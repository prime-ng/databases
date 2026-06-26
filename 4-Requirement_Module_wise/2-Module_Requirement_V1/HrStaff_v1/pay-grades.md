# Pay Grades — Requirements

## What It Does
Defines salary grade bands with minimum and maximum CTC ranges. Each pay grade can be linked to multiple designations. Used during salary assignment to ensure employee CTC falls within the appropriate grade band. Enables structured compensation planning.

Features:
- CTC range (min/max) per grade
- Multi-designation applicability (JSON array of designation IDs)
- Pay grade reference on salary assignments
- Soft-delete with full restore/force-delete workflow

## Database Fields

**hrs_pay_grades**

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `grade_name` | VARCHAR(100) | Required. E.g., `Grade I`, `Grade II`, `Senior`, `Lead`. |
| `min_ctc` | DECIMAL(12,2) | Required. Minimum CTC for this grade. Cast to 2 decimals. |
| `max_ctc` | DECIMAL(12,2) | Required. Maximum CTC for this grade. Must be > min_ctc. Cast to 2 decimals. |
| `applicable_designation_ids` | JSON | Array of `sch_designation` IDs. Cast to array. Which designations this grade applies to. |
| `is_active` | BOOLEAN | Default true. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard timestamps. |

## Business Rules

**Range Validation**
- `max_ctc` must be strictly greater than `min_ctc`
- Both are stored as DECIMAL(12,2) — supports values up to 99,99,99,999.99
- During salary assignment, the employee's CTC must fall within the assigned pay grade range

**Designation Applicability**
- `applicable_designation_ids` stores an array of designation IDs
- When assigning a pay grade to an employee, the employee's designation must be in the grade's applicable list
- If empty array, the grade applies to all designations
- Used for dropdown filtering on the salary assignment form

**Grade Overlap**
- Grade ranges can overlap (Grade I: 3-5 LPA, Grade II: 4-7 LPA)
- No automatic exclusivity — HR admin should ensure non-overlapping ranges for clarity
- System does not prevent overlapping ranges

## CRUD Operations

**List Pay Grades**
- Table view with grade name, min CTC, max CTC, designation count
- Active/Inactive badge

**Create Pay Grade**
- Designation multi-select dropdown

**Show / Edit / Update**
- Min CTC / Max CTC editable with range validation

**Toggle Active Status**
- Inactive grades are hidden from assignment dropdowns

**Soft Delete / Restore / Force Delete**

## Permissions

| Operation | Permission Key |
|---|---|
| View / Manage pay grades | `hrs.pay_grade.manage` |
| Create / Edit / Delete | `hrs.pay_grade.manage` |
| Toggle status / Restore / Force delete | `hrs.pay_grade.manage` |
