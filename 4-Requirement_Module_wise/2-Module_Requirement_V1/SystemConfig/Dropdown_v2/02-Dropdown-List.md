# Dropdown List — Business Requirements

## What This Screen Does

The Dropdown List screen shows all dropdown key-value pairs in the system grouped by their key. Think of it as the master catalogue — every dropdown that exists in the system, whether created by Prime admins or tenant school admins, appears here.

---

## When This Screen Is Used

- Admin wants to see all available dropdowns and their values at a glance
- Admin needs to search for a specific dropdown key or value
- Admin wants to filter dropdowns by type (String, Integer, etc.) or by status (Active/Inactive)
- Admin wants to check which dropdowns are active and which are disabled

---

## Key Features

**Accordion Grouping**
Dropdowns are displayed in an accordion layout, grouped by their key. Clicking a key expands it to show all values inside that group.

**Inline Status**
Each dropdown key group can be toggled Active or Inactive. When a key is inactive, all its values are effectively disabled.

**Value Ordering**
Values within each group appear in a defined order. Admin can add new values and the system assigns an ordinal automatically.

**Type Classification**
Each dropdown key has a type (String, Integer, Decimal, Double, Date). This defines what kind of data the dropdown represents.

---

## Business Rules

**Grouping**
All dropdown values with the same key are shown together in one accordion panel. This makes it easy to manage related values.

**Status Cascade**
When a dropdown key is set to inactive, all values under it are considered inactive. Re-activating the key makes all values active again.

**Search**
The search box looks through both the key name and the value text, making it easy to find specific entries.

**Pagination**
Dropdowns are paginated to handle large numbers of keys. Admin can navigate between pages to browse all dropdowns.
