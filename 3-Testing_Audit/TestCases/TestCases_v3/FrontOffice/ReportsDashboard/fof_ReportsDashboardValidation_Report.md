# FrontOffice ── ReportsDashboard — Validation Report

## 1. Static validation
| Check | Result |
|-------|--------|
| `php -l fof_ReportsDashboard_TestCas.php` | **No syntax errors detected** |
| `php -l run-ReportsDashboard-tests.php` | **No syntax errors detected** |
| Class name == filename | `fof_ReportsDashboard_TestCas` ✔ |
| One suite / one file | ✔ |
| Namespace | `Tests\Browser\Modules\FrontOffice\ReportsDashboard` (mirrors sibling convention) |

## 2. Rule-Card compliance (05_)
| Rule | Applied |
|------|---------|
| #1–#4 tenancy | Tenant-side: `initializeTenantContextForTests()` via `Modules\Prime\Models\Domain` in `setUp`; guarded `tenancy()->end()` in `tearDown` |
| #5 users/factory | `Modules\SchoolSetup\Models\User::factory()` (mirrors `Complaint/CmpDashboard` sibling) |
| #13 typed props | `private string $tenantBaseUrl = ''` initialized |
| #14 Dusk has no assertStatus | Status/route facts asserted via `Route::has()`; browser flows via `assertPathIs`/`assertSee`/`assertPresent` |
| #19 module enabled | Documented as env prereq (FrontOffice DISABLED) — see §4 |
| #31 / #37 permission negatives | `restrictedUser()` strips super-admin flags + `syncRoles([])`/`syncPermissions([])` + `forgetCachedPermissions()`, then asserts 403; non-super-admin required because `Gate::before` grants Super Admin all |
| #40 no hand URLs/selectors | Paths derived from module route prefix `front-office`; gate strings grepped per method; selectors/labels taken from real Blade |
| F33 real assertions | Every method has ≥1 real assertion or `markTestSkipped` |
| F34 real methods | Only real Dusk/PHPUnit/Route methods used |

## 3. Coverage summary
- **21 test methods** — structure(1), render(6), filter(6), export-absent(1), empty-state(2), permission/auth(5).
- No create/edit/delete/duplicate matrix (light read-only screen, per task scope + Fact Pack §7).
- Export category proven **absent** (`TC_X01`) rather than invented (F40).

## 4. Environment prerequisites (MUST be satisfied to run green)
1. **FrontOffice = `true` in `prime_testing/modules_statuses.json`** — module is DISABLED by default (Rule Card #19). While disabled, all `/front-office/*` routes 404 and `Route::has()` returns false → every test fails/errors. **This is an env prerequisite, not a test-code bug.**
2. `APP_ENV=testing` (Dusk CSRF bypass, #20).
3. `DUSK_TENANT_URL` set to a resolvable tenant domain present in `prm_domains`/`Domain` (else `setUp` `markTestSkipped`).
4. Tenant `sys_users` seeded so `User::factory()` can build users; the 8 gate abilities creatable in the tenant permission table (best-effort `firstOrCreate`).
5. ChromeDriver aligned with the installed Chrome; run `php artisan route:clear` if routes were cached.
6. `sys_media` may be absent (#11) — not exercised by this read-only screen, so no impact here.

## 5. Tolerances applied
- 403 page text asserted as the stable token `'403'` only (sibling pages vary between "Forbidden" / "THIS ACTION IS UNAUTHORIZED").
- Empty-state asserted structurally (`#purposeChartEmpty`/`#trendChartEmpty` always in DOM) so the test is independent of current tenant data volume.
- Data-dependent table rows are not asserted (non-deterministic); headings + no-error render asserted instead.

## 6. Defects
- No P0/P1 defect originates in this screen. **PERF-FOF-001 (P2)** touches it indirectly (unbounded aggregations in menu pages) — documented, render-success only. No new `DEV-###` raised.

## 7. How to run
```
php run-ReportsDashboard-tests.php
php run-ReportsDashboard-tests.php --filter=test_TC_N02_dashboard_403_without_visitor_view
```
Runner copies the suite into `prime_testing/tests/Browser/Modules/FrontOffice/ReportsDashboard` and invokes `php artisan dusk`. Set `PRIME_TESTING_PATH` if the runner root is not auto-detected.
