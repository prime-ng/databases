# Bloom Taxonomy Master — Business Requirements

## What This Screen Does

The Bloom Taxonomy screen configures the highest echelon of the school's cognitive learning framework. It establishes Benjamin Bloom’s Revised Taxonomy within the system, categorizing the educational goals of the entire curriculum into a hierarchy ranging from low-level retention to high-level synthesis.

This configuration is the foundational cornerstone for all depth of knowledge analytics. Without this setup, the school can only report on how much syllabus was finished, but cannot report on how deeply the students understood it.

---

## When This Screen Is Used

- System Initialization configured once during the initial setup of the educational software
- Framework Customization when an administrator wants to alter the terminology of the 6 standard levels to align with specific international board guidelines
- Analytics Configuration when establishing the baseline levels for cognitive radar charts and pyramid graphs in the reports module

## Default Data Load

This screen displays within the Syllabus Bloom tab group. When the user navigates to Syllabus → Bloom, SyllabusController@bloom() loads all 5 bloom/grid screens simultaneously (Bloom Taxonomy, Cognitive Skills, Question Types, Question Type Specificity, Complexity Levels), each independently paginated at 10 rows per page. A shared Cognitive Skills dropdown is also loaded for filter purposes.

---

---

## Key Fields at a Glance

**Identity and Definition**
A Unique Code acts as a standardized identifier, such as REMEMBERING or EVALUATING, which is heavily referenced in background reporting queries and is usually locked. The Display Name provides the human-readable name shown on dashboards, like 'Remembering' or 'Evaluating'. A Detailed Description provides a thorough pedagogical explanation of the cognitive level, such as the ability to recall facts and basic concepts.

**Hierarchical Ranking**
A Bloom Rank or Level captures a numeric value representing the mathematical rank of the cognitive level. This rank scales from 1 for Remembering, which is base-level thinking, up to 6 for Creating, which is the apex of higher-order thinking. 

**State Management**
A Status Toggle acts as an active or inactive switch. If deactivated, this level and all its associated child skills disappear from tagging dropdowns across the system.

---

## Business Rules and Conditions

**Mathematical Integrity of the Rank**
While the exact textual name is up to the school's specific pedagogical style, the numeric ranks from 1 through 6 must be strictly maintained. Analytical charts, like Cognitive Depth Pyramids, rely entirely on this mathematical progression. Furthermore, a level 6 skill is mathematically treated as more advanced than a level 2 skill by the AI when generating adaptive question papers.

**Foundational Parent-Child Dependency**
This screen acts as the master parent for all granular cognitive skills. The system enforces a strict relational dependency. You cannot define granular cognitive skills like Comparing or Listing without first linking them to a valid Bloom Taxonomy level. If a Bloom level is ever deactivated, cascading logic should ideally disable all associated cognitive skills to preserve assessment integrity.

**Uniqueness Enforcement**
The system ensures that duplicate levels cannot be created, preventing data corruption during complex analytics roll-ups.

---

## Workflow Steps

**Customizing a Cognitive Level**
This is typically a one-time setup performed by System Administrators. The Academic Director reviews the default system installation and navigates to the Bloom Taxonomy screen. They wish to rename the apex level, so they click Edit on the record with Rank 6. They change the Display Name from "Creating" to "Synthesizing & Creating" to match their specific educational board's terminology. They update the description to reflect compiling component ideas into a new whole and save the record. All radar charts and dropdowns instantly update to reflect the new terminology while maintaining the mathematical Rank 6 weighting in the background.

---

## Example Scenario

At the end of the academic year, the school's Board of Directors reviews the Coverage Audit Report. 

The system scans all the assessment questions administered throughout the year, checking their tagged Cognitive Skills, and tracing those skills back to the Bloom Rank defined in this screen. The generated Pyramid Chart visually demonstrates that 75% of all exams were restricted to Ranks 1 and 2, which are Rote Memorization and Basic Understanding. 

Appalled by the lack of higher-order thinking, the Directors mandate a new policy for the upcoming year stating that every Summative Exam blueprint must include a minimum of 20% weightage allocated to questions mapping back to Rank 4 and Rank 5. The system enforces this rule during paper generation based entirely on this master setup.

---

## Related Screens

- **Cognitive Skills** — The child screen where specific sub-skills are created and mapped to these 6 broad levels
- **Coverage Audit Report** — The analytics consumer that transforms Bloom Rank data into visual insights

---

## Requirements

- This screen loads exclusively via the Syllabus Bloom tab view at GET /syllabus/bloom (route: syllabus.bloom.index). The individual controller index route is internal and not directly accessible.bloom.index`).
- The system MUST authorize access via `Gate::authorize()` using the `tenant.bloom-taxonomy.viewAny` permission.
- The system MUST allow users with appropriate permissions to perform CRUD operations: create, store, edit, update, show (`withTrashed()->findOrFail`), destroy (soft-delete: sets `is_active = false` then calls `delete()`), restore, forceDelete, and toggleStatus.
- The system MUST enforce validation rules via FormRequest:
  - `code`: required, string, max:20, alpha, unique on `slb_bloom_taxonomy` (ignoring self on update)
  - `name`: required, string, max:100
  - `description`: nullable, string, max:255
  - `bloom_level`: required, integer, between:1,6
  - `is_active`: nullable, boolean
- The system MUST apply `prepareForValidation()` to uppercase `code` via `strtoupper()` and cast `is_active` to boolean.
- The system MUST paginate results at 10 per page.
- The system MUST order records by `bloom_level` ascending.
- The system MUST log activities for: Stored, Updated, Trashed, Restored, Deleted, Toggled.
- The system MUST support soft deletes via the `SoftDeletes` trait.
- The system MUST redirect to route `syllabus.bloom.index` with tab `bloom_taxonomy` after any CRUD operation.
- The system MUST set `slb_cognitive_skill.bloom_id` to NULL (ON DELETE SET NULL) when a Bloom taxonomy record is force-deleted.

---

## Who Can Access This Screen

| Role | Permission | Access Level |
|---|---|---|
| Super Admin | `tenant.bloom-taxonomy.*` (all permissions) | Full CRUD + restore + forceDelete + toggleStatus |
| Academic Director | `tenant.bloom-taxonomy.viewAny` + `.view` | Read-only (view, show) |
| HOD | `tenant.bloom-taxonomy.viewAny` + `.view` + `.create` + `.update` | Create and Edit (cannot delete or toggle status) |
| Teacher | No explicit permission | No access |

---

## How This Screen Works — Logic Flow (Non-Technical)

1. The user navigates to the aggregate Syllabus page; the Bloom Taxonomy tab triggers the `index()` controller.
2. The screen loads as a tab within the Syllabus Bloom tab view. Then `Gate::authorize()` checks the user's permission.
3. The system fetches all Bloom Taxonomy records (including soft-deleted) ordered by `bloom_level` ascending, paginated at 10 per page.
4. The user clicks "Add New" to open the creation form. The system pre-processes the input via `prepareForValidation()` — uppercasing the code and casting `is_active` to boolean.
5. On submit, the FormRequest validates: code (required, alpha, unique, max:20), name (required, max:100), description (nullable, max:255), bloom_level (required, integer, 1–6), is_active (boolean).
6. If valid, the record is saved and an activity log entry "Stored" is created. The system redirects to the Bloom Taxonomy tab.
7. Existing records can be edited via the edit form; updates go through the same validation (code uniqueness ignores the current record's ID).
8. Deleting a record triggers soft delete: `is_active` is set to `false`, then `delete()` is called. The record remains in the database with `deleted_at` populated.
9. The "Trashed" view shows soft-deleted records. From there, the user can restore (which sets `deleted_at` to `null`) or force-delete (permanently removes the record and sets `bloom_id` to NULL on related cognitive skills).
10. The `toggleStatus()` action flips `is_active` and returns a JSON response `{success, is_active, message}`.
11. The `show()` view uses `withTrashed()->findOrFail($id)` to display both active and trashed records.

---

## Validate Before Save (Multiple Conditions)

1. **Code Required** — `code` field must not be empty. Error: "Bloom taxonomy code is required."
2. **Code Alpha** — `code` must contain only letters. Error: "Code must contain only letters."
3. **Code Max Length** — `code` must not exceed 20 characters. Error: "Code must not exceed 20 characters."
4. **Code Uniqueness** — `code` must be unique in `slb_bloom_taxonomy` table (ignoring the current record on update). Error: "This bloom taxonomy code already exists."
5. **Code Uppercase** — `code` is automatically uppercased via `strtoupper()` in `prepareForValidation()`.
6. **Name Required** — `name` field must not be empty. Error: "Bloom taxonomy name is required."
7. **Name Max Length** — `name` must not exceed 100 characters. Error: "Name must not exceed 100 characters."
8. **Bloom Level Required** — `bloom_level` must not be empty. Error: "Bloom level is required."
9. **Bloom Level Integer** — `bloom_level` must be an integer. Error: "Bloom level must be an integer."
10. **Bloom Level Range** — `bloom_level` must be between 1 and 6. Error: "Bloom level must be between 1 and 6."
11. **Is Active Boolean** — `is_active` is cast to boolean automatically.
12. **Authorization** — `Gate::authorize()` checks the user has the required permission before any operation.

---

## Error Handling and Validation Messages

| Scenario | Error Message | HTTP Status |
|---|---|---|
| Code is empty | "Bloom taxonomy code is required." | 500 |
| Code contains non-alpha characters | "Code must contain only letters." | 500 |
| Code exceeds 20 characters | "Code must not exceed 20 characters." | 500 |
| Duplicate code (already exists) | "This bloom taxonomy code already exists." | 500 |
| Name is empty | "Bloom taxonomy name is required." | 500 |
| Name exceeds 100 characters | "Name must not exceed 100 characters." | 500 |
| Bloom level is empty | "Bloom level is required." | 500 |
| Bloom level is not an integer | "Bloom level must be an integer." | 500 |
| Bloom level is outside 1–6 range | "Bloom level must be between 1 and 6." | 500 |
| Unauthorized access (missing permission) | "This action is unauthorized." | 403 |


---

## Success Scenarios

**SC-001: Creating a New Bloom Taxonomy Level**
1. Admin navigates to the Syllabus page → Bloom Taxonomy tab → clicks "Add New".
2. Enters Code: "CREATING", Name: "Creating", Description: "Putting elements together to form a coherent whole", Bloom Level: 6, Status: Active.
3. System uppercases code, validates all rules, saves the record.
4. Activity log records "Stored". System redirects to the Bloom Taxonomy tab with the new record displayed (ordered by bloom_level).

**SC-002: Deactivating a Bloom Taxonomy Level**
1. Admin finds an existing active level and clicks the toggle status button.
2. System sends a POST request to the `toggleStatus` endpoint.
3. System flips `is_active` from `true` to `false`, returns JSON `{success: true, is_active: false, message: "Status updated successfully"}`.
4. The level is hidden from active dropdowns across the system. Historical associations remain intact.

**SC-003: Restoring a Soft-Deleted Bloom Taxonomy Level**
1. Admin navigates to the "Trashed" view and clicks "Restore" on a deleted record.
2. System sets `deleted_at` to `null` and `is_active` to `true`.
3. Activity log records "Restored". The record reappears in the active list.

---

## Failure Scenarios

**FC-001: Duplicate Code Rejected**
1. Admin attempts to create a new Bloom level with code "REMEMBERING" when a record with the same code already exists.
2. System validation fails with error: "This bloom taxonomy code already exists."
3. Record is not saved. The form remains open with the entered data preserved for correction.

**FC-002: Invalid Bloom Level Range**
1. Admin enters Bloom Level as "7" (outside the valid 1–6 range).
2. System validation fails with error: "Bloom level must be between 1 and 6."
3. Record is not saved. Admin must correct the value to a valid level.

**FC-003: Unauthorized Access Attempt**
1. A Teacher (who lacks `tenant.bloom-taxonomy.viewAny`) directly navigates to the Bloom Taxonomy tab URL.
2. `Gate::authorize()` throws an authorization exception.
3. System returns HTTP 403 with message: "This action is unauthorized."

---

## Dependencies module and tables

| Type | Name | Details |
|---|---|---|
| Primary Table | `slb_bloom_taxonomy` | `id`, `code` VARCHAR(20) UNIQUE, `name` VARCHAR(100), `description` VARCHAR(255), `bloom_level` TINYINT, `is_active` TINYINT(1), `created_at`, `updated_at`, `deleted_at` (SoftDeletes) |
| Related Table | `slb_cognitive_skill` | FK `slb_cognitive_skill.bloom_id` REFERENCES `slb_bloom_taxonomy.id` ON DELETE SET NULL |
| Module Dependency | Syllabus Module | Core module where this master data is configured via `syllabus.bloom.index` route |
| Module Dependency | Assessment Module | Consumes Bloom taxonomy for question cognitive tagging and analytics |
| Module Dependency | User & Permission Module | `Gate::authorize()` checks `tenant.bloom-taxonomy.*` permissions |
