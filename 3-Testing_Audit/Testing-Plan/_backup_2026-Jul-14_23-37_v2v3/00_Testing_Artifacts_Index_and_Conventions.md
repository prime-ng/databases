# Prime-AI Testing — Artifacts Index & Conventions

**Owner:** QA / Testing Architecture
**Last updated:** 2026-07-09
**Applies to:** All modules of the Prime-AI application (`prime_ai`), tested via the `prime_testing` Dusk runner.

This document is the **single source of truth for conventions** shared by humans and the `Testcase_Creator` agent. Read it first. The Strategy Report (`01_`), the Testing Plan (`02_`), and the Agent Prompt (`03_`) all reference the rules defined here.

---

## 1. Repository & Path Map

| Variable | Path | Purpose |
|----------|------|---------|
| `OLD_REPO` | `/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db` | Requirements, FRDs, DDLs, Audits (the "knowledge base") |
| `APP_REPO` | `/Users/bkwork/Herd/prime_ai` | Application source code (Laravel modules) |
| `TEST_FILE_REPO` | `/Users/bkwork/Herd/prime_testing` | Dusk test runner (where all test artifacts live) |
| `REQUIRE_DETAIL_V1` | `{OLD_REPO}/4-Requirement_Module_wise/2-Module_Requirement_V1/[MODULE]*` | Module requirement docs (V1) |
| `FRD_DIR` | `{OLD_REPO}/4-Requirement_Module_wise/0-FRD_Documents` | FRD documents (per 3-letter code) |
| `MODULE_DDL_DIR` | `{OLD_REPO}/2-DDL_Tenant_Consolidated` | Consolidated tenant DDL (schema) — **v-latest files only** |
| `AUDIT_REPORT_DIR` | `{OLD_REPO}/3-Audit_Reports/V1_Jun-2026/[MODULE]*` | Module technical audit reports (known defects) |
| `APP_CODE_DIR` | `{APP_REPO}/Modules/[MODULE]*` | Controllers, Requests, Models, Routes, Views |
| `SAMPLE_TESTCASE_FILES` | `{TEST_FILE_REPO}/tests/Browser/Modules/Class&SubjectMgmt/Classes/*` | Golden reference (Class feature) |
| `TEST_OUTPUT_ROOT` | `{OLD_REPO}/3-Testing_Audit/TestCases/{Module}/` | **Every output lives under a per-module folder here, and nowhere else** — never write into `TEST_FILE_REPO`, `APP_REPO`, or elsewhere. See the mandatory folder structure below. |
| `PLAN_ROOT` | `{OLD_REPO}/3-Testing_Audit/Testing-Plan` | This planning folder |

> **Golden reference:** `Class&SubjectMgmt/Classes/` is the canonical example. Every new feature's artifacts must match its structure, depth, and idioms. The `HrStaff/*` folders are the most recent real-world application of the pattern (23 features) and add the `Validation_Report.md` + dual runner (`.ps1` + `.sh`) evolution.

### 1.1 Mandatory Output Folder Structure (every output, every time)

**Rule:** the FIRST thing any run does is **resolve a module folder name once** (using the collision rule below), then write everything for that run **inside that one module folder** — never at the `TestCases/` root, never anywhere else.

#### Module-folder collision rule (never overwrite an existing module folder)

Resolve the module folder name **once per invocation**, in this order, and use the first name that does **not** already exist:

1. `TestCases/{Module}/`
2. if that exists → `TestCases/{Module}_{YYYY-MMM-DD}/`  (e.g. `BehaviouralAssessment_2026-Jul-09`)
3. if that also exists → `TestCases/{Module}_{YYYY-MMM-DD}_{HH-MM}/`  (e.g. `BehaviouralAssessment_2026-Jul-09_14-30`, 24-hour clock)

- **Date/time format:** `YYYY-MMM-DD` = 4-digit year, 3-letter month (`Jan`…`Dec`), 2-digit day; `HH-MM` = 24-hour hour and minute, zero-padded.
- Resolve the name **at the start of the run and reuse it for every file in that run** — do not re-evaluate per feature (all of a run's features/inventory/reports land in the same resolved module folder).
- The resolved folder is treated as `{ModuleFolder}` everywhere below (`{ModuleFolder}/{Feature}/…`). Feature sub-folders are created fresh inside it as normal.
- Rationale: each generation run is preserved as an immutable, timestamped snapshot; a prior run's artifacts are never overwritten or mixed with a new run's.

Then everything for that run is written **inside `{ModuleFolder}`**:

```
{OLD_REPO}/3-Testing_Audit/TestCases/
└── {Module}/                                   ← ALWAYS create/reuse this module folder first
    ├── {Module}_Feature_Inventory.md           ← module-level docs live at the module-folder root
    ├── {Module}_Coverage_Dashboard.md          ← (report mode)
    ├── {Module}_RTM.md                          ← (report mode)
    ├── {Feature}/                               ← one sub-folder per feature/screen
    │   ├── {prefix}_{Feature}TcList_Require.md
    │   ├── {prefix}_{Feature}MANUALTESTING_Require.md
    │   ├── {prefix}_{Feature}GAPANALYSIS_Require.md
    │   ├── {prefix}_{Feature}_TestCas.php        ← ONE comprehensive test file per screen (no V1/V2 split)
    │   ├── {prefix}_{Feature}Validation_Report.md
    │   ├── run-{Feature}-tests.ps1
    │   └── run-{Feature}-tests.sh
    └── {Feature2}/ ...
```

- **Module-level outputs** (Feature Inventory, module Coverage Dashboard, module RTM) → directly in `TestCases/{Module}/`.
- **Per-feature outputs** (the 7 artifacts) → in `TestCases/{Module}/{Feature}/`.
- **Program-level roll-ups** that genuinely span modules (Program Defect Register, Program Test Summary) → `TestCases/_Program/` (the one reserved non-module folder).
- Create the module (and feature) folders if missing. Nothing is ever written to the bare `TestCases/` root.

---

## 2. Module Registry

The app has **45 modules**. Each module contains one or more **features**. Artifacts are generated **per feature**, grouped under the module folder.

### 2.0 Feature = Screen = one Requirement file (authoritative unit)

**The unit of work is a *screen*, and each screen is defined by exactly one requirement file** in `REQUIRE_DETAIL_V1/{MODULE}_v1/`. One requirement file → one screen → one feature → one 7-artifact set (with a single test file).

- The requirement folder `{OLD_REPO}/4-Requirement_Module_wise/2-Module_Requirement_V1/{MODULE}_v1/` holds one kebab-case `.md` file **per screen** (e.g. `Accounting_v1/` has 12 files → 12 screens/features: `bank-reconciliation.md`, `chart-of-accounts.md`, `vouchers.md`, …).
- **Feature discovery = list these files.** Each file is the *primary requirement source* for that screen's artifacts, and drives BC-BIZ (business rules, statuses, user stories) and the manual test cases.
- **Screen file → feature name** (PascalCase): strip `.md`, split on `-`, PascalCase-join. `leave-types.md` → `LeaveType`(s), `bank-reconciliation.md` → `BankReconciliation`, `chart-of-accounts.md` → `ChartOfAccounts`. Singularise the head noun to match the primary DDL table where sensible; when the app Controller/route uses a different name, prefer the app's name and note the alias.
- **Not every file is a CRUD screen.** Report/dashboard/composite screens (e.g. `reports-dashboard.md`, `reports.md`) get a lighter, read-focused artifact set (no create/edit/delete matrix — assert render, filters, export, permissions, empty state). Non-screen docs (e.g. `implementation-plan.md`) are **not** features — skip them and note the skip in the Feature Inventory.
- The **primary DDL table + Controller** for each screen are resolved from the module's DDL and `APP_CODE_DIR/{Module}` and recorded alongside the screen in the Feature Inventory.

> The `{MODULE}_v1` folder is the **canonical feature list** for a module. The DDL and controllers refine/confirm it, but the count of screens comes from the requirement files.

| Module (app folder) | FRD code(s) | Primary DDL file | Table prefix(es) | Notes |
|---------------------|-------------|------------------|------------------|-------|
| Accounting | ACC | `Accounting_DDL_v3.sql` | `acc_` | |
| Admission | ADM | `Admission_DDL_v1.sql` | `adm_` | |
| BehaviouralAssessment | BHA | `BehaviouralAssess_DDL_v2.sql` | `bha_` | |
| Billing | BIL | `Billing_DDL_v1.sql` | `bil_` | |
| Cafeteria | CAF | `Cafeteria_DDL_v1.sql` | `caf_` | |
| Certificate | CRT | `Certificates_DDL_v1.sql` | `crt_` | |
| CommonChat | COM | `CommonChat_DDL_v1.sql` | `com_` | |
| Complaint | CMP | `Complaint_DDL_v2.sql` | `cmp_` | |
| Dashboard | DSH | — | — | Composite/read-only |
| Documentation | DOC | `Template_DDL_v5.sql` | `doc_` | |
| EventEngine | EVT | — | `evt_` | |
| Feedback | FBK | — | `fbk_` | |
| FrontOffice | FOF | `FrontOffice_DDL_v1.sql` | `fof_` | |
| GlobalMaster | GLB | `_global_db_v4.sql` | `glb_` | Cross-cutting (activity logs, dropdowns) |
| Hostel | HST | `Hostel_DDL_v4.sql` | `hst_` | |
| Hpc | HPC | `HPC_DDL_v2.sql` | `hpc_` | |
| HrStaff | HRS, PAY | `HrStaff_Payroll_DDL_v2.sql` | `hrs_`, `pay_` | Payroll tables use `pay_` |
| Inventory | INV | `Inventory_DDL_v1.sql` | `inv_` | |
| Library | LIB | `Library_ddl_v7.sql` | `lib_` | |
| LmsExam | EXM | `LmsExam_DDL_v6.sql` | `exm_` | |
| LmsHomework | HMW | `LmsHomework_DDL_v5.sql` | `hmw_` | |
| LmsQuests | QST | `LmsQuest_DDL_v2.sql` | `qst_` | |
| LmsQuiz | QUZ | `LmsQuiz_DDL_v2.sql` | `quz_` | |
| MarksheetGeneration | MSH | `MarksheetGeneration_DDL_v1.sql` | `msh_` | |
| Notification | NTF | `Notification_DDL_v3.sql` | `ntf_` | |
| ParentPortal | PPT | `ParentPortal_DDL_v2.sql` | `ppt_` | |
| Payment | PAY | `StudentFee_DDL_v4.sql` | `pay_`/`fin_` | |
| Prime | PRM | `_prime_db_v4.sql` | `sys_`, `prime` | Central DB / tenancy |
| Ptm | PTM | `PTM_DDL_v3.sql` | `ptm_` | |
| QuestionBank | QNS | `LmsQuestionBank_DDL_v1.4.sql` | `qns_` | |
| Recommendation | REC | `Recommendation_DDL_v1.6.sql` | `rec_` | |
| Scheduler | SCO | — | `sco_` | |
| SchoolSetup | SCH | `SchoolSetup_DDL_v3.sql` | `sch_`, `csm_` | Class&Section uses `csm_`/`sch_` |
| SmartTimetable | — | `Timetable_DDL_v7.8.sql` | `tt_` | |
| StandardTimetable | — | `Timetable_DDL_v7.8.sql` | `tt_` | |
| StudentFee | FIN | `StudentFee_DDL_v4.sql` | `fin_` | |
| StudentPortal | SCO | `StudentPortal_DDL_v4.sql` | `stp_` | |
| StudentProfile | — | `StudentProfile_DDL_v1.6.sql` | `std_` | |
| Syllabus | — | `Syllabus_DDL_v1.1.sql` | `syl_` | |
| SyllabusBooks | — | `SyllabusBooks_DDL_v3.sql` | `syb_` | |
| SystemConfig | GLB | `_tenant_db_v4.sql` | `sys_` | |
| Template | — | `Template_DDL_v5.sql` | `tpl_` | |
| TimetableFoundation | FOF | `Timetable_DDL_v7.8.sql` | `tt_` | |
| Transport | — | `Transport_DDL_v2.3.sql` | `trn_` | |
| Vendor | — | `Vendor_DDL_v2.1.sql` | `ven_` | |

> **Prefix resolution rule (authoritative):** the **file prefix equals the DDL table prefix of the feature's primary table** (e.g. `hrs_`, `pay_`, `lib_`, `sch_`). Confirm by opening the DDL and reading the `CREATE TABLE` name. The legacy `csm_` prefix (Class&Subject Mgmt grouping) predates this rule; new work follows the table-prefix rule. Always verify against the DDL — never guess. This table is a starting map, not a substitute for reading the actual DDL/audit filenames per run.

---

## 3. The 7-Artifact Contract (per feature)

For every feature, the agent produces **exactly these files** in `TEST_OUTPUT_ROOT`. **There is exactly ONE PHP test file per screen** — the old V1/V2 pair is gone (the golden `Class` reference only had two because that feature was authored twice; that was never the standard).

| # | Filename | Type | Purpose |
|---|----------|------|---------|
| 1 | `{prefix}_{Feature}TcList_Require.md` | Requirements | Business Conditions (BC-*) + Test Case List (TC-P/N/D) + Test Method Index |
| 2 | `{prefix}_{Feature}MANUALTESTING_Require.md` | Manual test spec | Feature info + full BC + step-by-step manual test cases (Step/Action/Expected + DB + activity-log checks) |
| 3 | `{prefix}_{Feature}GAPANALYSIS_Require.md` | Coverage | Manual TC ↔ Dusk method mapping + coverage % + partial/gap list |
| 4 | `{prefix}_{Feature}_TestCas.php` | Dusk (single comprehensive suite) | Schema/model/request config truth (opening `test_01`) **plus** full coverage of every TC-P/N/D/SM/T/S + rich private helper library — one file, sized to the screen (commonly 40–80 methods) |
| 5 | `{prefix}_{Feature}Validation_Report.md` | QA gate | File existence, naming, structure, coverage, known-defect, verdict |
| 6 | `run-{Feature}-tests.ps1` | Runner (Windows) | Filtered Dusk run + result parsing + proof capture |
| 7 | `run-{Feature}-tests.sh` | Runner (Linux/WSL) | Same, for bash environments |

**Produced in TWO PHASES (token discipline — see `03_` §"Two-Phase Generation & Model Routing"). Still exactly 7 artifacts; only the production is split into 2 passes:**
- **Phase 1 (reasoning-heavy, strong model):** do the BC/TC analysis and write **artifact 4 — the `_TestCas.php` — FIRST, and flush it to disk before anything else** (crash-resilience: a killed run keeps the expensive artifact). Nothing else is written in Phase 1.
- **Phase 2 (mechanical, cheaper model):** read the finished `.php` and derive the other **6 docs 1:1 from it** (artifacts 1, 2, 3, 5, 6, 7). Phase 2 MUST NOT modify the `.php`.

**Generation order:** *Phase 1:* analysis → **4 (the test file, flushed first)**; *Phase 2 (from the finished `.php`):* 1 → 2 → 3 → 5 → 6/7. (The docs are mechanically derivable from the `.php` — proven by the crash-recovery docs-only runs — so they do not need the strong model.)

See `03_Testcase_Creator_Agent_Prompt.md` §"Artifact Templates" for the required internal structure of each file, and §"Two-Phase Generation & Model Routing" for the phase boundary and per-phase model tags.

### 3.1 Token discipline (prompt caching & doc de-duplication)
**Prompt caching (keep prefixes cache-warm):** the large read-only prefixes — this conventions doc, `03_` (the agent prompt), `05_` (constraints), and the sibling reference `.php` — should stay **byte-stable during a generation batch** and features should run **back-to-back**, so those prefixes stay in the prompt cache (cached reads ≈ 0.1× input price vs full). **Do NOT edit `00_`/`03_`/`05_`/the reference `.php` mid-batch** — an edit invalidates the cache and forces every subsequent feature to re-read them at full price. Also reuse the module **Fact Pack** (Lever 2) so per-feature discovery isn't re-paid.

**Doc de-duplication (cut the most duplicative output):** TcList, MANUALTESTING, and GAPANALYSIS otherwise each re-enumerate all ~50 methods. **MANUALTESTING should REFERENCE the TcList method table rather than restate every method step-by-step** — keep full Step/Action/Expected tables only where a manual tester genuinely needs them (complex multi-step flows, money paths, workflow transitions), and for simple CRUD/validation cases point to the TcList row + the one-line expected result. This trims output on the most duplicative artifact **without dropping any coverage** — every TC still appears in TcList and is still mapped in GAPANALYSIS.

---

## 4. Naming & Structure Conventions

- **Feature folder:** PascalCase (`SalaryComponent`, `LeaveApplication`, `Classes`).
- **File prefix:** DDL table prefix + `_` (§2 rule).
- **PHP class name = filename** (no `.php`): `class pay_SalaryComponent_TestCas extends DuskTestCase`.
- **Namespace:** always `namespace Tests\Browser;`.
- **Test methods:** snake_case, zero-padded, sequential: `test_{feature}_{NN}_{short_description}` (e.g. `test_class_07_status_toggle_endpoint_updates_is_active`).
- **One test file per screen; coverage-gated, not ratio-gated.** No V1/V2 split and no "≥ 2×" method ratio. The single file must meet the coverage gates (Negative 100%, Positive ≥ 90%, Dependency ≥ 90%, Tenancy 100% on P0/P1), checked in the Validation Report, which states the total method count.
- **Every TC-ID** in the TcList must map to at least one test method; every test method maps back to a TC-ID or a BC.
- **Screenshots/console/source** are auto-routed per-feature by `DuskTestCase::resolveReportBase()` into `{Feature}/dusk-report/{screenshots,console,source}` — do **not** hardcode a screenshot path; use the base class + the `capturePassScreenshot`/`captureFailureScreenshot` helpers.

---

## 5. Test Case Taxonomy

| Class | ID prefix | Covers |
|-------|-----------|--------|
| **Positive** | `TC-P##` | Happy-path CRUD, list/search/filter, endpoints, breadcrumbs, auto-behaviours (auto-name, auto-ordinal, toast) |
| **Negative** | `TC-N##` | Required/format/length/range validation, duplicates, invalid IDs (404), auth (403), guest redirect, XSS/whitespace, cross-field rules |
| **Dependency** | `TC-D##` | Referential integrity + cross-module + lifecycle + concurrency. Sub-categorised A–G below |

**Dependency sub-categories (A–G):**
- **A** — Inactive-record impact on dependent displays/dropdowns
- **B** — Soft-delete / force-delete data preservation & cascade
- **C** — FK `RESTRICT` (delete blocked while referenced)
- **D** — FK `SET NULL` (reference nullified on parent delete)
- **E** — Cross-module impact (this feature ↔ other modules)
- **F** — Full lifecycle & multi-step flows (create→edit→toggle→delete→restore→forceDelete)
- **G** — Race conditions, concurrent edits, edge/boundary uniqueness

---

## 6. Business Condition (BC) Taxonomy

Every requirement is decomposed into typed, ID'd Business Conditions so tests are traceable:

| BC prefix | Meaning | Source |
|-----------|---------|--------|
| `BC-DB-##` | Column/type/constraint per table | DDL |
| `BC-VAL-##` | Validation rule + error message | FormRequest in `APP_CODE_DIR` |
| `BC-AUTH-##` | Permission gate ↔ controller method | Policy/gate + Controller + requirement permission matrix |
| `BC-BIZ-##` | Business logic / auto-behaviour / activity-log event | Controller/Service/Model/Observer + Requirement |
| `BC-SM-##` | **State-machine transition** (State → Trigger → Next State) | Requirement state machine + Controller/Service |
| `BC-INT-##` | **Integration point** (cross-module dependency / FK to another module) | Requirement integration points + DDL FKs |
| `BC-REF-##` | FK column → referenced table → onDelete behaviour | DDL |
| `BC-AUTO-##` | Cross-module auto-update (model events) | Model observers |
| `BC-EDG-##` | **Edge case / boundary** not covered by the above | Requirement edge cases + DDL limits |
| `BC-CFG-##` | **Configuration / settings** behaviour | Config tables + `Config/config.php` + requirement |

- `BC-DB / VAL / AUTH / BIZ / REF / AUTO` are **always** produced. Add `BC-SM` for any feature with a workflow/status lifecycle (e.g. Draft→Submitted→Approved, open→locked→closed). Add `BC-INT / EDG / CFG` when the feature has cross-module dependencies, notable boundaries, or config-driven behaviour. Report/dashboard screens lean on `BC-AUTH / BC-UIX-style render checks`.

**Traceability chain:** **Requirement/FRD/Screen §(Source tag) → BC-xx → TC-P/N/D/T/S → test_method() → (optional) DEV-###/audit-equivalent defect.**

**`Source` tag convention (WP-F):** every BC and TC carries a `Source` cell tracing it back to the exact origin section, so coverage is auditable. Use short codes: `Screen-BR-3` (screen requirement Business Rule #3), `Screen-SM-2` (State-Machine row 2), `Screen-VR-5` (Validation Rule 5), `Screen-IP-3` (Integration Point 3), `Screen-PM-2` (Permission-Matrix row 2), `DDL-<table>`, `Req-<§>`, `FRD-<§>`, `Audit-<ID>`. (For multi-tab supplementary docs, use `TabN-BR-M` etc.)

---

## 7. Known Environment Facts (for test authoring)

> ⚠️ **These are Class-reference examples, not universal law. Verify every one against the feature's real source.** The Phase-0 dry run proved conventions vary by module: `HrStaff` uses `sys_activity_logs` with events `Created/Updated/Trashed/Restored/Deleted` (not `Stored/Update/ToggelStatus`) and `hrs.*` permissions (not `tenant.*`). Read the actual Controller/Policy/Model/Observer and assert the **real** strings.

- **Test style is per-feature — detect it, don't assume.** Some features (the `Class` golden reference) are tested with **browser Dusk** (`extends DuskTestCase`, real Chrome). Others (the committed `HrStaff` features) use **HTTP feature tests** (`actingAs` + `DatabaseMigrations`/`initTenant`, no browser). Before generating, inspect the module's existing committed tests (in `TEST_FILE_REPO`) to choose the matching style; mirror the nearest sibling feature in the **same module**, falling back to the golden reference only when the module has no precedent.
- **Stack:** Laravel 11 + `laravel-modules` (`Modules/{Module}/...`) + `stancl/tenancy` multi-tenancy + AdminLTE/Blade + Alpine.js + SweetAlert + AJAX modals.
- **Test base URL:** `http://test.localhost:8000` (env `DUSK_TENANT_URL` → `APP_URL`).
- **Admin creds:** `DUSK_ADMIN_EMAIL` (`root@tenant.com`) / `DUSK_ADMIN_PASSWORD` (`password`).
- **Runner needs `prime_ai` cloned alongside** and `MAIN_PROJECT_PATH` set (see `{TEST_FILE_REPO}/TEST_SETUP.md`).
- **Databases:** `global_master`, `prime_db` (tenant template), `test_runner_db`.
- **Permission gates:** `tenant.{resource}.{viewAny|view|create|update|delete|restore|forceDelete|status}`.
- **Activity-log events:** `Stored`, `Update`, `Delete`, `Restored`, `ForceDelete`, `ToggelStatus` (note the intentional typo — assert the literal string).
- **UX conventions:** 10/page pagination; green success toast; SweetAlert confirms for edit/delete/restore/force-delete; modal + AJAX CRUD (no separate create/edit pages for most features).
- **Cross-module tests** must be defensive: wrap in `try/catch` and `markTestSkipped()` when a dependency module/table is absent, so the suite stays green in partial environments.

---

## 8. Deliverables in this folder

| File | What it is |
|------|-----------|
| `00_Testing_Artifacts_Index_and_Conventions.md` | **This file** — shared conventions, module registry, artifact contract |
| `01_Testing_Strategy_Report.md` | The strategy: scope, risk model, test dimensions, coverage goals, additions beyond the sample, metrics |
| `02_Testing_Plan.md` | The plan: phased rollout, per-feature workflow, sequencing, tracking, exit criteria, CI |
| `03_Testcase_Creator_Agent_Prompt.md` | The deployable system prompt for the `Testcase_Creator` agent |
| `05_Known_Test_Failure_Constraints.md` | Verified guardrails the agent must obey when writing PHP (tenancy, User/factory, soft-delete, assertions, env prerequisites) |
