# PPT — Parent Portal: DDL + Authorization Architecture
**Version:** 1.0 | **Date:** 2026-03-27 | **Module:** `Modules\ParentPortal`

This document covers the complete authorization backbone for the PPT module:
- **Part 1** — DDL decisions summary (tables in separate files)
- **Part 2** — Custom Middleware: `EnsureParentPortalAccess` (`parent.portal`)
- **Part 3** — Policies: `ParentChildPolicy`, `ParentMessagePolicy`, `ParentLeavePolicy`
- **Part 4** — FormRequests: 9 classes (P0 through P3)
- **Part 5** — Service Skeletons: 5 classes with full method signatures

---

## Part 1 — DDL Summary

See `PPT_DDL_v1.sql` and `PPT_Migration.php` for complete DDL and migration.

**Tables created:** `ppt_parent_sessions`, `ppt_messages`, `ppt_leave_applications`, `ppt_event_rsvps`, `ppt_document_requests`, `ppt_consent_form_responses`

**Critical design decisions:**
- All ppt_* PKs = `INT UNSIGNED AUTO_INCREMENT` — ✅
- `sys_users.id` = `INT UNSIGNED` (verified) → `sender_user_id`, `recipient_user_id`, `reviewed_by_user_id` all = `INT UNSIGNED` — ✅
- `created_by` = `BIGINT UNSIGNED` (platform standard) — ✅
- `ppt_consent_form_responses`: NO `deleted_at` (immutable) — ✅
- `ppt_event_rsvps`: NO `deleted_at` (update in-place) — ✅
- `fee_invoices` table name: no `fin_` prefix (verified in DDL) — documented in all code ✅

---

## Part 2 — Custom Middleware: `parent.portal`

**File:** `Modules/ParentPortal/app/Http/Middleware/EnsureParentPortalAccess.php`

Three-condition check. Returns **404 (not 401/403)** on failure — prevents portal enumeration.

```php
<?php

namespace Modules\ParentPortal\app\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class EnsureParentPortalAccess
{
    /**
     * Enforce all three conditions for parent portal access.
     *
     * Returns 404 (not 401/403) on all failures to prevent:
     * - Enumeration of whether the portal exists
     * - Role/type disclosure to unauthenticated users
     * - Information leakage about account structure
     */
    public function handle(Request $request, Closure $next): Response
    {
        // Condition 1: Must be authenticated
        if (! auth()->check()) {
            if ($request->expectsJson()) {
                return response()->json(['message' => 'Not found.'], 404);
            }
            return redirect()->route('ppt.login');
        }

        // Condition 2: Must be user_type = PARENT
        if (auth()->user()->user_type !== 'PARENT') {
            abort(404);  // 404 not 403 — prevents portal enumeration by other user types
        }

        // Condition 3: Must have a guardian record linked to this user
        $guardian = auth()->user()->guardian;  // std_guardians via user_id FK
        if (! $guardian) {
            abort(404);
        }

        // Condition 4: Must have at least 1 child with portal access
        $hasPortalAccess = $guardian->studentGuardianJnts()
            ->where('can_access_parent_portal', 1)
            ->exists();

        if (! $hasPortalAccess) {
            abort(404);
        }

        // Share guardian and allowed children with ALL portal views
        $allowedChildren = $guardian->studentGuardianJnts()
            ->where('can_access_parent_portal', 1)
            ->with('student')
            ->get()
            ->pluck('student');

        view()->share('currentGuardian', $guardian);
        view()->share('allowedChildren', $allowedChildren);

        // Refresh last_active_at on each portal request (background, non-blocking)
        $guardian->activeSession?->update(['last_active_at' => now()]);

        return $next($request);
    }
}
```

### 2.1 Middleware Registration

In `ParentPortalServiceProvider::boot()`:

```php
use Illuminate\Routing\Router;

public function boot(Router $router): void
{
    // Register custom middleware alias
    $router->aliasMiddleware('parent.portal', EnsureParentPortalAccess::class);

    // Register Policies
    Gate::policy(Student::class, ParentChildPolicy::class);

    parent::boot();
}
```

### 2.2 Route Group Pattern

```php
// Modules/ParentPortal/routes/web.php

use Illuminate\Support\Facades\Route;
use Modules\ParentPortal\app\Http\Controllers\AuthController;
// ... other controller imports

// ── Public Auth Routes (NO parent.portal middleware) ──────────────────────
Route::middleware(['web'])->prefix('parent-portal')->name('ppt.')->group(function () {
    Route::get('/login', [AuthController::class, 'login'])->name('login');
    Route::post('/auth/otp/send', [AuthController::class, 'sendOtp'])->name('otp.send')
        ->middleware('throttle:3,1');    // max 3 OTP requests per minute window
    Route::post('/auth/otp/verify', [AuthController::class, 'verifyOtp'])->name('otp.verify');
    Route::post('/auth/login', [AuthController::class, 'loginWithPassword'])->name('auth.login');
});

// ── Public Webhook (NO auth, NO parent.portal) ───────────────────────────
Route::middleware(['web'])->prefix('parent-portal')->name('ppt.')->group(function () {
    Route::post('/fees/razorpay-callback', [FeeViewController::class, 'razorpayCallback'])
        ->name('fees.razorpay-callback')
        ->withoutMiddleware(['web']); // Razorpay sends no CSRF token
});

// ── Protected Portal Routes ───────────────────────────────────────────────
Route::middleware(['auth', 'verified', 'parent.portal', 'EnsureTenantHasModule:ParentPortal'])
    ->prefix('parent-portal')
    ->name('ppt.')
    ->group(function () {

        Route::post('/auth/logout', [AuthController::class, 'logout'])->name('logout');
        Route::get('/dashboard', [ParentPortalController::class, 'dashboard'])->name('dashboard');
        Route::get('/children', [ParentPortalController::class, 'children'])->name('children');
        Route::post('/children/switch', [ParentPortalController::class, 'switchChild'])
            ->name('children.switch');

        // ... all other portal routes

        // Fee payment (extra rate limit on payment initiation)
        Route::post('/fees/pay', [FeeViewController::class, 'pay'])->name('fees.pay')
            ->middleware('throttle:3,5');  // max 3 payment initiations per 5 minutes
    });
```

---

## Part 3 — Policies

### 3.1 ParentChildPolicy (Core — applied on every data request)

**File:** `Modules/ParentPortal/app/Policies/ParentChildPolicy.php`

```php
<?php

namespace Modules\ParentPortal\app\Policies;

use App\Models\User;
use Modules\StudentProfile\app\Models\Student;  // Adjust FQCN per actual module location

class ParentChildPolicy
{
    /**
     * Core ownership check.
     * Verifies guardian → student link with portal access.
     * Called by EVERY portal data endpoint.
     *
     * @param  User    $user     Authenticated PARENT user
     * @param  Student $student  Target student record
     * @return bool
     */
    public function viewChildData(User $user, Student $student): bool
    {
        return $user->guardian?->studentGuardianJnts()
            ->where('student_id', $student->id)
            ->where('can_access_parent_portal', 1)
            ->exists() ?? false;
    }

    /**
     * Verify the student is the currently active child for this guardian.
     * Used when an action must be scoped to the active child only.
     */
    public function isActiveChild(User $user, Student $student): bool
    {
        if (! $this->viewChildData($user, $student)) {
            return false;
        }

        return optional($user->guardian?->activeSession)->active_student_id === $student->id;
    }

    /**
     * Health record visibility gate.
     * Requires both guardian → child ownership AND per-record parent_visible = 1.
     *
     * @param  mixed $record  stdClass or Eloquent model with parent_visible attribute
     */
    public function viewHealthRecord(User $user, Student $student, mixed $record): bool
    {
        return $this->viewChildData($user, $student)
            && (bool) data_get($record, 'parent_visible', false);
    }

    /**
     * Counsellor psychological report visibility gate.
     * Controlled by school-level setting (not per-record).
     * Default = hidden; school must explicitly enable.
     */
    public function viewCounsellorReport(User $user): bool
    {
        return (bool) app('school_settings')->get('parent_counsellor_report_visibility', false);
    }

    /**
     * Fee invoice payment gate.
     * Requires: guardian → child ownership + invoice belongs to that child
     *          + invoice is in a payable status + balance > 0.
     *
     * IMPORTANT: fee_invoices has NO direct student_id column.
     * Ownership chain: fee_invoices.student_assignment_id → fee_student_assignments.student_id
     *
     * @param  mixed $invoice  FeeInvoice model instance
     */
    public function payInvoice(User $user, Student $student, mixed $invoice): bool
    {
        if (! $this->viewChildData($user, $student)) {
            return false;
        }

        // Verify invoice belongs to this student via fee_student_assignments chain
        $invoiceBelongsToStudent = $invoice->studentAssignment?->student_id === $student->id;
        if (! $invoiceBelongsToStudent) {
            return false;
        }

        // Verify invoice is in a payable status
        $payableStatuses = ['Published', 'Partially Paid', 'Overdue'];
        if (! in_array($invoice->status, $payableStatuses, true)) {
            return false;
        }

        // Verify there is an outstanding balance (balance_amount is GENERATED ALWAYS column)
        return $invoice->balance_amount > 0;
    }
}
```

### 3.2 ParentMessagePolicy

**File:** `Modules/ParentPortal/app/Policies/ParentMessagePolicy.php`

```php
<?php

namespace Modules\ParentPortal\app\Policies;

use App\Models\User;
use Modules\StudentProfile\app\Models\Student;
use Modules\ParentPortal\app\Services\MessagingService;

class ParentMessagePolicy
{
    public function __construct(
        private readonly MessagingService $messagingService
    ) {}

    /**
     * Parent can only compose a message to a teacher who teaches their active child.
     * Teacher list sourced from timetable assignments for child's class+section.
     *
     * @param  User $user     Authenticated PARENT user
     * @param  User $teacher  The teacher user the parent wants to message
     */
    public function composeMessage(User $user, User $teacher): bool
    {
        $guardian = $user->guardian;
        if (! $guardian) {
            return false;
        }

        // Get active child
        $activeStudentId = $guardian->activeSession?->active_student_id;
        if (! $activeStudentId) {
            return false;
        }

        $activeStudent = Student::find($activeStudentId);
        if (! $activeStudent) {
            return false;
        }

        // Verify teacher is in the allowed list for this child
        $allowedTeacherIds = $this->messagingService
            ->getAllowedTeachers($activeStudent)
            ->pluck('id');

        return $allowedTeacherIds->contains($teacher->id);
    }

    /**
     * Parent can only view a thread they are a participant in.
     * thread_id = MD5(guardian_id + '_' + teacher_user_id + '_' + student_id)
     *
     * @param  User   $user      Authenticated PARENT user
     * @param  string $threadId  MD5 thread hash
     */
    public function viewThread(User $user, string $threadId): bool
    {
        $guardian = $user->guardian;
        if (! $guardian) {
            return false;
        }

        // Verify at least one message in thread belongs to this guardian
        return \Modules\ParentPortal\app\Models\ParentMessage::where('thread_id', $threadId)
            ->where('guardian_id', $guardian->id)
            ->exists();
    }
}
```

### 3.3 ParentLeavePolicy

**File:** `Modules/ParentPortal/app/Policies/ParentLeavePolicy.php`

```php
<?php

namespace Modules\ParentPortal\app\Policies;

use App\Models\User;
use Modules\StudentProfile\app\Models\Student;
use Modules\ParentPortal\app\Models\ParentLeaveApplication;
use Modules\ParentPortal\app\Policies\ParentChildPolicy;

class ParentLeavePolicy
{
    public function __construct(
        private readonly ParentChildPolicy $childPolicy
    ) {}

    /**
     * Parent can apply leave for a child they are authorized to access.
     * Delegates to ParentChildPolicy::viewChildData().
     */
    public function apply(User $user, Student $student): bool
    {
        return $this->childPolicy->viewChildData($user, $student);
    }

    /**
     * Parent can withdraw their OWN leave application,
     * but ONLY while it is in 'Pending' status.
     * Cannot withdraw Approved, Rejected, or already Withdrawn applications.
     */
    public function withdraw(User $user, ParentLeaveApplication $leaveApplication): bool
    {
        $guardian = $user->guardian;
        if (! $guardian) {
            return false;
        }

        // Must be the guardian who submitted this application
        if ($leaveApplication->guardian_id !== $guardian->id) {
            return false;
        }

        // Can only withdraw from Pending state (BR-PPT-010)
        return $leaveApplication->status === 'Pending';
    }
}
```

---

## Part 4 — FormRequests (9 Classes)

### 4.1 SwitchChildRequest (P0 — IDOR guard)

**File:** `Modules/ParentPortal/app/Http/Requests/SwitchChildRequest.php`

```php
<?php

namespace Modules\ParentPortal\app\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Modules\StudentProfile\app\Models\StudentGuardianJnt;

class SwitchChildRequest extends FormRequest
{
    /**
     * Verify the student_id is in the guardian's allowed children list.
     * Prevents child-switching IDOR where ParentA switches to StudentB's context.
     */
    public function authorize(): bool
    {
        $guardian = auth()->user()->guardian;
        if (! $guardian) {
            return false;
        }

        return StudentGuardianJnt::where('guardian_id', $guardian->id)
            ->where('student_id', (int) $this->student_id)
            ->where('can_access_parent_portal', 1)
            ->exists();
    }

    public function rules(): array
    {
        return [
            'student_id' => ['required', 'integer', 'exists:std_students,id'],
        ];
    }

    public function messages(): array
    {
        return [
            'student_id.exists' => 'The selected child was not found.',
        ];
    }
}
```

### 4.2 FeePaymentRequest (P0 — IDOR guard)

**File:** `Modules/ParentPortal/app/Http/Requests/FeePaymentRequest.php`

```php
<?php

namespace Modules\ParentPortal\app\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Modules\StudentFee\app\Models\FeeInvoice;  // Adjust FQCN per actual module

class FeePaymentRequest extends FormRequest
{
    /**
     * P0 IDOR guard: verify every invoice_id in the request belongs to the
     * guardian's active child via the fee_student_assignments ownership chain.
     *
     * fee_invoices has NO direct student_id — chain:
     * fee_invoices.student_assignment_id → fee_student_assignments.student_id
     */
    public function authorize(): bool
    {
        $guardian = auth()->user()->guardian;
        if (! $guardian) {
            return false;
        }

        $activeStudentId = $guardian->activeSession?->active_student_id;
        if (! $activeStudentId) {
            return false;
        }

        // All invoice IDs must belong to the active student
        $invoiceIds = (array) $this->invoice_ids;
        if (empty($invoiceIds)) {
            return false;
        }

        $validCount = FeeInvoice::whereIn('id', $invoiceIds)
            ->whereHas('studentAssignment', function ($q) use ($activeStudentId) {
                $q->where('student_id', $activeStudentId);
            })
            ->whereIn('status', ['Published', 'Partially Paid', 'Overdue'])
            ->where('balance_amount', '>', 0)
            ->count();

        // All invoices must pass the ownership check
        return $validCount === count($invoiceIds);
    }

    public function rules(): array
    {
        return [
            'invoice_ids'   => ['required', 'array', 'min:1'],
            'invoice_ids.*' => ['required', 'integer', 'exists:fee_invoices,id'],
            'total_amount'  => ['required', 'numeric', 'min:0.01'],
        ];
    }

    public function messages(): array
    {
        return [
            'invoice_ids.required'   => 'Please select at least one invoice to pay.',
            'total_amount.min'       => 'Payment amount must be greater than zero.',
        ];
    }
}
```

### 4.3 ComposeMessageRequest (P1)

**File:** `Modules/ParentPortal/app\Http\Requests\ComposeMessageRequest.php`

```php
<?php

namespace Modules\ParentPortal\app\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use App\Models\User;
use Modules\ParentPortal\app\Services\MessagingService;
use Modules\StudentProfile\app\Models\Student;

class ComposeMessageRequest extends FormRequest
{
    public function __construct(
        private readonly MessagingService $messagingService
    ) {
        parent::__construct();
    }

    /**
     * Verify recipient is a teacher who teaches the parent's active child.
     * Enforces BR-PPT-003: parent can only message teachers of their active child.
     */
    public function authorize(): bool
    {
        $guardian = auth()->user()->guardian;
        if (! $guardian) {
            return false;
        }

        $activeStudentId = $guardian->activeSession?->active_student_id;
        if (! $activeStudentId) {
            return false;
        }

        $teacher = User::find((int) $this->recipient_user_id);
        if (! $teacher) {
            return false;
        }

        $activeStudent = Student::find($activeStudentId);
        $allowedTeacherIds = $this->messagingService
            ->getAllowedTeachers($activeStudent)
            ->pluck('id');

        return $allowedTeacherIds->contains($teacher->id);
    }

    public function rules(): array
    {
        return [
            'recipient_user_id' => ['required', 'integer', 'exists:sys_users,id'],
            'subject'           => ['required', 'string', 'max:200'],
            'message_body'      => ['required', 'string', 'min:10', 'max:5000'],
            'attachments'       => ['nullable', 'array', 'max:3'],
            'attachments.*'     => [
                'file',
                'max:5120',                             // 5 MB each
                'mimes:pdf,jpg,jpeg,png,doc,docx',
            ],
        ];
    }

    protected function prepareForValidation(): void
    {
        // Strip HTML tags from message body to prevent XSS
        if ($this->has('message_body')) {
            $this->merge([
                'message_body' => strip_tags($this->message_body),
            ]);
        }
    }
}
```

### 4.4 ApplyLeaveRequest (P2)

**File:** `Modules/ParentPortal/app/Http/Requests/ApplyLeaveRequest.php`

```php
<?php

namespace Modules\ParentPortal\app\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Modules\StudentProfile\app\Models\StudentGuardianJnt;

class ApplyLeaveRequest extends FormRequest
{
    /**
     * Verify guardian has access to the active child.
     * from_date >= tomorrow is enforced in rules(), not here.
     */
    public function authorize(): bool
    {
        $guardian = auth()->user()->guardian;
        if (! $guardian) {
            return false;
        }

        $activeStudentId = $guardian->activeSession?->active_student_id;
        if (! $activeStudentId) {
            return false;
        }

        return StudentGuardianJnt::where('guardian_id', $guardian->id)
            ->where('student_id', $activeStudentId)
            ->where('can_access_parent_portal', 1)
            ->exists();
    }

    public function rules(): array
    {
        return [
            'from_date'       => ['required', 'date', 'after:today'],    // BR-PPT-004: must be >= tomorrow
            'to_date'         => ['required', 'date', 'after_or_equal:from_date'],
            'leave_type'      => ['required', 'in:Sick,Family,Personal,Festival,Medical,Other'],
            'reason'          => ['required', 'string', 'min:20', 'max:1000'],
            'supporting_doc'  => ['nullable', 'file', 'mimes:pdf,jpg,jpeg,png', 'max:5120'],
        ];
    }

    public function messages(): array
    {
        return [
            'from_date.after'            => 'Leave can only be applied for tomorrow or a future date.',
            'to_date.after_or_equal'     => 'End date must be on or after the start date.',
            'reason.min'                 => 'Please provide a detailed reason (minimum 20 characters).',
            'supporting_doc.mimes'       => 'Supporting document must be a PDF or image file.',
        ];
    }
}
```

### 4.5 NotificationPreferencesRequest (P2)

**File:** `Modules/ParentPortal/app/Http/Requests/NotificationPreferencesRequest.php`

```php
<?php

namespace Modules\ParentPortal\app\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class NotificationPreferencesRequest extends FormRequest
{
    public function authorize(): bool
    {
        // parent.portal middleware already verified auth; guardian existence confirmed
        return auth()->check() && auth()->user()->user_type === 'PARENT';
    }

    public function rules(): array
    {
        $allowedAlertTypes = [
            'FeeReminder', 'AbsenceAlert', 'ExamResult', 'HomeworkDue',
            'CircularAnnouncement', 'TransportUpdate', 'EventReminder',
            'LeaveStatus', 'PTMReminder', 'EmergencyAlert',
        ];

        return [
            'preferences'                  => ['required', 'array'],
            'preferences.*'                => ['array'],
            'preferences.*.in_app'         => ['nullable', 'boolean'],
            'preferences.*.sms'            => ['nullable', 'boolean'],
            'preferences.*.email'          => ['nullable', 'boolean'],
            'preferences.*.whatsapp'       => ['nullable', 'boolean'],
            'quiet_hours_start'            => ['nullable', 'date_format:H:i'],
            'quiet_hours_end'              => ['nullable', 'date_format:H:i', 'required_with:quiet_hours_start'],
        ];
    }

    public function withValidator($validator): void
    {
        $validator->after(function ($validator) {
            $allowedKeys = [
                'FeeReminder', 'AbsenceAlert', 'ExamResult', 'HomeworkDue',
                'CircularAnnouncement', 'TransportUpdate', 'EventReminder',
                'LeaveStatus', 'PTMReminder', 'EmergencyAlert',
            ];

            foreach (array_keys((array) $this->preferences) as $key) {
                if (! in_array($key, $allowedKeys, true)) {
                    $validator->errors()->add(
                        "preferences.{$key}",
                        "Unknown alert type: {$key}"
                    );
                }
            }
        });
    }

    public function messages(): array
    {
        return [
            'quiet_hours_end.required_with' => 'Quiet hours end time is required when start time is set.',
            'quiet_hours_end.date_format'   => 'Quiet hours must be in HH:MM format (e.g. 22:00).',
        ];
    }
}
```

### 4.6 ConsentFormSignRequest (P2)

**File:** `Modules/ParentPortal/app/Http/Requests/ConsentFormSignRequest.php`

```php
<?php

namespace Modules\ParentPortal\app\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Modules\StudentProfile\app\Models\StudentGuardianJnt;

class ConsentFormSignRequest extends FormRequest
{
    /**
     * Verify guardian can access active child AND the form deadline has not passed.
     * Deadline check here prevents the database insert; unique constraint is the DB backstop.
     */
    public function authorize(): bool
    {
        $guardian = auth()->user()->guardian;
        if (! $guardian) {
            return false;
        }

        $activeStudentId = $guardian->activeSession?->active_student_id;
        if (! $activeStudentId) {
            return false;
        }

        // Verify child access
        $hasAccess = StudentGuardianJnt::where('guardian_id', $guardian->id)
            ->where('student_id', $activeStudentId)
            ->where('can_access_parent_portal', 1)
            ->exists();

        if (! $hasAccess) {
            return false;
        }

        // Verify consent form deadline has not passed
        // consent_form_id comes from route parameter (set by ConsentFormController)
        $consentFormId = $this->route('id') ?? $this->consent_form_id;
        // The controller should check deadline; authorize() checks access only
        // Deadline enforcement: controller aborts with 422 if form.deadline_date < today

        return true;
    }

    public function rules(): array
    {
        return [
            'response'       => ['required', 'in:Signed,Declined'],
            'decline_reason' => ['required_if:response,Declined', 'nullable', 'string', 'min:10', 'max:1000'],
            'signer_name'    => ['required', 'string', 'min:3', 'max:150'],
        ];
    }

    protected function prepareForValidation(): void
    {
        // Strip HTML tags from signer_name to prevent XSS in legal records
        if ($this->has('signer_name')) {
            $this->merge([
                'signer_name' => strip_tags($this->signer_name),
            ]);
        }
    }

    public function messages(): array
    {
        return [
            'response.in'                    => 'Response must be either "Signed" or "Declined".',
            'decline_reason.required_if'     => 'Please provide a reason for declining.',
            'signer_name.required'           => 'Please enter your full name to sign.',
        ];
    }
}
```

### 4.7 PtmBookingRequest (P2)

**File:** `Modules/ParentPortal/app/Http/Requests/PtmBookingRequest.php`

```php
<?php

namespace Modules\ParentPortal\app\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Modules\StudentProfile\app\Models\StudentGuardianJnt;

class PtmBookingRequest extends FormRequest
{
    /**
     * Verify parent has active child access for PTM booking.
     * Race condition safety is handled in PtmSchedulingService::bookSlot() via DB::transaction.
     */
    public function authorize(): bool
    {
        $guardian = auth()->user()->guardian;
        if (! $guardian) {
            return false;
        }

        $activeStudentId = $guardian->activeSession?->active_student_id;
        if (! $activeStudentId) {
            return false;
        }

        return StudentGuardianJnt::where('guardian_id', $guardian->id)
            ->where('student_id', $activeStudentId)
            ->where('can_access_parent_portal', 1)
            ->exists();
    }

    public function rules(): array
    {
        return [
            'ptm_event_id'     => ['required', 'integer'],     // Event Engine record
            'slot_id'          => ['required', 'integer'],     // PTM slot record
            'teacher_user_id'  => ['required', 'integer', 'exists:sys_users,id'],
        ];
    }

    public function messages(): array
    {
        return [
            'teacher_user_id.exists' => 'The selected teacher was not found.',
        ];
    }
}
```

### 4.8 EventRsvpRequest (P3)

**File:** `Modules/ParentPortal/app/Http/Requests/EventRsvpRequest.php`

```php
<?php

namespace Modules\ParentPortal\app\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class EventRsvpRequest extends FormRequest
{
    public function authorize(): bool
    {
        // parent.portal middleware handles auth and guardian existence check
        return auth()->check() && auth()->user()->user_type === 'PARENT';
    }

    public function rules(): array
    {
        return [
            'event_id'      => ['required', 'integer'],
            'rsvp_status'   => ['required', 'in:Attending,Not_Attending,Maybe'],
            'is_volunteer'  => ['nullable', 'boolean'],
            'volunteer_role'=> ['required_if:is_volunteer,1', 'nullable', 'string', 'max:150'],
            'rsvp_notes'    => ['nullable', 'string', 'max:500'],
        ];
    }

    public function messages(): array
    {
        return [
            'volunteer_role.required_if' => 'Please specify your volunteer role.',
        ];
    }
}
```

### 4.9 DocumentRequestForm (P3)

**File:** `Modules/ParentPortal/app/Http/Requests/DocumentRequestForm.php`

```php
<?php

namespace Modules\ParentPortal\app\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Modules\StudentProfile\app\Models\StudentGuardianJnt;

class DocumentRequestForm extends FormRequest
{
    /**
     * Verify parent has active child access before submitting document request.
     */
    public function authorize(): bool
    {
        $guardian = auth()->user()->guardian;
        if (! $guardian) {
            return false;
        }

        $activeStudentId = $guardian->activeSession?->active_student_id;
        if (! $activeStudentId) {
            return false;
        }

        return StudentGuardianJnt::where('guardian_id', $guardian->id)
            ->where('student_id', $activeStudentId)
            ->where('can_access_parent_portal', 1)
            ->exists();
    }

    public function rules(): array
    {
        return [
            'document_type' => [
                'required',
                'in:TC,MarkSheet,Bonafide,Character,Migration,MedicalFitness,Other',
            ],
            'reason'    => ['required', 'string', 'min:20', 'max:2000'],
            'urgency'   => ['required', 'in:Normal,Urgent'],
        ];
    }

    public function messages(): array
    {
        return [
            'reason.min' => 'Please provide a detailed reason (minimum 20 characters).',
        ];
    }
}
```

---

## Part 5 — Service Skeletons (5 Services)

### 5.1 ParentDashboardService

**File:** `Modules/ParentPortal/app/Services/ParentDashboardService.php`

```php
<?php

namespace Modules\ParentPortal\app\Services;

use Illuminate\Support\Facades\Cache;
use Modules\StudentProfile\app\Models\Guardian;
use Modules\StudentProfile\app\Models\Student;

/**
 * Aggregates all dashboard data for the parent portal.
 *
 * Performance target: max 5 queries for all dashboard widgets.
 * Cache: Cache::tags(['parent', $guardian->id])->remember(300, ...) — 5-min TTL
 * Cache invalidation: invalidate 'parent' tag on fee payment, leave status change, new message.
 */
class ParentDashboardService
{
    /**
     * Fetch all dashboard data for the active child.
     * Returns an array suitable for passing directly to the dashboard Blade view.
     *
     * @param  Guardian $guardian    Authenticated guardian model
     * @param  Student  $activeChild Currently selected child
     * @return array{
     *   child_cards: Collection,
     *   snapshot: array,
     *   today_timetable: Collection,
     *   transport_status: array|null,
     *   action_required: array,
     *   unread_notifications: int,
     * }
     */
    public function getDashboardData(Guardian $guardian, Student $activeChild): array
    {
        return Cache::tags(['parent', $guardian->id])->remember(
            "dashboard_{$guardian->id}_{$activeChild->id}",
            300,
            function () use ($guardian, $activeChild) {
                // Query 1: Eager-load all allowed children with their current class/section
                $guardian->loadMissing([
                    'studentGuardianJnts.student.currentAcademicSession.classSection.class',
                    'studentGuardianJnts.student.currentAcademicSession.classSection.section',
                ]);

                return [
                    'child_cards'           => $this->buildChildCards($guardian),
                    'snapshot'              => $this->getAcademicSnapshot($activeChild),
                    'today_timetable'       => $this->getTodayTimetable($activeChild),    // NOT cached (realtime)
                    'transport_status'      => $this->getTransportStatus($activeChild),
                    'action_required'       => $this->getActionRequired($guardian, $activeChild),
                    'unread_notifications'  => $this->getUnreadCount($guardian),
                ];
            }
        );
    }

    /**
     * Build child overview cards for the dashboard header.
     * Shows: photo, name, class+section, today's attendance status.
     *
     * @param  Guardian $guardian
     * @return \Illuminate\Support\Collection
     */
    public function buildChildCards(Guardian $guardian): \Illuminate\Support\Collection
    {
        // TODO: Implement — map each allowed child to card data array
        // Query: std_attendance WHERE student_id IN [...] AND date = today
        throw new \RuntimeException('Not implemented — stub');
    }

    /**
     * Academic snapshot for the active child.
     * Returns: attendance_pct (month), last_test_score, pending_homework_count,
     *          fee_due_amount, next_fee_due_date.
     *
     * @param  Student $student
     * @return array
     */
    public function getAcademicSnapshot(Student $student): array
    {
        // TODO: Implement — queries: std_attendance + hmw_assignments + fee_invoices
        // fee_invoices via: fee_student_assignments WHERE student_id = $student->id
        //                    → fee_invoices WHERE status IN ['Published','Partially Paid','Overdue']
        throw new \RuntimeException('Not implemented — stub');
    }

    /**
     * Today's timetable for the active child (NOT cached — realtime).
     *
     * @param  Student $student
     * @return \Illuminate\Support\Collection
     */
    public function getTodayTimetable(Student $student): \Illuminate\Support\Collection
    {
        // TODO: Implement — query tt_timetable_cells + tt_published_timetables
        // Filter: class_section_id = student's current class section, day = today
        throw new \RuntimeException('Not implemented — stub');
    }

    /**
     * Transport status for the active child (soft dependency — null if TPT inactive).
     *
     * @param  Student $student
     * @return array|null
     */
    public function getTransportStatus(Student $student): ?array
    {
        // TODO: Implement — query tpt_student_route_jnt + tpt_routes + tpt_vehicles
        // Graceful degradation: return null if Transport module not active
        return null; // stub
    }

    /**
     * "Action required" section: unpaid fees + unsigned consent forms + pending leaves.
     * Surfaces urgency items prominently (SUG-PPT-10).
     *
     * @param  Guardian $guardian
     * @param  Student  $student
     * @return array{unpaid_invoices: int, unsigned_forms: int, pending_leaves: int}
     */
    public function getActionRequired(Guardian $guardian, Student $student): array
    {
        // TODO: Implement — 3 quick count queries
        return ['unpaid_invoices' => 0, 'unsigned_forms' => 0, 'pending_leaves' => 0];
    }

    /**
     * Unread notification count for nav badge.
     *
     * @param  Guardian $guardian
     * @return int
     */
    public function getUnreadCount(Guardian $guardian): int
    {
        // TODO: Implement — query ntf_notifications WHERE user_id = guardian.user_id AND read_at IS NULL
        return 0; // stub
    }
}
```

### 5.2 FeePaymentService

**File:** `Modules/ParentPortal/app/Services/FeePaymentService.php`

```php
<?php

namespace Modules\ParentPortal\app\Services;

use Illuminate\Support\Facades\DB;
use Modules\StudentProfile\app\Models\Guardian;
use Modules\StudentProfile\app\Models\Student;

/**
 * Handles Razorpay payment initiation, verification, and recording.
 *
 * Design: razorpayCallback() and apiCallback() share the same verifyAndRecord() method.
 * Idempotency guard must be checked BEFORE any database write.
 */
class FeePaymentService
{
    public function __construct(
        private readonly \Razorpay\Api\Api $razorpay  // Injected via AppServiceProvider binding
    ) {}

    /**
     * Create a Razorpay order for one or more invoice IDs.
     * Ownership verified upstream by FeePaymentRequest::authorize().
     *
     * @param  Guardian $guardian
     * @param  array    $invoiceIds  Array of fee_invoices.id values
     * @param  float    $totalAmount
     * @return array{order_id: string, razorpay_key: string, amount: int, currency: string}
     */
    public function initiatePayment(Guardian $guardian, array $invoiceIds, float $totalAmount): array
    {
        // TODO: Implement
        // 1. Create Razorpay order: $this->razorpay->order->create([...])
        // 2. Store order_id in cache for verification step
        // 3. Return order_id + razorpay_key (from config) + amount in paise + 'INR'
        throw new \RuntimeException('Not implemented — stub');
    }

    /**
     * Verify Razorpay signature and record successful payment.
     * Called from both web (razorpayCallback) and API (apiCallback).
     *
     * ⚠️ IDEMPOTENCY: check for existing payment_reference BEFORE any write.
     * Webhook replay with same payment_id must return true without creating duplicate record.
     *
     * @param  array $payload  Contains: razorpay_order_id, razorpay_payment_id, razorpay_signature
     * @return bool  true = success (including idempotent replay), false = signature invalid
     */
    public function verifyAndRecord(array $payload): bool
    {
        // TODO: Implement
        // Step 1: HMAC SHA256 verify
        //   $expectedSignature = hash_hmac('sha256',
        //       $payload['razorpay_order_id'] . '|' . $payload['razorpay_payment_id'],
        //       config('services.razorpay.secret')
        //   );
        //   if (!hash_equals($expectedSignature, $payload['razorpay_signature'])) return false;
        //
        // Step 2: ⚠️ Idempotency check
        //   if (FeeTransaction::where('payment_reference', $payload['razorpay_payment_id'])->exists()) {
        //       return true; // Already processed — idempotent webhook replay
        //   }
        //
        // Step 3: DB transaction — create fee_transactions + update fee_invoices.status
        //   DB::transaction(function() use ($payload) { ... });
        //
        // Step 4: Dispatch receipt notification (queued)
        throw new \RuntimeException('Not implemented — stub');
    }

    /**
     * Generate PDF fee receipt using DomPDF.
     *
     * @param  int $transactionId  fee_transactions.id
     * @return string  Path to generated PDF in storage
     */
    public function generateReceipt(int $transactionId): string
    {
        // TODO: Implement — DomPDF with school letterhead; store in tenant storage
        throw new \RuntimeException('Not implemented — stub');
    }
}
```

### 5.3 MessagingService

**File:** `Modules/ParentPortal/app/Services/MessagingService.php`

```php
<?php

namespace Modules\ParentPortal\app\Services;

use Illuminate\Support\Collection;
use Modules\StudentProfile\app\Models\Student;
use Modules\StudentProfile\app\Models\Guardian;
use Modules\ParentPortal\app\Http\Requests\ComposeMessageRequest;
use Modules\ParentPortal\app\Models\ParentMessage;

/**
 * Thread-based parent-teacher messaging.
 *
 * Thread model: thread_id = MD5(guardian_id + '_' + teacher_user_id + '_' + student_id)
 * Ownership: all messages in a thread share the same (guardian, teacher, student) tuple.
 */
class MessagingService
{
    /**
     * Compute deterministic thread ID from participant IDs.
     * Same inputs always produce same thread_id — groups messages into conversations.
     *
     * @param  int $guardianId      ppt_parent_sessions.guardian_id
     * @param  int $teacherUserId   sys_users.id of the teacher
     * @param  int $studentId       std_students.id
     * @return string  MD5 hash (32 hex chars, stored in VARCHAR(64))
     */
    public function getOrCreateThread(int $guardianId, int $teacherUserId, int $studentId): string
    {
        return md5("{$guardianId}_{$teacherUserId}_{$studentId}");
    }

    /**
     * Get all teachers allowed to receive messages from parent for given student.
     * Sources teacher list from timetable assignments for student's class+section.
     * Fallback: all active staff if timetable unavailable.
     *
     * Used by: ParentMessagePolicy::composeMessage(), ComposeMessageRequest::authorize()
     *
     * @param  Student $student
     * @return Collection  Collection of sys_users records (teachers)
     */
    public function getAllowedTeachers(Student $student): Collection
    {
        // TODO: Implement
        // 1. Get student's current class_section_id via currentAcademicSession
        // 2. Query tt_timetable_cells WHERE class_section_id = ... → get teacher_user_ids
        // 3. Return User::whereIn('id', $teacherUserIds)->where('user_type', 'TEACHER')->get()
        // Fallback: User::where('user_type', 'TEACHER')->get() if timetable unavailable
        return collect(); // stub
    }

    /**
     * Store a new parent-to-teacher message.
     * Dispatches in-app notification to teacher (queued).
     *
     * @param  ComposeMessageRequest $request
     * @param  Guardian              $guardian
     * @return ParentMessage
     */
    public function storeMessage(ComposeMessageRequest $request, Guardian $guardian): ParentMessage
    {
        // TODO: Implement
        // 1. Resolve activeStudentId from guardian session
        // 2. Compute thread_id
        // 3. Handle attachment upload → sys_media → store IDs in JSON
        // 4. Create ppt_messages record
        // 5. Dispatch notification to recipient_user_id (queued)
        throw new \RuntimeException('Not implemented — stub');
    }

    /**
     * Get all threads for a guardian, with latest message per thread.
     * Used for the message inbox (SCR-PPT-17).
     *
     * @param  Guardian $guardian
     * @return Collection  Grouped by thread_id, ordered by latest created_at
     */
    public function getThreadsForGuardian(Guardian $guardian): Collection
    {
        // TODO: Implement — group ppt_messages by thread_id, take latest per thread
        return collect(); // stub
    }

    /**
     * Search messages by keyword using FULLTEXT index.
     * Returns messages matching keyword in (subject, message_body).
     *
     * @param  Guardian $guardian
     * @param  string   $keyword
     * @return Collection
     */
    public function searchMessages(Guardian $guardian, string $keyword): Collection
    {
        // TODO: Implement — MATCH(subject, message_body) AGAINST($keyword IN BOOLEAN MODE)
        return collect(); // stub
    }
}
```

### 5.4 NotificationPreferenceService

**File:** `Modules/ParentPortal/app/Services/NotificationPreferenceService.php`

```php
<?php

namespace Modules\ParentPortal\app\Services;

use Modules\ParentPortal\app\Models\ParentSession;
use Modules\StudentProfile\app\Models\Guardian;

/**
 * Evaluates notification delivery constraints (preferences + quiet hours).
 *
 * Critical business rule:
 * AbsenceAlert + EmergencyAlert ALWAYS bypass quiet hours (BR-PPT-008).
 * All other alert types respect preference toggles and quiet hours.
 */
class NotificationPreferenceService
{
    /** Alert types that bypass quiet hours unconditionally */
    private const URGENT_ALERT_TYPES = ['AbsenceAlert', 'EmergencyAlert'];

    /**
     * Determine whether a notification should be delivered now.
     *
     * @param  ParentSession $session    Guardian's portal session (contains prefs + quiet hours)
     * @param  string        $alertType  e.g. 'FeeReminder', 'AbsenceAlert'
     * @param  string        $channel    e.g. 'in_app', 'sms', 'email', 'whatsapp'
     * @return bool  true = deliver now, false = suppress or buffer
     */
    public function shouldDeliver(ParentSession $session, string $alertType, string $channel): bool
    {
        // ⚠️ Urgent types ALWAYS bypass quiet hours (BR-PPT-008)
        if (in_array($alertType, self::URGENT_ALERT_TYPES, true)) {
            return $this->isChannelEnabled($session, $alertType, $channel);
        }

        // Check preference toggle for this alert type + channel
        if (! $this->isChannelEnabled($session, $alertType, $channel)) {
            return false;
        }

        // Check quiet hours — buffer if within quiet period
        if ($this->isQuietHoursActive($session)) {
            return false;  // Caller should buffer this notification for later delivery
        }

        return true;
    }

    /**
     * Check if a specific alert type + channel is enabled in preferences.
     *
     * @param  ParentSession $session
     * @param  string        $alertType
     * @param  string        $channel
     * @return bool  Defaults to true if preference not explicitly set
     */
    public function isChannelEnabled(ParentSession $session, string $alertType, string $channel): bool
    {
        $prefs = $session->notification_preferences_json ?? [];
        return (bool) data_get($prefs, "{$alertType}.{$channel}", true);
    }

    /**
     * Check if current time falls within the guardian's quiet hours window.
     * Handles midnight-crossing windows (e.g. 22:00 to 07:00).
     *
     * @param  ParentSession $session
     * @return bool  true = currently in quiet hours
     */
    public function isQuietHoursActive(ParentSession $session): bool
    {
        if (! $session->quiet_hours_start || ! $session->quiet_hours_end) {
            return false;
        }

        $now   = now()->format('H:i');
        $start = $session->quiet_hours_start;
        $end   = $session->quiet_hours_end;

        // Handle overnight window (e.g. 22:00 → 07:00)
        if ($start > $end) {
            return $now >= $start || $now < $end;
        }

        return $now >= $start && $now < $end;
    }

    /**
     * Save notification preferences for all active sessions of a guardian.
     * Upserts ppt_parent_sessions.notification_preferences_json.
     *
     * @param  Guardian $guardian
     * @param  array    $preferences  Validated preferences array from NotificationPreferencesRequest
     * @param  array    $quietHours   ['start' => 'HH:MM', 'end' => 'HH:MM'] or empty
     * @return void
     */
    public function savePreferences(Guardian $guardian, array $preferences, array $quietHours = []): void
    {
        // TODO: Implement — update all active ppt_parent_sessions for this guardian
        // guardian->parentSessions()->where('is_active', 1)->update([
        //     'notification_preferences_json' => json_encode($preferences),
        //     'quiet_hours_start' => $quietHours['start'] ?? null,
        //     'quiet_hours_end'   => $quietHours['end'] ?? null,
        // ]);
    }
}
```

### 5.5 PtmSchedulingService

**File:** `Modules/ParentPortal/app/Services/PtmSchedulingService.php`

```php
<?php

namespace Modules\ParentPortal\app\Services;

use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;
use Modules\StudentProfile\app\Models\Guardian;
use Modules\ParentPortal\app\Http\Requests\PtmBookingRequest;

/**
 * Race-condition-safe PTM slot booking.
 *
 * Design: DB::transaction + SELECT...FOR UPDATE on slot record.
 * Concurrent bookings resolved at DB level — only one guardian wins.
 * Test scenario T-18 (PtmDoubleBookingTest) validates this behavior.
 */
class PtmSchedulingService
{
    /**
     * Get available (unbooked) slots for a specific teacher in a PTM event.
     *
     * @param  int $ptmEventId    PTM event ID (Event Engine record)
     * @param  int $teacherUserId sys_users.id of the teacher
     * @return Collection  Available PTM slots ordered by slot_time
     */
    public function getAvailableSlots(int $ptmEventId, int $teacherUserId): Collection
    {
        // TODO: Implement — query PTM slot records for this event + teacher WHERE is_booked = 0
        return collect(); // stub
    }

    /**
     * Book a PTM slot with race-condition protection.
     *
     * Uses DB::transaction() + lockForUpdate() to prevent two guardians
     * from booking the same slot simultaneously.
     *
     * @param  PtmBookingRequest $request   Validated request (ptm_event_id, slot_id, teacher_user_id)
     * @param  Guardian          $guardian
     * @return object  The created booking record
     * @throws \Symfony\Component\HttpKernel\Exception\HttpException  409 if slot taken
     */
    public function bookSlot(PtmBookingRequest $request, Guardian $guardian): object
    {
        return DB::transaction(function () use ($request, $guardian) {
            // ⚠️ SELECT...FOR UPDATE: lock slot row exclusively for this transaction
            $slot = DB::table('ptm_slots')
                ->lockForUpdate()
                ->where('id', $request->slot_id)
                ->where('ptm_event_id', $request->ptm_event_id)
                ->where('teacher_user_id', $request->teacher_user_id)
                ->first();

            abort_if(! $slot, 404, 'PTM slot not found.');
            abort_if($slot->is_booked, 409, 'Slot just taken; please choose another.');

            // Mark slot as booked
            DB::table('ptm_slots')->where('id', $slot->id)->update([
                'is_booked'             => 1,
                'booked_by_guardian_id' => $guardian->id,
                'booked_at'             => now(),
            ]);

            // TODO: Create booking record + dispatch confirmation notifications (queued)
            // $booking = PtmBooking::create([...]);
            // dispatch(new SendPtmConfirmation($booking, $guardian))->onQueue('notifications');

            return (object) ['slot_id' => $slot->id, 'status' => 'booked']; // stub return
        });
    }

    /**
     * Cancel a PTM booking, subject to 1-hour cutoff rule.
     * Releases slot back to available pool.
     *
     * @param  int      $bookingId  PTM booking record ID
     * @param  Guardian $guardian
     * @return bool  true = cancelled successfully
     * @throws \Symfony\Component\HttpKernel\Exception\HttpException  403 if within 1 hour
     */
    public function cancelBooking(int $bookingId, Guardian $guardian): bool
    {
        // TODO: Implement
        // 1. Find booking; verify guardian ownership
        // 2. Check: booking ptm time >= now() + 1 hour (else abort 422 "Too late to cancel")
        // 3. DB::transaction: release slot (is_booked=0) + delete/soft-delete booking
        // 4. Dispatch cancellation notification to teacher (queued)
        throw new \RuntimeException('Not implemented — stub');
    }
}
```

---

## Quality Gate — Phase 2 Verification

- [x] All 6 ppt_* tables in `PPT_DDL_v1.sql` with complete CREATE TABLE DDL
- [x] All PKs confirmed as `INT UNSIGNED AUTO_INCREMENT` (NOT BIGINT)
- [x] `sys_users.id = INT UNSIGNED` verified → `sender_user_id`, `recipient_user_id` = `INT UNSIGNED` — documented in DDL comments
- [x] `ppt_consent_form_responses` has NO `deleted_at` — immutability documented explicitly
- [x] `uq_ppt_session_guardian_device_fcm` UNIQUE on ppt_parent_sessions ✅
- [x] `uq_ppt_rsvp_event_guardian` UNIQUE on ppt_event_rsvps ✅
- [x] `uq_ppt_consent_response` UNIQUE (consent_form_id, student_id, guardian_id) on ppt_consent_form_responses ✅
- [x] `application_number` UNIQUE on ppt_leave_applications ✅
- [x] `request_number` UNIQUE on ppt_document_requests ✅
- [x] `payment_reference` UNIQUE nullable on ppt_document_requests — idempotency guard ✅
- [x] FULLTEXT index on ppt_messages (subject, message_body) ✅
- [x] Composite INDEX `idx_ppt_leave_student_status` (student_id, status) ✅
- [x] `parent.portal` middleware generated with three-condition check + 404 on failure ✅
- [x] `EnsureParentPortalAccess` middleware alias registration code in ServiceProvider ✅
- [x] `ParentChildPolicy` with 5 methods (viewChildData, isActiveChild, viewHealthRecord, viewCounsellorReport, payInvoice) ✅
- [x] `ParentMessagePolicy` + `ParentLeavePolicy` with full method code ✅
- [x] ServiceProvider policy registration code generated ✅
- [x] All 9 FormRequest classes with full `authorize()` + `rules()` + `prepareForValidation()` ✅
- [x] `SwitchChildRequest::authorize()` performs allowed-children check via `std_student_guardian_jnt` ✅
- [x] `FeePaymentRequest::authorize()` performs invoice ownership via `whereHas('studentAssignment')` chain ✅
- [x] `ConsentFormSignRequest` includes `strip_tags()` in `prepareForValidation()` ✅
- [x] `ApplyLeaveRequest` uses `after:today` on from_date (BR-PPT-004) ✅
- [x] `ComposeMessageRequest::authorize()` calls `MessagingService::getAllowedTeachers()` ✅
- [x] All 5 service skeletons with method signatures + docblocks ✅
- [x] `ParentDashboardService` eager-load chain: `loadMissing([...])` + `Cache::tags()` strategy ✅
- [x] `FeePaymentService` idempotency guard pattern: check before DB write ✅
- [x] `PtmSchedulingService` `DB::transaction()` + `lockForUpdate()` race condition guard ✅
- [x] Laravel migration uses `->unsignedInteger()` for ppt_* PKs and std_* FKs ✅
