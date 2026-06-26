# Dropdown Need & Table Mapping — Business Requirements

## What This Screen Does

The Dropdown Need & Table Mapping screen provides a cross-reference view between dropdown needs and the actual dropdown values. It shows which dropdown needs are linked to which dropdown keys/values at a glance.

---

## When This Screen Is Used

- Admin wants to verify which dropdowns are mapped to a specific dropdown need
- Admin needs to check if a dropdown need has all the required values assigned
- Troubleshooting — admin wants to understand why a certain dropdown is not appearing in a form

---

## Key Features

**Mapping Overview**
A table-style view showing dropdown needs alongside their mapped dropdown values. Admin can quickly see what is connected to what.

**Filtering**
Admin can filter by table name, column name, or menu context to narrow down the view.

**Gap Analysis**
At a glance, the screen shows which dropdown needs have values mapped and which are still empty.

---

## Business Rules

**Read-Only Reference**
This screen is primarily a reference view. Actual mapping changes are done through the Create Dropdown screen.

**Visual Indicators**
Mapped needs are shown with a green indicator. Needs without mappings show a warning indicator.

**Junction Table**
The actual mapping data is stored in `sys_dropdown_need_dropdowns_jnt`, which links `sys_dropdown_needs` entries to `sys_dropdowns` entries. When a dropdown need or a dropdown value is deleted, the mapping entries are cleaned up automatically.
