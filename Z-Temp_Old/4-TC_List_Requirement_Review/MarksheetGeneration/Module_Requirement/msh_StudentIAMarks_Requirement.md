# Student IA Marks — Business Requirements

## What This Screen Does

The Student IA Marks screen displays and manages detailed, component-level scores recorded for each student's Internal Assessments (IA) per subject. Unlike the main Subject Results screen which shows a single rolled-up internal assessment total, this screen breaks down scores for every individual component (such as "Lab Record", "Term Project", or "Viva Voce") with the marks obtained and maximum possible marks.

This screen provides the detailed evidence behind a student's final internal assessment total. Without it, teachers would have no way to verify how a student's internal score was compiled. They would have to search through separate markbooks or spreadsheets to justify a grade, increasing the workload during parent-teacher meetings. By providing this detailed breakdown, the school ensures full transparency in grading and supports easy manual score entry and corrections.

The screen appears in the following contexts:
1. **Results Hub → IA Marks tab** — An accordion list where each student row expands to reveal a subject-wise table of internal assessment scores.
2. **Modal-Based CRUD** — Modals used to add and edit individual IA marks directly from the results page.

---

## Default Data Load

When the user opens the Results Hub and selects the IA Marks tab, the system runs a query in the background that retrieves student results, paginated at 10 records per page, using a specific page indicator for IA marks. The system then batch-retrieves all IA mark records for those students, pre-loading references to the subject and template component type, and displays them inline.

The class section filter is loaded using a shared list of classes that have computed results.

---

## When This Screen Is Used

*   **Audit and Review** — After computation, the coordinator reviews the component-level internal marks for each student to verify correctness.
*   **Manual Entry of Marks** — When a teacher needs to record scores for a specific classroom task (e.g., John's Science Project score), they open the entry modal.
*   **Grading Corrections** — If a score was typed in incorrectly, the teacher opens the edit modal to adjust the marks.

---

## Key Fields at a Glance

**Student, Subject, and Component Context**
*   **Student** — The student receiving the marks.
*   **Marksheet Schedule** — The active schedule.
*   **Subject** — The academic subject (e.g., "Science").
*   **IA Component** — The specific component (e.g., "Lab Report 1").

**Marks Details**
*   **Marks Obtained** — The score awarded to the student. Must be 0 or greater.
*   **Max Marks** — The maximum possible score for the component. Must be 0 or greater.

---

## Business Rules and Conditions

**Unique Component Entry (BR-MSG-032)**
A student can only have one marks record per IA component in a given schedule, subject, and component context. Duplicate entries are blocked.

**Active Status Control (BR-MSG-033)**
Only active IA marks are included in final marksheet calculations.

**Deletion and Integrity (BR-MSG-034)**
Deleting a mark record soft-deletes it (moves it to trash), from where it can be restored (reactivating it) or permanently deleted.

---

## Workflow Steps

**Manually Entering an Internal Assessment Mark**
It is the end of the term. The Science Teacher, Mr. Sharma, opens the Results Hub and selects the IA Marks tab. He filters the list by "Grade 10 - Section A" and expands student John Doe's row. Under the "Science" section, he notices that the "Viva Voce" component is blank. Mr. Sharma clicks "Add IA Marks" to open the entry modal. He selects Student "John Doe", Schedule "Term 1 Final", Subject "Science", IA Component "Viva Voce", enters Marks Obtained "9.00", and Max Marks "10.00". He clicks Save. The system validates the entry, saves the score, logs the action, and refreshes the page to display the score.

---

## Example Scenario

Greenwood International School requires three internal assessments for Science. The coordinator, Mrs. Desai, opens the IA Marks tab for Grade 10-A. Student John Doe has:
*   "Lab Record" — Marks: 18.00 / 20.00
*   "Project Report" — Marks: 15.00 / 20.00
*   "Viva Voce" — Marks: 9.00 / 10.00

She notices John's Project Report score should be 17.00. She clicks the edit icon next to the score, changes it to 17.00, and clicks Save. The system updates the score and logs the change.

---

## Related Screens

*   **Student Results** — The parent results tab.
*   **Subject Results** — Shows rolled-up theory, practical, and IA totals.
*   **Template IA Components** — Defines the IA components for templates.
