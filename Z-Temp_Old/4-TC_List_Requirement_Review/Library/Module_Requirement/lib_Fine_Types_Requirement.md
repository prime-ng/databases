# Lib Fine Types — Business Requirements

## What This Screen Does
Manages library fine type definitions — the categories of fines that can be applied to library members (e.g., Late Return, Damaged Book, Lost Book). Each fine type has a unique code, a display name, an optional description, a default monetary amount, and an active/inactive status. Admins can create, edit, view, soft-delete, restore, permanently delete, and toggle the active status of fine types.

---

## When This Screen Is Used
- Setting up the library's fine structure as part of initial configuration.
- Adding a new fine category (e.g., a new "Processing Fee").
- Modifying the default amount or description of an existing fine type.
- Deactivating a fine type so it cannot be selected in new transactions.
- Viewing a list of all fine types (active and trashed) for audit or reference.

## Default Data Load
- Index: Paginated list (10 per page) of all fine types with search (by name) and status filter. Accessed via the Hub tab `fine-types` under Library Configuration.
- Create: Blank form with fields for code, name, description, default_amount, is_active (default true).
- Edit: Pre-populated form with existing fine type data.
- Show: Read-only display of all fine type fields.
- Trash: Paginated list of soft-deleted fine types with restore and force-delete actions.

---

## Key Fields at a Glance
| Field | Type | Constraints | Notes |
|-------|------|-------------|-------|
| code | VARCHAR(30) | UNIQUE, required, max:30 | Machine-readable identifier (e.g., `LATE_RETURN`) |
| name | VARCHAR(100) | required, max:100 | Human-readable display name |
| description | VARCHAR(255) | nullable, max:255 | Optional description of the fine type |
| default_amount | DECIMAL(10,2) | DEFAULT 0.00, nullable, min:0 | Default fine amount; can be overridden per transaction |
| is_active | TINYINT(1) | DEFAULT 1, boolean | Soft on/off toggle |

---

## Business Rules and Conditions
1. **Unique Code:** Each fine type must have a unique `code`. Duplicate codes are rejected at both form validation and DB UNIQUE constraint levels.
2. **Unique Name:** Each fine type must also have a unique `name`. No two fine types can share the same display name — enforced at both validation and DB UNIQUE constraint levels.
3. **Default Amount:** If not provided, `default_amount` defaults to 0.00. A negative amount is never allowed.
4. **Soft Delete:** Deleting a fine type performs a soft delete (sets `deleted_at`). The record is hidden from the main list but retained in the trash.
5. **Restore:** Restoring sets `deleted_at` to NULL. The fine type becomes available again.
6. **Force Delete:** Permanently removes the record. If the fine type is referenced by existing transactions (FK constraint), the operation fails gracefully.
7. **Active Toggle:** The `is_active` flag can be toggled via AJAX. Inactive fine types remain in the database but should not appear as selectable options in new transactions.
8. **Config Tab:** The index view is loaded as a partial inside the Library Configuration hub under the `fine-types` tab.
9. **Pre-seeded Records:** Four default fine types are pre-seeded in the system at installation:
   - `LateReturn` — Charged when books are returned after the due date
   - `LostBook` — Charged when a book is reported lost by a member
   - `DamagedBook` — Charged when a book is returned in damaged condition
   - `ProcessingFee` — Administrative fee for library processing activities
   These pre-seeded types cannot be removed via soft-delete at seed level and serve as the base fine categories for all slab configurations.

---

## Workflow Steps
1. **Admin navigates** to Library Configuration → Fine Types tab.
2. **Admin clicks** "Add Fine Type" to open the create form.
3. **Admin fills in** code, name, description, default_amount, and toggles active status.
4. **System validates** the input (required fields, unique code, valid amount).
5. **System saves** the record and redirects to the fine types list with a success message.
6. **Admin can edit** any existing fine type via the Edit button in the action column.
7. **Admin can toggle** the active status directly from the table via the status switch.
8. **Admin can soft-delete** a fine type; the record moves to trash.
9. **Admin can view** trashed fine types via the "Trash" view.
10. **Admin can restore** from trash or permanently delete.

---

## Example Scenario
**Setting up a "Late Return Fee":**
1. Admin enters code `LATE_RETURN`, name `Late Return Fee`, description `Charged when books are returned after the due date`, default_amount `10.00`.
2. System saves the fine type and displays it in the fine types list.
3. Later, the library increases the fee to `15.00`. Admin edits the fine type and updates `default_amount` to `15.00`.
4. If the library stops charging late fees, Admin canggles the status to inactive.

---

## Related Screens
- **Library Configuration Hub** — The fine types list is rendered as a tab (`fine-types`) within the Library Configuration tabbed page.
- **Fine Transactions** — When issuing fines, the fine type code is selected from the active fine types defined here.
- **Fine Slab Config** — Alternative tiered fine calculation; fine types are used alongside or instead of slab rules.

---

## Requirements
(technical: controller, model, validation, activityLog, policy)

- **Controller:** `LibFineTypeController` — 11 methods: `index` (redirects to config hub with `tab=fine-types`), `create`, `store` (DB transaction), `show`, `edit`, `update`, `destroy`, `trashed`, `restore`, `forceDelete` (catches FK constraint violation 23001), `toggleStatus`.
- **Model:** `LibFineType` — table `lib_fine_types`, fillable: `code`, `name`, `description`, `default_amount`, `is_active`. No relationships defined.
- **Validation (FormRequest):** `code` => required|string|max:30|unique:lib_fine_types,code; `name` => required|string|max:100; `description` => nullable|string|max:255; `default_amount` => nullable|numeric|min:0; `is_active` => boolean.
- **ActivityLog:** Must call `activityLog()` after create, update, delete, restore, forceDelete.
- **Policy:** Gate string `tenant.lib-fine-types.*` mapped to `LibFineTypePolicy`.
- **Permissionslist entry:** `'lib-fine-types' => $crud`

---

## Who Can Access This Screen
- Users with the `tenant.lib-fine-types.viewAny` permission (list/tab visibility).
- Users with `tenant.lib-fine-types.create` (add button and store).
- Users with `tenant.lib-fine-types.view` (show/details).
- Users with `tenant.lib-fine-types.update` (edit, update, toggle status).
- Users with `tenant.lib-fine-types.delete` (soft delete).
- Users with `tenant.lib-fine-types.restore` (trash view, restore).
- Users with `tenant.lib-fine-types.forceDelete` (permanent delete).

---

## How This Screen Works — Logic Flow (Non-Technical)
1. User navigates to the Library section and clicks "Configuration."
2. The system displays a tabbed page. The "Fine Types" tab is one of several configuration tabs.
3. The system loads all fine types from the database and displays them in a table.
4. Each row shows the fine type code, name, default amount, and a status toggle.
5. The user can use the search box to filter by name or the status dropdown to show only active/inactive records.
6. Clicking "Add Fine Type" opens a form where the user fills in the details.
7. When saving, the system checks that the code hasn't been taken and that all required fields are filled.
8. After saving, the new fine type appears in the list.
9. The user can edit, delete, or toggle any fine type using the buttons in the action column.
10. Deleted items go to the trash. The user can restore them or permanently delete them from the trash view.

---

## Validate Before Save
1. Code is required, must be a string ≤30 characters, and must be unique across all fine types.
2. Name is required, must be a string ≤100 characters.
3. Description is optional, ≤255 characters.
4. Default amount is optional but must be a non-negative number if provided.
5. Active status is a boolean flag.
6. Update validation excludes the current record's code from the unique check.

---

## Error Handling and Validation Messages
| Condition | Message |
|-----------|---------|
| Code missing | "The code field is required." |
| Code duplicate | "The code has already been taken." |
| Code too long | "The code must not be greater than 30 characters." |
| Name missing | "The name field is required." |
| Default amount negative | "The default amount must be at least 0." |
| Invalid amount format | "The default amount must be a number." |
| FK violation on force delete | "Cannot delete fine type that is in use" (caught via DB exception) |

---

## Success Scenarios
1. **Create:** Valid fine type data is saved. Redirect to list with "Fine Type created successfully."
2. **Update:** Modified fine type data is saved. Redirect to list with "Fine Type updated successfully."
3. **Toggle Status:** AJAX request flips `is_active`. Returns JSON `{success: true, is_active: bool}`.
4. **Soft Delete:** Record's `deleted_at` is set. Redirect to list with "Fine Type deactivated and trashed."
5. **Restore:** `deleted_at` cleared, `is_active` set to true. Redirect to list with "Fine Type restored successfully."
6. **Force Delete:** Record permanently removed. Redirect to list with "Fine Type permanently deleted."

---

## Failure Scenarios
1. **Create with duplicate code:** Validation fails, form re-displays with error "The code has already been taken."
2. **Update with conflicting code (another record's code):** Validation fails with unique error.
3. **Force delete with existing references:** FK constraint violation caught. User sees a flash error "Cannot delete fine type that is in use."
4. **Toggle status on deleted record:** `findOrFail` throws 404.

---

## Dependencies module and tables
| Dependency | Type | Details |
|-----------|------|---------|
| `lib_fine_types` | Table | Primary table for this feature |
| Library Configuration Hub | View | Tab-based hub that includes the fine types partial under `fine-types` tab |
| `lib-fine-types` | Permission | CRUD permissions defined in `permissionslist.php` |
| `LibFineTypePolicy` | Policy | Authorization policy mapped to `tenant.lib-fine-types.*` |
