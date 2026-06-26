# Salary Assignments — Requirements

## What It Does
Assigns a salary structure and pay grade to an employee with a specific CTC amount. Computes gross monthly from CTC. Tracks assignment history via effective date ranges — end-dating old assignments when new ones are created. Supports salary revisions with reason logging.

Features:
- CTC → gross monthly computation (annual CTC ÷ 12)
- Effective date range tracking (from → to)
- Auto end-dating previous assignment on revision
- Pay grade and salary structure linkage
- Revision reason tracking
- Soft-delete with restore

## Database Fields

**hrs_salary_assignments**

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `employee_id` | BIGINT UNSIGNED FK → `sch_employees` | Required. CASCADE on delete. |
| `pay_salary_structure_id` | BIGINT UNSIGNED FK → `pay_salary_structures` | Required. |
| `pay_grade_id` | BIGINT UNSIGNED FK → `hrs_pay_grades` | Nullable. |
| `ctc_amount` | DECIMAL(12,2) | Required. Annual CTC. Cast to 2 decimals. |
| `gross_monthly` | DECIMAL(10,2) | Required. Computed: `ctc_amount / 12`. Cast to 2 decimals. |
| `effective_from_date` | DATE | Required. When this assignment takes effect. |
| `effective_to_date` | DATE | Nullable. When this assignment ends. Null = current/active. |
| `revision_reason` | VARCHAR(200) | Nullable. Why the salary was revised. |
| `is_active` | BOOLEAN | Default true. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard timestamps. |

## Business Rules

**CTC → Gross Monthly**
- `gross_monthly = ctc_amount / 12`
- Both stored explicitly in DB (not computed at runtime)
- When CTC is updated, gross_monthly is recomputed

**Effective Dating**
- `effective_from_date`: When the salary assignment starts
- `effective_to_date`: Null when current/active, set to the day before the new assignment starts
- Only one assignment per employee can have `effective_to_date = NULL` (current)

**Salary Revision Flow**
1. HR selects employee and views current assignment
2. HR clicks "Revise Salary" — enters new CTC, structure (optional), reason
3. System end-dates the current assignment: `effective_to_date = new_from_date - 1 day`
4. System creates new assignment with `effective_from_date = new_from_date`, `effective_to_date = NULL`
5. New assignment linked to same or different salary structure

**Pay Grade Validation**
- If `pay_grade_id` is set: `ctc_amount` must be between `pay_grade.min_ctc` and `pay_grade.max_ctc`
- Validation is a warning, not a hard block (configurable)
- Employee's designation must match the pay grade's `applicable_designation_ids`

**CTC History**
- All historical assignments are preserved with `effective_to_date` populated
- Used by reports to show salary trends over time

## CRUD Operations

**Show Current Salary**
- Displays current assignment: structure, grade, CTC, gross monthly
- Shows assignment history timeline below
- "Revise Salary" button

**Create / Update Salary Assignment**
- Structure dropdown filtered by employee category applicability
- Pay grade dropdown filtered by employee designation
- On create: sets as current (effective_to_date = null)
- On update: only allowed if no payroll run exists for the period

**Salary Revision**
- End-dates current assignment, creates new one
- Revision reason required

## Permissions

| Operation | Permission Key |
|---|---|
| View salary assignments | `hrs.salary.manage` |
| Create / Update / Revise salary | `hrs.salary.manage` |
