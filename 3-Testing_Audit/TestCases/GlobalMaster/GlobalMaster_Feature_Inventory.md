# GlobalMaster — Feature Inventory

**Module:** GlobalMaster · **Code:** GLB · **Registry prefix:** `glb_` · **Folder:** `Modules/GlobalMaster` · **DDL:** `_global_db_v4.sql` (registry `_global_db_` → auto-corrected to `_global_db_v4.sql`)
**Generated:** 2026-Jul-10 · **Run mode:** module → report
**DB scope:** **CENTRAL / prime-side** (global + central `sys_` tables; connection `global_master_mysql` / `mysql`; served on the central domain). Browser Dusk tests run on **http://127.0.0.1:8000** and mirror the committed **Prime/Billing central pattern** (`prm_BillingDuskTestCase` / `prm_BillingCycle_TestCas`). **No tenant scaffolding** (no `initializeTenantContext`, no `tenancy()->initialize`).

## Basis for the feature list (no requirement folder exists)
There is **no** `GlobalMaster_v1` requirement-screen folder. The feature list was derived from **real registered `central.global-master.*` (and `central.prime.*`) routes** in `prime_ai/routes/web.php`, cross-checked against the module controllers/views and the `_global_db_v4.sql` / `_prime_db_v4.sql` DDLs. Five screens are in scope.

## Feature table (in-scope, generated)

| # | Screen (route/path) | Feature | Primary table | DDL-verified prefix | Live controller (HARD RULE 13) | Type | Output folder |
|---|---------------------|---------|---------------|---------------------|--------------------------------|------|---------------|
| 1 | `/global-master/country` (`central.global-master.country.*`, also `/prime/country`) | **Country** | `glb_countries` | **`glb_`** | `Modules\GlobalMaster\Http\Controllers\CountryController` (module-owned) | CRUD + soft-delete + toggle (cascades to states/districts) | `Country/` |
| 2 | `/global-master/language` (`central.global-master.language.*`) | **Language** | `glb_languages` | **`glb_`** | `Modules\Prime\Http\Controllers\LanguageController` (Prime serves central; GlobalMaster's own is a dead duplicate) | CRUD + soft-delete + toggle | `Language/` |
| 3 | `/global-master/dropdown` (`central.global-master.dropdown.*`) | **Dropdown** | `sys_dropdown_table` | **`sys_`** ⚠ (not `glb_`) | `Modules\Prime\Http\Controllers\DropdownController` (Prime serves central; GlobalMaster's own is dead) | Complex tabbed CRUD + junction | `Dropdown/` |
| 4 | `/prime/session-board-setup` (`central.prime.session-board-setup.*`) | **SessionBoardSetup** | `glb_academic_sessions` + `glb_boards` | **`glb_`** | `Modules\Prime\Http\Controllers\SessionBoardSetupController` (Prime serves central; GlobalMaster's own is dead) | Read-only composite (two lists) | `SessionBoardSetup/` |
| 5 | `/global-master/activity-log` (`central.global-master.activity-log.*`) | **ActivityLog** | `sys_central_activity_logs` | **`sys_`** ⚠ (not `glb_`; **no consolidated DDL** — schema from a central migration only) | `Modules\Prime\Http\Controllers\ActivityLogController` (Prime serves central; GlobalMaster's own is dead) | Read-only audit viewer + search | `ActivityLog/` |

⚠ **Prefix note (per DDL `CREATE TABLE` verification):** Country/Language/SessionBoardSetup tables live in the **global** DB (`glb_`). **Dropdown** (`sys_dropdown_table`) and **ActivityLog** (`sys_central_activity_logs`) live in the **central/prime** DB with the **`sys_`** prefix — the file prefixes for those two features are `sys_`, matching their primary tables, not the module registry's `glb_`.

## HARD RULE 13 reconciliation (central routes served by `Modules\Prime`)
The central route tree is `Route::domain(app.domain)->name("central.")` → `->prefix('global-master')->name('global-master.')` (and a parallel `->prefix('prime')->name('prime.')`). The global-master group is **defined three times** in `routes/web.php` (Laravel keeps the last), and several resources are wired to **Prime** controllers:
- **Country** → served by the module's own `GlobalMaster\CountryController` (the one genuinely GlobalMaster-owned screen).
- **Language / Dropdown / ActivityLog** → served by `Modules\Prime\*Controller`; the identically-named `Modules\GlobalMaster\*Controller` classes are registered only in the module's own `routes/web.php` under `global-master.*` (no `central.` prefix) and are **dead on the central domain**.
- **SessionBoardSetup** → served by `Modules\Prime\SessionBoardSetupController` at path **`/prime/session-board-setup`** (not under the global-master prefix).
- **Central audit sink** = `sys_central_activity_logs` (`Modules\Prime\Models\ActivityLog`, connection `mysql`); `activityLog()` writes there when tenancy is not initialized.

## Source screens NOT generated (explicit gaps — not invented)
The GlobalMaster module folder contains additional controllers/views that are **out of scope for this run** (the caller fixed the 5-feature list). They are listed here as known gaps, not features to fabricate:
- **State** (`glb_states`), **District** (`glb_districts`), **City** (`glb_cities`) — geography children of Country (served by GlobalMaster controllers under `central.*.state/district/city`).
- **GeographySetup / location-setup** (`GeographySetupController`) — the composite geography index the Country controller redirects to (`central.global-master.location-setup.index`).
- **Module** (`glb_modules`), **Plan** (`glb_...`/plans), **Organization** (`OrganizationController`), **Notification** (`NotificationController`), **GlobalMaster** (`GlobalMasterController` root resource + `routes/api.php` `globalmaster` apiResource), **AcademicSession** and **Board** as standalone CRUD screens (served under `central.prime.*` by Prime controllers), **DropdownNeed / Dropdown-Mgmt** (Prime).
- Module `tests/Unit/*` (ArchitectureTest, BoardTest, ControllerAuthTest, ModelStructureTest) are the app's own unit tests, not screens.

These are documented so the coverage picture is honest; generate them in a future run if in scope.

## Environment prerequisites (apply to every feature — see each Validation Report)
- `prime_testing/modules_statuses.json` currently has **GlobalMaster = false AND Prime = false** → all central routes 404 until both are enabled. Enable before running (env prerequisite, not a code fix).
- `APP_ENV=testing` (CSRF bypass; else 419). Run on `http://127.0.0.1:8000` (the central `prm_PrimeDuskTestCase` `fail()`s on any other host).
- Central DB reachable via connections `global_master_mysql` (glb_*) and `mysql` (sys_central_*).
