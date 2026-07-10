# GlobalMaster (GLB) — Feature Inventory

**Generated:** 2026-Jul-09
**Module registry (module_list.md):** MODULE_NAME=`GlobalMaster` · CODE=`GLB` · PREFIX(hint)=`glb_` · FOLDER_NAME=`GlobalMaster` · DDL_FILE_NAME(registry)=`_global_db_` → resolved DDL `2-DDL_Tenant_Consolidated/_global_db_v4.sql` (auto-corrected via glob).
**FRD:** `0-FRD_Documents/GLB_FRD_Complete_2026-06-29.md` (15 REQ / 34 BR / 3 RPT).
**Audit:** `3-Audit_Reports/V1_Jun-2026/GlobalMaster_Complete_Audit_2026-06-29.md` (Health 34/100, Deploy Gate NO-GO).

## DB Scope — CENTRAL (prime-side), NOT tenant-side

The DDL header reads `Global DB (global_db)` / `TABLE PREFIX: glb_`. The audit's Layer line confirms:
`CENTRAL — global_master_mysql → global_db (real tables) + default mysql → prime_db (VIEWs of every glb_* table)`.
Screens are registered in the app's **root** `routes/web.php` under the central group with name prefix `central.global-master.*` (the module's own `Modules/GlobalMaster/routes/web.php` `global-master.*` group is a duplicate registration — see DUP-WEB-001), permission gates use the `prime.*` prefix, and controllers redirect to `route('central.global-master.…')`.

**Consequences for test scaffolding (per `05_Known_Test_Failure_Constraints.md` §A4, E21, E22):**
- **No tenant init** — these are central tables; do NOT emit `initializeTenantContext()`/`tenancy()->initialize()`.
- **Host = `http://127.0.0.1:8000`** (NOT `test.localhost`). Mirror the committed **Prime/Billing** central Dusk pattern: `Tests\Browser\Modules\Prime\{…}`, extend the central base (`PrimeDuskTestCase` → `prm_PrimeDuskTestCase_TestCas`, forces `127.0.0.1`), use `authenticateCentral()` / `visitAuthenticated()` / `centralUrl()` / `resolveAdminUser()` (resolves `App\Models\User` by `is_super_admin`).
- **User model:** `App\Models\User` (runner) per constraint B5.

## Feature List (canonical source = registered routes + controllers + views + DDL)

> There is **no `GlobalMaster_v1` requirement screen folder** in `2-Module_Requirement_V1/` (the only GLB requirement source is the FRD + the audit). The feature list below is therefore derived from the **real registered `central.global-master.*` web routes** and their controllers/views/DDL — features are read from source, not invented.

**Order:** masters → composite/report last.

| # | Feature | Screen route base | Primary table | Prefix | Controller | Type | Output folder | Audit status |
|---|---------|-------------------|---------------|--------|-----------|------|---------------|--------------|
| 1 | Country | `central.global-master.country.*` | `glb_countries` | `glb_` | `CountryController` | CRUD master (parent of State→District→City) | `Country/` | PARTIAL — SEC-GLB-001, BUG-GLB-004 |
| 2 | Language | `central.global-master.language.*` | `glb_languages` | `glb_` | `LanguageController` | CRUD master | `Language/` | BROKEN/INSECURE — SEC-GLB-010, BUG-GLB-006, SEC-GLB-005 |
| 3 | Dropdown | `central.global-master.dropdown.*` | `sys_dropdown_table` (in `prime_db`) | `sys_` | `DropdownController` | CRUD master | `Dropdown/` | PARTIAL — VAL-GLB-001, BUG-GLB-005, BUG-GLB-009, PERF-GLB-001 |
| 4 | SessionBoardSetup | `central.global-master.session-board-setup.*` | `glb_academic_sessions` + `glb_boards` | `glb_` | `SessionBoardSetupController` | Composite hub (read) | `SessionBoardSetup/` | BROKEN — BUG-GLB-001 (AcademicSession model), empty `store()` |
| 5 | ActivityLog | `central.global-master.activity-log.*` | `sys_activity_logs` (in `prime_db`) | `sys_` | `ActivityLogController` | Read-only report/audit viewer | `ActivityLog/` | index ungated (SEC); MIG-GLB-001 dead migration |

## Screens present in source but NOT route-registered under `central.global-master.*` (coverage GAP — not live features)

The following controllers + Blade views + FormRequests exist but are **only** registered in the root `web.php` `prefix('prime')` group and/or the duplicate module `global-master` groups — the audit flags the naming/registration drift (SEC-GLB-005, DUP-WEB-001, BUG-GLB-005). They are recorded here as gaps, not generated as features, because their live route identity/permissions are inconsistent and several routed methods 500:

- **State** (`glb_states`) — routed, but `getStatesByCountry` method missing (BUG-GLB-005 → 500).
- **District** (`glb_districts`) — routed; `forceDelete` uses wrong permission (BUG-GLB-007).
- **City** (`glb_cities`) — routed; omitted from country-deactivation cascade (BUG-GLB-004).
- **AcademicSession** (`glb_academic_sessions`) — **BROKEN** (BUG-GLB-001, referenced by SessionBoardSetup).
- **Board** (`glb_boards`), **Module** (`glb_modules`), **Plan** (`prm_plans`) — registered under `prefix('prime')` (name `central.prime.*`), not `central.global-master.*`.
- **GeographySetup / location-setup** (composite geography hub) — `location-setup.search` routed but method presence unverified.
- **GlobalMasterController** (`api/v1/globalmasters` + `global-master` resource) — scaffold/stub controller, no real screen.

> These State/District/City/AcademicSession/Board/Module/Plan screens are the geography children of Country. They are candidates for a follow-up run once the audit's P0/P1 route-registration and missing-model defects (BUG-GLB-001, BUG-GLB-005, SEC-GLB-005, DUP-WEB-001) are fixed and their live route identity is deterministic.

## Known Source Defects mapped to generated features (from audit)

| Defect | Sev | Feature | Summary |
|--------|-----|---------|---------|
| SEC-GLB-001 | P1 | Country (+5 others) | `Country::create($request->all())` / `->update($request->all())` mass-assignment (should be `validated()`) |
| BUG-GLB-004 | P1 | Country | `toggleStatus` deactivation cascade updates States + Districts but **omits Cities** (BR-GLB-001) |
| SEC-GLB-010 | P0 | Language | `LanguageController` create/store/edit/update authorization gap (verify live: `index()` ungated) |
| BUG-GLB-006 | P1 | Language | imports `Modules\Prime\Models\Language` (wrong model); `forceDelete` logs event `'Stored'` (mislabeled); `update` flash is literal `'update.language'` not `flash('updated.language')` |
| SEC-GLB-005 | P1 | Language | destroy/restore/forceDelete/toggle gate `global-master.language.*` (prefix mismatch vs `prime.*` → likely 403/AuthorizationException) |
| VAL-GLB-001 | P1 | Dropdown | `DropdownRequest` validates only 2 of 5 fields → null `key`/`type` persisted |
| BUG-GLB-005 | P1 | Dropdown | `dropdown.search` route → controller method missing → 500 |
| BUG-GLB-009 | P2 | Dropdown | `org_id` conflated with user id; ordinal not scoped to `key`; mislabeled log/flash (`'A new module…'`) |
| PERF-GLB-001 | P2 | Dropdown | index N+1 |
| BUG-GLB-001 | P0 | SessionBoardSetup | `AcademicSession` model resolution (controller imports `Modules\Prime\Models\AcademicSession`; audit flags GLB-model absence → verify live 500) + empty `store()` |
| MIG-GLB-001 | P2 | ActivityLog | dead `activity_logs` migration; `sys_activity_logs` is the single real audit table |

## Environment prerequisites (Validation Reports must restate)

- `prime_testing/modules_statuses.json` currently has `"GlobalMaster": false` and `"Prime": false` → **all central routes 404 until enabled** (constraint E19). Enable `GlobalMaster` (and the Prime central host) before running.
- `APP_ENV=testing` for Dusk (CSRF bypass — constraint E20).
- Central host `http://127.0.0.1:8000` reachable (constraint E21).
