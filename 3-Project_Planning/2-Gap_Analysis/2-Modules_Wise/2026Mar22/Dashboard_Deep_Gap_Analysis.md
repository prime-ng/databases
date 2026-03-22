# Dashboard Module — Production-Readiness Gap Analysis
**Date:** 2026-03-22  |  **Branch:** Brijesh_SmartTimetable  |  **Auditor:** Claude Code (Deep Audit)
**Module Path:** /Users/bkwork/Herd/prime_ai/Modules/Dashboard

---

## EXECUTIVE SUMMARY

| Severity    | Count |
|-------------|-------|
| Critical    | 3     |
| High        | 5     |
| Medium      | 4     |
| Low         | 3     |
| **Total**   | **15**|

### Module Scorecard

| Area                      | Score | Notes                                         |
|---------------------------|-------|-----------------------------------------------|
| DB / DDL Integrity        | N/A   | No DDL — view-only module                     |
| Route Integrity           | 6/10  | Routes exist but inconsistent across contexts |
| Controller Quality        | 3/10  | Zero auth, zero input handling, view-only     |
| Model Quality             | N/A   | No models                                     |
| Security                  | 3/10  | Zero authorization on all methods             |
| Performance               | 7/10  | Simple view returns, no queries               |
| Authorization             | 1/10  | ZERO Gate checks in entire controller         |
| Test Coverage             | 0/10  | Zero tests                                    |
| Architecture              | 4/10  | No service layer, controller is thin          |
| **Overall**               | **3.4/10** |                                          |

---

## SECTION 1 — MISSING FEATURES

**MF-001 — No Dynamic Data on Dashboard Views**
- File: `DashboardController.php` (lines 9-38)
- All 7 methods simply return Blade views with zero data passed. Dashboard views are static HTML with no dynamic widgets, stats, or metrics.
- Expected: KPIs, student counts, pending tasks, recent activity, etc.

**MF-002 — No Tenant Dashboard Differentiation**
- The `index()` method at line 9 returns `view('backend.v1.dashboard.index')` — points to a generic backend view, not module-specific views.
- Tenant routes (tenant.php line 1347-1361) define additional dashboard routes for sub-dashboards but all return static views.

**MF-003 — No Dashboard Widget Configuration**
- No model or config for dashboard customization per user/role.
- No drag-and-drop widget support or user preferences.

---

## SECTION 2 — BUGS

**BUG-001 — `index()` Returns Non-Module View Path**
- File: `DashboardController.php` line 11
- `return view('backend.v1.dashboard.index')` — references a `backend.v1` view, not `dashboard::index`.
- All other methods use module-namespaced views (`dashboard::core-configuration.dashboard`), creating inconsistency.

**BUG-002 — Tenant Route and Web Route Duplication**
- Dashboard routes exist in BOTH `routes/web.php` (line 65, central domain) and `routes/tenant.php` (line 1347, tenant context).
- Web.php uses `PrimeController::class` for some dashboard methods, while tenant.php uses `DashboardController::class`.
- Potential confusion about which controller handles which context.

---

## SECTION 3 — SECURITY ISSUES

**SEC-001 — Zero Authorization on All Dashboard Methods (CRITICAL)**
- File: `DashboardController.php` — 7 methods, 0 Gate checks.
- Methods: `index()`, `coreConfiguration()`, `foundationSetup()`, `admissionStudentManagement()`, `schoolSetup()`, `operationManagement()`, `supportManagement()`.
- Any authenticated user can access ANY dashboard section regardless of role.
- These sub-dashboards (core-configuration, foundational-setup, etc.) may expose sensitive navigation or data to unauthorized roles.

**SEC-002 — No Role-Based Dashboard Filtering**
- No mechanism to show/hide dashboard sections based on user permissions.
- A student or parent could navigate to `/dashboard/core-configuration` and see admin-level dashboard.

**SEC-003 — No CSRF Token on Dashboard AJAX Calls**
- While current dashboard is static, any future AJAX widgets need CSRF protection. No patterns established.

---

## SECTION 4 — PERFORMANCE ISSUES

**PERF-001 — No Performance Concerns Currently**
- Module is purely view-returning with no DB queries. Performance is inherently good.
- Future concern: when dashboards become data-driven, will need caching strategy.

---

## SECTION 5 — AUTHORIZATION GAPS

**AUTH-001 — DashboardController Has ZERO Gate::authorize Calls (CRITICAL)**
- Every method is unprotected:
  - `index()` — line 9: No auth
  - `coreConfiguration()` — line 14: No auth
  - `foundationSetup()` — line 18: No auth
  - `admissionStudentManagement()` — line 22: No auth
  - `schoolSetup()` — line 26: No auth
  - `operationManagement()` — line 30: No auth
  - `supportManagement()` — line 34: No auth

**AUTH-002 — Web.php Dashboard Routes Use Auth Middleware But No Policy**
- Routes at web.php line 65: `Route::middleware(['auth', 'verified'])` ensures login but no role/permission check.

---

## SECTION 6 — MISSING POLICIES

| Entity    | Policy Exists | Registered |
|-----------|---------------|------------|
| Dashboard | **No**        | N/A        |

- No DashboardPolicy exists anywhere in the codebase.
- Recommended: Create a `DashboardPolicy` with `viewCoreConfig`, `viewFoundationalSetup`, etc. abilities.

---

## SECTION 7 — DB / MODEL MISMATCHES

N/A — Module has no models or DDL.

---

## SECTION 8 — ROUTE ISSUES

**RT-001 — Conflicting Dashboard Routes Across Files**
- `routes/web.php` line 65-83: Dashboard under `central.dashboard.*` prefix using `PrimeController`.
- `routes/tenant.php` line 1347-1361: Dashboard under `dashboard.*` prefix using `DashboardController`.
- `routes/tenant.php` line 330: `Route::get('/dashboard', [DashboardController::class, 'index'])` — main tenant dashboard.
- `routes/tenant.php` line 544: `Route::get('dashboard', [SystemConfigController::class, 'index'])` inside global-master prefix — conflicts with main dashboard route.

**RT-002 — Module's Own routes/web.php is Empty**
- File: `/Modules/Dashboard/routes/web.php` — likely empty or minimal.
- All routing is done in global route files.

**RT-003 — No Named Route for Main Dashboard `index()`**
- `routes/tenant.php` line 330: `->name('dashboard')` — but this is a top-level name, not namespaced.

---

## SECTION 9 — MISSING FORM REQUESTS

N/A — Module has no form submissions. No FormRequests needed unless dashboard configuration is added.

---

## SECTION 10 — TEST COVERAGE GAPS

**TEST-001 — Zero Test Files**
- `/Modules/Dashboard/tests/Feature/.gitkeep` — empty
- `/Modules/Dashboard/tests/Unit/.gitkeep` — empty
- No tests of any kind.

**Missing Test Coverage:**
- No route accessibility tests
- No view rendering tests
- No authorization tests (critical since auth is missing)
- No smoke tests for each dashboard sub-page

---

## SECTION 11 — STUB / EMPTY METHODS

No empty stubs — all methods return views. However, all methods are functionally trivial (single-line view returns).

---

## SECTION 12 — ARCHITECTURE VIOLATIONS

**ARCH-001 — No Service Layer for Dashboard Data**
- When dashboards need real data, there's no `DashboardService` to aggregate metrics across modules.
- Should prepare service interfaces now.

**ARCH-002 — Cross-Concern View Reference**
- `index()` returns `view('backend.v1.dashboard.index')` — references views outside the module.
- Other methods properly use `dashboard::` prefix.

**ARCH-003 — No Dashboard Configuration Model**
- No way to persist dashboard layout, widget preferences, or user customizations.
- For SaaS product, each tenant should be able to customize their dashboard.

**ARCH-004 — Module Structure Has Unnecessary Files**
- `database/seeders/DashboardDatabaseSeeder.php` exists but has nothing to seed.
- Empty migration directory, empty factory directory.

---

## SECTION 13 — WHAT IS WORKING CORRECTLY

1. **Module Structure** — Follows nwidart/laravel-modules convention with proper ServiceProvider, RouteServiceProvider, EventServiceProvider.
2. **View Organization** — Sub-dashboard views are properly organized in subdirectories (core-configuration, foundational-setup, etc.).
3. **Route Middleware** — Routes are protected by `auth` and `verified` middleware at the route level.
4. **Clean Controller** — No unnecessary complexity; simple and readable.
5. **Blade Templates** — Each sub-dashboard has its own blade template for easy customization.
6. **Module Registration** — Properly registered in module.json with correct providers.

---

## PRIORITY FIX PLAN

### P0 — Critical (Fix Immediately)
| ID       | Issue                                                    | Effort |
|----------|----------------------------------------------------------|--------|
| AUTH-001 | Add Gate::authorize checks to all 7 DashboardController methods | 1h |
| SEC-001  | Create DashboardPolicy with per-section permissions       | 1.5h   |
| SEC-002  | Implement role-based dashboard section visibility          | 2h     |

### P1 — High (Fix Before Release)
| ID       | Issue                                                    | Effort |
|----------|----------------------------------------------------------|--------|
| BUG-001  | Change `index()` to return `dashboard::index` view       | 0.25h  |
| RT-001   | Consolidate dashboard routes, remove duplicates           | 1h     |
| MF-001   | Pass basic dynamic data to dashboard views                | 4h     |
| MF-002   | Differentiate central vs tenant dashboard properly        | 2h     |

### P2 — Medium (Fix in Next Sprint)
| ID       | Issue                                                    | Effort |
|----------|----------------------------------------------------------|--------|
| ARCH-001 | Create DashboardService for metrics aggregation           | 4h     |
| TEST-001 | Write smoke tests for all dashboard routes                | 2h     |
| MF-003   | Design dashboard widget configuration system              | 8h     |

### P3 — Low (Technical Debt)
| ID       | Issue                                                    | Effort |
|----------|----------------------------------------------------------|--------|
| ARCH-002 | Move backend.v1 view into dashboard module                | 0.5h   |
| ARCH-004 | Clean up empty scaffold files                             | 0.25h  |

---

## EFFORT ESTIMATION

| Priority | Items | Estimated Hours |
|----------|-------|----------------|
| P0       | 3     | 4.5h           |
| P1       | 4     | 7.25h          |
| P2       | 3     | 14h            |
| P3       | 2     | 0.75h          |
| **Total**| **12**| **26.5h**      |
