# Prime-AI Testing Automation App — Requirements Document (v2)

**Status:** Draft for approval
**Author:** Enterprise Architect (Claude)
**Date:** 2026-06-14
**Supersedes:** `testing_requirement_v1.md`
**Target Project:** `/Users/bkwork/Herd/prime_ai_testing` (new, separate Laravel project)
**Source App:** `/Users/bkwork/Herd/prime_ai`
**Companion DDL:** `testing_ddl_v5.sql` (supersedes `testing_ddl_v4.sql`)

---

## 0. What's New in v2

v1 covered the **catalog → select → run → history → analytics → test-case-creation**
lifecycle (FR-1 to FR-7). All of that remains valid and unchanged. v2 adds a
**continuous-enhancement lifecycle** on top of it:

1. **FR-8 — Test Case Requirements**: a backlog of test cases that *need to be written*
   because Prime-AI is regularly enhanced with new functionality.
2. **FR-9 — Bug Tracking & Developer Assignment**: when a test case fails, raise a bug,
   assign it to a developer (picked from `tst_users`).
3. **FR-10 — Automated Bug-Fix Verification Loop**: once a developer marks a bug "Fixed",
   the app automatically re-runs **all test cases for that Screen**; if any still fail, the
   bug re-opens and re-assigns to the **same developer**, repeating until the whole Screen
   is green.
4. **FR-11 — App Settings**: configurable thresholds (e.g. max auto-retest attempts).
5. **FR-12 — Additional v2 features**: SLAs, notifications, dashboards, audit history.

This document is **additive** — sections 1-12 below are carried forward from v1 (with two
small hierarchy corrections noted in §0.1), and §13 onward is new.

### 0.1 Hierarchy Correction (matches `testing_ddl_v4.sql`)

v1's hierarchy was strictly `Module → Category → Main Menu → Sub Menu → Tab`. The DDL has
since evolved (`testing_ddl_v4.sql`) to allow **Tabs to attach directly under a Main Menu**
when a screen has no Sub Menu level (`tst_tabs.sub_menu_id` is nullable; `tst_tabs.main_menu_id`
is always set). v2 carries this forward:

```
Module → Category → Main Menu → [Sub Menu (optional)] → Tab → Test Case
```

This directly affects **"Screen" scoping** for the auto-retest loop in FR-10 — see §13.3.

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
7. **(v2)** Tracks a **continuous backlog of new test-case requirements** as the app evolves,
   and runs a **closed-loop bug-fix → re-test → re-assign cycle** until a screen is fully
   green.

---

## 2. Source Material Reviewed

| File / Folder | Purpose |
|---|---|
| `prime_ai/tests/Browser/Modules/**` | 67 `*Test.php` Dusk files + 58 `requirements.md` — current test catalog |
| `prime_ai/tests/Browser/{screenshots,console,source,reports}/` | Legacy/loose artifact dirs (mostly empty, `.gitignore` placeholders) |
| `prime_ai/tests/Browser/Modules/Library/dusk-report/{screenshots,console}` + `testdox.txt/html`, `junit.xml` | Most mature example of per-module run output — pattern to generalize |
| `prime_ai/tests/DuskTestCase.php` | Confirms: Browser screenshots/console/source paths are configurable per run |
| `prime_ai/Modules/*` (44 module folders) | Source of truth for **Module** names |
| `testing_ddl_v4.sql` | Current (v1-derived) schema — hierarchy, catalog, run history, analytics |
| `testing_requirement_v1.md` | Prior requirements — catalog/run/history/analytics lifecycle |
| `AI_Brain/memory/testing-strategy.md` | Defines Unit/Feature/Dusk test types, `TenantTestCase`, naming conventions |
| `AI_Brain/memory/conventions.md` | Table-prefix & DDL conventions (soft delete, `is_active`, `_json`, etc.) |

---

## 3. Goals & Non-Goals

### Goals (v1, retained)
- G1: Single catalog of all testable Module → Category → Main Menu → [Sub Menu] → Tab → Test
  Case relationships, kept in sync with the real `prime_ai` codebase.
- G2: UI to browse this hierarchy, multi-select test cases, and run them.
- G3: Durable run history with full execution metadata + failure screenshots.
- G4: Analytics dashboards over history (pass rate trends, flaky tests, slowest tests,
  module/tab health).
- G5: Guided creation of new test cases (scaffold file + requirements doc + catalog entry).
- G6: Migrate existing artifacts (`tests/Browser/**` test files, requirements docs,
  screenshots, reports) from `prime_ai` into `prime_ai_testing`.

### Goals (v2, new)
- G7: Maintain a living **backlog of test-case requirements** generated as Prime-AI features
  are added/enhanced, with a completion workflow tied back to G5's scaffolding.
- G8: Turn every test **failure** into a tracked **bug** with developer assignment.
- G9: Close the loop automatically — a "Fixed" bug triggers a **scoped re-run**, and the
  bug only closes when that scope is 100% green; otherwise it **bounces back to the same
  developer** automatically.

### Non-Goals (unchanged from v1)
- NG1: Replacing PHPUnit/Dusk itself.
- NG2: CI/CD integration (future enhancement).
- NG3: Editing `prime_ai` application code from the testing app (only test files /
  requirements docs under `tests/` are created/edited).
- NG4 *(relaxed in v2)*: v1 assumed single-developer usage. v2's bug-assignment workflow
  requires **multiple named users** (`tst_users`) — testers and developers — but still no
  full RBAC/permission system; assignment is a simple FK pick-list.

---

## 4. Hierarchy & Discovery Model

Unchanged from v1, with the §0.1 correction (Tab may attach directly to Main Menu). See
`testing_requirement_v1.md` §4 for the full discovery-process description (Sync, manual
curation, file-pattern tolerance). v2 adds no new discovery logic — requirements/bugs are
created *by users*, not by the Sync job.

---

## 5. Functional Requirements (v1, retained)

### FR-1: Module/Hierarchy Browser
List all Modules → Categories → Main Menus → [Sub Menus] → Tabs → Test Cases, with status,
search/filter. *(unchanged)*

### FR-2: Test Case Selection & Execution
Checkbox selection at any level, "Run Selected"/"Run All"/"Re-run Failed" via
`php artisan dusk --filter=...`, queued execution with live output streaming. *(unchanged)*

### FR-3: Run History Capture
Full `tst_test_runs` + `tst_test_run_results` capture (executed_by, timings, counts, raw
output). *(unchanged — v2 adds `trigger_type = 'Auto_Retest'`, see §13.3)*

### FR-4: Failure Artifact Capture
Per-run screenshot/console/source directories, linked from `tst_test_run_results`.
*(unchanged)*

### FR-5: Run History & Analytics
History list, run detail, pass-rate trends, flaky detection, slowest tests, coverage gaps.
*(unchanged — v2 adds bug-centric dashboards, see §13.6)*

### FR-6: Test Case Creation Workflow
"New Test Case" wizard generating scaffold `*Test.php` + `requirements.md` + catalog row.
*(unchanged — v2's FR-8 is the upstream backlog that feeds this wizard)*

### FR-7: Additional v1 Features
Tagging, scheduling (`tst_schedules`), run comparison, annotations, module health score,
export. *(unchanged — v2 reuses `tst_schedules` infrastructure for auto-retest, see §13.3)*

---

# 13. New Requirements (v2)

## 13.1 FR-8 — Test Case Requirements (Backlog)

**Purpose:** As Prime-AI is enhanced regularly, every new/changed screen or feature needs a
new (or updated) automated test case. FR-8 gives the team a place to **log that need**,
**track ownership**, and **close the loop** once the test case exists.

### Data captured per requirement
- Target location in the catalog: `module_id`, `main_menu_id`, `sub_menu_id` (nullable),
  `tab_id` (nullable — may not exist yet if the Tab itself is new).
- If `tab_id` is null, a **free-text proposed tab/feature name** + proposed folder path
  (so the eventual FR-6 scaffolding wizard has somewhere to write).
- `title`, `description` (what changed in the app / what needs covering — e.g. "New bulk
  attendance import on Student Profile screen needs a happy-path + validation test").
- `priority` (Low/Medium/High/Critical) and optional `target_release` (free text, e.g.
  "2026.07 Release" — ties to Prime-AI's regular enhancement cadence).
- `requested_by` (FK `tst_users` — e.g. Business Analyst / QA Lead who spotted the gap).
- `assigned_to` (FK `tst_users`, nullable — the tester who will write the test case).
- `status`: `Pending` → `In_Progress` → `Completed` (or `Cancelled`).
- Once the testing team writes the test case (via FR-6's wizard or manually + Sync),
  they link it via `target_test_case_id` (FK `tst_test_cases`) and set
  `status = 'Completed'`, recording `completed_by` / `completed_at`.

### Workflow
1. Anyone (BA/QA/Dev) raises a Test Case Requirement against a Module/Screen (existing or
   new) describing the enhancement that needs coverage.
2. QA Lead triages: sets `priority`, assigns to a tester (`assigned_to`), optionally sets
   `target_release`.
3. Tester picks it up (`status = 'In_Progress'`), uses FR-6's "New Test Case" wizard
   (pre-filled from the requirement's module/screen/title/description) to scaffold the
   `*Test.php` + `requirements.md`.
4. Tester implements the test, runs Sync (catalog picks up the new `tst_test_cases` row).
5. Tester links the requirement to the new catalog row (`target_test_case_id`) and marks
   `status = 'Completed'`.
6. **Dashboard**: open requirements by status/priority/assignee; "stale" requirements
   (no movement in N days) surfaced (see §13.6).

---

## 13.2 FR-9 — Bug Tracking & Developer Assignment

**Purpose:** Every test-case **failure** is a potential bug. FR-9 turns a failing
`tst_test_run_results` row into a tracked, assignable, auditable **bug**.

### Bug creation
- When a run completes and a `tst_test_run_results` row has `status = 'Failed'` (or
  `'Error'`), the system either:
  - **Auto-creates** a `tst_bugs` row (`status = 'Open'`) if no open bug already exists for
    that `test_case_id`, **or**
  - **Links** the new failing result to the **existing open bug** for that test case
    (avoids duplicate bug spam on repeated failures of the same test).
- A QA user can also raise a bug **manually** (e.g. from exploratory testing, not tied to an
  automated run) — `run_result_id` is nullable.

### Bug fields
- `run_result_id` (FK `tst_test_run_results`, nullable — originating failure).
- `test_case_id` (FK `tst_test_cases`).
- `tab_id`, `sub_menu_id`, `main_menu_id` — denormalized **scope** info, used by FR-10 to
  determine the "Screen" to re-test (see §13.3).
- `title`, `description` (defaults to the test's error message/trace, editable).
- `severity` (Low/Medium/High/Critical).
- `status`: `Open` → `Assigned` → `In_Progress` → `Fixed` → `Retesting` → (`Closed` |
  `Reopened` → back to `Assigned`) | `Wont_Fix`.
- `assigned_to` (FK `tst_users` — **picked from the Users table**, i.e. a developer),
  `assigned_by`, `assigned_at`.
- `fixed_by`, `fixed_at`, `fix_notes` — developer fills these when marking `Fixed`.
- `reopen_count` — incremented each time FR-10's re-test loop sends it back.
- `closed_by`, `closed_at`.

### Workflow
1. **QA** reviews newly-failed test cases (dashboard: "Open Bugs"), edits/confirms
   `title`/`description`/`severity`, and sets `assigned_to` = a developer (from
   `tst_users`) → `status = 'Assigned'`.
2. **Developer** sees their assigned bugs (dashboard: "My Bugs"), works the fix, sets
   `status = 'In_Progress'` then `status = 'Fixed'` (fills `fix_notes`, optionally a
   commit/PR reference).
3. Marking `Fixed` **automatically triggers FR-10** (the re-test loop) — `status` moves to
   `Retesting`.
4. FR-10 resolves the bug to either `Closed` (screen fully green) or `Reopened` → back to
   `Assigned` to the **same developer** (`assigned_to` unchanged), with `reopen_count + 1`.
5. Every status transition is recorded in `tst_bug_status_history` for audit.

---

## 13.3 FR-10 — Automated Bug-Fix Verification Loop ("Screen Re-test")

**Purpose:** Once a developer marks a bug `Fixed`, automatically **re-run every test case
for that Screen**. If all pass, close the bug(s). If any still fail, **reopen and
re-assign to the same developer**, and repeat — until the Screen is fully green (or a
configurable max-attempts safety limit is hit, see FR-11).

### "Screen" definition (resolves §0.1's hierarchy correction)
The **Screen** is the smallest catalog node that groups multiple Tabs:
- If the bug's Tab has a `sub_menu_id`, **Screen = that Sub Menu** → re-test scope =
  *all Test Cases under all Tabs where `tab.sub_menu_id = bug.sub_menu_id`*.
- If the bug's Tab has **no** `sub_menu_id` (attaches directly to a Main Menu), **Screen =
  that Main Menu** → re-test scope = *all Test Cases under all Tabs where
  `tab.main_menu_id = bug.main_menu_id AND tab.sub_menu_id IS NULL`*.

This scope is computed once and stored on the bug (`sub_menu_id` / `main_menu_id`,
already denormalized per §13.2) so the retest job doesn't need to re-derive it.

### Retest Cycle mechanics
1. Developer sets bug `status = 'Fixed'`.
2. System creates a **`tst_retest_cycles`** row: `sub_menu_id`/`main_menu_id` (the Screen),
   `triggered_by_bug_id`, `cycle_number` (1, 2, 3… — increments per Screen+bug chain),
   `status = 'Pending'`.
3. System enqueues a `tst_test_runs` row scoped to **all Test Cases for that Screen**
   (`trigger_type = 'Auto_Retest'`), linked via `tst_retest_cycles.run_id`.
4. **Every open bug whose scope matches this Screen** (not just the one that triggered it —
   multiple bugs can share a Screen) is linked to this cycle via
   `tst_bug_retest_cycles_jnt` and moves to `status = 'Retesting'`.
5. When the run completes:
   - For each bug in the cycle, check whether **its own `test_case_id`** passed in this run:
     - **Passed** → `tst_bug_retest_cycles_jnt.outcome = 'Passed'`; bug → `status = 'Closed'`,
       `closed_at = now()`, `closed_by = NULL` (system-closed).
     - **Failed** → `outcome = 'Failed'`; bug → `status = 'Reopened'`, `reopen_count += 1`,
       `assigned_to` **unchanged** (same developer), `status` then immediately →
       `Assigned` (re-enters developer's queue).
   - `tst_retest_cycles.status` = `'Passed'` only if **every** Test Case in the Screen's
     scope passed (not just the bugged ones — a regression elsewhere on the same Screen
     also counts); otherwise `'Failed'`.
6. **Loop continuation**: a Reopened bug, when next marked `Fixed` again, creates
   `cycle_number + 1` for the same Screen — the loop repeats from step 2.
7. **Safety valve**: if `reopen_count >= tst_app_settings['max_auto_retest_attempts']`
   (default 5, see FR-11), the bug instead moves to `status = 'Escalated'` (no further
   auto-retest; requires manual QA intervention) rather than looping forever.

### New run trigger type
`tst_test_runs.trigger_type` gains a 4th value: `'Auto_Retest'` (alongside `Manual`,
`Scheduled`, `Rerun`).

---

## 13.4 FR-11 — App Settings

A simple key/value settings table (`tst_app_settings`) for thresholds/toggles the above
workflows depend on:

| Key | Default | Purpose |
|---|---|---|
| `max_auto_retest_attempts` | `5` | FR-10 step 7 safety valve — after this many reopen cycles for the same bug, escalate instead of auto-retesting again. |
| `auto_retest_enabled` | `true` | Global kill-switch — if `false`, marking a bug `Fixed` does **not** auto-trigger FR-10 (manual re-test only). |
| `auto_bug_creation_enabled` | `true` | If `false`, failures populate `tst_test_run_results` as today but **no** `tst_bugs` row is auto-created (QA must raise manually). |
| `bug_fix_sla_hours` | `48` | Used by §13.6 "stale bug" dashboard alerts (no DB enforcement, reporting only). |

`tst_app_settings` is a generic `key` (unique) / `value` / `value_type` / `description` table
— extensible without further DDL changes for future toggles.

---

## 13.5 FR-12 — Additional v2 Functionality (Architect's additions)

- **Bug status audit trail** (`tst_bug_status_history`): every transition
  (`Open→Assigned→In_Progress→Fixed→Retesting→Closed/Reopened→...`) recorded with actor +
  timestamp + optional note — essential once bugs can loop multiple times.
- **Retest cycle history** (`tst_retest_cycles` + `tst_bug_retest_cycles_jnt`): full audit of
  how many times a Screen had to be re-tested before going green — a great "code quality"
  KPI per module/screen.
- **"My Work" dashboards**:
  - *Tester view*: open Test Case Requirements assigned to me.
  - *Developer view*: open/reopened bugs assigned to me, sorted by `severity` then
    `reopen_count` (a bug that keeps bouncing back is high-signal).
  - *QA Lead view*: unassigned bugs, unassigned requirements, bugs nearing
    `bug_fix_sla_hours`, bugs at `Escalated`.
- **Bug ↔ Requirement linkage** *(optional, light-touch)*: a bug can optionally reference the
  `tst_test_case_requirements.id` that introduced the feature being tested (nullable FK on
  `tst_bugs`), giving end-to-end traceability: *enhancement requested → test case written →
  test failed → bug raised → fixed → re-verified*.
- **Notifications** *(Phase 2, out of DB scope for v2 DDL)*: email/in-app notify
  `assigned_to` on bug assignment/reassignment and `requested_by` on requirement completion.
- **Reopen-count leaderboard**: surfaces Screens/Tabs/developers with the highest
  `reopen_count` totals — proxy for fragile areas of the app or fixes that don't hold.

---

## 14. Updated Conceptual Data Model (v2 additions)

All v1 tables (`tst_modules` … `vw_test_run_history`) are retained as-is (per
`testing_ddl_v4.sql`, with two bug-fixes — see `testing_ddl_v5.sql` header notes). New
tables:

| Table | Purpose | Key Columns (indicative) |
|---|---|---|
| `tst_test_case_requirements` | Backlog of needed/updated test cases (FR-8) | `id`, `module_id`, `main_menu_id`, `sub_menu_id`, `tab_id` (nullable), `proposed_tab_name`, `proposed_folder_path`, `title`, `description`, `priority`, `target_release`, `requested_by`, `assigned_to`, `status`, `target_test_case_id`, `completed_by`, `completed_at` |
| `tst_bugs` | One row per tracked bug (FR-9) | `id`, `run_result_id`, `test_case_id`, `tab_id`, `main_menu_id`, `sub_menu_id`, `requirement_id`, `title`, `description`, `severity`, `status`, `assigned_to`, `assigned_by`, `assigned_at`, `fixed_by`, `fixed_at`, `fix_notes`, `reopen_count`, `closed_by`, `closed_at` |
| `tst_bug_status_history` | Audit trail of bug status transitions (FR-12) | `id`, `bug_id`, `from_status`, `to_status`, `changed_by`, `note`, `created_at` |
| `tst_retest_cycles` | One row per auto-retest cycle for a Screen (FR-10) | `id`, `main_menu_id`, `sub_menu_id`, `triggered_by_bug_id`, `cycle_number`, `run_id`, `status` |
| `tst_bug_retest_cycles_jnt` | Many-to-many: which bugs were covered by which retest cycle, and the outcome (FR-10) | `bug_id`, `retest_cycle_id`, `outcome` |
| `tst_app_settings` | Key/value configuration (FR-11) | `id`, `key`, `value`, `value_type`, `description` |

### Modified existing tables
- `tst_test_runs.trigger_type` ENUM extended with `'Auto_Retest'`.
- `tst_test_run_results` gains nullable `bug_id` (FK `tst_bugs`) — links a failing result to
  the bug it raised/belongs to.

---

## 15. Phased Roadmap (updated)

- **Phase 1** *(v1, unchanged)*: Catalog (sync), browse/select/run UI, run history, failure
  screenshots, basic reporting.
- **Phase 2** *(v1, unchanged)*: Analytics dashboards, tagging, run comparison, annotations.
- **Phase 3** *(v1, unchanged)*: Test case creation wizard/scaffolding, scheduling, CI
  integration.
- **Phase 4** *(v2, new)*: Test Case Requirements backlog (FR-8) + wizard pre-fill from
  requirements.
- **Phase 5** *(v2, new)*: Bug tracking + developer assignment (FR-9), bug dashboards.
- **Phase 6** *(v2, new)*: Automated Screen re-test loop (FR-10) + settings (FR-11) +
  audit trails / leaderboards (FR-12).

---

## 16. Open Questions / Assumptions (v2)

1. **Bug auto-creation de-dup window**: if a test case has an *existing closed* bug and
   fails again later (regression), should the system reopen the closed bug or create a new
   one? *(Assumed: create a **new** bug — a closed bug represents a verified fix; a new
   failure is a new defect, even if the symptom looks similar. The old bug's history remains
   intact for trend analysis.)*
2. **"Screen" granularity for re-test**: confirmed as Sub Menu (or Main Menu when no Sub
   Menu) per §13.3. If this proves too broad (large screens with many tabs → long re-test
   runs), a future Tab-level retest mode could be added — flagged as a possible v3 toggle,
   not built now.
3. **`tst_users` roles**: v2 needs to distinguish "testers" (assignable to
   `tst_test_case_requirements.assigned_to`) from "developers" (assignable to
   `tst_bugs.assigned_to`). Should `tst_users` gain a `role` ENUM
   (`Admin`/`Tester`/`Developer`/`QA_Lead`), or is assignment unrestricted (any user can be
   picked for either)? *(Recommendation: add a lightweight `role` ENUM for filtering
   assignment dropdowns, but don't enforce it at the DB level — flagged for your decision.)*
4. **Max-attempts escalation routing**: when `status = 'Escalated'` (FR-10 step 7), who does
   it route to — QA Lead, or back to `assigned_by`? *(Assumed: stays visible to QA Lead
   dashboard via status filter; no separate escalation-assignee field added in v2 — can be a
   v3 enhancement.)*

---

## 17. Next Step

Pending your approval (and §16 decisions, particularly **#3 `tst_users.role`**), the next
deliverable is:

`/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/1-DDL_Tenant_Modules/Z-Testing_App/DDL/testing_ddl_v5.sql`

— built on `testing_ddl_v4.sql` (with two small bug-fixes: a dangling `created_by` FK on
`tst_modules`, and a typo in `tst_schedules`' `ON DELETE SET NULL`), plus the six new tables
and two column additions described in §14.
