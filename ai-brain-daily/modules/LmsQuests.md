# Module: LmsQuests

Append-only rollup. Newest entries at the bottom.

## 2026-10-25 — Quest question create overflow / MathJax / badge fix

- **Commit:** `e9283eda2`
- **Files:** `Modules/LmsQuests/resources/views/quest-question/create.blade.php` (M)
- **What:** Added `.mathjax-content`, `.question-col-details`, `.question-col-badges` CSS and MathJax scroll wrappers to the search/review tables and JS render loops, fixing question-text overlap with badges and LaTeX overflow.
- **Verified:** `php -l` OK; `git diff` verified; browser testing pending.
- **Status:** Done
- **Report:** [daily/2026-10-25.md](../daily/2026-10-25.md)
