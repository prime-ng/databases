# LmsQuests Module — Requirement Specification Document

**Version:** 1.0 | **Date:** 2026-03-25 | **Author:** Claude Code (Automated Extraction)
**Platform:** Prime-AI Academic Intelligence Platform
**Module Code:** QST | **Module Path:** `Modules/LmsQuests`
**Module Type:** Tenant | **Database:** tenant_db
**Table Prefix:** `lms_quest*` | **Processing Mode:** FULL
**RBS Reference:** Module S — Learning Management System (LMS)

---

## 1. EXECUTIVE SUMMARY

LmsQuests is the formative assessment and challenge engine of Prime-AI. A "Quest" is a longer-horizon or cross-lesson timed assessment (as distinct from a Quiz which is topic-focused and shorter). Quests support multi-lesson scope definition, complexity-level difficulty profiling, question bank integration, and flexible allocation (CLASS/SECTION/GROUP/STUDENT) with published and due dates. Quests share the same underlying attempt infrastructure (`lms_quiz_quest_attempts`) as Quizzes via a polymorphic `assessment_type` column.

**Current implementation status: ~60% complete.**

The teacher-facing quest creation, scope definition, question assignment, and allocation flows are functional. The student-facing attempt pipeline (taking the quest, viewing results) is completely absent. A security defect exists: `Gate::authorize` is commented out in the index() method of `LmsQuestController`. No `EnsureTenantHasModule` middleware is applied.

**Stats:**
- Controllers: 4 | Models: 4 | Services: 0 | FormRequests: 4 | Tests: 0
- Database tables: `lms_quests`, `lms_quest_scopes`, `lms_quest_questions`, `lms_quest_allocations`
- Shared attempt tables: `lms_quiz_quest_attempts`, `lms_quiz_quest_attempt_answers`

---

## 2. MODULE OVERVIEW

### Business Purpose
Enable teachers to create multi-lesson formative assessments ("Quests") that evaluate student understanding across a broader curriculum scope. Quests support challenge, enrichment, diagnostic, and remedial assessment modes. They integrate with the Question Bank for automated or manual question selection and with the allocation system for targeted delivery to specific student populations.

### Key Features
1. Quest creation with academic hierarchy (session → class → subject → lesson)
2. Multi-lesson scope definition (which lessons/topics/question-types are in scope)
3. Question assignment from Question Bank with ordinal and marks override
4. Quest allocation to CLASS/SECTION/GROUP/STUDENT with timing windows
5. Assessment type categorisation (Challenge, Enrichment, Practice, Revision, Diagnostic, Remedial, Re-Test) via shared `lms_assessment_types`
6. Difficulty distribution config from shared `lms_difficulty_distribution_configs`
7. Timer enforcement, randomisation, multiple attempts, negative marking
8. Auto-publish result and show-correct-answer post-attempt options
9. Shared attempt tracking infrastructure with LmsQuiz

### Menu Path
`LMS > Quests`

### Architecture
Tab-based single-page interface via `LmsQuestController::index()`. Uses the same shared models `AssessmentType` and `DifficultyDistributionConfig` from `Modules\LmsQuiz`. Individual CRUD under `lms-quests.*` prefix.

---

## 3. STAKEHOLDERS & ACTORS

| Actor | Role |
|---|---|
| Teacher | Creates quest, defines scope, adds questions, creates allocations |
| Admin | Manages assessment types and difficulty configs (via LmsQuiz module) |
| Student | (Absent) Takes quest, views result — NOT YET IMPLEMENTED |
| Parent | (Absent) Views child's quest attempt — NOT YET IMPLEMENTED |
| QuestionBank Module | Provides questions to lms_quest_questions |
| LmsQuiz Module | Provides shared models: AssessmentType, DifficultyDistributionConfig |

---

## 4. FUNCTIONAL REQUIREMENTS

### FR-QST-001: Quest Creation
**RBS Reference:** S3.1 (Quiz Builder) | **Priority:** Critical | **Status:** Implemented (Gate disabled in index — SECURITY BUG)
**Tables:** `lms_quests`

**Description:** Teacher creates a quest with full academic hierarchy, assessment type, difficulty config, grading settings (marks, passing %), timer, randomisation, attempt policies, and result display options.

**Actors:** Teacher, Admin
**Input:** quest_code (auto-generated), title, description, instructions, academic_session_id, class_id, subject_id, lesson_id, quest_type_id (AssessmentType), difficulty_config_id, duration_minutes, total_marks, total_questions, passing_percentage, allow_multiple_attempts, max_attempts, negative_marks, is_randomized, question_marks_shown, show_result_immediately, auto_publish_result, timer_enforced, show_correct_answer, show_explanation, is_system_generated

**Processing:**
- Auto-generates quest_code: `QUEST_{session_code}_{class_code}_{subject_code}_{lesson_code}_{random6}`
- UUID generated on boot
- status defaults to DRAFT

**KNOWN BUG — SECURITY:**
```php
// LmsQuestController::index() line 35
// Gate::authorize('tenant.quest.viewAny');  // COMMENTED OUT
```
Any authenticated user can list all quests without the `tenant.quest.viewAny` permission check.

**Acceptance Criteria:**
- Quest code is globally unique
- Academic hierarchy (session + class + subject + lesson) must be complete
- `total_questions` must match actual number of assigned questions before publishing
- Gate authorization must be re-enabled

**Current Implementation:**
- `LmsQuestController` — index (Gate disabled), create, store, show, edit, update, destroy, trashed, restore, forceDelete, toggleStatus
- Model: `Modules\LmsQuests\Models\Quest`, table: `lms_quests`
- Route: `lms-quests.quest.*`
- Missing: `EnsureTenantHasModule` middleware

---

### FR-QST-002: Quest Scope Definition
**RBS Reference:** S3.1 (Quiz Settings) | **Priority:** High | **Status:** Implemented
**Tables:** `lms_quest_scopes`

**Description:** Defines the curriculum scope of a quest: which lessons, topics, and question types are covered, and optionally specifies target question counts per scope entry. This is richer than a Quiz's single-topic scope — a Quest can span multiple lessons and topics simultaneously.

**Actors:** Teacher
**Input:** quest_id, lesson_id, topic_id, question_type_id (optional), target_question_count

**Auxiliary AJAX endpoint:**
- `GET /lms-quests/quest-scope/get-topics` — retrieves topics for a selected lesson

**Current Implementation:**
- `QuestScopeController` — full CRUD + trashed/restore/forceDelete/toggleStatus + getTopics()
- Model: `Modules\LmsQuests\Models\QuestScope`
- Route: `lms-quests.quest-scope.*`

---

### FR-QST-003: Quest Question Assignment
**RBS Reference:** S3.1 / S4 | **Priority:** Critical | **Status:** Implemented (rich AJAX interface)
**Tables:** `lms_quest_questions`

**Description:** Links questions from the Question Bank to a Quest with ordinal ordering and marks override. Supports bulk add/remove and inline editing of order and marks.

**Actors:** Teacher
**Input:** quest_id, question_id, ordinal, marks_override

**AJAX Endpoints (all under lms-quests prefix):**
- `GET /lms-quests/get-sections` — cascade: sections for a class
- `GET /lms-quests/get-subject-groups` — subject groups
- `GET /lms-quests/get-subjects` — subjects for class/section
- `GET /lms-quests/get-lessons` — lessons for subject
- `GET /lms-quests/get-topics` — topics for lesson
- `GET /lms-quests/search` — search Question Bank with filters
- `GET /lms-quests/existing` — list already-assigned questions
- `POST /lms-quests/bulk-store` — add multiple questions at once
- `POST /lms-quests/bulk-destroy` — remove multiple questions
- `POST /lms-quests/update-ordinal` — drag-and-drop reorder
- `POST /lms-quests/update-marks` — inline marks override
- `GET /lms-quests/quest-meta` — quest metadata for question form

**Acceptance Criteria:**
- UNIQUE (quest_id, question_id) constraint prevents duplicate question assignment
- ordinal must be maintained consistently after reorder
- marks_override when NULL uses the question's default marks from QB

**Current Implementation:**
- `QuestQuestionController` — full CRUD + 10 AJAX endpoints
- Model: `Modules\LmsQuests\Models\QuestQuestion`
- Route: `lms-quests.quest-question.*`

---

### FR-QST-004: Quest Allocation
**RBS Reference:** S3.1.2 | **Priority:** Critical | **Status:** Implemented
**Tables:** `lms_quest_allocations`

**Description:** Assigns a published quest to a target (CLASS/SECTION/GROUP/STUDENT) with a publication date, due date, cut-off date, and result publish date.

**Actors:** Teacher, Admin
**Input:** quest_id, allocation_type (CLASS/SECTION/GROUP/STUDENT), target_table_name, target_id, assigned_by, published_at, due_date, cut_off_date, is_auto_publish_result, result_publish_date

**Auxiliary AJAX endpoint:**
- `GET /lms-quests/quest-allocation/get-target-options` — returns available targets based on allocation_type

**FK note:** `target_id` is polymorphic — references different tables based on `allocation_type`. Application-level FK enforcement required (no DB foreign key possible).

**Current Implementation:**
- `QuestAllocationController` — full CRUD + trashed/restore/forceDelete/toggleStatus + getTargetOptions()
- Model: `Modules\LmsQuests\Models\QuestAllocation`
- Route: `lms-quests.quest-allocation.*`

---

### FR-QST-005: Quest Attempt — Student Side (ABSENT)
**RBS Reference:** S3.1 / S5 | **Priority:** Critical | **Status:** NOT IMPLEMENTED
**Tables:** `lms_quiz_quest_attempts`, `lms_quiz_quest_attempt_answers`

**Description (proposed):** Student sees their allocated quests, opens one during the published/due window, starts a timed attempt, answers questions, submits. The system auto-grades MCQ answers, flags descriptive answers for teacher review.

**Shared infrastructure from DDL:**
- `lms_quiz_quest_attempts.assessment_type = 'QUEST'`
- `lms_quiz_quest_attempt_answers` linked to attempt

**Required controllers (to be created):**
- `StudentQuestAttemptController` — myQuests, startAttempt, saveAnswer, submitAttempt, viewResult
- View: student quest list, attempt interface (timer + questions), result screen

---

### FR-QST-006: Quest Publish Workflow (PARTIALLY IMPLEMENTED)
**RBS Reference:** S3 | **Priority:** High | **Status:** Partial

**Description:** Quest model has `canPublish()` validation and `publish()` method that transitions status to PUBLISHED. However, no dedicated route or controller action calls `publish()` — status is changed only via the generic update() form. A dedicated publish/archive endpoint would improve UX.

**Current implementation notes:**
- `Quest::canPublish()` — checks: total_questions > 0, total_questions matches assigned count, settings valid, academic hierarchy complete
- `Quest::publish()` — sets status=PUBLISHED, published_at=now()
- `Quest::archive()` — sets status=ARCHIVED, is_active=false
- No `/publish` route exists; teacher must use edit form to change status

---

## 5. DATA MODEL & ENTITY SPECIFICATION

### lms_quests
| Column | Type | Notes |
|---|---|---|
| id | INT UNSIGNED PK | |
| uuid | BINARY(16) | UNIQUE NOT NULL (stored as string in model) |
| academic_session_id | INT UNSIGNED | FK glb_academic_sessions CASCADE |
| class_id | INT UNSIGNED | FK sch_classes CASCADE |
| subject_id | INT UNSIGNED | FK sch_subjects CASCADE |
| quest_type_id | INT UNSIGNED | FK lms_assessment_types CASCADE |
| quest_code | VARCHAR(50) | UNIQUE NOT NULL |
| title | VARCHAR(255) | NOT NULL |
| description | TEXT | NULL |
| instructions | TEXT | NULL |
| status | VARCHAR(20) | DEFAULT 'DRAFT' (DRAFT/PUBLISHED/ARCHIVED) |
| duration_minutes | INT UNSIGNED | NULL=unlimited |
| total_marks | DECIMAL(8,2) | DEFAULT 0.00 |
| total_questions | INT UNSIGNED | DEFAULT 0 |
| passing_percentage | DECIMAL(5,2) | DEFAULT 33.00 |
| allow_multiple_attempts | TINYINT(1) | DEFAULT 0 |
| max_attempts | TINYINT UNSIGNED | DEFAULT 1 |
| negative_marks | DECIMAL(4,2) | DEFAULT 0.00 |
| is_randomized | TINYINT(1) | DEFAULT 0 |
| question_marks_shown | TINYINT(1) | DEFAULT 0 |
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

**Note:** DDL does NOT have a `lesson_id` column on `lms_quests`, but the Model and controller both use `lesson_id` in fillable and code-gen logic. This is a MODEL-DDL MISMATCH. The lesson coverage is intended to be defined via `lms_quest_scopes` instead.

**Model:** `Modules\LmsQuests\Models\Quest`
- Relationships: academicSession, class, subject, lesson (BelongsTo — but no DB column), assessmentType, difficultyConfig, creator, scopes (HasMany), questQuestions (HasMany), questions (BelongsToMany via lms_quest_questions), allocations (HasMany)
- Cross-module: imports `AssessmentType` and `DifficultyDistributionConfig` from `Modules\LmsQuiz`
- Key methods: canPublish(), publish(), archive(), restoreQuest(), duplicate(), validateSettings()
- Computed: academic_hierarchy, marks_per_question, passing_marks, is_published, is_draft, has_timer, duration_formatted, statistics, summary

### lms_quest_scopes
| Column | Type | Notes |
|---|---|---|
| id | INT UNSIGNED PK | |
| quest_id | INT UNSIGNED | FK lms_quests CASCADE |
| lesson_id | INT UNSIGNED | FK slb_lessons CASCADE |
| topic_id | INT UNSIGNED | FK slb_topics CASCADE |
| question_type_id | INT UNSIGNED | FK slb_question_types NULL |
| target_question_count | INT UNSIGNED | DEFAULT 0 (0=all) |
| is_active, created_at, updated_at, deleted_at | standard | |

### lms_quest_questions
| Column | Type | Notes |
|---|---|---|
| id | INT UNSIGNED PK | |
| quest_id | INT UNSIGNED | FK lms_quests CASCADE |
| question_id | INT UNSIGNED | FK qns_questions_bank CASCADE |
| ordinal | INT UNSIGNED | DEFAULT 0 |
| marks_override | DECIMAL(5,2) | NULL |
| is_active, created_at, updated_at, deleted_at | standard | |
| **UNIQUE** | (quest_id, question_id) | |

### lms_quest_allocations
| Column | Type | Notes |
|---|---|---|
| id | INT UNSIGNED PK | |
| quest_id | INT UNSIGNED | FK lms_quests CASCADE |
| allocation_type | ENUM('CLASS','SECTION','GROUP','STUDENT') | |
| target_table_name | VARCHAR(60) | Application-level FK only |
| target_id | INT UNSIGNED | Polymorphic — FK enforced at app level |
| assigned_by | INT UNSIGNED | FK sys_users NULL |
| published_at | DATETIME | NULL — when quest becomes visible |
| due_date | DATETIME | NULL |
| cut_off_date | DATETIME | NULL — no submissions after this |
| is_auto_publish_result | TINYINT(1) | DEFAULT 0 |
| result_publish_date | DATETIME | NULL |
| is_active, created_at, updated_at, deleted_at | standard | |
| INDEX | (allocation_type, target_id) | |

### lms_quiz_quest_attempts (SHARED with LmsQuiz)
| Column | Type | Notes |
|---|---|---|
| id | INT UNSIGNED PK | |
| student_id | INT UNSIGNED | FK sch_students |
| assessment_type | ENUM('QUIZ','QUEST') | polymorphic |
| assessment_id | INT UNSIGNED | FK to quiz or quest (app-level) |
| allocation_id | INT UNSIGNED | FK to allocation (app-level) |
| attempt_number | TINYINT UNSIGNED | increments per attempt |
| started_at | DATETIME | |
| completed_at | DATETIME | NULL |
| status | ENUM(NOT_STARTED, IN_PROGRESS, SUBMITTED, TIMEOUT, ABANDONED, CANCELLED, REASSIGNED) | |
| total_score | DECIMAL(8,2) | NULL |
| percentage | DECIMAL(5,2) | NULL |
| is_passed | TINYINT(1) | DEFAULT 0 |
| teacher_feedback | TEXT | NULL |
| is_active, created_at, updated_at, deleted_at | standard | |

---

## 6. API & ROUTE SPECIFICATION

**Route Prefix:** `/lms-quests` | **Name Prefix:** `lms-quests.`
**Middleware:** `auth`, `verified` (NOTE: `EnsureTenantHasModule` is MISSING)

| Method | URI | Name | Controller | Action |
|---|---|---|---|---|
| GET | /lms-quests/quest | lms-quests.quest.index | LmsQuestController | Tab view (Gate DISABLED) |
| GET | /lms-quests/quest/create | lms-quests.quest.create | LmsQuestController | Create form |
| POST | /lms-quests/quest | lms-quests.quest.store | LmsQuestController | Store |
| GET | /lms-quests/quest/{id} | lms-quests.quest.show | LmsQuestController | Show |
| GET | /lms-quests/quest/{id}/edit | lms-quests.quest.edit | LmsQuestController | Edit form |
| PUT | /lms-quests/quest/{id} | lms-quests.quest.update | LmsQuestController | Update |
| DELETE | /lms-quests/quest/{id} | lms-quests.quest.destroy | LmsQuestController | Soft delete (+ set ARCHIVED) |
| GET | /lms-quests/quest/trash/view | lms-quests.quest.trashed | LmsQuestController | Trash list |
| GET | /lms-quests/quest/{id}/restore | lms-quests.quest.restore | LmsQuestController | Restore |
| DELETE | /lms-quests/quest/{id}/force-delete | lms-quests.quest.forceDelete | LmsQuestController | Force delete |
| POST | /lms-quests/quest/{id}/toggle-status | lms-quests.quest.toggleStatus | LmsQuestController | Toggle active |
| (resource) | /lms-quests/quest-scope | lms-quests.quest-scope.* | QuestScopeController | Full CRUD |
| GET | /lms-quests/quest-scope/get-topics | lms-quests.quest-scope.getTopics | QuestScopeController | AJAX topics |
| (resource) | /lms-quests/quest-allocation | lms-quests.quest-allocation.* | QuestAllocationController | Full CRUD |
| GET | /lms-quests/quest-allocation/get-target-options | lms-quests.quest-allocation.getTargetOptions | QuestAllocationController | AJAX targets |
| (resource) | /lms-quests/quest-question | lms-quests.quest-question.* | QuestQuestionController | Full CRUD |
| GET | /lms-quests/search | lms-quests.search | QuestQuestionController | QB search |
| GET | /lms-quests/existing | lms-quests.existing | QuestQuestionController | Existing questions |
| POST | /lms-quests/bulk-store | lms-quests.bulk-store | QuestQuestionController | Bulk add |
| POST | /lms-quests/bulk-destroy | lms-quests.bulk-destroy | QuestQuestionController | Bulk remove |
| POST | /lms-quests/update-ordinal | lms-quests.update-ordinal | QuestQuestionController | Reorder |
| POST | /lms-quests/update-marks | lms-quests.update-marks | QuestQuestionController | Marks override |
| GET | /lms-quests/get-sections | lms-quests.get-sections | QuestQuestionController | AJAX sections |
| GET | /lms-quests/get-lessons | lms-quests.get-lessons | QuestQuestionController | AJAX lessons |
| GET | /lms-quests/get-topics | lms-quests.get-topics | QuestQuestionController | AJAX topics |
| GET | /lms-quests/quest-meta | lms-quests.quest-meta | QuestQuestionController | Quest metadata |

---

## 7. UI SCREEN INVENTORY & FIELD MAPPING

| Screen | View File | Purpose |
|---|---|---|
| Quest Hub (tab) | `tab_module/tab.blade.php` | Main container: quests, scopes, questions, allocations |
| Quest Create | `quest/create.blade.php` | Title, class, subject, lesson, type, difficulty, settings |
| Quest Edit | `quest/edit.blade.php` | Same fields |
| Quest Show | `quest/show.blade.php` | Detail + questions list |
| Quest Trash | `quest/trash.blade.php` | Soft-deleted |
| Quest List | `quest/index.blade.php` | Filter by status, type, date range |
| Quest Scope List | `quest-scope/index.blade.php` | Scopes per quest |
| Quest Scope Create | `quest-scope/create.blade.php` | lesson_id, topic_id, question_type_id, target_count |
| Quest Question List | `quest-question/index.blade.php` | Questions with ordinal, marks |
| Quest Question Create | `quest-question/create.blade.php` | QB search + bulk add interface |
| Quest Allocation List | `quest-allocation/index.blade.php` | Allocation per quest |
| Quest Allocation Create | `quest-allocation/create.blade.php` | Allocation type, target, dates |
| Module Index | `index.blade.php` | Module landing page |

---

## 8. BUSINESS RULES & DOMAIN CONSTRAINTS

1. **Quest code uniqueness:** UNIQUE (quest_code) globally — enforced at DB and in model boot.
2. **Publish guard:** Quest cannot be published unless: total_questions > 0, actual question count matches total_questions config, all settings are valid, academic hierarchy is complete.
3. **Multiple attempts:** When `allow_multiple_attempts = 0`, max_attempts=1. When enabled, max_attempts can be set to 2 or more.
4. **Negative marking:** When `negative_marks > 0`, wrong MCQ answers deduct marks. Minimum score is 0 (no negative total).
5. **Cut-off date:** Once past cut_off_date, no new attempt starts even if `max_attempts` not reached.
6. **Auto-publish result:** If `is_auto_publish_result = 1` on allocation, results visible immediately after `result_publish_date` passes.
7. **Duplicate questions:** UNIQUE (quest_id, question_id) prevents adding the same question twice.
8. **Scope vs direct lesson:** Quest has a `lesson_id` FK in the model/code but NOT in the DDL. Lesson coverage should be defined via `lms_quest_scopes`. This discrepancy must be resolved.
9. **Assessment type usage:** `quest_type_id` links to `lms_assessment_types.assessment_usage_type_id = 'QUEST'` — only Quest-type assessment types should be shown.

---

## 9. WORKFLOW & STATE MACHINE DEFINITIONS

### Quest Lifecycle
```
[Create Quest] (DRAFT)
     ↓
[Define Scopes] (which lessons/topics covered)
     ↓
[Assign Questions from QB] → [lms_quest_questions]
     ↓
[canPublish() validation] — must pass before status change
     ↓
[PUBLISH Quest]
     ↓
[Create Allocations] (target + published_at + due_date + cut_off_date)
     ↓
[published_at reached] → Quest visible to allocated students
     ↓
[Student Attempts Quest] (within due_date and before cut_off_date)
  ├── attempt_number increments per attempt (up to max_attempts)
  ├── MCQ: auto-graded
  └── Descriptive: teacher_feedback + manual score
     ↓
[total_score + percentage computed]
     ↓
[result_publish_date reached] → Score visible to student
     ↓
[ARCHIVED]
```

### Attempt Status Transitions
```
NOT_STARTED → IN_PROGRESS → SUBMITTED
                           → TIMEOUT (timer expired)
                           → ABANDONED (student left)
IN_PROGRESS → CANCELLED (admin action)
SUBMITTED → REASSIGNED (allow re-attempt)
```

---

## 10. NON-FUNCTIONAL REQUIREMENTS

| # | Requirement | Target |
|---|---|---|
| NFR-QST-01 | Quest attempt concurrency | 500+ students simultaneously |
| NFR-QST-02 | Auto-submit on timer expiry | Within 5 seconds of timer = 0 |
| NFR-QST-03 | Answer auto-save | Save answer every 30 seconds to prevent data loss |
| NFR-QST-04 | Randomisation | Question order + option order randomisation per student |
| NFR-QST-05 | Gate authorization | Re-enable `tenant.quest.viewAny` in index() |
| NFR-QST-06 | EnsureTenantHasModule middleware | Must be added to route group |
| NFR-QST-07 | Audit trail | All CUD operations logged via activityLog() |

---

## 11. CROSS-MODULE DEPENDENCIES

| Module | Dependency Type | Detail |
|---|---|---|
| **QuestionBank** | CRITICAL | `qns_questions_bank` is source for `lms_quest_questions.question_id`. QuestQuestionController searches QB. |
| **LmsQuiz** | SHARED MODELS | Quest model imports `AssessmentType` and `DifficultyDistributionConfig` from `Modules\LmsQuiz`. These shared masters are owned by LmsQuiz. |
| **SchoolSetup** | FK DEPENDENCY | `sch_classes`, `sch_sections`, `sch_subjects` |
| **Syllabus** | FK DEPENDENCY | `slb_lessons`, `slb_topics`, `slb_question_types`, `slb_complexity_level` |
| **StudentProfile** | FK DEPENDENCY | `std_students` in attempt tracking |
| **Prime (Academic)** | FK DEPENDENCY | `glb_academic_sessions` |

---

## 12. TEST CASE REFERENCE & COVERAGE

**Current test coverage: 0 tests**

### Proposed Test Plan

**Unit Tests:**
- `QuestCodeGeneratorTest` — format and uniqueness
- `QuestCanPublishTest` — all 4 canPublish() conditions
- `QuestDuplicateTest` — verify duplicate() creates independent copy with new code
- `NegativeMarkingTest` — score floor at 0

**Feature Tests:**
- `QuestCreationTest` — happy path, missing hierarchy, duplicate code
- `QuestScopeTest` — add multiple scopes, getTopics AJAX
- `QuestQuestionBulkStoreTest` — add questions, ordinal assignment, duplicate prevention
- `QuestAllocationTest` — CLASS/SECTION/GROUP/STUDENT allocation types, target resolution
- `QuestGateTest` — verify index() requires permission after fix
- `QuestPublishGuardTest` — attempt to publish before questions added → reject

---

## 13. GLOSSARY & TERMINOLOGY

| Term | Meaning |
|---|---|
| Quest | A multi-lesson formative assessment — broader scope than a Quiz |
| Scope | Definition of which lessons/topics are covered in a Quest |
| Allocation | Assignment of a Quest to a student population with timing |
| Assessment Type | Category of assessment (Challenge, Enrichment, Diagnostic, Remedial, etc.) |
| Difficulty Config | Percentage distribution of question difficulty levels (Easy/Medium/Hard) |
| Auto-publish Result | Setting that releases scores automatically at result_publish_date |
| Cut-off Date | Hard deadline after which no attempt can be started |
| Ordinal | Sequence number for question ordering within the quest |
| Marks Override | Per-question marks that override the default QB marks |

---

## 14. ADDITIONAL SUGGESTIONS

1. **Re-enable `Gate::authorize('tenant.quest.viewAny')`** in `LmsQuestController::index()` immediately.
2. **Add `EnsureTenantHasModule` middleware** to the `lms-quests` route group.
3. **Resolve lesson_id DDL mismatch:** Either add `lesson_id` to `lms_quests` DDL (and run migration), or remove it from the model/fillable and document that lesson scope is via `lms_quest_scopes` only.
4. **Add a `/publish` route** that calls `Quest::canPublish()` and `Quest::publish()` — currently teacher must use the edit form to change status which bypasses canPublish() validation.
5. **Build student attempt pipeline** — this is the highest-priority remaining work. The DDL infrastructure (`lms_quiz_quest_attempts`) is ready.
6. **Create shared `AttemptService`** for Quiz+Quest attempt logic to avoid duplication.
7. **Consider extracting shared models** (AssessmentType, DifficultyDistributionConfig) to a dedicated `LmsConfig` or `LmsMaster` module instead of importing from LmsQuiz.
8. **Add `lms_quiz_quest_attempts` Model** to the module (or in a shared location).

---

## 15. APPENDICES

### A. File Inventory
```
Modules/LmsQuests/
├── app/Http/Controllers/
│   ├── LmsQuestController.php         (tab hub + Quest CRUD, Gate disabled in index)
│   ├── QuestScopeController.php       (CRUD + getTopics AJAX)
│   ├── QuestAllocationController.php  (CRUD + getTargetOptions AJAX)
│   └── QuestQuestionController.php    (CRUD + 10 AJAX endpoints)
├── app/Models/
│   ├── Quest.php          (665 lines — rich model with canPublish, duplicate, etc.)
│   ├── QuestScope.php
│   ├── QuestQuestion.php
│   └── QuestAllocation.php
├── app/Http/Requests/ [4 FormRequests]
├── app/Policies/ [QuestPolicy, QuestAllocationPolicy, QuestQuestionPolicy, QuestScopePolicy]
├── resources/views/ [~21 blade files across 5 folders + tab module]
└── routes/web.php (minimal — main routes in tenant.php lines 669-722)
```

### B. Route Group Location
All functional routes for LmsQuests are defined in `/Users/bkwork/Herd/prime_ai/routes/tenant.php` lines 669–722 under the `lms-quests` prefix group.

### C. Known Bugs Summary
| Bug | Location | Severity |
|---|---|---|
| `Gate::authorize` commented out in index() | LmsQuestController line 35 | HIGH SECURITY |
| `lesson_id` in model fillable but not in DDL | Quest model vs lms_quests DDL | HIGH — data integrity |
| No student attempt controllers | Entire attempt pipeline | HIGH |
| `EnsureTenantHasModule` middleware missing | Route group | MEDIUM |
| No publish endpoint (bypasses canPublish guard) | No /publish route | MEDIUM |
| 0 tests | All controllers | HIGH |
