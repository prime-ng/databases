# Prime-AI Testing Automation App — Requirements Document (v3)

**Status:** Draft for approval
**Author:** Enterprise Architect (Claude)
**Date:** 2026-06-21
**Supersedes:** `testing_requirement_v2.md`
**Target Project:** `/Users/bkwork/Herd/prime_testing` (standalone Laravel app)
**Source App:** `/Users/bkwork/Herd/prime_ai`
**Companion DDL:** `testing_ddl_v7.sql` (supersedes `testing_ddl_v6.sql`)

---

## 0. What's New in v3

v1 established the **catalog → select → run → history → analytics → test-case-creation** lifecycle (FR-1 to FR-7).

v2 added a **continuous-enhancement lifecycle**: test case requirements backlog (FR-8), bug tracking & developer assignment (FR-9), automated bug-fix verification loop (FR-10), app settings (FR-11), and audit trails / dashboards (FR-12).

v3 adds a **distributed multi-developer execution model**:

1. **FR-13 — Multi-Developer Distributed Execution Model**: multiple developers run the same tests on their own localhost machines; the app must attribute every action to an individual user.
2. **FR-14 — Composite Primary Key Strategy**: all transaction tables adopt a composite PK `(id, user_code)` so records from multiple machines can be merged into a central database without ID collisions.
3. **FR-15 — Central Data Aggregation & Import**: a mechanism for Brijesh to collect all developers' test data into a single central database for team-wide analysis.
4. **FR-16 — System-Wide Audit Log**: every write operation across all tables is recorded in `tst_audit_logs` for full accountability.
5. **FR-17 — Regression Detection & Code Quality Insights**: surface tests that previously passed and now fail, identifying fragile code areas and developer patterns that introduce regressions.
6. **FR-18 — Enhanced Environment & Device Capture**: capture hostname, PHP version, browser version, OS, and other environment details per run to separate environment failures from code failures.
7. **FR-19 — Test Coverage Matrix (Cross-User Comparison)**: show which tests each developer ran, compare pass/fail rates across users for the same test case to detect environment-specific failures.
8. **FR-20 — Data Export/Import Mechanism**: structured export bundles from each developer's machine, with a conflict-safe import process for the central system.

### 0.1 Schema Bug Fix (v6 → v7)

In `testing_ddl_v6.sql`, all `_by` columns (`created_by`, `executed_by`, `assigned_by`, `fixed_by`, `closed_by`, `changed_by`, `completed_by`, `requested_by`, `assigned_to`) were defined as `INT UNSIGNED` referencing `tst_users(id)`. However, `tst_users` has **no `id` column** — its primary key is `code VARCHAR(5)`. Every FK referencing `tst_users` must be `VARCHAR(5)` referencing `tst_users(code)`. This is corrected in v7.

### 0.2 Hierarchy Model (unchanged from v2 §0.1)

```
Module → Category → Main Menu → [Sub Menu (optional)] → Tab → Test Case
```

Tab may attach directly to a Main Menu when no Sub Menu level exists (`tst_tabs.sub_menu_id` is nullable).

---

## 1. Executive Summary

Prime-AI currently has **67 Dusk/PHPUnit test files** and **58 `requirements.md`** specs scattered across `prime_ai/tests/Browser/Modules/**`. There is no central catalog, no run history, no analytics, and no UI to select/run specific test cases.

`prime_testing` is a standalone Laravel application that:

1. **Discovers** Prime-AI's module/menu/tab hierarchy and the test cases tied to each tab.
2. Presents a **browse → select → run** UI for executing Dusk test cases (individually, by tab, by module, or in bulk).
3. **Records full run history** with execution metadata, failure screenshots, and environment details per developer.
4. Provides **analytics/reporting** over history (trends, flaky tests, slowest tests, module health).
5. Supports **creating new test cases** as part of the discovery/maintenance workflow.
6. **(v2)** Tracks a **continuous backlog of test-case requirements** and runs a **closed-loop bug-fix → re-test → re-assign cycle**.
7. **(v3)** Operates as a **distributed multi-developer tool** where each developer runs it locally, and all data can be **aggregated into a central system** without ID collisions.

---

## 2. Source Material Reviewed

| File / Folder | Purpose |
|---|---|
| `prime_ai/tests/Browser/Modules/**` | 67 `*Test.php` Dusk files + 58 `requirements.md` — current test catalog |
| `prime_ai/Modules/*` (44 module folders) | Source of truth for Module names |
| `testing_ddl_v6.sql` | Current schema — basis for v7 |
| `testing_requirement_v2.md` | Prior requirements — all retained in v3 |
| `AI_Brain/memory/testing-strategy.md` | Unit/Feature/Dusk types, `TenantTestCase`, naming conventions |
| `AI_Brain/memory/conventions.md` | Table-prefix & DDL conventions |

---

## 3. Goals & Non-Goals

### Goals (v1 + v2, retained)

- G1: Single catalog of all testable Module → Category → Main Menu → [Sub Menu] → Tab → Test Case relationships.
- G2: UI to browse hierarchy, multi-select test cases, and run them.
- G3: Durable run history with full execution metadata + failure screenshots.
- G4: Analytics dashboards over history (pass rate trends, flaky tests, slowest tests, module/tab health).
- G5: Guided creation of new test cases (scaffold file + requirements doc + catalog entry).
- G6: Migrate existing artifacts from `prime_ai/tests/Browser/**` into `prime_testing`.
- G7: Living backlog of test-case requirements as Prime-AI evolves.
- G8: Every test failure becomes a tracked bug with developer assignment.
- G9: Closed-loop — "Fixed" bug triggers scoped re-run; bug only closes when scope is 100% green.

### Goals (v3, new)

- G10: Support **multiple developers running tests simultaneously on their own machines**, with every action attributed to an individual user by `user_code`.
- G11: Allow **central aggregation** of all developer test data into one database for team-wide analysis, without ID duplication or data loss.
- G12: **Detect regressions** — tests that passed in earlier runs now failing — and surface them as a code quality signal.
- G13: Provide a **cross-user coverage matrix** showing which developer tested which screen and with what result, to identify environment-specific failures vs. real bugs.
- G14: Maintain **complete audit accountability** — every write operation is logged with actor, timestamp, before/after values.

### Non-Goals (unchanged from v1)

- NG1: Replacing PHPUnit/Dusk itself.
- NG2: CI/CD integration (future enhancement).
- NG3: Editing `prime_ai` application code from the testing app.

---

## 4. Hierarchy & Discovery Model (unchanged from v2)

See `testing_requirement_v2.md` §4. No new discovery logic in v3 — multi-user operation does not change how catalog sync works. Recommendation: catalog sync should be **triggered manually by each developer** (not auto-triggered on startup) to avoid catalog drift across machines with different Prime-AI code states.

---

## 5. Functional Requirements (v1, retained)

All FR-1 through FR-7 are unchanged. Refer to `testing_requirement_v2.md` §5 for full descriptions. Key points:

- **FR-1**: Module/Hierarchy Browser
- **FR-2**: Test Case Selection & Execution (queued, via `php artisan dusk --filter=...`)
- **FR-3**: Run History Capture (`tst_test_runs` + `tst_test_run_results`)
- **FR-4**: Failure Artifact Capture (screenshots, console logs, HTML source)
- **FR-5**: Run History & Analytics
- **FR-6**: Test Case Creation Workflow (scaffold wizard)
- **FR-7**: Tagging, scheduling, run comparison, annotations, export

---

## 6. v2 Functional Requirements (retained)

All FR-8 through FR-12 are unchanged. Refer to `testing_requirement_v2.md` §13 for full descriptions:

- **FR-8**: Test Case Requirements Backlog
- **FR-9**: Bug Tracking & Developer Assignment
- **FR-10**: Automated Bug-Fix Verification Loop (Screen Re-test)
- **FR-11**: App Settings (`tst_app_settings` key/value store)
- **FR-12**: Bug status audit trail, retest cycle history, "My Work" dashboards, reopen-count leaderboard

---

## 7. New Requirements (v3)

### FR-13 — Multi-Developer Distributed Execution Model

**Problem Statement:**

The app will be installed and run as a **localhost application on every developer's and tester's machine**. More than one developer can execute test cases for the same Module/Screen simultaneously on their respective machines. Each instance is independent — there is no shared database.

**Requirements:**

- Every action in the app is attributed to the **logged-in user** via their `user_code` (e.g. `brij`, `tarun`, `shail`, `samer`, `gaurav`).
- A special system user `sys` (code = `'sys'`, `is_system = 1`) is pre-seeded for auto-triggered operations (Auto_Retest runs, system-generated bug creation).
- `user_code` must be captured on **every transaction record** — not just as a created_by attribute, but as part of the record's identity.
- The app UI always shows the current user's context: their runs, their assigned bugs, their open test-case requirements.
- The app must capture per-run environment details (hostname, PHP version, browser version, OS) — see FR-18.

**User roles** (`tst_users.role`):

| Role | Capabilities |
|---|---|
| `Admin` | All actions, user management, app settings |
| `Architect` | Read all, comment, set priorities |
| `QA_Lead` | Assign bugs, triage requirements, view all dashboards |
| `Tester` | Run tests, create test cases, manage requirements |
| `Developer` | Fix bugs, mark Fixed, view assigned bugs |
| `Reviewer` | Read-only access to all data |

---

### FR-14 — Composite Primary Key Strategy for Transaction Tables

**Problem Statement:**

When multiple developers each run tests locally, their transaction tables generate sequential IDs independently: developer A has run IDs 1, 2, 3, 4... and developer B also has run IDs 1, 2, 3, 4... When Brijesh attempts to import all this data into his central database, these IDs collide.

**Solution:**

All **transaction tables** adopt a **composite primary key `(id, user_code)`**:
- `id` is an `INT UNSIGNED AUTO_INCREMENT` — unique within one machine.
- `user_code` is `VARCHAR(5)` referencing `tst_users.code` — identifies the machine/user.
- Together, `(id, user_code)` is globally unique across all machines.

**Transaction tables** (composite PK applies):

| Table | Purpose |
|---|---|
| `tst_test_runs` | One row per run batch |
| `tst_test_run_results` | One row per test case within a run |
| `tst_test_case_runs_summary` | Rolling per-test-case stats |
| `tst_bugs` | Bug records |
| `tst_bug_status_history` | Bug status transition audit |
| `tst_retest_cycles` | Auto-retest cycle tracking |
| `tst_bug_retest_cycles_jnt` | Bug ↔ retest cycle junction |
| `tst_run_annotations` | User notes on runs/results |
| `tst_sync_logs` | Catalog sync history |
| `tst_test_case_requirements` | Test case backlog requirements |
| `tst_audit_logs` | System-wide write audit trail |
| `tst_data_exports` | Export job records |

**Catalog/Master tables** (simple INT or VARCHAR PK — same data across all machines):

| Table | PK |
|---|---|
| `tst_users` | `code VARCHAR(5)` |
| `tst_modules` | `id INT UNSIGNED` |
| `tst_categories` | `id INT UNSIGNED` |
| `tst_main_menus` | `id INT UNSIGNED` |
| `tst_sub_menus` | `id INT UNSIGNED` |
| `tst_tabs` | `id INT UNSIGNED` |
| `tst_test_cases` | `id INT UNSIGNED` |
| `tst_schedules` | `id INT UNSIGNED` |
| `tst_app_settings` | `id INT UNSIGNED` |

**FK chain rule within transaction tables:**

When a child transaction table references a parent transaction table, the FK must include **both columns** of the composite key: `FOREIGN KEY (parent_id, user_code) REFERENCES tst_parent(id, user_code)`. Since parent and child rows always belong to the same user on the same machine, `user_code` propagates naturally through the FK chain.

**Special case — `tst_schedules.last_run_id`:**

Because `tst_test_runs` now has a composite PK `(id, user_code)`, the schedule → run FK would require a composite FK on `tst_schedules`. To avoid this complexity on a catalog table, `last_run_id` is changed to reference `tst_test_runs.run_id` (a `VARCHAR(64)` unique natural key, format `YYYYMMDD_HHMMSS_XXXXXX`) instead of the composite PK. This allows a simple single-column FK.

**Special case — `tst_test_run_results` → `tst_bugs`:**

`tst_test_run_results` gains two columns: `bug_id INT UNSIGNED NULL` and `bug_user_code VARCHAR(5) NULL`, forming a composite FK to `tst_bugs(id, user_code)`.

---

### FR-15 — Central Data Aggregation & Import

**Purpose:** Brijesh collects every developer's test data into his central machine for team-wide analysis, trend detection, and accountability reporting.

**Import process:**

1. **Step 1 — Export**: each developer generates an export bundle from their local machine (see FR-20). The bundle includes all their transaction data, tagged with their `user_code`.
2. **Step 2 — Catalog sync**: the central import process first upserts catalog records (modules, menus, tabs, test_cases) by their **natural keys** (unique constraints) — no duplication, no collision.
3. **Step 3 — Transaction import**: transaction records are inserted with their original composite `(id, user_code)` — because `user_code` differs per machine, there is no collision even if `id` values are identical.
4. **Step 4 — Dedup detection**: the import log (`tst_sync_logs` on the central machine) records how many rows were inserted vs. skipped (already imported from a previous export from the same user).

**Central-only views:**

The central database enables cross-user queries that individual machines cannot run:
- Pass rate per test case per developer.
- Tests that pass for one developer but fail for another (environment divergence signal).
- Aggregate bug counts per developer (accountability).
- Regression timeline across all users.

**Conflict handling assumptions:**
- Same test case has bugs from two different developers (different `user_code`) → treated as **two separate bugs** in the central system (they represent independent discoveries on separate machines).
- A bug is `Fixed` on Dev A's machine but still `Open` on Dev B's → both records are imported as-is; the central analysis dashboard surfaces the divergence for QA Lead review.
- Catalog data (module IDs, tab IDs, test case IDs) must be **identical across all machines** — achieved by distributing catalog seeding scripts from the central machine and running `Sync` from the same Prime-AI codebase.

---

### FR-16 — System-Wide Audit Log (`tst_audit_logs`)

**Purpose:** Full accountability — who did what, when, and what changed — covering every write operation across all tables.

**Trigger:** Every `INSERT`, `UPDATE`, and `DELETE` on any `tst_*` table should create an entry. In Laravel, this is implemented via Model Observers on all Eloquent models.

**Data captured per audit entry:**

| Column | Type | Description |
|---|---|---|
| `id` | INT UNSIGNED AUTO_INCREMENT | Part of composite PK |
| `user_code` | VARCHAR(5) | Part of composite PK — actor who triggered the operation |
| `table_name` | VARCHAR(60) | Target table name, e.g. `tst_bugs` |
| `record_id` | VARCHAR(100) | String representation of the target row's PK (may be composite, serialized as JSON) |
| `operation` | ENUM(INSERT, UPDATE, DELETE) | Operation type |
| `old_values_json` | JSON NULL | Previous column values (NULL for INSERT) |
| `new_values_json` | JSON NULL | New column values (NULL for DELETE) |
| `ip_address` | VARCHAR(45) | Client IP |
| `user_agent` | VARCHAR(500) NULL | Browser/CLI user agent |
| `created_at` | TIMESTAMP | When the operation occurred |

**Key use cases:**
- "Who changed this bug status and when?"
- "Who deleted this test case?"
- "What was the value of this field before it was updated?"
- Compliance: complete tamper-evident trail for the testing process.

---

### FR-17 — Regression Detection & Code Quality Insights

**Purpose:** Surface tests that were previously passing and now fail — the primary signal of code changes that broke existing functionality.

**Regression definition:** A test case is a **regression** when its `tst_test_case_runs_summary.consecutive_failures > 0` AND `total_passed > 0` (it has passed before). A new test that has always failed is not a regression; it was never working.

**Data captured:**

- `tst_test_case_runs_summary` gains `first_passed_at DATETIME NULL` and `first_failed_after_pass_at DATETIME NULL` columns — the timestamp when a previously-passing test first failed (regression onset).
- `tst_test_runs` already captures `environment_json` (v3 adds `hostname` to this — see FR-18).

**Regression dashboard requirements:**
- List all currently-failing tests that have a prior passing history, sorted by `consecutive_failures DESC`.
- Group by Module and Tab to identify fragile areas of the codebase.
- Show which developer's run first detected the regression.
- Correlate regression onset date with git commits (out of app scope — the dashboard shows the date; developer cross-references git log manually).

**Code quality leaderboard (per developer `user_code`):**
- Count of bugs assigned to this developer that had `reopen_count > 0` (fix didn't hold).
- Count of tests that regressed after this developer's code changes (inferred from regression onset date and `executed_by` of last passing run vs. first failing run on the same machine).
- Intent: identify patterns of fragile fixes, not blame — used for coaching and targeted code review.

---

### FR-18 — Enhanced Environment & Device Capture

**Purpose:** Distinguish between "real bugs" (test fails on all machines) and "environment issues" (test fails only on one developer's machine due to local setup differences).

**Data captured per run** (additions to `tst_test_runs.environment_json`):

| Field | Example |
|---|---|
| `hostname` | `tarun-macbook` |
| `os` | `macOS 14.5` |
| `php_version` | `8.3.2` |
| `laravel_version` | `11.0.3` |
| `dusk_driver` | `chromedriver 124.0.6367.60` |
| `chrome_version` | `124.0.6367.61` |
| `app_env` | `testing` |
| `db_connection` | `mysql` |
| `prime_ai_git_commit` | `d55ceaa` |

**Environment divergence detection (FR-19 dependency):**

When the cross-user view (FR-19) shows the same test case passing for one user and failing for another, the environment details from both runs are compared to surface likely causes (e.g. different PHP versions, different Chrome versions).

---

### FR-19 — Test Coverage Matrix (Cross-User Comparison)

**Purpose (central database only):** Show which test cases each developer has run, and what their results were, allowing QA Lead to identify:
- Tests no developer has run yet (coverage gaps).
- Tests that consistently fail for one developer but pass for others (environment issue, not a code bug).
- Tests that fail for everyone (real bugs).

**Views required on central database:**

**`vw_cross_user_test_coverage`:**

| Column | Description |
|---|---|
| `test_case_id` | FK tst_test_cases |
| `module_name` | Module |
| `tab_name` | Tab |
| `test_case_name` | Display name |
| `user_code` | Developer |
| `last_status` | Their most recent result |
| `last_run_at` | When they last ran it |
| `pass_rate` | Pass rate for this user for this test case |
| `total_runs` | How many times this user ran this test case |

**`vw_test_flakiness_by_user`:**

Surfaces tests where `is_flaky = 1` per user — a test flaky for only one user is likely an environment issue. A test flaky for all users is likely a timing issue in the test itself.

**`vw_coverage_gaps`:**

Lists test cases with no run history from any user in the past 30 days — tests that exist in the catalog but are not being executed.

---

### FR-20 — Data Export/Import Mechanism (`tst_data_exports`)

**Purpose:** Each developer exports their local test data as a structured bundle. Brijesh imports these bundles into his central database.

**Export bundle contents:**

1. Catalog snapshot (modules, categories, menus, tabs, test_cases) — for dedup on import.
2. All transaction data rows for this `user_code`, in dependency order (runs → results → bugs → status history → retest cycles → annotations → audit logs).
3. Metadata file: `user_code`, export timestamp, date range, row counts per table.

**Export bundle format:** JSON (one file per table, wrapped in a manifest JSON). SQL dump format as an alternative (INSERT statements with explicit column lists).

**`tst_data_exports` table (tracks export jobs):**

| Column | Type | Description |
|---|---|---|
| `id` | INT UNSIGNED AUTO_INCREMENT | Part of composite PK |
| `user_code` | VARCHAR(5) | Part of composite PK |
| `export_name` | VARCHAR(150) | User-defined label, e.g. "Week 25 Export" |
| `date_from` | DATE NULL | Filter: export data from this date |
| `date_to` | DATE NULL | Filter: export data to this date |
| `modules_json` | JSON NULL | Filter: specific module IDs to include (NULL = all) |
| `file_path` | VARCHAR(500) NULL | Path to generated export file in storage |
| `status` | ENUM(Pending, In_Progress, Completed, Failed) | Export job status |
| `record_counts_json` | JSON NULL | `{"tst_test_runs": 120, "tst_bugs": 8, ...}` |
| `exported_at` | DATETIME NULL | When the export file was generated |
| `created_at` | TIMESTAMP | |
| `updated_at` | TIMESTAMP | |

**Import process (on central machine):**

1. Receive export bundle from a developer.
2. Upsert catalog records (by natural key) — no duplication.
3. INSERT transaction rows with `ON DUPLICATE KEY UPDATE` (using composite PK) — idempotent; re-importing the same bundle is safe.
4. Log the import in `tst_sync_logs` on the central machine (rows added, rows skipped, errors).

---

## 8. Updated Conceptual Data Model (v3)

### Composite PK on Transaction Tables

All transaction tables gain a `user_code VARCHAR(5) NOT NULL` column that references `tst_users.code`. The composite `(id, user_code)` becomes the table's PK. FK references between transaction tables carry `user_code` as part of the composite FK.

### Schema Bug Fixes (v6 → v7)

All `_by` / `_to` columns that previously were `INT UNSIGNED` referencing `tst_users(id)` are corrected to `VARCHAR(5)` referencing `tst_users(code)`:

| Column examples | Old (incorrect) | New (correct) |
|---|---|---|
| `created_by`, `executed_by` | `INT UNSIGNED` → `tst_users(id)` | `VARCHAR(5)` → `tst_users(code)` |
| `assigned_to`, `assigned_by` | `INT UNSIGNED` → `tst_users(id)` | `VARCHAR(5)` → `tst_users(code)` |
| `fixed_by`, `closed_by` | `INT UNSIGNED` → `tst_users(id)` | `VARCHAR(5)` → `tst_users(code)` |
| `changed_by`, `requested_by` | `INT UNSIGNED` → `tst_users(id)` | `VARCHAR(5)` → `tst_users(code)` |
| `completed_by` | `INT UNSIGNED` → `tst_users(id)` | `VARCHAR(5)` → `tst_users(code)` |

### New Tables (v3)

| Table | Purpose | Composite PK |
|---|---|---|
| `tst_audit_logs` | System-wide write audit trail (FR-16) | `(id, user_code)` |
| `tst_data_exports` | Export job records (FR-20) | `(id, user_code)` |

### Modified Existing Tables (v3)

| Table | Change |
|---|---|
| `tst_test_runs` | Add `user_code`; PK → `(id, user_code)`; `executed_by` → `VARCHAR(5)` |
| `tst_test_run_results` | Add `user_code`; PK → `(id, user_code)`; add `bug_user_code` for composite FK to `tst_bugs`; FK `run_id` → `(run_id, user_code)` |
| `tst_test_case_runs_summary` | Add `user_code`; PK → `(test_case_id, user_code)`; add `first_passed_at`, `first_failed_after_pass_at` |
| `tst_bugs` | Add `user_code`; PK → `(id, user_code)`; `assigned_to/by/fixed_by/closed_by` → `VARCHAR(5)` |
| `tst_bug_status_history` | Add `user_code`; PK → `(id, user_code)`; FK → `(bug_id, user_code)`; `changed_by` → `VARCHAR(5)` |
| `tst_retest_cycles` | Add `user_code`; PK → `(id, user_code)`; FK `triggered_by_bug_id` → `(bug_id, user_code)` |
| `tst_bug_retest_cycles_jnt` | Add `user_code`; PK → `(bug_id, retest_cycle_id, user_code)` |
| `tst_run_annotations` | Add `user_code`; PK → `(id, user_code)` |
| `tst_sync_logs` | Add `user_code`; PK → `(id, user_code)`; `created_by` → `VARCHAR(5)` |
| `tst_test_case_requirements` | Add `user_code`; PK → `(id, user_code)`; all user FKs → `VARCHAR(5)` |
| `tst_modules` | `created_by` → `VARCHAR(5)` |
| `tst_schedules` | `last_run_id` → `VARCHAR(64)` referencing `tst_test_runs(run_id)` (natural key, avoids composite FK) |
| `tst_test_runs` | `environment_json` gains `hostname`, `os`, `prime_ai_git_commit` fields (documented, not schema-enforced) |

---

## 9. System User Seeding

The following users must be seeded before first use:

| code | name | role | is_system | Purpose |
|---|---|---|---|---|
| `sys` | System | `Admin` | 1 | Auto-triggered runs (Auto_Retest), system-generated bugs |
| `brij` | Brijesh | `Admin` | 0 | Central machine owner / QA Lead |

Additional developer users are seeded per installation by the Admin.

---

## 10. Updated Phased Roadmap

| Phase | Scope | FR Coverage |
|---|---|---|
| **Phase 1** | Catalog (sync), browse/select/run UI, run history, failure screenshots, basic reporting | FR-1, FR-2, FR-3, FR-4 |
| **Phase 2** | Analytics dashboards, tagging, run comparison, annotations | FR-5, FR-7 |
| **Phase 3** | Test case creation wizard/scaffolding, scheduling | FR-6, FR-7 |
| **Phase 4** | Test Case Requirements backlog + wizard pre-fill | FR-8 |
| **Phase 5** | Bug tracking + developer assignment + bug dashboards | FR-9, FR-12 |
| **Phase 6** | Automated Screen re-test loop + settings + audit trails + reopen leaderboard | FR-10, FR-11, FR-12 |
| **Phase 7** | Multi-user distributed model — composite PK schema, user attribution, environment capture | FR-13, FR-14, FR-18 |
| **Phase 8** | Central aggregation — export bundles, import process, import log | FR-15, FR-20 |
| **Phase 9** | Insights & regression detection — cross-user views, coverage matrix, code quality leaderboard | FR-16, FR-17, FR-19 |

---

## 11. Open Questions (v3)

1. **Same test case, two developers, two bugs (central system):** When the same test case has bugs raised by two developers with different `user_codes`, are they tracked as separate bugs?
   *Assumed: YES — they are independent discoveries on separate machines. The central analysis can correlate them by `test_case_id` to surface "this test is failing for multiple developers."*

2. **Catalog sync — manual vs. automatic:** Should the catalog sync run automatically on app startup?
   *Recommended: MANUAL only, triggered by the developer. Auto-sync on startup risks catalog drift if different developers have different states of the Prime-AI codebase (e.g. one has a feature branch checked out with new modules, another is on `main`).*

3. **Import conflict — same bug, different states on different machines:** A bug is `Fixed` on Dev A's machine but still `Open` on Dev B's. How should the central import handle this?
   *Assumed: import BOTH records as-is (they have different `user_codes`, so no key conflict). Central dashboard shows the divergence. QA Lead decides which state is authoritative.*

4. **Pre-seed `sys` user:** Should the system user (`code = 'sys'`) be pre-seeded in the migration/seed files?
   *YES — `is_system = 1` prevents it from appearing in assignment dropdowns. All auto-retest runs and system-generated audit entries reference this user.*

5. **`tst_test_case_runs_summary` — per user or aggregate?** With composite PK `(test_case_id, user_code)`, this table tracks stats per-user-per-test-case. The central machine can then aggregate across all users. Is this the intended behavior?
   *Assumed: YES — per-user stats on individual machines; the central machine can compute aggregates using standard GROUP BY queries on the unified data.*

6. **Export frequency:** How often should developers export and share their data?
   *Recommended: end of each sprint / testing session. No enforced frequency in the app — it is manual and on-demand.*

---

## 12. Architect's Additions (v3)

The following requirements were not in the user's original brief but are recommended for completeness of the distributed testing lifecycle:

- **Test isolation per developer:** Because each developer's machine may have different database state in Prime-AI (different tenant data, different seed data), test failures may be environment-specific rather than code bugs. FR-18 (environment capture) + FR-19 (cross-user comparison) together allow QA Lead to distinguish these cases systematically rather than guessing.

- **`user_code` on `tst_test_case_runs_summary`:** This table was a singleton in v2 (one row per test case). With composite PK in v3, it becomes per-user, enabling a "my test stats" view on individual machines and cross-user comparison on the central machine.

- **Reopen leaderboard (v2 FR-12, extended in v3):** In the central database, this leaderboard now spans all developers, providing a team-level view of which developers' fixes tend not to hold. This is a coaching tool, not a blame tool.

- **`prime_ai_git_commit` in `environment_json`:** Capturing the git commit hash of `prime_ai` at the time of each test run enables precise regression analysis — "this test started failing at commit X" — without requiring app integration with git.

- **Import idempotency:** The import process (FR-20) uses `INSERT ... ON DUPLICATE KEY UPDATE` (or `INSERT IGNORE` for append-only tables like `tst_audit_logs`). This means re-importing the same export bundle is always safe and produces no duplicates.

- **`vw_coverage_gaps` threshold:** The 30-day window used in FR-19's coverage gap view should be configurable via `tst_app_settings` (key: `coverage_gap_days`, default: `30`). Add this to FR-11's settings seed data.

---

## 13. Next Step

After approval of this document (and resolution of the open questions in §11, particularly **#2 catalog sync trigger** and **#5 summary table granularity**), the next deliverable is:

`/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/1-DDL_Tenant_Modules/Z-Testing_App/DDL/testing_ddl_v7.sql`

Built on `testing_ddl_v6.sql` with:
1. Bug fix: all user FK columns changed from `INT UNSIGNED → tst_users(id)` to `VARCHAR(5) → tst_users(code)`.
2. All transaction tables: add `user_code VARCHAR(5)`, convert to composite PK `(id, user_code)`, update internal FK chains.
3. `tst_test_case_runs_summary`: PK → `(test_case_id, user_code)`, add `first_passed_at`, `first_failed_after_pass_at`.
4. `tst_schedules.last_run_id`: change to `VARCHAR(64)` referencing `tst_test_runs(run_id)`.
5. `tst_test_run_results`: add `bug_user_code VARCHAR(5)`, fix composite FK to `tst_bugs`.
6. New tables: `tst_audit_logs`, `tst_data_exports`.
7. New views: `vw_cross_user_test_coverage`, `vw_test_flakiness_by_user`, `vw_coverage_gaps`.
8. `tst_app_settings`: add seed row for `coverage_gap_days`.
9. Pre-seed `tst_users` rows for `sys` (is_system=1) and `brij` (Admin).
