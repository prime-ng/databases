# Tenant Dropdown — Business Requirements

## What This Screen Does

The Tenant Dropdown screen lets a school admin manage dropdown values specific to their school. Each school (tenant) can have its own set of dropdown keys and values, allowing customisation without affecting other schools.

---

## When This Screen Is Used

- A school admin needs to add a new dropdown for their school's forms (e.g., bus routes, hostel wings, activity types)
- Admin wants to update existing dropdown values for their school
- Admin needs to deactivate outdated dropdown options
- Admin wants to search for a specific dropdown key or value
- Admin wants to filter dropdowns by type (String, Integer) or by status

---

## Key Fields at a Glance

**Key**
The dropdown key is auto-generated as `table_name.column_name` when the admin selects a table and column from the database. This ensures consistency and traceability. The key field is read-only — it is always derived from the table and column selection.

**Table**
The admin selects which database table the dropdown belongs to. Available tables are fetched from the school's database in real time.

**Column**
Once a table is selected, the available columns from that table are loaded via AJAX. The admin picks the column that needs a dropdown.

**Value(s)**
The actual dropdown options. For example, if the key is `bus_route`, values could be "Route A — North Campus", "Route B — South Campus", etc.

**Type**
The data type of the dropdown values — String, Integer, Decimal, Double, or Date. This tells the system how to treat the values.

**Status**
Each dropdown can be Active (visible and usable in forms) or Inactive (hidden). New dropdowns are active by default.

**Additional Info**
Any extra information the admin wants to store alongside the dropdown, in text format.

---

## Business Rules

**Auto-Generated Key**
The key is automatically generated as `table.column` format. The admin cannot edit it manually. If the table or column changes, the key updates accordingly.

**Unique Key Per School**
Within a single school (tenant), each key must be unique. No two dropdowns can have the same `table.column` key.

**Active by Default**
When a new dropdown is created, its status is set to Active automatically. The admin can change it later.

**Search Across Key and Value**
The search box looks through both the key name and the value text simultaneously, making it easy to find specific dropdowns.

**Filters**
Admin can filter by Type (String/Integer/Decimal/Double/Date) and Status (Active/Inactive). A Clear button resets all filters while keeping the admin on the same page/tab.

**Force Delete Protection**
If a dropdown has active mappings (linked to dropdown needs), the system prevents permanent deletion and warns the admin. Associated junction records are cleaned up before deletion.

**Edit Protection**
Admin can edit the values, type, status, and additional info of any dropdown. The key remains derived from table.column and cannot be changed directly.
