# Context: Authored 7 new testing-pipeline prompts, executed 9 of them in parallel, then classified all 47 modules
# Saved: 2026-07-30 19:21
# Session Duration: Full session — from a gap-audit of the token-cost document through complete 47-module screen classification
# Project: PrimeAI

---

## 1. SESSION OBJECTIVE

Four sequential objectives, all in the test-case generation programme:

1. **Gap audit.** Read `TestCase_Generation_Activities_and_Token_Cost_v1.md` and find every *report/activity* that was NOT covered by the 3 existing prompts (`ScreenClassificationRegister.md`, `CategoryGoldKit.md`, `CanonAuthoring_Maintenance.md`). Create a prompt for each gap in `9-TestingStrategy/Prompts`.
2. **Enforce two standing directions** in the new prompts: (a) all files saved into a sub-folder of `/Users/bkwork/WorkFolder/3-Local_Workspace/9-TestingStrategy`; (b) NO changes anywhere outside that folder.
3. **Execute all the new prompts** using multiple parallel agents.
4. **Create a summary document** explaining every generated file, its purpose, and how to use it to generate test cases (the user's stated final goal).
5. **Extend classification from 12 to ALL modules** — user challenged: "How should I create Testcases for other Module without that information?"

---

## 2. SUMMARY OF WORK DONE

- Audited the token-cost document against the 3 existing prompts. Found **GROUP 0 only was covered** (A0.1–A0.3); six activity groups downstream had no prompt.
- **Authored 7 new prompts** (~160 KB total) + a coverage-map index. Each owns exactly one output sub-folder (04–10).
- Verified all 7 carried both standing directions; found `ExecuteAndRepair.md` had carved out an exception (a `REPAIR-DIRECT` mode that could edit a test file in `prime_testing`). **Removed it** — now patch-proposal-only.
- **Launched 9 parallel agents** to execute the new prompts. All 9 completed. Produced 165 files / ~2.05 MB across folders 04–08 and 10.
- Verified every agent's headline claims against disk myself. **Found and corrected 4 defects in prompts I wrote** and **5 errors in agent findings** (details in §7).
- Wrote `_WORKSPACE_SUMMARY_2026-07-30.md` (35.6 KB) — a per-folder operating manual with an 11-step per-screen test-generation walkthrough.
- **Launched 8 more parallel agents** to classify the remaining 35 modules. All completed.
- **Classification now complete: 47/47 modules, 872 screen rows** (was 12 modules / 266 rows).
- Found and fixed a **defect in the classification decision procedure itself** (step 1 was a method-name test — see §4/§7).

---

## 3. FILES TOUCHED

### Created — new prompts (in `/Users/bkwork/WorkFolder/3-Local_Workspace/9-TestingStrategy/Prompts/New/`; user later moved them there from `Prompts/`)
- `ModuleFactPack.md` — A1.1+A1.2. Builds per-module Fact Pack (identity, tenancy scope, table/constraint inventory, routes, verbatim permissions + activity-log strings). Output → `04-Module_Fact_Packs/`
- `LegacyEstateTriage.md` — A0.4 (Master Plan Phase 0.3 + §8). Verdicts every existing TcList/test + assigns test tier. Output → `05-Legacy_Estate_Triage/`
- `ReviewBatchPacket.md` — GROUP 3. Review batching, pre-flight, verbatim red-line capture, the `% TCs deleted at review` metric. Output → `06-Review_Batches/`
- `ExecuteAndRepair.md` — A5.1–A5.3. Static validation, execution, 3-iteration-capped repair loop, (a)/(b)/(c) failure triage. Output → `07-Execute_Repair/`
- `CrossReferenceDefectScan.md` — A5.4. The 15 cross-layer checks. Output → `08-Defect_Scan/`
- `ProgrammeRollups.md` — A6.1. RTM, coverage dashboard, defect register, §9.2 metrics. Output → `09-Rollups/`
- `DuskSelectorRetrofit.md` — §7 opt #10. Selector manifests + additive `dusk=""` patch proposals. Output → `10-Selector_Retrofit/`

### Created — other
- `/Users/bkwork/WorkFolder/3-Local_Workspace/9-TestingStrategy/Prompts/_PROMPT_COVERAGE_MAP.md` — activity-ID → owning-prompt audit; documents what deliberately has NO prompt.
- `/Users/bkwork/WorkFolder/3-Local_Workspace/9-TestingStrategy/_WORKSPACE_SUMMARY_2026-07-30.md` — the operating manual (see §10).

### Modified — prompts (defect fixes discovered during execution)
- `New/LegacyEstateTriage.md` — tolerant TC/BC-ID regexes + mandatory per-module ID calibration block.
- `New/ReviewBatchPacket.md` — same regex fix + calibration warning.
- `New/ModuleFactPack.md` — replaced a FABRICATED worked example (`exm_` prefix, stale `Exam` alias); added the `RouteServiceProvider` middleware trap and the `route:list`-unavailable note.
- `New/CrossReferenceDefectScan.md` — added "migrations are production truth, not DDL" + the D36 generated-column false-positive warning.
- `New/ExecuteAndRepair.md` — removed `REPAIR-DIRECT`; now patch-proposal-only; added `PATCHES-PENDING` health state; iterations now count *executions*.
- `Prompts/Executed/ScreenClassificationRegister.md` — **3 additions**: (1) `Route::resource` routes methods implicitly → correct unrouted-detection procedure; (2) new `NO-BEHAVIOUR` register outcome; (3) **decision-step-1 rewritten** from a method-name test to a "no persistence anywhere in the stack" test.

### Discussed/Reviewed (not modified)
- `9-TestingStrategy/TestCase_Generation_Activities_and_Token_Cost_v1.md` — the gap-audit source.
- `9-TestingStrategy/Prime_AI_TestCase_Generation_Master_Plan_2026Jul29.md` — §4.3 gaps, §8 tiering, §9.1 DoD, §9.2 metrics.
- `old_db/3-Testing_Audit/Testing-Plan/00_…Conventions.md`, `05_Known_Test_Failure_Constraints.md` — canon.
- `old_db/0-Prime_Ai_Detail/module_list.md` — the registry (found stale in several places).
- `prime_testing/TEST_SETUP.md` — real run commands (`php artisan test`, `php artisan dusk`).

---

## 4. KEY DECISIONS & RATIONALE

- **Decision:** Create 7 prompts, not fewer.
  **Why:** The audit found 6 uncovered activity groups plus optimisation #10. Each maps to one distinct report and one output folder.
  **Alternatives:** Folding roll-ups into estate triage — rejected; different frequency (weekly vs once) and different inputs.

- **Decision:** Remove `ExecuteAndRepair.md`'s `REPAIR-DIRECT` mode entirely.
  **Why:** User's direction #2 ("DO NOT make any changes other than folder 9-TestingStrategy") is absolute. My exception ("a repair that cannot touch the test file is not a repair") was my own reasoning, not theirs.
  **Trade-off accepted and documented in the prompt:** the loop is slower — it stops for a human between executions instead of self-repairing to green.

- **Decision:** Hold `ProgrammeRollups` (folder 09) back to wave 2.
  **Why:** Its entire input is folders 01–08. Rolling up empty registers produces a dashboard of `NOT AVAILABLE`.
  **STILL NOT RUN.**

- **Decision:** Run `ReviewBatchPacket` and `ExecuteAndRepair` in deliberately degraded modes.
  **Why:** Their own rules say stop rather than fake it. No kit `Definition.md` exists (review gate blocked); no `.env`/`phpunit.xml`/chromedriver (execution blocked). Ran pre-flight-only and static-only respectively — both still produced real value.

- **Decision:** Have concurrent agents self-derive rather than wait on siblings.
  **Why:** Write-collision rule W5 (no reading in-flight sibling output). DS-1 derived its own DDL inventory instead of waiting on FP-1; SR-1 self-derived `CANDIDATE-TIER` from archetypes. Mirrors how the existing orchestrator unblocked the kit agents.

- **Decision:** Per-agent output files (`_Identity_Register_FP-1.md`, `_Run_Log_ET-2.md`, `_AMBIGUOUS_{Module}.md`), never shared roll-ups.
  **Why:** Parallel agents sharing a file silently clobber each other. Roll-up is an orchestrator step.

- **Decision (recommendation, NOT yet ruled by user):** A pure tab-aggregation hub controller gets **NO** register row.
  **Why:** It writes nothing; giving it an archetype invents CRUD tests for a screen with no CRUD. Each tab already has its own Requirement doc and row. Seen in HrStaff (`HrMenuController`), Hostel (`HostelSetupController`), Library (`LibraryController`).

- **Decision (recommendation, NOT yet ruled):** `status` column WITHOUT named transition methods → **A2 with a status note**, not A6.
  **Why:** A6 requires actual transition methods; inferring a workflow from a column alone generates state-machine tests against transitions that don't exist.

- **Decision:** Rewrite classification decision-step 1.
  **Why:** It tested for method names (`store`/`update`/`destroy`). Controllers here persist via `saveAllocation()`, `assignMeal()`, `publish()`, `markAttendance()`, `syncTopics()`. 5 real misfires found. A write screen misclassified A7 read-only gets ZERO write-path coverage and then *looks finished* — worse than over-generation because it's invisible.

---

## 5. TECHNICAL DETAILS & PATTERNS

**Universal prompt contract (all 10 prompts):**
- `WORKSPACE_ROOT = /Users/bkwork/WorkFolder/3-Local_Workspace/9-TestingStrategy`; each prompt has its own `OUTPUT_DIR` sub-folder.
- `prime_ai`, `prime_testing`, `old_db`, `pgdatabase` are **read-only**. No git ops, no migrations, no schema/canon/`CLAUDE.md` edits, nothing in `/tmp`.
- Shell-first: never full-read a DDL, a controller >20k chars, a blade >15k chars, a TcList, or a test file.
- Every fact carries `file:line`. Verbatim strings are verbatim or marked `NOT-FOUND`.
- Canon-bound output → written to sandbox + a `PROMOTION CANDIDATES` line in `_Run_Log.md`. Promotion is a human decision.

**Measured codebase facts established this session (these are the reusable gold):**
1. **Route middleware lives in the module's `RouteServiceProvider`** (`mapWebRoutes`/`mapApiRoutes`), NOT in `routes/*.php`. `SchoolSetup/routes/web.php` is 489 lines with ZERO `->middleware`. Web and API surfaces often differ (SchoolSetup api has NO tenancy).
2. **`php artisan` cannot boot**: `Class "Sentry\Laravel\Integration" not found` at `bootstrap/app.php:74`. `route:list` unavailable programme-wide; all route tables are file-derived.
3. **Migrations are production truth, not DDL files.** Centralised in `prime_ai/database/migrations/` and `.../tenant/` (743 files) — most modules ship NONE of their own. Check for later retrofit migrations (e.g. `2026_07_09_000006_add_unique_invoice_no_to_fee_invoices.php`).
4. **Pattern D36** — a UNIQUE on a `*_flag` column is usually CORRECT: `current_flag INT GENERATED ALWAYS AS (CASE WHEN is_current=1 THEN student_id ELSE NULL END) STORED` + `UNIQUE(current_flag)` = partial-unique idiom (NULLs don't collide). 15 DDL files use `GENERATED ALWAYS AS`.
5. **Authorization is not always a Gate.** Must grep ALL of: `Gate::authorize|Gate::allows|Gate::denies|Gate::any|->can(|authorize(|hasRole|is_super_admin|abort(403`. A Gate-only grep produced a false "zero-auth" finding on a Super-Admin-gated controller.
6. **`Route::resource`/`apiResource` route methods implicitly** — a method-name grep returns 0 (whole controller looks dead) or false positives (generic names match other controllers). resource→7 methods, apiResource→5.
7. **TC-ID conventions are mixed.** `TC-P01`/`TC-N01`/`TC-CR01`/`TC-D01`/`TC-E01`/`TC-S01`/`TC-UX01` ≈49,000 occurrences (NO hyphen, dominant); `TC-P-01` form only ~3,700 (~7%); a third form `TC-MI-P25` (screen-abbrev then type). BC classes wider than canon: `BIZ · DB · VAL · AUTH · EDG · REF · SEC · REL`.
8. **Activity-log sinks:** tenant = `sys_activity_logs` (TenantCore + GlobalMaster models); prime = `sys_central_activity_logs`. **Rule Card E25's `activity_logs` is WRONG.**
9. **`glb_languages`** is a REAL TABLE centrally and a VIEW only inside each tenant schema — scope-dependent.
10. **Central/prime-side modules confirmed:** Prime, GlobalMaster, Billing. Evidence: no tenancy middleware, `Route::domain(config('app.domain'))->name("central.")`, `$connection='global_master_mysql'`, migrations in central root. `R3` withheld on all 55 of their rows.

**Test-tier decision (from `LegacyEstateTriage.md` §5):** the one question is *"is the DOM or the JS the thing under test?"* Archetype defaults: A1/A2/A3/A4/A5/A6/A7/A8/A11 → Feature; A9/A10/A12 → Dusk; engines → Unit. Target 15% Unit / 70% Feature / 15% Dusk; Dusk ceiling ~25% of a module's BCs.

---

## 6. DATABASE CHANGES

**None.** Every prompt forbids schema changes, and no migration/seeder was run or written. All DB observations are read-only findings.

---

## 7. PROBLEMS ENCOUNTERED & SOLUTIONS

### Defects in prompts I authored (all fixed)
- **Problem:** `TC-[PND]-[0-9]+` regex in `LegacyEstateTriage.md` and `ReviewBatchPacket.md`.
  **Cause:** I wrote it from the canon's illustrative examples, not from the estate.
  **Solution:** Tolerant regexes + a mandatory per-module calibration step + the rule "a TC count of 0 means your regex is wrong, not that the TcList is empty." Would otherwise have missed ~93% of TC-IDs.

- **Problem:** `ModuleFactPack.md` §3.2 worked example gave LmsExam `PREFIX = exm_` and propagated the registry's `LmsExam → Exam` alias.
  **Cause:** I fabricated the example row instead of measuring it.
  **Solution:** Real values (`lms_`; review folder is `LmsExam/`, no `Exam/` exists) + two explicit traps: `CODE ≠ PREFIX`, and `ls`-confirm every alias.

- **Problem:** Prompts assumed route middleware is visible in route files.
  **Solution:** Mandatory `RouteServiceProvider` step; must distinguish *unauthenticated* from *authenticated-but-unauthorised*.

- **Problem:** DDL treated as schema truth; UNIQUE-on-flag readable as a defect.
  **Solution:** "Migrations are truth" + print a column's full definition before flagging a UNIQUE (D36).

- **Problem:** `ExecuteAndRepair.md` violated user direction #2.
  **Solution:** Removed `REPAIR-DIRECT` (see §4).

- **Problem (KNOWN, NOT FIXED):** `LegacyEstateTriage.md` §4.1 verdict rules have no branch for "nothing in the estate is ever approved." ET-1 hit this and applied a documented interpretive ruling per module.

### Errors in agent findings (caught by my own disk verification)
- **DS-1 SP-1a** listed `invoice_no` as unindexed — WRONG, migration `2026_07_09_000006` adds `uq_fee_invoices_invoice_no`. (Side-effect: **BUG-FIN-35 is resolved on disk.**) `receipt_no`/`transaction_no`/`refund_no` ARE genuinely unindexed.
- **FP-1 finding 6** read `UNIQUE(current_flag)` as "allows only 2 rows" — false positive, it's D36. Acting on it would have broken correct constraint logic.
- **FP-3 DEV-SCH-F04** reported `/sync-permissions` as zero-auth — WRONG, `PermissionSyncController:26` has `hasRole('Super Admin')`. **I relayed this error to the user before catching it**, because my own verification grep was Gate-only too. 4 zero-auth controllers narrowed to 1 (`Mobile/EmployeeAttendanceController`).
- **FP-3 DEV-SCH-F03** said the `school-setup` scope "exists nowhere" — it IS at `permissionslist.php:125` under the `tenant` scope. Root cause restated as scope-vs-feature mismatch; count corrected 233→**376 gate strings, 251 created, 125 never created** (its first pass missed `Gate::allows/denies/any`).
- **RB-1** said no `00_` conventions contract exists — it does (22.5 KB). But this surfaced a REAL issue: **`00_` specifies a 5-artefact combined-doc contract while the Master Plan specifies a 13-section standalone TcList.** Canon and plan disagree → A0.3 item.

### My own verification failures worth remembering
- Twice got the SmartTimetable unrouted-method count wrong (1, then 25 routed) before finding the truth (25 UNROUTED). Cause: method-name greps against route files. `Route::resource` is the reason.
- Used a Gate-only grep to "verify" a zero-auth claim, thereby confirming an error instead of catching it.

---

## 8. CURRENT STATE OF WORK

### Completed
- 7 new prompts authored, hardened, both standing directions verified in all of them.
- `_PROMPT_COVERAGE_MAP.md` — every activity ID mapped to an owning prompt.
- 9 wave-1 agents executed → folders **04, 05, 06, 07, 08, 10** populated (165 files, ~2.05 MB).
- `_WORKSPACE_SUMMARY_2026-07-30.md` written.
- **Classification COMPLETE: 47/47 modules, 872 screen rows, 47 shards** in `01-Classification/Shards/`.
- FP-3 corrections applied (SchoolSetup pack split to 24,993 chars + `_Tables.md` companion).

### In Progress / owed
- **Master register rollup**: `01-Classification/07_Screen_Classification_Register.md` (122 KB) still covers **only the original 12 modules**. Needs all 47 shards rolled up, `_AMBIGUOUS_*`/`_DEV_Candidates_*` concatenated, and a fresh `_SpotCheck_{DATE}.md` (10% sample weighted to A3/A5/A6/A9/A10 + every P0 row) for Gate-1 sign-off.
- **Folder 05 roll-up**: only 36 shards exist; the three top-level registers (`TcList_Inventory_Register.md`, `Test_File_Inventory_Register.md`, `Tier_Assignment_Register.md`) were never written.
- **Folder 04 merge**: `_Identity_Register_FP-{1,2,3}.md` → `_Identity_Register.md`; same for `_Stale_Inputs_*` and `_Run_Log_*`.
- **Folder 08 merge**: `_DEV_Register_DS-1.md` → `_DEV_Register.md`.

### Not Yet Started
- **Folder 09 (`ProgrammeRollups`) — NEVER RUN.** Empty. Blocked on the roll-ups above.
- **A7/A8 re-verification sweep** — 37 modules were classified under the OLD decision-step 1, so any A7/A8 row whose controller *or service* writes is suspect. Mechanical grep. Must run before Stage A trusts any read-only classification.
- Fact Packs for 3 modules: **Notification, StandardTimetable, TimetableFoundation** (folder 04 covers only 9 of 12).
- Fact Packs for the 35 newly-classified modules (none exist).
- Cross-reference defect scan beyond the 3 P0 modules; the SP-1a DDL-form diff across the other 10 modules.

---

## 9. OPEN QUESTIONS & TODOS

- [?] **RULING NEEDED — tab-hub controllers:** does a pure tab-aggregation hub get its own register row? My recommendation: **NO** (see §4). Affects HrStaff/Hostel/Library and more.
- [?] **RULING NEEDED — `status` column without transition methods:** A2-with-note (my recommendation) or A6? ~7 rows in Hostel/Library alone.
- [?] **RULING NEEDED — Scheduler's inclusion** in a tenant-facing register (scope policy, not a signal question).
- [?] `00_` (5-artefact combined doc) vs Master Plan (13-section TcList) — which is the real TcList contract?
- [?] Library has 3 Requirement docs + TcLists with NO controller/route: `Acquisition_Report`, `Digital_Resource_Report`, `Overdue_Report`.
- [?] Accounting: Voucher and Expense Claim are genuinely dual-natured A3+A6 — classified A3, escalated.
- [?] LmsQuests' Quest has no `publish()` unlike its twin LmsQuiz — missing feature or different path?
- [ ] Run the master register rollup + `_SpotCheck` for Gate-1.
- [ ] Run the A7/A8 re-verification sweep.
- [ ] Red-line `02-Category_Kits/A2_FkDependentMaster/A2_Gold_TcList_DRAFT.md` — **the single highest-leverage action in the programme**; unblocks `StudentFee × A2` (5 TcLists, all P0).
- [ ] Approve the 3 canon patches in `03-Canon_Patches/Proposed/` — until then the kits are inert.
- [ ] Work `07-Execute_Repair/_Environment_Readiness.md`'s ordered 8-step list.
- [ ] Escalate/fix **SEC-MNT-001** and **DEV-301**.
- [ ] Re-verify the 2026-06-29 audit reports before Stage A reads them.
- [ ] New Rule Card candidates: E25 table name; `artisan` boot failure; FP-3's 4 authorization-discovery method notes.

---

## 10. IMPORTANT CONTEXT FOR FUTURE SESSIONS

**Folder → prompt ownership (each prompt writes ONLY its own folder):**
`01-Classification`→A0.1 · `02-Category_Kits`→A0.2 · `03-Canon_Patches`→A0.3 · `04-Module_Fact_Packs`→A1.1/A1.2 · `05-Legacy_Estate_Triage`→A0.4 · `06-Review_Batches`→A3.1 · `07-Execute_Repair`→A5.1–A5.3 · `08-Defect_Scan`→A5.4 · `09-Rollups`→A6.1 · `10-Selector_Retrofit`→OPT-10.

**Prompt locations:** executed ones in `Prompts/Executed/`; the 7 new ones in `Prompts/New/`; `_PROMPT_COVERAGE_MAP.md` at `Prompts/`. **The user moves prompts into `Executed/` after running them** — check both paths before editing.

**READ `_WORKSPACE_SUMMARY_2026-07-30.md` FIRST.** Its §5 is the 11-step per-screen test-generation walkthrough; §6 lists blockers; §7 lists documents containing known errors.

### The 4 blockers preventing test-case generation today
1. **No finished Category Kit** — 3 drafts only (A2/A3/A7); A1/A5/A6/A8/A9 have nothing. Stage A has no FORBIDDEN list, so the original over-generation problem is NOT yet fixed. `_RedLines/` is empty.
2. **Canon patches unapplied** — kits would be inert even once built.
3. **No test environment** — no `.env`, no `.env.example`, no `phpunit.xml`, no `phpunit.dusk.xml` (none git-tracked, so no template), no Chrome/chromedriver.
4. **`php artisan` unbootable** (Sentry).

### Baseline problems that change every coverage number
- **`REUSE = 0`.** Of ~187 inventoried TcList rows, ZERO have a Category Obligation Matrix and ZERO have genuine reviewer sign-off (all apparent approvals were false positives — `UNSIGNED` columns, ENUM values named `Approved`). 0 of 556 estate-wide have an Obligation Matrix.
- **Traceability absent:** 0/68 test files cite a TC-ID; 0/82 TcLists have a filled Covered-By column. A `FULL` state means "three files exist", never "the test implements the TcList".
- **A second, parallel TcList estate:** **492** `*TcList_Require*` files (562 non-standard TcList-named docs) live under `tests/`, outside `Doc_Analysis/4-TC_List_Requirement_Review/…/TC_List/` — the only path the canon, prompts and the "556 TcLists" figure use.
- **MarksheetGeneration has 15 test files / 602 test methods** under `tests/Created_by_Brijesh/Version-1/` and `Z-Old_TestCases/`, never found by classification.
- **~27 phantom tables** — referenced by live code, no migration anywhere: Dashboard 17, Hpc 6, EventEngine 3, SyllabusBooks 1. Dashboard's are prefix-drift guesses (`fin_fee_invoices` vs real `fee_invoices`; `msg_*` vs real `msh_*`); `safeCount()` swallows the error so those tiles show 0 forever.
- **The 2026-06-29 audit reports are STALE in four independent checks** — ~20 findings incl. several P0s already fixed (`SEC-EXM-005`, `BUG-MSH-001`, `BUG-ADM-004`, `SEC-PPT-003`, `BUG-FIN-35`, 9 more in FP-1's slice). Stage A/B reading them would assert vulnerabilities that no longer exist.

### The two most severe live defects
- **SEC-MNT-001 (top priority).** `Modules/Maintenance/app/Http/Controllers/RestoreController.php` (133 lines) has ZERO authorization; `RestoreBackupRequest::authorize()` returns `true`; route is only `['auth','verified']` (`routes/web.php:6`). Sibling `BackupController` has 5 `Gate::authorize` calls → omission, not design. **Worse than first reported: the restore target comes from user input** — `target_connection` = `tenant:<uuid>` → `buildDatabaseName($tenantId)`. So **any authenticated user of any tenant can overwrite any other tenant's database** via `POST /maintenance/backup/{run}/restore`.
- **DEV-301.** `FeeInvoiceService.php:282` calls `FeeReceipt::withTrashed()`. `FeeInvoice` (266) and `FeeTransaction` (274) both have `SoftDeletes`; **`FeeReceipt` has none** — no trait, no `deleted_at`, no `BaseModel` shim, no macro. Throws `BadMethodCallException` unconditionally inside `recordGatewayPayment()`'s transaction, AFTER the payment row is written → every online fee payment rolls back: **payer debited, nothing recorded.** 3 live routes.

### User preferences observed
- Insists on the two standing directions (sandbox sub-folder; no changes outside `9-TestingStrategy`) — enforce absolutely, no exceptions.
- Wants parallel agents for multi-part execution.
- Wants complete coverage, not release-scope subsets ("I need that classification for all the Module").
- Wants documents that explain purpose AND usage, tied back to the final goal of generating test cases.
- Moves executed prompts into `Prompts/Executed/` and new ones into `Prompts/New/`.

---

## 11. DEPENDENCIES & CROSS-MODULE REFERENCES

- **`prime_ai`** (`/Users/bkwork/Herd/prime_ai`) — 47 modules. Migrations centralised at `database/migrations/` + `.../tenant/` (743 files).
- **`prime_testing`** (`/Users/bkwork/Herd/prime_testing`) — 933 php test files (756 under `Browser/`, 209 under a `V2/` path), 556 canonical TcLists + 492 `TcList_Require` companions. `TEST_SETUP.md` documents 3 DBs (`global_master`, `prime_db`, `test_runner_db`).
- **Canon** — `old_db/3-Testing_Audit/Testing-Plan/`: `00_`, `01_`, `02_`, `03_`, `04_`, `05_`, `05a_`. The `07_`/`08_` agent prompts referenced by the token-cost doc are the registered `testcase-scripter` / `tclist-author` agents.
- **Registry** — `old_db/0-Prime_Ai_Detail/module_list.md`. Stale in ≥4 places (LmsExam `REVIEW_FOLDER`, LmsHomework `REVIEW_FOLDER`, all 3 FP-2 `DDL_FILE_NAME`s, Payment prefix `pmt_` vs real `ptm_payment_*`).
- **Pattern D36** (generated columns) and the `qns_question_statistics` formula contract are recorded in the AI Brain.
- Stancl/tenancy (`InitializeTenancyByDomain`, `PreventAccessFromCentralDomains`, `EnsureTenantIsActive`, `InitializeTenancyByMobileHeader` with `X-School-Code`); Spatie permissions (cached — needs `forgetCachedPermissions()`); Laravel Dusk + ChromeDriver.

---

## 12. CONVERSATION HIGHLIGHTS — RAW NOTES

**Classification totals:** 47/47 modules · **872 rows**. Original 12 = 266 rows; the 35 added = 606 rows at ~4.6k tokens/screen (prompt target ≤8k) — **within budget**. I initially told the user this would exceed the token-cost estimate; that was wrong and I corrected it.

**Wave-1 agent results:** FP-1 (StudentProfile/StudentFee/Payment: 50 tables, 43 screens) · FP-2 (LmsExam/MarksheetGeneration/Admission: 54 tables, 73 screens) · FP-3 (SchoolSetup/HrStaff/ParentPortal: 80 tables, 103 screens) · ET-1 (6 modules, 116 screens, 89 TcLists) · ET-2 (6 modules, 152 screens, 98 rows) · DS-1 (28 findings: 7 HIGH/15 MED/3 LOW/3 THEORETICAL + 8 false positives logged) · RB-1 (22 TcLists pre-flighted) · EX-1 (771 files static-validated, `php -l` 100% clean) · SR-1 (269 screens assessed, 51 Dusk-candidates, 3 manifests).

**Wave-2 classification agents:** A01-5 Hostel+Library (97) · A01-6 StudentPortal+Transport+Complaint (120, 0% ambiguous) · A01-7 Dashboard+Inventory+Prime (75) · A01-8 FrontOffice+Accounting+SmartTimetable (75) · A01-9 GlobalMaster+Cafeteria+Syllabus+CommonChat (68) · A01-10 Hpc+BA+SyllabusBooks+Ptm+Recommendation (69) · A01-11 Feedback+Certificate+SystemConfig+Vendor+QuestionBank+Billing (57) · A01-12 the 9 small modules (39).

**Other confirmed defects:**
- `Library\LibraryController::store()/update()/destroy()` are LITERALLY EMPTY at lines 988/1009/1014, behind a live `Route::apiResource('libraries', …)` (`api.php:7`). → the `NO-BEHAVIOUR` class; 6 instances across 4 modules.
- `LibBookMasterController`: 3 `rollBack()` (291, 454, 544) but only 2 `beginTransaction()` (361, 528) — the one at 291 has no open transaction. 5-table save with no atomicity.
- `Transport\FeeMasterController`: `store()` (61) writes `TptFeeMaster`(66)+`StudentPayLog`(81) unwrapped; `update()` (112) same; but `destroy`(154)/`restore`(196)/`forceDelete`(231) ARE wrapped.
- `SmartTimetableController` 153,494 chars, 32 methods, routed only via `Route::resource` (web.php:47) + `Route::apiResource` (api.php:8) → **25 of 32 unrouted.**
- 101 files in the Dusk tree have ZERO `$browser->` usage + real HTTP assertions (mis-tiered); 41 files have vacuous `assertTrue(true)`, one is ~39 stub methods.
- Duplicate TC-IDs: `TC-ATT-P14` used for BOTH QR-scan and manual entry; `TC-MI-P25` ×3; `TC-MI-P72` ×2 — each collapsing to ONE test method.
- Vendor PII: `pan_number`/`bank_account_no`/`bank_ifsc_code` now `\App\Casts\SafeEncrypted` (Vendor.php:37-39); `gst_number`(25)/`upi_id`(31) in `$fillable` only — still plaintext.
- **SEC-STP-014 CLEARED:** `Modules/StudentPortal/routes/mobile_api.php` is `require`d from the CENTRAL `routes/api.php:30`, inside `Route::middleware('role:Student|Parent')->group(...)` at line 29 — guard is one layer above the module.
- **EX-1's 617 `BLOCKED` rows are NOT 617 defects** — 473 trip only two systemic house conventions (`markTestSkipped` guards, `->pause()` waits). Needs ONE Rule Card decision.
- Two competing undocumented class-name mechanisms: `tests/Browser/Modules/preload.php` (runtime `class_alias`) vs `tests/Browser/Modules/fix_test_classes.php` (renamer). Which is wired in is unverifiable while `phpunit.xml` is missing.
- SchoolSetup: 376 gate strings, 125 never created (scope-vs-feature mismatch). Whole P0 screens 403 for non-super-admin: Fee Refund, Cheque/DD Reconciliation, leave review.
- `fee_invoices.balance_amount`: DDL says `GENERATED ALWAYS AS (total_amount - paid_amount) STORED`; migration `2026_07_09_000005:19` makes it a plain `decimal(12,2) default 0.00`; `FeeInvoice.php:160` maintains it in PHP and it's in `$fillable` → proves the live column is NOT generated. BUG-FIN-05, recommend P0.

**Selector retrofit payback:** SchoolSetup Employee Wizard blade set = **549,830 chars** (edit 237,644 + create 170,665 + show 141,521) → 2,998-char manifest. 232k tokens saved per Stage-A/B read across 3 screens.

**Useful commands:**
```bash
# ID-convention calibration (run per module before counting)
grep -rhoE "TC-[A-Z]{1,4}-?[0-9]{1,3}\b" "$TCLIST_DIR" | sed -E 's/[0-9]+$/NN/' | sort | uniq -c | sort -rn

# Correct unrouted-method detection
grep -rnE "Route::(api)?resource\([^,]+, *\{Controller\}::class" $APP/routes/
grep -rhoE "\{Controller\}::class, *'[a-zA-Z0-9_]+'" $APP/routes/ | grep -oE "'[a-zA-Z0-9_]+'$" | tr -d "'" | sort -u

# Full authorization check (never Gate-only)
grep -cE "Gate::authorize|Gate::allows|Gate::denies|Gate::any|->can\(|authorize\(|hasRole|is_super_admin|abort\(403" $C

# Phantom-table detection
grep -rhoE "hpc_[a-z_]+" $A/Modules/Hpc/app/Models/ | sort -u | while read t; do \
  [ "$(grep -rl "$t" $A/database/migrations/ | wc -l)" = "0" ] && echo "MISSING: $t"; done
```

**Exact user directions to carry forward, verbatim:**
1. "Save all the file in the Sub-Folder, created in Folder `/Users/bkwork/WorkFolder/3-Local_Workspace/9-TestingStrategy`"
2. "DO NOT make any changes other then folder `/Users/bkwork/WorkFolder/3-Local_Workspace/9-TestingStrategy`"

---
*End of Context Save*
