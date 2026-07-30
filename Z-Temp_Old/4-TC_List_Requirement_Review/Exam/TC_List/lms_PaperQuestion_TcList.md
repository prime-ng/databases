# lms_paper_set_question_TcList

## Module: LmsExam → Creation & Allocation → Paper Set Questions

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | LmsExam |
| Tab Group | Creation & Allocation |
| Feature | Paper Set Questions |
| URL(s) | `/lms-exam/creation-allocation` (index via tab), `/lms-exam/paper-set-question/create` (create), `/lms-exam/paper-set-question/store` (store single), `/lms-exam/paper-set-question/{id}` (show), `/lms-exam/paper-set-question/{id}/edit` (edit), `/lms-exam/paper-set-question/{id}` (update), `/lms-exam/paper-set-question/{id}/destroy` (destroy), `/lms-exam/paper-set-question/trash/view` (trashed), `/lms-exam/paper-set-question/{id}/restore` (restore), `/lms-exam/paper-set-question/{id}/force-delete` (forceDelete), `/lms-exam/paper-set-question/{id}/toggle-status` (toggleStatus), `/lms-exam/paper-set-question/search` (search AJAX), `/lms-exam/paper-set-question/existing` (existing AJAX), `/lms-exam/paper-set-question/bulk-store` (bulkStore AJAX), `/lms-exam/paper-set-question/bulk-destroy` (bulkDestroy AJAX), `/lms-exam/paper-set-question/update-ordinal` (updateOrdinal AJAX), `/lms-exam/paper-set-question/update-marks` (updateMarks AJAX), `/lms-exam/paper-set-question/update-compulsory` (updateCompulsory AJAX), `/lms-exam/paper-set-question/get-sections` (getSections AJAX), `/lms-exam/paper-set-question/get-subject-groups` (getSubjectGroups AJAX), `/lms-exam/paper-set-question/get-subjects` (getSubjects AJAX), `/lms-exam/paper-set-question/get-lessons` (getLessons AJAX), `/lms-exam/paper-set-question/get-topics` (getTopics AJAX) |
| Controller | `Modules\LmsExam\Http\Controllers\PaperSetQuestionController` |
| Model(s) | `Modules\LmsExam\Models\PaperSetQuestion` |
| Validation (Create) | `Modules\LmsExam\Http\Requests\PaperSetQuestionRequest` — validates paper_set_id, question_id (unique per set), exam_blueprint_id, section_name, ordinal, override_marks, negative_marks, is_compulsory, is_active |
| Validation (Update) | Same `PaperSetQuestionRequest` — same rules plus ignore own ID for unique check |
| Validation (Bulk Store) | Controller-level in `bulkStore()` — validates paper_set_id, question_ids array, questions_data array, negative_marks, is_compulsory, exam_blueprint_id |
| Permissions | `tenant.paper-set-question.viewAny`, `tenant.paper-set-question.view`, `tenant.paper-set-question.create`, `tenant.paper-set-question.update`, `tenant.paper-set-question.delete`, `tenant.paper-set-question.restore`, `tenant.paper-set-question.forceDelete` |
| Soft Deletes | Yes (`PaperSetQuestion` uses `SoftDeletes` trait; `destroy()` soft-deletes; `bulkDestroy()` forceDeletes) |
| Activity Log | Events: `Stored`, `Updated`, `Deleted`, `Restored`, `Permanently Deleted`, `Toggled`, `Questions Removed` |
| Unique Constraint | `uq_set_question (paper_set_id, question_id)` — no duplicate questions in a set |
| Usage Logging | `QuestionUsageLog` created on add (usage_type ONLINE_EXAM/OFFLINE_EXAM); removed on delete |
| Difficulty Validation | `validateDifficultyDistribution()` — checks against `DifficultyDistributionDetail` rules |
| Scope Validation | `validateExamScopes()` — checks against `ExamScope` target counts |

---

## 2. Pre-conditions

- Required permissions: `tenant.paper-set-question.viewAny`, `tenant.paper-set-question.view`, `tenant.paper-set-question.create`, `tenant.paper-set-question.update`, `tenant.paper-set-question.delete`, `tenant.paper-set-question.restore`, `tenant.paper-set-question.forceDelete`
- Required seed data: Active `ExamPaperSet`, active `QuestionBank` (PUBLISHED status), active `ExamPaper` with total_questions, total_marks configured
- Test user must have all above permissions (default admin user)
- Tenant context must be initialized via `tenancy()->initialize()`
- Dusk environment variables: `DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD`
- For search tests: At least 5 published questions with varied class, subject, lesson, topic, question_type, complexity, bloom, cognitive_skill
- For difficulty tests: Exam paper with `difficulty_config_id` set and `DifficultyDistributionDetail` rules configured
- For scope tests: Exam paper with `ExamScope` records and target_question_count > 0
- For usage tests: Exam paper with `only_unused_questions=1` and questions that have `QuestionUsageLog`
- For authorised tests: Exam paper with `only_authorised_questions=1` and some questions with `for_quiz=0`
- For blueprint tests: Active `ExamBlueprint` records linked to the exam paper

---

## 3. Default Data Load

When the page loads via Creation & Allocation tab (`active_tab=paper_set_question`):

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| Paper Set Questions Grid | queryBuilder() | PaperSetQuestion::with(paperSet, question, paperSet.examPaper) | Filters: paper_set_id, question_id, exam_paper_id, section_name, is_active, search | 10/page |
| Paper Sets List | PaperSetQuestionController@index() | ExamPaperSet::where('is_active','1')->get() | is_active=1 | None |
| Questions List | PaperSetQuestionController@index() | QuestionBank::where('is_active','1')->get() | is_active=1 | None |
| Exam Papers List | PaperSetQuestionController@index() | ExamPaper::where('is_active','1')->get() | is_active=1 | None |
| Classes (create view) | create() | SchoolClass::where('is_active','1')->get() | is_active=1 | None |
| Subjects (create view) | create() | Subject::where('is_active','1')->get() | is_active=1 | None |
| Question Types (create view) | create() | QuestionType::where('is_active','1')->get() | is_active=1 | None |
| Complexity Levels (create view) | create() | ComplexityLevel::where('is_active','1')->get() | is_active=1 | None |
| Bloom Taxonomies (create view) | create() | BloomTaxonomy::where('is_active','1')->get() | is_active=1 | None |
| Cognitive Skills (create view) | create() | CognitiveSkill::where('is_active','1')->get() | is_active=1 | None |
| Blueprints (create view) | create() | ExamBlueprint::where('is_active','1')->get() | is_active=1 | None |
| Performance Categories (create view) | create() | PerformanceCategory::where('is_active',1)->get() | is_active=1 | None |
| Question Tags (create view) | create() | QuestionTag::where('is_active',1)->get() | is_active=1 | None |

## 4. Test Data Strategy

- **Unique suffix**: `now()->format('His') . random_int(100, 999)` via `uniqueSuffix()` method
- **Questions**: Use PUBLISHED questions from QuestionBank; ensure varied question_types, complexity levels
- **Paper sets**: Create with exam_paper.total_questions set to expected value for exact match testing
- **Difficulty config**: Set up DifficultyDistributionDetail rules with min_percentage/max_percentage
- **Scopes**: Create ExamScope records with target_question_count matching paper set requirements
- **Cleanup**: Remove PaperSetQuestion records by paper_set_id after tests; also clean QuestionUsageLog
- **Pre-test cleanup**: Delete PaperSetQuestion by paper_set_id and associated usage logs before/after tests

---

## 5. Business Conditions

### 4.1 Database Schema — `lms_paper_set_questions`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | id | INT UNSIGNED PK | Auto-increment |
| BC-DB-02 | paper_set_id | INT UNSIGNED FK | NOT NULL, FK → `lms_exam_paper_sets.id`, ON DELETE CASCADE |
| BC-DB-03 | question_id | INT UNSIGNED FK | NOT NULL, FK → `qns_questions_bank.id` |
| BC-DB-04 | section_name | VARCHAR(50) | DEFAULT 'Section A' |
| BC-DB-05 | exam_blueprint_id | INT UNSIGNED FK NULL | FK → `lms_exam_blueprints.id` |
| BC-DB-06 | ordinal | INT UNSIGNED | NOT NULL DEFAULT 0 |
| BC-DB-07 | override_marks | DECIMAL(5,2) | NOT NULL |
| BC-DB-08 | negative_marks | DECIMAL(5,2) | DEFAULT 0.00 |
| BC-DB-09 | is_compulsory | TINYINT(1) | NOT NULL DEFAULT 1 |
| BC-DB-10 | is_active | TINYINT(1) | NOT NULL DEFAULT 1 |
| BC-DB-11 | created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |
| BC-DB-12 | updated_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP ON UPDATE |
| BC-DB-13 | deleted_at | TIMESTAMP NULL | Soft delete |

### 4.2 Validation Rules — `PaperSetQuestionRequest` (Create)

| BC ID | Field | Rule | Error Message |
|-------|-------|------|---------------|
| BC-VAL-01 | paper_set_id | required, exists:lms_exam_paper_sets,id | "Paper set is required" |
| BC-VAL-02 | question_id | required, exists:qns_questions_bank,id, unique(paper_set_id, question_id) | "This question is already added to this paper set" |
| BC-VAL-03 | exam_blueprint_id | nullable, exists:lms_exam_blueprints,id | — |
| BC-VAL-04 | section_name | nullable, string, max:50 | — |
| BC-VAL-05 | ordinal | required, integer, min:0 | "Sequence number is required" |
| BC-VAL-06 | override_marks | required, numeric, min:0, max:999.99 | "Marks are required" / "Marks cannot be negative" |
| BC-VAL-07 | negative_marks | nullable, numeric, min:0, max:999.99 | — |
| BC-VAL-08 | is_compulsory | boolean | — |
| BC-VAL-09 | is_active | boolean | — |

### 4.3 Validation Rules — Bulk Store (Controller)

| BC ID | Field | Rule | Error Message |
|-------|-------|------|---------------|
| BC-VAL-U01 | paper_set_id | required, exists:lms_exam_paper_sets,id | — |
| BC-VAL-U02 | question_ids | sometimes, array | — |
| BC-VAL-U03 | question_ids.* | exists:qns_questions_bank,id | — |
| BC-VAL-U04 | questions_data | sometimes, array | — |
| BC-VAL-U05 | questions_data.*.id | required_with:questions_data, exists:qns_questions_bank,id | — |
| BC-VAL-U06 | negative_marks | nullable, numeric, min:0 | — |
| BC-VAL-U07 | is_compulsory | boolean | — |
| BC-VAL-U08 | exam_blueprint_id | nullable, exists:lms_exam_blueprints,id | — |
| BC-VAL-U09 | At least one question | questionsToAdd must not be empty | "No questions selected." |
| BC-VAL-U10 | Total questions limit (controller) | existingCount + newCount must equal paper.total_questions | "Exact selection required. This exam paper requires exactly X questions." |
| BC-VAL-U11 | Only unused check (controller) | If paper.only_unused_questions, questions must not have usage log | "This exam paper requires unused questions only." |
| BC-VAL-U12 | Only authorised check (controller) | If paper.only_authorised_questions, questions must have for_quiz=1 | "This exam paper requires authorised questions only (for_quiz=1)." |
| BC-VAL-U13 | Difficulty distribution (controller) | Must match difficulty rules if difficulty_config_id set | "Cannot add X questions of this type/complexity." |
| BC-VAL-U14 | Exam scope limit (controller) | Must not exceed target_question_count per scope | "Cannot add questions. Limit exceeded for Scope: X" |
| BC-VAL-U15 | Marks limit (single store) | Sum of override_marks must not exceed paper.total_marks | "Cannot add question. Total marks limit (X) would be exceeded." |
| BC-VAL-U16 | Marks limit (update) | Potential new total must not exceed paper.total_marks | "Cannot update question. Total marks limit (X) would be exceeded." |
| BC-VAL-U17 | Marks limit (updateMarks AJAX) | Potential new total must not exceed paper.total_marks | "Cannot update marks. Total marks limit (X) would be exceeded." |
| BC-VAL-U18 | Question count limit (single store) | existingCount + 1 must not exceed paper.total_questions | "Cannot add question. Total questions limit (X) reached." |

### 4.4 Authorization (Permission Gates)

| BC ID | Permission | Controller Method | Behavior |
|-------|-----------|-------------------|----------|
| BC-AUTH-01 | tenant.paper-set-question.viewAny | index() | Without → 403 |
| BC-AUTH-02 | tenant.paper-set-question.view | show(), existing() | Without → 403 |
| BC-AUTH-03 | tenant.paper-set-question.create | create(), store(), search(), bulkStore() | Without → 403 |
| BC-AUTH-04 | tenant.paper-set-question.update | edit(), update(), toggleStatus(), updateOrdinal(), updateMarks(), updateCompulsory() | Without → 403 |
| BC-AUTH-05 | tenant.paper-set-question.delete | destroy(), bulkDestroy() | Without → 403 |
| BC-AUTH-06 | tenant.paper-set-question.restore | trashed(), restore() | Without → 403 |
| BC-AUTH-07 | tenant.paper-set-question.forceDelete | forceDelete() | Without → 403 |

### 4.5 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Bulk store adds multiple questions | Each question linked to paper_set_id with per-question settings (marks, ordinal, compulsory, blueprint) |
| BC-BIZ-02 | Total questions exact match validation | existingCount + newCount must EXACTLY equal paper.total_questions (strict check) |
| BC-BIZ-03 | Marks limit validation (bulk) | Sum of override_marks must not exceed paper.total_marks (checked in individual store and update) |
| BC-BIZ-04 | Difficulty distribution validation | validateDifficultyDistribution() checks question_type+complexity against rules; strict mode rejects, warning mode allows with warning |
| BC-BIZ-05 | Exam scope validation | validateExamScopes() checks each scope's target_question_count is not exceeded by existing+new questions matching that scope |
| BC-BIZ-06 | Only unused questions constraint | If paper.only_unused_questions=1, questions with existing usage logs rejected |
| BC-BIZ-07 | Only authorised questions constraint | If paper.only_authorised_questions=1, questions without for_quiz=1 rejected |
| BC-BIZ-08 | No duplicate questions | UNIQUE(paper_set_id, question_id) constraint; duplicates silently skipped in bulk store |
| BC-BIZ-09 | Usage logging on add | QuestionUsageLog created with usage_type = 'ONLINE_EXAM' or 'OFFLINE_EXAM' based on paper mode |
| BC-BIZ-10 | Usage log removal on delete | QuestionUsageLog records forceDeleted when PaperSetQuestion is removed |
| BC-BIZ-11 | Usage log restore on restore | QuestionUsageLog restored when PaperSetQuestion is restored |
| BC-BIZ-12 | Marks override from difficulty rules | If difficulty rule has marks_per_question, that overrides question's default marks |
| BC-BIZ-13 | Per-question settings priority | Per-question marks/compulsory/ordinal/blueprint map takes priority over global defaults |
| BC-BIZ-14 | Section name defaults to "Section A" | If no blueprint or section specified, default 'Section A' used |
| BC-BIZ-15 | Negative marks default | Defaults to exam paper's negative_marks if not specified in request |
| BC-BIZ-16 | Update marks via AJAX | updateMarks() validates total marks limit before saving new override_marks |
| BC-BIZ-17 | Update ordinal via AJAX | updateOrdinal() directly updates ordinal field |
| BC-BIZ-18 | Update compulsory via AJAX | updateCompulsory() toggles is_compulsory flag |
| BC-BIZ-19 | Bulk store with questions_data vs question_ids | questions_data provides per-question config; question_ids is simple list |
| BC-BIZ-20 | Difficulty distribution with optional fields | validateDifficultyDistribution handles rules with bloom/cognitive_skill/ques_type_specificity |
| BC-BIZ-21 | Difficulty distribution without optional fields | Grouped by question_type_id+complexity_level_id for simpler validation |
| BC-BIZ-22 | Search with 20+ filters | search() accepts class_id, section_id, subject_id, topic_id, tag_ids, question_type_id, complexity_level_id, bloom_id, cognitive_skill_id, question_type_specificity_id, recommendation_type, performance_category, priority, only_unused, only_authorised, for_quiz, for_exam, for_quest, paper_set_id, search_text, limit |
| BC-BIZ-23 | Search excludes existing questions | Questions already in the paper set are excluded from search results |
| BC-BIZ-24 | Existing endpoint returns stats | existing() returns questions list, stats (count, marks), blueprint_stats, difficulty_rules, exam_scopes |
| BC-BIZ-25 | Difficulty rule matching with marks override | In search(), matching difficulty rule's marks_per_question overrides question's default marks in results |
| BC-BIZ-26 | DB transaction on all write operations | store(), update(), destroy(), bulkStore(), bulkDestroy(), restore(), forceDelete() all use DB::transaction |
| BC-BIZ-27 | Soft delete with is_active=false before delete | restore() sets is_active=true before restore; destroy() does NOT set is_active=false (unlike exam scope) |
| BC-BIZ-28 | forceDelete cleans usage logs | forceDelete permanently removes QuestionUsageLog records for that question+set |
| BC-BIZ-29 | Warning mode for difficulty distribution | If ignore_difficulty_config=true, question added but warning message shown |
| BC-BIZ-30 | Calculation base for difficulty % | Uses paper.total_questions for percentage calculation if available; otherwise uses current total count |

### 4.6 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|------------------|----------------|
| BC-REF-01 | paper_set_id | lms_exam_paper_sets (id) | CASCADE |
| BC-REF-02 | question_id | qns_questions_bank (id) | RESTRICT (no CASCADE) |
| BC-REF-03 | exam_blueprint_id | lms_exam_blueprints (id) | RESTRICT (no CASCADE) |

---

## 6. Test Case List

### 5.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | Paper Set Questions Index Page Loads | Page loads with filters, search, grid with 10 items per page | — | — | ⬜ |
| TC-P02 | Filter By Paper Set | Grid shows only questions for selected paper set | — | — | ⬜ |
| TC-P03 | Filter By Exam Paper | Grid shows questions for all sets under selected exam paper | — | — | ⬜ |
| TC-P04 | Filter By Question | Grid filters by specific question ID | — | — | ⬜ |
| TC-P05 | Filter By Active/Inactive Status | Grid shows only active or inactive questions | — | — | ⬜ |
| TC-P06 | Search By Section Name | Search returns questions with matching section_name | — | — | ⬜ |
| TC-P07 | Search By Question Title | Search filters by ques_title LIKE | — | — | ⬜ |
| TC-P08 | Search By Paper Set Code/Name | Search returns questions in set matching set_code or set_name | — | — | ⬜ |
| TC-P09 | AJAX Search — Filter By Class | Search returns published questions for selected class | — | — | ⬜ |
| TC-P10 | AJAX Search — Filter By Subject | Search filters by subject_id | — | — | ⬜ |
| TC-P11 | AJAX Search — Filter By Topic | Search filters by topic_id including questionTopics relationship | — | — | ⬜ |
| TC-P12 | AJAX Search — Filter By Question Type | Search filters by question_type_id | — | — | ⬜ |
| TC-P13 | AJAX Search — Filter By Complexity Level | Search filters by complexity_level_id | — | — | ⬜ |
| TC-P14 | AJAX Search — Filter By Bloom Taxonomy | Search filters by bloom_id | — | — | ⬜ |
| TC-P15 | AJAX Search — Filter By Cognitive Skill | Search filters by cognitive_skill_id | — | — | ⬜ |
| TC-P16 | AJAX Search — Filter By Tags | Search returns questions with matching tag_ids | — | — | ⬜ |
| TC-P17 | AJAX Search — Text Search By Title | Search returns questions matching search_text in ques_title or question_content | — | — | ⬜ |
| TC-P18 | AJAX Search — Exclude Existing Questions | Questions already in the paper set excluded from results | — | — | ⬜ |
| TC-P19 | AJAX Search — Only Unused Questions | If paper.only_unused_questions=1, only questions without usage logs returned | — | — | ⬜ |
| TC-P20 | AJAX Search — Only Authorised Questions | If paper.only_authorised_questions=1, only questions with for_exam=1 returned | — | — | ⬜ |
| TC-P21 | AJAX Search — Returns Difficulty Rule Marks Override | Search results show marks possibly overridden by matching difficulty rule | — | — | ⬜ |
| TC-P22 | Bulk Store — Add Single Question | One question added with default settings | — | — | ⬜ |
| TC-P23 | Bulk Store — Add Multiple Questions (2-3) | Multiple questions added with per-question marks, ordinal, compulsory, blueprint | — | — | ⬜ |
| TC-P24 | Bulk Store — Exact Questions Count Matching Paper Limit | existingCount + newCount = paper.total_questions; succeeds | — | — | ⬜ |
| TC-P25 | Bulk Store — With Difficulty Distribution Validation Passing | Questions match difficulty rules; added successfully | — | — | ⬜ |
| TC-P26 | Bulk Store — With Exam Scope Validation Passing | Questions don't exceed scope target counts; added successfully | — | — | ⬜ |
| TC-P27 | Bulk Store — Usage Log Created For Each Question | QuestionUsageLog created with ONLINE_EXAM or OFFLINE_EXAM | — | — | ⬜ |
| TC-P28 | Bulk Store — Marks From Difficulty Rules Applied | Matching rule's marks_per_question overrides question default marks | — | — | ⬜ |
| TC-P29 | Bulk Store — Per-Question Settings Applied | Each question gets its specified is_compulsory, ordinal, marks, exam_blueprint_id | — | — | ⬜ |
| TC-P30 | Bulk Store — Section Name From Blueprint | Section name auto-set from linked blueprint's section_name | — | — | ⬜ |
| TC-P31 | Single Store — Add Question With All Fields | Question added with paper_set_id, question_id, override_marks, ordinal, is_compulsory, section_name, exam_blueprint_id | — | — | ⬜ |
| TC-P32 | Show Question Details | Detail page shows question title, type, marks, compulsory status, ordinal, blueprint | — | — | ⬜ |
| TC-P33 | Edit Question Form Loads | Edit form pre-filled with question data, paper sets, blueprints dropdowns | — | — | ⬜ |
| TC-P34 | Update Question — Change Marks | override_marks updated; total marks limit checked | — | — | ⬜ |
| TC-P35 | Update Question — Change Blueprint | exam_blueprint_id updated; section_name potentially changes | — | — | ⬜ |
| TC-P36 | AJAX Update Ordinal | updateOrdinal() sets new ordinal; returns success | — | — | ⬜ |
| TC-P37 | AJAX Update Marks | updateMarks() checks marks limit; saves override_marks; returns success with marks data | — | — | ⬜ |
| TC-P38 | AJAX Update Compulsory | updateCompulsory() toggles is_compulsory; returns success | — | — | ⬜ |
| TC-P39 | Bulk Destroy (Force Delete) Questions | Multiple questions removed; usage logs forceDeleted | — | — | ⬜ |
| TC-P40 | Soft Delete Single Question | Single question soft-deleted; usage logs soft-deleted | — | — | ⬜ |
| TC-P41 | Restore Soft-Deleted Question | Question restored; usage logs restored | — | — | ⬜ |
| TC-P42 | ForceDelete Permanently Deletes | Question permanently removed; usage logs forceDeleted | — | — | ⬜ |
| TC-P43 | Toggle Status Active/Inactive | is_active toggled; JSON response | — | — | ⬜ |
| TC-P44 | AJAX Existing — Returns Questions With Stats | existing() returns questions list, stats (count, marks, limits), blueprint_stats, difficulty_rules, exam_scopes | — | — | ⬜ |
| TC-P45 | AJAX Existing — Calculates Blueprint Stats | Grouped by exam_blueprint_id with count and sum of override_marks | — | — | ⬜ |
| TC-P46 | AJAX Existing — Calculates Scope Progress | Each scope shows target_count and added_count for that paper set | — | — | ⬜ |
| TC-P47 | AJAX Get Sections For Class | getSections() returns sections for selected class | — | — | ⬜ |
| TC-P48 | AJAX Get Subject Groups | getSubjectGroups() returns subject groups for class+section | — | — | ⬜ |
| TC-P49 | AJAX Get Subjects For Subject Group | getSubjects() returns subjects for selected subject_group_id | — | — | ⬜ |
| TC-P50 | AJAX Get Lessons For Subject | getLessons() returns lessons for subject+class | — | — | ⬜ |
| TC-P51 | AJAX Get Topics For Lesson | getTopics() returns topics for lesson with optional level filter | — | — | ⬜ |
| TC-P52 | Bulk Store With Warning Mode (Difficulty Violation) | ignore_difficulty_config=true; question added but warning message shown | — | — | ⬜ |
| TC-P53 | Trash View | Shows soft-deleted paper set questions | — | — | ⬜ |
| TC-P54 | Full Lifecycle: Search → Bulk Add → View Existing → Edit Marks → Bulk Remove | All transitions succeed | — | — | ⬜ |

### 5.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | Required — Missing `paper_set_id` (single store) | Validation error: "Paper set is required" | — | — | ⬜ |
| TC-N02 | Required — Missing `question_id` (single store) | Validation error: "Question is required" | — | — | ⬜ |
| TC-N03 | Required — Missing `override_marks` (single store) | Validation error: "Marks are required" | — | — | ⬜ |
| TC-N04 | Invalid — Negative `override_marks` | Validation error: "Marks cannot be negative" | — | — | ⬜ |
| TC-N05 | Unique — Duplicate Question In Same Paper Set | "This question is already added to this paper set" | — | — | ⬜ |
| TC-N06 | Invalid — Non-Existent `paper_set_id` | Validation error: "The selected paper set id is invalid." | — | — | ⬜ |
| TC-N07 | Invalid — Non-Existent `question_id` | Validation error: "The selected question id is invalid." | — | — | ⬜ |
| TC-N08 | Invalid — Non-Existent `exam_blueprint_id` | Validation error: "The selected exam blueprint id is invalid." | — | — | ⬜ |
| TC-N09 | Bulk Store — No Questions Selected | "No questions selected." — 422 | — | — | ⬜ |
| TC-N10 | Bulk Store — Total Questions Exceeds Paper Limit | "Exact selection required. This exam paper requires exactly X questions." | — | — | ⬜ |
| TC-N11 | Bulk Store — Total Questions Below Paper Limit | Same error as above (strict exact match required) | — | — | ⬜ |
| TC-N12 | Single Store — Total Questions Limit Reached | "Cannot add question. Total questions limit (X) reached." | — | — | ⬜ |
| TC-N13 | Single Store — Total Marks Limit Exceeded | "Cannot add question. Total marks limit (X) would be exceeded." | — | — | ⬜ |
| TC-N14 | Update — Total Marks Limit Exceeded | "Cannot update question. Total marks limit (X) would be exceeded." | — | — | ⬜ |
| TC-N15 | AJAX Update Marks — Total Marks Limit Exceeded | "Cannot update marks. Total marks limit (X) would be exceeded." | — | — | ⬜ |
| TC-N16 | Bulk Store — Only Unused Constraint Violated | "This exam paper requires unused questions only. The following questions have been used before: X" | — | — | ⬜ |
| TC-N17 | Bulk Store — Only Authorised Constraint Violated | "This exam paper requires authorised questions only (for_quiz=1). The following questions are not authorised: X" | — | — | ⬜ |
| TC-N18 | Bulk Store — Difficulty Distribution Validation Failed (Strict) | "Cannot add X questions of this type/complexity. Max allowed: X, Existing: X." — 422 | — | — | ⬜ |
| TC-N19 | Bulk Store — Difficulty Rule No Match | "Questions with Type ID: X and Complexity ID: Y do not match any rule." | — | — | ⬜ |
| TC-N20 | Bulk Store — Exam Scope Limit Exceeded | "Cannot add questions. Limit exceeded for Scope: X (Limit: X, Current: X, Adding: X)." | — | — | ⬜ |
| TC-N21 | Permission 403 — No Paper Set Question Permissions | 403 Forbidden on all endpoints | — | — | ⬜ |
| TC-N22 | Guest Access Redirect | Redirected to /login | — | — | ⬜ |
| TC-N23 | Show With Invalid ID (404) | 404 via findOrFail | — | — | ⬜ |
| TC-N24 | Edit/Update With Invalid ID (404) | 404 via findOrFail | — | — | ⬜ |
| TC-N25 | Delete With Invalid ID (404) | 404 via findOrFail | — | — | ⬜ |
| TC-N26 | AJAX Existing With Invalid paper_set_id | 404 via findOrFail | — | — | ⬜ |
| TC-N27 | AJAX Search With No Matching Questions | Empty questions array returned | — | — | ⬜ |
| TC-N28 | Bulk Destroy With Empty question_ids | Validation error: "The question ids field is required." | — | — | ⬜ |
| TC-N29 | Bulk Store — Question Already Exists In Set (Silently Skipped) | Duplicate question not added; count only reflects new additions | — | — | ⬜ |
| TC-N30 | XSS Injection In Search Fields | Stored/returned as literal; escaped on output | — | — | ⬜ |
| TC-N31 | AJAX Update Ordinal Without paper_set_question_id | 404: Model not found | — | — | ⬜ |
| TC-N32 | AJAX Update Marks With Non-Existent ID | 404: Model not found | — | — | ⬜ |
| TC-N33 | AJAX Update Compulsory With Non-Existent ID | 404: Model not found | — | — | ⬜ |
| TC-N34 | Restore Non-Existent Trashed Question | 404: onlyTrashed findOrFail | — | — | ⬜ |
| TC-N35 | ForceDelete Non-Existent Question | 404: withTrashed findOrFail | — | — | ⬜ |
| TC-N36 | Bulk Store — Exam Paper Has No total_questions Set | Validation skipped if paper.total_questions is 0 | — | — | ⬜ |
| TC-N37 | Search — Performance Category With No Match | Empty results array returned | — | — | ⬜ |
| TC-N38 | Search — Recommendation Type With No Match | Empty results array returned | — | — | ⬜ |

### 5.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|----------------|---------|---------|--------|
| TC-D01 | A | Bulk Store → Usage Log Created For Each Question | QuestionUsageLog with type ONLINE_EXAM/OFFLINE_EXAM and context_id=paper_set_id | — | — | ⬜ |
| TC-D02 | B | Bulk Destroy → Usage Log Removed | QuestionUsageLog forceDeleted for removed questions | — | — | ⬜ |
| TC-D03 | C | Soft Delete → Usage Log Soft-Deleted | QuestionUsageLog records also soft-deleted | — | — | ⬜ |
| TC-D04 | D | Restore → Usage Log Restored | QuestionUsageLog records restored with withTrashed()->restore() | — | — | ⬜ |
| TC-D05 | E | Force Delete → Usage Log Permanently Removed | QuestionUsageLog forceDeleted | — | — | ⬜ |
| TC-D06 | F | Paper Set Deletion Cascades To Questions (CASCADE) | Deleting paper set deletes all PaperSetQuestion records | — | — | ⬜ |
| TC-D07 | G | DB Transaction Rollback On Failure | In bulkStore, all adds rolled back on exception | — | — | ⬜ |
| TC-D08 | H | validateDifficultyDistribution — Strict Mode Rejects | ignore_difficulty_config=false; returns 422 with error message | — | — | ⬜ |
| TC-D09 | I | validateDifficultyDistribution — Warning Mode Allows | ignore_difficulty_config=true; question added with warning message | — | — | ⬜ |
| TC-D10 | J | validateExamScopes — Scope Passes When Count Within Limit | existingCount + newCount ≤ target_question_count; validation passes | — | — | ⬜ |
| TC-D11 | K | validateExamScopes — Scope Fails When Count Exceeds Limit | existingCount + newCount > target_question_count; validation fails with detailed message | — | — | ⬜ |
| TC-D12 | L | Difficulty Matching With Optional Fields (Bloom/Skill/Specificity) | findDifficultyRuleMatch checks all non-null optional fields for exact match | — | — | ⬜ |
| TC-D13 | M | Difficulty Matching Without Optional Fields | Grouped by question_type_id + complexity_level_id only | — | — | ⬜ |
| TC-D14 | N | Calculation Base For Difficulty % | Uses paper.total_questions if > 0; uses currentTotalCount otherwise | — | — | ⬜ |
| TC-D15 | O | existing() Returns Blueprint Stats | Blueprint stats grouped by exam_blueprint_id with count and marks sum | — | — | ⬜ |
| TC-D16 | P | existing() Returns Scope Progress | Each scope has target_count and added_count computed from PaperSetQuestion | — | — | ⬜ |
| TC-D17 | Q | Search Limits Results | search() uses `limit` parameter (default 50) | — | — | ⬜ |
| TC-D18 | R | Search for_quiz/for_exam/for_quest Flags | Boolean flags filter questions by for_quiz, for_exam, for_quest columns | — | — | ⬜ |
| TC-D19 | S | AJAX getTopics With Both Lesson And Level | Topics filtered by lesson_id and level_id simultaneously | — | — | ⬜ |
| TC-D20 | T | DB \| P1 \| lms_paper_set_questions table — UNIQUE KEY uq_set_question | Duplicate (paper_set_id, question_id) at DB level throws integrity constraint violation | — | — | ⬜ |
| TC-D21 | U | Integration \| P1 \| Controller — Gate::authorize('tenant.paper-set-question.*') | Gate called before each operation; without permissions → 403 Forbidden | — | — | ⬜ |
| TC-D22 | V | Integration \| P1 \| Controller — activityLog — Activity Logged After CRUD | 'Stored' after create; 'Updated' after update; 'Deleted' after destroy; 'Restored' after restore; 'Questions Removed' after bulkDestroy | — | — | ⬜ |
| TC-D23 | W | Unit \| P1 \| PaperSetQuestion model — belongsTo Relationships | paperSet, question, examBlueprint all return correct models; eager loading works | — | — | ⬜ |
| TC-D24 | X | Unit \| P1 \| PaperSetQuestion model — SoftDeletes Trait | delete() sets deleted_at; restore() nullifies; withTrashed() includes | — | — | ⬜ |
| TC-D25 | Y | Unit \| P1 \| PaperSetQuestion model — \$casts | is_compulsory boolean; is_active boolean; override_marks decimal:2; negative_marks decimal:2; ordinal integer | — | — | ⬜ |
| TC-D26 | Z | Integration \| P1 \| Controller — queryBuilder with Combined Filters | All filters (paper_set_id, question_id, exam_paper_id, section_name, search, is_active) work together with pagination | — | — | ⬜ |
| TC-D27 | AA | Integration \| P1 \| Controller — search Excludes Deleted Questions | existingIds computed with withTrashed to also exclude soft-deleted questions | — | — | ⬜ |
| TC-D28 | AB | Integration \| P1 \| bulkStore — Marks Override From Difficulty Rules | Matching rule with marks_per_question overrides default question marks | — | — | ⬜ |
| TC-D29 | AC | Integration \| P1 \| bulkStore — Default Section Name From Blueprint | When blueprint selected but no section_name, blueprint's name used; defaults to 'Section A' | — | — | ⬜ |
| TC-D30 | AD | DEV \| P1 \| bulkStore — questions_data Overrides question_ids | When both present, questions_data takes precedence for per-question settings | — | — | ⬜ |
| TC-D31 | AE | Integration \| P1 \| updateMarks — Total Marks Calculation | currentTotalMarks - oldMark + newMark ≤ paper.total_marks | — | — | ⬜ |
| TC-D32 | AF | Integration \| P1 \| Controller — search with performance_category filter | whereHas performanceCategories with performance_category_id and is_active=1 | — | — | ⬜ |
| TC-D33 | AG | Integration \| P1 \| Controller — search with priority filter | whereHas performanceCategories with priority value and is_active=1 | — | — | ⬜ |

### 5.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|-----------------|---------|---------|--------|
| TC-CR01 | CR | Code Review | P1 | Controller — DB Transactions in All Write Operations | store(), update(), destroy(), bulkStore(), bulkDestroy(), restore(), forceDelete() all use DB::beginTransaction/commit/rollback | — | — | ◌ |
| TC-CR02 | CR | Code Review | P1 | Controller — validateDifficultyDistribution Function | Checks rules against questions; handles grouped (no optional) and per-rule (with optional) matching; returns success/failure with message | — | — | ◌ |
| TC-CR03 | CR | Code Review | P1 | Controller — validateExamScopes Function | Checks each scope's target_question_count against existing+new questions filtered by question_type_id+lesson_id+topic_id | — | — | ◌ |
| TC-CR04 | CR | Code Review | P1 | Controller — search() With 20+ Filters | Handles class_id, section_id, subject_id, topic_id, tag_ids, question_type_id, complexity_level_id, bloom_id, cognitive_skill_id, question_type_specificity_id, recommendation_type, performance_category, priority, only_unused, only_authorised, for_quiz, for_exam, for_quest, search_text, limit, paper_set_id | — | — | ◌ |
| TC-CR05 | CR | Code Review | P1 | Controller — existing() Returns Comprehensive Stats | Returns questions + stats + blueprint_stats + difficulty_rules + exam_scopes for the frontend modal | — | — | ◌ |
| TC-CR06 | CR | Code Review | P1 | Controller — Usage Log Integration On Add/Remove | bulkStore creates QuestionUsageLog; bulkDestroy forceDeletes; destroy soft-deletes; restore restores; forceDelete forceDeletes | — | — | ◌ |
| TC-CR07 | CR | Code Review | P1 | Controller — Marks Limit Validation Across All Update Paths | Single store, update, updateMarks AJAX all check total marks ≤ paper.total_marks before saving | — | — | ◌ |
| TC-CR08 | CR | Code Review | P1 | Controller — Bulk Store Per-Question Config Priority | Per-question maps (marksMap, ordinalMap, compulsoryMap, blueprintMap, negativeMarksMap) take priority over global request params | — | — | ◌ |
| TC-CR09 | CR | Code Review | P1 | Controller — AJAX JSON Responses | All AJAX endpoints return response()->json() with success flag or error structure | — | — | ◌ |
| TC-CR10 | CR | Code Review | P1 | Request — PaperSetQuestionRequest prepareForValidation | Casts is_compulsory, is_active to boolean; ordinal to int; negative_marks defaults to 0.00; section_name defaults to 'Section A' | — | — | ◌ |

---

## 7. Detailed Test Steps

#### TC-CR01: Controller — DB Transactions in All Write Operations

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open PaperSetQuestionController.php | Controller in Modules/LmsExam/Http/Controllers/ |
| 2 | Inspect store() | DB::beginTransaction() before create; DB::commit() after; DB::rollBack() on exception |
| 3 | Inspect update() | DB::beginTransaction() before update; DB::commit() after; DB::rollBack() on exception |
| 4 | Inspect destroy() | DB::beginTransaction() before usage log delete + model delete; DB::commit() after |
| 5 | Inspect bulkStore() | DB::beginTransaction() before loop; DB::commit() after; DB::rollBack() on exception |
| 6 | Inspect bulkDestroy() | DB::beginTransaction() before operations; DB::commit() after; DB::rollBack() on exception |
| 7 | Inspect restore() | DB::beginTransaction() before restore; DB::commit() after; DB::rollBack() on exception |
| 8 | Inspect forceDelete() | DB::beginTransaction() before cleanup; DB::commit() after; DB::rollBack() on exception |

#### TC-P09: AJAX Search — Filter By Class

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create questions for Class A and Class B | 3 in Class A, 2 in Class B |
| 2 | Call AJAX POST `/lms-exam/paper-set-question/search` with class_id={Class A id} | JSON response |
| 3 | Verify only Class A questions returned | 3 questions |
| 4 | Verify each question has id, title, type, class, subject, topic, complexity, bloom, marks | Complete metadata |
| 5 | Verify questions have status=PUBLISHED and is_active=1 | Filtered correctly |

#### TC-P22: Bulk Store — Add Single Question

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure paper set has exam_paper with total_questions=1 | Paper set ready |
| 2 | Ensure no existing questions in this paper set | Count = 0 |
| 3 | Call AJAX POST `/lms-exam/paper-set-question/bulk-store` with paper_set_id and question_ids=[Q1] | POST with data |
| 4 | Check response | "1 questions added successfully." |
| 5 | DB check: PaperSetQuestion record exists | Linked to paper_set_id and question_id=Q1 |
| 6 | DB check: QuestionUsageLog created | Usage type based on paper mode |

#### TC-P23: Bulk Store — Add Multiple Questions With Per-Question Settings

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure paper set has exam_paper with total_questions=3 | Ready |
| 2 | Ensure empty set | Count = 0 |
| 3 | Call bulk-store with questions_data: Q1 (marks=5, ordinal=1, compulsory=true), Q2 (marks=10, ordinal=2, compulsory=false), Q3 (marks=15, ordinal=3, compulsory=true, negative_marks=1) | POST with data |
| 4 | Check response | "3 questions added successfully." |
| 5 | DB check: Q1 has override_marks=5, ordinal=1, is_compulsory=1 | Per-question config applied |
| 6 | DB check: Q2 has override_marks=10, ordinal=2, is_compulsory=0 | Per-question config applied |
| 7 | DB check: Q3 has override_marks=15, ordinal=3, is_compulsory=1, negative_marks=1.00 | Per-question config applied |
| 8 | DB check: 3 QuestionUsageLog records created | All logged |

#### TC-N10: Bulk Store — Total Questions Exceeds Paper Limit

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Paper set with exam_paper.total_questions=2, 1 existing question | Existing count = 1 |
| 2 | Try to add 2 new questions (would make total 3 ≠ 2) | POST with 2 question IDs |
| 3 | Check response | 422: "Exact selection required. This exam paper requires exactly 2 questions. (Current total after addition would be: 3)" |
| 4 | DB check: No new questions added | Transaction rolled back |

#### TC-N18: Bulk Store — Difficulty Distribution Validation Failed (Strict)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Paper set with difficulty_config_id, ignore_difficulty_config=false | Strict mode |
| 2 | Paper has max 2 MCQ questions at Medium complexity | Rule configured |
| 3 | Set already has 2 MCQ-Medium questions | Existing = 2 |
| 4 | Try to add 1 more MCQ-Medium question | Would exceed max |
| 5 | Check response | 422: "Cannot add 1 questions of this type/complexity. Max allowed: 2, Existing: 2. Limit exceeded for complexity rule." |
| 6 | DB check: No new questions added | Rolled back |

#### TC-P52: Bulk Store — Warning Mode (Difficulty Violation)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Paper set with difficulty_config_id, ignore_difficulty_config=true | Warning mode |
| 2 | Adding question that violates difficulty rule | POST with data |
| 3 | Check response | "1 questions added successfully. However, difficulty distribution rule was violated: ..." |
| 4 | DB check: Question actually added | Added despite violation |
| 5 | Response includes warning flag | `warning: true` |

#### TC-N20: Bulk Store — Exam Scope Limit Exceeded

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Exam paper has scope: question_type=MCQ, lesson=L1, topic=T1, target=3 | Scope exists |
| 2 | Paper set already has 3 MCQ questions matching L1+T1 | Already at limit |
| 3 | Try to add 1 more MCQ question matching same scope | POST |
| 4 | Check response | 422: "Cannot add questions. Limit exceeded for Scope: MCQ (Limit: 3, Current: 3, Adding: 1)." |
| 5 | DB check: No new questions added | Rolled back |

#### TC-P36: AJAX Update Ordinal

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create PaperSetQuestion with ordinal=1 | Record exists |
| 2 | Call AJAX POST updateOrdinal with paper_set_question_id and ordinal=5 | POST |
| 3 | Check response | success: true, "Sequence order updated successfully." |
| 4 | DB check: ordinal=5 | Updated |

#### TC-P37: AJAX Update Marks

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create PaperSetQuestion with override_marks=5 | Record exists |
| 2 | Paper set exam_paper has total_marks=50, current total marks=45 | Room for 5 more |
| 3 | Call AJAX updateMarks with paper_set_question_id and override_marks=10 | POST |
| 4 | Check response | success: true, marks: 10.00, original_marks: 5.00 |
| 5 | DB check: override_marks=10 | Updated |
| 6 | Now try override_marks=50 (would exceed total 45-5+50=90 > 50) | POST |
| 7 | Check response | 422: "Cannot update marks. Total marks limit (50) would be exceeded." |

#### TC-P44: AJAX Existing — Returns Questions With Stats

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Add 2 questions to paper set (marks 5 and 10) | Questions exist |
| 2 | Call AJAX POST `/lms-exam/paper-set-question/existing` with paper_set_id | POST |
| 3 | Check response questions array | 2 questions with title, type, complexity, marks, is_compulsory, ordinal, section_name |
| 4 | Check stats | added_questions=2, added_marks=15, required_marks=paper.total_marks, exam_title, paper_set_name |
| 5 | Check blueprint_stats | Grouped data by blueprint |
| 6 | Check difficulty_rules | List of rules from difficulty_config_id |
| 7 | Check exam_scopes | Each scope with target_count and added_count |

#### TC-P01: Paper Set Questions Index Page Loads

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with admin credentials | Dashboard loads |
| 2 | Expand LmsExam, navigate to Creation & Allocation, click Paper Set Questions tab | Page loads with active_tab=paper_set_question |
| 3 | Verify paper set filter dropdown | Dropdown present |
| 4 | Verify question filter | Question filter present |
| 5 | Verify exam paper filter | Exam paper filter present |
| 6 | Verify search input | Search text field present |
| 7 | Verify grid with columns: Paper Set, Question, Section, Marks, Compulsory, Ordinal, Status, Actions | All columns present |
| 8 | Verify pagination (10/page) | Pagination controls |

#### TC-P02: Filter By Paper Set

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create questions for Paper Set A (3 questions) and Paper Set B (2 questions) | Data ready |
| 2 | Select Paper Set A from dropdown | Page reloads with paper_set_id filter |
| 3 | Verify 3 questions shown | Filter correct |
| 4 | Select Paper Set B | 2 questions shown |
| 5 | Clear filter | All 5 shown |

#### TC-P03: Filter By Exam Paper

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Paper Set A (under Exam Paper X) with 2 questions, Paper Set B (under Exam Paper Y) with 2 questions | Data ready |
| 2 | Select Exam Paper X | whereHas('paperSet') filters by exam_paper_id |
| 3 | Verify only Paper Set A's 2 questions shown | Filter correct |

#### TC-P09: AJAX Search — Filter By Class

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create questions in Class A (3 questions) and Class B (2 questions), all PUBLISHED | Data ready |
| 2 | Call search() with class_id = Class A | AJAX call |
| 3 | Verify 3 questions returned | Correct class filter |
| 4 | Each question has id, title, type, class, subject, topic, complexity, bloom, marks | Full metadata |

#### TC-P10: AJAX Search — Filter By Subject

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Questions in Subject S1 (3) and Subject S2 (2) | Data ready |
| 2 | Call search() with subject_id = S1 | AJAX call |
| 3 | Verify only S1 questions | Correct |

#### TC-P12: AJAX Search — Filter By Question Type

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Questions of type MCQ (3), Short Answer (2), Long Answer (1) | Data ready |
| 2 | Call search() with question_type_id = MCQ | AJAX call |
| 3 | Verify only MCQ questions returned | Correct filter |

#### TC-P13: AJAX Search — Filter By Complexity Level

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Questions with Easy (2), Medium (3), Hard (1) complexity | Data ready |
| 2 | Call search() with complexity_level_id = Medium | AJAX call |
| 3 | Verify 3 medium questions returned | Correct |

#### TC-P22: Bulk Store — Add Single Question

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Paper set with exam_paper.total_questions=1, no existing questions | Set ready |
| 2 | Call bulkStore with paper_set_id and question_ids=[Q1] | AJAX POST |
| 3 | Check response | "1 questions added successfully." |
| 4 | DB check: PaperSetQuestion created | Linked correctly |
| 5 | DB check: QuestionUsageLog created | Usage logged |

#### TC-P23: Bulk Store — Add Multiple Questions With Per-Question Settings

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Paper set with exam_paper.total_questions=3 | Set ready |
| 2 | Call bulkStore with questions_data: Q1(marks=5, ordinal=1, compulsory=true), Q2(marks=10, ordinal=2, compulsory=false), Q3(marks=15, ordinal=3, compulsory=true) | AJAX POST |
| 3 | DB check Q1: override_marks=5, ordinal=1, is_compulsory=1 | Per-question applied |
| 4 | DB check Q2: override_marks=10, ordinal=2, is_compulsory=0 | Per-question applied |
| 5 | DB check Q3: override_marks=15, ordinal=3, is_compulsory=1 | Per-question applied |

#### TC-P24: Bulk Store — Exact Questions Count Matching Paper Limit

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Paper set with exam_paper.total_questions=5, 2 existing questions | Need 3 more to equal 5 |
| 2 | Call bulkStore with 3 new questions | Adding 3 (2+3=5 = total questions) |
| 3 | Check response | "3 questions added successfully." |
| 4 | DB check: total now = 5 | Exact match |

#### TC-P25: Bulk Store — With Difficulty Distribution Validation Passing

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Paper has difficulty_config_id set, rules allow 2 MCQ-Medium questions (50% of 4 total) | Rules exist |
| 2 | Paper total_questions=4, 0 existing questions | Empty set |
| 3 | Call bulkStore with 2 MCQ-Medium questions | Within limit |
| 4 | Check response | "2 questions added successfully." |

#### TC-P30: Single Store — Add Question With All Fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to create form | Form loads |
| 2 | Select paper set, question, blueprint, section_name="Section B", ordinal=3, override_marks=10, negative_marks=1.50, is_compulsory=true | All fields filled |
| 3 | Click "Save" | POST to store |
| 4 | DB check: all fields saved correctly | Record verified |

#### TC-P34: Update Question — Change Marks

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create PaperSetQuestion with override_marks=5, is_compulsory=1 | Record exists |
| 2 | Navigate to edit, change override_marks to 10 | Marks changed |
| 3 | Submit update | POST with validated data |
| 4 | Check response | Success |
| 5 | DB check: override_marks=10 | Updated |
| 6 | Verify marks limit not exceeded (5→10, delta=5, paper total=50, existing=45, 45-5+10=50 ≤ 50) | Passes limit check |

#### TC-P39: Bulk Destroy (Force Delete) Questions

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Add 3 questions to Paper Set A | 3 records + 3 usage logs |
| 2 | Call bulkDestroy with paper_set_id and question_ids=[Q1, Q2, Q3] | AJAX POST |
| 3 | Check response | "Questions removed successfully." |
| 4 | DB check: PaperSetQuestion forceDeleted | Permanently removed |
| 5 | DB check: QuestionUsageLog forceDeleted | Usage logs also removed |

#### TC-P40: Soft Delete Single Question

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create PaperSetQuestion | Active record |
| 2 | Click "Delete" on that question | POST to destroy |
| 3 | Check response | Success message |
| 4 | DB check: deleted_at set, is_active unchanged | Soft-deleted |
| 5 | DB check: QuestionUsageLog also soft-deleted | Cascaded |

#### TC-P42: ForceDelete Permanently Deletes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft delete question first | In trash |
| 2 | Navigate to trash view | Question visible |
| 3 | Click "Permanently Delete" | POST to forceDelete |
| 4 | DB check: record gone | Permanently deleted |
| 5 | DB check: QuestionUsageLog forceDeleted | Usage log gone |

#### TC-P43: Toggle Status Active/Inactive

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create question with is_active=1 | Active |
| 2 | Toggle status via AJAX with is_active=0 | POST |
| 3 | Check JSON response | success: true, is_active: false |
| 4 | DB check: is_active=0 | Toggled |
| 5 | Toggle back to 1 | Works both ways |

#### TC-P51: AJAX Get Topics For Lesson

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create topics under Lesson L1: T1 (level 1), T2 (level 2) | Topics exist |
| 2 | Call getTopics with lesson_id=L1 | AJAX |
| 3 | Verify both T1 and T2 returned | All topics for lesson |
| 4 | Call getTopics with lesson_id=L1, level_id=1 | Only T1 returned |
| 5 | Call getTopics with class_id=C1, subject_id=S1 (no lesson_id) | Topics for class+subject |

#### TC-N01: Required — Missing paper_set_id (Single Store)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST to store without paper_set_id | Missing field |
| 2 | Validation error | "Paper set is required" |

#### TC-N05: Unique — Duplicate Question In Same Paper Set

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create PaperSetQuestion with paper_set_id=PS1, question_id=Q1 | Record exists |
| 2 | POST store with same paper_set_id=PS1, question_id=Q1 | Duplicate |
| 3 | Validation error from unique rule | "This question is already added to this paper set" |

#### TC-N10: Bulk Store — Total Questions Exceeds Paper Limit

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Paper set: exam_paper.total_questions=2, 1 existing question | Need exactly 1 more |
| 2 | Call bulkStore with 2 new questions (would be 3 total ≠ 2) | Violation |
| 3 | Error 422 | "Exact selection required. This exam paper requires exactly 2 questions." |
| 4 | DB check: no new questions added | Rolled back |

#### TC-N13: Single Store — Total Marks Limit Exceeded

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Paper set: exam_paper.total_marks=50, current total marks=48 | 2 marks remaining |
| 2 | Try to add question with override_marks=5 | 48+5=53 > 50 |
| 3 | Error response | "Cannot add question. Total marks limit (50) would be exceeded." |

#### TC-N16: Bulk Store — Only Unused Constraint Violated

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Exam paper has only_unused_questions=1 | Constraint active |
| 2 | Questions Q1, Q2 have usage logs (used in previous exam) | Used questions |
| 3 | Try bulkStore with Q1, Q2 | Violation |
| 4 | Error 422 | "This exam paper requires unused questions only. The following questions have been used before: Q1, Q2" |

#### TC-N18: Bulk Store — Difficulty Distribution Failed (Strict)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Paper has difficulty_config_id, ignore_difficulty_config=false | Strict mode |
| 2 | Rule max 2 MCQ-Medium questions, existing 2, adding 1 more | Would exceed |
| 3 | Error 422 | "Cannot add 1 questions of this type/complexity. Max allowed: 2, Existing: 2." |

#### TC-N20: Bulk Store — Exam Scope Limit Exceeded

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Scope: question_type=MCQ, lesson=L1, topic=T1, target=3 | Scope defined |
| 2 | Existing 3 MCQ-L1-T1 questions, adding 1 more | Would exceed |
| 3 | Error 422 | "Cannot add questions. Limit exceeded for Scope: MCQ (Limit: 3, Current: 3, Adding: 1)." |

#### TC-D01: Bulk Store → Usage Log Created

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Add 2 questions via bulkStore | Success |
| 2 | Query QuestionUsageLog table | 2 records |
| 3 | Verify each: question_bank_id, question_usage_type (ONLINE_EXAM or OFFLINE_EXAM based on paper mode), context_id=paper_set_id, used_at=now, is_active=1 | All fields correct |

#### TC-D02: Bulk Destroy → Usage Log Removed

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Add 2 questions, then bulkDestroy them | Removed |
| 2 | Query QuestionUsageLog: should be forceDeleted | 0 records |

#### TC-D06: Paper Set Deletion Cascades To Questions

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create paper set with 2 questions | Paper set + 2 PSQ |
| 2 | Delete paper set | Cascading delete |
| 3 | DB check: PSQ records gone | Cascaded |
| 4 | Verify DDL: ON DELETE CASCADE on fk_sq_set | Confirmed |

#### TC-D07: DB Transaction Rollback On Failure

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | bulkStore with 3 questions, mock exception after 2nd | Exception |
| 2 | Verify DB::rollBack() called | Rolled back |
| 3 | DB check: 0 questions added | No partial data |

#### TC-D12: Difficulty Matching With Optional Fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Rule: question_type=MCQ, complexity=Medium, bloom=Remember, cognitive_skill=Recall | Rule with optional fields |
| 2 | Question: type=MCQ, complexity=Medium, bloom=Remember, cognitive_skill=Recall | All match |
| 3 | findDifficultyRuleMatch() should match | Returns the rule |
| 4 | Question: type=MCQ, complexity=Medium, bloom=Analyze, cognitive_skill=Recall | Bloom doesn't match |
| 5 | findDifficultyRuleMatch() should NOT match | Returns null |

#### TC-D20: UNIQUE KEY uq_set_question

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create PSQ with (paper_set_id=PS1, question_id=Q1) | Record exists |
| 2 | Insert duplicate (PS1, Q1) directly at DB level | Integrity constraint violation |
| 3 | Verify DDL: UNIQUE KEY uq_set_question (paper_set_id, question_id) | Confirmed |

#### TC-D22: Activity Logging After CRUD

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Store a question | 'Stored' logged |
| 2 | Update the question | 'Updated' logged |
| 3 | Delete the question | 'Trashed' not found; uses 'Deleted' event |
| 4 | Restore the question | 'Restored' logged |
| 5 | Bulk destroy | 'Questions Removed' logged with count |

#### TC-D25: Model Casts Verification

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create PSQ with is_compulsory=1, override_marks=5.50 | Casts applied |
| 2 | Access $psq->is_compulsory | Returns true (boolean) |
| 3 | Access $psq->override_marks | Returns 5.50 (decimal) |
| 4 | Access $psq->negative_marks | Returns 0.00 (decimal, default) |
| 5 | Access $psq->ordinal | Returns integer |

#### TC-D27: search Excludes Deleted Questions

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Add Q1 to paper set, then soft delete it | Q1 in trash |
| 2 | Call search with paper_set_id | Q1 excluded |
| 3 | Verify query: `PaperSetQuestion::withTrashed()->where('paper_set_id')->pluck('question_id')` | Existing IDs includes soft-deleted |
| 4 | Result: `whereNotIn('id', $existingIds)` excludes Q1 | Correct |

#### TC-D28: BulkStore — Marks Override From Difficulty Rules

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Difficulty rule: type=MCQ, complexity=Medium → marks_per_question=3 | Rule set |
| 2 | Question Q1: type=MCQ, complexity=Medium, default marks=5 | Question exists |
| 3 | Call bulkStore with Q1 (no per-question marks override) | No marks in request |
| 4 | Controller matches difficulty rule | Matching rule found |
| 5 | DB check: override_marks = 3 (from difficulty rule, not 5 from question) | Rule overrode default |

#### TC-D31: updateMarks — Total Marks Calculation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Paper total_marks=50, existing marks sum=45 | Buffer of 5 |
| 2 | Current question Q1 has override_marks=5 | Old marks = 5 |
| 3 | Try updateMarks to 12 | 45 - 5 + 12 = 52 > 50 |
| 4 | Error 422 | "Cannot update marks. Total marks limit (50) would be exceeded." |
| 5 | Try updateMarks to 10 | 45 - 5 + 10 = 50 ≤ 50 |
| 6 | Success | Marks updated to 10 |

#### TC-P52: Bulk Store With Warning Mode (Difficulty Violation)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Paper has ignore_difficulty_config=true, difficulty rules exist | Warning mode |
| 2 | Adding question that violates difficulty distribution | Would exceed max |
| 3 | Controller: ignoreDifficulty=true, does NOT reject | Proceeds |
| 4 | Question added successfully | Created |
| 5 | Response includes warning | "However, difficulty distribution rule was violated: ..." |
| 6 | Response includes warning: true flag | warning flag set |

### 7.4 Additional Search Test Cases

#### TC-P53: Search By Question Code

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create question Q1 with question_code = MCQ001 | Question exists |
| 2 | Navigate to questions tab for Paper P1 | Search form visible |
| 3 | Enter MCQ001 in question_code field | Code entered |
| 4 | Click Search | AJAX request |
| 5 | Only Q1 shown in results | Filtered correctly |

#### TC-P54: Search By Bookmark Status

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Q1 is bookmarked, Q2 is not | Filter data |
| 2 | Select bookmark_filter = 1 (bookmarked) | Filter selected |
| 3 | Click Search | Only Q1 shown |
| 4 | Select bookmark_filter = 0 (not bookmarked) | Only Q2 shown |

#### TC-P55: Search By Question Type

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Q1 is MCQ, Q2 is Short, Q3 is Long | 3 types |
| 2 | Select question_type_id = MCQ type | Filter |
| 3 | Click Search | Only MCQ questions shown |

#### TC-P56: Search By Complexity

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Q1 complexity=Easy, Q2=Medium, Q3=Hard | 3 levels |
| 2 | Select complexity = Medium | Filter |
| 3 | Click Search | Only Medium shown |

#### TC-P57: Search By Multiple Combined Filters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Q1: lesson=L1, topic=T1, type=MCQ, complexity=Easy | Data |
| 2 | Create Q2: lesson=L1, topic=T2, type=MCQ, complexity=Easy | Data |
| 3 | Create Q3: lesson=L2, topic=T1, type=Short, complexity=Hard | Data |
| 4 | Filter: lesson_id=L1 + question_type_id=MCQ + complexity=Easy | Combined |
| 5 | Click Search | Q1 and Q2 returned, Q3 excluded |

### 7.5 Additional Detailed Test Steps

#### TC-P58: Pagination In Question Search Results

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Have 25 questions matching search criteria | Exceeds 20/page |
| 2 | Search without pagination override | First 20 results |
| 3 | Verify pagination links at bottom | Present |
| 4 | Click page 2 | Next 5 results |
| 5 | Total count displayed | 25 total |

#### TC-P59: Search With No Results

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Search for non-existent question code | No match |
| 2 | Click Search | Empty results |
| 3 | No question cards shown | Empty state |
| 4 | Message displayed | No questions found matching criteria |

#### TC-P60: Clear Search Resets Results

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Perform filtered search | Filtered results shown |
| 2 | Click Clear button | Form resets |
| 3 | All questions for paper shown | Default unfiltered view |

### 7.6 Additional Negative Test Cases

#### TC-N23: Bulk Store — Question Already In Paper

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Question Q1 already in Paper P1 (existing question) | Already added |
| 2 | Try to add Q1 again via bulkStore | Duplicate |
| 3 | Error response | Question already exists in this paper |

#### TC-N24: Bulk Store — No Questions Selected

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click bulkStore with empty question_ids array | Empty payload |
| 2 | Validation error | At least one question must be selected |

#### TC-N25: Bulk Store — Exceed Total Marks

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Paper P1 total_marks=50, existing questions sum=40 | 10 remaining |
| 2 | Try adding Q1 with marks=12 (50-40+current = would exceed) | Exceeds |
| 3 | Error 422 | Total marks limit would be exceeded |

#### TC-N26: Bulk Store — Exceed Total Questions

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Paper P1 total_questions=10, existing questions=8 | 2 remaining |
| 2 | Try adding 3 questions | Would exceed |
| 3 | Error 422 | Total question limit would be exceeded |

#### TC-N27: Difficulty Distribution — Exceed Max Per Type

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Difficulty rule: max=3 for type=MCQ, complexity=Easy | Rule set |
| 2 | Already 3 MCQs with complexity=Easy in paper | At max |
| 3 | Try adding another MCQ with complexity=Easy | Exceeds |
| 4 | Error 422 (unless ignore_difficulty_config=true) | Difficulty distribution violation |

#### TC-N28: Difficulty Distribution — Below Min Per Type

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Difficulty rule: min=2 for type=Short, complexity=Medium | Rule set |
| 2 | 0 Short-Medium questions currently in paper | Below min |
| 3 | Cannot remove last Short-Medium question | Violates min constraint |
| 4 | Validation blocks removal | Must maintain minimum count |

#### TC-N29: AJAX Get Sections With Non-Existent Paper

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Call sections endpoint with exam_paper_id=99999 | Invalid paper |
| 2 | Response | Empty array or 404 |

### 7.7 Additional Code Review Test Cases

#### TC-CR07: validateDifficultyDistribution Logic

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open PaperSetQuestionController | validateDifficultyDistribution method |
| 2 | Verify it checks difficulty_rules table | Query present |
| 3 | Verify it compares current + proposed counts | Count logic |
| 4 | Verify min/max boundary checks | Both directions |
| 5 | Verify returns violations collection | Structured output |

#### TC-CR08: validateExamScopes Logic

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open PaperSetQuestionController | validateExamScopes method |
| 2 | Verify it checks exam_scopes table | Scope existence |
| 3 | Verify it validates question_type compatibility | Type match |
| 4 | Verify lesson/topic matching | Scope filters |

#### TC-CR09: updateMarks — Marks Buffer Logic

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect updateMarks method | Current sum fetched |
| 2 | Calculate new sum: currentSum - oldOverrideMarks + newMarks | Formula |
| 3 | Compare with paper total_marks | Limit check |
| 4 | Return error if exceeded | 422 response |

#### TC-CR10: Search With 20+ Filters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect questions() search method | Paginated query |
| 2 | Verify each filter condition | lesson_id, topic_id etc. |
| 3 | Verify scope_name relation | Eager loaded |
| 4 | Verify search keyword on question_code and question_text | OR condition |

#### TC-CR11: Transaction In Bulk Operations

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect bulkStore() | beginTransaction |
| 2 | Inspect bulkRemove() | beginTransaction |
| 3 | Inspect updateMarks() | beginTransaction |
| 4 | All have commit/rollback | Consistent pattern |

#### TC-CR12: Difficulty Rule Integration

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check model relationship | difficultyRule belongsTo |
| 2 | Verify override_marks from difficulty_rules | Priority logic |
| 3 | Verify error/warning mode based on ignore_difficulty_config | Config flag checked |
| 4 | Verify warning message returned in response | Structured warning |
