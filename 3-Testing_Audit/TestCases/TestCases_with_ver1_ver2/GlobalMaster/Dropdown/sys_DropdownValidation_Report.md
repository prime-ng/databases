# Dropdown — Validation Report (`sys_DropdownValidation_Report.md`)

**Feature:** GlobalMaster > Dropdown · **Scope:** CENTRAL / prime-side (`prime_db`) · **Generated:** 2026-Jul-09

## 1. File Existence Summary

| # | Artifact | Present |
|---|----------|---------|
| 1 | `sys_DropdownTcList_Require.md` | ✅ |
| 2 | `sys_DropdownMANUALTESTING_Require.md` | ✅ |
| 3 | `sys_DropdownGAPANALYSIS_Require.md` | ✅ |
| 4 | `sys_DropdownV1_TestCas.php` | ✅ |
| 5 | `sys_DropdownV2_TestCas.php` | ✅ |
| 6 | `sys_DropdownValidation_Report.md` | ✅ (this file) |
| 7 | `run-Dropdown-tests.ps1` | ✅ |
| 8 | `run-Dropdown-tests.sh` | ✅ |

## 2. Naming Conventions

| Check | Result |
|-------|--------|
| Prefix matches DDL primary table | ✅ `sys_` = `sys_dropdown_table` (verified in `_prime_db_v4.sql` + migration `2025_11_16_114618`) |
| Feature PascalCase | ✅ `Dropdown` |
| Class name = filename | ✅ `sys_DropdownV1_TestCas`, `sys_DropdownV2_TestCas` |
| snake_case zero-padded methods | ✅ `test_dropdown_NN_*` |

## 3. Structure Validation

| Check | Result |
|-------|--------|
| Namespace | ✅ `Tests\Browser\Modules\Prime\GlobalMaster` (central sibling of Billing) |
| Base class | ✅ `extends BillingDuskTestCase` (physical `prm_BillingDuskTestCase_TestCas`, alias via `preload.php` — constraint E22) |
| Central host | ✅ inherits `http://127.0.0.1:8000` from `PrimeDuskTestCase` (constraint E21) |
| setUp/tearDown | ✅ inherited from base (`resolveAdminUser`, status-report teardown); no tenant init (central scope, constraint A4) |
| Typed properties initialised | ✅ base declares `?User $adminUser = null` etc. |
| `php -l` V1 | ✅ No syntax errors |
| `php -l` V2 | ✅ No syntax errors |

## 4. Coverage Completeness

| Metric | Value |
|--------|-------|
| V1 methods | **18** |
| V2 methods | **79** |
| V2 ≥ 2× V1 | ✅ 79 ≥ 36 (4.39×) |
| Positive coverage | 100% (target ≥90%) ✅ |
| Negative coverage | 100% (target 100%) ✅ |
| Dependency coverage | 100% (target ≥90%) ✅ |
| Security pack | ✅ XSS(91), mass-assign guard(92), IDOR(76,93), injection search(94), guest→login(50,95) |
| API contract | ✅ toggle JSON `{success,is_active,message}` shape asserted (13,96,99) |
| Every TC ↔ ≥1 method | ✅ (see Gap Analysis §1) |
| Every method ↔ TC/BC | ✅ (see TcList §3 Method Index with bands) |
| Semantic numbering bands | ✅ 01–09 schema, 10–19 biz, 30–39 val, 40–49 integ, 50–59 auth, 60–69 UI, 70–79 edge, 90–99 security |

## 5. Known Source Defects Documented

| ID | Sev | Where captured | Proving tests |
|----|-----|----------------|---------------|
| VAL-GLB-001 | P1 | TcList §1/§Defects, Gap #8 | V1-05; V2-30,36 |
| BUG-GLB-005 | P1 | TcList, Gap #2 | V1-15; V2-48,49,94 |
| BUG-GLB-009 | P2 | TcList, Gap #4 | V1-04; V2-45,46,19,92 |
| PERF-GLB-001 | P2 | TcList, Gap #12 | V2-69 (soft timing) |

## 6. Constraints Applied (from `05_Known_Test_Failure_Constraints.md`)

- **A4 / prime-side:** central `sys_*` table → no tenant init emitted.
- **E21 / E22:** extends the central Billing base (alias) so host is forced to `127.0.0.1:8000` and the classname/filename mismatch resolves via preloader.
- **D14:** dead-route & endpoint status checks use Laravel HTTP methods (`$this->get()/postJson()`), NOT Dusk `assertStatus`.
- **D18:** ENUM `type` asserted case-sensitively; `ordinal` treated as TINYINT (≤255).
- **B5 / B7:** `App\Models\User` used (runner has it, matches sibling); admin resolved by base helper.
- **C11:** central activity-log reads guarded with try/catch → `markTestSkipped` when unavailable.
- **C13:** typed props initialised (inherited from base).

## 7. Environment Prerequisites (NOT test-code fixes)

1. **`modules_statuses.json` must enable `GlobalMaster: true` AND `Prime: true`.** Both are currently `false` → all `/global-master/dropdown` routes return 404 (constraint E19). Browser flows will fail until enabled; the env-tolerant asserts (200-or-403/404) keep schema/reflection/HTTP-contract tests meaningful even when disabled.
2. **`APP_ENV=testing`** (runners set it) to bypass CSRF (else 419 on POST).
3. **Central host `http://127.0.0.1:8000` reachable** with Chromedriver for Dusk.
4. Copy both PHP files into `prime_testing/tests/Browser/Modules/Prime/GlobalMaster/Dropdown/` before running (they are authored against that path/namespace).

## 8. Deliberate Skips
- **Cross-tenant isolation (TC-T):** N/A — `sys_dropdown_table` is a single central table in `prime_db`, not per-tenant. Recorded as `test_dropdown_90_cross_tenant_isolation_not_applicable`.
- **State-machine (BC-SM):** feature has no status workflow beyond active/inactive + soft-delete; no FSM band emitted.

## 9. Final Verdict

**PASS WITH NOTES.**

All 8 artifacts present and consistent; both PHP suites `php -l` clean; V2 (79) ≥ 2× V1 (18); coverage targets met; four source defects encoded with proving tests. Notes: (a) live browser assertions require GlobalMaster + Prime enabled in `modules_statuses.json` (currently `false`); (b) the store() happy-path is intentionally NOT asserted as passing because the feature's store is defective (VAL-GLB-001 + BUG-GLB-009) — tests prove the current broken behaviour instead; (c) `execute` was not requested, so no live run proof is attached.
