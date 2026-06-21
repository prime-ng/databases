# Quiz Tab 2: Difficulty Distribution Config

This tab lets teachers set up rules for how many Easy, Medium, and Difficult questions a quiz should have. These rules act as guidelines. When a teacher is building a quiz, the system compares the actual question mix against these rules and warns if the balance seems off.

---

## How It Works

A difficulty configuration is a set of rules. Each rule says: "For questions of this type and this difficulty level, they should make up between X% and Y% of the total quiz." For example, one rule might say "MCQ Single questions at Easy difficulty should be 20% to 30% of all questions." Another might say "MCQ Single at Difficult difficulty should be 10% to 20%."

The teacher creates a configuration by giving it a name, linking it to an assessment type (like Practice or Exam), and then adding individual rules. Each rule specifies the question type, the difficulty level, and optional Bloom's taxonomy and cognitive skill filters. Then the teacher sets a minimum and maximum percentage.

The system checks that the minimum is not higher than the maximum, and that the percentages are between 0 and 100. It also warns if two rules overlap — for example, two rules that both cover "MCQ Single, Easy" would conflict.

---

## How the Rules Are Used

When a teacher later adds questions to a quiz (in Tab 5), the system looks at whether the quiz has a linked difficulty configuration. If it does, it checks the current question mix against the rules and shows a comparison.

If the mix is within the configured ranges, the system shows a green indicator saying everything is fine. If some rules are not met, it shows a yellow warning listing which rules are off and by how much. If the mix is significantly off, it shows a red warning.

Importantly, these warnings do not block the teacher from publishing the quiz. They are informational only. The teacher can decide to ignore the warning and publish anyway.

If a quiz does not have a linked configuration, no difficulty analysis is shown at all. The teacher can add any mix of questions freely.

---

## Important Business Rules

- A configuration can be marked as "Use for System Generated Quizzes." This tells the system to use this configuration when automatically creating remedial quizzes for struggling students. Only one configuration can have this flag active at a time.
- Once a configuration is linked to any quiz, it cannot be deleted. The system blocks deletion with a message: "This configuration is used by X quizzes. Remove it from all quizzes first." The teacher must go to each quiz and unlink the configuration before deleting it.
- Editing a configuration is allowed even if it is linked to quizzes. The changes take effect for any future additions to those quizzes. Existing attempts are not affected.
- A configuration can have as many rules as needed. If it has 20 rules covering every combination of question type and difficulty, that is fine — the system checks all them during validation.
- Overlapping rules are flagged during configuration creation. If two rules cover the same combination of question type, difficulty, and Bloom's level, the system shows a warning but does not block creation. The teacher should resolve overlaps to avoid ambiguous guidance.
- The "Use for System Generated Quizzes" flag is exclusive. If another configuration already has this flag, moving it to a new configuration automatically removes it from the previous one.
- A configuration without any rules is valid but effectively useless — it will not produce any guidance when adding questions.
- The minimum and maximum percentages in a rule can be set to the same value, meaning exactly that percentage is required. For example, a rule with min 25% and max 25% means exactly one quarter of the questions must match this criteria.

---

## Deep Analysis

### Business Workflows & State Machines

**State Machine for Difficulty Config Lifecycle:**

| Current State | Transition | Trigger | Next State | Conditions |
|---|---|---|---|---|
| Draft | Create | Teacher fills form & saves | Active | All required fields provided |
| Active | Link to Quiz | Teacher selects config in Tab 4 | Active (Linked) | Config must be active |
| Active (Linked) | Unlink from Quiz | Teacher removes config in Tab 4 | Active | Config still exists |
| Active | Edit Rules | Teacher modifies rules | Active | Changes apply to future additions only |
| Active | Delete | Teacher clicks delete | — | **Blocked** if linked to any quiz |
| Active (not linked) | Delete | Teacher clicks delete | Deleted | Allowed only if no quizzes reference it |
| Active | Set System Flag | Teacher toggles `use_for_system_generated_quiz` | Active (System) | Flag removed from any previous system config |

**Workflow:**
1. Teacher creates a named configuration linked to an assessment usage type.
2. Teacher adds rules specifying question type, difficulty, optional Bloom's/cognitive skill filters, and min/max percentages.
3. System validates rules (min ≤ max, 0–100%, no hard overlaps).
4. Config becomes available for linking in Tab 4 (Quiz Creation) and Tab 5 (Quiz Questions).
5. When linked to a quiz, the config guides the difficulty distribution check in Tab 5.
6. Config can be edited anytime; linked quizzes pick up changes on next add/remove action.

### Validation Rules & Edge Cases

| Operation/Field | Rule | Error Message |
|---|---|---|
| Config Name | Must be unique across active configs | "A configuration with this name already exists." |
| Config Code | Must be unique | "Configuration code must be unique." |
| Usage Type | Must reference a valid `qns_question_usage_type` | "Invalid usage type selected." |
| Rule – Min % | Must be ≤ Max % | "Minimum percentage cannot exceed maximum percentage." |
| Rule – Min/Max % | Must be between 0 and 100 | "Percentages must be between 0 and 100." |
| Rule – Overlap | Two rules covering same type+difficulty+Bloom's+skill | "Warning: This rule overlaps with an existing rule." |
| Delete Config | Config must not be linked to any quiz | "This configuration is used by X quizzes. Remove it from all quizzes first." |
| System Flag Toggle | Only one config can have this flag | Flag moved automatically from previous config |
| Empty Config (no rules) | Allowed, but produces no guidance | No error — config is valid but produces no checks |
| Rule – Exact Percentage | Min = Max allowed | No error — config requires exactly that percentage |
| Deactivate Config | Linked quizzes unaffected | No error — config hidden from dropdowns but linked quizzes continue working |

### Integration Points

| Module | Table(s) | Foreign Key | Purpose |
|---|---|---|---|
| Quiz Core | `lms_quizzes` | `difficulty_config_id` → `lms_difficulty_distribution_configs.id` | Links a quiz to its difficulty config |
| Quiz Questions | `lms_quiz_questions` | `quiz_id` → `lms_quizzes.id` | Used to compute actual question mix vs config rules |
| Question Bank | `qns_questions_bank` | `id` → `lms_quiz_questions.question_id` | Source of question type, complexity, Bloom's data |
| Question Types | `slb_question_types` | `id` → `lms_difficulty_distribution_details.question_type_id` | Lookup for question type filter |
| Complexity Levels | `slb_complexity_level` | `id` → `lms_difficulty_distribution_details.complexity_level_id` | Lookup for difficulty level filter |
| Bloom's Taxonomy | `slb_bloom_taxonomy` | `id` → `lms_difficulty_distribution_details.bloom_id` | Optional taxonomy filter |
| Cognitive Skills | `slb_cognitive_skill` | `id` → `lms_difficulty_distribution_details.cognitive_skill_id` | Optional skill filter |
| Usage Types | `qns_question_usage_type` | `id` → `lms_difficulty_distribution_configs.usage_type_id` | Determines which question usage type this config applies to |

### Permissions Matrix

| Action | Role | Permission Key |
|---|---|---|
| View Config List | Teacher | `quiz.difficulty-config.view` |
| Create Config | Teacher | `quiz.difficulty-config.create` |
| Edit Config | Teacher | `quiz.difficulty-config.edit` |
| Delete Config | Teacher | `quiz.difficulty-config.delete` |
| Toggle System Flag | Admin/Teacher | `quiz.difficulty-config.set-system-flag` |
| Link Config to Quiz | Teacher | `quiz.difficulty-config.link` |
| View All Configs | Admin | `quiz.difficulty-config.view.all` |

---

## Database Columns & Behavior

### Table: `lms_difficulty_distribution_configs`

| Column | Type | FK | Nullable | Default | Behavior |
|---|---|---|---|---|---|
| `id` | INT UNSIGNED | No | No | AUTO_INCREMENT | Primary key |
| `code` | VARCHAR(50) | No | No | — | Unique code (e.g. STD_QUIZ_EASY) |
| `name` | VARCHAR(100) | No | No | — | Display name |
| `description` | VARCHAR(255) | No | Yes | NULL | Optional description |
| `usage_type_id` | INT UNSIGNED | Yes → `qns_question_usage_type.id` | No | — | Links to question usage type (QUIZ, EXAM, etc.) |
| `is_active` | TINYINT(1) | No | No | 1 | Soft toggle for visibility |
| `use_for_system_generated_quiz` | TINYINT(1) | No | No | 0 | If 1, used for auto-generated remedial quizzes; only one config can have this |
| `created_at` | TIMESTAMP | No | No | CURRENT_TIMESTAMP | Record creation time |
| `updated_at` | TIMESTAMP | No | No | CURRENT_TIMESTAMP ON UPDATE | Last update time |
| `deleted_at` | TIMESTAMP | No | Yes | NULL | Soft-delete timestamp |

### Table: `lms_difficulty_distribution_details`

| Column | Type | FK | Nullable | Default | Behavior |
|---|---|---|---|---|---|
| `id` | INT UNSIGNED | No | No | AUTO_INCREMENT | Primary key |
| `difficulty_config_id` | INT UNSIGNED | Yes → `lms_difficulty_distribution_configs.id` ON DELETE CASCADE | No | — | FK to parent config |
| `question_type_id` | INT UNSIGNED | Yes → `slb_question_types.id` | No | — | Question type filter (MCQ_SINGLE, etc.) |
| `complexity_level_id` | INT UNSIGNED | Yes → `slb_complexity_level.id` | No | — | Difficulty level (EASY, MEDIUM, DIFFICULT) |
| `bloom_id` | INT UNSIGNED | Yes → `slb_bloom_taxonomy.id` | Yes | NULL | Optional Bloom's taxonomy filter |
| `cognitive_skill_id` | INT UNSIGNED | Yes → `slb_cognitive_skill.id` | Yes | NULL | Optional cognitive skill filter |
| `ques_type_specificity_id` | INT UNSIGNED | Yes → `slb_ques_type_specificity.id` | Yes | NULL | Optional question type specificity filter |
| `min_percentage` | DECIMAL(5,2) | No | No | 0.00 | Minimum % of total questions |
| `max_percentage` | DECIMAL(5,2) | No | No | 0.00 | Maximum % of total questions |
| `marks_per_question` | DECIMAL(5,2) | No | Yes | NULL | Optional marks override per question |
| `is_active` | TINYINT(1) | No | No | 1 | Soft-delete flag |
| `created_at` | TIMESTAMP | No | No | CURRENT_TIMESTAMP | Record creation time |
| `updated_at` | TIMESTAMP | No | No | CURRENT_TIMESTAMP ON UPDATE | Last update time |
| `deleted_at` | TIMESTAMP | No | Yes | NULL | Soft-delete timestamp |
