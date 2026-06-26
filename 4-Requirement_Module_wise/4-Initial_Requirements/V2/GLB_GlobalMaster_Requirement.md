# GlobalMaster Module — Requirement Specification Document v2
**Version:** 2.0  |  **Date:** 2026-03-26  |  **Author:** Claude Code (Automated)
**Platform:** Prime-AI Academic Intelligence Platform
**Module Code:** GLB  |  **Module Path:** `Modules/GlobalMaster/`
**Module Type:** Global  |  **Database:** `global_db + prime_db`
**Table Prefix:** `glb_*`  |  **Processing Mode:** FULL
**RBS Reference:** Global Reference Data, Platform Masters  |  **RBS Version:** v4.0
**V1 Baseline:** `2-Requirement_Module_wise/2-Detailed_Requirements/V1/Dev_Done/GLB_GlobalMaster_Requirement.md`
**Gap Analysis:** `3-Project_Planning/2-Gap_Analysis/2-Modules_Wise/2026Mar22/GlobalMaster_Deep_Gap_Analysis.md`
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
10. [Tests Inventory](#10-tests-inventory)
11. [Known Issues and Technical Debt](#11-known-issues-and-technical-debt)
12. [API Endpoints](#12-api-endpoints)
13. [Non-Functional Requirements](#13-non-functional-requirements)
14. [Future Enhancements (Suggestions Only)](#14-future-enhancements-suggestions-only)
15. [Integration Points](#15-integration-points)
16. [V2 Change Summary vs V1](#16-v2-change-summary-vs-v1)

---

## 1. Module Overview

### 1.1 Purpose

GlobalMaster is the **central reference data management module** for the Prime-AI SaaS platform. It runs exclusively on the central domain (`admin.prime-ai.com`) and manages shared reference data consumed by all tenant schools across the platform.

Unlike tenant modules (which run inside isolated `tenant_{uuid}` databases), GlobalMaster data lives in `global_db` and is effectively read-only from the tenant perspective. The central Super-Admin team is the sole owner of this data.

### 1.2 Module Position in the Platform

```
Platform Layer          Module              Database
─────────────────────────────────────────────────────
Central (Super-Admin)   GlobalMaster (GLB)  global_db + prime_db (cross-DB)
Central (SaaS Mgmt)     Prime (PRM)         prime_db
Tenant (Per-School)     All other modules   tenant_{uuid}
```

### 1.3 Module Characteristics

| Attribute           | Value                                                      |
|---------------------|------------------------------------------------------------|
| Laravel Module      | `nwidart/laravel-modules` v12.0, module name `GlobalMaster` |
| Namespace           | `Modules\GlobalMaster`                                     |
| Module Code         | GLB                                                        |
| Domain              | Central (`admin.prime-ai.com`)                             |
| Primary DB          | `global_master_mysql` connection → `global_db`             |
| Secondary DB        | `default` connection → `prime_db` (Plans, Dropdowns, Logs) |
| Table Prefix        | `glb_*` (also reads `prm_plans`, `sys_dropdowns`, `sys_activity_logs`) |
| Auth                | Spatie Permission v6.21 via `Gate::authorize()`            |
| Frontend            | Bootstrap 5 + AdminLTE 4                                   |
| Completion Status   | ~55%                                                       |
| Module Scorecard    | 5.4/10 (from 2026-03-22 deep audit)                        |

### 1.4 Sub-Modules Managed

| # | Sub-Module | Primary Table(s) | Status |
|---|-----------|-----------------|--------|
| 1 | Geography Setup | `glb_countries`, `glb_states`, `glb_districts`, `glb_cities` | ✅ Implemented |
| 2 | Educational Boards | `glb_boards` | 🟡 Partial (hub-only, no standalone CRUD routes) |
| 3 | Academic Sessions | `glb_academic_sessions` | 🟡 Partial (bugs in destroy/validation) |
| 4 | Languages | `glb_languages` | 🟡 Partial (auth gaps, DDL schema gap) |
| 5 | Module Registry | `glb_modules`, `glb_menu_model_jnt` | 🟡 Partial (wrong perm on show, bugs) |
| 6 | SaaS Plans | `prm_plans`, `prm_module_plan_jnt` | 🟡 Partial (`$request->all()` bug) |
| 7 | Dropdowns | `sys_dropdown_table`, `sys_dropdown_needs` | ✅ Implemented |
| 8 | Activity Logs | `sys_activity_logs` | 🟡 Partial (list only, stubs elsewhere) |
| 9 | Translations | `glb_translations` | ❌ Not Started |
| 10 | Menus | `glb_menus` | ❌ Managed in SystemConfig (not GlobalMaster) |

### 1.5 V2 Key Deltas from V1

V2 incorporates all 47 gaps identified in the 2026-03-22 deep audit:
- **8 critical gaps** added as ❌ FR items
- **12 high-priority gaps** elevated to FR items with gap references
- **18 medium gaps** documented as technical debt requirements
- **9 new DDL schema gaps** identified (DBM-001 through DBM-010)
- **New sub-requirements** added for: Translation management, Menu management (cross-module), caching, service layer, route consolidation, and missing `AcademicSession` model

---

## 2. Scope and Boundaries

### 2.1 In Scope

- Full CRUD for all `glb_*` reference tables in `global_db`
- Soft-delete lifecycle (trash / restore / force-delete) for all entities
- Toggle active/inactive status for all entities
- Geographic hierarchy cascade (country deactivation propagates to states, districts, and cities)
- Module-Menu many-to-many mapping via `glb_menu_model_jnt`
- Plan-Module many-to-many assignment via `prm_module_plan_jnt`
- Activity log viewing (read-only audit trail from `sys_activity_logs`)
- Dropdown key-value management via `sys_dropdown_table`
- Translation management UI for `glb_translations` (pending implementation)
- Permission-based RBAC via Spatie Gate pattern

### 2.2 Out of Scope

- Tenant-specific customization of reference data (handled in `SchoolSetup` module)
- Billing and invoicing beyond plan definition (handled in `Billing` module)
- User and role management for tenants (handled in `Auth` and `UserManagement` modules)
- Menu display rendering in tenant apps (menus defined here but rendered via tenant middleware)
- Menu CRUD management UI (managed in `SystemConfig` module — confirmed by audit MF-004)
- HR, Payroll, Inventory modules (separate pending modules)

### 2.3 RBS Reference Mapping

| RBS Section | RBS Feature | GlobalMaster Coverage |
|-------------|-------------|----------------------|
| A1 — Tenant Registration | F.A1.1.2 — Configure Default Settings | `glb_academic_sessions`, `glb_countries` |
| A1 — Subscription Assignment | F.A1.2.1 — Choose Plan / Attach Modules | `prm_plans`, `glb_modules`, `prm_module_plan_jnt` |
| A2 — Feature Management | F.A2.1.1 — Enable/Disable Modules | `glb_modules` toggle |
| A3 — Geography | F.A3.x — Geographic Reference | `glb_countries`, `glb_states`, `glb_districts`, `glb_cities` |
| A4 — Education Standards | F.A4.1 — Board / Session Definitions | `glb_boards`, `glb_academic_sessions` |
| A5 — Multilingual | F.A5.1 — Language and Translation Support | `glb_languages`, `glb_translations` |
| A6 — Audit Logs | F.A6.1 — System Logs, Track Activities | `sys_activity_logs` viewer |

---

## 3. Actors and User Roles

### 3.1 Primary Actors

| Actor | Description | Default Permissions |
|-------|-------------|-------------------|
| Super Admin | Prime-AI platform operator | Full CRUD + forceDelete on all entities |
| Platform Manager | Senior reference data manager | Full CRUD, no forceDelete |
| Support Staff | Read-only viewer | `viewAny` only |

### 3.2 Permission Scope

All GlobalMaster permissions follow the standardized pattern: **`prime.{entity}.{action}`**

Note: A known inconsistency exists where `AcademicSessionController` and `LanguageController` mix `global-master.*` and `prime.*` prefixes — this is a documented bug (BUG-006 in gap analysis, INC-01 in V1).

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
**Status:** 🟡 Partial (implemented, but security gaps and cascade incompleteness)

| ID | Sub-Requirement | Description | Status | Gap Ref |
|----|-----------------|-------------|--------|---------|
| FR-GLB-01.1 | List countries | Paginated (10/page), sorted by `is_active` DESC | ✅ | |
| FR-GLB-01.2 | Create country | Fields: `name` (unique), `short_name` (unique), `global_code`, `currency_code`, `is_active` | ✅ | |
| FR-GLB-01.3 | Edit country | Unique name validation ignoring current record | ✅ | |
| FR-GLB-01.4 | Soft-delete country | Deactivates before soft-deleting | ✅ | |
| FR-GLB-01.5 | View trash and restore | Trashed countries listing + restore | ✅ | |
| FR-GLB-01.6 | Force-delete | Permanent delete of trashed record | ✅ | |
| FR-GLB-01.7 | Toggle status with cascade | Deactivating cascades to states and districts in DB transaction | 🟡 | |
| FR-GLB-01.8 | Activity log | Logged on Create/Update/Trash/Restore/Delete/Toggle | ✅ | |
| FR-GLB-01.9 | ❌ Fix `$request->all()` in store/update | Must use `$request->validated()` — mass-assignment risk | ❌ | BUG-001, SEC-002 |
| FR-GLB-01.10 | ❌ Cascade toggle must include cities | Country deactivation must cascade to all child cities, not only states and districts | ❌ | BUG-010 |
| FR-GLB-01.11 | ❌ Force-delete must handle FK violation | Wrap `forceDelete` in try/catch; return user-friendly error when states exist | ❌ | SEC-007 |
| FR-GLB-01.12 | ❌ Fix missing `$connection` and `$casts` on Country model | `Country.php` must set `$connection = 'global_master_mysql'` and cast `is_active` to boolean | ❌ | DBM-004, DBM-005 |
| FR-GLB-01.13 | ❌ Remove stale V1 imports | `CountryController.php` imports `App\Models\V1\GlobalMaster\District` and `State` — stale unused paths | ❌ | ARCH-002 |

---

### FR-GLB-02 — State Management

**Feature:** CRUD management for states, scoped to parent country.
**Status:** 🟡 Partial (duplicate activity log bug)

| ID | Sub-Requirement | Description | Status | Gap Ref |
|----|-----------------|-------------|--------|---------|
| FR-GLB-02.1 | List states | Grouped by country with eager-loaded relationship | ✅ | |
| FR-GLB-02.2 | Create state | Fields: `country_id` (FK), `name`, `short_name`, `global_code`, `is_active` | ✅ | |
| FR-GLB-02.3 | Unique constraint | `(country_id, name)` pair must be unique | ✅ | |
| FR-GLB-02.4 | Edit state | Scoped uniqueness check on update | ✅ | |
| FR-GLB-02.5 | Soft-delete, restore, force-delete | Full lifecycle | ✅ | |
| FR-GLB-02.6 | Toggle status | Blocked if parent country is inactive | ✅ | |
| FR-GLB-02.7 | AJAX: get states by country | `GET /get-states/{countryId}` — returns states for dependent dropdowns | ✅ | |
| FR-GLB-02.8 | ❌ Fix duplicate activity log in update | `activityLog()` called twice in `StateController::update()` (lines 95 and 109) | ❌ | BUG-002 |
| FR-GLB-02.9 | ❌ Fix `$request->all()` in store/update | Must use `$request->validated()` | ❌ | BUG-001 |
| FR-GLB-02.10 | ❌ Fix activity log before parent-check | Activity log is written before checking if parent country is active in `toggleStatus` — failed toggles log as successful | ❌ | SEC-006 |
| FR-GLB-02.11 | ❌ Implement `getStatesByCountry` method | Route `get-states/{countryId}` references a method that does not exist in `StateController.php` | ❌ | RT-004 |
| FR-GLB-02.12 | ❌ Paginate `StateController::index()` | Currently loads ALL countries with states unbounded — no pagination | ❌ | PERF-003 |

---

### FR-GLB-03 — District Management

**Feature:** CRUD management for districts, scoped to parent state.
**Status:** ✅ Best-quality geography controller (uses `$request->validated()`)

| ID | Sub-Requirement | Description | Status | Gap Ref |
|----|-----------------|-------------|--------|---------|
| FR-GLB-03.1 | List districts | Grouped by country > state hierarchy | ✅ | |
| FR-GLB-03.2 | Create district | Fields: `state_id` (FK), `name`, `short_name`, `global_code`, `is_active` | ✅ | |
| FR-GLB-03.3 | Unique constraint | `(state_id, name)` must be unique | ✅ | |
| FR-GLB-03.4 | Uses `$request->validated()` | Correct pattern for store and update | ✅ | |
| FR-GLB-03.5 | Toggle status | Blocked if parent state is inactive | ✅ | |
| FR-GLB-03.6 | Full soft-delete lifecycle | Trash, restore, force-delete | ✅ | |
| FR-GLB-03.7 | ❌ Fix `forceDelete` permission | Uses `prime.district.delete` instead of `prime.district.forceDelete` | ❌ | BUG-005 |

---

### FR-GLB-04 — City Management

**Feature:** CRUD management for cities, scoped to parent district.
**Status:** 🟡 Partial (security gaps, no parent-check in toggle, route-binding issue)

| ID | Sub-Requirement | Description | Status | Gap Ref |
|----|-----------------|-------------|--------|---------|
| FR-GLB-04.1 | List cities | Full eager-load: `district > state > country` | ✅ | |
| FR-GLB-04.2 | Create city | Fields: `district_id` (FK), `name`, `short_name`, `global_code`, `default_timezone`, `is_active` | ✅ | |
| FR-GLB-04.3 | Edit/Update city | Standard edit workflow | ✅ | |
| FR-GLB-04.4 | Full soft-delete lifecycle | Trash, restore, force-delete | ✅ | |
| FR-GLB-04.5 | Toggle status | Status toggle without parent check | 🟡 | |
| FR-GLB-04.6 | ❌ Fix `$request->all()` in store/update | Must use `$request->validated()` | ❌ | BUG-001 |
| FR-GLB-04.7 | ❌ Fix route model binding | `city.edit()` uses `string $id` with raw `City::findOrFail($id)` instead of route model binding | ❌ | V1: FR-GLB-04.4 |
| FR-GLB-04.8 | ❌ Add parent status check to toggle | City `toggleStatus` must verify parent district is active before activating | ❌ | Gap vs State/District pattern |
| FR-GLB-04.9 | ❌ Optimize 4-level eager loading | `City::with(['district', 'district.state', 'district.state.country'])` on every page should be paginated | ❌ | PERF-005 |

---

### FR-GLB-05 — Geography Setup Dashboard

**Feature:** Unified tabbed interface (Countries / States / Districts / Cities) with tab-aware search and pagination.
**Status:** 🟡 Partial (hub index works; CRUD stub methods empty)

| ID | Sub-Requirement | Description | Status | Gap Ref |
|----|-----------------|-------------|--------|---------|
| FR-GLB-05.1 | Tabbed index view | Four tab panels: country, state, district, city on `location-setup/index` | ✅ | |
| FR-GLB-05.2 | Tab-aware search | `?tab=country&search=india` searches only active tab entity | ✅ | |
| FR-GLB-05.3 | Independent pagination | `country_page`, `state_page`, `district_page`, `city_page` per tab | ✅ | |
| FR-GLB-05.4 | AJAX search endpoint | `location-setup/search?tab=&search=` returns plucked names | ✅ | |
| FR-GLB-05.5 | Gate check | `Gate::any(['prime.*.viewAny'])` — allows if user has any geography viewAny permission | ✅ | |
| FR-GLB-05.6 | ❌ Remove/implement hub stub methods | `GeographySetupController` stubs (create, store, show, edit, update, destroy) have no logic and no auth | ❌ | AUTH-002 |
| FR-GLB-05.7 | ❌ Add rate limiting to search | `GeographySetupController::search()` and index search have no rate limiting | ❌ | SEC-005 |
| FR-GLB-05.8 | ❌ Fix unbounded country/state load | `Country::has('states')->with('states')->get()` loads all countries without pagination — N+1 risk | ❌ | PERF-002 |
| FR-GLB-05.9 | ❌ Fix LIKE search pattern | `%{$search}%` on unparameterized input (4 places) — allow DoS via crafted patterns | ❌ | SEC-001 |

---

### FR-GLB-06 — Educational Board Management

**Feature:** CRUD management for educational boards (CBSE, ICSE, State boards, IGCSE, IB, NIOS).
**Status:** 🟡 Partial (FormRequest exists; dedicated standalone BoardController routes are missing)

| ID | Sub-Requirement | Description | Status | Gap Ref |
|----|-----------------|-------------|--------|---------|
| FR-GLB-06.1 | Create board | Fields: `name` (unique), `short_name` (unique), `is_active` | ✅ | |
| FR-GLB-06.2 | Edit/Update board | Self-ignore uniqueness on update | ✅ | |
| FR-GLB-06.3 | Board in hub view | Displayed in `session-board-setup` hub view alongside academic sessions | ✅ | |
| FR-GLB-06.4 | Board-Organization relationship | Many-to-many via `sch_board_organization_jnt` | ✅ | |
| FR-GLB-06.5 | Board index view | `resources/views/board/index.blade.php` exists | ✅ | |
| FR-GLB-06.6 | ❌ Implement dedicated BoardController | `BoardController` is imported in `routes/web.php` as `Modules\Prime\Http\Controllers\BoardController` — the GlobalMaster `BoardController.php` does not exist | ❌ | MF-002 |
| FR-GLB-06.7 | ❌ Implement board trash/restore/force-delete routes | Views exist (`board/trash.blade.php`) but routes are not defined | ❌ | V1: FR-GLB-06.6 |
| FR-GLB-06.8 | ❌ Implement SessionBoardSetupController CRUD stubs | Stub methods (create, store, show, edit, update, destroy) have no logic and no auth | ❌ | AUTH-005 |

---

### FR-GLB-07 — Academic Session Management

**Feature:** CRUD for global academic year definitions (2024-25, 2025-26, etc.) used as reference data for tenant schools.
**RBS:** F.A1.1.2 ST.A1.1.2.1 — Set academic year
**Status:** 🟡 Partial (multiple bugs in validation, destroy guard, and auth)

| ID | Sub-Requirement | Description | Status | Gap Ref |
|----|-----------------|-------------|--------|---------|
| FR-GLB-07.1 | Create session | Fields: `name`, `short_name` (both unique), `start_date`, `end_date`, `is_current` | ✅ | |
| FR-GLB-07.2 | Only-one-current enforcement | DB generated column `current_flag` with UNIQUE constraint enforces single current session | ✅ | |
| FR-GLB-07.3 | Toggle is_current | Activating one session deactivates all others | ✅ | |
| FR-GLB-07.4 | Active session destroy guard | `destroy()` blocks deletion of active session | 🟡 | |
| FR-GLB-07.5 | Session-Board hub view | Combined view listing sessions + boards paginated on one page | ✅ | |
| FR-GLB-07.6 | ❌ Fix AcademicSession model — missing from GlobalMaster | `AcademicSessionController.php` imports `Modules\GlobalMaster\Models\AcademicSession` but only `Modules\Prime\Models\AcademicSession.php` exists — runtime class-not-found | ❌ | MF-001 |
| FR-GLB-07.7 | ❌ Fix inverted destroy guard | `if (!$academicSession->is_active === true)` has operator precedence bug — active sessions CAN be deleted (guard is inverted). Fix: `if ($academicSession->is_active === true)` | ❌ | BUG-004 |
| FR-GLB-07.8 | ❌ Add start_date and end_date validation | `AcademicSessionRequest` validates only `name` and `short_name`. Must add `start_date` (required, date, before:end_date) and `end_date` (required, date, after:start_date) | ❌ | BUG-005 |
| FR-GLB-07.9 | ❌ Fix `$request->all()` in store/update | Must use `$request->validated()` (lines 44 and 83 of AcademicSessionController) | ❌ | BUG-001 |
| FR-GLB-07.10 | ❌ Standardize Gate permission prefix | `create()/store()` uses `global-master.academic-session.create`; `index()` uses `prime.academic-session.viewAny` — must be uniform `prime.*` | ❌ | BUG-006 |
| FR-GLB-07.11 | ❌ Fix missing `is_active` column in DDL | `glb_academic_sessions` DDL has `is_current` but no `is_active` column — controller references `is_active` for toggle | ❌ | DBM-003 |

---

### FR-GLB-08 — Language Management

**Feature:** CRUD for platform-supported languages used for multilingual content and translations.
**Status:** 🟡 Partial (4 auth gaps, wrong model import, DDL schema gap)

| ID | Sub-Requirement | Description | Status | Gap Ref |
|----|-----------------|-------------|--------|---------|
| FR-GLB-08.1 | List languages | Paginated (10/page — currently 11, inconsistency) | 🟡 | |
| FR-GLB-08.2 | Create language | Fields: `code` (ISO, unique), `name`, `native_name`, `direction` (LTR/RTL), `is_active` | ✅ | |
| FR-GLB-08.3 | Edit/Update language | `$request->validated()` used correctly | ✅ | |
| FR-GLB-08.4 | Full soft-delete lifecycle | Trash, restore, force-delete | ✅ | |
| FR-GLB-08.5 | ❌ Fix 4 missing Gate checks | `create()`, `store()`, `edit()`, `update()` have no `Gate::authorize()` calls — any authenticated user can create/edit languages | ❌ | AUTH-001 |
| FR-GLB-08.6 | ❌ Fix wrong model import | `LanguageController.php` imports `Modules\Prime\Models\Language` instead of `Modules\GlobalMaster\Models\Language` | ❌ | BUG-007 |
| FR-GLB-08.7 | ❌ Fix forceDelete event label | `forceDelete()` logs event as `'Stored'` instead of `'Deleted'` | ❌ | V1: FR-GLB-08.8 |
| FR-GLB-08.8 | ❌ Standardize Gate permission prefix | `destroy()` uses `global-master.language.delete`; `index()` uses `prime.language.viewAny` — must be uniform `prime.*` | ❌ | BUG-006 |
| FR-GLB-08.9 | ❌ Add timestamps to `glb_languages` DDL | `glb_languages` table missing `created_at`, `updated_at`, `deleted_at` — violates platform standard; Language model uses SoftDeletes which requires `deleted_at` | ❌ | MF-005, DBM-002 |
| FR-GLB-08.10 | ❌ Fix pagination to 10/page | `LanguageController::index()` uses `paginate(11)` — platform standard is 10 | ❌ | INC-05 |

---

### FR-GLB-09 — Module Registry Management

**Feature:** CRUD for the platform's module registry. Defines what functional modules exist in Prime-AI, permission availability flags, core/non-core status, and menu associations.
**RBS:** F.A2.1.1 — Enable/Disable Modules
**Status:** 🟡 Partial (wrong permission on show, duplicate log bug, `$request->all()`)

| ID | Sub-Requirement | Description | Status | Gap Ref |
|----|-----------------|-------------|--------|---------|
| FR-GLB-09.1 | List modules | Paginated (10/page) with eager-loaded menus | ✅ | |
| FR-GLB-09.2 | Create module | Fields: `name`, `version`, `is_sub_module`, `description`, `is_core`, `default_visible`, 7 permission flags, `is_active` | ✅ | |
| FR-GLB-09.3 | Assign menus | Many-to-many assignment via `glb_menu_model_jnt` (code references `glb_menu_module_jnt`) during create | ✅ | |
| FR-GLB-09.4 | Update module with menu sync | Replaces all existing menu assignments on update | ✅ | |
| FR-GLB-09.5 | Self-referencing sub-modules | Parent/children relationship for sub-modules via `parent_id` | ✅ | |
| FR-GLB-09.6 | Toggle active/inactive | AJAX toggle endpoint | ✅ | |
| FR-GLB-09.7 | Full soft-delete lifecycle | Trash, restore, force-delete | ✅ | |
| FR-GLB-09.8 | ❌ Fix `$request->all()` in store/update | Must use `$request->validated()` | ❌ | BUG-001 |
| FR-GLB-09.9 | ❌ Fix `show()` wrong permission | `ModuleController::show()` uses `prime.module.create` (should be `prime.module.view`) | ❌ | BUG-002 |
| FR-GLB-09.10 | ❌ Fix `show()` wrong view | `ModuleController::show()` returns `module.edit` view (should return `module.show`) | ❌ | BUG-002 |
| FR-GLB-09.11 | ❌ Fix duplicate activity log in update | `activityLog()` called twice in `ModuleController::update()` (lines 113 and 127) | ❌ | BUG-003 |
| FR-GLB-09.12 | ❌ Fix `is_sub_module` validation type | `ModuleRequest::is_sub_module` validated as `nullable|string|max:50` (should be `boolean`) | ❌ | INC-06 |
| FR-GLB-09.13 | ❌ Fix DDL vs code table name mismatch | DDL defines `glb_menu_model_jnt`; Eloquent pivot references `glb_menu_module_jnt` — names must be reconciled | ❌ | DBM-009, INC-07 |
| FR-GLB-09.14 | ❌ Fix hardcoded DB prefix in Module relationship | `Module.php` line 100: `'prime_db.glb_module_plan_jnt'` hardcodes database name in pivot | ❌ | DBM-009 |
| FR-GLB-09.15 | ❌ Sub-module UI | No form UI to set `parent_id` for sub-module creation | ❌ | V1: FR-GLB-09.11 |

---

### FR-GLB-10 — SaaS Plan Management

**Feature:** CRUD for SaaS subscription plans assigned to tenant schools. Plans define pricing, billing cycle, trial period, and included modules.
**Note:** Plan data lives in `prm_plans` table in `prime_db`, managed in GlobalMaster for co-location with Module management.
**RBS:** F.A1.2.1 — Choose Plan / Attach Modules
**Status:** 🟡 Partial (`$request->all()` in store, stub show, planDetails auth gap)

| ID | Sub-Requirement | Description | Status | Gap Ref |
|----|-----------------|-------------|--------|---------|
| FR-GLB-10.1 | List plans | Paginated (10/page) | ✅ | |
| FR-GLB-10.2 | Create plan | Fields: `plan_code` (unique), `name` (unique), `version`, `description`, `billing_cycle_id`, `price_monthly`, `price_quarterly`, `price_yearly`, `currency` (3-char), `trial_days`, `is_active` | ✅ | |
| FR-GLB-10.3 | Assign modules to plan | Many-to-many via `prm_module_plan_jnt`, min 1 module required | ✅ | |
| FR-GLB-10.4 | Update plan with module sync | Replaces all module assignments on update | ✅ | |
| FR-GLB-10.5 | Billing cycle mapping | IDs: 1=Monthly, 2=Quarterly, 3=Yearly, 4=One-time | ✅ | |
| FR-GLB-10.6 | Plan details AJAX | `GET plan/details/{plan}` — returns plan + modules as JSON for modal | ✅ | |
| FR-GLB-10.7 | Toggle active/inactive | AJAX toggle | ✅ | |
| FR-GLB-10.8 | Full soft-delete lifecycle | Trash, restore, force-delete | ✅ | |
| FR-GLB-10.9 | ❌ Fix `$request->all()` in store | Must use `$request->validated()` | ❌ | BUG-001 |
| FR-GLB-10.10 | ❌ Add Gate check to `planDetails()` | `PlanController::planDetails()` has no `Gate::authorize()` — any authenticated user can view plan+module details | ❌ | AUTH-008 |
| FR-GLB-10.11 | ❌ Implement `show()` method | `PlanController::show()` returns empty body | ❌ | V1: FR-GLB-10.10 |
| FR-GLB-10.12 | ❌ Add `price_quarterly` to V2 DDL | `prm_plans` DDL v2 adds `price_quarterly` column — PlanRequest and Plan model must be updated | ❌ | 🆕 V2 schema delta |
| FR-GLB-10.13 | ❌ Drive billing cycles from DB | Billing cycle mapping is a hardcoded array in `PlanController::edit()` — should be driven by `prm_billing_cycles` table | ❌ | V1: BR-GLB-PLN-05 |

---

### FR-GLB-11 — Dropdown Management

**Feature:** CRUD for global enumeration values (`sys_dropdown_table`) used across the platform for lookup lists.
**Status:** ✅ Mostly implemented (N+1 query issue, validation gaps on `key/type/org_id`)

| ID | Sub-Requirement | Description | Status | Gap Ref |
|----|-----------------|-------------|--------|---------|
| FR-GLB-11.1 | List dropdowns | List distinct keys paginated (10/page), each key showing grouped values | ✅ | |
| FR-GLB-11.2 | Bulk create | Supports comma-separated values split into multiple records | ✅ | |
| FR-GLB-11.3 | Record fields | `key` (slugified), `value`, `type` (String/Integer/Decimal/Date/Datetime/Time/Boolean), `ordinal`, `is_active` | ✅ | |
| FR-GLB-11.4 | Edit single value | Standard edit workflow | ✅ | |
| FR-GLB-11.5 | Toggle active/inactive | AJAX toggle | ✅ | |
| FR-GLB-11.6 | Full soft-delete lifecycle | Trash, restore, force-delete | ✅ | |
| FR-GLB-11.7 | ❌ Fix `key`, `type`, `org_id` validation | `DropdownRequest` has these fields commented out — they are not validated, allowing empty/arbitrary values | ❌ | DBM-010 |
| FR-GLB-11.8 | ❌ Fix N+1 in Dropdown index | `DropdownController::index()` executes one query per key to load values — must use `groupBy` or eager loading | ❌ | PERF-001 |
| FR-GLB-11.9 | ❌ Fix `org_id` assignment | `Dropdown::where('org_id', auth()->user()->id)` uses user ID as org_id — semantically incorrect | ❌ | BUG-009 |
| FR-GLB-11.10 | ❌ Fix `DropdownRequest` stale field references | `DropdownRequest.php` references `$this->input('table_name')` and `$this->input('column_name')` which are not in validation rules | ❌ | DBM-010 |
| FR-GLB-11.11 | ❌ Implement `search` method on DropdownController | Route at web.php references `DropdownController::search()` which does not exist | ❌ | RT-006 |
| FR-GLB-11.12 | ❌ Remove duplicate Dropdown model | `Dropdown.php` exists at `/Models/Dropdown.php` (root, no SoftDeletes) AND `/app/Models/Dropdown.php` (standard, correct) — root copy must be deleted | ❌ | BUG-008 |
| FR-GLB-11.13 | ❌ Remove backup files from repository | `Dropdown.php.bkk`, `DropdownSeeder copy.bk`, `DropdownSeeder_24_01_2026.php.bk` must be removed | ❌ | ARCH-005 |

---

### FR-GLB-12 — Activity Log Viewer

**Feature:** Read-only audit trail viewer showing all platform activity recorded by the `activityLog()` helper.
**RBS:** F.A6.1 — System Logs, Track Activities
**Status:** 🟡 Partial (list works; filtering/export pending; stub CRUD methods present)

| ID | Sub-Requirement | Description | Status | Gap Ref |
|----|-----------------|-------------|--------|---------|
| FR-GLB-12.1 | List activity logs | Reverse-chronological, paginated (10/page) | ✅ | |
| FR-GLB-12.2 | Activity log is read-only | No create/edit/delete actions should be available from the UI | ✅ (by design) | |
| FR-GLB-12.3 | ❌ Implement log filters | Filter by user, date range, event type, subject model type | ❌ | V1: FR-GLB-12.3 |
| FR-GLB-12.4 | ❌ Implement CSV export | Export filtered logs to CSV | ❌ | V1: FR-GLB-12.4 |
| FR-GLB-12.5 | ❌ Remove/clean stub methods | `ActivityLogController` stubs (store, show, edit, update, destroy) have Gate checks but empty bodies — dead code | ❌ | AUTH-007 |
| FR-GLB-12.6 | ❌ Implement `search` method on ActivityLogController | Route references `ActivityLogController::search()` which does not exist | ❌ | RT-005 |

---

### FR-GLB-13 — Session Board Setup Hub

**Feature:** Combined hub view showing Academic Sessions and Boards side-by-side for tenant onboarding reference.
**Status:** 🟡 Partial (hub view works; Board standalone CRUD not implemented)

| ID | Sub-Requirement | Description | Status | Gap Ref |
|----|-----------------|-------------|--------|---------|
| FR-GLB-13.1 | Hub index view | Academic sessions (paginated 10/page) + boards (paginated 10/page) on single view | ✅ | |
| FR-GLB-13.2 | Auth on index | `Gate::any(['prime.board.viewAny'])` | ✅ | |
| FR-GLB-13.3 | ❌ Implement or remove hub CRUD stubs | `SessionBoardSetupController` stubs (create, store, show, edit, update, destroy) have no logic and no auth | ❌ | AUTH-005 |

---

### FR-GLB-14 — Translation Management (New in V2)

**Feature:** CRUD management for multilingual translations of reference data stored in `glb_translations`.
**Status:** ❌ Not Started

| ID | Sub-Requirement | Description | Status | Gap Ref |
|----|-----------------|-------------|--------|---------|
| FR-GLB-14.1 | ❌ Create Translation model | `glb_translations` DDL exists but no Translation model in GlobalMaster | ❌ | MF-003 |
| FR-GLB-14.2 | ❌ Create TranslationController | CRUD controller for managing translations of any `glb_*` entity field | ❌ | MF-003 |
| FR-GLB-14.3 | ❌ Translation index view | List translations grouped by entity type and language | ❌ | MF-003 |
| FR-GLB-14.4 | ❌ Create/edit translation form | Form with `translatable_type`, `translatable_id`, `language_id` (FK to `glb_languages`), `key`, `value` | ❌ | MF-003 |
| FR-GLB-14.5 | ❌ Unique constraint enforcement | `(translatable_type, translatable_id, language_id, key)` must be unique — enforced by DDL and validated in request | ❌ | MF-003 |
| FR-GLB-14.6 | ❌ Cascade on language delete | `glb_translations.language_id` FK uses `ON DELETE CASCADE` — verify Eloquent model handles this | ❌ | 🆕 |
| FR-GLB-14.7 | ❌ TranslationRequest FormRequest | Must validate: `translatable_type`, `translatable_id`, `language_id` (exists in `glb_languages`), `key`, `value` | ❌ | MF-003 |

---

### FR-GLB-15 — Service Layer (Architecture Requirement, New in V2)

**Feature:** Extract reusable business logic from controllers into service classes.
**Status:** ❌ Not Started (zero service classes currently exist)

| ID | Sub-Requirement | Description | Status | Gap Ref |
|----|-----------------|-------------|--------|---------|
| FR-GLB-15.1 | ❌ Create `GeographyService` | Extract toggle cascade logic from `CountryController::toggleStatus()` | ❌ | ARCH-001 |
| FR-GLB-15.2 | ❌ Create `ModulePlanService` | Extract plan-module sync, billing cycle mapping, and module assignment logic | ❌ | ARCH-001 |
| FR-GLB-15.3 | ❌ Create `DropdownService` | Extract ordinal calculation, key slugification, and bulk-create logic | ❌ | ARCH-001 |
| FR-GLB-15.4 | ❌ Create `TranslationService` | Service for creating/syncing translations for any polymorphic entity | ❌ | ARCH-001, MF-003 |

---

### FR-GLB-16 — Route Consolidation (Architecture Requirement, New in V2)

**Feature:** Consolidate triplicated route groups and move routes to module's own `routes/web.php`.
**Status:** ❌ Not Started

| ID | Sub-Requirement | Description | Status | Gap Ref |
|----|-----------------|-------------|--------|---------|
| FR-GLB-16.1 | ❌ Consolidate triplicated route groups | `global-master` route group appears three times in `routes/web.php` (lines 85-251, 384-493, 629-818) — creates conflicting route names and duplicate endpoints | ❌ | RT-001 |
| FR-GLB-16.2 | ❌ Move routes to module web.php | `Modules/GlobalMaster/routes/web.php` is empty — all routes defined in root `routes/web.php` violating modular architecture | ❌ | RT-003, ARCH-05 |
| FR-GLB-16.3 | ❌ Implement or remove GlobalMasterController | `GlobalMasterController` has 7 methods with zero auth checks and empty bodies — should be implemented with full auth or removed | ❌ | AUTH-003 |
| FR-GLB-16.4 | ❌ Implement or remove OrganizationController | `OrganizationController` has 7 methods with zero auth checks and empty bodies | ❌ | AUTH-004 |
| FR-GLB-16.5 | ❌ Remove or secure NotificationController | `NotificationController::testNotification()` exposes test functionality to any authenticated user — no Gate check | ❌ | AUTH-006 |

---

### FR-GLB-17 — Reference Data Caching (New in V2)

**Feature:** Cache static reference data to reduce database load for frequently accessed, rarely-changing reference data.
**Status:** ❌ Not Started

| ID | Sub-Requirement | Description | Status | Gap Ref |
|----|-----------------|-------------|--------|---------|
| FR-GLB-17.1 | ❌ Cache country list | Countries list (read by tenant forms) cached with 1-hour TTL; cache invalidated on create/update/toggle | ❌ | PERF-006 |
| FR-GLB-17.2 | ❌ Cache states by country | `get-states/{countryId}` response cached with 1-hour TTL | ❌ | PERF-006 |
| FR-GLB-17.3 | ❌ Cache module and plan list | `glb_modules` and `prm_plans` cached since they change infrequently | ❌ | PERF-006 |
| FR-GLB-17.4 | ❌ Cache active academic session | Current academic session cached — single record query on every tenant request | ❌ | PERF-006 |
| FR-GLB-17.5 | ❌ Cache board list | `glb_boards` list cached | ❌ | PERF-006 |

---

## 5. Data Model

### 5.1 Geographic Hierarchy Tables (global_db)

#### `glb_countries`

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| id | INT UNSIGNED | PK, AI=11 | Pre-seeded with India and major countries |
| name | VARCHAR(50) | NOT NULL, UNIQUE `uq_country_name` | |
| short_name | VARCHAR(10) | NOT NULL, UNIQUE `uq_countries_shortName` | |
| global_code | VARCHAR(10) | NULL | ISO alpha-2/alpha-3 |
| currency_code | VARCHAR(8) | NULL | e.g., INR, USD |
| is_active | TINYINT(1) | NOT NULL DEFAULT 1 | |
| created_at | TIMESTAMP | NULL | |
| updated_at | TIMESTAMP | NULL | |
| deleted_at | TIMESTAMP | NULL | SoftDelete |

**DDL Gap:** No `created_by` column (project standard). Country Eloquent model missing `$connection` and `$casts` (DBM-004, DBM-005).

---

#### `glb_states`

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| id | INT UNSIGNED | PK, AI=71 | Pre-seeded: India has 36 states/UTs |
| country_id | INT UNSIGNED | NOT NULL, FK → `glb_countries.id` ON DELETE RESTRICT | |
| name | VARCHAR(50) | NOT NULL | |
| short_name | VARCHAR(10) | NOT NULL | |
| global_code | VARCHAR(10) | NULL | |
| is_active | TINYINT(1) | NOT NULL DEFAULT 1 | |
| created_at, updated_at, deleted_at | TIMESTAMP | NULL | |

**Unique Key:** `uq_state_countryId_name (country_id, name)`

---

#### `glb_districts`

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| id | INT UNSIGNED | PK, AI=290 | Pre-seeded: ~290 Indian districts |
| state_id | INT UNSIGNED | NOT NULL, FK → `glb_states.id` ON DELETE RESTRICT | |
| name | VARCHAR(50) | NOT NULL | |
| short_name | VARCHAR(10) | NOT NULL | |
| global_code | VARCHAR(10) | NULL | |
| is_active | TINYINT(1) | NOT NULL DEFAULT 1 | |
| created_at, updated_at, deleted_at | TIMESTAMP | NULL | |

**Unique Key:** `uq_district_stateId_name (state_id, name)`

---

#### `glb_cities`

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| id | INT UNSIGNED | PK, AI=21 | Pre-seeded: major Indian cities |
| district_id | INT UNSIGNED | NOT NULL, FK → `glb_districts.id` ON DELETE RESTRICT | |
| name | VARCHAR(100) | NOT NULL | |
| short_name | VARCHAR(20) | NOT NULL | |
| global_code | VARCHAR(20) | NULL | |
| default_timezone | VARCHAR(64) | NULL | e.g., Asia/Kolkata |
| is_active | TINYINT(1) | NOT NULL DEFAULT 1 | |
| created_at, updated_at, deleted_at | TIMESTAMP | NULL | |

**Relationship Chain:** `glb_countries` → `glb_states` → `glb_districts` → `glb_cities` (one-to-many at each level, all FK ON DELETE RESTRICT)

---

### 5.2 Academic Reference Tables (global_db)

#### `glb_academic_sessions`

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| id | INT UNSIGNED | PK, AI=31 | |
| short_name | VARCHAR(20) | NOT NULL, UNIQUE `uq_acadSessions_shortName` | e.g., "2024-25" |
| name | VARCHAR(50) | NOT NULL | e.g., "Academic Year 2024-2025" |
| start_date | DATE | NOT NULL | Typically April 1 (Indian school year) |
| end_date | DATE | NOT NULL | Typically March 31 next year |
| is_current | TINYINT(1) | NOT NULL DEFAULT 1 | |
| current_flag | TINYINT(1) | GENERATED STORED | `CASE WHEN is_current=1 THEN 1 ELSE NULL END` |
| deleted_at, created_at, updated_at | TIMESTAMP | NULL | |

**DDL Gap (DBM-003):** `glb_academic_sessions` has `is_current` but no `is_active` column — controller references `is_active` for toggle status.

**Key Design:** `current_flag` generated column + `UNIQUE KEY uq_acadSession_currentFlag (current_flag)` ensures only one session is current at a time (NULLs excluded from uniqueness in MySQL).

---

#### `glb_boards`

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| id | INT UNSIGNED | PK, AI=11 | Pre-seeded: CBSE, ICSE, State boards |
| name | VARCHAR(255) | NOT NULL, UNIQUE `uq_academicBoard_name` | |
| short_name | VARCHAR(20) | NOT NULL, UNIQUE `uq_academicBoard_shortName` | |
| is_active | TINYINT(1) | NOT NULL DEFAULT 1 | |
| created_at, updated_at, deleted_at | TIMESTAMP | NULL | |

---

### 5.3 System Reference Tables (global_db)

#### `glb_languages`

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| id | INT UNSIGNED | PK, AI | |
| code | VARCHAR(10) | NOT NULL, UNIQUE `uq_languages_code` | ISO 639-1 (en, hi, mr, ta, etc.) |
| name | VARCHAR(50) | NOT NULL | English display name |
| native_name | VARCHAR(50) | NULL | Native script ("हिन्दी") |
| direction | ENUM('LTR','RTL') | DEFAULT 'LTR' | |
| is_active | TINYINT(1) | DEFAULT 1 | |

**Critical DDL Gap (DBM-002):** `glb_languages` is missing `created_at`, `updated_at`, and `deleted_at` columns. The Language Eloquent model uses `SoftDeletes` which requires `deleted_at`. Migration to add these columns is required.

---

#### `glb_menus`

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| id | INT UNSIGNED | PK, AI=29 | |
| parent_id | INT UNSIGNED | NULL, FK → `glb_menus.id` ON DELETE RESTRICT | Self-referencing |
| is_category | TINYINT(1) | NOT NULL DEFAULT 0 | CHECK: categories have no parent |
| code | VARCHAR(60) | NOT NULL, UNIQUE `uq_menus_code` | |
| slug | VARCHAR(150) | NOT NULL | URL slug |
| title | VARCHAR(100) | NOT NULL | Display title |
| description | VARCHAR(255) | NULL | |
| icon | VARCHAR(150) | NULL | CSS icon class |
| route | VARCHAR(255) | NULL | Laravel named route |
| sort_order | INT UNSIGNED | NOT NULL | |
| visible_by_default | TINYINT(1) | NOT NULL DEFAULT 1 | |
| is_active | TINYINT(1) | NOT NULL DEFAULT 1 | |
| deleted_at, created_at, updated_at | TIMESTAMP | NULL | |

**Check Constraint:** `chk_is_category_parentId` — categories must have `parent_id IS NULL`; non-categories may have any parent.
**Note (MF-004):** Menu CRUD management is handled in the `SystemConfig` module, not GlobalMaster. GlobalMaster only assigns menus to modules.

---

#### `glb_modules`

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| id | INT UNSIGNED | PK, AI=6 | |
| parent_id | INT UNSIGNED | NULL, FK → `glb_modules.id` ON DELETE RESTRICT | For sub-modules |
| name | VARCHAR(50) | NOT NULL | |
| version | TINYINT | NOT NULL DEFAULT 1 | |
| is_sub_module | TINYINT(1) | NOT NULL DEFAULT 0 | Kept for CHECK constraint |
| description | VARCHAR(500) | NULL | |
| is_core | TINYINT(1) | NOT NULL DEFAULT 0 | Core modules cannot be removed from plans |
| default_visible | TINYINT(1) | NOT NULL DEFAULT 1 | |
| available_perm_view | TINYINT(1) | NOT NULL DEFAULT 1 | |
| available_perm_add | TINYINT(1) | NOT NULL DEFAULT 1 | |
| available_perm_edit | TINYINT(1) | NOT NULL DEFAULT 1 | |
| available_perm_delete | TINYINT(1) | NOT NULL DEFAULT 1 | |
| available_perm_export | TINYINT(1) | NOT NULL DEFAULT 1 | |
| available_perm_import | TINYINT(1) | NOT NULL DEFAULT 1 | |
| available_perm_print | TINYINT(1) | NOT NULL DEFAULT 1 | |
| is_active | TINYINT(1) | NOT NULL DEFAULT 1 | |
| deleted_at, created_at, updated_at | TIMESTAMP | NULL | |

**Unique Key:** `uq_module_parentId_name_version (parent_id, name, version)`

**Check Constraint:** `chk_isSubModule_parentId` — sub-modules must have `parent_id`; top-level modules must have `parent_id IS NULL`.

---

#### `glb_menu_model_jnt` (DDL name) / `glb_menu_module_jnt` (code name)

| Column | Type | Constraints |
|--------|------|-------------|
| id | INT UNSIGNED | PK, AI |
| menu_id | INT UNSIGNED | FK → `glb_menus.id` ON DELETE RESTRICT |
| module_id | INT UNSIGNED | FK → `glb_modules.id` ON DELETE RESTRICT |

**Critical Mismatch (INC-07, DBM-009):** DDL defines `glb_menu_model_jnt`; Eloquent Module model references `glb_menu_module_jnt` as the pivot table. These must be reconciled — either rename the DDL table or fix the Eloquent pivot reference.

---

#### `glb_translations`

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| id | INT UNSIGNED | PK, AI | |
| translatable_type | VARCHAR(255) | NOT NULL | Laravel morph type (e.g., `Modules\GlobalMaster\Models\Country`) |
| translatable_id | INT UNSIGNED | NOT NULL | Primary key of the related record |
| language_id | INT UNSIGNED | NOT NULL, FK → `glb_languages.id` ON DELETE CASCADE | |
| key | VARCHAR(255) | NOT NULL | Field name (e.g., 'name', 'description') |
| value | TEXT | NOT NULL | Translated value |
| created_at, updated_at | TIMESTAMP | NULL | |

**Unique Key:** `uq_translatable_language_key (translatable_type, translatable_id, language_id, key)`

**Note:** No `deleted_at` — translations are not soft-deleted; deletion is cascade from language or manual hard delete.

---

### 5.4 Cross-DB Tables (Managed in GlobalMaster, Located in prime_db)

#### `prm_plans` (in prime_db)

Managed by `PlanController` and `Plan` model in GlobalMaster module. `Plan` model uses `$table = 'prm_plans'` and `$connection = default` (prime_db).

| Column | Type | Notes |
|--------|------|-------|
| id | INT UNSIGNED | PK, AI |
| plan_code | VARCHAR(20) | Unique composite: `(plan_code, version)` |
| version | INT UNSIGNED | DEFAULT 0 |
| name | VARCHAR(100) | |
| description | VARCHAR(255) | NULL |
| billing_cycle_id | SMALLINT | FK → `prm_billing_cycles.id` ON DELETE RESTRICT |
| price_monthly | DECIMAL(12,2) | NULL |
| price_quarterly | DECIMAL(12,2) | NULL — 🆕 new column in v2 DDL |
| price_yearly | DECIMAL(12,2) | NULL |
| currency | CHAR(3) | NOT NULL DEFAULT 'INR' |
| trial_days | INT UNSIGNED | DEFAULT 0 |
| is_active | TINYINT(1) | NOT NULL DEFAULT 1 |
| deleted_at, created_at, updated_at | TIMESTAMP | NULL |

---

#### `prm_module_plan_jnt` (in prime_db)

| Column | Type | Notes |
|--------|------|-------|
| id | INT UNSIGNED | PK, AI |
| plan_id | INT UNSIGNED | FK → `prm_plans.id` ON DELETE CASCADE |
| module_id | INT UNSIGNED | FK → `glb_modules.id` (cross-DB via VIEW in prime_db) |
| is_active | TINYINT(1) UNSIGNED | NOT NULL |
| created_at, updated_at | TIMESTAMP | NULL |

**Cross-DB Note:** `module_id` references `glb_modules` which is in `global_db`. The comment in DDL notes: "Note: `glb_modules` is a VIEW in prime_db; FK may need to reference global_master.glb_modules directly". The `Module.php` model hardcodes `'prime_db.glb_module_plan_jnt'` as the pivot table (DBM-009).

---

#### `sys_dropdown_table` (in prime_db)

Managed by `DropdownController` and `Dropdown` model. Model maps to `sys_dropdown_table`.

| Column | Type | Notes |
|--------|------|-------|
| id | INT UNSIGNED | PK, AI |
| ordinal | INT | Sort order within key group |
| key | VARCHAR | Slugified lookup key |
| value | VARCHAR(255) | Display value |
| type | VARCHAR | String/Integer/Decimal/Date/Datetime/Time/Boolean |
| additional_info | JSON | Extra metadata |
| org_id | INT UNSIGNED | Organization scope |
| is_active | TINYINT(1) | |
| deleted_at, created_at, updated_at | TIMESTAMP | NULL |

---

### 5.5 Eloquent Model Summary

| Model | File | Table | DB Connection | SoftDeletes | Key Issues |
|-------|------|-------|---------------|-------------|------------|
| Country | app/Models/Country.php | glb_countries | Missing `$connection` (DBM-004) | Yes | No `$casts` (DBM-005) |
| State | app/Models/State.php | glb_states | global_master_mysql | Yes | |
| District | app/Models/District.php | glb_districts | global_master_mysql (commented out) | Yes | Connection commented out |
| City | app/Models/City.php | glb_cities | global_master_mysql | Yes | |
| Board | app/Models/Board.php | glb_boards | global_master_mysql | Yes | |
| Language | app/Models/Language.php | glb_languages | global_master_mysql | Yes | DDL missing `deleted_at` |
| Module | app/Models/Module.php | glb_modules | global_master_mysql | Yes | Hardcoded `prime_db.` prefix in pivot |
| Plan | app/Models/Plan.php | prm_plans | default (prime_db) | Yes | Cross-DB placement |
| Dropdown | app/Models/Dropdown.php | sys_dropdown_table | default (prime_db) | Yes | Duplicate model at root Models/ |
| DropdownNeed | app/Models/DropdownNeed.php | sys_dropdown_needs | default (prime_db) | Yes | |
| ActivityLog | app/Models/ActivityLog.php | sys_activity_logs | default (prime_db) | No | No `deleted_at` in table |
| Media | app/Models/Media.php | (undefined) | default | No | Empty shell (`$fillable = []`) |

**Note:** `AcademicSession` model does not exist in GlobalMaster. `AcademicSessionController` imports `Modules\GlobalMaster\Models\AcademicSession` which is actually at `Modules\Prime\Models\AcademicSession` (MF-001).

---

### 5.6 DDL-Level Issues Summary

| ID | Table | Issue | Priority |
|----|-------|-------|----------|
| DBM-001 | All `glb_*` tables | Missing `created_by` column (project standard) | P2 |
| DBM-002 | `glb_languages` | Missing `created_at`, `updated_at`, `deleted_at` columns | P1 |
| DBM-003 | `glb_academic_sessions` | Missing `is_active` column; controller uses `is_active` for toggle | P0 |
| DBM-004 | Country model | Missing `$connection = 'global_master_mysql'` | P1 |
| DBM-005 | Country model | Missing `$casts` for `is_active` (all other geo models have it) | P1 |
| DBM-006 | ActivityLog model | No SoftDeletes; no `deleted_at` in migration | P3 |
| DBM-007 | Media model | Empty shell — `$fillable = []`, no table, no relationships | P3 |
| DBM-008 | Plan model | `$table = 'prm_plans'` in prime_db; lives in GlobalMaster module — cross-DB architecture | P2 |
| DBM-009 | Module model | Hardcodes `'prime_db.glb_module_plan_jnt'` as pivot | P2 |
| DBM-010 | DropdownRequest | References `table_name`/`column_name` fields not in validation rules | P2 |

---

## 6. Controller and Route Inventory

### 6.1 Controllers

| Controller | Location | Method Count | Auth Coverage | Primary Issues |
|-----------|---------|-------------|---------------|----------------|
| `CountryController` | app/Http/Controllers/ | 11 | All covered (`prime.country.*`) | `$request->all()`, cascade misses cities |
| `StateController` | app/Http/Controllers/ | 12 | All covered (`prime.state.*`) | `$request->all()`, duplicate log, missing `getStatesByCountry` |
| `DistrictController` | app/Http/Controllers/ | 11 | All covered (`prime.district.*`) | Wrong permission on `forceDelete` |
| `CityController` | app/Http/Controllers/ | 11 | All covered (`prime.city.*`) | `$request->all()`, string $id, no parent check |
| `ModuleController` | app/Http/Controllers/ | 11 | All covered (`prime.module.*`) | `$request->all()`, wrong perm/view on show, duplicate log |
| `AcademicSessionController` | app/Http/Controllers/ | 11 | Mixed `prime.*` and `global-master.*` | `$request->all()`, inverted destroy guard, wrong model import |
| `LanguageController` | app/Http/Controllers/ | 11 | Partial — 4 methods missing Gate | Wrong model import, wrong log event, mixed perm prefix |
| `PlanController` | app/Http/Controllers/ | 12 | All covered + `planDetails` missing auth | `$request->all()`, `planDetails` no Gate check |
| `DropdownController` | app/Http/Controllers/ | 12 | All covered (`prime.dropdown.*`) | N+1 queries, `org_id` semantics, missing `search` method |
| `GeographySetupController` | app/Http/Controllers/ | 8 | Only index covered; stubs have no auth | Unbounded queries, LIKE injection risk |
| `SessionBoardSetupController` | app/Http/Controllers/ | 7 | Only index covered; stubs have no auth | Stub methods with no logic |
| `ActivityLogController` | app/Http/Controllers/ | 6 | index covered; stubs have checks but empty bodies | Missing `search`, stale CRUD stubs |
| `GlobalMasterController` | app/Http/Controllers/ | 7 | ZERO auth on all 7 methods | Pure stubs |
| `OrganizationController` | app/Http/Controllers/ | 7 | ZERO auth on all 7 methods | Pure stubs |
| `NotificationController` | app/Http/Controllers/ | 2 | ZERO auth | Dev/test utility exposed to all authenticated users |

**Total Controllers:** 15 (from actual directory listing)

### 6.2 Models

| Model | Status | Key Relationships |
|-------|--------|------------------|
| Country | Partial | `hasMany(State)`, `hasMany(OrganizationGroup)` |
| State | OK | `belongsTo(Country)`, `hasMany(District)` |
| District | OK | `belongsTo(State)`, `hasMany(City)` |
| City | OK | `belongsTo(District)`, `hasMany(StudentDetail)` |
| Board | OK | `belongsToMany(Organization)` via `sch_board_organization_jnt` |
| Language | OK | None declared |
| Module | OK | Self-reference parent/children, `belongsToMany(Menu)`, `belongsToMany(Plan)` |
| Plan | OK | `belongsToMany(Module)`, `hasMany(TenantPlan)`, `belongsTo(BillingCycle)` |
| Dropdown | Duplicate exists | `belongsToMany(DropdownNeed)` |
| DropdownNeed | OK | `hasMany(Dropdown)`, `belongsToMany(Dropdown)` |
| ActivityLog | OK (no SoftDeletes) | `morphTo(subject)`, `belongsTo(User)` |
| Media | Shell | Empty |

**Total Models:** 12 in `app/Models/` + 1 rogue at root `Models/Dropdown.php`

### 6.3 Policies

| Policy | Model | Registered in AppServiceProvider | Notes |
|--------|-------|----------------------------------|-------|
| CountryPolicy | Country | Yes | Standard 7 methods |
| StatePolicy | State | Yes | Standard 7 methods |
| DistrictPolicy | District | Yes | Standard 7 methods |
| CityPolicy | City | Yes | Standard 7 methods |
| BoardPolicy | Board | Yes | Standard 7 methods |
| ModulePolicy | Module | Yes | Standard 7 methods |
| PlanPolicy | Plan | Yes | Standard 7 methods |
| AcademicSessionPolicy | AcademicSession | Yes | Standard 7 methods |
| LanguagePolicy | Language | Yes | Partial — create/update not enforced in controller |
| ActivityLogPolicy | ActivityLog | Yes | Stubs |
| DropdownPolicy | Dropdown | Yes | Standard 7 methods |
| DropdownNeedPolicy | DropdownNeed | Yes | Standard 7 methods |
| DropdownNeedMgmtPolicy | — | Unknown | Separate from DropdownNeedPolicy |
| GeographySetupPolicy | — | NOT registered | Hub policy unregistered |

**Note:** Policies are registered but controllers use `Gate::authorize('prime.x.y')` with string permissions — Spatie permission model used, NOT policy method resolution through Gate.

### 6.4 Form Requests

| FormRequest | Controller(s) | Fields Validated | Issues |
|-------------|--------------|-----------------|--------|
| CountryRequest | CountryController | name, short_name, global_code, currency_code, default_timezone, is_active | None |
| StateRequest | StateController | country_id, name, short_name, global_code, default_timezone, is_active | None |
| DistrictRequest | DistrictController | state_id, name, short_name, global_code, is_active | None |
| CityRequest | CityController | district_id, name, short_name, global_code, default_timezone, is_active | None |
| BoardRequest | (SessionBoardSetupController) | name, short_name, is_active | Dedicated BoardController missing |
| AcademicSessionRequest | AcademicSessionController | name, short_name only — start_date, end_date, is_current MISSING | Critical gap BUG-005 |
| LanguageRequest | LanguageController | code, name, native_name, direction, is_active | None |
| ModuleRequest | ModuleController | name, menu_id, version, description, is_core, default_visible, 7 perm flags, is_active, is_sub_module | is_sub_module type wrong (INC-06) |
| PlanRequest | PlanController | plan_code, name, version, description, billing_cycle_id, price_monthly, price_yearly, currency, trial_days, features, meta_data, module_ids, is_active | price_quarterly not in request |
| DropdownRequest | DropdownController | value, is_active only — key, type, org_id NOT validated | Critical validation gap |

**Total Form Requests:** 10 (no TranslationRequest, no ToggleStatusRequest)

### 6.5 Web Routes

All GlobalMaster routes are registered in the root `routes/web.php` (the module's own `routes/web.php` is empty). Three separate `global-master` route groups exist in web.php (RT-001):

| Resource | Route Name Base | Extra Routes | Status |
|----------|-----------------|--------------|--------|
| country | global-master.country.* | trashed, restore, forceDelete, toggleStatus | Active |
| state | global-master.state.* | trashed, restore, forceDelete, toggleStatus, get-states/{countryId} | RT-004: method missing |
| district | global-master.district.* | trashed, restore, forceDelete, toggleStatus | Active |
| city | global-master.city.* | trashed, restore, forceDelete, toggleStatus | Active |
| module | global-master.module.* | trashed, restore, forceDelete, toggleStatus | Active |
| plan | global-master.plan.* | trashed, restore, forceDelete, toggleStatus, details | Active |
| language | global-master.language.* | trashed, restore, forceDelete, toggleStatus | Active |
| academic-session | global-master.academic-session.* | trashed, restore, forceDelete, toggleStatus | Active |
| board | global-master.board.* | trashed, restore, forceDelete, toggleStatus | BoardController missing |
| location-setup | global-master.location-setup.* | search | Active |
| activity-log | global-master.activity-log.* | search | RT-005: search method missing |
| dropdown | global-master.dropdown.* | trashed, restore, forceDelete, toggleStatus, mgmt, search | RT-006: search method missing |
| dropdown-need | global-master.dropdown-need.* | trashed, restore, forceDelete, toggleStatus, mgmt, search | |
| global-master (resource) | global-master.index.* | GlobalMasterController stub | Auth-less stubs |

### 6.6 Blade Views

| View Path | Description | Status |
|-----------|-------------|--------|
| `country/index, create, edit, trash` | Country CRUD views | ✅ |
| `state/index, create, edit, trash` | State CRUD views | ✅ |
| `district/index, create, edit, trash` | District CRUD views | ✅ |
| `city/index, create, edit, trash` | City CRUD views | ✅ |
| `module/index, create, edit, trash` | Module CRUD views | ✅ |
| `plan/index, create, edit, trash` | Plan CRUD views | ✅ |
| `language/index, create, edit, trash` | Language CRUD views | ✅ |
| `academic-session/index, create, edit, trash` | Academic session views | ✅ |
| `board/index, create, edit, trash` | Board views (exist) | ✅ |
| `dropdown/index, create, edit, trash` | Dropdown views | ✅ |
| `activity-log/index, create, edit, trash` | Activity log views | ✅ (create/edit unused) |
| `session-board-setup/index` | Session-board hub | ✅ |
| `location-management/index` | Geography hub | ✅ |
| `index.blade.php` | Module root index | ✅ |
| `components/layouts/master.blade.php` | Layout component | ✅ |

**Total Views:** 48 (from actual directory listing)

### 6.7 Seeders

| Seeder | Purpose | Status |
|--------|---------|--------|
| `GlobalMasterDatabaseSeeder.php` | Master seeder entry point | ✅ |
| `DropdownSeeder.php` | Seeds `sys_dropdown_table` with platform lookup values | ✅ |
| `LanguageSeeder.php` | Seeds `glb_languages` with Indian + major world languages | ✅ |

**Missing Seeders:** No seeder for `glb_countries`, `glb_states`, `glb_districts`, `glb_boards`, `glb_academic_sessions`, `glb_modules`, `glb_menus` (pre-seeded data expected via migrations or manual SQL).

### 6.8 Migrations

| Migration File | Purpose | Status |
|---------------|---------|--------|
| 2025_10_06_112509_create_media_table.php | Creates media table | ✅ |
| 2025_10_18_085546_create_board_organization_table.php | Creates `sch_board_organization_jnt` | ✅ |
| 2025_10_18_101401_make_organization_academic_sessions_table.php | Creates academic sessions table | ✅ |
| 2025_10_21_091617_create_plans_table.php | Creates `prm_plans` | ✅ |
| 2025_10_21_094426_create_module_plan_table.php | Creates `prm_module_plan_jnt` | ✅ |
| 2025_11_02_071024_create_activity_logs_table.php | Creates `sys_activity_logs` | ✅ |

**Missing Migrations:** No migration to add `deleted_at`, `created_at`, `updated_at` to `glb_languages`. No migration to add `is_active` to `glb_academic_sessions`.

---

## 7. Form Request Validation Rules

### 7.1 CountryRequest

| Field | Rules | Notes |
|-------|-------|-------|
| name | `required|string|max:50|unique:glb_countries,name,{id},id` | Scoped unique ignore on update |
| short_name | `required|string|max:10` | |
| global_code | `nullable|string|max:10` | ISO alpha-2/3 |
| currency_code | `nullable|string|max:8` | e.g., INR, USD |
| default_timezone | `nullable|string|max:64` | |
| is_active | `required|boolean` | Preprocessed from checkbox 'on' → true |

### 7.2 StateRequest

| Field | Rules | Notes |
|-------|-------|-------|
| country_id | `required|exists:glb_countries,id` | |
| name | `required|string|max:50|unique:glb_states (scoped by country_id, ignore self)` | |
| short_name | `required|string|max:10` | |
| global_code | `nullable|string|max:10` | |
| default_timezone | `nullable|string|max:64` | |
| is_active | `required|boolean` | |

### 7.3 DistrictRequest

| Field | Rules | Notes |
|-------|-------|-------|
| state_id | `required|exists:glb_states,id` | |
| name | `required|string|max:50|unique:glb_districts (scoped by state_id, ignore self)` | |
| short_name | `required|string|max:10` | |
| global_code | `nullable|string|max:10` | |
| is_active | `required|boolean` | |

### 7.4 CityRequest

| Field | Rules | Notes |
|-------|-------|-------|
| district_id | `required|exists:glb_districts,id` | |
| name | `required|string|max:100` | |
| short_name | `required|string|max:20` | |
| global_code | `nullable|string|max:20` | |
| default_timezone | `nullable|string|max:64` | |
| is_active | `required|boolean` | |

### 7.5 BoardRequest

| Field | Rules | Notes |
|-------|-------|-------|
| name | `required|string|max:50|unique:glb_boards,name,{id},id` | |
| short_name | `required|string|max:10|unique:glb_boards,short_name,{id},id` | |
| is_active | `required|boolean` | |

### 7.6 AcademicSessionRequest

| Field | Rules | Issue |
|-------|-------|-------|
| name | `required|string|max:50|unique:glb_academic_sessions,name,{id},id` | |
| short_name | `required|string|max:20|unique:glb_academic_sessions,short_name,{id},id` | |
| start_date | **Missing** | ❌ BUG-005 — must add: `required|date|before:end_date` |
| end_date | **Missing** | ❌ BUG-005 — must add: `required|date|after:start_date` |
| is_current | **Missing** | Should add: `sometimes|boolean` |

### 7.7 LanguageRequest

| Field | Rules | Notes |
|-------|-------|-------|
| code | `required|string|max:10|unique:glb_languages,code,{id},id` | ISO 639-1 |
| name | `required|string|max:50` | |
| native_name | `nullable|string|max:50` | |
| direction | `required|in:LTR,RTL` | |
| is_active | `required|boolean` | |

### 7.8 ModuleRequest

| Field | Rules | Issues |
|-------|-------|-------|
| name | `required|string|max:50|unique:glb_modules,name,{id},id` | |
| menu_id | `required|array|min:1` | |
| menu_id.* | `integer|exists:glb_menus,id` | |
| version | `required|string|max:10` | |
| description | `nullable|string|max:500` | |
| is_core | `required|boolean` | |
| default_visible | `required|boolean` | |
| available_perm_view/add/edit/delete/export/import/print | `required|boolean` (×7) | |
| is_active | `required|boolean` | |
| is_sub_module | `nullable|string|max:50` | ❌ INC-06 — should be `nullable|boolean` |
| parent_id | Not validated | Gap — no validation for parent_id FK |

### 7.9 PlanRequest

| Field | Rules | Issues |
|-------|-------|-------|
| plan_code | `required|string|max:15|unique:prm_plans` | |
| name | `required|string|max:30|unique:prm_plans` | |
| version | `required|string|max:10` | |
| description | `nullable|string|max:255` | |
| billing_cycle_id | `required|exists:prm_billing_cycles,id` | |
| price_monthly | `nullable|numeric|between:0,9999999999.99` | |
| price_quarterly | **Missing** | ❌ 🆕 V2 — prm_plans DDL v2 adds price_quarterly |
| price_yearly | `nullable|numeric|between:0,9999999999.99` | |
| currency | `required|string|size:3` | |
| trial_days | `required|integer|min:1|max:30` | |
| features | `nullable|array` | |
| meta_data | `nullable|array` | |
| module_ids | `required|array|min:1` | At least 1 module per plan |
| module_ids.* | `integer|exists:glb_modules,id` | |
| is_active | `required|boolean` | |

### 7.10 DropdownRequest

| Field | Rules | Issues |
|-------|-------|-------|
| value | `required|string|max:255|unique:sys_dropdown_table (scoped by key)` | |
| is_active | `required|boolean` | |
| key | **Not validated** | ❌ DBM-010 — key must be required|string|regex slug |
| type | **Not validated** | ❌ DBM-010 — type must be required|in:String,Integer,Decimal,Date,Datetime,Time,Boolean |
| org_id | **Not validated** | ❌ DBM-010 — unclear if needed for central admin |

### 7.11 Required New Form Requests (V2)

| FormRequest | Purpose |
|-------------|---------|
| `TranslationRequest` | For FR-GLB-14 — validate `translatable_type`, `translatable_id`, `language_id`, `key`, `value` |
| `ToggleStatusRequest` | Extract inline `$request->validate()` from all 9 toggleStatus methods into shared FormRequest |

---

## 8. Business Rules

### 8.1 Geographic Hierarchy Rules

**BR-GLB-GEO-01:** Deactivating a country MUST cascade to all child states, all child districts, AND all child cities (4-level cascade) within a single DB transaction. Activating a country does NOT auto-activate children.

**BR-GLB-GEO-02:** A state cannot be activated if its parent country is inactive. A district cannot be activated if its parent state is inactive. A city cannot be activated if its parent district is inactive (city check currently missing — gap).

**BR-GLB-GEO-03:** Deletion is blocked (ON DELETE RESTRICT FK) for any geography record that has child records. Force-delete must catch the FK violation and return a user-friendly error.

**BR-GLB-GEO-04:** India-specific pre-seeding: platform pre-seeded with India (36 states/UTs, ~290 districts, major cities). Auto-increment values reflect this: countries AI=11, states AI=71, districts AI=290, cities AI=21.

**BR-GLB-GEO-05:** Activity log must be written AFTER all status-check guards pass, not before. A failed toggle should not produce a success activity log entry.

### 8.2 Academic Session Rules

**BR-GLB-SES-01:** Only one academic session can be `is_current = true` at any time. Enforced by MySQL generated column `current_flag` with UNIQUE constraint (NULLs excluded).

**BR-GLB-SES-02:** An active (is_active = true) academic session CANNOT be soft-deleted. Correct guard: `if ($academicSession->is_active === true) { return redirect()->back()->with('error', ...); }` (current code has inverted guard — BUG-004).

**BR-GLB-SES-03:** Indian school year runs April 1 to March 31. `start_date` must be before `end_date`; end_date must be after `start_date` (cross-field validation required in AcademicSessionRequest — BUG-005).

**BR-GLB-SES-04:** `glb_academic_sessions` has no `is_active` column — the `is_current` field serves as the active/current indicator. The `toggleStatus` method on the controller must be aligned with this DDL reality.

### 8.3 Educational Board Rules

**BR-GLB-BRD-01:** Standard pre-seeded Indian boards: CBSE, ICSE/ISC, IGCSE (Cambridge), IB (International Baccalaureate), NIOS, plus state boards for each state/UT.

**BR-GLB-BRD-02:** A board associated with tenant organizations via `sch_board_organization_jnt` cannot be force-deleted (FK RESTRICT).

### 8.4 Module Registry Rules

**BR-GLB-MOD-01:** `is_core = true` modules are included in all plans by default and cannot be deselected during plan creation.

**BR-GLB-MOD-02:** Sub-modules (`is_sub_module = true`) MUST have a `parent_id`. Top-level modules MUST have `parent_id = NULL`. Enforced by CHECK constraint `chk_isSubModule_parentId`.

**BR-GLB-MOD-03:** `available_perm_*` boolean flags define which permission types are applicable for a module in role management UI.

**BR-GLB-MOD-04:** Module versioning: unique on `(parent_id, name, version)`. A new version creates a new record, not an update to the existing one.

### 8.5 Plan and Billing Rules

**BR-GLB-PLN-01:** Every plan must include at least 1 module (`module_ids: required|array|min:1`).

**BR-GLB-PLN-02:** Plans support three price points: `price_monthly`, `price_quarterly` (v2 addition), and `price_yearly`. All nullable to support one-time/custom pricing.

**BR-GLB-PLN-03:** Currency must be a 3-character ISO 4217 code (default: INR).

**BR-GLB-PLN-04:** Trial days minimum 1, maximum 30 (validated in PlanRequest).

**BR-GLB-PLN-05:** Billing cycle lookup must be driven by `prm_billing_cycles` table, not a hardcoded array.

### 8.6 Dropdown Rules

**BR-GLB-DRP-01:** Dropdown keys are slugified using `Str::slug($key, '_')` on creation.

**BR-GLB-DRP-02:** Multiple values can be bulk-created by providing comma-separated values. Duplicates removed with `array_unique()` before insert.

**BR-GLB-DRP-03:** Ordinal is auto-incremented per `org_id` to maintain sort order within a key group.

**BR-GLB-DRP-04:** Dropdown types: String (default), Integer, Decimal, Date, Datetime, Time, Boolean.

### 8.7 Multilingual Support Rules

**BR-GLB-LANG-01:** `glb_translations` implements a polymorphic translation store. Any `glb_*` entity can have translated field values for any active language.

**BR-GLB-LANG-02:** `glb_translations.language_id` FK uses `ON DELETE CASCADE` — deleting a language deletes all its translations.

**BR-GLB-LANG-03:** Translation unique constraint `(translatable_type, translatable_id, language_id, key)` — one translation value per field per language per entity record.

**BR-GLB-LANG-04:** Language direction (LTR/RTL) supports Arabic, Urdu, and other RTL languages.

### 8.8 Authorization Rules

**BR-GLB-AUTH-01:** All public controller methods must call `Gate::authorize('prime.{entity}.{action}')` before executing business logic. No exceptions (including hub controllers and test utilities).

**BR-GLB-AUTH-02:** All permission strings must follow `prime.{entity}.{action}` pattern. Prefix `global-master.*` is deprecated and must be replaced.

**BR-GLB-AUTH-03:** `forceDelete` actions must use `prime.{entity}.forceDelete` permission, not `prime.{entity}.delete`.

### 8.9 Data Input Security Rules

**BR-GLB-SEC-01:** All `Model::create()` and `$model->update()` calls must use `$request->validated()`, never `$request->all()`.

**BR-GLB-SEC-02:** Search inputs used in LIKE queries must be sanitized/escaped to prevent DoS via crafted wildcard patterns.

**BR-GLB-SEC-03:** Rate limiting must be applied to public-facing search and AJAX endpoints.

---

## 9. Permission and Authorization Model

### 9.1 Standardized Permission Convention

All GlobalMaster permissions MUST follow: `prime.{entity}.{action}`

**Entities:** `country`, `state`, `district`, `city`, `module`, `plan`, `board`, `language`, `academic-session`, `dropdown`, `dropdown-need`, `activity-log`

**Actions:** `viewAny`, `view`, `create`, `update`, `delete`, `restore`, `forceDelete`

### 9.2 Full Permission Matrix

| Entity | Required Permission Strings |
|--------|---------------------------|
| Country | `prime.country.viewAny`, `prime.country.view`, `prime.country.create`, `prime.country.update`, `prime.country.delete`, `prime.country.restore`, `prime.country.forceDelete` |
| State | `prime.state.viewAny`, `prime.state.view`, `prime.state.create`, `prime.state.update`, `prime.state.delete`, `prime.state.restore`, `prime.state.forceDelete` |
| District | `prime.district.viewAny`, `prime.district.view`, `prime.district.create`, `prime.district.update`, `prime.district.delete`, `prime.district.restore`, `prime.district.forceDelete` |
| City | `prime.city.viewAny`, `prime.city.view`, `prime.city.create`, `prime.city.update`, `prime.city.delete`, `prime.city.restore`, `prime.city.forceDelete` |
| Module | `prime.module.viewAny`, `prime.module.view`, `prime.module.create`, `prime.module.update`, `prime.module.delete`, `prime.module.restore`, `prime.module.forceDelete` |
| Plan | `prime.plan.viewAny`, `prime.plan.view`, `prime.plan.create`, `prime.plan.update`, `prime.plan.delete`, `prime.plan.restore`, `prime.plan.forceDelete` |
| Board | `prime.board.viewAny`, `prime.board.view`, `prime.board.create`, `prime.board.update`, `prime.board.delete`, `prime.board.restore`, `prime.board.forceDelete` |
| Language | `prime.language.viewAny`, `prime.language.view`, `prime.language.create`, `prime.language.update`, `prime.language.delete`, `prime.language.restore`, `prime.language.forceDelete` |
| Academic Session | `prime.academic-session.viewAny`, `prime.academic-session.view`, `prime.academic-session.create`, `prime.academic-session.update`, `prime.academic-session.delete`, `prime.academic-session.restore`, `prime.academic-session.forceDelete` |
| Activity Log | `prime.activity-log.viewAny` (read-only; no create/update/delete) |
| Dropdown | `prime.dropdown.viewAny`, `prime.dropdown.view`, `prime.dropdown.create`, `prime.dropdown.update`, `prime.dropdown.delete`, `prime.dropdown.restore`, `prime.dropdown.forceDelete` |
| Dropdown Need | `prime.dropdown-need.viewAny`, `prime.dropdown-need.view`, `prime.dropdown-need.create`, `prime.dropdown-need.update`, `prime.dropdown-need.delete`, `prime.dropdown-need.restore`, `prime.dropdown-need.forceDelete` |
| Translation | `prime.translation.viewAny`, `prime.translation.create`, `prime.translation.update`, `prime.translation.delete` |

### 9.3 Current Authorization Gaps

| Controller | Methods Lacking Gate | Bug Reference |
|-----------|---------------------|---------------|
| LanguageController | create(), store(), edit(), update() | AUTH-001 |
| GlobalMasterController | ALL 7 methods | AUTH-003 |
| OrganizationController | ALL 7 methods | AUTH-004 |
| GeographySetupController | create(), store(), show(), edit(), update(), destroy() | AUTH-002 |
| SessionBoardSetupController | create(), store(), show(), edit(), update(), destroy() | AUTH-005 |
| NotificationController | testNotification(), allNotifications() | AUTH-006 |
| PlanController | planDetails() | AUTH-008 |
| ActivityLogController | store(), show(), edit(), update(), destroy() (stub methods with dead Gate checks) | AUTH-007 |

### 9.4 Authorization Method Pattern

```php
// Correct pattern used in working controllers:
Gate::authorize('prime.country.create');

// Hub pattern (Gate::any):
Gate::any(['prime.country.viewAny', 'prime.state.viewAny', ...]);

// Incorrect patterns to fix:
Gate::authorize('global-master.academic-session.create');  // Wrong prefix
Gate::authorize('prime.module.create');  // Wrong action (in show() method)
Gate::authorize('prime.district.delete');  // Wrong action (in forceDelete() method)
```

---

## 10. Tests Inventory

### 10.1 Current Test Files

| File | Type | Framework | Tests | Quality |
|------|------|-----------|-------|---------|
| `tests/Unit/BoardTest.php` | Unit | PHPUnit class | 2 | Trivial — `true === true` + in-memory model |

**Test Score: 2/10** — Only 1 test file with 2 trivial tests. Both use stale import `App\Models\V1\GlobalMaster\Board`.

### 10.2 Required Test Coverage (V2)

#### Feature Tests (None Exist — All Required)

| Test Class | Covers | Priority |
|------------|--------|----------|
| `CountryControllerTest` | CRUD routes, auth gates, cascade toggle, activity log | P1 |
| `StateControllerTest` | CRUD, parent-check toggle, getStatesByCountry | P1 |
| `DistrictControllerTest` | CRUD, unique scoping, forceDelete permission fix | P1 |
| `CityControllerTest` | CRUD, parent-check gap, route model binding | P1 |
| `ModuleControllerTest` | CRUD, show() permission fix, menu sync | P1 |
| `PlanControllerTest` | CRUD, module assignment, planDetails auth | P1 |
| `LanguageControllerTest` | CRUD, missing Gate checks, model import | P0 |
| `AcademicSessionControllerTest` | CRUD, destroy guard, date validation | P0 |
| `DropdownControllerTest` | CRUD, bulk create, N+1 fix | P1 |
| `ActivityLogControllerTest` | Index only (read-only), filter, export | P2 |

#### Unit Tests (None Exist — All Required)

| Test Class | Covers | Priority |
|------------|--------|----------|
| `CountryCascadeTest` | Toggle cascade includes cities (BUG-010) | P0 |
| `AcademicSessionDestroyTest` | Inverted guard fix (BUG-004) | P0 |
| `GeographyHierarchyTest` | Parent-status checks at each level | P1 |
| `ModulePermissionFlagTest` | available_perm_* flags in model casts | P1 |
| `PlanModuleAssignmentTest` | Minimum 1 module, core module enforcement | P1 |
| `DropdownBulkCreateTest` | Comma-split, dedup, slugify | P1 |
| `ToggleStatusLogOrderTest` | Log written after guard passes (SEC-006) | P1 |

#### FormRequest Validation Tests (None Exist)

| Test Class | Covers | Priority |
|------------|--------|----------|
| `AcademicSessionRequestTest` | start_date/end_date cross-field validation | P0 |
| `DropdownRequestTest` | key, type, org_id validation (currently missing) | P1 |
| `ModuleRequestTest` | is_sub_module boolean type | P1 |
| `PlanRequestTest` | module_ids min:1, price_quarterly (v2) | P1 |

### 10.3 Test Infrastructure Notes

- Test framework: Pest PHP (as used in other Prime-AI modules)
- Feature tests extend `Tests\TestCase` with `RefreshDatabase` trait
- Unit tests use in-memory models (no DB) where possible
- Separate test DB connections needed: `global_master_mysql_test` and `prime_test`

---

## 11. Known Issues and Technical Debt

### 11.1 Critical Issues (P0 — Fix Before Any Deployment)

| ID | File | Method(s) | Issue | Fix |
|----|------|-----------|-------|-----|
| SEC-001/BUG-001 | Country/State/City/Module/Plan/AcademicSession Controllers | store(), update() | `$request->all()` — mass-assignment vulnerability (12 occurrences) | Replace with `$request->validated()` |
| AUTH-001 | LanguageController | create(), store(), edit(), update() | No Gate::authorize() — any auth user can create/edit languages | Add `Gate::authorize('prime.language.{action}')` |
| BUG-004 | AcademicSessionController | destroy() | Inverted is_active guard — active sessions CAN be deleted | Change to `if ($academicSession->is_active === true)` |
| AUTH-003 | GlobalMasterController | ALL methods | Zero auth — any auth user has full access | Add Gate checks or remove controller |
| AUTH-004 | OrganizationController | ALL methods | Zero auth — any auth user has full access | Add Gate checks or remove controller |
| BUG-006 | AcademicSession/LanguageController | multiple | Mixed `prime.*` and `global-master.*` Gate prefixes — permission system inconsistency | Standardize to `prime.*` |
| MF-001 | AcademicSessionController | ALL methods | Imports `Modules\GlobalMaster\Models\AcademicSession` which does not exist — runtime fatal | Create model in GlobalMaster or fix import to Prime |
| AUTH-008 | PlanController | planDetails() | planDetails AJAX endpoint has no Gate check | Add `Gate::authorize('prime.plan.view')` |

### 11.2 High Priority Issues (P1 — Fix Before Release)

| ID | File | Issue | Fix |
|----|------|-------|-----|
| BUG-002 | StateController::update() | Duplicate activityLog() call (lines 95+109) | Remove duplicate |
| BUG-003 | ModuleController::update() | Duplicate activityLog() call (lines 113+127) | Remove duplicate |
| BUG-005 | AcademicSessionRequest | Missing start_date, end_date validation rules | Add date validation with cross-field before/after |
| BUG-007 | LanguageController | Imports `Modules\Prime\Models\Language` — wrong module | Fix to `Modules\GlobalMaster\Models\Language` |
| BUG-008 | GlobalMaster/Models/ root | Duplicate `Dropdown.php` at non-standard location | Remove root-level copy |
| BUG-010 | CountryController::toggleStatus() | Cascade does not include cities | Add city cascade in DB transaction |
| DBM-002 | glb_languages DDL | Missing created_at, updated_at, deleted_at | Migration to add columns |
| DBM-004 | Country model | Missing `$connection = 'global_master_mysql'` | Add $connection property |
| DBM-005 | Country model | Missing `$casts` for `is_active` | Add $casts array |
| RT-001 | routes/web.php | Triplicated `global-master` route groups (3x) | Consolidate into one group |
| RT-004 | StateController | Route references `getStatesByCountry()` which does not exist | Implement method |

### 11.3 Medium Priority Issues (P2 — Next Sprint)

| ID | Issue | Fix |
|----|-------|-----|
| ARCH-001 | No service layer — all business logic in controllers | Extract GeographyService, ModulePlanService, DropdownService |
| PERF-001 | N+1 query in DropdownController::index() | Use groupBy or eager loading |
| PERF-002 | Unbounded query in GeographySetupController | Add pagination |
| PERF-003 | StateController::index() loads all countries unbounded | Add pagination |
| PERF-006 | No caching for static reference data | Implement Redis cache with TTL |
| DBM-001 | All `glb_*` tables missing `created_by` column | Migration to add created_by |
| DBM-003 | `glb_academic_sessions` missing `is_active` column | Migration to add is_active |
| MF-003 | Translation management not implemented | Create model, controller, views, routes |
| RT-003 | Module's own routes/web.php is empty | Move routes from root web.php |
| RT-005 | ActivityLogController missing `search()` | Implement or remove route |
| RT-006 | DropdownController missing `search()` | Implement or remove route |
| INC-06 | ModuleRequest::is_sub_module wrong type | Change to nullable|boolean |
| INC-07 | DDL `glb_menu_model_jnt` vs code `glb_menu_module_jnt` | Reconcile names |
| SEC-006 | Activity log written before status check | Reorder logic |
| SEC-005 | No rate limiting on search endpoints | Add throttle middleware |
| BUG-009 | DropdownController uses user ID as org_id | Fix org_id logic |
| TEST-001 | Only 1 trivial test file | Write comprehensive test suite |
| BUG-002/003 | Wrong permission on ModuleController::show() | Fix to prime.module.view |

### 11.4 Low Priority Issues (P3 — Technical Debt)

| ID | Issue |
|----|-------|
| ARCH-002 | Stale V1 imports in CountryController (`App\Models\V1\GlobalMaster\District`, `State`) |
| ARCH-003 | Cross-module model dependencies without interfaces |
| ARCH-005 | Backup files in repository (`.bk`, `.bkk` files) |
| DBM-006 | ActivityLog model — project standard requires SoftDeletes |
| DBM-007 | Media model is an empty shell with no purpose |
| DBM-009 | Module.php hardcodes `prime_db.` database prefix in pivot |
| DBM-010 | DropdownRequest references non-existent fields (table_name, column_name) |
| SEC-001 | LIKE queries — sanitize search inputs against DoS patterns |
| INC-05 | LanguageController paginates 11/page — should be 10 |
| INC-08 | Language model declares SoftDeletes but DDL lacks deleted_at |
| INC-09 | GlobalMasterController, OrganizationController, NotificationController are zero-auth shells |

---

## 12. API Endpoints

### 12.1 Current API State

Only `GlobalMasterController` is exposed via API, which is a pure stub with empty bodies.

```
Route:     /api/v1/globalmasters
Auth:      auth:sanctum
Resources: GET / POST / GET {id} / PUT {id} / DELETE {id}
File:      Modules/GlobalMaster/routes/api.php
Status:    All methods return empty (stubs)
```

### 12.2 Required REST API Endpoints (Pending)

These endpoints are needed for tenant apps to consume GlobalMaster reference data:

| Endpoint | Method | Auth | Purpose | Priority |
|----------|--------|------|---------|----------|
| `/api/v1/countries` | GET | `auth:sanctum` | List active countries | P1 |
| `/api/v1/countries/{id}/states` | GET | `auth:sanctum` | Get states by country for dependent dropdowns | P1 |
| `/api/v1/states/{id}/districts` | GET | `auth:sanctum` | Get districts by state | P1 |
| `/api/v1/districts/{id}/cities` | GET | `auth:sanctum` | Get cities by district | P1 |
| `/api/v1/boards` | GET | `auth:sanctum` | List active educational boards | P1 |
| `/api/v1/academic-sessions` | GET | `auth:sanctum` | List all academic sessions | P1 |
| `/api/v1/academic-sessions/current` | GET | `auth:sanctum` | Get current academic session | P0 |
| `/api/v1/languages` | GET | `auth:sanctum` | List active languages | P1 |
| `/api/v1/dropdowns/{key}` | GET | `auth:sanctum` | Get dropdown values by key | P1 |
| `/api/v1/modules` | GET | `auth:sanctum` | List active modules (for plan display) | P2 |
| `/api/v1/translations/{type}/{id}` | GET | `auth:sanctum` | Get all translations for a specific record | P2 |

### 12.3 API Response Format Standard

```json
{
  "success": true,
  "data": { ... },
  "message": "Optional message"
}
```

Error response:
```json
{
  "success": false,
  "message": "Error description",
  "errors": { ... }
}
```

---

## 13. Non-Functional Requirements

### 13.1 Performance Requirements

| Requirement | Target | Current State |
|-------------|--------|---------------|
| Geography list load time | < 500ms | Unbounded queries — no baseline |
| States by country AJAX | < 200ms | Missing method (RT-004) |
| Plan/Module list | < 300ms | No caching |
| Search response | < 300ms | No rate limiting |
| Activity log pagination | < 400ms | No filter indexes |

**NFR-GLB-PERF-01:** Country, state, and district lists accessed by tenant forms must be cached (Redis, 1-hour TTL). Cache must be invalidated on any create/update/toggle/delete operation.

**NFR-GLB-PERF-02:** `GeographySetupController::index()` must not load all countries+states+districts into memory. Use paginated queries with eager-loading only for visible page records.

**NFR-GLB-PERF-03:** `DropdownController::index()` must fix the N+1 query pattern. Use a single query with `groupBy` or `groupBy` + `count()` + separate keyed queries on demand.

**NFR-GLB-PERF-04:** `CityController::index()` 4-level deep eager loading must be paginated — never load all cities with relationships at once.

### 13.2 Data Integrity Requirements

**NFR-GLB-DI-01:** All FK constraints use `ON DELETE RESTRICT` — no orphan records can be created by normal CRUD operations.

**NFR-GLB-DI-02:** Soft deletes (`deleted_at`) must be used on all `glb_*` entities. Physical deletion only via `forceDelete` with authorization.

**NFR-GLB-DI-03:** The `current_flag` generated column provides MySQL-level uniqueness guarantee for active academic session — no application-level workaround is needed or permitted.

**NFR-GLB-DI-04:** Geographic cascade (deactivation) must execute within a single `DB::beginTransaction()` block. If any step fails, the entire cascade rolls back.

**NFR-GLB-DI-05:** All `glb_*` tables must have `created_at`, `updated_at`, `deleted_at`, and `is_active` columns (standard platform convention). Missing columns must be added via migration.

### 13.3 Security Requirements

**NFR-GLB-SEC-01:** All 12 `$request->all()` occurrences must be replaced with `$request->validated()`. No exceptions.

**NFR-GLB-SEC-02:** All controller methods must call `Gate::authorize()` before executing any business logic. Stub methods that cannot be secured must be removed.

**NFR-GLB-SEC-03:** `forceDelete` operations must use the `prime.{entity}.forceDelete` permission, not the `delete` permission.

**NFR-GLB-SEC-04:** Search inputs used in LIKE queries must be validated/escaped. Add `preg_replace('/[%_\\\\]/', '\\\\$0', $search)` or equivalent before interpolation.

**NFR-GLB-SEC-05:** Rate limiting must be applied to all search endpoints: `throttle:60,1` (60 requests per minute per user).

**NFR-GLB-SEC-06:** CSRF protection is provided by web middleware group — toggle endpoints (POST) are covered. No additional action needed.

### 13.4 Auditability Requirements

**NFR-GLB-AUDIT-01:** All state changes (Create/Update/Trash/Restore/Delete/Toggle) on geographic entities, modules, plans, languages, boards, and dropdowns must be recorded via `activityLog()`.

**NFR-GLB-AUDIT-02:** Activity log entries must include: subject model class + ID, event type, user ID, changed attributes (old vs. new values).

**NFR-GLB-AUDIT-03:** Activity logs must be append-only from the UI — no edit or delete actions exposed to any role.

**NFR-GLB-AUDIT-04:** Activity log must be written AFTER all business rule guards pass. A failed operation must not produce a success log entry.

### 13.5 Architecture Requirements

**NFR-GLB-ARCH-01:** All reusable business logic must be extracted to service classes: `GeographyService`, `ModulePlanService`, `DropdownService`, `TranslationService`.

**NFR-GLB-ARCH-02:** All GlobalMaster routes must be defined in `Modules/GlobalMaster/routes/web.php`, not in the root `routes/web.php`.

**NFR-GLB-ARCH-03:** Cross-module model references must be minimized. When required (e.g., `Board` → `Organization`), the reference must be documented here.

**NFR-GLB-ARCH-04:** All Eloquent models in GlobalMaster that access `global_db` must explicitly declare `protected $connection = 'global_master_mysql'`.

**NFR-GLB-ARCH-05:** Backup files (`.bk`, `.bkk`) must be removed from the repository.

---

## 14. Future Enhancements (Suggestions Only)

This section contains suggestions only. None of these items are required for V2 completion.

### 14.1 Bulk Import via CSV

Allow Super Admin to import countries, states, districts, cities, boards, and languages via CSV upload. Useful for new country additions and bulk seeding.

### 14.2 Translation Management UI

Once `TranslationService` (FR-GLB-14) is implemented, a translation management dashboard could allow translating any `glb_*` entity field (e.g., board names in regional languages).

### 14.3 Geographic Hierarchy Visualization

A tree-view or map-based visualization of the country > state > district > city hierarchy would improve usability for the support team.

### 14.4 Module Dependency Graph

A visual dependency graph showing which modules are core, which are optional, and their inter-dependencies would assist in plan configuration.

### 14.5 Plan Comparison Matrix

A plan comparison table view showing all plans side-by-side with their included modules and pricing would assist the sales team during tenant onboarding.

### 14.6 Automated Session Rollover

An automated task (Laravel scheduled command) that creates the next academic session (e.g., creates "2026-27" when "2025-26" ends) and marks it as current.

### 14.7 API Rate Limiting Dashboard

Dashboard showing API usage statistics per tenant for the geographic and reference data APIs, helping identify abuse patterns.

---

## 15. Integration Points

### 15.1 Modules That Consume GlobalMaster Data

| Consumer Module | Data Consumed | Mechanism |
|-----------------|---------------|-----------|
| SchoolSetup | `glb_countries`, `glb_states`, `glb_districts`, `glb_cities` | Direct FK in `sch_organization_groups` |
| SchoolSetup | `glb_boards` | Many-to-many via `sch_board_organization_jnt` |
| Prime (Tenant Onboarding) | `glb_academic_sessions`, `prm_plans`, `glb_modules` | FK references in tenant creation wizard |
| Billing | `prm_plans` | Plan → `prm_tenant_plan_jnt` → Invoice chain |
| All Tenant Modules | `sys_dropdown_table` | Direct query by key |
| Auth / UserManagement | `glb_modules`, `glb_menus` | Permission and menu rendering |
| All Modules | `sys_activity_logs` | Write via `activityLog()` helper function |
| StudentProfile | `glb_cities` | City FK in student detail |
| Any i18n-aware module | `glb_translations`, `glb_languages` | Polymorphic translation lookup |

### 15.2 Database Connections

```
global_master_mysql  →  global_db       Country, State, District, City, Board, Language, Module, Menu, Translations
default (prime_db)   →  prime_db        Plan (prm_plans), Dropdown (sys_dropdown_table), ActivityLog (sys_activity_logs)
```

**Important:** `Module.php` sets `$connection = 'global_master_mysql'` but the `Plan` model's `belongsToMany(Module::class)` pivot `prime_db.glb_module_plan_jnt` crosses database boundaries. This cross-DB relationship requires the `prime_db.glb_module_plan_jnt` table to reference `glb_modules` via a VIEW in prime_db.

### 15.3 activityLog() Helper Dependency

```php
// File: /app/Helpers/activityLog.php
use Modules\GlobalMaster\Models\ActivityLog;  // ARCH-006: tight coupling
```

All modules depend on this helper for audit logging. The GlobalMaster `ActivityLog` model is the central write target. This coupling means GlobalMaster must always be present and its ActivityLog model must remain stable.

### 15.4 External Package Dependencies

| Package | Version | Usage |
|---------|---------|-------|
| spatie/laravel-permission | v6.21 | RBAC — `Gate::authorize()` and string permissions |
| nwidart/laravel-modules | v12.0 | Module architecture and loading |
| stancl/tenancy | v3.9 | Central domain routing, prevents tenant routes conflict |
| Bootstrap 5 + AdminLTE 4 | — | Frontend layout and components |
| MySQL 8.x | — | Generated columns, CHECK constraints |

---

## 16. V2 Change Summary vs V1

### 16.1 New Functional Requirements Added in V2

| FR ID | Description | Source |
|-------|-------------|--------|
| FR-GLB-01.10–13 | Country cascade fix, FK error handling, model connection/casts, stale imports | BUG-010, SEC-007, DBM-004/005, ARCH-002 |
| FR-GLB-02.8–12 | Duplicate log fix, request validation fix, log ordering, missing method, unbounded query | BUG-002, BUG-001, SEC-006, RT-004, PERF-003 |
| FR-GLB-04.8–9 | City parent check, 4-level eager load optimization | Gap vs State/District, PERF-005 |
| FR-GLB-05.6–9 | Geography hub stubs auth, rate limiting, unbounded load, LIKE injection | AUTH-002, SEC-005, PERF-002, SEC-001 |
| FR-GLB-06.6–8 | Dedicated BoardController, board routes, SessionBoardSetup stubs | MF-002, AUTH-005 |
| FR-GLB-07.6–11 | Missing AcademicSession model, inverted destroy guard, date validation, request all, gate prefix, DDL is_active | MF-001, BUG-004, BUG-005, BUG-001, BUG-006, DBM-003 |
| FR-GLB-08.5–10 | 4 missing Gate checks, wrong model import, wrong log event, gate prefix, DDL timestamps, pagination | AUTH-001, BUG-007, V1 bug, BUG-006, MF-005/DBM-002, INC-05 |
| FR-GLB-09.8–15 | request all, show perm, show view, duplicate log, is_sub_module type, table name mismatch, DB prefix, sub-module UI | BUG-001/003, BUG-002, INC-06, INC-07, DBM-009 |
| FR-GLB-10.9–13 | request all, planDetails auth, show stub, price_quarterly, billing cycles from DB | BUG-001, AUTH-008, V2 DDL, BR-PLN-05 |
| FR-GLB-11.7–13 | Dropdown validation, N+1, org_id semantics, stale field refs, missing search, duplicate model, backup files | DBM-010, PERF-001, BUG-009, RT-006, BUG-008, ARCH-005 |
| FR-GLB-12.3–6 | Log filters, CSV export, stub cleanup, missing search | V1 pending, AUTH-007, RT-005 |
| FR-GLB-14 | Translation Management (entirely new sub-module) | MF-003 |
| FR-GLB-15 | Service Layer (architecture requirement) | ARCH-001 |
| FR-GLB-16 | Route Consolidation (architecture requirement) | RT-001/003 |
| FR-GLB-17 | Reference Data Caching | PERF-006 |

### 16.2 V2 Gap Analysis Coverage

| Gap Analysis Category | Total Gaps | Covered in V2 FRs |
|----------------------|------------|-------------------|
| Missing Features (MF) | 5 | 5/5 ✅ |
| Bugs (BUG) | 11 | 11/11 ✅ |
| Security Issues (SEC) | 8 | 7/8 ✅ (SEC-004 out of scope) |
| Performance Issues (PERF) | 6 | 6/6 ✅ |
| Authorization Gaps (AUTH) | 8 | 8/8 ✅ |
| DB/Model Mismatches (DBM) | 10 | 10/10 ✅ |
| Route Issues (RT) | 7 | 6/7 ✅ (RT-002, RT-007 are Scheduler module) |
| Architecture Violations (ARCH) | 6 | 5/6 ✅ |
| **Total** | **47** | **44/47** |

### 16.3 Module Completion Assessment

| Area | V1 Status | V2 Target | Effort Estimate |
|------|-----------|-----------|----------------|
| Security (request->all fixes) | 0% | 100% | 1h |
| Authorization gaps | 50% | 100% | 2h |
| Logic bugs (destroy guard, duplicate logs) | 0% | 100% | 1h |
| Form request completion | 70% | 100% | 1h |
| Route consolidation | 0% | 100% | 2h |
| Service layer | 0% | 100% | 4h |
| Translation management | 0% | 100% | 8h |
| Test coverage | 2% | 80% | 16h |
| DDL/model fixes | 0% | 100% | 3h |
| Caching | 0% | 100% | 2h |
| **Overall GLB** | **~55%** | **~90%** | **~40h** |

---

*Document generated: 2026-03-26 | Based on V1 baseline + 2026-03-22 deep audit of 47 gaps | All gap references verified against code*
