# QNS — Question Bank
## Module Requirement Document V2
**Version:** 2.0 | **Date:** 2026-03-26 | **Status:** Draft | **Mode:** FULL

---

## 1. Executive Summary

The QuestionBank module (QNS) is the central repository for all educational assessment content in Prime-AI. It provides a structured, taxonomy-tagged library of questions that feeds four assessment types: LMS Quiz, LMS Quest/Practice, Online Exam, and Offline Exam. The module supports manual question creation across six question types, bulk Excel import, rich media attachments (image/audio/video/PDF), full version history, a DRAFT→PUBLISHED review/approval workflow, AI-assisted question generation via OpenAI and Google Gemini, and statistical analytics (difficulty index, discrimination index, guessing factor).

**Current Implementation: ~45% complete.** Core CRUD and import skeleton exist. Critical security vulnerabilities are present (hardcoded AI API keys). Authorization gaps affect multiple controllers. AI generation returns only demo data. No service layer. Zero tests.

**P0 Security Alert:** OpenAI and Gemini API keys are hardcoded in source code in `AIQuestionGeneratorController.php`. These must be rotated immediately and moved to `.env`. See Section 10 (NFRs) and Appendix B for the exact remediation steps.

| Metric | Value |
|--------|-------|
| Module Code | QNS |
| Table Prefix | `qns_` |
| DDL Tables | 13 |
| Controllers | 7 |
| Models | 16 (17 files — 1 duplicate) |
| Services | 0 (gap — required) |
| FormRequests | 6 |
| Tests | 0 (gap — required) |
| Completion | ~45% |
| Critical Issues | 6 |
| High Issues | 10 |
| Estimated Fix Effort | 10–12 developer days |

---

## 2. Module Overview

### 2.1 Business Purpose

The QuestionBank serves as the foundational content repository for all assessment activities in Prime-AI. A structured, well-tagged question bank enables:

- Reuse of peer-reviewed questions across multiple exams and quizzes without duplication
- Consistent Bloom's Taxonomy tagging (Levels 1–6) to ensure balanced cognitive coverage
- AI-assisted question generation to accelerate content creation for teachers
- Statistical analysis of question quality (difficulty index, discrimination index) from real student responses
- Personalized learning paths via performance-category mapping — students in "weak" categories receive REVISION questions; "average" receive PRACTICE; "strong" receive CHALLENGE questions
- Multi-format support: MCQ (single/multi-correct), True/False, Fill-in-the-Blank, Short Answer, Essay/Long Answer, Match-the-Columns

### 2.2 Key Design Principles

1. **Curriculum-Anchored:** Every question is anchored to the `class → subject → lesson → topic → competency` chain from the Syllabus module.
2. **Taxonomy-Tagged:** Questions carry Bloom's Taxonomy level, Cognitive Skill, Question Type Specificity, and Complexity Level — all required fields.
3. **Version-Controlled:** Every content modification creates a full JSON snapshot in `qns_question_versions`. Version number is tracked on the parent record.
4. **Review-Gated:** Questions follow DRAFT → IN_REVIEW → APPROVED → PUBLISHED before use in any assessment. Only APPROVED or PUBLISHED questions are selectable in Quiz/Exam builders.
5. **Usage-Tracked:** Every question's use in a quiz/exam/quest is recorded in `qns_question_usage_log`, written by the consuming module.
6. **Statistically Analyzed:** `qns_question_statistics` tracks difficulty_index, discrimination_index, guessing_factor, and time-to-answer metrics, computed by a scheduled backend service.
7. **Ownership-Aware:** `ques_owner` (PrimeGurukul vs School) and `availability` scope (GLOBAL/SCHOOL_ONLY/CLASS_ONLY/SECTION_ONLY/ENTITY_ONLY/STUDENT_ONLY) control visibility and editability.
8. **Credentials-Safe (P0 Requirement):** AI provider API keys must never appear in source code — they must live exclusively in `.env` and be accessed via `config('services.*')`.

### 2.3 Menu Path

```
Tenant Dashboard > Academics > Question Bank
  ├── Question List (filtered tab view)
  ├── Create Question
  ├── AI Question Generator
  ├── Tags Management
  ├── Import Questions (Excel)
  ├── Usage Logs
  ├── Statistics
  └── Version History
```

### 2.4 Architecture — Cross-Module References

```
QuestionBank (qns_*) references:
  Incoming from Syllabus (slb_*):
    slb_bloom_taxonomy, slb_complexity_level, slb_cognitive_skill,
    slb_ques_type_specificity, slb_question_types, slb_performance_categories,
    slb_lessons, slb_topics, slb_competencies, slb_books, slb_entity_groups
  Incoming from SchoolSetup (sch_*):
    sch_classes, sch_sections, sch_subjects
  Incoming from StudentProfile (std_*):
    std_students (for STUDENT_ONLY availability)
  Incoming from SystemConfig (sys_*):
    sys_users (created_by, reviewer_id), sys_dropdown_table (review_status)
  Outgoing to Quiz (LMS):     for_quiz = 1 flag
  Outgoing to Quest (LMS):    for_assessment = 1 flag
  Outgoing to Exam (exm_*):   for_exam = 1 / for_offline_exam = 1
  External: OpenAI API (GPT-4o-mini), Google Gemini API (Gemini 2.0 Flash)
  Package:  maatwebsite/laravel-excel (bulk import)
```

---

## 3. Stakeholders & Roles

| Actor | Role | Access Level |
|-------|------|-------------|
| School Admin | Full question bank management, approve/publish questions, manage tags | Full CRUD on all sub-modules |
| Subject Teacher | Create questions, submit for review, edit own DRAFT/REJECTED questions, use AI generator | Create + edit own; view approved/published |
| Department Head | Review submitted questions, approve or reject with comments | Review + approve/reject; view all |
| Exam Coordinator | Browse approved/published question bank for exam paper design | View APPROVED/PUBLISHED only |
| Student | No direct access — questions served through Quiz/Exam/Quest interfaces only | None (indirect via assessment) |
| AI System (OpenAI/Gemini) | External service called via configured API key to generate question drafts | Controlled through AIQuestionService; rate-limited |

---

## 4. Functional Requirements

### FR-QNS-01: Question Creation & Management ✅ (Partial)

**RBS Ref:** F.I3.1 — Marks Entry (question creation precedes assessment entry)

**Status:** Core CRUD exists (~85%). Auth gaps on index/import endpoints. No service layer.

**REQ-QNS-01.1 — Question Record Structure**

Each question (`qns_questions_bank`) shall capture the following grouped fields:

*Identity:*
- `uuid` — BINARY(16), globally unique; inserted via `UUID_TO_BIN(UUID())`, read via `BIN_TO_UUID(uuid)`. The ORM must use a UUID cast.
- `ques_title` — VARCHAR(255); system-use title, not shown to students.
- `ques_title_display` — TINYINT(1); whether to show title to students (default 0).

*Curriculum Anchoring (all required):*
- `class_id` → FK `sch_classes.id`
- `subject_id` → FK `sch_subjects.id`
- `lesson_id` → FK `slb_lessons.id`
- `topic_id` → FK `slb_topics.id` (primary topic)
- `competency_id` → FK `slb_competencies.id`

*Content:*
- `question_content` — TEXT; the question shown to students.
- `content_format` — ENUM(TEXT/HTML/MARKDOWN/LATEX/JSON); controls rendering. LATEX requires MathJax/KaTeX on frontend.
- `teacher_explanation` — TEXT NULL; explanation revealed after the student answers.

*Taxonomy (all required):*
- `bloom_id` → FK `slb_bloom_taxonomy.id`
- `cognitive_skill_id` → FK `slb_cognitive_skill.id`
- `ques_type_specificity_id` → FK `slb_ques_type_specificity.id`
- `complexity_level_id` → FK `slb_complexity_level.id`
- `question_type_id` → FK `slb_question_types.id`

*Assessment Metadata:*
- `expected_time_to_answer_seconds` — INT UNSIGNED NULL
- `marks` — DECIMAL(5,2) DEFAULT 1.00
- `negative_marks` — DECIMAL(5,2) DEFAULT 0.00

*Usage Flags:*
- `for_quiz`, `for_assessment`, `for_exam`, `for_offline_exam` — TINYINT(1)

*Ownership:*
- `ques_owner` — ENUM(PrimeGurukul/School)
- `created_by_AI` — TINYINT(1) DEFAULT 0
- `is_school_specific` — TINYINT(1) DEFAULT 0
- `created_by` — FK `sys_users.id` NULL

*Availability Scope:*
- `availability` — ENUM(GLOBAL/SCHOOL_ONLY/CLASS_ONLY/SECTION_ONLY/ENTITY_ONLY/STUDENT_ONLY) DEFAULT GLOBAL
- `selected_entity_group_id` — FK `slb_entity_groups.id` NULL (for ENTITY_ONLY)
- `selected_section_id` — FK `sch_sections.id` NULL (for SECTION_ONLY)
- `selected_student_id` — FK `std_students.id` NULL (for STUDENT_ONLY)

*Reference Source:*
- `book_id` — FK `slb_books.id` NULL
- `book_page_ref` — VARCHAR(50) NULL
- `external_ref` — VARCHAR(100) NULL
- `reference_material` — TEXT NULL

*Status:*
- `status` — ENUM(DRAFT/IN_REVIEW/APPROVED/REJECTED/PUBLISHED/ARCHIVED) DEFAULT DRAFT
- `current_version` — TINYINT UNSIGNED DEFAULT 1

**REQ-QNS-01.2 — MCQ Answer Options**
- `qns_question_options` stores per-question options with `ordinal` (display order), `option_text`, `is_correct`, `Explanation`.
- Multi-select MCQ (multiple correct answers) is supported by allowing multiple `is_correct = 1` rows.
- Options are CASCADE-deleted when the parent question is deleted.
- For non-MCQ question types (True/False, Short Answer, Essay), options are not required.

**REQ-QNS-01.3 — Authorization (Gap)**
- `QuestionBankController@index`, `@print`, `@validateFile`, `@startImport` currently lack `Gate::authorize()`. All four must be protected.
- Policy: `QuestionBankPolicy` — gate names follow pattern `tenant.question-bank.*`.

**Acceptance Criteria:**
- Given a teacher creates an MCQ with 4 options and exactly 1 correct, the question saves with `status = DRAFT` and `current_version = 1`.
- Given a question has `for_quiz = 1` and `status = PUBLISHED`, it appears in the quiz question picker filtered by Bloom level.
- Given a question has `status = DRAFT`, the quiz builder cannot add it to an assessment.
- Given an unauthenticated user calls `GET /question-bank`, they receive a 401/403 response.

---

### FR-QNS-02: Question Types ✅ (Schema) / 🟡 (UI)

**REQ-QNS-02.1 — Supported Question Formats**

All question types are defined in `slb_question_types` and selected via `question_type_id`. The following types must be fully supported in the create/edit form:

| Type Code | Name | Options Required | Answer Format |
|-----------|------|-----------------|---------------|
| MCQ | Multiple Choice — Single Correct | Yes (min 2) | Single `is_correct = 1` option |
| MCQ_MULTI | Multiple Choice — Multi Correct | Yes (min 2) | Multiple `is_correct = 1` options |
| TF | True / False | No (system-generated) | Boolean |
| FIB | Fill in the Blank | No | Free text answer stored in teacher_explanation |
| SA | Short Answer | No | Free text; teacher marks manually |
| ESSAY | Long Answer / Essay | No | Extended free text; rubric-based marking |
| MATCH | Match the Columns | Yes (pairs) | Left-right pair mapping stored as options |

**REQ-QNS-02.2 — Rich Content Formats**
- `content_format = LATEX`: question_content contains LaTeX math expressions. Frontend must load MathJax or KaTeX for rendering.
- `content_format = HTML`: rich text with formatting. Frontend must use a sanitized HTML renderer (no XSS).
- `content_format = MARKDOWN`: markdown-rendered content.
- `content_format = JSON`: structured content (used for Match/Ordering type schemas).

---

### FR-QNS-03: Bloom's Taxonomy & Taxonomy Tagging ✅

**RBS Ref:** F.I1.2 — Weightage & Scheme; F.I5.1 — Grade Calculation

**REQ-QNS-03.1 — Bloom's Taxonomy Integration**
- All questions must be tagged with a Bloom's Taxonomy level (`bloom_id` FK to `slb_bloom_taxonomy`).
- 6 levels in ascending cognitive order: 1-Remember, 2-Understand, 3-Apply, 4-Analyze, 5-Evaluate, 6-Create.
- Assessment generators (Quiz/Exam) filter questions by Bloom level to create cognitively balanced assessments.
- Analytics reports group question distribution by Bloom level.

**REQ-QNS-03.2 — Cognitive Skill Tagging**
- `cognitive_skill_id` FK to `slb_cognitive_skill` — defines the mental process required: Recall, Comprehension, Application, Critical Thinking, Creative Thinking, etc.

**REQ-QNS-03.3 — Complexity Level**
- `complexity_level_id` FK to `slb_complexity_level` — user-facing difficulty rating: Easy / Medium / Hard / Very Hard.
- Distinct from Bloom level — a "Remember" question can be rated Hard based on content obscurity.
- This is the field used by teachers when browsing the question bank; Bloom level is used for cognitive analysis.

**REQ-QNS-03.4 — Question Type Specificity**
- `ques_type_specificity_id` FK to `slb_ques_type_specificity` — sub-classifies question format within a type.
- Example for MCQ: Single-Correct vs Multiple-Correct vs Assertion-Reason.
- Example for Essay: Analytical vs Descriptive vs Narrative.

---

### FR-QNS-04: Version History ✅ (Model) / 🟡 (Service)

**RBS Ref:** F.I4.1 — Moderation Workflow

**REQ-QNS-04.1 — Version Snapshot on Modification**
- On every save that modifies `question_content`, `question_type_id`, `marks`, any answer option content, or any taxonomy field — a `qns_question_versions` record must be created BEFORE applying the change.
- Pure status transitions (DRAFT → IN_REVIEW, APPROVED → PUBLISHED) do not create version records.
- The snapshot `data` JSON field stores the full prior state: question fields + all options + media references.
- `current_version` on `qns_questions_bank` increments to match.
- A `QuestionBankService::createVersionSnapshot()` method must be built to encapsulate this logic.

**REQ-QNS-04.2 — Version History View**
- Teachers and admins can view the complete modification history for any question.
- The version history screen lists: version number, change_reason, version_created_by (user name), created_at.
- Clicking a version shows the full diff or the snapshot JSON rendered as a readable question.
- `QuestionVersionController@index` and `@show` handle this.

**Acceptance Criteria:**
- Given a teacher edits a question's content, a version row is created with the prior state before the edit.
- Given a question has been modified 3 times, `qns_question_versions` has 3 rows for that `question_bank_id` with versions 1, 2, 3.
- Given a pure status change (APPROVED → PUBLISHED), no new version row is created.

---

### FR-QNS-05: Review & Approval Workflow 🟡 (Model exists, limited controller)

**RBS Ref:** F.I4.1 — Moderation Review/Approval

**REQ-QNS-05.1 — Review State Machine**
```
DRAFT → [Teacher submits]   → IN_REVIEW
      → [Admin shortcut]    → APPROVED (skip review for trusted content)

IN_REVIEW → [Reviewer approves] → APPROVED  + review_log entry
          → [Reviewer rejects]  → REJECTED  + review_log entry with mandatory comment

APPROVED  → [Admin publishes]   → PUBLISHED (available in assessments)
          → [Superseded]        → ARCHIVED

REJECTED  → [Teacher revises]   → DRAFT (can re-submit after edits)

PUBLISHED → [Retired]           → ARCHIVED (terminal for most purposes)
```

**REQ-QNS-05.2 — Review Log**
- Every status transition triggered by a reviewer creates a `qns_question_review_log` record with:
  - `question_id`, `reviewer_id`, `review_status_id`, `review_comment` (required on REJECT), `reviewed_at`.
- `review_status_id` FK to `sys_dropdown_table` for values like PENDING/APPROVED/REJECTED.

**REQ-QNS-05.3 — Dedicated Review Controller (Gap — 📐 Proposed)**
- A `QuestionReviewController` must be created (or review actions added to `QuestionBankController`) to expose:
  - `POST /question-bank/{question}/submit-review` — Teacher submits for review.
  - `POST /question-bank/{question}/approve` — Reviewer approves.
  - `POST /question-bank/{question}/reject` — Reviewer rejects with comment.
  - `POST /question-bank/{question}/publish` — Admin publishes.
  - `POST /question-bank/{question}/archive` — Admin archives.
- Notifications to relevant parties on status transitions (email/in-app via NTF module).

**Acceptance Criteria:**
- Given a teacher clicks "Submit for Review," the status changes to IN_REVIEW and a review_log entry is created.
- Given a reviewer clicks "Reject," a `review_comment` is required; the status changes to REJECTED.
- Given a question is REJECTED, the teacher can edit and re-submit.

---

### FR-QNS-06: Media Management ✅ (Model) / 🟡 (Policy bug)

**REQ-QNS-06.1 — Question Media Attachments**
- Questions and their answer options may have attached media: IMAGE, AUDIO, VIDEO, PDF.
- `qns_question_media_jnt` links media records to questions with `media_purpose` context:
  - `QUESTION` — image/audio illustrating the question itself
  - `OPTION` — media specific to an option (links to `question_option_id`)
  - `QUES_EXPLANATION` — media in the teacher's explanation
  - `OPT_EXPLANATION` — media explaining an option
  - `RECOMMENDATION` — media used in personalized recommendation context
- `ordinal` controls display sequence when multiple media items are attached to the same purpose.

**REQ-QNS-06.2 — Media Store**
- `qns_media_store` stores physical file metadata: `uuid` (BINARY 16), `owner_type` (QUESTION/OPTION/EXPLANATION/RECOMMENDATION), `owner_id`, `media_type`, `file_name`, `file_path`, `mime_type`, `disk` (local/s3), `size` (bytes), `checksum` (SHA-256).
- The `checksum` enables deduplication — uploading an identical file should link to the existing store record.

**REQ-QNS-06.3 — Authorization Fix (Gap — P1)**
- `QuestionMediaStoreController` currently uses `Gate::authorize('tenant.competency.*')` — a copy-paste error from the Syllabus module.
- All policy references must be corrected to `tenant.question-media.*` to match `QuestionMediaStorePolicy`.

**Acceptance Criteria:**
- Given a teacher uploads an image for a question, the image appears inline in the question view and print.
- Given the same image file is uploaded twice, only one `qns_media_store` record exists (checksum deduplication).

---

### FR-QNS-07: Tag System ✅

**REQ-QNS-07.1 — Custom Keyword Tags**
- `qns_question_tags` stores free-form tags with `short_name` (UNIQUE) and `name`.
- Many-to-many relationship via `qns_question_questiontag_jnt` with `UNIQUE KEY (question_bank_id, tag_id)`.
- Tags provide search/filter capability beyond the formal curriculum hierarchy (e.g., "NCERT Important," "Board 2024," "Frequently Wrong").

**REQ-QNS-07.2 — Tag Management**
- School admins and teachers can create, edit, and delete tags.
- `QuestionTagController` with `QuestionTagRequest` — this sub-module is well-implemented (95%).
- Tags should be autocomplete-searchable in the question create/edit form.

---

### FR-QNS-08: Multi-Topic Mapping ✅ (Schema)

**REQ-QNS-08.1 — Spanning Multiple Topics**
- A single question may test content from multiple topics via `qns_question_topic_jnt`.
- `weightage` (DECIMAL 5,2 DEFAULT 100) indicates the proportion of the question associated with each topic (all weightages should sum to 100 across topic rows for a question).
- The primary `topic_id` on `qns_questions_bank` is retained for fast indexing and backward compatibility; `qns_question_topic_jnt` provides the full multi-topic mapping.

---

### FR-QNS-09: Performance Category Mapping ✅ (Schema)

**RBS Ref:** F.I5.1 — Grade Calculation; F.I10.1 — Performance Insights; LXP Integration

**REQ-QNS-09.1 — Performance-Linked Recommendations**
- Questions are mapped to `slb_performance_categories` via `qns_question_performance_category_jnt`.
- Each mapping carries:
  - `performance_category_id` — FK to `slb_performance_categories`
  - `recommendation_type` — FK to `sys_dropdowns` (values: REVISION, PRACTICE, CHALLENGE)
  - `priority` — SMALLINT; ordering within a performance category
- This table directly powers personalized learning paths and LXP integration: students identified as "weak" in a topic receive REVISION questions; "average" students receive PRACTICE; "strong" students receive CHALLENGE questions.

---

### FR-QNS-10: Question Statistics ✅ (Model) / ❌ (Computation Service)

**RBS Ref:** F.I10.1 — AI-Based Examination Analytics

**REQ-QNS-10.1 — Statistical Metrics**
`qns_question_statistics` stores (one record per question, UNIQUE on `question_bank_id`):
- `difficulty_index` — DECIMAL(5,2): percentage of students who answered correctly (0–100). Low = hard, high = easy.
- `discrimination_index` — DECIMAL(5,2): difference in correct-answer rate between top-performing and bottom-performing student groups.
- `guessing_factor` — DECIMAL(5,2): MCQ-specific estimate of guessing contribution.
- `min_time_taken_seconds` / `max_time_taken_seconds` / `avg_time_taken_seconds` — response time metrics.
- `total_attempts` — INT UNSIGNED.
- `last_computed_at` — TIMESTAMP.

**REQ-QNS-10.2 — Computation Service (Gap — 📐 Required)**
- DDL note states: "Required a backend Service to calculate the statistics."
- A `QuestionStatisticsService` must be built to:
  1. Aggregate answer data from Quiz/Exam response tables (`quz_*`, `exm_*`).
  2. Compute the three statistical metrics per question.
  3. Upsert `qns_question_statistics` with updated values and `last_computed_at`.
- The service should be invokable on-demand (admin trigger via `POST /question-bank/{question}/statistics/compute`) and also scheduled (daily/weekly via the SCH_JOB module).
- Computation must never block the UI request cycle — run as a queued job.

**REQ-QNS-10.3 — Statistics View**
- `QuestionStatisticController@show` presents statistics for a single question.
- A dashboard-style analytics screen should show question bank-wide distribution of difficulty index and Bloom level.

---

### FR-QNS-11: Usage Logging ✅ (Model) / 🟡 (Written by consuming modules)

**REQ-QNS-11.1 — Usage Tracking**
- Every time a question is added to a quiz, quest, or exam, a `qns_question_usage_log` record is created by the consuming module (Quiz/Exam/Quest — NOT by the QuestionBank module itself).
- DDL note: "Display Only" — no CRUD UI in QuestionBank; records are created externally.
- Fields: `question_bank_id`, `question_usage_type` (FK to `qns_question_usage_type`), `context_id` (quiz_id / exam_id), `used_at`.

**REQ-QNS-11.2 — Usage Type Reference**
`qns_question_usage_type` is a pre-seeded lookup (seeded in DDL):

| Code | Name |
|------|------|
| QUIZ | LMS Quiz |
| QUEST | LMS Quest/Practice |
| ONLINE_EXAM | Online Examination |
| OFFLINE_EXAM | Offline Paper Exam |

**REQ-QNS-11.3 — Usage View in QuestionBank UI**
- Teachers can see "where has this question been used" — list of assessments with dates.
- This informs `BR-QNS-05` (only_unused_questions filter).

---

### FR-QNS-12: Bulk Import (Excel) 🟡 (Import classes exist, auth gap)

**REQ-QNS-12.1 — Excel Import Flow**
1. Teacher downloads the standard Excel template from `GET /question-bank/import-template`.
2. Teacher fills in questions in the template (one row per question, options in separate columns).
3. Teacher uploads via `POST /question-bank/import/validate` — triggers `QuestionReadOnly` for preview/validation.
4. System shows preview of parsed rows with any validation errors highlighted.
5. Teacher confirms import via `POST /question-bank/import/start` — triggers `QuestionImport` for actual creation.
6. All imported questions are created with `status = DRAFT` for review before use.

**REQ-QNS-12.2 — Import Validation Rules**
- Required fields per row: `ques_title`, `question_content`, `question_type_code`, `class_code`, `subject_code`, `lesson_code`, `topic_code`, `bloom_level`, `complexity_level`.
- `question_type_code` must match a valid `slb_question_types` record.
- Duplicate detection: flag rows where `ques_title` + `class_id` + `subject_id` combination already exists.
- Current implementation uses `LOWER()` for duplicate check — this prevents index use. Must be replaced with a hash-based approach.

**REQ-QNS-12.3 — Authorization Fix (Gap)**
- `validateFile()` and `startImport()` in `QuestionBankController` lack `Gate::authorize()`. Both must be protected.

---

### FR-QNS-13: Question Print ✅

**REQ-QNS-13.1 — Printable Question Paper**
- `QuestionBankController@print` generates a print-friendly view of a filtered set of questions.
- Loads school organization details (name, logo) for letterhead.
- Supports filter parameters (class, subject, Bloom level, complexity, status) to select question subset.
- Renders LATEX content correctly (MathJax must be included in print view head).
- Used by teachers to generate draft question paper layouts before formal exam configuration.

---

### FR-QNS-14: AI Question Generation ❌ (Interface stub — API keys not configured)

**RBS Ref:** F.I9.1 — Template Designer (AI-assisted content)

**REQ-QNS-14.1 — AI Generator Interface**
- Admin/Teacher opens `GET /question-bank/ai-generator` — displays a form with:
  - AI Provider selection (OpenAI GPT-4o-mini / Google Gemini 2.0 Flash)
  - Class, Subject, Lesson, Topic (cascading dropdowns)
  - Question Type, Bloom Level, Complexity Level, Cognitive Skill
  - Count of questions to generate (default 5, max 20)
- On form submit (`POST /question-bank/ai-generator/generate`), the system calls the selected AI provider API.
- The AI API response is parsed into structured question JSON matching the `qns_questions_bank` schema.
- Each generated question is saved as `status = DRAFT`, `created_by_AI = 1`.
- Teacher reviews the generated questions, edits if needed, and submits for approval.

**REQ-QNS-14.2 — Security Fix (P0 — CRITICAL)**

The current implementation has hardcoded API keys in `AIQuestionGeneratorController.php`. The required fix:

```php
// REMOVE from AIQuestionGeneratorController.php:
private $apiKeys = [
    'chatgpt' => 'Replace chatgpt key here',
    'gemini' => 'Replace Gemini key here'
];

// ADD to .env:
OPENAI_API_KEY=sk-...your-real-key...
GEMINI_API_KEY=AIzaSy...your-real-key...

// ADD to config/services.php:
'openai' => [
    'key' => env('OPENAI_API_KEY'),
    'default_model' => env('OPENAI_DEFAULT_MODEL', 'gpt-4o-mini'),
],
'gemini' => [
    'key' => env('GEMINI_API_KEY'),
    'default_model' => env('GEMINI_DEFAULT_MODEL', 'gemini-2.0-flash'),
],

// USE in AIQuestionService.php:
$apiKey = config('services.openai.key');
```

Both keys committed to the repository must be rotated immediately at:
- OpenAI: https://platform.openai.com/api-keys
- Gemini: https://aistudio.google.com/

**REQ-QNS-14.3 — AIQuestionService (Gap — 📐 Required)**
- Extract AI logic from `AIQuestionGeneratorController` into a dedicated `AIQuestionService`.
- The service accepts: `provider`, `prompt_params` (class, subject, topic, bloom_level, question_type, count).
- Builds a structured prompt incorporating the curriculum context for relevant question generation.
- Makes the HTTP call to the provider API using the key from `config('services.*.key')`.
- Parses the JSON response and returns an array of question DTOs.
- `generateQuestions()` in the controller currently returns `getDemoResponse()` — this stub must be removed and replaced with the real service call.

**REQ-QNS-14.4 — Authorization Fix (Gap — P0)**
- `AIQuestionGeneratorController` currently has ZERO authorization checks on all methods.
- All methods — `index()`, `getSections()`, `getSubjectGroups()`, `getSubjects()`, `getLessons()`, `getTopics()`, `generateQuestions()` — must call `Gate::authorize()`.
- Policy: `AiQuestionGeneratorPolicy` exists but is NOT enforced. Must be registered and called.

**REQ-QNS-14.5 — Rate Limiting (Gap)**
- AI generation endpoint `POST /question-bank/ai-generator/generate` has no rate limiting.
- Must be protected with a throttle middleware (e.g., `throttle:10,1` — max 10 requests per minute per user) to prevent runaway API costs.

**REQ-QNS-14.6 — FormRequest (Gap)**
- `generateQuestions()` uses inline `Validator::make()` — must be replaced with an `AIQuestionGenerateRequest` FormRequest class.

**REQ-QNS-14.7 — Remove Demo Data**
- `getDemoResponse()` method (lines 302–393 in `AIQuestionGeneratorController`) returns hardcoded question data.
- This method and the early return `return $this->getDemoResponse($request)` at line 224 must be removed.
- All dead code after that early return must also be removed.

**Acceptance Criteria:**
- Given an admin submits an AI generation request for 5 MCQ questions on "Photosynthesis" at Bloom Level 3, the system calls the configured AI provider and returns up to 5 DRAFT questions.
- Given an API key is not configured in `.env`, the system returns a user-friendly error: "AI provider not configured. Please contact administrator."
- Given a teacher attempts 11 AI generation requests in one minute, the 11th request is rate-limited with a 429 response.
- Given `config('services.openai.key')` is called, no literal API key string appears anywhere in source code.

---

## 5. Data Model

### 5.1 Overview — All qns_* Tables

| # | Table | Purpose | Rows |
|---|-------|---------|------|
| 1 | `qns_questions_bank` | Core question records | Many |
| 2 | `qns_question_options` | Answer options for MCQ/Match | Many |
| 3 | `qns_question_media_jnt` | Link questions/options to media | Junction |
| 4 | `qns_media_store` | Physical media file metadata | Many |
| 5 | `qns_question_tags` | Keyword tags | Few |
| 6 | `qns_question_questiontag_jnt` | Q ↔ Tag many-to-many | Junction |
| 7 | `qns_question_versions` | Full JSON snapshots on modification | Many |
| 8 | `qns_question_topic_jnt` | Multi-topic coverage mapping | Junction |
| 9 | `qns_question_statistics` | Computed difficulty/discrimination metrics | 1:1 with question |
| 10 | `qns_question_performance_category_jnt` | Q ↔ PerformanceCategory for LXP | Junction |
| 11 | `qns_question_usage_log` | Usage trail per quiz/exam | Log (insert-only) |
| 12 | `qns_question_review_log` | Approval/rejection audit trail | Log (insert-only) |
| 13 | `qns_question_usage_type` | Lookup: QUIZ/QUEST/ONLINE_EXAM/OFFLINE_EXAM | Reference (4 rows) |

### 5.2 Table: `qns_questions_bank` (Core)

| Column | Type | Default | Notes |
|--------|------|---------|-------|
| id | INT UNSIGNED PK | AUTO_INCREMENT | |
| uuid | BINARY(16) UNIQUE | — | UUID_TO_BIN(UUID()) on insert |
| class_id | INT UNSIGNED NOT NULL | — | FK sch_classes |
| subject_id | INT UNSIGNED NOT NULL | — | FK sch_subjects |
| lesson_id | INT UNSIGNED NOT NULL | — | FK slb_lessons |
| topic_id | INT UNSIGNED NOT NULL | — | FK slb_topics (primary) |
| competency_id | INT UNSIGNED NOT NULL | — | FK slb_competencies |
| ques_title | VARCHAR(255) NOT NULL | — | System title |
| ques_title_display | TINYINT(1) | 0 | Show title to student? |
| question_content | TEXT NOT NULL | — | Student-facing question |
| content_format | ENUM | TEXT | TEXT/HTML/MARKDOWN/LATEX/JSON |
| teacher_explanation | TEXT | NULL | Shown post-answer |
| bloom_id | INT UNSIGNED NOT NULL | — | FK slb_bloom_taxonomy |
| cognitive_skill_id | INT UNSIGNED NOT NULL | — | FK slb_cognitive_skill |
| ques_type_specificity_id | INT UNSIGNED NOT NULL | — | FK slb_ques_type_specificity |
| complexity_level_id | INT UNSIGNED NOT NULL | — | FK slb_complexity_level |
| question_type_id | INT UNSIGNED NOT NULL | — | FK slb_question_types |
| expected_time_to_answer_seconds | INT UNSIGNED | NULL | Optional time hint |
| marks | DECIMAL(5,2) | 1.00 | |
| negative_marks | DECIMAL(5,2) | 0.00 | |
| current_version | TINYINT UNSIGNED | 1 | Tracks latest version number |
| for_quiz | TINYINT(1) | 1 | Usage flag |
| for_assessment | TINYINT(1) | 0 | Usage flag |
| for_exam | TINYINT(1) | 0 | Usage flag |
| for_offline_exam | TINYINT(1) | 0 | Usage flag |
| ques_owner | ENUM | PrimeGurukul | PrimeGurukul / School |
| created_by_AI | TINYINT(1) | 0 | AI-generated flag |
| is_school_specific | TINYINT(1) | 0 | |
| availability | ENUM | GLOBAL | Visibility scope |
| selected_entity_group_id | INT UNSIGNED | NULL | FK slb_entity_groups |
| selected_section_id | INT UNSIGNED | NULL | FK sch_sections |
| selected_student_id | INT UNSIGNED | NULL | FK std_students |
| book_id | INT UNSIGNED | NULL | FK slb_books |
| book_page_ref | VARCHAR(50) | NULL | |
| external_ref | VARCHAR(100) | NULL | |
| reference_material | TEXT | NULL | |
| status | ENUM | DRAFT | DRAFT/IN_REVIEW/APPROVED/REJECTED/PUBLISHED/ARCHIVED |
| created_by | INT UNSIGNED | NULL | FK sys_users |
| is_active | TINYINT(1) | 1 | Soft filter |
| created_at / updated_at / deleted_at | TIMESTAMP | — | Standard audit |

**Indexes:** `idx_ques_uuid` (UNIQUE), `idx_ques_topic`, `idx_ques_competency`, `idx_ques_class_subject` (class_id, subject_id), `idx_ques_complexity_bloom` (complexity_level_id, bloom_id), `idx_ques_active`, `idx_ques_book`, `idx_ques_visibility` (availability).

### 5.3 Table: `qns_question_options`

| Column | Type | Notes |
|--------|------|-------|
| id | INT UNSIGNED PK | |
| question_bank_id | INT UNSIGNED NOT NULL | FK qns_questions_bank — CASCADE DELETE |
| ordinal | SMALLINT UNSIGNED | NULL — display order |
| option_text | TEXT NOT NULL | Option content |
| is_correct | TINYINT(1) | DEFAULT 0 |
| Explanation | TEXT | NULL — why correct/incorrect |
| is_active / created_at / updated_at / deleted_at | Standard | |

### 5.4 Table: `qns_question_media_jnt`

| Column | Type | Notes |
|--------|------|-------|
| id | INT UNSIGNED PK | |
| question_bank_id | INT UNSIGNED NOT NULL | FK qns_questions_bank — CASCADE |
| question_option_id | INT UNSIGNED | NULL — FK qns_question_options — CASCADE |
| media_purpose | ENUM | QUESTION/OPTION/QUES_EXPLANATION/OPT_EXPLANATION/RECOMMENDATION |
| media_id | INT UNSIGNED NOT NULL | FK qns_media_store — CASCADE |
| media_type | ENUM | IMAGE/AUDIO/VIDEO/ATTACHMENT |
| ordinal | SMALLINT UNSIGNED | DEFAULT 1 |

### 5.5 Table: `qns_media_store`

| Column | Type | Notes |
|--------|------|-------|
| id | INT UNSIGNED PK | |
| uuid | BINARY(16) UNIQUE | |
| owner_type | ENUM | QUESTION/OPTION/EXPLANATION/RECOMMENDATION |
| owner_id | INT UNSIGNED | Polymorphic owner |
| media_type | ENUM | IMAGE/AUDIO/VIDEO/PDF |
| file_name / file_path / mime_type | VARCHAR | |
| disk | VARCHAR(50) | NULL — local/s3 |
| size | INT UNSIGNED | NULL — bytes |
| checksum | CHAR(64) | NULL — SHA-256 for deduplication |
| ordinal | SMALLINT UNSIGNED | DEFAULT 1 |

### 5.6 Table: `qns_question_tags` / `qns_question_questiontag_jnt`

`qns_question_tags`: `id`, `short_name` (UNIQUE), `name`. Junction: `UNIQUE KEY (question_bank_id, tag_id)`.

### 5.7 Table: `qns_question_versions`

| Column | Type | Notes |
|--------|------|-------|
| id | INT UNSIGNED PK | |
| question_bank_id | INT UNSIGNED NOT NULL | FK — CASCADE DELETE |
| version | INT UNSIGNED NOT NULL | |
| data | JSON NOT NULL | Full snapshot: question + options + metadata |
| version_created_by | INT UNSIGNED | NULL |
| change_reason | VARCHAR(255) | NULL |
| UNIQUE KEY | (question_bank_id, version) | |

### 5.8 Table: `qns_question_topic_jnt`

| Column | Type | Notes |
|--------|------|-------|
| question_bank_id | INT UNSIGNED | FK — CASCADE |
| topic_id | INT UNSIGNED | FK slb_topics — CASCADE |
| weightage | DECIMAL(5,2) | DEFAULT 100.00 |
| UNIQUE KEY | (question_bank_id, topic_id) | |

### 5.9 Table: `qns_question_statistics`

| Column | Type | Notes |
|--------|------|-------|
| question_bank_id | INT UNSIGNED UNIQUE | FK — CASCADE |
| difficulty_index | DECIMAL(5,2) | % students correct |
| discrimination_index | DECIMAL(5,2) | Top-bottom delta |
| guessing_factor | DECIMAL(5,2) | MCQ only |
| min/max/avg_time_taken_seconds | INT UNSIGNED | Response times |
| total_attempts | INT UNSIGNED | DEFAULT 0 |
| last_computed_at | TIMESTAMP | |

### 5.10 Table: `qns_question_performance_category_jnt`

| Column | Type | Notes |
|--------|------|-------|
| question_bank_id | INT UNSIGNED | FK — CASCADE |
| performance_category_id | INT UNSIGNED | FK slb_performance_categories — CASCADE |
| recommendation_type | INT UNSIGNED | FK sys_dropdowns (REVISION/PRACTICE/CHALLENGE) |
| priority | SMALLINT UNSIGNED | DEFAULT 1 |
| UNIQUE KEY | (question_bank_id, performance_category_id) | |

### 5.11 Table: `qns_question_usage_log` (Insert-Only)

| Column | Type | Notes |
|--------|------|-------|
| question_bank_id | INT UNSIGNED | FK — CASCADE |
| question_usage_type | INT UNSIGNED | FK qns_question_usage_type |
| context_id | INT UNSIGNED | quiz_id / exam_id |
| used_at | TIMESTAMP | |

**DDL Note:** FK constraint references column `usage_context` but the column is named `question_usage_type` — this is a DDL bug that must be corrected.

### 5.12 Table: `qns_question_review_log` (Insert-Only)

| Column | Type | Notes |
|--------|------|-------|
| review_log_id | INT UNSIGNED PK | |
| question_id | INT UNSIGNED | FK qns_questions_bank — CASCADE |
| reviewer_id | INT UNSIGNED | FK sys_users — CASCADE |
| review_status_id | INT UNSIGNED | FK sys_dropdown_table — CASCADE |
| review_comment | TEXT | NULL |
| reviewed_at | DATETIME NOT NULL | |

### 5.13 Table: `qns_question_usage_type` (Seeded Reference)

Pre-seeded with 4 rows: QUIZ, QUEST, ONLINE_EXAM, OFFLINE_EXAM. Has `code` (UNIQUE) and `name` (UNIQUE).

---

## 6. API Endpoints & Routes

### 6.1 Current Route State (Gap)

The module routes are declared in `/Modules/QuestionBank/routes/web.php` but most sub-resources are missing from the web route file. The main routes appear in `/routes/tenant.php` at line 962 with only `['auth', 'verified']` middleware — `EnsureTenantHasModule` middleware is absent.

### 6.2 Required Route Structure

```php
// Middleware group — ALL question-bank routes must include:
Route::middleware(['auth', 'verified', 'EnsureTenantHasModule:QNS'])
    ->prefix('question-bank')
    ->name('question-bank.')
    ->group(function () {

    // Core Question CRUD
    Route::get('/',                     [QuestionBankController::class, 'index'])    ->name('index');
    Route::get('/create',               [QuestionBankController::class, 'create'])   ->name('create');
    Route::post('/',                    [QuestionBankController::class, 'store'])    ->name('store');
    Route::get('/{question}',           [QuestionBankController::class, 'show'])     ->name('show');
    Route::get('/{question}/edit',      [QuestionBankController::class, 'edit'])     ->name('edit');
    Route::put('/{question}',           [QuestionBankController::class, 'update'])   ->name('update');
    Route::delete('/{question}',        [QuestionBankController::class, 'destroy'])  ->name('destroy');

    // Print
    Route::get('/print',                [QuestionBankController::class, 'print'])    ->name('print');

    // Import
    Route::post('/import/validate',     [QuestionBankController::class, 'validateFile'])  ->name('import.validate');
    Route::post('/import/start',        [QuestionBankController::class, 'startImport'])   ->name('import.start');
    Route::get('/import/template',      [QuestionBankController::class, 'importTemplate'])->name('import.template');

    // Review Workflow
    Route::post('/{question}/submit-review', [QuestionReviewController::class, 'submit'])  ->name('review.submit');
    Route::post('/{question}/approve',       [QuestionReviewController::class, 'approve']) ->name('review.approve');
    Route::post('/{question}/reject',        [QuestionReviewController::class, 'reject'])  ->name('review.reject');
    Route::post('/{question}/publish',       [QuestionReviewController::class, 'publish']) ->name('review.publish');
    Route::post('/{question}/archive',       [QuestionReviewController::class, 'archive']) ->name('review.archive');

    // Tags
    Route::resource('tags', QuestionTagController::class)->names('tags');

    // Versions
    Route::get('/{question}/versions',      [QuestionVersionController::class, 'index'])  ->name('versions.index');
    Route::get('/{question}/versions/{v}',  [QuestionVersionController::class, 'show'])   ->name('versions.show');

    // Statistics
    Route::get('/{question}/statistics',          [QuestionStatisticController::class, 'show'])    ->name('statistics.show');
    Route::post('/{question}/statistics/compute', [QuestionStatisticController::class, 'compute']) ->name('statistics.compute');

    // Usage Logs
    Route::get('/{question}/usage', [QuestionBankController::class, 'usageLogs'])->name('usage.index');

    // Media Store
    Route::resource('media', QuestionMediaStoreController::class)->names('media');

    // AI Generator
    Route::get('/ai-generator',          [AIQuestionGeneratorController::class, 'index'])          ->name('ai.index');
    Route::post('/ai-generator/generate',[AIQuestionGeneratorController::class, 'generateQuestions'])->name('ai.generate');
    Route::get('/ai-generator/sections', [AIQuestionGeneratorController::class, 'getSections'])    ->name('ai.sections');
    Route::get('/ai-generator/subjects', [AIQuestionGeneratorController::class, 'getSubjects'])    ->name('ai.subjects');
    Route::get('/ai-generator/lessons',  [AIQuestionGeneratorController::class, 'getLessons'])     ->name('ai.lessons');
    Route::get('/ai-generator/topics',   [AIQuestionGeneratorController::class, 'getTopics'])      ->name('ai.topics');
});
```

### 6.3 Route Security Requirements

| Route | Required Gate | Current Status |
|-------|--------------|----------------|
| All question-bank routes | `EnsureTenantHasModule:QNS` | ❌ Missing |
| `index`, `print`, `validateFile`, `startImport` | `tenant.question-bank.viewAny` | ❌ Missing |
| All AI generator routes | `tenant.ai-question-generator.*` | ❌ Missing |
| Media store routes | `tenant.question-media.*` | 🟡 Wrong policy name |

---

## 7. UI Screens

| Screen ID | Screen Name | Status | Notes |
|-----------|-------------|--------|-------|
| SCR-QNS-01 | Question Bank List (Tab View) | 🟡 Partial | Multi-tab view with filters; auth gap |
| SCR-QNS-02 | Create Question | 🟡 Partial | Form exists; all 6 types need full UI |
| SCR-QNS-03 | Edit Question | 🟡 Partial | Same form as create |
| SCR-QNS-04 | Question Detail / Show | 🟡 Partial | With media display and taxonomy info |
| SCR-QNS-05 | Print Question Paper | ✅ | Implemented; ensure LaTeX rendering |
| SCR-QNS-06 | AI Question Generator | 🟡 Form only | UI complete; generation is stub |
| SCR-QNS-07 | AI Generated Questions Review | ❌ | Must be built post-AI fix |
| SCR-QNS-08 | Tags Management | 🟡 | Controller exists; routes missing |
| SCR-QNS-09 | Version History | 🟡 | Controller exists; routes missing |
| SCR-QNS-10 | Question Statistics | 🟡 | Controller exists; routes missing |
| SCR-QNS-11 | Usage Logs (per question) | ❌ | Model only; no view |
| SCR-QNS-12 | Excel Import (validate + confirm) | 🟡 | Import classes exist; auth gap |
| SCR-QNS-13 | Review / Approval Queue | ❌ | No dedicated controller or view |
| SCR-QNS-14 | Question Bank Analytics Dashboard | ❌ | Not started |

### 7.1 Screen: Question Bank List (SCR-QNS-01)

- Tab-based layout: All / By Class / By Subject / AI-Generated / Pending Review / Published.
- Filter panel: Class, Subject, Lesson, Topic, Bloom Level, Complexity, Question Type, Status, Tags, Owner.
- Table columns: Title, Type, Bloom, Complexity, Status, Marks, Created By, Created At, Actions.
- Pagination: 20 items per page; indexed queries via `idx_ques_class_subject` + `idx_ques_complexity_bloom`.
- Bulk actions: Bulk approve, bulk archive (admin only).

### 7.2 Screen: Create/Edit Question (SCR-QNS-02/03)

- Section 1 — Curriculum Anchoring: cascading dropdowns Class → Subject → Lesson → Topic → Competency.
- Section 2 — Question Content: Rich text editor (Quill/TinyMCE) with LATEX toggle (MathJax preview).
- Section 3 — Question Type Selection: switching type updates the Options section dynamically.
- Section 4 — Answer Options (shown for MCQ/Match): add/remove option rows; checkboxes for is_correct.
- Section 5 — Taxonomy Tags: Bloom level, Cognitive Skill, Complexity, Type Specificity — all required.
- Section 6 — Assessment Metadata: marks, negative marks, expected time, usage flags.
- Section 7 — Availability & Ownership: availability scope; conditional fields for section/entity/student.
- Section 8 — Reference Source: book, page ref, external ref.
- Section 9 — Media Attachments: upload images/audio per question and per option.
- Section 10 — Tags: autocomplete tag search and multi-select.

---

## 8. Business Rules

**BR-QNS-01 (Taxonomy Completeness):** A question cannot be submitted for review unless ALL taxonomy fields are populated: `bloom_id`, `cognitive_skill_id`, `ques_type_specificity_id`, `complexity_level_id`, `question_type_id`. Validation enforced in `QuestionBankRequest`.

**BR-QNS-02 (MCQ Correct Option):** For MCQ question types (`question_type_id` maps to MCQ or MCQ_MULTI), at least one option must have `is_correct = 1`. The system shall validate this on save and on review submission.

**BR-QNS-03 (Status-Gated Assessment Use):** Only questions with `status = APPROVED` or `status = PUBLISHED` may be added to quizzes, exams, or quests. DRAFT, IN_REVIEW, REJECTED, and ARCHIVED questions are excluded from all assessment pickers.

**BR-QNS-04 (Usage Flag Filtering):** When a quiz/exam configuration uses `only_authorised_questions = 1`, only questions with the corresponding usage flag set (`for_quiz = 1`, `for_exam = 1`, etc.) are eligible.

**BR-QNS-05 (Unused Question Filtering):** When `only_unused_questions = 1` is set in an assessment, the system cross-references `qns_question_usage_log` by `question_usage_type` to exclude questions already used in the same context.

**BR-QNS-06 (Availability Scope Enforcement):** `availability = GLOBAL` means visible to all teachers. `SCHOOL_ONLY` restricts to the school's tenant. `CLASS_ONLY` restricts to the question's `class_id`. `SECTION_ONLY` restricts to `selected_section_id`. `ENTITY_ONLY` restricts to `selected_entity_group_id`. `STUDENT_ONLY` restricts to `selected_student_id`. The question list query must apply these scope filters based on the authenticated user's context.

**BR-QNS-07 (PrimeGurukul Ownership Protection):** Questions with `ques_owner = PrimeGurukul` cannot be modified by school teachers. They may only use these questions in assessments or duplicate them as `ques_owner = School` questions for customization. Edit/delete actions on PrimeGurukul-owned questions must be blocked by policy.

**BR-QNS-08 (AI-Generated Question Review Gate):** Questions with `created_by_AI = 1` must go through the full review/approval workflow before use in any formal assessment. The system must not skip the review requirement for AI-generated questions, even if the teacher is an admin.

**BR-QNS-09 (Version Snapshot Triggers):** A version snapshot is created on modification of any of: `question_content`, `content_format`, `question_type_id`, `marks`, `negative_marks`, or any answer option's `option_text` or `is_correct`. Pure status changes do not trigger versioning.

**BR-QNS-10 (Negative Marks Constraint):** `negative_marks` must satisfy `0 <= negative_marks < marks`. Setting `negative_marks = 0` disables negative marking for that question. Validated in `QuestionBankRequest`.

**BR-QNS-11 (Rejection Comment Required):** When a reviewer rejects a question (status → REJECTED), a `review_comment` must be provided. The system must enforce this at the controller/FormRequest level.

**BR-QNS-12 (Topic Weightage Sum):** When multiple topics are mapped via `qns_question_topic_jnt`, the sum of all `weightage` values for a question should equal 100. Enforced with a soft warning (not a hard error) on save.

---

## 9. Workflows

### 9.1 Question Lifecycle State Machine

```
[Created / Imported / AI-Generated]
          |
          v
        DRAFT ──────────────────────────────────────────────┐
          |                                                   |
          | Teacher clicks "Submit for Review"               | Teacher revises after rejection
          v                                                   |
       IN_REVIEW                                             |
          |                                                   |
          |──[Reviewer Approves]──>  APPROVED                |
          |                              |                    |
          |──[Reviewer Rejects]──>  REJECTED ────────────────┘
                                         (review_log entry with mandatory comment)
                                    APPROVED
                                         |
                                         | Admin clicks "Publish"
                                         v
                                     PUBLISHED ──> [Retire] ──> ARCHIVED
                                         |
                                    (available in assessments)

Notes:
- Admin can shortcut DRAFT → APPROVED for trusted content.
- ARCHIVED is terminal — no transitions out.
- Only APPROVED and PUBLISHED questions are selectable in Quiz/Exam builders.
- AI-generated questions (created_by_AI=1) cannot bypass the IN_REVIEW stage.
```

### 9.2 AI Question Generation Flow

```
Teacher opens AI Generator (GET /question-bank/ai-generator)
    |
    | Gate::authorize('tenant.ai-question-generator.viewAny')
    v
Form: Select Provider + Class + Subject + Lesson + Topic
       + Question Type + Bloom Level + Complexity + Count
    |
    | POST /question-bank/ai-generator/generate
    v
AIQuestionGenerateRequest (FormRequest validation)
    |
    v
Throttle check (max 10 per minute per user)
    |
    v
AIQuestionService::generate(provider, params)
    |   Loads API key: config('services.openai.key') OR config('services.gemini.key')
    |   Builds curriculum-aware structured prompt
    |   Makes HTTP call to AI provider API
    |   Parses JSON response
    v
For each generated question:
    QuestionBankService::createFromAI(questionData)
    → qns_questions_bank INSERT (status=DRAFT, created_by_AI=1)
    → qns_question_options INSERT (if MCQ)
    v
Response: list of created DRAFT question IDs + titles
    |
    v
Teacher reviews each generated question on SCR-QNS-07
    |── Edit fields as needed
    |── Submit each for review (→ IN_REVIEW)
    v
Normal review workflow proceeds
```

### 9.3 Excel Bulk Import Flow

```
Teacher downloads import template (GET /question-bank/import/template)
    |
    v
Teacher fills template (one row per question) and uploads
    |
    | POST /question-bank/import/validate
    v
Gate::authorize('tenant.question-bank.import')
    |
    v
QuestionReadOnly (maatwebsite/excel) — preview/validation pass
    → Parse rows
    → Validate required fields, valid enum values, foreign key codes
    → Flag duplicates
    v
Preview screen: rows with status (valid / invalid / duplicate)
    |
    | Teacher reviews, optionally removes invalid rows
    | POST /question-bank/import/start (session token)
    v
Gate::authorize('tenant.question-bank.import')
    |
    v
QuestionImport (maatwebsite/excel) — actual creation
    → All valid rows → qns_questions_bank (status=DRAFT)
    v
Success message: "X questions imported, Y skipped"
```

### 9.4 Question Statistics Computation Flow

```
[Question used in Quiz / Exam / Quest]
    |
    | Consuming module (Quiz/Exam/Quest) creates:
    v
qns_question_usage_log INSERT (context_id = quiz_id/exam_id)
    |
    | [Scheduled Job — daily/weekly via SCH_JOB]
    v
QuestionStatisticsService::computeForQuestion(question_id)
    → Aggregate student answers from quz_*/exm_* response tables
    → Calculate difficulty_index: correct_answers / total_attempts * 100
    → Calculate discrimination_index: top_27%_correct_rate - bottom_27%_correct_rate
    → Calculate guessing_factor (MCQ): apply formula based on # options
    → Aggregate time metrics (min/max/avg)
    v
qns_question_statistics UPSERT (by question_bank_id)
    → Update last_computed_at
    v
Admin can also trigger on-demand:
    POST /question-bank/{question}/statistics/compute
    → Dispatches QuestionStatisticsComputeJob to queue
```

---

## 10. Non-Functional Requirements

**NFR-QNS-01 (Security — P0 CRITICAL):** OpenAI and Gemini API keys must be removed from all source code immediately. Both keys are committed to the repository and must be considered compromised — rotate them now. New keys must be stored in `.env` only and accessed via `config('services.openai.key')` and `config('services.gemini.key')`. See Section 14 and Appendix B for the exact remediation procedure. **Zero tolerance — this blocks production deployment.**

**NFR-QNS-02 (Security — P0):** `AIQuestionGeneratorController` must implement `Gate::authorize()` on all 7 methods before any production use. The `AiQuestionGeneratorPolicy` exists but is not enforced. An unauthenticated call to `POST /question-bank/ai-generator/generate` must return 403.

**NFR-QNS-03 (Security — P0):** `QuestionBankController@index`, `@print`, `@validateFile`, and `@startImport` lack authorization guards. All four must have `Gate::authorize()` added before production deployment.

**NFR-QNS-04 (Security — P1):** `QuestionMediaStoreController` references `tenant.competency.*` policy — a copy-paste error. All policy gate references must be corrected to `tenant.question-media.*` to match `QuestionMediaStorePolicy`.

**NFR-QNS-05 (Security — P1):** The `EnsureTenantHasModule` middleware must be added to the question-bank route group to prevent unauthorized module access when a tenant has not licensed the QNS module.

**NFR-QNS-06 (Rate Limiting — P1):** The AI generation endpoint `POST /question-bank/ai-generator/generate` must be protected with a throttle middleware of maximum 10 requests per user per minute. Exceeding this limit returns HTTP 429. This prevents runaway API costs in the event of a loop or abuse.

**NFR-QNS-07 (Performance):** The question bank listing must support pagination (20 per page) with indexed filtering. The compound indexes `idx_ques_class_subject` and `idx_ques_complexity_bloom` must be leveraged in `getQuestionBank()` queries. The current `QuestionBank::get()` (no pagination) seen in `LmsExamController` at line 61 must be refactored to `paginate()` or a scoped query.

**NFR-QNS-08 (Performance):** Filter dropdown data (Bloom levels, complexity levels, question types, cognitive skills) must be cached (e.g., `Cache::remember()` with 1-hour TTL) in `QuestionBankController::getFilterData()`. These reference tables rarely change.

**NFR-QNS-09 (Performance):** The duplicate-check query in `validateFile()` currently uses `LOWER()` which prevents index use on `ques_title`. Replace with a SHA-256 hash stored as an indexed column, or use a case-insensitive collation index.

**NFR-QNS-10 (Performance — Scalability):** The question bank may grow to 100,000+ records in large schools. Statistics computation must be an offline scheduled job (never computed on-the-fly per HTTP request). The `QuestionStatisticsService` must dispatch a queued job via Laravel's queue system.

**NFR-QNS-11 (Data Integrity — UUID):** The `uuid` BINARY(16) field requires explicit MySQL conversion: `UUID_TO_BIN(UUID())` on insert, `BIN_TO_UUID(uuid)` on read. The `QuestionBank` Eloquent model must use a UUID cast (`Illuminate\Database\Eloquent\Casts\AsStringable` or a custom cast) to handle this transparently. Direct string assignment without conversion will silently corrupt the binary value.

**NFR-QNS-12 (Rendering — LaTeX):** When `content_format = LATEX`, the question view, edit preview, print, and all assessment delivery screens must include MathJax or KaTeX JavaScript library. This must be conditionally loaded when any question in scope has `content_format = LATEX`.

**NFR-QNS-13 (Media Storage):** Question media files (especially audio and video) may be large. The `qns_media_store.disk` field supports multiple storage backends. S3 or equivalent object storage must be used for media in production deployments. Local disk is acceptable for development only.

**NFR-QNS-14 (Code Quality — Service Layer):** `QuestionBankController` is currently ~1,400 lines — a fat controller anti-pattern. A `QuestionBankService` must be extracted containing: `createQuestion()`, `updateQuestion()`, `createVersionSnapshot()`, `submitForReview()`, `approveQuestion()`, `rejectQuestion()`, `publishQuestion()`, `computeAvailabilityScope()`. This refactoring is P2 priority.

**NFR-QNS-15 (Code Quality — Duplicate Model):** Both `QuestionStatistic` and `QuestionStatistics` model files exist. One is a duplicate. The correct model is `QuestionStatistic` (singular, matching Laravel convention). `QuestionStatistics` must be identified and removed after confirming it has no active references.

**NFR-QNS-16 (Code Quality — Duplicate Policy):** Both `AIQuestionPolicy` and `AiQuestionGeneratorPolicy` exist. One is dead code. Determine which is correct (`AiQuestionGeneratorPolicy` per the gap analysis), remove the duplicate, and update all references.

---

## 11. Cross-Module Dependencies

| Module | Direction | Purpose | Impact if Missing |
|--------|-----------|---------|-------------------|
| Syllabus (slb_*) | Consumed by QNS | Bloom taxonomy, question types, cognitive skills, complexity levels, topics, lessons, competencies, performance categories, entity groups, books | Question creation impossible without syllabus data |
| SchoolSetup (sch_*) | Consumed by QNS | Classes, sections, subjects | Cannot anchor questions to curriculum |
| StudentProfile (std_*) | Consumed by QNS | std_students (for STUDENT_ONLY availability) | STUDENT_ONLY questions cannot be scoped |
| SystemConfig (sys_*) | Consumed by QNS | sys_users (ownership/review), sys_dropdown_table (review status) | Review workflow broken |
| Quiz / LMS (quz_*) | Provides to QNS | Writes qns_question_usage_log entries; reads for_quiz=1 questions | Usage tracking incomplete |
| Quest / Practice | Provides to QNS | Writes qns_question_usage_log (QUEST type); reads for_assessment=1 | Same |
| Examination (exm_*) | Provides to QNS | Writes qns_question_usage_log; reads for_exam/for_offline_exam | Same |
| Examination (exm_*) | Provides data to QNS | Student answer records used by QuestionStatisticsService for computation | Statistics computation requires exam responses |
| Recommendation (rec_*) | Consumes QNS | Reads qns_question_performance_category_jnt for personalized learning path questions | LXP personalization broken without this mapping |
| Scheduler (SCH_JOB) | Triggers QNS | Schedules QuestionStatisticsComputeJob daily/weekly | Statistics go stale |
| Notification (NTF) | Triggered by QNS | Notify reviewer on submission; notify teacher on approval/rejection | Manual notification only |
| OpenAI API | External | GPT-4o-mini model for AI question generation | AI generation unavailable |
| Google Gemini API | External | Gemini 2.0 Flash for AI question generation | AI generation unavailable |
| maatwebsite/laravel-excel | Package | Excel import (QuestionImport, QuestionReadOnly) | Bulk import unavailable |

---

## 12. Test Scenarios

**Current state: 0 tests exist across all test types.**

| Test ID | Name | Type | Priority | Description |
|---------|------|------|----------|-------------|
| T-QNS-01 | QuestionBankCrudTest | Feature | P0 | Full create/read/update/delete lifecycle for a question |
| T-QNS-02 | QuestionStatusWorkflowTest | Feature | P0 | DRAFT → IN_REVIEW → APPROVED → PUBLISHED state machine |
| T-QNS-03 | TaxonomyRequiredFieldsTest | Unit | P0 | Validation fails without bloom_id, cognitive_skill_id, complexity_level_id |
| T-QNS-04 | MCQCorrectOptionTest | Unit | P0 | Validation fails for MCQ with zero is_correct options |
| T-QNS-05 | AIKeySecurityTest | Unit | P0 | Assert no literal API key string in AIQuestionGeneratorController |
| T-QNS-06 | AIEndpointAuthTest | Feature | P0 | Unauthenticated POST to /ai-generator/generate returns 403 |
| T-QNS-07 | QuestionBankAuthTest | Feature | P0 | index/print/validateFile/startImport return 403 without auth |
| T-QNS-08 | TenantModuleMiddlewareTest | Feature | P0 | Tenant without QNS module license gets 403 on all routes |
| T-QNS-09 | QuestionVersioningTest | Feature | P1 | Content edit creates version snapshot; status change does not |
| T-QNS-10 | ReviewWorkflowTest | Feature | P1 | Submit/approve/reject creates review_log; reject requires comment |
| T-QNS-11 | QuestionAvailabilityScopeTest | Unit | P1 | GLOBAL shows to all; CLASS_ONLY filtered by class_id |
| T-QNS-12 | PrimeGurukulOwnershipTest | Feature | P1 | School teacher cannot edit PrimeGurukul-owned question |
| T-QNS-13 | AIGeneratedReviewGateTest | Feature | P1 | AI-generated question cannot be added to exam without APPROVED status |
| T-QNS-14 | NegativeMarksValidationTest | Unit | P1 | negative_marks >= marks fails validation |
| T-QNS-15 | QuestionImportTest | Feature | P1 | Excel import creates DRAFT questions with correct taxonomy |
| T-QNS-16 | ImportDuplicateDetectionTest | Feature | P1 | Duplicate title+class+subject flagged in import preview |
| T-QNS-17 | MediaAttachmentTest | Feature | P1 | Image upload links to question via qns_question_media_jnt |
| T-QNS-18 | MediaChecksumDeduplicationTest | Unit | P1 | Same file uploaded twice reuses existing media_store record |
| T-QNS-19 | UsageLoggingTest | Feature | P1 | Usage log created when quiz module uses question |
| T-QNS-20 | StatisticsComputationTest | Unit | P2 | difficulty_index = correct_count / total_attempts * 100 |
| T-QNS-21 | StatisticsJobDispatchTest | Feature | P2 | /statistics/compute dispatches queued job (not sync) |
| T-QNS-22 | AIRateLimitTest | Feature | P1 | 11th AI generation request in 1 minute returns HTTP 429 |
| T-QNS-23 | UUIDCastTest | Unit | P1 | QuestionBank model stores/retrieves uuid correctly via BIN/UUID conversion |
| T-QNS-24 | MediaPolicyCorrectionTest | Feature | P1 | QuestionMediaStoreController uses question-media.* policy (not competency.*) |
| T-QNS-25 | TagCrudTest | Feature | P2 | Create/edit/delete tags; assign to question |

**Testing Framework:** Pest PHP syntax; Feature tests extend `Tests\TestCase` with `RefreshDatabase`; Unit tests are framework-free where possible.

---

## 13. Glossary

| Term | Definition |
|------|-----------|
| Bloom's Taxonomy | 6-level cognitive classification system: 1-Remember, 2-Understand, 3-Apply, 4-Analyze, 5-Evaluate, 6-Create. Used to ensure balanced cognitive coverage across assessments. |
| Cognitive Skill | The specific mental process a question requires: Recall, Comprehension, Application, Critical Thinking, Creative Thinking. More granular than Bloom level. |
| Complexity Level | User-facing difficulty label: Easy / Medium / Hard / Very Hard. A teacher's intuitive rating distinct from formal cognitive taxonomy. |
| Question Type Specificity | Sub-classification within a question type. For MCQ: Single-Correct vs Multi-Correct vs Assertion-Reason. For Essay: Analytical vs Descriptive. |
| Difficulty Index | The percentage of students who answered a question correctly. Values near 0 = very hard; near 100 = very easy. Range: 0–100. |
| Discrimination Index | The difference in correct-answer rate between top 27% and bottom 27% of students by score. Positive value = question discriminates well. Negative = poor question. |
| Guessing Factor | MCQ-specific metric estimating how much of the correct-answer rate is due to random guessing based on the number of options. |
| Competency | A specific learning outcome mapped to a topic in the syllabus. Questions target specific competencies. |
| Availability Scope | Controls who can view and use a question: GLOBAL (all tenants), SCHOOL_ONLY, CLASS_ONLY, SECTION_ONLY, ENTITY_ONLY, STUDENT_ONLY. |
| Usage Log | An immutable record created by Quiz/Exam/Quest modules each time a question is used in an assessment. |
| Version Snapshot | A full JSON copy of a question's state (fields + options + metadata) stored before a content modification. Enables rollback and audit. |
| PrimeGurukul | The platform owner. Questions with `ques_owner = PrimeGurukul` are master content, read-only for school teachers. |
| DRAFT | Initial question status. Editable. Not available in assessments. |
| PUBLISHED | Final active status. Approved and made available to all eligible assessments. |
| created_by_AI | Flag (`TINYINT 1`) indicating a question was generated by an AI provider rather than authored manually. |
| Media Purpose | Context enum on `qns_question_media_jnt` indicating where the media is used: on the question itself, on an option, in an explanation, or for a recommendation. |
| Performance Category | A classification of student performance level (e.g., Weak/Average/Strong) from `slb_performance_categories`. Used to match students with appropriate practice questions. |

---

## 14. Suggestions & Analyst Notes

### P0 — Security (Act Immediately)

1. **Rotate API keys NOW.** OpenAI key and Gemini key in `AIQuestionGeneratorController.php` are committed to the repository. Even though they appear as placeholder strings (the gap analysis identified partial masking), treat them as compromised. Rotate at https://platform.openai.com/api-keys and https://aistudio.google.com/.

2. **Move keys to `.env`.** Add to `.env`:
   ```
   OPENAI_API_KEY=sk-...
   GEMINI_API_KEY=AIzaSy...
   ```
   Add to `config/services.php`:
   ```php
   'openai' => ['key' => env('OPENAI_API_KEY'), 'default_model' => 'gpt-4o-mini'],
   'gemini' => ['key' => env('GEMINI_API_KEY'), 'default_model' => 'gemini-2.0-flash'],
   ```
   Remove `private $apiKeys = [...]` from `AIQuestionGeneratorController` entirely.

3. **Add `Gate::authorize()` to `AIQuestionGeneratorController`** — all 7 methods. Use `AiQuestionGeneratorPolicy`. This controller currently has zero authorization, meaning any authenticated user can trigger AI API calls.

4. **Add `Gate::authorize()` to `QuestionBankController@index`, `@print`, `@validateFile`, `@startImport`.**

5. **Add `EnsureTenantHasModule:QNS` to the route group middleware stack.**

### P1 — Fix Before Release

6. **Fix `QuestionMediaStoreController` policy references.** Replace all `tenant.competency.*` with `tenant.question-media.*`. This is a copy-paste bug from the Syllabus module.

7. **Remove `getDemoResponse()` stub** from `AIQuestionGeneratorController` (lines 302–393) and the early return `return $this->getDemoResponse($request)` at line 224. Dead code below that return must also be removed.

8. **Build `AIQuestionService`** — extract AI provider HTTP calls from the controller into a testable service class. Implement structured prompts that include board, class, subject, topic, and Bloom level context for higher-quality generated questions.

9. **Replace inline `Validator::make()` in `generateQuestions()`** with a proper `AIQuestionGenerateRequest` FormRequest class.

10. **Add throttle middleware** to the AI generation route: `throttle:10,1`.

11. **Add activity logging** (`activityLog()` calls) to `AIQuestionGeneratorController` and `QuestionBankController` — currently absent.

12. **Fix DDL bug in `qns_question_usage_log`** — the CONSTRAINT references column `usage_context` but the column is named `question_usage_type`. This must be corrected in the migration.

### P2 — Quality & Performance

13. **Extract `QuestionBankService`** from the 1,400-line `QuestionBankController`. Key methods: `createQuestion()`, `updateQuestion()`, `createVersionSnapshot()`, `submitForReview()`, `approveQuestion()`, `rejectQuestion()`.

14. **Implement `QuestionStatisticsService`** with a queued job. Aggregate answers from `quz_*` and `exm_*` response tables. Schedule via SCH_JOB module.

15. **Build `QuestionReviewController`** (or add review methods to QuestionBankController) with dedicated routes for the review workflow. Add email/in-app notifications to the reviewer on submission and to the teacher on approval/rejection.

16. **Implement question duplication feature** — a teacher can click "Duplicate" on a PrimeGurukul-owned question to create a school-owned copy with `ques_owner = School` and `status = DRAFT`, allowing customization.

17. **Fix UUID binary handling** in the `QuestionBank` model — add a custom Eloquent cast so that `$question->uuid` always returns a readable UUID string, not raw binary.

18. **Add caching to `getFilterData()`** — Bloom levels, complexity levels, cognitive skills, question types change rarely. Use `Cache::remember('qns.filter_data', 3600, fn() => ...)`.

19. **Replace `LOWER()` duplicate check** in `validateFile()` with a deterministic hash index or rely on the database collation for case-insensitive comparison.

### P3 — Analytics & Future Enhancements

20. **Question Bank Analytics Dashboard** (SCR-QNS-14) — Bloom level distribution pie chart, complexity distribution, questions per subject, usage frequency heatmap, AI-generated vs manual ratio.

21. **Question Paper Template Builder** — admin can define a paper template (e.g., Section A: 10 MCQ Easy, Section B: 5 SA Medium) and the system auto-selects questions matching the criteria from the approved pool.

22. **Batch AI Generation with Queue** — for large generation requests (count > 20), dispatch an async job and notify the teacher when complete, rather than blocking the HTTP request.

23. **Remove `QuestionStatistics` duplicate model** (keep `QuestionStatistic` singular) and remove the duplicate `AIQuestionPolicy` (keep `AiQuestionGeneratorPolicy`).

24. **Write a minimum of 25 test cases** (mapped to Test Scenarios in Section 12), targeting at least 70% coverage of `QuestionBankController` and `AIQuestionGeneratorController`.

---

## 15. Appendices

### Appendix A: Key File Paths

| File | Path |
|------|------|
| AIQuestionGeneratorController | `Modules/QuestionBank/app/Http/Controllers/AIQuestionGeneratorController.php` |
| QuestionBankController | `Modules/QuestionBank/app/Http/Controllers/QuestionBankController.php` |
| QuestionMediaStoreController | `Modules/QuestionBank/app/Http/Controllers/QuestionMediaStoreController.php` |
| QuestionStatisticController | `Modules/QuestionBank/app/Http/Controllers/QuestionStatisticController.php` |
| QuestionTagController | `Modules/QuestionBank/app/Http/Controllers/QuestionTagController.php` |
| QuestionVersionController | `Modules/QuestionBank/app/Http/Controllers/QuestionVersionController.php` |
| QuestionUsageTypeController | `Modules/QuestionBank/app/Http/Controllers/QuestionUsageTypeController.php` |
| QuestionBank Model | `Modules/QuestionBank/app/Models/QuestionBank.php` |
| QuestionVersion Model | `Modules/QuestionBank/app/Models/QuestionVersion.php` |
| QuestionStatistic Model | `Modules/QuestionBank/app/Models/QuestionStatistic.php` |
| QuestionStatistics Model (duplicate) | `Modules/QuestionBank/app/Models/QuestionStatistics.php` |
| QuestionImport | `Modules/QuestionBank/app/Imports/QuestionImport.php` |
| QuestionReadOnly | `Modules/QuestionBank/app/Imports/QuestionReadOnly.php` |
| AiQuestionGeneratorPolicy | `Modules/QuestionBank/app/Policies/AiQuestionGeneratorPolicy.php` |
| AIQuestionPolicy (duplicate) | `Modules/QuestionBank/app/Policies/AIQuestionPolicy.php` |
| Web Routes (module) | `Modules/QuestionBank/routes/web.php` |
| Tenant Routes (main) | `routes/tenant.php` line 962 |
| DDL Reference | `tenant_db_v2.sql` lines 5207–5506 |
| Gap Analysis | `databases/3-Project_Planning/2-Gap_Analysis/2-Modules_Wise/2026Mar22/QuestionBank_Deep_Gap_Analysis.md` |

### Appendix B: Security Issue Registry

| SEC-ID | Severity | Description | File / Line | Required Fix |
|--------|----------|-------------|-------------|-------------|
| SEC-QNS-01 | P0 CRITICAL | OpenAI API key hardcoded | `AIQuestionGeneratorController.php:55` | Rotate key; move to .env as OPENAI_API_KEY |
| SEC-QNS-02 | P0 CRITICAL | Gemini API key hardcoded | `AIQuestionGeneratorController.php:56-57` | Rotate key; move to .env as GEMINI_API_KEY |
| SEC-QNS-03 | P0 CRITICAL | Zero authorization on all AI controller methods | `AIQuestionGeneratorController.php` all | Add Gate::authorize() using AiQuestionGeneratorPolicy |
| SEC-QNS-04 | P0 CRITICAL | No authorization on QuestionBankController index/print/validateFile/startImport | `QuestionBankController.php:55,71,82,193` | Add Gate::authorize() calls |
| SEC-QNS-05 | P0 CRITICAL | Missing EnsureTenantHasModule middleware | `routes/tenant.php:962` | Add EnsureTenantHasModule:QNS to route group |
| SEC-QNS-06 | P1 HIGH | Wrong policy references (competency.* instead of question-media.*) | `QuestionMediaStoreController.php:25+` | Replace all tenant.competency.* references |
| SEC-QNS-07 | P1 HIGH | No rate limiting on AI generation endpoint | `AIQuestionGeneratorController.php:202` | Add throttle:10,1 middleware |
| SEC-QNS-08 | P1 HIGH | Demo data hardcoded in production controller | `AIQuestionGeneratorController.php:302-393` | Remove getDemoResponse() method entirely |
| SEC-QNS-09 | P2 MEDIUM | File upload without virus/malware scanning | `QuestionBankController.php:82` | Add file scanning before storage |
| SEC-QNS-10 | P2 MEDIUM | Inline Validator instead of FormRequest in AI controller | `AIQuestionGeneratorController.php:206` | Create AIQuestionGenerateRequest |

### Appendix C: Bloom's Taxonomy Quick Reference

| Level | Name | Cognitive Action | Indicator Verbs |
|-------|------|-----------------|-----------------|
| 1 | Remember | Recall facts and basic concepts | List, Define, Recall, Identify, Name |
| 2 | Understand | Explain ideas or concepts | Summarize, Describe, Explain, Classify |
| 3 | Apply | Use information in new situations | Solve, Use, Demonstrate, Apply, Execute |
| 4 | Analyze | Draw connections among ideas | Compare, Contrast, Differentiate, Examine |
| 5 | Evaluate | Justify a decision or course of action | Critique, Defend, Judge, Assess, Justify |
| 6 | Create | Produce new or original work | Design, Construct, Formulate, Develop |

### Appendix D: Question Status Transition Table

| Current Status | Actor | Action | New Status | review_log Created? | Version Created? |
|---------------|-------|--------|-----------|--------------------|--------------------|
| DRAFT | Teacher | Submit for review | IN_REVIEW | No | No |
| DRAFT | Admin | Approve directly | APPROVED | Yes | No |
| IN_REVIEW | Reviewer/Admin | Approve | APPROVED | Yes | No |
| IN_REVIEW | Reviewer/Admin | Reject | REJECTED | Yes (comment required) | No |
| APPROVED | Admin | Publish | PUBLISHED | No | No |
| APPROVED | Admin | Archive | ARCHIVED | No | No |
| REJECTED | Teacher | Edit content | DRAFT (auto) | No | Yes (if content changed) |
| PUBLISHED | Admin | Archive | ARCHIVED | No | No |
| ARCHIVED | — | (terminal) | — | — | — |

### Appendix E: DDL Issues Found

| Issue ID | Table | Issue | Severity | Fix |
|----------|-------|-------|----------|-----|
| DDL-QNS-01 | `qns_question_usage_log` | CONSTRAINT references column `usage_context` but column is named `question_usage_type` | HIGH | Correct FK constraint name in migration |
| DDL-QNS-02 | `qns_questions_bank` | ON DELETE SET NULL on NOT NULL FK columns (class_id, subject_id, etc.) | MEDIUM | Change to ON DELETE RESTRICT or make FKs nullable |
| DDL-QNS-03 | `qns_question_statistics` | No `created_by` column — audit trail gap | LOW | Add created_by FK in future migration |
| DDL-QNS-04 | `qns_question_usage_log` | No `created_by` column — audit trail gap | LOW | Add created_by FK in future migration |

---

## 16. V1 → V2 Delta

| Section | V1 Coverage | V2 Enhancement |
|---------|-------------|----------------|
| Security | Listed P0 issues | Added exact code snippets for API key fix; complete SEC registry with 10 entries; Appendix B with fix instructions |
| FR-QNS-02 (Question Types) | Mentioned 6 types | Added full type table with MCQ/MCQ_MULTI/TF/FIB/SA/ESSAY/MATCH; content_format rendering requirements per type |
| FR-QNS-14 (AI Generation) | Described security issue | Added REQ-QNS-14.3 (AIQuestionService spec), 14.4 (auth fix), 14.5 (rate limiting), 14.6 (FormRequest), 14.7 (remove demo data) — 5 sub-requirements vs 3 |
| FR-QNS-05 (Review Workflow) | Review log model, basic states | Added QuestionReviewController proposal (📐) with 5 specific routes; notification integration requirement |
| FR-QNS-10 (Statistics) | "Service needed" note | Added QuestionStatisticsService spec with computation algorithm (difficulty_index formula, discrimination_index top/bottom 27%); queued job requirement; on-demand trigger route |
| Routes (Section 6) | Listed required routes (text) | Full PHP route group code block with correct middleware; route security table |
| UI Screens (Section 7) | Table with 11 screens | 14 screens; added SCR-QNS-07 (AI review), SCR-QNS-13 (review queue), SCR-QNS-14 (analytics dashboard); per-screen field breakdown for create form |
| Business Rules | 10 rules | 12 rules; added BR-QNS-11 (rejection comment required) and BR-QNS-12 (topic weightage sum) |
| Workflows (Section 9) | 3 flows (text) | 4 flows with ASCII diagrams including AI generation, Excel import, statistics computation |
| NFRs (Section 10) | 7 NFRs | 16 NFRs covering security (P0-P1), performance, scalability, data integrity, rendering, media storage, code quality |
| Test Scenarios | 12 tests | 25 tests; added T-QNS-05 (AI key security), T-QNS-06 (AI auth), T-QNS-07 (QBank auth), T-QNS-08 (tenant middleware), T-QNS-22 (rate limiting), T-QNS-23 (UUID cast), T-QNS-24 (policy correction) |
| Data Model | 13 tables documented | DDL issues table added (Appendix E); DDL-QNS-01 FK constraint name bug flagged |
| Appendices | 4 appendices | 5 appendices; added Appendix E (DDL Issues); Appendix B expanded with 10-entry security registry |
| Dependencies | 8 entries | 13 entries; added QuestionStatisticsService dep on exm_* response tables; Scheduler (SCH_JOB); Notification (NTF) |
| New Sections | — | FR-QNS-08 (Multi-Topic Mapping), FR-QNS-09 (Performance Category Mapping) split out as explicit FRs |
