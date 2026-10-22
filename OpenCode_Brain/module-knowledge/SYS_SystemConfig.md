# Module Knowledge — SYS: SystemConfig
**Seeded:** 2026-06-30 | **Agent:** Business Analyst
**Version:** 1.0

---

## Module Facts

| Attribute | Value |
|-----------|-------|
| Module Name | SystemConfig |
| Module Code | SYS |
| Table Prefixes | `sys_*` (prime_db) + `glb_*` (global_db, menus/translations) |
| Laravel Module Path | `Modules/SystemConfig/` |
| Namespace | `Modules\SystemConfig` |
| DB Layer | **Central only** — `prime_mysql` (prime_db) + `global_master_mysql` (global_db) |
| Domain Scope | Central/Prime domain (Super-Admin only; no tenant users) |
| RBS Reference | PG (System Configuration) — RBS v4.0 |
| FRD Status | FRD written 2026-06-30 (SYS_FRD_2026-06-30.md) + Complete Pack (SYS_FRD_Complete_2026-06-30.md) |
| V2 Estimated Completion | ~53% (D+) as of 2026-03-26 |
| Revised Estimated Completion | ~65–70% as of 2026-06-30 (post June 2026 expansions) |

### Verified File Counts (from `ls Modules/SystemConfig/` — 2026-06-30)

| Component | Count | V2 Said | Delta / Notes |
|-----------|-------|---------|---------------|
| Controllers | 11 | 4 | +7: BackupController, BackupScheduleController, TenantActivityLogController, TenantDropdownController, TenantDropdownNeedController, TenantLocationController, TenantMediaStoreController |
| Models | 8 | 3 | +5: BackupRun, BackupSchedule, Dropdown, DropdownNeed, DropdownNeedDropdown |
| FormRequests | 4 | 1 | +3: StoreBackupRequest, StoreBackupScheduleRequest, TenantDropdownRequest |
| Policies | 2 | 2 | No change: MenuPolicy (broken prefix), SystemConfigPolicy (empty stub) |
| Services | 2 | 0 | +2: BackupService, BackupScheduleService |
| Jobs | 1 | 0 | +1: RunBackupJob |
| Notifications | 2 | 0 | +2: BackupFailedNotification, BackupSuccessNotification |
| Seeders | 5 | 0 | DropdownNeedDropdownsJntSeeder, DropdownNeedsSeeder, DropdownsSeeder, SettingsSeeder, SystemConfigDatabaseSeeder |
| Tests | 1 file | 1 file | 22 unit tests, 0 feature/HTTP tests — unchanged |
| Views (Blade) | 36 | ~12 | Backup views, location views, dropdown views, activity-log view, media-store view added |

---

## DDL Table Inventory

Tables derived from central migrations in `database/migrations/` (non-tenant migrations).
Note: `sys_permissions`, `sys_roles`, and Spatie RBAC junction tables are managed by Spatie's own migrations. `glb_menus` and `glb_translations` live in `global_db`.

### sys_* Tables (prime_db — confirmed from migrations)

| Table | Purpose | New vs V2? |
|-------|---------|-----------|
| `sys_settings` | Platform key-value configuration (SMTP, SMS, auth, feature flags) | V2 |
| `sys_dropdown_needs` | Registry of fields that require dropdown values across all modules | V2 |
| `sys_dropdowns` | Dropdown values (key-value pairs per field group) | V2 called it `sys_dropdown_table` — **name changed** |
| `sys_dropdown_need_dropdowns_jnt` | Need ↔ Dropdown value junction | V2 called it `sys_dropdown_need_table_jnt` — **name changed** |
| `sys_media` | Polymorphic file attachment store (model_type, model_id, uuid, file_name) | V2 |
| `sys_activity_logs` | Append-only audit trail (subject_type, subject_id, user_id, event, properties JSON) | V2 |
| `sys_users` | Platform users (is_super_admin, is_pg_user, two_factor_auth_enabled) | V2 |
| `sys_backup_runs` | Log of backup execution runs (status, file path, size, duration) | **NEW — not in V2** |
| `sys_backup_schedules` | Scheduled backup definitions (frequency, retention, type) | **NEW — not in V2** |

### glb_* Tables (global_db)

| Table | Purpose | Managed By |
|-------|---------|-----------|
| `glb_menus` | Application navigation tree (self-referential; SoftDeletes) | SystemConfig (MenuController) |
| `glb_translations` | Multilingual labels for menus and entities | SystemConfig (translation logic in MenuController) |

### Spatie RBAC Tables (prime_db — Spatie-managed migrations)

| Table | Purpose |
|-------|---------|
| `sys_permissions` | RBAC permission definitions |
| `sys_roles` | Role definitions |
| `sys_role_has_permissions_jnt` | Role-permission mapping |
| `sys_model_has_permissions_jnt` | Direct model-permission mapping |
| `sys_model_has_roles_jnt` | Model-role mapping |

> **Table name changes from V2:** `sys_dropdown_table` → `sys_dropdowns`; `sys_dropdown_need_table_jnt` → `sys_dropdown_need_dropdowns_jnt`. Models reflect these: `Dropdown` (not `DropdownValue`), `DropdownNeedDropdown` (not `DropdownNeedTableJnt`). Update any code or FRD referencing the old names.

---

## Feature Area Status (as of 2026-06-30)

| # | Feature Area | Status | Notes |
|---|-------------|--------|-------|
| 1 | Platform Settings (CRUD) | 🟡 65% | View exists; edit broken (wrong table name in validation); no SettingRequest; store() returns raw $request |
| 2 | Menu Management | 🟡 65% | CRUD partially implemented; create/destroy/restore/toggleStatus stubs; $request->all() mass-assign bug in update() |
| 3 | Menu Sync | 🟡 70% | Functional but auth block COMMENTED OUT — destructive truncate without auth |
| 4 | Translation Management | 🟡 30% | Hardcoded languageId=2; translation create commented out in store(); no standalone UI |
| 5 | Dropdown Management (Needs + Values) | 🟡 75% | Models (Dropdown, DropdownNeed, DropdownNeedDropdown) + controllers (TenantDropdownController, TenantDropdownNeedController) added post-V2; TenantDropdownRequest exists; views present |
| 6 | Backup System | ✅ 85% | **Fully new post-V2**: BackupController + BackupScheduleController + BackupService + BackupScheduleService + RunBackupJob + 2 notifications + 3 schedule views + create/index views |
| 7 | Location Management | 🟡 70% | **New post-V2**: TenantLocationController + 8 views (country/state/city/district create+edit + index) |
| 8 | Activity Log Viewer | 🟡 70% | **New post-V2**: TenantActivityLogController + activity-log/index view; read-only viewer |
| 9 | Media Store Viewer | 🟡 60% | **New post-V2**: TenantMediaStoreController + media-store/index view |
| 10 | Policy (MenuPolicy) | ❌ 0% effective | All 7 methods use wrong prefix `prime.menu.*` vs controller's `system-config.menu.*` — policy is dead code |
| 11 | Policy (SystemConfigPolicy) | ❌ 0% | Empty stub; not registered in AppServiceProvider |
| 12 | Test Coverage (Feature) | ❌ 0% | Zero HTTP/feature tests; 22 unit tests only (model structure + class existence) |

---

## Known Gaps & Open Issues

### P0 — Critical (Security / Runtime)

| ID | Issue | Location |
|----|-------|---------|
| SEC-SYS-01 | ZERO authorization on ALL 7 SystemConfigController methods (index, create, store, show, edit, update, destroy) — any authenticated user can access platform settings | `SystemConfigController.php` lines 13-61 |
| SEC-SYS-02 | MenuSyncController::sync() auth check is COMMENTED OUT — any authenticated user can trigger destructive truncate + re-create of all tenant menus | `MenuSyncController.php` lines 42-47 |
| SEC-SYS-03 | MenuController::create() and destroy() have NO authorization — empty method bodies, no gate | `MenuController.php` lines 59-62, 164-167 |
| BUG-SYS-04 | MenuController::update() uses `$request->all()` not `$request->validated()` — bypasses FormRequest whitelist, allows injecting immutable `code` field | `MenuController.php` line 127 |
| ARCH-SYS-05 | Duplicate `Setting` model: `Modules\Prime\Models\Setting` and `Modules\SystemConfig\Models\Setting` both map to `sys_settings` — conflicting imports across the codebase | `Modules/Prime/app/Models/Setting.php` |

### P1 — High (Broken Functionality / Architecture)

| ID | Issue | Location |
|----|-------|---------|
| BUG-SYS-06 | SettingController::update() validates against non-existent table `settings` (should be `sys_settings`) and a non-existent column `organization_id` — every setting update fails validation | `SettingController.php` line 66-67 |
| BUG-SYS-07 | SettingController::store() returns raw `$request` object — exposes all request headers and body in the HTTP response | `SettingController.php` line 37 |
| BUG-SYS-08 | MenuPolicy uses wrong permission prefix `prime.menu.*` across all 7 methods — controller calls `system-config.menu.*`; policy is effectively dead code and never enforced | `MenuPolicy.php` |
| GAP-SYS-09 | MenuController::create(), destroy(), restore(), toggleStatus() are empty stub method bodies — routes registered but return nothing | `MenuController.php` |
| GAP-SYS-10 | Module's `routes/web.php` is EMPTY — all SystemConfig routes registered in central application routes files; route names collide between prime and tenant contexts | `Modules/SystemConfig/routes/web.php` |
| GAP-SYS-11 | SettingRequest FormRequest is MISSING — SettingController uses inline `$request->validate()` with wrong rules | Needs new `SettingRequest.php` |
| GAP-SYS-12 | MenuSyncController is 1,702 lines — violates SRP; sync logic must be extracted to MenuSyncService | `MenuSyncController.php` |
| GAP-SYS-13 | SystemConfigPolicy is empty stub + NOT registered in AppServiceProvider — dead code | `SystemConfigPolicy.php` |

### P2 — Medium

| ID | Issue | Location |
|----|-------|---------|
| BUG-SYS-14 | MenuController::trashedMenu() uses dot-notation view name `systemconfig.menu.trash` not module double-colon `systemconfig::menu.trash` — view-not-found exception on access | `MenuController.php` line 177 |
| BUG-SYS-15 | MenuController::trashedMenu() has no Gate::authorize() | `MenuController.php` line 171 |
| BUG-SYS-16 | MenuController::forceDelete() has no Gate::authorize() — any authenticated user can permanently delete menu items | `MenuController.php` line 187 |
| GAP-SYS-17 | Hardcoded `$languageId = 2` in MenuController at lines 22 and 105 — translation language should be dynamic (from request, user preference, or sys_settings default) | `MenuController.php` |
| GAP-SYS-18 | Translation create logic in MenuController::store() is commented out (lines 72-80); not implemented in update() either | `MenuController.php` |
| DDL-SYS-19 | FK constraint name typo in sys_model_has_permissions_jnt: `fk_odelHasPermissions_permissionId` (missing 'm') | prime_db DDL |
| DDL-SYS-20 | `sys_settings`, `sys_dropdown_needs`, `sys_dropdowns` have no `deleted_at` column — violates project soft-delete convention | prime_db DDL |
| DDL-SYS-21 | `sys_dropdown_needs.is_system` comment contradicts its meaning — comment says "can be created by Tenant" but actual behavior field is `tenant_creation_allowed`; code must use `tenant_creation_allowed` only | prime_db DDL |
| SEC-SYS-22 | SettingController uses wrong permission prefix `tenant.setting.*` — must be `system-config.settings.*` (central module, not tenant) | `SettingController.php` |

### P3 — Backlog

| ID | Issue |
|----|-------|
| GAP-SYS-23 | Menu.$connection = 'mysql' (hardcoded) — fragile if default DB connection name changes; should use named connection |
| GAP-SYS-24 | Zero rate limiting on any SystemConfig route — MenuSync endpoint especially vulnerable |
| GAP-SYS-25 | Multiple sys_* tables missing `created_by` column (sys_settings, sys_dropdown_needs, sys_dropdowns, sys_media) |
| GAP-SYS-26 | api.php registers non-functional apiResource routes for SystemConfigController with Sanctum auth — dead code |
| GAP-SYS-27 | Translation.php model missing `translatable_type` and `translatable_id` in $fillable — polymorphic parent fields excluded |

---

## Design Decisions Made

| Decision | Detail | Source |
|----------|--------|--------|
| Central-only module | SystemConfig runs ONLY on the prime/central domain — no tenant user should ever access it. Central middleware + Gate::authorize() required at every method. | V2 Section 3.3 |
| `sys_settings.key` is immutable | The setting key is a code contract — never editable via UI. Controller must strip `key` from update payload. | V2 BR-SYS-01 |
| `glb_menus.code` is immutable | Menu code is the system identifier used in permissions and route guards — immutable post-creation. Controller must strip `code` from `update()` payload. | V2 BR-SYS-02 |
| Category menus: parent_id must be NULL | Enforced at DB CHECK + application validation + updateMenu() 422 response | V2 BR-SYS-03 |
| Sibling sort_order auto-renumbering | On drag-drop reorder: siblings are sequentially renumbered to close gaps, skipping the moved item's target slot | V2 BR-SYS-04 |
| Sensitive setting masking | `is_public=0` settings masked in list view; API responses filter to `is_public=1`; keys containing `password`/`api_key`/`secret`/`token` excluded from activity log values | V2 BR-SYS-05/06 |
| Dropdown key format | `sys_dropdowns.key` = `table_name.column_name` (e.g., `cmp_complaint_actions.action_type`) — derived server-side, never accepted from request | V2 BR-SYS-08 |
| Ordinal auto-assign | `sys_dropdowns.ordinal` = `MAX(ordinal)+1` within key group on create; unique per key enforced by DB | V2 BR-SYS-09 |
| Single Super Admin | Enforced by DB generated column `super_admin_flag` + UNIQUE KEY + two DB triggers preventing DELETE and demotion | V2 BR-SYS-10 |
| Menu Sync is Super-Admin only | Destructive truncate+recreate operation; commented-out auth must be restored | V2 BR-SYS-11 |
| Canonical Setting model | `Modules\SystemConfig\Models\Setting` is canonical; `Modules\Prime\Models\Setting` must be deleted | V2 FR-SYS-06 |
| Table name changes (post-V2) | `sys_dropdown_table` renamed to `sys_dropdowns`; `sys_dropdown_need_table_jnt` renamed to `sys_dropdown_need_dropdowns_jnt` | Verified from migrations 2026-06-30 |
| Backup system added (post-V2) | Full backup scheduling/execution feature added with service layer, job queue, and notifications — not in V2 spec | Filesystem verification 2026-06-30 |
| "Tenant" prefix controllers | TenantDropdownController, TenantActivityLogController, TenantLocationController, TenantMediaStoreController suggest these routes are accessible to tenant admins (school admin) for read/manage operations on system data visible within their tenant context | Inferred from naming convention |

---

## Controller Inventory (11 confirmed)

| Controller | Purpose | Auth Coverage | Key Issues |
|-----------|---------|---------------|------------|
| `SystemConfigController` | Settings CRUD (platform settings) | ❌ ZERO on all 7 methods | All stubs; P0 security gap |
| `MenuController` | Menu hierarchy CRUD + reorder | 🟡 ~5/12 methods | create/destroy/restore/toggleStatus stubs; $request->all() bug |
| `SettingController` | Settings view/edit (alternate) | 🟡 Wrong permission prefix | Wrong table in validation; store() returns $request |
| `MenuSyncController` | Menu truncate + re-create from code | ❌ Auth COMMENTED OUT | 1,702 lines; P0 security gap |
| `TenantDropdownController` | Dropdown value management | Unknown | Post-V2 addition; TenantDropdownRequest exists |
| `TenantDropdownNeedController` | Dropdown needs registry management | Unknown | Post-V2 addition |
| `TenantLocationController` | Country/State/City/District management | Unknown | Post-V2; 8 views (create+edit for each level) |
| `TenantActivityLogController` | Read-only activity log viewer | Unknown | Post-V2; activity-log/index view |
| `TenantMediaStoreController` | Media file management viewer | Unknown | Post-V2; media-store/index view |
| `BackupController` | Manual backup trigger + backup list | Unknown | Post-V2; BackupService injected; RunBackupJob dispatched |
| `BackupScheduleController` | Backup schedule CRUD | Unknown | Post-V2; BackupScheduleService injected; 3 views |

---

## Model Inventory (8 confirmed)

| Model | Table | Connection | SoftDeletes | Key Issues |
|-------|-------|------------|:-----------:|------------|
| `Menu` | `glb_menus` | `mysql` (hardcoded) | YES | Connection fragile; correct canonical model |
| `Setting` | `sys_settings` | default (prime_mysql) | NO | Duplicate in Modules\Prime — must delete Prime version |
| `Translation` | `glb_translations` | `global_master_mysql` | NO | Missing `translatable_type`/`translatable_id` in $fillable |
| `Dropdown` | `sys_dropdowns` | default | Unknown | Post-V2; was planned as `DropdownValue` in V2 |
| `DropdownNeed` | `sys_dropdown_needs` | default | Unknown | Post-V2 addition |
| `DropdownNeedDropdown` | `sys_dropdown_need_dropdowns_jnt` | default | Unknown | Post-V2; junction model |
| `BackupRun` | `sys_backup_runs` | default | Unknown | Post-V2 new feature |
| `BackupSchedule` | `sys_backup_schedules` | default | Unknown | Post-V2 new feature |

**Models NOT yet created (still needed from V2 plan):**
- `ActivityLog` — read-only model for `sys_activity_logs` (TenantActivityLogController exists but likely queries directly)

---

## V1 Screen Spec Inventory (6 files in `SystemConfig/`)

| File | Coverage |
|------|---------|
| `00-Module-Overview.md` | Module purpose and architecture |
| `01-Dropdown-Needs.md` | Dropdown needs registry screen |
| `02-Dropdown-List.md` | Dropdown values list screen |
| `03-Create-Dropdown.md` | Create dropdown value (Option 1: DB details / Option 2: Menu path) |
| `04-Mapping.md` | Dropdown need-to-value mapping screen |
| `05-Tenant-Dropdown.md` | Tenant-specific dropdown creation screen (tenant_creation_allowed=1 path) |

> **All 6 V1 specs are dropdown-focused.** Settings management, Menu management, Backup, and Location are not in V1 screen specs — they were either assumed self-evident or developed without dedicated V1 specs. V2 is the primary source for those features.

---

## Permission Architecture

### Current State — Broken / Inconsistent

| Caller | Permission Prefix Used | Should Be |
|--------|----------------------|-----------|
| MenuController | `system-config.menu.*` | `system-config.menu.*` ✅ |
| MenuPolicy | `prime.menu.*` | `system-config.menu.*` ❌ mismatch |
| SettingController | `tenant.setting.*` | `system-config.settings.*` ❌ wrong domain |
| SystemConfigPolicy | (empty — never called) | `system-config.settings.*` |

The mismatch between MenuController (`system-config.menu.*`) and MenuPolicy (`prime.menu.*`) means the registered policy is never invoked by the Gate — the Gate evaluates the controller's explicit permission string directly.

### Target Permission Set (from V2)

| Resource | Permissions |
|----------|------------|
| Settings | `system-config.settings.viewAny/create/update/delete` |
| Menu | `system-config.menu.viewAny/create/update/delete/restore/forceDelete/sync` |
| Dropdown | `system-config.dropdown.viewAny/create/update/delete` |
| Activity Log | `system-config.activityLog.viewAny` |

---

## Cross-Module Dependencies

### SYS Consumes From

| Source | Data / Entity | Why |
|--------|---------------|-----|
| GlobalMaster | `glb_languages` | Language list for translations; hardcoded ID=2 is a workaround |
| Auth (Spatie) | `sys_permissions`, `sys_roles` | All authorization decisions |

### SYS Provides To (Platform-Wide Impact)

| Consumer | Mechanism | What SYS Provides |
|----------|-----------|-------------------|
| ALL tenant modules | Read `sys_dropdown_table` / `sys_dropdowns` | Every configurable dropdown field in every module consumes SYS dropdown values |
| ALL tenant apps | Read `glb_menus` | Sidebar navigation rendered from `glb_menus` after MenuSync |
| Notification module | Read `sys_settings` | SMTP/SMS credentials for email and SMS delivery |
| All modules | `sys_activity_logs` (write) | Platform-wide audit trail |
| SyllabusBooks | `sys_media` | Cover image storage (FK to sys_media) |
| Auth system | `sys_users`, `sys_settings` | Password policy, MFA settings, 2FA |

---

## Backup System (New Feature — Post-V2)

Fully functional backup feature added after V2 was written:

| Component | Detail |
|-----------|--------|
| `BackupController` | Manual backup trigger + list of runs |
| `BackupScheduleController` | Schedule CRUD (create/edit/index) |
| `BackupService` | Core backup execution logic |
| `BackupScheduleService` | Schedule management (frequency, retention) |
| `RunBackupJob` | Queued job that executes the backup |
| `BackupFailedNotification` | Notification sent on backup failure |
| `BackupSuccessNotification` | Notification sent on backup success |
| `BackupRun` model | Tracks each backup execution (status, size, duration, file path) |
| `BackupSchedule` model | Stores schedule definitions |
| `StoreBackupRequest` | Validates manual backup form |
| `StoreBackupScheduleRequest` | Validates schedule create/edit |
| Views | `backup/create`, `backup/index`, `backup/schedules/create`, `backup/schedules/edit`, `backup/schedules/index` |

> **Not in V2 scope** — V2 explicitly called out "Database backup/restore operations (infrastructure level)" as out of scope. This was implemented post-V2.

---

## Seeder Inventory

| Seeder | Populates |
|--------|-----------|
| `SystemConfigDatabaseSeeder` | Orchestrator |
| `DropdownsSeeder` | `sys_dropdowns` (platform-wide dropdown values) |
| `DropdownNeedsSeeder` | `sys_dropdown_needs` (field registry) |
| `DropdownNeedDropdownsJntSeeder` | `sys_dropdown_need_dropdowns_jnt` |
| `SettingsSeeder` | `sys_settings` (platform configuration) |

> These seeders are critical — the entire platform's dropdown system depends on `sys_dropdowns` and `sys_dropdown_needs` being populated correctly. Running `DropdownsSeeder` populates dropdowns consumed by every module.

---

## FRD Summary Block

| Attribute | Value |
|-----------|-------|
| FRD File | `/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/4-Requirement_Module_wise/0-FRD_Documents/SYS_FRD_2026-06-30.md` |
| Complete Pack | `/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/4-Requirement_Module_wise/0-FRD_Documents/SYS_FRD_Complete_2026-06-30.md` |
| Conditions Catalog | `/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/4-Requirement_Module_wise/5-Requirement_Conditions/SYS_Conditions.md` |
| FRD Date | 2026-06-30 |
| Agent | Business Analyst (pa-business-analyst) |
| Total REQs | 10 (4 × P0, 4 × P1, 2 × P2) |
| Total BRs | 20 (BR-SYS-001 through BR-SYS-020) |
| Total RPTs | 2 (RPT-SYS-001 Audit Report, RPT-SYS-002 Backup Report) |
| Total ENHs | 5 (ENH-SYS-001 through ENH-SYS-005) |
| P0 REQs | REQ-SYS-001 (Settings), REQ-SYS-002 (Menu Mgmt), REQ-SYS-004 (Dropdown Needs), REQ-SYS-007 (Menu Sync) |
| P1 REQs | REQ-SYS-003 (Translations), REQ-SYS-005 (Dropdown Values), REQ-SYS-006 (Activity Log), REQ-SYS-008 (Backup) |
| P2 REQs | REQ-SYS-009 (Location Data [inferred]), REQ-SYS-010 (Media Viewer [inferred]) |
| Sprint Count | 4 sprints, 46 h total (30 h backend/frontend + 11 h testing + 5 h schema/config) |
| Overall Completion | 65–70% as of 2026-06-30 |
| Critical Next Steps | SYS-T01 (auth on SystemConfigController), SYS-T02 (uncomment MenuSync auth), SYS-T06 (fix SettingRequest), SYS-T29 (permission seeder) |

### Version History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-06-30 | Business Analyst Agent | Initial FRD + Complete Analysis Pack (first formal FRD for this module) |

---

## Lessons Learned

- [2026-06-30 | Business Analyst] V2 (March 2026) understated SYS by ~3×: claimed 4 controllers/3 models/0 services; actual is 11/8/2. The entire Backup system, Location management, Activity Log viewer, and Media Store viewer were implemented post-V2. Always run `find Modules/SystemConfig -type f | sort` before trusting a V2 completion estimate.
- [2026-06-30 | Business Analyst] Table names changed after V2: `sys_dropdown_table` → `sys_dropdowns`; `sys_dropdown_need_table_jnt` → `sys_dropdown_need_dropdowns_jnt`. The models reflect the new names (`Dropdown`, `DropdownNeedDropdown`). Any FRD or gap analysis using old names must be updated.
- [2026-06-30 | Business Analyst] SYS is unusual — it spans TWO databases: `prime_db` (sys_* tables) and `global_db` (glb_menus, glb_translations). The `Menu` model has a hardcoded `$connection = 'mysql'` override. Any query builder or Eloquent scoping on Menu must account for this non-default connection.
- [2026-06-30 | Business Analyst] The "Tenant" prefix on TenantDropdownController, TenantActivityLogController, TenantLocationController, TenantMediaStoreController does NOT mean these serve tenant DB. All SYS tables are in prime_db. "Tenant" here likely means "accessible by tenant admins" (school admin can view/manage dropdowns relevant to their school). This naming is confusing — should be renamed to reflect actual access scope.
- [2026-06-30 | Business Analyst] The 5 P0 security gaps from V2 are very likely still present: SystemConfigController has zero auth; MenuSync auth is commented out; create/destroy have no gates; $request->all() mass-assign; duplicate Setting model. The June 2026 additions (Backup, Location, etc.) didn't fix these.
- [2026-06-30 | Business Analyst] `sys_dropdown_table` (now `sys_dropdowns`) is a platform-critical table — it powers every dropdown field across all 29 modules. A broken `TenantDropdownController` or bad seed data in `DropdownsSeeder` would cascade failures across the entire platform. This table deserves the highest data-integrity discipline.

---

## Pending Next Steps

1. **P0 Security Fixes** (before any feature work):
   - Add `Gate::authorize('system-config.settings.<action>')` to all 7 `SystemConfigController` methods
   - Uncomment and enforce MenuSync auth (Super Admin only)
   - Add `Gate::authorize()` to `MenuController::create()` and `destroy()`
   - Fix `MenuController::update()` `$request->all()` → `$request->validated()`; strip `code` key
   - Delete `Modules/Prime/app/Models/Setting.php`; update all Prime imports

2. **P1 — Fix broken Settings** — Create `SettingRequest`; fix `SettingController` wrong table/column validation; fix `store()` returning raw `$request`

3. **P1 — Fix MenuPolicy** — Change all 7 methods from `prime.menu.*` to `system-config.menu.*`; register SystemConfigPolicy

4. **P1 — Implement stubs** — MenuController: create(), destroy(), restore(), toggleStatus() bodies

5. **FRD Generation** — SYS needs a formal FRD covering the V2 features + new post-V2 features (Backup, Location, "Tenant" controllers)

6. **MenuSyncService refactor** — Extract 1,702-line controller into service class

7. **Move routes** — Relocate all SYS routes from central `routes/web.php` into `Modules/SystemConfig/routes/web.php`

8. **Test coverage** — Priority: `SystemConfigAuthTest` (P0 feature test — 7 auth scenarios); `MenuControllerAuthTest`; `MenuSyncAuthTest`

---

## Version History

| Version | Date | Agent | Changes |
|---------|------|-------|---------|
| 1.0 | 2026-06-30 | Business Analyst | Initial seed — V2 requirement + filesystem verification + migration-derived DDL + V1 screen specs cross-check |
| 1.1 | 2026-06-30 | Technical Auditor | Mode X Complete Audit — 5 P0 findings (3 NEW), 8 P1 findings, 2 BA P1s cleared, health 40/100 NO-GO |

---

## Mode X Audit Lessons Learned (2026-06-30, Technical Auditor)

**Report:** `3-Audit_Reports/SYS_SystemConfig_Complete_Audit_2026-06-30.md`
**Health:** 40/100 (P0-capped). Deploy: NO-GO.

### Stale Knowledge Corrections (BA v1.0 → Auditor v1.1)

1. **BUG-SYS-06 CLEARED.** BA reported SettingController validates wrong table/columns. **Live code:** update() correctly validates only the `value` field with `max:1000`. CLEARED.

2. **BUG-SYS-07 CLEARED.** BA reported store() returns raw $request. **Live code:** no store() method in SettingController — only index/edit/update. CLEARED.

3. **SEC-SYS-01 DOWNGRADED P0 → P2.** BA flagged SystemConfigController zero auth across 7 methods as P0. **Live code:** only `dashboard` (index) is routed; returns a stub view. Other 6 CRUD methods NOT registered in any route file — unrouted dead scaffold. Low exploitability. Downgraded to P2.

4. **File count dramatically understated.** BA v1.0: 4 ctrl / 3 mdl / 0 svc / 1 req. **Live code:** 11 ctrl / 8 mdl / 2 svc / 4 req. Backup system (BackupController, BackupScheduleController, BackupService, BackupScheduleService, RunBackupJob, 2 Notifications, 2 FormRequests) and Location/ActivityLog/MediaStore controllers were all post-V2 additions not in BA knowledge.

5. **Partial auth coverage in BA.** BA knew MenuController/SettingController. Auditor found: TenantDropdownController CRUD methods DO have Gate (only getColumns() ungated). TenantLocationController has Gate on all 20+ CRUD methods. BackupController and BackupScheduleController have ZERO Gate — critical gap not in BA knowledge.

### New P0 Findings (not in BA knowledge)

6. **SEC-SYS-28 — BackupController::download() is a data breach vector.** `Storage::disk('local')->download(...)` serves complete DB dump ZIP files to any `auth+verified` user. No Gate, no role check. Teacher/parent with valid account can exfiltrate entire database. File: `BackupController.php`.

7. **SEC-SYS-29 — BackupScheduleController zero Gate.** Any `auth+verified` user can create high-frequency schedules (resource DoS) or delete existing schedules (backup sabotage). File: `BackupScheduleController.php`.

8. **SEC-SYS-30 — SQL injection in getColumns() + ungated endpoint.** `DB::connection('tenant')->select("SHOW COLUMNS FROM {$request->table_name}")` — user-controlled table name in raw SQL string. No Gate::authorize. Fix: whitelist table names + add Gate. File: `TenantDropdownController.php:219-234`.

### Confirmed P0 Findings

9. **SEC-SYS-02 CONFIRMED.** MenuSyncController::sync() auth guard is commented out at lines 74-79. Destructive operation (`glb_menu_module_jnt` truncate + `Menu::where('menu_for','tenant')->forceDelete()` + rebuild) accessible to any `auth+verified` user. Route: `GET /system-config/sync-menus`.

10. **ARCH-SYS-05 CONFIRMED.** `Modules\Prime\Models\Setting` and `Modules\SystemConfig\Models\Setting` both map to `sys_settings`. Canonical model is SystemConfig. Fix: delete `Modules/Prime/app/Models/Setting.php`.

### Confirmed P1 Findings

11. **BUG-SYS-04 CONFIRMED.** MenuController::update() line 127: `$menu->update($request->all())`. Immutable `code` field can be overwritten. Fix: `$request->validated()` with code excluded.

12. **BUG-SYS-08 CONFIRMED.** MenuPolicy all 7 methods use `prime.menu.*`. MenuController calls `Gate::authorize('system-config.menu.*')` directly — policy never consulted. Dead code.

13. **BUG-SYS-16 CONFIRMED.** MenuController::forceDelete() (lines 187-198) has live `$menu->forceDelete()` logic but NO Gate::authorize.

14. **PERM-SYS-01 — 5 controllers wrong prefix.** TenantActivityLogController (`tenant.activity-log.*`), TenantMediaStoreController (`tenant.setting.*`), TenantLocationController (`tenant.geography.*`), TenantDropdownController (`tenant.dropdown.*`), SettingController (`tenant.setting.*`) — all must be `system-config.*`. Fix: rename + update seeders.

15. **AUD-SYS-01 — activityLog wrong argument order.** SettingController line 67: `activityLog('updated', $setting, ...)` — first arg should be model, second should be action string. Correct: `activityLog($setting, 'updated', ...)`. Platform-wide pattern — check all modules.

### Verified Good

16. **RunBackupJob** correctly implements ShouldQueue, active-backup guard, 500MB disk space check, `failed()` handler, dynamic tenant DB registration for backup scope. One of the better-implemented jobs in the codebase. No tenancy re-init needed (central operation).

17. **MenuController CRUD methods (5/12) fully gated.** index(), store(), edit(), update(), updateMenu() all call `Gate::authorize('system-config.menu.*')` with correct prefix. store() uses `$request->validated()` correctly.

18. **TenantLocationController fully gated.** All 20+ country/state/district/city CRUD methods have Gate::authorize. Above platform baseline.

19. **No duplicate Gate::policy() kills.** Only 1 policy registered. MenuPolicy dead for different reason (prefix mismatch, not duplicate registration).

### Architecture Notes for SYS

20. **Routes in tenant.php lack tenancy middleware.** SYS controllers registered in `routes/tenant.php` (lines 95-148) have a comment claiming they need InitializeTenancyByDomain — but the middleware is NOT applied. TenantDropdownController, SettingController, TenantLocationController all run in central context with no tenant initialized. Architectural inconsistency: central module controllers in tenant route file with no tenancy stack.

21. **TenantDropdownController context confusion.** `DB::connection('tenant')` calls fail silently (caught in try/catch, returns empty array). The entire controller needs architectural review — fix the context first, then fix the SQL injection in getColumns().
