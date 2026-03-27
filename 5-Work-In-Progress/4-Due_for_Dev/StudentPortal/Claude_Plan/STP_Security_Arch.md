# STP — Student Portal
## Security & Architecture Layer
**Version:** 1.0 | **Generated:** 2026-03-27
**Source:** STP_FeatureSpec.md + code audit of `Modules/StudentPortal/` on branch `Brijesh_Main`

---

> **⚠️ ACTUAL vs DOCUMENTED STATE — CRITICAL**
> The requirement v2 described `viewInvoice()` and `payDueAmount()` as having a "partial IDOR fix" (`where('student_id', ...)`). Actual committed code audit shows **ZERO ownership check** — both methods do plain `FeeInvoice::findOrFail($id)`. Additionally, the portal route group is missing `role:Student|Parent` middleware entirely. The fixes below address the actual committed code state, which is MORE vulnerable than the requirement described.

---

## Table of Contents

1. [Part 1 — Security Fixes (10 Fixes)](#part-1--security-fixes)
2. [Part 2 — FormRequest Classes (4 Classes)](#part-2--formrequest-classes)
3. [Part 3 — Policy & Service](#part-3--policy--service)

---

## Part 1 — Security Fixes

### DDL Confirmation: `fee_invoices.student_id` Column

**Grep result:** `CREATE TABLE fee_invoices` in `tenant_db_v2.sql`

```
fee_invoices columns:
  id, invoice_no, student_assignment_id (FK → fee_student_assignments.id),
  installment_id, invoice_date, due_date, base_amount, concession_amount,
  fine_amount, tax_amount, total_amount, paid_amount,
  balance_amount (GENERATED ALWAYS AS total_amount - paid_amount STORED),
  status ENUM('Draft','Published','Partially Paid','Paid','Overdue','Cancelled'),
  invoice_pdf_path, generated_by, cancelled_by, cancellation_reason,
  created_at, updated_at, deleted_at
```

**Verdict:** `fee_invoices` has **NO `student_id` column**. Ownership chain is:
`fee_invoices.student_assignment_id → fee_student_assignments.student_id → std_students.id`

All invoice ownership guards MUST use `whereHas('feeStudentAssignment', ...)` — never `where('student_id', ...)`.

---

### Fix 1 — IDOR: `proceedPayment()` (P0 — CRITICAL)

**File:** `Modules/StudentPortal/app/Http/Controllers/StudentPortalController.php`
**Issue:** `payable_id` is taken directly from client POST body with zero server-side ownership verification. Any authenticated student can trigger payment for another student's invoice.
**Additional:** Route is registered as `GET` — must be `POST`.

**Current (gap summary):**
```php
// Route: GET /pay-due-amount/proceed-payment  ← WRONG HTTP METHOD
public function proceedPayment(Request $request)
{
    $validated = $request->validate([...]);  // validates format only — no ownership check

    $response = $this->paymentService->createPayment([
        'payable_id' => $request->payable_id,  // ← CLIENT-CONTROLLED: P0 IDOR
        ...
    ]);
}
```

**Replacement (full method):**
```php
public function proceedPayment(ProcessPaymentRequest $request)
{
    // ProcessPaymentRequest::authorize() has already verified:
    //   - payable_id belongs to auth()->user()->student via feeStudentAssignment chain
    //   - invoice status is payable (Published / Partially Paid / Overdue)
    //   - balance_amount > 0
    // No need to re-fetch here; pass the verified payable_id through.

    $response = $this->paymentService->createPayment([
        'payable_type' => FeeInvoice::class,
        'payable_id'   => $request->payable_id,  // safe — ownership verified in FormRequest
        'gateway'      => $request->gateway,
        'amount'       => $request->amount,
        'currency'     => 'INR',
    ]);

    return view('payment::razorpay.process-payment', [
        'checkoutData' => $response['checkout_data'],
    ]);
}
```

**Route change required** in `routes/tenant.php`:
```php
// BEFORE (WRONG):
Route::get('/pay-due-amount/proceed-payment', [StudentPortalController::class, 'proceedPayment'])->name('proceed-payment');

// AFTER (CORRECT):
Route::post('/pay-due-amount/proceed-payment', [StudentPortalController::class, 'proceedPayment'])
    ->name('proceed-payment')
    ->middleware('throttle:3,5');
```

---

### Fix 2 — IDOR: `viewInvoice()` and `payDueAmount()` (P0 — CRITICAL)

**File:** `Modules/StudentPortal/app/Http/Controllers/StudentPortalController.php`
**Issue:** Both methods do bare `FeeInvoice::findOrFail($id)` — zero ownership check. Any authenticated user can view or initiate payment on any student's invoice.

**Private helper to add to `StudentPortalController`:**
```php
/**
 * Resolve a FeeInvoice that belongs to the authenticated student.
 * Uses the feeStudentAssignment chain because fee_invoices has NO direct student_id column.
 *
 * @throws \Illuminate\Database\Eloquent\ModelNotFoundException (404) if not found or not owned
 */
private function findStudentInvoice(int $invoiceId): FeeInvoice
{
    $studentId = auth()->user()->student->id;

    return FeeInvoice::whereHas('feeStudentAssignment',
        fn($q) => $q->where('student_id', $studentId)
    )->findOrFail($invoiceId);
}
```

**Updated `viewInvoice()`:**
```php
public function viewInvoice(int $id)
{
    $feeInvoice = $this->findStudentInvoice($id);
    $this->authorize('viewInvoice', $feeInvoice);  // StudentPortalPolicy

    return view('studentportal::academic-information.invoice', compact('feeInvoice'));
}
```

**Updated `payDueAmount()`:**
```php
public function payDueAmount(int $id)
{
    $feeInvoice = $this->findStudentInvoice($id);
    $this->authorize('payInvoice', $feeInvoice);  // StudentPortalPolicy — checks status + balance

    $paymentGateways = PaymentGateway::active()->get();  // Fix 5 applied here

    return view('studentportal::academic-information.payment-page', compact('feeInvoice', 'paymentGateways'));
}
```

---

### Fix 3 — Missing `role:Student|Parent` Middleware on Route Group (P0)

**File:** `routes/tenant.php`
**Issue:** The portal route group has only `['auth', 'verified']` middleware — ANY authenticated user (admin, teacher, staff) can access the student portal. `role:Student|Parent` is missing.

**Current:**
```php
Route::middleware(['auth', 'verified'])->prefix('student-portal')->name('student-portal.')->group(function () {
```

**Fixed:**
```php
Route::middleware(['auth', 'verified', 'role:Student|Parent'])->prefix('student-portal')->name('student-portal.')->group(function () {
```

> **Note:** This is an undocumented P0 finding from code audit — the requirement stated `role:Student|Parent` was already applied, but it is NOT in the committed code.

---

### Fix 4 — Missing `EnsureTenantHasModule:StudentPortal` Middleware (P0)

**File:** `routes/tenant.php`
**Issue:** No tenant module licensing check. Schools that have not subscribed to StudentPortal can still access it.

**Combined with Fix 3 (apply together):**
```php
Route::middleware([
    'auth',
    'verified',
    'role:Student|Parent',
    'EnsureTenantHasModule:StudentPortal',
])->prefix('student-portal')->name('student-portal.')->group(function () {
    // ... all portal routes
});
```

> **Middleware class location:** Ensure `EnsureTenantHasModule` is registered in `app/Http/Kernel.php` under `$routeMiddleware`. If it follows the pattern from other modules, the alias is `EnsureTenantHasModule` mapping to `App\Http\Middleware\EnsureTenantHasModule`.

---

### Fix 5 — `PaymentGateway::all()` → `::active()->get()` (P1)

**File:** `Modules/StudentPortal/app/Http/Controllers/StudentPortalController.php`
**Method:** `payDueAmount()`
**Issue:** Disabled/inactive payment gateways are shown to students.

```php
// BEFORE:
$paymentGateways = PaymentGateway::all();

// AFTER:
$paymentGateways = PaymentGateway::active()->get();
```

> **Assumption:** `PaymentGateway` model has a `scopeActive()` — the commented line `//  $paymentGateways = PaymentGateway::active()->get();` in the existing code confirms this scope exists.

---

### Fix 6 — Typo `currentFeeAssignemnt` → `currentFeeAssignment` (P1)

**Primary fix — STD module (NOT in STP):**
```
File: Modules/StudentProfile/app/Models/Student.php
Change: rename method currentFeeAssignemnt() → currentFeeAssignment()
⚠️ Coordinate with STD module team — this change affects any caller across the entire application.
```

**Callers in `StudentPortalController.php` to update (3 locations):**

```php
// BEFORE (line 55):
'student.currentFeeAssignemnt.feeStructure.details.head',

// AFTER:
'student.currentFeeAssignment.feeStructure.details.head',


// BEFORE (line 56):
'student.currentFeeAssignemnt.invoices',

// AFTER:
'student.currentFeeAssignment.invoices',


// BEFORE (line 59):
$assignment = $user->student->currentFeeAssignemnt;

// AFTER:
$assignment = $user->student->currentFeeAssignment;
```

> **Also update** `academicInformation()` — the eager load array at lines 55-56 and the variable assignment at line 59 all use the misspelled name.

---

### Fix 7 — Remove `test-notification` Route (P0)

**File:** `routes/tenant.php`
**Issue:** `test-notification` route is live in production — dispatches real notifications with hard-coded payload (`user_id: 35`).

```php
// REMOVE this line entirely:
Route::get('test-notification', [StudentPortalNotificationController::class, 'testNotification'])->name('test-notification');
```

> If the route must exist for local development, replace with:
> ```php
> if (app()->environment('local')) {
>     Route::get('test-notification', [StudentPortalNotificationController::class, 'testNotification'])->name('test-notification');
> }
> ```

---

### Fix 8 — `notifications/{id}/mark-read`: GET → POST/PATCH (P1)

**File:** `routes/tenant.php` + `Modules/StudentPortal/app/Http/Controllers/NotificationController.php`
**Issue:** GET route is vulnerable to pre-fetch attacks (browser link scanners, crawlers, and prefetch headers can silently mark all notifications as read before the student sees them).

**Route change:**
```php
// BEFORE:
Route::get('notifications/{id}/mark-read', [StudentPortalNotificationController::class, 'markRead'])->name('notifications.mark-read');

// AFTER:
Route::post('notifications/{id}/mark-read', [StudentPortalNotificationController::class, 'markRead'])
    ->name('notifications.mark-read')
    ->middleware('throttle:10,1');
```

**Blade update required** — any `<a href="{{ route('student-portal.notifications.mark-read', $id) }}">` links must become forms:
```html
<form method="POST" action="{{ route('student-portal.notifications.mark-read', $notification->id) }}" style="display:inline">
    @csrf
    <button type="submit" class="btn btn-sm btn-link">Mark Read</button>
</form>
```

**`NotificationController@markRead` — no change needed** (already correctly scopes to `auth()->user()->notifications()->findOrFail($id)`).

---

### Fix 9 — Rate Limiting on Payment Route (P1)

Already included in Fix 1 route change (`->middleware('throttle:3,5')`).

Additionally, add rate limiting to the login POST route. Locate the login POST route (likely in `routes/tenant.php` or `routes/web.php`) and add:

```php
// Find the login POST route for student portal and add throttle:
Route::post('/student-portal/login', [StudentPortalController::class, 'login'])
    ->name('student-portal.login.post')
    ->middleware('throttle:5,2');
```

> If login is handled by Fortify/Breeze (shared with admin), add the throttle via a route middleware group or a dedicated route override.

---

### Fix 10 — Remove Scaffold Stub Methods from `StudentPortalController` (P1)

**File:** `Modules/StudentPortal/app/Http/Controllers/StudentPortalController.php`
**Issue:** 7 unused resource scaffold methods exist at the bottom of the controller. They return stub views and pollute the route namespace via the `Route::resource('studentportals', ...)` in the module's own `routes/web.php`.

**Methods to DELETE (lines ~119–171):**

| Method | Current Body | Remove? |
|---|---|---|
| `index()` | `return view('studentportal::index')` | ✅ Remove |
| `create()` | `return view('studentportal::create')` | ✅ Remove |
| `store(Request $request)` | Empty body | ✅ Remove |
| `show($id)` | `return view('studentportal::show')` | ✅ Remove |
| `edit($id)` | `return view('studentportal::edit')` | ✅ Remove |
| `update(Request $request, $id)` | Empty body | ✅ Remove |
| `destroy($id)` | Empty body | ✅ Remove |

**Also remove** the scaffold `Route::resource(...)` from `Modules/StudentPortal/routes/web.php`:
```php
// REMOVE from routes/web.php:
Route::middleware(['auth', 'verified'])->group(function () {
    Route::resource('studentportals', StudentPortalController::class)->names('studentportal');
});
```

> All real portal routes live in `routes/tenant.php` — the module's `web.php` was never wired into the portal's route prefix.

---

## Part 2 — FormRequest Classes

### FormRequest 1: `StoreComplaintRequest` (P1)

**File:** `Modules/StudentPortal/app/Http/Requests/StoreComplaintRequest.php`
**Replaces:** Inline `$request->validate()` + `$request->merge()` anti-pattern in `StudentPortalComplaintController@store`

```php
<?php

namespace Modules\StudentPortal\app\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Support\Facades\DB;

class StoreComplaintRequest extends FormRequest
{
    /**
     * Authorize: only students can submit complaints.
     */
    public function authorize(): bool
    {
        return auth()->check() && auth()->user()->hasRole('Student');
    }

    /**
     * Resolve dropdown IDs from sys_dropdowns and force complainant_user_id
     * to the authenticated user — never trust client-submitted user IDs.
     */
    protected function prepareForValidation(): void
    {
        $complainantTypeId = DB::table('sys_dropdowns')
            ->where('key', 'complainant_type')
            ->where('value', $this->complainant_type_id)
            ->value('id');

        $targetTypeId = DB::table('sys_dropdowns')
            ->where('key', 'target_user_type')
            ->where('value', $this->target_type_id)
            ->value('id');

        $this->merge([
            'complainant_type_id'  => $complainantTypeId,
            'target_type_id'       => $targetTypeId,
            'complainant_user_id'  => auth()->id(),  // Force — never accept from client
            'description'          => strip_tags($this->description ?? ''),  // Prevent HTML injection
        ]);
    }

    /**
     * Validation rules.
     */
    public function rules(): array
    {
        return [
            'target_type_id'      => ['required', 'exists:sys_dropdowns,id'],
            'complainant_type_id' => ['required', 'exists:sys_dropdowns,id'],
            'category_id'         => ['required', 'exists:cmp_complaint_categories,id'],
            'subcategory_id'      => ['nullable', 'exists:cmp_complaint_categories,id'],
            'severity_level_id'   => ['required'],
            'priority_score_id'   => ['nullable'],
            'title'               => ['required', 'string', 'max:200'],
            'description'         => ['nullable', 'string', 'max:2000'],
            'location_details'    => ['nullable', 'string', 'max:255'],
            'incident_date'       => ['nullable', 'date'],
            'complaint_img'       => ['nullable', 'file', 'mimes:jpg,jpeg,png,pdf', 'max:5120'],
        ];
    }

    public function messages(): array
    {
        return [
            'category_id.required'    => 'Please select a complaint category.',
            'title.required'          => 'Please provide a brief title for your complaint.',
            'complaint_img.mimes'     => 'Attachment must be a JPG, PNG, or PDF file.',
            'complaint_img.max'       => 'Attachment size must not exceed 5 MB.',
        ];
    }
}
```

**Usage in `StudentPortalComplaintController@store`:**
```php
// BEFORE:
public function store(Request $request) { $request->merge([...]); $request->validate([...]); }

// AFTER:
public function store(StoreComplaintRequest $request)
{
    // Authorization and validation already done by FormRequest.
    // $request->complainant_user_id is guaranteed to be auth()->id()
    // $request->description is already strip_tags'd
    // No need for the hard-coded ID 104 check — sys_dropdowns key resolved in prepareForValidation

    DB::beginTransaction();
    try {
        // ... ticket number generation (unchanged) ...

        $complaint = Complaint::create([
            'ticket_no'           => $ticketNo,
            'ticket_date'         => now(),
            'target_type_id'      => $request->target_type_id,
            'complainant_type_id' => $request->complainant_type_id,
            'complainant_user_id' => $request->complainant_user_id,  // = auth()->id()
            'complainant_name'    => null,  // Portal complaints always identified
            // ... rest of fields ...
            'created_by'          => auth()->id(),
            'status_id'           => $statusId,
        ]);

        // ... media upload (unchanged) ...

        DB::commit();
        return redirect()->route('student-portal.complaint.index')
            ->with('success', "Complaint Lodged. Ticket No: {$ticketNo}");
    } catch (\Exception $e) {
        DB::rollBack();
        return back()->withInput()->with('error', 'Something went wrong. Please try again.');
    }
}
```

> **Note on anonymous complaints:** The portal is for authenticated students — complainant is always identified. The hard-coded ID `104` branch for "Anonymous" is no longer needed from the portal. If anonymous complaints are needed, they should come from a public (unauthenticated) endpoint, not the student portal.

---

### FormRequest 2: `ProcessPaymentRequest` (P0)

**File:** `Modules/StudentPortal/app/Http/Requests/ProcessPaymentRequest.php`
**Replaces:** Inline `$request->validate()` in `StudentPortalController@proceedPayment`
**Key responsibility:** Performs the IDOR ownership check in `authorize()` so the controller is clean.

```php
<?php

namespace Modules\StudentPortal\app\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Modules\StudentFee\Models\FeeInvoice;

class ProcessPaymentRequest extends FormRequest
{
    /**
     * Verify that the payable_id belongs to the authenticated student
     * via the feeStudentAssignment chain.
     *
     * fee_invoices has NO direct student_id column — ownership is via:
     *   fee_invoices.student_assignment_id → fee_student_assignments.student_id
     *
     * @throws \Illuminate\Auth\Access\AuthorizationException (403)
     */
    public function authorize(): bool
    {
        $student = auth()->user()?->student;

        if (!$student) {
            return false;
        }

        $invoice = FeeInvoice::whereHas('feeStudentAssignment',
            fn($q) => $q->where('student_id', $student->id)
        )->find((int) $this->payable_id);

        if (!$invoice) {
            return false;  // Invoice does not exist or does not belong to this student → 403
        }

        if (!in_array($invoice->status, ['Published', 'Partially Paid', 'Overdue'])) {
            abort(422, 'This invoice is not payable.');
        }

        if ($invoice->balance_amount <= 0) {
            abort(422, 'This invoice has already been fully paid.');
        }

        return true;
    }

    /**
     * Validation rules.
     */
    public function rules(): array
    {
        return [
            'amount'       => ['required', 'numeric', 'min:0.01'],
            'payable_type' => ['required', 'string', 'in:fee_invoice'],
            'payable_id'   => ['required', 'integer', 'min:1'],
            'gateway'      => ['required', 'string', 'in:razorpay,stripe,paytm,phonepe'],
        ];
    }

    public function messages(): array
    {
        return [
            'amount.min'         => 'Minimum payment amount is ₹1.',
            'gateway.in'         => 'Please select a valid payment gateway.',
            'payable_id.required'=> 'Invoice reference is missing. Please go back and try again.',
        ];
    }
}
```

---

### FormRequest 3: `LeaveApplicationRequest` (P2 — Design Only)

**File:** `Modules/StudentPortal/app/Http/Requests/LeaveApplicationRequest.php`
**Note:** Only implemented when the leave application feature is built (Phase P2).

```php
<?php

namespace Modules\StudentPortal\app\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class LeaveApplicationRequest extends FormRequest
{
    public function authorize(): bool
    {
        return auth()->check() && auth()->user()->hasRole('Student|Parent');
    }

    public function rules(): array
    {
        return [
            'leave_type'   => ['required', 'string'],
            'start_date'   => ['required', 'date', 'after_or_equal:today'],
            'end_date'     => ['required', 'date', 'after_or_equal:start_date'],
            'reason'       => ['required', 'string', 'max:1000'],
            'attachment'   => ['nullable', 'file', 'mimes:jpg,jpeg,png,pdf', 'max:5120'],
        ];
    }

    protected function prepareForValidation(): void
    {
        $this->merge([
            'reason' => strip_tags($this->reason ?? ''),
        ]);
    }
}
```

> **Prerequisite:** Verify whether `std_leave_applications` table exists in `tenant_db_v2.sql`. If not, a migration is required before this FormRequest can be used.

---

### FormRequest 4: `PasswordChangeRequest` (P2 — Design Only)

**File:** `Modules/StudentPortal/app/Http/Requests/PasswordChangeRequest.php`
**Note:** Only implemented when account settings password-change tab is wired.

```php
<?php

namespace Modules\StudentPortal\app\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rules\Password;

class PasswordChangeRequest extends FormRequest
{
    public function authorize(): bool
    {
        return auth()->check();
    }

    public function rules(): array
    {
        return [
            'current_password' => [
                'required',
                function ($attribute, $value, $fail) {
                    if (!Hash::check($value, auth()->user()->password)) {
                        $fail('The current password is incorrect.');
                    }
                },
            ],
            'password' => [
                'required',
                'confirmed',
                Password::min(8)->mixedCase()->numbers(),
            ],
        ];
    }

    public function messages(): array
    {
        return [
            'password.confirmed' => 'New password and confirmation do not match.',
        ];
    }
}
```

---

## Part 3 — Policy & Service

### StudentPortalPolicy

**File:** `Modules/StudentPortal/app/Policies/StudentPortalPolicy.php`
**Register in:** `Modules/StudentPortal/app/Providers/StudentPortalServiceProvider.php`

```php
<?php

namespace Modules\StudentPortal\app\Policies;

use App\Models\User;
use Modules\StudentFee\Models\FeeInvoice;

class StudentPortalPolicy
{
    /**
     * Determine if the authenticated user may view the given invoice.
     *
     * Uses feeStudentAssignment chain because fee_invoices has NO direct student_id column.
     * Safe guard: works regardless of schema changes to fee_invoices.
     */
    public function viewInvoice(User $user, FeeInvoice $invoice): bool
    {
        if (!$user->student) {
            return false;
        }

        return $invoice->feeStudentAssignment()
            ->where('student_id', $user->student->id)
            ->exists();
    }

    /**
     * Determine if the authenticated user may initiate payment on the given invoice.
     *
     * Requires: ownership + payable status + outstanding balance.
     */
    public function payInvoice(User $user, FeeInvoice $invoice): bool
    {
        return $this->viewInvoice($user, $invoice)
            && in_array($invoice->status, ['Published', 'Partially Paid', 'Overdue'])
            && $invoice->balance_amount > 0;
    }

    /**
     * Determine if the authenticated user may create a complaint from the portal.
     */
    public function createComplaint(User $user): bool
    {
        return $user->hasRole('Student');
    }
}
```

**Registration in `StudentPortalServiceProvider@boot()`:**
```php
<?php

namespace Modules\StudentPortal\app\Providers;

use Illuminate\Support\Facades\Gate;
use Illuminate\Support\ServiceProvider;
use Modules\StudentFee\Models\FeeInvoice;
use Modules\StudentPortal\app\Policies\StudentPortalPolicy;

class StudentPortalServiceProvider extends ServiceProvider
{
    public function boot(): void
    {
        Gate::policy(FeeInvoice::class, StudentPortalPolicy::class);
    }
}
```

---

### StudentPortalService

**File:** `Modules/StudentPortal/app/Services/StudentPortalService.php`
**Purpose:** Extract heavy dashboard aggregation and repeated query logic from `StudentPortalController` (currently ~110+ lines in `dashboard()` alone in the uncommitted version). Keep controllers thin.

```php
<?php

namespace Modules\StudentPortal\app\Services;

use Carbon\Carbon;
use Modules\LmsExam\Models\ExamAllocation;
use Modules\LmsHomework\Models\Homework;
use Modules\SmartTimetable\Models\TimetableCell;
use Modules\SmartTimetable\Models\SchoolDay;
use Modules\StudentProfile\Models\Student;
use Modules\StudentProfile\Models\StudentAttendance;

class StudentPortalService
{
    /**
     * Load all data needed for the student dashboard in a consolidated query chain.
     *
     * Current state (uncommitted): ~6 separate queries executed sequentially in dashboard().
     * After refactor: 1 eager-load chain + 4 scoped aggregate queries.
     *
     * @return array{
     *   attendanceStats: array,
     *   todayTimetable: \Illuminate\Support\Collection,
     *   pendingHomework: \Illuminate\Support\Collection,
     *   upcomingExams: \Illuminate\Support\Collection,
     *   feeSummary: array,
     *   session: \Modules\StudentProfile\Models\StudentAcademicSession|null
     * }
     */
    public function getDashboardData(Student $student): array
    {
        // Step 1: Single eager-load chain — no N+1
        $student->loadMissing([
            'currentSession.classSection.class',
            'currentSession.classSection.section',
            'currentFeeAssignment.invoices',
            'healthProfile',
        ]);

        $session    = $student->currentSession;
        $classId    = $session?->classSection?->class?->id;
        $sectionId  = $session?->classSection?->section?->id;
        $sessionId  = $session?->id;

        // Step 2: Attendance aggregate (1 query)
        $attendanceStats = $this->getAttendanceSummary($student, $sessionId);

        // Step 3: Today's timetable (1 query)
        $todayDayOfWeek  = Carbon::now()->dayOfWeekIso; // 1=Mon ... 7=Sun
        $todayTimetable  = collect();
        if ($classId && $sectionId) {
            $todayTimetable = TimetableCell::with(['subject', 'teacher'])
                ->where('class_id', $classId)
                ->where('section_id', $sectionId)
                ->whereIn('timetable_status', ['ACTIVE', 'GENERATED', 'PUBLISHED'])
                ->where('day_of_week', $todayDayOfWeek)
                ->where('is_break', false)
                ->orderBy('period_ord')
                ->get();
        }

        // Step 4: Pending homework — top 5 (1 query)
        $pendingHomework = collect();
        if ($classId && $sectionId) {
            $pendingHomework = Homework::with('subject')
                ->whereHas('scopePublished') // Use scope equivalent
                ->where('class_id', $classId)
                ->where('section_id', $sectionId)
                ->whereDoesntHave('submissions', fn($q) => $q->where('student_id', $student->id))
                ->orderBy('due_date')
                ->limit(5)
                ->get();
        }

        // Step 5: Upcoming exams — top 5 (1 query)
        $upcomingExams = collect();
        if ($classId && $sectionId) {
            $upcomingExams = ExamAllocation::with(['examPaper.exam'])
                ->where('status', 'PUBLISHED')
                ->where(function ($q) use ($classId, $sectionId, $student) {
                    $q->where(fn($q) => $q->where('target_type', 'CLASS')->where('target_id', $classId))
                      ->orWhere(fn($q) => $q->where('target_type', 'SECTION')->where('target_id', $sectionId))
                      ->orWhere(fn($q) => $q->where('target_type', 'STUDENT')->where('target_id', $student->id));
                })
                ->where('scheduled_date', '>=', today())
                ->orderBy('scheduled_date')
                ->limit(5)
                ->get();
        }

        // Step 6: Fee summary from already eager-loaded relationship (0 extra queries)
        $feeSummary = $this->getFeeSummary($student);

        return compact(
            'attendanceStats',
            'todayTimetable',
            'pendingHomework',
            'upcomingExams',
            'feeSummary',
            'session'
        );
    }

    /**
     * Compute attendance summary for a student in a session.
     * Normalizes inconsistent status casing (P/Present/present, A/Absent/absent, etc.)
     *
     * @return array{total: int, present: int, absent: int, late: int, leave: int, percentage: float, byMonth: array}
     */
    public function getAttendanceSummary(Student $student, ?int $sessionId): array
    {
        $records = StudentAttendance::where('student_id', $student->id)
            ->when($sessionId, fn($q) => $q->where('academic_session_id', $sessionId))
            ->get(['status', 'attendance_date']);

        $counts = ['total' => 0, 'present' => 0, 'absent' => 0, 'late' => 0, 'leave' => 0];
        $byMonth = [];

        foreach ($records as $r) {
            $counts['total']++;
            $normalizedStatus = $this->normalizeAttendanceStatus($r->status);
            $counts[$normalizedStatus] = ($counts[$normalizedStatus] ?? 0) + 1;

            $monthKey = Carbon::parse($r->attendance_date)->format('F Y');
            $byMonth[$monthKey][$normalizedStatus] = ($byMonth[$monthKey][$normalizedStatus] ?? 0) + 1;
            $byMonth[$monthKey]['total'] = ($byMonth[$monthKey]['total'] ?? 0) + 1;
        }

        $counts['percentage'] = $counts['total'] > 0
            ? round(($counts['present'] / $counts['total']) * 100, 1)
            : 0.0;

        $counts['byMonth'] = $byMonth;

        return $counts;
    }

    /**
     * Compute fee summary from the already eager-loaded feeAssignment.
     * Call only after getDashboardData() or after loading currentFeeAssignment.invoices.
     *
     * @return array{totalFee: float, paidAmount: float, balanceDue: float, pendingCount: int, invoices: Collection}
     */
    public function getFeeSummary(Student $student): array
    {
        $invoices = $student->currentFeeAssignment?->invoices ?? collect();

        return [
            'totalFee'     => $invoices->sum('total_amount'),
            'paidAmount'   => $invoices->sum('paid_amount'),
            'balanceDue'   => $invoices->sum('balance_amount'),
            'pendingCount' => $invoices->whereIn('status', ['Published', 'Partially Paid', 'Overdue'])->count(),
            'invoices'     => $invoices,
        ];
    }

    /**
     * Build syllabus progress grouped by subject.
     * Status derived from scheduled dates vs today (no status column on syllabus_schedules).
     *
     * @return array<string, array{subject: string, total: int, completed: int, inProgress: int, upcoming: int, percentage: float, topics: array}>
     */
    public function getSyllabusProgress(Student $student, int $classId, int $sectionId, int $sessionId): array
    {
        $schedules = \Modules\Syllabus\Models\SyllabusSchedule::with('subject', 'topic')
            ->where('class_id', $classId)
            ->where('section_id', $sectionId)
            ->where('academic_session_id', $sessionId)
            ->get();

        $today = today();
        $grouped = [];

        foreach ($schedules as $s) {
            $subjectName = $s->subject?->name ?? 'Unknown';

            $status = match(true) {
                $s->scheduled_date < $today  => 'completed',
                $s->scheduled_date->isToday()=> 'in_progress',
                default                       => 'upcoming',
            };

            $grouped[$subjectName]['subject']    = $subjectName;
            $grouped[$subjectName]['topics'][]   = ['topic' => $s->topic?->name, 'status' => $status, 'date' => $s->scheduled_date];
            $grouped[$subjectName]['total']       = ($grouped[$subjectName]['total'] ?? 0) + 1;
            $grouped[$subjectName][$status]       = ($grouped[$subjectName][$status] ?? 0) + 1;
        }

        foreach ($grouped as &$subject) {
            $subject['in_progress'] = $subject['in_progress'] ?? 0;
            $subject['upcoming']    = $subject['upcoming'] ?? 0;
            $subject['completed']   = $subject['completed'] ?? 0;
            $subject['percentage']  = $subject['total'] > 0
                ? round(($subject['completed'] / $subject['total']) * 100, 1)
                : 0.0;
        }

        return $grouped;
    }

    /**
     * Normalize inconsistent attendance status values across the codebase.
     * Maps: P/Present/present → 'present' | A/Absent/absent → 'absent' |
     *       L/Late/late → 'late' | leave/On Leave/Leave → 'leave'
     */
    private function normalizeAttendanceStatus(string $status): string
    {
        return match(strtolower(trim($status))) {
            'p', 'present'              => 'present',
            'a', 'absent'               => 'absent',
            'l', 'late'                 => 'late',
            'leave', 'on leave'         => 'leave',
            default                     => 'absent',
        };
    }
}
```

**Thin controller usage after service extraction:**
```php
// In StudentPortalController@dashboard:
public function __construct(
    protected PaymentService $paymentService,
    protected StudentPortalService $portalService,  // inject service
) {}

public function dashboard()
{
    $student       = auth()->user()->student;
    $dashboardData = $this->portalService->getDashboardData($student);
    $notifications = auth()->user()->notifications()->latest()->paginate(10);

    return view('studentportal::dashboard.index', array_merge($dashboardData, compact('notifications')));
}
```

---

## Appendix — Files to Create / Modify Summary

### New Files to Create

| File | Priority | Section |
|---|---|---|
| `Modules/StudentPortal/app/Http/Requests/ProcessPaymentRequest.php` | P0 | Part 2, FormRequest 2 |
| `Modules/StudentPortal/app/Policies/StudentPortalPolicy.php` | P0 | Part 3 |
| `Modules/StudentPortal/app/Http/Requests/StoreComplaintRequest.php` | P1 | Part 2, FormRequest 1 |
| `Modules/StudentPortal/app/Services/StudentPortalService.php` | P1 | Part 3 |
| `Modules/StudentPortal/app/Http/Requests/LeaveApplicationRequest.php` | P2 | Part 2, FormRequest 3 |
| `Modules/StudentPortal/app/Http/Requests/PasswordChangeRequest.php` | P2 | Part 2, FormRequest 4 |

### Files to Modify

| File | Fix(es) | Priority |
|---|---|---|
| `routes/tenant.php` | Fix 1 (POST route + throttle), Fix 3 (role middleware), Fix 4 (EnsureTenantHasModule), Fix 7 (remove test-notification), Fix 8 (mark-read GET→POST), Fix 9 (login throttle) | P0/P1 |
| `Modules/StudentPortal/app/Http/Controllers/StudentPortalController.php` | Fix 1 (proceedPayment), Fix 2 (viewInvoice/payDueAmount + helper), Fix 5 (PaymentGateway::active), Fix 6 (typo callers), Fix 10 (remove 7 stubs), inject StudentPortalService | P0/P1 |
| `Modules/StudentPortal/app/Http/Controllers/StudentPortalComplaintController.php` | Fix 4 (ID 104 → FormRequest), use StoreComplaintRequest, paginate complaints | P1 |
| `Modules/StudentPortal/app/Providers/StudentPortalServiceProvider.php` | Register StudentPortalPolicy | P0 |
| `Modules/StudentPortal/routes/web.php` | Remove Resource route | P1 |
| `Modules/StudentProfile/app/Models/Student.php` | Fix 6 (rename typo — coordinate with STD team) | P1 |
