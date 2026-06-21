# Syllabus Tab 3: Topic Hierarchy

This tab enables curriculum designers to break down lessons into granular, hierarchical topics. The hierarchy supports up to 10 levels (Topic → Sub-topic → Mini-topic → Sub-mini-topic → Micro-topic → Sub-micro-topic → Nano-topic → Sub-nano-topic → Ultra-topic → Sub-ultra-topic), enabling extremely fine-grained syllabus mapping.

---

## How It Works

The user selects a class, subject, and then a lesson. Once selected, the topic tree is displayed as an expandable, indented hierarchy. Each node shows the topic name, its auto-generated analytics code, the level type badge, and its ordinal position. The user can expand and collapse branches to navigate the tree.

Creating a new topic requires first selecting the parent node (or the lesson root for a top-level topic). A form appears with fields for the topic name, short name, description, ordinal, weightage in lesson, estimated duration in minutes, learning objectives, keywords, prerequisite topic IDs, and whether the topic is assessable. The level type (Topic, Sub-topic, etc.) is automatically determined based on the depth of the parent: if the parent is level 0, the new topic becomes level 1, and so on.

The system auto-generates two codes for each topic. The `code` is a human-readable path like `9TH_SCI_L01_TOP01_SUB02_MIN01`. The `analytics_code` follows a slightly different format optimized for system tracking. The `code` is user-editable; the `analytics_code` is system-generated and read-only. The materialized `path` stores ancestor IDs (e.g., `/1/5/23/145/`) for fast tree queries, and `path_names` stores the human-readable breadcrumb (e.g., "Algebra > Linear Equations > Solving Methods").

Users can drag and drop topics to reorder them within the same parent. Moving a topic to a different parent changes its level and regenerates its codes. Deleting a parent topic cascades to all descendants.

---

## Important Business Rules

- The maximum hierarchy depth is 10 levels (level 0 through level 9). Attempting to create a topic at level 10 or beyond is rejected.
- The `analytics_code` is system-generated and cannot be modified by users. The `code` can be edited after generation.
- The combination of `lesson_id`, `parent_id`, and `ordinal` must be unique. No two sibling topics can share the same ordinal.
- A topic's `level_id` is determined by its depth: root = parent IS NULL with level_id = 0. Each child increments by 1.
- Deleting a parent topic triggers CASCADE delete on all descendants from the topics table.
- The `path` is automatically maintained: when a topic is moved, all descendant paths are rebuilt.
- If `is_assessable` is set to 0, the topic cannot be linked to questions in the assessment module.
- `release_quiz_on_completion` and `release_quest_on_completion` control automatic release of quiz/quest content when a student marks the topic as completed.
- `prerequisite_topic_ids` is a JSON array of topic IDs that must be completed before this topic.
- `base_topic_id` links to a prerequisite topic from a previous class (e.g., this year's topic builds on last year's topic).

---

## Database Columns & Behavior

### slb_topics
- `id` — Primary key. INT UNSIGNED AUTO_INCREMENT.
- `uuid` — Unique binary identifier for analytics. BINARY(16). Unique constraint.
- `parent_id` — Self-referencing FK for hierarchy. INT UNSIGNED, nullable. CASCADE on delete.
- `lesson_id` — Parent lesson. INT UNSIGNED FK to slb_lessons. CASCADE on delete.
- `class_id` — Denormalized class for fast queries. INT UNSIGNED FK to sch_classes. CASCADE on delete.
- `subject_id` — Denormalized subject for fast queries. INT UNSIGNED FK to sch_subjects. CASCADE on delete.
- `path` — Materialized path of ancestor IDs. VARCHAR(500). Example: `/1/5/23/145/`.
- `path_names` — Human-readable breadcrumb path. VARCHAR(2000), nullable.
- `level_id` — Hierarchy depth level. INT UNSIGNED FK to slb_topic_level_types. RESTRICT on delete.
- `code` — User-editable topic code. VARCHAR(60). Unique constraint.
- `name` — Topic display name. VARCHAR(150) NOT NULL.
- `short_name` — Compact name. VARCHAR(50), nullable.
- `ordinal` — Sort order within the parent. SMALLINT UNSIGNED. Unique per lesson+parent+ordinal.
- `description` — Topic explanation. VARCHAR(255), nullable.
- `weightage_in_lesson` — Weightage percentage within the lesson. DECIMAL(5,2), nullable.
- `duration_minutes` — Estimated teaching time in minutes. INT UNSIGNED, nullable.
- `learning_objectives` — JSON array of objectives. JSON, nullable.
- `keywords` — JSON array of search keywords. JSON, nullable.
- `prerequisite_topic_ids` — JSON array of prerequisite topic IDs. JSON, nullable.
- `base_topic_id` — Prerequisite from a previous class. INT UNSIGNED FK to slb_topics. SET NULL on delete.
- `is_assessable` — Whether the topic can have assessment questions. TINYINT(1), default 1.
- `analytics_code` — System-generated unique code for tracking. VARCHAR(60). Unique constraint.
- `can_use_for_syllabus_status` — Whether topic contributes to syllabus progress. TINYINT(1), default 1.
- `release_quiz_on_completion` — Auto-release quiz on topic completion. TINYINT(1), default 0.
- `release_quest_on_completion` — Auto-release quest on topic completion. TINYINT(1), default 0.
- `is_active` — Soft delete flag. TINYINT(1), default 1.

---

## Deep Analysis

### Business Workflows & State Machines
- **Create Topic** → select parent (or lesson root) → form (name, short_name, description, ordinal, weightage, duration, objectives, keywords, prerequisites, assessable flag) → auto-detect `level_id` = parent.level + 1 → auto-generate `code` and `analytics_code` → compute materialized `path` and `path_names` → INSERT.
- **Edit Topic** → pre-filled form → validate name/ordinal scoped to `(lesson_id, parent_id)` → UPDATE.
- **Delete Topic** → CASCADE delete all descendants via `parent_id` FK → soft delete not cascaded through FK (DB uses physical CASCADE); hard delete at DB level.
- **Move / Reorder** → drag & drop → update `parent_id` (changes level) → regenerate `code`, `analytics_code`, `path`, `path_names` → rebuild all descendant paths recursively.
- **State machine**: Topic is ACTIVE or HARD-DELETED (no soft delete for children; parent deletion is physical CASCADE).

### Validation Rules & Edge Cases
- **Depth cap** — reject if `(SELECT level FROM slb_topic_level_types WHERE id = parent.level_id) + 1 > 9`.
- **Ordinal uniqueness** — `uq_topic_parent_ordinal` composite key `(lesson_id, parent_id, ordinal)`.
- **Code uniqueness** — `uq_topic_code` and `uq_topic_analytics_code` both UNIQUE; `code` editable; `analytics_code` read-only system-generated.
- **Move to different lesson** — cross-lesson move must set `lesson_id`; must rebuild entire subtree path.
- **Self-referencing parent** — `parent_id` cannot equal `id`; circular references guarded at app layer.
- **Base topic** — `base_topic_id` FK must reference a topic from a prior academic session; SET NULL on delete.
- **Assessable flag** — if `is_assessable = 0`, assessment module must block question linking at app layer.
- **Large tree rebuild** — moving a deep topic with 1000+ descendants triggers recursive path update; use queue for async processing.

### Integration Points
- `slb_lessons` — parent lesson; CASCADE delete.
- `slb_topic_level_types` — level_id determines code prefix and release permissions.
- `slb_topic_competency_jnt` — child mappings cascade on topic deletion.
- `slb_syllabus_schedule` — schedule entries cascade on topic deletion.
- `sch_classes` / `sch_subjects` — denormalized for fast hierarchical queries.

### Permissions Matrix
| Role | Create | Edit | Delete | Move/Reorder | View Tree |
|---|---|---|---|---|---|
| Super Admin | ✅ | ✅ | ✅ | ✅ | ✅ |
| School Admin | ✅ | ✅ | ✅ | ✅ | ✅ |
| Curriculum Coordinator | ✅ | ✅ | ✅ | ✅ | ✅ |
| Teacher | ❌ | ❌ | ❌ | ❌ | ✅ |
| Student/Parent | ❌ | ❌ | ❌ | ❌ | ❌ |
