# GlobalMaster Module — Requirement Specification Document

**Version:** 1.0 | **Date:** 2026-03-25 | **Author:** Claude Code (Automated Extraction)
**Platform:** Prime-AI Academic Intelligence Platform
**Module Code:** GLB | **Module Path:** `Modules/GlobalMaster`
**Module Type:** Global (Central) | **Database:** global_db
**Table Prefix:** `glb_*` | **Processing Mode:** FULL
**RBS Reference:** Module A — Tenant & System Management (GlobalMaster sections)

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

GlobalMaster is the **central reference data management module** for the Prime-AI SaaS platform. It runs exclusively on the central domain (`admin.prime-ai.com`) and manages shared reference data that is consumed by all tenant schools across the platform.

Unlike tenant modules (which run inside isolated `tenant_{uuid}` databases), GlobalMaster data lives in `global_db` and is read-only from the tenant perspective. The central Super-Admin team is the sole owner of this data.

### 1.2 Module Position in the Platform

```
Platform Layer          Module              Database
─────────────────────────────────────────────────────
Central (Super-Admin)   GlobalMaster (GLB)  global_db
Central (SaaS Mgmt)     Prime               prime_db
Tenant (Per-School)     All other modules   tenant_{uuid}
```

### 1.3 Module Characteristics

| Attribute          | Value                                               |
|--------------------|-----------------------------------------------------|
| Laravel Module     | `nwidart/laravel-modules` v12, name `GlobalMaster`  |
| Namespace          | `Modules\GlobalMaster`                              |
| Module Code        | GLB                                                 |
| Domain             | Central (admin.prime-ai.com)                        |
| DB Connection      | `global_master_mysql` (global_db)                   |
| Table Prefix       | `glb_*` (plus `sys_*` for dropdowns/logs, `prm_*` for plans) |
| Auth               | Spatie Permission v6.21 via `Gate::authorize()`     |
| Frontend           | Bootstrap 5 + AdminLTE 4                            |
| Completion Status  | ~55%                                                |

### 1.4 Sub-Modules Managed

1. Geography Setup — Countries, States, Districts, Cities
2. Academic Boards — Educational boards (CBSE, ICSE, State boards)
3. Academic Sessions — Global academic year definitions
4. Languages — Platform language support
5. Modules — Platform module registry
6. Plans — SaaS subscription plan definitions
7. Dropdowns — Global enumeration values
8. Activity Logs — Audit trail viewer

---

## 2. Scope and Boundaries

### 2.1 In Scope

- Full CRUD for all `glb_*` reference tables
- Soft-delete lifecycle (trash / restore / force-delete) for all entities
- Toggle active/inactive status for all entities
- Geographic hierarchy cascade (country deactivation propagates to states and districts)
- Module-Menu many-to-many mapping
- Plan-Module many-to-many assignment
- Activity log viewing (read-only audit trail)
- Dropdown key-value management for `sys_dropdowns`

### 2.2 Out of Scope

- Tenant-specific customization of reference data (handled in `SchoolSetup` module)
- Billing and invoicing (handled in `Billing` module)
- User and role management for tenants (handled in `Auth` and `UserManagement` modules)
- Menu display rendering in tenant apps (menus are defined here but rendered via tenant middleware)
- Translation management for multilingual content (`glb_translations` table is defined, management UI not yet implemented)

### 2.3 RBS Reference Mapping

The GlobalMaster module covers the global reference data sections embedded in **RBS Module A — Tenant & System Management**. Specifically:

| RBS Section | RBS Feature | GlobalMaster Coverage |
|-------------|-------------|----------------------|
| A1 — Tenant Registration | F.A1.1.2 (Configure Default Settings) | `glb_academic_sessions`, `glb_countries` |
| A1 — Subscription Assignment | F.A1.2.1 (Choose Plan / Attach Modules) | `prm_plans`, `glb_modules`, module-plan junction |
| A2 — Feature Management | F.A2.1.1 (Enable/Disable Modules) | `glb_modules` toggle |
| A6 — Audit Logs | F.A6.1 (System Logs, Track Activities) | `sys_activity_logs` viewer |

---

## 3. Actors and User Roles

### 3.1 Primary Actors

| Actor | Description | Access Level |
|-------|-------------|--------------|
| Super Admin | Prime-AI platform operator | Full CRUD on all GlobalMaster entities |
| Platform Manager | Senior staff managing reference data | Full CRUD, no force-delete |
| Support Staff | Read-only reference data access | ViewAny only |

### 3.2 Permission Scopes

All permissions follow the `prime.{entity}.{action}` naming convention. Available permission actions:

| Action | Description |
|--------|-------------|
| `viewAny` | List all records (paginated) |
| `view` | View single record detail |
| `create` | Create new record |
| `update` | Edit existing record |
| `delete` | Soft-delete (trash) a record |
| `restore` | Restore a trashed record |
| `forceDelete` | Permanently delete a trashed record |

---

## 4. Functional Requirements

### FR-GLB-01 — Country Management

**Feature:** CRUD management for countries in the geographic hierarchy.

**RBS:** F.A1.1.2 — Configure Default Settings (country selection for tenant setup)

**Status:** Implemented

| Sub-Requirement | Description | Status |
|-----------------|-------------|--------|
| FR-GLB-01.1 | List countries paginated (10/page), sorted by is_active descending | Done |
| FR-GLB-01.2 | Create country with name, short_name, global_code, currency_code, is_active | Done |
| FR-GLB-01.3 | Edit country with unique name validation ignoring current record | Done |
| FR-GLB-01.4 | Soft-delete (trash) country — deactivates before deleting | Done |
| FR-GLB-01.5 | View trashed countries and restore them | Done |
| FR-GLB-01.6 | Force-delete permanently removed country | Done |
| FR-GLB-01.7 | Toggle active/inactive via AJAX; cascade deactivation to all child States and Districts in a single DB transaction | Done |
| FR-GLB-01.8 | Activity log on every state change (Create/Update/Trash/Restore/Delete/Toggle) | Done |
| FR-GLB-01.9 | `$request->all()` used in store/update instead of `$request->validated()` | Bug (security gap) |

**Cascade Rule:** `CountryController::toggleStatus()` wraps in `DB::beginTransaction()`. When a country is deactivated, all `glb_states` belonging to it and all `glb_districts` belonging to those states are bulk-updated to `is_active = false`.

---

### FR-GLB-02 — State Management

**Feature:** CRUD management for states, scoped to parent country.

**Status:** Implemented

| Sub-Requirement | Description | Status |
|-----------------|-------------|--------|
| FR-GLB-02.1 | List states grouped by country (eager-loads country relationship) | Done |
| FR-GLB-02.2 | Create state with country_id FK, name, short_name, global_code, is_active | Done |
| FR-GLB-02.3 | Unique constraint: (country_id + name) pair must be unique | Done |
| FR-GLB-02.4 | Edit state with scoped uniqueness check | Done |
| FR-GLB-02.5 | Soft-delete, restore, force-delete | Done |
| FR-GLB-02.6 | Toggle status: blocked if parent country is inactive (cannot activate state under inactive country) | Done |
| FR-GLB-02.7 | AJAX endpoint: get states by country_id (for dependent dropdowns in tenant forms) | Done |
| FR-GLB-02.8 | Duplicate `activityLog()` call in `update()` method | Bug (duplicate log entry) |

---

### FR-GLB-03 — District Management

**Feature:** CRUD management for districts, scoped to parent state.

**Status:** Implemented

| Sub-Requirement | Description | Status |
|-----------------|-------------|--------|
| FR-GLB-03.1 | List districts grouped by country > state hierarchy | Done |
| FR-GLB-03.2 | Create district with state_id FK, name, short_name, global_code, is_active | Done |
| FR-GLB-03.3 | Unique constraint: (state_id + name) must be unique | Done |
| FR-GLB-03.4 | Uses `$request->validated()` (correct pattern, unlike Country/State/City) | Done |
| FR-GLB-03.5 | Toggle status: blocked if parent state is inactive | Done |
| FR-GLB-03.6 | Full soft-delete lifecycle | Done |
| FR-GLB-03.7 | `forceDelete` permission uses `prime.district.delete` instead of `prime.district.forceDelete` | Bug |

---

### FR-GLB-04 — City Management

**Feature:** CRUD management for cities, scoped to parent district.

**Status:** Implemented

| Sub-Requirement | Description | Status |
|-----------------|-------------|--------|
| FR-GLB-04.1 | List cities with full eager-load: district > state > country | Done |
| FR-GLB-04.2 | Create city with district_id FK, name, short_name, default_timezone, is_active | Done |
| FR-GLB-04.3 | Edit/Update city | Done |
| FR-GLB-04.4 | `city.edit()` uses raw `City::findOrFail($id)` (string $id) instead of route model binding | Technical debt |
| FR-GLB-04.5 | Toggle status (no parent check for district — gap vs. State/District pattern) | Partial gap |
| FR-GLB-04.6 | Full soft-delete lifecycle | Done |
| FR-GLB-04.7 | `$request->all()` in store/update (security gap) | Bug |

---

### FR-GLB-05 — Geography Setup Dashboard

**Feature:** Unified tabbed interface showing Countries, States, Districts, and Cities in a single screen with tab-aware search/pagination.

**Status:** Implemented

| Sub-Requirement | Description | Status |
|-----------------|-------------|--------|
| FR-GLB-05.1 | Single page `location-setup/index` with four tab panels (country/state/district/city) | Done |
| FR-GLB-05.2 | Tab-aware search: `?tab=country&search=india` searches only the active tab's entity | Done |
| FR-GLB-05.3 | Independent pagination per tab (`country_page`, `state_page`, `district_page`, `city_page`) | Done |
| FR-GLB-05.4 | AJAX search endpoint `location-setup/search?tab=&search=` returning plucked names | Done |
| FR-GLB-05.5 | Gate check: allows entry if user has ANY of the four `viewAny` permissions | Done |
| FR-GLB-05.6 | Stub methods (create, store, show, edit, update, destroy) have no logic | Pending |

---

### FR-GLB-06 — Educational Board Management

**Feature:** CRUD management for educational boards (CBSE, ICSE, State boards, IGCSE, IB, etc.) used by tenant schools.

**Status:** Managed via `SessionBoardSetupController` (hub view) + standalone BoardRequest

| Sub-Requirement | Description | Status |
|-----------------|-------------|--------|
| FR-GLB-06.1 | Create board with name (unique), short_name (unique), is_active | Done (Request exists) |
| FR-GLB-06.2 | Edit/Update board with self-ignore uniqueness | Done |
| FR-GLB-06.3 | Board displayed in session-board-setup hub view alongside academic sessions | Done |
| FR-GLB-06.4 | Board has many-to-many relationship with `Organization` via `sch_board_organization_jnt` | Done |
| FR-GLB-06.5 | Dedicated BoardController (separate CRUD routes for board) | Pending — currently hub-only |
| FR-GLB-06.6 | Board soft-delete / restore / force-delete UI | Pending (trash view exists) |

---

### FR-GLB-07 — Academic Session Management

**Feature:** CRUD for global academic year definitions (e.g., 2024-25, 2025-26) used as reference data for tenant schools.

**RBS:** F.A1.1.2 ST.A1.1.2.1 — Set academic year

**Status:** Implemented

| Sub-Requirement | Description | Status |
|-----------------|-------------|--------|
| FR-GLB-07.1 | Create session with name, short_name (both unique), start_date, end_date, is_current | Done |
| FR-GLB-07.2 | Only one session can be `is_current = true` at any time (enforced by DB generated column + toggle logic) | Done |
| FR-GLB-07.3 | Toggle status: activating one session deactivates all others | Done |
| FR-GLB-07.4 | Destroy blocked if session is_active = true (cannot trash active session) | Done |
| FR-GLB-07.5 | AcademicSessionRequest missing `start_date` and `end_date` validation rules | Bug (incomplete validation) |
| FR-GLB-07.6 | `gate.any(['prime.academic-session.viewAny'])` — inconsistency with other controllers using `gate.authorize()` | Technical debt |
| FR-GLB-07.7 | `create()` and `store()` use `global-master.academic-session.*` permission prefix instead of `prime.*` | Inconsistency bug |
| FR-GLB-07.8 | Session-Board-Setup hub view: combined view listing sessions + boards paginated on one page | Done |

---

### FR-GLB-08 — Language Management

**Feature:** CRUD for platform-supported languages used for multilingual content and translation management.

**Status:** Partially Implemented (auth gaps)

| Sub-Requirement | Description | Status |
|-----------------|-------------|--------|
| FR-GLB-08.1 | List languages (11/page) — `paginate(11)` is inconsistent with standard 10/page | Done (minor issue) |
| FR-GLB-08.2 | Create language: code (ISO, unique), name, native_name, direction (LTR/RTL), is_active | Done |
| FR-GLB-08.3 | Uses `$request->validated()` in store/update (correct pattern) | Done |
| FR-GLB-08.4 | `create()` and `edit()` methods have no `Gate::authorize()` checks | Bug (missing auth) |
| FR-GLB-08.5 | `update()` method has no `Gate::authorize()` check | Bug (missing auth) |
| FR-GLB-08.6 | Uses `Modules\Prime\Models\Language` instead of `Modules\GlobalMaster\Models\Language` — cross-module model reference | Technical debt |
| FR-GLB-08.7 | `toggleStatus()` type-hint uses lowercase `language` (wrong PHP convention) | Code quality issue |
| FR-GLB-08.8 | `forceDelete` event logged as 'Stored' instead of 'Deleted' | Bug (wrong log event) |
| FR-GLB-08.9 | Permission prefix mixes `prime.*` and `global-master.*` within same controller | Inconsistency bug |

---

### FR-GLB-09 — Module Registry Management

**Feature:** CRUD for the platform's module registry — defines what functional modules exist in Prime-AI, their capabilities, and permission availability flags.

**RBS:** F.A2.1.1 — Enable/Disable Modules

**Status:** Implemented

| Sub-Requirement | Description | Status |
|-----------------|-------------|--------|
| FR-GLB-09.1 | List modules with eager-loaded menus (10/page) | Done |
| FR-GLB-09.2 | Create module: name, version, is_sub_module, description, is_core, default_visible, 7 permission flags (view/add/edit/delete/export/import/print), is_active | Done |
| FR-GLB-09.3 | Assign menus to module during create (many-to-many via `glb_menu_module_jnt` with sort_order pivot) | Done |
| FR-GLB-09.4 | Update module with menu sync (replaces all existing menu assignments) | Done |
| FR-GLB-09.5 | `$request->all()` used in store/update — security gap (validated() should be used) | Bug |
| FR-GLB-09.6 | `show()` method uses `prime.module.create` permission — should be `prime.module.view` | Bug (wrong permission) |
| FR-GLB-09.7 | `show()` returns `module.edit` view instead of `module.show` view | Bug |
| FR-GLB-09.8 | Self-referencing parent/children relationship for sub-modules | Done |
| FR-GLB-09.9 | Toggle active/inactive status via AJAX | Done |
| FR-GLB-09.10 | Full soft-delete lifecycle (trash, restore, force-delete) | Done |
| FR-GLB-09.11 | No sub-module management UI (parent_id assignment not in form) | Gap |

---

### FR-GLB-10 — SaaS Plan Management

**Feature:** CRUD for SaaS subscription plans that can be assigned to tenant schools. Plans define pricing, billing cycle, trial period, and which modules are included.

**Note:** Plan data resides in `prm_plans` table in `prime_db`, but is managed here in GlobalMaster for convenience alongside Module management.

**RBS:** F.A1.2.1 — Choose Plan / Attach Modules

**Status:** Implemented

| Sub-Requirement | Description | Status |
|-----------------|-------------|--------|
| FR-GLB-10.1 | List plans paginated (10/page) | Done |
| FR-GLB-10.2 | Create plan: plan_code (unique), name (unique), version, description, billing_cycle_id, price_monthly, price_yearly, currency (3-char), trial_days (1-30), is_active | Done |
| FR-GLB-10.3 | Assign modules to plan during create (many-to-many via `glb_module_plan_jnt`, min 1 module required) | Done |
| FR-GLB-10.4 | Update plan with module sync | Done |
| FR-GLB-10.5 | Billing cycle mapping: integer ID (1=monthly, 2=quarterly, 3=yearly, 4=one_time) mapped from/to string label | Done |
| FR-GLB-10.6 | AJAX endpoint `plan/details/{plan}` — returns plan + all modules as JSON for plan detail modal | Done |
| FR-GLB-10.7 | Toggle active/inactive | Done |
| FR-GLB-10.8 | Full soft-delete lifecycle | Done |
| FR-GLB-10.9 | `$request->all()` used in store (security gap) | Bug |
| FR-GLB-10.10 | `show()` method returns empty body | Stub |

---

### FR-GLB-11 — Dropdown Management

**Feature:** CRUD for global enumeration values (`sys_dropdowns`) used across the platform for lookup lists (e.g., gender, blood groups, status codes, complaint severities).

**Status:** Implemented

| Sub-Requirement | Description | Status |
|-----------------|-------------|--------|
| FR-GLB-11.1 | List distinct keys paginated (10/page), each key showing its values grouped | Done |
| FR-GLB-11.2 | Create dropdown: supports bulk value input (comma-separated values split into multiple records) | Done |
| FR-GLB-11.3 | Each record: key (slugified), value, type (String/Integer/Decimal/Date/Datetime/Time/Boolean), ordinal, is_active | Done |
| FR-GLB-11.4 | Edit single dropdown value | Done |
| FR-GLB-11.5 | Toggle active/inactive | Done |
| FR-GLB-11.6 | Full soft-delete lifecycle | Done |
| FR-GLB-11.7 | DropdownRequest validation: `key`, `type`, `org_id` fields not validated (commented out in FormRequest) | Bug (incomplete validation) |
| FR-GLB-11.8 | `store()` uses `auth()->user()->id` for `org_id` — unclear if this is correct for central admin context | Design question |
| FR-GLB-11.9 | `Dropdown` model maps to `sys_dropdowns` table (prime_db), not a `glb_*` table — cross-DB model | Note |

---

### FR-GLB-12 — Activity Log Viewer

**Feature:** Read-only audit trail viewer showing all platform activity logged by the `activityLog()` helper function.

**RBS:** F.A6.1 — System Logs, Track Activities

**Status:** Partially Implemented (view-only works; create/edit/delete are stubs)

| Sub-Requirement | Description | Status |
|-----------------|-------------|--------|
| FR-GLB-12.1 | List activity logs in reverse-chronological order, paginated (10/page) | Done |
| FR-GLB-12.2 | `ActivityLogController::create()`, `store()`, `edit()`, `update()`, `destroy()` all return empty bodies | Stub |
| FR-GLB-12.3 | Filter logs by user, date range, event type | Pending |
| FR-GLB-12.4 | Export logs to CSV | Pending |
| FR-GLB-12.5 | Activity logs should be read-only (no edit/delete from UI) | Pending design decision |

---

### FR-GLB-13 — Session Board Setup Hub

**Feature:** Combined hub view showing Academic Sessions and Boards side-by-side for quick reference during tenant onboarding.

**Status:** Implemented (hub view) — full standalone CRUD for boards is pending

| Sub-Requirement | Description | Status |
|-----------------|-------------|--------|
| FR-GLB-13.1 | Display academic sessions (paginated 10/page) and boards (paginated 10/page) on single view | Done |
| FR-GLB-13.2 | Uses `Gate::any(['prime.board.viewAny'])` for auth | Done |
| FR-GLB-13.3 | CRUD actions for boards routed from this hub | Pending (routes not yet defined) |
| FR-GLB-13.4 | Stub methods (create, store, show, edit, update, destroy) | Stub |

---

## 5. Data Model

### 5.1 Geographic Hierarchy Tables

#### `glb_countries`

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| id | INT UNSIGNED | PK, AI | |
| name | VARCHAR(50) | NOT NULL, UNIQUE | |
| short_name | VARCHAR(10) | NOT NULL, UNIQUE | |
| global_code | VARCHAR(10) | NULL | ISO alpha-2/alpha-3 |
| currency_code | VARCHAR(8) | NULL | e.g., INR, USD |
| is_active | TINYINT(1) | DEFAULT 1 | |
| created_at | TIMESTAMP | NULL | |
| updated_at | TIMESTAMP | NULL | |
| deleted_at | TIMESTAMP | NULL | Soft delete |

Auto-increment starts at 11 (pre-seeded data present).

#### `glb_states`

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| id | INT UNSIGNED | PK, AI | |
| country_id | INT UNSIGNED | NOT NULL, FK → glb_countries.id RESTRICT | |
| name | VARCHAR(50) | NOT NULL | |
| short_name | VARCHAR(10) | NOT NULL | |
| global_code | VARCHAR(10) | NULL | |
| is_active | TINYINT(1) | DEFAULT 1 | |
| created_at, updated_at, deleted_at | TIMESTAMP | NULL | |

Unique key: `(country_id, name)`. Auto-increment starts at 71 (pre-seeded).

#### `glb_districts`

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| id | INT UNSIGNED | PK, AI | |
| state_id | INT UNSIGNED | NOT NULL, FK → glb_states.id RESTRICT | |
| name | VARCHAR(50) | NOT NULL | |
| short_name | VARCHAR(10) | NOT NULL | |
| global_code | VARCHAR(10) | NULL | |
| is_active | TINYINT(1) | DEFAULT 1 | |
| created_at, updated_at, deleted_at | TIMESTAMP | NULL | |

Unique key: `(state_id, name)`. Auto-increment starts at 290 (pre-seeded).

#### `glb_cities`

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| id | INT UNSIGNED | PK, AI | |
| district_id | INT UNSIGNED | NOT NULL, FK → glb_districts.id RESTRICT | |
| name | VARCHAR(100) | NOT NULL | |
| short_name | VARCHAR(20) | NOT NULL | |
| global_code | VARCHAR(20) | NULL | |
| default_timezone | VARCHAR(64) | NULL | e.g., Asia/Kolkata |
| is_active | TINYINT(1) | DEFAULT 1 | |
| created_at, updated_at, deleted_at | TIMESTAMP | NULL | |

Auto-increment starts at 21 (pre-seeded).

**Relationship Chain:** `glb_countries` → `glb_states` → `glb_districts` → `glb_cities` (one-to-many at each level, all with ON DELETE RESTRICT FKs)

---

### 5.2 Academic Reference Tables

#### `glb_academic_sessions`

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| id | INT UNSIGNED | PK, AI | |
| short_name | VARCHAR(20) | NOT NULL, UNIQUE | e.g., "2024-25" |
| name | VARCHAR(50) | NOT NULL | e.g., "Academic Year 2024-2025" |
| start_date | DATE | NOT NULL | Typically April 1 (Indian school year) |
| end_date | DATE | NOT NULL | Typically March 31 |
| is_current | TINYINT(1) | DEFAULT 1 | |
| current_flag | TINYINT(1) | GENERATED STORED | `CASE WHEN is_current=1 THEN 1 ELSE NULL END` |
| deleted_at, created_at, updated_at | TIMESTAMP | NULL | |

**Key Design:** `current_flag` is a generated column that is `1` when active and `NULL` when inactive. The `UNIQUE KEY uq_acadSession_currentFlag (current_flag)` enforces that only ONE session can be current at any time (NULLs are not unique in MySQL). Auto-increment starts at 31.

#### `glb_boards`

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| id | INT UNSIGNED | PK, AI | |
| name | VARCHAR(255) | NOT NULL, UNIQUE | e.g., "Central Board of Secondary Education" |
| short_name | VARCHAR(20) | NOT NULL, UNIQUE | e.g., "CBSE" |
| is_active | TINYINT(1) | DEFAULT 1 | |
| created_at, updated_at, deleted_at | TIMESTAMP | NULL | |

Auto-increment starts at 11 (pre-seeded with major Indian boards).

---

### 5.3 System Reference Tables

#### `glb_languages`

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| id | INT UNSIGNED | PK, AI | |
| code | VARCHAR(10) | NOT NULL, UNIQUE | ISO 639-1 code (en, hi, mr, ta, etc.) |
| name | VARCHAR(50) | NOT NULL | English display name |
| native_name | VARCHAR(50) | NULL | Native script name ("हिन्दी") |
| direction | ENUM('LTR','RTL') | DEFAULT 'LTR' | |
| is_active | TINYINT(1) | DEFAULT 1 | |

Note: `glb_languages` does NOT have `created_at`, `updated_at`, or `deleted_at` columns in the DDL schema. The Eloquent model uses SoftDeletes but the DDL lacks `deleted_at` — this is a schema gap.

#### `glb_menus`

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| id | INT UNSIGNED | PK, AI | |
| parent_id | INT UNSIGNED | NULL, FK → glb_menus.id RESTRICT | Self-referencing |
| is_category | TINYINT(1) | DEFAULT 0 | Categories have no parent (CHECK constraint) |
| code | VARCHAR(60) | NOT NULL, UNIQUE | |
| slug | VARCHAR(150) | NOT NULL | URL slug |
| title | VARCHAR(100) | NOT NULL | Display title |
| description | VARCHAR(255) | NULL | |
| icon | VARCHAR(150) | NULL | CSS icon class |
| route | VARCHAR(255) | NULL | Laravel named route |
| sort_order | INT UNSIGNED | NOT NULL | |
| visible_by_default | TINYINT(1) | DEFAULT 1 | |
| is_active | TINYINT(1) | DEFAULT 1 | |
| deleted_at, created_at, updated_at | TIMESTAMP | NULL | |

CHECK: Categories must have `parent_id IS NULL`. Non-categories may have any parent. Auto-increment starts at 29.

#### `glb_modules`

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| id | INT UNSIGNED | PK, AI | |
| parent_id | INT UNSIGNED | NULL, FK → glb_modules.id RESTRICT | For sub-modules |
| name | VARCHAR(50) | NOT NULL | |
| version | TINYINT | DEFAULT 1 | |
| is_sub_module | TINYINT(1) | DEFAULT 0 | Kept for CHECK constraint |
| description | VARCHAR(500) | NULL | |
| is_core | TINYINT(1) | DEFAULT 0 | Core modules cannot be removed from plans |
| default_visible | TINYINT(1) | DEFAULT 1 | |
| available_perm_view | TINYINT(1) | DEFAULT 1 | Governs whether view perm is available in plan |
| available_perm_add | TINYINT(1) | DEFAULT 1 | |
| available_perm_edit | TINYINT(1) | DEFAULT 1 | |
| available_perm_delete | TINYINT(1) | DEFAULT 1 | |
| available_perm_export | TINYINT(1) | DEFAULT 1 | |
| available_perm_import | TINYINT(1) | DEFAULT 1 | |
| available_perm_print | TINYINT(1) | DEFAULT 1 | |
| is_active | TINYINT(1) | DEFAULT 1 | |
| deleted_at, created_at, updated_at | TIMESTAMP | NULL | |

Unique key: `(parent_id, name, version)`. CHECK: sub-modules must have parent_id; top-level modules must not. Auto-increment starts at 6.

#### `glb_menu_model_jnt`

| Column | Type | Constraints |
|--------|------|-------------|
| id | INT UNSIGNED | PK, AI |
| menu_id | INT UNSIGNED | FK → glb_menus.id RESTRICT |
| module_id | INT UNSIGNED | FK → glb_modules.id RESTRICT |

**Note:** DDL table is named `glb_menu_model_jnt`. The Eloquent model references `glb_menu_module_jnt`. This naming discrepancy between DDL and code is a potential bug.

#### `glb_translations`

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| id | INT UNSIGNED | PK, AI | |
| translatable_type | VARCHAR(255) | NOT NULL | Laravel morph type |
| translatable_id | INT UNSIGNED | NOT NULL | |
| language_id | INT UNSIGNED | NOT NULL, FK → glb_languages.id CASCADE DELETE | |
| key | VARCHAR(255) | NOT NULL | Field name (e.g., 'name', 'description') |
| value | TEXT | NOT NULL | Translated value |
| created_at, updated_at | TIMESTAMP | NULL | |

Unique key: `(translatable_type, translatable_id, language_id, key)`.

---

### 5.4 Cross-DB Tables (Managed in GlobalMaster)

#### `prm_plans` (in prime_db)

Managed by `PlanController` and `Plan` model in GlobalMaster module.

| Column | Type | Notes |
|--------|------|-------|
| plan_code | VARCHAR(15) | Unique |
| version | TINYINT | |
| name | VARCHAR(30) | Unique |
| description | VARCHAR(255) | |
| billing_cycle_id | INT | FK → prm_billing_cycles |
| price_monthly | DECIMAL(12,2) | |
| price_yearly | DECIMAL(12,2) | |
| currency | CHAR(3) | ISO 4217 |
| trial_days | INT | |
| is_active | TINYINT(1) | |

#### `sys_dropdowns` (in prime_db)

Managed by `DropdownController` and `Dropdown` model in GlobalMaster module.

| Column | Type | Notes |
|--------|------|-------|
| ordinal | INT | Sort order |
| key | VARCHAR | Slugified lookup key |
| value | VARCHAR(255) | Display value |
| type | VARCHAR | String/Integer/Decimal/Date/etc. |
| additional_info | JSON | Extra metadata (`_json` convention) |
| is_active | TINYINT(1) | |

---

### 5.5 Eloquent Model Summary

| Model | Table | Connection | SoftDeletes | Key Relationships |
|-------|-------|------------|-------------|-------------------|
| Country | glb_countries | global_master_mysql | Yes | hasMany(State), hasMany(OrganizationGroup) |
| State | glb_states | global_master_mysql | Yes | belongsTo(Country), hasMany(District), hasMany(OrganizationGroup) |
| District | glb_districts | global_master_mysql | Yes | belongsTo(State), hasMany(City), hasMany(OrganizationGroup) |
| City | glb_cities | global_master_mysql | Yes | belongsTo(District), hasMany(OrganizationGroup), hasMany(StudentDetail) |
| Board | glb_boards | global_master_mysql | Yes | belongsToMany(Organization) via sch_board_organization_jnt |
| Language | glb_languages | global_master_mysql | Yes | (none in model) |
| Module | glb_modules | global_master_mysql | Yes | belongsTo(self:parent), hasMany(self:children), belongsToMany(Menu), belongsToMany(Plan), hasMany(TenantPlanModule), belongsToMany(TenantInvoice) |
| Plan | prm_plans | default | Yes | belongsToMany(Module), hasMany(TenantPlan), belongsTo(BillingCycle) |
| Dropdown | sys_dropdowns | default | Yes | belongsToMany(DropdownNeed), hasMany(Complaint*) |
| DropdownNeed | sys_dropdown_needs | default | Yes | hasMany(Dropdown), belongsToMany(Dropdown) |
| ActivityLog | sys_activity_logs | default | No | morphTo(subject), belongsTo(User) |
| Media | (migration-defined) | default | No | polymorphic |

---

## 6. Controller & Route Inventory

### 6.1 Controllers

| Controller | Methods | Auth Coverage | Notes |
|------------|---------|---------------|-------|
| `CountryController` | index, create, store, show(empty), edit, update, destroy, trashedCountry, restore, forceDelete, toggleStatus | All covered (prime.country.*) | `$request->all()` in store/update |
| `StateController` | index, create, store, show(empty), edit, update, destroy, trashedState, restore, forceDelete, toggleStatus, getStatesByCountry | All covered (prime.state.*) | Duplicate activityLog call in update |
| `DistrictController` | index, create, store, show, edit, update, destroy, trashedDistrict, restore, forceDelete, toggleStatus | All covered (prime.district.*) | Uses `validated()` correctly |
| `CityController` | index, create, store, show(empty), edit(string $id), update, destroy(string $id), trashedCity, restore, forceDelete, toggleStatus | All covered (prime.city.*) | Uses string $id not route binding |
| `ModuleController` | index, create, store, show, edit, update, destroy, trashedModule, restore, forceDelete, toggleStatus | All covered (prime.module.*) | show() has wrong permission |
| `AcademicSessionController` | index, create, store, show(empty), edit, update, destroy, trashedAcademicSession, restore, forceDelete, toggleStatus | Mixed: prime.* and global-master.* | Permission prefix inconsistency |
| `LanguageController` | index, create(no auth), store, show(no auth), edit(no auth), update(no auth), destroy, trashedlanguage, restore, forceDelete, toggleStatus | Partial — create/edit/update missing Gate | Uses Prime\Models\Language |
| `PlanController` | index, create, store, show(empty), edit, update, destroy, trashedPlan, restore, forceDelete, toggleStatus, planDetails | All covered (prime.plan.*) | `$request->all()` in store |
| `DropdownController` | index, create, store, show, edit, update, destroy, trashedDropdown, restore, forceDelete, toggleStatus | All covered (prime.dropdown.*) | |
| `GeographySetupController` | index, create(stub), store(stub), show(stub), edit(stub), update(stub), destroy(stub), search | index covered (Gate::any) | Hub-only, individual CRUD stubs |
| `SessionBoardSetupController` | index, create(stub), store(stub), show(stub), edit(stub), update(stub), destroy(stub) | index covered | Hub-only |
| `ActivityLogController` | index, create, store, edit, update, destroy | index covered, others are stubs | |
| `GlobalMasterController` | index, create, store(empty), show, edit, update(empty), destroy(empty) | None | Pure stubs, no auth |
| `OrganizationController` | index, create, store(empty), show, edit, update(empty), destroy(empty) | None | Pure stubs, no auth |
| `NotificationController` | testNotification, allNotifications | None | Dev/test utility |

### 6.2 Web Routes

All GlobalMaster routes are registered under:
- **Route prefix:** `global-master`
- **Route name prefix:** `global-master.`
- **Middleware:** `['auth', 'verified']`
- **Named as:** `central.global-master.*`

| Resource | Route Name Base | Extra Routes |
|----------|-----------------|--------------|
| language | global-master.language.* | trashed, restore, forceDelete, toggleStatus |
| module | global-master.module.* | trashed, restore, forceDelete, toggleStatus |
| country | global-master.country.* | trashed, restore, forceDelete, toggleStatus |
| plan | global-master.plan.* | trashed, restore, forceDelete, toggleStatus, details |
| state | global-master.state.* | trashed, restore, forceDelete, toggleStatus, get-states/{countryId} |
| city | global-master.city.* | trashed, restore, forceDelete, toggleStatus |
| district | global-master.district.* | trashed, restore, forceDelete, toggleStatus |
| location-setup | global-master.location-setup.* | search |
| activity-log | global-master.activity-log.* | — |
| dropdown | global-master.dropdown.* | trashed, restore, forceDelete, toggleStatus, mgmt, search |
| dropdown-need | global-master.dropdown-need.* | trashed, restore, forceDelete, toggleStatus, mgmt, search |
| global-master (resource) | global-master.index.* | GlobalMasterController stub resource |

**Note:** The routes/web.php for the module (`Modules/GlobalMaster/routes/web.php`) is empty — all GlobalMaster routes are registered in the root `routes/web.php` file.

### 6.3 API Routes

| Endpoint | Auth | Notes |
|----------|------|-------|
| `GET/POST/PUT/DELETE /v1/globalmasters` | `auth:sanctum` | Registered in `Modules/GlobalMaster/routes/api.php` — maps to `GlobalMasterController` stubs only |

---

## 7. Form Request Validation Rules

### 7.1 CountryRequest

| Field | Rules |
|-------|-------|
| name | required, string, max:50, unique:glb_countries (ignores self on update) |
| short_name | required, string, max:10 |
| global_code | nullable, string, max:10 |
| currency_code | nullable, string, max:8 |
| default_timezone | nullable, string, max:64 |
| is_active | required, boolean (checkbox pre-processed from 'on' → true) |

### 7.2 StateRequest

| Field | Rules |
|-------|-------|
| country_id | required, exists:glb_countries,id |
| name | required, string, max:50, unique:(glb_states scoped by country_id, ignores self) |
| short_name | required, string, max:10 |
| global_code | nullable, string, max:10 |
| default_timezone | nullable, string, max:64 |
| is_active | required, boolean |

### 7.3 DistrictRequest

| Field | Rules |
|-------|-------|
| state_id | required, exists:glb_states,id |
| name | required, string, max:50, unique:(glb_districts scoped by state_id) |
| short_name | required, string, max:10 |
| global_code | nullable, string, max:10 |
| is_active | required, boolean |

### 7.4 CityRequest

| Field | Rules |
|-------|-------|
| district_id | required, exists:glb_districts,id |
| name | required, string, max:100 |
| short_name | required, string, max:20 |
| global_code | nullable, string, max:20 |
| default_timezone | nullable, string, max:64 |
| is_active | required, boolean |

### 7.5 BoardRequest

| Field | Rules |
|-------|-------|
| name | required, string, max:50, unique:glb_boards (ignores self) |
| short_name | required, string, max:10, unique:glb_boards (ignores self) |
| is_active | required, boolean |

### 7.6 AcademicSessionRequest

| Field | Rules | Issue |
|-------|-------|-------|
| name | required, string, max:50, unique:glb_academic_sessions (ignores self) | |
| short_name | required, string, max:10, unique:glb_academic_sessions (ignores self) | |
| start_date | missing | **Gap — no validation for start_date** |
| end_date | missing | **Gap — no validation for end_date** |
| is_current | checkbox pre-processed | |

### 7.7 LanguageRequest

| Field | Rules |
|-------|-------|
| code | required, string, max:10, unique:glb_languages (ignores self) |
| name | required, string, max:50 |
| native_name | nullable, string, max:50 |
| direction | required, in:LTR,RTL |
| is_active | required, boolean |

### 7.8 ModuleRequest

| Field | Rules |
|-------|-------|
| name | required, string, max:50, unique:glb_modules (ignores self) |
| menu_id | required, array, min:1 |
| menu_id.* | integer, exists:glb_menus,id |
| version | required, string, max:10 |
| description | nullable, string, max:500 |
| is_core | required, boolean |
| default_visible | required, boolean |
| available_perm_view/add/edit/delete/export/import/print | required, boolean each |
| is_active | required, boolean |
| is_sub_module | nullable, string, max:50 (should be boolean — design inconsistency) |

### 7.9 PlanRequest

| Field | Rules |
|-------|-------|
| plan_code | required, string, max:15, unique:prm_plans |
| name | required, string, max:30, unique:prm_plans |
| version | required, string, max:10 |
| description | nullable, string, max:255 |
| billing_cycle_id | required, exists:prm_billing_cycles,id |
| price_monthly | nullable, numeric, between:0,9999999999.99 |
| price_yearly | nullable, numeric, between:0,9999999999.99 |
| currency | required, string, size:3 |
| trial_days | required, integer, min:1, max:30 |
| features | nullable, array |
| meta_data | nullable, array |
| module_ids | required, array, min:1 |
| module_ids.* | integer, exists:glb_modules,id |
| is_active | required, boolean |

### 7.10 DropdownRequest

| Field | Rules | Issue |
|-------|-------|-------|
| value | required, string, max:255, unique:sys_dropdowns (scoped by key) | |
| is_active | required, boolean | |
| key | not validated | **Gap** |
| type | not validated | **Gap** |
| org_id | not validated | **Gap** |

---

## 8. Business Rules

### 8.1 Geographic Hierarchy Rules

**BR-GLB-GEO-01:** Only one geographic level can be deactivated/activated at a time, but deactivating a country cascades downward. Activating a country does NOT auto-activate children — they remain inactive until individually activated.

**BR-GLB-GEO-02:** A state cannot be activated if its parent country is inactive. A district cannot be activated if its parent state is inactive. (City does not enforce this check — gap vs. State/District pattern.)

**BR-GLB-GEO-03:** Deletion is blocked (ON DELETE RESTRICT) for any geography record that has child records. A country with states cannot be force-deleted; states with districts cannot be force-deleted; districts with cities cannot be force-deleted.

**BR-GLB-GEO-04:** India-specific seeding: The platform is pre-seeded with India (36 states/UTs, ~290 districts, major cities). Initial auto-increment values reflect this: countries start at 11, states at 71, districts at 290, cities at 21.

### 8.2 Academic Session Rules

**BR-GLB-SES-01:** Only one academic session can be `is_current = true` at any given time. This is enforced by a MySQL generated column `current_flag` with a UNIQUE constraint — NULL values are excluded from the uniqueness check.

**BR-GLB-SES-02:** An active (is_active = true) academic session cannot be soft-deleted. The `destroy()` method checks `!$academicSession->is_active === true` — note this has a PHP operator precedence bug (`!bool === bool`) that should be `$academicSession->is_active !== true`.

**BR-GLB-SES-03:** Indian school academic year runs April 1 to March 31. Sessions should be seeded accordingly (e.g., "2024-25" = 2024-04-01 to 2025-03-31).

### 8.3 Educational Board Rules

**BR-GLB-BRD-01:** Standard Indian educational boards to be pre-seeded: CBSE (Central Board of Secondary Education), ICSE/ISC (Council for Indian School Certificate Examinations), State boards for each state/UT, IGCSE (Cambridge), IB (International Baccalaureate), NIOS (National Institute of Open Schooling).

**BR-GLB-BRD-02:** A board associated with tenant organizations cannot be deleted (FK RESTRICT will prevent orphan assignment).

### 8.4 Module Registry Rules

**BR-GLB-MOD-01:** `is_core = true` modules (e.g., School Setup, User Management) are included in all plans by default and cannot be deselected during plan creation.

**BR-GLB-MOD-02:** A module with `is_sub_module = true` must have a `parent_id` pointing to its parent module. Top-level modules must have `parent_id = NULL` (enforced by CHECK constraint).

**BR-GLB-MOD-03:** `available_perm_*` flags define which permission types are applicable for a module. If `available_perm_export = false`, the module does not expose an "export" permission option in role management.

**BR-GLB-MOD-04:** Module version is managed here. When a module is updated to a new version, a new record is created with incremented version (unique on `parent_id, name, version`).

### 8.5 Plan & Billing Rules

**BR-GLB-PLN-01:** Every plan must include at least 1 module (validated by `module_ids: required|array|min:1`).

**BR-GLB-PLN-02:** Plans have both `price_monthly` and `price_yearly` pricing — both are nullable to support one-time or custom pricing models.

**BR-GLB-PLN-03:** Currency must be a 3-character ISO 4217 code (default: INR for Indian schools).

**BR-GLB-PLN-04:** Trial days are bounded 1–30 days.

**BR-GLB-PLN-05:** Billing cycles: 1 = Monthly, 2 = Quarterly, 3 = Yearly, 4 = One-time. This mapping is maintained as a hardcoded array in `PlanController::edit()` — should be driven by `prm_billing_cycles` table.

### 8.6 Dropdown Rules

**BR-GLB-DRP-01:** Dropdown keys are slugified (using `Str::slug($key, '_')`) on creation. Example: "Blood Group" → "blood_group".

**BR-GLB-DRP-02:** Multiple values can be created in one store operation by providing comma-separated values. Duplicates are removed with `array_unique()` before insert.

**BR-GLB-DRP-03:** Ordinal is auto-incremented per `org_id` to maintain sort order within a key group.

**BR-GLB-DRP-04:** Dropdowns of type `String` are the default and most common. Other types (Integer, Decimal, Date, Datetime, Time, Boolean) enable type-aware handling in consuming modules.

### 8.7 Multilingual Support Rules

**BR-GLB-LANG-01:** The `glb_translations` table implements a polymorphic translation store. Any `glb_*` entity can have translated field values for any active language.

**BR-GLB-LANG-02:** Language direction is stored (`LTR`/`RTL`) to support Arabic, Urdu, and other RTL languages if the platform expands beyond India.

**BR-GLB-LANG-03:** The translation management UI is not yet built — this is a pending feature.

---

## 9. Permission & Authorization Model

### 9.1 Permission String Convention

All GlobalMaster permissions follow the pattern: `prime.{entity}.{action}`

### 9.2 Full Permission Matrix

| Entity | Permission Strings |
|--------|-------------------|
| Country | `prime.country.viewAny`, `prime.country.view`, `prime.country.create`, `prime.country.update`, `prime.country.delete`, `prime.country.restore`, `prime.country.forceDelete` |
| State | `prime.state.viewAny`, `prime.state.view`, `prime.state.create`, `prime.state.update`, `prime.state.delete`, `prime.state.restore`, `prime.state.forceDelete` |
| District | `prime.district.viewAny`, `prime.district.view`, `prime.district.create`, `prime.district.update`, `prime.district.delete`, `prime.district.restore`, `prime.district.forceDelete` |
| City | `prime.city.viewAny`, `prime.city.view`, `prime.city.create`, `prime.city.update`, `prime.city.delete`, `prime.city.restore`, `prime.city.forceDelete` |
| Module | `prime.module.viewAny`, `prime.module.view`, `prime.module.create`, `prime.module.update`, `prime.module.delete`, `prime.module.restore`, `prime.module.forceDelete` |
| Plan | `prime.plan.viewAny`, `prime.plan.view`, `prime.plan.create`, `prime.plan.update`, `prime.plan.delete`, `prime.plan.restore`, `prime.plan.forceDelete` |
| Board | `prime.board.viewAny`, `prime.board.view`, `prime.board.create`, `prime.board.update`, `prime.board.delete`, `prime.board.restore`, `prime.board.forceDelete` |
| Language | `prime.language.viewAny` (only one enforced — others missing) |
| Activity Log | `prime.activity-log.viewAny`, `prime.activity-log.create`, `prime.activity-log.update`, `prime.activity-log.delete` |
| Dropdown | `prime.dropdown.viewAny`, `prime.dropdown.view`, `prime.dropdown.create`, `prime.dropdown.update`, `prime.dropdown.delete`, `prime.dropdown.restore`, `prime.dropdown.forceDelete` |
| Academic Session | `prime.academic-session.viewAny` + `global-master.academic-session.*` (mixed prefixes) |

### 9.3 Policy Inventory

| Policy Class | Model | Methods |
|-------------|-------|---------|
| CountryPolicy | Country | viewAny, view, create, update, delete, restore, forceDelete |
| StatePolicy | State | viewAny, view, create, update, delete, restore, forceDelete |
| DistrictPolicy | District | viewAny, view, create, update, delete, restore, forceDelete |
| CityPolicy | City | viewAny, view, create, update, delete, restore, forceDelete |
| ModulePolicy | Module | viewAny, view, create, update, delete, restore, forceDelete |
| BoardPolicy | Board | viewAny, view, create, update, delete, restore, forceDelete |
| AcademicSessionPolicy | AcademicSession | (methods assumed standard) |
| LanguagePolicy | Language | (partial — create/update methods not enforced in controller) |
| PlanPolicy | Plan | (assumed standard) |
| DropdownPolicy | Dropdown | (assumed standard) |
| DropdownNeedPolicy | DropdownNeed | (assumed standard) |
| GeographySetupPolicy | — | Hub policy |

### 9.4 Authorization Method Used

`Gate::authorize('prime.entity.action')` is used directly in controller methods (not via constructor `$this->authorize()`). This means the Gate check happens at execution time, not at route resolution. The `Gate::any([...])` pattern is used in hub controllers (GeographySetupController, AcademicSessionController index).

---

## 10. Tests Inventory

### 10.1 Test Files

| File | Type | Framework | Count |
|------|------|-----------|-------|
| `tests/Unit/ArchitectureTest.php` | Unit | Pest | ~60 tests |
| `tests/Unit/ModelStructureTest.php` | Unit | Pest | ~40 tests |
| `tests/Unit/ControllerAuthTest.php` | Unit | Pest | ~35 tests |
| `tests/Unit/BoardTest.php` | Unit | PHPUnit class | 2 tests |

### 10.2 ArchitectureTest Coverage

- 14 controllers exist (class_exists check)
- 12 models exist and are instantiable
- 10 form requests exist, extend FormRequest, authorize() returns true
- Key validation rules present (name, code, plan_code, country_id)
- 6 migration files exist
- SoftDeletes trait on correct models (Country/State/District/City/Board/Language/Module/Plan/Dropdown/DropdownNeed)
- ActivityLog and Media do NOT use SoftDeletes (verified)
- Edge cases: geographic chain relationships, Module self-reference, Dropdown defaults, Plan decimal casts

### 10.3 ControllerAuthTest Coverage

- 5 main controllers (Country/State/City/District/Module) — all public methods have `Gate::authorize`
- Bug detection tests: `ModuleController::show()` uses `prime.module.create` (confirmed bug)
- `CountryController::show()` and `StateController::show()` are empty stubs (confirmed)
- Permission string scope verification (prime.country.*, prime.state.*, prime.module.*)
- 6 policies have all 7 standard methods
- ToggleStatus JSON response format (success, is_active, message keys)
- Country toggleStatus cascades to states/districts with transaction
- SoftDelete methods (destroy, restore, forceDelete) present on 3 main controllers

### 10.4 ModelStructureTest Coverage

- All 12 models: table name, SoftDeletes, fillable, casts
- Geographic models: correct connection (`global_master_mysql`)
- State: uses global_master_mysql connection (verified)
- City: has `studentDetails` relationship
- Board: has `organizations` relationship
- Language model: correct namespace (not aliased to a wrong class)
- Module: all 6 permission flag casts verified
- Plan: `price_monthly/yearly` cast to `decimal:2`
- ActivityLog: morphTo(subject), belongsTo(User), properties cast to array
- Dropdown: default type='String', default is_active=true
- DropdownNeed: 4 boolean casts verified
- Media model: not SoftDeletes

---

## 11. Known Issues & Technical Debt

### 11.1 Security Issues (High Priority)

| ID | Controller | Method | Issue | Fix Required |
|----|-----------|--------|-------|-------------|
| SEC-01 | CountryController | store() | `$request->all()` — unvalidated fields may reach `Model::create()` | Replace with `$request->validated()` |
| SEC-02 | CountryController | update() | `$request->all()` — same issue | Replace with `$request->validated()` |
| SEC-03 | StateController | store() | `$request->all()` | Replace with `$request->validated()` |
| SEC-04 | StateController | update() | `$request->all()` | Replace with `$request->validated()` |
| SEC-05 | CityController | store() | `$request->all()` | Replace with `$request->validated()` |
| SEC-06 | CityController | update() | `$request->all()` | Replace with `$request->validated()` |
| SEC-07 | ModuleController | store() | `$request->all()` | Replace with `$request->validated()` |
| SEC-08 | ModuleController | update() | `$request->all()` — only `billing_cycle` and `module_ids` are removed manually | Replace with `$request->validated()` |
| SEC-09 | PlanController | store() | `$request->all()` | Replace with `$request->validated()` |
| SEC-10 | LanguageController | create() | No `Gate::authorize()` | Add `Gate::authorize('prime.language.create')` |
| SEC-11 | LanguageController | edit() | No `Gate::authorize()` | Add `Gate::authorize('prime.language.update')` |
| SEC-12 | LanguageController | update() | No `Gate::authorize()` | Add `Gate::authorize('prime.language.update')` |

### 11.2 Logic Bugs (Medium Priority)

| ID | Location | Bug | Fix |
|----|---------|-----|-----|
| BUG-01 | AcademicSessionController::destroy() | `if (!$academicSession->is_active === true)` — PHP operator precedence: `!` binds tighter than `===`, so this is `(false === true)` which is always false | Change to `$academicSession->is_active !== true` |
| BUG-02 | ModuleController::show() | Uses `prime.module.create` permission; returns `module.edit` view | Change permission to `prime.module.view`; change view to `module.show` |
| BUG-03 | StateController::update() | `activityLog()` called twice (lines 95 and 109) | Remove duplicate call |
| BUG-04 | LanguageController::forceDelete() | Event logged as `'Stored'` instead of `'Deleted'` | Correct event string |
| BUG-05 | DistrictController::forceDelete() | Uses `prime.district.delete` permission (should be `prime.district.forceDelete`) | Correct permission string |

### 11.3 Inconsistencies (Low Priority)

| ID | Issue |
|----|-------|
| INC-01 | AcademicSessionController mixes `prime.*` and `global-master.*` permission prefixes |
| INC-02 | LanguageController mixes `prime.*` and `global-master.*` permission prefixes |
| INC-03 | LanguageController uses `Modules\Prime\Models\Language` not `Modules\GlobalMaster\Models\Language` |
| INC-04 | `AcademicSessionRequest` missing `start_date` and `end_date` validation |
| INC-05 | `LanguageController::index()` paginates 11/page (should be 10) |
| INC-06 | `ModuleRequest::is_sub_module` validated as `nullable|string|max:50` (should be `boolean`) |
| INC-07 | DDL table `glb_menu_model_jnt` referenced in code as `glb_menu_module_jnt` (naming discrepancy) |
| INC-08 | `glb_languages` DDL has no `created_at`, `updated_at`, `deleted_at` columns but model uses SoftDeletes |
| INC-09 | `GlobalMasterController`, `OrganizationController`, and `NotificationController` have zero auth checks |

### 11.4 Architecture Concerns

| ID | Issue | Recommendation |
|----|-------|----------------|
| ARCH-01 | Zero Service classes — all business logic in controllers | Extract reusable logic to Services (e.g., `GeographyService`, `ModulePlanService`) |
| ARCH-02 | `Plan` model lives in GlobalMaster but references `prm_plans` in prime_db — cross-DB architecture is fragile | Document the cross-DB dependency explicitly; consider moving Plan management to Prime module |
| ARCH-03 | `Dropdown` model uses `sys_dropdowns` (prime_db) not a `glb_*` table — misleading placement | Consider moving to Prime or SystemConfig module |
| ARCH-04 | `GlobalMasterController` and `OrganizationController` are pure stubs with no purpose | Either implement or remove |
| ARCH-05 | Module web.php routes file is empty — all routes in root web.php | This violates modular architecture; routes should be in module's routes/web.php |

---

## 12. API Endpoints

### 12.1 Current API State

The API is minimally configured. Only `GlobalMasterController` is exposed via API, which is a pure stub.

```
Route: /api/v1/globalmasters
Auth:  auth:sanctum
CRUD:  GET / POST / GET {id} / PUT {id} / DELETE {id}
```

All API methods return empty responses (stubs).

### 12.2 Required API Endpoints (Pending)

The following REST API endpoints are needed for tenant apps to consume GlobalMaster reference data:

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/api/v1/countries` | GET | List active countries for tenant dropdowns |
| `/api/v1/countries/{id}/states` | GET | Get states by country |
| `/api/v1/states/{id}/districts` | GET | Get districts by state |
| `/api/v1/districts/{id}/cities` | GET | Get cities by district |
| `/api/v1/boards` | GET | List active educational boards |
| `/api/v1/academic-sessions` | GET | List academic sessions |
| `/api/v1/academic-sessions/current` | GET | Get current academic session |
| `/api/v1/languages` | GET | List active languages |
| `/api/v1/dropdowns/{key}` | GET | Get dropdown values by key |
| `/api/v1/modules` | GET | List active modules (for plan display) |

---

## 13. Non-Functional Requirements

### 13.1 Performance

- Geographic hierarchy data is reference data (low write frequency). Implement caching (Redis/DB cache, 1-hour TTL) for country/state/district/city lists accessed by tenant apps.
- `GeographySetupController::index()` makes N+1 queries for the hub view (loading all countries+states+districts for filter dropdowns). This needs eager-loading optimization.
- Module and Plan listings should be cached since they change infrequently.

### 13.2 Data Integrity

- All FK constraints use `ON DELETE RESTRICT` — no orphan records can exist.
- Soft deletes (`deleted_at`) are used for all geographic and reference entities — data is never physically lost by normal operations.
- The `current_flag` generated column provides database-level uniqueness guarantee for active academic session.

### 13.3 Security

- All controllers (except stubs) use `Gate::authorize()` directly in each method. This provides method-level RBAC.
- The `$request->all()` pattern in 9 controller methods is a critical security gap — mass assignment protection is bypassed since all fillable fields pass through.
- The `authorize(): bool { return true; }` pattern in all FormRequests is intentional (Gate checks are in controllers), but it means FormRequest authorization is disabled.

### 13.4 Auditability

- All state changes in geographic entities, modules, plans, and dropdowns are recorded via `activityLog()` helper.
- Activity logs include: subject model, event type, user performing the action, changed attributes (old vs. new values), and custom message.
- Activity logs are append-only (no `deleted_at` on `sys_activity_logs` model).

---

## 14. Integration Points

### 14.1 Modules That Consume GlobalMaster Data

| Consumer Module | Data Used | How |
|-----------------|-----------|-----|
| SchoolSetup | glb_countries, glb_states, glb_districts, glb_cities | Direct FK reference in sch_organization_groups table |
| SchoolSetup | glb_boards | Many-to-many via sch_board_organization_jnt |
| Prime (Tenant Onboarding) | glb_academic_sessions, prm_plans, glb_modules | FK references in tenant creation wizard |
| Billing | prm_plans | Plan → TenantPlan → Invoice chain |
| All Tenant Modules | sys_dropdowns | Direct query by key |
| Auth/UserManagement | glb_modules, glb_menus | Permission and menu rendering |
| All Modules | sys_activity_logs | Write via activityLog() helper |

### 14.2 Database Connections

```
global_master_mysql  →  global_db      (Countries, States, Districts, Cities, Boards, Languages, Modules, Menus)
default (prime_db)   →  prime_db       (Plans, Dropdowns, ActivityLogs)
```

The `Module` model explicitly sets `protected $connection = 'global_master_mysql'`. The `Plan` model has the connection commented out (uses default prime_db connection).

### 14.3 External Dependencies

| Dependency | Version | Usage |
|------------|---------|-------|
| spatie/laravel-permission | v6.21 | RBAC via Gate::authorize() |
| nwidart/laravel-modules | v12 | Module architecture |
| stancl/tenancy | v3.9 | Central domain routing |
| Bootstrap 5 + AdminLTE 4 | — | Frontend views |

---

## 15. Pending Work & Gap Analysis

### 15.1 Implementation Gaps (By Priority)

#### Critical — Security Fixes

- [ ] Replace `$request->all()` with `$request->validated()` in 9 controller methods (SEC-01 through SEC-09)
- [ ] Add `Gate::authorize()` to LanguageController create/edit/update methods (SEC-10 through SEC-12)
- [ ] Fix `AcademicSessionController::destroy()` boolean logic bug (BUG-01)

#### High — Incomplete Features

- [ ] AcademicSessionRequest: add `start_date` and `end_date` validation rules with `date`, `before:end_date`/`after:start_date` cross-field validation
- [ ] BoardController: implement standalone CRUD routes separate from the hub view (currently only accessible via hub)
- [ ] Board: full trash/restore/force-delete UI (views exist, routes missing)
- [ ] SessionBoardSetupController: implement CRUD stub methods or redirect to dedicated controllers

#### Medium — Consistency/Quality

- [ ] Standardize permission prefix: all controllers should use `prime.*` (not `global-master.*`)
- [ ] Fix `ModuleController::show()` — wrong permission and wrong view (BUG-02)
- [ ] Remove duplicate `activityLog()` call in `StateController::update()` (BUG-03)
- [ ] Fix `LanguageController::forceDelete()` event string (BUG-04)
- [ ] Fix `DistrictController::forceDelete()` permission (BUG-05)
- [ ] Resolve DDL vs code naming discrepancy: `glb_menu_model_jnt` vs `glb_menu_module_jnt`
- [ ] Add `deleted_at`, `created_at`, `updated_at` to `glb_languages` DDL to match model SoftDeletes usage
- [ ] Fix `ModuleRequest::is_sub_module` validation type (string → boolean)
- [ ] Standardize pagination to 10/page (LanguageController currently uses 11)

#### Low — Architecture Improvements

- [ ] Move GlobalMaster routes from root `routes/web.php` into `Modules/GlobalMaster/routes/web.php`
- [ ] Create Service classes: `GeographyService`, `ModulePlanService`, `AcademicSessionService`
- [ ] Implement Translation Management UI for `glb_translations`
- [ ] Implement full REST API for tenant consumption of reference data (see Section 12.2)
- [ ] Remove or implement `GlobalMasterController` and `OrganizationController` stubs
- [ ] Remove `NotificationController` from GlobalMaster (belongs in a Notification module)
- [ ] Add Redis caching for geographic reference data and dropdown lookups
- [ ] City `toggleStatus`: add parent-district active check (consistent with State/District pattern)

### 15.2 Missing Features vs. RBS

| RBS Feature | Status |
|-------------|--------|
| F.A6.1.2 — Export audit logs CSV | Pending |
| F.A6.1.2 — Filter logs by user/date | Pending |
| Translation Management UI | Pending |
| Menu Management (glb_menus CRUD) | Done (in Prime/SystemConfig module, not GlobalMaster) |
| F.A8 — Data Privacy & Compliance | Not started |
| F.A9 — System Backup & Recovery | Not started |

### 15.3 Test Coverage Gaps

- [ ] Feature tests with database (RefreshDatabase) for geographic cascade operations
- [ ] Test that AcademicSession unique current constraint works correctly at DB level
- [ ] Test that Plan::store() requires at least 1 module
- [ ] Test Country::toggleStatus() DB transaction rollback on failure
- [ ] Test AcademicSessionController::destroy() bug (current logic is inverted)
- [ ] Integration test: tenant consumption of GlobalMaster data via API

---

*Document generated: 2026-03-25 | Source: Automated extraction from codebase inspection*
*Files analyzed: 15 controllers, 12 models, 10 FormRequests, 4 test files, global_db_v2.sql (189 lines), RBS Module A (lines 1786-1905)*
