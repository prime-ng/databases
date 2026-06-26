# EXM — LMS Exam
## Module Requirement Document V2
**Version:** 2.0 | **Date:** 2026-03-26 | **Status:** Draft | **Mode:** FULL
**Module Code:** EXM | **Module Type:** Tenant | **Table Prefix:** `lms_exam*`
**Platform:** Laravel 12 + PHP 8.2 + MySQL 8.x | **Multi-tenancy:** stancl/tenancy v3.9
**Module Path:** `Modules/LmsExam/` | **RBS Reference:** Module S — LMS

---

## 1. Executive Summary

LmsExam is the online and offline examination management module of Prime-AI. It covers the complete lifecycle of school examinations: defining exam types and lifecycle statuses, creating exam blueprints and paper structures per subject, populating question paper sets from the Question Bank, allocating papers to student groups with scheduling, conducting online or offline exams, entering marks, computing graded results, and publishing results to students and parents.

**Current implementation: ~65% complete.**

The teacher-facing setup pipeline (exam creation, paper design, blueprint, scope, paper sets, question assignment, student groups, allocations) is substantially implemented with 11 controllers and 11 models. The student-facing attempt and grading pipeline is entirely absent — no attempt, result, grievance, or report card controllers exist. Four critical defects must be resolved before any production deployment.

**Implementation snapshot:**

| Artifact | Count |
|---|---|
| Controllers | 11 (implemented) + 5 (to be built) |
| Models | 11 (implemented) + 5 (to be built) |
| Services | 0 (all to be extracted) |
| FormRequests | 11 |
| Policies | 11 (2 with Gate disabled) |
| Test files | 0 |
| DDL tables covered by code | 11 of 17 |

**Critical defects requiring immediate action:**

| ID | Defect | Location | Severity |
|---|---|---|---|
| BUG-01 | `dd($e)` before `DB::rollBack()` — halts execution, exposes stack trace | LmsExamController::store() line 565 | CRITICAL |
| BUG-02 | ALL Gate::authorize() calls commented out | ExamBlueprintController (10 calls) | CRITICAL SECURITY |
| BUG-03 | ALL Gate::authorize() calls commented out | ExamScopeController (10 calls) | CRITICAL SECURITY |
| BUG-04 | No `EnsureTenantHasModule` middleware on route group | routes/tenant.php line 520 | HIGH |

---

## 2. Module Overview

### 2.1 Business Purpose

Enable schools to manage their examination calendar end-to-end: define exam events, design question papers in multiple variants (sets), allocate them to student groups with scheduled timings, allow online or offline execution, and produce graded results with rank, grade, and report card PDF generation.

### 2.2 Key Feature Groups

| Group | Features | Status |
|---|---|---|
| Master Configuration | Exam types, status events | ✅ Complete |
| Exam Setup | Exam creation, paper design, blueprints, scopes, paper sets | ✅ Complete (with BUG-01) |
| Question Assignment | Question bank integration, bulk add, reorder, marks override | ✅ Complete |
| Scheduling & Allocation | Student groups, group members, paper-to-student allocation | ✅ Complete |
| Online Exam Player | Timed attempt, answer saving, proctoring hooks, auto-submit | ❌ Not started |
| Offline Marks Entry | Roster-based bulk entry, question-wise entry | ❌ Not started |
| Grading & Results | Marks computation, grade lookup, result publication | ❌ Not started |
| Grievance Management | Student re-evaluation requests, marks correction | ❌ Not started |
| Analytics | Class-wise performance, rank computation, report cards | ❌ Not started |

### 2.3 Menu Path

`LMS > Exam Management`

### 2.4 Architecture

Tab-based single-page interface driven by `LmsExamController::index()` which loads all sub-entities in a single paginated request. Individual CRUD operations are handled by separate resource controllers under the `lms-exam.*` route prefix. The existing architecture has no Service layer; all business logic resides in controllers.

---

## 3. Stakeholders & Roles

| Actor | Permissions | Notes |
|---|---|---|
| Admin / Principal | Full CRUD on all entities; publish and conclude exams; view all results | Final authority on result publication |
| Exam Coordinator | Create exams, papers, allocations; enter offline marks | Typically a class teacher or HOD |
| Subject Teacher | Define blueprints, scopes, paper sets; assign questions; enter marks for own subject | Cannot publish results |
| Student | View allocated exams; take online exam; view published results | Not yet implemented |
| Parent | View child's published results and report card | Not yet implemented |
| QuestionBank Module | Source of questions via `qns_questions_bank` | Consumed, not a human actor |

---

## 4. Functional Requirements

### FR-EXM-001: Exam Type Management
**Priority:** High | **Status:** ✅ Implemented
**Tables:** `lms_exam_types`

**Description:** CRUD management of exam categories (UT-1, UT-2, HY-EXAM, ANNUAL-EXAM, etc.). These categories are used as a classification FK in `lms_exams`.

**Actors:** Admin
**Input Fields:** `code` (VARCHAR 50, UNIQUE), `name` (VARCHAR 100), `description` (VARCHAR 255)
**Processing:** Soft delete lifecycle; code uniqueness enforced at DB level via `UNIQUE KEY`.
**Output:** Exam type list used as FK in lms_exams.exam_type_id

**Acceptance Criteria:**
- Code must be unique across all exam types; duplicate code returns validation error
- Soft delete sets `deleted_at` and `is_active=0`; restore sets `is_active=1`
- toggleStatus endpoint responds with JSON `{status, is_active}` for AJAX calls
- Missing `created_by` on model — must be added (gap from gap analysis)

**Implementation:**
- Controller: `ExamTypeController` — index/create/store/show/edit/update/destroy/trashed/restore/forceDelete/toggleStatus
- Model: `Modules\LmsExam\Models\ExamType`, table: `lms_exam_types`
- FormRequest: `ExamTypeRequest`, Policy: `ExamTypePolicy`
- Routes: `lms-exam.exam-type.*`

**Known Gap:** 🟡 `ExamType` model missing `created_by` attribute and fillable entry.

---

### FR-EXM-002: Exam Status Event Management
**Priority:** High | **Status:** ✅ Implemented
**Tables:** `lms_exam_status_events`

**Description:** Master table of lifecycle statuses for exams, papers, results, and attempts. Each status event is typed by `event_type` ENUM and carries a `action_logic` JSON field containing transition rules.

**Actors:** Admin
**Input Fields:** `code` (UNIQUE), `name`, `event_type` ENUM('EXAM','PAPER','RESULT','ATTEMPT'), `action_logic` JSON, `description`
**Processing:** `event_type` determines which entity can reference this status.

**Standard Status Sequences:**
- EXAM statuses: DRAFT → PUBLISHED → CONCLUDED → ARCHIVED
- PAPER statuses: NOT_STARTED → IN_PROGRESS → SUBMITTED → EVALUATION_PENDING → EVALUATED → RESULT_PUBLISHED
- ATTEMPT statuses: NOT_STARTED → IN_PROGRESS → SUBMITTED → ABSENT / CANCELLED

**Implementation:**
- Controller: `ExamStatusEventController` — full CRUD + trashed/restore/forceDelete/toggleStatus
- Model: `Modules\LmsExam\Models\ExamStatusEvent`
- Routes: `lms-exam.exam-status-event.*`

**Known Gap:** 🟡 `ExamStatusEvent` model missing `created_by` attribute.

---

### FR-EXM-003: Exam Creation
**Priority:** Critical | **Status:** 🟡 Implemented with critical bug
**Tables:** `lms_exams`

**Description:** Teacher/Admin creates an exam event binding an academic session, class, exam type, date range, grading schema, and initial status (DRAFT).

**Actors:** Admin, Exam Coordinator
**Input Fields:** `academic_session_id`, `class_id`, `exam_type_id`, `title`, `start_date`, `end_date`, `grading_schema_id`, `status_id`, `description`
**Processing:**
- Auto-generates code: `EXAM_{session_code}_{class_code}_{type_code}_{random6}`
- Wraps entire store in `DB::beginTransaction()` / `DB::commit()`
- Writes activity log on success

**Critical Bug — BUG-01:**
```
LmsExamController::store() line 565:
} catch (\Exception $e) {
    dd($e);          // FATAL: halts PHP, exposes stack trace, blocks rollback
    DB::rollBack();  // UNREACHABLE — never executes
    return redirect()->back()...  // UNREACHABLE
```
Consequences:
1. On any store exception, the transaction is never rolled back (partial writes may persist)
2. Raw PHP dump shown to browser user — exposes database schema, credentials path, file paths
3. The redirect-with-error never executes — page dies with a dump

**Fix Required:**
```php
} catch (\Exception $e) {
    DB::rollBack();
    logger()->error('Exam store failed: ' . $e->getMessage(), ['trace' => $e->getTraceAsString()]);
    return redirect()->back()->withInput()->with('error', 'Failed to create exam. Please try again.');
}
```

**Acceptance Criteria:**
- `dd($e)` removed before any production deployment
- On exception: rollback executes, safe error flash displayed, full trace logged server-side only
- Code uniqueness enforced at DB: UNIQUE KEY `uq_exam_code` on `lms_exams.code`
- One exam per session+class+type: UNIQUE KEY on `(academic_session_id, class_id, exam_type_id)`
- Only Admin / Exam Coordinator can create; students cannot

**Implementation:**
- Controller: `LmsExamController` (820 lines) — index/create/store/show/edit/update/destroy/trashed/restore/forceDelete/toggleStatus
- Model: `Modules\LmsExam\Models\Exam`
- FormRequest: `ExamRequest`, Policy: `ExamPolicy`
- Routes: `lms-exam.exam.*`

**Performance Gap:** 🟡 `index()` loads all questions (`QuestionBank::where('is_active','1')->get()`) and all students (`Student::where('is_active','1')->get()`) into memory — must be replaced with AJAX search or paginated selects.

---

### FR-EXM-004: Exam Paper Creation
**Priority:** Critical | **Status:** ✅ Implemented
**Tables:** `lms_exam_papers`

**Description:** Creates a specific paper within an exam for one subject and one mode (ONLINE/OFFLINE). Defines marks, duration, proctoring configuration, result display rules, and difficulty distribution config.

**Actors:** Subject Teacher, Exam Coordinator
**Input Fields:**

| Field | Type | Notes |
|---|---|---|
| exam_id | FK | Parent exam |
| class_id, subject_id | FK | Class and subject |
| paper_code | VARCHAR 50 | UNIQUE per exam |
| title | VARCHAR 150 | |
| mode | ENUM('ONLINE','OFFLINE') | Determines available features |
| total_marks | DECIMAL(8,2) | |
| passing_percentage | DECIMAL(5,2) | |
| duration_minutes | INT | NULL = unlimited |
| total_questions | INT | |
| negative_marks | DECIMAL(5,2) | Default 0 |
| instructions | TEXT | Shown to student |
| only_unused_questions | BOOL | Question bank filter |
| only_authorised_questions | BOOL | Question bank filter |
| difficulty_config_id | FK lms_difficulty_distribution_configs | Cross-module from LmsQuiz |
| is_proctored, is_ai_proctored | BOOL | Proctor hierarchy |
| fullscreen_required, browser_lock_required | BOOL | Additional restrictions |
| shuffle_questions, shuffle_options, timer_enforced | BOOL | |
| show_result_type | ENUM('IMMEDIATE','SCHEDULED','MANUAL') | |
| scheduled_result_at | DATETIME | If SCHEDULED |
| offline_entry_mode | ENUM('BULK_TOTAL','QUESTION_WISE') | Offline-only |
| status_id | FK lms_exam_status_events | Paper status |

**Business Rules:**
- Paper code must be unique within the exam
- If `is_ai_proctored=1` then `is_proctored` must also be 1 (AI requires base proctoring)
- `offline_entry_mode` is irrelevant when `mode=ONLINE`
- `duration_minutes` = NULL means student can take as long as needed

**Cross-module Dependency:** `ExamPaper` model imports `LmsQuiz\Models\DifficultyDistributionConfig` — this is a cross-module model dependency. Migration to a shared config or interface is recommended.

**Implementation:**
- Controller: `ExamPaperController` — full CRUD + trashed/restore/forceDelete/toggleStatus
- Model: `Modules\LmsExam\Models\ExamPaper`
- FormRequest: `ExamPaperRequest`, Policy: `ExamPaperPolicy`
- Routes: `lms-exam.exam-paper.*`

---

### FR-EXM-005: Exam Blueprint Definition
**Priority:** High | **Status:** 🟡 Implemented — Gate authorization disabled (BUG-02)
**Tables:** `lms_exam_blueprints`

**Description:** Defines the structural layout of a paper by sections (e.g., Section A — MCQ 1 mark each, Section B — Short Answer 5 marks each). Each blueprint row specifies a section's question type, question count, marks per question, total section marks, and ordinal position.

**Actors:** Subject Teacher
**Input Fields:** `exam_paper_id`, `section_name` (default 'Section A'), `question_type_id`, `instruction_text`, `total_questions`, `marks_per_question`, `total_marks`, `ordinal`

**Critical Security Bug — BUG-02:**
```
ExamBlueprintController — every single Gate::authorize() call is commented out:
// Gate::authorize('tenant.exam-blueprint.viewAny');   ← commented
// Gate::authorize('tenant.exam-blueprint.create');    ← commented
// Gate::authorize('tenant.exam-blueprint.update');    ← commented
// Gate::authorize('tenant.exam-blueprint.delete');    ← commented
```
**Impact:** Any authenticated user in the tenant — including students — can view, create, modify, and delete exam blueprints (which reveals exam paper structure before the exam). This is an information security breach.

**Fix Required:** Uncomment all 10 Gate::authorize() calls in ExamBlueprintController. Also add activity logging (currently absent).

**Implementation:**
- Controller: `ExamBlueprintController` — full CRUD + trashed/restore/forceDelete/toggleStatus
- Model: `Modules\LmsExam\Models\ExamBlueprint`
- FormRequest: `ExamBlueprintRequest`, Policy: `ExamBlueprintPolicy` (exists, not enforced)
- Routes: `lms-exam.exam-blueprint.*`

**Known Gap:** 🟡 `ExamBlueprint` model missing `created_by` attribute. No activity logging in controller.

---

### FR-EXM-006: Exam Scope Definition
**Priority:** High | **Status:** 🟡 Implemented — Gate authorization disabled (BUG-03)
**Tables:** `lms_exam_scopes`

**Description:** Defines which lessons/topics/question types are included in a paper, along with weightage percentage and target question count. Used for auto-generating questions from the Question Bank based on syllabus coverage.

**Actors:** Subject Teacher
**Input Fields:** `exam_paper_id`, `lesson_id` (nullable), `topic_id` (nullable), `question_type_id` (nullable), `target_question_count` (0 = all), `weightage_percent`

**Critical Security Bug — BUG-03:**
Same pattern as BUG-02. All 10 Gate::authorize() calls in `ExamScopeController` are commented out. Any authenticated user can view and modify exam scope definitions, revealing the exact syllabus areas to be tested.

**Fix Required:** Uncomment all 10 Gate::authorize() calls. Add activity logging.

**Implementation:**
- Controller: `ExamScopeController` — full CRUD + trashed/restore/forceDelete/toggleStatus
- Model: `Modules\LmsExam\Models\ExamScope`
- FormRequest: `ExamScopeRequest`, Policy: `ExamScopePolicy` (not registered in ServiceProvider)
- Routes: `lms-exam.exam-scope.*`

**Known Gap:** 🟡 `ExamScope` model missing `created_by`. `ExamScopePolicy` not registered in LmsExamServiceProvider.

---

### FR-EXM-007: Exam Paper Set Management
**Priority:** High | **Status:** ✅ Implemented
**Tables:** `lms_exam_paper_sets`

**Description:** Creates variants of a paper (SET_A, SET_B, SET_1, SET_2) to prevent copying during physical/online exams. Each set has a unique set_code within the parent paper.

**Actors:** Exam Coordinator, Subject Teacher
**Input Fields:** `exam_paper_id`, `set_code` (VARCHAR 20, UNIQUE per paper), `set_name`, `description`

**Business Rules:**
- Set code must be unique per paper (enforced by DB UNIQUE KEY on `(exam_paper_id, set_code)`)
- At least one set must exist before questions can be assigned or students allocated

**Implementation:**
- Controller: `ExamPaperSetController` — full CRUD + trashed/restore/forceDelete/toggleStatus
- Model: `Modules\LmsExam\Models\ExamPaperSet`
- FormRequest: `ExamPaperSetRequest`, Policy: `ExamPaperSetPolicy`
- Routes: `lms-exam.paper-set.*`

---

### FR-EXM-008: Paper Set Question Assignment
**Priority:** Critical | **Status:** ✅ Implemented (rich AJAX interface)
**Tables:** `lms_paper_set_questions`

**Description:** Links questions from the Question Bank to a specific paper set with ordering, marks override, negative marks, compulsory/optional flag, and section assignment. This is the richest AJAX-driven interface in the module.

**Actors:** Subject Teacher
**AJAX Endpoints:**

| Method | URI | Action |
|---|---|---|
| GET | paper-set-question/get-sections | Cascade: load sections for class |
| GET | paper-set-question/get-subject-groups | Cascade: load subject groups |
| GET | paper-set-question/get-subjects | Cascade: load subjects |
| GET | paper-set-question/get-lessons | Cascade: load lessons |
| GET | paper-set-question/get-topics | Cascade: load topics |
| GET | paper-set-question/search | Search QB with filters |
| GET | paper-set-question/existing | List questions already in set |
| POST | paper-set-question/bulk-store | Add multiple questions at once |
| POST | paper-set-question/bulk-destroy | Remove multiple questions |
| POST | paper-set-question/update-ordinal | Drag-and-drop reorder |
| POST | paper-set-question/update-marks | Inline marks override |
| POST | paper-set-question/update-compulsory | Toggle compulsory flag |

**Data Fields per question assignment:** `paper_set_id`, `question_id`, `section_name`, `ordinal`, `override_marks`, `negative_marks`, `is_compulsory`

**Business Rules:**
- A question can appear only once per set (UNIQUE KEY on `(paper_set_id, question_id)`)
- `override_marks` is required — defaults to the question's default marks from QB
- Questions from different paper sets of the same paper are independent (duplication is allowed across sets)

**Performance Gap:** 🟡 `PaperSetQuestionController` is 1200+ lines with no Service extraction. Refactor to `ExamPaperService` is required.

**Implementation:**
- Controller: `PaperSetQuestionController` — full CRUD + 10 AJAX endpoints
- Model: `Modules\LmsExam\Models\PaperSetQuestion`
- FormRequest: `PaperSetQuestionRequest`, Policy: `PaperSetQuestionPolicy`
- Routes: `lms-exam.paper-set-question.*`

---

### FR-EXM-009: Exam Student Group Management
**Priority:** High | **Status:** ✅ Implemented
**Tables:** `lms_exam_student_groups`, `lms_exam_student_group_members`

**Description:** Creates ad-hoc groups for exam purposes (e.g., "9-A SET-A Group", "Special Needs Group") within an exam. Groups allow fine-grained allocation — assigning specific paper sets to specific student subsets. Members are individual students drawn from an enrolled class+section.

**Actors:** Exam Coordinator

**Student Group Input Fields:** `exam_id`, `class_id`, `section_id`, `code`, `name`, `description`

**Group Member Input Fields:** `group_id`, `student_id`
- UNIQUE KEY on `(group_id, student_id)` — student cannot be added twice

**Auxiliary Endpoint:**
- `GET exam-group-member/get-group-details` — retrieves group metadata for pre-populating the member add form

**Implementation:**
- Controllers: `ExamStudentGroupController`, `ExamStudentGroupMemberController`
- Models: `ExamStudentGroup`, `ExamStudentGroupMember`
- Routes: `lms-exam.exam-student-group.*`, `lms-exam.exam-group-member.*`

**Known Gap:** 🟡 `ExamStudentGroup` model missing `created_by`.

---

### FR-EXM-010: Exam Allocation
**Priority:** Critical | **Status:** ✅ Implemented
**Tables:** `lms_exam_allocations`

**Description:** Maps an exam paper + paper set to a target entity (CLASS/SECTION/EXAM_GROUP/STUDENT) with scheduling overrides (date, start time, end time) and optional physical location. This is the mechanism that determines which students take which set at what time.

**Actors:** Exam Coordinator
**Input Fields:**

| Field | Notes |
|---|---|
| exam_paper_id | Which paper |
| paper_set_id | Which set variant |
| allocation_type | ENUM('CLASS','SECTION','EXAM_GROUP','STUDENT') |
| class_id | Required for all types |
| section_id | Required for SECTION and EXAM_GROUP types |
| exam_group_id | Required for EXAM_GROUP type |
| student_id | Required for STUDENT type |
| scheduled_date | Override date (may differ from paper default) |
| scheduled_start_time | Required |
| scheduled_end_time | Required |
| location | Physical venue (for OFFLINE mode) |

**AJAX Supporting Endpoints:**

| Method | URI | Action |
|---|---|---|
| GET | lms-exam/paper-sets | List paper sets for a paper |
| GET | lms-exam/sections | List sections for a class |
| GET | lms-exam/exam-groups | List student groups for an exam |
| GET | lms-exam/students | List students for a class/section |

**Business Rules:**
- `scheduled_end_time` must be after `scheduled_start_time`
- A student must not receive conflicting allocations (same paper, different set) — enforce in application layer
- CLASS allocation covers all students in that class automatically

**Implementation:**
- Controller: `ExamAllocationController` — full CRUD + 4 AJAX endpoints
- Model: `Modules\LmsExam\Models\ExamAllocation`
- FormRequest: `ExamAllocationRequest`, Policy: `ExamAllocationPolicy`
- Routes: `lms-exam.exam-allocation.*`

---

### FR-EXM-011: Student Online Exam Attempt
**Priority:** Critical | **Status:** ❌ Not Started
**Tables:** `lms_student_attempts`, `lms_exam_answers`, `lms_attempt_activity_logs`
**DDL Defined:** Yes (lines 7489–7793 in tenant_db_v2.sql)

**Description:** The student-facing exam player. After an allocation is published, the assigned student navigates to the exam portal, starts the timed attempt, answers questions (MCQ, descriptive, file upload), receives timer warnings, and submits. Every interaction is recorded with telemetry.

**Required New Artifacts:**
- Controller: `StudentExamAttemptController` — startAttempt, getQuestions, saveAnswer, flagQuestion, submitAttempt, getAttemptStatus
- Model: `StudentAttempt` (table: `lms_student_attempts`), `ExamAnswer` (table: `lms_exam_answers`), `AttemptActivityLog` (table: `lms_attempt_activity_logs`)
- Policy: `StudentAttemptPolicy`
- Views: exam-player (timer, question navigator, answer area), exam-submitted confirmation

**Key Behaviors:**
- `startAttempt()`: Creates `lms_student_attempts` record with `status=IN_PROGRESS`, records `actual_started_time` and `ip_address`
- `saveAnswer()`: Upserts `lms_exam_answers` record; updates `change_count` and `time_spent_seconds`
- Auto-submit: When `actual_started_time + duration_minutes` elapses, status → SUBMITTED via scheduled job
- `submitAttempt()`: Sets `status=SUBMITTED`, `actual_end_time`, computes MCQ marks immediately
- Proctoring: Any `FOCUS_LOST`, `FULLSCREEN_EXIT`, `BROWSER_RESIZE`, `KEY_PRESS_BLOCKED`, `MOUSE_LEAVE`, `IP_CHANGE` event writes to `lms_attempt_activity_logs` and increments `violation_count`

**Proctoring Violation Handling:**
- `violation_count` threshold defined per paper (configurable)
- At threshold: auto-submit or alert to invigilator
- `browser_lock_required=1`: Disable browser navigation keys, copy-paste via JS
- `fullscreen_required=1`: Force fullscreen on start; exit triggers a violation log entry

**Business Rules:**
- One attempt per student per paper (UNIQUE KEY on `(exam_paper_id, student_id)`)
- Student can only start if their allocation is published and within scheduled time window
- `OFFLINE` attempt: `is_present_offline` toggled by teacher; no answer recording in this table

**NFR:** Must support 500+ concurrent online sessions without significant degradation.

---

### FR-EXM-012: Offline Exam Marks Entry
**Priority:** High | **Status:** ❌ Not Started
**Tables:** `lms_student_attempts`, `lms_exam_marks_entry`, `lms_attempt_answers` (question-wise mode)
**DDL Defined:** Yes (lms_exam_marks_entry line 7559)

**Description:** Teacher opens a class roster for a paper and enters marks per student. Two modes exist based on `lms_exam_papers.offline_entry_mode`:
- **BULK_TOTAL**: One total marks entry per student into `lms_exam_marks_entry`
- **QUESTION_WISE**: Marks entered per question into `lms_attempt_answers` with `evaluated_by` set to teacher ID

**Required New Artifacts:**
- Controller: `ExamMarksEntryController` — showRoster, bulkTotalEntry, questionWiseEntry, computeResults, publishResults
- Model: `ExamMarksEntry` (table: `lms_exam_marks_entry`)
- View: marks-entry/roster (student list, marks input), marks-entry/question-wise

**Key Behaviors:**
- `showRoster()`: Lists all students with an allocation for the paper; shows current marks if entered; respects `is_present_offline` flag
- `bulkTotalEntry()`: Validates marks <= `total_marks`; creates/updates `lms_exam_marks_entry`; sets attempt status to EVALUATION_PENDING
- `computeResults()`: Calculates `percentage = (marks / total_marks) * 100`; looks up grade from `slb_grade_division_master`; writes to `lms_exam_results`; computes class rank
- `publishResults()`: Sets `lms_exam_results.is_published=1`, `published_at=NOW()`; triggers notification to students and parents

**Business Rules:**
- Marks entered cannot exceed `total_marks` for the paper
- Absent students (`is_present_offline=0`) get `result_status=ABSENT` in `lms_exam_results`
- Bulk entry overwrites any existing entry (idempotent)
- Question-wise entry must have questions summing to no more than `total_marks`

---

### FR-EXM-013: Result Computation and Publication
**Priority:** High | **Status:** ❌ Not Started
**Tables:** `lms_exam_results`
**DDL Defined:** Yes (lines 7665–7726)

**Description:** The final graded result per student per exam. Aggregates marks across papers, computes overall percentage, applies grading schema, assigns rank, and enables result publication to the Student Portal and Parent Portal.

**Required New Artifacts:**
- Controller: `ExamResultController` — index (class-wise result sheet), show (individual), publish, unpublish, generateReportCard
- Model: `ExamResult` (table: `lms_exam_results`)
- Service: `ExamResultService` — computeClassResults, computeRanks, applyGradingSchema, generateReportCardPdf

**Result Record Fields:**
- `exam_id`, `student_id`, `attempt_id` (optional link)
- `total_marks_possible`, `total_marks_obtained`, `percentage`
- `grade_obtained`, `division` (First, Second, Third, Fail)
- `result_status` ENUM('PASS','FAIL','ABSENT','WITHHELD')
- `rank_in_class`, `percentile`
- `is_published`, `published_at`
- `teacher_remarks`
- `generated_report_card_url` (path to DomPDF-generated PDF)

**Business Rules:**
- Result can only be published after all paper marks are entered (no pending marks)
- Once published, marks can be modified only by Admin (unpublish → modify → republish)
- Rank is computed within the same class for the same exam
- `WITHHELD` status is manually set by Admin (e.g., fee dues)
- Report card PDF uses DomPDF (same as HPC module); layout defined per school template

---

### FR-EXM-014: Exam Grievance Management
**Priority:** Medium | **Status:** ❌ Not Started
**Tables:** `lms_exam_grievances`
**DDL Defined:** Yes (lines 7731–7774)

**Description:** After result publication, students may raise a grievance against specific question evaluations or general result. Teacher reviews, optionally corrects marks, and resolves.

**Required New Artifacts:**
- Controller: `ExamGrievanceController` — index (by paper/class), store, updateStatus, resolve, reject
- Model: `ExamGrievance` (table: `lms_exam_grievances`)

**Grievance Record Fields:**
- `exam_result_id`, `question_id`, `student_id`
- `grievance_text` (student's complaint)
- `status` ENUM('OPEN','UNDER_REVIEW','RESOLVED','REJECTED')
- `reviewer_id`, `resolution_remarks`
- `marks_changed` (boolean), `old_marks`, `new_marks`, `resolved_at`

**Business Rules:**
- Grievance can only be filed within a configurable window after result publication (e.g., 7 days)
- If `marks_changed=1`, the `lms_exam_answers.marks_obtained` must be updated and `lms_exam_results` recomputed
- Marks increase from grievance must not exceed `override_marks` for that question
- Resolution triggers notification to student and parent

---

### FR-EXM-015: Exam Schedule & Hall Ticket Generation
**Priority:** Medium | **Status:** ❌ Not Started (📐 Proposed for V2)
**Tables:** No dedicated table — derives from `lms_exam_allocations` + `lms_exams` + `lms_exam_papers`

**Description:** Generates a printable/PDF hall ticket per student showing exam schedule (subject, date, time, venue, set/roll number assignment). Also produces a seating arrangement chart per venue.

**Required New Artifacts:**
- Controller: `ExamHallTicketController` — generateForStudent, generateBulkForClass, seatingArrangement
- Service: `HallTicketService` — buildStudentSchedule, buildVenueSeatingMap, generatePdf

**Hall Ticket Contents:**
- Student name, roll number, photo
- School name and logo
- Per-paper row: subject, date, day, time, venue, set code
- Instructions and signature space

**Business Rules:**
- Hall ticket available only after exam is PUBLISHED
- Set code shown on hall ticket only if admin enables "show set on ticket" flag per exam
- Seating arrangement groups students by venue (derived from `allocation.location`)

---

### FR-EXM-016: Module Access Guard (Missing Middleware)
**Priority:** High | **Status:** ❌ Not Started — BUG-04
**Location:** `routes/tenant.php` line 520

**Description:** The `EnsureTenantHasModule` middleware must be added to the `lms-exam` route group to prevent schools that have not purchased the LMS Exam module from accessing these endpoints.

**Current state:**
```php
Route::middleware(['auth', 'verified'])->prefix('lms-exam')...
```

**Required state:**
```php
Route::middleware(['auth', 'verified', 'tenant.hasModule:EXM'])->prefix('lms-exam')...
```

**Impact of missing middleware:** Any authenticated user at any tenant can access LmsExam routes regardless of whether the school has a valid module license.

---

## 5. Data Model

### 5.1 Tables Currently Implemented (11)

#### lms_exam_types
| Column | Type | Constraints |
|---|---|---|
| id | INT UNSIGNED PK | AUTO_INCREMENT |
| code | VARCHAR(50) | UNIQUE NOT NULL |
| name | VARCHAR(100) | NOT NULL |
| description | VARCHAR(255) | NULL |
| is_active | TINYINT(1) | DEFAULT 1 |
| created_at, updated_at, deleted_at | TIMESTAMP | Standard |

#### lms_exam_status_events
| Column | Type | Constraints |
|---|---|---|
| id | INT UNSIGNED PK | |
| code | VARCHAR(50) | UNIQUE NOT NULL |
| name | VARCHAR(100) | NOT NULL |
| event_type | ENUM('EXAM','PAPER','RESULT','ATTEMPT') | NOT NULL DEFAULT 'EXAM' |
| action_logic | JSON | NOT NULL |
| description | VARCHAR(255) | NULL |
| is_active, created_at, updated_at, deleted_at | standard | |

#### lms_exams
| Column | Type | Constraints |
|---|---|---|
| id | INT UNSIGNED PK | |
| uuid | BINARY(16) | UNIQUE NOT NULL |
| academic_session_id | INT UNSIGNED | FK glb_academic_sessions |
| class_id | INT UNSIGNED | FK sch_classes |
| exam_type_id | INT UNSIGNED | FK lms_exam_types |
| code | VARCHAR(50) | UNIQUE NOT NULL |
| title | VARCHAR(150) | NOT NULL |
| description | TEXT | NULL |
| start_date | DATE | NOT NULL |
| end_date | DATE | NOT NULL |
| grading_schema_id | INT UNSIGNED | FK slb_grade_division_master NULL |
| status_id | INT UNSIGNED | FK lms_exam_status_events |
| created_by | INT UNSIGNED | FK sys_users NULL |
| is_active, created_at, updated_at, deleted_at | standard | |
| UNIQUE | (academic_session_id, class_id, exam_type_id) | One exam per session+class+type |

#### lms_exam_papers
| Column | Type | Notes |
|---|---|---|
| id | INT UNSIGNED PK | |
| exam_id | INT UNSIGNED | FK lms_exams CASCADE |
| class_id, subject_id | INT UNSIGNED | FK sch_classes, sch_subjects |
| paper_code | VARCHAR(50) | UNIQUE per exam |
| title | VARCHAR(150) | |
| mode | ENUM('ONLINE','OFFLINE') | |
| total_marks | DECIMAL(8,2) | |
| passing_percentage | DECIMAL(5,2) | |
| duration_minutes | INT UNSIGNED | NULL = unlimited |
| total_questions | INT UNSIGNED | |
| negative_marks | DECIMAL(5,2) | DEFAULT 0.00 |
| instructions | TEXT | |
| only_unused_questions, only_authorised_questions | TINYINT(1) | QB filters |
| difficulty_config_id | INT UNSIGNED | FK lms_difficulty_distribution_configs NULL |
| allow_calculator, show_marks_per_question, is_randomized | TINYINT(1) | |
| is_proctored, is_ai_proctored | TINYINT(1) | Proctor hierarchy |
| fullscreen_required, browser_lock_required | TINYINT(1) | Restrictions |
| shuffle_questions, shuffle_options, timer_enforced | TINYINT(1) | |
| show_result_type | ENUM('IMMEDIATE','SCHEDULED','MANUAL') | |
| scheduled_result_at | DATETIME | NULL |
| offline_entry_mode | ENUM('BULK_TOTAL','QUESTION_WISE') | |
| status_id | INT UNSIGNED | FK lms_exam_status_events |
| created_by, is_active, created_at, updated_at, deleted_at | standard | |

#### lms_exam_paper_sets
| Column | Type | Notes |
|---|---|---|
| id | INT UNSIGNED PK | |
| exam_paper_id | INT UNSIGNED | FK lms_exam_papers CASCADE |
| set_code | VARCHAR(20) | UNIQUE per paper |
| set_name | VARCHAR(50) | |
| description | VARCHAR(255) | NULL |
| created_by, is_active, created_at, updated_at, deleted_at | standard | |

#### lms_exam_scopes
| Column | Type | Notes |
|---|---|---|
| id | INT UNSIGNED PK | |
| exam_paper_id | INT UNSIGNED | FK lms_exam_papers CASCADE |
| lesson_id | INT UNSIGNED | FK slb_lessons NULL |
| topic_id | INT UNSIGNED | FK slb_topics NULL |
| question_type_id | INT UNSIGNED | FK slb_question_types NULL |
| target_question_count | INT UNSIGNED | 0 = all matching questions |
| weightage_percent | DECIMAL(5,2) | NULL |
| is_active, created_at, updated_at, deleted_at | standard | |

#### lms_exam_blueprints
| Column | Type | Notes |
|---|---|---|
| id | INT UNSIGNED PK | |
| exam_paper_id | INT UNSIGNED | FK lms_exam_papers CASCADE |
| section_name | VARCHAR(50) | DEFAULT 'Section A' |
| question_type_id | INT UNSIGNED | FK slb_question_types NULL |
| instruction_text | TEXT | NULL |
| total_questions | INT UNSIGNED | |
| marks_per_question | DECIMAL(5,2) | NULL |
| total_marks | DECIMAL(8,2) | |
| ordinal | TINYINT UNSIGNED | Section ordering |
| is_active, created_at, updated_at, deleted_at | standard | |

#### lms_paper_set_questions
| Column | Type | Notes |
|---|---|---|
| id | INT UNSIGNED PK | |
| paper_set_id | INT UNSIGNED | FK lms_exam_paper_sets CASCADE |
| question_id | INT UNSIGNED | FK qns_questions_bank |
| section_name | VARCHAR(50) | DEFAULT 'Section A' |
| ordinal | INT UNSIGNED | Sequence order |
| override_marks | DECIMAL(5,2) | NOT NULL |
| negative_marks | DECIMAL(5,2) | DEFAULT 0.00 |
| is_compulsory | TINYINT(1) | DEFAULT 1 |
| is_active, created_at, updated_at, deleted_at | standard | |
| UNIQUE | (paper_set_id, question_id) | |

#### lms_exam_student_groups
| Column | Type | Notes |
|---|---|---|
| id | INT UNSIGNED PK | |
| exam_id | INT UNSIGNED | FK lms_exams CASCADE |
| class_id | INT UNSIGNED | FK sch_classes CASCADE |
| section_id | INT UNSIGNED | FK sch_sections CASCADE |
| code | VARCHAR(50) | UNIQUE per exam+class+section |
| name, description | VARCHAR | |
| is_active, created_at, updated_at, deleted_at | standard | |

#### lms_exam_student_group_members
| Column | Type | Notes |
|---|---|---|
| id | INT UNSIGNED PK | |
| group_id | INT UNSIGNED | FK lms_exam_student_groups CASCADE |
| student_id | INT UNSIGNED | FK std_students |
| created_at, updated_at, deleted_at | standard | |
| UNIQUE | (group_id, student_id) | |

#### lms_exam_allocations
| Column | Type | Notes |
|---|---|---|
| id | INT UNSIGNED PK | |
| exam_paper_id | INT UNSIGNED | FK lms_exam_papers CASCADE |
| paper_set_id | INT UNSIGNED | FK lms_exam_paper_sets |
| allocation_type | ENUM('CLASS','SECTION','EXAM_GROUP','STUDENT') | |
| class_id | INT UNSIGNED | FK sch_classes NOT NULL |
| section_id | INT UNSIGNED | FK sch_sections NULL |
| exam_group_id | INT UNSIGNED | FK lms_exam_student_groups NULL |
| student_id | INT UNSIGNED | FK std_students NULL |
| scheduled_date | DATE | NULL |
| scheduled_start_time | TIME | NOT NULL |
| scheduled_end_time | TIME | NOT NULL |
| location | VARCHAR(100) | NULL |
| is_active, created_at, updated_at, deleted_at | standard | |

### 5.2 Tables Defined in DDL — No Code Yet (6)

#### lms_student_attempts
| Column | Type | Notes |
|---|---|---|
| uuid | BINARY(16) | UNIQUE |
| exam_paper_id, paper_set_id | INT UNSIGNED | FKs |
| allocation_id | INT UNSIGNED | FK NULL |
| student_id | INT UNSIGNED | FK std_students |
| actual_started_time, actual_end_time | DATETIME | |
| actual_time_taken_seconds | INT UNSIGNED | |
| status_id | INT UNSIGNED | FK lms_exam_status_events |
| attempt_mode | ENUM('ONLINE','OFFLINE') | |
| answer_sheet_number | VARCHAR(50) | Offline physical sheet |
| is_present_offline | TINYINT(1) | Attendance flag |
| ip_address, device_info JSON, violation_count | | Proctoring |
| UNIQUE | (exam_paper_id, student_id) | One attempt per student per paper |

#### lms_exam_answers
| Column | Notes |
|---|---|
| attempt_id, question_id | FKs |
| selected_option_id, selected_option_ids JSON | MCQ single/multi |
| descriptive_answer TEXT | Text answer |
| attachment_id | FK sys_media (file upload) |
| is_correct, marks_obtained, is_evaluated | Evaluation fields |
| evaluated_by, evaluation_remarks, evaluated_at | Teacher evaluation |
| time_spent_seconds, change_count | Analytics telemetry |

#### lms_exam_marks_entry
| Column | Notes |
|---|---|
| attempt_id | FK lms_student_attempts |
| total_marks_obtained | Offline bulk total |
| remarks | Optional |
| entered_by | FK sys_users (teacher) |
| entered_at | DATETIME |
| UNIQUE | (attempt_id) |

#### lms_exam_results
| Column | Notes |
|---|---|
| exam_id, student_id, attempt_id | FKs |
| total_marks_possible, total_marks_obtained, percentage | Aggregated |
| grade_obtained, division | From grading schema |
| result_status | ENUM('PASS','FAIL','ABSENT','WITHHELD') |
| rank_in_class, percentile | Class-level stats |
| is_published, published_at | Publication state |
| teacher_remarks, generated_report_card_url | Extra |
| UNIQUE | (exam_id, student_id) |

#### lms_exam_grievances
| Column | Notes |
|---|---|
| exam_result_id, question_id, student_id | FKs |
| grievance_text | Student complaint |
| status | ENUM('OPEN','UNDER_REVIEW','RESOLVED','REJECTED') |
| reviewer_id, resolution_remarks, resolved_at | Review |
| marks_changed, old_marks, new_marks | Correction tracking |

#### lms_attempt_activity_logs
| Column | Notes |
|---|---|
| attempt_id | FK lms_student_attempts |
| activity_type | ENUM('FOCUS_LOST','FULLSCREEN_EXIT','BROWSER_RESIZE','KEY_PRESS_BLOCKED','MOUSE_LEAVE','IP_CHANGE') |
| activity_data JSON | Event context |
| occurred_at | TIMESTAMP |

---

## 6. API Endpoints & Routes

**Route Group:** `/routes/tenant.php` line 520
**Prefix:** `/lms-exam` | **Name Prefix:** `lms-exam.`
**Current Middleware:** `['auth', 'verified']`
**Required Middleware:** `['auth', 'verified', 'tenant.hasModule:EXM']` (BUG-04 fix)

### 6.1 Implemented Routes

| Method | URI | Route Name | Controller | Status |
|---|---|---|---|---|
| GET/POST | /lms-exam/exam | lms-exam.exam.index/store | LmsExamController | ✅ |
| GET | /lms-exam/exam/trash/view | lms-exam.exam.trashed | LmsExamController | ✅ |
| GET/PUT/DELETE | /lms-exam/exam/{id} | lms-exam.exam.show/update/destroy | LmsExamController | ✅ |
| GET | /lms-exam/exam/{id}/restore | lms-exam.exam.restore | LmsExamController | ✅ |
| DELETE | /lms-exam/exam/{id}/force-delete | lms-exam.exam.forceDelete | LmsExamController | ✅ |
| POST | /lms-exam/exam/{exam}/toggle-status | lms-exam.exam.toggleStatus | LmsExamController | ✅ |
| resource | /lms-exam/exam-paper | lms-exam.exam-paper.* | ExamPaperController | ✅ |
| GET | /lms-exam/paper-set-question/get-sections | lms-exam.paper-set-question.get-sections | PaperSetQuestionController | ✅ |
| GET | /lms-exam/paper-set-question/search | lms-exam.paper-set-question.search | PaperSetQuestionController | ✅ |
| GET | /lms-exam/paper-set-question/existing | lms-exam.paper-set-question.existing | PaperSetQuestionController | ✅ |
| POST | /lms-exam/paper-set-question/bulk-store | lms-exam.paper-set-question.bulk-store | PaperSetQuestionController | ✅ |
| POST | /lms-exam/paper-set-question/bulk-destroy | lms-exam.paper-set-question.bulk-destroy | PaperSetQuestionController | ✅ |
| POST | /lms-exam/paper-set-question/update-ordinal | lms-exam.paper-set-question.update-ordinal | PaperSetQuestionController | ✅ |
| POST | /lms-exam/paper-set-question/update-marks | lms-exam.paper-set-question.update-marks | PaperSetQuestionController | ✅ |
| POST | /lms-exam/paper-set-question/update-compulsory | lms-exam.paper-set-question.update-compulsory | PaperSetQuestionController | ✅ |
| resource | /lms-exam/paper-set-question | lms-exam.paper-set-question.* | PaperSetQuestionController | ✅ |
| resource | /lms-exam/exam-scope | lms-exam.exam-scope.* | ExamScopeController | 🟡 Gate disabled |
| resource | /lms-exam/exam-blueprint | lms-exam.exam-blueprint.* | ExamBlueprintController | 🟡 Gate disabled |
| resource | /lms-exam/paper-set | lms-exam.paper-set.* | ExamPaperSetController | ✅ |
| resource | /lms-exam/exam-allocation | lms-exam.exam-allocation.* | ExamAllocationController | ✅ |
| GET | /lms-exam/paper-sets | lms-exam.paper-sets | ExamAllocationController | ✅ |
| GET | /lms-exam/sections | lms-exam.sections | ExamAllocationController | ✅ |
| GET | /lms-exam/exam-groups | lms-exam.exam-groups | ExamAllocationController | ✅ |
| GET | /lms-exam/students | lms-exam.students | ExamAllocationController | ✅ |
| resource | /lms-exam/exam-student-group | lms-exam.exam-student-group.* | ExamStudentGroupController | ✅ |
| GET | /lms-exam/exam-group-member/get-group-details | lms-exam.get-group-details | ExamStudentGroupMemberController | ✅ |
| resource | /lms-exam/exam-group-member | lms-exam.exam-group-member.* | ExamStudentGroupMemberController | ✅ |
| resource | /lms-exam/exam-type | lms-exam.exam-type.* | ExamTypeController | ✅ |
| resource | /lms-exam/exam-status-event | lms-exam.exam-status-event.* | ExamStatusEventController | ✅ |

### 6.2 Routes to Be Created (Proposed V2)

| Method | URI | Route Name | Controller | Purpose |
|---|---|---|---|---|
| POST | /lms-exam/attempt/{allocation}/start | lms-exam.attempt.start | StudentExamAttemptController | 📐 Start online attempt |
| POST | /lms-exam/attempt/{attempt}/save-answer | lms-exam.attempt.save-answer | StudentExamAttemptController | 📐 Auto-save answer |
| POST | /lms-exam/attempt/{attempt}/submit | lms-exam.attempt.submit | StudentExamAttemptController | 📐 Final submit |
| GET | /lms-exam/attempt/{attempt}/status | lms-exam.attempt.status | StudentExamAttemptController | 📐 Polling endpoint |
| POST | /lms-exam/attempt/{attempt}/log-activity | lms-exam.attempt.log-activity | StudentExamAttemptController | 📐 Proctoring log |
| GET | /lms-exam/marks-entry/{paper} | lms-exam.marks-entry.roster | ExamMarksEntryController | 📐 Marks roster |
| POST | /lms-exam/marks-entry/{paper}/bulk-total | lms-exam.marks-entry.bulk-total | ExamMarksEntryController | 📐 Bulk marks save |
| POST | /lms-exam/marks-entry/{paper}/question-wise | lms-exam.marks-entry.question-wise | ExamMarksEntryController | 📐 Q-wise marks |
| POST | /lms-exam/marks-entry/{paper}/compute | lms-exam.marks-entry.compute | ExamMarksEntryController | 📐 Compute results |
| POST | /lms-exam/result/{exam}/publish | lms-exam.result.publish | ExamResultController | 📐 Publish results |
| GET | /lms-exam/result/{exam} | lms-exam.result.index | ExamResultController | 📐 Result sheet |
| GET | /lms-exam/result/{result}/report-card | lms-exam.result.report-card | ExamResultController | 📐 PDF report card |
| POST | /lms-exam/grievance | lms-exam.grievance.store | ExamGrievanceController | 📐 File grievance |
| PATCH | /lms-exam/grievance/{grievance}/resolve | lms-exam.grievance.resolve | ExamGrievanceController | 📐 Resolve grievance |
| GET | /lms-exam/hall-ticket/{student}/{exam} | lms-exam.hall-ticket | ExamHallTicketController | 📐 Hall ticket PDF |

---

## 7. UI Screens

### 7.1 Implemented Screens

| Screen | View File | Status |
|---|---|---|
| Module Hub (tab container) | `tab_module/tab.blade.php` | ✅ |
| Exam Index / Tab | `exam/index.blade.php` | ✅ |
| Exam Create | `exam/create.blade.php` | ✅ |
| Exam Edit | `exam/edit.blade.php` | ✅ |
| Exam Show | `exam/show.blade.php` | ✅ |
| Exam Trash | `exam/trash.blade.php` | ✅ |
| Exam Paper Index | `exam-paper/index.blade.php` | ✅ |
| Exam Paper Create | `exam-paper/create.blade.php` | ✅ (proctor flags included) |
| Exam Paper Edit/Show/Trash | `exam-paper/{edit,show,trash}.blade.php` | ✅ |
| Exam Paper Set | `exam-paper-set/{create,edit,index,show,trash}.blade.php` | ✅ |
| Exam Scope | `exam-scope/{create,edit,index,show,trash}.blade.php` | ✅ |
| Exam Blueprint | `exam-blueprint/{create,edit,index,show,trash}.blade.php` | ✅ |
| Paper Set Questions | `paper-set-question/{create,edit,index,show,trash}.blade.php` | ✅ |
| Exam Allocation | `exam-allocation/{create,edit,index,show,trash}.blade.php` | ✅ |
| Student Groups | `exam-student-group/{create,edit,index,show,trash}.blade.php` | ✅ |
| Group Members | `exam-group-member/{create,edit,index,show,trash}.blade.php` | ✅ |
| Exam Types | `exam-type/{create,edit,index,show,trash}.blade.php` | ✅ |
| Status Events | `exam-status-event/{create,edit,index,show,trash}.blade.php` | ✅ |

### 7.2 Screens to Be Built (V2)

| Screen | Proposed View Path | Purpose |
|---|---|---|
| Online Exam Player | `exam-player/index.blade.php` | 📐 Timed exam with question navigator, timer |
| Offline Marks Roster | `marks-entry/roster.blade.php` | 📐 Class roster with marks input |
| Question-wise Marks Entry | `marks-entry/question-wise.blade.php` | 📐 Per-question marks entry grid |
| Class Result Sheet | `result/index.blade.php` | 📐 All students' results for an exam |
| Individual Result | `result/show.blade.php` | 📐 Student's detailed result |
| Report Card PDF | `result/report-card.blade.php` | 📐 DomPDF-rendered report card |
| Grievance List | `grievance/index.blade.php` | 📐 Pending/resolved grievances |
| Grievance Review | `grievance/review.blade.php` | 📐 Review and resolve |
| Hall Ticket PDF | `hall-ticket/template.blade.php` | 📐 Printable hall ticket |
| Seating Arrangement | `seating/index.blade.php` | 📐 Venue-wise seating chart |

---

## 8. Business Rules

| BR# | Rule | Source |
|---|---|---|
| BR-01 | One exam per academic session + class + type combination | DB UNIQUE KEY on lms_exams |
| BR-02 | Paper code unique within an exam | DB UNIQUE KEY on (exam_id, paper_code) |
| BR-03 | Set code unique within a paper | DB UNIQUE KEY on (exam_paper_id, set_code) |
| BR-04 | A question can appear only once per paper set | DB UNIQUE KEY on (paper_set_id, question_id) |
| BR-05 | Student can attempt a paper only once | DB UNIQUE KEY on (exam_paper_id, student_id) |
| BR-06 | AI proctoring requires base proctoring enabled | Application-layer validation |
| BR-07 | Online exam: auto-submit when timer expires | Scheduled job or frontend JS timer |
| BR-08 | Marks entered cannot exceed the paper's total_marks | FormRequest validation |
| BR-09 | Absent students get result_status=ABSENT; not calculated as PASS/FAIL | Application-layer logic |
| BR-10 | Results cannot be published with un-evaluated papers remaining | Pre-publish validation check |
| BR-11 | Exam status: DRAFT → PUBLISHED → CONCLUDED → ARCHIVED (no reversal from CONCLUDED) | Status FSM |
| BR-12 | Paper status: NOT_STARTED → IN_PROGRESS → SUBMITTED → EVALUATION_PENDING → EVALUATED → RESULT_PUBLISHED | Status FSM |
| BR-13 | Grievance filing only within configurable window post result publication | Application-layer + config |
| BR-14 | If grievance resolves with marks_changed=1, lms_exam_results must be recomputed | Application-layer cascade |
| BR-15 | WITHHELD result status can only be set by Admin | Gate-protected action |
| BR-16 | Proctoring violation count exceeding threshold triggers auto-submit or alert | Configurable per paper |
| BR-17 | Offline entry mode QUESTION_WISE requires answers for each question in lms_paper_set_questions | Validation |
| BR-18 | Hall ticket available only after exam is PUBLISHED | Gate check on allocation status |
| BR-19 | Grade is derived from slb_grade_division_master against percentage thresholds | Grading schema lookup |
| BR-20 | Rank in class is computed only among students with result_status=PASS or FAIL (not ABSENT/WITHHELD) | Business logic |

---

## 9. Workflows

### 9.1 Exam Lifecycle (Complete End-to-End FSM)

```
[Prerequisites]
  ExamType + StatusEvent master data seeded
          |
          v
[PHASE 1: Setup]
  Create Exam (status=DRAFT)
          |
          v
  Create Exam Papers (per subject + mode)
          |
    +-----+-----+
    |           |
    v           v
  Define       Define
  Blueprint    Scope
  (sections)   (topics/lessons)
          |
          v
  Create Paper Sets (SET_A, SET_B...)
          |
          v
  Assign Questions from QB
  (bulk-store, reorder, marks override)
          |
          v
  Create Student Groups + Members
          |
          v
  Create Allocations
  (paper+set → class/section/group/student + schedule)
          |
          v
[PHASE 2: Publishing]
  Publish Exam (status → PUBLISHED)
  Generate Hall Tickets (📐)
          |
          v
[PHASE 3: Execution]
  +----------ONLINE-----------+    +----------OFFLINE-----------+
  |                           |    |                            |
  Student starts attempt      |    Teacher marks attendance     |
  (lms_student_attempts)      |    (is_present_offline flag)    |
  Answers questions           |    Teacher enters marks         |
  (lms_exam_answers)          |    (lms_exam_marks_entry or     |
  Proctoring logs violations  |     question-wise entry)       |
  (lms_attempt_activity_logs) |                                |
  Submits (or auto-submit)    |                                |
  +---------------------------+    +----------------------------+
                    |
                    v
[PHASE 4: Evaluation]
  Auto-grade MCQ answers
  Teacher grades descriptive answers
  Compute results (lms_exam_results)
  Compute ranks within class
          |
          v
[PHASE 5: Publication]
  Publish Results (is_published=1)
  Notify students + parents
  Generate Report Cards (PDF)
          |
          v
[PHASE 6: Post-Result]
  Student files Grievance (optional, within window)
  Teacher reviews, resolves
  If marks changed: recompute result
          |
          v
  Conclude Exam (status → CONCLUDED)
  Archive (status → ARCHIVED)
```

### 9.2 Paper Status FSM

```
NOT_STARTED
     |
     | (student starts attempt)
     v
IN_PROGRESS
     |
     | (student submits OR timer expires)
     v
SUBMITTED
     |
     | (system auto-grades MCQ)
     v
EVALUATION_PENDING     ABSENT
     |                   ^
     | (teacher grades)  | (if is_present_offline=0)
     v
EVALUATED
     |
     | (admin publishes)
     v
RESULT_PUBLISHED
```

### 9.3 Online Exam Attempt Sequence

```
Student → GET /exam-player?allocation={id}
        → System validates: allocation active, within time window, no existing attempt
        → POST /attempt/{allocation}/start
            Creates lms_student_attempts (status=IN_PROGRESS)
        → JS timer starts counting down
        → For each answer:
            POST /attempt/{attempt}/save-answer (upsert lms_exam_answers)
        → Proctoring events → POST /attempt/{attempt}/log-activity
        → On submit/timeout: POST /attempt/{attempt}/submit
            status → SUBMITTED, actual_end_time = NOW()
            MCQ auto-graded immediately
```

---

## 10. Non-Functional Requirements

| ID | Requirement | Target | Priority |
|---|---|---|---|
| NFR-01 | Tab index page load time (11 concurrent paginated queries) | < 2 seconds at P95 | High |
| NFR-02 | Online exam answer auto-save latency | < 500ms | Critical |
| NFR-03 | Concurrent online exam sessions supported | 500+ students per tenant | Critical |
| NFR-04 | Question paper confidentiality | Paper set contents not accessible via API until allocation is published | High |
| NFR-05 | All write operations must use DB transactions | No partial writes on failure | Critical |
| NFR-06 | Audit trail completeness | All CUD operations logged via activityLog(); currently missing in ExamBlueprintController and ExamScopeController | High |
| NFR-07 | Multi-tenant isolation | All tables in tenant_db; no cross-tenant data leakage via query scoping | Critical |
| NFR-08 | Report card PDF generation | < 3 seconds per PDF via DomPDF | Medium |
| NFR-09 | Module licensing enforcement | EnsureTenantHasModule middleware required (currently absent) | Critical |
| NFR-10 | No debug code in production | Zero `dd()`, `var_dump()`, `dump()` calls in any controller | Critical |
| NFR-11 | Service layer extraction | LmsExamController (820 lines) and PaperSetQuestionController (1200+ lines) must be refactored to services before adding student pipeline | High |
| NFR-12 | Test coverage | Minimum 80 test cases (unit + feature) before student pipeline production release | High |
| NFR-13 | Memory limits | QuestionBank::get() and Student::get() must be replaced with paginated/AJAX search | High |
| NFR-14 | Online exam security | Browser lock + fullscreen enforcement via JS when paper flags enabled | High |

---

## 11. Dependencies

### 11.1 Inbound Dependencies (modules that EXM consumes)

| Module | Type | Detail |
|---|---|---|
| QuestionBank (QNS) | Critical | `qns_questions_bank` and `qns_question_options` are the source for paper set questions. `PaperSetQuestionController` uses `Modules\QuestionBank\Models\QuestionBank` directly. |
| LmsQuiz (QUZ) | Shared Model | `ExamPaper` model imports `LmsQuiz\Models\DifficultyDistributionConfig`; cross-module model dependency. Table `lms_difficulty_distribution_configs` is owned by LmsQuiz. |
| SchoolSetup (SCH) | FK Dependency | `sch_classes`, `sch_sections`, `sch_subjects` throughout all tables |
| Syllabus (SLB) | FK Dependency | `slb_lessons`, `slb_topics`, `slb_question_types`, `slb_grade_division_master` in scopes, blueprints, results |
| StudentProfile (STD) | FK Dependency | `std_students` in group members, allocations, attempts, results |
| GlobalMasters (GLB) | FK Dependency | `glb_academic_sessions` for academic session FK on lms_exams |
| SystemConfig (SYS) | Shared | `sys_media` for answer sheet uploads and report card PDF storage |
| SystemConfig (SYS) | Shared | `sys_users` for `created_by`, `entered_by`, `resolved_by` fields |

### 11.2 Outbound Dependencies (modules that consume EXM)

| Module | Type | Detail |
|---|---|---|
| StudentPortal (STP) | Consumer | Student views their exam schedule and published results |
| ParentPortal (PPT) | Consumer | Parent views child's published results and report card |
| CRT Certificate (CRT) | Consumer | Rank certificates generated from `lms_exam_results.rank_in_class` |
| Notification (NTF) | Event Trigger | Result publication triggers notifications to students and parents |
| Dashboard (DSH) | Consumer | Exam statistics and upcoming exam schedule on dashboards |

---

## 12. Test Scenarios

**Current coverage: 0 tests.** Target: minimum 80 test cases before student pipeline release.

### 12.1 Unit Tests (Pest)

| Test Class | Test Cases | Priority |
|---|---|---|
| ExamCodeGeneratorTest | Code format `EXAM_{session}_{class}_{type}_{random}`, uniqueness collision retry | High |
| ExamStatusTransitionTest | Valid transitions (DRAFT→PUBLISHED, PUBLISHED→CONCLUDED); invalid (CONCLUDED→DRAFT) | High |
| MarksCalculationTest | percentage formula, PASS/FAIL boundary at passing_percentage, ABSENT bypass | Critical |
| GradeSchemaLookupTest | Grade lookup from slb_grade_division_master thresholds | High |
| ProctoringViolationTest | Threshold logic, auto-submit trigger | Medium |
| RankComputationTest | Class rank ordering, tie handling, exclude ABSENT/WITHHELD | Medium |

### 12.2 Feature Tests

| Test Class | Scenarios | Priority |
|---|---|---|
| ExamCreationTest | Happy path create; duplicate code; duplicate session+class+type; rollback on exception (no dd) | Critical |
| ExamBlueprintGateTest | CRITICAL: Verify Gate IS enforced after BUG-02 fix; unauthorized access returns 403 | Critical |
| ExamScopeGateTest | CRITICAL: Verify Gate IS enforced after BUG-03 fix; unauthorized access returns 403 | Critical |
| EnsureTenantModuleTest | Tenant without EXM module gets 403 on lms-exam routes | High |
| ExamPaperTest | Online mode flags validation; offline_entry_mode; proctor hierarchy; paper code uniqueness | High |
| PaperSetQuestionTest | bulk-store; duplicate question rejected; ordinal update; marks override; bulk-destroy | High |
| ExamAllocationTest | CLASS type; SECTION type; EXAM_GROUP type; STUDENT type; time overlap detection | High |
| StudentGroupTest | Create group; add member; duplicate member rejected; getGroupDetails AJAX | Medium |
| OfflineMarksEntryTest | BULK_TOTAL mode; marks > total_marks rejected; ABSENT status; idempotent re-entry | Critical |
| ExamResultPublicationTest | Publish results; unpublish; re-publish after mark change; student sees result | High |
| GrievanceFlowTest | File grievance; review; resolve with marks change; recompute result; reject | Medium |
| OnlineAttemptTest | Start attempt; save answer; submit; auto-submit on timeout; proctoring log | High |
| HallTicketTest | Available after publish; correct schedule data; set code shown/hidden per flag | Medium |

### 12.3 Security Tests

| Test | Expected Result |
|---|---|
| Unauthenticated access to lms-exam routes | Redirect to login |
| Student role accessing ExamBlueprint (post BUG-02 fix) | 403 Forbidden |
| Student role accessing ExamScope (post BUG-03 fix) | 403 Forbidden |
| Tenant without EXM module (post BUG-04 fix) | 403 Forbidden |
| dd() not present in any controller after BUG-01 fix | Grep passes |

---

## 13. Glossary

| Term | Meaning |
|---|---|
| Exam | A school examination event spanning multiple subjects and days (e.g., Annual Exam 2025-26) |
| Exam Paper | A specific paper for one subject within an exam (e.g., Math Online Paper — Annual Exam) |
| Paper Set | A variant of an exam paper to prevent copying (SET_A, SET_B) |
| Blueprint | Section-level structural definition of a paper (Section A: 20 MCQs at 1 mark each) |
| Scope | Lesson/topic coverage mapping defining which syllabus areas appear in a paper |
| Allocation | Assignment of a paper+set to a class/section/group/student with schedule |
| Attempt | A student's instance of taking an exam (one per student per paper) |
| Proctor | Invigilation mode: Human, AI, or Both |
| Grading Schema | Grade boundary definitions (A+, A, B+...) from slb_grade_division_master |
| BULK_TOTAL | Offline marks entry mode: one total score per student without per-question breakdown |
| QUESTION_WISE | Offline marks entry mode: marks entered per question per student |
| Hall Ticket | Printable PDF document showing student's exam schedule, roll number, venue, and set |
| Grievance | A student's formal objection to their evaluation outcome |
| WITHHELD | A result status applied by Admin when result cannot be released (e.g., fee defaulter) |
| Report Card | PDF document summarizing a student's performance across all papers in an exam |

---

## 14. Suggestions

### P0 — Critical (Must fix before any production deployment)

1. **Remove `dd($e)` from LmsExamController::store() line 565.** Replace with `logger()->error(...)` + safe redirect. The current code blocks transaction rollback and exposes stack traces to users.

2. **Uncomment all 10 Gate::authorize() calls in ExamBlueprintController.** The policy exists and is correctly defined — the calls are only commented out. This is a one-line fix per call but has critical security implications.

3. **Uncomment all 10 Gate::authorize() calls in ExamScopeController.** Same as above. Also register `ExamScopePolicy` in `LmsExamServiceProvider` (it exists but is not registered).

4. **Add `tenant.hasModule:EXM` to the lms-exam route group middleware stack** in `routes/tenant.php` line 520.

### P1 — High (Fix before student pipeline work begins)

5. **Replace `QuestionBank::where('is_active','1')->get()` and `Student::where('is_active','1')->get()`** in `LmsExamController::index()` with AJAX search endpoints. Loading entire question bank and student roster into memory on every tab load will cause memory exhaustion in production schools with 1000+ students.

6. **Extract Service classes:** Create `ExamService` (exam create/publish/conclude/archive, code generation) and `ExamPaperService` (paper set questions logic). `LmsExamController` (820 lines) and `PaperSetQuestionController` (1200+ lines) are too large.

7. **Add `created_by` to five models:** `ExamType`, `ExamStatusEvent`, `ExamScope`, `ExamBlueprint`, `ExamStudentGroup`. The DDL tables do not have this column — a migration is needed to add it, along with model fillable and observer updates.

8. **Add activity logging** to `ExamBlueprintController` and `ExamScopeController` (currently absent despite being present in all other controllers in the module).

### P2 — Medium (Student pipeline implementation)

9. **Implement student online attempt pipeline** (FR-EXM-011): `StudentAttempt` model, `ExamAnswer` model, `AttemptActivityLog` model, `StudentExamAttemptController`. This is the most significant remaining work.

10. **Implement offline marks entry** (FR-EXM-012): `ExamMarksEntry` model, `ExamMarksEntryController`, `ExamResultService`.

11. **Implement result computation and publication** (FR-EXM-013): `ExamResult` model, `ExamResultController`, report card PDF via DomPDF.

12. **Consider removing cross-module model import** of `LmsQuiz\Models\DifficultyDistributionConfig` from `ExamPaper`. Options: shared config module, interface contract, or replicate only the fields needed as a local reference.

### P3 — Lower (Post-student pipeline)

13. **Implement grievance management** (FR-EXM-014): `ExamGrievance` model, `ExamGrievanceController`.

14. **Implement hall ticket generation** (FR-EXM-015): `HallTicketService` using DomPDF.

15. **Write comprehensive tests** — minimum 80 test cases targeting P0 security fixes first (`ExamBlueprintGateTest`, `ExamScopeGateTest`, `EnsureTenantModuleTest`).

16. **Add caching** for reference data (exam types, status events) via `remember()` — these change infrequently and are loaded on every exam creation form.

---

## 15. Appendices

### A. File Inventory

```
Modules/LmsExam/
├── app/Http/Controllers/
│   ├── LmsExamController.php                  (Tab hub + Exam CRUD, ~820 lines, dd bug on line 565)
│   ├── ExamPaperController.php                (CRUD, clean)
│   ├── ExamPaperSetController.php             (CRUD, clean)
│   ├── PaperSetQuestionController.php         (CRUD + 10 AJAX endpoints, ~1200 lines)
│   ├── ExamScopeController.php                (CRUD, Gate disabled — SECURITY BUG)
│   ├── ExamBlueprintController.php            (CRUD, Gate disabled — SECURITY BUG)
│   ├── ExamAllocationController.php           (CRUD + 4 AJAX endpoints, clean)
│   ├── ExamStudentGroupController.php         (CRUD, clean)
│   ├── ExamStudentGroupMemberController.php   (CRUD + getGroupDetails, clean)
│   ├── ExamTypeController.php                 (CRUD, clean)
│   └── ExamStatusEventController.php          (CRUD, clean)
├── app/Models/
│   ├── Exam.php, ExamPaper.php, ExamPaperSet.php
│   ├── ExamScope.php, ExamBlueprint.php, PaperSetQuestion.php
│   ├── ExamAllocation.php, ExamStudentGroup.php, ExamStudentGroupMember.php
│   ├── ExamType.php, ExamStatusEvent.php
│   └── [MISSING] StudentAttempt, ExamAnswer, ExamMarksEntry, ExamResult, ExamGrievance
├── app/Http/Requests/ [11 FormRequests — all clean]
├── app/Policies/
│   ├── ExamPolicy.php, ExamPaperPolicy.php, ExamPaperSetPolicy.php
│   ├── ExamAllocationPolicy.php, ExamStudentGroupPolicy.php, ExamStudentGroupMemberPolicy.php
│   ├── ExamTypePolicy.php, ExamStatusEventPolicy.php, PaperSetQuestionPolicy.php
│   ├── ExamBlueprintPolicy.php    (exists, not enforced)
│   └── ExamScopePolicy.php        (exists, NOT REGISTERED in ServiceProvider)
├── resources/views/ [~55 blade files across 11 folders]
│   └── [MISSING] exam-player/, marks-entry/, result/, grievance/, hall-ticket/
├── routes/web.php  (empty — all routes in /routes/tenant.php)
└── tests/Feature/ [empty], tests/Unit/ [empty]
```

### B. Critical Bug Locations

| Bug ID | File | Line | Fix Required |
|---|---|---|---|
| BUG-01 | `Modules/LmsExam/app/Http/Controllers/LmsExamController.php` | 565 | Remove `dd($e)`, fix rollback order |
| BUG-02 | `Modules/LmsExam/app/Http/Controllers/ExamBlueprintController.php` | Lines 19,42,52,81,87,98,127,152,159,184 | Uncomment 10 Gate::authorize() calls |
| BUG-03 | `Modules/LmsExam/app/Http/Controllers/ExamScopeController.php` | Lines 21,44,56,85,91,104,133,158,165,190 | Uncomment 10 Gate::authorize() calls; register ExamScopePolicy |
| BUG-04 | `routes/tenant.php` | 520 | Add `tenant.hasModule:EXM` to middleware array |

### C. DDL Canonical Source

All table definitions referenced in this document are from:
`/Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/0-DDL_Masters/tenant_db_v2.sql`
Exam section: lines 7136–7793

---

## 16. V1 to V2 Delta

| Section | V1 (2026-03-25) | V2 Changes |
|---|---|---|
| Executive Summary | 65% complete, 4 critical issues noted | Expanded stats; table of critical defects with file+line references |
| FR count | 13 FRs | 16 FRs — added FR-EXM-014 (Grievances), FR-EXM-015 (Hall Tickets), FR-EXM-016 (Module Guard) |
| FR-EXM-003 | Bug noted | 🆕 Exact fix pattern with code snippet added |
| FR-EXM-005/006 | Bug noted | 🆕 Security impact analysis; exact lines added; policy registration gap for ExamScopePolicy added |
| FR-EXM-011 | Placeholder | 🆕 Detailed: startAttempt/saveAnswer/submitAttempt flow; proctoring violation handling; auto-submit job |
| FR-EXM-012 | Placeholder | 🆕 Detailed: BULK_TOTAL vs QUESTION_WISE; roster flow; computeResults; publishResults |
| FR-EXM-013 | Placeholder | 🆕 Full result record fields; rank computation; report card PDF |
| Data Model §5 | 11 tables, basic columns | 🆕 6 DDL-only tables fully documented: lms_student_attempts, lms_exam_answers, lms_exam_marks_entry, lms_exam_results, lms_exam_grievances, lms_attempt_activity_logs |
| Routes §6 | Implemented routes only | 🆕 15 proposed new routes for student pipeline (FR-11 through FR-15) |
| UI Screens §7 | Implemented screens only | 🆕 10 proposed new screens |
| Business Rules §8 | 10 rules | 🆕 20 rules — added rules for proctoring, absent handling, withheld status, grievance window, rank computation |
| Workflow §9 | Single lifecycle diagram | 🆕 3 FSMs: complete end-to-end, paper status FSM, online attempt sequence |
| NFRs §10 | 7 NFRs | 🆕 14 NFRs — added memory limits, service extraction requirement, test coverage target, module licensing |
| Dependencies §11 | Module list only | 🆕 Split into inbound (consumed by EXM) and outbound (consuming EXM); CRT certificate added |
| Test Scenarios §12 | Proposed test plan | 🆕 Detailed table with 6 unit test classes and 13 feature test classes; security test matrix |
| Suggestions §14 | 8 suggestions | 🆕 Reorganized into P0/P1/P2/P3 priority tiers; 16 specific actionable items |
| Appendix B | Known bugs summary table | 🆕 Exact file paths and line numbers for all 4 critical bugs |
