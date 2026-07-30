# Salary Assignment — Business Requirements

## What This Screen Does

The Salary Assignment screen allows HR managers to assign salary structures to individual employees, define their annual CTC and monthly gross, and link them to a pay grade band. It supports the full lifecycle of salary management — initial assignment, in-place updates, and revisions with effective dating and employment history tracking.

The screen enforces a critical business rule: only one active assignment can exist per employee at any time. When a new assignment or revision is created, the prior active assignment is automatically closed by setting its `effective_to_date`.

## When This Screen Is Used

- **New employee onboarding** when HR assigns a salary structure to a newly joined employee
- **Salary revision** when an employee receives a pay raise, promotion, or grade change
- **Salary correction** when HR needs to update an existing assignment's details before it takes effect
- **Salary audit** when reviewing current and historical salary assignments for any employee

## Default Data Load

The `SalaryAssignmentController@show` method loads the salary assignment screen under the Employee → Salary tab group, reached via route `hr-staff.salary.show` with `{employee}` parameter. It gates on `hrs.salary.manage`. It loads:

- The current active assignment (where `effective_to_date` is null and `is_active` is true) via `SalaryAssignmentService::getActiveAssignment()`
- Full assignment history ordered by `effective_from_date` descending
- All active salary structures for the dropdown selector
- All active pay grades for the dropdown selector

## Key Fields at a Glance

**Assignment Identity**
- `employee_id` — the employee this assignment belongs to
- `pay_salary_structure_id` — the selected salary structure (e.g. "Teaching Staff Structure")
- `pay_grade_id` — optional pay grade band (e.g. "Grade B")

**Financial Values**
- `ctc_amount` — annual Cost to Company in INR (must fall within the pay grade's min/max range if a grade is selected)
- `gross_monthly` — monthly gross salary (CTC/12 minus employer PF/ESI contributions)

**Effective Dating**
- `effective_from_date` — date from which this assignment is active
- `effective_to_date` — automatically set to the next assignment's `effective_from_date` when a revision is created; `null` for the currently active assignment
- `revision_reason` — optional explanation for the change (used during salary revision)

## Business Rules and Conditions

**Single Active Assignment (BR-HRS-010)** — Only one salary assignment per employee can have `effective_to_date = null` at a time. The `assign()` and `revise()` methods use `lockForUpdate()` to prevent race conditions and automatically close the prior assignment.

**CTC in Pay Grade Range (BR-HRS-011)** — If a pay grade is selected, the annual CTC must fall within that grade's `min_ctc` and `max_ctc` range. Violating this throws a `DomainException` with a descriptive message.

**Salary Revision Creates History (BR-HRS-013)** — A salary revision closes the current active assignment, creates a new assignment with its own effective date, and records the change in the employment history table via `EmploymentService::logHistory()`.

## Workflow Steps

**Viewing Current Salary** — HR navigates to the employee's profile, clicks the "Salary" tab. The system shows the active assignment's details (structure, CTC, gross, grade) along with a timeline of historical assignments.

**Assigning Salary (First Time)** — For a new employee with no prior assignment, HR selects a salary structure, optionally chooses a pay grade, enters the annual CTC, monthly gross, and the effective from date. The system validates CTC against the grade range, closes any prior active assignment (none in this case), and creates the new assignment.

**Updating Salary (In-Place)** — HR modifies the active assignment's details (e.g. correcting the gross amount). The system validates and updates the record in place without creating history. No employment history entry is created.

**Revising Salary** — HR triggers a salary revision by entering the new structure, CTC, gross, effective date, and a revision reason. The system closes the current active assignment (setting `effective_to_date`), creates a new assignment with the new values, and logs the change in the employment history table.

## Example Scenario

Green Valley School hires a new teacher, Priya. HR Manager Rajesh opens Priya's profile, navigates to the Salary tab, and sees no active assignment. He selects "Teaching Staff Structure" from the structure dropdown, chooses pay grade "Grade B" (min CTC ₹3,00,000, max CTC ₹5,00,000), enters annual CTC ₹3,60,000, monthly gross ₹28,500, and effective date as the joining date. The system validates and creates the assignment.

Six months later, Priya receives a promotion. Rajesh initiates a revision: selects "Senior Teacher Structure," pay grade "Grade A" (min ₹5,00,000, max ₹8,00,000), enters CTC ₹6,00,000, and provides the reason "Promotion to Senior Teacher effective July 2026." The system closes the prior assignment, creates a new one with effective from July 1, 2026, and records the revision in employment history.

## Related Screens

- **Employee Profile** — the parent screen under which the Salary tab is accessed
- **Salary Structure** — defines the component breakdown template used by the assignment
- **Pay Grades** — defines CTC bands that assignments must comply with
- **Employment History** — receives a log entry when a salary revision occurs

## Requirements

- `SalaryAssignmentController@show(Employee)` — renders salary assignment view with active, history, structures, and pay grades; gates on `hrs.salary.manage`
- `SalaryAssignmentController@store(StoreSalaryAssignmentRequest, Employee)` — assigns salary; gates on `hrs.salary.manage`; creates via `SalaryAssignmentService::assign()`; logs "Salary assigned." activity
- `SalaryAssignmentController@update(StoreSalaryAssignmentRequest, Employee)` — updates active assignment; gates on `hrs.salary.manage`; updates via `SalaryAssignmentService::update()`; logs "Salary assignment updated." activity
- `SalaryAssignmentController@revision(StoreSalaryAssignmentRequest, Employee)` — creates salary revision; gates on `hrs.salary.manage`; processes via `SalaryAssignmentService::revise()`; logs "Salary revised." activity
- `StoreSalaryAssignmentRequest` — validates `pay_salary_structure_id` (required, exists on `pay_salary_structures`), `pay_grade_id` (nullable, exists on `hrs_pay_grades`), `ctc_amount` (required, numeric, min:0), `gross_monthly` (required, numeric, min:0), `effective_from_date` (required, date), `revision_reason` (nullable, string, max:200)
- `SalaryAssignmentService::assign()` — validates CTC in pay grade range; uses `lockForUpdate()` to close prior active; creates new assignment
- `SalaryAssignmentService::update()` — validates CTC in pay grade range; updates active assignment in place
- `SalaryAssignmentService::revise()` — calls `assign()` to close old + create new; logs employment history via `EmploymentService::logHistory()`
- `SalaryAssignmentService::validateCtcInGrade()` — throws `DomainException` if CTC outside grade range
- `SalaryAssignmentPolicy` — defines viewAny, view, create, update, delete, restore, forceDelete all gated on `hrs.salary.manage`
- Model uses `SoftDeletes`, `$casts` for `ctc_amount`, `gross_monthly` (decimal:2), `effective_from`/`to` (date), `is_active` (boolean)
- Relationships: `employee()` (BelongsTo Employee), `salaryStructure()` (BelongsTo SalaryStructure), `payGrade()` (BelongsTo PayGrade), `payrollRunDetails()` (HasMany PayrollRunDetail)

## Who Can Access

| Gate/Permission | Methods | Notes |
|-----------------|---------|-------|
| `hrs.salary.manage` | `show`, `store`, `update`, `revision` | Full CRUD on salary assignments |
| Policy | `SalaryAssignmentPolicy` | Applied via Gate::authorize() in each method; all methods use same permission |

## Logic Flow

**Page Load (show)** — User with `hrs.salary.manage` accesses `employees/{employee}/salary`. The service queries the active assignment (`whereNull('effective_to_date')->active()->with(['salaryStructure', 'payGrade'])`), the full history ordered by effective_from_date desc, all active salary structures, and all active pay grades.

**Store (assign)** — User submits the form. `StoreSalaryAssignmentRequest` validates all fields. `SalaryAssignmentService::assign()` runs in a transaction: optionally validates CTC against grade range (BR-HRS-011), locks prior active assignments with `lockForUpdate()`, closes them by setting `effective_to_date`, creates a new assignment with `employee_id`, status fields, and returns it.

**Update** — Same request validation. `SalaryAssignmentService::update()` finds the active assignment, optionally validates CTC against grade, updates the record in place.

**Revision** — Same request, must include `revision_reason`. `SalaryAssignmentService::revise()` calls `assign()` to close old and create new, then logs the change via `EmploymentService::logHistory()` with old and new CTC values and structure IDs.

## Validate Before Save

| Field | Rule(s) | Error Message |
|-------|---------|---------------|
| `pay_salary_structure_id` | required, exists:pay_salary_structures,id | The Salary Structure field is required. |
| `pay_grade_id` | nullable, exists:hrs_pay_grades,id | The Pay Grade field is required. |
| `ctc_amount` | required, numeric, min:0 | Annual CTC must be a number and at least 0. |
| `gross_monthly` | required, numeric, min:0 | Monthly Gross must be a number and at least 0. |
| `effective_from_date` | required, date | The Effective From field is required. |
| `revision_reason` | nullable, string, max:200 | Revision Reason must not exceed 200 characters. |
| **CTC outside grade range** | Controller check (DomainException) | "CTC ₹{amount} is outside pay grade range ₹{min} – ₹{max} (BR-HRS-011)." |

## Error Handling and Validation Messages

| Scenario | Message | Type |
|----------|---------|------|
| CTC outside pay grade range | "CTC ₹{amount} is outside pay grade range ₹{min} – ₹{max} (BR-HRS-011)." | DomainException |
| No active assignment for update | "No active salary assignment found." | DomainException |
| Missing permission | HTTP 403 | Gate |

## Success Scenarios

**SC-001 — Salary Assigned to New Employee** — HR assigns structure "Teaching Staff" with CTC ₹3,60,000, grade "Grade B," effective from the joining date. Assignment created with `effective_to_date = null`. Flash: "Salary assigned successfully."

**SC-002 — Salary Updated In-Place** — HR corrects the gross monthly from ₹28,500 to ₹29,000. The active assignment is updated. Flash: "Salary assignment updated successfully."

**SC-003 — Salary Revision Completed** — HR revises Priya's salary from CTC ₹3,60,000 to ₹6,00,000 with reason "Promotion." The old assignment is closed, a new one created, and employment history logged. Flash: "Salary revision recorded successfully."

## Failure Scenarios

**FC-001 — CTC Outside Grade Range** — HR enters CTC ₹8,00,000 for grade "Grade B" (max ₹5,00,000). DomainException: "CTC ₹800000 is outside pay grade range ₹300000 – ₹500000 (BR-HRS-011)."

**FC-002 — Update Without Active Assignment** — HR tries to update an employee who has no active assignment. DomainException: "No active salary assignment found."

## Dependencies module and tables

| Dependency | Type | Details |
|------------|------|---------|
| `sch_employees` | FK parent | `hrs_salary_assignments.employee_id` → `sch_employees.id` (RESTRICT) |
| `pay_salary_structures` | FK parent | `hrs_salary_assignments.pay_salary_structure_id` → `pay_salary_structures.id` (RESTRICT) |
| `hrs_pay_grades` | FK parent | `hrs_salary_assignments.pay_grade_id` → `hrs_pay_grades.id` (RESTRICT) |
| `hrs_salary_assignments` | Self | Children: `pay_payroll_run_details.salary_assignment_id` (RESTRICT) |
| `SalaryAssignmentService` | Service | Orchestrates assign/update/revise with grade validation |
| `EmploymentService` | Service | Logs salary revision history |
| Activity Log | Helper | Logged on create, update, revise |

**Table: `hrs_salary_assignments`**

| Column | Type | Details |
|--------|------|---------|
| id | BIGINT UNSIGNED | PK, Auto-increment |
| employee_id | INT UNSIGNED | NOT NULL, FK → sch_employees.id |
| pay_salary_structure_id | BIGINT UNSIGNED | NOT NULL, FK → pay_salary_structures.id |
| pay_grade_id | BIGINT UNSIGNED | NULL, FK → hrs_pay_grades.id |
| ctc_amount | DECIMAL(12,2) | NOT NULL |
| gross_monthly | DECIMAL(12,2) | NOT NULL |
| effective_from_date | DATE | NOT NULL |
| effective_to_date | DATE | NULL |
| revision_reason | VARCHAR(200) | NULL |
| is_active | TINYINT(1) | NOT NULL, DEFAULT 1 |
| created_by | BIGINT UNSIGNED | NOT NULL |
| updated_by | BIGINT UNSIGNED | NOT NULL |
| created_at | TIMESTAMP | NULL |
| updated_at | TIMESTAMP | NULL |
| deleted_at | TIMESTAMP | NULL |
