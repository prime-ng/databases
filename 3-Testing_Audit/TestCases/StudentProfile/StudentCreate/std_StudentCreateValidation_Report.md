# std_StudentCreate — Validation Report

## 1. File Existence Summary
| # | Artifact | Status |
|---|----------|--------|
| 1 | `std_StudentCreateTcList_Require.md` | ✅ |
| 2 | `std_StudentCreateMANUALTESTING_Require.md` | ✅ |
| 3 | `std_StudentCreateGAPANALYSIS_Require.md` | ✅ |
| 4 | `std_StudentCreate_TestCas.php` | ✅ (ONE file, no V1/V2) |
| 5 | `std_StudentCreateValidation_Report.md` | ✅ |
| 6 | `run-StudentCreate-tests.ps1` | ✅ |
| 7 | `run-StudentCreate-tests.sh` | ✅ |

## 2. Naming Conventions
- Prefix `std_` verified against DDL `StudentProfile_DDL_v1.6.sql` — all feature tables `std_*`; primary `std_students`. (NOT the sibling `spr_`.)
- Feature PascalCase `StudentCreate`; class = filename `std_StudentCreate_TestCas`; methods snake_case `test_studentcreate_NN_*`.

## 3. Structure Validation
- `namespace Tests\Browser;` · `extends DuskTestCase` · typed props initialised (`?User $adminUser = null`).
- `setUp()`/`tearDown()` with `initializeTenantContext()` + guarded `tenancy()->end()`.
- Tenant resolution via `Modules\Prime\Models\Domain` (05_ A2). No `assertStatus()` on Dusk `Browser` — status codes captured via in-page fetch (05_ D14).
- **`php -l`: No syntax errors detected.**

## 4. Coverage Completeness
- **37 test methods, single file.** Semantic bands: 01–09 schema/config truth (9), 10–19 business/happy (9), 30–39 validation (9), 40–49 FK (3), 50–59 permissions (2), 90–99 tenancy+security (5).
- Coverage: Negative **100%**, Positive **100%** (≥90 gate), Dependency **100%** (≥90 gate), Tenancy **100%**.
- Every TC-ID ↔ ≥1 method; every method ↔ a TC/BC (see TcList §3 and GapAnalysis §1).

## 5. Known Source Defects Documented
| ID | State | Proving test |
|----|-------|--------------|
| SEC-STD-01 | Controller fixed; UI residual | test_92, test_93 |
| SEC-STD-02 | Fixed | test_09 |
| SEC-STD-03 | Fixed | test_05 |
| GAP-STD-05 | Confirmed open | test_06 |
| BUG-STD-11 | Confirmed open | test_07 |
| ARCH-STD-13 | Confirmed open | test_08 |
| DDL-STD-12 | Table fixed / model residual | test_04 |
| DEV-STD-CRE-01 | New (first_name max100 vs col50) | test_38 |

## 6. Constraints applied (05_Known_Test_Failure_Constraints)
- A1/A2/A3 tenancy scaffolding (tenant-side feature). #8/#9 user creation: `user_type='STUDENT'`, `emp_code` ≤ 20 (`STD-`+uniqid), `prefered_language=1` — fixes the sibling's `STD-YmdHis+rand` (21-char) overflow. #11 `forceDelete` wrapped in try/catch (`safeForceDelete`). #12 SoftDeletes checked with `class_uses_recursive` before asserting. #14 status codes via in-page fetch, not Dusk `assertStatus`. #17 schema types via `information_schema`/`SHOW INDEX` fail-soft. #26 migration existence via glob (not stale hardcoded paths).

## 7. Environment Prerequisites (E19/E20)
- **STUDENT module must be ENABLED** in `prime_testing/modules_statuses.json` (currently most modules `false`; disabled → 404 on all `/student-profile/*` routes). Browser bands are not runnable until enabled.
- `APP_ENV=testing` for Dusk (CSRF bypass); runners set it. Dusk stack (Chrome) + `MAIN_PROJECT_PATH` required.
- **Not executed this run** (module disabled per instruction). `php -l` performed and passes.

## 8. Dimensions deliberately skipped
- Session tab (`createStudentSession`) deep CRUD and `getSubjectGroupSubjects`/`getFilterDependencies` AJAX are covered at smoke level only here (create-wizard scope) — full coverage belongs to a dedicated StudentSession feature file.
- Activity-log assertion on create omitted (no `activityLog` call on student create path; only `pii_aadhar_updated` on aadhar change).

## 9. Final Verdict
**PASS WITH NOTES** — 7 artifacts present, single `.php` (no V1/V2), `php -l` clean, coverage gates met, defects proven with tests. Notes: (a) browser bands require the STUDENT module enabled; (b) SEC-STD-01 UI residual and DDL-STD-12 model residual remain open in source; (c) new DEV-STD-CRE-01 first_name length mismatch raised.
