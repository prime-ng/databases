# Module: Library

Append-only rollup. Newest entries at the bottom.

## 2026-10-25 — LIB-01/02/06/07 last-borrowed & copies-on-shelf detail

- **Commit:** `db7ad61df`
- **Files:**
  - `Modules/Library/app/Http/Controllers/LibraryController.php` (M)
  - `Modules/Library/app/Http/Controllers/LibMemberController.php` (M)
  - `Modules/Library/app/Http/Controllers/LibCurricularAlignmentController.php` (M)
  - `Modules/Library/resources/views/lib-book-copies/index.blade.php` (M)
  - `Modules/Library/resources/views/lib-physical-book-requests/index.blade.php` (M)
  - `Modules/Library/resources/views/lib-members/index.blade.php` (M)
  - `Modules/Library/resources/views/lib-curricular-alignments/index.blade.php` (M)
- **What:**
  - Book copies: `last_borrowed_at` (max issue_date per copy) + "Last Borrowed" column.
  - Physical-book requests: "Copies on Shelf" column.
  - Members: `last_borrowed_at` + "Last Borrowed" column.
  - Curricular alignments: `borrow_count` + "Borrow Count" column (red if < 2).
- **Verified:** `php -l` OK (3 controllers); `php artisan view:cache` OK; no DB/migration change.
- **Status:** Done
- **Report:** [daily/2026-10-25.md](../daily/2026-10-25.md)
