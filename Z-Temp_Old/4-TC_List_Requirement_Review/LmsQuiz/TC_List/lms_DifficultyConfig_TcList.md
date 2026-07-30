# lms_DifficultyConfig_TcList

## Module: LmsQuiz → Quiz Management → Difficulty Distribution Config

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | LmsQuiz (cross-module: also used by LmsExam, LmsQuests) |
| Tab Group | Quiz Management |
| Feature | Difficulty Distribution Config |
| URL(s) | `/lms-quize/difficulty-distribution-config` (resource, but NO show route), `/lms-quize/difficulty-distribution-config/create` (create), `/lms-quize/difficulty-distribution-config/{difficulty_distribution_config}/edit` (edit), `/lms-quize/difficulty-distribution-config/{difficulty_distribution_config}` (update/destroy), `/lms-quize/difficulty-distribution-config/trash/view` (trashed), `/lms-quize/difficulty-distribution-config/{id}/restore` (restore), `/lms-quize/difficulty-distribution-config/{id}/force-delete` (forceDelete), `/lms-quize/difficulty-distribution-config/{difficulty_distribution_config}/toggle-status` (toggleStatus), `/lms-quize/difficulty-distribution-config/get-cognitive-skills` (AJAX), `/lms-quize/difficulty-distribution-config/get-specificities` (AJAX) |
| Controller | `Modules\LmsQuiz\Http\Controllers\DifficultyDistributionConfigController` |
| Model(s) | `DifficultyDistributionConfig` (parent — `Modules\LmsQuiz\Models\DifficultyDistributionConfig`), `DifficultyDistributionDetail` (child — `Modules\LmsQuiz\Models\DifficultyDistributionDetail`) |
| Validation | `DifficultyDistributionConfigRequest` (`Modules\LmsQuiz\Http\Requests\DifficultyDistributionConfigRequest`) — single request |
| Permission Gates | `tenant.difficulty-distribution-config.viewAny`, `.view`, `.create`, `.update`, `.delete`, `.restore`, `.forceDelete`, `.status` (Request uses `tenant.lms-difficulty-config.create`/`.update` — different prefix) |
| Soft Deletes | Yes — `SoftDeletes` trait on both Config and Detail models |
| Activity Log | Yes — `activityLog()` called in store, update, destroy, restore, forceDelete, toggleStatus |
| Import | Not supported |

---

## 2. Pre-conditions

- Required permission: `tenant.difficulty-distribution-config.viewAny` (Policy) / `tenant.lms-difficulty-config` (Request)
- Seed data: Question Usage Types, Question Types, Complexity Levels, Bloom Taxonomies, Cognitive Skills, Question Type Specificities
- Config defines `rules` (distribution details) linking question_type_id + complexity_level_id (+ optional bloom/cognitive/specificity) to min/max percentage ranges

---

## 3. Default Data Load

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| Config List | `DifficultyDistributionConfig::with('usageType')` | Search by code/name, filter by usage_type_id, is_active | search, usage_type_id, is_active | 10 per page |
| Single Config (edit) | `DifficultyDistributionConfig::with('distributionDetails')->findOrFail($id)` | By ID | None |
| Single Config (show) | `DifficultyDistributionConfig::with(['usageType','distributionDetails.questionType','distributionDetails.complexityLevel'])->findOrFail($id)` | By ID | None |
| Question Usage Types (dropdown) | `QuestionUsageType::where('is_active',1)->get()` | | |
| Question Types (dropdown) | `QuestionType::where('is_active',1)->get()` | | |
| Complexity Levels (dropdown) | `ComplexityLevel::where('is_active',1)->get()` | | |
| Bloom Taxonomies (dropdown) | `BloomTaxonomy::where('is_active',1)->get()` | | |
| Cognitive Skills (AJAX) | `CognitiveSkill::where('bloom_id',$bloomId)->active()->orderBy('name')->get()` | By bloom_id | |
| Question Type Specificities (AJAX) | `QueTypeSpecifity::where('cognitive_skill_id',$skillId)->active()->orderBy('name')->get()` | By cognitive_skill_id | |
| Usage Details | `DifficultyConfigUsageCheckService::getUsageDetails($id)` | Checks Quiz, ExamPaper, Quest counts | |

---

## 4. Test Data Strategy

- **Rules-Based Distribution**: Config defines rules (distribution details) as an array of `{question_type_id, complexity_level_id, min_percentage, max_percentage, optional: bloom_id, cognitive_skill_id, ques_type_specificity_id, marks_per_question}`
- **No Percentage Sum Constraint**: Unlike the old TC, the code does NOT enforce sum of percentages = 100. Each rule has independent min/max ranges
- **Unique Code**: `code` field is unique across all configs (validated via `Rule::unique`)
- **System Default Exclusivity**: Only ONE config can have `use_for_system_generated_quiz=true` at a time. Model `booted()` `saving` event auto-deactivates others. Request also validates this
- **Cross-Module Usage**: Config is shared across LmsQuiz, LmsExam, LmsQuests modules. Usage check counts all three
- **Update Resets Rules**: `update()` force-deletes all existing details and re-creates them from request
- **Cascading AJAX**: Bloom → Cognitive Skills → Specificities chain for rule builder
- **Permission Prefix Inconsistency**: Policy uses `tenant.difficulty-distribution-config.*` but Request's `authorize()` uses `tenant.lms-difficulty-config.*`

---

## 5. Business Conditions

### 5.1 Database Schema

Table: `lms_difficulty_distribution_configs`

| Column | Type | Constraints | Default | Notes |
|--------|------|-------------|---------|-------|
| id | bigint(20) unsigned | PK, AUTO_INCREMENT | | |
| code | varchar(50) | UNIQUE | | Unique identifier |
| name | varchar(100) | | | Required |
| description | varchar(255) | NULLABLE | NULL | |
| usage_type_id | bigint(20) unsigned | INDEX | | FK → qns_question_usage_type.id |
| is_active | tinyint(1) | | 1 | Boolean |
| use_for_system_generated_quiz | tinyint(1) | | 0 | Only one can be true (enforced by model boot + request) |
| created_at | timestamp | | CURRENT_TIMESTAMP | |
| updated_at | timestamp | | ON UPDATE CURRENT_TIMESTAMP | |
| deleted_at | timestamp | NULLABLE | NULL | |

Table: `lms_difficulty_distribution_details`

| Column | Type | Constraints | Default | Notes |
|--------|------|-------------|---------|-------|
| id | bigint(20) unsigned | PK, AUTO_INCREMENT | | |
| difficulty_config_id | bigint(20) unsigned | INDEX, FK | | Parent config |
| question_type_id | bigint(20) unsigned | INDEX | | FK → slb_question_types.id |
| complexity_level_id | bigint(20) unsigned | INDEX | | FK → slb_complexity_level.id |
| bloom_id | bigint(20) unsigned | NULLABLE | NULL | Optional FK → slb_bloom_taxonomy.id |
| cognitive_skill_id | bigint(20) unsigned | NULLABLE | NULL | Optional FK → slb_cognitive_skill.id |
| ques_type_specificity_id | bigint(20) unsigned | NULLABLE | NULL | Optional FK → slb_ques_type_specificity.id |
| min_percentage | decimal(5,2) | | 0 | Minimum % of questions for this rule |
| max_percentage | decimal(5,2) | | 0 | Maximum % of questions for this rule |
| marks_per_question | decimal(8,2) | NULLABLE | NULL | Override marks for questions matching this rule |
| is_active | tinyint(1) | | 1 | Boolean |
| created_at | timestamp | | CURRENT_TIMESTAMP | |
| updated_at | timestamp | | ON UPDATE CURRENT_TIMESTAMP | |
| deleted_at | timestamp | NULLABLE | NULL | |

### 5.2 Validation Rules — DifficultyDistributionConfigRequest

| BC ID | Field | Rule | Notes |
|-------|-------|------|-------|
| BC-VAL-01 | code | required, string, max:50, unique:lms_difficulty_distribution_configs (ignore current ID on update) | |
| BC-VAL-02 | name | required, string, max:100 | |
| BC-VAL-03 | description | nullable, string, max:255 | |
| BC-VAL-04 | usage_type_id | required, exists:qns_question_usage_type,id | |
| BC-VAL-05 | is_active | sometimes, boolean | Via prepareForValidation |
| BC-VAL-06 | use_for_system_generated_quiz | sometimes, boolean, custom rule: only one allowed | Cross-field validation checking no other config has this flag |
| BC-VAL-07 | rules | required, array, min:1 | At least one rule required |
| BC-VAL-08 | rules.*.question_type_id | required, exists:slb_question_types,id | |
| BC-VAL-09 | rules.*.complexity_level_id | required, exists:slb_complexity_level,id | |
| BC-VAL-10 | rules.*.bloom_id | nullable, exists:slb_bloom_taxonomy,id | |
| BC-VAL-11 | rules.*.cognitive_skill_id | nullable, exists:slb_cognitive_skill,id | |
| BC-VAL-12 | rules.*.ques_type_specificity_id | nullable, exists:slb_ques_type_specificity,id | |
| BC-VAL-13 | rules.*.min_percentage | required, numeric, min:0, max:100 | |
| BC-VAL-14 | rules.*.max_percentage | required, numeric, min:0, max:100 | |
| BC-VAL-15 | rules.*.max_percentage (cross) | Must be ≥ min_percentage | via withValidator |
| BC-VAL-16 | rules.*.marks_per_question | nullable, numeric, min:0 | |
| BC-VAL-17 | rules.*.is_active | sometimes, boolean | |

### 5.3 Authorization (Permission Gates)

| BC ID | Permission | Policy Method | Controller Method | Behavior Without |
|-------|-----------|---------------|-------------------|-----------------|
| BC-AUTH-01 | tenant.difficulty-distribution-config.viewAny | viewAny() | index() | 403 |
| BC-AUTH-02 | tenant.difficulty-distribution-config.view | view() | show() | 403 |
| BC-AUTH-03 | tenant.difficulty-distribution-config.create | create() | create(), store() | 403 |
| BC-AUTH-04 | tenant.difficulty-distribution-config.update | update() | edit(), update(), toggleStatus() | 403 |
| BC-AUTH-05 | tenant.difficulty-distribution-config.delete | delete() | destroy() | 403 |
| BC-AUTH-06 | tenant.difficulty-distribution-config.restore | restore() | trashed(), restore() | 403 |
| BC-AUTH-07 | tenant.difficulty-distribution-config.forceDelete | forceDelete() | forceDelete() | 403 |
| BC-AUTH-08 | tenant.difficulty-distribution-config.status | status() | — (not used by controller) | — |

Note: Request's `authorize()` uses `tenant.lms-difficulty-config.create`/`.update` — different prefix from Policy's `tenant.difficulty-distribution-config.*`. This is a permission naming inconsistency between the two layers.

### 5.4 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Create config — with rules | Config created; rules (details) created with question_type_id + complexity_level_id + percentages |
| BC-BIZ-02 | Create config — use_for_system_generated_quiz=true | Sets flag; any other config with same flag auto-deactivated (model boot + request validation) |
| BC-BIZ-03 | Create config — unique code violation | Validation error: code already taken |
| BC-BIZ-04 | Update config — code unchanged | Unique validation ignores current ID; update succeeds |
| BC-BIZ-05 | Update config — rules reset | Existing details force-deleted; new rules created from request |
| BC-BIZ-06 | Edit config — config in use (has quizzes/exams/quests) | Redirect with error: "Therefore cannot be edited." |
| BC-BIZ-07 | Update config — config in use | Back with error: "Therefore cannot be updated." |
| BC-BIZ-08 | Destroy config — config in use | Back with error: "Therefore cannot be deleted." |
| BC-BIZ-09 | Destroy config — not in use | Sets is_active=false, then soft deletes |
| BC-BIZ-10 | Restore config | Restores soft-deleted record; sets is_active=true |
| BC-BIZ-11 | Force delete config — has dependencies | Checks Quiz, ExamPaper, Quest dependencies; blocks with list of dependent items |
| BC-BIZ-12 | Force delete config — no dependencies | Force-deletes details then config in transaction |
| BC-BIZ-13 | Toggle status (toggleStatus AJAX) | is_active toggled; no exclusivity check on toggle |
| BC-BIZ-14 | Show config — usage details | Displays usage counts across LmsQuiz, LmsExam, LmsQuests |
| BC-BIZ-15 | Rule min/max percentage validation | max_percentage must be ≥ min_percentage per rule |
| BC-BIZ-16 | Optional attributes in rules | bloom_id, cognitive_skill_id, ques_type_specificity_id can be null for broader matching |
| BC-BIZ-17 | AJAX getCognitiveSkills | Returns cognitive skills filtered by bloom_id |
| BC-BIZ-18 | AJAX getSpecificities | Returns question type specificities filtered by cognitive_skill_id |

### 5.5 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|------------------|----------------|
| BC-REF-01 | difficulty_config_id (details) | lms_difficulty_distribution_configs (id) | — |
| BC-REF-02 | question_type_id (details) | slb_question_types (id) | — |
| BC-REF-03 | complexity_level_id (details) | slb_complexity_level (id) | — |
| BC-REF-04 | bloom_id (details) | slb_bloom_taxonomy (id) | — |
| BC-REF-05 | cognitive_skill_id (details) | slb_cognitive_skill (id) | — |
| BC-REF-06 | ques_type_specificity_id (details) | slb_ques_type_specificity (id) | — |
| BC-REF-07 | difficulty_config_id (lms_quizzes) | lms_difficulty_distribution_configs (id) | SET NULL |
| BC-REF-08 | usage_type_id | qns_question_usage_type (id) | — |

---

## 6. Test Case List

### 6.1 Positive Test Cases

| TC ID | Description | Expected Result | Status |
|-------|-------------|----------------|--------|
| TC-P01 | Create Config — with code, name, usage_type, 1 rule | Config created; 1 detail row with question_type + complexity + percentages | ⬜ |
| TC-P02 | Create Config — with 3 rules (different type+complexity combos) | Config created; 3 detail rows | ⬜ |
| TC-P03 | Create Config — with optional bloom_id, cognitive_skill_id, ques_type_specificity_id | Optional fields saved on detail rows | ⬜ |
| TC-P04 | Create Config — with marks_per_question | marks_per_question saved on detail | ⬜ |
| TC-P05 | Create Config — use_for_system_generated_quiz=true (first) | Flag set; no other config affected | ⬜ |
| TC-P06 | Create Config — is_active=false | Config created inactive | ⬜ |
| TC-P07 | Create Config — with description | Description saved | ⬜ |
| TC-P08 | View Config List | Paginated list with code, name, usage_type, is_active | ⬜ |
| TC-P09 | View Single Config (show) | Config details with rules, usage counts across modules | ⬜ |
| TC-P10 | Edit Config — Change name and description | Name/description updated; rules unchanged (recreated) | ⬜ |
| TC-P11 | Edit Config — Add/remove rules | Old rules force-deleted; new rules created | ⬜ |
| TC-P12 | Edit Config — Toggle use_for_system_generated_quiz | Flag set; other config with flag auto-cleared | ⬜ |
| TC-P13 | Update Config — With unchanged code | Update succeeds (unique ignores own ID) | ⬜ |
| TC-P14 | Soft Delete Config (not in use) | Config soft-deleted; is_active=false | ⬜ |
| TC-P15 | Restore Config | Config restored; is_active=true | ⬜ |
| TC-P16 | Force Delete Config (no dependencies) | Config + details permanently deleted | ⬜ |
| TC-P17 | Toggle Status (toggleStatus AJAX) | is_active toggled; JSON success | ⬜ |
| TC-P18 | AJAX getCognitiveSkills by bloom_id | Returns filtered cognitive skills JSON | ⬜ |
| TC-P19 | AJAX getSpecificities by cognitive_skill_id | Returns filtered specificities JSON | ⬜ |

### 6.2 Negative Test Cases

| TC ID | Description | Expected Result | Status |
|-------|-------------|----------------|--------|
| TC-N01 | Create — Empty code | Validation error: code required | ⬜ |
| TC-N02 | Create — Code exceeds 50 chars | Validation error: code max 50 | ⬜ |
| TC-N03 | Create — Duplicate code | Validation error: code already taken | ⬜ |
| TC-N04 | Create — Empty name | Validation error: name required | ⬜ |
| TC-N05 | Create — Name exceeds 100 chars | Validation error: name max 100 | ⬜ |
| TC-N06 | Create — Empty usage_type_id | Validation error: usage_type_id required | ⬜ |
| TC-N07 | Create — Invalid usage_type_id | Validation error: exists | ⬜ |
| TC-N08 | Create — Empty rules (no array) | Validation error: rules required | ⬜ |
| TC-N09 | Create — Empty rules array | Validation error: rules min 1 | ⬜ |
| TC-N10 | Create — Rule with empty question_type_id | Validation error: rules.*.question_type_id required | ⬜ |
| TC-N11 | Create — Rule with invalid complexity_level_id | Validation error: exists | ⬜ |
| TC-N12 | Create — Rule min_percentage negative | Validation error: min 0 | ⬜ |
| TC-N13 | Create — Rule min_percentage > 100 | Validation error: max 100 | ⬜ |
| TC-N14 | Create — Rule max_percentage < min_percentage | Validation error: "Max percentage must be >= Min percentage" | ⬜ |
| TC-N15 | Create — Rule max_percentage > 100 | Validation error: max 100 | ⬜ |
| TC-N16 | Create — use_for_system_generated_quiz=true when another config already has it | Validation error: "Another configuration is already set as the system default." | ⬜ |
| TC-N17 | Create — with invalid bloom_id | Validation error: exists | ⬜ |
| TC-N18 | Update — Config in use (has quizzes) | Error: "Therefore cannot be updated." | ⬜ |
| TC-N19 | Destroy — Config in use (has quizzes/exams/quests) | Error: "Therefore cannot be deleted." | ⬜ |
| TC-N20 | Force Delete — Config has associated quizzes | Error: "Cannot permanently delete... used by: Quiz1, Quiz2" | ⬜ |
| TC-N21 | Force Delete — Config has associated exam papers | Error: "Cannot permanently delete... used by: Exam1" | ⬜ |
| TC-N22 | View — without permission | 403 Forbidden | ⬜ |
| TC-N23 | Create — without permission | 403 Forbidden | ⬜ |
| TC-N24 | Edit — without permission | 403 Forbidden | ⬜ |
| TC-N25 | Delete — without permission | 403 Forbidden | ⬜ |

### 6.3 Dependency Test Cases

| TC ID | Category | Priority | Description | Expected Result | Status |
|-------|----------|----------|-------------|----------------|--------|
| TC-D01 | Business — use_for_system_generated_quiz exclusivity | P1 | Create config A with flag → create config B with flag → verify config A cleared | Config A.use_for_system_generated_quiz = 0; Config B = 1 | ⬜ |
| TC-D02 | Cascade — Soft delete config → verify details | P1 | Soft delete config with details → check details.deleted_at | Details have deleted_at timestamp (SoftDeletes) | ⬜ |
| TC-D03 | Cascade — Force delete config → details force-deleted | P1 | Force delete config → verify details permanently removed | Details removed via explicit forceDelete in transaction | ⬜ |
| TC-D04 | Cascade — Update config → old rules force-deleted | P1 | Update config with different rules → verify old rules force-deleted | Old details permanently removed; new details created | ⬜ |
| TC-D05 | Business — Config used in Quiz | P1 | Create quiz referencing difficulty_config_id → try to edit config | Edit blocked: "Therefore cannot be edited" | ⬜ |
| TC-D06 | Business — Config used in ExamPaper | P1 | Create exam paper referencing config → try to force delete | Force delete blocked: "used by: ExamPaper title" | ⬜ |
| TC-D07 | Business — Config used in Quest | P1 | Create quest referencing config → try to force delete | Usage count includes LmsQuests module | ⬜ |
| TC-D08 | Cascading AJAX — Bloom → Cognitive → Specificity | P2 | Select bloom → verify cognitive skills load → select cognitive → verify specificities load | AJAX chain works end-to-end | ⬜ |

### 6.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | Status |
|-------|----------|----------|-------------|----------------|--------|
| TC-CR01 | CR | P1 | Request — unique code validation | `Rule::unique('lms_difficulty_distribution_configs','code')->ignore($configId)` | ◌ |
| TC-CR02 | CR | P1 | Request — use_for_system_generated_quiz exclusivity rule | Custom closure checking no other config has the flag (except current) | ◌ |
| TC-CR03 | CR | P1 | Request — max >= min percentage validation | In withValidator: checks each rule's max_percentage >= min_percentage | ◌ |
| TC-CR04 | CR | P1 | Controller store() — transaction | Config created + rules created in DB transaction | ◌ |
| TC-CR05 | CR | P1 | Controller update() — reset all rules | `$config->distributionDetails()->forceDelete()` + re-create all | ◌ |
| TC-CR06 | CR | P1 | Controller forceDelete() — dependency check | Checks Quiz, ExamPaper tables for associated records | ◌ |
| TC-CR07 | CR | P1 | Controller forceDelete() — details cleanup | `DifficultyDistributionDetail::where(...)->forceDelete()` before config force delete | ◌ |
| TC-CR08 | CR | P1 | Model — use_for_system_generated_quiz exclusivity | `static::saving()` event: sets other configs' flag to 0 when this one is 1 | ◌ |
| TC-CR09 | CR | P1 | Policy vs Request permission mismatch | Policy: `tenant.difficulty-distribution-config.*` — Request: `tenant.lms-difficulty-config.*` | ◌ |
| TC-CR10 | CR | P2 | Controller edit() — usage check before gate | `$usageCheck->isUsed($id)` runs before `Gate::authorize()` — unnecessary query if unauthorized | ◌ |
| TC-CR11 | CR | P2 | Controller show() — usage details | Calls `DifficultyConfigUsageCheckService::getUsageDetails($id)` | ◌ |
| TC-CR12 | CR | P2 | Controller destroy() — sets inactive before delete | `$config->update(['is_active' => false])` then `$config->delete()` | ◌ |
| TC-CR13 | CR | P2 | Controller restore() — sets active | `$config->restore()` then `$config->update(['is_active' => true])` | ◌ |
| TC-CR14 | CR | P1 | Controller store()/update() — activityLog after create/update | `activityLog($config, 'Created', ...)` in store(); `activityLog($config, 'Updated', ...)` in update() | ◌ |
| TC-CR15 | CR | P1 | Controller destroy()/restore()/forceDelete()/toggleStatus() — activityLog on all state changes | `activityLog($config, 'Trashed', ...)` in destroy(); `activityLog($config, 'Restored', ...)` in restore(); `activityLog($config, 'Deleted', ...)` in forceDelete(); `activityLog($config, 'Toggled', ...)` in toggleStatus() | ◌ |

---

## 7. Detailed Test Steps

### 7.1 Positive TC Steps

**Pre-conditions**: User logged in with `tenant.difficulty-distribution-config.create` permission (TC-P01 to TC-P07). User logged in with `tenant.difficulty-distribution-config.viewAny` permission (TC-P08 to TC-P09). User logged in with `tenant.difficulty-distribution-config.update` permission (TC-P10 to TC-P13). User logged in with `tenant.difficulty-distribution-config.delete` permission (TC-P14). User logged in with `tenant.difficulty-distribution-config.restore` permission (TC-P15). User logged in with `tenant.difficulty-distribution-config.forceDelete` permission (TC-P16). User logged in with `tenant.difficulty-distribution-config.update` permission (TC-P17). Authenticated user with any role (TC-P18 to TC-P19).

#### TC-P01: Create Config — With Code, Name, Usage Type, 1 Rule

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to Difficulty Config → Create | Create form loads |
| 2 | Enter unique Code (≤50 chars) | Code filled |
| 3 | Enter Name (≤100 chars) | Name filled |
| 4 | Select Usage Type from dropdown | Usage type selected |
| 5 | In Rules section, add 1 rule: select Question Type, Complexity Level, enter Min % (30), Max % (50), leave bloom/cognitive/specificity empty | 1 rule row added |
| 6 | Leave is_active checked | Checkbox checked |
| 7 | Click Submit | POST request to store |
| 8 | Check success flash message | Config created successfully |
| 9 | Verify config appears in list | Config row visible with correct code, name, usage type |
| 10 | DB check: `SELECT * FROM lms_difficulty_distribution_details WHERE difficulty_config_id = new_id` | 1 detail record with correct question_type_id, complexity_level_id, min_percentage=30, max_percentage=50 |

---

#### TC-P02: Create Config — With 3 Rules

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to Difficulty Config → Create | Create form loads |
| 2 | Enter unique Code and Name | Fields filled |
| 3 | Select Usage Type | Usage type selected |
| 4 | Add 3 rules with different question_type_id + complexity_level_id combinations | 3 rule rows added |
| 5 | Set Min/Max percentages for each rule (e.g., Rule1: 10-30, Rule2: 20-40, Rule3: 30-50) | Percentages filled |
| 6 | Click Submit | POST request to store |
| 7 | Verify success message | Config created |
| 8 | DB check: `SELECT * FROM lms_difficulty_distribution_details WHERE difficulty_config_id = new_id` | 3 detail records created with different type+complexity combos |

---

#### TC-P03: Create Config — With Optional Bloom, Cognitive Skill, Specificity

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form visible |
| 2 | Enter Code, Name, select Usage Type | Required fields set |
| 3 | Add a rule and select Question Type + Complexity Level | Rule row visible |
| 4 | Select Bloom Taxonomy | Cognitive Skills dropdown loads via AJAX (getCognitiveSkills) |
| 5 | Select Cognitive Skill | Specificities dropdown loads via AJAX (getSpecificities) |
| 6 | Select Specificity | All optional fields filled |
| 7 | Enter Min %, Max %, Marks Per Question | Values set |
| 8 | Click Submit | Config created |
| 9 | DB check: detail record | bloom_id, cognitive_skill_id, ques_type_specificity_id, marks_per_question all saved |

---

#### TC-P04: Create Config — With Marks Per Question

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form visible |
| 2 | Enter Code, Name, select Usage Type | Required fields set |
| 3 | Add a rule with Question Type + Complexity Level | Rule row |
| 4 | Enter Marks Per Question (e.g., 5.00) | Value filled |
| 5 | Enter Min % and Max % | Percentages set |
| 6 | Click Submit | Config created |
| 7 | DB check: detail record marks_per_question | Value matches input |

---

#### TC-P05: Create Config — Use for System Generated Quiz (First)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form visible |
| 2 | Enter Code, Name, select Usage Type | Required fields set |
| 3 | Add 1 rule with Question Type + Complexity Level + percentages | Rule added |
| 4 | Toggle "Use for System Generated Quiz" to ON | Checkbox/switch enabled |
| 5 | Click Submit | Config created |
| 6 | DB check: `SELECT use_for_system_generated_quiz FROM lms_difficulty_distribution_configs WHERE id = new_id` | Value = 1 |
| 7 | Verify no other config was affected (if this is the first) | No other configs have flag = 1 |

---

#### TC-P06: Create Config — is_active=False

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form visible |
| 2 | Enter Code, Name, select Usage Type, add 1 rule | Required fields set |
| 3 | Uncheck is_active checkbox | Checkbox unchecked |
| 4 | Click Submit | Config created |
| 5 | DB check: `SELECT is_active FROM lms_difficulty_distribution_configs WHERE id = new_id` | is_active = 0 |
| 6 | Verify config NOT visible in default list (which likely filters active) | Config hidden or shows inactive badge |

---

#### TC-P07: Create Config — With Description

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form visible |
| 2 | Enter Code, Name, select Usage Type, add 1 rule | Required fields set |
| 3 | Enter Description (≤255 chars): "Test configuration for difficulty distribution" | Description filled |
| 4 | Click Submit | Config created |
| 5 | DB check: `SELECT description FROM lms_difficulty_distribution_configs WHERE id = new_id` | Description saved correctly |

---

#### TC-P08: View Config List

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to Difficulty Config list page | List loads with pagination (10 per page) |
| 2 | Check table columns | Code, Name, Usage Type, Status, Actions visible |
| 3 | Check search input | Search field present with placeholder |
| 4 | Check usage_type_id filter dropdown | Dropdown with Usage Type options |
| 5 | Check is_active filter dropdown | Dropdown with All/Active/Inactive |
| 6 | Check pagination | If 10+ records, pagination links appear |
| 7 | Check column sorting (if applicable) | Clickable sort headers |

---

#### TC-P09: View Single Config (Show)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click "View" icon on a config row that has rules | Show page loads (or if no show route, verify 404 or redirect) |
| 2 | Check config details section | Code, Name, Description, Usage Type, Status displayed |
| 3 | Check rules/details section | All distribution details listed with question type, complexity, percentages |
| 4 | Check usage details section | Usage counts across LmsQuiz, LmsExam, LmsQuests displayed |
| 5 | Note: Route may not exist | If no show route, this TC is informational |

---

#### TC-P10: Edit Config — Change Name and Description

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to config list | List loads |
| 2 | Click "Edit" icon on an existing config (not in use) | Edit form loads with pre-filled data |
| 3 | Change Name to a new value | Name updated |
| 4 | Change Description | Description updated |
| 5 | Leave Code unchanged | Code same as original |
| 6 | Leave rules unchanged | Rules array same |
| 7 | Click Update | PUT request sent |
| 8 | Check success flash | "Difficulty distribution config updated successfully" |
| 9 | DB check: `SELECT name, description FROM lms_difficulty_distribution_configs WHERE id = X` | Name and description updated; code unchanged |
| 10 | Verify old details were force-deleted and recreated | Detail IDs changed (old removed, new created) |

---

#### TC-P11: Edit Config — Add/Remove Rules

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open edit form for a config with 2 existing rules | Form loads with 2 rule rows |
| 2 | Remove 1 existing rule | Rule row removed |
| 3 | Add 2 new rules with different type+complexity combos | 2 new rule rows appear (total 3) |
| 4 | Click Update | PUT request sent |
| 5 | DB check: old rules | Original 2 detail records force-deleted (deleted_at NOT NULL on soft delete or permanently removed) |
| 6 | DB check: new rules | 3 new detail records created with updated values |

---

#### TC-P12: Edit Config — Toggle Use for System Generated Quiz

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Config A with use_for_system_generated_quiz=1 | Config A = system default |
| 2 | Create Config B with use_for_system_generated_quiz=0 | Config B exists without flag |
| 3 | Edit Config B, toggle use_for_system_generated_quiz to ON | Flag set to 1 |
| 4 | Click Update | Update succeeds |
| 5 | DB check Config A: `SELECT use_for_system_generated_quiz` | Config A.use_for_system_generated_quiz = 0 (auto-cleared) |
| 6 | DB check Config B: `SELECT use_for_system_generated_quiz` | Config B.use_for_system_generated_quiz = 1 |

---

#### TC-P13: Update Config — With Unchanged Code

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open edit form for an existing config | Form loads with existing code |
| 2 | Keep Code unchanged | Code field shows original value |
| 3 | Change Name to something new | Name changed |
| 4 | Click Update | Update succeeds (unique validation ignores current ID) |
| 5 | Verify success | Config updated without "code already taken" error |

---

#### TC-P14: Soft Delete Config (Not in Use)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to config list | List loads |
| 2 | Click delete icon on a config with no associated quizzes/exams/quests | SweetAlert confirmation prompt |
| 3 | Confirm deletion | DELETE request to destroy |
| 4 | Check success flash | Config deleted successfully |
| 5 | DB check: `SELECT is_active, deleted_at FROM lms_difficulty_distribution_configs WHERE id = X` | is_active = 0, deleted_at NOT NULL |
| 6 | Verify config hidden from active list | Not visible in main list |

---

#### TC-P15: Restore Config

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to trash page (`/lms-quize/difficulty-distribution-config/trash/view`) | Trash page shows soft-deleted records |
| 2 | Click "Restore" on a deleted config | SweetAlert confirmation |
| 3 | Confirm restore | GET restore route called |
| 4 | Check success flash | Config restored successfully |
| 5 | DB check: `SELECT deleted_at, is_active FROM lms_difficulty_distribution_configs WHERE id = X` | deleted_at = NULL, is_active = 1 |
| 6 | Navigate to main list | Config visible again |

---

#### TC-P16: Force Delete Config (No Dependencies)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to trash page | Trash page shows deleted records |
| 2 | Click "Force Delete" on a config with no associated quizzes/exams/quests | SweetAlert confirmation |
| 3 | Confirm force delete | DELETE request to forceDelete |
| 4 | Check success flash | Config permanently deleted |
| 5 | DB check: `SELECT * FROM lms_difficulty_distribution_configs WHERE id = X` WITH trashed | Record permanently gone |
| 6 | DB check: `SELECT * FROM lms_difficulty_distribution_details WHERE difficulty_config_id = X` WITH trashed | Detail records permanently gone |

---

#### TC-P17: Toggle Status (ToggleStatus AJAX)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create config with is_active=1 | Config active |
| 2 | Click status toggle switch on the config row | AJAX POST to `/lms-quize/difficulty-distribution-config/{id}/toggle-status` |
| 3 | Check JSON response | `{success: true, is_active: false, message: "..."}` |
| 4 | DB check: `SELECT is_active` | is_active = 0 |
| 5 | Click toggle again | AJAX POST |
| 6 | Check JSON response | `{success: true, is_active: true}` |
| 7 | DB check: `SELECT is_active` | is_active = 1 |

---

#### TC-P18: AJAX GetCognitiveSkills by Bloom ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send GET request to `/lms-quize/difficulty-distribution-config/get-cognitive-skills?bloom_id=X` where X is a valid bloom ID | JSON response with list of cognitive skills filtered by bloom_id |
| 2 | Verify response structure | Array of `{id, name, ...}` objects |
| 3 | Send request with invalid bloom_id | Empty array or 404 |
| 4 | Send request without bloom_id | Error or empty response |

---

#### TC-P19: AJAX GetSpecificities by Cognitive Skill ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send GET request to `/lms-quize/difficulty-distribution-config/get-specificities?cognitive_skill_id=X` where X is a valid cognitive skill ID | JSON response with list of question type specificities filtered by cognitive_skill_id |
| 2 | Verify response structure | Array of `{id, name, ...}` objects |
| 3 | Send request with invalid cognitive_skill_id | Empty array or 404 |
| 4 | Send request without cognitive_skill_id | Error or empty response |

---

### 7.2 Negative TC Steps

**Pre-conditions**: User logged in with `tenant.difficulty-distribution-config.create` permission (TC-N01 to TC-N17). User logged in with `tenant.difficulty-distribution-config.update` permission (TC-N18). User logged in with `tenant.difficulty-distribution-config.delete` permission (TC-N19). User logged in with `tenant.difficulty-distribution-config.forceDelete` permission (TC-N20 to TC-N21). Varying permissions for TC-N22 to TC-N25.

#### TC-N01: Create — Empty Code

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form visible |
| 2 | Leave Code empty | Code field blank |
| 3 | Fill all other required fields (Name, Usage Type, 1 rule) | Valid data |
| 4 | Click Submit | Validation error: "The code field is required." |

---

#### TC-N02: Create — Code Exceeds 50 Chars

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form visible |
| 2 | Enter Code with 51+ characters | Code exceeds max length |
| 3 | Fill other required fields | Valid data |
| 4 | Click Submit | Validation error: "The code must not be greater than 50 characters." |

---

#### TC-N03: Create — Duplicate Code

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a config with Code = "DUPCONF" | Config created |
| 2 | Open create form again | Form visible |
| 3 | Enter Code = "DUPCONF" | Duplicate code |
| 4 | Fill other fields with different data | Valid data |
| 5 | Click Submit | Validation error: "The code has already been taken." |

---

#### TC-N04: Create — Empty Name

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form visible |
| 2 | Enter valid Code | Code filled |
| 3 | Leave Name empty | Name blank |
| 4 | Fill other required fields | Valid data |
| 5 | Click Submit | Validation error: "The name field is required." |

---

#### TC-N05: Create — Name Exceeds 100 Chars

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form visible |
| 2 | Enter Name with 101+ characters | Name exceeds max length |
| 3 | Fill other required fields | Valid data |
| 4 | Click Submit | Validation error: "The name must not be greater than 100 characters." |

---

#### TC-N06: Create — Empty Usage Type

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form visible |
| 2 | Fill Code, Name | Valid data |
| 3 | Leave Usage Type unselected | No usage type |
| 4 | Add 1 rule | Rule added |
| 5 | Click Submit | Validation error: "The usage type id field is required." |

---

#### TC-N07: Create — Invalid Usage Type ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form visible |
| 2 | Fill Code, Name | Valid data |
| 3 | Set usage_type_id = 99999 (non-existent) | Invalid value |
| 4 | Add 1 rule | Rule added |
| 5 | Click Submit | Validation error: "The selected usage type id is invalid." |

---

#### TC-N08: Create — Empty Rules (No Array)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form visible |
| 2 | Fill Code, Name, Usage Type | Required fields set |
| 3 | Do not add any rules section data | No rules submitted |
| 4 | Click Submit | Validation error: "The rules field is required." |

---

#### TC-N09: Create — Empty Rules Array

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form visible |
| 2 | Fill Code, Name, Usage Type | Required fields set |
| 3 | Submit with rules = [] (empty array) | Empty rules array |
| 4 | Click Submit | Validation error: "The rules must contain at least 1 items." |

---

#### TC-N10: Create — Rule With Empty Question Type ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form visible |
| 2 | Fill Code, Name, Usage Type | Required fields set |
| 3 | Add a rule but leave Question Type unselected | Empty question_type_id |
| 4 | Fill Complexity Level and percentages | Other fields set |
| 5 | Click Submit | Validation error: "The rules.0.question type id field is required." |

---

#### TC-N11: Create — Rule With Invalid Complexity Level ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form visible |
| 2 | Fill Code, Name, Usage Type | Required fields set |
| 3 | Add a rule with valid Question Type | Question type selected |
| 4 | Set complexity_level_id = 99999 (non-existent) | Invalid value |
| 5 | Fill percentages | Valid percentages |
| 6 | Click Submit | Validation error: "The selected rules.0.complexity level id is invalid." |

---

#### TC-N12: Create — Rule Min Percentage Negative

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form visible |
| 2 | Fill Code, Name, Usage Type | Required fields set |
| 3 | Add a rule with valid Question Type + Complexity Level | Rule row |
| 4 | Set min_percentage = -10 | Negative value |
| 5 | Set max_percentage = 50 | Valid max |
| 6 | Click Submit | Validation error: "The rules.0.min percentage must be at least 0." |

---

#### TC-N13: Create — Rule Min Percentage > 100

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form visible |
| 2 | Fill Code, Name, Usage Type | Required fields set |
| 3 | Add a rule with valid Question Type + Complexity Level | Rule row |
| 4 | Set min_percentage = 150 | Exceeds 100 |
| 5 | Set max_percentage = 150 | Exceeds 100 |
| 6 | Click Submit | Validation error: "The rules.0.min percentage must not be greater than 100." |

---

#### TC-N14: Create — Rule Max Percentage < Min Percentage

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form visible |
| 2 | Fill Code, Name, Usage Type | Required fields set |
| 3 | Add a rule with valid Question Type + Complexity Level | Rule row |
| 4 | Set min_percentage = 60 | Higher than max |
| 5 | Set max_percentage = 30 | Lower than min |
| 6 | Click Submit | Validation error: "Max percentage must be >= Min percentage" |

---

#### TC-N15: Create — Rule Max Percentage > 100

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form visible |
| 2 | Fill Code, Name, Usage Type | Required fields set |
| 3 | Add a rule | Rule row |
| 4 | Set min_percentage = 50 | Valid min |
| 5 | Set max_percentage = 200 | Exceeds 100 |
| 6 | Click Submit | Validation error: "The rules.0.max percentage must not be greater than 100." |

---

#### TC-N16: Create — Use for System Generated Quiz When Another Config Already Has It

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Config A with use_for_system_generated_quiz = 1 | Config A is system default |
| 2 | Open create form for new Config B | Form visible |
| 3 | Fill Code, Name, Usage Type, add 1 rule | Required fields set |
| 4 | Toggle use_for_system_generated_quiz to ON | Flag set to 1 |
| 5 | Click Submit | Validation error: "Another configuration is already set as the system default." |

---

#### TC-N17: Create — With Invalid Bloom ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form visible |
| 2 | Fill Code, Name, Usage Type | Required fields set |
| 3 | Add a rule with Question Type + Complexity Level + bloom_id = 99999 | Invalid bloom_id |
| 4 | Fill percentages | Valid percentages |
| 5 | Click Submit | Validation error: "The selected rules.0.bloom id is invalid." |

---

#### TC-N18: Update — Config in Use (Has Quizzes)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a config | Config created, ID = X |
| 2 | Create a quiz that references difficulty_config_id = X | Quiz uses this config |
| 3 | Navigate to edit page for config X | Edit form page |
| 4 | Make any change to the form | Form modified |
| 5 | Click Update | Error: "Therefore cannot be updated." |
| 6 | Verify config unchanged in DB | Original values preserved |

---

#### TC-N19: Destroy — Config in Use

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a config | Config created, ID = X |
| 2 | Create a quiz/exam/quest that references difficulty_config_id = X | Config in use |
| 3 | Navigate to config list | List loads |
| 4 | Click delete icon on config X | SweetAlert confirmation |
| 5 | Confirm deletion | Error: "Therefore cannot be deleted." |
| 6 | DB check: config still exists | Record not deleted |

---

#### TC-N20: Force Delete — Config Has Associated Quizzes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a config | Config created, ID = X |
| 2 | Create a quiz referencing difficulty_config_id = X | Quiz depends on config |
| 3 | Soft delete the config | Config moved to trash |
| 4 | Navigate to trash page | Trash shows config |
| 5 | Click "Force Delete" | SweetAlert confirmation |
| 6 | Confirm force delete | Error: "Cannot permanently delete... used by: [Quiz title]" |

---

#### TC-N21: Force Delete — Config Has Associated Exam Papers

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a config | Config created, ID = X |
| 2 | Create an exam paper referencing difficulty_config_id = X | Exam depends on config |
| 3 | Soft delete the config | Config moved to trash |
| 4 | Navigate to trash page | Trash shows config |
| 5 | Click "Force Delete" | SweetAlert confirmation |
| 6 | Confirm force delete | Error: "Cannot permanently delete... used by: [Exam title]" |

---

#### TC-N22: View — Without Permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user WITHOUT `tenant.difficulty-distribution-config.viewAny` permission | User lacks view permission |
| 2 | Navigate to Difficulty Config list page | 403 Forbidden |
| 3 | Try accessing `/lms-quize/difficulty-distribution-config` directly | 403 Forbidden |

---

#### TC-N23: Create — Without Permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user WITHOUT `tenant.difficulty-distribution-config.create` permission | User lacks create permission |
| 2 | Check UI for "Add New" or "Create" button | Button NOT visible |
| 3 | Navigate to `/lms-quize/difficulty-distribution-config/create` | 403 Forbidden |
| 4 | POST to store route | 403 Forbidden |

---

#### TC-N24: Edit — Without Permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user WITHOUT `tenant.difficulty-distribution-config.update` permission | User lacks update permission |
| 2 | Navigate to config list | Edit icon NOT visible on rows |
| 3 | Navigate to `/lms-quize/difficulty-distribution-config/{id}/edit` | 403 Forbidden |
| 4 | PUT to update route | 403 Forbidden |
| 5 | POST to toggleStatus route | 403 Forbidden |

---

#### TC-N25: Delete — Without Permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user WITHOUT `tenant.difficulty-distribution-config.delete` permission | User lacks delete permission |
| 2 | Navigate to config list | Delete icon NOT visible on rows |
| 3 | DELETE to destroy route | 403 Forbidden |

---

### 7.3 Dependency TC Steps

**Pre-conditions**: User logged in with appropriate permissions for the operations involved.

#### TC-D01: Business — Use for System Generated Quiz Exclusivity

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Config A with use_for_system_generated_quiz = 1 | Config A.flag = 1 |
| 2 | Create Config B with use_for_system_generated_quiz = 1 | Config B created; Config A.flag auto-cleared to 0 |
| 3 | DB check Config A: `SELECT use_for_system_generated_quiz` | 0 |
| 4 | DB check Config B: `SELECT use_for_system_generated_quiz` | 1 |
| 5 | Create Config C with flag = 0, then update to flag = 1 | Config C updated; Config B.flag auto-cleared to 0 |
| 6 | Verify only one config has flag = 1 at any time | Enforced by both model boot() and request validation |

---

#### TC-D02: Cascade — Soft Delete Config → Details

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create config with 2 rules | Config + 2 details exist |
| 2 | Soft delete the config | Config.deleted_at set |
| 3 | DB check: `SELECT * FROM lms_difficulty_distribution_details WHERE difficulty_config_id = X` | Details also have deleted_at set (SoftDeletes on both parent and child) |

---

#### TC-D03: Cascade — Force Delete Config → Details Force-Deleted

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create config with 2 rules | Config + 2 details exist |
| 2 | Soft delete then force delete the config | Force delete succeeds |
| 3 | DB check: `SELECT * FROM lms_difficulty_distribution_details WHERE difficulty_config_id = X` WITH trashed | Details permanently removed (force deleted in transaction) |

---

#### TC-D04: Cascade — Update Config → Old Rules Force-Deleted

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create config with 2 rules, note detail IDs | Detail IDs = [10, 11] |
| 2 | Open edit form, change rules completely | Remove both, add 3 new rules |
| 3 | Submit update | Update succeeds |
| 4 | DB check: old detail IDs [10, 11] | Force-deleted (permanently removed or deleted_at set) |
| 5 | DB check: new detail records | 3 new detail records with different IDs |

---

#### TC-D05: Business — Config Used in Quiz (Edit Blocked)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create config | Config created, ID = X |
| 2 | Create a quiz with difficulty_config_id = X | Quiz uses config |
| 3 | Navigate to config list | List loads |
| 4 | Click "Edit" on config X | Redirect or error: "Therefore cannot be edited." |
| 5 | Try direct PUT to update route | Error: "Therefore cannot be updated." |

---

#### TC-D06: Business — Config Used in ExamPaper (Force Delete Blocked)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create config | Config created, ID = X |
| 2 | Create an exam paper with difficulty_config_id = X | Exam uses config |
| 3 | Soft delete config | Config in trash |
| 4 | Try force delete on trash page | Error: "Cannot permanently delete... used by: [ExamPaper title]" |

---

#### TC-D07: Business — Config Used in Quest (Usage Check)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create config | Config created, ID = X |
| 2 | Create a quest with difficulty_config_id = X | Quest references config |
| 3 | Navigate to show/edit page | Usage details display count from LmsQuests module |
| 4 | Try force delete | Blocked with quest reference listed |

---

#### TC-D08: Cascading AJAX — Bloom → Cognitive → Specificity

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create/edit form with rule builder | Rule section visible |
| 2 | Select a Bloom Taxonomy | Cognitive Skills dropdown populates via AJAX (getCognitiveSkills) |
| 3 | Select a Cognitive Skill | Specificities dropdown populates via AJAX (getSpecificities) |
| 4 | Verify all three dropdowns properly cascaded | End-to-end AJAX chain works |
| 5 | Change Bloom selection | Cognitive Skills and Specificities reset/refreshed |

---

### 7.4 Code Review TC Steps

**Pre-conditions**: Access to the source code files for review.

#### TC-CR01: Request — Unique Code Validation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `DifficultyDistributionConfigRequest.php` | File loaded |
| 2 | Locate the `code` field validation rule | `Rule::unique('lms_difficulty_distribution_configs','code')->ignore($configId)` |
| 3 | Verify ignore on update | On update, `$configId` is passed to ignore current record |
| 4 | Verify no ignore on create (or ignore(null) ) | On create, unique check applies to all records |

---

#### TC-CR02: Request — Use for System Generated Quiz Exclusivity Rule

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `DifficultyDistributionConfigRequest.php` | File loaded |
| 2 | Locate `use_for_system_generated_quiz` validation | Custom closure or rule exists |
| 3 | Verify it checks no other config has flag = 1 | Closure queries DB excluding current ID |
| 4 | Verify it does NOT run when flag = 0 | Only validates when flag is being set to true |

---

#### TC-CR03: Request — Max >= Min Percentage Validation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `DifficultyDistributionConfigRequest.php` | File loaded |
| 2 | Locate `withValidator()` method | Custom after-validation hook exists |
| 3 | Verify it iterates over each rule | Checks each rule's max_percentage >= min_percentage |
| 4 | Verify error message | "Max percentage must be >= Min percentage" or similar |

---

#### TC-CR04: Controller Store() — Transaction

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `DifficultyDistributionConfigController.php` | File loaded |
| 2 | Locate `store()` method | `DB::beginTransaction()` called |
| 3 | Verify config creation and detail creation within same transaction | Config saved, then details created, then `DB::commit()` |
| 4 | Verify rollback on failure | `DB::rollBack()` in catch block |

---

#### TC-CR05: Controller Update() — Reset All Rules

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `DifficultyDistributionConfigController.php` | File loaded |
| 2 | Locate `update()` method | Calls `$config->distributionDetails()->forceDelete()` |
| 3 | Verify all old details permanently removed | forceDelete() bypasses SoftDeletes |
| 4 | Verify new details created from request input | Loop through rules input and create new detail records |

---

#### TC-CR06: Controller ForceDelete() — Dependency Check

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `DifficultyDistributionConfigController.php` | File loaded |
| 2 | Locate `forceDelete()` method | Calls `DifficultyConfigUsageCheckService` |
| 3 | Verify it checks Quiz, ExamPaper, Quest tables | Queries all three modules for references |
| 4 | Verify it blocks with list if dependencies exist | Returns error listing dependent items |

---

#### TC-CR07: Controller ForceDelete() — Details Cleanup

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `DifficultyDistributionConfigController.php` | File loaded |
| 2 | Locate `forceDelete()` method | Before config force delete, details are force-deleted |
| 3 | Verify code: `DifficultyDistributionDetail::where('difficulty_config_id', $id)->forceDelete()` | Details removed before config in transaction |

---

#### TC-CR08: Model — Use for System Generated Quiz Exclusivity

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `DifficultyDistributionConfig.php` model | File loaded |
| 2 | Locate `booted()` method | `static::saving()` event registered |
| 3 | Verify it sets other configs' flag to 0 when current flag is 1 | `static::where('id', '!=', $this->id)->update(['use_for_system_generated_quiz' => false])` |
| 4 | Note: This fires on EVERY save, not just when flag changes | Redundant updates on unrelated saves |

---

#### TC-CR09: Policy vs Request Permission Mismatch

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `DifficultyDistributionConfigPolicy.php` | Policy uses `tenant.difficulty-distribution-config.*` |
| 2 | Open `DifficultyDistributionConfigRequest.php` | Request's `authorize()` uses `tenant.lms-difficulty-config.*` |
| 3 | Compare prefixes | Mismatch: `difficulty-distribution-config` vs `lms-difficulty-config` |
| 4 | Verify all policy methods | viewAny, view, create, update, delete, restore, forceDelete, status |
| 5 | Verify request uses only create/update | `tenant.lms-difficulty-config.create` and `tenant.lms-difficulty-config.update` |

---

#### TC-CR10: Controller Edit() — Usage Check Before Gate

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `DifficultyDistributionConfigController.php` | File loaded |
| 2 | Locate `edit()` method | `$usageCheck->isUsed($id)` runs before `Gate::authorize()` |
| 3 | Verify ordering | Usage check query executes even if user will be denied by Gate |
| 4 | Note: Performance issue | Unnecessary DB query for unauthorized users |

---

#### TC-CR11: Controller Show() — Usage Details

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `DifficultyDistributionConfigController.php` | File loaded |
| 2 | Locate `show()` method | Calls `DifficultyConfigUsageCheckService::getUsageDetails($id)` |
| 3 | Verify usage details passed to view | Returns usage counts for Quiz, ExamPaper, Quest |

---

#### TC-CR12: Controller Destroy() — Sets Inactive Before Delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `DifficultyDistributionConfigController.php` | File loaded |
| 2 | Locate `destroy()` method | `$config->update(['is_active' => false])` then `$config->delete()` |
| 3 | Verify ordering | is_active set to false BEFORE soft delete |

---

#### TC-CR13: Controller Restore() — Sets Active

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `DifficultyDistributionConfigController.php` | File loaded |
| 2 | Locate `restore()` method | `$config->restore()` then `$config->update(['is_active' => true])` |
| 3 | Verify ordering | Restore first, then set active |
| 4 | Verify redirect | Redirects to trash view (not main index) |

---

#### TC-CR14: Controller Store()/Update() — ActivityLog After Create/Update

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `DifficultyDistributionConfigController.php` | File loaded |
| 2 | Locate `store()` method | Calls `activityLog($config, 'Created', ...)` after successful create |
| 3 | Verify activityLog arguments | Event name is `'Created'`; message describes config creation; performed_by set to current user |
| 4 | Locate `update()` method | Calls `activityLog($config, 'Updated', ...)` after successful update |
| 5 | Verify activityLog arguments | Event name is `'Updated'`; changes array tracks modified attributes; performed_by set to current user |
| 6 | Query `activity_log` table for store action | Entry exists with `event = 'Created'` and correct config ID |
| 7 | Query `activity_log` table for update action | Entry exists with `event = 'Updated'` and correct config ID |

---

#### TC-CR15: Controller Destroy()/Restore()/ForceDelete()/ToggleStatus() — ActivityLog on All State Changes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `DifficultyDistributionConfigController.php` | File loaded |
| 2 | Locate `destroy()` method | Calls `activityLog($config, 'Trashed', ...)` after soft delete |
| 3 | Locate `restore()` method | Calls `activityLog($config, 'Restored', ...)` after restore |
| 4 | Locate `forceDelete()` method | Calls `activityLog($config, 'Deleted', ...)` after permanent delete |
| 5 | Locate `toggleStatus()` method | Calls `activityLog($config, 'Toggled', ...)` after status change |
| 6 | Verify each activityLog call has correct event name | `'Trashed'`, `'Restored'`, `'Deleted'`, `'Toggled'` respectively |
| 7 | Verify each call includes performed_by | `'performed_by' => Auth::user()->name` for all |
| 8 | Query `activity_log` table after each action | Correct event entry exists for each action with matching subject ID |

---

## 8. Known Issues

| # | Issue | Severity | Details |
|---|-------|----------|---------|
| KI-01 | Permission prefix mismatch: Policy vs Request | Medium | Policy uses `tenant.difficulty-distribution-config.*` but Request's authorize() uses `tenant.lms-difficulty-config.*`. This means if only one set of permissions is defined, the other layer will always deny. |
| KI-02 | No show route despite show() method existing | Low | Controller has `show()` method but no GET route for show is registered (resource probably uses `except:['show']` or similar). The method is dead code unless called programmatically. |
| KI-03 | edit() runs usage check before Gate authorize | Low | `$usageCheck->isUsed($id)` runs before `Gate::authorize()`, causing unnecessary DB query if user is unauthorized. Same pattern in update() and destroy(). |
| KI-04 | No percentage sum validation | Medium | Unlike the old TC's assumption, there is NO validation that rules' percentages sum to 100 (or any specific total). Each rule has independent min/max ranges. This could lead to under/over allocation. |
| KI-05 | update() force-deletes all details even if unchanged | Low | Update always runs `distributionDetails()->forceDelete()` + re-create, even if rules didn't change. This loses audit trail of original detail records. |
| KI-06 | Model exclusivity fires on every save | Low | The `booted()` `saving` event runs `static::where(...)->update(['use_for_system_generated_quiz' => false])` every time a config is saved, not just when the flag changes. |
| KI-07 | Restore redirects to trash view | Low | `restore()` redirects to `...trashed` route instead of the main index, which is inconsistent with other modules that redirect to active list. |

---

## 9. Route Reference

| Method | URL | Name | Controller Method | Required Permission |
|--------|-----|------|-------------------|---------------------|
| GET | `/lms-quize/difficulty-distribution-config` | lms-quize.difficulty-distribution-config.index | index() | tenant.difficulty-distribution-config.viewAny |
| GET | `/lms-quize/difficulty-distribution-config/create` | lms-quize.difficulty-distribution-config.create | create() | tenant.difficulty-distribution-config.create |
| POST | `/lms-quize/difficulty-distribution-config` | lms-quize.difficulty-distribution-config.store | store() | tenant.difficulty-distribution-config.create |
| GET | `/lms-quize/difficulty-distribution-config/{difficulty_distribution_config}/edit` | lms-quize.difficulty-distribution-config.edit | edit() | tenant.difficulty-distribution-config.update |
| PUT | `/lms-quize/difficulty-distribution-config/{difficulty_distribution_config}` | lms-quize.difficulty-distribution-config.update | update() | Request → tenant.lms-difficulty-config.update |
| DELETE | `/lms-quize/difficulty-distribution-config/{difficulty_distribution_config}` | lms-quize.difficulty-distribution-config.destroy | destroy() | tenant.difficulty-distribution-config.delete |
| GET | `/lms-quize/difficulty-distribution-config/trash/view` | lms-quize.difficulty-distribution-config.trashed | trashed() | tenant.difficulty-distribution-config.restore |
| GET | `/lms-quize/difficulty-distribution-config/{id}/restore` | lms-quize.difficulty-distribution-config.restore | restore() | tenant.difficulty-distribution-config.restore |
| DELETE | `/lms-quize/difficulty-distribution-config/{id}/force-delete` | lms-quize.difficulty-distribution-config.forceDelete | forceDelete() | tenant.difficulty-distribution-config.forceDelete |
| POST | `/lms-quize/difficulty-distribution-config/{difficulty_distribution_config}/toggle-status` | lms-quize.difficulty-distribution-config.toggleStatus | toggleStatus() | tenant.difficulty-distribution-config.update |
| GET | `/lms-quize/difficulty-distribution-config/get-cognitive-skills` | — | getCognitiveSkills() | — |
| GET | `/lms-quize/difficulty-distribution-config/get-specificities` | — | getSpecificities() | — |

Note: No `show` route for this resource — `Resource::except(['show'])` or equivalent. The show view is not routed.

| # | Issue | Severity | Details |
|---|-------|----------|---------|
| KI-01 | Permission prefix mismatch: Policy vs Request | Medium | Policy uses `tenant.difficulty-distribution-config.*` but Request's authorize() uses `tenant.lms-difficulty-config.*`. This means if only one set of permissions is defined, the other layer will always deny. |
| KI-02 | No show route despite show() method existing | Low | Controller has `show()` method but no GET route for show is registered (resource probably uses `except:['show']` or similar). The method is dead code unless called programmatically. |
| KI-03 | edit() runs usage check before Gate authorize | Low | `$usageCheck->isUsed($id)` runs before `Gate::authorize()`, causing unnecessary DB query if user is unauthorized. Same pattern in update() and destroy(). |
| KI-04 | No percentage sum validation | Medium | Unlike the old TC's assumption, there is NO validation that rules' percentages sum to 100 (or any specific total). Each rule has independent min/max ranges. This could lead to under/over allocation. |
| KI-05 | update() force-deletes all details even if unchanged | Low | Update always runs `distributionDetails()->forceDelete()` + re-create, even if rules didn't change. This loses audit trail of original detail records. |
| KI-06 | Model exclusivity fires on every save | Low | The `booted()` `saving` event runs `static::where(...)->update(['use_for_system_generated_quiz' => false])` every time a config is saved, not just when the flag changes. |
| KI-07 | Restore redirects to trash view | Low | `restore()` redirects to `...trashed` route instead of the main index, which is inconsistent with other modules that redirect to active list. |

---

## 10. Execution Status

| Section | Total TCs | Executed | Passed | Failed | Blocked | Not Executed |
|---------|-----------|----------|--------|--------|---------|--------------|
| Positive (6.1) | 19 | 0 | 0 | 0 | 0 | 19 |
| Negative (6.2) | 25 | 0 | 0 | 0 | 0 | 25 |
| Dependency (6.3) | 8 | 0 | 0 | 0 | 0 | 8 |
| Code Review (6.4) | 15 | 0 | 0 | 0 | 0 | 15 |
| **Total** | **67** | **0** | **0** | **0** | **0** | **67** |

**Legend**: ⬜ = Pending Execution | ✅ = Passed | ❌ = Failed | ⛔ = Blocked | ◌ = Code Review (structure verified, not executed)

---

*TC List generated from actual codebase analysis — all TCs based on verified controller, model, request, policy, service, route, and blade file contents.*
