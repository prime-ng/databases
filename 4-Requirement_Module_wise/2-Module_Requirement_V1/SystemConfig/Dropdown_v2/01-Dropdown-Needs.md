# Dropdown Needs — Business Requirements

## What This Screen Does

The Dropdown Needs screen is where a Super Admin or Prime Admin defines what dropdowns the system should have. Think of this as creating a "requirement" for a dropdown — the admin specifies which database table and column needs a dropdown, where it appears in the menu structure, and whether schools can add their own values.

---

## When This Screen Is Used

- A new feature is added to the system and needs a dropdown for one of its form fields
- Admin wants to change which menu/tab/field a dropdown is linked to
- Admin needs to enable or disable tenant schools from creating their own values for a dropdown
- A dropdown is no longer needed and needs to be deactivated

---

## Key Fields at a Glance

**Database Context**
The admin selects the DB Type (Prime/Global/Tenant), the table name (e.g., `std_students`), and the column name (e.g., `blood_group`). This links the dropdown need to a specific database field.

**Menu Context**
The admin selects where this dropdown appears in the system's navigation — the menu category, main menu, sub menu, tab name, and field name. This helps with filtering and contextual understanding.

**Permissions**
The admin can enable or disable "Tenant Creation Allowed" — when checked, school-level admins can create their own dropdown values for this need. When unchecked, only Prime admins can manage the values.

**Status**
The dropdown need can be Active or Inactive. Inactive needs are hidden from dropdown selection screens.

---

## Business Rules

**Unique Combination**
A dropdown need is uniquely identified by its table name and column name combination. Duplicate entries for the same table/column should be prevented.

**Menu Context Filtering**
When creating a dropdown need, the system shows cascading filters — selecting a Category narrows the Main Menu options, selecting a Main Menu narrows the Sub Menu options, and so on.

**Is System Protection**
Dropdown needs marked as "Is System" cannot be edited or deleted. These are protected system-level entries.

**Soft Delete**
Dropdown needs support soft deletion (trash). Trashed needs can be restored or permanently deleted. Permanent deletion is blocked if active mappings exist.
