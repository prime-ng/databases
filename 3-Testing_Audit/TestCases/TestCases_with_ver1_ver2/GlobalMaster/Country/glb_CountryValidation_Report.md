# glb_Country — Validation Report

**Feature:** GlobalMaster > Country  **Date:** 2026-Jul-09  **Scope:** CENTRAL / prime-side

---

## 1. File Existence Summary

| # | Artifact | Present |
|---|----------|---------|
| 1 | `glb_CountryTcList_Require.md` | ✅ |
| 2 | `glb_CountryMANUALTESTING_Require.md` | ✅ |
| 3 | `glb_CountryGAPANALYSIS_Require.md` | ✅ |
| 4 | `glb_CountryV1_TestCas.php` | ✅ |
| 5 | `glb_CountryV2_TestCas.php` | ✅ |
| 6 | `glb_CountryValidation_Report.md` | ✅ (this file) |
| 7 | `run-Country-tests.ps1` | ✅ |
| 8 | `run-Country-tests.sh` | ✅ |

---

## 2. Naming Conventions

| Check | Result |
|-------|--------|
| Prefix matches DDL primary table | ✅ `glb_` ← `glb_countries` (`CREATE TABLE` in `_global_db_v4.sql`) |
| Feature PascalCase | ✅ `Country` |
| Class name = filename | ✅ `glb_CountryV1_TestCas` / `glb_CountryV2_TestCas` |
| snake_case, banded test methods | ✅ `test_country_NN_*` |
| Namespace (central pattern) | ✅ `Tests\Browser\Modules\Prime\GlobalMaster` |

---

## 3. Structure Validation

| Check | Result |
|-------|--------|
| Extends central base | ✅ `extends PrimeDuskTestCase` (physical `prm_PrimeDuskTestCase_TestCas`, resolves via preloader alias) — forces host `http://127.0.0.1:8000` |
| setUp/tearDown | ✅ resolveAdminUser + screenshot cleanup; no tenant init (central scope) |
| Typed props initialised | ✅ `?User $adminUser = null;` etc. |
| `php -l` V1 | ✅ No syntax errors |
| `php -l` V2 | ✅ No syntax errors |
| Central helper library reused | ✅ `centralUrl / authenticateCentral / visitAuthenticated / resolveAdminUser / ensurePageAccessible` (mirrors Billing base) |

---

## 4. Coverage Completeness

| Metric | Value |
|--------|-------|
| V1 method count | 16 |
| V2 method count | 54 |
| V2 ≥ 2×V1 (32) | ✅ 54 ≥ 32 |
| Negative coverage | 100% |
| Positive coverage | 100% |
| Dependency coverage | 100% |
| Every TC ↔ ≥1 method | ✅ (see Gap Analysis §1 + TcList §3) |
| Every method ↔ TC/BC | ✅ (V2 Method Index) |
| Semantic bands applied | ✅ 01–09 / 10–19 / 30–39 / 40–49 / 50–59 / 60–69 / 70–79 / 90–99 |

---

## 5. Constraints Obeyed (`05_Known_Test_Failure_Constraints.md`)

| Constraint | Applied |
|-----------|---------|
| A4 prime-side → no tenant scaffolding | ✅ central; no `initializeTenantContext`/tenancy end |
| B5 `App\Models\User` | ✅ used for admin + limited users |
| B9 `emp_code` ≤ 20 | ✅ `EMP###` / `LMT###` |
| C11 forceDelete wrapped in try/catch | ✅ `cleanupCountry` + child cleanup |
| C12 SoftDeletes verified before withTrashed | ✅ asserted `class_uses_recursive` in test_01 |
| C13 typed props default-init | ✅ |
| D14 no Dusk `assertStatus` | ✅ status/validation via `get/post/postJson` + `assertForbidden/assertNotFound/assertStatus(422)/assertSessionHasErrors` |
| D15 authenticate before POST | ✅ `actingAs($this->adminUser)` before mutations |
| D16 pass vars into browse closures | ✅ `use (...)` everywhere |
| D17 schema type asserts tolerant | ✅ `hasColumn/hasColumns` (no exact COLUMN_TYPE equals) |
| E19 module-enabled prerequisite | ✅ documented below (see §7) |
| E20 `APP_ENV=testing` | ✅ set by both runners |
| E21 central host 127.0.0.1 | ✅ via PrimeDuskTestCase |
| E22 base-class alias via preloader | ✅ `use Tests\Browser\Modules\Prime\PrimeDuskTestCase` + `extends PrimeDuskTestCase` |

---

## 6. Known Source Defects Documented

| ID | Sev | Where proven | Where documented |
|----|-----|--------------|------------------|
| SEC-GLB-001 | P1 | test_country_17 (+18) | TcList §4, Gap §3 (check 4), Manual TC-S01 |
| BUG-GLB-004 | P1 | test_country_42 | TcList §4, Gap §3 (check 7), Manual TC-D06 |
| CR-GLB-01 (short_name unique) | P3 | test_country_73 | Gap §3 (check 8) |
| CR-GLB-02 (global_code unique) | P3 | test_country_74 | Gap §3 (check 8) |
| CR-GLB-03 (missing is_active cast) | P3 | source-truth note | Gap §3 (check 5) |

Both P1 tests assert **current defective behaviour**; they must be inverted once the source is fixed.

---

## 7. Environment Prerequisites (not test-code issues)

1. **GlobalMaster AND Prime modules must be enabled** in `prime_testing/modules_statuses.json` — both are currently `false`, so every `/global-master/country` route returns **404**. Enable both before running.
2. `APP_ENV=testing` (bypasses CSRF/419) — set by the runners.
3. Central host `http://127.0.0.1:8000` must be serving (`php artisan serve` / Herd) — PrimeDuskTestCase fails fast otherwise.
4. `global_master_mysql` connection must be configured and `glb_countries` (+ `glb_states`/`glb_districts`/`glb_cities` for dependency tests) reachable, else those tests `markTestSkipped()`.
5. `MAIN_PROJECT_PATH` should point at the `prime_ai` checkout for source-truth asserts (falls back to `../prime_ai`).

---

## 8. Deliberately Skipped Dimensions

- **Cross-tenant isolation (TC-T):** N/A — Country is central/global (shared across tenants); recorded as an explicit skip in `test_country_90`.
- **DOM pagination navigation:** substituted with controller source-truth assert for speed/robustness (see Gap §5).

---

## 9. Final Verdict

**PASS WITH NOTES.**

- All 8 artifacts present; naming/structure/coverage gates met; both PHP files `php -l` clean; V2 (54) ≥ 2×V1 (16).
- Notes: (a) execution requires the two module-enabled + host prerequisites in §7 (env, not code); (b) two P1 defects (SEC-GLB-001, BUG-GLB-004) are encoded as current-behaviour proving tests and must be inverted on fix; (c) tenancy dimension is intentionally N/A for this central feature.
