# Module: QuestionBank

Append-only rollup. Newest entries at the bottom.

## 2026-10-23 — `scopeActive()` enforcement across 8 tables, Competency cascading by Class & Subject, Usage Log fatal error & AJAX loop fix

- **Commits:** `e824169c0`, `fed43223d`, `99428665b`, `f57974331`, `29a09d926`, `84628520a`, `b0659b7d0`
- **Files:** `Modules/QuestionBank/app/Services/QuestionCRUDService.php`, `Modules/QuestionBank/resources/views/question-bank/js.blade.php`, `Modules/QuestionBank/app/Http/Controllers/QuestionBankReportController.php`, `Modules/QuestionBank/resources/views/report/partials/usage-log.blade.php`, `Modules/QuestionBank/app/Models/QuestionBank.php`, `Modules/QuestionBank/app/Models/QuestionMediaStore.php`, `Modules/QuestionBank/app/Models/QuestionReviewLog.php`, `Modules/QuestionBank/app/Models/QuestionStatistic.php`, `Modules/QuestionBank/app/Models/QuestionTag.php`, `Modules/QuestionBank/app/Models/QuestionUsageLog.php`, `Modules/QuestionBank/app/Models/QuestionUsageType.php`, `Modules/QuestionBank/app/Models/QuestionVersion.php`, `Modules/QuestionBank/app/Services/QuestionLookupService.php`, `Modules/QuestionBank/app/Services/QuestionReviewService.php`, `Modules/QuestionBank/app/Http/Controllers/AIQuestionGeneratorController.php`, `Modules/QuestionBank/app/Http/Controllers/QuestionBankDashboardController.php`, `Modules/QuestionBank/app/Http/Controllers/QuestionMediaStoreController.php`, `Modules/QuestionBank/app/Http/Controllers/QuestionVersionController.php`, `Modules/QuestionBank/app/Imports/QuestionImport.php`
- **What:**
  - **Active Master Scoping:** Added `scopeActive()` across all Question Bank models (`QuestionBank`, `QuestionMediaStore`, `QuestionReviewLog`, `QuestionStatistic`, `QuestionTag`, `QuestionUsageLog`, `QuestionUsageType`, `QuestionVersion`) and enforced `is_active = 1` in all controllers, services, lookups, and imports.
  - **Dynamic Competency Cascading:** Made Competency dropdown dynamically dependent on Class and Subject on both Question Bank Create and Edit views. Server-side rendering only loads competencies for active class/subject, while frontend dynamically refreshes competencies on subject selection while strictly preserving edit state.
  - **Usage Log Report Fatal Fix:** Resolved fatal `Class "Modules\QuestionBank\Http\Controllers\DB" not found` error at line 430 of `QuestionBankReportController.php` by importing `Illuminate\Support\Facades\DB`. Prevented infinite 302 AJAX redirect loops by returning JSON HTTP 500 on AJAX failures.
  - **ApexCharts Empty State Guard:** Added empty data checks in `usage-log.blade.php` to prevent JavaScript errors when rendering donut or polarArea charts with zero metrics.
- **Verified:** `php -l` passed (0 syntax errors); `view:clear` passed; tested on `question-bank/create`, `edit`, and `question-report?tab=usage-log#usage-log`.
- **Status:** Done
- **Report:** [daily/2026-10-23.md](../daily/2026-10-23.md)
