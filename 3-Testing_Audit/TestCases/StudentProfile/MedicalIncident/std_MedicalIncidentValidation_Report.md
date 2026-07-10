# std_ Medical Incident — Validation Report

**Feature:** StudentProfile / MedicalIncident · **Generated:** 2026-Jul-10 · **Prefix:** `std_` (verified against DDL `CREATE TABLE std_medical_incidents`)

---

## 1. File Existence Summary
| # | File | Present |
|---|------|---------|
| 1 | `std_MedicalIncidentTcList_Require.md` | ✅ |
| 2 | `std_MedicalIncidentMANUALTESTING_Require.md` | ✅ |
| 3 | `std_MedicalIncidentGAPANALYSIS_Require.md` | ✅ |
| 4 | `std_MedicalIncident_TestCas.php` | ✅ (ONE file — no V1/V2) |
| 5 | `std_MedicalIncidentValidation_Report.md` | ✅ |
| 6 | `run-MedicalIncident-tests.ps1` | ✅ |
| 7 | `run-MedicalIncident-tests.sh` | ✅ |

## 2. Naming Conventions
- Prefix `std_` matches the DDL primary table `std_medical_incidents` ✅ (NOT `spr_`).
- Feature PascalCase `MedicalIncident` ✅.
- Class name = filename: `class std_MedicalIncident_TestCas` ✅.
- Test methods snake_case, zero-padded, semantic bands `test_medical_incident_NN_*` ✅.

## 3. Structure Validation
- `namespace Tests\Browser;` ✅
- `extends DuskTestCase` ✅ (mirrors committed sibling `spr_MedicalIncident_TestCas.php`)
- `setUp()`/`tearDown()` with `initializeTenantContext()` + guarded `tenancy()->end()` ✅
- Typed properties initialised (`?User $adminUser = null`, string defaults) ✅
- `php -l` result: **No syntax errors detected** ✅

## 4. Coverage Completeness
- **Total test methods: 53.**
- Coverage: Negative **100%** · Positive **100%** (96% Full + 4% conditional-partial) · Dependency **100%** (86% Full + defensive) · Tenancy **100%** (1/1).
- Every TC-ID maps to ≥1 method; every method maps back to a TC/BC (see TcList §3 Method Index and Gap Analysis §1).
- No V1/V2 split; no method-ratio target — coverage-gated only.

## 5. Known Source Defects Documented
| DEV | Severity | Proving test | Where recorded |
|-----|----------|--------------|----------------|
| DEV-MI-01 (location max:255 vs VARCHAR(100)) | Med | test_70 | TcList §4, Gap §4 |
| DEV-MI-02 (action_taken max:512 vs VARCHAR(255)) | Med | test_71 | TcList §4, Gap §4 |
| DEV-MI-03 (update reported_by `exists:users,id`) | High | test_43 | TcList §4, Gap §4 |
| DEV-MI-04 (incident_type_id no DB FK) | Low | test_41/02 | TcList §4, Gap §4 |
| DEV-MI-05 (create student picker `is_active='true'`) | Med | Gap note | TcList §4, Gap §4 |
| DEV-MI-06 (index filters ignored) | Med | test_69 | TcList §4, Gap §4 |
| DEV-MI-07 (store/destroy redirect to attendance.bulk) | Low | test_16 | TcList §4, Gap §4 |

**GAP-STD-08 (audit "missing MedicalIncidentPolicy"):** verified FALSE for this screen — the policy file exists with all 8 abilities. Residual note: controller authorizes via Spatie ability-string gates, so the Policy is not invoked per-object. No P0/P1 defect is primarily owned by this screen.

## 6. Constraints applied (`05_Known_Test_Failure_Constraints.md`)
- A1/A2/A3 — tenant resolution via `Modules\Prime\Models\Domain`, guarded `tenancy()->end()` ✅
- A4 — tenant-side (`std_*`, tenant_db) → tenancy scaffolding emitted ✅
- B5/B7/B8/B9 — `App\Models\User` + `User::factory()` for temp/limited users; `user_type='EMPLOYEE'` override passed; factory sets emp_code/prefered_language ✅
- C11 — `forceDelete()` cleanup wrapped in `try/catch` (InteractsWithMedia → `sys_media`) ✅
- C12 — `withTrashed/onlyTrashed/forceDelete` used only because model uses `SoftDeletes` (verified) ✅
- C13 — all typed properties initialised ✅
- D14 — status codes captured via `sendJsonRequestFromBrowser` (browser fetch), never Dusk `assertStatus` ✅
- D15 — authenticated before every negative/validation POST ✅
- D16 — browse closures pass outer vars via `use(...)` ✅
- D17 — schema-type asserts via `Schema::hasColumn`/fail-soft, not exact COLUMN_TYPE ✅
- E19 — **module `STUDENT` must be ENABLED in `modules_statuses.json`** (currently most modules `false`; disabled → 404 on all routes). ENVIRONMENT PREREQUISITE — not a test-code fix.
- E20 — `APP_ENV=testing` for Dusk (CSRF bypass); runners set it.
- #26 — module-local migrations dir is empty; real migrations under `database/migrations/tenant/`; `test_01` reads them fail-soft via `File::exists` guard ✅
- #27 — incident_type FK target asserted as `sys_dropdown_table` (validation `exists:sys_dropdown_table,id`) ✅

## 7. Environment prerequisites (to actually run)
1. `STUDENT` module enabled in `prime_testing/modules_statuses.json` (currently disabled → **dusk was NOT run** per instruction; all routes would 404).
2. `APP_ENV=testing`, Chrome/Dusk driver, `MAIN_PROJECT_PATH` set, `prime_ai` cloned alongside.
3. Tenant DB seeded with ≥1 active student, a `MEDICAL_INCIDENT_TYPE` dropdown, and an active user.

## 8. Final Verdict
**PASS WITH NOTES.**
- Static: `php -l` clean; ONE test file; naming/structure conform; 53 methods; all coverage gates met.
- Dusk execution NOT performed (module `STUDENT` disabled — E19). Runtime green-ness pending module enablement + seed data.
- 7 documented DEV defects (1 High: DEV-MI-03) with proving tests; GAP-STD-08 rebutted for this screen.
