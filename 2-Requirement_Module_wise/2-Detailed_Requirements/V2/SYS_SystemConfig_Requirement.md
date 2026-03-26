# SystemConfig Module — Requirement Specification Document v2
**Version:** 2.0  |  **Date:** 2026-03-26  |  **Author:** Claude Code (Automated)
**Platform:** Prime-AI Academic Intelligence Platform
**Module Code:** SYS  |  **Module Path:** `Modules/SystemConfig/`
**Module Type:** Prime  |  **Database:** `prime_db`
**Table Prefix:** `sys_*`  |  **Processing Mode:** FULL
**RBS Reference:** PG (System Configuration)  |  **RBS Version:** v4.0
**V1 Baseline:** `2-Requirement_Module_wise/2-Detailed_Requirements/V1/Dev_Done/SYS_SystemConfig_Requirement.md`
**Gap Analysis:** `3-Project_Planning/2-Gap_Analysis/2-Modules_Wise/2026Mar22/SystemConfig_Deep_Gap_Analysis.md`
**Generation Batch:** 1/10

---

## Table of Contents

1. [Module Overview](#1-module-overview)
2. [Scope and Boundaries](#2-scope-and-boundaries)
3. [Actors and User Roles](#3-actors-and-user-roles)
4. [Functional Requirements](#4-functional-requirements)
5. [Data Model](#5-data-model)
6. [Controller and Route Inventory](#6-controller-and-route-inventory)
7. [Form Request Validation Rules](#7-form-request-validation-rules)
8. [Business Rules](#8-business-rules)
9. [Permission and Authorization Model](#9-permission-and-authorization-model)
10. [Policy Inventory](#10-policy-inventory)
11. [Tests Inventory](#11-tests-inventory)
12. [Known Issues and Technical Debt](#12-known-issues-and-technical-debt)
13. [API Endpoints](#13-api-endpoints)
14. [Non-Functional Requirements](#14-non-functional-requirements)
15. [Integration Points](#15-integration-points)
16. [V2 Development Plan and Priority Queue](#16-v2-development-plan-and-priority-queue)

---

## 1. Module Overview

### 1.1 Purpose

SystemConfig is the **central platform administration module** for Prime-AI. It runs exclusively on the prime/central domain and provides Super-Admins with tools to manage the global platform configuration. Every tenant school on the platform is directly affected by changes made here — menus, settings, and dropdown values propagate across all tenant applications.

The module sits at the intersection of three concerns:

1. **Platform Settings** — Key-value store for application-level behavior (SMTP credentials, auth policies, SMS providers, feature flags)
2. **Navigation Management** — Application menu hierarchy stored in `glb_menus`; tenant sidebar is rendered directly from this
3. **Dropdown / Enumeration Management** — Configurable dropdown values in `sys_dropdown_table` consumed by every module's form fields
4. **Translation Management** — Per-language translations for menu titles and entity labels

### 1.2 Module Position in the Platform

```
Platform Layer          Module               Database              Notes
─────────────────────────────────────────────────────────────────────────────
Central (Super-Admin)   SystemConfig (SYS)   prime_db              sys_settings, sys_dropdown_*
                                              global_db             glb_menus, glb_translations
Tenant (All Schools)    All Modules          Reads from both DBs   Sidebar, dropdowns, settings
```

### 1.3 Module Characteristics

| Attribute             | Value                                                                                |
|-----------------------|--------------------------------------------------------------------------------------|
| Laravel Module Name   | `SystemConfig` (nwidart/laravel-modules v12)                                         |
| Namespace             | `Modules\SystemConfig`                                                               |
| Module Code           | SYS                                                                                  |
| Domain Scope          | Central only (admin/prime domain — NOT tenant domains)                               |
| DB Connections        | `prime_mysql` (prime_db) + `global_master_mysql` (global_db) + `mysql` (glb_menus)  |
| Table Prefix          | `sys_*` (settings, dropdowns, RBAC) + `glb_*` (menus, translations)                 |
| Auth Status           | CRITICAL — SystemConfigController has ZERO auth on all 7 methods                    |
| Frontend Stack        | Bootstrap 5 + AdminLTE 4                                                             |
| Completion Status     | ~53% (Gap Analysis score: D+)                                                        |
| Controllers           | 4 (`SystemConfigController`, `MenuController`, `SettingController`, `MenuSyncController`) |
| Models                | 3 (`Menu`, `Setting`, `Translation`)                                                 |
| Services              | 0 (none — P1 gap)                                                                    |
| FormRequests          | 1 (`MenuRequest` only — `SettingRequest` missing)                                    |
| Policies              | 2 (`MenuPolicy` partially working, `SystemConfigPolicy` empty stub)                  |
| Tests                 | 1 file — 22 unit tests, 0 feature/HTTP tests                                         |
| Lines of Code         | ~2,200 (MenuSyncController alone is 1,702 lines)                                     |

### 1.4 Sub-Modules / Feature Areas

| # | Sub-Module | Description | Status |
|---|-----------|-------------|--------|
| 1 | System Settings | Global platform key-value configuration (SMTP, SMS, auth) | 🟡 Partial — view exists, edit broken |
| 2 | Menu Management | Application navigation tree CRUD + drag-drop reorder | 🟡 Partial — 60% done |
| 3 | Menu Sync | Sync menu definitions from code to DB (1,702-line controller) | ✅ Functional but no auth |
| 4 | Translation Management | Per-language translations for menu/entity labels | 🟡 Read only — no create/edit UI |
| 5 | Dropdown Needs Registry | Developer-defined registry of which columns need dropdowns | ❌ No UI |
| 6 | Dropdown Value Management | CRUD for `sys_dropdown_table` values | ❌ No UI |

### 1.5 V2 Mandate

V2 addresses the **29 confirmed gaps** from the 2026-03-22 deep audit, including 5 P0 critical security failures, 9 P1 high-priority items, and architectural deficiencies that prevent this module from being production-ready.

---

## 2. Scope and Boundaries

### 2.1 In Scope (V2)

- Full CRUD for platform settings (`sys_settings`) — properly authenticated and validated
- Menu hierarchy management: complete CRUD, drag-drop reorder, soft delete, restore, force delete, toggle status
- Menu translation management (create, edit, delete) for `glb_translations`
- Dropdown needs registry management (`sys_dropdown_needs`)
- Dropdown value management (`sys_dropdown_table` CRUD)
- Dropdown-need junction management (`sys_dropdown_need_table_jnt`)
- Activity logging for all admin mutations
- Authorization: all routes protected with correct `Gate::authorize()` + Spatie permissions
- Self-contained module routing: all routes defined in `Modules/SystemConfig/routes/web.php`
- Service layer extraction: `MenuSyncService` from the 1,702-line `MenuSyncController`
- Duplicate Setting model consolidation: remove `Modules\Prime\Models\Setting`, use `Modules\SystemConfig\Models\Setting` as canonical
- Policy correction: `MenuPolicy` permission prefix mismatch fix, `SystemConfigPolicy` implementation

### 2.2 Out of Scope (V2)

- Tenant-specific menu customization (menus are platform-wide; per-tenant visibility controlled by module license assignment)
- Email delivery and SMS sending infrastructure (in `Notification` module; SystemConfig only stores provider credentials)
- User and role CRUD management (handled by `Auth` and `UserManagement` modules — SystemConfig only reads roles/permissions for its own access control)
- Database backup/restore operations (infrastructure level)
- System health monitoring dashboards (separate concern, not planned for this module)
- Tenant database migrations (handled by TenantCreation module)

### 2.3 RBS v4.0 Reference Mapping

| RBS Section   | RBS Feature                              | SystemConfig Coverage                                             | Status |
|---------------|------------------------------------------|-------------------------------------------------------------------|--------|
| PG-01         | Platform Settings Management             | `sys_settings` CRUD                                               | 🟡     |
| PG-02         | Email/SMTP Configuration                 | `sys_settings` keys: smtp_host, smtp_port, smtp_username          | 🟡     |
| PG-03         | SMS Provider Configuration               | `sys_settings` keys: sms_provider, sms_api_key                    | ❌     |
| PG-04         | Navigation Menu Management               | `glb_menus` CRUD + drag-drop                                      | 🟡     |
| PG-05         | Menu Translation                         | `glb_translations` polymorphic read; write not implemented        | 🟡     |
| PG-06         | Dropdown / Picklist Management           | `sys_dropdown_table` + `sys_dropdown_needs`                       | ❌     |
| PG-07         | Module Registry                          | Read-only view planned (enable/disable modules via Prime module)  | ❌     |
| PG-08         | Audit Log Viewer                         | `sys_activity_logs` read-only viewer                              | ❌     |
| A3-01         | Password Policy (Auth Rules)             | `sys_settings` keys: password_min_length, password_expiry_days    | ❌     |
| A3-02         | MFA Configuration                        | `sys_settings` keys: otp_enabled, mfa_required                    | ❌     |

---

## 3. Actors and User Roles

### 3.1 Primary Actors

| Actor | Description | Access Level | Notes |
|-------|-------------|--------------|-------|
| Super Admin | Prime-AI platform owner/operator | Full access to all SystemConfig features | Protected by DB trigger — cannot be deleted or demoted |
| Platform Manager | Senior platform staff | Menu management, translation, read settings | Cannot create/delete settings |
| Platform Support | Support team | Read-only access to settings, menus, activity logs | View only |

### 3.2 Role Definitions

Roles are defined in `sys_roles` with `guard_name = 'web'` and `is_system = 1` for platform-level roles. The `is_pg_user = 1` flag on `sys_users` distinguishes platform users from tenant users.

### 3.3 Important Constraint

SystemConfig is a **central module only**. No tenant user (`is_pg_user = 0`) should ever have access to any SystemConfig route. All routes must be gated behind both central-domain middleware and explicit `Gate::authorize()` checks. Tenant users accessing the central domain must be rejected at the auth layer before reaching any SystemConfig controller.

### 3.4 Privilege Separation for Dropdown Management

Per the DDL comments and V1 requirements:
- **PG Users** (`is_pg_user = 1`): Can create dropdown values via both Option 1 (DB details: db_type + table + column) and Option 2 (Menu path: category + menu + field)
- **Tenant Users** (if `tenant_creation_allowed = 1` on a need): Can only use Option 2 (Menu path)
- **Tenant Users** (if `tenant_creation_allowed = 0`): Cannot create dropdown values for that need

---

## 4. Functional Requirements

Status key: ✅ Implemented | 🟡 Partial | ❌ Not Started | 🆕 New in V2

---

### 4.1 Platform Settings Management (FR-SYS-01)

**FR-SYS-01.1 — View Settings List** 🟡
- Display all `sys_settings` records grouped by category (SMTP, SMS, Auth, General, Features)
- Columns shown: key (read-only), description, current value (masked if sensitive), type, is_public flag
- Settings with `is_public = 0` must show masked values in the list (e.g., `••••••••`) for keys containing `password`, `api_key`, `secret`, `token`
- Pagination: 20 records per page; filter by category, search by key/description

**FR-SYS-01.2 — Edit Setting Value** 🟡
- Super-Admin can update only the `value` and `is_public` fields
- `key` and `type` are displayed as read-only — they are code contracts and cannot be changed via UI
- Type-aware form inputs:
  - `boolean` → toggle switch
  - `json` → CodeMirror/Monaco editor with JSON syntax validation
  - `int` → numeric input with min/max validation
  - `string` → text input (password-type if key suggests sensitivity)
  - `date` → date picker
- Before saving, validate the value matches the declared `type`
- On save, log to `sys_activity_logs` with before/after values (but NEVER log the raw value for keys containing `password`, `api_key`, `secret`, `token`)
- Return to settings list with success flash after update

**FR-SYS-01.3 — Create Setting (Super-Admin Emergency Use)** ❌
- Gate: `system-config.settings.create` (Super-Admin only)
- Fields: key (required, unique, snake_case enforced), description, value, type (ENUM), is_public (boolean, default false)
- Key is auto-converted to snake_case by the `setKeyAttribute` mutator on the `Setting` model
- This form is for emergency/developer use only — normal setting creation happens via seeders

**FR-SYS-01.4 — Known Setting Keys** 🟡
| Category | Keys |
|----------|------|
| SMTP | `smtp_host`, `smtp_port`, `smtp_encryption`, `smtp_username`, `smtp_password` |
| SMS | `sms_provider`, `sms_api_key`, `sms_sender_id` |
| Auth | `password_min_length`, `password_requires_uppercase`, `password_requires_number`, `password_expiry_days` |
| MFA | `otp_enabled`, `mfa_required`, `otp_expiry_minutes` |
| Platform | `default_timezone`, `default_currency`, `default_language`, `maintenance_mode` |
| Features | `registration_open`, `tenant_self_service` |

**FR-SYS-01.5 — P0 Gap: Zero Auth on SystemConfigController** ❌
- **CRITICAL:** The current `SystemConfigController` at `Modules/SystemConfig/app/Http/Controllers/SystemConfigController.php` (63 lines) has **ZERO** authorization on all 7 methods (index, create, store, show, edit, update, destroy)
- Any HTTP request to these routes succeeds without authentication or permission check
- All 7 methods must be refactored to call `Gate::authorize()` with appropriate `system-config.settings.*` permission strings before any logic executes
- The `store()`, `update()`, and `destroy()` methods are currently empty stubs — they must be implemented with auth before any data-writing logic is added

---

### 4.2 Menu Management (FR-SYS-02)

**FR-SYS-02.1 — View Menu Tree** ✅
- Display the full `glb_menus` hierarchy as a nested tree, loaded with `whereNull('parent_id')` + eager-loaded `children` + `translations` for `language_id = 2`
- Translated titles displayed via `setTranslatedTitleRecursive()` with fallback to `title` if no translation found
- Show: icon, translated title, route, sort_order, is_active status, is_category badge
- Gate: `system-config.menu.viewAny` — implemented

**FR-SYS-02.2 — Create Menu Item** ❌
- Gate: `system-config.menu.create` — NOT implemented (method is empty stub at line 59-62)
- Fields: parent_id (null for top-level), code (unique, immutable after creation), title (auto-generates slug), description, icon (FontAwesome class), route (validated by `ValidCombinedRoute` rule), sort_order, is_category (boolean), is_direct_link (boolean), visible_by_default, is_active
- Category menus (`is_category = true`) require `parent_id = null` (enforced by DB CHECK + app validation)
- On create: `activityLog($menu, 'Stored', [...])` — pattern exists in `store()`
- Redirect to menu index with `flash('created.menu')` success message

**FR-SYS-02.3 — Edit Menu Item** ✅
- Gate: `system-config.menu.update` — implemented
- All fields editable except `code` (immutable — read-only in the edit form)
- Parent menu tree loaded for the parent_id dropdown
- Translation fields (`language_id`, `translateable_key`, `translateable_value`) in `MenuRequest` but the translation create logic is commented out in `store()` — needs uncomment and implementation in `update()` as well

**FR-SYS-02.4 — Update Menu Item** 🟡
- Gate: `system-config.menu.update` — implemented
- **BUG:** `update()` calls `$menu->update($request->all())` at line 127 — MUST use `$request->validated()` to prevent mass assignment bypass
- `code` must be excluded from the update even if present in request (code is immutable)
- Detailed change log built from `$menu->getChanges()` vs `$original` — pattern is good but broken by `$request->all()` bug
- Activity logging with before/after per-field changes — implemented

**FR-SYS-02.5 — Soft Delete Menu Item** ❌
- Gate: `system-config.menu.delete` — NOT implemented (method empty at line 164-167)
- Soft delete via `deleted_at` (Menu model uses `SoftDeletes`)
- Pre-condition: Menu with active children cannot be soft-deleted — must show error message
- Activity log on deletion

**FR-SYS-02.6 — View Trashed Menus** 🟡
- Route: `trashedMenu()` at line 171-178
- **BUG:** Missing `Gate::authorize('system-config.menu.viewAny')` check
- **BUG:** View reference uses dot notation `systemconfig.menu.trash` instead of module double-colon `systemconfig::menu.trash` — will fail with view-not-found error
- Lists all `Menu::onlyTrashed()` records

**FR-SYS-02.7 — Restore Soft-Deleted Menu** ❌
- Gate: `system-config.menu.restore` — NOT implemented (method empty at line 183-185)
- Restore via `Menu::withTrashed()->findOrFail($id)->restore()`
- Activity log on restore

**FR-SYS-02.8 — Force Delete Menu** ✅
- Gate: no auth check — but method is implemented and calls `forceDelete()`
- **GAP:** Missing `Gate::authorize('system-config.menu.forceDelete')` — any authenticated user can permanently delete menu items
- Activity log on force delete — implemented

**FR-SYS-02.9 — Toggle Active Status** ❌
- Gate: `system-config.menu.update` — NOT implemented (method empty at line 203-207)
- Toggle `is_active` on `Menu` record
- Returns JSON response for AJAX toggle switches in UI
- Activity log on toggle

**FR-SYS-02.10 — Drag-and-Drop Reorder** ✅
- Gate: `system-config.menu.update` — implemented
- AJAX PATCH endpoint: accepts `menu_id`, `parent_id`, `sort_order`
- Category menus (`is_category = true`) cannot be re-parented — returns HTTP 422 with flash message if attempted
- Non-null `parent_id = 0` is treated as `null` (root level)
- Sibling renumbering: after saving, all siblings of the moved item are reordered from `sort_order=1` upward, skipping the slot occupied by the moved item
- Returns JSON `{ success: true/false, message: "..." }`
- Activity log on reorder — implemented

**FR-SYS-02.11 — Menu Sync (MenuSyncController)** 🟡
- 1,702-line controller that truncates all `menu_for = 'tenant'` records and re-creates from hardcoded definitions
- `sync()` endpoint at `GET /system-config/sync-menus`
- **CRITICAL GAP:** Authorization check at lines 42-47 is COMMENTED OUT — any request triggers a full menu truncate + re-create
- Uses `SET FOREIGN_KEY_CHECKS=0` to bypass FK constraints during truncate — acceptable but must be protected by auth
- Maintains `legacyCodesToDelete` array for renamed/removed menu codes
- **P1 Gap:** Extract sync business logic into `MenuSyncService` — controller is 1,702 lines, violating SRP

---

### 4.3 Translation Management (FR-SYS-03)

**FR-SYS-03.1 — Display Translations on Menu Edit** 🟡
- Current: `edit()` loads translations for `language_id = 2` via eager loading
- Target: Show all available translations per language on the edit form
- Hardcoded `$languageId = 2` at lines 22 and 105 of `MenuController` — must be dynamic

**FR-SYS-03.2 — Add/Edit Translation for Menu Item** ❌
- `MenuRequest` includes `language_id`, `translateable_key`, `translateable_value` fields (already validated)
- `store()` has the translation create logic commented out (lines 72-80) — must be uncommented and implemented
- `update()` must also create/update translations when `translateable_value` is provided
- Polymorphic: `translatable_type = 'Modules\SystemConfig\Models\Menu'`, `translatable_id = $menu->id`
- UNIQUE constraint: `(translatable_type, translatable_id, language_id, key)` — use `updateOrCreate()` to handle upserts

**FR-SYS-03.3 — Translation Management UI (Standalone)** ❌
- List all translations for a given entity type + id
- Filter by language
- In-line edit capability
- Languages sourced from `glb_languages` table (managed by GlobalMaster module)
- `Translation` model uses `global_master_mysql` connection (reads from global_db)

**FR-SYS-03.4 — Language Selection** ❌
- Replace hardcoded `$languageId = 2` with user-preference-based or request-parameter-based language selection
- Fall back to platform default language setting (`default_language` key in `sys_settings`)

---

### 4.4 Dropdown Management (FR-SYS-04)

**FR-SYS-04.1 — Dropdown Needs Registry — List** ❌
- Gate: `system-config.dropdown.viewAny`
- List all `sys_dropdown_needs` records
- Columns: db_type, table_name, column_name, menu_category, main_menu, sub_menu, field_name, is_system, tenant_creation_allowed, compulsory, dropdown_tabel_record_exist
- Filter by db_type, compulsory, tenant_creation_allowed

**FR-SYS-04.2 — Dropdown Needs Registry — Create (Developer)** ❌
- Gate: `system-config.dropdown.create` (Super-Admin + developer role only)
- Fields: db_type (ENUM: Prime/Tenant/Global), table_name, column_name, menu_category, main_menu, sub_menu, tab_name, field_name, is_system (default 1), tenant_creation_allowed (default 0), compulsory (default 1)
- UNIQUE constraints on both (db_type, table_name, column_name) AND (menu_category, main_menu, sub_menu, tab_name, field_name)
- **Note on DDL inconsistency:** `is_system DEFAULT 1` comment says "If true, this Dropdown can be created by Tenant" but the correct field for that purpose is `tenant_creation_allowed` — this contradiction (DB-04 from gap analysis) must be documented as a known DDL ambiguity; application logic must use `tenant_creation_allowed` for the tenant-creation permission check

**FR-SYS-04.3 — Dropdown Values — Create** ❌
- Gate: `system-config.dropdown.create`
- **PG User path (Option 1 — DB Details):** Select DB type → table name → column name (cascading dropdowns from `sys_dropdown_needs` records)
- **PG User path (Option 2 — Menu Detail):** Select menu_category → main_menu → sub_menu → tab_name → field_name (all cascading from `sys_dropdown_needs`)
- **Tenant User path (if allowed):** Only Option 2 is available — no Option selector button shown
- Fields on `sys_dropdown_table`: ordinal (auto-increment within key group), key (auto-derived as `table.column`), value (required), type (ENUM: String/Integer/Decimal/Date/Datetime/Time/Boolean), additional_info (JSON, optional), is_active (default 1)
- Pre-condition: A matching `sys_dropdown_needs` record must exist; if not, return error "No dropdown need configured for this field"
- After creation, auto-create junction record in `sys_dropdown_need_table_jnt`
- Auto-set `dropdown_tabel_record_exist = 1` on the parent `sys_dropdown_needs` record

**FR-SYS-04.4 — Dropdown Values — List** ❌
- Gate: `system-config.dropdown.viewAny`
- Group by `key` — show all values for each key group
- Display: ordinal, key, value, type, is_active, additional_info preview
- Filter by key, type, is_active

**FR-SYS-04.5 — Dropdown Values — Edit** ❌
- Gate: `system-config.dropdown.update`
- Fields editable: value, type, ordinal (within key group), additional_info, is_active
- `key` is not editable (it is derived from the needs registry)
- Ordinal uniqueness per key must be re-validated on edit
- Activity log on update

**FR-SYS-04.6 — Dropdown Values — Delete (Soft)** ❌
- Gate: `system-config.dropdown.delete`
- Note: `sys_dropdown_table` has `is_active` but no `deleted_at` in the current DDL
- Soft delete via setting `is_active = 0` (DDL gap DB-02 variation — no `deleted_at` on dropdown tables)
- Cannot delete a dropdown value if it is currently referenced by active tenant data (application-level check)

**FR-SYS-04.7 — Ordinal Management** ❌
- `ordinal` must be UNIQUE per `key` group (UNIQUE KEY `uq_dropdownTable_key_ordinal`)
- When creating, auto-assign the next available ordinal within the key group
- When editing ordinal, validate no collision within the key group before saving

---

### 4.5 Activity Log Viewer (FR-SYS-05) 🆕

**FR-SYS-05.1 — View Activity Logs** ❌
- Gate: `system-config.activityLog.viewAny` (Super-Admin only)
- Read-only view of `sys_activity_logs`
- Columns: subject_type, subject_id, user_id (with user name join), event, ip_address, created_at
- `properties` JSON column rendered as expandable/collapsible detail panel
- Filter: by subject_type, event, user, date range
- Pagination: 50 records per page, ordered by `created_at DESC`
- `sys_activity_logs` FK: `user_id → sys_users.id` (ON DELETE CASCADE)

**FR-SYS-05.2 — Activity Log Detail** ❌
- Click on a log entry to expand/view full `properties` JSON
- Show before/after values for update events
- No editing or deletion of audit logs (append-only)

---

### 4.6 Duplicate Setting Model Resolution (FR-SYS-06) 🆕

**FR-SYS-06.1 — Consolidate Setting Model** ❌
- **P0 Architecture Gap:** Two identical `Setting` models exist on the same `sys_settings` table:
  - `Modules\Prime\Models\Setting` — `Modules/Prime/app/Models/Setting.php`
  - `Modules\SystemConfig\Models\Setting` — `Modules/SystemConfig/app/Models/Setting.php`
- Both have identical `$fillable`, identical mutators (`setKeyAttribute`, `getDisplayKeyAttribute`), and no `SoftDeletes`
- The canonical model must be `Modules\SystemConfig\Models\Setting` (SystemConfig owns `sys_*` tables)
- `Modules\Prime\Models\Setting` must be deleted and all references updated to import from `Modules\SystemConfig`
- Any controllers in the Prime module using `Modules\Prime\Models\Setting` must be updated to use `Modules\SystemConfig\Models\Setting`

---

## 5. Data Model

### 5.1 Primary Tables (from `prime_db_v2.sql`)

| Table | Database | Purpose | Key Columns | Soft Delete |
|-------|---------|---------|-------------|-------------|
| `sys_permissions` | prime_db | RBAC permissions (Spatie) | short_name, name, guard_name, is_active | No `deleted_at` |
| `sys_roles` | prime_db | RBAC roles (Spatie) | name, short_name, guard_name, is_system, is_active | No `deleted_at` |
| `sys_role_has_permissions_jnt` | prime_db | Role-permission map | permission_id (FK), role_id (FK) | Junction — no soft delete |
| `sys_model_has_permissions_jnt` | prime_db | Direct model-permission map | permission_id (FK), model_type, model_id | Junction — no soft delete |
| `sys_model_has_roles_jnt` | prime_db | Model-role map | role_id (FK), model_type, model_id | Junction — no soft delete |
| `sys_users` | prime_db | Platform users | emp_code, name, email, is_super_admin, is_pg_user, two_factor_auth_enabled | Has `deleted_at` |
| `sys_settings` | prime_db | Platform configuration | key (UNIQUE), value, type, is_public | No `deleted_at` (DDL gap) |
| `sys_dropdown_needs` | prime_db | Dropdown field registry | db_type, table_name, column_name, tenant_creation_allowed | Has `is_active`; no `deleted_at` |
| `sys_dropdown_table` | prime_db | Dropdown values | ordinal, key, value, type ENUM, additional_info JSON | Has `is_active`; no `deleted_at` |
| `sys_dropdown_need_table_jnt` | prime_db | Need-value link | dropdown_needs_id (FK), dropdown_table_id (FK) | Has `is_active` |
| `sys_media` | prime_db | Polymorphic file attachments | model_type, model_id, uuid, file_name, disk | No `deleted_at` |
| `sys_activity_logs` | prime_db | Audit trail | subject_type, subject_id, user_id (FK), event, properties JSON, ip_address | Append-only — no soft delete appropriate |
| `glb_menus` | global_db | Application navigation tree | parent_id (self-ref), code (UNIQUE), title, icon, route, sort_order, is_category, menu_for | Has `deleted_at` (SoftDeletes on model) |
| `glb_translations` | global_db | Multilingual content | translatable_type, translatable_id, language_id, key, value | No `deleted_at` on model |

### 5.2 DDL Constraints (Critical)

| Constraint | Table | Details |
|------------|-------|---------|
| UNIQUE KEY `uq_settings_key` | `sys_settings` | One row per setting key |
| UNIQUE KEY `uq_DDNeeds_dbType_tableName_columnName` | `sys_dropdown_needs` | One need entry per (db_type + table + column) |
| UNIQUE KEY `uq_DDNeeds_category_mainMenu_subMenu_tabName_fieldName` | `sys_dropdown_needs` | One need entry per menu path |
| UNIQUE KEY `uq_dropdownTable_key_ordinal` | `sys_dropdown_table` | No two values share same ordinal within a key |
| UNIQUE KEY `uq_dropdownTable_key_value` | `sys_dropdown_table` | No duplicate values within a key |
| UNIQUE KEY `uq_single_super_admin` (generated column) | `sys_users` | Only one super admin allowed |
| DB TRIGGER `trg_users_prevent_delete_super` | `sys_users` | Cannot DELETE super admin row |
| DB TRIGGER `trg_users_prevent_update_super` | `sys_users` | Cannot demote super admin (is_super_admin 1→0) |
| FK `fk_odelHasPermissions_permissionId` (TYPO) | `sys_model_has_permissions_jnt` | Missing 'm' in constraint name — cosmetic but should be fixed |

### 5.3 Models (Current State)

| Model | Namespace | Table | Connection | SoftDeletes | fillable | Issues |
|-------|-----------|-------|------------|:-----------:|----------|--------|
| `Menu` | `Modules\SystemConfig\Models` | `glb_menus` | `mysql` (explicit override) | YES | parent_id, is_category, code, slug, title, description, icon, route, permission, sort_order, visible_by_default, is_active, menu_for | Connection override fragile if DB config name changes |
| `Setting` | `Modules\SystemConfig\Models` | `sys_settings` | default | NO | key, value, type, is_public | Missing `description` in fillable; no SoftDeletes (consistent with DDL but violates project rule) |
| `Translation` | `Modules\SystemConfig\Models` | `glb_translations` | `global_master_mysql` | NO | language_id, key, value | Missing `translatable_type`, `translatable_id` in fillable (polymorphic parent fields) |

### 5.4 Model Relationships

```
glb_menus self-ref hierarchy:
  Menu.parent_id → Menu.id (BelongsTo parent)
  Menu (1) → (N) Menu via parent_id (HasMany children, ordered by sort_order)
  Menu → recursiveChildren() [HasMany → children → with('recursiveChildren')]

glb_menus translations:
  Menu (1) → (N) Translation [morphMany via translatable_id/type]
  Translation.translatable_type = 'Modules\SystemConfig\Models\Menu'

glb_menus modules:
  Menu (N) ↔ (N) Module via glb_menu_module_jnt [BelongsToMany]
  Menu.modules() → Modules\GlobalMaster\Models\Module

sys_dropdown_needs ↔ sys_dropdown_table:
  DropdownNeed (1) ↔ (1) DropdownTable via sys_dropdown_need_table_jnt
  (UNIQUE constraints on both FKs in junction table enforce 1:1 per current DDL)
```

### 5.5 Models Not Yet Created (V2 Requirement)

| Model (New) | Table | Purpose |
|-------------|-------|---------|
| `DropdownNeed` | `sys_dropdown_needs` | Dropdown field registry entries |
| `DropdownValue` | `sys_dropdown_table` | Dropdown key-value entries |
| `ActivityLog` | `sys_activity_logs` | Read-only audit log viewer |

---

## 6. Controller and Route Inventory

### 6.1 Controller Summary

| Controller | File | Lines | Auth Status | Notes |
|-----------|------|------:|-------------|-------|
| `SystemConfigController` | `app/Http/Controllers/SystemConfigController.php` | 63 | **P0 CRITICAL — ZERO auth on all 7 methods** | All methods are empty stubs |
| `MenuController` | `app/Http/Controllers/MenuController.php` | 270 | PARTIAL — 5/12 methods authorized | `$request->all()` bug in update() |
| `SettingController` | `app/Http/Controllers/SettingController.php` | 89 | PARTIAL — uses `tenant.setting.*` prefix (wrong for central module) | Wrong table name in validation; store() returns raw `$request` |
| `MenuSyncController` | `app/Http/Controllers/MenuSyncController.php` | 1702 | **P0 CRITICAL — auth block commented out** | Truncates menus without auth check |

### 6.2 Routes — Current State

**Module's own `routes/web.php`:** Contains only imports (PHP opening tag + use statements) — **EMPTY, no routes registered** (Gap RT-01).

**`routes/api.php`:** Has `Route::middleware(['auth:sanctum'])->prefix('v1')->group()` with `apiResource('systemconfigs', SystemConfigController::class)` — but `SystemConfigController` has no Sanctum token logic and all methods are stubs.

All actual routes are registered externally in the central application's `routes/web.php` and `routes/tenant.php`.

### 6.3 Routes — Target State (V2)

All routes must be moved into `Modules/SystemConfig/routes/web.php` under the correct middleware group.

**Route Group Prefix:** `system-config` | **Name Prefix:** `system-config.`
**Middleware:** `['auth', 'verified', 'central']` (central-domain guard)

#### Settings Routes

| Method | URI | Controller | Action | Permission |
|--------|-----|-----------|--------|------------|
| GET | `/system-config/settings` | `SystemConfigController` | `index` | `system-config.settings.viewAny` |
| GET | `/system-config/settings/create` | `SystemConfigController` | `create` | `system-config.settings.create` |
| POST | `/system-config/settings` | `SystemConfigController` | `store` | `system-config.settings.create` |
| GET | `/system-config/settings/{setting}` | `SystemConfigController` | `show` | `system-config.settings.viewAny` |
| GET | `/system-config/settings/{setting}/edit` | `SystemConfigController` | `edit` | `system-config.settings.update` |
| PUT/PATCH | `/system-config/settings/{setting}` | `SystemConfigController` | `update` | `system-config.settings.update` |
| DELETE | `/system-config/settings/{setting}` | `SystemConfigController` | `destroy` | `system-config.settings.delete` |

#### Menu Routes

| Method | URI | Controller | Action | Permission |
|--------|-----|-----------|--------|------------|
| GET | `/system-config/menu` | `MenuController` | `index` | `system-config.menu.viewAny` |
| GET | `/system-config/menu/create` | `MenuController` | `create` | `system-config.menu.create` |
| POST | `/system-config/menu` | `MenuController` | `store` | `system-config.menu.create` |
| GET | `/system-config/menu/{menu}/edit` | `MenuController` | `edit` | `system-config.menu.update` |
| PUT/PATCH | `/system-config/menu/{menu}` | `MenuController` | `update` | `system-config.menu.update` |
| DELETE | `/system-config/menu/{menu}` | `MenuController` | `destroy` | `system-config.menu.delete` |
| GET | `/system-config/menu/trashed` | `MenuController` | `trashedMenu` | `system-config.menu.viewAny` |
| PATCH | `/system-config/menu/{id}/restore` | `MenuController` | `restore` | `system-config.menu.restore` |
| DELETE | `/system-config/menu/{id}/force-delete` | `MenuController` | `forceDelete` | `system-config.menu.forceDelete` |
| PATCH | `/system-config/menu/{menu}/toggle-status` | `MenuController` | `toggleStatus` | `system-config.menu.update` |
| PATCH | `/system-config/menu/{menu}/update-menu` | `MenuController` | `updateMenu` | `system-config.menu.update` |
| GET | `/system-config/sync-menus` | `MenuSyncController` | `sync` | `system-config.menu.sync` (Super-Admin only) |

#### Dropdown Routes

| Method | URI | Controller | Action | Permission |
|--------|-----|-----------|--------|------------|
| GET | `/system-config/dropdown-needs` | `DropdownNeedController` | `index` | `system-config.dropdown.viewAny` |
| POST | `/system-config/dropdown-needs` | `DropdownNeedController` | `store` | `system-config.dropdown.create` |
| GET | `/system-config/dropdown-values` | `DropdownValueController` | `index` | `system-config.dropdown.viewAny` |
| GET | `/system-config/dropdown-values/create` | `DropdownValueController` | `create` | `system-config.dropdown.create` |
| POST | `/system-config/dropdown-values` | `DropdownValueController` | `store` | `system-config.dropdown.create` |
| GET | `/system-config/dropdown-values/{id}/edit` | `DropdownValueController` | `edit` | `system-config.dropdown.update` |
| PUT/PATCH | `/system-config/dropdown-values/{id}` | `DropdownValueController` | `update` | `system-config.dropdown.update` |
| DELETE | `/system-config/dropdown-values/{id}` | `DropdownValueController` | `destroy` | `system-config.dropdown.delete` |

#### Activity Log Routes (V2 New)

| Method | URI | Controller | Action | Permission |
|--------|-----|-----------|--------|------------|
| GET | `/system-config/activity-logs` | `ActivityLogController` | `index` | `system-config.activityLog.viewAny` |
| GET | `/system-config/activity-logs/{id}` | `ActivityLogController` | `show` | `system-config.activityLog.viewAny` |

---

## 7. Form Request Validation Rules

### 7.1 MenuRequest — Current State ✅

File: `Modules/SystemConfig/app/Http/Requests/MenuRequest.php`

| Field | Rules | Notes |
|-------|-------|-------|
| `parent_id` | nullable, exists:glb_menus,id | |
| `code` | required, string, max:60, unique:glb_menus (ignore current on update) | Immutable after create — controller must not pass to update() |
| `title` | required, string, max:100, unique:glb_menus (ignore current) | Mutator auto-sets `slug` from title |
| `is_category` | boolean | Checkbox converted from 'on'/null in `prepareForValidation()` |
| `description` | nullable, string, max:255 | |
| `icon` | required, string, max:150 | |
| `route` | required, string, max:255, ValidCombinedRoute rule | Bypassed if `is_category = true AND parent_id = null` |
| `sort_order` | required, integer, min:0, max:255 | |
| `is_direct_link` | boolean | Checkbox converted in prepareForValidation() |
| `visible_by_default` | boolean | Checkbox converted in prepareForValidation() |
| `is_active` | boolean | Checkbox converted in prepareForValidation() |
| `language_id` | nullable | For translation |
| `translateable_key` | nullable | For translation |
| `translateable_value` | nullable | For translation |

**Gap:** `code` should be conditionally `required` only on create (not update). Use `Rule::requiredIf()` or separate `StoreMenuRequest` / `UpdateMenuRequest`.

### 7.2 SettingRequest — Missing ❌

Must be created at `Modules/SystemConfig/app/Http/Requests/SettingRequest.php`.

| Field | Rules | Notes |
|-------|-------|-------|
| `value` | required | Type-specific validation applied conditionally |
| `value` (type=boolean) | boolean | |
| `value` (type=int) | integer | |
| `value` (type=json) | json | Custom rule to validate JSON string |
| `value` (type=date) | date | |
| `value` (type=string) | string, max:255 | |
| `is_public` | boolean | |

Current `SettingController::update()` uses inline `$request->validate()` with wrong table name (`settings` instead of `sys_settings`) and validates a non-existent column `organization_id`. Both must be removed.

### 7.3 DropdownNeedRequest — Missing ❌

| Field | Rules |
|-------|-------|
| `db_type` | required, in:Prime,Tenant,Global |
| `table_name` | required, string, max:150 |
| `column_name` | required, string, max:150 |
| `menu_category` | nullable, string, max:150 |
| `main_menu` | nullable, string, max:150 |
| `sub_menu` | nullable, string, max:150 |
| `tab_name` | nullable, string, max:100 |
| `field_name` | nullable, string, max:100 |
| `is_system` | boolean |
| `tenant_creation_allowed` | boolean |
| `compulsory` | boolean |
| Conditional | If `tenant_creation_allowed = true`: menu_category, main_menu, field_name must be required |

### 7.4 DropdownValueRequest — Missing ❌

| Field | Rules |
|-------|-------|
| `dropdown_needs_id` | required, integer, exists:sys_dropdown_needs,id |
| `value` | required, string, max:100 |
| `type` | required, in:String,Integer,Decimal,Date,Datetime,Time,Boolean |
| `additional_info` | nullable, json |
| `is_active` | boolean |
| Derived `key` | Auto-derived server-side from the needs record (`table_name.column_name`) — not accepted from request |
| Derived `ordinal` | Auto-assigned as next available ordinal within the key group — not accepted from request |

---

## 8. Business Rules

**BR-SYS-01:** Setting `key` is the code-contract — it must never be changed via the UI. The edit form must render `key` as a read-only `<input disabled>`. The controller must exclude `key` from the validated array on update.

**BR-SYS-02:** `glb_menus.code` is the system identifier for a menu item and is immutable after creation. It is used in permission names and route guards across the platform. The update controller must strip `code` from `$request->validated()` before passing to `$menu->update()`.

**BR-SYS-03:** Category menus (`is_category = 1`) must have `parent_id = NULL`. This is enforced at three layers: (a) DB CHECK constraint on `glb_menus`, (b) application validation in `MenuRequest`, (c) `updateMenu()` returns HTTP 422 if `is_category = true AND parent_id != null`.

**BR-SYS-04:** On drag-and-drop menu reorder (`updateMenu`), sibling sort_orders are automatically renumbered to close gaps. The algorithm in the current code: save the moved item's new sort_order → load siblings (excluding moved item) ordered by current sort_order → iterate assigning sequential integers, skipping the moved item's slot.

**BR-SYS-05:** Settings with `is_public = 0` must never be exposed to JavaScript, frontend-accessible API responses, or browser-renderable JSON. Any endpoint that returns settings must filter to `is_public = 1` unless the caller is authenticated as a platform admin.

**BR-SYS-06:** Sensitive setting values (keys containing `password`, `api_key`, `secret`, or `token`) must be masked in all UI outputs and activity log entries. Full values are only shown in the edit form field, which itself must use `type="password"` for such keys.

**BR-SYS-07:** Before creating a dropdown value in `sys_dropdown_table`, a corresponding entry in `sys_dropdown_needs` must exist. The create form resolves this need via cascading dropdowns. A dropdown value record without a needs registry entry is invalid.

**BR-SYS-08:** `sys_dropdown_table.key` follows the format `table_name.column_name` (e.g., `cmp_complaint_actions.action_type`). This key is derived server-side from the `sys_dropdown_needs` record — it is never accepted from the request body.

**BR-SYS-09:** The `ordinal` field in `sys_dropdown_table` must be unique per `key` group. When creating a new dropdown value, the system auto-assigns `MAX(ordinal) + 1` for that key. On edit, the new ordinal is validated against the UNIQUE constraint before saving.

**BR-SYS-10:** Only one Super Admin can exist on the platform. The `sys_users.super_admin_flag` generated column (STORED) combined with UNIQUE KEY `uq_single_super_admin` enforces this at the DB level. DB triggers prevent deletion or demotion of the super admin.

**BR-SYS-11:** The Menu Sync operation (`MenuSyncController::sync()`) performs a destructive truncate + re-create of all `menu_for = 'tenant'` records. It must only be accessible to the Super Admin. The commented-out auth check at lines 42-47 must be re-enabled before production.

**BR-SYS-12:** All mutations (create, update, delete, restore, toggle, reorder) on settings, menus, and dropdown values must be logged to `sys_activity_logs` via the `activityLog()` helper. The log entry must include the authenticated user's name, IP address, and a structured `properties` JSON with before/after values.

**BR-SYS-13:** The canonical `Setting` model is `Modules\SystemConfig\Models\Setting`. The duplicate `Modules\Prime\Models\Setting` (on the same `sys_settings` table) must be removed. No module may create its own model for a `sys_*` table that is owned by SystemConfig.

---

## 9. Permission and Authorization Model

### 9.1 Current Auth State — Security Failures

| Controller | Method | Line(s) | Current Auth | Required Auth | Severity |
|-----------|--------|---------|-------------|---------------|----------|
| `SystemConfigController` | `index()` | 13 | NONE | `system-config.settings.viewAny` | P0 |
| `SystemConfigController` | `create()` | 21 | NONE | `system-config.settings.create` | P0 |
| `SystemConfigController` | `store()` | 29 | NONE | `system-config.settings.create` | P0 |
| `SystemConfigController` | `show()` | 36 | NONE | `system-config.settings.viewAny` | P0 |
| `SystemConfigController` | `edit()` | 44 | NONE | `system-config.settings.update` | P0 |
| `SystemConfigController` | `update()` | 52 | NONE | `system-config.settings.update` | P0 |
| `SystemConfigController` | `destroy()` | 59 | NONE | `system-config.settings.delete` | P0 |
| `MenuSyncController` | `sync()` | 36-47 | Auth block COMMENTED OUT | `system-config.menu.sync` (Super-Admin only) | P0 |
| `MenuController` | `create()` | 59 | NONE | `system-config.menu.create` | P0 |
| `MenuController` | `destroy()` | 164 | NONE | `system-config.menu.delete` | P0 |
| `MenuController` | `trashedMenu()` | 171 | NONE | `system-config.menu.viewAny` | P1 |
| `MenuController` | `restore()` | 183 | NONE | `system-config.menu.restore` | P1 |
| `MenuController` | `forceDelete()` | 187 | NONE | `system-config.menu.forceDelete` | P1 |
| `MenuController` | `toggleStatus()` | 203 | NONE | `system-config.menu.update` | P2 |
| `SettingController` | All methods | 15-87 | Uses `tenant.setting.*` prefix | Must use `system-config.settings.*` | P1 |

### 9.2 Permission Prefix Mismatch

`MenuPolicy` checks `prime.menu.*` permissions (e.g., `$user->can('prime.menu.viewAny')`) but `MenuController` calls `Gate::authorize('system-config.menu.viewAny')`. These do not match — the controller's Gate calls do NOT route through the registered `MenuPolicy`. The policy check and controller check are decoupled and independently evaluating different permission strings.

**Resolution:** Standardize to `system-config.menu.*` prefix in both `MenuPolicy` and all `Gate::authorize()` calls in `MenuController`.

### 9.3 Required Permissions (Target State)

| Resource | Permission Name | Guard | Assigned To |
|----------|----------------|-------|-------------|
| Settings | `system-config.settings.viewAny` | web | Super Admin, Platform Manager, Platform Support |
| Settings | `system-config.settings.create` | web | Super Admin |
| Settings | `system-config.settings.update` | web | Super Admin |
| Settings | `system-config.settings.delete` | web | Super Admin |
| Menu | `system-config.menu.viewAny` | web | Super Admin, Platform Manager |
| Menu | `system-config.menu.create` | web | Super Admin, Platform Manager |
| Menu | `system-config.menu.update` | web | Super Admin, Platform Manager |
| Menu | `system-config.menu.delete` | web | Super Admin |
| Menu | `system-config.menu.restore` | web | Super Admin |
| Menu | `system-config.menu.forceDelete` | web | Super Admin |
| Menu | `system-config.menu.sync` | web | Super Admin only |
| Dropdown | `system-config.dropdown.viewAny` | web | Super Admin, Platform Manager |
| Dropdown | `system-config.dropdown.create` | web | Super Admin, Platform Manager |
| Dropdown | `system-config.dropdown.update` | web | Super Admin, Platform Manager |
| Dropdown | `system-config.dropdown.delete` | web | Super Admin |
| Activity Log | `system-config.activityLog.viewAny` | web | Super Admin |

### 9.4 Seeder Requirements

A `SystemConfigPermissionSeeder` must be created to seed all permissions above into `sys_permissions` and assign them to the appropriate roles in `sys_roles`. The seeder must be idempotent (use `firstOrCreate()`).

---

## 10. Policy Inventory

### 10.1 MenuPolicy — Current State (Broken)

File: `Modules/SystemConfig/app/Policies/MenuPolicy.php`

| Method | Permission Checked | Issue |
|--------|-------------------|-------|
| `viewAny()` | `prime.menu.viewAny` | Wrong prefix — must be `system-config.menu.viewAny` |
| `view()` | `prime.menu.view` | Wrong prefix |
| `create()` | `prime.menu.create` | Wrong prefix |
| `update()` | `prime.menu.update` | Wrong prefix |
| `delete()` | `prime.menu.delete` | Wrong prefix |
| `restore()` | `prime.menu.restore` | Wrong prefix |
| `forceDelete()` | `prime.menu.forceDelete` | Wrong prefix |

**All 7 methods must have their permission prefix changed from `prime.menu.*` to `system-config.menu.*`.**

The policy IS registered in `AppServiceProvider` (line 645 of app service provider) but the mismatch means the policy is never effectively used — controller Gate calls and policy method calls check different permission strings.

### 10.2 SystemConfigPolicy — Current State (Empty Stub)

File: `Modules/SystemConfig/app/Policies/SystemConfigPolicy.php`

Contains only a constructor. The policy is NOT registered in `AppServiceProvider`. It is dead code.

**Target state:** Implement all 5 standard methods (`viewAny`, `create`, `update`, `delete`, `restore`) with `system-config.settings.*` permission checks. Register the policy in `AppServiceProvider` mapping `Setting::class → SystemConfigPolicy::class`.

### 10.3 Policies to Create (V2)

| Policy | Model | Permission Prefix | Priority |
|--------|-------|-------------------|----------|
| `DropdownPolicy` | `DropdownValue` | `system-config.dropdown.*` | P1 |
| `ActivityLogPolicy` | `ActivityLog` | `system-config.activityLog.*` | P2 |

---

## 11. Tests Inventory

### 11.1 Existing Tests

**File:** `Modules/SystemConfig/tests/Unit/SystemConfigModuleTest.php` (144 lines)

| Test Group | Count | Type | What It Tests |
|-----------|------:|------|--------------|
| Setting Model | 5 | Unit | Table name, no SoftDeletes, fillable, setKeyAttribute, getDisplayKeyAttribute |
| Translation Model | 4 | Unit | Table name, connection, fillable, morphTo relationship |
| Menu Model | 9 | Unit | Table name, SoftDeletes, fillable, casts, slug auto-gen, relationships |
| Architecture | 6 | Unit | 4 controllers exist, MenuRequest exists, routes/web.php exists |
| Gate Coverage | 2 | Unit | MenuController and SettingController contain `Gate::authorize` string |
| SoftDeletes | 3 | Unit | Menu uses SoftDeletes; Setting/Translation do not |
| **Total** | **22** | Unit | Model structure + class existence only |

**Coverage gap:** 0 Feature tests. No HTTP testing. The Gate coverage test only checks that the string `Gate::authorize` appears somewhere in the source file — it does NOT verify which methods are protected.

### 11.2 Tests to Create (V2)

#### Feature Tests (HTTP)

| Test Class | Location | Scenarios | Priority |
|-----------|---------|-----------|----------|
| `SystemConfigAuthTest` | `tests/Feature/` | All 7 SystemConfigController methods return 403 without auth; return 403 without correct permission; return 200/redirect with correct permission | P0 |
| `MenuControllerAuthTest` | `tests/Feature/` | create(), destroy(), trashedMenu(), restore(), toggleStatus(), forceDelete() all return 403 without auth | P0 |
| `MenuSyncAuthTest` | `tests/Feature/` | sync() returns 403 without Super Admin role | P0 |
| `MenuControllerTest` | `tests/Feature/` | store() creates record; update() uses validated() not all(); destroy() soft-deletes; restore() restores; forceDelete() permanently deletes | P1 |
| `MenuReorderTest` | `tests/Feature/` | updateMenu() reorders siblings correctly; category cannot be re-parented (422); valid reorder returns 200 JSON | P1 |
| `SettingControllerTest` | `tests/Feature/` | index() lists settings; edit() returns form; update() saves value; is_public=0 values masked in index | P1 |
| `DropdownControllerTest` | `tests/Feature/` | Creating value without needs entry returns error; creating with valid need creates dropdown and junction record | P2 |
| `TranslationTest` | `tests/Feature/` | Translation upsert on menu create/update; fallback to title when no translation | P2 |

#### Unit Tests (New)

| Test Class | Location | Scenarios | Priority |
|-----------|---------|-----------|----------|
| `MenuCategoryConstraintTest` | `tests/Unit/` | Category menu with parent_id fails validation; category re-parent via updateMenu returns 422 | P1 |
| `MenuSortOrderTest` | `tests/Unit/` | Sibling renumbering algorithm produces correct sequence; no sort_order gaps; moved item occupies correct slot | P1 |
| `SettingTypeValidationTest` | `tests/Unit/` | Boolean value validated correctly; JSON value parsed; int validated as integer | P2 |
| `DropdownOrdinalTest` | `tests/Unit/` | Auto-ordinal assigns MAX+1; duplicate ordinal within key fails | P2 |

---

## 12. Known Issues and Technical Debt

### 12.1 P0 — Critical (Fix Before Any Feature Work)

**ISSUE-SYS-01 [P0 — SECURITY]:** `SystemConfigController` has **ZERO authorization** on all 7 methods.
- File: `Modules/SystemConfig/app/Http/Controllers/SystemConfigController.php`, lines 13-61
- Any authenticated HTTP user (tenant user, platform support, unrelated role) can access `/system-config/*` routes
- The `store()`, `update()`, `destroy()` methods are empty stubs — current risk is primarily information disclosure but will become data write risk as implementation proceeds
- Fix: Add `Gate::authorize('system-config.settings.<action>')` as the first statement in each method

**ISSUE-SYS-02 [P0 — SECURITY]:** `MenuSyncController::sync()` authorization check is commented out.
- Lines 42-47 contain an auth check wrapped in `/* ... */` comment block
- Any authenticated user can trigger a full menu truncate + re-create operation
- This is a destructive irreversible operation (truncates `menu_for = 'tenant'` rows)
- Fix: Uncomment and enforce `Gate::authorize('system-config.menu.sync')` + verify only Super Admin has this permission

**ISSUE-SYS-03 [P0 — SECURITY]:** `MenuController::create()` and `MenuController::destroy()` have no authorization.
- `create()` (line 59-62) returns an empty body with no auth check — route is accessible without permission
- `destroy()` (line 164-167) returns empty body with no auth check — DELETE route accessible without permission
- Fix: Add `Gate::authorize()` as first statement and implement the method bodies

**ISSUE-SYS-04 [P0 — MASS ASSIGNMENT]:** `MenuController::update()` uses `$request->all()` at line 127.
- `MenuRequest` is injected and validates input, but `$menu->update($request->all())` passes the raw unvalidated request bag
- This bypasses the FormRequest whitelist and allows injecting any field present in `$fillable`, including `code` (which must be immutable post-creation)
- Fix: Change line 127 to `$menu->update($request->validated())` and strip `code` from the validated array

**ISSUE-SYS-05 [P0 — ARCHITECTURE]:** Duplicate `Setting` model on same table.
- `Modules\Prime\Models\Setting` and `Modules\SystemConfig\Models\Setting` are byte-for-byte identical (same `$table = 'sys_settings'`, same `$fillable`, same mutators)
- Two models for one table means any query on either model returns the same data — this can cause confusion in imports and is a maintenance hazard
- Fix: Delete `Modules/Prime/app/Models/Setting.php`; update all Prime module imports to use `Modules\SystemConfig\Models\Setting`

### 12.2 P1 — High

**ISSUE-SYS-06 [P1 — VALIDATION]:** `SettingController::update()` validates against wrong table name.
- Line 66: `'key' => 'required|string|exists:settings,key'` — table is `sys_settings`, not `settings`
- Line 67: `'organization_id' => 'required|exists:settings,organization_id'` — `organization_id` column does NOT exist in `sys_settings` DDL; this validation will always fail for any setting update
- `SettingController::store()` at line 37 returns the raw `$request` object — this exposes all request headers and body in the HTTP response
- Fix: Create `SettingRequest` with correct table `sys_settings` and correct columns; update `store()` to not return `$request`

**ISSUE-SYS-07 [P1 — POLICY]:** `MenuPolicy` uses wrong permission prefix (`prime.menu.*` vs `system-config.menu.*`).
- `MenuPolicy::viewAny()` checks `$user->can('prime.menu.viewAny')` but `MenuController::index()` calls `Gate::authorize('system-config.menu.viewAny')`
- The Laravel Gate dispatches `system-config.menu.viewAny` check — this will NOT invoke `MenuPolicy::viewAny()` because the policy is registered under a different permission name
- The Gate authorization in the controller passes or fails independently of the policy — the policy is dead code
- Fix: Change all 7 methods in `MenuPolicy` from `prime.menu.*` to `system-config.menu.*`

**ISSUE-SYS-08 [P1 — SRP]:** `MenuSyncController` is 1,702 lines — far exceeds SRP.
- Contains: menu definitions, sync logic, orphan detection, parent resolution, legacy code deletion, summary generation
- Fix: Extract into `MenuSyncService` class; controller becomes a thin HTTP adapter (< 50 lines)

**ISSUE-SYS-09 [P1 — MODULE SELF-CONTAINMENT]:** Module's `routes/web.php` is empty.
- All SystemConfig routes are defined externally in the central application's `routes/web.php` and `routes/tenant.php`
- Route naming collision: `system-config.setting.*` exists in both central web.php (using Prime's SettingController) and tenant.php (using SystemConfig's SettingController) — different controllers, same route names
- Fix: Move all SystemConfig routes into the module's own `routes/web.php`

**ISSUE-SYS-10 [P1 — FUNCTIONALITY]:** 7+ empty/stub method bodies across controllers.
- `SystemConfigController`: store(), update(), destroy() — empty (all 7 methods do nothing meaningful)
- `MenuController`: create(), destroy(), restore(), toggleStatus() — empty bodies
- `SettingController`: destroy() — empty body (method has Gate::authorize but does nothing)
- Fix: Implement each method with proper logic or remove the method and its route

### 12.3 P2 — Medium

**ISSUE-SYS-11 [P2]:** `MenuController::trashedMenu()` uses dot notation for view name.
- Line 177: `return view('systemconfig.menu.trash', ...)` — should be `view('systemconfig::menu.trash', ...)`
- Module views require double-colon notation; dot notation looks for a view in the application's `resources/views/` directory, not the module's views folder
- This will throw a view-not-found exception when the route is accessed

**ISSUE-SYS-12 [P2]:** Hardcoded `$languageId = 2` in `MenuController`.
- Lines 22 and 105 hardcode the translation language ID as `2`
- Should be sourced from: (1) request parameter, (2) auth user preference, (3) `sys_settings.default_language` key
- Fix: Add a helper method to resolve language ID dynamically

**ISSUE-SYS-13 [P2]:** `SystemConfigPolicy` is empty stub and not registered.
- File contains only constructor; no viewAny/create/update/delete/restore methods
- Not registered in `AppServiceProvider` — dead code taking up a file slot
- Fix: Implement fully or delete; register in AppServiceProvider

**ISSUE-SYS-14 [P2]:** `MenuController::trashedMenu()` has no auth check.
- Soft-deleted menu items may contain sensitive navigation data
- Fix: Add `Gate::authorize('system-config.menu.viewAny')` at line 172

**ISSUE-SYS-15 [P2 — DDL]:** FK constraint name typo in `sys_model_has_permissions_jnt`.
- Line 97: `fk_odelHasPermissions_permissionId` (missing 'm') — should be `fk_modelHasPermissions_permissionId`
- Cosmetic but violates naming conventions and will confuse future developers reading the schema

**ISSUE-SYS-16 [P2 — DDL]:** `sys_settings` has no `is_active` or `deleted_at` columns.
- Violates project rule of soft deletes on all tables
- `Setting` model correctly has no `SoftDeletes` trait (consistent with DDL) but the inconsistency with project rules should be addressed in a DDL migration

**ISSUE-SYS-17 [P2 — DDL]:** Contradictory comment on `sys_dropdown_needs.is_system`.
- DDL comment at line 180: `is_system TINYINT(1) DEFAULT 1 -- If true, this Dropdown can be created by Tenant`
- But `tenant_creation_allowed` (next column, default 0) is the actual flag for tenant creation permission
- The `is_system` field appears to mean the dropdown is a system-level (PG-owned) definition, not a tenant-created one — opposite of what the comment says
- Application code must use `tenant_creation_allowed` for permission checks; `is_system` should be treated as "this need was defined by Prime-AI (not tenant)"

### 12.4 P3 — Low

**ISSUE-SYS-18 [P3]:** Multiple sys_* tables missing `created_by` column (project convention).
- Affected: `sys_permissions`, `sys_roles`, `sys_settings`, `sys_dropdown_needs`, `sys_dropdown_table`, `sys_media`
- Low priority as these tables are typically managed by platform admins who are tracked via auth context

**ISSUE-SYS-19 [P3]:** `Menu.$connection = 'mysql'` is fragile.
- Hardcoded connection name `mysql` will break if the default DB connection is renamed
- Should use `config('database.default')` or a named connection constant

**ISSUE-SYS-20 [P3]:** Zero rate limiting on any SystemConfig route.
- Settings update and menu sync endpoints could be hammered
- Should apply `throttle:60,1` middleware to prevent abuse

---

## 13. API Endpoints

### 13.1 Current API State

File: `Modules/SystemConfig/routes/api.php`

```
Route::middleware(['auth:sanctum'])->prefix('v1')->group(function () {
    Route::apiResource('systemconfigs', SystemConfigController::class)->names('systemconfig');
});
```

This registers 5 Sanctum-authenticated API routes (`GET/POST /v1/systemconfigs`, `GET/PUT/DELETE /v1/systemconfigs/{id}`) but `SystemConfigController` has no Sanctum token handling and all methods are empty stubs. These routes are non-functional.

### 13.2 Intended Web AJAX Endpoints

| Method | Route | Controller@Action | Response | Auth |
|--------|-------|------------------|----------|------|
| PATCH | `/system-config/menu/{menu}/update-menu` | `MenuController@updateMenu` | JSON `{success, message}` | `system-config.menu.update` |
| PATCH | `/system-config/menu/{menu}/toggle-status` | `MenuController@toggleStatus` | JSON `{success, is_active}` | `system-config.menu.update` |
| GET | `/system-config/sync-menus` | `MenuSyncController@sync` | JSON `{success, data: {created, updated, unchanged, total}}` | Super Admin only |

### 13.3 V2 No External REST API Planned

SystemConfig is a web-only platform administration module. No public or tenant-facing REST API is planned for V2. The `api.php` routes stub should either be populated with meaningful endpoints or left empty with a comment explaining the decision.

---

## 14. Non-Functional Requirements

### 14.1 Security

- All SystemConfig routes MUST be restricted to the central domain — central middleware must reject any request from a tenant subdomain
- All controller methods MUST call `Gate::authorize()` before executing any logic (the existing middleware `auth` + `verified` is necessary but not sufficient)
- Settings with `is_public = 0` MUST never appear in API responses, JSON payloads, or Blade templates in plaintext — mask or exclude them entirely in non-admin contexts
- The Menu Sync endpoint executes DDL-adjacent operations (FK_CHECKS toggle, truncate-equivalent) — it MUST require Super Admin role, not just authentication
- All form submissions MUST use Laravel CSRF protection (the default for web routes)
- Mass assignment: all controller mutations MUST use `$request->validated()`, never `$request->all()`

### 14.2 Performance

| Operation | Target Response Time | Notes |
|-----------|---------------------|-------|
| Settings index | < 200ms | Small dataset, simple query |
| Menu tree index | < 500ms | Up to 100 items, recursive eager loading |
| Menu drag-drop reorder | < 300ms | Sibling renumbering is O(n) on same-level menus |
| Menu sync | < 30s | Set `set_time_limit(300)` already in code |
| Dropdown list | < 300ms | Grouped query with pagination |
| Activity log list | < 500ms | Indexed on `created_at + user_id`; paginate 50 rows |

### 14.3 Auditability

- ALL write operations (create, update, delete, restore, toggle, reorder) must log to `sys_activity_logs` via the platform `activityLog()` helper
- Log entry must include: subject model reference, event name, authenticated user name + id, IP address, structured before/after `properties` JSON
- Sensitive values (API keys, passwords) must be excluded from the `properties` JSON — log "value changed" but not the actual value
- The `activityLog()` helper is already called correctly in `MenuController::store()`, `update()`, `updateMenu()`, `forceDelete()` — this pattern must be extended to all remaining methods

### 14.4 Consistency and Immutability

- `sys_settings.key` and `glb_menus.code` are immutable post-creation — no UI path or API call may change these fields after the record is created
- `sys_dropdown_table.key` (the `table.column` composite) is derived and never directly editable

### 14.5 Accessibility

- All admin forms must include proper `<label>` associations and ARIA roles
- Toggle switches must have `aria-label` attributes with the setting name
- Error messages must be associated with their input fields via `aria-describedby`

---

## 15. Integration Points

| Module | Integration Type | Direction | Description | Status |
|--------|-----------------|-----------|-------------|--------|
| `GlobalMaster` | Shared tables | Bidirectional | `glb_menus` and `glb_translations` managed by SystemConfig UI; read by all tenant modules for navigation rendering | ✅ Active |
| `Auth` / `UserManagement` | RBAC consumer | SystemConfig reads | All SystemConfig routes gated via Spatie permissions; users/roles defined in `sys_users` / `sys_roles` | 🟡 Partial (permission prefix mismatch) |
| `All Tenant Modules` | Dropdown consumer | SystemConfig provides | `sys_dropdown_table` values consumed by all module form fields; SystemConfig owns creation/management | ❌ No management UI |
| `All Tenant Apps` | Navigation consumer | SystemConfig provides | `glb_menus` renders the sidebar navigation in every tenant app after menu sync | ✅ Data exists; sync works |
| `Notification` | Settings consumer | SystemConfig provides | SMTP/SMS credentials in `sys_settings` consumed by Notification module's mailer | 🟡 Data model ready; no edit UI |
| `Prime` (Billing/Tenant mgmt) | Model conflict | SystemConfig owns | `Modules\Prime\Models\Setting` and `Modules\SystemConfig\Models\Setting` both point to `sys_settings` — consolidation required | ❌ Conflict |
| `sys_activity_logs` | Audit producer | SystemConfig writes | All mutations in SystemConfig controllers write to `sys_activity_logs` via `activityLog()` helper | 🟡 Partial (not all methods) |

---

## 16. V2 Development Plan and Priority Queue

### 16.1 Effort Estimate (from Gap Analysis + V2 additions)

| Priority | Items | Estimated Hours |
|----------|------:|:---------------:|
| P0 — Critical (security fixes) | 5 | 4-6 hrs |
| P1 — High (broken functionality + arch) | 9 | 18-24 hrs |
| P2 — Medium (correctness + UX) | 8 | 10-14 hrs |
| P3 — Low (polish + conventions) | 4 | 4-6 hrs |
| V2 New Features (Dropdown UI, Activity Log viewer) | — | 20-25 hrs |
| **Total** | **26** | **56-75 hrs** |

### 16.2 Development Priority Queue

**SPRINT 1 — Security Hardening (P0, ~6 hrs)**

| Task | File | Action |
|------|------|--------|
| SYS-T01 | `SystemConfigController.php` | Add `Gate::authorize('system-config.settings.<action>')` to all 7 methods |
| SYS-T02 | `MenuSyncController.php` | Uncomment and enforce Super Admin auth check in `sync()` |
| SYS-T03 | `MenuController.php` | Add `Gate::authorize()` to `create()`, `destroy()`, `trashedMenu()`, `restore()`, `forceDelete()` |
| SYS-T04 | `MenuController.php` line 127 | Change `$request->all()` to `$request->validated()` and strip `code` key |
| SYS-T05 | `Modules/Prime/app/Models/Setting.php` | Delete file; update all Prime module imports |

**SPRINT 2 — Broken Functionality (P1, ~24 hrs)**

| Task | File | Action |
|------|------|--------|
| SYS-T06 | `SettingController.php` | Implement `index()`, `edit()`, `update()` with correct table/columns; create `SettingRequest` |
| SYS-T07 | `MenuController.php` | Implement `create()`, `destroy()`, `restore()`, `toggleStatus()` method bodies |
| SYS-T08 | `MenuPolicy.php` | Change all 7 permission checks from `prime.menu.*` to `system-config.menu.*` |
| SYS-T09 | `SystemConfigPolicy.php` | Implement all 5 CRUD methods; register in AppServiceProvider |
| SYS-T10 | `MenuSyncService.php` (new) | Extract 1,702-line MenuSyncController logic into a service class |
| SYS-T11 | `routes/web.php` | Move all SystemConfig routes from central routes files into module's own web.php |
| SYS-T12 | `MenuController.php` line 177 | Fix view reference `systemconfig.menu.trash` → `systemconfig::menu.trash` |

**SPRINT 3 — New Dropdown Management (❌ → ✅, ~20 hrs)**

| Task | File | Action |
|------|------|--------|
| SYS-T13 | `DropdownNeed.php` (new model) | Create model for `sys_dropdown_needs` |
| SYS-T14 | `DropdownValue.php` (new model) | Create model for `sys_dropdown_table` |
| SYS-T15 | `DropdownNeedController.php` (new) | CRUD for needs registry |
| SYS-T16 | `DropdownValueController.php` (new) | CRUD for values with cascading dropdown create form |
| SYS-T17 | `DropdownNeedRequest.php` (new) | Form request with conditional validation |
| SYS-T18 | `DropdownValueRequest.php` (new) | Form request with derived key/ordinal logic |
| SYS-T19 | Views | Create views for all dropdown CRUD screens |

**SPRINT 4 — Activity Log Viewer + Translation UI (P2/New, ~15 hrs)**

| Task | File | Action |
|------|------|--------|
| SYS-T20 | `ActivityLog.php` (new model) | Read-only model for `sys_activity_logs` |
| SYS-T21 | `ActivityLogController.php` (new) | index + show views |
| SYS-T22 | `MenuController.php` lines 22, 105 | Replace hardcoded `$languageId = 2` with dynamic resolution |
| SYS-T23 | Translation create/edit | Uncomment translation create logic in `store()`; add to `update()` |

**SPRINT 5 — Tests and DDL Fixes (P1-P2, ~10 hrs)**

| Task | File | Action |
|------|------|--------|
| SYS-T24 | `SystemConfigAuthTest.php` (new) | Feature test: all 7 methods require auth |
| SYS-T25 | `MenuControllerTest.php` (new) | Feature test: CRUD + reorder |
| SYS-T26 | `MenuReorderTest.php` (new) | Feature + unit: sibling renumbering |
| SYS-T27 | DDL migration | Fix FK constraint typo `fk_odelHasPermissions` → `fk_modelHasPermissions` |
| SYS-T28 | DDL migration | Add `deleted_at`, `created_by` to `sys_settings`, `sys_dropdown_needs`, `sys_dropdown_table` |

### 16.3 Target Completion State (V2)

| Dimension | V1 Score | V2 Target |
|-----------|:--------:|:---------:|
| Feature Completeness | 60% (D) | 90% (A-) |
| Security | 40% (F) | 95% (A) |
| Test Coverage | 40% (F) | 75% (B) |
| Code Quality | 50% (D) | 85% (B+) |
| Architecture | 55% (D+) | 90% (A-) |
| **Overall** | **53% (D+)** | **87% (B+)** |

---

*End of SystemConfig Module — Requirement Specification Document v2*
*Generated: 2026-03-26 | Source: Code audit of `Modules/SystemConfig/` + `prime_db_v2.sql` + Gap Analysis 2026-03-22*
