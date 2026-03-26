# LmsQuiz Module — Requirement Specification Document

**Version:** 1.0 | **Date:** 2026-03-25 | **Author:** Claude Code (Automated Extraction)
**Platform:** Prime-AI Academic Intelligence Platform
**Module Code:** QUZ | **Module Path:** `Modules/LmsQuiz`
**Module Type:** Tenant | **Database:** tenant_db
**Table Prefix:** `lms_quiz*` | **Processing Mode:** FULL
**RBS Reference:** Module S — Learning Management System (LMS)

---

## 1. EXECUTIVE SUMMARY

LmsQuiz is the primary short-form assessment module of Prime-AI. A "Quiz" is a lesson/topic-scoped timed assessment typically used for quick knowledge checks, practice, revision, and diagnostic purposes. The module owns the shared masters (`lms_assessment_types`, `lms_difficulty_distribution_configs`, `lms_difficulty_distribution_details`) used by both Quiz and Quest modules. It supports automatic question generation based on difficulty distribution profiles, timer enforcement, randomisation, negative marking, multiple attempts, and flexible result display. Student attempt tracking uses the shared `lms_quiz_quest_attempts` table.

**Current implementation status: ~70% complete.**

The teacher-facing quiz creation, difficulty configuration, assessment type management, question assignment (with a rich difficulty-builder AJAX interface), and allocation flows are functional. The student-facing attempt pipeline is entirely absent. Two critical defects exist: (1) `Gate::authorize` is commented out in `LmsQuizController::index()` — a security gap; (2) the route prefix and route names contain a typo `lms-quize` / `quize` instead of `lms-quiz` / `quiz`, which will cause hard-to-trace 404 errors in link generation.

**Stats:**
- Controllers: 5 | Models: 6 | Services: 0 | FormRequests: 5 | Tests: 0
- Database tables owned: `lms_quizzes`, `lms_quiz_questions`, `lms_quiz_allocations`, `lms_difficulty_distribution_configs`, `lms_difficulty_distribution_details`, `lms_assessment_types`
- Shared attempt tables: `lms_quiz_quest_attempts`, `lms_quiz_quest_attempt_answers`

---

## 2. MODULE OVERVIEW

### Business Purpose
Enable teachers to create topic-focused quizzes that assess student understanding quickly. Quizzes can be manually constructed or auto-generated using difficulty distribution profiles (percentages of Easy/Medium/Hard questions). They are allocated to classes/sections/groups/students with configurable windows. The module also owns and maintains the shared configuration masters used across all assessment modules.

### Key Features
1. Assessment Type management (Challenge, Enrichment, Practice, Revision, Re-Test, Diagnostic, Remedial) — shared with LmsQuests and LmsExam
2. Difficulty Distribution Config management (profiles for auto-question selection) — shared with LmsQuests and LmsExam
3. Difficulty Distribution Detail lines (per-question-type percentage allocations)
4. Quiz creation with full academic hierarchy alignment
5. Difficulty-builder AJAX interface for automatic question selection by profile
6. Manual question assignment with ordinal and marks override
7. Quiz allocation to CLASS/SECTION/GROUP/STUDENT with published/due/cut-off dates
8. Timer enforcement, randomisation, negative marking, multiple attempts
9. Result display options: immediate, teacher-manual, auto-publish

### Menu Path
`LMS > Quiz`

### Architecture
Tab-based single-page interface via `LmsQuizController::index()`. The module is the owner of shared master tables. Route prefix uses typo `lms-quize` instead of `lms-quiz`. Individual CRUD under `lms-quize.*` prefix.

---

## 3. STAKEHOLDERS & ACTORS

| Actor | Role |
|---|---|
| Admin | Creates assessment types, difficulty configs; system-wide settings |
| Teacher | Creates quizzes, assigns questions, creates allocations |
| Student | (Absent) Takes quiz, views result — NOT YET IMPLEMENTED |
| Parent | (Absent) Views child's quiz result — NOT YET IMPLEMENTED |
| QuestionBank Module | Provides questions via qns_questions_bank |
| LmsQuests Module | Consumes AssessmentType and DifficultyDistributionConfig from this module |
| LmsExam Module | Consumes DifficultyDistributionConfig and model from this module |

---

## 4. FUNCTIONAL REQUIREMENTS

### FR-QUZ-001: Assessment Type Management
**RBS Reference:** S3 (Assessment Management — classification) | **Priority:** High | **Status:** Implemented
**Tables:** `lms_assessment_types`

**Description:** CRUD management of assessment categories used across Quiz, Quest, and indirectly Exam. Each type has a code, name, description, and is linked to a usage type (QUIZ/QUEST/ONLINE_EXAM/OFFLINE_EXAM).

**Actors:** Admin
**Input:** code (UNIQUE), name, assessment_usage_type_id (FK to qns_question_usage_type), description
**Processing:** Soft delete lifecycle. Code uniqueness at DB level.

**Key values:** Challenge, Enrichment, Practice, Revision, Re-Test, Diagnostic, Remedial

**Current Implementation:**
- `AssessmentTypeController` — full CRUD + trashed/restore/forceDelete/toggleStatus
- Model: `Modules\LmsQuiz\Models\AssessmentType`
- Route: `lms-quize.assessment-type.*`

**Required Test Cases:**
- TC-QUZ-001-01: Create duplicate assessment type code — expect validation error
- TC-QUZ-001-02: Filter by usage type (QUIZ vs QUEST)

---

### FR-QUZ-002: Difficulty Distribution Config Management
**RBS Reference:** S3.1.2 | **Priority:** High | **Status:** Implemented
**Tables:** `lms_difficulty_distribution_configs`, `lms_difficulty_distribution_details`

**Description:** Manages profiles that define what percentage of questions should be Easy/Medium/Hard per question type. A config (e.g., "Standard Quiz Balanced") has one or more detail rows specifying: question_type_id, complexity_level_id, Bloom taxonomy level, cognitive skill, min_percentage, max_percentage, marks_per_question.

**Actors:** Admin
**Input (Config):** code, name, description, usage_type_id
**Input (Detail rows):** difficulty_config_id, question_type_id, complexity_level_id, bloom_id, cognitive_skill_id, min_percentage, max_percentage, marks_per_question

**Current Implementation:**
- `DifficultyDistributionConfigController` — full CRUD for config + details
- Models: `DifficultyDistributionConfig`, `DifficultyDistributionDetail`
- Route: `lms-quize.difficulty-distribution-config.*`
- View: `quiz-question/difficulty_builder_tab.blade.php` for visual difficulty profile builder

---

### FR-QUZ-003: Quiz Creation
**RBS Reference:** S3.1 (Quiz Builder) | **Priority:** Critical | **Status:** Implemented (Gate disabled — SECURITY BUG + route name typo)
**Tables:** `lms_quizzes`

**Description:** Teacher creates a quiz with academic hierarchy, assessment type, scope topic, difficulty config, grading settings, timer, randomisation, attempt policy, and result display options.

**Actors:** Teacher, Admin
**Input:** quiz_code (auto-generated), academic_session_id, class_id, subject_id, lesson_id, scope_topic_id, quiz_type_id, title, description, instructions, status, duration_minutes, total_marks, total_questions, passing_percentage, allow_multiple_attempts, max_attempts, negative_marks, is_randomized, question_marks_shown, show_result_immediately, auto_publish_result, timer_enforced, show_correct_answer, show_explanation, difficulty_config_id, ignore_difficulty_config, is_system_generated

**Processing:**
- Auto-generates quiz_code: `QUIZ_{session}_{class}_{subject}_{lesson}_{topic}_{random4}`
- UUID assigned in model boot

**KNOWN BUG 1 — SECURITY:**
```php
// LmsQuizController::index() line 34
// Gate::authorize('tenant.quiz.viewAny');  // COMMENTED OUT
```
Any authenticated user can list all quizzes regardless of permissions.

**KNOWN BUG 2 — ROUTE NAME TYPO:**
```php
// LmsQuizController::store() line 287
return redirect()->route('lms-quize.quize.index')  // 'quize' is a typo — should be 'quiz'
// Also in update(), restore(), destroy(), forceDelete()
```
The route prefix in tenant.php is `lms-quize` with route name prefix `lms-quize.` and resource name `quize`. This typo appears in both the route definition and all redirect calls. It will cause 404 errors if any external component references the correct spelling.

**Auxiliary AJAX endpoint:**
- `POST /lms-quize/get-lessons` — returns lessons for a selected class+subject combination

**Acceptance Criteria:**
- Quiz code must be globally unique
- Gate authorization must be re-enabled
- Route prefix and names should be corrected from `quize` to `quiz`
- Missing: `EnsureTenantHasModule` middleware

**Current Implementation:**
- `LmsQuizController` — index (Gate disabled), create, store, show, edit, update, destroy, trashed, restore, forceDelete, toggleStatus, getLessons
- Model: `Modules\LmsQuiz\Models\Quiz`, table: `lms_quizzes`
- Route: `lms-quize.quize.*` (typo — should be `lms-quiz.quiz.*`)

---

### FR-QUZ-004: Quiz Question Assignment
**RBS Reference:** S3.1 / S4 | **Priority:** Critical | **Status:** Implemented (rich AJAX difficulty-builder)
**Tables:** `lms_quiz_questions`

**Description:** Links questions from the Question Bank to a Quiz. Supports two workflows: (a) manual question selection via search interface; (b) automated question selection via difficulty builder that fetches questions matching the difficulty profile.

**Actors:** Teacher
**Input:** quiz_id, question_id, ordinal, marks_override

**AJAX Endpoints (under lms-quize prefix):**
- `POST /lms-quize/difficulty-builder/questions` — fetch questions matching difficulty profile filters
- `POST /lms-quize/difficulty-builder/add` — add fetched questions in bulk
- `POST /lms-quize/difficulty-builder/quiz-meta` — get quiz metadata for builder
- `GET /lms-quize/get-sections` — sections for class
- `GET /lms-quize/get-subject-groups` — subject groups
- `GET /lms-quize/get-subjects` — subjects
- `GET /lms-quize/get-topics` — topics for lesson
- `GET /lms-quize/search` — manual QB search
- `GET /lms-quize/existing` — existing questions in quiz
- `POST /lms-quize/bulk-store` — add multiple questions
- `POST /lms-quize/bulk-destroy` — remove multiple questions
- `POST /lms-quize/update-ordinal` — drag-and-drop reorder
- `POST /lms-quize/update-marks` — inline marks override

**Acceptance Criteria:**
- UNIQUE (quiz_id, question_id) prevents duplicate questions
- Difficulty builder respects min/max percentages from config
- `only_unused_questions = 1` must filter out questions already in `qns_question_usage_log`
- `only_authorised_questions = 1` must filter to `qns_questions_bank.for_quiz = 1`

**Current Implementation:**
- `QuizQuestionController` — full CRUD + 13 AJAX endpoints + difficulty builder endpoints
- Model: `Modules\LmsQuiz\Models\QuizQuestion`
- Route: `lms-quize.quiz-question.*`
- Special view: `quiz-question/difficulty_builder_tab.blade.php`

---

### FR-QUZ-005: Quiz Allocation
**RBS Reference:** S3.1.2 | **Priority:** Critical | **Status:** Implemented
**Tables:** `lms_quiz_allocations`

**Description:** Assigns a published quiz to a target (CLASS/SECTION/GROUP/STUDENT) with timing windows.

**Actors:** Teacher, Admin
**Input:** quiz_id, allocation_type, target_table_name, target_id, assigned_by, published_at, due_date, cut_off_date, is_auto_publish_result, result_publish_date

**Note:** `is_auto_publish_result` in this table OVERRIDES the quiz-level `auto_publish_result` setting for this specific allocation, allowing different publish-timing per group.

**Current Implementation:**
- `QuizAllocationController` — full CRUD + trashed/restore/forceDelete/toggleStatus
- Model: `Modules\LmsQuiz\Models\QuizAllocation`
- Route: `lms-quize.quiz-allocation.*`

---

### FR-QUZ-006: Student Quiz Attempt (ABSENT)
**RBS Reference:** S3.1 / S5 | **Priority:** Critical | **Status:** NOT IMPLEMENTED
**Tables:** `lms_quiz_quest_attempts`, `lms_quiz_quest_attempt_answers`

**Description (proposed):** Student sees quizzes allocated to them during the published/due window. Student starts timed attempt. System loads questions (randomised if configured). Student answers each question. Auto-submit on timer expiry. System grades MCQ instantly; descriptive flagged for teacher. Result shown based on `show_result_immediately` and `auto_publish_result`.

**Shared infrastructure:**
- `lms_quiz_quest_attempts.assessment_type = 'QUIZ'`
- `lms_quiz_quest_attempt_answers` for per-question responses

**Required controllers (to be created):**
- `StudentQuizAttemptController` — myQuizzes, startAttempt, saveAnswer, submitAttempt, viewResult
- Auto-submit job for timer expiry

---

### FR-QUZ-007: Automatic Quiz Generation (PARTIALLY SPECIFIED)
**RBS Reference:** S3.1.2 | **Priority:** Medium | **Status:** NOT IMPLEMENTED

**Description (proposed):** When `is_system_generated = 1`, the system should automatically select questions from the QB based on the difficulty_config_id distribution, the scope (lesson/topic), and the `only_unused_questions` / `only_authorised_questions` flags. This would create quiz questions automatically without teacher manual selection.

**Note:** The flags and config columns exist in the DDL. No controller method or service implements this generation logic.

---

## 5. DATA MODEL & ENTITY SPECIFICATION

### lms_assessment_types (SHARED MASTER — owned by LmsQuiz)
| Column | Type | Notes |
|---|---|---|
| id | INT UNSIGNED PK | |
| code | VARCHAR(20) | UNIQUE NOT NULL |
| name | VARCHAR(100) | NOT NULL |
| assessment_usage_type_id | INT UNSIGNED | FK qns_question_usage_type |
| description | VARCHAR(255) | NULL |
| is_active, created_at, updated_at, deleted_at | standard | |

**Imported by:** Modules\LmsQuests (Quest model), Modules\LmsExam (ExamPaper, ExamStudentGroup via LmsExamController)

### lms_difficulty_distribution_configs (SHARED MASTER — owned by LmsQuiz)
| Column | Type | Notes |
|---|---|---|
| id | INT UNSIGNED PK | |
| code | VARCHAR(50) | UNIQUE NOT NULL |
| name | VARCHAR(100) | NOT NULL |
| description | VARCHAR(255) | NULL |
| usage_type_id | INT UNSIGNED | FK qns_question_usage_type (QUIZ/QUEST/EXAM) |
| is_active, created_at, updated_at, deleted_at | standard | |

**Imported by:** Modules\LmsQuests (Quest model), Modules\LmsExam (ExamPaper model)

### lms_difficulty_distribution_details
| Column | Type | Notes |
|---|---|---|
| id | INT UNSIGNED PK | |
| difficulty_config_id | INT UNSIGNED | FK lms_difficulty_distribution_configs CASCADE |
| question_type_id | INT UNSIGNED | FK slb_question_types |
| complexity_level_id | INT UNSIGNED | FK slb_complexity_level |
| bloom_id | INT UNSIGNED | FK slb_bloom_taxonomy NULL |
| cognitive_skill_id | INT UNSIGNED | FK slb_cognitive_skill NULL |
| ques_type_specificity_id | INT UNSIGNED | FK slb_ques_type_specificity NULL |
| min_percentage | DECIMAL(5,2) | DEFAULT 0.00 |
| max_percentage | DECIMAL(5,2) | DEFAULT 0.00 |
| marks_per_question | DECIMAL(5,2) | NULL |
| is_active, created_at, updated_at, deleted_at | standard | |

### lms_quizzes
| Column | Type | Notes |
|---|---|---|
| id | INT UNSIGNED PK | |
| uuid | BINARY(16) | UNIQUE NOT NULL |
| academic_session_id | INT UNSIGNED | FK glb_academic_sessions CASCADE |
| class_id | INT UNSIGNED | FK sch_classes CASCADE |
| subject_id | INT UNSIGNED | FK sch_subjects CASCADE |
| lesson_id | INT UNSIGNED | FK sch_lessons CASCADE |
| scope_topic_id | INT UNSIGNED | FK slb_topics NULL (primary scope topic) |
| quiz_type_id | INT UNSIGNED | FK lms_assessment_types |
| quiz_code | VARCHAR(50) | UNIQUE NOT NULL |
| title | VARCHAR(100) | NOT NULL |
| description | VARCHAR(255) | NULL |
| instructions | TEXT | NULL |
| status | VARCHAR(20) | DEFAULT 'DRAFT' (DRAFT/PUBLISHED/ARCHIVED) |
| duration_minutes | TINYINT UNSIGNED | NULL=unlimited |
| total_marks | DECIMAL(8,2) | DEFAULT 0.00 |
| total_questions | INT UNSIGNED | DEFAULT 0 |
| passing_percentage | DECIMAL(5,2) | DEFAULT 33.00 |
| allow_multiple_attempts | TINYINT(1) | DEFAULT 0 |
| max_attempts | TINYINT UNSIGNED | DEFAULT 1 |
| negative_marks | DECIMAL(4,2) | DEFAULT 0.00 |
| is_randomized | TINYINT(1) | DEFAULT 0 |
| question_marks_shown | TINYINT(1) | DEFAULT 0 |
| show_result_immediately | TINYINT(1) | DEFAULT 0 |
| auto_publish_result | TINYINT(1) | DEFAULT 0 |
| timer_enforced | TINYINT(1) | DEFAULT 1 |
| show_correct_answer | TINYINT(1) | DEFAULT 0 |
| show_explanation | TINYINT(1) | DEFAULT 0 |
| difficulty_config_id | INT UNSIGNED | FK lms_difficulty_distribution_configs NULL |
| ignore_difficulty_config | TINYINT(1) | DEFAULT 0 |
| is_system_generated | TINYINT(1) | DEFAULT 0 |
| only_unused_questions | TINYINT(1) | DEFAULT 0 |
| only_authorised_questions | TINYINT(1) | DEFAULT 0 |
| created_by | INT UNSIGNED | FK sys_users NULL |
| is_active, created_at, updated_at, deleted_at | standard | |
| INDEX | (scope_topic_id) | idx_quiz_topic |
| INDEX | (status) | idx_quiz_status |

**Model:** `Modules\LmsQuiz\Models\Quiz`
- Relationships: academicSession, class, subject, lesson, assessmentType (quiz_type_id), topic (scope_topic_id), difficultyConfig, creator, quizQuestions (HasMany), questions (BelongsToMany), allocations (HasMany)
- Scopes: active, published, draft
- Key methods: isAvailable()
- Boot: auto-generates uuid + quiz_code
- Computed: academic_hierarchy

**MODEL-DDL NOTE:** `Quiz` model has `lesson_id` in fillable and `lesson()` BelongsTo — DDL has `lesson_id` as a proper column in `lms_quizzes`. This is consistent (unlike Quest). However, the model fillable list is missing `only_unused_questions` and `only_authorised_questions` — these columns exist in DDL but are not in `$fillable`.

### lms_quiz_questions
| Column | Type | Notes |
|---|---|---|
| id | INT UNSIGNED PK | |
| quiz_id | INT UNSIGNED | FK lms_quizzes CASCADE |
| question_id | INT UNSIGNED | FK qns_questions_bank CASCADE |
| ordinal | INT UNSIGNED | DEFAULT 0 |
| marks_override | DECIMAL(5,2) | NULL |
| is_active, created_at, updated_at, deleted_at | standard | |
| **UNIQUE** | (quiz_id, question_id) | |

### lms_quiz_allocations
| Column | Type | Notes |
|---|---|---|
| id | INT UNSIGNED PK | |
| quiz_id | INT UNSIGNED | FK lms_quizzes CASCADE |
| allocation_type | ENUM('CLASS','SECTION','GROUP','STUDENT') | |
| target_table_name | VARCHAR(60) | App-level FK only |
| target_id | INT UNSIGNED | Polymorphic |
| assigned_by | INT UNSIGNED | FK sys_users NULL |
| published_at | DATETIME | NULL |
| due_date | DATETIME | NULL |
| cut_off_date | DATETIME | NULL |
| is_auto_publish_result | TINYINT(1) | DEFAULT 0 (OVERRIDES quiz-level setting) |
| result_publish_date | DATETIME | NULL |
| is_active, created_at, updated_at, deleted_at | standard | |
| INDEX | (allocation_type, target_id) | |

### lms_quiz_quest_attempts (SHARED with LmsQuests)
See Section 5 of QST_LmsQuests_Requirement.md — identical structure with `assessment_type = 'QUIZ'`.

---

## 6. API & ROUTE SPECIFICATION

**Route Prefix:** `/lms-quize` (TYPO — should be `/lms-quiz`)
**Name Prefix:** `lms-quize.` (TYPO — should be `lms-quiz.`)
**Middleware:** `auth`, `verified` (NOTE: `EnsureTenantHasModule` is MISSING)

| Method | URI | Name | Controller | Action |
|---|---|---|---|---|
| GET | /lms-quize/quize | lms-quize.quize.index | LmsQuizController | Tab view (Gate DISABLED) |
| GET | /lms-quize/quize/create | lms-quize.quize.create | LmsQuizController | Create form |
| POST | /lms-quize/quize | lms-quize.quize.store | LmsQuizController | Store |
| GET | /lms-quize/quize/{id} | lms-quize.quize.show | LmsQuizController | Show |
| GET | /lms-quize/quize/{id}/edit | lms-quize.quize.edit | LmsQuizController | Edit form |
| PUT | /lms-quize/quize/{id} | lms-quize.quize.update | LmsQuizController | Update |
| DELETE | /lms-quize/quize/{id} | lms-quize.quize.destroy | LmsQuizController | Soft delete + ARCHIVED |
| GET | /lms-quize/quize/trash/view | lms-quize.quize.trashed | LmsQuizController | Trash list |
| GET | /lms-quize/quize/{id}/restore | lms-quize.quize.restore | LmsQuizController | Restore |
| DELETE | /lms-quize/quize/{id}/force-delete | lms-quize.quize.forceDelete | LmsQuizController | Force delete |
| POST | /lms-quize/quize/{id}/toggle-status | lms-quize.quize.toggleStatus | LmsQuizController | Toggle active |
| POST | /lms-quize/get-lessons | lms-quize.get-lessons | LmsQuizController | AJAX: lessons |
| (resource) | /lms-quize/assessment-type | lms-quize.assessment-type.* | AssessmentTypeController | Full CRUD |
| (resource) | /lms-quize/difficulty-distribution-config | lms-quize.difficulty-distribution-config.* | DifficultyDistributionConfigController | Full CRUD |
| (resource) | /lms-quize/quiz-allocation | lms-quize.quiz-allocation.* | QuizAllocationController | Full CRUD |
| (resource) | /lms-quize/quiz-question | lms-quize.quiz-question.* | QuizQuestionController | Full CRUD |
| POST | /lms-quize/difficulty-builder/questions | lms-quize.difficulty.builder.fetch | QuizQuestionController | Fetch by profile |
| POST | /lms-quize/difficulty-builder/add | lms-quize.difficulty.builder.add | QuizQuestionController | Add by profile |
| POST | /lms-quize/difficulty-builder/quiz-meta | lms-quize.difficulty.builder.quiz-meta | QuizQuestionController | Quiz metadata |
| GET | /lms-quize/get-sections | lms-quize.get-sections | QuizQuestionController | AJAX sections |
| GET | /lms-quize/get-topics | lms-quize.get-topics | QuizQuestionController | AJAX topics |
| GET | /lms-quize/search | lms-quize.search | QuizQuestionController | QB search |
| GET | /lms-quize/existing | lms-quize.existing | QuizQuestionController | Existing questions |
| POST | /lms-quize/bulk-store | lms-quize.bulk-store | QuizQuestionController | Bulk add |
| POST | /lms-quize/bulk-destroy | lms-quize.bulk-destroy | QuizQuestionController | Bulk remove |
| POST | /lms-quize/update-ordinal | lms-quize.update-ordinal | QuizQuestionController | Reorder |
| POST | /lms-quize/update-marks | lms-quize.update-marks | QuizQuestionController | Marks override |

---

## 7. UI SCREEN INVENTORY & FIELD MAPPING

| Screen | View File | Purpose |
|---|---|---|
| Quiz Hub (tab) | `tab_module/tab.blade.php` | Main container: quizzes, configs, types, questions, allocations |
| Quiz Create | `quiz/create.blade.php` | All quiz fields including difficulty config, timer, attempts |
| Quiz Edit | `quiz/edit.blade.php` | Same fields |
| Quiz Show | `quiz/show.blade.php` | Detail + questions list |
| Quiz Trash | `quiz/trash.blade.php` | |
| Quiz List | `quiz/index.blade.php` | Filter by status, type, topic, date |
| Assessment Types | `assessment-type/{create,edit,index,show,trash}.blade.php` | Master data |
| Difficulty Config | `difficulty-config/{create,edit,index,show,trash}.blade.php` | Config profiles |
| Quiz Questions | `quiz-question/{create,edit,index,show,trash}.blade.php` | Question assignment |
| Difficulty Builder | `quiz-question/difficulty_builder_tab.blade.php` | Auto-selection by profile |
| Quiz Allocations | `quiz-allocation/{create,edit,index,show,trash}.blade.php` | |

---

## 8. BUSINESS RULES & DOMAIN CONSTRAINTS

1. **Quiz code uniqueness:** UNIQUE (quiz_code) enforced at DB level.
2. **Question uniqueness:** UNIQUE (quiz_id, question_id) prevents duplicates.
3. **Allocation override:** `is_auto_publish_result` on `lms_quiz_allocations` OVERRIDES the quiz-level `auto_publish_result` setting. Allocation-level setting takes precedence.
4. **Cut-off date:** No attempt starts after `cut_off_date` even if max_attempts not reached.
5. **only_unused_questions:** When 1, only questions NOT present in `qns_question_usage_log` for this student are eligible for selection.
6. **only_authorised_questions:** When 1, only questions where `qns_questions_bank.for_quiz = 1` are eligible.
7. **Difficulty distribution min/max:** Sum of min_percentages per config should not exceed 100%. Sum of max_percentages must equal 100%.
8. **Assessment type to usage type binding:** Assessment types are linked to a `qns_question_usage_type` (QUIZ/QUEST/ONLINE_EXAM/OFFLINE_EXAM). Only types with the correct usage type should appear in quiz creation dropdowns.
9. **Auto-submit on timeout:** When `timer_enforced = 1` and duration expires, the attempt must be auto-submitted with status = 'TIMEOUT'.
10. **Score floor:** Total score cannot go negative (negative marking floor = 0).
11. **show_result_immediately vs auto_publish_result:** `show_result_immediately` shows the student their own score as soon as they submit. `auto_publish_result` publishes scores for the whole class after `result_publish_date`.

---

## 9. WORKFLOW & STATE MACHINE DEFINITIONS

### Quiz Lifecycle
```
[Create Assessment Types] + [Create Difficulty Configs]  ← Master setup
     ↓
[Create Quiz] (DRAFT)
  ├── Manual: assign questions from QB search
  └── Auto: use difficulty builder → fetch matching questions → bulk-add
     ↓
[PUBLISH Quiz]
     ↓
[Create Allocation] (target + published_at + due_date + cut_off_date)
     ↓
[published_at reached] → Quiz visible to student
     ↓
[Student Attempts Quiz] (before cut_off_date, within max_attempts)
  ├── Timer counts down (if timer_enforced)
  ├── MCQ: auto-graded immediately
  ├── Descriptive: stored, teacher reviews
  └── TIMEOUT: auto-submit
     ↓
[show_result_immediately = 1] → Student sees score immediately after submit
[auto_publish_result = 1] → Scores published at result_publish_date
     ↓
[ARCHIVED]
```

### Difficulty Builder Workflow
```
[Teacher selects quiz in difficulty-builder tab]
     ↓
[Select difficulty_config + question filters (lesson, topic, type, complexity)]
     ↓
[fetchQuestions AJAX] → returns candidate questions from QB matching profile
     ↓
[Teacher reviews candidates]
     ↓
[addQuestions AJAX] → bulk-inserts into lms_quiz_questions with ordinal
```

### Attempt Status Transitions (SHARED with Quest)
```
NOT_STARTED → IN_PROGRESS → SUBMITTED
                           → TIMEOUT (timer expired, auto-submit)
                           → ABANDONED
SUBMITTED → REASSIGNED (allow re-attempt)
```

---

## 10. NON-FUNCTIONAL REQUIREMENTS

| # | Requirement | Target |
|---|---|---|
| NFR-QUZ-01 | Quiz attempt concurrency | 500+ students simultaneously per quiz |
| NFR-QUZ-02 | Auto-submit latency on timer expiry | < 5 seconds |
| NFR-QUZ-03 | Answer auto-save interval | Every 30 seconds |
| NFR-QUZ-04 | Difficulty builder fetch performance | < 1 second for 1000 QB questions |
| NFR-QUZ-05 | Gate authorization | Re-enable `tenant.quiz.viewAny` in index() |
| NFR-QUZ-06 | Route typo fix | Rename `lms-quize` → `lms-quiz` across tenant.php and all controllers |
| NFR-QUZ-07 | EnsureTenantHasModule middleware | Must be added to route group |
| NFR-QUZ-08 | Shared master integrity | DifficultyConfig and AssessmentType changes affect Quiz, Quest, and Exam simultaneously |

---

## 11. CROSS-MODULE DEPENDENCIES

| Module | Dependency Type | Detail |
|---|---|---|
| **QuestionBank** | CRITICAL | `qns_questions_bank` source for `lms_quiz_questions`. QuizQuestionController + difficulty builder search QB. |
| **LmsQuests** | SHARED MASTER CONSUMER | Quest model imports `AssessmentType` and `DifficultyDistributionConfig` from this module. |
| **LmsExam** | SHARED MASTER CONSUMER | ExamPaper model imports `DifficultyDistributionConfig` from this module. |
| **SchoolSetup** | FK DEPENDENCY | `sch_classes`, `sch_sections`, `sch_subjects` |
| **Syllabus** | FK DEPENDENCY | `slb_lessons`, `slb_topics`, `slb_question_types`, `slb_complexity_level`, `slb_bloom_taxonomy`, `slb_cognitive_skill` |
| **StudentProfile** | FK DEPENDENCY | `std_students` in attempt tracking |
| **Prime (Academic)** | FK DEPENDENCY | `glb_academic_sessions` |
| **qns_question_usage_type** | FK DEPENDENCY | Used by assessment_types and difficulty_configs as FK |

---

## 12. TEST CASE REFERENCE & COVERAGE

**Current test coverage: 0 tests**

### Proposed Test Plan

**Unit Tests:**
- `QuizCodeGeneratorTest` — format, uniqueness collision handling
- `DifficultyPercentageValidationTest` — sum of max_percentages = 100
- `OnlyUnusedQuestionsFilterTest` — verify QB filter excludes used questions
- `NegativeMarkingFloorTest` — score never goes below 0

**Feature Tests:**
- `QuizCreationTest` — happy path, missing academic hierarchy, duplicate code
- `DifficultyBuilderTest` — fetch questions matching profile, add questions
- `QuizQuestionBulkStoreTest` — add, ordinal update, marks override, duplicate prevention
- `QuizAllocationTest` — allocation types, allocation-level auto_publish_result override
- `QuizGateTest` — verify index() requires permission after fix
- `RouteTyopFixTest` — verify redirects work after lms-quize → lms-quiz rename
- `AssessmentTypeUsageFilterTest` — only QUIZ-type assessment types shown in quiz creation

---

## 13. GLOSSARY & TERMINOLOGY

| Term | Meaning |
|---|---|
| Quiz | A short topic-focused timed assessment for knowledge checks |
| Assessment Type | The pedagogical category of assessment (Practice, Challenge, Diagnostic, etc.) |
| Difficulty Config | A named profile defining percentages of Easy/Medium/Hard questions per type |
| Difficulty Builder | AJAX interface to auto-select questions matching a difficulty profile |
| Scope Topic | The primary topic covered by a quiz (can span sub-topics) |
| Allocation | Assignment of a published quiz to students with timing windows |
| Auto-Publish Result | Releases scores to students at a specified date (per allocation) |
| Cut-off Date | Hard deadline — no attempts started after this date |
| Only Unused Questions | Flag to select only questions not yet presented to the student |
| System Generated | Quiz was created automatically by an AI/algorithm rather than a teacher |

---

## 14. ADDITIONAL SUGGESTIONS

1. **Fix route typo immediately:** Change all occurrences of `lms-quize` and `quize` to `lms-quiz` and `quiz` in `tenant.php`, all controllers, and all redirect calls. This affects: LmsQuizController (9+ redirects), QuizQuestionController, QuizAllocationController route names.
2. **Re-enable `Gate::authorize('tenant.quiz.viewAny')`** in `LmsQuizController::index()`.
3. **Add `EnsureTenantHasModule` middleware** to the route group.
4. **Add `only_unused_questions` and `only_authorised_questions` to `Quiz::$fillable`** — these columns exist in DDL but are missing from the fillable array.
5. **Build student attempt pipeline** — this is the highest-priority remaining work.
6. **Implement auto-submit job** for timer expiry using Laravel Queue/Scheduler.
7. **Consider extracting shared masters to a `LmsMaster` module** — AssessmentType and DifficultyDistributionConfig being owned by LmsQuiz but imported by LmsQuests and LmsExam creates a unidirectional dependency that is architecturally fragile.
8. **Implement auto-generation service** — when `is_system_generated = 1`, build a `QuizGenerationService` that selects questions from QB using the difficulty config profile.
9. **Add a `/publish` route** similar to LmsQuests recommendation — instead of requiring the teacher to use the edit form to change status.

---

## 15. APPENDICES

### A. File Inventory
```
Modules/LmsQuiz/
├── app/Http/Controllers/
│   ├── LmsQuizController.php                    (tab hub + Quiz CRUD, Gate disabled, route typo)
│   ├── QuizQuestionController.php               (CRUD + 13 AJAX + difficulty-builder endpoints)
│   ├── QuizAllocationController.php             (CRUD)
│   ├── AssessmentTypeController.php             (CRUD — shared master)
│   └── DifficultyDistributionConfigController.php (CRUD — shared master + detail management)
├── app/Models/
│   ├── Quiz.php                                 (model for lms_quizzes)
│   ├── QuizQuestion.php                         (junction model)
│   ├── QuizAllocation.php
│   ├── AssessmentType.php                       (SHARED — imported by LmsQuests, LmsExam)
│   ├── DifficultyDistributionConfig.php         (SHARED — imported by LmsQuests, LmsExam)
│   └── DifficultyDistributionDetail.php         (child of DifficultyDistributionConfig)
├── app/Http/Requests/ [5 FormRequests]
├── app/Policies/ [AssessmentTypePolicy, DifficultyDistributionConfigPolicy, QuizAllocationPolicy, QuizPolicy, QuizQuestionPolicy]
├── resources/views/ [~26 blade files across 6 folders + difficulty_builder_tab]
└── routes/web.php (minimal — main routes in tenant.php lines 724-780)
```

### B. Route Group Location
All functional routes for LmsQuiz are defined in `/Users/bkwork/Herd/prime_ai/routes/tenant.php` lines 724–780 under the `lms-quize` prefix group (typo).

### C. Cross-Module Import Map
```
LmsQuiz owns:
  Modules\LmsQuiz\Models\AssessmentType
  Modules\LmsQuiz\Models\DifficultyDistributionConfig

Imported by:
  Modules\LmsQuests\Models\Quest          → AssessmentType, DifficultyDistributionConfig
  Modules\LmsQuests\Http\Controllers\LmsQuestController → AssessmentType, DifficultyDistributionConfig
  Modules\LmsExam\Models\ExamPaper        → DifficultyDistributionConfig
  Modules\LmsExam\Http\Controllers\ExamPaperController → DifficultyDistributionConfig
```

### D. Known Bugs Summary
| Bug | Location | Severity |
|---|---|---|
| Route prefix/names typo `lms-quize` → should be `lms-quiz` | tenant.php line 724, all LmsQuizController redirects | HIGH — URL breaks |
| `Gate::authorize` commented out in index() | LmsQuizController line 34 | HIGH SECURITY |
| `only_unused_questions` + `only_authorised_questions` missing from `$fillable` | Quiz model | MEDIUM — silently ignored on create/update |
| `EnsureTenantHasModule` middleware missing | Route group | MEDIUM |
| No student attempt controllers | Entire attempt pipeline | HIGH |
| No auto-generation service | is_system_generated = 1 does nothing | MEDIUM |
| 0 tests | All controllers | HIGH |
