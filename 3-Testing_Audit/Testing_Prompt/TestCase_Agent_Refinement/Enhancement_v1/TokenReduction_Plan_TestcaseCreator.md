# EXECUTABLE PROMPT — Reduce Token Cost of the "TestCase Creator" Agent (keep quality)

**Purpose:** Cut the token/$ cost of generating the 7-artifact test suite per feature, without
losing coverage or fidelity. This is a config-only change to the TestCase Creator agent — no live
test regeneration is part of this task.

**How to run this:** Paste this file's contents (or say "execute
`Testing_Prompt/TokenReduction_Plan_TestcaseCreator.md`") into a fresh session. Work top-to-bottom.
Phases are gated — stop at each GATE for the user's approval before proceeding.

---

## 0. Context — why this is needed (measured, not assumed)

Observed during the BehaviouralAssessment run (24 features, all on Opus 4.8):
- Each `testcase-creator` agent burned **~100k–210k tokens**; module total ≈ **~4M tokens**.
- **Output tokens dominate cost.** The `_TestCas.php` is 60–78 KB (~20–25k output tokens) and the
  6 companion docs add more. On Opus, output is **$25/MTok vs $5 input** (5×).
- **Redundant source reading.** Every one of the 24 agents independently re-read the same large
  inputs: the Testing-Plan agent prompt (~977 lines / ~32k tokens), `05_Known_Test_Failure_Constraints.md`,
  the sibling reference `.php`, the module DDL, and the controller. The `bha_`→`ba_` prefix fact was
  re-discovered 24 times.
- **Proven fact:** the 6 companion docs are mechanically derivable 1:1 from a finished `.php` — the
  crash-recovery "docs-only completion" agents produced full-quality docs from the existing `.php`
  alone. This is the key lever: the docs do not need the expensive model.

### Current model pricing (verify at run time via the `claude-api` skill; values as of 2026-07)
| Model | Input $/MTok | Output $/MTok |
|---|---|---|
| Opus 4.8 (`claude-opus-4-8`) | $5.00 | $25.00 |
| Sonnet 5 (`claude-sonnet-5`) | $3.00 ($2 intro→2026-08-31) | $15.00 ($10 intro) |
| Haiku 4.5 (`claude-haiku-4-5`) | $1.00 | $5.00 |

Prompt caching: cache **reads ≈ 0.1× input price**; writes 1.25× (5-min TTL) / 2× (1-hr). ~90% off
the cached portion once warm.

### Config surfaces to edit (all under Testing-Plan/, plus the loader)
- `/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/3-Testing_Audit/Testing-Plan/00_Testing_Artifacts_Index_and_Conventions.md`
- `.../Testing-Plan/03_Testcase_Creator_Agent_Prompt.md`
- `.../Testing-Plan/05_Known_Test_Failure_Constraints.md` (reference only; don't bloat)
- `~/.claude/agents/testcase-creator/AGENT.md` (thin loader)

**Output discipline (unchanged):** touch only Testing-Plan/ + the loader. Never write to
prime_ai / prime_testing / TestCases/ during this task.

---

## GATE 0 — snapshot before editing
1. `date "+%Y-%b-%d"` and snapshot the 3 planning docs + loader to
   `Testing-Plan/_backup_<date>_tokenreduction/` (one-line rollback available).
2. Confirm `git status` is clean-ish / note pre-existing changes so later diffs are attributable.
STOP — report the snapshot path, then proceed.

---

## LEVER 1 (P1, biggest win) — Two-phase generation with model routing

**Rationale:** Output tokens are the dominant cost, and ~60% of per-feature output is the 6 docs,
which are mechanical. Route the mechanical output to a cheaper model; keep the reasoning-heavy
`.php` on the strong model.

**Change:** Make the agent generate each feature in TWO phases:
- **Phase 1 — Test file (reasoning-heavy):** produce the single comprehensive `_TestCas.php` only.
  Model: **Opus 4.8** by default; allow **Sonnet 5** for CRUD/report/light features (keep Opus for
  workflow/FSM-heavy features — those with a populated BC-SM band, e.g. period/assessment state
  machines). Write the `.php` FIRST and flush it to disk before anything else (crash-resilience —
  a killed run keeps the expensive artifact).
- **Phase 2 — Companion docs (mechanical):** read the finished `.php` and generate the other 6
  artifacts (TcList, MANUALTESTING, GAPANALYSIS, Validation_Report, run-*.ps1, run-*.sh) 1:1 from
  it. Model: **Sonnet 5** (try **Haiku 4.5** for the two runners + Validation_Report). Do NOT
  rewrite the `.php` in Phase 2.

**Encode:**
- In `03_` add a "Two-Phase Generation" section with the phase boundary, the "write .php first +
  flush" rule, and a per-phase model tag the orchestrator/subagent reads.
- In `00_` note the phase split in the artifact contract (still 7 artifacts, just produced in 2 passes).
- In the loader, document that Phase-2 docs-only runs may use a cheaper model.
- Add a feature-classification rule: `depth ∈ {Light, CRUD}` and no BC-SM band → Sonnet-5-eligible
  for Phase 1; workflow/FSM/P0-money features → Opus.

**Est. savings:** 40–55% of total spend, no quality loss on docs (proven by the crash-recovery runs).

**GATE 1 — dry-run validation:** regenerate ONE already-done feature (e.g. HrStaff/LeaveType, or a
BehaviouralAssessment feature) into a SCRATCH folder (not TestCases/) using the two-phase flow, and
diff the artifacts + method counts + `php -l` against the committed version. Confirm: (a) docs match
1:1, (b) `.php` quality holds if Phase 1 ran on Sonnet 5. Report the token delta. STOP for approval.

---

## LEVER 2 (P1) — Module "Fact Pack" computed once, injected into every feature

**Rationale:** Discovery (schema/tables, real table prefix, controller→screen map, routes,
permission prefixes, known audit defects) is re-derived by every feature agent. Do it once per module.

**Change:** Add a **Fact Pack** step at module start (report/inventory mode):
- Produce `TestCases/{Module}/{Module}_FactPack.md` containing: verified table prefix + the
  doc-vs-live divergence (e.g. `bha_` filenames / `ba_` live tables, DOC-BA-001), CREATE TABLE list
  with columns, controller→screen map, route list, permission prefix, base-class/tenancy scaffolding
  choice (prime vs tenant), and the module's known audit defects (BUG/SEC/VAL/DATA/DEAD/DOC IDs).
- Each per-feature Phase-1 prompt **receives the Fact Pack** and is told to trust it instead of
  re-deriving — reading source only to confirm feature-specific details.

**Encode:** new step in `03_` ("Step 0.5 — build/reuse the module Fact Pack"), and a per-feature
rule "if a FactPack exists for this module, read it first and don't re-discover module-wide facts."

**Est. savings:** 15–25% of input tokens across all but the first feature.

---

## LEVER 3 (P2) — Batch features by shared controller

**Rationale:** One controller often serves many screens (e.g. `BaReportController` served ~10 of the
24 BHA screens; `BaAssessmentController` served 4). Each separate agent re-reads the whole controller.

**Change:** Add a discovery rule that groups screens by backing controller and lets ONE agent
generate that controller's cluster of Phase-1 `.php` files in a single run (reads the controller
once). Phase-2 docs can still fan out per feature on the cheap model.

**Encode:** in `03_` module-mode, add "group features by controller; a controller cluster may be
generated in one Phase-1 agent." Keep the per-feature output-folder discipline intact.

**Est. savings:** large on report-heavy modules; also fewer agent spin-ups (less fixed overhead).

---

## LEVER 4 (P2) — Prompt caching + trim doc duplication

**Rationale:** The same large prefixes are re-read every run; and TcList/MANUALTESTING/GAPANALYSIS
each re-enumerate all ~50 methods.

**Change:**
- **Caching discipline:** keep the Testing-Plan prompt, `05_` constraints, and the reference `.php`
  **byte-stable** during a batch, and run features **back-to-back** so those prefixes stay
  cache-warm (reads ≈ 0.1× vs full price). Add a note: don't edit those files mid-batch.
- **De-duplicate docs:** have MANUALTESTING **reference** the TcList method table rather than
  restate every method step-by-step; keep the full step tables only where they add manual-tester
  value. This cuts output on the most duplicative artifact without dropping coverage.

**Encode:** a "Token discipline" subsection in `00_`; adjust the MANUALTESTING template in `03_`.

**GATE 2 — no-regression check:** re-confirm all protected strengths still hold (screen-based
feature model, module-folder-first + timestamped non-overwrite output, TC-T/TC-S/a11y dimensions,
BC-SM taxonomy, Source tags + Coverage-Score, Cross-Reference Defect Scan, V2≥2×V1 where applicable,
`php -l` gate, output discipline). All edits confined to Testing-Plan/ + loader. STOP for approval.

---

## Ordering & expected combined effect
Implement in this order (highest ROI first): **Lever 1 → Lever 2 → Lever 3 → Lever 4**, with the
two GATE dry-runs. Combined, these target roughly a **2–3× reduction** in $/module versus the
all-Opus, single-phase, re-discover-everything baseline, with the docs half proven lossless and the
`.php` half validated per-feature-class before rollout.

## Non-goals / guardrails
- Do NOT reduce coverage, drop artifacts, or weaken the `php -l` gate to save tokens.
- Do NOT let Phase 2 (cheap model) touch the `.php`.
- Do NOT regenerate any committed TestCases as part of this task — this is agent-config only.
- Verify model IDs/pricing live via the `claude-api` skill before quoting cost numbers.

## Resume checklist
- [x] GATE 0 snapshot taken — `Testing-Plan/_backup_2026-Jul-14_tokenreduction/` (00_, 03_, 05_, loader AGENT.md)
- [x] Lever 1 encoded (two-phase + model routing + feature-class rule) — `03_` new §"Two-Phase Generation & Model Routing"; `00_` §3 phase split; loader routing bullet
- [x] **GATE 1 dry-run** — QUALITY passed; COST inconclusive/concerning (see measured results below)
- [x] Lever 2 encoded (Fact Pack step + per-feature reuse rule) — `03_` Step 0.5 + module-mode step 1b + Feature Inventory `Model` column
- [x] Lever 3 encoded (controller-cluster batching) — `03_` module-mode step 3b
- [x] Lever 4 encoded (caching discipline + MANUALTESTING de-dup) — `00_` §3.1 + `03_` Step 5 de-dup rule
- [x] GATE 2 no-regression check — **PASSED** (static: all protected strengths intact; empirical: coverage bands identical, no category dropped).
- [x] Summary written back here with measured token deltas — **DONE (see below); $ delta directional only (no in/out split available)**

### GATE 1 + GATE 2 DRY-RUN RESULTS (2026-Jul-14) — target: BehaviouralAssessment/Category (Light/CRUD)
Baseline = committed Opus single-phase (`.php` = 55 methods, 78KB, php -l clean). Both dry-run phases ran on **Sonnet 5** into a scratch folder (nothing written to TestCases/).

**QUALITY — PASS.**
- Phase-1 `.php` (Sonnet): **50 methods** (vs 55 Opus = 91%), `php -l` clean, **coverage bands identical** (00,10,20,30,40,50,60,70,90 — no category dropped), all batch-1/2 constraints applied (0 hollow/`isCasted`/`isActive`; `forgetCachedPermissions`, `assertGreaterThanOrEqual`, 13×`refresh()`, independent soft-delete check, duplicate-rejection, over-length boundary, 403 negatives, tenancy all present). Independently found 9 source defects (DOC-BA-001 prefix divergence, no DB UNIQUE behind the composite rule, unbounded weight/sort_order, etc.). → **Sonnet-5 Phase-1 quality HOLDS for Light/CRUD.**
- Phase-2 docs (Sonnet, from committed `.php`): all 6 regenerated, **55/55 methods traced 1:1** into TcList + GapAnalysis, MANUALTESTING de-dup **−36%** (268→171 lines) with no coverage lost. → **Docs are mechanically derivable; Lever-4 de-dup works.** Caveat: cheap model silently abbreviated method names and broke exact-string traceability until a grep self-check caught it — **add a grep full-method-name check as a standard Phase-2 step.**

**COST — INCONCLUSIVE / CONCERNING (this is the important finding).**
- Measured tokens: **Phase-1 = 219,124; Phase-2 = 163,413; two-phase TOTAL = 382,537** for one feature.
- Plan baseline (single-phase all-Opus) = **~100k–210k tokens/feature**. So the two-phase split, **run as two isolated cold agent spawns, used ~1.8–3.8× MORE tokens** — because each phase independently re-read the large shared context (`03_`, `00_`, `05_` now 42KB, golden reference, DDL, controller, models, policy, Blade). The discovery was **paid twice**.
- The savings thesis is model routing ($/token), not token count. Opus/Sonnet rate ratio ≈ 1.67×; measured token ratio ≈ 1.9–3.8×. So the cheaper model does **not** obviously overcome the extra tokens → **net ≈ break-even to slightly worse** as measured. The projected **2–3× reduction is NOT substantiated** by this run.
- **Two confounds that make this a near-worst-case measurement, not the real steady state:** (a) **Levers 2 (Fact Pack) and 4 (caching) were NOT active** — no Fact Pack was pre-built and two cold spawns don't share a warm cache; these are exactly what eliminate the double-read. (b) `05_` doubled in size (21→42KB) from the batch-1/2 constraint work, so every agent now reads more than the original baseline agents did.
- **Verdict:** two-phase + model routing is **quality-safe** but only **cost-positive if the two phases share context** (same warm session / injected Fact Pack) and features run **back-to-back cache-warm**. Naive "two cold subagents per feature" is a cost REGRESSION. Needs a **warm-cache full-module run with Levers 2+4 active** to measure the real $/feature before rollout.

### Execution status (2026-Jul-14)
All 4 levers ENCODED (config-only, confined to `Testing-Plan/00_`, `Testing-Plan/03_`, loader `AGENT.md`; `05_` deliberately not bloated). Static no-regression verification PASSED. The only remaining work is the two **billable** dry-run validations (GATE 1 quality diff + GATE 2 empirical no-regression), which the user chose to run together in one approved session AFTER encoding. Nothing in `prime_ai`/`prime_testing`/`TestCases/` was written. Rollback = restore the 4 files from the GATE-0 backup folder.
