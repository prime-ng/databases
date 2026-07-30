# hrs_Payslips_TcList

## Module: HrStaff → Payroll → Payslips

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | HrStaff |
| Tab Group | Payroll |
| Feature | Payslips |
| URL(s) | `POST payroll/{run}/payslips/generate-all` (generateAll), `GET my-payslips` (myPayslips), `GET my-payslips/{payslip}/download` (download) |
| Controller | `Modules\HrStaff\Http\Controllers\PayslipController` — `generateAll()` lines 26-37, `myPayslips()` lines 42-55, `download()` lines 61-86 |
| Model(s) | `Modules\HrStaff\Models\Payslip` (table: `pay_payslips`) |
| Validation | None (server-side generation) |
| Policy | `Modules\HrStaff\Policies\PayslipPolicy` |
| Permissions | `pay.payslip.generate`, `pay.payslip.own.download` |
| Pagination | 12 records per page (myPayslips) |
| Soft Deletes | Yes — `SoftDeletes` trait on `Payslip` |
| Data Source | Generated from `PayrollRunDetail` after payroll run is locked |

## 2. Pre-conditions

- Required permissions: `pay.payslip.generate`, `pay.payslip.own.download`
- Required seed data: At least one locked payroll run with computed details, employees with PAN and DOB populated
- Tenant context initialized with `DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD`
- At least one employee account linked to a user for self-service testing
- Spatie MediaLibrary configured for employee 'payslips' media collection

## 3. Default Data Load

`PayslipController@myPayslips()` loads via route `hr-staff.my-payslips.index`. No filters — all active payslips for the authenticated employee, ordered by `payroll_month` desc.

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| Payslip list (self-service) | `myPayslips()` | `Payslip::where('employee_id', $id)->active()->orderByDesc('payroll_month')` | is_active = true implicit | 12/page |

## 4. Test Data Strategy

- Create locked payroll runs with employees having varied PAN and DOB values to test PDF password derivation
- Generate payslips via the `generate-all` POST endpoint with at least 13 employees to test pagination at 12 per page
- Create employees with missing PAN or DOB to test password fallback to defaults
- Set up employee records linked (and not linked) to user accounts for self-service guard tests

## 5. Business Conditions

### 5.1 Database Schema — pay_payslips

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | id | BIGINT UNSIGNED | PK, Auto-increment |
| BC-DB-02 | run_detail_id | BIGINT UNSIGNED | NOT NULL, FK → pay_payroll_run_details.id, UNIQUE |
| BC-DB-03 | employee_id | INT UNSIGNED | NOT NULL, FK → sch_employees.id |
| BC-DB-04 | payroll_month | VARCHAR(7) | NOT NULL |
| BC-DB-05 | media_id | INT UNSIGNED | NOT NULL, FK → sys_media.id |
| BC-DB-06 | generated_at | TIMESTAMP | NOT NULL, DEFAULT CURRENT_TIMESTAMP |
| BC-DB-07 | email_status | ENUM('not_sent','pending','sent','failed') | NOT NULL, DEFAULT 'not_sent' |
| BC-DB-08 | email_sent_at | TIMESTAMP | NULL |
| BC-DB-09 | is_active | TINYINT(1) | NOT NULL, DEFAULT 1 |
| BC-DB-10 | deleted_at | TIMESTAMP | NULL |

### 5.2 Authorization

| BC ID | Permission | Behavior |
|-------|-----------|----------|
| BC-AUTH-01 | pay.payslip.generate | Without: 403 on generateAll |
| BC-AUTH-02 | pay.payslip.own.download | Without: 403 on myPayslips |
| BC-AUTH-03 | Guest access | Redirect to /login |

### 5.3 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|------------------|
| BC-BIZ-01 | Generate payslips on locked run | All run details processed; Payslip records created; success flash "N payslips generated successfully." |
| BC-BIZ-02 | Generate payslips on non-locked run | HTTP 422: "Payslips can only be generated for locked payroll runs." |
| BC-BIZ-03 | View own payslips | Paginated list (12/page) of own payslips, ordered by month desc |
| BC-BIZ-04 | Download own payslip (first hit) | Redirected to temporary signed URL |
| BC-BIZ-05 | Download own payslip (signed URL) | PDF file streamed for download |
| BC-BIZ-06 | Download another employee's payslip (no HR permission) | HTTP 403: "Unauthorized." |
| BC-BIZ-07 | HR user downloads any payslip | Allowed (bypasses ownership check) |
| BC-BIZ-08 | Self-service with no linked employee record | HTTP 403: "No employee record linked." |
| BC-BIZ-09 | Generate payslips idempotent (re-run) | Existing records updated, no duplicates |
| BC-BIZ-10 | PDF password uses PAN last 4 + DOB DDYYYY | Password = substr(PAN, -4) . DOB->format('dY') |

### 5.4 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|-----------------|----------------|
| BC-REF-01 | pay_payslips.run_detail_id | pay_payroll_run_details.id | RESTRICT |
| BC-REF-02 | pay_payslips.employee_id | sch_employees.id | RESTRICT |
| BC-REF-03 | pay_payslips.media_id | sys_media.id | RESTRICT |

## 6. Test Case List

### 6.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|-----------------|---------|---------|--------|
| TC-P01 | Generate payslips for all employees in a locked run | All run details processed; Payslip records created with media_id; flash "N payslips generated successfully." | — | — | ⬜ |
| TC-P02 | Re-generate payslips (idempotent) | Existing payslip records updated; no duplicates created | — | — | ⬜ |
| TC-P03 | View own payslip list (self-service) | Paginated list of own payslips (12/page), ordered by month desc | — | — | ⬜ |
| TC-P04 | Download own payslip | Redirected to signed URL; PDF file downloads | — | — | ⬜ |
| TC-P05 | HR/Admin downloads another employee's payslip | User with pay.payslip.generate can bypass ownership guard; PDF downloads | — | — | ⬜ |
| TC-P06 | Payslip PDF password protection | PDF opens only with password = PAN last 4 + DOB DDYYYY | — | — | ⬜ |
| TC-P07 | Pagination: more than 12 payslips | Page 2 available, shows older payslips | — | — | ⬜ |

### 6.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|-----------------|---------|---------|--------|
| TC-N01 | Generate payslips on non-locked payroll run | HTTP 422: "Payslips can only be generated for locked payroll runs." | — | — | ⬜ |
| TC-N02 | Access myPayslips without pay.payslip.own.download permission | HTTP 403 Forbidden | — | — | ⬜ |
| TC-N03 | Access generateAll without pay.payslip.generate permission | HTTP 403 Forbidden | — | — | ⬜ |
| TC-N04 | Self-service user with no linked employee record | HTTP 403: "No employee record linked." | — | — | ⬜ |
| TC-N05 | Download payslip owned by another employee (no HR permission) | HTTP 403: "Unauthorized." | — | — | ⬜ |
| TC-N06 | Download non-existent payslip | ModelNotFoundException → 404 | — | — | ⬜ |
| TC-N07 | Access any payslip route as guest | Redirect to /login | — | — | ⬜ |
| TC-N08 | PDF password falls back to defaults when PAN/DOB missing | Password = "0000000000" for missing PAN and DOB | — | — | ⬜ |

### 6.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|-----------------|---------|---------|--------|
| TC-D01 | A | Payslip unique constraint on run_detail_id | Cannot create two payslips for same run detail | — | — | ⬜ |
| TC-D02 | B | SoftDeletes on Payslip | Deleted payslip has deleted_at set; excluded from active() | — | — | ⬜ |
| TC-D03 | C | Payslip cascade: detail deletion blocked (RESTRICT) | Cannot delete PayrollRunDetail if payslip exists | — | — | ⬜ |
| TC-D04 | D | Activity logged on generateAll | "PayslipsGenerated" entry added to activity log with count | — | — | ⬜ |
| TC-D05 | E | Signed URL expires after 5 minutes | Using expired signed URL returns 403 | — | — | ⬜ |

### 6.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|-----------------|---------|---------|--------|
| TC-CR01 | CR | P1 | Model — Payslip $fillable matches DDL columns | All writable columns (excluding PK, timestamps) are in $fillable | — | — | ◌ |
| TC-CR02 | CR | P1 | Model — Payslip $casts for booleans/datetimes | generated_at, email_sent_at → datetime; is_active → boolean | — | — | ◌ |
| TC-CR03 | CR | P1 | Model — SoftDeletes trait | deleted_at column exists; restore/trashed scopes function | — | — | ◌ |
| TC-CR04 | CR | P1 | Model — Relationships: runDetail, employee, media | BelongsTo defined with correct FKs | — | — | ◌ |
| TC-CR05 | CR | P1 | Controller — Gate::authorize() on generateAll, myPayslips, download | Each method checks appropriate permission | — | — | ◌ |
| TC-CR06 | CR | P1 | Controller — Activity logged on generateAll | activityLog() called after generation | — | — | ◌ |
| TC-CR07 | CR | P1 | Policy — PayslipPolicy methods defined | viewAny, view, generate, downloadOwn all defined | — | — | ◌ |
| TC-CR08 | CR | P1 | Routes — payslip routes registered | generateAll, myPayslips, download routes with correct names | — | — | ◌ |
| TC-CR09 | CR | P1 | PDF — mPDF password protection implemented | SetProtection called with PAN last 4 + DOB DDYYYY | — | — | ◌ |
| TC-CR10 | CR | P1 | Download — signed temporary URL flow | First hit redirects to signed URL; signed URL streams file | — | — | ◌ |

## 7. Detailed Test Steps

#### TC-CR01: Model — Payslip $fillable matches DDL columns
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Compare `Payslip::$fillable` against DDL columns of `pay_payslips` | run_detail_id, employee_id, payroll_month, media_id, generated_at, email_status, email_sent_at, is_active, created_by, updated_by are all present |

#### TC-CR02: Model — Payslip $casts
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `Payslip::$casts` | generated_at → 'datetime', email_sent_at → 'datetime', is_active → 'boolean' |

#### TC-CR03: Model — SoftDeletes on Payslip
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Delete a Payslip | deleted_at set; excluded from active() scope |

#### TC-CR04: Model — Relationships
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect Payslip model | runDetail (BelongsTo PayrollRunDetail), employee (BelongsTo Employee), media (BelongsTo Media) |

#### TC-CR05: Controller — Gate::authorize() on each method
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect generateAll, myPayslips, download | Each has Gate::authorize() call at start |

#### TC-CR06: Controller — Activity logged on generateAll
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect generateAll() | activityLog() called after service completes |

#### TC-CR07: Policy — PayslipPolicy methods
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect PayslipPolicy | viewAny, view, generate, downloadOwn defined |

#### TC-CR08: Routes — payslip routes registered
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect routes | POST payroll/{run}/payslips/generate-all, GET my-payslips, GET my-payslips/{payslip}/download all registered |

#### TC-CR09: PDF password protection implemented
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `PayslipService::generate()` | SetProtection called with $password = PAN last 4 + DOB DDYYYY |

#### TC-CR10: Download signed temporary URL flow
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `PayslipController::download()` | First request (no signature) → redirect to temporarySignedRoute; second request (with signature) → response()->download() |

### 7.1 Positive TC Steps

#### TC-P01: Generate payslips for all employees in a locked run
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user with pay.payslip.generate permission | Session ready |
| 2 | Open a locked payroll run with 5 employees | Run show page |
| 3 | Click "Generate Payslips" or POST to `/payroll/{run}/payslips/generate-all` | Success flash "5 payslips generated successfully." |
| 4 | Verify in DB | 5 Payslip records exist with media_id, generated_at populated |

#### TC-P02: Re-generate payslips (idempotent)
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Re-generate payslips for the same locked run | Flash "5 payslips generated successfully." |
| 2 | Verify in DB | Still 5 records (no duplicates), media_ids updated |

#### TC-P03: View own payslip list (self-service)
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as employee with linked payslips and pay.payslip.own.download permission | Session ready |
| 2 | Navigate to `GET /my-payslips` | Paginated list of own payslips (up to 12), ordered by month desc |

#### TC-P04: Download own payslip
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | From myPayslips page, click "Download" on a payslip | Browser redirects to temporary signed URL |
| 2 | Follow the redirect | PDF file downloads with filename "payslip-{month}-{emp_code}.pdf" |

#### TC-P05: HR/Admin downloads another employee's payslip
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user with pay.payslip.generate permission | HR user |
| 2 | Navigate to `GET /my-payslips/{payslip}/download` for another employee's payslip | PDF downloads successfully (bypasses ownership guard) |

#### TC-P06: Payslip PDF password protection
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Download a payslip for employee with PAN "ABCDE1234F" and DOB 15-01-1990 | PDF is password-protected |
| 2 | Open PDF with password "1234F15011990" (last 4 of PAN = "34F" + DOB DDYYYY = "15011990") | PDF opens and displays salary details |
| 3 | Attempt to copy/print the PDF without password | PDF copy/print protection is active |

#### TC-P07: Pagination: more than 12 payslips
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Generate 15 payslips for the same employee across multiple months | 15 records exist |
| 2 | View myPayslips page | Page 1 shows 12, pagination links visible |
| 3 | Click page 2 | Remaining 3 payslips displayed |

### 7.2 Negative TC Steps

#### TC-N01: Generate payslips on non-locked payroll run
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open a payroll run that is approved (not locked) | Status ≠ locked |
| 2 | POST to `/payroll/{run}/payslips/generate-all` | HTTP 422: "Payslips can only be generated for locked payroll runs." |

#### TC-N02: Access myPayslips without permission
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user without pay.payslip.own.download | No permission |
| 2 | Navigate to `GET /my-payslips` | HTTP 403 Forbidden |

#### TC-N03: Access generateAll without permission
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user without pay.payslip.generate | No permission |
| 2 | POST to `/payroll/{run}/payslips/generate-all` | HTTP 403 Forbidden |

#### TC-N04: Self-service user with no linked employee record
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user who has no employee record linked | User exists, no employee relationship |
| 2 | Navigate to `GET /my-payslips` | HTTP 403: "No employee record linked." |

#### TC-N05: Download payslip owned by another employee (no HR permission)
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as employee A | Employee A session |
| 2 | Navigate to `GET /my-payslips/{payslipOfEmployeeB}/download` | HTTP 403: "Unauthorized." |

#### TC-N06: Download non-existent payslip
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to `GET /my-payslips/99999/download` | ModelNotFoundException → 404 |

#### TC-N07: Access any payslip route as guest
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Logout | Guest session |
| 2 | Navigate to any payslip URL | Redirect to /login |

#### TC-N08: PDF password falls back to defaults when PAN/DOB missing
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set up an employee with PAN = null and DOB = null | Missing fields |
| 2 | Generate payslip for this employee | Payslip generated |
| 3 | Download and open PDF | Password = "0000000000" (0000 + 000000) |

### 7.3 Dependency TC Steps

#### TC-D01: Payslip unique constraint on run_detail_id
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a Payslip for run_detail_id = 5 | Succeeds |
| 2 | Attempt to create another Payslip with same run_detail_id = 5 | Integrity constraint violation (unique key) |

#### TC-D02: SoftDeletes on Payslip
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Delete a Payslip record | deleted_at set; excluded from myPayslips listing |

#### TC-D03: Payslip FK RESTRICT on detail deletion
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Try to delete a PayrollRunDetail that has an associated Payslip | FK constraint violation (RESTRICT) prevents deletion |

#### TC-D04: Activity logged on generateAll
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Generate payslips for a locked run | Activity log entry "PayslipsGenerated" with count appears |

#### TC-D05: Signed URL expires after 5 minutes
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Obtain a signed download URL for a payslip | URL has expiry timestamp |
| 2 | Wait 6 minutes (or manipulate time) and use the same URL | Request fails (signature invalid / expired) |
