# LmsExam Module — Requirement Specification Document

**Version:** 1.0 | **Date:** 2026-03-25 | **Author:** Claude Code (Automated Extraction)
**Platform:** Prime-AI Academic Intelligence Platform
**Module Code:** EXM | **Module Path:** `Modules/LmsExam`
**Module Type:** Tenant | **Database:** tenant_db
**Table Prefix:** `lms_exam*` | **Processing Mode:** FULL
**RBS Reference:** Module S — Learning Management System (LMS)

---

## 1. EXECUTIVE SUMMARY

LmsExam is the online and offline examination management module of Prime-AI. It covers the complete lifecycle of school examinations: from defining exam types and status events, creating exam blueprints and paper structures, populating question paper sets from the Question Bank, allocating exams to student groups, and eventually (once student-facing layers are built) conducting online exams, entering offline marks, and generating graded results.

**Current implementation status: ~65% complete.**

The teacher-facing setup flow (exam creation, paper creation, paper-set creation, question assignment, student group management, allocation) is substantially implemented with 11 controllers and 11 models. The student-facing attempt and grading pipeline is entirely absent — no attempt, result, or grading controllers exist. A critical debug statement (`dd($e)`) remains in the main store method. Two controllers have Gate authorization commented out, which is a security defect.

**Stats:**
- Controllers: 11 | Models: 11 | Services: 0 | FormRequests: 11 | Tests: 0
- Database tables covered: 11 (lms_exams, lms_exam_papers, lms_exam_paper_sets, lms_exam_scopes, lms_exam_blueprints, lms_paper_set_questions, lms_exam_allocations, lms_exam_student_groups, lms_exam_student_group_members, lms_exam_types, lms_exam_status_events)
- Student attempt tables defined in DDL but no controllers: lms_student_attempts, lms_attempt_answers, lms_exam_marks_entry

---

## 2. MODULE OVERVIEW

### Business Purpose
Enable schools to manage their examination calendar end-to-end: define exam events, design question papers in multiple variants (sets), allocate them to student groups with scheduled timings, allow online or offline execution, and produce graded results.

### Key Features
1. Exam master management (UT-1, UT-2, Half-Yearly, Annual, etc.)
2. Exam paper design per subject with mode selection (ONLINE / OFFLINE)
3. Blueprint and scope definition per paper
4. Paper set variants (SET_A, SET_B) linked to Question Bank
5. Student group definition (ad-hoc cross-section groupings)
6. Student-to-set allocation with scheduling (date, start time, end time, location)
7. Online proctoring configuration (AI proctored, browser lock, full-screen)
8. Offline marks entry (bulk total or question-wise)
9. Result computation and publishing (ABSENT/NOT_STARTED/EVALUATED states)

### Menu Path
`LMS > Exam Management`

### Architecture
Tab-based single-page interface driven by `LmsExamController::index()` which loads all sub-entities in a single request. Individual CRUD operations are handled by separate resource controllers under the `lms-exam.*` route prefix.

---

## 3. STAKEHOLDERS & ACTORS

| Actor | Role |
|---|---|
| Admin / Principal | Creates exam types, status events; final approval of exam publication |
| Subject Teacher | Creates exam papers, defines blueprints/scopes, assigns questions |
| Class Teacher / Exam Coordinator | Creates student groups, manages allocations, enters offline marks |
| Student | (Absent) Takes online exam, views result — NOT YET IMPLEMENTED |
| Parent | (Absent) Views child's result — NOT YET IMPLEMENTED |
| QuestionBank Module | Provides questions via `qns_questions_bank` to `lms_paper_set_questions` |

---

## 4. FUNCTIONAL REQUIREMENTS

### FR-EXM-001: Exam Type Management
**RBS Reference:** S3 (Assessment Management) | **Priority:** High | **Status:** Implemented
**Tables:** `lms_exam_types`

**Description:** CRUD management of exam categories (UT-1, UT-2, HY-EXAM, ANNUAL-EXAM, etc.)

**Actors:** Admin
**Input:** code (VARCHAR 50, UNIQUE), name (VARCHAR 100), description
**Processing:** Soft delete lifecycle; code uniqueness enforced at DB level
**Output:** List of exam types used as FK in lms_exams.exam_type_id

**Acceptance Criteria:**
- Code must be unique across all exam types
- Deletion must soft-delete (set deleted_at, is_active=0)
- Restore must re-activate (is_active=1)

**Current Implementation:**
- `ExamTypeController` — full CRUD + trashed/restore/forceDelete/toggleStatus
- Model: `Modules\LmsExam\Models\ExamType`, table: `lms_exam_types`
- Route: `GET/POST /lms-exam/exam-type`, name prefix `lms-exam.exam-type.*`

**Required Test Cases:**
- TC-EXM-001-01: Create exam type with duplicate code — expect validation error
- TC-EXM-001-02: Soft delete and restore exam type
- TC-EXM-001-03: Toggle active status via AJAX

---

### FR-EXM-002: Exam Status Event Management
**RBS Reference:** S3 | **Priority:** High | **Status:** Implemented
**Tables:** `lms_exam_status_events`

**Description:** Master table of lifecycle statuses for exams, papers, results, and attempts. Status events are typed by `event_type` ENUM (EXAM/PAPER/RESULT/ATTEMPT) and carry a JSON `action_logic` field.

**Actors:** Admin
**Input:** code, name, event_type, action_logic (JSON), description
**Processing:** event_type filters which entities can use the status. EXAM statuses: DRAFT, PUBLISHED, CONCLUDED, ARCHIVED. PAPER statuses: NOT_STARTED → IN_PROGRESS → SUBMITTED → EVALUATED → RESULT_PUBLISHED.

**Current Implementation:**
- `ExamStatusEventController` — full CRUD + trashed/restore/forceDelete/toggleStatus
- Model: `Modules\LmsExam\Models\ExamStatusEvent`
- Route: `lms-exam.exam-status-event.*`

---

### FR-EXM-003: Exam Creation
**RBS Reference:** S3 | **Priority:** Critical | **Status:** Implemented (with bugs)
**Tables:** `lms_exams`

**Description:** Teacher/Admin creates an exam event binding an academic session, class, exam type, date range, grading schema, and initial status.

**Actors:** Admin, Exam Coordinator
**Input:** academic_session_id, class_id, exam_type_id, title, code (auto-generated), start_date, end_date, grading_schema_id, status_id
**Processing:**
- Auto-generates code: `EXAM_{session_code}_{class_code}_{type_code}_{random6}`
- Wraps in `DB::beginTransaction()` / `DB::commit()`
- Writes activity log on success

**Output:** New exam record; redirect to index with success flash

**KNOWN BUG — CRITICAL:**
```php
// LmsExamController::store() line 565
} catch (\Exception $e) {
    dd($e);   // <-- FATAL: halts execution, exposes stack trace to browser, blocks rollback
    DB::rollBack();
```
The `dd($e)` placed BEFORE `DB::rollBack()` means:
1. On any exception, the transaction is never rolled back (partial writes persist)
2. A raw PHP dump is shown to the user exposing internal details
3. The redirect never executes

**Acceptance Criteria:**
- `dd($e)` must be removed before any production release
- Rollback must execute before any response on failure
- Code uniqueness enforced at DB level (UNIQUE KEY uq_exam_code)
- Only one exam per session+class+type combination (UNIQUE KEY uq_exam_session_class_type)

**Current Implementation:**
- `LmsExamController` — index/create/store/show/edit/update/destroy/trashed/restore/forceDelete/toggleStatus
- Route: `lms-exam.exam.*`
- Missing: `EnsureTenantHasModule` middleware on route group

---

### FR-EXM-004: Exam Paper Creation
**RBS Reference:** S3 | **Priority:** Critical | **Status:** Implemented
**Tables:** `lms_exam_papers`

**Description:** Creates a specific paper within an exam for a particular subject and mode (ONLINE/OFFLINE). Defines marks, duration, proctor settings, result display rules, and difficulty config.

**Actors:** Subject Teacher, Exam Coordinator
**Input:** exam_id, class_id, subject_id, paper_code, title, mode, total_marks, passing_percentage, duration_minutes, total_questions, instructions, is_proctored, is_ai_proctored, fullscreen_required, browser_lock_required, shuffle_questions, show_result_type, scheduled_result_at, offline_entry_mode, difficulty_config_id, negative_marks
**Processing:** Paper code is UNIQUE per exam. Difficulty config sourced from `lms_difficulty_distribution_configs` (cross-module dependency on LmsQuiz).

**Current Implementation:**
- `ExamPaperController` — full CRUD + toggleStatus
- Model: `Modules\LmsExam\Models\ExamPaper` references `LmsQuiz\Models\DifficultyDistributionConfig`
- Route: `lms-exam.exam-paper.*`

---

### FR-EXM-005: Exam Blueprint Definition
**RBS Reference:** S3 | **Priority:** High | **Status:** Implemented (Gate disabled — SECURITY BUG)
**Tables:** `lms_exam_blueprints`

**Description:** Defines the structure of a paper by sections (e.g., Section A — MCQ, Section B — Descriptive). Each blueprint row specifies: section name, question type, total questions in section, marks per question, total marks for section, and ordinal.

**KNOWN BUG — SECURITY:**
```php
// ExamBlueprintController — ALL methods
// Gate::authorize('tenant.exam-blueprint.viewAny');  // COMMENTED OUT
// Gate::authorize('tenant.exam-blueprint.create');   // COMMENTED OUT
// Gate::authorize('tenant.exam-blueprint.update');   // COMMENTED OUT
// Gate::authorize('tenant.exam-blueprint.delete');   // COMMENTED OUT
```
All authorization is disabled. Any authenticated user can create/modify/delete exam blueprints.

**Current Implementation:**
- `ExamBlueprintController` — full CRUD + toggleStatus
- Model: `Modules\LmsExam\Models\ExamBlueprint`
- Route: `lms-exam.exam-blueprint.*`

---

### FR-EXM-006: Exam Scope Definition
**RBS Reference:** S3 | **Priority:** High | **Status:** Implemented (Gate disabled — SECURITY BUG)
**Tables:** `lms_exam_scopes`

**Description:** Defines which lessons/topics/question types are included in a paper, along with weightage percentage and target question count. Used for auto-generating questions from the Question Bank.

**KNOWN BUG — SECURITY:** Same pattern as ExamBlueprintController — all Gate::authorize calls are commented out in `ExamScopeController`.

**Current Implementation:**
- `ExamScopeController` — full CRUD + toggleStatus
- Model: `Modules\LmsExam\Models\ExamScope`
- Route: `lms-exam.exam-scope.*`

---

### FR-EXM-007: Exam Paper Set Management
**RBS Reference:** S3 | **Priority:** High | **Status:** Implemented
**Tables:** `lms_exam_paper_sets`

**Description:** Creates variants of a paper (SET_A, SET_B, SET_1, SET_2) to prevent copying. Each set has a unique set_code within the parent paper.

**Current Implementation:**
- `ExamPaperSetController` — full CRUD + toggleStatus
- Model: `Modules\LmsExam\Models\ExamPaperSet`
- Route: `lms-exam.paper-set.*`

---

### FR-EXM-008: Paper Set Question Assignment
**RBS Reference:** S3/S4 | **Priority:** Critical | **Status:** Implemented (rich AJAX endpoints)
**Tables:** `lms_paper_set_questions`

**Description:** Links questions from the Question Bank to a specific paper set with ordering, marks override, negative marks, compulsory/optional flag, and section assignment.

**Actors:** Subject Teacher
**AJAX Endpoints (all under lms-exam prefix):**
- `GET paper-set-question/search` — search QuestionBank
- `GET paper-set-question/existing` — list already-added questions
- `GET paper-set-question/get-sections/subjects/lessons/topics` — cascade filters
- `POST paper-set-question/bulk-store` — add multiple questions at once
- `POST paper-set-question/bulk-destroy` — remove multiple questions
- `POST paper-set-question/update-ordinal` — drag-and-drop reorder
- `POST paper-set-question/update-marks` — inline mark override
- `POST paper-set-question/update-compulsory` — toggle compulsory flag

**Current Implementation:**
- `PaperSetQuestionController` — full CRUD + all AJAX endpoints above
- Model: `Modules\LmsExam\Models\PaperSetQuestion`
- Route: `lms-exam.paper-set-question.*`

---

### FR-EXM-009: Exam Student Group Management
**RBS Reference:** S3 | **Priority:** High | **Status:** Implemented
**Tables:** `lms_exam_student_groups`, `lms_exam_student_group_members`

**Description:** Creates ad-hoc groups for exam purposes (e.g., "9th-A SET-A") within an exam. Members are individual students drawn from the enrolled class.

**Auxiliary endpoint:**
- `GET exam-group-member/get-group-details` — retrieves group meta for member form pre-population

**Current Implementation:**
- `ExamStudentGroupController` — full CRUD
- `ExamStudentGroupMemberController` — full CRUD + `getGroupDetails()`
- Route: `lms-exam.exam-student-group.*`, `lms-exam.exam-group-member.*`

---

### FR-EXM-010: Exam Allocation
**RBS Reference:** S3 | **Priority:** Critical | **Status:** Implemented
**Tables:** `lms_exam_allocations`

**Description:** Maps an exam paper + paper set to a target (CLASS/SECTION/EXAM_GROUP/STUDENT) with scheduling overrides (date, start time, end time) and optional physical location.

**Auxiliary AJAX endpoints:**
- `GET lms-exam/paper-sets` — list paper sets for a paper
- `GET lms-exam/sections` — list sections for a class
- `GET lms-exam/exam-groups` — list student groups for an exam
- `GET lms-exam/students` — list students for a class/section

**Current Implementation:**
- `ExamAllocationController` — full CRUD + auxiliary AJAX endpoints
- Model: `Modules\LmsExam\Models\ExamAllocation`
- Route: `lms-exam.exam-allocation.*`

---

### FR-EXM-011: Student Online Attempt (ABSENT)
**RBS Reference:** S3 | **Priority:** Critical | **Status:** NOT IMPLEMENTED
**Tables:** `lms_student_attempts`, `lms_attempt_answers`

**Description (proposed):** Student navigates to their allocated exam, starts the timed attempt, answers questions one-by-one (MCQ/descriptive), optionally receives timer warnings, and submits. The system records each answer with time_taken_seconds.

**Required controllers (to be created):**
- `StudentExamAttemptController` — startAttempt, saveAnswer, submitAttempt, getAttemptStatus
- Online proctoring integration hooks (violation detection, violation_count increment)

---

### FR-EXM-012: Offline Marks Entry (ABSENT)
**RBS Reference:** S3 | **Priority:** High | **Status:** NOT IMPLEMENTED
**Tables:** `lms_exam_marks_entry`, `lms_attempt_answers` (question-wise mode)

**Description (proposed):** Teacher opens a class roster for a paper, enters total marks per student (BULK_TOTAL mode) or marks per question (QUESTION_WISE mode). System computes percentage, pass/fail status, and grade against the grading schema.

**Required controller (to be created):**
- `ExamMarksEntryController` — bulkEntry, questionWiseEntry, computeResults, publishResults

---

### FR-EXM-013: Result Publication (ABSENT)
**RBS Reference:** S3/S7 | **Priority:** High | **Status:** NOT IMPLEMENTED

**Description (proposed):** Teacher/Admin changes paper status to RESULT_PUBLISHED. Students and parents can view marks, percentage, grade. Optional: generate mark sheet PDF.

---

## 5. DATA MODEL & ENTITY SPECIFICATION

### lms_exam_types
| Column | Type | Constraints |
|---|---|---|
| id | INT UNSIGNED PK | AUTO_INCREMENT |
| code | VARCHAR(50) | UNIQUE NOT NULL |
| name | VARCHAR(100) | NOT NULL |
| description | VARCHAR(255) | NULL |
| is_active, created_at, updated_at, deleted_at | standard | |

### lms_exam_status_events
| Column | Type | Constraints |
|---|---|---|
| id | INT UNSIGNED PK | |
| code | VARCHAR(50) | UNIQUE NOT NULL |
| name | VARCHAR(100) | NOT NULL |
| event_type | ENUM('EXAM','PAPER','RESULT','ATTEMPT') | NOT NULL DEFAULT 'EXAM' |
| action_logic | JSON | NOT NULL |
| is_active, created_at, updated_at, deleted_at | standard | |

### lms_exams
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
| **UNIQUE** | (academic_session_id, class_id, exam_type_id) | one exam per session+class+type |

**Model:** `Modules\LmsExam\Models\Exam`
- Relationships: examType (BelongsTo), class (BelongsTo), status (BelongsTo), academicSession (BelongsTo), gradingSchema (BelongsTo), creator (BelongsTo), examPapers (HasMany), studentGroups (HasMany), allocations (HasMany)
- Scopes: active, published, draft, concluded, archived, byAcademicSession, byClass, byExamType
- Computed attributes: academic_hierarchy, is_published, is_draft, duration_days, statistics

### lms_exam_papers
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
| duration_minutes | INT UNSIGNED | NULL=unlimited |
| total_questions | INT UNSIGNED | |
| negative_marks | DECIMAL(5,2) | |
| instructions | TEXT | |
| only_unused_questions | TINYINT(1) | |
| only_authorised_questions | TINYINT(1) | |
| difficulty_config_id | INT UNSIGNED | FK lms_difficulty_distribution_configs NULL |
| allow_calculator, show_marks_per_question, is_randomized | TINYINT(1) | |
| is_proctored, is_ai_proctored, fullscreen_required, browser_lock_required | TINYINT(1) | online proctor flags |
| shuffle_questions, shuffle_options, timer_enforced | TINYINT(1) | |
| show_result_type | ENUM('IMMEDIATE','SCHEDULED','MANUAL') | |
| scheduled_result_at | DATETIME | NULL |
| offline_entry_mode | ENUM('BULK_TOTAL','QUESTION_WISE') | |
| status_id | INT UNSIGNED | FK lms_exam_status_events |
| is_active, created_at, updated_at, deleted_at | standard | |

**Cross-module dependency:** ExamPaper model imports `LmsQuiz\Models\DifficultyDistributionConfig`

### lms_exam_paper_sets
| Column | Type | Notes |
|---|---|---|
| id | INT UNSIGNED PK | |
| exam_paper_id | INT UNSIGNED | FK lms_exam_papers CASCADE |
| set_code | VARCHAR(20) | UNIQUE per paper (e.g. SET_A) |
| set_name | VARCHAR(50) | |
| description | VARCHAR(255) | NULL |
| is_active, created_at, updated_at, deleted_at | standard | |

### lms_exam_scopes
| Column | Type | Notes |
|---|---|---|
| id | INT UNSIGNED PK | |
| exam_paper_id | INT UNSIGNED | FK lms_exam_papers CASCADE |
| lesson_id | INT UNSIGNED | FK slb_lessons NULL |
| topic_id | INT UNSIGNED | FK slb_topics NULL |
| question_type_id | INT UNSIGNED | FK slb_question_types NULL |
| target_question_count | INT UNSIGNED | 0=all questions |
| weightage_percent | DECIMAL(5,2) | NULL |
| is_active, created_at, updated_at, deleted_at | standard | |

### lms_exam_blueprints
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
| ordinal | TINYINT UNSIGNED | section ordering |
| is_active, created_at, updated_at, deleted_at | standard | |

### lms_paper_set_questions
| Column | Type | Notes |
|---|---|---|
| id | INT UNSIGNED PK | |
| paper_set_id | INT UNSIGNED | FK lms_exam_paper_sets CASCADE |
| question_id | INT UNSIGNED | FK qns_questions_bank |
| section_name | VARCHAR(50) | DEFAULT 'Section A' |
| ordinal | INT UNSIGNED | |
| override_marks | DECIMAL(5,2) | NOT NULL |
| negative_marks | DECIMAL(5,2) | DEFAULT 0.00 |
| is_compulsory | TINYINT(1) | DEFAULT 1 |
| is_active, created_at, updated_at, deleted_at | standard | |
| **UNIQUE** | (paper_set_id, question_id) | |

### lms_exam_student_groups
| Column | Type | Notes |
|---|---|---|
| id | INT UNSIGNED PK | |
| exam_id | INT UNSIGNED | FK lms_exams CASCADE |
| class_id | INT UNSIGNED | FK sch_classes CASCADE |
| section_id | INT UNSIGNED | FK sch_sections CASCADE |
| code | VARCHAR(50) | UNIQUE per exam+class+section |
| name, description | VARCHAR | |
| is_active, created_at, updated_at, deleted_at | standard | |

### lms_exam_student_group_members
| Column | Type | Notes |
|---|---|---|
| id | INT UNSIGNED PK | |
| group_id | INT UNSIGNED | FK lms_exam_student_groups CASCADE |
| student_id | INT UNSIGNED | FK std_students |
| created_at, updated_at, deleted_at | standard | |
| **UNIQUE** | (group_id, student_id) | |

### lms_exam_allocations
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

### lms_student_attempts (DDL defined, no controller)
| Column | Type | Notes |
|---|---|---|
| exam_paper_id, paper_set_id, allocation_id, student_id | INT UNSIGNED | FKs |
| actual_started_time, actual_end_time | DATETIME | |
| actual_time_taken_seconds | INT UNSIGNED | |
| status_id | INT UNSIGNED | FK lms_exam_status_events |
| attempt_mode | ENUM('ONLINE','OFFLINE') | |
| answer_sheet_number | VARCHAR(50) | offline |
| is_present_offline | TINYINT(1) | attendance |
| ip_address, device_info JSON, violation_count | | online proctor |

### lms_exam_marks_entry (DDL defined, no controller)
| Column | Type | Notes |
|---|---|---|
| attempt_id | INT UNSIGNED | FK lms_student_attempts |
| total_marks_obtained | DECIMAL(8,2) | |
| remarks | VARCHAR(255) | |
| entered_by | INT UNSIGNED | FK sys_users |
| entered_at | DATETIME | |

---

## 6. API & ROUTE SPECIFICATION

**Route Prefix:** `/lms-exam` | **Name Prefix:** `lms-exam.`
**Middleware:** `auth`, `verified` (NOTE: `EnsureTenantHasModule` is MISSING)

| Method | URI | Name | Controller | Action |
|---|---|---|---|---|
| GET | /lms-exam/exam | lms-exam.exam.index | LmsExamController | Tab view (all data) |
| GET | /lms-exam/exam/create | lms-exam.exam.create | LmsExamController | Create form |
| POST | /lms-exam/exam | lms-exam.exam.store | LmsExamController | Store |
| GET | /lms-exam/exam/{id} | lms-exam.exam.show | LmsExamController | Show |
| GET | /lms-exam/exam/{id}/edit | lms-exam.exam.edit | LmsExamController | Edit form |
| PUT | /lms-exam/exam/{id} | lms-exam.exam.update | LmsExamController | Update |
| DELETE | /lms-exam/exam/{id} | lms-exam.exam.destroy | LmsExamController | Soft delete |
| GET | /lms-exam/exam/trash/view | lms-exam.exam.trashed | LmsExamController | Trash list |
| GET | /lms-exam/exam/{id}/restore | lms-exam.exam.restore | LmsExamController | Restore |
| DELETE | /lms-exam/exam/{id}/force-delete | lms-exam.exam.forceDelete | LmsExamController | Force delete |
| POST | /lms-exam/exam/{id}/toggle-status | lms-exam.exam.toggleStatus | LmsExamController | Toggle active |
| (resource) | /lms-exam/exam-paper | lms-exam.exam-paper.* | ExamPaperController | Full CRUD |
| (resource) | /lms-exam/exam-scope | lms-exam.exam-scope.* | ExamScopeController | Full CRUD |
| (resource) | /lms-exam/exam-blueprint | lms-exam.exam-blueprint.* | ExamBlueprintController | Full CRUD |
| (resource) | /lms-exam/paper-set | lms-exam.paper-set.* | ExamPaperSetController | Full CRUD |
| GET | /lms-exam/paper-set-question/search | lms-exam.paper-set-question.search | PaperSetQuestionController | QB search |
| POST | /lms-exam/paper-set-question/bulk-store | lms-exam.paper-set-question.bulk-store | PaperSetQuestionController | Bulk add |
| POST | /lms-exam/paper-set-question/update-ordinal | lms-exam.paper-set-question.update-ordinal | PaperSetQuestionController | Reorder |
| (resource) | /lms-exam/exam-allocation | lms-exam.exam-allocation.* | ExamAllocationController | Full CRUD |
| (resource) | /lms-exam/exam-student-group | lms-exam.exam-student-group.* | ExamStudentGroupController | Full CRUD |
| (resource) | /lms-exam/exam-group-member | lms-exam.exam-group-member.* | ExamStudentGroupMemberController | Full CRUD |
| (resource) | /lms-exam/exam-type | lms-exam.exam-type.* | ExamTypeController | Full CRUD |
| (resource) | /lms-exam/exam-status-event | lms-exam.exam-status-event.* | ExamStatusEventController | Full CRUD |

---

## 7. UI SCREEN INVENTORY & FIELD MAPPING

| Screen | View File | Purpose |
|---|---|---|
| Exam Hub (tab) | `tab_module/tab.blade.php` | Main tab container, all sub-entities |
| Exam List | `exam/index.blade.php` | List with search/filter |
| Exam Create | `exam/create.blade.php` | exam_type_id, class_id, dates, grading_schema_id |
| Exam Edit | `exam/edit.blade.php` | Same fields |
| Exam Show | `exam/show.blade.php` | Detail view |
| Exam Trash | `exam/trash.blade.php` | Soft-deleted list |
| Exam Paper List | `exam-paper/index.blade.php` | Filter by exam, class, subject, mode |
| Exam Paper Create | `exam-paper/create.blade.php` | All paper fields including proctor flags |
| Exam Paper Set List | `exam-paper-set/index.blade.php` | Filter by paper |
| Exam Scope | `exam-scope/{create,edit,index,show,trash}.blade.php` | Scope per paper |
| Exam Blueprint | `exam-blueprint/{create,edit,index,show,trash}.blade.php` | Section structure |
| Paper Set Questions | `paper-set-question/{create,edit,index,show,trash}.blade.php` | Question assignment |
| Exam Allocations | `exam-allocation/{create,edit,index,show,trash}.blade.php` | Student allocations |
| Student Groups | `exam-student-group/{create,edit,index,show,trash}.blade.php` | |
| Group Members | `exam-group-member/{create,edit,index,show,trash}.blade.php` | |
| Exam Types | `exam-type/{create,edit,index,show,trash}.blade.php` | Master data |
| Status Events | `exam-status-event/{create,edit,index,show,trash}.blade.php` | Master data |

---

## 8. BUSINESS RULES & DOMAIN CONSTRAINTS

1. **One exam per session+class+type:** DB enforces UNIQUE (academic_session_id, class_id, exam_type_id) on lms_exams.
2. **Paper code uniqueness:** UNIQUE (exam_id, paper_code) on lms_exam_papers.
3. **Set code uniqueness:** UNIQUE (exam_paper_id, set_code) on lms_exam_paper_sets.
4. **Question uniqueness in set:** UNIQUE (paper_set_id, question_id) on lms_paper_set_questions.
5. **Online paper proctor hierarchy:** AI proctoring requires proctoring enabled; browser lock/fullscreen are optional addons.
6. **OFFLINE entry mode:** BULK_TOTAL allows a single total marks entry. QUESTION_WISE requires an entry per question.
7. **Late submission / student cannot appear twice:** UNIQUE (exam_paper_id, student_id) on lms_student_attempts.
8. **Status transitions (EXAM):** DRAFT → PUBLISHED → CONCLUDED → ARCHIVED (no reverse from CONCLUDED)
9. **Marks calculation:** percentage = (marks_obtained / total_marks) * 100; pass = percentage >= passing_percentage
10. **Grading schema lookup:** Grade is determined by comparing percentage against slb_grade_division_master thresholds.

---

## 9. WORKFLOW & STATE MACHINE DEFINITIONS

### Exam Lifecycle
```
[Exam Type Setup] → [Status Events Setup]
     ↓
[Create Exam] (DRAFT)
     ↓
[Create Exam Papers] (per subject + mode)
     ↓
[Define Blueprints] + [Define Scopes]
     ↓
[Create Paper Sets] (SET_A, SET_B...)
     ↓
[Assign Questions from QB] → [paper_set_questions]
     ↓
[Create Student Groups] → [Add Group Members]
     ↓
[Create Exam Allocations] (Paper+Set → Class/Section/Group/Student + Schedule)
     ↓
[PUBLISH Exam]
     ↓
[Exam Day: Online Attempt OR Offline Presence]
     ↓
[Marks Entry / Auto-Grading]
     ↓
[EVALUATED] → [RESULT_PUBLISHED]
     ↓
[CONCLUDED] → [ARCHIVED]
```

### Paper Status Transitions
```
NOT_STARTED → IN_PROGRESS → SUBMITTED → EVALUATION_PENDING → EVALUATED → RESULT_PUBLISHED
(also: ABSENT, CANCELLED at any pre-submission stage)
```

---

## 10. NON-FUNCTIONAL REQUIREMENTS

| # | Requirement | Target |
|---|---|---|
| NFR-EXM-01 | Response time for tab index (11 paginated queries) | < 2 seconds |
| NFR-EXM-02 | Online exam security: prevent tab switching, copy-paste | Browser lock + fullscreen |
| NFR-EXM-03 | Concurrent online exam sessions | 500+ students simultaneously |
| NFR-EXM-04 | Question paper confidentiality | Paper sets not visible to students until allocation published_at |
| NFR-EXM-05 | Data integrity | All write operations in DB transactions |
| NFR-EXM-06 | Audit trail | All CUD operations logged via activityLog() |
| NFR-EXM-07 | Multi-tenancy isolation | All tables in tenant_db, no cross-tenant data leakage |

---

## 11. CROSS-MODULE DEPENDENCIES

| Module | Dependency Type | Detail |
|---|---|---|
| **QuestionBank** | CRITICAL | `qns_questions_bank` is the source for `lms_paper_set_questions.question_id`. PaperSetQuestionController searches QB via `Modules\QuestionBank\Models\QuestionBank`. |
| **LmsQuiz** | SHARED MODEL | `ExamPaper` and `ExamPaper` model import `LmsQuiz\Models\DifficultyDistributionConfig` — cross-module model dependency. `lms_difficulty_distribution_configs` is owned by LmsQuiz. |
| **SchoolSetup** | FK DEPENDENCY | `sch_classes`, `sch_sections`, `sch_subjects` used throughout |
| **Syllabus** | FK DEPENDENCY | `slb_lessons`, `slb_topics`, `slb_question_types`, `slb_grade_division_master`, `slb_complexity_level` used in scopes/blueprints |
| **StudentProfile** | FK DEPENDENCY | `std_students` used in group members and allocations |
| **Prime (Academic)** | FK DEPENDENCY | `glb_academic_sessions` for academic session FK |

---

## 12. TEST CASE REFERENCE & COVERAGE

**Current test coverage: 0 tests**

### Proposed Test Plan

**Unit Tests (Pest):**
- `ExamCodeGeneratorTest` — verify code format, uniqueness loop
- `ExamStatusTransitionTest` — valid/invalid status changes
- `MarksCalculationTest` — percentage, pass/fail, grade lookup

**Feature Tests:**
- `ExamCreationTest` — happy path create, duplicate code, missing required fields
- `ExamPaperTest` — online/offline mode, proctor flags validation
- `PaperSetQuestionTest` — bulk-store, ordinal update, marks override
- `ExamAllocationTest` — CLASS/SECTION/GROUP/STUDENT allocation types
- `ExamBlueprintGateTest` — verify Gate IS enforced after fix (currently disabled)
- `ExamStoreRollbackTest` — force exception in store, verify transaction rolled back and dd() removed

---

## 13. GLOSSARY & TERMINOLOGY

| Term | Meaning |
|---|---|
| Exam | A school examination event spanning multiple subjects and days (e.g., Annual Exam 2025-26) |
| Exam Paper | A specific paper for one subject within an exam (e.g., Math Online Paper) |
| Paper Set | A variant of an exam paper to prevent copying (SET_A, SET_B) |
| Blueprint | Section-level structure definition of a paper (Section A: 20 MCQs × 1 mark) |
| Scope | Lesson/topic coverage mapping for a paper, used for auto-question selection |
| Allocation | Assignment of a paper+set to a class/section/group/student with schedule |
| Proctor | Invigilation mode: Human, AI, or Both |
| Grading Schema | Grade boundary definitions (A+, A, B+...) from slb_grade_division_master |
| BULK_TOTAL | Offline marks entry mode: one total score per student |
| QUESTION_WISE | Offline marks entry mode: marks entered per question |

---

## 14. ADDITIONAL SUGGESTIONS

1. **Remove `dd($e)` immediately** — this is a production-blocking bug. Replace with `logger()->error()` and return a safe error response.
2. **Re-enable Gate::authorize** in ExamBlueprintController and ExamScopeController before any production deployment.
3. **Add `EnsureTenantHasModule` middleware** to the `lms-exam` route group to prevent unauthorized module access.
4. **Extract Service Layer:** `ExamService` (create, publish, conclude, archive), `MarksEntryService` (bulk, question-wise, compute, publish) — the controller is doing too much.
5. **Implement student attempt pipeline** as the highest-priority remaining work: StudentExamAttemptController + ExamMarksEntryController.
6. **Add `lms_student_attempts` and `lms_attempt_answers` Models** to the module — they exist in DDL but have no Eloquent representation.
7. **Performance:** The tab index loads 11 paginated queries simultaneously. Consider deferred/lazy loading for less-used tabs.
8. **Consider removing cross-module model import** of `LmsQuiz\Models\DifficultyDistributionConfig` in `ExamPaper` — use an interface or a shared config module instead.

---

## 15. APPENDICES

### A. File Inventory
```
Modules/LmsExam/
├── app/Http/Controllers/
│   ├── LmsExamController.php          (tab hub + Exam CRUD, 819 lines)
│   ├── ExamPaperController.php        (CRUD)
│   ├── ExamPaperSetController.php     (CRUD)
│   ├── PaperSetQuestionController.php (CRUD + 8 AJAX endpoints)
│   ├── ExamScopeController.php        (CRUD, Gate disabled)
│   ├── ExamBlueprintController.php    (CRUD, Gate disabled)
│   ├── ExamAllocationController.php   (CRUD + 4 AJAX endpoints)
│   ├── ExamStudentGroupController.php (CRUD)
│   ├── ExamStudentGroupMemberController.php (CRUD + getGroupDetails)
│   ├── ExamTypeController.php         (CRUD)
│   └── ExamStatusEventController.php  (CRUD)
├── app/Models/ [11 models]
├── app/Http/Requests/ [11 FormRequests]
├── app/Policies/ [ExamAllocationPolicy, ExamPaperPolicy]
├── resources/views/ [~55 blade files across 11 folders]
└── routes/web.php (minimal — main routes in tenant.php)
```

### B. Route Group Location
All functional routes for LmsExam are defined in `/Users/bkwork/Herd/prime_ai/routes/tenant.php` lines 556–667 under the `lms-exam` prefix group.

### C. Known Bugs Summary
| Bug | Location | Severity |
|---|---|---|
| `dd($e)` before DB::rollBack() | LmsExamController::store() line 565 | CRITICAL |
| All Gate::authorize commented out | ExamBlueprintController (all methods) | HIGH SECURITY |
| All Gate::authorize commented out | ExamScopeController (all methods) | HIGH SECURITY |
| EnsureTenantHasModule middleware missing | Route group in tenant.php | MEDIUM |
| No student attempt/grading controllers | Entire student pipeline | HIGH |
| 0 tests | All controllers | HIGH |
