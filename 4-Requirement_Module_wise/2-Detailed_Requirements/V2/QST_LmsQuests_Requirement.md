# QST — LMS Quests
## Module Requirement Document V2
**Version:** 2.0 | **Date:** 2026-03-26 | **Status:** Draft | **Mode:** FULL

---

## 1. Executive Summary

LmsQuests is the multi-scope formative assessment and challenge engine of Prime-AI. A "Quest" is a longer-horizon, cross-lesson assessment distinct from a Quiz: where a Quiz is single-topic and short-duration, a Quest spans multiple lessons and topics simultaneously, allowing teachers to evaluate deeper, integrated understanding across a broader curriculum window.

**Implementation status: ~60% complete.**

The teacher-facing pipeline — quest creation, scope definition, question bank integration, and allocation management — is largely functional with 4 controllers, 4 models, 4 FormRequests, and 4 policies, plus ~22 Blade views. However, the module has two critical gaps that block production use:

1. **Security defect:** `Gate::authorize('tenant.quest.viewAny')` is commented out in `LmsQuestController::index()` — any authenticated user can list all quests without permission.
2. **Missing student-facing pipeline:** No attempt controller, no attempt model, no student UI. The `lms_quiz_quest_attempts` and `lms_quiz_quest_attempt_answers` tables exist in the DDL but no module code references them.

Additional gaps: no `EnsureTenantHasModule` middleware, no service layer (0 services), no publish-dedicated route (bypassing `canPublish()` guard), route ordering bugs causing 404s on AJAX endpoints, duplicate quest-code generation in both model boot and controller, and 0 tests.

**Total estimated remediation effort: 89–121 hours** (P0: 4–6 h, P1: 40–55 h, P2: 30–40 h, P3: 15–20 h).

**Stats (current):**
- Controllers: 4 | Models: 4 | Services: 0 | FormRequests: 4 | Policies: 4 | Tests: 0
- DDL tables owned: `lms_quests`, `lms_quest_scopes`, `lms_quest_questions`, `lms_quest_allocations`
- DDL tables shared: `lms_quiz_quest_attempts`, `lms_quiz_quest_attempt_answers`

---

## 2. Module Overview

### 2.1 Business Purpose

Enable teachers to design multi-lesson formative assessments ("Quests") that measure student understanding across an integrated curriculum window. Quests are used for challenge, enrichment, diagnostic, and remedial purposes. They draw questions from the Question Bank (QNS module), can be targeted at specific student groups via the allocation system, and eventually drive gamification via LXP rewards.

### 2.2 Key Features

| # | Feature | Status |
|---|---|---|
| 1 | Quest creation with academic hierarchy (session → class → subject → multi-lesson scope) | ✅ |
| 2 | Multi-lesson scope definition (which lessons/topics are covered per quest) | ✅ |
| 3 | Question assignment from QNS Question Bank with ordinal ordering and marks override | ✅ |
| 4 | Quest allocation to CLASS / SECTION / GROUP / STUDENT with timing windows | ✅ |
| 5 | Assessment type classification (Challenge, Enrichment, Practice, Revision, Diagnostic, Remedial, Re-Test) | ✅ |
| 6 | Difficulty distribution config integration | ✅ |
| 7 | Publish workflow with `canPublish()` validation guard | 🟡 Partial (no dedicated route) |
| 8 | Student quest-taking pipeline (start, answer, submit, auto-grade) | ❌ |
| 9 | Student progress tracking and result viewing | ❌ |
| 10 | Teacher monitoring dashboard (attempt analytics per quest) | ❌ |
| 11 | System-generated quests (auto-select questions by difficulty config) | ❌ |
| 12 | Timer enforcement (server-side + client-side countdown) | ❌ |
| 13 | Negative marking scoring logic | ❌ |
| 14 | Multiple attempts management (counting against max_attempts) | ❌ |
| 15 | LXP reward/badge integration on quest completion | 📐 Proposed |

### 2.3 Menu Path
`LMS > Quests`

### 2.4 Architecture

Tab-based single-page interface via `LmsQuestController::index()`. Uses shared master models `AssessmentType` and `DifficultyDistributionConfig` from `Modules\LmsQuiz`. Individual CRUD under `lms-quests.*` prefix in `routes/tenant.php` (lines 669–721).

The module targets the **tenant** scope — each school has its own isolated tenant database containing all `lms_quest*` tables.

---

## 3. Stakeholders & Roles

| Actor | Permissions | Notes |
|---|---|---|
| Teacher | Create, edit, publish, archive quests; manage scopes, questions, allocations; view attempt reports | Primary creator role |
| Admin (School) | All teacher permissions + force-delete, restore from trash | Manages assessment type/difficulty masters via LmsQuiz |
| Student | View allocated quests, start attempt, save answers, submit, view results | ABSENT — not yet implemented |
| Parent | View child's quest attempts and scores | ABSENT — not yet implemented |
| System | Auto-submit on timer expiry; auto-publish results at result_publish_date | Background job required |
| QuestionBank Module (QNS) | Source of all questions used in quests | Cross-module dependency |
| LmsQuiz Module (QUZ) | Owner of shared masters: AssessmentType, DifficultyDistributionConfig | Shared model dependency |

---

## 4. Functional Requirements

### FR-QST-01: Quest Creation
**Priority:** Critical | **Status:** ✅ Implemented (with security bug)
**Tables:** `lms_quests`
**RBS Reference:** S3.1

**Description:** Teacher creates a quest with full academic hierarchy, assessment type, difficulty config, grading settings, timer, randomisation, attempt policies, and result display options.

**Input Fields:**
- `quest_code` — auto-generated: `QUEST_{session_code}_{class_code}_{subject_code}_{random6}`; UNIQUE globally
- `title` (VARCHAR 255, required)
- `description`, `instructions` (TEXT, optional)
- `academic_session_id`, `class_id`, `subject_id` — academic hierarchy (all required)
- `quest_type_id` — FK to `lms_assessment_types` (Challenge/Enrichment/Practice/Revision/Diagnostic/Remedial/Re-Test)
- `difficulty_config_id` — FK to `lms_difficulty_distribution_configs` (optional)
- `ignore_difficulty_config` — override flag (TINYINT)
- `duration_minutes` — NULL = unlimited
- `total_marks` DECIMAL(8,2), `total_questions` INT
- `passing_percentage` DECIMAL(5,2) DEFAULT 33.00
- `allow_multiple_attempts` (TINYINT), `max_attempts` (TINYINT UNSIGNED DEFAULT 1)
- `negative_marks` DECIMAL(4,2) DEFAULT 0.00
- `is_randomized`, `question_marks_shown`, `auto_publish_result`, `timer_enforced`, `show_correct_answer`, `show_explanation` — TINYINT flags
- `only_unused_questions`, `only_authorised_questions` — question filter flags
- `is_system_generated` — flag for auto-generation mode

**Processing:**
- UUID generated via `Quest::boot()` on creating event
- Quest code generated via `Quest::generateQuestCode()` in boot (loop-checks uniqueness)
- `status` defaults to `DRAFT`
- `created_by` set to `auth()->id()`

**Known Bug — SECURITY (P0):**
```
LmsQuestController::index() line 35:
// Gate::authorize('tenant.quest.viewAny');   ← COMMENTED OUT
```
Any authenticated user can list all quests. Must be uncommented before production.

**Known Bug — DRY (P1):**
`store()` in controller also calls `AcademicSession::find()`, `SchoolClass::find()`, `Subject::find()`, `Lesson::find()` to build a quest code — duplicating the model boot logic. The controller code takes precedence and may overwrite the model-generated code.

**Acceptance Criteria:**
- `quest_code` must be globally unique (DB UNIQUE constraint `uq_quest_code`)
- Academic hierarchy (session + class + subject) must be fully populated
- `total_questions` must match actual assigned question count before publishing
- `Gate::authorize('tenant.quest.viewAny')` must be active in `index()`

---

### FR-QST-02: Quest Scope Definition
**Priority:** High | **Status:** ✅ Implemented
**Tables:** `lms_quest_scopes`
**RBS Reference:** S3.1 (Quiz Settings)

**Description:** Defines the curriculum coverage of a quest. A quest can span multiple lessons and topics simultaneously. Each scope record maps one (lesson + topic) pair to the quest, with an optional question-type filter and target question count.

**Note on DDL Mismatch:** The `lms_quests` DDL has **no `lesson_id` column**, but `Quest.php` model has `lesson_id` in `$fillable` and controller code uses `Lesson::find($request->lesson_id)` for code generation. Lesson coverage is architecturally intended to be managed via `lms_quest_scopes`. The `lesson_id` field in the Quest model/fillable is an error and must be removed.

**Input Fields:**
- `quest_id` — FK to `lms_quests` (CASCADE)
- `lesson_id` — FK to `slb_lessons` (required)
- `topic_id` — FK to `slb_topics` (required)
- `question_type_id` — FK to `qns_question_types` (optional filter)
- `target_question_count` — 0 = include all questions from this topic

**AJAX Support:**
- `GET /lms-quests/quest-scope/get-topics` — returns topics for a selected lesson (cascade dropdown)

**Route Ordering Bug (P0):** The `get-topics` GET route is defined AFTER the `quest-scope/{quest_scope}` resource route in `tenant.php:686`. Laravel will attempt to resolve `get-topics` as a `quest_scope` model ID and throw 404. The AJAX route must be declared before the resource route.

**Acceptance Criteria:**
- One quest can have multiple scope records (different lesson+topic pairs)
- `get-topics` AJAX endpoint must be reachable (route order fix required)
- `target_question_count = 0` means no limit (include all matching questions)

---

### FR-QST-03: Quest Question Assignment
**Priority:** Critical | **Status:** ✅ Implemented (rich AJAX interface)
**Tables:** `lms_quest_questions`
**RBS Reference:** S3.1 / S4

**Description:** Links questions from the QNS Question Bank to a Quest with ordinal ordering and per-question marks override. Supports bulk add/remove and drag-and-drop reorder.

**Input Fields:**
- `quest_id` — FK to `lms_quests`
- `question_id` — FK to `qns_questions_bank`
- `ordinal` — display/answer sequence (INT UNSIGNED)
- `marks_override` — when NULL, uses question's default marks from QB

**AJAX Endpoints (all under `lms-quests.*` prefix):**

| Endpoint | Method | Purpose |
|---|---|---|
| `get-sections` | GET | Sections for a class (cascade) |
| `get-subject-groups` | GET | Subject groups |
| `get-subjects` | GET | Subjects for class/section |
| `get-lessons` | GET | Lessons for a subject |
| `get-topics` | GET | Topics for a lesson |
| `search` | GET | Search QNS Question Bank with filters |
| `existing` | GET | List already-assigned questions for a quest |
| `bulk-store` | POST | Add multiple questions at once |
| `bulk-destroy` | POST | Remove multiple questions |
| `update-ordinal` | POST | Drag-and-drop reorder |
| `update-marks` | POST | Inline marks override |
| `quest-meta` | GET | Quest metadata (for question form context) |

**Acceptance Criteria:**
- UNIQUE(quest_id, question_id) constraint prevents duplicate assignment (DB + application level)
- Ordinal must stay consistent after bulk reorder
- `marks_override = NULL` means fall back to QB default marks
- AJAX endpoints must have authorization checks (currently unverified — GAP-POL-003)

---

### FR-QST-04: Quest Allocation
**Priority:** Critical | **Status:** ✅ Implemented
**Tables:** `lms_quest_allocations`
**RBS Reference:** S3.1.2

**Description:** Assigns a published quest to a target audience (CLASS / SECTION / GROUP / STUDENT) with a publication window, due date, cut-off date, and result release date.

**Input Fields:**
- `quest_id` — FK to `lms_quests`
- `allocation_type` — ENUM('CLASS','SECTION','GROUP','STUDENT')
- `target_table_name` — e.g. `sch_classes`, `sch_sections`, `sch_entity_groups`, `std_students`
- `target_id` — polymorphic ID; app-level FK only (no DB FK due to polymorphism)
- `assigned_by` — FK to `sys_users` (NULL = system-assigned)
- `published_at` — datetime when quest becomes visible to students
- `due_date` — recommended completion deadline
- `cut_off_date` — hard deadline; no new attempts after this
- `is_auto_publish_result` — auto-release results at `result_publish_date`
- `result_publish_date` — when scores become visible to students

**AJAX Support:**
- `GET /lms-quests/quest-allocation/get-target-options` — returns target list based on allocation_type

**Route Ordering Bug (P0):** Same as FR-QST-02 — `get-target-options` is defined after the resource route in `tenant.php:695`.

**Acceptance Criteria:**
- Quest must be in PUBLISHED status before allocation is created
- `cut_off_date` must be >= `due_date` if both are set
- `result_publish_date` must be >= `cut_off_date`
- `get-target-options` AJAX route must be reachable (route order fix required)

---

### FR-QST-05: Quest Publish Workflow
**Priority:** High | **Status:** 🟡 Partial
**Tables:** `lms_quests`
**RBS Reference:** S3

**Description:** Quest transitions from DRAFT to PUBLISHED only when all readiness conditions are met. Currently, the `Quest` model has `canPublish()` and `publish()` methods, but there is no dedicated publish route — teachers must use the generic edit form to change status, which can bypass the `canPublish()` guard.

**Existing Model Methods:**
- `Quest::canPublish()` — validates: total_questions > 0, actual assigned question count matches `total_questions`, academic hierarchy complete, settings valid
- `Quest::publish()` — sets `status = PUBLISHED`, `published_at = now()`
- `Quest::archive()` — sets `status = ARCHIVED`, `is_active = false`

**Gap:** No `POST /lms-quests/quest/{id}/publish` route exists. Status can be changed via the update form, bypassing the canPublish() guard.

**Proposed New Route:**
- `POST /lms-quests/quest/{id}/publish` → `LmsQuestController::publish()` — calls `canPublish()`, returns validation errors if not ready, else calls `publish()`
- `POST /lms-quests/quest/{id}/archive` → `LmsQuestController::archive()`

**Acceptance Criteria:**
- canPublish() must pass before status transitions to PUBLISHED
- Publish endpoint must return structured errors if guard fails (e.g., "questions count mismatch: 10 configured, 7 assigned")
- Archive sets `is_active = false`

---

### FR-QST-06: Student Quest-Taking Pipeline
**Priority:** Critical | **Status:** ❌ Not Started
**Tables:** `lms_quiz_quest_attempts`, `lms_quiz_quest_attempt_answers`
**RBS Reference:** S3.1 / S5

**Description:** Student views their allocated quests (filtered by `published_at <= now() <= cut_off_date`), starts a timed attempt, answers questions one-by-one or all at once, saves progress incrementally, and submits. MCQ answers are auto-graded. Descriptive answers are flagged for teacher review.

**Required New Components:**
- `StudentQuestAttemptController` with methods:
  - `myQuests()` — list of active allocated quests for the logged-in student
  - `startAttempt(QuestAllocation $allocation)` — creates `lms_quiz_quest_attempts` record (status=IN_PROGRESS); validates: quest is PUBLISHED, within timing window, max_attempts not exceeded
  - `saveAnswer(Attempt $attempt)` — upserts `lms_quiz_quest_attempt_answers`; auto-saves every 30 seconds via AJAX
  - `submitAttempt(Attempt $attempt)` — finalises attempt (status=SUBMITTED); triggers auto-grading for MCQ questions
  - `autoTimeout(Attempt $attempt)` — sets status=TIMEOUT; triggered by server-side check or scheduled job
  - `viewResult(Attempt $attempt)` — shows scored attempt; only accessible after `result_publish_date` or if `is_auto_publish_result = 1`
  - `teacherGrade(Attempt $attempt)` — teacher submits score and feedback for descriptive answers

**Attempt Model (new):** `Modules\LmsQuests\Models\QuestAttempt` (wraps `lms_quiz_quest_attempts` with `assessment_type = QUEST`)

**Auto-Grading Logic:**
- MCQ/True-False: `marks_obtained = marks_override ?? QB default marks` if `is_correct = 1`
- Negative marking: deduct `negative_marks` factor from marks if wrong (minimum 0)
- Descriptive: `marks_obtained = NULL`, `is_correct = NULL` — requires teacher evaluation
- `total_score` = sum of `marks_obtained` across all answers
- `percentage` = (total_score / quest.total_marks) * 100
- `is_passed` = percentage >= quest.passing_percentage

**Acceptance Criteria:**
- Attempt can only start within [published_at, cut_off_date] window
- Each student limited to `max_attempts` attempts per allocation
- Timer: when `timer_enforced = 1` and `duration_minutes` set, auto-submit on expiry
- Answer saved incrementally (AJAX save-answer endpoint); no data loss on disconnect
- Result only visible after `result_publish_date` or `auto_publish_result = 1`
- MCQ scoring with negative marking: minimum question score = 0 (no negative total)

---

### FR-QST-07: Teacher Monitoring Dashboard
**Priority:** High | **Status:** ❌ Not Started
**Tables:** `lms_quiz_quest_attempts`, `lms_quest_allocations`
**RBS Reference:** S3.1.3

**Description:** Teacher views attempt statistics per quest allocation: submitted count, pending count, average score, pass/fail rate, per-student attempt status, and ability to provide feedback on descriptive answers.

**Required New Components:**
- `QuestMonitorController` with:
  - `dashboard(Quest $quest)` — aggregate stats for all allocations of a quest
  - `allocationDetail(QuestAllocation $allocation)` — per-student attempt list
  - `gradeAttempt(Attempt $attempt)` — submit teacher score + feedback for descriptive answers

**Views needed:**
- `quest-monitor/dashboard.blade.php` — quest-level stats summary
- `quest-monitor/allocation-detail.blade.php` — per-student attempt status table

---

### FR-QST-08: System-Generated Quests
**Priority:** Medium | **Status:** ❌ Not Started
**Tables:** `lms_quests`, `lms_quest_questions`, `lms_difficulty_distribution_configs`
**RBS Reference:** S3.1 (AI Generation)

**Description:** When `is_system_generated = 1`, the system automatically selects questions from the QB based on the difficulty distribution config, applying filters for `only_unused_questions` and `only_authorised_questions`.

**Required New Component:** `QuestGenerationService`
- `generateQuestions(Quest $quest)` — queries `qns_questions_bank` filtered by quest scope (lessons/topics), applies difficulty distribution percentages from `lms_difficulty_distribution_configs`, respects `only_unused_questions` and `only_authorised_questions` flags, bulk-inserts into `lms_quest_questions`

**Acceptance Criteria:**
- Distribution percentages from config must sum to 100%
- If insufficient questions exist for a difficulty tier, warn teacher with remaining count
- Generated questions must honour the UNIQUE(quest_id, question_id) constraint

---

### FR-QST-09: Quest Duplication
**Priority:** Medium | **Status:** ✅ Implemented (via model method)
**Tables:** `lms_quests`, `lms_quest_scopes`, `lms_quest_questions`
**RBS Reference:** S3.1

**Description:** Teacher duplicates an existing quest, creating an independent copy with a new `quest_code`, `DRAFT` status, and cloned scopes and questions.

**Existing Model Method:** `Quest::duplicate()` — creates copy with new UUID, new quest_code, DRAFT status.

**Gap:** No dedicated route or controller action calls `duplicate()`. Must be exposed via a controller action and route.

**Proposed Route:** `POST /lms-quests/quest/{id}/duplicate` → `LmsQuestController::duplicate()`

---

### FR-QST-10: Security Hardening
**Priority:** Critical | **Status:** ❌ Multiple Issues
**RBS Reference:** Cross-cutting

**Description:** Multiple security and middleware gaps that must be resolved before production.

**Required Fixes:**

| ID | Fix | Location | Severity |
|---|---|---|---|
| SEC-QST-001 | Uncomment `Gate::authorize('tenant.quest.viewAny')` | `LmsQuestController.php:35` | CRITICAL |
| SEC-QST-002 | Add `EnsureTenantHasModule` middleware to `lms-quests` route group | `tenant.php:669` | HIGH |
| SEC-QST-003 | Replace `$request->all()` with `$request->validated()` in activity log calls | `QuestScopeController.php:107,181,363`; `QuestAllocationController.php:178,282,469` | MEDIUM |
| SEC-QST-004 | Move AJAX GET routes before resource routes (route ordering fix) | `tenant.php:686,695` | HIGH |
| SEC-QST-005 | Add authorization checks on AJAX endpoints (`getSections`, `getSubjects`, etc.) | `QuestQuestionController` | MEDIUM |
| SEC-QST-006 | Add rate limiting to AJAX search and bulk-store endpoints | `tenant.php:706–717` | LOW |

---

## 5. Data Model

### 5.1 lms_quests
*Primary table. DDL source: `tenant_db_v2.sql` line 7030*

| Column | Type | Constraint | Notes |
|---|---|---|---|
| id | INT UNSIGNED | PK AUTO_INCREMENT | |
| uuid | BINARY(16) | UNIQUE NOT NULL | Generated in model boot |
| academic_session_id | INT UNSIGNED | FK glb_academic_sessions CASCADE | |
| class_id | INT UNSIGNED | FK sch_classes CASCADE | |
| subject_id | INT UNSIGNED | FK sch_subjects CASCADE | |
| quest_type_id | INT UNSIGNED | FK lms_assessment_types CASCADE | |
| quest_code | VARCHAR(50) | UNIQUE NOT NULL | Auto-generated |
| title | VARCHAR(255) | NOT NULL | |
| description | TEXT | NULL | |
| instructions | TEXT | NULL | |
| status | VARCHAR(20) | DEFAULT 'DRAFT' | DRAFT / PUBLISHED / ARCHIVED |
| duration_minutes | INT UNSIGNED | NULL | NULL = unlimited |
| total_marks | DECIMAL(8,2) | DEFAULT 0.00 | |
| total_questions | INT UNSIGNED | DEFAULT 0 | Must match actual assigned count before publish |
| passing_percentage | DECIMAL(5,2) | DEFAULT 33.00 | |
| allow_multiple_attempts | TINYINT(1) | DEFAULT 0 | |
| max_attempts | TINYINT UNSIGNED | DEFAULT 1 | |
| negative_marks | DECIMAL(4,2) | DEFAULT 0.00 | 0 = no negative marking |
| is_randomized | TINYINT(1) | DEFAULT 0 | Randomise question order per student |
| question_marks_shown | TINYINT(1) | DEFAULT 0 | Show marks during attempt |
| auto_publish_result | TINYINT(1) | DEFAULT 0 | Release results at result_publish_date |
| timer_enforced | TINYINT(1) | DEFAULT 1 | Enforce countdown timer |
| show_correct_answer | TINYINT(1) | DEFAULT 0 | Show correct answer post-submission |
| show_explanation | TINYINT(1) | DEFAULT 0 | Show answer explanation post-submission |
| difficulty_config_id | INT UNSIGNED | FK lms_difficulty_distribution_configs NULL | |
| ignore_difficulty_config | TINYINT(1) | DEFAULT 0 | |
| is_system_generated | TINYINT(1) | DEFAULT 0 | Auto-generated by system |
| only_unused_questions | TINYINT(1) | DEFAULT 0 | Filter: exclude questions in usage log |
| only_authorised_questions | TINYINT(1) | DEFAULT 0 | Filter: `qns_questions_bank.for_quiz = 1` |
| created_by | INT UNSIGNED | FK sys_users NULL ON DELETE SET NULL | |
| is_active | TINYINT(1) | DEFAULT 1 | |
| created_at, updated_at, deleted_at | TIMESTAMP | Standard soft-delete | |

**DDL Mismatch:** The Quest model has `lesson_id` in `$fillable` but `lms_quests` DDL has NO `lesson_id` column. Lesson coverage is managed via `lms_quest_scopes`. The `lesson_id` field must be removed from the model's `$fillable` and the controller's code-generation logic.

### 5.2 lms_quest_scopes
*DDL source: `tenant_db_v2.sql` line 7083*

| Column | Type | Constraint | Notes |
|---|---|---|---|
| id | INT UNSIGNED | PK | |
| quest_id | INT UNSIGNED | FK lms_quests CASCADE | |
| lesson_id | INT UNSIGNED | FK slb_lessons CASCADE | |
| topic_id | INT UNSIGNED | FK slb_topics CASCADE | |
| question_type_id | INT UNSIGNED | FK qns_question_types NULL | Optional type filter |
| target_question_count | INT UNSIGNED | DEFAULT 0 | 0 = no limit |
| is_active, created_at, updated_at, deleted_at | — | Standard | |

### 5.3 lms_quest_questions
*DDL source: `tenant_db_v2.sql` line 7104*

| Column | Type | Constraint | Notes |
|---|---|---|---|
| id | INT UNSIGNED | PK | |
| quest_id | INT UNSIGNED | FK lms_quests CASCADE | |
| question_id | INT UNSIGNED | FK qns_questions_bank CASCADE | |
| ordinal | INT UNSIGNED | DEFAULT 0 | Display order |
| marks_override | DECIMAL(5,2) | NULL | NULL = use QB default |
| is_active, created_at, updated_at, deleted_at | — | Standard | |
| **UNIQUE** | (quest_id, question_id) | uq_quest_ques | |

### 5.4 lms_quest_allocations
*DDL source: `tenant_db_v2.sql` line 7124*

| Column | Type | Constraint | Notes |
|---|---|---|---|
| id | INT UNSIGNED | PK | |
| quest_id | INT UNSIGNED | FK lms_quests CASCADE | |
| allocation_type | ENUM | ('CLASS','SECTION','GROUP','STUDENT') | |
| target_table_name | VARCHAR(60) | NOT NULL | sch_classes / sch_sections / sch_entity_groups / std_students |
| target_id | INT UNSIGNED | App-level FK only | Polymorphic |
| assigned_by | INT UNSIGNED | FK sys_users NULL ON DELETE SET NULL | |
| published_at | DATETIME | NULL | Visibility start |
| due_date | DATETIME | NULL | Soft deadline |
| cut_off_date | DATETIME | NULL | Hard deadline |
| is_auto_publish_result | TINYINT(1) | DEFAULT 0 | |
| result_publish_date | DATETIME | NULL | |
| is_active, created_at, updated_at, deleted_at | — | Standard | |
| INDEX | (allocation_type, target_id) | idx_quest_alloc_target | |

### 5.5 lms_quiz_quest_attempts (SHARED with LmsQuiz)
*DDL source: `tenant_db_v2.sql` line 7453*

| Column | Type | Constraint | Notes |
|---|---|---|---|
| id | INT UNSIGNED | PK | |
| student_id | INT UNSIGNED | FK std_students (key idx_att_student) | |
| assessment_type | ENUM | ('QUIZ','QUEST') | Discriminator |
| assessment_id | INT UNSIGNED | App-level FK | lms_quizzes.id or lms_quests.id |
| allocation_id | INT UNSIGNED | App-level FK NULL | Corresponding allocation record |
| attempt_number | TINYINT UNSIGNED | DEFAULT 1 | Increments per attempt |
| started_at | DATETIME | DEFAULT CURRENT_TIMESTAMP | |
| completed_at | DATETIME | NULL | |
| status | ENUM | NOT_STARTED / IN_PROGRESS / SUBMITTED / TIMEOUT / ABANDONED / CANCELLED / REASSIGNED | |
| total_score | DECIMAL(8,2) | NULL | Computed after submit |
| percentage | DECIMAL(5,2) | NULL | (total_score / total_marks) * 100 |
| is_passed | TINYINT(1) | DEFAULT 0 | |
| teacher_feedback | TEXT | NULL | For descriptive answer grading |
| is_active, created_at, updated_at, deleted_at | — | Standard | |

### 5.6 lms_quiz_quest_attempt_answers (SHARED with LmsQuiz)
*DDL source: `tenant_db_v2.sql` line 7481*

| Column | Type | Constraint | Notes |
|---|---|---|---|
| id | INT UNSIGNED | PK | |
| attempt_id | INT UNSIGNED | FK lms_quiz_quest_attempts CASCADE | |
| question_id | INT UNSIGNED | FK qns_questions_bank RESTRICT | |
| selected_option_id | INT UNSIGNED | FK qns_question_options NULL ON DELETE SET NULL | For MCQ |
| answer_text | TEXT | NULL | For Descriptive / Fill-in-the-blank |
| marks_obtained | DECIMAL(5,2) | DEFAULT 0.00 | |
| is_correct | TINYINT(1) | NULL | NULL = not graded; 0 = wrong; 1 = correct |
| time_taken_seconds | INT UNSIGNED | DEFAULT 0 | Per-question telemetry |
| is_active, created_at, updated_at, deleted_at | — | Standard | |

---

## 6. API Endpoints & Routes

**Route Group:** `routes/tenant.php` lines 669–721
**URL Prefix:** `/lms-quests`
**Name Prefix:** `lms-quests.`
**Middleware:** `auth`, `verified` — NOTE: `EnsureTenantHasModule` is MISSING (SEC-QST-002)

### 6.1 Quest CRUD (LmsQuestController)

| Method | URI | Route Name | Action | Status |
|---|---|---|---|---|
| GET | /lms-quests/quest | quest.index | Tab hub view (GATE DISABLED) | ✅ Bug |
| GET | /lms-quests/quest/create | quest.create | Create form | ✅ |
| POST | /lms-quests/quest | quest.store | Store new quest | ✅ |
| GET | /lms-quests/quest/{id} | quest.show | Show detail | ✅ |
| GET | /lms-quests/quest/{id}/edit | quest.edit | Edit form | ✅ |
| PUT | /lms-quests/quest/{id} | quest.update | Update quest | ✅ |
| DELETE | /lms-quests/quest/{id} | quest.destroy | Soft delete + ARCHIVED | ✅ |
| GET | /lms-quests/quest/trash/view | quest.trashed | Trash list | ✅ |
| GET | /lms-quests/quest/{id}/restore | quest.restore | Restore | ✅ |
| DELETE | /lms-quests/quest/{id}/force-delete | quest.forceDelete | Force delete | ✅ |
| POST | /lms-quests/quest/{id}/toggle-status | quest.toggleStatus | Toggle active | ✅ |
| POST | /lms-quests/quest/{id}/publish | quest.publish | Publish (canPublish guard) | 📐 Proposed |
| POST | /lms-quests/quest/{id}/archive | quest.archive | Archive | 📐 Proposed |
| POST | /lms-quests/quest/{id}/duplicate | quest.duplicate | Duplicate quest | 📐 Proposed |

### 6.2 Quest Scope (QuestScopeController)

| Method | URI | Route Name | Action | Status |
|---|---|---|---|---|
| GET | /lms-quests/quest-scope/get-topics | quest-scope.getTopics | AJAX: topics for lesson | ✅ Bug (route order) |
| (resource) | /lms-quests/quest-scope | quest-scope.* | Full CRUD | ✅ |
| +trash/restore/force-delete | — | quest-scope.* | Standard extras | ✅ |

### 6.3 Quest Allocation (QuestAllocationController)

| Method | URI | Route Name | Action | Status |
|---|---|---|---|---|
| GET | /lms-quests/quest-allocation/get-target-options | quest-allocation.getTargetOptions | AJAX: targets by type | ✅ Bug (route order) |
| (resource) | /lms-quests/quest-allocation | quest-allocation.* | Full CRUD | ✅ |
| +trash/restore/force-delete | — | quest-allocation.* | Standard extras | ✅ |

### 6.4 Quest Questions — AJAX (QuestQuestionController)

| Method | URI | Route Name | Action | Status |
|---|---|---|---|---|
| (resource) | /lms-quests/quest-question | quest-question.* | Full CRUD | ✅ |
| GET | /lms-quests/get-sections | get-sections | Cascade: sections for class | ✅ |
| GET | /lms-quests/get-subject-groups | get-subject-groups | Subject groups | ✅ |
| GET | /lms-quests/get-subjects | get-subjects | Subjects for class/section | ✅ |
| GET | /lms-quests/get-lessons | get-lessons | Lessons for subject | ✅ |
| GET | /lms-quests/get-topics | get-topics | Topics for lesson | ✅ |
| GET | /lms-quests/search | search | QB search with filters | ✅ |
| GET | /lms-quests/existing | existing | Already-assigned questions | ✅ |
| POST | /lms-quests/bulk-store | bulk-store | Bulk add questions | ✅ |
| POST | /lms-quests/bulk-destroy | bulk-destroy | Bulk remove questions | ✅ |
| POST | /lms-quests/update-ordinal | update-ordinal | Drag-and-drop reorder | ✅ |
| POST | /lms-quests/update-marks | update-marks | Inline marks override | ✅ |
| GET | /lms-quests/quest-meta | quest-meta | Quest metadata for form | ✅ |

### 6.5 Student Attempt Routes (Proposed New)

| Method | URI | Route Name | Action | Status |
|---|---|---|---|---|
| GET | /lms-quests/my-quests | student.myQuests | Student's allocated quest list | 📐 |
| POST | /lms-quests/allocation/{allocation}/start | student.startAttempt | Start attempt | 📐 |
| POST | /lms-quests/attempt/{attempt}/save-answer | student.saveAnswer | AJAX auto-save answer | 📐 |
| POST | /lms-quests/attempt/{attempt}/submit | student.submitAttempt | Submit attempt | 📐 |
| GET | /lms-quests/attempt/{attempt}/result | student.viewResult | View scored result | 📐 |
| POST | /lms-quests/attempt/{attempt}/grade | teacher.gradeAttempt | Teacher grades descriptive | 📐 |
| GET | /lms-quests/quest/{quest}/monitor | teacher.monitor | Teacher monitoring dashboard | 📐 |

---

## 7. UI Screens

### 7.1 Existing Screens

| Screen | View File | Purpose | Status |
|---|---|---|---|
| Module Landing | `index.blade.php` | Module entry point | ✅ |
| Quest Hub (tabs) | `tab_module/tab.blade.php` | Tabbed container: quests / scopes / questions / allocations | ✅ |
| Quest List | `quest/index.blade.php` | Filter by status, type, date range | ✅ |
| Quest Create | `quest/create.blade.php` | Full creation form | ✅ |
| Quest Edit | `quest/edit.blade.php` | Update form | ✅ |
| Quest Show | `quest/show.blade.php` | Detail + question list | ✅ |
| Quest Trash | `quest/trash.blade.php` | Soft-deleted quests | ✅ |
| Quest Scope List | `quest-scope/index.blade.php` | Scopes per quest | ✅ |
| Quest Scope Create | `quest-scope/create.blade.php` | Lesson/topic/type/count form | ✅ |
| Quest Scope Edit | `quest-scope/edit.blade.php` | Edit scope | ✅ |
| Quest Scope Show | `quest-scope/show.blade.php` | Scope detail | ✅ |
| Quest Scope Trash | `quest-scope/trash.blade.php` | Trash | ✅ |
| Quest Question List | `quest-question/index.blade.php` | Questions with ordinal, marks | ✅ |
| Quest Question Create | `quest-question/create.blade.php` | QB search + bulk-add | ✅ |
| Quest Question Edit | `quest-question/edit.blade.php` | Edit ordinal/marks | ✅ |
| Quest Question Show | `quest-question/show.blade.php` | Question detail | ✅ |
| Quest Question Trash | `quest-question/trash.blade.php` | Trash | ✅ |
| Quest Allocation List | `quest-allocation/index.blade.php` | Allocations per quest | ✅ |
| Quest Allocation Create | `quest-allocation/create.blade.php` | Type/target/dates | ✅ |
| Quest Allocation Edit | `quest-allocation/edit.blade.php` | Edit allocation | ✅ |
| Quest Allocation Show | `quest-allocation/show.blade.php` | Allocation detail | ✅ |
| Quest Allocation Trash | `quest-allocation/trash.blade.php` | Trash | ✅ |

### 7.2 Required New Screens (Proposed)

| Screen | View File | Purpose | Status |
|---|---|---|---|
| My Quests (Student) | `student/my-quests.blade.php` | Student's quest list with status and deadlines | 📐 |
| Quest Attempt Interface | `student/attempt.blade.php` | Timer + question display + answer input | 📐 |
| Quest Result | `student/result.blade.php` | Score, percentage, pass/fail, answer review | 📐 |
| Quest Monitor Dashboard | `quest-monitor/dashboard.blade.php` | Teacher: aggregate stats per quest | 📐 |
| Allocation Detail Monitor | `quest-monitor/allocation-detail.blade.php` | Per-student attempt status table | 📐 |
| Grade Descriptive | `quest-monitor/grade-attempt.blade.php` | Teacher submits feedback and score | 📐 |

---

## 8. Business Rules

| # | Rule | Enforcement |
|---|---|---|
| BR-QST-01 | `quest_code` must be globally unique across all quests | DB UNIQUE constraint + model loop-check |
| BR-QST-02 | Quest cannot be PUBLISHED unless: total_questions > 0 AND assigned question count matches total_questions AND academic hierarchy is complete | `Quest::canPublish()` — must be called from dedicated publish route |
| BR-QST-03 | Multiple attempts: when `allow_multiple_attempts = 0`, `max_attempts` must equal 1 | Application validation |
| BR-QST-04 | Once `cut_off_date` is past, no new attempt can be started even if `max_attempts` not reached | `startAttempt()` controller check |
| BR-QST-05 | `result_publish_date` must be >= `cut_off_date`; `cut_off_date` must be >= `due_date` | Form validation |
| BR-QST-06 | Negative marking: minimum score per question is 0 (no negative total carry-over between questions) | Auto-grading service |
| BR-QST-07 | UNIQUE(quest_id, question_id) — same question cannot be added twice to a quest | DB constraint + bulkStore application check |
| BR-QST-08 | Student can only start attempt if allocation `published_at <= now() <= cut_off_date` | `startAttempt()` controller |
| BR-QST-09 | If `is_randomized = 1`, question order and MCQ option order must be shuffled uniquely per attempt | Shuffle seed stored per attempt |
| BR-QST-10 | Result is only visible after `result_publish_date` OR if `is_auto_publish_result = 1` | `viewResult()` access check |
| BR-QST-11 | When `only_unused_questions = 1`, questions present in `qns_question_usage_log` are excluded | QuestGenerationService filter |
| BR-QST-12 | When `only_authorised_questions = 1`, only questions with `qns_questions_bank.for_quiz = 1` are included | QuestGenerationService filter |
| BR-QST-13 | Difficulty distribution percentages must sum to 100% for a config to be valid | DifficultyDistributionConfig validation |
| BR-QST-14 | Quest with `is_system_generated = 1` auto-selects questions at publish time if quest has no manually assigned questions | QuestGenerationService trigger |
| BR-QST-15 | Teacher can only grade descriptive answers after attempt status = SUBMITTED | `gradeAttempt()` guard |

---

## 9. Workflows

### 9.1 Quest Lifecycle FSM

```
[Teacher Creates Quest]
     ↓ status = DRAFT
[Define Multi-Lesson Scopes] → lms_quest_scopes
     ↓
[Assign Questions from QB] → lms_quest_questions
     ↓
[canPublish() validation]
     ├── FAIL: errors returned (missing questions, hierarchy incomplete)
     └── PASS
          ↓
     [POST /publish] → status = PUBLISHED, published_at = now()
          ↓
[Create Allocations] → lms_quest_allocations
  (with published_at, due_date, cut_off_date, result_publish_date)
          ↓
[Clock: published_at reached] → Quest visible to target students
          ↓
[Student Starts Attempt] → lms_quiz_quest_attempts (status=IN_PROGRESS)
     ├── Timer running (if timer_enforced=1 and duration_minutes set)
     ├── AJAX auto-save answers every 30s → lms_quiz_quest_attempt_answers
     └── Submit / Timeout / Abandon
          ↓
[Auto-grade MCQ answers] → marks_obtained, is_correct
[Flag Descriptive] → is_correct = NULL (pending teacher review)
          ↓
[Compute total_score, percentage, is_passed]
          ↓
[Clock: result_publish_date] OR [auto_publish_result=1 on submission]
     → Status: result visible to student
          ↓
[Teacher grading complete] → teacher_feedback, marks_obtained set
          ↓
[Quest ARCHIVED] (manual or scheduled)
```

### 9.2 Attempt Status Transitions

```
NOT_STARTED → IN_PROGRESS  (student starts attempt)
IN_PROGRESS → SUBMITTED    (student submits)
IN_PROGRESS → TIMEOUT      (timer expires — server-side auto-submit)
IN_PROGRESS → ABANDONED    (student leaves without submitting)
IN_PROGRESS → CANCELLED    (admin/teacher cancels active attempt)
SUBMITTED   → REASSIGNED   (admin allows re-attempt — increments attempt_number)
```

### 9.3 Quest Code Generation

```
QUEST_{session_code}_{class_code}_{subject_code}_{random6}

Example: QUEST_2025-26_9TH_SCI_A3F7K2

Uniqueness check: while (Quest::where('quest_code', $code)->exists()) { regenerate }
Issue: Duplicate generation in both Quest::boot() and LmsQuestController::store()
Fix: Remove generation from controller; rely solely on model boot
```

---

## 10. Non-Functional Requirements

| ID | Category | Requirement | Target |
|---|---|---|---|
| NFR-QST-01 | Scalability | Concurrent quest attempts | 500+ students simultaneously |
| NFR-QST-02 | Reliability | Auto-submit on timer expiry | Within 5 seconds of timer = 0 (server-side job) |
| NFR-QST-03 | Data Integrity | Answer auto-save | AJAX upsert every 30 seconds; no data loss on disconnect |
| NFR-QST-04 | Security | Gate authorization | Re-enable `tenant.quest.viewAny` in index() |
| NFR-QST-05 | Security | Module middleware | `EnsureTenantHasModule` on route group |
| NFR-QST-06 | Security | Logging | Use `$request->validated()` not `$request->all()` in activity logs |
| NFR-QST-07 | Maintainability | DRY — quest code | Generate in model boot only; remove from controller |
| NFR-QST-08 | Auditability | CUD logging | All create/update/delete operations logged via `activityLog()` |
| NFR-QST-09 | Performance | Index queries | Paginate quest index; eager-load relationships to prevent N+1 |
| NFR-QST-10 | Performance | Accessor caching | `getStatisticsAttribute()` and `getSummaryAttribute()` run 2–3 queries per access; cache or refactor |
| NFR-QST-11 | Testability | Coverage target | Minimum 60% feature test coverage after P1 implementation |
| NFR-QST-12 | Correctness | Randomisation | Question order + option order shuffled uniquely per student per attempt |

---

## 11. Dependencies

### 11.1 Internal Module Dependencies

| Module | Code | Dependency Type | Detail |
|---|---|---|---|
| Question Bank | QNS | CRITICAL | `qns_questions_bank` is the source for `lms_quest_questions.question_id`. All question search/filter logic queries QNS tables. |
| LMS Quiz | QUZ | SHARED MODELS | Quest imports `AssessmentType` and `DifficultyDistributionConfig` from `Modules\LmsQuiz`. Shared attempt tables also defined in LmsQuiz ecosystem. |
| School Setup | SCH | FK DEPENDENCY | `sch_classes`, `sch_sections`, `sch_subjects`, `sch_entity_groups` |
| Syllabus | SLB | FK DEPENDENCY | `slb_lessons`, `slb_topics` |
| Student Profile | STD | FK DEPENDENCY | `std_students` in attempt tracking |
| Global / Academic | GLB | FK DEPENDENCY | `glb_academic_sessions` |
| System Config | SYS | AUTH DEPENDENCY | `sys_users`, policies, permissions, activity logs |

### 11.2 Shared Infrastructure

| Table | Owner | Usage by QST |
|---|---|---|
| `lms_assessment_types` | LmsQuiz | FK `quest_type_id` on `lms_quests` |
| `lms_difficulty_distribution_configs` | LmsQuiz | FK `difficulty_config_id` on `lms_quests` |
| `lms_quiz_quest_attempts` | Shared | Student attempts with `assessment_type='QUEST'` |
| `lms_quiz_quest_attempt_answers` | Shared | Per-question answers for quest attempts |
| `qns_question_options` | QNS | FK on `selected_option_id` in attempt answers |

### 11.3 Proposed Future Dependencies

| Module | Dependency |
|---|---|
| LXP (LXP) | Reward/badge triggers on quest completion — proposed integration |
| Notification (NTF) | Notify students when quest is published, approaching due date, or result is ready |
| Student Portal (STP) | Student quest-taking UI may be integrated into student portal |

---

## 12. Test Scenarios

**Current coverage: 0 tests (F)**

### 12.1 Unit Tests

| Test | Class | Scenarios |
|---|---|---|
| Quest code generation | `QuestCodeGeneratorTest` | Format is `QUEST_*_*_*_[A-Z0-9]{6}`; duplicate triggers regeneration; uniqueness guaranteed |
| canPublish validation | `QuestCanPublishTest` | Returns false when total_questions=0; returns false when assigned count != total_questions; returns true when all conditions met |
| Quest duplication | `QuestDuplicateTest` | New UUID; new quest_code; status=DRAFT; scopes cloned; questions cloned |
| Negative marking | `NegativeMarkingTest` | Wrong MCQ deducts `negative_marks`; minimum question score = 0; no negative total |
| Attempt status transitions | `AttemptStatusTest` | Valid transitions pass; invalid transitions throw exception |

### 12.2 Feature Tests

| Test | Description |
|---|---|
| `QuestCreationTest` | Happy path; missing hierarchy validation; duplicate code rejection |
| `QuestScopeTest` | Add multiple scopes per quest; getTopics AJAX cascade; scope deletion cascades |
| `QuestQuestionBulkStoreTest` | Bulk add 10 questions; ordinal auto-assigned; duplicate question rejected |
| `QuestAllocationTest` | CLASS / SECTION / GROUP / STUDENT allocation types; getTargetOptions per type |
| `QuestPublishGuardTest` | Attempt to publish with 0 questions → 422; publish with question mismatch → error; valid publish → 200 |
| `QuestGateTest` | Unauthenticated → 302 redirect; authenticated without permission → 403; with permission → 200 |
| `QuestAttemptStartTest` | Before published_at → 403; after cut_off_date → 403; within window → 201 |
| `QuestAttemptSubmitTest` | Auto-grades MCQ; flags descriptive; computes total_score and percentage; is_passed set |
| `QuestAttemptMaxAttemptsTest` | Attempt blocked after max_attempts reached |
| `QuestTimerEnforcedTest` | Auto-timeout sets status=TIMEOUT within 5 seconds |
| `QuestResultVisibilityTest` | Result hidden before result_publish_date; visible after; immediate if auto_publish_result=1 |
| `QuestEnsureTenantModuleTest` | Routes return 403 when module not enabled for tenant |
| `QuestActivityLogTest` | All CUD operations create activity log entries |

---

## 13. Glossary

| Term | Definition |
|---|---|
| Quest | A multi-lesson, broader-scope formative assessment. Distinct from a Quiz (single topic, short duration). |
| Quest Scope | A record defining which lesson + topic pair is covered by a given quest. One quest has many scopes. |
| Allocation | Assignment of a published quest to a target (CLASS/SECTION/GROUP/STUDENT) with a time window. |
| Assessment Type | Category label: Challenge, Enrichment, Practice, Revision, Diagnostic, Remedial, Re-Test. Managed in LmsQuiz module. |
| Difficulty Config | Percentage distribution across difficulty levels (Easy/Medium/Hard). Managed in LmsQuiz module. |
| canPublish | Model method: validates quest is ready for publishing (questions assigned, count matches, hierarchy complete). |
| Cut-off Date | Hard deadline: no new attempt can start after this datetime. |
| Auto-publish Result | Setting that releases scores automatically at `result_publish_date` without manual teacher action. |
| Ordinal | Integer sequence number controlling question display order within a quest attempt. |
| Marks Override | Per-question marks in `lms_quest_questions` that override the QNS question's default marks. |
| Negative Marking | Deduction of `negative_marks` factor per wrong MCQ answer; minimum per-question score = 0. |
| TIMEOUT | Attempt status when timer expires and server auto-submits the attempt. |
| REASSIGNED | Attempt status after admin grants a student an additional attempt beyond max_attempts. |
| system_generated | Flag indicating the quest's questions were auto-selected by `QuestGenerationService` rather than manually assigned. |

---

## 14. Suggestions

### 14.1 Critical (P0 — Block Production)

1. **Re-enable Gate authorization:** Uncomment `Gate::authorize('tenant.quest.viewAny')` in `LmsQuestController::index()` line 35. This is a security defect, not a feature request.
2. **Add `EnsureTenantHasModule` middleware:** Add to the `lms-quests` route group in `tenant.php:669`.
3. **Fix route ordering:** Move `quest-scope/get-topics` and `quest-allocation/get-target-options` GET routes to BEFORE their respective `Route::resource()` calls in `tenant.php`. Currently they will always resolve to the resource `show()` action and throw 404.
4. **Replace `$request->all()` in activity logs** with `$request->validated()` or specific named fields in `QuestScopeController` and `QuestAllocationController`.

### 14.2 High Priority (P1 — Production Readiness)

5. **Build student attempt pipeline:** Create `StudentQuestAttemptController` with `myQuests`, `startAttempt`, `saveAnswer`, `submitAttempt`, `viewResult`. This is the largest missing feature and makes the module unusable from the student perspective.
6. **Create `QuestAttempt` model:** Wrap `lms_quiz_quest_attempts` with `assessment_type = 'QUEST'` scope. Place in `Modules\LmsQuests\Models\QuestAttempt`.
7. **Create `QuestAttemptService`:** Extract auto-grading logic (MCQ scoring, negative marking, total_score computation, is_passed evaluation) from the future controller into a dedicated service.
8. **Expose publish route:** Add `POST /lms-quests/quest/{id}/publish` → `LmsQuestController::publish()` that calls `canPublish()` and returns structured validation errors if not ready.
9. **Remove duplicate quest code generation from controller:** The model boot already generates the code. The controller's `store()` method additionally loads 4 models and builds the code string, overwriting the model-generated code. Remove the controller-side generation and rely solely on `Quest::boot()`.
10. **Add authorization to AJAX endpoints:** AJAX methods (`getSections`, `getSubjects`, etc.) in `QuestQuestionController` may lack Gate checks. Verify and add where missing.

### 14.3 Medium Priority (P2)

11. **Implement timer enforcement server-side:** Create a scheduled command or queued job that checks `lms_quiz_quest_attempts` for `IN_PROGRESS` records past `started_at + duration_minutes` and transitions them to TIMEOUT status.
12. **Resolve `lesson_id` DDL mismatch:** Remove `lesson_id` from `Quest::$fillable` and from controller code-gen logic. Document that multi-lesson coverage is defined exclusively via `lms_quest_scopes`.
13. **Build teacher monitoring dashboard:** `QuestMonitorController::dashboard()` showing aggregate attempt stats per quest, with drill-down to per-student attempt detail.
14. **Create `QuestGenerationService`:** For quests with `is_system_generated = 1` — auto-select questions from QNS by difficulty distribution, respecting `only_unused_questions` and `only_authorised_questions` filters.
15. **Add test coverage:** Target minimum 60% feature test coverage. Priority tests: `QuestGateTest`, `QuestPublishGuardTest`, `QuestAttemptStartTest`, `QuestAttemptSubmitTest`.

### 14.4 Low Priority (P3)

16. **Extract shared masters to `LmsMaster` module:** `AssessmentType` and `DifficultyDistributionConfig` are currently owned by `Modules\LmsQuiz` but used by both Quiz and Quest. Consider a dedicated `LmsMaster` (or `LmsConfig`) module to break the direct cross-module import dependency.
17. **Add `QuestAnalyticsService`:** Track quest effectiveness — which questions are commonly answered incorrectly, average score trend by class, comparison across academic sessions.
18. **Cache lookup tables:** `AssessmentType` and `DifficultyDistributionConfig` are read-heavy / write-rarely. Add Redis cache with a school-scoped key.
19. **Optimise model accessors:** `getStatisticsAttribute()` and `getSummaryAttribute()` each run 2–3 queries on every access. Refactor to use eager-loaded relationships or add a `loadStatistics()` explicit method.
20. **LXP integration:** When student completes a quest with `is_passed = 1`, emit an event for the LXP module to award XP, badges, or streak rewards.

---

## 15. Appendices

### A. File Inventory (Current State)

```
Modules/LmsQuests/
├── app/Http/Controllers/
│   ├── LmsQuestController.php         (452 lines — tab hub + Quest CRUD; Gate disabled in index)
│   ├── QuestScopeController.php       (CRUD + getTopics AJAX; $request->all() in logs)
│   ├── QuestAllocationController.php  (CRUD + getTargetOptions AJAX; $request->all() in logs)
│   └── QuestQuestionController.php    (CRUD + 12 AJAX endpoints)
├── app/Models/
│   ├── Quest.php                      (665 lines — canPublish, publish, archive, duplicate, validateSettings)
│   ├── QuestScope.php
│   ├── QuestQuestion.php
│   └── QuestAllocation.php
├── app/Http/Requests/
│   ├── QuestRequest.php
│   ├── QuestAllocationRequest.php
│   ├── QuestQuestionRequest.php
│   └── QuestScopeRequest.php
├── app/Policies/
│   ├── QuestPolicy.php
│   ├── QuestAllocationPolicy.php
│   ├── QuestQuestionPolicy.php
│   └── QuestScopePolicy.php
├── resources/views/             (~22 blade files across 5 folders + tab_module)
│   ├── quest/          (create, edit, index, show, trash)
│   ├── quest-scope/    (create, edit, index, show, trash)
│   ├── quest-question/ (create, edit, index, show, trash)
│   ├── quest-allocation/ (create, edit, index, show, trash)
│   ├── tab_module/tab.blade.php
│   └── index.blade.php
├── routes/web.php                     (minimal — main routes in tenant.php:669–721)
└── tests/                             (empty — 0 test files)
```

### B. Files Required (Proposed for V2)

```
Modules/LmsQuests/ (additions)
├── app/Http/Controllers/
│   ├── StudentQuestAttemptController.php   (student attempt pipeline)
│   └── QuestMonitorController.php          (teacher monitoring dashboard)
├── app/Models/
│   └── QuestAttempt.php                    (wraps lms_quiz_quest_attempts with QUEST scope)
├── app/Services/
│   ├── QuestAttemptService.php             (auto-grading, scoring, negative marking)
│   └── QuestGenerationService.php          (system-generated quest auto-selection)
├── resources/views/
│   ├── student/
│   │   ├── my-quests.blade.php
│   │   ├── attempt.blade.php               (timer + questions + answers)
│   │   └── result.blade.php
│   └── quest-monitor/
│       ├── dashboard.blade.php
│       ├── allocation-detail.blade.php
│       └── grade-attempt.blade.php
└── tests/
    ├── Feature/
    │   ├── QuestCreationTest.php
    │   ├── QuestGateTest.php
    │   ├── QuestPublishGuardTest.php
    │   ├── QuestAttemptTest.php
    │   └── QuestEnsureTenantModuleTest.php
    └── Unit/
        ├── QuestCanPublishTest.php
        └── NegativeMarkingTest.php
```

### C. Known Bugs Summary

| Bug ID | Location | Severity | Description |
|---|---|---|---|
| SEC-QST-001 | `LmsQuestController.php:35` | CRITICAL | Gate::authorize commented out — index() unprotected |
| SEC-QST-002 | `tenant.php:669` | HIGH | `EnsureTenantHasModule` middleware missing on route group |
| GAP-RT-002 | `tenant.php:686` | HIGH | `quest-scope/get-topics` declared after resource route → 404 |
| GAP-RT-003 | `tenant.php:695` | HIGH | `quest-allocation/get-target-options` declared after resource route → 404 |
| SEC-QST-003 | `QuestScopeController:107,181,363` | MEDIUM | `$request->all()` logged — exposes sensitive fields |
| SEC-QST-003 | `QuestAllocationController:178,282,469` | MEDIUM | `$request->all()` logged — exposes sensitive fields |
| GAP-MDL-001 | `Quest.php $fillable` | HIGH | `lesson_id` in fillable but no column in `lms_quests` DDL |
| GAP-ARCH-004 | `LmsQuestController::store()` | MEDIUM | Duplicate quest code generation (also in model boot) |
| GAP-MDL-004 | Entire module | HIGH | No QuestAttempt model; no student attempt pipeline |
| GAP-SVC-001 | Entire module | HIGH | 0 services; all business logic in model or controllers |

### D. Route Group Location
All functional routes: `/Users/bkwork/Herd/prime_ai/routes/tenant.php` lines 669–721.
Route name prefix: `lms-quests.`

### E. Effort Estimates

| Priority | Items | Hours |
|---|---|---|
| P0 — Critical security + bugs | 4 items | 4–6 h |
| P1 — Student pipeline + publish route | 6 items | 40–55 h |
| P2 — Monitoring + timer + tests | 5 items | 30–40 h |
| P3 — Analytics + LXP + optimisation | 4 items | 15–20 h |
| **Total** | **19 items** | **89–121 h** |

---

## 16. V1 → V2 Delta

| Section | V1 | V2 Change |
|---|---|---|
| Status markers | Text only | ✅/🟡/❌/📐 status per FR and per feature |
| FR-QST-05 | Named "Quest Publish Workflow" | Expanded: proposed `/publish` and `/archive` routes; `canPublish()` bypass documented |
| FR-QST-06 | Named "Student Quest-Taking" — brief description | Fully expanded: all required controller methods, auto-grading logic, negative marking, timer, result visibility rules |
| FR-QST-07 | Not present | NEW — Teacher Monitoring Dashboard |
| FR-QST-08 | Not present | NEW — System-Generated Quests (QuestGenerationService) |
| FR-QST-09 | Not present | NEW — Quest Duplication (expose via route) |
| FR-QST-10 | Not present | NEW — Security Hardening (consolidated all SEC-QST-* items) |
| Section 5 Data Model | Table columns listed | Added DDL source line references; clarified DDL mismatch on lesson_id; added attempt_answers table detail |
| Section 6 Routes | Simple table | Split into subsections (Quest/Scope/Allocation/Questions/Student); added proposed student routes with 📐 markers |
| Section 7 Screens | 13 screens | Expanded to 22 existing + 6 proposed new screens |
| Section 8 Business Rules | 9 rules | Expanded to 15 rules including negative marking floor, result visibility, system-generated filters |
| Section 9 Workflow | Single lifecycle + attempt transitions | Added Quest Code Generation FSM; expanded attempt state diagram |
| Section 10 NFRs | 7 items | Expanded to 12 items including randomisation, accessor caching, DRY |
| Section 11 Dependencies | 6 modules | Added proposed future dependencies (LXP, NTF, STP); added shared infrastructure table |
| Section 12 Tests | 10 proposed tests | Expanded to 5 unit + 13 feature tests |
| Section 14 Suggestions | 8 items | Expanded to 20 items organised by P0/P1/P2/P3 priority |
| Section 15 Appendices | File inventory + route group + bug summary | Added "Files Required for V2", effort estimates table |
| Section 16 | Not present | NEW — V1→V2 Delta (this section) |
