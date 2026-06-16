# HPC Tab 3: Learning Outcomes

This tab manages the learning outcomes that feed into the Holistic Progress Card. A learning outcome describes what a student should know, understand, or be able to do after completing a lesson or topic. Outcomes are linked to specific curriculum entities (subjects, lessons, or topics), mapped to Bloom's Taxonomy levels, and optionally linked to questions from the question bank for assessment purposes.

---

## How It Works

The main screen lists all learning outcomes in a paginated table. Each row displays the outcome code, a short description, the domain (Cognitive, Affective, or Psychomotor), the Bloom's Taxonomy level, and its active status. The user can search by code or description.

Clicking "Add New" or selecting an existing outcome opens a three-section form. The first section captures the outcome itself — code, description, domain, and Bloom's level. The second section handles entity mapping: the user selects a class, then chooses whether to map this outcome to a subject, a lesson, or a topic. The entity type determines which dropdown appears next. Multiple entity mappings are allowed for a single outcome. The third section links questions from the question bank to this outcome, with an optional weightage value to indicate how much that question contributes to assessing the outcome.

The entity mapping table shows all subjects, lessons, or topics currently linked to the outcome. The question mapping table shows all linked questions along with their weightage. The user can add or remove mappings from either table.

---

## Important Business Rules

- The outcome code must be unique across the entire system. No two outcomes can share the same code.
- A domain must be selected from a predefined system dropdown (Cognitive, Affective, Psychomotor). Cognitive is the default.
- Bloom's Taxonomy level is optional. If provided, it must reference a valid entry in the Bloom's Taxonomy master table.
- The same outcome can be mapped to multiple entity types and multiple entities. For example, one outcome can map to Subject "Science" AND Topic "Photosynthesis."
- An entity mapping combination (outcome_id + entity_type + entity_id) must be unique. Duplicate mappings are rejected.
- A question can be linked to multiple outcomes. The weightage is per outcome-question pair and can be NULL.
- When an outcome is soft-deleted, all its entity and question mappings are also soft-deleted.
- Outcomes cannot be deleted if they are referenced by active student evaluations.

---

## Database Columns & Behavior

### hpc_learning_outcomes
- `id` — Primary key. INT UNSIGNED AUTO_INCREMENT.
- `code` — Unique outcome code, max 50 characters. UNIQUE. VARCHAR(50) NOT NULL.
- `description` — Short description of the outcome. VARCHAR(255) NOT NULL.
- `domain` — FK to sys_dropdown_table. Values include 'COGNITIVE', 'AFFECTIVE', 'PSYCHOMOTOR'. INT UNSIGNED NOT NULL.
- `bloom_id` — FK to slb_bloom_taxonomy. Optional. INT UNSIGNED DEFAULT NULL.
- `level` — Numeric level indicator. TINYINT UNSIGNED, default 1.
- `is_active` — Soft enable/disable flag. TINYINT(1), default 1.

### hpc_outcome_entity_jnt
- `id` — Primary key. INT UNSIGNED AUTO_INCREMENT.
- `outcome_id` — FK to hpc_learning_outcomes. INT UNSIGNED NOT NULL.
- `class_id` — FK to sch_classes. Identifies the class this mapping applies to. INT UNSIGNED NOT NULL.
- `entity_type` — Defines what kind of entity this maps to. ENUM('SUBJECT','LESSON','TOPIC') NOT NULL.
- `entity_id` — The ID of the mapped entity. FK varies based on entity_type (sch_subjects, slb_lessons, or slb_topics). INT UNSIGNED NOT NULL.
- `is_active` — Soft enable/disable flag. TINYINT(1), default 1.

### hpc_outcome_question_jnt
- `id` — Primary key. INT UNSIGNED AUTO_INCREMENT.
- `outcome_id` — FK to hpc_learning_outcomes. INT UNSIGNED NOT NULL.
- `question_id` — FK to qns_questions_bank. INT UNSIGNED NOT NULL.
- `weightage` — Optional decimal weight for this question in assessing the outcome. DECIMAL(5,2). NULL allowed.
- `is_active` — Soft enable/disable flag. TINYINT(1), default 1.

---

## Deep Analysis

### Business Workflows & State Machines
- **Three-step creation workflow:** User creates the outcome (code + description + domain + Bloom's level), then maps it to curriculum entities (subject/lesson/topic), then optionally links assessment questions with weightage. Steps can be done in any order and revisited.
- **Multi-entity mapping:** A single outcome can map to a subject AND a lesson AND a topic simultaneously. Each mapping is a separate row in `hpc_outcome_entity_jnt`. The UI must dynamically switch dropdowns based on `entity_type` selection.
- **Cascading soft delete:** Deleting an outcome must soft-delete all its entity mappings and question mappings. This requires either a DB-level cascade (if supported) or application-level batch update.
- **Outcome-to-Evaluation dependency:** An outcome cannot be soft-deleted if it is referenced by active evaluations. The system must check `hpc_student_evaluation` (or related evaluation tables) before allowing deactivation.

### Validation Rules & Edge Cases
- **Unique code enforcement:** `code` is UNIQUE across the entire system. The UI must show an inline error if the code is already taken.
- **Domain validation:** Domain must be one of COGNITIVE, AFFECTIVE, PSYCHOMOTOR from `sys_dropdown_table`. If the dropdown table is misconfigured, the outcome cannot be created.
- **Bloom's Taxonomy optionality:** `bloom_id` is nullable. When NULL, no Bloom's level is displayed on reports. The UI should indicate this is optional.
- **Entity mapping uniqueness:** (`outcome_id`, `entity_type`, `entity_id`) triple must be unique. The UI should prevent adding the same entity twice.
- **Weightage edge cases:** `weightage` can be NULL (no weighting) or any decimal. The question mapping still works without a weight.
- **Minimal state:** An outcome can exist with zero entity mappings and zero question mappings. The forms must handle empty junction tables gracefully.

### Integration Points
- **`slb_bloom_taxonomy`** — FK to the Bloom's levels master table. If this table is empty, the Bloom's dropdown is disabled.
- **`sch_subjects`, `slb_lessons`, `slb_topics`** — Dynamic FKs based on `entity_type`. The entity resolution is polymorphic.
- **`qns_questions_bank`** — Question mappings source the question bank module. If the question bank module is not installed, this section is hidden.
- **`sys_dropdown_table`** — Domain values configured here. Must seed COGNITIVE, AFFECTIVE, PSYCHOMOTOR.

### Permissions Matrix
| Action | Teacher | Class Teacher | Principal | Admin |
|---|---|---|---|---|
| View outcomes | ✅ | ✅ | ✅ | ✅ |
| Create outcome | ❌ | ❌ | ✅ | ✅ |
| Edit outcome | ❌ | ❌ | ✅ | ✅ |
| Map entities | ❌ | ❌ | ✅ | ✅ |
| Link questions | ❌ | ❌ | ✅ | ✅ |
| Delete outcome | ❌ | ❌ | ✅ | ✅ |
