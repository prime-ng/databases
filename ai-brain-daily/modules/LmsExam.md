# Module: LmsExam

Append-only rollup. Newest entries at the bottom.

## 2026-10-25 — Exam report insight detail, pagination isolation, question overflow CSS

- **Commits:** `385e028d5`, `167564ffe`, `e9283eda2`
- **Files:**
  - `Modules/LmsExam/app/Http/Controllers/ExamAdvancedReportController.php` (M)
  - `Modules/LmsExam/resources/views/advanced-reports/index.blade.php` (M)
  - `Modules/LmsExam/resources/views/advanced-reports/partials/exam-result-report.blade.php` (M)
  - `Modules/LmsExam/resources/views/advanced-reports/partials/lms-activity-dashboard.blade.php` (M)
  - `Modules/LmsExam/resources/views/exam-grievances/index.blade.php` (M)
  - `Modules/LmsExam/resources/views/exam-grievances/partial_list.blade.php` (M)
  - `Modules/LmsExam/resources/views/paper-set-question/create.blade.php` (M)
- **What:**
  - `selected_exam` (title / end_date / is_result_published) added to exam-result data + empty-state.
  - Proctoring-violations aggregation fixed: `lms_exam_attempts` has no `exam_id`; join `lms_exam_papers` on `exam_paper_id` → `p.exam_id`.
  - "Age (days)" column added to exam grievances.
  - Pagination: unique `pageName` per report (`hw_sub_page`, `hw_perf_page`, `exam_result_page`, `student_history_page`, `subject_cmp_page`, `activity_page`) + delegated AJAX click handler so links no longer dump raw JSON.
  - Paper-set question create: MathJax / overflow / badge-overlap CSS fix.
  - Caught and fixed a Blade quoting error in `lms-activity-dashboard.blade.php`.
- **Verified:** `php -l` OK; `php artisan view:cache` OK; no DB/migration change.
- **Status:** Done
- **Report:** [daily/2026-10-25.md](../daily/2026-10-25.md)
