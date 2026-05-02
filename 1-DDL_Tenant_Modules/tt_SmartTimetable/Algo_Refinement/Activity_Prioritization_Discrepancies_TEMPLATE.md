# Activity Prioritization — Discrepancies & Proposed Refinements

> **Author:** {{your name}}
> **Date:** {{YYYY-MM-DD}}
> **Status:** Draft for Enterprise Architect review
> **Source of truth for current behavior:**
> - `1-DDL_Tenant_Modules/tt_SmartTimetable/tt_brain/SmartTimetable_Deep_Understanding_v1.md`
>   - §8.5 — Soft scoring formula (slot scoring)
>   - §9 — Activity difficulty scoring (ordering)
>   - Appendix B — Tunable parameters cheat-sheet
>   - Appendix C — Constraint matrix (per-class weights)
> - `1-DDL_Tenant_Modules/tt_SmartTimetable/Algo_Refinement/Algo_parameter_detail.md`
> - `1-DDL_Tenant_Modules/tt_SmartTimetable/Algo_Refinement/Algo_implement_plan.md`
> - Code:
>   - `Modules/SmartTimetable/app/Services/Generator/PrimeSolver.php`
>   - `Modules/SmartTimetable/app/Services/ActivityScoreService.php`
>   - `Modules/TimetableFoundation/app/Services/PriorityConfigService.php`

---

## How to use this template

1. Fill **§0 Context** in 2–4 sentences — *why* you're raising these discrepancies, and what the desired outcome is. Skip if obvious.
2. Tick the surfaces you're critiquing in **§1**. Anything not ticked is out of scope.
3. Add one row per discrepancy in **§2**. Use the column rules below — keep observation separate from prescription.
4. Use **§3** only for issues that span multiple parameters (e.g., "all weights are unnormalized").
5. Be explicit in **§4** about what you're *not* critiquing — prevents scope creep during refinement.
6. Park unanswered questions in **§5** so they don't block the rest.
7. Define falsifiable success criteria in **§6**. "Better" is not a criterion; "force-place count drops by ≥50% on dataset X" is.

> **Tip:** 8–12 high-confidence rows beat 40 mediocre ones. Don't try to be exhaustive on day 1.

---

## 0. Context

{{One paragraph. Why now? What outcome do you want after refinement? Examples:
- "Heavy-load classes are losing their best teachers to easier classes"
- "Class-teacher-first-period bonus is dominating the ordering and starving scarce-teacher activities"
- "Force-placement bucketing is masking real capacity issues"}}



---

## 1. Scoring surfaces under review

Tick the formulas this document critiques. Anything unticked is **out of scope**.

- [ ] **Activity difficulty / ordering score** — `PrimeSolver::orderActivitiesByDifficulty()` (§9)
- [ ] **Per-slot soft scoring** — `PrimeSolver::scoreSlotForActivity()` (§8.5)
- [ ] **Teacher pick (LPT)** — `PrimeSolver::pickRandomTeacherAssignment()`
- [ ] **Activity priority precompute** — `ActivityScoreService::calculateDifficultyScore()`
- [ ] **Requirement priority precompute** — `PriorityConfigService::recalculate()` (7 indices)
- [ ] **Room allocation priority** — `RoomAllocationPass::roomPriorityScore()`
- [ ] **Constraint default weights** — `tt_constraint_type.default_weight` and per-class `getWeight()`
- [ ] **Force-placement bucket priority** — `bucketForcedPlacements()` A/B/C/D
- [ ] **Other:** {{describe}}

---

## 2. Discrepancy register

> **Column rules:**
> - **Current behavior** = a quoted fact from the doc/code (cite §/line). Don't paraphrase.
> - **Why this is wrong** = the *principle* being violated (scarcity ≠ volume, hard ≠ soft, signal ≠ noise, etc.).
> - **Proposed change** = concrete numbers / rules. "Make it less" is unactionable; "−30 → −1,000" is.
> - **Expected effect** = a falsifiable prediction.
> - **Confidence** = High / Medium / Low. Drives whether it gets implemented or workshopped.
> - **Evidence** = doc section + file:line where the current behavior lives.

| ID | Surface | Parameter / Rule | Current behavior | Why this is wrong | Proposed change | Expected effect | Confidence | Evidence |
|----|---------|------------------|------------------|-------------------|-----------------|-----------------|-----------|----------|
| D-01 | {{e.g. Activity ordering}} | {{e.g. `weeklyPeriods × 500`}} | {{Quote the formula/value as it is today}} | {{Principle being violated, in one sentence}} | {{Concrete: replace X with Y, or move to a hard pre-pass, or split into two surfaces}} | {{Falsifiable prediction: "scarce subjects place earlier; rescue-phase entries drop"}} | {{High / Med / Low}} | {{§9 line 972; PrimeSolver.php:XXXX}} |
| D-02 |  |  |  |  |  |  |  |  |
| D-03 |  |  |  |  |  |  |  |  |
| D-04 |  |  |  |  |  |  |  |  |
| D-05 |  |  |  |  |  |  |  |  |
| D-06 |  |  |  |  |  |  |  |  |
| D-07 |  |  |  |  |  |  |  |  |
| D-08 |  |  |  |  |  |  |  |  |

### 2a. Worked example (delete before submitting)

> Showing how a row should read once filled. Use this as a model, not as a real entry.

| ID | Surface | Parameter / Rule | Current behavior | Why this is wrong | Proposed change | Expected effect | Confidence | Evidence |
|----|---------|------------------|------------------|-------------------|-----------------|-----------------|-----------|----------|
| EX-01 | Activity ordering | `weeklyPeriods × 500` | A 5-period subject scores +2,500; a 1-period subject scores +500. The multiplier dominates over `difficulty_score_calculated` (range 0–100). | High weekly-period count is a *volume* signal, not a *scarcity / difficulty* signal. A scarce-teacher 1-period subject is harder to place than a common 5-period one — but today it ranks lower. | Demote `weeklyPeriods` to ×100 (tiebreaker only). Promote `teacher_scarcity_index × 800` from `tt_priority_config` as the primary ordering signal. | Scarce-teacher activities place earlier. Phase 3 rescue/force entries drop ≥30% on the medium-school dataset. | High | §9 lines 970–972; PrimeSolver.php (search `weekly_periods * 500`); `tt_priority_config.teacher_scarcity_index` exists but unused in ordering. |
| EX-02 | Activity ordering | `is_compulsory ? +20 : 0` | Compulsory adds a flat +20 to the ordering score. | +20 is noise next to the ×500 / ×1000 / ×20000 multipliers — it has effectively zero ranking power. Either compulsory must be a hard precondition or a much larger bonus. | Move compulsory to a separate **pre-pass** before the main ordering loop: place all compulsory activities first, then run the ordering function on the rest. | Compulsory is guaranteed; ordering function gets simpler and less noisy. | Medium | §9 line 975. Open question: does any compulsory activity *need* to defer to a non-compulsory one? If yes, this change breaks. |

---

## 3. Cross-cutting concerns

> Use this section for issues that affect the *whole* scoring system, not a single parameter. Each entry should be its own bullet — no table here.

- {{Example: "Weights are integer-additive with no normalization. A score of 27,500 vs 27,485 is essentially noise but treated as ranked. Recommend post-normalization or banding."}}
- {{Example: "Soft scoring multiplier ×0.5 (per §8.5) is hidden — operators can't see it in any UI or config. Recommend exposing in `tt_config` or strategy params."}}
- {{Example: "Three configuration surfaces (config.php, tt_config, generation request options, strategy params_json — see §11) silently disagree. Refining weights in one without retiring the others amplifies the problem."}}

---

## 4. Out of scope (explicit non-goals)

> List what you are **not** critiquing. Prevents the refinement plan from "fixing" things you didn't flag.

- {{Example: "Phase ordering (backtrack → greedy → rescue → force) is correct as designed."}}
- {{Example: "RoomAllocationPass priorities (§16) are not in scope for this round."}}
- {{Example: "Substitution scoring (§10.2) is not in scope."}}
- {{Example: "Constraint cache key shape is correct."}}

---

## 5. Open questions

> Things you need the Enterprise Architect to decide or research before you finalize.

- **Q1.** {{e.g. "Should `class_teacher_first_lecture` move from a +1,000 soft bonus to a hard pre-pin?"}}
- **Q2.** {{e.g. "Is `teacher_scarcity_index` already populated in `tt_priority_config` for live tenants? If yes, plug it in. If no, what's the backfill plan?"}}
- **Q3.** {{e.g. "Do we want to expose the new weight set per-strategy via `tt_generation_strategy.parameters_json`, or keep it global?"}}

---

## 6. Acceptance criteria

> Falsifiable conditions that tell us the refinement worked. At least one must be measurable on a real dataset.

- {{Example: "On the medium-school benchmark (280 activities), scarce-teacher subjects' avg placement attempt count drops from 12 → ≤4."}}
- {{Example: "Phase 3 force-place cell count drops by ≥50% on the medium-school benchmark."}}
- {{Example: "Total generation time stays within ±15% of baseline (no regression)."}}
- {{Example: "Class-teacher-first-period coverage stays at 100% on the small-school benchmark."}}
- {{Example: "Operator-facing diagnostics still surface every force-placed cell with the same A/B/C/D bucketing — no information loss."}}

---

## 7. Submission checklist (run before handing this to the EA)

- [ ] Every D-row has all 9 columns filled (no blanks, no "TBD" without a Q-entry to back it).
- [ ] Every "Current behavior" cell cites a §/line or a `file:line`.
- [ ] Every "Confidence: Low" row has a corresponding entry in §5 Open Questions.
- [ ] §4 lists at least one out-of-scope item (proves you thought about it).
- [ ] §6 has at least one *measurable* acceptance criterion.
- [ ] Worked example block (§2a) is deleted.

---

## 8. What the Enterprise Architect will deliver back

Once this document is submitted, expect:

1. **Per-row review** — Agree / Counter-propose / Question for each D-row.
2. **ADR** entry in `AI_Brain/state/decisions.md` capturing the new scoring philosophy.
3. **Refined enhancement plan** — sequenced patches to `PrimeSolver::orderActivitiesByDifficulty()`, `scoreSlotForActivity()`, `ActivityScoreService`, and constraint default weights — each scoped to a single PR.
4. **Backtest checklist** — what to re-generate to verify §6 acceptance criteria.

---

*Template v1 — created 2026-05-01 for the SmartTimetable algorithm refinement workstream.*
