# Student Exam History — Business Requirements

---

## What Does This Screen Do?

This screen lets teachers and administrators pull up a complete academic report card for any individual student. It is a read-only dashboard that shows the student's profile picture and basic info, five key performance metrics, two interactive charts (a progress trend line and a subject competency radar), and a detailed table listing every exam the student has ever taken with marks, percentages, grades, and pass/fail results.

No data is created, edited, or deleted on this screen.

---

## Real-Life Example

Imagine a parent-teacher meeting where a mother wants to see how her son Rohan has been performing across all exams this term. The teacher selects Rohan's class from a dropdown, which automatically populates a student list. She picks Rohan, optionally sets a date range, and clicks "Retrieve." Instantly she sees Rohan's photo, his average score, his best subject, five summary cards (how many exams he took, his average percentage, how many he passed, his highest score, and his strongest subject), a line chart comparing his scores against the class average over time, a radar chart showing his strengths across subjects, and a full table with every exam result. She can see at a glance that Rohan excels in Mathematics but needs help in Science.

---

## How It Works

Step 1 — The user selects a class from the "Select Class" dropdown. This triggers an AJAX call that fetches only the students belonging to that class and populates the "Identify Student" dropdown.

Step 2 — The user selects a specific student from the "Identify Student" dropdown (required). Without a student, no data is shown.

Step 3 — Optionally, the user picks a date range using the "Timeline Range" date picker. If no range is chosen, all available history is shown.

Step 4 — The user clicks "Retrieve" to submit the form.

Step 5 — The system looks up the student's current academic session (the active class, section, and roll number). If no student was selected (unusual case), it falls back to the most recently active student session in the system.

Step 6 — The system queries all exam results for that student, loading the related exam details and subject information for each result. If a date range was provided, only results within that range are included.

Step 7 — For each exam result, the system calculates the class average by looking up all other students who took the same exam and paper. This allows the progress chart to compare the student against their peers.

Step 8 — Five metrics are calculated: total number of unique exams attempted, the average percentage across all attempts, the count of passed results, the single highest percentage achieved, and the subject with the highest average score across all attempts.

Step 9 — Two chart datasets are built. The progress trend chart has two lines: the student's percentage (solid purple) and the class average percentage (dashed grey) plotted across each exam in chronological order. The radar chart shows the student's average score percentage in each subject.

Step 10 — The profile banner is assembled with the student's photo (or a fallback avatar showing initials), name, class, section, roll number, average score, and top subject.

Step 11 — All data is returned to the browser and rendered on the page.

---

## Key Features / Widgets / Tabs

- **Profile Banner** — Shows student photo, name, class/section, roll number, average score percentage, and top subject name in a styled header card.
- **Summary Metric Cards (5)** — Unit Audits (total exams attempted), Academic Avg (average percentage), Success Units (number of passes), Peak Score (highest percentage), Strong Suit (best subject name).
- **Benchmarked Progress Trend Chart** — Line chart with the student's percentage as a solid purple line and the class average as a dashed grey line, plotted across exams in chronological order. Hover tooltips and markers are enabled.
- **Subject Competency Hexagon (Radar/Polar Chart)** — Polar area chart showing the student's average percentage per subject, with color-coded segments.
- **Historical Performance Ledger** — Table listing every exam result with columns: Date, Exam/Assessment Title, Subject Area, Secured/Max marks, Efficiency percentage with a color-coded progress bar, Result (Pass/Fail badge), Division (class average percentage), and Grade badge.
- **Cumulative Academic Summary Bar** — Shows at the bottom when data exists: total exam row count, a placeholder for rank average, and the overall average percentage as "Profile Health."
- **Reset Button** — Clears all filters and reloads the page in its default state.
- **Student Lookup via AJAX** — Selecting a class dynamically loads that class's students without page refresh.

---

## Business Rules

| # | Rule | Found In Code? |
|---|------|----------------|
| 1 | Selecting a class is required before students can be chosen | View: class dropdown onChange triggers AJAX load of students |
| 2 | Student lookup is done by querying `Student` model where `is_active = 1` and they have a current academic session in the selected class | Controller: `generateStudentExamHistoryData` + index method |
| 3 | If no `student_id` is provided in the request, the system uses the most recently updated active student session in the entire system | Controller line 511-516: `latest()->first()` |
| 4 | If no active student session exists at all, the screen shows placeholder data — name "—", class "—", empty rows, empty charts | Controller lines 518-525: early return with default values |
| 5 | Date range filters apply to the `created_at` timestamp of the exam result record, NOT to the exam date | Controller line 529-530: `whereDate('created_at', ...)` |
| 6 | Class average for each exam row is calculated by averaging the percentages of ALL students who took the same exam AND the same paper | Controller line 541-543: `ExamResult::where('exam_id', ...)->where('exam_paper_id', ...)->avg('percentage')` |
| 7 | Total exams count (`total_exams`) counts unique exam IDs, not individual exam results | Controller line 570: `$results->unique('exam_id')->count()` |
| 8 | Pass count counts results where `result_status` equals exactly "PASS" (uppercase) | Controller line 572: `$results->where('result_status', 'PASS')->count()` |
| 9 | Best subject is determined by averaging percentages per subject name and picking the highest average | Controller line 574: map scores by subject name, average each, sort descending, get first key |
| 10 | The efficiency progress bar color is green for >= 75%, blue for >= 40%, red for below 40% | View: hardcoded CSS classes in the progress bar |
| 11 | The result badge shows PASS in green and anything else (including FAIL, ABSENT, N/A) in red | View: status badge logic checks for 'PASS' only |
| 12 | Student photo falls back to UI Avatars API with initials if no photo URL exists | Controller line 597: ternary with `photo_url` ?? avatar URL |
| 13 | The bottom summary bar shows rank average as "Global Rank Avg" but the controller does NOT calculate this field — it always shows a dash | View: `$studentExamHistoryData['metrics']['rank_avg'] ?? '-'` — field never set in controller |
| 14 | The profile section "Avg Score" and metric card "Academic Avg" both use the same `avg_pct` value | View and controller share `$m['avg_pct']` |
| 15 | The system does NOT show any data for students who have no exam results; the table will display an empty state message | View: `@forelse` with `@empty` block |
| 16 | Editing or creating data is not allowed — no form inputs, no save buttons | No POST/PUT/DELETE routes for this feature |

---

## Validation & Error Messages

| Scenario | Message | Location |
|----------|---------|----------|
| No student session found | Placeholder data with "—" labels shown; no error message displayed | Controller, early return |
| No exam results for student | "No assessment records identified for this student profile." | View, `@empty` block |
| AJAX student load fails | Error logged to console only: "AJAX Load Failed for Student Lookup" | View, JS error handler |

There is no server-side validation for this screen because it is purely read-only with optional filters.

---

## Permissions

| Permission Key | Type | Description |
|----------------|------|-------------|
| `tenant.lms-exam-report.viewAny` | Gate | Required to access the Advanced Reports page (the parent page of this tab) |
| `tenant.student-exam-history.view` | Policy | Defined in `StudentExamHistoryPolicy` but NOT checked in the controller — the parent gate is sufficient |

The screen does not have its own explicit gate check in the controller method; it relies on the parent page gate (`tenant.lms-exam-report.viewAny`) applied in the `index()` method of `ExamAdvancedReportController`.

---

## Related Screens

- **Advanced Reports (Parent)** — This screen is one of six tabs under the Advanced Reports page (`lms-exam.exam-advanced-reports.index`).
- **LMS Activity Dashboard** — Another tab in the same report page showing activity data.
- **Exam Result Report** — Another tab showing aggregated exam result data for analysis.
- **Homework Submission Tracker** — Another tab in the same page for homework tracking.
- **Student Profile** — The student data originates from the student profile module.
