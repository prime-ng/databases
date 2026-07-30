# lms_QuizQuestions_TcList

## Module: LmsQuiz → Quiz Management → Quiz Questions

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | LmsQuiz |
| Tab Group | Quiz Management |
| Feature | Quiz Questions |
| URL(s) | `/lms-quize/quiz-question` (resource index/create/store/show/edit/update/destroy), `/lms-quize/quiz-question/trash/view` (trashed), `/lms-quize/quiz-question/{id}/restore` (restore), `/lms-quize/quiz-question/{id}/force-delete` (forceDelete), `/lms-quize/quiz-question/{quiz_question}/toggle-status` (toggleStatus), `/lms-quize/search` (question search AJAX), `/lms-quize/existing` (existing questions AJAX), `/lms-quize/bulk-store` (bulk add AJAX), `/lms-quize/bulk-destroy` (bulk remove AJAX), `/lms-quize/update-marks` (marks update AJAX), `/lms-quize/update-ordinal` (ordinal update AJAX), `/lms-quize/get-sections`, `/lms-quize/get-subject-groups`, `/lms-quize/get-subjects`, `/lms-quize/get-lessons`, `/lms-quize/get-topics` (AJAX dependency endpoints) |
| Controller | `Modules\LmsQuiz\Http\Controllers\QuizQuestionController` |
| Model(s) | `QuizQuestion` (`Modules\LmsQuiz\Models\QuizQuestion`) — junction/pivot table linking `Quiz` → `QuestionBank` |
| Validation | `QuizQuestionRequest` (`Modules\LmsQuiz\Http\Requests\QuizQuestionRequest`) — single request for store and update |
| Permission Gates | `tenant.quiz-question.viewAny`, `.view`, `.create`, `.update`, `.delete`, `.restore`, `.forceDelete`, `.status` |
| Soft Deletes | Yes — `SoftDeletes` trait on QuizQuestion model |
| Activity Log | Yes — `activityLog()` helper called in store, update, destroy, restore, forceDelete, bulkDestroy |
| Import | Not supported |

---

## 2. Pre-conditions

- Required permission: `tenant.quiz-question.viewAny`
- At least one Quiz must exist (any status) for question linking
- At least one QuestionBank record (PUBLISHED status, MCQ type) must exist
- QuestionBank module must be active with questions seeded
- Quiz difficulty constraints (only_unused, only_authorised, scope_topic, difficulty_config) affect available questions

---

## 3. Default Data Load

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| Quiz Question List | `QuizQuestion::with(['quiz','question'])` via `queryBuilder()` | Filters by quiz_id, question_id, search, is_active | quiz_id, question_id, search (by question title/content or quiz title/code), is_active | 10 per page |
| Single Quiz Question | `QuizQuestion::with(['quiz','question','question.questionType','question.complexityLevel'])->findOrFail($id)` | By ID | None |
| Quiz list (dropdown) | `Quiz::where('is_active','1')->with('class','subject','topic')->get()` | | Only active quizzes |
| QuestionBank list | `QuestionBank::where('is_active','1')->get()` | | Only active questions |
| Question Types (create form) | `QuestionType::where('is_active','1')->get()` | | |
| Complexity Levels | `ComplexityLevel::where('is_active','1')->get()` | | |
| Difficulty Configs | `DifficultyDistributionConfig::where('is_active','1')->get()` | | |
| Bloom Taxonomies | `BloomTaxonomy::where('is_active','1')->get()` | | |
| Cognitive Skills | `CognitiveSkill::where('is_active','1')->get()` | | |
| Question Type Specificities | `QueTypeSpecifity::where('is_active','1')->get()` | | |
| Performance Categories | `PerformanceCategory::where('is_active',1)->get()` | | |
| Question Tags | `QuestionTag::where('is_active',1)->get()` | | |
| Classes/Sections/SubjectGroups/Subjects/Lessons/Topics (AJAX) | Various cascading endpoints | | |
| Existing Questions (AJAX) | `QuizQuestion::with(['question','question.*'])->where('quiz_id',$id)->get()` | By quiz_id | None |
| Search Questions (AJAX) | `QuestionBank::where('is_active',1)->where('status','PUBLISHED')` with multiple filters | class_id, section_id, subject_id, topic_id, tag_ids, complexity, bloom, cognitive, type_specificity, search_text, recommendation_type, performance_category, priority, for_quiz, for_exam, for_quest, only_unused, only_authorised | Max 50 results |

---

## 4. Test Data Strategy

- **QuizQuestion is a junction table**: Links existing `QuestionBank` records to a `Quiz`. Does NOT store question content — only `quiz_id`, `question_id`, `ordinal`, `marks_override`, `is_active`
- **Question Source**: All questions come from `qns_questions_bank` table via `QuestionBank` model. Only PUBLISHED, active, MCQ-type questions are available for quiz linking
- **Bulk Operations**: Adding/removing questions is done via AJAX (`bulkStore`, `bulkDestroy`). The single `store()` method also exists but is not the primary workflow
- **Exact Count/Marks Matching**: `bulkStore()` enforces that total questions after add must EXACTLY match `quiz.total_questions` and marks must EXACTLY match `quiz.total_marks`
- **Difficulty Distribution**: Complex validation via `DifficultyDistributionDetail` rules matching question_type_id + complexity_level_id (+ optional bloom/cognitive/specificity). Percentage-based min/max limits per rule
- **Quiz Constraints**: `only_unused_questions`, `only_authorised_questions`, `scope_topic_id`, and MCQ-only restrictions are enforced server-side
- **Ordinal Management**: Questions have `ordinal` field. `recalculateOrdinals()` runs after removal. `updateOrdinal()` allows drag-and-drop reordering with adjacent shifting
- **Marks Override**: Each QuizQuestion can override the default QuestionBank marks via `marks_override`. If null, `effective_marks` accessor returns QuestionBank marks
- **Usage Check**: `QuizQuestionUsageCheckService` checks if parent quiz has any student attempts before allowing edit/delete

---

## 5. Business Conditions

### 5.1 Database Schema

Table: `lms_quiz_questions`

| Column | Type | Constraints | Default | Notes |
|--------|------|-------------|---------|-------|
| id | bigint(20) unsigned | PK, AUTO_INCREMENT | | |
| quiz_id | bigint(20) unsigned | INDEX, FK → lms_quizzes.id | | Parent quiz (CASCADE on delete) |
| question_id | bigint(20) unsigned | INDEX, FK → qns_questions_bank.id | | Linked question from QuestionBank |
| ordinal | int(11) | | 0 | Display order within quiz |
| marks_override | decimal(8,2) | NULLABLE | NULL | Override QuestionBank marks; NULL = use default |
| is_active | tinyint(1) | | 1 | Boolean |
| created_at | timestamp | | CURRENT_TIMESTAMP | |
| updated_at | timestamp | | ON UPDATE CURRENT_TIMESTAMP | |
| deleted_at | timestamp | NULLABLE | NULL | |

Accessor: `effective_marks` = `$this->marks_override ?? $this->question->marks ?? 0`

### 5.2 Validation Rules — QuizQuestionRequest

| BC ID | Field | Rule | Notes |
|-------|-------|------|-------|
| BC-VAL-01 | quiz_id | required, exists:lms_quizzes,id | |
| BC-VAL-02 | question_id | required, exists:qns_questions_bank,id | |
| BC-VAL-03 | ordinal | required, integer, min:0 | Defaults to 0 in prepareForValidation |
| BC-VAL-04 | marks_override | nullable, numeric, min:0 | |
| BC-VAL-05 | is_active | boolean | Via prepareForValidation |

Note: `withValidator()` has commented-out checks for question count limit, marks limit, and difficulty config. These checks are NOT active in the Request — they are enforced in `bulkStore()` instead.

### 5.3 Authorization (Permission Gates)

| BC ID | Permission | Policy Method | Controller Method | Behavior Without |
|-------|-----------|---------------|-------------------|-----------------|
| BC-AUTH-01 | tenant.quiz-question.viewAny | viewAny() | index() | 403 |
| BC-AUTH-02 | tenant.quiz-question.view | view() | show(), existing() | 403 |
| BC-AUTH-03 | tenant.quiz-question.create | create() | create(), store(), search(), bulkStore() | 403 |
| BC-AUTH-04 | tenant.quiz-question.update | update() | edit(), update(), updateOrdinal(), updateMarks() | 403 |
| BC-AUTH-05 | tenant.quiz-question.delete | delete() | destroy(), bulkDestroy() | 403 |
| BC-AUTH-06 | tenant.quiz-question.restore | restore() | trashed(), restore() | 403 |
| BC-AUTH-07 | tenant.quiz-question.forceDelete | forceDelete() | forceDelete() | 403 |
| BC-AUTH-08 | tenant.quiz-question.status | status() | toggleStatus() | 403 |

Note: `status` gate exists in Policy but `toggleStatus` uses `tenant.quiz-question.update` — controller does not use `status` gate.

### 5.4 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Add single question (store) — duplicate check | Checks if (quiz_id, question_id) already exists; returns error if duplicate |
| BC-BIZ-02 | Add single question — only_unused check | If quiz.only_unused_questions=true, checks QuestionUsageLog for prior usage; blocks if used |
| BC-BIZ-03 | Add single question — only_authorised check | If quiz.only_authorised_questions=true, checks question.for_quiz=1; blocks if not authorised |
| BC-BIZ-04 | Add single question — scope_topic check | If quiz.scope_topic_id set, checks question.topic_id matches; blocks if out of scope |
| BC-BIZ-05 | Add single question — total_questions limit | Checks existing count + 1 ≤ quiz.total_questions; blocks if exceeded |
| BC-BIZ-06 | Add single question — total_marks limit | Checks current sum + new marks ≤ quiz.total_marks; blocks if exceeded |
| BC-BIZ-07 | Bulk add (bulkStore) — exact match required | Total questions after add must EXACTLY match quiz.total_questions; total marks must EXACTLY match quiz.total_marks; fails otherwise |
| BC-BIZ-08 | Bulk add — only unused constraint | If quiz.only_unused_questions=true, checks all selected questions for prior QUIZ usage |
| BC-BIZ-09 | Bulk add — only authorised constraint | If quiz.only_authorised_questions=true, all questions must have for_quiz=1 |
| BC-BIZ-10 | Bulk add — scope topic constraint | If quiz.scope_topic_id set, all questions must match that topic |
| BC-BIZ-11 | Bulk add — MCQ-only constraint | Only MCQ_SINGLE and MCQ_MULTI question types allowed; non-MCQ blocked |
| BC-BIZ-12 | Bulk add — difficulty distribution validation | If quiz.difficulty_config_id set, validates each question against DifficultyDistributionDetail rules (question_type_id + complexity_level_id + optional bloom/cognitive/specificity). Blocks if no matching rule or exceeds min/max percentages. Skipped if ignore_difficulty_config=true |
| BC-BIZ-13 | Bulk add — marks from difficulty rules | If matching difficulty rule has marks_per_question, uses it as marks_override |
| BC-BIZ-14 | Bulk add — usage logging | After successful add, creates QuestionUsageLog entry for each question with type='QUIZ' |
| BC-BIZ-15 | Bulk remove (bulkDestroy) — usage log cleanup | Deletes associated QuestionUsageLog records for removed questions |
| BC-BIZ-16 | Bulk remove — recalculate ordinals | After removal, calls recalculateOrdinals() to reassign sequential ordinals |
| BC-BIZ-17 | Update ordinal — adjacent shifting | When ordinal changes, shifts adjacent questions up/down within same quiz |
| BC-BIZ-18 | Update marks — marks limit check | Checks if updated marks would exceed quiz.total_marks; blocks if exceeded |
| BC-BIZ-19 | Update marks — null when matching original | If marks_override matches QuestionBank default marks, stores null |
| BC-BIZ-20 | Edit/update/delete — usage check | Uses QuizQuestionUsageCheckService to check if parent quiz has any student attempts; blocks if attempts exist |
| BC-BIZ-21 | Show — usage details display | Calls QuizQuestionUsageCheckService.getUsageDetails() and getQuizAttemptsDetails() for display |
| BC-BIZ-22 | Question search — default MCQ filter | If no question_type_id specified, defaults to MCQ_SINGLE + MCQ_MULTI types only |
| BC-BIZ-23 | Question search — quiz context filters | Applies quiz's only_unused, only_authorised, scope_topic_id filters to question search results |
| BC-BIZ-24 | Question search — exclude existing | Excludes question_ids already linked to the quiz |
| BC-BIZ-25 | Single store + update — does NOT sync quiz totals | total_questions and total_marks on quiz are NOT updated by single store/update/destroy |

### 5.5 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|------------------|----------------|
| BC-REF-01 | quiz_id | lms_quizzes (id) | CASCADE |
| BC-REF-02 | question_id | qns_questions_bank (id) | — |

### 5.6 Question Search Filters

| Filter | Field | Description |
|--------|-------|-------------|
| Class | class_id | Academic filter |
| Section | section_id | Academic filter |
| Subject | subject_id | Academic filter |
| Topic | topic_id | Academic filter (direct or via questionTopics) |
| Tag IDs | tag_ids | Array of question tag IDs |
| Question Type | question_type_id | Defaults to MCQ_SINGLE + MCQ_MULTI if not specified |
| Complexity | complexity_level_id | Difficulty level |
| Bloom Taxonomy | bloom_id | Cognitive domain level |
| Cognitive Skill | cognitive_skill_id | Specific skill |
| Type Specificity | question_type_specificity_id | Question format variation |
| Recommendation Type | recommendation_type | From performance categories |
| Performance Category | performance_category_id | From performance categories |
| Priority | priority | From performance categories |
| For Quiz | for_quiz | Flag for quiz usage |
| For Exam | for_exam | Flag for exam usage |
| For Quest | for_quest | Flag for quest usage |
| Only Unused | only_unused | Excludes previously used questions |
| Only Authorised | only_authorised | Only questions with for_quiz=1 |
| Search Text | search_text | Free text search on ques_title and question_content |
| Quantity | quantity | Max results (default 50) |

---

## 6. Test Case List

### 6.1 Positive Test Cases

| TC ID | Description | Expected Result | Status |
|-------|-------------|----------------|--------|
| TC-P01 | Add Single Question (store) — to DRAFT quiz with no constraints | QuizQuestion record created with quiz_id, question_id, ordinal, is_active=1 | ⬜ |
| TC-P02 | Add Single Question — with marks_override set | marks_override saved; effective_marks returns override value | ⬜ |
| TC-P03 | Add Single Question — without marks_override (null) | marks_override=NULL; effective_marks returns QuestionBank default marks | ⬜ |
| TC-P04 | Bulk Add Questions (bulkStore) — exact match total questions | Adds N questions where existing+N = quiz.total_questions; marks also match exactly | ⬜ |
| TC-P05 | Bulk Add Questions — marks from difficulty config | Questions with matching difficulty rule get marks_per_question as marks_override | ⬜ |
| TC-P06 | Bulk Add Questions — with ignore_difficulty_config=true | Questions added even if they don't match difficulty rules; warning returned | ⬜ |
| TC-P07 | View Quiz Question List (index) | Paginated list with quiz code, question title, marks, ordinal | ⬜ |
| TC-P08 | View Single Quiz Question (show) | Question details with quiz info, usage details, attempt details | ⬜ |
| TC-P09 | View Existing Questions (existing AJAX) | JSON with all questions linked to quiz, stats (count, marks), difficulty rules | ⬜ |
| TC-P10 | Search Questions (search AJAX) | JSON with filtered questions from QuestionBank matching quiz criteria | ⬜ |
| TC-P11 | Update Quiz Question (update) — change question_id | Links different question; duplicate check runs | ⬜ |
| TC-P12 | Update Quiz Question — change marks_override | marks_override updated; effective_marks recalculated | ⬜ |
| TC-P13 | Update Ordinal (updateOrdinal AJAX) | Ordinal changed; adjacent questions shifted | ⬜ |
| TC-P14 | Update Marks (updateMarks AJAX) — within total_marks limit | marks_override updated; returns success with new marks | ⬜ |
| TC-P15 | Update Marks — same as original QuestionBank marks | marks_override set to null (no override stored) | ⬜ |
| TC-P16 | Remove Single Question (destroy) | QuizQuestion soft-deleted; usage log NOT removed | ⬜ |
| TC-P17 | Bulk Remove Questions (bulkDestroy AJAX) | Questions force-deleted; usage logs deleted; ordinals recalculated | ⬜ |
| TC-P18 | Restore Soft-Deleted Question | QuizQuestion restored | ⬜ |
| TC-P19 | Force Delete Question (forceDelete) | QuizQuestion permanently deleted | ⬜ |
| TC-P20 | View Trashed Questions (trashed) | Paginated list of soft-deleted quiz questions | ⬜ |
| TC-P21 | Toggle active status (toggleStatus AJAX) | is_active toggled; JSON success response | ⬜ |
| TC-P22 | Cascading AJAX — getSections by class_id | JSON sections array | ⬜ |
| TC-P23 | Cascading AJAX — getSubjectGroups by class+section | JSON subject groups array | ⬜ |
| TC-P24 | Cascading AJAX — getSubjects by subject_group_id | JSON subjects array | ⬜ |
| TC-P25 | Cascading AJAX — getLessons by subject_id | JSON lessons array | ⬜ |
| TC-P26 | Cascading AJAX — getTopics by lesson_id | JSON topics array | ⬜ |
| TC-P27 | Search Questions — combined filters (bloom + cognitive + topic + complexity) | JSON filtered to match ALL specified filter criteria | ⬜ |
| TC-P28 | Update Question (update PUT) — marks change within total_marks limit | Question updated; marks_override saved; total_marks not exceeded | ⬜ |

### 6.2 Negative Test Cases

| TC ID | Description | Expected Result | Status |
|-------|-------------|----------------|--------|
| TC-N01 | Store — Empty quiz_id | Validation error: quiz_id required | ⬜ |
| TC-N02 | Store — Invalid quiz_id | Validation error: exists | ⬜ |
| TC-N03 | Store — Empty question_id | Validation error: question_id required | ⬜ |
| TC-N04 | Store — Invalid question_id | Validation error: exists | ⬜ |
| TC-N05 | Store — Duplicate (quiz_id, question_id) | Error: "This question already exists in the quiz." | ⬜ |
| TC-N06 | Store — quiz.only_unused_questions=true and question used before | Error: "This quiz requires unused questions only." | ⬜ |
| TC-N07 | Store — quiz.only_authorised_questions=true and question.for_quiz=0 | Error: "This quiz requires authorised questions only." | ⬜ |
| TC-N08 | Store — quiz.scope_topic_id set and question.topic_id different | Error: "This question is out of the quiz topic scope." | ⬜ |
| TC-N09 | Store — Total questions limit exceeded | Error: "Total questions limit reached." | ⬜ |
| TC-N10 | Store — Total marks limit exceeded | Error: "Total marks limit would be exceeded." | ⬜ |
| TC-N11 | Bulk Store — No questions selected (empty questions_data) | Error: "No questions selected." | ⬜ |
| TC-N12 | Bulk Store — Exact match failure (count mismatch) | Error: "Exact match required. Questions: X/Y, Marks: X/Y" | ⬜ |
| TC-N13 | Bulk Store — Already used question (only_unused=true) | Error: "This quiz requires unused questions only." | ⬜ |
| TC-N14 | Bulk Store — Unauthorised question (only_authorised=true) | Error: "This quiz requires authorised questions only." | ⬜ |
| TC-N15 | Bulk Store — Out of scope topic | Error: "This quiz is scoped to topic..." | ⬜ |
| TC-N16 | Bulk Store — Non-MCQ question | Error: "Only MCQ questions are allowed." | ⬜ |
| TC-N17 | Bulk Store — Difficulty config mismatch (strict mode) | Error: "Questions with Type ID: X and Complexity ID: Y do not match any rule." | ⬜ |
| TC-N18 | Bulk Store — Difficulty config percentage exceeded | Error: "Cannot add N questions... Max allowed: X, Existing: Y" | ⬜ |
| TC-N19 | Bulk Destroy — Empty question_ids | Validation error: question_ids required | ⬜ |
| TC-N20 | Update Ordinal — Invalid quiz_question_id | Validation error: exists | ⬜ |
| TC-N21 | Update Marks — Exceeds total_marks | Error: "Total marks limit would be exceeded." | ⬜ |
| TC-N22 | Edit/Update/Destroy — Question has student attempts | Error: "Cannot edit/delete because students have already started attempts." | ⬜ |
| TC-N23 | View — without `tenant.quiz-question.view` permission | 403 Forbidden | ⬜ |
| TC-N24 | Create — without `tenant.quiz-question.create` permission | 403 Forbidden | ⬜ |
| TC-N25 | Update — without `tenant.quiz-question.update` permission | 403 Forbidden | ⬜ |
| TC-N26 | Delete — without `tenant.quiz-question.delete` permission | 403 Forbidden | ⬜ |

### 6.3 Dependency Test Cases

| TC ID | Category | Priority | Description | Expected Result | Status |
|-------|----------|----------|-------------|----------------|--------|
| TC-D01 | Cascade — Quiz Delete | P1 | Soft delete parent quiz → verify QuizQuestion records cascade | QuizQuestion.deleted_at set via FK cascade | ⬜ |
| TC-D02 | Cascade — Quiz Force Delete | P1 | Force delete parent quiz → verify QuizQuestion records cascade-deleted | QuizQuestion records permanently deleted | ⬜ |
| TC-D03 | Business — Bulk Add Usage Log | P1 | Bulk add questions → verify QuestionUsageLog entries created | Logs with type='QUIZ', context_id=quiz_id | ⬜ |
| TC-D04 | Business — Bulk Remove Usage Log Cleanup | P1 | Bulk remove questions → verify QuestionUsageLog entries deleted | Associated usage logs force-deleted | ⬜ |
| TC-D05 | Business — Ordinal Recalculation | P1 | Add questions → verify ordinals sequential; remove → verify recalculated | Ordinals always start at 1 and are sequential | ⬜ |
| TC-D06 | Business — Marks Override vs QuestionBank Marks | P2 | Add question with marks_override vs without → verify effective_marks | marks_override=NULL returns QuestionBank marks | ⬜ |
| TC-D07 | Business — Difficulty Rules with Optional Fields | P2 | Config with bloom/cognitive/specificity rules → add matching questions | Only questions matching ALL rule attributes accepted | ⬜ |
| TC-D08 | Business — Search Filter Privacy | P1 | Search for questions with quiz_id → verify existing questions excluded | Already-linked questions not in search results | ⬜ |
| TC-D09 | Business — Search Default MCQ Filter | P2 | Search without question_type_id → verify only MCQ types returned | Defaults to MCQ_SINGLE + MCQ_MULTI | ⬜ |
| TC-D10 | Cascade — Ordinal Adjacent Shift | P2 | Move question from position 3 to 7 → verify positions 4-7 shift up | Adjacent questions decremented/incremented correctly | ⬜ |

### 6.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | Status |
|-------|----------|----------|-------------|----------------|--------|
| TC-CR01 | CR | P1 | Controller store() — duplicate check | Checks `where('quiz_id',..)->where('question_id',..)->exists()` before insert | ◌ |
| TC-CR02 | CR | P1 | Controller store() — constraint checks | Checks only_unused, only_authorised, scope_topic, count limit, marks limit before insert | ◌ |
| TC-CR03 | CR | P1 | Controller store() — usage log | Creates QuestionUsageLog with type='QUIZ' after successful insert | ◌ |
| TC-CR04 | CR | P1 | Controller bulkStore() — exact match validation | Requires total count to exactly match quiz.total_questions and marks to exactly match quiz.total_marks | ◌ |
| TC-CR05 | CR | P1 | Controller bulkStore() — constraint checks | Validates only_unused, only_authorised, scope_topic, MCQ-only, difficulty distribution | ◌ |
| TC-CR06 | CR | P1 | Controller bulkStore() — difficulty distribution validation | Validates each question against DifficultyDistributionDetail rules with percentage-based limits | ◌ |
| TC-CR07 | CR | P1 | Controller bulkStore() — marks from rules | If difficulty rule has marks_per_question, uses it as marks_override | ◌ |
| TC-CR08 | CR | P1 | Controller bulkStore() — difficulty warning mode | If ignore_difficulty_config=true, allows violations but returns warning message | ◌ |
| TC-CR09 | CR | P1 | Controller bulkStore() — transaction | All operations wrapped in DB::beginTransaction/commit/rollback | ◌ |
| TC-CR10 | CR | P1 | Controller bulkDestroy() — usage log cleanup | Force-deletes QuestionUsageLog for each removed question | ◌ |
| TC-CR11 | CR | P1 | Controller bulkDestroy() — ordinal recalculation | Calls recalculateOrdinals() after removal | ◌ |
| TC-CR12 | CR | P1 | Controller updateOrdinal() — adjacent shifting | Decrements/increments ordinals of affected questions to maintain sequential order | ◌ |
| TC-CR13 | CR | P1 | Controller updateMarks() — total marks limit | Checks potential new total ≤ quiz.total_marks; blocks if exceeded | ◌ |
| TC-CR14 | CR | P1 | Controller updateMarks() — null when matching default | If marks_override ≈ question.marks, stores null instead | ◌ |
| TC-CR15 | CR | P1 | QuizQuestionRequest — withValidator commented out | The after-validation checks for count limit, marks limit, and difficulty config are commented out — NOT enforced at request level | ◌ |
| TC-CR16 | CR | P2 | Controller edit()/update()/destroy() — usage check | Calls QuizQuestionUsageCheckService.isUsed() before allowing modification | ◌ |
| TC-CR17 | CR | P2 | Controller show() — usage details | Calls getUsageDetails() and getQuizAttemptsDetails() for display | ◌ |
| TC-CR18 | CR | P2 | Controller search() — default MCQ filter | If no question_type_id, defaults to MCQ_SINGLE + MCQ_MULTI | ◌ |
| TC-CR19 | CR | P2 | Controller search() — quiz context filters | Applies quiz's only_unused, only_authorised, scope_topic_id to search | ◌ |
| TC-CR20 | CR | P2 | Model QuizQuestion — effective_marks accessor | Returns marks_override ?? question->marks ?? 0 | ◌ |
| TC-CR21 | CR | P1 | Controller — findDifficultyRuleMatch() null wildcard matching | Matches first rule where question_type_id + complexity_level_id match AND (bloom_id IS NULL OR matches) AND (cognitive_skill_id IS NULL OR matches) AND (ques_type_specificity_id IS NULL OR matches) — null fields act as wildcards | ◌ |
| TC-CR22 | CR | P1 | Controller — validateDifficultyDistribution() maxAllowed calculation | Uses `ceil(calculationBase × rule.max_percentage ÷ 100)` formula; rounds up so 3.1 → max 4; minAllowed uses `floor()` | ◌ |
| TC-CR23 | CR | P1 | Controller store() — activityLog called after creation | Calls `activityLog($quizQuestion, 'Stored', ...)`, creates `activity_log` entry with subject_id, event='Stored', description | ◌ |
| TC-CR24 | CR | P1 | Controller update()/destroy()/restore()/forceDelete() — activityLog called on all state transitions | Each CRUD method calls `activityLog()` with correct event: 'Updated', 'Trashed', 'Restored', 'Deleted', 'Toggled' | ◌ |

---

## 7. Detailed Test Steps

### 7.1 Positive TC Steps

#### TC-P01: Add Single Question to DRAFT Quiz

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with user having `tenant.quiz-question.create` permission | Dashboard loads |
| 2 | Navigate to Quiz Questions → click Create New | Create form loads with quiz dropdown, question dropdown, ordinal, marks_override fields |
| 3 | Select a DRAFT quiz (no constraints) from dropdown | Quiz selected |
| 4 | Select a PUBLISHED MCQ question from QuestionBank dropdown | Question selected |
| 5 | Set Ordinal to 1 | Ordinal set |
| 6 | Leave marks_override empty | marks_override = NULL |
| 7 | Click Submit | POST sent to store endpoint |
| 8 | Verify success flash message | Success message displayed |
| 9 | DB check: `SELECT * FROM lms_quiz_questions WHERE quiz_id=X AND question_id=Y` | Record exists with marks_override=NULL, is_active=1, ordinal=1 |

---

#### TC-P02: Add Single Question with Marks Override

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to Quiz Questions → Create New | Create form loads |
| 2 | Select a DRAFT quiz (no constraints) | Quiz selected |
| 3 | Select a PUBLISHED MCQ question | Question selected |
| 4 | Set Ordinal to 1 | Ordinal set |
| 5 | Enter marks_override = 5.00 | marks_override filled |
| 6 | Click Submit | POST sent to store |
| 7 | Verify success flash | Success message displayed |
| 8 | DB check: `SELECT marks_override FROM lms_quiz_questions WHERE ...` | marks_override = 5.00 |
| 9 | Check `effective_marks` accessor | Returns 5.00 (override value) |

---

#### TC-P03: Add Single Question Without Marks Override

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to Quiz Questions → Create New | Create form loads |
| 2 | Select a DRAFT quiz (no constraints) | Quiz selected |
| 3 | Select a PUBLISHED MCQ question (QuestionBank default marks = 4.00) | Question selected |
| 4 | Set Ordinal to 1 | Ordinal set |
| 5 | Leave marks_override empty | marks_override = NULL |
| 6 | Click Submit | POST sent to store |
| 7 | Verify success | Success message displayed |
| 8 | DB check: `SELECT marks_override FROM lms_quiz_questions WHERE ...` | marks_override = NULL |
| 9 | Check `effective_marks` accessor | Returns QuestionBank default marks (4.00) |

---

#### TC-P04: Bulk Add Questions — Exact Count/Marks Match

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create/use a quiz with total_questions=5, total_marks=25, no existing questions | Quiz ready with 0 linked questions |
| 2 | Open quiz in question builder UI | Question builder loads with search panel |
| 3 | Search and select exactly 5 PUBLISHED MCQ questions (each 5 marks) | 5 questions selected |
| 4 | Submit bulk add | POST sent to bulkStore |
| 5 | Verify success message: "5 questions added successfully." | Success response |
| 6 | DB check: `SELECT COUNT(*) FROM lms_quiz_questions WHERE quiz_id=X` | 5 records created (0 + 5 = total_questions=5) |
| 7 | DB check: `SELECT SUM(COALESCE(marks_override, q.marks)) FROM lms_quiz_questions ... JOIN ...` | Sum = 25 (matches total_marks=25) |
| 8 | Verify QuestionUsageLog records created | Log entries with type='QUIZ', context_id=quiz_id |

---

#### TC-P05: Bulk Add Questions — Marks from Difficulty Config

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create quiz with difficulty_config_id pointing to config with rules that have marks_per_question set | Quiz with difficulty distribution rules |
| 2 | Search questions matching the rule criteria (question_type_id + complexity_level_id) | Matching questions returned |
| 3 | Add matching questions via bulk add | POST sent to bulkStore |
| 4 | Verify marks_override set to rules' marks_per_question for applicable questions | marks_override = marks_per_question from matching rule |

---

#### TC-P06: Bulk Add Questions with Ignore Difficulty Config

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create quiz with difficulty_config_id and ignore_difficulty_config=true | Quiz configured to ignore difficulty rules |
| 2 | Search questions that do NOT match any difficulty distribution rule | Non-matching questions found |
| 3 | Add questions via bulk add | POST sent to bulkStore |
| 4 | Verify success despite difficulty config mismatch | Questions added successfully |
| 5 | Check response includes warning message | Warning about difficulty config violations returned |

---

#### TC-P07: View Quiz Question List

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with user having `tenant.quiz-question.viewAny` permission | Dashboard loads |
| 2 | Navigate to Quiz Questions index page | Paginated list loads with table |
| 3 | Check table columns | Shows quiz code, question title, marks, ordinal, status, action buttons |
| 4 | Verify pagination (10 per page) | Pagination links visible if 10+ records exist |

---

#### TC-P08: View Single Quiz Question Details

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click "View" (eye) icon on a QuizQuestion record | Show page loads with details |
| 2 | Check quiz information displayed | Quiz code, name visible |
| 3 | Check question details displayed | Question title, content, marks, complexity level shown |
| 4 | Check usage details section | Usage details from QuizQuestionUsageCheckService.getUsageDetails() displayed |
| 5 | Check attempt details section | Attempt details from getQuizAttemptsDetails() displayed |

---

#### TC-P09: View Existing Questions via AJAX

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Call `/lms-quize/existing?quiz_id=X` with GET | JSON response returned |
| 2 | Verify response contains all questions linked to the quiz | Array of QuizQuestion records with question, questionType, complexityLevel relations |
| 3 | Check stats object in response | Contains count and total marks |
| 4 | Check difficulty rules in response | Difficulty distribution rules included if configured |

---

#### TC-P10: Search Questions via AJAX

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Call `/lms-quize/search` with quiz_id and filter parameters (class_id, subject_id, etc.) | JSON response with filtered questions |
| 2 | Verify response contains filtered questions from QuestionBank | Array of matching QuestionBank records |
| 3 | Verify existing quiz questions are excluded from results | Already-linked question_ids not present |
| 4 | Verify only MCQ types returned by default (MCQ_SINGLE + MCQ_MULTI) | No non-MCQ question types in results |
| 5 | Verify quiz constraints applied (only_unused, only_authorised, scope_topic) | Constraints respected in filtered results |

---

#### TC-P27: Search Questions — Combined Filters (Bloom + Cognitive + Topic + Complexity)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Call `/lms-quize/search` with class_id, subject_id, topic_id, complexity_level_id, bloom_id, cognitive_skill_id, and search_text | JSON response |
| 2 | Verify all filters applied in combination (AND logic) | Every returned question matches ALL filter criteria |
| 3 | Verify bloom_id filter | Only questions with matching bloom taxonomy level returned |
| 4 | Verify cognitive_skill_id filter | Only questions with matching cognitive skill returned |
| 5 | Verify topic_id filter (direct match on topic_id or via questionTopics) | Questions belong to specified topic |
| 6 | Verify complexity_level_id filter | Only questions with matching difficulty level returned |
| 7 | Verify search_text filter | Questions with matching title/content text returned |
| 8 | Submit same request without bloom_id/cognitive_skill_id | Results include questions without those filters (wider set) |

---

#### TC-P11: Update Quiz Question — Change Question

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create QuizQuestion linking quiz Q1 to question QB_A | Record exists with ID=X |
| 2 | Navigate to edit page for that record | Edit form loads with current data pre-filled |
| 3 | Change question_id to a different valid question QB_B | Question changed in form |
| 4 | Submit update | PUT request sent to update |
| 5 | Verify success flash | "Updated successfully" message |
| 6 | DB check: `SELECT question_id FROM lms_quiz_questions WHERE id=X` | question_id = QB_B |
| 7 | Negative: try to change to a question already in same quiz | Duplicate check blocks: "This question already exists in the quiz." |

---

#### TC-P12: Update Quiz Question — Change Marks Override

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create QuizQuestion with marks_override=3.00 | Record exists |
| 2 | Edit the record, change marks_override to 5.00 | Marks updated in form |
| 3 | Submit update | PUT request sent |
| 4 | DB check: `SELECT marks_override FROM lms_quiz_questions WHERE id=X` | marks_override = 5.00 |
| 5 | Check `effective_marks` accessor | Returns 5.00 |

---

#### TC-P28: Update Question (PUT) — Marks Change Within Total Marks Limit

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create quiz Q1 with total_marks=20 | Quiz exists |
| 2 | Create QuizQuestion linking Q1 → QB_A with marks_override=5, and another question QB_B with marks_override=8 | Total current marks = 13 |
| 3 | Edit the record for QB_A, change marks_override from 5 to 10 | marks_override changed to 10 |
| 4 | Submit update (PUT) | PUT request to update |
| 5 | Verify success flash | "Updated successfully" message |
| 6 | DB check: `SELECT marks_override FROM lms_quiz_questions WHERE id=X` | marks_override = 10.00 |
| 7 | Verify total marks = 10+8 = 18 ≤ 20 (within limit) | Update succeeds |
| 8 | Now change QB_A marks_override from 10 to 15 (potential total = 15+8 = 23 > 20) | Blocked: "Cannot update question. Total marks limit (20) would be exceeded." |

---

#### TC-P13: Update Ordinal via AJAX

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 3 QuizQuestion records for same quiz with ordinals 1, 2, 3 | Ordinals: 1, 2, 3 |
| 2 | Call updateOrdinal with quiz_question_id of ordinal-1 record, new_ordinal=3 | AJAX POST sent |
| 3 | Verify JSON success response | `{success: true}` |
| 4 | DB check: ordinals of all 3 records | Moved question → 3, original 2→1, original 3→2 (adjacent shift) |

---

#### TC-P14: Update Marks via AJAX — Within Limit

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Quiz with total_marks=10; one QuizQuestion has marks_override=3, other questions sum to 5 | Current total marks = 8 |
| 2 | Call updateMarks with quiz_question_id=X, marks=2 (total would be 10, within limit) | AJAX POST sent |
| 3 | Verify JSON success response | `{success: true, marks_override: 2}` |
| 4 | DB check: `SELECT marks_override FROM lms_quiz_questions WHERE id=X` | marks_override = 2.00 |

---

#### TC-P15: Update Marks — Null When Matching Default

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | QuizQuestion linked to question with QuestionBank marks=4.00; current marks_override=5.00 | marks_override=5.00 |
| 2 | Call updateMarks with quiz_question_id=X, marks=4.00 (same as QuestionBank default) | AJAX POST sent |
| 3 | Verify JSON success response | `{success: true}` |
| 4 | DB check: `SELECT marks_override FROM lms_quiz_questions WHERE id=X` | marks_override = NULL (stored as null instead of 4.00) |

---

#### TC-P16: Remove Single Question (Soft Delete)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create QuizQuestion record | Record exists with ID=X |
| 2 | Click Delete (trash icon) on that row | SweetAlert confirmation prompt |
| 3 | Confirm deletion | DELETE request sent to destroy |
| 4 | Verify success flash | "Moved to trash" message |
| 5 | DB check: `SELECT deleted_at FROM lms_quiz_questions WHERE id=X` | deleted_at NOT NULL (soft-deleted) |
| 6 | Verify QuestionUsageLog NOT removed | Associated usage log still exists |

---

#### TC-P17: Bulk Remove Questions via AJAX

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Have a quiz with 5 questions linked | 5 QuizQuestion records exist |
| 2 | Call bulkDestroy with 2 question_ids | AJAX POST sent to bulkDestroy |
| 3 | Verify JSON success response | `{success: true, message: "..."}` |
| 4 | DB check: 2 QuizQuestion records force-deleted | Permanently removed from DB |
| 5 | DB check: associated QuestionUsageLog records force-deleted | Usage logs for removed questions deleted |
| 6 | DB check: remaining 3 questions have recalculated ordinals | Ordinals: 1, 2, 3 (sequential, no gaps) |

---

#### TC-P18: Restore Soft-Deleted Question

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete a QuizQuestion record | Record in trash, deleted_at NOT NULL |
| 2 | Navigate to trash page (`/lms-quize/quiz-question/trash/view`) | Trash list shows deleted record |
| 3 | Click "Restore" button on that row | GET request sent to restore route |
| 4 | Verify success flash | "Restored successfully" message |
| 5 | DB check: `SELECT deleted_at FROM lms_quiz_questions WHERE id=X` | deleted_at = NULL (restored) |

---

#### TC-P19: Force Delete Question

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete a QuizQuestion record | Record in trash |
| 2 | Navigate to trash page | Trash shows the record |
| 3 | Click "Force Delete" button | SweetAlert confirmation prompt |
| 4 | Confirm | DELETE request sent to forceDelete |
| 5 | Verify success flash | "Permanently deleted" message |
| 6 | DB check: `SELECT * FROM lms_quiz_questions WHERE id=X` (with trashed) | Record permanently removed |

---

#### TC-P20: View Trashed Questions

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete at least one QuizQuestion record | Record in trash |
| 2 | Navigate to `/lms-quize/quiz-question/trash/view` | Trash page loads with table |
| 3 | Check table columns | Shows quiz code, question title, marks, ordinal, action buttons |
| 4 | Verify soft-deleted record is visible | Deleted record displayed in table |
| 5 | Check "Restore" button is present | Visible (if user has restore permission) |
| 6 | Check "Force Delete" button is present | Visible (if user has forceDelete permission) |
| 7 | Empty state: no deleted records | "No Data Found" message displayed |

---

#### TC-P21: Toggle Active Status via AJAX

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create QuizQuestion with is_active=1 | Record active |
| 2 | Click the status toggle switch on that row | AJAX POST to toggle-status with `{is_active: false}` |
| 3 | Verify JSON response | `{success: true, is_active: false, message: "..."}` |
| 4 | DB check: `SELECT is_active FROM lms_quiz_questions WHERE id=X` | is_active = 0 |
| 5 | Click toggle switch again | AJAX POST with `{is_active: true}` |
| 6 | DB check | is_active = 1 |

---

#### TC-P22: Cascading AJAX — Get Sections

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Call `/lms-quize/get-sections?class_id=X` | JSON response with sections array |
| 2 | Verify response format | Array of `{id, name}` objects matching the class |

---

#### TC-P23: Cascading AJAX — Get Subject Groups

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Call `/lms-quize/get-subject-groups?class_id=X&section_id=Y` | JSON response with subject groups array |
| 2 | Verify response format | Array of `{id, name}` objects |

---

#### TC-P24: Cascading AJAX — Get Subjects

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Call `/lms-quize/get-subjects?subject_group_id=X` | JSON response with subjects array |
| 2 | Verify response format | Array of `{id, name}` objects |

---

#### TC-P25: Cascading AJAX — Get Lessons

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Call `/lms-quize/get-lessons?subject_id=X` | JSON response with lessons array |
| 2 | Verify response format | Array of `{id, name}` objects |

---

#### TC-P26: Cascading AJAX — Get Topics

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Call `/lms-quize/get-topics?lesson_id=X` | JSON response with topics array |
| 2 | Verify response format | Array of `{id, name}` objects |

---

### 7.2 Negative TC Steps

#### TC-N01: Store — Empty quiz_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to Quiz Questions → Create New | Create form loads |
| 2 | Leave quiz dropdown empty / do not select any quiz | No quiz selected |
| 3 | Fill other required fields (question_id, ordinal) | Fields filled |
| 4 | Click Submit | POST sent to store |
| 5 | Verify validation error response | "The quiz id field is required." |

---

#### TC-N02: Store — Invalid quiz_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send direct POST to store with quiz_id=99999 (non-existent) | POST with invalid quiz_id |
| 2 | Verify validation error | "The selected quiz id is invalid." |

---

#### TC-N03: Store — Empty question_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form loads |
| 2 | Select a valid quiz | Quiz selected |
| 3 | Leave question dropdown empty | No question selected |
| 4 | Fill ordinal | Ordinal set |
| 5 | Click Submit | POST sent to store |
| 6 | Verify validation error | "The question id field is required." |

---

#### TC-N04: Store — Invalid question_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send direct POST to store with question_id=99999 (non-existent) | POST with invalid question_id |
| 2 | Verify validation error | "The selected question id is invalid." |

---

#### TC-N05: Store — Duplicate Question in Quiz

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create QuizQuestion linking quiz Q1 to question QB_A | Record exists |
| 2 | Attempt to create another QuizQuestion with same quiz_id=Q1 and question_id=QB_A | POST sent to store |
| 3 | Verify duplicate error returned | "This question already exists in the quiz." |

---

#### TC-N06: Store — Only Unused Constraint

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create quiz with only_unused_questions=true | Quiz configured |
| 2 | Use a question that has been used in a previous quiz attempt (QuestionUsageLog exists) | Question has prior usage |
| 3 | Attempt to add that question via single store | POST sent to store |
| 4 | Verify error | "This quiz requires unused questions only." |

---

#### TC-N07: Store — Only Authorised Constraint

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create quiz with only_authorised_questions=true | Quiz configured |
| 2 | Select a question with for_quiz=0 (not authorised for quiz) | Question not authorised |
| 3 | Attempt to add that question via single store | POST sent to store |
| 4 | Verify error | "This quiz requires authorised questions only." |

---

#### TC-N08: Store — Scope Topic Constraint

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create quiz with scope_topic_id = T1 | Quiz scoped to topic T1 |
| 2 | Select a question with topic_id != T1 (different topic) | Question out of scope |
| 3 | Attempt to add that question via single store | POST sent to store |
| 4 | Verify error | "This question is out of the quiz topic scope." |

---

#### TC-N09: Store — Total Questions Limit Exceeded

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Quiz with total_questions=5, already has 5 questions linked | Quiz at capacity |
| 2 | Attempt to add one more question via single store | POST sent to store |
| 3 | Verify error | "Total questions limit reached." |

---

#### TC-N10: Store — Total Marks Limit Exceeded

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Quiz with total_marks=10, current sum of marks = 9, new question marks = 2 | Adding would make total 11 (>10) |
| 2 | Attempt to add that question via single store | POST sent to store |
| 3 | Verify error | "Total marks limit would be exceeded." |

---

#### TC-N11: Bulk Store — No Questions Selected

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open quiz in question builder UI | Builder loads with search panel |
| 2 | Submit bulk add without selecting any questions (empty questions_data) | POST sent to bulkStore |
| 3 | Verify error | "No questions selected." |

---

#### TC-N12: Bulk Store — Exact Match Failure (Count Mismatch)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Quiz with total_questions=5, 2 existing questions already linked | 2 questions exist |
| 2 | Try to add 2 new questions (total would be 4, NOT 5) | POST sent to bulkStore |
| 3 | Verify error about exact count mismatch | "Exact match required. Questions: 4/5, Marks: ..." |

---

#### TC-N13: Bulk Store — Already Used Question

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Quiz with only_unused_questions=true | Quiz configured |
| 2 | Include a previously used question in bulk selection | Question has QuestionUsageLog |
| 3 | Submit bulk add | POST sent to bulkStore |
| 4 | Verify error | "This quiz requires unused questions only." |

---

#### TC-N14: Bulk Store — Unauthorised Question

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Quiz with only_authorised_questions=true | Quiz configured |
| 2 | Include a question with for_quiz=0 in bulk selection | Question not authorised |
| 3 | Submit bulk add | POST sent to bulkStore |
| 4 | Verify error | "This quiz requires authorised questions only." |

---

#### TC-N15: Bulk Store — Out of Scope Topic

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Quiz with scope_topic_id=T1 | Quiz scoped to topic T1 |
| 2 | Include a question with topic_id != T1 in bulk selection | Question out of scope |
| 3 | Submit bulk add | POST sent to bulkStore |
| 4 | Verify error | "This quiz is scoped to topic..." |

---

#### TC-N16: Bulk Store — Non-MCQ Question

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Include a non-MCQ question (e.g., ESSAY, SHORT_ANSWER) in bulk selection | Non-MCQ question type |
| 2 | Submit bulk add | POST sent to bulkStore |
| 3 | Verify error | "Only MCQ questions are allowed." |

---

#### TC-N17: Bulk Store — Difficulty Config Mismatch

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Quiz with difficulty_config_id with rules for specific (question_type_id, complexity_level_id) pairs | Rules defined |
| 2 | Try to add a question with non-matching type/complexity combination | Question does not match any rule |
| 3 | Submit bulk add | POST sent to bulkStore |
| 4 | Verify error | "Questions with Type ID: X and Complexity ID: Y do not match any rule in the selected difficulty configuration." |

---

#### TC-N18: Bulk Store — Difficulty Config Percentage Exceeded

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Quiz with difficulty config rules having max percentage limits | Rules with min/max percentages |
| 2 | Try to add more questions than allowed for a specific (question_type_id, complexity_level_id) combination | Exceeds max percentage |
| 3 | Submit bulk add | POST sent to bulkStore |
| 4 | Verify error | "Cannot add N questions... Max allowed: X, Existing: Y" |

---

#### TC-N19: Bulk Destroy — Empty question_ids

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send POST to bulkDestroy with empty question_ids array | Request sent |
| 2 | Verify validation error | "The question ids field is required." |

---

#### TC-N20: Update Ordinal — Invalid ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Call updateOrdinal with non-existent quiz_question_id (e.g., 99999) | AJAX POST sent |
| 2 | Verify validation error | exists validation rule fails |

---

#### TC-N21: Update Marks — Exceeds Total Marks

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Quiz with total_marks=10, current sum of all question marks = 9 | 1 mark remaining |
| 2 | Call updateMarks with new_marks=5 (total would be 14, exceeds 10) | AJAX POST sent |
| 3 | Verify error | "Total marks limit would be exceeded." |

---

#### TC-N22: Edit/Update/Destroy Blocked by Student Attempts

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Quiz has existing student attempt records | Attempts exist for this quiz |
| 2 | Try to edit a QuizQuestion for that quiz | Edit blocked |
| 3 | Try to update a QuizQuestion for that quiz | Update blocked |
| 4 | Try to delete a QuizQuestion for that quiz | Delete blocked |
| 5 | Verify error message for all actions | "Cannot edit/delete because students have already started attempts." |

---

#### TC-N23: View — Without View Permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user without `tenant.quiz-question.view` permission | User lacks view permission |
| 2 | Navigate to Quiz Questions index | 403 Forbidden |
| 3 | Access show route for a specific QuizQuestion | 403 Forbidden |

---

#### TC-N24: Create — Without Create Permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user without `tenant.quiz-question.create` permission | User lacks create permission |
| 2 | Navigate to Quiz Questions create page | 403 Forbidden |
| 3 | POST to store endpoint | 403 Forbidden |
| 4 | Check UI for "Create New" button | Button NOT visible in UI |

---

#### TC-N25: Update — Without Update Permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user without `tenant.quiz-question.update` permission | User lacks update permission |
| 2 | Navigate to edit page for a QuizQuestion | 403 Forbidden |
| 3 | PUT to update endpoint | 403 Forbidden |
| 4 | POST to toggleStatus | 403 Forbidden |
| 5 | POST to updateOrdinal | 403 Forbidden |
| 6 | POST to updateMarks | 403 Forbidden |
| 7 | Check UI for Edit button | NOT visible |

---

#### TC-N26: Delete — Without Delete Permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user without `tenant.quiz-question.delete` permission | User lacks delete permission |
| 2 | DELETE to destroy endpoint | 403 Forbidden |
| 3 | POST to bulkDestroy | 403 Forbidden |
| 4 | Check UI for Delete/trash button | NOT visible |

---

### 7.3 Dependency TC Steps

#### TC-D01: Cascade — Quiz Soft Delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a Quiz record and link 3 QuizQuestion records to it | 3 records with quiz_id = Q1 |
| 2 | Soft-delete the parent quiz (Quiz::find(Q1)->delete()) | Quiz soft-deleted (deleted_at set) |
| 3 | Check QuizQuestion records for quiz_id = Q1 | QuizQuestion.deleted_at set via FK CASCADE |

---

#### TC-D02: Cascade — Quiz Force Delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a Quiz record and link QuizQuestion records to it | Records exist with quiz_id = Q1 |
| 2 | Force-delete the parent quiz | Quiz permanently deleted |
| 3 | Check QuizQuestion records for quiz_id = Q1 | QuizQuestion records cascade-deleted permanently |

---

#### TC-D03: Business — Bulk Add Usage Log Creation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Bulk add questions to a quiz via bulkStore | Questions added successfully |
| 2 | Check QuestionUsageLog table for the quiz | Log entries created with type='QUIZ', context_id=quiz_id |
| 3 | Verify each added question has a corresponding log entry | One log per question |

---

#### TC-D04: Business — Bulk Remove Usage Log Cleanup

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Bulk add questions (creates QuestionUsageLog entries) | Usage logs exist |
| 2 | Bulk remove the same questions via bulkDestroy | Removal successful |
| 3 | Check QuestionUsageLog table for removed questions | Associated usage logs force-deleted (permanently removed) |

---

#### TC-D05: Business — Ordinal Recalculation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Add questions sequentially to a quiz | Ordinals: 1, 2, 3, ... (sequential, starting at 1) |
| 2 | Remove a question (e.g., the one at ordinal 2) | Record removed |
| 3 | Check ordinals of remaining questions | Recalculated: sequential, no gaps (1, 2, 3...) |

---

#### TC-D06: Business — Marks Override vs QuestionBank Marks

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Add question to quiz with marks_override=5.00 | marks_override=5.00 |
| 2 | Add same question to a different quiz without marks_override | marks_override=NULL |
| 3 | Check effective_marks for first record | Returns 5.00 |
| 4 | Check effective_marks for second record | Returns QuestionBank default marks |

---

#### TC-D07: Business — Difficulty Rules with Optional Fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create quiz with config having rules that include bloom_id, cognitive_skill_id, specificity_id | Rules with all optional attributes |
| 2 | Try to add a question matching ALL rule attributes (type + complexity + bloom + cognitive + specificity) | Question accepted |
| 3 | Try to add a question matching only type+complexity but NOT the optional attributes | Question rejected (if those attributes are required by the rule) |

---

#### TC-D08: Business — Search Filter Privacy

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Have quiz Q1 with 3 questions already linked | Existing QuizQuestion records |
| 2 | Call `/lms-quize/search` with quiz_id=Q1 | Response excludes already-linked question_ids |

---

#### TC-D09: Business — Search Default MCQ Filter

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Call search without specifying question_type_id parameter | Results filtered to MCQ_SINGLE + MCQ_MULTI types only |
| 2 | Call search explicitly specifying a non-MCQ question_type_id | Non-MCQ types included in results |

---

#### TC-D10: Cascade — Ordinal Adjacent Shift

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 7 QuizQuestion records for same quiz with ordinals 1 through 7 | Sequential ordinals: 1, 2, 3, 4, 5, 6, 7 |
| 2 | Call updateOrdinal to move the question at ordinal 3 to new ordinal=7 | AJAX POST sent |
| 3 | Check final ordinals | Moved: 7; original 4→3, 5→4, 6→5, 7→6 (adjacent questions shifted correctly) |

---

### 7.4 Code Review TC Steps

#### TC-CR01: Controller store() — Duplicate Check

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `QuizQuestionController@store()` method | Checks `where('quiz_id',..)->where('question_id',..)->exists()` before inserting new record |
| 2 | Verify duplicate check runs before any insert | If duplicate (quiz_id, question_id) exists, returns error without inserting |

---

#### TC-CR02: Controller store() — Constraint Checks

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review store() logic | Verifies only_unused_questions, only_authorised_questions, scope_topic_id, total_questions limit, and total_marks limit before insert |
| 2 | Confirm each constraint returns appropriate error message | Constraint checks block invalid additions |

---

#### TC-CR03: Controller store() — Usage Log Creation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review store() after successful insert | Creates QuestionUsageLog with type='QUIZ', question_id, and context_id = quiz_id |
| 2 | Confirm usage log is inside DB transaction | Rolled back if insert fails |

---

#### TC-CR04: Controller bulkStore() — Exact Match Validation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review bulkStore() method | Validates that total question count after adding exactly matches quiz.total_questions |
| 2 | Verify total marks after adding exactly matches quiz.total_marks | Both count and marks must match exactly; fails otherwise |

---

#### TC-CR05: Controller bulkStore() — Constraint Checks

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review bulkStore() constraint logic | Validates only_unused, only_authorised, scope_topic, MCQ-only, and difficulty distribution rules for all selected questions |

---

#### TC-CR06: Controller bulkStore() — Difficulty Distribution Validation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review bulkStore() difficulty validation | Validates each question against DifficultyDistributionDetail rules keyed by question_type_id + complexity_level_id |
| 2 | Verify percentage-based min/max limits are enforced | Blocks if adding would exceed max percentage for any rule |
| 3 | Verify ignore_difficulty_config flag bypasses this check | If true, allows violations with warning |

---

#### TC-CR07: Controller bulkStore() — Marks from Rules

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review bulkStore() marks assignment | If matching difficulty distribution rule has marks_per_question set, uses it as marks_override for that question |

---

#### TC-CR08: Controller bulkStore() — Difficulty Warning Mode

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review bulkStore() for ignore_difficulty_config=true path | Allows questions that violate difficulty rules but includes warning message in response |
| 2 | Verify warning message structure | Contains details of which rules were violated |

---

#### TC-CR09: Controller bulkStore() — Transaction Wrapper

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review bulkStore() method | All DB operations wrapped in DB::beginTransaction() / DB::commit() / DB::rollback() |
| 2 | Verify rollback happens on any failure | Partial changes not persisted if any step fails |

---

#### TC-CR10: Controller bulkDestroy() — Usage Log Cleanup

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review bulkDestroy() method | Force-deletes QuestionUsageLog records for each removed question_id |
| 2 | Verify cleanup happens before or after record deletion | Usage logs cleaned up as part of the operation |

---

#### TC-CR11: Controller bulkDestroy() — Ordinal Recalculation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review bulkDestroy() method | Calls `recalculateOrdinals()` on the quiz after successful removal |
| 2 | Verify recalculation is inside the transaction | Ordinals remain consistent |

---

#### TC-CR12: Controller updateOrdinal() — Adjacent Shifting

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review updateOrdinal() method | Decrements or increments ordinals of affected questions to maintain sequential order without gaps or duplicates |

---

#### TC-CR13: Controller updateMarks() — Total Marks Limit

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review updateMarks() method | Checks that the new total marks (current total - old marks + new marks) ≤ quiz.total_marks |
| 2 | Verify block when limit exceeded | Returns error: "Total marks limit would be exceeded." |

---

#### TC-CR14: Controller updateMarks() — Null When Matching Default

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review updateMarks() method | If the new marks_override value matches the QuestionBank's default marks for that question, stores NULL instead |
| 2 | Verify null storage avoids redundant override | DB stores marks_override = NULL |

---

#### TC-CR15: QuizQuestionRequest — withValidator Commented Out

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `QuizQuestionRequest::withValidator()` method | The after-validation callback code for count limit, marks limit, and difficulty config checks is commented out |
| 2 | Confirm these validations are NOT enforced at Request level | Only enforced in bulkStore() controller method |

---

#### TC-CR16: Controller edit/update/destroy — Usage Check

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review edit(), update(), destroy() methods | Each calls `QuizQuestionUsageCheckService.isUsed()` before allowing modification |
| 2 | Verify block when attempts exist | Returns error: "Cannot edit/delete because students have already started attempts." |

---

#### TC-CR17: Controller show() — Usage Details

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review show() method | Calls `getUsageDetails()` and `getQuizAttemptsDetails()` from QuizQuestionUsageCheckService |
| 2 | Verify results passed to view | Usage and attempt data available in the show view |

---

#### TC-CR18: Controller search() — Default MCQ Filter

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review search() method | If no question_type_id filter is specified, defaults to MCQ_SINGLE + MCQ_MULTI question type IDs |
| 2 | Confirm non-MCQ types excluded by default | Only MCQ questions returned unless explicit type filter provided |

---

#### TC-CR19: Controller search() — Quiz Context Filters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review search() method | Applies quiz-level filters: only_unused_questions, only_authorised_questions, scope_topic_id |
| 2 | Verify filters are applied when quiz context is given | Search results respect quiz configuration |

---

#### TC-CR20: Model QuizQuestion — effective_marks Accessor

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review QuizQuestion model | `effective_marks` accessor returns `$this->marks_override ?? $this->question->marks ?? 0` |
| 2 | Verify null-coalescing chain | Returns marks_override first; falls back to QuestionBank marks; then 0 |

---

#### TC-CR21: Controller — findDifficultyRuleMatch() Null Wildcard Matching

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `findDifficultyRuleMatch()` in QuizQuestionController | Iterates through DifficultyDistributionDetail rules to find first match |
| 2 | Check question_type_id matching | Rule.question_type_id must equal question.question_type_id |
| 3 | Check complexity_level_id matching | Rule.complexity_level_id must equal question.complexity_level_id |
| 4 | Check bloom_id wildcard | If rule.bloom_id is null → matches ANY bloom; if set → must match question.bloom_id |
| 5 | Check cognitive_skill_id wildcard | If rule.cognitive_skill_id is null → matches ANY; if set → must match |
| 6 | Check ques_type_specificity_id wildcard | If rule.ques_type_specificity_id is null → matches ANY; if set → must match |
| 7 | Test: question with type=1, complexity=2, bloom=3, cognitive=4 against rule with bloom=null, cognitive=null | Matches (null wildcards) |
| 8 | Test: question with type=1, complexity=2, bloom=3 against rule with bloom=5 | No match (non-null field differs) |

---

#### TC-CR22: Controller — validateDifficultyDistribution() MaxAllowed Ceil Calculation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `validateDifficultyDistribution()` in QuizQuestionController | Loads rules, groups questions, enforces percentage limits |
| 2 | Check maxAllowed formula | `$maxAllowed = ceil($calculationBase × $rule->max_percentage / 100)` |
| 3 | Verify ceil() rounds up | If base=10, max_percentage=30 → ceil(3.0) = 3; if max_percentage=35 → ceil(3.5) = 4 |
| 4 | Check minAllowed formula | `$minAllowed = floor($calculationBase × $rule->min_percentage / 100)` — calculated but not enforced |
| 5 | Check calculationBase source | Uses `$quiz->total_questions` if > 0, else current total count |
| 6 | Verify existing + new count comparison | If (existingCount + newCount) > maxAllowed → FAIL with error message |
| 7 | Verify simple mode grouping | Groups by (question_type_id + complexity_level_id) for rules without optional taxonomy fields |
| 8 | Verify complex mode grouping | Groups by matched rule ID using findDifficultyRuleMatch() for rules with taxonomy fields |

---

#### TC-CR23: Controller store() — activityLog Called After Creation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `QuizQuestionController@store()` method after successful `QuizQuestion::create(...)` | Code calls `activityLog($quizQuestion, 'Stored', [...])` with message containing "QuizQuestion created" |
| 2 | Check `activity_log` table after store() executes | Entry exists with `subject_id` = new QuizQuestion ID, `event` = 'Stored', `description` containing "QuizQuestion created" |
| 3 | Verify `performed_by` field in activity_log entry | Set to `Auth::user()->name` |

---

#### TC-CR24: Controller CRUD — activityLog on All State Transitions

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `store()` — after successful create | Calls `activityLog($quizQuestion, 'Stored', [...])` → event = 'Stored' |
| 2 | Review `update()` — after successful update | Calls `activityLog($quizQuestion, 'Updated', [...])` with changes array; event = 'Updated' |
| 3 | Review `destroy()` — after soft delete | Calls `activityLog($quizQuestion, 'Trashed', [...])` → event = 'Trashed' |
| 4 | Review `restore()` — after restore | Calls `activityLog($quizQuestion, 'Restored', [...])` → event = 'Restored' |
| 5 | Review `forceDelete()` — after permanent delete | Calls `activityLog($quizQuestion, 'Deleted', [...])` → event = 'Deleted' |
| 6 | Review `toggleStatus()` — after status toggle | Calls `activityLog($quizQuestion, 'Toggled', [...])` → event = 'Toggled' |

---

## 8. Known Issues

| # | Issue | Severity | Details |
|---|-------|----------|---------|
| KI-01 | QuizQuestionRequest withValidator checks are commented out | Medium | The after-validation hooks for count limit, marks limit, and difficulty config are ALL commented out. These validations only run in bulkStore(), not in single store(). Single store() has its own inline checks in the controller, but they differ from what was intended in the Request. |
| KI-02 | Single store/update/destroy does NOT sync quiz totals | Medium | Adding/removing single questions via store()/destroy() does NOT update quiz.total_questions or quiz.total_marks. Only bulkStore() enforces count/marks matching. |
| KI-03 | destroy() does not remove usage log | Low | Single destroy() soft-deletes QuizQuestion but does NOT clean up QuestionUsageLog. bulkDestroy() does clean up. This can leave orphaned usage log entries. |
| KI-04 | bulkStore() exact match is overly strict | Medium | Requires total questions after add to EXACTLY match quiz.total_questions. If quiz has total_questions=10 and 3 existing, user must add exactly 7. Cannot add fewer or more. Same for marks. |
| KI-05 | QuizQuestionUsageCheckService checks parent quiz attempts | Low | getUsageCount() checks if ANY attempt exists for the parent quiz, not whether the specific question was used. A question could be unused but still blocked because other questions in the same quiz have attempts. |
| KI-06 | search() defaults to MCQ only | Low | The default filter restricts to MCQ_SINGLE and MCQ_MULTI types. The commented-out `else` block on question_type_id filter shows this was intentional but rigid. |
| KI-07 | No status gate usage | Low | Policy defines `status` gate (`tenant.quiz-question.status`) but toggleStatus() uses `tenant.quiz-question.update` instead. |
| KI-08 | No Quiz status check for question CRUD | Low | There is no check preventing question modifications when quiz is PUBLISHED or ARCHIVED. The old TC assumed this restriction but the actual code does not enforce it. |

---

## 9. Route Reference

| Method | URI | Name | Controller Action | Middleware/Gate |
|--------|-----|------|-------------------|-----------------|
| GET | `/lms-quize/quiz-question` | lms-quize.quiz-question.index | index() | tenant.quiz-question.viewAny |
| GET | `/lms-quize/quiz-question/create` | lms-quize.quiz-question.create | create() | tenant.quiz-question.create |
| POST | `/lms-quize/quiz-question` | lms-quize.quiz-question.store | store() | QuizQuestionRequest → tenant.quiz-question.create |
| GET | `/lms-quize/quiz-question/{quiz_question}` | lms-quize.quiz-question.show | show() | tenant.quiz-question.view |
| GET | `/lms-quize/quiz-question/{quiz_question}/edit` | lms-quize.quiz-question.edit | edit() | tenant.quiz-question.update |
| PUT | `/lms-quize/quiz-question/{quiz_question}` | lms-quize.quiz-question.update | update() | QuizQuestionRequest → tenant.quiz-question.update |
| DELETE | `/lms-quize/quiz-question/{quiz_question}` | lms-quize.quiz-question.destroy | destroy() | tenant.quiz-question.delete |
| GET | `/lms-quize/quiz-question/trash/view` | lms-quize.quiz-question.trashed | trashed() | tenant.quiz-question.restore |
| GET | `/lms-quize/quiz-question/{id}/restore` | lms-quize.quiz-question.restore | restore() | tenant.quiz-question.restore |
| DELETE | `/lms-quize/quiz-question/{id}/force-delete` | lms-quize.quiz-question.forceDelete | forceDelete() | tenant.quiz-question.forceDelete |
| POST | `/lms-quize/quiz-question/{quiz_question}/toggle-status` | lms-quize.quiz-question.toggleStatus | toggleStatus() | tenant.quiz-question.update |
| POST | `/lms-quize/difficulty-builder/questions` | lms-quize.difficulty.builder.fetch | fetchQuestions() | — |
| POST | `/lms-quize/difficulty-builder/add` | lms-quize.difficulty.builder.add | addQuestions() | — |
| POST | `/lms-quize/difficulty-builder/quiz-meta` | lms-quize.difficulty.builder.quiz-meta | quizMeta() | — |
| GET | `/lms-quize/get-sections` | lms-quize.quiz-question.get-sections | getSections() | — |
| GET | `/lms-quize/get-subject-groups` | lms-quize.quiz-question.get-subject-groups | getSubjectGroups() | — |
| GET | `/lms-quize/get-subjects` | lms-quize.quiz-question.get-subjects | getSubjects() | — |
| GET | `/lms-quize/get-topics` | lms-quize.quiz-question.get-topics | getTopics() | — |
| GET | `/lms-quize/get-lessons` | lms-quize.quiz-question.get-lessons | getLessons() | — |
| GET | `/lms-quize/search` | lms-quize.quiz-question.search | search() | tenant.quiz-question.create |
| GET | `/lms-quize/existing` | lms-quize.quiz-question.existing | existing() | tenant.quiz-question.view |
| POST | `/lms-quize/bulk-store` | lms-quize.quiz-question.bulk-store | bulkStore() | tenant.quiz-question.create |
| POST | `/lms-quize/bulk-destroy` | lms-quize.quiz-question.bulk-destroy | bulkDestroy() | tenant.quiz-question.delete |
| POST | `/lms-quize/update-marks` | lms-quize.quiz-question.update-marks | updateMarks() | tenant.quiz-question.update |
| POST | `/lms-quize/update-ordinal` | lms-quize.quiz-question.update-ordinal | updateOrdinal() | tenant.quiz-question.update |

---

## 10. Execution Status

| Section | Total TCs | Executed | Passed | Failed | Blocked | Not Executed |
|---------|-----------|----------|--------|--------|---------|--------------|
| Positive (6.1) | 28 | 0 | 0 | 0 | 0 | 28 |
| Negative (6.2) | 26 | 0 | 0 | 0 | 0 | 26 |
| Dependency (6.3) | 10 | 0 | 0 | 0 | 0 | 10 |
| Code Review (6.4) | 22 | 0 | 0 | 0 | 0 | 22 |
| **Total** | **86** | **0** | **0** | **0** | **0** | **86** |

**Legend**: ⬜ = Pending Execution | ✅ = Passed | ❌ = Failed | ⛔ = Blocked | ◌ = Code Review (structure verified, not executed)

---

*TC List generated from actual codebase analysis — all TCs based on verified controller, model, request, policy, service, route, and blade file contents.*
