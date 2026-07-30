# Exam Subject Comparison — Business Requirements

---

## What Does This Screen Do?

This screen lets teachers and administrators compare student performance across different subjects within a single exam. It provides summary metrics, two interactive charts (a grouped bar chart comparing average scores and pass rates per subject, and a stacked bar chart showing performance band distribution), and a detailed table listing each subject's statistics. The goal is to identify which subjects students excel at and which subjects need instructional attention.

This is a read-only report. No data is created or edited here.

---

## Real-Life Example

After the mid-term exams, the Academic Director wants to see how students performed across all subjects in the Grade 10 final exam. She selects the class "Grade 10" from the "Target Class" dropdown (optional), which automatically loads the sections for that class and lists the exams available for that class. She picks the "Mid-Term 2026" exam and clicks "Run Benchmarking." The screen shows her four summary cards: 120 students analyzed across 6 papers, a net exam average of 68%, pass consistency of 78%, and Mathematics as the leading subject. The bar chart reveals that while students score well in Mathematics (82% average), the pass rate in Science is only 55%, indicating many students barely scraped through. The stacked bar chart shows that Science has the largest "Low performers" segment. The table below confirms this with numbers: Science has only a 55% pass rate and 12 students failed.

---

## How It Works

Step 1 — The user optionally selects a "Target Class" from the first dropdown. This triggers an AJAX call that loads the sections available for that class and the list of exams for that class into their respective dropdowns.

Step 2 — Optionally, the user narrows by a specific section. If no section is chosen, all sections are included.

Step 3 — The user selects a "Comparison Exam" from the exam dropdown (required). Only exams belonging to the selected class are shown.

Step 4 — The user clicks "Run Benchmarking" to submit the form.

Step 5 — The system queries all exam results for the selected exam ID. If a date range was provided, results outside that range are excluded (though the view does not expose a date range filter in the UI).

Step 6 — The system also loads all exam papers (subjects) for the selected exam.

Step 7 — For each paper/subject, the system calculates:
- The total number of students who have results for that paper
- The average marks obtained, average percentage, highest percentage, and lowest percentage
- The count of passed and failed results (based on `result_status` field)
- The pass rate as a percentage of passed over total

Step 8 — If a paper has zero results, it is skipped entirely and does not appear in the output.

Step 9 — Each subject is classified into three performance bands:
- High performers: students scoring 75% or above
- Mid performers: students scoring between 40% and 74% (inclusive of 74%)
- Low performers: students scoring below 40%

Step 10 — Four summary metrics are calculated:
- Total unique students analyzed (count of distinct student IDs across all results)
- Total papers analyzed (count of subjects with results)
- Net exam average (average of all subject average percentages)
- Pass consistency (average of all subject pass rates)
- Leading subject (the subject name with the highest average percentage)

Step 11 — Two chart datasets are prepared. The benchmarking chart shows two bars per subject: average score percentage and pass rate percentage. The banding chart shows three stacked segments per subject: high, mid, and low performer counts.

Step 12 — The data is returned and rendered in the browser.

---

## Key Features / Widgets / Tabs

- **Filter Section** — Class dropdown (optional), Section dropdown (optional, loaded via AJAX), Exam dropdown (required, loaded via AJAX), "Run Benchmarking" button, and a reset button.
- **Summary Metric Cards (4)** — Analysed Students (count of unique students and papers), Net Exam Avg (overall average percentage), Pass Consistency (average pass rate across subjects), Leading Subject (best performing subject name).
- **Subject Benchmark Comparison Chart** — Grouped bar chart with two bars per subject: Average Score % (purple) and Pass Rate % (green). Bars are rounded, with data labels shown.
- **Performance Banding Chart** — Stacked bar chart per subject with three segments: High performers (75%+, green), Mid performers (40-74%, yellow), Low performers (<40%, red).
- **Subject Performance Comparison Table** — Columns: row number, Subject name, Max Marks, Avg Marks, Avg %, Peak %, Lowest %, Pass/Fail counts (two badges), Pass Rate (with color-coded progress bar).
- **Consolidated Benchmarking Summary** — Footer bar showing: Papers Audited count, Overall Average %, Pass Consistency %, Top Performer subject name.
- **Cascading Dropdowns** — Class selection loads sections and exams automatically via AJAX.
- **Empty State** — When no data is available, displays a message asking the user to generate the report.

---

## Business Rules

| # | Rule | Found In Code? |
|---|------|----------------|
| 1 | Class and Section filters are DISPLAYED in the UI but are NOT APPLIED by the controller when generating subject comparison data | View has `class_id` and `section_id` dropdowns; Controller only uses `exam_id` and date filters |
| 2 | The exam dropdown is required — without an exam selected, the table and charts remain empty | View: submit button triggers form; no exam means no query filtering |
| 3 | Papers with zero results are SKIPPED and do not appear in the output | Controller line 635: `if ($count === 0) continue;` |
| 4 | Pass/fail is determined by the `result_status` field matching exactly "PASS" or "FAIL" | Controller lines 637-638 |
| 5 | Average percentage per subject is computed by averaging the `percentage` field of all results for that paper | Controller line 639 |
| 6 | Pass rate is computed as `(passed / total) * 100` for each subject | Controller line 640 |
| 7 | Performance band cutoffs: High >= 75%, Mid >= 40% and < 75%, Low < 40% | Controller lines 658-660 |
| 8 | Total students count counts DISTINCT `student_id` values across all results | Controller line 664: `$results->unique('student_id')->count()` |
| 9 | Net exam average is the average of all subject average percentages, NOT the average of all individual student percentages | Controller line 667: `collect($rows)->avg('avg_pct')` |
| 10 | Pass consistency is the average of all subject pass rates | Controller line 668 |
| 11 | Leading subject is the subject with the highest `avg_pct` value | Controller line 666 |
| 12 | The pass rate progress bar color is green >= 75%, yellow >= 50%, red < 50% | View: CSS class logic in the progress bar |
| 13 | Average marks per subject uses the `avg` aggregate on `total_marks_obtained` | Controller line 645 |
| 14 | Highest and lowest percentages use the `max` and `min` aggregate functions | Controller lines 647-648 |
| 15 | No date range filter is exposed in the view, but the controller DOES accept and apply optional `date_from`/`date_to` parameters | Controller lines 608-612, 616-618 — `hasDateFilter` logic present but no UI element |
| 16 | The subject name displayed comes from the `ExamPaper` model's related `Subject` model name, or falls back to "Subject #{id}" | Controller line 643: `$paper->subject?->name ?? 'Subject '.$paper->id` |

---

## Validation & Error Messages

| Scenario | Message | Location |
|----------|---------|----------|
| No exam selected on initial load | Table shows "Generate report to visualize cross-subject success metrics." | View, `@empty` block |
| No results found for selected exam | Table shows the same empty state message | View, `@empty` block |
| AJAX load for sections/exams fails | Error logged to console only: "AJAX Load Failed for Rep-5" | View, JS error handler |

There is no server-side validation because the report is purely read-only with optional filters.

---

## Permissions

| Permission Key | Type | Description |
|----------------|------|-------------|
| `tenant.lms-exam-report.viewAny` | Gate | Required to access the Advanced Reports page (the parent page containing this tab) |
| `tenant.exam-subject-comparison.view` | Policy | Defined in `ExamSubjectComparisonPolicy` but not explicitly checked in the controller — the parent gate is sufficient |

---

## Related Screens

- **Advanced Reports (Parent)** — This screen is one of six tabs under the Advanced Reports page.
- **Student Exam History** — Another tab showing per-student exam history.
- **Exam Result Report** — Another tab showing the full result ledger with ranking.
- **LMS Activity Dashboard** — Another tab showing LMS-wide activity metrics.
