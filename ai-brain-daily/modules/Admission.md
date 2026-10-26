# Module: Admission

Append-only rollup. Newest entries at the bottom.

## 2026-10-21 — View page redesign, filters, media upload fixes

- **Commits:** `c79b79402`
- **Files:** 47 (Gaurav)
- **What:**
  - Admission view page design enhancements.
  - Added filters.
  - Media upload fixes.
- **Status:** Done
- **Report:** `ai-brain-daily/daily/2026-10-21.md`

## 2026-10-25 — Question-create table overflow / MathJax / badge fix

- **Commit:** `94f82233d`
- **Files:** `Modules/Admission/resources/views/admission-questions/create.blade.php` (M)
- **What:** Added `.mathjax-content`, `.question-col-details`, `.question-col-badges` CSS and scroll wrappers to search/review tables so long question text and LaTeX no longer overlap badges or break cells.
- **Verified:** `php -l` OK; browser testing pending.
- **Status:** Done
- **Report:** [daily/2026-10-25.md](../daily/2026-10-25.md)
