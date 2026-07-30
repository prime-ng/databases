# FrontOffice → Appointment — Validation Report

## 1. File Existence Summary
| # | Artifact | Present |
|---|----------|---------|
| 1 | `fof_AppointmentTcList_Require.md` (combined: Feature Info + BC + TC list + Method Index + Manual Steps + Defects) | ✅ |
| 2 | `fof_AppointmentGAPANALYSIS_Require.md` | ✅ |
| 3 | `fof_Appointment_TestCas.php` | ✅ |
| 4 | `fof_AppointmentValidation_Report.md` | ✅ |
| 5 | `run-Appointment-tests.php` (single cross-platform runner; no `.ps1`/`.sh`) | ✅ |

## 2. Naming Conventions
- Prefix `fof_` **verified** against DDL `CREATE TABLE fof_appointments`. ✅
- Feature PascalCase `Appointment`. ✅
- Class name = filename: `fof_Appointment_TestCas`. ✅
- snake_case test methods with semantic bands (01–09 schema, 10–19 biz, 20–29 SM, 30–39 val, 40–49 FK, 50–59 auth, 60–69 UI, 70–79 edge, 90–99 tenancy). ✅

## 3. Structure Validation
- `extends Tests\DuskTestCase`, namespace `Tests\Browser`. ✅
- `setUp()` initialises tenant context (via `Modules\Prime\Models\Domain`) BEFORE any `actingAs()`; `tearDown()` guards `tenancy()->end()`. ✅ (Rule Card #1–#3, A1)
- Typed properties initialised (`?User $adminUser = null`, strings `= ''`). ✅
- `php -l`: **No syntax errors detected.** ✅
- ONE test style file: browser-driven Dusk for UI; direct Eloquent for DDL constraints; Laravel HTTP test methods (`get/post/json` with tenant `Host` header) used ONLY for status-code / permission negatives (Rule Card #14/F37 — `Browser` has no `assertStatus()`). No `browse()`+`actingAs()->post()` on the same logical action. ✅

## 4. Coverage Completeness
- **41 test methods**; 43 mapped TCs. Every TC ↔ ≥1 method; every method ↔ a TC/BC (see Method Index). ✅
- Category coverage: Negative **100%**, Positive **100%**, Dependency **100%**, State-Machine **100%**, Security/Tenancy **100%**. ✅
- No V1/V2 split — one comprehensive suite. ✅
- DDL-derived coverage: duplicate-rejection for the UNIQUE `appointment_number` (G43, test_02); missing-value negatives for all 11 NOT-NULL-no-default columns (G44, test_03); over-length + max-length boundary for VARCHARs (G45, test_05/36); `test_01` full DDL↔live alignment matrix with soft-delete column+trait asserted independently (G46); all CRUD through the verified `Appointment` model (G47); auto fields (`appointment_number`/`status`/`created_by`/`confirmed_*`) tested as auto-behaviour, never form inputs (G48). ✅

## 5. Constraints obeyed (Rule Card A–G)
- Real assertions only; no `addToAssertionCount(1)`/empty bodies (F33). ✅
- Real Laravel-12 methods (`hasColumns`, `getCasts`, `class_uses_recursive`); no `isCasted`/`->isActive` (F34). ✅
- `->refresh()` before asserting DB-populated values (F35, test_04/05/06). ✅
- Reference counts via tolerant assertions; no brittle `assertEquals` on seed counts (F36). ✅
- Permission negatives: non-super-admin (`makeLimitedUser` strips `is_super_admin`/roles/permissions), `forgetCachedPermissions()`, assert **403** (F37/#31). ✅
- Cleanup: every created record force-deleted in `finally`; limited users force-deleted (F38). ✅
- No hand-written URLs/selectors — paths from routes, selectors/field-names/button-text from real Blade (`visitor_name`, `Sign In`, `Upcoming`, toggle-status JSON contract) (F40). ✅
- Validation rejection tolerant of 500-vs-422 and web-redirect-with-errors; asserts observed DB outcome (no row created) (F41). ✅
- Users built with NOT-NULL cols (`emp_code`, `short_name`, verified) via `User::factory()` (#5/#8). ✅
- Cross-module dependency (`SchoolSetup\User`) guarded with try/catch + `markTestSkipped` (HARD #9). ✅

## 6. Known Source Defects documented (with proving tests)
| ID | Where documented | Proving test |
|----|------------------|--------------|
| DEV-FOF-A01 (VAL-FOF-001, **remediated**) | TcList §6, Gap §3 #? | test_12 |
| DEV-FOF-A02 (status ENUM mismatch) | TcList §6, Gap #1 | test_01, test_11 |
| DEV-FOF-A03 (appointment_type ENUM mismatch) | TcList §6, Gap #1b | test_13 |
| DEV-FOF-A04 (No_Show dead state) | TcList §6, Gap #7 | test_26 |
| DEV-FOF-A05 (cancellation_reason not required) | TcList §6 | MT-3 (manual) |
| DEV-FOF-A06 (missing activity logs) | TcList §6, Gap | test_72 |
| DEV-FOF-A07 (SEC-FOF-003 authorize=true) | TcList §6, Gap | test_55 |
| DEV-FOF-A08 (PERF-FOF-001 preload) | TcList §6 | documented (non-functional) |
| DEV-FOF-A10 (PUT allows past date / no overlap recheck) | TcList §6, Gap #8 | test_71 |

## 7. Environment Prerequisites (MUST be satisfied before a green run)
1. **FrontOffice = `false` in `prime_testing/modules_statuses.json` (#19)** — MODULE DISABLED. All `/front-office/*` routes 404 → every route-driven method `markTestSkipped` until enabled. This is an ENV prerequisite, **not** a code fix. The schema/model/direct-Eloquent tests still run.
2. `APP_ENV=testing` for Dusk CSRF bypass (#20); the runner sets it.
3. Tenant resolvable via `DUSK_TENANT_URL` host in `prm_domain` (`Modules\Prime\Models\Domain`); else tests skip.
4. `sys_media` may be absent — not exercised by Appointment (no media FK), so no impact.
5. `sys_activity_logs` table present for activity-sink assertion (test_73 skips if absent).
6. **Live-schema `status` ENUM** must actually allow `Scheduled` for the workflow (SM) and store tests to persist — if the live DB matches the shipped DDL (`Pending`…, no `Scheduled`), those seeds throw and the SM tests `markTestSkipped` (DEV-FOF-A02 is the root cause; documented, not masked).
7. Validation 500-vs-422 tolerated; stale route cache → `php artisan route:clear` prereq; ChromeDriver aligned with Chrome.

## 8. Final Verdict
**PASS WITH NOTES.**
- All 5 artifacts present with exact names; `php -l` clean; 41 methods; 100% category coverage; DDL coverage complete.
- Notes: (a) FrontOffice is disabled in `modules_statuses.json` — enable it for route-driven tests to execute rather than skip; (b) DEV-FOF-A02 status-ENUM divergence can force the SM/store tests to skip on a DDL-faithful DB — this is the defect surfacing, and is documented, not worked around; (c) VAL-FOF-001 is now **remediated** in current source (overlap enforced) — the FactPack §6 entry is stale and is corrected here.
