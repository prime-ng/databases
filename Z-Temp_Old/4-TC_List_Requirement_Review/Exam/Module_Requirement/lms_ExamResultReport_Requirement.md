# Exam Result Report — Business Requirements

---

## What Does This Screen Do?

This screen provides a comprehensive analysis of student performance after an exam has been conducted and results are published. It shows pass/fail rates, grade distribution across eight grade brackets (A+ through F), class average, highest and lowest scores, and a detailed results ledger with student rankings. Teachers and administrators use this to understand how the entire class performed, identify top performers, spot at-risk students, and evaluate the overall effectiveness of the examination.

---

## Real-Life Example

The Class 12 Board Exam results have been published. Mrs. Gupta, the class teacher, opens this report, selects "Class 12 — Final Exams," and sees a dashboard showing: 120 students appeared, 95 passed (79.2% pass rate), class average is 68%, the highest score is 97%, the lowest is 18%. A donut gauge shows the pass rate visually. A bar chart breaks down how many students got A+, A, B+, B, C+, C, D, and F. Below, a detailed ledger lists every student with their marks, percentage, pass/fail status, division (I/II/III), and rank. She sees that Rohan ranked #1 with 97% (gets a trophy icon), while 5 students at the bottom failed and need remedial attention.

---

## How the Report Works

1. The system queries all `ExamResult` records matching the selected filters (exam, paper, class, section, result status).
2. It calculates summary metrics: total students, present/absent counts, pass/fail counts, pass percentage, class average, highest percentage, lowest percentage.
3. It builds grade distribution across 8 grade brackets (A+ through F).
4. Each student result is enriched with: percentage, grade, division, rank.
5. Rank is determined by sorting all results by percentage in descending order — the highest percentage gets rank #1.
6. Chart data is prepared: a radial gauge for pass rate, a bar chart for grade distribution.
7. The results ledger is paginated at 25 records per page.

---

## Filters Available

| Filter | Options | What It Does | Implemented? |
|--------|---------|-------------|--------------|
| **Select Exam** | Choose from available exams | Required — narrows results to one specific exam. Without this, all exams across all classes would appear | ✓ Implemented |
| **Paper** | All Papers or a specific subject paper | Filters by exam paper (each paper typically corresponds to a subject within the exam) | ✓ Implemented |
| **Class** | Select a class | Narrow results by class. Cascades from the exam selection | ✓ Implemented |
| **Section** | All Sections or a specific section | Further narrow results within a class | ✓ Implemented |
| **Timeline Audit** | Date range picker with presets: Today, Last 30 Days, This Month | Should filter results by creation date | **NOT IMPLEMENTED** — the date range picker is in the view but the controller method `generateExamResultData()` does not read `date_from` or `date_to` parameters at all |
| **Mode** | Both Mode, Online, Offline | Should filter by exam attempt mode (online vs offline) | **NOT IMPLEMENTED** — the mode dropdown exists in the view but the controller method does not read or apply any `mode` parameter |
| **Result Filter** | All Results, Pass, Fail, Absent | Filter by result status | ✓ Implemented — values are case-insensitive, mapped to uppercase in the query |

**CRITICAL MISSING FILTERS**: Two filter controls visible on screen have no effect on the actual data:
1. **Timeline Audit**: The date range inputs (`date_from`, `date_to`) are sent with the form but are never consumed by `generateExamResultData()`.
2. **Mode**: The `mode` parameter (Both/Online/Offline) is sent but never read. All results are returned regardless of attempt mode.

These are significant gaps — users may select these filters expecting the report to change, but nothing will happen.

---

## Widgets and Charts

### 1. Summary Metrics (5 cards)

| Card | What It Shows | How It Is Calculated |
|------|--------------|---------------------|
| **Total Students** | Total number of students who have results, with a sub-line showing "X Pres / Y Abs" | `total = count(all results)`. Present = count where status != 'ABSENT'. Absent = count where status == 'ABSENT' |
| **Pass Rate** | Pass percentage, with a sub-line showing "X Pass / Y Fail" | `(passed / total) × 100`. Passed = count where status == 'PASS'. Failed = count where status == 'FAIL' |
| **Class Avg** | Average percentage across all students | Average of all `percentage` fields from result records |
| **Peak Score** | Highest percentage achieved by any student | Maximum value of `percentage` across all results |
| **Floor Score** | Lowest percentage recorded | Minimum value of `percentage` across all results |

Each card has a colored left border and an icon:
- Total Students: Purple (users icon)
- Pass Rate: Green (checkmark icon)
- Class Avg: Blue (chart-line icon)
- Peak Score: Amber (trophy icon)
- Floor Score: Red (trend-down icon)

### 2. Result Distribution Audit (Radial Bar Gauge Chart)

- A semi-circular gauge (radial bar) starting at -90 degrees and ending at +90 degrees.
- Shows the overall pass rate percentage prominently in the center (large green text).
- The label "OVERALL PASS RATE" is displayed above the value.
- The gauge arc is a green gradient, with a light grey track behind it.
- The color does NOT dynamically change based on the pass rate — it is always green (#10b981).
- The displayed value is `(passed / total_students) × 100`, rounded to one decimal.

### 3. Grade Brackets Proliferation (Bar Chart)

- A vertical bar chart with one bar for each of the 8 grade levels, ordered from A+ to F.
- Each bar is a different color (green, lime, yellow, amber, indigo, purple, pink, red).
- The Y-axis is hidden; only the bars with their value labels on top are visible.
- The X-axis shows the grade labels (A+, A, B+, B, C+, C, D, F).
- The chart title is "STUDENT GRADE DISTRIBUTION".

**Grade Bracket Ranges** (how they map to percentage scores):

| Grade | Percentage Range | Color |
|-------|-----------------|-------|
| A+ | 90% and above | Green (#10b981) |
| A | 80% to 89.9% | Lime (#84cc16) |
| B+ | 75% to 79.9% | Yellow (#eab308) |
| B | 60% to 74.9% | Amber (#f59e0b) |
| C+ | 55% to 59.9% | Indigo (#6366f1) |
| C | 50% to 54.9% | Purple (#a855f7) |
| D | 33% to 49.9% | Pink (#ec4899) |
| F | Below 33% | Red (#ef4444) |

### 4. Grade Brackets Summary Table

A compact table above the main ledger showing the count of students in each grade bracket in a single row. The columns are:
- A+ (90%+), A (80-89%), B+ (75-79%), B (60-74%), C+ (55-59%), C (50-54%), D (33-49%), F (<33%)

Each cell displays a number (student count). This gives a quick overview without having to read the bar chart.

### 5. Exam Overall Results Ledger

The main data table — a detailed ledger with one row per student, sorted by rank (highest percentage first):

| Column | What It Shows |
|--------|--------------|
| **#** | Row number (accounts for pagination, continuing across pages) |
| **Student Identity** | Student's full name in bold, with "U-ID: [admission number]" below in grey |
| **System Roll** | Student's roll number displayed as a light badge |
| **Grand Total** | Total marks possible for this exam/paper, in grey bold text |
| **Mark Secured** | Total marks the student actually obtained, in dark bold text |
| **Efficiency %** | Percentage value with a progress bar. Bar colors: green (>=60%), blue (>=40%), red (<40%). The percentage value is displayed in bold small text |
| **Audit Status** | Green badge with "PASS" or red badge with "FAIL" (or other status). The view converts status to uppercase for display |
| **Division** | Division awarded: I (>=60%), II (>=45%), III (>=33%), or "—" (below 33%) |
| **Rank** | Student's rank. Top 3 show a yellow trophy badge (#1, #2, #3). Others show plain grey rank number |

**Division Rules**:
| Percentage | Division |
|-----------|----------|
| 60% and above | I (First Division) |
| 45% to 59.9% | II (Second Division) |
| 33% to 44.9% | III (Third Division) |
| Below 33% | — (No division) |

**Pagination**: 25 records per page. The header shows "Student Performance Matrix & Division Audit (Page X of Y)". The footer shows "Showing X to Y of Z Academic Records" with Bootstrap 4 pagination links.

---

## Business Rules & Filters

### Status Mapping
The `result_status` filter dropdown offers: "All Results" (no filter), "Pass", "Fail", "Absent". In the code, the value is converted to uppercase before querying. The database values should be 'PASS', 'FAIL', 'ABSENT' to match.

### Grade Calculation Priority
When determining a student's grade:
1. If the result record already has a `grade_obtained` value stored, that value is used.
2. If no grade is stored, it is calculated from the percentage using the grade brackets table above.

This means if the exam grading system uses a different grading scheme (e.g., custom grade boundaries), the stored grade takes precedence.

### Rank Calculation
- All results are sorted by `percentage` in descending order.
- The rank is the position in this sorted list (1-indexed).
- Tied percentages get consecutive ranks (e.g., two students with 95% get ranks 1 and 2, not a tie for rank 1).
- The "Audit Status" column shows the raw stored status; it does NOT recalculate pass/fail based on percentage. A student could have a high percentage but be marked "FAIL" if the stored status says so, or vice versa.

### Class/Section Filter Behavior
When filtering by class and/or section:
- The system looks at each student's current academic session (`StudentAcademicSession`) records to find their class/section.
- It queries the `classSection` relationship to match on `class_id` and optionally `section_id`.
- This means the student's class/section at the time of the result may differ from their current class/section. The report uses the **current** session, not the session when the exam was taken.

### Empty State
When no results match the filters, the screen shows:
- All metric cards show 0
- Pass rate chart shows 0%
- Grade distribution chart shows all grades at 0
- Grade summary table shows all zeros
- Ledger shows a placeholder: "No academic records identified for selected criteria" with a clipboard-question icon

---

## Error Scenarios

| Scenario | What Happens |
|----------|-------------|
| No exam selected | All papers dropdown is empty. No results shown. All metrics are zero |
| Selected exam has no results | Empty state with "No academic records" message |
| Class selected with no students having results | Empty state with zero metrics |
| Result has null percentage | Treated as 0 for calculations. Grade defaults to 'F'. Division defaults to '—' |
| Paper has zero total marks | Total marks shown as 0. Percentage calculation still works based on stored percentage field |
| Student has null roll_number | Shown as '-' in the ledger |
| Student has null admission_no | Shown as '-' in the U-ID field |
| All students are absent | Total = X, Present = 0, Absent = X. Pass rate = 0%. Class avg = 0% |
| All students fail | Pass rate = 0%. Grade distribution shows all F. Every student ranked. Division shows '—' |
| AJAX dependency loading for class→sections fails | Logged to console; sections dropdown stays disabled |
| AJAX dependency loading for exam→papers fails | Papers dropdown stays in loading state |

---

## Permissions

- **Required Permission**: `tenant.lms-exam-report.viewAny`
- Same permission for all six tabs on the reports page
- Both controller Gate and view-level `@can` checks are in place

---

## Related Screens

- **Student Exam History** — Individual student's performance across all exams over time, with trend charts
- **Exam Subject Comparison** — Side-by-side performance comparison across different subject papers within an exam
- **HW Performance Analysis** — Similar matrix-style report but for homework assignments
- **LMS Activity Dashboard** — High-level comparison of homework vs exam activity volume and engagement

---

## Known Gaps Between Requirements and Code

1. **Timeline Audit Filter Is Non-Functional** — The view renders a date range picker that sends `date_from` and `date_to` parameters, but `generateExamResultData()` never reads these parameters. Users who select a date range expecting filtered results will get all results regardless. This is a missing feature that needs to be implemented.

2. **Mode Filter Is Non-Functional** — The view offers "Both Mode", "Online", and "Offline" options via a `mode` parameter, but the controller method never reads this parameter. All results are returned irrespective of their attempt mode. This is a missing feature.

3. **Class/Section Uses Current Session, Not Exam Session** — The class and section filter looks up the student's current academic session to determine which class/section they belong to. If a student has changed classes since taking the exam, they will be filtered by their new class, not the class they were in when they took the exam. This could cause results to appear under the wrong class filter.

4. **Pass/Fail Relies on Stored Status, Not Percentage** — The "Audit Status" column displays whatever value is stored in `result_status` (typically 'PASS' or 'FAIL'). It does NOT recalculate pass/fail based on the percentage. If the stored status was set incorrectly during result entry, the report will reflect that error.

5. **Grade Bracket Colors in Chart Don't Match Cell Colors** — The radial gauge for pass rate always uses green regardless of the value. A better UX might use dynamic coloring (green for high pass rate, yellow for moderate, red for low).

6. **Rank Does Not Handle Ties** — If two students have the same percentage, they get consecutive ranks (1 and 2) instead of tied ranks (1 and 1). This could be misleading in cases where multiple students achieve the same score.

7. **Inconsistency in Grade Brackets** — The grade brackets displayed in the summary table and bar chart differ slightly from the `getGrade()` function in code. The `getGrade()` function uses: >=90=A+, >=80=A, >=70=B+, >=60=B, >=50=C+, >=40=C, >=33=D, <33=F. But the view's column headers say: A+ (90%+), A (80-89%), B+ (75-79%), B (60-74%), C+ (55-59%), C (50-54%), D (33-49%), F (<33%). Notice the B+ bracket in the view shows 75-79% but the code assigns B+ for >=70%. This means a student with 72% would get B+ in the code but would be expected to fall under "B (60-74%)" based on the table header. There is a mismatch between the displayed grade bracket ranges and the actual code logic.
