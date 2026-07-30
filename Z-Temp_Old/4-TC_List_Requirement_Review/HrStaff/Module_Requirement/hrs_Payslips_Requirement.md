# Payslips — Business Requirements

## What This Screen Does

The Payslips feature generates password-protected PDF payslips for all employees within a locked payroll run. Each payslip provides a detailed monthly salary breakdown — gross earnings, LOP deductions, statutory contributions (PF, ESI, PT, TDS), and net pay — using a per-component computation snapshot stored during payroll calculation.

Employees can view and download their own payslips through a self-service portal. Payslip downloads are protected by a temporary signed URL that expires in 5 minutes, and the PDF itself is password-protected using a combination of the employee's PAN last 4 digits and date of birth.

## When This Screen Is Used

- **Bulk payslip generation** when the Payroll Manager generates payslips for all employees after a payroll run is locked
- **Employee self-service** when staff members view their payslip history and download individual monthly payslips
- **Payslip distribution** when employees access their payslips via a secure time-limited download link

## Default Data Load

The `PayslipController@myPayslips` method loads the employee's own payslips under the Payroll tab group, reached via route `hr-staff.my-payslips.index`. It queries `Payslip::where('employee_id', $employeeId)->active()->orderByDesc('payroll_month')->paginate(12)` — 12 payslips per page. Each card displays the payroll month, a status indicator for download availability, and a download action.

## Key Fields at a Glance

**Identity and Tracking**
- `run_detail_id` — links the payslip one-to-one with the payroll run detail record used for computation
- `employee_id` — the employee this payslip belongs to (denormalised for fast self-service queries)
- `payroll_month` — the month the payslip covers, denormalised from the run for direct lookup
- `media_id` — reference to the generated PDF file stored in Spatie MediaLibrary

**Generation and Distribution**
- `generated_at` — timestamp when the payslip was generated
- `email_status` — tracks email dispatch: `not_sent`, `pending`, `sent`, `failed`
- `email_sent_at` — timestamp when the email was successfully dispatched

## Business Rules and Conditions

**Locked Run Prerequisite** — Payslips can only be generated for locked payroll runs. Attempting generation on any other status returns HTTP 422 with "Payslips can only be generated for locked payroll runs."

**PDF Password Protection (REQ-HRS-031)** — Each payslip PDF is encrypted with a password composed of the last 4 characters of the employee's PAN card number concatenated with the employee's date of birth in DDYYYY format (e.g. `AB1234C` → last 4 `34C` + DOB `15011990` = `34C15011990`). If PAN or DOB is missing, defaults `0000` and `000000` are used respectively.

**Self-Service Ownership Guard** — The `myPayslips` and `download` endpoints verify that the authenticated user's employee ID matches the payslip's `employee_id`. However, users with `pay.payslip.generate` permission can bypass this guard to download any payslip (support/HR use).

**Time-Limited Download (NFR-HRS-006)** — The download endpoint uses a two-step flow: the first hit redirects to a temporary signed URL valid for 5 minutes. The signed URL then streams the actual file. This ensures download links cannot be shared indefinitely.

**Idempotent Generation** — `PayslipService::generateAll()` uses `updateOrCreate` keyed on `run_detail_id`, so re-running generation updates existing payslip records rather than creating duplicates.

## Workflow Steps

**Generating Payslips for a Run** — The Payroll Manager opens a locked payroll run and clicks "Generate Payslips." The system iterates through all run details, renders each employee's payslip via a Blade-to-PDF pipeline (using mPDF), encrypts the PDF with the employee's PAN+DOB password, stores the file via Spatie MediaLibrary on the employee's media collection, and creates/updates a `Payslip` record linking to the media file. A success message shows the count of generated payslips.

**Viewing Own Payslips** — An employee navigates to "My Payslips." The system displays a paginated list of their generated payslips, most recent first, showing the payroll month for each.

**Downloading a Payslip** — The employee clicks "Download" on a specific payslip. The system checks ownership or HR permission. It then generates a signed temporary URL (valid 5 minutes) and redirects the browser to that URL. The signed URL handler streams the PDF file from MediaLibrary storage to the browser.

## Example Scenario

Ravi, a teacher at Green Valley School, logs into the staff portal and clicks "My Payslips." He sees his December 2025 and January 2026 payslips. He clicks Download on January 2026 — the browser redirects momentarily to a signed URL, then the PDF downloads. Ravi opens it using his PAN last 4 digits `34CD` and his birth date `12041985` — the PDF unlocks, showing his gross pay of ₹45,000, deductions totalling ₹8,250, and net pay of ₹36,750.

## Related Screens

- **Payroll Runs** — the parent payroll run that must be locked before payslips can be generated
- **Payroll Run Details** — each detail record provides the computation data that populates the payslip

## Requirements

- `PayslipController@generateAll(PayrollRun)` — generates payslips for all employees in a locked run; gates on `pay.payslip.generate`; aborts with 422 if run is not locked; logs "PayslipsGenerated" activity
- `PayslipController@myPayslips()` — lists own payslips; gates on `pay.payslip.own.download`; aborts with 403 if no employee record linked
- `PayslipController@download(Request, Payslip)` — streams payslip PDF via signed temporary URL; gates ownership (employee_id match) or `pay.payslip.generate` permission; 403 on unauthorized access; signed URL valid 5 minutes
- `PayslipService::generate(PayrollRunDetail)` — renders Blade view `hrstaff::payslip.pdf`, generates mPDF PDF, sets password protection (PAN last 4 + DOB DDYYYY), stores via `$employee->addMediaFromString()`, creates/updates `Payslip` record with `updateOrCreate` on `run_detail_id`
- `PayslipService::generateAll(PayrollRun)` — iterates all run details, calls `generate()` for each, returns count
- `PayslipPolicy` — defines `viewAny` (pay.payslip.generate or pay.payslip.own.download), `view` (employee match or generate permission), `generate` (pay.payslip.generate), `downloadOwn` (employee match + own.download permission)
- Model uses `SoftDeletes`, `$casts` for `generated_at`, `email_sent_at` (datetime), `is_active` (boolean)
- Relationships: `runDetail()` (BelongsTo PayrollRunDetail), `employee()` (BelongsTo Employee), `media()` (BelongsTo Media)

## Who Can Access

| Gate/Permission | Methods | Notes |
|-----------------|---------|-------|
| `pay.payslip.generate` | `generateAll` | Generate payslips for any locked run |
| `pay.payslip.own.download` | `myPayslips` | View own payslip list and initiate downloads |
| Policy | `PayslipPolicy` | Applied via Gate::authorize() in controller methods |

## Logic Flow

**Page Load (myPayslips)** — User with `pay.payslip.own.download` accesses the page. The system verifies the user has a linked employee record (403 if not). It queries `Payslip::where('employee_id', $id)->active()->orderByDesc('payroll_month')->paginate(12)` and renders the list.

**Generate All** — User with `pay.payslip.generate` clicks "Generate Payslips" on a locked run. The system iterates all `run->details()`. For each detail, it renders a Blade view with detail, employee, and salary assignment data into HTML, converts to PDF via mPDF, applies password protection `$panLast4 . $dobDdYyyy`, stores the PDF via `$employee->addMediaFromString()` to the 'payslips' media collection, and upserts a Payslip record. Returns flash with count.

**Download Flow** — User clicks download. If the request has a valid signature, it streams the file directly via `response()->download()`. Otherwise, it generates a `temporarySignedRoute` valid for 5 minutes and redirects there. The signed route hits the same method but with the signature present.

## Validate Before Save

No direct form validation — payslips are generated server-side from existing run detail data. The `Payslip` model uses `$fillable` for mass-assignment protection.

## Error Handling and Validation Messages

| Scenario | Message | Type |
|----------|---------|------|
| Generate payslips on non-locked run | "Payslips can only be generated for locked payroll runs." | Controller check (422) |
| No employee record linked for self-service | "No employee record linked." | Controller check (403) |
| Unauthorized payslip download | "Unauthorized." | Controller check (403) |
| Payslip not found (invalid ID) | ModelNotFoundException → 404 | Automatic |

## Success Scenarios

**SC-001 — Payslips Generated for Locked Run** — Payroll Manager generates payslips for a locked run with 50 employees. All 50 PDFs are created, stored, and records inserted. Flash: "50 payslips generated successfully."

**SC-002 — Employee Downloads Own Payslip** — Employee with linked record accesses "My Payslips." The list shows 3 payslips. Clicking download on the most recent one initiates a redirect to a signed URL, then the PDF is streamed for download.

## Failure Scenarios

**FC-001 — Generate on Non-Locked Run** — User tries to generate payslips on a run that is approved (not locked). HTTP 422: "Payslips can only be generated for locked payroll runs."

**FC-002 — Self-Service Without Employee Record** — A user account without a linked employee record accesses "My Payslips." HTTP 403: "No employee record linked."

**FC-003 — Download Another Employee's Payslip** — An employee without `pay.payslip.generate` permission tries to download a payslip belonging to a different employee. HTTP 403: "Unauthorized."

## Dependencies module and tables

| Dependency | Type | Details |
|------------|------|---------|
| `pay_payroll_run_details` | FK parent | `pay_payslips.run_detail_id` → `pay_payroll_run_details.id` (RESTRICT) |
| `sch_employees` | FK parent | `pay_payslips.employee_id` → `sch_employees.id` (RESTRICT) |
| `sys_media` | FK parent | `pay_payslips.media_id` → `sys_media.id` (RESTRICT) |
| `PayslipService` | Service | Generates password-protected PDF payslips |
| mPDF | Library | PDF generation from Blade views |
| Spatie MediaLibrary | Library | File storage and retrieval on Employee model |

**Table: `pay_payslips`**

| Column | Type | Details |
|--------|------|---------|
| id | BIGINT UNSIGNED | PK, Auto-increment |
| run_detail_id | BIGINT UNSIGNED | NOT NULL, FK → pay_payroll_run_details.id (UNIQUE) |
| employee_id | INT UNSIGNED | NOT NULL, FK → sch_employees.id |
| payroll_month | VARCHAR(7) | NOT NULL |
| media_id | INT UNSIGNED | NOT NULL, FK → sys_media.id |
| generated_at | TIMESTAMP | NOT NULL, DEFAULT CURRENT_TIMESTAMP |
| email_status | ENUM('not_sent','pending','sent','failed') | NOT NULL, DEFAULT 'not_sent' |
| email_sent_at | TIMESTAMP | NULL |
| is_active | TINYINT(1) | NOT NULL, DEFAULT 1 |
| created_by | BIGINT UNSIGNED | NOT NULL |
| updated_by | BIGINT UNSIGNED | NOT NULL |
| created_at | TIMESTAMP | NULL |
| updated_at | TIMESTAMP | NULL |
| deleted_at | TIMESTAMP | NULL |
| UNIQUE KEY | `uq_pay_payslip_detail` | (`run_detail_id`) |
| FK | `fk_pay_pslip_detid` | RESTRICT |
| FK | `fk_pay_pslip_empid` | RESTRICT |
| FK | `fk_pay_pslip_mediaid` | RESTRICT |
