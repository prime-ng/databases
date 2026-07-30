# hrs_PayrollRuns_TcList

## Module: HrStaff → Payroll → Payroll Runs

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | HrStaff |
| Tab Group | Payroll |
| Feature | Payroll Runs |
| URL(s) | `GET payroll` (index), `POST payroll` (store), `GET payroll/{run}` (show), `POST payroll/{run}/compute`, `GET payroll/{run}/details`, `PUT payroll/{run}/details/{detail}/override`, `POST payroll/{run}/submit`, `POST payroll/{run}/approve`, `POST payroll/{run}/lock`, `GET payroll/{run}/bank-file`, `POST payroll/{run}/mark-paid` |
| Controller | `Modules\HrStaff\Http\Controllers\PayrollController` — `index()` lines 27-36, `store()` lines 38-48, `show()` lines 50-57, `compute()` lines 59-73, `details()` lines 75-85, `override()` lines 87-128, `submit()` lines 130-141, `approve()` lines 143-154, `lock()` lines 156-167, `bankFile()` lines 169-180, `markPaid()` lines 182-193 |
| Model(s) | `Modules\HrStaff\Models\PayrollRun` (table: `pay_payroll_runs`), `Modules\HrStaff\Models\PayrollRunDetail` (table: `pay_payroll_run_details`), `Modules\HrStaff\Models\PayrollOverride` (table: `pay_payroll_overrides`) |
| Validation (Create) | `Modules\HrStaff\Http\Requests\StorePayrollRunRequest` |
| Validation (Override) | `Modules\HrStaff\Http\Requests\OverridePayrollDetailRequest` |
| Policy | `Modules\HrStaff\Policies\PayrollRunPolicy` |
| Permissions | `pay.run.initiate`, `pay.run.compute`, `pay.run.approve`, `pay.run.lock`, `pay.bank_file.export` |
| Pagination | 20 records per page (index), 50 records per page (details) |
| Soft Deletes | Yes — `SoftDeletes` trait on `PayrollRun`, `PayrollRunDetail`, `PayrollOverride` |
| Data Source | Native — records created and computed within the module |

## 2. Pre-conditions

- Required permissions: `pay.run.initiate`, `pay.run.compute`, `pay.run.approve`, `pay.run.lock`, `pay.bank_file.export`
- Required seed data: At least one academic session in `sch_org_academic_sessions_jnt`, active employees with salary assignments, at least one salary structure, compliance records (PF/ESI), PT slabs, confirmed LOP records for LWP computation
- Tenant context initialized with `DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD`
- Payroll run records with various FSM statuses for transition tests
- Employees with and without active salary assignments for guard tests

## 3. Default Data Load

`PayrollController@index()` loads via route `hr-staff.payroll.index` under Payroll tab. No default filters — all active runs, ordered by `payroll_month` desc.

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| Payroll runs grid | `index()` | `PayrollRun::active()->orderByDesc('payroll_month')` | None (is_active = true implicit) | 20/page |

## 4. Test Data Strategy

- Create payroll runs via the `store` POST endpoint with `payroll_month` values spanning 3 different months
- Create runs in each FSM state for transition tests: draft, computed, reviewing, approved, locked
- Create at least 21 active payroll runs to test pagination overflow (20 per page)
- Create employees with and without active salary assignments to test BR-PAY-002 guard
- Create override records with valid and invalid field names/values
- Prep configurations: academic sessions, salary structures with components, pay grades, PT slabs, compliance records, LOP records

## 5. Business Conditions

### 5.1 Database Schema — pay_payroll_runs

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | id | BIGINT UNSIGNED | PK, Auto-increment |
| BC-DB-02 | payroll_month | VARCHAR(7) | NOT NULL |
| BC-DB-03 | academic_year_id | SMALLINT UNSIGNED | NOT NULL, FK → sch_org_academic_sessions_jnt.id |
| BC-DB-04 | run_type | ENUM('regular','supplementary') | NOT NULL, DEFAULT 'regular' |
| BC-DB-05 | parent_run_id | BIGINT UNSIGNED | NULL, FK → pay_payroll_runs.id |
| BC-DB-06 | status | ENUM('draft','computing','computed','reviewing','approved','locked') | NOT NULL, DEFAULT 'draft' |
| BC-DB-07 | initiated_by | INT UNSIGNED | NOT NULL, FK → sch_employees.id |
| BC-DB-08 | approved_by | INT UNSIGNED | NULL, FK → sch_employees.id |
| BC-DB-09 | approved_at | TIMESTAMP | NULL |
| BC-DB-10 | locked_at | TIMESTAMP | NULL |
| BC-DB-11 | total_gross | DECIMAL(14,2) | NULL |
| BC-DB-12 | total_net | DECIMAL(14,2) | NULL |
| BC-DB-13 | employee_count | SMALLINT UNSIGNED | NULL |
| BC-DB-14 | computation_notes | TEXT | NULL |
| BC-DB-15 | is_active | TINYINT(1) | NOT NULL, DEFAULT 1 |
| BC-DB-16 | created_by | BIGINT UNSIGNED | NOT NULL |
| BC-DB-17 | updated_by | BIGINT UNSIGNED | NOT NULL |
| BC-DB-18 | created_at | TIMESTAMP | NULL |
| BC-DB-19 | updated_at | TIMESTAMP | NULL |
| BC-DB-20 | deleted_at | TIMESTAMP | NULL |
| BC-DB-21 | UNIQUE KEY uq_pay_run_month_type | (`payroll_month`, `run_type`) | No duplicate month+type combinations |

### 5.2 Database Schema — pay_payroll_run_details

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-22 | id | BIGINT UNSIGNED | PK, Auto-increment |
| BC-DB-23 | payroll_run_id | BIGINT UNSIGNED | NOT NULL, FK → pay_payroll_runs.id |
| BC-DB-24 | employee_id | INT UNSIGNED | NOT NULL, FK → sch_employees.id |
| BC-DB-25 | salary_assignment_id | BIGINT UNSIGNED | NOT NULL, FK → hrs_salary_assignments.id |
| BC-DB-26 | lop_days | DECIMAL(4,1) | NOT NULL, DEFAULT 0 |
| BC-DB-27 | gross_pay | DECIMAL(12,2) | NOT NULL, DEFAULT 0 |
| BC-DB-28 | lwp_deduction | DECIMAL(12,2) | NOT NULL, DEFAULT 0 |
| BC-DB-29 | pf_employee | DECIMAL(10,2) | NOT NULL, DEFAULT 0 |
| BC-DB-30 | pf_employer | DECIMAL(10,2) | NOT NULL, DEFAULT 0 |
| BC-DB-31 | esi_employee | DECIMAL(10,2) | NOT NULL, DEFAULT 0 |
| BC-DB-32 | esi_employer | DECIMAL(10,2) | NOT NULL, DEFAULT 0 |
| BC-DB-33 | tds_deducted | DECIMAL(10,2) | NOT NULL, DEFAULT 0 |
| BC-DB-34 | pt_deduction | DECIMAL(8,2) | NOT NULL, DEFAULT 0 |
| BC-DB-35 | other_deductions | DECIMAL(10,2) | NOT NULL, DEFAULT 0 |
| BC-DB-36 | total_deductions | DECIMAL(12,2) | NOT NULL, DEFAULT 0 |
| BC-DB-37 | net_pay | DECIMAL(12,2) | NOT NULL, DEFAULT 0 |
| BC-DB-38 | computation_json | JSON | NULL |
| BC-DB-39 | payment_status | ENUM('pending','exported','paid','failed') | NOT NULL, DEFAULT 'pending' |
| BC-DB-40 | is_override | TINYINT(1) | NOT NULL, DEFAULT 0 |
| BC-DB-41 | is_active | TINYINT(1) | NOT NULL, DEFAULT 1 |
| BC-DB-42 | UNIQUE KEY uq_pay_rundetail | (`payroll_run_id`, `employee_id`) | No duplicate employee per run |

### 5.3 Database Schema — pay_payroll_overrides

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-43 | id | BIGINT UNSIGNED | PK, Auto-increment |
| BC-DB-44 | run_detail_id | BIGINT UNSIGNED | NOT NULL, FK → pay_payroll_run_details.id, CASCADE |
| BC-DB-45 | field_name | VARCHAR(50) | NOT NULL |
| BC-DB-46 | original_value | DECIMAL(12,2) | NOT NULL |
| BC-DB-47 | override_value | DECIMAL(12,2) | NOT NULL |
| BC-DB-48 | reason | TEXT | NOT NULL |
| BC-DB-49 | overridden_by | INT UNSIGNED | NOT NULL, FK → sch_employees.id |
| BC-DB-50 | is_active | TINYINT(1) | NOT NULL, DEFAULT 1 |

### 5.4 Validation Rules — StorePayrollRunRequest (Create)

| BC ID | Field | Rule(s) | Error Message |
|-------|-------|---------|---------------|
| BC-VAL-01 | payroll_month | required, string, regex:/^\d{4}-\d{2}$/ | The Payroll Month field is required. |
| BC-VAL-02 | academic_year_id | required, exists:sch_org_academic_sessions_jnt,id | The Academic Year field is required. |
| BC-VAL-03 | run_type | required, in:regular,supplementary | The Run Type field is required. |
| BC-VAL-04 | parent_run_id | nullable, required_if:run_type,supplementary, exists:pay_payroll_runs,id | The Parent Run field is required when Run Type is supplementary. |

### 5.5 Validation Rules — OverridePayrollDetailRequest

| BC ID | Field | Rule(s) | Error Message |
|-------|-------|---------|---------------|
| BC-VAL-05 | field_name | required, string, in:net_pay,tds_deducted,pf_employee,esi_employee,pt_deduction,other_deductions | The selected Field is invalid. |
| BC-VAL-06 | override_value | required, numeric, min:0 | Override Value must be a number and at least 0. |
| BC-VAL-07 | reason | required, string, min:10, max:500 | Override Reason must be at least 10 characters. |

### 5.6 Authorization

| BC ID | Permission | Behavior |
|-------|-----------|----------|
| BC-AUTH-01 | pay.run.initiate | Without: 403 on index, store, show |
| BC-AUTH-02 | pay.run.compute | Without: 403 on compute, details, override, submit |
| BC-AUTH-03 | pay.run.approve | Without: 403 on approve |
| BC-AUTH-04 | pay.run.lock | Without: 403 on lock |
| BC-AUTH-05 | pay.bank_file.export | Without: 403 on bankFile, markPaid |
| BC-AUTH-06 | Guest access | Redirect to /login |

### 5.7 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|------------------|
| BC-BIZ-01 | Index page loads | 20 active runs per page, ordered by payroll_month desc, status badges visible |
| BC-BIZ-02 | Create regular run | Run created with status 'draft', initiated_by set, success flash "Payroll run created." |
| BC-BIZ-03 | Create supplementary run | Run created with parent_run_id linked, run_type='supplementary' |
| BC-BIZ-04 | Compute draft run | Status transitions: draft → computing → computed; aggregates stored; employee_count > 0 |
| BC-BIZ-05 | Compute with unassigned employees | DomainException thrown listing missing employee IDs; no computation occurs |
| BC-BIZ-06 | Submit computed run | Status transitions from computed to reviewing |
| BC-BIZ-07 | Submit non-computed run | DomainException: "Cannot submit payroll with status: {status}" |
| BC-BIZ-08 | Approve reviewing run | Status transitions from reviewing to approved; approved_by and approved_at set |
| BC-BIZ-09 | Approve non-reviewing run | DomainException: "Cannot approve payroll with status: {status}" |
| BC-BIZ-10 | Lock approved run | Status transitions from approved to locked; locked_at set |
| BC-BIZ-11 | Lock non-approved run | DomainException: "Cannot lock payroll with status: {status}" |
| BC-BIZ-12 | Override on locked run | HTTP 422: "Locked payroll cannot be modified." |
| BC-BIZ-13 | Override field (non-net_pay) | Override created; derived fields recalculated; is_override=true |
| BC-BIZ-14 | Override net_pay field | Override created; no derived field recalculation |
| BC-BIZ-15 | Bank file on locked run | CSV downloaded with employee bank details; payment_status → exported |
| BC-BIZ-16 | Bank file on non-locked run | DomainException thrown |
| BC-BIZ-17 | Mark paid on locked run | payment_status → paid for all pending details |
| BC-BIZ-18 | Mark paid on non-locked run | DomainException: "Only locked payroll runs can be marked as paid." |
| BC-BIZ-19 | Details page loads | 50 details per page, sorted by employee_id |
| BC-BIZ-20 | Index pagination | Page 2 loads when ≥21 runs exist |

### 5.8 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|-----------------|----------------|
| BC-REF-01 | pay_payroll_runs.academic_year_id | sch_org_academic_sessions_jnt.id | RESTRICT |
| BC-REF-02 | pay_payroll_runs.parent_run_id | pay_payroll_runs.id | RESTRICT |
| BC-REF-03 | pay_payroll_runs.initiated_by | sch_employees.id | RESTRICT |
| BC-REF-04 | pay_payroll_runs.approved_by | sch_employees.id | RESTRICT |
| BC-REF-05 | pay_payroll_run_details.payroll_run_id | pay_payroll_runs.id | RESTRICT |
| BC-REF-06 | pay_payroll_run_details.employee_id | sch_employees.id | RESTRICT |
| BC-REF-07 | pay_payroll_run_details.salary_assignment_id | hrs_salary_assignments.id | RESTRICT |
| BC-REF-08 | pay_payroll_overrides.run_detail_id | pay_payroll_run_details.id | CASCADE |
| BC-REF-09 | pay_payroll_overrides.overridden_by | sch_employees.id | RESTRICT |

## 6. Test Case List

### 6.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|-----------------|---------|---------|--------|
| TC-P01 | Load payroll runs index page | 20 runs displayed per page, ordered by month desc, status badges rendered, action buttons gated by permissions | — | — | ⬜ |
| TC-P02 | Create a regular payroll run | Run created with status 'draft', redirected to show page with success message | — | — | ⬜ |
| TC-P03 | Create a supplementary payroll run with parent run | Supplementary run created linked to parent, run_type='supplementary' | — | — | ⬜ |
| TC-P04 | Compute a draft payroll run | Status changes draft→computed; totals_gross, total_net, employee_count populated; computation_notes null or populated | — | — | ⬜ |
| TC-P05 | View computed details for a run | 50 details per page, sorted by employee_id, each showing gross, deductions, net | — | — | ⬜ |
| TC-P06 | Override a non-net_pay field on a computed run | Override record created; derived fields recalculated; is_override=true | — | — | ⬜ |
| TC-P07 | Override the net_pay field directly | Override record created; no derived field recalculation | — | — | ⬜ |
| TC-P08 | Submit a computed payroll run for approval | Status transitions computed→reviewing | — | — | ⬜ |
| TC-P09 | Approve a reviewing payroll run | Status transitions reviewing→approved; approved_by and approved_at recorded | — | — | ⬜ |
| TC-P10 | Lock an approved payroll run | Status transitions approved→locked; locked_at recorded | — | — | ⬜ |
| TC-P11 | Download bank file CSV for locked run | CSV downloaded with employee code, name, bank account, IFSC, net pay, NEFT mode; payment_status→exported | — | — | ⬜ |
| TC-P12 | Mark pending details as paid on locked run | All pending details → payment_status='paid' | — | — | ⬜ |
| TC-P13 | Pagination: navigate to page 2 of runs list | Second page loads with remaining runs | — | — | ⬜ |
| TC-P14 | Full lifecycle: create → compute → submit → approve → lock → bank file → mark paid | All FSM transitions complete successfully; each step produces correct status and flash message | — | — | ⬜ |
| TC-P15 | Compute with some employees having LOP records | LWP deduction calculated correctly: (gross_monthly / working_days) × lop_days | — | — | ⬜ |
| TC-P16 | Compute with PF-eligible employees | PF employee 12%, employer EPF 3.67% + EPS 8.33% of capped basic (₹15,000) | — | — | ⬜ |
| TC-P17 | Compute with ESI-eligible employees (gross ≤ ₹21,000) | ESI employee 0.75%, employer 3.25% calculated | — | — | ⬜ |

### 6.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|-----------------|---------|---------|--------|
| TC-N01 | Create run with invalid payroll_month format (not YYYY-MM) | Validation error: The Payroll Month must be in YYYY-MM format. | — | — | ⬜ |
| TC-N02 | Create run with empty payroll_month | Validation error: The Payroll Month field is required. | — | — | ⬜ |
| TC-N03 | Create run with non-existent academic_year_id | Validation error: The Academic Year field is required. | — | — | ⬜ |
| TC-N04 | Create run with invalid run_type | Validation error: The Run Type field is required. | — | — | ⬜ |
| TC-N05 | Create supplementary run without parent_run_id | Validation error: The Parent Run field is required when Run Type is supplementary. | — | — | ⬜ |
| TC-N06 | Create duplicate run (same month + same type) | UNIQUE constraint violation or validation error | — | — | ⬜ |
| TC-N07 | Compute run with employees having no active salary assignment | DomainException listing unassigned employee IDs; no computation occurs | — | — | ⬜ |
| TC-N08 | Submit draft (not computed) run | DomainException: "Cannot submit payroll with status: draft" | — | — | ⬜ |
| TC-N09 | Approve computed (not reviewing) run | DomainException: "Cannot approve payroll with status: computed" | — | — | ⬜ |
| TC-N10 | Lock reviewing (not approved) run | DomainException: "Cannot lock payroll with status: reviewing" | — | — | ⬜ |
| TC-N11 | Override on locked run | HTTP 422: "Locked payroll cannot be modified." | — | — | ⬜ |
| TC-N12 | Override on approved run | HTTP 422: "Approved payroll cannot be recomputed." | — | — | ⬜ |
| TC-N13 | Override with invalid field_name | Validation error: The selected Field is invalid. | — | — | ⬜ |
| TC-N14 | Override with negative override_value | Validation error: Override Value must be a number and at least 0. | — | — | ⬜ |
| TC-N15 | Override with reason < 10 characters | Validation error: Override Reason must be at least 10 characters. | — | — | ⬜ |
| TC-N16 | Override with reason > 500 characters | Validation error: Override Reason must not exceed 500 characters. | — | — | ⬜ |
| TC-N17 | Bank file on non-locked run | DomainException: "Bank file can only be generated for locked payroll runs." | — | — | ⬜ |
| TC-N18 | Mark paid on non-locked run | DomainException: "Only locked payroll runs can be marked as paid." | — | — | ⬜ |
| TC-N19 | Access index without pay.run.initiate permission | HTTP 403 Forbidden | — | — | ⬜ |
| TC-N20 | Access compute without pay.run.compute permission | HTTP 403 Forbidden | — | — | ⬜ |
| TC-N21 | Access approve without pay.run.approve permission | HTTP 403 Forbidden | — | — | ⬜ |
| TC-N22 | Access lock without pay.run.lock permission | HTTP 403 Forbidden | — | — | ⬜ |
| TC-N23 | Access bankFile without pay.bank_file.export permission | HTTP 403 Forbidden | — | — | ⬜ |
| TC-N24 | Access any payroll route as guest | Redirect to /login | — | — | ⬜ |

### 6.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|-----------------|---------|---------|--------|
| TC-D01 | A | PayrollOverride cascade on delete of PayrollRunDetail | Deleting a detail record cascades to delete its override records (CASCADE) | — | — | ⬜ |
| TC-D02 | B | PayrollRun cannot be deleted if it has details (RESTRICT) | FK constraint prevents deleting a run with existing details (no ON DELETE CASCADE on detail FK) | — | — | ⬜ |
| TC-D03 | C | Unique constraint on (payroll_month, run_type) | Second run with same month+type fails with integrity violation | — | — | ⬜ |
| TC-D04 | D | Unique constraint on (payroll_run_id, employee_id) in details | Second detail for same employee in same run fails | — | — | ⬜ |
| TC-D05 | E | SoftDeletes on PayrollRun | Deleted run has deleted_at set; excluded from active queries | — | — | ⬜ |
| TC-D06 | F | SoftDeletes on PayrollRunDetail | Deleted detail excluded; cascade not automatic due to RESTRICT parent FK | — | — | ⬜ |
| TC-D07 | G | PayrollRun `is_active` scope | Inactive runs excluded from index listing | — | — | ⬜ |
| TC-D08 | H | Activity logged on all state changes | Create, Compute, Override, Submit, Approve, Lock, BankFile, MarkPaid each produce activity log entries | — | — | ⬜ |
| TC-D09 | I | PayrollApproved event fires on approve | Event listener/handler executes (if configured) | — | — | ⬜ |
| TC-D10 | J | PayrollLocked event fires on lock | Event listener/handler executes (if configured) | — | — | ⬜ |

### 6.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|-----------------|---------|---------|--------|
| TC-CR01 | CR | P1 | Model — PayrollRun $fillable matches DDL columns | All writable columns (excluding PK, timestamps, deleted_at) are in $fillable | — | — | ◌ |
| TC-CR02 | CR | P1 | Model — PayrollRun $casts for decimals/integers/timestamps | total_gross, total_net cast to decimal:2; employee_count to integer; approved_at, locked_at to datetime; is_active to boolean | — | — | ◌ |
| TC-CR03 | CR | P1 | Model — SoftDeletes on PayrollRun | deleted_at column exists; restore/trashed scopes function | — | — | ◌ |
| TC-CR04 | CR | P1 | Model — PayrollRun relationships: academicYear, parentRun, supplementaryRuns, initiatedByEmployee, approvedByEmployee, details, pfContributions, esiContributions | All defined as BelongsTo/HasMany with correct FKs | — | — | ◌ |
| TC-CR05 | CR | P1 | Controller — Try-catch on compute/submit/approve/lock/markPaid | DomainException caught, flash error displayed | — | — | ◌ |
| TC-CR06 | CR | P1 | Controller — DB transaction in computeRun | Entire multi-employee computation wrapped in DB transaction | — | — | ◌ |
| TC-CR07 | CR | P1 | Controller — Gate::authorize() on every method | Each method checks appropriate permission before execution | — | — | ◌ |
| TC-CR08 | CR | P1 | Controller — Activity logged on create/compute/override/submit/approve/lock/bankFile/markPaid | Each state change calls activityLog() | — | — | ◌ |
| TC-CR09 | CR | P1 | Controller — JSON success response or redirect with flash | All write methods redirect with success flash message | — | — | ◌ |
| TC-CR10 | CR | P1 | Request — StorePayrollRunRequest rules cover payroll_month format, academic_year existence, run_type enum, parent_run conditional | Validation exactly as specified in BC-VAL section | — | — | ◌ |
| TC-CR11 | CR | P1 | Request — OverridePayrollDetailRequest field_name allowlist | Only net_pay, tds_deducted, pf_employee, esi_employee, pt_deduction, other_deductions accepted | — | — | ◌ |
| TC-CR12 | CR | P1 | Policy — PayrollRunPolicy methods defined | viewAny, view, create, compute, approve, lock, delete, restore, forceDelete all defined | — | — | ◌ |
| TC-CR13 | CR | P1 | Routes — All payroll routes registered with model binding | 11 routes for payroll CRUD + FSM actions, route names match controller | — | — | ◌ |
| TC-CR14 | CR | P1 | Database — Unique indexes match validation | uq_pay_run_month_type prevents duplicate month+type; uq_pay_rundetail prevents duplicate employee per run | — | — | ◌ |
| TC-CR15 | CR | P1 | Model — PayrollRunDetail $casts for computation_json as array | Computation JSON stored as array cast | — | — | ◌ |

## 7. Detailed Test Steps

#### TC-CR01: Model — PayrollRun $fillable matches DDL columns
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Compare `PayrollRun::$fillable` array against DDL columns of `pay_payroll_runs` | All writable columns are present in fillable; no extra fillable columns that don't exist in DDL |

#### TC-CR02: Model — PayrollRun $casts for decimals/integers/timestamps
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `PayrollRun::$casts` array | total_gross, total_net → 'decimal:2'; employee_count → 'integer'; approved_at, locked_at → 'datetime'; is_active → 'boolean' |

#### TC-CR03: Model — SoftDeletes on PayrollRun
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Delete a PayrollRun record | deleted_at set to current timestamp |
| 2 | Query active() scope | Deleted run excluded |
| 3 | Call restore() on trashed record | deleted_at set to null |

#### TC-CR04: Model — PayrollRun relationships
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect PayrollRun model | academicYear (BelongsTo), parentRun (BelongsTo self), supplementaryRuns (HasMany self), initiatedByEmployee (BelongsTo), approvedByEmployee (BelongsTo), details (HasMany), pfContributions (HasMany), esiContributions (HasMany) all defined |

#### TC-CR05: Controller — Try-catch on compute/submit/approve/lock/markPaid
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect compute(), submit(), approve(), lock(), markPaid() | Each wraps PayrollRunService call in try-catch for DomainException; catches flash error and redirects back |

#### TC-CR06: Controller — DB transaction in computeRun
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `PayrollComputationService::computeRun()` | Entire employee loop wrapped in `DB::transaction()` |

#### TC-CR07: Controller — Gate::authorize() on every method
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect each public method in PayrollController | Each method has `Gate::authorize('pay.run.*')` as first operation |

#### TC-CR08: Controller — Activity logged on all state changes
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect store(), compute(), override(), submit(), approve(), lock(), bankFile(), markPaid() | Each calls activityLog() after the state change |

#### TC-CR09: Controller — JSON success response or redirect with flash
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect all write methods | Each returns `redirect()->route(...)->with('success', ...)` or `back()->with('error', ...)` |

#### TC-CR10: Request — StorePayrollRunRequest rules
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `StorePayrollRunRequest::rules()` | payroll_month (required+regex), academic_year_id (required+exists), run_type (required+in), parent_run_id (nullable+required_if+exists) |

#### TC-CR11: Request — OverridePayrollDetailRequest field_name allowlist
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `OverridePayrollDetailRequest::rules()` | field_name rule has `in:net_pay,tds_deducted,pf_employee,esi_employee,pt_deduction,other_deductions` |

#### TC-CR12: Policy — PayrollRunPolicy methods defined
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `PayrollRunPolicy` | viewAny, view, create, compute, approve, lock, delete, restore, forceDelete all defined with correct permission checks |

#### TC-CR13: Routes — All payroll routes registered with model binding
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect web.php routes section for payroll | All 11 routes registered: index, store, show, compute, details, override, submit, approve, lock, bankFile, markPaid — each with correct URI and name |

#### TC-CR14: Database — Unique indexes match validation
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Compare DDL unique keys with validation rules | uq_pay_run_month_type prevents duplicate month+type; uq_pay_rundetail prevents duplicate employee per run |

#### TC-CR15: Model — PayrollRunDetail $casts for computation_json as array
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `PayrollRunDetail::$casts` | computation_json → 'array' |

### 7.1 Positive TC Steps

#### TC-P01: Load payroll runs index page
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user with pay.run.initiate permission | Dashboard loads |
| 2 | Navigate to `GET /hr-staff/payroll` | Payroll runs index page loads |
| 3 | Observe the runs table | Up to 20 runs displayed, ordered by payroll_month descending |
| 4 | Observe status column | Each run shows a status badge: draft, computing, computed, reviewing, approved, or locked |

#### TC-P02: Create a regular payroll run
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | On payroll runs index, click "Create Run" | Create form appears |
| 2 | Enter payroll_month "2026-02", select an academic session, select run_type "regular" | Fields populated |
| 3 | Submit the form | Run created with status 'draft'; redirected to show page with "Payroll run created." |
| 4 | Verify the new run appears in index | Run with month 2026-02 in draft status visible |

#### TC-P03: Create a supplementary payroll run with parent run
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | On create form, select run_type "supplementary" | Parent Run dropdown appears |
| 2 | Select a parent regular run, fill month and academic session | All fields valid |
| 3 | Submit | Supplementary run created linked to parent; run_type='supplementary' |

#### TC-P04: Compute a draft payroll run
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open a draft run with active employees who have salary assignments | Show page with "Compute" button visible |
| 2 | Click "Compute" | Status transitions to 'computed'; total_gross, total_net, employee_count populated; success flash "Payroll computed for N employees." |

#### TC-P05: View computed details for a run
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open a computed run | Show page with "View Details" button |
| 2 | Click "View Details" | `GET /payroll/{run}/details` loads with 50 details per page, sorted by employee_id |

#### TC-P06: Override a non-net_pay field on a computed run
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | From details page, click override for a field like tds_deducted | Override form appears |
| 2 | Enter field_name "tds_deducted", override_value "3000", reason "Manual adjustment for partial month" | All fields valid |
| 3 | Submit | Override recorded in pay_payroll_overrides; total_deductions and net_pay recalculated; is_override=true |

#### TC-P07: Override the net_pay field directly
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | From details page, click override for net_pay | Override form appears |
| 2 | Enter field_name "net_pay", override_value "50000", reason "Manual net pay correction due to prior month adjustment" | All fields valid |
| 3 | Submit | Override recorded; no derived field recalculation (net_pay is the final field) |

#### TC-P08: Submit a computed payroll run for approval
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open a computed run | Submit button visible |
| 2 | Click "Submit" | Status → reviewing; success flash "Payroll submitted for approval." |

#### TC-P09: Approve a reviewing payroll run
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user with pay.run.approve permission | Session ready |
| 2 | Open a reviewing run | Approve button visible |
| 3 | Click "Approve" | Status → approved; approved_by and approved_at set; success flash |

#### TC-P10: Lock an approved payroll run
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open an approved run | Lock button visible |
| 2 | Click "Lock" | Status → locked; locked_at set; success flash "Payroll locked." |

#### TC-P11: Download bank file CSV for locked run
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open a locked run with pending payments | "Bank File Export" button visible |
| 2 | Click "Bank File Export" | CSV file `bank-transfer-{month}.csv` downloaded |
| 3 | Check CSV content | Headers: Sr, Employee Code, Employee Name, Bank Account, IFSC, Net Pay, Payment Mode |
| 4 | Check payment_status of details | Changed from 'pending' to 'exported' |

#### TC-P12: Mark pending details as paid on locked run
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open a locked run | "Mark Paid" button visible |
| 2 | Click "Mark Paid" | All pending details updated to payment_status='paid'; success flash "N employees marked as paid." |

#### TC-P13: Pagination: navigate to page 2 of runs list
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure ≥21 payroll runs exist | Data setup complete |
| 2 | Load index page | Page 1 shows first 20 runs, pagination controls visible |
| 3 | Click page 2 | Next set of runs displayed |

#### TC-P14: Full lifecycle: create → compute → submit → approve → lock → bank file → mark paid
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a regular draft run | Run created in draft status |
| 2 | Compute the run | Status → computed with aggregates |
| 3 | Submit the run | Status → reviewing |
| 4 | Approve the run (as approver) | Status → approved |
| 5 | Lock the run | Status → locked |
| 6 | Export bank file | CSV downloaded |
| 7 | Mark as paid | Details → payment_status=paid |

#### TC-P15: Compute with some employees having LOP records
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create LOP records for 2 employees in the target month | LOP records with flag_status='confirmed' exist |
| 2 | Compute a draft run containing those employees | LWP deduction calculated as (gross_monthly / working_days) × lop_days for affected employees |

#### TC-P16: Compute with PF-eligible employees
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set up an employee with PF compliance record and basic+DA ≤ ₹15,000 | PF applicability established |
| 2 | Compute the run | pf_employee = basic×12%, pf_employer = basic×3.67% + basic×8.33% |

#### TC-P17: Compute with ESI-eligible employees
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set up an employee with ESI compliance and gross ≤ ₹21,000 | ESI applicability established |
| 2 | Compute the run | esi_employee = gross×0.75%, esi_employer = gross×3.25% |

### 7.2 Negative TC Steps

#### TC-N01: Create run with invalid payroll_month format
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | On create form, enter payroll_month "Jan-2026" | Invalid format |
| 2 | Submit | Validation error: "The Payroll Month must be in YYYY-MM format." |

#### TC-N02: Create run with empty payroll_month
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Leave payroll_month blank | Empty field |
| 2 | Submit | Validation error: "The Payroll Month field is required." |

#### TC-N03: Create run with non-existent academic_year_id
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter academic_year_id = 99999 | Non-existent ID |
| 2 | Submit | Validation error: "The Academic Year field is required." |

#### TC-N04: Create run with invalid run_type
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter run_type = "invalid" | Not in allowed list |
| 2 | Submit | Validation error: "The Run Type field is required." |

#### TC-N05: Create supplementary run without parent_run_id
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select run_type = "supplementary", leave parent_run_id blank | Conditional requirement triggered |
| 2 | Submit | Validation error: "The Parent Run field is required when Run Type is supplementary." |

#### TC-N06: Create duplicate run (same month + same type)
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a regular run for 2026-01 | First run created |
| 2 | Create another regular run for 2026-01 | UNIQUE constraint violation (dup month+type) |

#### TC-N07: Compute run with employees having no active salary assignment
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create an active employee with no active salary assignment | Employee exists without assignment |
| 2 | Compute a draft run | DomainException listing the unassigned employee ID; no computation occurs |

#### TC-N08: Submit draft (not computed) run
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a draft run, do NOT compute it | Run in draft status |
| 2 | Click "Submit" | DomainException: "Cannot submit payroll with status: draft" |

#### TC-N09: Approve computed (not reviewing) run
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a computed run | Status = computed |
| 2 | Click "Approve" (as approver) | DomainException: "Cannot approve payroll with status: computed" |

#### TC-N10: Lock reviewing (not approved) run
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a reviewing run | Status = reviewing |
| 2 | Click "Lock" | DomainException: "Cannot lock payroll with status: reviewing" |

#### TC-N11: Override on locked run
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Lock a run | Status = locked |
| 2 | Attempt override on a detail field | HTTP 422: "Locked payroll cannot be modified." |

#### TC-N12: Override on approved run
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Approve a run (status = approved) but do NOT lock | Status = approved |
| 2 | Attempt override on a detail field | HTTP 422: "Approved payroll cannot be recomputed." |

#### TC-N13: Override with invalid field_name
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter field_name = "gross_pay" | Not in allowlist |
| 2 | Submit | Validation error: "The selected Field is invalid." |

#### TC-N14: Override with negative override_value
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter override_value = "-100" | Negative value |
| 2 | Submit | Validation error: "Override Value must be a number and at least 0." |

#### TC-N15: Override with reason < 10 characters
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter reason = "Fix" | Too short |
| 2 | Submit | Validation error: "Override Reason must be at least 10 characters." |

#### TC-N16: Override with reason > 500 characters
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter reason text of 501 characters | Too long |
| 2 | Submit | Validation error: "Override Reason must not exceed 500 characters." |

#### TC-N17: Bank file on non-locked run
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open a run that is not locked (e.g. approved) | Status ≠ locked |
| 2 | Click "Bank File Export" | DomainException: "Bank file can only be generated for locked payroll runs." |

#### TC-N18: Mark paid on non-locked run
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open a run that is not locked | Status ≠ locked |
| 2 | Click "Mark Paid" | DomainException: "Only locked payroll runs can be marked as paid." |

#### TC-N19: Access index without pay.run.initiate permission
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user without pay.run.initiate | No permission |
| 2 | Navigate to `GET /hr-staff/payroll` | HTTP 403 Forbidden |

#### TC-N20: Access compute without pay.run.compute permission
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user without pay.run.compute | No permission |
| 2 | POST to `/payroll/{run}/compute` | HTTP 403 Forbidden |

#### TC-N21: Access approve without pay.run.approve permission
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user without pay.run.approve | No permission |
| 2 | POST to `/payroll/{run}/approve` | HTTP 403 Forbidden |

#### TC-N22: Access lock without pay.run.lock permission
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user without pay.run.lock | No permission |
| 2 | POST to `/payroll/{run}/lock` | HTTP 403 Forbidden |

#### TC-N23: Access bankFile without pay.bank_file.export permission
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user without pay.bank_file.export | No permission |
| 2 | GET `/payroll/{run}/bank-file` | HTTP 403 Forbidden |

#### TC-N24: Access any payroll route as guest
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Logout (guest session) | No auth |
| 2 | Navigate to any payroll URL | Redirect to /login |

### 7.3 Dependency TC Steps

#### TC-D01: PayrollOverride cascade on delete of PayrollRunDetail
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a PayrollRunDetail with an override record | Both exist |
| 2 | Force-delete the PayrollRunDetail | Associated PayrollOverride records are also deleted (CASCADE) |

#### TC-D02: PayrollRun cannot be deleted if it has details
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Attempt to delete a PayrollRun that has child details | FK constraint violation (RESTRICT) prevents deletion |

#### TC-D03: Unique constraint on (payroll_month, run_type)
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Insert a payroll run with month=2026-01, type=regular | Succeeds |
| 2 | Insert another run with same month=2026-01, type=regular | Integrity constraint violation (duplicate key) |

#### TC-D04: Unique constraint on (payroll_run_id, employee_id) in details
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a detail for employee 1 in run 5 | Succeeds |
| 2 | Create another detail for employee 1 in same run 5 | Integrity constraint violation |

#### TC-D05: SoftDeletes on PayrollRun
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Delete a PayrollRun via model | deleted_at set; record excluded from active() scope |
| 2 | Query index page | Deleted run not visible |

#### TC-D06: SoftDeletes on PayrollRunDetail
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Delete a PayrollRunDetail | deleted_at set; excluded from active() scope |

#### TC-D07: PayrollRun `is_active` scope
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set is_active=0 on a PayrollRun | Run excluded from index |

#### TC-D08: Activity logged on all state changes
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Perform create, compute, override, submit, approve, lock, bankFile, markPaid | Each action produces an entry in the activity log with relevant description |

#### TC-D09: PayrollApproved event fires on approve
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Approve a reviewing run | PayrollApproved event dispatched (verify via event listener or log) |

#### TC-D10: PayrollLocked event fires on lock
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Lock an approved run | PayrollLocked event dispatched (verify via event listener or log) |
