# Exam Summary — Business Requirements

---

## What Does This Screen Do?

The Exam Summary screen provides a unified, filterable overview of ALL exam papers across both online and offline modes. It shows a table with each paper's title, class/section/subject, mode, exam date, and three key counts: how many students were assigned, how many submitted, and how many were checked/evaluated. From this screen, users can navigate to the detailed per-student report for any paper or jump directly to the paper-checking interface.

There are two entry points for this functionality:
1. The "Exam Summary" tab within the main Exam Management page (the `masters()` method in `LmsExamController`), which shows papers of ALL modes together.
2. The Online Assessment and Offline Assessment tabs (the `assessment()` method in `LmsExamController`), which filter by mode but use the same summary table structure.

This screen generates the data that feeds into the detailed Exam Report and Student Result screens, which show per-student performance breakdowns, charts, and question-by-question analysis.

---

## Real-Life Example

During exam week, the Exam Coordinator opens the Exam Management page and clicks the "Exam Summary" tab. She sees a table showing all 45 exam papers across all classes and subjects. Title, Subject, Mode, Exam Date — each paper has three number badges: "Assigned: 60, Submitted: 55, Checked: 30." She notices that one paper has 60 assigned but only 55 submitted — 5 students haven't submitted yet. Another paper shows 60 submitted but only 30 checked, meaning the teachers haven't finished evaluation. She filters by class "Grade 10" to focus on just those papers, then clicks the "Report" button on a Mathematics paper to see each student's individual marks and performance breakdown.

Later, a subject teacher uses the "Online Assessment" tab to see only online-mode papers. She sees a paper where 40 students are assigned, 38 have submitted, and 35 have been checked. She clicks "Check" to go directly to the evaluation interface for the remaining unchecked students.

---

## How It Works

Step 1 — The user navigates to the Exam Management page. The system checks they have the `tenant.exam.viewAny` permission.

Step 2 — The user clicks the "Exam Summary" tab (or the Online Assessment / Offline Assessment tabs). An `active_tab` parameter is sent with the request.

Step 3 — The system loads all exam papers with their related exam, class, subject, and status information. It also computes three sub-query counts for each paper:
- `total_assigned`: Count of allocation records linked to the paper
- `total_submitted`: Count of attempt records with a status of SUBMITTED, EVALUATION_PENDING, EVALUATED, or RESULT_PUBLISHED
- `total_checked`: Count of attempt records with a status of EVALUATED or RESULT_PUBLISHED

Step 4 — When the "Exam Summary" tab is active, the system applies the selected filters before showing results. Filters available are:
- Class/Section: limits papers to a specific class and section
- Subject: limits to a specific subject
- Exam: limits to a specific exam
- Paper: limits to a specific paper by ID
- Paper Set: limits to papers that belong to a specific set
- Date Range: filters by the exam's start date
- Search: matches paper title, paper code, or parent exam title
- Mode: limits to ONLINE or OFFLINE only (set via hidden input based on active tab)

Step 5 — The filtered, paginated results are rendered in a table. Each row shows the paper title, paper code, parent exam title, class badge, section name, subject name, mode badge (Online/Offline + Bulk/Question Wise indicator), exam start date, and the three count badges.

Step 6 — For each paper, the user can click "Report" to open a detailed per-student performance report. They can also click "Check" to go to the evaluation interface. The "Check" button routes differently depending on the mode:
- Online mode → online paper-check interface
- Offline + Question Wise → offline question-wise paper-check interface
- Offline + Bulk/Total → offline bulk marks entry interface

Step 7 — The Report view loads a new page with:
- A header showing the paper title, class, subject, and exam name
- Four statistics cards: Total Assigned, Total Attempts, Evaluated count, Average Score percentage
- Two charts: a participation summary doughnut chart and a score distribution bar chart
- A student-wise performance table showing each student's name, admission number, class/section, submission date, attempt status badge, obtained marks, percentage, and a "View Result" button

Step 8 — The Student Result view (accessed from the Report page) shows an individual student's attempt in detail, including their score, pass/fail status, time taken, and a question-by-question breakdown organized by blueprint section.

---

## Key Features / Widgets / Tabs

- **Tab Navigation** — Three sub-tabs within the Exam tab page: "Exam Summary" (all modes), "Online Assessment" (online only), "Offline Assessment" (offline only).
- **Filter Bar** — Cascading dropdowns for Class/Section, Subject, Exam, Paper, Paper Set; date range picker with preset ranges; search input for paper title/code; Search and Reset buttons.
- **Summary Table** — Columns: Exam Title (with paper code and parent exam title), Class/Section/Subject badges, Mode badge (Online/Offline with Bulk/Question Wise indicator), Exam Date, Assigned count badge, Submitted count badge, Checked count badge, Action buttons.
- **Action Buttons** — "Report" (per-student detailed report) and "Check" (paper evaluation interface, routes vary by mode).
- **Date Range Picker** — Selects exam start date range; auto-submits the form on selection or clear.
- **Report Statistics Cards (4)** — Total Assigned students, Total Attempts (submitted), Evaluated count, Average Score percentage.
- **Report Charts** — Doughnut chart for participation summary (assigned vs submitted vs not submitted), bar chart for score distribution (score ranges with student counts).
- **Student Performance Table** — Shows each student's name, admission number, class/section, submission date, attempt status with color-coded badge, marks obtained (official or provisional), percentage (official or provisional), "View Result" button to see question-level detail.
- **Student Result Detail** — Shows result overview (score circle, pass/fail badge, attempt mode, time taken, marks), teacher feedback (for bulk offline marks), and question-by-question analysis organized by blueprint section.
- **Student Search** — On the Report page, a search field filters students by name or admission number.
- **MathJax Support** — The student result view includes MathJax for rendering mathematical content in questions.

---

## Business Rules

| # | Rule | Found In Code? |
|---|------|----------------|
| 1 | The Exam Summary tab shows papers of ALL modes; the Online/Offline tabs filter by mode | Controller `masters()` has no mode filter; `assessment()` splits by mode |
| 2 | The `total_assigned` count comes from the number of allocation records for the paper | Controller: `withCount(['allocations as total_assigned'])` |
| 3 | The `total_submitted` count counts attempts with status in: SUBMITTED, EVALUATION_PENDING, EVALUATED, RESULT_PUBLISHED | Controller line 930-932 |
| 4 | The `total_checked` count counts attempts with status in: EVALUATED, RESULT_PUBLISHED | Controller line 933-935 |
| 5 | The `total_evaluated` count is a separate count of result records | Controller line 936 |
| 6 | The "Exam Summary" tab only applies its filters when `active_tab === 'exam_summary'` | Controller line 104: `if ($request->get('active_tab') === 'exam_summary')` |
| 7 | Class/Section filter uses `class_section_id` from the filter form; it resolves the class_id from ClassSection and filters allocations by either `class_section_jnt_id` OR a combination of `class_id` + `section_id` | Controller lines 106-117 |
| 8 | Search filters by paper title, paper code, OR parent exam title (via a `like` query) | Controller lines 141-149 |
| 9 | Date range filters by the parent exam's `start_date` field, NOT the paper's date | Controller lines 132-138 |
| 10 | Pagination for the masters() method uses a custom page name `summary_page` to avoid conflicts with other paginated elements | Controller line 176: `->paginate(10, ['*'], 'summary_page')` |
| 11 | Pagination for the assessment() method uses the default page name | Controller lines 928-937 |
| 12 | The "Check" button routing for offline papers in `online_index.blade.php` uses `offline_entry_mode` field; in `offline_index.blade.php` it uses `is_ques_wise_file_upload` field | Different field names in two views for the same logical check |
| 13 | The report view calculates average score by summing percentages of all evaluated/submitted attempts and dividing by the count — it uses BOTH official result percentages AND provisional percentages from answer marks | Controller lines 2908-2923 |
| 14 | Student attempts with status NOT_STARTED or ABSENT show "--/--" for marks and "--" for percentage | View: `@else` branches in report.blade.php |
| 15 | The "View Result" button on the report page is disabled (greyed out) for students with no attempt | View: `btn btn-sm btn-light disabled` |
| 16 | The class-section list is cached for 1 hour (3600 seconds) to reduce database queries | Controller line 153-155 |
| 17 | The standalone summary tab does NOT require separate mode-specific permissions beyond `tenant.exam.viewAny` | Controller line 72: only one gate check |
| 18 | The assessment() method checks BOTH `tenant.online-assessment.view` AND `tenant.offline-assessment.view` | Controller lines 909-910 |

---

## Validation & Error Messages

| Scenario | Message | Location |
|----------|---------|----------|
| No papers found for filters | "No exams found for the selected filters." | View, `@empty` block |
| No students found in report | "No students found." | View, `@empty` block |
| Student attempt not submitted | "Attempt is not yet submitted." plus hourglass icon | `student_result.blade.php` line 29-33 |
| Student attempt pending evaluation | Warning alert: "Pending Evaluation: Final result is not yet generated. Showing provisional scores." | `student_result.blade.php` lines 35-40 |

---

## Permissions

| Permission Key | Type | Description |
|----------------|------|-------------|
| `tenant.exam.viewAny` | Gate | Required for the masters() method (Exam Summary tab) |
| `tenant.online-assessment.view` | Gate | Required for the assessment() method (Online Assessment tab) |
| `tenant.offline-assessment.view` | Gate | Required for the assessment() method (Offline Assessment tab) |
| `tenant.exam.viewAny` | Gate | Required for the report() method (Report page) |

---

## Related Screens

- **Online Assessment** — Separate tab that shows only online-mode papers with the same summary table structure and filters.
- **Offline Assessment** — Separate tab that shows only offline-mode papers with the same structure.
- **Exam Report** — Per-paper detailed report showing student-wise performance, charts, and search (accessed via "Report" button).
- **Student Result** — Per-student question-by-question breakdown (accessed via "View Result" in the report).
- **Paper Check (Online)** — Evaluation interface for online exam papers.
- **Paper Check (Bulk/Offline)** — Bulk marks entry for offline papers.
- **Paper Check (Question Wise Offline)** — Question-wise evaluation for offline papers with file uploads.
