# SystemConfig (SYS) — Module Overview

**Module:** SystemConfig | **Code:** SYS | **Type:** Central | **DB:** prime_db + global_db | **Prefix:** `sys_`

---

## 1. Module Purpose

SystemConfig is the **central configuration hub** for the Prime Gurukul platform. It owns all platform-level settings, navigation menus, dropdown value registries, activity logging, media assets, and location reference data. Every module in the ecosystem depends on SystemConfig for settings, menus, and dropdown values — making it the highest-blast-radius module in the platform.

---

## 2. Feature Summary

| # | Feature | REQ-ID | Priority | Code Status | Key Gap |
|---|---------|--------|----------|-------------|---------|
| 1 | Platform Settings Management | REQ-SYS-001 | P0 | PARTIAL (65%) | SettingController validates wrong table `settings` instead of `sys_settings`; `store()` returns raw `$request`; duplicate Setting model in Prime module |
| 2 | Navigation Menu Management | REQ-SYS-002 | P0 | PARTIAL (60%) | `create()`, `destroy()`, `restore()`, `toggleStatus()` are empty stubs; `$request->all()` mass-assign bug in `update()`; `trashedMenu()` wrong view notation |
| 3 | Menu Translation Management | REQ-SYS-003 | P1 | PARTIAL (30%) | Translation create logic commented out in `store()`; hardcoded language ID=2; no standalone translation UI |
| 4 | Dropdown Needs Registry | REQ-SYS-004 | P0 | PARTIAL (75%) | `TenantDropdownNeedController` + views exist post-V2; auth coverage unknown |
| 5 | Dropdown Value Management | REQ-SYS-005 | P1 | PARTIAL (75%) | `TenantDropdownController` + views exist post-V2; ordinal/reference-check enforcement unknown |
| 6 | Activity Log Viewer | REQ-SYS-006 | P1 | PARTIAL (70%) | `TenantActivityLogController` + view exist; no filtering; no date range; no expandable detail panel confirmed |
| 7 | Menu Synchronisation | REQ-SYS-007 | P0 | PARTIAL (70%) | Auth check was **COMMENTED OUT** — any authenticated user could trigger destructive truncate; 1,702-line controller violates SRP |
| 8 | Platform Backup Management | REQ-SYS-008 | P1 | PARTIAL (85%) | BackupController + BackupScheduleController + services + job + notifications implemented; auth coverage on backup routes unknown |
| 9 | Location Reference Data Management | REQ-SYS-009 | P2 | PARTIAL (70%) | `TenantLocationController` + 8 views exist; auth unknown; overlap with GlobalMaster |
| 10 | Media Asset Viewer | REQ-SYS-010 | P2 | PARTIAL (60%) | `TenantMediaStoreController` + index view exist; auth unknown |

---

## 3. Requirements (10 MUST — All P0/P1/P2)

### 3.1 REQ Register

| REQ-ID | Feature | BR Refs | MoSCoW | Effort (h) |
|--------|---------|---------|--------|:----------:|
| REQ-SYS-001 | Platform Settings Management | BR-SYS-001, 005, 006, 012, 013 | MUST | 6 |
| REQ-SYS-002 | Navigation Menu Management | BR-SYS-002, 003, 004, 012 | MUST | 10 |
| REQ-SYS-003 | Menu Translation Management | BR-SYS-017, 012 | SHOULD | 3 |
| REQ-SYS-004 | Dropdown Needs Registry | BR-SYS-014, 015, 012 | MUST | 5 |
| REQ-SYS-005 | Dropdown Value Management | BR-SYS-007, 008, 009, 016, 019, 012 | SHOULD | 8 |
| REQ-SYS-006 | Activity Log Viewer | BR-SYS-006, 012 | SHOULD | 3 |
| REQ-SYS-007 | Menu Synchronisation | BR-SYS-011, 012 | MUST | 4 |
| REQ-SYS-008 | Platform Backup Management | BR-SYS-020, 012 | SHOULD | 5 |
| REQ-SYS-009 | Location Reference Data Management | — | COULD | 2 |
| REQ-SYS-010 | Media Asset Viewer | — | COULD | 2 |

### 3.2 Business Rules Summary

| BR-ID | Rule | Priority |
|-------|------|:--------:|
| BR-SYS-001 | Setting key is permanent — edit endpoint must strip it | P0 |
| BR-SYS-002 | Menu system identifier (code) is permanent — update endpoint must strip it | P0 |
| BR-SYS-003 | Category heading menu item must have no parent | P0 |
| BR-SYS-004 | On drag-drop reorder, all siblings at the same level are renumbered sequentially | P1 |
| BR-SYS-005 | Settings with `is_public=false` are masked in all list views | P0 |
| BR-SYS-006 | Keys containing `password`, `api_key`, `secret`, `token` excluded from audit log | P0 |
| BR-SYS-007 | No Dropdown Value without a matching Dropdown Need | P0 |
| BR-SYS-008 | Group key is always derived server-side as `tablename.columnname` | P0 |
| BR-SYS-009 | Ordinal auto-assigned as MAX+1; must be unique within key group | P1 |
| BR-SYS-011 | Menu Sync is Super Admin only | P0 |
| BR-SYS-012 | Every mutation must produce an audit log entry | P0 |
| BR-SYS-013 | Authoritative Setting model is `Modules\SystemConfig\Models\Setting` | P0 |
| BR-SYS-014 | Dropdown Need (database tier, table, column) must be unique | P0 |
| BR-SYS-015 | System-protected Dropdown Needs cannot be edited or deleted | P1 |
| BR-SYS-016 | Dropdown Value deletion blocked if school data references it | P1 |
| BR-SYS-017 | Translation uses upsert (updateOrCreate) per menu item + language | P1 |
| BR-SYS-018 | All SYS routes accessible only from central domain | P0 |
| BR-SYS-019 | School-admin path: group key is read-only | P1 |
| BR-SYS-020 | Backup runs are queued background jobs | P1 |

---

## 4. Controllers

| # | Controller | Route Prefix | Scope | Lines | Status |
|---|-----------|-------------|-------|:-----:|--------|
| 1 | `MenuController` | `system-config/menu` | Central | 272 | PARTIAL |
| 2 | `MenuSyncController` | `system-config/sync-*` | Central | 2,760 | PARTIAL |
| 3 | `SettingController` | `system-config/setting` | Tenant | 72 | PARTIAL |
| 4 | `SystemConfigController` | `system-config/dashboard` | Central | — | PARTIAL |
| 5 | `TenantDropdownController` | `system-config/dropdown` | Tenant | — | PARTIAL |
| 6 | `TenantDropdownNeedController` | `system-config/dropdown-need` | Tenant | — | PARTIAL |
| 7 | `TenantActivityLogController` | `system-config/activity-log` | Tenant | — | PARTIAL |
| 8 | `TenantLocationController` | `system-config/location` | Tenant | — | PARTIAL |
| 9 | `TenantMediaStoreController` | `system-config/media-store` | Tenant | — | PARTIAL |
| 10 | `BackupController` | `maintenance/backup` | Central | — | PARTIAL |
| 11 | `BackupScheduleController` | `maintenance/backup-schedule` | Central | — | PARTIAL |

---

## 5. Models (Owned)

| # | Model | Table | Connection | SoftDeletes | Fillable Fields |
|---|-------|-------|------------|:-----------:|-----------------|
| 1 | `Setting` | `sys_settings` | `mysql` (tenant) | No | key, value, type, is_public |
| 2 | `Menu` | `glb_menus` | `mysql` (global) | Yes | parent_id, is_category, code, slug, title, description, icon, route, permission, sort_order, visible_by_default, is_active, menu_for |
| 3 | `Translation` | `glb_translations` | `global_master_mysql` | No | language_id, key, value |
| 4 | `Dropdown` | `sys_dropdowns` | `mysql` (tenant) | — | — |
| 5 | `DropdownNeed` | `sys_dropdown_needs` | `mysql` (tenant) | — | — |
| 6 | `DropdownNeedDropdown` | `sys_dropdown_need_dropdowns` | `mysql` (tenant) | — | — |

---

## 6. Databases & Tables

### 6.1 prime_db (Tenant Database)

| Table | Prefix | Type | Purpose |
|-------|--------|------|---------|
| `sys_settings` | `sys_` | Core | Platform key-value settings |
| `sys_dropdown_needs` | `sys_` | Core | Registry of dropdown-eligible table/column pairs |
| `sys_dropdowns` | `sys_` | Core | Actual dropdown option values |
| `sys_dropdown_need_dropdowns` | `sys_` | JNT | Junction: needs ↔ values |
| `sys_activity_logs` | `sys_` | Core | Polymorphic audit log entries |
| `sys_media` | `sys_` | Core | Spatie media-library assets |
| `sys_backup_runs` | `sys_` | Core | Backup execution records |

### 6.2 global_db (global_master_mysql)

| Table | Prefix | Type | Purpose |
|-------|--------|------|---------|
| `glb_menus` | `glb_` | Core | Navigation menu items (recursive tree) |
| `glb_menu_module_jnt` | `glb_` | JNT | Menu ↔ Module links |
| `glb_translations` | `glb_` | Core | Polymorphic translations for menu items |
| `glb_languages` | `glb_` | Ref | Available languages |
| `glb_countries` | `glb_` | Ref | Country reference data |
| `glb_states` | `glb_` | Ref | State reference data |
| `glb_districts` | `glb_` | Ref | District reference data |
| `glb_cities` | `glb_` | Ref | City reference data |

---

## 7. Dependencies

| Consumer | Provider | What is Provided |
|----------|----------|-----------------|
| All 40+ tenant modules | SYS (Dropdowns) | Every configurable dropdown field in school forms |
| All school applications | SYS (Menus) | Entire sidebar navigation tree via MenuSync |
| Notification module (NTF) | SYS (Settings) | SMTP host/port/credentials, SMS provider & API key |
| Auth system | SYS (Settings) | Password policy, OTP, MFA configuration |
| All modules | SYS (Activity Log) | Platform-wide audit trail via `activityLog()` helper |
| SyllabusBooks (SLK) | SYS (Media) | Book cover image storage |

---

## 8. Routes Overview

### Central Routes (`routes/web.php` + `Modules/SystemConfig/routes/web.php`)

| Method | URI | Controller | Permission |
|--------|-----|-----------|------------|
| GET | `/system-config/dashboard` | `SystemConfigController@index` | — |
| GET | `/system-config/sync-menus` | `MenuSyncController@sync` | `system-config.menu.sync` |
| GET | `/system-config/sync-prime-menus` | `MenuSyncController@syncPrime` | `system-config.menu.sync` |
| GET | `/system-config/refresh-menu-cache` | `MenuSyncController@refreshCache` | — |
| GET | `/system-config/menu` | `MenuController@index` | `system-config.menu.viewAny` |
| GET | `/system-config/menu/create` | `MenuController@create` (stub) | `system-config.menu.create` |
| POST | `/system-config/menu` | `MenuController@store` | `system-config.menu.create` |
| GET | `/system-config/menu/{id}/edit` | `MenuController@edit` | `system-config.menu.update` |
| PUT | `/system-config/menu/{id}` | `MenuController@update` | `system-config.menu.update` |
| DELETE | `/system-config/menu/{id}` | `MenuController@destroy` (stub) | `system-config.menu.delete` |
| GET | `/system-config/menu/trash` | `MenuController@trashedMenu` | `system-config.menu.restore` |
| POST | `/system-config/menu/{id}/restore` | `MenuController@restore` (stub) | `system-config.menu.restore` |
| DELETE | `/system-config/menu/{id}/force-delete` | `MenuController@forceDelete` | `system-config.menu.forceDelete` |
| POST | `/system-config/menu/{id}/toggle-status` | `MenuController@toggleStatus` (stub) | — |
| POST | `/system-config/menu/update-menu` | `MenuController@updateMenu` | `system-config.menu.update` |

### Tenant Routes (`routes/tenant.php`)

| Method | URI | Controller | Permission |
|--------|-----|-----------|------------|
| GET | `/system-config/setting` | `SettingController@index` | `system-config.setting.viewAny` |
| GET | `/system-config/setting/{id}/edit` | `SettingController@edit` | `system-config.setting.update` |
| PUT | `/system-config/setting/{id}` | `SettingController@update` | `system-config.setting.update` |
| GET | `/system-config/activity-log` | `TenantActivityLogController@index` | — |
| GET | `/system-config/media-store` | `TenantMediaStoreController@index` | — |
| GET | `/system-config/location` | `TenantLocationController@index` | — |
| GET | `/system-config/dropdown` | `TenantDropdownNeedController@index` | — |
| (+ many) | `/system-config/dropdown-need/*`, `/system-config/dropdowns/*` | Various | — |

---

## 9. Known Gaps & Risks

| Risk-ID | Risk | Impact | Priority |
|---------|------|:------:|:--------:|
| RISK-SYS-001 | SystemConfigController (dashboard) has zero auth on all 7 methods | H | P0 |
| RISK-SYS-002 | MenuSyncController auth was COMMENTED OUT | H | P0 |
| RISK-SYS-003 | DropdownsSeeder failure cascades to every module | M | P1 |
| RISK-SYS-004 | Duplicate Setting model causes import ambiguity | M | P1 |
| RISK-SYS-005 | SettingController validates wrong table `settings` instead of `sys_settings` | H | P0 |
| RISK-SYS-006 | MenuSyncController is 1,702 lines (SRP violation) | M | P1 |
| RISK-SYS-007 | sys_settings/sys_dropdown_needs/sys_dropdowns lack soft-delete columns | L | P2 |
| RISK-SYS-009 | Zero HTTP/feature tests (22 tests only check class existence) | H | P0 |

---

## 10. Reports

| RPT-ID | Name | Audience | Source |
|--------|------|----------|--------|
| RPT-SYS-001 | Platform Activity Audit Report | Super Admin, Platform Support | `sys_activity_logs` |
| RPT-SYS-002 | Backup History Report | Super Admin | `sys_backup_runs` |

---

## 11. Effort Summary

| Sprint | Hours | Focus |
|--------|:-----:|-------|
| Sprint 1 — Security Hardening | 8 h | All P0 auth gaps |
| Sprint 2 — Broken Functionality Fix | 18 h | Stub methods, validation, SRP, route migration |
| Sprint 3 — Dropdown UI Completion | 12 h | Dropdown management UI |
| Sprint 4 — Activity Log, Backup, DDL | 8 h | Activity log, backup audit, DDL fixes |
| **Total** | **46 h** | |
