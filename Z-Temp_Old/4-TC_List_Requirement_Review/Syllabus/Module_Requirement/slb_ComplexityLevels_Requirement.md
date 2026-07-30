# Complexity Levels Master — Business Requirements

## What This Screen Does

The Complexity Levels screen acts as a vital calibration tool for the Assessment Engine. It provides a master reference configuration that categorizes the difficulty of any given topic or question, such as Easy, Medium, or Hard. 

This is the primary metric used to balance question papers, generate automated exam blueprints, and power adaptive testing algorithms.

---

## When This Screen Is Used

- System Setup configured during initial deployment to define the school's difficulty scale
- Question Creation whenever a teacher adds a question to the Question Bank, they are forced to assign a complexity level from this list
- Automated Exam Generation when an Exam Coordinator tells the system to generate a 100-mark paper with a specific ratio of Easy, Medium, and Hard questions

## Default Data Load

This screen displays within the Syllabus Bloom tab group. When the user navigates to Syllabus → Bloom, SyllabusController@bloom() loads all 5 bloom/grid screens simultaneously (Bloom Taxonomy, Cognitive Skills, Question Types, Question Type Specificity, Complexity Levels), each independently paginated at 10 rows per page. A shared Cognitive Skills dropdown is also loaded for filter purposes.

---

---

## Key Fields at a Glance

**Identity and Nomenclature**
A Unique Code acts as the standardized system identifier, such as EASY, MEDIUM, or DIFFICULT, ensuring consistency across data imports. A Display Name provides the human-readable name shown to teachers, like 'Easy', 'Hard', or 'High Order Thinking Skills'.

**Hierarchical Ranking and Mathematics**
A Complexity Rank captures a numeric value representing the mathematical weight or rank of the difficulty. This scales from 1 for Easy up to 4 for Expert. This is not just a label; it is a critical mathematical operator used by the system for sorting, filtering, and adaptive logic.

**State Management**
A Status Toggle acts as an active or inactive switch to enable or disable the level without destroying historical question data.

---

## Business Rules and Conditions

**Mathematical Hierarchy Integrity**
The numeric rank is critical. It allows the system to mathematically understand that a Rank 3 is definitively harder than a Rank 1. This enables Adaptive Testing logic where if a student answers a Rank 1 question correctly, the adaptive algorithm searches the database for questions with a rank higher than 1. If a student fails a Rank 2 question, the system searches for questions with a rank lower than 2 to serve as remedial practice.

**Strict Uniqueness Constraints**
The system ensures that no two complexity levels can share the same unique code. This ensures that automated question paper blueprints do not accidentally query duplicate or ambiguous difficulty pools.

**Immutability of Used Levels**
If a specific Complexity Level like Easy has already been tagged to thousands of questions in the Question Bank, the system must restrict the deletion of this level. It must only allow the Status Toggle to be set to inactive, ensuring that historical analytical reports do not crash due to missing references.

---

## Workflow Steps

**Adding an Advanced Complexity Level**
The Admin navigates to the Complexity Levels screen because the school decides to introduce extreme challenge questions for Olympiad preparation. The Admin clicks Add New Complexity Level. They enter the Name as "Expert / Olympiad Level" and the Code as "EXPERT". They set the Complexity Rank to 4, which is mathematically higher than the existing rank of 3 for Difficult. They save the record, and teachers instantly see this new level as an option when uploading massive calculation-based questions to the bank.

---

## Example Scenario

The Examination Department is creating a blueprint for the critical Class 10 Pre-Board Exams. Instead of manually picking 50 individual questions, the Exam Head sets a purely algorithmic blueprint rule in the Exam Generator. 

They instruct the system to select 10 questions where the Topic is Trigonometry and Complexity Level is Easy, 15 questions where the Complexity Level is Medium, and 5 questions where the Complexity Level is Difficult. The Exam Engine queries the Question Bank based precisely on the numeric ranks defined in this screen. It executes randomized selection and auto-generates a perfectly balanced exam paper in seconds, eliminating human bias.

---

## Related Screens

- **Question Bank Module** — Every single question must be tagged with a complexity level from this configuration
- **Syllabus Reports** — Analytics can cross-reference this to show if a student perfectly answers Easy questions but completely fails Medium or Difficult ones

---

## Requirements

- This screen loads exclusively via the Syllabus Bloom tab view at GET /syllabus/bloom (route: syllabus.bloom.index). The individual controller index route is internal and not directly accessible.bloom.index`).
- The system MUST authorize access via `Gate::authorize()` using the `tenant.complexity-level.viewAny` permission.
- The system MUST allow users with appropriate permissions to perform CRUD operations: create, store, edit, update, show (`withTrashed()->findOrFail`), destroy (soft-delete: sets `is_active = false` then calls `delete()`), restore, forceDelete, and toggleStatus.
- The system MUST enforce validation rules via FormRequest:
  - `code`: required, string, max:20, unique on `slb_complexity_level` (ignoring self on update)
  - `name`: required, string, max:50
  - `complexity_level`: nullable, integer, between:1,3 (1=Easy, 2=Medium, 3=Difficult)
  - `is_active`: nullable, boolean
- The system MUST apply `prepareForValidation()` to uppercase `code` via `strtoupper()` and cast `is_active` to boolean.
- The system MUST paginate results at 10 per page.
- The system MUST log activities for: Stored, Updated, Trashed, Restored, Deleted, Toggled.
- The system MUST support soft deletes via the `SoftDeletes` trait.
- The system MUST redirect to route `syllabus.bloom.index` with tab `complexity_levels` after any CRUD operation.

---

## Who Can Access This Screen

| Role | Permission | Access Level |
|---|---|---|
| Super Admin | `tenant.complexity-level.*` (all permissions) | Full CRUD + restore + forceDelete + toggleStatus |
| Academic Director | `tenant.complexity-level.viewAny` + `.view` | Read-only (view, show) |
| HOD | `tenant.complexity-level.viewAny` + `.view` + `.create` + `.update` | Create and Edit (cannot delete or toggle status) |
| Teacher | No explicit permission | No access |

---

## How This Screen Works — Logic Flow (Non-Technical)

1. The user navigates to the aggregate Syllabus page; the Complexity Levels tab triggers the `index()` controller.
2. The screen loads as a tab within the Syllabus Bloom tab view. Then `Gate::authorize()` checks the user's permission.
3. The system fetches all Complexity Level records (including soft-deleted) paginated at 10 per page.
4. The user clicks "Add New" to open the creation form. The system pre-processes the input via `prepareForValidation()` — uppercasing the code and casting `is_active` to boolean.
5. On submit, the FormRequest validates: code (required, unique, max:20), name (required, max:50), complexity_level (nullable, integer, between 1–3), is_active (boolean).
6. If valid, the record is saved and an activity log entry "Stored" is created. The system redirects to the Complexity Levels tab.
7. Existing records can be edited via the edit form; updates go through the same validation (code uniqueness ignores the current record's ID).
8. Deleting a record triggers soft delete: `is_active` is set to `false`, then `delete()` is called. The record remains in the database with `deleted_at` populated.
9. The "Trashed" view shows soft-deleted records. From there, the user can restore (which sets `deleted_at` to `null`) or force-delete (permanently removes the record).
10. The `toggleStatus()` action flips `is_active` and returns a JSON response `{success, is_active, message}`.
11. The `show()` view uses `withTrashed()->findOrFail($id)` to display both active and trashed records.

---

## Validate Before Save (Multiple Conditions)

1. **Code Required** — `code` field must not be empty. Error: "Complexity level code is required."
2. **Code Max Length** — `code` must not exceed 20 characters. Error: "Code must not exceed 20 characters."
3. **Code Uniqueness** — `code` must be unique in `slb_complexity_level` table (ignoring the current record on update). Error: "This complexity level code already exists."
4. **Code Uppercase** — `code` is automatically uppercased via `strtoupper()` in `prepareForValidation()`.
5. **Name Required** — `name` field must not be empty. Error: "Complexity level name is required."
6. **Name Max Length** — `name` must not exceed 50 characters. Error: "Name must not exceed 50 characters."
7. **Complexity Level Integer** — `complexity_level` must be an integer if provided. (Nullable field.)
8. **Complexity Level Range** — `complexity_level` must be between 1 and 3 (1=Easy, 2=Medium, 3=Difficult). Error: "Complexity level must be Easy, Medium, or Difficult."
9. **Is Active Boolean** — `is_active` is cast to boolean automatically.
10. **Authorization** — `Gate::authorize()` checks the user has the required permission before any operation.

---

## Error Handling and Validation Messages

| Scenario | Error Message | HTTP Status |
|---|---|---|
| Code is empty | "Complexity level code is required." | 500 |
| Code exceeds 20 characters | "Code must not exceed 20 characters." | 500 |
| Duplicate code (already exists) | "This complexity level code already exists." | 500 |
| Name is empty | "Complexity level name is required." | 500 |
| Name exceeds 50 characters | "Name must not exceed 50 characters." | 500 |
| Complexity level is outside 1–3 range | "Complexity level must be Easy, Medium, or Difficult." | 500 |
| Unauthorized access (missing permission) | "This action is unauthorized." | 403 |


---

## Success Scenarios

**SC-001: Creating a New Complexity Level**
1. Admin navigates to the Syllabus page → Complexity Levels tab → clicks "Add New".
2. Enters Code: "EXPERT", Name: "Expert Level", Complexity Level: 3 (Difficult), Status: Active.
3. System uppercases code, validates all rules, saves the record.
4. Activity log records "Stored". System redirects to the Complexity Levels tab with the new level available for question tagging.

**SC-002: Deactivating a Complexity Level**
1. Admin finds an existing active level and clicks the toggle status button.
2. System sends a POST request to the `toggleStatus` endpoint.
3. System flips `is_active` from `true` to `false`, returns JSON `{success: true, is_active: false, message: "Status updated successfully"}`.
4. The level is hidden from active dropdowns. Existing questions retain their complexity tag for historical reporting.

**SC-003: Restoring a Soft-Deleted Complexity Level**
1. Admin navigates to the "Trashed" view and clicks "Restore" on a deleted record.
2. System sets `deleted_at` to `null` and `is_active` to `true`.
3. Activity log records "Restored". The record reappears in the active list.

---

## Failure Scenarios

**FC-001: Duplicate Code Rejected**
1. Admin attempts to create a complexity level with code "EASY" when a record with the same code already exists.
2. System validation fails with error: "This complexity level code already exists."
3. Record is not saved. The form remains open with the entered data preserved for correction.

**FC-002: Invalid Complexity Level Value**
1. Admin enters Complexity Level as "4" (outside the valid 1–3 range).
2. System validation fails with error: "Complexity level must be Easy, Medium, or Difficult."
3. Record is not saved. Admin must correct the value to 1, 2, or 3.

**FC-003: Unauthorized Access Attempt**
1. A user lacking `tenant.complexity-level.viewAny` navigates to the Complexity Levels tab.
2. `Gate::authorize()` throws an authorization exception.
3. System returns HTTP 403 with message: "This action is unauthorized."

---

## Dependencies module and tables

| Type | Name | Details |
|---|---|---|
| Primary Table | `slb_complexity_level` | `id`, `code` VARCHAR(20) UNIQUE, `name` VARCHAR(50), `complexity_level` TINYINT, `is_active` TINYINT(1), `created_at`, `updated_at`, `deleted_at` (SoftDeletes) |
| Module Dependency | Syllabus Module | Core module where this master data is configured via `syllabus.bloom.index` route |
| Module Dependency | Assessment Module | Exam blueprint engine and adaptive testing rely on complexity rank for question selection |
| Module Dependency | User & Permission Module | `Gate::authorize()` checks `tenant.complexity-level.*` permissions |
