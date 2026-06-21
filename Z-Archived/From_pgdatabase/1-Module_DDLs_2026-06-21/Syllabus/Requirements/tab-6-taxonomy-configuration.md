# Syllabus Tab 6: Taxonomy Configuration

This tab manages the question taxonomy framework used by the assessment module. It defines how questions are classified across five dimensions: Bloom's taxonomy level, cognitive skill, question type specificity, complexity level, and question type format. These classifications drive balanced exam paper generation and student skill gap analysis.

---

## How It Works

The screen presents five sub-sections, one for each taxonomy dimension.

The Bloom's Taxonomy section lists the six levels: Remembering, Understanding, Applying, Analyzing, Evaluating, and Creating. Each has a numeric level (1-6), a code, and a description. This is system-seeded data that schools can view but typically should not modify.

The Cognitive Skills section lists granular skills that fall under each Bloom's level. For example, under Remembering there might be Recall and Interpretation skills. Each cognitive skill links to a parent Bloom's level. Schools can add custom cognitive skills if needed.

The Question Type Specificity section defines the context in which a question type is used — such as In-Class, Homework, Summative, or Formative. Each specificity can optionally link to a cognitive skill. For example, "Assertion-Reason" specificity might be linked to the Analyzing cognitive skill.

The Complexity Level section manages difficulty ratings: Easy, Medium, Difficult. Each has a numeric complexity value (1-3) and an active flag.

The Question Types section defines the actual question format — MCQ Single Answer, MCQ Multi Answer, Short Answer, Long Answer, Match, Numeric, Fill Blank, Coding. Each type has a flag for whether it has options (MCQ does, Short Answer does not) and whether it is auto-gradable. System-defined question types are marked as `is_system = 1` and cannot be edited by schools.

---

## Important Business Rules

- Bloom's taxonomy levels are system-defined and read-only for schools. Codes are unique: REMEMBERING, UNDERSTANDING, APPLYING, ANALYZING, EVALUATING, CREATING.
- Cognitive skills must have a unique code. They optionally link to a Bloom's level (SET NULL on bloom delete).
- Question type specificity codes must be unique. They optionally link to a cognitive skill.
- Complexity levels must have unique codes. The numeric complexity_level (1-3) is used by the adaptive testing engine.
- Question types with `has_options = 1` render option-based input components; those with `has_options = 0` render open input fields.
- Question types with `auto_gradable = 1` can be automatically scored by the system. Types with `auto_gradable = 0` require manual teacher grading.
- System question types (`is_system = 1`) are seeded by PG Team and cannot be deleted or edited by schools. Schools can add their own custom question types with `is_system = 0`.
- All tables support soft deletes. Deactivating a taxonomy item prevents it from being used in new questions but existing questions retain their classification.

---

## Database Columns & Behavior

### slb_bloom_taxonomy
- `id` — Primary key. INT UNSIGNED AUTO_INCREMENT.
- `code` — Unique level code. VARCHAR(20). Example: REMEMBERING, UNDERSTANDING. Unique constraint.
- `name` — Display name. VARCHAR(100).
- `description` — Explanation. VARCHAR(255), nullable.
- `bloom_level` — Numeric 1-6. TINYINT UNSIGNED, nullable.
- `is_active` — Active flag. TINYINT(1), default 1.

### slb_cognitive_skill
- `id` — Primary key. INT UNSIGNED AUTO_INCREMENT.
- `bloom_id` — FK to slb_bloom_taxonomy. INT UNSIGNED, nullable. SET NULL on delete.
- `code` — Unique code. VARCHAR(20). Example: COG-KNOWLEDGE. Unique constraint.
- `name` — Display name. VARCHAR(100).
- `description` — Explanation. VARCHAR(255), nullable.
- `is_active` — Active flag. TINYINT(1), default 1.

### slb_ques_type_specificity
- `id` — Primary key. INT UNSIGNED AUTO_INCREMENT.
- `cognitive_skill_id` — FK to slb_cognitive_skill. INT UNSIGNED, nullable. SET NULL on delete.
- `code` — Unique code. VARCHAR(20). Example: IN_CLASS, HOMEWORK. Unique constraint.
- `name` — Display name. VARCHAR(100).
- `description` — Explanation. VARCHAR(255), nullable.
- `is_active` — Active flag. TINYINT(1), default 1.

### slb_complexity_level
- `id` — Primary key. INT UNSIGNED AUTO_INCREMENT.
- `code` — Unique code. VARCHAR(20). Example: EASY, MEDIUM, DIFFICULT. Unique constraint.
- `name` — Display name. VARCHAR(50).
- `complexity_level` — Numeric 1-3. TINYINT UNSIGNED, nullable. 1 = Easy, 2 = Medium, 3 = Difficult.
- `is_active` — Active flag. TINYINT(1), default 1.

### slb_question_types
- `id` — Primary key. INT UNSIGNED AUTO_INCREMENT.
- `code` — Unique code. VARCHAR(20). Example: MCQ_SINGLE, SHORT_ANSWER. Unique constraint.
- `name` — Display name. VARCHAR(100).
- `has_options` — Whether this type requires option-based input. TINYINT(1), default 0.
- `auto_gradable` — Whether the system can auto-grade this type. TINYINT(1), default 1.
- `description` — Detailed explanation. TEXT, nullable.
- `is_system` — Whether this is a system-defined type. TINYINT(1), default 1. System types are read-only.
- `is_active` — Active flag. TINYINT(1), default 1.

---

## Deep Analysis

### Business Workflows & State Machines
- **View Taxonomy** — read-only grid of 5 dimensions; schools navigate between sub-sections.
- **Edit Cognitive Skills** — schools can add custom cognitive skills with `code`, `name`, optional `bloom_id` FK.
- **Edit Question Types** — schools can add custom types (`is_system = 0`); system types (`is_system = 1`) are read-only.
- **Toggle Active** — deactivating an item (`is_active = 0`) prevents use in new questions; existing questions retain classification.
- **State machine**: Simple active/inactive toggle; no workflow states.

### Validation Rules & Edge Cases
- **Bloom's taxonomy** — fully system-seeded; codes are UNIQUE; `bloom_level` 1-6 is application-enforced (DB is TINYINT nullable).
- **Cognitive skill** — `code` UNIQUE; optional FK to `slb_bloom_taxonomy` with SET NULL on delete; deactivating a Bloom level does not cascade-delete linked skills.
- **Question type specificity** — `code` UNIQUE; optional FK to `slb_cognitive_skill` with SET NULL.
- **Complexity level** — `complexity_level` 1-3 stored as TINYINT; used by adaptive testing engine—must be sequential.
- **Question types** — `has_options` determines UI component (options vs. open input); `auto_gradable` routes to auto-grading or manual grading pipeline.
- **System vs. custom** — `is_system = 1` rows must be seeded by PG Team; application must prevent DELETE/UPDATE on these rows.
- **Deactivation impact** — existing questions with deactivated taxonomy values are unaffected; only new question creation is blocked.

### Integration Points
- **Assessment module (question bank)** — reads all 5 taxonomy tables for question classification filters.
- **Exam paper generator** — uses Bloom's levels and complexity levels for balanced paper generation.
- **Auto-grading engine** — reads `auto_gradable` flag to determine grading pipeline.
- **Student skill gap analysis** — uses cognitive skill and Bloom's taxonomy data.
- **UI components** — `has_options` drives question renderer (MCQ vs. open text).

### Permissions Matrix
| Role | View All | Edit System Rows | Edit Custom Rows | Toggle Active | Add Custom |
|---|---|---|---|---|---|
| Super Admin | ✅ | ✅ | ✅ | ✅ | ✅ |
| School Admin | ✅ | ❌ | ✅ | ✅ | ✅ |
| Curriculum Coordinator | ✅ | ❌ | ✅ | ✅ | ✅ |
| Teacher | ✅ | ❌ | ❌ | ❌ | ❌ |
| PG Team (DB) | ✅ | ✅ | ✅ | ✅ | ✅ |
| Student/Parent | ❌ | ❌ | ❌ | ❌ | ❌ |
