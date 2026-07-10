# Completion Formula v2 — 10-Dimension Evidence-Anchored Model

**Status:** Single Source of Truth for module completeness scoring.
**Supersedes (as the scoring authority):** the 3-layer A/B/C formula in `7-CLAUDE_Prompts/Dev_Completness_Status_Prompt/ModuleCompletionCalculation_Formula/22-Dev_Completness_Calculation_Process.md` and the 5-dimension draft in `12-ModuleCompletionCalculationFormula_v2.md`. Those remain valid history; **v2 below is what the Status_Analyzer agent now uses.**
**Owner:** Status_Analyzer agent (`AI_Brain/agents/status-analyzer.md`).

---

## 0. Why v2 exists

The prior formula folded everything into three opaque layers (A/B/C). Users could not see *"how complete is the requirement doc?"*, *"how secure is it?"*, *"how many bugs are fixed vs pending?"* as distinct, defensible numbers. v2 splits completeness into **10 named dimensions**, each scored **0–100% per module**, each derived from a **counted evidence ledger** (never a gut estimate), then rolled up into one weighted score with P0 caps.

**The three reliability rules (non-negotiable):**
1. **Every % must come from a count** — numerator/denominator recorded in the Evidence Ledger. If you cannot count it, you cannot score it; mark it `⚠️ unmeasured` and lower the dimension's confidence.
2. **Every dimension cites its source file(s).** No dimension is scored from memory or the prior number (no anchoring).
3. **Same inputs → same score.** Two runs on an unchanged module must produce the identical number.

---

## 1. Input Sources (load ALL before scoring)

**⭐ Resolution map (authoritative):** `{APP_INTRO}/module_list.md` maps every module →
`MODULE_NAME · CODE · PREFIX · FOLDER_NAME · DDL_FILE_NAME`. **Always resolve a module's files
through this table** — never fuzzy-match filenames. `FOLDER_NAME` = the app code folder + the
requirement/test folder stem; `CODE` = the FRD/requirement file prefix; `DDL_FILE_NAME` = the DDL
stem (may be `N/A` for code-only modules; `global_db_/prime_db_/tenant_db_` = a MASTER db).

**Fixed source folders (this machine):**
```
DEV_CODE          = /Users/bkwork/Herd/prime_ai/Modules/{FOLDER_NAME}
MODULE_DATABASES  = /Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/2-DDL_Tenant_Consolidated   (per-module {DDL_FILE_NAME}*.sql)
MASTER_DATABASES  = /Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/0-DDL_Masters                 (global_db_/prime_db_/tenant_db_ v4)
TESTCASE_FOLDER   = /Users/bkwork/Herd/prime_testing/tests/Browser/Modules/{FOLDER_NAME}         (real Browser tests — NOT Modules/{M}/tests)
FRD_FOLDER        = /Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/4-Requirement_Module_wise/0-FRD_Documents/{CODE}_FRD*.md
REQUIREMENT_FOLDER= /Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/4-Requirement_Module_wise/2-Module_Requirement_V1/{FOLDER_NAME}_v*/
OLD_REQUIREMENT   = /Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/4-Requirement_Module_wise/4-Initial_Requirements/V2
APP_INTRO         = /Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/0-Prime_Ai_Detail
```

| # | Source | Resolve via | Feeds |
|---|--------|-------------|-------|
| 1 | **Requirements** | `FRD_FOLDER/{CODE}_FRD*.md` → else `REQUIREMENT_FOLDER/{FOLDER_NAME}_v*` → else `OLD_REQUIREMENT` | D1, D3 |
| 2 | **DDL schema** | `MODULE_DATABASES/{DDL_FILE_NAME}*.sql`; if stem is a master db → `MASTER_DATABASES`; if `N/A` → module is code-only, D2 = N/A (exclude, renormalize) | D2, D4 |
| 3 | **App code** | `DEV_CODE` (routes, controllers, models, FormRequests, policies) | D3, D4, D5, D6, D10 |
| 4 | **Migrations** | central `{LARAVEL_REPO}/database/migrations/tenant/` (this app centralizes migrations — assess platform-level, not per-module) | D2, D9 |
| 5 | **RSP / tenant routes** | `DEV_CODE/app/Providers/RouteServiceProvider.php`, `routes/*`, `{LARAVEL_REPO}/routes/tenant.php` | D5, D9 |
| 6 | **Policies / Gates** | `DEV_CODE/app/Policies/`, `AuthServiceProvider`, `Gate::` usage (verify policy is *registered & invoked*, not just present) | D5 |
| 7 | **Tests** | `TESTCASE_FOLDER/{FOLDER_NAME}/` (Browser tests) + any `DEV_CODE/tests/` | D8 |
| 8 | **Seeders** | `DEV_CODE/database/seeders/` | D9 |
| 9 | **Known issues / bugs** | `AI_Brain/lessons/known-issues.md` (codes `*-{CODE}-*` + severity + status) | D7 |
| 10 | **Prior state** | `AI_Brain/state/progress.md` (delta only — NEVER an anchor) | reporting |
| 11 | **Conventions / systemic baseline** | `AI_Brain/memory/conventions.md`, known-issues "Platform-Wide Systemic Patterns" | D5, D6 |

If a source is genuinely missing (after resolving via `module_list.md`), score dependent dimensions on what exists, mark **confidence = Low**, and record the gap. Never invent evidence. Never fuzzy-match when `module_list.md` gives the exact name.

---

## 2. The 10 Dimensions

| Dim | Name | Weight | "100%" means | Primary evidence |
|-----|------|:---:|---|---|
| **D1** | Requirement Document Completeness | 5% | A V2 requirement doc exists with feature functions + acceptance criteria for every entity | Requirement file |
| **D2** | DDL / Schema Completeness | 10% | Valid v2 DDL, no P0 schema errors, every requirement entity has a table, migrations exist for all tables | DDL + migrations |
| **D3** | Development Coverage (Requirements) | 25% | Every planned feature function is implemented (route + method + real logic) | Req register vs code |
| **D4** | Implementation Quality / Correctness | 18% | Built features return correct data — no stubs, broken columns, dummy keys, or God controllers | Controller bodies vs DDL |
| **D5** | Security & Authorization | 15% | Every write + sensitive-read route gated; tenancy isolation intact; no PII in plaintext; policies actually invoked | Gate/policy/middleware/FormRequest |
| **D6** | Coding Standard & Maintainability | 5% | PSR-12 + platform conventions; no God controllers, dead code, live `dd()`, wrong prefixes | File metrics + conventions |
| **D7** | Bug-Fix Status | 8% | All logged issues for the module are Resolved (weighted by severity) | known-issues.md |
| **D8** | Test Coverage | 4% | Pest tests exist for controllers/critical flows and pass | tests/ |
| **D9** | Deployment Readiness | 8% | Installs on a fresh tenant unattended: migrations + seeders + full tenancy stack + module registration, zero P0 blockers | migrations/seeders/RSP |
| **D10** | Performance | 2% | No P1 N+1 in hot paths, no unbounded `::all()` on form render, no schema introspection in request path | code scan |
| | **TOTAL** | **100%** | | |

> **Weight rationale:** Development Coverage (25%) + Implementation Quality (18%) dominate because a module IS its working features. Security (15%) is next — an unsecured module is worse than an incomplete one. DDL (10%), Deployment (8%), and Bug-Fix (8%) are foundation/operational gates. Requirement doc (5%), coding standard (5%), tests (4%), performance (2%) are quality multipliers. Weights are stable unless the user changes them.

---

## 3. Per-Dimension Rubrics (0–100, all count-derived)

### D1 — Requirement Document Completeness
```
score = 100 × (documented_feature_functions_with_acceptance_criteria / expected_feature_functions)
```
| Evidence | Points contribution |
|---|---|
| V2 requirement file exists | gate (if absent → D1 ≤ 30, from V1/HighLevel/DDL-inferred) |
| Each entity/CRUD set has a feature-function list | +count |
| Acceptance criteria / expected route+method present per feature | +count |
| Mobile/API + reports/dashboards documented | +count |
`expected_feature_functions` = union of (requirement-listed) ∪ (DDL-table-implied CRUD sets). Missing doc but rich DDL ⇒ D1 low, note "requirements under-specified."

### D2 — DDL / Schema Completeness
```
D2 = 0.5×schema_validity + 0.3×entity_coverage + 0.2×migration_presence
```
- `schema_validity` (0–100): 100 if zero P0 schema errors (type-mismatch FK, FK→missing table, index on missing column, no prefix); 50 if only P1; 0 if P0 present or no DDL.
- `entity_coverage` = 100 × (requirement_entities_with_a_table / requirement_entities).
- `migration_presence` = 100 × (module_tables_with_a_migration / module_tables).
**P0 schema error ⇒ D2 capped at 40 AND triggers the global 50% cap (§5).**

### D3 — Development Coverage (Requirements Coverage) — the old "Layer A"
Build the **Feature Function Register** (every planned discrete user action). Score each:
`✅ 1.0` (route+method+real logic+correct output) · `🟡 0.5` (exists but stub/broken/incomplete) · `❌ 0.0` (missing/500).
```
D3 = 100 × Σ(feature_score) / total_feature_functions
```

### D4 — Implementation Quality / Correctness — the old "Layer B" (per built feature, avg)
Per ✅/🟡 feature score 4 sub-criteria, then average across built features:
| Sub | Max | 0-point trigger |
|---|:---:|---|
| Route integrity | 30 | 500/404 or shadowed(→10) |
| Business logic completeness | 30 | stub / live `dd()` / abort(501) |
| Data integrity (columns/keys match DDL) | 25 | dummy keys, wrong columns, DDL/code mismatch |
| Layer separation (no God controller, no cross-layer model import) | 15 | >1000 lines(→≤7) or central-model import in tenant controller |
```
D4 = Σ(per-feature sub-total) / (built_feature_count × 100) × 100
```

### D5 — Security & Authorization
```
D5 = 0.45×write_auth + 0.20×read_auth + 0.20×tenancy_isolation + 0.15×data_protection
```
- `write_auth` = 100 × (write routes with a REAL Gate/policy that is actually invoked / total write routes). FormRequest `authorize(){return true;}` = not real. Dead/duplicate-killed policy = not real.
- `read_auth` = 100 × (sensitive read routes gated / sensitive read routes).
- `tenancy_isolation` = 100 minus penalties for: missing `EnsureTenantHasModule`, cross-layer central-model import, wrong tenant DB usage.
- `data_protection` = 100 minus penalties for PII in plaintext, secrets in source, mass-assignment on privilege fields.
**Any P0 security finding ⇒ D5 capped at 50.** (Cross-check the "Platform-Wide Systemic Patterns" table in known-issues.md — SEC-PLATFORM-001, D30, etc.)

### D6 — Coding Standard & Maintainability
```
D6 = 100 − Σ penalties (each capped)
```
| Violation | Penalty |
|---|---|
| God controller >1000 lines | −15 each (max −30) |
| Controller 500–1000 lines | −5 each (max −15) |
| Wrong permission prefix / naming | −10 |
| Live uncommitted `dd()`/`var_dump()` | −20 |
| Dead code / commented blocks / `.blade_*` backups | −5 each (max −15) |
| `->enum()` where `sys_dropdown` FK expected (D29) | −5 |
Floor at 0. Cross-reference conventions.md.

### D7 — Bug-Fix Status  (severity-weighted resolution rate)
From `known-issues.md`, collect all issue codes scoped to the module (`*-{PREFIX}-*`) + applicable platform-wide P0s.
```
weight: P0=5, P1=3, P2=1
D7 = 100 × Σ(weight × resolved?) / Σ(weight × all_issues)
```
Where `resolved? = 1` if the issue is marked Fixed/Resolved/Closed, else 0. If no issues logged for the module, D7 = `⚠️ unmeasured` (exclude from roll-up, renormalize weights) and note "no bug data — run Technical Auditor first."
**Report the raw ledger:** `P0: {fixed}/{total} · P1: {fixed}/{total} · P2: {fixed}/{total}`.

### D8 — Test Coverage
```
D8 = 0.6×controller_test_ratio + 0.4×pass_rate
```
- `controller_test_ratio` = 100 × (controllers with ≥1 test / total controllers). 0 tests ⇒ 0.
- `pass_rate` = 100 × (passing tests / total tests) if runnable; else `⚠️ unmeasured` and use ratio only.

### D9 — Deployment Readiness
```
D9 = 0.35×migrations + 0.20×seeders + 0.30×tenancy_stack + 0.15×module_registration
```
- `migrations` = 100 × (tables with migration / tables); 0 ⇒ **global 50% cap**.
- `seeders` = 100 if required master-data seeders exist, 50 partial, 0 none (N/A modules score 100).
- `tenancy_stack` = 100 full stack (`InitializeTenancyByDomain + PreventAccessFromCentralDomains + EnsureTenantIsActive + EnsureTenantHasModule + auth + verified`), −20 per missing middleware.
- `module_registration` = 100 if wired into `tenant.php` / module.json enabled, else 0.

### D10 — Performance
```
D10 = 100 − (25×N+1_hotpaths + 15×unbounded_form_queries + 20×schema_introspection_in_request), floored at 0
```
counts from code scan (reference PERF-* codes in known-issues.md).

---

## 4. Roll-Up

```
Overall_Raw = Σ (Dimension_score × weight)     (renormalize weights if any dimension is ⚠️ unmeasured)
Overall_Final = min(Overall_Raw, P0_Cap)
Round to nearest integer.
```

Each dimension also carries a **Confidence** = High (all evidence present + counted) / Medium (partial evidence) / Low (inferred). Report a module-level confidence = lowest of the dimensions that contribute ≥10% weight.

---

## 5. P0 Caps (global — apply the LOWEST matching)

| P0 Condition | Global Cap |
|---|---|
| Module cannot load (RSP/import/route syntax error) | **20%** |
| DDL P0 structural error OR zero migrations | **50%** |
| Primary-entity core route (Create/List) throws 500 | **55%** |
| Primary-entity write route has ZERO real Gate | **60%** |
| All report/dashboard routes unguarded, OR confirmed PII-plaintext / secret-in-source | **65%** |
| No P0 conditions | No cap |

Per-dimension caps also apply: D2 ≤ 40 on P0 schema error; D5 ≤ 50 on any P0 security. These shape the dimension display even when the global cap is higher.

---

## 6. Deployment-Readiness Gate (module go/no-go)

Independent of the %, every module gets a **deployment verdict** (the user's "Readiness for Deployment"):
- 🟢 **Ready** — Overall ≥ 85, no P0, D5 ≥ 70, D9 ≥ 80, D2 valid.
- 🟡 **Near** — Overall 60–84, ≤ 1 P0 (non-security), D9 ≥ 60.
- 🔴 **Blocked** — Overall < 60, OR any P0 security/DDL, OR D9 < 60 (cannot install cleanly).

---

## 7. Reproducibility Checklist (run before finalizing any score)
- [ ] Every dimension % has a numerator/denominator in the Evidence Ledger.
- [ ] Every dimension cites the file(s) it was scored from.
- [ ] No score was anchored to the prior progress.md number.
- [ ] P0 caps checked in order, lowest applied.
- [ ] `⚠️ unmeasured` dimensions excluded from roll-up with weights renormalized.
- [ ] Confidence recorded per dimension.

*Update this file's rubrics as calibration patterns emerge; treat the weights and P0 caps as stable unless the user changes them.*
