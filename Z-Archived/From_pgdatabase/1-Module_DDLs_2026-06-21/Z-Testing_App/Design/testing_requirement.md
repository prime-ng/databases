# Prime-AI Testing Automation App — Requirements Document

**Status:** Draft for approval
**Author:** Enterprise Architect (Claude)
**Date:** 2026-06-12
**Target Project:** `/Users/bkwork/Herd/prime_ai_testing` (new, separate Laravel project)
**Source App:** `/Users/bkwork/Herd/prime_ai`

---

## 1. Executive Summary

Prime-AI currently has **67 Dusk/PHPUnit test files** and **58 `requirements.md`** specs
scattered across `prime_ai/tests/Browser/Modules/**`, with ad-hoc per-module report folders
(`dusk-report/`, `screenshots/`, `console/`, `source/`) and one stray CSV
(`reports/library-categories-error-tracking.csv`). There is no central catalog, no run
history, no analytics, and no UI to select/run specific test cases.

This document defines requirements for **`prime_ai_testing`** — a standalone Laravel
application that:

1. **Discovers** Prime-AI's module/menu/tab hierarchy and the test cases tied to each tab.
2. Presents a **browse → select → run** UI for executing Dusk test cases (individually,
   by tab, by module, or in bulk).
3. **Records full run history** (who ran it, when, how long, pass/fail/skip counts,
   per-test results, failure screenshots).
4. Provides **analytics/reporting** over that history (trends, flaky tests, slowest tests,
   module health).
5. Supports **creating new test cases** (scaffolding files + catalog registration) as part
   of the discovery/maintenance workflow.
6. Becomes the **single home** for all testing artifacts currently scattered inside
   `prime_ai/tests/Browser/**`.

This is the requirements deliverable. Per instructions, **DDL (`testing_ddl_v1.sql`) will
only be created after this document is approved.**

---

## 2. Source Material Reviewed

| File / Folder | Purpose |
|---|---|
| `prime_ai/tests/Browser/Modules/**` | 67 `*Test.php` Dusk files + 58 `requirements.md` — current test catalog |
| `prime_ai/tests/Browser/{screenshots,console,source,reports}/` | Legacy/loose artifact dirs (mostly empty, `.gitignore` placeholders) |
| `prime_ai/tests/Browser/Modules/Library/dusk-report/{screenshots,console}` + `testdox.txt/html`, `junit.xml` | Most mature example of per-module run output — pattern to generalize |
| `prime_ai/tests/DuskTestCase.php` | Confirms: Browser screenshots/console/source paths are configurable per run; Library module already wires `dusk-report/` as its artifact root |
| `prime_ai/Modules/*` (44 module folders) | Source of truth for **Module** names |
| `2-New_Primedb/pgdatabase/1-Master_DDLs/test_runner_db.sql` | Preliminary SQLite schema: `test_runs`, `test_run_results` — baseline for `tst_test_runs` / `tst_test_run_results` |
| `AI_Brain/memory/testing-strategy.md` | Defines Unit/Feature/Dusk test types, `TenantTestCase`, naming conventions |
| `AI_Brain/memory/conventions.md` | Table-prefix & DDL conventions (soft delete, `is_active`, `_json`, etc.) |
| `AI_Brain/config/paths.md` | Path variables — `LARAVEL_REPO`, `OLD_REPO`, etc. |

### 2.1 Observed Hierarchy (example — Syllabus module)

```
Category: School Setup
 └─ Main Menu: Syllabus Mgmt.
     └─ Sub Menu: Syllabus Master   (view: /syllabus/lesson?tab=...)
         ├─ Tab: Lessons              → Modules/Syllabus/Lesson/LessonPlanningTest.php
         ├─ Tab: Topic Types          → Modules/Syllabus/TopicTypes/requirements.md (no test file yet)
         ├─ Tab: Topics               → Modules/Syllabus/Topic/
         ├─ Tab: Competency Types     → Modules/Syllabus/CompetencyType/
         ├─ Tab: Competencies         → Modules/Syllabus/Competencies/
         ├─ Tab: Topic-Competency     → Modules/Syllabus/TopicCompetency/
         ├─ Tab: Performance Cat.     → Modules/Syllabus/PerformanceCategory/
         └─ Tab: Grade Divisions Mst. → Modules/Syllabus/GradeDivisionMaster/
```

### 2.2 Observed File Patterns

- **One test file per Tab/feature**, e.g. `LessonPlanningTest.php`, `StudentEditTest.php`,
  `LibGenreCreateTest.php` — namespace `Tests\Browser\Modules\{Module}\{Feature}`.
- A file may contain **multiple `test_*` methods** (each is one selectable "test case").
- Some folders only have `requirements.md` (spec written, test not yet automated) — these
  must still appear in the catalog as **"Due for TestCase Creation"**.
- Some modules nest a `Testcases/` or `TestCases/` subfolder; others put `*Test.php`
  directly in the feature folder; naming is **not fully consistent** — discovery must be
  tolerant (recursive scan for `*Test.php` + `requirements.md`, not rigid path assumptions).
- `dusk-report/{screenshots,console}/...` filenames follow the pattern:
  `{prefix}Tests_Browser_<Namespace_With_Underscores>_<ClassName>_<test_method_name>-0.{png|log}`
  with a `failure-` prefix on failure screenshots.

---

## 3. Goals & Non-Goals

### Goals
- G1: Single catalog of all testable Module → Category → Main Menu → Sub Menu → Tab → Test
  Case relationships, kept in sync with the real `prime_ai` codebase.
- G2: UI to browse this hierarchy, multi-select test cases, and run them.
- G3: Durable run history with full execution metadata + failure screenshots.
- G4: Analytics dashboards over history (pass rate trends, flaky tests, slowest tests,
  module/tab health).
- G5: Guided creation of new test cases (scaffold file + requirements doc + catalog entry).
- G6: Migrate existing artifacts (`tests/Browser/**` test files, requirements docs,
  screenshots, reports) from `prime_ai` into `prime_ai_testing`.

### Non-Goals (Phase 1)
- NG1: Replacing PHPUnit/Dusk itself — `prime_ai_testing` **orchestrates** Dusk runs against
  `prime_ai`, it does not reimplement a test runner.
- NG2: CI/CD integration (GitHub Actions etc.) — noted as a future enhancement, not required now.
- NG3: Editing `prime_ai` application code from the testing app (only test files / requirements
  docs under `tests/` are created/edited).
- NG4: Authentication/multi-user RBAC beyond a simple "executed_by" identity (single
  developer usage initially, but schema should not preclude multi-user later).

---

## 4. Hierarchy & Discovery Model

### 4.1 Conceptual Hierarchy

```
Module (from prime_ai/Modules/*)
 └─ Category            (e.g. "School Setup", "LMS", "HR & Payroll")
     └─ Main Menu        (e.g. "Syllabus Mgmt.")
         └─ Sub Menu      (e.g. "Syllabus Master")  → maps to one View/Screen + URL
             └─ Tab        (e.g. "Lessons")          → maps to one feature folder
                 └─ Test Case  (= one test_* method inside a *Test.php file,
                                  OR a "planned" case described only in requirements.md)
```

Category / Main Menu / Sub Menu correspond to Prime-AI's **RBS menu structure**
(`AI_Brain` references `PrimeAI_RBS_Menu_Mapping_v2.0.md`). The Testing App should be able
to import/seed this menu hierarchy so Tabs can be correctly grouped, but must also allow
**manual mapping** for tabs whose folder names don't obviously match a menu entry.

### 4.2 Discovery Process ("Sync")

A **Sync** operation (button + scheduled artisan command) scans `prime_ai`:

1. **Modules** — `ls Modules/*` → upsert `tst_modules` (name, display name, is_active).
2. **Test Case Files** — recursively scan
   `prime_ai/tests/Browser/Modules/**/*Test.php` (after migration:
   `prime_ai_testing` will hold its **own copy/symlink** of these files — see §9):
   - Parse namespace → module + feature path segments.
   - Parse class name.
   - Regex-extract every `public function test_*(...)` method (+ optional `#[Test]`
     attribute / docblock summary) → one row per method in `tst_test_cases`.
3. **Requirements docs** — scan `**/requirements.md` (and `**/requirements/*.md`):
   - Link to the same Tab/feature node as a "Not Automated" test case OR as
     supplementary documentation for an existing automated case.
4. **Tab/Screen mapping** — derive Tab name from folder name (humanized), allow manual
   override of Category/Main Menu/Sub Menu/Tab labels and ordering via the UI.
5. Sync is **idempotent and additive**: re-running updates existing rows (matched by file
   path + class + method name) and marks removed items `is_active = 0` rather than deleting
   (preserve run-history FK integrity).

### 4.3 Manual Curation

Because folder names are inconsistent (`Testcases/` vs `TestCases/` vs flat, `requirements/`
vs `requirements.md`), the UI must let a user:
- Re-assign a discovered test file/case to the correct Category/Main Menu/Sub Menu/Tab.
- Mark a Tab as "out of scope" (excluded from catalog/UI but not deleted).
- Manually add a Tab/Test Case that doesn't match the folder-scan heuristics.

---

## 5. Functional Requirements

### FR-1: Module/Hierarchy Browser
- List all Modules (from sync). Selecting a Module shows its Categories → Main Menus →
  Sub Menus → Tabs tree.
- Each Tab node shows its Test Cases with: name, type (Dusk/Feature/Unit/Not Automated),
  automation status, last run result, last run date.
- Search/filter by module, tab, test name, status (passed/failed/never run/not automated).

### FR-2: Test Case Selection & Execution
- Checkbox selection at any level (Module / Sub Menu / Tab / individual test case) — selecting
  a parent selects all descendants.
- "Run Selected" button triggers execution:
  - Group selected test cases by **file** (Dusk runs at file/class granularity but can filter
    by `--filter` for specific methods).
  - Execute via `php artisan dusk --filter=...` (or `dusk:fails` for re-runs) against the
    `prime_ai` codebase, using `prime_ai`'s `.env.testing` / test DB — **never the
    production DB** (per `testing-strategy.md` Key Rule #1).
  - Stream live output to the UI (queued job + polling or websockets/SSE).
- Support "Run All" for a Module/Sub Menu/Tab, and "Re-run Failed" from a previous run.

### FR-3: Run History Capture
For every run (`tst_test_runs`), capture:
- `run_id` (unique, e.g. `YYYYMMDD_HHMMSS_<uuid>`)
- `executed_by` (user/identity who clicked Run)
- `started_at`, `finished_at`, `duration_seconds`
- `scope` (which module/tab/test cases were selected — stored as JSON + FK links)
- `exit_code`, `total`, `passed`, `failed`, `skipped`, `assertions`
- `environment` (e.g. local/CI, PHP/Chrome versions — nice-to-have)
- `raw_output` (full console output, for debugging)
- `trigger_type` (manual / scheduled / re-run)

For every individual test case within a run (`tst_test_run_results`):
- `test_case_id` (FK to catalog), `status` (passed/failed/skipped/error), `duration_seconds`,
  `assertions`, `error_message`/`error_trace` (on failure), `failure_screenshot_path`,
  `console_log_path`, `source_html_path`.

### FR-4: Failure Artifact Capture
- On failure, Dusk's `Browser::$storeScreenshotsAt` / `storeConsoleLogAt` / `storeSourceAt`
  are pointed at a **per-run** directory (e.g.
  `storage/app/test-runs/{run_id}/{screenshots,console,source}/`).
- Each `tst_test_run_results` row stores the **relative path** to its screenshot/log/source
  (nullable — only failures produce these).
- UI: clicking a failed test case shows the screenshot inline + console log + source HTML
  download + stack trace.

### FR-5: Run History & Analytics
- **History list**: paginated/filterable list of all runs (by date range, module, executed_by,
  result).
- **Run detail**: full breakdown of a run — all test cases + statuses + drill into failures.
- **Analytics dashboards**:
  - Pass-rate trend over time (overall, per Module, per Tab).
  - **Flaky test detection**: test cases whose status changes between consecutive runs
    without code change.
  - Slowest test cases / slowest modules (duration trends).
  - "Never run" / "Not automated" coverage gaps per Module/Sub Menu/Tab.
  - Last-N-runs status grid (like a mini CI dashboard) per test case.

### FR-6: Test Case Creation Workflow
- "New Test Case" wizard: pick Module → Category/Main Menu/Sub Menu/Tab (existing or new) →
  provide test class name + method name(s) + short description.
- Generates:
  - A scaffold `*Test.php` file (extends `DuskTestCase`, boilerplate `browse()` block) in the
    correct `tests/Browser/Modules/...` path.
  - An optional `requirements.md` scaffold (using the existing requirements.md format as a
    template — Feature Overview, Routes, Permissions sections).
  - A `tst_test_cases` catalog row marked `automation_status = 'draft'`.
- Does **not** attempt to write test logic — only scaffolding + catalog registration. Actual
  test implementation remains a manual/Claude-assisted dev task.

### FR-7: Additional Useful Features (Architect's additions)
- **Tagging**: tag test cases (`@smoke`, `@regression`, `@critical-path`) for quick filtered
  runs (e.g. "run smoke suite before deploy").
- **Scheduling**: optional cron-style scheduled full-suite or smoke-suite runs (future phase,
  schema should accommodate `tst_schedules` but UI may be Phase 2).
- **Comparison view**: diff two runs (what newly failed / newly passed / newly added test cases).
- **Notes/annotations**: allow a user to annotate a failed run/result (e.g. "known issue,
  ticket #123") — persisted, shown in future history views, excluded from flaky-test alerts
  if marked "known issue".
- **Module health score**: simple composite metric (pass rate + coverage + recency of last run)
  surfaced per module on a dashboard landing page.
- **Export**: CSV/JSON export of run history and analytics (continuing the precedent of
  `library-categories-error-tracking.csv`).

---

## 6. Conceptual Data Model

Building on the preliminary `test_runner_db.sql` (`test_runs`, `test_run_results`), expanded
into a full relational catalog + history schema, prefixed `tst_` (not currently used in the
table-prefix registry — confirmed available).

| Table | Purpose | Key Columns (indicative) |
|---|---|---|
| `tst_modules` | Catalog of Prime-AI modules (from `Modules/*`) | `id`, `name`, `display_name`, `is_active` |
| `tst_categories` | Top-level menu categories (e.g. School Setup, LMS) | `id`, `module_id`, `name`, `sort_order` |
| `tst_main_menus` | Main menu entries under a category | `id`, `category_id`, `name`, `sort_order` |
| `tst_sub_menus` | Sub menu entries (= one screen/view + URL) | `id`, `main_menu_id`, `name`, `route_url`, `sort_order` |
| `tst_tabs` | Tabs within a sub-menu screen, = one feature folder | `id`, `sub_menu_id`, `name`, `folder_path`, `sort_order` |
| `tst_test_cases` | Individual test case catalog | `id`, `tab_id`, `module_id`, `file_path`, `namespace`, `class_name`, `method_name`, `display_name`, `test_type` (dusk/feature/unit), `automation_status` (automated/draft/not_automated), `tags_json`, `requirements_md_path`, `is_active` |
| `tst_test_runs` | One row per "Run" click | `id`, `run_id`, `executed_by`, `scope_json`, `trigger_type`, `started_at`, `finished_at`, `duration_seconds`, `exit_code`, `total`, `passed`, `failed`, `skipped`, `assertions`, `raw_output_path` |
| `tst_test_run_results` | One row per test case per run | `id`, `run_id` (FK), `test_case_id` (FK), `status`, `duration_seconds`, `assertions`, `error_message`, `error_trace`, `screenshot_path`, `console_log_path`, `source_html_path` |
| `tst_test_case_runs_summary` *(optional materialized view/table)* | Rolling stats per test case (last status, last run at, pass rate, flaky flag) for fast dashboard queries | `test_case_id`, `last_run_id`, `last_status`, `consecutive_failures`, `pass_rate_30d`, `is_flaky` |
| `tst_run_annotations` | User notes on a run/result (known issues etc.) | `id`, `run_result_id` (FK, nullable), `run_id` (FK, nullable), `note`, `created_by`, `created_at` |
| `tst_tags` / `tst_test_case_tags` | Tagging (smoke/regression/critical) — could be `tags_json` instead if simplicity preferred | `id`, `name` / junction |
| `tst_sync_logs` | History of discovery/sync runs (what changed) | `id`, `started_at`, `finished_at`, `modules_found`, `test_cases_added`, `test_cases_removed`, `details_json` |
| `tst_schedules` *(Phase 2)* | Scheduled run definitions | `id`, `name`, `scope_json`, `cron_expression`, `is_active` |

**Conventions to follow** (per `AI_Brain/memory/conventions.md`):
- All tables: `created_at`, `updated_at`, `deleted_at` (soft delete), `is_active`.
- `created_by` FK where a "user" concept exists (simple `users` table local to
  `prime_ai_testing`, or just a free-text `executed_by` string if no auth needed in Phase 1 —
  **open question, see §10**).
- JSON columns suffixed `_json`.
- FKs named `{entity}_id`.

---

## 7. Application Architecture (prime_ai_testing)

- **Stack**: Laravel (same major version family as `prime_ai` for tooling familiarity),
  single database (no multi-tenancy needed — this is an internal tool).
- **Core components**:
  1. **Sync Service** — scans `LARAVEL_REPO` (`/Users/bkwork/Herd/prime_ai`) filesystem,
     parses PHP files (regex or `nikic/php-parser` for robustness) and Markdown requirement
     files, upserts catalog tables.
  2. **Execution Service** — builds and runs `php artisan dusk --filter=...` commands as
     **queued jobs** (Laravel Queue) against the `prime_ai` codebase (shell exec from
     `prime_ai_testing`, working directory = `prime_ai`), captures stdout/exit code, parses
     JUnit/testdox output for per-test results.
  3. **Artifact Manager** — relocates/links Dusk screenshot/console/source output into
     `storage/app/test-runs/{run_id}/...` and records paths.
  4. **Reporting/Analytics Service** — aggregation queries + scheduled jobs to refresh
     `tst_test_case_runs_summary`.
  5. **Scaffolding Service** — generates new test/requirements files (FR-6).
- **UI**: standard Laravel Blade/Livewire (or existing Prime-AI frontend stack — Vite/Tailwind)
  admin-style dashboard: Module tree (left nav) + Test Case table (center) + Run/History
  panels.
- **Cross-project execution**: since `prime_ai_testing` must run commands inside `prime_ai`,
  it needs read access to `prime_ai`'s path and **write access only under `prime_ai/tests/**`
  and `prime_ai/storage/**`** (for Dusk artifacts) — no writes to application code.

---

## 8. Non-Functional Requirements

- **NFR-1 Safety**: Execution Service must refuse to run if `prime_ai`'s `APP_ENV` /
  `.env.testing` doesn't resolve to a test database (mirrors `DuskTestCase::verifyTestEnvironment()`
  and Testing Strategy Key Rule #1 — never run against real DB).
- **NFR-2 Idempotent Sync**: re-running Sync must not duplicate catalog rows or break FK
  references in existing run history.
- **NFR-3 Performance**: catalog browsing and history list views must paginate (catalog could
  grow to hundreds of test cases; history grows unbounded).
- **NFR-4 Retention**: failure screenshots/console logs/source HTML can be large — define a
  retention policy (e.g. keep artifacts for last N runs per test case, or last X days),
  configurable.
- **NFR-5 Portability**: all `prime_ai` paths configurable (mirrors `AI_Brain/config/paths.md`
  style) — don't hardcode `/Users/bkwork/Herd/prime_ai`.
- **NFR-6 Auditability**: every run records `executed_by` and exact scope/command run, for
  reproducibility.

---

## 9. Migration Plan — Moving Existing Test Artifacts

Current state in `prime_ai/tests/Browser/`:
- `Modules/**` — 67 `*Test.php` + 58 `requirements.md` (**stay in `prime_ai`** — Dusk must
  execute them from within the `prime_ai` Laravel app; PHPUnit/Dusk cannot run test classes
  living in a different Composer project against this app's bootstrap).
- `screenshots/`, `console/`, `source/`, `reports/` (mostly empty `.gitignore` placeholders +
  1 CSV) — **artifacts only**, safe to repoint.
- `Library/dusk-report/**` — existing populated example of the artifact pattern.

**Recommendation** (resolves the apparent tension between "tests must run inside `prime_ai`"
and "user wants everything moved to `prime_ai_testing`"):

1. **Test source files (`*Test.php`, `requirements.md`) remain physically in
   `prime_ai/tests/Browser/Modules/**`** — this is a hard Dusk/Laravel constraint. The
   `prime_ai_testing` catalog **indexes** them (stores `file_path` relative to
   `LARAVEL_REPO`), it does not own/move the PHP test code.
2. **All run artifacts and history move/are newly created under `prime_ai_testing`**:
   - `prime_ai_testing/storage/app/test-runs/{run_id}/{screenshots,console,source}/`
   - The legacy `prime_ai/tests/Browser/{screenshots,console,source,reports}/` and
     `Modules/Library/dusk-report/` become **deprecated**; a one-time migration script
     copies existing artifacts (incl. `library-categories-error-tracking.csv` and Library's
     `junit.xml`/`testdox.*`) into `prime_ai_testing` storage and backfills
     `tst_test_runs`/`tst_test_run_results` rows where parseable, for historical continuity.
   - `DuskTestCase.php` in `prime_ai` is updated so `Browser::$storeScreenshotsAt` etc. point
     to a path supplied by the Execution Service (e.g. via env var / generated config) instead
     of the hardcoded `Modules/Library/dusk-report` path.
3. This keeps `prime_ai` "thin" (just runnable test code) while `prime_ai_testing` becomes the
   **sole source of truth for catalog, history, analytics, and artifacts** — matching the
   user's intent.

> ⚠️ This recommendation should be explicitly confirmed during approval — it's the one place
> where "move everything" isn't literally achievable without breaking Dusk's execution model.

---

## 10. Open Questions / Assumptions (for approval)

1. **Auth/users**: Is a simple `users` table (for `executed_by` + future RBAC) needed in
   `prime_ai_testing`, or is a free-text name/email sufficient for Phase 1? *(Assumed:
   lightweight `users` table — minimal but future-proof, matches `created_by` convention.)*
2. **Test execution transport**: confirm shell-exec (via `Symfony\Process`, same as
   `DuskTestCase` already does for ChromeDriver) from `prime_ai_testing` into `prime_ai` is
   acceptable, vs. an HTTP endpoint inside `prime_ai` that `prime_ai_testing` calls. *(Assumed:
   shell-exec, simplest for a local single-developer tool.)*
3. **Menu/Category hierarchy source**: should Category/Main Menu/Sub Menu be **seeded from**
   `PrimeAI_RBS_Menu_Mapping_v2.0.md` / `prm_menus` (Prime module), or built fresh from
   folder-scan + manual curation only? *(Assumed: folder-scan + manual curation for Phase 1;
   RBS import as enhancement.)*
4. **Database engine**: preliminary file is **SQLite**. Given Prime-AI's standard stack is
   MySQL 8 (per conventions), should `testing_ddl_v1.sql` target MySQL (consistent with rest of
   `Z-Testing_App` DDLs in this repo) or stay SQLite (matches the preliminary file, simplest
   for a local tool with no server dependency)? *(Recommendation: MySQL, for consistency with
   this repo's DDL conventions and to allow richer reporting queries — but flag for your
   decision.)*
5. **Scheduling (FR-7)**: confirm Phase 2 — should `tst_schedules` table still be included in
   v1 DDL (empty/unused) for forward compatibility, or omitted entirely until needed?

---

## 11. Phased Roadmap (indicative)

- **Phase 1**: Catalog (sync), browse/select/run UI, run history, failure screenshots, basic
  reporting.
- **Phase 2**: Analytics dashboards (flaky tests, trends, module health), tagging, run
  comparison, annotations.
- **Phase 3**: Test case creation wizard/scaffolding, scheduling, CI integration.

---

## 12. Next Step

Pending your approval of this requirements document (and resolution of §10 open questions —
particularly **#4 database engine** and **#1 users table**, which directly affect the DDL),
the next deliverable is:

`/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/1-DDL_Tenant_Modules/Z-Testing_App/DDL/testing_ddl_v1.sql`
