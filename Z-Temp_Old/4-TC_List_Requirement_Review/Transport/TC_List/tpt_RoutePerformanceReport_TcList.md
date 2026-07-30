# tpt_RoutePerformanceReport_TcList

## Module: Transport → Transport Report → Route Performance

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | Transport |
| Tab Group | Transport Report |
| Feature | Route Performance Report |
| URL(s) | `/transport-report?active_tab=route-performance` (page load), AJAX: `GET /transport-report?active_tab=route-performance&section=charts` and `&section=table` |
| Controller | `Modules\Transport\app\Http\Controllers\TransportReportController` |
| Tab Builder Method | `buildRoutePerformanceSection()` (line 99) |
| Data Method | `getRouteReport()` (line 561) |
| View | `transport::report.route-performance.index` |
| Hub View | `transport::tab_module.transportreport` |
| Permission | `tenant.route-performance.viewAny` (line 23 of transportreport.blade.php) |
| Permission (config) | `config/permissionslist.php` line 337: `'route-performance' => $crud` |
| $crud actions | create, view, viewAny, update, delete, restore, forceDelete, import, export, print, publish, status, email-schedule, remark, pdf, edit, approve |
| Effective Permissions | `tenant.route-performance.viewAny`, `tenant.route-performance.create`, `tenant.route-performance.view`, `tenant.route-performance.update`, `tenant.route-performance.delete`, `tenant.route-performance.restore`, `tenant.route-performance.forceDelete`, `tenant.route-performance.import`, `tenant.route-performance.export`, `tenant.route-performance.print`, `tenant.route-performance.publish`, `tenant.route-performance.status`, `tenant.route-performance.email-schedule`, `tenant.route-performance.remark`, `tenant.route-performance.pdf`, `tenant.route-performance.edit`, `tenant.route-performance.approve` |
| Export | Not implemented (report is read-only, no export button in view) |
| Soft Deletes | N/A (aggregation queries, not direct model CRUD) |
| Chart.js Version | Loaded from CDN: `https://cdn.jsdelivr.net/npm/chart.js` |
| DateRangePicker | Loaded from CDN: `moment.js` + `daterangepicker.js` + `daterangepicker.css` |
| Record Count Minimum | 3 routes with allocations + boarding logs for meaningful charts |
| Pagination Strategy | Custom `paginateCollection()` with `page_route` page name, 10 per page |
| Eager Loading Strategy | 6 relationships: studentAllocationsAll.student, boardingLogs (constrained), tripStopDetails (constrained), trips (constrained), pickupPointRoutes, shift |

---

## 2. Pre-conditions

| PC ID | Condition | Details |
|-------|-----------|---------|
| PC-01 | Required Permission | `tenant.route-performance.viewAny` — user must have this permission to see the tab |
| PC-02 | Base Permission | `tenant.transport.viewAny` — required for `index()` Gate check at line 36; without this, `/transport-report` returns 403 |
| PC-03 | Tenant Context | Tenant must be initialized via `tenancy()->initialize()` middleware chain |
| PC-04 | Dusk Environment | `DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD` must be set for automated testing |
| PC-05 | Seed Data — Routes | At least 1 active `Route` (tpt_route) with `is_active = 1`, linked to an active `Shift` (tpt_shift) via `shift_id` FK |
| PC-06 | Seed Data — Allocations | `TptStudentAllocationJnt` records linking students to routes via `pickup_route_id` or `drop_route_id`; minimum 1 student per route |
| PC-07 | Seed Data — Boarding Logs | `StudentBoardingLog` records with `trip_date` within the test date range; some with `boarding_time`/`unboarding_time` set, some null |
| PC-08 | Seed Data — Trip Stop Details | `TptTripStopDetail` records with `reached_flag = 1`, `reaching_time` and `sch_arrival_time` set to create delay variance |
| PC-09 | Date Range Default | If no `dates` parameter, defaults to `now()->startOfMonth()->toDateString()` through `now()->endOfMonth()->toDateString()` (line 334-335 of controller) |
| PC-10 | AJAX Dual Request | On tab activation, two sequential AJAX calls fire: `section=charts` and `section=table`; each returns JSON with an `html` property |
| PC-11 | JavaScript Dependencies | Chart.js, Moment.js, jQuery, Bootstrap JS, DateRangePicker JS/CSS must all be loaded (CDN-SRC at lines 68-71 of hub view) |
| PC-12 | Route active() Scope | `getRouteReport()` applies `->active()` scope which filters `is_active = 1` — only enabled routes appear in report |
| PC-13 | Controller Path Correctness | Controller lives at `Modules\Transport\app\Http\Controllers\TransportReportController.php` (with `app/` segment) |
| PC-14 | Collection Pagination | Results are wrapped via `paginateCollection($routeReports, 10, 'page_route')` — uses `LengthAwarePaginator` with a custom page name |
| PC-15 | Filter Data Availability | `getFilterData()` pre-loads routes, vehicles, shifts, academic sessions, stops, drivers, staff, classes, students, notification types for dropdowns |

---

## 3. Default Data Load

### 3.1 Summary Cards (Charts Section)

| DL ID | Card | Variable | Source Method | Aggregation | Fallback |
|-------|------|----------|--------------|-------------|----------|
| DL-01 | Total Routes | `$summary->total_routes` | `$routeReports->count()` | Count of collection items | 0 |
| DL-02 | Allocated Students | `$summary->total_students` | `$routeReports->sum('allocated_students')` | Sum of unique student allocations per route | 0 |
| DL-03 | Boarded Students | `$summary->boarded_students` | `$routeReports->sum('boarded_students')` | Sum of boarding logs with non-null boarding_time per route | 0 |
| DL-04 | Avg Pickup Delay | `$summary->avg_pickup_delay` | `round((float)($routeReports->avg('avg_delay_minutes') ?? 0), 2)` | Average of route-level avg_delay_minutes | 0 |

### 3.2 Charts (Charts Section)

| DL ID | Chart | Canvas ID | Chart Type | Datasets | Notes |
|-------|-------|-----------|------------|----------|-------|
| DL-05 | Route Performance Overview | `routePerformanceChart` | Bar (Grouped/Stacked toggle) | Allocated Students, Boarded Students, Unboarded Students | Radio buttons toggle `scales.x/y.stacked` |
| DL-06 | Route Compliance Analysis | `routeComplianceChart` | Line (filled) | Boarding Compliance %, Unboarding Compliance % | Y-axis: 0–100%; tension: 0.3; fill: true |
| DL-07 | Route Delay Analysis | `routeDelayChart` | Horizontal Bar | Average Delay (minutes) | Color-coded: green ≤5min, yellow ≤15min, red >15min; `indexAxis: 'y'` |

### 3.3 Table Columns (Table Section)

| DL ID | Column | Data Type | Source in Code | Formatting |
|-------|--------|-----------|----------------|------------|
| DL-08 | Route | String | `$r->name`, `$r->code` | `strong` name + `small.text-muted` code below |
| DL-09 | Stops | Integer | `$r->total_stops` | Plain number |
| DL-10 | Allocated | Integer | `$r->allocated_students` | `fw-semibold` |
| DL-11 | Boarded | Integer | `$r->boarded_students` | `fw-semibold text-primary` |
| DL-12 | Unboarded | Integer | `$r->unboarded_students` | Plain number |
| DL-13 | Boarding % | Float | `$r->boarding_compliance_pct` | Progress bar (8px height) + percentage; color: green ≥90%, yellow ≥75%, red <75% |
| DL-14 | Unboarding % | Float | `$r->unboarding_compliance_pct` | Progress bar + percentage; same color scheme |
| DL-15 | Avg Delay | Float (minutes) | `$r->avg_delay_minutes` | Badge: green ≤5min, yellow ≤15min, red >15min |
| DL-16 | Status | String | Computed from `boarding_compliance_pct` in blade | Badge: Excellent (≥90%), Good (≥75%), Fair (≥60%), Poor (<60%) |

### 3.4 Backend Computation Details

| DL ID | Computed Field | Formula | Line in Controller |
|-------|---------------|---------|--------------------|
| DL-17 | `allocated_students` | `$route->studentAllocationsAll->unique('student_id')->count()` | 577 |
| DL-18 | `boarded_students` | `$route->boardingLogs->whereNotNull('boarding_time')->unique('student_id')->count()` | 578 |
| DL-19 | `unboarded_students` | `$route->boardingLogs->whereNotNull('unboarding_time')->unique('student_id')->count()` | 579 |
| DL-20 | `avg_delay_minutes` | `$route->tripStopDetails->avg(function($d) { return $d->reaching_time->diffInMinutes($d->sch_arrival_time); })` | 582-586 |
| DL-21 | `boarding_compliance_pct` | `$allocated ? round(($boarded / $allocated) * 100, 2) : 0` | 597 |
| DL-22 | `unboarding_compliance_pct` | `$allocated ? round(($unboarded / $allocated) * 100, 2) : 0` | 598 |
| DL-23 | `total_stops` | `$route->pickupPointRoutes->count()` | 592 |

### 3.5 AJAX Loading Behavior

| DL ID | Aspect | Detail |
|-------|--------|--------|
| DL-24 | Initial Load | `loadTabSection('route-performance', 'charts')` and `loadTabSection('route-performance', 'table')` called during `$(document).ready()` |
| DL-25 | Tab Switch | On `shown.bs.tab` event, checks `loaded` CSS class; only loads if not already loaded |
| DL-26 | Filter Submission | `transport-filter-form` submit handler serializes form, calls both section loads with formData |
| DL-27 | Pagination Click | Click handler intercepts `.pagination a` clicks, parses query string, calls table section load |
| DL-28 | Error State | AJAX error → container shows `<div class="alert alert-danger">Failed to load charts/table.</div>` |
| DL-29 | Loading State | During AJAX, `container.css('opacity', 0.5)` gives visual feedback |
| DL-30 | Empty Data (Table) | Table shows `<i class="bi bi-inbox">` icon + "No route performance data found" for empty results |

---

## 4. Test Data Strategy

| TD ID | Strategy | Details |
|-------|----------|---------|
| TD-01 | Unique Identifiers | Use `now()->format('His') . random_int(100, 999)` suffix for route codes/names to guarantee uniqueness across test runs |
| TD-02 | Minimum Route Count | Create at least 3 active routes via `Route::factory()` or direct DB insert; each linked to an active shift |
| TD-03 | Student Allocation Seed | For each route, insert `TptStudentAllocationJnt` records linking 2-5 students per route; use both `pickup_route_id` and `drop_route_id` assignments |
| TD-04 | Boarding Log Seed | Insert `StudentBoardingLog` records with `trip_date` inside the test date range; for Route 1: all boarded/unboarded; Route 2: partial boarding; Route 3: no boarding |
| TD-05 | Trip Stop Detail Seed | Insert `TptTripStopDetail` with `reached_flag = 1`; vary `reaching_time` vs `sch_arrival_time` to create delays: Route 1: 2min avg; Route 2: 10min avg; Route 3: 30min avg |
| TD-06 | Edge Case — Zero Allocations | Create one additional route with no `TptStudentAllocationJnt` records → `allocated_students = 0`, compliance = 0% |
| TD-07 | Edge Case — 100% Compliance | Create route where every allocated student has a boarding log with non-null `boarding_time` → `boarding_compliance_pct = 100%` |
| TD-08 | Edge Case — 0% Compliance | Create route with allocations but NO boarding logs (trip_date outside range or deleted) → `boarding_compliance_pct = 0%` |
| TD-09 | Edge Case — High Delay | Create route with trip stop details where `reaching_time` is 60+ minutes after `sch_arrival_time` → `avg_delay_minutes > 60` |
| TD-10 | Cleanup Strategy | Delete all test-inserted records after test run: `Route::where('code', 'like', 'TC-%')->forceDelete()`, cascading to allocations, logs, stop details |
| TD-11 | Academic Session Coverage | Ensure test allocations span 2 academic sessions to test the `academic_session_id` filter |
| TD-12 | Shift Diversity | Create routes under 2 different shifts to test `shift_id` filter |
| TD-13 | Concurrent Test Safety | Use database transactions with rollback in test `setUp()/tearDown()` to avoid cross-test pollution |
| TD-14 | Student Duplication Case | Allocate the same student to BOTH `pickup_route_id` and `drop_route_id` on the same route → tests `unique('student_id')` deduplication |

---

## 5. Business Conditions

### 5.1 Database Schema — Referenced Tables

| BC ID | Table | Key Columns | Notes |
|-------|-------|-------------|-------|
| BC-DB-01 | tpt_route | id, name, code, pickup_drop, shift_id, is_active | Routes filtered by `active()` scope (is_active = 1) |
| BC-DB-02 | tpt_shift | id, name, code | FK from `tpt_route.shift_id`; used in shift filter |
| BC-DB-03 | tpt_student_route_allocation_jnt | id, student_session_id, student_id, pickup_route_id, drop_route_id, pickup_stop_id, drop_stop_id | Used via `Route::studentAllocationsAll` relationship (hasMany) |
| BC-DB-04 | tpt_student_boarding_log | id, trip_date, student_id, student_session_id, boarding_route_id, boarding_time, unboarding_route_id, unboarding_time | Filtered by `trip_date BETWEEN startDate AND endDate` in constrained eager load |
| BC-DB-05 | tpt_trip_stop_detail | id, trip_id, stop_id, sch_arrival_time, reaching_time, reached_flag | `reached_flag = 1` filter in constrained eager load; delay = `reaching_time->diffInMinutes(sch_arrival_time)` |
| BC-DB-06 | tpt_trip | id, route_id (via route_scheduler), trip_date, vehicle_id, shift_id, start_time, end_time, status | Used for vehicle filter via constrained eager load |
| BC-DB-07 | tpt_pickup_points_route_jnt | id, route_id, pickup_point_id, ordinal | Counted via `Route::pickupPointRoutes` relationship for `total_stops` |
| BC-DB-08 | tpt_pickup_points | id, name, is_active | Stop name reference in pickup point junction |
| BC-DB-09 | tpt_route_scheduler | id, route_id | Bridge table: `TptTrip` → `tpt_route_scheduler` → `tpt_route` |
| BC-DB-10 | std_students | id, first_name, last_name | Student name reference via eager load |

### 5.2 Query Logic (`getRouteReport` — line 561)

| BC ID | Aspect | Line(s) | Detail |
|-------|--------|---------|--------|
| BC-QL-01 | Base Query | 563 | [Query/Code Removed] |
| BC-QL-02 | studentAllocationsAll.student | 564 | Eager loads allocations with student data — uses `Route.studentAllocationsAll` hasMany |
| BC-QL-03 | boardingLogs Constraint | 565 | [Query/Code Removed] |
| BC-QL-04 | tripStopDetails Constraint | 566 | [Query/Code Removed] |
| BC-QL-05 | trips Constraint | 567 | [Query/Code Removed] |
| BC-QL-06 | Route ID Filter | 569 | [Query/Code Removed] |
| BC-QL-07 | Shift ID Filter | 570 | [Query/Code Removed] |
| BC-QL-08 | Academic Session Filter | 571-573 | [Query/Code Removed] |
| BC-QL-09 | Active Scope | 574 | `->active()` — local scope filtering `is_active = 1` |
| BC-QL-10 | Unique Student Count | 577 | `$route->studentAllocationsAll->unique('student_id')->count()` — deduplicates students allocated to both pickup AND drop on same route |
| BC-QL-11 | Boarded Count | 578 | `$route->boardingLogs->whereNotNull('boarding_time')->unique('student_id')->count()` — only students who actually boarded |
| BC-QL-12 | Unboarded Count | 579 | `$route->boardingLogs->whereNotNull('unboarding_time')->unique('student_id')->count()` — only students who unboarded |
| BC-QL-13 | Delay Calculation | 582-586 | `$detail->reaching_time->diffInMinutes($detail->sch_arrival_time)` — average across all trip stop details; `Carbon::diffInMinutes()` returns absolute difference |
| BC-QL-14 | Division by Zero Guard (Boarding) | 597 | `$allocated ? round(($boarded / $allocated) * 100, 2) : 0` — ternary prevents division by zero |
| BC-QL-15 | Division by Zero Guard (Unboarding) | 598 | Same pattern: `$allocated ? round(($unboarded / $allocated) * 100, 2) : 0` |
| BC-QL-16 | Null Delay Coalescing | 596 | `round((float) $avgDelay, 2)` — if all tripStopDetails are empty, `avg()` returns null which casts to 0 via `(float)` |
| BC-QL-17 | Collection Map Return | 588-599 | Returns raw object (not array via `toArray()`) — properties accessed as `$r->name`, `$r->code`, etc. in blade |
| BC-QL-18 | Eager Loading N+1 Prevention | 563-568 | All 4 relationships eager-loaded in single query; no lazy-loading inside the map loop |
| BC-QL-19 | vehicle_id Filter Scope | 567 | Only constrains `trips` eager load — does NOT filter the Route query itself; route still appears but with empty trips collection |
| BC-QL-20 | Carbon DiffInMinutes Behavior | 584 | `diffInMinutes()` returns absolute value (always positive); does NOT distinguish early vs late arrival |

### 5.3 Validation / Error Handling

| BC ID | Condition | Code Location | Expected Behavior |
|-------|-----------|---------------|-------------------|
| BC-VAL-01 | Empty `dates` parameter | `parseDateRange()` line 329 | Defaults to `startOfMonth()` → `endOfMonth()` |
| BC-VAL-02 | Malformed `dates` string | [Query/Code Removed] | [Query/Code Removed] |
| BC-VAL-03 | Single date instead of range | `parseDateRange()` line 330 | `explode(' - ', $request->dates, 2)` returns `[$date]`; `$to` is undefined → PHP warning |
| BC-VAL-04 | Non-numeric filter IDs | Eloquent `where('id', 'abc')` | Returns empty result set (no matching route); no error thrown |
| BC-VAL-05 | Zero routes in DB | `getRouteReport()` returns empty collection | Summary all 0; table shows "No route performance data found" |
| BC-VAL-06 | Route with null name | `$route->name` is null | Chart label shows empty string; table shows nothing in strong tag |
| BC-VAL-07 | Route with null code | `$route->code` is null | Table shows "Code:" with no value |
| BC-VAL-08 | Student with null first_name/last_name | `$route->studentAllocationsAll.student` | `->unique('student_id')` still counts by integer ID; no error |
| BC-VAL-09 | boarding_time null for all records | `whereNotNull('boarding_time')` | `boarded_students = 0`; `boarding_compliance_pct = 0` |
| BC-VAL-10 | tripStopDetails empty for route | `tripStopDetails` constrained collection empty | `avg_delay_minutes = 0` via `(float) null` cast |
| BC-VAL-11 | Date range spanning future dates | No boarding logs exist yet | Empty results; fallback to empty state |
| BC-VAL-12 | Academic session with no allocations | `whereHas` subquery returns no routes | Routes with no allocations in that session excluded from results |
| BC-VAL-13 | vehicle_id filter with no matching trips | Trips eager load returns empty | Route still appears; delay = 0 since no trip stop details to average |
| BC-VAL-14 | `$routeReports` null in blade charts section | Blade line 6-11 | `??` operator provides default (object) with all 0 values |
| BC-VAL-15 | `$routeReports` null in blade table section | Blade line 228 | `$routeReports = $routeReports ?? collect()` fallback to empty collection |
| BC-VAL-16 | `section` param missing from request | `buildRoutePerformanceSection()` line 101 | `request()->merge(['section' => $section])` ensures section is set |

### 5.4 Authorization (Permission Gates)

| BC ID | Permission | Code Location | Without Permission | Notes |
|-------|-----------|---------------|-------------------|-------|
| BC-AUTH-01 | `tenant.transport.viewAny` | `index()` line 36 — `Gate::authorize(...)` | 403 Forbidden on `/transport-report` | Master gate — all tabs depend on this |
| BC-AUTH-02 | `tenant.route-performance.viewAny` | `transportreport.blade.php` line 23 — `@can` | Tab hidden from UI; tab-pane content not rendered | Blade-level protection ONLY |
| BC-AUTH-03 | No per-tab Gate in AJAX | `loadTabSection()` line 73-92 | User with `transport.viewAny` but WITHOUT `route-performance.viewAny` can still receive data via AJAX | **SECURITY GAP** — `loadTabSection()` checks no per-tab permission |
| BC-AUTH-04 | No per-row permissions | N/A | All data visible if tab is accessible | Read-only aggregated report; no row-level filtering |
| BC-AUTH-05 | `tenant.route-performance.viewAny` in permissionslist.php | `config/permissionslist.php` line 337 | If removed from config, `Gate::authorize()` throws `InvalidArgumentException` | Permission must exist in the list AND in the user/role assignment |
| BC-AUTH-06 | Blade `@can` vs actual permission string | Blade line 23 | Uses `tenant.route-performance.viewAny` — matches config/permissionslist.php exactly | ✅ Confirmed consistent |
| BC-AUTH-07 | Super Admin Bypass | `Gate::before()` in `AppServiceProvider` | Super admin (`is_super_admin = 1`) bypasses all Gate checks | All data visible regardless of assigned permissions |
| BC-AUTH-08 | Unauthenticated access | Web middleware | Redirected to `/login` | Laravel default auth middleware |
| BC-AUTH-09 | AJAX bypass via active_tab parameter | User manually sets `?active_tab=route-performance` in URL | Page loads; `$activeTab` variable passed; AJAX fires; data returns | Tab pane still hidden by `@can` but DOM contains hidden content |
| BC-AUTH-10 | Permission group check | `config/permissionslist.php` line 337 | `'route-performance' => $crud` — all 14+ crud actions registered | `viewAny` is one of the registered actions in $crud array |

### 5.5 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Date range default | When no `dates` parameter, defaults to `now()->startOfMonth()->toDateString()` through `now()->endOfMonth()->toDateString()` |
| BC-BIZ-02 | Date range parsing | [Query/Code Removed] |
| BC-BIZ-03 | No routes in filter range | Empty collection returned; summary shows 0 for all KPIs; table shows "No route performance data found" |
| BC-BIZ-04 | Route with zero allocations | `allocated_students = 0`; `boarding_compliance_pct = 0` (division by zero guard at line 597) |
| BC-BIZ-05 | Route with zero trip stop details | `avg_delay_minutes = 0` (null coalescing via `(float)` cast of null → 0) |
| BC-BIZ-06 | Boarding compliance > 100% | Not possible — `unique('student_id')` on both allocated and boarded ensures boarded ≤ allocated; blade uses `min($r->boarding_compliance_pct, 100)` for progress bar |
| BC-BIZ-07 | AJAX pagination | Uses `page_route` as page name param in `paginateCollection()`; pagination links serialize query string via `->appends(request()->query())->links()` |
| BC-BIZ-08 | Chart data binding (empty data) | Chart.js datasets initialized with `@json($routeReports->pluck('...'))`; empty arrays → Chart.js renders with zero-height bars (no explicit empty-data fallback) |
| BC-BIZ-09 | Grouped/Stacked toggle | Radio buttons `groupedViewRoute` / `stackedViewRoute` toggle `performanceChart.options.scales.x/y.stacked` between `false`/`true` |
| BC-BIZ-10 | Route with 100% boarding compliance | All allocated students have `boarding_time` set → `boarding_compliance_pct = 100%`; progress bar full-width green; Status badge = "Excellent" |
| BC-BIZ-11 | Route with 0% boarding compliance | Allocations exist but no boarding logs within date range → `boarded_students = 0` → `boarding_compliance_pct = 0%`; Status badge = "Poor" |
| BC-BIZ-12 | Compliance status thresholds | Excellent (≥90%), Good (≥75%), Fair (≥60%), Poor (<60%) — computed inline in blade line 246 |
| BC-BIZ-13 | Delay color thresholds | Green (≤5min), Yellow (>5 and ≤15min), Red (>15min) — applied to both chart bars and table badges |
| BC-BIZ-14 | Summary card precision | `avg_pickup_delay` rounded via `round(..., 2)`; displayed as integer via `{{ round($summary->avg_pickup_delay) }}` in blade |
| BC-BIZ-15 | Table delay precision | `avg_delay_minutes` displayed as `{{ round($r->avg_delay_minutes, 2) }} min` with 2 decimal places |
| BC-BIZ-16 | Column count in empty table | 9 columns in header; empty row `colspan="9"` matches |
| BC-BIZ-17 | Active tab persistence | `$activeTab` set from `$request->get('active_tab', 'route-performance')` — route-performance is the default tab |
| BC-BIZ-18 | Filter reset link | `<a href="{{ request()->url() }}"` — clears all query params; no `active_tab` preserved in href |
| BC-BIZ-19 | Chart.js re-render on filter change | Filter form submit → `loadTabSection` AJAX → returned HTML includes fresh `<canvas>` + `<script>` with Chart.js initialization; old charts destroyed via DOM replacement |
| BC-BIZ-20 | Daterangepicker auto-submit | On date range select, callback at line 98-101 updates hidden fields and submits the filter form |

### 5.6 Model Relationships Used

| BC ID | Model | Relationship | Type | Foreign Key (Local Key) |
|-------|-------|-------------|------|-------------------------|
| BC-REL-01 | Route | studentAllocationsAll | HasMany | `tpt_student_route_allocation_jnt.pickup_route_id` OR `drop_route_id` |
| BC-REL-02 | Route | boardingLogs | HasMany | `tpt_student_boarding_log.boarding_route_id` OR `unboarding_route_id` |
| BC-REL-03 | Route | tripStopDetails | HasManyThrough | Route → `tpt_route_scheduler.route_id` → `tpt_trip.route_scheduler_id` → `tpt_trip_stop_detail.trip_id` |
| BC-REL-04 | Route | trips | HasMany | `tpt_trip.route_scheduler_id` → `tpt_route_scheduler.id` → `route_id` |
| BC-REL-05 | Route | pickupPointRoutes | HasMany | `tpt_pickup_points_route_jnt.route_id` |
| BC-REL-06 | Route | shift | BelongsTo | `tpt_route.shift_id` |
| BC-REL-07 | StudentAllocationJnt | student | BelongsTo | `tpt_student_route_allocation_jnt.student_id` |

### 5.7 Filter Parameters

| BC ID | Parameter | Type | Default | Source | Behavior |
|-------|-----------|------|---------|--------|----------|
| BC-FLT-01 | academic_session_id | Integer | Empty/All | Dropdown (All Sessions) | [Query/Code Removed] |
| BC-FLT-02 | route_id | Integer | Empty/All | Dropdown (Route) | Exact match on `route.id` |
| BC-FLT-03 | vehicle_id | Integer | Empty/All | Dropdown (Vehicle) | Constrains `trips` eager load (line 567) — NOT a main query filter |
| BC-FLT-04 | shift_id | Integer | Empty/All | Dropdown (Shift) | Exact match on `route.shift_id` |
| BC-FLT-05 | dates | String (range) | Current month | DateRangePicker | Parsed into `from_date`/`to_date`; constrains boarding logs AND trips eager loads |
| BC-FLT-06 | search | String | Empty | NOT in this tab's filter bar | Route Performance tab has no standalone search field (filters use dropdowns only) |

### 5.8 Blade View Logic

| BC ID | Aspect | File Line | Detail |
|-------|--------|-----------|--------|
| BC-VIEW-01 | Section routing via `@if(request('section') === 'charts')` | `index.blade.php` line 1 | Charts section rendered when `section=charts` |
| BC-VIEW-02 | Section routing via `@elseif(request('section') === 'table')` | `index.blade.php` line 226 | Table section rendered when `section=table` |
| BC-VIEW-03 | Section routing via `@else` | `index.blade.php` line 295 | Default tab-pane with skeleton loaders and filter bar when no section param |
| BC-VIEW-04 | Summary defaults | `index.blade.php` lines 6-11 | `$summary ?? (object)[...0 defaults]` — prevents undefined variable errors |
| BC-VIEW-05 | Chart.js script embedded inline | `index.blade.php` lines 137-223 | Charts JS is inside the charts-section HTML, NOT a separate file |
| BC-VIEW-06 | Progress bar width clamped | `index.blade.php` line 257 | `min($r->boarding_compliance_pct, 100)` prevents over-100% bar width |
| BC-VIEW-07 | Skeleton loader | `index.blade.php` lines 342-350 | `<div class="spinner-border text-primary">` shown during initial load |
| BC-VIEW-08 | Filter bar with `x-backend.tab.filter-bar` | `index.blade.php` line 298 | Wraps the transport-filter-form |
| BC-VIEW-09 | CDN scripts in hub view | `transportreport.blade.php` lines 68-71 | Chart.js, Moment.js, daterangepicker loaded from CDN |
| BC-VIEW-10 | JS for tab loading in hub | `transportreport.blade.php` lines 73-201 | `loadTabSection()` function handles all AJAX communication |
| BC-VIEW-11 | Pagination appends all query params | `index.blade.php` line 292 | `$routeReportsPaginated->appends(request()->query())->links()` |
| BC-VIEW-12 | Compliance status computed in blade | `index.blade.php` line 246 | `$complianceStatus = $r->boarding_compliance_pct >= 90 ? 'Excellent' : ...` |
| BC-VIEW-13 | Delay badge color in blade | `index.blade.php` line 271 | Nested ternary: `$r->avg_delay_minutes > 15 ? 'bg-danger' : ($r->avg_delay_minutes > 5 ? 'bg-warning' : 'bg-success')` |

---

## 6. Test Case List

### 6.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | Route Performance Tab Loads | `/transport-report?active_tab=route-performance` loads filter bar (Session, Route, Vehicle, Shift, Date Range) + skeleton loaders for charts + table sections | — | — | ⬜ |
| TC-P02 | Charts Section Loads With Data | Two AJAX calls fire: section=charts returns 4 summary cards + 3 charts with data; section=table returns paginated table | — | — | ⬜ |
| TC-P03 | Summary Cards Show Correct Aggregates | Total Routes, Allocated Students, Boarded Students, Avg Pickup Delay cards display aggregated values matching DB | — | — | ⬜ |
| TC-P04 | Table Displays All Routes With Metrics | Table rows show Route (name+code), Stops, Allocated, Boarded, Unboarded, Boarding %, Unboarding %, Avg Delay, Status badge | — | — | ⬜ |
| TC-P05 | Pagination Works | When 11+ routes exist, pagination links appear; navigating to page 2 loads next set via AJAX (page_route param) | — | — | ⬜ |
| TC-P06 | Filter By Route ID | Select specific route from dropdown → only that route's data in charts and table | — | — | ⬜ |
| TC-P07 | Filter By Shift | Select shift → only routes with that shift_id shown | — | — | ⬜ |
| TC-P08 | Filter By Academic Session | Select session → only routes with allocations in that session shown | — | — | ⬜ |
| TC-P09 | Filter By Date Range | Set custom date range → boarding logs and trip data constrained to range | — | — | ⬜ |
| TC-P10 | Chart Grouped/Stacked Toggle | Toggle between Grouped and Stacked view on Route Performance chart → chart redraws correctly | — | — | ⬜ |
| TC-P11 | Reset Filters | Click reset button → all filters cleared, default date range applied | — | — | ⬜ |
| TC-P12 | Full Lifecycle — All Filters Combined | Route + Shift + Session + Date range all selected → filtered data in charts and table | — | — | ⬜ |
| TC-P13 | Route With 100% Boarding Compliance | Route where all allocated students have boarding_time → boarding_compliance_pct = 100%, progress bar full | — | — | ⬜ |
| TC-P14 | Route With 0% Boarding Compliance | Route with allocations but no boarding logs → boarding_compliance_pct = 0%, progress bar empty | — | — | ⬜ |
| TC-P15 | Route With Zero Allocations Survives | Route exists with no allocations → allocated_students=0, boarding_compliance_pct=0%; route still appears in table | — | — | ⬜ |
| TC-P16 | Avg Delay Card Rounds Correctly | Routes with delays 2.456min, 5.789min, 10.123min → avg_pickup_delay displayed as integer (rounded via `{{ round() }}`) | — | — | ⬜ |
| TC-P17 | Compliance Chart Shows Two Datasets | Route Compliance line chart has both "Boarding Compliance %" and "Unboarding Compliance %" lines with fill | — | — | ⬜ |
| TC-P18 | Delay Chart Color-Coding Verified | Route with 2min delay → green bar; 10min → yellow; 30min → red bar in horizontal bar chart | — | — | ⬜ |
| TC-P19 | Tab Persists After Filter Submit | After filter form submission, active_tab=route-performance is preserved in URL; tab stays visible | — | — | ⬜ |
| TC-P20 | Vehicle Filter Constrains Trips Only | Route with vehicle_id filter applied still appears in table (trips collection filtered, not route query) | — | — | ⬜ |

### 6.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | No Routes In Date Range | Filter by date range with no boarding data → empty table with "No route performance data found"; all summary cards show 0 | — | — | ⬜ |
| TC-N02 | No Route Allocations | Route exists but has zero student allocations → allocated_students=0, boarding_compliance=0% | — | — | ⬜ |
| TC-N03 | Invalid Date Range Format | [Query/Code Removed] | — | — | ⬜ |
| TC-N04 | Non-Numeric Filter IDs | Pass `route_id=abc` → Eloquent `where('id', 'abc')` returns empty collection (no matching route) | — | — | ⬜ |
| TC-N05 | Very Large Date Range | Set range spanning multiple years → query may be slow or time out; boarding logs aggregated correctly | — | — | ⬜ |
| TC-N06 | Permission 403 — No transport.viewAny | User without `tenant.transport.viewAny` → 403 on `/transport-report` | — | — | ⬜ |
| TC-N07 | Tab Hidden — No route-performance.viewAny | User without `tenant.route-performance.viewAny` → tab is hidden; cannot access data via manual tab param | — | — | ⬜ |
| TC-N08 | Guest Access | Unauthenticated access → redirect to `/login` | — | — | ⬜ |
| TC-N09 | AJAX Error Handling | Server error during AJAX load → error message "Failed to load charts." displayed in container | — | — | ⬜ |
| TC-N10 | Empty Route Name in Chart Labels | Route with empty/null name → chart label shows empty string; still renders | — | — | ⬜ |
| TC-N11 | AJAX Bypass — Tab Permission Not Checked Server-Side | User with `tenant.transport.viewAny` but WITHOUT `tenant.route-performance.viewAny` sends AJAX `GET /transport-report?active_tab=route-performance&section=charts` → data is returned because `loadTabSection()` has no per-tab Gate check (only `index()` Gate is checked) | — | — | ⬜ |
| TC-N12 | Manual active_tab Param Without Permission | User with `tenant.transport.viewAny` but WITHOUT `tenant.route-performance.viewAny` navigates to `/transport-report?active_tab=route-performance` → page loads but route-performance tab pane is hidden by blade `@can`; however AJAX still fires via `loadTabSection()` on page init | — | — | ⬜ |
| TC-N13 | Negative Delay Values | If `reaching_time` is BEFORE `sch_arrival_time`, `diffInMinutes()` returns absolute value → negative delays never appear (all shown as positive) | — | — | ⬜ |
| TC-N14 | All Routes Inactive | All routes have `is_active = 0` → `->active()` scope returns empty → no data | — | — | ⬜ |
| TC-N15 | Single Date Value (No Range) | Send `dates=2026-01-15` (missing ` - ` separator) → `explode(' - ', ...)` returns single-element array → `$to` undefined → PHP warning | — | — | ⬜ |

### 6.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|----------------|---------|---------|--------|
| TC-D01 | A | Route Deletion Cascades to BoardingLog FK SET NULL | Route soft-deleted → `is_active = 0` → hidden from `active()` scope; boarding_log FK remains intact | — | — | ⬜ |
| TC-D02 | B | Eager Loading N+1 Prevention | `getRouteReport()` fires 1 main query + 4 eager loads = 5 queries total (1 routes + 1 allocations + 1 boardingLogs + 1 tripStopDetails + 1 trips); verify no lazy-loading inside map loop | — | — | ⬜ |
| TC-D03 | C | Shift Deletion Cascades to Routes (CASCADE) | Shift deleted → associated routes cascade deleted → routes hidden from `active()` scope → report shows fewer routes | — | — | ⬜ |
| TC-D04 | D | Unique Student Deduplication Correct | Student allocated to both pickup_route_id and drop_route_id on same route → counted once via `unique('student_id')` | — | — | ⬜ |
| TC-D05 | B | Academic Session Filter Indexing | [Query/Code Removed] | — | — | ⬜ |
| TC-D06 | B | Date Range Filter Performance | `boardingLogs` constrained eager load uses `WHERE trip_date BETWEEN ? AND ?` — verify `trip_date` column is indexed on tpt_student_boarding_log | — | — | ⬜ |
| TC-D07 | B | `reached_flag` Filter Performance | `tripStopDetails` constrained eager load uses `WHERE reached_flag = 1` — verify index exists on tpt_trip_stop_detail | — | — | ⬜ |
| TC-D08 | D | Student Allocation Without Boarding Log | Student allocated to route but has no boarding logs in date range → allocated > 0, boarded = 0; still counted in unique student count | — | — | ⬜ |
| TC-D09 | D | Student Boarding Log Without Allocation | Boarding log exists but student allocation was deleted → `studentAllocationsAll` returns empty → route still appears but with 0 allocation/boarding counts | — | — | ⬜ |
| TC-D10 | B | CDN Script Availability | Chart.js CDN unavailable → Chart.js `ReferenceError`; charts fail silently; table section still loads (separate AJAX call) | — | — | ⬜ |

### 6.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|-----------------|---------|---------|--------|
| TC-CR01 | CR | P1 | Gate Check Before Any Query | `index()` calls `Gate::authorize('tenant.transport.viewAny')` as first executable line (line 36) — before any data queries | — | — | ◌ |
| TC-CR02 | CR | P1 | Tab Permission Check In Blade | `@can('tenant.route-performance.viewAny')` wraps the entire tab include at line 23 of transportreport.blade.php | — | — | ◌ |
| TC-CR03 | CR | P1 | Default Date Range Fallback | `parseDateRange()` returns current month (`startOfMonth()` → `endOfMonth()`) when no `dates` parameter provided (line 334-335) | — | — | ◌ |
| TC-CR04 | CR | P1 | Division By Zero Guard | `boarding_compliance_pct` uses ternary `$allocated ? round(($boarded / $allocated) * 100, 2) : 0` at line 597 | — | — | ◌ |
| TC-CR05 | CR | P1 | Null Coalescing on Computed Fields | `avg_delay_minutes` in blade: `?? 0` defaults; summary cards use `?? 0` via `(float) null` cast | — | — | ◌ |
| TC-CR06 | CR | P1 | Collection Pagination Uses Correct Page Name | `paginateCollection()` uses `'page_route'` as pageName parameter at line 109 | — | — | ◌ |
| TC-CR07 | CR | P1 | AJAX Section Load Only Returns Partial | `loadTabSection()` returns JSON response with `html` key, not full page layout (line 92) | — | — | ◌ |
| TC-CR08 | CR | P1 | Undefined Variable Guard in Blade | `$summary` defaulted to `(object)[...0 defaults]` via `??` in blade at lines 6-11; `$routeReports` defaulted via `?? collect()` at line 228 | — | — | ◌ |
| TC-CR09 | CR | P2 | Chart.js Canvas Rendering — No Data | Canvas renders Chart.js with zero-value datasets when data is empty; no explicit empty-data fallback function exists in the blade | — | — | ◌ |
| TC-CR10 | CR | P1 | Filter Form Uses GET for Cacheability | Filter form uses `method="GET"` at line 299 for bookmarkable URLs | — | — | ◌ |
| TC-CR11 | CR | P1 | Active Scope Applied | `Route::active()` at line 574 ensures only `is_active = 1` routes are included | — | — | ◌ |
| TC-CR12 | CR | P2 | Controller Path Correctness | TC list originally referenced `Modules\Transport\Http\Controllers\TransportReportController` — actual path is `Modules\Transport\app\Http\Controllers\TransportReportController` (missing `app/` segment) | — | — | ◌ |
| TC-CR13 | CR | P2 | activityLog Not Required (Read-Only Report) | `TransportReportController` is a read-only report controller with no create/update/delete/destroy/restore/forceDelete methods — `activityLog()` calls are N/A and should NOT be added | — | — | ◌ |
| TC-CR14 | CR | P2 | No Per-Tab Gate in AJAX loadTabSection | `loadTabSection()` is private, called after `Gate::authorize('tenant.transport.viewAny')` in `index()`, but has no per-tab permission check for `tenant.route-performance.viewAny` — blade `@can` is the only barrier for route-performance tab data | — | — | ◌ |
| TC-CR15 | CR | P1 | Permission String Matches permissionslist.php | `tenant.route-performance.viewAny` used in blade matches exactly with `config/permissionslist.php` line 337 where `'route-performance' => $crud` | — | — | ◌ |
| TC-CR16 | CR | P1 | Section Merge Before View Render | `request()->merge(['section' => $section])` at line 101 ensures `request('section')` is available in the view for section routing | — | — | ◌ |
| TC-CR17 | CR | P2 | Summary Object Cast to stdClass | `$summary = (object)[...]` at lines 103-108 — properties accessed as `$summary->total_routes` in blade | — | — | ◌ |
| TC-CR18 | CR | P2 | [Query/Code Removed] | [Query/Code Removed] | — | — | ◌ |
| TC-CR19 | CR | P3 | Pagination Uses `appends(request()->query())` | Line 292 uses `$routeReportsPaginated->appends(request()->query())` — includes ALL query params but does NOT exclude the `page_route` param (no issue, Laravel handles this) | — | — | ◌ |
| TC-CR20 | CR | P2 | `paginateCollection()` Implementation | Lines 262-273: custom paginator that slices collection; resolves current page from `Paginator::resolveCurrentPage($pageName)` | — | — | ◌ |
| TC-CR21 | CR | P2 | Chart.js CDN Loaded From External Source | `transportreport.blade.php` line 68: `<script src="https://cdn.jsdelivr.net/npm/chart.js"></script>` — no fallback if CDN is blocked | — | — | ◌ |
| TC-CR22 | CR | P3 | Filter Reset Does Not Preserve active_tab | Reset link `<a href="{{ request()->url() }}"` at line 336 removes all query params including `active_tab`; default tab (`route-performance`) re-applied by `$activeTab` fallback | — | — | ◌ |
| TC-CR23 | CR | P2 | Route Performance Tab is Default | `$activeTab` defaults to `'route-performance'` at line 38 when no `active_tab` or `tab` param present | — | — | ◌ |

---

## 7. Code Trace (Full Execution Flow)

### 7.1 Entry Point: `index()` (line 34)



### 7.2 Tab Builder: `buildRoutePerformanceSection()` (line 99)



### 7.3 Data Method: `getRouteReport()` (line 561)



### 7.4 Chart Assembly (Blade — `index.blade.php`)



### 7.5 Table Assembly (Blade — `index.blade.php`)



### 7.6 Hub View JavaScript Flow



---

## 8. Detailed Test Steps

### TC-P01: Route Performance Tab Loads

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin with transport permissions | Dashboard loads |
| 2 | Navigate to Transport Report | URL: `/transport-report` |
| 3 | Click "Route Performance" tab | URL updates to `?active_tab=route-performance`; tab-pane visible with skeleton loaders |
| 4 | Check filter bar | Academic Session dropdown, Route dropdown, Vehicle dropdown, Shift dropdown, Date RangePicker, Search + Reset buttons |
| 5 | Verify two AJAX calls fire | Network tab shows calls to `/transport-report?active_tab=route-performance&section=charts` and `&section=table` |
| 6 | Verify charts section populates | 4 summary cards + 3 Chart.js canvases render |
| 7 | Verify table section populates | Table with 9 columns: Route, Stops, Allocated, Boarded, Unboarded, Boarding %, Unboarding %, Avg Delay, Status |
| 8 | Verify `loaded` CSS class added | `#route-performance-pane` has class `loaded` after initial load |
| 9 | Verify spinner disappears | Skeleton loader spinners replaced by actual content after AJAX success |
| 10 | Check CDN scripts loaded | Chart.js, Moment.js, daterangepicker scripts present in DOM |

### TC-P02: Charts Section Loads With Data

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure at least 3 routes exist with allocations and boarding logs | Data seeded |
| 2 | Click Route Performance tab | AJAX calls fire |
| 3 | Check Total Routes card | Displays count matching DB query |
| 4 | Check Allocated Students card | Displays sum of unique student allocations per route |
| 5 | Check Boarded Students card | Displays sum of boarding logs with non-null boarding_time |
| 6 | Check Avg Pickup Delay card | Displays rounded average delay across all routes |
| 7 | Verify Route Compliance chart | Line chart with Boarding Compliance % and Unboarding Compliance % datasets; filled area under lines |
| 8 | Verify Route Delay chart | Horizontal bar chart with color-coded bars per route; y-axis labels = route names |
| 9 | Verify Route Performance Overview chart | Grouped bar chart with Allocated/Boarded/Unboarded per route |
| 10 | Check Chart.js options | `responsive: true`, `maintainAspectRatio: false` set on all charts |

### TC-P03: Summary Cards Show Correct Aggregates

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Count total active routes in DB via `Route::active()->count()` | Total Routes card matches this count |
| 2 | Sum `allocated_students` across all route report objects | Allocated Students card shows matching sum |
| 3 | Sum `boarded_students` from boarding logs with non-null boarding_time | Boarded Students card shows matching sum |
| 4 | Calculate average of `avg_delay_minutes` across all routes manually | Avg Pickup Delay card shows matching value rounded to integer |
| 5 | Verify card icons | Each card has correct SVG icon: Total Routes (rectangle), Allocated (person), Boarded (checkmark), Avg Delay (clock) |
| 6 | Verify card colors | Total Routes = `text-bg-primary` (blue), Allocated = `text-bg-success` (green), Boarded = `text-bg-warning` (yellow), Avg Delay = `text-bg-danger` (red) |
| 7 | Verify "More info" links | Each card footer links to `route('transport.transport-master.index')` |

### TC-P04: Table Displays All Routes With Metrics

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Route Performance tab has data loaded | Table visible |
| 2 | Check Route column | Route name in `strong` tag with code in `small.text-muted` text below as "Code: {code}" |
| 3 | Check Stops column | Integer value from `pickupPointRoutes->count()` |
| 4 | Check Allocated column | Unique student count from `studentAllocationsAll->unique('student_id')->count()` |
| 5 | Check Boarded column | Count of boarding logs with non-null `boarding_time`; styled with `fw-semibold text-primary` |
| 6 | Check Unboarded column | Count of boarding logs with non-null `unboarding_time` |
| 7 | Check Boarding % column | Progress bar (8px height) + percentage; green bar for ≥90%, yellow for ≥75%, red for <75%; bar width clamped via `min(100)` |
| 8 | Check Unboarding % column | Same progress bar pattern as Boarding % |
| 9 | Check Avg Delay column | Badge with minutes: green `bg-success` ≤5min, yellow `bg-warning` ≤15min, red `bg-danger` >15min; 2 decimal places |
| 10 | Check Status column | Badge: `bg-success` for Excellent (≥90%), `bg-warning` for Good (≥75%) or Fair (≥60%), `bg-danger` for Poor (<60%) |

### TC-P05: Pagination Works

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure 11+ routes exist with data | 11+ records in seed |
| 2 | Load Route Performance tab | Table shows 10 rows (page 1) |
| 3 | Verify pagination links | Pagination bar below table with page numbers |
| 4 | Click page 2 | AJAX call fires with `&page_route=2` in query string |
| 5 | Verify page 2 data loads | Remaining routes displayed; page 2 highlighted |
| 6 | Go back to page 1 | AJAX call fires; first 10 routes shown |
| 7 | Verify pageName parameter | Request URL contains `page_route=1` (not `page=1`) |
| 8 | Apply filter then paginate | Filter + page number both preserved in URL |

### TC-P06: Filter By Route ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Load Route Performance tab | All routes shown |
| 2 | Select specific route from Route dropdown | Dropdown has `name="route_id"`; pre-populated from `$filters['routes']` |
| 3 | Click Search/Filter button | AJAX calls fire with `route_id={id}` |
| 4 | Verify charts show only selected route | Route Performance chart has 1 bar; Route Compliance has 1 line; Delay chart has 1 bar |
| 5 | Verify table shows only selected route | Table has 1 row matching selected route |
| 6 | Verify summary cards match single route | Total Routes = 1; other cards show values for single route |
| 7 | Verify URL reflects filter | No URL change (filter form uses AJAX, not page navigation) |
| 8 | Switch to "All Routes" option | All routes re-appear in charts and table |
| 9 | Verify backend query | [Query/Code Removed] |
| 10 | Test with non-existent route_id (e.g., 99999) | Empty collection; summary all 0; table shows "No data found" |

### TC-P07: Filter By Shift

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure routes exist under at least 2 shifts | Test data covers Shift A and Shift B |
| 2 | Select Shift A from dropdown | AJAX fires with `shift_id={shiftA_id}` |
| 3 | Verify only Shift A routes shown | Charts + table data filtered to Shift A routes |
| 4 | Switch to Shift B | Only Shift B routes shown |
| 5 | Clear shift filter | All routes shown again |
| 6 | Verify summary card values change | Total Routes reflects filtered count |
| 7 | Verify backend query | [Query/Code Removed] |
| 8 | Test shift with no associated routes | Shift dropdown shows the shift; selecting it yields empty report |

### TC-P08: Filter By Academic Session

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure allocations span 2 academic sessions | Test data covers Session 2025-26 and 2026-27 |
| 2 | Select Session 2025-26 from dropdown | AJAX fires with `academic_session_id={sessionId}` |
| 3 | Verify only routes with allocations in that session shown | [Query/Code Removed] |
| 4 | Switch to Session 2026-27 | Different set of routes (or empty if no allocations) |
| 5 | Verify summary cards reflect filtered data | Total Routes count matches filtered set |
| 6 | Test session with no transport allocations | Session shows in dropdown; selecting it yields empty report |
| 7 | Verify backend query is a subquery, NOT a join | `whereHas` performs correlated subquery — no join pollution on main Route query |
| 8 | Verify session filter combines with other filters | Academic Session + Route ID → intersection of both filters |

### TC-P09: Filter By Date Range

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Load default tab (current month) | Default data loaded |
| 2 | Open DateRangePicker | Calendar popup appears with range presets: Today, Last 7 Days, This Month, Last Month |
| 3 | Select "Last 7 Days" preset | Hidden `from_date`/`to_date` fields updated via callback; form auto-submits |
| 4 | Verify boarding logs constrained to last 7 days | Boarded/unboarded counts reflect only logs in that 7-day window |
| 5 | Select "This Month" preset | Data resets to current month range |
| 6 | Select "Last Month" preset | Data switches to previous month |
| 7 | Select custom range via calendar | Custom start/end dates applied via `moment().startDate` / `moment().endDate` |
| 8 | Verify daterangepicker locale | Format: `YYYY-MM-DD`; `opens: 'left'`; `autoApply: true` |
| 9 | Verify backend date constraint | [Query/Code Removed] |
| 10 | Compare boarded counts between different date ranges | Wider range → more boarding logs → higher boarded/unboarded counts |

### TC-P10: Chart Grouped/Stacked Toggle

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Load Route Performance tab with multi-route data | Route Performance Overview chart visible with multiple bars |
| 2 | Verify default state | "Grouped" radio checked (`#groupedViewRoute`); chart shows grouped bars side-by-side per route |
| 3 | Click "Stacked" radio (`#stackedViewRoute`) | Chart redraws: Allocated + Boarded + Unboarded bars stack per route; `performanceChart.options.scales.x.stacked = true; performanceChart.options.scales.y.stacked = true; performanceChart.update()` |
| 4 | Verify stacked bar totals | Each route's stacked bar shows total = allocated (boarded + unboarded overlap may not equal allocated) |
| 5 | Click "Grouped" radio again | Chart returns to grouped bars; stacked = false |
| 6 | Verify toggle buttons styling | Both use `btn-outline-primary`; selected has `active` state via Bootstrap `.btn-check` |
| 7 | Verify Chart.update() is called | Chart redraws without page reload — no AJAX involved |
| 8 | Switch tabs and return | Toggle state resets (chart re-initialized from fresh AJAX response) |

### TC-P11: Reset Filters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Apply route filter + shift filter | Filters active; URL has query params |
| 2 | Click Reset button (`<a href="{{ request()->url() }}">`) | URL cleared of all query params; page reloads |
| 3 | Verify all dropdowns reset to default (blank/All) | All `<select>` show "All Sessions", "Route", "Vehicle", "Shift" |
| 4 | Verify date range reset to current month | Daterangepicker shows current month range |
| 5 | Verify data reloads with defaults | Charts + table show unfiltered data |

### TC-P12: Full Lifecycle — All Filters Combined

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select Route A from dropdown | `route_id` set to Route A's ID |
| 2 | Select Shift A from dropdown | `shift_id` set to Shift A's ID |
| 3 | Select Session 2025-26 | `academic_session_id` set |
| 4 | Set date range to current month | `dates` range set; hidden `from_date`/`to_date` updated |
| 5 | Click Search/Filter button | Single form submit triggers 2 AJAX calls (charts + table) |
| 6 | Verify AJAX request payload | Query params include `route_id`, `shift_id`, `academic_session_id`, `dates`, `active_tab=route-performance`, `section=charts`/`section=table` |
| 7 | Verify combined filtering | Only Route A + Shift A + Session 2025-26 data within date range shown |
| 8 | Verify charts + table consistency | Chart labels match table route names; counts match |
| 9 | Verify summary cards reflect combined filter | Total Routes = 1 (only Route A); other KPIs computed from filtered data |
| 10 | Remove one filter (e.g., shift_id) | Results expand to include routes matching remaining filters |
| 11 | Paginate filtered results | Page 2 of filtered data loads via `page_route` param |
| 12 | Navigate away and back | Filters are NOT persisted (no session storage); page reloads with defaults |

### TC-P13: Route With 100% Boarding Compliance

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed route with 3 students, all having `boarding_time` set in boarding_logs | Route has `boarding_compliance_pct = 100%` |
| 2 | Load Route Performance tab | Route appears in table |
| 3 | Check Allocated vs Boarded counts | Both columns show same number (all allocated students boarded) |
| 4 | Check Boarding % column | Progress bar at 100% width; green `bg-success` color; "100%" label displayed |
| 5 | Check Status column | Badge shows "Excellent" with green `bg-success` class |
| 6 | Check Route Compliance chart | Route's Boarding Compliance % data point at 100 on Y-axis |
| 7 | Check Unboarding % | Shows percentage of students who also unboarded (may differ) |
| 8 | Verify progress bar width clamped correctly | `min(100, 100) = 100` — full width |

### TC-P14: Route With 0% Boarding Compliance

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed route with 3 students allocated, but NO boarding_logs within the current date range | Route has `boarding_compliance_pct = 0%` |
| 2 | Load Route Performance tab | Route appears in table |
| 3 | Check Allocated column | Shows 3 (students still allocated to route) |
| 4 | Check Boarded column | Shows 0 (no boarding logs within date range) |
| 5 | Check Boarding % column | Progress bar at 0% width; red `bg-danger` color; "0%" label |
| 6 | Check Status column | Badge shows "Poor" with red `bg-danger` class |
| 7 | Check Route Compliance chart | Route's Boarding Compliance % data point at 0 on Y-axis |
| 8 | Check Unboarding % | Also 0% (no unboarding logs either) |
| 9 | Verify progress bar renders correctly at 0 width | Bar is invisible (no width), but container still visible |

### TC-P15: Route With Zero Allocations

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed route with no student allocations | Route has `allocated_students = 0` |
| 2 | Load Route Performance tab | Route appears in table |
| 3 | Check Allocated column | Shows 0 |
| 4 | Check Boarded, Unboarded columns | Both show 0 |
| 5 | Check Boarding % column | Shows 0%; no division by zero error |
| 6 | Check Avg Delay column | Shows 0 min (no trip stop details to average) |

### TC-P16: Avg Delay Card Rounds Correctly

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed 3 routes with trip stop delays: 2.456min, 5.789min, 10.123min | Route averages computed via `diffInMinutes()` |
| 2 | Load Route Performance tab | Avg Pickup Delay card shows `{{ round($summary->avg_pickup_delay) }}` — "6 min" |
| 3 | Verify Avg Pickup Delay precision | `round((float)($routeReports->avg('avg_delay_minutes') ?? 0), 2)` → 6.12 → `round(6.12)` → 6 (integer cast in blade) |
| 4 | Verify individual route delays in table | Each row shows 2 decimal places: "2.46 min", "5.79 min", "10.12 min" |
| 5 | Verify delay badge colors | 2.46min → green `bg-success`; 5.79min → yellow `bg-warning`; 10.12min → yellow `bg-warning` (≤15 threshold) |
| 6 | Verify calculation formula | `$detail->reaching_time->diffInMinutes($detail->sch_arrival_time)` — absolute difference, always positive |

### TC-P17: Compliance Chart Shows Two Datasets

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Load Route Performance tab with data | Route Compliance chart visible |
| 2 | Verify dataset labels | Legend shows "Boarding Compliance %" (green line) and "Unboarding Compliance %" (blue line) |
| 3 | Verify fill property | Lines have semi-transparent fill below (`backgroundColor: rgba(..., 0.1)`) |
| 4 | Verify tension | `tension: 0.3` — lines are slightly curved |
| 5 | Verify Y-axis | Range 0-100; ticks formatted with "%" suffix |

### TC-P18: Delay Chart Color-Coding

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed 3 routes with trip stop detail delays: route1=2min avg, route2=10min avg, route3=30min avg | Routes have clearly distinct delay levels |
| 2 | Load Route Performance tab | Route Delay Analysis chart visible under "Route Delay Analysis" card header |
| 3 | Verify route1 bar color | Green `rgba(40, 167, 69, 0.8)` with border `rgba(40, 167, 69, 1)` — threshold ≤5min |
| 4 | Verify route2 bar color | Yellow/amber `rgba(255, 193, 7, 0.8)` with border `rgba(255, 193, 7, 1)` — threshold >5 and ≤15min |
| 5 | Verify route3 bar color | Red `rgba(220, 53, 69, 0.8)` with border `rgba(220, 53, 69, 1)` — threshold >15min |
| 6 | Verify color mapping in source code | `delayData.map(d => d <= 5 ? 'rgba(40,167,69,0.8)' : d <= 15 ? 'rgba(255,193,7,0.8)' : 'rgba(220,53,69,0.8)')` at line 205 of index.blade.php |
| 7 | Verify chart orientation | Horizontal bars via `indexAxis: 'y'` option — route names on Y-axis, delay minutes on X-axis |
| 8 | Verify chart type | `type: 'bar'` (horizontal bar) |
| 9 | Verify no legend displayed | `legend: { display: false }` — single dataset, label is "Average Delay (minutes)" |
| 10 | Verify X-axis title | `title: { display: true, text: 'Delay (minutes)' }` |
| 11 | Verify Y-axis grid lines | `grid: { display: false }` — cleaner look for horizontal bars |
| 12 | Verify bar border radius | `borderRadius: 4` — subtle rounded corners on each bar |
| 13 | Verify `beginAtZero: true` | X-axis starts at 0, no negative delay values possible |

### TC-P19: Tab Persists After Filter Submit

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Load Transport Report page | Default tab is route-performance; no active_tab in URL initially |
| 2 | Apply a filter (e.g., select shift from dropdown) | Filter form submit handler at lines 124-131 fires |
| 3 | Inspect AJAX request payload via Network tab | `active_tab=route-performance` included in query data alongside filter params |
| 4 | Check browser URL after AJAX filter | URL remains `/transport-report` — no pushState or location change |
| 5 | Navigate to another tab (e.g., Trip Execution) then return to Route Performance | Route Performance tab loads via AJAX (may use cache if `loaded` class present) |
| 6 | Verify previously applied filters are preserved | Filters are NOT preserved in session — page reload resets all filters to defaults |
| 7 | Verify daterangepicker auto-submit preserves active_tab | Daterangepicker callback submits form; form has `<input type="hidden" name="active_tab" value="route-performance">` |

### TC-P20: Vehicle Filter Constrains Trips Only

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed route with trips under 2 different vehicles | Route has Vehicle A: 3 trips with delays 2/3/4min; Vehicle B: 2 trips with delays 20/25min |
| 2 | Load Route Performance tab without vehicle filter | All 5 trips considered; avg_delay computed from all trip stop details |
| 3 | Select Vehicle A from vehicle dropdown | AJAX fires with `vehicle_id={vehicleA_id}` |
| 4 | Verify route still appears in table | Vehicle filter constrains `trips` eager load (line 567), NOT the Route query — route remains visible |
| 5 | Verify delay reflects Vehicle A only | Delay computed only from Vehicle A's 3 trips → ~3min avg |
| 6 | Select Vehicle B | Route still appears; delay computed from Vehicle B's 2 trips → ~22.5min avg |
| 7 | Clear vehicle filter (select "Vehicle" blank option) | All 5 trips considered again; delay returns to combined average |
| 8 | Verify no routes hidden by vehicle filter | Vehicle filter cannot hide routes — all active routes always appear |

### TC-N01: No Routes In Date Range

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to Route Performance tab | Tab loaded |
| 2 | Set date range to period with no boarding data | e.g., last year or future date |
| 3 | Click Search | AJAX reloads charts and table |
| 4 | Check summary cards | All 4 cards show 0 |
| 5 | Check table | "No route performance data found" empty state with inbox icon |
| 6 | Check charts | Canvas elements render Chart.js with zero-value datasets; no explicit empty-data message is shown |
| 7 | Check table colspan | Empty row uses `colspan="9"` matching 9 header columns |

### TC-N02: No Route Allocations

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed route with active status but no student allocations | Route exists, `is_active = 1` |
| 2 | Load Route Performance tab | Route appears in table |
| 3 | Check Allocated column | Shows 0 |
| 4 | Check Boarding % column | Shows 0% (division by zero guard at line 597: `$allocated ? ... : 0`) |
| 5 | Check charts | Route appears in chart labels with 0 values for all datasets |

### TC-N03: Invalid Date Range Format

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open browser DevTools Network tab | Ready to inspect |
| 2 | Submit filter with malformed date: `dates=not-a-date` | AJAX call sends malformed date |
| 3 | Observe response | [Query/Code Removed] |
| 4 | Check error message container | "Failed to load charts." / "Failed to load table." displayed |
| 5 | Verify no data corruption | App still functional; other tabs unaffected |

### TC-N04: Non-Numeric Filter IDs

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit filter with `route_id=abcde` | AJAX call sends `route_id=abcde` |
| 2 | Observe SQL query | Eloquent generates `WHERE id = 'abcde'` — no matching route; empty result |
| 3 | Verify empty state | Table shows "No route performance data found" |
| 4 | Submit filter with `shift_id=xyz` | Same behavior — empty result |

### TC-N05: Very Large Date Range

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set date range spanning 5 years | daterangepicker allows multi-year selection |
| 2 | Click Search | AJAX fires; backend processes large date range |
| 3 | Check response time | May be slow if boarding_logs table has millions of rows across 5 years |
| 4 | Verify data correctness | Aggregations computed correctly across full range (no partial data) |
| 5 | Check memory usage | Large collection may cause memory pressure — `getRouteReport()` loads ALL records into memory |

### TC-N06: Permission 403 — No transport.viewAny

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user WITHOUT `tenant.transport.viewAny` | Dashboard loads |
| 2 | Navigate to `/transport-report` | 403 Forbidden |
| 3 | Try direct AJAX to `/transport-report?active_tab=route-performance&section=charts` | 403 Forbidden |
| 4 | Verify Gate check occurs before any query | `Gate::authorize()` at line 36 is first executable line; no DB queries execute |
| 5 | Login as user WITH `tenant.transport.viewAny` but WITHOUT `tenant.route-performance.viewAny` | Dashboard loads |
| 6 | Navigate to `/transport-report` | Page loads but "Route Performance" tab is hidden from tab bar |

### TC-N07: Tab Hidden — No route-performance.viewAny

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user with `tenant.transport.viewAny` but WITHOUT `tenant.route-performance.viewAny` | Dashboard loads |
| 2 | Navigate to `/transport-report` | Page loads; tab bar does not show "Route Performance" tab |
| 3 | Inspect tab-pane element | `#route-performance-pane` exists in DOM but is hidden (not rendered by `@can`) |
| 4 | Manually add `?active_tab=route-performance` to URL | Page loads; default tab shown instead; AJAX does NOT fire for route-performance |
| 5 | Attempt direct AJAX via browser console | `loadTabSection('route-performance', 'charts')` — data returned (no server-side per-tab Gate check) |

### TC-N08: Guest Access

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Logout of application | Redirected to login page |
| 2 | Navigate directly to `/transport-report` | Redirected to `/login` |
| 3 | Navigate to `/transport-report?active_tab=route-performance` | Redirected to `/login` |
| 4 | Attempt AJAX call without auth cookie | 401 Unauthorized or redirect to login |

### TC-N09: AJAX Error Handling

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Simulate server error (e.g., make DB unavailable) | Server error |
| 2 | Trigger AJAX load via tab click | AJAX error handler fires |
| 3 | Check charts container | Shows `<div class="alert alert-danger">Failed to load charts.</div>` |
| 4 | Check table container | Shows `<div class="alert alert-danger">Failed to load table.</div>` |
| 5 | Restore server and refresh | Normal data loads |

### TC-N10: Empty Route Name in Chart Labels

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed route with `name = null` or `name = ''` | Route record has empty/short name |
| 2 | Load Route Performance tab | Chart renders without JS error |
| 3 | Check chart labels | Empty string appears as label (no crash, legend shows blank entry) |
| 4 | Check table | Route column shows empty `strong` tag; code shown below |

### TC-N11: AJAX Bypass — Tab Permission Not Checked Server-Side

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user with `tenant.transport.viewAny` but WITHOUT `tenant.route-performance.viewAny` | Tab hidden in UI |
| 2 | Open browser DevTools Console | Ready to execute JS |
| 3 | Manually call `loadTabSection('route-performance', 'charts')` | AJAX fires |
| 4 | Check response | **Data returned** — `loadTabSection()` at line 73 does NOT check `tenant.route-performance.viewAny` |
| 5 | Verify security impact | User can see route performance data despite not having the permission via the blade `@can` guard |
| 6 | Document as known limitation | No per-tab Gate check in `loadTabSection()` — only master `tenant.transport.viewAny` Gate in `index()` |

### TC-N12: Manual active_tab Param Without Permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user with `tenant.transport.viewAny` but WITHOUT `tenant.route-performance.viewAny` | Dashboard loads |
| 2 | Navigate to `/transport-report?active_tab=route-performance` | Page loads; route-performance tab-pane is hidden by blade `@can` |
| 3 | Observe AJAX calls | `loadTabSection()` still fires on page init (lines 107-108) for both charts and table |
| 4 | Check network tab | AJAX calls to `section=charts` and `section=table` return data because `loadTabSection()` lacks per-tab permission check |
| 5 | Verify hidden content in DOM | Though tab-pane is hidden, the returned HTML is injected into `#route-performance-charts` and `#route-performance-table` — data is in DOM but visually hidden |

### TC-N13: Negative Delay Values

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed route with trip stop detail where `reaching_time` is BEFORE `sch_arrival_time` (e.g., arrived 5 minutes early) | `diffInMinutes()` returns 5 (absolute value) |
| 2 | Load Route Performance tab | Route shows `avg_delay_minutes = 5.00` (positive, not -5) |
| 3 | Verify this is technically incorrect | `diffInMinutes()` in Carbon returns absolute difference — early arrival should show 0 or negative, but shows positive |
| 4 | Check if early arrival could be misreported | A route that consistently arrives early appears as "delayed" by the absolute difference |

### TC-N14: All Routes Inactive

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set all routes to `is_active = 0` | No active routes |
| 2 | Load Route Performance tab | `getRouteReport()` returns empty collection (active() scope filters all out) |
| 3 | Check summary cards | All 4 cards show 0 |
| 4 | Check table | "No route performance data found" |
| 5 | Check charts | Canvas renders with empty datasets |

### TC-N15: Single Date Value (No Range)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit filter with `dates=2026-01-15` (no ` - ` separator) | `explode(' - ', $request->dates, 2)` returns `['2026-01-15']` |
| 2 | Check PHP behavior | [Query/Code Removed] |
| 3 | Observe error | PHP warning "Undefined array key 1" → 500 error or warning depending on error_reporting |
| 4 | Verify this is a code defect | `parseDateRange()` expects `{from} - {to}` format but has no validation for missing separator |
| 5 | Check if front-end prevents this | DateRangePicker always sends a properly formatted range; but raw API calls could trigger this |

### TC-D01: Route Deletion Cascades to BoardingLog FK SET NULL

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed route with allocations, boarding logs, and trip stop details | All related records exist |
| 2 | Soft-delete the route (`$route->delete()`) | Route `deleted_at` set; `is_active` may still be 1 |
| 3 | Check if route appears in report | `active()` scope checks `is_active`, NOT `deleted_at` — if `is_active = 1`, route still appears |
| 4 | Verify boarding_log FK behavior | `boarding_log.boarding_route_id` is NOT SET to null by soft delete (route is not hard-deleted) |
| 5 | Force-delete the route | `boarding_log.boarding_route_id` becomes NULL if FK is SET NULL; route disappears from report |
| 6 | Check report after force-delete | Missing route handled gracefully by lookup (no broken page)

### TC-D02: Eager Loading N+1 Prevention

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enable SQL query logging | `DB::enableQueryLog()` |
| 2 | Load Route Performance tab | `getRouteReport()` executes |
| 3 | Count total queries | Expect 1 (routes) + 4 eager loads (allocations, boardingLogs, tripStopDetails, trips) = 5 queries total |
| 4 | Verify no lazy-loading inside map loop | The `map()` closure accesses `$route->studentAllocationsAll`, `$route->boardingLogs`, `$route->tripStopDetails`, `$route->pickupPointRoutes` — all already eager-loaded; no additional queries |
| 5 | Check for N+1 on shift relationship | `$route->shift` is NOT eager-loaded in `getRouteReport()` — if accessed, triggers N+1; check if blade accesses it |

### TC-D03: Shift Deletion Cascades to Routes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed shift with 2 active routes | Both routes linked to same shift |
| 2 | Delete the shift | If FK has CASCADE, routes deleted; if SET NULL, `shift_id = NULL` |
| 3 | Check report after deletion | If CASCADE: routes gone; if SET NULL: routes still appear (shift_id null doesn't break query) |
| 4 | Verify `active()` scope behavior | Route's `is_active` field determines visibility, not shift_id |

### TC-D04: Unique Student Deduplication Correct

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Allocate Student A to Route X as BOTH pickup AND drop (2 records in `TptStudentAllocationJnt`) | Student A appears twice in `studentAllocationsAll` |
| 2 | Load Route Performance tab | Route X shows `allocated_students = 1` (deduplicated via `unique('student_id')`) |
| 3 | If Student A also has 1 boarding log, verify `boarded_students = 1` | Also deduplicated via `unique('student_id')` |
| 4 | Remove `unique('student_id')` concept (note: cannot modify code) | Without dedup, would show `allocated = 2` — incorrect |

### TC-D05: Academic Session Filter Indexing

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check DB schema for `tpt_student_route_allocation_jnt` | Verify if index exists on `student_session_id` column |
| 2 | If no index, run EXPLAIN on the `whereHas` subquery | Full table scan on `tpt_student_route_allocation_jnt` |
| 3 | If indexed, verify index usage | `whereHas` subquery uses index for faster filtering |

### TC-D06: Date Range Filter Performance

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check DB schema for `tpt_student_boarding_log` | Verify if index exists on `trip_date` column |
| 2 | If no index, explain query plan | `WHERE trip_date BETWEEN ? AND ?` triggers full table scan |
| 3 | Test with 50k+ boarding log records | Query performance degrades without index |

### TC-D07: `reached_flag` Filter Performance

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check DB schema for `tpt_trip_stop_detail` | Verify if index exists on `reached_flag` column |
| 2 | Assess selectivity | `reached_flag = 1` is high-selectivity if most records are flagged; index may not help much |
| 3 | Consider composite index | `(trip_id, reached_flag)` or `(route_id, reached_flag)` may be more beneficial |

### TC-D08: Student Allocation Without Boarding Log

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Allocate Student A to Route X | No boarding log created for Student A |
| 2 | Load Route Performance tab | Route X shows: allocated=1, boarded=0, unboarded=0 |
| 3 | Verify compliance | `boarding_compliance_pct = 0%`; Status = "Poor" |

### TC-D09: Student Boarding Log Without Allocation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create boarding log for Student A on Route X | But Student A has no allocation record for Route X |
| 2 | Load Route Performance tab | `studentAllocationsAll` does not include Student A; boarding logs filtered by `boarding_route_id` relationship |
| 3 | Check behavior | Route X: allocated=0 (no matching allocations), boarded=0 (boarding logs filtered by route relationship — no matching student in unique set due to empty allocations) |
| 4 | Verify route still appears | Route appears with 0s for all metrics |

### TC-D10: CDN Script Unavailability

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Block CDN domain (`cdn.jsdelivr.net`) in browser DevTools | Chart.js fails to load |
| 2 | Load Transport Report page | Page loads without JS errors for non-chart content |
| 3 | Click Route Performance tab | Filter bar and structure load; charts section shows empty/spinner area |
| 4 | Check console | `ReferenceError: Chart is not defined` |
| 5 | Verify table still loads | Table section is separate AJAX call; table HTML and pagination work despite Chart.js failure |

### TC-CR01: Gate Check Before Any Query

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `index()` method | `Gate::authorize('tenant.transport.viewAny')` at line 36 is the very first executable statement (after method signature + variable declarations) |
| 2 | Confirm no DB queries execute before Gate | No `DB::query()`, `Model::...`, or `->get()` calls appear before line 36 |
| 3 | Code | ✅ PASS — Gate is first check |

### TC-CR02: Tab Permission Check In Blade

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `transportreport.blade.php` | `@can('tenant.route-performance.viewAny')` at line 23 wraps `@include('transport::report.route-performance.index')` |
| 2 | Confirm closing directive | `@endcan` at line 25 matches `@can` (not `@endcanany`) |
| 3 | Confirm permission string | `tenant.route-performance.viewAny` matches `config/permissionslist.php` line 337 |

### TC-CR03: Default Date Range Fallback

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `parseDateRange()` | Line 329: `if ($request->filled('dates'))` — when false, falls to else block |
| 2 | Confirm default values | Line 334: `now()->startOfMonth()->toDateString()`; Line 335: `now()->endOfMonth()->toDateString()` |
| 3 | Code | ✅ PASS — current month fallback |

### TC-CR04: Division By Zero Guard

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `getRouteReport()` | Line 597: `boarding_compliance_pct = $allocated ? round(($boarded / $allocated) * 100, 2) : 0` |
| 2 | Review unboarding | Line 598: same pattern for `unboarding_compliance_pct` |
| 3 | Code | ✅ PASS — ternary prevents division by zero |

### TC-CR05: Null Coalescing on Computed Fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review avg delay | Line 596: `round((float) $avgDelay, 2)` — `avg()` returns null on empty collection; `(float) null` casts to 0.0 |
| 2 | Review summary | Line 107: `$routeReports->avg('avg_delay_minutes') ?? 0` — null coalescing on avg result |
| 3 | Code | ✅ PASS — null safety via type casting and ?? operator |

### TC-CR06: Collection Pagination Uses Correct Page Name

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `buildRoutePerformanceSection()` | Line 109: `$this->paginateCollection($routeReports, 10, 'page_route')` |
| 2 | Review `paginateCollection()` | Line 264: `$page = Paginator::resolveCurrentPage($pageName)` — uses the provided page name |
| 3 | Code | ✅ PASS — `page_route` used consistently |

### TC-CR07: AJAX Section Load Only Returns Partial

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `loadTabSection()` | Line 92: `return response()->json(['html' => $html])` — returns JSON, not full view |
| 2 | Confirm no layout wrapper in partial | `index.blade.php` starts with `@if(request('section') === 'charts')` — NO `<x-backend.layouts.app>` wrapper |
| 3 | Code | ✅ PASS — partial HTML wrapped in JSON response |

### TC-CR08: Undefined Variable Guard in Blade

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review blade | Line 6-11: `$summary = $summary ?? (object)[...0 defaults]` |
| 2 | Review blade | Line 228: `$routeReports = $routeReports ?? collect()` |
| 3 | Code | ✅ PASS — null coalescing guards against undefined variables |

### TC-CR09: Chart.js Canvas Rendering — No Data

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review blade chart JS | Lines 149-155: `@json($routeLabels)`, `@json($allocatedData)`, etc. — if routeReports empty, all are empty arrays `[]` |
| 2 | No explicit empty-data check | No `if (routeLabels.length === 0) { showEmptyMessage(); }` before Chart constructor |
| 3 | Code | ⚠️ Chart constructor runs even when labels/datasets are empty; Chart.js renders with no error but zero-height canvas |

### TC-CR10: Filter Form Uses GET for Cacheability

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review blade | Line 299: `<form class="transport-filter-form d-flex align-items-center flex-wrap gap-2" method="GET">` |
| 2 | Confirm no POST methods for filter | Filter form uses GET; pagination links also use GET |
| 3 | Code | ✅ PASS — GET method for filter form |

### TC-CR11: Active Scope Applied

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `getRouteReport()` | Line 574: `->active()` |
| 2 | Confirm scope definition | `Route` model has `scopeActive()` filtering `is_active = 1` |
| 3 | Code | ✅ PASS — active scope ensures only enabled routes |

### TC-CR12: Controller Path Correctness

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Verify actual file path | `Modules\Transport\app\Http\Controllers\TransportReportController.php` |
| 2 | Check if old docs reference wrong path | Some documentation references `Modules\Transport\Http\Controllers\TransportReportController` (missing `app/` segment) |
| 3 | Code | ⚠️ DOCs MISMATCH — update references to include `app/` segment |

### TC-CR13: activityLog Not Required (Read-Only Report)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review all controller methods | `index()`, `loadTabSection()`, `buildRoutePerformanceSection()`, `getRouteReport()` — all read-only |
| 2 | No create/update/delete/destroy/restore/forceDelete | Controller has no mutation methods |
| 3 | Code | ✅ PASS — activityLog N/A for read-only report |

### TC-CR14: No Per-Tab Gate in AJAX loadTabSection

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `loadTabSection()` | Lines 73-92 — no `Gate::authorize()` call for the specific tab |
| 2 | Confirm security reliance | Only `Gate::authorize('tenant.transport.viewAny')` in `index()` protects AJAX access |
| 3 | Code | ⚠️ SECURITY GAP — `loadTabSection()` should verify per-tab permission before returning tab data |

### TC-CR15: Permission String Matches permissionslist.php

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check blade permission string | `@can('tenant.route-performance.viewAny')` |
| 2 | Check `config/permissionslist.php` | Line 337: `'route-performance' => $crud` — $crud includes 'viewAny' |
| 3 | Resulting permission | `tenant.route-performance.viewAny` — matches blade string exactly |

### TC-CR16: Section Merge Before View Render

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `buildRoutePerformanceSection()` | Line 101: `request()->merge(['section' => $section])` — merges section into request before view |
| 2 | Confirm view uses `request('section')` | Blade line 1: `@if(request('section') === 'charts')` — uses merged section value |
| 3 | Code | ✅ PASS — section merge ensures correct partial rendering |

### TC-CR17: Summary Object Cast to stdClass

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review summary construction | Lines 103-108: `$summary = (object)[...]` — PHP array cast to stdClass |
| 2 | Confirm blade property access | `$summary->total_routes`, `$summary->total_students`, etc. |
| 3 | Code | ✅ PASS — object properties accessible in blade |

### TC-CR18: `parseDateRange()` Lacks Try/Catch

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `parseDateRange()` | Lines 327-339 — no try/catch block |
| 2 | Carbon parse behavior | [Query/Code Removed] |
| 3 | Code | ⚠️ FRAGILE — malformed date causes 500 error |

### TC-CR19: Pagination Uses `appends(request()->query())`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review pagination | Line 292: `$routeReportsPaginated->appends(request()->query())->links()` |
| 2 | Confirm no double-encoding | `appends()` with full query string passes all params; Laravel handles internal page param correctly |
| 3 | Code | ✅ PASS — preserves all query params during pagination |

### TC-CR20: `paginateCollection()` Implementation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review method | Lines 262-273: custom paginator for in-memory collections |
| 2 | Resolve current page | `Paginator::resolveCurrentPage($pageName)` — resolves `?page_route=N` |
| 3 | Slice logic | `$items->slice(($page - 1) * $perPage, $perPage)` — proper offset |
| 4 | Path resolution | `Paginator::resolveCurrentPath()` — uses current URL path |
| 5 | Code | ✅ PASS — standard custom collection paginator pattern |

### TC-CR21: Chart.js CDN Loaded From External Source

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review hub view | Line 68: `<script src="https://cdn.jsdelivr.net/npm/chart.js"></script>` |
| 2 | No fallback script | No inline copy or alternate CDN source provided |
| 3 | Code | ⚠️ CDN DEPENDENCY — page relies on external CDN availability for chart rendering |

### TC-CR22: Filter Reset Does Not Preserve active_tab

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review reset link | Line 336: `<a href="{{ request()->url() }}"` — `request()->url()` returns URL without query string |
| 2 | Verify active_tab loss | After reset, `active_tab` is removed; `$activeTab` defaults to `'route-performance'` at line 38 |
| 3 | Code | ✅ PASS (minor) — default tab is route-performance, so no functional issue |

### TC-CR23: Route Performance Tab is Default

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review activeTab default | Line 38: `$activeTab = $request->get('active_tab') ?: $request->get('tab', 'route-performance')` |
| 2 | No active_tab in URL | Defaults to `'route-performance'` |
| 3 | Code | ✅ PASS — route-performance is the default active tab |

### TC-CR24: Section Routing Via request('section') in Blade

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review blade section logic | Line 1: `@if(request('section') === 'charts')` — renders charts partial |
| 2 | Review table section logic | Line 226: `@elseif(request('section') === 'table')` — renders table partial |
| 3 | Review default case | Line 295: `@else` — renders tab-pane with filter bar + skeleton loaders |
| 4 | Backward compatibility | If `section` param is missing entirely, default tab-pane with skeleton loaders renders |

### TC-CR25: Chart.js Canvas IDs Are Unique

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check canvas ID for performance chart | `routePerformanceChart` — unique across the hub view |
| 2 | Check canvas ID for compliance chart | `routeComplianceChart` — unique across the hub view |
| 3 | Check canvas ID for delay chart | `routeDelayChart` — unique across the hub view |
| 4 | Verify no other tab uses same IDs | Each tab has its own unique chart canvas IDs to prevent duplicate ID conflicts |

### TC-CR26: Skeleton Loader Present on Initial Load

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review default tab-pane case | Lines 342-350: `#route-performance-charts` and `#route-performance-table` divs contain spinner-border |
| 2 | Spinner markup | `<div class="spinner-border text-primary" role="status"><span class="visually-hidden">Loading...</span></div>` |
| 3 | Spinner replaced on AJAX success | `loadTabSection` success callback: `container.html(res.html)` — spinner replaced by actual content |
| 4 | Spinner removed on error | Error callback: `container.html('<div class="alert alert-danger">Failed to load...</div>')` — spinner replaced by error |

### TC-CR27: Chart.js Responsive Configuration Verified

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review performance chart options | `responsive: true, maintainAspectRatio: false` at line 169 |
| 2 | Review compliance chart options | `responsive: true, maintainAspectRatio: false` at line 192 |
| 3 | Review delay chart options | `responsive: true, maintainAspectRatio: false` at line 211 |
| 4 | Purpose | Charts resize with browser window; `maintainAspectRatio: false` allows chart container to control height |

---

## 9. API Contract (AJAX Response Shape)

### 9.1 Charts Section Response

When `section=charts`, the AJAX response returns JSON:


The HTML payload contains:
- 4 summary cards in a `.row.g-3.mt-2` grid
- 3 chart cards in `.row.mt-4` grid each containing a `<canvas>` element
- Inline `<script>` block with Chart.js initialization using `@json`-serialized PHP data

**Data contract (embedded in script):**
| JS Variable | Source | Type |
|-------------|--------|------|
| `routeLabels` | `$routeReports->pluck('name')` | `string[]` |
| `allocatedData` | `$routeReports->pluck('allocated_students')` | `int[]` |
| `boardedData` | `$routeReports->pluck('boarded_students')` | `int[]` |
| `unboardedData` | `$routeReports->pluck('unboarded_students')` | `int[]` |
| `boardingPercentData` | `$routeReports->pluck('boarding_compliance_pct')` | `float[]` |
| `unboardingPercentData` | `$routeReports->pluck('unboarding_compliance_pct')` | `float[]` |
| `delayData` | `$routeReports->pluck('avg_delay_minutes')` | `float[]` |

### 9.2 Table Section Response

When `section=table`, the AJAX response returns JSON:


The HTML payload contains:
- `<table>` with 9-column `<thead>` and `<tbody>` with route rows
- Pagination links (`$routeReportsPaginated->appends(request()->query())->links()`)
- Empty state when no data: `colspan=9` row with inbox icon

### 9.3 Error Response

On server error:


On AJAX transport error (client-side):


### 9.4 HTTP Status Codes

| Scenario | Status Code | Response Body |
|----------|-------------|---------------|
| Success (charts) | 200 | `{ "html": "..." }` |
| Success (table) | 200 | `{ "html": "..." }` |
| Unauthenticated | 302 | Redirect to `/login` |
| Forbidden (no transport.viewAny) | 403 | Laravel 403 page |
| Server Error (malformed date) | 500 | Laravel debug page (if APP_DEBUG=true) or generic error |
| Validation Error | 419 | Page expired (CSRF not applicable for GET AJAX) |

---

## 10. Environment & Configuration Matrix

| ENV ID | Variable | Expected Value | Impact |
|--------|----------|----------------|--------|
| ENV-01 | `APP_DEBUG` | `true` in dev, `false` in prod | Controls whether Carbon parse errors show debug trace |
| ENV-02 | `DB_CONNECTION` | `mysql` (or configured tenant DB) | Route report queries target the tenant database |
| ENV-03 | `DUSK_TENANT_URL` | Tenant-specific URL | Dusk test navigation target |
| ENV-04 | `DUSK_ADMIN_EMAIL` | Admin user email | Dusk login credential |
| ENV-05 | `DUSK_ADMIN_PASSWORD` | Admin user password | Dusk login credential |
| ENV-06 | `SESSION_DRIVER` | `database` or `file` | AJAX requests rely on session for auth state |
| ENV-07 | `CACHE_STORE` | `file`, `redis`, etc. | No caching used in report - no impact |
| ENV-08 | `CDN availability` | `cdn.jsdelivr.net` reachable | Chart.js, Moment.js, daterangepicker load failure |
| ENV-09 | `PHP memory_limit` | ≥ 128MB recommended | `getRouteReport()` loads all routes into memory |
| ENV-10 | `max_execution_time` | ≥ 30s recommended | Large date ranges with many records need more time |

---

## 11. Cross-Reference Matrix

| Section | Total Items | TC Coverage |
|---------|-------------|-------------|
| Pre-conditions (PC) | 15 | PC-01 → TC-N06, TC-N07; PC-02 → TC-N06; PC-05 → TC-D01; PC-09 → TC-CR03; PC-13 → TC-CR12 |
| Default Load (DL) | 30 | DL-01→DL-04 → TC-P03; DL-05→DL-07 → TC-P02, TC-P17, TC-P18; DL-08→DL-16 → TC-P04; DL-24→DL-30 → TC-P02, TC-N09 |
| Business Conditions (BC) | 60+ | BC-QL-01→BC-QL-20 → TC-CR01→TC-CR23; BC-AUTH-01→BC-AUTH-10 → TC-N06, TC-N07, TC-N11, TC-N12; BC-BIZ-01→BC-BIZ-20 → TC-P06→TC-P12 |
| Positive Tests | 20 | TC-P01→TC-P20 |
| Negative Tests | 15 | TC-N01→TC-N15 |
| Dependency Tests | 10 | TC-D01→TC-D10 |
| Code Review Tests | 23 | TC-CR01→TC-CR23 |
| Total Test Cases | 68 | P:20, N:15, D:10, CR:23 |

---

## 10. Known Limitations / Technical Debt

| LIM ID | Issue | Impact | Suggested Fix |
|--------|-------|--------|---------------|
| LIM-01 | No per-tab Gate check in `loadTabSection()` | Users missing `route-performance.viewAny` can still access data via AJAX | Add `Gate::authorize("tenant.$tab.viewAny")` inside `loadTabSection()` |
| LIM-02 | [Query/Code Removed] | Malformed date string → 500 error | [Query/Code Removed] |
| LIM-03 | Single date format not handled | `dates=2026-01-15` (no separator) → PHP undefined array key error | Validate `explode()` result has 2 elements before parsing |
| LIM-04 | No empty-data fallback for Chart.js | Empty datasets render as zero-height canvas; no "No data" message | Add JS check: `if (routeLabels.length === 0) { showEmptyMessage(); return; }` |
| LIM-05 | `$route->shift` not eager-loaded in `getRouteReport()` | If blade accesses `$r->shift`, triggers N+1 query | Add `'shift'` to `with()` array in `getRouteReport()` |
| LIM-06 | `diffInMinutes()` returns absolute value | Early arrival (negative delay) reported as positive delay | Use `$reaching_time->diffInMinutes($sch_arrival_time, false)` for signed result; clamp negative to 0 |
| LIM-07 | Collection loaded entirely in memory | Large datasets (10k+ routes) cause memory pressure | Consider chunking or DB-level aggregation instead of collection |
| LIM-08 | Filter reset link does not preserve tab | After reset, `active_tab` removed from URL; defaults to route-performance (acceptable) | Add `?active_tab={{ request('active_tab', 'route-performance') }}` to reset link |
| LIM-09 | No export functionality | Users cannot download route performance data | Add `export` button with Excel/CSV download using `Maatwebsite\Excel` |
| LIM-10 | CDN dependency for Chart.js | Chart rendering breaks if CDN unavailable | Bundle Chart.js locally or add `<script>` fallback |

---

*End of document — 68 test cases, 15+ pre-conditions, 30+ default load items, 60+ business conditions, 10+ data strategies, full code trace, and detailed test steps.*
