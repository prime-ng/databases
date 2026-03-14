# HPC: Send Report Card to Guardian via Email (Queued)

**Date:** 2026-03-13
**Type:** Development (new feature)
**Module:** HPC (Holistic Progress Card)
**Priority:** High
**Files to create/modify:**
- `Modules/Hpc/resources/views/student-list/index.blade.php` — add button + AJAX
- `Modules/Hpc/app/Http/Controllers/HpcController.php` — add `sendReportEmail()` method
- `Modules/Hpc/app/Jobs/SendHpcReportEmail.php` — NEW
- `Modules/Hpc/app/Mail/HpcReportMail.php` — NEW
- `Modules/Hpc/resources/views/emails/hpc-report.blade.php` — NEW
- `routes/tenant.php` — add one new route

---

## Task

Add a per-student **"Send Email"** action button in the HPC student list table. When clicked:

1. The student's class is used to resolve the correct HPC template (same logic that already exists).
2. A PDF of the student's report card is generated using `buildPdf()`.
3. The PDF is emailed to **all guardians** of the student who have a non-empty `email` field in `std_guardians`.
4. Step 2 and 3 run **inside a Laravel queued Job** — the HTTP response returns immediately with "Queued successfully", the PDF generation and email sending happen in the background.

---

## Pre-Read (mandatory before coding)

Read these files **in full** before making any changes:

1. `Modules/Hpc/resources/views/student-list/index.blade.php` — Full file (237 lines + scripts). Note:
   - Per-row action buttons in `<td>` at line 103: currently has view, view-form, download buttons
   - The `$templateId` resolution logic (lines 104–192) already computes the template per student using class ordinal and name fallback
   - `$url` built at line 194 uses `route('hpc.hpc-form', ...)`
   - The AJAX `#generate-report` handler at line 324 sends `student_ids[]` + `academic_term_id` via POST
   - `<meta name="csrf-token">` is at line 237

2. `Modules/Hpc/app/Http/Controllers/HpcController.php` — Read:
   - `resolveTemplateId()` method — already encapsulates the template ID logic
   - `generateSingleStudentPdf()` method (~line 1847–2163): the **full PDF generation flow** — student load, siblings, template load, saved values, HTML render, `buildPdf()` — this is the reference pattern for the Job
   - `buildPdf(string $html)` private method (~line 2221): wraps DomPDF, returns a PDF object with `->output()`
   - `minifyHtml(string $html)` private method: strips whitespace before passing to DomPDF
   - Storage path pattern: `storage_path('app/public/hpc-reports/pdf/')` for filesystem, `tenant_asset('storage/hpc-reports/pdf/')` for URL
   - Imports at top of file: `use Modules\StudentProfile\Models\Guardian;`, `use Modules\StudentProfile\Models\StudentGuardianJnt;`

3. `Modules\StudentProfile\app\Models\Guardian.php` — Note:
   - Table: `std_guardians`
   - Key field: `email` (nullable string)
   - Has `first_name`, `last_name` fields

4. `routes/tenant.php` — Find the existing HPC route group at line ~2360:
   ```php
   Route::middleware(['auth', 'verified'])->prefix('hpc')->name('hpc.')->group(function () {
       Route::post('/generate-report', [HpcController::class, 'generateReportPdf'])->name('generate-report');
       // add new route here
   });
   ```

---

## Architecture: How the Feature Works

```
[User clicks "Send Email" button on student row]
         ↓
[AJAX POST to /hpc/send-report-email]
{student_id, academic_term_id}
         ↓
[HpcController::sendReportEmail()]
  - Validate student_id, academic_term_id
  - Load student + guardians
  - Check guardian emails exist
  - Dispatch SendHpcReportEmail::dispatch($studentId, $academicTermId, $tenantId)->onQueue('emails')
         ↓
[Return JSON {success:true, message:'Report queued for email delivery'}]

============= QUEUE WORKER (background) =============

[SendHpcReportEmail Job::handle()]
  - Initialize tenancy for $tenantId
  - Load student, template, saved values (same as generateSingleStudentPdf)
  - Render HTML via View::make(...)
  - Build PDF via DomPDF: $pdf->output()
  - Save PDF to storage temporarily
  - Load guardian emails from std_guardians via StudentGuardianJnt
  - Send HpcReportMail to each guardian email (with PDF attached)
  - Log success/failure per guardian
```

---

## Implementation

### Step 1 — Create the Job: `SendHpcReportEmail.php`

**File:** `Modules/Hpc/app/Jobs/SendHpcReportEmail.php` (create new)

```php
<?php

namespace Modules\Hpc\Jobs;

use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\View;
use Modules\Hpc\Http\Controllers\HpcController;
use Modules\Hpc\Mail\HpcReportMail;
use Modules\Hpc\Models\HpcReport;
use Modules\Hpc\Models\HpcTemplates;
use Modules\Hpc\Services\HpcReportService;
use Modules\StudentProfile\Models\Guardian;
use Modules\StudentProfile\Models\StudentGuardianJnt;
use App\Models\Organization;

// Import the Student model — use the same namespace as HpcController uses
use Modules\StudentProfile\Models\Student;

class SendHpcReportEmail implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $tries = 3;
    public int $timeout = 300; // 5 min — PDF generation can be slow

    public function __construct(
        public readonly int    $studentId,
        public readonly int    $academicTermId,
        public readonly string $tenantId,
    ) {}

    public function handle(): void
    {
        // 1. Initialize tenancy
        tenancy()->initialize($this->tenantId);

        try {
            $this->processAndSend();
        } finally {
            tenancy()->end();
        }
    }

    private function processAndSend(): void
    {
        $studentId     = $this->studentId;
        $academicTermId = $this->academicTermId;

        // 2. Load student (same eager-load as generateSingleStudentPdf)
        $studentDetails = Student::with([
            'details', 'studentDetail', 'profile', 'addresses',
            'guardians', 'studentGuardianJnts', 'sessions',
            'academicSessions', 'currentAcademicSession',
            'currentClassSection.class',
        ])->find($studentId);

        if (!$studentDetails) {
            Log::error("SendHpcReportEmail: Student {$studentId} not found.");
            return;
        }

        // 3. Resolve guardian emails
        $guardianIds = StudentGuardianJnt::where('student_id', $studentId)
            ->pluck('guardian_id')
            ->toArray();

        if (empty($guardianIds)) {
            Log::warning("SendHpcReportEmail: No guardians for student {$studentId}.");
            return;
        }

        $guardians = Guardian::whereIn('id', $guardianIds)
            ->whereNotNull('email')
            ->where('email', '!=', '')
            ->get();

        if ($guardians->isEmpty()) {
            Log::warning("SendHpcReportEmail: No guardian email for student {$studentId}.");
            return;
        }

        // 4. Resolve template (same logic as resolveTemplateId in HpcController)
        $hpcController = new HpcController();
        $templateId = $hpcController->resolveTemplateId($studentDetails);

        if (!$templateId) {
            Log::error("SendHpcReportEmail: No template for student {$studentId}.");
            return;
        }

        // 5. Load template
        $template = HpcTemplates::with([
            'parts'                        => fn($q) => $q->where('is_active', 1)->orderBy('page_no')->orderBy('display_order'),
            'parts.sections'               => fn($q) => $q->where('is_active', 1)->orderBy('display_order'),
            'parts.sections.rubrics'       => fn($q) => $q->where('is_active', 1)->orderBy('display_order'),
            'parts.sections.rubrics.items' => fn($q) => $q->where('is_active', 1)->orderBy('ordinal'),
        ])->find($templateId);

        if (!$template) {
            Log::error("SendHpcReportEmail: Template {$templateId} not found.");
            return;
        }

        // 6. Load saved values (same as generateSingleStudentPdf)
        $service = new HpcReportService();
        $organization = Organization::first();

        $savedValues    = [];
        $savedTableData = [];
        $illnessTotal   = [];
        $attendanceSummary = ['working' => 0, 'present' => 0];

        $hpcReport = HpcReport::where('student_id', $studentId)
            ->where('academic_term_id', $academicTermId)
            ->first();

        if ($hpcReport) {
            // Load saved report items
            $savedValues = \Modules\Hpc\Models\HpcReportItem::where('hpc_report_id', $hpcReport->id)
                ->pluck('value', 'html_object_name')
                ->toArray();

            $savedTableData = \Modules\Hpc\Models\HpcReportTable::where('hpc_report_id', $hpcReport->id)
                ->get()
                ->mapWithKeys(fn($row) => [
                    $row->section_id . '_' . $row->row_id . '_' . $row->column_id => $row->value
                ])
                ->toArray();
        }

        // 7. Sibling data (same as generateSingleStudentPdf)
        try {
            $sibGuardianIds = StudentGuardianJnt::where('student_id', $studentId)
                ->pluck('guardian_id')->toArray();
            if (!empty($sibGuardianIds)) {
                $siblingIds = StudentGuardianJnt::whereIn('guardian_id', $sibGuardianIds)
                    ->where('student_id', '!=', $studentId)
                    ->pluck('student_id')->unique()->toArray();
                $siblingAges = Student::whereIn('id', $siblingIds)->get(['dob'])
                    ->filter(fn($s) => !empty($s->dob))
                    ->map(fn($s) => (new \DateTime($s->dob))->diff(new \DateTime('today'))->y)
                    ->values()->toArray();
                if ($studentDetails->details) {
                    $studentDetails->details->siblings_count = count($siblingIds);
                    $studentDetails->details->siblings_age   = implode(',', $siblingAges);
                }
            }
        } catch (\Throwable $e) {
            Log::warning("SendHpcReportEmail: sibling data failed for {$studentId}: " . $e->getMessage());
        }

        // 8. Render HTML — choose view by templateId
        $viewMap = [1 => 'hpc::hpc_form.pdf.first_pdf', 2 => 'hpc::hpc_form.pdf.second_pdf', 3 => 'hpc::hpc_form.pdf.third_pdf', 4 => 'hpc::hpc_form.pdf.fourth_pdf'];
        $viewName = $viewMap[$templateId] ?? null;
        if (!$viewName) {
            Log::error("SendHpcReportEmail: No view for templateId {$templateId}.");
            return;
        }

        $html = View::make($viewName, [
            'studentDetails'    => $studentDetails,
            'savedValues'       => $savedValues,
            'savedTableData'    => $savedTableData,
            'template'          => $template,
            'organization'      => $organization,
            'attendanceSummary' => $attendanceSummary,
            'illnessTotal'      => $illnessTotal,
            'academic_term_id'  => $academicTermId,
        ])->render();

        // 9. Build PDF
        $pdf = $hpcController->buildPdfPublic($hpcController->minifyHtmlPublic($html));

        // 10. Save PDF to storage
        $filename    = 'HPC_student_' . $studentId . '_' . now()->format('Ymd_His') . '.pdf';
        $storagePath = 'hpc-reports/pdf/' . $filename;
        Storage::disk('public')->makeDirectory('hpc-reports/pdf');
        Storage::disk('public')->put($storagePath, $pdf->output());
        $pdfFullPath = storage_path('app/public/' . $storagePath);

        // 11. Send email to each guardian
        $studentName = trim(($studentDetails->first_name ?? '') . ' ' . ($studentDetails->last_name ?? ''));

        foreach ($guardians as $guardian) {
            try {
                Mail::to($guardian->email)
                    ->send(new HpcReportMail($studentDetails, $guardian, $pdfFullPath, $filename));

                Log::info("SendHpcReportEmail: Sent to {$guardian->email} for student {$studentId}.");
            } catch (\Throwable $e) {
                Log::error("SendHpcReportEmail: Mail failed to {$guardian->email} for student {$studentId}: " . $e->getMessage());
            }
        }

        // 12. Optionally clean up the saved PDF after sending (uncomment if disk space is a concern)
        // Storage::disk('public')->delete($storagePath);
    }

    public function failed(\Throwable $exception): void
    {
        Log::error("SendHpcReportEmail Job FAILED for student {$this->studentId}: " . $exception->getMessage());
    }
}
```

**Important note about `buildPdf` and `minifyHtml`:**
These are `private` methods on `HpcController`. Before implementing the Job, change their visibility to `public` in `HpcController.php`:

```php
// In HpcController.php — change private to public:
public function buildPdfPublic(string $html): \Barryvdh\DomPDF\PDF
{
    return $this->buildPdf($html);
}

public function minifyHtmlPublic(string $html): string
{
    return $this->minifyHtml($html);
}
```

OR — extract PDF generation into a **protected helper method** on the controller that the Job can call via `app(HpcController::class)`. The simplest approach: make `buildPdf` and `minifyHtml` `public` (they have no security concern — they just process a string).

**Alternative (cleaner):** Extract the PDF-build logic into `HpcReportService::buildPdf()` so the Job can call the service directly without depending on the controller. If `HpcReportService` already has the DomPDF logic, use that. If not, add it there.

---

### Step 2 — Create the Mailable: `HpcReportMail.php`

**File:** `Modules/Hpc/app/Mail/HpcReportMail.php` (create new)

```php
<?php

namespace Modules\Hpc\Mail;

use Illuminate\Bus\Queueable;
use Illuminate\Mail\Mailable;
use Illuminate\Mail\Mailables\Content;
use Illuminate\Mail\Mailables\Envelope;
use Illuminate\Mail\Mailables\Attachment;
use Illuminate\Queue\SerializesModels;

class HpcReportMail extends Mailable
{
    use Queueable, SerializesModels;

    public function __construct(
        public readonly object $student,
        public readonly object $guardian,
        public readonly string $pdfPath,
        public readonly string $pdfFilename,
    ) {}

    public function envelope(): Envelope
    {
        $studentName = trim(($this->student->first_name ?? '') . ' ' . ($this->student->last_name ?? ''));
        return new Envelope(
            subject: 'Holistic Progress Card — ' . $studentName,
        );
    }

    public function content(): Content
    {
        return new Content(
            view: 'hpc::emails.hpc-report',
        );
    }

    public function attachments(): array
    {
        return [
            Attachment::fromPath($this->pdfPath)
                ->as($this->pdfFilename)
                ->withMime('application/pdf'),
        ];
    }
}
```

---

### Step 3 — Create the Email View: `hpc-report.blade.php`

**File:** `Modules/Hpc/resources/views/emails/hpc-report.blade.php` (create new)

```html
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <style>
        body { font-family: Arial, sans-serif; color: #333; font-size: 14px; }
        .header { background: #e36c0a; color: white; padding: 16px 24px; border-radius: 6px 6px 0 0; }
        .body { padding: 24px; border: 1px solid #e0e0e0; border-top: none; border-radius: 0 0 6px 6px; }
        .footer { margin-top: 24px; font-size: 12px; color: #999; }
    </style>
</head>
<body>
    <div class="header">
        <h2 style="margin:0;">Holistic Progress Card</h2>
    </div>
    <div class="body">
        <p>Dear {{ $guardian->first_name ?? 'Parent/Guardian' }},</p>

        <p>
            Please find attached the <strong>Holistic Progress Card</strong> for
            <strong>{{ trim(($student->first_name ?? '') . ' ' . ($student->last_name ?? '')) }}</strong>.
        </p>

        <p>
            This report reflects your child's overall progress and achievements.
            Please review it carefully and feel free to contact the school if you have any questions.
        </p>

        <p>Warm regards,<br>
        <strong>The School Team</strong></p>

        <div class="footer">
            This is an automated email. Please do not reply directly to this message.
        </div>
    </div>
</body>
</html>
```

---

### Step 4 — Add `sendReportEmail()` to `HpcController.php`

**File:** `Modules/Hpc/app/Http/Controllers/HpcController.php`
**Where:** After the `generateReportPdf()` method (after line ~1558)

Add this method:

```php
/**
 * Queue a report card PDF email to all guardians of a student.
 * POST /hpc/send-report-email
 */
public function sendReportEmail(Request $request): \Illuminate\Http\JsonResponse
{
    $request->validate([
        'student_id'       => 'required|integer|exists:std_students,id',
        'academic_term_id' => 'required|integer',
    ]);

    $studentId      = (int) $request->input('student_id');
    $academicTermId = (int) $request->input('academic_term_id');

    // Load student to verify template and guardians before queuing
    $student = Student::with([
        'currentClassSection.class',
        'studentGuardianJnts',
    ])->find($studentId);

    if (!$student) {
        return response()->json(['success' => false, 'message' => 'Student not found.'], 404);
    }

    // Check template exists
    $templateId = $this->resolveTemplateId($student);
    if (!$templateId) {
        return response()->json([
            'success' => false,
            'message' => 'No HPC template is mapped for this student\'s class.',
        ], 422);
    }

    // Check guardian emails exist
    $guardianIds = StudentGuardianJnt::where('student_id', $studentId)
        ->pluck('guardian_id')
        ->toArray();

    if (empty($guardianIds)) {
        return response()->json([
            'success' => false,
            'message' => 'No guardians found for this student.',
        ], 422);
    }

    $emailCount = Guardian::whereIn('id', $guardianIds)
        ->whereNotNull('email')
        ->where('email', '!=', '')
        ->count();

    if ($emailCount === 0) {
        return response()->json([
            'success' => false,
            'message' => 'No guardian email address found for this student.',
        ], 422);
    }

    // Dispatch the job
    $tenantId = tenant('id');

    \Modules\Hpc\Jobs\SendHpcReportEmail::dispatch($studentId, $academicTermId, $tenantId)
        ->onQueue('emails');

    Log::info("HPC: Queued report email for student {$studentId}, term {$academicTermId}, tenant {$tenantId}");

    return response()->json([
        'success' => true,
        'message' => "Report card queued for email delivery to {$emailCount} guardian(s).",
    ]);
}
```

Also add these imports at the top of `HpcController.php` if not already present:

```php
use Modules\Hpc\Jobs\SendHpcReportEmail;
use Modules\StudentProfile\Models\Guardian;
```

---

### Step 5 — Add route to `routes/tenant.php`

**File:** `routes/tenant.php`
**Where:** Inside the existing HPC route group (after line ~2369 where `generate-report` route is defined)

Add:

```php
Route::post('/send-report-email', [HpcController::class, 'sendReportEmail'])->name('send-report-email');
```

The full HPC group will then include:
```php
Route::middleware(['auth', 'verified'])->prefix('hpc')->name('hpc.')->group(function () {
    // ... existing routes ...
    Route::post('/generate-report',     [HpcController::class, 'generateReportPdf'])->name('generate-report');
    Route::post('/send-report-email',   [HpcController::class, 'sendReportEmail'])->name('send-report-email');
});
```

---

### Step 6 — Add button + AJAX in `student-list/index.blade.php`

**File:** `Modules/Hpc/resources/views/student-list/index.blade.php`

**Step 6a — Add the email button to the per-row action `<td>` (after line 217, where the download button ends):**

Find the row action td block:
```html
<a class="btn btn-outline-primary btn-sm"
   href="{{ route('hpc.hpc-form.single', $st->id) }}"
   title="Download">
    <i class="bi bi-download"></i>
</a>
```

After the download button, add:
```html
@if($templateId)
<button type="button"
        class="btn btn-outline-success btn-sm send-report-email"
        data-student-id="{{ $st->id }}"
        data-student-name="{{ trim(($st->first_name ?? '').' '.($st->last_name ?? '')) }}"
        title="Send Report to Guardian Email">
    <i class="bi bi-envelope"></i>
</button>
@endif
```

**Step 6b — Add the AJAX handler inside the existing `<script>` block (after the `#generate-report` handler, before the closing `</script>` tag):**

```javascript
// ================= SEND REPORT EMAIL =================
$(document).on('click', '.send-report-email', function () {

    var studentId   = $(this).data('student-id');
    var studentName = $(this).data('student-name');
    var $btn        = $(this);

    var academicTermId = $('#academic_term_id').val();

    if (!academicTermId) {
        Swal.fire({
            icon: 'error',
            title: 'Academic Term Required',
            text: 'Please select an academic term before sending the report.',
            toast: true,
            position: 'top-end',
            showConfirmButton: false,
            timer: 3000
        });
        return;
    }

    Swal.fire({
        icon: 'question',
        title: 'Send Report Card?',
        text: 'Send the HPC report for ' + studentName + ' to their guardian(s) via email?',
        showCancelButton: true,
        confirmButtonText: 'Yes, Send',
        cancelButtonText: 'Cancel',
        confirmButtonColor: '#198754',
    }).then(function (result) {
        if (!result.isConfirmed) return;

        $btn.prop('disabled', true).html('<span class="spinner-border spinner-border-sm"></span>');

        $.ajax({
            url: "{{ route('hpc.send-report-email') }}",
            type: "POST",
            data: {
                student_id:       studentId,
                academic_term_id: academicTermId,
                _token:           $('meta[name="csrf-token"]').attr('content')
            },
            success: function (response) {
                $btn.prop('disabled', false).html('<i class="bi bi-envelope"></i>');

                if (response.success) {
                    Swal.fire({
                        icon: 'success',
                        title: 'Queued!',
                        text: response.message,
                        toast: true,
                        position: 'top-end',
                        showConfirmButton: false,
                        timer: 4000,
                        timerProgressBar: true
                    });
                } else {
                    Swal.fire({
                        icon: 'warning',
                        title: 'Cannot Send',
                        text: response.message || 'Unable to queue the report email.',
                        confirmButtonColor: '#e36c0a'
                    });
                }
            },
            error: function (xhr) {
                $btn.prop('disabled', false).html('<i class="bi bi-envelope"></i>');
                var msg = xhr.responseJSON?.message || 'Something went wrong. Please try again.';
                Swal.fire({
                    icon: 'error',
                    title: 'Server Error',
                    text: msg
                });
            }
        });
    });

});
```

---

## Rules

1. Do NOT change `generateSingleStudentPdf()` or `generateReportPdf()` — the Job replicates the generation logic independently.
2. Do NOT use `dispatch()->afterResponse()` — use a proper `ShouldQueue` Job so it runs in the queue worker.
3. The Job MUST re-initialize tenancy using `tenancy()->initialize($tenantId)` — queue workers run outside tenant context.
4. Do NOT store the tenant ID as a model or object — store only the string ID and reinitialize in the Job's `handle()`.
5. The Mailable MUST NOT implement `ShouldQueue` itself — the Job handles queuing; the Mailable sends synchronously inside the Job.
6. Do NOT use `Mail::queue()` — use `Mail::to()->send()` inside the Job (the Job itself is queued).
7. Do NOT send email if guardian has no email address — check before dispatching and return a user-friendly JSON error.
8. Do NOT modify the SmartTimetable or any other module.
9. The `buildPdf()` and `minifyHtml()` methods in `HpcController` must be made accessible to the Job. Preferred approach: make them `public` OR move them to `HpcReportService`.
10. Log every major step in the Job using `Log::info()` / `Log::error()`.

---

## Queue Configuration

The Job dispatches to the `emails` queue:
```php
SendHpcReportEmail::dispatch(...)->onQueue('emails');
```

To process the queue during development, run:
```bash
php artisan queue:work --queue=emails
```

Or for all queues:
```bash
php artisan queue:work
```

Ensure `QUEUE_CONNECTION` in `.env` is set to `database` (not `sync`) for background processing:
```
QUEUE_CONNECTION=database
```

If using `database` queue driver, ensure the `jobs` table exists:
```bash
php artisan queue:table
php artisan migrate
```

---

## Verification

After implementation:

### Button Appearance
- Each student row in the student list table has an envelope icon button (`btn-outline-success`)
- The button only appears when `$templateId` is not null (same condition as the view button)

### Pre-flight Validation
- Clicking the email button without selecting an academic term shows: "Please select an academic term before sending the report."
- Clicking for a student with no guardians returns: "No guardians found for this student."
- Clicking for a student whose guardians have no email returns: "No guardian email address found for this student."
- All validation errors show via SweetAlert, NOT a page redirect

### Queue Dispatch
- Clicking for a valid student + term shows confirmation dialog
- On confirm, button shows a spinner, AJAX fires POST to `/hpc/send-report-email`
- Response returns `{success: true, message: "Report card queued for email delivery to N guardian(s)."}` within 1–2 seconds
- SweetAlert toast shows "Queued!" success message

### Job Execution
- `php artisan queue:work --queue=emails` processes the job
- Guardian receives email with subject "Holistic Progress Card — [Student Name]"
- Email body addresses guardian by first name
- PDF report card is attached as `HPC_student_N_YYYYMMDD_HHiiss.pdf`

### Error Handling
- If PDF generation fails inside the Job, `Log::error` is written and the job retries (up to 3 times)
- If mail fails for one guardian, the Job logs the error and continues to the next guardian

---

## Summary of Changes

| # | File | Change | Location |
|---|------|--------|----------|
| 1 | `index.blade.php` | Add `send-report-email` envelope button per row | Per-row action `<td>`, after download button |
| 2 | `index.blade.php` | Add AJAX click handler for `.send-report-email` | `<script>` block, after `#generate-report` handler |
| 3 | `HpcController.php` | Add `sendReportEmail()` method | After `generateReportPdf()` (~line 1558) |
| 4 | `HpcController.php` | Make `buildPdf()` and `minifyHtml()` public (or add public wrappers) | ~line 2221 |
| 5 | `routes/tenant.php` | Add `POST /hpc/send-report-email` route | Inside HPC route group (~line 2369) |
| 6 | `SendHpcReportEmail.php` | CREATE new Job: generates PDF + sends to guardian emails | `Modules/Hpc/app/Jobs/` (new directory) |
| 7 | `HpcReportMail.php` | CREATE new Mailable with PDF attachment | `Modules/Hpc/app/Mail/` (new directory) |
| 8 | `hpc-report.blade.php` | CREATE email HTML view | `Modules/Hpc/resources/views/emails/` (new directory) |