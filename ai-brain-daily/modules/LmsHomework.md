# Module: LmsHomework

Append-only rollup. Newest entries at the bottom.

## 2026-10-25 — LMS-07 pending grading / pending days visibility

- **Commits:** `385e028d5`, `167564ffe`, `3d442c558`
- **Files:**
  - `Modules/LmsHomework/app/Http/Controllers/LmsHomeworkController.php` (M)
  - `Modules/LmsHomework/app/Http/Controllers/HomeworkReportController.php` (M)
  - `Modules/LmsHomework/resources/views/submission/index.blade.php` (M)
  - `Modules/LmsHomework/resources/views/summary/index.blade.php` (M)
  - `Modules/LmsHomework/resources/views/report/partials/submission-tracker.blade.php` (M)
- **What:**
  - Submission list: "Pending Days" column (days since `submitted_at` for non-graded rows).
  - Summary: `# Pending` and `Oldest Pending` columns via correlated `oldest_pending_at` subquery + export columns.
  - Submission-tracker report: `graded` / `pending_graded` aggregates and columns.
- **Verified:** `php -l` OK; `php artisan view:cache` OK; no DB/migration change.
- **Status:** Done
- **Report:** [daily/2026-10-25.md](../daily/2026-10-25.md)
