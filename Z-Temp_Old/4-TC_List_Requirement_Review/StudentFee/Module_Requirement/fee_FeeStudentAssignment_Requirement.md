# Fee Student Assignment — Business Requirements

## What This Screen Does

The Fee Student Assignment screen links an active student to a fee structure for the current academic session. It is the bridge between the fee catalog (heads, groups, and structures) and individual students, producing the total fee amount that billing and invoices will use. The screen supports both single-student assignment and one-click bulk generation for every active student in the current session whose class has an active fee structure.

Administrators can also maintain the assignment over time: edit it, change the attached fee structure, toggle active status, soft-delete it, restore it from trash, or permanently remove it. Mid-year joiners can be flagged with a prorated start date and percentage, although the stored total is taken directly from the chosen structure (the proration calculation is not applied in the current code).

---

## When This Screen Is Used

- A new academic session starts and the school must attach a fee structure to every enrolled student before invoicing.
- A single student joins the school mid-year and needs a prorated fee assignment.
- A student changes class or section and the fee structure attached to the assignment needs to be switched.
- An administrator wants to opt a student in or out of optional fee heads or groups.
- A previously deleted assignment must be restored, or an incorrect assignment must be deactivated.
- Billing reports that an assignment is missing for a student and the cashier must create it manually.

---

## Default Data Load

The screen is loaded by `StudentFeeManagementController::assignment()` at `GET /student-fee/assignment` (route name `student-fee.assignment`). The gate `tenant.student-fee-management.viewAny` is checked before any data is fetched.

The controller loads `FeeStudentAssignment` with eager-loaded relations `student.user`, `class`, `section`, and `feeStructure`. If a current academic session exists, results are filtered to that session. The query supports `search` (student name or admission number) and `status` (active/inactive) parameters. The grid is paginated at 12 records per page using the default `page` query parameter. The view also receives `totalAssignmentsCount` for the statistics card and `currentSession` for the session banner.

---

## Key Fields at a Glance

**Identity and Tracking**

- `Student` — The student who receives the fee structure. Displayed as the user's name plus admission number.
- `Class / Section` — The class and section the student is assigned to at the time the assignment is created; stored directly on the row to avoid joins during invoice calculation.
- `Academic Session` — The session for which the fee applies; assignments are unique per `student_id + academic_session_id`.
- `Fee Structure` — The chosen `fee_structure_master` record that defines the heads, groups, and total amount.
- `Assignment Date` — The effective date of the assignment, defaulting to today.

**Automation Triggers and Financial Fields**

- `Total Fee Amount` — The amount used for billing; populated from the selected fee structure on create and from the update request on edit. The model casts it to `decimal:2`.
- `Opted Heads / Opted Groups` — JSON arrays stored as text; they capture optional head IDs and group IDs selected for this student. The model casts both to `array`.
- `Join in Mid-Year` — Boolean flag indicating a student joined after the session started. When enabled, `fee_start_date` and `proration_percentage` become required.
- `Fee Start Date` — The first date from which the prorated fee applies.
- `Proration Percentage` — A 0–100 percentage intended for mid-year fee reduction.
- `Is Active` — Boolean status flag that can be toggled independently of the soft-delete state.

---

## Business Rules and Conditions

**One Active Assignment per Student per Session**

The system must prevent a student from having more than one assignment for the same academic session. The controller checks `FeeStudentAssignment::where('student_id', …)->where('academic_session_id', …)->exists()` before creating, and the database enforces a unique index on `(student_id, academic_session_id)`.

**Fee Structure Must Belong to the Selected Session**

During manual creation, the controller fetches the selected `FeeStructureMaster` and rejects the request if `structure.academic_session_id` does not match the submitted `academic_session_id`. The error message is: `Selected fee structure does not belong to the selected academic session.`

**Bulk Generation is Session-Scoped and Idempotent**

`generateStudentAssignment()` runs only for the current academic session and only for student sessions with `session_status_id = 1`. It skips students who already have an assignment (including trashed ones, which are restored and updated instead of recreated). The flash message reports counts: `Fee assignments: N created, M updated. X skipped (no class section or no active fee structure).`

**Total Fee Amount Comes from the Structure on Create**

On manual creation, `total_fee_amount` is always taken from the selected fee structure, not from any submitted value. Proration fields are stored but are not used to reduce the amount in the current implementation.

**Soft Delete with Restore and Force Delete**

Deleting deactivates the record (`is_active = false`) before soft-deleting it. Restoring reactivates it (`is_active = true`). Force delete permanently removes the row. Invoices referencing the assignment are blocked by a `RESTRICT` foreign key; concessions referencing it cascade.

---

## Workflow Steps

**Creating a Single Assignment**

1. Open the Assignment tab (`GET /student-fee/assignment`).
2. Click **Create Assignment** (`GET /student-fee/fee-student-assignment/create`).
3. Select a Class; the Section dropdown is filtered client-side by the class-section map.
4. Select a Student, the current Academic Session (read-only), and a Fee Structure.
5. Choose an Assignment Date and Status (default Active).
6. Optionally enable **Join in Mid-Year** and enter `Fee Start Date` and `Proration Percentage`.
7. Optionally enter `Opted Heads` and `Opted Groups` as JSON arrays.
8. Submit the form. The controller validates, checks for duplicates, verifies the structure belongs to the session, stores the assignment, writes an activity log, and redirects to the detail page.

**Bulk Generation**

1. From the Assignment tab, click **Generate** in the **Generate Structures** banner (`POST /student-fee/fee-student-assignment/generate/all`).
2. The controller iterates active `StudentAcademicSession` records for the current session, finds a matching active `FeeStructureMaster` by `class_id` and `academic_session_id`, and creates or updates an assignment for each student.
3. A flash message reports how many were created and updated, and how many were skipped.

**Updating a Structure on an Existing Assignment**

1. Open an assignment detail page and click **Edit**.
2. Submit the **Update Assignment** form, or use the `PATCH /student-fee/fee-student-assignment/{id}/update-structure` route to change only the fee structure and recalculate the total from the new structure.

**Deleting, Restoring, and Force Deleting**

1. From the list or card view, click **Delete** to deactivate and soft-delete the assignment.
2. Open the trash view (`GET /student-fee/fee-student-assignment/trash/view`), click **Restore** to reactivate it, or **Force Delete** to remove it permanently.

---

## Example Scenario

**Actors:** Aditi (fee administrator), Rohan (new student joining Class 5-A in March).

1. The school has set 2025–26 as the current academic session and created a `Class 5 - Annual` fee structure with `total_fee_amount = 45,000` for that session.
2. Rohan is admitted in March. Aditi opens the Fee Student Assignment tab and clicks **Create Assignment**.
3. She selects Class 5, Section A, Rohan as the student, and the `Class 5 - Annual` structure. The assignment date is set to 15 March 2026.
4. Aditi checks **Join in Mid-Year**, sets `Fee Start Date` to 1 March 2026, and sets `Proration Percentage` to 50.00. The system saves the assignment with `total_fee_amount = 45,000` (the full structure amount in the current code) but records the proration fields for reporting.
5. She clicks **Generate** to bulk-create assignments for all other Class 5 students; the system reports `20 created, 0 updated, 3 skipped`.
6. Later, Rohan moves to Section B. Aditi opens the assignment, changes the section, and saves. The total remains 45,000.
7. If Rohan withdraws, Aditi clicks **Delete**; the record is deactivated and moved to trash, and any invoice tied to it cannot be force-deleted because of the `RESTRICT` foreign key.

---

## Related Screens

- **Assignment Tab (`student-fee.assignment`)** — Parent view that hosts this feature.
- **Configuration Tab (`student-fee.configuration`)** — Defines fee heads, groups, and structures consumed by assignments.
- **Billing Tab (`student-fee.billing`)** — Generates invoices from `fee_student_assignments`.
- **Payment Tab (`student-fee.payment`)** — Records transactions against students who have assignments.
- **Student Concession (`fee-student-concession`)** — Applies concessions to a student assignment; cascades when the assignment is deleted.
- **Trash (`fee-student-assignment.trashed`)** — Lists soft-deleted assignments and allows restore or force delete.

---

## Requirements

- The system MUST load the assignment screen through `StudentFeeManagementController::assignment()` at `GET /student-fee/assignment`, gated by `tenant.student-fee-management.viewAny`.
- The system MUST redirect `GET /student-fee/fee-student-assignment` to `student-fee.assignment` via `FeeStudentAssignmentController::index()`.
- The system MUST enforce the following gates via `FeeStudentAssignmentPolicy`:
  - `tenant.fee-student-assignment.create` for `create()`, `store()`, and `generateStudentAssignment()`.
  - `tenant.fee-student-assignment.view` for `show()`.
  - `tenant.fee-student-assignment.update` for `edit()`, `update()`, and `updateAssignmentStructure()`.
  - `tenant.fee-student-assignment.delete` for `destroy()`.
  - `tenant.fee-student-assignment.restore` for `trashedFeeStudentAssignments()` and `restore()`.
  - `tenant.fee-student-assignment.forceDelete` for `forceDelete()`.
  - `tenant.fee-student-assignment.status` for `toggleStatus()`.
- The system MUST validate manual create requests with `StoreFeeStudentAssignmentRequest` and update requests with `UpdateFeeStudentAssignmentRequest`.
- The system MUST validate structure-only updates with `UpdateFeeAssignmentStructureRequest`.
- The system MUST prevent duplicate assignments for the same `student_id + academic_session_id` in `store()`.
- The system MUST verify that the selected `fee_structure_id` belongs to the submitted `academic_session_id` in `store()`.
- The system MUST take `total_fee_amount` from the fee structure on create; the `UpdateFeeStudentAssignmentRequest` requires `total_fee_amount` on update.
- The system MUST store `opted_heads` and `opted_groups` as JSON arrays parsed from the request strings, and reject invalid JSON with a controller-level error.
- The system MUST support mid-year join flags (`join_in_mid-year`, `fee_start_date`, `proration_percentage`) as conditional fields.
- The system MUST bulk-generate assignments for all active student sessions of the current academic session via `POST /student-fee/fee-student-assignment/generate/all`.
- The system MUST soft-delete assignments with `FeeStudentAssignment` using the `SoftDeletes` trait; `destroy()` sets `is_active = false` first, and `restore()` sets `is_active = true`.
- The system MUST log activity for create, update, delete, restore, toggle, generate, and structure-update events using `activityLog()`.
- The system MUST expose `GET /student-fee/fee-student-assignment/sections-by-class/{classId}` for class→section AJAX filtering in the create and edit forms.
- The system MUST paginate the assignment grid at 12 records per page and preserve the `search` and `status` query strings.

---

## Who Can Access

| Gate / Permission | Methods | Notes |
|---|---|---|
| `tenant.student-fee-management.viewAny` | `StudentFeeManagementController::assignment()` | Required to open the Assignment tab. |
| `tenant.fee-student-assignment.create` | `create()`, `store()`, `generateStudentAssignment()` | Also covers bulk generation. |
| `tenant.fee-student-assignment.view` | `show()` | Detail view. |
| `tenant.fee-student-assignment.update` | `edit()`, `update()`, `updateAssignmentStructure()` | Structure update uses `PATCH` route. |
| `tenant.fee-student-assignment.delete` | `destroy()` | Deactivates before soft delete. |
| `tenant.fee-student-assignment.restore` | `trashedFeeStudentAssignments()`, `restore()` | Trash view and restore. |
| `tenant.fee-student-assignment.forceDelete` | `forceDelete()` | Permanent removal. |
| `tenant.fee-student-assignment.status` | `toggleStatus()` | JSON response. |
| `FeeStudentAssignmentPolicy` | All policy methods | The policy also defines `viewAny`, `import`, `export`, `print`, `emailSchedule`, `remark`, and `pdf`, but these are not invoked by the controller. |

---

## Logic Flow

**1. Page Load**

`StudentFeeManagementController::assignment()` checks `tenant.student-fee-management.viewAny`, resolves the current academic session, builds a query with optional `search` and `status` filters, paginates 12 records, and renders `assignment.blade.php` which includes `fee-student-assignment/index.blade.php`.

**2. Create Load**

`FeeStudentAssignmentController::create()` checks `tenant.fee-student-assignment.create`. If no current academic session exists, it redirects with error `No active academic session found. Please set a current session first.`. Otherwise it loads active students, active class-section mappings, and active fee structures for the current session, then renders the create form.

**3. Store Assignment**

`store()` checks the create gate, validates via `StoreFeeStudentAssignmentRequest`, checks for an existing assignment, fetches the fee structure, rejects if the structure's session differs, starts a transaction, parses `opted_heads` and `opted_groups` from JSON strings, creates the record with `total_fee_amount` from the structure, logs activity, commits, and redirects to `student-fee.fee-student-assignment.show` with message `Fee assignment created successfully.` On any exception it rolls back and returns `Creation failed. Please try again.`

**4. Edit / Update**

`edit()` checks the update gate, loads the assignment with relations, and renders the edit form. `update()` validates via `UpdateFeeStudentAssignmentRequest`, parses opted arrays, updates all fields including the manually supplied `total_fee_amount`, logs activity, commits, and redirects to the show route. On exception it rolls back and returns `Update failed: <message>`.

**5. Show / Delete / Restore / Force Delete**

`show()` checks the view gate and loads `student.user` and `feeStructure`. `destroy()` checks the delete gate, deactivates (`is_active = false`), soft-deletes, and logs `Trashed`. `restore()` checks the restore gate, restores, reactivates (`is_active = true`), and logs `Restored`. `forceDelete()` checks the force-delete gate and permanently removes the row, logging `Deleted`.

**6. Toggle Status**

`toggleStatus()` validates via `ToggleStatusRequest`, flips `is_active`, saves, and returns a JSON success object `{success: true, is_active: <new_status>, message: flash('status_updated.fee_student_assignment')}`. On save failure returns `{success: false, is_active: <current>, message: flash('status_switch_failed.fee_student_assignment')}`.

**7. Bulk Generate**

`generateStudentAssignment()` checks the create gate, resolves the current session, iterates active student sessions (`session_status_id = 1`), matches a fee structure by class and session (`FeeStructureMaster::where('class_id', $classId)->where('academic_session_id', $currentActiveSession->id)->where('is_active', true)->first()`), and either creates a new assignment or restores and updates an existing one. It reports counts and skips students whose class has no active structure or no class-section mapping.

**8. AJAX Section Lookup**

`getSectionsByClass($classId)` returns a JSON array of `{id, name}` sections for the given class via the `ClassSection` relation; no gate is applied.

**9. Update Assignment Structure (PATCH)**

`updateAssignmentStructure()` checks the update gate, validates via `UpdateFeeAssignmentStructureRequest`, fetches the new `FeeStructureMaster`, and updates `fee_structure_id` and `total_fee_amount` on the assignment. Logs `Updated` and redirects with `Fee structure updated successfully.`

---

## Validate Before Save

### Store — `StoreFeeStudentAssignmentRequest`

| Field | Rule(s) | Error Message |
|---|---|---|
| `student_id` | `required`, `integer`, `exists:std_students,id` | Laravel default: "The student id field is required." / "The selected student id is invalid." |
| `class_id` | `required`, `integer`, `exists:sch_classes,id` | Laravel default required/invalid messages. |
| `section_id` | `nullable`, `integer`, `exists:sch_sections,id` | Laravel default invalid messages. |
| `academic_session_id` | `required`, `integer` | Laravel default required/integer messages. |
| `fee_structure_id` | `required`, `integer`, `exists:fee_structure_master,id` | Laravel default required/invalid messages. |
| `assignment_date` | `required`, `date` | Laravel default required/date messages. |
| `is_active` | `required`, `boolean` | Laravel default required/boolean messages. |
| `opted_heads` | `nullable` | Laravel default messages. |
| `opted_groups` | `nullable` | Laravel default messages. |
| `join_in_mid_year` | `nullable`, `boolean` | Laravel default boolean messages. |
| `fee_start_date` | `required_if:join_in_mid_year,1`, `nullable`, `date` | Laravel default required_if/date messages. |
| `proration_percentage` | `required_if:join_in_mid_year,1`, `nullable`, `numeric`, `min:0`, `max:100` | Laravel default numeric/min/max messages. |

### Update — `UpdateFeeStudentAssignmentRequest`

| Field | Rule(s) | Error Message |
|---|---|---|
| `class_id` | `required`, `integer`, `exists:sch_classes,id` | Laravel default required/invalid messages. |
| `section_id` | `nullable`, `integer`, `exists:sch_sections,id` | Laravel default invalid messages. |
| `fee_structure_id` | `required`, `integer`, `exists:fee_structure_master,id` | Laravel default required/invalid messages. |
| `total_fee_amount` | `required`, `numeric`, `min:0` | Laravel default required/numeric/min messages. |
| `assignment_date` | `required`, `date` | Laravel default required/date messages. |
| `is_active` | `required`, `boolean` | Laravel default required/boolean messages. |
| `opted_heads` | `nullable` | Laravel default messages. |
| `opted_groups` | `nullable` | Laravel default messages. |
| `join_in_mid_year` | `nullable`, `boolean` | Laravel default boolean messages. |
| `fee_start_date` | `required_if:join_in_mid_year,1`, `nullable`, `date` | Laravel default required_if/date messages. |
| `proration_percentage` | `required_if:join_in_mid_year,1`, `nullable`, `numeric`, `min:0`, `max:100` | Laravel default numeric/min/max messages. |

### Update Structure Only — `UpdateFeeAssignmentStructureRequest`

| Field | Rule(s) | Error Message |
|---|---|---|
| `fee_structure_id` | `required`, `integer`, `exists:fee_structure_master,id` | Laravel default required/invalid messages. |

### Controller-Level Checks

| Check | Error Message |
|---|---|
| Duplicate assignment for same `student_id + academic_session_id` | `Student assignment already exists for this academic session.` |
| Selected fee structure does not belong to the selected academic session | `Selected fee structure does not belong to the selected academic session.` |
| Invalid `opted_heads` JSON during update | `Invalid JSON format for opted heads.` |
| Invalid `opted_groups` JSON during update | `Invalid JSON format for opted groups.` |
| Any exception during store | `Creation failed. Please try again.` (with rollback) |
| Any exception during update | `Update failed: <exception message>` (with rollback) |
| No current academic session on create | `No active academic session found. Please set a current session first.` |

---

## Error Handling and Validation Messages

| Scenario | Message | Type |
|---|---|---|
| No current academic session on create/generate | `No active academic session found. Please set a current session first.` | Controller check (redirect with error) |
| Duplicate assignment on store | `Student assignment already exists for this academic session.` | Controller check (redirect with error) |
| Fee structure from a different session on store | `Selected fee structure does not belong to the selected academic session.` | Controller check (redirect with error) |
| Invalid `opted_heads` JSON on update | `Invalid JSON format for opted heads.` | Controller validation error (redirect with errors) |
| Invalid `opted_groups` JSON on update | `Invalid JSON format for opted groups.` | Controller validation error (redirect with errors) |
| Any exception during store | `Creation failed. Please try again.` | Controller catch (redirect with error) |
| Any exception during update | `Update failed: <exception message>` | Controller catch (redirect with error) |
| Validation fails on form request | Laravel default messages (e.g., `The student id field is required.`) | Validation rule |
| Missing permission | HTTP 403 Forbidden | Gate authorization |
| Guest access | Redirect to `/login` | Authentication middleware |
| Missing record on show/edit/update/destroy/restore/forceDelete | HTTP 404 Not Found | Route model binding or `findOrFail` |

---

## Success Scenarios

**SC-001 — Create a single assignment for a new student**

Administrator selects Class 5, Section A, student Rohan (admission 2025-045), fee structure `Class 5 - Annual` (₹45,000), assignment date 15 March 2026, and leaves mid-year unchecked. The system creates the assignment with `total_fee_amount = 45000.00` from the structure, logs `Created`, and redirects to the detail page with `Fee assignment created successfully.`

**SC-002 — Bulk generate assignments for the current session**

The current session is 2025–26. There are 25 active student sessions and active fee structures for Classes 5, 6, and 7. After clicking **Generate**, the system creates 22 assignments, updates 2 existing/trashed assignments, and skips 1 student whose class has no active structure. The flash message reports `Fee assignments: 22 created, 2 updated. 1 skipped (no class section or no active fee structure).`

**SC-003 — Update an assignment's fee structure**

An existing assignment for student Ananya is switched from `Class 5 - Annual` to `Class 5 - Quarterly` (₹12,000). Using `PATCH /student-fee/fee-student-assignment/{id}/update-structure`, the system sets `fee_structure_id` to the new structure and `total_fee_amount` to `12000.00`, then redirects to the detail page with `Fee structure updated successfully.`

**SC-004 — Restore a deleted assignment**

An administrator opens the trash, finds a deleted assignment for student Kabir, and clicks **Restore**. The system restores the row, sets `is_active = true`, logs `Restored`, and redirects to the trash view with `restored.fee_student_assignment`.

**SC-005 — Toggle assignment status**

From the card view, the administrator toggles an active assignment off. The system flips `is_active` to `false`, saves, logs `Toggled`, and returns JSON `{success: true, is_active: false, message: flash('status_updated.fee_student_assignment')}`.

**SC-006 — AJAX section lookup**

On the create form, the administrator selects Class 5. The section dropdown is populated via `GET /student-fee/fee-student-assignment/sections-by-class/5`, returning `[{"id": 1, "name": "A"}, {"id": 2, "name": "B"}]`.

---

## Failure Scenarios

**FC-001 — Duplicate assignment on create**

Administrator tries to create a second assignment for student Rohan in session 2025–26. The controller detects the existing record and redirects back with `Student assignment already exists for this academic session.`

**FC-002 — Fee structure from a different session**

Administrator selects a fee structure defined for session 2024–25 while the academic session is 2025–26. The controller rejects the request with `Selected fee structure does not belong to the selected academic session.`

**FC-003 — Missing required field on create**

The form is submitted without a student. `StoreFeeStudentAssignmentRequest` fails and returns `The student id field is required.`

**FC-004 — Mid-year proration missing required fields**

The administrator checks **Join in Mid-Year** but leaves `fee_start_date` empty. `StoreFeeStudentAssignmentRequest` returns `The fee start date field is required when join in mid year is 1.`

**FC-005 — Force delete blocked by existing invoice**

An administrator force-deletes an assignment that has a related `fee_invoices` row. The database `RESTRICT` foreign key (`fk_finv_assignment`) raises an integrity error and the deletion fails.

**FC-006 — Unauthorized access to create**

A user without `tenant.fee-student-assignment.create` opens the create route. The `Gate::authorize` call returns 403.

**FC-007 — Invalid JSON in opted heads on update**

The administrator enters `{bad json` in the opted heads textarea and submits the update form. The controller rejects with `Invalid JSON format for opted heads.`

---

## Dependencies module and tables

> **Note:** The input requirement states that `total_fee_amount` is recomputed from `proration_percentage` when mid-year join is enabled. The current code does not apply this calculation; it stores the full fee structure amount on create and uses the submitted `total_fee_amount` on update. This is a code↔requirement discrepancy.
>
> **Note:** The input requirement describes optional heads and groups as checkboxes. The current create and edit views expose `opted_heads` and `opted_groups` as JSON textareas, not as checkboxes. This is a UI/UX discrepancy.
>
> **Note:** The `_search-bar.blade.php` partial under `fee-student-assignment/_partials/` contains fields (`has_group`, "Notification / Group") that are not used by the rendered search bar in `index.blade.php`. The actual search filters by student name/admission number and status only. This partial appears stale.
>
> **Note:** The form request and view use the field name `join_in_mid_year` (underscore), while the database column is named `join_in_mid-year` (hyphen). The controller maps the request field to the column correctly, but this naming inconsistency is a maintenance risk.

| Dependency | Type | Details |
|---|---|---|
| `std_students` | FK parent | `student_id` references `std_students.id` with `ON DELETE CASCADE` |
| `sch_classes` | FK parent | `class_id` references `sch_classes.id` with `ON DELETE RESTRICT` |
| `sch_sections` | FK parent | `section_id` references `sch_sections.id` with `ON DELETE RESTRICT` |
| `sch_org_academic_sessions_jnt` | FK parent | `academic_session_id` references `sch_org_academic_sessions_jnt.id` with `ON DELETE RESTRICT` |
| `fee_structure_master` | FK parent | `fee_structure_id` references `fee_structure_master.id` with `ON DELETE RESTRICT` |
| `fee_invoices` | FK child | `student_assignment_id` references `fee_student_assignments.id` with `ON DELETE RESTRICT` — blocks assignment force delete if invoices exist |
| `fee_student_concessions` | FK child | `student_assignment_id` references `fee_student_assignments.id` with `ON DELETE CASCADE` |
| `Student` | Cross-module consumer | `Modules\StudentProfile\Models\Student` loaded via `student()` relation |
| `SchoolClass` / `Section` | Cross-module consumer | `Modules\SchoolSetup\Models\SchoolClass` and `Section` loaded via `class()` / `section()` |
| `AcademicSession` | Cross-module consumer | `Modules\Prime\Models\AcademicSession` loaded via `academicSession()` and used for current session resolution |
| `FeeStructureMaster` | Same module | `feeStructure()` belongsTo relation |
| `FeeInvoice` / `FeeStudentConcession` | Same module | `invoices()` and `concessions()` hasMany relations |
| `ClassSection` | Cross-module consumer | Used for class→section AJAX mapping and bulk generation |
| `StudentAcademicSession` | Cross-module consumer | Used for bulk generation source data |
| Activity log | Service | `activityLog()` called on create, update, delete, restore, toggle, generate, and structure-update |
| Soft deletes | Trait | `Illuminate\Database\Eloquent\SoftDeletes` used on `FeeStudentAssignment` |

**Table:** `fee_student_assignments`

| Column | Type | Details |
|---|---|---|
| `id` | INT UNSIGNED | Auto-increment primary key |
| `student_id` | INT UNSIGNED NOT NULL | FK → `std_students.id` ON DELETE CASCADE |
| `class_id` | INT UNSIGNED NOT NULL | FK → `sch_classes.id` ON DELETE RESTRICT |
| `section_id` | INT UNSIGNED NULL | FK → `sch_sections.id` ON DELETE RESTRICT |
| `academic_session_id` | SMALLINT UNSIGNED NOT NULL | FK → `sch_org_academic_sessions_jnt.id` ON DELETE RESTRICT |
| `fee_structure_id` | INT UNSIGNED NOT NULL | FK → `fee_structure_master.id` ON DELETE RESTRICT |
| `total_fee_amount` | DECIMAL(12,2) NOT NULL | Stored billing amount |
| `opted_heads` | JSON NULL | Selected optional heads |
| `opted_groups` | JSON NULL | Selected optional groups |
| `assignment_date` | DATE NOT NULL | Effective assignment date |
| `join_in_mid-year` | TINYINT(1) NOT NULL DEFAULT 0 | Mid-year join flag |
| `fee_start_date` | DATE NULL | Actual fee start date for mid-year joins |
| `proration_percentage` | DECIMAL(5,2) NULL | Percentage of total fee applicable |
| `is_active` | TINYINT(1) NOT NULL DEFAULT 1 | Status flag |
| `created_at` | TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP | Standard Laravel timestamp |
| `updated_at` | TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP | Standard Laravel timestamp |
| `deleted_at` | TIMESTAMP NULL | Soft-delete timestamp |
| UNIQUE KEY `uq_fee_student_session` | (`student_id`, `academic_session_id`) | Prevents duplicate active assignments per student/session |
| INDEX `idx_fee_assignment_active` | (`is_active`) | Active-status filter index |
