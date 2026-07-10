# glb_Language — Validation Report

**Feature:** GlobalMaster › Language (central / prime-side)
**Generated:** 2026-Jul-09
**Verdict:** ✅ **PASS WITH NOTES**

---

## 1. File Existence Summary

| # | File | Present |
|---|------|---------|
| 1 | glb_LanguageTcList_Require.md | ✅ |
| 2 | glb_LanguageMANUALTESTING_Require.md | ✅ |
| 3 | glb_LanguageGAPANALYSIS_Require.md | ✅ |
| 4 | glb_LanguageV1_TestCas.php | ✅ |
| 5 | glb_LanguageV2_TestCas.php | ✅ |
| 6 | glb_LanguageValidation_Report.md | ✅ |
| 7 | run-Language-tests.ps1 | ✅ |
| 8 | run-Language-tests.sh | ✅ |

## 2. Naming Conventions

| Check | Result |
|-------|--------|
| Prefix `glb_` matches DDL primary table `glb_languages` | ✅ (verified `CREATE TABLE glb_languages`, `_global_db_v4.sql`) |
| Feature PascalCase `Language` | ✅ |
| PHP class name = filename (`glb_LanguageV1_TestCas`, `glb_LanguageV2_TestCas`) | ✅ |
| snake_case zero-padded methods `test_language_NN_*` | ✅ |
| Namespace `Tests\Browser\Modules\Prime\GlobalMaster` | ✅ |

## 3. Structure Validation

| Check | Result |
|-------|--------|
| Extends `PrimeDuskTestCase` (physical `prm_PrimeDuskTestCase_TestCas`, resolved via `preload.php` alias) | ✅ (C22) |
| Central host forced to `http://127.0.0.1:8000` by parent `setUp()` | ✅ (E21) |
| Typed properties initialised (`?User $adminUser = null;` etc.) | ✅ (C13) |
| `setUp()`/`tearDown()`; teardown guards `tenancy()->initialized` | ✅ (A3) |
| `php -l` clean on V1 | ✅ No syntax errors |
| `php -l` clean on V2 | ✅ No syntax errors |
| No hardcoded secrets/screenshot paths (env + base-class routing) | ✅ |

## 4. Coverage Completeness

| Metric | Value |
|--------|-------|
| V1 methods | **18** |
| V2 methods | **65** |
| V2 ≥ 2× V1 | ✅ (3.6×) |
| Every TC-ID ↔ ≥1 method | ✅ |
| Every method ↔ TC/BC | ✅ (V2 Method Index) |
| Negative coverage | 100% ✅ |
| Positive coverage | 100% ✅ |
| Dependency coverage | 100% ✅ |
| Cross-Reference Findings table | ✅ (11 checks) |
| Coverage-Score by Source | ✅ |
| Semantic numbering bands | ✅ (01-09/10-19/20-29/30-39/40-49/50-59/60-69/70-79/90-99) |

## 5. Known Source Defects Documented

| ID | Sev | Reproduces on live central route? | Proving test | Where documented |
|----|-----|-----------------------------------|--------------|------------------|
| BUG-GLB-006a (forceDelete logs `'Stored'`) | P1 | **YES** | test_17, test_24, V1-11 | TcList §3, Gap §4 |
| BUG-GLB-006b (update flash raw `'update.language'`) | P1 | **YES** | test_13, V1-07 | TcList §3, Gap §4 |
| BUG-GLB-006c (GlobalMaster ctrl wrong model import) | P1 | NO (GlobalMaster ctrl only) | Documented | TcList §3 |
| SEC-GLB-010 (ungated create/store/edit/update) | P0 | NO — live Prime ctrl gates all; repro on disabled GlobalMaster module route | tests 51-54 assert live 403 | TcList §3, Gap §4 |
| SEC-GLB-005 (`global-master.*` gate-prefix mismatch) | P1 | NO — live Prime ctrl uses `prime.*` | tests 55-57 assert live 403 | TcList §3, Gap §4 |
| D30 (`authorize()` returns `true`) | P2 | YES (shared request) | test_58 | TcList §1, Gap §4 |
| DUP-WEB-001 (triple-registered routes) | P2 | YES | Cross-ref #2 (test_02) | Gap §4 |
| DATA/MIG drift (DDL omits deleted_at/timestamps/name-unique) | P2 | N/A (spec) | test_05, test_01 | TcList §3, Gap §4 |
| MODEL drift (Prime\Language has no `is_active` cast) | P3 | YES | test_03 | Gap §4 |

## 6. Constraints applied (`05_`)

| Constraint | Applied |
|-----------|---------|
| A3 teardown tenancy guard | ✅ |
| A4 prime-side scope → **no tenant init** | ✅ (central; no `initializeTenantContext`) |
| B5 `App\Models\User` (runner) | ✅ |
| C8/C9 limited-user `emp_code`≤20 + `prefered_language` FK + `user_type` set defensively | ✅ (tests 51-57 helper) |
| C10 `glb_languages` is a VIEW on central `mysql` | ✅ (model uses `global_master_mysql` real table) |
| C11 `forceDelete()` guarded in cleanup | ✅ |
| C12 `withTrashed()`/`onlyTrashed()` only after verifying SoftDeletes | ✅ (verified in test_01/03) |
| C13 typed props initialised | ✅ |
| D14 Dusk has no `assertStatus`/`.post` — HTTP test methods used for endpoints/status | ✅ |
| D15 authenticate before validation/negative POSTs | ✅ (`actingAs` admin) |
| D16 browse closures pass outer vars via `use` | ✅ |
| D18 ENUM case-exact (LTR/RTL) | ✅ (test_39) |
| E21 central features on `127.0.0.1:8000` via `PrimeDuskTestCase` | ✅ |
| E22 filename↔classname mismatch base resolves via preloader | ✅ |

## 7. Environment prerequisites (E19/E20/E21 — not test-code fixes)

1. **`APP_ENV=testing`** (bypasses CSRF/419). Runners set it.
2. Host **`http://127.0.0.1:8000`** (central domain); base test case fails otherwise. In-process HTTP tests pin `HTTP_HOST` to this host so `Route::domain(config('app.domain'))` matches; if the env's `app.domain` differs, endpoint tests skip on 404 rather than false-fail.
3. **Prime module ENABLED** in `prime_testing/modules_statuses.json` (renders `prime::language.*` views). **GlobalMaster** should also be enabled so `Modules\GlobalMaster\Http\Requests\LanguageRequest` and the activity-log models autoload reliably. **Both are currently `false`** → without enabling, central language routes/views 404 or error. Document, do not code around.
4. A super-admin user (`is_super_admin=1`) exists for `resolveAdminUser()`.
5. `MAIN_PROJECT_PATH` env points at the `prime_ai` clone for the migration/request file-content assertions (else those sub-assertions skip).

## 8. Deliberately skipped dimensions

- **Cross-tenant isolation (TC-T):** N/A — Language is a CENTRAL master shared by all tenants; no per-tenant scoping exists to isolate. Recorded via `test_language_96_*` (`markTestSkipped`).
- **Responsive / a11y / console-error smoke:** not included (simple reference-master screen); can be added later.

## 9. Final Verdict

✅ **PASS WITH NOTES.** All 8 artifacts present; prefix verified against DDL; V1/V2 `php -l` clean; V2 (65) ≥ 2× V1 (18); full negative/positive/dependency coverage; reconciled the audit's SEC-GLB-010/SEC-GLB-005 against the **live** Prime controller (correctly gated) and encoded the two reproducible BUG-GLB-006 sub-defects with proving tests. **Notes:** (a) execution requires Prime + GlobalMaster enabled and the central host/domain configured; (b) many endpoint/permission tests carry env skip guards by design; (c) DDL spec `_global_db_v4.sql` is stale vs the migration (document, do not fix in test).
