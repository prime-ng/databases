# QUZ — LMS Quiz
## Module Requirement Document V2
**Version:** 2.0 | **Date:** 2026-03-26 | **Status:** Draft | **Mode:** FULL
**Module Code:** QUZ | **Scope:** Tenant | **Table Prefix:** `lms_quiz*` / `lms_assessment*` / `lms_difficulty*`
**Laravel Module Path:** `Modules/LmsQuiz/` | **Known Completion:** ~70%

---

## 1. Executive Summary

LmsQuiz is the primary short-form assessment module of Prime-AI. A "Quiz" is a lesson/topic-scoped timed assessment used for knowledge checks, practice, revision, and diagnostic purposes. The module also owns the shared master tables (`lms_assessment_types`, `lms_difficulty_distribution_configs`, `lms_difficulty_distribution_details`) consumed by both LmsQuests and LmsExam modules.

The teacher-facing workflow — quiz creation, difficulty configuration, assessment type management, question assignment via a rich difficulty-builder AJAX interface, and allocation — is approximately 90–95% complete. The student-facing attempt pipeline is entirely absent (0% implemented). Two critical defects exist:

1. **Security gap (PARTIALLY FIXED):** V1 gap analysis reported `Gate::authorize()` commented out in `LmsQuizController::index()` — current code inspection confirms Gate IS active on line 34. This may have been fixed between audits. Verify before release.
2. **Route prefix typo (CONFIRMED):** `tenant.php` line 688 uses prefix `lms-quize` and resource name `quize` — the extra 'e' is confirmed in code. All redirect calls in controllers propagate this typo. External references using the correct spelling `lms-quiz` will receive 404 errors.
3. **Missing middleware:** `EnsureTenantHasModule` is absent from the route group.

**Module stats (current):**
- Controllers: 5 | Models: 6 | Services: 0 | FormRequests: 5 | Tests: 0
- DDL tables owned: 6 quiz/master tables + 2 shared attempt tables (`lms_quiz_quest_attempts`, `lms_quiz_quest_attempt_answers`)
- Estimated remaining work: 5–7 developer days (P0+P1 fixes: 2–3 hrs; student attempt pipeline: 32–40 hrs; tests: 20–28 hrs)

---

## 2. Module Overview

### 2.1 Business Purpose

Enable teachers to create topic-focused quizzes that assess student understanding quickly. Quizzes can be manually constructed or auto-generated using difficulty distribution profiles (percentages of Easy/Medium/Hard questions). They are allocated to classes/sections/groups/individual students with configurable published/due/cut-off windows. The module also owns and maintains shared configuration masters used across all assessment modules.

### 2.2 Key Features

| # | Feature | Status |
|---|---|---|
| 1 | Assessment Type management (CRUD) — shared with LmsQuests and LmsExam | ✅ |
| 2 | Difficulty Distribution Config management (profiles for auto-question selection) | ✅ |
| 3 | Difficulty Distribution Detail lines (per-question-type percentage allocations) | ✅ |
| 4 | Quiz creation with full academic hierarchy alignment | ✅ |
| 5 | Difficulty-builder AJAX interface for automatic question selection by profile | ✅ |
| 6 | Manual question assignment with ordinal drag-and-drop and inline marks override | ✅ |
| 7 | Quiz allocation to CLASS/SECTION/GROUP/STUDENT with publish/due/cut-off dates | ✅ |
| 8 | Timer enforcement, randomisation, negative marking, multiple attempts config | 🟡 Config exists; enforcement backend absent |
| 9 | Result display options: immediate, teacher-manual, auto-publish | 🟡 Config exists; execution absent |
| 10 | Student attempt flow (start, answer, submit, auto-grade MCQ) | ❌ |
| 11 | Teacher manual grading for descriptive answers | ❌ |
| 12 | Attempt history and per-student analytics | ❌ |
| 13 | Class-wise performance reports | ❌ |
| 14 | Auto-submit job on timer expiry | ❌ |
| 15 | Automatic quiz generation from difficulty config profile | ❌ |

### 2.3 Menu Path
`LMS > Quiz`

### 2.4 Architecture
Tab-based single-page interface via `LmsQuizController::index()`. The module owns shared master tables. Route group prefix in `tenant.php` contains a confirmed typo: `lms-quize` instead of `lms-quiz`.

---

## 3. Stakeholders & Roles

| Actor | Role | Current Access |
|---|---|---|
| Admin | Creates assessment types, difficulty configs; system-wide settings | ✅ Implemented |
| Teacher | Creates quizzes, assigns questions, creates allocations, manually grades descriptive | ✅ CRUD done; grading absent |
| Student | Takes quiz, views result | ❌ Not implemented |
| Parent | Views child's quiz result | ❌ Not implemented |
| QuestionBank Module | Provides questions via `qns_questions_bank` | ✅ Integration done |
| LmsQuests Module | Consumes AssessmentType + DifficultyDistributionConfig from this module | ✅ Models imported |
| LmsExam Module | Consumes DifficultyDistributionConfig from this module | ✅ Model imported |

---

## 4. Functional Requirements

### FR-QUZ-001: Assessment Type Management
**RBS Reference:** S3 | **Priority:** High | **Status:** ✅ Implemented
**Tables:** `lms_assessment_types`

**Description:** CRUD management of assessment categories used across Quiz, Quest, and Exam. Each type has a code, name, description, and is linked to a usage type (QUIZ/QUEST/ONLINE_EXAM/OFFLINE_EXAM).

**Actors:** Admin
**Input:** code (UNIQUE, VARCHAR 20), name (VARCHAR 100), assessment_usage_type_id (FK to qns_question_usage_type), description (VARCHAR 255)
**Processing:** Soft delete lifecycle. Code uniqueness enforced at DB level (UNIQUE KEY `uq_quiz_type_code`).

**Standard values:** Challenge, Enrichment, Practice, Revision, Re-Test, Diagnostic, Remedial

**Acceptance Criteria:**
- Duplicate code rejected with validation error
- Toggle status works without hard delete
- Only types with matching usage type appear in quiz/quest/exam creation dropdowns
- Trashed records restorable by Admin

**Implementation:** `AssessmentTypeController` — full CRUD + trashed/restore/forceDelete/toggleStatus; policy: `AssessmentTypePolicy`; route: `lms-quize.assessment-type.*`

---

### FR-QUZ-002: Difficulty Distribution Config Management
**RBS Reference:** S3.1.2 | **Priority:** High | **Status:** ✅ Implemented
**Tables:** `lms_difficulty_distribution_configs`, `lms_difficulty_distribution_details`

**Description:** Manages profiles defining what percentage of questions must come from each Easy/Medium/Hard level per question type. A config (e.g., "Standard Quiz Balanced") has one or more detail rows specifying: question_type_id, complexity_level_id, Bloom taxonomy level, cognitive skill, min_percentage, max_percentage, marks_per_question.

**Actors:** Admin
**Input (Config):** code (UNIQUE), name, description, usage_type_id (FK qns_question_usage_type)
**Input (Detail rows):** difficulty_config_id, question_type_id, complexity_level_id, bloom_id, cognitive_skill_id, ques_type_specificity_id, min_percentage, max_percentage, marks_per_question

**Business Rules:**
- Sum of `max_percentage` across detail rows for a config must equal 100%
- Sum of `min_percentage` must not exceed 100%
- Config linked to a specific usage_type — only QUIZ configs shown in quiz creation

**Acceptance Criteria:**
- Detail rows managed inline (parent-child within same form)
- Profile is shared read-only with LmsQuests and LmsExam modules

**Implementation:** `DifficultyDistributionConfigController` — full CRUD for config + details; visual difficulty profile builder view at `quiz-question/difficulty_builder_tab.blade.php`

---

### FR-QUZ-003: Quiz Creation
**RBS Reference:** S3.1 | **Priority:** Critical | **Status:** ✅ Implemented (with known issues)
**Tables:** `lms_quizzes`

**Description:** Teacher creates a quiz with academic hierarchy, assessment type, scope topic, difficulty config, grading settings, timer, randomisation, attempt policy, and result display options.

**Actors:** Teacher, Admin

**Input Fields:**

| Field | Type | Notes |
|---|---|---|
| quiz_code | VARCHAR(50) | AUTO-GENERATED; UNIQUE |
| academic_session_id | FK | glb_academic_sessions |
| class_id | FK | sch_classes |
| subject_id | FK | sch_subjects |
| lesson_id | FK | sch_lessons |
| scope_topic_id | FK NULL | slb_topics (primary scope) |
| quiz_type_id | FK | lms_assessment_types |
| title | VARCHAR(100) | Required |
| description | VARCHAR(255) | Optional |
| instructions | TEXT | Supports HTML/Markdown/LaTeX |
| status | VARCHAR(20) | DRAFT / PUBLISHED / ARCHIVED |
| duration_minutes | TINYINT | NULL = Unlimited |
| total_marks | DECIMAL(8,2) | Auto-calculated from questions |
| total_questions | INT | Auto-calculated |
| passing_percentage | DECIMAL(5,2) | Default 33.00 |
| allow_multiple_attempts | BOOL | Default 0 |
| max_attempts | TINYINT | Default 1 |
| negative_marks | DECIMAL(4,2) | Deduction per wrong answer; 0 = no deduction |
| is_randomized | BOOL | Shuffle question order per attempt |
| question_marks_shown | BOOL | Show per-question marks during attempt |
| show_result_immediately | BOOL | Student sees score immediately on submit |
| auto_publish_result | BOOL | Class-wide results auto-released at result_publish_date |
| timer_enforced | BOOL | Default 1 — countdown visible and enforced |
| show_correct_answer | BOOL | Show correct answer after attempt |
| show_explanation | BOOL | Show explanation after attempt |
| difficulty_config_id | FK NULL | lms_difficulty_distribution_configs |
| ignore_difficulty_config | BOOL | Override difficulty filtering |
| is_system_generated | BOOL | Quiz created by algorithm |
| only_unused_questions | BOOL | Exclude already-used questions from pool |
| only_authorised_questions | BOOL | Restrict to questions where for_quiz=1 |

**Processing:**
- UUID assigned via model `boot()` creating event using `Str::uuid()` — **BUG:** stored as 36-char string (`(string) Str::uuid()`) but DDL column is `BINARY(16)`; should use `Str::uuid()->getBytes()`
- Quiz code auto-generated in model `boot()` AND duplicated in controller `store()`/`update()` — eliminate controller copy; retain model boot() logic only
- `only_unused_questions` and `only_authorised_questions` exist in DDL but are **missing from `$fillable`** in Quiz model

**Known Issues:**
- `SEC-03`: UUID type mismatch — BINARY(16) vs 36-char string
- `SEC-04`: No DB transaction wrapping `store()`, `update()`, `destroy()`
- `PERF-01/02`: `Topic::where('is_active','1')->get()` and `Quiz::where('is_active','1')->get()` load all records without pagination in `index()`
- `PERF-05`: Quiz listing query lacks eager loading for class/subject/lesson

**Acceptance Criteria:**
- Quiz code must be globally unique (DB UNIQUE KEY enforced)
- Gate authorization active on `index()` — verify `Gate::authorize('tenant.quiz.viewAny')` is uncommented
- Route prefix corrected from `quize` to `quiz`
- `only_unused_questions` and `only_authorised_questions` added to `$fillable`
- DB transactions added to store/update/destroy

**Implementation:** `LmsQuizController` — index (Gate currently active line 34), create, store, show, edit, update, destroy, trashed, restore, forceDelete, toggleStatus, getLessons; AJAX: `POST /get-lessons`

---

### FR-QUZ-004: Quiz Question Assignment
**RBS Reference:** S3.1 / S4 | **Priority:** Critical | **Status:** ✅ Implemented (rich AJAX difficulty-builder)
**Tables:** `lms_quiz_questions`

**Description:** Links questions from the Question Bank to a quiz. Two workflows:
- (a) Manual: search QB by class/subject/lesson/topic/type/complexity, select questions
- (b) Automatic: use difficulty builder — select difficulty profile, fetch questions matching profile percentages, bulk-add

**Actors:** Teacher

**Input:** quiz_id, question_id, ordinal, marks_override (optional)

**AJAX Endpoints (all under `lms-quize` prefix):**

| Endpoint | Method | Purpose |
|---|---|---|
| `difficulty-builder/questions` | POST | Fetch questions matching difficulty profile |
| `difficulty-builder/add` | POST | Bulk-add fetched questions |
| `difficulty-builder/quiz-meta` | POST | Quiz metadata for builder UI |
| `get-sections` | GET | Sections for a class |
| `get-subject-groups` | GET | Subject groups |
| `get-subjects` | GET | Subjects |
| `get-topics` | GET | Topics for a lesson |
| `search` | GET | Manual QB search |
| `existing` | GET | Current questions already in quiz |
| `bulk-store` | POST | Add multiple questions |
| `bulk-destroy` | POST | Remove multiple questions |
| `update-ordinal` | POST | Drag-and-drop reorder |
| `update-marks` | POST | Inline marks override |

**Business Rules:**
- UNIQUE (quiz_id, question_id) prevents duplicate questions in same quiz
- Difficulty builder respects `min_percentage`/`max_percentage` from selected config
- `only_unused_questions = 1` filters out questions already in `qns_question_usage_log`
- `only_authorised_questions = 1` filters to `qns_questions_bank.for_quiz = 1`
- `ordinal` determines display order; drag-and-drop updates via `update-ordinal`
- `marks_override` supersedes question's default marks if set

**Acceptance Criteria:**
- Duplicate question prevented with clear user message
- Difficulty builder counts respect configured percentages
- Reorder persists correctly after page reload

**Implementation:** `QuizQuestionController` — full CRUD + 13 AJAX endpoints; special view: `quiz-question/difficulty_builder_tab.blade.php`

---

### FR-QUZ-005: Quiz Allocation
**RBS Reference:** S3.1.2 | **Priority:** Critical | **Status:** ✅ Implemented
**Tables:** `lms_quiz_allocations`

**Description:** Assigns a published quiz to a target audience (CLASS/SECTION/GROUP/STUDENT) with configurable timing windows. Allocation-level result publish settings override quiz-level settings.

**Actors:** Teacher, Admin

**Input:**

| Field | Type | Notes |
|---|---|---|
| quiz_id | FK | lms_quizzes |
| allocation_type | ENUM | CLASS / SECTION / GROUP / STUDENT |
| target_table_name | VARCHAR(60) | App-level FK (sch_classes, sch_sections, sch_entity_groups, std_students) |
| target_id | INT | Polymorphic ID matching target_table_name |
| assigned_by | FK NULL | sys_users |
| published_at | DATETIME | Visible from this time |
| due_date | DATETIME | Should be completed by |
| cut_off_date | DATETIME | Hard stop — no attempts after this |
| is_auto_publish_result | BOOL | OVERRIDES quiz-level `auto_publish_result` |
| result_publish_date | DATETIME | When results become visible |

**Business Rules:**
- `is_auto_publish_result` at allocation level OVERRIDES quiz-level setting — allows different result publish timing per target group
- `cut_off_date` enforced hard — no attempt start permitted after this datetime even if max_attempts not reached
- A quiz must be in PUBLISHED status to be allocatable

**Acceptance Criteria:**
- Allocation-level result override clearly indicated in UI
- System prevents allocation of DRAFT/ARCHIVED quiz
- Multiple allocations for same quiz to different targets are permitted

**Implementation:** `QuizAllocationController` — full CRUD + trashed/restore/forceDelete/toggleStatus

---

### FR-QUZ-006: Student Quiz Attempt Pipeline
**RBS Reference:** S3.1 / S5 | **Priority:** Critical | **Status:** ❌ Not Implemented
**Tables:** `lms_quiz_quest_attempts`, `lms_quiz_quest_attempt_answers`

**Description:** Complete student-facing quiz flow: see allocated quizzes, start timed attempt, answer questions, auto-submit on timer expiry, receive grade.

**Actors:** Student

**Sub-requirements:**

#### FR-QUZ-006a: My Quizzes Dashboard (Student)
Student sees list of quizzes allocated to them (via CLASS/SECTION/GROUP/STUDENT target) where `published_at <= now <= cut_off_date`. Shows: title, subject, due date, attempt status, remaining attempts.

#### FR-QUZ-006b: Start Attempt
Student initiates attempt for a quiz. System validates:
- Quiz is PUBLISHED and `is_active = 1`
- Current time is within `published_at` and `cut_off_date`
- `attempt_number` < `max_attempts` (or `allow_multiple_attempts = 0` and no prior attempt)
Creates `lms_quiz_quest_attempts` record with `status = IN_PROGRESS`, `started_at = now()`.
If `is_randomized = 1`, question order is shuffled per-attempt.

#### FR-QUZ-006c: Answer Recording (Auto-Save)
For each question answered:
- MCQ single/multi: `selected_option_id` stored in `lms_quiz_quest_attempt_answers`
- Descriptive/Fill-in: `answer_text` stored
- `time_taken_seconds` tracked per question (telemetry)
- Auto-save every 30 seconds (debounce) — prevents data loss on connectivity drop
- If attempt is `IN_PROGRESS` and student navigates back, resume from last saved state

#### FR-QUZ-006d: Timer Management
- If `timer_enforced = 1` and `duration_minutes` is set: countdown timer shown in UI
- Timer starts at `started_at`; expiry = `started_at + duration_minutes * 60`
- On expiry: auto-submit triggered (background job or frontend beacon)
- Attempt status set to `TIMEOUT`
- If `duration_minutes = NULL`: no timer shown (unlimited)

#### FR-QUZ-006e: Submit Attempt
Student explicitly submits or system auto-submits (timer/cut-off).
- `completed_at` set to now()
- Status: `SUBMITTED` (manual) or `TIMEOUT` (timer) or `ABANDONED` (detected)
- Auto-grading triggered for objective questions (MCQ single/multi, true/false, fill-in)
- Descriptive questions flagged for teacher manual review (`is_correct = NULL`)
- `total_score` and `percentage` calculated and stored
- `is_passed` set based on `passing_percentage`
- Negative marking applied: deduct `negative_marks` per wrong MCQ answer; floor at 0

#### FR-QUZ-006f: Result Display
- If `show_result_immediately = 1`: student sees their score, pass/fail immediately after submit
- If `show_correct_answer = 1`: correct answers shown post-submit
- If `show_explanation = 1`: question explanations shown post-submit
- If `auto_publish_result = 1` (or allocation-level override): class results visible at `result_publish_date`

**Required New Controllers:**
- `StudentQuizAttemptController` — myQuizzes, startAttempt, saveAnswer, submitAttempt, viewResult, attemptHistory
- `TeacherQuizGradingController` — pendingGrading, gradeAnswer, publishResult

**Required New Models:**
- `QuizQuestAttempt` — maps `lms_quiz_quest_attempts`
- `QuizQuestAttemptAnswer` — maps `lms_quiz_quest_attempt_answers`

**Required New Job:**
- `AutoSubmitExpiredAttemptJob` — scheduled or queued; checks `IN_PROGRESS` attempts where `started_at + duration_minutes < now()` and submits

**Required New Views:**
- `student/my-quizzes.blade.php` — quiz list with status badges
- `student/attempt.blade.php` — quiz player (question navigation, timer, answer inputs)
- `student/result.blade.php` — result card with score, pass/fail, answers (conditional)
- `teacher/grading/index.blade.php` — list of attempts pending manual grading
- `teacher/grading/grade.blade.php` — per-attempt answer review and marks entry

---

### FR-QUZ-007: Teacher Manual Grading
**RBS Reference:** S5.2 | **Priority:** High | **Status:** ❌ Not Implemented
**Tables:** `lms_quiz_quest_attempt_answers`

**Description:** For descriptive/short-answer questions, teacher reviews student response and awards marks.

**Actors:** Teacher

**Processing:**
- Teacher sees list of attempts containing at least one unevaluated descriptive answer (`is_correct = NULL`)
- Per question: teacher views student's `answer_text`, enters `marks_obtained` (0 to question's max marks), sets `is_correct = 1/0`
- On all descriptive answers graded: attempt `total_score` recalculated; `percentage` and `is_passed` updated
- Teacher may add `teacher_feedback` on the attempt record

**Acceptance Criteria:**
- Teacher cannot award marks exceeding question's max marks
- System triggers result visibility update once all pending answers are graded

---

### FR-QUZ-008: Quiz Results Publishing
**RBS Reference:** S5.3 | **Priority:** High | **Status:** ❌ Not Implemented
**Tables:** `lms_quiz_quest_attempts`, `lms_quiz_allocations`

**Description:** Controls when quiz results become visible to students beyond individual immediate view.

**Processing:**
- If `is_auto_publish_result = 1` (allocation level): results auto-publish at `result_publish_date` via scheduler
- Manual publish: teacher action to release results for an allocation
- Class-wise leaderboard / summary table available to teacher post-publish
- Published results visible to student on their My Quizzes / result page

---

### FR-QUZ-009: Quiz Performance Analytics
**RBS Reference:** S6 | **Priority:** Medium | **Status:** ❌ Not Implemented (config exists)

**Description:** Aggregated analytics for teacher and admin.

**Proposed features:**
- Per-quiz: attempt count, average score, pass rate, question-wise difficulty analysis
- Per-student: attempt history, score trend across multiple attempts
- Per-class: score distribution (histogram), top/bottom performers
- Per-question: correct answer rate (item analysis) — identifies poorly understood topics

**Proposed controllers/views:**
- `QuizAnalyticsController` — quizSummary, studentReport, classReport, questionAnalysis

---

### FR-QUZ-010: Automatic Quiz Generation
**RBS Reference:** S3.1.2 | **Priority:** Medium | **Status:** ❌ Not Implemented (infrastructure ready)

**Description:** When `is_system_generated = 1`, the system automatically selects questions from QB based on `difficulty_config_id` distribution, scope (lesson/topic), and `only_unused_questions`/`only_authorised_questions` flags. Creates quiz questions without teacher manual selection.

**Processing (proposed):**
- `QuizGenerationService::generate(Quiz $quiz)` — reads difficulty config details, computes required count per type/complexity, queries QB, inserts into `lms_quiz_questions`
- Called from `store()` after quiz creation when `is_system_generated = 1`

---

## 5. Data Model

### 5.1 lms_difficulty_distribution_configs (SHARED MASTER — owned by LmsQuiz)

| Column | Type | Constraints | Notes |
|---|---|---|---|
| id | INT UNSIGNED | PK AUTO_INCREMENT | |
| code | VARCHAR(50) | UNIQUE NOT NULL | e.g. 'STD_QUIZ_BALANCED' |
| name | VARCHAR(100) | NOT NULL | Display name |
| description | VARCHAR(255) | NULL | |
| usage_type_id | INT UNSIGNED | FK qns_question_usage_type NOT NULL | QUIZ / QUEST / ONLINE_EXAM / OFFLINE_EXAM |
| is_active | TINYINT(1) | DEFAULT 1 | |
| created_at, updated_at | TIMESTAMP | | |
| deleted_at | TIMESTAMP | NULL | Soft delete |

**Consumed by:** `Modules\LmsQuests\Models\Quest`, `Modules\LmsExam\Models\ExamPaper`

### 5.2 lms_difficulty_distribution_details (child of lms_difficulty_distribution_configs)

| Column | Type | Constraints | Notes |
|---|---|---|---|
| id | INT UNSIGNED | PK | |
| difficulty_config_id | INT UNSIGNED | FK → lms_difficulty_distribution_configs CASCADE | |
| question_type_id | INT UNSIGNED | FK → slb_question_types NOT NULL | MCQ_SINGLE, MCQ_MULTI, SHORT_ANSWER, etc. |
| complexity_level_id | INT UNSIGNED | FK → slb_complexity_level NOT NULL | EASY, MEDIUM, DIFFICULT |
| bloom_id | INT UNSIGNED | FK → slb_bloom_taxonomy NULL | |
| cognitive_skill_id | INT UNSIGNED | FK → slb_cognitive_skill NULL | |
| ques_type_specificity_id | INT UNSIGNED | FK → slb_ques_type_specificity NULL | |
| min_percentage | DECIMAL(5,2) | DEFAULT 0.00 NOT NULL | Minimum % of total questions |
| max_percentage | DECIMAL(5,2) | DEFAULT 0.00 NOT NULL | Maximum % of total questions |
| marks_per_question | DECIMAL(5,2) | NULL | Optional override |
| is_active | TINYINT(1) | DEFAULT 1 | |
| created_at, updated_at, deleted_at | TIMESTAMP | | |

### 5.3 lms_assessment_types (SHARED MASTER — owned by LmsQuiz)

| Column | Type | Constraints | Notes |
|---|---|---|---|
| id | INT UNSIGNED | PK | |
| code | VARCHAR(20) | UNIQUE NOT NULL | Challenge, Practice, Diagnostic, etc. |
| name | VARCHAR(100) | NOT NULL | |
| assessment_usage_type_id | INT UNSIGNED | FK qns_question_usage_type NOT NULL | |
| description | VARCHAR(255) | NULL | |
| is_active | TINYINT(1) | DEFAULT 1 | |
| created_at, updated_at, deleted_at | TIMESTAMP | | |

**Consumed by:** `Modules\LmsQuests\Models\Quest`, `Modules\LmsExam\Models\ExamPaper`

### 5.4 lms_quizzes (PRIMARY TABLE)

| Column | Type | Constraints | Notes |
|---|---|---|---|
| id | INT UNSIGNED | PK | |
| uuid | BINARY(16) | UNIQUE NOT NULL | BUG: model stores 36-char string — fix to getBytes() |
| academic_session_id | INT UNSIGNED | FK glb_academic_sessions CASCADE | |
| class_id | INT UNSIGNED | FK sch_classes CASCADE | |
| subject_id | INT UNSIGNED | FK sch_subjects CASCADE | |
| lesson_id | INT UNSIGNED | FK sch_lessons NOT NULL | |
| scope_topic_id | INT UNSIGNED | FK slb_topics NULL | Primary scope topic |
| quiz_type_id | INT UNSIGNED | FK lms_assessment_types | |
| quiz_code | VARCHAR(50) | UNIQUE NOT NULL | Auto-generated |
| title | VARCHAR(100) | NOT NULL | |
| description | VARCHAR(255) | NULL | |
| instructions | TEXT | NULL | Supports HTML/Markdown/LaTeX |
| status | VARCHAR(20) | DEFAULT 'DRAFT' | DRAFT / PUBLISHED / ARCHIVED |
| duration_minutes | TINYINT UNSIGNED | NULL = unlimited | |
| total_marks | DECIMAL(8,2) | DEFAULT 0.00 | |
| total_questions | INT UNSIGNED | DEFAULT 0 | |
| passing_percentage | DECIMAL(5,2) | DEFAULT 33.00 | |
| allow_multiple_attempts | TINYINT(1) | DEFAULT 0 | |
| max_attempts | TINYINT UNSIGNED | DEFAULT 1 | |
| negative_marks | DECIMAL(4,2) | DEFAULT 0.00 | Per wrong answer deduction |
| is_randomized | TINYINT(1) | DEFAULT 0 | Shuffle question order |
| question_marks_shown | TINYINT(1) | DEFAULT 0 | Show per-question marks during attempt |
| show_result_immediately | TINYINT(1) | DEFAULT 0 | |
| auto_publish_result | TINYINT(1) | DEFAULT 0 | |
| timer_enforced | TINYINT(1) | DEFAULT 1 | |
| show_correct_answer | TINYINT(1) | DEFAULT 0 | |
| show_explanation | TINYINT(1) | DEFAULT 0 | |
| difficulty_config_id | INT UNSIGNED | FK lms_difficulty_distribution_configs NULL | |
| ignore_difficulty_config | TINYINT(1) | DEFAULT 0 | |
| is_system_generated | TINYINT(1) | DEFAULT 0 | |
| only_unused_questions | TINYINT(1) | DEFAULT 0 | BUG: missing from $fillable |
| only_authorised_questions | TINYINT(1) | DEFAULT 0 | BUG: missing from $fillable |
| created_by | INT UNSIGNED | FK sys_users NULL | NULL if system-generated |
| is_active | TINYINT(1) | DEFAULT 1 | |
| created_at, updated_at, deleted_at | TIMESTAMP | | |

**Indexes:** `idx_quiz_topic` (scope_topic_id), `idx_quiz_status` (status)

**Model:** `Modules\LmsQuiz\Models\Quiz`
Relationships: academicSession, class, subject, lesson, assessmentType (quiz_type_id → FK), topic (scope_topic_id), difficultyConfig, creator, quizQuestions (HasMany), questions (BelongsToMany via lms_quiz_questions), allocations (HasMany)
Scopes: active, published, draft
Computed attribute: academic_hierarchy (array)
Method: isAvailable() — returns true if PUBLISHED and is_active

### 5.5 lms_quiz_questions (Junction)

| Column | Type | Constraints | Notes |
|---|---|---|---|
| id | INT UNSIGNED | PK | |
| quiz_id | INT UNSIGNED | FK lms_quizzes CASCADE | |
| question_id | INT UNSIGNED | FK qns_questions_bank CASCADE | |
| ordinal | INT UNSIGNED | DEFAULT 0 | Display order |
| marks_override | DECIMAL(5,2) | NULL | Overrides question default marks |
| is_active | TINYINT(1) | DEFAULT 1 | |
| created_at, updated_at, deleted_at | TIMESTAMP | | |

**Unique constraint:** UNIQUE KEY `uq_quiz_ques` (quiz_id, question_id)

### 5.6 lms_quiz_allocations

| Column | Type | Constraints | Notes |
|---|---|---|---|
| id | INT UNSIGNED | PK | |
| quiz_id | INT UNSIGNED | FK lms_quizzes CASCADE | |
| allocation_type | ENUM | CLASS / SECTION / GROUP / STUDENT | |
| target_table_name | VARCHAR(60) | NOT NULL | App-level FK — dynamic |
| target_id | INT UNSIGNED | NOT NULL | Polymorphic ID |
| assigned_by | INT UNSIGNED | FK sys_users NULL | |
| published_at | DATETIME | NULL | Visible from |
| due_date | DATETIME | NULL | Should complete by |
| cut_off_date | DATETIME | NULL | Hard cutoff |
| is_auto_publish_result | TINYINT(1) | DEFAULT 0 | OVERRIDES quiz-level setting |
| result_publish_date | DATETIME | NULL | Results visible from |
| is_active | TINYINT(1) | DEFAULT 1 | |
| created_at, updated_at, deleted_at | TIMESTAMP | | |

**Index:** KEY `idx_quiz_alloc_target` (allocation_type, target_id)

### 5.7 lms_quiz_quest_attempts (SHARED — owned by LmsStudentAttempts / LmsQuiz)

| Column | Type | Constraints | Notes |
|---|---|---|---|
| id | INT UNSIGNED | PK | |
| student_id | INT UNSIGNED | FK sch_students | |
| assessment_type | ENUM | QUIZ / QUEST | Discriminator |
| assessment_id | INT UNSIGNED | App-level FK | lms_quizzes.id or lms_quests.id |
| allocation_id | INT UNSIGNED | App-level FK NULL | lms_quiz_allocations.id or lms_quest_allocations.id |
| attempt_number | TINYINT UNSIGNED | DEFAULT 1 | Increments per re-attempt |
| started_at | DATETIME | NOT NULL | |
| completed_at | DATETIME | NULL | |
| status | ENUM | NOT_STARTED / IN_PROGRESS / SUBMITTED / TIMEOUT / ABANDONED / CANCELLED / REASSIGNED | |
| total_score | DECIMAL(8,2) | NULL | Computed post-submit |
| percentage | DECIMAL(5,2) | NULL | Computed post-submit |
| is_passed | TINYINT(1) | DEFAULT 0 | |
| teacher_feedback | TEXT | NULL | |
| is_active | TINYINT(1) | DEFAULT 1 | |
| created_at, updated_at, deleted_at | TIMESTAMP | | |

**Indexes:** `idx_att_student` (student_id), `idx_att_assessment` (assessment_type, assessment_id)

### 5.8 lms_quiz_quest_attempt_answers (SHARED)

| Column | Type | Constraints | Notes |
|---|---|---|---|
| id | INT UNSIGNED | PK | |
| attempt_id | INT UNSIGNED | FK lms_quiz_quest_attempts CASCADE | |
| question_id | INT UNSIGNED | FK qns_questions_bank RESTRICT | |
| selected_option_id | INT UNSIGNED | FK qns_question_options NULL | For MCQ |
| answer_text | TEXT | NULL | For descriptive/fill-in |
| marks_obtained | DECIMAL(5,2) | DEFAULT 0.00 | |
| is_correct | TINYINT(1) | NULL | NULL=ungraded, 0=incorrect, 1=correct |
| time_taken_seconds | INT UNSIGNED | DEFAULT 0 | Telemetry |
| is_active | TINYINT(1) | DEFAULT 1 | |
| created_at, updated_at, deleted_at | TIMESTAMP | | |

---

## 6. API Endpoints & Routes

**Current Route Group (CONFIRMED TYPO IN CODE):**
- File: `routes/tenant.php` line 688
- Prefix: `lms-quize` (typo — should be `lms-quiz`)
- Name prefix: `lms-quize.` (typo)
- Middleware: `['auth', 'verified']`
- Missing: `EnsureTenantHasModule`

**Corrected prefix (target state):** `lms-quiz` / name prefix `lms-quiz.`

### 6.1 Existing Routes (as-built, with typo preserved for reference)

| Method | URI | Named Route | Controller | Status |
|---|---|---|---|---|
| GET | /lms-quize/quize | lms-quize.quize.index | LmsQuizController@index | ✅ Gate active |
| GET | /lms-quize/quize/create | lms-quize.quize.create | LmsQuizController@create | ✅ |
| POST | /lms-quize/quize | lms-quize.quize.store | LmsQuizController@store | ✅ |
| GET | /lms-quize/quize/{id} | lms-quize.quize.show | LmsQuizController@show | ✅ |
| GET | /lms-quize/quize/{id}/edit | lms-quize.quize.edit | LmsQuizController@edit | ✅ |
| PUT | /lms-quize/quize/{id} | lms-quize.quize.update | LmsQuizController@update | ✅ |
| DELETE | /lms-quize/quize/{id} | lms-quize.quize.destroy | LmsQuizController@destroy | ✅ |
| GET | /lms-quize/quize/trash/view | lms-quize.quize.trashed | LmsQuizController@trashed | ✅ |
| GET | /lms-quize/quize/{id}/restore | lms-quize.quize.restore | LmsQuizController@restore | ✅ |
| DELETE | /lms-quize/quize/{id}/force-delete | lms-quize.quize.forceDelete | LmsQuizController@forceDelete | ✅ |
| POST | /lms-quize/quize/{id}/toggle-status | lms-quize.quize.toggleStatus | LmsQuizController@toggleStatus | ✅ |
| POST | /lms-quize/get-lessons | lms-quize.get-lessons | LmsQuizController@getLessons | 🟡 No input validation |
| GET/POST | /lms-quize/assessment-type/* | lms-quize.assessment-type.* | AssessmentTypeController | ✅ |
| GET/POST | /lms-quize/difficulty-distribution-config/* | lms-quize.difficulty-distribution-config.* | DifficultyDistributionConfigController | ✅ |
| GET/POST | /lms-quize/quiz-allocation/* | lms-quize.quiz-allocation.* | QuizAllocationController | ✅ |
| GET/POST | /lms-quize/quiz-question/* | lms-quize.quiz-question.* | QuizQuestionController | ✅ |
| POST | /lms-quize/difficulty-builder/questions | lms-quize.difficulty.builder.fetch | QuizQuestionController@fetchQuestions | ✅ |
| POST | /lms-quize/difficulty-builder/add | lms-quize.difficulty.builder.add | QuizQuestionController@addQuestions | ✅ |
| POST | /lms-quize/difficulty-builder/quiz-meta | lms-quize.difficulty.builder.quiz-meta | QuizQuestionController@quizMeta | ✅ |
| GET | /lms-quize/get-sections | lms-quize.get-sections | QuizQuestionController@getSections | ✅ |
| GET | /lms-quize/get-subject-groups | lms-quize.get-subject-groups | QuizQuestionController@getSubjectGroups | ✅ |
| GET | /lms-quize/get-subjects | lms-quize.get-subjects | QuizQuestionController@getSubjects | ✅ |
| GET | /lms-quize/get-topics | lms-quize.get-topics | QuizQuestionController@getTopics | ✅ |
| GET | /lms-quize/search | lms-quize.search | QuizQuestionController@search | ✅ |
| GET | /lms-quize/existing | lms-quize.existing | QuizQuestionController@existing | ✅ |
| POST | /lms-quize/bulk-store | lms-quize.bulk-store | QuizQuestionController@bulkStore | ✅ |
| POST | /lms-quize/bulk-destroy | lms-quize.bulk-destroy | QuizQuestionController@bulkDestroy | ✅ |
| POST | /lms-quize/update-ordinal | lms-quize.update-ordinal | QuizQuestionController@updateOrdinal | ✅ |
| POST | /lms-quize/update-marks | lms-quize.update-marks | QuizQuestionController@updateMarks | ✅ |

### 6.2 Proposed New Routes (Student Attempt Pipeline)

| Method | URI | Named Route | Controller | Status |
|---|---|---|---|---|
| GET | /lms-quiz/my-quizzes | lms-quiz.student.my-quizzes | StudentQuizAttemptController@myQuizzes | 📐 |
| POST | /lms-quiz/attempt/start | lms-quiz.attempt.start | StudentQuizAttemptController@startAttempt | 📐 |
| POST | /lms-quiz/attempt/{attempt}/save-answer | lms-quiz.attempt.save-answer | StudentQuizAttemptController@saveAnswer | 📐 |
| POST | /lms-quiz/attempt/{attempt}/submit | lms-quiz.attempt.submit | StudentQuizAttemptController@submitAttempt | 📐 |
| GET | /lms-quiz/attempt/{attempt}/result | lms-quiz.attempt.result | StudentQuizAttemptController@viewResult | 📐 |
| GET | /lms-quiz/attempt/history | lms-quiz.attempt.history | StudentQuizAttemptController@attemptHistory | 📐 |
| GET | /lms-quiz/grading | lms-quiz.grading.index | TeacherQuizGradingController@index | 📐 |
| GET | /lms-quiz/grading/{attempt} | lms-quiz.grading.show | TeacherQuizGradingController@show | 📐 |
| POST | /lms-quiz/grading/{attempt}/grade | lms-quiz.grading.grade | TeacherQuizGradingController@grade | 📐 |
| POST | /lms-quiz/allocation/{allocation}/publish-results | lms-quiz.results.publish | QuizAllocationController@publishResults | 📐 |
| POST | /lms-quiz/quize/{quiz}/publish | lms-quiz.quiz.publish | LmsQuizController@publish | 📐 |

---

## 7. UI Screens

### 7.1 Existing Screens

| Screen | View Path | Purpose | Status |
|---|---|---|---|
| Quiz Hub (tab container) | `tab_module/tab.blade.php` | Main container: quizzes, configs, types, questions, allocations | ✅ |
| Quiz List | `quiz/index.blade.php` | Filter by status, type, topic, date range | ✅ |
| Quiz Create | `quiz/create.blade.php` | All quiz fields including difficulty config, timer, attempts | ✅ |
| Quiz Edit | `quiz/edit.blade.php` | Same fields as create | ✅ |
| Quiz Show | `quiz/show.blade.php` | Detail + questions list | ✅ |
| Quiz Trash | `quiz/trash.blade.php` | Soft-deleted quiz list | ✅ |
| Assessment Type CRUD | `assessment-type/{create,edit,index,show,trash}.blade.php` | Master data management | ✅ |
| Difficulty Config CRUD | `difficulty-config/{create,edit,index,show,trash}.blade.php` | Difficulty profile management | ✅ |
| Quiz Questions CRUD | `quiz-question/{create,edit,index,show,trash}.blade.php` | Question assignment to quiz | ✅ |
| Difficulty Builder | `quiz-question/difficulty_builder_tab.blade.php` | AJAX-driven auto-selection by difficulty profile | ✅ |
| Quiz Allocations CRUD | `quiz-allocation/{create,edit,index,show,trash}.blade.php` | Allocation management | ✅ |

### 7.2 Proposed New Screens

| Screen | View Path | Purpose | Status |
|---|---|---|---|
| Student: My Quizzes | `student/my-quizzes.blade.php` | Quiz list with status badges and attempt counts | 📐 |
| Student: Attempt Player | `student/attempt.blade.php` | Quiz player — question navigation, timer, answer inputs | 📐 |
| Student: Result Card | `student/result.blade.php` | Score, pass/fail, question-wise review (conditional) | 📐 |
| Student: Attempt History | `student/history.blade.php` | All past attempts across quizzes | 📐 |
| Teacher: Grading List | `teacher/grading/index.blade.php` | Attempts pending manual review | 📐 |
| Teacher: Grade Attempt | `teacher/grading/grade.blade.php` | Per-question mark entry for descriptive answers | 📐 |
| Teacher: Quiz Analytics | `teacher/analytics/index.blade.php` | Quiz-wise attempt summary, score distribution | 📐 |
| Teacher: Class Report | `teacher/analytics/class-report.blade.php` | Per-class performance table | 📐 |

### 7.3 UI Field Mapping: Quiz Create/Edit Key Fields

| Section | Fields | Notes |
|---|---|---|
| Academic Hierarchy | academic_session_id, class_id, subject_id, lesson_id | Cascading dropdowns |
| Scope | scope_topic_id, quiz_type_id | Topic from slb_topics; type from lms_assessment_types |
| Identity | title, description, instructions | Instructions: rich text |
| Settings | duration_minutes, total_marks, total_questions, passing_percentage | Auto-calc fields |
| Attempt Policy | allow_multiple_attempts, max_attempts, negative_marks | Show max_attempts only if allow_multiple |
| Behaviour | is_randomized, question_marks_shown, timer_enforced | Toggle switches |
| Result Display | show_result_immediately, auto_publish_result, show_correct_answer, show_explanation | Grouped toggles |
| Question Selection | difficulty_config_id, ignore_difficulty_config, is_system_generated, only_unused_questions, only_authorised_questions | Advanced section |

---

## 8. Business Rules

| ID | Rule | Enforcement |
|---|---|---|
| BR-QUZ-01 | Quiz code is globally unique | DB UNIQUE KEY `uq_quiz_code` |
| BR-QUZ-02 | UNIQUE (quiz_id, question_id) — same question cannot appear twice | DB UNIQUE KEY `uq_quiz_ques` |
| BR-QUZ-03 | `is_auto_publish_result` at allocation level OVERRIDES quiz-level `auto_publish_result` | Application logic |
| BR-QUZ-04 | No attempt starts after `cut_off_date` even if `max_attempts` not reached | Application validation in startAttempt |
| BR-QUZ-05 | `only_unused_questions = 1` → exclude questions in `qns_question_usage_log` for this student | Application filter in QB query |
| BR-QUZ-06 | `only_authorised_questions = 1` → restrict to `qns_questions_bank.for_quiz = 1` | Application filter |
| BR-QUZ-07 | Sum of `max_percentage` across detail rows for a difficulty config must equal 100% | Application validation |
| BR-QUZ-08 | Assessment types filter by usage_type — only QUIZ-type shown in quiz creation dropdown | Application filter |
| BR-QUZ-09 | Auto-submit when `timer_enforced = 1` and `duration_minutes` elapses | Background job / frontend beacon |
| BR-QUZ-10 | Total score floor at 0 — negative marking cannot produce a negative final score | Scoring computation |
| BR-QUZ-11 | `show_result_immediately` — student sees own score; `auto_publish_result` — class results visible at date | Separate display gates |
| BR-QUZ-12 | A quiz must be PUBLISHED before it can be allocated | Validation in QuizAllocationController |
| BR-QUZ-13 | Attempt count increments by 1 on each new attempt; cannot exceed `max_attempts` | Application validation |
| BR-QUZ-14 | Descriptive answers require teacher manual grading; MCQ/true-false/fill-in are auto-graded | Scoring service |
| BR-QUZ-15 | `attempt_number` on `lms_quiz_quest_attempts` must be `> 0` and `<= max_attempts` | Application validation |

---

## 9. Workflows

### 9.1 Quiz Lifecycle (Full)

```
[Create Assessment Types] + [Create Difficulty Configs]
         (Admin — master setup)
                |
                v
[Create Quiz] — status: DRAFT
  |
  |-- Manual: search QB → assign questions → set ordinal/marks
  |-- Auto:   difficulty builder → fetch candidates → bulk-add
  |-- System: is_system_generated=1 → QuizGenerationService (proposed)
                |
                v
[PUBLISH Quiz] — status: PUBLISHED
                |
                v
[Create Allocation] — select target (CLASS/SECTION/GROUP/STUDENT)
                    — set published_at + due_date + cut_off_date
                    — configure is_auto_publish_result + result_publish_date
                |
                v
[published_at reached] → Quiz visible to student
                |
                v
[Student: Start Attempt] — validate window + attempt count
  — create lms_quiz_quest_attempts (IN_PROGRESS)
  — load questions (randomised if is_randomized=1)
                |
                v
[Student: Answer Questions] — auto-save every 30s
  — MCQ → selected_option_id
  — Descriptive → answer_text
  — Track time_taken_seconds per question
                |
                v
[Timer expires OR Student submits OR cut_off_date reached]
  — status: SUBMITTED / TIMEOUT
  — Auto-grade MCQ: compute marks_obtained, is_correct
  — Flag descriptive for teacher review (is_correct=NULL)
  — Compute total_score, percentage, is_passed
                |
        --------+--------
        |                |
  [show_result_immediately=1]   [show_result_immediately=0]
  Student sees result now        Result held pending publish
        |
        v
[Teacher: Grade Descriptive answers] (if any)
  — Award marks_obtained per answer
  — Recompute total_score
                |
                v
[Result Publish]
  — Auto: at result_publish_date (if auto_publish_result=1)
  — Manual: teacher clicks Publish
                |
                v
[ARCHIVED] — status: ARCHIVED
```

### 9.2 Difficulty Builder Workflow

```
[Teacher opens Difficulty Builder tab for a quiz]
        |
        v
[Select difficulty_config + filters (lesson, topic, type, complexity)]
        |
        v
[POST /difficulty-builder/questions] → returns candidate questions
   (filtered by for_quiz=1, usage_log, complexity %, type %)
        |
        v
[Teacher reviews candidate list]
        |
        v
[POST /difficulty-builder/add] → bulk-inserts into lms_quiz_questions
   (assigns ordinal, uses marks_per_question from detail if set)
```

### 9.3 Attempt Status State Machine

```
NOT_STARTED → IN_PROGRESS → SUBMITTED
                          → TIMEOUT  (timer expired — auto-submit)
                          → ABANDONED (detected inactive)
SUBMITTED   → REASSIGNED  (re-attempt granted)
IN_PROGRESS → CANCELLED   (admin cancels)
```

---

## 10. Non-Functional Requirements

| ID | Requirement | Target | Status |
|---|---|---|---|
| NFR-QUZ-01 | Quiz attempt concurrency | 500+ students simultaneously per quiz without degradation | 📐 |
| NFR-QUZ-02 | Auto-submit latency on timer expiry | < 5 seconds after timer zero | 📐 |
| NFR-QUZ-03 | Answer auto-save interval | Every 30 seconds; debounced on answer change | 📐 |
| NFR-QUZ-04 | Difficulty builder fetch performance | < 1 second for 1,000 QB questions | ✅ (existing) |
| NFR-QUZ-05 | Gate authorization on index() | `tenant.quiz.viewAny` must remain active; verify before release | 🟡 |
| NFR-QUZ-06 | Route prefix typo fix | Rename `lms-quize` → `lms-quiz` across tenant.php and all controllers | ❌ |
| NFR-QUZ-07 | EnsureTenantHasModule middleware | Must be added to route group | ❌ |
| NFR-QUZ-08 | Shared master integrity | DifficultyConfig and AssessmentType changes propagate to Quiz, Quest, Exam | ✅ |
| NFR-QUZ-09 | UUID binary storage | Quiz.php `boot()` must use `Str::uuid()->getBytes()` not `(string) Str::uuid()` | ❌ |
| NFR-QUZ-10 | DB transactions | store(), update(), destroy() in LmsQuizController must be wrapped in DB::transaction | ❌ |
| NFR-QUZ-11 | AJAX input validation | `getLessons()` endpoint must validate request inputs | ❌ |
| NFR-QUZ-12 | N+1 elimination | Quiz listing query must eager-load class/subject/lesson relationships | ❌ |
| NFR-QUZ-13 | Auto-save data loss prevention | Attempt answers must survive page reload; in-progress state recoverable | 📐 |
| NFR-QUZ-14 | Test coverage target | Minimum 40 test cases covering critical paths | ❌ |

---

## 11. Dependencies

### 11.1 Inbound (this module depends on)

| Module | Dependency | Detail |
|---|---|---|
| QuestionBank (QNS) | CRITICAL | `qns_questions_bank` source for `lms_quiz_questions`; difficulty builder queries QB; `qns_question_options` for MCQ answer recording |
| SchoolSetup (SCH) | FK dependency | `sch_classes`, `sch_subjects`; AJAX cascading dropdowns |
| Syllabus (SLB) | FK dependency | `slb_lessons`, `slb_topics`, `slb_question_types`, `slb_complexity_level`, `slb_bloom_taxonomy`, `slb_cognitive_skill` |
| StudentProfile (STD) | FK dependency | `std_students` in attempt tracking |
| Prime / Academic | FK dependency | `glb_academic_sessions` |
| qns_question_usage_type | FK dependency | Used by assessment_types and difficulty_configs |

### 11.2 Outbound (other modules depend on this module)

| Module | Dependency | Detail |
|---|---|---|
| LmsQuests (QST) | SHARED MASTER CONSUMER | `Modules\LmsQuiz\Models\AssessmentType` imported in Quest model and LmsQuestController; `Modules\LmsQuiz\Models\DifficultyDistributionConfig` imported in Quest model |
| LmsExam (EXM) | SHARED MASTER CONSUMER | `Modules\LmsQuiz\Models\DifficultyDistributionConfig` imported in ExamPaper model |

### 11.3 Shared Tables

| Table | Shared With |
|---|---|
| `lms_quiz_quest_attempts` | LmsQuests module (assessment_type='QUEST') |
| `lms_quiz_quest_attempt_answers` | LmsQuests module |
| `lms_assessment_types` | LmsQuests, LmsExam (read-only) |
| `lms_difficulty_distribution_configs` | LmsQuests, LmsExam (read-only) |

---

## 12. Test Scenarios

**Current test coverage: 0 tests**

### 12.1 Unit Tests

| Test | Scenario | Expected |
|---|---|---|
| TC-QUZ-U-01 | QuizCodeGeneratorTest — standard format | `QUIZ_{session}_{class}_{subject}_{lesson}_{topic}_{random4}` |
| TC-QUZ-U-02 | QuizCodeGeneratorTest — collision handling | Unique code generated on retry |
| TC-QUZ-U-03 | DifficultyPercentageValidationTest — sum=100% | Passes validation |
| TC-QUZ-U-04 | DifficultyPercentageValidationTest — sum>100% | Fails with error |
| TC-QUZ-U-05 | OnlyUnusedQuestionsFilterTest | Questions in usage_log excluded |
| TC-QUZ-U-06 | NegativeMarkingFloorTest — score floor at 0 | Score cannot go below 0 |
| TC-QUZ-U-07 | NegativeMarkingFloorTest — partial wrong answers | Correct deduction applied |
| TC-QUZ-U-08 | UuidBinaryStorageTest — getBytes() used | Stored value is 16 bytes |
| TC-QUZ-U-09 | AttemptScoringTest — all MCQ correct | total_score = total_marks |
| TC-QUZ-U-10 | AttemptScoringTest — mixed correct/wrong with negative marking | Correct net score |

### 12.2 Feature Tests

| Test | Scenario | Expected |
|---|---|---|
| TC-QUZ-F-01 | QuizCreationTest — happy path | Quiz created with auto-generated code |
| TC-QUZ-F-02 | QuizCreationTest — missing academic hierarchy | Validation error |
| TC-QUZ-F-03 | QuizCreationTest — duplicate quiz_code | DB constraint violation handled gracefully |
| TC-QUZ-F-04 | DifficultyBuilderTest — fetch questions matching profile | Returns correct count per complexity |
| TC-QUZ-F-05 | DifficultyBuilderTest — add questions | Questions inserted with correct ordinals |
| TC-QUZ-F-06 | QuizQuestionBulkStoreTest — add questions | `lms_quiz_questions` populated |
| TC-QUZ-F-07 | QuizQuestionBulkStoreTest — duplicate prevention | UNIQUE violation rejected |
| TC-QUZ-F-08 | QuizQuestionBulkStoreTest — ordinal update | Order persists |
| TC-QUZ-F-09 | QuizAllocationTest — CLASS allocation | Allocation record created |
| TC-QUZ-F-10 | QuizAllocationTest — allocation-level auto_publish override | Overrides quiz-level setting |
| TC-QUZ-F-11 | QuizGateTest — index() requires permission | 403 for unauthenticated user |
| TC-QUZ-F-12 | RouteTypoFixTest — redirects work after rename | No 404 on redirect after store |
| TC-QUZ-F-13 | AssessmentTypeUsageFilterTest — QUIZ-type only in quiz creation | QUEST-type not shown |
| TC-QUZ-F-14 | StudentAttemptTest — start attempt within window | Attempt created IN_PROGRESS |
| TC-QUZ-F-15 | StudentAttemptTest — start attempt after cut_off_date | Rejected with error |
| TC-QUZ-F-16 | StudentAttemptTest — exceed max_attempts | Rejected |
| TC-QUZ-F-17 | StudentAttemptTest — MCQ auto-grading on submit | Correct marks computed |
| TC-QUZ-F-18 | StudentAttemptTest — timer expiry auto-submit | Status = TIMEOUT |
| TC-QUZ-F-19 | TeacherGradingTest — grade descriptive answer | marks_obtained saved; total_score recomputed |
| TC-QUZ-F-20 | ResultPublishTest — auto_publish at result_publish_date | Results visible to student |
| TC-QUZ-F-21 | EnsureTenantHasModuleTest — module not licensed | 403 returned |
| TC-QUZ-F-22 | FillableFieldTest — only_unused_questions saves correctly | Stored in DB after fix |
| TC-QUZ-F-23 | FillableFieldTest — only_authorised_questions saves correctly | Stored in DB after fix |

---

## 13. Glossary

| Term | Meaning |
|---|---|
| Quiz | A short topic-focused timed assessment used for knowledge checks, practice, or diagnosis |
| Assessment Type | Pedagogical category (Practice, Challenge, Diagnostic, Remedial, etc.) shared across Quiz/Quest/Exam |
| Difficulty Config | Named profile defining percentages of Easy/Medium/Hard questions per question type |
| Difficulty Builder | AJAX-driven UI to auto-select questions matching a difficulty profile |
| Scope Topic | Primary topic covered by a quiz; may include sub-topics beneath it |
| Allocation | Assignment of a published quiz to a target audience with timing windows |
| Auto-Publish Result | Releases class-wide results at a specified date (configurable per allocation) |
| Cut-off Date | Hard deadline — no new attempt starts after this datetime |
| Only Unused Questions | Flag restricting QB query to questions not yet presented to the student |
| Only Authorised Questions | Flag restricting QB query to `qns_questions_bank.for_quiz = 1` |
| System Generated | Quiz created automatically by algorithm rather than a teacher |
| Timer Enforced | Countdown timer shown and auto-submit triggered on expiry |
| is_correct=NULL | Answer not yet graded — requires teacher manual evaluation |
| TIMEOUT | Attempt status when auto-submitted after timer expiry |
| Shared Master | Table owned by LmsQuiz but consumed read-only by LmsQuests and LmsExam |

---

## 14. Suggestions

### P0 — Critical (Fix Before Any Further Development)

1. **Fix route prefix typo** — Change all occurrences of `lms-quize` and `quize` to `lms-quiz` and `quiz` in `routes/tenant.php` (line 688), `LmsQuizController` (all redirect calls), `QuizQuestionController`, `QuizAllocationController`, and all 26+ blade view files that reference route names.

2. **Add `EnsureTenantHasModule` middleware** to the `lms-quize` route group in `tenant.php`.

3. **Fix UUID binary storage** in `Quiz::boot()` — change `$model->uuid = (string) Str::uuid()` to `$model->uuid = Str::uuid()->getBytes()`. Align cast: `'uuid' => 'string'` needs custom accessor or use hex string consistently with a migration.

4. **Verify Gate::authorize()** — Current code shows Gate is active on line 34. Confirm this has not been accidentally re-commented during any merge and add a regression test (TC-QUZ-F-11).

### P1 — High Priority (Required for Module Stability)

5. **Add `only_unused_questions` and `only_authorised_questions` to `Quiz::$fillable`** — both columns exist in DDL and are critical for question selection but are absent from the fillable array. Data submitted via forms will be silently discarded.

6. **Remove duplicate quiz_code generation from controller** — logic exists in both `Quiz::boot()` (creating event) and in `LmsQuizController::store()`/`update()`. Keep only model boot() logic; delete controller copy to eliminate potential race conditions.

7. **Wrap store/update/destroy in DB::transaction** in `LmsQuizController` — multiple DB writes in each action are not atomic.

8. **Add input validation to `getLessons()` AJAX endpoint** — currently accepts raw request parameters without validation; potential for injection or unexpected errors.

9. **Add `created_by` to `AssessmentType`, `DifficultyDistributionConfig`, and `QuizQuestion` models** — these models lack audit trail for who created the record.

10. **Add a dedicated `/publish` route** — instead of requiring teacher to use edit form to change `status` field. Similar to LmsHomework's `publish` route pattern already in the codebase.

### P2 — Medium Priority (Required for Launch)

11. **Build complete student attempt pipeline** — `StudentQuizAttemptController`, `QuizQuestAttempt` model, `QuizQuestAttemptAnswer` model, 4 views, routes (see FR-QUZ-006).

12. **Build teacher manual grading flow** — `TeacherQuizGradingController`, grading views, marks entry, total_score recomputation (see FR-QUZ-007).

13. **Implement `AutoSubmitExpiredAttemptJob`** — Laravel Queue job or scheduled command that checks `IN_PROGRESS` attempts where `started_at + duration_minutes * 60 < now()` and auto-submits with TIMEOUT status.

14. **Implement results publishing** — both auto (scheduler + `result_publish_date`) and manual (teacher action) pathways (see FR-QUZ-008).

15. **Eliminate N+1 in index()** — eager-load class/subject/lesson in `quizzesQuery()`; replace `Topic::where()->get()` and `Quiz::where()->get()` with paginated or limited queries.

### P3 — Lower Priority (Post-Launch)

16. **Implement `QuizGenerationService`** — when `is_system_generated = 1`, auto-select questions from QB using difficulty config profile (see FR-QUZ-010).

17. **Implement quiz analytics** — per-quiz attempt summary, item analysis (question-wise correct rate), class performance report (see FR-QUZ-009).

18. **Consider extracting shared masters to a `LmsMaster` module** — `AssessmentType` and `DifficultyDistributionConfig` being owned by `LmsQuiz` but imported by `LmsQuests` and `LmsExam` creates a unidirectional dependency. A neutral `LmsMaster` module would be architecturally cleaner and easier to maintain.

19. **Write comprehensive test suite** — minimum 40 test cases; target TC-QUZ-U-01 through TC-QUZ-F-23 from Section 12; use Pest syntax consistent with SmartTimetable test files.

20. **Add auto-save beacon fallback** — in addition to 30-second AJAX auto-save in the attempt player, implement `navigator.sendBeacon()` for reliability on page close/navigation away.

---

## 15. Appendices

### Appendix A: File Inventory (Current State)

```
Modules/LmsQuiz/
├── app/
│   ├── Http/
│   │   ├── Controllers/
│   │   │   ├── LmsQuizController.php           (tab hub + Quiz CRUD — 5 queries in index; Gate active line 34)
│   │   │   ├── QuizQuestionController.php       (CRUD + 13 AJAX endpoints + difficulty-builder)
│   │   │   ├── QuizAllocationController.php     (CRUD)
│   │   │   ├── AssessmentTypeController.php     (CRUD — SHARED master)
│   │   │   └── DifficultyDistributionConfigController.php  (CRUD — SHARED master + detail mgmt)
│   │   └── Requests/
│   │       ├── QuizRequest.php
│   │       ├── AssessmentTypeRequest.php
│   │       ├── DifficultyDistributionConfigRequest.php
│   │       ├── QuizAllocationRequest.php
│   │       └── QuizQuestionRequest.php
│   ├── Models/
│   │   ├── Quiz.php                            (lms_quizzes — UUID bug; missing fillable fields)
│   │   ├── QuizQuestion.php                    (lms_quiz_questions)
│   │   ├── QuizAllocation.php                  (lms_quiz_allocations)
│   │   ├── AssessmentType.php                  (SHARED — imported by LmsQuests, LmsExam)
│   │   ├── DifficultyDistributionConfig.php    (SHARED — imported by LmsQuests, LmsExam)
│   │   └── DifficultyDistributionDetail.php    (child of DifficultyDistributionConfig)
│   └── Policies/
│       ├── QuizPolicy.php
│       ├── QuizQuestionPolicy.php
│       ├── QuizAllocationPolicy.php
│       ├── AssessmentTypePolicy.php
│       └── DifficultyDistributionConfigPolicy.php
├── resources/views/
│   ├── tab_module/tab.blade.php
│   ├── index.blade.php
│   ├── quiz/{create,edit,show,index,trash}.blade.php
│   ├── quiz-question/{create,edit,show,index,trash,difficulty_builder_tab}.blade.php
│   ├── quiz-allocation/{create,edit,show,index,trash}.blade.php
│   ├── assessment-type/{create,edit,show,index,trash}.blade.php
│   ├── difficulty-config/{create,edit,show,index,trash}.blade.php
│   └── components/
└── routes/
    ├── web.php    (minimal stub)
    └── api.php    (minimal stub)
```

Main routes defined in: `routes/tenant.php` lines 688–744

### Appendix B: Cross-Module Import Map

```
LmsQuiz owns:
  Modules\LmsQuiz\Models\AssessmentType
  Modules\LmsQuiz\Models\DifficultyDistributionConfig

Imported by:
  Modules\LmsQuests\Models\Quest
    → use Modules\LmsQuiz\Models\AssessmentType
    → use Modules\LmsQuiz\Models\DifficultyDistributionConfig
  Modules\LmsQuests\Http\Controllers\LmsQuestController
    → use Modules\LmsQuiz\Models\AssessmentType
    → use Modules\LmsQuiz\Models\DifficultyDistributionConfig
  Modules\LmsExam\Models\ExamPaper
    → use Modules\LmsQuiz\Models\DifficultyDistributionConfig
```

Any change to these models (especially namespace change if refactored to LmsMaster) requires updating all 3+ consuming locations.

### Appendix C: Confirmed Bugs Summary

| ID | File | Line | Severity | Description |
|---|---|---|---|---|
| BUG-01 | routes/tenant.php | 688 | MEDIUM | Route prefix `lms-quize` (extra 'e') — affects all named routes |
| BUG-02 | routes/tenant.php | 691 | MEDIUM | Resource name `quize` instead of `quiz` |
| BUG-03 | LmsQuizController.php | All redirect calls | MEDIUM | `route('lms-quize.quize.index')` propagates typo |
| BUG-04 | Quiz.php | 96 | HIGH | `uuid = (string) Str::uuid()` stores 36-char string in BINARY(16) column |
| BUG-05 | Quiz.php | 61 | MEDIUM | `only_unused_questions` not in `$fillable` |
| BUG-06 | Quiz.php | 61 | MEDIUM | `only_authorised_questions` not in `$fillable` |
| BUG-07 | LmsQuizController.php | 99-114 + store()/update() | LOW | Quiz code generation duplicated in boot() and controller |
| BUG-08 | routes/tenant.php | 688 | CRITICAL | `EnsureTenantHasModule` middleware absent |
| BUG-09 | LmsQuizController.php | 256, 354, 410 | MEDIUM | No DB::transaction in store/update/destroy |
| BUG-10 | LmsQuizController.php | 51, 53 | MEDIUM | Full table loads without pagination for topics and quizzes lists |

---

## 16. V1 → V2 Delta

| Section | V1 State | V2 Change |
|---|---|---|
| Gate status | Reported as COMMENTED OUT | Current code shows Gate ACTIVE on line 34; status updated to "verify" |
| DDL source | Referenced tenant_db_v2.sql (not found in project) | Updated to use confirmed DDL at `1-DDL_Tenant_Modules/53b-LMS_Quiz/LMS_Quiz_ddl_v2.sql` and `55e-LMS_StudentAttempts_/StudentAttempt_ddl_v1.sql` |
| Shared attempt tables | Named `lms_quiz_quest_attempts` and `lms_quiz_quest_attempt_answers` | Confirmed table names from actual DDL file; distinct from LmsExam's `lms_student_attempts` (exam-specific) |
| FR-QUZ-006 | Brief description only | Fully expanded into 6 sub-requirements (006a–006f) with all fields, validations, and processing logic |
| FR-QUZ-007 | Not in V1 | FR-QUZ-007 (Teacher Manual Grading) added as new functional requirement |
| FR-QUZ-008 | Not in V1 | FR-QUZ-008 (Results Publishing) added as new functional requirement |
| FR-QUZ-009 | Not in V1 | FR-QUZ-009 (Analytics) added as proposed requirement |
| Data model | lms_quiz_quest_attempt_answers documented | `time_taken_seconds` column added; `selected_option_ids` (JSON for multi-MCQ) clarified |
| Routes table | Current routes only | Separated into existing (6.1) and proposed new (6.2) with 11 new student/grading/publish routes |
| UI Screens | Existing 11 screens | Added 8 proposed student/teacher screens in section 7.2 |
| Business rules | 11 rules | Expanded to 15 rules including attempt count, descriptive grading, PUBLISHED-before-allocate |
| Test scenarios | 11 proposed tests | Expanded to 23 (10 unit + 23 feature) covering the complete pipeline |
| Suggestions | 9 items | Expanded to 20 items with P0/P1/P2/P3 priority tiers |
| Appendix C | Not in V1 | Bug summary table added with 10 confirmed bugs with file/line references |
