# lms_QuestScopes_TcList

## Module: LmsQuests → Quest Management → Quest Scopes

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | LmsQuests |
| Tab Group | Quest Management |
| Feature | Quest Scopes |
| URL(s) | `/lms-quests/quest-scope` (resource index/create/store/show/edit/update/destroy), `/lms-quests/quest-scope/trash/view` (trashed), `/lms-quests/quest-scope/{id}/restore` (restore), `/lms-quests/quest-scope/{id}/force-delete` (forceDelete), `/lms-quests/quest-scope/{quest_scope}/toggle-status` (toggleStatus), `/lms-quests/quest-details/{id}` (AJAX getQuestDetails), `/lms-quests/lessons-by-quest` (AJAX getLessonsByQuest), `/lms-quests/topic-hierarchy` (AJAX getTopicHierarchy) |
| Controller | `Modules\LmsQuests\Http\Controllers\QuestScopeController` |
| Model(s) | `QuestScope` (`Modules\LmsQuests\Models\QuestScope`) — table `lms_quest_scopes` |
| Validation (Create/Update) | `QuestScopeRequest` (`Modules\LmsQuests\Http\Requests\QuestScopeRequest`) — uses `withValidator` for duplicate check + max 20 limit |
| Permission Gates | `tenant.quest-scope.viewAny`, `.view`, `.create`, `.update`, `.delete`, `.restore`, `.forceDelete`, `.status`, `.bulkAdd`, `.import`, `.export` |
| Soft Deletes | Yes — `SoftDeletes` trait on QuestScope; grouped by `quest_id` in trash |
| Activity Log | Events: `Stored`, `Updated`, `Trashed`, `Restored`, `Permanently Deleted`, `Toggled` |
| Usage Guard | `QuestScopeUsageCheckService` — checks `QuestAllocation` + `QuizQuestAttempt` records by `quest_id` |

---

## 2. Pre-conditions

- Required permissions: `tenant.quest-scope.viewAny`, `.create`, `.update`, `.delete`, `.restore`, `.forceDelete`, `.status`
- At least one active Quest must exist (`is_active=1`) with `total_questions` configured
- At least one active Lesson must exist for the Quest's class+subject combination
- For topic hierarchy tests: Topic Level Types (L1–L4) and parent-child topic relationships must exist
- For usage guard tests: Quest Allocations and/or QuizQuestAttempt records must exist referencing the Quest
- For duplicate tests: Existing scope records in `lms_quest_scopes` for the target Quest

---

## 3. Default Data Load

When create page loads (GET `/lms-quests/quest-scope/create`):

| Data | Source | Query | Pagination |
|------|--------|-------|------------|
| Topics | `Topic::where('is_active', '1')` | Active topics | None |
| Question Types | `QuestionType::all()` | All types (no active filter) | None |
| Quests | `Quest::where('is_active', '1')` | Active quests | None |
| Lessons | `Lesson::where('is_active', '1')->orderBy('name')` | Active lessons ordered by name | None |
| Topic Level Types | `TopicLevelType::where('is_active', true)` | Active level types (L1–L4) | None |

When AJAX `getQuestDetails` fires (GET `/lms-quests/quest-details/{id}`):

| Data | Source | Notes |
|------|--------|-------|
| Quest total_questions, total_marks | `Quest::findOrFail($id)` | Limits from quest config |
| Lessons filtered by quest class+subject | `Lesson::where('class_id', X)->where('subject_id', Y)->where('is_active', 1)` | Only lessons matching quest context |

When AJAX `getLessonsByQuest` fires (GET `/lms-quests/lessons-by-quest?quest_id=X`):

| Data | Source | Notes |
|------|--------|-------|
| Lessons by quest subject | `Lesson::where('subject_id', quest->subject_id)->where('is_active', 1)` | Subject-scoped lessons |

When AJAX `getTopicHierarchy` fires (GET `/lms-quests/topic-hierarchy?lesson_id=X&level=Y&parent_id=Z`):

| Data | Source | Notes |
|------|--------|-------|
| Topics by lesson + level + parent | `Topic::where('lesson_id', X)->where('is_active', 1)->where('parent_id', Z)->whereHas('topicLevelType', fn => level=Y)` | 4-level cascading hierarchy |

When edit page loads (GET `/lms-quests/quest-scope/{id}/edit`):

| Data | Source | Notes |
|------|--------|-------|
| All scopes for quest | `QuestScope::where('quest_id', id)->with('quest','lesson','topic','questionType')` | Full scope set |
| Question Types | `QuestionType::where('is_active', 1)` | Active types only |
| Lessons | `Lesson::where('class_id', X)->where('subject_id', Y)->where('is_active', 1)` | Quest-matched lessons |
| Topic Level Types | `TopicLevelType::where('is_active', true)` | Active level types |
| Scopes JSON | Mapped with parent chain per scope | Includes full topic ancestor trail (L1→L4) |

---

## 4. Database Schema (BC-DB)

### 4.1 DDL — `lms_quest_scopes`

```sql
CREATE TABLE IF NOT EXISTS `lms_quest_scopes` (
    `id`                     INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `quest_id`               INT UNSIGNED NOT NULL,              -- FK → lms_quests.id
    `lesson_id`              INT UNSIGNED NOT NULL,              -- FK → slb_lessons.id
    `topic_id`               INT UNSIGNED NOT NULL,              -- FK → slb_topics.id
    `question_type_id`       INT UNSIGNED DEFAULT NULL,          -- FK → qns_question_types.id
    `target_question_count`  INT UNSIGNED DEFAULT 0,
    `is_active`              TINYINT(1) NOT NULL DEFAULT 1,
    `created_at`             TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`             TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`             TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    CONSTRAINT `fk_qs_quest`  FOREIGN KEY (`quest_id`)  REFERENCES `lms_quests`  (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_qs_topic`  FOREIGN KEY (`topic_id`)  REFERENCES `slb_topics`  (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_qs_lesson` FOREIGN KEY (`lesson_id`) REFERENCES `slb_lessons` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### 4.2 BC-DB Mapping

| BC-DB ID | Column | Type | Constraints | Default | Notes |
|----------|--------|------|-------------|---------|-------|
| BC-DB-01 | id | INT UNSIGNED | PK, AUTO_INCREMENT | | Primary key |
| BC-DB-02 | quest_id | INT UNSIGNED | NOT NULL, INDEX, FK → lms_quests.id (CASCADE) | | Parent quest |
| BC-DB-03 | lesson_id | INT UNSIGNED | NOT NULL, INDEX, FK → slb_lessons.id (CASCADE) | | Mandatory per scope row |
| BC-DB-04 | topic_id | INT UNSIGNED | NOT NULL in DDL, FK → slb_topics.id (CASCADE) | | **DDL discrepancy:** `NOT NULL` in DDL but `nullable` in code (code is authoritative) |
| BC-DB-05 | question_type_id | INT UNSIGNED | NULLABLE, FK → qns_question_types.id | NULL | Optional filter |
| BC-DB-06 | target_question_count | INT UNSIGNED | DEFAULT 0 | 0 | 0 = no limit |
| BC-DB-07 | is_active | TINYINT(1) | NOT NULL, DEFAULT 1 | 1 | Boolean |
| BC-DB-08 | created_at | TIMESTAMP | NULL, DEFAULT CURRENT_TIMESTAMP | CURRENT_TIMESTAMP | |
| BC-DB-09 | updated_at | TIMESTAMP | NULL, ON UPDATE CURRENT_TIMESTAMP | CURRENT_TIMESTAMP | |
| BC-DB-10 | deleted_at | TIMESTAMP | NULLABLE | NULL | Soft delete |

**Note:** Unique constraint `(quest_id, lesson_id, topic_id)` is enforced at application level (no DB unique index). DDL discrepancy: `topic_id` is `INT UNSIGNED NOT NULL` in DDL but `nullable` in code (code behaviour is authoritative).

---

## 5. Validation Rules (BC-VAL)

### 5.1 Base Validation Rules — QuestScopeRequest::rules()

| BC-VAL ID | Field | Rule | Notes |
|-----------|-------|------|-------|
| BC-VAL-01 | quest_id | required, exists:lms_quests,id | Must reference existing quest |
| BC-VAL-02 | scopes | required, array, min:1 | At least one scope row |
| BC-VAL-03 | scopes.*.lesson_id | required, exists:slb_lessons,id | Lesson is mandatory per scope row |
| BC-VAL-04 | scopes.*.topic_id | nullable, exists:slb_topics,id | Topic is optional |
| BC-VAL-05 | scopes.*.question_type_id | nullable, exists:slb_question_types,id | Question type is optional |
| BC-VAL-06 | scopes.*.target_question_count | nullable, integer, min:0 | Defaults to 0 via prepareForValidation |
| BC-VAL-07 | scopes.*.is_active | boolean | |

### 5.2 Custom Error Messages

| BC-VAL ID | Scenario | Error Message |
|-----------|----------|--------------|
| BC-VAL-08 | No quest selected | "Please select a quest." |
| BC-VAL-09 | No scope rows | "Please add at least one scope." |
| BC-VAL-10 | Missing lesson | "Please select a lesson." |
| BC-VAL-11 | Invalid lesson | "Selected lesson is invalid." |
| BC-VAL-12 | Invalid topic | "Selected topic is invalid." |
| BC-VAL-13 | Invalid target count (non-integer) | "Target must be a number." |
| BC-VAL-14 | Invalid target count (negative) | "Target cannot be negative." |

### 5.3 prepareForValidation

| BC-VAL ID | Field | Default Logic | Behavior |
|-----------|-------|---------------|----------|
| BC-VAL-15 | target_question_count | `$scope['target_question_count'] ?? 0` | Sets to 0 if not provided |
| BC-VAL-16 | is_active | `isset($scope['is_active']) ? 1 : 0` | Checkbox unchecked → 0 |

### 5.4 withValidator Rules — Duplicate Check & Max 20

| BC-VAL ID | Rule | Enforcement | Behavior |
|-----------|------|-------------|----------|
| BC-VAL-17 | Duplicate Check (DB) | `QuestScope::where('quest_id', X)->where('lesson_id', L)` + `where('topic_id', T) or whereNull('topic_id')` → `exists()` | Error per row: "This scope already exists for selected lesson and topic (or without topic)." |
| BC-VAL-18 | Max 20 Limit | `(existingCount + newCount) > 20` | Error on quest_id: "Maximum 20 scopes allowed per quest." |

### 5.5 Controller-Level Validation (store method)

| BC-VAL ID | Rule | Enforcement | Behavior |
|-----------|------|-------------|----------|
| BC-VAL-19 | Duplicate Check (same request) | In-memory `$seenScopes` tracking `"{questId}-{lessonId}-{topicId}"` | Throws Exception: "Duplicate scope detected in your request for Lesson ID: {N} and Topic ID: {N}" |
| BC-VAL-20 | No valid rows | After loop, `$created === 0` | Rollback + error: "No valid scope rows found. Please select at least Lesson." |
| BC-VAL-21 | updateOrCreate withTrashed | `QuestScope::withTrashed()->updateOrCreate([quest_id, lesson_id, topic_id], [...])` | Restores soft-deleted matching records by setting `deleted_at = null` |

### 5.6 Controller-Level Validation (update method)

| BC-VAL ID | Rule | Enforcement | Behavior |
|-----------|------|-------------|----------|
| BC-VAL-22 | Conflict check on update | `QuestScope::where(quest_id, lesson_id, topic_id)->where('id', '!=', $row['id'])->exists()` | Error: "Conflict: Another scope already exists for Lesson ID: {N} and Topic ID: {N}" |
| BC-VAL-23 | Full replacement — force-delete removed | `array_diff(existingIds, submittedIds)` → `forceDelete()` | IDs not in submission are permanently removed |
| BC-VAL-24 | Auto-update Quest total_questions | `$quest->total_questions != $totalQuestions` → `$quest->update(['total_questions' => $totalQuestions])` | Quest question limit synced to scope sum |

---

## 6. Authorization (BC-AUTH)

### 6.1 Policy Gates — QuestScopePolicy

| BC-AUTH ID | Gate Method | Permission String | Model Binding | Applied In |
|------------|-------------|-------------------|---------------|------------|
| BC-AUTH-01 | viewAny | tenant.quest-scope.viewAny | none | index(), trashed() |
| BC-AUTH-02 | view | tenant.quest-scope.view | QuestScope | show(), getQuestDetails(), getLessonsByQuest(), getTopicHierarchy() |
| BC-AUTH-03 | create | tenant.quest-scope.create | none | create(), store() |
| BC-AUTH-04 | update | tenant.quest-scope.update | QuestScope | edit(), update(), toggleStatus() |
| BC-AUTH-05 | delete | tenant.quest-scope.delete | QuestScope | destroy() |
| BC-AUTH-06 | restore | tenant.quest-scope.restore | QuestScope | restore() |
| BC-AUTH-07 | forceDelete | tenant.quest-scope.forceDelete | QuestScope | forceDelete() |
| BC-AUTH-08 | status | tenant.quest-scope.status | QuestScope | (used in Blade @can) |
| BC-AUTH-09 | bulkAdd | tenant.quest-scope.bulkAdd | none | (reserved) |
| BC-AUTH-10 | import | tenant.quest-scope.import | none | (reserved) |
| BC-AUTH-11 | export | tenant.quest-scope.export | none | (reserved) |

### 6.2 Gate Enforcement Pattern

| BC-AUTH ID | Endpoint | Pattern | Notes |
|------------|----------|---------|-------|
| BC-AUTH-12 | store() | `Gate::authorize('tenant.quest-scope.create')` | Called before validation |
| BC-AUTH-13 | update() | `Gate::authorize('tenant.quest-scope.update')` | Called before usage check |
| BC-AUTH-14 | destroy() | Usage check FIRST → `Gate::authorize('tenant.quest-scope.delete')` AFTER | Usage guard has priority |
| BC-AUTH-15 | restore() | Usage check FIRST → `Gate::authorize('tenant.quest-scope.restore')` AFTER | Usage guard has priority |
| BC-AUTH-16 | forceDelete() | Usage check FIRST → `Gate::authorize('tenant.quest-scope.forceDelete')` AFTER | Usage guard has priority |
| BC-AUTH-17 | toggleStatus() | `Gate::authorize('tenant.quest-scope.update')` | Uses update gate |
| BC-AUTH-18 | trashed() | `Gate::authorize('tenant.quest-scope.restore')` | Uses restore gate (not viewAny) |
| BC-AUTH-19 | Blade @can (index) | `@can('tenant.quest-scope.status')` on Active column | Conditional column rendering |
| BC-AUTH-20 | Blade @canany (index) | `@canany(['.view', '.update', '.delete'])` on Actions column | Conditional action buttons |
| BC-AUTH-21 | Blade @can (show) | `@can('tenant.quest-scope.update')` on Edit button | Wrapped with `!$isUsed` condition |
| BC-AUTH-22 | Blade @canany (trash) | `@canany(['.restore', '.forceDelete'])` on Action column | Conditional trash actions |

---

## 7. Business Logic (BC-BIZ)

| BC-BIZ ID | Rule | Description | Enforcement | Type | Priority | Coverage |
|-----------|------|-------------|-------------|------|----------|----------|
| BC-BIZ-01 | Lesson Mandatory, Topic Optional | Scope row must have a lesson; topic_id is optional (nullable) | QuestScopeRequest: `lesson_id` required, `topic_id` nullable | Validation | P0 | store(), update(), QuestScopeRequest |
| BC-BIZ-02 | No Duplicate lesson+topic per Quest | No two scope rows can have same `quest_id + lesson_id + topic_id`; null topic_id matches null | In-memory `$seenScopes` in store() + withValidator DB query check | Validation | P1 | store(), QuestScopeRequest |
| BC-BIZ-03 | Target Count 0 = Unlimited | `target_question_count = 0` means unlimited questions from that scope scope | Stored as 0; enforced during question selection (not in scope form) | Calculation | P1 | store(), update() |
| BC-BIZ-04 | Max 20 Scopes per Quest | Hard limit of 20 scope rows per Quest | withValidator: `(existingCount + newCount) > 20` → error on quest_id | Validation | P2 | QuestScopeRequest |
| BC-BIZ-05 | Usage Lock — Modification Guard | Scopes cannot be modified once Quest has allocations or student attempts | `QuestScopeUsageCheckService::isUsed()` blocks edit/update/destroy/restore/forceDelete | Workflow | P1 | edit(), update(), destroy(), restore(), forceDelete() |
| BC-BIZ-06 | Toggle Affects ALL Scopes for Quest | Toggling status on one scope applies to ALL scopes of the same quest | `toggleStatus()` queries by `quest_id` and updates all matching records | Workflow | P2 | toggleStatus() |
| BC-BIZ-07 | Exact Sum Match (Frontend) | Sum of `target_question_count` must equal Quest's `total_questions` | Frontend JS: submit button disabled until sum === limit | Frontend | P2 | create(), edit() views |
| BC-BIZ-08 | Full Replacement on Update | Edit form represents the complete scope set; IDs not in submission are force-deleted | `array_diff(existingIds, submittedIds)` → `forceDelete()` | Logic | P1 | update() |
| BC-BIZ-09 | Auto-Sync Quest total_questions | Quest's `total_questions` auto-updated when scope sum changes | `if ($quest->total_questions != $totalQuestions) → $quest->update(...)` | Sync | P1 | update() |
| BC-BIZ-10 | updateOrCreate Restores Trashed | Creating with same quest+lesson+topic restores soft-deleted record instead of creating new | `QuestScope::withTrashed()->updateOrCreate([...], ['deleted_at' => null])` | Logic | P1 | store() |
| BC-BIZ-11 | All-or-Nothing DB Transaction | All multi-row scope operations wrapped in DB transactions | `DB::beginTransaction/commit/rollBack` in store(), update(), destroy(), restore(), forceDelete() | Logic | P1 | store(), update(), destroy(), restore(), forceDelete() |
| BC-BIZ-12 | Batch Restore — All Scopes for Quest | Restoring restores ALL soft-deleted scopes for a Quest (grouped by quest_id in trash) | `QuestScope::onlyTrashed()->where('quest_id', $id)->get()` → loop restore | Workflow | P1 | restore() |
| BC-BIZ-13 | Batch Force-Delete — All Scopes for Quest | Force-delete removes ALL trashed scopes for a Quest at once | `QuestScope::withTrashed()->where('quest_id', $id)->get()` → loop forceDelete | Workflow | P1 | forceDelete() |
| BC-BIZ-14 | Soft Delete Deactivates Before Delete | Before soft-deleting, `is_active` is set to false | `$scope->update(['is_active' => false])` then `$scope->delete()` | Workflow | P1 | destroy() |
| BC-BIZ-15 | Activity Logging | All state-changing operations log audit trail | `activityLog($scope, 'Stored'/'Trashed'/'Restored'/'Deleted'/'Toggled', [...])` | Audit | P1 | store(), destroy(), restore(), forceDelete(), toggleStatus() |

---

## 8. Referential Integrity (BC-REF)

| BC-REF ID | Column | Parent Table | Parent Column | ON DELETE | ON UPDATE | Notes |
|-----------|--------|-------------|---------------|-----------|-----------|-------|
| BC-REF-01 | quest_id | lms_quests | id | CASCADE | — | Parent quest; if quest is force-deleted, scopes cascade |
| BC-REF-02 | lesson_id | slb_lessons | id | CASCADE | — | Mandatory per scope row |
| BC-REF-03 | topic_id | slb_topics | id | CASCADE | — | DDL: NOT NULL; Code: nullable (code authoritative) |
| BC-REF-04 | question_type_id | qns_question_types | id | SET NULL | — | No explicit FK constraint in DDL (nullable, no constraint defined) |

**Cascade Behaviour:**
- **Quest force-deleted (`ON DELETE CASCADE`):** All scopes for that quest are permanently removed
- **Quest soft-deleted:** Scopes remain intact (soft-delete does not cascade)
- **Lesson deleted:** All scopes referencing that lesson are cascade-deleted
- **Topic deleted:** All scopes referencing that topic are cascade-deleted
- **Question type deleted:** `question_type_id` set to NULL (if FK existed; currently NO explicit FK constraint in DDL)

---

## 9. Test Data Strategy

- **Unique Suffix**: Use `now()->format('His') . random_int(100, 999)` for test data uniqueness
- **Quest Needed**: Each test requires a parent Quest with configured `total_questions` and `total_marks`
- **Scope Data**: Create `QuestScope` records with `target_question_count` for limit/duplicate tests
- **Lesson/Topic Data**: Ensure lessons exist for the Quest's class+subject; create parent-child topic hierarchy up to 4 levels
- **Topic Level Types**: Ensure `TopicLevelType` records exist with levels 1–4 for hierarchy cascade tests
- **Usage Guard Data**: Create `QuestAllocation` and/or `QuizQuestAttempt` records referencing the Quest for modification-lock tests
- **Soft Delete Data**: Create scopes and soft-delete them for trash/restore/forceDelete tests
- **Sum Exact Match**: Create quests with specific `total_questions` values; sum of scope `target_question_count` must exactly match

---

## 10. Test Case Steps

### 10.1 Positive TC Steps

#### TC-P01: Create — Add single scope row with lesson only (topic optional)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Quest Q1 with total_questions=10, total_marks=100 | Quest exists |
| 2 | Navigate to Quest Scopes → Create | Create form loads |
| 3 | Select Quest Q1, trigger AJAX getQuestDetails | Returns total_questions=10, total_marks=100, lessons[] |
| 4 | Click "Add Scope Row" | New row appears with Lesson dropdown, 4-level topic dropdowns (disabled), Question Type dropdown, Target Qty input, Active checkbox |
| 5 | Select Lesson L1 from dropdown | Lesson L1 selected |
| 6 | Leave Topic Hierarchy blank (topic optional) | No topic_id will be stored |
| 7 | Leave Question Type as "Any Type" (null) | No question_type filter |
| 8 | Set Target Question Count = 10 | Footer shows 10/10 |
| 9 | Click "Create Scopes" | POST store with scopes array |
| 10 | Verify redirect to Quest Scope list tab | Redirected with success message "1 quest scope(s) added successfully!" |
| 11 | DB check: `lms_quest_scopes` | Record created: quest_id=Q1, lesson_id=L1, topic_id=NULL, question_type_id=NULL, target_question_count=10, is_active=1, deleted_at=NULL |

---

#### TC-P02: Create — Add scope row with lesson + specific topic

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Quest Q1 with total_questions=5 | Quest exists |
| 2 | Open create form, select Q1 | Quest selected |
| 3 | Add scope row: Lesson L1, Topic T1 (leaf-level), Question Type = MCQ, Target = 5 | Row configured |
| 4 | Footer shows 5/5 | Sum matches |
| 5 | Submit | Saved |
| 6 | DB check: topic_id, question_type_id | Stored with T1 and MCQ type ID |

---

#### TC-P03: Create — Multiple scope rows summing exactly to Quest total_questions

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Quest Q1 with total_questions=20 | Quest exists |
| 2 | Add 3 scope rows: Row1 (L1, T1, 10), Row2 (L1, T2, 5), Row3 (L2, no topic, 5) | 3 rows |
| 3 | Footer shows 20/20 | Exact match |
| 4 | Submit | 3 scopes created |
| 5 | DB check: count = 3, sum(target_question_count) = 20 | All rows saved |

---

#### TC-P04: Create — 20 scope rows (max limit)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Quest Q1 with total_questions=100 | Quest exists |
| 2 | Add 20 scope rows, each with different lesson+topic combos, target=5 each | 20 rows |
| 3 | Footer shows 100/100 | Exact match |
| 4 | Submit | Success: "20 quest scope(s) added successfully!" |
| 5 | DB check: count = 20 | Max limit reached |

---

#### TC-P05: Create — Target count 0 (unlimited)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Quest Q1 with total_questions=0 (unlimited) | Quest exists |
| 2 | Add scope row: Lesson L1, Target = 0 | Target 0 meaning no limit |
| 3 | Submit | Scope created with target_question_count=0 |
| 4 | DB check: target_question_count | 0 stored |
| 5 | Verify BR-QST-009 (BC-BIZ-03): 0 means no limit | Enforced in question selection (not in scopes) |

---

#### TC-P06: Create — `updateOrCreate` restores previously soft-deleted scope

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Quest Q1 has a soft-deleted scope: lesson_id=L1, topic_id=NULL | Deleted record exists |
| 2 | Open create form for Q1 | Form loads |
| 3 | Add scope row: Lesson L1, no topic, Target=10 | Same lesson+topic as soft-deleted record |
| 4 | Submit | updateOrCreate finds trashed record, restores it |
| 5 | DB check: old soft-deleted record | `deleted_at` set to NULL (restored) |
| 6 | DB check: is_active | Set to true |
| 7 | DB check: target_question_count | Updated to 10 |
| 8 | Verify no new record created — old record restored | Same ID as before |

---

#### TC-P07: Edit — Update scope target count and lesson

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Quest Q1 has 2 scopes: S1 (L1, target=5), S2 (L2, target=5), Q1 total_questions=10 | Scopes exist |
| 2 | Navigate to edit for Q1 | Edit form loads with 2 pre-filled rows |
| 3 | Change S1 target from 5 to 8 | S1 target changed |
| 4 | Change S2 target from 5 to 2 | Footer shows 10/10 |
| 5 | Submit update | Success |
| 6 | DB check: S1 target_question_count | 8 |
| 7 | DB check: S2 target_question_count | 2 |
| 8 | DB check: Quest Q1 total_questions | 10 (unchanged since sum=10 matches) |

---

#### TC-P08: Edit — Add new row and delete existing row (full replacement)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Quest Q1 has 2 scopes: S1 (id=1, L1, target=5), S2 (id=2, L2, target=5), Q1 total_questions=10 | Scopes exist |
| 2 | Open edit form | Shows S1 and S2 |
| 3 | Remove S2 row (trash icon) | S2 row removed from form |
| 4 | Add new row: Lesson L3, target=5 | Row added |
| 5 | Footer shows 10/10 (S1=5 + new=5) | Match |
| 6 | Submit | Success |
| 7 | DB check: S1 still exists, updated if changed | S1 preserved |
| 8 | DB check: S2 (id=2) | Force-deleted (permanently removed from DB) |
| 9 | DB check: new scope for L3 | Created with target=5 |
| 10 | DB check: total scopes for Q1 | 2 (S1 + new) |

---

#### TC-P09: Edit — Conflict detection when updating to duplicate lesson+topic

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Quest Q1 has scopes: S1 (L1, T1), S2 (L2, T2) | Scopes exist |
| 2 | Open edit, try to change S2's lesson to L1 and topic to T1 (same as S1) | Conflict scenario |
| 3 | Submit | Error: "Conflict: Another scope already exists for Lesson ID: {L1} and Topic ID: {T1}" |
| 4 | DB check: S2 unchanged | No update applied |

---

#### TC-P10: Edit — Auto-update Quest total_questions when scope sum changes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Quest Q1 has scope S1 (target=10), Q1 total_questions=15 | Mismatch: sum=10, quest=15 |
| 2 | Open edit, change S1 target from 10 to 15 | New sum=15 |
| 3 | Submit | Success |
| 4 | DB check: Quest Q1 total_questions | Updated to 15 (auto-synced to new sum) |
| 5 | DB check: S1 target_question_count | 15 |

---

#### TC-P11: Show — View grouped scope details with stats

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Quest Q1 has 3 scopes: S1(L1,T1,target=10), S2(L1,T2,target=5), S3(L2,NULL,target=5) | Scopes exist |
| 2 | Navigate to show: GET `/lms-quests/quest-scope/{Q1}` | Show page loads |
| 3 | Verify total_scopes | 3 |
| 4 | Verify total_questions (sum of targets) | 20 |
| 5 | Verify total_lessons (unique lesson_ids) | 2 (L1, L2) |
| 6 | Verify total_topics (unique topic_ids, excluding null) | 2 (T1, T2) |
| 7 | If no allocations/attempts exist | isUsed = false, no usage details |

---

#### TC-P12: Show — With usage (allocations exist)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Quest Q1 has scopes and an allocation with student attempts | Usage exists |
| 2 | Navigate to show for Q1 | Show page loads |
| 3 | Verify isUsed = true | Usage flag shown |
| 4 | Verify usageDetails | Allocation type, target, attempt count displayed |
| 5 | Verify attemptDetails | Recent student attempts listed |

---

#### TC-P13: Destroy — Soft-delete single scope with usage check (no usage)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Quest Q1 has scope S1, no allocations/attempts | S1 exists |
| 2 | Click Delete on S1 | POST destroy |
| 3 | Verify redirect with success | Redirected with success message "Quest scope moved to trash!" |
| 4 | DB check: S1.deleted_at | NOT NULL (soft-deleted) |
| 5 | DB check: S1.is_active | false (set to 0 before delete) |
| 6 | DB check: other scopes for Q1 | Unaffected |

---

#### TC-P14: Trashed — List scopes grouped by quest_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete 2 scopes for Q1 (S1, S2) | 2 scopes in trash for Q1 |
| 2 | Soft-delete 1 scope for Q2 (S3) | 1 scope in trash for Q2 |
| 3 | Navigate to trash: GET `/lms-quests/quest-scope/trash/view` | Trash page loads |
| 4 | Verify trashed scopes are grouped by quest_id | Q1: count=2, Q2: count=1 |
| 5 | Verify last_deleted_at column | Shows latest deletion timestamp per group |
| 6 | Verify pagination (10 per page) | Paginated |

---

#### TC-P15: Restore — Restore all soft-deleted scopes for a quest

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete 3 scopes for Q1 (no usage) | 3 scopes in trash for Q1 |
| 2 | Navigate to trash | Trash shows Q1 group |
| 3 | Click Restore on Q1 group | GET restore |
| 4 | Verify redirect with success | "Quest scope restored successfully!" |
| 5 | DB check: all 3 scopes for Q1 withTrashed | deleted_at = NULL for all (restored) |
| 6 | DB check: is_active for all 3 | true (set to 1 on restore) |
| 7 | DB check: scopes for other quests | Unaffected |

---

#### TC-P16: Force Delete — Permanently delete all scopes for a quest (no usage)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete 2 scopes for Q1 (no allocations/attempts) | 2 scopes in trash for Q1 |
| 2 | Navigate to trash | Trash shows Q1 group |
| 3 | Click Force Delete | DELETE forceDelete |
| 4 | Verify redirect with success | "Quest scope permanently deleted!" |
| 5 | DB check: scopes for Q1 withTrashed | Records gone (permanently removed) |
| 6 | DB check: scopes for other quests | Unaffected |

---

#### TC-P17: Toggle Status — Deactivate ALL scopes for a quest (AJAX)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Quest Q1 has 3 scopes, all is_active=1 | All active |
| 2 | Send AJAX POST to toggleStatus: scope_id=S1, is_active=0 | AJAX call |
| 3 | Verify response | `{"success": true, "message": "Status updated for selected scopes"}` |
| 4 | DB check: ALL scopes for Q1 (`where('quest_id', Q1->quest_id)`) | All 3 scopes have is_active=0 |
| 5 | DB check: scopes for other quests | Unaffected (only Q1's scopes toggled) |

---

#### TC-P18: Toggle Status — Reactivate ALL scopes for a quest (AJAX)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Quest Q1 has 3 scopes, all is_active=0 | All inactive |
| 2 | Send AJAX POST to toggleStatus: scope_id=S1, is_active=1 | AJAX call |
| 3 | Verify response | Success |
| 4 | DB check: ALL scopes for Q1 | All 3 have is_active=1 |

---

#### TC-P19: AJAX getQuestDetails — Returns quest metadata and lessons

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Quest Q1 with class_id=C1, subject_id=S1, total_questions=30, total_marks=100 | Quest exists |
| 2 | Create lessons L1, L2 for class C1 + subject S1 | Lessons match |
| 3 | Send AJAX GET to getQuestDetails: quest_id=Q1 | AJAX call |
| 4 | Verify response.success | true |
| 5 | Verify response.total_questions | 30 |
| 6 | Verify response.total_marks | 100.00 |
| 7 | Verify response.lessons array | Contains L1 and L2 |
| 8 | Verify lessons include id, name, code | Properly mapped and UTF-8 cleaned |

---

#### TC-P20: AJAX getQuestDetails — Quest not found returns error

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send AJAX GET to getQuestDetails with non-existent ID (99999) | Invalid quest |
| 2 | Verify response.success | false |
| 3 | Verify response.total_questions | 0 |
| 4 | Verify response.total_marks | 0 |
| 5 | Verify response.lessons | Empty array |

---

#### TC-P21: AJAX getLessonsByQuest — Returns subject-filtered lessons

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Quest Q1 with subject_id=S1 | Quest exists |
| 2 | Create Lesson L1 (subject_id=S1, active), Lesson L2 (subject_id=S2, active) | L1 matches, L2 does not |
| 3 | Send AJAX GET to getLessonsByQuest: quest_id=Q1 | AJAX call |
| 4 | Verify response.lessons | Contains L1 only (filtered by subject) |
| 5 | Verify Lesson names include code suffix | e.g. "Cell Biology (BIO-101)" |

---

#### TC-P22: AJAX getLessonsByQuest — Quest not found returns empty

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send AJAX GET with non-existent quest_id (99999) | Invalid quest |
| 2 | Verify response.lessons | Empty array |

---

#### TC-P23: AJAX getTopicHierarchy — Level 1 (root) topics

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Lesson L1 has Topic T1 (parent_id=null, level=1) and Topic T2 (parent_id=null, level=1) | Root topics exist |
| 2 | Send AJAX GET to getTopicHierarchy: lesson_id=L1, no level, no parent_id | AJAX call |
| 3 | Verify response.topics | Contains T1 and T2 (root topics where parent_id IS NULL or 0) |
| 4 | Verify topic data: id, name, level_id, level, level_name, parent_id | Proper structure |

---

#### TC-P24: AJAX getTopicHierarchy — Level 2 (children of Level 1)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Lesson L1 has T1 (root, level=1), T1a (parent_id=T1, level=2) | Hierarchy set |
| 2 | Send AJAX GET: lesson_id=L1, parent_id=T1, level=2 | AJAX call |
| 3 | Verify response.topics | Contains T1a only |
| 4 | Verify level=2 topics have proper topicLevelType | Level name shown (e.g. "Chapter") |

---

#### TC-P25: AJAX getTopicHierarchy — Full 4-level cascade

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 4-level hierarchy: L1→T1(lvl1)→T1a(lvl2)→T1ai(lvl3)→T1aiX(lvl4) | Full chain |
| 2 | Send AJAX: lesson_id=L1 (no level, no parent) | Returns T1 (root) |
| 3 | Send AJAX: lesson_id=L1, parent_id=T1, level=2 | Returns T1a |
| 4 | Send AJAX: lesson_id=L1, parent_id=T1a, level=3 | Returns T1ai |
| 5 | Send AJAX: lesson_id=L1, parent_id=T1ai, level=4 | Returns T1aiX |
| 6 | Verify each level scoped correctly | Only immediate children returned at each level |

---

#### TC-P26: AJAX getTopicHierarchy — Level filter and ordering

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Lesson L1 has topics with various levels | Topics exist |
| 2 | Send AJAX GET with level parameter | `$query->whereHas('topicLevelType', fn => where('level', N))` |
| 3 | Verify ordering | `orderBy('ordinal')->orderBy('name')` |
| 4 | Verify is_active filter | Only active topics returned |

---

### 10.2 Negative TC Steps

#### TC-N01: Create — No Quest selected

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to create form | Form loads |
| 2 | Add scope row without selecting a quest | Quest field empty |
| 3 | Submit | Validation error: "Please select a quest." |
| 4 | DB check: no scopes created | 0 records |

---

#### TC-N02: Create — No scope rows submitted

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select Quest Q1 | Quest selected |
| 2 | Submit without adding any scope rows | Empty scopes array |
| 3 | Server validation | Error: "Please add at least one scope." |
| 4 | DB check | 0 records created |

---

#### TC-N03: Create — Duplicate scope within same request (same lesson+topic)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select Quest Q1 | Quest selected |
| 2 | Add Row1: Lesson L1, no topic, Target=5 | Row1 configured |
| 3 | Add Row2: Lesson L1, no topic, Target=5 | Same lesson+topic = duplicate |
| 4 | Submit | Error: "Duplicate scope detected in your request for Lesson ID: {L1} and Topic ID: N/A" |
| 5 | DB check: transaction rolled back | No records created |

---

#### TC-N04: Create — Duplicate scope already exists in DB

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Quest Q1 already has scope: lesson_id=L1, topic_id=NULL | Existing scope |
| 2 | Open create form, add new row: Lesson L1, no topic | Same as existing |
| 3 | Submit | withValidator error: "This scope already exists for selected lesson and topic (or without topic)." |
| 4 | DB check: no duplicate record | Only original scope remains |

---

#### TC-N05: Create — Exceed max 20 scopes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Quest Q1 already has 19 scopes | 19 exist |
| 2 | Add 2 new scope rows (would make 21) | 2 new rows |
| 3 | Submit | Error: "Maximum 20 scopes allowed per quest." |
| 4 | DB check: count still 19 | Transaction rolled back |

---

#### TC-N06: Create — Missing lesson_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select Quest Q1 | Quest selected |
| 2 | Add scope row, leave Lesson dropdown empty | No lesson selected |
| 3 | Submit | Validation error: "Please select a lesson." |
| 4 | DB check | No record created |

---

#### TC-N07: Create — Invalid lesson_id (non-existent)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select Quest Q1 | Quest selected |
| 2 | Add scope row with lesson_id=99999 | Invalid lesson |
| 3 | Submit | Validation error: Selected lesson is invalid |
| 4 | DB check | No record created |

---

#### TC-N08: Create — Invalid topic_id (non-existent)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select Quest Q1 | Quest selected |
| 2 | Add scope row with topic_id=99999 | Invalid topic |
| 3 | Submit | Validation error: Selected topic is invalid |
| 4 | DB check | No record created |

---

#### TC-N09: Create — Invalid question_type_id (non-existent)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select Quest Q1 | Quest selected |
| 2 | Add scope row with question_type_id=99999 | Invalid type |
| 3 | Submit | Validation error (exists rule fails) |
| 4 | DB check | No record created |

---

#### TC-N10: Create — Negative target_question_count

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select Quest Q1 | Quest selected |
| 2 | Add scope row with Target = -5 | Negative value |
| 3 | Submit | Validation error: "Target cannot be negative." |
| 4 | DB check | No record created |

---

#### TC-N11: Edit — Blocked by usage (has allocations)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Quest Q1 has scopes and at least one allocation | Usage exists |
| 2 | Navigate to edit page for Q1 | Edit loads |
| 3 | Verify usage check fires | Redirected back: "Cannot edit this quest scopes because it is already used in allocations or attempts." |
| 4 | DB check: scopes unchanged | No modifications |

---

#### TC-N12: Edit — Blocked by usage (has student attempts)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Quest Q1 has scopes and student attempts via QuizQuestAttempt | Usage exists |
| 2 | Navigate to edit page for Q1 | Blocked: cannot edit |
| 3 | Verify error message | "Cannot edit this quest scopes because it is already used in allocations or attempts." |

---

#### TC-N13: Edit — No scopes found for quest

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Quest Q1 exists but has no scopes | Empty scope set |
| 2 | Navigate to edit: GET `/lms-quests/quest-scope/{Q1}/edit` | Redirected: "No scopes found for this quest." |

---

#### TC-N14: Update — Blocked by usage

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Quest Q1 has scopes + allocations | In use |
| 2 | Send PUT request to update scopes | Blocked: "Cannot update this quest scopes because it is already used." |
| 3 | DB check: scopes unchanged | No changes |

---

#### TC-N15: Destroy — Blocked by usage (has allocations)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Quest Q1 has scope S1 and an allocation | Usage exists |
| 2 | Click Delete on S1 | POST destroy |
| 3 | Verify blocked | Error: "Cannot delete this scope because the quest has allocations or student attempts." |
| 4 | DB check: S1.deleted_at | NULL (not deleted) |

---

#### TC-N16: Destroy — Blocked by usage (has student attempts)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Quest Q1 has scope S1 and student attempts | Usage exists |
| 2 | Click Delete on S1 | POST destroy |
| 3 | Verify blocked | Error: "Cannot delete this scope because the quest has allocations or student attempts." |
| 4 | DB check: S1.deleted_at | NULL (not deleted) |

---

#### TC-N17: Restore — Blocked by usage

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Quest Q1 has soft-deleted scopes and has student attempts | Trashed + in use |
| 2 | Navigate to trash, click Restore | Blocked: "Cannot restore this scope because the quest has allocations or student attempts." |
| 3 | DB check: scopes remain soft-deleted | deleted_at still NOT NULL |

---

#### TC-N18: Force Delete — Blocked by usage

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Quest Q1 has soft-deleted scopes and has allocations/attempts | Trashed + in use |
| 2 | Navigate to trash, click Force Delete | Blocked: "Cannot permanently delete this scope because the quest has allocations or student attempts." |
| 3 | DB check: scopes still exist withTrashed | Records not permanently removed |

---

#### TC-N19: View — without permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user WITHOUT `tenant.quest-scope.viewAny` permission | Authenticated |
| 2 | Navigate to Quest Scopes index | 403 Forbidden |

---

#### TC-N20: Create — without permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user WITHOUT `tenant.quest-scope.create` permission | Authenticated |
| 2 | Navigate to create page | 403 Forbidden |
| 3 | Send POST to store directly | 403 Forbidden |

---

#### TC-N21: Edit — without permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user WITHOUT `tenant.quest-scope.update` permission | Authenticated |
| 2 | Navigate to edit page directly | 403 Forbidden |
| 3 | Send POST to toggleStatus | 403 Forbidden |

---

#### TC-N22: Delete — without permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user WITHOUT `tenant.quest-scope.delete` permission | Authenticated |
| 2 | Send DELETE request directly | 403 Forbidden |

---

#### TC-N23: Restore — without permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user WITHOUT `tenant.quest-scope.restore` permission | Authenticated |
| 2 | Send GET restore request directly | 403 Forbidden |

---

#### TC-N24: Force Delete — without permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user WITHOUT `tenant.quest-scope.forceDelete` permission | Authenticated |
| 2 | Send DELETE forceDelete directly | 403 Forbidden |

---

#### TC-N25: Toggle Status — Invalid is_active value

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send AJAX POST to toggleStatus: is_active='invalid' | Non-boolean value |
| 2 | Verify validation error | 422 response: is_active must be boolean |
| 3 | DB check: scopes is_active unchanged | No toggle applied |

---

#### TC-N26: Create — Invalid quest_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form loads |
| 2 | Select non-existent quest_id (e.g., 99999) | Invalid quest |
| 3 | Submit | Validation error: quest_id does not exist |
| 4 | DB check | No record created |

---

### 10.3 Dependency TC Steps

#### TC-D01: Cascade — Quest force-deleted cascades to scopes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Quest Q1 with 3 scopes | Q1 + scopes exist |
| 2 | Force-delete Quest Q1 (from Quest controller) | Q1 permanently removed |
| 3 | DB check: scopes for Q1 | Cascade-deleted (FK ON DELETE CASCADE) |
| 4 | DB check: scopes withTrashed | Records gone permanently |

---

#### TC-D02: Cascade — Quest soft-deleted leaves scopes intact

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Quest Q1 with 3 scopes | Q1 + scopes exist |
| 2 | Soft-delete Quest Q1 | Q1 soft-deleted |
| 3 | DB check: scopes for Q1 | Still exist (soft-delete doesn't cascade) |
| 4 | DB check: scope is_active | Unchanged |

---

#### TC-D03: Business — Store with `updateOrCreate` restores soft-deleted duplicate

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Quest Q1 has scope S1 (L1, no topic) that was soft-deleted | S1.deleted_at NOT NULL |
| 2 | Create new scope: Quest Q1, Lesson L1, no topic | Same combo |
| 3 | Controller uses `updateOrCreate` with `withTrashed()` | Old S1 restored |
| 4 | DB check: old S1.deleted_at | NULL (restored) |
| 5 | DB check: old S1.target_question_count | Updated to new value |
| 6 | Verify no duplicate ID created | Only 1 record for L1+no topic |

---

#### TC-D04: Business — Dynamic duplicate detection in store prevents internal conflicts

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Single request with Row1 (L1, T1) and Row2 (L1, T1) | Same combo in same request |
| 2 | In-memory `$seenScopes` detects duplicate | Exception thrown before DB write |
| 3 | DB check: no records created (transaction rolled back) | Atomic rollback |

---

#### TC-D05: Business — Update full replacement force-deletes removed scopes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Quest Q1 has 3 scopes: S1(id=1), S2(id=2), S3(id=3) | 3 existing |
| 2 | Submit update with only S1(id=1) and S3(id=3) in scopes array | S2 omitted |
| 3 | Code computes `array_diff([1,2,3], [1,3])` = [2] | S2 ID identified for removal |
| 4 | `QuestScope::whereIn('id', [2])->forceDelete()` | S2 permanently deleted |
| 5 | DB check: only S1 and S3 remain | Full replacement confirmed |

---

#### TC-D06: Business — Quest total_questions auto-updated on scope update

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Quest Q1 has total_questions=10, scope sum=10 | Match |
| 2 | Update scope: change target from 5 to 8 (new sum=13) | Sum changed |
| 3 | Controller checks: `$quest->total_questions != $totalQuestions` (10 != 13) | Condition true |
| 4 | `$quest->update(['total_questions' => 13])` | Quest updated |
| 5 | DB check: Q1.total_questions | 13 |

---

#### TC-D07: Business — Activity log recorded for store/create/destroy/restore/forceDelete/toggleStatus

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Perform store (create scopes) | Activity log: 'Stored' event created |
| 2 | Perform destroy (soft-delete) | Activity log: 'Trashed' event created |
| 3 | Perform restore | Activity log: 'Restored' event created |
| 4 | Perform forceDelete | Activity log: 'Permanently Deleted' event created |
| 5 | Perform toggleStatus | Activity log: 'Toggled' event created per scope |
| 6 | Verify each event has actor, message, and timestamp | Audit trail complete |

---

#### TC-D08: Business — Store with zero valid rows rolls back

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit scopes array with all rows having empty lesson_id | No valid rows |
| 2 | Controller loop skips rows where `empty($row['lesson_id'])` | 0 created |
| 3 | `if ($created === 0)` → rollback | Transaction reversed |
| 4 | Error message returned | "No valid scope rows found. Please select at least Lesson." |

---

### 10.4 Code Review TC Steps

#### TC-CR01: Request — QuestScopeRequest base validation rules

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `QuestScopeRequest::rules()` | Validates quest_id, scopes array, each scope's lesson_id (required), topic_id (nullable), question_type_id (nullable), target_question_count (integer|min:0), is_active (boolean) |
| 2 | Verify `target_question_count` is `nullable` in rules() | Accepts missing (defaults to 0 via prepareForValidation) |
| 3 | Verify `prepareForValidation()` | Sets `target_question_count` to 0 if missing; sets `is_active` to 1 if unchecked |

---

#### TC-CR02: Request — Duplicate Check (withValidator)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `withValidator()` duplicate check | Queries `QuestScope::where('quest_id', X)->where('lesson_id', L)` |
| 2 | Verify topic_id handling: if provided → `where('topic_id', T)`, else → `whereNull('topic_id')` | Correct null handling |
| 3 | Verify error message per row | "This scope already exists for selected lesson and topic (or without topic)." |
| 4 | Verify edit does NOT exclude current record in duplicate check | Known gap: same duplicate check applies on edit as well |

---

#### TC-CR03: Request — Max 20 Check (withValidator)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review max 20 check: `existingCount + newCount > 20` | Total must not exceed 20 |
| 2 | Verify `existingCount = QuestScope::where('quest_id', X)->count()` | Counts all existing (including inactive) |
| 3 | Verify error on `quest_id` field | "Maximum 20 scopes allowed per quest." |

---

#### TC-CR04: Controller store() — In-Memory Duplicate Detection

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `store()` method | Before DB insert, checks `$seenScopes` array |
| 2 | Verify scope key: `"{$questId}-{$row['lesson_id']}-" . ($row['topic_id'] ?? 'null')` | Distinguishes null vs value |
| 3 | Verify exception on duplicate | `throw new \Exception("Duplicate scope detected...")` |
| 4 | Verify exception caught → rollback → error redirect | Transaction-safe |

---

#### TC-CR05: Controller store() — updateOrCreate with withTrashed

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `updateOrCreate()` call | Uses `QuestScope::withTrashed()` scope |
| 2 | Verify match fields: `['quest_id', 'lesson_id', 'topic_id']` | Unique key matched |
| 3 | Verify update fields: `question_type_id`, `target_question_count`, `is_active`, `deleted_at => null` | Restores and updates |
| 4 | Verify `deleted_at => null` explicitly set | Overrides soft-delete timestamp |

---

#### TC-CR06: Controller store() — Transaction + Rollback

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review transaction wrapper: `DB::beginTransaction()` before loop | Atomic operation |
| 2 | Verify `DB::commit()` on success | Persisted |
| 3 | Verify `DB::rollBack()` in catch + empty-rows check | All-or-nothing behaviour |
| 4 | Verify error logging: `Log::error(...)` with exception, request, user | Debug info captured |

---

#### TC-CR07: Controller edit() — Usage Check Before Loading

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `edit()` method | First retrieves scopes, then checks usage |
| 2 | Verify usage check via `QuestScopeUsageCheckService::isUsed($id)` | Passes scope ID, checks quest's allocations/attempts |
| 3 | Verify early redirect on usage | `return back()->with('error', 'Cannot edit...')` |
| 4 | Verify data load for edit view: QuestionTypes (active), Lessons (filtered by class+subject), TopicLevelTypes (active) | Proper scoped loads |
| 5 | Verify scope parent chain generation: traverses topic ancestors up to root | Array of `[id, name, level, level_name]` |

---

#### TC-CR08: Controller update() — Full Replacement Logic

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `update()` method | Gets existing scope IDs via `QuestScope::where('quest_id')->pluck('id')` |
| 2 | Verify submitted IDs tracked in `$submittedScopeIds[]` | Every processed row's ID added |
| 3 | Verify `array_diff($existingScopeIds, $submittedScopeIds)` | Computes removed IDs |
| 4 | Verify `QuestScope::whereIn('id', $scopesToDelete)->forceDelete()` | Permanently removes omitted scopes |
| 5 | Verify conflict check before update | Prevents creating duplicate lesson+topic via update |

---

#### TC-CR09: Controller update() — Quest total_questions Auto-Sync

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review sync logic after scope save | `$totalQuestions = QuestScope::where('quest_id')->sum('target_question_count')` |
| 2 | Verify `if ($quest && $quest->total_questions != $totalQuestions)` | Only updates if different |
| 3 | Verify `$quest->update(['total_questions' => $totalQuestions])` | Auto-syncs quest total |
| 4 | Verify this happens inside same transaction | Consistent with scope changes |

---

#### TC-CR10: Controller show() — Grouped Statistics

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `show()` method | Gets all scopes for quest by `quest_id` |
| 2 | Verify abort if empty | `if ($scopes->isEmpty()) abort(404)` |
| 3 | Verify `total_scopes = count()` | 3 |
| 4 | Verify `total_questions = sum(target_question_count)` | Sum of all targets |
| 5 | Verify `total_lessons = pluck('lesson_id')->unique()->count()` | Unique lesson count |
| 6 | Verify `total_topics = pluck('topic_id')->unique()->count()` | Unique topic count (excluding nulls) |
| 7 | Verify usage check via `QuestScopeUsageCheckService` | isUsed, usageDetails, attemptDetails |

---

#### TC-CR11: Controller destroy() — Soft Delete with Usage Guard

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `destroy()` method | Sets `is_active = false`, then `delete()` |
| 2 | Verify usage check runs BEFORE Gate | `isUsed` check first, then `Gate::authorize` |
| 3 | Verify `$scope->update(['is_active' => false])` | Deactivates before soft-delete |
| 4 | Verify `$scope->delete()` | Sets deleted_at |
| 5 | Verify activity log | `activityLog($scope, 'Trashed', ...)` |

---

#### TC-CR12: Controller trashed() — Grouped by Quest

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `trashed()` method | `QuestScope::onlyTrashed()` |
| 2 | Verify select: `quest_id, COUNT(*) as total_scopes, MAX(deleted_at) as last_deleted_at` | Grouped aggregation |
| 3 | Verify `groupBy('quest_id')` | One row per quest in trash |
| 4 | Verify `orderByDesc('last_deleted_at')` | Most recently deleted first |
| 5 | Verify pagination: 10 per page | Paginated result |

---

#### TC-CR13: Controller restore() — Batch Restore All Scopes for Quest

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `restore()` method | Gets all trashed scopes for quest: `QuestScope::onlyTrashed()->where('quest_id', $id)->get()` |
| 2 | Verify usage check before restore | Blocks if quest has allocations/attempts |
| 3 | Verify each scope restored + reactivated | `$scope->restore()` and `$scope->update(['is_active' => true])` |
| 4 | Verify activity log per scope | `activityLog($scope, 'Restored', ...)` |
| 5 | Verify all-or-nothing transaction | DB::beginTransaction/commit/rollBack |

---

#### TC-CR14: Controller forceDelete() — Permanent Delete All Scopes for Quest

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `forceDelete()` method | Gets all scopes: `QuestScope::withTrashed()->where('quest_id', $id)->get()` |
| 2 | Verify usage check before force-delete | Blocks if quest has allocations/attempts |
| 3 | Verify each scope force-deleted in loop | `$scope->forceDelete()` |
| 4 | Verify activity log per scope | `activityLog($scope, 'Deleted', ...)` |
| 5 | Verify transaction wrapper | All-or-nothing |

---

#### TC-CR15: Controller toggleStatus() — Bulk Toggle All Scopes for Quest

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `toggleStatus()` method | Finds scope by ID, then gets ALL scopes by `quest_id` |
| 2 | Verify `$request->validate(['is_active' => 'required|boolean'])` | Validates input |
| 3 | Verify loop: `QuestScope::where('quest_id', $scope->quest_id)->get()` | ALL scopes for quest toggled |
| 4 | Verify each scope updated: `$scopeData->update(['is_active' => $request->boolean('is_active')])` | Bulk update |
| 5 | Verify JSON response | `{'success': true, 'message': 'Status updated for selected scopes'}` |
| 6 | Verify BR-QST-032 (BC-BIZ-06) enforced | All scopes for same quest toggled, not just the clicked one |

---

#### TC-CR16: Controller getQuestDetails() — AJAX Data

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `getQuestDetails()` | Finds quest, returns total_questions, total_marks, and filtered lessons |
| 2 | Verify lesson filter: `Lesson::where('class_id', X)->where('subject_id', Y)->where('is_active', 1)` | Scoped to quest's class+subject |
| 3 | Verify UTF-8 cleaning via `cleanUtf8String()` | Removes invalid UTF-8 characters from names |
| 4 | Verify catch block returns safe defaults | success=false, 0s, empty array |

---

#### TC-CR17: Controller getLessonsByQuest() — AJAX Lessons

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `getLessonsByQuest()` | Finds quest, returns active lessons by subject_id |
| 2 | Verify NOT found → empty array | `if (!$quest) return ['lessons' => []]` |
| 3 | Verify lesson response: id, name with code suffix | `name . " ({$l->code})"` |
| 4 | Verify ordering: `orderBy('name')` | Alphabetical |

---

#### TC-CR18: Controller getTopicHierarchy() — 4-Level Cascading

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `getTopicHierarchy()` | Builds query on `Topic::where('lesson_id', X)->where('is_active', 1)` |
| 2 | Verify parent_id filter: if provided → `where('parent_id', P)`, else → `whereNull('parent_id')->orWhere('parent_id', 0)` | Root vs child topics |
| 3 | Verify level filter: `whereHas('topicLevelType', fn => where('level', N))` | Scoped to specific hierarchy level |
| 4 | Verify eager-load: `with('topicLevelType')` | Includes level name in response |
| 5 | Verify ordering: `orderBy('ordinal')->orderBy('name')` | Proper sort |
| 6 | Verify response: id, name, level_id, level, level_name, parent_id | Complete topic data |

---

#### TC-CR19: Controller index() — Always 404 (Not Used)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `index()` method | `Gate::authorize('tenant.quest-scope.viewAny')` then `abort(404)` |
| 2 | Verify paginated query exists but never reached | Dead code after abort(404) |

---

#### TC-CR20: Controller — Permission Gates Consistent Across Methods

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review Gate calls in every method | Each endpoint calls `Gate::authorize('tenant.quest-scope.{action}')` |
| 2 | Verify destroy() calls Gate AFTER usage check | Usage guard first, then Gate |
| 3 | Verify restore() calls Gate AFTER usage check | Usage guard first, then Gate |
| 4 | Verify forceDelete() calls Gate AFTER usage check | Usage guard first, then Gate |

---

#### TC-CR21: Service — QuestScopeUsageCheckService Usage Logic

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `isUsed($scopeId)` | Returns `getUsageCount > 0` |
| 2 | Review `getUsageCount($scopeId)` | Finds scope → gets `quest_id` → counts `QuestAllocation + QuizQuestAttempt` |
| 3 | Review `getUsageDetails($scopeId)` | Returns total_usage, quest info, per-allocation breakdown |
| 4 | Review `getUsageMessage($scopeId)` | Human-readable usage message |
| 5 | Review `getQuestAttemptsDetails($scopeId, $limit)` | Latest student attempts with eager-loaded student+user |
| 6 | Review null-safety: returns 0 or empty if scope/quest not found | Graceful degradation |

---

#### TC-CR22: Policy — QuestScopePolicy Permission Map

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `QuestScopePolicy` | Maps each Gate method to `user->can('tenant.quest-scope.{action}')` |
| 2 | Verify all 11 permissions mapped | viewAny, view, create, update, delete, restore, forceDelete, status, bulkAdd, import, export |
| 3 | Verify policies reference QuestScope model | All policy methods typed with `QuestScope $questScope` (except create/bulkAdd/import/export which use no model) |

---

#### TC-CR23: Blade — @can Directives in Templates

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `index.blade.php` | `@can('tenant.quest-scope.status')` wraps the Active column header and status-switch component; `@canany(['.view', '.update', '.delete'])` wraps the Actions column |
| 2 | Verify `show.blade.php` | `@can('tenant.quest-scope.update')` wraps the "Edit Quest" button, combined with `@if(!$isUsed)` condition |
| 3 | Verify `trash.blade.php` | `@canany(['tenant.quest-scope.restore', 'tenant.quest-scope.forceDelete'])` wraps the Action column and `action-trashed` component |
| 4 | Verify no orphan UI elements | Every action button/link in views is gated by the appropriate @can/@canany directive |
| 5 | Verify consistency with Policy | All permission strings used in @can match the 11 gates defined in `QuestScopePolicy` |

---

#### TC-CR24: Blade — Breadcrumb Navigation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `create.blade.php` | `<x-backend.components.breadcrum title="Create Quest Scope" :links="[]" />` — renders breadcrumb with title only |
| 2 | Review `edit.blade.php` | `<x-backend.components.breadcrum title="Edit Quest Scopes" :links="[]" />` — renders breadcrumb with title |
| 3 | Review `show.blade.php` | `<x-backend.components.breadcrum title="Quest Scope Details" :links="[]" />` — renders breadcrumb with title |
| 4 | Review `trash.blade.php` | `<x-backend.components.breadcrum title="Trashed Quest Scopes" :links="[]" />` — renders breadcrumb with title |
| 5 | Verify all 4 view files have breadcrumb component rendered at top | Consistent breadcrumb navigation across all views |
| 6 | Verify `:links="[]"` indicates no parent links (flat breadcrumb) | Breadcrumb shows only the current page title |

---

#### TC-CR25: View — isset / Null Coalescing Checks

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `show.blade.php` | `{{ $scope->lesson->name ?? '-' }}`, `{{ $scope->topic->name ?? 'All' }}`, `{{ $scope->questionType->name ?? 'Any' }}`, `{{ $groupedData->quest->title ?? 'N/A' }}` — all nullable relations use `??` fallback |
| 2 | Review `index.blade.php` | `{{ $scope->quest->title ?? 'N/A' }}`, `{{ $scope->lesson->name ?? 'N/A' }}`, `{{ $scope->topic->name ?? 'N/A' }}` — all nullable fields guarded |
| 3 | Review `trash.blade.php` | `{{ $scope->quest->title ?? '-' }}` — nullable quest relation guarded |
| 4 | Review `create.blade.php` JS | `sanitizeString()` helper function strips invalid characters; `Array.isArray(lessons)` check before iteration; `res.lessons && res.lessons.length > 0` guard |
| 5 | Review null safety for optional topic_id | `($row['topic_id'] ?? 'null')` in controller; `$scope->topic->name ?? 'All'` in show view; `$scope->topic->name ?? 'N/A'` in index view |

---

#### TC-CR26: View — Flash / Session Messages

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `create.blade.php` | `@if ($errors->any())` block renders validation errors in `alert-danger` div with listed messages |
| 2 | Review `edit.blade.php` | Same `@if ($errors->any())` block for validation error display |
| 3 | Review controller `store()` | `->with('success', "{$created} quest scope(s) added successfully!")` on success; `->with('error', 'Failed...')` on failure |
| 4 | Review controller `update()` | `->with('success', $messageText)` on success with created/updated/deleted counts |
| 5 | Review controller `destroy()` | `->with('success', 'Quest scope moved to trash!')` on success |
| 6 | Review controller `restore()` | `->with('success', 'Quest scope restored successfully!')` on success |
| 7 | Review controller `forceDelete()` | `->with('success', 'Quest scope permanently deleted!')` on success |
| 8 | Verify all flash messages use consistent `success`/`error` keys | Session flash keys are standardized across all controller methods |

---

## 11. Route Reference

| Method | URL | Name | Controller Method | Required Permission |
|--------|-----|------|-------------------|---------------------|
| GET | `/lms-quests/quest-scope` | lms-quests.quest-scope.index | index() (aborts 404) | tenant.quest-scope.viewAny |
| GET | `/lms-quests/quest-scope/create` | lms-quests.quest-scope.create | create() | tenant.quest-scope.create |
| POST | `/lms-quests/quest-scope` | lms-quests.quest-scope.store | store() | tenant.quest-scope.create |
| GET | `/lms-quests/quest-scope/{quest_scope}` | lms-quests.quest-scope.show | show() | tenant.quest-scope.view |
| GET | `/lms-quests/quest-scope/{quest_scope}/edit` | lms-quests.quest-scope.edit | edit() | tenant.quest-scope.update |
| PUT | `/lms-quests/quest-scope/{quest_scope}` | lms-quests.quest-scope.update | update() | tenant.quest-scope.update |
| DELETE | `/lms-quests/quest-scope/{quest_scope}` | lms-quests.quest-scope.destroy | destroy() | tenant.quest-scope.delete |
| GET | `/lms-quests/quest-scope/trash/view` | lms-quests.quest-scope.trashed | trashed() | tenant.quest-scope.restore |
| GET | `/lms-quests/quest-scope/{id}/restore` | lms-quests.quest-scope.restore | restore() | tenant.quest-scope.restore |
| DELETE | `/lms-quests/quest-scope/{id}/force-delete` | lms-quests.quest-scope.forceDelete | forceDelete() | tenant.quest-scope.forceDelete |
| POST | `/lms-quests/quest-scope/{quest_scope}/toggle-status` | lms-quests.quest-scope.toggleStatus | toggleStatus() | tenant.quest-scope.update |
| GET | `/lms-quests/quest-details/{id}` | (custom) | getQuestDetails() | tenant.quest-scope.view |
| GET | `/lms-quests/lessons-by-quest` | (custom) | getLessonsByQuest() | tenant.quest-scope.view |
| GET | `/lms-quests/topic-hierarchy` | (custom) | getTopicHierarchy() | tenant.quest-scope.view |

---

## 12. Test Case Summary

### 12.1 TC Distribution

| Category | Count | ID Range | Coverage |
|----------|-------|----------|----------|
| Positive (P) | 26 | P01 – P26 | Create (P01–P06), Edit (P07–P10), Show (P11–P12), Destroy (P13), Trashed (P14), Restore (P15), Force Delete (P16), Toggle Status (P17–P18), AJAX endpoints (P19–P26) |
| Negative (N) | 26 | N01 – N26 | Create validation (N01–N10), Edit/Update blocked (N11–N14), Destroy blocked (N15–N16), Restore/ForceDelete blocked (N17–N18), Authorization (N19–N24), Toggle invalid (N25), Invalid quest (N26) |
| Dependency (D) | 8 | D01 – D08 | Cascade (D01–D02), Business logic (D03–D08) |
| Code Review (CR) | 26 | CR01 – CR26 | Request (CR01–CR03), Controller store (CR04–CR06), Controller edit/update (CR07–CR09), Controller show/destroy (CR10–CR11), Controller trashed/restore/forceDelete (CR12–CR14), Controller toggle (CR15), AJAX methods (CR16–CR18), Controller index/gates (CR19–CR20), Service (CR21), Policy (CR22), Blade @can (CR23), Breadcrumb (CR24), Null coalescing (CR25), Flash messages (CR26) |
| **Total** | **86** | | |

### 12.2 Coverage by Module Component

| Component | TCs Count | TC IDs |
|-----------|-----------|--------|
| QuestScopeRequest (Validation) | 9 | P01–P05, N01–N10, CR01–CR03 |
| QuestScopeController CRUD | 30 | P06–P18, N11–N18, CR04–CR15 |
| QuestScopeController AJAX | 8 | P19–P26, CR16–CR18 |
| QuestScopePolicy (Auth) | 8 | N19–N24, CR20, CR22, CR23 |
| QuestScopeUsageCheckService | 6 | P12, N11–N18, CR21 |
| Blade Views (UI) | 4 | CR23–CR26 |
| Database (DDL/FK) | 2 | D01–D02 |
| Activity Logging | 1 | D07 |
| Model (QuestScope) | 1 | CR05 |

### 12.3 Coverage by Business Rule

| BC-BIZ ID | Rule | Covered By |
|-----------|------|------------|
| BC-BIZ-01 | Lesson Mandatory, Topic Optional | P01, P02, N06–N08, CR01 |
| BC-BIZ-02 | No Duplicate lesson+topic per Quest | N03, N04, CR02, CR04 |
| BC-BIZ-03 | Target Count 0 = Unlimited | P05 |
| BC-BIZ-04 | Max 20 Scopes per Quest | P04, N05, CR03 |
| BC-BIZ-05 | Usage Lock — Modification Guard | N11, N12, N14–N18, CR07, CR13, CR14, CR21 |
| BC-BIZ-06 | Toggle Affects ALL Scopes for Quest | P17, P18, CR15 |
| BC-BIZ-07 | Exact Sum Match (Frontend) | P03, P07, P10 |
| BC-BIZ-08 | Full Replacement on Update | P08, D05, CR08 |
| BC-BIZ-09 | Auto-Sync Quest total_questions | P10, D06, CR09 |
| BC-BIZ-10 | updateOrCreate Restores Trashed | P06, D03, CR05 |
| BC-BIZ-11 | All-or-Nothing DB Transaction | N03, N05, D04, D08, CR06 |
| BC-BIZ-12 | Batch Restore All Scopes for Quest | P15, CR13 |
| BC-BIZ-13 | Batch Force-Delete All Scopes for Quest | P16, CR14 |
| BC-BIZ-14 | Soft Delete Deactivates Before Delete | P13, CR11 |
| BC-BIZ-15 | Activity Logging | D07, CR11, CR13, CR14, CR15 |

---

## 13. Known Issues

| # | Issue | Severity | Details |
|---|-------|----------|---------|
| KI-01 | `QuestScopeRequest::authorize()` returns `true` unconditionally | **High** | `authorize()` returns `true` instead of checking `Gate::allows()`. Permission is enforced in the Controller via `Gate::authorize()`, but this bypasses the defence-in-depth pattern used by other modules. |
| KI-02 | `QuestScopeRequest` does NOT validate exact sum match | **Low** | The exact sum match (scope target sum === quest total_questions) is only enforced on the frontend (submit button disabled). The backend does NOT validate this. A direct POST could create scopes with sum != total_questions. |
| KI-03 | `toggleStatus()` uses single scope ID but toggles ALL by quest_id | **Medium** | The endpoint accepts a specific `{quest_scope}` ID but then toggles all scopes for that quest. The response message says "selected scopes" but selection is automatic. This is by design (BC-BIZ-06) but the endpoint contract is misleading. |
| KI-04 | `trashed()` Gate uses `tenant.quest-scope.restore` permission | **Low** | Trash view requires restore permission, not viewAny. Users with viewAny but not restore cannot see the trash list, even though they can view active scopes. |
| KI-05 | `restore()` and `forceDelete()` operate on all scopes by quest_id | **Low** | Both methods receive a scope ID but query all scopes by `quest_id`. The URL parameter `{id}` is a scope ID but the operation is per-quest. This is by design (grouped trash) but the route param is misleading. |
| KI-06 | No `index()` page — always aborts 404 | Low | The `index()` method calls `abort(404)`. Quest Scopes are only accessed via the Quest's tab interface, never standalone. |
| KI-07 | DDL specifies `topic_id` as `NOT NULL` but code treats it as nullable | Medium | The DDL `lms_quest_scopes.topic_id` is `INT UNSIGNED NOT NULL` but the code uses `nullable\|exists:slb_topics,id`. The code behaviour (nullable) is authoritative, representing a schema drift between DDL and migrations. |
| KI-08 | `getQuestDetails()` calls `Quest::findOrFail($id)` inside catch block | Low | The exception from `findOrFail` is caught by the generic catch block, returning a safe error JSON. This is acceptable but a dedicated 404 check could be cleaner. |
| KI-09 | `toggleStatus()` Null Reference — missing `first()` / `findOrFail()` | **Medium** | `$scope = QuestScope::where('id',$id)->first();` returns null if not found. `$scope->quest_id` would throw error. No null-check before accessing quest_id. |
