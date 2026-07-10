# Validation Report — MarksheetGeneration · Student Results & Print

## 1. File Existence Summary
| # | Artifact | Present |
|---|----------|---------|
| 1 | `msh_StudentResultsAndPrintTcList_Require.md` | ✅ |
| 2 | `msh_StudentResultsAndPrintMANUALTESTING_Require.md` | ✅ |
| 3 | `msh_StudentResultsAndPrintGAPANALYSIS_Require.md` | ✅ |
| 4 | `msh_StudentResultsAndPrint_TestCas.php` (ONE test file — no V1/V2 split) | ✅ |
| 5 | `msh_StudentResultsAndPrintValidation_Report.md` | ✅ |
| 6 | `run-StudentResultsAndPrint-tests.ps1` | ✅ |
| 7 | `run-StudentResultsAndPrint-tests.sh` | ✅ |

## 2. Naming Conventions
- Prefix `msh_` = DDL table prefix of primary table `msh_student_results` ✅ (verified vs `CREATE TABLE`).
- Feature PascalCase `StudentResultsAndPrint` ✅.
- Class name = filename: `class msh_StudentResultsAndPrint_TestCas` ✅.
- Methods snake_case, zero-padded, semantic bands `test_studentresult_NN_*` ✅.

## 3. Structure Validation
- `namespace Tests\Browser;` + `extends DuskTestCase` ✅.
- `setUp()`/`tearDown()` with tenancy init/guarded end ✅ (TENANT-side scope).
- Typed properties null-initialised (`?User $adminUser = null`) ✅.
- `php -l` → **No syntax errors detected** ✅.
- Rich private helper library (screenshots, JSON-from-browser, tenancy, permissions, seed/cleanup) ✅.

## 4. Coverage Completeness
- **Total test methods: 57.**
- Bands: 01-09 schema/config (9) · 10-19 business (10) · 20-29 state-machine (6) · 30-39 validation (10) · 40-49 integration/FK (6) · 50-59 permissions/security-defect (6) · 60-69 UI/UX (4) · 70-79 edge (3) · 90-99 tenancy/security (3).
- Coverage: Negative **100%**, Positive **100%** (≥90 ✅), Dependency **100%** (≥90 ✅), Tenancy P0/P1 **100%**.
- Every TC-ID ↔ ≥1 method; every method ↔ a TC/BC (see TcList §4, Gap Analysis §1).
- Activity-log event strings asserted verbatim from source: `Stored`, `Updated`, `Deleted`, `Withheld`, `Declared`.
- Selectors/routes/gates/empty-state strings sourced from real code (`results.blade`, partials, controllers, routes) — no invention.

## 5. Known Source Defects Documented
| ID | Sev | Where | Proving test |
|----|-----|-------|--------------|
| SEC-MSH-001 | P1 | `StudentResultController::create()` gate `.view` (should be `.create`) | test_51 |
| SEC-MSH-002 | P1 | `StudentResultController::store()` gate `.update` (should be `.create`) | test_52 |
| SEC-MSH-003 | P1 | `StudentResultRequest` / `WithholdStudentResultRequest` `authorize()`=`true` | test_09, test_53 |
| PERF-MSH-003 | P2 | Unbounded `Student::get()`/`Subject::get()` in results view | Documented (Gap §4) |
| PERF-MSH-004 | P3 | `wipePreviousResults()` hard-deletes soft-deletable rows on recompute | Documented (Gap §4) |

## 6. Environment Prerequisites (05_ constraints obeyed)
- Module **MarksheetGeneration must be enabled** in `prime_testing/modules_statuses.json` — else all routes 404 (env prereq, not a test-code fix).
- `APP_ENV=testing` for Dusk runs (CSRF bypass; runners set it).
- Tenant seed data required: active **unlocked** `msh_marksheet_schedules`, a `sch_class_section_jnt`, and a `std_students` row — absent → tests `markTestSkipped` (defensive).
- `05_` compliance: `use App\Models\User;` + factory pattern; `emp_code` suffix short; Dusk `Browser` has no `assertStatus` → HTTP-from-browser `fetch` helper used; `actingAs`/authenticated before negative POSTs; `use(...)` in closures; MySQL8 type variance handled via `SHOW INDEX`/`Schema::has*`; `forceDelete()` wrapped in try/catch; SoftDeletes guarded (ComputationLog immutable path asserted to throw).
- Module `routes/api.php` is unregistered (`RouteServiceProvider::map()` calls only `mapWebRoutes()`) — no api-route assertions made (05_ E23).
- **Note (per-feature):** the module ships NO per-module migration files (`database/migrations/` empty); schema is applied via the consolidated tenant DDL. `test_01` therefore asserts schema truth via `Schema::hasTable/hasColumns` + `SHOW INDEX` + the (existing) FormRequest file, and does NOT assert a migration file (which would false-fail).

## 7. Final Verdict
**PASS WITH NOTES.**
Notes: (a) SEC-MSH-001/002/003 tests assert the *current, defective* gate/authorize behaviour on purpose (proving tests) — they will need inverting once the source is fixed; (b) PERF-MSH-003/004 are documented, not automated; (c) execution requires the module enabled + tenant seed data; without them the suite skips rather than fails. `php -l` clean; one comprehensive `.php` file; coverage gates met.
