# Context: GROUP 0 test-case setup prompts (A0.1/A0.2/A0.3) authored, sandboxed, and executed via an 8-agent parallel orchestrator
# Saved: 2026-07-30 13:12
# Session Duration: ~2.5 hours (single continuous session, 5 user turns)
# Project: PrimeAI

---

## 1. SESSION OBJECTIVE

Four escalating requests in one session:

1. Read `TestCase_Generation_Activities_and_Token_Cost_v1.md` and author executable **prompts** for three GROUP 0
   activities — A0.1 (Screen Classification Register build), A0.2 (Category Gold Kit creation, 12 archetypes),
   A0.3 (Canon authoring & maintenance) — saved to a `Prompts/` folder with mandated filenames.
2. **Sandbox all three prompts** so every output lands inside `/Users/bkwork/WorkFolder/3-Local_Workspace/9-TestingStrategy`
   and nothing anywhere else is ever modified.
3. Author a **parallel orchestrator prompt** to run all three concurrently with multiple agents.
4. **Actually run it** — 8 concurrent agents, then roll up their output.

---

## 2. SUMMARY OF WORK DONE

- Read the source cost doc + both companions (`Final_TestCase_Categories_v1.md`, `Prime_AI_TestCase_Generation_Master_Plan_2026Jul29.md`) and verified all canon/DDL/requirement paths on disk before writing anything.
- Authored 3 prompts (~23–26k chars each) in `9-TestingStrategy/Prompts/`.
- Retro-fitted a **binding §0.1 write-sandbox section** into all three, rewrote every output path, and converted A0.3 from an in-place canon editor into a **patch-proposal generator** (its targets live outside the sandbox).
- Authored `RunAll_Parallel_Orchestrator.md` — resolved the A0.1→A0.2→A0.3 dependency chain so all three groups could run concurrently in wave 1 rather than serialising.
- Launched **8 background agents** (4 × A0.1 classification on Sonnet, 3 × A0.2 kit drafts on Opus, 1 × A0.3 on Opus). All 8 completed successfully.
- Performed full orchestrator post-processing: built the 266-row master register by script, merged queues/logs, extracted rule-card candidates + DEV register, generated a tiered Gate-1 spot-check, and wrote a run report.
- Verified sandbox integrity: both source repos `git status` clean, all 6 canon files unmodified (mtimes predate the run), `Testing-Plan/06_*` still absent.
- **Net result: 69 files / 1.2 MB in `9-TestingStrategy`, ~1.51M tokens spent, zero writes outside the sandbox.**

---

## 3. FILES TOUCHED

### Created — prompts (the primary deliverable)
- `/Users/bkwork/WorkFolder/3-Local_Workspace/9-TestingStrategy/Prompts/ScreenClassificationRegister.md` (23,392) — A0.1. Shell-first grep signal battery (S1–S12 + blade greps), stop-at-first-match A1–A12 decision procedure, AMBIGUOUS escalation queue, per-module shards, `_DEV_Candidates` output.
- `.../Prompts/CategoryGoldKit.md` (25,830) — A0.2. **6-file** kit contract (not the Master Plan's 4): Definition, Gold TcList, **Obligations Digest ≤5k chars**, Gold Test, **Idiom Digest ≤15k chars**, Review Rubric. Encodes D3 (AI drafts → tester red-lines) and D4 (obligations not content).
- `.../Prompts/CanonAuthoring_Maintenance.md` (24,817) — A0.3. Five change triggers T1–T5, Rule Card protocol (never renumber, `05_` terse / `05a_` verbose), patch-proposal format, gate-preservation rules.
- `.../Prompts/RunAll_Parallel_Orchestrator.md` (12,665) — the 8-agent launch prompt + wave-2 resume prompt + write-collision rules W1–W7 + acceptance checks.

### Created — orchestrator run output (2026-07-30)
- `.../_ORCHESTRATOR_REPORT_2026-07-30.md` (10,536) — the authoritative run report: reconciliation table, findings F1–F8, defect list, 5 ordered human actions.
- `.../01-Classification/07_Screen_Classification_Register.md` (121,756) — **266 rows, 16 columns**, script-derived summary.
- `.../01-Classification/Shards/{Module}_Classification.md` × 12 — agent-authored source shards (unmodified by roll-up).
- `.../01-Classification/_AMBIGUOUS_Queue.md`, `_DEV_Candidates.md`, `_Run_Log.md`, `_SpotCheck_2026-07-30.md`
- `.../01-Classification/_AMBIGUOUS_{Module}.md` × 12, `_DEV_Candidates_{Module}.md` × 12 (per-agent, kept as source)
- `.../02-Category_Kits/A2_FkDependentMaster/` — `A2_Gold_TcList_DRAFT.md` (68,377), `KIT_READINESS.md`, `_Register_Row_Candidate.md`
- `.../02-Category_Kits/A3_MasterDetail/` — `A3_Gold_TcList_DRAFT.md` (41,113), + same 2
- `.../02-Category_Kits/A7_ReadOnlyList/` — `A7_Gold_TcList_DRAFT.md` (52,057), + same 2
- `.../02-Category_Kits/_RuleCard_Candidates.md` (8,603), `_DEV_Register.md` (6,954), `_Run_Log.md` (42,658)
- `.../03-Canon_Patches/Proposed/2026-07-30_07-08_gold-path-V2.patch.md` (8,435)
- `.../03-Canon_Patches/Proposed/2026-07-30_07-08_category-layer-wiring.patch.md` (27,826)
- `.../03-Canon_Patches/Proposed/2026-07-30_06_taxonomy-freeze.patch.md` (11,773)
- `.../03-Canon_Patches/Taxonomy/06_Screen_Category_Taxonomy.md` (25,268) — the frozen taxonomy payload
- `.../03-Canon_Patches/_Canon_Change_Log.md`, `_Run_Log.md`

### Modified
- Only the 3 prompt files, during the sandboxing pass (§0.1 insertion + path rewrites + A0.3 restructure).

### Discussed/Reviewed (NOT modified — all read-only)
- `/Users/bkwork/WorkFolder/3-Local_Workspace/9-TestingStrategy/TestCase_Generation_Activities_and_Token_Cost_v1.md` — the source spec for A0.1/A0.2/A0.3.
- `.../Final_TestCase_Categories_v1.md` — **authoritative taxonomy** (A1–A12 / M1–M12 / R1–R4 / D1–D11).
- `.../Prime_AI_TestCase_Generation_Master_Plan_2026Jul29.md` — decisions D1–D6, phases, §8 tiering.
- `.../Category_Assigned.md` — team ownership of archetypes.
- `/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/3-Testing_Audit/Testing-Plan/{00_,05_,05a_}` — canon.
- `.../Testing_Prompt/TestCase_Agent_Refinement/1-TC_Creation/{07_,08_}` — the two agent prompts.
- `/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/0-Prime_Ai_Detail/module_list.md` — registry.
- `/Users/bkwork/Herd/prime_ai/Modules/` (46 modules), `/Users/bkwork/Herd/prime_testing/Doc_Analysis/`.

---

## 4. KEY DECISIONS & RATIONALE

- **Decision:** Standardise all prompts on the `A1–A12 / M1–M12 / R1–R4 / D1–D11` taxonomy; treat Master Plan §5's `C1–C10` as superseded. Kit folders named `A{n}_{Name}`.
  **Why:** `Final_TestCase_Categories_v1.md` §8 explicitly supersedes it, and `Category_Assigned.md` already uses `A{n}`. Two live numbering schemes would fracture the register's `Kit to follow` column.
  **Alternatives:** Keep C1–C10 for continuity — rejected; it is the older, smaller taxonomy.

- **Decision:** A0.2 produces **6** kit files, adding an Obligations Digest (≤5k chars) and an Idiom Digest (≤15k chars) to the Master Plan's 4.
  **Why:** §7 optimisations #3/#4 are worth ~10M tokens, and a digest authored later drifts from the gold it summarises. The byte caps + "zero copyable TC rows" rule are the *mechanical* enforcement of decision D4 (obligations, not content).

- **Decision:** A0.3 never edits canon — it emits patch proposals with verbatim anchor text.
  **Why:** Canon lives in `old_db`, outside the user-mandated sandbox. Also genuinely better: canon is read 1,132 times and deserves an explicit human approval step.

- **Decision:** In the parallel run, A0.2 agents **self-classify their own exemplar** instead of waiting for A0.1's register.
  **Why:** A kit needs the archetype of *one* screen (~2k tokens to derive), not 566 rows. This converted a blocking dependency into concurrency, and produced free cross-validation (two independent classifications of the same screen).
  **Alternatives:** Serialise A0.1 → A0.2 → A0.3 — rejected as unnecessary.

- **Decision:** Per-agent output files (`_Run_Log_A01-1.md`, `_AMBIGUOUS_{Module}.md`), never shared append targets; the orchestrator merges.
  **Why:** 8 concurrent agents writing one `_Run_Log.md` clobber each other silently.

- **Decision:** Build the 266-row master register with **shell**, not by re-typing rows through the model.
  **Why:** ~40k output tokens for zero added value; consistent with the prompts' own cost rules.

- **Decision:** Derive every register summary number from the rows by script; distrust agent self-reports.
  **Why:** 4 of 12 shards had arithmetic errors; the agents' aggregate claim was 272 rows vs **266** actually on disk.

- **Decision:** Make the Gate-1 spot-check **tiered** (T1 26 / T2 35 / T3 35 / T4 41) rather than literal.
  **Why:** The prompt's own rule ("10% weighted to A3/A5/A6/A9/A10 **and every P0 row**") yields 100+ rows, which is not a spot-check. Tiers are ordered by cost-of-being-wrong.

- **Decision (user, stated):** Do not call the Agent tool unless requested; do not use workflows/deep-research unless requested.
  **Applied:** All research done inline for turns 1–3; agents launched only in turn 4 when explicitly asked to run the orchestrator.

---

## 5. TECHNICAL DETAILS & PATTERNS

- **Sandbox pattern used in all 3 prompts:** a `§0.1 Output location & write sandbox — BINDING` block with `WORKSPACE_ROOT` / `OUTPUT_DIR` constants, an allowed/forbidden/read-only table, a "no side effects" line (no git, no `mv`/`rm` outside, no app/schema edits), a self-check item requiring the agent to list its writes, and a `PROMOTION CANDIDATES` convention (write to sandbox anyway, log the intended canonical destination, promotion is a human decision).
- **Folder convention established:** `01-Classification/` (A0.1) · `02-Category_Kits/` (A0.2) · `03-Canon_Patches/` (A0.3) · `Prompts/`.
- **Register row format — 16 columns:** `# | Screen | Module | Review Folder | Prefix | Archetype | Modifiers | Overlays | Tier | Signals (evidence) | Kit to follow | Source of row | Confidence | Existing TcList | Existing Test | Complexity`.
- `Signals` must contain **literal grep hits** (backticked); `Confidence` ∈ `HIGH | MED | AMBIGUOUS`; `Source of row` ∈ `CTRL+REQ+ROUTE | CTRL+ROUTE | REQ only (NO-CODE) | CTRL only (DEAD?)`.
- **Roll-up normalisations** (shards left as source of truth): insert a `Review Folder` cell for SchoolSetup's 15-column table; escape `|` → `&#124;` inside backtick spans (perl `s{(`[^`]*`)}{...}ge`) because ~10 rows broke markdown rendering; renumber `#` 1–266.
- **Patch-proposal format:** Target + verified `file:line` · `Change n of N` (INSERT/REPLACE/DEPRECATE) · verbatim anchor block · replacement · Why · Size delta (`±chars → ±tokens × 1,132 reads`) · Companion changes · Blast radius · How to verify.
- **Model allocation:** Sonnet for mechanical A0.1 signal extraction; Opus for A0.2 BC-derivation and A0.3 canon work.
- **Token economics driving everything:** canon is read ~1,132 times (566 screens × 2 stages), so +400 chars of canon ≈ +113k tokens programme-wide.

---

## 6. DATABASE CHANGES

**None.** No migrations, no DDL, no schema edits. All DDL access was read-only grep. Two DDL *gaps* were discovered
and recorded (see §9): Payment has no DDL file at all; TimetableFoundation/LmsExam use tables absent from their
consolidated DDL (the D30 pattern).

---

## 7. PROBLEMS ENCOUNTERED & SOLUTIONS

- **Problem:** A0.3's entire purpose (editing `00_`/`05_`/`05a_`/`07_`/`08_`) is impossible under the sandbox rule.
  **Cause:** Canon lives in `old_db`, outside `9-TestingStrategy`.
  **Solution:** Restructured it into a patch-proposal generator with verbatim anchor text + `Proposed/`→`Applied/` lifecycle. Trigger T3 (kit-definition fixes) remains directly actionable because kits are in-sandbox.

- **Problem:** A0.2 Step 1 requires a register row that A0.1 hadn't produced yet — would have idled 3 agents.
  **Cause:** Genuine dependency chain A0.1 → A0.2 → A0.3.
  **Solution:** Kit agents self-classify their single exemplar via the §8 decision procedure and emit `_Register_Row_Candidate.md` for later reconciliation.

- **Problem:** Roster listed an `Attendance` module that does not exist.
  **Cause:** Attendance is distributed across StudentProfile/ParentPortal/Hpc/Hostel/Transport/MarksheetGeneration.
  **Solution:** Dropped it; 12 modules at 3 per agent. Told A01-1 that StudentProfile owns `AttendanceController.php`.

- **Problem (MINE, significant):** My merge glob `_AMBIGUOUS_*.md` matched the output file being written, feeding it into itself → **69.6 GB** file before the 2-min timeout killed the command.
  **Cause:** `> _AMBIGUOUS_Queue.md` creates the file before the in-loop glob expands, so `cat` read its own target.
  **Solution:** Deleted the file (disk recovered); rebuilt via staged temp files in the scratchpad then `cp`. **No source data lost** — the `rm -f _Run_Log_A01-*.md` line never executed because the timeout killed the command first.

- **Problem:** Register row counts didn't reconcile — 266 on disk vs 272 claimed.
  **Cause:** 4 shards have internally inconsistent self-summaries (TimetableFoundation breakdown 34 / stated 33 / actual 32; SchoolSetup 56 vs 55; Admission double-counts AMBIGUOUS).
  **Solution:** Script-derive all counts from rows; document the discrepancy prominently in the register header.

- **Problem:** `grep` in this environment is shimmed to a `ugrep` wrapper that mis-parses patterns beginning with `->` as flags.
  **Cause:** Shell environment shim.
  **Solution:** Agents used `command grep`. **The A0.1 prompt's §4 recipes still contain the broken form — NOT yet fixed.**

- **Problem:** SchoolSetup's shard had 15 columns; ~10 rows across shards had unescaped `|` inside backticks (broken markdown).
  **Solution:** Normalised during roll-up only; shards untouched.

---

## 8. CURRENT STATE OF WORK

### Completed
- All 4 prompt files authored, sandboxed, internally consistent.
- 8-agent parallel run executed end-to-end; all agents returned success.
- Master register (266 rows) built, summary script-derived, defects/queues/logs merged.
- `_RuleCard_Candidates.md` (15 items) + `_DEV_Register.md` (31 items) extracted for A0.3's follow-up.
- Gate-1 tiered spot-check generated.
- Sandbox integrity verified: both repos clean, 6 canon files unmodified, `06_` absent from canon.
- `_ORCHESTRATOR_REPORT_2026-07-30.md` written with 5 ordered human actions.

### In Progress (exact stopping point)
- **3 gold kits are at Stage 1 only** — drafts exist, awaiting tester red-lines in `02-Category_Kits/_RedLines/` (folder created, empty). Stages 3–6 (rules → Definition → gold test → digests) cannot proceed without human ✂/➕/✏ marks.
- **3 canon patches are PROPOSED, none applied.** Apply order: taxonomy → gold-path → wiring. The wiring patch is **gated** on the register + kits existing.

### Not Yet Started
- Pass-2 on the escalation queue (6 AMBIGUOUS + 89 MED rows).
- 34 unclassified modules outside the release scope.
- Overlay kits R1 Money / R2 Self-Scoped / R3 Tenancy / R4 PII.
- Archetypes A1 (marked Done pre-session), A4, A5, A6, A8, A9, A10, A11, A12 kits.
- A0.3 Rule Card triage of the now-populated `_RuleCard_Candidates.md`.

---

## 9. OPEN QUESTIONS & TODOS

- [?] **BLOCKING — register unit: page or tab?** `Final_TestCase_Categories_v1.md` §3 lists the same StudentProfile page as **A9** ("student details") *and* **A3** ("Health blocks"), never defining the unit. A0.1 chose page (→ Student Edit = A9); A0.2 chose tab (→ health tab = A3). If page wins, the A3 64-TC draft is **void**. If tab wins, the register is under-decomposed. Decide, then record the rule in `06_Screen_Category_Taxonomy.md`. Recurs on every multi-tab screen.
- [?] **A2 exemplar has no UNIQUE key** — cannot demonstrate duplicate-rejection, a headline A2 MANDATORY obligation. Options: accept the N/A, add a companion UNIQUE-bearing exemplar, or move A2 to another module (last two invalidate the 105-TC draft).
- [?] **A7 exemplar is out of scope** — TenantCore `ActivityLogController` isn't in the 12 release modules. In-scope substitute: register **row 64** (LmsExam → Activity Log, A7, M8, P1).
- [?] **A7 draft's blade is 27.5k chars vs the 25k guideline** — disclosed; tester may reject the exemplar.
- [?] Should an obligation the app *cannot* satisfy be `Applies=Yes` with failing TCs, or `N/A` + a DEV entry? (A3 screen has zero server-side line validation.) Changes how every A3 screen is scored.
- [ ] **Fix `Prompts/ScreenClassificationRegister.md` §4**: `command grep` (F5) + add a service-layer write chase (F6). Do this **before** the next A0.1 run.
- [ ] Re-check the 45 A7 + 22 A8 rows against **GET-only route evidence** (Spot-Check Tier 3) — the method-absence signal is proven leaky.
- [ ] Re-measure the "221 of 750 read-only controllers" figure; it is an upper bound and several estimates depend on it.
- [ ] Fix `Final_TestCase_Categories_v1.md` §3's stale A7 examples ("Topic Release Control", "Periods Allocation" have no controller in `Modules/Syllabus/`) before freezing `06_`.
- [ ] Split A2's FK cascade obligations into soft-delete vs force-delete paths (F3).
- [ ] Create/repair the Payment DDL and the missing TimetableFoundation/LmsExam tables before those screens reach Stage A.
- [ ] Review the 63 + 31 defect candidates; raise real ones as `DEV-###` with proving tests.
- [ ] Patch `module_list.md`: LmsExam's `REVIEW_FOLDER` is **`LmsExam`**, not `Exam`; SchoolSetup says `N/A` but an informal `sst_*` suite exists.

---

## 10. IMPORTANT CONTEXT FOR FUTURE SESSIONS

**User preferences stated this session:**
- "Do not call the AgentTool unless the user requested it. Do not use workflows or deep-research unless requested."
- **Everything must be saved inside `/Users/bkwork/WorkFolder/3-Local_Workspace/9-TestingStrategy`; no prompt may change anything anywhere else.** This is absolute and is why A0.3 proposes rather than edits.
- Prompts live in `9-TestingStrategy/Prompts/` with the exact filenames the user specified.

**Non-negotiable programme rules encoded in the prompts (do not soften):**
1. If it isn't in the DDL, controller, route, FormRequest or a stated business rule — it is not tested.
2. Every TC carries a `Source` anchor (`DDL-{table}.{column}` · `Ctrl-{X}::{method}` · `Route-{name}` · `FR-{X}.{rule}` · `Req-BR-{n}` · `Audit-{ID}`). No anchor → deleted at review.
3. Never invent routes, selectors, permission strings, table names, ENUM values, error messages.
4. Category FORBIDDEN lists are binding; disagreement = ONE `⚠️ CATEGORY-EXCEPTION` note, never extra TCs.
5. Never let the model guess a fix — feed real failure output.
6. Defects → `DEV-###` with a proving test, never silently fixed.
7. An unexecuted test is inventory, not coverage.

**Read order is load-bearing:** DDL **first**, requirement doc second (intent only, never schema truth). Reading
the narrative first is what caused the original drift. This was validated live: the A2 requirement doc had invented
CSV/PDF export, a multi-step form and "medications administered" — zero TCs were emitted for any of them.

**Cost controls that must stay hard rules in `07_`/`08_`:** repair loop capped at **3 iterations**; never full-read a
DDL / >40k controller / large blade; annotate `Covered By` with targeted `Edit` — a full `Write` of the TcList is
**forbidden**; never load `05a_` (42k chars) unless a rule is contested.

**Layer defaults (fixing the inverted pyramid — 691 browser vs 146 non-browser tests today):** Feature is the
default; Dusk **only** where the DOM or JS is the thing under test. Target 15% Unit / 70% Feature / 15% Dusk.
`Dusk\Browser` has **no `assertStatus()`** (Rule Card #14) — server assertions belong at the Feature layer.

**Next free Rule Card number is 49.** `05_` numbers rules as list items inside band headings (A–G), **not** as
`### G49` headings — so `grep -nE "^### [A-G][0-9]+"` returns nothing; use `^[0-9]+\. `.

---

## 11. DEPENDENCIES & CROSS-MODULE REFERENCES

- **App:** `/Users/bkwork/Herd/prime_ai` — Laravel 11/12, `nwidart/laravel-modules`, `stancl/tenancy ^3.9`, `spatie/laravel-permission ^6.21`, `spatie/laravel-medialibrary ^11.17`, `laravel/dusk ^8.3`, `pestphp/pest ^4.1`. AdminLTE/Blade + Alpine.js — **no Livewire**. 46 modules (verified list this session).
- **Test estate:** `/Users/bkwork/Herd/prime_testing` — `Doc_Analysis/1-Module_DDLs/`, `Doc_Analysis/4-TC_List_Requirement_Review/{REVIEW_FOLDER}/{Module_Requirement,TC_List}/`, `tests/Browser/Modules/`.
- **Gold reference pair (READ-ONLY):** `prime_testing/tests/Browser/Modules/Recommendation/V2/RecommendationMasters/RecommendationModes/` → `lms_rec_RecommendationModeTcList.md` (40,860) + `RecRecommendationModeV2Test.php` (61,040). **Note the `/V2/`** — both agent prompts cite the path without it (`08_:62`, `07_:68`) and that directory does not exist.
- **Canon:** `old_db/3-Testing_Audit/Testing-Plan/` (`00_`, `05_`, `05a_`) and `old_db/3-Testing_Audit/Testing_Prompt/TestCase_Agent_Refinement/1-TC_Creation/` (`07_`, `08_`).
- **Registry:** `old_db/0-Prime_Ai_Detail/module_list.md`.
- **DDL repo:** `/Users/bkwork/WorkFolder/2-New_Primedb/pgdatabase/2-DDL_Tenant_Consolidated/`.
- **Existing agents relevant to wave 2:** `tclist-author` (Stage A), `testcase-scripter` (Stage B), `tclist`/`testcase-creator`, plus `pa-testing-architect`.

---

## 12. CONVERSATION HIGHLIGHTS — RAW NOTES

**Register spread (script-derived from 266 rows — the authoritative numbers):**
```
A2 75 · A7 45 · A1 38 · A6 34 · A8 22 · A5 12 · A4 9 · A3 7 · A10 7 · A9 6 · A11 3 · A12 2 · AMBIGUOUS 6
Tier: P0 69 · P1 103 · P2 51 · P3 43
Confidence: HIGH 171 (64%) · MED 89 (33%) · AMBIGUOUS 6 (2.3%)
Overlays: R1 41 · R2 27 · R3 266 (all) · R4 121
Per-module: SchoolSetup 55 · TimetableFoundation 32 · LmsExam 30 · HrStaff 29 · StudentFee 24 ·
            MarksheetGeneration 24 · ParentPortal 19 · Admission 17 · Notification 13 ·
            StudentProfile 11 · Payment 8 · StandardTimetable 4
```

**Agent roster actually launched (all 8 succeeded):**
```
A01-1 Sonnet  SchoolSetup, Admission, StudentProfile        → 83 rows, ~145k tok
A01-2 Sonnet  TimetableFoundation, StandardTimetable, LmsExam → 66 rows, ~235k tok
A01-3 Sonnet  MarksheetGeneration, StudentFee, Payment      → 56 rows, ~259k tok
A01-4 Sonnet  HrStaff, Notification, ParentPortal           → 61 rows, ~265k tok
A02-1 Opus    A2 kit · StudentProfile → Medical Incidents   → 105 TCs, ~95k tok
A02-2 Opus    A3 kit · StudentProfile → health tab          →  64 TCs, ~95k tok
A02-3 Opus    A7 kit · TenantCore → Activity Log Viewer     →  63 TCs, ~65k tok
A03-1 Opus    3 canon patch proposals                       → ~141k tok
```

**Reconciliation (the payoff of the parallel unblock):**
```
A2: A0.2 says A2 · A0.1 row 8 "Medical Incident" says A2, M1, R3+R4, P2   → AGREE ✅
A3: A0.2 says A3 (health tab) · A0.1 row 2 "Student Edit" says A9         → DISAGREE (granularity) ⚠️
A7: A0.2 exemplar = TenantCore · no register row (out of 12-module scope) → OUT OF SCOPE ⚠️
```

**Highest-severity defects recorded (never fixed, no app code touched):**
- `deleteVaccinationRecord` — `findOrFail($id)` with no `student_id` scoping → **IDOR on child medical data**.
- `FeeStudentConcessionController` — `approval_status` (Pending/Approved/Rejected) moved via generic `update()`; no separately-permissioned approve/reject → **money-approval bypass**.
- Saving the health form with **no rows wipes the student's entire vaccination history**.
- `LmsExamController::saveBulkGrades` — no transaction around a multi-table, multi-student loop.
- `StudentIaMarkController`, `StudentCoscholasticResultController` — reference `index`/`create`/`edit` views absent from disk → **routes 500**.
- `deleted_at` on both health tables but neither model uses `SoftDeletes` → **child PII hard-deleted**.
- Route collision: `SchoolSetup\StudentLeaveTypeController` and `StudentProfile\StudentLeaveTypeController` both register `Route::resource('student-leave-types')`.
- 4 dead controllers: `AdmSettingsController` (20 methods, 0 routes), `EmployeeReportSeederController`, `StudentFeeController` (routed scaffold stub), `ParentPortalController` (empty CRUD bodies).

**Notable NEGATIVE result (evidence-backed, not absence of looking):** the ParentPortal IDOR sweep traced every
mutating/detail/download route across all 19 screens and found **no unguarded route** — scoping is centralised in
`ParentContextService::resolveChild()` plus per-screen asserts like
`abort_unless($invoice->studentAssignment?->student_id === $child->id, 403)`.

**Top environment truths captured for the Rule Card (in `_RuleCard_Candidates.md`):**
- **E7 (most generalisable):** where a parent uses `SoftDeletes`, `ON DELETE CASCADE`/`SET NULL` never fire through the UI — only `forceDelete()`. A2 cascade tests otherwise silently assert nothing.
- **E2:** no seeder creates `sys_dropdown_table` rows for `key = '{table}.{column}'`, so dropdowns are empty on a fresh tenant and **no create test can pass** without seeding.
- **E4:** SweetAlert2 confirm strings are fixed by shared components verbatim — `Sure to Edit?`/`Yes, proceed!`, `Move to Trash ?`/`Yes, move to trash!`, `Sure to restore?`, `Delete Permanently ?`/`Yes, delete permanently!` (source `resources/views/components/backend/table/action.blade.php:65-100`).
- **E5:** `flash('created.medical_incident')` → "Medical Incident was created successfully." via `config/flash.php` + `app/Helpers/helpers.php:11-33`.
- **ENV-A3-01/02:** `std_health_profiles` has no `created_at`; `std_vaccination_records` has no `updated_at`; both models set `$timestamps = false` → assertions on the missing column fail with an SQL error.
- **ENV-A3-03:** `App\Casts\SafeEncrypted` keys off `tenant()->getKey()`; reading ciphertext outside the writing tenant returns `null` + a logged warning, never throws → assert `null` explicitly.
- **ENV-A3-06:** StudentProfile has **no module-level migrations** — all its tables live in app-level `database/migrations/tenant/`. A DDL-first agent pointed at `Modules/{M}/database/migrations` finds nothing and invents.

**Useful shell recipes proven this session:**
```bash
# extract register rows from a shard's Register section only
awk '/^## Register/{f=1;next} /^## /{f=0} f && /^\| *(\*\*)?[0-9]+/' shard.md
# escape pipes inside backtick spans (fixes broken markdown tables)
perl -pe 's{(`[^`]*`)}{ my $x=$1; $x =~ s/\|/&#124;/g; $x }ge'
# grep patterns starting with -> MUST use `command grep` (ugrep shim mis-parses them as flags)
command grep -nE -- "->sync\(|->attach\(" file.php
```

**Canon integrity proof at end of run** (mtimes all predate 2026-07-30):
`00_` 2026-07-14 23:50 · `05_` 2026-07-14 23:39 · `05a_` 2026-07-14 23:38 · `07_` 2026-07-24 19:09 ·
`08_` 2026-07-24 19:13 · `module_list.md` 2026-07-26 18:13 · `Testing-Plan/06_*` absent ·
`prime_ai` + `prime_testing` `git status` clean.

**Wave-2 launch prompt is ready** in `Prompts/RunAll_Parallel_Orchestrator.md` §4 (resume 3 kit agents at Stages 3–6
with red-lines + run A0.3's Rule Card triage).

---
*End of Context Save*
