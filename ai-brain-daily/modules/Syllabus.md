# Module: Syllabus

Append-only rollup. Newest entries at the bottom.

## 2026-10-22 — Dynamic sequential lesson ordinal calculation, route priority fix, AJAX debounce

- **Commits:** `33c160b70`, `ab72a5f6d`, `f83f756d5`
- **Files:** `Modules/Syllabus/app/Http/Controllers/LessonController.php`, `Modules/Syllabus/resources/views/lesson/create.blade.php`, `Modules/Syllabus/resources/views/lesson/js/create_js.blade.php`, `Modules/Syllabus/routes/web.php`
- **What:**
  - **Dynamic Sequential Lesson Ordinal:** Implemented dynamic sequential lesson number calculation on Lesson Create (`total lessons count + 1`) fetched via `/lesson/get-next-ordinal`.
  - **Route Priority Fix:** Resolved 302 redirect on `/lesson/get-next-ordinal` by placing the specific route before generic resource parameter patterns in `routes/web.php`.
  - **AJAX Debouncing & Continuity:** Implemented frontend debounce deduplication on subject/book changes, ensuring ordinal continuity is preserved across book selection changes and dropdown resets.
- **Verified:** `php -l` syntax check passed; Pint code style verified; route list verified; UI verified.
- **Status:** Done
- **Report:** [daily/2026-10-22.md](../daily/2026-10-22.md)

## 2026-10-23 — Book-scoped lesson ordinals, symmetrical 4+4 UI redesign, native week picker, SweetAlert2, and question type & complexity upgrades

- **Commits:** `330f70d78`, `7f04ebb81`, `e824169c0`, `fed43223d`, `99428665b`, `319b4b60d`, `940c12bec`, `e5e17b19a`, `52ec3477b`, `d67eb29f8`, `1262125a4`, `59b4a4491`, `b2733937c`
- **Files:** `Modules/Syllabus/app/Http/Controllers/LessonController.php`, `Modules/Syllabus/app/Http/Requests/LessonRequest.php`, `Modules/Syllabus/app/Http/Requests/UpdateLessonRequest.php`, `Modules/Syllabus/app/Models/Lesson.php`, `Modules/Syllabus/resources/views/lesson/create.blade.php`, `Modules/Syllabus/resources/views/lesson/edit.blade.php`, `Modules/Syllabus/resources/views/lesson/js/create_js.blade.php`, `Modules/Syllabus/resources/views/lesson/js/week-picker.blade.php`, `Modules/Syllabus/database/seeders/SlbQuestionTypesSeeder.php`, `Modules/Syllabus/app/Http/Controllers/QuestionTypeController.php`, `Modules/Syllabus/app/Http/Requests/ComplexityLevelRequest.php`, planning views
- **What:**
  - **Book-Scoped Lesson Ordinals:** Scoped lesson ordinal auto-increment and uniqueness checks by Book (`class_id + subject_id + book_id`), preventing collisions across textbooks. Preserved DB lesson numbers on edit refresh.
  - **Symmetrical 4+4 UI Redesign:** Rebalanced Lesson Create and Edit layouts into symmetrical 4+4 columns; integrated native ISO year-week picker component.
  - **Planning Views & Question Masters:** Replaced native browser alerts with SweetAlert2. Converted Question Type from dropdown to text input with status toggle switch and seeder expansion. Converted Complexity Level to numeric inputs (1-10) with dynamic badges.
  - **Active Master Scoping:** Enforced `is_active = 1` across all Lesson, Topic, Cognitive Skill, Bloom, and Question Type queries.
- **Verified:** `php -l` passed (0 syntax errors); Blade views compiled cleanly; UI tested across create and edit workflows.
- **Status:** Done
- **Report:** [daily/2026-10-23.md](../daily/2026-10-23.md)

## 2026-10-25 — SYL-03 / SYL-04 detail on syllabus progress report

- **Commit:** `2e9965984`
- **Files:** `Modules/Syllabus/resources/views/report/partials/progress.blade.php` (M, +90)
- **What:** Added unresolved-disruptions count/list (SYL-03) and topics-beyond-session count/list (SYL-04), queried from `SyllabusDisruption` and `SyllabusSchedule` with academic-session filter. All 4 syllabus rules now display on `syllabus/report?tab=syllabus_progress`.
- **Verified:** `php artisan view:cache` OK; no DB/migration change.
- **Status:** Done
- **Report:** [daily/2026-10-25.md](../daily/2026-10-25.md)
