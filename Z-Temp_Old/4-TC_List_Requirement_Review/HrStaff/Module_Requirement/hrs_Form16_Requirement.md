# Form 16 — Business Requirements

## What This Screen Does

The Form 16 feature generates annual tax deduction certificates (Form 16) for employees. Form 16 serves as proof of tax deducted at source (TDS) from salary and is required by employees for income tax filing. The feature generates Part A (TDS summary from the employer's tax deduction account) and Part B (salary breakup and tax computation) in a single PDF document per employee per financial year.

Generation is restricted to occur only after April 15 of the year following the financial year close, ensuring all monthly payroll runs for that FY have been completed and locked.

## When This Screen Is Used

- **Annual tax certificate generation** when the Payroll Manager generates Form 16 PDFs for all employees who had TDS deducted during a completed financial year
- **Employee self-service** when staff members download their own Form 16 for income tax filing purposes
- **Post-April 15 processing** — the system prevents generation before April 15 of the year following the FY close (e.g. Form 16 for FY 2025-26 cannot be generated before April 15, 2026)

## Default Data Load

The `Form16Controller@index` method loads the Form 16 listing page under the Payroll tab group, reached via route `hr-staff.form16.index` with a `{year}` parameter (e.g. `form16/2025-26`). It gates on `pay.form16.generate`. It queries `Form16::with('employee')->where('financial_year', $year)->active()->orderBy('employee_id')->paginate(50)` — 50 forms per page. It also loads a TDS ledger summary showing `SUM(gross_pay)` and `SUM(tds_deducted)` grouped by `employee_id` for the given year, displayed alongside the form list for cross-reference.

## Key Fields at a Glance

**Identity and Tracking**
- `employee_id` — the employee this Form 16 belongs to
- `financial_year` — the applicable financial year in `YYYY-YY` format (e.g. `2025-26`)
- `media_id` — reference to the generated PDF file stored in Spatie MediaLibrary

**Generation Metadata**
- `generated_at` — timestamp of Form 16 generation
- `generated_by` — the employee (Payroll Manager) who triggered the generation

## Business Rules and Conditions

**April 15 Guard (BR-PAY-009)** — Form 16 generation is blocked before April 15 of the year following the financial year close. For FY 2025-26, the earliest generation date is April 15, 2026. Attempting generation earlier throws a `DomainException`.

**TDS Threshold** — Only employees with cumulative `tds_deducted > 0` for the financial year (as recorded in the TDS ledger) are eligible for Form 16 generation. Employees with zero TDS are excluded.

**Idempotent Generation** — `Form16Service::generateAll()` uses `updateOrCreate` keyed on `(employee_id, financial_year)`, so re-running generation updates existing records rather than creating duplicates.

**Self-Service Ownership** — The `download` endpoint verifies that the authenticated user's employee ID matches the Form 16 record's `employee_id`, gated by `pay.form16.own.download`.

## Workflow Steps

**Viewing Form 16 Records** — The Payroll Manager navigates to Payroll → Form 16, selects a financial year (e.g. `2025-26`). The system displays existing generated forms alongside a TDS ledger summary showing year-to-date gross and TDS per employee.

**Generating Form 16 for All Eligible Employees** — The Payroll Manager clicks "Generate All." The system checks the April 15 guard. It then queries the TDS ledger for all employees with `SUM(tds_deducted) > 0` for that FY. For each eligible employee, it renders a Blade-to-PDF document combining the annual salary summary and monthly TDS deduction data from the TDS ledger, stores the PDF via Spatie MediaLibrary, and creates or updates a `Form16` record.

**Downloading Own Form 16** — An employee navigates to Form 16 under self-service, selects the financial year, and clicks "Download." The system validates ownership, finds the media record, and streams the PDF file.

## Example Scenario

In May 2026, Payroll Manager Anita navigates to Form 16 and enters financial year `2025-26`. The page shows that no forms have been generated yet, with a TDS ledger summary listing 80 employees who had TDS deducted totalling ₹12,50,000. She clicks "Generate All" — the system creates 80 Form 16 PDFs. Each PDF contains the employee's salary summary and monthly TDS breakdown. Later, teacher Ravi logs into the staff portal, navigates to Form 16 for FY 2025-26, and downloads his certificate.

## Related Screens

- **TDS Ledger** — the source of monthly TDS data used to populate Form 16 Part A and Part B
- **Payroll Runs** — all runs within the financial year contribute to the annual TDS totals
- **Payslips** — monthly payslips are the individual counterparts to the annual Form 16 certificate

## Requirements

- `Form16Controller@index(string $year)` — lists Form 16 records for a FY with TDS summary; gates on `pay.form16.generate`; paginates 50 per page
- `Form16Controller@generateAll(string $year)` — generates Form 16 for all eligible employees; gates on `pay.form16.generate`; guarded by `guardApril15()` DomainException
- `Form16Controller@download(string $year)` — streams own Form 16 PDF; gates on `pay.form16.own.download`; aborts with 403 if no employee record linked; uses `firstOrFail`
- `Form16Service::generateAll(string $year)` — queries TDS ledger for employees with `SUM(tds_deducted) > 0`, iterates and calls `generateForEmployee()`; guarded by `guardApril15()`
- `Form16Service::generateForEmployee(Employee, string $year)` — renders Blade view `hrstaff::form16.pdf` with employee, year, total gross, total TDS, and monthly rows; generates PDF via mPDF; stores via MediaLibrary; upserts `Form16` record keyed on `(employee_id, financial_year)`
- `Form16Service::guardApril15(string $year)` — parses FY end year, creates Carbon date of April 15, throws if `now() < earliestAllowed`
- `Form16Policy` — defines `viewAny` (pay.form16.generate or pay.form16.own.download), `generate` (pay.form16.generate), `downloadOwn` (employee match + own.download permission)
- Model uses `SoftDeletes`, `$casts` for `generated_at` (datetime), `is_active` (boolean)
- Relationships: `employee()` (BelongsTo), `generatedByEmployee()` (BelongsTo), `media()` (BelongsTo)
- Scopes: `active()`, `forFinancialYear($fy)`

## Who Can Access

| Gate/Permission | Methods | Notes |
|-----------------|---------|-------|
| `pay.form16.generate` | `index`, `generateAll` | View and generate Form 16 records |
| `pay.form16.own.download` | `download` | Download own Form 16 |
| Policy | `Form16Policy` | Applied via `Gate::authorize()` in controller methods |

## Logic Flow

**Page Load (index)** — User with `pay.form16.generate` accesses `form16/{year}`. The system queries `Form16::with('employee')->where('financial_year', $year)->active()` ordered by employee, paginated at 50. Additionally, it queries `TdsLedger::where('financial_year', $year)` with `selectRaw('employee_id, SUM(gross_pay), SUM(tds_deducted)')` grouped by employee for cross-reference display.

**Generate All** — User clicks "Generate All." The system calls `guardApril15($year)` which parses the FY end year and checks `now() >= April 15 of endYear`. If before April 15, a `DomainException` is thrown. Otherwise, eligible employees (those with `SUM(tds_deducted) > 0` in TDS ledger) are fetched. For each, the system renders a Blade view with yearly aggregates and monthly TDS rows into a PDF via mPDF, stores via MediaLibrary on the employee's 'form16' collection, and upserts a `Form16` record. Activity is logged with the count.

**Download** — User accesses `my-form16/{year}/download`. The system gates on `pay.form16.own.download`, verifies employee record linkage, queries `Form16::where('employee_id', $id)->where('financial_year', $year)->active()->firstOrFail()`, then streams the file via `response()->download($media->getPath(), $media->file_name)`.

## Validate Before Save

No direct form validation — Form 16 is generated server-side from existing TDS ledger data. The `{year}` route parameter is a string validated by the route regex pattern.

## Error Handling and Validation Messages

| Scenario | Message | Type |
|----------|---------|------|
| Generate before April 15 | "Form 16 for FY {year} cannot be generated before April 15, {endYear}." | DomainException |
| No employee record linked for download | "No employee record linked." | Controller check (403) |
| Form 16 not found for employee+year | ModelNotFoundException → 404 | Automatic |
| Generate with invalid FY format | Route not matched (pattern mismatch) | 404 |

## Success Scenarios

**SC-001 — Form 16 Generated for All Eligible Employees** — On May 1, 2026, Anita generates Form 16 for FY 2025-26. The system creates 80 Form 16 PDFs and records. Flash: "80 Form 16 record(s) generated for FY 2025-26."

**SC-002 — Employee Downloads Own Form 16** — Ravi accesses Form 16 for FY 2025-26. The system finds his record and streams `form16-2025-26-EMP001.pdf` for download.

## Failure Scenarios

**FC-001 — Generate Before April 15** — Anita tries to generate Form 16 for FY 2025-26 on March 20, 2026. DomainException: "Form 16 for FY 2025-26 cannot be generated before April 15, 2026."

**FC-002 — No Form 16 Generated for Year** — Employee tries to download Form 16 for a FY where no records exist. ModelNotFoundException → 404.

**FC-003 — Download Without Employee Record** — User account without linked employee record tries to download. HTTP 403: "No employee record linked."

## Dependencies module and tables

| Dependency | Type | Details |
|------------|------|---------|
| `sch_employees` | FK parent | `pay_form16.employee_id`, `generated_by` → `sch_employees.id` (RESTRICT) |
| `sys_media` | FK parent | `pay_form16.media_id` → `sys_media.id` (RESTRICT) |
| `pay_tds_ledger` | Data source | Monthly TDS data used for PDF content |
| `Form16Service` | Service | Orchestrates generation with April 15 guard |
| mPDF | Library | PDF generation from Blade views |
| Spatie MediaLibrary | Library | File storage on Employee model |

**Table: `pay_form16`**

| Column | Type | Details |
|--------|------|---------|
| id | BIGINT UNSIGNED | PK, Auto-increment |
| employee_id | INT UNSIGNED | NOT NULL, FK → sch_employees.id |
| financial_year | VARCHAR(7) | NOT NULL, YYYY-YY format |
| media_id | INT UNSIGNED | NOT NULL, FK → sys_media.id |
| generated_at | TIMESTAMP | NOT NULL, DEFAULT CURRENT_TIMESTAMP |
| generated_by | INT UNSIGNED | NOT NULL, FK → sch_employees.id |
| is_active | TINYINT(1) | NOT NULL, DEFAULT 1 |
| created_by | BIGINT UNSIGNED | NOT NULL |
| updated_by | BIGINT UNSIGNED | NOT NULL |
| created_at | TIMESTAMP | NULL |
| updated_at | TIMESTAMP | NULL |
| deleted_at | TIMESTAMP | NULL |
| UNIQUE KEY | `uq_pay_form16` | (`employee_id`, `financial_year`) |
