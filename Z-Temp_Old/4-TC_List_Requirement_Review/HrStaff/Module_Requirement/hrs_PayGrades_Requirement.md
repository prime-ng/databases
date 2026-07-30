# Pay Grades — Business Requirements

## What This Screen Does

The Pay Grades screen allows the school to define salary grade bands that serve as validation boundaries for employee compensation. Each pay grade specifies a minimum and maximum CTC range, along with optional designation restrictions. When assigning a salary to an employee, the system uses these grades to ensure the offered CTC falls within the appropriate band.

---

## When This Screen Is Used

- Salary Structure Design when the school administration defines compensation bands for different role categories
- Employee Onboarding when assigning a salary to a new employee within a predefined grade
- Salary Revision during annual increments to ensure the revised CTC stays within the applicable grade band
- Designation Mapping when restricting certain grades to specific job designations

## Default Data Load

The screen is loaded via `HrMenuController@hrMasters()` at route `GET /hr-masters` with tab parameter `tab=pay-grades`. The controller loads pay grades from `PayGrade::orderBy('grade_name')`, filtered by search when the active tab is `pay-grades`.

Separately, `PayGradeController@index()` at `GET /pay-grades` provides a standalone paginated view with 20 records per page, searchable by `grade_name`.

---

## Key Fields at a Glance

**Grade Identity**
The Grade Name is a human-readable label such as "Grade A" or "Senior Teacher". It uniquely identifies the pay band in dropdown selections during salary assignment.

**CTC Range**
The Minimum CTC and Maximum CTC define the lower and upper annual compensation limits for this grade. The system enforces that the maximum must be greater than the minimum.

**Designation Restriction**
The Applicable Designations field stores an array of designation IDs from the school setup module. When populated, the grade is only available for employees holding those specific designations. When null, the grade applies to all designations.

---

## Business Rules and Conditions

**Maximum Greater Than Minimum**
The system enforces that Max CTC must be strictly greater than Min CTC via the `gt:min_ctc` validation rule.

**Designation IDs Validation**
When provided, each ID in the applicable designation IDs array must reference an existing record in the `sch_designation` table with `is_active = true`.

**Salary Assignment Guard**
A pay grade cannot be deleted if there are existing salary assignments referencing it. The controller checks `salaryAssignments()->exists()` before proceeding with deletion.

---

## Workflow Steps

**Creating a Pay Grade**
The HR Manager navigates to HR Masters → Pay Grades, clicks Add, enters the grade name (e.g., "Senior Teacher"), sets minimum CTC (₹300,000) and maximum CTC (₹600,000), optionally selects applicable designations, and saves.

**Editing a Pay Grade**
The HR Manager edits a grade to adjust its CTC range or add/remove designation restrictions. The system updates the record and logs the change.

---

## Example Scenario

A school defines three pay grades: Support Staff (₹120,000–₹240,000), Teaching Staff (₹240,000–₹600,000 designated for Teacher and Senior Teacher roles), and Leadership (₹600,000–₹1,200,000 designated for Principal and Vice Principal). When onboarding a new Senior Teacher, the HR Manager selects the Teaching Staff grade and enters a CTC of ₹450,000, which falls within the band.

---

## Related Screens

- **Salary Structures** — Pay grades are used as validation boundaries during structure assignment
- **Salary Assignment** — The grade is linked to an employee's salary record
- **Designations (SchoolSetup)** — Provides the designation reference data

---

## Requirements

- Controller `PayGradeController`: `index()` loads paginated grid; `store()` creates with validated + `created_by`/`updated_by`; `show()` loads with designation names resolved; `edit()` loads with active designations; `update()` updates with validated + `updated_by`; `toggleStatus()` flips `is_active` via JSON; `destroy()` guards on `salaryAssignments()->exists()`, sets `is_active=false` before soft-delete; `trashed()` lists soft-deleted; `restore()` restores and sets `is_active=true`; `forceDelete()` permanently deletes
- Gate: `Gate::authorize('hrs.salary.manage')` on all methods
- Route resource: `pay-grades` with `except(['create'])`, plus custom `toggle-status`, `trashed`, `restore`, `force-delete`
- Validation `StorePayGradeRequest`: `grade_name` required, max:100; `min_ctc` required, numeric, min:0; `max_ctc` required, numeric, gt:min_ctc; `applicable_designation_ids` nullable, array; `applicable_designation_ids.*` integer, exists:sch_designation,id; `is_active` required, boolean
- `prepareForValidation()`: casts `is_active` to boolean (default true)
- Model `PayGrade`: SoftDeletes, table `hrs_pay_grades`, `$fillable` = 7 fields, `$casts` = `min_ctc` decimal:2, `max_ctc` decimal:2, `applicable_designation_ids` array (JSON), `is_active` boolean; relationships: `salaryAssignments()` HasMany; scopes: `active()`
- `show()` resolves designation IDs via `Designation::whereIn('id', ...)->pluck('name')` for display
- Delete guard: `salaryAssignments()->exists()` → back with error "Cannot delete pay grade with existing salary assignments."
- Activity logged via `activityLog()` on all state-changing operations
- Policy: `PayGradePolicy` using `hrs.pay_grade.manage` for all gates

## Who Can Access

| Gate/Permission | Methods | Notes |
|----------------|---------|-------|
| `hrs.salary.manage` | All PayGradeController methods | Controller-level gate |
| `hrs.pay_grade.manage` | Policy gates | Policy-level permission |
| Policy: `PayGradePolicy` | All gates | Uses `hrs.pay_grade.manage` |

## Logic Flow

1. **Page Load** — `HrMenuController@hrMasters()` loads tabbed view; `PayGradeController@index()` paginated. Gate enforced. Search by grade name.
2. **Create** — `store()` validates via `StorePayGradeRequest`. `applicable_designation_ids` stored as JSON. Redirect to tab.
3. **Edit/Update** — `edit()` loads active designations for multi-select. `update()` merges `updated_by`.
4. **Show** — `show()` resolves the designation IDs array into human-readable names via `Designation::pluck()`.
5. **Status Toggle** — AJAX flip of `is_active`.
6. **Delete** — Guards against existing `salaryAssignments()`.

## Validate Before Save

| Field | Rule(s) | Error Message |
|-------|---------|---------------|
| `grade_name` | required, string, max:100 | — |
| `min_ctc` | required, numeric, min:0 | — |
| `max_ctc` | required, numeric, gt:min_ctc | — |
| `applicable_designation_ids` | nullable, array | — |
| `applicable_designation_ids.*` | integer, exists:sch_designation,id | — |
| `is_active` | required, boolean | — |

## Error Handling and Validation Messages

| Scenario | Message | Type |
|----------|---------|------|
| Max CTC not greater than Min CTC | "The max ctc field must be greater than min ctc." | Validation (gt) |
| Invalid designation ID | "The selected applicable designation ids.* is invalid." | Validation (exists) |
| Delete with salary assignments | "Cannot delete pay grade with existing salary assignments." | Controller check |

## Success Scenarios

**SC-001 — Creating a Pay Grade**
HR Manager creates "Teaching Staff" with min CTC 240000 and max CTC 600000. System creates record, logs Created activity, redirects with success.

**SC-002 — Editing CTC Range**
HR Manager expands the range of a grade. System updates and logs Updated.

**SC-003 — Toggling Pay Grade Inactive**
HR Manager disables a grade via AJAX toggle. JSON success response.

## Failure Scenarios

**FC-001 — Max CTC Less Than Min CTC**
User enters max CTC lower than min CTC. Validation error on `max_ctc`.

**FC-002 — Delete Blocked by Salary Assignments**
HR Manager tries to delete a grade that is referenced by salary assignments. Error: "Cannot delete pay grade with existing salary assignments."

## Dependencies module and tables

| Dependency | Type | Details |
|-----------|------|---------|
| `sch_designation` | FK Table | `applicable_designation_ids.*` references `sch_designation.id` |
| `hrs_salary_assignments` | Child Table | `pay_grade_id` FK → blocks delete if exists |
| Activity Log | Consumer | `activityLog()` on CRUD |

**Table:** `hrs_pay_grades`

| Column | Type | Details |
|--------|------|---------|
| id | BIGINT UNSIGNED PK | Auto-increment |
| grade_name | VARCHAR(100) | NOT NULL |
| min_ctc | DECIMAL(12,2) | NOT NULL |
| max_ctc | DECIMAL(12,2) | NOT NULL |
| applicable_designation_ids | JSON | NULL DEFAULT NULL |
| is_active | TINYINT(1) | NOT NULL DEFAULT 1 |
| created_by | BIGINT UNSIGNED | NOT NULL |
| updated_by | BIGINT UNSIGNED | NOT NULL |
| created_at | TIMESTAMP | NULL |
| updated_at | TIMESTAMP | NULL |
| deleted_at | TIMESTAMP | NULL (soft delete) |
