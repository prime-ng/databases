# Refinement Prompt v3 — Consolidate Artifacts (7 → 5) to Cut Output Tokens, Same Quality

**Purpose:** Reduce token/$ cost further by **removing duplicated artifacts**, not coverage. Two consolidations, both proposed by the maintainer and confirmed as genuine (output-side) savings:
1. **Merge the MANUALTESTING doc INTO the TcList doc** — one requirement file that serves both purposes (7 artifacts → 6).
2. **Replace the two runner scripts (`.ps1` + `.sh`) with ONE cross-platform runner** (6 → 5).

This composes with v1 (quality constraints F33–F48/G43–G48) and v2 (compress the always-read surface, Fact Pack, caching, single-pass — two-phase retired). **v3 does not touch any of those; it only collapses redundant OUTPUT.**

**Run this prompt once** (a maintenance/refinement task). After it completes, the agent emits **5 artifacts per feature** instead of 7, with identical coverage.

> **Prime directive (non-negotiable): QUALITY IS THE FLOOR.** Every Business Condition, every Test Case, every manual step a human tester needs, every coverage gate, and the `php -l` gate survive the merge. You are deleting *duplication and boilerplate*, never *content*. A merge that loses a TC, a BC, a manual step table for a complex/money/workflow flow, or the runner's ability to run on either OS is a FAILURE.

---

## 0. Read these first (do not skip)
1. **The cost direction & measured context:** `…/TestCase_Agent_Refinement/Refinement_Prompt_TestCase_Creator_Agent_v2.md` (esp. its L4 output-reduction lever and the §2 "where the tokens go" table) and the `TokenReduction_Plan_TestcaseCreator.md` dry-run results. v3 is the artifact-consolidation companion to v2's L4.
2. **The agent's single source of truth (files you will EDIT):**
   - `…/Testing-Plan/03_Testcase_Creator_Agent_Prompt.md` — Artifact Contract, workflow Steps 4/5/8/9, filenames, quality gate.
   - `…/Testing-Plan/00_Testing_Artifacts_Index_and_Conventions.md` — §3 "The 7-Artifact Contract" table, generation order, §3.1 token discipline.
   - `~/.claude/agents/testcase-creator/AGENT.md` — the loader (mentions the "7-artifact" set in its description).
3. **A committed sample to preserve fidelity against** (read to see exactly what MANUALTESTING uniquely carries before you fold it in): a completed feature's `…MANUALTESTING_Require.md` + `…TcList_Require.md` + `run-*.ps1`/`run-*.sh` (e.g. under `…/TestCases/**/BillingCycle/` or `…/BehaviouralAssessment/Category/`).

---

## 1. Re-evaluation — do these actually save tokens? (record this reasoning; don't overclaim)
- **Output tokens dominate cost** (5× input on Opus). Removing a whole emitted document and one of two emitted scripts is a direct output cut on **every feature of every module** — it compounds.
- **Merge MANUALTESTING → TcList = the bigger win.** MANUALTESTING re-states the BC tables and the method matrix that TcList already contains; its only *unique* value is (a) the Feature-Information header and (b) the human-tester Step/Action/Expected tables with DB + activity-log checks. Fold (a) and (b) into TcList and the rest was pure duplication. Net: one fewer file header/boilerplate, no restated BC/method matrix, one fewer artifact for the agent to reason out — **zero coverage loss**.
- **Single runner = smaller but real.** The `.ps1`/`.sh` pair is identical logic in two dialects; emitting one instead of two removes ~50–67 lines of output per feature and the dual-dialect reasoning.
- **Honest scale:** these are **incremental** savings, smaller than v2's L1 (compressing the 42 KB always-read `05_`), but **low-risk** because they never touch coverage. Do them; don't oversell them. Measure the real output delta in §4.

---

## 2. Governing principles
1. **Merge = relocate content, not delete it.** Every section that carried tester-necessary information moves into the surviving file. Nothing a human tester or the traceability chain relies on is dropped.
2. **Reconcile with v2's L4.** v2 said "MANUALTESTING references the TcList method table." v3 **supersedes that specific instruction by merging the two outright** (the endpoint of the same idea). Keep v2's other de-dup principle: GAPANALYSIS still maps to — does not restate — the method list.
3. **This changes the Artifact Contract (7 → 5) — update it everywhere consistently.** `03_`, `00_`, the loader description, the quality gate, the generation order, and every filename reference must agree. A dangling "7 artifacts" or a reference to the deleted MANUALTESTING filename is a defect.
4. **The runner format is a team-workflow decision — recommend, then flag for approval.** A native `.ps1`+`.sh` polyglot is fragile; do NOT generate one. Recommend a **single portable PHP runner** (`run-{Feature}-tests.php`, invoked `php run-{Feature}-tests.php …`) because PHP is guaranteed present in this Laravel/Dusk project, so it runs natively on Windows and Linux with no shell hacks. Offer "standardise on a single `.sh`" as a lighter alternative. **Surface this as a design decision for the user in the summary**; encode the chosen default (PHP runner) but note it's approval-pending.
5. **Actionable, checkable, reversible.** Snapshot the four files before editing. Phrase new rules as imperatives the quality gate can check.

---

## 3. What to change

### Change A — Merge MANUALTESTING into TcList (surviving file: `{prefix}_{Feature}TcList_Require.md`)
Fold the manual-testing essentials into TcList so it serves both machine-traceability and human-tester purposes. The combined file's sections:
1. **Feature Information** (from MANUALTESTING): Module, Feature, URL, Controller, Models, Validation, Migrations, CRUD Type, Soft Delete, Pagination, Activity Log.
2. **Business Conditions** — the full BC-* tables, each with its `Source` tag (unchanged).
3. **Test Case List** — the TC-P/N/D (+T/S/SM) tables, columns `TC ID | Category | BC | Source | Description | Expected Result | Test Method | Status` (unchanged).
4. **Test Method Index** (unchanged) — every method ↔ TC.
5. **Manual Test Steps** — Step/Action/Expected tables **with explicit DB checks (`SELECT … expect …`) and activity-log checks**, provided **only for the cases a human tester genuinely needs to walk** (complex multi-step flows, money/financial paths, workflow/state-machine transitions). Simple CRUD/validation cases are fully covered by the `Expected Result` column in section 3 — do not restate them as step tables (this is the v2/L4 de-dup, now enforced by the merge).
6. **Known Source Defects** subsection if any (unchanged).

- **Delete the separate `{prefix}_{Feature}MANUALTESTING_Require.md` artifact** from the contract. Its content now lives in TcList sections 1 and 5.
- **In `03_`:** merge Step 5 (MANUALTESTING) into Step 4 (TcList) — one authoring step producing the combined file; renumber/annotate so the workflow reads cleanly. Update the artifact-templates section accordingly.
- **In `00_` §3:** collapse rows 1 and 2 of the contract table into one, and fix the generation order.
- **Preserve GAPANALYSIS** as a separate file (it is the coverage/traceability artifact and maps to the combined TcList — do NOT merge it in; keeping mapping separate is what makes gaps visible).

### Change B — One cross-platform runner (replace `run-{Feature}-tests.ps1` + `.sh`)
- **Emit a single `run-{Feature}-tests.php`** (default recommendation) that does everything the two scripts did: accept php-binary/filter/sync-db params, clean old screenshots, run `php artisan dusk --filter=…`, tee output to a timestamped `proof/` file, parse `Tests: N, Assertions: A, Failures: F`, print a summary, and exit with the dusk exit code. It must run under both Windows and Linux (`php` is present on both; use PHP's `PHP_OS_FAMILY`/`proc_open` rather than shell-specific calls).
- **Delete `run-{Feature}-tests.ps1` and `run-{Feature}-tests.sh`** from the contract.
- Do **not** produce a `.ps1`/`.sh` polyglot. If the user prefers the lighter "single `.sh`" option instead of a PHP runner, that is a one-line switch — note it in the summary.
- Update `03_` Step 8 (runners) and `00_` §3 rows 6/7 accordingly.

### The new 5-artifact contract (update the table in both `03_` and `00_`)
| # | Filename | Purpose |
|---|----------|---------|
| 1 | `{prefix}_{Feature}TcList_Require.md` | **Combined**: Feature Info + BC + TC list + Method Index + Manual Test Steps (complex/money/workflow only) |
| 2 | `{prefix}_{Feature}GAPANALYSIS_Require.md` | Coverage/traceability map to the combined TcList |
| 3 | `{prefix}_{Feature}_TestCas.php` | The one comprehensive Dusk suite (unchanged) |
| 4 | `{prefix}_{Feature}Validation_Report.md` | QA gate/verdict (unchanged) |
| 5 | `run-{Feature}-tests.php` | Single cross-platform runner (approval-pending format) |

### Cross-references & loader
- Update the **loader `AGENT.md` description** ("7-artifact test suite" → "5-artifact test suite") and any step text that enumerates the artifacts.
- Update the **quality gate** in `03_`: change "All 7 files written" → "All 5 files written"; add a check "TcList contains the Feature-Information + Manual-Test-Steps sections merged from the former MANUALTESTING (no separate MANUALTESTING file)"; add "single `run-*.php` present; no `.ps1`/`.sh` pair"; keep every existing quality-gate line (F/G checks, `php -l`, coverage gates) intact.
- Search all four files for the literals `MANUALTESTING`, `7-artifact`, `7 artifacts`, `.ps1`, `run-*.sh`, `6/7`, `Steps 6/7` and reconcile each.

---

## 4. Prove it: quality preserved + real output delta
1. **Quality (no loss):** on a scratch regeneration of ONE feature, confirm the combined TcList contains **every BC and every TC** the two old files did, **plus** the Manual Test Steps for the complex/money/workflow cases; confirm GAPANALYSIS still maps every method; confirm the single runner performs all steps the two scripts did and runs on both OS (at least dry-run/lint it — `php -l run-*.php`).
2. **Output delta (the saving):** measure combined output size (lines/bytes, and tokens if available) of the **5-artifact** set vs the committed **7-artifact** set for the same feature. Report the delta. Expect a modest but positive reduction (one doc + one script removed, minus the manual-steps folded back into TcList).
3. Never write to `TestCases/`, `prime_ai`, or `prime_testing` during validation — use a scratch folder.

## 5. Verification before you finish
1. No `MANUALTESTING` artifact remains in the contract, and its tester-essential content is present in TcList.
2. No `.ps1`/`.sh` pair remains; a single runner is specified; the format decision is flagged for the user.
3. Every "7-artifact"/"7 files"/generation-order/cross-reference is updated to 5; the quality gate and loader description agree.
4. No coverage gate, constraint (F33–F48/G43–G48), or `php -l` gate was weakened.
5. No rule directs edits to `prime_testing`/`prime_ai`.

## 6. Deliverable / final summary
Report concisely:
- Files edited; the new 5-artifact contract; the measured output delta vs the 7-artifact baseline (and the quality-preserved confirmation).
- The **runner-format design decision** surfaced for the user (PHP runner recommended; single-`.sh` as the lighter alternative), noting the polyglot was rejected as fragile.
- Explicit confirmation that **coverage/quality is unchanged** — every BC/TC/manual-step preserved, GAPANALYSIS still separate, `php -l` and all F/G constraints intact.

## Non-goals / guardrails
- Do NOT drop any BC, TC, manual step for complex flows, coverage gate, constraint, or `php -l` to save tokens. Merge = relocate, not delete.
- Do NOT merge GAPANALYSIS into TcList (keeping the coverage map separate is what surfaces gaps).
- Do NOT generate a fragile `.ps1`/`.sh` polyglot.
- Do NOT edit `prime_ai`/`prime_testing`/`TestCases/`; touch only `Testing-Plan/` + the loader.
- Do NOT claim a cost reduction you did not measure. Verify model IDs/pricing live via the `claude-api` skill before quoting any $ figure.
