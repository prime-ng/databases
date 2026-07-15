# MarksheetGeneration — Dashboard & Navigation — Validation Report

## 1. File Existence Summary
| # | File | Present |
|---|------|---------|
| 1 | `msh_DashboardTcList_Require.md` | ✅ |
| 2 | `msh_DashboardMANUALTESTING_Require.md` | ✅ |
| 3 | `msh_DashboardGAPANALYSIS_Require.md` | ✅ |
| 4 | `msh_Dashboard_TestCas.php` | ✅ (ONE test file — no V1/V2 split) |
| 5 | `msh_DashboardValidation_Report.md` | ✅ (this file) |
| 6 | `run-Dashboard-tests.ps1` | ✅ |
| 7 | `run-Dashboard-tests.sh` | ✅ |

## 2. Naming Conventions
- Prefix `msh_` — verified against DDL `CREATE TABLE msh_*` (`MarksheetGeneration_DDL_v1.sql`, `Database: tenant_db`). Composite screen: **owns no primary table**, aggregates `msh_*`.
- Feature PascalCase: `Dashboard`.
- Class = filename: `class msh_Dashboard_TestCas` ✅.
- Namespace `Tests\Browser` ✅.
- Methods snake_case + semantic bands: `test_dashboard_NN_*` ✅.

## 3. Structure Validation
- `extends DuskTestCase` ✅; `use App\Models\User;` + factory ✅.
- `setUp()` / `tearDown()` with tenant init + guarded teardown (`function_exists('tenancy') && tenancy()->initialized`) ✅.
- Typed properties null-initialised (`?User $adminUser = null` etc.) ✅.
- `php -l`: **No syntax errors detected** ✅.
- Method count: **44** (39 mapped TCs; 5 config/wiring truth methods).

## 4. Coverage Completeness (composite / read-focused — no CRUD matrix)
| Category | % |
|----------|---|
| Positive (render/nav/widgets/UX) | 100% |
| Negative (guest/permission/dead-API) | 100% |
| Dependency (integration/perf) | 100% |
| Tenancy | 100% |

- Every TC-ID ↔ ≥1 method; every method ↔ a TC/BC (see Gap Analysis §1, TcList §3).
- No V1/V2 ratio applies (single-file, coverage-gated).

## 5. Known Source Defects Documented
| Defect | Sev | Proving method(s) | Where documented |
|--------|-----|-------------------|------------------|
| **BUG-MSH-001** — dead `apiResource('marksheetgenerations')` (unregistered + no controller REST methods) | P0 | `test_dashboard_58` (Route::has false + provider maps web-only + api.php still declares it), `test_dashboard_59` (method_exists false), `test_dashboard_72` (getJson ∈ {401,403,404,405,500}) | TcList §1, Gap §3 (checks 2 & 11) |
| **PERF-MSH-003** — unbounded `Student::get()` + `Subject::get()` in `results()` | P2 | `test_dashboard_46` (source proof + page renders) | Gap §3 |
| **D39-MSH** — msh gates unseeded (super-admin only) | P1 | `test_dashboard_52..56` (denial), grant helper (positive determinism) | §6 prereqs, Gap §3 (check 10) |

## 6. Environment Prerequisites (E19/E20/E23)
- `MarksheetGeneration` must be **ENABLED** in `prime_testing/modules_statuses.json` (else 404 on all routes).
- `APP_ENV=testing` for Dusk (bypasses CSRF).
- Tenant reachable at `DUSK_TENANT_URL`; admin `root@tenant.com`/`password`.
- D39-MSH: msh gates unseeded — the suite grants the 5 view gates to the admin so positive tests are deterministic; denial tests skip cleanly if a limited user cannot be provisioned or a super-admin bypass leaks.
- E23 honoured: the module `routes/api.php` is not registered (`map()` maps web-only) — the API is probed as a **dead** route, never asserted as a live contract.

## 7. Constraints obeyed (`05_`)
- A1-A4 tenant scaffolding (Domain resolve, guarded teardown) ✅.
- B5-B9 `App\Models\User` + factory; `emp_code` `'MSHL'.substr(uniqid(),-6)` ≤ 20; valid `user_type='EMPLOYEE'` + `prefered_language` ✅.
- C13 typed props null-init ✅.
- D14 no Dusk `assertStatus` — API status via `$this->getJson()` ✅; `actingAs`/`loginAs` before authenticated probes ✅.
- D16 `use(...)` in closures ✅; D17 MySQL8 → `assertStringContainsString` / accepted-status array ✅.
- E23 dead-API status set `{401,403,404,405,500}` ✅.

## 8. Dimensions deliberately skipped (with reason)
- **CRUD / validation / activity-log / FK-cascade** — N/A: read-only composite screen with no form inputs or mutations.
- **State machine (BC-SM)** — N/A: dashboard has no lifecycle.

## 9. Final Verdict
**PASS WITH NOTES.**
- 7 artifacts present; single `php -l`-clean test file (44 methods); coverage gates met for a composite read screen (Negative 100%, Tenancy 100%).
- Notes: (1) execution requires the module enabled + `APP_ENV=testing`; (2) D39-MSH permission-denial and cross-module tests are defensive (may skip in constrained envs); (3) BUG-MSH-001 (P0) and PERF-MSH-003 (P2) are proved as current-behaviour defects, not regressions to fix in test code.
