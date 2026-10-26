# Module: LmsQuiz

Append-only rollup. Newest entries at the bottom.

## 2026-10-22 — Report seeder 30-day window backfill & report controller cross-class scoping

- **Commits:** `6ab7775a4`, `e21989c8d`, `a3496c0d9`, `6ec61fba3`
- **Files:** `Modules/LmsQuiz/database/seeders/LmsReportsFullDemoSeeder.php`, `Modules/LmsQuiz/app/Http/Controllers/LmsQuizReportController.php`
- **What:**
  - **30-Day Attempt Seeder Backfill:** Expanded attempt timestamp generation in `LmsReportsFullDemoSeeder` to cover the full preceding 30 days instead of only the last 7 days, aligning with the default 30-day reporting window.
  - **Reports Cross-Class Scoping:** Cleaned up `LmsQuizReportController` Current Class and Student Summary reports for proper class scoping and data integrity.
- **Verified:** `php -l` passed; Pint verified; `php artisan db:seed --class="Modules\LmsQuiz\Database\Seeders\LmsReportsFullDemoSeeder"` seeded successfully.
- **Status:** Done
- **Report:** [daily/2026-10-22.md](../daily/2026-10-22.md)

## 2026-10-23 — `scopeActive()` implementation across 12 LMS models, report queries & `total_questions >= 1` validation

- **Commits:** `e824169c0`, `fed43223d`, `99428665b`, `f57974331`, `29a09d926`, `c9343157d`
- **Files:** `Modules/LmsQuiz/app/Models/AssessmentType.php`, `Modules/LmsQuiz/app/Models/DifficultyDistributionConfig.php`, `Modules/LmsQuiz/app/Models/DifficultyDistributionDetail.php`, `Modules/LmsQuiz/app/Models/QuizAllocationDetail.php`, `Modules/LmsQuiz/app/Models/Quiz.php`, `Modules/LmsQuiz/app/Http/Controllers/LmsQuizReportController.php`, `Modules/LmsQuiz/app/Http/Controllers/LmsQuizController.php`, `Modules/LmsQuiz/app/Http/Controllers/QuizAllocationController.php`, `Modules/LmsQuiz/app/Http/Controllers/QuizQuestionController.php`, `Modules/LmsQuiz/app/Http/Requests/QuizRequest.php`, `Modules/LmsQuiz/resources/views/quiz/create.blade.php`, `Modules/LmsQuiz/resources/views/quiz/edit.blade.php`
- **What:**
  - **`scopeActive()` Model Scoping:** Added standard `scopeActive()` to `AssessmentType`, `DifficultyDistributionConfig`, `DifficultyDistributionDetail`, and `QuizAllocationDetail`.
  - **Query Enforcement:** Enforced `is_active = 1` across all Quiz reports, allocation controllers, question queries, and remedial quiz generation.
  - **Strict Validation:** Added server-side `min:1` validation rule on `total_questions` and frontend zero/negative blocker to prevent empty or invalid quiz allocations.
- **Verified:** `php -l` passed (0 syntax errors); `view:clear` passed; allocation workflows tested.
- **Status:** Done
- **Report:** [daily/2026-10-23.md](../daily/2026-10-23.md)

## 2026-10-25 — LMS-09 quizzes-set + LMS-12 skip rate, teacher filter fix, question overflow CSS

- **Commits:** `3d442c558`, `db7ad61df`, `e9283eda2`
- **Files:** `Modules/LmsQuiz/app/Http/Controllers/LmsQuizReportController.php` (M), `Modules/LmsQuiz/resources/views/reports/partials/teacher-monthly.blade.php` (M), `Modules/LmsQuiz/resources/views/reports/partials/class-performance.blade.php` (M), `Modules/LmsQuiz/resources/views/quiz-question/create.blade.php` (M)
- **What:**
  - Teacher-monthly KPI strip: Quizzes Set (Assigned), Attempted, Skip Rate, Subjects.
  - Class-performance skip-rate strip (Allocated/Attempted/Skipped/Skip Rate) from `lms_quiz_allocation_detail` + `lms_quiz_allocations` + `lms_quiz_quest_attempts`.
  - Teacher filter card moved into the `charts` section so it renders in AJAX tab loads.
  - Question-create table overflow / MathJax / badge-overlap CSS fix.
- **Verified:** `php -l` OK; `php artisan view:cache` OK; no DB/migration change.
- **Status:** Done
- **Report:** [daily/2026-10-25.md](../daily/2026-10-25.md)
