# Syllabus Tab 4: Topic Level Types

This tab manages the master configuration of topic hierarchy levels. These levels define what each tier in the topic hierarchy is called (Topic, Sub-topic, Mini-topic, etc.) and control which assessment types can be released at each level.

---

## How It Works

The topic level types screen displays a table of all defined levels, sorted by their numeric depth (0 through 9). Each row shows the level number, the three-letter code (TOP, SBT, MIN, SMN, MIC, SMC, NAN, SNN, ULT, SUT), the full name (TOPIC, SUB-TOPIC, etc.), and four toggle switches controlling whether this level can be used for homework release, quiz release, quest release, and exam release.

This is a system-defined configuration table populated by the Prime-AI team. School users can view the levels but cannot add, edit, or delete them. The only editable fields per level are the four release permission toggles. These toggles let the school decide, for example, that homework can be released at the Mini-topic level but exams can only be released at the Topic level.

When a topic is created in the Topic Hierarchy tab, the system reads this table to determine the level name, the code prefix to use in code generation, and which release permissions apply to that topic depth.

---

## Important Business Rules

- The level number (0-9) cannot be changed. It determines the hierarchy depth.
- The code (TOP, SBT, etc.) and name (TOPIC, SUB-TOPIC, etc.) are system-defined and read-only for school users.
- Only the four release permission toggles (homework, quiz, quest, exam) are configurable by school administrators.
- At least one level must have all four release permissions enabled so that topics at the root level can always be assessed.
- If a level's permission toggle is turned off, existing topics at that level lose the ability to have new assessments of that type linked to them. Existing assessments remain unaffected.
- The `is_active` flag can be used to decommission a level entirely. Deactivating a level prevents new topics from being created at that depth.
- The table is seeded by default with 10 levels (0-9). PG Team manages the seed data and structural changes.

---

## Database Columns & Behavior

### slb_topic_level_types
- `id` — Primary key. INT UNSIGNED AUTO_INCREMENT.
- `level` — Numeric depth (0-9). TINYINT UNSIGNED. Unique constraint. 0 = Topic (root), 9 = Sub-ultra-topic (deepest).
- `code` — Three-letter abbreviation. VARCHAR(3). Unique constraint. Values: TOP, SBT, MIN, SMN, MIC, SMC, NAN, SNN, ULT, SUT.
- `name` — Full display name. VARCHAR(150). Unique constraint. Values: TOPIC, SUB-TOPIC, MINI TOPIC, etc.
- `is_active` — Whether this level can be used. TINYINT(1), default 1.
- `can_be_used_for_homework_release` — Allows homework assignments at this level. TINYINT(1), default 1.
- `can_be_used_for_quiz_release` — Allows quiz release at this level. TINYINT(1), default 1.
- `can_be_used_for_quest_release` — Allows quest release at this level. TINYINT(1), default 1.
- `can_be_used_for_exam_release` — Allows exam release at this level. TINYINT(1), default 1.
- `created_at`, `updated_at`, `deleted_at` — Standard timestamps.

---

## Deep Analysis

### Business Workflows & State Machines
- **View Levels** — table grid sorted by `level` ASC; read-only for school users.
- **Toggle Release Permissions** — school admin clicks one of 4 toggles → UPDATE `can_be_used_for_homework_release`, `can_be_used_for_quiz_release`, `can_be_used_for_quest_release`, `can_be_used_for_exam_release`.
- **Deactivate Level** — `is_active = 0` → prevents new topic creation at that `level_id`; existing topics remain unaffected.
- **State machine**: Each level is ACTIVE or INACTIVE; no workflow transitions beyond the two-state toggle.

### Validation Rules & Edge Cases
- **System-seeded immutability** — `code`, `name`, `level` are read-only at DB level for school users; PG Team manages via direct DB or seed migration.
- **Orphaned constraint** — deactivating a level (`is_active = 0`) must not break existing `slb_topics.level_id` FK; FK uses RESTRICT, so deactivation only blocks future use.
- **Release toggle impact** — turning off a toggle does not retroactively remove existing assessment links; only prevents new assessment linkages at that level.
- **At-least-one rule** — at least one level must have all 4 release toggles enabled; checked at app layer before UPDATE.
- **Level 0 guard** — level 0 (Topic) should always remain active and fully enabled; no validation in DB, but app layer enforces.
- **Unique constraints** — `level` (TINYINT 0-9), `code` (VARCHAR 3), `name` (VARCHAR 150) each have UNIQUE indexes.

### Integration Points
- `slb_topics` — `level_id` FK references this table; RESTRICT on delete (prevents removing a level that has topics).
- **Assessment module** — reads `can_be_used_for_quiz_release`, `can_be_used_for_exam_release` etc. to filter available topic levels when linking assessments.
- **Code generation service** — reads `code` prefix (TOP, SBT, etc.) to build `slb_topics.code` and `analytics_code`.
- **Topic hierarchy tab** — reads this table to display level badge and determine auto-level on topic creation.

### Permissions Matrix
| Role | View Levels | Edit Toggles | Deactivate | Edit System Fields | Seed Data |
|---|---|---|---|---|---|
| Super Admin | ✅ | ✅ | ✅ | ✅ | ✅ |
| School Admin | ✅ | ✅ | ✅ | ❌ | ❌ |
| Curriculum Coordinator | ✅ | ❌ | ❌ | ❌ | ❌ |
| Teacher | ✅ | ❌ | ❌ | ❌ | ❌ |
| PG Team (DB) | ✅ | ✅ | ✅ | ✅ | ✅ |
| Student/Parent | ❌ | ❌ | ❌ | ❌ | ❌ |
