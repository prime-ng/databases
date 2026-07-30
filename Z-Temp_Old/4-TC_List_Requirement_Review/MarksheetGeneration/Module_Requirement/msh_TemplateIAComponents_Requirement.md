# Template IA Components — Business Requirements

## What This Screen Does

The Template IA Components tab configures the specific Internal Assessment (IA) components that appear on a report card template. Unlike the scholastic section (which pulls scores from formal exams), the internal assessment section captures ongoing, classroom-based tasks such as projects, oral tests, assignments, or laboratory records.

Each row links a master IA component category (e.g., "Project Work") to a specific marksheet template, defining its maximum possible marks and display sequence. Without this configuration, the report card would not display internal assessment marks. Teachers would have no way to record student scores for classroom tasks, and coordinators would have to track internal marks manually, increasing the administrative workload. By establishing these components, the school automates internal mark tracking and ensures they are displayed correctly on student report cards.

The screen appears in the following contexts:
1. **Components Hub → IA Components tab** — A tabbed interface displaying a paginated table of template IA components with their template, category, max marks, and display order.
2. **Modal-Based CRUD** — Inline modals on the components page used to add, edit, restore, toggle status, and delete mappings.

---

## Default Data Load

When the user opens the Components Hub and selects the IA Components tab, the system runs a query in the background that retrieves all template IA components, paginated at 15 records per page, using a specific page indicator for IA components. The query pre-loads references to the configuration template to display in the table.

Shared dropdown lists containing active templates and active IA component categories are loaded for the modals.

---

## When This Screen Is Used

*   **Template Setup** — When configuring a marksheet template, the coordinator defines which classroom tasks (e.g., Notebook, Oral Test) are evaluated.
*   **Updating Assessment Rules** — If the board changes the max marks for projects (e.g., from 10 to 20 marks), the coordinator updates the configuration.
*   **Reordering Report Cards** — When the coordinator needs to adjust the order in which internal marks are displayed on the report card.

---

## Key Fields at a Glance

**Template and IA Category Binding**
*   **Config Template** — The marksheet template this component belongs to.
*   **IA Component Type** — The category of internal assessment (e.g., "Notebook Maintenance").

**Marks and Sequence**
*   **Max Marks** — The maximum possible score for the component. Must be 0 or greater.
*   **Display Order** — A positive integer determining the visual sequence on the report card.

---

## Business Rules and Conditions

**Unique IA Category per Template (BR-MSG-053)**
You cannot link the same internal assessment category to a configuration template more than once.

**Deletion Safety (BR-MSG-054)**
A template IA component mapping cannot be permanently deleted if student IA marks have already been recorded under it. The system blocks the deletion.

**Soft Deletion (BR-MSG-055)**
Deleting a component soft-deletes the record (moves it to trash), from where it can be restored (reactivating it) or permanently deleted.

---

## Workflow Steps

**Mapping an IA Component to a Template**
It is the start of the academic year. The Examination Coordinator, Mr. Sharma, opens the Components Hub and selects the IA Components tab. He clicks "Add" to open the creation modal. Mr. Sharma selects Template "CBSE Grade 10 Template", selects IA Component Type "Notebook Maintenance", enters Max Marks "5.00", sets Display Order to 1, and sets status to Active. He clicks Save. The system validates uniqueness, saves the mapping, logs the action, and refreshes the list.

**Editing a Component**
The board updates the Notebook weight to 10 marks. Mr. Sharma clicks Edit next to the component in the list, changes the Max Marks to 10.00, and clicks Save. The system updates the marks and logs the change.

---

## Example Scenario

Greenwood International School requires three internal assessments for Class 10. The coordinator, Mrs. Desai, sets up the components under the template:
1. **NOTEBOOK** — Notebook Maintenance, Max Marks: 5, Display Order: 1.
2. **PORTFOLIO** — Project Report, Max Marks: 5, Display Order: 2.
3. **MULTIPLE** — Viva Voce, Max Marks: 10, Display Order: 3.

These components appear in order on the student results entry screen and final report cards.

---

## Related Screens

*   **Config Templates** — The template that owns these components.
*   **IA Component Types** — The source master list of IA categories.
*   **Student IA Marks** — Where student scores are entered against these components.
*   **Subject Results** — Displays the rolled-up IA total.
