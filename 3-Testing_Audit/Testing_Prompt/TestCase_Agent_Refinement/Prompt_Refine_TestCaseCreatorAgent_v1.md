# Refinement Prompt — Harden the "TestCase Creator" Agent Against 20 Known Test-Quality Defects

**Purpose:** A team member reviewed test files produced by the `testcase-creator` agent and logged 20 recurring quality defects. This prompt tells you (the executing agent) how to fold those findings **permanently** into the agent's single source of truth, so every future test-case generation run avoids them automatically.

**Run this prompt once** (it is a maintenance/refinement task, not a per-module task). After it completes, re-running the `testcase-creator` agent on any module must no longer reproduce these defects.

---

## 0. Read these first (do not skip)

1. **The defect report (input):**
   `/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/3-Testing_Audit/Testing_Prompt/TestCase_Agent_Refinement/test_quality_report.md`
   — Read all 20 mistakes AND the Quick Reference Table AND the "What Should Change for the Agent" section. Understand each in full.

2. **The agent's single source of truth (the files you will EDIT):**
   - `…/Testing-Plan/03_Testcase_Creator_Agent_Prompt.md` — the agent's role, HARD RULES, workflow, PHP skeleton, self-check quality gate.
   - `…/Testing-Plan/05_Known_Test_Failure_Constraints.md` — the numbered, evidence-tagged "MUST read before writing PHP" constraint list (currently rules 1–32). **This is the primary target** for most of the 20 defects.
   - `…/Testing-Plan/00_Testing_Artifacts_Index_and_Conventions.md` — shared conventions (helper library, taxonomies) — edit only if a defect is about shared helpers/structure.
   - (base = `/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/3-Testing_Audit/Testing-Plan/`)

3. **The loader (context only, usually no edit needed):**
   `/Users/bkwork/.claude/agents/testcase-creator/AGENT.md`

4. **Reference paths the report cites** (for verifying claims against real code):
   - Generated test files: `/Users/bkwork/Herd/prime_testing/tests/Browser/Modules/{MODULE}` (e.g. `Hostel`, `Inventory`)
   - App source: `/Users/bkwork/Herd/prime_ai/Modules/{Module}`
   - DDL: `/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/2-DDL_Tenant_Consolidated` and `…/2-DDL_Tenant_Enhanced`

---

## 1. Governing principles (obey these while refining)

1. **Reconcile, do not blindly append.** Several of the 20 defects are already *partially* covered by existing constraints in `05_`. Before writing a new rule, grep `05_` for the topic and **extend/strengthen the existing rule** instead of adding a duplicate that could contradict it. Known overlaps to reconcile (verify each yourself):
   - Mistake #8 (missing `media` table) ↔ existing **constraint 11** (`sys_media`, `forceDelete` guard).
   - Mistake #9 (tenant init) ↔ existing **constraint 2** (resolve via `Modules\Prime\Models\Domain` → `tenancy()->initialize($domain->tenant)`). **The report's suggested `tenancy()->initializeByDomain($domain)` may not be the verified API here — trust the codebase-verified constraint 2 and only correct the *actual* bug the report describes (missing/empty tenant id), not the method name, unless you verify otherwise.**
   - Mistake #14 (User required fields) ↔ existing **constraints 8 & 9** (`emp_code`, `prefered_language`, `user_type`). Fold `short_name` and `academic_session_id` into that same rule after confirming they are NOT NULL-without-default in the migrations.
   - Mistake #20 (mixed `actingAs()` + `browse()`) ↔ existing **constraint A1** (mirror the sibling's test style). Strengthen A1 with an explicit "one style per file" clause.
   - Mistakes #4/#6/#16 (403 not asserted, wrong URL prefix, wrong selectors) ↔ existing HARD RULES in `03_` ("never invent routes/selectors/messages/permissions") and **constraints 14, 31**. Strengthen, don't duplicate.

2. **Preserve the file's discipline.** `05_` states only *codebase-verified* rules and tags them `[Codebase-verified]` (and `[Per-feature-verify]` where per-module). For each new rule, **verify the claim against the real code** (the generated test file, the app source, the DDL, or a quick `grep`/`php -l`) and attach a short *Evidence:* note in the same style. If a claim in the report cannot be verified (e.g. it is a pure Laravel-API fact like `isCasted()` not existing), state it as a framework fact and tag it `[Laravel-12]` rather than fabricating codebase evidence.

3. **Separate authoring rules from environment prerequisites.** Some defects are things the **generated test code** must do (assertions, `refresh()`, cleanup, correct method names). Others are **harness/infra** issues the agent cannot fix in a test file (missing `media` migration in the test DB, catch-all handler in `prime_testing/bootstrap/app.php` turning 422→500, stale route cache, ChromeDriver curl timeouts). For the latter, the rule must instruct the agent to **document them as environment prerequisites in the Validation Report and assert against a tolerant observed-status set**, NOT to assert a brittle exact value that will false-fail. Do **not** direct the agent to edit `prime_testing` — that repo is read-only per the loader.

4. **Watch for conflicts with established convention.** Mistake #10 (extract shared helpers into a `TenantTestSetup` trait) **conflicts with the current design**, where the agent emits one self-contained `{prefix}_{Feature}_TestCas.php` per screen that mirrors the committed sibling's private helpers. Do **not** silently rewrite the artifact contract. Instead: encode the *intent* (helpers must be correct and consistent, and must mirror the sibling verbatim so a fix propagates by copy), and **flag the shared-trait proposal in the summary as a design decision for the user** rather than adopting it unilaterally. Same caution for Mistake #12 (broken cURL fallback in `responseStatusCode()`): fix the helper idiom in the skeleton, don't invent a new architecture.

5. **Every rule must be actionable and checkable.** Phrase each as an imperative the agent can self-verify in the quality gate ("MUST assert `403` via an HTTP test method after visiting a permission-denied route", not "be careful about permissions").

---

## 2. What to change, defect by defect

For each of the 20 mistakes, decide the correct home and encode it. Suggested mapping (adjust if your verification shows better placement):

| # | Defect | Home | Action |
|---|--------|------|--------|
| 1 | `addToAssertionCount(1)` with no real assertion | `03_` HARD RULE + `05_` new rule + quality gate | Ban it outright. Every test method MUST contain ≥1 real assertion. Add a self-check grep step to the quality gate: fail if any generated method's body is only `addToAssertionCount`. |
| 15 | Empty stub methods | same as #1 | Same ban; allowed escape hatch is `markTestIncomplete('reason')`, never a hollow pass. |
| 2 | `isCasted()` → `hasCast()` | `05_` new rule `[Laravel-12]` | No `isCasted()` in Laravel 12; correct is `hasCast()`. Add a short "verify any framework method exists before using it" clause. |
| 13 | `$model->isActive()` instance method | same rule as #2 | No `isActive()` instance method on Eloquent. Use the query scope `Model::active()` or check casts/columns directly. (Correct the report's own imprecision — `hasCast('is_active')` is not a semantic substitute for an active check.) |
| 3 | Missing `->refresh()` after `->create()` | `05_` new rule | Always `->refresh()` before asserting DB-default/DB-computed values. |
| 4 | 403 test never asserts 403 (+ stale permission cache) | strengthen `05_` 14/31 | After visiting a permission-denied route, MUST assert the status via an HTTP test method (`assertForbidden`/`assertStatus(403)`). After `revokePermissionTo()`/role changes, MUST call `app(\Spatie\Permission\PermissionRegistrar::class)->forgetCachedPermissions()`. Cross-link to constraint 31 (Super-Admin `Gate::before` bypass) so negatives use a non-super-admin user. |
| 5 | Exact seed counts | `05_` new rule | Use `assertGreaterThanOrEqual(N, …)` for seed/reference counts; never `assertEquals` on counts that other tests can grow. |
| 6 | Wrong URL prefix (`/fee-structures` vs `/hostel/fee-structures`) | strengthen `03_` "never invent routes" | Reinforce: derive every path from `php artisan route:list` / the module `routes/*.php` / `Route::has(name)`; never hand-write a URL. |
| 7 | No data cleanup | `05_` new rule (link to existing 11/13 teardown guards) | Every created record MUST be cleaned up — prefer sibling's `try/finally` teardown or `DatabaseMigrations`/`RefreshDatabase` when the sibling uses it. Keep the existing `try{ forceDelete }catch` guard from constraint 11. |
| 8 | Missing `media` table in test DB | strengthen constraint 11 | Models using `InteractsWithMedia` touch `sys_media`; if the table is absent in the test DB the call throws. Guard media-touching operations and note the `sys_media` migration as an environment prerequisite in the Validation Report. |
| 9 | Tenant context missing / empty id | strengthen constraint 2 | Fix the *real* bug (init called with null/empty tenant, or not called at all in `setUp`); keep the verified resolution path from constraint 2. Do not adopt an unverified API name. |
| 10 | Copy-pasted helpers | `03_`/summary (design flag) | Encode "helpers must mirror the sibling verbatim and be correct"; **flag the shared-trait proposal to the user**, do not change the one-file-per-screen contract unilaterally. |
| 11 | Missing CSRF token in AJAX | `05_` new rule (reconcile with constraint 20) | Reconcile with constraint 20 (`APP_ENV=testing` bypasses CSRF) and 14 (use HTTP test methods, not Dusk `.post()`). Rule: for real browser-side `fetch()`/AJAX include `X-CSRF-TOKEN` + `X-Requested-With`; for endpoint tests prefer `postJson()` etc. under the testing env. |
| 12 | Broken cURL fallback in `responseStatusCode()` | `03_` skeleton/helper | Fix the helper idiom (carry session cookies, or prefer Laravel HTTP test methods over a raw cURL fallback). Don't invent new architecture. |
| 14 | User created without required fields | strengthen constraints 8/9 | Add `short_name`, and `academic_session_id` where the table requires it, to the "required user/insert fields" rule — after confirming NOT NULL/no-default in the migration. |
| 16 | Wrong element selectors (`table` vs card, `Save` vs `Submit`) | strengthen `03_` "never invent selectors" | Reinforce: read the actual Blade view / rendered HTML for element type, button text, field names before writing selectors. |
| 17 | ChromeDriver curl timeouts | `05_` env note | Flakiness, not a code bug: allow a `retry()` wrapper around fragile browser ops; document as infra in the Validation Report; never assert on it. |
| 18 | Stale route cache | `05_` env prerequisite | Before route assertions, route cache must be cleared (`php artisan route:clear`); document as a runner prerequisite, do not bake a shell call into a test file. |
| 19 | Validation returns 500 not 422 | `05_` env prerequisite | Root cause is the catch-all handler in `prime_testing/bootstrap/app.php` (read-only repo). Rule: assert validation against a tolerant set (`{422,500}`) with a note, OR document the handler fix as a prerequisite — do NOT edit `prime_testing`. |
| 20 | Mixed `actingAs()` HTTP + `browse()` in one file | strengthen constraint A1 | One test style per file, chosen by mirroring the module sibling; if HTTP tests are used, tenant context MUST be initialized before `actingAs()`. |

---

## 3. Also update the agent's self-check quality gate

In `03_Testcase_Creator_Agent_Prompt.md`, find the pre-finish self-check / quality-gate checklist and add explicit, greppable gates so the agent catches these before returning:

- [ ] No method body is only `addToAssertionCount(1)` / empty (Mistakes #1, #15).
- [ ] No call to `isCasted(` or `->isActive(` (Mistakes #2, #13).
- [ ] Every `->create(` that is followed by a DB-default assertion has a `->refresh()` (Mistake #3).
- [ ] Every count assertion on seed/reference data uses `assertGreaterThanOrEqual` (Mistake #5).
- [ ] Every permission-denied path asserts a 403 and flushes the permission cache (Mistake #4).
- [ ] Every created record is cleaned up (teardown / `try-finally` / `DatabaseMigrations`) (Mistake #7).
- [ ] No hand-written URL paths or invented selectors/messages/permissions (Mistakes #6, #16).
- [ ] User-creation payloads include all NOT-NULL-no-default columns (Mistake #14).
- [ ] File uses exactly ONE test style, matching the sibling (Mistake #20).
- [ ] `php -l` passes on every generated PHP file.

Keep the checklist wording consistent with the existing gate's style.

---

## 4. How to write each new/edited constraint

- **Number new `05_` rules continuing from 32** (33, 34, …); keep the existing section headers (A–E) and place each rule under the best-fitting section, or extend the relevant existing numbered rule in place when reconciling.
- Each rule: one bold imperative sentence, then the *why*, then a short *Evidence:* note citing the real file/line or the framework fact, then the `[Codebase-verified]` / `[Laravel-12]` / `[Per-feature-verify]` tag(s) — mirroring the existing entries.
- Update the **"Usage in generated artifacts"** footer of `05_` if you add a category that must surface in the Validation Report (env prerequisites from #8/#17/#18/#19).
- Do **not** remove or weaken any existing verified constraint.

---

## 5. Verification before you finish

1. Re-read your edits end-to-end; confirm no new rule contradicts an existing one (especially constraints 2, 8, 11, 14, 20, 31).
2. Confirm every "environment prerequisite" rule tells the agent to *document*, not to edit `prime_testing`/`prime_ai`.
3. Confirm the `03_` HARD RULES and the quality-gate checklist reference the new constraints by number.
4. Spot-check 2–3 of the report's cited files (e.g. a Hostel 403 test, an Inventory seed-count test) against your new rules to confirm the rules would have caught the real defect.

## 6. Deliverable / final summary

Report back, concisely:
- Which files you edited and the new constraint numbers added.
- The reconciliations you made (which report mistakes were merged into existing constraints vs added new).
- Any report suggestion you deliberately did **not** adopt verbatim (e.g. the `initializeByDomain` API name, the shared-trait refactor of Mistake #10, the cURL-fallback redesign) and why — surfacing the shared-trait proposal as an open **design decision for the user**.
- Confirmation that no rule directs edits to the read-only `prime_testing`/`prime_ai` repos.

**Do not modify any test files or app code as part of this run** — this task only hardens the agent's source-of-truth prompt/constraints. Regenerating the affected modules with the improved agent is a separate, later step.
