# Student Coscholastic Results — Business Requirements

## What This Screen Does

The Student Coscholastic Results screen displays and manages grades awarded to students for non-academic areas such as Life Skills, Art Education, Physical Education, and Health & Wellness. Unlike academic results which use numerical scores, co-scholastic results are purely grade-based (e.g., A+, A, B, C).

This screen allows teachers and administrators to review qualitative performance. Without it, the school would have no centralized interface to view or modify holistic student evaluations. The homeroom teacher would have to manually record co-scholastic grades on paper, leading to loss of data and inconsistencies on the final printed report cards. By establishing this interface, the school automates the tracking of holistic grades, supports auto-retrieval from behavior assessments, and enables fast manual updates.

The screen appears in the following contexts:
1. **Results Hub → Coscholastic Results tab** — An accordion list where each student row expands to reveal their co-scholastic components table.
2. **Modal-Based CRUD** — Modals used to record and edit co-scholastic grades directly from the results page.

---

## Default Data Load

When the user opens the Results Hub and selects the Coscholastic Results tab, the system runs a query in the background that retrieves student results, paginated at 10 records per page, using a specific page indicator for co-scholastic results. Once the students are loaded, the system batch-retrieves all co-scholastic grade records for those students, grouped by student, and displays them inline.

The class section filter is loaded using a shared list of classes that have computed results.

---

## When This Screen Is Used

*   **Grade Verification** — After marksheet computation, the homeroom teacher verifies that all student co-scholastic grades are correctly loaded.
*   **Manual Grade Entry** — When a student's grade for a manual component (like Art Education) is missing, the teacher opens the modal to record it.
*   **Correction of Grades** — If a student was graded incorrectly, the teacher updates the grade and adds explanatory remarks.

---

## Key Fields at a Glance

**Student and Evaluation Mappings**
*   **Student** — The student being graded.
*   **Marksheet Schedule** — The active schedule.
*   **Co-scholastic Component** — The non-academic activity (e.g., "Art Education").

**Grade and Comments**
*   **Grade** — The qualitative grade awarded (e.g., A, B, C).
*   **Remarks** — Optional comments (up to 255 characters) explaining the student's performance.

**Source Badge**
*   **Evaluation Source** — A status badge showing "Auto (BA)" if the grade was automatically pulled from behavior records, or "Manual" if entered by a teacher.

---

## Business Rules and Conditions

**Unique Component Grade (BR-MSG-028)**
A student can only have one grade record per co-scholastic component in a given marksheet schedule. Duplicate records are blocked.

**Auto-grading Visual Identifier (BR-MSG-029)**
The system displays distinct badges ("Auto (BA)" vs "Manual") to clearly differentiate between automatically calculated grades and manually entered ones.

**Active Status Control (BR-MSG-030)**
Only active co-scholastic grade records are displayed and printed on student report cards.

**Deletion Safety (BR-MSG-031)**
Deleting a grade soft-deletes the record (moves it to trash), from where it can be restored (which automatically makes it active again) or permanently deleted.

---

## Workflow Steps

**Manually Entering a Co-scholastic Grade**
It is the end of the term. The Grade 10 Homeroom Teacher, Mr. Sharma, opens the Results Hub and selects the Coscholastic Results tab. He filters the list by "Grade 10 - Section A". The list of students loads. He expands student Sarah Jones's row and notices that the "Art Education" component displays a pending status. He clicks "Add Coscholastic Result" to open the entry modal. Mr. Sharma selects Student "Sarah Jones", Schedule "Term 1 Final", Component "Art Education", selects Grade "A", and enters remarks: _Excellent participation in the school art exhibition_. He clicks Save. The system saves the grade, marks it as "Manual", and refreshes the page.

---

## Example Scenario

Greenwood International School grades students on five co-scholastic components. The coordinator, Mrs. Desai, opens the Coscholastic Results tab for Grade 10-A. Student Sarah Jones has:
*   "Life Skills" — Grade: A+ (Source: Auto BA)
*   "Art Education" — Grade: A (Source: Manual)
*   "Work Education" — Pending (No grade entered)

Mrs. Desai clicks the add button, records grade "B" for "Work Education", and saves, completing Sarah's evaluations.

---

## Related Screens

*   **Student Results** — The parent results tab.
*   **Template Coscholastic Components** — Where co-scholastic activities are mapped to templates.
*   **Behavioural Assessment Module** — The source system for auto-graded components.
