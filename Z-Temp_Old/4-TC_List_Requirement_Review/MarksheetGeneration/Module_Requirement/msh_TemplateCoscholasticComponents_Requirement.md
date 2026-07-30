# Template Coscholastic Components — Business Requirements

## What This Screen Does

The Template Coscholastic Components tab defines the non-academic grading areas that appear on a report card template. Unlike the scholastic section (which evaluates written exam scores), the co-scholastic section grades students on broader development areas such as behaviour, sports, art, yoga, or community service. These are typically graded on a qualitative scale (e.g., A, B, C, D) rather than numeric scores.

Each row defines a co-scholastic area for a template — such as the grading scale label and display order. The screen also allows linking a component to the Behavioural Assessment module, which enables the automatic population of behavior grades. Without this setup, the report card would not display non-academic evaluations, preventing a holistic review of student development.

The screen appears in the following contexts:
1. **Components Hub → Coscholastic Components tab** — A tabbed interface displaying a paginated table of template co-scholastic components with their template, code, name, and grading scale.
2. **Modal-Based CRUD** — Inline modals on the components page used to add, edit, restore, toggle status, and delete mappings.

---

## Default Data Load

When the user opens the Components Hub and selects the Coscholastic Components tab, the system runs a query in the background that retrieves all components, paginated at 15 records per page, using a specific page indicator for co-scholastic components. The query pre-loads references to the configuration template to display in the table.

A shared dropdown list of active config templates is loaded for the modals.

---

## When This Screen Is Used

*   **Template Setup** — When setting up a new marksheet template, the coordinator defines which co-scholastic components (e.g., Health, Work Education) appear on the report card.
*   **Integrating Behavior Marks** — When linking a component to the Behavioural Assessment module for automatic grade retrieval.
*   **Reordering Report Cards** — When the school wants to adjust the order in which non-academic sections are printed.

---

## Key Fields at a Glance

**Template and Component Identity**
*   **Config Template** — The marksheet template this component belongs to.
*   **Component Code** — A short code (e.g., "BEHAVE") that must be unique within the selected template.
*   **Component Name** — The display name (e.g., "Behaviour and Discipline").

**Grading Scale and Order**
*   **Grading Scale** — A descriptive label for the grading scale used (e.g., "5-Point Scale", "A-E").
*   **Display Order** — A positive integer determining the visual sequence on the report card.
*   **BA Linked (Behavioral Assessment)** — A checkbox indicating whether the grade should be automatically retrieved from the behavior log.

---

## Business Rules and Conditions

**Unique Code per Template (BR-MSG-046)**
The component code must be unique within the same configuration template.

**Deletion Safety (BR-MSG-047)**
A co-scholastic component mapping cannot be permanently deleted if student co-scholastic grades have already been recorded under it. The system blocks the deletion.

**Soft Deletion (BR-MSG-048)**
Deleting a component soft-deletes the record (moves it to trash), from where it can be restored (reactivating it) or permanently deleted.

---

## Workflow Steps

**Adding a Co-scholastic Component to a Template**
It is the start of the term. The Examination Coordinator, Mr. Sharma, opens the Components Hub and selects the Coscholastic Components tab. He clicks "Add" to open the creation modal. Mr. Sharma selects Template "CBSE Grade 10 Template", enters code "BEHAVE", name "Behaviour and Discipline", grading scale "5-Point Scale", sets the display order to 1, and checks **BA Linked**. He clicks Save. The system validates uniqueness, saves the component, logs the action, and refreshes the list.

**Editing a Component**
Mr. Sharma needs to change a display order. He clicks Edit next to the component, changes the Display Order from 1 to 2, and saves. The system updates the order and logs the change.

---

## Example Scenario

Greenwood International School has a "Term 1 Report Card". The coordinator, Mrs. Desai, sets up four co-scholastic components under the template:
1. **BEH** — "Behaviour", order 1, BA-linked (auto-graded).
2. **ART** — "Art & Craft", order 2, manual grading.
3. **PE** — "Physical Education", order 3, manual grading.

Once saved, these sections appear in sequence on the student report cards.

---

## Related Screens

*   **Config Templates** — The template that owns these components.
*   **Student Coscholastic Results** — Where student grades are recorded against these components.
*   **Behavioural Assessment Module** — The source system for auto-graded behavior scores.
