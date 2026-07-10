# Components & Weightages — Validation Report

## 1. File Existence Summary
| # | Artifact | Present |
|---|----------|---------|
| 1 | `msh_ComponentsAndWeightagesTcList_Require.md` | ✅ |
| 2 | `msh_ComponentsAndWeightagesMANUALTESTING_Require.md` | ✅ |
| 3 | `msh_ComponentsAndWeightagesGAPANALYSIS_Require.md` | ✅ |
| 4 | `msh_ComponentsAndWeightages_TestCas.php` (ONE file, no V1/V2) | ✅ |
| 5 | `msh_ComponentsAndWeightagesValidation_Report.md` | ✅ |
| 6 | `run-ComponentsAndWeightages-tests.ps1` | ✅ |
| 7 | `run-ComponentsAndWeightages-tests.sh` | ✅ |

## 2. Naming Conventions
- Prefix `msh_` = DDL table prefix of primary table `msh_template_scholastic_components` — **verified** against `CREATE TABLE` in `MarksheetGeneration_DDL_v1.sql`. ✅
- Feature PascalCase `ComponentsAndWeightages`. ✅
- Class name = filename: `class msh_ComponentsAndWeightages_TestCas extends DuskTestCase`. ✅
- Methods snake_case, zero-padded, semantic bands: `test_components_NN_*`. ✅

## 3. Structure Validation
- `namespace Tests\Browser;` + `extends DuskTestCase`. ✅
- `setUp()` (screenshot clean once, tenant init via `Modules\Prime\Models\Domain`, resolve admin) / guarded `tearDown()` (`tenancy()->end()`). ✅
- Typed props null-initialised (`?User $adminUser = null`, `?int $sharedTemplateId = null`). ✅
- `php -l` → **No syntax errors detected**. ✅

## 4. Coverage Completeness
- **Total methods: 51** (single file).
- Positive **100%** · Negative **100%** · Dependency **100%** · Defect-proving **100%**.
- Tenancy: tenant-side feature; all flows run inside the initialized tenant context (100% on this P1 module's flows). Cross-tenant IDOR not separately exercised (single-tenant Dusk env) — noted as a deliberate skip.
- Every TC-ID ↔ ≥1 method; every method ↔ a TC/BC (see TcList §3 index + Gap Analysis §1). ✅

## 5. Known Source Defects Documented
| ID | Where | Proving test |
|----|-------|--------------|
| BR-MSH-050 (P2) | Gap §5, TcList TC-DEF01 | 16 |
| BR-MSH-009 (P1) | Gap §5, TcList TC-DEF02/03 | 17, 18 |
| BR-MSH-012 (P1) | Gap §5 | 16, 17 |
| SEC-MSH-003 (P1) | Gap §3 #3 | 06, 51 |
| D39-MSH (P1, env) | §6 below | 06, 52 (defensive seed) |
| DEV-MSH-C03 (discovered) | Gap §3 #13 | 80 |
| DEV-MSH-C04 (discovered) | Gap §3 #1 | 72 |

## 6. Environment Prerequisites
- `MarksheetGeneration: true` in `prime_testing/modules_statuses.json` (else all routes 404). **Required.**
- `APP_ENV=testing` (Dusk CSRF bypass; runners set it). **Required.**
- Tenant domain resolvable from `DUSK_TENANT_URL`; `DUSK_ADMIN_EMAIL`/`DUSK_ADMIN_PASSWORD` valid.
- **D39-MSH:** component permissions unseeded → the suite seeds/grants `tenant.msh-*` defensively in `grantComponentPermissions()`.
- FK dependencies (academic session, marksheet type, exam group, `lms_exam_types`) resolved-or-seeded; tests `markTestSkipped()` when a hard dependency is truly absent.

## 7. Constraints Obeyed (`05_Known_Test_Failure_Constraints.md`)
- `use App\Models\User;` + factory-compatible resolution; tenant init via `Domain`, never `artisan tenancy:init`. ✅
- No Dusk `assertStatus()` — status via `sendJsonRequestFromBrowser()` fetch capture. ✅
- `use(...)` in all browse closures; `forceDelete()` wrapped in try/catch; `withTrashed()` only on SoftDeletes models. ✅
- MySQL8 type variance handled via index-name `SHOW INDEX` checks + `assertStringContainsString`; DECIMAL asserted exactly (`'100.00'`). ✅
- Typed props initialised; guarded teardown. ✅

## 8. Final Verdict
**PASS WITH NOTES.** All 7 artifacts present; exactly ONE `.php` test file (51 methods); `php -l` clean; prefix verified; coverage gates met; owned defects (BR-MSH-050/009/012, SEC-MSH-003, D39-MSH) mapped with proving tests plus two discovered defects (DEV-MSH-C03/C04).
**Notes:** (1) execution not run in this generation pass — requires the enabled-module + tenant Dusk environment above. (2) Several defect-proving tests assert *current* (buggy) behaviour and will need updating if the source is fixed (they carry explicit "defect may be fixed" guard messages). (3) Cross-tenant IDOR deliberately not exercised (single-tenant env).
