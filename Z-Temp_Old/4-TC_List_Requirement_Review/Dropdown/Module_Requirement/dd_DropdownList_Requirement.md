# Dropdown List — Business Requirements

## What This Screen Does

The Dropdown List screen provides a consolidated, grouped view of all key-value pairs stored in the sys_dropdown_table. It displays dropdown entries grouped by their key in an accordion format, allowing administrators to see, filter, search, and manage all available dropdown options in one place.

This screen serves as the inventory dashboard for the entire dropdown value repository. Every dropdown option created across all needs appears here, organized by its logical key.

---

## When This Screen Is Used

- Auditing when an administrator needs to review all available dropdown options across the system
- Bulk Editing when multiple dropdown values for the same key need simultaneous updates
- Verification when confirming that seed data from system configuration has been loaded correctly
- Troubleshooting when investigating why certain dropdown options are not appearing in the UI

## Default Data Load

This screen displays as the second tab (Dropdown List) within the Global Master Dropdown module. It loads when the user switches to the `dropdown-list` tab. For users who lack permission to view the Dropdown Needs tab (non-admin, non-PRIME users), this tab becomes the default landing view.

---

## Key Fields at a Glance

**Accordion Grouping**
Every unique key in sys_dropdown_table becomes an accordion header. Clicking the header expands to reveal all values associated with that key, ordered by ordinal.

**Inline Row Controls**
Each value row displays: ordinal, value, type, and status toggle. Users can see at a glance the ordering, the actual dropdown text, the data type, and whether the option is active.

**Bulk Operations**
Checkboxes allow selecting multiple rows for bulk delete or bulk restore. Inline editing fields allow modifying ordinal, value, and type for multiple rows simultaneously.

---

## Business Rules and Conditions

**Distinct Key Grouping**
The system first fetches all distinct keys from sys_dropdown_table (filtered by active status by default). Each key becomes an accordion section. Within each section, all rows with that key are fetched ordered by ordinal.

**Status Filtering**
The list_status filter has four modes: default (active only, is_active=true), all (excludes soft-deleted records), 0 (inactive only), 1 (active only). This allows comprehensive management of all dropdown states.

**Inline Toggle Cascade**
When a dropdown's status is toggled, the change cascades to the junction table (sys_dropdown_need_dropdowns_jnt), updating the mapping status for all needs linked to that dropdown.

---

## Workflow Steps

**Bulk Editing Dropdown Values**
An administrator navigates to the Dropdown List tab, filters by key, and expands the desired accordion section. They modify ordinal, value, or type fields inline for multiple rows, then click "Update Bulk" to save all changes simultaneously.

---

## Example Scenario

The system has been running for a year and the school has accumulated hundreds of dropdown options. The admin needs to standardize the activity types across all schools. They open the Dropdown List tab, filter by the key `sch_activities.type`, and expand the accordion. They see 15 different activity types. They edit a few values, deactivate outdated ones, and delete duplicates — all from a single screen.

---

## Related Screens

- **Dropdown Needs** — Defines what dropdowns are needed and where they appear
- **Create Dropdown** — Creates new dropdown values for specific needs
- **Mapping** — Links dropdown values to specific needs

---

## Requirements

- The screen MUST display dropdowns grouped by distinct `key` in an accordion format.
- The system MUST authorize access via `Gate::authorize('prime.dropdown.viewAny')`.
- The system MUST provide filters: list_key (exact match), list_value (LIKE), list_status (default=active, all, 0, 1).
- The system MUST support inline status toggle via `POST /global-master/dropdown/{id}/toggle-status` returning JSON `{success, is_active, message}`.
- The system MUST support bulk update via `POST /global-master/dropdown/update-bulk` accepting an array of rows with id, ordinal, value, type, additional_info.
- The system MUST support bulk delete via `POST /global-master/dropdown/delete-bulk` — soft deletes and deactivates junction entries.
- The system MUST provide trash view at `GET /global-master/dropdown/trash/view` with pagination (10 per page).
- The system MUST provide bulk restore and bulk force-delete endpoints.
- The system MUST paginate the key listing at 10 per page using the `list_page` parameter.

---

## Who Can Access This Screen

| Role | Permission | Access Level |
|---|---|---|
| Super Admin | `prime.dropdown.*` | Full access: view, edit, toggle, delete, restore, force-delete |
| PRIME User | `prime.dropdown.*` | Full access |
| TEACHER / EMPLOYEE | `prime.dropdown.viewAny` | Read-only view (no CRUD) |

---

## How This Screen Works — Logic Flow (Non-Technical)

1. The user navigates to Global Master → Dropdown and clicks the Dropdown List tab.
2. The system loads all distinct keys from sys_dropdown_table, filtered by the selected status (active by default).
3. Each key renders as an accordion header. Clicking a header loads all values for that key.
4. Filter controls above allow narrowing by key, value, or status.
5. Each value row shows ordinal, value, type, a status toggle switch, and a checkbox for bulk selection.
6. User can toggle individual status inline. The system updates the dropdown and its junction entries.
7. User can select multiple rows and use bulk actions (delete, restore in trash view).
8. User can edit values inline and click "Update Bulk" to save multiple changes at once.

---

## Validate Before Save (applied on bulk update and toggle)

1. **Bulk Update Validation** — `rows` required array. Each row: `id` required exists, `value` required max:255, `ordinal` nullable integer, `type` nullable string, `additional_info` nullable max:1000.
2. **Toggle Validation** — `is_active` required boolean.
3. **Authorization** — Each dropdown's manageability is checked per-row for TEACHER/EMPLOYEE users.

---

## Error Handling and Validation Messages

| Scenario | Error Message | HTTP Status |
|---|---|---|
| Invalid row id in bulk update | Validation error for the specific field | 422 |
| Empty rows array in bulk update | "The rows field is required." | 422 |
| Unauthorized dropdown update | "Unauthorized: Some dropdowns cannot be updated." | 403 |
| Unauthorized toggle | "Unauthorized action." | 403 |

---

## Success Scenarios

**SC-001: Bulk Editing Dropdown Values**
1. Admin opens Dropdown List, expands an accordion section for key `sch_activity.type`.
2. Changes ordinal of first row from 1 to 2, updates value text of second row.
3. Clicks "Update Bulk". System validates and saves all changes in a transaction.
4. Returns JSON `{success: true, message: "Dropdowns updated successfully."}`.

**SC-002: Toggling a Dropdown Status**
1. Admin clicks the toggle switch on an active dropdown row.
2. System sends POST to toggle-status endpoint.
3. System flips is_active, updates junction entries, logs "Toggled".
4. Returns JSON `{success: true, is_active: false, message: "Dropdown status updated successfully!"}`.

---

## Failure Scenarios

**FC-001: Unauthorized TEACHER Tries to Update**
1. TEACHER user attempts to update a dropdown linked to a need with tenant_creation_allowed=false.
2. `canUserManageDropdown()` returns false.
3. System returns 403 with "Unauthorized action."

---

## Dependencies module and tables

| Type | Name | Details |
|---|---|---|
| Table | `sys_dropdown_table` | Primary table for dropdown key-value pairs |
| Table | `sys_dropdown_need_dropdowns_jnt` | Junction table updated on toggle/bulk delete |
| Gate | `prime.dropdown.*` | Authorization gates for all operations |
