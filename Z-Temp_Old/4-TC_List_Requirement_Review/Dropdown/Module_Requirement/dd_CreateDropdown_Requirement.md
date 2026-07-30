# Create Dropdown — Business Requirements

## What This Screen Does

The Create Dropdown screen provides inline management of dropdown values for a selected dropdown need. It is the operational interface where administrators and authorized users create, edit, and delete the actual key-value pairs that populate dropdown fields throughout the application.

While the Dropdown Needs screen defines *what* dropdowns are needed, this screen manages *what values* those dropdowns contain. It bridges the definition layer and the actual data layer.

---

## When This Screen Is Used

- Value Maintenance when new options need to be added to an existing dropdown field
- Tenant Customization when a teacher or employee needs to add school-specific values to a field configured as tenant-creatable
- Bulk Population when multiple dropdown values for the same need need to be created at once
- Quick Setup during initial module configuration when seed data is being supplemented

## Default Data Load

This screen displays as the third tab (Create Dropdown) within the Global Master Dropdown module. It shows cascading filters (Category → Main Menu → Sub Menu → Tab → Field) to help the user locate the specific dropdown need. Once a need is selected, the screen displays its mapped and unmapped dropdown values with an inline add form.

---

## Key Fields at a Glance

**Need Selection via Cascading Filters**
A 5-level cascading filter chain helps locate the dropdown need: Category → Main Menu → Sub Menu → Tab → Field. Each selection narrows the options for the next level, sourced from the glb_menus table and the existing dropdown needs data.

**Inline Management Panel**
Once a field is selected, the system identifies the corresponding dropdown need and displays a management panel showing currently mapped dropdowns and available unmapped dropdowns.

**Add Form**
An inline form allows creating new dropdown values directly. Users can provide key, ordinal, value, type, and additional_info. The system auto-generates keys when not provided.

---

## Business Rules and Conditions

**Permission-Based Access**
Super Admin and PRIME users can manage dropdown values for all needs. TEACHER and EMPLOYEE users can only manage values for needs where tenant_creation_allowed = true. This is enforced in the controller via canManageDropdownNeed() and canUserManageDropdown().

**Auto Key Generation**
When creating a dropdown without providing a key, the system auto-generates one using a slug of the table_name_column_name combined with a timestamp. This ensures uniqueness while maintaining readability.

**Ordinal Auto-Calculation**
When ordinal is not provided, the system calculates it as max(ordinal) + 1 from the entire sys_dropdown_table. This automatically places new options at the end of the list.

**Transaction Safety**
All create operations run within a database transaction. Both the dropdown record and the junction entry are created together. If either fails, both are rolled back.

---

## Workflow Steps

**Adding a Dropdown Value via Inline Form**
An administrator locates the dropdown need using the cascading filters. They select a category, then main menu, sub menu, tab, and field. The management panel appears showing existing mapped values. The admin clicks "Add New" in the inline form, enters key (or leaves blank for auto-generation), ordinal, value, type, optional additional info, and saves. The system creates the dropdown and maps it to the selected need.

---

## Example Scenario

A school is configuring the Student Profile module. A dropdown need exists for `std_students.gender` with allowed tenant creation. A teacher navigates to the Create Dropdown tab, selects the menu path: Student Profile → Student Management → Create Student → Basic Details → Gender. The management panel shows standard gender options (Male, Female). The teacher clicks Add New and enters "Other" as a new gender option specific to their school. The system auto-generates the key `std_students_gender_1234567890` and maps it. Now the Gender dropdown on the Create Student form includes "Other" as an option for their school only.

---

## Related Screens

- **Dropdown Needs** — Defines the need that this screen manages values for
- **Dropdown List** — Shows all dropdown values across all needs in a grouped accordion view
- **Mapping** — Maps/unmaps existing dropdown values to needs

---

## Requirements

- The screen MUST display cascading filters (Category, Main Menu, Sub Menu, Tab, Field Name) to locate a dropdown need.
- The system MUST authorize store operations via `Gate::authorize('prime.dropdown.create')`.
- The system MUST authorize the management tab view via `Gate::authorize('prime.dropdown-need-mgmt.viewAny')`.
- The system MUST enforce TEACHER/EMPLOYEE permission checks: only allowed for needs with tenant_creation_allowed=true.
- The system MUST support creating dropdowns via multiple endpoints:
  - Full create: `POST /global-master/dropdown` (validates key unique, auto-ordinal, creates junction)
  - AJAX store-option: `POST /global-master/dropdown/store-option` (auto-key, auto-map)
  - AJAX add-by-selection: `POST /global-master/dropdown/add-by-selection` (auto-key if empty)
  - AJAX quick-save: `POST /global-master/dropdowns/save-option` (auto-key, optional map)
- The system MUST create both the dropdown record and the junction entry within a single transaction.
- The system MUST auto-generate ordinal as max(ordinal)+1 when not provided.
- The system MUST auto-generate key as a slug of table_name_column_name + timestamp when not provided.
- The system MUST redirect to the main index with success flash after store.

---

## Who Can Access This Screen

| Role | Permission | Access Level |
|---|---|---|
| Super Admin | `prime.dropdown.create` + `prime.dropdown-need-mgmt.*` | Full access to all needs |
| PRIME User | `prime.dropdown.create` + `prime.dropdown-need-mgmt.*` | Full access to all needs |
| TEACHER / EMPLOYEE | `prime.dropdown.create` | Limited to needs with tenant_creation_allowed=true |

---

## How This Screen Works — Logic Flow (Non-Technical)

1. The user navigates to Global Master → Dropdown → Create Dropdown tab.
2. A cascading filter chain appears. The user selects Category → Main Menu → Sub Menu → Tab → Field.
3. Each selection triggers an AJAX call to load the next level's options.
4. When a Field is selected, the system identifies the matching dropdown need.
5. The management panel loads: mapped dropdowns (already linked to this need) and unmapped dropdowns (available to link).
6. The user can use the inline Add form to create a new dropdown value. Key, ordinal, value, type, and additional info can be entered.
7. On submit, the system validates, creates the dropdown, creates the junction mapping, and redirects to the main view.
8. TEACHER/EMPLOYEE users see only needs where tenant_creation_allowed is true.

---

## Validate Before Save

1. **Key Unique** — `key` must be unique in sys_dropdown_table (full create only).
2. **Key Max Length** — `key` max 160 characters.
3. **Ordinal Integer** — `ordinal` must be integer >= 1 (optional, auto-calculated if empty).
4. **Value Required** — `value` must not be empty. Max 255 characters.
5. **Type Valid** — `type` must be one of: String, Integer, Decimal, Date, Datetime, Time, Boolean.
6. **Dropdown Need ID** — Must exist in sys_dropdown_needs.
7. **Authorization** — User must have appropriate permission and access rights.

---

## Error Handling and Validation Messages

| Scenario | Error Message | HTTP Status |
|---|---|---|
| Duplicate key | "The key has already been taken." | 422 |
| Empty value | "The value field is required." | 422 |
| Invalid type | "The selected type is invalid." | 422 |
| Missing dropdown_need_id | "Please select a dropdown need first!" | Redirect with error |
| TEACHER unauthorized for need | "Unauthorized: You do not have permission to create options for this dropdown." | 403/Redirect |
| Non-existent need ID | 404 Not Found | 404 |

---

## Success Scenarios

**SC-001: Creating a New Dropdown Value via Full Create**
1. Admin selects a need via cascading filters, clicks "Add New".
2. Uses the full create form: enters key `std_students.gender`, ordinal 3, value "Other", type String.
3. System validates, creates dropdown with ordinal=3, creates junction entry.
4. Redirects to main index with success message "Dropdown saved successfully!".

**SC-002: Quick Adding via AJAX with Auto-Generated Key**
1. Admin selects a need and uses the inline quick-add form.
2. Enters value "Prefer Not to Say", ordinal 4.
3. System auto-generates key `std_students_gender_1234567890`, creates dropdown, creates junction.
4. Returns JSON `{success: true, message: "Dropdown saved successfully!"}`.

---

## Failure Scenarios

**FC-001: TEACHER Tries to Add to Non-Tenant Need**
1. TEACHER user locates a need where tenant_creation_allowed=false.
2. Clicks "Add New" and submits the form.
3. `canManageDropdownNeed()` returns false.
4. System returns 403 with "Unauthorized: You do not have permission to create options for this dropdown."

---

## Dependencies module and tables

| Type | Name | Details |
|---|---|---|
| Table | `sys_dropdown_table` | Stores the actual dropdown key-value pairs |
| Table | `sys_dropdown_needs` | Defines the dropdown needs (referenced via dropdown_need_id) |
| Table | `sys_dropdown_need_dropdowns_jnt` | Junction mapping dropdowns to needs |
| Gate | `prime.dropdown.create`, `prime.dropdown-need-mgmt.*` | Authorization gates |
