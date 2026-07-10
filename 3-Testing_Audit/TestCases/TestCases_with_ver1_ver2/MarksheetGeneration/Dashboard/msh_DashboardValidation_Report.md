# MarksheetGeneration — Dashboard & Navigation — Validation Report

## 1. File Existence Summary
| # | Artifact | Status |
|---|----------|--------|
| 1 | `msh_DashboardTcList_Require.md` | ✅ |
| 2 | `msh_DashboardMANUALTESTING_Require.md` | ✅ |
| 3 | `msh_DashboardGAPANALYSIS_Require.md` | ✅ |
| 4 | `msh_DashboardV1_TestCas.php` | ✅ |
| 5 | `msh_DashboardV2_TestCas.php` | ✅ |
| 6 | `msh_DashboardValidation_Report.md` | ✅ (this file) |
| 7 | `run-Dashboard-tests.ps1` | ✅ |
| 8 | `run-Dashboard-tests.sh` | ✅ |

## 2. Naming Conventions
| Check | Result |
|-------|--------|
| Prefix `msh_` = DDL primary-table prefix (`MarksheetGeneration_DDL_v1.sql`, `msh_* (22 tables)`, `Database: tenant_db`) | ✅ |
| Feature PascalCase = `Dashboard` | ✅ |
| Class name = filename (`msh_DashboardV1_TestCas`, `msh_DashboardV2_TestCas`) | ✅ |
| Namespace `Tests\Browser;` | ✅ |
| Methods snake_case, zero-padded, semantic bands | ✅ |

## 3. Structure Validation
| Check | V1 | V2 |
|-------|----|----|
| `extends DuskTestCase` | ✅ | ✅ |
| `namespace Tests\Browser;` | ✅ | ✅ |
| `setUp()`/`tearDown()` with tenant init + guarded `tenancy()->end()` | ✅ | ✅ |
| Typed properties initialised (`?User $adminUser = null`, strings `''`) | ✅ | ✅ |
| `php -l` clean | ✅ | ✅ |
| Private helper library (screenshots, auth, tenancy, permissions, console) | ✅ | ✅ |

## 4. Coverage Completeness
| Metric | Value |
|--------|-------|
| V1 methods | 17 |
| V2 methods | 44 |
| V2 ≥ 2× V1 | ✅ (44 ≥ 34; 2.59×) |
| Every TC-ID ↔ ≥ 1 method | ✅ |
| Every method ↔ TC/BC | ✅ |
| Negative/Auth coverage | 100% |
| Positive coverage | 100% |
| Dependency coverage | 100% |
| Coverage-Score + Cross-Reference tables present | ✅ |

## 5. Known Source Defects Documented
| ID | Severity | Where documented | Proving test |
|----|----------|------------------|--------------|
| **BUG-MSH-001** | P0 | TcList §Known Defects, Gap §4, this report | V1 test_13; V2 test_58/59/72 |
| PERF-MSH-003 | P2 | TcList, Gap §4, this report | V1 test_11; V2 test_46 |
| D39-MSH | P1 | TcList, Gap §4, this report | V2 test_52–56 + grant helper |

**BUG-MSH-001 proof note:** confirmed *two* independent causes — (a) `MarksheetGenerationController` defines none of `index/store/show/update/destroy` (only `dashboard/configuration/components/scheduling/results`); (b) the module `RouteServiceProvider::map()` calls only `mapWebRoutes()`, so `routes/api.php` (the `apiResource('marksheetgenerations', …)`) is never registered. Tests assert both (`method_exists` false, `Route::has('marksheetgeneration.*')` false) plus an HTTP probe (`getJson` ≠ 200).

## 6. Constraints Applied (`05_Known_Test_Failure_Constraints.md`)
| Constraint | Applied |
|------------|---------|
| A1/A2/A3 tenant via `Modules\Prime\Models\Domain`, guarded teardown | ✅ |
| A4 tenant-side scaffolding (msh_/tenant_db) | ✅ |
| B5 `App\Models\User` + factory (matches golden sibling) | ✅ |
| B8/B9 limited user sets `emp_code`, `prefered_language`, `user_type=EMPLOYEE`; short unique suffix | ✅ (createLimitedUser) |
| B10 valid `glb_languages` id fetched before user create | ✅ |
| C13 typed props initialised | ✅ |
| D14 Dusk has no `assertStatus` → `getJson()` for the dead-API status; browser flows via path/see | ✅ |
| D16 browse closures receive outer vars via `use (...)` | ✅ |
| E19 **module must be enabled** in `modules_statuses.json` (else 404) | ✅ documented as env prereq |
| E20 `APP_ENV=testing` for Dusk | ✅ runners set it |

## 7. Enhanced dimensions
| Dimension | Included | Note |
|-----------|----------|------|
| Console/a11y smoke | ✅ | test_91, test_93 (SEVERE log filter) |
| Responsive smoke | ✅ | test_92 (390×844) |
| Tenancy isolation | Partial | test_90 single-tenant smoke; cross-tenant fixture deferred |
| API contract | ✅ | dead-API proving tests (BUG-MSH-001) |
| Security (XSS/IDOR/CSRF) | Skipped | read-only screen, no free-text input or mutations — not applicable |
| State-machine (BC-SM) | Skipped | no workflow on this screen |

## 8. Final Verdict

**PASS WITH NOTES.**

Notes:
1. **Env prereq (E19):** `MarksheetGeneration` must be enabled in `prime_testing/modules_statuses.json` before running; otherwise all routes 404 and every browser test fails for an environmental reason, not a defect.
2. **D39-MSH:** msh permissions are unseeded. Positive render tests grant the 5 msh view gates to the admin; gate-denial tests (test_52–56) skip defensively if a super-admin bypass is present in the environment.
3. **Proving tests assert current defective behaviour** for BUG-MSH-001 and PERF-MSH-003 — they will flag if the source behaviour changes (i.e. after a fix, update the assertions).
4. Suite not executed here (`execute` not requested); `php -l` verified clean on both PHP files.
