# Teacher Assignment Roles — Business Requirements

## What This Screen Does

The Teacher Assignment Roles screen is a **simple CRUD master data screen** that defines the canonical set of roles a teacher can hold when assigned to an activity or timetable cell. Roles are purely categorical labels — they describe *how* a teacher participates (Primary Instructor, Assistant, Co-Teacher, Substitute, Observer, Trainee) rather than *who* the teacher is. The actual teacher-to-subject/class link lives in `tt_teacher_availabilities` and `tt_activity_teachers`.

Each role carries behavioural flags consumed by the timetable solver:

- **`is_primary_instructor`** — Whether this role represents the lead teacher (forces `allows_overlap = false`).
- **`counts_for_workload`** — Whether periods assigned under this role contribute to workload calculations.
- **`allows_overlap`** — Whether the teacher may be assigned to overlapping time slots (e.g., Assistant observing multiple classes).
- **`workload_factor`** — A decimal multiplier applied to the period count when calculating workload (e.g., Assistant = 0.50).
- **`is_system`** — Marks roles seeded by the system as protected; system roles cannot be edited, deleted, or have their status toggled by users.

The screen appears under **Timetable Configuration → Timetable Masters** tab group, specifically the **Teacher Roles** tab (`tab=teacher-roles`). Because this is a reference-data table with a `tinyIncrements` primary key (max 255 rows), the DDL intentionally constrains row count — the seeder creates exactly 5 system roles, and user-created custom roles should be kept minimal.

## When This Screen Is Used

- **Initial system setup** — During the Timetable Foundation seeding process (`TtTeacherAssignmentRoleSeeder`), the five canonical roles (PRIMARY, ASSISTANT, CO_TEACHER, OBSERVER, SUBSTITUTE) are created as system-protected records. Administrators inspect these after seeding.
- **Adding custom roles** — If a school uses specialised roles (e.g., "Trainee Teacher", "Mentor", "Lab Assistant") that do not match the five seed roles, an administrator creates a new role with the appropriate behavioural flags.
- **Modifying non-system roles** — Custom roles may have their name, description, workload factor, or ordinal adjusted as school policies change.
- **Deactivating obsolete roles** — When a role is no longer in use (e.g., a pilot programme ends), the administrator deactivates or soft-deletes it. System roles cannot be deactivated through the UI.
- **Solver configuration** — The `SmartTimetable` generation service queries `tt_teacher_assignment_roles` to identify primary instructors (`is_primary_instructor = true`) for constraint enforcement.

## Default Data Load

The `TeacherAssignmentRoleController@index` method authorises the user and immediately redirects to the Timetable Masters page with `tab=teacher-roles`. The actual data load occurs in `TimetableFoundationController@timetableMasters`, which queries:

```php
$teacherRoles = TeacherAssignmentRole::query()
    ->select('tt_teacher_assignment_roles.*')
    ->leftJoin(...) // counts related activity_teachers
    ->whereColumn('assignment_role_id', 'tt_teacher_assignment_roles.id')
    ->withCount('activityTeachers')
    ->orderBy('ordinal')
    ->get();
```

The result set is **not paginated** (this is master data, typically 5–15 rows). It includes:

| Filter | Input name | Default |
|--------|------------|---------|
| Search (name/code) | `role_search` | None (all) |
| Status (is_active) | `role_status` | `1` (active only) |

Columns rendered in the table: **# (ordinal)**, **Code**, **Name**, **Description**, **Primary Instructor**, **Counts for Workload**, **Allows Overlap**, **Workload Factor**, **Status** (toggle), **Action** (View, Edit, Trash).

## Key Fields at a Glance

**Identity Fields**

- **Code** — A unique uppercase code using only `[A-Z0-9_]` (e.g., `PRIMARY`, `ASSISTANT`, `CO_TEACHER`). Max 30 characters. Used as a stable reference in seeders and solver logic.
- **Name** — Human-readable display name (e.g., "Primary Instructor", "Assistant Teacher"). Max 100 characters.
- **Description** — Optional free-text explanation of the role's purpose. Max 255 characters.

**Behavioural Flags**

- **Is Primary Instructor** (`is_primary_instructor`) — Boolean, default `false`. When true, the system **forces `allows_overlap = false`** — a primary instructor cannot be double-booked. The solver uses this flag to identify lead teachers for hard-constraint enforcement.
- **Counts for Workload** (`counts_for_workload`) — Boolean, default `true`. When false, periods assigned under this role contribute zero to workload calculations, and `workload_factor` is **forced to `0`**.
- **Allows Overlap** (`allows_overlap`) — Boolean, default `false`. When true, the teacher may be assigned to this role simultaneously with another role in a different class (e.g., Observer monitoring two nearby rooms).
- **Workload Factor** (`workload_factor`) — Decimal(5,2), default `1.00`, range `0` to `9.99`. Multiplier applied to each assigned period: `workload_contribution = periods × workload_factor`. An Assistant at 0.50 contributes half the workload of a Primary Instructor.

**Ordering and Protection**

- **Ordinal** — Unsigned tiny integer, default `1`. Controls sort order in list views (ascending). Seeded ordinals: PRIMARY=1, ASSISTANT=2, CO_TEACHER=3, OBSERVER=4, SUBSTITUTE=5.
- **Is System** (`is_system`) — Boolean, default `true`. System roles are **protected** — the controller rejects updates, deletes, status toggles, and force-deletes on any role where `is_system = true`. This flag is intended for seed-data only.
- **Is Active** (`is_active`) — Boolean, default `true`. Soft toggle. Inactive roles are hidden from selection dropdowns and the solver ignores them.

**Timestamps**
- `created_at` / `updated_at` — Standard Laravel timestamps.
- `deleted_at` — Nullable; populated by `SoftDeletes` trait on soft delete.

## Business Rules and Conditions

**BR-001 — Code Uniqueness (System-Wide)**
The `code` column has a unique index (`uq_tarole_code`). No two roles, even after soft-deletion, may share the same code. The validation rule `Rule::unique('tt_teacher_assignment_roles', 'code')` enforces this at the application layer (with `->ignore($id)` on update).

**BR-002 — Code Format Constraint**
The `code` field is validated with `regex:/^[A-Z0-9_]+$/`. Only uppercase letters, digits, and underscores are permitted. Lowercase or special characters are rejected.

**BR-003 — Non-Workload Roles Force Factor to Zero**
If `counts_for_workload` is `false`, the controller **overrides** the user-supplied `workload_factor` to `0` regardless of what was entered. This ensures workload calculations are never accidentally inflated for non-workload roles.

**BR-004 — Primary Instructor Cannot Overlap**
If `is_primary_instructor` is `true`, the controller **forces** `allows_overlap = false`. Primary instructors must always have exclusive, non-overlapping assignments.

**BR-005 — System Roles Are Immutable**
Any role with `is_system = true` is protected against:

| Action | Behaviour |
|--------|-----------|
| Update | Redirect back with `system_record_update_not_allowed` error |
| Delete (soft) | Redirect back with `system_record_delete_not_allowed` error |
| Toggle Status | JSON `403` response with `system_record_status_change_not_allowed` |
| Force Delete | Redirect back with `system_record_force_delete_not_allowed` error |

The five seeded roles (PRIMARY, ASSISTANT, CO_TEACHER, OBSERVER, SUBSTITUTE) all have `is_system = true`.

**BR-006 — Deactivation Cascade on Delete**
When a role is soft-deleted via `destroy()`, the controller **first** sets `is_active = false`, **then** calls `$role->delete()`. This ensures the role is immediately excluded from active queries even though the SoftDeletes trait normally hides it only from non-trashed queries.

**BR-007 — Reactivation on Restore**
When a trashed role is restored via `restore()`, the controller automatically sets `is_active = true`. The role becomes immediately available for use.

**BR-008 — Ordinal Uniqueness (Not Enforced)**
The DDL has no unique constraint on `ordinal`. Multiple roles may share the same ordinal, which causes non-deterministic ordering in list views. This is a **known gap** — a future requirement should add unique-ordinal validation or at least warn on duplicate ordinal values.

**BR-009 — Activity Logging on All Mutations**
Every state-changing operation (create, update, destroy, restore, forceDelete, toggleStatus) invokes the `activityLog()` helper to record an audit trail.

## Workflow Steps

**Creating a New Role**

1. User navigates to **Timetable Foundation → Timetable Masters → Teacher Roles** tab.
2. Clicks **"Add New"** → `TeacherAssignmentRoleController@create`.
3. `Gate::authorize('timetable-foundation.teacher-assignment-role.create')` — 403 if unauthorised.
4. Form rendered: Code (`text`, required, uppercase regex), Name (`text`, required), Description (`textarea`, optional), Is Primary (`checkbox`), Counts for Workload (`checkbox`, default checked), Allows Overlap (`checkbox`), Workload Factor (`number`, 0–9.99), Ordinal (`number`, min 1).
5. On submit → `POST /teacher-assignment-role` → `store()`.
6. Validation runs → if fails, redirect back with errors.
7. Business rules applied: if `counts_for_workload = false` → factor = 0; if `is_primary_instructor = true` → overlap = false.
8. `TeacherAssignmentRole::create($validated)` → new row inserted.
9. Activity log entry created.
10. Redirect to `timetable-foundation.menu.timetableMasters?tab=teacher-roles` with success flash.

**Editing an Existing Role**

1. User clicks **Edit** on a role row → `TeacherAssignmentRoleController@edit($id)`.
2. `Gate::authorize('timetable-foundation.teacher-assignment-role.update')`.
3. If `$role->is_system`: redirect back with error (system role update not allowed).
4. Form pre-filled with existing values.
5. On submit → `PUT /teacher-assignment-role/{id}` → `update()`.
6. Same validation + business rules as create.
7. `$teacherAssignmentRole->update($validated)` → row updated.
8. Redirect with success flash.

**Soft-Deleting a Role**

1. User clicks **Trash** → `destroy($id)`.
2. `Gate::authorize('timetable-foundation.teacher-assignment-role.delete')`.
3. If `is_system` → redirect with error.
4. `is_active = false` → `save()` → `delete()` (SoftDeletes).
5. Activity log: "Teacher assignment role was deactivated and moved to trash."
6. Redirect with success flash.

**Restoring a Trashed Role**

1. Navigate to **Trash** view → `trashedTeacherAssignmentRole()` lists only-trashed records.
2. Click **Restore** → `restore($id)`.
3. `Gate::authorize('timetable-foundation.teacher-assignment-role.restore')`.
4. `$role->restore()` → `is_active = true` → `save()`.
5. Redirect to trash view with success flash.

**Toggling Status**

1. User toggles the switch in the list table → `POST /teacher-assignment-role/{id}/toggle-status` → `toggleStatus()`.
2. Validates `is_active` boolean.
3. If `is_system` → JSON 403 error.
4. Saves new status.
5. Returns JSON `{ success: true, is_active, message }`.

## Example Scenario

Ms. Sharma, the Timetable Manager at Sunshine Academy, is setting up the system for the new academic year:

1. She navigates to **Timetable Masters → Teacher Roles tab** and sees the five pre-seeded roles: Primary Instructor (ordinal 1), Assistant Teacher (ordinal 2), Co-Teacher (ordinal 3), Observer (ordinal 4), Substitute Teacher (ordinal 5). All are system-protected and cannot be edited or deleted.

2. The school runs a "Trainee Teacher" programme where final-year B.Ed. students observe and co-teach. Ms. Sharma clicks **Add New** and creates:
   - Code: `TRAINEE`
   - Name: `Trainee Teacher`
   - Description: `Pre-service teacher under supervision`
   - Is Primary: `No`
   - Counts for Workload: `No` (trainee periods are not counted)
   - Allows Overlap: `Yes` (trainee may float between classrooms)
   - Workload Factor: `0` (auto-set by business rule)
   - Ordinal: `6`

3. Later, the school discontinues the Trainee programme. Ms. Sharma soft-deletes the TRAINEE role. It is deactivated, moved to trash, and can be restored if needed in the future.

4. Ms. Sharma tries to edit the PRIMARY role's workload factor from 1.00 to 1.50. The system rejects the change because PRIMARY is a system role. She must create a custom role if she needs different behaviour.

## Related Screens

| Screen | Module | Relationship |
|--------|--------|-------------|
| **Teacher Availability** | Timetable Foundation | `tt_teacher_availabilities` links teachers to subjects/classes; the `TeacherAvailabilityController@generateTeacherAvailability` method ensures the two canonical roles (PRIMARY and ASSISTANT) exist before generating availability records. |
| **Activity Teachers** | Timetable Foundation | `tt_activity_teachers` stores the pivot `(activity_id, teacher_id, assignment_role_id)` — this is where roles are actually assigned to teachers for specific activities. |
| **Timetable Cell Teachers** | Timetable Foundation | `tt_timetable_cell_teacher` stores the pivot `(timetable_cell_id, teacher_id, assignment_role_id)` — roles assigned per timetable cell. |
| **Smart Timetable Generation** | SmartTimetable | The `TimetableGenerationService` queries `tt_teacher_assignment_roles` for `is_primary_instructor = true` to identify primary instructors for hard-constraint enforcement. |
| **Activity Controller** | Timetable Foundation | The `ActivityController` caches active roles for teacher assignment lookups during activity creation/editing. Caches `TeacherAssignmentRole::where('is_active', true)->get()`. |

## Requirements

**REQ-TAR-001 — Display Roles List**
The system MUST display all `tt_teacher_assignment_roles` records in a table ordered by `ordinal` ascending, with columns: Ordinal, Code, Name, Description, Primary Instructor (Yes/No badge), Counts for Workload (Yes/No), Allows Overlap (Yes/No), Workload Factor, Status (active/inactive toggle), Actions (View, Edit, Trash).

**REQ-TAR-002 — Create Role**
The system MUST allow authorised users to create a new role with fields: code, name, description, is_primary_instructor, counts_for_workload, allows_overlap, workload_factor, ordinal. The code must be unique and match `^[A-Z0-9_]+$`.

**REQ-TAR-003 — Edit Role**
The system MUST allow authorised users to edit a non-system role. All fields are editable. System roles MUST be rejected with an error message.

**REQ-TAR-004 — Soft Delete Role**
The system MUST allow authorised users to soft-delete a non-system role. On delete, `is_active` MUST be set to `false` before `delete()` is called. System roles MUST be rejected.

**REQ-TAR-005 — Restore Role**
The system MUST allow authorised users to restore a soft-deleted role. On restore, `is_active` MUST be set back to `true`.

**REQ-TAR-006 — Force Delete Role**
The system MUST allow authorised users to permanently delete a soft-deleted role (force delete). System roles MUST be rejected.

**REQ-TAR-007 — Toggle Status**
The system MUST allow authorised users to toggle `is_active` on a non-system role via an AJAX toggle. Returns JSON response.

**REQ-TAR-008 — View Role Detail**
The system MUST display a read-only detail view of a single role showing all fields, timestamps, and the count of related activity teachers.

**REQ-TAR-009 — View Trashed Roles**
The system MUST display a paginated list of soft-deleted roles with options to Restore or Force Delete.

**REQ-TAR-010 — System Role Protection**
The system MUST protect all roles where `is_system = true` from update, delete, force-delete, and status toggle. Any attempt MUST return an appropriate error and MUST NOT modify the record.

**REQ-TAR-011 — Business Rule: Non-Workload Forces Zero Factor**
When `counts_for_workload` is `false`, the system MUST automatically set `workload_factor` to `0`, overriding any user-supplied value.

**REQ-TAR-012 — Business Rule: Primary Instructor Forces No Overlap**
When `is_primary_instructor` is `true`, the system MUST automatically set `allows_overlap` to `false`, overriding any user-supplied value.

**REQ-TAR-013 — Activity Logging**
The system MUST record an audit log entry via `activityLog()` for every create, update, soft-delete, restore, force-delete, and toggle-status operation.

## Who Can Access

| Role | Permission Key | Operations |
|------|---------------|------------|
| Super Admin | `timetable-foundation.teacher-assignment-role.*` | All operations (create, read, update, delete, restore, forceDelete, toggleStatus) |
| Timetable Manager | `timetable-foundation.teacher-assignment-role.viewAny` | View list, view detail |
| Timetable Manager (with create) | `timetable-foundation.teacher-assignment-role.create` | Create new roles |
| Timetable Manager (with update) | `timetable-foundation.teacher-assignment-role.update` | Edit roles, toggle status |
| Timetable Manager (with delete) | `timetable-foundation.teacher-assignment-role.delete` | Soft delete, force delete |
| Timetable Manager (with restore) | `timetable-foundation.teacher-assignment-role.restore` | Restore trashed roles |
| Teacher | None (not applicable) | No access — roles are administrative configuration |

The `TeacherAssignmentRolePolicy` gates each method: `viewAny`, `view`, `create`, `update`, `delete`, `restore`, `forceDelete`. The `toggleStatus` method gates with `update`.

## Logic Flow

### Store / Update Flow

```
User submits form
        │
        ▼
Gate::authorize('create' | 'update')
        │
        ▼ (authorised)
Validate request:
  • code: required|string|max:30|regex:/^[A-Z0-9_]+$/|unique:tt_teacher_assignment_roles
  • name: required|string|max:100
  • description: nullable|string|max:255
  • is_primary_instructor: nullable|boolean
  • counts_for_workload: nullable|boolean
  • allows_overlap: nullable|boolean
  • workload_factor: required|numeric|min:0|max:9.99
  • ordinal: required|integer|min:1
  • is_system: nullable
  • is_active: nullable
        │
        ▼ (pass)
Normalize booleans: $request->boolean(...)
        │
        ▼
Apply business rules:
  • !counts_for_workload → workload_factor = 0
  • is_primary_instructor → allows_overlap = false
        │
        ▼
Persist: TeacherAssignmentRole::create($validated) / ->update($validated)
        │
        ▼
Redirect → timetable-foundation.menu.timetableMasters?tab=teacher-roles
```

### Delete Flow

```
User clicks Trash
        │
        ▼
Gate::authorize('delete')
        │
        ▼ (authorised)
Find: TeacherAssignmentRole::findOrFail($id)
        │
        ▼
Check: $role->is_system?
        │
        ├── YES → redirect back with error
        │
        └── NO  → is_active = false → save() → delete()
                    │
                    ▼
                activityLog('Trashed')
                    │
                    ▼
                Redirect → success
```

### Toggle Status Flow

```
User flips toggle switch
        │
        ▼
POST /teacher-assignment-role/{role}/toggle-status
        │
        ▼
Gate::authorize('update')
        │
        ▼ (authorised)
Validate: is_active required|boolean
        │
        ▼
Check: $role->is_system?
        │
        ├── YES → JSON 403 { success: false, message }
        │
        └── NO  → $role->is_active = $request->boolean('is_active')
                    │
                    ▼
                save() → JSON { success: true, is_active, message }
```

## Validate Before Save

The following validation rules are applied in both `store()` and `update()`:

| Field | Rule | Error Message |
|-------|------|---------------|
| `code` | `required`, `string`, `max:30`, `regex:/^[A-Z0-9_]+$/`, `unique:tt_teacher_assignment_roles,code` | "The code field is required." / "Code must contain only uppercase letters, numbers, and underscores." / "This code is already in use." |
| `name` | `required`, `string`, `max:100` | "The name field is required." |
| `description` | `nullable`, `string`, `max:255` | "Description may not be longer than 255 characters." |
| `is_primary_instructor` | `nullable`, `boolean` | Coerced to boolean via `$request->boolean()`. |
| `counts_for_workload` | `nullable`, `boolean` | Coerced to boolean; default `true`. |
| `allows_overlap` | `nullable`, `boolean` | Coerced to boolean. |
| `workload_factor` | `required`, `numeric`, `min:0`, `max:9.99` | "Workload factor must be between 0 and 9.99." |
| `ordinal` | `required`, `integer`, `min:1` | "Ordinal must be at least 1." |
| `is_system` | `nullable` | Coerced to boolean. |
| `is_active` | `nullable` | Coerced to boolean; default `true`. |

On update, the `code` unique rule includes `->ignore($teacherAssignmentRole->id)` so the role's own code does not trigger a false conflict.

**Business Rule Enforcement (post-validation):**
- If `counts_for_workload === false` → `workload_factor` is overridden to `0`.
- If `is_primary_instructor === true` → `allows_overlap` is overridden to `false`.

## Error Handling and Validation Messages

| Scenario | HTTP Status | Response |
|----------|-------------|----------|
| Validation failure (any field) | 302 Redirect | Redirect back with `$errors` bag; fields re-populated. |
| Update on system role | 302 Redirect | Flash error: `system_record_update_not_allowed` |
| Delete on system role | 302 Redirect | Flash error: "Cannot delete `{name}` — it is a system role." |
| Force delete on system role | 302 Redirect | Flash error: `system_record_force_delete_not_allowed` |
| Toggle status on system role | 403 JSON | `{ success: false, is_active, message: "System role status cannot be changed." }` |
| Not authorised (view list) | 403 | `AuthorizationException` → Laravel 403 page |
| Not authorised (create) | 403 | `AuthorizationException` → Laravel 403 page |
| Not authorised (update) | 403 | `AuthorizationException` → Laravel 403 page |
| Not authorised (delete) | 403 | `AuthorizationException` → Laravel 403 page |
| Not authorised (restore) | 403 | `AuthorizationException` → Laravel 403 page |
| Model not found | 404 | `ModelNotFoundException` → 404 page |
| DB constraint violation | 500 | Exception logged; generic error page shown |

## Success Scenarios

**SC-001 — Create a New Custom Role**
Ms. Sharma creates a role with Code = `MENTOR`, Name = `Mentor Teacher`, Counts for Workload = checked (true), Workload Factor = `0.75`, Ordinal = `6`. The role is saved with `is_system = false` (default for user-created). She is redirected to the Teacher Roles tab with a green success message.

**SC-002 — Edit a Custom Role Name**
Ms. Sharma changes the name of the `MENTOR` role to "Senior Mentor Teacher". The update succeeds, activity is logged, and the table refreshes with the new name.

**SC-003 — Delete a Custom Role**
Ms. Sharma clicks Trash on the `MENTOR` role. The role is deactivated (`is_active = false`), soft-deleted, and disappears from the active list. It appears in the Trash view.

**SC-004 — Restore a Deleted Role**
Ms. Sharma navigates to the Trash view, finds the `MENTOR` role, and clicks Restore. The role is restored with `is_active = true` and reappears in the active list.

**SC-005 — Toggle Status via AJAX**
Ms. Sharma clicks the status toggle next to `MENTOR`. A POST request is sent; the server flips `is_active` and returns `{ success: true, is_active: false }`. The toggle UI updates without a page reload.

## Failure Scenarios

**FC-001 — Duplicate Role Code**
Ms. Sharma tries to create a role with code `ASSISTANT` (which already exists as a system role). The `unique` validation rule returns: "The code has already been taken." The form is re-displayed with the error.

**FC-002 — Invalid Code Format**
Ms. Sharma enters code `primary-role` (lowercase with hyphen). The `regex:/^[A-Z0-9_]+$/` rule returns: "Code must contain only uppercase letters, numbers, and underscores."

**FC-003 — Edit System Role**
Ms. Sharma clicks Edit on the PRIMARY role. The `update()` method detects `is_system = true` and redirects back with error: "System record update not allowed."

**FC-004 — Delete System Role**
Ms. Sharma clicks Trash on the PRIMARY role. The `destroy()` method checks `is_system` and returns: "Cannot delete "Primary Instructor" — it is a system role."

**FC-005 — Toggle System Role Status**
Ms. Sharma toggles the status switch on the PRIMARY role. The server returns a 403 JSON response: `{ success: false, is_active: true, message: "System role status cannot be changed." }`

**FC-006 — Unauthorised Access (No Permission)**
A teacher without the `timetable-foundation.teacher-assignment-role.*` permission tries to access the Teacher Roles tab. `Gate::authorize()` throws an `AuthorizationException`, resulting in a 403 HTTP response.

## Dependencies module and tables

| Dependency | Type | Details |
|------------|------|---------|
| `tt_teacher_assignment_roles` | Primary table | Master data table; `tinyIncrements('id')` — max 255 rows. All CRUD operations target this table. |
| `tt_activity_teachers` | Child (FK) | `tt_activity_teachers.assignment_role_id` FK references `tt_teacher_assignment_roles(id)` via `fk_at_role`. ON DELETE behaviour not explicitly set — defaults to RESTRICT. Teachers with roles used in activities cannot have their role deleted. |
| `tt_timetable_cell_teacher` | Child (FK) | `tt_timetable_cell_teacher.assignment_role_id` FK references `tt_teacher_assignment_roles(id)` via `fk_cct_role`. Same RESTRICT constraint. |
| `Modules\TimetableFoundation\Models\TeacherAssignmentRole` | Eloquent model | Uses `SoftDeletes`; casts all booleans; uses `BaseModel` as parent. |
| `TeacherAssignmentRolePolicy` | Auth policy | Gates all CRUD actions; registered in `TimetableFoundationServiceProvider`. |
| `activityLog()` helper | Service dependency | Called on every state change (create, update, destroy, restore, forceDelete, toggleStatus). |
| `TimetableFoundationServiceProvider` | Service provider | Registers `Gate::policy(TeacherAssignmentRole::class, TeacherAssignmentRolePolicy::class)`. |

**Table:** `tt_teacher_assignment_roles`

| Column | Type | Details |
|--------|------|---------|
| `id` | TINYINT UNSIGNED | Primary key, auto-increment (max 255 rows) |
| `code` | VARCHAR(30) | NOT NULL. Unique (`uq_tarole_code`). Uppercase + digits + underscores only. |
| `name` | VARCHAR(100) | NOT NULL. Display name. |
| `description` | VARCHAR(255) | NULLABLE. |
| `is_primary_instructor` | BOOLEAN | DEFAULT FALSE. |
| `counts_for_workload` | BOOLEAN | DEFAULT FALSE. |
| `allows_overlap` | BOOLEAN | DEFAULT FALSE. |
| `workload_factor` | DECIMAL(5,2) | DEFAULT 1.00. Range 0–9.99. |
| `ordinal` | TINYINT UNSIGNED | DEFAULT 1. Sort order. |
| `is_system` | BOOLEAN | DEFAULT TRUE. Protects seeded roles. |
| `is_active` | BOOLEAN | DEFAULT TRUE. |
| `created_at` | TIMESTAMP | NULLABLE. |
| `updated_at` | TIMESTAMP | NULLABLE. |
| `deleted_at` | TIMESTAMP | NULLABLE. From SoftDeletes trait. |

**Unique Keys:**
- `uq_tarole_code` — on `code` (ensures unique code across all roles)

**Seeded Data (TtTeacherAssignmentRoleSeeder):**

| Code | Name | Primary | Workload Factor | Overlap | Ordinal | System |
|------|------|---------|----------------|---------|---------|--------|
| PRIMARY | Primary Instructor | Yes | 1.00 | No | 1 | Yes |
| ASSISTANT | Assistant Teacher | No | 0.50 | Yes | 2 | Yes |
| CO_TEACHER | Co-Teacher | No | 1.00 | No | 3 | Yes |
| OBSERVER | Observer | No | 0.00 | Yes | 4 | Yes |
| SUBSTITUTE | Substitute Teacher | Yes | 1.00 | No | 5 | Yes |
