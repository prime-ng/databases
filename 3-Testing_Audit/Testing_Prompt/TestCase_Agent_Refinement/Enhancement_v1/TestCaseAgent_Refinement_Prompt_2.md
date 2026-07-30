# Refinement Prompt #2 — Close the DDL-Coverage Gaps & the "Read-the-Code" Gap in the "TestCase Creator" Agent

**Purpose:** A second review of test files produced by the `testcase-creator` agent (batch 2, from Shailesh) surfaced **6 issues**. Unlike batch 1 (which was mostly *test-hygiene / correctness* defects), this batch is mostly about **coverage the agent fails to generate** — schema constraints that exist in the DDL but are never actually exercised by a test — plus one **process defect**: test cases written by looking at the UI/form instead of reading the real code. This prompt tells you (the executing agent) how to fold these findings **permanently** into the agent's single source of truth so every future generation run produces this coverage automatically.

**Run this prompt once** (it is a maintenance/refinement task, not a per-module task). After it completes, re-running the `testcase-creator` agent on any module must produce the UNIQUE/NULL/length/DDL-consistency/model-usage coverage and must never propose a programmatically-managed field as a form input.

---

## 0. Read these first (do not skip)

1. **The batch-2 report (input):**
   `/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/3-Testing_Audit/Testing_Prompt/TestCase_Agent_Refinement/Enhance_report.md`
   — Read all 6 mistakes AND the Quick Reference Table AND the "What Should Change for the Agent" section. Understand each fully.

2. **The batch-1 report (context — so you don't duplicate or contradict what was already encoded):**
   `…/TestCase_Agent_Refinement/test_quality_report.md` and the already-applied
   `…/TestCase_Agent_Refinement/Refinement_Prompt_TestCase_Creator_Agent.md`
   (batch 1 added constraints **F33–F42** to `05_` and HARD RULE 14 + quality-gate items to `03_`).

3. **The agent's single source of truth (the files you will EDIT):**
   - `…/Testing-Plan/03_Testcase_Creator_Agent_Prompt.md` — role, HARD RULES, WORKFLOW (esp. Step 2 BC decomposition, Step 3 TC enumeration, Step 6 the test file + `test_01`), coverage gates, quality-gate checklist.
   - `…/Testing-Plan/05_Known_Test_Failure_Constraints.md` — numbered, evidence-tagged constraint list (currently **1–42** after batch 1; sections A–F). **This is where new codebase-verified constraints go, continuing from F43.**
   - `…/Testing-Plan/00_Testing_Artifacts_Index_and_Conventions.md` — BC/TC taxonomies — edit only if a taxonomy row must be added.
   - (base = `/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/3-Testing_Audit/Testing-Plan/`)

4. **Reference paths for verifying claims against real code:**
   - Generated test files: `/Users/bkwork/Herd/prime_testing/tests/Browser/Modules/{MODULE}` (Hostel, Inventory were the review scope)
   - App source: `/Users/bkwork/Herd/prime_ai/Modules/{Module}`
   - DDL: `/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/2-DDL_Tenant_Consolidated` and `…/2-DDL_Tenant_Enhanced`

---

## 1. Governing principles (obey these while refining)

1. **This batch is mostly about GENERATED COVERAGE, not just guardrails.** Batch 1 lived mostly in `05_` (rules that stop false failures). Batch 2 lives mostly in `03_` — the agent must **enumerate and emit** these test cases as part of the standard matrix. So most edits belong in `03_` (BC decomposition, TC enumeration, `test_01`, coverage gates, quality gate), with supporting codebase-verified facts captured as new `05_` F-rules where useful.

2. **Reconcile, do not blindly append.** Several of the 6 overlap existing material — extend/strengthen in place, do not add a contradicting duplicate. Known overlaps to reconcile (verify each yourself):
   - Mistake #3 (field length) ↔ existing **constraint 18** ("Respect column limits in generated data"). **These are complementary, not the same:** constraint 18 says *your own seed data must not overflow the column*; Shailesh's rule says *you must also submit an over-length value on purpose and assert the app rejects it*. Encode the new positive-obligation (a boundary negative test) and cross-link 18 so the agent doesn't confuse them.
   - Mistake #4 (soft-delete sub-check) ↔ existing **constraints 12 & 30**. Constraint 30 already establishes that `deleted_at` (the column) and `SoftDeletes` (the trait) can disagree in this codebase and must be asserted **independently** and reported as a defect — do NOT let the new rule regress that into "make them match." Reuse 30's discipline.
   - Mistake #6 (read the code, not the UI) ↔ existing **HARD RULE #1 ("Read before you write")** and **#2** and the **Step 1 read-order**. Strengthen with the specific *programmatically-managed field* clause (the `ordinal` example) rather than restating "read the source."
   - Mistake #1 (UNIQUE) and #2 (NULL/NOT NULL) partly touch the existing negative matrix in `03_` Step 6 ("required/…/duplicate") and the cross-reference scan — make them **explicit, mandatory, DDL-derived** obligations rather than optional mentions.

3. **DDL is the source of truth for these obligations — derive from the schema, not the form.** Every rule in this batch keys off the DDL (`UNIQUE`, `NOT NULL`/nullable, `VARCHAR(n)`, columns, types, defaults, FKs, `deleted_at`). The agent already reads the DDL in Step 1; the change is that it must now **turn each relevant DDL fact into a specific test case** and prove coverage of it. Cross-check the DDL against the FormRequest (`max:`, `required`, `unique:`, `in:`) — a divergence is a `DEV-###` candidate (this extends the existing Cross-Reference Defect Scan in Step 7).

4. **Respect this codebase's verified quirks** (from batch 1 / existing `05_`), so the new coverage does not false-fail:
   - Validation-error status may be **500 not 422** here (F41) — a "rejected" assertion for #1/#2/#3 must accept the tolerant set, or assert the DB-level outcome (row absent / duplicate refused), not a brittle exact 422.
   - The consolidated DDL can **diverge from the live schema** (constraints 28, 30) — assert schema truth against the live schema (`Schema::hasColumn`, `information_schema`, `SHOW INDEX`) where the DDL is known to lag, not only `assertStringContainsString` on the DDL file.
   - Soft-delete column vs trait can disagree (30). Unique/NOT NULL enforcement may live in the **DB, the FormRequest, or both** — assert the observed behaviour and, where only one layer enforces it, record the gap as a `DEV-###` rather than "fixing" it.
   - Authorization/Gate quirks (31), user-required-columns (#8) still apply when these new tests create records.

5. **Every rule must be actionable and self-checkable** — phrase as an imperative the agent can verify in the quality gate ("For every DDL `UNIQUE` key, emit a duplicate-rejection test", not "consider uniqueness").

---

## 2. What to change, issue by issue

For each of the 6 issues, encode the obligation in the right place. Suggested mapping (adjust if your verification shows better placement):

| # | Issue | Home | Action |
|---|-------|------|--------|
| 1 | UNIQUE constraint never tested with a duplicate | `03_` Step 3/Step 6 negative matrix + coverage gate + new `05_` F-rule | For **every** `UNIQUE` column/composite `UNIQUE KEY` in the DDL: emit a test that creates one record then attempts a second with the same value(s) and asserts rejection (validation error, or DB `1062`/tolerant status, or "row not inserted"). Composite keys: vary only the keyed columns. Add a `BC-DB`/`TC-N` obligation and a coverage-gate line. |
| 2 | NULL / NOT NULL never verified | `03_` Step 2/3 + coverage gate + new `05_` F-rule | Derive required/optional from the DDL (NOT the form). For each **NOT NULL-no-default** column: a missing-value negative test asserting rejection. For representative **nullable** columns: a missing-value positive test asserting success. Cross-check DDL vs FormRequest `required` — divergence → `DEV-###`. |
| 3 | Field length (VARCHAR size) never tested | `03_` Step 3 + strengthen constraint 18 | For sized string columns (`VARCHAR(n)`/`CHAR(n)`): emit an over-length boundary negative test (n+k chars) asserting rejection, AND a max-length positive test (exactly n) asserting success. Cross-link constraint 18 (don't overflow your OWN seed data) — the two are complementary. Cross-check DDL size vs FormRequest `max:` — divergence → `DEV-###`. |
| 4 | No DDL ↔ app consistency check (incl. soft-delete) | `03_` Step 6 `test_01` spec + quality gate | Make `test_01` assert the FULL alignment matrix: every DDL column exists in the model/migration; no app field references a non-existent column; NULL/NOT NULL match; data types handled; lengths match; defaults respected; UNIQUE validated; FKs/relationships correct; column names consistent across DDL/model/request/controller/test. **Soft-delete:** assert the `deleted_at` column and the `SoftDeletes` trait **independently** (per constraint 30 — they can disagree; report a mismatch as a defect, don't force them to match), and make delete-assertions match reality (`assertSoftDeleted()` only when the model actually soft-deletes). Assert against the **live schema** where the DDL is known to lag (28/30). |
| 5 | Wrong / misconfigured Eloquent model | `03_` HARD RULES + Step 1 read-order + quality gate | Before CRUD, resolve and verify the feature's correct model from real usage (controller/service) + DDL table: model exists, correct import, `$table` matches the DDL primary table/prefix, `$fillable`/`$guarded` support the tested fields, relationships valid; route ALL CRUD through it. A wrong/missing/misconfigured model → fix the test (and if the app model is wrong, `DEV-###`). |
| 6 | Tests written from the UI, not the code (the `ordinal` case) | strengthen `03_` HARD RULE #1/#2 + Step 1 + new `05_` F-rule | The agent MUST review controller, FormRequest, model, service, routes, and business logic before writing cases — never the Blade form alone. **Programmatically-managed fields** (auto-assigned `ordinal`, auto-generated code/name, server-set defaults, computed columns, status transitions) must be tested as **auto-behaviour** (assert the controller/service sets them), and must **NEVER** be proposed as form inputs or as user-editable fields. Use the `ordinal` example verbatim as the canonical illustration. |

---

## 3. Where to add the coverage obligations in `03_` (be specific)

- **Step 2 (Decompose into Business Conditions):** ensure `BC-DB` explicitly enumerates, per column, the DDL facts that must be tested: UNIQUE keys, NOT NULL/nullable, VARCHAR sizes, defaults, FKs, `deleted_at`. Add a short instruction that each such DDL fact becomes ≥1 TC.
- **Step 3 (Enumerate Test Cases):** state that the negative matrix MUST include, DDL-derived: duplicate-on-every-unique-key, missing-value-on-every-NOT-NULL, over-length-on-every-sized-string; and the positive matrix MUST include nullable-omitted-succeeds and max-length-succeeds.
- **Step 6 (`test_01` + the matrix):** expand the `test_01` spec (currently "schema/config truth") to the full alignment matrix from Issue #4, and add the programmatic-field assertions from Issue #6 (e.g. assert `ordinal` is auto-set, not fillable-by-user where that's the design).
- **Step 7 (Cross-Reference Defect Scan):** extend the 11-check table with DDL-vs-FormRequest divergence rows for UNIQUE / required / max-length / soft-delete-trait so mismatches surface as `DEV-###`.
- **Coverage gates / QUALITY GATES:** add explicit checkboxes (see §5).
- Keep all wording consistent with the existing document's style and the batch-1 additions (HARD RULE 14, the F33–F42 gate lines).

## 4. How to write each new/edited `05_` constraint

- **Number new `05_` rules continuing from 42** (43, 44, …) under section **F** (or a new short section **G. DDL-derived coverage obligations** if that reads cleaner) — keep the existing A–F structure; extend constraint 18 in place for the length reconciliation.
- Each rule: one bold imperative, then the *why*, then a short *Evidence:* note (a real DDL `UNIQUE KEY`/`NOT NULL`/`VARCHAR(n)` you actually looked at, or the `ordinal` controller logic you confirmed), then the `[Codebase-verified]`/`[Laravel-12]`/`[Per-feature-verify]` tag — mirroring existing entries and the batch-1 F-rules.
- **Verify before you state.** Open one real DDL table and confirm it has a `UNIQUE KEY` and a `NOT NULL`/`VARCHAR(n)` column; open the `ordinal`-handling controller to confirm the field is set in code, not the form. Cite what you actually saw. Do **not** fabricate evidence — if a point is a pure framework/testing fact, tag it `[Laravel-12]`.
- Do **not** remove or weaken any existing constraint (especially 12, 18, 28, 30, 31, and the batch-1 F-rules).

## 5. Add these self-check quality gates to `03_`

Append to the QUALITY GATES checklist (consistent with the batch-1 additions):

- [ ] For every DDL `UNIQUE` column/key, a duplicate-rejection test exists and asserts the duplicate is refused (#1).
- [ ] For every NOT NULL-no-default column, a missing-value negative test asserts rejection; representative nullable columns have a missing-value positive test (#2).
- [ ] For every sized string column, an over-length negative test asserts rejection and a max-length positive test asserts success; DDL size ↔ FormRequest `max:` cross-checked (#3).
- [ ] `test_01` asserts the full DDL↔app alignment matrix (columns, null/not-null, types, lengths, defaults, unique, FKs, name consistency) against the LIVE schema where the DDL lags; soft-delete column and trait asserted independently (#4, constraints 30).
- [ ] The correct, verified Eloquent model is used for all CRUD (`$table`/prefix, fillable, relationships confirmed) (#5).
- [ ] No programmatically-managed field (e.g. `ordinal`, auto-code, server default) is proposed as a form input; such fields are tested as auto-behaviour (#6).
- [ ] DDL-vs-FormRequest divergences (unique/required/max/soft-delete) surfaced as `DEV-###` in the Gap Analysis (#1–#4).

## 6. Verification before you finish

1. Re-read your edits end-to-end; confirm nothing contradicts existing constraints — **especially 12, 18, 28, 30, 31, and F33–F42**.
2. Confirm the soft-delete rule preserves constraint 30's "assert independently, report mismatch" discipline (does NOT tell the agent to force column=trait).
3. Confirm the length rule is framed as an over-length **negative test to submit**, distinct from constraint 18's "don't overflow your own seed data."
4. Confirm every "rejected" assertion tolerates the 500-vs-422 quirk (F41) or asserts the DB-level outcome, so it won't false-fail.
5. Spot-check one real DDL table (a Hostel or Inventory table with a `UNIQUE KEY` + a `VARCHAR(n)` + a NOT NULL column) and the `ordinal` controller against your new rules to confirm the rules are correct and would generate the missing coverage.

## 7. Deliverable / final summary

Report back, concisely:
- Which files you edited, the new constraint numbers added (F43+), and the `03_` sections/gates changed.
- The reconciliations made (which of the 6 were merged into existing constraints/HARD RULES vs added new — expected: #3↔18, #4↔12/30, #6↔HARD RULE 1/2; #1/#2/#5 new obligations).
- Any point you deliberately did NOT encode verbatim (e.g. anything that would regress constraint 30, or force an exact-422 assertion despite F41) and why.
- Confirmation that no rule directs edits to the read-only `prime_testing`/`prime_ai` repos, and that the DDL-derived tests tolerate this codebase's verified quirks (500-vs-422, DDL-lags-live-schema, column↔trait divergence).

**Do not modify any test files or app code as part of this run** — this task only hardens the agent's source-of-truth prompt/constraints. Regenerating the affected modules with the improved agent is a separate, later step.
