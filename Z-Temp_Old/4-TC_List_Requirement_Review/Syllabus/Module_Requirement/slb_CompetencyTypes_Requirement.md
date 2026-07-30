# Competency Types Master — Business Requirements

## What This Screen Does

The Competency Types screen is a high-level master configuration interface. It acts as the ultimate categorisation dictionary for all educational outcomes and skills tracked by the school.

Instead of throwing hundreds of granular skills into one massive, unmanageable list, this screen allows schools to group them into broad, distinct pedagogical categories, such as Cognitive Knowledge, Practical Skills, or Behavioral Attitudes. This is the absolute first step in aligning a school's digital system with national mandates like the National Education Policy or National Curriculum Framework.

---

## When This Screen Is Used

- Initial Setup configured by administrators before any syllabus or skill mapping begins
- Policy Adaptation when the government introduces a new educational mandate like tracking Financial Literacy or 21st Century Skills as distinct domains
- Report Configuration when setting up the legends and categories for Radar Charts or Performance Audits

## Default Data Load

This screen displays within the Syllabus Master tab group. When the user navigates to Syllabus → Master, SyllabusController@master() loads all master tab data simultaneously (Lessons, Topics, Competencies, etc.), each independently paginated at 10 rows per page. Shared dropdowns (Class, Section, Subject, Academic Session, Book) are fetched as active records with no pagination.

---

---

## Key Fields at a Glance

**Identity and Definition**
A Unique Code acts as a standardized system identifier, such as KNOWLEDGE, SKILL, or ATTITUDE. Because this code is heavily relied upon by backend reporting tools, it must be unique and is usually locked once it is in use. The Display Name provides a human-readable label displayed in dropdowns across the system, while a detailed Description explains exactly what this broad category encapsulates.

**State Management**
A Status Toggle acts as an active or inactive switch. If marked as inactive, this Competency Type will no longer appear as an option when users are creating new specific skills, keeping the dropdowns clean without deleting historical data.

---

## Business Rules and Conditions

**Foundational Dependency**
This screen acts as the parent category for all individual competencies. The system enforces a strict dependency rule preventing the deletion of a Competency Type if there are individual skills currently linked to it. The system must prevent deletion and instead encourage administrators to deactivate it.

**Uniqueness and Data Cleanliness**
The unique code must not be duplicated. The system should automatically format user input, such as converting text to uppercase and replacing spaces, before saving to ensure data cleanliness and consistency for reporting.

**Analytics Roll-up**
When the Coverage Audit report is generated, the system dynamically groups all granular outcomes under these Types. If a type exists here but has zero topics mapped to it downstream in the syllabus, the reports will flag it as a Deficient Domain, alerting the Principal that an entire category of learning is being ignored.

---

## Workflow Steps

**Adding a New Competency Type**
The Administrator navigates to the Competency Types screen. They click Add New Type and enter the Name as "Socio-Emotional Learning". They enter the Code as "SEL_DOMAIN" and provide a Description explaining that it tracks emotional intelligence and empathy. Upon saving the record, the "Socio-Emotional Learning" type instantly becomes available as a category when teachers or HODs are defining new specific skills.

---

## Example Scenario

An International Baccalaureate school uses the system. The IB framework requires tracking specific "Learner Profiles" like Inquirers, Thinkers, and Risk-takers. 

The school administrator uses the Competency Types screen to create a new broad category called "IB Learner Profile". Following this, they go to the Competencies screen and create the specific traits, linking them to this new category. At the end of the term, the Principal can generate a specialized report filtered exclusively by the "IB Learner Profile" category. This instantly generates the official, compliant tracking documentation required for external audits without manual data sorting.

---

## Related Screens

- **Competencies** — The child screen where granular skills are created and linked to these broad types
- **Coverage Audit Report** — Uses these types to generate high-level pie charts and radar graphs showing syllabus distribution

---

## Requirements

- This screen loads exclusively via the Syllabus Master tab view at GET /syllabus/master (route: syllabus.master.index). The individual controller index route is internal and not directly accessible.
- The system MUST authorize access via `Gate::authorize()` using the `tenant.competency-type.viewAny` permission.
- The system MUST allow users with appropriate permissions to perform CRUD operations: create, store, edit, update, show (`withTrashed()->findOrFail`), destroy (soft-delete: sets `is_active = false` then calls `delete()`), restore, forceDelete, and toggleStatus.
- The system MUST enforce validation rules via FormRequest:
  - `code`: required, string, max:20, alpha_dash, unique on `slb_competency_types` (ignoring self on update)
  - `name`: required, string, max:100
  - `description`: nullable, string, max:255
  - `is_active`: nullable, boolean (default TRUE on create, FALSE on update if unchecked)
- The system MUST apply `prepareForValidation()` to uppercase `code` via `strtoupper()` and cast `is_active` to boolean.
- The system MUST paginate results at 10 per page.
- The system MUST log activities for: Stored, Updated, Trashed, Restored, Deleted, Toggled.
- The system MUST support soft deletes via the `SoftDeletes` trait.
- The system MUST redirect to route `syllabus.master.index` with tab `competency_types` after any CRUD operation.
- The system MUST cascade delete child `slb_competencies` records (ON DELETE CASCADE) when a competency type record is force-deleted.

---

## Who Can Access This Screen

| Role | Permission | Access Level |
|---|---|---|
| Super Admin | `tenant.competency-type.*` (all permissions) | Full CRUD + restore + forceDelete + toggleStatus |
| Academic Director | `tenant.competency-type.viewAny` + `.view` | Read-only (view, show) |
| HOD | `tenant.competency-type.viewAny` + `.view` + `.create` + `.update` | Create and Edit (cannot delete or toggle status) |
| Teacher | No explicit permission | No access |

---

## How This Screen Works — Logic Flow (Non-Technical)

1. The user navigates to the aggregate Syllabus master page; the Competency Types tab triggers the `index()` controller.
2. The screen loads as a tab within the Syllabus Master tab view. Then `Gate::authorize()` checks the user's permission.
3. The system fetches all Competency Type records (including soft-deleted) paginated at 10 per page.
4. The user clicks "Add New" to open the creation form. The system pre-processes the input via `prepareForValidation()` — uppercasing the code and casting `is_active` to boolean.
5. On submit, the FormRequest validates: code (required, alpha_dash, unique, max:20), name (required, max:100), description (nullable, max:255), is_active (boolean).
6. If valid, the record is saved with `is_active` defaulting to `true`. An activity log entry "Stored" is created. The system redirects to the Competency Types tab.
7. Existing records can be edited via the edit form; updates go through the same validation (code uniqueness ignores the current record's ID).
8. Deleting a record triggers soft delete: `is_active` is set to `false`, then `delete()` is called. The record remains in the database with `deleted_at` populated.
9. The "Trashed" view shows soft-deleted records. From there, the user can restore (which sets `deleted_at` to `null`) or force-delete (permanently removes the record and cascades to delete child competencies).
10. The `toggleStatus()` action flips `is_active` and returns a JSON response `{success, is_active, message}`.
11. The `show()` view uses `withTrashed()->findOrFail($id)` to display both active and trashed records.

---

## Validate Before Save (Multiple Conditions)

1. **Code Required** — `code` field must not be empty. Error: "Competency type code is required."
2. **Code Alpha Dash** — `code` may only contain letters, numbers, dashes and underscores. Error: "Code may only contain letters, numbers, dashes and underscores."
3. **Code Max Length** — `code` must not exceed 20 characters. Error: "Code must not exceed 20 characters."
4. **Code Uniqueness** — `code` must be unique in `slb_competency_types` table (ignoring the current record on update). Error: "This competency type code already exists."
5. **Code Uppercase** — `code` is automatically uppercased via `strtoupper()` in `prepareForValidation()`.
6. **Name Required** — `name` field must not be empty. Error: "Competency type name is required."
7. **Name Max Length** — `name` must not exceed 100 characters. Error: "Name must not exceed 100 characters."
8. **Is Active Boolean** — `is_active` is cast to boolean automatically. Defaults to `true` on create, `false` on update if unchecked.
9. **Authorization** — `Gate::authorize()` checks the user has the required permission before any operation.

---

## Error Handling and Validation Messages

| Scenario | Error Message | HTTP Status |
|---|---|---|
| Code is empty | "Competency type code is required." | 500 |
| Code contains invalid characters | "Code may only contain letters, numbers, dashes and underscores." | 500 |
| Code exceeds 20 characters | "Code must not exceed 20 characters." | 500 |
| Duplicate code (already exists) | "This competency type code already exists." | 500 |
| Name is empty | "Competency type name is required." | 500 |
| Name exceeds 100 characters | "Name must not exceed 100 characters." | 500 |
| Unauthorized access (missing permission) | "This action is unauthorized." | 403 |


---

## Success Scenarios

**SC-001: Creating a New Competency Type**
1. Admin navigates to the Syllabus master page → Competency Types tab → clicks "Add New".
2. Enters Code: "SEL_DOMAIN", Name: "Socio-Emotional Learning", Description: "Tracks emotional intelligence and empathy", Status: Active.
3. System uppercases code to "SEL_DOMAIN", validates all rules, saves the record with `is_active = true`.
4. Activity log records "Stored". System redirects to the Competency Types tab with the new type available for competency creation.

**SC-002: Deactivating a Competency Type**
1. Admin finds an existing active type and clicks the toggle status button.
2. System sends a POST request to the `toggleStatus` endpoint.
3. System flips `is_active` from `true` to `false`, returns JSON `{success: true, is_active: false, message: "Status updated successfully"}`.
4. The type is hidden from dropdowns when creating new competencies. Existing associations are retained for historical reporting.

**SC-003: Restoring a Soft-Deleted Competency Type**
1. Admin navigates to the "Trashed" view and clicks "Restore" on a deleted record.
2. System sets `deleted_at` to `null` and `is_active` to `true`.
3. Activity log records "Restored". The record reappears in the active list.

---

## Failure Scenarios

**FC-001: Duplicate Code Rejected**
1. Admin attempts to create a competency type with code "KNOWLEDGE" when a record with the same code already exists.
2. System validation fails with error: "This competency type code already exists."
3. Record is not saved. The form remains open with the entered data preserved for correction.

**FC-002: Invalid Characters in Code**
1. Admin enters code "KNOWLEDGE DOMAIN" (with a space) which violates the `alpha_dash` rule.
2. System validation fails with error: "Code may only contain letters, numbers, dashes and underscores."
3. Record is not saved. Admin must replace the space with a dash or underscore.

**FC-003: Unauthorized Access Attempt**
1. A user lacking `tenant.competency-type.viewAny` navigates to the Competency Types tab.
2. `Gate::authorize()` throws an authorization exception.
3. System returns HTTP 403 with message: "This action is unauthorized."

---

## Dependencies module and tables

| Type | Name | Details |
|---|---|---|
| Primary Table | `slb_competency_types` | `id`, `code` VARCHAR(20) UNIQUE, `name` VARCHAR(100), `description` VARCHAR(255), `is_active` TINYINT(1), `created_at`, `updated_at`, `deleted_at` (SoftDeletes) |
| Related Table | `slb_competencies` | FK `slb_competencies.competency_type_id` REFERENCES `slb_competency_types.id` ON DELETE CASCADE |
| Module Dependency | Syllabus Module | Core module where this master data is configured via `syllabus.master.index` route |
| Module Dependency | Assessment Module | Consumes competency types for performance audit grouping |
| Module Dependency | User & Permission Module | `Gate::authorize()` checks `tenant.competency-type.*` permissions |
