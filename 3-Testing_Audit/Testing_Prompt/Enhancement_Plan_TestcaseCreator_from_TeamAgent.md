# Enhancement Plan — Adopting Team-Agent Findings into `Testcase_Creator` (Safely)

**Prepared:** 2026-07-09
**Scope:** Implement **only** the "worth adopting" findings from `Comparison_Report_TeamAgent_vs_TestcaseCreator.md`, without regressing any existing strength of the `Testcase_Creator` agent.
**Governing principle:** *Verify every codebase/environment-specific claim against YOUR actual sources before encoding it into the agent.* Nothing is copied from the team agent on faith.

**Files this plan will touch (agent config only — never app/test source):**
- `…/3-Testing_Audit/Testing-Plan/03_Testcase_Creator_Agent_Prompt.md` (the agent)
- `…/3-Testing_Audit/Testing-Plan/00_Testing_Artifacts_Index_and_Conventions.md` (shared conventions)
- `…/3-Testing_Audit/Testing-Plan/05_Known_Test_Failure_Constraints.md` (**new** — referenced constraints library)
- `~/.claude/agents/testcase-creator/AGENT.md` (loader — add a pointer to the new constraints file)

---

## 1. What's In Scope (and what is deliberately NOT)

### In scope — the "worth adopting" set
| # | Item | Source (report §) | Priority |
|---|------|-------------------|----------|
| A | Known Test-Failure Constraints library | §4.1 | P1 |
| B | 11 cross-reference gap checks | §4.2 | P1 |
| C | Service-layer reading in source-read order | §4.7 | P1 |
| D | Prime-vs-Tenant DB determination → toggles tenancy scaffolding | §4.3 | P1 |
| E | `BC-SM` (+ optional `BC-INT`, `BC-EDG`, `BC-CFG`) taxonomy | §4.5 | P2 |
| F | `Source` traceability tags + Coverage-Score table | §4.4 | P2 |
| G | Semantic V2 numbering bands | §4.6 | P2 |
| H | Auto path-correction + Constraints feedback loop | §4.8 | P3 |

### Explicitly OUT of scope (do NOT change — these are your strengths, report §5)
- Screen-based feature model (1 requirement file = 1 feature). **Keep.**
- Module-folder-first + `{Module}_YYYY-MMM-DD[_HH-MM]` non-overwrite output governance. **Keep.**
- Strategy/roll-up layer (risk tiers, RTM, dashboards, defect register, program summary). **Keep.**
- Enhanced dimensions as first-class categories (TC-T tenancy, TC-S security, a11y, responsive, timing). **Keep.**
- "Detect test style per feature" grounded in the committed sibling. **Keep.**
- Report/dashboard screen-type awareness. **Keep.**
- His controller-scan-as-primary, interactive 5-input workflow, vendor-neutral shell. **Do not import** — borrow content, not his workflow.

---

## 2. Safety Principles (apply to every change)

1. **Config-only edits.** Only the four files in the header. Never touch `prime_ai`, `prime_testing`, or generated `TestCases/`.
2. **Verify-before-encode.** Any codebase fact (fillable, column sizes, table/view names) or env fact (base-class method, `APP_ENV`, route loading) must be confirmed against the real source (§4 harness) before it enters the prompt. Unverified items are written as "verify per feature," not as absolutes.
3. **Reconcile with YOUR base class.** The team agent assumes `initTenant()` via `Domain` lookup; your `DuskTestCase` uses `initializeTenantContext()` + auto dev-server + per-feature screenshot routing. Translate, don't paste.
4. **Versioned, reversible edits.** Snapshot the three existing docs before editing (§6). Every edit is a discrete, described diff.
5. **No-regression guard.** After edits, re-confirm each OUT-of-scope strength still reads intact (§7 checklist).
6. **Prove with a dry run.** Re-generate one already-known feature and diff behaviour before/after the enhancement (§8).
7. **Additive over rewrite.** Prefer new appendix sections + short pointers in the workflow over rewriting existing steps, to minimise blast radius.

---

## 3. Work Packages (each: change → target → verification → acceptance → risk)

### WP-A — Known Test-Failure Constraints library  *(P1)*
- **Change:** create `05_Known_Test_Failure_Constraints.md` holding the curated constraints; add a short "Constraints (MUST FOLLOW)" pointer in `03_` (in HARD RULES and in the V1/V2 generation steps) and a one-line reference in the loader.
- **Content source:** report §4.1 + §6, **filtered through the §4 harness** and tagged `[Universal] / [Codebase-verified] / [Env-verified] / [Per-feature-verify]`.
- **Verification:** run the §4 harness; only `Universal`/`*-verified` items become imperative rules; unverified become advisory.
- **Acceptance:** every imperative constraint cites a verified source; the file is referenced (not duplicated) from `03_`.
- **Risk:** Low. Additive appendix.

### WP-B — Cross-reference gap checks  *(P1)*
- **Change:** add an "11-point cross-reference defect scan" subsection to the Gap-Analysis step (Step 8) in `03_`, and a row-set in the Gap Analysis artifact template.
- **Checks:** enum-case (DDL `ENUM` vs FormRequest `in:`), route-registration (Blade `route()` vs registered), gate-vs-policy, fillable-vs-DDL, cast-vs-DDL, service-delegation, state-machine-vs-impl, validation-vs-FormRequest, error-message-vs-FormRequest, permissions-vs-policy, integration-FK-vs-migration.
- **Verification:** dry-run the checks against one feature; confirm they produce real, non-noise findings.
- **Acceptance:** Gap Analysis output gains a "Cross-Reference Findings" table; each check maps to a `DEV-###`/module-equivalent when it fires.
- **Risk:** Low–Med (could produce false positives → keep as "candidate findings, verify in source").

### WP-C — Service-layer reading  *(P1)*
- **Change:** insert `app/Services/{Feature}Service.php` (and shared services) into the Step-1 "read source" order in `03_`, right after Controller; note "business logic often lives here."
- **Verification:** confirm services exist in `prime_ai` modules (grep). If a module has none, the step is a no-op.
- **Acceptance:** read-order lists Services; BC-BIZ extraction references service logic when present.
- **Risk:** Low.

### WP-D — Prime-vs-Tenant DB determination  *(P1)*
- **Change:** add a resolution rule: determine whether the feature's primary tables are central (`prime_db`/`prm_*`,`sys_*` central) or per-tenant, and **toggle tenancy scaffolding** in generated V1/V2 accordingly. Reconcile with your `DuskTestCase` (`initializeTenantContext`) rather than his `initTenant()`.
- **Verification:** confirm how your base class initialises tenancy; confirm at least one prime-side vs tenant-side example from the DDLs.
- **Acceptance:** prompt states how to decide prime vs tenant and what setUp/tearDown differs; does not emit tenancy init for prime-side features.
- **Risk:** Med — must match your actual base class; verify first.

### WP-E — Expanded BC taxonomy (BC-SM +)  *(P2)*
- **Change:** add `BC-SM` (State Machine) — and optionally `BC-INT`, `BC-EDG`, `BC-CFG` — to the BC taxonomy in `00_` §6 and to the TcList template in `03_`. Map FSM transitions → `BC-SM-##` → state-transition TCs.
- **Verification:** none needed (taxonomy convention). Confirm it composes with existing BC-DB/VAL/AUTH/BIZ/REF/AUTO.
- **Acceptance:** taxonomy table updated; workflow features (e.g. BehaviouralAssessment period/assessment FSM) get BC-SM rows.
- **Risk:** Low.

### WP-F — `Source` tags + Coverage-Score table  *(P2)*
- **Change:** adopt `Source` tag convention (trace each TC back to its screen-file section, e.g. `Screen-BR-3`, `Screen-SM-2`) in TcList; add a Coverage-Score table to Gap Analysis (% of screen Business Rules / State-Machine rows / Validation rules / Integration points / Permissions covered).
- **Verification:** none (documentation convention).
- **Acceptance:** TcList TCs carry `Source`; Gap Analysis shows Coverage-Score %.
- **Risk:** Low.

### WP-G — Semantic V2 numbering bands  *(P2)*
- **Change:** define numbering bands for V2 methods (01-09 schema · 10-19 business rules · 20-29 state machines · 30-39 validation · 40-49 integration · 50-59 permissions · 60-69 UI/UX · 70-79 edge · 80-89 config) and map your TC-T/TC-S onto free bands (e.g. 90-99 tenancy/security). Update the V2 generation step in `03_`.
- **Verification:** ensure it doesn't conflict with the golden-reference sequential style — present as the preferred scheme for new work; existing files unaffected.
- **Acceptance:** V2 step documents bands; `#`→band mapping shown.
- **Risk:** Low.

### WP-H — Auto path-correction + feedback loop  *(P3)*
- **Change:** (i) add `Module`↔`Modules`/trailing-slash/case auto-retry to the resolve step; (ii) add a "Constraints feedback loop" — when a real new test-failure/fix is discovered, append it to `05_Known_Test_Failure_Constraints.md` so the agent compounds.
- **Verification:** none.
- **Acceptance:** resolve step self-heals path variants; loader/prompt instruct appending new lessons to `05_`.
- **Risk:** Low.

---

## 4. Verify-Before-Encode Harness (run BEFORE writing constraints)

Run these read-only checks against the real repos; record PASS/FAIL + the evidence next to each constraint in `05_`. **Only verified constraints become imperative.**

| Claim to verify | How to check (read-only) | If FALSE |
|-----------------|--------------------------|----------|
| Your base class init method | Read `TEST_FILE_REPO/tests/DuskTestCase.php` — confirm `initializeTenantContext()` (not `initTenant()`); screenshot routing; dev-server autostart | Encode YOUR method names, not his |
| `password` not in `$fillable` on module User | `grep -n fillable APP_REPO/Modules/SchoolSetup/app/Models/User.php` (and `App\Models\User`) | Drop/adjust the rule |
| `sys_users` columns: `emp_code` size, `prefered_language` FK, no `user_type` | Grep the tenant DDL / migrations for `emp_code`, `prefered_language`, `user_type` | Correct sizes/names |
| `glb_languages` is a VIEW | `grep -in "glb_languages" OLD_REPO/2-DDL_Tenant_Consolidated/*` (look for `CREATE VIEW`) | Adjust seeding note |
| Media table name (`sys_media` vs `media`) | Grep DDL/config for media table | Use the real name |
| `APP_ENV=testing` requirement / CSRF | Read `TEST_FILE_REPO/phpunit.dusk.xml` + `.env.dusk*` | Confirm your value |
| `modules_statuses.json` disabled ⇒ 404 | Read `TEST_FILE_REPO/modules_statuses.json` | Keep as pre-run check |
| MySQL version (COLUMN_TYPE variance) | Confirm MySQL 8 in `TEST_SETUP.md`/config | Keep assertStringContainsString guidance |
| Dusk `Browser` lacks `assertStatus()` | Universal Dusk fact | Adopt as-is |
| `withTrashed()` needs SoftDeletes; closures need `use()` | Universal Laravel/PHP facts | Adopt as-is |
| Services exist per module | `ls APP_REPO/Modules/*/app/Services 2>/dev/null` | Make read step conditional |
| Prime-side vs tenant-side example | Identify a `prm_*`/central feature vs a `sys_*`/tenant feature in DDLs | Ground WP-D |

Any claim that can't be verified is written as **"verify per feature at generation time"**, never as a hard assertion.

---

## 5. Execution Sequence & Gates

```
Gate 0  Snapshot the 3 existing docs (§6)                 ── required before any edit
Phase 1 (P1): WP-C → WP-A → WP-B → WP-D                    ── run §4 harness first
   Gate 1  Harness PASS recorded for every imperative constraint
Phase 2 (P2): WP-E → WP-F → WP-G
   Gate 2  Taxonomy/traceability compose cleanly with existing artifacts
Phase 3 (P3): WP-H
Gate 3  No-regression checklist (§7) all green
Gate 4  Dry-run diff (§8) shows improvement, no breakage  ── final sign-off
```
- Do Phase 1 first (highest value, correctness-critical), pause for review, then Phase 2/3.
- Each WP is a separate, described edit — not a bulk rewrite.

---

## 6. Backup & Rollback

- **Snapshot (Gate 0):** copy the three docs to a dated backup, e.g. `Testing-Plan/_backup_YYYY-MMM-DD/` (this is inside the planning tree, not `TestCases/`), before editing. The new `05_` file has no prior version.
- **Rollback:** restore from the dated backup; delete `05_` if abandoning WP-A; the loader pointer is a one-line revert.
- **Git:** if the planning folder is under version control, commit before and after each phase for granular revert.

---

## 7. No-Regression Checklist (Gate 3 — must all stay TRUE)

- [ ] Screen-based feature model intact (1 requirement file = 1 feature).
- [ ] Module-folder-first + timestamped non-overwrite output rule intact and unchanged.
- [ ] `OUTPUT_ROOT` still `…/3-Testing_Audit/TestCases/`; no other write locations introduced.
- [ ] TC-T / TC-S / a11y / responsive / timing dimensions still present.
- [ ] "Detect test style per feature" rule intact.
- [ ] Report/dashboard screen-type awareness intact.
- [ ] 8-artifact contract + filenames unchanged.
- [ ] V2 ≥ 2× V1 gate unchanged.
- [ ] "Read real source / never invent" hard rules unchanged.
- [ ] No app/test source files were modified.

---

## 8. Validation Dry Run (Gate 4)

1. Pick a known feature with a committed baseline (e.g. `HrStaff/LeaveType`, already dry-run once).
2. Regenerate to a scratch folder with the **enhanced** agent.
3. Confirm the additions appear and add value: constraints observed, cross-reference findings table present, Service layer read (if any), prime/tenant scaffolding correct, BC-SM rows where a FSM exists, `Source` tags + Coverage-Score present, V2 banding applied.
4. Confirm nothing broke: `php -l` clean, V2≥2×V1, filenames/contract unchanged, output still under `TestCases/{Module}/…`.
5. Diff against the pre-enhancement dry run; record the delta as evidence of improvement.

---

## 9. Acceptance Criteria (definition of done for this enhancement)

- All P1+P2 WPs implemented in `03_`/`00_`/`05_` with the loader pointer added.
- Every imperative constraint in `05_` has a recorded verification (§4).
- §7 no-regression checklist fully green.
- §8 dry run shows the enhancements active and no breakage.
- The comparison report's "worth adopting" set is fully reflected; out-of-scope items untouched.

---

## 10. Rough Effort & Suggested Order

| Phase | WPs | Effort | Note |
|-------|-----|--------|------|
| Prep | Gate 0 + §4 harness | ~0.5 day | Read-only verification; produces the evidence table |
| P1 | C, A, B, D | ~1 day | Correctness-critical; review before proceeding |
| P2 | E, F, G | ~0.5 day | Structure/traceability |
| P3 | H | ~0.25 day | Robustness + feedback loop |
| Close | Gates 3–4 | ~0.5 day | No-regression + dry-run diff |

> On approval, execute Phase 1 first and pause at Gate 1 for your review before Phase 2/3.
