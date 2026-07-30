# Library Config — Business Requirements

## What This Screen Does

The Library Config screen displays global library configuration settings stored as key-value pairs. These settings control system-wide rules such as default loan periods, borrowing limits, and operational parameters. Each setting is associated with an academic year, enabling year-specific configuration overrides alongside global defaults. The screen provides a paginated listing of all settings with inline editing of setting values and descriptions, supporting search across setting key, value, and description fields.

This screen is lightweight — it only supports viewing and editing existing settings. Users cannot create new settings or delete them; the system seeds the required configuration entries during module setup.

---

## When This Screen Is Used

- When the librarian needs to change default borrowing rules such as the maximum number of books a member can borrow
- When updating fine rates, renewal limits, or loan period defaults
- When reviewing current configuration values for a specific academic year
- When checking which settings are active or inactive

## Default Data Load

The screen opens with a paginated table (20 records per page) of all `lib_library_config` records ordered by newest first, with each record showing the academic year association via the `academicYear` relationship. A search bar filters by `setting_key`, `description`, or `setting_value` using LIKE matching. The screen supports AJAX-based partial reload via `wantsJson()` and returns rendered table rows + pagination HTML for AJAX calls.

---

---

## Key Fields at a Glance

**Core Configuration Structure**
Every config record has a unique `setting_key` (varchar 100) combined with an `academic_year_id` to allow year-specific overrides. A NULL `academic_year_id` means the setting is a global default applicable across all years. The `setting_value` column stores the actual value as VARCHAR(500), and the `value_type` enum (`string`, `integer`, `decimal`, `boolean`, `json`) tells the system how to interpret and display the stored value.

**Description and Active Status**
Each setting includes a textual `description` explaining its purpose. Settings can be toggled active or inactive using the `is_active` boolean, allowing the library team to disable a rule without deleting it.

---

## Business Rules and Conditions

1. **Immutable Keys** — Users cannot add new settings or delete existing ones. Only `setting_value` and `description` can be updated.
2. **Academic Year Scoping** — The unique constraint `uq_lib_libSettings_year_key` ensures that a given `setting_key` can only appear once per `academic_year_id` (including NULL for global defaults).
3. **Inline AJAX Update** — The `update()` method validates `setting_value` (nullable, max 500) and `description` (nullable, max 255), updates the record, and returns a JSON response with the updated values.
4. **Soft Deletes** — Records use the `SoftDeletes` trait but setting deletion is not exposed through the UI.
5. **Authorization** — Both `index()` and `update()` use `Gate::authorize('tenant.lib-transactions-history.viewAny')` (the same permission as Transaction History since Config is nested under the History & Audit hub).

---

## Workflow Steps

1. User navigates to Library → History & Audit → Library Settings tab
2. System loads the paginated table of all configuration records
3. User optionally uses the search bar to filter by key, value, or description
4. User clicks the Edit/Update button on any row
5. An inline editor (modal or direct field edit) appears for `setting_value` and `description`
6. User modifies the values and clicks Save
7. System validates, updates the record, and returns a JSON success response
8. The table row refreshes to show the updated values

---

## Example Scenario

The school librarian needs to reduce the maximum borrow limit from 5 books to 3 books for the current academic year. They navigate to Library Settings, search for the setting key "MAX_BOOKS_ALLOWED", click the edit button, change the value from "5" to "3", and save. The system validates the input and updates the record instantly. The borrowing rule change takes effect immediately for all new transactions.

---

## Related Screens

- **Library Main Hub** — Parent hub containing the Library Settings tab within the History & Audit section
- **Membership Types** — Defines membership-level overrides for borrowing limits that can supersede global config values
- **Fine Slab Config** — Defines fine calculation rules that reference configuration for defaults

---

## Requirements

**Controller:** `Modules\Library\Http\Controllers\LibLibraryConfigController`
**Model:** `Modules\Library\Models\LibLibraryConfig` (table: `lib_library_config`, uses `SoftDeletes`)
**FormRequest:** No dedicated FormRequest — inline validation via `$request->validate()` in `update()` method
**Policy:** No dedicated policy — uses `Gate::authorize('tenant.lib-transactions-history.viewAny')` directly
**Route:** `GET /library-settings` (index), `PUT /library-settings/{id}` (update) — named `lib-library-settings.index` and `lib-library-settings.update`

Key controller methods:
- `index(Request)` — Lists all configs with search filtering, paginated at 20, supports AJAX partial reload
- `update(Request, $id)` — Validates and updates `setting_value` and `description`, returns JSON response

---

## Who Can Access This Screen

| Role | Permission | Access Level |
|---|---|---|
| Super Admin | `tenant.lib-transactions-history.viewAny` | Full read/write access (bypasses via Gate::before) |
| Library Admin | `tenant.lib-transactions-history.viewAny` | View and edit all settings |
| Librarian | `tenant.lib-transactions-history.viewAny` | View and edit all settings |
| Library Assistant | `tenant.lib-transactions-history.viewAny` | View only |

---

## How This Screen Works — Logic Flow (Non-Technical)

The user opens the Library Settings screen, which is one of the tabs under History & Audit. The system loads all configuration entries from the database — each entry is a single setting like "MAX_BOOKS_ALLOWED" with its current value. The settings are displayed in a table with the key name, description, current value, and academic year context. To change a setting, the user clicks the update button, makes their change, and saves. The system validates the input, saves it to the database, and shows a success message. Only the setting value and description can be changed — no new settings can be added, and no settings can be deleted.

---

## Validate Before Save

| # | Field | Rule | Error Message |
|---|---|---|---|
| 1 | setting_value | nullable, string, max:500 | The setting value must not exceed 500 characters. |
| 2 | description | nullable, string, max:255 | The description must not exceed 255 characters. |

---

## Error Handling and Validation Messages

| Scenario | Error Message | HTTP Status |
|---|---|---|
| Validation fails | (per-field messages from Validate Before Save table) | 422 |
| Gate authorization fails | This action is unauthorized. | 403 |
| Model not found | No setting found with this ID. | 404 |
| AJAX update success | Setting updated successfully. | 200 |
| AJAX update failure | Failed to update setting. Please try again. | 500 |

---

## Success Scenarios

**SS-001: Update a global setting value**
1. User navigates to Library Settings tab
2. User finds the "MAX_BOOKS_ALLOWED" setting and clicks edit
3. User changes the value from "5" to "3" and clicks Save
4. System validates the input, updates the record, and returns JSON success
5. The table row refreshes showing "3" as the current value
6. Borrowing limit enforcement uses the new value immediately

**SS-002: Search for a specific setting**
1. User types "fine" in the search bar
2. System filters records where setting_key, description, or setting_value contains "fine"
3. Only matching records such as "FINE_RATE_PER_DAY" and "MAX_FINE_AMOUNT" are displayed
4. User clears search to see all settings again

--- 

## Failure Scenarios

**FS-001: Update with invalid value length**
1. User attempts to set a description exceeding 255 characters
2. Server-side validation fails
3. Error response returned with field-specific message
4. Setting remains unchanged

**FS-002: Unauthorized user attempts to edit**
1. User with insufficient permissions clicks edit
2. `Gate::authorize()` throws `AuthorizationException`
3. System returns 403 Forbidden
4. Setting remains unchanged

---

## Dependencies module and tables

| Type | Name | Details |
|---|---|---|
| Table | `lib_library_config` | Main config table with `academic_year_id`, `setting_key`, `setting_value`, `value_type`, `description` |
| FK | `academic_year_id` | References `academic_years.id` (NULL = global default) |
| Module | History & Audit Hub | Parent hub containing the Library Settings tab |
| Module | Academic Sessions | Provides academic year context for config overrides |
