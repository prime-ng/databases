# Topic Types Master — Business Requirements

## What This Screen Does

The Topic Types screen is a foundational configuration interface that controls the architectural depth of the entire syllabus. 

Instead of hardcoding fixed terms like "Topic" and "Sub-topic", this screen allows the school to define a scalable, multi-tiered hierarchy. It answers the question of how deep a teacher can break down a chapter. Furthermore, it acts as the primary gatekeeper for assessments, defining exactly which levels of the hierarchy are allowed to be tested in exams or given as homework.

---

## When This Screen Is Used

- System Deployment by the software provider or super-admin during the initial rollout to the school
- Assessment Policy Definition when the Examination Board decides that quizzes cannot be generated for extremely small topics
- Analytics Configuration when configuring how the automated tracking codes should be structured for deep reporting

## Default Data Load

This screen displays within the Syllabus Master tab group. When the user navigates to Syllabus → Master, SyllabusController@master() loads all master tab data simultaneously (Lessons, Topics, Competencies, etc.), each independently paginated at 10 rows per page. Shared dropdowns (Class, Section, Subject, Academic Session, Book) are fetched as active records with no pagination.

---

---

## Key Fields at a Glance

**Identity and Depth Indicators**
A numeric depth level represents the mathematical depth of the hierarchy, such as 0 for Root Topic, 1 for Sub-topic, or 2 for Micro Topic. The system strictly relies on these numbers to render the visual tree, ensuring parents always have a lower number than children. The human-readable name is displayed in dropdowns, like "Sub-Topic" or "Nano Topic", alongside a standardized short code which is used by the system to dynamically generate tracking codes for analytics.

**Gatekeeper Settings**
These configuration toggles govern exactly how the rest of the system interacts with this specific depth level. The Homework Release toggle allows teachers to assign homework specifically bound to this level. The Quiz Release toggle allows generating automated short quizzes based on this level. The Question Bank Tagging toggle allows individual questions in the Question Bank to be tagged down to this granular level. The Exam Release toggle allows a formal Summative Exam to be built around this level.

---

## Business Rules and Conditions

**Strict Uniqueness Rules**
The system enforces absolute uniqueness across its core identity fields to prevent structural collapse. No two types can share the same depth number, short code, or name.

**Global Configuration Control**
Because changing these levels fundamentally alters how tracking codes are constructed, this screen is typically locked for regular school administrators. It is maintained at the master tenant level. Allowing schools to randomly insert a new depth level mid-year would break global analytics reporting and cross-school benchmarking.

**Restrictive Deletion**
A Topic Type cannot be deleted if even a single Topic in the database is currently using it, preventing broken references in the curriculum tree.

---

## Workflow Steps

**Adding a New Depth Level**
The Super Admin logs into the Global Master configuration and navigates to Topic Types. If a school requests the ability to track extremely granular details beyond a Micro Topic, the Admin clicks Add New Level. They set the Depth Level to the next available number, enter the Name as "Nano Topic", and the Short Code as "NAN". They enable Homework and Quiz release but disable Exam Release because a Nano Topic is too small to warrant a major final exam. Upon saving, "Nano Topic" instantly becomes available as an option across the entire school.

---

## Example Scenario

The Examination Department is setting up the Mid-Term Exam Blueprint using the Exam Generator. The Exam Head tries to select specific syllabus areas to test. 

They navigate to the "Cell Division" chapter and try to select a deeply nested item called "Spindle Fiber Formation" to build the exam around. However, the system checks the setup and sees that "Spindle Fiber Formation" is categorized as a "Micro Topic". 

The Exam Engine then checks the rules for Micro Topics defined in this screen. It sees that Exam Release is disabled for this level. The system instantly displays a validation error advising the user that they cannot center a formal Exam around a Micro Topic and must select a higher-level Topic. This ensures educational standards are maintained.

---

## Related Screens

- **Topics** — Heavily relies on this table to define parent-child logic and generate analytics codes
- **Exam Blueprinting** — Uses the gatekeeper settings to permit or block assessment generation

---

## Requirements

- Controller `TopicLevelTypeController`; `index()` is loaded via Syllabus tab; `Gate::authorize('tenant.topic-level-type.viewAny')` is enforced
- Route: `syllabus.master.index` with tab parameter `topic_level_types`
- `store()` gates `tenant.topic-level-type.create`, calls `TopicLevelType::create($request->validated())`, logs "Created" via `activityLog()`
- `update()` gates, finds record, calls `$item->update()`, logs "Updated"
- `destroy()` gates `tenant.topic-level-type.delete`, checks if topics exist at this level or below (`whereHas('topicLevelType', where level >= current)`), blocks with error if used; otherwise logs "Delete" and soft-deletes via `$item->delete()`
- `restore()` gates, finds `onlyTrashed()`, calls `$item->restore()`, logs "Restored"
- `forceDelete()` gates, finds `onlyTrashed()`, calls `$item->forceDelete()`, logs "Force Delete"
- `toggleStatus($id)` AJAX: gates `update`, toggles `is_active`, logs "Toggle Status"
- `prepareForValidation()` casts `is_active` via `$this->boolean()`
- Validation enforces unique `level` (min:0, max:9), `code` (max:3), `name` (max:150) — all unique across `slb_topic_level_types`
- `withValidator()` enforces sequential level creation: new level must equal `max(level) + 1`; first level must be 0
- Only 3 fillable fields in model: `level`, `code`, `name`, `is_active` (no gatekeeper toggle columns in fillable — `homework_release_flag`, `quiz_release_flag`, `quest_release_flag` exist in DDL but not in model fillable)
- Soft deletes enabled; pagination: 10 per page
- Activity logged: Created, Updated, Delete, Restored, Force Delete, Toggle Status
- Policy: `TopicLevelTypePolicy` (`tenant.topic-level-type.*`)

## Who Can Access

| Gate/Permission | Methods | Notes |
|----------------|---------|-------|
| `tenant.topic-level-type.viewAny` | `index()` | Page load |
| `tenant.topic-level-type.view` | `show()` | View single |
| `tenant.topic-level-type.create` | `create()`, `store()` | Create |
| `tenant.topic-level-type.update` | `edit()`, `update()`, `toggleStatus()` | Edit / toggle |
| `tenant.topic-level-type.delete` | `destroy()` | Soft delete |
| `tenant.topic-level-type.restore` | `restore()`, `trashed()` | Restore |
| `tenant.topic-level-type.forceDelete` | `forceDelete()` | Permanent delete |
| Policy: `TopicLevelTypePolicy` | Single policy | Uses `tenant.topic-level-type.*` |

## Logic Flow

1. **Page Load** — Screen loads via Master tab; Gates, fetches paginated (10) records ordered by `level`.
2. **Create** — `create()` gates. POST to `store()` validates via `TopicLevelTypeRequest`: `withValidator()` checks first record must be level 0, subsequent records must be `max(level)+1`. If valid, creates, logs "Created", redirects to `syllabus.master.index` tab `topic_level_types`.
3. **Edit** — `edit()` gates, finds record. POST to `update()` gates, validates (with level continuity check for updates: new level cannot exceed `max(existing.levels) + 1`), updates, logs "Updated".
4. **Destroy** — `destroy()` gates, finds record, checks `Topic::whereHas('topicLevelType')` at this level or below. If topics exist → redirect with error. Otherwise logs "Delete" and soft-deletes.
5. **Restore** — `restore()` finds `onlyTrashed()`, calls `restore()`, logs "Restored".
6. **Force Delete** — `forceDelete()` finds `onlyTrashed()`, calls `forceDelete()`, logs "Force Delete".
7. **Status Toggle** — `toggleStatus()` AJAX: finds record, inverts `is_active`, saves, logs "Toggle Status". Returns JSON.

## Validate Before Save

| Field | Rule(s) | Error Message |
|-------|---------|---------------|
| `level` | `required, integer, min:0, max:9, unique:slb_topic_level_types` (ignoring current, whereNull deleted_at) | "The level field is required." / "This level already exists." / "Level must be at least 0." / "Level cannot exceed 9." |
| `code` | `required, string, max:3, unique:slb_topic_level_types` (ignoring current, whereNull deleted_at) | "The code field is required." / "This code already exists." / "Code cannot exceed 3 characters." |
| `name` | `required, string, max:150, unique:slb_topic_level_types` (ignoring current, whereNull deleted_at) | "The name field is required." / "This name already exists." / "Name cannot exceed 150 characters." |
| `is_active` | `sometimes, boolean` | — |
| **Sequence (custom)** | `withValidator()`: POST — first must be 0, subsequent must be max+1. PUT — new level ≤ max(existing)+1, no gaps | "The first level must be 0." / "Level must be N to maintain sequence. Current max level is M." |

## Error Handling and Validation Messages

| Scenario | Message | Type |
|----------|---------|------|
| Duplicate level | "This level already exists." | Validation (`level.unique`) |
| Duplicate code | "This code already exists." | Validation (`code.unique`) |
| Duplicate name | "This name already exists." | Validation (`name.unique`) |
| Level > 9 | "Level cannot exceed 9." | Validation (`level.max`) |
| Level < 0 | "Level must be at least 0." | Validation (`level.min`) |
| Code > 3 chars | "Code cannot exceed 3 characters." | Validation (`code.max`) |
| Name > 150 chars | "Name cannot exceed 150 characters." | Validation (`name.max`) |
| Non-sequential level | "Level must be N to maintain sequence. Current max level is M." | `withValidator()` custom |
| First level not 0 | "The first level must be 0." | `withValidator()` custom |
| Delete level in use | "Topic Type cannot be deleted because topics exist at this level or below." | Controller business rule |

## Success Scenarios

**SC-001 — Creating the First Level**
Super Admin creates level 0 "Root Topic" with code "TOP". `withValidator()` checks no records exist → level must be 0. Record created, redirects with success.

**SC-002 — Creating Sequential Level**
Super Admin creates level 1 "Sub Topic" with code "SUB". `withValidator()` checks max existing level is 0 → level must be 1. Record created.

**SC-003 — Status Toggle**
User toggles status. `toggleStatus()` inverts `is_active`, logs "Toggle Status", returns JSON.

## Failure Scenarios

**FC-001 — Duplicate Level Number**
User tries to create level 2 "Mini Topic" when level 2 already exists. `level.unique` fails with "This level already exists."

**FC-002 — Non-Sequential Level**
User tries to create level 3 when max existing level is 1. `withValidator()` rejects with "Level must be 2 to maintain sequence. Current max level is 1."

**FC-003 — Delete Blocked Due to Topic References**
User tries to delete level 1 that is used by 500 topics. `destroy()` checks `Topic::whereHas('topicLevelType')` at level ≥ 1. If found, redirects with error "Topic Type cannot be deleted because topics exist at this level or below."

## Dependencies module and tables

| Dependency | Type | Details |
|-----------|------|---------|
| `slb_topics` | Consumer FK | `level_id` → `slb_topic_level_types.id` ON DELETE RESTRICT |
| Activity Log | Consumer | `activityLog()` on all CRUD + toggle |

**Table:** `slb_topic_level_types`

| Column | Type | Details |
|--------|------|---------|
| id | BIGINT PK | Auto-increment |
| level | TINYINT UNIQUE | Numeric depth (0, 1, 2, ... 9) |
| code | VARCHAR(3) UNIQUE | Short code for analytics |
| name | VARCHAR(150) UNIQUE | Display name |
| homework_release_flag | TINYINT(1) | Release homework (DDL only, not in model fillable) |
| quiz_release_flag | TINYINT(1) | Release quiz (DDL only) |
| quest_release_flag | TINYINT(1) | Release quest (DDL only) |
| is_active | TINYINT(1) | Soft-delete flag |
| created_at | TIMESTAMP | — |
| updated_at | TIMESTAMP | — |
| deleted_at | TIMESTAMP | Soft deletes | |
