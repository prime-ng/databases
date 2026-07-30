# Config Templates — Business Requirements

## What This Screen Does

The Config Templates screen is the central configuration blueprint of the marksheet system. A Config Template defines exactly how a student's marksheet should be calculated and presented. It ties together all aspects of the grading system: which marksheet category (report card layout) it belongs to, which exam group (collection of exams) feeds into the calculations, which scholastic subjects and internal assessment (IA) components are evaluated, how weightages are distributed, and which co-scholastic areas are graded.

This screen serves as the academic rulebook for a set of classes. Without config templates, the school would have no standardized way to calculate grades. The system would not know how much a periodic test contributes compared to a final exam, what passing percentage to apply, or how to map scores to letter grades. The Examination Coordinator would have to manually compute results for every student, leading to administrative chaos and high margin of error. By defining a config template, the school ensures that grading formulas are automated and uniform for all classes assigned to it.

The screen appears in three contexts:
1. **Configuration Hub → Config Templates tab** — A tabbed interface displaying a paginated table of templates with their code, name, board code, passing percentage, and active status.
2. **Standalone Create/Edit Pages** — Full-page forms for configuring extensive template parameters and class assignments.
3. **Template Details Page (Show Page)** — A dedicated overview page displaying the template's parameters along with its scholastic, co-scholastic, exam weightage, and IA components.

---

## Default Data Load

When the user opens the Configuration Hub and selects the Config Templates tab, the system paginates config templates at 15 rows per page, using a specific page indicator for templates. The query pre-loads references to the marksheet type, exam group, and academic session to display them in the table.

When creating or editing a template, the standalone page loads active reference lists for:
*   Marksheet Types
*   Exam Groups
*   Academic Sessions
*   Grading Schemas (describing grade mapping boundaries)
*   Active School Classes and Class Groups (for assigning target classes to this template)

---

## When This Screen Is Used

*   **Academic Year Setup** — At the start of a new school year, the coordinator creates new templates (or updates existing ones) to match the school's grading policy for that year.
*   **Curriculum Shifts** — If the school changes its board (e.g., switching from CBSE to a custom system), the coordinator configures a new template to enforce the new board's guidelines.
*   **Grade-Level Differentiation** — When different sections of the school require different passing thresholds (e.g., Primary requires 40% while Secondary requires 33%), separate templates are created for each section.
*   **Class Assignment Updates** — When class sections change mid-year, the coordinator updates the template's class assignments to map the new sections.

---

## Key Fields at a Glance

**Identity and Curricular Context**
Each template has a unique code (e.g., "CBSE_10_2026") that is unique within its academic session, a template name (e.g., "CBSE Class 10 Template"), and an optional board code (e.g., "CBSE", "ICSE"). It links to an Academic Session, a Marksheet Type (report format), and an Exam Group (the set of exams evaluated).

**Grading and Assessment Rules**
*   **Passing Percentage** — The minimum percentage a student must score to pass a subject (e.g., 33.00%). Must be between 0 and 100.
*   **Compartment Max Failures** — The maximum number of subjects a student can fail and still qualify for a compartment exam rather than being detained. Must be between 0 and 255.
*   **Best of N Settings** — An optional toggle to enable "Best of N" calculations, along with a field to specify the count (e.g., picking the best 2 out of 3 periodic tests).
*   **Grading Schema** — An optional schema mapping numeric marks to letter grades.

**Class Assignments**
A list where the coordinator maps specific classes (e.g., "Grade 10 Section A") or entire class groups (e.g., "Secondary Section") to the template.

---

## Business Rules and Conditions

**Session-Scoped Uniqueness (BR-MSG-005)**
The template code must be unique within the same academic session. Two different sessions can share the same template code, but within the same session, codes must be distinct.

**Locked Template Protection (BR-MSG-006)**
Once a template is linked to a marksheet schedule that has been published, it is locked. A locked template cannot be updated, edited, or deleted.

**Class Assignment Synchronization (BR-MSG-007)**
When you save a template, the system synchronizes class and group assignments. It unlinks removed classes and links new ones, ensuring the mappings are accurate.

**Deletion Restrictions (BR-MSG-008)**
A template cannot be deleted if it is referenced by any marksheet schedules or has scholastic, co-scholastic, weightage, or IA components configured under it.

---

## Workflow Steps

**Creating a Config Template from Scratch**
It is the start of the academic year. The Examination Coordinator, Mr. Sharma, opens the Configuration Hub and selects the Config Templates tab. He clicks "Add Config Template" which takes him to a standalone creation page. Mr. Sharma selects Academic Session "2026-27", enters code "CBSE_SEC_2026", name "CBSE Secondary 2026-27", selects Marksheet Type "Term Report Card", selects Exam Group "Term 1 Exams", sets the Passing Percentage to 33.00, and sets Compartment Max Failures to 2. Under Class Assignments, he adds two rows: one for the "Secondary Section" class group, and one for a custom class "Grade 10 Special". He clicks Save. The system validates the code is unique within the session, saves the template, links the classes, and redirects him to the Config Templates tab.

**Modifying a Config Template**
Two weeks later, the board updates the passing percentage to 35.00%. Mr. Sharma clicks Edit next to the template, updates the Passing Percentage field to 35.00, and clicks Save. The system updates the template, logs the change, and redirects him back.
   > [!WARNING]
   > If the template is locked (published), the Edit option is disabled, and any attempt to save changes will be blocked.

---

## Example Scenario

Greenwood International School needs to configure Term 1 report cards for Grade 9 and Grade 10. The Examination Coordinator, Mrs. Desai, sets up the template:
*   **Template**: "CBSE Secondary Term-1" (code: CBSE_SEC_T1)
*   **Passing Criteria**: 33.00%
*   **Compartment Failures**: Max 2 subjects
*   **Class Assignment**: Assigned to the "Secondary (9-10)" Class Group.

Once saved, Mrs. Desai opens the template's details page to verify all settings. The template is now ready to receive weightages and exam components.

---

## Related Screens

*   **Components Hub** — Where scholastic, co-scholastic, weightages, and IA components are defined for this template.
*   **Marksheet Schedules** — Where schedules link to this template to generate report cards.
*   **Class Groups** — Defines the class groups that can be assigned to this template.
