# Difficulty Distribution Config — Business Requirements

## What This Screen Does

The Difficulty Distribution Config screen allows academic coordinators to create rules that control how many questions of each difficulty level should appear in a quiz. Think of it as a recipe: it says "for every 10 questions in a quiz, 4 should be Easy, 4 should be Medium, and 2 should be Difficult." These rules help maintain fairness and consistency across assessments.

Each config combines: Question Type (like MCQ_SINGLE, MCQ_MULTI) × Complexity Level (EASY, MEDIUM, DIFFICULT) × optional Taxonomy dimensions (Bloom's Level, Cognitive Skill, Specificity). The system uses these rules when teachers add questions to a quiz — either as strict validation (blocking if violated) or as a warning (allowing with a note).

---

## When This Screen Is Used

- **Start of Academic Year Setup** — Coordinators define standard difficulty rules (e.g., "Balanced", "Easy", "Hard")
- **Curriculum Update** — School changes its assessment strategy (e.g., shifting from 70% Easy to 50% Medium)
- **Auto-Generated Quiz Setup** — Configuring rules for system-generated remedial quizzes (only one config can have this flag)
- **Quiz Creation** — Teachers select a difficulty config when creating quizzes
- **Difficulty Builder** — When adding questions, the system validates against the selected config

## Default Data Load

This screen is a tab within the Quiz Management page (`active_tab=difficulty_config`). When loaded, it displays a paginated list of configs (10 per page) via `QuizQueryService@difficultyConfigsQuery()`. If the tab is NOT active, an empty request is passed (no filters).

**Filters available on index page:**
- `search` — Searches `code` and `name` fields
- `usage_type_id` — Filter by question usage type
- `is_active` — Filter by active/inactive status

---

## Key Fields at a Glance

### Config Header Table (`lms_difficulty_distribution_configs`)
| Field | Type | Details |
|-------|------|---------|
| `code` | varchar(50), UNIQUE | Short identifier like `STD_QUIZ_BALANCED` |
| `name` | varchar(100) | Display name like "Standard Quiz Balanced" |
| `description` | text | Optional notes about the config's purpose |
| `usage_type_id` | FK → `qns_question_usage_type` | Links to QUIZ, QUEST, ONLINE_EXAM, OFFLINE_EXAM |
| `use_for_system_generated_quiz` | boolean, EXCLUSIVE | Only ONE config can have this TRUE at a time |
| `is_active` | boolean | Enable/disable toggle |

### Distribution Details Table (`lms_difficulty_distribution_details`)
Each config has MANY detail rows. Each row defines one "bucket":

| Field | Required | Details |
|-------|----------|---------|
| `question_type_id` | YES | FK → `slb_question_types` (MCQ_SINGLE, MCQ_MULTI, etc.) |
| `complexity_level_id` | YES | FK → `slb_complexity_level` (EASY, MEDIUM, DIFFICULT) |
| `bloom_id` | Optional | FK → `slb_bloom_taxonomy` |
| `cognitive_skill_id` | Optional | FK → `slb_cognitive_skill` |
| `ques_type_specificity_id` | Optional | FK → `slb_ques_type_specificity` |
| `min_percentage` | YES | Minimum % of total questions from this bucket |
| `max_percentage` | YES | Maximum % of total questions from this bucket |
| `marks_per_question` | YES | Marks assigned to each question in this bucket |
| `is_active` | YES | Enable/disable this bucket |

---

## Complete Validation Flow Before Save

This section explains every check the system performs — in plain language — for each operation on a Difficulty Config. Difficulty configs are the "recipe" that controls what mix of Easy/Medium/Hard questions a quiz should have.

---

### [A] Creating a New Config (Save)

When an academic coordinator fills the form and clicks Save, here's what happens:

**Step 1 — Permission Check**
Does this user have permission to create difficulty configs?
- If No → Access Denied
- If Yes → Proceed

**Step 2 — Form Validation**
Did the coordinator fill in everything correctly?
- `code`: Required. A short identifier like "STD_QUIZ_BALANCED". Must be unique — no other config can have the same code
- `name`: Required. Display name like "Standard Quiz Balanced"
- `usage_type_id`: Required. What type of assessment this config applies to (Quiz, Online Exam, etc.)
- `rules`: At least one rule is required. Each rule needs: question_type, complexity_level, min_percentage, max_percentage, marks_per_question
If anything is wrong → Show validation error and stop

**Step 3 — System-Generated Quiz Exclusivity Check**
The system checks the "Use for System Generated Quiz" checkbox:
- If it's checked → The system AUTOMATICALLY un-checks this flag on ALL other configs
- **Why?** Only ONE config can be the default for auto-generated quizzes

**Step 4 — Create the Config**
The system saves the config header (code, name, description, etc.) and then saves ALL the rules you defined.

**Real Example:**
> Shail creates a config called "STD_QUIZ_BALANCED" with 3 rules:
> - Easy → 30-40%, 2 marks each
> - Medium → 30-40%, 3 marks each
> - Difficult → 15-25%, 5 marks each
> She also checks "Use for System Generated Quiz"
> System saves the config and 3 rules. If another config called "STD_QUIZ_EASY" had the system-generated flag, it gets auto-unchecked.

**Step 5 — Log + Redirect**
The system logs this action (who created what) and redirects back with success message.

---

### [B] Opening a Config for Editing (Edit Load)

When a coordinator clicks "Edit" on an existing config:

**Step 1 — Usage Check**
The system asks: "Is this config currently being used by any quiz?"
- Checks if any quiz has this `difficulty_config_id`
- If YES → **BLOCKED**. Coordinator sees: *"This config is used in: Science Quiz, Math Quiz, English Quiz. Therefore cannot be edited."*
- **Why?** If a config is already in use, editing it could change the rules mid-way, affecting quizzes that were already set up. The coordinator must first remove the config from those quizzes, then edit.

**Step 2 — Permission Check**
Does user have permission to edit configs?

**Step 3 — Load the Data**
If the config is not used → Load all the config's data (header + all rules) into the edit form, along with dropdown options for editing.

---

### [C] Saving Changes to a Config (Update)

When a coordinator clicks Update on an existing config:

**Step 1 — Usage Check** (same as Edit)
If used → BLOCKED

**Step 2 — Update Header + Replace All Rules**
The system:
1. Updates the header fields (code, name, etc.)
2. **DELETES ALL existing rules**
3. **CREATES brand new rules** from what the coordinator just submitted
4. Re-checks the system-generated exclusivity

**Why does it delete and re-create rules?**
Because it's simpler and safer than figuring out which rules changed. The coordinator is expected to submit the COMPLETE set of rules every time.

**Step 3 — Change Detection**
The system checks: "What changed in the header?"
- Compares old vs new values
- Records only meaningful changes (e.g., name changed from "Old Name" to "New Name")
- Doesn't track rule-level changes since rules are fully replaced

**Step 4 — Log + Redirect**
Who changed what → record in activity log → redirect with success

---

### [D] Soft Deleting a Config (Delete)

When a coordinator clicks Delete:

**Step 1 — Usage Check**
If any quiz uses this config → **BLOCKED**: *"Cannot delete this config as it is being used by 5 quiz(es)."*

**Step 2 — Permission Check**

**Step 3 — Soft Delete**
- Sets `is_active = false` (config is disabled)
- Sets `deleted_at` timestamp (soft deleted — can be restored)

**Why soft delete instead of permanent?**
In case a coordinator accidentally deletes a config, it can be restored. Also, quizzes that reference this config won't break — the reference remains valid even though the config is "deleted."

---

### [E] Permanently Deleting a Config (Force Delete)

When a coordinator force-deletes from the trash:

**Step 1 — Dependency Check**
The system checks: "Is this config referenced by any Quiz OR ExamPaper?"
- If YES → **BLOCKED**: *"Cannot permanently delete this configuration as it is used by: Science Quiz, Math Quiz. Please remove these dependencies first."*
- Lists up to 3 dependent items (with "and others" if more)

**Step 2 — Permanent Deletion**
If no dependencies:
- Permanently deletes ALL rule rows for this config
- Permanently deletes the config itself
- This CANNOT be undone

---

### [F] Restoring a Deleted Config (Restore)

When a coordinator restores from trash:
- System finds the soft-deleted config
- Restores it (clears `deleted_at`)
- Sets `is_active = true`
- Logs the action

---

### [G] Toggling Active/Inactive (AJAX Toggle)

When a coordinator clicks the active/inactive toggle:
- System checks permission
- Flips the `is_active` flag
- Returns JSON success
- No usage check here — you can disable a config even if quizzes are using it (they'll just keep their existing rules but can't be re-validated)

---

---

## AJAX Cascade Endpoints

### getCognitiveSkills(Request) — GET
| Parameter | Required |
|-----------|----------|
| `bloom_id` | YES |

Returns: `{ success: true, skills: [{id, name}] }` — filtered to active, ordered by name

### getSpecificities(Request) — GET
| Parameter | Required |
|-----------|----------|
| `cognitive_skill_id` | YES |

Returns: `{ success: true, specs: [{id, name}] }` — filtered to active, ordered by name

---

## System Generated Exclusivity — Model Logic

The `DifficultyDistributionConfig::booted() saving` event:

```
WHEN use_for_system_generated_quiz === true:
  → DifficultyDistributionConfig::where('id', '!=', $this->id)
    → where('use_for_system_generated_quiz', true)
    → update(['use_for_system_generated_quiz' => false])
  → This happens AUTOMATICALLY before save, in the same transaction

WHEN use_for_system_generated_quiz === false:
  → No action — other configs with the flag remain unchanged
```

---

## Validations (DifficultyDistributionConfigRequest)

| Field | Rules | Notes |
|-------|-------|-------|
| `code` | required, string, max:50, unique:lms_difficulty_distribution_configs | Unique at DB level |
| `name` | required, string, max:100 | — |
| `description` | nullable, string | — |
| `usage_type_id` | required, exists:qns_question_usage_type,id | — |
| `is_active` | boolean | — |
| `use_for_system_generated_quiz` | boolean | Exclusive enforced at model level |
| `rules` | nullable, array | Array of detail rows |
| `rules.*.question_type_id` | required_with:rules, exists:slb_question_types,id | — |
| `rules.*.complexity_level_id` | required_with:rules, exists:slb_complexity_level,id | — |
| `rules.*.bloom_id` | nullable, exists:slb_bloom_taxonomy,id | Optional |
| `rules.*.cognitive_skill_id` | nullable, exists:slb_cognitive_skill,id | Optional |
| `rules.*.ques_type_specificity_id` | nullable, exists:slb_ques_type_specificity,id | Optional |
| `rules.*.min_percentage` | required_with:rules, numeric, 0-100 | — |
| `rules.*.max_percentage` | required_with:rules, numeric, 0-100 | — |
| `rules.*.marks_per_question` | required_with:rules, numeric, min:0 | — |
| `rules.*.is_active` | boolean | — |

---

## How Validation Works When a Teacher Adds Questions to a Quiz

This is the most important section to understand. A Difficulty Config is just a set of rules sitting in the database — it only becomes active when a teacher selects it on a quiz AND starts adding questions. Think of the config as the **law** and the question-addition flow as the **police officer** enforcing it.

### The Two Settings on a Quiz That Control This

When a teacher creates a quiz, they see two settings:

| Quiz Setting | What It Does |
|-------------|--------------|
| **Difficulty Config** (dropdown) | Which rule-set to use. Pick one like "Balanced" or "Easy Only" |
| **Ignore Difficulty Config** (checkbox) | OFF = **Strict Mode** — rules are enforced, violations BLOCK the addition. ON = **Warning Mode** — rules are checked but violations just show a warning |

### How the Quiz Links to the Config

The quiz stores:
- `difficulty_config_id = 5` (points to "Balanced" config)
- `ignore_difficulty_config = false` (strict mode)

When a teacher adds questions to this quiz, the system:
1. Sees `difficulty_config_id` is set → activates validation
2. Loads the config's rules
3. For each batch of new questions, checks: "Do these questions fit within the rules?"

---

### Mode 1: SIMPLE — When Rules Have NO Extra Taxonomy

Rules are simple: they only specify (Question Type × Complexity Level).

**Example Config — "Balanced" (Simple Rules):**

| Rule | Question Type | Complexity | Min % | Max % | Marks |
|------|--------------|------------|-------|-------|-------|
| 1 | MCQ_SINGLE | EASY | 30% | 40% | 2 |
| 2 | MCQ_SINGLE | MEDIUM | 30% | 40% | 3 |
| 3 | MCQ_SINGLE | DIFFICULT | 20% | 30% | 5 |

This means: In ANY quiz using this config, Easy questions should be 30-40% of total, Medium 30-40%, Difficult 20-30%.

**How the Math Works — Step by Step:**

> **Quiz:** "Science Test" has total_questions = 10
> **Config:** "Balanced" with the rules above
> **Current quiz state:** 2 Easy, 2 Medium, 1 Difficult already added (5 total)

**Step 1** — System calculates how many questions are allowed for each group:
| Group | Max % | Calculation | Max Allowed |
|-------|-------|-------------|-------------|
| Easy | 40% | ceil(10 × 40 ÷ 100) = ceil(4.0) | **4** |
| Medium | 40% | ceil(10 × 40 ÷ 100) = ceil(4.0) | **4** |
| Difficult | 30% | ceil(10 × 20 ÷ 100) = ceil(2.0) | **2** |

**Step 2** — Teacher tries to add 3 more Easy questions:
- Already have: 2 Easy
- Adding: 3 Easy
- Total would be: 2 + 3 = **5**
- Max allowed: **4**
- 5 > 4 → **VIOLATION**

**Result in Strict Mode:** *"Cannot add 3 questions. Max allowed: 4, Existing: 2. Limit exceeded for rule: MCQ_SINGLE - Easy"* → Questions NOT added

**Result in Warning Mode:** Questions ADDED but teacher sees warning: *"Question added. However, difficulty rule was violated: [same message]"*

**What If a Question Type Doesn't Match Any Rule?**

> Teacher has a config with rules only for MCQ_SINGLE
> Teacher tries to add an MCQ_MULTI question
> System can't find a matching rule → **BLOCKED**: *"Questions with Type ID: X and Complexity ID: Y do not match any rule"*

---

### Mode 2: COMPLEX — When Rules HAVE Extra Taxonomy

Rules include optional fields: Bloom's Taxonomy Level, Cognitive Skill, Question Type Specificity. Each question must match ALL specified fields.

**Example Config — "Bloom-Based" (Complex Rules):**

| Rule | Q Type | Com-plexity | Bloom | Cog Skill | Specificity | Min% | Max% | Marks |
|------|--------|-------------|-------|-----------|-------------|------|------|-------|
| 1 | MCQ_SINGLE | EASY | Remember | Recall | — | 15% | 25% | 2 |
| 2 | MCQ_SINGLE | EASY | Understand | Explain | — | 15% | 25% | 2 |
| 3 | MCQ_SINGLE | MEDIUM | Apply | Solve | — | 20% | 30% | 3 |

**How Matching Works — Each question is checked against ALL criteria:**

A question is: MCQ_SINGLE + EASY + Bloom=Remember + Cog Skill=Recall + Specificity=null
- Rule 1: MCQ_SINGLE ✓, EASY ✓, Bloom=Remember ✓, Cog Skill=Recall ✓, Specificity=null (wildcard — matches anything) ✓
- → **MATCH with Rule 1**

A question is: MCQ_SINGLE + EASY + Bloom=Analyze + Cog Skill=Compare + Specificity=null
- Rule 1: Bloom=Remember ≠ Analyze ✗
- Rule 2: Bloom=Understand ≠ Analyze ✗
- Rule 3: Complexity=MEDIUM ≠ EASY ✗
- → **NO MATCH — BLOCKED**: *"Question with Type ID: 1 and Complexity ID: 1 does not match any rule"*

**What About Wildcards?**
When a rule has a null field (like `specificity_id IS NULL`), that field is WILDCARD — it matches ANY value. So a rule that says "MCQ_SINGLE + EASY + Bloom=Remember + (any cog skill) + (any specificity)" will match any EASY MCQ_SINGLE with Bloom=Remember, regardless of cog skill or specificity.

---

### Summary of All Possible Outcomes

| Scenario | Ignore Config = OFF (Strict) | Ignore Config = ON (Warning) |
|----------|------------------------------|------------------------------|
| Questions fit within all rules | ✅ Questions added | ✅ Questions added |
| No matching rule for a question type | ❌ BLOCKED — no match | ⚠️ Added with warning |
| Exceeds max % for a group | ❌ BLOCKED — limit exceeded | ⚠️ Added with warning |
| No difficulty config selected | No validation occurs | No validation occurs |

---

## Workflow Steps

### Creating a New Config
1. Navigate to Quiz Management → "Difficulty Distribution Config" tab → Click "Add New"
2. Fill: Code (e.g., `STD_QUIZ_BALANCED`), Name, Description, select Usage Type
3. Check "Use for System Generated Quiz" if this should be the default for auto-generated quizzes (will un-set any other config that had this flag)
4. In the Rules section, add rows:
   - Select Question Type, Complexity Level
   - Optionally select Bloom Taxonomy → AJAX loads Cognitive Skills → AJAX loads Specificities
   - Set Min% and Max%
   - Set Marks Per Question
5. Click Save → system validates, creates config + all rules, logs activity

### Editing a Config
1. Click "Edit" on any row
2. If config is used by quizzes → BLOCKED with message "This config is used in: Quiz A, Quiz B. Therefore cannot be edited."
3. If unused → edit form loads with all header fields + existing detail rows
4. Modify fields, add/remove/modify rules
5. Click Update → system DELETES ALL existing rules, RE-CREATES them from form input

### Deleting a Config
1. Click "Delete" on any row
2. If config is used by quizzes → BLOCKED with message "Cannot delete this config as it is being used by N quiz(es)."
3. If unused → soft delete (sets is_active=false, deleted_at=presents)

### Force Deleting
1. From trash list, click "Force Delete"
2. System checks if any Quiz or ExamPaper uses this config
3. If dependencies found → BLOCKED with list: "Cannot permanently delete this configuration as it is used by: [Quiz names]. Please remove these dependencies first."
4. If no dependencies → permanently deletes config + all detail rows

---

## Example Scenarios

**SC-001 — Create Balanced Config (Non-Technical)**
Shail, the Academic Coordinator, creates a config called "STD_QUIZ_BALANCED" to ensure every quiz has a fair mix of question difficulties. She adds 3 rules:
- Rule 1: MCQ-SINGLE × EASY → Min 30%, Max 40%, 2 marks per question
- Rule 2: MCQ-SINGLE × MEDIUM → Min 30%, Max 40%, 3 marks per question
- Rule 3: MCQ-SINGLE × DIFFICULT → Min 15%, Max 25%, 5 marks per question
She clicks Save. The system creates the config and 3 detail rows in a transaction.

**SC-002 — System Generated Exclusivity**
Shail sets "Use for System Generated Quiz" on STD_QUIZ_BALANCED. The system automatically un-checks this flag on any other config that had it. Now auto-generated remedial quizzes will use STD_QUIZ_BALANCED.

**SC-003 — Edit Config with Taxonomy (Non-Technical)**
Shail edits STD_QUIZ_BALANCED to add taxonomy-based rules. She selects Bloom Taxonomy level "Remember" → system loads Cognitive Skills → she selects "Recall" → system loads Specificities → she selects "Definition Recall". She sets Min 10%, Max 20%. When she clicks Update, the system deletes all 3 old rules and creates 4 new rules (3 original + 1 new taxonomy rule).

**SC-004 — Delete Blocked by Usage (Non-Technical)**
Shail tries to delete STD_QUIZ_HARD. The system shows: "Cannot delete this config as it is being used by 5 quiz(es)." She must first remove the difficulty config from those 5 quizzes before deleting.

**SC-005 — Force Delete Blocked with Exam Dependencies**
Shail force-deletes STD_QUIZ_EASY. The system checks: Quiz module finds 0 dependencies. ExamPaper module finds 2 exam papers using this config. System blocks: "Cannot permanently delete this configuration as it is used by: Midterm Exam, Final Exam. Please remove these dependencies first."

**SC-006 — Config Applied to Quiz (Non-Technical Flow)**
Teacher creates a quiz with `total_questions=10`. She selects STD_QUIZ_BALANCED as the difficulty config. When adding 10 questions via difficulty builder:
- She tries to add 6 Easy MCQ-SINGLE questions. Rule says max 40% of 10 = 4. 6 > 4. BLOCKED (if ignore_difficulty_config=false) or ALLOWED WITH WARNING (if ignore_difficulty_config=true).

**SC-007 — AJAX Cascade: Bloom → Cognitive Skill → Specificity**
Shail selects Bloom "Analyze" → system calls getCognitiveSkills(bloom_id) → loads "Compare", "Differentiate", "Organize", "Attribute" in the Cognitive Skill dropdown. She selects "Compare" → system calls getSpecificities(cognitive_skill_id) → loads "Venn Diagram", "Comparison Table".

**SC-008 — Update with Change Detection**
Shail renames STD_QUIZ_BALANCED to "Standard Quiz Balanced v2" and changes min_percentage on the first rule from 30% to 25%. System detects:
- name: old="Standard Quiz Balanced" → new="Standard Quiz Balanced v2"
- Also all rules were re-created (due to delete+insert pattern)
Activity log records the name change.

---

## Business Rules Summary

| # | Rule | Enforced At | Behavior |
|---|------|-------------|----------|
| 1 | Unique `code` | DB unique index `uq_diff_config_code` | Duplicate blocked with validation error |
| 2 | `use_for_system_generated_quiz` exclusivity | Model `booted() saving` event | Auto-un-sets other configs |
| 3 | Edit blocked if config is referenced by Quiz | `edit()` + `update()` via DifficultyConfigUsageCheckService | Redirect with error listing dependent quizzes |
| 4 | Delete blocked if referenced by Quiz | `destroy()` via DifficultyConfigUsageCheckService | Back with error listing count |
| 5 | Force delete blocked if referenced by Quiz OR ExamPaper | `forceDelete()` | Back with dependency names |
| 6 | Update resets ALL detail rows | `update()` | forceDelete all → re-create from input |
| 7 | Soft delete sets is_active=false | `destroy()` | Before calling ->delete() |
| 8 | Restore sets is_active=true | `restore()` | After calling ->restore() |
| 9 | Details CASCADE on force delete | `forceDelete()` | forceDelete details before config |
| 10 | Difficulty builder validates at runtime | QuizQuestionController → validateDifficultyDistribution() | Block or warn per ignore_difficulty_config |

---

## Error Messages Reference

| Scenario | Message | HTTP Code |
|----------|---------|-----------|
| Duplicate code | "A difficulty distribution config with this code already exists." | 422 |
| Edit blocked | "[usage message] Therefore cannot be edited." | Redirect |
| Update blocked | "[usage message] Therefore cannot be updated." | Redirect |
| Delete blocked | "[usage message] Therefore cannot be deleted." | Redirect |
| Force delete blocked | "Cannot permanently delete this configuration as it is used by: [names]. Please remove these dependencies first." | Redirect |
| Store exception | "[exception message]" | Redirect with input |
| Update exception | "[exception message]" | Redirect with input |
| Delete exception | "Failed to delete configuration: [message]" | Redirect |
| AJAX cascade error | JSON 500 with message | AJAX |

---

## Requirements

**Controller:** `Modules\LmsQuiz\Http\Controllers\DifficultyDistributionConfigController`
**Model:** `DifficultyDistributionConfig` (table: `lms_difficulty_distribution_configs`, soft deletes)
**Child Model:** `DifficultyDistributionDetail` (table: `lms_difficulty_distribution_details`)
**Requests:** `DifficultyDistributionConfigRequest`
**Policy:** `DifficultyDistributionConfigPolicy`
**Usage Check:** `DifficultyConfigUsageCheckService`

**Controller Methods:**

| Method | Type | Gate | Key Behavior |
|--------|------|------|-------------|
| `index()` | GET | viewAny | List with search/usage_type/is_active filters, paginate 10 |
| `create()` | GET | create | Load form with usage types, question types, complexity levels, taxonomy dropdowns |
| `store()` | POST | create | Transactional: create header + detail rows, exclusivity enforcement, activity log |
| `show($id)` | GET | view | Load config + details + usage details |
| `edit($id)` | GET | update | Block if used; load config + details + dropdowns |
| `update()` | PUT | update | Block if used; transactional update + delete-reinsert details + change detection |
| `destroy($id)` | DELETE | delete | Block if used; soft delete + deactivate |
| `trashed()` | GET | restore | List onlyTrashed configs |
| `restore($id)` | GET | restore | Restore + reactivate |
| `forceDelete($id)` | DELETE | forceDelete | Dependency check (Quiz + ExamPaper); force delete details + config |
| `toggleStatus()` | AJAX POST | update | JSON toggle of is_active |
| `getCognitiveSkills()` | AJAX GET | — | Cascade: bloom_id → cognitive skills |
| `getSpecificities()` | AJAX GET | — | Cascade: cognitive_skill_id → specificities |

---

## Dependencies

| Dependency | Type | Details |
|-----------|------|---------|
| `lms_difficulty_distribution_configs` | Primary | Config header with soft deletes |
| `lms_difficulty_distribution_details` | Child | Detail rows (force-deleted on parent forceDelete) |
| `qns_question_usage_type` | FK | usage_type_id |
| `slb_question_types` | FK | question_type_id in details |
| `slb_complexity_level` | FK | complexity_level_id in details |
| `slb_bloom_taxonomy` | FK | bloom_id in details (optional) |
| `slb_cognitive_skill` | FK | cognitive_skill_id in details (optional) |
| `slb_ques_type_specificity` | FK | ques_type_specificity_id in details (optional) |
| `lms_quizzes` | Consumer | difficulty_config_id FK — blocks edit/delete if referenced |
| `lms_exam_papers` (ExamPaper) | Consumer (external module) | difficulty_config_id FK — blocks forceDelete if referenced |
