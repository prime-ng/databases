# Context: Phase 2 Deep Code Audit (10 Modules) + New Agent Creation Plan
# Saved: 2026-06-22 09:03
# Session Duration: Multi-turn session (continuation from previous context-compacted session)
# Project: PrimeAI

---

## 1. SESSION OBJECTIVE

Three parallel goals were accomplished:

A. **Phase 2 Deep Quality Audit** — Run a full grep-based code audit across 10 newly added or high-growth Laravel modules. Find SEC/BUG/PERF/VAL/DEAD issues. Write findings to `known-issues.md` and update `progress.md`.

B. **prime_testing App DDL + Requirements** — Create `testing_requirement_v3.md` and `testing_ddl_v7.sql` for the standalone prime_testing Laravel app (multi-developer localhost test automation).

C. **New Agent Creation Plan** — Design and document two new Claude agents: `Technical_Auditor` and `Testing_Architect`.

---

## 2. SUMMARY OF WORK DONE

- **Phase 2 workflow launched** — 10 parallel audit agents (one per module) using structured JSON schema output, then 1 synthesis agent that wrote findings to files.
- **108 findings** recorded across 10 modules (SEC, BUG, PERF, VAL, DEAD categories).
- **`known-issues.md` updated** — grew from 1,022 lines to 1,144 lines. New section "Phase 2 — New Module Audit (2026-06-21)" appended with P0/P1/P2 tables.
- **`progress.md` updated** — completion % revised downward for several modules based on stub discovery. New audit header line added.
- **`testing_requirement_v3.md` created** (525 lines, FR-1 through FR-20). New FRs: FR-13 (multi-dev distributed), FR-14 (composite PK), FR-15 (central aggregation), FR-16 (audit log), FR-17 (regression detection), FR-18 (env capture with hostname), FR-19 (cross-user coverage matrix), FR-20 (export/import).
- **`testing_ddl_v7.sql` created** (976 lines, 12 sections). Fixed v6 bug where all "by" columns were INT UNSIGNED → tst_users(id) which doesn't exist (PK is `code VARCHAR(5)`).
- **`modules-map.md` updated** — 37 → 45 modules. Global stats: 806 models, 747 ctrl, 318 svc, 3,764 views, 451 req, 608 migrations.
- **New agent plan written** to `7-Work_with_CLAUDE/Temp_Output_Files/New_Agent_Creation_plan.md` — full agent file content for both agents included, plus 5-step implementation checklist.

---

## 3. FILES TOUCHED

### Created:
- `/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/1-DDL_Tenant_Modules/Z-Testing_App/Design/testing_requirement_v3.md`
  — Purpose: v3 requirements doc for prime_testing app; adds FR-13 to FR-20 covering multi-developer composite PK architecture, audit logs, regression detection, export/import.
- `/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/1-DDL_Tenant_Modules/Z-Testing_App/DDL/testing_ddl_v7.sql`
  — Purpose: v7 DDL for prime_testing app. Key fix: all "by" columns changed from INT UNSIGNED → VARCHAR(5) referencing `tst_users(code)` (the correct PK). Adds tst_audit_logs (Section 9) and tst_data_exports (Section 10). 4 new views added.
- `/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/7-Work_with_CLAUDE/Temp_Output_Files/New_Agent_Creation_plan.md`
  — Purpose: Complete plan for creating Technical_Auditor and Testing_Architect agents. Includes full file content, CLAUDE.md update rows, supporting memory files needed, and 5-step implementation checklist.

### Modified:
- `/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/AI_Brain/lessons/known-issues.md`
  — Appended "Phase 2 — New Module Audit (2026-06-22)" section. 1,022 → 1,144 lines. 305 total issue rows now in file.
- `/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/AI_Brain/state/progress.md`
  — Added Phase 2 audit header. Updated completion % for 10 modules. Added deep-audit detail rows for ParentPortal, Dashboard, SchoolSetup, Library, Hostel, CommonChat, BehaviouralAssessment, Ptm, MarksheetGeneration, Feedback.
- `/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/AI_Brain/memory/modules-map.md`
  — Phase 1 update: 37 → 45 modules. Added Hostel, ParentPortal, BehaviouralAssessment, CommonChat, Ptm (new). MarksheetGeneration and Feedback graduated from DDL-only. Fresh counts for all 35 tenant modules.

### Discussed/Reviewed (not modified):
- `/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/AI_Brain/agents/enterprise-architect.md` — Read to understand agent file format before writing New Agent plan.
- `/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/AI_Brain/agents/test-agent.md` — Read to understand existing test agent scope (it's narrow: Pest syntax only). New Testing_Architect agent is much broader.
- `/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/AI_Brain/config/paths.md` — Loaded to resolve path variables.
- `/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/Z-Others/Workspaces/Prime-AI_Main.code-workspace` — Checked: last 2 folders (tarun_prime_context, prime_testing) don't exist on disk at paths specified.
- `/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/AI_Brain/lessons/known-issues.md` — Read (tail) before Phase 2 launch to extract max issue codes per module prefix.

---

## 4. KEY DECISIONS & RATIONALE

**Decision:** Composite PK `PRIMARY KEY (id, user_code)` on ALL transaction tables in prime_testing.
**Why:** Multiple developers run tests on localhost independently. All get id=1,2,3... Auto-increment collides when merging into central DB. With `(id, user_code)` — `(1,'brij')` and `(1,'tarun')` are unique.
**Alternatives Considered:** UUID primary keys — rejected as they're harder to read in queries and break existing INT-based UI patterns.

**Decision:** `tst_users` PK is `code VARCHAR(5)` (not `id INT`).
**Why:** The user code IS the identity. There is no surrogate key needed. All "by" columns across the entire schema are `VARCHAR(5)` referencing `tst_users(code)`.
**Impact:** This was a breaking change vs v6 which had `INT UNSIGNED` for all "by" columns pointing to a non-existent `tst_users.id`.

**Decision:** `tst_schedules.last_run_id` is `VARCHAR(64)` not `INT UNSIGNED`.
**Why:** `tst_schedules` is a catalog table (simple INT PK), but `tst_test_runs` now has composite PK `(id, user_code)`. A catalog table cannot have a composite FK. Solution: reference `tst_test_runs.run_id` instead (a UNIQUE string key like `'20260612_143000_a1b2c3'`).

**Decision:** Catalog tables (tst_modules, tst_categories, tst_menus, tst_tabs, tst_test_cases) keep simple INT PK.
**Why:** These contain identical data across all developer machines (synced from codebase). No collision risk. Composite PK is only needed on transaction tables where each developer generates independent auto-increment IDs.

**Decision:** Phase 2 audit run as a Workflow with 10 parallel agents + 1 synthesis agent.
**Why:** 10 independent module audits with no cross-dependency → perfect for parallelism. Synthesis agent needed structured output (JSON schema) from audit agents to format markdown table rows correctly.

**Decision:** Two new agents (`Technical_Auditor`, `Testing_Architect`) planned but NOT yet created.
**Why:** Plan file was written first for review. Actual agent files in `AI_Brain/agents/` not yet created. See Step 1 of the plan.

---

## 5. TECHNICAL DETAILS & PATTERNS

- **Issue code format:** `TYPE-PREFIX-NNN` — e.g., `SEC-PPT-001`, `BUG-HST-004`, `PERF-BEH-003`. Each type (SEC/BUG/PERF/VAL/DEAD) has its own counter per module prefix. New codes must not conflict with existing ones in `known-issues.md`.
- **Max existing codes per prefix** (as of Phase 2 audit — use NEXT number for new findings):
  - PPT: SEC-005, BUG-003, PERF-003, VAL-002, DEAD-001
  - DSH: SEC-007, BUG-006, PERF-002, DEAD-001
  - SCH: SEC-020, BUG-024, PERF-001, VAL-002, DEAD-003
  - LIB: SEC-011, BUG-011, PERF-010, VAL-002, DEAD-002
  - HST: SEC-003, BUG-005, PERF-002, VAL-001, DEAD-001
  - CCH: SEC-001, BUG-001, PERF-003, VAL-001, DEAD-001
  - BEH: SEC-002, BUG-002, PERF-004, VAL-002, DEAD-001
  - PTM: SEC-002, PERF-004, VAL-001, DEAD-001
  - MSG: SEC-003, BUG-004, PERF-003, VAL-001, DEAD-001
  - FBK: SEC-002, BUG-002, PERF-001, VAL-002, DEAD-001
  - (Older prefixes: ACC-6, ADM-3, BIL-5, BOK-4, CAF-1, CMP-13, DSH-5, EVT-2, EXM-7, FEE-3, GLB-5, HPC-16, HR-1, HWK-3, INV-2, LIB-9, LMS-5, NOT-10, NTF-6, PAY-8, PRM-14, QB-3, QNS-2, QZT-2, REC-2, RTG-5, SCH-16, STD-7, STP-14, SYL-3, SYS-10, TPT-21, TT-13, VND-6)

- **Agent file structure** (from enterprise-architect.md study):
  - Section: Role, Scope vs Other Agents, Before Starting (files to read), Domain sections with sub-checks, Deliverables
  - Agents are pure markdown — no code deployment. Claude reads the file when user says "act as X".

- **prime_testing table prefix:** `tst_`
- **prime_testing composite FK pattern:** `FOREIGN KEY (run_id, user_code) REFERENCES tst_test_runs(id, user_code)` — both columns included in FK.
- **tst_test_runs.run_id:** A UNIQUE VARCHAR(64) string key (e.g., `'20260612_143000_a1b2c3'`) used as an alternative FK anchor for catalog tables that can't use composite PKs.

---

## 6. DATABASE CHANGES

**prime_testing app (standalone Laravel app, not in LARAVEL_REPO):**
- `tst_users` — PK: `code VARCHAR(5)`. Seeded with: sys, brij, tarun, shail, samer, gaurv.
- Catalog tables (simple INT PK): `tst_modules`, `tst_categories`, `tst_main_menus`, `tst_sub_menus`, `tst_tabs`, `tst_test_cases`, `tst_schedules`, `tst_app_settings`.
- Transaction tables (composite PK): `tst_test_runs`, `tst_test_run_results`, `tst_test_case_runs_summary`, `tst_run_annotations`, `tst_sync_logs`, `tst_test_case_requirements`, `tst_bugs`, `tst_bug_status_history`, `tst_retest_cycles`, `tst_bug_retest_cycles_jnt`, `tst_audit_logs`, `tst_data_exports`.
- 12 views total: 4 from v6 (updated) + 4 new (vw_cross_user_test_comparison, vw_regression_candidates, vw_developer_activity_summary, vw_reopen_leaderboard).
- DDL file: `1-DDL_Tenant_Modules/Z-Testing_App/DDL/testing_ddl_v7.sql` (976 lines).

**No changes to prime_ai LARAVEL_REPO database migrations this session.**

---

## 7. PROBLEMS ENCOUNTERED & SOLUTIONS

**Problem:** v6 DDL had `INT UNSIGNED` for all "by" columns referencing `tst_users(id)`.
**Cause:** `tst_users` has no `id` column — its PK is `code VARCHAR(5)`. The FK target didn't exist.
**Solution:** Fixed in v7: all "by" columns changed to `VARCHAR(5)` with FK `REFERENCES tst_users(code)`.

**Problem:** `tst_schedules` (catalog table with simple INT PK) needed a FK to `tst_test_runs` which now has composite PK `(id, user_code)`.
**Cause:** A catalog table with simple PK cannot have a composite FK to a composite PK table without including the extra column in the catalog table itself.
**Solution:** Changed `last_run_id` from `INT UNSIGNED` to `VARCHAR(64)` referencing `tst_test_runs.run_id` (a UNIQUE string key), bypassing the composite PK issue entirely.

**Problem:** Phase 2 pre-work needed max code numbers per module prefix from 1,022-line known-issues.md.
**Cause:** New findings must not conflict with existing codes.
**Solution:** Ran `grep -n` to extract all code patterns per prefix, manually identified max numbers for all 34 prefixes. These are recorded in Section 5 above.

---

## 8. CURRENT STATE OF WORK

### Completed:
- Phase 1 memory update: modules-map.md updated to 45 modules with fresh code counts.
- Phase 2 deep audit: 108 findings written to known-issues.md; progress.md updated for 10 modules.
- prime_testing app: testing_requirement_v3.md (FR-1 to FR-20) and testing_ddl_v7.sql (v7) created.
- New agent plan: New_Agent_Creation_plan.md written with full content for both agents.

### In Progress:
- N/A — all tasks completed within this session.

### Not Yet Started:
- **Create actual agent files** (Step 1 of plan):
  - `AI_Brain/agents/technical-auditor.md`
  - `AI_Brain/agents/testing-architect.md`
- **Update CLAUDE.md** agent table (Step 2) — add rows for both new agents.
- **Create `AI_Brain/memory/deployment-config.md`** (Step 3 of plan).
- **Update `AI_Brain/memory/testing-strategy.md`** (Step 3 of plan).
- **Fix P0 security issues** identified in Phase 2 audit (particularly SEC-PPT-001, SEC-FBK-001/002).
- **Fix BUG P0 issues** — missing methods on live routes (BUG-HST-001 through 004, BUG-LIB-010).
- **Workspace fix** — last 2 folders in Prime-AI_Main.code-workspace don't exist on disk:
  - `/Users/bkwork/Herd/tarun_prime_context` (missing)
  - `/Users/bkwork/Herd/prime_testing` (missing — prime_testing app not yet created on disk)

---

## 9. OPEN QUESTIONS & TODOS

- [ ] Create `AI_Brain/agents/technical-auditor.md` (full content is in New_Agent_Creation_plan.md, Section "Agent 1")
- [ ] Create `AI_Brain/agents/testing-architect.md` (full content is in New_Agent_Creation_plan.md, Section "Agent 2")
- [ ] Add 2 rows to CLAUDE.md agent table: `"act as Technical Auditor"` and `"act as Testing Architect"`
- [ ] Create `AI_Brain/memory/deployment-config.md`
- [ ] Update `AI_Brain/memory/testing-strategy.md` with 4-layer test pyramid and tenant context rules
- [ ] Fix SEC-PPT-001 — Gate::define() in ParentResultController overwrites PHP-FPM worker gate permanently
- [ ] Fix SEC-FBK-001/002 — Feedback module: 9/10 controllers unauthed + eligibility never called
- [ ] Fix BUG-HST-001 to BUG-HST-004 — missing methods on live routes in Hostel
- [ ] Fix BUG-LIB-010 — 9 missing methods in Library controllers (all 500 in production)
- [ ] Fix DEAD-DSH-001 — 8 Dashboard controllers return hardcoded dummy data
- [ ] Create prime_testing Laravel app at `/Users/bkwork/Herd/prime_testing` (path in workspace but dir missing)
- [ ] Create `/Users/bkwork/Herd/tarun_prime_context` or remove from workspace file
- [?] Should Technical_Auditor also audit the global_db and prime_db DDL files (not just tenant_db)? Not yet decided.
- [?] Should the audit workflow be run periodically on a schedule (e.g., after each sprint)? No decision made.

---

## 10. IMPORTANT CONTEXT FOR FUTURE SESSIONS

**Multi-tenant DB architecture:** 3 databases — `global_db` (shared reference), `prime_db` (SaaS/billing), `tenant_db` (per-school). All tenant module code lives in `LARAVEL_REPO=/Users/bkwork/Herd/prime_ai/Modules/`.

**Key path variables** (from `AI_Brain/config/paths.md`):
- `OLD_REPO` = `/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db`
- `LARAVEL_REPO` = `/Users/bkwork/Herd/prime_ai`
- `AI_BRAIN` = `{OLD_REPO}/AI_Brain`

**Agent system:** Agents are markdown files in `AI_Brain/agents/`. Activated by saying "act as X". No code deployed. Claude reads the file and adopts the role.

**Issue codes:** Never reuse existing codes. Always `grep -n "SEC-PREFIX\|BUG-PREFIX"` in known-issues.md to find the max code number before assigning new ones.

**prime_testing app specifics:**
- Standalone Laravel app (NOT a module inside prime_ai)
- Table prefix: `tst_`
- `tst_users` PK is `code VARCHAR(5)`, NOT an integer `id`
- All "by" columns throughout the schema are `VARCHAR(5)` referencing `tst_users(code)`
- Transaction tables: composite PK `(id, user_code)` — solves multi-developer id collision
- Catalog tables: simple INT PK (same data on all machines)

**Module count as of 2026-06-22:** 45 modules total (5 central + 40 tenant).

**Phase 2 audit top P0 findings (not yet fixed):**
1. SEC-PPT-001 — ParentResultController Gate::define permanently corrupts PHP-FPM worker process
2. SEC-FBK-001 — Feedback 9/10 controllers have zero Gate::authorize
3. SEC-FBK-002 — FbkEligibilityService injected but never called (eligibility bypassed)
4. BUG-HST-001 to 004 — Hostel: 4 live routes → fatal 500 (methods don't exist)
5. BUG-LIB-010 — Library: 9 live routes → fatal 500 (methods don't exist)

---

## 11. DEPENDENCIES & CROSS-MODULE REFERENCES

- **prime_testing app** — standalone; imports module/menu/tab structure from prime_ai codebase. No FK to prime_ai databases; data synced via export/import mechanism (FR-20).
- **Technical_Auditor agent** — reads `known-issues.md`, `progress.md`, `modules-map.md`, `conventions.md`. Writes new issue codes to `known-issues.md` and updates `progress.md`.
- **Testing_Architect agent** — reads `testing-strategy.md`, `known-issues.md`, `progress.md`. Writes test files to `LARAVEL_REPO/tests/`. Reads module routes from `LARAVEL_REPO/Modules/*/routes/`.
- **Phase 2 findings** feed into the `Technical_Auditor` workflow scope (existing issues to re-check in future audits).
- `tst_test_runs.run_id` (VARCHAR 64) is the anchor for catalog-table FKs that can't use composite PKs.

---

## 12. CONVERSATION HIGHLIGHTS — RAW NOTES

**Composite PK rationale quote (user requirement):**
> "multiple devs on localhost, composite PK PRIMARY KEY (id, user_id) for transaction tables"
> "tst_users PK is code VARCHAR(5) (NOT id). All 'by' columns must be VARCHAR(5) referencing tst_users(code)"

**Phase 2 top findings — exact severity/codes:**
```
SEC-PPT-001  P0  Gate::define permanently overwrites tenant.hpc.view for PHP-FPM worker lifetime
SEC-FBK-001  P0  Zero Gate::authorize in 9/10 Feedback controllers
SEC-FBK-002  P0  FbkEligibilityService injected but never called
BUG-HST-001  P0  VisitorLogController::storeMedia/destroyMedia missing → fatal 500
BUG-HST-002  P0  MessOptOutController::approve/reject missing → fatal 500
BUG-HST-003  P0  MessBillController::publish missing → fatal 500
BUG-HST-004  P0  RoomReservationController::confirm/cancel missing → fatal 500
BUG-LIB-010  P0  9 missing methods in Library → all 500
PERF-HST-001 P1  HostelOccupancyReportService N+1: 400+ queries/page (10 floors × 20 rooms)
PERF-BEH-003 P1  bulkRate() 600 queries for 30 students × 10 criteria
PERF-DSH-001 P1  24 Schema::getColumnListing + 24 COUNT queries per dashboard page load
```

**Module completion after Phase 2 audit:**
```
Feedback            28%
Dashboard           30%
SchoolSetup         35%
Library             42%
ParentPortal        45%
CommonChat          48%
Ptm                 55%
MarksheetGeneration 52%
BehaviouralAssessment 58%
Hostel              58%
```

**New agent trigger phrases to add to CLAUDE.md:**
```
"act as Technical Auditor" → AI_Brain/agents/technical-auditor.md
"act as Testing Architect" → AI_Brain/agents/testing-architect.md
```

**Workflow run ID for Phase 2 audit:** `wf_621fe33c-b57`
(Script at: `.claude/projects/.../workflows/scripts/phase2-quality-audit-wf_621fe33c-b57.js`)
(Can be resumed with: `Workflow({scriptPath: "...", resumeFromRunId: "wf_621fe33c-b57"})`)

---
*End of Context Save*
