# Context: Build the "Testcase_Creator" AI agent + Testing Strategy/Plan, then enhance it from a peer OpenCode agent
# Saved: 2026-07-09 13:59
# Session Duration: Full session — from "create a Testcase_Creator agent" through 3-phase enhancement completion
# Project: PrimeAI

---

## 1. SESSION OBJECTIVE
Create an AI agent **"Testcase_Creator"** that generates all testing artifacts (Testcase Requirements, Test Case List, Test Cases, PHP Dusk test scripts, gap analysis, validation reports, runners) for every module of the Prime-AI app. Deliver a Testing Strategy Report, a Testing Plan, and the deployable agent prompt. Then: install the agent, run dry-runs, refine output rules, produce a Feature Inventory for a module, compare against a team member's OpenCode agent, and safely enhance the agent with the peer's best ideas (Phases 1–3).

## 2. SUMMARY OF WORK DONE
- Studied the golden reference test artifacts (`Class&SubjectMgmt/Classes/`) and the HrStaff evolution (23 features) to reverse-engineer the **8-artifact-per-feature contract**.
- Wrote 4 planning docs (`00_`–`04_`) + later `05_` in `…/3-Testing_Audit/Testing-Plan/`.
- Installed the agent as a **loader** at `~/.claude/agents/testcase-creator/AGENT.md` (deferring to `03_` as single source of truth), following the user's existing `pa-*` agent convention.
- Ran Phase-0 dry run (HrStaff/LeaveType) → discovered HrStaff uses **HTTP feature tests** (not browser Dusk), `sys_activity_logs` events `Created/Updated/Trashed`, `hrs.*` permissions — so conventions vary per module.
- Established **"Feature = Screen = one requirement file"** model (each `.md` in `{MODULE}_v*/` = one feature).
- Set output rule: everything under `TestCases/{Module}/…`, **module-folder-first**, **never overwrite** (timestamped `{Module}_YYYY-MMM-DD[_HH-MM]`).
- Produced the **BehaviouralAssessment Feature Inventory** (25 screens → 24 features, prefix `bha_`, saved into `TestCases/BehaviouralAssessment/`).
- Read the team member's OpenCode agent (`prime-test-creator`, 1166-line AGENT.md) and wrote a **comparison report**.
- Wrote a safe **enhancement plan**, then executed it: Gate 0 backup → verification harness → Phase 1 → Phase 2 → Phase 3.
- **Verify-before-encode harness caught 3 factual errors** in the peer's constraints (see §7).
- Phase-1 dry run (Gate 4) validated the enhanced agent and caught 1 error in our own constraint (App\Models\User).

## 3. FILES TOUCHED
### Created:
- `…/3-Testing_Audit/Testing-Plan/00_Testing_Artifacts_Index_and_Conventions.md` — shared conventions, module registry, 8-artifact contract, folder structure, BC/TC taxonomy, env facts.
- `…/3-Testing_Audit/Testing-Plan/01_Testing_Strategy_Report.md` — strategy: scope, pyramid, dimensions, enhanced dimensions, risk tiers, metrics, DoD.
- `…/3-Testing_Audit/Testing-Plan/02_Testing_Plan.md` — execution: per-feature workflow, phased rollout, sequencing, CI, exit criteria.
- `…/3-Testing_Audit/Testing-Plan/03_Testcase_Creator_Agent_Prompt.md` — **THE deployable agent prompt** (single source of truth). Has frontmatter (`name: Testcase_Creator`).
- `…/3-Testing_Audit/Testing-Plan/04_Agent_Usage_Commands.md` — command cookbook (how to invoke the agent for all task types).
- `…/3-Testing_Audit/Testing-Plan/05_Known_Test_Failure_Constraints.md` — **verified guardrails** (tenancy/User/factory/soft-delete/assertions/env). Agent reads before writing PHP.
- `~/.claude/agents/testcase-creator/AGENT.md` — the installed loader agent (registered subagent type `testcase-creator`).
- `…/3-Testing_Audit/TestCases/BehaviouralAssessment/BehaviouralAssessment_Feature_Inventory.md` — 24-feature inventory + generation order + audit-defect map.
- `…/3-Testing_Audit/Testing_Prompt/Comparison_Report_TeamAgent_vs_TestcaseCreator.md` — capability comparison.
- `…/3-Testing_Audit/Testing_Prompt/Enhancement_Plan_TestcaseCreator_from_TeamAgent.md` — the safe 3-phase plan (WP-A..H, gates, rollback).
- `…/3-Testing_Audit/Testing_Prompt/Phase1_Verification_Harness_Results.md` — evidence table (encode/don't-encode decisions) + Gate-4 correction.
- `…/3-Testing_Audit/Testing-Plan/_backup_2026-Jul-09/` — Gate-0 snapshot of docs 00–04 (rollback point).

### Modified:
- `03_…Agent_Prompt.md` — Phase 1: added `05_` pointer (Hard Rule 13), Service-layer read (Step 1 3b), Cross-Reference Defect Scan (Step 8, 11 checks), prime/tenant scope (Step 1 + Rule 13). Phase 2: `BC-SM`/INT/EDG/CFG (Step 2), Source tags + TcList columns (Step 4), semantic V2 numbering bands (Step 7), Coverage-Score table (Step 8), quality-gates additions. Phase 3: path auto-correction (Step 1), feedback loop (Step 11b), reconciled output-discipline exception.
- `00_…Conventions.md` — output-folder-first rule + collision/timestamp rule; screen=feature §2.0; per-feature test-style caveat (§7); expanded BC taxonomy + Source tags (§6); added `05_` to deliverables index.
- `~/.claude/agents/testcase-creator/AGENT.md` — output discipline, module-folder-first, never-overwrite, `05_` pointer, feedback-loop exception.

### Discussed/Reviewed (not modified):
- `prime_testing/tests/Browser/Modules/Class&SubjectMgmt/Classes/*` — golden reference (csm_ prefix, 8 files, V2=78 methods).
- `prime_testing/tests/DuskTestCase.php` — base class (screenshot routing via `resolveReportBase`, auto dev-server; NO init method — tests define their own).
- `prime_testing/tests/Browser/Modules/HrStaff/LeaveType/*` — committed sibling (HTTP style, `initTenant()`, `App\Models\User`, `User::factory()`).
- Team agent: `…/2-New_Primedb/pgdatabase/9-Support/Test Agent/prime-test-creator/*` (AGENT.md 1166 lines + README + 7 templates).

## 4. KEY DECISIONS & RATIONALE
- **Decision:** Feature = Screen = one requirement file (`{MODULE}_v*/*.md`). **Why:** matches the user's actual requirement folder structure; the peer's controller-scan would skip report/dashboard screens. **Alternatives:** controller-based scan (rejected — under-counts).
- **Decision:** Output = `TestCases/{Module}/`, module-folder-first, never-overwrite with `{Module}_YYYY-MMM-DD[_HH-MM]`. **Why:** user explicitly required it; preserves immutable timestamped snapshots.
- **Decision:** Install agent as thin loader deferring to `03_`. **Why:** matches user's `pa-*` "knowledge in ONE place / AI_Brain single source of truth" convention.
- **Decision:** Verify-before-encode every peer constraint. **Why:** caught 3 false claims that would have generated broken tests.
- **Decision:** Keep the peer's *content* (constraints, gap checks, taxonomy) but NOT his *workflow shell* (controller-scan, interactive inputs, vendor-neutral format). **Why:** user's screen-model + output governance + strategy layer are stronger.
- **Decision:** Feedback loop is the ONLY permitted write outside `OUTPUT_ROOT` (append to `05_`). **Why:** compound constraints over time without breaking output discipline.

## 5. TECHNICAL DETAILS & PATTERNS
- **8-artifact contract per feature:** `{prefix}_{Feature}TcList_Require.md`, `…MANUALTESTING_Require.md`, `…GAPANALYSIS_Require.md`, `…V1_TestCas.php`, `…V2_TestCas.php`, `…Validation_Report.md`, `run-{Feature}-tests.ps1`, `run-{Feature}-tests.sh`.
- **Prefix = DDL table prefix** of the feature's primary table (verify against real `CREATE TABLE`).
- **BC taxonomy:** BC-DB/VAL/AUTH/BIZ/REF/AUTO (always) + BC-SM/INT/EDG/CFG (when applicable). **TC taxonomy:** TC-P/N/D(A–G) + TC-T (tenancy), TC-S (security), TC-A (a11y).
- **V2 ≥ 2× V1** (hard gate). **Semantic V2 numbering bands:** 01–09 schema, 10–19 BR, 20–29 SM, 30–39 VAL, 40–49 INT, 50–59 AUTH, 60–69 UIX, 70–79 EDG, 80–89 CFG, 90–99 tenancy+security.
- **Source tags:** `Screen-BR-3`, `Screen-SM-2`, `Screen-VR-5`, `Screen-IP-3`, `Screen-PM-2`, `DDL-<table>`, `Audit-<ID>`.
- **Detect test STYLE per feature** (browser Dusk vs HTTP feature test) by mirroring the nearest same-module committed sibling; golden `Class` is fallback only.
- **Prime vs Tenant DB** from DDL header (`Database: tenant_db` vs `prime_db`) + prefix → toggles tenancy scaffolding.
- **11-point Cross-Reference Defect Scan** in Gap Analysis (enum-case, route-reg, gate-vs-policy, fillable-vs-DDL, cast-vs-DDL, service-delegation, SM-vs-impl, val-vs-request, msg-vs-request, perms-vs-policy, FK-vs-migration).

## 6. DATABASE CHANGES
None (no schema changes — this session produced test artifacts and agent config only; app/test source untouched).

## 7. PROBLEMS ENCOUNTERED & SOLUTIONS
- **Problem:** Peer constraint "`password` NOT fillable on SchoolSetup User." **Cause:** his-repo-specific. **Solution:** verified FALSE here (`password` IS fillable + `'password'=>'hashed'`); inverted in `05_`.
- **Problem:** Peer constraint "`user_type` doesn't exist in `sys_users`." **Cause:** his-repo-specific. **Solution:** verified FALSE — tenant `sys_users` HAS `user_type ENUM(...) NOT NULL`; inverted in `05_`.
- **Problem:** My own harness said "`App\Models\User` doesn't exist here." **Cause:** I checked the APP repo (`prime_ai`) but tests RUN in the RUNNER repo (`prime_testing`), which DOES have `App\Models\User` (dynamic `$table`→sys_users, has UserFactory) — golden ref + base class + HrStaff sibling all use it. **Solution:** Gate-4 dry run caught it; corrected `05_` §B to default to `App\Models\User` + `User::factory()`, use module User only when a Service/Policy type-hints it.
- **Problem:** Feedback loop (append to `05_`) conflicted with "never write outside OUTPUT_ROOT." **Solution:** reconciled — `05_` append is the single explicit exception in both output rules + loader.

## 8. CURRENT STATE OF WORK
### Completed:
- Testcase_Creator agent built, installed (registered subagent `testcase-creator`), and enhanced through Phases 1–3.
- All planning docs (00–05), usage cookbook, comparison report, enhancement plan, harness-results, Gate-0 backup.
- BehaviouralAssessment Feature Inventory saved in TestCases/.
- 3 dry runs executed to scratch (LeaveType ×2, inventory) — NOT promoted to TestCases (they were validation only).
### In Progress:
- None — enhancement project fully closed at Phase 3 with all gates green.
### Not Yet Started:
- **Real generation of actual feature suites into TestCases/** (nothing beyond the inventory has been generated for real).
- Suggested first real target: BehaviouralAssessment `RatingScale` (Group A master) OR `AssessmentPeriod` (to exercise the new BC-SM state-machine path).

## 9. OPEN QUESTIONS & TODOS
- [ ] Generate the first REAL feature suite into `TestCases/BehaviouralAssessment/` (note: folder exists with inventory → per never-overwrite rule the next run lands in `BehaviouralAssessment_2026-Jul-09/` unless the user wants it in the existing folder — ASK).
- [ ] Decide generation order: Group A masters first (RatingScale→Category→Intervention→AssessmentPeriod→Configuration→ClassMapping), then Group B transactional, then Group C reports.
- [?] Should reports/dashboards (screens 15–24) get the lighter read-only artifact set as planned? (Yes per convention, confirm at generation.)
- [ ] Optional: run a combined Phase1+2 dry run on a workflow feature (AssessmentPeriod) to exercise BC-SM before mass generation.

## 10. IMPORTANT CONTEXT FOR FUTURE SESSIONS
- **Agent invocation:** natural language "Use the testcase-creator agent — module=X, feature=Y" (params: module, feature[screen name kebab/PascalCase], mode[feature|module|report], execute[true|false]). It's a registered subagent type.
- **Single source of truth = `03_Testcase_Creator_Agent_Prompt.md`.** Loader at `~/.claude/agents/testcase-creator/AGENT.md` reads 03_, 00_, 05_, golden reference.
- **Output rule (ABSOLUTE):** `TestCases/{Module}/` module-folder-first; if exists → `{Module}_YYYY-MMM-DD/` → `{Module}_YYYY-MMM-DD_HH-MM/` (real `date`, 24h). Module-level files at module root; per-feature in `{Module}/{Feature}/`; program roll-ups in `TestCases/_Program/`. ONLY exception to "no writes outside OUTPUT_ROOT" = appending to `05_`.
- **modules_statuses.json:** nearly ALL modules are `false` (only Syllabus true) → generated suites need the target module enabled or all routes 404. Document as prerequisite, not a test fix.
- **Verified codebase facts (in `05_`):** `emp_code` VARCHAR(20); `prefered_language`→`glb_languages` (a VIEW); `sys_media` (not `media`); `password` IS fillable; tenant `sys_users` HAS `user_type` ENUM; `App\Models\User` exists in the RUNNER with a factory; tenancy via `Modules\Prime\Models\Domain` host lookup (never `tenancy:init`); Dusk Browser has no `assertStatus()`.
- **Path resolution:** requirement folders are versioned `{MODULE}_v1`/`_v2`/`_V2` — glob `{MODULE}_*`, don't assume `_v1`.
- **Rollback:** `Testing-Plan/_backup_2026-Jul-09/` holds pre-enhancement docs 00–04.
- **User prefers:** verify-before-encode; never modify app/test source; ask before real generation; keep the user's strengths (screen model, output governance) over peer patterns.

## 11. DEPENDENCIES & CROSS-MODULE REFERENCES
- **Repos:** `OLD_REPO`=`/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db`; `APP_REPO`=`/Users/bkwork/Herd/prime_ai`; `TEST_FILE_REPO`=`/Users/bkwork/Herd/prime_testing`.
- **Input paths:** REQUIRE_DETAIL_V1=`{OLD_REPO}/4-Requirement_Module_wise/2-Module_Requirement_V1/{MODULE}_v*/` (one file per screen); FRD_DIR=`{OLD_REPO}/4-Requirement_Module_wise/0-FRD_Documents`; MODULE_DDL_DIR=`{OLD_REPO}/2-DDL_Tenant_Consolidated`; AUDIT_REPORT_DIR=`{OLD_REPO}/3-Audit_Reports/V1_Jun-2026`; APP_CODE_DIR=`{APP_REPO}/Modules/{Module}`.
- **Stack:** Laravel + laravel-modules (nwidart) + stancl/tenancy (DB-per-tenant) + AdminLTE/Blade/Alpine + Laravel Dusk + Pest. 3 DBs: global_master, prime_db, tenant_*.
- **Team member's agent** (OpenCode `prime-test-creator`) lives in the newer `pgdatabase` repo — different path variables ({LARAVEL_REPO}/{DB_REPO}/{TESTING_REPO}/{AI_BRAIN}); do not copy his literal paths.

## 12. CONVERSATION HIGHLIGHTS — RAW NOTES
- Golden reference: `csm_SchClassV2_TestCas.php` = 78 test methods + rich private helper library; V1 = foundation (schema/config truth in `test_01`), V2 = comprehensive.
- HrStaff/LeaveType committed: V1=7, V2=28; uses `use App\Models\User;`, `User::factory()->create()`, `initTenant()` via Domain, `DatabaseMigrations`, HTTP `actingAs()->post(route('hr-staff.leave-types.store'))`, real activity table `sys_activity_logs` (events Created/Updated/Trashed), permission `hr-staff.*`/`hrs.*`.
- BehaviouralAssessment: prefix `bha_` (16 tables), tenant_db; 25 screen files (00-Module-Overview = SKIP); controllers group screens (BaAssessmentController serves 4 screens; BaReportController serves all reports). Audit uses `BUG-BA-###`/`SEC-BA-###` (no DEV-###). Key P1 bugs: BUG-BA-001 (ratings editable after lock), BUG-BA-002 (period FSM violations), SEC-BA-001 (parent notification missing), SEC-BA-002 (all FormRequests authorize()=true).
- Enhancement WPs: A=constraints lib, B=11 gap checks, C=service read, D=prime/tenant, E=BC-SM+, F=Source tags+Coverage-Score, G=numbering bands, H=path auto-correction+feedback loop.
- Dry-run scratch outputs live in `/private/tmp/claude-502/.../scratchpad/dryrun_LeaveType`, `dryrun2_LeaveType_phase1` — NOT delivered artifacts.
- Gate-4 dry run: V1=16, V2=53 (3.31×), php -l clean; correctly found no service for LeaveType, produced Cross-Reference Findings (5 candidates), obeyed constraints.

---
*End of Context Save*
