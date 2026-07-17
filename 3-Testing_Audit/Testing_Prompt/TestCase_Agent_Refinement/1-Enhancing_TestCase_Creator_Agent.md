# Enhancing Testcase Creator Agent to make less Expensive
=========================================================


Creating Testcases using "TestCase Creator" Agent is consuming too much Tokan, As per your suggesion I was using Claude Opus. Can you provide some plan how Can I create TestCases with same quality but spending less Tokan?

That's the right instinct — this run cost roughly ~170k tokens per feature × 24 ≈ 4M tokens on Opus, and most of that is avoidable. Before I give you concrete numbers on model routing (the biggest lever), let me pull the current model/pricing facts so my cost math is accurate rather than from memory.

⏺ Skill(claude-api)
Successfully loaded skill · 4 tools allowed

Now I have accurate pricing. Here's a concrete plan grounded in what this actual run cost.

Where your tokens actually went

Each testcase-creator agent burned ~100–210k tokens (I saw 98k–230k across the 24). Two things dominate, and both are the expensive kind:

1. Output tokens — the .php is 60–78 KB (~20–25k output tokens) plus 6 markdown docs. On Opus, output is $25/MTok vs $5 input — 5× the price. This is the single biggest cost.
2. Redundant source reading — every agent independently re-reads the same ~32k-token Testing-Plan prompt, the 05_ constraints file, the sibling reference .php, the DDL, and the controller. 24 agents × the same reads.

Rough total: ~4M tokens, mostly on Opus for one module.

Current model pricing (just verified)

┌───────────┬─────────────────────────────┬────────────────────┐
│   Model   │        Input $/MTok         │   Output $/MTok    │
├───────────┼─────────────────────────────┼────────────────────┤
│ Opus 4.8  │ $5.00                       │ $25.00             │
├───────────┼─────────────────────────────┼────────────────────┤
│ Sonnet 5  │ $3.00 ($2 intro→2026-08-31) │ $15.00 ($10 intro) │
├───────────┼─────────────────────────────┼────────────────────┤
│ Haiku 4.5 │ $1.00                       │ $5.00              │
└───────────┴─────────────────────────────┴────────────────────┘

Prompt caching: cache reads ≈ 0.1× input price, writes 1.25× (5-min) / 2× (1-hr). Up to ~90% off the cached portion.

---
The plan — 4 levers, biggest first

1. Model routing: docs on Sonnet, .php on Opus (biggest win)

The 6 companion docs are mechanical — they're derived 1:1 from the finished .php (we proved this: the docs-only recovery agents produced identical-quality output). That's ideal cheap-model work. The .php is the reasoning-heavy artifact where Opus earns its price.

- Split every feature into two phases: Phase 1 (Opus or Sonnet 5) writes the .php; Phase 2 (Sonnet 5, or even Haiku 4.5) writes the 6 docs from it.
- Docs are ~60% of the output. Moving them from Opus→Sonnet-intro output is $25→$10/MTok — roughly 60% cheaper on the doc half.
- Sonnet 5 is near-Opus on coding/agentic work — worth A/B-testing it on the .php itself for CRUD/report features (keep Opus only for the FSM-heavy ones like AssessmentPeriod/ReviewQueue). If it 
- Sonnet 5 is near-Opus on coding/agentic work — worth A/B-testing it on the .php itself for CRUD/report features (keep Opus only for the FSM-heavy ones like AssessmentPeriod/ReviewQueue). If it holds up, that's another ~2.5× on the expensive half.

Est. savings: 40–55% of total spend, no quality loss on docs.

2. Compute a module "Fact Pack" once, feed it to every feature

Right now each agent re-derives module facts (schema/tables, ba_ vs bha_ prefix, controller→screen map, route list, permission prefixes, known audit defects). Do that discovery once per module and pass the resulting fact sheet into each feature prompt.

- The bha_/ba_ prefix confusion alone was re-discovered by all 24 agents.
- Eliminates ~30% of each agent's input reads across 23 of 24 features.

Est. savings: 15–25% of input tokens.

3. Batch features by shared controller

BaReportController serves ~10 of the 24 screens; BaAssessmentController serves 4. Each agent re-reads the full controller. Generating a controller's screens in one agent reads it once, not 10×.

Est. savings: meaningful on Group C especially; also fewer agent spin-ups.

4. Prompt caching + trim doc duplication

- Keep the Testing-Plan prompt, 05_ constraints, and reference .php byte-stable and run features back-to-back so those large prefixes stay cache-warm (reads at ~0.1× instead of full price). Don't interleave unrelated edits to those files mid-batch.
- The TcList, MANUALTESTING, and GAPANALYSIS docs each re-enumerate all ~50 methods. Have MANUALTESTING reference the TcList rather than restate every method — cuts output on the most duplicative artifact.

---
What I'd change in your agent config

All of this is config-only (the 03_ prompt, 00_ conventions, loader) — same low-risk pattern as your earlier enhancement project:
- Add a two-phase mode (.php first, docs-only second) with a model tag per phase.
- Add a Fact Pack step that runs once per module and is injected into each feature prompt.
- Add a controller-batch discovery rule.

Want me to draft these into the Testing-Plan config (no live regen — just the agent changes), starting with the model-routing split since it's the highest ROI? I can also do a quick cost-per-feature comparison on the next module so you can see the delta before committing.

✻ Brewed for 1m 50s

※ recap: BehaviouralAssessment test generation is fully done: all 24 features complete and verified, plus roll-ups. You then asked how to cut token costs; I gave a plan and offered to implement the top lever. Next: your call on drafting the model-routing split into the agent config. (disable recaps in /config)

-------------------------------------------------------------------------------------------------------------------------------------------
## Prompt:
Write this entire Plan as a executable Prompt in folder "/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/3-Testing_Audit/Testing_Prompt"

## Responce:
I'll write the plan as an executable prompt that a future session (or agent) can run to implement the token-reduction changes into your TestCase Creator config.

⏺ Write(~/WorkFolder/1-Old_PrimeDB/old_db/3-Testing_Audit/Testing_Prompt/TokenReduction_Plan_TestcaseCreator.md)
Wrote 168 lines to ../../Testing_Prompt/TokenReduction_Plan_TestcaseCreator.md
# EXECUTABLE PROMPT — Reduce Token Cost of the "TestCase Creator" Agent (keep quality)

**Purpose:** Cut the token/$ cost of generating the 7-artifact test suite per feature, without
losing coverage or fidelity. This is a config-only change to the TestCase Creator agent — no live
test regeneration is part of this task.

**How to run this:** Paste this file's contents (or say "execute
`Testing_Prompt/TokenReduction_Plan_TestcaseCreator.md`") into a fresh session. Work top-to-bottom.
Phases are gated — stop at each GATE for the user's approval before proceeding.
… +158 lines

Written:

Testing_Prompt/TokenReduction_Plan_TestcaseCreator.md

It's structured as a drop-in executable prompt — paste it (or say "execute Testing_Prompt/TokenReduction_Plan_TestcaseCreator.md") into a fresh session and it runs top-to-bottom. Contents:

- §0 Context — the measured cost breakdown (~4M tokens/module, output-dominated), current model pricing, and the config surfaces to edit (00_, 03_, 05_, loader).
- GATE 0 — snapshot/backup before any edit.
- Lever 1 (P1) — two-phase generation: .php on Opus (Sonnet 5 for CRUD/light), the 6 docs on Sonnet 5/Haiku; write .php first + flush. → GATE 1 dry-run diff before rollout.
- Lever 2 (P1) — compute a module Fact Pack once, inject into every feature.
- Lever 3 (P2) — batch features by shared controller (reads the controller once).
- Lever 4 (P2) — prompt-caching discipline + de-duplicate the MANUALTESTING doc. → GATE 2 no-regression check.
- Ordering, non-goals/guardrails, and a resume checklist.

Every step is config-only (never touches committed TestCases), gated for your approval, and keeps the quality guardrails explicit (no dropped artifacts, no weakened php -l gate, cheap model never touches the .php). Combined target: ~2–3× lower $/module, with the docs half already proven lossless by this run's crash-recovery passes.

Want me to go ahead and execute it now (starting at GATE 0), or leave it for a separate session?

-------------------------------------------------------------------------------------------------------------------------------------------
## Prompt:
One of My Team member found some issue in the TestCases Created by "TestCase Creator" Agent. Read the file "old_db/3-Testing_Audit/Testing_Prompt/TestCase_Agent_Refinement/test_quality_report.md" and understand all those issue in detail. You can read other related files if required. Then create a Prompt to perform those refinments into "TestCase Creator" Agent", so that in future when I will create TestCases using "TestCase Creator" Agent then those issues should be eliminated from those. Save the Prompt in Folder "old_db/3-Testing_Audit/Testing_Prompt/TestCase_Agent_Refinement"
## Responce:
I've read the full report. Now let me understand the current "TestCase Creator" agent structure so the refinement prompt fits its actual format. Let me find the source-of-truth prompt.

  Read 1 file, listed 1 directory, ran 1 shell command

The single source of truth is the Testing-Plan agent prompt. Let me examine the agent loader and that prompt's structure so my refinement targets the right file and format.

  Listed 1 directory

There's a 05_Known_Test_Failure_Constraints.md — the loader mandates reading it before writing any PHP, and there's already a feedback loop that appends to it. This is the natural home for these fixes. Let me read it and the agent prompt to understand format and what's already covered.

  Read 1 file

I now have the full picture. Key finding: the agent's single source of truth is the Testing-Plan folder, and 05_Known_Test_Failure_Constraints.md (a numbered, evidence-tagged, "MUST read before writing PHP" file with an existing feedback-loop mechanism) is exactly where these fixes belong. Importantly, several of the 20 mistakes already have partial constraints (e.g. #8 media→constraint 11, #9 tenant-init→constraint 2, #14 user fields→constraint 8, #20 mixed styles→constraint A1), and a few of the report's suggested "fixes" mildly conflict with what's already codebase-verified. So the refinement prompt must reconcile and merge, not blindly append — and must separate test-authoring rules from harness/environment prerequisites.

Let me write the refinement prompt.

⏺ Write(~/WorkFolder/1-Old_PrimeDB/old_db/3-Testing_Audit/Testing_Prompt/TestCase_Agent_Refinement/Refinement_Prompt_TestCase_Creator_Agent.md)
Wrote 122 lines to ../../WorkFolder/1-Old_PrimeDB/old_db/3-Testing_Audit/Testing_Prompt/TestCase_Agent_Refinement/Refinement_Prompt_TestCase_Creator_Agent.md
# Refinement Prompt — Harden the "TestCase Creator" Agent Against 20 Known Test-Quality Defects

**Purpose:** A team member reviewed test files produced by the `testcase-creator` agent and logged 20 recurring quality defects. This prompt tells you (the executing agentwith what's already codebase-verified. So the refinement prompt must reconcile and merge, not blindly append — and must separate test-authoring rules from harness/environment prerequisites.

Let me write the refinement prompt.

⏺ Write(~/WorkFolder/1-Old_PrimeDB/old_db/3-Testing_Audit/Testing_Prompt/TestCase_Agent_Refinement/Refinement_Prompt_TestCase_Creator_Agent.md)
Wrote 122 lines to ../../WorkFolder/1-Old_PrimeDB/old_db/3-Testing_Audit/Testing_Prompt/TestCase_Agent_Refinement/Refinement_Prompt_TestCase_Creator_Agent.md
# Refinement Prompt — Harden the "TestCase Creator" Agent Against 20 Known Test-Quality Defects

**Purpose:** A team member reviewed test files produced by the `testcase-creator` agent and logged 20 recurring quality defects. This prompt tells you (the executing agent
) how to fold those findings **permanently** into the agent's single source of truth, so every future test-case generation run avoids them automatically.

nger reproduce these defects.

---

## 0. Read these first (do not skip)
… +158 lines

Done. I've written the refinement prompt.

What I did

I read the full defect report (all 20 mistakes), then traced how the testcase-creator agent is actually wired so the prompt targets the right place:

- The agent is a thin loader (~/.claude/agents/testcase-creator/AGENT.md) that defers to a single source of truth in …/Testing-Plan/.
- The key file is 05_Known_Test_Failure_Constraints.md — a numbered (rules 1–32), evidence-tagged, "MUST read before writing any PHP" constraint list with an existing feedback-loop mechanism for appending new rules. That is exactly where most of these 20 fixes belong, alongside the HARD RULES and self-check gate in 03_Testcase_Creator_Agent_Prompt.md.

The prompt I saved

…/TestCase_Agent_Refinement/Refinement_Prompt_TestCase_Creator_Agent.md

It's a run-once maintenance prompt that folds the 20 defects permanently into the agent's source of truth. Its important design decisions:

1. Reconcile, don't blindly append. I found that ~7 of the 20 mistakes are already partially covered by existing constraints (media→#11, tenant-init→#2, user fields→#8/9, mixed styles→A1, 403/selectors→existing HARD RULES). The prompt maps each of the 20 to "extend existing rule N" vs "add new rule 33+", so the agent strengthens rather than duplicates or contradicts.
2. Flags where the report's own "fix" is wrong. The report suggests tenancy()->initializeByDomain() (conflicts with codebase-verified constraint 2) and hasCast('is_active') as a substitute for an active-check (semantically wrong). The prompt tells the executor to trust the verified codebase and correct the real bug, not the report's imprecise remedy.
3. Separates authoring rules from harness/infra. Mistakes #17/#18/#19 (ChromeDriver timeouts, stale route cache, 422→500 from bootstrap/app.php) can't be fixed in a generated test file — and the loader forbids editing prime_testing. The prompt routes these to "document as environment prerequisite + assert a tolerant status set," not a brittle assertion.
4. Protects the established artifact contract. Mistake #10 (extract a shared TenantTestSetup trait) conflicts with the current one-self-contained-file-per-screen design, so the prompt has the executor flag it as a design decision for you rather than unilaterally rewriting the contract.
5. Adds a greppable self-check quality gate (no addToAssertionCount-only bodies, no isCasted(/->isActive(, ->refresh() present, etc.) so the agent catches regressions before returning.

The included per-defect mapping table (§2) is the core — it tells the executing agent exactly which file and which existing rule number each of the 20 mistakes lands in.

One note: the folder already had two empty placeholder files (Enhancement_from_Shailesh.md here, and 2-Enhancing_TestCase_Creator_Agent.md one level up). I left those untouched and created a clearly-named new file. If you'd prefer this content go into one of those existing placeholders instead, say the word.

Want me to go ahead and execute this refinement prompt now (apply the edits to 03_/05_), or would you rather review the prompt first?

### Brij:
go ahead and execute this refinement prompt now
### Responce:
All edits applied. Let me do the final verification pass the prompt requires — check numbering integrity, confirm no contradictions, and spot-check that the new rules would have caught the real defects.

  Ran 1 shell command

Numbering runs cleanly 1–42, sections A–F, no duplicates (rule 7 exists — it just starts with a ⚠️ so the grep pattern skipped it). All edits are coherent. The refinement is complete.

Done — the 20 defects are now hard-coded into the agent's source of truth

I verified every claim against the real code first, then encoded the fixes with evidence notes matching the file's existing discipline.

Files edited (agent's single source of truth):

05_Known_Test_Failure_Constraints.md — the file the agent MUST read before writing any PHP:
- 3 existing constraints strengthened in place (reconciled, not duplicated): rule 1 (added "one test style per file" + tenant-before-actingAs, Mistake #20), rule 8 (added short_name NOT-NULL + the 1364 strict-mode rule, Mistake #14), rule 11 (added "media table may be absent → guard + document", Mistake #8).
- 10 new evidence-tagged rules (F33–F42) in a new "F. Assertion completeness & test hygiene" section: hollow tests/empty stubs (#1/#15), isCasted/isActive (#2/#13), missing refresh() (#3), exact seed counts (#5), 403-not-asserted + forgetCachedPermissions (#4), no cleanup (#7), browser AJAX CSRF (#11), never-hand-write URLs/selectors (#6/#16), infra prerequisites bundle (#17/#18/#19), and shared-helper correctness (#10/#12).
- Updated the "Usage in generated artifacts" footer to point at A–F and the new env prerequisites.

03_Testcase_Creator_Agent_Prompt.md — the role prompt:
- Added HARD RULE 14 summarizing F33–F42.
- Added 11 greppable quality-gate checks (e.g. "grep the file: 0 addToAssertionCount", "0 isCasted(/->isActive(") so the agent self-catches before returning.

Verification I ran (evidence now cited in the rules): confirmed addToAssertionCount across 20+ Hostel files, isCasted(/->isActive( in the named files, /fee-structures vs /hostel/fee-structures at hst_FeeStructures:19 / hst_FeeDemands:21, and sys_users.short_name varchar(30) NOT NULL at _prime_db_v4.sql:123.

Reconciliations (merged into existing rules rather than added as duplicates): #8→11, #9→2, #14→8, #20→A1, #4→31, #6/#16→HARD RULE #1.

Deliberately NOT adopted verbatim (flagged for your decision):
- Mistake #9's tenancy()->initializeByDomain($domain) — conflicts with the codebase-verified constraint 2 (tenancy()->initialize($domain->tenant)). I kept the verified API and only encoded the real bug (init with null/empty tenant).
- Mistake #10's shared TenantTestSetup trait — this changes the one-file-per-screen artifact contract, so rule F42 records the intent (mirror sibling helpers verbatim) and explicitly surfaces the trait extraction as a design decision for you, not something the agent adopts mid-run.
- Mistake #19's exact 422 assertion — the current prime_testing/bootstrap/app.php:72 has no ValidationException→422 render callback, so I made the rule assert a tolerant {422,500} set + document, rather than a brittle exact assert.

No test files or app code were touched, and no rule directs edits to the read-only prime_testing/prime_ai repos (F41 states this in 4 places). Regenerating the affected modules with the hardened agent is the separate next step whenever you're ready.

---------------------------------------------------------------------------------------------------------------------------------------
## Prompt:
Another Team member also created a file with issue he found in the TestCases but the file is not formated properly. First Read his issue he found from the file "/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/3-Testing_Audit/Testing_Prompt/TestCase_Agent_Refinement/Enhancement_from_Shailesh.md" and then create a "Enhance_report.md in same folder in the fomrat similer to "/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/3-Testing_Audit/Testing_Prompt/TestCase_Agent_Refinement/test_quality_report.md"

## Responce:
Done. I read Shailesh's raw notes and reformatted them into Enhance_report.md, matching the structure of test_quality_report.md.

What I did

Shailesh's file had 6 issues written as prose validation-check descriptions. I converted each into the same friendly report format:

- Header + paths block + scope note (mirroring the original)
- Each issue as ## Mistake #N — <title> with: The problem → Real-life example (fresh analogies: cinema seats, visa form, parking meter, fire-exit map, wrong cabinet, restaurant menu) → Where it happens → What the correct test should do → Files affected → Rule for the agent (blockquote)
- A Quick Reference Table and a What Should Change for the Agent numbered list at the end

The 6 issues, grouped

Notice these split cleanly into two themes:

1. DDL-driven coverage gaps (#1–#5) — constraints that exist in the schema but are never actually exercised: UNIQUE (create a duplicate), NULL/NOT NULL, VARCHAR length, full DDL↔app consistency (incl. the soft-delete trait↔deleted_at check), and correct-model usage.
2. Process gap (#6) — the concrete ordinal example: tests written from the UI instead of the code, wrongly proposing an auto-managed controller field as a form input.

Honesty note

Shailesh didn't list specific file names or line numbers for most items (unlike the first report), so rather than invent them I marked the scope explicitly — "all DDL-backed CRUD screens, review scope was Hostel and Inventory" — and only used the one concrete case he actually gave (the ordinal field). I also added one factual caveat in #4 from what we verified earlier: in this codebase the deleted_at column and the SoftDeletes trait can genuinely disagree, so the rule says assert each independently and report the mismatch rather than "fixing" it in the test.

Want me to fold these 6 into the agent's source of truth as well (as constraints F43+ in 05_Known_Test_Failure_Constraints.md, the same way I did the first batch)? A few are already partially covered — #3 length ↔ existing constraint 18, #4 soft-delete ↔ constraints 12/30, #6 read-the-code ↔ HARD RULE #1/#2 — so it'd be a reconcile-and-extend pass like last time.


---------------------------------------------------------------------------------------------------------------------------------------

## Prompt:
Another Team member also found some issue in the TestCases Created by "TestCase Creator" Agent. Read the file "old_db/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/3-Testing_Audit/Testing_Prompt/TestCase_Agent_Refinement/Enhance_report.md" and understand all those issue in detail. You can read other related files if required. Then create a Prompt to perform those refinments into "TestCase Creator" Agent", so that in future when I will create TestCases using "TestCase Creator" Agent then those issues should be eliminated from those. Save the Prompt as "old_db/3-Testing_Audit/Testing_Prompt/TestCase_Agent_Refinement/TestCaseAgent_Refinement_Prompt_2.md"
## Responce:
Done. I read Shailesh's Enhance_report.md (the 6 issues) and created the refinement prompt at:

…/TestCase_Agent_Refinement/TestCaseAgent_Refinement_Prompt_2.md

How this prompt differs from Refinement Prompt #1

I deliberately shaped it around the different character of this batch. Batch 1 was mostly test-hygiene / correctness bugs → those lived in 05_ as guardrails. Batch 2 is mostly coverage the agent fails to generate → so this prompt directs most edits into 03_'s workflow (BC decomposition Step 2, TC enumeration Step 3, test_01 Step 6, the Cross-Reference scan Step 7, and the coverage/quality gates), with supporting facts as new 05_ F-rules.

Key design decisions baked in

Reconciliation, not duplication — I flagged the three real overlaps and told the executor exactly how to handle each so it doesn't contradict what's already there:
- #3 (field length) ↔ constraint 18 — these are complementary opposites: 18 says "don't overflow your own seed data," Shailesh says "deliberately submit an over-length value and assert rejection." The prompt makes the executor encode the new obligation and cross-link 18 so they aren't confused.
- #4 (soft-delete) ↔ constraints 12/30 — this is the important guardrail. Constraint 30 (which we verified in batch 1) establishes that in this codebase the deleted_at column and the SoftDeletes trait can genuinely disagree, and must be asserted independently with the mismatch reported as a defect. The prompt explicitly forbids regressing that into "make column and trait match."
- #6 (read the code) ↔ HARD RULE #1/#2 — reinforced with the specific programmatically-managed field clause and the ordinal example verbatim, rather than restating "read the source."

Respect this codebase's verified quirks — a coverage rule that naively asserts 422 on rejection would false-fail here, because batch 1 confirmed validation errors can surface as 500 (F41) and the consolidated DDL can lag the live schema (28/30). So every "rejected" assertion in the new coverage is required to tolerate the 500-vs-422 set or assert the DB-level outcome (row absent / duplicate refused), and to check schema truth against the live schema where the DDL lags.

DDL-vs-FormRequest divergence becomes a defect — since these rules key off the DDL, a mismatch between DDL (UNIQUE/NOT NULL/VARCHAR(n)) and the FormRequest (unique:/required/max:) is routed into the existing Cross-Reference Defect Scan as a DEV-###, not silently "fixed."

The prompt is verify-first (open a real Hostel/Inventory DDL table + the ordinal controller before writing rules) and, like #1, explicitly does not touch test files or the read-only prime_testing/prime_ai repos.

Want me to go ahead and execute this prompt now (apply the edits to 03_/05_), the same way I did with batch 1?

### Brij:
Yes, go ahead and execute this prompt

### Responce:
All edits applied. Now the verification pass — check numbering integrity and section structure in 05_:

  Ran 1 shell command

Everything is coherent: 05_ now runs 1–48 across sections A–G, and 03_ references G43–G48 in 18 places with the Cross-Reference table correctly expanded to 15 checks. Verification confirms the soft-delete rule preserves "assert independently" and the rejection assertions tolerate the 500-vs-422 quirk — no contradictions with existing constraints.

Refinement Prompt #2 executed — batch-2 findings now hard-coded into the agent

I verified every claim against real code first (hst_room_types gave me a live UNIQUE KEY + NOT NULL + VARCHAR(n) all on one table; ordinal confirmed as a code-managed field), then encoded the fixes with real evidence.

05_Known_Test_Failure_Constraints.md:
- Constraint 18 strengthened in place — clarified it's the complement of the new over-length coverage rule (valid fixtures stay within size; a boundary test deliberately exceeds it), so the two aren't confused.
- New section G (rules 43–48) — the DDL-derived coverage obligations, framed as "the agent must GENERATE these tests," each keyed off the DDL and each tolerating this codebase's verified quirks (500-vs-422, DDL-lags-live-schema, column↔trait divergence): UNIQUE-duplicate (43), NULL/NOT NULL (44), field-length (45), full test_01 alignment matrix with independent soft-delete asserts (46), verified-model CRUD (47), read-the-code / no programmatic field as form input (48).

03_Testcase_Creator_Agent_Prompt.md — since this batch is about coverage, most edits landed in the workflow:
- HARD RULE 15 summarizing G43–G48.
- Step 1 read-order — verify the correct model + flag programmatic fields.
- Step 2 (BC decomposition) — BC-DB must enumerate one testable fact per DDL constraint.
- Step 3 (TC enumeration) — the DDL-derived negative/positive matrix is now mandatory.
- Step 6 / test_01 — expanded to the full DDL↔app alignment matrix with independent soft-delete asserts against the live schema.
- Step 7 Cross-Reference scan — grew from 11 to 15 checks (DDL-vs-FormRequest divergence for unique/required/max/soft-delete → DEV-###).
- 8 new quality-gate checkboxes.

Reconciliations (as predicted, merged not duplicated): #3↔18 (complementary), #4↔12/30 (preserved "assert independently, report mismatch" — did not regress into "force column=trait"), #6↔HARD RULE 1/2; #1/#2/#5 added as new obligations.

Deliberately not encoded verbatim: nothing that would force an exact-422 assertion (every rejection tolerates F41's 500-vs-422) or that would make the soft-delete column and trait match (constraint 30's discipline is upheld). No rule directs edits to the rea_ai repos, and no test/app files were touched — regenerating modules with thehardened agent remains the separate next step.

### Brij:
Verify both refinement prompts are reflected in the agent files

### Responce:


  Ran 1 shell command

Confirmed — that was a grep-pattern artifact; rule 8 correctly carries short_name VARCHAR(30) NOT NULL, the 1364 rule, and academic_session_id. Everything checks out.

Verification complete — both refinement prompts are fully reflected in the agent files

Every change from both batches is present in the two source-of-truth files (03_Testcase_Creator_Agent_Prompt.md and 05_Known_Test_Failure_Constraints.md).

05_Known_Test_Failure_Constraints.md — now 48 rules across sections A–G

┌───────┬──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┬────────────────┐
│ Batch │                                                                           What                                                                           │     Status     │
├───────┼──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┼────────────────┤
│ 1     │ New section F + rules 33–42 (hollow tests, framework methods, refresh, seed counts, permission 403+cache, cleanup, AJAX CSRF, no-hand-written-URLs,      │ ✅ all 10      │
│       │ infra prerequisites, shared helpers)                                                                                                                     │ present        │
├───────┼──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┼────────────────┤
│ 1     │ In-place amendments: rule 1 (one-style-per-file), rule 8 (short_name/1364/academic_session_id), rule 11 (media table absent)                             │ ✅ all 3       │
│       │                                                                                                                                                          │ present        │
├───────┼──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┼────────────────┤
│ 2     │ New section G + rules 43–48 (UNIQUE-duplicate, NULL/NOT NULL, field-length, full test_01 matrix, verified-model CRUD, read-the-code)                     │ ✅ all 6       │
│       │                                                                                                                                                          │ present        │
├───────┼──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┼────────────────┤
│ 2     │ In-place amendment: rule 18 (complement-of-#45 note)                                                                                                     │ ✅ present     │
└───────┴──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┴────────────────┘

03_Testcase_Creator_Agent_Prompt.md


---------------------------------------------------------------------------------------------------------------------------------------

## Prompt:
Read and Execute "/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/3-Testing_Audit/Testing_Prompt/TokenReduction_Plan_TestcaseCreator.md"

### Responce:
All encoding work is complete. Here's the summary.

Token-reduction plan executed — all 4 levers encoded (config-only), billable dry-runs deferred

Per your choice, I did all the free config work now and left the two billable dry-run gates for one approved session at the end.

What was done

GATE 0 — snapshot ✅ Backed up 00_, 03_, 05_, and the loader to Testing-Plan/_backup_2026-Jul-14_tokenreduction/ (one-line rollback). Noted the pre-existing uncommitted TestCases/BehaviouralAssessment/ changes are from earlier work, not this task.

Lever 1 — Two-phase generation + model routing ✅
- 03_: new "Two-Phase Generation & Model Routing" section — Phase 1 writes the .php first and flushes it (crash-resilience) on Opus 4.8 (Sonnet 5 only for Light/CRUD with no BC-SM); Phase 2 derives the 6 docs 1:1 on Sonnet 5 / Haiku 4.5 and must not touch the .php. Feature-classification rule included.
- 00_ §3: annotated the artifact contract with the 2-pass split + revised generation order.
- Loader: two-phase routing bullet (docs-only/crash-recovery runs are cheap-model-eligible).

Lever 2 — Module Fact Pack ✅ 03_ Step 0.5 (build/reuse {Module}_FactPack.md once: verified prefix + doc-vs-live divergence, CREATE TABLE list, controller→screen map, routes, permission prefix, tenancy scaffolding, known defects, per-feature model tag) + "read it first, don't re-discover" rule + module-mode wiring + a Model column in the Feature Inventory.

Lever 3 — Controller-cluster batching ✅ 03_ module-mode step 3b: group features by backing controller; one agent may generate a cluster's Phase-1 .php files (read the controller once); Phase-2 docs still fan out cheap; per-feature output-folder discipline unchanged.

Lever 4 — Caching + doc de-dup ✅ 00_ §3.1 (keep 00_/03_/05_/reference .php byte-stable mid-batch, run back-to-back for cache warmth) + 03_ Step 5 (MANUALTESTING references the TcList table instead of restating every method — full step tables only where a tester needs them; no coverage dropped).

GATE 2 — static no-regression ✅ Verified: 8/8 lever markers present, 11/11 protected strengths intact (screen-based model, module-folder-first non-overwrite, timestamped collision rule, TC-T/TC-S/a11y, BC-SM, Source tags + Coverage-Score, Cross-Reference scan, php -l gate, output discipline, batch-1/2 HARD RULES 14/15). All edits confined to Testing-Plan/ + loader; 05_ deliberately left unbloated; nothing written to prime_ai/prime_testing/TestCases/.

What remains (needs your go-ahead — billable)

The two empirical dry-runs, to be run together:
- GATE 1: spawn testcase-creator to regenerate one done feature (e.g. HrStaff/LeaveType) two-phase into scratch → diff docs 1:1, method counts, php -l, and confirm .php quality holds if Phase 1 ran on Sonnet 5 → report token delta.
- GATE 2 empirical: confirm no coverage regression on that regenerated output.

Only after those can the plan's final "measured $/feature before vs after" line be filled in. Just say the word when you want me to run them.

One caveat worth flagging: the plan projects a 2–3× cost reduction, but that figure is unvalidated until the dry-run measures a real token delta — and the Sonnet-5-for-Phase-1 quality claim is an assumption until we diff a real regenerated .php. I'd treat both as hypotheses to confirm at GATE 1, not settled results.

✻ Baked for 5m 35s

### Brij:
run GATE 1 and GATE 2 dry-runs now

### Responce:
You authorized the billable dry-runs — I'll run them now. First, let me find a good committed baseline feature (a Light/CRUD one, so it exercises the Sonnet-5 Phase-1 routing we most need to validate) and confirm it has the full artifact set.

  Listed 1 directory

Let me inspect a clean CRUD candidate (Category) — its artifact set and the committed .php method count, to serve as the baseline for the diff.

  Ran 1 shell command

Category is the ideal baseline: complete 7-artifact set, already single-file (no V1/V2), 55 test methods, 78KB, php -l clean, and it's a Light/CRUD feature — so it exercises exactly the Sonnet-5 Phase-1 routing that most needs validating.

My dry-run design answers the two questions the gate poses, each into a scratch folder (never TestCases/):
- Test B (GATE 1b — Phase-1 quality): regenerate Category's .php fresh on Sonnet 5 via the real (newly-edited) agent → compare method count / coverage / php -l vs the committed Opus baseline (55 methods).
- Test A (GATE 1a — Phase-2 losslessness): regenerate the 6 docs from the committed .php on Sonnet 5 → diff 1:1 vs committed docs.

Let me set up scratch dirs and launch both (independent, so in parallel).

  Ran 1 shell command

Scratch is ready and baselines captured. Launching both dry-run agents in parallel on Sonnet 5 (the model whose quality we're validating):

⏺ 2 background agents launched (↓ to manage)
GATE1b Phase-1 quality dryrun
GATE1a Phase-2 docs losslessness

Both dry-run agents are now running in the background on Sonnet 5:

- Test B (Phase-1 quality) — regenerating Category's .php fresh via the real two-phase agent config, into scratch.
- Test A (Phase-2 losslessness) — deriving the 6 docs from the committed .php, into scratch.

These are full agent runs (typically several minutes each). They're harness-tracked, so I'll be notified automatically when each finishes — no need to poll. Once both complete I'll run the diffs (method count vs the committed 55, php -l, coverage categories, docs 1:1) and the GATE 2 empirical no-regression check, then report the results with token deltas.

Sitting tight until they complete.

✻ Waiting for 2 background agents to finish

⏺ Agent "GATE1a Phase-2 docs losslessness" finished · 7m 14s

Test A (Phase-2 docs) is complete — all 6 docs regenerated on Sonnet, 55/55 methods traced 1:1. It also surfaced a genuinely useful finding (cheap-model abbreviation risk). Test B (the fresh .php on Sonnet) is still running. Let me run the GATE 1a diff now (comparing the regenerated docs vs committed) while Test B finishes.

  Ran 1 shell command

GATE 1a (Phase-2 docs losslessness) — PASSED. Strong result:

┌──────────────────────────────────────────────────┬────────────────────────────────────────────┐
│                      Check                       │                   Result                   │
├──────────────────────────────────────────────────┼────────────────────────────────────────────┤
│ All 6 docs regenerated                           │ ✅ 6/6                                     │
├──────────────────────────────────────────────────┼────────────────────────────────────────────┤
│ All 55 committed methods present in regen TcList │ ✅ 0 missing                               │
├──────────────────────────────────────────────────┼────────────────────────────────────────────┤
│ All 55 present in regen GapAnalysis              │ ✅ 0 missing                               │
├──────────────────────────────────────────────────┼────────────────────────────────────────────┤
│ Lever-4 de-dup on MANUALTESTING                  │ 268 → 171 lines (−36%), no coverage lost   │
├──────────────────────────────────────────────────┼────────────────────────────────────────────┤
│ TcList / GapAnalysis                             │ 270→278 / 143→177 (slightly more thorough) │
├──────────────────────────────────────────────────┼────────────────────────────────────────────┤
│ Runners / Validation Report                      │ ~unchanged                                 │
└──────────────────────────────────────────────────┴────────────────────────────────────────────┘

So the core lever is validated: the docs do derive 1:1 from the finished .php, and the de-dup rule trims the most duplicative artifact by a third without dropping any of the 55 methods. The agent also flagged a real risk — a cheaper model can silently abbreviate method names and break exact-string traceability unless a grep self-check catches it (it self-caught here). That's worth encoding as a standard Phase-2 check; I'll note it in the final recommendations.

Test B (the fresh .php on Sonnet 5) is still running — it's the heavier reasoning pass. I'll run the quality diff and the GATE 2 empirical check as soon as it lands. Waiting on its completion notification.

Agent "GATE1b Phase-1 quality dryrun" finished · 12m 14s


---------------------------------------------------------------------------------------------------------------------------------------
## Prompt:
I noticed few files are not required which may reduce the Tokan expence further. Here is the detail of those:
 - For Every Feature Agent is creating ManulaTesting File (/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/3-Testing_Audit/TestCases/TestCases_v3/Billing/BillingCycle/prm_BillingCycleMANUALTESTING_Require.md) & TestCaseList File (/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/3-Testing_Audit/TestCases/TestCases_v3/Billing/BillingCycle/prm_BillingCycleTcList_Require.md). I think we can create only 1 file (TestCaseList File) which can serve both the purpose. Any additional important info belongs to ManualTesting can be added into TestCaseList File.
 - Agent is creating 2 Script file e.g. 
    - 3-Testing_Audit/TestCases/TestCases_v3/Billing/BillingCycle/run-BillingCycle-tests.ps1
    - 3-Testing_Audit/TestCases/TestCases_v3/Billing/BillingCycle/run-BillingCycle-tests.sh
    We can create a single consolidated file which can run in both the environment Windows & Linux.
    
Can you re-evaluate the Prompt on above points and if you think doing above enhancements (changes) can further reduce the cost(Tokan spent) then Create a Prompt to Enhance these change into Agent and save the prompt as "3-Testing_Audit/Testing_Prompt/TestCase_Agent_Refinement/Prompt_Refine_TestCaseCreatorAgent_v3.md"

### Responce:
Good ideas — let me evaluate them on the merits before writing anything, because the point is real token savings, not just fewer files.

Idea 1 — merge MANUALTESTING into TcList: worth it. Output tokens are the priciest tokens (5× input on Opus), and MANUALTESTING is a whole artifact (~268 lines committed, still ~171 even after v2's de-dup). Its only unique value over TcList is the human-tester step tables (Step/Action/Expected + DB + activity-log checks) and the Feature-Information header. Folding those sections into TcList and dropping the separate file eliminates the duplicated BC/method restatement, a file's worth of boilerplate, and the agent's reasoning to produce a second document — with zero coverage loss (every TC/BC/step still present). This is actually the logical endpoint of v2's L4 de-dup lever.

Idea 2 — single cross-platform runner: worth it, but smaller and it's a workflow change. The .ps1/.sh pair is the same logic in two dialects (~118 lines total). Eliminating one is a real output cut. One caution: a true .ps1+.sh polyglot is fragile and error-prone (would cost more reasoning tokens and risk breakage). The robust "runs natively on Windows and Linux" answer is a single PHP runner (run-{Feature}-tests.php) — PHP is guaranteed present in a Laravel/Dusk project, so it's genuinely cross-platform with no shell-dialect hacks. That's a team-workflow change (CI/muscle-memory may expect .sh), so it should be flagged for your approval, not imposed.

Both reduce cost; Idea 1 is the bigger win. Honest framing: these are incremental output-side savings (smaller than v2's L1, which compresses the 42 KB always-read surface), but they're low-risk because they don't touch coverage. Worth encoding. Writing v3 now.

⏺ Write(~/WorkFolder/1-Old_PrimeDB/old_db/3-Testing_Audit/Testing_Prompt/TestCase_Agent_Refinement/Prompt_Refine_TestCaseCreatorAgent_v3.md)
Wrote 103 lines to ../../../Testing_Prompt/TestCase_Agent_Refinement/Prompt_Refine_TestCaseCreatorAgent_v3.md
# Refinement Prompt v3 — Consolidate Artifacts (7 → 5) to Cut Out

 artifacts**, not coverage. Two consolidations, both proposed by
1. **Merge the MANUALTESTING doc INTO the TcList doc** — one requ
2. **Replace the two runner scripts (`.ps1` + `.sh`) with ONE cro

2 (compress the always-read surface, Fact Pack, caching, single-p
ly collapses redundant OUTPUT.**
**Run this prompt once** (a maintenance/refinement task). After i
of 7, with identical coverage.
… +135 lines


Done. Saved as Prompt_Refine_TestCaseCreatorAgent_v3.md.

My evaluation (short version)

Both of your ideas are genuine token savings, and they're low-risk because they cut duplication, not coverage:

- Merge MANUALTESTING → TcList — the bigger win. MANUALTESTING mostly re-states the BC tables and method matrix that TcList already holds; its only unique content is the Feature-Info header and the human-tester step tables. Fold those into TcList, drop the file, and you remove a whole emitted document plus the agent's reasoning to produce it — zero coverage lost. It's literally the endpoint of v2's L4 de-dup lever.
- Single runner — smaller but real. I recommend a single PHP runner (run-{Feature}-tests.php) rather than a .ps1/.sh polyglot: PHP is guaranteed present in a Laravel/Dusk project, so it runs natively on Windows and Linux with no fragile shell hacks. The polyglot approach I explicitly rejected — it'd cost more reasoning tokens and risk breakage.

Net effect: 7 artifacts → 5. I was honest in the prompt that these are incremental output-side savings (smaller than v2's L1, which compresses the 42 KB always-read 05_) — but they compound across every feature of every module and don't endanger quality.

What v3 instructs

- Change A: a combined TcList with 6 sections (Feature Info + BC + TC list + Method Index + Manual Test Steps for complex/money/workflow cases only + Known Defects); delete the MANUALTESTING artifact; keep GAPANALYSIS separate (merging the coverage map in would hide gaps — I called that out as a non-goal).
- Change B: one run-{Feature}-tests.php; delete the .ps1/.sh pair; no polyglot.
- Update the 5-artifact contract everywhere it's referenced (03_, 00_, loader description, generation order, quality gate) and reconcile every literal (MANUALTESTING, 7-artifact, .ps1, Steps 6/7, …).
- A quality-preservation + output-delta measurement step, and the prime-directive "merge = relocate, not delete."

Two things I flagged rather than decided for you

1. Runner format is a team-workflow change (CI/muscle-memory may expect .sh), so v3 recommends the PHP runner as the default but marks it approval-pending, with "standardise on a single .sh" as a one-line lighter alternative.
2. v3 explicitly supersedes v2's L4 instruction ("MANUALTESTING references TcList") with the outright merge, so the two prompts don't conflict if both are executed.

I did not execute v3 (you asked to save the prompt). When you're ready to apply it, note the ordering question: v3 and v2 both edit 03_/00_, so if you want both, running v2 first then v3 is cleanest (v3 assumes v2's context) — and each should start with a fresh GATE-0 snapshot.

✻ Churned for 2m 41s

※ recap: Goal: make the TestCase Creator agent cheaper without losing quality. I've saved three refinement prompts (v1 quality, v2 read/output cuts, v3 artifact consolidation 7→5); v2 and v3 aren't executed yet. Next: run v2, then v3, each after a fresh snapshot.

---------------------------------------------------------------------------------------------------------------------------------------
## Prompt:
 I think I have already RAN "3-Testing_Audit/Testing_Prompt/TestCase_Agent_Refinement/Prompt_Refine_TestCaseCreatorAgent_v2.md", if YES then directly Execute "3-Testing_Audit/Testing_Prompt/TestCase_Agent_Refinement/Prompt_Refine_TestCaseCreatorAgent_v3.md" ELSE First Execute "Prompt_Refine_TestCaseCreatorAgent_v2.md" and then Execute "Prompt_Refine_TestCaseCreatorAgent_v3.md"

 ## Responce:
 Let me first determine whether v2 was actually executed, by inspecting the agent's source-of-truth files for v2's signature changes (chiefly: v2 retires the two-phase section that's currently present, and compresses 05_ into a Rule Card).

  Ran 1 shell command

Determination is conclusive: v2 has NOT been run. The two-phase section is still present in 03_, 00_, and the loader (v2 retires it); there's no "Rule Card" in 05_ (still 42 KB uncompressed); and no read-budget discipline in 03_. The only backups are from the earlier TokenReduction run, not a v2 run.

So per your instruction, I'll execute v2 first, then v3. Both mandate a snapshot first (reversibility). Let me snapshot and pull the current full state of the files I'll restructure.

  Ran 1 shell command

Snapshot secured. Now let me read the current full 05_ (the 42 KB file v2 wants compressed into a Rule Card + Evidence Appendix) so I restructure it without losing any constraint.

  Read 1 file

I have the full current 05_ (48 rules). Now executing v2. The centerpiece (L1) is splitting 05_ into a compact always-read Rule Card plus an on-demand Evidence Appendix. To preserve every constraint's evidence with zero transcription risk, I'll copy the current file verbatim into the new appendix, then overwrite 05_ with the condensed Rule Card.

  Ran 1 shell command

Now relabel the appendix header (it's the on-demand evidence source, not the always-read file):

⏺ Update(~/WorkFolder/1-Old_PrimeDB/old_db/3-Testing_Audit/Testing-Plan/05a_Constraints_Evidence_Appendix.md)

Now overwrite 05_ with the compact Rule Card (the always-read surface), which references the appendix for detail:

⏺ Write(~/WorkFolder/1-Old_PrimeDB/old_db/3-Testing_Audit/Testing-Plan/05_Known_Test_Failure_Constraints.md)

05_ compressed. Let me verify the reduction and that all 48 rules survived:

  Ran 1 shell command

70% reduction on the always-read surface (42 KB → 12.4 KB). The grep counted 46 because rules 7 and 19 start with ⚠️; let me confirm all 48 numbers are present with no gap:

  Ran 1 shell command

All 48 rules preserved, no gaps, 70% smaller always-read surface. Now the rest of v2. First, retire the two-phase section from 03_ and replace with a single-pass statement, and update the 05_/05a read references + add read-budget discipline. Let me handle the big two-phase block:

⏺ Update(~/WorkFolder/1-Old_PrimeDB/old_db/3-Testing_Audit/Testing-Plan/03_Testcase_Creator_Agent_Prompt.md)

Now clean up the residual two-phase references elsewhere in 03_. The Fact Pack's model-routing tag:

⏺ Update(~/WorkFolder/1-Old_PrimeDB/old_db/3-Testing_Audit/Testing-Plan/03_Testcase_Creator_Agent_Prompt.md)


v2 is complete. Now v3 — artifact consolidation (7 → 5). Let me pull the exact current text of the artifact contract, Steps 4/5/8, the quality gate, and the 00_ contract table so I edit precisely.

  Ran 1 shell command

I have all anchors. Executing v3. First let me read Step 4 (TcList) so I merge Step 5's content into it correctly:

  Read 1 file

Now merge Steps 4 & 5 into one combined-artifact step:

⏺ Update(~/WorkFolder/1-Old_PrimeDB/old_db/3-Testing_Audit/Testing-Plan/03_Testcase_Creator_Agent_Prompt.md)


Now a comprehensive verification sweep across all files for both v2 and v3 — checking for stale references and consistency:

  Ran 1 shell command

All clean — no stale references, two-phase fully retired, artifact step-numbers map correctly to the new 5-artifact contract with no collisions. Let me measure the net always-read surface reduction (the guaranteed, cache-independent saving) against the pre-edit backup, and do a final 05_/05a consistency check:

  Ran 1 shell command

Always-read surface down 23% (112 KB → 85.6 KB), driven by 05_ shrinking 70% (42 KB → 12.4 KB); the 42 KB evidence appendix is now on-demand only. All 48 rules preserved in both the Rule Card and the appendix. Let me run the final quality-preservation check (v2 §4 / v3 §5) — confirming no coverage gate, constraint, or php -l was weakened:

  Ran 1 shell command

Two flags — likely pattern-match artifacts. Let me confirm they're not real deletions:

  Ran 1 shell command

Both false alarms — just case-sensitivity in my grep. Everything is intact (lines 19/82/83/179 confirm "one .php per screen"; lines 399–401 confirm the G43–G48 gate checks).

Let me do one last check — whether the non-loaded planning docs (01_/02_/04_) still say "7 artifacts" (they don't affect the agent since the loader doesn't read them, but worth flagging):

  Ran 1 shell command

Both v2 and v3 are fully executed and verified. Here's the complete report.

v2 executed (cost reduction via read/output discipline)

┌────────────────────────────────┬─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│             Change             │                                                                         Result                                                                          │
├────────────────────────────────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ L1 — Compress the always-read  │ Split 05_ (42 KB, read every run) into a 12.4 KB Rule Card (05_, always read) + a 42 KB Evidence Appendix (05a, on-demand only). All 48 rules preserved │
│ surface                        │  in both, sections A–G intact, no gaps.                                                                                                                 │
├────────────────────────────────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ Retire two-phase               │ Removed the two-phase/model-routing section from 03_, 00_, and the loader; replaced with a single-pass, one-model, context-read-once statement citing   │
│                                │ the measured 382k-vs-165k regression.                                                                                                                   │
├────────────────────────────────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ L3 — Read-budget discipline    │ Added to 03_ Step 1 + loader: read the Rule Card not the appendix; reuse the Fact Pack; never re-read the 78 KB golden reference per feature; targeted  │
│                                │ grep/offset reads of large source.                                                                                                                      │
├────────────────────────────────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ L2/L5 — kept                   │ Fact Pack, caching/back-to-back, controller-clustering retained (stripped only their two-phase wording).                                                │
├────────────────────────────────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ L4 — output                    │ Doc de-dup kept; shared-helper-base flagged as the top output saving (approval-pending).                                                                │
└────────────────────────────────┴─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘

Net always-read surface: 112 KB → 85.6 KB (−23%), paid on every feature of every module. The appendix (42 KB) is no longer in that path.

v3 executed (artifact consolidation 7 → 5)

- Merged MANUALTESTING → TcList: the combined TcList now has 6 sections (Feature Info + BC + TC list + Method Index + Manual Test Steps for complex/money/workflow only + Known Defects). GAPANALYSIS kept separate (surfaces gaps). Content preserved, duplication removed.
- Single cross-platform runner: run-{Feature}-tests.php replaces the .ps1+.sh pair; polyglot explicitly banned.
- Updated the 5-artifact contract everywhere: 03_ (description, modes, HARD RULE 5, Artifact Contract table, Steps 4–9 with corrected artifact numbers, quality gate), 00_ (folder diagram, §3 table + header, §3.1, generation order, golden-ref note), loader description. Zero stale 7-artifact/MANUALTESTING/.ps1/.sh references remain in any loaded file.

Quality preservation — verified

All protected strengths intact: php -l gate, coverage gates (Neg 100/Pos 90/Dep 90), one-.php-per-screen, BC-SM, Cross-Reference Defect Scan (15 checks), HARD RULES 14/15, F33–F48 + G43–G48 gate lines, output discipline. Nothing was deleted — content was relocated (constraints → appendix; manual steps → combined TcList).

Two things to flag

1. Design decisions still pending your approval (encoded as recommended defaults, not imposed): the shared-helper-base (v2's biggest output lever) and the PHP-runner format (vs a single .sh). Both are marked approval-pending in the files.
2. Non-loaded planning docs (01_/02_/04_) still say "7 artifacts" (12 stale refs total). They don't affect the agent — the loader only reads 03_/00_/05_+05a/golden reference — so I left them to keep this change focused. Want me to sync them for documentation consistency?

Snapshot for rollback: Testing-Plan/_backup_2026-Jul-14_23-37_v2v3/.

One honest caveat: the −23% always-read reduction is measured and guaranteed; the total per-feature cost drop (with output consolidation + caching) still needs a warm-cache, back-to-back multi-feature run to quantify — exactly the measurement v2 §4 calls for. I have not run that (it's billable); say the word and I'll run it the same way I ran the GATE dry-runs.

✻ Cooked for 12m 43s

※ recap: Goal: cut the TestCase Creator agent's token cost while keeping quality. I've executed refinement prompts v2 and v3, shrinking the always-read surface 23% and consolidating artifacts 7 to 5. Next: run a warm-cache multi-feature dry-run to measure the total cost drop.


---------------------------------------------------------------------------------------------------------------------------------------
## Prompt:
My Tester has checked the testCases Created by the Enhanced "TestCase Creator" Agent. The comparision Report File is "/old_db/3-Testing_Audit/Testing_Prompt/TestCase_Agent_Refinement/fof_Circular_AGENTS_Review.md". In Process of Refining the "TestCase Creator" Agent I have executed multipal Prompt, detail as below:
- 3-Testing_Audit/Testing_Prompt/TestCase_Agent_Refinement/Prompt_Refine_TestCaseCreatorAgent_v1.md
- 3-Testing_Audit/Testing_Prompt/TestCase_Agent_Refinement/Prompt_Refine_TestCaseCreatorAgent_v2.md
- 3-Testing_Audit/Testing_Prompt/TestCase_Agent_Refinement/Prompt_Refine_TestCaseCreatorAgent_v3.md
- 3-Testing_Audit/Testing_Prompt/TestCase_Agent_Refinement/TokenReduction_Plan_TestcaseCreator.md

My Tester has refined Test Cases for 1 Screen, which can be used as a Sample Required output, which located at "prime_testing/tests/Browser/Modules/Class&SubjectMgmt/ClassGroup". Read all the Files from this Folder when you need to understand what type of output I am looking for. But before that first I want to understand What all Rules "TestCase Creator" Agent are Following while creating TestCases. Provide me all detail including but not limited to below points:
- Common Rules - what is being tested for every Screen For Example -
    - Compare DDL with Migration to find gaps or discripencies
    - Model - Call is for correct Model or not
    - Conditions whether checked the View before Submit to Save for the Fields which are NOT NULL in DDL Schema
    - etc.
- Common Business Rule
- What Process Agent is following to understand how to create TestCases before start writing output files

My purpose is to read & verify the entire proces before execution, so add every detail to make it easy to understand the entire process. Ad only detail which exists in "TestCase Creator" Agent and being use by it. DO NOT ADD ANYTHING FROM PROMPTS, I PROVIDED FOR REFERENCE ONLY. Save the final Report as "old_db/3-Testing_Audit/Testing_Prompt/TestCase_Agent_Refinement/Enhancement_v2/TC_Creation_Process.md"

## Responce:
Done. Saved to .../Enhancement_v2/TC_Creation_Process.md.

What it documents

A faithful, source-cited description of what the current TestCase Creator agent actually does — drawn only from its five live files (loader, 03_, 00_, 05_ Rule Card, 05a_ appendix). Every rule carries a citation like [03_ HARD RULE 15], [Rule Card #46], [00_ §6] so you can verify each at source. I explicitly kept the refinement prompts (v1/v2/v3/TokenReduction) out — their effects are already baked into the five files, and the header states this.

Structure

1. What the agent is — role, 3 modes, unit-of-work
2. The process BEFORE writing — the full ordered flow: bootstrap → Fact Pack (Step 0.5) → the fixed 9-item read order (screen file → DDL → FormRequest → Controller → Service → Model → Routes → Blade → FRD → Audit) → BC decomposition → TC enumeration
3. Common Rules tested for every screen — the test_01 full DDL↔app alignment matrix, correct-model verification, DDL-derived UNIQUE/NOT-NULL/length coverage, permissions/403, activity-log, dependency A–G, hygiene rules
4. Common Business Rules — BC-BIZ, BC-SM state machines, the 15-check Cross-Reference Defect Scan, defect discipline
5. Taxonomies — BC (10 types), TC (P/N/D/T/S/A), traceability chain, semantic bands
6. The 48 Rule-Card guardrails (A–G)
7. The 5-artifact output contract
8. Coverage gates + the ~30-item self-check
9. Review notes (report screens lighter, single-pass, doesn't execute unless execute=true, etc.)

Your three examples — where each lives in the report

- "Compare DDL with Migration for gaps" → §3.1 (test_01 alignment matrix, asserted against the live schema where migration/DDL lag) + §4.3 Cross-Reference checks 11–15.
- "Model — correct model or not" → §3.2 (constraint G47; verified in the read phase, enforced in generated CRUD).
- "NOT-NULL fields checked in the View before Submit" → §3.3 + the callout: the agent derives "required" from the DDL, not the form, reads the Blade for real field names, generates a missing-value rejection test per NOT-NULL-no-default column, and cross-checks DDL NOT NULL vs FormRequest required (check 13).

One honest caveat I built into the doc: I described the agent's intended behaviour as written in its files — it's the specification, and the FrontOffice run showed the agents follow it closely, but the ClassGroup sample you pointed me at is exactly the right way to check whether the specified process produces the output shape you want. I did not read ClassGroup for this doc (you said that's for the next step). When you're ready, I can diff the sample against this documented process and the fof_Circular_AGENTS_Review.md findings to pinpoint any gap between what the agent is specified to do and the output you actually want.


---------------------------------------------------------------------------------------------------------------------------------------
## Prompt:
I want to create a Rule Book for "TestCase Creator" Agent, where every Rule for creating TestCases will be covered. It will be having below Categories:
1. Category : DDL (first source of truth)
    - Every table having "deleted_at" to implement Soft Delete. It should be implemented in Code as well.
    - Transactions & Log Table may not have deleted_at, as they are not required soft delete implementation.
    - Check - Every Foriegn Key Field should have similer Field Type (Bigint, Int, TinyInt etc) in Parent Table also.
    - etc.
2. 
- Requirement File Screen wise : Separate Files for every Screen
- FRD : 

> 2. Model → Controller → FormRequests → Routes → Policy → Permission Seeder → Views → Services → Requirements → Conditions

