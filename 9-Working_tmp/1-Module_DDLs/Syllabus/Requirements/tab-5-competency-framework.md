# Syllabus Tab 5: Competency Framework

This tab manages the competency framework aligned with NEP 2020 guidelines. Competencies are skills or outcomes that students must master, tracked independently from topics. The framework supports hierarchical competency types, individual competencies, and topic-to-competency mapping with weightage.

---

## How It Works

The screen is divided into three sections accessed via sub-tabs or a stepped interface.

The first section manages Competency Types. This is a simple list of categories such as Knowledge, Skill, and Attitude. Each type has a code and description. These types are primarily system-defined but schools can add custom types if needed.

The second section manages Competencies. Each competency belongs to a competency type and is assigned a domain (Cognitive, Affective, or Psychomotor). Competencies can be hierarchical — a parent competency can have child sub-competencies. Each competency can optionally be scoped to a specific class and subject (if it applies only to certain contexts) or left global (applicable across all classes). Key fields include the NEP framework reference, NCF alignment code, and learning outcome code from the board. A materialized path tracks the competency hierarchy.

The third section maps topics to competencies. The user selects a topic and then searches for and links one or more competencies. For each mapping, the user specifies a weightage percentage (how much this topic contributes to that competency) and whether this is the primary competency for the topic. When a topic is deleted, its competency mappings are automatically removed.

---

## Important Business Rules

- Competency types are seeded by the system but additional types can be added by schools.
- Competencies can be created at the global level (no class/subject) or scoped to a specific class and subject.
- A competency's code must be unique across the entire system.
- The competency hierarchy supports unlimited depth via the `parent_id` self-reference.
- The `path` field is automatically maintained for breadcrumb navigation, similar to topic paths.
- A topic can be mapped to multiple competencies with different weightages. The sum of weightages across all competencies for a topic does not need to equal 100% — the weightage indicates contribution strength, not proportional allocation.
- Only one competency can be marked as `is_primary = 1` per topic. If a new primary is set, the previous primary is automatically demoted.
- The same topic-competency pair cannot be duplicated — the junction table has a unique constraint on (topic_id, competency_id).
- Deleting a competency cascades to all its child competencies and all topic mappings.
- NEP reference codes and learning outcome codes are used for government compliance reporting.

---

## Database Columns & Behavior

### slb_competency_types
- `id` — Primary key. INT UNSIGNED AUTO_INCREMENT.
- `code` — Unique type code. VARCHAR(20). Example: KNOWLEDGE, SKILL, ATTITUDE. Unique constraint.
- `name` — Display name. VARCHAR(100).
- `description` — Explanation of the type. VARCHAR(255), nullable.
- `is_active` — Soft delete flag. TINYINT(1), default 1.

### slb_competencies
- `id` — Primary key. INT UNSIGNED AUTO_INCREMENT.
- `uuid` — Unique binary identifier. BINARY(16). Unique constraint.
- `parent_id` — Self-referencing FK for hierarchy. INT UNSIGNED, nullable. CASCADE on delete.
- `code` — Unique competency code. VARCHAR(60). Unique constraint.
- `name` — Display name. VARCHAR(150).
- `short_name` — Abbreviated name. VARCHAR(50), nullable.
- `description` — Detailed explanation. VARCHAR(255), nullable.
- `class_id` — Optional class scope. INT UNSIGNED FK to sch_classes. CASCADE on delete. Nullable.
- `subject_id` — Optional subject scope. INT UNSIGNED FK to sch_subjects. CASCADE on delete. Nullable.
- `competency_type_id` — FK to slb_competency_types. INT UNSIGNED. CASCADE on delete.
- `domain` — Educational domain. ENUM('COGNITIVE', 'AFFECTIVE', 'PSYCHOMOTOR'). Default COGNITIVE.
- `nep_framework_ref` — NEP 2020 framework reference code. VARCHAR(100), nullable.
- `ncf_alignment` — NCF alignment code. VARCHAR(100), nullable.
- `learning_outcome_code` — Board-specific outcome code. VARCHAR(50), nullable.
- `path` — Materialized path for hierarchy. VARCHAR(500), default '/'.
- `level` — Hierarchy depth. TINYINT UNSIGNED, default 0.
- `is_active` — Soft delete flag. TINYINT(1), default 1.

### slb_topic_competency_jnt
- `id` — Primary key. INT UNSIGNED AUTO_INCREMENT.
- `topic_id` — FK to slb_topics. INT UNSIGNED. CASCADE on delete.
- `competency_id` — FK to slb_competencies. INT UNSIGNED. CASCADE on delete.
- `weightage` — Contribution percentage. DECIMAL(5,2), nullable.
- `is_primary` — Primary competency flag. TINYINT(1), default 0.
- `is_active` — Soft delete flag. TINYINT(1), default 1.
- Unique constraint on (topic_id, competency_id) prevents duplicate mappings.

---

## Deep Analysis

### Business Workflows & State Machines
- **Competency Type Management** → system seeds `KNOWLEDGE`, `SKILL`, `ATTITUDE`; schools can add custom types → INSERT with `name`, `code`, `description`.
- **Competency CRUD** → create competency with `parent_id` (optional), `class_id`/`subject_id` scope, `domain`, NEP references → auto-build `path` and `level` based on parent.
- **Topic-Competency Mapping** → select topic → search competency → set `weightage` and `is_primary` → INSERT into junction table.
- **Primary toggle** → when setting `is_primary = 1`, auto-demote any existing primary for that topic (`UPDATE ... SET is_primary = 0 WHERE topic_id = ?`).
- **State machine**: Competency types / competencies / mappings are always ACTIVE or SOFT-DELETED; no workflow states.

### Validation Rules & Edge Cases
- **Code uniqueness** — `uq_competency_code` ENFORCED at DB level across entire system (global + scoped).
- **Scope consistency** — if both `class_id` and `subject_id` are NULL, the competency is global; if one is set, the other may also be set; no partial scope validation in DB (app layer validates).
- **Hierarchy depth** — unlimited via `parent_id` self-reference; path rebuilding on move is app-layer.
- **Primary competency** — application must enforce max 1 primary per topic; `is_primary` uniqueness is not in DB.
- **Weightage sum** — does NOT need to equal 100%; indicates relative strength, not proportion.
- **Duplicate mapping** — UNIQUE `(topic_id, competency_id)` prevents the same pair.
- **Delete cascade** — deleting a competency cascades to children AND junction rows; must confirm with user.
- **NEP/NCF/LO codes** — free-text; used for government compliance reports; no format validation in DB.

### Integration Points
- `slb_topics` — topic FK in junction table; CASCADE on topic delete.
- `slb_competency_types` — type FK in competencies table.
- `sch_classes` / `sch_subjects` — optional scope filters.
- **Assessment module** — reads competency mappings for competency-aligned question generation.
- **Compliance reporting** — exports NEP framework ref, NCF alignment, learning outcome codes for board/ government submissions.

### Permissions Matrix
| Role | Manage Types | Create Competency | Edit Competency | Delete Competency | Map Topic↔Competency | View |
|---|---|---|---|---|---|---|
| Super Admin | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| School Admin | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Curriculum Coordinator | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Teacher | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ |
| Student/Parent | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
