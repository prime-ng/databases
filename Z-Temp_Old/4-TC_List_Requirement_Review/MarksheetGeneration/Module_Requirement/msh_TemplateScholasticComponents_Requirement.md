# Template Scholastic Components — Business Requirements

## What This Screen Does

The Template Scholastic Components tab maps external exam score sources — specifically individual exams — to a marksheet template. Each row defines which exam feeds into the template's academic section, what column header appears on the printed marksheet, the maximum marks it carries, and what percentage weight it contributes to the overall scholastic total.

This screen is the core weightage management layer. Because a student's final scholastic grade is a weighted sum of all mapped exams, the system automatically checks that the combined weightage percentages across all active exams for a template do not exceed 100%. Without this mapping, the system would not know which exams to pull for a report card. Without the weightage check, users could save conflicting percentages, resulting in mathematically incorrect report cards. By establishing these mappings, the school automates exam score retrieval and guarantees that all weightage splits are mathematically valid.

The screen appears in the following contexts:
1. **Components Hub → Scholastic Components tab** — A tabbed interface displaying a paginated table of mapped exams with their template, source exam, weightage percentage, and max marks.
2. **Modal-Based CRUD** — Inline modals on the components page used to add, edit, restore, toggle status, and delete mappings.

---

## Default Data Load

When the user opens the Components Hub and selects the Scholastic Components tab, the system runs a query in the background that retrieves all mapped exams, paginated at 15 records per page, using a specific page indicator for scholastic components. The query pre-loads references to the configuration template and source exam to display in the table.

Shared dropdown lists containing active templates and active exam sources are loaded for the modals.

---

## When This Screen Is Used

*   **Template Setup** — When configuring a marksheet template, the coordinator maps which exams (e.g., Annual Exam, Half-Yearly) contribute to the academic score.
*   **Updating Grading Weights** — If the academic policy updates (e.g., changing the Final Exam weight from 50% to 60%), the coordinator updates the weightage percentages.
*   **Adding New Exams** — When a new exam is introduced mid-year, the coordinator maps it to the relevant templates.

---

## Key Fields at a Glance

**Template and Exam Source Mapping**
*   **Config Template** — The marksheet template this mapping belongs to.
*   **Source Exam** — The source exam to retrieve scores from.
*   **Display Label** — The text label printed as the column header on the marksheet.

**Weightage and Marks**
*   **Weightage Percent** — The percentage this exam contributes to the scholastic total (e.g., 40.00%). Must be between 0 and 100.
*   **Max Marks** — The maximum possible marks for the exam. Must be 0 or greater.

---

## Business Rules and Conditions

**Unique Exam Source per Template (BR-MSG-056)**
You cannot map the same exam source to a configuration template more than once.

**100% Weightage Cap (BR-MSG-057)**
The sum of all active weightage percentages assigned to a template's scholastic components must not exceed 100%. If a user attempts to save a mapping that pushes the total over 100%, the system blocks the transaction and displays an error.

**Deletion Safety (BR-MSG-058)**
A scholastic component mapping cannot be permanently deleted if student results have already been calculated using it. The system blocks the deletion.

**Soft Deletion (BR-MSG-059)**
Deleting a mapping soft-deletes the record (moves it to trash), from where it can be restored (reactivating it) or permanently deleted.

---

## Workflow Steps

**Mapping an Exam with Weightage Check**
It is the start of the academic year. The Examination Coordinator, Mr. Sharma, opens the Components Hub and selects the Scholastic Components tab. He clicks "Add" to open the creation modal. He selects Template "CBSE Grade 10 Template", selects Source Exam "Annual Exam", enters Weightage Percent "50.00", and Max Marks "100.00". He clicks Save. The system checks that the exam is not already mapped and that the total weightage for the template (which currently has 30% from another exam) is now 80% (under the 100% limit). The mapping is saved.

**Handling a Weightage Sum Error**
Mr. Sharma attempts to add another exam with 30% weightage. The system calculates the new total would be 110% (80% + 30%), blocks the save, and displays the error: _Scholastic weightage sum validation failed._ Mr. Sharma must reduce the weightage or deactivate another component before saving.

---

## Example Scenario

Greenwood International School has three exams. The coordinator, Mrs. Desai, maps them under the template:
*   Periodic Test 1 — Weight: 20.00%
*   Half-Yearly Exam — Weight: 30.00%
*   Annual Exam — Weight: 50.00%

Once the third mapping is saved, the system verifies the sum equals 100% and approves the template for marksheet calculations.

---

## Related Screens

*   **Config Templates** — The template that owns these components.
*   **Source Components** — The pre-configured exam sources.
*   **Subject Results** — Displays the calculated weighted totals.
*   **Student Results** — Compiles overall student totals.
