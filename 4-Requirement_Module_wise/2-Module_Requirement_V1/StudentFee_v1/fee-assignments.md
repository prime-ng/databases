# Student Fee Assignments — Requirements

## What It Does
Assigns a fee structure to a specific student for an academic session. Tracks opted heads/groups (for optional items), mid-year join with proration, and links to invoices and concessions. Supports bulk generation for all students in a class and individual assignment management.

Features:
- Per-student fee structure assignment
- Optional head/group selection (opt-in/opt-out)
- Mid-year join proration
- Bulk generation: one-click assignments for entire class
- AJAX class→sections dropdown chaining
- Soft-delete with full restore

## Database Fields

**fee_student_assignments**

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `student_id` | BIGINT UNSIGNED FK → `std_students` | Required. |
| `class_id` | BIGINT UNSIGNED FK → `sch_classes` | Required. |
| `section_id` | BIGINT UNSIGNED FK → `sch_sections` | Required. |
| `academic_session_id` | BIGINT UNSIGNED FK → `glb_academic_sessions` | Required. |
| `fee_structure_id` | BIGINT UNSIGNED FK → `fee_structure_masters` | Required. |
| `total_fee_amount` | DECIMAL(12,2) | Required. Copied from structure (or adjusted for proration). |
| `opted_heads` | JSON | Array of opted head IDs when structure has optional heads. Cast to array. |
| `opted_groups` | JSON | Array of opted group IDs when structure has optional groups. Cast to array. |
| `assignment_date` | DATE | Required. Date of assignment. |
| `join_in_mid-year` | BOOLEAN | Default false. Whether student joined mid-year. |
| `fee_start_date` | DATE | Nullable. Fee start date (for mid-year join proration). |
| `proration_percentage` | DECIMAL(5,2) | Nullable. Prorated fee percentage for mid-year join. |
| `is_active` | BOOLEAN | Default true. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard timestamps. |

## Business Rules

**Duplicate Prevention**
- Only one active assignment per `student_id + academic_session_id`
- Creating a new assignment for a student who already has one for the same session is blocked

**Bulk Generation**
- `generateStudentAssignment()` creates assignments for ALL active students whose class + session matches a fee structure
- Process:
  1. Find all fee structures for the current session
  2. Find all students with active student sessions matching those classes
  3. For each student without an existing assignment: create one with the matching structure
- Idempotent: skips students who already have an assignment for the session

**Optional Heads/Groups**
- When a fee structure has optional heads or groups, the student (or admin) selects which to include
- `opted_heads`: JSON array of selected optional head IDs
- `opted_groups`: JSON array of selected optional group IDs
- Only optional items (marked `is_optional = true`) can be opted in/out
- Mandatory items are always included and their amount is always part of `total_fee_amount`

**Mid-Year Join Proration**
- `join_in_mid-year = true`: Student joined after the session started
- `proration_percentage` = `(remaining_months / total_months) × 100`
- `total_fee_amount` is recomputed: `structure_total × (proration_percentage / 100)`
- `fee_start_date` = the month from which fee applies

**Class/Section AJAX**
- When creating assignment: select class → AJAX loads sections → select section
- `getSectionsByClass(int $classId)` returns JSON of sections for that class

**Structure Update on Assignment**
- `updateAssignmentStructure(Request, $id)`: updates `fee_structure_id` and recalculates `total_fee_amount`
- Used when student changes class or structure changes mid-year

## CRUD Operations

**List Assignments**
- Search by: admission_no, student name
- Filter by: status (active/inactive)
- Shows: student, class, section, structure, total fee, assignment date

**Create Assignment (Individual)**
- Select: student, class (→ AJAX loads sections), section, fee structure
- Optional heads/groups shown as checkboxes
- Mid-year join toggle shows fee_start_date and proration fields

**Bulk Generate Assignments**
- One-click: generates assignments for all students without existing ones
- Progress indicator

**Show / Edit / Update / Destroy**
- Edit: can change structure, update opted heads/groups
- Destroy: deactivates + soft deletes

**Toggle Active Status / Soft Delete / Restore / Force Delete**

## Permissions

| Operation | Permission Key |
|---|---|
| View assignments | `tenant.fee-student-assignment.viewAny` |
| Create / Update / Delete | `tenant.fee-student-assignment.*` |
