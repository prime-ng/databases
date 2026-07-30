# Question Type Specificity — Business Requirements

## What This Screen Does

The Question Type Specificity screen acts as the ultimate bridge between the structural format of a question and its deep cognitive intent. 

It defines exactly what a question is asking the student to do in a practical sense, such as identifying the correct diagram, calculating the missing variable, or writing an essay. By explicitly linking these practical actions to a Cognitive Skill, the system closes the loop where the format dictates the action, the action dictates the skill, and the skill dictates the Bloom's Level.

---

## When This Screen Is Used

- System Setup when defining specific assessment rubrics for a new curriculum
- Formative vs Summative Design when defining that certain specific actions like quick recall are meant for Formative Homework, while actions like extensive calculation are meant for Summative Exams
- Detailed Analytics when a school wants to classify its Question Bank not just by Subject and Chapter, but by the exact functional requirement of the questions

## Default Data Load

This screen displays within the Syllabus Bloom tab group. When the user navigates to Syllabus → Bloom, SyllabusController@bloom() loads all 5 bloom/grid screens simultaneously (Bloom Taxonomy, Cognitive Skills, Question Types, Question Type Specificity, Complexity Levels), each independently paginated at 10 rows per page. A shared Cognitive Skills dropdown is also loaded for filter purposes.

---

---

## Key Fields at a Glance

**Parent Linkage**
A Target Cognitive Skill field links directly to a specific skill defined in the Cognitive Skills screen. This is the crucial link because by setting this, any question tagged with this specificity is instantly associated with the higher-level Cognitive Skill and, by extension, the Bloom's Taxonomy level.

**Identity and Definition**
A Unique Code acts as a standardized identifier, such as CALCULATE_VAR or LABEL_DIAG, which is used for data imports and system stability. A Display Name provides the human-readable name shown to teachers, like 'Calculate the missing variable' or 'Label the diagram'. A Detailed Description provides an explanation of what this specific action entails and when a teacher should select it.

**State Management**
A Status Toggle acts as an active or inactive switch to deprecate specific actions without deleting historical assessment data.

---

## Business Rules and Conditions

**Deep Cognitive Mapping Architecture**
By enforcing the chain from Specificity to Cognitive Skill to Bloom Taxonomy, the system creates a 3-tier deep cognitive engine. Every single time a teacher tags a question with a Specificity like "Label Diagram", the system automatically derives its Cognitive Skill as "Recalling" and its Bloom Level as "Remembering". The teacher only has to make one simple, practical choice, but the system gains 3 levels of analytical depth.

**Cascading Filtering**
To prevent interface clutter in the Question Bank, this screen acts as a secondary cascading filter. If a teacher first selects "Recall" as the Cognitive Skill, the Specificity dropdown will dynamically filter to only show options mapped to "Recall", such as showing "Identify definition" but hiding "Calculate formula".

**Uniqueness and Standardization**
The system ensures that duplicate specificity codes cannot be created. This prevents the vocabulary from becoming diluted and ensures data consistency across thousands of question bank entries.

---

## Workflow Steps

**Adding a New Question Specificity**
The Biology HOD navigates to Question Type Specificity to standardize how diagrams are tested. They click Add Specificity and enter the Name as "Label the Anatomical Parts". They select the Parent Cognitive Skill as "Recalling", which the system knows is linked to the Bloom level "Remembering". They enter the Description explaining that it requires the student to correctly identify and label parts of a provided diagram. They save the record to make it available for all teachers.

---

## Example Scenario

An external audit demands to know how often the school relies on Rote Memorization versus Application. 

The HOD doesn't need to manually read through thousands of test papers. Instead, they run an assessment report. The system looks at all the questions administered over the year. It sees 500 questions tagged with the Specificity of Identify Definition, 300 tagged with Label the Anatomical Parts, and 200 tagged with Calculate Velocity.

Because of the links defined in this screen, the system automatically rolls the first 800 questions up into the Remembering Bloom Level, and the 200 questions up into the Applying Bloom Level. The HOD instantly gets a perfect, data-backed pie chart showing exactly what functional actions the students were tested on.

---

## Related Screens

- **Cognitive Skills** — The parent master configuration screen
- **Question Types (Master)** — Works alongside the mechanical format of the question

---

## Requirements

- Controller `QuestionTypeSpecificityController`; `index()` is loaded via Syllabus tab; `Gate::authorize('tenant.que-type-specificity.viewAny')` is enforced
- Route: `syllabus.bloom.index` with tab parameter `ques_type_specificity`
- `store()` gates `tenant.ques-type-specificity.create`, calls `QueTypeSpecifity::create($request->validated())`, logs "Stored"
- `update()` gates, finds record, diffs changes via `array_diff_assoc`, logs "Updated"
- `destroy()` gates `tenant.ques-type-specificity.delete`, sets `is_active = false`, calls `save()` then `delete()` (soft delete)
- `restore()` gates, finds `onlyTrashed()` with `cognitiveSkill` relation, calls `$item->restore()`, logs "Restored"
- `forceDelete()` gates, finds `withTrashed()`, calls `forceDelete()`, logs "Deleted"
- `toggleStatus($id)` AJAX: gates `tenant.ques-type-specificity.update`, toggles `is_active`, logs "Toggled"
- `prepareForValidation()` uppercases `code` via `strtoupper()`, casts `is_active` via `$this->boolean()`
- Code is unique across entire table (no scope)
- `cognitive_skill_id` FK → `slb_cognitive_skill.id` ON DELETE SET NULL
- Soft deletes enabled; pagination: 10 per page (used in `trashed()`)
- Activity logged: Stored, Updated, Trashed, Restored, Deleted, Toggled
- Policies: `QuesTypeSpecificityPolicy` (`tenant.ques-type-specificity.*`) + `QueTypeSpecifityPolicy`

## Who Can Access

| Gate/Permission | Methods | Notes |
|----------------|---------|-------|
| `tenant.ques-type-specificity.viewAny` | `index()` | Page load |
| `tenant.ques-type-specificity.view` | `show()` | View single |
| `tenant.ques-type-specificity.create` | `create()`, `store()` | Create |
| `tenant.ques-type-specificity.update` | `edit()`, `update()`, `toggleStatus()` | Edit / status |
| `tenant.ques-type-specificity.delete` | `destroy()` | Soft delete |
| `tenant.ques-type-specificity.restore` | `restore()`, `trashed()` | Restore |
| `tenant.ques-type-specificity.forceDelete` | `forceDelete()` | Permanent delete |
| Policies: `QuesTypeSpecificityPolicy` + `QueTypeSpecifityPolicy` | Both registered | Dual permission support |

## Logic Flow

1. **Page Load** — Screen loads via Bloom tab; Gates, eager-loads `cognitiveSkill` relation, orders by `code`, fetches all records (no pagination on index, but `paginate(10)` on `trashed()`).
2. **Create** — `create()` gates, loads active `CognitiveSkill` models for dropdown. POST to `store()` gates, creates via `$request->validated()`, logs "Stored". Redirects to `syllabus.bloom.index` with tab `ques_type_specificity`.
3. **Edit** — `edit()` gates, loads record + cognitive skills. POST to `update()` gates, computes changes via `array_diff_assoc`, updates, logs "Updated". Redirects.
4. **View** — `show()` gates, loads record with `cognitiveSkill`, includes trashed via `withTrashed()`.
5. **Status Toggle** — `toggleStatus()` AJAX: gates, finds record, inverts `is_active`, saves, logs "Toggled". Returns JSON `{success, is_active, message}`.
6. **Delete** — `destroy()` gates, finds record, sets `is_active = false`, `save()`, then `delete()`. Logs "Trashed". Redirects.
7. **Restore** — `restore()` finds `onlyTrashed()` with `cognitiveSkill`, calls `restore()`, logs "Restored".
8. **Force Delete** — `forceDelete()` finds `withTrashed()`, calls `forceDelete()`, logs "Deleted".

## Validate Before Save

| Field | Rule(s) | Error Message |
|-------|---------|---------------|
| `cognitive_skill_id` | `nullable, integer, exists:slb_cognitive_skill,id` | "Selected cognitive skill does not exist." |
| `code` | `required, unique:slb_ques_type_specificity,code` (ignoring current) | "This question type specificity code already exists." |
| `name` | `required, string, max:100` | "Question type specificity name is required." |
| `description` | `nullable, string, max:255` | "Description must not exceed 255 characters." |
| `is_active` | `nullable, boolean` | — |

## Error Handling and Validation Messages

| Scenario | Message | Type |
|----------|---------|------|
| Duplicate code | "This question type specificity code already exists." | Validation (`code.unique`) |
| Invalid cognitive skill | "Selected cognitive skill does not exist." | Validation (`exists`) |
| Missing name | "Question type specificity name is required." | Validation |
| Missing code | "Question type specificity code is required." | Validation |
| Description too long | "Description must not exceed 255 characters." | Validation |
| Cognitive ID not integer | "Cognitive skill must be a valid ID." | Validation |

## Success Scenarios

**SC-001 — Creating a New Specificity**
User creates specificity with code `LABEL_ANAT`, name "Label the Anatomical Parts", links to cognitive_skill_id=3. `prepareForValidation()` uppercases code to `LABEL_ANAT`. `store()` creates record, logs "Stored", redirects to bloom index.

**SC-002 — Toggling a Specificity Inactive**
User toggles status. `toggleStatus()` inverts `is_active`, logs "Toggled", returns JSON with new state.

**SC-003 — Restoring a Trashed Specificity**
Admin views trash, clicks restore. `restore()` on soft-deleted record calls `$item->restore()`, logs "Restored".

## Failure Scenarios

**FC-001 — Duplicate Code Entry**
User creates specificity with code `LABEL_ANAT` that already exists. `code.unique` validation fails with "This question type specificity code already exists."

**FC-002 — Invalid Cognitive Skill Reference**
User selects cognitive_skill_id that does not exist. `exists:slb_cognitive_skill,id` validation fails with "Selected cognitive skill does not exist."

**FC-003 — Missing Required Name**
User leaves name empty. `name.required` fails with "Question type specificity name is required."

## Dependencies module and tables

| Dependency | Type | Details |
|-----------|------|---------|
| `slb_cognitive_skill` | FK Table | `cognitive_skill_id` → `id` ON DELETE SET NULL |
| Activity Log | Consumer | `activityLog()` on all CRUD + status toggle |

**Table:** `slb_ques_type_specificity`

| Column | Type | Details |
|--------|------|---------|
| id | BIGINT PK | Auto-increment |
| cognitive_skill_id | BIGINT FK NULL | → `slb_cognitive_skill.id` ON DELETE SET NULL |
| code | VARCHAR(20) UNIQUE | Uppercased identifier |
| name | VARCHAR(100) | Display name |
| description | VARCHAR(255) | Explanation of the specificity |
| is_active | TINYINT(1) | Active/inactive toggle |
| created_at | TIMESTAMP | — |
| updated_at | TIMESTAMP | — |
| deleted_at | TIMESTAMP | Soft deletes | |
