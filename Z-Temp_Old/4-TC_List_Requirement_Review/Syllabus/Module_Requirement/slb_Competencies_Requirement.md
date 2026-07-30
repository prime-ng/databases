# Competencies Master — Business Requirements

## What This Screen Does

The Competencies screen is designed to shift education from topic-based to outcome-based. It stores the master dictionary of specific, measurable skills, behaviors, and knowledge outcomes that students are expected to acquire.

This screen supports deep hierarchical nesting, allowing schools to define broad outcomes and break them down into specific sub-skills. Crucially, this screen maps the school's internal objectives directly to external national standards like the National Education Policy or National Curriculum Framework.

---

## When This Screen Is Used

- Curriculum Mapping Phase when Academic Directors translate official board guidelines into the digital system
- Skill Framework Expansion when adding new, modern requirements to the curriculum like coding logic or financial literacy
- Subject Specialization when Heads of Departments define specific outcomes that apply exclusively to their subjects

## Default Data Load

This screen displays within the Syllabus Master tab group. When the user navigates to Syllabus → Master, SyllabusController@master() loads all master tab data simultaneously (Lessons, Topics, Competencies, etc.), each independently paginated at 10 rows per page. Shared dropdowns (Class, Section, Subject, Academic Session, Book) are fetched as active records with no pagination.

---

---

## Key Fields at a Glance

**Hierarchical Architecture**
A Parent Competency field links a skill to a broader parent skill, allowing the creation of a skill tree. A background Breadcrumb Path mechanism allows the system to instantly fetch all sub-skills of a master skill for reporting purposes without slow queries.

**Core Identity**
A Unique Tracking ID provides an unchanging identifier used for global analytics and data warehousing. A Reference Code and Name act as a unique reference, such as SCI_EXP_01, and the full display name. A Short Name is also captured for condensed mobile app displays.

**Categorization and Scope**
The Competency Type links the skill to a broad category defined in the Competency Types screen. The Cognitive Domain classifies the outcome into one of three psychological domains: Cognitive, Affective, or Psychomotor. The Class and Subject Scope determines where this skill is applicable; if left empty, it becomes a Global Competency available across the entire school.

**External Compliance Mapping**
The NEP Framework Reference aligns the skill with a specific clause from the National Education Policy. The NCF Alignment aligns the skill with the National Curriculum Framework. The Board Learning Outcome Code aligns the skill with the specific educational board's official outcome code.

---

## Business Rules and Conditions

**Global vs Specific Scope**
The system intentionally allows the Class and Subject fields to be left blank. A competency with blank scope fields must appear in the mapping dropdowns for every subject and class. If a class is selected, the system must restrict this competency so it only appears when teachers are mapping topics within that specific class.

**Domain Standardization**
The Cognitive Domain field must be a strict selection between Cognitive, Affective, or Psychomotor. The system must provide this as a fixed dropdown or radio button. Custom values cannot be entered, ensuring standardized data for radar charts.

**Unique Naming and Coding**
The reference code must be universally unique across the system to prevent confusion during data imports or reporting.

**Automatic Tree Updates**
The system must automatically compute and update the internal tracking paths whenever a competency is saved or moved under a new parent, preserving reporting integrity.

---

## Workflow Steps

**Creating a Hierarchical Competency**
The History HOD navigates to Master and selects Competencies. They click Add Competency, enter the Name as "Critical Analysis of Historical Sources", and provide a unique Code. They select the Cognitive Domain and the appropriate Competency Type. They link it specifically to Class 10 and the Subject History, enter the NCF Alignment Code provided by the government, and save the record. They then create a child competency named "Identifying Bias in Texts", setting the parent to the newly created Critical Analysis competency.

---

## Example Scenario

During an external school inspection, the inspector asks how the school is implementing the government mandate for Psychomotor Development in junior classes.

The Principal opens the system and filters the Competencies master by the Psychomotor domain and Class 2. The system instantly displays a deeply nested list of competencies like "Hand-Eye Coordination" leading to "Catching a Ball", all tagged with official NEP framework reference codes. Because these competencies exist in this master table, teachers are able to map their daily lesson plans directly to them, providing undeniable, organized proof of compliance to the inspector.

---

## Related Screens

- **Topic-Competency Mapping** — Where these defined skills are attached to the actual topics being taught
- **Competency Types** — The parent categories that group these skills together
- **Coverage Audit Report** — Visualizes the delivery of these competencies across the academic term

---

## Requirements

- Controller `CompetencieController` used; `index()` is loaded via Syllabus tab; `Gate::authorize('tenant.competencies.viewAny')` is enforced
- Route: `syllabus.master.index` with tab parameter `competencies`
- `store()` acts as both create and update: if `id` present in request → gate `update` + `findOrFail` + update; otherwise → gate `create` + `Competencie::create()`
- `destroy()` checks `children()->exists()` and returns 500 if children exist, otherwise calls `$competency->delete()` (soft delete via model trait)
- `updateHierarchy(Request)` parses JSON `tree` string, sets all nodes `parent_id` to null first, then assigns new `parent_id` per tree in a transaction
- `getParentCompetencies()` and `getCompetencyTree()` return filtered JSON for dropdowns and tree view
- `getByFilter()` returns tree filtered by `class_id`/`subject_id`
- `prepareForValidation()` casts `is_active` via `$this->boolean()`, sets empty `parent_id` to null
- Code uniqueness scoped to `(class_id, subject_id)` combination
- Activity logged with `activityLog()`: Stored, Updated, Trashed, Restored, Deleted
- Soft deletes on model; `deleting` boot event cascades to children and `topicCompetencies`
- UUID auto-generated via `Str::random(16)` on `creating` event
- `level` and `path` auto-computed on `creating` event: level=parent.level+1, path=`/parentId/`

## Who Can Access

| Gate/Permission | Methods | Notes |
|----------------|---------|-------|
| `tenant.competencies.viewAny` | `index()` | Page load |
| `tenant.competencies.view` | `show()`, `edit()`, `getParentCompetencies()`, `getCompetencyTree()`, `getByFilter()` | View single / filtered |
| `tenant.competencies.create` | `store()` (no id) | Create new |
| `tenant.competencies.update` | `store()` (with id), `update()`, `updateHierarchy()` | Update / reorder |
| `tenant.competencies.delete` | `destroy()` | Soft delete |
| Policies: `CompetenciePolicy` (`tenant.competencie.*`) and `CompetencyPolicy` (`tenant.competencies.*`) | Both registered | Dual permission support |

## Logic Flow

1. **Page Load** — Screen loads via Master tab; Gates `tenant.competencies.viewAny`, loads `SchoolClass` and `Subject` for filter dropdowns. View renders tree container that fetches data via AJAX `getCompetencyTree()` or `getByFilter()`.
2. **Create** — AJAX POST to `store()`. `prepareForValidation()` normalizes `is_active` to boolean, `parent_id` to null if blank. `validated()` applies rules. `Competencie::create()` triggers `creating` boot event: generates UUID, auto-sets `level` (0 for root, parent+1 for child), auto-sets `path` (`/` root or `/parentId/` child). Uses `Str::upper(Str::random(16))` for UUID.
3. **Edit** — AJAX POST to `store()` with `id` field. Gates `update`. Checks self-parent (`$request->parent_id == $competency->id`) and circular-relation (`$parent->parent_id == $competency->id`). If fail, returns 500 JSON. Otherwise `$competency->update($request->validated())`.
4. **Tree Display** — `getCompetencyTree()` queries root competencies (`whereNull('parent_id')`), eager-loads `children` recursively. `formatCompetencyTree()` builds nested JSON: `id, code, name, level, level_label, competency_type, has_children, children[]`.
5. **Drag-Drop Reorder** — `updateHierarchy()` receives `tree` JSON string. Phase 1: sets all nodes' `parent_id` to null via `withoutEvents`. Phase 2: assigns new `parent_id` and `code` per tree structure. Wrapped in `DB::transaction()`.
6. **Delete** — `destroy()` checks `children()->exists()`. If children found → 500 with "Cannot delete competency because it has child competencies." Otherwise `$competency->delete()` which triggers `deleting` event → cascade deletes children and `topicCompetencies` junction records.

## Validate Before Save

| Field | Rule(s) | Error Message |
|-------|---------|---------------|
| `class_id` | `required, integer, exists:sch_classes,id` | "Class is required." / "Selected class is invalid." |
| `subject_id` | `required, integer, exists:sch_subjects,id` | "Subject is required." / "Selected subject is invalid." |
| `parent_id` | `nullable, integer, exists:slb_competencies,id` + custom not-self callback | "A competency cannot be its own parent." |
| `code` | `required, string, max:50, unique` — scoped to `(class_id, subject_id)` | "This competency code already exists for the selected class and subject." |
| `name` | `required, string, max:255` | "Competency name is required." |
| `competency_type_id` | `required, integer, exists:slb_competency_types,id` | "Competency type is required." |
| `domain` | `required` (no ENUM strict check in request) | — |
| `short_name` | `nullable, string, max:50` | — |
| `nep_alignment` | `nullable, string, max:100` | "NEP alignment must not exceed 100 characters." |
| `nep_framework_ref` | `nullable, string, max:255` | — |
| `learning_outcome_code` | `nullable, string, max:100` | — |
| `description` | `nullable, string` | — |
| `is_active` | `required, boolean` | "Status is required." |

## Error Handling and Validation Messages

| Scenario | Message | Type |
|----------|---------|------|
| Duplicate code in scope | "This competency code already exists for the selected class and subject." | Validation (`code.unique`) |
| Self-parent | "A competency cannot be its own parent." | Custom callback in request |
| Circular parent-child | "Invalid parent-child relationship." | Controller business check |
| Delete with children | "Cannot delete competency because it has child competencies." | Controller business check (500 JSON) |
| Invalid class/subject FK | "Selected class is invalid." / "Selected subject is invalid." | Validation (`exists`) |

## Success Scenarios

**SC-001 — Creating a Root Competency**
User creates "Critical Thinking" with code `CRIT_THINK`, selects Cognitive domain, no parent. `Competencie::create()` triggers `creating` event: UUID generated, `level` = 0, `path` = `/`, auto-code from name slug. Returns 200 JSON with record.

**SC-002 — Creating a Child Competency**
User creates "Analyzing Arguments" under parent "Critical Thinking". `creating` event sets `level` = parent.level + 1, `path` = `/parentId/`. `children()` relationship returns nested under parent.

**SC-003 — Drag-Drop Reparenting**
User drags "Analyzing Arguments" under "Reasoning Skills". `updateHierarchy()` processes tree JSON, updates `parent_id` and `code` in transaction. Returns success JSON.

## Failure Scenarios

**FC-001 — Duplicate Code in Scope**
User enters code `CRIT_THINK` for same class/subject. `code.unique` rule fails with "This competency code already exists for the selected class and subject." Returns 500.

**FC-002 — Self-Parent Assignment**
User tries to set a competency's own ID as `parent_id`. Controller detects `$request->parent_id == $competency->id` and returns 500 "Competency cannot be its own parent."

**FC-003 — Delete Blocked Due to Children**
User tries to delete competency with child competencies. `children()->exists()` returns true. Controller returns 500 "Cannot delete competency because it has child competencies."

## Dependencies module and tables

| Dependency | Type | Details |
|-----------|------|---------|
| `slb_competencies` (self) | Self-referencing FK | `parent_id` → `id` ON DELETE CASCADE |
| `slb_competency_types` | FK Table | `competency_type_id` → `id` |
| `sch_classes` | FK Table | `class_id` → `id` |
| `sch_subjects` | FK Table | `subject_id` → `id` |
| `slb_topic_competency_jnt` | Child Table | Cascade via `deleting` event on model |
| Activity Log | Consumer | `activityLog()` on Stored, Updated, Trashed, Restored |

**Table:** `slb_competencies`

| Column | Type | Details |
|--------|------|---------|
| id | BIGINT PK | Auto-increment |
| uuid | BINARY(16) UNIQUE | Generated via `Str::random(16)` |
| parent_id | BIGINT FK NULL | Self-reference → `slb_competencies.id` CASCADE |
| code | VARCHAR(60) UNIQUE | Scoped unique (class_id, subject_id) |
| name | VARCHAR(150) | Display name |
| short_name | VARCHAR(50) | Condensed display |
| description | VARCHAR(255) | — |
| class_id | BIGINT FK | → `sch_classes.id` CASCADE |
| subject_id | BIGINT FK | → `sch_subjects.id` CASCADE |
| competency_type_id | BIGINT FK | → `slb_competency_types.id` CASCADE |
| domain | ENUM('COGNITIVE','AFFECTIVE','PSYCHOMOTOR') | Cognitive domain |
| nep_framework_ref | VARCHAR(100) | NEP clause reference |
| ncf_alignment | VARCHAR(100) | NCF alignment code |
| learning_outcome_code | VARCHAR(50) | Board learning outcome |
| path | VARCHAR(500) | Materialized path (e.g. `/5/`) |
| level | TINYINT | 0 = root, increments for children |
| is_active | TINYINT(1) | Soft-delete flag |
| created_at | TIMESTAMP | — |
| updated_at | TIMESTAMP | — |
| deleted_at | TIMESTAMP | Soft deletes | |
