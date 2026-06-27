# StandardTimetable Module -- Deep Gap Analysis Report

**Date:** 2026-03-22
**Branch:** Brijesh_SmartTimetable
**Auditor:** Senior Laravel Architect (AI)
**Module Path:** `/Users/bkwork/Herd/prime_ai/Modules/StandardTimetable/`

---

## EXECUTIVE SUMMARY

| Metric | Count |
|---|---|
| DDL Tables (tt_*) | 0 (shares with SmartTimetable) |
| Controllers | 1 |
| Models | 0 |
| Services | 0 |
| FormRequests | 0 |
| Policies | 0 |
| Views (blade) | 3 |
| Tests | 0 |
| Routes | 0 (empty group) |

### Scorecard

| Category | Score | Grade |
|---|---|---|
| DB Integrity | N/A | N/A |
| Route Integrity | 0% | F |
| Controller Audit | 15% | F |
| Model Audit | 0% | F |
| Service Audit | 0% | F |
| FormRequest Audit | 0% | F |
| Policy/Auth Audit | 10% | F |
| Security Audit | 10% | F |
| Performance Audit | N/A | N/A |
| Architecture Audit | 10% | F |
| Test Coverage | 0% | F |
| **Overall** | **~5%** | **F** |

---

## SECTION 1: DATABASE INTEGRITY

StandardTimetable shares the `tt_*` table prefix with SmartTimetable. No dedicated tables exist for this module. The module is designed to provide a simpler manual-placement workflow using the same underlying database schema as SmartTimetable.

---

## SECTION 2: ROUTE INTEGRITY

### 2.1 Routes Defined
**File:** `/Users/bkwork/Herd/prime_ai/routes/tenant.php`, lines 2210-2212

```php
Route::middleware(['auth', 'verified'])->prefix('standard-timetable')->name('standard-timetable.')->group(function () {
    // COMPLETELY EMPTY
});
```

### 2.2 Issues
- **GAP-RT-001 (CRITICAL):** The route group is **completely empty**. Zero routes are registered. The module is inaccessible via routing.
- **GAP-RT-002:** `StandardTimetableController` is imported at `tenant.php:164` but never used in any route definition.
- **GAP-RT-003:** No `EnsureTenantHasModule` middleware applied.
- **GAP-RT-004:** The `StandardTimetable/routes/web.php` and `StandardTimetable/routes/api.php` files exist but are not loaded by the RouteServiceProvider (routes are defined in global `tenant.php`).

---

## SECTION 3: CONTROLLER AUDIT

### 3.1 StandardTimetableController (21 lines)
**File:** `/Users/bkwork/Herd/prime_ai/Modules/StandardTimetable/app/Http/Controllers/StandardTimetableController.php`

```php
class StandardTimetableController extends Controller
{
    public function manualPlacement(): mixed
    {
        Gate::authorize('standard-timetable.viewAny');
        return view('standardtimetable::pages.manual-placement');
    }
}
```

### 3.2 Issues
- **GAP-CTRL-001 (CRITICAL):** Only ONE method exists (`manualPlacement`). No CRUD operations, no timetable management, no generation flow.
- **GAP-CTRL-002:** The method uses `Gate::authorize('standard-timetable.viewAny')` but this permission is not defined in any seeder or permission table.
- **GAP-CTRL-003:** No data is passed to the view -- the manual-placement blade receives zero variables from the controller.
- **GAP-CTRL-004:** Missing all essential methods: index, create, store, show, edit, update, destroy.
- **GAP-CTRL-005:** The method is not connected to any route (route group is empty).

---

## SECTION 4: MODEL AUDIT

- **GAP-MDL-001:** Zero models in this module. The module directory has no `app/Models/` directory.
- **GAP-MDL-002:** Expected to reuse SmartTimetable/TimetableFoundation models but no imports or references exist.

---

## SECTION 5: SERVICE AUDIT

- **GAP-SVC-001:** Zero services in this module. No business logic layer exists.

---

## SECTION 6: FORMREQUEST AUDIT

- **GAP-FR-001:** Zero FormRequests in this module.

---

## SECTION 7: POLICY/AUTHORIZATION AUDIT

- **GAP-POL-001:** Zero policies in this module.
- **GAP-POL-002:** The one controller method uses a Gate check (`standard-timetable.viewAny`) but the permission string has no corresponding policy registered in `AppServiceProvider.php`.

---

## SECTION 8: VIEW AUDIT

### 8.1 Views Found (3)
1. `resources/views/components/layouts/master.blade.php` -- layout wrapper
2. `resources/views/index.blade.php` -- basic index page
3. `resources/views/pages/manual-placement.blade.php` -- drag-and-drop grid page

### 8.2 Issues
- **GAP-VW-001:** `manual-placement.blade.php` exists but receives no data from controller. May be a static mockup.
- **GAP-VW-002:** `index.blade.php` exists but no route or controller method serves it.

---

## SECTION 9: SECURITY AUDIT

| ID | Severity | Issue | Location |
|---|---|---|---|
| SEC-ST-001 | CRITICAL | Module is entirely non-functional -- no routes registered | `tenant.php:2210-2212` |
| SEC-ST-002 | HIGH | No `EnsureTenantHasModule` middleware | `tenant.php:2210` |
| SEC-ST-003 | HIGH | Permission `standard-timetable.viewAny` is not seeded/registered | Controller line 17 |

---

## SECTION 10: PERFORMANCE AUDIT

No performance issues to report -- the module has no functional code to evaluate.

---

## SECTION 11: ARCHITECTURE AUDIT

- **GAP-ARCH-001 (CRITICAL):** Module is a skeleton with zero functional implementation. Only boilerplate files from module generator exist.
- **GAP-ARCH-002:** No clear architectural boundary between StandardTimetable and SmartTimetable. The design intent (simpler manual workflow vs. auto-generation) is not implemented.
- **GAP-ARCH-003:** Module has its own ServiceProvider (`StandardTimetableServiceProvider.php`) registered but provides nothing.
- **GAP-ARCH-004:** `database/seeders/StandardTimetableDatabaseSeeder.php` exists but is likely empty.

---

## SECTION 12: TEST COVERAGE

- **0 tests found.** No test files exist anywhere for this module.

---

## SECTION 13: BUSINESS LOGIC COMPLETENESS

This module is **~5% complete**. Only the file skeleton exists. The entire business logic for standard (manual) timetable management needs to be built:

1. Manual timetable creation (drag-and-drop grid)
2. Class-wise, Teacher-wise, Room-wise views
3. Manual cell placement and swapping
4. Validation against constraints
5. Publishing workflow
6. Integration with SmartTimetable data (activities, constraints, etc.)

---

## PRIORITY FIX PLAN

### P0 -- Critical (Must Fix Before Production)
1. Register routes in the route group for at least: index, manual-placement, store-cell, swap-cell, delete-cell
2. Add `EnsureTenantHasModule` middleware
3. Build out StandardTimetableController with CRUD + manual placement logic
4. Create or reuse models from TimetableFoundation

### P1 -- High Priority
5. Create service layer for manual placement business logic
6. Create FormRequests for all store/update operations
7. Create policy and register in AppServiceProvider
8. Seed permissions for `standard-timetable.*`
9. Build functional views with data binding

### P2 -- Medium Priority
10. Add constraint validation for manual placements
11. Implement class/teacher/room wise views
12. Add publishing workflow

### P3 -- Low Priority
13. Add test coverage
14. Add AJAX endpoints for real-time drag-and-drop

---

## EFFORT ESTIMATION

| Priority | Items | Estimated Hours |
|---|---|---|
| P0 | 4 items | 30-40 hours |
| P1 | 5 items | 25-35 hours |
| P2 | 3 items | 20-30 hours |
| P3 | 2 items | 15-20 hours |
| **Total** | **14 items** | **90-125 hours** |

**Note:** This module needs to be built almost from scratch. The estimate above assumes reuse of SmartTimetable/TimetableFoundation models and services.
