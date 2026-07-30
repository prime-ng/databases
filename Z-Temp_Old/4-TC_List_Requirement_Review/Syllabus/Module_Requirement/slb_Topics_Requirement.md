# Topics Master — Business Requirements

## What This Screen Does

The Topics screen is the most critical and complex interface in the Syllabus module. It breaks down broad Lessons into highly granular, teachable, and assessable units. 

It utilizes an advanced hierarchical structure to allow infinite nesting, such as Topic leading to Sub-topic leading to Micro-topic. It acts as the central hub connecting the teaching content to time duration, prerequisite dependencies, and unique analytics tracking codes. Everything from generating question papers to tracking daily teacher progress relies on the accuracy of this screen.

---

## When This Screen Is Used

- Syllabus Breakdown when a Head of Department takes a large Lesson and breaks it down into specific daily topics
- Prerequisite Enforcement when establishing dependencies to prevent a student from accessing advanced topics before mastering basic ones
- Automation Setup when configuring rules to automatically release quizzes or unlock study materials as soon as a teacher marks a topic as completed

## Default Data Load

This screen displays within the Syllabus Master tab group. When the user navigates to Syllabus → Master, SyllabusController@master() loads all master tab data simultaneously (Lessons, Topics, Competencies, etc.), each independently paginated at 10 rows per page. Shared dropdowns (Class, Section, Subject, Academic Session, Book) are fetched as active records with no pagination.

---

---

## Key Fields at a Glance

**Hierarchical Structure**
The Parent Topic links the topic to an immediate parent, while leaving it empty makes it a root topic. The Topic Level defines whether it is a Topic, Sub-Topic, or Micro-Topic. A human-readable Breadcrumb Path is displayed to provide a fast navigation trail for reporting purposes.

**Identity and Tracking**
An automatically generated Analytics Tracking Code is built by combining parent codes, providing deep context tracking for reporting tools. A User Code is an editable reference code that the school can use for their internal tracking. The full Display Name and a condensed Short Name are captured, along with a Sequence Order which determines the exact order in which topics appear in the curriculum tree.

**Teaching and Assessment Details**
The Duration captures the exact time estimated to teach this specific topic in minutes. The Weightage represents how important this topic is relative to the whole lesson, expressed as a percentage, which is used to auto-calculate progress bars. Baseline mapping allows a prerequisite topic to be linked from a previous academic year, while Current Year Prerequisites is a list of other topics in the current year that must be completed before this topic unlocks.

**Automation Triggers**
The Assessable toggle determines if questions can be linked to this topic in the Question Bank. The Track for Syllabus Status toggle determines if this topic should be counted when calculating the overall Syllabus Completed percentage on the dashboard. The Auto-Release Quiz toggle dictates if the system should automatically push linked quizzes to students as soon as the teacher marks this topic complete.

---

## Business Rules and Conditions

**Auto-Generation of Tracking Paths**
When a new topic is saved, the system must automatically figure out its ancestry and append its code to the parent's code. If a parent topic is moved using drag-and-drop, the system must instantly update the tracking codes for that topic and all of its nested children to ensure analytics are never broken.

**Sequence and Uniqueness Constraints**
The system enforces that no two topics can have the same sequence order under the same parent to maintain a strict chronological curriculum.

**Logical Nesting Validation**
The interface must prevent illogical nesting. For example, a Sub-Topic cannot be the parent of a Root Topic. The hierarchical level of a child must always be deeper than its parent.

**Circular Dependency Prevention**
When saving prerequisites, the system must perform a logic check. Topic A cannot require Topic B if Topic B already requires Topic A. Furthermore, a topic cannot be set as a prerequisite for itself.

---

## Workflow Steps

**Creating a Hierarchical Topic**
The teacher selects the Lesson and clicks Add Topic. The system defaults to the Root Topic level. The teacher names it "Velocity" and sets the duration. Upon saving, the system automatically generates the analytics tracking code. The teacher then clicks to add a child under "Velocity". The system locks the parent to "Velocity" and forces the level to "Sub-Topic". The teacher names it "Average Velocity", assigns a weightage, enables the auto-release quiz option, and saves it. The system creates a deeper tracking code reflecting the parent-child relationship.

---

## Example Scenario

A school enforces a strict Mastery-Based Learning policy. The Biology HOD structures the syllabus by creating Topic A: "Cell Structure" and Topic B: "Cell Division". The HOD edits Topic B and adds Topic A into the prerequisites list. 

When the academic year begins, students can view the study materials for Topic A. However, Topic B is completely locked and greyed out. Even if the scheduled date for Topic B arrives, the system validates the prerequisites. It sees that the student hasn't passed the Topic A assessment yet. Topic B remains locked, forcing the student to master Cell Structure before moving to Cell Division.

---

## Related Screens

- **Topic Types** — Controls the depth and rules for nesting
- **Topic-Competency Mapping** — Links these specific topics to broad educational outcomes
- **Lesson Date Planning** — Where these topics are assigned target completion dates

---

## Requirements

- Controller `TopicController`; `index()` is loaded via Syllabus tab; `Gate::authorize('tenant.topic.viewAny')` is enforced
- Route: `syllabus.master.index` with tab parameter `topic`
- `store()` acts as both create and update: if `id` present, delegates to `update()`; otherwise gates `tenant.topic.create`
- `store()` validates parent-child level integrity: parent must be at `selectedType.level - 1`; root topics need level 0; parent must belong to same lesson
- `update()` validates level change blocked if children exist, validates parent relationship
- `destroy()` gates `tenant.topic.delete`, checks quizzes assigned (`Quiz::where('scope_topic_id', $id)`) and children (`Topic::where('parent_id', $id)`), blocks with 500 if either found; otherwise calls `forceDelete()` (hard delete, not soft)
- `updateHierarchy(Request)` receives `tree` JSON + `lesson_id`, two-phase update: (1) temporary ordinals (50000 + index) to avoid unique constraint, (2) final parent/level/ordinal assignment
- `toggleReleaseStatus()` gates `update`, handles `schedule`, `lesson`, `sync_all` types via `TopicReleaseControlService`
- `validateImportFile()` validates Excel/CSV import file row-by-row, returns error text file or stores file in session
- `startImport()` reads session-stored file and filters, runs `TopicImport` via `Excel::import()`
- `getTopicsByLesson()` returns tree with `children.children...` (5 levels deep)
- `getParentOptions()` returns topics at `selectedLevel - 1` for dropdown
- `getTopicLevels()` returns active level types ordered by level
- `getTopicsByLevelFilter()` returns topics filtered by level_id, optional class/subject/lesson
- `getChildTopics($id)` returns active children ordered by ordinal
- `prepareForValidation()` auto-computes `level_id` if missing: parent exists → parent.level+1; else → level 0. Casts `is_active` boolean, normalizes `parent_id`/`ordinal`
- Model `creating` event: auto-generates UUID (`Str::random(16)`), auto-sets path (`/parentId/TEMP/` initially, replaced with real ID in `created` event), auto-generates hierarchical `code`
- Model `deleting` event: cascades to children, competencies, syllabus schedules
- Soft deletes enabled in model trait, but `destroy()` uses `forceDelete()`
- Activity logged via `activityLog()` for CRUD operations
- Policy: `TopicPolicy` (`tenant.topic.*`)

## Who Can Access

| Gate/Permission | Methods | Notes |
|----------------|---------|-------|
| `tenant.topic.viewAny` | `index()`, `show()` | Page load + view |
| `tenant.topic.view` | `getTopicsByLesson()`, `getParentOptions()`, `getTopicLevels()`, `getTopicsByLevelFilter()`, `getChildTopics()`, `getParentTopics()` | All AJAX read endpoints |
| `tenant.topic.create` | `store()` (no id), `validateImportFile()`, `startImport()` | Create + import |
| `tenant.topic.update` | `update()`, `store()` (with id), `updateHierarchy()`, `toggleReleaseStatus()` | Edit + reorder + release |
| `tenant.topic.delete` | `destroy()` | Hard delete (forceDelete) |
| Policy: `TopicPolicy` | Single policy | Uses `tenant.topic.*` |

## Logic Flow

1. **Page Load** — Screen loads via Master tab; Gates `tenant.topic.viewAny`, loads classes, subjects, lessons, and `topicsByLevel` (grouped by numeric level). View renders tree container.
2. **Create** — `store()` validates via `TopicRequest`. `prepareForValidation()` auto-computes `level_id`. If `parent_id` present: validates parent is at `selectedType.level - 1` and same lesson. If no parent: validates level must be 0. `ordinal` auto-set to `max(ordinal) + 1` for siblings. Model `creating` event: generates UUID, path (`/parentId/TEMP/`), hierarchical code. `created` event: replaces `TEMP/` with `$topic->id . '/'` in path.
3. **Edit** — `show()` loads with `topicLevelType` relation, computes parent options for the topic's depth - 1 level, excludes self and descendants. `update()` validates level change blocked if children exist, validates parent relationship, updates in DB transaction.
4. **Tree Display** — `getTopicsByLesson()` fetches root topics for a lesson, eager-loads `children` up to 5 levels deep. `formatTree()` builds nested JSON with `id, name, level, level_label, class_id, subject_id, lesson_id, parent_id, ordinal, short_name, description, duration_minutes, learning_objectives, is_active, is_assessable, children[]`.
5. **Drag-Drop Reorder** — `updateHierarchy()` receives `tree` JSON + `lesson_id`. Phase 1: temporary ordinals (50000 + index) to avoid unique constraint violations. Phase 2: final parent (`parent_id`), level (`TopicLevelType::where('level', $level)`), ordinal (index+1). Recursively processes children at level+1. Maximum level via `TopicLevelType::max('level')`.
6. **Delete** — `destroy()` checks quizzes (`Quiz::where('scope_topic_id', $id)->exists()` → 500), then children (`Topic::where('parent_id', $id)->exists()` → 500). Otherwise calls `forceDelete()`.
7. **Import** — `validateImportFile()` validates file, parses Excel row-by-row, checks required fields (topic_name), validates duration/weightage/active formats. Returns error text file or stores file + filters in session. `startImport()` retrieves from session, runs `Excel::import(new TopicImport($filters))`, returns `{status, created, skipped, errors}`.

## Validate Before Save

| Field | Rule(s) | Error Message |
|-------|---------|---------------|
| `class_id` | `required, integer, exists:sch_classes,id` | — |
| `subject_id` | `required, integer, exists:sch_subjects,id` | — |
| `lesson_id` | `required, integer, exists:slb_lessons,id` | — |
| `parent_id` | `nullable, integer, exists:slb_topics,id` | — |
| `name` | `required, string, max:150, unique` — scoped to `(lesson_id, parent_id)` | "This topic already exists under the selected lesson and parent." |
| `short_name` | `nullable, string, max:50` | — |
| `level_id` | `required, integer, exists:slb_topic_level_types,id` | — |
| `description` | `nullable, string` | — |
| `duration_minutes` | `nullable, integer, min:1` | — |
| `learning_objectives` | `nullable` | — |
| `is_active` | `required, boolean` | — |
| **Parent level (controller)** | Parent must be at `selectedType.level - 1` | "Selected parent must be at X level" |
| **Same lesson (controller)** | Parent must belong to same lesson | "Parent topic must belong to the same lesson" |
| **Root level (controller)** | Topic without parent must have level 0 | "X level requires a parent topic" |
| **Level change (controller)** | Cannot change level if children exist | "Cannot change level of a topic that has child topics" |

## Error Handling and Validation Messages

| Scenario | Message | Type |
|----------|---------|------|
| Duplicate name under lesson+parent | "This topic already exists under the selected lesson and parent." | Validation (`name.unique`) |
| Invalid parent level | "Selected parent must be at SUB_TOPIC level" | Controller check (500 JSON) |
| Parent wrong lesson | "Parent topic must belong to the same lesson" | Controller check (500 JSON) |
| Level change with children | "Cannot change level of a topic that has child topics" | Controller check (500 JSON) |
| Delete with quizzes | "Cannot delete this topic because quizzes are assigned to it." | Controller check (500 JSON) |
| Delete with children | "Cannot delete this topic because it has child topics." | Controller check (500 JSON) |
| Invalid import row | "Row N : topic_name required" etc. | Import validation text file |

## Success Scenarios

**SC-001 — Creating a Root Topic**
Teacher creates topic "Velocity" under lesson "Motion", no parent. `prepareForValidation()` sets `level_id` to level 0. Model `creating` event: UUID generated, path = `/TEMP/`, `code` auto-generated (e.g., `CLS_SUB_MOT_TOP01`). `created` event: path updated to `/5/`. Returns 200 JSON.

**SC-002 — Creating a Child Topic**
Teacher creates "Average Velocity" under parent "Velocity" (level_id for level 1). Controller validates parent at level 0 (correct). `creating`: path = `/5/TEMP/`, level auto-computed, `code` = `{parentCode}_SUB01`. `ordinal` auto-set to max+1.

**SC-003 — Drag-Drop Reparenting**
Teacher drags topic to new parent. `updateHierarchy()` processes JSON tree, two-phase update. Phase 1: temp ordinals 50000+N. Phase 2: parent, level, ordinal, lesson_id. Returns JSON success.

**SC-004 — Bulk Import**
Teacher uploads Excel with topic rows. `validateImportFile()` validates each row, returns error file or stores in session. `startImport()` runs `TopicImport` importer, returns created/skipped/errors count.

## Failure Scenarios

**FC-001 — Invalid Parent Level**
User tries to set a level-3 topic as parent of a level-0 topic. Controller validates `parent->level !== selectedType->level - 1` → 500 "Selected parent must be at MICRO_TOPIC level".

**FC-002 — Delete Blocked Due to Quizzes**
User tries to delete topic with associated quizzes. `destroy()` checks `Quiz::where('scope_topic_id', $id)->exists()` → 500 "Cannot delete this topic because quizzes are assigned to it."

**FC-003 — Delete Blocked Due to Children**
User tries to delete topic with child topics. `destroy()` checks children → 500 "Cannot delete this topic because it has child topics."

**FC-004 — Duplicate Import Row**
Import file row has empty `topic_name`. `validateImportFile()` adds "Row 5 : topic_name required" to error output.

## Dependencies module and tables

| Dependency | Type | Details |
|-----------|------|---------|
| `slb_lessons` | FK Table | `lesson_id` → `id` ON DELETE CASCADE |
| `slb_topic_level_types` | FK Table | `level_id` → `id` ON DELETE RESTRICT |
| `sch_classes` | FK Table | `class_id` → `id` |
| `sch_subjects` | FK Table | `subject_id` → `id` |
| `slb_topic_competency_jnt` | Child Table | Cascade via `deleting` event |
| `slb_topics` (self) | Self-referencing FK | `parent_id` → `id` CASCADE |
| `lms_quizzes` | Consumer | `scope_topic_id` — blocks delete if referenced |
| `TopicReleaseControlService` | Service | Used by `toggleReleaseStatus()` |
| Activity Log | Consumer | `activityLog()` on CRUD |

**Table:** `slb_topics`

| Column | Type | Details |
|--------|------|---------|
| id | BIGINT PK | Auto-increment |
| uuid | BINARY(16) | Generated via `Str::random(16)` |
| parent_id | BIGINT FK NULL | Self-reference → `slb_topics.id` CASCADE |
| lesson_id | BIGINT FK | → `slb_lessons.id` CASCADE |
| class_id | BIGINT FK | → `sch_classes.id` CASCADE |
| subject_id | BIGINT FK | → `sch_subjects.id` CASCADE |
| path | VARCHAR(500) | Materialized path (e.g., `/5/12/`) |
| path_names | VARCHAR(2000) | Breadcrumb names |
| level_id | BIGINT FK | → `slb_topic_level_types.id` RESTRICT |
| code | VARCHAR(60) UNIQUE | Auto-generated hierarchical code |
| name | VARCHAR(150) | Display name |
| short_name | VARCHAR(50) | Condensed display |
| ordinal | SMALLINT | Sequence order under parent |
| description | VARCHAR(255) | — |
| weightage_in_lesson | DECIMAL(5,2) | Importance within lesson |
| duration_minutes | INT | Estimated teaching time |
| learning_objectives | JSON | Learning objectives array |
| keywords | JSON | Keywords array |
| prerequisite_topic_ids | JSON | Prerequisite topic IDs array |
| base_topic_id | BIGINT FK NULL | Previous year baseline topic |
| is_assessable | TINYINT(1) | Question Bank tagging toggle |
| analytics_code | VARCHAR(60) UNIQUE | Auto-generated tracking code |
| can_use_for_syllabus_status | TINYINT(1) | Syllabus completion toggle |
| release_quiz_on_completion | TINYINT(1) | Auto quiz publish toggle |
| release_quest_on_completion | TINYINT(1) | Auto quest publish toggle |
| is_active | TINYINT(1) | Activity flag |
| created_at | TIMESTAMP | — |
| updated_at | TIMESTAMP | — |
| deleted_at | TIMESTAMP | Soft deletes | |
