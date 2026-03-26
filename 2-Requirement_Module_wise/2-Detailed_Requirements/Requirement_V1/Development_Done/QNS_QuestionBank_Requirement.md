# QuestionBank Module — Requirement Specification Document
**Version:** 1.0 | **Date:** 2026-03-25 | **Author:** Claude Code (Automated Extraction)
**Module Code:** QNS | **Module Type:** Tenant Module
**Table Prefix:** `qns_*` | **Processing Mode:** FULL
**RBS Reference:** Module I — Examination & Gradebook (question bank sections)

---

## 1. Executive Summary

The QuestionBank module (QNS) is the central repository for all educational assessment questions in Prime-AI. It provides a structured, taxonomy-tagged library of questions that feeds multiple assessment types: Quiz (LMS), Quest (practice), Online Exam, and Offline Exam. The module supports manual question creation, bulk Excel import, media attachments (images/audio/video), versioning, review/approval workflows, usage analytics, AI-assisted question generation, and deep curriculum tagging (Bloom's Taxonomy, Cognitive Skills, Complexity Levels).

**Implementation Statistics:**
- Controllers: 7 (AIQuestionGeneratorController, QuestionBankController, QuestionMediaStoreController, QuestionStatisticController, QuestionTagController, QuestionUsageTypeController, QuestionVersionController)
- Models: 17 (QuestionBank, QuestionMedia, QuestionMediaStore, QuestionOption, QuestionPerformanceCategory, QuestionPerformanceCategoryJnt, QuestionQuestionTag, QuestionQuestionTagJnt, QuestionReviewLog, QuestionStatistic, QuestionStatistics, QuestionTag, QuestionTopic, QuestionTopicJnt, QuestionUsageLog, QuestionUsageType, QuestionVersion)
- Services: 0
- FormRequests: 6 (QuestionBankRequest, QuestionMediaStoreRequest, QuestionStatisticRequest, QuestionTagRequest, QuestionUsageTypeRequest, QuestionVersionRequest)
- Tests: 0
- Imports: 2 (QuestionImport, QuestionReadOnly — maatwebsite/excel)
- Completion: ~45%

---

## CRITICAL SECURITY ISSUE — P0: HARDCODED API KEYS

**IMMEDIATE ACTION REQUIRED — ROTATE THESE KEYS NOW:**

```php
// File: Modules/QuestionBank/app/Http/Controllers/AIQuestionGeneratorController.php
// Lines 54-57

private $apiKeys = [
    'chatgpt' => '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',
    'gemini' => 'AIzaSyD-UVS7sEjn79TuvA3sxeFlGTjD_xaUhKY'
];
```

**These OpenAI and Google Gemini API keys are committed to source code and are exposed to anyone with repository access.** This constitutes:
- Potential unauthorized API usage billed to the organization
- Risk of model abuse, data exfiltration via AI API
- Violation of OpenAI and Google API terms of service

**Required Actions:**
1. Rotate the OpenAI key immediately at https://platform.openai.com/api-keys
2. Rotate the Gemini key immediately at https://aistudio.google.com/
3. Remove hardcoded keys from source code
4. Store keys in `.env` file as `OPENAI_API_KEY` and `GEMINI_API_KEY`
5. Access via `config('services.openai.key')` and `config('services.gemini.key')`
6. Add `.env` to `.gitignore` (should already be, but verify)
7. Audit git history and invalidate any previously committed credentials

**Additional AI Security Issue:**
- `AIQuestionGeneratorController` has no authorization check — anyone authenticated can trigger AI generation
- The controller is implemented but both providers have `'active' => false`, so generation returns empty results

---

## 2. Module Overview

### 2.1 Business Purpose

The QuestionBank serves as the foundational content repository for all assessment activities in Prime-AI. A well-structured question bank enables:
- Reuse of high-quality, peer-reviewed questions across multiple exams and quizzes
- Consistent cognitive taxonomy tagging (Bloom's Levels 1–6) for quality assessment
- AI-assisted question generation to accelerate content creation
- Statistical analysis of question quality (difficulty index, discrimination index)
- Personalized learning through performance-category-based question recommendations
- Multi-format support: MCQ, True/False, Fill-in-the-Blank, Short Answer, Essay, Match-the-Columns

### 2.2 Key Design Principles

1. **Curriculum-Anchored:** Every question is anchored to a specific `class → subject → lesson → topic → competency` chain from the Syllabus module.
2. **Taxonomy-Tagged:** Questions are tagged with Bloom's Taxonomy level, Cognitive Skill, Question Type Specificity, and Complexity Level.
3. **Version-Controlled:** Modifications create `qns_question_versions` snapshots — full JSON of question state.
4. **Review-Gated:** Questions go through DRAFT → IN_REVIEW → APPROVED → PUBLISHED workflow before being available for assessments.
5. **Usage-Tracked:** Every question used in quiz/exam/quest is recorded in `qns_question_usage_log`.
6. **Statistically Analyzed:** `qns_question_statistics` tracks difficulty_index, discrimination_index, guessing_factor, and time metrics.
7. **Ownership-Aware:** Questions have `ques_owner` (PrimeGurukul vs School) and `availability` scope (GLOBAL/SCHOOL_ONLY/CLASS_ONLY/SECTION_ONLY/ENTITY_ONLY/STUDENT_ONLY).

### 2.3 Menu Path

`Tenant Dashboard > Academics > Question Bank`
- Question List (filtered tab view)
- Create Question
- AI Question Generator
- Tags Management
- Usage Logs
- Statistics
- Version History
- Import Questions (Excel)

### 2.4 Architecture — Cross-Module References

```
QuestionBank (qns_*) references:
  ← Syllabus (slb_*): BloomTaxonomy, ComplexityLevel, CognitiveSkill, QueTypeSpecifity,
                       PerformanceCategory, QuestionType, Lesson, Topic, Competency, Book
  ← SchoolSetup (sch_*): SchoolClass, Section, Subject, SubjectGroup
  ← StudentProfile (std_*): Student (for STUDENT_ONLY availability)
  → Quiz (LMS): qns_questions_bank.for_quiz = 1
  → Quest (LMS): qns_questions_bank.for_assessment = 1
  → Exam (exm_*): qns_questions_bank.for_exam = 1 / for_offline_exam = 1
  → AI APIs: OpenAI GPT-4o-mini, Google Gemini 2.0 Flash
```

---

## 3. Stakeholders & Actors

| Actor | Role | Access Level |
|-------|------|-------------|
| School Admin | Manage question bank, approve questions | Full CRUD |
| Subject Teacher | Create, submit questions for review | Create, edit own, view |
| Department Head | Review and approve questions | Review + approve |
| Exam Coordinator | View approved/published questions | View only |
| Student | No direct access to question bank | Access via Quiz/Exam only |
| AI System | Generate question suggestions | Controlled via policy (currently stub) |

---

## 4. Functional Requirements

### FR-QNS-01: Question Creation & Management

**RBS Ref:** F.I3.1 — Marks Entry (question creation precedes entry)

**REQ-QNS-01.1 — Question Record Structure**
Each question (`qns_questions_bank`) shall capture:

*Identity:*
- `uuid` (BINARY(16), globally unique, `UUID_TO_BIN(UUID())`)
- `ques_title` (VARCHAR 255 — system use title)
- `ques_title_display` (bool — show title to students)

*Curriculum Anchoring (all required):*
- `class_id` → FK to `sch_classes`
- `subject_id` → FK to `sch_subjects`
- `lesson_id` → FK to `slb_lessons`
- `topic_id` → FK to `slb_topics`
- `competency_id` → FK to `slb_competencies`

*Content:*
- `question_content` (TEXT — shown to students)
- `content_format` (ENUM: TEXT/HTML/MARKDOWN/LATEX/JSON)
- `teacher_explanation` (TEXT NULL — shown after answer)

*Taxonomy (all required):*
- `bloom_id` → FK to `slb_bloom_taxonomy` (6 Bloom levels)
- `cognitive_skill_id` → FK to `slb_cognitive_skill`
- `ques_type_specificity_id` → FK to `slb_ques_type_specificity`
- `complexity_level_id` → FK to `slb_complexity_level`
- `question_type_id` → FK to `slb_question_types` (MCQ/TF/FIB/SA/Essay/Match)

*Assessment Metadata:*
- `expected_time_to_answer_seconds` (INT NULL)
- `marks` (DECIMAL 5,2 DEFAULT 1.00)
- `negative_marks` (DECIMAL 5,2 DEFAULT 0.00)

*Usage Flags (boolean):*
- `for_quiz`, `for_assessment`, `for_exam`, `for_offline_exam`

*Ownership:*
- `ques_owner` (ENUM: PrimeGurukul / School)
- `created_by_AI` (bool)
- `is_school_specific` (bool)

*Availability Scope:*
- `availability` (ENUM: GLOBAL/SCHOOL_ONLY/CLASS_ONLY/SECTION_ONLY/ENTITY_ONLY/STUDENT_ONLY)
- `selected_entity_group_id` (for ENTITY_ONLY)
- `selected_section_id` (for SECTION_ONLY)
- `selected_student_id` (for STUDENT_ONLY)

*Reference:*
- `book_id`, `book_page_ref`, `external_ref`, `reference_material`

*Status:*
- `status` (ENUM: DRAFT/IN_REVIEW/APPROVED/REJECTED/PUBLISHED/ARCHIVED)

**REQ-QNS-01.2 — Answer Options (MCQ)**
- `qns_question_options` stores options with `ordinal` (display order), `option_text`, `is_correct`, `Explanation`.
- Multiple correct answers supported (multi-select MCQ).
- Options are CASCADE-deleted with parent question.

**Acceptance Criteria:**
- Given teacher creates MCQ with 4 options and 1 correct, question saves with status DRAFT.
- Given question has `for_quiz = 1`, it appears in quiz question picker with Bloom filter.
- Given question is in DRAFT status, it cannot be added to a published quiz.

**Current Implementation:**
- `QuestionBankController@index` returns tab-based view with question list, media, tags, versions, statistics, usage logs.
- `QuestionBankController@print` provides filtered question printing view.
- `QuestionBankRequest` for validation.
- Complex `getQuestionBank($request)` private method with filtering support.

---

### FR-QNS-02: Bloom's Taxonomy Tagging

**RBS Ref:** F.I1.2 — Weightage & Scheme; F.I5.1 — Grade Calculation

**REQ-QNS-02.1 — Bloom's Taxonomy Integration**
- All questions must be tagged with a Bloom's Taxonomy level (`bloom_id` FK to `slb_bloom_taxonomy`).
- Bloom's levels in order: 1-Remember, 2-Understand, 3-Apply, 4-Analyze, 5-Evaluate, 6-Create.
- Assessment generators (Quiz/Exam) shall be able to filter questions by Bloom level to create balanced assessments.
- Difficulty distribution reports shall group questions by Bloom level.

**REQ-QNS-02.2 — Cognitive Skill Tagging**
- Questions are tagged with a `cognitive_skill_id` (FK to `slb_cognitive_skill`).
- Cognitive skills define the mental process required: Recall, Comprehension, Application, Critical Thinking, Creative Thinking, etc.

**REQ-QNS-02.3 — Complexity Level**
- `complexity_level_id` provides a user-facing difficulty rating (Easy/Medium/Hard/Very Hard).
- Distinct from Bloom level — a "Remember" question can still be rated Hard based on content obscurity.

**REQ-QNS-02.4 — Question Type Specificity**
- `ques_type_specificity_id` further classifies the question format within a question type (e.g., for MCQ: Single-Correct vs Multiple-Correct; for Essay: Analytical vs Descriptive).

**Current Implementation:**
- All taxonomy FK fields are required in `qns_questions_bank`.
- `AIQuestionGeneratorController` loads all taxonomy models for the question generator form: `bloomTaxonomies`, `questionTypes`, `complexityLevels`, `cognitiveSkills`, `queTypeSpecificities`.
- `QuestionBankController` loads all taxonomy options for filter data.

---

### FR-QNS-03: Question Versioning

**RBS Ref:** F.I4.1 — Moderation Workflow

**REQ-QNS-03.1 — Version Snapshot**
- On every modification to a question, a `qns_question_versions` record shall be created.
- The version stores: `question_bank_id`, `version` (incremented INT), `data` (full JSON snapshot of question + options + metadata), `version_created_by`, `change_reason`.
- The `current_version` field on `qns_questions_bank` tracks the latest version number.
- No-CRUD note in DDL: "data will be entered on Modification only."

**REQ-QNS-03.2 — Version Viewing**
- Teachers and admins can view the full history of question changes.
- `QuestionVersionController` and `QuestionVersion` model manage this.

**Acceptance Criteria:**
- Given a question's `question_content` is modified, a version record is created with the old state before modification.
- Given question is at version 3, the versions table has 3 rows for that question.

**Current Implementation:**
- `QuestionVersion` model exists.
- `QuestionVersionController` exists with `QuestionVersionRequest`.

---

### FR-QNS-04: Review & Approval Workflow

**RBS Ref:** F.I4.1 — Moderation Review/Approval

**REQ-QNS-04.1 — Review States**
- Questions follow the lifecycle: DRAFT → IN_REVIEW → APPROVED / REJECTED → PUBLISHED → ARCHIVED.
- Teachers submit questions for review (DRAFT → IN_REVIEW).
- Department Head or Admin reviews and approves (IN_REVIEW → APPROVED) or rejects (IN_REVIEW → REJECTED with comment).
- Approved questions are published for use in assessments (APPROVED → PUBLISHED).

**REQ-QNS-04.2 — Review Log**
- Every status change is recorded in `qns_question_review_log` with: `question_id`, `reviewer_id`, `review_status_id`, `review_comment`, `reviewed_at`.

**Current Implementation:**
- `QuestionReviewLog` model exists with fields matching DDL.
- No dedicated ReviewController — review status changes appear to be managed within `QuestionBankController`.

---

### FR-QNS-05: Media Management

**RBS Ref:** (Implicit — content quality)

**REQ-QNS-05.1 — Question Media**
- Questions and their options can have associated media: IMAGE, AUDIO, VIDEO, PDF.
- `qns_question_media_jnt` links media to questions with `media_purpose`: QUESTION/OPTION/QUES_EXPLANATION/OPT_EXPLANATION/RECOMMENDATION.
- `qns_media_store` stores physical media metadata: `uuid`, `media_type`, `file_name`, `file_path`, `mime_type`, `disk`, `size`, `checksum`.

**REQ-QNS-05.2 — Media Operations**
- Teachers upload images/audio/video for visual or audio-based questions.
- `QuestionMediaStoreController` handles media CRUD.
- Media uses ordinal positioning for display sequence.

**Current Implementation:**
- `QuestionMediaStore` and `QuestionMedia` models exist.
- `QuestionMediaStoreController` with `QuestionMediaStoreRequest`.

---

### FR-QNS-06: Tag System

**RBS Ref:** (Supporting F.I9.1 — Template Designer)

**REQ-QNS-06.1 — Question Tags**
- Custom keyword tags (`qns_question_tags`) with `short_name` (UNIQUE) and `name`.
- Many-to-many relationship via `qns_question_questiontag_jnt`.
- Tags support searching and filtering questions by topic/theme beyond the curriculum hierarchy.

**REQ-QNS-06.2 — Tag Management**
- Admins and teachers can create tags.
- `QuestionTagController` with `QuestionTagRequest`.

---

### FR-QNS-07: Performance Category Mapping

**RBS Ref:** F.I5.1 — Grade Calculation; F.I10.1 — Performance Insights

**REQ-QNS-07.1 — Performance Category Association**
- Questions are mapped to `slb_performance_categories` via `qns_question_performance_category_jnt`.
- `recommendation_type` (FK to sys_dropdowns): REVISION, PRACTICE, CHALLENGE.
- `priority` defines the order within a performance category.
- This table directly powers personalized learning paths — students in "weak" performance category receive REVISION questions, "average" receive PRACTICE, "strong" receive CHALLENGE.

**Current Implementation:**
- `QuestionPerformanceCategoryJnt` model exists.
- Schema DDL has explicit note: "This directly powers Personalized learning paths, AI-Teacher module, LXP integration."

---

### FR-QNS-08: Question Statistics

**RBS Ref:** F.I10.1 — AI-Based Examination Analytics

**REQ-QNS-08.1 — Statistical Metrics**
`qns_question_statistics` tracks (computed by backend service, not directly via UI):
- `difficulty_index` (DECIMAL 5,2): % of students who answered correctly
- `discrimination_index`: delta between top vs bottom performer scores
- `guessing_factor`: MCQ-specific estimate of random guessing contribution
- `min_time_taken_seconds` / `max_time_taken_seconds` / `avg_time_taken_seconds`
- `total_attempts`
- `last_computed_at`

**REQ-QNS-08.2 — Statistics Computation**
- DDL note: "Required a backend Service to calculate the statistics."
- Statistics are computed from historical answer records (stored in Quiz/Exam response tables).
- `QuestionStatisticController` exists for viewing statistics.
- No computation service exists yet (pending implementation).

**Current Implementation:**
- Both `QuestionStatistic` and `QuestionStatistics` models exist (possible duplication).
- `QuestionStatisticController` and `QuestionStatisticRequest` exist.

---

### FR-QNS-09: Usage Logging

**REQ-QNS-09.1 — Usage Tracking**
- Every use of a question in quiz/quest/exam/offline-exam creates a `qns_question_usage_log` record.
- Fields: `question_bank_id`, `question_usage_type` (FK to `qns_question_usage_type`), `context_id` (the quiz_id / exam_id), `used_at`.
- DDL note: "Display Only" — no CRUD UI needed; records written by Quiz/Exam modules.

**REQ-QNS-09.2 — Usage Type Reference**
`qns_question_usage_type` is a lookup table with pre-seeded values:
- QUIZ: for LMS Quiz
- QUEST: for LMS Quest/Practice
- ONLINE_EXAM: for online examinations
- OFFLINE_EXAM: for offline paper exams

**Current Implementation:**
- `QuestionUsageType` model with `QuestionUsageTypeController`.
- `QuestionUsageLog` model exists.

---

### FR-QNS-10: Bulk Import (Excel)

**REQ-QNS-10.1 — Excel Import**
- Teachers can bulk-upload questions via Excel template using `maatwebsite/laravel-excel`.
- `QuestionImport` handles actual import with model creation.
- `QuestionReadOnly` provides preview/validation before committing import.
- Template validation includes: required fields, valid taxonomy IDs, duplicate detection.

**Current Implementation:**
- Both `QuestionImport` and `QuestionReadOnly` import classes exist.
- `QuestionBankController` includes `Excel` facade import.

---

### FR-QNS-11: Question Print

**REQ-QNS-11.1 — Print Question Paper**
- `QuestionBankController@print` generates a printable view of filtered questions.
- Loads school organization details for letterhead.
- Used by teachers to generate question paper drafts.

**Current Implementation:**
- `print()` method implemented in `QuestionBankController`.
- `questionbank::question-bank.print` view.

---

### FR-QNS-12: AI Question Generation

**REQ-QNS-12.1 — AI Generator Interface**
- Admin/Teacher selects: AI provider, class, subject, lesson, topic, question type, Bloom level, complexity, cognitive skill, count of questions.
- System submits prompt to AI API (OpenAI/Gemini) and receives structured question JSON.
- Generated questions are saved as DRAFT questions with `created_by_AI = 1`.
- Teacher reviews and publishes after verification.

**REQ-QNS-12.2 — Provider Configuration (SECURITY FIX REQUIRED)**
- AI provider credentials must be stored in `.env` / `config/services.php`:
  ```env
  OPENAI_API_KEY=sk-...
  GEMINI_API_KEY=AIzaSy...
  ```
  ```php
  // config/services.php
  'openai' => ['key' => env('OPENAI_API_KEY')],
  'gemini' => ['key' => env('GEMINI_API_KEY')],
  ```
- The current `active` flag (`false` for both providers) means no actual API calls are made — generator returns empty results.

**REQ-QNS-12.3 — Authorization**
- The `AIQuestionGeneratorController` must check `Gate::authorize('tenant.ai-question-generator.viewAny')` before any action.
- Currently no authorization check is present.

**Current Implementation:**
- `AIQuestionGeneratorController@index` loads taxonomy dropdowns for generator form.
- AI providers defined as a static array with `api_url`, `default_model`, `headers` templates.
- Both providers have `'active' => false` — generation is effectively disabled.
- API keys hardcoded — **CRITICAL SECURITY ISSUE — ROTATE IMMEDIATELY**.

---

### FR-QNS-13: Topic-Level Associations

**REQ-QNS-13.1 — Multi-Topic Mapping**
- A question can span multiple topics via `qns_question_topic_jnt`.
- `weightage` (DECIMAL 5,2 DEFAULT 100) indicates the proportion of the question that tests each topic.
- Primary `topic_id` on `qns_questions_bank` is retained for quick filtering; `qns_question_topic_jnt` provides the full multi-topic mapping.

---

## 5. Data Model

### 5.1 Table: `qns_questions_bank` (Core)

| Column | Type | Notes |
|--------|------|-------|
| id | INT UNSIGNED PK | |
| uuid | BINARY(16) | UNIQUE — insert via `UUID_TO_BIN(UUID())` |
| class_id | INT UNSIGNED | FK → sch_classes |
| subject_id | INT UNSIGNED | FK → sch_subjects |
| lesson_id | INT UNSIGNED | FK → slb_lessons |
| topic_id | INT UNSIGNED | FK → slb_topics (primary) |
| competency_id | INT UNSIGNED | FK → slb_competencies |
| ques_title | VARCHAR(255) | System title |
| question_content | TEXT | Shown to students |
| content_format | ENUM | TEXT/HTML/MARKDOWN/LATEX/JSON |
| teacher_explanation | TEXT NULL | Post-answer explanation |
| bloom_id | INT UNSIGNED | FK → slb_bloom_taxonomy |
| cognitive_skill_id | INT UNSIGNED | FK → slb_cognitive_skill |
| ques_type_specificity_id | INT UNSIGNED | FK → slb_ques_type_specificity |
| complexity_level_id | INT UNSIGNED | FK → slb_complexity_level |
| question_type_id | INT UNSIGNED | FK → slb_question_types |
| expected_time_to_answer_seconds | INT UNSIGNED NULL | |
| marks | DECIMAL(5,2) | DEFAULT 1.00 |
| negative_marks | DECIMAL(5,2) | DEFAULT 0.00 |
| current_version | TINYINT UNSIGNED | DEFAULT 1 |
| for_quiz / for_assessment / for_exam / for_offline_exam | TINYINT(1) | Usage flags |
| ques_owner | ENUM | PrimeGurukul / School |
| created_by_AI | TINYINT(1) | DEFAULT 0 |
| is_school_specific | TINYINT(1) | DEFAULT 0 |
| availability | ENUM | GLOBAL/SCHOOL_ONLY/CLASS_ONLY/SECTION_ONLY/ENTITY_ONLY/STUDENT_ONLY |
| selected_entity_group_id | INT UNSIGNED NULL | FK → slb_entity_groups |
| selected_section_id | INT UNSIGNED NULL | FK → sch_sections |
| selected_student_id | INT UNSIGNED NULL | FK → std_students |
| book_id | INT UNSIGNED NULL | FK → slb_books |
| book_page_ref / external_ref | VARCHAR | |
| status | ENUM | DRAFT/IN_REVIEW/APPROVED/REJECTED/PUBLISHED/ARCHIVED |
| created_by | INT UNSIGNED NULL | FK → sys_users |
| is_active | TINYINT(1) | DEFAULT 1 |
| deleted_at | TIMESTAMP NULL | Soft delete |

**Key Indexes:** `idx_ques_class_subject` (class_id, subject_id), `idx_ques_complexity_bloom` (complexity_level_id, bloom_id), `idx_ques_visibility` (availability)

### 5.2 Table: `qns_question_options`

| Column | Type | Notes |
|--------|------|-------|
| id | INT UNSIGNED PK | |
| question_bank_id | INT UNSIGNED | FK → qns_questions_bank (CASCADE DELETE) |
| ordinal | SMALLINT UNSIGNED NULL | Display order |
| option_text | TEXT | |
| is_correct | TINYINT(1) | DEFAULT 0 |
| Explanation | TEXT NULL | Why this option is correct/incorrect |
| is_active / deleted_at | Standard | |

### 5.3 Table: `qns_question_versions`

| Column | Type | Notes |
|--------|------|-------|
| id | INT UNSIGNED PK | |
| question_bank_id | INT UNSIGNED | FK → qns_questions_bank |
| version | INT UNSIGNED | |
| data | JSON | Full snapshot of question state |
| version_created_by | INT UNSIGNED NULL | |
| change_reason | VARCHAR(255) NULL | |
| UNIQUE KEY | (question_bank_id, version) | |

### 5.4 Table: `qns_question_tags`

| Column | Type |
|--------|------|
| id | INT UNSIGNED PK |
| short_name | VARCHAR(100) UNIQUE |
| name | VARCHAR(255) |

### 5.5 Table: `qns_question_questiontag_jnt`

Junction between questions and tags. `UNIQUE KEY (question_bank_id, tag_id)`.

### 5.6 Table: `qns_media_store`

| Column | Type | Notes |
|--------|------|-------|
| id | INT UNSIGNED PK | |
| uuid | BINARY(16) UNIQUE | |
| owner_type | ENUM | QUESTION/OPTION/EXPLANATION/RECOMMENDATION |
| owner_id | INT UNSIGNED | Polymorphic owner ID |
| media_type | ENUM | IMAGE/AUDIO/VIDEO/PDF |
| file_name / file_path / mime_type | VARCHAR | |
| disk | VARCHAR(50) NULL | Storage disk (local/s3) |
| size | INT UNSIGNED NULL | Bytes |
| checksum | CHAR(64) NULL | SHA256 for integrity |

### 5.7 Table: `qns_question_media_jnt`

Junction linking media to questions/options. `media_purpose` enum: QUESTION/OPTION/QUES_EXPLANATION/OPT_EXPLANATION/RECOMMENDATION.

### 5.8 Table: `qns_question_statistics`

| Column | Type | Description |
|--------|------|-------------|
| question_bank_id | INT UNSIGNED | UNIQUE FK → qns_questions_bank |
| difficulty_index | DECIMAL(5,2) | % students correct |
| discrimination_index | DECIMAL(5,2) | Top vs bottom performer delta |
| guessing_factor | DECIMAL(5,2) | MCQ guess factor |
| min/max/avg_time_taken_seconds | INT UNSIGNED | Response time metrics |
| total_attempts | INT UNSIGNED | |
| last_computed_at | TIMESTAMP | |

### 5.9 Table: `qns_question_performance_category_jnt`

| Column | Description |
|--------|-------------|
| question_bank_id | FK → qns_questions_bank |
| performance_category_id | FK → slb_performance_categories |
| recommendation_type | FK → sys_dropdowns (REVISION/PRACTICE/CHALLENGE) |
| priority | SMALLINT — ordering within category |

### 5.10 Table: `qns_question_usage_log`

| Column | Description |
|--------|-------------|
| question_bank_id | FK → qns_questions_bank |
| question_usage_type | FK → qns_question_usage_type |
| context_id | quiz_id / exam_id (polymorphic) |
| used_at | TIMESTAMP |

### 5.11 Table: `qns_question_usage_type`

Pre-seeded lookup: QUIZ, QUEST, ONLINE_EXAM, OFFLINE_EXAM.

### 5.12 Table: `qns_question_review_log`

| Column | Description |
|--------|-------------|
| question_id | FK → qns_questions_bank |
| reviewer_id | FK → sys_users |
| review_status_id | FK → sys_dropdown_table |
| review_comment | TEXT NULL |
| reviewed_at | DATETIME |

### 5.13 Table: `qns_question_topic_jnt`

Multi-topic mapping. `UNIQUE KEY (question_bank_id, topic_id)`. `weightage DECIMAL(5,2) DEFAULT 100`.

---

## 6. API & Route Specification

### 6.1 Current Routes

```php
// Modules/QuestionBank/routes/web.php
Route::middleware(['auth', 'verified'])->group(function () {
    Route::resource('questionbanks', QuestionBankController::class)->names('questionbank');
});
```

**Issues:**
- Only the core CRUD resource is routed.
- Missing routes for: AI generator, tags, statistics, versions, media, usage types, import, print.
- No tenant middleware applied.

### 6.2 Required Route Structure

```
// Core Question Bank
GET/POST       /question-bank                              → QuestionBankController@index/store
GET/POST       /question-bank/create                       → QuestionBankController@create
GET/PUT/DELETE /question-bank/{question}                   → show/update/destroy
GET            /question-bank/print                        → QuestionBankController@print
POST           /question-bank/import                       → QuestionBankController@import (Excel)
GET            /question-bank/import-preview               → QuestionReadOnly preview

// AI Generator
GET            /question-bank/ai-generator                 → AIQuestionGeneratorController@index
POST           /question-bank/ai-generator/generate        → AIQuestionGeneratorController@generate

// Tags
GET/POST/PUT   /question-bank/tags                         → QuestionTagController (CRUD)

// Versions
GET            /question-bank/{question}/versions          → QuestionVersionController@index
GET            /question-bank/{question}/versions/{v}      → QuestionVersionController@show

// Statistics
GET            /question-bank/{question}/statistics        → QuestionStatisticController@show
POST           /question-bank/{question}/statistics/compute → QuestionStatisticController@compute

// Usage Logs
GET            /question-bank/{question}/usage             → (QuestionUsageLog view)

// Review (proposed)
POST           /question-bank/{question}/submit-review     → submit for review
POST           /question-bank/{question}/approve           → approve
POST           /question-bank/{question}/reject            → reject with comment
```

---

## 7. UI Screen Inventory

| Screen | Status | Notes |
|--------|--------|-------|
| Question Bank Tab View (index) | Partial — multi-tab view with filters | |
| Create Question | Partial — form controller exists | |
| Edit Question | Partial | |
| Print Question Paper | Implemented | |
| AI Question Generator | Implemented (form only, generation stub) | HARDCODED KEYS — P0 |
| Tags Management | Controller exists, routes missing | |
| Version History | Controller exists, routes missing | |
| Question Statistics | Controller exists, routes missing | |
| Usage Logs | Model only | |
| Excel Import | Import classes exist, UI unclear | |
| Review/Approval Workflow | Model only (no dedicated UI) | |

---

## 8. Business Rules & Domain Constraints

**BR-QNS-01:** A question must have ALL taxonomy fields populated before submission for review: `bloom_id`, `cognitive_skill_id`, `ques_type_specificity_id`, `complexity_level_id`, `question_type_id`.

**BR-QNS-02:** For MCQ questions, at least one option must have `is_correct = 1`. The system shall enforce this validation on save.

**BR-QNS-03:** Questions with `status` of DRAFT, IN_REVIEW, REJECTED, or ARCHIVED cannot be added to quizzes, exams, or any assessment. Only APPROVED or PUBLISHED questions are selectable.

**BR-QNS-04:** When `only_authorised_questions = 1` in a quiz/exam configuration, only questions with `qns_questions_bank.for_quiz = 1` (or respective `for_exam` flag) are eligible.

**BR-QNS-05:** When `only_unused_questions = 1`, the system shall cross-reference `qns_question_usage_log` to exclude questions already used in the same context type.

**BR-QNS-06:** Question `availability = GLOBAL` means the question is visible to all teachers and can be used in any assessment. `SCHOOL_ONLY`, `CLASS_ONLY`, `SECTION_ONLY`, `ENTITY_ONLY`, `STUDENT_ONLY` restrict visibility progressively.

**BR-QNS-07:** Questions with `ques_owner = PrimeGurukul` cannot be modified by school teachers. They can only use them as-is or duplicate them as `ques_owner = School` questions.

**BR-QNS-08:** AI-generated questions (`created_by_AI = 1`) must be reviewed and approved by a human teacher before use in any formal assessment.

**BR-QNS-09:** Every modification to `question_content`, `question_type_id`, `marks`, or any option creates a version snapshot in `qns_question_versions`. Pure status changes (DRAFT → IN_REVIEW) do not create version records.

**BR-QNS-10:** `negative_marks` must be >= 0 and < `marks`. Setting `negative_marks = 0` disables negative marking for that question.

---

## 9. Workflow & State Machines

### 9.1 Question Lifecycle

```
DRAFT → [Teacher submits for review] → IN_REVIEW
      → [Admin approves directly] → APPROVED

IN_REVIEW → [Reviewer approves] → APPROVED + review_log entry
          → [Reviewer rejects] → REJECTED + review_log entry (with comment)

APPROVED → [Admin publishes] → PUBLISHED (available in all assessments)
         → [Superseded by new version] → ARCHIVED

REJECTED → [Teacher revises] → DRAFT (can re-submit)

PUBLISHED → [No longer relevant] → ARCHIVED
```

### 9.2 AI Generation Flow

```
[Teacher opens AI Generator]
  → Selects: provider, class, subject, topic, bloom_level, question_type, count
       ↓
[POST /ai-generator/generate]
  → Load API key from config (NOT hardcoded)
  → Build curriculum-specific prompt
  → Call OpenAI/Gemini API
  → Parse JSON response
       ↓
[Review Generated Questions]
  → Each generated question saved as qns_questions_bank (status=DRAFT, created_by_AI=1)
  → Teacher reviews, edits, and submits for approval
```

### 9.3 Statistics Computation Flow

```
[Question used in quiz/exam]
  → qns_question_usage_log entry created by Quiz/Exam module
       ↓
[Scheduled Statistics Service (not yet implemented)]
  → Aggregates answers from quiz/exam response tables
  → Computes difficulty_index, discrimination_index, guessing_factor
  → Upserts qns_question_statistics record
  → Updates last_computed_at
```

---

## 10. Non-Functional Requirements

**NFR-QNS-01 (Security — P0):** OpenAI and Gemini API keys must be removed from source code immediately. Keys have been committed to the repository and must be rotated. New keys must be stored in `.env` only.

**NFR-QNS-02 (Security — P1):** `AIQuestionGeneratorController` must implement authorization before processing any request. Use `Gate::authorize('tenant.ai-question-generator.create')` at minimum.

**NFR-QNS-03 (Performance):** The question bank listing (`index` view) must support pagination and indexed filtering. The `idx_ques_class_subject`, `idx_ques_complexity_bloom`, `idx_ques_visibility` indexes support the most common filter combinations.

**NFR-QNS-04 (Data Integrity):** UUID binary storage requires explicit conversion: `UUID_TO_BIN(UUID())` on insert, `BIN_TO_UUID(uuid)` on read. All application code handling UUID must use these MySQL functions or an ORM cast.

**NFR-QNS-05 (Scalability):** Question bank may grow to 100,000+ records. Statistics computation must be an offline/scheduled process, not computed on-the-fly per request.

**NFR-QNS-06 (Accessibility):** LaTeX content format (`content_format = 'LATEX'`) requires MathJax or KaTeX rendering in the frontend. This must be loaded on question view/print pages.

**NFR-QNS-07 (Media Storage):** Question media files may be large (audio/video). The `qns_media_store.disk` field supports multiple storage backends (local, s3). S3 or equivalent CDN should be used for media files in production.

---

## 11. Cross-Module Dependencies

| Dependency | Direction | Purpose |
|-----------|-----------|---------|
| Syllabus (slb_*) | Consumes | Bloom taxonomy, question types, cognitive skills, complexity levels, topics, lessons, competencies, performance categories, books |
| SchoolSetup (sch_*) | Consumes | Classes, sections, subjects, subject groups |
| StudentProfile (std_*) | Consumes | Students (for STUDENT_ONLY availability) |
| Quiz/LMS | Provides | Supplies `for_quiz=1` questions to quiz builder |
| Quest/Practice | Provides | Supplies `for_assessment=1` questions |
| Exam (exm_*) | Provides | Supplies `for_exam=1` / `for_offline_exam=1` questions |
| SystemConfig (sys_*) | Consumes | `sys_dropdown_table` for status/review lookups; `sys_user` for ownership/review |
| OpenAI API | External | GPT-4o-mini for AI question generation |
| Google Gemini API | External | Gemini 2.0 Flash for AI question generation |
| maatwebsite/excel | Package | Excel import/export |

---

## 12. Test Coverage

**Current State: 0 tests exist.**

**Required Test Suite:**

| Test | Type | Priority | Description |
|------|------|----------|-------------|
| QuestionBankCrudTest | Feature | P0 | Create/read/update/delete questions |
| QuestionStatusWorkflowTest | Feature | P0 | DRAFT → IN_REVIEW → APPROVED → PUBLISHED |
| BloomTaxonomyTaggingTest | Unit | P0 | Bloom level required validation |
| MCQOptionValidationTest | Unit | P0 | At least one correct option |
| QuestionVersioningTest | Feature | P1 | Modification creates version snapshot |
| ReviewLogTest | Feature | P1 | Approve/reject creates review log |
| QuestionAvailabilityTest | Unit | P1 | GLOBAL vs scoped availability filtering |
| AIKeySecurityTest | Unit | P0 | Ensure no hardcoded keys in config |
| QuestionImportTest | Feature | P1 | Excel bulk import |
| StatisticsComputationTest | Unit | P2 | Difficulty/discrimination index calculation |
| MediaAttachmentTest | Feature | P1 | Image/audio attachment to question |
| UsageLoggingTest | Feature | P1 | Usage log created when question used in quiz |

---

## 13. Glossary

| Term | Definition |
|------|-----------|
| Bloom's Taxonomy | 6-level cognitive classification: Remember, Understand, Apply, Analyze, Evaluate, Create |
| Cognitive Skill | Mental process category for a question (Recall, Comprehension, Application, Critical Thinking) |
| Complexity Level | User-facing difficulty rating: Easy, Medium, Hard, Very Hard |
| Question Type Specificity | Sub-classification of question format within a type |
| Difficulty Index | % of students who answered correctly — low = hard, high = easy |
| Discrimination Index | Difference in correct-answer rate between top and bottom-performing students |
| Guessing Factor | MCQ-specific estimate of answers obtained by random guessing |
| Competency | Learning outcome associated with a topic |
| Availability Scope | Controls who can see/use a question: GLOBAL to STUDENT_ONLY |
| Usage Log | Record of which quiz/exam used a specific question |
| Version Snapshot | Full JSON copy of a question at a point in time before modification |

---

## 14. Additional Suggestions (Analyst Notes)

**Priority 0 — Security (Immediate):**
1. Rotate OpenAI key (`sk-proj-KimXs0Dn...`) at https://platform.openai.com/api-keys.
2. Rotate Gemini key (`AIzaSyD-UVS7...`) at https://aistudio.google.com/.
3. Move keys to `.env` as `OPENAI_API_KEY` and `GEMINI_API_KEY`.
4. Reference via `config('services.openai.key')` in `AIQuestionGeneratorController`.
5. Add authorization check to `AIQuestionGeneratorController`.

**Priority 1 — Feature Completion:**
6. Implement the statistics computation service — aggregate answers from Quiz/Exam response tables to compute difficulty_index and discrimination_index.
7. Complete the review/approval workflow with dedicated UI screens and email notifications to reviewers.
8. Implement question duplication feature (copy PrimeGurukul question as school question for customization).
9. Fix the UUID binary handling in the ORM layer — add a custom cast or accessor/mutator in `QuestionBank` model for the `uuid` binary field.

**Priority 2 — AI Enhancement:**
10. Activate AI providers by setting `'active' => true` after API key security is fixed.
11. Implement structured prompt engineering: include curriculum context (board, class, subject, topic) in the AI prompt for more relevant questions.
12. Add AI-generated question quality scoring using the existing taxonomy fields.
13. Consider a human-in-the-loop review queue UI specifically for AI-generated questions.

**Priority 3 — Analytics:**
14. Build question bank analytics dashboard: Bloom level distribution, complexity distribution, questions by subject/class, usage frequency heatmap.
15. Integrate question statistics with the Recommendation module to power personalized learning paths.

---

## 15. Appendices

### Appendix A: Key File Paths

| File | Path |
|------|------|
| AIQuestionGeneratorController | `Modules/QuestionBank/app/Http/Controllers/AIQuestionGeneratorController.php` |
| QuestionBankController | `Modules/QuestionBank/app/Http/Controllers/QuestionBankController.php` |
| QuestionBank Model | `Modules/QuestionBank/app/Models/QuestionBank.php` |
| QuestionVersion Model | `Modules/QuestionBank/app/Models/QuestionVersion.php` |
| QuestionImport | `Modules/QuestionBank/app/Imports/QuestionImport.php` |
| Web Routes | `Modules/QuestionBank/routes/web.php` |
| DDL | `tenant_db_v2.sql` lines 5211–5510 |

### Appendix B: Known Security Issues

| ID | Severity | Description | File / Line | Fix |
|----|----------|-------------|-------------|-----|
| SEC-QNS-001 | P0 CRITICAL | OpenAI API key hardcoded in source | `AIQuestionGeneratorController.php:55` | Rotate key, move to .env |
| SEC-QNS-002 | P0 CRITICAL | Gemini API key hardcoded in source | `AIQuestionGeneratorController.php:56` | Rotate key, move to .env |
| SEC-QNS-003 | HIGH | No authorization on AIQuestionGeneratorController | `AIQuestionGeneratorController.php` | Add Gate::authorize() |

### Appendix C: Bloom's Taxonomy Level Reference

| Level | Name | Cognitive Action | Question Indicators |
|-------|------|-----------------|---------------------|
| 1 | Remember | Recall facts | List, Define, Recall, Identify |
| 2 | Understand | Explain ideas | Summarize, Describe, Explain |
| 3 | Apply | Use in new situations | Solve, Use, Demonstrate, Apply |
| 4 | Analyze | Draw connections | Compare, Contrast, Differentiate |
| 5 | Evaluate | Justify decisions | Critique, Defend, Judge, Assess |
| 6 | Create | Produce something new | Design, Construct, Formulate |

### Appendix D: Question Status Reference

| Status | Actor Who Sets | Next States |
|--------|---------------|-------------|
| DRAFT | System (on create) / Teacher (on reject-revise) | IN_REVIEW, APPROVED (admin shortcut) |
| IN_REVIEW | Teacher (submit for review) | APPROVED, REJECTED |
| APPROVED | Reviewer / Admin | PUBLISHED, ARCHIVED |
| REJECTED | Reviewer | → Teacher revises → DRAFT |
| PUBLISHED | Admin | ARCHIVED |
| ARCHIVED | Admin | (terminal) |
