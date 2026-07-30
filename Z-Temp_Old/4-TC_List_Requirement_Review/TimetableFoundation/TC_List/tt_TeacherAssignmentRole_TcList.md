# tt_TeacherAssignmentRole_TcList

## Module: TimetableFoundation → Timetable Masters → Teacher Assignment Roles

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | TimetableFoundation |
| Tab Group | Timetable Masters |
| Feature | Teacher Assignment Roles |
| URL(s) | `GET /timetable-foundation/teacher-assignment-role` — redirects to `timetable-foundation.menu.timetableMasters?tab=teacher-roles` |
| | `GET /timetable-foundation/teacher-assignment-role/create` — create form |
| | `POST /timetable-foundation/teacher-assignment-role` — store |
| | `GET /timetable-foundation/teacher-assignment-role/{id}` — show |
| | `GET /timetable-foundation/teacher-assignment-role/{id}/edit` — edit form |
| | `PUT /timetable-foundation/teacher-assignment-role/{id}` — update |
| | `DELETE /timetable-foundation/teacher-assignment-role/{id}` — destroy (soft) |
| | `GET /timetable-foundation/teacher-assignment-role/trash/view` — trashed list |
| | `GET /timetable-foundation/teacher-assignment-role/{id}/restore` — restore |
| | `DELETE /timetable-foundation/teacher-assignment-role/{id}/force-delete` — force delete |
| | `POST /timetable-foundation/teacher-assignment-role/{teacherAssignmentRole}/toggle-status` — toggle AJAX |
| Controller | `Modules\TimetableFoundation\Http\Controllers\TeacherAssignmentRoleController`; `index()` lines 16–21 (redirect), `create()` lines 26–31, `store()` lines 36–149, `show()` lines 154–159, `edit()` lines 164–170, `update()` lines 175–301, `destroy()` lines 306–339, `trashedTeacherAssignmentRole()` lines 341–353, `forceDelete()` lines 354–381, `restore()` lines 382–406, `toggleStatus()` lines 407–449 |
| Model(s) | `Modules\TimetableFoundation\Models\TeacherAssignmentRole` (table: `tt_teacher_assignment_roles`) |
| Validation (Create) | Inline in `store()` (no separate Form Request) |
| Validation (Update) | Inline in `update()` — unique code ignores current ID |
| Policy | `Modules\TimetableFoundation\Policies\TeacherAssignmentRolePolicy` (viewAny, view, create, update, delete, restore, forceDelete) |
| Permissions | `timetable-foundation.teacher-assignment-role.viewAny` |
| | `timetable-foundation.teacher-assignment-role.view` |
| | `timetable-foundation.teacher-assignment-role.create` |
| | `timetable-foundation.teacher-assignment-role.update` |
| | `timetable-foundation.teacher-assignment-role.delete` |
| | `timetable-foundation.teacher-assignment-role.restore` |
| | `timetable-foundation.teacher-assignment-role.forceDelete` |
| Pagination | 10 records per page on main tab list (`tr_page` parameter); 10 records per page on trash view |
| Soft Deletes | Yes — `SoftDeletes` trait on Model |
| Read-Only | No — full CRUD |

---

## 2. Pre-conditions

- Admin user has all `timetable-foundation.teacher-assignment-role.*` permissions granted.
- Dusk environment variables set: `DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD`.
- Seeded system roles exist: PRIMARY, ASSISTANT, CO_TEACHER, SUBSTITUTE, TRAINEE (all `is_system = 1`).
- At least one non-system role exists for update/delete tests (created fresh as needed).
- Tenant academic session, classes, sections, subjects, employees not required for this CRUD screen (no FK dependencies at creation time).

---

## 3. Default Data Load

The `index()` method in `TeacherAssignmentRoleController` redirects to `TimetableFoundationController@timetableMasters` with `tab=teacher-roles`. That method queries roles with eager-loaded `activityTeachers.teacher.user` and `activityTeachers.activity.subject/class/section`, ordered by `teachers_count DESC, ordinal, name`, paginated at 10 per page with `tr_page` parameter.

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| Teacher Roles list | `TimetableFoundationController@timetableMasters` | `TeacherAssignmentRole::with('activityTeachers.teacher.user', 'activityTeachers.activity.subject', 'activityTeachers.activity.class', 'activityTeachers.activity.section')` | `tr_search` (name/code), `tr_status` (1/0) | 10/page (`tr_page`) |

---

## 4. Test Data Strategy

- **System seed roles**: Verify 5 system roles (PRIMARY, ASSISTANT, CO_TEACHER, SUBSTITUTE, TRAINEE) are present with `is_system = 1`.
- **Non-system roles**: Create test roles via UI for edit/delete/toggle tests — use unique codes e.g. `TEST_ROLE_01`, `TEST_ROLE_02`.
- **Pre-test cleanup**: Ensure no test role codes collide — use a unique test prefix.
- **Pagination overflow**: Create 12+ roles to test the 10-record per-page limit.
- **Child table data**: For dependency tests, create `ActivityTeacher` and `TimetableCellTeacher` records referencing a role to verify RESTRICT behavior.

---

## 5. Business Conditions

### 5.1 Database Schema — `tt_teacher_assignment_roles`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | `id` | TINYINT UNSIGNED | PK, NOT NULL, AUTO_INCREMENT |
| BC-DB-02 | `code` | VARCHAR(30) | NOT NULL, UNIQUE (`uq_tarole_code`) |
| BC-DB-03 | `name` | VARCHAR(100) | NOT NULL |
| BC-DB-04 | `description` | VARCHAR(255) | DEFAULT NULL |
| BC-DB-05 | `is_primary_instructor` | TINYINT(1) | NOT NULL, DEFAULT 0 |
| BC-DB-06 | `counts_for_workload` | TINYINT(1) | NOT NULL, DEFAULT 0 |
| BC-DB-07 | `allows_overlap` | TINYINT(1) | NOT NULL, DEFAULT 0 |
| BC-DB-08 | `workload_factor` | DECIMAL(5,2) | DEFAULT 1.00 |
| BC-DB-09 | `ordinal` | TINYINT UNSIGNED | DEFAULT 1 |
| BC-DB-10 | `is_system` | TINYINT(1) | DEFAULT 1 |
| BC-DB-11 | `is_active` | TINYINT(1) | NOT NULL, DEFAULT 1 |
| BC-DB-12 | `created_at` | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |
| BC-DB-13 | `updated_at` | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP |
| BC-DB-14 | `deleted_at` | TIMESTAMP | NULL DEFAULT NULL |
| BC-DB-15 | UNIQUE KEY `uq_tarole_code` | — | `code` |

### 5.2 Validation Rules — Inline in `store()` (Create)

| BC ID | Field | Rule(s) | Error Message |
|-------|-------|---------|---------------|
| BC-VAL-01 | `code` | `required`, `string`, `max:30`, `regex:/^[A-Z0-9_]+$/`, `unique:tt_teacher_assignment_roles,code` | Laravel default — "validation.unique", "validation.regex" |
| BC-VAL-02 | `name` | `required`, `string`, `max:100` | Laravel default |
| BC-VAL-03 | `description` | `nullable`, `string`, `max:255` | Laravel default |
| BC-VAL-04 | `is_primary_instructor` | `nullable`, `boolean` (normalized via `$request->boolean()`) | — |
| BC-VAL-05 | `counts_for_workload` | `nullable`, `boolean` (normalized via `$request->boolean(`, `true`)` default true) | — |
| BC-VAL-06 | `allows_overlap` | `nullable`, `boolean` (normalized via `$request->boolean()`) | — |
| BC-VAL-07 | `workload_factor` | `required`, `numeric`, `min:0`, `max:9.99` | Laravel default |
| BC-VAL-08 | `ordinal` | `required`, `integer`, `min:1` | Laravel default |
| BC-VAL-09 | `is_system` | `nullable` (normalized via `$request->boolean()`) | — |
| BC-VAL-10 | `is_active` | `nullable` (normalized via `$request->boolean()`) | — |
| BC-VAL-11 | *Business override* | If `counts_for_workload = false` → `workload_factor` forced to 0 | — |
| BC-VAL-12 | *Business override* | If `is_primary_instructor = true` → `allows_overlap` forced to false | — |

### 5.3 Validation Rules — Inline in `update()` (Update)

| BC ID | Field | Rule(s) | Error Message |
|-------|-------|---------|---------------|
| BC-VAL-13 | `code` | `required`, `string`, `max:30`, `regex:/^[A-Z0-9_]+$/`, `unique:tt_teacher_assignment_roles,code` → ignores current ID | Laravel default |
| BC-VAL-14 | `name` | `required`, `string`, `max:100` | Laravel default |
| BC-VAL-15 | `description` | `nullable`, `string`, `max:255` | Laravel default |
| BC-VAL-16 | `is_primary_instructor` | `nullable`, `boolean` | — |
| BC-VAL-17 | `counts_for_workload` | `nullable`, `boolean` | — |
| BC-VAL-18 | `allows_overlap` | `nullable`, `boolean` | — |
| BC-VAL-19 | `workload_factor` | `required`, `numeric`, `min:0`, `max:9.99` | Laravel default |
| BC-VAL-20 | `ordinal` | `required`, `integer`, `min:1` | Laravel default |
| BC-VAL-21 | `is_system` | `nullable` | — |
| BC-VAL-22 | `is_active` | `nullable` | — |
| BC-VAL-23 | *Business override* | If `counts_for_workload = false` → `workload_factor` forced to 0 | — |
| BC-VAL-24 | *Business override* | If `is_primary_instructor = true` → `allows_overlap` forced to false | — |

### 5.4 Authorization

| BC ID | Permission | Behavior |
|-------|-----------|----------|
| BC-AUTH-01 | `timetable-foundation.teacher-assignment-role.viewAny` | Without it → 403 on index / trashed list |
| BC-AUTH-02 | `timetable-foundation.teacher-assignment-role.view` | Without it → 403 on show |
| BC-AUTH-03 | `timetable-foundation.teacher-assignment-role.create` | Without it → 403 on create/store |
| BC-AUTH-04 | `timetable-foundation.teacher-assignment-role.update` | Without it → 403 on edit/update/toggleStatus |
| BC-AUTH-05 | `timetable-foundation.teacher-assignment-role.delete` | Without it → 403 on destroy/forceDelete |
| BC-AUTH-06 | `timetable-foundation.teacher-assignment-role.restore` | Without it → 403 on restore |
| BC-AUTH-07 | `timetable-foundation.teacher-assignment-role.forceDelete` | Without it → 403 on forceDelete |
| BC-AUTH-08 | Guest access | Redirect to `/login` on any route |

### 5.5 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Screen loads with `tab=teacher-roles` | Accordion list of roles is rendered; each row shows code, name, badges (primary, system, workload, overlap, ordinal), teacher count |
| BC-BIZ-02 | Search by `tr_search` | Roles matching name or code (case-insensitive substring) are shown; non-matching roles hidden |
| BC-BIZ-03 | Filter by `tr_status=1` | Only active roles displayed |
| BC-BIZ-04 | Filter by `tr_status=0` | Only inactive roles displayed |
| BC-BIZ-05 | Pagination exceeds 10 roles | Roles paginated at 10 per page; page navigation visible; `tr_page` parameter present in URL |
| BC-BIZ-06 | Empty role list | "No teacher roles found." placeholder displayed |
| BC-BIZ-07 | `counts_for_workload = false` | `workload_factor` is forced to 0 regardless of submitted value |
| BC-BIZ-08 | `is_primary_instructor = true` | `allows_overlap` is forced to false regardless of submitted value |
| BC-BIZ-09 | System role (`is_system = 1`) | Lock icon displayed; edit form disables code field; update blocked with error; delete blocked with error; toggleStatus returns 403 JSON; force delete blocked with error |
| BC-BIZ-10 | Non-system role soft delete | `is_active` set to false before `delete()`; record moved to trash with `deleted_at` |
| BC-BIZ-11 | Restore from trash | `is_active` set to true after `restore()`; record reappears in main list |

### 5.6 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|------------------|----------------|
| BC-REF-01 | `activity_teachers.assignment_role_id` | `tt_teacher_assignment_roles.id` | RESTRICT |
| BC-REF-02 | `timetable_cell_teachers.assignment_role_id` | `tt_teacher_assignment_roles.id` | RESTRICT |

---

## 6. Test Case List

### 6.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|-----------------|---------|---------|--------|
| TC-P01 | Load teacher roles tab on Timetable Masters page | `GET /timetable-foundation/timetable-masters?tab=teacher-roles` returns 200; accordion list renders with all seeded system roles (PRIMARY, ASSISTANT, CO_TEACHER, SUBSTITUTE, TRAINEE); each accordion header shows code, name, badges, teacher count | — | — | ⬜ |
| TC-P02 | Expand accordion item to view role details | Click accordion header; body expands showing description (or "No description."), status toggle, action buttons, and assigned teachers table (or "No teachers are currently assigned" if none) | — | — | ⬜ |
| TC-P03 | Search roles by code or name | Enter `PRIMARY` in search box, submit; only role with code/name containing "PRIMARY" shown; non-matching roles hidden | — | — | ⬜ |
| TC-P04 | Filter by active status | Select "Active" from status dropdown, submit; only roles with `is_active = 1` displayed | — | — | ⬜ |
| TC-P05 | Filter by inactive status | Select "Inactive" from status dropdown, submit; only roles with `is_active = 0` displayed | — | — | ⬜ |
| TC-P06 | Reset filters | Apply search and status filter, then click reset button; all roles shown without filters | — | — | ⬜ |
| TC-P07 | Pagination with 10+ roles | Create 12+ roles; navigate to page 2; 2 remaining roles shown; `tr_page=2` in URL; page navigation controls visible | — | — | ⬜ |
| TC-P08 | Create role — all fields filled | Fill code=`TEST_PRIMARY`, name=`Test Primary`, description=`Test description`, workload_factor=`1.50`, ordinal=`10`, check Primary Instructor, check Counts for Workload, uncheck Allows Overlap, Active; submit; role created; redirect to tab; success flash message | — | — | ⬜ |
| TC-P09 | Create role — required fields only | Fill code=`TEST_MIN`, name=`Test Minimal`, workload_factor=`1.00`, ordinal=`5`; submit; role created with defaults: `is_primary_instructor=false`, `counts_for_workload=true`, `allows_overlap=false`, `is_system=true`, `is_active=true` | — | — | ⬜ |
| TC-P10 | View role details | Navigate to show page for a role; all fields displayed: Code, Name, Description, Is Primary Instructor (Yes/No badge), Counts for Workload (Yes/No badge), Allows Overlap (Yes/No badge), Workload Factor, Ordinal, Is System (Yes/No), Status (Active/Inactive), Created, Updated | — | — | ⬜ |
| TC-P11 | Edit role — update name and flags | Navigate to edit page for a non-system role; change name to `Updated Role`, uncheck Counts for Workload, check Allows Overlap; submit; update succeeds; redirect to tab; success flash message; name updated; `workload_factor` forced to 0 (because counts_for_workload=false) | — | — | ⬜ |
| TC-P12 | Toggle active status via AJAX | POST to toggle-status endpoint with `is_active=true` for an inactive non-system role; JSON response `{"success":true, "is_active":true, "message":"..."}`; DB updated; status badge changes in UI | — | — | ⬜ |
| TC-P13 | Soft delete non-system role | Click delete on a non-system role; `is_active` set to false; record soft-deleted (`deleted_at` populated); redirect to tab; success flash; record no longer appears in main list | — | — | ⬜ |
| TC-P14 | Trash view loads soft-deleted roles | Navigate to trash view; soft-deleted records shown with name, code, workload badge ("Ignored" since is_active=false), behavior badges, "Inactive" status badge, restore and force-delete actions | — | — | ⬜ |
| TC-P15 | Restore role from trash | Click restore on a soft-deleted non-system role; `restore()` called; `is_active` set to true; redirect to trash; success flash message; record reappears in main list | — | — | ⬜ |
| TC-P16 | Force delete role from trash | Click force delete on a soft-deleted non-system role; record permanently deleted from DB; redirect to trash; success flash message; record no longer in trash | — | — | ⬜ |
| TC-P17 | Business rule — counts_for_workload=false forces workload_factor=0 | Create role with `counts_for_workload` unchecked and `workload_factor=2.00`; after save, `workload_factor` is 0; edit same role, check `counts_for_workload`, set `workload_factor=1.50`; workload_factor saved as 1.50 | — | — | ⬜ |
| TC-P18 | Business rule — is_primary_instructor=true forces allows_overlap=false | Create role with `is_primary_instructor` checked and `allows_overlap` checked; after save, `allows_overlap` is false; edit same role, uncheck `is_primary_instructor`, check `allows_overlap`; allows_overlap saved as true | — | — | ⬜ |

### 6.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|-----------------|---------|---------|--------|
| TC-N01 | Create role — missing required fields | Submit create form with empty code, name, workload_factor, ordinal; validation errors for `code` (required), `name` (required), `workload_factor` (required), `ordinal` (required) | — | — | ⬜ |
| TC-N02 | Create role — duplicate code | Submit with code `PRIMARY` (already exists as system role); validation error: `code` must be unique | — | — | ⬜ |
| TC-N03 | Create role — invalid code format | Submit code `primary!` (lowercase + special char); validation error: `code` format invalid (regex `/^[A-Z0-9_]+$/`) | — | — | ⬜ |
| TC-N04 | Create role — workload_factor out of range | Submit `workload_factor=-1` or `workload_factor=10`; validation error: min:0 / max:9.99 | — | — | ⬜ |
| TC-N05 | Create role — ordinal less than 1 | Submit `ordinal=0`; validation error: min:1 | — | — | ⬜ |
| TC-N06 | Update system role — blocked | Submit edit form for a system role (e.g. PRIMARY); redirect back with error flash `system_record_update_not_allowed`; DB unchanged | — | — | ⬜ |
| TC-N07 | Delete system role — blocked | Click delete on a system role (e.g. PRIMARY); redirect back with error flash "Cannot delete ... it is a system role."; record not deleted | — | — | ⬜ |
| TC-N08 | Toggle status on system role — 403 | POST to toggle-status for a system role; JSON response `{"success":false, "is_active":true, "message":"..."}` with HTTP 403; status unchanged | — | — | ⬜ |
| TC-N09 | Force delete system role — blocked | Try to force delete a system role; redirect back with error flash `system_record_force_delete_not_allowed`; record not deleted | — | — | ⬜ |
| TC-N10 | Guest access to index route | Visit any teacher-assignment-role route while not logged in; redirect to `/login` | — | — | ⬜ |
| TC-N11 | Missing viewAny permission | User without `viewAny` tries to access index; 403 Forbidden | — | — | ⬜ |
| TC-N12 | Missing create permission | User without `create` tries to access create/store; 403 Forbidden | — | — | ⬜ |
| TC-N13 | Non-existent role ID — show/edit/update/destroy | Access route with invalid ID (e.g. 9999); 404 Not Found | — | — | ⬜ |

### 6.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|-----------------|---------|---------|--------|
| TC-D01 | A | Delete role that has assigned ActivityTeacher records | Delete blocked by FK RESTRICT constraint; DB throws integrity constraint violation; role not deleted | — | — | ⬜ |
| TC-D02 | A | Delete role that has assigned TimetableCellTeacher records | Delete blocked by FK RESTRICT constraint; DB throws integrity constraint violation; role not deleted | — | — | ⬜ |
| TC-D03 | B | Activity logging on create/update/delete/restore/toggle | Each state change creates an activity log entry with model name, action type (Created/Updated/Trashed/Restored/Toggled/Deleted), and descriptive message | — | — | ⬜ |
| TC-D04 | C | Model `$fillable` matches DDL columns | `$fillable` array contains: code, name, description, is_primary_instructor, counts_for_workload, allows_overlap, workload_factor, ordinal, is_system, is_active (no extra columns, no missing columns) | — | — | ⬜ |
| TC-D05 | C | Model `$casts` for boolean/decimal/integer/datetime columns | `is_primary_instructor` → boolean, `counts_for_workload` → boolean, `allows_overlap` → boolean, `is_system` → boolean, `is_active` → boolean, `ordinal` → integer, `workload_factor` → decimal:2, `created_at` → datetime, `updated_at` → datetime, `deleted_at` → datetime | — | — | ⬜ |
| TC-D06 | D | Unique `code` constraint at DB level | Direct DB insert with duplicate code (e.g. 'PRIMARY') throws `SQLSTATE[23000]: Integrity constraint violation` for `uq_tarole_code` | — | — | ⬜ |

### 6.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|-----------------|---------|---------|--------|
| TC-CR01 | CR | P1 | Model — `$fillable` matches DDL columns for mass-assignment protection | All 10 DDL columns present; no extra column that does not exist in DDL | — | — | ◌ |
| TC-CR02 | CR | P1 | Model — `$casts` for booleans/integers/decimals/dates | Boolean casts for all 5 tinyint flags; integer for ordinal; decimal:2 for workload_factor; datetime for 3 timestamps | — | — | ◌ |
| TC-CR03 | CR | P1 | Model — SoftDeletes trait correctly implemented | `SoftDeletes` imported and used; `deleted_at` column in `$casts`; soft-deleted records return null `deleted_at` after restore | — | — | ◌ |
| TC-CR04 | CR | P1 | Model — relationships defined | `activityTeachers()` (hasMany ActivityTeacher), `timetableCellTeachers()` (hasMany TimetableCellTeacher) — both defined with correct FKs | — | — | ◌ |
| TC-CR05 | CR | P1 | Controller — try-catch exception handling on all write methods | `store()`, `update()`, `destroy()`, `forceDelete()`, `restore()`, `toggleStatus()` wrapped in try-catch or use Laravel's DB exception handling | — | — | ◌ |
| TC-CR06 | CR | P1 | Controller — DB transactions on multi-step writes | `store()` wraps create in transaction; `update()` wraps update; `destroy()` wraps deactivate+delete | — | — | ◌ |
| TC-CR07 | CR | P1 | Controller — `Gate::authorize()` on every method | Each public method: `index()`, `create()`, `store()`, `show()`, `edit()`, `update()`, `destroy()`, `trashedTeacherAssignmentRole()`, `forceDelete()`, `restore()`, `toggleStatus()` calls `Gate::authorize()` before any logic | — | — | ◌ |
| TC-CR08 | CR | P1 | Controller — activity logged on all state changes | `store()` → 'Created'; `update()` → 'Updated'; `destroy()` → 'Trashed'; `forceDelete()` → 'Deleted'; `restore()` → 'Restored'; `toggleStatus()` → 'Toggled'; each with descriptive message | — | — | ◌ |
| TC-CR09 | CR | P1 | Controller — `is_active=false` before soft delete; restore sets `is_active=true` | `destroy()` sets `is_active=false` then `save()` before `delete()`; `restore()` calls `restore()` then sets `is_active=true` then `save()` | — | — | ◌ |
| TC-CR10 | CR | P1 | Controller — `toggleStatus()` flips `is_active` | Method validates `is_active` boolean, updates model, saves, returns JSON `{success: true, is_active: <new_value>, message: "..."}` | — | — | ◌ |
| TC-CR11 | CR | P1 | Controller — trash/restore/forceDelete flow | `trashedTeacherAssignmentRole()` uses `onlyTrashed()` + `paginate(10)`; `restore()` uses `onlyTrashed()->findOrFail($id)`; `forceDelete()` uses `withTrashed()->findOrFail($id)` | — | — | ◌ |
| TC-CR12 | CR | P1 | Controller — JSON/flash response after write operations | All write methods return redirect with `success` flash message (or JSON for toggleStatus); failure scenarios return `error` flash with descriptive message | — | — | ◌ |
| TC-CR13 | CR | P1 | Validation — rules cover all fields; unique code ignores current ID on update | `store()` rule: `unique:tt_teacher_assignment_roles,code`; `update()` rule: `unique:tt_teacher_assignment_roles,code` with `->ignore($teacherAssignmentRole->id)` | — | — | ◌ |
| TC-CR14 | CR | P1 | Policy — all 7 CRUD methods defined with correct permission strings | `viewAny`, `view`, `create`, `update`, `delete`, `restore`, `forceDelete` — each calls `$user->can('timetable-foundation.teacher-assignment-role.<action>')` | — | — | ◌ |
| TC-CR15 | CR | P1 | Routes — resource + custom routes registered; model binding 404s | `Route::resource('teacher-assignment-role', ...)` generates 7 routes; 4 custom routes (trashed, restore, forceDelete, toggleStatus); implicit model binding on `{teacherAssignmentRole}` returns 404 for missing IDs | — | — | ◌ |
| TC-CR16 | CR | P1 | View — Blade `@can` directives / component visibility on action buttons | Action buttons (edit, delete, status switch) render based on user permissions via `x-backend.table.action` and `x-backend.table.status-switch` components | — | — | ◌ |

---

## 7. Detailed Test Steps

#### TC-CR01: Model — `$fillable` Matches DDL Columns

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `TeacherAssignmentRole.php` `$fillable` array | Array contains: `code`, `name`, `description`, `is_primary_instructor`, `counts_for_workload`, `allows_overlap`, `workload_factor`, `ordinal`, `is_system`, `is_active` |
| 2 | Cross-reference with DDL columns of `tt_teacher_assignment_roles` | All 10 fillable columns exist in DDL; no fillable column is absent from DDL; no DDL column that is fillable (excluding id, created_at, updated_at, deleted_at) is missing |

#### TC-CR02: Model — `$casts` for Booleans/Integers/Decimals/Dates

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `TeacherAssignmentRole.php` `$casts` array | Contains: `is_primary_instructor`→boolean, `counts_for_workload`→boolean, `allows_overlap`→boolean, `is_system`→boolean, `is_active`→boolean, `ordinal`→integer, `workload_factor`→`decimal:2`, `created_at`→datetime, `updated_at`→datetime, `deleted_at`→datetime |

#### TC-CR03: Model — SoftDeletes Trait

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `TeacherAssignmentRole.php` imports | `use SoftDeletes;` present from `Illuminate\Database\Eloquent\SoftDeletes` |
| 2 | Verify `deleted_at` in `$casts` | `'deleted_at' => 'datetime'` present |

#### TC-CR04: Model — Relationships Defined

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `TeacherAssignmentRole.php` | `activityTeachers()` returns `$this->hasMany(ActivityTeacher::class, 'assignment_role_id')` |
| 2 | | `timetableCellTeachers()` returns `$this->hasMany(TimetableCellTeacher::class, 'assignment_role_id')` |

#### TC-CR05 through TC-CR16 — Implementation Verification

*These are static code review TCs verified by file inspection. Implementation details are described in the Expected Result column of Section 6.4. Run automated PHPStan/Pint or manual code review to confirm each assertion.*

---

### 7.1 Positive TC Steps

#### TC-P01: Load Teacher Roles Tab

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Log in as admin with full permissions | Dashboard loads |
| 2 | Navigate to `GET /timetable-foundation/timetable-masters?tab=teacher-roles` | HTTP 200; page title "Timetable Masters" visible |
| 3 | Locate the Teacher Roles tab pane | Accordion list visible with role items; each header shows code (e.g. `PRIMARY`), name (e.g. "Primary Teacher"), badges (workload factor, primary star, lock icon for system roles) |
| 4 | Verify seeded system roles present | PRIMARY, ASSISTANT, CO_TEACHER, SUBSTITUTE, TRAINEE — all 5 system roles rendered |

#### TC-P02: Expand Accordion Item

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click on the PRIMARY accordion header | Body expands showing: description text (or "No description." if null), status toggle switch, action buttons (edit, delete), and the teacher assignments table (or "No teachers are currently assigned" message) |

#### TC-P03: Search Roles by Code or Name

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Type `PRIMARY` in the search bar | — |
| 2 | Click search (magnifying glass) button | Page reloads with `?tab=teacher-roles&tr_search=PRIMARY`; only role with "PRIMARY" in code or name shown; non-matching roles hidden |
| 3 | Clear search and submit empty search | All roles shown again |

#### TC-P04: Filter by Active Status

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select "Active" from status dropdown | — |
| 2 | Click search button | Page reloads with `?tab=teacher-roles&tr_status=1`; only roles with `is_active=1` displayed |

#### TC-P05: Filter by Inactive Status

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select "Inactive" from status dropdown | — |
| 2 | Click search button | Page reloads with `?tab=teacher-roles&tr_status=0`; only roles with `is_active=0` displayed |

#### TC-P06: Reset Filters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Apply search text and status filter | Filtered results shown |
| 2 | Click reset (rotate-left icon) button | Page reloads with `?tab=teacher-roles`; all roles shown; search and filter fields cleared |

#### TC-P07: Pagination with 10+ Roles

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure 12+ non-deleted roles exist (create via UI if needed) | — |
| 2 | Navigate to teacher roles tab | 10 roles shown on page 1; pagination controls visible |
| 3 | Click page 2 link | URL contains `tr_page=2`; remaining roles shown (2 roles on page 2) |

#### TC-P08: Create Role — All Fields Filled

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click "Add" button to navigate to create form | `GET /timetable-foundation/teacher-assignment-role/create` — form rendered with all fields |
| 2 | Fill code: `TEST_PRIMARY` | — |
| 3 | Fill name: `Test Primary Instructor` | — |
| 4 | Fill description: `A test role for primary instruction` | — |
| 5 | Fill workload_factor: `1.50` | — |
| 6 | Fill ordinal: `10` | — |
| 7 | Check "Primary Instructor" | — |
| 8 | Check "Counts for Workload" | — |
| 9 | Leave "Allows Overlap" unchecked | — |
| 10 | Ensure "Active" status switch is ON | — |
| 11 | Click "Create Teacher Assignment Role" submit button | POST request; redirect to `timetable-foundation.menu.timetableMasters?tab=teacher-roles`; success flash message displayed |
| 12 | Find `TEST_PRIMARY` in the accordion list | Role present with code `TEST_PRIMARY`, name "Test Primary Instructor", primary instructor star icon, workload factor badge "1.50x", "Workload" badge, ordinal "#10", no "Overlap" badge |

#### TC-P09: Create Role — Required Fields Only

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to create form | — |
| 2 | Fill code: `TEST_MIN` | — |
| 3 | Fill name: `Test Minimal` | — |
| 4 | Fill workload_factor: `1.00` | — |
| 5 | Fill ordinal: `5` | — |
| 6 | Leave all checkboxes at defaults | — |
| 7 | Submit form | Role created; `is_primary_instructor=false`, `counts_for_workload=true`, `allows_overlap=false`, `is_system=true`, `is_active=true` |

#### TC-P10: View Role Details

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to show page for a role: `GET /timetable-foundation/teacher-assignment-role/{id}` | HTTP 200; detail table with all fields displayed: Code, Name, Description, Is Primary Instructor (Yes/No badge), Counts for Workload (Yes/No), Allows Overlap (Yes/No), Workload Factor, Ordinal, Is System (Yes/No), Status (Active/Inactive), Created, Updated |
| 2 | Verify Edit button present | Link to edit route visible |
| 3 | Verify Back button present | Link to `timetableMasters?tab=teacher-roles` visible |

#### TC-P11: Edit Role — Update Name and Flags

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to edit page for a non-system role: `GET /timetable-foundation/teacher-assignment-role/{id}/edit` | Form pre-filled with current data |
| 2 | Change name to `Updated Role` | — |
| 3 | Uncheck "Counts for Workload" | `workload_factor` input becomes disabled |
| 4 | Check "Allows Overlap" | — |
| 5 | Submit form | PUT request; redirect to tab; success flash message |
| 6 | Find the role in the list | Name updated to "Updated Role"; workload factor badge shows "0.00x"; "Workload" badge absent; "Overlap" badge present |

#### TC-P12: Toggle Active Status via AJAX

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Identify an inactive non-system role | — |
| 2 | Click the status toggle switch for that role | AJAX POST to `toggle-status` endpoint with `is_active=true` |
| 3 | Verify response | JSON `{"success": true, "is_active": true, "message": "..."}` |
| 4 | Verify UI updates | Status badge changes to "Active" (green); list reflects new active state upon reload |

#### TC-P13: Soft Delete Non-System Role

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click delete (trash icon) on a non-system role (e.g. `TEST_PRIMARY`) | DELETE request to destroy route |
| 2 | Verify redirect | Redirect to `timetableMasters?tab=teacher-roles` |
| 3 | Verify flash | Success flash message displayed |
| 4 | Verify role absent from main list | `TEST_PRIMARY` not in accordion list |
| 5 | Query DB directly | `deleted_at` populated; `is_active=0` |

#### TC-P14: Trash View Loads Soft-Deleted Roles

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to trash view: `GET /timetable-foundation/teacher-assignment-role/trash/view` | HTTP 200; table with Role, Code, Workload, Behavior, Status, Action columns |
| 2 | Verify deleted role appears | `TEST_PRIMARY` listed with: name, code `TEST_PRIMARY`, workload "Ignored" badge, behavior "Secondary" badge, status "Inactive" badge, restore and force-delete action icons |

#### TC-P15: Restore Role from Trash

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | On trash view, click restore (undo icon) for `TEST_PRIMARY` | GET request to restore route |
| 2 | Verify redirect | Redirect to trash view |
| 3 | Verify flash | Success flash message displayed |
| 4 | Navigate to main teacher roles tab | `TEST_PRIMARY` reappears in accordion list; role is active |
| 5 | Query DB directly | `deleted_at` null; `is_active=1` |

#### TC-P16: Force Delete Role from Trash

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft delete a non-system role (e.g. `TEST_MIN`) | — |
| 2 | Navigate to trash view | Role visible in trash |
| 3 | Click force delete (X icon) for `TEST_MIN` | DELETE request to force-delete route |
| 4 | Verify redirect | Redirect to trash view |
| 5 | Verify flash | Success flash message displayed |
| 6 | Verify role absent from trash and main list | Role permanently removed |
| 7 | Query DB directly | Role record does not exist |

#### TC-P17: Business Rule — counts_for_workload Forces workload_factor

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create role with `code=WL_TEST`, `name=Workload Test`, `workload_factor=2.00`, `ordinal=20`, uncheck "Counts for Workload" | — |
| 2 | Submit and inspect the created role | `workload_factor` stored as 0 (not 2.00); workload badge shows "0.00x"; "Workload" badge absent |
| 3 | Edit the role, check "Counts for Workload", set `workload_factor=1.50` | — |
| 4 | Submit and inspect | `workload_factor` stored as 1.50; "Workload" badge present |

#### TC-P18: Business Rule — is_primary_instructor Forces allows_overlap

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create role with `code=PO_TEST`, `name=Primary Overlap Test`, `workload_factor=1.00`, `ordinal=25`, check "Primary Instructor", check "Allows Overlap" | — |
| 2 | Submit and inspect the created role | `allows_overlap` stored as false (overridden); no "Overlap" badge; primary instructor star icon present |
| 3 | Edit the role, uncheck "Primary Instructor", check "Allows Overlap" | — |
| 4 | Submit and inspect | `allows_overlap` stored as true; "Overlap" badge appears; primary instructor star absent |

---

### 7.2 Negative TC Steps

#### TC-N01: Missing Required Fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to create form | — |
| 2 | Leave code, name, workload_factor, ordinal blank | — |
| 3 | Submit form | Validation errors: "The code field is required.", "The name field is required.", "The workload factor field is required.", "The ordinal field is required."; form not submitted |

#### TC-N02: Duplicate Code

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create role with `code=DUPLICATE`, `name=First Duplicate`, `workload_factor=1.00`, `ordinal=1` | Created successfully |
| 2 | Create another role with `code=DUPLICATE` | Validation error: "The code has already been taken." |

#### TC-N03: Invalid Code Format

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create role with `code=invalid!` (lowercase + special char) | Validation error: code format invalid (regex `/^[A-Z0-9_]+$/`) |
| 2 | Create role with `code=lowercase` | Same validation error |
| 3 | Create role with `code=VALID_CODE` | Accepted (uppercase + underscore) |

#### TC-N04: Workload Factor Out of Range

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create role with `workload_factor=-1` | Validation error: "The workload factor must be at least 0." |
| 2 | Create role with `workload_factor=10` | Validation error: "The workload factor must not be greater than 9.99." |

#### TC-N05: Ordinal Less Than 1

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create role with `ordinal=0` | Validation error: "The ordinal must be at least 1." |

#### TC-N06: Update System Role — Blocked

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to edit page for PRIMARY (system role) | Form loads; code field is disabled with note "System role code cannot be modified." |
| 2 | Change name to `Hacked Primary` | — |
| 3 | Submit form | Redirect back to edit page; error flash message `system_record_update_not_allowed`; DB unchanged |

#### TC-N07: Delete System Role — Blocked

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click delete on a system role (e.g. PRIMARY) | Redirect back; error flash message: "Cannot delete \"Primary Teacher\" — it is a system role."; record not deleted; DB `deleted_at` remains null |

#### TC-N08: Toggle Status on System Role — 403

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click the status toggle on a system role (e.g. PRIMARY) | AJAX POST to toggle-status; response: HTTP 403, JSON `{"success": false, "is_active": true, "message": "..."}`; role remains active |

#### TC-N09: Force Delete System Role — Blocked

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft delete a system role is also blocked (see TC-N07), so for this test note the system protection applies to all delete paths | On attempt to access force-delete for a system role: redirect back with error flash `system_record_force_delete_not_allowed` |

#### TC-N10: Guest Access Redirect

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Log out | — |
| 2 | Navigate to `GET /timetable-foundation/teacher-assignment-role/create` | Redirected to `/login` |

#### TC-N11: Missing viewAny Permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Log in as user without `viewAny` permission | — |
| 2 | Navigate to teacher roles tab | 403 Forbidden or redirect with error |

#### TC-N12: Missing create Permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Log in as user without `create` permission | — |
| 2 | Navigate to create form or POST store | 403 Forbidden |

#### TC-N13: Non-Existent Role ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to `GET /timetable-foundation/teacher-assignment-role/9999` | HTTP 404 |
| 2 | Navigate to edit for ID 9999 | HTTP 404 |
| 3 | POST to update with ID 9999 | HTTP 404 |

---

### 7.3 Dependency TC Steps

#### TC-D01: FK RESTRICT — ActivityTeacher Exists

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Identify a role that has `ActivityTeacher` records referencing it (or create an activity and assign a teacher with this role) | — |
| 2 | Attempt to delete this role via the UI | Delete fails; integrity constraint violation logged; user sees an error (DB-level RESTRICT prevents deletion) |

#### TC-D02: FK RESTRICT — TimetableCellTeacher Exists

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Identify a role that has `TimetableCellTeacher` records referencing it | — |
| 2 | Attempt to delete this role via the UI | Delete fails; integrity constraint violation logged; RESTRICT prevents deletion |

#### TC-D03: Activity Logging on State Changes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a new role | Activity log entry created: action 'Created', message 'Teacher assignment role was created.' |
| 2 | Edit and update the role | Activity log entry created: action 'Updated', message 'Teacher assignment role was updated.' |
| 3 | Toggle status of the role | Activity log entry created: action 'Toggled', message 'Teacher assignment role status was updated.' |
| 4 | Soft delete the role | Activity log entry created: action 'Trashed', message 'Teacher assignment role was deactivated and moved to trash.' |
| 5 | Restore the role | Activity log entry created: action 'Restored', message 'Teacher assignment role was restored successfully.' |
| 6 | Force delete the role | Activity log entry created: action 'Deleted', message 'Teacher assignment role was permanently deleted.' |

#### TC-D04: Model — `$fillable` Matches DDL Columns

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `TeacherAssignmentRole.php` `$fillable` array | Contains exactly: `code`, `name`, `description`, `is_primary_instructor`, `counts_for_workload`, `allows_overlap`, `workload_factor`, `ordinal`, `is_system`, `is_active` — matching all DDL columns (excluding id, timestamps, deleted_at) |
| 2 | Verify no extra column exists in `$fillable` | Every fillable column is a real column in `tt_teacher_assignment_roles` |

#### TC-D05: Model — `$casts` for Boolean/Decimal/Integer/Datetime

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `TeacherAssignmentRole.php` `$casts` array | `is_primary_instructor` → `boolean`, `counts_for_workload` → `boolean`, `allows_overlap` → `boolean`, `is_system` → `boolean`, `is_active` → `boolean`, `ordinal` → `integer`, `workload_factor` → `decimal:2`, `created_at` → `datetime`, `updated_at` → `datetime`, `deleted_at` → `datetime` |

#### TC-D06: Unique Code Constraint at DB Level

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Insert a duplicate code directly into `tt_teacher_assignment_roles` via SQL: `INSERT INTO tt_teacher_assignment_roles (code, name, workload_factor, ordinal) VALUES ('PRIMARY', 'Duplicate', 1.00, 99)` | SQL error: `SQLSTATE[23000]: Integrity constraint violation` — duplicate entry for key `uq_tarole_code` |

---
