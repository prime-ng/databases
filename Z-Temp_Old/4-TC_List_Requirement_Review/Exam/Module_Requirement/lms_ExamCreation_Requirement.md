# Exam Creation — Business Requirements

## What This Screen Does

The Exam Creation screen is the central entity of the entire Exam module. It is where an administrator defines an exam event — for example, "Annual Exam 2025-26 for Class 10". An exam belongs to a specific **Academic Session**, **Class**, and **Exam Type** (e.g., UT-1, Half-Yearly, Annual). It has a date range, a status (Draft/Published/Concluded/Archived), and optional grading schema and result-publishing settings.

Once an exam is created, the admin proceeds to add **Exam Papers** (one per subject), **Paper Sets** (variants of each paper), **Scopes** (lessons/topics covered), **Blueprints** (section-wise structure), **Paper Set Questions** (the actual questions), and finally **Allocations** (assigning students to papers).

The exam creation screen is Tab 1 in the **Creation & Allocation** tab set (`lms-exam.creation-allocation.index`).

---

## When This Screen Is Used

- **New Exam Setup** — At the start of a new assessment cycle, the admin creates an exam for every combination of session, class, and exam type.
- **Exam Planning** — Before individual papers can be created, the overarching exam must exist.
- **Editing an Existing Exam** — If exam-level details (dates, title, status, grading schema) need to be changed before papers/allocations exist.
- **Publishing / Concluding** — The admin changes the exam status from DRAFT → PUBLISHED → CONCLUDED → ARCHIVED as the exam lifecycle progresses.
- **Deleting / Trashing** — If the exam was created in error or is no longer needed.

---

## Default Data Load

This screen is the first sub-tab that opens inside the Creation & Allocation tab page (`lms-exam.creation-allocation.index` with `active_tab=exam`). When the page loads, the system asks:

**"Give me all exams, newest first, 10 records per page."**

It fetches from `lms_exams` table using the `ExamQueryService::examsQuery()` method. The list is paginated (10 rows per page). If the user has applied filters (search, status, exam type, class, date range, data type), those filters are applied.

If this is NOT the active tab, no exams are loaded — only data for the active tab is fetched.

---

## Key Fields at a Glance

**Exam Title**
A human-readable name like "Annual Examination 2025-26" (required, max 150 characters).

**Code**
Auto-generated unique code like `EXAM_2025_ANNUAL_CLASS10_ABC123`. The system generates it from session code + class code + exam type code + random string. The admin can also provide a custom code (max 50 chars, unique). If a duplicate code is detected on update, the system appends a random suffix.

**Academic Session**
The academic year this exam belongs to (e.g., "2025-26"). Required.

**Class**
The target class (e.g., "Class 10"). Required. Combined with academic session and exam type, this forms a unique constraint — you cannot create two exams with the same session + class + exam type.

**Exam Type**
The category of exam (e.g., "UT-1", "Half Yearly Exam", "Annual Exam"). Required. Only active exam types appear in the dropdown.

**Start Date / End Date**
The date range of the exam. Start must be before or equal to end date. Both required.

**Status**
The lifecycle stage of the exam. Options come from `lms_exam_status_events` filtered to `event_type='EXAM'`. Values like DRAFT, PUBLISHED, CONCLUDED, ARCHIVED.

**Result Publishing**
How results will be published: `IMMEDIATE` (auto-publish results), `MANUAL` (admin publishes), or `SCHEDULED` (publish at a scheduled datetime). If IMMEDIATE, `is_result_published` is set to true automatically (both on create and update). If SCHEDULED, `is_result_published` is explicitly set to false — but only during update, not during initial creation.

**Scheduled Result At**
If result publishing is SCHEDULED, the datetime when results will auto-publish.

**Grading Schema**
Optional. The grading schema (grade divisions like A+, A, B+) from `slb_grade_division_master`.

**Active Status**
Toggle to control whether this exam is active. Inactive exams are hidden from most dropdowns.

---

## Business Rules and Conditions

**Unique Combination**
An exam type can only be created once per academic session and class. The system enforces: `UNIQUE KEY uq_exam_session_class_type (academic_session_id, class_id, exam_type_id)`. If someone tries to create "Annual Exam 2025-26 for Class 10" when it already exists, validation rejects it: "This exam type already exists for the selected session and class."

**Auto-Generated Code**
If no code is provided, the system generates one using the pattern: `EXAM_<SESSION_CODE>_<CLASS_CODE>_<EXAM_TYPE_CODE>_<RANDOM6>`. If the generated code already exists, it appends a counter until unique. On update, the duplicate check only runs if the code was actually changed — if the code remains the same, no regeneration occurs.

**Usage Protection — Cannot Edit or Delete If In Use**
If an exam has any of the following, editing and deletion are blocked:
- Exam Papers created under it
- Allocations (students assigned)
- Student Attempts

The system checks this via `ExamUsageCheckService::isUsed()`. If used:
- Edit is blocked: "Cannot edit this exam because it has papers, allocations, or student attempts."
- Update is blocked: same message.
- Delete (soft) is blocked: same message.
- Restore is blocked: same message.
- Permanent delete is blocked: same message.

The status toggle (`toggleStatus`) is NOT blocked — you can activate/deactivate even if the exam is in use.

**Publication Validation (DV1-DV8)**
When updating an exam to PUBLISHED status, the system runs 8 validation checks (DV1-DV8):
- DV1: Each paper set must have questions
- DV2: Each paper set's total marks must match the paper's target marks
- DV3-DV4: Blueprint alignment — each section has the correct number and marks of questions
- DV5-DV6: Difficulty distribution — each complexity level has the minimum required questions (if difficulty config is set and not ignored)
- DV7: Scope coverage — each topic/lesson has its required questions
- DV8: Unique questions across randomized sets (informational only)

If any validation fails, the status update is rolled back with specific error messages.

**Soft Delete Behavior**
When soft-deleted: sets `is_active = 0` and sets `deleted_at` timestamp.

**Activity Logging**
Every action is logged: Stored, Updated (with old/new diff), Trashed, Restored, Deleted (permanent), Toggled.

---

## Workflow Steps

**Creating a New Exam**
1. Admin clicks "Add Exam" on the Creation & Allocation tab (active_tab=exam).
2. System opens the Create page (`lms-exam.exam.create`).
3. Admin fills in: title, academic session (only the current active session is shown), class, exam type, start date, end date, status, result publishing mode, grading schema (optional), description (optional).
4. Admin clicks "Create Exam".
5. System validates: required fields, date logic, unique combination, unique code.
6. If valid: creates record in `lms_exams`, generates UUID and code, sets `is_result_published` based on result_publishing mode (IMMEDIATE → true, others → false), auto-fills `created_by` with the current user's ID, logs activity, redirects back with success.
7. If invalid: shows validation errors.

**Editing an Existing Exam**
1. Admin clicks Edit button next to an exam.
2. System checks usage via `ExamUsageCheckService`. If used, blocks with error.
3. If not used, Edit page opens with pre-filled values.
4. Admin changes fields and clicks "Update Exam".
5. System re-checks usage, re-validates, saves with audit log, redirects.

**Changing Status (Publishing)**
1. Admin edits the exam and sets status to PUBLISHED.
2. System runs DV1-DV8 validation checks.
3. If checks pass: status updated, exam published.
4. If checks fail: update rolled back, specific errors shown.

**Deleting (Soft Delete / Trash)**
1. Admin clicks Delete button.
2. System checks usage — if used, blocks.
3. If not used: deactivates (`is_active=0`), soft-deletes (`deleted_at=now`), logs, redirects.

**Restoring from Trash**
1. Admin goes to Trash page.
2. Clicks Restore. System checks usage.
3. If not used: restores (`deleted_at=null`), reactivates (`is_active=1`), logs.

**Permanent Deletion**
1. From Trash page, admin clicks "Delete Forever".
2. System checks usage. If not used, permanently removes record from database.

---

## Example Scenario

Green Valley Academy is setting up exams for "2025-26" academic session. The admin creates:
- **Exam 1**: "Unit Test 1 - 2025-26 - Class 10" (Exam Type: UT-1, Status: DRAFT)
- **Exam 2**: "Half Yearly Exam - 2025-26 - Class 10" (Exam Type: HY-EXAM, Status: DRAFT)
- **Exam 3**: "Annual Exam - 2025-26 - Class 10" (Exam Type: ANNUAL-EXAM, Status: DRAFT)

After creating papers, sets, blueprints, and adding questions for Exam 1, the admin tries to publish it. The system runs DV1-DV8 checks and confirms everything is aligned. The exam status changes to PUBLISHED.

Later, the admin realizes they created a duplicate exam for Class 10. Since no papers or allocations exist, they can delete it safely.

---

## Related Screens

- **Exam Papers (Tab 2)** — Papers are created under an exam. The exam ID is a required FK in `lms_exam_papers`.
- **Exam Summary Dashboard** — Shows statistics across all exams (papers, allocations, attempts, evaluations).
- **Masters Tab** — Exam Types and Status Events are configured here and used by exam creation.

---

## Requirements

- **Controller**: `LmsExamController` — methods `index`, `create`, `store`, `show`, `edit`, `update`, `destroy`, `trashed`, `restore`, `forceDelete`, `toggleStatus`
- **Route group**: `lms-exam.*` — exam CRUD routes, plus `lms-exam.creation-allocation.index`
- **Model**: `Exam` (`Modules\LmsExam\Models\Exam`) — table `lms_exams`, uses SoftDeletes, has UUID auto-generation, automatic code generation
- **Form Request**: `ExamRequest` — validates academic_session_id (required), class_id (required, exists), exam_type_id (required, exists, unique per session+class), code (nullable, string, max:50, unique), title (required, string, max:150), description (nullable, string), start_date (required, date, before_or_equal:end_date), end_date (required, date, after_or_equal:start_date), scheduled_result_at (nullable, date, after_or_equal:start_date), result_published (nullable, in:IMMEDIATE,MANUAL,SCHEDULED), grading_schema_id (nullable, exists), status_id (required, exists), is_active (boolean), is_result_published (boolean)
- **Policy**: `ExamPolicy` with gates: `tenant.exam.viewAny`, `view`, `create`, `update`, `delete`, `restore`, `forceDelete`, `status`, `import`, `export`, `print`
- **Service**: `ExamUsageCheckService` — checks if exam is used in `lms_exam_papers`, `lms_exam_allocations`, or `lms_exam_attempts`; blocks edit/delete/restore/forceDelete if used
- **Service**: `ExamQueryService::examsQuery(Request)` — filters by search (code, title, description, class, exam type, status, creator), status_id, exam_type_id, class_id, date_range, data_type (status code), is_active; ordered by `latest()`
- **View path**: `lmsexam::exam/` — `create.blade.php`, `edit.blade.php`, `show.blade.php`, `trash.blade.php`; listed on `lmsexam::tab_module.creation_allocation`
- **Default page size**: 10 rows per page
- **Pagination**: Appends `active_tab=exam` to pagination links
- **destroy()**: sets `is_active = false` before `delete()`
- **restore()**: sets `is_active = true` after `restore()`
- **toggleStatus()**: AJAX endpoint, validates `is_active` boolean, toggles via save
- **Activity Log**: Logged on create, update (with old/new value diff), trash, restore, force-delete, toggle-status
- **Publication Validation**: `validateExamDifficulty()` runs DV1-DV8 checks when status changes to PUBLISHED

---

## Who Can Access

| Gate/Permission | Methods | Notes |
|----------------|---------|-------|
| `tenant.exam.viewAny` | `index()`, `creationAllocation()` | View the list of exams |
| `tenant.exam.view` | `show()` | View details of a single exam |
| `tenant.exam.create` | `create()`, `store()` | Open create form + save |
| `tenant.exam.update` | `edit()`, `update()`, `toggleStatus()` | Edit form + save + toggle active |
| `tenant.exam.delete` | `destroy()` | Soft-delete (trash) |
| `tenant.exam.restore` | `trashed()`, `restore()` | View trash + restore |
| `tenant.exam.forceDelete` | `forceDelete()` | Permanent delete from trash |
| `tenant.exam.status` | (used in Blade for toggle) | View/change active toggle |
| `tenant.exam.import` | (policy only) | Future use |
| `tenant.exam.export` | (policy only) | Future use |
| `tenant.exam.print` | (policy only) | Future use |

---

## Logic Flow (Non-Technical)

### Page Load
```
Step 1: User clicks Creation & Allocation tab → URL has active_tab=exam
Step 2: System asks → "Is the user allowed to view exams?" (Gate: viewAny)
Step 3: System asks → "Give me exams, filtered by search/status/class/type/date if provided"
Step 4: Query runs: SELECT * FROM lms_exams WHERE ... ORDER BY created_at DESC LIMIT 10
Step 5: View renders table with results + search bar + filters + pagination
```

### Create
```
Step 1: User clicks "Add Exam" → create() method → Gate: create → Show form
Step 2: User fills form → clicks "Create Exam"
Step 3: store() method → Gate: create again
Step 4: ExamRequest validates → all required fields, unique combination, unique code
Step 5: If invalid → show errors on form
Step 6: If valid → DB transaction:
          a. Auto-generate UUID
          b. Auto-generate code if not provided
          c. INSERT INTO lms_exams (...)
          d. activityLog() → "A new exam was created."
          e. DB commit
Step 7: Redirect back to Creation & Allocation tab with success toast
```

### Edit
```
Step 1: User clicks Edit → edit($id) method
Step 2: UsageCheckService checks → "Is this exam used in papers/allocations/attempts?"
Step 3: If used → BLOCK
Step 4: If not used → Gate: update → Show form with existing values
Step 5: User changes fields → clicks "Update Exam"
Step 6: update($id) method → UsageCheck again, Gate again
Step 7: If new status is PUBLISHED → run DV1-DV8 validation
Step 8: If validation fails → rollback, show errors
Step 9: If passes → save, log changes with diff, commit
Step 10: Redirect back with success toast
```

---

## Validate Before Save

| Field | Rule(s) | Error Message |
|-------|---------|---------------|
| `academic_session_id` | required | "Academic session is required" |
| `class_id` | required, exists:sch_classes,id | "Class is required" / "Selected class is invalid" |
| `exam_type_id` | required, exists, unique per session+class (ignores own ID) | "Exam type is required" / "This exam type already exists for the selected session and class" |
| `code` | nullable, string, max:50, unique | — |
| `title` | required, string, max:150 | "Exam title is required" |
| `start_date` | required, date, before_or_equal:end_date | "Start date must be before or equal to end date" |
| `end_date` | required, date, after_or_equal:start_date | "End date must be after or equal to start date" |
| `status_id` | required, exists | "Status is required" |
| `scheduled_result_at` | nullable, date, after_or_equal:start_date | — |
| `result_published` | nullable, in:IMMEDIATE,MANUAL,SCHEDULED | — |
| `grading_schema_id` | nullable, exists | — |
| `is_active` | boolean | — |
| **Usage (controller)** | Checked before edit/update/destroy/restore/forceDelete | "Cannot edit/update/delete/restore this exam because it has papers, allocations, or student attempts." |
| **DV1-DV8 (controller)** | Checked when status → PUBLISHED | Specific errors for each validation |

---

## Error Handling and Validation Messages

| Scenario | Message | Type |
|----------|---------|------|
| Missing title | "Exam title is required" | Validation (FormRequest) |
| Missing class | "Class is required" | Validation (FormRequest) |
| Missing exam type | "Exam type is required" | Validation (FormRequest) |
| Duplicate session+class+type | "This exam type already exists for the selected session and class" | Validation (unique) |
| End date before start | "End date must be after or equal to start date" | Validation (FormRequest) |
| Edit blocked (in use) | "Cannot edit this exam because it has papers, allocations, or student attempts." | Controller check |
| Update blocked (in use) | "Cannot update this exam because it has papers, allocations, or student attempts." | Controller check |
| Delete blocked (in use) | "Cannot delete this exam because it has papers, allocations, or student attempts." | Controller check |
| Restore blocked (in use) | "Cannot restore this exam because it has papers, allocations, or student attempts." | Controller check |
| Force delete blocked (in use) | "Cannot permanently delete this exam because it has papers, allocations, or student attempts." | Controller check |
| DV1: Empty paper set | "Set 'X' in paper 'Y' contains no questions." | Publication validation |
| DV2: Marks mismatch | "Set 'X' total marks (Y) does not match Paper target marks (Z)." | Publication validation |
| DV3-DV4: Blueprint mismatch | "Set 'X' is missing Y questions of type 'Z'." / "Set 'X' section 'Y' marks (A) do not match Blueprint target (B)." | Publication validation |
| DV5-DV6: Difficulty mismatch | "Set 'X' lacks questions for complexity 'Y'. (Actual: A, Min Required: B)" | Publication validation |
| DV7: Scope coverage | "Set 'X' does not cover required questions for Topic 'Y'." | Publication validation |
| DB save failure | "Failed to create exam. Please try again." | Catch block (transaction rollback) |
| DB update failure | "Failed to update exam. Please try again." | Catch block (transaction rollback) |
| DB delete failure | "Failed to delete exam. Please try again." | Catch block (transaction rollback) |
| Status toggle failure | "Failed to update status." | Catch block (500 JSON) |

---

## Success Scenarios

**SC-001 — Creating a New Exam**
Admin creates "Annual Exam 2025-26 for Class 10". FormRequest validates. System generates UUID and code `EXAM_2025_CLASS10_ANNUAL_A1B2C3`. `Exam::create()` inserts into `lms_exams`. Activity logged. Redirect with success.

**SC-002 — Editing an Unused Exam**
Admin edits exam title from "Annual Exam" to "Final Annual Exam". UsageCheck returns false (no papers/allocations). Validation passes. `update()` saves changes, logs old/new values. Redirect with success.

**SC-003 — Publishing with Valid Structure**
Admin sets exam status to PUBLISHED. `validateExamDifficulty()` runs DV1-DV8. All checks pass. Status updated. Redirect with success.

**SC-004 — Soft Delete and Restore**
Admin deletes unused exam. `destroy()` sets `is_active=0`, soft-deletes. Later restored from trash. `restore()` sets `deleted_at=NULL`, `is_active=1`. Back to active list.

---

## Failure Scenarios

**FC-001 — Duplicate Session+Class+Type Rejected**
Admin tries to create "Annual Exam 2025-26 for Class 10" when it already exists. Validation fails: "This exam type already exists for the selected session and class."

**FC-002 — Edit Blocked Due to Usage**
Admin tries to edit an exam that already has 3 papers under it. `edit()` calls `UsageCheckService->isUsed()` → returns true. Blocked with error.

**FC-003 — Publication Rejected Due to Validation**
Admin tries to publish an exam where a paper set's total marks don't match the paper target. DV2 fails. Rollback. Error shown.

**FC-004 — Delete Blocked Due to Allocations**
Admin tries to delete an exam that has student allocations. `destroy()` checks usage first. Blocked.

---

## Dependencies Module and Tables

| Dependency | Type | Details |
|-----------|------|---------|
| `lms_exams` | Primary Table | All exam data stored here |
| `lms_exam_papers` | Consumer Table | `exam_id` FK → `lms_exams.id` — usage check queries this |
| `lms_exam_allocations` | Consumer Table | Accessed through `ExamPaper` — usage check |
| `lms_exam_attempts` | Consumer Table | Accessed through `ExamPaper` — usage check |
| `Exam` Model | Eloquent Model | `Modules\LmsExam\Models\Exam` — uses SoftDeletes, UUID boot |
| `LmsExamController` | Controller | Monolithic controller with all CRUD + validation + tab loading |
| `ExamRequest` | Form Request | Validation rules for all fields |
| `ExamPolicy` | Policy | Gates: `tenant.exam.*` |
| `ExamUsageCheckService` | Service | Checks `ExamPaper::where('exam_id', $id)->count()` + allocations + attempts |
| `ExamQueryService::examsQuery()` | Service | Builds filtered query for index listing |
| `lms_exam_types` | Reference Table | `exam_type_id` FK |
| `lms_exam_status_events` | Reference Table | `status_id` FK |
| `glb_academic_sessions` | Reference Table | `academic_session_id` FK |
| `sch_classes` | Reference Table | `class_id` FK |
| `slb_grade_division_master` | Reference Table | `grading_schema_id` FK |
| Activity Log | Consumer | `activityLog()` on all CRUD operations |

**Table: `lms_exams`**

| Column | Type | Details |
|--------|------|---------|
| id | INT UNSIGNED PK | Auto-increment |
| uuid | BINARY(16) | Unique UUID |
| academic_session_id | INT UNSIGNED | FK to glb_academic_sessions.id |
| class_id | INT UNSIGNED | FK to sch_classes.id |
| exam_type_id | INT UNSIGNED | FK to lms_exam_types.id |
| code | VARCHAR(50) | Auto-generated or custom, unique |
| title | VARCHAR(150) | Display name |
| description | TEXT NULL | Optional description |
| start_date | DATE | Exam start date |
| end_date | DATE | Exam end date |
| grading_schema_id | INT UNSIGNED NULL | FK to slb_grade_division_master.id |
| status_id | INT UNSIGNED | FK to lms_exam_status_events.id |
| result_published | ENUM('IMMEDIATE','SCHEDULED','MANUAL') | Default 'MANUAL' |
| scheduled_result_at | DATETIME NULL | Scheduled result publish time |
| is_result_published | TINYINT(1) | Default 0 |
| created_by | INT UNSIGNED NULL | FK to sys_users.id |
| is_active | TINYINT(1) | Default 1 |
| created_at | TIMESTAMP | Auto-set on insert |
| updated_at | TIMESTAMP | Auto-updated on change |
| deleted_at | TIMESTAMP NULL | Soft delete timestamp |

**Constraints:**
- `UNIQUE KEY uq_exam_uuid (uuid)` — no duplicate UUIDs
- `UNIQUE KEY uq_exam_code (code)` — no duplicate codes
- `UNIQUE KEY uq_exam_session_class_type (academic_session_id, class_id, exam_type_id)` — one exam type per session+class
- `FOREIGN KEY` references to sessions, classes, exam types, grading schemas, statuses, users
