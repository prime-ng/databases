# Module Knowledge — GlobalMaster (GLB)

> **Single source of truth for the GlobalMaster module's accumulated knowledge.**
> Seeded 2026-06-29 by Business Analyst from live code (three-way reconcile: migration ↔ model ↔ controller/route), with the V2 Requirement (`GLB_GlobalMaster_Requirement.md`, 2026-03-26) read for intent. **All counts verified against the filesystem.** Where the live code contradicts V2, the live code wins and the divergence is flagged below.

---

## Module Facts

| Fact | Value | Source / Verification |
|---|---|---|
| Module name | GlobalMaster | `module.json` |
| Module code | GLB | `0-Prime_Ai_Detail/module_list.md` / conventions.md |
| Table prefix | `glb_` (also owns `prm_plans`, `media`, `activity_logs`; consumes `sys_dropdowns`, `sys_dropdown_needs`, `sys_activity_logs`) | migrations + models |
| Scope | **CENTRAL — GLOBAL DB layer.** Runs on the central domain; primary data in `global_db` via the **`global_master_mysql`** connection; secondary data in `prime_db` via default `mysql` connection. NOT per-tenant. | migrations (`protected $connection = 'global_master_mysql'`); permissions `prime.*`; routes on central domain |
| Cross-DB consumption pattern | Every `glb_*` table is created in `global_db` and then exposed to `prime_db` as a **`CREATE OR REPLACE VIEW`** (so prime-side code and FKs can read it on the default connection). Tenant modules consume `glb_*` masters either through these prime-side views or via direct cross-DB FK to `{global_db}.glb_*`. | every geography/board/language/module/menu/translation migration ends with `DB::connection('mysql')->statement("CREATE OR REPLACE VIEW glb_... AS SELECT * FROM {globalDb}.glb_...")` |
| Laravel path | `Modules/GlobalMaster/` | filesystem |
| Known completion | ~55% (per V2 2026-03-26; module scorecard 5.4/10 from 2026-03-22 audit). Core geography + module/plan/dropdown CRUD functional; multiple P0 bugs, auth gaps, and one runtime-fatal (missing AcademicSession model) open. | V2 §1.3 + live code |
| Controllers | **15** — AcademicSession, ActivityLog, City, Country, District, Dropdown, GeographySetup, GlobalMaster, Language, Module, Notification, Organization, Plan, SessionBoardSetup, State | `app/Http/Controllers/` (filesystem) |
| Models | **12** in `app/Models/` — Country, State, District, City, Board, Module, Plan, Language, Dropdown, DropdownNeed, ActivityLog, Media. ⚠ Plus a **rogue duplicate** `Modules/GlobalMaster/Models/Dropdown.php` (wrong location) and a `Dropdown.php.bkk` backup. **No `AcademicSession`, `Menu`, or `Translation` model exists in this module.** | `app/Models/` |
| Policies | **14** — AcademicSession, ActivityLog, Board, City, Country, District, Dropdown, DropdownNeed, DropdownNeedMgmt, GeographySetup, Language, Module, Plan, State | `app/Policies/` |
| FormRequests | **10** — AcademicSession, Board, City, Country, District, Dropdown, Language, Module, Plan, State | `app/Http/Requests/` |
| Services | **0** — all business logic lives in controllers (no `Services/` dir) | filesystem |
| Migrations | **17** (see DDL inventory) | `database/migrations/` |
| Seeders | **2** — `GlobalMasterDatabaseSeeder` (entry stub), `LanguageSeeder` | `database/seeders/`. ⚠ V2 §6.7 lists a `DropdownSeeder` — **not present** in live tree. |
| Blade views | **55** | `resources/views/` |
| Module web routes | **5 resources only** registered in `Modules/GlobalMaster/routes/web.php` (country, language, activity-log, dropdown, session-board-setup) under `prefix('global-master')`. The **majority of routes live in the central root `routes/web.php`** (geography masters under `prefix('prime')`; module/location-setup under `prefix('global-master')`). | module `routes/web.php` + root `routes/web.php` |
| Module API routes | **1** — `apiResource('globalmasters', GlobalMasterController)` stub under `auth:sanctum` `/v1`. Controller methods are empty. | module `routes/api.php` |
| Tests | **4 files** — `tests/Unit/{ArchitectureTest, BoardTest, ControllerAuthTest, ModelStructureTest}.php`. ⚠ V2 §10 reported only 1 trivial `BoardTest`; live now has 4 (still no Feature/HTTP/security coverage). | `tests/Unit/` |
| FRD status | **FRD + Complete Analysis Pack created 2026-06-29** | `GLB_FRD_Complete_2026-06-29.md` |

### Key technology dependencies
- **Multi-DB:** `global_master_mysql` connection → `global_db`; default `mysql` → `prime_db`. Cross-DB FKs use fully-qualified `{global_db}.glb_*` paths; cross-DB BelongsToMany pivots are DB-qualified in the model (e.g. `"{$primeDb}.glb_module_plan_jnt"`).
- **Spatie Permission (RBAC)** — `Gate::authorize('prime.{entity}.{action}')` string abilities in controllers (NOT model-bound policy resolution, despite 14 Policy classes existing).
- **`activityLog()` helper** (`app/Helpers/activityLog.php`) — central audit-write target; imports `Modules\GlobalMaster\Models\ActivityLog`. **All modules depend on this**, so GLB's ActivityLog model must remain stable (tight coupling, ARCH-006).
- **MySQL 8 features** — generated STORED column (`glb_academic_sessions.current_flag`) + unique index to enforce single-current-session; CHECK constraints on `glb_menus` and `glb_modules`.
- **Spatie MediaLibrary** — `media` table migration present; `Media` model is an empty shell (`$fillable = []`, no `$table`).

---

## DDL / Schema Inventory (verified against migration source — authoritative)

> **Reconciliation note:** `glb_*` tables ARE present in the consolidated `0-DDL_Masters/global_db_v4.sql` (11 tables). Two name/placement divergences between the DDL master and the live migrations are flagged inline. `sys_dropdowns` / `sys_dropdown_needs` / `sys_activity_logs` are **owned elsewhere** (central/SystemConfig) and only *consumed* here.

### Tables created on `global_master_mysql` (global_db) — each mirrored as a prime_db VIEW
1. **`glb_countries`** — PK `id` (UNSIGNED INT) · `name` VARCHAR(50) UNIQUE · `short_name` VARCHAR(10) UNIQUE · `global_code` VARCHAR(10) NULL · `currency_code` VARCHAR(8) NULL · `is_active` BOOL · timestamps · softDeletes. No `default_timezone` column (FormRequest validates it; silently dropped).
2. **`glb_states`** — `id` · `country_id` → `glb_countries` RESTRICT · `name` UNIQUE · `short_name` UNIQUE · `global_code` NULL · `is_active` · UNIQUE `(country_id, name)` · timestamps · softDeletes.
3. **`glb_districts`** — `id` · `state_id` → `glb_states` RESTRICT · `name`(50) · `short_name`(10) UNIQUE · `global_code` NULL · `is_active` · UNIQUE `(state_id, name)` · timestamps · softDeletes.
4. **`glb_cities`** — `id` · `district_id` → `glb_districts` RESTRICT · `name`(100) · `short_name`(20) · `global_code`(20) NULL · `default_timezone`(64) NULL · `is_active` · timestamps · softDeletes.
5. **`glb_boards`** — `id` · `name`(255) UNIQUE · `short_name`(20) UNIQUE · `is_active` · timestamps · softDeletes.
6. **`glb_menus`** — `id` · `parent_id` self-FK RESTRICT NULL · `is_category` BOOL · `code`(60) · `menu_for` ENUM(prime,tenant) · `slug`(150) · `title`(100) · `description` NULL · `icon` NULL · `route` NULL · `permission` NULL · `sort_order` · `visible_by_default` BOOL · `is_active` · UNIQUE `(code, menu_for, slug, title, route)` · softDeletes · timestamps. **CHECK** `chk_is_category_parent_id`: a category, or else parent_id not null. ⚠ Menu **CRUD is owned by SystemConfig**, not GLB; GLB only maps menus to modules.
7. **`glb_academic_sessions`** — `id` · `short_name`(20) UNIQUE · `name`(50) · `start_date` DATE · `end_date` DATE · `is_current` BOOL default true · softDeletes · timestamps · **generated** `current_flag` BIGINT `GENERATED ALWAYS AS (CASE WHEN is_current=1 THEN 1 ELSE NULL END) STORED` + UNIQUE index `uq_acadSessions_currentFlag`. ⚠ **No `is_active` column** (controller's toggle references `is_active` — DBM-003).
8. **`glb_modules`** — `id` · `parent_id` self-FK RESTRICT NULL · `name`(50) · `version` TINYINT default 1 · `is_sub_module` BOOL · `description`(500) NULL · `is_core` BOOL · `default_visible` BOOL · 7× `available_perm_{view,add,edit,delete,export,import,print}` BOOL · `is_active` · UNIQUE `(parent_id, name, version)` · softDeletes · timestamps. (CHECK `chk_isSubModule_parentId` is commented out in live migration.)
9. **`glb_languages`** — `id` · `code`(10) UNIQUE · `name`(50) UNIQUE · `native_name`(50) NULL · `direction` ENUM(LTR,RTL) default LTR · `is_active` · softDeletes · timestamps. (⚠ V2 §5.3/DBM-002 claimed this table lacks timestamps/deleted_at — **live migration DOES create them**; that V2 gap is now resolved/stale.)
10. **`glb_translations`** — `id` · `morphs(translatable)` · `language_id` → `glb_languages` **CASCADE** · `key` · `value` TEXT · UNIQUE `(translatable_type, translatable_id, language_id, key)` · timestamps. No softDeletes. **No Translation model/controller exists** (FR-GLB-14 not started).
11. **`glb_menu_module_jnt`** (live migration name) · `id` · `menu_id` → `{global_db}.glb_menus` RESTRICT · `module_id` → `{global_db}.glb_modules` RESTRICT · `sort_order` default 0 · timestamps. ⚠ **NAME MISMATCH:** consolidated `global_db_v4.sql` names this table **`glb_menu_model_jnt`**; the live migration AND `Module::menus()` pivot both use **`glb_menu_module_jnt`**. (INC-07 / DBM-009.)

### Tables created on default `mysql` (prime_db)
12. **`media`** — Spatie MediaLibrary table (no prefix). `Media` model is an empty shell.
13. **`prm_plans`** — `id` · `plan_code`(20) · `version` UNSIGNED INT default 0 · `name`(100) · `description`(255) NULL · `billing_cycle_id` → `prm_billing_cycles` RESTRICT · `price_monthly` DECIMAL(12,2) NULL · `price_yearly` DECIMAL(12,2) NULL · `currency` CHAR(3) default INR · `trial_days` UNSIGNED INT default 0 · `is_active` · UNIQUE `(plan_code, version)` · softDeletes · timestamps. ⚠ **No `price_quarterly`** (V2 proposed it; not built). Managed by GLB's `Plan` model + `PlanController` (co-located with Module mgmt).
14. **`glb_module_plan_jnt`** — `id` · `plan_id` → `prm_plans` CASCADE · `module_id` → `{global_db}.glb_modules` CASCADE · `is_active` · timestamps. **Lives in prime_db** (per the migration's own doc-block). ⚠ V2 repeatedly calls this `prm_module_plan_jnt` — **the live name is `glb_module_plan_jnt`.**
15. **`activity_logs`** — `id` · `morphs(subject)` · `user_id` → `sys_users` RESTRICT · `event` · `properties` JSON · `ip_address` · `user_agent` · timestamps · index `(created_at, user_id)`. ⚠ **MODEL/TABLE MISMATCH:** this migration creates a table literally named **`activity_logs`**, but the `ActivityLog` model maps to **`sys_activity_logs`** (the platform-standard audit table owned centrally). The `activity_logs` migration appears to be dead/superseded.

### Tables created on default connection but referencing tenant `sch_*` (module-boundary anomalies)
16. **`sch_board_organization_jnt`** — `id` · `organization_id` → `sch_organizations` RESTRICT · `board_id` → `{global_db}.glb_boards` RESTRICT · `academic_sessions_id` → `{global_db}.glb_academic_sessions` RESTRICT · timestamps. Backs `Board::organizations()`. (A `sch_*` junction defined inside the GLB module — boundary smell.)
17. **`organization_academic_sessions`** — **un-prefixed** table · `organization_id` → `sch_organizations` RESTRICT · `academic_sessions_id` → `{global_db}.glb_academic_sessions` RESTRICT · `short_name` · `name` · dates · `is_current` · `is_active` · `current_flag` (plain bool, generated-column attempt commented out) · UNIQUE `(organization_id, short_name)` · softDeletes. **No prefix → naming-standard violation; no `down()` body.**

### Models — fillable / connection facts (three-way reconciled)
- **Connection inconsistency across the geography models:** `Country` sets **no** `$connection` (DBM-004); `State`, `City`, `Board`, `Module`, `Language` set `global_master_mysql`; `District` has it **commented out**; `Plan` sets `mysql`; `Dropdown`/`DropdownNeed`/`ActivityLog` set none. Connection-less models still resolve `glb_*` because of the prime_db VIEWs.
- **Country** — no `$casts` (DBM-005, all peers cast `is_active`→bool). Rels: `states()`, `organizationGroups()`.
- **Module** — `plans()` BelongsToMany via DB-qualified `"{$primeDb}.glb_module_plan_jnt"`; `menus()` via `glb_menu_module_jnt` withPivot `sort_order`; self-ref `parent()/children()`; `tenantPlanModules()`, `tenantInvoices()`.
- **Plan** — `$connection='mysql'`, `$table='prm_plans'`; `modules()` BelongsToMany via DB-qualified pivot; `tenantPlans()`, `billingCycle()`.
- **Dropdown** — `$table='sys_dropdowns'` (⚠ V2 says `sys_dropdown_table` — **stale**; the `.bkk` backup uses the old name). Rich Complaint-module relationships (status/severity/priority/action/medical/sentiment) — this is the platform-wide config-driven dropdown (D29).
- **DropdownNeed** — `$table='sys_dropdown_needs'`; `dropdownValues()/dropdowns()/activeDropdowns()`.
- **ActivityLog** — `$table='sys_activity_logs'`; no SoftDeletes; `user()` switches between tenant/central User model based on `tenancy()->initialized`; `subject()` morphTo.

---

## Known Gaps & Open Issues
*(Carried from V2 2026-03-26 gap analysis; live-verified items marked ✔; stale/resolved items marked ✗-stale. These feed the FRD and the downstream Technical Audit.)*

> **Technical Audit (Mode X — Complete) completed 2026-06-29** → `3-Audit_Reports/V1_Jun-2026/GlobalMaster_Complete_Audit_2026-06-29.md`. **Verdict: NO-GO, health 34/100 (P0-capped). P0=2, P1=10, P2=10, P3=3.** Issue codes assigned: BUG-GLB-001..009, SEC-GLB-010..014, VAL-GLB-001..003, DATA-GLB-001..003, MIG-GLB-001, PERF-GLB-002, ARCH-GLB-001, ORM-GLB-001, DEAD-GLB-003 (full table in `lessons/known-issues.md`).
> **Audit-confirmed P0s:** (1) **BUG-GLB-001** — missing `AcademicSession` model breaks BOTH `AcademicSessionController` and `SessionBoardSetupController` (REQ-GLB-007 *and* REQ-GLB-013 500). (2) **SEC-GLB-010** — LanguageController `create/store/edit/update` ungated (BR-GLB-020).
> **Live corrections (live wins):** `ModuleController::show()` is now **FIXED** (uses `prime.module.view` + returns `module.show`) — BUG-PRM-014 resolved, NOT re-reported. GlobalMaster/Organization/SessionBoardSetup `store/update/destroy` are empty `{}` stubs → not auth holes (guardrail). GLB `NotificationController` is **unrouted** (root web.php wires Prime's) → dead code, not an auth finding. `$request->all()` live count is **6 controllers / 12 sites**, not 4.
> **New audit-only findings beyond the BA hint list:** `DropdownRequest` validates only 2 of 5 fields so `store()` inserts null `key`/`type` (VAL-GLB-001, P1 — creation effectively broken); three routed methods don't exist (`getStatesByCountry`, `dropdown.search`, `activity-log.search` → BUG-GLB-005); GLB resources are registered up to **3×** (one `prime.` group + two identical `global-master` groups at root web.php:416 & 666 + module web.php); `glb_academic_sessions` `is_active` column is **absent** (DATA-GLB-002, root cause of the destroy/toggle bugs); all **10/10** FormRequests `authorize(){return true;}` (D30).
> **Positive vs platform baseline:** D29-clean (0 `->enum()` in GLB migrations); `glb_academic_sessions.current_flag` is a correct `GENERATED ALWAYS … STORED` column (D36-compliant); central module → Layer-6 tenancy correctly N/A.

### P0 — Critical
- ✔ **Missing `AcademicSession` model (runtime fatal).** `AcademicSessionController` imports `Modules\GlobalMaster\Models\AcademicSession` and calls `AcademicSession::paginate/create/findOrFail` — **the class does not exist in this module** (only `Modules\Prime\Models\AcademicSession` exists). Every academic-session route 500s. (MF-001 → REQ-GLB-007 / BR-GLB-019.)
- ✔ **Mass-assignment via `$request->all()`** in `store()`/`update()` of **6 controllers** (Country, State, City, Module, Plan, AcademicSession). Must use `$request->validated()`. (BUG-001 / SEC-001 → BR-GLB-022.)
- ✔ **LanguageController auth + wrong import.** Imports `Modules\Prime\Models\Language` (wrong module); `create()/store()/edit()/update()` have **no `Gate::authorize()`** → any authenticated central user can create/edit languages. Also mixes `global-master.*` and `prime.*` ability prefixes. (AUTH-001 / BUG-007 / BUG-006.)
- **Inverted destroy guard** on `AcademicSessionController::destroy()` — `if (!$session->is_active === true)` (operator-precedence bug) lets active sessions be deleted. (BUG-004 → BR-GLB-009.)
- **Zero-auth stub controllers** — `GlobalMasterController` (7 methods), `OrganizationController` (7 methods), `NotificationController::testNotification()/allNotifications()` have no Gate checks. Implement or remove. (AUTH-003/004/006.)
- **`planDetails()`** AJAX endpoint has no Gate check (any auth user reads plan+module pricing). (AUTH-008.)

### P1 — High
- Duplicate `activityLog()` calls in `StateController::update()` and `ModuleController::update()` (BUG-002/003).
- `AcademicSessionRequest` validates only `name`/`short_name` — missing `start_date`/`end_date` cross-field rules and `is_current` (BUG-005 → BR-GLB-010).
- `DistrictController::forceDelete()` uses `prime.district.delete` instead of `…forceDelete` (BUG-005-dist → BR-GLB-021).
- `ModuleController::show()` uses `prime.module.create` ability + returns the `module.edit` view (BUG-002).
- City `toggleStatus` has **no parent-status check** (inconsistent with State/District); `city.edit()` uses raw `findOrFail($id)` instead of route-model binding.
- `StateController::getStatesByCountry()` referenced by route `get-states/{countryId}` — verify method exists (RT-004 flagged it missing in V2).
- Geography cascade on country deactivation **omits cities** (only states+districts cascade) (BUG-010 → BR-GLB-001).
- Activity log written **before** status-check guards in some toggles → failed toggles log as success (SEC-006 → BR-GLB-005).
- **Triplicated `global-master` route groups** historically in root `routes/web.php`; live file currently has 2 `prefix('global-master')` groups plus geography under `prefix('prime')` — still un-consolidated and the module's own `routes/web.php` carries only 5 resources (RT-001/003, ARCH-02).
- `glb_languages` no longer needs the DBM-002 fix — **live migration creates timestamps + deleted_at** (V2 gap stale).

### P2 — Medium
- **No service layer** (ARCH-001) — extract GeographyService / ModulePlanService / DropdownService / TranslationService.
- N+1 in `DropdownController::index()` (one query per key) (PERF-001); unbounded geography loads in `GeographySetupController` / `StateController` / `CityController` (PERF-002/003/005).
- No caching of static reference data (countries/states/sessions/modules/plans/boards) (PERF-006).
- `glb_academic_sessions` missing `is_active` column (DBM-003); all `glb_*` missing `created_by` (DBM-001).
- `glb_menu_module_jnt` (code) vs `glb_menu_model_jnt` (DDL master) name mismatch (INC-07/DBM-009).
- `ModuleRequest::is_sub_module` typed `nullable|string|max:50` (should be boolean) (INC-06); `DropdownRequest` does not validate `key`/`type`/`org_id` and references stale `table_name`/`column_name` inputs (DBM-010).
- Dropdown `org_id` set from `auth()->user()->id` (semantically wrong) (BUG-009).
- LIKE-search inputs not escaped; no rate limiting on search/AJAX endpoints (SEC-002/003 → BR-GLB-023/024).
- Translation management (model/controller/views) not started (MF-003 → REQ-GLB-014).
- Reference-data REST API for tenant consumption not built (only the empty `globalmasters` stub) → REQ-GLB-015.

### P3 — Low / Tech-debt
- Rogue duplicate `Modules/GlobalMaster/Models/Dropdown.php` + `Dropdown.php.bkk` backup in repo (BUG-008 / ARCH-005).
- `Media` model is an empty shell (DBM-007); `ActivityLog` lacks SoftDeletes (DBM-006); `Module.php` hardcodes the prime DB name in its pivot (DBM-009).
- Stale `App\Models\V1\GlobalMaster\*` imports in `CountryController` (ARCH-002).
- Dead `activity_logs` migration (model targets `sys_activity_logs`).
- Un-prefixed `organization_academic_sessions` + `sch_board_organization_jnt` defined inside GLB (module-boundary smell).
- `DropdownController`/`ActivityLogController` reference `search()` methods that may not exist (RT-005/006).

---

## Design Decisions Made
- **Central / global-DB scope.** GLB owns the platform's shared reference data. It is read-mostly from the tenant perspective; the central Super-Admin team is the sole owner. No academic-year scoping of GLB's own data (it *defines* the academic-session master).
- **Global table → prime VIEW pattern.** `glb_*` tables physically live in `global_db`; a `CREATE OR REPLACE VIEW` of the same name is created in `prime_db` so default-connection code and prime-side FKs can read them. This is how prime/tenant code consumes global masters without a second connection.
- **Single-current academic session** enforced at the DB via a generated `current_flag` column + unique index (no app-level locking) — NFR-GLB-DI-03.
- **Config-driven dropdowns (D29).** Platform enumerations live in `sys_dropdowns` keyed by slug; managed here, consumed everywhere (Complaint severity/priority/status, etc.).
- **Policies present but unused for resolution.** 14 Policy classes exist, but controllers authorize via `Gate::authorize('prime.{entity}.{action}')` string abilities (Spatie), not model-bound policy methods.

## Cross-Module Dependencies
- **Outbound (GLB feeds / is read by):**
  - SchoolSetup ← `glb_countries/states/districts/cities` (org address FKs), `glb_boards` (via `sch_board_organization_jnt`).
  - Prime (tenant onboarding) ← `glb_academic_sessions`, `prm_plans`, `glb_modules`.
  - Billing ← `prm_plans` (→ `prm_tenant_plan_jnt` → invoices).
  - StudentProfile ← `glb_cities` (student city FK).
  - All tenant modules ← `sys_dropdowns` (lookup by key); `glb_menus`/`glb_modules` (menu + permission rendering).
  - All modules → write `sys_activity_logs` via the `activityLog()` helper (which imports GLB's `ActivityLog` model — hard coupling).
  - i18n-aware modules ← `glb_translations` + `glb_languages` (polymorphic lookup) — *future*.
- **Inbound (GLB reads):** `sys_users` (activity-log actor, plan/board creator), `prm_billing_cycles` (Plan billing cycle), `sch_organizations` (board/session org junctions).

## Lessons Learned
- `[2026-06-29 | Business Analyst]` GLB is a **multi-connection** module: the "create in global_db, then VIEW into prime_db" migration idiom is the load-bearing mechanism that lets connection-less Eloquent models and prime-side FKs read global masters. Any claim about where a `glb_*` table "lives" must distinguish the real table (global_db) from its prime_db view.
- `[2026-06-29 | Business Analyst]` Several high-profile V2 claims are **stale against live code**: junction is `glb_module_plan_jnt` not `prm_module_plan_jnt`; Dropdown maps to `sys_dropdowns` not `sys_dropdown_table`; `glb_languages` already has timestamps+deleted_at (DBM-002 resolved); `prm_plans` still has no `price_quarterly`; tests grew from 1→4 files. Always re-verify counts/names before asserting.
- `[2026-06-29 | Business Analyst]` The single most dangerous defect is non-obvious from V2's tone: the **missing `AcademicSession` model makes the entire academic-session feature a guaranteed runtime 500**, yet V2 scores the module ~55% — confirms the rule that "Partial/✅" status markers in older requirement docs are not a substitute for reading the live class list.
- `[2026-06-29 | Business Analyst]` Table/model name mismatches are systemic here: `activity_logs` migration vs `sys_activity_logs` model; `glb_menu_module_jnt` code vs `glb_menu_model_jnt` DDL master. Three-way reconcile (DDL master ↔ migration ↔ model) is mandatory for every GLB schema claim.
- `[2026-06-29 | Technical Auditor]` The missing-`AcademicSession`-model fault has a **second consumer** the BA list missed: `SessionBoardSetupController.php:8,22` also imports and paginates `AcademicSession`, so REQ-GLB-013 (Session-Board Hub) 500s too — not just REQ-GLB-007. Always grep ALL consumers of a missing class, not just the obvious controller.
- `[2026-06-29 | Technical Auditor]` `DropdownController::store()` is a textbook "validated() lies" trap: it reads `$data['key']/['type']/['org_id']` from `$request->validated()`, but `DropdownRequest::rules()` only declares `value`+`is_active` (the real rules are commented out) → those keys are absent → null inserts / undefined-key notices. When a controller uses `validated()`, cross-check that every key it then reads is actually in `rules()`.
- `[2026-06-29 | Technical Auditor]` `glb_academic_sessions` has **no `is_active` column** (only `is_current` + generated `current_flag`), yet the controller's destroy/toggle/single-current logic all key off `is_active`. The FRD's "current session" semantics map to `is_current`; the whole academic-session feature must be rewired to `is_current`. A migration column that "should obviously exist" was the hidden root cause of three separate P1 bugs.
- `[2026-06-29 | Technical Auditor]` Verify routed methods exist before trusting a route list: `get-states/{countryId}`, `dropdown/search`, `activity-log/search` are all registered but the methods are absent (`grep -c` = 0) → 500 on call. Route registration ≠ method existence.
- `[2026-06-29 | Technical Auditor]` Architectural risk D39: the global `activityLog()` helper hard-imports GLB's `ActivityLog` model, so platform-wide auditing depends on this one feature-module class — recommend binding the writer behind an interface.

## Pending Next Steps
1. DDL Schema Gap Analysis → DB Architect (reconcile `glb_menu_module_jnt`/`glb_menu_model_jnt`; add `is_active` to `glb_academic_sessions`; decide `price_quarterly`; resolve dead `activity_logs` migration; prefix `organization_academic_sessions`).
2. Application Code Gap → Technical Auditor (FRD-driven: missing AcademicSession model, `$request->all()`×6, Language auth gaps, zero-auth stubs, inverted destroy guard).
3. Business-Rule Enforcement audit (geography cascade incl. cities, single-current session, log-after-guard ordering, forceDelete permission).
4. Test Coverage Gap → Testing Architect (4 structural unit tests today; 0 feature/HTTP/security).

## Version History
| Date | Agent | Change |
|---|---|---|
| 2026-06-29 | Business Analyst | Seeded from live code (migration↔model↔controller/route three-way reconcile) + V2 Requirement; created FRD + Complete Analysis Pack (`GLB_FRD_Complete_2026-06-29.md`). Counts verified against filesystem; multiple stale V2 claims corrected. |
| 2026-06-29 | Technical Auditor | Mode-X Complete Audit (A+B+C+G + scoped D) → `3-Audit_Reports/V1_Jun-2026/GlobalMaster_Complete_Audit_2026-06-29.md`. NO-GO, health 34/100. P0=2 (missing AcademicSession model; Language create/edit unauth), P1=10, P2=10, P3=3. Added BUG/SEC/VAL/DATA/MIG/PERF/ARCH/ORM/DEAD-GLB codes to known-issues.md; D39 to decisions.md; updated progress.md. |
