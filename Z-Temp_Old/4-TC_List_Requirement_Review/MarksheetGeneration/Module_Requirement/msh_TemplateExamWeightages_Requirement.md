# Template Exam Weightages — Business Requirements

## What This Screen Does

The Template Exam Weightages tab determines how each exam type — such as "Periodic Test", "Half-Yearly Exam", or "Annual Exam" — contributes to the final academic score on a marksheet template. While other configurations map the individual exam papers, this screen defines the proportional weight (percentage) each category of exam carries in the final calculations.

This configuration is the grading formula for the template. Without exam weightages, the system would not know how to compile final grades. It would not know whether a periodic test is worth 10% or 50% compared to a final exam, leading to uncalculated report cards. By establishing these weightages, the school automates the calculation of final terms based on their relative percentages.

The screen appears in the following contexts:
1. **Components Hub → Exam Weightages tab** — A tabbed interface displaying a paginated table of template exam weightages with their template, exam type, and weightage percentage.
2. **Modal-Based CRUD** — Inline modals on the components page used to add, edit, restore, toggle status, and delete weightage mappings.

---

## Default Data Load

When the user opens the Components Hub and selects the Exam Weightages tab, the system runs a query in the background that retrieves all weightages, paginated at 15 records per page, using a specific page indicator for exam weightages. The query pre-loads references to the configuration template to display in the table.

Shared dropdown lists containing active templates and active exam types are loaded for the modals.

---

## When This Screen Is Used

*   **Template Setup** — When setting up a marksheet template, the coordinator defines the weightage percentages for each exam type.
*   **Grading Policy Updates** — If the school updates its weightage rules (e.g., increasing the final exam weight from 50% to 60%), the coordinator updates this screen.
*   **Adding New Exam Types** — When a new exam type is added mid-year, the coordinator maps its weightage percentage.

---

## Key Fields at a Glance

**Template and Exam Type Mapping**
*   **Config Template** — The marksheet template this weightage applies to.
*   **Exam Type** — The category of exam (e.g., "Half-Yearly Exam").

**Weightage Details**
*   **Weightage Percent** — The percentage this exam type contributes to the scholastic total (e.g., 30.00%). Must be between 0 and 100.
*   **Max Marks** — An optional marks cap for display formatting. Must be 0 or greater.

---

## Business Rules and Conditions

**Unique Exam Type per Template (BR-MSG-049)**
You cannot map the same exam type to the same configuration template more than once.

**Independent Saving (BR-MSG-050)**
Unlike the scholastic components setup, this service does not automatically validate that the sum of all weightage percentages equals 100% when saving a single record. The total sum is evaluated during marksheet calculations.

**Deletion Safety (BR-MSG-051)**
An exam weightage mapping cannot be permanently deleted if student results have already been computed using it. The system blocks the deletion.

**Soft Deletion (BR-MSG-052)**
Deleting a mapping soft-deletes the record (moves it to trash), from where it can be restored (reactivating it) or permanently deleted.

---

## Workflow Steps

**Configuring an Exam Weightage**
It is the start of the academic year. The Examination Coordinator, Mr. Sharma, opens the Components Hub and selects the Exam Weightages tab. He clicks "Add" to open the mapping modal. Mr. Sharma selects Template "CBSE Grade 10 Template", selects Exam Type "Half-Yearly Exam", enters Weightage Percent "30.00", and sets status to Active. He clicks Save. The system validates uniqueness, saves the weightage, logs the action, and refreshes the list.

**Editing a Weightage**
The board increases the Half-Yearly weight to 40.00%. Mr. Sharma clicks Edit next to the mapping in the list, changes the Weightage Percent to 40.00, and clicks Save. The system updates the percentage and logs the change.

---

## Example Scenario

Greenwood International School has a "Term 1 Template". The coordinator, Mrs. Desai, sets up the weightages:
*   Periodic Test 1 — Weight: 20.00%
*   Half-Yearly Exam — Weight: 30.00%
*   Final Exam — Weight: 50.00%

When results are computed, the system calculates the student's final score by applying these percentages to their scores in each exam.

---

## Related Screens

*   **Config Templates** — The template that owns these weightages.
*   **Exam Types** — The source master list of exam categories.
*   **Student Subject Results** — Displays the final calculated grades.
