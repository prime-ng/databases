# LmsHomework Module — Requirement Specification Document

**Version:** 1.0 | **Date:** 2026-03-25 | **Author:** Claude Code (Automated Extraction)
**Platform:** Prime-AI Academic Intelligence Platform
**Module Code:** HMW | **Module Path:** `Modules/LmsHomework`
**Module Type:** Tenant | **Database:** tenant_db
**Table Prefix:** `lms_homework*` | **Processing Mode:** FULL
**RBS Reference:** Module S — Learning Management System (LMS)

---

## 1. EXECUTIVE SUMMARY

LmsHomework is the homework assignment and submission management module of Prime-AI. It allows teachers to create graded or un-graded homework tasks aligned to subjects, lessons, and topics with configurable deadlines and late-submission policies. Students (once the portal is built) can submit text, files, or both. Teachers review and grade submissions. A Rule Engine framework (TriggerEvent + ActionType + RuleEngineConfig) exists to automate notifications and actions on homework lifecycle events.

**Current implementation status: ~60% complete.**

The teacher-facing homework creation flow and the admin-facing rule engine configuration are functional. Student submission creation via admin UI exists. However, the most critical production blocker is the **FATAL BUG** in `LmsHomeworkController::HoemworkData()`: the method is missing its `$request` parameter entirely, causing a PHP fatal error on any page load (undefined variable `$request` inside the method body). The `review()` method in `HomeworkSubmissionController` has zero authorization checks and zero input validation. No `EnsureTenantHasModule` middleware is present.

**Stats:**
- Controllers: 5 | Models: 5 | Services: 0 | FormRequests: 5 | Tests: 0
- Database tables: `lms_homework`, `lms_homework_submissions` (with `lms_trigger_events`, `lms_action_types`, `lms_rule_engine_configs` if separate)

---

## 2. MODULE OVERVIEW

### Business Purpose
Enable teachers to assign homework to classes/sections/students with configurable submission windows. Track student submissions, detect late submissions automatically, and allow teacher grading and feedback. Optionally trigger automated actions (notifications, LXP points, etc.) via the Rule Engine on homework lifecycle events.

### Key Features
1. Homework creation with subject/lesson/topic alignment
2. Configurable submission types: TEXT, FILE, HYBRID, OFFLINE_CHECK
3. Gradable/non-gradable homework with max/passing marks
4. Assign date + due date scheduling
5. Late submission policy (allow/deny)
6. Auto-publish score toggle
7. Release conditions (IMMEDIATE or ON_TOPIC_COMPLETE)
8. Submission tracking with late flag auto-computation
9. File attachment via Spatie Media Library
10. Teacher grading (marks_obtained + feedback)
11. Rule Engine: trigger events + action types + rule configurations

### Menu Path
`LMS > Homework`

### Architecture
Tab-based single-page interface via `LmsHomeworkController::index()`. All sub-entities (homeworks, submissions, trigger events, action types, rule configs) load in one request. Individual CRUD is handled by separate controllers under the `lms-home-work.*` route prefix.

---

## 3. STAKEHOLDERS & ACTORS

| Actor | Role |
|---|---|
| Teacher | Creates homework, sets deadline, reviews and grades submissions |
| Admin | Manages rule engine configuration, trigger events, action types |
| Student | (Partially implemented via admin UI) Submits homework text or file |
| Parent | (Absent) Views child's homework status |
| Rule Engine | Automated system that fires actions on trigger events (notification, badge, etc.) |

---

## 4. FUNCTIONAL REQUIREMENTS

### FR-HMW-001: Trigger Event Management
**RBS Reference:** S3 (Assessment Management — automation) | **Priority:** Medium | **Status:** Implemented
**Tables:** `lms_trigger_events` (assumed table name from TriggerEvent model)

**Description:** Defines automation trigger points in the homework lifecycle (e.g., HOMEWORK_ASSIGNED, HOMEWORK_SUBMITTED, HOMEWORK_GRADED, DEADLINE_PASSED).

**Actors:** Admin
**Input:** code, name, description, status

**Current Implementation:**
- `TriggerEventController` — full CRUD + trashed/restore/forceDelete/toggleStatus
- Model: `Modules\LmsHomework\Models\TriggerEvent`
- Route: `lms-home-work.trigger-event.*`

**Required Test Cases:**
- TC-HMW-001-01: Create duplicate trigger event code — expect validation error
- TC-HMW-001-02: Soft delete and restore

---

### FR-HMW-002: Action Type Management
**RBS Reference:** S3 | **Priority:** Medium | **Status:** Implemented
**Tables:** `lms_action_types`

**Description:** Defines what automated action to take when a trigger fires (e.g., SEND_NOTIFICATION, AWARD_LXP_POINTS, SEND_EMAIL, MARK_LATE).

**Actors:** Admin
**Input:** code, name, description, status

**Current Implementation:**
- `ActionTypeController` — full CRUD + trashed/restore/forceDelete/toggleStatus
- Model: `Modules\LmsHomework\Models\ActionType`
- Route: `lms-home-work.action-types.*`

---

### FR-HMW-003: Rule Engine Configuration
**RBS Reference:** S3 | **Priority:** Medium | **Status:** Implemented
**Tables:** `lms_rule_engine_configs`

**Description:** Binds a TriggerEvent to an ActionType with rule conditions. Configuration includes rule_code, rule_name, trigger_event_id, action_type_id, and status.

**Actors:** Admin
**Input:** rule_code, rule_name, trigger_event_id, action_type_id, status

**Current Implementation:**
- `RuleEngineConfigController` — full CRUD + trashed/restore/forceDelete/toggleStatus
- Model: `Modules\LmsHomework\Models\RuleEngineConfig`
- Route: `lms-home-work.rule-engine-configs.*`

---

### FR-HMW-004: Homework Creation
**RBS Reference:** S3 (S3.2 — Assignment Management) | **Priority:** Critical | **Status:** Implemented (with FATAL BUG)
**Tables:** `lms_homework`

**Description:** Teacher creates a homework task aligned to an academic session, class, section, subject, lesson, and optional topic. Sets submission type, grading config, schedule, and policies.

**Actors:** Teacher, Admin
**Input:** class_id, section_id (optional), subject_id, lesson_id, topic_id, title, description (HTML), submission_type_id, is_gradable, max_marks, passing_marks, difficulty_level_id, assign_date, due_date, allow_late_submission, auto_publish_score, release_condition_id, status_id
**Processing:**
- `academic_session_id` set from current active session
- `created_by` and `updated_by` set from Auth::id()
- SoftDeletes enabled

**Output:** New homework record; redirect to index

**KNOWN BUG — FATAL:**
```php
// LmsHomeworkController.php line 49-62
public function HoemworkData()   // <-- MISSING $request parameter
{
    $query = Homework::query();
    if (isset($request->class)) {  // <-- $request is UNDEFINED — PHP fatal error
        $query->where('class_id', $request->class);
    }
    if (isset($request->subject_id)) {  // <-- same issue
    ...
```
The method `HoemworkData()` is called by `index()` as `$this->HoemworkData($request)` on line 36, passing `$request` as an argument. But the method signature declares no parameters. Inside the method body, `$request` is used as though it were injected — but it is never received. This causes an `Undefined variable $request` notice (or fatal in strict mode) and silently falls back to no filtering, returning all records unfiltered.

**Additional Issues:**
- Method name is a typo: `HoemworkData` instead of `HomeworkData`
- No `DB::beginTransaction()` in store() — partial failure leaves orphaned records

**Acceptance Criteria:**
- `HoemworkData(Request $request)` parameter must be added
- Method name should be corrected to `getHomeworkData`
- store() should be wrapped in a DB transaction

**Current Implementation:**
- `LmsHomeworkController::create()`, `store()`, `show()`, `edit()`, `update()`, `destroy()`, `trashed()`, `restore()`, `forceDelete()`, `toggleStatus()`, `getStudentsByClass()`
- Model: `Modules\LmsHomework\Models\Homework`, table `lms_homework`
- Route: `lms-home-work.home-works.*`

---

### FR-HMW-005: Homework Submission — Student Side
**RBS Reference:** S3.2.1 | **Priority:** Critical | **Status:** Partially implemented (admin UI only; no student portal)
**Tables:** `lms_homework_submissions`

**Description:** A student submits their homework response (text, file attachment, or both) before the due date. The system auto-computes the `is_late` flag by comparing `now()` to `homework.due_date`.

**Actors:** Student (absent from portal), Admin (can create on behalf)
**Input:** homework_id, student_id, submission_text, attachment (file)
**Processing:**
- Checks `homework.due_date` to set `is_late = true` if `now() > due_date`
- If `allow_late_submission = 0` and `is_late = true`, submission should be blocked (currently NOT enforced)
- File stored via Spatie Media Library to collection `homework_submission_files`
- `submitted_at` = now()

**Acceptance Criteria:**
- Late submission must be blocked when `allow_late_submission = 0` and current time is past `due_date`
- UNIQUE constraint (homework_id, student_id) must prevent duplicate submissions
- File upload should support PDF, DOCX, image formats

**Current Implementation:**
- `HomeworkSubmissionController::store()` — creates submission, handles file attachment
- Model: `Modules\LmsHomework\Models\HomeworkSubmission`
- Route: `lms-home-work.homework-submission.*`

---

### FR-HMW-006: Homework Grading / Review
**RBS Reference:** S3.2.2 | **Priority:** Critical | **Status:** Implemented (ZERO SECURITY — BUG)
**Tables:** `lms_homework_submissions`

**Description:** Teacher opens a submitted homework, enters marks_obtained, teacher_feedback, changes status. System records graded_by and graded_at.

**Actors:** Teacher

**KNOWN BUG — SECURITY:**
```php
// HomeworkSubmissionController::review() lines 285-299
public function review(Request $request, $id)
{
    $submission = HomeworkSubmission::findOrFail($id);
    $submission->update([
        'status_id' => $request->status_id,
        'marks_obtained' => $request->marks_obtained,
        'teacher_feedback' => $request->teacher_feedback,
        'graded_by' => auth()->id(),
        'graded_at' => now(),
    ]);
    // NO authorization check (any logged-in user can grade any submission)
    // NO input validation (marks_obtained not checked against max_marks)
    // NO Gate::authorize()
```

**Required fixes:**
1. Add `Gate::authorize('tenant.homework-submission.grade')` or equivalent policy check
2. Validate `marks_obtained` <= `homework.max_marks`
3. Validate `marks_obtained` >= 0
4. Validate `status_id` exists in valid submission statuses

**Acceptance Criteria:**
- Only the teacher who created the homework (or Admin) can grade it
- `marks_obtained` must not exceed `max_marks`
- `auto_publish_score = 1` on the homework should trigger student notification

**Current Implementation:**
- `HomeworkSubmissionController::review()` — AJAX PUT endpoint
- Route: `PUT lms-home-work/homework-submission/review/{review}` → `lms-home-work.homework-submission.review`

---

### FR-HMW-007: Student Homework Portal (ABSENT)
**RBS Reference:** S3.2.1 | **Priority:** High | **Status:** NOT IMPLEMENTED

**Description (proposed):** Student-facing view to see assigned homework, submit responses, and view grades. Requires a dedicated student portal route group with student authentication context.

**Required (to be created):**
- `StudentHomeworkController` — myHomework (list), viewHomework (detail), submitHomework, viewResult
- Student-specific views showing homework aligned to their class/section

---

## 5. DATA MODEL & ENTITY SPECIFICATION

### lms_homework
| Column | Type | Notes |
|---|---|---|
| id | INT UNSIGNED PK | AUTO_INCREMENT |
| academic_session_id | INT UNSIGNED | FK sch_academic_sessions NOT NULL |
| class_id | INT UNSIGNED | FK sch_classes NOT NULL |
| section_id | INT UNSIGNED | FK sch_sections NULL (NULL=all sections) |
| subject_id | INT UNSIGNED | FK sch_subjects NOT NULL |
| lesson_id | INT UNSIGNED | FK slb_lessons NULL |
| topic_id | INT UNSIGNED | FK slb_topics NULL |
| title | VARCHAR(255) | NOT NULL |
| description | LONGTEXT | HTML/Markdown |
| submission_type_id | INT UNSIGNED | FK sys_dropdown (TEXT/FILE/HYBRID/OFFLINE_CHECK) |
| is_gradable | TINYINT(1) | DEFAULT 1 |
| max_marks | DECIMAL(5,2) | NULL |
| passing_marks | DECIMAL(5,2) | NULL |
| difficulty_level_id | INT UNSIGNED | FK slb_complexity_level NULL |
| assign_date | DATETIME | NOT NULL |
| due_date | DATETIME | NOT NULL |
| allow_late_submission | TINYINT(1) | DEFAULT 0 |
| auto_publish_score | TINYINT(1) | DEFAULT 0 |
| release_condition_id | INT UNSIGNED | FK sys_dropdown NULL (IMMEDIATE/ON_TOPIC_COMPLETE) |
| status_id | INT UNSIGNED | FK sys_dropdown (DRAFT/PUBLISHED/ARCHIVED) |
| created_by | INT UNSIGNED | FK sys_users NOT NULL |
| updated_by | INT UNSIGNED | FK sys_users NULL |
| is_active, created_at, updated_at, deleted_at | standard | |
| INDEX | (class_id, subject_id) | idx_hw_class_sub |

**Model:** `Modules\LmsHomework\Models\Homework`
- Relationships: class, section, subject, lesson, topic, submissionType, difficultyLevel, releaseCondition, status, createdBy, updatedBy, submissions (HasMany)
- Scopes: search, byStatus, byClass, bySubject, byAcademicSession, published, upcoming, ongoing, overdue
- Computed attributes: status (UPCOMING/ONGOING/OVERDUE), submission_count, graded_count
- **Bug in model:** `academicSession()` relation references `SchAcademicSession::class` which is an undefined class (should be `AcademicSession::class`)
- **Bug in model:** `scopeSearch` and `scopeByStatus` type-hint `Builder` without importing it

### lms_homework_submissions
| Column | Type | Notes |
|---|---|---|
| id | INT UNSIGNED PK | |
| homework_id | INT UNSIGNED | FK lms_homework CASCADE |
| student_id | INT UNSIGNED | FK sys_users (student) |
| submitted_at | DATETIME | DEFAULT CURRENT_TIMESTAMP |
| submission_text | LONGTEXT | NULL |
| attachment_media_id | INT UNSIGNED | FK sys_media NULL (Spatie) |
| status_id | INT UNSIGNED | FK sys_dropdown (SUBMITTED/CHECKED/REJECTED) |
| marks_obtained | DECIMAL(5,2) | NULL |
| teacher_feedback | TEXT | NULL |
| graded_by | INT UNSIGNED | FK sys_users NULL |
| graded_at | DATETIME | NULL |
| is_late | TINYINT(1) | DEFAULT 0 (auto-computed) |
| created_at, updated_at, deleted_at | standard | |
| **UNIQUE** | (homework_id, student_id) | one submission per student per homework |

**Model:** `Modules\LmsHomework\Models\HomeworkSubmission`
- Relationships: homework (BelongsTo), student (BelongsTo), status (BelongsTo)
- Uses Spatie Media Library (`InteractsWithMedia`) for attachment handling
- Collection name: `homework_submission_files`

---

## 6. API & ROUTE SPECIFICATION

**Route Prefix:** `/lms-home-work` | **Name Prefix:** `lms-home-work.`
**Middleware:** `auth`, `verified` (NOTE: `EnsureTenantHasModule` is MISSING)

| Method | URI | Name | Controller | Action |
|---|---|---|---|---|
| GET | /lms-home-work/home-works | lms-home-work.home-works.index | LmsHomeworkController | Tab view (all data) |
| GET | /lms-home-work/home-works/create | lms-home-work.home-works.create | LmsHomeworkController | Create form |
| POST | /lms-home-work/home-works | lms-home-work.home-works.store | LmsHomeworkController | Store |
| GET | /lms-home-work/home-works/{id} | lms-home-work.home-works.show | LmsHomeworkController | Show |
| GET | /lms-home-work/home-works/{id}/edit | lms-home-work.home-works.edit | LmsHomeworkController | Edit form |
| PUT | /lms-home-work/home-works/{id} | lms-home-work.home-works.update | LmsHomeworkController | Update |
| DELETE | /lms-home-work/home-works/{id} | lms-home-work.home-works.destroy | LmsHomeworkController | Soft delete |
| GET | /lms-home-work/home-works/trash/view | lms-home-work.home-works.trashed | LmsHomeworkController | Trash list |
| GET | /lms-home-work/home-works/{id}/restore | lms-home-work.home-works.restore | LmsHomeworkController | Restore |
| DELETE | /lms-home-work/home-works/{id}/force-delete | lms-home-work.home-works.forceDelete | LmsHomeworkController | Force delete |
| POST | /lms-home-work/home-works/{id}/toggle-status | lms-home-work.home-works.toggleStatus | LmsHomeworkController | Toggle active |
| POST | /lms-home-work/get-students-by-class | lms-home-work.get-students-by-class | LmsHomeworkController | AJAX: students for class |
| (resource) | /lms-home-work/trigger-event | lms-home-work.trigger-event.* | TriggerEventController | Full CRUD |
| (resource) | /lms-home-work/homework-submission | lms-home-work.homework-submission.* | HomeworkSubmissionController | Full CRUD |
| PUT | /lms-home-work/homework-submission/review/{id} | lms-home-work.homework-submission.review | HomeworkSubmissionController | Grade (AJAX) |
| (resource) | /lms-home-work/action-types | lms-home-work.action-types.* | ActionTypeController | Full CRUD |
| (resource) | /lms-home-work/rule-engine-configs | lms-home-work.rule-engine-configs.* | RuleEngineConfigController | Full CRUD |

---

## 7. UI SCREEN INVENTORY & FIELD MAPPING

| Screen | View File | Purpose |
|---|---|---|
| Homework Hub (tab) | `lmshome-work/index.blade.php` | Main tab container |
| Homework Create | `home-work/create.blade.php` | Title, class, subject, topic, dates, flags |
| Homework Edit | `home-work/edit.blade.php` | Same + section, lesson cascade |
| Homework Show | `home-work/show.blade.php` | Detail view |
| Homework Trash | `home-work/trash.blade.php` | Soft-deleted list |
| Homework List | `home-work/index.blade.php` | Standalone list |
| Submission List | `submission/index.blade.php` | Filter by homework, student, status, late |
| Submission Create | `submission/create.blade.php` | Student select, text input, file upload |
| Submission Edit | `submission/edit.blade.php` | Grade entry (marks, feedback, status) |
| Submission Show | `submission/show.blade.php` | Detail view with attachment |
| Submission Trash | `submission/trash.blade.php` | |
| Trigger Events | `trigger-event/{create,edit,index,show,trash}.blade.php` | Master data |
| Action Types | `action-type/{create,edit,index,show,trash}.blade.php` | Master data |
| Rule Engine Config | `rule-engine-config/{create,edit,index,show,trash}.blade.php` | Rule binding |

---

## 8. BUSINESS RULES & DOMAIN CONSTRAINTS

1. **One submission per student per homework:** UNIQUE (homework_id, student_id) on lms_homework_submissions.
2. **Late submission detection:** `is_late` flag is set to true when `submitted_at > homework.due_date`. This happens at submission time in `HomeworkSubmissionController::store()`.
3. **Late submission blocking:** When `allow_late_submission = 0`, the system MUST reject submissions after `due_date`. Currently NOT enforced — this is a gap.
4. **Gradable constraint:** `marks_obtained` must only be set if `homework.is_gradable = 1`.
5. **Auto-publish score:** When `auto_publish_score = 1`, once `marks_obtained` is set, the student should see their score immediately.
6. **Release conditions:** `ON_TOPIC_COMPLETE` release condition means the homework should only become visible to the student after they complete the associated topic (requires LXP tracking, currently absent).
7. **Submission type enforcement:** submission_text must be provided for TEXT type; attachment for FILE type; either for HYBRID.
8. **Homework deletable only if no submissions:** The `isDeletable()` model method enforces this (`submission_count == 0`).
9. **Homework editable only in DRAFT status:** The `isEditable()` model method checks `status_id == config('lmshomework.status.draft')`.

---

## 9. WORKFLOW & STATE MACHINE DEFINITIONS

### Homework Lifecycle
```
[Create Homework] (DRAFT)
     ↓
[PUBLISH Homework]
     ↓
[assign_date reached] → Homework becomes visible to students
     ↓
[Student Submits] (before or after due_date)
  ├── is_late = 0 if before due_date
  └── is_late = 1 if after due_date (if allowed)
     ↓
[Teacher Reviews Submission]
     ├── Enter marks_obtained
     ├── Enter teacher_feedback
     └── Change status: SUBMITTED → CHECKED (or REJECTED)
     ↓
[auto_publish_score = 1] → Score visible to student immediately
     ↓
[ARCHIVED]
```

### Submission Status States
```
(not yet submitted) → SUBMITTED → CHECKED
                                → REJECTED → (student can resubmit?)
```

### Rule Engine Flow
```
[Homework Event Fires] (e.g., HOMEWORK_SUBMITTED)
     ↓
[Rule Engine checks lms_rule_engine_configs]
     ↓ match found
[Execute ActionType] (e.g., SEND_NOTIFICATION → student notified)
```

---

## 10. NON-FUNCTIONAL REQUIREMENTS

| # | Requirement | Target |
|---|---|---|
| NFR-HMW-01 | File upload size limit | 10MB max per attachment |
| NFR-HMW-02 | File types allowed | PDF, DOCX, JPG, PNG, ZIP |
| NFR-HMW-03 | Due date enforcement | Server-side check, not client-side only |
| NFR-HMW-04 | Grading by teacher only | Policy-enforced, not just UI-restricted |
| NFR-HMW-05 | Audit trail | All grading actions logged via activityLog() |
| NFR-HMW-06 | EnsureTenantHasModule middleware | Must be added to route group |

---

## 11. CROSS-MODULE DEPENDENCIES

| Module | Dependency Type | Detail |
|---|---|---|
| **SchoolSetup** | FK DEPENDENCY | `sch_classes`, `sch_sections`, `sch_subjects` used throughout |
| **Syllabus** | FK DEPENDENCY | `slb_lessons`, `slb_topics`, `slb_complexity_level` for alignment |
| **StudentProfile** | FK DEPENDENCY | `std_students` (student_id in submissions) |
| **Prime (Academic)** | FK DEPENDENCY | `glb_academic_sessions` |
| **sys_dropdown** | FK DEPENDENCY | submission_type_id, release_condition_id, status_id all reference sys_dropdown_table |
| **sys_media (Spatie)** | SHARED SERVICE | `attachment_media_id` FK to sys_media; file uploads via Spatie Media Library |
| **Notifications Module** | RUNTIME DEPENDENCY | Rule Engine ActionType SEND_NOTIFICATION depends on notification system |

---

## 12. TEST CASE REFERENCE & COVERAGE

**Current test coverage: 0 tests**

### Proposed Test Plan

**Unit Tests:**
- `HomeworkLateFlagTest` — verify is_late computed correctly for on-time and late submissions
- `HomeworkScoreValidationTest` — marks_obtained <= max_marks

**Feature Tests:**
- `HomeworkCreationTest` — happy path, missing required fields, DRAFT vs PUBLISHED
- `HomeworkSubmissionTest` — on-time submission, late with allow, late without allow (should reject)
- `HomeworkGradingTest` — grade by authorized teacher, grade by unauthorized user (should 403)
- `HoemworkDataParameterTest` — verify the FATAL BUG is fixed (method accepts Request)
- `ReviewAuthorizationTest` — verify review() has Gate check after fix
- `DuplicateSubmissionTest` — second submission by same student should fail

---

## 13. GLOSSARY & TERMINOLOGY

| Term | Meaning |
|---|---|
| Homework | A teacher-assigned task for students to complete outside class |
| Submission | A student's response to a homework task (text, file, or both) |
| Gradable | Homework that carries marks; non-gradable is for completion tracking only |
| Late Submission | A submission made after the `due_date` |
| Auto-Publish Score | Setting that shows student their marks immediately after grading |
| Release Condition | Trigger that controls when homework becomes visible to student |
| Rule Engine | The automation framework binding trigger events to actions |
| Trigger Event | A lifecycle event in homework flow (assigned, submitted, graded, etc.) |
| Action Type | The action to execute when trigger fires (notify, award points, etc.) |

---

## 14. ADDITIONAL SUGGESTIONS

1. **Fix FATAL BUG first:** Change `public function HoemworkData()` to `public function getHomeworkData(Request $request)` and update all callers.
2. **Secure review() immediately:** Add Gate authorization and validate marks_obtained <= homework.max_marks.
3. **Enforce late submission blocking:** In `HomeworkSubmissionController::store()`, check `allow_late_submission` before creating submission.
4. **Fix model import:** `Homework::academicSession()` references undefined `SchAcademicSession` — should be `AcademicSession::class`.
5. **Fix scope methods:** Add `use Illuminate\Database\Eloquent\Builder;` import in `Homework` model.
6. **Add `EnsureTenantHasModule` middleware** to the `lms-home-work` route group.
7. **Wrap store() in DB transaction** for homework creation.
8. **Build student-facing portal** as the primary remaining work: view assigned homeworks, submit, view grade.
9. **Implement Rule Engine execution** — currently the configuration exists but no execution engine fires the actions.
10. **Consider a `HomeworkService`** to centralize: publishHomework, gradeSubmission, computeStats.

---

## 15. APPENDICES

### A. File Inventory
```
Modules/LmsHomework/
├── app/Http/Controllers/
│   ├── LmsHomeworkController.php        (tab hub + Homework CRUD, FATAL BUG on line 49)
│   ├── HomeworkSubmissionController.php  (CRUD + review AJAX, no auth on review)
│   ├── TriggerEventController.php        (CRUD)
│   ├── ActionTypeController.php          (CRUD)
│   └── RuleEngineConfigController.php    (CRUD)
├── app/Models/
│   ├── Homework.php    (undefined class SchAcademicSession, missing Builder import)
│   ├── HomeworkSubmission.php
│   ├── TriggerEvent.php
│   ├── ActionType.php
│   └── RuleEngineConfig.php
├── app/Http/Requests/ [5 FormRequests]
├── app/Policies/ [ActionTypePolicy, HomeworkPolicy, HomeworkSubmissionPolicy, RuleEngineConfigPolicy]
├── resources/views/ [~25 blade files across 6 folders]
└── routes/web.php (minimal — main routes in tenant.php lines 782-825)
```

### B. Route Group Location
All functional routes for LmsHomework are defined in `/Users/bkwork/Herd/prime_ai/routes/tenant.php` lines 782–825 under the `lms-home-work` prefix group.

### C. Known Bugs Summary
| Bug | Location | Severity |
|---|---|---|
| `HoemworkData()` missing `$request` parameter | LmsHomeworkController line 49 | CRITICAL — runtime fatal error |
| `review()` has zero authorization + zero validation | HomeworkSubmissionController lines 285-299 | CRITICAL SECURITY |
| `academicSession()` references undefined `SchAcademicSession` | Homework model line 71 | HIGH — runtime fatal |
| `Builder` not imported in Homework model scopes | Homework model lines 137-186 | HIGH — fatal on scope use |
| Late submission not blocked when `allow_late_submission=0` | HomeworkSubmissionController::store() | HIGH — business rule gap |
| `EnsureTenantHasModule` middleware missing | Route group | MEDIUM |
| No student-facing portal | Entire student pipeline | HIGH |
| Rule Engine not executed | No execution engine exists | MEDIUM |
| 0 tests | All controllers | HIGH |
