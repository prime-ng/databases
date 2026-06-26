# Building — Business Requirements

## What This Screen Does

The Building screen is where the school registers its physical buildings or wings. A building is a structural entity on the school campus — for example, "Junior Wing", "Senior Wing", "Administration Block", "Sports Complex", etc.

Think of buildings as the top-level containers. Every room in the school belongs to exactly one building.

---

## When This Screen Is Used

- A new building is constructed or acquired by the school
- Admin wants to rename or update building details
- A building is being demolished or decommissioned
- Admin needs to view or report on available buildings

---

## Key Fields at a Glance

**Code**
A unique 2-digit numeric code for the building (10–99). This code is used as the first part of room codes. For example, if the Senior Wing has code 11, a room in it might be coded as `11G-10A`.

**Short Name**
A brief name for the building, displayed in dropdowns and tables. Examples: "Junior Wing", "Senior Wing", "Admin Block".

**Full Name**
A detailed, descriptive name for the building.

**Status**
Each building can be Active (currently in use) or Inactive (decommissioned or under renovation).

---

## Business Rules and Conditions

**Unique Code**
Every building must have a unique 2-digit code. No two buildings can share the same code.

**Unique Short Name**
Every building must have a unique short name. This prevents confusion in dropdown selections.

**Code Format**
The building code must be a 2-digit number. This is important because the code becomes part of every room code in that building.

**Soft Delete Protection**
A building cannot be permanently deleted if there are active rooms linked to it. The system will show an error message if the admin tries to force delete a building that still has rooms.

---

## What Shows in the List

| Column | Description |
|--------|-------------|
| Sr. No | Row number |
| Code | 2-digit building code |
| Short Name | Brief display name |
| Building Name | Full building name |
| Status | Active/Inactive toggle |
| Action | View, Edit, Delete buttons |

---

## Workflow Steps

**Adding a New Building**
Admin clicks Add, enters a unique 2-digit Code (e.g., 10), Short Name (e.g., "Junior Wing"), and Full Name (e.g., "Junior Wing Building"), then submits. The building appears in the list with no rooms initially.

**Editing a Building**
Admin clicks Edit, modifies any field, and saves. Changes are logged in the activity log.

**Viewing a Building**
Admin clicks View to see full details of a building.

**Toggling Status**
Admin clicks the status switch to activate or deactivate a building. Inactive buildings cannot be selected when creating new rooms.

**Deleting a Building**
Admin can soft-delete a building. It moves to the trash where it can be restored or permanently deleted.

---

## Example Scenario

A school campus has three buildings:
- **Code:** 10, **Name:** "Junior Wing" — Classes 1–5
- **Code:** 11, **Name:** "Senior Wing" — Classes 6–12
- **Code:** 12, **Name:** "Administration Block" — Offices and staff rooms

Each building is registered here. Later, rooms like "11G-10A" tell us: Building 11 (Senior Wing), Ground Floor, Class 10 Section A.

---

## Related Screens

- **Room** — Each room must be assigned to a building
- **Room Type Rooms** — Rooms displayed with their building name
