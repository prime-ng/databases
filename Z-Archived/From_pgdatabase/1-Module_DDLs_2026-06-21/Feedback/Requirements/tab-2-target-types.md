# Feedback Tab 2: Target Types

This is a master-data management screen where school administrators define what kinds of entities can be rated in the feedback system. Examples include Teacher, Student, Transport Driver, Canteen Staff, Library Staff, Hostel Warden, Security Staff, Sports Coach, and Department.

---

## How It Works

The screen shows a table listing all target types currently configured in the system. Each row displays the target code, name, description, icon, display order, linked entity table, and whether it is an individual or aggregate target. Administrators can add new target types, edit existing ones, reorder them, or deactivate types that are no longer needed.

When adding or editing a target type, the administrator selects a linked entity table from a dropdown. This tells the system which database table holds the actual records for that target kind. For example, Teacher links to sys_users, Student links to std_students, and Department links to sch_departments. The is-individual flag indicates whether each target points to a specific person (Teacher, Student) or an aggregate entity (Department, Class).

The display order determines the sequence in which target types appear in dropdowns throughout the feedback module.

---

## Important Business Rules

- Target types cannot be deleted if they are referenced by any existing relationship type, template, cycle target, or response. Attempting to delete will show a validation error.
- To remove a target type that is in use, it must be deactivated (is_active = 0) rather than deleted. This preserves referential integrity.
- The code field must be unique across all target types (including soft-deleted ones, to prevent reuse of a previously used code).
- The linked entity table dropdown is populated from sys_dropdown_table where the key is fbk_target_types.linked_entity_table. New entries can be added here by support staff if a new entity type needs to be ratable.
- At least one target type must always be active for the feedback module to function. The system warns when deactivating the last active target type.
- Display order values can have gaps; the system sorts by this column ascending when showing dropdown options.

---

## Database Columns & Behavior

### fbk_target_types
- `id` — Primary key. SMALLINT UNSIGNED, auto-increment.
- `code` — Unique short identifier like TEACHER, STUDENT, TRANSPORT_DRIVER. VARCHAR(40). Unique with soft-delete.
- `name` — Human-readable name. VARCHAR(100).
- `description` — Optional explanation of what this target type represents. VARCHAR(255).
- `icon` — Font Awesome icon class for UI display. VARCHAR(50).
- `display_order` — Determines sort sequence in dropdowns. SMALLINT UNSIGNED, default 1.
- `linked_entity_table_id` — FK to sys_dropdown_table.id. Tells the application which base table holds target records (key: fbk_target_types.linked_entity_table). INT UNSIGNED.
- `is_individual` — 1 = points to a specific person/record, 0 = aggregate entity like DEPARTMENT. TINYINT(1), default 1.
- `is_active` — Soft delete flag. 1 = active, 0 = deactivated. TINYINT(1), default 1.
- `created_at` / `updated_at` / `deleted_at` — Standard timestamps.

---

## Deep Analysis

### Business Workflows & State Machines

Master-data CRUD with soft-delete. No state machine — records are either active (is_active=1) or deactivated (is_active=0). Workflow: Admin creates a target type → it becomes active immediately → Admin can edit any field (except code if responses already exist) → Admin can deactivate (soft-delete) → Admin can reactivate. No lifecycle versioning — edits overwrite the existing record.

### Validation Rules & Edge Cases

- **Unique code**: UNIQUE KEY (`code`, `deleted_at`) enforces uniqueness across active and soft-deleted records — a code cannot be reused even after deletion.
- **Referential integrity**: DELETE is blocked if any row in fbk_relationship_types.target_type_id, fbk_templates.target_type_id, fbk_cycle_targets.target_type_id, or fbk_responses.target_type_id references this id. The UI must check before allowing delete.
- **Last active guard**: System must warn (or block) when deactivating the last is_active=1 target type. The module cannot function with zero active types.
- **linked_entity_table_id** must resolve to a valid sys_dropdown_table row with key = 'fbk_target_types.linked_entity_table'. The application should validate this FK at save time.
- **is_individual flag**: When false (aggregate), the target_user_id / target_student_id / target_employee_id columns in fbk_responses and fbk_cycle_targets must be null; only target_department_id is populated. This should be enforced by the application.
- **display_order**: Values may have gaps. Sorting is ascending. Two records may have the same value — tiebreak by name or id.

### Integration Points

- **sys_dropdown_table** via linked_entity_table_id for the entity table dropdown (key: fbk_target_types.linked_entity_table).
- **fbk_relationship_types** via target_type_id — a target type cannot be deleted if any relationship type references it.
- **fbk_templates** via target_type_id — each template is scoped to a target type.
- **fbk_cycle_targets** via target_type_id — denormalised target type on each cycle target.
- **fbk_responses** via target_type_id — denormalised target type on each response.
- **fbk_summary** via target_type_id — denormalised target type on each summary row.

### Permissions Matrix

| Action | Admin | Principal | Teacher | Student | Parent | Staff |
|---|---|---|---|---|---|---|
| View list | Yes | Yes | Yes | No | No | No |
| Create new | Yes | No | No | No | No | No |
| Edit existing | Yes | No | No | No | No | No |
| Deactivate | Yes | No | No | No | No | No |
| Reorder | Yes | No | No | No | No | No |
| Delete (if unused) | Yes | No | No | No | No | No |
