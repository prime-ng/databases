# Exam Groups — Business Requirements

## What This Screen Does

The Exam Groups screen allows schools to define logical groupings of exam types that constitute a complete examination cycle. Rather than selecting individual exams (like "Term-1 Half-Yearly" and "Term-1 Pre-Board") one by one when building a marksheet template, the school first bundles the relevant exam types into an Exam Group — for example, a "Term-1 Exams" group might contain Half-Yearly, Unit Test 1, and Unit Test 2.

This screen simplifies the setup of marksheet configuration templates. When an Exam Group is assigned to a template, all its linked exam types automatically participate in the grade calculations. This ensures that the report cards generated under the template cover all necessary exam components.

The screen appears in the following contexts:
1. **Configuration Hub → Exam Groups tab** — A tabbed interface displaying a paginated table of exam groups with their code, name, academic session, date range, and active status.
2. **Modal-Based CRUD** — Pop-up modals used to create, edit, restore, and permanently delete exam groups directly from the hub page.

---

## Default Data Load

When the user navigates to the Configuration Hub and selects the Exam Groups tab, the system runs a query in the background that retrieves all exam groups, paginated at 15 records per page, using a specific page indicator for exam groups. The query pre-loads references to the academic session and the linked exam types to display in the table.

Shared dropdown lists containing active academic sessions and active exam types are loaded and shared with the create/edit modals.

---

## When This Screen Is Used

*   **Academic Year Setup** — At the start of a school session, the coordinator defines which exams belong to the Term 1, Term 2, or Annual exam groups.
*   **Curriculum Shifts** — When the school updates its exam pattern (e.g., adding a third Unit Test), the coordinator updates the exam group to include the new exam type.
*   **Template Setup** — When creating a new configuration template, the coordinator selects the appropriate exam group to define which tests contribute to the report card.

---

## Key Fields at a Glance

**Identity and Session Association**
Each exam group has a unique code (e.g., "TERM1_EXAMS") and a descriptive name (e.g., "Term-1 Exams"). The code must be unique within the selected Academic Session, allowing the reuse of codes across different academic years.

**Term Date Range**
Optional Start Date and End Date fields define the calendar window for the exam group. These dates can be used by other systems (like Homework or Quizzes) to identify which scores fall within this term.

**Exam Mappings**
A list where the coordinator selects which exam types (e.g., "Periodic Test", "Half-Yearly") belong to the group.

---

## Business Rules and Conditions

**Session-Scoped Uniqueness (BR-MSG-011)**
The exam group code must be unique within the same academic session. Different sessions can reuse the same code (e.g., "T1" in 2025 and 2026), but duplicate codes within the same year are blocked.

**Junction Synchronization (BR-MSG-012)**
When saving an exam group, the system synchronizes its exam mappings, linking newly selected exam types and unlinking removed ones safely.

**Date Validation (BR-MSG-013)**
If both start and end dates are entered, the end date must be on or after the start date.

**Deletion Safeguards (BR-MSG-014)**
An exam group cannot be permanently deleted if it is currently linked to any active configuration templates. Deletion will be blocked by the system.

---

## Workflow Steps

**Creating a New Exam Group**
It is the start of the school session. The Examination Coordinator, Mr. Sharma, opens the Configuration Hub and selects the Exam Groups tab. He clicks "Add Exam Group" to open the pop-up modal. Mr. Sharma selects Academic Session "2026-27", enters code "T1_EXAMS", name "Term 1 Exams", sets the start date to April 1, 2026, and the end date to September 30, 2026. He selects "Periodic Test 1", "Periodic Test 2", and "Half-Yearly Exam" from the list of exam types and clicks Save. The system validates the code is unique, saves the exam group, links the exam types, and refreshes the list.

**Modifying an Exam Group**
Mid-term, the board introduces a new "Oral Quiz" exam type that must contribute to Term 1. Mr. Sharma clicks Edit next to the "Term 1 Exams" group in the list, checks "Oral Quiz" in the exam types checklist, and clicks Save. The system updates the mappings and logs the change.

---

## Example Scenario

Greenwood International School has three major terms. The Examination Coordinator, Mrs. Desai, sets up an exam group for Term 1:
*   **Group Name**: "Term 1 Assessments" (code: T1_EXAMS)
*   **Mapped Exams**: Periodic Test 1, Periodic Test 2, and Half-Yearly.

Later, when she creates the "Term 1 Template", she selects "Term 1 Assessments" as the exam group. These exam types are now available for weightage configuration.

---

## Related Screens

*   **Config Templates** — Templates reference these exam groups to know which scores to fetch.
*   **Template Exam Weightages** — Where the relative percentages of each exam type in the group are defined.
*   **Exam Types** — The source master list of exam types.
