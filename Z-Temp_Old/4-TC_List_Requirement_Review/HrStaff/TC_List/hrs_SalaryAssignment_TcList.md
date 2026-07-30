# hrs_SalaryAssignment_TcList

## Module: HrStaff → Employee → Salary

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | HrStaff |
| Tab Group | Employee |
| Feature | Salary Assignment |
| URL(s) | `GET employees/{employee}/salary` (show), `POST employees/{employee}/salary` (store), `PUT employees/{employee}/salary` (update), `POST employees/{employee}/salary-revision` (revision) |
| Controller | `Modules\HrStaff\Http\Controllers\SalaryAssignmentController` — `show()` lines 27-44, `store()` lines 49-67, `update()` lines 72-86, `revision()` lines 91-109 |
| Model(s) | `Modules\HrStaff\Models\SalaryAssignment` (table: `hrs_salary_assignments`) |
| Validation (Create/Update) | `Modules\HrStaff\Http\Requests\StoreSalaryAssignmentRequest` |
| Policy | `Modules\HrStaff\Policies\SalaryAssignmentPolicy` |
| Permissions | `hrs.salary.manage` |
| Pagination | None (single-employee view) |
| Soft Deletes | Yes — `SoftDeletes` trait on `SalaryAssignment` |
| Data Source | Native — records created within the module |

## 2. Pre-conditions

- Required permission: `hrs.salary.manage`
- Required seed data: At least one employee, one active salary structure, one active pay grade with defined min/max CTC range
- Tenant context initialized with `DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD`
- Employees with and without existing salary assignments for full coverage
- Pay grades with overlapping and non-overlapping CTC ranges for validation testing

## 3. Default Data Load

`SalaryAssignmentController@show(Employee)` loads via route `hr-staff.salary.show` under the Employee → Salary relationship view.

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| Active assignment | `getActiveAssignment()` | `SalaryAssignment::where('employee_id', $id)->whereNull('effective_to_date')->active()->with('salaryStructure', 'payGrade')` | is_active, effective_to_date IS NULL | None |
| History | `show()` | `SalaryAssignment::where('employee_id', $id)->with('salaryStructure', 'payGrade')->orderByDesc('effective_from_date')` | None | None |
| Structure dropdown | `show()` | `SalaryStructure::active()->orderBy('name')` | is_active | None |
| Pay Grade dropdown | `show()` | `PayGrade::active()->orderBy('grade_name')` | is_active | None |

## 4. Test Data Strategy

- Create employees with 0, 1, and 3+ historical assignments to test active/history rendering
- Create pay grades with known min/max ranges (e.g. Grade A: 2L-5L, Grade B: 5L-10L) for CTC validation
- Create salary structures with various applicable_to categories
- Test revision by first creating an initial assignment, then revising it
- Verify that after revision, only one active assignment exists with correct effective_to_date closure

## 5. Business Conditions

### 5.1 Database Schema — hrs_salary_assignments

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | id | BIGINT UNSIGNED | PK, Auto-increment |
| BC-DB-02 | employee_id | INT UNSIGNED | NOT NULL, FK → sch_employees.id |
| BC-DB-03 | pay_salary_structure_id | BIGINT UNSIGNED | NOT NULL, FK → pay_salary_structures.id |
| BC-DB-04 | pay_grade_id | BIGINT UNSIGNED | NULL, FK → hrs_pay_grades.id |
| BC-DB-05 | ctc_amount | DECIMAL(12,2) | NOT NULL |
| BC-DB-06 | gross_monthly | DECIMAL(12,2) | NOT NULL |
| BC-DB-07 | effective_from_date | DATE | NOT NULL |
| BC-DB-08 | effective_to_date | DATE | NULL |
| BC-DB-09 | revision_reason | VARCHAR(200) | NULL |
| BC-DB-10 | is_active | TINYINT(1) | NOT NULL, DEFAULT 1 |
| BC-DB-11 | deleted_at | TIMESTAMP | NULL |

### 5.2 Validation Rules — StoreSalaryAssignmentRequest

| BC ID | Field | Rule(s) | Error Message |
|-------|-------|---------|---------------|
| BC-VAL-01 | pay_salary_structure_id | required, exists:pay_salary_structures,id | The Salary Structure field is required. |
| BC-VAL-02 | pay_grade_id | nullable, exists:hrs_pay_grades,id | The Pay Grade field is required. |
| BC-VAL-03 | ctc_amount | required, numeric, min:0 | Annual CTC must be a number and at least 0. |
| BC-VAL-04 | gross_monthly | required, numeric, min:0 | Monthly Gross must be a number and at least 0. |
| BC-VAL-05 | effective_from_date | required, date | The Effective From field is required. |
| BC-VAL-06 | revision_reason | nullable, string, max:200 | Revision Reason must not exceed 200 characters. |
| BC-VAL-07 | **CTC outside grade range** | Controller: `validateCtcInGrade()` | "CTC ₹{amount} is outside pay grade range ₹{min} – ₹{max} (BR-HRS-011)." |

### 5.3 Authorization

| BC ID | Permission | Behavior |
|-------|-----------|----------|
| BC-AUTH-01 | hrs.salary.manage | Without: 403 on show, store, update, revision |
| BC-AUTH-02 | Guest access | Redirect to /login |

### 5.4 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|------------------|
| BC-BIZ-01 | Show employee with active assignment | Active assignment displayed with structure, grade details; history list visible |
| BC-BIZ-02 | Show employee with no assignment | Empty state: "No salary assigned" shown; structure + grade dropdowns available |
| BC-BIZ-03 | Store (first assignment) | Assignment created with effective_to_date=null; success flash |
| BC-BIZ-04 | Store for employee with existing active assignment | Prior assignment closed (effective_to_date set); new assignment created |
| BC-BIZ-05 | Update active assignment in-place | Same assignment record updated; effective_to_date unchanged (null) |
| BC-BIZ-06 | Update with no active assignment | DomainException: "No active salary assignment found." |
| BC-BIZ-07 | Revision with valid data | Old assignment closed; new assignment created; employment history logged |
| BC-BIZ-08 | Revision without revision_reason | Operation succeeds (revision_reason nullable); history logged with default reason |
| BC-BIZ-09 | CTC within grade range | Assignment created/updated successfully |
| BC-BIZ-10 | CTC outside grade range | DomainException with grade range details |
| BC-BIZ-11 | Pay grade not selected | No grade validation applied; assignment created with pay_grade_id=null |
| BC-BIZ-12 | Concurrent assignment prevention | `lockForUpdate()` prevents race conditions on simultaneous assigns |

### 5.5 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|-----------------|----------------|
| BC-REF-01 | hrs_salary_assignments.employee_id | sch_employees.id | RESTRICT |
| BC-REF-02 | hrs_salary_assignments.pay_salary_structure_id | pay_salary_structures.id | RESTRICT |
| BC-REF-03 | hrs_salary_assignments.pay_grade_id | hrs_pay_grades.id | RESTRICT |

## 6. Test Case List

### 6.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|-----------------|---------|---------|--------|
| TC-P01 | View employee salary show page with active assignment | Active assignment details + history + structure/grade dropdowns displayed | — | — | ⬜ |
| TC-P02 | View employee salary show page with no assignment | Empty state with dropdowns available for new assignment | — | — | ⬜ |
| TC-P03 | Assign salary to new employee (no prior assignment) | Assignment created with effective_to_date=null; success flash | — | — | ⬜ |
| TC-P04 | Assign salary to employee with existing active assignment | Prior assignment closed; new assignment created | — | — | ⬜ |
| TC-P05 | Update active assignment in-place | Same record updated; effective_to_date remains null | — | — | ⬜ |
| TC-P06 | Revise salary (create new revision) | Old closed; new created; history logged | — | — | ⬜ |
| TC-P07 | Assign with pay grade within CTC range | CTC validated against grade; assignment created | — | — | ⬜ |
| TC-P08 | Assign without pay grade (null) | No grade validation; assignment created | — | — | ⬜ |
| TC-P09 | View salary history shows multiple revisions | History timeline lists all past assignments ordered by effective_from desc | — | — | ⬜ |

### 6.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|-----------------|---------|---------|--------|
| TC-N01 | Store with empty pay_salary_structure_id | Validation error: The Salary Structure field is required. | — | — | ⬜ |
| TC-N02 | Store with non-existent salary structure ID | Validation error (exists rule fails) | — | — | ⬜ |
| TC-N03 | Store with non-existent pay_grade_id | Validation error (exists rule fails) | — | — | ⬜ |
| TC-N04 | Store with negative ctc_amount | Validation error: Annual CTC must be a number and at least 0. | — | — | ⬜ |
| TC-N05 | Store with negative gross_monthly | Validation error: Monthly Gross must be a number and at least 0. | — | — | ⬜ |
| TC-N06 | Store with empty effective_from_date | Validation error: The Effective From field is required. | — | — | ⬜ |
| TC-N07 | Store with CTC outside pay grade range | DomainException: "CTC ₹{amount} is outside pay grade range..." | — | — | ⬜ |
| TC-N08 | Update with no active assignment | DomainException: "No active salary assignment found." | — | — | ⬜ |
| TC-N09 | Revision with revision_reason > 200 characters | Validation error: Revision Reason must not exceed 200 characters. | — | — | ⬜ |
| TC-N10 | Access show without hrs.salary.manage permission | HTTP 403 Forbidden | — | — | ⬜ |
| TC-N11 | Access store without hrs.salary.manage permission | HTTP 403 Forbidden | — | — | ⬜ |
| TC-N12 | Access any salary route as guest | Redirect to /login | — | — | ⬜ |
| TC-N13 | View salary for non-existent employee | ModelNotFoundException → 404 | — | — | ⬜ |

### 6.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|-----------------|---------|---------|--------|
| TC-D01 | A | SoftDeletes on SalaryAssignment | Deleted assignment excluded from queries | — | — | ⬜ |
| TC-D02 | B | SalaryAssignment FK RESTRICT on employee delete | Cannot delete employee with active assignment | — | — | ⬜ |
| TC-D03 | C | Assignment blocks PayrollRunDetail FK | Cannot delete assignment referenced by payroll details (RESTRICT) | — | — | ⬜ |
| TC-D04 | D | Activity logged on assign, update, revise | Each operation creates activity log entry | — | — | ⬜ |
| TC-D05 | E | Employment history created on revision | hrs_employment_history record created with old/new CTC values | — | — | ⬜ |
| TC-D06 | F | `is_active` scope filtering | Inactive assignments hidden from active query | — | — | ⬜ |

### 6.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|-----------------|---------|---------|--------|
| TC-CR01 | CR | P1 | Model — SalaryAssignment $fillable matches DDL | employee_id, pay_salary_structure_id, pay_grade_id, ctc_amount, gross_monthly, effective_from_date, effective_to_date, revision_reason, is_active, created_by, updated_by in fillable | — | — | ◌ |
| TC-CR02 | CR | P1 | Model — $casts for decimals/dates/boolean | ctc_amount, gross_monthly → decimal:2; effective_from/to → date; is_active → boolean | — | — | ◌ |
| TC-CR03 | CR | P1 | Model — SoftDeletes | deleted_at column exists | — | — | ◌ |
| TC-CR04 | CR | P1 | Model — Relationships: employee, salaryStructure, payGrade, payrollRunDetails | BelongsTo/HasMany defined with correct FKs | — | — | ◌ |
| TC-CR05 | CR | P1 | Controller — Try-catch on store/update/revision | DomainException caught; back()->with('error') | — | — | ◌ |
| TC-CR06 | CR | P1 | Controller — DB transaction on assign/revise | Multi-step writes wrapped in DB::transaction() | — | — | ◌ |
| TC-CR07 | CR | P1 | Controller — Gate::authorize() on show/store/update/revision | Each checks hrs.salary.manage | — | — | ◌ |
| TC-CR08 | CR | P1 | Controller — Activity logged on all state changes | store, update, revision each call activityLog() | — | — | ◌ |
| TC-CR09 | CR | P1 | Request — StoreSalaryAssignmentRequest rules cover all required fields | All fields validated as per BC-VAL section | — | — | ◌ |
| TC-CR10 | CR | P1 | Policy — SalaryAssignmentPolicy methods defined | viewAny, view, create, update, delete, restore, forceDelete all defined with hrs.salary.manage | — | — | ◌ |
| TC-CR11 | CR | P1 | Routes — salary routes registered | employees/{employee}/salary (GET/POST/PUT) and salary-revision (POST) | — | — | ◌ |
| TC-CR12 | CR | P1 | Service — validateCtcInGrade logic | Correctly validates CTC against pay grade's min_ctc and max_ctc | — | — | ◌ |

## 7. Detailed Test Steps

#### TC-CR01: Model — SalaryAssignment $fillable matches DDL
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Compare `SalaryAssignment::$fillable` against DDL of `hrs_salary_assignments` | employee_id, pay_salary_structure_id, pay_grade_id, ctc_amount, gross_monthly, effective_from_date, effective_to_date, revision_reason, is_active, created_by, updated_by present |

#### TC-CR02: Model — $casts
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `SalaryAssignment::$casts` | ctc_amount → 'decimal:2', gross_monthly → 'decimal:2', effective_from_date → 'date', effective_to_date → 'date', is_active → 'boolean' |

#### TC-CR03: Model — SoftDeletes
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Delete a SalaryAssignment | deleted_at set; excluded from active/current scopes |

#### TC-CR04: Model — Relationships
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect SalaryAssignment model | employee (BelongsTo), salaryStructure (BelongsTo), payGrade (BelongsTo), payrollRunDetails (HasMany) |

#### TC-CR05: Controller — Try-catch on store/update/revision
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect store(), update(), revision() | Each wraps AssignmentService call in try-catch for DomainException |

#### TC-CR06: Controller — DB transaction on assign/revise
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `SalaryAssignmentService::assign()` | Close + create wrapped in DB::transaction() |
| 2 | Inspect `SalaryAssignmentService::revise()` | Calls assign() + logHistory in transaction |

#### TC-CR07: Controller — Gate::authorize() on all methods
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect show, store, update, revision | Each has Gate::authorize('hrs.salary.manage') |

#### TC-CR08: Controller — Activity logged
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect store, update, revision | Each calls activityLog() after success |

#### TC-CR09: Request — StoreSalaryAssignmentRequest rules
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `StoreSalaryAssignmentRequest::rules()` | All 6 fields validated as per BC-VAL |

#### TC-CR10: Policy — SalaryAssignmentPolicy
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect SalaryAssignmentPolicy | viewAny, view, create, update, delete, restore, forceDelete all defined with hrs.salary.manage |

#### TC-CR11: Routes — salary routes
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect web.php | GET employees/{employee}/salary, POST employees/{employee}/salary, PUT employees/{employee}/salary, POST employees/{employee}/salary-revision |

#### TC-CR12: Service — validateCtcInGrade logic
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `SalaryAssignmentService::validateCtcInGrade()` | Compares CTC against payGrade->min_ctc and max_ctc; throws DomainException if outside range |

### 7.1 Positive TC Steps

#### TC-P01: View employee salary show page with active assignment
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user with hrs.salary.manage | Session ready |
| 2 | Navigate to `GET /employees/{employee}/salary` where employee has an active assignment | Active assignment card visible (structure name, CTC, gross, grade); history list below; structure + grade dropdowns loaded |

#### TC-P02: View employee salary show page with no assignment
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to salary page for employee with no assignments | Empty state message "No salary assigned"; structure + grade dropdowns available for creating new assignment |

#### TC-P03: Assign salary to new employee
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select structure "Teaching Staff", grade "Grade B", CTC 360000, gross 28500, effective_from "2026-01-01" | All fields valid |
| 2 | Submit via POST to `/employees/{employee}/salary` | Assignment created with effective_to_date=null; flash "Salary assigned successfully." |

#### TC-P04: Assign salary to employee with existing active assignment
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Employee currently has active assignment A | Assignment A exists with effective_to_date=null |
| 2 | Submit a new assignment | Assignment A's effective_to_date set to new assignment's effective_from; new assignment created with effect_to_date=null |

#### TC-P05: Update active assignment in-place
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Change CTC from 360000 to 380000 via PUT to `/employees/{employee}/salary` | Same assignment record updated; effective_to_date unchanged (still null); flash "Salary assignment updated successfully." |

#### TC-P06: Revise salary (create new revision)
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit revision via POST to `/employees/{employee}/salary-revision` with new CTC 600000, effective_from "2026-07-01", reason "Promotion to Senior Teacher" | Old assignment closed (effective_to_date = 2026-07-01); new assignment created; employment history logged; flash "Salary revision recorded successfully." |

#### TC-P07: Assign with pay grade within CTC range
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select grade with min=300000, max=500000, enter CTC=400000 | Validation passes; assignment created |

#### TC-P08: Assign without pay grade (null)
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Leave pay_grade_id empty | No grade validation; assignment created with pay_grade_id=null |

#### TC-P09: View salary history shows multiple revisions
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Perform 3 salary revisions for an employee | 4 assignments total (1 original + 3 revisions) |
| 2 | View salary show page | History lists all 4 assignments ordered by effective_from_date desc |

### 7.2 Negative TC Steps

#### TC-N01: Store with empty pay_salary_structure_id
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Leave pay_salary_structure_id empty | Validation error: "The Salary Structure field is required." |

#### TC-N02: Store with non-existent salary structure ID
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter pay_salary_structure_id = 99999 | Validation error (exists rule) |

#### TC-N03: Store with non-existent pay_grade_id
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter pay_grade_id = 99999 | Validation error (exists rule) |

#### TC-N04: Store with negative ctc_amount
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter ctc_amount = -1000 | Validation error: "Annual CTC must be a number and at least 0." |

#### TC-N05: Store with negative gross_monthly
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter gross_monthly = -1000 | Validation error: "Monthly Gross must be a number and at least 0." |

#### TC-N06: Store with empty effective_from_date
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Leave effective_from_date empty | Validation error: "The Effective From field is required." |

#### TC-N07: Store with CTC outside pay grade range
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select grade B (min=300000, max=500000), enter CTC=800000 | DomainException: "CTC ₹800000 is outside pay grade range ₹300000 – ₹500000 (BR-HRS-011)." |

#### TC-N08: Update with no active assignment
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | PUT to `/employees/{employee}/salary` where employee has no assignments | DomainException: "No active salary assignment found." |

#### TC-N09: Revision with revision_reason > 200 characters
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter revision_reason text of 201 characters | Validation error: "Revision Reason must not exceed 200 characters." |

#### TC-N10: Access show without permission
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user without hrs.salary.manage | No permission |
| 2 | Navigate to salary show page | HTTP 403 Forbidden |

#### TC-N11: Access store without permission
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user without hrs.salary.manage | No permission |
| 2 | POST to `/employees/{employee}/salary` | HTTP 403 Forbidden |

#### TC-N12: Access any salary route as guest
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Logout | Guest session |
| 2 | Navigate to any salary URL | Redirect to /login |

#### TC-N13: View salary for non-existent employee
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to `/employees/99999/salary` | ModelNotFoundException → 404 |

### 7.3 Dependency TC Steps

#### TC-D01: SoftDeletes on SalaryAssignment
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Delete a SalaryAssignment | deleted_at set; excluded from active() and current() scopes |

#### TC-D02: SalaryAssignment FK RESTRICT on employee delete
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Attempt to delete an employee who has a salary assignment | FK constraint violation (RESTRICT) prevents deletion |

#### TC-D03: Assignment referenced by PayrollRunDetail
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Attempt to delete a SalaryAssignment that is referenced by PayrollRunDetail | FK constraint violation (RESTRICT) |

#### TC-D04: Activity logged on assign, update, revise
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Perform assign, update, revise operations | Activity log entries: "Salary assigned.", "Salary assignment updated.", "Salary revised." |

#### TC-D05: Employment history created on revision
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Perform a salary revision | hrs_employment_history record created with change_type='salary_revision', old_value (old CTC + structure), new_value (new CTC + structure) |

#### TC-D06: `is_active` scope filtering
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set is_active=0 on a SalaryAssignment | Record excluded from show page's active assignment retrieval |
