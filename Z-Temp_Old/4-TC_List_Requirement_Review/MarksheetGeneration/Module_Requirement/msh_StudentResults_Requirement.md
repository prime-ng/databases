# Student Results — Business Requirements

## What This Screen Does

The Student Results screen is the primary interface for viewing computed report card outcomes at the student level. Each row represents a single student's overall academic performance for a marksheet schedule — showing their grand total score, overall percentage, letter grade, division, class rank, and promotion status.

This screen also serves as the control hub for results publication. Authorized users can withhold a student's result (blocking it from publication with a mandatory reason), declare a result (finalizing it for student/parent view), export the results summary to Excel, open a print preview of the report card, or generate a PDF using the browser-based print engine. Without this screen, the school would have no way to verify overall student performance before report card distribution. Coordinators would have to manually review grades, risking mistakes and delays in publishing report cards.

The screen appears in the following contexts:
1. **Results Hub → Student Results tab** — Displays a paginated table of computed student results with filters for class section and student search.
2. **Student Result Details Page (Show Page)** — A dedicated detail page displaying a student's full subject-wise scores, co-scholastic grades, and attendance.

---

## Default Data Load

When the user opens the Results Hub, the Student Results tab loads by default. The system runs a query in the background that retrieves student results, paginated at 15 records per page, using a specific page indicator for student results. The query pre-loads student profiles and class section mappings.

If a class section is selected, the results are sorted by Grand Total descending (displaying top-ranked students first); otherwise, they are grouped by class section and sorted by grand total. A dropdown list of all class sections with computed results is loaded for filtering.

---

## When This Screen Is Used

*   **Review Before Publication** — After computation, the coordinator reviews student-level scores, percentages, and ranks to verify calculation accuracy.
*   **Result Gating (Withholding)** — If a student has pending fees or library books, the admin withholds their result, blocking it from publication.
*   **Official Result Declaration** — Once results are verified, the coordinator declares the results to make them visible to parents.
*   **Print and Distribution** — The admin prints formatted report cards or downloads them as PDFs for distribution.

---

## Key Fields at a Glance

**Student Identity and Rank**
*   **Student** — The student's name and admission number.
*   **Class Section** — The class section they belong to.
*   **Rank** — The student's rank within their section.

**Performance Metrics**
*   **Grand Total** — The sum of all marks achieved out of the maximum possible.
*   **Percentage** — The overall percentage score.
*   **Grade & Division** — The letter grade and division (e.g., First Division) achieved.
*   **Promotion Status** — Mapped as "Promoted" or "Detained".

**Workflow Status**
*   **Workflow Status** — Draft, Computed, Published, or Withheld.
*   **Withheld Details** — The Withheld Reason, along with the timestamp and user who withheld the result.
*   **Declaration Details** — The declaration timestamp and user who declared the result.

---

## Business Rules and Conditions

**Unique Student Result (BR-MSG-035)**
A student can only have one result record per marksheet schedule.

**Workflow State Transitions (BR-MSG-036)**
Results follow a strict workflow: Draft ➔ Computed ➔ Published. 
*   A result can be transitioned to **Withheld** from any state.
*   A withheld result can only be released and transitioned to Published via the **Declare** action.
*   Withholding a result requires a mandatory Withheld Reason.

**Direct Deletion (BR-MSG-037)**
Deleting a student result removes it directly from the database. Soft-delete is not supported for this entity.

**Browser-Side PDF Generation (BR-MSG-038)**
To preserve formatting and signatures, PDF generation is executed on the browser side using a browser-based PDF converter, rather than server-side rendering.

---

## Workflow Steps

**Withholding and Declaring a Result**
It is the day before report card distribution. The Examination Coordinator, Mr. Sharma, opens the Results Hub and filters the list by "Grade 10 - Section A". The list of students loads. He locates student Sarah Jones, who has a pending library fee. Mr. Sharma clicks the Withhold button on her row, enters the reason: _Pending library return fee of $5_, and clicks Save. The system updates the status to Withheld and displays a withheld badge.

Once Sarah clears her fee, Mr. Sharma locates her row in the list, clicks **Declare**, and saves. The system updates her status to Published, sets the declaration timestamp, and makes her report card available.

**Printing a Report Card**
Mr. Sharma clicks the **Print** icon on Sarah's row. A new tab opens showing a formatted print preview of her report card. He clicks **PDF** to download a copy. The browser-based print engine compiles the page and downloads the PDF directly to his computer.

---

## Example Scenario

Greenwood International School is declaring Term 1 results. The coordinator, Mrs. Desai, opens the Student Results tab and reviews the ranks. Student John Doe has:
*   Grand Total: 485 / 500 (97%)
*   Grade: A+, Rank: 1 (Section A)
*   Promotion Status: Promoted

She clicks **Declare** to publish his results. Once published, she prints his report card for distribution.

---

## Related Screens

*   **Subject Results** — Shows subject-wise breakdown.
*   **IA Marks** — Shows internal assessment component scores.
*   **Coscholastic Results** — Shows non-academic grades.
*   **Marksheet Schedules** — The schedule that generated these results.
