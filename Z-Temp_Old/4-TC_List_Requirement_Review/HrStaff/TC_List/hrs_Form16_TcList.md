# hrs_Form16_TcList

## Module: HrStaff → Payroll → Form 16

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | HrStaff |
| Tab Group | Payroll |
| Feature | Form 16 |
| URL(s) | `GET form16/{year}` (index), `POST form16/{year}/generate-all` (generateAll), `GET my-form16/{year}/download` (download) |
| Controller | `Modules\HrStaff\Http\Controllers\Form16Controller` — `index()` lines 24-40, `generateAll()` lines 46-63, `download()` lines 68-83 |
| Model(s) | `Modules\HrStaff\Models\Form16` (table: `pay_form16`) |
| Validation | None (server-side generation from TDS ledger) |
| Policy | `Modules\HrStaff\Policies\Form16Policy` |
| Permissions | `pay.form16.generate`, `pay.form16.own.download` |
| Pagination | 50 records per page (index) |
| Soft Deletes | Yes — `SoftDeletes` trait on `Form16` |
| Data Source | Generated from `pay_tds_ledger` data monthly aggregates |

## 2. Pre-conditions

- Required permissions: `pay.form16.generate`, `pay.form16.own.download`
- Required seed data: TDS ledger records with multiple employees across a financial year where `SUM(tds_deducted) > 0`
- Current date must be on or after April 15 of the year following the FY close (or mock time travel)
- Tenant context initialized with `DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD`
- At least one employee account linked to a user for self-service testing
- At least one employee with zero TDS to test exclusion logic

## 3. Default Data Load

`Form16Controller@index(string $year)` loads via route `hr-staff.form16.index` with `{year}` parameter (e.g. `2025-26`). No additional filters — records matched by `financial_year = $year`.

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| Form 16 grid | `index()` | `Form16::with('employee')->where('financial_year', $year)->active()->orderBy('employee_id')` | is_active, financial_year | 50/page |
| TDS ledger summary | `index()` | `TdsLedger::where('financial_year', $year)->selectRaw('employee_id, SUM(gross_pay), SUM(tds_deducted)')->groupBy('employee_id')` | financial_year | None |

## 4. Test Data Strategy

- Create TDS ledger entries for at least 55 employees across a financial year — some with TDS > 0, some with TDS = 0
- Manipulate system date or mock Carbon to test April 15 guard on either side of the boundary
- Generate Form 16 records via the `generate-all` POST endpoint
- Create employees with TDS but no Form 16 generated to test the index page's cross-reference display
- Test pagination by generating 55+ Form 16 records (50 per page)

## 5. Business Conditions

### 5.1 Database Schema — pay_form16

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | id | BIGINT UNSIGNED | PK, Auto-increment |
| BC-DB-02 | employee_id | INT UNSIGNED | NOT NULL, FK → sch_employees.id |
| BC-DB-03 | financial_year | VARCHAR(7) | NOT NULL |
| BC-DB-04 | media_id | INT UNSIGNED | NOT NULL, FK → sys_media.id |
| BC-DB-05 | generated_at | TIMESTAMP | NOT NULL, DEFAULT CURRENT_TIMESTAMP |
| BC-DB-06 | generated_by | INT UNSIGNED | NOT NULL, FK → sch_employees.id |
| BC-DB-07 | is_active | TINYINT(1) | NOT NULL, DEFAULT 1 |
| BC-DB-08 | deleted_at | TIMESTAMP | NULL |
| BC-DB-09 | UNIQUE KEY uq_pay_form16 | (`employee_id`, `financial_year`) | No duplicate employee per FY |

### 5.2 Authorization

| BC ID | Permission | Behavior |
|-------|-----------|----------|
| BC-AUTH-01 | pay.form16.generate | Without: 403 on index, generateAll |
| BC-AUTH-02 | pay.form16.own.download | Without: 403 on download |
| BC-AUTH-03 | Guest access | Redirect to /login |

### 5.3 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|------------------|
| BC-BIZ-01 | Index page loads for existing FY | Form 16 grid with 50 records/page + TDS ledger summary displayed |
| BC-BIZ-02 | Generate All after April 15 | All employees with TDS > 0 get Form 16 records; success flash "N Form 16 record(s) generated for FY {year}." |
| BC-BIZ-03 | Generate All before April 15 | DomainException: "Form 16 for FY {year} cannot be generated before April 15, {endYear}." |
| BC-BIZ-04 | Generate All when no employees have TDS > 0 | Zero records created; flash "0 Form 16 record(s) generated..." |
| BC-BIZ-05 | Download own Form 16 (employee) | PDF file streams for download with filename `form16-{year}-{emp_code}.pdf` |
| BC-BIZ-06 | Re-generate Form 16 (idempotent) | Existing records updated; no duplicates |
| BC-BIZ-07 | Index FY with no generated forms | Empty grid with TDS summary visible showing pending employees |

### 5.4 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|-----------------|----------------|
| BC-REF-01 | pay_form16.employee_id | sch_employees.id | RESTRICT |
| BC-REF-02 | pay_form16.media_id | sys_media.id | RESTRICT |
| BC-REF-03 | pay_form16.generated_by | sch_employees.id | RESTRICT |

## 6. Test Case List

### 6.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|-----------------|---------|---------|--------|
| TC-P01 | Load Form 16 index for a FY with existing records | Grid shows 50 forms per page; TDS summary displays alongside | — | — | ⬜ |
| TC-P02 | Generate All Form 16 for employees with TDS > 0 | PDFs created for each eligible employee; records upserted; success flash | — | — | ⬜ |
| TC-P03 | Re-generate Form 16 (idempotent) | Existing records updated; no duplicates | — | — | ⬜ |
| TC-P04 | Employee downloads own Form 16 | PDF streams with correct filename | — | — | ⬜ |
| TC-P05 | Generate All when all employees have zero TDS | Zero records created; flash "0 Form 16 record(s) generated..." | — | — | ⬜ |
| TC-P06 | Index page renders when no Form 16 records exist | Empty grid; TDS summary shows pending employees | — | — | ⬜ |
| TC-P07 | Pagination on index with 55+ records | Page 2 shows remaining 5 records | — | — | ⬜ |

### 6.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|-----------------|---------|---------|--------|
| TC-N01 | Generate All before April 15 | DomainException: "Form 16 for FY {year} cannot be generated before April 15, {endYear}." | — | — | ⬜ |
| TC-N02 | Access index without pay.form16.generate permission | HTTP 403 Forbidden | — | — | ⬜ |
| TC-N03 | Access generateAll without pay.form16.generate permission | HTTP 403 Forbidden | — | — | ⬜ |
| TC-N04 | Access download without pay.form16.own.download permission | HTTP 403 Forbidden | — | — | ⬜ |
| TC-N05 | Download Form 16 for FY where no record exists | ModelNotFoundException → 404 | — | — | ⬜ |
| TC-N06 | Download Form 16 with no linked employee record | HTTP 403: "No employee record linked." | — | — | ⬜ |
| TC-N07 | Access any Form 16 route as guest | Redirect to /login | — | — | ⬜ |
| TC-N08 | Index with invalid FY format | Route not matched (404) | — | — | ⬜ |

### 6.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|-----------------|---------|---------|--------|
| TC-D01 | A | Form16 unique constraint on (employee_id, financial_year) | Cannot create two Form 16 records for same employee+FY | — | — | ⬜ |
| TC-D02 | B | SoftDeletes on Form16 | Deleted record excluded from active() scope | — | — | ⬜ |
| TC-D03 | C | Activity logged on generateAll | Form16Generate activity entry created with count and FY | — | — | ⬜ |
| TC-D04 | D | Form16 depends on TDS ledger data | Generated PDF contains monthly TDS rows from pay_tds_ledger | — | — | ⬜ |

### 6.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|-----------------|---------|---------|--------|
| TC-CR01 | CR | P1 | Model — Form16 $fillable matches DDL columns | employee_id, financial_year, media_id, generated_at, generated_by, is_active, created_by, updated_by in fillable | — | — | ◌ |
| TC-CR02 | CR | P1 | Model — Form16 $casts | generated_at → datetime; is_active → boolean | — | — | ◌ |
| TC-CR03 | CR | P1 | Model — SoftDeletes | deleted_at column exists | — | — | ◌ |
| TC-CR04 | CR | P1 | Model — Relationships: employee, generatedByEmployee, media | BelongsTo defined with correct FKs | — | — | ◌ |
| TC-CR05 | CR | P1 | Controller — Gate::authorize() on index, generateAll, download | Each method checks appropriate permission | — | — | ◌ |
| TC-CR06 | CR | P1 | Controller — Activity logged on generateAll | activityLog() called after generation completes | — | — | ◌ |
| TC-CR07 | CR | P1 | Controller — Try-catch on generateAll | DomainException caught, flash error displayed | — | — | ◌ |
| TC-CR08 | CR | P1 | Policy — Form16Policy methods | viewAny, generate, downloadOwn defined | — | — | ◌ |
| TC-CR09 | CR | P1 | Routes — Form16 routes registered | index, generateAll, download with correct names | — | — | ◌ |
| TC-CR10 | CR | P1 | Service — guardApril15 logic | Correctly blocks generation before April 15 of end year | — | — | ◌ |

## 7. Detailed Test Steps

#### TC-CR01: Model — Form16 $fillable matches DDL
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Compare `Form16::$fillable` against DDL of `pay_form16` | employee_id, financial_year, media_id, generated_at, generated_by, is_active, created_by, updated_by present |

#### TC-CR02: Model — Form16 $casts
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `Form16::$casts` | generated_at → 'datetime'; is_active → 'boolean' |

#### TC-CR03: Model — SoftDeletes
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Delete a Form16 record | deleted_at set; excluded from active() |

#### TC-CR04: Model — Relationships
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect Form16 model | employee (BelongsTo), generatedByEmployee (BelongsTo), media (BelongsTo) |

#### TC-CR05: Controller — Gate::authorize()
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect index, generateAll, download | Each has Gate::authorize() call |

#### TC-CR06: Controller — Activity logged
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect generateAll() | activityLog() called after service completes |

#### TC-CR07: Controller — Try-catch
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect generateAll() | DomainException caught; back()->with('error') |

#### TC-CR08: Policy — Form16Policy
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect Form16Policy | viewAny, generate, downloadOwn defined with correct permissions |

#### TC-CR09: Routes — Form16 routes
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect web.php | GET form16/{year}, POST form16/{year}/generate-all, GET my-form16/{year}/download registered |

#### TC-CR10: Service — guardApril15 logic
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `Form16Service::guardApril15()` | Parses endYear from FY, compares now() >= April 15 of endYear; throws DomainException if before |

### 7.1 Positive TC Steps

#### TC-P01: Load Form 16 index for a FY with existing records
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user with pay.form16.generate | Session ready |
| 2 | Navigate to `GET /form16/2025-26` | Index page loads with grid of existing Form 16 records (50/page) and TDS ledger summary table |

#### TC-P02: Generate All Form 16 for employees with TDS > 0
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure current date is after April 15, 2026 | Guard passes |
| 2 | Verify 5 employees have TDS > 0 in TDS ledger for FY 2025-26 | Data exists |
| 3 | Click "Generate All" or `POST /form16/2025-26/generate-all` | Flash "5 Form 16 record(s) generated for FY 2025-26." |
| 4 | Verify DB | 5 Form16 records exist with media_id |

#### TC-P03: Re-generate Form 16 (idempotent)
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Re-generate Form 16 for same FY | Flash indicates count; records updated, not duplicated |

#### TC-P04: Employee downloads own Form 16
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as employee with a generated Form 16 and pay.form16.own.download | Session ready |
| 2 | Navigate to `GET /my-form16/2025-26/download` | PDF file streams; filename `form16-2025-26-{emp_code}.pdf` |

#### TC-P05: Generate All when all employees have zero TDS
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a FY with TDS ledger entries all having tds_deducted = 0 | Zero TDS data |
| 2 | POST to generate-all for that FY | Flash "0 Form 16 record(s) generated..." |

#### TC-P06: Index page renders when no Form 16 records exist
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to a FY where no Form 16 records exist | Empty grid with TDS summary showing pending employees |

#### TC-P07: Pagination on index with 55+ records
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Generate 55 Form 16 records for one FY | Data exists |
| 2 | Navigate to index | Page 1 shows 50 records; pagination visible |
| 3 | Click page 2 | Remaining 5 records displayed |

### 7.2 Negative TC Steps

#### TC-N01: Generate All before April 15
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set system date to March 20, 2026 (before Apr 15, 2026) | Date before guard |
| 2 | POST to `/form16/2025-26/generate-all` | DomainException: "Form 16 for FY 2025-26 cannot be generated before April 15, 2026." |

#### TC-N02: Access index without permission
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user without pay.form16.generate | No permission |
| 2 | Navigate to `GET /form16/2025-26` | HTTP 403 Forbidden |

#### TC-N03: Access generateAll without permission
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user without pay.form16.generate | No permission |
| 2 | POST to `/form16/2025-26/generate-all` | HTTP 403 Forbidden |

#### TC-N04: Access download without permission
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user without pay.form16.own.download | No permission |
| 2 | Navigate to `GET /my-form16/2025-26/download` | HTTP 403 Forbidden |

#### TC-N05: Download Form 16 for FY where no record exists
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as employee with valid permission | Session ready |
| 2 | Navigate to `GET /my-form16/2099-00/download` (FY with no records) | ModelNotFoundException → 404 |

#### TC-N06: Download Form 16 with no linked employee record
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user with no linked employee record | User exists, no employee |
| 2 | Navigate to `GET /my-form16/2025-26/download` | HTTP 403: "No employee record linked." |

#### TC-N07: Access any Form 16 route as guest
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Logout | Guest session |
| 2 | Navigate to any Form 16 URL | Redirect to /login |

#### TC-N08: Index with invalid FY format
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to `GET /form16/invalid` | Route not matched → 404 |

### 7.3 Dependency TC Steps

#### TC-D01: Form16 unique constraint on (employee_id, financial_year)
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Form16 for employee 1, FY 2025-26 | Succeeds |
| 2 | Create another Form16 for same employee+FY | Integrity constraint violation |

#### TC-D02: SoftDeletes on Form16
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Delete a Form16 | deleted_at set; excluded from index |

#### TC-D03: Activity logged on generateAll
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Generate Form 16 | Activity log entry "Form16Generate" with count and FY created |

#### TC-D04: Form16 depends on TDS ledger data
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Generate Form 16 | Generated PDF contains monthly TDS rows from pay_tds_ledger for that employee+FY |
