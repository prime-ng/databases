# Dropdown Needs — Business Requirements

## What This Screen Does

The Dropdown Needs screen is the definition hub for the entire dynamic dropdown system. It configures what dropdowns the system needs to display across the application. Each "need" record defines a database table and column that requires a dropdown selection, along with the menu context where it appears.

This configuration drives the system's ability to present contextual dropdown options to users. Without this setup, the system cannot determine which fields need dropdown values, what type of database they belong to, or where they appear in the menu hierarchy.

---

## When This Screen Is Used

- Module Onboarding when a new module is integrated into the system and its database columns need dropdown configurations
- Menu Restructuring when the application's menu hierarchy changes and dropdown placements need updating
- Tenant Customization when a tenant wants to allow their users to create custom dropdown options for specific fields
- System Initialization when seed data populates the initial set of dropdown needs

## Default Data Load

This screen displays as the first tab (Dropdown Needs) within the Global Master Dropdown module. When the user navigates to /global-master/dropdown, DropdownController@index() loads all 4 tabs simultaneously. The Dropdown Needs tab is the default active tab for users authorized with prime.dropdown.viewAny permission.

---

## Key Fields at a Glance

**Database Configuration**
A DB Type selector restricts the dropdown context to Prime (central system config), Global (cross-tenant shared config), or Tenant (per-tenant custom config). The Table Name dropdown loads dynamically via AJAX reading the migrations table for the selected DB Type. The Column Name dropdown loads dynamically by reading the actual columns of the selected table.

**Tenant Access Control**
A Tenant Creation Allowed toggle determines whether non-admin users (TEACHER, EMPLOYEE) are permitted to create and manage dropdown values for this need. When enabled, a cascade of 5 menu location fields becomes mandatory.

**Menu Location Chain**
When Tenant Creation Allowed is enabled, the system requires a complete menu breadcrumb: Menu Category, Main Menu, Sub Menu, Tab Name, and Field Name. These load from the glb_menus table in the global_master_mysql connection. When disabled, all 5 are cleared to null.

**System Protection**
An Is System flag locks the record. System records are installed via seeders and cannot be edited or deleted through the UI. This protects critical dropdown definitions from accidental modification.

---

## Business Rules and Conditions

**Conditional Menu Field Requirement**
The most critical business rule is the conditional validation of menu fields. If Tenant Creation Allowed is set to Yes, all five menu location fields become required. If any one is missing, validation rejects the submission. If set to No, all five fields are forcibly nulled before saving, regardless of what was submitted.

**System Record Immutability**
Records marked as is_system = true are protected from edit, update, and delete operations. Attempting to edit or delete a system record redirects the user with an error message. System records can still be toggled and trashed via toggleStatus and destroy, but destroy only soft-deletes while is_system remains true.

**Dynamic AJAX Data Loading**
Table and column dropdowns are populated dynamically based on the DB Type selection. For Prime and Global types, results are cached for 1 hour to improve performance. For Tenant type, caching is skipped because tenant schemas can change during setup. The system reads migration files to determine available tables, then inspects the actual database columns.

**Menu Data from Central Source**
All menu hierarchy data is fetched from the glb_menus table in the global_master_mysql connection. The getMenuData endpoint loads categories (is_category=1) first. When a category is selected, getMainMenus fetches menus whose parent_id matches the category. When a main menu is selected, getSubMenus fetches menus under that parent.

**Trash Lifecycle**
When a need is destroyed, the system deactivates all related junction entries (sys_dropdown_need_dropdowns_jnt.is_active = false), sets the need's is_active to false, then soft-deletes. Restoring reverses this: restores the need, sets is_active to true, and reactivates all junction entries. Force-deleting permanently removes the need and all junction entries.

---

## Workflow Steps

**Creating a New Dropdown Need**
An administrator navigates to the Dropdown Needs tab and clicks "Add New". They select the DB Type (Prime/Global/Tenant). The system loads available migration tables. They select a table, which triggers loading of available columns. They select the column. They decide whether Tenant Creation should be Allowed — if Yes, they must fill the entire menu breadcrumb chain. If No, menu fields are disabled. They set Is System, Compulsory, and Status, then save. The system validates, creates the record, logs the activity, and returns to the main tab.

---

## Example Scenario

The Academic Management module is being onboarded. The admin navigates to Dropdown Needs and creates a need for the table `acd_classes` column `class_type` with DB Type Prime. Since this is a system-wide configuration that tenants should not modify, Tenant Creation Allowed is set to No. The menu fields remain null.

Later, a school wants teachers to create custom activity categories. The admin creates another need for `sch_activities` column `category` with DB Type Tenant. Tenant Creation Allowed is set to Yes. The admin selects the menu breadcrumb: School Activities → Activity Management → Activities → Create → Category. Now, when a teacher accesses that form, they can add custom dropdown options for the category field.

---

## Related Screens

- **Dropdown List** — Shows the actual key-value pairs that populate the dropdowns configured here
- **Create Dropdown** — Inline management of dropdown values for a selected need
- **Mapping** — Links dropdown values to specific dropdown needs

---

## Requirements

- The screen MUST load as the active tab `dropdown-need` within the Global Master Dropdown index view at `GET /global-master/dropdown`.
- The system MUST authorize access via `Gate::authorize('prime.dropdown.viewAny')`.
- The system MUST allow CRUD operations: create, store, edit, update, show, destroy (soft-delete), trashed list, restore, forceDelete, and toggleStatus.
- The system MUST enforce validation rules on store/update:
  - `db_type`: required, in:Prime,Tenant,Global
  - `table_name`: required, string, max:150
  - `column_name`: required, string, max:150
  - `tenant_creation_allowed`: required, boolean
  - `menu_category`: nullable, string, max:150 (required if tenant_creation_allowed=true)
  - `main_menu`: nullable, string, max:150 (required if tenant_creation_allowed=true)
  - `sub_menu`: nullable, string, max:150 (required if tenant_creation_allowed=true)
  - `tab_name`: nullable, string, max:100 (required if tenant_creation_allowed=true)
  - `field_name`: nullable, string, max:100 (required if tenant_creation_allowed=true)
  - `is_system`: required, boolean
  - `compulsory`: required, boolean
  - `is_active`: nullable, boolean (defaults to true)
- The system MUST force menu fields to null when tenant_creation_allowed is false.
- The system MUST block edit/update/destroy on records with `is_system = true`.
- The system MUST load migration tables via AJAX from `GET /dropdown-need-api/migration-tables/{dbType}` with caching for Prime/Global (1 hour), no cache for Tenant.
- The system MUST load table columns via AJAX from `GET /dropdown-need-api/table-columns?db_type=X&table_name=Y` with caching for Prime/Global (1 hour), no cache for Tenant.
- The system MUST load menu data from `glb_menus` table in `global_master_mysql` connection via AJAX endpoints.
- The system MUST log activities for: Created, Updated, Trashed, Restored, Deleted, Toggled.
- The system MUST support soft deletes via the SoftDeletes trait.
- The system MUST paginate results at 10 per page using the `needs_page` query parameter.
- The system MUST provide cascading filter dropdowns: db_type, table_name, column_name, menu_category, main_menu, sub_menu, tab_name, field_name.
- The system MUST provide AJAX search via `GET /dropdown-need/search` returning top 10 matches by table_name/column_name/field_name LIKE.

---

## Who Can Access This Screen

| Role | Permission | Access Level |
|---|---|---|
| Super Admin | `prime.dropdown.viewAny` + `prime.dropdown-need.*` | Full CRUD + restore + forceDelete + toggleStatus |
| PRIME User | `prime.dropdown.viewAny` + `prime.dropdown-need.*` | Full CRUD + restore + forceDelete + toggleStatus |
| TEACHER / EMPLOYEE | `prime.dropdown.viewAny` | View-only (no CRUD on needs) |

---

## How This Screen Works — Logic Flow (Non-Technical)

1. The user navigates to Global Master → Dropdown. The Dropdown Needs tab is the default view.
2. `Gate::authorize('prime.dropdown.viewAny')` checks permission. A table of existing dropdown needs appears with filter controls above.
3. The user can filter by DB Type, Table Name, Column Name, or any of the 5 menu hierarchy fields. Filters are cascading — selecting a category narrows the available main menus, which narrows sub menus, and so on.
4. Clicking "Add New" opens a creation form. DB Type determines available tables. Selecting a table loads its columns. Menu fields load from the global menus database.
5. On save, validation enforces the conditional menu requirement. If Tenant Creation Allowed is Yes, all 5 menu fields must be filled. If No, they are cleared.
6. System records (is_system=true) display but the Edit and Delete buttons are hidden. Attempting to directly access edit/delete URLs redirects with an error.
7. Toggle status flips active/inactive and updates all related junction entries accordingly.
8. Trashing a need deactivates its junction entries. Restoring reactivates them. Force deletes permanently remove everything.

---

## Validate Before Save (Multiple Conditions)

1. **DB Type Required** — `db_type` must not be empty. Must be one of: Prime, Tenant, Global.
2. **Table Name Required** — `table_name` must not be empty. Max 150 characters.
3. **Column Name Required** — `column_name` must not be empty. Max 150 characters.
4. **Tenant Creation Allowed Required** — `tenant_creation_allowed` must be boolean.
5. **Menu Category Required (conditional)** — Required when tenant_creation_allowed is true. Max 150 characters.
6. **Main Menu Required (conditional)** — Required when tenant_creation_allowed is true. Max 150 characters.
7. **Sub Menu Required (conditional)** — Required when tenant_creation_allowed is true. Max 150 characters.
8. **Tab Name Required (conditional)** — Required when tenant_creation_allowed is true. Max 100 characters.
9. **Field Name Required (conditional)** — Required when tenant_creation_allowed is true. Max 100 characters.
10. **Is System Required** — `is_system` must be boolean.
11. **Compulsory Required** — `compulsory` must be boolean.
12. **System Record Protection** — `is_system=true` records cannot be edited, updated, or deleted.

---

## Error Handling and Validation Messages

| Scenario | Error Message | HTTP Status |
|---|---|---|
| db_type is empty | "The db type field is required." | 422 |
| db_type is invalid | "The selected db type is invalid." | 422 |
| table_name is empty | "The table name field is required." | 422 |
| table_name exceeds 150 chars | "The table name must not be greater than 150 characters." | 422 |
| column_name is empty | "The column name field is required." | 422 |
| tenant_creation_allowed=true + menu_category empty | "The menu category field is required." | 422 |
| tenant_creation_allowed=true + main_menu empty | "The main menu field is required." | 422 |
| tenant_creation_allowed=true + sub_menu empty | "The sub menu field is required." | 422 |
| tenant_creation_allowed=true + tab_name empty | "The tab name field is required." | 422 |
| tenant_creation_allowed=true + field_name empty | "The field name field is required." | 422 |
| Edit/update on system record | "System records cannot be edited." | Redirect with error |
| Destroy on system record | "System records cannot be deleted." | Redirect with error |
| Non-existing id on show/edit/update/destroy | 404 Not Found | 404 |
| Unauthorized access (missing permission) | "This action is unauthorized." | 403 |

---

## Success Scenarios

**SC-001: Creating a Non-Tenant Dropdown Need**
1. Admin navigates to Dropdown Needs → clicks "Add New".
2. Selects DB Type: Prime, Table: `acd_classes`, Column: `class_type`.
3. Sets Tenant Creation Allowed: No. Menu fields disable automatically.
4. Sets Is System: Yes, Compulsory: Yes, Status: Active.
5. System validates, saves, logs "Created". Redirects to main tab with success message.

**SC-002: Creating a Tenant-Aware Dropdown Need with Full Menu Breadcrumb**
1. Admin clicks "Add New". Selects DB Type: Tenant, Table: `sch_activities`, Column: `category`.
2. Sets Tenant Creation Allowed: Yes. Menu fields enable.
3. Selects Category: School Activities → Main Menu: Activity Management → Sub Menu: Activities → Tab Name: Create → Field Name: Category.
4. Sets Is System: No, Compulsory: No, Status: Active.
5. System validates all required menu fields, saves the record.

**SC-003: Restoring a Soft-Deleted Dropdown Need**
1. Admin navigates to Trash view, finds the deleted need, clicks "Restore".
2. System restores the record, sets is_active=true, reactivates all junction entries.
3. Activity logs "Restored". Record reappears in active list.

---

## Failure Scenarios

**FC-001: Editing a System Record**
1. Admin navigates to edit URL for a system record directly.
2. Controller checks `is_system` flag, redirects back with "System records cannot be edited."
3. Record is not modified.

**FC-002: Tenant Creation Allowed with Missing Menu Fields**
1. Admin selects Tenant Creation Allowed: Yes but leaves menu_category empty.
2. Validation fails with "The menu category field is required."
3. Form returns with entered data preserved for correction.

**FC-003: Force Deleting a Referenced Need**
1. Admin force-deletes a need that has mapped dropdowns.
2. Junction entries are force-deleted first, then the need itself.
3. Activity logs "Deleted". All related data is permanently removed.

---

## Dependencies module and tables

| Type | Name | Details |
|---|---|---|
| Table | `sys_dropdown_needs` | Primary table for this screen |
| Table | `sys_dropdown_need_dropdowns_jnt` | Junction table linked on destroy/restore/forceDelete |
| Table | `glb_menus` | Global menu hierarchy in `global_master_mysql` connection |
| Module | Migrations | Migration files in database/migrations/ (Prime), database/migrations/global/ (Global), database/migrations/tenant/ (Tenant) |
| Module | SystemConfig | DropdownNeedsSeeder seeds initial system records |
| Gate | `prime.dropdown.*`, `prime.dropdown-need.*` | Authorization gates |
