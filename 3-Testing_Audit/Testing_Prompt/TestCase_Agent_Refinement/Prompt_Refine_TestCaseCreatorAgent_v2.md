# Refinement Prompt v2 — Make the "TestCase Creator" Agent Generate the SAME Quality in FEWER Tokens (lower $)

**Purpose:** Cut the token/$ cost of generating the 7-artifact test suite **without losing any coverage, any constraint, or the `php -l` gate**. This supersedes the earlier two-phase `TokenReduction_Plan_TestcaseCreator.md`, which a measured dry-run proved was a **cost regression** (see §2). This prompt tells you (the executing agent) how to fold a set of measured, quality-safe cost reductions **permanently** into the agent's single source of truth.

**Run this prompt once** (a maintenance/refinement task, not a per-module task). After it completes, re-running the `testcase-creator` agent on any module must produce test suites of the **same quality** as today at a **measurably lower token cost**.

> **Prime directive (non-negotiable): QUALITY IS THE FLOOR.** Every coverage gate, every A–G constraint in `05_`, the single-comprehensive-`.php`-per-screen contract, and the `php -l` gate stay exactly as strong as they are now. A token cut that drops one test-case category, one constraint, or one artifact is a FAILURE, not a saving. You are removing *waste* (redundant reads, duplicated prose, a counter-productive two-phase split), never *coverage*.

---

## 0. Read these first (do not skip)

1. **The cost evidence (input — read for the measured facts, don't re-derive):**
   - `…/Testing_Prompt/TokenReduction_Plan_TestcaseCreator.md` — the original plan AND its **"GATE 1 + GATE 2 DRY-RUN RESULTS"** section: the two-phase split measured **382k tokens for one feature (Phase-1 219k + Phase-2 163k) vs a ~100k–210k single-phase baseline** — i.e. it made cost *worse* by paying discovery twice. Quality held on Sonnet; cost did not. **Do not resurrect the two-phase design.**
   - This file's §2 below distils where the tokens actually go.

2. **The quality baseline you must PRESERVE (already-applied refinements — do not weaken):**
   - `…/TestCase_Agent_Refinement/Refinement_Prompt_TestCase_Creator_Agent.md` (v1) and `…/TestCaseAgent_Refinement_Prompt_2.md` — batch-1/2 added constraints **F33–F48** to `05_` and HARD RULES 14/15 + quality-gate items to `03_`. Every one of those stays.

3. **The agent's single source of truth (the files you will EDIT):**
   - `…/Testing-Plan/03_Testcase_Creator_Agent_Prompt.md` — role, HARD RULES, workflow, PHP skeleton, quality gate.
   - `…/Testing-Plan/05_Known_Test_Failure_Constraints.md` — the numbered constraint list (**now ~42 KB, rules 1–48; read on EVERY run — the single biggest always-paid input**).
   - `…/Testing-Plan/00_Testing_Artifacts_Index_and_Conventions.md` — conventions, artifact contract, token-discipline §3.1.
   - `~/.claude/agents/testcase-creator/AGENT.md` — the loader.
   - (base = `/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/3-Testing_Audit/Testing-Plan/`)

4. **Reference paths (for measuring, not re-reading in full):** committed suites `…/TestCases/{Module}/` and `/Users/bkwork/Herd/prime_testing/tests/Browser/Modules/{MODULE}`; app source `/Users/bkwork/Herd/prime_ai/Modules/{Module}`; DDL `…/2-DDL_Tenant_Consolidated`.

---

## 1. Governing principles (obey these while refining)

1. **Measure, don't guess.** Before and after each change, measure the concrete thing you are cutting — byte size of the always-read prompt surface, output size of a `.php`/doc, tokens of a dry-run. Record real numbers. The two-phase plan failed precisely because it was reasoned, not measured; do not repeat that.
2. **Single-pass, single-agent, single-model — context read ONCE.** The dominant waste is **re-reading the same large context**. Everything in this prompt drives toward reading each large input at most once per feature (ideally once per *module*). **Do NOT split a feature across two agents/phases** — that doubles the read (proven). Keep the strong model for the whole feature; the win comes from reading/writing *less*, not from model-swapping.
3. **Quality is the floor (restated because it's the whole point).** Do not touch a coverage gate, an A–G constraint, the one-`.php`-per-screen contract, or `php -l`. If a proposed cut risks any of these, don't make it.
4. **Reconcile with existing token-discipline material, don't duplicate.** `00_` §3.1 (caching + doc de-dup) and the Fact Pack (Step 0.5) and controller-clustering (module-mode 3b) already exist from the earlier plan — **keep the genuinely token-saving parts (Fact Pack, caching, de-dup, clustering), strip only the two-phase/model-routing parts** that the dry-run discredited. Grep before adding; extend in place.
5. **Every change must be actionable, checkable, and reversible.** Snapshot first (GATE 0 style). Phrase each new rule as an imperative the agent self-checks. Keep an evidence/measurement note.

---

## 2. Where the tokens actually go (measured — this is what you are cutting)

From the dry-run and file sizes (verify current numbers yourself with `wc -c`):

| Cost driver | Evidence | Lever |
|---|---|---|
| **Re-reading the large always-read config every run** — `05_` alone is **~42 KB** (doubled from batch-1/2 additions), plus `03_` (~42 KB) + `00_`. All read cold by every feature agent. | file sizes; Phase-1 dry-run read them in full | **L1 Compress the always-read surface** |
| **Re-deriving module-wide discovery per feature** — DDL, controller, routes, permission prefix, tenancy scaffolding re-read for every screen of a module. | plan §0; 24 BHA agents each re-discovered `bha_`→`ba_` | **L2 Fact Pack as discovery cache** |
| **Full-reading large source & the 78 KB golden reference every feature** | golden ref `.php` = 78 KB; read per feature | **L3 Read-budget discipline** |
| **Output bloat** — each `.php` is 60–78 KB and **re-embeds a near-identical private helper library**; the 3 requirement docs each re-enumerate all ~50 methods. Output is the priciest tokens (5× input on Opus). | `bha_Category` `.php` = 78 KB; MANUALTESTING restated every method | **L4 Output reduction** |
| **Two-phase double-read** — two cold agents each paid the full context read. | dry-run: 382k vs ~165k baseline | **RETIRE (do not use)** |
| **Cold cache between features** — big prefixes re-billed at full price when features don't run back-to-back. | plan §0 caching note | **L5 Caching discipline** |

---

## 3. What to change (the levers — same-quality, fewer tokens)

### L1 (biggest structural win) — Compress the always-read prompt surface; move prose to on-demand appendices
`05_` is read **in full on every single feature run** and has grown to ~42 KB of verbose evidence prose. Split its content by *access frequency*:
- **Create a terse operative "Rule Card"** — one greppable line per constraint: `#<id> | <SECTION> | <imperative in ≤ ~20 words>`. This is what the agent reads every run. Target: the whole card ≪ the current 42 KB (aim for a small fraction).
- **Move the long *why*/*Evidence:* narrative into an "Evidence Appendix"** (same file, a clearly separated lower section, OR a sibling `05a_…_Evidence.md`) that the agent reads **only when a rule is contested / it needs the justification**. No constraint is deleted — it's relocated by how often it must be read.
- **Do the same for `03_`:** keep the operative HARD RULES, workflow steps, skeleton, and quality gate terse; relocate long worked examples/rationale to an appendix section read on demand.
- **Preserve every rule's identity** — the Rule Card keeps the exact numbers (F33–F48, G43–G48, etc.) so `03_`/loader cross-references and the quality gate still resolve. Nothing is renumbered or removed; only re-tiered by read-frequency.
- **Measure:** record `wc -c` of the always-read surface before and after. This lever's saving is paid on *every* feature of *every* module, so it compounds hardest.

### L2 — Module Fact Pack as the authoritative discovery cache (keep & elevate; drop nothing from Step 0.5)
Keep the existing `Step 0.5 — Fact Pack` and its per-feature "read it first, don't re-discover" rule. Strengthen so a per-feature run reads the **compact Fact Pack** instead of re-reading raw DDL/controller/routes/permission source. Keep it terse (tables + IDs, not prose). This is genuine, model-agnostic token saving across all-but-the-first feature of a module.

### L3 — Read-budget discipline (read only what this feature needs; never re-read the golden reference)
Add an explicit **read budget** to `03_` Step 1:
- **Targeted reads, not full-file reads,** for large sources: use `grep`/offset reads to pull only the feature's controller methods, the feature's columns from the DDL, the feature's Blade selectors — not the whole file when a slice suffices.
- **Do NOT re-read the 78 KB golden reference `.php` every feature.** Its structure/helpers/idioms are already canonicalised in `03_` §"PHP Dusk Idioms" (the skeleton + helper list) and mirrored from the **nearest same-module sibling**; consult the sibling only for the *specific* idiom in question, via a targeted read. Internalise once, don't re-ingest.
- **State a per-run "what to read / what NOT to re-read" list** so the agent doesn't reflexively open large files it already has summarised (module_list after Fact Pack, the golden reference, `05_` evidence appendix).

### L4 — Output reduction (output is the priciest token; cut duplication, not coverage)
- **Keep the `00_` §3.1 doc de-dup** (MANUALTESTING references the TcList method table). Extend the principle: the three requirement docs must not each re-enumerate the full method matrix — TcList is the canonical method list; GAPANALYSIS maps to it; MANUALTESTING references it and gives full step tables only where a manual tester needs them. Every method still appears once and is still mapped (no coverage loss).
- **Shared test base/trait to stop re-embedding the helper library in every `.php` (RECOMMENDED — make the cost case, then get sign-off).** Each `.php` re-embeds a large, near-identical private helper library (screenshots, UI drivers, auth/tenancy, uniqueness, assertions). Because output tokens dominate cost and this block is ~identical across files, factoring the stable helpers into ONE shared base class / trait (that each `{prefix}_{Feature}_TestCas.php` extends/uses) removes the biggest repeated output chunk **without changing any test logic or coverage**. This modifies the artifact's internal shape, so: encode the recommendation + a migration note (new files use the shared base; existing committed files are not force-migrated), verify it composes with the module base-class/preloader constraints (`05_` #21/#22), and **flag it in the summary as a design decision for the user to approve** — but, unlike v1, present it as the single highest-leverage OUTPUT saving with the measured rationale, not a neutral aside.
- **Trim boilerplate prose** in the docs (repeated legends/headers) to a referenced convention where safe.

### L5 — Caching discipline (keep prefixes warm; run back-to-back)
Keep and strengthen the `00_` §3.1 caching rule: the always-read surface (`00_`/`03_`/`05_` Rule Card / sibling reference) stays **byte-stable during a batch**; features run **back-to-back** so those prefixes are cache-reads (~0.1× input) not full reads; **do not edit those files mid-batch**. Note that L1 (a smaller always-read surface) makes each cache miss cheaper too.

### RETIRE — the two-phase split & per-artifact model routing
- **Remove/neutralise the two-phase generation instructions** added by the earlier plan: the `03_` §"Two-Phase Generation & Model Routing", the `00_` §3 two-pass split, and the loader's two-phase bullet. Replace with a **single-pass** statement: one agent reads the (now-compact) context once and produces all 7 artifacts; `.php` is still written first and flushed for crash-resilience, but **not handed to a second agent**. Keep the crash-recovery *docs-only* capability (useful when a `.php` already exists) but frame it as recovery, not the normal path.
- Rationale to record inline: measured 382k vs ~165k baseline; the model-routing discount (~1.67×) did not overcome the double-read (~1.9–3.8× more tokens).

---

## 4. Prove it: quality-preservation gate + real cost measurement

Cuts are only valid if quality holds AND cost actually drops. Before declaring done:

1. **Static quality check** — confirm all protected strengths still resolve after the compression: every constraint number (F33–F48, G43–G48, 1–32) still present (relocated is fine), coverage gates intact, `php -l` gate intact, one-`.php`-per-screen intact. (grep the Rule Card + appendix.)
2. **Byte-surface measurement** — record `wc -c` of the always-read surface before vs after L1 (this is the guaranteed, cache-independent saving).
3. **Warm-cache, back-to-back dry-run (the honest cost test the earlier gate lacked)** — regenerate **2–3 features of ONE module back-to-back** (build the Fact Pack once, keep files byte-stable, single-pass) into a **scratch** folder, and compare against the committed baseline:
   - **Quality:** same coverage bands, all A–G constraints applied, `php -l` clean, method count within ~10% of baseline. (Matches how the v1 dry-run verified quality.)
   - **Cost:** measured tokens **per feature after the first** (so caching + Fact Pack are active — the real steady state), vs the plan's ~100k–210k baseline. Report the delta. Target: a **meaningful reduction (aim 30–50%)** with zero quality loss. If tokens do NOT drop, the change failed — do not claim a saving.
   - Never write to `TestCases/`, `prime_ai`, or `prime_testing`.

---

## 5. Verification before you finish
1. Re-read your edits; confirm **no constraint was deleted** — only relocated by read-frequency — and no coverage gate/`php -l` weakened.
2. Confirm the two-phase instructions are gone and replaced by a coherent single-pass workflow (no dangling references to "Phase 2 model").
3. Confirm the Fact Pack, caching, de-dup, and clustering (the genuinely token-saving levers) are retained and consistent.
4. Confirm every cross-reference (`03_`/loader → `05_` rule numbers) still resolves after the Rule Card split.
5. Confirm no rule directs edits to the read-only `prime_testing`/`prime_ai`.

## 6. Deliverable / final summary
Report back, concisely:
- Files edited; the before/after `wc -c` of the always-read surface; the warm-cache dry-run token delta per feature (with the quality check result).
- What was retired (two-phase/model-routing) and what was kept (Fact Pack, caching, de-dup, clustering).
- The shared-helper-base recommendation surfaced as a **design decision for the user**, with its measured output-saving rationale.
- Explicit confirmation that **quality is unchanged** (constraints, coverage gates, `php -l`, artifact contract all intact) and that the measured cost **dropped** (or, honestly, that it did not — do not overclaim).

## Non-goals / guardrails
- Do NOT reduce coverage, drop an artifact, delete a constraint, or weaken `php -l` to save tokens. Relocation ≠ deletion.
- Do NOT reintroduce the two-phase split or per-artifact model routing.
- Do NOT edit `prime_ai`/`prime_testing`/`TestCases/`; touch only `Testing-Plan/` + the loader.
- Do NOT claim a cost reduction you did not measure in a warm-cache, back-to-back run. Verify model IDs/pricing live via the `claude-api` skill before quoting any $ figure.
