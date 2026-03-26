# SystemConfig Module — Requirement Specification Document

**Version:** 1.0 | **Date:** 2026-03-25 | **Author:** Claude Code (Automated Extraction)
**Platform:** Prime-AI Academic Intelligence Platform
**Module Code:** SYS | **Module Path:** `Modules/SystemConfig`
**Module Type:** Prime (Central) | **Database:** prime_db / global_db
**Table Prefix:** `sys_*`, `glb_*` | **Processing Mode:** FULL
**RBS Reference:** Module A — Tenant & System Management; Module SYS — System Administration

---

## Table of Contents

1. [Module Overview](#1-module-overview)
2. [Scope and Boundaries](#2-scope-and-boundaries)
3. [Actors and User Roles](#3-actors-and-user-roles)
4. [Functional Requirements](#4-functional-requirements)
5. [Data Model](#5-data-model)
6. [Controller & Route Inventory](#6-controller--route-inventory)
7. [Form Request Validation Rules](#7-form-request-validation-rules)
8. [Business Rules](#8-business-rules)
9. [Permission & Authorization Model](#9-permission--authorization-model)
10. [Tests Inventory](#10-tests-inventory)
11. [Known Issues & Technical Debt](#11-known-issues--technical-debt)
12. [API Endpoints](#12-api-endpoints)
13. [Non-Functional Requirements](#13-non-functional-requirements)
14. [Integration Points](#14-integration-points)
15. [Pending Work & Gap Analysis](#15-pending-work--gap-analysis)

---

## 1. Module Overview

### 1.1 Purpose

SystemConfig is the **central platform administration module** for Prime-AI. It runs exclusively on the central domain (`admin.prime-ai.com`) and provides Super-Admins with tools to manage:

1. **Platform Settings** — Key-value configuration for application-level behavior
2. **Menu Management** — Application navigation structure (glb_menus hierarchy)
3. **Translation Management** — Multilingual support for menu and entity labels
4. **Dropdown Management** — Enumeration values (`sys_dropdown_table`) used across all modules

This module affects every tenant on the platform — changes to menus, settings, and dropdowns propagate to all tenant schools.

### 1.2 Module Position in the Platform

```
Platform Layer          Module               Database
──────────────────────────────────────────────────────
Central (Super-Admin)   SystemConfig (SYS)   prime_db (sys_settings)
                                              global_db (glb_menus, glb_translations)
                                              prime_db (sys_dropdown_table)
Tenant (All Schools)    Consumers            Reads from global_db + prime_db
```

### 1.3 Module Characteristics

| Attribute          | Value                                                    |
|--------------------|----------------------------------------------------------|
| Laravel Module     | `nwidart/laravel-modules` v12, name `SystemConfig`       |
| Namespace          | `Modules\SystemConfig`                                   |
| Module Code        | SYS                                                      |
| Domain             | Central (admin.prime-ai.com only)                        |
| DB Connections     | `global_master_mysql` (global_db) + `prime_mysql` (prime_db) |
| Table Prefix       | `sys_*` (settings, dropdowns) + `glb_*` (menus, translations) |
| Auth               | CRITICAL: ZERO auth on SystemConfigController (all 7 methods) |
| Frontend           | Bootstrap 5 + AdminLTE 4                                 |
| Completion Status  | ~50%                                                     |
| Controllers        | 4                                                        |
| Models             | 3                                                        |
| Services           | 0                                                        |
| FormRequests       | 1 (MenuRequest only)                                     |
| Tests              | 1                                                        |

### 1.4 Sub-Modules / Feature Areas

1. System Settings — Global platform key-value configuration
2. Menu Management — Application navigation tree with drag-and-drop ordering
3. Translation Management — Per-language translations for menu titles
4. Dropdown Management — Enumeration values for form fields across all modules
5. Menu Sync — Synchronize menu structure from code/config files

---

## 2. Scope and Boundaries

### 2.1 In Scope

- Full CRUD for platform settings (`sys_settings`)
- Menu hierarchy management: create, edit, delete, reorder via drag-and-drop (`glb_menus`)
- Menu translation management (`glb_translations` polymorphic table)
- Dropdown needs management (`sys_dropdown_needs` — which columns need dropdowns)
- Dropdown value management (`sys_dropdown_table` — actual key-value pairs)
- Dropdown junction management (`sys_dropdown_need_table_jnt`)
- Activity logging for all admin actions

### 2.2 Out of Scope

- Tenant-specific menu customization (menus are platform-wide, tenant visibility controlled by module assignment)
- SMTP and SMS configuration (these are settings records but the notification sending infrastructure is in `Notification` module)
- User and role management (separate `Auth` and `UserManagement` modules)
- Backup and recovery operations (infra-level, not application-level)
- System health monitoring and API key management (listed in RBS Module SYS but not yet planned for this module)

### 2.3 RBS Reference Mapping

| RBS Section | RBS Feature | SystemConfig Coverage |
|-------------|-------------|----------------------|
| A3 — Auth & Access | F.A3.1.1 (Password Rules) | `sys_settings` key-value (e.g., password_strength, expiry_days) |
| A7 — Notification Settings | F.A7.1.1 (Email/SMTP Settings) | `sys_settings` keys: smtp_host, smtp_port, etc. |
| A7 — SMS Settings | F.A7.1.2 (SMS Provider) | `sys_settings` keys: sms_provider, sms_api_key |
| SYS1 — System Health | F.SYS1.1 (Monitor Metrics) | Partially planned; not yet implemented |
| SYS2 — API Management | F.SYS2.1 (API Keys) | `sys_settings` keys for API tokens |
| SYS3 — Data Management | F.SYS3.1 (Import/Export) | Not in current scope of this module |

---

## 3. Actors and User Roles

### 3.1 Primary Actors

| Actor | Description | Access Level |
|-------|-------------|--------------|
| Super Admin | Prime-AI platform operator | Full access to all SystemConfig features |
| Platform Manager | Senior platform staff | Menu and translation management; read settings |
| Platform Support | Support team | Read-only access to settings and menus |

### 3.2 Important Note

SystemConfig is a **central module only**. No tenant user should have access to any SystemConfig route. All routes must be gated behind central-domain authentication.

---

## 4. Functional Requirements

### 4.1 Platform Settings Management (FR-SYS-01)

**FR-SYS-01.1 — View Settings**
- Display all `sys_settings` records in an organized list
- Show key, key description, current value, type, and public/private flag
- Group settings by category for readability (SMTP, SMS, Auth, General)

**FR-SYS-01.2 — Edit Setting Value**
- Super-Admin can update the `value` field of a setting record
- Setting `key` is immutable — cannot be changed via UI (the key is the contract with code)
- Type-aware editing: boolean shows toggle, JSON shows code editor, string shows text input
- `is_public` flag determines if setting is exposed to frontend (e.g., school logo URL = public)

**FR-SYS-01.3 — Setting Types**
- Supported types: `string`, `json`, `int`, `boolean`, `date`
- Type validation enforced on save

**FR-SYS-01.4 — Create Setting (Developer Only)**
- New settings are added by developers during module development, not by UI
- Admin UI should show a create form for emergency use but scope it to Super-Admin only

**FR-SYS-01.5 — Key Examples**
- `smtp_host`, `smtp_port`, `smtp_encryption`, `smtp_username`
- `sms_provider`, `sms_api_key`
- `password_min_length`, `password_requires_uppercase`, `password_expiry_days`
- `otp_enabled`, `mfa_required`
- `default_timezone`, `default_currency`, `default_language`
- `maintenance_mode`, `registration_open`

### 4.2 Menu Management (FR-SYS-02)

**FR-SYS-02.1 — View Menu Tree**
- Display the full `glb_menus` hierarchy as a nested tree
- Show menu icon, title, route, sort_order, is_active status
- Support language-specific translated titles (from `glb_translations`) displayed alongside default titles

**FR-SYS-02.2 — Create Menu Item**
- Fields: parent_id (null for top-level), code (unique, immutable), slug (unique), title, description, icon (FontAwesome class), route (Laravel route name), sort_order, visible_by_default, is_active
- Category menus (`is_category = 1`) must have `parent_id = NULL` (enforced by DB CHECK constraint)
- Non-category menus can have a parent

**FR-SYS-02.3 — Edit Menu Item**
- All fields except `code` are editable
- Route changes propagate immediately to all tenant navigation renders

**FR-SYS-02.4 — Delete Menu Item**
- Soft delete via `deleted_at`
- A menu item with children cannot be deleted until children are moved or deleted first (FK ON DELETE RESTRICT)

**FR-SYS-02.5 — Drag-and-Drop Reordering**
- `updateMenu` endpoint accepts `menu_id`, `parent_id`, `sort_order` as JSON payload
- On reorder, siblings are automatically renumbered to maintain consistent ordering
- Category menus (`is_category = 1`) cannot be re-parented to a non-null parent

**FR-SYS-02.6 — Menu-Module Junction**
- `glb_menu_model_jnt` links each menu item to one or more modules
- This determines which modules control a menu item's visibility per tenant

**FR-SYS-02.7 — Menu Sync (MenuSyncController)**
- Sync menu definitions from a JSON/PHP config file to the `glb_menus` table
- Used during deployments to seed new menu items added in code

### 4.3 Translation Management (FR-SYS-03)

**FR-SYS-03.1 — View Translations**
- List translations from `glb_translations` for a given entity (menu, module, etc.)
- Filter by language, key

**FR-SYS-03.2 — Add Translation**
- Fields: translatable_type (Laravel morph type e.g. `Modules\SystemConfig\Models\Menu`), translatable_id, language_id (FK to glb_languages), key (e.g. `title`), value
- UNIQUE constraint on (translatable_type, translatable_id, language_id, key)

**FR-SYS-03.3 — Edit Translation**
- Update the `value` field for an existing translation key

**FR-SYS-03.4 — Language Support**
- Languages defined in `glb_languages` table (managed by GlobalMaster)
- Current implementation uses `language_id = 2` as the default translated language in MenuController

**FR-SYS-03.5 — Translation Usage in MenuController**
- `setTranslatedTitleRecursive()` method on MenuController applies translations recursively to the menu tree
- Sets `menu.translated_title` attribute for display; falls back to `menu.title` if no translation

### 4.4 Dropdown Management (FR-SYS-04)

**FR-SYS-04.1 — Dropdown Needs Registry**
- `sys_dropdown_needs` defines which DB table/column combinations require dropdown values
- Fields: db_type (Prime/Tenant/Global), table_name, column_name, menu_category, main_menu, sub_menu, tab_name, field_name, is_system, tenant_creation_allowed, compulsory
- Developer creates entries here first before adding dropdown values

**FR-SYS-04.2 — Create Dropdown Value**
- Super-Admin (PG_USER) can create dropdown values by either:
  - **Option 1 — DB Details**: Select DB type → Table Name → Column Name
  - **Option 2 — Menu Detail**: Select Menu Category → Main Menu → Sub Menu → Tab Name → Field Name
- Tenant users (if `tenant_creation_allowed = 1`) can only use Option 2 (Menu Detail path)
- Fields on `sys_dropdown_table`: ordinal, key (table.column composite), value, type ENUM, additional_info JSON

**FR-SYS-04.3 — Dropdown Value Types**
- String, Integer, Decimal, Date, Datetime, Time, Boolean
- `additional_info` JSON field for extended metadata (e.g., country dial codes on phone type dropdowns)

**FR-SYS-04.4 — Dropdown-Need Junction**
- `sys_dropdown_need_table_jnt` links a need to its dropdown table entry
- Enforces that dropdown values exist for all configured needs

**FR-SYS-04.5 — Ordering**
- `ordinal` field on `sys_dropdown_table` controls display order within a key group
- UNIQUE constraint on (key, ordinal) and (key, value)

---

## 5. Data Model

### 5.1 Primary Tables

| Table | Database | Purpose | Key Columns |
|-------|---------|---------|-------------|
| `sys_settings` | prime_db | Platform configuration | key (unique), value, type, is_public |
| `sys_dropdown_needs` | prime_db | Dropdown configuration registry | db_type, table_name, column_name, tenant_creation_allowed |
| `sys_dropdown_table` | prime_db | Dropdown values | ordinal, key, value, type ENUM, additional_info JSON |
| `sys_dropdown_need_table_jnt` | prime_db | Dropdown need ↔ value link | dropdown_needs_id, dropdown_table_id |
| `glb_menus` | global_db | Application navigation tree | parent_id (self-ref), code (unique), slug, title, icon, route, sort_order, is_category |
| `glb_translations` | global_db | Multilingual content | translatable_type, translatable_id, language_id, key, value |

### 5.2 Models

| Model | Namespace | Table | Notes |
|-------|-----------|-------|-------|
| `Menu` | `Modules\SystemConfig\Models` | `glb_menus` | Hierarchical; has translations relationship |
| `Setting` | `Modules\SystemConfig\Models` | `sys_settings` | Key-value config |
| `Translation` | `Modules\SystemConfig\Models` | `glb_translations` | Polymorphic morph |

### 5.3 Relationships

```
glb_menus (1) ──── (N) glb_menus [parent_id self-ref]
glb_menus (N) ──── (N) glb_translations [polymorphic via translatable_id/type]
glb_menus (N) ──── (N) glb_modules [via glb_menu_model_jnt]
sys_dropdown_needs (N) ──── (N) sys_dropdown_table [via sys_dropdown_need_table_jnt]
```

### 5.4 DB Constraints

- `glb_menus` CHECK constraint: `(is_category = 1 AND parent_id IS NULL) OR (is_category = 0)` — categories cannot have a parent
- `sys_settings` UNIQUE on `key` — prevents duplicate setting keys
- `sys_dropdown_table` UNIQUE on (key, ordinal) and (key, value)
- `glb_translations` UNIQUE on (translatable_type, translatable_id, language_id, key)

---

## 6. Controller & Route Inventory

### 6.1 Controllers

| Controller | Methods Implemented | Auth | Notes |
|-----------|---------------------|------|-------|
| `SystemConfigController` | index, create, store (empty), show, edit, update (empty), destroy (empty) | ZERO AUTH on ALL 7 methods | Pure stub — settings view/edit not implemented |
| `MenuController` | index, create (empty stub), store, show (empty), edit, update, destroy (empty), trashedMenu, restore (empty), forceDelete, toggleStatus (empty), updateMenu, setTranslatedTitleRecursive | Partial: store, edit, update, updateMenu have Gate::authorize; index, create, destroy, restore, toggleStatus have NO auth | `$request->all()` used in `update()` method |
| `MenuSyncController` | Unknown (sync functionality) | Unknown | Menu sync from config |
| `SettingController` | Unknown | Unknown | Settings CRUD |

### 6.2 Routes (web.php — prefix: `system-config`)

All routes under `Route::middleware(['auth', 'verified'])->prefix('system-config')->name('system-config.')`:
- Menu resource routes: `system-config.menu.*`
- `menu/{menu}/update-menu` (PATCH) → `MenuController@updateMenu`
- `menu/{id}/restore` → restore soft-deleted menu
- `menu/{id}/force-delete` → permanent deletion
- `menu/{menu}/toggle-status` → active/inactive toggle
- System config resource routes (stub, empty controller)
- Settings routes (via SettingController)
- Translation routes (via TranslationController, if implemented)

Note: The routes file contains menu routes in 3 separate sections (lines 254, 496, 821 in web.php), suggesting incremental development without route consolidation.

---

## 7. Form Request Validation Rules

### 7.1 MenuRequest
- `parent_id`: nullable, integer, exists:glb_menus,id
- `code`: required (on create), string, max:60, unique:glb_menus,code
- `slug`: required, string, max:150, unique:glb_menus,slug
- `title`: required, string, max:100
- `description`: nullable, string, max:255
- `icon`: nullable, string, max:150
- `route`: nullable, string, max:255
- `sort_order`: required, integer, min:1
- `visible_by_default`: boolean
- `is_active`: boolean

### 7.2 SettingRequest (Missing — needed)
- `value`: required, type-dependent validation
- `is_public`: boolean

### 7.3 TranslationRequest (Missing — needed)
- `language_id`: required, exists:glb_languages,id
- `key`: required, string, max:255
- `value`: required, string

---

## 8. Business Rules

**BR-SYS-01:** Setting `key` is the code-contract — it must never be changed via the UI. The system should display the key as read-only on the edit form.

**BR-SYS-02:** `glb_menus.code` is the system identifier for a menu item and is immutable after creation. It is used in permission names and route guards.

**BR-SYS-03:** Category menus (`is_category = 1`) must have `parent_id = NULL`. Attempting to assign a parent to a category menu must be rejected. The DB CHECK constraint enforces this at the DB level; the application must also enforce it.

**BR-SYS-04:** On drag-and-drop menu reorder (`updateMenu`), sibling sort_orders are automatically renumbered to close gaps and prevent sort_order conflicts.

**BR-SYS-05:** A menu item that is a category cannot be re-parented (its `parent_id` must remain null). The `updateMenu` method validates this and returns HTTP 422 if a category is assigned a non-null parent.

**BR-SYS-06:** Settings with `is_public = 0` must never be exposed to frontend JavaScript or API responses — they contain sensitive data (API keys, passwords, internal tokens).

**BR-SYS-07:** Before creating a dropdown value, a corresponding entry in `sys_dropdown_needs` must exist. Dropdown values without a needs registry entry should be rejected.

**BR-SYS-08:** `sys_dropdown_table.key` follows the format `table_name.column_name` (e.g., `cmp_complaint_actions.action_type`). This format is enforced by convention, not by DB constraint.

**BR-SYS-09:** The `ordinal` field in `sys_dropdown_table` determines display order within a key group. Ordinals are UNIQUE per key — no two items with the same key can share an ordinal.

---

## 9. Permission & Authorization Model

### 9.1 Current State — CRITICAL GAP

**ISSUE CRITICAL:** `SystemConfigController` has ZERO authentication on ALL 7 methods:
```
index()   — no Gate check
create()  — no Gate check
store()   — no Gate check (also empty stub)
show()    — no Gate check
edit()    — no Gate check
update()  — no Gate check (also empty stub)
destroy() — no Gate check (also empty stub)
```

Any HTTP request to `/system-config` endpoints will succeed without any authentication or authorization check.

**MenuController partial auth:**
- `index()` — uses `Gate::authorize('system-config.menu.viewAny')` — PROTECTED
- `store()` — uses `Gate::authorize('system-config.menu.create')` — PROTECTED
- `edit()` — uses `Gate::authorize('system-config.menu.update')` — PROTECTED
- `update()` — uses `Gate::authorize('system-config.menu.update')` — PROTECTED
- `updateMenu()` — uses `Gate::authorize('system-config.menu.update')` — PROTECTED
- `create()` — NO auth check — UNPROTECTED
- `destroy()` — empty body, no auth — UNPROTECTED
- `restore()` — empty body, no auth — UNPROTECTED
- `toggleStatus()` — empty body, no auth — UNPROTECTED
- `trashedMenu()` — NO auth check — UNPROTECTED

### 9.2 Required Permissions (Target State)

| Resource | Permission | Methods to Protect |
|----------|-----------|-------------------|
| System Config | `system-config.viewAny` | index, show |
| System Config | `system-config.create` | create, store |
| System Config | `system-config.update` | edit, update |
| System Config | `system-config.delete` | destroy |
| Menu | `system-config.menu.viewAny` | index, trashedMenu |
| Menu | `system-config.menu.create` | create, store |
| Menu | `system-config.menu.update` | edit, update, updateMenu |
| Menu | `system-config.menu.delete` | destroy, forceDelete |
| Menu | `system-config.menu.restore` | restore |
| Setting | `system-config.setting.viewAny` | index |
| Setting | `system-config.setting.update` | edit, update |
| Dropdown | `system-config.dropdown.viewAny` | index |
| Dropdown | `system-config.dropdown.create` | create, store |
| Dropdown | `system-config.dropdown.update` | edit, update |
| Dropdown | `system-config.dropdown.delete` | destroy |

---

## 10. Tests Inventory

### 10.1 Current State

**1 test file exists** — contents and location not confirmed but module reports 1 test.

### 10.2 Required Tests (Target)

| Test Class | Type | Priority | Key Scenarios |
|-----------|------|----------|--------------|
| `SystemConfigAuthTest` | Feature | CRITICAL | Verify all 7 SystemConfigController methods require auth |
| `MenuControllerTest` | Feature | HIGH | CRUD, drag-drop reorder, category constraint, translation |
| `MenuCategoryConstraintTest` | Unit | HIGH | Cannot assign parent to category menu |
| `SettingControllerTest` | Feature | HIGH | View/edit settings; is_public enforcement |
| `DropdownTest` | Feature | MEDIUM | Create dropdown with/without needs registry entry |
| `TranslationTest` | Feature | MEDIUM | Multilingual title retrieval for menus |
| `MenuSortOrderTest` | Unit | MEDIUM | Sibling renumbering on drag-drop |

---

## 11. Known Issues & Technical Debt

### 11.1 Critical Security Gaps

**ISSUE-SYS-01 [CRITICAL]:** `SystemConfigController` has ZERO authentication on ALL 7 methods. Any unauthenticated HTTP client can access `/system-config` routes and call any endpoint. The `store`, `update`, and `destroy` methods are empty stubs so no data is currently at risk, but as the controller gets implemented, data will be fully exposed.

This is particularly dangerous because SystemConfig controls platform-wide settings including SMTP credentials, SMS API keys, and authentication policy (password rules, MFA settings).

**ISSUE-SYS-02 [HIGH]:** `MenuController::update()` uses `$request->all()` instead of `$request->validated()`. While `MenuRequest` is injected and validates the input, the raw unvalidated request bag is passed to `$menu->update()`. This bypasses the FormRequest whitelist and could allow injection of any field that appears in `$fillable` on the Menu model, including `code` (which should be immutable).

### 11.2 Functionality Issues

**ISSUE-SYS-03 [HIGH]:** `MenuController::create()` returns an empty function body — the create menu form has no implementation.

**ISSUE-SYS-04 [HIGH]:** `MenuController::destroy()`, `restore()`, and `toggleStatus()` are empty method bodies — soft delete, restore, and status toggle for menus do not function.

**ISSUE-SYS-05 [MEDIUM]:** Route duplication — menu-related routes appear in 3 separate blocks in `web.php` (lines 254, 496, 821). This indicates incremental route addition without consolidation and may cause unexpected route precedence behavior.

**ISSUE-SYS-06 [MEDIUM]:** `MenuController::trashedMenu()` has no authentication check and returns a view that likely lists soft-deleted menu items.

**ISSUE-SYS-07 [MEDIUM]:** `language_id = 2` is hardcoded in `MenuController::index()` and `edit()`. The translation language should be dynamic (e.g., from user preference or request parameter).

### 11.3 Missing Functionality

**ISSUE-SYS-08 [HIGH]:** `SystemConfigController` is a stub with all methods empty. Platform settings (SMTP, SMS, auth policies) cannot be managed via UI.

**ISSUE-SYS-09 [MEDIUM]:** No `SettingController` implementation confirmed — `SettingRequest` is absent.

**ISSUE-SYS-10 [MEDIUM]:** No dropdown management UI confirmed despite `sys_dropdown_table`, `sys_dropdown_needs`, and `sys_dropdown_need_table_jnt` being critical to the platform.

---

## 12. API Endpoints

No REST API endpoints currently. SystemConfig is a web-only admin module.

### 12.1 Key AJAX Endpoints (Web Routes)

| Method | Route | Controller | Description |
|--------|-------|-----------|-------------|
| PATCH | `/system-config/menu/{menu}/update-menu` | `MenuController@updateMenu` | Drag-drop reorder endpoint; returns JSON success/error |

---

## 13. Non-Functional Requirements

### 13.1 Security

- All SystemConfig routes MUST be restricted to central domain (`admin.prime-ai.com`)
- All routes MUST require authentication AND Super-Admin level permissions
- Settings with `is_public = 0` MUST never appear in API responses or frontend-accessible JSON
- Menu reorder endpoint MUST validate CSRF token (PATCH method, Laravel default CSRF applies)

### 13.2 Performance

- Menu tree loading (with translations, recursive) should respond within 500ms for up to 100 menu items
- Settings listing should respond within 200ms

### 13.3 Auditability

- All settings changes MUST be logged to `sys_activity_logs` with before/after values
- Menu structure changes (create, update, delete, reorder) MUST be logged
- `activityLog()` helper is already called in `MenuController::store()` and `update()` — this pattern must be extended to all mutations

### 13.4 Consistency

- Menu `code` field is the immutable identifier used in permission names. Changing a code would break all permission checks across the platform. The system must treat `code` as immutable post-creation.

---

## 14. Integration Points

| Module | Integration Type | Description |
|--------|-----------------|-------------|
| `GlobalMaster` | Shared tables | `glb_menus` and `glb_translations` defined in global_db; SystemConfig provides the management UI |
| `Auth` | RBAC | All SystemConfig access gated via Spatie permissions |
| `All Tenant Modules` | Consumer | `sys_dropdown_table` values consumed by all modules for form dropdowns |
| `All Tenant Apps` | Consumer | `glb_menus` renders the sidebar navigation in every tenant app |
| `Notification` | Settings consumer | SMTP/SMS settings in `sys_settings` consumed by Notification module |
| `sys_activity_logs` | Audit | All changes logged to activity log |

---

## 15. Pending Work & Gap Analysis

### 15.1 Completion Status: ~50%

| Feature Area | Status | Gap Description |
|-------------|--------|-----------------|
| Platform Settings UI | 10% | SystemConfigController is a blank stub; SettingController unknown |
| Menu CRUD | 65% | index/store/edit/update work; create/destroy/restore/toggleStatus are stubs |
| Menu Drag-Drop Reorder | 90% | updateMenu works; sibling renumbering implemented |
| Menu Translation | 60% | Translation display works; create/edit translation UI not confirmed |
| Dropdown Management | 15% | Tables exist; no confirmed UI controller/routes |
| MenuSync | Unknown | MenuSyncController exists; implementation unknown |
| Auth on SystemConfig | 0% | All 7 methods completely unprotected |
| Auth on Menu (complete) | 50% | 5 of 10 methods protected; create/destroy/restore/toggleStatus unprotected |
| Service Layer | 0% | No services |
| Tests | ~5% | 1 test file reported; coverage unknown |

### 15.2 Priority Remediation Items

1. **[P0 — CRITICAL]** Add `Gate::authorize('system-config.settings.viewAny')` (and appropriate auth) to ALL 7 methods in `SystemConfigController`
2. **[P0 — CRITICAL]** Implement `SystemConfigController::index()`, `edit()`, `update()` to actually read and write `sys_settings`
3. **[P0]** Replace `$request->all()` with `$request->validated()` in `MenuController::update()`
4. **[P1]** Add auth checks to `MenuController::create()`, `destroy()`, `restore()`, `toggleStatus()`, `trashedMenu()`
5. **[P1]** Implement `MenuController::create()`, `destroy()`, `restore()`, `toggleStatus()`
6. **[P1]** Implement dropdown management UI (controller + views for `sys_dropdown_table` and `sys_dropdown_needs`)
7. **[P1]** Consolidate duplicate route groups in `web.php` (3 separate system-config groups)
8. **[P2]** Replace hardcoded `$languageId = 2` with dynamic language detection
9. **[P2]** Write security tests verifying all SystemConfig routes require authentication
10. **[P3]** Add translation management UI (create, edit translations per entity per language)
