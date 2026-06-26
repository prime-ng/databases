# HMW — LMS Homework
## Module Requirement Document V2
**Version:** 2.0 | **Date:** 2026-03-26 | **Status:** Draft | **Mode:** FULL

---

## 1. Executive Summary

LmsHomework is the homework assignment and submission management module of Prime-AI. It enables teachers to create graded or ungraded homework tasks aligned to academic session, class/section, subject, lesson, and optional topic. Students (once the portal is live) receive per-student assignment records (`lms_homework_assignment`) with release conditions, per-student due-date overrides, and notification timestamps. A Rule Engine framework (`sys_trigger_event`, `sys_action_type`, `sys_rule_engine_config`, `sys_rule_action_map`, `sys_rule_execution_log`) exists to automate notifications and actions on homework lifecycle events.

**Current implementation status: ~62% complete.**

**Critical bugs confirmed in code:**

- `HomeworkSubmissionController::review()` (line 285) — zero `Gate::authorize()`, uses raw `$request->field` instead of validated data. Any authenticated user can grade any submission.
- `HomeworkSubmissionController::show()` (line 149) — zero authorization check.
- `HomeworkSubmissionController::store()` (lines 128–134) — does not use `$request->validated()`, uses raw request fields directly.
- `HomeworkSubmissionController::edit()` (line 168) — fetches `$teachers` from `Student::where('is_active','1')->get()` — wrong model, students are not teachers.
- `HomeworkSubmissionController::store()` — `is_late` computed correctly but late submission is NOT blocked when `allow_late_submission = 0`.
- `lms_homework_assignment` table is referenced by `HomeworkAssignment` model and `publish()` controller but the table **does not exist in tenant_db_v2.sql DDL**.
- No `EnsureTenantHasModule` middleware on route group (line 746 of routes/tenant.php).
- `Homework` model fillable includes `schedule_id` and `release_condition` (string ENUM) but the DDL uses `release_condition_id` (INT FK to sys_dropdown). Schema mismatch.
- No `sys_rule_action_map` model or controller — table exists in DDL but is unimplemented.
- No `sys_rule_execution_log` model or controller — table exists in DDL but is unimplemented.
- Zero test coverage (0 tests).

**Note on previously reported FATAL bug:** V1 and the gap analysis reported `HoemworkData()` as missing the `$request` parameter. The actual code (line 52) shows `public function HoemworkData(Request $request)` — the parameter IS present. The method name typo (`HoemworkData`) remains but the crash is not reproducible. The method body references `$request->class` which works in PHP (class is not a reserved word as an object property). This bug is downgraded to LOW (naming convention issue only).

**Stats:**
- Controllers: 5 | Models: 6 (incl. HomeworkAssignment) | Services: 0 | FormRequests: 5 | Tests: 0
- Database tables (DDL-confirmed): `lms_homework`, `lms_homework_submissions`
- Database tables (model exists but DDL missing): `lms_homework_assignment`
- System tables used: `sys_trigger_event`, `sys_action_type`, `sys_rule_engine_config`, `sys_rule_action_map`, `sys_rule_execution_log`

---

## 2. Module Overview

### Business Purpose
Enable teachers to assign homework to class/section groups with configurable submission windows, difficulty levels, and release conditions. Track per-student assignment records, detect late submissions, allow teacher grading and feedback, and optionally trigger automated actions (notifications, LXP points) via the Rule Engine on lifecycle events.

### Key Features
1. Homework template creation with class/subject/lesson/topic alignment
2. Configurable submission types: TEXT, FILE, HYBRID, OFFLINE_CHECK
3. Gradable/non-gradable homework with max/passing marks
4. Assign date + due date scheduling with server-side enforcement
5. Three release conditions: IMMEDIATE, ON_TOPIC_COMPLETE, ON_SCHEDULED_DATE
6. Publish workflow: DRAFT → PUBLISHED, bulk-creates per-student `lms_homework_assignment` rows
7. Per-student assignment tracking: release flags, view counts, notification timestamps
8. Late submission detection and enforcement (flag auto-computed at submit time)
9. File attachment via Spatie Media Library (collection `homework_submission_files`)
10. Teacher grading: marks_obtained, teacher_feedback, graded_by, graded_at
11. Auto-publish score toggle for immediate grade visibility
12. Rule Engine: trigger events + action types + rule configurations + action mapping + execution logging

### Menu Path
`LMS > Homework`

### Architecture
Tab-based single-page interface via `LmsHomeworkController::index()`. All sub-entities load in one request. Publish action is a separate JSON endpoint (`POST /home-works/{id}/publish`). Review/grade is a JSON PUT endpoint (`PUT /homework-submission/review/{id}`).

---

## 3. Stakeholders & Roles

| Actor | Role |
|---|---|
| Teacher | Creates homework, publishes to students, reviews and grades submissions |
| Admin | Manages rule engine configuration, trigger events, action types; can override any action |
| Student | (Portal absent) Receives assignment record; submits text or file; views grade |
| Parent | (Absent) Views child's homework status and grades via parent portal |
| System (Rule Engine) | Fires automated actions on trigger events (notify, award LXP points, etc.) |

---

## 4. Functional Requirements

### FR-HMW-01: Trigger Event Management
**Priority:** Medium | **Status:** ✅ Implemented
**Tables:** `sys_trigger_event`

**Description:** Defines automation trigger points in the homework lifecycle (e.g., `HOMEWORK_ASSIGNED`, `HOMEWORK_SUBMITTED`, `HOMEWORK_GRADED`, `DEADLINE_PASSED`). Each record has a `code`, `name`, `description`, and `event_logic` (JSON).

**Actors:** Admin
**Input:** code (UNIQUE), name, description, event_logic (JSON), is_active

**Implementation:**
- `TriggerEventController` — full CRUD + trashed/restore/forceDelete/toggleStatus
- Model: `Modules\LmsHomework\Models\TriggerEvent`, table `sys_trigger_event`
- FormRequest: `TriggerEventRequest`
- Route: `lms-home-work.trigger-event.*`
- Gap: No `TriggerEventPolicy` exists — authorization relies on implicit or global policy. ❌ Policy missing.

**Test Cases:**
- TC-HMW-01-01: Create duplicate trigger event code — expect unique validation error
- TC-HMW-01-02: Soft delete and restore trigger event
- TC-HMW-01-03: Toggle status on active/inactive event

---

### FR-HMW-02: Action Type Management
**Priority:** Medium | **Status:** ✅ Implemented
**Tables:** `sys_action_type`

**Description:** Defines what automated action to execute when a trigger fires (e.g., `SEND_NOTIFICATION`, `AWARD_LXP_POINTS`, `SEND_EMAIL`, `MARK_LATE`). Each action type has `action_logic` (JSON) and `required_parameters` (JSON) columns.

**Actors:** Admin
**Input:** code (UNIQUE), name, description, action_logic (JSON), required_parameters (JSON), is_active

**Implementation:**
- `ActionTypeController` — full CRUD + trashed/restore/forceDelete/toggleStatus
- Model: `Modules\LmsHomework\Models\ActionType`, table `sys_action_type`
- FormRequest: `ActionTypeRequest`
- Policy: `ActionTypePolicy` — registered and enforced
- Route: `lms-home-work.action-types.*`

**Test Cases:**
- TC-HMW-02-01: Create action type with valid JSON action_logic
- TC-HMW-02-02: Create action type without required code — validation error

---

### FR-HMW-03: Rule Engine Configuration
**Priority:** Medium | **Status:** ✅ Implemented (config only; execution absent)
**Tables:** `sys_rule_engine_config`

**Description:** Binds a TriggerEvent to execution rules. Configuration includes `rule_code`, `rule_name`, `trigger_event_id`, `logic_config` (JSON), `priority`, `stop_further_execution`, `ai_enabled`, and `ai_confidence_score`. Note: the DDL column is `trigger_event_id` FK → `lms_trigger_event` (using old table name prefix in DDL FK constraint — potential mismatch with `sys_trigger_event`).

**Actors:** Admin
**Input:** rule_code, rule_name, description, trigger_event_id, logic_config (JSON), priority, stop_further_execution, ai_enabled, is_active

**Implementation:**
- `RuleEngineConfigController` — full CRUD + trashed/restore/forceDelete/toggleStatus
- Model: `Modules\LmsHomework\Models\RuleEngineConfig`, table `sys_rule_engine_config`
- FormRequest: `RuleEngineConfigRequest`
- Policy: `RuleEngineConfigPolicy` — registered and enforced
- Route: `lms-home-work.rule-engine-configs.*`

**Gap:** No `sys_rule_action_map` controller or model — cannot bind multiple actions per rule. ❌

**Test Cases:**
- TC-HMW-03-01: Create rule config with valid trigger_event_id
- TC-HMW-03-02: Create rule config with non-existent trigger_event_id — validation error
- TC-HMW-03-03: Verify priority ordering (lower priority integer executes first)

---

### FR-HMW-04: Rule Action Mapping
**Priority:** Medium | **Status:** ❌ Not Started
**Tables:** `sys_rule_action_map`

**Description:** Binds a RuleEngineConfig to one or more ActionTypes with execution order. Allows a single rule trigger to fire multiple sequential actions (e.g., send notification AND award LXP points).

**Actors:** Admin
**Input:** rule_id (FK sys_rule_engine_config), action_type_id (FK sys_action_type), execution_order, is_active

**Required:**
- Model: `RuleActionMap`, table `sys_rule_action_map`
- Controller: `RuleActionMapController` with CRUD + reorder support
- FormRequest: `RuleActionMapRequest`
- Policy: `RuleActionMapPolicy`
- Routes under `lms-home-work.rule-action-maps.*`

**Test Cases:**
- TC-HMW-04-01: Add two actions to same rule — both saved with correct execution_order
- TC-HMW-04-02: Reorder actions — execution_order updated correctly

---

### FR-HMW-05: Rule Execution Logging
**Priority:** Low | **Status:** ❌ Not Started
**Tables:** `sys_rule_execution_log`

**Description:** Audit log for every rule execution. Records rule_id, trigger_event_id, action_type_id, entity_type, entity_id, execution_context (JSON), execution_result (SUCCESS/FAILED/SKIPPED), error_message, and executed_at.

**Actors:** System (automated)
**Required:**
- Model: `RuleExecutionLog`, table `sys_rule_execution_log`
- Read-only controller (index + show) for admin audit view
- No soft delete — execution logs are immutable audit records

**Test Cases:**
- TC-HMW-05-01: Rule execution creates log with SUCCESS result
- TC-HMW-05-02: Failed rule execution creates log with FAILED result and error_message

---

### FR-HMW-06: Homework Creation (Template)
**Priority:** Critical | **Status:** 🟡 Partial (publish workflow functional; schema mismatch present)
**Tables:** `lms_homework`

**Description:** Teacher creates a homework template aligned to academic session, class, optional section, subject, optional lesson, and optional topic. Sets submission type, grading config, schedule, release condition, and policies. On save, homework is DRAFT. The `publish()` action promotes to PUBLISHED and bulk-creates per-student assignment records.

**Actors:** Teacher, Admin
**Input Fields:**
- `academic_session_id` — FK sch_academic_sessions (auto-set from current session)
- `class_id` — FK sch_classes (required)
- `section_id` — FK sch_sections (optional; NULL = all sections)
- `subject_id` — FK sch_subjects (required)
- `lesson_id` — FK slb_lessons (optional)
- `topic_id` — FK slb_topics (optional)
- `title` — VARCHAR(255), required
- `description` — LONGTEXT HTML/Markdown, required (DDL: NOT NULL)
- `submission_type_id` — FK sys_dropdown_table (TEXT/FILE/HYBRID/OFFLINE_CHECK)
- `is_gradable` — TINYINT DEFAULT 1
- `max_marks` — DECIMAL(5,2), nullable
- `passing_marks` — DECIMAL(5,2), nullable
- `difficulty_level_id` — FK slb_complexity_level (optional)
- `assign_date` — DATETIME required
- `due_date` — DATETIME required (must be >= assign_date)
- `allow_late_submission` — TINYINT DEFAULT 0
- `auto_publish_score` — TINYINT DEFAULT 0
- `release_condition_id` — FK sys_dropdown_table (IMMEDIATE/ON_TOPIC_COMPLETE/ON_SCHEDULED_DATE)
- `status_id` — FK sys_dropdown_table (DRAFT/PUBLISHED/ARCHIVED)

**Schema Bug (CRITICAL):**
The `Homework` model `$fillable` lists `release_condition` (string) and `schedule_id` (INT), but the DDL defines `release_condition_id` (INT UNSIGNED FK → sys_dropdown_table) and no `schedule_id` column. The model also has `syllabusSchedule()` relationship via `schedule_id` which will fail at runtime. The model's `$casts` do not cast `release_condition_id`.

**Fix Required:** Update `$fillable` to use `release_condition_id` (remove `release_condition` string, remove `schedule_id`). Update `publish()` controller which reads `$homework->release_condition` (string) — must read `$homework->releaseCondition->value` instead.

**Processing:**
- `created_by` = Auth::id(), `updated_by` = Auth::id() on updates
- `isEditable()` checks `status_id == config('lmshomework.status.draft')`
- `isDeletable()` checks `submission_count == 0`
- SoftDeletes enabled
- DB::transaction in `publish()` — wraps assignment bulk-create

**Gaps:**
- `Topic::get()` in `index()` (line 45) loads entire topics table — N+1 performance risk ❌
- `Student::get()` in `index()` (line 46) loads entire students table — N+1 performance risk ❌
- `AcademicSession::get()` (line 43) loads all sessions without current-session filter ❌
- No DB::transaction in `store()` — partial failure leaves orphaned records ❌
- `destroy()` uses `Homework::where('id',$id)->first()` (line 331) instead of `findOrFail()` ❌

**Acceptance Criteria:**
- DRAFT homework can be created and edited
- Only DRAFT homework can be published
- Published homework cannot be edited or deleted
- Homework with existing submissions cannot be deleted
- `due_date` must be >= `assign_date` — server-side validation

**Test Cases:**
- TC-HMW-06-01: Create homework happy path — DRAFT created with all required fields
- TC-HMW-06-02: Create homework missing title — validation error
- TC-HMW-06-03: due_date before assign_date — validation error
- TC-HMW-06-04: Edit DRAFT homework — succeeds
- TC-HMW-06-05: Edit PUBLISHED homework — rejected
- TC-HMW-06-06: Delete homework with submissions — rejected
- TC-HMW-06-07: Publish homework — assignments created for all enrolled students

---

### FR-HMW-07: Homework Assignment (Publish Workflow)
**Priority:** Critical | **Status:** 🟡 Partial (code functional; DDL table missing)
**Tables:** `lms_homework_assignment` (MODEL EXISTS; DDL TABLE MISSING)

**Description:** When teacher publishes a homework, the system bulk-creates one `lms_homework_assignment` row per enrolled student in the target class/section. Each row captures release status, per-student due date, notification timestamps, and view tracking. This is the per-student assignment record that drives the student portal visibility and late-submission enforcement per student.

**CRITICAL GAP — DDL MISSING:**
The `lms_homework_assignment` table is referenced by `HomeworkAssignment` model and `publish()` controller but does NOT exist in `tenant_db_v2.sql`. Any call to `publish()` will throw a MySQL `Table 'lms_homework_assignment' doesn't exist` error. The table must be added to the DDL.

**Proposed Table Structure (from HomeworkAssignment model $fillable):**

| Column | Type | Notes |
|---|---|---|
| id | INT UNSIGNED PK | AUTO_INCREMENT |
| homework_id | INT UNSIGNED | FK lms_homework.id CASCADE |
| student_id | INT UNSIGNED | FK sys_users (student) |
| academic_session_id | INT UNSIGNED | FK sch_academic_sessions |
| class_id | INT UNSIGNED | FK sch_classes |
| section_id | INT UNSIGNED | FK sch_sections NULL |
| subject_id | INT UNSIGNED | FK sch_subjects |
| release_condition_id | INT UNSIGNED | FK sys_dropdown NULL |
| release_scheduled_date | DATETIME | NULL (for ON_SCHEDULED_DATE) |
| is_released | TINYINT(1) | DEFAULT 0 |
| released_at | DATETIME | NULL |
| due_date | DATETIME | NULL (per-student override) |
| allow_late_submission | TINYINT(1) | DEFAULT 0 |
| late_submission_override_reason | TEXT | NULL |
| late_submission_override_by | INT UNSIGNED | NULL FK sys_users |
| late_submission_override_at | DATETIME | NULL |
| viewed_at | DATETIME | NULL |
| view_count | INT UNSIGNED | DEFAULT 0 |
| student_notified_at | DATETIME | NULL |
| parent_notified_at | DATETIME | NULL |
| reminder_sent_at | DATETIME | NULL |
| status_id | INT UNSIGNED | FK sys_dropdown (ASSIGNED/PENDING_RELEASE/SUBMITTED/GRADED) |
| assigned_by | INT UNSIGNED | FK sys_users |
| is_active | TINYINT(1) | DEFAULT 1 |
| created_by | INT UNSIGNED | FK sys_users |
| updated_by | INT UNSIGNED | NULL FK sys_users |
| created_at | TIMESTAMP | NULL |
| updated_at | TIMESTAMP | NULL |
| deleted_at | TIMESTAMP | NULL |
| UNIQUE | (homework_id, student_id) | one assignment per student |

**Acceptance Criteria:**
- Publish creates exactly one assignment row per enrolled active student
- IMMEDIATE release: `is_released=1`, `released_at=now()`, `status=ASSIGNED`
- ON_TOPIC_COMPLETE / ON_SCHEDULED_DATE: `is_released=0`, `status=PENDING_RELEASE`
- Duplicate publish (re-publish) uses `updateOrCreate` — idempotent

**Test Cases:**
- TC-HMW-07-01: Publish to class of 30 students — 30 assignment rows created
- TC-HMW-07-02: Re-publish (idempotency) — rows updated, no duplicates
- TC-HMW-07-03: IMMEDIATE release — all rows have is_released=1
- TC-HMW-07-04: ON_SCHEDULED_DATE release — all rows have is_released=0

---

### FR-HMW-08: Homework Submission — Student Side
**Priority:** Critical | **Status:** 🟡 Partial (admin UI only; no student portal; missing late enforcement)
**Tables:** `lms_homework_submissions`

**Description:** A student submits homework response (text, file, or both) before the due date. System auto-computes `is_late` by comparing `now()` to `homework.due_date`. When `allow_late_submission = 0` and submission is late, the system MUST block the submission (currently NOT enforced — bug).

**Actors:** Student (portal absent), Admin (can create on behalf)
**Input:** homework_id, student_id, submission_text (nullable), attachment (file, nullable)

**Processing:**
- Load homework via `Homework::findOrFail($request->homework_id)`
- Compute `is_late = now()->gt($homework->due_date)`
- If `is_late == true` AND `$homework->allow_late_submission == false` → reject with 422 (NOT CURRENTLY DONE)
- Create `HomeworkSubmission` record with `submitted_at = now()`
- If file uploaded: `addMediaFromRequest('attachment')->toMediaCollection('homework_submission_files', 'public')`

**Bugs:**
- `store()` does not use `$request->validated()` (lines 129–133) — uses raw request fields directly ❌
- Late submission not blocked when `allow_late_submission = 0` ❌
- `show()` (line 149) has no `Gate::authorize()` — any authenticated user can view any submission ❌
- No file size/type validation on attachment upload ❌

**Acceptance Criteria:**
- UNIQUE (homework_id, student_id) prevents duplicate submissions
- Late submission blocked (422 response) when `allow_late_submission = 0` and `now() > due_date`
- File upload validated: max 10MB, allowed types PDF/DOCX/JPG/PNG/ZIP
- `show()` restricted to submission owner, grading teacher, or Admin

**Test Cases:**
- TC-HMW-08-01: On-time submission — stored with is_late=0
- TC-HMW-08-02: Late submission with allow_late=1 — stored with is_late=1
- TC-HMW-08-03: Late submission with allow_late=0 — rejected 422
- TC-HMW-08-04: Duplicate submission by same student — rejected (UNIQUE violation)
- TC-HMW-08-05: File upload over 10MB — rejected with validation error
- TC-HMW-08-06: Unauthorized user views submission — 403

---

### FR-HMW-09: Homework Grading / Review
**Priority:** Critical | **Status:** 🟡 Partial (method exists; ZERO security — critical bug)
**Tables:** `lms_homework_submissions`

**Description:** Teacher opens a submitted homework, enters `marks_obtained`, `teacher_feedback`, and changes status from SUBMITTED to CHECKED or REJECTED. System records `graded_by` (Auth::id()) and `graded_at` (now()).

**Actors:** Teacher (homework creator or Admin only)

**CRITICAL SECURITY BUG:**
```
File: /Modules/LmsHomework/app/Http/Controllers/HomeworkSubmissionController.php
Lines: 285–299

public function review(Request $request, $id)
{
    $submission = HomeworkSubmission::findOrFail($id);
    $submission->update([
        'status_id' => $request->status_id,           // raw, unvalidated
        'marks_obtained' => $request->marks_obtained, // raw, unvalidated — can exceed max_marks
        'teacher_feedback' => $request->teacher_feedback,
        'graded_by' => auth()->id(),
        'graded_at' => now(),
    ]);
    // NO Gate::authorize() — any authenticated user can grade any submission
    // NO validation — marks_obtained not checked against homework.max_marks
    // NO FormRequest used
```

**Required Fixes:**
1. Add `Gate::authorize('tenant.homework-submission.update')` before findOrFail
2. Verify Auth::id() is the teacher who created the homework OR is Admin
3. Create `ReviewSubmissionRequest` FormRequest validating:
   - `status_id` — required, exists in sys_dropdown_table
   - `marks_obtained` — nullable, numeric, min:0, max from homework.max_marks
   - `teacher_feedback` — nullable, string, max:2000
4. Use `$request->validated()` in the update call
5. If `auto_publish_score = 1` on homework, dispatch notification to student after grading

**Acceptance Criteria:**
- Only the teacher who created the homework OR Admin can grade
- `marks_obtained` must not exceed `homework.max_marks`
- `marks_obtained` must be >= 0
- `status_id` must be a valid submission status dropdown value
- Auto-publish score triggers student notification if `auto_publish_score = 1`

**Test Cases:**
- TC-HMW-09-01: Grade by homework creator (teacher) — succeeds
- TC-HMW-09-02: Grade by different authenticated user — 403
- TC-HMW-09-03: marks_obtained > max_marks — validation error
- TC-HMW-09-04: marks_obtained negative — validation error
- TC-HMW-09-05: Invalid status_id — validation error
- TC-HMW-09-06: auto_publish_score=1 on homework — notification fired after grade

---

### FR-HMW-10: Student Homework Portal
**Priority:** High | **Status:** ❌ Not Started

**Description:** Student-facing view to see assigned and unsubmitted homework, submit responses, view grades and teacher feedback. Requires integration with `lms_homework_assignment` (release check) and a student-authenticated route context.

**Actors:** Student

**Required (to be created):**
- `StudentHomeworkController` with methods:
  - `myHomework(Request $request)` — list assignments (is_released=1) for logged-in student
  - `viewHomework($assignmentId)` — detail view; increments view_count, sets viewed_at
  - `submit(Request $request, $assignmentId)` — student submission form handler
  - `viewResult($assignmentId)` — view grade and feedback (if auto_publish_score=1 or graded)
- Views: student dashboard, detail view, submission form, result view
- Routes under student-authenticated prefix (e.g., `student.homework.*`)

**Business Rules:**
- Only show homework where `lms_homework_assignment.is_released = 1`
- Submission form only accessible before `due_date` (or if `allow_late_submission = 1` on assignment)
- Result view only accessible if `auto_publish_score = 1` on homework OR if teacher manually releases

**Test Cases:**
- TC-HMW-10-01: Student sees only released assignments for their class/section
- TC-HMW-10-02: Student cannot view unreleased (is_released=0) assignment
- TC-HMW-10-03: Student views assignment — view_count increments, viewed_at set
- TC-HMW-10-04: Student submits before due_date — submission created
- TC-HMW-10-05: Student views result when auto_publish_score=1 after grading

---

### FR-HMW-11: Parent Visibility
**Priority:** Medium | **Status:** ❌ Not Started

**Description:** Parent can view their child's homework assignments, submission status, and grades (if published). Requires parent portal integration.

**Actors:** Parent

**Required:** Integration with parent portal module (PPT). Read-only view of child's `lms_homework_assignment` and `lms_homework_submissions` records. Notification via `parent_notified_at` field on assignment.

---

### FR-HMW-12: Auto-Release Logic
**Priority:** Medium | **Status:** ❌ Not Started

**Description:** When release_condition is `ON_TOPIC_COMPLETE`, homework becomes visible to a student when they complete the associated topic in LXP. When `ON_SCHEDULED_DATE`, a scheduled job releases at `release_scheduled_date`.

**Required:**
- Scheduled job (Laravel Scheduler) to check `release_scheduled_date` and set `is_released=1`
- Event listener for LXP topic completion to trigger release for `ON_TOPIC_COMPLETE`

---

### FR-HMW-13: Rule Engine Execution
**Priority:** Medium | **Status:** ❌ Not Started

**Description:** When a homework lifecycle event fires (HOMEWORK_SUBMITTED, HOMEWORK_GRADED, DEADLINE_PASSED, etc.), the Rule Engine evaluates matching configs, executes all mapped actions in priority/execution_order, and logs results to `sys_rule_execution_log`.

**Required:**
- `RuleEngineService` — `fire(string $eventCode, string $entityType, int $entityId, array $context)`
- Integration points: `HomeworkSubmissionController::store()` (HOMEWORK_SUBMITTED), `review()` (HOMEWORK_GRADED)
- Models: `RuleActionMap`, `RuleExecutionLog`

---

## 5. Data Model

### 5.1 lms_homework
| Column | Type | Nullable | Notes |
|---|---|---|---|
| id | INT UNSIGNED PK | N | AUTO_INCREMENT |
| academic_session_id | INT UNSIGNED | N | FK sch_academic_sessions.id |
| class_id | INT UNSIGNED | N | FK sch_classes.id |
| section_id | INT UNSIGNED | Y | FK sch_sections.id; NULL = all sections |
| subject_id | INT UNSIGNED | N | FK sch_subjects.id |
| lesson_id | INT UNSIGNED | Y | FK slb_lessons.id |
| topic_id | INT UNSIGNED | Y | FK slb_topics.id |
| title | VARCHAR(255) | N | |
| description | LONGTEXT | N | HTML/Markdown |
| submission_type_id | INT UNSIGNED | N | FK sys_dropdown_table (TEXT/FILE/HYBRID/OFFLINE_CHECK) |
| is_gradable | TINYINT(1) | N | DEFAULT 1 |
| max_marks | DECIMAL(5,2) | Y | |
| passing_marks | DECIMAL(5,2) | Y | |
| difficulty_level_id | INT UNSIGNED | Y | FK slb_complexity_level.id |
| assign_date | DATETIME | N | |
| due_date | DATETIME | N | Must be >= assign_date |
| allow_late_submission | TINYINT(1) | N | DEFAULT 0 |
| auto_publish_score | TINYINT(1) | N | DEFAULT 0 |
| release_condition_id | INT UNSIGNED | Y | FK sys_dropdown_table (IMMEDIATE/ON_TOPIC_COMPLETE/ON_SCHEDULED_DATE) |
| status_id | INT UNSIGNED | N | FK sys_dropdown_table (DRAFT/PUBLISHED/ARCHIVED) |
| is_active | TINYINT(1) | N | DEFAULT 1 |
| created_by | INT UNSIGNED | N | FK sys_users.id |
| updated_by | INT UNSIGNED | Y | FK sys_users.id |
| created_at | TIMESTAMP | Y | |
| updated_at | TIMESTAMP | Y | |
| deleted_at | TIMESTAMP | Y | SoftDeletes |

**Indexes:** `idx_hw_class_sub (class_id, subject_id)`

**Model:** `Modules\LmsHomework\Models\Homework`
**Schema Mismatch:** Model `$fillable` has `release_condition` (string) and `schedule_id` — neither exists in DDL. Must be corrected to `release_condition_id`.

---

### 5.2 lms_homework_submissions
| Column | Type | Nullable | Notes |
|---|---|---|---|
| id | INT UNSIGNED PK | N | AUTO_INCREMENT |
| homework_id | INT UNSIGNED | N | FK lms_homework.id ON DELETE CASCADE |
| student_id | INT UNSIGNED | N | FK sys_users (student) |
| submitted_at | DATETIME | Y | DEFAULT CURRENT_TIMESTAMP |
| submission_text | LONGTEXT | Y | Student response text |
| attachment_media_id | INT UNSIGNED | Y | FK sys_media (Spatie) |
| status_id | INT UNSIGNED | N | FK sys_dropdown_table (SUBMITTED/CHECKED/REJECTED) |
| marks_obtained | DECIMAL(5,2) | Y | |
| teacher_feedback | TEXT | Y | |
| graded_by | INT UNSIGNED | Y | FK sys_users |
| graded_at | DATETIME | Y | |
| is_late | TINYINT(1) | N | DEFAULT 0 (auto-computed at submit time) |
| created_at | TIMESTAMP | Y | |
| updated_at | TIMESTAMP | Y | |
| deleted_at | TIMESTAMP | Y | SoftDeletes |

**Unique:** `uq_hw_sub (homework_id, student_id)` — one submission per student per homework

**Model:** `Modules\LmsHomework\Models\HomeworkSubmission`
**Gap:** Model has no `is_active` or `created_by` — DDL also lacks these columns (confirmed). SoftDeletes present.

---

### 5.3 lms_homework_assignment (DDL MISSING — MUST ADD)
See FR-HMW-07 for proposed column specification.

**Model:** `Modules\LmsHomework\Models\HomeworkAssignment`
**Model Table:** `lms_homework_assignment`
**Unique:** `(homework_id, student_id)`

---

### 5.4 sys_trigger_event
| Column | Type | Notes |
|---|---|---|
| id | INT UNSIGNED PK | AUTO_INCREMENT |
| code | VARCHAR(50) | UNIQUE NOT NULL |
| name | VARCHAR(100) | NOT NULL |
| description | TEXT | NULL |
| event_logic | JSON | NOT NULL |
| is_active | TINYINT(1) | DEFAULT 1 |
| created_at, updated_at, deleted_at | TIMESTAMP | |

---

### 5.5 sys_action_type
| Column | Type | Notes |
|---|---|---|
| id | INT UNSIGNED PK | AUTO_INCREMENT |
| code | VARCHAR(50) | UNIQUE NOT NULL |
| name | VARCHAR(100) | NOT NULL |
| description | TEXT | NULL |
| action_logic | JSON | NOT NULL |
| required_parameters | JSON | NULL |
| is_active | TINYINT(1) | DEFAULT 1 |
| created_at, updated_at, deleted_at | TIMESTAMP | |

---

### 5.6 sys_rule_engine_config
| Column | Type | Notes |
|---|---|---|
| id | INT UNSIGNED PK | AUTO_INCREMENT |
| rule_code | VARCHAR(50) | UNIQUE NOT NULL |
| rule_name | VARCHAR(100) | NOT NULL |
| description | TEXT | NULL |
| trigger_event_id | INT UNSIGNED | FK lms_trigger_event.id (DDL FK name mismatch — references old prefix) |
| applicable_class_group_id | INT UNSIGNED | NULL FK sch_class_groups_jnt |
| logic_config | JSON | NOT NULL |
| priority | INT | DEFAULT 100 |
| stop_further_execution | TINYINT(1) | DEFAULT 0 |
| ai_enabled | TINYINT(1) | DEFAULT 0 |
| ai_confidence_score | DECIMAL(5,2) | NULL |
| is_active | TINYINT(1) | DEFAULT 1 |
| created_at, updated_at, deleted_at | TIMESTAMP | |

---

### 5.7 sys_rule_action_map
| Column | Type | Notes |
|---|---|---|
| id | INT UNSIGNED PK | AUTO_INCREMENT |
| rule_id | INT UNSIGNED | FK lms_rule_engine_config.id (DDL FK references old prefix) |
| action_type_id | INT UNSIGNED | FK lms_action_type.id (DDL FK references old prefix) |
| execution_order | INT | DEFAULT 1 |
| is_active | TINYINT(1) | DEFAULT 1 |
| created_at, updated_at | TIMESTAMP | |

---

### 5.8 sys_rule_execution_log
| Column | Type | Notes |
|---|---|---|
| id | INT UNSIGNED PK | AUTO_INCREMENT |
| rule_id | INT UNSIGNED | FK lms_rule_engine_config.id |
| trigger_event_id | INT UNSIGNED | FK lms_trigger_event.id |
| action_type_id | INT UNSIGNED | FK lms_action_type.id |
| entity_type | VARCHAR(50) | e.g. 'homework', 'submission' |
| entity_id | INT UNSIGNED | |
| execution_context | JSON | |
| execution_result | ENUM | SUCCESS/FAILED/SKIPPED |
| error_message | TEXT | NULL |
| executed_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |

**Note:** DDL FK constraints on sys_rule_action_map and sys_rule_execution_log still reference `lms_rule_engine_config`, `lms_trigger_event`, `lms_action_type` (old prefixes). These FK constraint names need updating to `sys_` prefixed table names before DDL execution.

---

## 6. API Endpoints & Routes

**Route File:** `/Users/bkwork/Herd/prime_ai/routes/tenant.php` lines 746–791
**Route Prefix:** `/lms-home-work` | **Name Prefix:** `lms-home-work.`
**Middleware:** `['auth', 'verified']`
**Missing Middleware:** `EnsureTenantHasModule` — must be added ❌

| Method | URI | Name | Controller | Auth | Status |
|---|---|---|---|---|---|
| GET | /lms-home-work/home-works | lms-home-work.home-works.index | LmsHomeworkController@index | Gate: viewAny | ✅ |
| GET | /lms-home-work/home-works/create | lms-home-work.home-works.create | LmsHomeworkController@create | Gate: create | ✅ |
| POST | /lms-home-work/home-works | lms-home-work.home-works.store | LmsHomeworkController@store | Gate: create | ✅ |
| GET | /lms-home-work/home-works/{id} | lms-home-work.home-works.show | LmsHomeworkController@show | Gate: view | ✅ |
| GET | /lms-home-work/home-works/{id}/edit | lms-home-work.home-works.edit | LmsHomeworkController@edit | Gate: update | ✅ |
| PUT | /lms-home-work/home-works/{id} | lms-home-work.home-works.update | LmsHomeworkController@update | Gate: update | ✅ |
| DELETE | /lms-home-work/home-works/{id} | lms-home-work.home-works.destroy | LmsHomeworkController@destroy | Gate: delete | ✅ |
| GET | /lms-home-work/home-works/trash/view | lms-home-work.home-works.trashed | LmsHomeworkController@trashed | Gate: viewAny | ✅ |
| GET | /lms-home-work/home-works/{id}/restore | lms-home-work.home-works.restore | LmsHomeworkController@restore | Gate: restore | ✅ |
| DELETE | /lms-home-work/home-works/{id}/force-delete | lms-home-work.home-works.forceDelete | LmsHomeworkController@forceDelete | Gate: forceDelete | ✅ |
| POST | /lms-home-work/home-works/{id}/toggle-status | lms-home-work.home-works.toggleStatus | LmsHomeworkController@toggleStatus | Gate: update | ✅ |
| POST | /lms-home-work/home-works/{id}/publish | lms-home-work.home-works.publish | LmsHomeworkController@publish | Gate: update | ✅ |
| POST | /lms-home-work/get-students-by-class | lms-home-work.get-students-by-class | LmsHomeworkController@getStudentsByClass | auth | ✅ |
| (resource) | /lms-home-work/trigger-event | lms-home-work.trigger-event.* | TriggerEventController | Gate | ✅ |
| (resource) | /lms-home-work/homework-submission | lms-home-work.homework-submission.* | HomeworkSubmissionController | Gate (partial) | 🟡 |
| PUT | /lms-home-work/homework-submission/review/{id} | lms-home-work.homework-submission.review | HomeworkSubmissionController@review | NONE ❌ | ❌ |
| (resource) | /lms-home-work/action-types | lms-home-work.action-types.* | ActionTypeController | Gate | ✅ |
| (resource) | /lms-home-work/rule-engine-configs | lms-home-work.rule-engine-configs.* | RuleEngineConfigController | Gate | ✅ |

**Missing Routes (to add):**
- POST `/lms-home-work/home-works/{id}/assign-students` — assign specific students (override)
- GET `/lms-home-work/home-works/{id}/assignments` — view assignment list for a homework
- (resource) `/lms-home-work/rule-action-maps` — RuleActionMapController CRUD
- GET `/lms-home-work/rule-execution-logs` — read-only log viewer

---

## 7. UI Screens

| Screen | View File | Purpose | Status |
|---|---|---|---|
| Homework Hub (tab) | `lmshomework::lmshome-work.index` | Main tab container with filters | ✅ |
| Homework Create | `lmshomework::home-work.create` | Title, class, subject, topic, dates, flags | ✅ |
| Homework Edit | `lmshomework::home-work.edit` | Edit DRAFT homework | ✅ |
| Homework Show | `lmshomework::home-work.show` | Detail view | ✅ |
| Homework Trash | `lmshomework::home-work.trash` | Soft-deleted list with restore | ✅ |
| Submission List | `lmshomework::submission.index` | Filter by homework/student/status/late | ✅ |
| Submission Create | `lmshomework::submission.create` | Student select, text input, file upload | ✅ |
| Submission Edit | `lmshomework::submission.edit` | Grade entry (marks, feedback, status) | 🟡 (wrong $teachers) |
| Submission Show | `lmshomework::submission.show` | Detail with attachment | 🟡 (no auth gate) |
| Submission Trash | `lmshomework::submission.trash` | Soft-deleted list | ✅ |
| Trigger Events | `lmshomework::trigger-event.*` | Master data CRUD | ✅ |
| Action Types | `lmshomework::action-type.*` | Master data CRUD | ✅ |
| Rule Engine Config | `lmshomework::rule-engine-config.*` | Rule binding CRUD | ✅ |
| Student: My Homework | (to create) | Student dashboard listing assigned homework | ❌ |
| Student: Submit | (to create) | Submission form for student | ❌ |
| Student: Result | (to create) | Grade and feedback view | ❌ |
| Rule Action Map | (to create) | Map multiple actions per rule | ❌ |
| Rule Execution Log | (to create) | Audit log viewer | ❌ |

---

## 8. Business Rules

| BR# | Rule | Enforced | Gap |
|---|---|---|---|
| BR-01 | One submission per student per homework | ✅ UNIQUE DB constraint (homework_id, student_id) | — |
| BR-02 | Late submission: `is_late=1` when `submitted_at > homework.due_date` | ✅ computed at store() | — |
| BR-03 | Late submission blocked when `allow_late_submission=0` after due_date | ❌ NOT enforced | Bug in store() |
| BR-04 | `marks_obtained` must not exceed `homework.max_marks` | ❌ NOT validated | Bug in review() |
| BR-05 | `marks_obtained` must be >= 0 | ❌ NOT validated | Bug in review() |
| BR-06 | Only `is_gradable=1` homework can have marks_obtained set | ❌ NOT enforced | Gap |
| BR-07 | Homework editable only in DRAFT status | ✅ `isEditable()` checks status_id | — |
| BR-08 | Homework deletable only if no submissions | ✅ `isDeletable()` checks submission_count==0 | — |
| BR-09 | Only homework creator or Admin can grade | ❌ NOT enforced | Bug in review() |
| BR-10 | `auto_publish_score=1` → student sees grade immediately after review | ❌ NOT implemented | Gap |
| BR-11 | `ON_TOPIC_COMPLETE` release → student sees homework only after completing topic | ❌ NOT implemented | Gap |
| BR-12 | Publish only transitions from DRAFT; PUBLISHED/ARCHIVED cannot be re-published fresh | ✅ `isEditable()` gate in publish() | — |
| BR-13 | Submission type TEXT → submission_text required; FILE → attachment required; HYBRID → either | ❌ NOT validated | Gap in FormRequest |
| BR-14 | due_date must be >= assign_date | ❌ NOT validated server-side | Gap in HomeworkRequest |
| BR-15 | `description` is NOT NULL in DDL | ✅ DDL NOT NULL | Model fillable OK |

---

## 9. Workflows

### 9.1 Homework Lifecycle FSM

```
[Teacher Creates] ─────→ DRAFT
                              │
                    [publish()] (requires DRAFT)
                              │
                              ↓
                         PUBLISHED ─────→ Assignments bulk-created per student
                              │
                    [All due dates passed] (manual or scheduled)
                              │
                              ↓
                         ARCHIVED
```

### 9.2 Submission Status FSM

```
(not yet submitted)
        │
        │ [student submits / admin creates]
        ↓
    SUBMITTED
        │
        ├── [teacher grades → CHECKED]
        │           │
        │           └── [auto_publish_score=1] → grade visible to student
        │
        └── [teacher rejects → REJECTED]
                    │
                    └── (student may resubmit? — policy not defined in current code)
```

### 9.3 Assignment Release FSM

```
[publish() called]
        │
        ├── release_condition = IMMEDIATE
        │       └── is_released=1, status=ASSIGNED
        │
        ├── release_condition = ON_SCHEDULED_DATE
        │       └── is_released=0, status=PENDING_RELEASE
        │           [Scheduler at release_scheduled_date] → is_released=1, status=ASSIGNED
        │
        └── release_condition = ON_TOPIC_COMPLETE
                └── is_released=0, status=PENDING_RELEASE
                    [LXP topic completion event] → is_released=1, status=ASSIGNED
```

### 9.4 Rule Engine Flow

```
[Homework Event Fires] (e.g., HOMEWORK_SUBMITTED)
        │
        ↓
RuleEngineService::fire('HOMEWORK_SUBMITTED', 'submission', $id, $context)
        │
        ↓
[Query sys_rule_engine_config WHERE trigger_event.code = 'HOMEWORK_SUBMITTED'
 AND is_active=1 ORDER BY priority ASC]
        │
        ↓ foreach matching rule
[Query sys_rule_action_map WHERE rule_id = $rule->id ORDER BY execution_order ASC]
        │
        ↓ foreach action
[Execute ActionType logic from action_logic JSON]
        │
        ↓
[Write sys_rule_execution_log] (SUCCESS or FAILED)
        │
        └── [stop_further_execution=1] → break rule loop
```

---

## 10. Non-Functional Requirements

| # | NFR | Target | Status |
|---|---|---|---|
| NFR-01 | File upload size limit | 10MB max per attachment | ❌ Not validated |
| NFR-02 | File types allowed | PDF, DOCX, JPG, PNG, ZIP only | ❌ Not validated |
| NFR-03 | Due date enforcement | Server-side check, not client-side | ❌ Not enforced |
| NFR-04 | Grading authorization | Policy-enforced, not just UI-restricted | ❌ Bug in review() |
| NFR-05 | Audit trail | All grading actions logged via activityLog() | 🟡 index/create/update have logs; review() does not |
| NFR-06 | EnsureTenantHasModule | Must be added to lms-home-work route group | ❌ Missing |
| NFR-07 | Dropdown queries | Use AJAX lazy-load for large sets (topics, students) | ❌ Eager loads all |
| NFR-08 | DB transactions | Store/update wrapped in transaction | ❌ Missing in store() |
| NFR-09 | Pagination | Lists paginated (10 items default) | ✅ HoemworkData paginate(10) |
| NFR-10 | Test coverage | Minimum 30 test cases | ❌ 0 tests |
| NFR-11 | Tenant isolation | All queries implicitly scoped to tenant DB via stancl/tenancy | ✅ via multi-tenant setup |

---

## 11. Dependencies

| Module | Dependency Type | Detail |
|---|---|---|
| SchoolSetup | FK | `sch_classes`, `sch_sections`, `sch_subjects` |
| Syllabus | FK | `slb_lessons`, `slb_topics`, `slb_complexity_level` |
| StudentProfile | FK | Student model; `publish()` queries enrolled students |
| Prime (AcademicSession) | FK | `sch_academic_sessions` via AcademicSession model |
| SysDropdown | FK | submission_type_id, release_condition_id, status_id all reference sys_dropdown_table |
| sys_media (Spatie) | Shared Service | `attachment_media_id`; Spatie Media Library for file uploads |
| Notifications Module | Runtime | Rule Engine ActionType SEND_NOTIFICATION depends on notification system |
| LXP Module | Runtime | ON_TOPIC_COMPLETE release condition requires LXP topic completion events |
| Parent Portal (PPT) | Runtime | Parent visibility of homework status and grades |
| sys_users | FK | created_by, updated_by, graded_by, student_id, assigned_by |

---

## 12. Test Scenarios

### Critical Path (P0 — must fix first)

| ID | Scenario | Type | Expected |
|---|---|---|---|
| TC-HMW-P0-01 | review() called by non-teacher user | Feature | 403 Forbidden |
| TC-HMW-P0-02 | review() with marks_obtained > max_marks | Feature | 422 Validation Error |
| TC-HMW-P0-03 | review() with negative marks_obtained | Feature | 422 Validation Error |
| TC-HMW-P0-04 | show() by unauthorized user | Feature | 403 Forbidden |
| TC-HMW-P0-05 | store() late submission when allow_late=0 | Feature | 422 Blocked |
| TC-HMW-P0-06 | publish() → lms_homework_assignment table exists and rows created | Feature | 200, rows in DB |
| TC-HMW-P0-07 | Route group has EnsureTenantHasModule middleware | Unit | Middleware present |

### Homework CRUD

| ID | Scenario | Type | Expected |
|---|---|---|---|
| TC-HMW-11 | Create homework with all required fields | Feature | DRAFT created |
| TC-HMW-12 | Create homework missing title | Feature | 422 Validation Error |
| TC-HMW-13 | Create homework with due_date < assign_date | Feature | 422 Validation Error |
| TC-HMW-14 | Edit DRAFT homework | Feature | Updated |
| TC-HMW-15 | Edit PUBLISHED homework | Feature | Rejected |
| TC-HMW-16 | Delete homework with 0 submissions | Feature | Soft deleted |
| TC-HMW-17 | Delete homework with 1+ submissions | Feature | Rejected |
| TC-HMW-18 | Restore soft-deleted homework | Feature | Restored |
| TC-HMW-19 | Force delete homework | Feature | Hard deleted |

### Homework Submission

| ID | Scenario | Type | Expected |
|---|---|---|---|
| TC-HMW-21 | Submit before due_date | Feature | is_late=0 |
| TC-HMW-22 | Submit after due_date, allow_late=1 | Feature | is_late=1, stored |
| TC-HMW-23 | Submit after due_date, allow_late=0 | Feature | 422 blocked |
| TC-HMW-24 | Submit twice by same student | Feature | 422 UNIQUE violation |
| TC-HMW-25 | File upload PDF under 10MB | Feature | Stored in media collection |
| TC-HMW-26 | File upload over 10MB | Feature | 422 |
| TC-HMW-27 | File upload unsupported type | Feature | 422 |

### Grading

| ID | Scenario | Type | Expected |
|---|---|---|---|
| TC-HMW-31 | Grade by homework creator | Feature | 200, submission updated |
| TC-HMW-32 | Grade by Admin | Feature | 200, allowed |
| TC-HMW-33 | Grade by other teacher | Feature | 403 |
| TC-HMW-34 | marks_obtained = max_marks (boundary) | Feature | Accepted |
| TC-HMW-35 | marks_obtained = max_marks + 0.01 | Feature | 422 |
| TC-HMW-36 | marks_obtained = 0 (boundary) | Feature | Accepted |
| TC-HMW-37 | marks_obtained = -0.01 | Feature | 422 |

### Model Unit Tests

| ID | Scenario | Type | Expected |
|---|---|---|---|
| TC-HMW-41 | is_late computed correctly for on-time submit | Unit | is_late=0 |
| TC-HMW-42 | is_late computed correctly for late submit | Unit | is_late=1 |
| TC-HMW-43 | timeline_status returns UPCOMING before assign_date | Unit | 'UPCOMING' |
| TC-HMW-44 | timeline_status returns ONGOING between dates | Unit | 'ONGOING' |
| TC-HMW-45 | timeline_status returns OVERDUE after due_date | Unit | 'OVERDUE' |
| TC-HMW-46 | isDeletable returns false when submissions exist | Unit | false |
| TC-HMW-47 | isEditable returns false when PUBLISHED | Unit | false |

---

## 13. Glossary

| Term | Meaning |
|---|---|
| Homework | A teacher-created task (template) that is assigned to students via publish workflow |
| HomeworkAssignment | Per-student assignment record created on publish; tracks release, visibility, notifications |
| Submission | A student's response to a homework (text, file, or both) |
| Gradable | Homework that carries marks; non-gradable is for completion tracking only |
| Late Submission | A submission made after the `due_date`; `is_late=1` flag set at submit time |
| Allow Late Submission | Per-homework flag: when 0, system blocks online submission after due_date |
| Auto-Publish Score | Setting that makes student grade immediately visible after teacher grades |
| Release Condition | Controls when homework becomes visible: IMMEDIATE, ON_TOPIC_COMPLETE, ON_SCHEDULED_DATE |
| Timeline Status | Computed attribute on Homework: UPCOMING, ONGOING, or OVERDUE based on dates |
| Rule Engine | Automation framework: TriggerEvent fires → matches RuleEngineConfig → executes mapped ActionTypes |
| Trigger Event | A lifecycle point (HOMEWORK_ASSIGNED, HOMEWORK_SUBMITTED, HOMEWORK_GRADED, DEADLINE_PASSED) |
| Action Type | The action to execute when trigger fires (SEND_NOTIFICATION, AWARD_LXP_POINTS, etc.) |
| Rule Action Map | Binding between a rule config and one or more action types with execution order |
| Rule Execution Log | Immutable audit record of each rule execution (SUCCESS/FAILED/SKIPPED) |

---

## 14. Suggestions

### P0 — Fix Before Any Release

1. **Add DDL for `lms_homework_assignment`** — The `publish()` method and `HomeworkAssignment` model reference this table, which does not exist in `tenant_db_v2.sql`. Adding the table is required before publish() can be called in production. See FR-HMW-07 for proposed column spec.

2. **Secure `review()` immediately** — Add `Gate::authorize('tenant.homework-submission.update')`, create `ReviewSubmissionRequest` with marks_obtained validation (min:0, max: from homework.max_marks), and use `$request->validated()`.
   File: `HomeworkSubmissionController.php` lines 285–299.

3. **Add `Gate::authorize()` to `show()`** — `HomeworkSubmissionController::show()` line 149 has no authorization. Add gate check before returning view.

4. **Add `EnsureTenantHasModule` middleware** to the lms-home-work route group in `/routes/tenant.php` line 746. Change to `['auth', 'verified', EnsureTenantHasModule::class]`.

5. **Enforce late submission blocking** — In `HomeworkSubmissionController::store()` after computing `$isLate`, add: `if ($isLate && !$homework->allow_late_submission) { return back()->withErrors(...); }`.

6. **Fix Homework model schema mismatch** — Remove `release_condition` (string) and `schedule_id` from `$fillable`. Add `release_condition_id`. Update `publish()` controller which reads `$homework->release_condition` (line 453) to use `$homework->releaseCondition->value`.

### P1 — Fix Before Stable Release

7. **Use `$request->validated()` in `HomeworkSubmissionController::store()`** — Replace lines 129–133 raw request field access with `$request->validated()`.

8. **Fix `$teachers` in `HomeworkSubmissionController::edit()`** — Line 168 fetches `Student` model as `$teachers`. Replace with the correct Staff/Employee model.

9. **Add server-side due_date >= assign_date validation** in `HomeworkRequest` FormRequest.

10. **Wrap `store()` in DB transaction** in `LmsHomeworkController` — handles orphaned records on partial failure.

11. **Replace `Topic::get()` and `Student::get()`** with AJAX-loaded dropdowns (add `/get-topics-by-lesson` and `/get-students-by-class` endpoints already partially in place). Remove eager loads from `index()`.

12. **Create `TriggerEventPolicy`** — currently missing; add to `AuthServiceProvider` registration.

13. **Add audit logging to `review()`** — Add `activityLog($submission, 'Graded', [...])` after successful grade.

### P2 — Complete Missing Features

14. **Implement Rule Engine execution** — Create `RuleEngineService::fire()`, `RuleActionMap` model, `RuleExecutionLog` model. Integrate call into `store()` (HOMEWORK_SUBMITTED) and `review()` (HOMEWORK_GRADED).

15. **Create Student Homework Portal** — `StudentHomeworkController` with myHomework, viewHomework, submit, viewResult. Integrate `lms_homework_assignment.is_released` check.

16. **Implement auto-release scheduled job** — For `ON_SCHEDULED_DATE` condition, create a queued job checking `release_scheduled_date`.

17. **Implement auto-publish score notification** — After review(), if `$homework->auto_publish_score == 1`, dispatch student notification.

18. **Add file upload validation** — In `HomeworkSubmissionRequest`, add `attachment => 'nullable|file|max:10240|mimes:pdf,docx,jpg,jpeg,png,zip'`.

19. **Fix DDL FK names in sys_rule_ tables** — DDL FK constraints on `sys_rule_action_map` and `sys_rule_execution_log` reference `lms_rule_engine_config`, `lms_trigger_event`, `lms_action_type` (old prefixes). Update to `sys_rule_engine_config`, `sys_trigger_event`, `sys_action_type`.

### P3 — Quality & Testing

20. **Write minimum 30 test cases** covering all P0 bugs confirmed above.
21. **Replace `Homework::where('id',$id)->first()`** with `Homework::findOrFail($id)` in `destroy()` (line 331) and `toggleStatus()` (line 404).
22. **Rename `HoemworkData()`** to `getHomeworkData()` to fix the typo and follow naming conventions.
23. **Remove unused model imports** in `Homework.php` (TriggerEvent, ActionType, RuleEngineConfig, HomeworkRequest, Gate, Auth are imported in the model but unused).

---

## 15. Appendices

### A. File Inventory

```
/Users/bkwork/Herd/prime_ai/Modules/LmsHomework/
├── app/Http/Controllers/
│   ├── LmsHomeworkController.php        (tab hub + Homework CRUD; publish() method added)
│   ├── HomeworkSubmissionController.php  (CRUD + review AJAX; CRITICAL: review() no auth)
│   ├── TriggerEventController.php        (CRUD)
│   ├── ActionTypeController.php          (CRUD)
│   └── RuleEngineConfigController.php    (CRUD)
├── app/Models/
│   ├── Homework.php                       (schema mismatch: release_condition vs release_condition_id)
│   ├── HomeworkAssignment.php             (DDL table MISSING — lms_homework_assignment)
│   ├── HomeworkSubmission.php
│   ├── TriggerEvent.php
│   ├── ActionType.php
│   └── RuleEngineConfig.php
├── app/Http/Requests/
│   ├── HomeworkRequest.php
│   ├── HomeworkSubmissionRequest.php
│   ├── ActionTypeRequest.php
│   ├── TriggerEventRequest.php
│   └── RuleEngineConfigRequest.php
├── app/Policies/
│   ├── HomeworkPolicy.php
│   ├── HomeworkSubmissionPolicy.php       (show + review not enforced in controller)
│   ├── ActionTypePolicy.php
│   └── RuleEngineConfigPolicy.php
│   [MISSING: TriggerEventPolicy.php]
├── resources/views/
│   ├── lmshome-work/index.blade.php       (main tab hub)
│   ├── home-work/{create,edit,show,index,trash}.blade.php
│   ├── submission/{create,edit,show,index,trash}.blade.php
│   ├── trigger-event/{create,edit,show,index,trash}.blade.php
│   ├── action-type/{create,edit,show,index,trash}.blade.php
│   └── rule-engine-config/{create,edit,show,index,trash}.blade.php
└── routes/web.php  (minimal; main routes in /routes/tenant.php lines 746–791)
```

### B. Known Bugs Summary

| ID | Bug | File | Line | Severity |
|---|---|---|---|---|
| BUG-01 | `review()` zero Gate::authorize() | HomeworkSubmissionController.php | 285 | CRITICAL |
| BUG-02 | `review()` uses raw request fields, no FormRequest | HomeworkSubmissionController.php | 288–293 | CRITICAL |
| BUG-03 | `show()` zero Gate::authorize() | HomeworkSubmissionController.php | 149 | HIGH |
| BUG-04 | `store()` uses raw request fields, not validated() | HomeworkSubmissionController.php | 128–134 | HIGH |
| BUG-05 | Late submission not blocked when allow_late=0 | HomeworkSubmissionController.php | 118–144 | HIGH |
| BUG-06 | `lms_homework_assignment` table missing from DDL | tenant_db_v2.sql | — | CRITICAL |
| BUG-07 | EnsureTenantHasModule missing from route group | routes/tenant.php | 746 | HIGH |
| BUG-08 | Homework model fillable has `release_condition` string, should be `release_condition_id` INT FK | Homework.php | 51 | HIGH |
| BUG-09 | Homework model fillable has `schedule_id` — column not in DDL | Homework.php | 53 | MEDIUM |
| BUG-10 | `publish()` reads `$homework->release_condition` (string) — not mapped | LmsHomeworkController.php | 453 | HIGH |
| BUG-11 | `$teachers` fetched from Student model in edit() | HomeworkSubmissionController.php | 168 | MEDIUM |
| BUG-12 | No file size/type validation on attachment | HomeworkSubmissionController.php | 136–139 | MEDIUM |
| BUG-13 | sys_rule_action_map DDL FK names reference old lms_ prefix | tenant_db_v2.sql | 362–372 | MEDIUM |
| BUG-14 | sys_rule_execution_log DDL FK names reference old lms_ prefix | tenant_db_v2.sql | 377–395 | MEDIUM |
| BUG-15 | `HoemworkData` method name typo | LmsHomeworkController.php | 52 | LOW |
| BUG-16 | 0 tests for entire module | — | — | HIGH |
| BUG-17 | No TriggerEventPolicy | Policies/ | — | MEDIUM |
| BUG-18 | No review() activityLog() call | HomeworkSubmissionController.php | 285–299 | MEDIUM |

### C. Route Group Location
All functional routes for LmsHomework are defined in `/Users/bkwork/Herd/prime_ai/routes/tenant.php` lines 746–791 under the `['auth','verified']` middleware group and `lms-home-work` prefix.

### D. Effort Estimation

| Priority | Items | Hours |
|---|---|---|
| P0 — Critical (BUG-01 through BUG-07) | 7 bugs | 6–10 hours |
| P1 — High (BUG-08 to BUG-12, NFR improvements) | 8 items | 12–20 hours |
| P2 — Feature completion (student portal, rule engine, auto-release) | 5 features | 40–60 hours |
| P3 — Tests + polish | 30 tests + cleanup | 16–24 hours |
| **Total** | | **74–114 hours (~9–14 dev days)** |

---

## 16. V1 → V2 Delta

| Area | V1 Status | V2 Correction/Addition |
|---|---|---|
| `HoemworkData()` bug | Reported as FATAL missing `$request` parameter | Verified in code: parameter IS present (line 52). Downgraded to LOW — only a naming typo. |
| `HomeworkAssignment` model | Not mentioned in V1 | Discovered in V2: model exists, table missing from DDL — CRITICAL gap |
| `publish()` method | Not in V1 | Discovered in V2: fully implemented, creates per-student assignments |
| `release_condition` schema | V1 described as FK to sys_dropdown | V2 finds model uses string ENUM fillable, creating mismatch with DDL INT FK |
| `schedule_id` column | Not in V1 | V2 finds in model `$fillable` but absent from DDL |
| `lms_homework_assignment` DDL | Not documented | V2 confirms table missing; proposed DDL column spec documented |
| `TriggerEventPolicy` | Not noted | V2 confirms policy file absent |
| `sys_rule_action_map` model | Noted as missing | Confirmed missing in V2 with DDL schema documented |
| `sys_rule_execution_log` model | Noted as missing | Confirmed missing in V2 with DDL schema documented |
| DDL FK name mismatches (sys_rule tables) | Not noted | V2 identifies old lms_ prefix in FK constraints |
| Bug count | V1: 8 bugs | V2: 18 bugs (10 new discovered) |
| Model imports in `Homework.php` | V1 noted Builder missing | V2 confirms Builder IS imported (line 5); downgraded. Other unused imports remain. |
| academicSession() bug | V1 reported as referencing SchAcademicSession | V2 confirms it uses AcademicSession::class correctly (line 11). Bug does not exist. |
| Functional completeness | ~60% | ~62% (publish workflow added since V1) |
