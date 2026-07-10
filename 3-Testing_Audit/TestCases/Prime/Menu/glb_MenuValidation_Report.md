# Menu (PRM / Central) — Validation Report

## 1. File Existence (7/7)
| # | File | Status |
|---|------|--------|
| 1 | glb_MenuTcList_Require.md | ✅ |
| 2 | glb_MenuMANUALTESTING_Require.md | ✅ |
| 3 | glb_MenuGAPANALYSIS_Require.md | ✅ |
| 4 | glb_Menu_TestCas.php | ✅ |
| 5 | glb_MenuValidation_Report.md | ✅ |
| 6 | run-Menu-tests.ps1 | ✅ |
| 7 | run-Menu-tests.sh | ✅ |

One PHP test file (no V1/V2 split). ✅

## 2. Naming Conventions
- Prefix `glb_` = DDL primary-table prefix of `glb_menus`. ✅ ⚠️ **Registry-vs-DDL mismatch**: module registry lists PRM prefix `prm_`; the feature's primary table is `glb_menus` (global_master), so `glb_` is used and the mismatch is flagged in every artifact header.
- Feature PascalCase `Menu`. ✅
- Class = filename `glb_Menu_TestCas`. ✅
- Methods snake_case, zero-padded, banded `test_menu_NN_*`. ✅

## 3. Structure Validation
- `namespace Tests\Browser\Modules\Prime\Menu;` ✅
- `extends PrimeDuskTestCase` (preloader alias for `prm_PrimeDuskTestCase_TestCas`, Constraint #22) ✅
- Central auth/helper chain implemented locally (copied from `prm_BillingDuskTestCase_TestCas`, Constraint #21): `centralUrl`, `authenticateCentral`, `visitAuthenticated`, `resolveAdminUser`, `ensurePageAccessible`, `currentPath`. ✅
- `App\Models\User` (Constraint #5). ✅
- Typed properties initialised (`?User $adminUser = null`, strings `''`). ✅
- `setUp()` resolves admin + cleans screenshots; `tearDown()` guards tenancy end. ✅ **No tenant init** (central scope). ✅
- `php -l` → **No syntax errors detected.** ✅

## 4. Coverage Completeness
- **Total methods: 52.**
- Positive 100% · Negative 100% · Dependency 100% · Tenancy/Security (central) 100%.
- Every TC-ID → ≥1 method; every method → a TC/BC. No V1/V2 ratio. ✅
- Semantic bands 01–09 / 10–19 / 20–29 / 30–39 / 40–49 / 50–59 / 60–69 / 70–79 / 90–99 applied. ✅

## 5. Known Source Defects Documented
| ID | Where |
|----|-------|
| DEV-PRM-MENU-001 (toggle binding) | test_menu_73, TcList §3, Gap §4/5 |
| DEV-PRM-MENU-002 (global unique vs scoped) | test_menu_74, TcList §3, Gap §4/5 |
| DEV-PRM-MENU-003 (menu_for/permission DDL drift) | test_menu_01, Gap §4 |
| DEV-PRM-MENU-004 (inverted route rule) | test_menu_38, Gap §4 |
| DEV-PRM-MENU-005 (is_direct_link dead field) | Gap §4/5 |
| PERF-PRM-002 + DEAD-PRM-001 (Navbar N+1, Blade component) | Gap §4/5 |
| DUP-PRM-001 (triplicate route groups) | test_menu_02, Gap §4 |

## 6. Constraints Applied (from 05_)
- #21 central runs on `http://127.0.0.1:8000`, extend PrimeDuskTestCase, use central auth chain (not tenant `DUSK_TENANT_URL`/initializeTenantContext).
- #22 filename↔classname mismatch resolved via preloader alias; `extends PrimeDuskTestCase` verbatim.
- #25 central activity sink `sys_central_activity_logs` asserted (fail-soft `Schema::hasTable`).
- #5/#7 `App\Models\User` factory/mass-assignment; password fillable.
- #14 Dusk has no `assertStatus()`/`->post()` → JSON via in-page synchronous XHR helper.
- #9 cross-module/DB-write paths guarded with `markTestSkipped`.
- #12/#17 schema types asserted via Schema introspection, not exact COLUMN_TYPE.
- #26 no module-local migration-file content assert (glb_menus provisioned via consolidated DDL / global_master) — schema truth via `Schema::connection('global_master_mysql')` + FormRequest source + model reflection.

## 7. Environment Prerequisites (E19/E20/E21)
- Prime **and** SystemConfig modules enabled in `prime_testing/modules_statuses.json` (else 404 on all routes).
- `APP_ENV=testing` for Dusk (CSRF bypass, else 419 on state-changing requests).
- App served at `http://127.0.0.1:8000`; central super-admin present; `global_master_mysql` connection configured.

## 8. Final Verdict
**PASS WITH NOTES.**
Notes: (1) `glb_` prefix vs registry `prm_` — intentional, DDL-correct, flagged. (2) DB-mutation and permission-gate tests fail-soft-skip in environments that cannot write central data or that apply a super-admin gate bypass. (3) Seven source findings documented with proving tests / static notes; none block the suite. (4) Suite not executed in this run (no `execute` flag) — `php -l` clean; runtime pending a live central environment.
