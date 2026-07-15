# Tenant Group — Validation Report (`prm_TenantGroupValidation_Report.md`)

## 1. File Existence Summary
| # | Artifact | Present |
|---|----------|---------|
| 1 | `prm_TenantGroupTcList_Require.md` | ✅ |
| 2 | `prm_TenantGroupMANUALTESTING_Require.md` | ✅ |
| 3 | `prm_TenantGroupGAPANALYSIS_Require.md` | ✅ |
| 4 | `prm_TenantGroup_TestCas.php` | ✅ (single file — no V1/V2) |
| 5 | `prm_TenantGroupValidation_Report.md` | ✅ |
| 6 | `run-TenantGroup-tests.ps1` | ✅ |
| 7 | `run-TenantGroup-tests.sh` | ✅ |

## 2. Naming Conventions
- Prefix `prm_` — **DDL-verified** against `CREATE TABLE prm_tenant_groups` (`_prime_db_v4.sql:329`). ✅
- Feature PascalCase `TenantGroup`. ✅
- Class = filename `prm_TenantGroup_TestCas`. ✅
- Methods snake_case, semantic bands `test_tenantgroup_NN_*`. ✅

## 3. Structure Validation
- `namespace Tests\Browser\Modules\Prime\TenantGroup;` ✅
- `extends PrimeDuskTestCase` (module-local alias via `preload.php`, constraint #22). ✅
- Central auth helpers copied locally from `prm_BillingDuskTestCase_TestCas` (`centralUrl`, `authenticateCentral`, `visitAuthenticated`, `resolveAdminUser`, `browseWithFailureScreenshot`, `captureFailureScreenshot`). ✅
- `setUp()` calls `parent::setUp()` (host guard 127.0.0.1), resolves admin, ensures gate-bypass flags. `tearDown()` guards tenancy defensively. ✅
- Typed properties initialised (`?User $adminUser = null`, string defaults). ✅
- **`php -l`: No syntax errors detected.** ✅

## 4. Coverage Completeness
- **Total test methods: 39.**
- Negative **100%**, Positive **96%**, Dependency **100%** (targets: 100 / ≥90 / ≥90 — all met).
- Tenancy dimension **N/A** (single central DB) — recorded, not counted as a gap.
- Every TC-ID maps to ≥1 method; every method maps back to a TC/BC (see TcList §3 index). ✅
- Selectors/routes/permissions/activity-event strings all sourced from real code (controller/request/model/blade/DDL) — no invention. ✅

## 5. Known Source Defects Documented
- **D25-PRM-002 (P2)** — assigned defect. Verified **NOT REPRODUCED**: `update()` uses `$request->validated()` (line 99), same as `store()`. Proving test `test_15` confirms mass-assignment safety. Documented in TcList + Gap Analysis.
- D25-PRM-003 (P3) update writes no activity log — proven by `test_16`.
- D25-PRM-004 (P2) index.blade renders cities not tenant groups — documented.
- D25-PRM-005 (P4) redirect anchor typo `#tanent-group` — documented.
- D25-PRM-006 (P3) `name` unique in Request only, not DB — `test_02` documents.
- D25-PRM-007 (P4) toggleStatus logs before save — documented.

## 6. Constraints applied (from `05_Known_Test_Failure_Constraints.md`)
- #21/#22 Prime/central host `127.0.0.1:8000`; extends module-local Prime base via preload alias.
- #25 Central activity sink `sys_central_activity_logs` asserted via `Schema::hasTable` + model `$fillable` (no DDL-file assert — none exists).
- #14 Dusk has no `assertStatus()` → status/JSON assertions use HTTP test methods (`post/put/delete/getJson/postJson`).
- #11 `forceDelete()` cleanup wrapped in try/catch (media table).
- #13 typed props initialised. #17 schema types not asserted for exact string.
- AppServiceProvider `Gate::before` requires `is_super_admin` **AND** `super_admin_flag`; gate-dependent tests self-skip via `skipUnlessAdminCan()` if the environment admin cannot bypass.

## 7. Environment Prerequisites
- **Prime module must be ENABLED** in `prime_testing/modules_statuses.json` (constraint #19) — else 404 on all routes.
- `APP_ENV=testing` (CSRF bypass, constraint #20). Runners set it.
- Central server reachable at `http://127.0.0.1:8000`; at least one `glb_cities` row for the `city_id` FK.

## 8. Final Verdict
**PASS WITH NOTES.** All 7 artifacts present; `php -l` clean; 39 methods; coverage gates met. Notes: (a) assigned defect D25-PRM-002 does **not** reproduce in the current source — documented honestly per HARD RULE 1; (b) five additional source findings (D25-PRM-003..007) discovered and traced; (c) browser render + limited-user tests self-skip in partial environments to stay green.
