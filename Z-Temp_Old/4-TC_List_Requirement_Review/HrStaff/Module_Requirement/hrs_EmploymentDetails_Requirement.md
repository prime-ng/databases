# Employment Details — Business Requirements

## What This Screen Does

The Employment Details screen captures and manages the HR-specific employment information for each staff member. It stores contract type, probation and confirmation dates, notice period, bank account details, emergency contacts, and previous employer history. This is a 1:1 extension of the Employee record — each employee has exactly one employment detail record.

## When This Screen Is Used

- When HR Manager onboards a new employee and needs to record contract terms and bank details
- When HR Manager updates an employee's contract type (e.g., probation to permanent) or confirmation date
- When payroll processing needs bank account information for salary disbursement
- When HR needs emergency contact information for a staff member
- When an employee needs to verify their own employment details on record

## Default Data Load

The screen is loaded by `EmploymentController::show()` under the Employee → HR Details tab. The route `GET /hr-staff/employees/{employee}/hr` displays the employee's existing `EmploymentDetail` record (if any) via `EmploymentDetail::where('employee_id', $employee->id)->first()`. If no record exists, an empty form is presented for creation. No pagination applies — this is a single-record form.

An additional read-only sub-screen is available at `GET /hr-staff/employees/{employee}/history` (`EmploymentController::history()`) showing the employment change audit trail via `EmploymentService::getHistory()`.

## Key Fields at a Glance

**Contract and Employment Terms**
- `contract_type` — The type of employment: permanent, contractual, probation, part_time, or substitute
- `probation_end_date` — Date when probation period ends (relevant for probation contracts)
- `confirmation_date` — Date when the employee was confirmed in their role
- `notice_period_days` — Contractual notice period in days (0–180)

**Bank Account Information**
- `bank_account_number` — Employee's bank account number, encrypted at rest via `SafeEncrypted` cast
- `bank_ifsc` — 11-character IFSC code of the bank branch
- `bank_name` — Name of the bank
- `bank_branch` — Branch name or location

**Emergency Contact**
- `emergency_contact_json` — JSON object containing name, relationship, phone, and address of a person to contact in an emergency

**Previous Employment**
- `previous_employer_json` — JSON array of previous employers, each with company name, role, from_date, and to_date

## Business Rules and Conditions

**One Record Per Employee Rule.** Each employee can have exactly one `hrs_employment_details` record. The database enforces a UNIQUE constraint on `employee_id`. If a record already exists, the create endpoint returns an error: "Employment details already exist for this employee. Use update instead."

**Contract Type Validation.** Only five contract types are allowed: permanent, contractual, probation, part_time, substitute. No free-text entry.

**Probation End Date Constraint.** When creating a new record, the `probation_end_date` must be a date after today (`after:today` rule). On update, this constraint is relaxed to allow any valid nullable date.

**Notice Period Cap.** Notice period is capped at 180 days and must be a non-negative integer.

**Bank Account Encryption.** The bank account number is encrypted at rest using Laravel's `encrypt()` via the `SafeEncrypted` cast. It is never stored in plaintext.

**Read-Only Remarks Field.** The `remarks` field (present on the model) is explicitly unset in `EmploymentService::createOrUpdate()` before save — it is not persisted through this service.

**Audit Trail via Employment History.** Every update to an employment detail that changes one or more tracked fields automatically creates an immutable entry in `hrs_employment_history` recording the old values, new values, change type, and who made the change.

## Workflow Steps

**Creating Employment Details for a New Employee**
1. HR Manager navigates to Employee → HR Details tab
2. System displays the empty employment detail form
3. HR Manager fills in contract type (e.g., "permanent"), probation end date (e.g., "2026-03-15"), notice period (e.g., "30"), bank account details, emergency contact, and previous employer info
4. HR Manager clicks Save
5. System validates all fields, creates the record, logs an activity entry, and displays success message
6. System redirects back to the HR Details tab showing the saved data

**Updating Employment Details**
1. HR Manager opens an employee's HR Details tab (record already exists)
2. System pre-fills the form with existing values
3. HR Manager modifies fields (e.g., changes contract_type from "probation" to "permanent", sets confirmation_date)
4. System validates, compares old and new values, creates a history entry for changed fields
5. System updates the record, logs activity, and displays success message

## Example Scenario

School "Green Valley" hires Ms Sharma as a new teacher on probation. HR Manager opens her profile → HR Details, selects contract_type = "probation", sets probation_end_date = "2026-06-30", notice_period_days = 30, enters her bank account and IFSC, and adds her spouse as emergency contact. After 6 months, HR Manager confirms her by changing contract_type to "permanent", setting confirmation_date = "2026-07-01". The system records the old and new values in employment history for audit.

## Related Screens

- **Employee Profile (SchoolSetup)** — The parent employee record; Employment Details is a 1:1 sub-record accessible from the employee profile
- **Salary Assignment** — Uses the employee ID but does not directly depend on Employment Details

## Requirements

- `EmploymentController` handles all requests with methods: `show()` (lines 26–33), `store()` (lines 38–56), `update()` (lines 61–74), `history()` (lines 79–86)
- `EmploymentService::createOrUpdate()` wraps the create/update logic in a DB transaction and auto-generates history entries on update when fields change; also unsets `remarks` from input data
- `EmploymentService::getHistory()` returns active history records ordered by `effective_date` DESC, `created_at` DESC
- `StoreEmploymentDetailRequest` validates creation with `contract_type required|in:permanent,contractual,probation,part_time,substitute`, `probation_end_date nullable|date|after:today`, `notice_period_days required|integer|min:0|max:180`, bank fields nullable, emergency contact and previous employer as nullable arrays with sub-field rules
- `UpdateEmploymentDetailRequest` validates update with `contract_type sometimes|in:...`, `probation_end_date nullable|date` (no `after:today`), `notice_period_days sometimes|integer|min:0|max:180`
- Route names: `hr-staff.employment.show` (GET), `hr-staff.employment.store` (POST), `hr-staff.employment.update` (PUT), `hr-staff.history.index` (GET)
- Controller checks gate: `Gate::authorize('hrs.employment.manage')` on all methods
- Activity logged on create (type 'Created') and update (type 'Updated') with employee_id in properties
- Policy: `EmploymentPolicy` — defines `viewAny`, `view` (own record or `hrs.employment.manage`), `create`, `update`, `delete`, `restore`, `forceDelete`

## Who Can Access

| Gate/Permission | Methods | Notes |
|-----------------|---------|-------|
| `hrs.employment.manage` | `show()`, `store()`, `update()`, `history()` | Required for all controller methods |
| Own record (employee viewing own) | `view()` in policy | The EmploymentPolicy allows viewing own record even without the manage permission, but the controller gate check overrides this |

## Logic Flow

**Page Load (`show()`).** Route-model-binding loads the `Employee`; controller queries `EmploymentDetail::where('employee_id', $employee->id)->first()` which returns null if no record exists. The view renders either the create form or the edit form with pre-filled data.

**Create (`store()`).** First checks if a record already exists for the employee — if yes, returns error. Otherwise calls `EmploymentService::createOrUpdate()` within a transaction: sets `employee_id`, `created_by`, `updated_by`, creates the model, returns fresh instance. Activity logged. Redirect back to show page.

**Update (`update()`).** Calls `EmploymentService::createOrUpdate()` which finds existing record, compares old vs new values per field, logs changed fields as a history entry (type `employment_detail_update`), then updates with `updated_by`. Activity logged. Redirect back to show page.

**History (`history()`).** Loads all active `EmploymentHistory` records for the employee, newest first. Renders a read-only table showing change type, old values as JSON, new values as JSON, effective date, and who made the change.

## Validate Before Save

| Field | Rule(s) | Error Message |
|-------|---------|---------------|
| `contract_type` | `required` (store) / `sometimes` (update), `in:permanent,contractual,probation,part_time,substitute` | "The selected Contract Type is invalid." |
| `probation_end_date` | `nullable`, `date`, `after:today` (store only) | "The Probation End Date must be a date after today." |
| `confirmation_date` | `nullable`, `date` | "The Confirmation Date is not a valid date." |
| `notice_period_days` | `required` (store) / `sometimes` (update), `integer`, `min:0`, `max:180` | "The Notice Period must be an integer." |
| `bank_account_number` | `nullable`, `string`, `max:30` | "The Bank Account Number must not exceed 30 characters." |
| `bank_ifsc` | `nullable`, `string`, `size:11` | "The Bank IFSC Code must be 11 characters." |
| `bank_name` | `nullable`, `string`, `max:100` | "The Bank Name must not exceed 100 characters." |
| `bank_branch` | `nullable`, `string`, `max:100` | "The Bank Branch must not exceed 100 characters." |
| `emergency_contact_json` | `nullable`, `array` | "The Emergency Contact must be a valid array." |
| `emergency_contact_json.name` | `nullable`, `string`, `max:100` | — |
| `emergency_contact_json.relationship` | `nullable`, `string`, `max:50` | — |
| `emergency_contact_json.phone` | `nullable`, `string`, `max:15` | — |
| `emergency_contact_json.address` | `nullable`, `string`, `max:255` | — |
| `previous_employer_json` | `nullable`, `array` | "The Previous Employer must be a valid array." |
| `previous_employer_json.*.company` | `nullable`, `string`, `max:150` | — |
| `previous_employer_json.*.role` | `nullable`, `string`, `max:100` | — |
| `previous_employer_json.*.from_date` | `nullable`, `date` | — |
| `previous_employer_json.*.to_date` | `nullable`, `date` | — |
| **Duplicate check (controller)** | Checks if record already exists for employee on store | "Employment details already exist for this employee. Use update instead." |

## Error Handling and Validation Messages

| Scenario | Message | Type |
|----------|---------|------|
| Required field missing (`contract_type`) | "The Contract Type field is required." | Validation rule |
| Invalid contract type | "The selected Contract Type is invalid." | Validation rule |
| Probation end date in the past (store) | "The Probation End Date must be a date after today." | Validation rule |
| Duplicate record attempt (create) | "Employment details already exist for this employee. Use update instead." | Controller check |
| Success — created | "Employment details created successfully." | Flash success |
| Success — updated | "Employment details updated successfully." | Flash success |
| Missing permission | "This action is unauthorized." | 403 (Gate) |
| Employee not found | 404 | Route model binding |

## Success Scenarios

**SC-001 — Create Employment Details.** HR Manager fills all required fields for employee ID 5 (contract_type="permanent", notice_period_days=30, bank_account_number="1234567890", bank_ifsc="HDFC0001234"). System creates the `hrs_employment_details` record, logs activity "Employment details created.", and redirects with success message.

**SC-002 — Update Contract Type.** HR Manager changes contract_type from "probation" to "permanent" and sets confirmation_date to "2026-07-01". System detects changed fields, creates an `hrs_employment_history` entry recording the old contract_type as "probation" and new as "permanent", updates the record, logs activity "Employment details updated.", and redirects with success message.

## Failure Scenarios

**FC-001 — Create Duplicate Record.** HR Manager tries to create employment details for an employee who already has a record. System returns an error: "Employment details already exist for this employee. Use update instead."

**FC-002 — Invalid Contract Type.** HR Manager enters contract_type = "intern" which is not in the allowed list. Validation fails with "The selected Contract Type is invalid."

**FC-003 — Probation End Date in Past (Store).** HR Manager sets probation_end_date to a past date during initial creation. Validation fails with "The Probation End Date must be a date after today."

**FC-004 — Missing Permission.** A user without `hrs.employment.manage` attempts to access the HR Details tab. System returns 403 "This action is unauthorized."

## Dependencies module and tables

| Dependency | Type | Details |
|------------|------|---------|
| `Modules\SchoolSetup\Models\Employee` | FK parent | `hrs_employment_details.employee_id` → `sch_employees.id`, ON DELETE RESTRICT |
| `Modules\SchoolSetup\Models\Employee` | FK parent | `hrs_employment_history.changed_by` → `sch_employees.id`, ON DELETE RESTRICT |
| `hrs_employment_history` | Child table | FK from `hrs_employment_history.employee_id` → `sch_employees.id` (also FK from `changed_by`) |
| Activity Log | Service | `activityLog()` called on create and update |
| `EmploymentService` | Service | Contains `createOrUpdate()`, `getHistory()`, `logHistory()`, `generateEmpCode()` |

**Table:** `hrs_employment_details`

| Column | Type | Details |
|--------|------|---------|
| id | BIGINT UNSIGNED | PK, Auto Increment |
| employee_id | INT UNSIGNED | NOT NULL, FK → sch_employees.id, UNIQUE |
| contract_type | ENUM('permanent','contractual','probation','part_time','substitute') | NOT NULL |
| probation_end_date | DATE | NULL DEFAULT NULL |
| confirmation_date | DATE | NULL DEFAULT NULL |
| notice_period_days | TINYINT UNSIGNED | NOT NULL DEFAULT 30 |
| bank_account_number | TEXT | NULL DEFAULT NULL (encrypted via SafeEncrypted cast) |
| bank_ifsc | VARCHAR(11) | NULL DEFAULT NULL |
| bank_name | VARCHAR(100) | NULL DEFAULT NULL |
| bank_branch | VARCHAR(100) | NULL DEFAULT NULL |
| emergency_contact_json | JSON | NULL DEFAULT NULL |
| previous_employer_json | JSON | NULL DEFAULT NULL |
| is_active | TINYINT(1) | NOT NULL DEFAULT 1 |
| created_by | BIGINT UNSIGNED | NOT NULL |
| updated_by | BIGINT UNSIGNED | NOT NULL |
| created_at | TIMESTAMP | NULL |
| updated_at | TIMESTAMP | NULL |
| deleted_at | TIMESTAMP | NULL |

**Table:** `hrs_employment_history`

| Column | Type | Details |
|--------|------|---------|
| id | BIGINT UNSIGNED | PK, Auto Increment |
| employee_id | INT UNSIGNED | NOT NULL, FK → sch_employees.id |
| change_type | VARCHAR(50) | NOT NULL (e.g., `employment_detail_update`) |
| old_value | JSON | NOT NULL |
| new_value | JSON | NOT NULL |
| effective_date | DATE | NOT NULL |
| changed_by | INT UNSIGNED | NOT NULL, FK → sch_employees.id |
| remarks | TEXT | NULL DEFAULT NULL |
| is_active | TINYINT(1) | NOT NULL DEFAULT 1 |
| created_by | BIGINT UNSIGNED | NOT NULL |
| updated_by | BIGINT UNSIGNED | NOT NULL |
| created_at | TIMESTAMP | NULL |
| updated_at | TIMESTAMP | NULL |
| deleted_at | TIMESTAMP | NULL |
