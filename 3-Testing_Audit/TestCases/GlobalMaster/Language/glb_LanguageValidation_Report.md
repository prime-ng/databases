# GlobalMaster :: Language — Validation Report (`glb_`)

- Screen: **Language** (GlobalMaster / CENTRAL, prime-side)
- Test file: `glb_Language_TestCas.php` (ONE comprehensive Dusk file)
- Class: `Tests\Browser\Modules\GlobalMaster\Language\glb_Language_TestCas extends \Tests\DuskTestCase`
- Live path: `/global-master/language` @ `http://127.0.0.1:8000`

---

## 1. Static validation

| Check | Result |
| --- | --- |
| `php -l` syntax | ✅ **No syntax errors detected** |
| Single `.php` test file (no V1/V2) | ✅ one file only |
| Namespace | ✅ `Tests\Browser\Modules\GlobalMaster\Language` |
| Extends framework Dusk case | ✅ `extends \Tests\DuskTestCase` |
| Central helper library inline | ✅ centralUrl / authenticateCentral / visitAuthenticated / ensurePageAccessible / browseWithFailureScreenshot / captureFailureScreenshot / resolveAdminUser / currentPath / confirmSweetAlert / click* / sendJsonRequestFromBrowser |
| Typed props initialized | ✅ `?User $adminUser=null`, `string $centralBaseUrl=''`, `string $adminEmail=''`, `string $adminPassword=''`, `array $statusReportEntries=[]` |
| setUp/tearDown guard tenancy | ✅ `tenancy()->end()` if initialized; NO tenant init |
| Automated test methods | ✅ **40** (`test_language_*`) |
| Prefix | ✅ `glb_` |

---

## 2. Environment prerequisites (document — do NOT code-fix)

| Prereq | Requirement | Failure mode |
| --- | --- | --- |
| Module status | **GlobalMaster AND Prime** = `true` in `modules_statuses.json` | If either `false` → route 404 |
| App env | `APP_ENV=testing` | Wrong env may alter gates/seeded data |
| Host | `http://127.0.0.1:8000` (Dusk/ChromeDriver) | `setUp` fails fast if host ≠ 127.0.0.1 |
| DB | `glb_languages` migrated on `global_master_mysql`; central `sys_central_activity_logs` present | Schema TCs fail if table missing |
| Admin auth | super-admin (or `prime.language.*`) exists / auto-provisioned via `resolveAdminUser` | `ensurePageAccessible` fails on 403 |
| Central DB view | migration also creates a `glb_languages` VIEW on the default `mysql` connection | tests query the base table via `global_master_mysql` |

---

## 3. 05_ constraint compliance

| Constraint | Status |
| --- | --- |
| `App\Models\User` + factory; password fillable | ✅ used in `resolveAdminUser` |
| Browser has NO `assertStatus` → use `getJson`/`postJson`/`deleteJson` | ✅ TC-39, TC-51, TC-92 use `get`/`getJson` |
| Guard `forceDelete` cleanup | ✅ `purgeLanguageById` deletes trashed+active rows and orphan activity logs in `finally` |
| `assertStringContainsString` for schema types | ✅ TC-05 (varchar), TC-06 (enum) |
| Typed props initialized | ✅ |
| No tenancy scaffolding | ✅ central-only; tenancy ended in setUp |

---

## 4. HARD RULE 13 reconciliation (recorded prominently)

> The LIVE central route `central.global-master.language.*` (path
> `/global-master/language`) is served by **`Modules\Prime\Http\Controllers\LanguageController`**
> (registered in app-root `routes/web.php` inside the `central.` domain group),
> **NOT** by the GlobalMaster module's own `LanguageController`, which is only
> wired under `global-master.language.*` in `Modules/GlobalMaster/routes/web.php`
> and is therefore **dead on central**. Both share
> `Modules\GlobalMaster\Http\Requests\LanguageRequest` and
> `Modules\Prime\Models\Language` → `glb_languages`. Tests target the live path.

---

## 5. Defect validation (verify in source)

| ID | Assertion in test | Source location | Verdict |
| --- | --- | --- | --- |
| DEV-GLB-L01 | `deleted_at`, `created_at`, `updated_at` columns exist though DDL omits them | migration `2025_11_10_061519_create_languages_table.php` vs `_global_db_v4.sql` ~L196-204 | **Confirmed** (docs divergence, not runtime) |
| DEV-GLB-L02 | force delete logs literal event `'Stored'` | Prime `LanguageController::forceDelete()` L132; GlobalMaster dup L123 | **Confirmed** |
| DEV-GLB-L03 | dead controller mixes `prime.*`/`global-master.*` gates; `update()` flashes `'update.language'` | GlobalMaster `LanguageController` L69/L79/L96/L103/L117/L135 | **Confirmed (dead path)** |
| DEV-GLB-L04 | two controllers → one request + model | Prime + GlobalMaster `LanguageController` | **Confirmed** |

---

## 6. Execution (do NOT run here)

Run via the provided runners (host must be up, ChromeDriver available):

```bash
./run-Language-tests.sh          # macOS / Linux
```
```powershell
.\run-Language-tests.ps1          # Windows
```

Both invoke Dusk with `--filter=glb_Language_TestCas`.

---

## 7. Result

| Item | Value |
| --- | --- |
| Files produced | 7 |
| PHP test files | **1** (`glb_Language_TestCas.php`) |
| `php -l` | **clean** |
| Automated methods | **40** |
| GLB defects documented | DEV-GLB-L01, L02, L03, L04 |
| Reconciliation | Prime serves `central.global-master.language.*` (documented) |
