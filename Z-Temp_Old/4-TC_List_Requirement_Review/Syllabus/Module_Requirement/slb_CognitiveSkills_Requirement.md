# Cognitive Skills — Business Requirements

## What This Screen Does

The Cognitive Skills screen acts as the detailed, actionable translation of Bloom's Taxonomy. 

While Bloom's Taxonomy provides broad buckets like Analyzing, teachers cannot effectively tag a question with such a generic label. This screen breaks down those broad buckets into highly specific, granular verbs and skills, such as Differentiating, Organizing, or Attributing. This gives teachers a precise, standardized vocabulary to use when defining the exact educational intent of a lesson or an assessment question.

---

## When This Screen Is Used

- Curriculum Framework Setup when an Academic Coordinator defines the detailed tagging vocabulary for teachers to use across the platform
- Question Bank Population when teachers are adding new questions to the database and must tag what specific mental process the question demands from the student
- NEP Alignment when mapping the school's internal assessment strategy to the skill-based, competency-driven focus of National Education Policies

## Default Data Load

This screen displays within the Syllabus Bloom tab group. When the user navigates to Syllabus → Bloom, SyllabusController@bloom() loads all 5 bloom/grid screens simultaneously (Bloom Taxonomy, Cognitive Skills, Question Types, Question Type Specificity, Complexity Levels), each independently paginated at 10 rows per page. A shared Cognitive Skills dropdown is also loaded for filter purposes.

---

---

## Key Fields at a Glance

**Parent Linkage**
A Target Bloom Level links the specific skill directly to one of the 6 fundamental cognitive levels in the Bloom Taxonomy screen. This firmly anchors the granular skill to a broad pedagogical category.

**Identity and Definition**
A Unique Code acts as a standardized identifier, such as COG-DIFFERENTIATE, which is crucial for data imports and ensuring consistency across different subjects. The Display Name captures the name of the skill shown in dropdowns, like 'Differentiating' or 'Recalling'. A Detailed Description provides a pedagogical explanation of the skill, such as distinguishing relevant from irrelevant parts of presented material.

**State Management**
A Status Toggle acts as an active or inactive switch. If marked as inactive, the skill is hidden from the Question Bank dropdowns, preventing teachers from using deprecated tagging standards without deleting historical data.

---

## Business Rules and Conditions

**Strict Parent-Child Enforcements**
A Cognitive Skill cannot exist in a vacuum. It must be linked to a valid Bloom Taxonomy level. If the parent Bloom level is somehow removed or disabled, the system should flag this cognitive skill as orphaned and prevent it from being used in active exam blueprints until it is re-assigned to a valid level.

**Analytics Roll-up Dependency**
This screen is the backbone of the Cognitive Analytics engine. When the system generates a report, it counts the occurrences of Cognitive Skill tags attached to questions or topics, and then aggregates them upwards using the Target Bloom Level to generate the final Radar and Pyramid charts.

**Uniqueness and Standardization**
The system ensures that duplicate skills cannot be created. This prevents the vocabulary from becoming diluted, which would otherwise confuse teachers during tagging and ruin the accuracy of the analytics.

---

## Workflow Steps

**Adding a New Cognitive Skill**
The Academic Head opens the Cognitive Skills screen and clicks Add New Skill. They enter the Name as "Critiquing". They select the Parent Bloom Level from the dropdown as "Evaluating". They enter the Description to explain detecting inconsistencies or fallacies within a process or product and making judgments based on criteria. They save the record. The system validates the uniqueness of the entry and saves the data. Instantly, the "Critiquing" skill becomes available in the Question Bank tagging interface for all teachers to use.

---

## Example Scenario

An English teacher is creating a complex subjective question asking students to read a provided editorial and identify the author's logical fallacies.

When adding this to the Question Bank, the teacher is prompted to tag its cognitive depth. They don't just tag it as the broad "Evaluating" level. Instead, they open the specific dropdown populated by this screen and select the exact Cognitive Skill, which is "Critiquing".

Months later, when the HOD generates an assessment audit, the system groups all questions tagged with "Critiquing" and automatically rolls them up into the "Evaluating" Bloom Level, providing the Principal with a precise, organized breakdown of higher-order thinking assessments.

---

## Related Screens

- **Bloom Taxonomy** — The parent master configuration screen
- **Question Type Specificity** — Links these precise mental skills to specific mechanical question formats

---

## Requirements

- This screen loads exclusively via the Syllabus Bloom tab view at GET /syllabus/bloom (route: syllabus.bloom.index). The individual controller index route is internal and not directly accessible.bloom.index`).
- The system MUST authorize access via `Gate::authorize()` using the `tenant.cognitive-skill.viewAny` permission.
- The system MUST allow users with appropriate permissions to perform CRUD operations: create, store, edit, update, show (`withTrashed()->findOrFail`), destroy (soft-delete: sets `is_active = false` then calls `delete()`), restore, forceDelete, and toggleStatus.
- The system MUST enforce validation rules via FormRequest:
  - `bloom_id`: nullable (no explicit exists rule in code, but FK constraint exists at DB level)
  - `code`: required, string, max:20, alpha, unique on `slb_cognitive_skill` (ignoring self on update)
  - `name`: required, string, max:100
  - `description`: nullable, string, max:255
  - `is_active`: nullable, boolean
- The system MUST apply `prepareForValidation()` to uppercase `code` via `strtoupper()` and cast `is_active` to boolean.
- The system MUST paginate results at 10 per page.
- The system MUST log activities for: Stored, Updated, Trashed, Restored, Deleted, Toggled.
- The system MUST support soft deletes via the `SoftDeletes` trait.
- The system MUST redirect to route `syllabus.bloom.index` with tab `cognitive_skills` after any CRUD operation.
- The system MUST set `slb_ques_type_specificity.cognitive_skill_id` to NULL (ON DELETE SET NULL) when a cognitive skill record is force-deleted.

---

## Who Can Access This Screen

| Role | Permission | Access Level |
|---|---|---|
| Super Admin | `tenant.cognitive-skill.*` (all permissions) | Full CRUD + restore + forceDelete + toggleStatus |
| Academic Director | `tenant.cognitive-skill.viewAny` + `.view` | Read-only (view, show) |
| HOD | `tenant.cognitive-skill.viewAny` + `.view` + `.create` + `.update` | Create and Edit (cannot delete or toggle status) |
| Teacher | No explicit permission | No access |

---

## How This Screen Works — Logic Flow (Non-Technical)

1. The user navigates to the aggregate Syllabus page; the Cognitive Skills tab triggers the `index()` controller.
2. The screen loads as a tab within the Syllabus Bloom tab view. Then `Gate::authorize()` checks the user's permission.
3. The system fetches all Cognitive Skill records (including soft-deleted) paginated at 10 per page.
4. The user clicks "Add New" to open the creation form. A dropdown lets the user select a parent Bloom Taxonomy level.
5. The system pre-processes the input via `prepareForValidation()` — uppercasing the code and casting `is_active` to boolean.
6. On submit, the FormRequest validates: bloom_id (nullable), code (required, alpha, unique, max:20), name (required, max:100), description (nullable, max:255), is_active (boolean). No explicit exists rule validates the Bloom ID in code; the FK constraint at database level ensures referential integrity.
7. If valid, the record is saved and an activity log entry "Stored" is created. The system redirects to the Cognitive Skills tab.
8. Existing records can be edited via the edit form; updates go through the same validation (code uniqueness ignores the current record's ID).
9. Deleting a record triggers soft delete: `is_active` is set to `false`, then `delete()` is called. The record remains in the database with `deleted_at` populated.
10. The "Trashed" view shows soft-deleted records. From there, the user can restore (which sets `deleted_at` to `null`) or force-delete (permanently removes the record and sets `cognitive_skill_id` to NULL on related question type specificity records).
11. The `toggleStatus()` action flips `is_active` and returns a JSON response `{success, is_active, message}`.
12. The `show()` view uses `withTrashed()->findOrFail($id)` to display both active and trashed records.

---

## Validate Before Save (Multiple Conditions)

1. **Code Required** — `code` field must not be empty. Error: "Cognitive skill code is required."
2. **Code Alpha** — `code` must contain only letters. Error: "Code must contain only letters."
3. **Code Max Length** — `code` must not exceed 20 characters. Error: "Code must not exceed 20 characters."
4. **Code Uniqueness** — `code` must be unique in `slb_cognitive_skill` table (ignoring the current record on update). Error: "This cognitive skill code already exists."
5. **Code Uppercase** — `code` is automatically uppercased via `strtoupper()` in `prepareForValidation()`.
6. **Name Required** — `name` field must not be empty. Error: "Cognitive skill name is required."
7. **Name Max Length** — `name` must not exceed 100 characters. Error: "Name must not exceed 100 characters."
8. **Parent Bloom ID** — `bloom_id` is nullable; no explicit exists validation in FormRequest, but DB FK constraint enforces referential integrity.
9. **Is Active Boolean** — `is_active` is cast to boolean automatically.
10. **Authorization** — `Gate::authorize()` checks the user has the required permission before any operation.

---

## Error Handling and Validation Messages

| Scenario | Error Message | HTTP Status |
|---|---|---|
| Code is empty | "Cognitive skill code is required." | 500 |
| Code contains non-alpha characters | "Code must contain only letters." | 500 |
| Code exceeds 20 characters | "Code must not exceed 20 characters." | 500 |
| Duplicate code (already exists) | "This cognitive skill code already exists." | 500 |
| Name is empty | "Cognitive skill name is required." | 500 |
| Name exceeds 100 characters | "Name must not exceed 100 characters." | 500 |
| Invalid Bloom Taxonomy reference | "Selected Bloom Taxonomy is invalid." | 500 |
| Unauthorized access (missing permission) | "This action is unauthorized." | 403 |

| Foreign key violation (invalid bloom_id) | DB constraint error | 500 |

---

## Success Scenarios

**SC-001: Creating a New Cognitive Skill**
1. Admin navigates to the Syllabus page → Cognitive Skills tab → clicks "Add New".
2. Enters Code: "COG_CRITIQUE", Name: "Critiquing", selects "Evaluating" as parent Bloom Taxonomy, Status: Active.
3. System uppercases code, validates all rules, saves the record.
4. Activity log records "Stored". System redirects to the Cognitive Skills tab with the new skill available for question tagging.

**SC-002: Deactivating a Cognitive Skill**
1. Admin finds an existing active skill and clicks the toggle status button.
2. System sends a POST request to the `toggleStatus` endpoint.
3. System flips `is_active` from `true` to `false`, returns JSON `{success: true, is_active: false, message: "Status updated successfully"}`.
4. The skill is hidden from active tagging dropdowns in the Question Bank. Historical question data remains intact.

**SC-003: Restoring a Soft-Deleted Cognitive Skill**
1. Admin navigates to the "Trashed" view and clicks "Restore" on a deleted record.
2. System sets `deleted_at` to `null` and `is_active` to `true`.
3. Activity log records "Restored". The record reappears in the active list.

---

## Failure Scenarios

**FC-001: Duplicate Code Rejected**
1. Admin attempts to create a cognitive skill with code "COG_CRITIQUE" when a record with the same code already exists.
2. System validation fails with error: "This cognitive skill code already exists."
3. Record is not saved. The form remains open with the entered data preserved for correction.

**FC-002: Invalid Bloom Taxonomy Reference**
1. Admin selects a Bloom Taxonomy level that does not exist (e.g., deleted or invalid ID).
2. While the FormRequest has no explicit `exists` rule, the database FK constraint rejects the invalid reference.
3. The operation fails with a database integrity error.

**FC-003: Unauthorized Access Attempt**
1. A user lacking `tenant.cognitive-skill.viewAny` navigates to the Cognitive Skills tab.
2. `Gate::authorize()` throws an authorization exception.
3. System returns HTTP 403 with message: "This action is unauthorized."

---

## Dependencies module and tables

| Type | Name | Details |
|---|---|---|
| Primary Table | `slb_cognitive_skill` | `id`, `bloom_id` FK → `slb_bloom_taxonomy.id` ON DELETE SET NULL, `code` VARCHAR(20) UNIQUE, `name` VARCHAR(100), `description` VARCHAR(255), `is_active` TINYINT(1), `created_at`, `updated_at`, `deleted_at` (SoftDeletes) |
| Related Table | `slb_bloom_taxonomy` | Parent table; FK `slb_cognitive_skill.bloom_id` REFERENCES `slb_bloom_taxonomy.id` |
| Related Table | `slb_ques_type_specificity` | FK `slb_ques_type_specificity.cognitive_skill_id` REFERENCES `slb_cognitive_skill.id` ON DELETE SET NULL |
| Module Dependency | Syllabus Module | Core module where this master data is configured via `syllabus.bloom.index` route |
| Module Dependency | Assessment Module | Question Bank consumes cognitive skills for question tagging |
| Module Dependency | User & Permission Module | `Gate::authorize()` checks `tenant.cognitive-skill.*` permissions |
