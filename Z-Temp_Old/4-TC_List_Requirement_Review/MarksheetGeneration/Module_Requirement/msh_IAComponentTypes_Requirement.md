# IA Component Types — Business Requirements

## What This Screen Does

The IA Component Types screen defines the master library of Internal Assessment (IA) component categories that the school uses to grade students. Internal Assessment covers ongoing, teacher-evaluated activities that supplement formal written exams — such as notebook completion, subject enrichment activities, project work, and class participation.

This screen establishes standard classification labels. When building a marksheet template, the school selects which of these active IA categories apply and defines their respective marks via the template setup page. This separation of type definition from weightage assignment allows the school to maintain a consistent library of assessment categories and apply them flexibly across different grade levels.

The screen appears in the following contexts:
1. **Configuration Hub → IA Component Types tab** — A tabbed interface displaying a paginated table of IA component categories with their code, name, description, and active status.
2. **Modal-Based CRUD** — Inline modals on the hub page used to create, edit, restore, and delete categories.

---

## Default Data Load

When the user navigates to the Configuration Hub and selects the IA Component Types tab, the system runs a query in the background that retrieves all categories, paginated at 15 records per page, using a specific page indicator for IA types. No complex relationships are loaded as this entity is a flat master list. Search and status filters are applied only when this tab is selected.

---

## When This Screen Is Used

*   **Grading Policy Setup** — At the start of system setup, the coordinator registers all internal assessment categories recognized by the school (e.g., Notebook, Subject Enrichment, Portfolio).
*   **Curriculum Revisions** — When the education board mandates a new internal assessment category, the coordinator registers it in this list.
*   **Template Setup** — When configuring template components, these categories populate the dropdown selection list.

---

## Key Fields at a Glance

**Category Identity**
Each IA component type is defined by a unique code (e.g., "NOTEBOOK") and a descriptive name (e.g., "Notebook Maintenance"). The code must be unique across all categories and is used in results calculations.

**Display and Sorting**
A display order field (positive integer) controls the visual sorting sequence in configuration dropdowns, helping coordinators list components in a logical order (e.g., Notebook first, then Project).

**Description**
An optional description field allows the coordinator to document what the category measures (e.g., "Evaluation of regular notebook maintenance and completeness of work").

---

## Business Rules and Conditions

**Global Unique Code (BR-MSG-015)**
The category code must be unique across all IA component types in the system, preventing conflicts during marksheet calculations.

**Cascade Protection on Deletion (BR-MSG-016)**
An IA component type category cannot be permanently deleted if it is referenced by any active marksheet templates. The system blocks the deletion.

**Active Status Gating (BR-MSG-017)**
Only active IA component types are displayed as options in template setup dropdowns. Inactive categories are hidden from selection.

---

## Workflow Steps

**Creating a New IA Component Type**
It is the start of the academic session. The Examination Coordinator, Mr. Sharma, opens the Configuration Hub and selects the IA Component Types tab. He clicks "Add IA Component Type" to open the creation modal. Mr. Sharma enters code "SUB_ENRICHMENT", name "Subject Enrichment", description: _Covers hands-on lab experiments and subject enrichment tasks_, sets the display order to 2, and toggles Active to Yes. He clicks Save. The system validates the code is unique, saves the category, logs the action, and refreshes the list. The component type is now available when configuring template components.

**Editing an IA Component Type**
Mr. Sharma needs to clarify what is evaluated under Notebooks. He clicks the Edit button next to the "NOTEBOOK" category in the list, updates the description to: _Evaluates regular submission, neatness, and completeness of notes_, and clicks Save. The system updates the description and logs the change.

---

## Example Scenario

Greenwood International School follows CBSE guidelines, which require evaluating four internal assessment components: Notebook, Subject Enrichment, Portfolio, and Multiple Assessments. The coordinator, Mrs. Desai, sets up four IA component types:
1. **NOTEBOOK** — "Notebook Maintenance", display order 1.
2. **ENRICH** — "Subject Enrichment", display order 2.
3. **PORTFOLIO** — "Portfolio / Project", display order 3.
4. **MULTIPLE** — "Multiple Assessments", display order 4.

Later, she configures these on the templates to map maximum marks and student score entries.

---

## Related Screens

*   **Template IA Components** — Where these categories are assigned max marks for specific templates.
*   **Student IA Marks** — Where teachers enter student scores against these components.
