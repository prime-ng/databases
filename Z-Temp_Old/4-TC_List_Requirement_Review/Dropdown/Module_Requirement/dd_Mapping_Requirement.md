# Dropdown Need & Table Mapping — Business Requirements

## What This Screen Does

The Dropdown Need & Table Mapping screen (Mapping tab) is the bridge that connects dropdown definitions (needs) to dropdown values (table entries). It provides a two-step interface where administrators first select a dropdown need, then bulk map or unmap existing dropdown values to that need.

This screen solves the fundamental relational challenge of the dropdown system: a dropdown value can exist independently in sys_dropdown_table, and it only becomes visible in a specific UI field when it is mapped to the corresponding dropdown need. Without mapping, even if a dropdown value exists in the database, users will never see it in the application.

---

## When This Screen Is Used

- Initial System Setup when seed data needs to be mapped to seed dropdown needs
- Module Onboarding when new dropdown needs are created and need to be linked to existing shared dropdown values
- Bulk Operations when many dropdown values need to be mapped or unmapped from a need at once
- Reconfiguration when an administrator decides that certain dropdown values should no longer be available for a specific field

## Default Data Load

This screen displays as the fourth tab (Dropdown Need & Table Mapping) within the Global Master Dropdown module. It loads two filter sections: Step 1 filters for selecting a dropdown need, and Step 2 filters for finding specific dropdowns to map/unmap.

---

## Key Fields at a Glance

**Step 1: Select Need to Map**
Two rows of filters allow narrowing down the dropdown need: DB Type, Table, Column, Field, Category, Main Menu, Sub Menu, Tab. Super Admin sees all fields; non-super-admin users see a reduced set.

**Step 2: Dropdowns with Mapping Status**
Once a need is selected, all active dropdowns from sys_dropdown_table are listed with a visual indicator showing whether each dropdown is currently mapped to the selected need. Checkboxes enable bulk selection.

**Second Filter Set**
Additional filters (dropdown_db_type, dropdown_table_name, dropdown_column_name, dropdown_category, dropdown_main_menu, dropdown_sub_menu, dropdown_tab_name, dropdown_field_name) narrow the dropdown list by the attributes of the needs they are mapped to.

**Direct Dropdown Search**
Search by key (LIKE), value (LIKE), or type (exact) filters the dropdown list directly.

**Mapping Status Filter**
A dedicated filter restricts the list to show only mapped, only unmapped, or all dropdowns relative to the selected need.

---

## Business Rules and Conditions

**Two-Step Flow Integrity**
Step 1 must select a dropdown need before Step 2 becomes operational. If no need is selected, the dropdown list shows an empty paginator and buttons are disabled.

**Bidirectional Mapping**
The map operation checks for existing junction entries. If a mapping already exists for a dropdown-need pair, it reactivates it (sets is_active=true) rather than creating a duplicate. If no mapping exists, a new junction entry is created.

**Bulk Unmapping**
The remove operation performs a bulk update on all matching junction entries, setting is_active=false. This does not delete the junction record — it soft-deactivates it, allowing reactivation later.

**Auto-Mapping on Create**
When creating a new dropdown via the modal in the mapping tab, the system optionally auto-maps it to the selected need if dropdown_need_id is provided. If a mapping already exists, it reactivates it.

**Key-Based Mapping**
The mapExistingOptions endpoint maps options to a need filtered by a specific key. This allows granular control over which key's values are mapped.

---

## Workflow Steps

**Mapping Dropdowns to a Need**
An administrator navigates to the Mapping tab. In Step 1, they select the dropdown need by filtering and clicking "Apply" or directly selecting a need. In Step 2, all dropdowns appear with is_mapped checkboxes. The admin checks the desired dropdowns and clicks "Map Selected". The system creates or reactivates junction entries and returns a success message with the count of mapped items.

---

## Example Scenario

A new module for "Library Management" is being onboarded. The admin creates a dropdown need for `lib_book_categories.category_name` in the Dropdown Needs tab. Now they need to map existing dropdown values (like "Fiction", "Non-Fiction", "Reference", "Periodical") that already exist in the system for other modules. They open the Mapping tab, select the Library Management need via Step 1 filters, see all available dropdowns in Step 2, check the four values, and click "Map Selected". The four values are now available in the Category field of the Library Management module.

---

## Related Screens

- **Dropdown Needs** — Defines the needs that this screen maps values to
- **Dropdown List** — Shows all available dropdown values in the system
- **Create Dropdown** — Creates new dropdown values for a specific need

---

## Requirements

- The screen MUST display a two-step interface: Step 1 (select need) and Step 2 (map/unmap dropdowns).
- The system MUST authorize map/unmap operations via `Gate::authorize('prime.dropdown-need.update')`.
- The system MUST support bulk mapping via `POST /global-master/dropdowns/map-to-need` accepting dropdown_needs_id and dropdown_ids array.
- The system MUST support bulk unmapping via `POST /global-master/dropdowns/remove-mapping` accepting dropdown_needs_id and dropdown_ids array.
- The system MUST support mapping existing options by key via `POST /global-master/dropdowns/map-existing-options`.
- The system MUST support creating a dropdown with optional auto-mapping via `POST /global-master/dropdowns/save-option`.
- The system MUST check existing mappings and reactivate (set is_active=true) rather than creating duplicates.
- The system MUST provide pagination at 10 per page using the `mapping_page` parameter.
- The system MUST provide the following filter layers:
  - Step 1 filters: db_type, table_name, column_name, field_name, category, main_menu, sub_menu, tab_name
  - Step 2 dropdown filters: dropdown_db_type, dropdown_table_name, dropdown_column_name, etc. (need-based)
  - Direct filters: search_key (LIKE), search_value (LIKE), search_type (exact)
  - Mapping status filter: all, mapped, unmapped
- The system MUST show is_mapped flag for each dropdown when a need is selected.
- The system MUST log activity for map/unmap operations (via activityLog).

---

## Who Can Access This Screen

| Role | Permission | Access Level |
|---|---|---|
| Super Admin | `prime.dropdown-need.update` | Full map/unmap access for all needs |
| PRIME User | `prime.dropdown-need.update` | Full map/unmap access for all needs |
| TEACHER / EMPLOYEE | `prime.dropdown-need.update` (implicit via canManageDropdownNeed) | Limited to needs with tenant_creation_allowed=true |

---

## How This Screen Works — Logic Flow (Non-Technical)

1. The user navigates to Global Master → Dropdown → Mapping tab.
2. Step 1 loads: filter controls for selecting a dropdown need. Super Admin sees all 8 filters; others see a reduced set.
3. The user applies filters or selects a need directly.
4. Step 2 loads: all active dropdowns from sys_dropdown_table are displayed with a checkmark column showing is_mapped.
5. A second filter set allows further narrowing by need attributes (e.g., show only dropdowns mapped to needs of type "Tenant").
6. Direct search by key, value, or type further narrows the list.
7. The mapping status filter shows all, only mapped, or only unmapped dropdowns.
8. The user selects checkboxes for desired dropdowns and clicks "Map Selected" or "Unmap Selected".
9. For mapping: the system iterates through selected IDs, checks for existing junction entries, creates or reactivates them.
10. For unmapping: the system bulk updates junction entries to is_active=false.
11. A modal also allows creating a brand new dropdown and optionally mapping it to the selected need.
12. Success/failure JSON is returned and the list refreshes.

---

## Validate Before Save

1. **Map Validation** — `dropdown_needs_id` required exists:sys_dropdown_needs. `dropdown_ids` required array, each exists:sys_dropdown_table.
2. **Unmap Validation** — Same schema as map.
3. **Map Existing Options Validation** — `dropdown_need_id` required exists, `option_ids` required array, `key` required string.
4. **Authorization** — User must have prime.dropdown-need.update permission. TEACHER/EMPLOYEE must have tenant_creation_allowed=true on the need.

---

## Error Handling and Validation Messages

| Scenario | Error Message | HTTP Status |
|---|---|---|
| Invalid dropdown_needs_id | Validation error | 422 |
| Empty dropdown_ids | "The dropdown ids field is required." | 422 |
| Invalid dropdown_id in array | Validation error for the specific ID | 422 |
| Server error during mapping | "Failed to map dropdown options. Please try again." | 500 |
| Unauthorized user attempts mapping | "This action is unauthorized." | 403 |

---

## Success Scenarios

**SC-001: Bulk Mapping Dropdowns to a Need**
1. Admin selects a need in Step 1, sees dropdown list in Step 2.
2. Checks 3 dropdown values, clicks "Map Selected".
3. System iterates: finds 2 new mappings (creates junction entries) and 1 existing inactive (reactivates).
4. Returns JSON `{success: true, message: "Successfully mapped 3 dropdown option(s)."}`.

**SC-002: Bulk Unmapping Dropdowns**
1. Admin selects a need, filters to show only mapped dropdowns.
2. Unchecks 2 dropdowns, clicks "Unmap Selected".
3. System updates junction entries: is_active=false.
4. Returns JSON `{success: true, message: "Successfully removed mapping for 2 dropdown option(s)."}`.

**SC-003: Creating and Auto-Mapping a New Dropdown**
1. Admin selects a need, opens the "Create New Dropdown" modal.
2. Enters key (or leaves blank), value "Urdu", type String.
3. System creates dropdown + maps to need, returns JSON success.

---

## Failure Scenarios

**FC-001: Unauthorized TEACHER Tries to Map**
1. TEACHER user accesses mapping tab, selects a need where tenant_creation_allowed=false.
2. Selects dropdowns and clicks "Map Selected".
3. `canManageDropdownNeed()` returns false.
4. System returns 403 or redirect with error.

**FC-002: Server Error During Mapping**
1. Admin attempts to map dropdowns but a database error occurs.
2. System catches the exception, logs it, returns 500 JSON.
3. No partial mapping is committed (transaction rolled back if applicable).

---

## Dependencies module and tables

| Type | Name | Details |
|---|---|---|
| Table | `sys_dropdown_need_dropdowns_jnt` | Junction table storing map/unmap state |
| Table | `sys_dropdown_needs` | Dropdown need definitions (Step 1 source) |
| Table | `sys_dropdown_table` | Dropdown key-value pairs (Step 2 source) |
| Gate | `prime.dropdown-need.update` | Authorization for map/unmap operations |
