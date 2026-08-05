
/clear

❯ Read "/Users/bkwork/WorkFolder/3-Local_Workspace/9-TestingStrategy/TestCase_Generation_Activities_and_Token_Cost_v1.md" and search if any other report needs to be generated which is not covered in 3 Prompts you have created :
  - "ScreenClassificationRegister.md"
  - "CategoryGoldKit.md"
  - "CanonAuthoring_Maintenance.md"

  If you find any other report then Create Prompt for That in same folder "/Users/bkwork/WorkFolder/3-Local_Workspace/9-TestingStrategy/Prompts"
⧉ Selected 6 lines from ../../WorkFolder/1-Old_PrimeDB/old_db/7-CLAUDE_Prompts/Z-Temp_Prompts/Prompt_2026-07-27.md in Visual Studio Code

I'll read the token cost document and the three existing prompts to find gaps.

  Read 1 file, listed 1 directory

Now let me examine what the existing prompts actually cover.

  Ran 2 shell commands

Now let me check which activities already have canon prompts (00_–08_) so I only flag genuine gaps.

  Searched for 2 patterns, listed 1 directory, ran 2 shell commands

Let me read the existing prompts in full to match their house style exactly.

  Read 2 files, listed 2 directories, ran 2 shell commands

I have the full picture. The three prompts cover only GROUP 0 (A0.1–A0.3). Six activity groups downstream have no prompt. Let me write them.

⏺ Write(Prompts/ModuleFactPack.md)
Wrote 454 lines to Prompts/ModuleFactPack.md
# PROMPT — A1.1 + A1.2 · Module Fact Pack Build

> **Activity:** `A1.1` (Module identity resolution) + `A1.2` (Module Fact Pack build) in
> `TestCase_Generation_Activities_and_Token_Cost_v1.md` (GROUP 1 — per-module, paid once, reused across the module's screens)
> **Companions:** `Prime_AI_TestCase_Generation_Master_Plan_2026Jul29.md` §Phase 3 · `Final_TestCase_Categories_v1.md`
> **Model policy:** cheap model for extraction; strong model only for the tenancy-scope decision and the known-defect list
> **Token target:** ≤ **35k tokens per module** to build. It repays itself after ~4 screens and saves ≈**2M tokens** programme-wide (§7 optimisation #7 plus the A1.1 registry re-read, ≈2
.8M).

---
… +460 lines

Now the legacy estate triage + tier assignment prompt (Master Plan §4.3 flags this as "missing entirely").

⏺ Write(Prompts/LegacyEstateTriage.md)
Wrote 389 lines to Prompts/LegacyEstateTriage.md
# PROMPT — A0.4 · Legacy Estate Triage & Test-Tier Assignment

> **Activity:** Master Plan Phase 0.3 (`TcList_Inventory_Register`) + §8.0–8.3 (tiering and the existing Dusk estate).
> Listed in `Prime_AI_TestCase_Generation_Master_Plan_2026Jul29.md` **§4.3 as "missing entirely"** — two of the four
> gaps it names ("no tier decision", "no handling of the 555 already-authored TcLists") are this prompt's job.
> **Companions:** `TestCase_Generation_Activities_and_Token_Cost_v1.md` (GROUP 5/6 context) · `Final_TestCase_Categories_v1.md`
> **Frequency:** once per module, then incrementally when a screen's archetype or tier changes
> **Model policy:** cheap model for inventory and mechanical mapping; strong model only for `RED/FLAKY` regenerate-vs-repair calls
> **Token target:** ≤ **6k tokens per existing artefact**; ≤ **200k per module**. Full-reading 555 TcLists (25.2M chars ≈ 6.3M tokens) is the failure mode this prompt exists to prevent.
… +392 lines

⏺ Write(Prompts/ReviewBatchPacket.md)
Wrote 404 lines to Prompts/ReviewBatchPacket.md
# PROMPT — A3.1 · Review Batch Packet & Red-Line Capture

> **Activity:** `GROUP 3 — Human review gate` in `TestCase_Generation_Activities_and_Token_Cost_v1.md`, plus
> §7 optimisation **#8 (batch review by category)** and Master Plan **Phase 4 — Review at scale**.
> **Token cost of the gate itself: zero. Throughput cost: everything.** 555 TcLists have produced only 175 test files —
> the review gate, not token spend, is the programme's actual bottleneck.
> **Companions:** `02-Category_Kits/A{n}_Definition.md` (FORBIDDEN/MANDATORY lists) · `A{n}_Review_Rubric.md`
> **Frequency:** once per review batch (one archetype × one module, 5–10 TcLists)
> **Model policy:** cheap model — this is assembly and arithmetic, not reasoning about test design
> **Token target:** ≤ **3k tokens per TcList** in the packet. Never full-read a TcList (11.4k tokens each).
… +396 lines

Now the biggest gap — the execute-and-repair loop (the #1 cost driver, and per the Master Plan "the discipline that is missing today").

⏺ Write(Prompts/ExecuteAndRepair.md)
Wrote 425 lines to Prompts/ExecuteAndRepair.md
# PROMPT — A5.1–A5.3 · Execute, Triage & Repair (capped loop)

> **Activity:** `A5.1` static validation · `A5.2` execute the suite · `A5.3` failure triage and repair loop —
> in `TestCase_Generation_Activities_and_Token_Cost_v1.md` (GROUP 5). Master Plan **Phase 6**.
> **This is the #1 cost driver in the entire programme** — the only activity with no natural upper bound
> (≈30–80k tokens per iteration, unbounded iterations; a single hard screen can consume 300k+). It is also the only
> activity that converts prediction into proof: *"a test that has never been executed is not coverage — it is inventory."*
> **Frequency:** once per screen after Stage B; re-run on any repair
> **Model policy:** strong model for triage classification (getting (a)/(b)/(c) wrong is what corrupts a suite); cheap model for re-running and log capture
> **Token target:** **≤ 3 repair iterations, hard cap. ≤ 150k tokens per screen.** At the cap you stop and escalate — you do not try a fourth time.
… +430 lines

Now the cross-reference defect scan (A5.4, the 15 checks) and the roll-ups (A6.1).

⏺ Write(Prompts/CrossReferenceDefectScan.md)
Wrote 366 lines to Prompts/CrossReferenceDefectScan.md
# PROMPT — A5.4 · Cross-Reference Defect Scan (15 checks)

> **Activity:** `A5.4` in `TestCase_Generation_Activities_and_Token_Cost_v1.md` (GROUP 5).
> **This is the activity that turns testing into defect discovery.** Checks 12–15 in particular find real bugs that
> no amount of test execution would ever surface — a `VARCHAR(50)` column validated with `max:255` is a live
> data-truncation defect, and it passes every test you could write against either layer alone.
> **Companions:** `04-Module_Fact_Packs/{Module}_Fact_Pack.md` (the input that makes this cheap) · Rule Card `05_`
> **Frequency:** **once per module** for the 9 module-wide checks; per screen only for the 6 screen-scoped ones
> **Model policy:** strong model — this is comparative reasoning across layers, and a false positive here wastes a developer's day
> **Token target:** ≤ **20k tokens per module** for the module-wide checks (from a Fact Pack), ≤ **6k per screen** for the screen-scoped ones. Without a Fact Pack this doubles.
… +368 lines

⏺ Write(Prompts/ProgrammeRollups.md)
Wrote 399 lines to Prompts/ProgrammeRollups.md
# PROMPT — A6.1 · Programme Roll-ups (RTM, Coverage, Defects, Metrics, Summary)

> **Activity:** `A6.1` in `TestCase_Generation_Activities_and_Token_Cost_v1.md` (GROUP 6 — roll-ups) plus
> Master Plan **§9.1 Definition of Done** and **§9.2 weekly metrics**.
> **The trap this prompt exists to avoid:** re-reading 30 TcLists to build one dashboard costs ~340k tokens and
> produces a number you could have computed from index files for ~10k. **Roll up from registers, never from artefacts.**
> **Frequency:** weekly per module; monthly programme-wide; on demand before a release gate
> **Model policy:** cheap model — this is aggregation and arithmetic. A strong model here is pure waste.
> **Token target:** ≤ **25k tokens per module roll-up** · ≤ **80k programme-wide**. If you are above that, you are reading artefacts instead of registers.
… +390 lines

⏺ Write(Prompts/DuskSelectorRetrofit.md)
Wrote 303 lines to Prompts/DuskSelectorRetrofit.md
# PROMPT — OPT-10 · `dusk=""` Selector Retrofit Proposal

> **Activity:** §7 optimisation **#10** in `TestCase_Generation_Activities_and_Token_Cost_v1.md` —
> *"`dusk=\"\"` selector retrofit on Dusk-tier screens · saves ~1M tokens + far fewer repair cycles · ~40–60 screens only,
> not all 3,749 blades."* Related to activity **A2.9** (blade read — a major variable cost, up to ≈87k tokens for one view).
> **Frequency:** once per Dusk-tier screen, before Stage B on that screen
> **Model policy:** cheap model — this is grep, arithmetic and patch authoring
> **Token target:** ≤ **4k tokens per screen**. Never full-read a blade; the largest in the estate is 350,018 chars (≈87k tokens).

---
… +297 lines

Now the coverage map that documents the audit itself — which activity has which prompt.

⏺ Write(Prompts/_PROMPT_COVERAGE_MAP.md)
Wrote 103 lines to Prompts/_PROMPT_COVERAGE_MAP.md
# Prompt Coverage Map — every activity in the token-cost analysis, and the prompt that owns it

> **Audited:** 2026-07-30 against `TestCase_Generation_Activities_and_Token_Cost_v1.md`,
> `Prime_AI_TestCase_Generation_Master_Plan_2026Jul29.md` and `Final_TestCase_Categories_v1.md`.
> **Purpose:** prove no activity that produces a report is unowned. Update this file whenever a prompt is added.

---

## 1. Coverage by activity
… +101 lines

  Listed 1 directory, ran 1 shell command

Audit done. The three existing prompts cover only GROUP 0 of the token-cost document (A0.1–A0.3). Six of the seven activity groups downstream had no prompt — including the two most expensive activities in the programme. I created 7 new prompts plus a coverage map.

What was missing

┌───────────────────────────────────────┬────────────────────────────────────────────────────────────────────────────────────────────────────────────────┬─────────────────────────────────────────┐
│          Uncovered activity           │                                                Why it mattered                                                 │               New prompt                │
├───────────────────────────────────────┼────────────────────────────────────────────────────────────────────────────────────────────────────────────────┼─────────────────────────────────────────┤
│ A1.1 + A1.2 Module Fact Pack          │ Doc calls it "second-highest-return optimisation after the canon digests" (~2M + 2.8M tokens). Mentioned in    │ ModuleFactPack.md →                     │
│                                       │ canon 03_ but never had a build procedure or output contract                                                   │ 04-Module_Fact_Packs/                   │
├───────────────────────────────────────┼────────────────────────────────────────────────────────────────────────────────────────────────────────────────┼─────────────────────────────────────────┤
│ Phase 0.3 + §8.0–8.3 estate triage &  │ Master Plan §4.3 lists this as "missing entirely" — 556 TcLists, 756 Dusk files, no tier decision              │ LegacyEstateTriage.md →                 │
│ tier assignment                       │                                                                                                                │ 05-Legacy_Estate_Triage/                │
├───────────────────────────────────────┼────────────────────────────────────────────────────────────────────────────────────────────────────────────────┼─────────────────────────────────────────┤
│ GROUP 3 human review gate             │ "Token cost zero. Throughput cost: everything" — the actual bottleneck, and the only place % TCs deleted at    │ ReviewBatchPacket.md →                  │
│                                       │ review can be counted                                                                                          │ 06-Review_Batches/                      │
├───────────────────────────────────────┼────────────────────────────────────────────────────────────────────────────────────────────────────────────────┼─────────────────────────────────────────┤
│ A5.1–A5.3 execute & repair            │ The #1 cost driver, unbounded, and "the discipline that is missing today"                                      │ ExecuteAndRepair.md →                   │
│                                       │                                                                                                                │ 07-Execute_Repair/                      │
├───────────────────────────────────────┼────────────────────────────────────────────────────────────────────────────────────────────────────────────────┼─────────────────────────────────────────┤
│ A5.4 cross-reference scan (15 checks) │ "The activity that turns testing into defect discovery" — checks 12–15 find bugs execution never surfaces      │ CrossReferenceDefectScan.md →           │
│                                       │                                                                                                                │ 08-Defect_Scan/                         │
├───────────────────────────────────────┼────────────────────────────────────────────────────────────────────────────────────────────────────────────────┼─────────────────────────────────────────┤
│ A6.1 RTM, dashboards, defect          │ The two decision-driving metrics live nowhere else                                                             │ ProgrammeRollups.md → 09-Rollups/       │
│ register, §9.2 metrics                │                                                                                                                │                                         │
├───────────────────────────────────────┼────────────────────────────────────────────────────────────────────────────────────────────────────────────────┼─────────────────────────────────────────┤
│ §7 opt #10 dusk="" retrofit           │ ~1M tokens + far fewer repair cycles; classification already detects the need but nothing acted on it          │ DuskSelectorRetrofit.md →               │
│                                       │                                                                                                                │ 10-Selector_Retrofit/                   │
└───────────────────────────────────────┴────────────────────────────────────────────────────────────────────────────────────────────────────────────────┴─────────────────────────────────────────┘

Design decisions worth flagging

- All follow your house contract: §0.1 sandbox (writes only under 9-TestingStrategy, source repos read-only), shell-first, evidence-with-file:line, promotion-is-human, §9 report block with Writes outside the sandbox: NONE.
- One deliberate sandbox exception: ExecuteAndRepair.md defaults to REPAIR-PROPOSE (patch proposals only); REPAIR-DIRECT must be granted per-invocation naming one test file. Application code is never writable in either mode — bucket (b) app defects stay DEV-### proposals. Hard 3-iteration cap, and explicit bans on weakening assertions / markTestSkipped / lengthening waits to reach green.
- Real commands verified against prime_testing/TEST_SETUP.md (php artisan test / php artisan dusk, the three-DB config, the APP_ENV/test-runner-DB safety check before any run).
- _PROMPT_COVERAGE_MAP.md records the audit itself — every activity ID → owning prompt, the §4.3 gaps now closed, and §3 lists what deliberately has no prompt here (Stage A/B live as canon 08_/07_; CI wiring and §10 production-readiness are dev programmes).

Two things I did not do: Stage A/B changes needed to make the Fact Pack saving real are written as A0.3 patch-proposal instructions inside ModuleFactPack.md §10, not applied. And RunAll_Parallel_Orchestrator.md still covers wave 0 only — I'd hold off on a wave-1 orchestrator until each new prompt has had one real run and its token figures are measured rather than estimated.

I also noticed you archived the three executed prompts into Prompts/Executed/ at 13:20; the new ones sit at the top level as un-run.

✻ Cogitated for 18m 22s

❯ have you write the same direction in these new Prompts also?
  1- Save all the file in the Sub-Folder, created in Folder "/Users/bkwork/WorkFolder/3-Local_Workspace/9-TestingStrategy"
  2- DO NOT make any changes other then folder "/Users/bkwork/WorkFolder/3-Local_Workspace/9-TestingStrategy"

Let me verify all seven mechanically rather than from memory.

  Ran 3 shell commands
Interrupted · What should Claude do instead?

❯ I have moved all 7 New prompt into Folder "/Users/bkwork/WorkFolder/3-Local_Workspace/9-TestingStrategy/Prompts/New"

  Ran 1 shell command

All seven carry both directives. Two things need fixing — let me look at the exact text.

  Read 1 file

Confirmed: ExecuteAndRepair.md carved out an exception to rule #2. Removing it now — propose-only, no writes outside the sandbox.

⏺ Update(Prompts/New/ExecuteAndRepair.md)
Added 6 lines, removed 2 lines
OUTPUT_DIR     = {WORKSPACE_ROOT}/07-Execute_Repair
```

> **Every file you create MUST live under `{WORKSPACE_ROOT}`** — with **one narrowly-scoped exception**, defined in
> §0.2, because a repair that cannot touch the test file is not a repair.
> **Every file you create or modify MUST live under `{WORKSPACE_ROOT}`. No exceptions.**
> You have **no write permission anywhere else on this machine** — not in `prime_ai`, not in `prime_testing`,
> not in `old_db`, not in `pgdatabase`, not in `/tmp`, not in the git repo, not in `CLAUDE.md`.
>
> **This includes the test file you are repairing.** Every repair is authored as a **patch proposal** under
> `{OUTPUT_DIR}` and applied by a human. See §0.2.

```
9-TestingStrategy/

⏺ Update(Prompts/New/ExecuteAndRepair.md)
Added 2 lines, removed 1 line
└── 07-Execute_Repair/                    ← ALL execution/repair output lives here
    ├── {Module}/{Screen}_Run_{DATE}.md         ← the run record: command, raw output, verdicts (§5.1)
    ├── {Module}/{Screen}_Repair_Log.md         ← one block per iteration, real failure text in (§5.2)
    ├── {Module}/{Screen}_Patch_Proposals/      ← proposed test edits when direct repair is not authorised (§0.2)
    ├── {Module}/{Screen}_Patch_Proposals/      ← every proposed test-file edit, as a patch (§0.2)
    ├── {Module}/raw_{DATE}_it{n}.txt           ← captured run output (tee'd here, never to /tmp)
    ├── _Failure_Signatures.md                  ← cross-screen root-cause index — the batching win (§6)
    ├── _DEV_Register_Candidates.md             ← bucket (b) app defects (§4.3)
    ├── _RuleCard_Candidates.md                 ← bucket (c) environment truths → A0.3 (§4.4)

⏺ Update(Prompts/New/ExecuteAndRepair.md)
Added 36 lines, removed 13 lines

| | |
|---|---|
| ✅ **Allowed writes** | Anything under `{OUTPUT_DIR}`; **plus** the single test file under repair, **only** in `REPAIR-DIRECT` mode (§0.2) |
| ❌ **Forbidden writes** | Application code in `prime_ai` — **always, in every mode, without exception**. Migrations, seeders, DDL, `.env`, `phpunit*.xml`, canon, `module_list.md`, `C
LAUDE.md`, any test file other than the one under repair |
| 📖 **Read-only inputs** | `prime_ai` (always) · `prime_testing` except the file under repair · `old_db` · `pgdatabase` |
| ✅ **Allowed writes** | Anything under `{OUTPUT_DIR}` — and nothing else, in any mode |
| ❌ **Forbidden writes** | Every other path on the machine — **the test file under repair included**, plus application code in `prime_ai`, migrations, seeders, DDL, `.env`, `phpunit*.
xml`, canon, `module_list.md`, `CLAUDE.md`, `/tmp` |
| 📖 **Read-only inputs** | `prime_ai` · `prime_testing` (**including the file under repair**) · `old_db` · `pgdatabase` — read and grep freely, never write |
| 🚫 **No side effects** | No `git add/commit/push`, no `git checkout`/`stash`/`reset`, no `php artisan migrate`/`db:seed`/`migrate:fresh`, no dropping or truncating a database, no `co
mposer` install/update, no Chrome/driver install |

### 0.2 The two modes — and why the exception is narrow
### 0.2 Repair means a patch proposal — you never edit the test file

| Mode | Authority | Writes to the test file? |
|---|---|---|
| **`REPAIR-PROPOSE`** (default) | none needed | **No.** Every fix is written as a unified-diff patch proposal in `{Screen}_Patch_Proposals/` with the failure evidence that justifies i
t. A human applies it. |
| **`REPAIR-DIRECT`** | must be granted **explicitly in the invocation**, naming the exact file path | **Yes — that one file only.** Every edit is a targeted `Edit`; a full `Write` of
the test file is forbidden. |
Executing a test is a **read** operation, so it stays inside the sandbox rule. Repairing one is a **write**, so it
does not. Therefore:

In `REPAIR-DIRECT` you must, before the first edit, record in the repair log: the file path, its `wc -c` and
`php -l` result, and the failing method names. Every subsequent edit block names the method it touched and the
failure line that justified it. An edit with no cited failure text is a guess (§0 rule 1) and is forbidden.
| | |
|---|---|
| **What you do** | Author a patch proposal per fix in `{OUTPUT_DIR}/{Module}/{Screen}_Patch_Proposals/`, with the verbatim failure text that justifies it, the verbatim anchor line fro
m the test file, and the replacement |
| **What a human does** | Applies it, then re-invokes you to re-execute |
| **Never** | `Edit` or `Write` any file under `prime_testing/tests/` — not even the one file you are working on, not even a one-character selector change |

> **Application code is never writable in either mode.** Bucket (b) is a `DEV-###` proposal, full stop. The test
> agent fixing the app is how a test suite silently stops being an independent check.
**Patch proposal format** — one block per fix, anchors verbatim from disk:

```markdown
## Patch 1 of 4 — signature `SEL-MISSING:#category-form`
File: `prime_testing/tests/Browser/Modules/StudentProfile/V2/StudentCategoryTest.php`
Methods affected: `…pos_03`, `…pos_04`, `…neg_07`, `…neg_08`   (4 occurrences)
### Failure that justifies it (verbatim)
NoSuchElementException: no such element: …{"css selector":"#category-form"}  at …Test.php:142
### Evidence from source
`create.blade.php:18` → `<form id="categoryModalForm" …>`
### Anchor (line 142, verbatim — do not reformat)
    $browser->waitFor('#category-form')
### Replace with
    $browser->waitFor('#categoryModalForm')
### Classification
(a) test defect — invented selector. Additive/corrective only; no assertion removed or weakened.
```

> **Consequence for the loop:** an iteration ends when its patches are written, not when they are applied. A run
> therefore reports `PATCHES-PENDING` rather than a repaired health state, and the 3-iteration cap counts *executions*
> (§7). This is slower than editing directly and it is the correct trade: the sandbox rule is what makes it safe to
> point this prompt at any screen without reviewing what it might touch.
>
> **Application code is never writable either.** Bucket (b) is a `DEV-###` proposal, full stop. A test agent fixing
> the app is how a test suite silently stops being an independent check.

### 0.3 Destructive-operation rule

Dusk runs against a real test tenant. Before the first run of a session, confirm and record:

Now the remaining references to the removed mode.

  Searched for 1 pattern, read 1 file

⏺ Update(Prompts/New/ExecuteAndRepair.md)
Added 1 line, removed 1 line

```markdown
# {Screen} — Execution Record {DATE}
Mode: REPAIR-PROPOSE | REPAIR-DIRECT ({file})
Test file (READ-ONLY): {path}   ·   Repairs delivered as patch proposals only
Env check: APP_ENV=testing · DB_DATABASE=test_runner_db · DUSK_TENANT_URL={…}   ✅ safe
Static (A5.1): php -l ✅ · class=filename ✅ · duplicate methods none · skips 0 · blind waits 0


  Read 1 file

⏺ Update(Prompts/New/ExecuteAndRepair.md)
Added 1 line, removed 1 line

### 5.2 Repair log — `{Screen}_Repair_Log.md`

One block per iteration: **real failure text in → classification → the exact edit or patch out**. This log is the
One block per iteration: **real failure text in → classification → the patch proposal out**. This log is the
evidence that no fix was guessed; it is as much a deliverable as the green suite.

```markdown

⏺ Update(Prompts/New/ExecuteAndRepair.md)
Added 5 lines, removed 3 lines
EVIDENCE: `grep -n 'id=' Modules/StudentProfile/resources/views/category/create.blade.php`
  → `18: <form id="categoryModalForm" …>`
CLASSIFICATION: (a) test defect — invented selector
EDIT: `StudentCategoryTest.php` methods `…pos_03`, `…pos_04`, `…neg_07`, `…neg_08`:
  `#category-form` → `#categoryModalForm`   (4 occurrences, targeted Edit)
RE-RUN: iteration 2 — those 4 pass.
PATCH PROPOSED: {Screen}_Patch_Proposals/patch_01_SEL-MISSING.md
  `StudentCategoryTest.php` methods `…pos_03`, `…pos_04`, `…neg_07`, `…neg_08`:
  `#category-form` → `#categoryModalForm`   (4 occurrences, anchors quoted verbatim)
TEST FILE MODIFIED BY ME: NO — awaiting human application
RE-RUN: deferred until the patch is applied (iteration 2 re-executes then)
```

### 5.3 `_Health_Register.md`

  Read 1 file

⏺ Update(Prompts/New/ExecuteAndRepair.md)
Added 1 line
|---|---|
| `GREEN` | every method passes in a captured run |
| `GREEN-WITH-KNOWN-FAILS` | all remaining failures have a `DEV-###` (R9) |
| `PATCHES-PENDING` | failures classified, patch proposals written, **waiting on a human to apply them** — the normal end state of a repairing run |
| `RED` | failures remain unclassified or unresolved within the cap |
| `BLOCKED` | static check failed, environment unsafe, or a dev answer is required |
| `UNKNOWN` | never executed — the state 756 existing files are in until this prompt runs |

Now §4.5 (repair mechanics), the procedure, self-check, report and invocation blocks.

  Read 1 file

⏺ Update(Prompts/New/ExecuteAndRepair.md)
Added 10 lines, removed 5 lines
Second sighting across screens ⇒ promote immediately. **Never** work around a bucket-(c) failure locally; that is the
per-screen cost the Rule Card exists to eliminate.

### 4.5 Repair (only after classification)
### 4.5 Repair — author patch proposals (only after classification)

- Repair **(a)** only, and only with a cited failure line.
- One signature at a time; re-run **after** the batch of same-signature fixes, not after each edit.
- Targeted `Edit` per method. A full `Write` of the test file is forbidden (it also loses Stage B's TC-ID annotations).
- Propose a fix for bucket **(a)** only, and only with a cited failure line.
- **One patch file per signature**, listing every method it touches — not one patch per method. A signature affecting
  4 methods is one reviewable decision, and a human applying 4 separate patches will apply 3.
- Each patch is **corrective, never subtractive**: it may fix a selector, a route name, a string, a cleanup order or a
  tenancy call. It may **never** delete or loosen an assertion, add `markTestSkipped`, or lengthen a wait (R4).
- Anchors quoted verbatim with line numbers, re-grepped against disk immediately before writing the patch.
- Do not add methods, do not add TCs, do not extend scope. If a failure reveals missing coverage, that is a Stage-A
  `➕` item for the reviewer — record it, do not implement it.
- After a repair, re-run `php -l` before re-executing.
- **Never `Edit` the test file to "verify the patch works."** If a patch's correctness is uncertain, say so in the
  patch's confidence field and name what would settle it.
- Where several signatures are independent, propose them all in one iteration so a single human pass applies everything.

---


  Read 1 file

⏺ Update(Prompts/New/ExecuteAndRepair.md)
Added 10 lines, removed 7 lines

## 8. Procedure

0. **Sandbox setup:** `mkdir -p {OUTPUT_DIR}/{Module}`. Confirm the mode (§0.2) and, if `REPAIR-DIRECT`, echo the one
   writable file path. Run the §0.3 environment safety check and record it.
0. **Sandbox setup:** `mkdir -p {OUTPUT_DIR}/{Module}/{Screen}_Patch_Proposals`. State in your first message that every
   write this run lands under `{WORKSPACE_ROOT}` and that the test file is read-only. Run the §0.3 environment safety
   check and record it.
1. **Confirm the screen is approved** (`06-Review_Batches/…/_DISPOSITION.md`). Not approved ⇒ report and stop.
2. **A5.1 static validation** (§3). Any failure ⇒ `BLOCKED`, return to Stage B, stop.
3. **Read `_Failure_Signatures.md` and the Rule Card** once per session — not per iteration.
4. **Iteration 1:** execute, capture raw output to a file, extract only failure blocks, triage (§4.2), group by
   signature, repair or propose patches for bucket (a) only.
5. **Iteration 2, 3:** same. Re-run once per signature batch, never per edit.
6. **At green, green-with-known-fails, or the cap:** write the run record, repair log, health register row, and update
   `_Failure_Signatures.md` · `_DEV_Register_Candidates.md` · `_RuleCard_Candidates.md` · `_Escalations.md`.
4. **Execute** (§4.1), capturing raw output to `{OUTPUT_DIR}/{Module}/raw_{DATE}_it{n}.txt` — never to `/tmp`. Extract
   only the failure blocks.
5. **Triage** (§4.2), group by signature, and **author one patch proposal per signature** (§4.5) for bucket (a) only.
   Health becomes `PATCHES-PENDING`; report and stop — a human applies them and re-invokes you for the next iteration.
6. **On re-invocation:** re-run §3 static checks, execute again, and repeat 4–5. **Iterations count executions, capped
   at 3.** At green, green-with-known-fails, or the cap: write the run record, repair log, health register row, and
   update `_Failure_Signatures.md` · `_DEV_Register_Candidates.md` · `_RuleCard_Candidates.md` · `_Escalations.md`.
7. **Append one line to `_Run_Log.md`.** Self-check (§9) and stop. Do not proceed to the cross-reference scan (`A5.4`)
   or the validation report (`A5.5`).


⏺ Update(Prompts/New/ExecuteAndRepair.md)
Added 9 lines, removed 5 lines
- [ ] Environment safety check (§0.3) ran and is recorded. `APP_ENV=testing`, test-runner DB confirmed.
- [ ] Static checks ran **before** any execution.
- [ ] Every failure row quotes the **verbatim** failure text plus a `file:line` frame — no paraphrases.
- [ ] Every repair cites the failure line that justified it. **Zero** edits without cited evidence.
- [ ] No assertion was deleted or loosened; no `markTestSkipped` added; no blind wait lengthened. Confirm explicitly.
- [ ] Every patch proposal cites the failure line that justified it. **Zero** proposals without cited evidence.
- [ ] Every patch anchor was re-grepped against disk immediately before writing, and is quoted verbatim with its line number.
- [ ] One patch per signature, listing all affected methods — not one patch per method.
- [ ] No patch deletes or loosens an assertion, adds `markTestSkipped`, or lengthens a wait. Confirm explicitly.
- [ ] Every bucket-(b) failure has a `DEV-###` candidate row **and** its proving test left intact.
- [ ] Every bucket-(c) failure has a Rule Card candidate; none was worked around locally.
- [ ] Iterations used ≤ 3. If 3 were used with failures left, `_Escalations.md` has a complete hand-over block.
- [ ] Iterations (executions) used ≤ 3. If 3 were used with failures left, `_Escalations.md` has a complete hand-over block.
- [ ] `GREEN` appears only where a captured run supports it; `GREEN-WITH-KNOWN-FAILS` only where every fail has an ID.
      A run that ended in unapplied patches is `PATCHES-PENDING`, never a repaired health state.
- [ ] No test methods were added and no TC scope was extended; missing coverage was recorded as a Stage-A `➕` item.
- [ ] In `REPAIR-PROPOSE` mode: zero writes to `prime_testing`. In `REPAIR-DIRECT`: writes to exactly one named file, via `Edit` only.
- [ ] **Zero writes to `prime_ai`.** `git status` in both repos shows nothing beyond the one authorised test file.
- [ ] **Zero writes outside `{OUTPUT_DIR}`** — including the test file under repair, which was read-only this run.
      Raw run output was tee'd into `{OUTPUT_DIR}`, not `/tmp`.
- [ ] `git status` in `prime_ai` **and** `prime_testing` is unchanged. State this explicitly.
- [ ] No migration, seed, DB drop/truncate, composer or driver-install command was run.

---

⏺ Update(Prompts/New/ExecuteAndRepair.md)
Added 9 lines, removed 8 lines

```
EXECUTE & REPAIR — {Module} / {Screen}
Mode: {REPAIR-PROPOSE | REPAIR-DIRECT: {file}}     Env: SAFE
Test file: {path} (READ-ONLY)     Env: SAFE
Static (A5.1): {PASS | BLOCKED: reason}
Iteration 1: {p}/{n} pass   Iteration 2: {p}/{n}   Iteration 3: {p}/{n}
Final health: {GREEN | GREEN-WITH-KNOWN-FAILS ({ids}) | RED | BLOCKED}
Execution 1: {p}/{n} pass   Execution 2: {p}/{n}   Execution 3: {p}/{n}
Final health: {GREEN | GREEN-WITH-KNOWN-FAILS ({ids}) | PATCHES-PENDING | RED | BLOCKED}
Failures triaged: {n}   (a) test defect {n} · (b) app defect {n} · (c) environment {n}
Signatures: new {n} · reused from the index {n} · promoted to programme-level {n}
DEV candidates raised: {ids}      Rule Card candidates: {n}
Patches proposed: {n} ({paths})   Direct edits: {n} methods in {file}
Patches proposed: {n} covering {n} methods ({paths})
Assertions weakened: NONE   Tests skipped: NONE   Methods added: NONE
Iterations used: {n}/3      Token spend: ~{n}k of 150k
Files written (ALL under {WORKSPACE_ROOT}/07-Execute_Repair/, plus the one authorised test file if REPAIR-DIRECT): {list}
Writes to prime_ai: NONE
Executions used: {n}/3      Token spend: ~{n}k of 150k
Files written (ALL under {WORKSPACE_ROOT}/07-Execute_Repair/): {list}
Writes outside the sandbox: NONE     Test files edited: NONE     Writes to prime_ai: NONE
git status (prime_ai / prime_testing): unchanged
Escalated: {yes → path | no}
Human action required: {apply patches | answer DEV-### | approve a Rule Card rule | none}
Human action required: {apply {n} patches then re-invoke | answer DEV-### | approve a Rule Card rule | none}
```

---

⏺ Update(Prompts/New/ExecuteAndRepair.md)
Added 2 lines, removed 1 line
| **Rule Card once, never per screen** | Environment truths stop being re-discovered at ~40k tokens a time |
| **Raw output to file; read only failure blocks** | Avoids re-reading a full 200-line run output every iteration |
| **Static checks first (≈0 tokens)** | Never spend a cycle on a file that `php -l` rejects |
| **No full `Write` of the test file** | Preserves Stage B's TC-ID annotations and avoids ~8k output tokens per iteration |
| **Patch proposals, not file rewrites** | A patch is a few hundred output tokens; re-writing the test file is ~8k per iteration and would destroy Stage B's TC-ID annotations |
| **One patch per signature** | Batches a human's application pass the same way it batches the fix |

---


  Read 1 file

⏺ Update(Prompts/New/ExecuteAndRepair.md)
Added 5 lines, removed 2 lines

```
Run PROMPT A5.1-A5.3 (Execute & Repair) for screen: Student Category · module StudentProfile
Mode: REPAIR-PROPOSE   Cap: 3 iterations
Cap: 3 executions. Patch proposals only — the test file is read-only.
```

```
Run PROMPT A5.1-A5.3 for module StudentProfile — all approved screens, batched by failure signature
Mode: REPAIR-DIRECT authorised for: prime_testing/tests/Browser/Modules/StudentProfile/V2/*.php
Propose patches for every screen in one pass so I can apply them together, then re-invoke for execution 2.
```

```

Scope: 05-Legacy_Estate_Triage rows with Health=UNKNOWN
```

> **`health-only` is the cheapest high-value mode here**, and it needs no patches at all: executing is a read, so it
> stays wholly inside the sandbox rule while converting 756 `UNKNOWN` files into measured health.

> **Gate 6 (Master Plan):** no screen is `DONE` until its tests have been **executed** — green, or
> green-with-known-fails each linked to a `DEV-###`. Set `execute=true` for all P0/P1 work.
> The `health-only` mode above is how the 756 existing files stop being inventory and become coverage.

Now fix the two remaining places: R10 in the rules table, and the coverage map's shared-contract row.

  Ran 1 shell command

⏺ Update(Prompts/New/ExecuteAndRepair.md)
Added 1 line, removed 1 line
| **R7** | **Batch by failure signature.** Normalise the failure into a signature (§6) before repairing. One root cause routinely explains 40 failures across a module; repairing them o
ne at a time is the single largest waste in the programme. |
| **R8** | **`GREEN` is a measured state.** Only a run whose output you captured may be recorded `GREEN`. Never infer it, never carry it forward from a previous run of an edited file.
|
| **R9** | **Known-fails must be linked.** `GREEN-WITH-KNOWN-FAILS` is valid **only** when every remaining failure has a `DEV-###` row. An unlinked known-fail is just a red test with a
n excuse. |
| **R10** | **Write only inside the sandbox** (§0.1/§0.2). |
| **R10** | **Write only inside the sandbox** (§0.1). The test file under repair is **read-only**; fixes are patch proposals (§0.2). If you are about to write outside `{WORKSPACE_ROOT}
`, stop — you have misread the task. |

---


⏺ Update(Prompts/New/ExecuteAndRepair.md)
Added 1 line, removed 1 line

---

## 2. Inputs (read-only unless §0.2 applies)
## 2. Inputs (ALL read-only — including the test file)

| # | Input | Path |
|---|---|---|

⏺ Update(Prompts/_PROMPT_COVERAGE_MAP.md)
Added 1 line, removed 1 line

| | |
|---|---|
| **Sandbox** | Every write under `/Users/bkwork/WorkFolder/3-Local_Workspace/9-TestingStrategy`. `prime_ai`, `prime_testing`, `old_db`, `pgdatabase` are read-only. **One exception:**
`ExecuteAndRepair.md` in explicitly-granted `REPAIR-DIRECT` mode may `Edit` the single named test file — never application code. |
| **Sandbox** | Every write under a sub-folder of `/Users/bkwork/WorkFolder/3-Local_Workspace/9-TestingStrategy`. **No exceptions, in any prompt.** `prime_ai`, `prime_testing`, `old_db
`, `pgdatabase` are read-only — including the test file `ExecuteAndRepair.md` is repairing, which is fixed via patch proposals a human applies. |
| **No side effects** | No git operations · no migrations/seeders · no schema change · no canon edits · no `CLAUDE.md` edits |
| **Shell first** | grep/wc/find before reading. Never full-read a DDL, a controller > 20k chars, a blade > 15k chars, a TcList, or a test file. |
| **Promotion is human** | Anything belonging in canon is written into the sandbox plus a `PROMOTION CANDIDATES` line in `_Run_Log.md`. |

Now a full sweep across all seven for any other write-outside-sandbox language, plus the missing report line in DuskSelectorRetrofit.md.

  Ran 1 shell command

⏺ Update(Prompts/New/DuskSelectorRetrofit.md)
Added 2 lines, removed 1 line
Computed saving: {n}k tokens per Stage-A/B read across {n} screens ≈ {n}k per full pass
Repair history informing priority: {n} SEL-MISSING failures across {n} screens
Files written (ALL under {WORKSPACE_ROOT}/10-Selector_Retrofit/): {list}
Writes to prime_ai: NONE     Blades edited: NONE
Writes outside the sandbox: NONE     Writes to prime_ai: NONE     Blades edited: NONE
git status (prime_ai / prime_testing): unchanged
Token spend: ~{n}k (budget 4k/screen)
Human action required: apply {n} patch proposals, confirm VERIFY-IN-DOM rows, then fill _Applied_Log.md
```

  Read 1 file

⏺ Update(Prompts/New/DuskSelectorRetrofit.md)
Added 3 lines
```

> **Every file you create or modify MUST live under `{WORKSPACE_ROOT}`. No exceptions.**
> You have **no write permission anywhere else on this machine** — not in `prime_ai`, not in `prime_testing`,
> not in `old_db`, not in `pgdatabase`, not in `/tmp`, not in the git repo, not in `CLAUDE.md`.
>
> **You never edit a blade.** Blades are application code in `prime_ai`; the retrofit is applied by a developer from
> your proposal. This is not a formality — a mis-edited blade takes a screen down in production.


⏺ Update(Prompts/New/DuskSelectorRetrofit.md)
Added 2 lines, removed 1 line
- [ ] Every `❌ proposed` row has a verified real fallback so Stage A/B is unblocked today.
- [ ] Manifest ≤ 3,000 chars, with the count printed and the per-read saving computed, not guessed.
- [ ] `_Applied_Log.md` has **no** agent-written rows.
- [ ] **Zero writes to `prime_ai`.** `git status` in both repos unchanged. Confirm explicitly.
- [ ] **Every file written this run is under `{OUTPUT_DIR}`.** List them. Zero writes to `prime_ai`, `prime_testing`,
      `old_db`, `pgdatabase`, `/tmp`, or git — and zero blades edited. `git status` in both repos unchanged. Confirm explicitly.

---


Final verification across all seven.

  Ran 1 shell command

Yes — but one of the seven had carved out an exception, and I've now removed it.

Verified state (all 7 in Prompts/New/)

Each carries both directions in five places:

┌─────────────────────┬─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│      Location       │                                                                 Content                                                                 │
├─────────────────────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ §0.1 header         │ WORKSPACE_ROOT = /Users/bkwork/WorkFolder/3-Local_Workspace/9-TestingStrategy + a dedicated OUTPUT_DIR sub-folder                       │
├─────────────────────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ §0.1 blockquote     │ "no write permission anywhere else on this machine — not in prime_ai, prime_testing, old_db, pgdatabase, /tmp, the git repo, CLAUDE.md" │
├─────────────────────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ §0.1 table          │ Allowed / Forbidden writes / Read-only inputs / No side effects                                                                         │
├─────────────────────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ Rules table         │ a numbered rule: "Write only inside the sandbox — if you are about to write outside {WORKSPACE_ROOT}, stop, you have misread the task"  │
├─────────────────────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ Self-check + report │ "Every file written this run is under {OUTPUT_DIR}" and Writes outside the sandbox: NONE                                                │
└─────────────────────┴─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘

Sub-folders: 04-Module_Fact_Packs · 05-Legacy_Estate_Triage · 06-Review_Batches · 07-Execute_Repair · 08-Defect_Scan · 09-Rollups · 10-Selector_Retrofit.

The exception I removed

ExecuteAndRepair.md had a REPAIR-DIRECT mode that could Edit the one test file under repair in prime_testing — my reasoning was "a repair that cannot touch the test file is not a repair." That breaks direction #2, so it's gone. The prompt is now patch-proposal-only:

- Repairs are authored as patch files under {OUTPUT_DIR}/{Module}/{Screen}_Patch_Proposals/ — verbatim failure text, verbatim anchor line, replacement, classification. One patch per failure signature, listing every method it touches.
- New health state PATCHES-PENDING — the normal end of a repairing run. A human applies, then re-invokes for the next execution.
- The 3-iteration cap now counts executions, not edit cycles.
- Raw run output is tee'd into {OUTPUT_DIR}, not /tmp.
- Also updated: §0.2, the rules table (R10), §2 inputs header, §4.5, procedure, self-check, report block, cost-controls table, and the invocations.

The trade this makes: the loop is now slower — it stops for a human between executions instead of self-repairing to green. Worth naming, since it's a real cost, and I've written it into the prompt so nobody rediscovers it as a surprise. health-only mode is unaffected (executing is a read), so converting the ~756 UNKNOWN test files to measured health still runs unattended end-to-end.

Also fixed: DuskSelectorRetrofit.md was missing the "no write permission anywhere else" enumeration and the Writes outside the sandbox: NONE report line; and _PROMPT_COVERAGE_MAP.md §5 no longer advertises an exception that no longer exists.

✻ Worked for 5m 11s

❯ Execute all the Prompts from folder "/Users/bkwork/WorkFolder/3-Local_Workspace/9-TestingStrategy/Prompts/New". Run multipal Agent to execute Prompts in Parralel.

The user has explicitly requested parallel agents. Let me check the actual state of the dependencies first, so I scope each agent correctly rather than launching agents that immediately block.

  Ran 1 shell command

Dependency reality check changes two of the nine agents' scope:

- No kit Definition.md exists yet (only draft TcLists) → ReviewBatchPacket would self-block at step 1. Running it pre-flight-only instead.
- No .env in prime_testing, no Chrome/chromedriver → ExecuteAndRepair cannot execute anything; its §0.3 says stop. Running it as env-verification + A5.1 static validation, which needs no environment and still produces a real health register.

Launching 9 agents on disjoint output paths.

⏺ 9 background agents launched (↓ to manage)
Fact Packs: P0 money modules
Fact Packs: exam/admission modules
Fact Packs: setup/HR modules
Estate triage: P0/P1 modules
Estate triage: ops/timetable modules
Cross-ref defect scan: high-yield
Review pre-flight + kit blocker
Static validation of test estate
Selector retrofit candidates

9 agents launched and running in parallel. Each owns a disjoint output folder, so there are no write collisions.

Wave 1 — running now

┌───────┬──────────────────────────┬─────────────────────────────────────────────────┬──────────────────────────┐
│ Agent │          Prompt          │                      Scope                      │          Output          │
├───────┼──────────────────────────┼─────────────────────────────────────────────────┼──────────────────────────┤
│ FP-1  │ ModuleFactPack           │ StudentProfile, StudentFee, Payment             │ 04-Module_Fact_Packs/    │
├───────┼──────────────────────────┼─────────────────────────────────────────────────┼──────────────────────────┤
│ FP-2  │ ModuleFactPack           │ LmsExam, MarksheetGeneration, Admission         │ 04-Module_Fact_Packs/    │
├───────┼──────────────────────────┼─────────────────────────────────────────────────┼──────────────────────────┤
│ FP-3  │ ModuleFactPack           │ SchoolSetup, HrStaff, ParentPortal              │ 04-Module_Fact_Packs/    │
├───────┼──────────────────────────┼─────────────────────────────────────────────────┼──────────────────────────┤
│ ET-1  │ LegacyEstateTriage       │ 6 P0/P1 modules, full mode                      │ 05-Legacy_Estate_Triage/ │
├───────┼──────────────────────────┼─────────────────────────────────────────────────┼──────────────────────────┤
│ ET-2  │ LegacyEstateTriage       │ 6 ops/timetable modules, full mode              │ 05-Legacy_Estate_Triage/ │
├───────┼──────────────────────────┼─────────────────────────────────────────────────┼──────────────────────────┤
│ DS-1  │ CrossReferenceDefectScan │ checks 12–15, the 3 P0 money modules            │ 08-Defect_Scan/          │
├───────┼──────────────────────────┼─────────────────────────────────────────────────┼──────────────────────────┤
│ RB-1  │ ReviewBatchPacket        │ pre-flight-only + kit blocker                   │ 06-Review_Batches/       │
├───────┼──────────────────────────┼─────────────────────────────────────────────────┼──────────────────────────┤
│ EX-1  │ ExecuteAndRepair         │ env verification + A5.1 static, ~933 test files │ 07-Execute_Repair/       │
├───────┼──────────────────────────┼─────────────────────────────────────────────────┼──────────────────────────┤
│ SR-1  │ DuskSelectorRetrofit     │ candidates + 3 manifests + 1 patch              │ 10-Selector_Retrofit/    │
└───────┴──────────────────────────┴─────────────────────────────────────────────────┴──────────────────────────┘

Scoping decisions I made

Two prompts are running degraded — deliberately, because their own rules say to stop rather than fake it:

- RB-1: no A{n}_Definition.md exists anywhere. 02-Category_Kits/ holds only three draft exemplar TcLists awaiting your red-lines. The prompt's step 1 says stop, so RB-1 documents the blocker and runs only the kit-independent pre-flight checks. It cannot invent a FORBIDDEN list.
- EX-1: prime_testing has no .env, and neither google-chrome nor chromedriver is installed. §0.3 forbids fixing the environment itself, so EX-1 verifies readiness and runs A5.1 static validation across the estate — which needs no DB and still converts ~933 files from unknown to statically measured.

Cross-dependencies handled by self-derivation, not waiting (the write-collision rule bans reading a sibling's in-flight output): DS-1 derives its own DDL inventory rather than waiting on FP-1's Fact Packs, and SR-1 derives candidate Dusk tiers from archetypes rather than waiting on ET-1/ET-2's tier register — both marked for reconciliation, matching how your existing orchestrator unblocked the kit agents.

Module scope: the 12 modules that have classification shards (266 screens). Fact Packs and the defect scan are weighted to the P0 money-and-identity modules first.

Wave 2 — after these return

ProgrammeRollups is held back on purpose: its entire input is the registers the other nine are writing right now, and rolling up empty registers produces a dashboard of NOT AVAILABLE. Once wave 1 lands I'll merge the per-agent files (_Identity_Register_FP-*, the ET shards → the three top-level registers, _DEV_Register_DS-1) and then run it.

I'll report back as each agent completes.

✻ Cooked for 3m 32s

⏺ Agent "Static validation of test estate" finished · 24m 57s

EX-1 has landed. Let me spot-check its headline claims before relaying them.

  Ran 2 shell commands

Verified independently — all of EX-1's headline claims hold. My counts across all of tests/ run slightly higher (667 / 687 / 59) than its in-scope numbers (527 / 513 / 41) because it correctly excluded Backup_Old_TestCase/ and Created_by_Brijesh/; its 771-file scope matches exactly.

EX-1 complete — ExecuteAndRepair (static-only)

Execution is genuinely blocked, and not by anything the agent could fix. prime_testing has no .env, no .env.example, and no phpunit.xml or phpunit.dusk.xml — none of which are tracked in git, so there's no template to restore from. Plus no Chrome/chromedriver. It escalated instead of improvising, which is right.

What it produced anyway — A5.1 static validation over 771 files, needing no environment:

- php -l: 100% clean. Zero syntax failures across the estate.
- 101 files sitting in the Dusk tree with zero $browser-> use and real HTTP assertions — mis-tiered. My own spot-check found 130 Browser files with no $browser-> at all. This is hard evidence for the inverted-pyramid problem the tier assignment is meant to fix, arriving independently of the ET agents.
- 41 files with vacuous assertTrue(true) assertions, including one file that is ~39 stub methods end to end — inventory masquerading as coverage.
- 12 real class-name/filename mismatches, and this is the finding I'd act on first: the repo contains two competing, undocumented mechanisms for routing around PHPUnit's naming rule — tests/Browser/Modules/preload.php (runtime class_alias) and tests/Browser/Modules/fix_test_classes.php (a file renamer). Both exist on disk; which one is actually wired in is unverifiable while phpunit.xml is missing. Whoever reconstructs that file decides this.

One number to read carefully: the register says 617 files BLOCKED (80%). The agent flagged that this is not 617 defects — 473 of them trip only two systemic conventions (markTestSkipped guards, ->pause() waits) that appear to be the house idiom, not errors. That needs one Rule Card decision, not 617 fixes. Treating that number as a work list would be a serious misread, and the agent said so rather than letting the count flatter itself.

Output in 07-Execute_Repair/: _Environment_Readiness.md (ordered 8-step unblock list), _Health_Register.md (771 rows), _Static_Findings.md, _Failure_Signatures.md, _Escalations.md. No writes outside the sandbox; both repos clean.

8 agents still running — the three Fact Pack builds, both estate triages, the defect scan, review pre-flight, and selector retrofit. I'll report each as it lands, then merge the per-agent registers and run the roll-up.

✻ Cogitated for 52s

⏺ Agent "Review pre-flight + kit blocker" finished · 26m 45s

RB-1 landed, but it claims the 00_ conventions contract "does not exist anywhere reachable" — I saw that file earlier. Verifying.

  Ran 3 shell commands

Verified. RB-1's core findings hold, and one of its stated reasons was wrong in a way that surfaces something more useful.

RB-1 complete — ReviewBatchPacket (pre-flight only)

The blocker is real and confirmed: no archetype has a Definition.md, digest or rubric. 02-Category_Kits/ holds three Stage-1 drafts (A2, A3, A7) and _RedLines/ is empty. A1, A5, A6, A8, A9 — which own most TcLists in the two modules scanned — have zero kit-track artefacts. And 0 of 556 TcLists contain a Category Obligation Matrix, so nothing in the estate is category-aware yet.

Confirmed defects (I checked each): genuine duplicate TC-IDs in StudentProfile — TC-ATT-P14 used twice (QR scan and manual entry), TC-MI-P25 three times, TC-MI-P72 twice. Each duplicate set maps to a single test method, so distinct behaviours are being counted as covered by one method. That's a live traceability defect, not a cosmetic one.

Format split confirmed: StudentProfile TcLists have 3 sections (one has 1); StudentFee's have 11. Two different legacy formats, neither matching the contract the new pipeline assumes.

Correction to the agent's reasoning, because it changes the conclusion: it reported check 1 as unscoreable because "no such contract document exists anywhere reachable." That's wrong — 00_Testing_Artifacts_Index_and_Conventions.md exists at the canonical path (22,550 chars) and does define the artefact contract. But checking it surfaces the more important problem: 00_ specifies a 5-artefact contract with a combined TcList+manual-testing document, while the Master Plan and token-cost doc describe a 13-section standalone TcList. Canon and the new plan disagree about what a TcList is. That is an A0.3 canon patch item and it sits upstream of every TcList-format judgement the pipeline makes — including my ReviewBatchPacket.md §4.1 check 1, which I wrote against the 13-section assumption.

Coverage shortfalls found arithmetically (DDL derived directly, no Fact Pack read): Student Create (A9 — both negative floors short; an 8-table wizard's budget doesn't come from a flat per-table sum), Application Review (A6 — zero dependency TCs against 12 outbound FKs), Fee Structure Master (A3, off by one), Fee Name Removal (A8, both floors short).

Batch plan: only StudentFee × A2 (5 TcLists, all P0) meets the 5-TcList floor and has a draft kit — the single highest-leverage red-line target. StudentProfile can't form a batch at all: every archetype there is a singleton. The agent considered cross-module batching to reach size and explicitly rejected it rather than breaking R1.

Output in 06-Review_Batches/: _PREFLIGHT_StudentProfile.md, _PREFLIGHT_StudentFee.md, _Batch_Plan_RB-1.md, _DEV_Candidates_RB-1.md. No TcLists edited; both repos clean.

7 agents still running (3 Fact Packs, 2 estate triages, defect scan, selector retrofit).

✻ Churned for 46s

⏺ Agent "Selector retrofit candidates" finished · 27m 47s

  Ran 3 shell commands

Verified against disk: blade sizes exact (237,644 + 170,665 + 141,521 = 549,830), all three manifests under the 3,000-char cap, patch anchors at lines 35/58/59 are real and match the described elements, 6 changes all additive, nothing removed or renamed.

SR-1 complete — DuskSelectorRetrofit (candidates + 3 manifests + 1 patch)

The scope discipline worked: 269 screens assessed, 51 Dusk-candidates, 215 excluded as Feature-tier. That ~19% Dusk share is an independent corroboration of the 15% pyramid target — and it means the retrofit stays a ~50-screen job, not a 3,749-blade one. All 51 fit inside the 40–60 cap with no trimming.

The payback numbers are real, not estimated:

┌───────────────────────────────────────────────────┬───────────────┬──────────┬─────────────────┐
│                      Screen                       │   Blade set   │ Manifest │ Saving per read │
├───────────────────────────────────────────────────┼───────────────┼──────────┼─────────────────┤
│ SchoolSetup — Employee Wizard (A9, P0)            │ 549,830 chars │    2,998 │    ~136k tokens │
├───────────────────────────────────────────────────┼───────────────┼──────────┼─────────────────┤
│ StudentProfile — Student Edit (A9, P0)            │       181,785 │    2,978 │            ~45k │
├───────────────────────────────────────────────────┼───────────────┼──────────┼─────────────────┤
│ TimetableFoundation — Requirement Wizard (A9, P1) │       206,847 │    2,928 │            ~51k │
└───────────────────────────────────────────────────┴───────────────┴──────────┴─────────────────┘

232k tokens saved per Stage-A/B read across just these three screens. The Employee Wizard alone is a half-million-character blade set — Stage A would otherwise re-read that on every pass. This is the single largest per-read cost in the pipeline, and a 3KB manifest replaces it.

The patch (Employee Wizard, 6 additive attributes) is disciplined: the loop-row action is keyed on $address->id, not the loop index, and the rationale explicitly calls out that the existing data-address-index breaks when rows are removed and the array re-indexes. It also flags that #tab-sch_employees is a DB-table-shaped id — brittle if the table is renamed. Twelve rows across the manifests are marked VERIFY-IN-DOM (component/@include-rendered) rather than asserted to work.

Two caveats worth carrying forward:

1. All tiers are CANDIDATE-TIER, self-derived from archetype — the ET agents' Tier_Assignment_Register.md didn't exist when SR-1 ran. These need reconciling once ET-1/ET-2 land; a screen SR-1 called Dusk that ET calls Feature is wasted retrofit effort.
2. Minor bookkeeping inconsistency: the summary says 51 candidates / 215 N/A / 269 assessed, but the register file contains 56 Dusk-CANDIDATE markers, 191 NOT-APPLICABLE, and 284 numbered rows. The narrative explains 54 matched → 2 excluded → 1 folded → 51, so the deltas are probably legend and summary-table rows, but the counts should be reconciled before the register is used as a work list.

Token spend was high (~300k) because CANDIDATES mode swept ~1,200 blades across 12 modules — well over the ≤4k/screen figure, which was written for the single-screen mode. The agent flagged this itself rather than quietly exceeding it.

Output in 10-Selector_Retrofit/: _Naming_Convention.md, _Candidate_Screens.md, 3 manifests, 1 patch, _Applied_Log.md left as an empty table (correct — no agent may claim a patch was applied). No blades edited; both repos clean.

6 agents still running: 3 Fact Packs, 2 estate triages, the defect scan.

✻ Brewed for 46s

⏺ Agent "Estate triage: ops/timetable modules" finished · 34m 0s

  Ran 1 shell command

Confirmed exactly (21+46+0+0+0+1 = 68). But ET-2's calibration note exposes a real defect in the prompts I wrote — let me check its scope.

  Ran 2 shell commands

Two real regex defects in my prompts, confirmed by counting the estate. Fixing them.

⏺ Update(Prompts/New/LegacyEstateTriage.md)
Added 2 lines, removed 2 lines

# Health of a TcList — all from grep counts:
head -25 "$F"                                   # feature info + status header
grep -cE "^\| *TC-[PND]-[0-9]+"        "$F"      # TC count
grep -cE "^\| *BC-(DB|VAL|AUTH|BIZ|REF|SM|IDX)" "$F"   # BC count
grep -cE "^\| *TC-[A-Z]{1,4}-?[0-9]+"  "$F"      # TC count  — see the ID-CONVENTION warning below
grep -cE "^\| *BC-[A-Z]{2,5}-?[0-9]+"  "$F"      # BC count  — deliberately tolerant, do not narrow it
grep -c  "Category Obligation Matrix"  "$F"      # ← present ⇒ category-aware (post-kit); absent ⇒ pre-kit
grep -c  "Source"                      "$F"      # source-anchor discipline
grep -cE "Covered By.*[A-Za-z_]+\(\)"  "$F"      # implemented TCs (Covered-By filled)

⏺ Update(Prompts/New/LegacyEstateTriage.md)
Added 1 line, removed 1 line
T=$PT/tests/Browser/Modules/$M/V2/StudentTest.php
grep -cE "public function test_"        "$T"     # method count
grep -c  "tenancy\|InitializeTenancy\|tenant("  "$T"   # tenancy scaffolding present?
grep -cE "TC-[PND]-[0-9]+"             "$T"      # TcList traceability in comments
grep -cE "TC-[A-Z]{1,4}-?[0-9]+"       "$T"      # TcList traceability in comments
grep -cE "assertSee|assertPathIs|click|type\("  "$T"   # is it really a browser test?
grep -cE "\\\$this->(get|post|put|patch|delete)\(" "$T" # HTTP-style assertions in a Dusk file → mis-tiered
php -l "$T"                                       # static health, ≈0 tokens

⏺ Update(Prompts/New/LegacyEstateTriage.md)
Added 22 lines

### 3.2 Triage signals — headers and greps, never bodies

> ⚠️ **ID-CONVENTION WARNING — calibrate before you count.** The regexes below are deliberately tolerant because this
> estate uses **several** ID conventions at once. Measured across all 556 TcLists on 2026-07-30:
>
> | Form | Occurrences | Note |
> |---|---:|---|
> | `TC-PNN`, `TC-NNN`, `TC-CRNN`, `TC-DNN`, `TC-ENN`, `TC-SNN`, `TC-UXNN` | ~49,000 | **no hyphen before the number — the dominant form** |
> | `TC-P-NN`, `TC-N-NN`, `TC-D-NN`, `TC-CR-NN` | ~3,700 (~7%) | the hyphenated form the canon examples use |
> | `TC-MI-P25`, `TC-ATT-P14` | some modules | a third form: screen-abbreviation *then* type |
>
> A `TC-[PND]-[0-9]+` regex therefore misses **~93%** of the estate. BC-IDs are hyphenated (`BC-DB-07`) but the class
> list is wider than the canon taxonomy: `BIZ · DB · VAL · AUTH · EDG · REF · SEC · REL` all occur — `EDG`, `SEC` and
> `REL` alone are ~2,700 occurrences.
>
> **Therefore:** before counting a module, run the calibration below and record the convention in the shard header.
> A TC count of 0 or an implausibly low count means your regex is wrong, **not** that the TcList is empty.
>
> ```bash
> # Which conventions does THIS module use? Run once per module, ~0 tokens.
> grep -rhoE "TC-[A-Z]{1,4}-?[0-9]{1,3}\b" "$TCLIST_DIR" | sed -E 's/[0-9]+$/NN/' | sort | uniq -c | sort -rn
> grep -rhoE "BC-[A-Z]{2,5}-?[0-9]{1,3}\b" "$TCLIST_DIR" | sed -E 's/[0-9]+$/NN/' | sort | uniq -c | sort -rn
> ```

```bash
F=$PT/Doc_Analysis/4-TC_List_Requirement_Review/$REVIEW/TC_List/std_Student_TcList.md


⏺ Update(Prompts/New/ReviewBatchPacket.md)
Added 17 lines, removed 3 lines

### 3.2 Building the batch table — greps only

> ⚠️ **Calibrate the ID regex first.** This estate uses several TC-ID conventions simultaneously — `TC-P01` (no
> hyphen) is the dominant form at ~93% of occurrences, `TC-P-01` is ~7%, and some modules use a third form
> (`TC-MI-P25` — screen abbreviation, then type). A `TC-[PND]-[0-9]+` regex silently returns near-zero on most
> modules. BC classes are wider than the canon taxonomy too: `BIZ · DB · VAL · AUTH · EDG · REF · SEC · REL`.
> Run the calibration line first and record the convention in the packet header. A TC count of 0 means your regex is
> wrong, not that the TcList is empty.

```bash
F=$PT/Doc_Analysis/4-TC_List_Requirement_Review/$REVIEW/TC_List/std_Category_TcList.md
grep -cE "^\| *TC-P-[0-9]+" "$F"; grep -cE "^\| *TC-N-[0-9]+" "$F"; grep -cE "^\| *TC-D-[0-9]+" "$F"
grep -cE "^\| *BC-[A-Z]+-[0-9]+" "$F"

# 0 · calibrate (once per module, ~0 tokens)
grep -rhoE "TC-[A-Z]{1,4}-?[0-9]{1,3}\b" "$(dirname "$F")" | sed -E 's/[0-9]+$/NN/' | sort | uniq -c | sort -rn

# then count with the tolerant forms
grep -cE "^\| *TC-[A-Z]*P-?[0-9]+" "$F"   # positive
grep -cE "^\| *TC-[A-Z]*N-?[0-9]+" "$F"   # negative
grep -cE "^\| *TC-[A-Z]*D-?[0-9]+" "$F"   # dependency
grep -cE "^\| *BC-[A-Z]{2,5}-?[0-9]+" "$F"
grep -c "Category Obligation Matrix" "$F"
grep -nE "^\| *TC-[PND]-[0-9]+" "$F" | head -200        # the TC table — the only body you extract
grep -nE "^\| *TC-[A-Z]{1,4}-?[0-9]+" "$F" | head -200   # the TC table — the only body you extract
```

### 3.3 Per-TcList review sheet

Verified independently — file counts match exactly (21+46+0+0+0+1 = 68), and ET-2's calibration note turned out to expose a defect in prompts I wrote.

ET-2 complete — LegacyEstateTriage (6 ops/timetable modules)

The headline is blunt: REUSE = 0. Of 82 real TcLists, none has a Category Obligation Matrix and none has any reviewer sign-off — Status and Covered-By columns are 100% empty. So 13 are RE-REVIEW, 83 are RE-AUTHOR. Nothing in these six modules can be handed to Stage B as-is.

A finding sharper than the counts: 33 screens scored FULL (row + TcList + test), but 0/68 test files cite a TC-ID and 0/82 TcLists have a filled Covered-By column. So not one artefact pair actually proves the test implements the TcList. FULL here means "all three files exist," not "traced" — the agent flagged this rather than letting the status flatter itself.

Coverage is thinner than the file count suggests: ParentPortal, Notification and StandardTimetable have zero Dusk tests. All 68 sit in SchoolSetup (21), HrStaff (46) and TimetableFoundation (1). Of those, 61 are REGENERATE-AS-FEATURE.

Tier gate PASSES — Dusk lands at 8.6% aggregate, 7.0–11.3% per module, well under the 25% ceiling. Unit is only 2.2% against a 15% target, and the agent gave the honest reason rather than an excuse: real calculation-engine content in this scope is almost entirely HrStaff payroll (increments, LOP reconciliation, payroll runs, TDS ledger); the rest is CRUD/workflow with little pure logic. That's a scope fact, not a gap to fill artificially.

Journeys: #4, #11, #12 claimed; no double-ownership. Two adjacency risks flagged for other agents' scope — #5 (SmartTimetable lives elsewhere) and #6 (SchoolSetup row 10 is staff attendance, likely not the intended student journey owned by StudentProfile).

Defect in my prompts, found and fixed

ET-2 noted the estate's real TC-IDs are TC-P01/TC-CR01, not the TC-P-01 my prompts' regexes assumed. I counted it across all 556 TcLists:

┌──────────────────────────────────────────────────────────────────────┬─────────────┐
│                                 Form                                 │ Occurrences │
├──────────────────────────────────────────────────────────────────────┼─────────────┤
│ TC-PNN, TC-NNN, TC-CRNN, TC-DNN, TC-ENN, TC-SNN, TC-UXNN — no hyphen │     ~49,000 │
├──────────────────────────────────────────────────────────────────────┼─────────────┤
│ TC-P-NN, TC-N-NN, TC-D-NN — the form I used                          │ ~3,700 (7%) │
└──────────────────────────────────────────────────────────────────────┴─────────────┘

My TC-[PND]-[0-9]+ regex would have missed ~93% of the estate and silently reported near-zero TC counts as fact. BC classes are wider too — EDG, SEC, REL (~2,700 occurrences) were absent from my class list.

Fixed in LegacyEstateTriage.md and ReviewBatchPacket.md: tolerant regexes, plus a mandatory per-module calibration step and an explicit rule that a TC count of zero means your regex is wrong, not that the TcList is empty. ET-2 caught this by sampling six file headers; ET-1 is running the un-fixed version, so I'll check its counts for the same artefact when it lands.

Human decisions queued: 61 retire proposals (all unapproved), 13 RE-REVIEW judgement calls, 4 SchoolSetup register discrepancies incl. an EmployeeProfile/EmployeeCreationProfile duplicate, 4 AMBIGUOUS archetypes blocking tier finalisation, and the --group={module} CI convention.

5 agents still running: 3 Fact Packs, ET-1, DS-1.

✻ Crunched for 1m 28s

⏺ Agent "Cross-ref defect scan: high-yield" finished · 39m 37s

DS-1 reports a P0 money-loss path. That's too consequential to relay unverified — checking it myself.

  Ran 1 shell command

⏺ Agent "Fact Packs: exam/admission modules" finished · 40m 37s

Finishing the P0 verification, then checking FP-2's claim that my own prompt contains a fabricated example.

  Listed 1 directory, ran 2 shell commands

Decisive: FeeInvoice and FeeTransaction both have SoftDeletes; FeeReceipt alone does not — the three sibling calls are identical, only one throws. DS-1's P0 is confirmed and correctly scoped. Fixing the fabricated example FP-2 caught in my prompt.

  Searched for 1 pattern

⏺ Update(Prompts/New/ModuleFactPack.md)
Added 3 lines, removed 1 line
# Does the folder exist under the name the registry claims?
ls -d $APP

# Does the REVIEW_FOLDER exist? (frequently ≠ module name: LmsExam→Exam, GlobalMaster→Dropdown)
# Does the REVIEW_FOLDER exist? The registry documents aliases (LmsExam→Exam, GlobalMaster→Dropdown) but MEASURED
# 2026-07-30: several are STALE — no `Exam/` directory exists; LmsExam's real review folder is `LmsExam/`.
# Trust `ls`, never the alias list. Every alias you rely on must be confirmed to exist on disk first.
ls -d /Users/bkwork/Herd/prime_testing/Doc_Analysis/4-TC_List_Requirement_Review/$REVIEW

# Is the prefix real? Count CREATE TABLE blocks that actually use it.

⏺ Update(Prompts/New/ModuleFactPack.md)
Added 7 lines, removed 1 line
| Module | Code | Prefix (registry) | Prefix (verified) | Folder | Review Folder | DDL file | Tables | Screens | Scope | Registry OK? |
|--------|------|-------------------|-------------------|--------|---------------|----------|-------:|--------:|-------|--------------|
| StudentProfile | STD | std_ | std_ ✅ | StudentProfile | StudentProfile | student_profile.sql | 14 | 22 | TENANT | ✅ |
| LmsExam | EXM | exm_ | exm_ ✅ | LmsExam | **Exam** ⚠️ | lms_exam.sql | 31 | 40 | TENANT | ⚠️ review folder ≠ module |
| LmsExam | EXM | lms_ | lms_ ✅ | LmsExam | `Exam` per registry — **no such folder; real is `LmsExam/`** ⚠️ | `LmsExam_DDL_` prefix — verify the exact filename | 19 | 30 | TENANT | ⚠️
stale REVIEW_FOLDER |

> ⚠️ **Two traps this real row demonstrates, both measured on 2026-07-30:**
> 1. **`CODE` ≠ `PREFIX`.** LmsExam's code is `EXM` but its table prefix is **`lms_`** (shared with LmsHomework and
>    LmsQuests). Never derive a prefix from the code — read the `PREFIX` column, then verify it against `CREATE TABLE`.
> 2. **The registry's alias list is stale.** It documents `LmsExam → Exam`, but no `Exam/` folder exists; the real
>    review folder is `LmsExam/`. Confirm every alias with `ls` before using it, and log the ones that fail.
```

> This table alone removes the 2.8M-token cost of re-reading `module_list.md` on every screen of every stage.

⏺ Update(Prompts/New/ModuleFactPack.md)
Added 1 line, removed 1 line
```markdown
| Input file | Field | Says | Disk says | Evidence | Suggested A0.3 patch |
|---|---|---|---|---|---|
| module_list.md | LmsExam REVIEW_FOLDER | LmsExam | `Exam/` | `ls …/4-TC_List_Requirement_Review/` | update the row |
| module_list.md | LmsExam REVIEW_FOLDER | `Exam` (+ alias note at line 62) | only `LmsExam/` exists | `ls …/4-TC_List_Requirement_Review/` returns no `Exam` | correct the column and t
he alias list |
```

You never edit the registry. This file is the input to `A0.3` (Canon Authoring & Maintenance).

Both verified. Two agents landed, and one found an error in my prompt.

DS-1 complete — CrossReferenceDefectScan (checks 12–15, 3 P0 modules)

28 findings: 7 HIGH, 15 MEDIUM, 3 LOW, 3 THEORETICAL. I verified the P0 personally, limb by limb:

DEV-301 — confirmed, and the mechanism is worse than a mismatch. FeeInvoiceService.php has three sibling calls: FeeInvoice::withTrashed() (266), FeeTransaction::withTrashed() (274), FeeReceipt::withTrashed() (282). FeeInvoice and FeeTransaction both have SoftDeletes. FeeReceipt has zero — no trait, no deleted_at, no BaseModel shim, and no withTrashed macro registered anywhere in the codebase. So line 282 throws BadMethodCallException unconditionally, while its two identical neighbours work fine. A copy-paste with one omission.

It sits inside recordGatewayPayment()'s DB::transaction, after the payment row is written, in the receipt-number generator — the last step of recording a payment. Every online fee payment rolls back: payer debited, application records nothing. Reachability proven to three live routes (Parent Portal, Student Portal web, mobile).

SP-1a — a mechanical cause worth acting on immediately. In StudentFee_DDL_v4.sql, every table-level UNIQUE INDEX reached the migrations (6/6); every inline VARCHAR(n) NOT NULL UNIQUE was dropped (0/10). invoice_no, transaction_no, receipt_no, refund_no and six more have no index — and the generators use COUNT(*)+1, which collides deterministically after any hard delete. The smoking gun: one migration carried the column's ->comment('Unique code…') while dropping the uniqueness itself. One DDL-form diff script across the other 10 modules is the highest-value next action here — ten confirmed HIGHs came from one module.

The methodological finding is the most transferable one. DS-1 treated migrations, not DDL files, as production truth. Reading the StudentProfile DDL alone would have produced five phantom HIGHs; conversely _DEV_Candidates_StudentFee.md row 4 records "no defect" on all four document-number columns citing the DDL — and none of those UNIQUEs reached the database. That single choice is the difference between 7 real HIGHs and 13, six of them wrong. Every DDL-only conclusion in the programme should be re-checked. It also logged 8 false positives (~25 findings avoided, 6 would-be HIGH) rather than banking them.

FP-2 complete — Fact Packs (LmsExam, MarksheetGeneration, Admission)

54 tables, 73 screens, all TENANT, prefixes verified, 289 permission strings and 44 activity-log strings captured verbatim. Mandatory-negative budget: 40 UNIQUE / 239 NOT-NULL / 109 VARCHAR.

It caught a fabricated example in the prompt I wrote, and it was right. My ModuleFactPack.md worked example gave LmsExam PREFIX = exm_. The registry says lms_ — EXM is the code, and the prefix is shared with LmsHomework and LmsQuests. My example would have taught every agent a false prefix. I also propagated the registry's LmsExam → Exam alias as fact; no Exam/ folder exists — the real one is LmsExam/. Both fixed, with the two traps (CODE ≠ PREFIX; aliases must be ls-confirmed) now called out explicitly.

Three more findings I confirmed:
- Rule Card E25 is wrong platform-wide — it names the tenant activity sink activity_logs; disk says sys_activity_logs (TenantCore and GlobalMaster), with Prime using sys_central_activity_logs. Affects every module using activityLog().
- The audit canon is 8 findings stale, including all three P0s (SEC-EXM-005, BUG-MSH-001, BUG-ADM-004 are fixed on disk). Stage A/B trusting the 2026-06-29 reports would write tests asserting broken behaviour.
- php artisan route:list cannot run (Class "Sentry\Laravel\Integration" not found), so all route tables are file-derived — disclosed in every pack's §11 rather than passed off as confirmed.

Also: Admission has 12 of 20 tables with no UNIQUE key at all, and the classification shard's claimed composite on adm_quota_config doesn't exist — a duplicate-rejection test written from that shard would fail.

3 agents still running: FP-1, FP-3, ET-1.

✻ Baked for 1m 11s

⏺ Agent "Estate triage: P0/P1 modules" finished · 44m 11s

ET-1's third finding — 276 test methods that the classification pass never saw — is the kind of thing that invalidates a work-breakdown. Verifying it and the coverage claims.

  Ran 3 shell commands

Verified, and both findings are larger than reported.

ET-1 complete — LegacyEstateTriage (6 P0/P1 modules)

REUSE = 0 again — 0 of 89 TcLists have a Category Obligation Matrix, and 0 carry a genuine approval marker. It checked its own hits and found every apparent approval was a false positive: UNSIGNED column declarations and ENUM values literally named Approved/Reviewed. That's the discipline that separates a count from a fact.

Confirmed exactly: StudentFee has 1 test file with 3 methods; Payment has 0 files; MarksheetGeneration has 0 in the canonical path — while StudentFee and Payment own mandatory release journeys #9 (fee collection → receipt → ledger) and #10 (payment gateway → reconciliation). The two highest-risk money journeys in the platform have essentially no executable coverage.

Finding 3 is bigger than reported. ET-1 found 5 MarksheetGeneration test files (~276 methods) misfiled under tests/Created_by_Brijesh/Version-1/. I counted 261 methods in those 5 — plus 10 more MSH files under Z-Old_TestCases/ with 341 methods. So 15 files and 602 test methods for MarksheetGeneration exist entirely outside the path the classification pass searched. Its "top reconciliation priority" call was right, and the target is 2.3× what it measured.

And a baseline problem neither agent fully sized. ET-1 flagged 49 *TcList_Require.md companion docs in its 3 modules. Repo-wide there are 492 — plus 562 non-standard TcList-named docs in total. They sit next to the tests under tests/, not in Doc_Analysis/4-TC_List_Requirement_Review/.../TC_List/, which is the only path the canon, my prompts, and the token-cost doc's "556 TcLists" figure ever look at. There is a second, parallel TcList estate roughly as large as the one being managed. That changes the denominator for every coverage number in the programme.

Also confirmed: Admission's TcLists overstate "Automated" coverage by 2.7–4.5× (real methods are 22–37% of claimed). Tier gate PASSES — Dusk 6.75%, never above ~10% in any module. All six of its mandatory journeys (#2, #3, #7, #8, #9, #10) claimed exactly once, no double-ownership.

One honest gap it raised rather than papered over: my §4.1 verdict rules have no branch for "nothing is ever approved" — the rule set assumes some TcLists are signed off. It applied a documented interpretive ruling per module instead of silently picking one. That's a real hole in the prompt I wrote, and it needs a rule for the pre-approval state.

Regex check: ET-1 ran before my fix, but it evidently calibrated on its own — its StudentFee TC count is consistent with my tolerant-regex recount (3,527 raw occurrences → ~2,120 unique). No under-count artefact.

Queued for you: 34 retire approvals (all unapproved), the MSH misfiled-test reconciliation (now 15 files), 2 duplicate-TcList reconciliations, 2 AMBIGUOUS archetypes (LmsExam row 22, Admission row 11), and the CI annotation convention.

2 agents still running: FP-1 (StudentProfile, StudentFee, Payment) and FP-3 (SchoolSetup, HrStaff, ParentPortal).

✻ Crunched for 1m 5s

⏺ Agent "Fact Packs: P0 money modules" finished · 50m 23s

  Ran 4 shell commands

One FP-1 finding is a false positive — and it matters, because "fixing" it would break correct code.

  Ran 1 shell command

The migrations are centrally located (743 files at database/migrations/tenant/) — but one filename directly challenges DS-1's SP-1a claim. Checking.

  Ran 1 shell command

All three FP-1 headline claims checked. Two confirmed exactly, one is a false positive, and the check turned up a correction to DS-1.

FP-1 complete — Fact Packs (StudentProfile, StudentFee, Payment)

50 tables, 43 screens, all TENANT, 121 permission + 37 activity-log strings verbatim. All three packs exceeded the 25k cap so it used the prompt's own §4 split remedy — correct behaviour, and it flagged the extra filenames rather than quietly adding them.

Confirmed — Payment prefix DRIFT. Tables are ptm_payment_payments, ptm_payment_gateways, ptm_payment_refunds… The registry says pmt_ and the classification shard says unprefixed. Both inputs are wrong; anything built on either targets non-existent tables.

Confirmed — BUG-FIN-05, and the P0 escalation is justified. Migration 2026_07_09_000005 line 19 does $table->decimal('balance_amount', 12, 2)->default(0.00)->change() — a plain writable column — while the DDL declares it GENERATED ALWAYS AS (total_amount - paid_amount) STORED. FeeInvoice.php:160 maintains it in PHP and it's in $fillable, which independently proves the live column is not generated (MySQL rejects writes to STORED generated columns). So the invariant the DDL promises isn't enforced anywhere, and the balance can silently go stale.

False positive — finding 6, and this one matters. FP-1 read UNIQUE KEY uq_studentSessions_currentFlag (current_flag) as a single-column unique on a boolean, "permitting at most one row per flag value in the whole table." The actual column is:

`current_flag` INT GENERATED ALWAYS AS (CASE WHEN `is_current` = 1 THEN `student_id` ELSE NULL END) STORED

That's the partial-unique-index-via-generated-column idiom: NULLs don't collide, so the constraint enforces exactly "at most one current session per student." It's correct code, elegantly done. 15 DDL files use GENERATED ALWAYS AS — this is an established platform pattern (your AI Brain records it as D36), so any agent reading a UNIQUE on a *_flag column needs to check for a generated definition before calling it a defect. Acting on this finding would have broken working constraint logic.

Correction to DS-1's SP-1a

Checking FP-1 surfaced an error in the defect scan. DS-1 listed invoice_no among ten money-document columns with no UNIQUE index. But migration 2026_07_09_000006_add_unique_invoice_no_to_fee_invoices.php adds uq_fee_invoices_invoice_no — with a dedup pass first. invoice_no is indexed.

The rest of SP-1a holds firmly: create_fee_receipts_table.php, create_fee_transactions_table.php and create_fee_refunds_table.php all have zero unique calls, and no later migration retrofits them. So receipt_no, transaction_no and refund_no genuinely have no index against COUNT(*)+1 generators. DS-1's count of 10 needs re-verification, but the mechanism and the P0 severity stand.

A useful side-effect: this means BUG-FIN-35 ("invoice_no no UNIQUE") is resolved on disk — the third independent confirmation this run that the audit canon is stale. FP-1 found 9 prior P0s already fixed, FP-2 found 8 stale findings including 3 P0s, and now BUG-FIN-35. The 2026-06-29 audit reports should not be trusted as test input until re-verified — Stage A/B reading them would write tests asserting broken behaviour that no longer exists.

Also confirmed: 26 permanently-unresolvable gate strings, root-caused to config/permissionslist.php + PermissionSyncController emitting only scope.feature.action from a fixed 17-verb list — so review, reject, deposit, clear, bounce etc. can never be granted. Whole P0 screens are 403 for every non-super-admin: StudentFee's Fee Refund and Cheque/DD Reconciliation, StudentProfile's leave review. And all 8 Payment money columns are DECIMAL cast to 'float' in Eloquent, including the computed discrepancy — likely platform-wide.

Environment blocker, now confirmed by three agents: php artisan route:list aborts with Class "Sentry\Laravel\Integration" not found (app.php:74). Every route table in every Fact Pack is grep-derived. This breaks a self-check item in my prompt programme-wide, not per-module.

1 agent still running: FP-3 (SchoolSetup, HrStaff, ParentPortal).

✻ Sautéed for 1m 51s

⏺ Agent "Fact Packs: setup/HR modules" finished · 59m 10s

All 9 agents are complete. FP-3 reports a zero-auth endpoint that rewrites the permission table — verifying that before anything else.

  Ran 4 shell commands

Critical nuance found. Let me authorize FP-3's split and record the lesson.
Agent "ad76683db378d435e" had no active task; resumed from transcript in the background with your message. You'll be notified when it finishes. Output: /private/tmp/claude-502/-Users-bkwork-Herd-prime-ai/38b86dd0-531f-4e8b-929c-81fe7d1cf379/tasks/ad76683db378d435e.output

Now recording the middleware lesson in the prompts, since a grep-only route check produced a wrong severity.

⏺ Update(Prompts/New/ModuleFactPack.md)
Added 33 lines, removed 1 line

```bash
grep -rnE "Route::(get|post|put|patch|delete|resource|any)" $APP/routes/
cd /Users/bkwork/Herd/prime_ai && php artisan route:list --path=$P 2>/dev/null | head -80

# ⚠️ MANDATORY — middleware lives in the PROVIDER, not the route file (see the warning below)
grep -nA14 "mapWebRoutes\|mapApiRoutes\|mapTenantRoutes" $APP/app/Providers/RouteServiceProvider.php

# route:list is currently UNAVAILABLE in this checkout — see the note below. Try it, expect failure, log it.
cd /Users/bkwork/Herd/prime_ai && php artisan route:list --path=$P 2>&1 | head -20
```

Record name · verb · URI · controller@method · middleware. Hand-written URLs are banned downstream — this table is
what makes `route()` usage possible.

> ⚠️ **MIDDLEWARE TRAP — measured 2026-07-30, and it produced a wrong security severity before it was caught.**
> In this codebase, route middleware is applied in the module's `RouteServiceProvider`, **not** in the route file and
> **not** on the route line. `Modules/SchoolSetup/routes/web.php` is 489 lines with **zero** `Route::group` and
> **zero** `->middleware` — which reads as "these routes are unprotected" and is **false**. The provider wraps the
> whole file:
>
> ```php
> Route::middleware(['web', InitializeTenancyByDomain::class, PreventAccessFromCentralDomains::class,
>                    EnsureTenantIsActive::class, 'auth', 'verified'])
>      ->prefix('school-setup')->name('school-setup.')->group(module_path($this->name, '/routes/web.php'));
> ```
>
> **Therefore:** never state a route's auth, tenancy or role posture from the route file alone. Quote the provider's
> `mapWebRoutes`/`mapApiRoutes` stack in the pack, per surface. Note that `mapApiRoutes` frequently applies only
> `Route::middleware('api')` — so the **same module** can be tenancy-protected on web and unprotected on API. That
> asymmetry is a real defect class; record it per surface, never per module.
>
> **Consequence for "no authorisation" findings:** distinguish *unauthenticated* (no `auth` anywhere — anonymous
> access) from *authenticated-but-unauthorised* (`auth` present, no `Gate`/permission check — privilege escalation by
> any logged-in user). These are different severities and different fixes. Say which one you mean, with the evidence.

> ⚠️ **`php artisan route:list` does not run in this checkout** (measured 2026-07-30): every `artisan` command aborts
> with `Class "Sentry\Laravel\Integration" not found` at `bootstrap/app.php:74`. All route tables are therefore
> **file-derived**. State that in §5 and §11 of the pack — never present a grep-derived route table as
> registration-confirmed. Do **not** try to fix the boot error; it is an application change (§0.1). This is a
> standing Rule Card candidate via `A0.3`.

---

## 4. Output contract — `{Module}_Fact_Pack.md`

⏺ Update(Prompts/New/CrossReferenceDefectScan.md)
Added 1 line, removed 1 line
|---|---|---|---|---|
| **1** | **ENUM case/value** | M | DDL `ENUM(...)` ↔ validation `in:` ↔ blade `<option value>` ↔ any `where('status','...')` in code | value sets differ, including **case** (`'Active'
` vs `'active'`) |
| **2** | **Route registration** | S | Blade `route('x')`/`action=` ↔ registered routes | a blade references a route name/URI that is not registered |
| **3** | **Gate vs Policy** | S | `Gate::authorize('ability')` ↔ Policy method names ↔ `can:` middleware | ability has no Policy method, or the Policy method is unreachable |
| **3** | **Gate vs Policy** | S | `Gate::authorize('ability')` ↔ Policy method names ↔ `can:` middleware ↔ **the `RouteServiceProvider` stack** | ability has no Policy method, or the
Policy method is unreachable |
| **4** | **`$fillable` vs DDL** | M | Model `$fillable` ↔ DDL columns | fillable names a non-existent column, or a user-writable column is absent from fillable (silent drop on mass-as
sign) |
| **5** | **`$casts` vs DDL type** | M | Model `$casts` ↔ DDL type | `boolean` cast on `VARCHAR`, `decimal:2` missing on a money column, `date` cast on `DATETIME` losing time |
| **6** | **Service delegation** | M | Controller ↔ Service | a business rule exists in the Service but the controller bypasses it on one path (or the reverse) |

⏺ Update(Prompts/New/CrossReferenceDefectScan.md)
Added 21 lines
> **Checks 12–15 are the highest-yield four.** They compare the *schema* with the *validation layer* — two places
> nobody edits together — and each firing is a live production defect, not a code-quality opinion.

> ⚠️ **Two traps that produced wrong findings on the 2026-07-30 run. Both are mandatory reading before check 3 or 12.**
>
> **(a) Migrations are production truth; DDL files are not.** The DDL corpus and the migrations disagree routinely.
> Reading a DDL file alone produced **five phantom HIGHs** in one module (models with `SoftDeletes` against tables the
> DDL shows without `deleted_at` — the migrations add it), and separately caused a real ten-column UNIQUE gap to be
> recorded as "no defect" *citing the DDL*. **Always resolve a disagreement in favour of the migrations**, and check
> for a **later retrofit migration** before declaring a constraint missing — e.g. `invoice_no` looks unindexed in
> `create_fee_invoices_table` and is indexed by a separate `add_unique_invoice_no_to_fee_invoices` migration months
> later. Migrations for this app are centralised in `prime_ai/database/migrations/` (and `…/tenant/`), **not** under
> `Modules/{Module}/database/migrations/` — several modules ship none of their own.
>
> **(b) A UNIQUE on a `*_flag` column is usually correct, not a defect.** Check for a generated definition first:
> ```sql
> `current_flag` INT GENERATED ALWAYS AS (CASE WHEN `is_current` = 1 THEN `student_id` ELSE NULL END) STORED,
> UNIQUE KEY `uq_studentSessions_currentFlag` (`current_flag`),
> ```
> This is the partial-unique-index idiom: NULLs do not collide, so it enforces "at most one current row per student."
> Reading it as "a UNIQUE on a boolean allows only two rows" is a **false positive**, and acting on it would break
> working constraint logic. 15 DDL files in this estate use `GENERATED ALWAYS AS`; the platform records it as pattern
> **D36**. Never flag a UNIQUE without first printing the column's full definition.

### 3.1 Extraction commands

```bash

All 9 agents are complete. FP-3 is re-running two corrections I sent it.

FP-3 complete — Fact Packs (SchoolSetup, HrStaff, ParentPortal)

80 tables, 103 screens, all TENANT, 258 permission + 72 activity-log strings verbatim. HrStaff has a dual prefix (hrs_ + pay_). SchoolSetup's pack breached the 25k cap at 33,099 chars after six compression passes — it chose to breach and document rather than drop verbatim content, which was the right call; I've authorized the §4 split.

Confirmed — ppt_events doesn't exist. ParentPortal's Event model binds a table present only in a DDL explanation doc, never in migrations or actual DDL. Screen 7 will throw 42S02.

Confirmed — the estate's audit canon is stale, for the fourth independent time. ParentPortal's report has six security findings including P0 SEC-PPT-003 that no longer reproduce. Combined with FP-1 (9 resolved P0s), FP-2 (8 stale, 3 P0s), and BUG-FIN-35: the 2026-06-29 audit reports must be re-verified before any Stage A/B run reads them. This is now the single most consistent finding across the whole wave.

Two corrections I sent back

Severity was overstated on the zero-auth endpoint — and the reason is a trap worth institutionalising. FP-3 reported GET /sync-permissions (which rewrites the permission table) as having zero authorisation. I confirmed the controller has no Gate/permission check and the route line has no middleware — but routes/web.php is 489 lines with zero Route::group and zero ->middleware, because the entire file is wrapped in the provider:

Route::middleware(['web', InitializeTenancyByDomain::class, PreventAccessFromCentralDomains::class,
                   EnsureTenantIsActive::class, 'auth', 'verified'])->prefix('school-setup')

So the real finding is privilege escalation by any authenticated tenant user, not anonymous access. Still serious — a logged-in parent could rewrite the permission table — but a different severity and a different fix. Notably mapApiRoutes applies only Route::middleware('api'), which does support FP-3's separate no-tenancy API finding: the same module is protected on web and unprotected on API.

permissionslist.php claim was imprecise. FP-3 said the school-setup scope "exists nowhere." 'school-setup' => $crud is at line 125, inside the tenant scope — so tenant.school-setup.{verb} permissions are generated. Its 96-unresolvable-gate-strings finding may still hold (if controllers gate on school-setup.… as the scope), but the root cause is a scope-vs-feature naming mismatch, not a missing entry, and the fix differs. It's re-verifying with exact string pairs.

Prompt hardening from this wave

Four defects in prompts I wrote, all found by agents doing real work and now fixed:

┌────────────────────────────────────────────────────────────────┬──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                             Defect                             │                                                               Fix                                                                │
├────────────────────────────────────────────────────────────────┼──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ TC-[PND]-[0-9]+ regex missed ~93% of the estate's TC-IDs       │ Tolerant regexes + mandatory per-module calibration; "a count of 0 means your regex is wrong"                                    │
├────────────────────────────────────────────────────────────────┼──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ Fabricated example gave LmsExam prefix exm_ (real: lms_) and   │ Replaced with measured facts + the CODE ≠ PREFIX and ls-confirm-aliases traps                                                    │
│ propagated a stale Exam/ alias                                 │                                                                                                                                  │
├────────────────────────────────────────────────────────────────┼──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ Route middleware assumed to be in route files                  │ New mandatory RouteServiceProvider step; unauthenticated vs authenticated-but-unauthorised must be distinguished                 │
├────────────────────────────────────────────────────────────────┼──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ DDL treated as schema truth; UNIQUE-on-flag read as a defect   │ Migrations are truth (centralised at database/migraions/, check for retrofits); print a column's full definition before flagging │
│                                                                │  a UNIQUE — the D36 generated-column idiom is correct code                                                                       │
└────────────────────────────────────────────────────────────────┴──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘

Also unfixed by design, but recorded: my §4.1 verdict rules have no branch for "nothing in the estate is ever approved," which ET-1 hit and handled with a documented ruling.

Once FP-3's corrections land I'll merge the per-agent registers (_Identity_Register_FP-*, the 36 ET shards → three top-level registers, _DEV_Register_DS-1) and run ProgrammeRollups — which now has real inputs to roll up. Two things it should surface immediately: REUSE = 0 across 172 TcLists, and the parallel 492-file TcList_Require estate that sits outside every path the programme currently measures.

✻ Worked for 2m 18s

⏺ Agent "Fact Packs: setup/HR modules" finished · 1h 25m 0s

FP-3's correction reverses something I relayed to you. Verifying immediately.

  Ran 1 shell command

Confirmed — and I need to correct something I told you.

PermissionSyncController is properly gated. Line 26: if (!$user || !$user->hasRole('Super Admin')) { … 403 }. My "privilege escalation by any authenticated tenant user" relay was wrong. The cause of my error is instructive: I verified FP-3's claim with the grep Gate::authorize|authorize\(|->can\(|middleware — the same too-narrow pattern that generated it. Authorization in this codebase also appears as hasRole(), is_super_admin, and bare abort(403), so I confirmed an error instead of catching it. Checking for authorization outcomes (403 responses) rather than Gate APIs would have caught it.

What survives is one genuinely unguarded endpoint: Mobile/EmployeeAttendanceController — zero hits for Gate::, authorize, ->can(, hasRole, abort(403) or is_super_admin. A batched staff-attendance write behind only mobile.key + tenant.mobile + auth:sanctum.

FP-3 corrections landed

┌───────────────────────────────────┬─────────────────────────┬────────────────────────────────────────────────────────┐
│              Finding              │         Before          │                   After verification                   │
├───────────────────────────────────┼─────────────────────────┼────────────────────────────────────────────────────────┤
│ SchoolSetup pack size             │ 33,099 (over cap)       │ 24,993 ✅ + _Tables.md companion, zero fact loss       │
├───────────────────────────────────┼─────────────────────────┼────────────────────────────────────────────────────────┤
│ DEV-SCH-F04 zero-auth controllers │ 4                       │ 1 — three were gated by abort(403), Gate::any, hasRole │
├───────────────────────────────────┼─────────────────────────┼────────────────────────────────────────────────────────┤
│ DEV-SCH-F03 gate strings          │ 233 found, 96 uncreated │ 376 found, 251 created, 125 uncreated                  │
└───────────────────────────────────┴─────────────────────────┴────────────────────────────────────────────────────────┘

The count rose because its first pass matched only Gate::authorize( and ->can(, missing Gate::allows( (66 sites), Gate::denies( (23) and Gate::any( (21). The root cause is now precise: controllers gate on school-setup.teacher.viewAny while PermissionHelper::flatten() emits tenant.school-setup.viewAny from line 125 — a scope-vs-feature mismatch, not a missing entry. It also found 71 near-miss cases (prime.department vs declared tenant.department; tenant.org-group vs tenant.organization-group) that a coarser pass would have lumped together.

DEV-SCH-F01 confirmed and quoted: mapApiRoutes() line 62 applies only Route::middleware('api') — no tenancy — while routes/api.php puts apiResource('schoolsetups') behind auth:sanctum, whose token table lives in the tenant DB. Broken by construction.

FP-3 recorded four method notes for the Rule Card, each of which had caused a wrong finding in its first pass: resolve permissions through flatten() not a config grep; enumerate all Gate:: methods before counting; authorization is not always a Gate; route middleware lives in the provider. That's the most valuable artefact of the whole correction cycle.

Where this leaves the run

All 9 wave-1 agents are complete. Net: three modules' Fact Packs × 3 agents (12 modules, 184 tables, 219 screens), two estate triages (268 screens, 36 shards), a 4-check defect scan on the P0 money modules, static validation of 771 test files, a review pre-flight, and a selector-retrofit plan.

The four findings that should drive your next decisions:

1. REUSE = 0 across all 172 TcLists. Nothing in the estate is category-aware or signed off. Everything needs re-review or re-authoring.
2. DEV-301 — FeeReceipt::withTrashed() throws unconditionally inside the payment transaction; payer debited, nothing recorded. Its two sibling models have SoftDeletes, it doesn't.
3. The 2026-06-29 audit canon is stale in four independent checks — ~20 findings including several P0s are already fixed. Stage A/B reading it would assert vulnerabilities that no longer exist.
4. A parallel 492-file TcList estate sits under tests/, outside every path the programme measures — so the "556 TcLists" baseline is incomplete.

Wave 2 remains: merge the per-agent files into the three top-level estate registers plus the consolidated identity and DEV registers, then run ProgrammeRollups against them. Want me to launch that now?

✻ Worked for 2h 30m 19s

※ recap: All 9 agents finished executing the 7 new testing prompts; findings are written under 9-TestingStrategy. Wave 2 is left: merge the per-agent files into the top-level registers, then run ProgrammeRollups. Want me to launch that? (disable recaps in /config)

❯ Create a summary document in the the folder "/Users/bkwork/WorkFolder/3-Local_Workspace/9-TestingStrategy" for all the files you have generated into 10 folders. The Summary should have complete detail what you have generated in those Document, what is the use of those documents & how to use those documents in process of Generating TestCases which is my final goal.

Let me inventory exactly what's on disk before writing anything.

  Ran 2 shell commands

Complete inventory in hand: 165 files, ~2.05 MB across 9 populated folders (09-Rollups is empty — not yet run). Writing the summary.

⏺ Write(_WORKSPACE_SUMMARY_2026-07-30.md)
Wrote 461 lines to _WORKSPACE_SUMMARY_2026-07-30.md
# Testing Strategy Workspace — What Exists, What It Is For, How To Use It

> **Written:** 2026-07-30 · **Covers:** every file under `/Users/bkwork/WorkFolder/3-Local_Workspace/9-TestingStrategy`
> **Your goal:** generate accurate test cases for the Prime-AI application.
> **This document's job:** tell you exactly what each of the 165 generated files is, why it exists, and where it
> plugs into the test-case generation pipeline — so nothing here is a mystery artefact.
>
> **Read §3 first** (the pipeline), then **§5** (the per-screen walkthrough — that is the actual "how do I generate a
> test case" procedure). §6 lists what is currently **blocking** generation. §7 lists documents that contain **known
> errors** — read it before trusting any single finding.
… +478 lines

  Ran 1 shell command

⏺ Update(_WORKSPACE_SUMMARY_2026-07-30.md)
Added 1 line, removed 1 line
| `_DEV_Register.md`, `_Run_Log.md` | Defects + audit trail | — |

> ⛔ **This is the programme's critical path.** No archetype has a finished `A{n}_Definition.md`, obligations digest,
> idiom digest or review rubble. **A1, A5, A6, A8, A9 have zero kit artefacts at all** — and those archetypes own most
> idiom digest or review rubric. **A1, A5, A6, A8, A9 have zero kit artefacts at all** — and those archetypes own most
> of the existing TcLists. Until at least one kit is finished, Stage A has no FORBIDDEN list and the review gate in
> folder 06 cannot issue a real batch.
>

Created _WORKSPACE_SUMMARY_2026-07-30.md (35.6 KB) at the root of 9-TestingStrategy/. File counts and sizes in it were taken from a disk inventory, not from the agents' self-reports — 165 files, ~2.05 MB across the 10 folders.

How the document is organised

It's built to be used, not just read, so it's ordered by what you'd need in sequence:

┌──────┬────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│  §   │                                                                                Contents                                                                                │
├──────┼────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ 1    │ At-a-glance table: all 10 folders, what each holds, files, size, state                                                                                                 │
├──────┼────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ 2    │ The one-paragraph version of why these folders exist                                                                                                                   │
├──────┼────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ 3    │ The pipeline — ASCII diagram of which folder feeds which stage, plus the 5 hard prerequisites                                                                          │
├──────┼────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ 4    │ Folder-by-folder detail — every file group, its contents, and how you use it                                                                                           │
├──────┼────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ 5    │ The per-screen walkthrough — an 11-step table taking one screen (Fee Collection) from register lookup to executed coverage, naming the exact file to read at each step │
├──────┼────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ 6    │ The 7 things currently blocking generation, each with what unblocks it                                                                                                 │
├──────┼────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ 7    │ Documents containing known errors                                                                                                                                      │
├──────┼────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ 8    │ Two facts that change the programme's baseline                                                                                                                         │
├──────┼────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ 9    │ Recommended order of next actions                                                                                                                                      │
├──────┼────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ App. │ Every prompt → the folder it owns, plus the universal sandbox contract                                                                                                 │
└──────┴────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘

§5 is the section that answers your actual goal directly — for each step it names the file, what to extract, and why it matters (e.g. step 2 pulls the tenancy verdict from the Fact Pack because that decides whether the test file emits tenancy scaffolding at all; get it wrong and every test in the module fails for an unrelated reason).

Two things I made sure the document does not do

It doesn't present this workspace as ready to generate test cases. §6 is explicit that four blockers stand in the way: no finished Category Kit (so Stage A still has no FORBIDDEN list — the original over-generation problem is not yet fixed), canon patches unapplied (so the kits would be inert even once built), no test environment, and artisan unbootable. The highest-leverage action remains you red-lining A2_Gold_TcList_DRAFT.md.

It doesn't present every finding as trustworthy. §7 is a "do not inherit these" table covering the six errors caught by cross-checking agents against disk — including the invoice_no over-claim, the current_flag false positive (correct code that would have been "fixed"), the /sync-permissions severity I relayed wrongly to you before correcting it, and the rule that migrations, not DDL files, are schema truth. It also flags that the 2026-06-29 audit reports are stale in four independent checks — that one is an input to your pipeline, and Stage A reading it would write tests asserting vulnerabilities that no longer exist.

§8 records the two baseline problems worth deciding on early: the parallel 492-file TcList_Require estate sitting outside every path the programme measures, and MarksheetGeneration's 602 test methods in a non-canonical directory.

Folder 09 is documented as deliberately empty with its blockers listed, rather than quietly omitted.

✻ Cooked for 4m 12s

※ recap: You wanted accurate test cases for Prime-AI; I wrote 7 new pipeline prompts, ran 9 agents producing 165 files across 10 folders, and just added a workspace summary. Next: red-line A2_Gold_TcList_DRAFT.md, which unblocks everything downstream. (disable recaps in /config)

❯ you have created classification only for 12 Modules in folder "/Users/bkwork/WorkFolder/3-Local_Workspace/9-TestingStrategy/01-Classification" but I need that classification for all the Module. How should I create Testcases for other Module without that information?

You're right — 12 modules was the frozen release scope from the earlier wave, not full coverage. Let me establish exactly what's missing.

  Ran 3 shell commands

47 modules exist on disk; 12 are classified. 35 modules and ~506 controllers are missing — roughly double the work already done.

You're correct that this blocks you: the register row is step 1 of the whole pipeline. Without an archetype you can't select a scope contract, and without a tier you don't know whether a screen's coverage belongs at Unit, Feature or Dusk. Generating test cases for those 35 modules today would mean guessing both. Launching 8 agents to close it.

⏺ 8 background agents launched (↓ to manage)
Classify Hostel, Library
Classify StudentPortal, Transport, Complaint
Classify Dashboard, Inventory, Prime
Classify FrontOffice, Accounting, SmartTimetable
Classify GlobalMaster, Cafeteria, Syllabus, CommonChat
Classify Hpc, BehaviouralAssessment, SyllabusBooks, Ptm, Recommendation
Classify Feedback, Certificate, SystemConfig, Vendor, QuestionBank, Billing
Classify remaining 9 small modules

⏺ API Error: 500 Internal server error. This is a server-side issue, usually temporary — try again in a moment. If it persists, check https://status.claude.com.

✻ Sautéed for 3m 6s

⏺ Agent "Classify Hostel, Library" finished · 21m 24s

  Ran 3 shell commands

Verified — row counts exact (55 + 42), and both flagged defects are real.

A01-5 complete — Hostel + Library (97 screens)

Archetype spread: A2 45 · A1 22 · A6 17 · A8 16 · A7 9 · A5 3 · A3 2 · A11 1. All 97 rows are R3 (both tenant-side), 13 carry R1 (money), ~58 carry R4 (PII). Tier: P0 9 · P2 ~66 · P3 ~22. Zero NO-CODE, zero DEAD — all 95 controllers are routed.

Two confirmed defects worth your attention:

- A live REST API that silently discards writes. Route::apiResource('libraries', LibraryController::class) is registered at api.php:7, and LibraryController::store(), update(), destroy() are literally empty bodies at lines 988, 1009, 1014. Callers get a success response and nothing happens.
- A 5-table save with no atomicity. LibBookMasterController has 3 rollBack() calls but only 2 beginTransaction() — the one at line 291 has no open transaction (the first beginTransaction is at 361, after it). On failure, partial writes persist.

Also: a stub no-op approve()/reject() in Hostel's Leave Approvals that shows a false success toast, and dead routes pointing at commented-out methods.

One decision needed, because it will recur in the 7 running agents

Ambiguity came in at 21.6%, over the 10% guideline — but not from shallow greps. Two structural questions account for most of it, and the second has now appeared in three modules across two passes (HrStaff's HrMenuController, Hostel's HostelSetupController, Library's LibraryController):

Does a pure tab-aggregation hub controller get its own register row? It renders a shell and delegates every tab to another controller. It has no CRUD of its own, but it is the URL the user visits.

My recommendation: no row for the hub. Each tab already has its own Requirement doc and gets its own row; the hub is a container, and giving it an archetype would invent CRUD test cases for a screen that writes nothing — exactly the phantom-test failure mode this taxonomy exists to prevent. The tab-switching behaviour is real, so capture it as one modifier on the module's first tab row (or one Dusk journey), not as a screen.

The other pattern — status FK columns with no matching named transition method (7 rows) — is a genuine A6-vs-A2 boundary case. I'd default those to A2 with a status note, not A6: A6 requires actual transition methods, and inferring a workflow from a column alone would generate state-machine tests against transitions that don't exist.

If you agree, I'll apply both rulings consistently when I roll the shards up, and the ~21 escalated rows across these two modules mostly resolve. If you'd rather rule differently, say so — it's a taxonomy call with a wide blast radius.

One item genuinely needs you: Library has 3 Requirement docs with existing TcLists (Acquisition_Report, Digital_Resource_Report, Overdue_Report) but no controller or route the agent could find. Either the code lives somewhere unexpected or those are documented-but-unbuilt features.

7 agents still running: StudentPortal/Transport/Complaint · Dashboard/Inventory/Prime · FrontOffice/Accounting/SmartTimetable · GlobalMaster/Cafeteria/Syllabus/CommonChat · Hpc/BehaviouralAssessment/SyllabusBooks/Ptm/Recommendation · Feedback/Certificate/SystemConfig/Vendor/QuestionBank/Billing · and the 9 small modules.

✻ Brewed for 59s

⏺ Agent "Classify remaining 9 small modules" finished · 23m 29s

A01-12 confirms SEC-MNT-001 is still active. Given its severity — any authenticated user overwriting any tenant's database — I'm verifying every limb myself.

  Ran 3 shell commands

⏺ Agent "Classify StudentPortal, Transport, Complaint" finished · 25m 32s

Both verified. One reverses a known finding; the other is the most severe finding of the session.

  Ran 2 shell commands

Both confirmed. My earlier doubt about the auth layer is resolved — web.php:6 does wrap the routes in ['auth','verified'], so A01-12's description was accurate.

🔴 SEC-MNT-001 — confirmed active, and worse than reported

Every limb verified independently:

┌──────────────────────────────────────────────────────────┬────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                          Claim                           │                                                  Verified                                                  │
├──────────────────────────────────────────────────────────┼────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ RestoreController.php (133 lines) has zero authorization │ ✅ 0 hits across Gate::authorize/allows/denies/any, ->can(, authorize(, hasRole, is_super_admin, abort(403 │
├──────────────────────────────────────────────────────────┼────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ RestoreBackupRequest::authorize() returns true           │ ✅ verbatim                                                                                                │
├──────────────────────────────────────────────────────────┼────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ Route requires only ['auth','verified']                  │ ✅ routes/web.php:6                                                                                        │
├──────────────────────────────────────────────────────────┼────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ Sibling BackupController does authorize                  │ ✅ 5 Gate::authorize calls — omission, not design                                                          │
└──────────────────────────────────────────────────────────┴────────────────────────────────────────────────────────────────────────────────────────────────────────────┘

The part the agent didn't emphasise, and it raises the severity: the restore target comes from user input. restore() reads target_connection from the request; if it starts with tenant:, it takes the remainder as a tenant UUID and builds that tenant's database name. So the attacker chooses which tenant to overwrite.

Net: any authenticated, verified user of any tenant can overwrite any other tenant's database via POST /maintenance/backup/{run}/restore. Not anonymous — but a parent or student account is sufficient, and it's a cross-tenant destructive write with no ownership check anywhere in the path. This is the most severe finding of the session and I'd treat it as the top item, above DEV-301.

A01-12 complete — 9 small modules (39 screens)

R7 judgement handled well: Scheduler, EventEngine, Documentation and TenantCore were each evaluated for exclusion and none qualified — none matches the five program-level categories. They got real rows; 4 controllers were excluded separately as dead scaffolding under R6, which is the correct distinction.

Other findings: EventEngine's 3 core tables have zero migrations anywhere (likely explains its "On Hold" status); TenantCore\ActivityLog confirmed as sys_activity_logs, corroborating the Rule Card E25 error; and LmsHomework's REVIEW_FOLDER is stale (Homework vs real LmsHomework) — the same bug FP-2 found on LmsExam independently, so it's systemic across the Lms* registry rows.

A01-6 complete — StudentPortal, Transport, Complaint (120 screens, 0% ambiguous)

SEC-STP-014 is CLEARED, and the agent got there by applying the middleware lesson correctly. Modules/StudentPortal/routes/mobile_api.php is required from the central routes/api.php:30, nested inside Route::middleware('role:Student|Parent')->group(...) at line 29. The guard exists one layer above the module — invisible to anyone grepping the module's own files or its RouteServiceProvider. A prior finding retired on evidence.

Confirmed defect, slightly broader than reported: Transport\FeeMasterController::store() writes TptFeeMaster + StudentPayLog with no transaction — and update() has the same gap. Meanwhile destroy(), restore() and forceDelete() are wrapped. Transactions are used correctly on the delete paths and omitted on the write paths.

A pattern now worth a platform ruling: "documented but functionally inert" controllers — full Requirement doc, TcList and Dusk folder, but store/update/destroy are no-ops. Four instances across three modules in this one pass (Complaint ×2, StudentPortal, Transport), plus Library's empty apiResource from A01-5. Generating test cases against these would produce tests that pass while proving nothing. They need flagging as NO-BEHAVIOUR in the register so Stage A skips them rather than writing CRUD assertions against empty method bodies.

Progress

26 of 47 modules classified · 522 screens. 5 agents still running (21 modules): Dashboard/Inventory/Prime · FrontOffice/Accounting/SmartTimetable · GlobalMaster/Cafeteria/Syllabus/CommonChat · Hpc/BehaviouralAssessment/SyllabusBooks/Ptm/Recommendation · Feedback/Certificate/SystemConfig/Vendor/QuestionBank/Billing.

The two taxonomy rulings I raised earlier (tab-hub controllers, status-without-transitions) are still open and now compound with a third (NO-BEHAVIOUR scaffolds). I'll apply my recommendations consistently at roll-up unless you rule otherwise.

✻ Worked for 1m 11s

⏺ Agent "Classify FrontOffice, Accounting, SmartTimetable" finished · 27m 1s

  Ran 1 shell command

⏺ Agent "Classify Hpc, BehaviouralAssessment, SyllabusBooks, Ptm, Recommendation" finished · 26m 55s

My verification of A01-8's dead-code claim was broken (my loop returned 1 of 32 — the pattern was wrong). Redoing it properly, plus checking A01-10's zero-migration finding.

  Ran 1 shell command

My check was also flawed — generic names like index match routes belonging to the module's other 17 controllers. Doing the controller-scoped check.

  Ran 2 shell commands

Decisive: SmartTimetableController is routed only via Route::resource (web.php:47) and Route::apiResource (api.php:8) — which route 7 methods implicitly. 32 − 7 = 25 unrouted. A01-8 was exactly right, and both my earlier checks were wrong. That's a lesson worth capturing.

  Ran 2 shell commands

Confirmed — 6 hpc_ tables (A01-10 said 5) have zero migrations. Recording the resource-routing lesson, since it silently corrupts dead-code detection estate-wide.

⏺ Update(Prompts/ScreenClassificationRegister.md)
File not found

  Read 1 file, listed 1 directory
Interrupted · What should Claude do instead?

❯ I have moved prompt (ScreenClassificationRegister.md) into folder "/Users/bkwork/WorkFolder/3-Local_Workspace/9-TestingStrategy/Prompts/Executed"

Thanks — I found it there. Making the edit.

⏺ Update(Prompts/Executed/ScreenClassificationRegister.md)
Added 32 lines, removed 1 line
grep -rnE "Route::(get|post|put|patch|delete|resource|any)" /Users/bkwork/Herd/prime_ai/Modules/$M/routes/
```

> ⚠️ **`Route::resource` routes methods IMPLICITLY — a method-name grep cannot see them.** Measured 2026-07-30:
> `SmartTimetableController` (32 methods, 153,494 chars) appears in its route files **only** as
> `Route::resource('smart-timetable-management', SmartTimetableController::class)` and
> `Route::apiResource('smarttimetables', SmartTimetableController::class)`. **No method name appears in the route file
> at all.** A naive `grep 'methodName' routes/` therefore returns either **zero** routed methods (concluding the whole
> controller is dead) or **false positives** — generic names like `index`/`store`/`update` match route entries
> belonging to the module's *other* controllers. Both wrong answers were produced before the correct one.
>
> **Correct procedure for the `DEAD?` / unrouted determination:**
> ```bash
> # 1. Is this controller resource-routed? If so, these are routed IMPLICITLY:
> #    Route::resource    → index, create, store, show, edit, update, destroy   (7)
> #    Route::apiResource → index, store, show, update, destroy                 (5)
> grep -rnE "Route::(api)?resource\([^,]+, *\{Controller\}::class" $APP/routes/
>
> # 2. Then the explicitly-routed methods, CONTROLLER-SCOPED (never a bare method-name grep):
> grep -rhoE "\{Controller\}::class, *'[a-zA-Z0-9_]+'" $APP/routes/ \
>   | grep -oE "'[a-zA-Z0-9_]+'$" | tr -d "'" | sort -u
> ```
> `unrouted = all methods − (implicit resource set ∪ explicit set)`. On the example above that is **25 of 32
> unrouted** — dead code *inside a live controller* (an incomplete refactor), which is a different finding from a dead
> controller. Give the screen a row for its **routed** surface only, and raise the dead methods as a DEV candidate.

**Reconcile the three lists.** One row per screen where "screen" = one user-facing surface (usually one controller,
but a controller with independent tabs that each have their own Requirement doc yields one row per tab).

Record the reconciliation outcome per row in `Source of row`: `CTRL+REQ+ROUTE` (ideal) · `CTRL+ROUTE` (no
requirement doc — flag it) · `REQ only` (⚠️ requirement with no code — flag as `NO-CODE`, do **not** classify) ·
`CTRL only` (unrouted — flag as `DEAD?`).
`CTRL only` (unrouted — flag as `DEAD?`, and only after the resource-route check above).

> **A fourth outcome, added 2026-07-30 — `NO-BEHAVIOUR`.** Some controllers are fully documented (Requirement doc +
> TcList + Dusk folder) and routed, but their `store`/`update`/`destroy` bodies are **literally empty** — e.g.
> `Library\LibraryController::store()/update()/destroy()` at lines 988/1009/1014, live behind
> `Route::apiResource('libraries', …)`. Six instances were found across four modules in one pass (Library, Complaint
> ×2, StudentPortal, Transport). **Flag these `NO-BEHAVIOUR` in the register.** Generating CRUD test cases against an
> empty method body produces tests that pass while proving nothing — the exact failure mode this programme exists to
> remove. Raise each as a DEV candidate; do not classify it as a working CRUD screen.

---

## 4. Signal extraction — shell only (≈0 tokens)

Prompt updated at the Executed/ path. Two more agents landed while I was verifying.

A01-8 complete — FrontOffice, Accounting, SmartTimetable (75 screens, 0% ambiguous)

Its dead-code finding is exactly right, and I got it wrong twice before confirming it. SmartTimetableController (153,494 chars, 32 methods) is routed only through Route::resource and Route::apiResource — which route 7 methods implicitly and put no method name in the route file at all. So 25 of 32 methods are unrouted: duplicated logic that lives and actually runs in 5 other specialised controllers. An incomplete refactor.

My first check said "1 routed", my second said "25 routed" — inverted. Both were artefacts of grepping method names against route files. I've written the correct procedure into the A0.1 prompt, because this silently corrupts DEAD? detection for every resource-routed controller in the estate.

Confirmed NO-CODE: acc_PaymentRequest_TcList.md exists with a Requirement doc, and there are zero matching files in Modules/Accounting. A TcList for a feature that was never built.

Accounting is the money module as expected: all 23 P0 rows and all 26 R1 overlays are Accounting's. It escalated Voucher and Expense Claim as genuinely dual-natured (A3 header+lines and A6 approval workflow on the same entity) rather than forcing one — the right call, since the §5 step order would pick A6 while the entity's save shape is A3.

A01-10 complete — Hpc, BehaviouralAssessment, SyllabusBooks, Ptm, Recommendation (69 screens, 0% ambiguous)

Confirmed, and broader than reported: 6 hpc_ tables referenced by live models have zero migrations anywhere — hpc_parent_form_tokens, hpc_peer_assignments, hpc_peer_responses, hpc_report_files, hpc_student_form_submissions, hpc_student_snapshot (it reported 5). Combined with SyllabusBooks (1 table) and EventEngine (3 tables from A01-12), that's a "live controller, zero-migration table" pattern in 3 of the last 19 modules. Any test touching those screens will fail on a missing table, not a logic error.

Two signs the hardening is working:
- It honoured the Hpc read discipline — HpcController.php (121.9k) and the confirmed largest blade in the estate (fourth_pdf.blade.php, 350,018 chars) were never full-read, only method-indexed with two targeted offset reads.
- It correctly did not flag the D36 generated-column pattern in ptm_slot_bookings. That lesson came out of FP-1's false positive earlier today and propagated successfully.

A useful independent validation: the Recommendation shard's mechanically-derived archetype split matched the existing gold Dusk test tree's own folder structure exactly. That's the calibration module, so the methodology agreeing with a human-built structure is meaningful evidence the classification is sound.

Progress

34 of 47 modules · 666 screens classified. 3 agents still running: Dashboard/Inventory/Prime · GlobalMaster/Cafeteria/Syllabus/CommonChat · Feedback/Certificate/SystemConfig/Vendor/QuestionBank/Billing.

Cost note worth flagging: A01-8 spent ~950k tokens against a ~750k budget, A01-10 ~410k. The overruns went into genuine forensics (the dual-archetype investigation, the 153k dead-controller analysis) rather than waste, but at this rate the full 47-module classification will land well above the token-cost document's estimate. Worth recalibrating that estimate with these measured figures once the last three land.

Three taxonomy rulings remain open for you: tab-hub controllers, status-without-transitions, and now NO-BEHAVIOUR scaffolds (I've added the third to the prompt as a register outcome, since six instances across four modules make it a recurring class rather than a judgement call).

✻ Cogitated for 13s

⏺ Agent "Classify Dashboard, Inventory, Prime" finished · 32m 52s

  Ran 1 shell command

Verified — and one finding is nearly double what was reported.

A01-7 complete — Dashboard, Inventory, Prime (75 screens, 0% ambiguous)

The highest-risk call in this pass was made correctly. Prime is confirmed central/prime-side: its RouteServiceProvider has zero tenancy middleware (applies only Route::middleware('web')), and routes/web.php:18 wraps everything in Route::domain(config('app.domain'))->name("central."). So R3 = 0 for all 24 Prime rows is right. Had this gone the other way, every generated Prime test would have emitted tenancy scaffolding and failed for a reason unrelated to the feature.

Dashboard's phantom-table finding is real and larger than reported. A01-7 found 9 safeCount() calls against non-existent tables; I found 17 distinct table names in safeCount() with no migration anywhere. And the cause is visible in the names:

┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┬─────────────────────────────────────────────┐
│                                                     Dashboard queries                                                     │                Actual table                 │
├───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┼─────────────────────────────────────────────┤
│ fin_fee_invoices, fin_fee_receipts, fin_fee_structure_masters                                                             │ fee_invoices, fee_receipts, … (fee_ prefix) │
├───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┼─────────────────────────────────────────────┤
│ msg_marksheet_schedules                                                                                                   │ msh_* prefix                                │
├───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┼─────────────────────────────────────────────┤
│ fof_enquiries, fof_call_logs, fof_postal_registers, fof_lost_found_items                                                  │ FrontOffice tables under a different prefix │
├───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┼─────────────────────────────────────────────┤
│ tpt_routes, tpt_vehicles, adm_cycles, beh_assessments, lms_homeworks, rec_recommendations, sch_room_types, slb_syllabuses │ —                                           │
└───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┴─────────────────────────────────────────────┘

These are prefix-drift guesses. safeCount() swallows the error, so every affected KPI tile has silently displayed 0 forever. This matters directly for your goal: you cannot write a meaningful accuracy assertion for a Dashboard tile whose source table doesn't exist — and a naive generator would produce a test asserting 0 == 0 and call it passing coverage.

Combined with the other finding — 9 of 26 Dashboard controllers render 100% hardcoded dummy data — a large share of the Dashboard module is untestable for numeric accuracy by construction. It should be classified A7/A8 (it was, correctly: all 26 rows) and its tiles marked as unverifiable until the data paths are real.

Inventory required a technique worth noting: business logic lives in Service classes, so DB::transaction had to be traced there, not in controllers. A controller-only grep would have under-counted A3 and A6 — the agent caught this itself. It found 7 disabled cross-module FK constraints and 2 services (Quotation, PurchaseRequisition) with unwrapped multi-table writes.

Also: an FK declared against a database VIEW, which InnoDB cannot enforce — so the referential integrity that a BC-REF test would assert doesn't exist at the database level.

Progress

37 of 47 modules · 741 screens classified. 2 agents still running: GlobalMaster/Cafeteria/Syllabus/CommonChat and Feedback/Certificate/SystemConfig/Vendor/QuestionBank/Billing.

A pattern is now unmistakable across the last five agents: tables referenced by live code that have no migration at all — Hpc 6, EventEngine 3, SyllabusBooks 1, Dashboard 17. That's ~27 phantom tables. Any test case generated against those screens fails on a missing table rather than on logic, so this needs to be a first-class register flag alongside NO-CODE and NO-BEHAVIOUR, and it belongs in the Fact Pack's §11 "facts not established" for every affected module.

✻ Cogitated for 44s

⏺ Agent "Classify GlobalMaster, Cafeteria, Syllabus, CommonChat" finished · 35m 47s

  Ran 1 shell command

Both verified. GlobalMaster central scope is correct (7 models on global_master_mysql, 12 refs in root routes/web.php under Route::domain(...)->name("central.") at line 78). And the step-1 misfire is real — I found 3 controllers that write data but have no store/update/destroy method.

This is the most consequential defect found in the taxonomy itself, so I'm fixing it.

  Read 1 file

⏺ Update(Prompts/Executed/ScreenClassificationRegister.md)
Added 2 lines, removed 1 line
## 5. Decision procedure — AXIS 1 (run in order, STOP at first match)

```
 1. Controller has no store/update/destroy?
 1. Controller performs NO PERSISTENCE OF ANY KIND?          ← see the STEP-1 WARNING below
      (no write call in the controller AND none in its Service/Action)
      → charts / aggregate SQL / export present?   → A8  Report / Analytics
      → otherwise                                  → A7  Read-only List / Monitor
 2. Content is markup/code in an editor?           → A12 Content / Template Designer

⏺ Update(Prompts/Executed/ScreenClassificationRegister.md)
Added 28 lines
11. Single table, no outbound business FK?         → A1  Simple Master / Lookup
```

> 🔴 **STEP-1 WARNING — the highest-consequence trap in this procedure. Added 2026-07-30 after 5 real misfires.**
>
> Step 1 used to read *"Controller has no `store`/`update`/`destroy`?"* — a **method-name** test. That is wrong,
> because many controllers in this codebase persist data under different method names: `saveAllocation()`,
> `assignMeal()`, `publish()`, `markAttendance()`, `syncTopics()`, and so on. Measured 2026-07-30, at least 3
> controllers in GlobalMaster/Cafeteria/Syllabus/CommonChat alone write data while having **no** `store`, `update` or
> `destroy` method — and the old step 1 would classify every one of them **A7 Read-only**.
>
> **Why this is worse than the over-generation problem.** A write screen misclassified as read-only gets:
> no duplicate-rejection tests, no missing-value tests, no over-length tests, no FK/cascade tests — **zero coverage of
> the write path** — and it then *looks finished*. Over-generation produces noise a reviewer deletes; this produces
> silent, invisible under-coverage on a screen that mutates data. Do not let step 1 fire on method names.
>
> **The correct step-1 test — persistence anywhere in the screen's stack:**
> ```bash
> # Writes in the controller itself
> grep -nE "::create\(|::updateOrCreate\(|::insert\(|->update\(|->save\(|->delete\(|->forceDelete\(|" \
>          -e "->sync\(|->attach\(|->detach\(|DB::table\([^)]*\)->(insert|update|delete)" $C
>
> # Writes delegated to a Service/Action — a controller-only grep UNDER-COUNTS A3/A5/A6
> grep -oE "[A-Z][A-Za-z]*(Service|Action)" $C | sort -u   # then grep the same write patterns in each
> ```
> Step 1 fires **only** when both come back empty. If either finds a write, skip to step 2 and continue the procedure —
> the screen is a write screen whatever its methods are called.
>
> **Corollary for A11 (step 3):** "only index + update/save" likewise means *only one persistence path*, not literally
> a method named `update` or `save`.

**Ordering traps to respect:**

- **A7 wins over everything** when there is no `store`/`update`/`destroy`. 221 of 750 controllers (29%) are read-only,

A01-9 complete — GlobalMaster, Cafeteria, Syllabus, CommonChat (68 screens)

Second high-risk scope call, also correct. GlobalMaster is central/prime-side: 7 of 8 models use $connection = 'global_master_mysql', and 12 GlobalMaster references sit in the root routes/web.php under Route::domain(config('app.domain'))->name("central.") at line 78 — not in the module's own route file. R3 correctly withheld on every row.

It also declined to inherit my warning uncritically, which is exactly right: I'd told it the registry's REVIEW_FOLDER aliases are stale, citing LmsExam→Exam. It checked Dropdown with ls first and found it valid. It also refined a Rule Card fact — glb_languages is a real table centrally and a VIEW only inside each tenant schema, so the blanket "it's a VIEW" rule is scope-dependent.

Other confirmed findings: 2 dead GlobalMaster controllers shadowed by same-named classes in SchoolSetup/Prime (proved by app-wide grep, not assumed); Cafeteria carries a real A3 money pattern (MealCardService with DB::transaction + lockForUpdate) so it applied R1 on evidence even though the taxonomy's named money-module list omits Cafeteria; and the SyllabusController (84.8k chars, ~1900 lines) was never full-read.

It also caught and fixed its own arithmetic errors before finalising, and amended two AMBIGUOUS files that under-listed their own rows.

🔴 A defect in the taxonomy itself — now fixed

A01-9 flagged that decision-procedure step 1 misfires, five times across its four modules. I verified it: at least 3 controllers write data (::create(, ->update(, ->save() while having no store/update/destroy method.

Step 1 asked "Controller has no store/update/destroy?" — a method-name test. Controllers here persist under names like saveAllocation(), assignMeal(), publish(), markAttendance(), syncTopics(). Every one of those would have been classified A7 Read-only.

This is worse than the over-generation problem you started with. A write screen called read-only gets no duplicate-rejection, no missing-value, no over-length, no FK/cascade tests — zero write-path coverage — and then looks finished. Over-generation produces noise a reviewer deletes; this produces invisible under-coverage on a screen that mutates data.

Step 1 now tests for persistence anywhere in the screen's stack, including Services and Actions (A01-7 hit the same issue from the other direction in Inventory, where transactions live in Services). The A11 corollary is fixed too.

This affects rows already produced. The 37 classified modules were done under the old step 1, so any screen marked A7/A8 whose controller or service actually writes is suspect. That's a cheap, mechanical pass-2 sweep — grep every A7/A8 row's controller and service for write calls — and it should run before Stage A trusts any read-only classification.

Progress

41 of 47 modules · 809 screens. One agent still running (Feedback, Certificate, SystemConfig, Vendor, QuestionBank, Billing).

Open for you: the three taxonomy rulings (tab-hub rows, status-without-transitions, and I've now added NO-BEHAVIOUR + the step-1 fix to the prompt directly), plus whether to run the A7/A8 re-verification sweep I just described.

✻ Cooked for 1m 19s

⏺ Agent "Classify Feedback, Certificate, SystemConfig, Vendor, QuestionBank, Billing" finished · 38m 0s

All 8 agents complete — 47 of 47 modules. Verifying the final state and the Vendor PII reversal.

  Ran 2 shell commands

Confirmed: gst_number (line 25) and upi_id (line 31) are in $fillable only — not in $casts — while pan_number, bank_account_no and bank_ifsc_code are cast to SafeEncrypted. A01-11's finding is exactly right: the PII fix landed partially.

Classification is complete — 47 of 47 modules, 872 screen rows

┌────────────────────┬────────┬─────┐
│                    │ Before │ Now │
├────────────────────┼────────┼─────┤
│ Modules classified │     12 │  47 │
├────────────────────┼────────┼─────┤
│ Screen rows        │    266 │ 872 │
├────────────────────┼────────┼─────┤
│ Shards on disk     │     12 │  47 │
└────────────────────┴────────┴─────┘

Your question — "how should I create test cases for other modules without that information?" — is now answered: you have it. Every module has an archetype, modifiers, overlays, tier and evidence per screen.

What the eight agents found beyond classification

Three scope determinations that would each have broken every test in their module. Prime, GlobalMaster and Billing are all central/prime-side, verified independently (no tenancy middleware, Route::domain(...)->name("central."), $connection = 'global_master_mysql', migrations in the central root). R3 correctly withheld on all 55 of those rows — so no tenancy scaffolding will be emitted for them.

A large phantom-table population. Tables referenced by live code with no migration anywhere: Dashboard 17, Hpc 6, EventEngine 3, SyllabusBooks 1 — and the Dashboard ones are visible prefix-drift guesses (fin_fee_invoices vs real fee_invoices, msg_* vs real msh_*). safeCount() swallows the error, so those KPI tiles have shown 0 forever.

Six NO-BEHAVIOUR scaffolds — fully documented and routed controllers whose store/update/destroy bodies are literally empty, including Library\LibraryController behind a live apiResource. Plus one NO-CODE (acc_PaymentRequest has a Requirement doc and TcList, zero implementation).

Real integrity defects: LibBookMasterController with 3 rollBack() calls but 2 beginTransaction() on a 5-table save; Transport\FeeMasterController::store() and update() unwrapped while destroy/restore/forceDelete are wrapped; 25 of 32 methods dead inside a 153k-char SmartTimetableController; an FK declared against a database VIEW.

Two prior findings retired on evidence — SEC-STP-014 (the mobile role guard exists one layer up in the central routes/api.php) and Vendor's PII (3 of 5 fields now encrypted). One confirmed and escalated: SEC-MNT-001, where the restore target comes from user input, making it a cross-tenant destructive write available to any authenticated account.

Correcting my own cost claim

I said earlier this would "land well above the token-cost document's estimate." That was wrong. The 35 modules cost ~2.76M tokens for 606 screens ≈ 4.6k per screen, against the prompt's ≤8k per screen target — comfortably inside budget, and far below the ~11M the document projects for a naive full-read approach. The per-agent "overruns" were against my tighter framing, not the actual budget.

Two things still owed before Stage A can use this

1. The master register covers only the original 12 modules. 07_Screen_Classification_Register.md needs all 47 shards rolled up, plus the per-agent _AMBIGUOUS_*/_DEV_Candidates_* files concatenated and a fresh _SpotCheck sample (10% weighted to A3/A5/A6/A9/A10 and every P0 row) for your Gate-1 sign-off.
2. An A7/A8 re-verification sweep. The 37 modules classified before I fixed decision-step 1 used the old method-name test, so any screen marked A7/A8 whose controller or service actually writes is suspect. Mechanical grep, cheap to run, and it must happen before Stage A trusts a read-only classification — otherwise a write screen silently gets zero write-path coverage.

Say the word and I'll run both. Still open for your ruling: tab-hub controller rows, and status-column-without-transition-methods (I recommended A2-with-note over A6).

✻ Sautéed for 42m 31s

──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
❯ run both