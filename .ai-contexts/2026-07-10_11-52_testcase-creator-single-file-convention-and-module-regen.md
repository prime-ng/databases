# Context: Enhanced testcase-creator agent (registry lookup + single-file test convention) and regenerated Billing/MarksheetGeneration/GlobalMaster
# Saved: Friday, July 10, 2026 11:52 IST
# Session Duration: ~ (spanned 2026-07-09 into 2026-07-10) — from "check my last prompt" through agent enhancement + 3-module regeneration
# Project: PrimeAI

---

## 1. SESSION OBJECTIVE
The session had several evolving goals:
1. Diagnose whether a prior prompt had completed (it had — nothing was mid-flight).
2. Configure the **testcase-creator** agent to ALWAYS read a module registry (`module_list.md`) FIRST and resolve 5 identity fields per module before generating test cases.
3. Use the agent to generate the full test-artifact set for several modules (Billing, MarksheetGeneration, GlobalMaster; a Prime run was started then aborted).
4. **Major pivot:** the user revealed the V1/V2 dual test-file pattern was a MISTAKE (it existed only because the `Class` golden reference was authored twice). Requirement changed to: **ONE comprehensive test file per screen**, never V1+V2. Enhance the agent accordingly.
5. Delete the aborted Prime partial output and **regenerate** Billing, MarksheetGeneration, GlobalMaster under the new single-file convention.

## 2. SUMMARY OF WORK DONE
- Confirmed no interrupted work existed at session start (clean tree; local `main` was 4 commits behind origin but those were teammates' commits).
- **Added Step 0 (registry lookup)** to the testcase-creator loader: it now reads `module_list.md` first and resolves MODULE_NAME/CODE/PREFIX/FOLDER_NAME/DDL_FILE_NAME, using them (not hardcoded) throughout; treats the registry prefix as a HINT and verifies the real prefix against the DDL `CREATE TABLE`.
- Generated Billing (9 features), MarksheetGeneration (5), GlobalMaster (5) initially under the OLD 8-artifact V1/V2 convention (later deleted/regenerated).
- Generated program-level roll-ups (`_Program_Defect_Register.md`, `_Program_Test_Summary.md`) — now STALE (predate regen).
- Reviewed `1-TestCase_Agent_using_Prompt.md` and found its Phase-2 was contaminated with BehaviouralAssessment-specific leftovers (BA defect prefixes, "RatingScale" first feature) that did NOT match MarksheetGeneration; advised Phase-1-only is the clean path.
- **Enhanced the agent to single-file convention** across 7 files + loader (8 artifacts → 7; removed "V2 ≥ 2× V1" gate; replaced with coverage gates).
- Deleted the aborted Prime partial (14 files) + old V1/V2 folders for the 3 modules (161 files).
- **Regenerated all 3 modules single-file, in parallel**, all verified on disk (exactly one `.php` per feature, zero V1/V2, all `php -l` clean).
- Fixed a parallel-run collision where 3 concurrent runs each numbered a new `05_` constraint "#24"; renumbered to unique #24–#27.

## 3. FILES TOUCHED
### Created:
- `.../3-Testing_Audit/TestCases/Billing/` — 66 files: 9 features × 7 artifacts + 3 roll-ups (single-file convention). Prefixes: BillingCycle & Subscription = `prm_`; other 7 = `bil_`. 365 test methods. Central/prime-side (extends `BillingDuskTestCase`).
- `.../3-Testing_Audit/TestCases/MarksheetGeneration/` — 38 files: 5 features × 7 + 3 roll-ups. Prefix `msh_`. 261 methods. Features: ConfigurationTemplates, ComponentsAndWeightages, SchedulingAndLifecycle, StudentResultsAndPrint, Dashboard (composite/read-focused, last).
- `.../3-Testing_Audit/TestCases/GlobalMaster/` — 38 files: 5 features × 7 + 3 roll-ups. 175 methods. Central/prime-side. Features: Country(`glb_`), Language(`glb_`), Dropdown(`sys_`), SessionBoardSetup(`glb_`), ActivityLog(`sys_`).
- `.../3-Testing_Audit/TestCases/_Program/_Program_Defect_Register.md` and `_Program_Test_Summary.md` — earlier this session (NOW STALE — predate the regen; reflect old Billing + BehaviouralAssessment only).
- THIS context file.

### Modified:
- `/Users/bkwork/.claude/agents/testcase-creator/AGENT.md` (the loader) — (a) added **Step 0** registry lookup; (b) rule #6 now says "produce exactly ONE comprehensive test file per screen (`{prefix}_{Feature}_TestCas.php` — no V1/V2 split; meet coverage gates, not a method ratio)"; (c) frontmatter `description` updated to "7-artifact ... one comprehensive PHP Dusk test file per screen".
- `.../3-Testing_Audit/Testing-Plan/03_Testcase_Creator_Agent_Prompt.md` (**single source of truth / role prompt**) — ~20 edits: frontmatter desc; added "ONE TEST FILE PER SCREEN (authoritative)" callout; modes 8→7; HARD RULE 5 (7 artifacts) & 6 (coverage-gated not ratio); merged workflow Steps 6&7 (V1+V2) into one Step 6 test-file step; renumbered subsequent steps (gap=7, runners=8, validation=9, execute=10, feedback=10b, report=11); Artifact Contract table 8→7 rows; PHP skeleton class `{prefix}_{Feature}_TestCas`; Quality Gates; report-mode dashboard fields.
- `.../3-Testing_Audit/Testing-Plan/00_Testing_Artifacts_Index_and_Conventions.md` — folder diagram (single `_TestCas.php`), §3 header "7-Artifact Contract", contract table 8→7, generation order, naming (class example), replaced "V2 ≥ 2× V1" gate with coverage gates.
- `.../3-Testing_Audit/Testing-Plan/01_Testing_Strategy_Report.md` — 12 edits (subagent): pyramid, "Two-Tier V1/V2 Split" → "Single Comprehensive Test File", DoD, metrics.
- `.../3-Testing_Audit/Testing-Plan/02_Testing_Plan.md` — 12 edits (subagent): work-breakdown tree, generate steps merged, estimation table, CI gates.
- `.../3-Testing_Audit/Testing-Plan/04_Agent_Usage_Commands.md` — 7 edits (subagent): 8→7 artifacts, single-file examples, runner flags.
- `.../3-Testing_Audit/Testing-Plan/05_Known_Test_Failure_Constraints.md` — 1 edit (subagent: retired "V1/V2 PHP" line 51) + FOUR new constraints appended by the regen runs, renumbered by me to unique **#24 #25 #26 #27** (see §6/§7).

### Deleted:
- `.../TestCases/Prime/` (14 files — aborted partial run, old convention).
- `.../TestCases/Billing/`, `MarksheetGeneration/`, `GlobalMaster/` OLD V1/V2 versions (75 + 43 + 43 = 161 files) before regenerating clean.

### Discussed/Reviewed (not modified):
- `/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/0-Prime_Ai_Detail/module_list.md` — the module registry (46 rows, 5 columns: MODULE_NAME | CODE | PREFIX | FOLDER_NAME | DDL_FILE_NAME). This is the file Step 0 reads.
- `.../3-Testing_Audit/Testing_Prompt/1-TestCase_Agent_using_Prompt.md` — invocation template; Phase-1 is correct, Phase-2 had BA leftover contamination (NOT fixed — flagged to user only).

## 4. KEY DECISIONS & RATIONALE
- **Decision:** Add registry lookup as loader "Step 0", not into the role prompt.
  **Why:** The loader (`AGENT.md`) holds mechanical loading steps; the role prompt (`03_`) holds role knowledge. A registry lookup is a mechanical pre-step. Keeps single-source-of-truth intact.
- **Decision:** Single comprehensive test file per screen; remove "V2 ≥ 2× V1" hard gate.
  **Why:** User clarified V1/V2 was an accident (Class authored twice), never the standard. Replaced ratio gate with existing coverage gates (Negative 100%, Positive ≥90%, Dependency ≥90%, Tenancy 100% P0/P1).
  **Alternatives Considered:** Keep V1/V2 (rejected — user explicit). Make a generic placeholder template for `1-TestCase_Agent_using_Prompt.md` (offered, user did not pick it up).
- **Decision:** Delete old module folders before regenerating (not just Prime).
  **Why:** The agent's collision rule NEVER overwrites — leaving old folders would create dated duplicates (`Billing_2026-Jul-10/`). User wanted replacement, so canonical `{Module}/` must be free. Old artifacts fully reproducible.
- **Decision:** Wait until all 3 regen runs finished before renumbering `05_`.
  **Why:** Parallel runs all read `05_` at #23 and each appended "#24" — renumbering mid-flight would collide again with the still-running MSG append.
- **Decision:** File naming `{prefix}_{Feature}_TestCas.php`, class name = filename.
  **Why:** Drop V1/V2 suffix; consistent with existing convention (class name = filename, `namespace Tests\Browser;`).

## 5. TECHNICAL DETAILS & PATTERNS
- **7-artifact contract per feature:** (1) `{prefix}_{Feature}TcList_Require.md` (2) `{prefix}_{Feature}MANUALTESTING_Require.md` (3) `{prefix}_{Feature}GAPANALYSIS_Require.md` (4) `{prefix}_{Feature}_TestCas.php` [ONE file] (5) `{prefix}_{Feature}Validation_Report.md` (6) `run-{Feature}-tests.ps1` (7) `run-{Feature}-tests.sh`.
- **Single test file structure:** opens with `test_{feature}_01_migration_model_and_request_configuration_are_correct` (schema/config truth — old V1's opener), then the full matrix (old V2) on semantic numbering bands (01–09 schema, 10–19 BIZ, 20–29 SM, 30–39 VAL, 40–49 INT/REF, 50–59 AUTH, 60–69 UIX, 70–79 EDG, 80–89 CFG, 90–99 tenancy/security).
- **Registry Step 0:** prefix from registry is a HINT — MUST verify against DDL `CREATE TABLE`. Proven valuable: GlobalMaster's Dropdown/ActivityLog are `sys_` not `glb_`; Billing's BillingCycle/Subscription are `prm_` not `bil_`.
- **Prime/central vs tenant scope:** determined from DDL header (`prime_db`/`global_db` vs `tenant_db`) + routes. Central features (Billing, GlobalMaster, Prime) use `BillingDuskTestCase`/central base, `authenticateCentral()`/`visitAuthenticated()`/`centralUrl()`, host `http://127.0.0.1:8000`, `App\Models\User`, NO tenant scaffolding. Tenant features use `initializeTenantContext()` + `DUSK_TENANT_URL` (`http://test.localhost:8000`).
- **OUTPUT_ROOT (agent writes ONLY here):** `/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/3-Testing_Audit/TestCases/`. Module folder resolved once, never overwritten (collision → `{Module}_{YYYY-MMM-DD}` → `..._{HH-MM}`). Only permitted write outside OUTPUT_ROOT = appending a general constraint to `05_` (Step 10b feedback loop).
- **Repos:** OLD_REPO=`/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db`; APP_REPO=`/Users/bkwork/Herd/prime_ai`; TEST_FILE_REPO=`/Users/bkwork/Herd/prime_testing` (agent reads but NEVER writes these last two).

## 6. DATABASE CHANGES
None (this session produced test artifacts and documentation only — no app schema/migrations were written). Notable DB *findings* documented in the artifacts:
- Billing: `bil_tenant_email_schedules` absent from `Billing_DDL_v1.sql` (authority is `prime_db_v4.sql`); MIG-BIL-001 (SoftDeletes vs no `deleted_at`); DATA-BIL-001 (audit-log FK column-name mismatch).
- MSG: `MarksheetGeneration_DDL_v1.sql` header says 22 tables but defines 23 (DOC-MSH-001). "rename sys_dropdown_table→sys_dropdowns" migration is a NO-OP; real table stays `sys_dropdown_table` (corrected audit DOC-MSH-002).
- GlobalMaster: `sys_central_activity_logs` has NO consolidated DDL (central migration only).

## 7. PROBLEMS ENCOUNTERED & SOLUTIONS
- **Problem:** Parallel regen runs each appended a `05_` constraint numbered "#24" (three collisions + a #25).
  **Cause:** All 3 concurrent agents read `05_` when the last constraint was #23, before any wrote.
  **Solution:** Waited for all 3 to finish, then renumbered to unique #24 (Billing web-routes), #25 (GlobalMaster activityLog sink), #26 (empty module migrations dir), #27 (rename-migration no-op). Verified no duplicate numbers remain.
- **Problem:** `1-TestCase_Agent_using_Prompt.md` Phase-2 referenced BA defect prefixes (BUG-BA-###/SEC-BA-###) and "RatingScale" as first feature — wrong for MarksheetGeneration.
  **Cause:** Copy-paste leftover from a BehaviouralAssessment run; only Phase-1's `{MODULE_NAME}` was updated.
  **Solution:** Advised user; used Phase-1-only clean invocation with corrected MSH prefixes. (File itself NOT edited — user did not request the fix.)
- **Problem:** Aborted Prime run left partial old-convention output.
  **Cause:** User pivoted to single-file mid-run; I stopped the Prime agent.
  **Solution:** Deleted `TestCases/Prime/`.

## 8. CURRENT STATE OF WORK
### Completed:
- testcase-creator agent enhanced: Step 0 registry lookup + single-file (7-artifact) convention across all 7 Testing-Plan files + loader. Verified no stale test-file V1/V2 refs remain (legit path/version refs like `REQUIRE_DETAIL_V1`, `V1_Jun-2026`, `_v4.sql`, requirement `_v1` suffixes preserved).
- Billing, MarksheetGeneration, GlobalMaster regenerated single-file: 142 files, 19 features, 801 methods, 19/19 feature folders with exactly one `.php` + zero V1/V2, all `php -l` clean, each with module roll-ups.
- `05_` constraints renumbered unique #24–#27.
- Prime partial + old V1/V2 folders deleted.

### In Progress:
- None (all launched agents completed).

### Not Yet Started:
- Refreshing `_Program` roll-ups (offered, awaiting user).
- Regenerating BehaviouralAssessment single-file (offered, awaiting user).
- Executing any of the tests (all are static-verified only; not run — needs modules enabled in `modules_statuses.json`, `APP_ENV=testing`).

## 9. OPEN QUESTIONS & TODOS
- [ ] Re-run report mode at program scope to refresh STALE `_Program_Defect_Register.md` / `_Program_Test_Summary.md` (they reflect old Billing + BehaviouralAssessment only).
- [ ] Decide whether to regenerate **BehaviouralAssessment** (still has old V1/V2 files, 6 of 24 features) under single-file convention.
- [ ] Optionally fix/genericize `1-TestCase_Agent_using_Prompt.md` Phase-2 (BA contamination + Phase-1/Phase-2 auto-run-vs-pause contradiction).
- [?] Whether user wants remaining ~40 modules generated (registry has 46 modules; only a handful done).
- [ ] Tests are authored but NOT executed — future work: enable modules, run runners, invert defect-proving tests once source bugs are fixed.

## 10. IMPORTANT CONTEXT FOR FUTURE SESSIONS
- **HOW TO INVOKE THE AGENT:** Use the `testcase-creator` subagent. Standard call: `mode=module, module={NAME}` → generates all features single-file, then `report mode` for module roll-ups. It auto-runs Step 0 (registry lookup) itself now.
- **THE STANDARD IS NOW ONE TEST FILE PER SCREEN.** Never V1/V2. File = `{prefix}_{Feature}_TestCas.php`. If any output ever shows V1/V2 files, that's a regression — the convention lives in `03_` (role prompt) and `00_` (conventions), read live by the loader `AGENT.md`.
- **Registry file:** `/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/0-Prime_Ai_Detail/module_list.md`. Columns MODULE_NAME|CODE|PREFIX|FOLDER_NAME|DDL_FILE_NAME. PREFIX is a hint — always verify vs DDL `CREATE TABLE`.
- **Coverage gates (replaced the ratio gate):** Negative 100%, Positive ≥90%, Dependency ≥90%, Tenancy 100% on P0/P1. Every TC-ID ↔ ≥1 method; every method ↔ a TC/BC.
- **HARD RULE 13:** read real source; source WINS over stale audit. Multiple stale audit items were caught this session (Billing SEC-BIL-* already remediated; MSG DOC-MSH-002 wrong; GlobalMaster central routes served by `Modules\Prime` controllers not the module's own).
- **Verification pattern I used:** after each run, on disk check per feature folder: exactly 1 `*_TestCas.php`, 0 `*V1_TestCas.php`/`*V2_TestCas.php`, 7 artifacts, and `php -l` on every PHP file.
- **User preferences observed:** wants me to VERIFY outputs on disk (not just trust agent reports); wants correct per-module defect prefixes (no cross-module contamination); wants clean canonical folders (delete-then-regenerate over dated duplicates); dislikes padding tests to hit arbitrary counts.
- **Module identity quick refs:** Billing=BIL/bil_(+prm_ for cycle/subscription); MarksheetGeneration=MSH/msh_ (requirement folder is `MarksheetGeneration_V2` capital V2); GlobalMaster=GLB/glb_(+sys_ for Dropdown/ActivityLog), central; Prime=PRM/prm_/sys_, central (NOT regenerated — has committed siblings in prime_testing/tests/Browser/Modules/Prime/).

## 11. DEPENDENCIES & CROSS-MODULE REFERENCES
- **Billing overlaps Prime:** Billing is a Prime-side sub-area; live routes registered in app-level `prime_ai/routes/web.php` (constraint #24), some served by `Modules\Prime\*`.
- **GlobalMaster ↔ Prime:** central routes `central.global-master.*` — Language/Dropdown/ActivityLog/SessionBoardSetup served by `Modules\Prime\*Controller` (module's own controllers are dead duplicates). Central audit sink = `sys_central_activity_logs` (`Modules\Prime\Models\ActivityLog`, `mysql`).
- **Env prerequisites to RUN tests:** relevant module(s) `true` in `prime_testing/modules_statuses.json` (Billing & GlobalMaster also need `Prime: true`), `APP_ENV=testing`, `MAIN_PROJECT_PATH`→`prime_ai`, central host `127.0.0.1:8000` reachable.
- **05_ constraints** the agent must obey when writing PHP: tenancy/User/factory/soft-delete/assertion/env rules; now includes #21 (Prime host 127.0.0.1:8000), #22 (preload.php class_alias base classes), #23 (module api.php not auto-registered), #24 (central web routes in app routes/web.php), #25 (activityLog sink by tenancy state), #26 (empty module migrations dir), #27 (rename migration may be no-op).

## 12. CONVERSATION HIGHLIGHTS — RAW NOTES
- User's pivot message (verbatim intent): "I dont want you to create Ver1 & Ver2 of Testcase for All the Module. It was there in the Sample file and you have taken it wrongly... we have created TestCases for Class 2 time. You need to create single file for Testcase for Every Screen of Every Module. Enhance the Agent 'TestCase Creator'."
- Key numbers this session: Billing 66 files/9 feat/365 methods; MSG 38/5/261; GlobalMaster 38/5/175. Total 142 files / 19 features / 801 methods.
- Deleted counts: Prime 14; old Billing 75; old MSG 43; old GlobalMaster 43.
- `05_` renumber result: constraints 20–27 all unique, `grep -oE "^[0-9]+\." | sort | uniq -d` returns none.
- Agent Step 0 loader text (added to `AGENT.md`): reads module_list.md, extracts 5 fields; STOP + ask if module not found; if DDL_FILE_NAME is `N/A` don't invent one.
- New defect discovered & proven this session: **BUG-MSH-101 (P1)** — `ScheduleClass` model missing `SoftDeletes` though `msh_schedule_class_jnt` has `deleted_at` and controller calls `withTrashed()/restore()` (audit missed it).
- Golden reference (form only): `/Users/bkwork/Herd/prime_testing/tests/Browser/Modules/Class&SubjectMgmt/Classes/*` and `HrStaff/*`.
- The context-save trigger routes through `/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/7-CLAUDE_Prompts/0-Important_Prompts/Save_Context.md` (PROMPT 1). CONTEXT_STORAGE_DIR = `.ai-contexts`, PROJECT_NAME = PrimeAI.

---
*End of Context Save*
