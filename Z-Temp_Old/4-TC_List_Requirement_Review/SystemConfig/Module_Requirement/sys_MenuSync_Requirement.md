# SystemConfig — Menu Synchronisation

**Feature:** Menu Synchronisation | **REQ-ID:** REQ-SYS-007 | **Priority:** P0 (MUST)

---

## 1. Description

The Menu Synchronisation feature enables a Super Admin to synchronise navigation menu definitions from code into the `glb_menus` database. The sync process **truncates all tenant menus** and re-creates them from the master definition array defined in `MenuSyncController::getMenuDefinitions()`. It also re-seeds menu↔module links via `glb_menu_module_jnt`. A companion `refreshCache` method clears application cache, compiled views, and all tenant menu caches.

---

## 2. Controller & Model

| Artifact | Path | Lines | Status |
|----------|------|:-----:|--------|
| Controller | `Modules/SystemConfig/app/Http/Controllers/MenuSyncController.php` | 2,760 | PARTIAL (oversized) |
| Model | `Modules/SystemConfig/app/Models/Menu.php` | 98 | ✅ |

---

## 3. Routes

| Method | URI | Action | Permission | Status |
|--------|-----|--------|------------|--------|
| GET | `/system-config/sync-menus` | `sync` | `system-config.menu.sync` | ✅ |
| GET | `/system-config/sync-prime-menus` | `syncPrime` | `system-config.menu.sync` | ✅ |
| GET | `/system-config/refresh-menu-cache` | `refreshCache` | — | ✅ |
| GET | `/system-config/refresh-menu-cache` (tenant) | `refreshTenantMenuCache` | — | ✅ |

Route registration: Central routes in `Modules/SystemConfig/routes/web.php` + tenant route in `routes/tenant.php`.

---

## 4. Controller Implementation Details

### 4.1 `sync()` — Tenant Menu Sync

**Gate:** `Gate::authorize('system-config.menu.sync')` — **WAS commented out; now restored**

**Flow:**

1. **Authorization** — Gate check for `system-config.menu.sync`
2. **Get Definitions** — `$this->getMenuDefinitions()` returns a 15-category master menu array (~2,500 lines of definition data) containing all tenant-side navigation items
3. **Truncate & Reset** — Sets `FOREIGN_KEY_CHECKS=0`, truncates `glb_menu_module_jnt` pivot table, force-deletes all menus where `menu_for='tenant'`
4. **Re-create** — Iterates each category and recursively creates menu items via `syncMenu()`
5. **Seed Module Links** — `seedMenuModuleLinks()` maps each top-level menu code to a module name; creates modules if needed via `Module::firstOrCreate()`; collects all descendant IDs; bulk inserts into `glb_menu_module_jnt`
6. **Clear Caches** — Iterates all tenants and calls `clearAllowedModulesCache()`
7. **Response** — Returns JSON with `created`, `updated`, `unchanged` counts, `menu_tree`, and `menu_module_links` count

**Critical Behaviours:**

| Behaviour | Detail |
|-----------|--------|
| Destructive | Truncates all tenant menus before re-creation — no partial sync |
| Legacy codes | `$legacyCodesToDelete` array (60 codes) lists renamed/removed menu codes from previous versions — but since truncation happens first, this array is effectively unused at runtime |
| Menu↔Module map | `getMenuModuleMap()` defines 18 modules; uses `firstOrCreate` for idempotent module creation |
| Recursive descendant collection | `collectDescendantIds()` walks the tree to link every menu item to its module |
| Execution timeout | `set_time_limit(300)` — 5 minutes for large installations |

### 4.2 `syncPrime()` — Prime Panel Menu Sync

**Gate:** Same as `sync()` — `system-config.menu.sync`

**Flow:**
1. Truncates all menus where `menu_for='prime'`
2. Re-creates from `getPrimeMenuDefinitions()` (5 categories: Foundation Setup, Core Configuration, Tenant Management, Messaging & Communication, Support & Maintenance)
3. Clears `prime_main_menus_tree` cache key
4. Returns JSON with created count and menu tree

### 4.3 `refreshCache()` — Application-wide Cache Clear

| Step | Command |
|------|---------|
| 1 | `Artisan::call('cache:clear')` — Clears Laravel application cache |
| 2 | `Artisan::call('view:clear')` — Clears compiled Blade views |
| 3 | Clears all tenant `allowed_modules` cache keys |
| 4 | Clears `tenant_main_menus_tree_{$id}` cache for each tenant |
| 5 | Clears `tenant_main_menus_tree` and `prime_main_menus_tree` global cache keys |

### 4.4 `refreshTenantMenuCache()` — Tenant-scoped Cache Clear

- Available from tenant domain
- Clears the current tenant's `allowed_modules`, `menu_cache`, and `tenant_main_menus_tree_{$id}` cache

---

## 5. Master Menu Definitions

### 5.1 Tenant Menu Categories (18 total)

| # | Category | Module | Code |
|---|----------|--------|------|
| 1 | Foundational Setup | Foundational Setup | `foundational_setup` |
| 2 | Core Configuration | Core Configuration | `core_configuration` |
| 3 | School Setup | School Setup | `school_setup` |
| 4 | Student Mgmt. | Student Mgmt. | `student_mgmt` |
| 5 | Staff Management | Staff Mgmt. | `staff_mgmt` |
| 6 | Finance | Finance | `finance` |
| 7 | Operations | Operations | `operations` |
| 8 | LMS | — | `lms` |
| 9 | Exam & Assessment | Exam & Assessment | `exam_assessment` |
| 10 | Academic Management | Academic Management | `academic_management` |
| 11 | Communication Mgmt. | Communication Mgmt. | `communication_mgmt` |
| 12 | Timetable Mgmt. | Timetable Mgmt. | `timetable_mgmt` |
| 13 | FrontDesk Mgmt. | FrontDesk Mgmt. | `front_desk_mgmt` |
| 14 | Support & Maintenance | Support & Maintenance | `support_and_maintenance` |
| 15 | Portal | Portal | `portal` |
| 16 | Others | Others | `others` |
| 17 | Behavioural Assessment | — | `behavioural_assessment` |
| 18 | HR & Payroll | — | `hr_payroll_management` |

### 5.2 Prime Menu Categories (5 total)

| # | Category | Code |
|---|----------|------|
| 1 | Foundation Setup | `foundation_setup` |
| 2 | Core Configuration | `core_configuration` |
| 3 | Tenant Management | `tenant_management` |
| 4 | Messaging & Communication | `messaging_communication` |
| 5 | Support & Maintenance | `support_maintenance` |

---

## 6. Business Rules

| BR-ID | Rule | Implementation | Status |
|-------|------|---------------|:------:|
| BR-SYS-011 | Menu Sync is Super Admin only; permission must never be commented out | ✅ Gate check present (`system-config.menu.sync`) | ✅ Fixed |
| BR-SYS-012 | Every mutation must produce audit log entry | Sync is a GET endpoint — no audit log call in `sync()` or `syncPrime()` | ❌ Missing |

---

## 7. Security Rules

| Rule | Implementation | Status |
|------|---------------|:------:|
| Sync requires `system-config.menu.sync` permission | `Gate::authorize()` in `sync()` and `syncPrime()` | ✅ |
| No auth bypass possible | Auth is enforced via route middleware + Gate | ✅ |
| No `$request->all()` used | Controllers use no user request data for DB mutation | ✅ |
| Cache refresh does not require permission | `refreshCache()` has no Gate check — any authenticated user can trigger | ❌ Missing |

---

## 8. Gaps & Known Issues

| # | Issue | Impact | Severity | Status |
|---|-------|--------|:--------:|:------:|
| 1 | Controller is 2,760 lines — violates Single Responsibility Principle (SRP) | Maintainability, testability | High | ⬜ |
| 2 | No transaction wrapping — if sync fails mid-way, DB is left in partially truncated state | Data integrity | Critical | ⬜ |
| 3 | `$legacyCodesToDelete` array (60 entries) is unused — truncation happens first | Dead code | Low | ⬜ |
| 4 | `refreshCache()` has no permission check — any authenticated user can trigger it | Security | Medium | ⬜ |
| 5 | No audit log call in `sync()` or `syncPrime()` — violates BR-SYS-012 | Audit compliance | Medium | ⬜ |
| 6 | No confirmation prompt before destructive truncate — user could trigger by accident | Usability | Medium | ⬜ |
| 7 | Hardcoded `FOREIGN_KEY_CHECKS=0` — risky if other processes write to `glb_menus` simultaneously | Concurrency | Medium | ⬜ |
| 8 | No feature tests for sync or cache refresh | Testing gap | High | ⬜ |

---

## 9. FRD References

| Reference | Source | Summary |
|-----------|--------|---------|
| REQ-SYS-007 | FRD §2 | Menu Synchronisation |
| BR-SYS-011 | FRD §4 | Super Admin only; permission must never be commented out |
| BR-SYS-012 | FRD §4 | Audit log requirement |
| US-SYS-007 | FRD §8 | User story for menu sync |
| WF-2 | FRD §6 | Menu Sync workflow |

---

## 10. Change Log

| Version | Date | Author | Description |
|---------|------|--------|-------------|
| V1 | — | — | — |
| V2 | — | — | — |
