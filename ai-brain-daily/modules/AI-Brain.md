# Module: AI Brain

Append-only rollup. Newest entries at the bottom.

## 2026-10-21 — Activity calendar page

- **Files (outside repo):** `index.html`, `build.php`, `data.js`
- **What:** Self-contained calendar UI for `/home/shailesh/shailesh/ai-brain-daily`:
  - month calendar with per-day commit / journal / report counts and activity shading;
  - click a day → all commits (hash, author, time, file table with status and +/-), journal entries and the day report;
  - filters: free-text (message, author, file path, task, module), author/agent, module, and type chips (commits/journal/reports); default = all;
  - "Show whole month" mode, month navigation, today shortcut, copy-commit-hash.
- **Data:** `build.php` reads only the current branch (`git log HEAD`) plus `live/` journals and `daily/` reports, then writes `data.js`.
- **Verification:** `php build.php` → 6,512 commits, 7 journal entries, 1 report, 91,506 file rows (11.0 MB); headless Chrome render checked with screenshots.
- **Status:** Done
- **Report:** `ai-brain-daily/daily/2026-10-20.md` (previous day, backfilled)

## 2026-10-21 — PDF data import + pagination + charts page

- **Files (outside repo):** `import-team.php`, `charts.html`, `index.html`, `build.php`, `data/team.json`, `data/pdf/`, `data.js`, `charts-data.js`
- **What:**
  - `import-team.php` parses 4 PDFs with `pdftotext -bbox-layout` coordinates (normal `-layout` text is column-shifted) and keeps only Shailesh: attendance 31 rows, September work 28, October work 7, gurukul 50.
  - Calendar day cards now show attendance/work/gurukul records next to commits; blank attendance rows are hidden from badges and counts.
  - Commit lists paginate (8/day, 6 day-groups/month) and show commit descriptions when present.
  - `charts.html` adds KPI cards, 10 inline-SVG charts (commits/month, churn, authors, modules, 45-day daily commits, attendance hours + donut, work/month + status, personal log/month + status, top categories), progress bars, a searchable/paginated work-log table and a source-PDF table.
- **Data:** `build.php` emits `team` plus `charts-data.js`: 6,512 commits, 91,506 file rows, 348 daily buckets, 17 authors, 183 modules, 35 work entries, 50 gurukul entries.
- **Verification:** `php import-team.php` and `php build.php` both exit 0 with the counts above; headless Chrome screenshots of the calendar and charts page; `--dump-dom` confirms `2026-10-19` has no PDF badge and shows `20 commits · 0 PDF`.
- **Status:** Done
- **Report:** `ai-brain-daily/live/2026-10-21/opencode.md` (entry `09:24`)

## 2026-10-26 — Backfilled 2026-10-25 evening closeout

- **Files (outside repo):** `daily/2026-10-25.md` (A), `live/2026-10-26/opencode.md` (A), `modules/{Transport,Vendor,Syllabus,LmsQuiz,PrimeCore,Admission}.md` (M), `modules/{LmsExam,LmsHomework,LmsQuests,Library,Ptm}.md` (A), `modules/00-INDEX.md` (M), `00-INDEX.md` (M)
- **What:** Ran the missing 2026-10-25 closeout: read both journals (38 entries), verified 11 commits / 44 unique files with `git log --name-status --numstat`, reconciled all 44 files, wrote the daily report (PASS), created 5 new module rollups and appended 6 existing ones, added the day row to the master index.
- **Verification:** `git status --short` clean; `git log --since/--until` counts; every file in the register maps to a journal block; no fabricated changes.
- **Status:** Done
- **Report:** [daily/2026-10-25.md](../daily/2026-10-25.md)
