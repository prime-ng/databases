# Country (GlobalMaster / CENTRAL) — Validation Report

- **Feature**: Country — GlobalMaster module (prime-side / CENTRAL)
- **Test file**: `glb_Country_TestCas.php` (single comprehensive class — no V1/V2)
- **Test class**: `Tests\Browser\Modules\GlobalMaster\Country\glb_Country_TestCas`
- **Extends**: `\Tests\DuskTestCase`
- **Method count**: **46** test methods
- **`php -l`**: PASS (no syntax errors — PHP 8.4)
- **DDL-verified prefix**: `glb_`
- **Generated**: 2026-07-10

---

## 1. Static validation performed

| Check | Result |
| --- | --- |
| `php -l glb_Country_TestCas.php` | **No syntax errors detected** |
| Exactly ONE `.php` file in output dir | **Confirmed** (no V1/V2 split) |
| Namespace / class naming | `Tests\Browser\Modules\GlobalMaster\Country\glb_Country_TestCas` |
| Typed props initialized | `?User $adminUser = null`, typed strings/array initialized |
| `setUp`/`tearDown` present | Yes; `tearDown` guards tenancy (`tenancy()->end()` if initialized) |
| No tenant init / no tenancy scaffolding | Confirmed — central pattern only |
| Central helpers copied INLINE | `centralUrl`, `authenticateCentral`, `visitAuthenticated`, `ensurePageAccessible`, `browseWithFailureScreenshot`, `captureFailureScreenshot`, `resolveAdminUser`, `currentPath`, `confirmSweetAlert`, `clickEdit/Delete/Restore/ForceDelete`, plus `sendJsonRequestFromBrowser` |
| Host guard | `setUp()` fails unless host is `127.0.0.1` |
| Uses `App\Models\User` + factory-style create | Yes (`User::create`, password fillable) |
| No `assertStatus` on Browser | Confirmed — status/JSON via `getJson`/`postJson`/`assertNotFound`/`assertForbidden` |
| `forceDelete` cleanup wrapped in try/catch | Yes (`purgeCountryById`, `purgeGlobal`, `purgeUser`) |
| Schema type asserts use `assertStringContainsString('int', …)` | Yes (guarded `safeColumnType`) |
| `emp_code` ≤ 20 | Yes (`'EMP' . rand(100,999)`) |

> **Not executed here**: browser runs require a live Chrome/Dusk environment and the two modules
> enabled. This report is a static + source-cross-reference validation only.

---

## 2. Source cross-reference (assert-against, never invented)

| Asserted fact | Verified against |
| --- | --- |
| Table `glb_countries`, connection `global_master_mysql`, fillable `[name,short_name,global_code,currency_code,is_active]`, SoftDeletes | `Country.php` model |
| Columns + 3 UNIQUE keys + FK RESTRICT | `_global_db_v4.sql` (glb_countries block, lines 13-27) |
| `softDeletes()` + `timestamps()` + `->unique()` + `global_master_mysql` | migration `2025_10_09_042528_create_countries_table.php` |
| Rules: name req/str/max:50/unique-ignore, short_name max:10, global_code max:10, currency_code max:8, default_timezone max:64, is_active required\|boolean; authorize true; `'on'`→bool | `CountryRequest.php` |
| Gates viewAny/view/create/update/delete/restore/forceDelete = `prime.country.*` | `CountryPolicy.php` + controller `Gate::authorize` |
| Activity events Stored/Updated/Trashed/Restored/Deleted/Toggled | `CountryController.php` `activityLog()` calls |
| toggleStatus cascade to states+districts + JSON `{success,is_active,message}` | `CountryController::toggleStatus()` |
| Selectors (edit/delete/restore/force/status/SweetAlert) | `action.blade.php`, `index/trash.blade.php` |
| Redirects to `location-setup.index#country` / `country.trashed` | controller |

---

## 3. Documented defects reproduced by tests

| ID | Severity | Proving method | Expected observation |
| --- | --- | --- | --- |
| **DEV-GLB-C01** | High | `test_country_36_duplicate_short_name_raises_db_error` | Duplicate `short_name` throws `QueryException` (no validation guard). |
| **DEV-GLB-C02** | Minor | `test_country_43_default_timezone_is_a_dead_rule` | `default_timezone` absent from schema and fillable → dead rule. |
| **DEV-GLB-C03** | Medium | `test_country_16_toggle_status_cascades_to_children` | Status cascades to children; only country logged as `Toggled`. |

---

## 4. Environment prerequisites (blockers, NOT code fixes)

1. **Enable modules**: set `"GlobalMaster": true` **and** `"Prime": true` in
   `prime_testing/modules_statuses.json`. Both are currently `false`, which makes every
   `/global-master/country` route return **404** — the suite cannot pass until enabled.
2. **`APP_ENV=testing`** — required for the toggle-status CSRF bypass / JSON assertions.
3. **Host** = `http://127.0.0.1:8000` (the suite `setUp()` fails fast on any other host).
4. **DB**: `global_master_mysql` reachable and migrated; `glb_countries.deleted_at` present;
   `glb_states` / `glb_districts` present for the cascade + FK tests (those tests self-skip if absent).

The runners (`run-Country-tests.sh` / `.ps1`) export `APP_ENV=testing`, clean stale screenshots,
run `php artisan dusk --filter=glb_Country_TestCas`, tee to a timestamped `proof/` log, print a
Tests/Assertions/Failures summary, and exit with the Dusk exit code.

---

## 5. Expected run shape (once env is satisfied)

| Band | Methods | Nature |
| --- | --- | --- |
| 01-09 | 9 | Pure schema/model/request/policy assertions (no browser) — fastest, most deterministic |
| 10-17 | 8 | Browser + DB business flows + activity-log assertions |
| 30-39 | 10 | Validation / negative (browser + one model-level DB defect proof) |
| 40-45 | 6 | Lifecycle + FK/dependency (mostly model/DB level) |
| 50-52 | 3 | Permissions (browser + HTTP) |
| 60-63 | 4 | UI (pagination, ordering, trash, listing) |
| 90-95 | 6 | Security pack (XSS, IDOR, mass-assignment, auth) |

**Total: 46 methods.** Config-band tests (01-09, 43, 45, 61, 92, 93) run without a browser session
and remain green even before the dev server is reachable, giving fast structural feedback.

---

## 6. Verdict

- Structure, naming, idiom, and selectors **mirror** the golden central Dusk reference.
- All assertions are **traceable to real source** (controller/request/model/policy/migration/DDL/views).
- The 3 GlobalMaster defects are **documented and each has a proving test**.
- File is syntactically valid and self-contained; exactly **one** `.php` test file was produced.

**Status: READY** (pending env enablement + live browser run).
