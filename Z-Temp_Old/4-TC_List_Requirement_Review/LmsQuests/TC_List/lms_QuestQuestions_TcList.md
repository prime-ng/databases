# lms_QuestQuestions_TcList

## Module: LmsQuests → Quest Management → Quest Questions

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | LmsQuests |
| Tab Group | Quest Management |
| Feature | Quest Questions |
| URL(s) | `/lms-quests/quest-question` (resource index/create/store/show/edit/update/destroy), `/lms-quests/quest-question/trash/view` (trashed), `/lms-quests/quest-question/{id}/restore` (restore), `/lms-quests/quest-question/{id}/force-delete` (forceDelete), `/lms-quests/quest-question/{quest_question}/toggle-status` (toggleStatus), `/lms-quests/search` (AJAX search), `/lms-quests/existing` (AJAX existing), `/lms-quests/bulk-store` (AJAX bulkStore), `/lms-quests/bulk-destroy` (AJAX bulkDestroy), `/lms-quests/update-ordinal` (AJAX updateOrdinal), `/lms-quests/update-marks` (AJAX updateMarks), `/lms-quests/quest-meta` (AJAX questMeta), `/lms-quests/get-sections` (AJAX), `/lms-quests/get-subject-groups` (AJAX), `/lms-quests/get-subjects` (AJAX), `/lms-quests/get-lessons` (AJAX), `/lms-quests/get-topics` (AJAX) |
| Controller | `Modules\LmsQuests\Http\Controllers\QuestQuestionController` |
| Model(s) | `QuestQuestion` (`Modules\LmsQuests\Models\QuestQuestion`) |
| Validation (Create/Update) | `QuestQuestionRequest` (`Modules\LmsQuests\Http\Requests\QuestQuestionRequest`) — uses `withValidator` for 4 rules |
| Validation (Bulk) | Inline in `bulkStore()` — 5 constraint checks |
| Permission Gates | `tenant.quest-question.viewAny`, `.view`, `.create`, `.update`, `.delete`, `.restore`, `.forceDelete`, `.status`, `.bulkAdd`, `.reorder`, `.difficultyBuilder`, `.autoGenerate` |
| Soft Deletes | Yes — `SoftDeletes` trait on QuestQuestion |
| Activity Log | Events: `Stored`, `Updated`, `Deleted`, `Restored`, `Permanently Deleted`, `Toggled`, `Questions Removed` |
| Usage Log | `qns_question_usage_log` — tracks each question added to a Quest with `question_usage_type='QUEST'` |

---

## 2. Pre-conditions

- Required permissions: `tenant.quest-question.viewAny`, `.create`, `.update`, `.delete`, `.restore`, `.forceDelete`, `.status`, `.bulkAdd`, `.reorder`
- At least one active Quest must exist (`is_active=1`) with `total_questions` and `total_marks` configured
- At least one active Question Bank question must exist (`is_active=1`, `status=PUBLISHED`)
- For difficulty tests: Difficulty Distribution Config with active rules
- For scope tests: Quest Scopes must be defined
- For usage constraint tests: Student attempts must exist via `QuizQuestAttempt`

---

## 3. Default Data Load

When create page loads (GET `/lms-quests/quest-question/create`):

| Data | Source | Query | Pagination |
|------|--------|-------|------------|
| Quests | `Quest::where('is_active', '1')->with('subject', 'class')` | Active quests | None |
| Classes | `SchoolClass::where('is_active', '1')` | Active classes | None |
| Subjects | `Subject::where('is_active', '1')` | Active subjects | None |
| Question Types | `QuestionType::where('is_active', '1')` | Active types | None |
| Complexity Levels | `ComplexityLevel::where('is_active', '1')` | Active levels | None |
| Difficulty Configs | `DifficultyDistributionConfig::where('is_active', '1')` | Active configs | None |
| Bloom Taxonomies | `BloomTaxonomy::where('is_active', '1')` | Active bloom levels | None |
| Cognitive Skills | `CognitiveSkill::where('is_active', '1')` | Active skills | None |
| Type Specificities | `QueTypeSpecifity::where('is_active', '1')` | Active specificities | None |
| Performance Categories | `PerformanceCategory::where('is_active', 1)` | Active categories | None |
| Question Tags | `QuestionTag::where('is_active', 1)` | Active tags | None |
| Recommendation Types | `Dropdown::where('key', 'qns_question_performance_category_jnt.recommendation_type')` | Dropdown values | None |

When index page loads with AJAX `existing` (GET `/lms-quests/existing?quest_id=X`):

| Data | Source | Notes |
|------|--------|-------|
| Existing Questions | `QuestQuestion::where('quest_id', X)->orderBy('ordinal')` | With question relations |
| Stats | Computed: added_questions, added_marks, required_marks, total_questions_limit | From quest config |
| Difficulty Rules | `DifficultyDistributionDetail::where('difficulty_config_id', quest->difficulty_config_id)` | If config exists and not ignored |
| Quest Scopes | `QuestScope::where('quest_id', quest->id)` | With type/lesson/topic relations |

---

## 4. Database Schema (BC-DB)

Table: `lms_quest_questions`

DDL:

```sql
CREATE TABLE IF NOT EXISTS `lms_quest_questions` (
    `id`              INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `quest_id`        INT UNSIGNED NOT NULL,
    `question_id`     INT UNSIGNED NOT NULL,
    `ordinal`         INT UNSIGNED NOT NULL DEFAULT 0,
    `marks_override`  DECIMAL(5,2) DEFAULT NULL,
    `is_active`       TINYINT(1) NOT NULL DEFAULT 1,
    `created_at`      TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`      TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`      TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_quest_ques` (`quest_id`, `question_id`),
    CONSTRAINT `fk_qst_q_quest` FOREIGN KEY (`quest_id`) REFERENCES `lms_quests` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_qst_q_question` FOREIGN KEY (`question_id`) REFERENCES `qns_questions_bank` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### BC-DB Column Reference

| BC-DB ID | Column | Type | Constraints | Default | Notes |
|----------|--------|------|-------------|---------|-------|
| BC-DB-01 | id | bigint(20) unsigned | PK, AUTO_INCREMENT | | Primary key |
| BC-DB-02 | quest_id | bigint(20) unsigned | INDEX, FK → lms_quests.id (CASCADE) | | Parent quest |
| BC-DB-03 | question_id | bigint(20) unsigned | INDEX, FK → qns_questions_bank.id (CASCADE) | | Question from bank |
| BC-DB-04 | ordinal | int(10) unsigned | | 0 | Display sequence |
| BC-DB-05 | marks_override | decimal(5,2) | NULLABLE | NULL | Override question's default marks |
| BC-DB-06 | is_active | tinyint(1) | | 1 | Boolean |
| BC-DB-07 | created_at | timestamp | | CURRENT_TIMESTAMP | |
| BC-DB-08 | updated_at | timestamp | | ON UPDATE CURRENT_TIMESTAMP | |
| BC-DB-09 | deleted_at | timestamp | NULLABLE | NULL | Soft delete |

### BC-DB Constraints

| BC-DB ID | Constraint Type | Definition | Behavior |
|----------|----------------|------------|----------|
| BC-DB-10 | UNIQUE | `(quest_id, question_id)` | Prevents duplicate questions in the same quest |
| BC-DB-11 | FK | `quest_id` → `lms_quests.id` | ON DELETE CASCADE |
| BC-DB-12 | FK | `question_id` → `qns_questions_bank.id` | ON DELETE CASCADE |

---

## 5. Validation Rules (BC-VAL)

### 5.1 FormRequest Rules — QuestQuestionRequest (Single Add/Edit)

Source: `QuestQuestionRequest.php` — `rules()` method

| BC-VAL ID | Field | Rule | Notes |
|-----------|-------|------|-------|
| BC-VAL-01 | quest_id | required, exists:lms_quests,id | Must reference existing quest |
| BC-VAL-02 | question_id | required, exists:qns_questions_bank,id | Must reference existing question |
| BC-VAL-03 | ordinal | required, integer, min:0 | Sequence position (defaults to 0 in prepareForValidation) |
| BC-VAL-04 | marks_override | nullable, numeric, min:0 | Override marks (optional) |
| BC-VAL-05 | is_active | boolean | Cast via prepareForValidation |

### 5.2 withValidator Rules (Single Add/Edit)

Source: `QuestQuestionRequest.php` — `withValidator()` method. These are custom after-validation hooks that run after the base rules above pass.

| BC-VAL ID | Rule Name | Enforcement | Error Message |
|-----------|-----------|-------------|---------------|
| BC-VAL-06 | Question Count Limit | `$addedCount >= $quest->total_questions` (excludes current on edit) | "You can add only {N} questions to this quest." |
| BC-VAL-07 | Marks Limit | `($usedMarks + $currentMarks) > $quest->total_marks` (excludes current on edit) | "Total marks limit exceeded. Max allowed: {N}. Current used: {N}" |
| BC-VAL-08 | Difficulty Match | No matching `DifficultyDistributionDetail` rule found | "This question does not match quest difficulty configuration." |
| BC-VAL-09 | Difficulty Max% | `$alreadyAdded >= $maxAllowed` where `$maxAllowed = ceil(($quest->total_questions * $rule->max_percentage) / 100)` | "Max {N} questions allowed for this difficulty level." |
| BC-VAL-10 | Duplicate Check | `QuestQuestion::where(quest_id, question_id)->exists()` (excludes current on edit) | "This question is already added to the quest." |
| BC-VAL-11 | Edit Exclusion | All count/limit checks exclude current record on edit | `where('id', '!=', $currentId)` |

### 5.3 Bulk Add Validation Rules (inline in bulkStore)

Source: `QuestQuestionController.php` — `bulkStore()` method

| BC-VAL ID | Rule Name | Enforcement | Error Message |
|-----------|-----------|-------------|---------------|
| BC-VAL-12 | Exact Count Match | `$totalResultingCount !== (int)$quest->total_questions` | "Exact match required. Questions: {N}/{N}, Marks: {N}/{N}" |
| BC-VAL-13 | Exact Marks Match | `$totalResultingMarks !== (float)$quest->total_marks` | Same as above (combined message) |
| BC-VAL-14 | Unused Only | Questions with existing `QuestionUsageLog` for 'QUEST' | "This quest requires unused questions only. The following questions have been used before: {titles}..." |
| BC-VAL-15 | Authorised Only | Questions where `for_quiz != 1` | "This quest requires authorised questions only (for_quiz=1). The following questions are not authorised: {titles}..." |
| BC-VAL-16 | No Matching Difficulty Rule | Question type+complexity not found in difficulty rules | "Questions with Type ID: {N} and Complexity ID: {N} do not match any rule in the selected difficulty configuration." |
| BC-VAL-17 | Rule Max% Exceeded | `($existingCount + $newCount) > $maxAllowed` | "Cannot add {N} questions of this type/complexity. Max allowed: {N}, Existing: {N}. Limit exceeded for complexity rule." |
| BC-VAL-18 | Scope Limit Exceeded | `($existingCount + $newCount) > $scope->target_question_count` | "Cannot add questions. Limit exceeded for Scope: {typeName} (Limit: {N}, Current: {N}, Adding: {N})." |
| BC-VAL-19 | Total Questions Limit | `$currentTotalCount > $targetTotalQuestions` | "Cannot add questions. Total questions limit ({N}) would be exceeded." |
| BC-VAL-20 | No Questions Selected | Empty `questions_data` array | "No questions selected." |

### 5.4 Controller-Level Constraint Checks (store/update)

Source: `QuestQuestionController.php` — `store()` and `update()` methods. These are additional checks outside the FormRequest.

| BC-VAL ID | Method | Check | Behavior |
|-----------|--------|-------|----------|
| BC-VAL-21 | store() | `($existingCount + 1) > $quest->total_questions` | Redirect back with error: "Cannot add question. Total questions limit ({N}) reached." |
| BC-VAL-22 | store() | `$potentialNewTotal > $quest->total_marks` | Redirect back with error: "Cannot add question. Total marks limit ({N}) would be exceeded." |
| BC-VAL-23 | update() | `$potentialNewTotal > $quest->total_marks` | Exception: "Cannot update question. Total marks limit ({N}) would be exceeded." |

### 5.5 AJAX Endpoint Validation

| BC-VAL ID | Endpoint | Validation | Behavior |
|-----------|----------|------------|----------|
| BC-VAL-24 | toggleStatus | `$request->validate(['is_active' => 'required|boolean'])` | Returns JSON 422 on failure |
| BC-VAL-25 | updateMarks | Inline constraint check | Returns JSON with success: false + message on marks limit violation |
| BC-VAL-26 | getSections | `$request->validate(['class_id' => 'required'])` | Returns empty sections array if class not found |

---

## 6. Authorization (BC-AUTH)

Source: `QuestQuestionPolicy.php`

### 6.1 Policy Gates

| BC-AUTH ID | Gate Name | Method | Model Binding | Notes |
|------------|-----------|--------|---------------|-------|
| BC-AUTH-01 | tenant.quest-question.viewAny | viewAny() | None | View list/index |
| BC-AUTH-02 | tenant.quest-question.view | view() | QuestQuestion | View single record |
| BC-AUTH-03 | tenant.quest-question.create | create() | None | Create/store |
| BC-AUTH-04 | tenant.quest-question.update | update() | QuestQuestion | Edit/update/toggleStatus/updateOrdinal/updateMarks |
| BC-AUTH-05 | tenant.quest-question.delete | delete() | QuestQuestion | Soft delete + bulkDestroy |
| BC-AUTH-06 | tenant.quest-question.restore | restore() | QuestQuestion | Restore from trash |
| BC-AUTH-07 | tenant.quest-question.forceDelete | forceDelete() | QuestQuestion | Permanently delete |
| BC-AUTH-08 | tenant.quest-question.status | status() | QuestQuestion | Toggle active status |
| BC-AUTH-09 | tenant.quest-question.bulkAdd | bulkAdd() | None | Bulk add questions |
| BC-AUTH-10 | tenant.quest-question.import | import() | None | Import questions |
| BC-AUTH-11 | tenant.quest-question.export | export() | None | Export questions |
| BC-AUTH-12 | tenant.quest-question.reorder | reorder() | QuestQuestion | Reorder questions |
| BC-AUTH-13 | tenant.quest-question.difficultyBuilder | difficultyBuilder() | None | Use difficulty builder |
| BC-AUTH-14 | tenant.quest-question.autoGenerate | autoGenerate() | None | Auto-generate questions |

### 6.2 Controller Gate Enforcement

| BC-AUTH ID | Controller Method | Gate Used | Notes |
|------------|------------------|-----------|-------|
| BC-AUTH-15 | index() | tenant.quest-question.viewAny | Then aborts(404) — no standalone index |
| BC-AUTH-16 | create() | tenant.quest-question.create | |
| BC-AUTH-17 | store() | tenant.quest-question.create | |
| BC-AUTH-18 | show() | tenant.quest-question.view | |
| BC-AUTH-19 | edit() | tenant.quest-question.update | Usage check runs BEFORE gate |
| BC-AUTH-20 | update() | tenant.quest-question.update | Usage check runs BEFORE gate |
| BC-AUTH-21 | destroy() | tenant.quest-question.delete | Usage check runs BEFORE gate |
| BC-AUTH-22 | trashed() | tenant.quest-question.restore | |
| BC-AUTH-23 | restore() | tenant.quest-question.restore | Usage check runs BEFORE gate |
| BC-AUTH-24 | forceDelete() | tenant.quest-question.forceDelete | Usage check runs BEFORE gate |
| BC-AUTH-25 | toggleStatus() | tenant.quest-question.update | |
| BC-AUTH-26 | search() | tenant.quest-question.create | |
| BC-AUTH-27 | existing() | tenant.quest-question.view | |
| BC-AUTH-28 | bulkStore() | tenant.quest-question.create | |
| BC-AUTH-29 | bulkDestroy() | tenant.quest-question.delete | |
| BC-AUTH-30 | updateOrdinal() | tenant.quest-question.update | |
| BC-AUTH-31 | updateMarks() | tenant.quest-question.update | |
| BC-AUTH-32 | questMeta() | tenant.quest-question.view | |
| BC-AUTH-33 | getSections() | tenant.quest-question.viewAny | |
| BC-AUTH-34 | getSubjectGroups() | tenant.quest-question.viewAny | |
| BC-AUTH-35 | getSubjects() | tenant.quest-question.viewAny | |
| BC-AUTH-36 | getLessons() | tenant.quest-question.viewAny | |
| BC-AUTH-37 | getTopics() | tenant.quest-question.viewAny | |

### 6.3 Known Authorization Issue

| BC-AUTH ID | Issue | Severity | Details |
|------------|-------|----------|---------|
| BC-AUTH-38 | `QuestQuestionRequest::authorize()` returns `true` unconditionally | High | FormRequest returns `true` instead of checking `Gate::allows()`. Permission enforcement relies entirely on controller-level `Gate::authorize()` calls. |

---

## 7. Business Logic (BC-BIZ)

### 7.1 Core Business Rules

| BC-BIZ ID | Rule Name | Description | Enforcement Location |
|-----------|-----------|-------------|---------------------|
| BC-BIZ-01 | Question Count Limit | A Quest's `total_questions` cannot be exceeded. Single add: `addedCount >= total_questions` blocks. Bulk add: exact match required. | withValidator (single), bulkStore (bulk) |
| BC-BIZ-02 | Marks Limit | A Quest's `total_marks` cannot be exceeded. Uses `effective_marks` (override ?: bank marks). Single add: `usedMarks + currentMarks > total_marks` blocks. Bulk add: exact match required. | withValidator (single), bulkStore (bulk) |
| BC-BIZ-03 | No Duplicate Questions | Same question cannot be added twice to the same Quest (checks include soft-deleted records). | withValidator (single), bulkStore skips silently |
| BC-BIZ-04 | Difficulty Config Matching | If Quest has `difficulty_config_id` and `ignore_difficulty_config=false`, each question must match a rule by `question_type_id` + `complexity_level_id` (plus optional bloom/cognitive/specificity). | withValidator (single), validateDifficultyDistribution (bulk) |
| BC-BIZ-05 | Difficulty Rule Max% | For each difficulty rule, count of matching questions cannot exceed `ceil(total_questions * max_percentage / 100)`. | withValidator (single), validateDifficultyDistribution (bulk) |
| BC-BIZ-06 | Scope Limits | If Quest has `QuestScope` records, adding questions must not exceed any scope's `target_question_count`. Scope matches by `question_type_id`, optional `lesson_id`, optional `topic_id`. | validateQuestScopes (bulkStore only) |
| BC-BIZ-07 | Unused Questions Constraint | If `only_unused_questions=true`, questions with existing `QuestionUsageLog` for 'QUEST' are rejected. | bulkStore |
| BC-BIZ-08 | Authorised Questions Constraint | If `only_authorised_questions=true`, only questions with `for_quiz=1` can be added. | bulkStore |
| BC-BIZ-09 | Bulk Add Exact Match | In bulk add, total count and total marks must EXACTLY match the Quest's configured values. Strict `!==` comparison. | bulkStore |
| BC-BIZ-10 | Usage Tracking | Every question added creates a `QuestionUsageLog` entry (`question_usage_type='QUEST'`). Removal cascades to usage log. | store, bulkStore, destroy, bulkDestroy, restore, forceDelete |
| BC-BIZ-11 | Modification Lock (Usage Check) | If students have attempted the Quest, editing/deleting/restoring/force-deleting the question link is blocked. | edit, update, destroy, restore, forceDelete |
| BC-BIZ-12 | Only Published Questions | Question search only returns questions with `status='PUBLISHED'` and `is_active=1`. | search() |

### 7.2 Model Accessors

| BC-BIZ ID | Accessor | Logic | Source |
|-----------|----------|-------|--------|
| BC-BIZ-13 | `effective_marks` | `$this->marks_override ?? $this->question->marks ?? 0` | QuestQuestion model |

### 7.3 Marks Computation Priority

When determining the marks for a question being added, the following priority applies:

| BC-BIZ ID | Priority Level | Source | Condition |
|-----------|---------------|--------|-----------|
| BC-BIZ-14 | 1 (Highest) | Request's `marks_override` field | If explicitly provided in the request |
| BC-BIZ-15 | 2 | Matching difficulty rule's `marks_per_question` | If request has no marks_override and a matching rule exists with marks_per_question |
| BC-BIZ-16 | 3 (Default) | Question Bank's default `marks` value | Fallback if neither override nor rule marks available |

### 7.4 Search Filter Logic

| BC-BIZ ID | Filter Step | Description | Code Reference |
|-----------|------------|-------------|----------------|
| BC-BIZ-17 | Base query | `QuestionBank::where('is_active', 1)->where('status', 'PUBLISHED')` | search() L234 |
| BC-BIZ-18 | Performance filters | recommendation_type, performance_category, priority | search() L237-254 |
| BC-BIZ-19 | Academic filters | class_id, section_id, subject_id, lesson_id, topic_id | search() L257-276 |
| BC-BIZ-20 | Tag filter | tag_ids via `questionTopics` relation | search() L278-282 |
| BC-BIZ-21 | Property filters | question_type_id, complexity_level_id, bloom_id, cognitive_skill_id, ques_type_specificity_id | search() L285-298 |
| BC-BIZ-22 | Unused filter | Excludes questions with existing 'QUEST' usage log | search() L310-322 |
| BC-BIZ-23 | Authorised filter | Filters to `for_quiz=1` | search() L324-331 |
| BC-BIZ-24 | Usage type flags | for_quiz, for_exam, for_quest | search() L334-342 |
| BC-BIZ-25 | Existing exclusion | Excludes questions already in quest (even soft-deleted) | search() L344-348 |
| BC-BIZ-26 | Text search | Searches `ques_title` and `question_content` | search() L351-357 |
| BC-BIZ-27 | Result limit | Default 50, configurable via `quantity` param | search() L359 |

### 7.5 Cascade Behavior

| BC-BIZ ID | Operation | Effect on QuestQuestion | Effect on Usage Log |
|-----------|-----------|------------------------|---------------------|
| BC-BIZ-28 | Single store() | Creates record | Creates usage log entry |
| BC-BIZ-29 | Single destroy() | Soft-deletes record | Soft-deletes usage log entry |
| BC-BIZ-30 | Single restore() | Restores record, sets is_active=true | Restores usage log entry |
| BC-BIZ-31 | Single forceDelete() | Permanently deletes record | Permanently deletes usage log entry |
| BC-BIZ-32 | Bulk store() | Creates multiple records | Creates usage log for each |
| BC-BIZ-33 | Bulk destroy() | Force-deletes multiple records | Force-deletes usage log for each |
| BC-BIZ-34 | Parent Quest forceDelete() | Cascade-deleted (FK CASCADE) | Cascade-deleted |
| BC-BIZ-35 | Parent Question Bank soft-delete | Record remains (soft-delete no cascade) | Record remains |

---

## 8. Referential Integrity (BC-REF)

### 8.1 Foreign Keys on `lms_quest_questions`

| BC-REF ID | Column | Parent Table | Parent Column | ON DELETE | ON UPDATE |
|-----------|--------|--------------|---------------|-----------|-----------|
| BC-REF-01 | quest_id | lms_quests | id | CASCADE | No action |
| BC-REF-02 | question_id | qns_questions_bank | id | CASCADE | No action |

### 8.2 Unique Constraints

| BC-REF ID | Constraint Name | Columns | Purpose |
|-----------|----------------|---------|---------|
| BC-REF-03 | uq_quest_ques | (quest_id, question_id) | Prevents duplicate questions in the same quest |

### 8.3 Related Tables (Indirect References)

| BC-REF ID | Related Table | Relationship | Usage |
|-----------|--------------|--------------|-------|
| BC-REF-04 | lms_quests | Parent quest (quest_id) | Stores quest config: total_questions, total_marks, difficulty_config_id |
| BC-REF-05 | qns_questions_bank | Question bank (question_id) | The actual question data |
| BC-REF-06 | qns_question_usage_log | Usage tracking | Tracks question usage with 'QUEST' type |
| BC-REF-07 | lms_quest_scopes | Scope limits | Validated in bulkStore |
| BC-REF-08 | lms_difficulty_distribution_details | Difficulty rules | Validated in withValidator and bulkStore |
| BC-REF-09 | sp_quiz_quest_attempts | Student attempts | Blocks modification if attempts exist |

---

## 9. Test Case Summary

### 9.1 TC Count by Category

| Category | Code | Count | Coverage Area |
|----------|------|-------|---------------|
| Positive | TC-P01 to TC-P22 | 22 | Happy path: create, bulk store, show, edit, update ordinal/marks, bulk destroy, soft delete, restore, force delete, toggle status, search, existing, quest meta, fetch questions |
| Negative | TC-N01 to TC-N26 | 26 | Validation failures: limits exceeded, duplicates, difficulty mismatch, permissions, bulk violations, usage blocks |
| Dependency | TC-D01 to TC-D08 | 8 | Cascade behaviors, usage log lifecycle, difficulty rule marks |
| Code Review | TC-CR01 to TC-CR26 | 26 | Request validation, controller logic, blade views, authorization, breadcrumbs, flash messages |
| **Total** | | **82** | |

### 9.2 TC Distribution by Feature Area

| Feature Area | P | N | D | CR | Total |
|-------------|---|---|---|---|-------|
| Single Question Add (store) | 3 | 9 | 0 | 5 | 17 |
| Bulk Add (bulkStore) | 3 | 8 | 2 | 5 | 18 |
| View/Show | 1 | 1 | 0 | 1 | 3 |
| Edit/Update | 1 | 1 | 0 | 2 | 4 |
| Update Ordinal (AJAX) | 1 | 0 | 0 | 1 | 2 |
| Update Marks (AJAX) | 1 | 1 | 0 | 1 | 3 |
| Bulk Destroy (AJAX) | 1 | 0 | 1 | 0 | 2 |
| Soft Delete (destroy) | 1 | 1 | 0 | 1 | 3 |
| Restore | 1 | 1 | 0 | 1 | 3 |
| Force Delete | 1 | 1 | 0 | 1 | 3 |
| Toggle Status (AJAX) | 1 | 0 | 0 | 1 | 2 |
| Search (AJAX) | 3 | 0 | 0 | 1 | 4 |
| Existing (AJAX) | 2 | 0 | 0 | 1 | 3 |
| Quest Meta (AJAX) | 1 | 0 | 0 | 0 | 1 |
| Fetch Questions (AJAX) | 1 | 0 | 0 | 0 | 1 |
| Permission/Authorization | 0 | 4 | 0 | 0 | 4 |
| Cascade/Integrity | 0 | 0 | 5 | 0 | 5 |
| Blade/View Layer | 0 | 0 | 0 | 4 | 4 |
| Known Issues | 0 | 0 | 0 | 2 | 2 |
| **Total** | **22** | **26** | **8** | **26** | **82** |

### 9.3 TC Execution Priority

| Priority | Count | TC IDs |
|----------|-------|--------|
| P0 (Critical) | 18 | P01-P04, N01-N03, N06-N07, N10-N12, N17, CR01-CR05 |
| P1 (High) | 28 | P05-P10, N04-N05, N08-N09, N13-N16, N18-N21, D01-D08, CR06-CR10 |
| P2 (Medium) | 24 | P11-P16, N22-N26, CR11-CR20 |
| P3 (Low) | 12 | P17-P22, CR21-CR26 |

---

## 10. Test Data Strategy

- **Unique Suffix**: Use `now()->format('His') . random_int(100, 999)` for test data uniqueness
- **Quest Needed**: Each test requires a parent Quest with `total_questions`, `total_marks`, and optionally `difficulty_config_id` and `only_unused_questions`/`only_authorised_questions` flags
- **Question Bank Data**: Ensure test questions exist with varied `question_type_id`, `complexity_level_id`, `marks`, and `for_quiz` flags
- **Bulk Add Strategy**: Tests for bulk add require a Quest where `total_questions` = exact count of questions to add and `total_marks` = exact sum of marks
- **Usage Log**: Pre-existing usage log entries may be needed for "Only Unused" tests
- **Scope Data**: For scope limit tests, create `QuestScope` records with `target_question_count`
- **Difficulty Config**: Create `DifficultyDistributionDetail` rules with `min_percentage`/`max_percentage` for difficulty validation tests
- **Attempt Data**: For usage block tests, create `QuizQuestAttempt` records referencing the Quest's allocations

---

## 11. Test Case Steps

### 11.1 Positive TC Steps

#### TC-P01: Create — Add single question within limits

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Quest Q1 with total_questions=10, total_marks=100 | Quest exists |
| 2 | Navigate to Quest Questions → Create | Create form loads |
| 3 | Select Quest Q1 | Quest selected |
| 4 | Select a Question (must be active, published) | Question selected |
| 5 | Set Ordinal = 1 | Ordinal set |
| 6 | Leave Marks Override blank (use default) | Default marks used |
| 7 | Click Submit | POST store |
| 8 | Verify redirect to Quest index with success message | Redirected |
| 9 | DB check: `lms_quest_questions` | Record created: quest_id=Q1, question_id matches, ordinal=1, marks_override=null, is_active=1 |
| 10 | DB check: `qns_question_usage_log` | Usage log created: question_bank_id matches, question_usage_type='QUEST', context_id=Q1 |

---

#### TC-P02: Create — Add single question with marks override

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Quest Q1 with total_marks=100 | Quest exists |
| 2 | Open create form, select Q1 | Quest selected |
| 3 | Select a Question with default marks=5 | Question selected |
| 4 | Set Marks Override = 8 | Override set |
| 5 | Submit | Saved |
| 6 | DB check: marks_override | 8.00 stored |
| 7 | Check `QuestQuestion::find(id)->effective_marks` | Returns 8 (override used, not 5) |

---

#### TC-P03: Create — Add single question with ordinal

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Quest Q1 has 3 existing questions (ordinals 1,2,3) | Questions exist |
| 2 | Create new question with ordinal=5 | Ordinal set |
| 3 | Submit | Saved with ordinal=5 |
| 4 | Verify no gap enforcement | Ordinal 5 accepted (no auto-sequencing) |

---

#### TC-P04: Bulk Store — Add exact batch matching quest config

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Quest Q1 with total_questions=3, total_marks=15 | Quest exists |
| 2 | Select 3 questions from bank: Qa(marks=5), Qb(marks=5), Qc(marks=5) | Questions selected |
| 3 | Send AJAX POST to bulkStore with questions_data | AJAX call |
| 4 | Verify success response | `{"success": true, "message": "3 questions added successfully."}` |
| 5 | DB check: 3 records in lms_quest_questions for Q1 | Count=3 |
| 6 | DB check: total marks = 15 | Sum of effective_marks = 15 |
| 7 | DB check: 3 usage log entries | 3 QuestionUsageLog records |

---

#### TC-P05: Bulk Store — Questions auto-assigned sequential ordinals

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Quest Q1 has 2 existing questions (max ordinal=5) | Max ordinal = 5 |
| 2 | Bulk add 3 new questions | Added |
| 3 | DB check ordinals | 6, 7, 8 (max + 1, +2, +3) |

---

#### TC-P06: Bulk Store — Marks from difficulty rule (marks_per_question)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Quest Q1 with difficulty_config_id=D1, ignore_difficulty_config=false | Quest linked to config |
| 2 | D1 has rule: QType=MCQ, Complexity=Medium, marks_per_question=4 | Rule exists |
| 3 | Bulk add an MCQ Medium question (bank default marks=5) | Question added |
| 4 | DB check marks_override | 4.00 (rule's marks_per_question, not bank's 5) |

---

#### TC-P07: Show — View quest question details

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create QuestQuestion QQ1 with quest and question relations | QQ1 exists |
| 2 | Navigate to show page: GET `/lms-quests/quest-question/{QQ1}` | Show page loads |
| 3 | Verify quest info displayed | Quest title, code shown |
| 4 | Verify question info displayed | Question title, type, complexity shown |
| 5 | If no student attempts exist | Usage section hidden/empty |

---

#### TC-P08: Edit — Update marks_override

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create QQ1 with marks_override=5, quest total_marks=100, existing total=50 | QQ1 exists |
| 2 | Navigate to edit page | Edit form loads |
| 3 | Change marks_override to 8 | Marks updated |
| 4 | Submit | Updated |
| 5 | DB check: marks_override | 8.00 |
| 6 | Verify total marks recalculated correctly | Total=53 (50-5+8) |

---

#### TC-P09: Update Ordinal (AJAX)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create QQ1 with ordinal=1 | QQ1 exists |
| 2 | Send AJAX POST to updateOrdinal: quest_question_id=QQ1, ordinal=10 | AJAX call |
| 3 | Verify response | `{"success": true, "message": "Sequence order updated successfully."}` |
| 4 | DB check: ordinal | 10 |

---

#### TC-P10: Update Marks (AJAX)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create QQ1 with marks_override=5, quest total_marks=100, current total=50 | QQ1 exists |
| 2 | Send AJAX POST to updateMarks: quest_question_id=QQ1, marks_override=8 | AJAX call |
| 3 | Verify response | `{"success": true, "marks": 8, "original_marks": original}` |
| 4 | DB check: marks_override | 8.00 |

---

#### TC-P11: Bulk Destroy — Remove multiple questions (AJAX)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Quest Q1 has 5 questions, with usage log entries | Questions exist |
| 2 | Send AJAX POST to bulkDestroy: quest_id=Q1, question_ids=[Qa_id, Qb_id] | AJAX call |
| 3 | Verify response | `{"success": true, "message": "Questions removed successfully."}` |
| 4 | DB check: questions force-deleted | lms_quest_questions records for Qa, Qb have deleted_at NOT NULL |
| 5 | DB check: usage logs force-deleted | QuestionUsageLog entries for Qa, Qb in quest Q1 removed |
| 6 | DB check: remaining questions | 3 questions still exist |

---

#### TC-P12: Destroy — Soft delete single question

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create QQ1 with usage log entry | QQ1 exists |
| 2 | Click delete icon on QQ1 | DELETE request |
| 3 | Verify redirect with success | Redirected |
| 4 | DB check: QQ1.deleted_at | NOT NULL (soft-deleted) |
| 5 | DB check: usage log deleted | QuestionUsageLog entry for QQ1 soft-deleted |

---

#### TC-P13: Restore — Restore soft-deleted question

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete QQ1 (both question link and usage log) | QQ1 in trash |
| 2 | Navigate to Trash page | Trash shows QQ1 |
| 3 | Click Restore | GET restore |
| 4 | Verify redirect with success | Redirected |
| 5 | DB check: QQ1.deleted_at | NULL (restored) |
| 6 | DB check: QQ1.is_active | true |
| 7 | DB check: usage log restored | QuestionUsageLog restored |

---

#### TC-P14: Force Delete — Permanently delete question (no attempts)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete QQ1 with no student attempts | QQ1 in trash |
| 2 | Navigate to Trash page | Trash shows QQ1 |
| 3 | Click Force Delete | DELETE forceDelete |
| 4 | Verify redirect with success | Redirected |
| 5 | DB check: QQ1 withTrashed | Record gone (force-deleted) |
| 6 | DB check: usage log | QuestionUsageLog force-deleted |

---

#### TC-P15: Toggle Status — Deactivate question (AJAX)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create QQ1 with is_active=1 | QQ1 active |
| 2 | Send AJAX POST to toggleStatus: is_active=0 | AJAX call |
| 3 | Verify response | `{"success": true, "is_active": false}` |
| 4 | DB check: is_active | 0 |
| 5 | Send AJAX POST to toggleStatus: is_active=1 | AJAX call |
| 6 | DB check: is_active | 1 |

---

#### TC-P16: Search — Filter questions by class (AJAX)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Quest Q1 (class_id=C1) | Quest exists |
| 2 | Have question Qa in class C1, Qb in class C2 | Questions exist |
| 3 | Send AJAX GET to search: quest_id=Q1, class_id=C1 | AJAX call |
| 4 | Verify response | Qa included, Qb excluded |
| 5 | Check questions count | Only class C1 questions returned |

---

#### TC-P17: Search — Filter by only_unused (AJAX)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Have question Qa with no usage log, Qb with existing QUEST usage log | Qa unused, Qb used |
| 2 | Send AJAX GET to search: only_unused=true | AJAX call |
| 3 | Verify Qa included, Qb excluded | Unused filter works |

---

#### TC-P18: Search — Filter by only_authorised (AJAX)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Have question Qa with for_quiz=1, Qb with for_quiz=0 | Qa authorised, Qb not |
| 2 | Send AJAX GET to search: only_authorised=true | AJAX call |
| 3 | Verify Qa included, Qb excluded | Authorised filter works |

---

#### TC-P19: Existing — Load existing questions with stats (AJAX)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Quest Q1 has 3 questions added (total marks=15, total_questions=5) | Questions exist |
| 2 | Send AJAX GET to existing: quest_id=Q1 | AJAX call |
| 3 | Verify response contains questions array | 3 questions returned |
| 4 | Verify stats: added_questions=3, added_marks=15, required_marks=quest.total_marks, total_questions_limit=5 | Stats correct |
| 5 | If quest has difficulty config | difficulty_rules array populated |
| 6 | If quest has scopes | quest_scopes array populated |

---

#### TC-P20: Existing — No difficulty config returns empty rules

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Quest Q1 has ignore_difficulty_config=true OR no difficulty_config_id | Difficulty ignored |
| 2 | AJAX GET existing: quest_id=Q1 | Call |
| 3 | Verify response.difficulty_rules | Empty array |
| 4 | Verify stats.ignore_difficulty | true |

---

#### TC-P21: Quest Meta — Load quest metadata (AJAX)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Quest Q1 with difficulty_config_id=D1, ignore_difficulty_config=false | Quest configured |
| 2 | Send AJAX GET to questMeta: quest_id=Q1 | AJAX call |
| 3 | Verify response | quest_id, difficulty_config_id, ignore_difficulty, total_questions, total_marks, complexities array |

---

#### TC-P22: Fetch Questions — Legacy endpoint with complexity filter

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Quest Q1 with total_questions=10 | Quest exists |
| 2 | Send AJAX GET to fetchQuestions: quest_id=Q1, min_percentage=20, max_percentage=30, complexity_level_ids=[1] | AJAX call |
| 3 | Verify response | min, max, available count, already_added count |

---

### 11.2 Negative TC Steps

#### TC-N01: Create — Exceed total_questions limit

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Quest Q1 with total_questions=3, add 3 questions | Quest at limit |
| 2 | Try to add 4th question | Validation error: "You can add only 3 questions to this quest." |
| 3 | DB check | No 4th record created |

---

#### TC-N02: Create — Exceed total_marks limit

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Quest Q1 with total_marks=50, existing questions sum to 45 | 5 marks remaining |
| 2 | Try to add question with marks_override=10 | Validation error: "Total marks limit exceeded. Max allowed: 50. Current used: 45" |
| 3 | DB check | No new record created |

---

#### TC-N03: Create — Duplicate question in same quest

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Quest Q1 already has question Qa added | Qa in Q1 |
| 2 | Try to add Qa again to Q1 | Validation error: "This question is already added to the quest." |
| 3 | DB check | No duplicate record |

---

#### TC-N04: Create — Question doesn't match difficulty config

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Quest Q1 with difficulty_config_id=D1, ignore_difficulty_config=false | Difficulty enforced |
| 2 | D1 has rules only for Type=MCQ, Complexity=Medium | Rule exists |
| 3 | Try to add question with Type=ESSAY, Complexity=Hard | Validation error: "This question does not match quest difficulty configuration." |
| 4 | DB check | No record created |

---

#### TC-N05: Create — Exceed difficulty rule max percentage

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Quest Q1 with total_questions=10, difficulty_config_id=D1 | Quest with config |
| 2 | D1 rule: Type=MCQ, Complexity=Easy, max_percentage=20% (max 2 questions) | Rule exists |
| 3 | Add 2 Easy MCQ questions (at limit) | 2 added |
| 4 | Try to add 3rd Easy MCQ question | Validation error: "Max 2 questions allowed for this difficulty level." |

---

#### TC-N06: Create — Invalid quest_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form loads |
| 2 | Select non-existent quest_id (e.g., 99999) | Invalid ID |
| 3 | Submit | Validation error: quest_id does not exist |
| 4 | DB check | No record created |

---

#### TC-N07: Create — Invalid question_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form loads |
| 2 | Select valid quest, but invalid question_id (e.g., 99999) | Invalid ID |
| 3 | Submit | Validation error: question_id does not exist |
| 4 | DB check | No record created |

---

#### TC-N08: Create — Negative ordinal

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form loads |
| 2 | Set ordinal = -1 | Negative value |
| 3 | Submit | Validation error: ordinal min:0 |
| 4 | DB check | No record created |

---

#### TC-N09: Create — Negative marks_override

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form loads |
| 2 | Set marks_override = -5 | Negative marks |
| 3 | Submit | Validation error: marks_override min:0 |
| 4 | DB check | No record created |

---

#### TC-N10: Bulk Store — Count mismatch (less than total_questions)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Quest Q1 with total_questions=5, total_marks=25 | Quest configured |
| 2 | Select only 3 questions (marks sum=15) | 3 questions selected |
| 3 | Send AJAX POST to bulkStore | AJAX call |
| 4 | Verify rejection | `{"success": false, "message": "Exact match required. Questions: 3/5, Marks: 15/25"}` |
| 5 | DB check: no questions added | 0 records in lms_quest_questions for Q1 |

---

#### TC-N11: Bulk Store — Count mismatch (more than total_questions)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Quest Q1 with total_questions=3, total_marks=15 | Quest configured |
| 2 | Bulk add 3 questions (at limit) | 3 added |
| 3 | Try to bulk add 2 more questions | Rejected: count would be 5/3 |

---

#### TC-N12: Bulk Store — Marks mismatch

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Quest Q1 with total_questions=2, total_marks=10 | Quest configured |
| 2 | Select 2 questions: Qa(marks=5), Qb(marks=6) (sum=11 ≠ 10) | Marks off |
| 3 | Send AJAX POST to bulkStore | Rejected: "Exact match required. Questions: 2/2, Marks: 11/10" |

---

#### TC-N13: Bulk Store — "Only Unused" violation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Quest Q1 with only_unused_questions=true | Unused flag on |
| 2 | Question Qb has existing QuestionUsageLog for 'QUEST' | Qb previously used |
| 3 | Try to bulk add Qb with other questions | Rejected: "This quest requires unused questions only" |
| 4 | DB check: no questions added | Transaction rolled back |

---

#### TC-N14: Bulk Store — "Only Authorised" violation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Quest Q1 with only_authorised_questions=true | Authorised flag on |
| 2 | Question Qb has for_quiz=0 | Qb not authorised |
| 3 | Try to bulk add Qb with other questions | Rejected: "This quest requires authorised questions only (for_quiz=1)" |
| 4 | DB check: no questions added | Transaction rolled back |

---

#### TC-N15: Bulk Store — No matching difficulty rule

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Quest Q1 with difficulty_config_id=D1, ignore_difficulty_config=false | Difficulty enforced |
| 2 | D1 has rules only for Type=MCQ, Complexity=Medium | Limited rules |
| 3 | Try to bulk add an ESSAY/Hard question | Rejected: "do not match any rule in the selected difficulty configuration" |

---

#### TC-N16: Bulk Store — Exceed scope limit

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Quest Q1 with Scope: target_question_count=3 for Type=MCQ, Lesson=L1 | Scope exists |
| 2 | Q1 already has 2 MCQ questions from L1 | Existing = 2 |
| 3 | Try to bulk add 2 more MCQ questions from L1 | Rejected: "Limit exceeded for Scope: MCQ (Limit: 3, Current: 2, Adding: 2)" |

---

#### TC-N17: Bulk Store — No questions selected

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send AJAX POST to bulkStore with empty questions_data | Empty selection |
| 2 | Verify rejection | `{"success": false, "message": "No questions selected."}` |

---

#### TC-N18: Edit — student attempts exist (blocked)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create QQ1, create student attempt for QQ1's quest allocation | Attempt exists |
| 2 | Navigate to edit page for QQ1 | Edit loads |
| 3 | Try to update | Redirect back with error: "Cannot update this quest question because students have already started attempts." |
| 4 | DB check | Record unchanged |

---

#### TC-N19: Destroy — student attempts exist (blocked)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create QQ1 with student attempt | Attempt exists |
| 2 | Click delete on QQ1 | POST destroy |
| 3 | Verify blocked | Redirect with error |
| 4 | DB check: deleted_at | NULL (not deleted) |

---

#### TC-N20: Force Delete — student attempts exist (blocked)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete QQ1 that has student attempts | QQ1 in trash |
| 2 | Click Force Delete | Blocked: "Cannot permanently delete this quest question because students have already started attempts." |

---

#### TC-N21: Restore — student attempts exist (blocked)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete QQ1 that has student attempts | QQ1 in trash |
| 2 | Click Restore | Blocked: "Cannot restore this quest question because students have already started attempts." |

---

#### TC-N22: View — without permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user WITHOUT `tenant.quest-question.viewAny` permission | Authenticated |
| 2 | Navigate to Quest Questions index | 403 Forbidden |

---

#### TC-N23: Create — without permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user WITHOUT `tenant.quest-question.create` permission | Authenticated |
| 2 | Navigate to create page | 403 Forbidden |

---

#### TC-N24: Edit — without permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user WITHOUT `tenant.quest-question.update` permission | Authenticated |
| 2 | Navigate to edit page directly | 403 Forbidden |
| 3 | Send POST to toggleStatus | 403 Forbidden |

---

#### TC-N25: Delete — without permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user WITHOUT `tenant.quest-question.delete` permission | Authenticated |
| 2 | Send DELETE request directly | 403 Forbidden |

---

#### TC-N26: Update Marks (AJAX) — Exceed total_marks

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Quest Q1 total_marks=100, current total=95, QQ1 has marks_override=5 | 5 marks remaining |
| 2 | Send AJAX POST to updateMarks: marks_override=10 | Would make total=100 |
| 3 | Verify rejection | `{"success": false, "message": "Cannot update marks. Total marks limit (100) would be exceeded. Potential total: 105"}` |

---

### 11.3 Dependency TC Steps

#### TC-D01: Cascade — Question Bank question deleted

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create QQ1 linking Quest Q1 and Question Qa | QQ1 exists |
| 2 | Soft-delete Question Qa from Question Bank | Qa deleted |
| 3 | Check QQ1 in DB | QQ1 still exists (FK CASCADE on delete but soft-delete doesn't cascade) |
| 4 | Verify QQ1 still accessible | Show page loads, question data may show as missing |

---

#### TC-D02: Cascade — Quest deleted

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create QQ1 linking Quest Q1 and Question Qa | QQ1 exists |
| 2 | Soft-delete Quest Q1 | Q1 deleted |
| 3 | Check QQ1 in DB | QQ1 still exists |
| 4 | Delete Quest Q1 permanently (forceDelete) | QQ1 cascade-deleted (FK CASCADE) |

---

#### TC-D03: Business — Usage Log Created on Add

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Add QQ1 via single store | Question added |
| 2 | DB check: qns_question_usage_log | Entry exists: question_bank_id=QQ1.question_id, question_usage_type='QUEST', context_id=QQ1.quest_id |

---

#### TC-D04: Business — Usage Log Removed on Delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Add QQ1, verify usage log exists | Usage log present |
| 2 | Soft-delete QQ1 (destroy) | QQ1 deleted |
| 3 | DB check: usage log deleted_at | QuestionUsageLog entry for QQ1 has deleted_at NOT NULL |

---

#### TC-D05: Business — Usage Log Restored on Restore

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete QQ1 (destroy) | Both QQ1 and usage log soft-deleted |
| 2 | Restore QQ1 | QQ1 restored |
| 3 | DB check: usage log | Usage log restored (deleted_at=NULL) |

---

#### TC-D06: Business — Usage Log Force-Deleted on Force Delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete QQ1, then forceDelete | QQ1 force-deleted |
| 2 | DB check: usage log withTrashed | QuestionUsageLog entry force-deleted (gone permanently) |

---

#### TC-D07: Business — Bulk Destroy also removes usage logs

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Add Qa and Qb to Quest Q1, verify usage logs exist | 2 usage logs |
| 2 | Send bulkDestroy: question_ids=[Qa_id, Qb_id] | Bulk remove |
| 3 | DB check: usage logs for Qa, Qb | Both force-deleted from QuestionUsageLog |

---

#### TC-D08: Business — Difficulty Rule Marks Auto-Applied in Bulk

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Quest Q1 with difficulty_config_id=D1, D1 has rule marks_per_question=4 | Rule with marks |
| 2 | Bulk add MCQ Medium question Qa (bank marks=5) | Qa added |
| 3 | DB check: marks_override on Qa | 4.00 (rule applied, not bank's 5) |
| 4 | If request explicitly provides marks_override | Request's value used (priority over rule) |

---

### 11.4 Code Review TC Steps

#### TC-CR01: Request — Question Count Limit (withValidator)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `QuestQuestionRequest::withValidator()` | Custom after-validation hook |
| 2 | Check count check: `$addedCount >= $quest->total_questions` | Blocks if at or over limit |
| 3 | Verify edit exclusion: `->when($currentId, fn($q) => $q->where('id', '!=', $currentId))` | On edit, excludes current record from count |
| 4 | Verify early return after error | `return;` after adding error — stops further checks |

---

#### TC-CR02: Request — Marks Limit (withValidator)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review marks calculation in `withValidator()` | Sums effective_marks of all quest questions (excluding current) |
| 2 | Verify calculation: `$currentMarks = $this->marks_override ?? $question->marks ?? 0` | Uses override if set, else bank marks |
| 3 | Verify check: `($usedMarks + $currentMarks) > $quest->total_marks` | Blocks if exceeds |
| 4 | Verify `calculateEffectiveMarks()` helper | Uses marks_override if set, else question->marks |

---

#### TC-CR03: Request — Difficulty Match (withValidator)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review difficulty check in `withValidator()` | Only runs if `!$quest->ignore_difficulty_config && $quest->difficulty_config_id` |
| 2 | Verify rule lookup: `DifficultyDistributionDetail::where([difficulty_config_id, question_type_id, complexity_level_id, is_active])` | Matches by type + complexity |
| 3 | Verify no-rule error: `if (!$rule)` | Error: "This question does not match quest difficulty configuration." |
| 4 | Verify max% check: `$alreadyAdded >= $maxAllowed` where `$maxAllowed = ceil(($quest->total_questions * $rule->max_percentage) / 100)` | Blocks if at/over max allowed |

---

#### TC-CR04: Request — Duplicate Check (withValidator)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review duplicate check in `withValidator()` | `QuestQuestion::where(quest_id, question_id)->exists()` |
| 2 | Verify edit exclusion | On edit, excludes current record |
| 3 | Verify error message | "This question is already added to the quest." |

---

#### TC-CR05: Controller store() — Transaction + Usage Log

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `QuestQuestionController::store()` | Wrapped in DB::transaction |
| 2 | Verify usage log creation after question save | `QuestionUsageLog::create([...'question_usage_type'=>'QUEST', 'context_id'=>$questQuestion->quest_id])` |
| 3 | Verify activity log | `activityLog($questQuestion, 'Stored', ...)` |
| 4 | Verify catch block | `DB::rollBack()`, redirect with error |

---

#### TC-CR06: Controller bulkStore() — Exact Match Requirement

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `bulkStore()` | Inline validation before DB writes |
| 2 | Verify count check: `$totalResultingCount !== (int)$quest->total_questions` | Uses strict `!==` — exact match required |
| 3 | Verify marks check: `$totalResultingMarks !== (float)$quest->total_marks` | Uses strict `!==` — exact match required |
| 4 | Verify `$perQuestionMarks = $quest->total_marks / $quest->total_questions` | Divides total_marks by total_questions for per-question value |
| 5 | Verify both checks happen BEFORE question validation | Early return on mismatch |

---

#### TC-CR07: Controller bulkStore() — Only Unused + Only Authorised

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review unused check: `if ($quest->only_unused_questions)` | Queries `QuestionUsageLog` for existing entries |
| 2 | Verify unused error message | Lists first 3 used question titles |
| 3 | Review authorised check: `if ($quest->only_authorised_questions)` | Filters questions where `!$q->for_quiz` |
| 4 | Verify authorised error message | Lists first 3 unauthorised question titles |
| 5 | Verify both checks return 422 JSON | No DB writes on failure |

---

#### TC-CR08: Controller bulkStore() — Difficulty Distribution Validation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `validateDifficultyDistribution()` | Called for each bulk add |
| 2 | Verify total questions limit check | `currentTotalCount > targetTotalQuestions` |
| 3 | Verify no-matching-rule check: `if (!$matchingRule)` | Error: "do not match any rule" |
| 4 | Verify max% check: `($existingCount + $newCount) > $maxAllowed` | Blocks if exceeds per-rule max |
| 5 | Verify advanced matching (optional bloom/cognitive/specificity) | `$hasOptional` triggers detailed rule matching via `findDifficultyRuleMatch()` |

---

#### TC-CR09: Controller bulkStore() — Scope Validation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `validateQuestScopes()` | Checks each scope's target_question_count |
| 2 | Verify empty scopes skips validation | `if ($scopes->isEmpty()) return ['success' => true]` |
| 3 | Verify count check: `($existingCount + $newCount) > $scope->target_question_count` | Blocks if exceeds |
| 4 | Verify scope matching: question_type_id match, optional lesson_id and topic_id match | Multiple matching criteria |
| 5 | Verify error message includes scope limit details | "Limit exceeded for Scope: {type} (Limit: X, Current: Y, Adding: Z)" |

---

#### TC-CR10: Controller bulkStore() — Transaction and Marks Resolution

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review transaction wrapper in bulkStore | `DB::beginTransaction()` before loop, `DB::commit()` after, `DB::rollBack()` on exception |
| 2 | Verify duplicate skip: `if (!$exists)` | Skips questions already in quest (no error, just skip) |
| 3 | Verify marks priority: request marks_override → rule marks_per_question → question default marks | Three-tier resolution |
| 4 | Verify usage log created for each question | `QuestionUsageLog::create` in loop |

---

#### TC-CR11: Controller update() — Marks Recalculation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `update()` method | Checks usage before allowing edit |
| 2 | Verify marks recalculation: `$potentialNewTotal = $currentTotalMarks - $oldEffectiveMarks + $potentialNewMarks` | Subtracts old, adds new |
| 3 | Verify check: `$potentialNewTotal > $quest->total_marks` | Blocks if exceeds |
| 4 | Verify usage check runs before Gate | Usage check first, then `Gate::authorize` |

---

#### TC-CR12: Controller destroy() — Usage Log Cleanup

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `destroy()` method | Deletes usage log, then soft-deletes question link |
| 2 | Verify usage log deletion: `QuestionUsageLog::where(...)->whereIn('question_usage_type', ['QUEST', 'Quest'])->delete()` | Catches both 'QUEST' and 'Quest' variations |
| 3 | Verify `$questQuestion->delete()` after usage log | Soft-delete question link |
| 4 | Verify usage check before destroy | Blocks if student attempts exist |

---

#### TC-CR13: Controller restore() — Cascading Restore

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `restore()` method | Restores question link, sets is_active, restores usage log |
| 2 | Verify `$questQuestion->restore()` + `$questQuestion->is_active = true; $questQuestion->save()` | Restores and activates |
| 3 | Verify usage log restore: `QuestionUsageLog::withTrashed()->where(...)->restore()` | Restores associated usage log |
| 4 | Verify usage check prevents restore if attempts exist | "Cannot restore this quest question because students have already started attempts." |

---

#### TC-CR14: Controller forceDelete() — Cascade Cleanup

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `forceDelete()` | Force-deletes usage log, activity log, then force-deletes question |
| 2 | Verify usage log force-delete: `->forceDelete()` | Permanently removes usage log |
| 3 | Verify `$questQuestion->forceDelete()` after cleanup | Permanently removes question link |
| 4 | Verify usage check prevents if attempts exist | Guarded |

---

#### TC-CR15: Controller toggleStatus() — AJAX Status Switch

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `toggleStatus()` | AJAX endpoint, validates `is_active` boolean |
| 2 | Verify inline validation: `$request->validate(['is_active' => 'required|boolean'])` | Validates input |
| 3 | Verify success JSON response | `{'success': true, 'is_active': bool, 'message': ...}` |
| 4 | Verify error JSON on failure | `{'success': false, 'message': ...}` with 500 status |

---

#### TC-CR16: Controller updateOrdinal() — Sequence Update

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `updateOrdinal()` | Simple update — no constraint checks |
| 2 | Verify `QuestQuestion::findOrFail($request->quest_question_id)` | Finds by quest_question_id (not question_id) |
| 3 | Verify `$questQuestion->ordinal = $request->ordinal; $questQuestion->save()` | Direct save |

---

#### TC-CR17: Controller updateMarks() — Marks Update with Constraint

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `updateMarks()` | Recalculates total marks with old→new diff |
| 2 | Verify calculation: `$potentialNewTotal = $currentTotalMarks - $oldMarks + $newMarks` | Correct diff calculation |
| 3 | Verify constraint: `if ($quest->total_marks > 0 && $potentialNewTotal > $quest->total_marks)` | Blocks if exceeds |
| 4 | Verify success response includes marks and original_marks | `{'marks': X, 'original_marks': Y}` |

---

#### TC-CR18: Controller search() — Question Filter Chain

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `search()` method | Complex filter chain for Question Bank |
| 2 | Verify base query: `QuestionBank::where('is_active', 1)->where('status', 'PUBLISHED')` | Only active, published questions |
| 3 | Verify academic filters: class_id, section_id, subject_id, lesson_id, topic_id | Cascade filters |
| 4 | Verify property filters: question_type_id, complexity_level_id, bloom_id, cognitive_skill_id, specificity_id | Property filter chain |
| 5 | Verify usage filters: only_unused, only_authorised, for_quiz/quest/exam | Usage toggles |
| 6 | Verify existing question exclusion: `whereNotIn('id', $existingIds)` | Already-added questions hidden |

---

#### TC-CR19: Controller search() — Difficulty Rule Marks in Response

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review response transformation in `search()` | Maps each question with `marks` |
| 2 | Verify marks resolution: if matching difficulty rule has `marks_per_question`, use that | Rule marks override question defaults in response display |
| 3 | Verify rule matching logic: question_type_id + complexity_level_id + optional bloom/cognitive/specificity | Same logic as bulkStore |

---

#### TC-CR20: Controller existing() — Stats Computation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `existing()` method | Returns existing questions, stats, difficulty rules, scopes |
| 2 | Verify stats: added_questions = count, added_marks = sum of marks | Correct computation |
| 3 | Verify difficulty rules fetched: `DifficultyDistributionDetail::where('difficulty_config_id', ...)` | Only if config exists and not ignored |
| 4 | Verify scopes fetched with current count per scope | Scope counts include existing questions only |

---

#### TC-CR21: Controller store() — Scope Limits NOT Checked (Known Gap)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Quest Q1 with scopes where Lesson scope target_question_count=5 | Scope requires max 5 questions from that Lesson |
| 2 | Add a single question from that Lesson via store() when scope already at 5 | store() succeeds (no scope check in single add) |
| 3 | DB check: question added despite scope limit already exceeded | Scope limit exceeded (known gap: only bulkStore() validates scopes) |

---

#### TC-CR22: Controller saveAnswerGrade() — Permission Namespace Inconsistency

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `saveAnswerGrade()` in LmsQuestController | Uses `Gate::authorize('tenant.quest-question.update')` |
| 2 | User with `tenant.quest.update` but WITHOUT `tenant.quest-question.update` | 403 Forbidden (inconsistent — should use `tenant.quest.update`) |
| 3 | User with `tenant.quest-question.update` | Succeeds (cross-namespace permission works but incorrect) |

---

#### TC-CR23: Blade — @can Directives in Views

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `resources/views/quest-question/index.blade.php` | `@can('tenant.quest-question.status')` wraps Active column (L42-L44) |
| 2 | Review `index.blade.php` action column | `@canany(['tenant.quest-question.view', 'tenant.quest-question.update', 'tenant.quest-question.delete'])` wraps Actions (L45-L47) |
| 3 | Review `index.blade.php` status switch | `x-backend.table.status-switch` with `permission="tenant.quest-question.update"` (L89-L93) |
| 4 | Review `index.blade.php` action component | `x-backend.table.action` with `permissions="tenant.quest-question"` (L98-L100) |
| 5 | Review `show.blade.php` edit button | `@can('tenant.quest-question.update')` wraps Edit button (L24-L31) |
| 6 | Review `trash.blade.php` action column | `@canany(['tenant.quest-question.restore', 'tenant.quest-question.forceDelete'])` wraps Action (L25-L30) |
| 7 | Review `trash.blade.php` action-trashed | `x-backend.table.action-trashed` with `permissions="tenant.quest-question"` (L55-L59) |
| 8 | Review `tab_module/tab.blade.php` tab permissions | `@can('tenant.quest-question.viewAny')` wraps quest-question tab include (L40-L42) |
| 9 | Verify all @can/@canany directives match policy gates | Gates map correctly to controller enforcement |
| 10 | Verify no action button rendered without required permission | Unauthorized users see no actionable UI elements |

---

#### TC-CR24: Blade — Breadcrumb Component

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `resources/views/quest-question/show.blade.php` | `<x-backend.components.breadcrum title="Quest Question Details" :links="[]" />` (L4-L7) |
| 2 | Review `resources/views/quest-question/create.blade.php` | `<x-backend.components.breadcrum title="Add Questions to Quest" :links="[]" />` (L2-L5) |
| 3 | Review `resources/views/quest-question/edit.blade.php` | `<x-backend.components.breadcrum title="Edit Quest Question" :links="[]" />` (L4-L7) |
| 4 | Review `resources/views/quest-question/trash.blade.php` | `<x-backend.components.breadcrum title="Trashed Quest Questions" :links="[]" />` (L4-L7) |
| 5 | Review `tab_module/tab.blade.php` | `<x-backend.components.breadcrum title="Quest Management" :links="[]" />` (L3-L6) |
| 6 | Verify breadcrumb `links` array is empty for all quest-question views | No breadcrumb trail beyond page title (no `['label' => ..., 'url' => ...]` entries) |
| 7 | Verify title correctly reflects the current view context | Each view has appropriate title string |
| 8 | Verify breadcrumb renders without errors when view is loaded | Page loads with breadcrumb displayed at top |

---

#### TC-CR25: Blade — View isset / Null Coalescing Checks

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `show.blade.php` quest title display | `{{ $questQuestion->quest->title ?? '-' }}` (L46) |
| 2 | Review `show.blade.php` quest code display | `{{ $questQuestion->quest->quest_code ?? '-' }}` (L51) |
| 3 | Review `show.blade.php` question title display | `{{ $questQuestion->question->ques_title ?? '-' }}` (L56) |
| 4 | Review `show.blade.php` question type display | `{{ $questQuestion->question->questionType->name ?? '-' }}` (L61) |
| 5 | Review `show.blade.php` default marks display | `{{ $questQuestion->question->marks ?? '0.00' }}` (L80) |
| 6 | Review `show.blade.php` marks override display | `{{ $questQuestion->marks_override ?? 'Not Set' }}` (L85) |
| 7 | Review `show.blade.php` effective marks display | `{{ $questQuestion->effective_marks ?? '0.00' }}` (L90) |
| 8 | Review `show.blade.php` created_at display | `{{ $questQuestion->created_at?->format('...') }}` (L106) |
| 9 | Review `show.blade.php` updated_at display | `{{ $questQuestion->updated_at?->format('...') }}` (L111) |
| 10 | Review `show.blade.php` usage details section | `@if($isUsed && $usageDetails && !empty($usageDetails['details']))` guards usage card (L126) |
| 11 | Review `show.blade.php` usage detail fields | `$detail['quest_title'] ?? '-'`, `$detail['allocation_type'] ?? '-'` (L151-L153) |
| 12 | Review `show.blade.php` attempt display | `$attempt->student?->full_name ?? 'Unknown'`, `$attempt->score_obtained ?? '-'` (L186, L202) |
| 13 | Review `index.blade.php` question title display | `{{ $question->question->ques_title ?? 'N/A' }}` (L84) |
| 14 | Review `index.blade.php` marks display | `{{ $question->marks_override ?? $question->question->marks ?? 'N/A' }}` (L86) |
| 15 | Review `trash.blade.php` quest title display | `{{ $question->quest->title ?? '-' }}` (L38) |
| 16 | Review `trash.blade.php` question title display | `{{ $question->question->ques_title ?? '-' }}` (L40) |
| 17 | Review `trash.blade.php` marks display | `{{ $question->marks_override ?? $question->question->marks ?? '-' }}` (L44) |
| 18 | Verify all nullable relationship chains use `??` fallback | No undefined property errors on missing relations |
| 19 | Verify nullable date fields use `?->` optional chaining | No null `format()` call errors |
| 20 | Verify conditional sections (`@if`, `@isset`) guard potentially missing data | Usage details section hidden when no data |

---

#### TC-CR26: Flash Messages — Session Flash Responses

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `store()` success redirect | `->with('success', flash('created.quest-question'))` (L1022) |
| 2 | Review `store()` error catch | `->with('error', flash('error.quest-question', 'Failed to add quest question. Please try again.'))` (L1028) |
| 3 | Review `update()` success redirect | `->with('success', flash('updated.quest-question'))` (L1128) |
| 4 | Review `update()` error catch | `->with('error', flash('error.quest-question', 'Failed to update quest question. Please try again.'))` (L1134) |
| 5 | Review `destroy()` success redirect | `->with('success', flash('deleted.quest-question'))` (L1170) |
| 6 | Review `destroy()` error catch | `->with('error', flash('error.quest-question', 'Failed to delete quest question.'))` (L1174) |
| 7 | Review `restore()` success redirect | `->with('success', flash('restored.quest-question'))` (L1227) |
| 8 | Review `restore()` error catch | `->with('error', flash('error.quest-question', 'Failed to restore quest question. Please try again.'))` (L1232) |
| 9 | Review `forceDelete()` success redirect | `->with('success', flash('force_deleted.quest-question'))` (L1270) |
| 10 | Review `forceDelete()` error catch | `->with('error', flash('error.quest-question', 'Failed to permanently delete quest question. Please try again.'))` (L1275) |
| 11 | Review `toggleStatus()` success JSON | `'message' => flash('status_updated.quest-question')` (L1306) |
| 12 | Review `toggleStatus()` save-fail JSON | `'message' => flash('status_switch_failed.quest-question')` (L1313) |
| 13 | Review `toggleStatus()` exception JSON | `'message' => flash('error.quest-question', 'Failed to update status.')` (L1320) |
| 14 | Review `edit()` usage block redirect | `->with('error', flash('error.quest-question', 'Cannot edit this quest question because students have already started attempts.'))` (L1069) |
| 15 | Review `update()` usage block redirect | `->with('error', flash('error.quest-question', 'Cannot update this quest question because students have already started attempts.'))` (L1086) |
| 16 | Review `destroy()` usage block redirect | `->with('error', flash('error.quest-question', 'Cannot delete this quest question because students have already started attempts.'))` (L1145) |
| 17 | Review `restore()` usage block redirect | `->with('error', flash('error.quest-question', 'Cannot restore this quest question because students have already started attempts.'))` (L1199) |
| 18 | Review `forceDelete()` usage block redirect | `->with('error', flash('error.quest-question', 'Cannot permanently delete this quest question because students have already started attempts.'))` (L1243) |
| 19 | Verify all flash messages use consistent `flash()` helper pattern | Keys: `created.*`, `updated.*`, `deleted.*`, `restored.*`, `force_deleted.*`, `status_updated.*`, `status_switch_failed.*`, `error.*` |
| 20 | Verify flash `success` messages shown on successful CRUD operations | User sees confirmation on each action |

---

## 12. Route Reference

| Method | URL | Name | Controller Method | Required Permission |
|--------|-----|------|-------------------|---------------------|
| GET | `/lms-quests/quest-question` | lms-quests.quest-question.index | index() | tenant.quest-question.viewAny |
| GET | `/lms-quests/quest-question/create` | lms-quests.quest-question.create | create() | tenant.quest-question.create |
| POST | `/lms-quests/quest-question` | lms-quests.quest-question.store | store() | tenant.quest-question.create |
| GET | `/lms-quests/quest-question/{quest_question}` | lms-quests.quest-question.show | show() | tenant.quest-question.view |
| GET | `/lms-quests/quest-question/{quest_question}/edit` | lms-quests.quest-question.edit | edit() | tenant.quest-question.update |
| PUT | `/lms-quests/quest-question/{quest_question}` | lms-quests.quest-question.update | update() | tenant.quest-question.update |
| DELETE | `/lms-quests/quest-question/{quest_question}` | lms-quests.quest-question.destroy | destroy() | tenant.quest-question.delete |
| GET | `/lms-quests/quest-question/trash/view` | lms-quests.quest-question.trashed | trashed() | tenant.quest-question.restore |
| GET | `/lms-quests/quest-question/{id}/restore` | lms-quests.quest-question.restore | restore() | tenant.quest-question.restore |
| DELETE | `/lms-quests/quest-question/{id}/force-delete` | lms-quests.quest-question.forceDelete | forceDelete() | tenant.quest-question.forceDelete |
| POST | `/lms-quests/quest-question/{quest_question}/toggle-status` | lms-quests.quest-question.toggleStatus | toggleStatus() | tenant.quest-question.update |
| GET | `/lms-quests/search` | search | search() | tenant.quest-question.create |
| GET | `/lms-quests/existing` | existing | existing() | tenant.quest-question.view |
| POST | `/lms-quests/bulk-store` | bulk-store | bulkStore() | tenant.quest-question.create |
| POST | `/lms-quests/bulk-destroy` | bulk-destroy | bulkDestroy() | tenant.quest-question.delete |
| POST | `/lms-quests/update-ordinal` | update-ordinal | updateOrdinal() | tenant.quest-question.update |
| POST | `/lms-quests/update-marks` | update-marks | updateMarks() | tenant.quest-question.update |
| GET | `/lms-quests/quest-meta` | quest-meta | questMeta() | tenant.quest-question.view |
| GET | `/lms-quests/get-sections` | get-sections | getSections() | tenant.quest-question.viewAny |
| GET | `/lms-quests/get-subject-groups` | get-subject-groups | getSubjectGroups() | tenant.quest-question.viewAny |
| GET | `/lms-quests/get-subjects` | get-subjects | getSubjects() | tenant.quest-question.viewAny |
| GET | `/lms-quests/get-lessons` | get-lessons | getLessons() | tenant.quest-question.viewAny |
| GET | `/lms-quests/get-topics` | get-topics | getTopics() | tenant.quest-question.viewAny |

---

## 13. Known Issues

| # | Issue | Severity | Details |
|---|-------|----------|---------|
| KI-01 | `FormRequest::authorize()` returns `true` unconditionally | **High** | `QuestQuestionRequest::authorize()` returns `true` instead of checking `Gate::allows()`. Permission is enforced in the Controller via `Gate::authorize()`, but this bypasses the defence-in-depth pattern used by other modules. |
| KI-02 | `bulkStore()` requires EXACT match on count and marks | Medium | The bulk add uses strict `!==` comparison (`$totalResultingCount !== (int)$quest->total_questions`). This means if the quest config says 10 questions and 100 marks, the teacher MUST add EXACTLY 10 questions summing to EXACTLY 100 marks. There's no way to add fewer than max. This differs from the single-add behavior which only checks `<=`. |
| KI-03 | No difficulty check for `ignore_difficulty_config` edge case in bulk | Low | In `validateDifficultyDistribution()`, if `!$quest->ignore_difficulty_config` is false, the function returns early. But the function is only called when `if ($quest->difficulty_config_id && !$quest->ignore_difficulty_config)` already, so this is redundant. |
| KI-04 | `getSections()` returns sections without checking `is_active` on junction | Low | `$class->classSections()->with('section')->get()` doesn't filter `class_section.is_active` before returning. |
| KI-05 | No `index()` page — always aborts 404 | Low | The `index()` method calls `abort(404)`. Quest Questions are only accessed via the Quest's tab interface, never standalone. |
| KI-06 | `usageLog()` cleanup uses `whereIn('question_usage_type', ['QUEST', 'Quest'])` | Low | The destroy method checks for both 'QUEST' and 'Quest' to handle case inconsistencies. Usage logs are always created with 'QUEST' (uppercase). This inconsistency should be normalized. |
| KI-07 | `toggleStatus()` saves `is_active` from request directly without boolean cast | Low | `$questQuestion->is_active = $request->is_active` — relies on model casting to boolean, but the request value may be a string '0'/'1'. |
| KI-08 | Single `store()` does not validate scope limits | Medium | Only `bulkStore()` calls `validateQuestScopes()`. Single question add bypasses scope target_question_count checks entirely. |
| KI-09 | `saveAnswerGrade()` uses wrong permission namespace | Medium | Uses `tenant.quest-question.update` in `LmsQuestController` instead of `tenant.quest.update`. Teacher needs wrong permission to grade. |
