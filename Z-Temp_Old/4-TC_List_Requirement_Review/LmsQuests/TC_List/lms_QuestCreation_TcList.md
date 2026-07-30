# lms_QuestCreation_TcList

## Module: LmsQuests → Quest Management → Quest Creation & Configuration

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | LmsQuests |
| Tab Group | Quest Management |
| Feature | Quest Creation & Configuration, Publish & Lifecycle, Duplication, Soft Delete/Restore/Force Delete, Status Toggle |
| Wizard | 2-Tab: Tab 1 (Basic Information) → Tab 2 (Configuration) |
| URL(s) | `/lms-quests/quest` (resource index/create/store/show/edit/update/destroy), `/lms-quests/quest/trash/view` (trashed), `/lms-quests/quest/{id}/restore` (restore), `/lms-quests/quest/{id}/force-delete` (forceDelete), `/lms-quests/quest/{quest}/toggle-status` (toggleStatus), `/lms-quests/quest/get-subjects-by-class` (AJAX cascade), `/lms-quests/quest-summary` (summary redirect), `/lms-quests/quest/report/{id}` (report), `/lms-quests/quest/{id}/paper-check` (paper check) |
| Controller | `Modules\LmsQuests\Http\Controllers\LmsQuestController` |
| Model(s) | `Quest` (`Modules\LmsQuests\Models\Quest`) — also `SoftDeletes` trait |
| Validation (Create/Update) | `QuestRequest` (`Modules\LmsQuests\Http\Requests\QuestRequest`) |
| Permission Gates | `tenant.quest.viewAny`, `.view`, `.create`, `.update`, `.delete`, `.restore`, `.forceDelete`, `.status`, `.duplicate`, `.publish`, `.archive`, `.manageQuestions`, `.manageAllocations` |
| Soft Deletes | Yes — `SoftDeletes` trait on Quest |
| Activity Log Events | `Stored`, `Updated`, `Trashed`, `Restored`, `Deleted` (force), `Toggled` |
| Auto-Generated Fields | `uuid` (binary 16), `quest_code` (pattern: `QUEST_{SESSION}_{CLASS}_{SUBJECT}_GEN_{RANDOM6}`), `created_by` (from auth), `created_at` |
| Usage Guard | `QuestUsageCheckService` — blocks edit/delete/restore/forceDelete when allocations or attempts exist |

---

## 2. Pre-conditions

- Required permissions: `tenant.quest.viewAny`, `.create`, `.update`, `.delete`, `.restore`, `.forceDelete`, `.status`, `.duplicate`, `.publish`, `.archive`
- At least one active Academic Session must exist (`glb_academic_sessions.is_current = 1`)
- At least one active School Class must exist (`sch_classes.is_active = 1`)
- At least one active Subject must exist (`sch_subjects.is_active = 1`)
- At least one active Assessment Type (Quest Type) must exist (`lms_assessment_types.is_active = 1`)
- For difficulty tests: At least one active Difficulty Distribution Config (`lms_difficulty_distribution_configs.is_active = 1`)
- For usage constraint tests: Student allocations and attempts must exist via `QuestAllocation` / `QuizQuestAttempt`
- For duplication tests: At least one existing Quest with scopes and questions
- For trash/restore tests: At least one soft-deleted Quest

---

## 3. Default Data Load

When create page loads (GET `/lms-quests/quest/create`):

| Data | Source | Query | Pagination |
|------|--------|-------|------------|
| Quest (new empty) | `new Quest()` | — | None |
| Assessment Types | `AssessmentType::where('is_active', '1')` | Active types | None |
| Difficulty Configs | `DifficultyDistributionConfig::where('is_active', '1')` | Active configs | None |
| Academic Sessions | `AcademicSession::where('is_current', '1')->first()` | Current session only | None |
| Classes | `SchoolClass::where('is_active', '1')` | Active classes | None |
| Subjects | `Subject::where('is_active', '1')` | Active subjects | None |
| Lessons | `Lesson::where('is_active', '1')` | Active lessons | None |

When edit page loads (GET `/lms-quests/quest/{quest}/edit`):

| Data | Source | Notes |
|------|--------|-------|
| Quest (existing) | `Quest::findOrFail($id)` | With all fillable attributes |
| Assessment Types | `AssessmentType::where('is_active', '1')` | Same as create |
| Difficulty Configs | `DifficultyDistributionConfig::where('is_active', '1')` | Same as create |
| Academic Sessions | `AcademicSession::where('is_current', '1')->first()` | Same as create |
| Classes | `SchoolClass::where('is_active', '1')` | Same as create |
| Subjects | `Subject::where('is_active', '1')` | Same as create |
| Lessons | `Lesson::where('is_active', '1')` | Same as create |
| Usage Check | `QuestUsageCheckService::isUsed($id)` | Blocks edit if used |

---

## 4. Database Schema (BC-DB)

### `lms_quests` — DDL Columns, Types & Constraints

| BC-DB ID | Column | Type | Nullable | Default | Constraints | Notes |
|----------|--------|------|----------|---------|-------------|-------|
| BC-DB-01 | id | INT UNSIGNED | NOT NULL | | PK, AUTO_INCREMENT | Surrogate primary key |
| BC-DB-02 | uuid | BINARY(16) | NOT NULL | | UNIQUE (uq_quest_uuid) | Auto-generated via `Str::uuid()->getBytes()` on create |
| BC-DB-03 | academic_session_id | INT UNSIGNED | NOT NULL | | FK → glb_academic_sessions.id | Required; cascade delete |
| BC-DB-04 | class_id | INT UNSIGNED | NOT NULL | | FK → sch_classes.id | Required; cascade delete |
| BC-DB-05 | subject_id | INT UNSIGNED | NOT NULL | | FK → sch_subjects.id | Required; cascade delete |
| BC-DB-06 | quest_type_id | INT UNSIGNED | NOT NULL | | FK → lms_assessment_types.id | Required; cascade delete |
| BC-DB-07 | quest_code | VARCHAR(50) | NOT NULL | | UNIQUE (uq_quest_code) | Auto-generated pattern: `QUEST_{S}_{C}_{SUB}_GEN_{RANDOM6}` |
| BC-DB-08 | title | VARCHAR(255) | NOT NULL | | | Required, max 255 chars |
| BC-DB-09 | description | TEXT | NULLABLE | NULL | | Optional |
| BC-DB-10 | instructions | TEXT | NULLABLE | NULL | | Optional |
| BC-DB-11 | status | VARCHAR(20) | NOT NULL | 'DRAFT' | | Allowed: DRAFT, PUBLISHED, ARCHIVED |
| BC-DB-12 | duration_minutes | INT UNSIGNED | NULLABLE | NULL | | Min 1, Max 300 |
| BC-DB-13 | total_marks | DECIMAL(8,2) | NOT NULL | 0.00 | | Min 0 |
| BC-DB-14 | total_questions | INT UNSIGNED | NOT NULL | 0 | | Min 0 |
| BC-DB-15 | passing_percentage | DECIMAL(5,2) | NOT NULL | 33.00 | | 0–100 |
| BC-DB-16 | allow_multiple_attempts | TINYINT(1) | NOT NULL | 0 | | Boolean |
| BC-DB-17 | max_attempts | TINYINT UNSIGNED | NOT NULL | 1 | | 1–10; required if allow_multiple_attempts=true |
| BC-DB-18 | negative_marks | DECIMAL(4,2) | NOT NULL | 0.00 | | 0–99.99 |
| BC-DB-19 | is_randomized | TINYINT(1) | NOT NULL | 0 | | Boolean |
| BC-DB-20 | question_marks_shown | TINYINT(1) | NOT NULL | 0 | | Boolean |
| BC-DB-21 | auto_publish_result | TINYINT(1) | NOT NULL | 0 | | Boolean |
| BC-DB-22 | timer_enforced | TINYINT(1) | NOT NULL | 1 | | Boolean |
| BC-DB-23 | show_correct_answer | TINYINT(1) | NOT NULL | 0 | | Boolean |
| BC-DB-24 | show_explanation | TINYINT(1) | NOT NULL | 0 | | Boolean |
| BC-DB-25 | difficulty_config_id | INT UNSIGNED | NULLABLE | NULL | FK → lms_difficulty_distribution_configs.id | SET NULL on delete |
| BC-DB-26 | ignore_difficulty_config | TINYINT(1) | NOT NULL | 0 | | Boolean |
| BC-DB-27 | is_system_generated | TINYINT(1) | NOT NULL | 0 | | Boolean |
| BC-DB-28 | only_unused_questions | TINYINT(1) | NOT NULL | 0 | | Boolean |
| BC-DB-29 | only_authorised_questions | TINYINT(1) | NOT NULL | 0 | | Boolean |
| BC-DB-30 | created_by | INT UNSIGNED | NULLABLE | NULL | FK → sys_users.id | SET NULL on delete; auto-set from auth |
| BC-DB-31 | is_active | TINYINT(1) | NOT NULL | 1 | | Boolean |
| BC-DB-32 | created_at | TIMESTAMP | NULL | CURRENT_TIMESTAMP | | |
| BC-DB-33 | updated_at | TIMESTAMP | NULL | ON UPDATE CURRENT_TIMESTAMP | | |
| BC-DB-34 | deleted_at | TIMESTAMP | NULLABLE | NULL | | Soft delete marker |

Unique keys: `uq_quest_uuid` (uuid), `uq_quest_code` (quest_code).

---

## 5. Validation Rules (BC-VAL)

### 5.1 Create Validation — BC-VAL-C

Source: `Modules\LmsQuests\Http\Requests\QuestRequest::rules()` (create context)

| BC-VAL-C ID | Field | Rule(s) | Error Message (Expected) |
|-------------|-------|---------|--------------------------|
| BC-VAL-C-01 | title | required, string, max:255 | The title field is required. / title must not exceed 255 characters. |
| BC-VAL-C-02 | description | nullable, string | |
| BC-VAL-C-03 | academic_session_id | required, integer | The academic session id field is required. |
| BC-VAL-C-04 | class_id | required, integer | The class id field is required. |
| BC-VAL-C-05 | subject_id | required, integer | The subject id field is required. |
| BC-VAL-C-06 | quest_code | nullable, string | |
| BC-VAL-C-07 | instructions | nullable, string | |
| BC-VAL-C-08 | quest_type_id | required, exists:lms_assessment_types,id | The selected quest type id is invalid. |
| BC-VAL-C-09 | status | required, in:DRAFT,PUBLISHED,ARCHIVED | The selected status is invalid. |
| BC-VAL-C-10 | duration_minutes | nullable, integer, min:1, max:300 | duration_minutes must be at least 1. / must not exceed 300. |
| BC-VAL-C-11 | total_marks | required, numeric, min:0 | The total marks field is required. |
| BC-VAL-C-12 | total_questions | required, integer, min:0 | The total questions field is required. |
| BC-VAL-C-13 | passing_percentage | required, numeric, min:0, max:100 | passing_percentage must be between 0 and 100. |
| BC-VAL-C-14 | allow_multiple_attempts | boolean | |
| BC-VAL-C-15 | max_attempts | required_if:allow_multiple_attempts,true, integer, min:1, max:10 | max_attempts is required when allow multiple attempts is enabled. / min 1 / max 10 |
| BC-VAL-C-16 | negative_marks | required, numeric, min:0, max:99.99 | negative_marks must be at least 0. / must not exceed 99.99. |
| BC-VAL-C-17 | is_randomized | boolean | |
| BC-VAL-C-18 | question_marks_shown | boolean | |
| BC-VAL-C-19 | auto_publish_result | boolean | |
| BC-VAL-C-20 | timer_enforced | boolean | |
| BC-VAL-C-21 | show_correct_answer | boolean | |
| BC-VAL-C-22 | show_explanation | boolean | |
| BC-VAL-C-23 | difficulty_config_id | nullable, exists:lms_difficulty_distribution_configs,id | The selected difficulty config id is invalid. |
| BC-VAL-C-24 | ignore_difficulty_config | boolean | |
| BC-VAL-C-25 | only_unused_questions | boolean | |
| BC-VAL-C-26 | only_authorised_questions | boolean | |
| BC-VAL-C-27 | is_system_generated | boolean | |
| BC-VAL-C-28 | is_active | boolean | |

### 5.2 Update Validation — BC-VAL-U

Source: `Modules\LmsQuests\Http\Requests\QuestRequest::rules()` (update context, same rules as create)

| BC-VAL-U ID | Field | Rule(s) | Diff from Create |
|-------------|-------|---------|------------------|
| BC-VAL-U-01 | title | required, string, max:255 | Same |
| BC-VAL-U-02 | description | nullable, string | Same |
| BC-VAL-U-03 | academic_session_id | required, integer | Same |
| BC-VAL-U-04 | class_id | required, integer | Same |
| BC-VAL-U-05 | subject_id | required, integer | Same |
| BC-VAL-U-06 | quest_code | nullable, string | Same (model `updating()` boot event handles uniqueness at model layer) |
| BC-VAL-U-07 | instructions | nullable, string | Same |
| BC-VAL-U-08 | quest_type_id | required, exists:lms_assessment_types,id | Same |
| BC-VAL-U-09 | status | required, in:DRAFT,PUBLISHED,ARCHIVED | Same |
| BC-VAL-U-10 | duration_minutes | nullable, integer, min:1, max:300 | Same |
| BC-VAL-U-11 | total_marks | required, numeric, min:0 | Same |
| BC-VAL-U-12 | total_questions | required, integer, min:0 | Same |
| BC-VAL-U-13 | passing_percentage | required, numeric, min:0, max:100 | Same |
| BC-VAL-U-14 | allow_multiple_attempts | boolean | Same |
| BC-VAL-U-15 | max_attempts | required_if:allow_multiple_attempts,true, integer, min:1, max:10 | Same |
| BC-VAL-U-16 | negative_marks | required, numeric, min:0, max:99.99 | Same |
| BC-VAL-U-17 | is_randomized | boolean | Same |
| BC-VAL-U-18 | question_marks_shown | boolean | Same |
| BC-VAL-U-19 | auto_publish_result | boolean | Same |
| BC-VAL-U-20 | timer_enforced | boolean | Same |
| BC-VAL-U-21 | show_correct_answer | boolean | Same |
| BC-VAL-U-22 | show_explanation | boolean | Same |
| BC-VAL-U-23 | difficulty_config_id | nullable, exists:lms_difficulty_distribution_configs,id | Same |
| BC-VAL-U-24 | ignore_difficulty_config | boolean | Same |
| BC-VAL-U-25 | only_unused_questions | boolean | Same |
| BC-VAL-U-26 | only_authorised_questions | boolean | Same |
| BC-VAL-U-27 | is_system_generated | boolean | Same |
| BC-VAL-U-28 | is_active | boolean | Same |

### 5.3 Boolean Conversion (prepareForValidation)

Source: `QuestRequest::prepareForValidation()`

All 12 boolean fields (`allow_multiple_attempts`, `is_randomized`, `question_marks_shown`, `auto_publish_result`, `timer_enforced`, `show_correct_answer`, `show_explanation`, `ignore_difficulty_config`, `only_unused_questions`, `only_authorised_questions`, `is_system_generated`, `is_active`) are converted via `$this->boolean()` before validation rules execute.

### 5.4 Authorization in Request

Source: `QuestRequest::authorize()` — returns `true` unconditionally. Permission enforcement is delegated to controller-level `Gate::authorize()` calls (see BC-AUTH).

---

## 6. Authorization (BC-AUTH)

### 6.1 Policy Gates

Source: `Modules\LmsQuests\Policies\QuestPolicy`

| BC-AUTH ID | Gate Name | Policy Method | Permission String | Scope |
|------------|-----------|---------------|-------------------|-------|
| BC-AUTH-01 | viewAny | `viewAny(User $user): bool` | `tenant.quest.viewAny` | List/all quests |
| BC-AUTH-02 | view | `view(User $user, Quest $quest): bool` | `tenant.quest.view` | Single quest show |
| BC-AUTH-03 | create | `create(User $user): bool` | `tenant.quest.create` | Create new quest |
| BC-AUTH-04 | update | `update(User $user, Quest $quest): bool` | `tenant.quest.update` | Edit/update/toggle |
| BC-AUTH-05 | delete | `delete(User $user, Quest $quest): bool` | `tenant.quest.delete` | Soft delete |
| BC-AUTH-06 | restore | `restore(User $user, Quest $quest): bool` | `tenant.quest.restore` | Restore from trash |
| BC-AUTH-07 | forceDelete | `forceDelete(User $user, Quest $quest): bool` | `tenant.quest.forceDelete` | Permanent delete |
| BC-AUTH-08 | status | `status(User $user, Quest $quest): bool` | `tenant.quest.status` | Toggle active status |
| BC-AUTH-09 | duplicate | `duplicate(User $user, Quest $quest): bool` | `tenant.quest.duplicate` | Duplicate quest |
| BC-AUTH-10 | publish | `publish(User $user, Quest $quest): bool` | `tenant.quest.publish` | Publish quest |
| BC-AUTH-11 | archive | `archive(User $user, Quest $quest): bool` | `tenant.quest.archive` | Archive quest |
| BC-AUTH-12 | manageQuestions | `manageQuestions(User $user, Quest $quest): bool` | `tenant.quest.manageQuestions` | Manage quest questions |
| BC-AUTH-13 | manageAllocations | `manageAllocations(User $user, Quest $quest): bool` | `tenant.quest.manageAllocations` | Manage quest allocations |

### 6.2 Blade View Permission Checks

| BC-AUTH ID | View File | Directive | Permission | Purpose |
|------------|-----------|-----------|------------|---------|
| BC-AUTH-V-01 | `quest/index.blade.php:44` | `@can('tenant.quest.status')` | tenant.quest.status | Shows Active toggle column header |
| BC-AUTH-V-02 | `quest/index.blade.php:47` | `@canany(['tenant.quest.view', 'tenant.quest.update', 'tenant.quest.delete'])` | view/update/delete | Shows Actions column header |
| BC-AUTH-V-03 | `quest/index.blade.php:67` | `@can('tenant.quest.status')` | tenant.quest.status | Shows status switch per row |
| BC-AUTH-V-04 | `quest/index.blade.php:76` | `@canany(['tenant.quest.view', 'tenant.quest.update', 'tenant.quest.delete'])` | view/update/delete | Shows action buttons per row |
| BC-AUTH-V-05 | `quest/show.blade.php:24` | `@can('tenant.quest.update')` | tenant.quest.update | Shows Edit button |
| BC-AUTH-V-06 | `tab_module/tab.blade.php:28-54` | `@can('tenant.quest.*')` | Multiple | Shows tab navigation items |

---

## 7. Business Logic (BC-BIZ)

### 7.1 Business Rules

| BC-BIZ ID | Rule | Description | Enforcement Point |
|-----------|------|-------------|-------------------|
| BC-BIZ-01 | Quest Code Auto-Generation | If quest_code empty, generate `QUEST_{SESSION}_{CLASS}_{SUBJECT}_GEN_{RANDOM6}`; null codes → `GEN`; uniqueness loop appends `_1`, `_2` | Model `generateQuestCode()` + boot `creating()` |
| BC-BIZ-02 | Quest Code Uniqueness on Update | If quest_code changed, check uniqueness excluding self; if duplicate, append random 4-char suffix | Model boot `updating()` |
| BC-BIZ-03 | 2-Tab Wizard Flow | Tab 1 (Basic Info) → Tab 2 (Configuration); Tab 1 must be valid before proceeding | Front-end UI flow + validation |
| BC-BIZ-04 | Toggle: Multiple Attempts | `allow_multiple_attempts` OFF → `max_attempts` forced to 1; ON → `max_attempts` required (1–10) | QuestRequest VR-15 `required_if` |
| BC-BIZ-05 | Toggle: Timer Enforced | `timer_enforced` ON → `duration_minutes` required (1–300); OFF → duration optional | QuestRequest VR-10 + model `validateSettings()` |
| BC-BIZ-06 | Toggle: Ignore Difficulty Config | `ignore_difficulty_config` ON → difficulty_config dropdown disabled/cleared on front-end | Front-end UI + stored flag |
| BC-BIZ-07 | Draft by Default | New Quest starts with status 'DRAFT'; `created_by` auto-set from auth | Model boot `creating()` |
| BC-BIZ-08 | Publish Readiness | Publish allowed only when: questions added, count matches `total_questions`, context complete (session/class/subject set), settings valid | Model `canPublish()` |
| BC-BIZ-09 | Archive Deactivates | Archiving sets `status='ARCHIVED'` and `is_active=false` | Model `archive()` |
| BC-BIZ-10 | Duplicate Creates Draft Copy | Duplicate creates new Draft with new code, "(Copy)" title, cloned scopes/questions, fresh timestamps | Model `duplicate()` |
| BC-BIZ-11 | Usage Lock | Quests with allocations or student attempts cannot be edited, deleted, restored, or force-deleted | Controller via `QuestUsageCheckService` |
| BC-BIZ-12 | Soft Delete = Deactivate + Archive | Soft delete sets `is_active=false`, `status='ARCHIVED'`, then `deleted_at` timestamp | Controller `destroy()` |
| BC-BIZ-13 | Force Delete Cascade | Force delete permanently removes quest + allocations + questions + scopes in DB transaction | Controller `forceDelete()` with `DB::transaction` |
| BC-BIZ-14 | Status Transitions | DRAFT ↔ PUBLISHED ↔ ARCHIVED ↔ DRAFT; soft delete forces ARCHIVED | Model + Controller |
| BC-BIZ-15 | UUID Auto-Generation | 16-byte binary UUID generated via `Str::uuid()->getBytes()` if empty on create | Model boot `creating()` |
| BC-BIZ-16 | Activity Logging | Every action (Stored, Updated, Trashed, Restored, Deleted, Toggled) creates activity log entry | Controller after each action |

### 7.2 Model Accessors & Computed Attributes

| BC-BIZ ID | Accessor | Logic | Return Type |
|-----------|----------|-------|-------------|
| BC-BIZ-ACC-01 | `academic_hierarchy` | Array: [academic_session, class, subject] | array |
| BC-BIZ-ACC-02 | `academic_hierarchy_string` | String: "Session > Class > Subject" | string |
| BC-BIZ-ACC-03 | `marks_per_question` | `total_marks / total_questions` (if > 0) | float |
| BC-BIZ-ACC-04 | `passing_marks` | `(passing_percentage / 100) × total_marks` | float |
| BC-BIZ-ACC-05 | `is_published` | `status === 'PUBLISHED'` | bool |
| BC-BIZ-ACC-06 | `is_draft` | `status === 'DRAFT'` | bool |
| BC-BIZ-ACC-07 | `is_archived` | `status === 'ARCHIVED'` | bool |
| BC-BIZ-ACC-08 | `has_timer` | `timer_enforced && duration_minutes > 0` | bool |
| BC-BIZ-ACC-09 | `duration_seconds` | `duration_minutes × 60` | int |
| BC-BIZ-ACC-10 | `duration_formatted` | Hours:minutes or minutes format | string |
| BC-BIZ-ACC-11 | `statistics` | questions count, marks, passing_marks, duration, max_attempts, timer, randomization, allocations count, question types breakdown | array |
| BC-BIZ-ACC-12 | `summary` | Full summary array with code, title, status, hierarchy, duration, counts | array |

### 7.3 Model Scopes

| BC-BIZ ID | Scope | Logic |
|-----------|-------|-------|
| BC-BIZ-SCP-01 | `active` | `where('is_active', true)` |
| BC-BIZ-SCP-02 | `published` | `where('status', 'PUBLISHED')` |
| BC-BIZ-SCP-03 | `draft` | `where('status', 'DRAFT')` |
| BC-BIZ-SCP-04 | `archived` | `where('status', 'ARCHIVED')` |
| BC-BIZ-SCP-05 | `systemGenerated` | `where('is_system_generated', true)` |
| BC-BIZ-SCP-06 | `manual` | `where('is_system_generated', false)` |
| BC-BIZ-SCP-07 | `byAcademicSession` | `where('academic_session_id', $sessionId)` |
| BC-BIZ-SCP-08 | `byClass` | `where('class_id', $classId)` |
| BC-BIZ-SCP-09 | `bySubject` | `where('subject_id', $subjectId)` |
| BC-BIZ-SCP-10 | `byAssessmentType` | `where('quest_type_id', $typeId)` |
| BC-BIZ-SCP-11 | `byCreator` | `where('created_by', $creatorId)` |
| BC-BIZ-SCP-12 | `search` | Search quest_code, title, description, instructions, class name, subject name |
| BC-BIZ-SCP-13 | `dateRange` | Between start/end dates on created_at |

### 7.4 Model Boot Events

| BC-BIZ ID | Event | Behavior |
|-----------|-------|----------|
| BC-BIZ-BOOT-01 | `creating()` | Sets uuid (if empty), quest_code (if empty), created_by (if empty and auth) |
| BC-BIZ-BOOT-02 | `updating()` | If quest_code changed, checks uniqueness and appends random 4-char suffix if duplicate |

### 7.5 Quest Code Generation Pattern

Pattern: `QUEST_{SESSION_CODE}_{CLASS_CODE}_{SUBJECT_CODE}_GEN_{RANDOM6}`
- If AcademicSession code is null → `GEN`
- If SchoolClass code is null → `GEN`
- If Subject code is null → `GEN`
- Random 6 uppercase alphanumeric characters
- Uniqueness loop: if code exists, appends `_1`, `_2`, etc.

---

## 8. Referential Integrity (BC-REF)

### Foreign Keys on `lms_quests`

Source: `LMS_Quest_DDL_v2.sql`

| BC-REF ID | FK Name | Column | Referenced Table | Referenced Column | On Delete | Notes |
|-----------|---------|--------|------------------|-------------------|-----------|-------|
| BC-REF-01 | `fk_quest_academic_session` | `academic_session_id` | `glb_academic_sessions` | `id` | CASCADE | Required |
| BC-REF-02 | `fk_quest_class` | `class_id` | `sch_classes` | `id` | CASCADE | Required |
| BC-REF-03 | `fk_quest_subject` | `subject_id` | `sch_subjects` | `id` | CASCADE | Required |
| BC-REF-04 | `fk_quest_type` | `quest_type_id` | `lms_assessment_types` | `id` | CASCADE | Required |
| BC-REF-05 | `fk_quest_diff` | `difficulty_config_id` | `lms_difficulty_distribution_configs` | `id` | SET NULL | Optional |
| BC-REF-06 | `fk_quest_creator` | `created_by` | `sys_users` | `id` | SET NULL | Optional |

### Foreign Keys on Child Tables (Referencing `lms_quests`)

| BC-REF ID | Child Table | FK Name | Foreign Key Column | On Delete | Notes |
|-----------|-------------|---------|--------------------|-----------|-------|
| BC-REF-07 | `lms_quest_scopes` | `fk_qs_quest` | `quest_id` | CASCADE | Force delete cascade |
| BC-REF-08 | `lms_quest_questions` | `fk_qst_q_quest` | `quest_id` | CASCADE | Force delete cascade |
| BC-REF-09 | `lms_quest_allocations` | `fk_qsta_quest` | `quest_id` | CASCADE | Force delete cascade |

### Unique Keys

| BC-REF ID | Constraint Name | Column(s) | Purpose |
|-----------|-----------------|-----------|---------|
| BC-REF-10 | `uq_quest_uuid` | `uuid` | UUID uniqueness |
| BC-REF-11 | `uq_quest_code` | `quest_code` | Quest code uniqueness |

---

## 9. Test Case Summary

### 9.1 Positive TC Summary

| TC ID | Test Case Name | Type | Area | Priority |
|-------|---------------|------|------|----------|
| TC-P01 | Create — Minimal Quest with all required fields (Draft) | Functional | Creation | High |
| TC-P02 | Create — Quest with full configuration (all fields populated) | Functional | Creation | High |
| TC-P03 | Create — Auto code generation with code uniqueness | Functional | Creation | High |
| TC-P04 | Create — Toggle interdependencies (Allow Multiple Attempts) | Functional | Creation | Medium |
| TC-P05 | Create — Toggle interdependencies (Timer Enforced) | Functional | Creation | Medium |
| TC-P06 | Create — Toggle interdependencies (Ignore Difficulty Config) | Functional | Creation | Medium |
| TC-P07 | Create — All 12 toggle switches default values | Functional | Creation | Medium |
| TC-P08 | Create — Quest with Description and Instructions | Functional | Creation | Low |
| TC-P09 | Create — Quest with zero total_marks and total_questions | Edge Case | Creation | Medium |
| TC-P10 | Create — Quest with max allowed values | Edge Case | Creation | Medium |
| TC-P11 | Show — View quest details | Functional | View | High |
| TC-P12 | Edit — Update title and academic context | Functional | Edit | High |
| TC-P13 | Edit — Update configuration fields | Functional | Edit | High |
| TC-P14 | Edit — Change quest_code manually | Functional | Edit | Medium |
| TC-P15 | Edit — Quest code auto-uniqueness on update | Functional | Edit | Medium |
| TC-P16 | Publish — Successful publish when ready | Functional | Lifecycle | High |
| TC-P17 | Publish — canPublish() readiness check passes | Functional | Lifecycle | High |
| TC-P18 | Archive — Successful archive | Functional | Lifecycle | High |
| TC-P19 | Status transition: DRAFT → PUBLISHED → ARCHIVED → DRAFT | Functional | Lifecycle | Medium |
| TC-P20 | Duplicate — Create exact copy via model duplicate() | Functional | Duplication | High |
| TC-P21 | Duplicate — With overrides | Functional | Duplication | Medium |
| TC-P22 | Duplicate — Quest without scopes or questions | Functional | Duplication | Low |
| TC-P23 | Destroy — Soft delete unused quest | Functional | Soft Delete | High |
| TC-P24 | Trashed — View trash listing | Functional | Trash | Medium |
| TC-P25 | Restore — Restore soft-deleted quest (admin only) | Functional | Restore | High |
| TC-P26 | Force Delete — Permanently delete unused quest | Functional | Force Delete | High |
| TC-P27 | Toggle Status — Activate/Deactivate quest (AJAX) | Functional | Status | High |
| TC-P28 | Toggle Status — inactive quest hidden from active lists | Functional | Status | Medium |
| TC-P29 | AJAX — Get subjects by class | Functional | Cascade | Medium |

### 9.2 Negative TC Summary

| TC ID | Test Case Name | Type | Area | Priority |
|-------|---------------|------|------|----------|
| TC-N01 | Create — Missing required fields | Validation | Creation | High |
| TC-N02 | Create — Invalid status value | Validation | Creation | Medium |
| TC-N03 | Create — Passing percentage out of range | Validation | Creation | Medium |
| TC-N04 | Create — Negative total marks or total questions | Validation | Creation | Medium |
| TC-N05 | Create — Duration out of range | Validation | Creation | Medium |
| TC-N06 | Create — Negative marks out of range | Validation | Creation | Medium |
| TC-N07 | Create — Max attempts required when multiple allowed | Validation | Creation | Medium |
| TC-N08 | Create — Invalid quest_type_id (non-existent) | Validation | Creation | Medium |
| TC-N09 | Create — Invalid difficulty_config_id (non-existent) | Validation | Creation | Medium |
| TC-N10 | Create — Title exceeds max length | Validation | Creation | Medium |
| TC-N11 | Edit — Quest with allocations (blocked) | Usage Guard | Edit | High |
| TC-N12 | Edit — Quest with student attempts (blocked) | Usage Guard | Edit | High |
| TC-N13 | Update — Quest with allocations via PUT (blocked) | Usage Guard | Update | High |
| TC-N14 | Destroy — Quest with allocations (blocked) | Usage Guard | Delete | High |
| TC-N15 | Destroy — Quest with questions (blocked) | Usage Guard | Delete | Medium |
| TC-N16 | Destroy — Quest with student attempts (blocked) | Usage Guard | Delete | High |
| TC-N17 | Restore — Quest with allocations (blocked) | Usage Guard | Restore | High |
| TC-N18 | Restore — Quest with student attempts (blocked) | Usage Guard | Restore | High |
| TC-N19 | Force Delete — Quest with allocations (blocked) | Usage Guard | Force Delete | High |
| TC-N20 | Force Delete — Quest with student attempts (blocked) | Usage Guard | Force Delete | High |
| TC-N21 | Create — Without permission | Auth | Permission | High |
| TC-N22 | Edit — Without permission | Auth | Permission | High |
| TC-N23 | Delete — Without permission | Auth | Permission | High |
| TC-N24 | View Trash — Without permission | Auth | Permission | High |
| TC-N25 | Force Delete — Without permission | Auth | Permission | High |
| TC-N26 | Toggle Status — Without permission | Auth | Permission | High |
| TC-N27 | Publish — No questions added | Readiness | Publish | Medium |
| TC-N28 | Publish — Question count mismatch | Readiness | Publish | Medium |
| TC-N29 | Publish — Incomplete academic context | Readiness | Publish | Medium |
| TC-N30 | Publish — Invalid settings (passing_percentage > 100) | Readiness | Publish | Low |
| TC-N31 | Publish — Timer enforced but duration = 0 | Readiness | Publish | Low |
| TC-N32 | Toggle Status — Invalid is_active value | Validation | Status | Low |
| TC-N33 | Duplicate — Questions with usage logs not copied | Edge Case | Duplication | Low |

### 9.3 Dependency TC Summary

| TC ID | Test Case Name | Type | Area | Priority |
|-------|---------------|------|------|----------|
| TC-D01 | Cascade — Force delete cascades to child records | Integration | Cascade | High |
| TC-D02 | Cascade — Soft delete does not cascade | Integration | Cascade | Medium |
| TC-D03 | Transaction — Force delete rolls back on failure | Integration | Transaction | Medium |
| TC-D04 | Business — Activity log entry created on every action | Business Rule | Activity Log | High |
| TC-D05 | Business — Quest becomes visible for allocation only when published | Business Rule | Lifecycle | High |
| TC-D06 | Business — Quest appears in status breakdown dashboard | Business Rule | Dashboard | Medium |
| TC-D07 | Business — Quest code auto-generation with null references | Business Rule | Code Gen | Medium |
| TC-D08 | Business — Quest marks_per_question accessor | Business Rule | Accessor | Low |

### 9.4 Code Review TC Summary

| TC ID | Test Case Name | Type | Area | Priority |
|-------|---------------|------|------|----------|
| TC-CR01 | Controller store() — Quest creation flow | Code Review | Controller | High |
| TC-CR02 | Controller store() — Duplicate code generation (Controller vs Model) | Code Review | Controller | Medium |
| TC-CR03 | Controller edit() — Usage check before edit | Code Review | Controller | High |
| TC-CR04 | Controller update() — Update with change tracking | Code Review | Controller | High |
| TC-CR05 | Controller destroy() — Soft delete with deactivation | Code Review | Controller | High |
| TC-CR06 | Controller trashed() — Trash listing | Code Review | Controller | Medium |
| TC-CR07 | Controller restore() — Restore with reactivation | Code Review | Controller | High |
| TC-CR08 | Controller forceDelete() — Permanent delete with cascade | Code Review | Controller | High |
| TC-CR09 | Controller toggleStatus() — AJAX status toggle | Code Review | Controller | High |
| TC-CR10 | Model Quest — boot() creating event | Code Review | Model | High |
| TC-CR11 | Model Quest — boot() updating event | Code Review | Model | High |
| TC-CR12 | Model Quest — generateQuestCode() uniqueness loop | Code Review | Model | High |
| TC-CR13 | Model Quest — canPublish() readiness check | Code Review | Model | High |
| TC-CR14 | Model Quest — validateSettings() validation | Code Review | Model | Medium |
| TC-CR15 | Model Quest — duplicate() method | Code Review | Model | High |
| TC-CR16 | Model Quest — SoftDeletes trait integration | Code Review | Model | Medium |
| TC-CR17 | Request QuestRequest — prepareForValidation() boolean conversion | Code Review | Request | Medium |
| TC-CR18 | Request QuestRequest — authorize() returns true unconditionally | Code Review | Request | High |
| TC-CR19 | QuestUsageCheckService — isUsed() logic | Code Review | Service | High |
| TC-CR20 | Policy QuestPolicy — Permission methods | Code Review | Policy | High |
| TC-CR21 | Blade @can Directives — Permission visibility for quest creation buttons | Code Review | View | Medium |
| TC-CR22 | Breadcrumb Config — Route registered in config/breadcrumb.php | Code Review | Config | Low |
| TC-CR23 | View — isset()/null-safe Checks for Relationship Variables | Code Review | View | Medium |
| TC-CR24 | View — Success Flash Messages After Create/Update/Delete | Code Review | View | Medium |

### 9.5 Total TC Count

| Category | Count |
|----------|-------|
| Positive (TC-P) | 29 |
| Negative (TC-N) | 33 |
| Dependency (TC-D) | 8 |
| Code Review (TC-CR) | 24 |
| **Total** | **94** |

---

## 10. API Details

| Method | URL | Name | Controller Method | Required Permission |
|--------|-----|------|-------------------|---------------------|
| GET | `/lms-quests/quest` | lms-quests.quest.index | index() | tenant.quest.viewAny |
| GET | `/lms-quests/quest/create` | lms-quests.quest.create | create() | tenant.quest.create |
| POST | `/lms-quests/quest` | lms-quests.quest.store | store() | tenant.quest.create |
| GET | `/lms-quests/quest/{quest}` | lms-quests.quest.show | show() | tenant.quest.view |
| GET | `/lms-quests/quest/{quest}/edit` | lms-quests.quest.edit | edit() | tenant.quest.update |
| PUT/PATCH | `/lms-quests/quest/{quest}` | lms-quests.quest.update | update() | tenant.quest.update |
| DELETE | `/lms-quests/quest/{quest}` | lms-quests.quest.destroy | destroy() | tenant.quest.delete |
| GET | `/lms-quests/quest/trash/view` | lms-quests.quest.trashed | trashed() | tenant.quest.restore |
| GET | `/lms-quests/quest/{id}/restore` | lms-quests.quest.restore | restore() | tenant.quest.restore |
| DELETE | `/lms-quests/quest/{id}/force-delete` | lms-quests.quest.forceDelete | forceDelete() | tenant.quest.forceDelete |
| POST | `/lms-quests/quest/{quest}/toggle-status` | lms-quests.quest.toggleStatus | toggleStatus() | tenant.quest.update |
| GET | `/lms-quests/quest/get-subjects-by-class` | lms-quests.quest.getSubjectsByClass | getSubjectsByClass() | (AJAX, authenticated) |
| GET | `/lms-quests/quest-summary` | lms-quests.quest.summary | questSummary() | tenant.quest.viewAny |
| GET | `/lms-quests/quest/report/{id}` | lms-quests.quest.report | report() | tenant.quest.viewAny |

---

## 11. Positive TC Steps

### 11.1 Quest Creation & Configuration (REQ-QST-001)

#### TC-P01: Create — Minimal Quest with all required fields (Draft)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to Quest → Add Quest | Create form loads with 2-tab wizard |
| 2 | Tab 1: Select Academic Session (current) | Session selected |
| 3 | Tab 1: Select Class (e.g., Class 10) | Class selected |
| 4 | Tab 1: Verify Subject dropdown loads via AJAX | Subjects filtered by class |
| 5 | Tab 1: Select Subject (e.g., Mathematics) | Subject selected |
| 6 | Tab 1: Select Quest Type (e.g., Practice) | Type selected |
| 7 | Tab 1: Enter Title = "Algebra Basics Test" | Title entered |
| 8 | Tab 1: Verify Status default = DRAFT | Status shows DRAFT |
| 9 | Tab 1: Optionally add Description and Instructions | Text entered |
| 10 | Tab 1: Leave quest_code blank | Empty (will be auto-generated) |
| 11 | Click "Next: Configuration" | Tab 2 loads |
| 12 | Tab 2: Set Total Marks = 100 | 100 entered |
| 13 | Tab 2: Set Total Questions = 20 | 20 entered |
| 14 | Tab 2: Set Passing Percentage = 40 | 40 entered |
| 15 | Tab 2: Leave Duration blank (unlimited) | Duration empty |
| 16 | Tab 2: Leave all 12 toggles at defaults | Defaults as per DDL |
| 17 | Tab 2: Leave Negative Marks = 0 | Default 0 |
| 18 | Tab 2: Leave difficulty config empty | Null |
| 19 | Click "Save" | POST store() |
| 20 | Verify redirect to Quest list with success message | `success = 'Quest created successfully'` |
| 21 | DB check: `lms_quests` | Record created |
| 22 | DB check: `quest_code` | Auto-generated: `QUEST_{SESSION}_{CLASS}_{SUBJECT}_GEN_{RANDOM6}` |
| 23 | DB check: `status` | 'DRAFT' |
| 24 | DB check: `is_active` | 1 (true) |
| 25 | DB check: `created_by` | Current authenticated user ID |
| 26 | DB check: `uuid` | 16-byte binary UUID set |
| 27 | DB check: `created_at` | Set to current timestamp |
| 28 | Verify activity log | `activityLog()` entry created with event 'Stored' |

---

#### TC-P02: Create — Quest with full configuration (all fields populated)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Quest with all basic fields as TC-P01 | Tab 1 complete |
| 2 | Tab 2: Set Duration = 60 minutes | Duration set |
| 3 | Tab 2: Set Total Marks = 50, Total Questions = 10 | Values set |
| 4 | Tab 2: Set Passing Percentage = 33 | Default |
| 5 | Tab 2: Set Negative Marks = 0.50 | Negative marking factor set |
| 6 | Tab 2: Set Max Attempts = 3 | Max attempts set |
| 7 | Tab 2: Toggle ON: `is_randomized`, `question_marks_shown`, `timer_enforced`, `show_correct_answer`, `show_explanation` | 5 toggles ON |
| 8 | Tab 2: Toggle OFF: `allow_multiple_attempts`, `auto_publish_result`, `ignore_difficulty_config`, `only_unused_questions`, `only_authorised_questions`, `is_system_generated` | 6 toggles OFF (is_active stays ON) |
| 9 | Tab 2: Select difficulty_config_id (e.g., STD_BALANCED) | Config selected |
| 10 | Click "Save" | Quest saved |
| 11 | DB check: All 22 columns populated correctly | All values match input |
| 12 | DB check: `max_attempts` = 1 (because allow_multiple_attempts is OFF → forced to 1) | max_attempts = 1 |

---

#### TC-P03: Create — Auto code generation with code uniqueness

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Quest Q1 (code: `QUEST_2425_10_MATH_GEN_A7B3C9`) | Q1 saved |
| 2 | Create Quest Q2 with same session/class/subject (code generated: `QUEST_2425_10_MATH_GEN_X2K4P6`) | Different random suffix |
| 3 | Manually create Quest Q3 with quest_code = `QUEST_2425_10_MATH_GEN_A7B3C9` (existing) | Model `creating()` boot event: uniqueness loop appends `_1` |
| 4 | DB check: Q3 quest_code = `QUEST_2425_10_MATH_GEN_A7B3C9_1` | Suffix appended |
| 5 | Create Q4 with same session code but different class | Different class code in quest_code |

---

#### TC-P04: Create — Toggle interdependencies (Allow Multiple Attempts)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Tab 2: Set `allow_multiple_attempts` = ON | max_attempts field enabled |
| 2 | Set max_attempts = 3 | Value accepted |
| 3 | Save | Quest saved with max_attempts = 3 |
| 4 | Edit: Set `allow_multiple_attempts` = OFF | max_attempts forced to 1 (BR-QST-004) |
| 5 | Save and DB check: max_attempts | 1 |

---

#### TC-P05: Create — Toggle interdependencies (Timer Enforced)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Tab 2: Set `timer_enforced` = ON | duration_minutes field enabled |
| 2 | Set duration_minutes = 30 | Value accepted |
| 3 | Save | Quest saved with timer_enforced=1, duration_minutes=30 |
| 4 | DB check: `has_timer` accessor | Returns true |
| 5 | Edit: Set `timer_enforced` = OFF | duration_minutes can be cleared/null |
| 6 | Save and DB check: duration_minutes | NULL or value preserved (front-end dependent) |

---

#### TC-P06: Create — Toggle interdependencies (Ignore Difficulty Config)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Tab 2: Select difficulty_config_id = D1 | Config selected |
| 2 | Toggle `ignore_difficulty_config` = ON | difficulty_config_id can be cleared on front-end |
| 3 | Save | DB: difficulty_config_id = D1, ignore_difficulty_config = 1 |
| 4 | Verify model `canPublish()` | Does not check difficulty (only validateSettings which ignores this) |

---

#### TC-P07: Create — All 12 toggle switches default values

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Quest with only required fields | Saved |
| 2 | DB check: `allow_multiple_attempts` | 0 |
| 3 | DB check: `is_randomized` | 0 |
| 4 | DB check: `question_marks_shown` | 0 |
| 5 | DB check: `auto_publish_result` | 0 |
| 6 | DB check: `timer_enforced` | 1 (DDL default) |
| 7 | DB check: `show_correct_answer` | 0 |
| 8 | DB check: `show_explanation` | 0 |
| 9 | DB check: `ignore_difficulty_config` | 0 |
| 10 | DB check: `only_unused_questions` | 0 |
| 11 | DB check: `only_authorised_questions` | 0 |
| 12 | DB check: `is_system_generated` | 0 |
| 13 | DB check: `is_active` | 1 |

---

#### TC-P08: Create — Quest with Description and Instructions

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Tab 1: Enter Description = "Test your algebra skills" | Description entered |
| 2 | Tab 1: Enter Instructions = "Read each question carefully" | Instructions entered |
| 3 | Save | Saved |
| 4 | DB check: description | "Test your algebra skills" |
| 5 | DB check: instructions | "Read each question carefully" |

---

#### TC-P09: Create — Quest with zero total_marks and total_questions

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Tab 2: Set Total Marks = 0, Total Questions = 0 | Zero values accepted (min:0) |
| 2 | Save | Quest saved |
| 3 | DB check: total_marks | 0.00 |
| 4 | DB check: total_questions | 0 |
| 5 | Verify `marks_per_question` accessor | Returns 0 (guarded division by zero) |

---

#### TC-P10: Create — Quest with max allowed values

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Tab 2: Set Duration = 300 (max) | Accepted |
| 2 | Tab 2: Set Total Marks = 999999.99 | Accepted |
| 3 | Tab 2: Set Total Questions = 9999 | Accepted |
| 4 | Tab 2: Set Passing Percentage = 100 | Accepted |
| 5 | Tab 2: Set Negative Marks = 99.99 | Accepted |
| 6 | Tab 2: Set Max Attempts = 10 (with allow_multiple_attempts = ON) | Accepted |
| 7 | Save | Quest saved with max boundary values |

---

### 11.2 Quest Show & View (REQ-QST-001)

#### TC-P11: Show — View quest details

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Quest Q1 with all configuration | Q1 exists |
| 2 | Navigate to show page: GET `/lms-quests/quest/{Q1}` | Show page loads |
| 3 | Verify quest basic info displayed | Title, code, status, hierarchy shown |
| 4 | Verify configuration settings displayed | Marks, questions, duration, toggles shown |
| 5 | If not used: usage section hidden | Empty usage section |

---

### 11.3 Quest Edit & Update (REQ-QST-001)

#### TC-P12: Edit — Update title and academic context

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Quest Q1 in Draft, no allocations/attempts | Q1 exists |
| 2 | Navigate to edit: GET `/lms-quests/quest/{Q1}/edit` | Edit form loads with pre-filled values |
| 3 | Change Title to "Updated Algebra Test" | Title changed |
| 4 | Change Subject | Subject changed |
| 5 | Submit (PUT) | Updated |
| 6 | DB check: title | "Updated Algebra Test" |
| 7 | DB check: subject_id | New subject ID |
| 8 | Verify activity log | event 'Updated' with changes logged |
| 9 | Verify `getChanges()` captured old/new values | Changed attributes array populated |

---

#### TC-P13: Edit — Update configuration fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Quest Q1 with total_marks=100, total_questions=20, passing=33 | Q1 exists |
| 2 | Edit: Change total_marks = 150, total_questions = 30, passing = 50 | Values changed |
| 3 | Edit: Toggle `is_randomized` = ON | Toggle changed |
| 4 | Submit | Updated |
| 5 | DB check: total_marks | 150.00 |
| 6 | DB check: total_questions | 30 |
| 7 | DB check: passing_percentage | 50.00 |
| 8 | DB check: is_randomized | 1 |

---

#### TC-P14: Edit — Change quest_code manually

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Quest Q1 with auto-generated code | code = "QUEST_..." |
| 2 | Edit: Set quest_code = "CUSTOM_CODE_001" | Code entered |
| 3 | Submit | Updated |
| 4 | DB check: quest_code | "CUSTOM_CODE_001" |
| 5 | Model `updating()` checks uniqueness | No duplicate, code saved as-is |

---

#### TC-P15: Edit — Quest code auto-uniqueness on update

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Q1 (code = "CODE_A"), Q2 (code = "CODE_B") | Both exist |
| 2 | Edit Q2: Change quest_code to "CODE_A" (exists on Q1) | Model `updating()` detects `isDirty('quest_code')` |
| 3 | Model appends random suffix: "CODE_A_X7K2" | Suffix added |
| 4 | DB check: Q2 quest_code | "CODE_A_X7K2" (different from Q1) |

---

### 11.4 Quest Publish & Lifecycle (REQ-QST-005)

#### TC-P16: Publish — Successful publish when ready

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Quest Q1 with total_questions=10, total_marks=50, status=DRAFT | Q1 in Draft |
| 2 | Add exactly 10 questions to Q1 (sum marks = 50) | Questions match quest config |
| 3 | Call `Quest::find(Q1)->publish()` | Returns true |
| 4 | DB check: status | 'PUBLISHED' |
| 5 | DB check: `is_published` accessor | Returns true |
| 6 | Quest now visible for allocation | Active list shows PUBLISHED |

---

#### TC-P17: Publish — canPublish() readiness check passes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Quest Q1 has: academic_session_id, class_id, subject_id set | Context complete |
| 2 | Q1 has: total_questions=5, exactly 5 questQuestions | Count matches |
| 3 | Q1 has: no validation errors from `validateSettings()` | Settings valid |
| 4 | Call `$quest->canPublish()` | Returns true |
| 5 | Call `$quest->publish()` | Returns true, status = PUBLISHED |

---

#### TC-P18: Archive — Successful archive

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Quest Q1 exists in PUBLISHED status | Q1 published |
| 2 | Call `$quest->archive()` | Returns true |
| 3 | DB check: status | 'ARCHIVED' |
| 4 | DB check: is_active | 0 (false) — BR-QST-028 |
| 5 | `is_archived` accessor | Returns true |

---

#### TC-P19: Status transition: DRAFT → PUBLISHED → ARCHIVED → DRAFT

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Q1 in DRAFT (ready for publish) | Draft |
| 2 | Update status to PUBLISHED (via edit form or model) | PUBLISHED |
| 3 | Update status to ARCHIVED | ARCHIVED |
| 4 | Update status back to DRAFT | DRAFT |

---

### 11.5 Quest Duplication (REQ-QST-006)

#### TC-P20: Duplicate — Create exact copy via model duplicate()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Quest Q1 with title="Physics Motion", status=DRAFT, all config set | Q1 exists |
| 2 | Add 3 scopes to Q1 (lesson+topic) | 3 scopes |
| 3 | Add 5 questions to Q1 | 5 questions |
| 4 | Call `$q1->duplicate()` | Returns new Quest Q2 |
| 5 | DB check: Q2 title | "Physics Motion (Copy)" |
| 6 | DB check: Q2 quest_code | New unique code (different from Q1) |
| 7 | DB check: Q2 status | 'DRAFT' |
| 8 | DB check: Q2 created_by | Current auth user ID |
| 9 | DB check: Q2 created_at | Fresh timestamp (not copied) |
| 10 | DB check: Q2 scopes count | 3 scopes (cloned, different quest_id) |
| 11 | DB check: Q2 questQuestions count | 5 questions (cloned, different quest_id) |
| 12 | Verify Q2 scopes have same lesson/topic/target_count | Data matches Q1 scopes |
| 13 | Verify Q2 questions have same ordinal/marks_override | Data matches Q1 questions |
| 14 | Verify Q1 still unchanged | Q1 retains original data |

---

#### TC-P21: Duplicate — With overrides

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Call `$q1->duplicate(['title' => 'Custom Title', 'total_marks' => 200])` | Overrides applied |
| 2 | DB check: Q2 title | "Custom Title" (not "Physics Motion (Copy)") |
| 3 | DB check: Q2 total_marks | 200.00 |

---

#### TC-P22: Duplicate — Quest without scopes or questions

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Q1 with only basic info (no scopes, no questions) | Q1 shell |
| 2 | Call `$q1->duplicate()` | Q2 created |
| 3 | DB check: Q2 scopes | 0 |
| 4 | DB check: Q2 questQuestions | 0 |

---

### 11.6 Soft Delete, Trash, Restore, Force Delete (REQ-QST-007)

#### TC-P23: Destroy — Soft delete unused quest

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Quest Q1 with no allocations, no questions, no attempts | Q1 unused |
| 2 | Click Delete on Q1 | DELETE `/lms-quests/quest/{Q1}` |
| 3 | Controller checks `QuestUsageCheckService::isUsed(Q1)` | Returns false |
| 4 | Quest is deactivated: `is_active = false, status = 'ARCHIVED'` | Pre-save |
| 5 | Quest is soft-deleted: `$quest->delete()` | deleted_at set |
| 6 | Verify redirect with success | `success = 'Quest trashed successfully'` |
| 7 | DB check: deleted_at | NOT NULL |
| 8 | DB check: is_active | 0 |
| 9 | DB check: status | 'ARCHIVED' |
| 10 | Verify activity log | event 'Trashed' with message |

---

#### TC-P24: Trashed — View trash listing

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete Q1, Q2 | Both in trash |
| 2 | Navigate to Trash: GET `/lms-quests/quest/trash/view` | Trash page loads |
| 3 | Verify Q1 and Q2 listed | Both shown |
| 4 | Verify only soft-deleted quests shown | Active quests not in list |
| 5 | DB check: query uses `Quest::onlyTrashed()` | Only trashed records |

---

#### TC-P25: Restore — Restore soft-deleted quest (admin only)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete Q1 (no allocations, no attempts) | Q1 in trash |
| 2 | Navigate to Trash | Q1 shown |
| 3 | Click Restore on Q1 | GET `/lms-quests/quest/{id}/restore` |
| 4 | Controller checks `tenant.quest.restore` permission | Gate passed |
| 5 | Controller checks `QuestUsageCheckService::isUsed(Q1)` | Returns false |
| 6 | `$quest->restore()` called | deleted_at = NULL |
| 7 | `is_active = true; $quest->save()` | Activated |
| 8 | Verify redirect with success | `success = 'Quest restored successfully'` |
| 9 | DB check: deleted_at | NULL |
| 10 | DB check: is_active | 1 |
| 11 | Verify activity log | event 'Restored' |

---

#### TC-P26: Force Delete — Permanently delete unused quest

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete Q1 (no allocations, no attempts, has 3 questions and 2 scopes) | Q1 in trash |
| 2 | Navigate to Trash | Q1 shown |
| 3 | Click Force Delete on Q1 | DELETE `/lms-quests/quest/{id}/force-delete` |
| 4 | Controller checks `tenant.quest.forceDelete` permission | Gate passed |
| 5 | Controller checks `hasAllocations(Q1)` = false, `hasAttempts(Q1)` = false | Guard passed |
| 6 | DB transaction begins: `allocations()->forceDelete()` | 0 records (none exist) |
| 7 | `questQuestions()->forceDelete()` | 3 quest questions force-deleted |
| 8 | `scopes()->forceDelete()` | 2 scopes force-deleted |
| 9 | `$quest->forceDelete()` | Quest permanently removed |
| 10 | DB commit | Transaction committed |
| 11 | DB check: Q1 withTrashed() | Record gone (permanently deleted) |
| 12 | DB check: scopes withTrashed() | All force-deleted |
| 13 | DB check: questQuestions withTrashed() | All force-deleted |
| 14 | Verify activity log | event 'Deleted' with cascade message |

---

### 11.7 Status Toggle (REQ-QST-008)

#### TC-P27: Toggle Status — Activate/Deactivate quest (AJAX)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Quest Q1 with is_active=1 | Q1 active |
| 2 | Send AJAX POST to toggleStatus: `is_active=0` | POST `/lms-quests/quest/{quest}/toggle-status` |
| 3 | Verify JSON response | `{"success": true, "is_active": false, "message": "Quest status updated."}` |
| 4 | DB check: is_active | 0 |
| 5 | Send AJAX POST to toggleStatus: `is_active=1` | Toggle back |
| 6 | Verify JSON response | `{"success": true, "is_active": true}` |
| 7 | DB check: is_active | 1 |
| 8 | Verify activity log | event 'Toggled' |

---

#### TC-P28: Toggle Status — inactive quest hidden from active lists

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Toggle Q1 is_active = 0 | Q1 inactive |
| 2 | Query with `Quest::active()` scope | Q1 excluded |
| 3 | Query with `Quest::where('is_active', 1)` | Q1 not returned |
| 4 | Toggle Q1 is_active = 1 | Q1 active again |
| 5 | Query with `Quest::active()` | Q1 included |

---

### 11.8 Cascade Filtering (AJAX) (REQ-QST-019)

#### TC-P29: AJAX — Get subjects by class

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select Class C1 (has subject group with subjects S1, S2) | Class selected |
| 2 | AJAX call: GET `/lms-quests/quest/get-subjects-by-class?class_section_id=X` | Call |
| 3 | Verify JSON response | `{"success": true, "subjects": [{id, name, code}, ...]}` |
| 4 | Verify only active subjects returned | `is_active = 1` filter applied |
| 5 | Verify subjects belong to class via SubjectGroup | Proper class→subject mapping |

---

## 12. Negative TC Steps

### 12.1 Quest Creation — Validation Failures

#### TC-N01: Create — Missing required fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit create form with all fields empty | Validation errors |
| 2 | Verify `title` error | "The title field is required." |
| 3 | Verify `academic_session_id` error | "The academic session id field is required." |
| 4 | Verify `class_id` error | "The class id field is required." |
| 5 | Verify `subject_id` error | "The subject id field is required." |
| 6 | Verify `quest_type_id` error | "The quest type id field is required." |
| 7 | Verify `status` error | "The status field is required." |
| 8 | Verify `total_marks` error | "The total marks field is required." |
| 9 | Verify `total_questions` error | "The total questions field is required." |
| 10 | Verify `passing_percentage` error | "The passing percentage field is required." |
| 11 | Verify `negative_marks` error | "The negative marks field is required." |
| 12 | DB check: no quest created | 0 new records |

---

#### TC-N02: Create — Invalid status value

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set status = "INVALID_STATUS" | Not in allowed list |
| 2 | Submit | Validation error: "The selected status is invalid." |
| 3 | Set status = "PUBLISHED" (without meeting canPublish) | Accepted (edit form bypass known gap) |

---

#### TC-N03: Create — Passing percentage out of range

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set passing_percentage = -1 | Min:0 validation |
| 2 | Submit | Validation error: "passing_percentage must be between 0 and 100." |
| 3 | Set passing_percentage = 101 | Max:100 validation |
| 4 | Submit | Validation error: "passing_percentage must be between 0 and 100." |

---

#### TC-N04: Create — Negative total marks or total questions

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set total_marks = -10 | Min:0 validation |
| 2 | Submit | Validation error: "total_marks must be at least 0." |
| 3 | Set total_questions = -5 | Min:0 validation |
| 4 | Submit | Validation error: "total_questions must be at least 0." |

---

#### TC-N05: Create — Duration out of range

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set duration_minutes = 0 | Min:1 validation |
| 2 | Submit (with timer_enforced = ON) | Validation error: "duration_minutes must be at least 1." |
| 3 | Set duration_minutes = 301 | Max:300 validation |
| 4 | Submit | Validation error: "duration_minutes must not exceed 300." |

---

#### TC-N06: Create — Negative marks out of range

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set negative_marks = -1 | Min:0 validation |
| 2 | Submit | Validation error: "negative_marks must be at least 0." |
| 3 | Set negative_marks = 100 | Max:99.99 validation |
| 4 | Submit | Validation error: "negative_marks must not exceed 99.99." |

---

#### TC-N07: Create — Max attempts required when multiple allowed

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set allow_multiple_attempts = ON, leave max_attempts empty | required_if validation |
| 2 | Submit | Validation error: "max_attempts is required when allow multiple attempts is enabled." |
| 3 | Set max_attempts = 0 | Min:1 validation |
| 4 | Submit | Validation error: "max_attempts must be at least 1." |
| 5 | Set max_attempts = 11 | Max:10 validation |
| 6 | Submit | Validation error: "max_attempts must not exceed 10." |

---

#### TC-N08: Create — Invalid quest_type_id (non-existent)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set quest_type_id = 99999 | Does not exist in lms_assessment_types |
| 2 | Submit | Validation error: "The selected quest type id is invalid." |

---

#### TC-N09: Create — Invalid difficulty_config_id (non-existent)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set difficulty_config_id = 99999 | Does not exist |
| 2 | Submit | Validation error: "The selected difficulty config id is invalid." |

---

#### TC-N10: Create — Title exceeds max length

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set title = string of 256 characters | Max:255 validation |
| 2 | Submit | Validation error: "title must not exceed 255 characters." |

---

### 12.2 Quest Edit — Blocked by Usage Guard

#### TC-N11: Edit — Quest with allocations (blocked)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Q1, create allocation for Q1 | Allocation exists |
| 2 | Navigate to edit: GET `/lms-quests/quest/{Q1}/edit` | Controller checks `isUsed(Q1)` = true |
| 3 | Redirect back with error | "Cannot edit this quest because it is used in allocations, questions, or has student attempts." |
| 4 | DB check: quest unchanged | No updates |

---

#### TC-N12: Edit — Quest with student attempts (blocked)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Q1, create allocation, create student attempt via QuizQuestAttempt | Attempt exists |
| 2 | Navigate to edit page | Redirected with error |
| 3 | DB check: no changes | Original data preserved |

---

#### TC-N13: Update — Quest with allocations via PUT (blocked)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Q1 has allocations | In use |
| 2 | Send PUT request to update Q1 | Controller `update()` checks `isUsed()` = true |
| 3 | Redirect back with error | "Cannot update this quest because it is used..." |
| 4 | DB check: no changes | Original data preserved |

---

### 12.3 Quest Delete — Blocked by Usage Guard

#### TC-N14: Destroy — Quest with allocations (blocked)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Q1 has allocations | In use |
| 2 | Send DELETE request | Controller `destroy()` checks `isUsed()` = true |
| 3 | Redirect back with error | "Cannot delete this quest because it is used in allocations, questions, or has student attempts." |
| 4 | DB check: deleted_at | NULL (not deleted) |

---

#### TC-N15: Destroy — Quest with questions (blocked)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Q1 has questions added | QuestQuestions exist |
| 2 | Send DELETE request | Blocked by usage check |
| 3 | Verify error message | Usage guard blocks |

---

#### TC-N16: Destroy — Quest with student attempts (blocked)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Q1 has student attempts via QuizQuestAttempt | Attempts exist |
| 2 | Send DELETE request | Blocked |
| 3 | DB check: deleted_at | NULL |

---

### 12.4 Quest Restore — Blocked by Usage Guard

#### TC-N17: Restore — Quest with allocations (blocked)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete Q1 that has allocations | Q1 in trash, still has allocations |
| 2 | Navigate to Trash, click Restore | Controller checks `isUsed()` = true |
| 3 | Redirect back with error | "Cannot restore this quest because it has allocations, questions, or student attempts." |
| 4 | DB check: deleted_at | NOT NULL (still trashed) |

---

#### TC-N18: Restore — Quest with student attempts (blocked)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete Q1 that has student attempts | Q1 in trash |
| 2 | Click Restore | Blocked by usage check |
| 3 | Verify error message | Guard message shown |

---

### 12.5 Force Delete — Blocked by Usage Guard

#### TC-N19: Force Delete — Quest with allocations (blocked)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete Q1 that has allocations | Q1 in trash |
| 2 | Click Force Delete | Controller `forceDelete()` checks `hasAllocations()` = true |
| 3 | Redirect back with error | "Cannot permanently delete this quest because it has allocations or student attempts." |
| 4 | DB check: Q1 withTrashed() | Still exists |
| 5 | DB check: allocations | Still exist |

---

#### TC-N20: Force Delete — Quest with student attempts (blocked)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete Q1 that has student attempts | Q1 in trash |
| 2 | Click Force Delete | Controller checks `hasAttempts()` = true |
| 3 | Redirect with error | "Cannot permanently delete this quest because it has allocations or student attempts." |
| 4 | DB check: Q1 still exists | Force delete blocked |

---

### 12.6 Permission Gates

#### TC-N21: Create — Without permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user WITHOUT `tenant.quest.create` | Authenticated |
| 2 | Navigate to create page | 403 Forbidden |
| 3 | Send POST store directly | 403 Forbidden |

---

#### TC-N22: Edit — Without permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user WITHOUT `tenant.quest.update` | Authenticated |
| 2 | Navigate to edit page directly | 403 Forbidden |
| 3 | Send PUT update directly | 403 Forbidden |

---

#### TC-N23: Delete — Without permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user WITHOUT `tenant.quest.delete` | Authenticated |
| 2 | Send DELETE directly | 403 Forbidden |

---

#### TC-N24: View Trash — Without permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user WITHOUT `tenant.quest.restore` | Authenticated |
| 2 | Navigate to Trash page | 403 Forbidden |

---

#### TC-N25: Force Delete — Without permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user WITHOUT `tenant.quest.forceDelete` | Authenticated |
| 2 | Send DELETE forceDelete directly | 403 Forbidden |

---

#### TC-N26: Toggle Status — Without permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user WITHOUT `tenant.quest.update` | Authenticated |
| 2 | Send AJAX POST to toggleStatus | 403 Forbidden |

---

### 12.7 Publish — Readiness Check Failures

#### TC-N27: Publish — No questions added

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Q1 with all settings valid but 0 questions | Q1 in Draft |
| 2 | Call `$quest->canPublish()` | Returns false |
| 3 | Call `$quest->publish()` | Returns false |
| 4 | DB check: status | Still 'DRAFT' |

---

#### TC-N28: Publish — Question count mismatch

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Q1 with total_questions=10, but only 7 questions added | Count mismatch |
| 2 | Call `canPublish()` | Returns false (questQuestions count 7 !== 10) |

---

#### TC-N29: Publish — Incomplete academic context

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Q1 missing academic_session_id or class_id or subject_id | Incomplete |
| 2 | Call `canPublish()` | Returns false |

---

#### TC-N30: Publish — Invalid settings (passing_percentage > 100)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Q1 with passing_percentage = 110 | Invalid (but min/max enforced by request) |
| 2 | Manually set via model: `$quest->passing_percentage = 110; $quest->save()` | Bypasses request validation |
| 3 | Call `validateSettings()` | Returns error: "Passing percentage must be between 0 and 100." |
| 4 | Call `canPublish()` | Returns false |

---

#### TC-N31: Publish — Timer enforced but duration = 0

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Q1 with timer_enforced=1, duration_minutes=0 | Invalid state (request blocks this but test via model) |
| 2 | Call `validateSettings()` | Returns error: "Duration must be at least 1 minute when timer is enforced." |
| 3 | Call `canPublish()` | Returns false |

---

### 12.8 Toggle Status — Invalid Input

#### TC-N32: Toggle Status — Invalid is_active value

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send AJAX POST to toggleStatus with `is_active="invalid"` | Validation error: "The is active field must be true or false." |
| 2 | Send AJAX POST without is_active field | Validation error: "The is active field is required." |

---

### 12.9 Duplication — Edge Cases

#### TC-N33: Duplicate — Quest with questions already having usage logs

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Q1 has 5 questions with usage log entries | Usage logs exist |
| 2 | Call `$q1->duplicate()` | Q2 created |
| 3 | DB check: Q2 questions have no usage logs | Usage logs not duplicated (fresh questions get new logs when added via UI) |

---

## 13. Dependency TC Steps

#### TC-D01: Cascade — Force delete cascades to child records

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Q1 with 3 scopes, 5 questions, 2 allocations | Children exist |
| 2 | All allocations have no student attempts | Guard passes for hasAttempts |
| 3 | Click Force Delete on Q1 | `forceDelete()` called |
| 4 | DB check: `lms_quest_scopes` withTrashed() | All 3 scopes force-deleted |
| 5 | DB check: `lms_quest_questions` withTrashed() | All 5 questions force-deleted |
| 6 | DB check: `lms_quest_allocations` withTrashed() | All 2 allocations force-deleted |
| 7 | DB check: `lms_quests` withTrashed() | Q1 permanently gone |

---

#### TC-D02: Cascade — Soft delete does not cascade

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Q1 with 3 scopes, 5 questions | Children exist |
| 2 | Soft-delete Q1 (destroy) | Q1.deleted_at set |
| 3 | DB check: scopes deleted_at | NULL (NOT cascade-deleted) |
| 4 | DB check: questions deleted_at | NULL (NOT cascade-deleted) |
| 5 | Restore Q1 | Q1 restored, children still exist |

---

#### TC-D03: Transaction — Force delete rolls back on failure

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Q1 with scopes and questions | Children exist |
| 2 | Simulate DB failure during force delete (e.g., FK violation) | Exception thrown |
| 3 | Verify `DB::rollBack()` called | Transaction rolled back |
| 4 | DB check: Q1 withTrashed() | Still exists (force delete not completed) |
| 5 | DB check: scopes withTrashed() | Still exist |

---

#### TC-D04: Business — Activity log entry created on every action

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Quest → event 'Stored' | Activity log created |
| 2 | Update Quest → event 'Updated' | Activity log created |
| 3 | Soft-delete Quest → event 'Trashed' | Activity log created |
| 4 | Restore Quest → event 'Restored' | Activity log created |
| 5 | Force delete Quest → event 'Deleted' | Activity log created |
| 6 | Toggle status → event 'Toggled' | Activity log created |

---

#### TC-D05: Business — Quest becomes visible for allocation only when published

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Q1 in DRAFT | Not eligible for allocation |
| 2 | Try to allocate Q1 | Allocation blocked (Quest not active/published) |
| 3 | Publish Q1 (or set status=PUBLISHED) | Eligible for allocation |
| 4 | Archive Q1 (status=ARCHIVED, is_active=0) | Not eligible |

---

#### TC-D06: Business — Quest appears in status breakdown dashboard

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Dashboard query `questsQuery()` | Returns Quests with filters |
| 2 | Verify status_breakdown counts | DRAFT / PUBLISHED / ARCHIVED counts match DB |
| 3 | Filter by class_section_id | Quests filtered correctly |
| 4 | Filter by subject_id | Quests filtered correctly |

---

#### TC-D07: Business — Quest code auto-generation with null references

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Quest where AcademicSession code is null | Code uses 'GEN' |
| 2 | Create Quest where SchoolClass code is null | Code uses 'GEN' |
| 3 | Create Quest where Subject code is null | Code uses 'GEN' |
| 4 | Verify code pattern: `QUEST_GEN_GEN_GEN_GEN_{RANDOM6}` | All null references default to 'GEN' |

---

#### TC-D08: Business — Quest `marks_per_question` accessor

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Q1: total_marks=100, total_questions=20 | marks_per_question = 5.00 |
| 2 | Q2: total_marks=50, total_questions=10 | marks_per_question = 5.00 |
| 3 | Q3: total_marks=0, total_questions=0 | marks_per_question = 0 (guarded) |

---

## 14. Code Review TC Steps

#### TC-CR01: Controller store() — Quest creation flow

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `store()` in `LmsQuestController` | Gate authorize, validated data, created_by set |
| 2 | Verify `Gate::authorize('tenant.quest.create')` | Called before any logic |
| 3 | Verify `$request->validated()` | Uses `QuestRequest` rules |
| 4 | Verify `$questData['created_by'] = Auth::user()->id` | Creator set from auth |
| 5 | Verify code generation path: if empty quest_code | Calls model `generateQuestCode()` via boot `creating()` |
| 6 | Verify code generation fallback in controller | Also generates code inline if empty (duplicate path — see KI-01) |
| 7 | Verify `Quest::create($questData)` | Mass-assignment via fillable |
| 8 | Verify `activityLog($quest, 'Stored', ...)` | Activity log created |
| 9 | Verify redirect with success flash | `redirect()->route('lms-quests.quest.index', ['active_tab' => 'quest'])` |

---

#### TC-CR02: Controller store() — Duplicate code generation (Controller vs Model)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Controller `store()` checks `empty($questData['quest_code'])` | If empty, generates code inline |
| 2 | Model boot `creating()` also calls `generateQuestCode()` if empty | Controller code is already set in $questData before create() |
| 3 | Controller inline generation: uses `strtoupper(Str::random(6))` | Same pattern as model |
| 4 | Known gap: Two code-generation paths exist (controller + model) | ENH-QST-002 to consolidate |

---

#### TC-CR03: Controller edit() — Usage check before edit

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `edit()` method | Finds quest, checks usage, loads form data |
| 2 | Verify `Quest::findOrFail($id)` | 404 if not found |
| 3 | Verify `Gate::authorize('tenant.quest.update')` | Permission check |
| 4 | Verify `QuestUsageCheckService::isUsed($id)` | Returns back with error if used |
| 5 | Verify form data loaded | assessmentTypes, difficultyConfigs, academicSessions, classes, subjects, lessons |

---

#### TC-CR04: Controller update() — Update with change tracking

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `update()` method | Usage check, gate, update, activity log |
| 2 | Verify usage check runs BEFORE Gate | `$usageCheck->isUsed($id)` first, then `Gate::authorize` |
| 3 | Verify `$quest->getOriginal()` captured before update | Used for change tracking |
| 4 | Verify code generation path if empty | Same as store() |
| 5 | Verify `$quest->update($questData)` | Mass update |
| 6 | Verify `$quest->getChanges()` | Extracts changed fields |
| 7 | Verify `activityLog($quest, 'Updated', ...)` | Logs with changes array |
| 8 | Verify `updated_at` excluded from changes array | `if ($field === 'updated_at') continue` |

---

#### TC-CR05: Controller destroy() — Soft delete with deactivation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `destroy()` method | Usage check, gate, deactivate, soft delete |
| 2 | Verify `$usageCheck->isUsed($id)` | Blocks if in use |
| 3 | Verify `Gate::authorize('tenant.quest.delete')` | Permission check |
| 4 | Verify `$quest->is_active = false; $quest->status = 'ARCHIVED'; $quest->save()` | Deactivates before delete |
| 5 | Verify `$quest->delete()` | Sets deleted_at |
| 6 | Verify `activityLog($quest, 'Trashed', ...)` | Logs deactivation and trash |

---

#### TC-CR06: Controller trashed() — Trash listing

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `trashed()` method | `Gate::authorize('tenant.quest.restore')` |
| 2 | Verify `Quest::onlyTrashed()->paginate(10)` | Only soft-deleted records |
| 3 | Verify view returned | `lmsquests::quest.trash` |

---

#### TC-CR07: Controller restore() — Restore with reactivation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `restore()` method | Usage check, gate, restore, reactivate |
| 2 | Verify `$usageCheck->isUsed($id)` | Blocks if has allocations or attempts |
| 3 | Verify `Gate::authorize('tenant.quest.restore')` | Permission check |
| 4 | Verify `Quest::onlyTrashed()->findOrFail($id)` | Finds trashed record |
| 5 | Verify `$quest->restore()` | Clears deleted_at |
| 6 | Verify `$quest->is_active = true; $quest->save()` | Reactivates |
| 7 | Verify `activityLog($quest, 'Restored', ...)` | Logs restore |

---

#### TC-CR08: Controller forceDelete() — Permanent delete with cascade

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `forceDelete()` method | Gate, usage check, DB transaction, cascade |
| 2 | Verify `Gate::authorize('tenant.quest.forceDelete')` | Permission check |
| 3 | Verify `Quest::withTrashed()->findOrFail($id)` | Finds even non-trashed |
| 4 | Verify `$usageCheck->hasAllocations($id) || $usageCheck->hasAttempts($id)` | Guard with specific checks (not generic isUsed) |
| 5 | Verify `DB::beginTransaction()` | Transaction start |
| 6 | Verify `$quest->allocations()->forceDelete()` | Cascade allocations |
| 7 | Verify `$quest->questQuestions()->forceDelete()` | Cascade questions |
| 8 | Verify `$quest->scopes()->forceDelete()` | Cascade scopes |
| 9 | Verify `$quest->forceDelete()` | Permanent delete |
| 10 | Verify `DB::commit()` on success | Transaction commit |
| 11 | Verify catch block: `DB::rollBack()` | Rollback on failure |
| 12 | Verify `activityLog($quest, 'Deleted', ...)` | Logs with cascade message |

---

#### TC-CR09: Controller toggleStatus() — AJAX status toggle

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `toggleStatus()` method | Gate, validate, update, response |
| 2 | Verify `Gate::authorize('tenant.quest.update')` | Permission check |
| 3 | Verify inline validation: `is_active => required|boolean` | Input validated |
| 4 | Verify `$quest->is_active = $request->is_active` | Direct assignment (relies on model boolean cast) |
| 5 | Verify success JSON response | `{"success": true, "is_active": bool, "message": ...}` |
| 6 | Verify failure JSON response | `{"success": false, "message": ...}` |
| 7 | Verify `activityLog($quest, 'Toggled', ...)` | Activity log |

---

#### TC-CR10: Model Quest — boot() creating event

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `boot()` `creating()` closure | UUID, quest_code, created_by auto-set |
| 2 | Verify uuid generation: `Str::uuid()->getBytes()` | 16-byte binary |
| 3 | Verify uuid only set if empty | `if (empty($model->uuid))` |
| 4 | Verify quest_code generation: `$model->generateQuestCode()` | Custom method |
| 5 | Verify quest_code only generated if empty | `if (empty($model->quest_code))` |
| 6 | Verify created_by: `auth()->id()` | Auto-set if empty and auth exists |

---

#### TC-CR11: Model Quest — boot() updating event

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `updating()` closure | Quest code uniqueness on change |
| 2 | Verify `$model->isDirty('quest_code')` | Only checks if changed |
| 3 | Verify uniqueness query: `self::where('quest_code', $code)->where('id', '!=', $model->id)->exists()` | Excludes self |
| 4 | Verify suffix append: `$model->quest_code . '_' . Str::random(4)` | Random suffix on conflict |

---

#### TC-CR12: Model Quest — generateQuestCode() uniqueness loop

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `generateQuestCode()` method | Pattern assembly + uniqueness loop |
| 2 | Verify code pattern: `QUEST_{S}_{C}_{SUB}_GEN_{R6}` | 5 segments |
| 3 | Verify null coalescing: `$session?->code ?? 'GEN'` | Null-safe defaults |
| 4 | Verify uniqueness while loop: `while (self::where('quest_code', $code)->exists())` | Appends `_1`, `_2`, etc. |

---

#### TC-CR13: Model Quest — canPublish() readiness check

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `canPublish()` method | 4 checks |
| 2 | Verify questions count check: `questQuestions()->count() === 0` | Must have questions |
| 3 | Verify count match check: `questQuestions()->count() !== $this->total_questions` | Exact match required |
| 4 | Verify settings check: `!empty($this->validateSettings())` | Calls validateSettings() |
| 5 | Verify context check: `!$this->academic_session_id || !$this->class_id || !$this->subject_id` | All required |

---

#### TC-CR14: Model Quest — validateSettings() validation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `validateSettings()` | Returns array of error strings |
| 2 | Verify total_questions < 0 check | Error: "Total questions cannot be negative." |
| 3 | Verify total_marks < 0 check | Error: "Total marks cannot be negative." |
| 4 | Verify passing_percentage range check: 0–100 | Error: "Passing percentage must be between 0 and 100." |
| 5 | Verify negative_marks < 0 check | Error: "Negative marks cannot be negative." |
| 6 | Verify max_attempts < 1 check | Error: "Maximum attempts must be at least 1." |
| 7 | Verify timer_enforced + duration check | Error: "Duration must be at least 1 minute when timer is enforced." |

---

#### TC-CR15: Model Quest — duplicate() method

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `duplicate()` method | Replicate, override, save, clone children |
| 2 | Verify `$this->replicate()` | Creates new instance |
| 3 | Verify `quest_code = generateQuestCode() . '_COPY'` | New code with COPY suffix |
| 4 | Verify `title = $this->title . ' (Copy)'` | Copy title |
| 5 | Verify `status = 'DRAFT'` | Always Draft |
| 6 | Verify `created_by = auth()->id()` | Current user |
| 7 | Verify `created_at = now(); updated_at = now()` | Fresh timestamps |
| 8 | Verify overrides applied: `foreach ($overrides as $key => $value)` | Custom overrides |
| 9 | Verify scopes cloned: `foreach ($this->scopes as $scope)` | replicate() + new quest_id |
| 10 | Verify questions cloned: `foreach ($this->questQuestions as $question)` | replicate() + new quest_id |

---

#### TC-CR16: Model Quest — SoftDeletes trait integration

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Verify model uses `SoftDeletes` | Trait imported |
| 2 | Verify `$dates` includes 'deleted_at' | Casted as datetime |
| 3 | Verify `$fillable` includes 'deleted_at' | Fillable for mass assignment |

---

#### TC-CR17: Request QuestRequest — prepareForValidation() boolean conversion

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `prepareForValidation()` | Converts 12 toggle fields to boolean |
| 2 | Verify `$this->boolean('allow_multiple_attempts')` | String '0'/'1' → bool |
| 3 | Verify all 12 boolean fields converted | is_randomized, question_marks_shown, auto_publish_result, timer_enforced, show_correct_answer, show_explanation, ignore_difficulty_config, only_unused_questions, only_authorised_questions, is_system_generated, is_active |
| 4 | Verify conversion runs before validation rules | `prepareForValidation()` called automatically |

---

#### TC-CR18: Request QuestRequest — authorize() returns true unconditionally

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `QuestRequest::authorize()` | Returns `true` (no permission check) |
| 2 | Verify controller `store()` and `update()` use `Gate::authorize()` separately | Relies on controller gate, not request authorization |

---

#### TC-CR19: QuestUsageCheckService — isUsed() logic

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `isUsed($questId)` | `getUsageCount($questId) > 0` |
| 2 | Verify `getUsageCount()` | Sum of allocations count + attempts count |
| 3 | Verify `hasAllocations()` | `QuestAllocation::where('quest_id', $id)->count() > 0` |
| 4 | Verify `hasAttempts()` | `QuizQuestAttempt::where('quest_id', $id)->count() > 0` |
| 5 | Verify `hasQuestions()` | `QuestQuestion::where('quest_id', $id)->count() > 0` |
| 6 | Note: `hasQuestions()` is NOT used in any controller guard | Only `isUsed()` (allocations + attempts) used for edit/delete block |

---

#### TC-CR20: Policy QuestPolicy — Permission methods

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `QuestPolicy` | 11 permission methods |
| 2 | Verify `viewAny`: `tenant.quest.viewAny` | List permission |
| 3 | Verify `view`: `tenant.quest.view` | Show permission |
| 4 | Verify `create`: `tenant.quest.create` | Create permission |
| 5 | Verify `update`: `tenant.quest.update` | Update/toggle permission |
| 6 | Verify `delete`: `tenant.quest.delete` | Soft delete permission |
| 7 | Verify `restore`: `tenant.quest.restore` | Restore permission |
| 8 | Verify `forceDelete`: `tenant.quest.forceDelete` | Force delete permission |
| 9 | Verify `status`: `tenant.quest.status` | Status toggle permission |
| 10 | Verify `duplicate`: `tenant.quest.duplicate` | Duplicate permission |
| 11 | Verify `publish`: `tenant.quest.publish` | Publish permission |
| 12 | Verify `archive`: `tenant.quest.archive` | Archive permission |

---

#### TC-CR21: Blade @can Directives — Permission visibility for quest creation buttons

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `quest/index.blade.php` — Index table header | `@can('tenant.quest.status')` wraps Active column header; `@canany(['tenant.quest.view', 'tenant.quest.update', 'tenant.quest.delete'])` wraps Actions column header |
| 2 | Review `quest/index.blade.php` — Index table rows | `@can('tenant.quest.status')` wraps per-row status toggle; `@canany(['tenant.quest.view', 'tenant.quest.update', 'tenant.quest.delete'])` wraps per-row action buttons |
| 3 | Review `quest/show.blade.php` — Show page | `@can('tenant.quest.update')` wraps Edit button |
| 4 | Review `quest/show.blade.php` — Usage check | `@if(!$isUsed)` inside `@can` block ensures Edit hidden when quest is in use |
| 5 | Review `tab_module/tab.blade.php` — Tab navigation | Each tab wrapped in `@can('tenant.quest-*.viewAny')` — quest, scope, question, allocation, summary, activity log tabs |
| 6 | Review `quest/trash.blade.php` — Trash actions | `@canany(...)` wraps restore and force-delete buttons per row |
| 7 | Review `quest/create.blade.php` — Create page | No `@can` check needed inside create view (controller `Gate::authorize()` already enforces); verify form renders only if user reached the page |
| 8 | Verify: User WITHOUT `tenant.quest.status` | Active column and toggle hidden from index |
| 9 | Verify: User WITHOUT `tenant.quest.update` | Edit button hidden from show page |
| 10 | Verify: User WITH only `tenant.quest.view` | Index shows only View action; no Edit/Delete buttons |

---

#### TC-CR22: Breadcrumb Config — Route registered in config/breadcrumb.php

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `config/breadcrumb.php` | Check `hub_map` section for Quest Module entries |
| 2 | Verify `hub_map` entry: `'lms-quests' => 'lms-quests/quest'` | Maps `lms-quests` URL segment to quest hub page |
| 3 | Verify `hub_map` entry: `'quest' => 'lms-quests/quest'` | Maps `quest` segment to quest hub |
| 4 | Verify `hub_map` entry: `'quest-scope' => 'lms-quests/quest'` | Scope sub-resource links back to quest hub |
| 5 | Verify `hub_map` entry: `'quest-question' => 'lms-quests/quest'` | Question sub-resource links back to quest hub |
| 6 | Verify `hub_map` entry: `'quest-allocation' => 'lms-quests/quest'` | Allocation sub-resource links back to quest hub |
| 7 | Verify `tab_aliases` entries: `'quest' => 'quest'`, `'quest-scope' => 'quest_scope'`, `'quest-question' => 'quest_question'`, `'quest-allocation' => 'quest_allocation'` | Tab aliases resolve to correct tab IDs |
| 8 | Verify blade files use `<x-backend.components.breadcrum title="..." :links="[]" />` pattern | All quest-related blade files follow rule of empty `:links` array |
| 9 | Verify breadcrumb renders correctly on index, create, edit, show, trash pages | Navigation trail shows and links resolve correctly |

---

#### TC-CR23: View — isset()/null-safe Checks for Relationship Variables

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `quest/show.blade.php` — Relationship display | `$quest->academicSession->name ?? '-'` — null-safe with `??` fallback |
| 2 | Review `quest/show.blade.php` — Class & Subject | `$quest->class->name ?? '-'` and `$quest->subject->name ?? '-'` — null-safe |
| 3 | Review `quest/show.blade.php` — Quest Type | `$quest->assessmentType->name ?? '-'` — null-safe |
| 4 | Review `quest/show.blade.php` — Duration & Difficulty | `$quest->duration_minutes ?? '-'` and `$quest->difficultyConfig->name ?? '-'` — null-safe |
| 5 | Review `quest/show.blade.php` — Timestamps | `$quest->created_at?->format(...)` — PHP 8 null-safe operator |
| 6 | Review `quest/show.blade.php` — Description & Instructions | `$quest->description ?? '-'` and `$quest->instructions ?? '-'` — null coalescing |
| 7 | Review `quest/show.blade.php` — Usage Details | `@if($isUsed && !empty($usageDetails))` and `@if(!empty($allocationDetails))` — emptiness checks before iteration |
| 8 | Review `quest/index.blade.php` — Table row | `$quest->assessmentType->name ?? 'N/A'` — null-safe with N/A fallback |
| 9 | Review `quest/index.blade.php` — Title truncation | `Str::limit($quest->title, 30)` — safe even if title is null (string cast) |
| 10 | Review `quest/trash.blade.php` — Trashed list | `$quest->assessmentType->name ?? '-'` — null-safe |
| 11 | Review `quest/edit.blade.php` — Form old values | `old('class_id', $quest->class_id)` — `$quest->class_id` is always set (NOT NULL column) |
| 12 | Verify no blade file calls `$quest->relationship->field` without `??` or `optional()` or `?->` | All relationship accesses guarded |

---

#### TC-CR24: View — Success Flash Messages After Create/Update/Delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `LmsQuestController::store()` | `return redirect()->route(...)->with('success', flash('created.quest'))` — flashes 'created.quest' key |
| 2 | Review `LmsQuestController::update()` | `return redirect()->route(...)->with('success', flash('updated.quest'))` — flashes 'updated.quest' key |
| 3 | Review `LmsQuestController::destroy()` | `return redirect()->route(...)->with('success', flash('trashed.quest'))` — flashes 'trashed.quest' key |
| 4 | Review `LmsQuestController::restore()` | `return redirect()->route(...)->with('success', flash('restored.quest'))` — flashes 'restored.quest' key |
| 5 | Review `LmsQuestController::forceDelete()` | `return redirect()->route(...)->with('success', flash('force_deleted.quest'))` — flashes 'force_deleted.quest' key |
| 6 | Review parent layout / master blade for flash display | Alert component renders `session('success')` message as a Bootstrap dismissible alert |
| 7 | Verify `flash('created.quest')` resolves to a valid translation string | Language file contains key (e.g., `'created.quest' => 'Quest created successfully!'`) |
| 8 | Verify `flash('updated.quest')` resolves | Language key defined |
| 9 | Verify `flash('trashed.quest')` resolves | Language key defined |
| 10 | Verify `flash('restored.quest')` resolves | Language key defined |
| 11 | Verify `flash('force_deleted.quest')` resolves | Language key defined |
| 12 | Verify error flash messages (usage guard blocks) also render | Controller uses `->with('error', flash('error.quest', '...'))` and alert component renders danger variant |

---

## 15. Known Issues

| # | Issue | Severity | Details |
|---|-------|----------|---------|
| KI-01 | Duplicate quest-code generation path (Controller + Model) | **Medium** | Both `LmsQuestController::store()` and `Quest::boot() creating()` generate quest codes independently. Controller generates inline code first, then sets it in $questData. But the model boot also checks `if (empty($model->quest_code))` — since the controller already set it, the model path is redundant for store, but the model path is the only one active when `Quest::create()` is called without the controller. ENH-QST-002 proposes consolidating. |
| KI-02 | `FormRequest::authorize()` returns `true` unconditionally | **High** | `QuestRequest::authorize()` returns `true` instead of checking `Gate::allows()`. Permission is enforced in the Controller via `Gate::authorize()`, but this bypasses the defence-in-depth pattern. |
| KI-03 | Edit form can bypass readiness check to set PUBLISHED | **Medium** | The edit form allows setting status = 'PUBLISHED' directly without calling `canPublish()`. The readiness check is only in the model `publish()` method, which is not called from the controller `update()`. ENH-QST-001 proposes a dedicated publish action. |
| KI-04 | `forceDelete()` uses `hasAllocations()` and `hasAttempts()` but not `hasQuestions()` | **Low** | The usage guard for force delete checks allocations and attempts but not if the quest has questions. The cascade (`questQuestions()->forceDelete()`) handles questions anyway, but the guard message doesn't mention questions. |
| KI-05 | `hasQuestions()` in `QuestUsageCheckService` is defined but never used by any controller method | **Low** | The method `hasQuestions()` exists in the service but is not called by `destroy()`, `edit()`, `update()`, `restore()`, or `forceDelete()`. The usage guard only checks `hasAllocations()` and `hasAttempts()`. |
| KI-06 | `toggleStatus()` saves `is_active` from request directly without explicit boolean cast in controller | **Low** | `$quest->is_active = $request->is_active` — relies on model casting to boolean, but the request value may be a string '0'/'1'. The `prepareForValidation()` in QuestRequest does convert booleans, but toggleStatus() uses inline validation not the FormRequest. |
| KI-07 | No dedicated duplicate route/controller method | **Medium** | The model `duplicate()` method exists with full capability, but there is no route or controller method exposing it. The only way to duplicate is via the model directly (ENH-QST-003). |
| KI-08 | No dedicated publish/archive route | **Medium** | The model `publish()` and `archive()` methods exist, but there are no dedicated controller routes for them. Publishing is done via the edit form by setting status = 'PUBLISHED', which bypasses `canPublish()`. |
| KI-09 | `restore()` sets `is_active=true` but does not reset status from ARCHIVED | **Low** | Controller `restore()` sets `is_active=true` but does not explicitly reset `status` to 'DRAFT'. The model has `restoreQuest()` which sets status='DRAFT', but the controller calls `$quest->restore()` (SoftDeletes trait) and then `$quest->is_active = true`. Status remains what it was before delete (ARCHIVED). |
| KI-10 | `destroy()` sets status=ARCHIVED before soft delete, but restore doesn't revert it | **Low** | Destroy deactivates: status=ARCHIVED, is_active=false, then deletes. Restore only sets is_active=true but doesn't revert status to DRAFT. |
| KI-11 | `forceDelete()` guard for allocations vs isUsed() inconsistency | **Medium** | `forceDelete()` uses `hasAllocations()` OR `hasAttempts()` whereas `edit()`, `update()`, `destroy()`, `restore()` use `isUsed()` which counts both. The forceDelete requires BOTH allocations AND attempts to fail, while others require EITHER. |
| KI-12 | Phantom fields: `show_result_immediately` and `pending` have no backing DDL column | **Low** | The model may reference these but the DDL does not have corresponding columns (ENH-QST-005). |

---

## 16. Execution Status

| TC ID | Test Case Name | Status (Pass/Fail/Blocked/Skip) | Tested By | Test Date | Bug ID | Notes |
|-------|---------------|----------------------------------|-----------|-----------|--------|-------|
| TC-P01 | Create — Minimal Quest | | | | | |
| TC-P02 | Create — Full configuration | | | | | |
| TC-P03 | Create — Auto code generation uniqueness | | | | | |
| TC-P04 | Create — Toggle: Allow Multiple Attempts | | | | | Verify max_attempts forced to 1 when OFF |
| TC-P05 | Create — Toggle: Timer Enforced | | | | | Verify duration enabled/disabled |
| TC-P06 | Create — Toggle: Ignore Difficulty Config | | | | | Verify config ignored |
| TC-P07 | Create — All 12 toggle switches defaults | | | | | |
| TC-P08 | Create — Description and Instructions | | | | | |
| TC-P09 | Create — Zero marks/questions | | | | | Edge case |
| TC-P10 | Create — Max boundary values | | | | | Duration=300, Marks=999999.99, etc. |
| TC-P11 | Show — View quest details | | | | | |
| TC-P12 | Edit — Update title and context | | | | | |
| TC-P13 | Edit — Update configuration | | | | | |
| TC-P14 | Edit — Manual quest_code change | | | | | |
| TC-P15 | Edit — Quest code auto-uniqueness | | | | | |
| TC-P16 | Publish — Successful when ready | | | | | |
| TC-P17 | Publish — canPublish() check | | | | | |
| TC-P18 | Archive — Successful | | | | | |
| TC-P19 | Status transition: D→P→A→D | | | | | |
| TC-P20 | Duplicate — Full copy with scopes/questions | | | | | |
| TC-P21 | Duplicate — With overrides | | | | | |
| TC-P22 | Duplicate — Empty quest | | | | | |
| TC-P23 | Destroy — Soft delete unused | | | | | |
| TC-P24 | Trashed — View trash listing | | | | | |
| TC-P25 | Restore — Restore soft-deleted | | | | | |
| TC-P26 | Force Delete — Permanent delete | | | | | |
| TC-P27 | Toggle Status — AJAX activate/deactivate | | | | | |
| TC-P28 | Toggle Status — Active list filtering | | | | | |
| TC-P29 | AJAX — Get subjects by class | | | | | |
| TC-N01 | Create — Missing required fields | | | | | |
| TC-N02 | Create — Invalid status | | | | | |
| TC-N03 | Create — Passing % out of range | | | | | |
| TC-N04 | Create — Negative marks/questions | | | | | |
| TC-N05 | Create — Duration out of range | | | | | |
| TC-N06 | Create — Negative marks out of range | | | | | |
| TC-N07 | Create — Max attempts validation | | | | | |
| TC-N08 | Create — Invalid quest_type_id | | | | | |
| TC-N09 | Create — Invalid difficulty_config_id | | | | | |
| TC-N10 | Create — Title too long | | | | | |
| TC-N11 | Edit — Blocked by allocations | | | | | |
| TC-N12 | Edit — Blocked by student attempts | | | | | |
| TC-N13 | Update — Blocked by allocations | | | | | |
| TC-N14 | Destroy — Blocked by allocations | | | | | |
| TC-N15 | Destroy — Blocked by questions | | | | | |
| TC-N16 | Destroy — Blocked by student attempts | | | | | |
| TC-N17 | Restore — Blocked by allocations | | | | | |
| TC-N18 | Restore — Blocked by student attempts | | | | | |
| TC-N19 | Force Delete — Blocked by allocations | | | | | |
| TC-N20 | Force Delete — Blocked by student attempts | | | | | |
| TC-N21 | Create — Without permission | | | | | |
| TC-N22 | Edit — Without permission | | | | | |
| TC-N23 | Delete — Without permission | | | | | |
| TC-N24 | View Trash — Without permission | | | | | |
| TC-N25 | Force Delete — Without permission | | | | | |
| TC-N26 | Toggle Status — Without permission | | | | | |
| TC-N27 | Publish — No questions | | | | | |
| TC-N28 | Publish — Question count mismatch | | | | | |
| TC-N29 | Publish — Incomplete context | | | | | |
| TC-N30 | Publish — Invalid settings | | | | | |
| TC-N31 | Publish — Timer enforced no duration | | | | | |
| TC-N32 | Toggle — Invalid is_active value | | | | | |
| TC-N33 | Duplicate — Usage log not copied | | | | | |
| TC-D01 | Cascade — Force delete children | | | | | |
| TC-D02 | Cascade — Soft delete no cascade | | | | | |
| TC-D03 | Transaction — Rollback on failure | | | | | |
| TC-D04 | Business — Activity log all actions | | | | | |
| TC-D05 | Business — Published for allocation | | | | | |
| TC-D06 | Business — Dashboard status breakdown | | | | | |
| TC-D07 | Business — Null code references | | | | | |
| TC-D08 | Business — marks_per_question accessor | | | | | |
| TC-CR01 | Controller store() — Flow | | | | | |
| TC-CR02 | Controller store() — Code gen paths | | | | | |
| TC-CR03 | Controller edit() — Usage check | | | | | |
| TC-CR04 | Controller update() — Change tracking | | | | | |
| TC-CR05 | Controller destroy() — Soft delete | | | | | |
| TC-CR06 | Controller trashed() — Listing | | | | | |
| TC-CR07 | Controller restore() — Restore flow | | | | | |
| TC-CR08 | Controller forceDelete() — Cascade | | | | | |
| TC-CR09 | Controller toggleStatus() — AJAX | | | | | |
| TC-CR10 | Model boot() — creating event | | | | | |
| TC-CR11 | Model boot() — updating event | | | | | |
| TC-CR12 | Model generateQuestCode() | | | | | |
| TC-CR13 | Model canPublish() | | | | | |
| TC-CR14 | Model validateSettings() | | | | | |
| TC-CR15 | Model duplicate() | | | | | |
| TC-CR16 | Model SoftDeletes integration | | | | | |
| TC-CR17 | Request prepareForValidation() | | | | | |
| TC-CR18 | Request authorize() unconditional | | | | | |
| TC-CR19 | QuestUsageCheckService logic | | | | | |
| TC-CR20 | QuestPolicy permissions | | | | | |
| TC-CR21 | Blade @can Directives | | | | | |
| TC-CR22 | Breadcrumb Config | | | | | |
| TC-CR23 | View isset()/null-safe checks | | | | | |
| TC-CR24 | View Success Flash Messages | | | | | |

---

## 17. TC Count Summary

| Category | Original Count | New Count | Change |
|----------|---------------|-----------|--------|
| Positive (TC-P) | 29 | 29 | Same |
| Negative (TC-N) | 33 | 33 | Same |
| Dependency (TC-D) | 8 | 8 | Same |
| Code Review (TC-CR) | 20 | 24 | +4 (CR21–CR24) |
| **Total** | **90** | **94** | **+4** |

---

*Document Version: 2.0 — Last Updated: 2026-07-18*
*TC List covers: REQ-QST-001 (Creation & Configuration), REQ-QST-005 (Publish & Lifecycle), REQ-QST-006 (Duplication), REQ-QST-007 (Soft Delete/Trash/Restore/Force Delete), REQ-QST-008 (Status Toggle), BR-QST-001 to BR-QST-006, BR-QST-027 to BR-QST-031, and related code paths. Total TC count: 94 (29 Positive + 33 Negative + 8 Dependency + 24 Code Review). Sections: 17 (restructured with BC-DB, BC-VAL, BC-AUTH, BC-BIZ, BC-REF, Test Case Summary).*
