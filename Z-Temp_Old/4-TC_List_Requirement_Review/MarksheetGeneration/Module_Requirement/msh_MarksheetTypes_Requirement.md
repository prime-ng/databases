# Marksheet Types — Business Requirements

## What This Screen Does

The Marksheet Types screen is the foundational configuration screen of the marksheet system. It defines the categories of report cards or marksheets that the school can produce — for example, a Term Report Card, a Unit Test Slip, or an Annual Statement of Grades.

Each Marksheet Type acts as a master category that governs what kind of configuration templates can be created under it. By separating types like "Term Report Card" from "Unit Test Slip", the system allows schools to maintain completely different grading structures and formats for each kind of academic output.

The screen appears in the following contexts:
1. **Configuration Hub → Marksheet Types tab** — A tabbed interface displaying a paginated table of marksheet categories with their code, name, description, and active status.
2. **Modal-Based CRUD** — Inline modals on the hub page used to create, edit, restore, toggle status, and permanently delete categories.

---

## Default Data Load

When the user opens the Configuration Hub and selects the Marksheet Types tab, the system runs a query in the background that retrieves all categories, paginated at 15 records per page, using a specific page indicator for marksheet types. 

Active reference lists of academic sessions and exam types are loaded for filtering dropdowns.

---

## When This Screen Is Used

*   **Initial Module Configuration** — When the school first sets up the marksheet module, the coordinator defines what categories of marksheets they intend to generate (e.g., Term, Annual).
*   **Grading Policy Restructuring** — If the school introduces a new type of report (e.g., a "Monthly Progress Slip"), the coordinator creates a new marksheet type.
*   **Template Setup** — When creating a new configuration template, the coordinator selects the marksheet type to define its category.

---

## Key Fields at a Glance

**Identity and Code**
Each marksheet type has a unique code (e.g., "TERM_CARD") and a descriptive name (e.g., "Term Report Card"). The code must be globally unique across all categories.

**Display Order**
A display order field (positive integer) controls the visual sorting sequence in selection dropdowns, ensuring that "Term Report" appears before "Annual Statement".

**Description**
An optional description field allows the coordinator to document the purpose of the category (e.g., "Used for CBSE Term-1 and Term-2 reporting").

---

## Business Rules and Conditions

**Global Unique Code (BR-MSG-022)**
No two marksheet types can share the same code.

**Deletion Safeguards (BR-MSG-023)**
A marksheet type category cannot be permanently deleted if it is referenced by any active marksheet templates. The system blocks deletion.

**Active Status Gating (BR-MSG-024)**
Only active marksheet types appear as options in template setup dropdowns. Inactive categories are hidden from selection.

---

## Workflow Steps

**Creating a New Marksheet Type**
It is the start of the academic year. The Examination Coordinator, Mr. Sharma, opens the Configuration Hub and selects the Marksheet Types tab. He clicks "Add Marksheet Type" to open the creation modal. Mr. Sharma enters code "TERM_CARD", name "Term Report Card", description: _Used for Term 1 and Term 2 report card generation_, sets the display order to 1, and toggles Active to Yes. He clicks Save. The system validates the code is unique, saves the category, logs the action, and refreshes the list.

**Editing a Category**
Mr. Sharma needs to update a category name. He clicks Edit next to "TERM_CARD" in the list, changes the name to "Term Report Card (CBSE)", and clicks Save. The system updates the name and logs the change.

---

## Example Scenario

Greenwood International School has three report cycles: Term 1, Term 2, and Annual. The coordinator, Mrs. Desai, sets up three marksheet types:
1. **TERM_1** — "Term 1 Report Card", display order 1.
2. **TERM_2** — "Term 2 Report Card", display order 2.
3. **ANNUAL** — "Annual Statement of Grades", display order 3.

She can now set up templates under each category with specific exam configurations.

---

## Related Screens

*   **Config Templates** — Templates map specific grading rules under these categories.
*   **Marksheet Schedules** — Schedules execute calculations scoped by these categories.
