# Student Subject Results — Business Requirements

## What This Screen Does

The Subject Results tab displays subject-level performance details for each student across a marksheet schedule. Unlike the main Student Results tab which shows a single rolled-up score and grade, this tab breaks down raw theory marks, practical marks, homework scores, quiz scores, quest scores, internal assessment (IA) totals, weighted exam totals, final subject totals, and grades for every subject a student took.

This screen provides the detailed marks breakdown for each subject. Without it, teachers would have no way to verify how a student's final subject grade was calculated. They would have to cross-reference multiple exam sheets and class logs manually to explain a low mark, increasing the risk of calculation errors. By providing this detailed breakdown, the school automates grade calculations and ensures that subject-level results are transparent and easy to audit.

The screen appears in the following contexts:
1. **Results Hub → Subject Results tab** — An accordion list where each student row expands to reveal a table showing their subject-level marks and grades.
2. **Student Subject Result Standalone Pages** — Standalone pages used to view details, create new entries, or edit scores.

---

## Default Data Load

When the user opens the Results Hub and selects the Subject Results tab, the system runs a query in the background that retrieves student results, paginated at 10 records per page, using a specific page indicator for subject results. Once the students are loaded, the system batch-retrieves all subject result records for those students (pre-loading the subject reference) and displays them inline.

The class section filter is loaded using a shared list of classes that have computed results.

---

## When This Screen Is Used

*   **Grade Verification** — After computation, the coordinator reviews the subject-level scores and grades to verify that the formulas were applied correctly.
*   **Subject Audits** — If a student fails a subject, the teacher reviews their marks breakdown to check if theory, practical, or internal scores were missing.
*   **Manual Adjustments** — Standalone pages are used to manually record or edit subject scores for individual students.

---

## Key Fields at a Glance

**Student and Subject Binding**
*   **Student** — The student who took the subject.
*   **Subject** — The academic subject (e.g., "Mathematics").

**Marks breakdown**
*   **Theory Marks** — Raw score from the theory paper. Must be 0 or greater.
*   **Practical Marks** — Score from the practical exam. Must be 0 or greater.
*   **Homework Score** — Score from homework tasks. Must be 0 or greater.
*   **Quiz Score** — Score from quizzes. Must be 0 or greater.
*   **Quest Score** — Score from academic quests. Must be 0 or greater.
*   **IA Total** — The computed total score for internal assessments. Must be 0 or greater.
*   **Exam Weighted Total** — The final weighted score for formal exams. Must be 0 or greater.
*   **Subject Total & Max** — The final combined total score and maximum possible marks.
*   **Subject Percentage & Grade** — The percentage score and letter grade (e.g., A+) achieved.

**Status**
*   **Pass/Fail Status** — A status badge showing "Pass" or "Fail" for the subject.

---

## Business Rules and Conditions

**Unique Subject Mapping (BR-MSG-039)**
A student can only have one result record per subject in a given marksheet schedule. Duplicate records are blocked.

**Read-Only Tab View (BR-MSG-040)**
The Subject Results tab is read-only for display purposes. Creation and edits are performed on standalone pages, and deletion is not available.

**Auto-calculated Metrics (BR-MSG-041)**
All score totals, weightages, percentages, grades, and pass/fail statuses are calculated by the computation engine and stored directly. They are not computed on-the-fly.

---

## Workflow Steps

**Viewing Subject-Level Results**
It is the day after calculations. The Academic Coordinator, Mr. Sharma, opens the Results Hub and selects the Subject Results tab. He filters the list by "Grade 10 - Section B". The list of students loads. He expands student Sarah Jones's row. A table appears showing all subjects Sarah took:
*   Mathematics: Theory 78/80, Practical 18/20, IA Total 20/20, Total 116/120, Grade A+ (Pass)
*   Science: Theory 30/80, Practical 10/20, IA Total 10/20, Total 50/120, Grade D (Pass)

Mr. Sharma reviews the marks and clicks the **View** icon next to Mathematics to open the standalone detail page, showing the full raw exam marks breakdown for that subject.

---

## Example Scenario

Greenwood International School has run Term 1 computations. The coordinator, Mrs. Desai, opens the Subject Results tab for Grade 10-B. Student John Doe has:
*   English — Total: 85 / 100, Grade: A (Pass)
*   Science — Total: 34 / 100, Grade: F (Fail)

She reviews the Science breakdown to verify that his failing grade was calculated correctly based on the template rules.

---

## Related Screens

*   **Student Results** — The parent results tab.
*   **IA Marks** — Shows detailed internal assessment component scores.
*   **Student Subject Result Show Page** — Dedicated page showing the full raw exam marks breakdown.
