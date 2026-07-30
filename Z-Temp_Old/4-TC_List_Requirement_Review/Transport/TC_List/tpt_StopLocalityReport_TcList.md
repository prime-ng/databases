# tpt_StopLocalityReport_TcList

## Module: Transport → Transport Report → Stop & Locality Analysis

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | Transport |
| Tab Group | Transport Report |
| Feature | Stop & Locality Analysis Report |
| URL(s) | `/transport-report?active_tab=stop-analysis` (page load), AJAX: `GET /transport-report?active_tab=stop-analysis&section=charts/table` |
| Controller | `Modules\Transport\Http\Controllers\TransportReportController` |
| Controller File | `Modules/Transport/app/Http/Controllers/TransportReportController.php` |
| Tab Builder Method | `buildStopAnalysisSection()` (line 121) |
| Data Method | `getRouteStopAnalysis()` (line 633) |
| Route | Defined inside `TransportReportController::index()` via `loadTabSection()` match block line 80 |
| View | `transport::report.stop-locality-analysis.index` |
| View File | `Modules/Transport/resources/views/report/stop-locality-analysis/index.blade.php` |
| Hub View | `transport::tab_module.transportreport` |
| Hub View File | `Modules/Transport/resources/views/tab_module/transportreport.blade.php` |
| Permission | `tenant.stop-analysis.viewAny` (line 29 of transportreport.blade.php) |
| JS Chart Library | Chart.js via CDN (`https://cdn.jsdelivr.net/npm/chart.js`) |
| Date Picker | daterangepicker + moment.js via CDN |
| Export | Not implemented |
| Pagination Strategy | Custom `paginateCollection()` on in-memory Collection — uses `page_stop` page name |
| Section Loading | AJAX-driven: charts and table loaded independently via `section=charts` and `section=table` |
| KPI Boxes Template | AdminLTE `small-box` component with SVG icons |

### 1.1 Controller Flow Summary

| Step | Method | Description |
|------|--------|-------------|
| S1 | `TransportReportController::index()` | Gate check `tenant.transport.viewAny`, parse filters, date range, return hub view with filter data |
| S2 | JS `loadTabSection('stop-analysis', 'charts')` | AJAX GET to `/transport-report?active_tab=stop-analysis&section=charts` |
| S3 | `loadTabSection()` match `'stop-analysis'` | Dispatches to `buildStopAnalysisSection()` |
| S4 | `buildStopAnalysisSection()` (line 121) | Calls `getRouteStopAnalysis()`, paginates collection with `page_stop`, renders charts view |
| S5 | `getRouteStopAnalysis()` (line 633) | Eager-loads `pickupPointRoutes.pickupPoint` → `tripStopDetails`, `boardingLogs`, `studentAllocations.student` |
| S6 | JS `loadTabSection('stop-analysis', 'table')` | AJAX GET to `/transport-report?active_tab=stop-analysis&section=table` |
| S7 | `buildStopAnalysisSection()` again | Renders table section with paginated `stopAnalysisReportsPaginated` |

---

## 2. Pre-conditions

| # | Pre-condition | Reason |
|---|--------------|--------|
| PC-01 | Required permission: `tenant.stop-analysis.viewAny` | Gate check in hub view `@can` + controller implicitly checked via hub |
| PC-02 | Required permission: `tenant.transport.viewAny` | Gate check in `TransportReportController::index()` line 36 |
| PC-03 | Active `Route` records must exist in DB | Base query: `Route::active()->with('pickupPointRoutes.pickupPoint')` |
| PC-04 | Routes must have `pickupPointRoutes` relationship records | `flatMap` iterates `$route->pickupPointRoutes` — no rows if empty |
| PC-05 | `PickupPoint` (stops) must be linked via `pickupPointRoutes.pickupPoint` | Eager load chain: `pickupPointRoutes.pickupPoint` |
| PC-06 | `TptTripStopDetail` records with `reached_flag = 1` | Delay computation filters `where('reached_flag', 1)` |
| PC-07 | `TptTripStopDetail` must have `sch_arrival_time` and `reaching_time` populated | Diff computation: `reaching_time->diffInMinutes(sch_arrival_time)` |
| PC-08 | `StudentBoardingLog` records for boarding counts | `boardingLogs` relationship counted for `boarding_count` |
| PC-09 | `TptStudentAllocationJnt` records for allocated counts | `studentAllocations` relationship: `unique('student_id')->count()` |
| PC-10 | Date range must be within `boardingLogs.trip_date` bounds | [Query/Code Removed] |
| PC-11 | Chart.js library must be loaded | Rendered in hub view: `<script src="https://cdn.jsdelivr.net/npm/chart.js">` |
| PC-12 | daterangepicker + moment.js must be loaded | Rendered in hub view for date filter |
| PC-13 | jQuery must be available | All AJAX logic uses `$.ajax`, `$(document).ready()` |
| PC-14 | Bootstrap 5 tab system must work | Tab pane uses `data-bs-toggle="tab"`, `tab-pane fade` classes |

### 2.1 Test Environment Setup

| Setup Step | Action | Verification |
|------------|--------|-------------|
| SE-01 | Create 3 routes: "Route A" (active), "Route B" (active), "Route C" (inactive) | Routes created in DB |
| SE-02 | Create 2 pickupPointRoutes per active route | PickupPointRoute records exist |
| SE-03 | Create 3 pickup points per route: "Stop-1", "Stop-2", "Stop-3" | PickupPoint records exist |
| SE-04 | Create TptTripStopDetail with reached_flag=1 for each stop, varying sch_arrival_time and reaching_time | Delay data available |
| SE-05 | Create StudentBoardingLog with trip_date inside current month for each stop, varying counts | Boarding data available |
| SE-06 | Create TptStudentAllocationJnt linking students to stops | Allocation data available |
| SE-07 | Assign the `tenant.stop-analysis.viewAny` permission to test user | `@can` passes |
| SE-08 | Ensure session is authenticated as a valid user | Auth guard passes |

---

## 3. Default Data Load

### 3.1 Section: charts — 4 KPI Boxes + 3 Charts

| Data | Variable Name | Source Code | Computation |
|------|--------------|-------------|-------------|
| KPI: Total Boardings | `$totalBoardings` | line 4 of view: `$stopAnalysisReports->sum('boarding_count')` | Sum of all `$row->boarding_count` |
| KPI: Allocated Students | `$totalAllocated` | line 5 of view: `$stopAnalysisReports->sum('allocated_students')` | Sum of all `$row->allocated_students` |
| KPI: Avg Arrival Delay | `$avgDelay` | line 6 of view: `$stopAnalysisReports->avg('avg_arrival_delay')` | Average of all `$row->avg_arrival_delay`, rounded to 1 decimal |
| KPI: Utilization Rate | `$utilizationRate` | line 69 of view: `$totalAllocated > 0 ? round(($totalBoardings / $totalAllocated) * 100, 1) : 0` | Overall boarding / allocation ratio |
| Boarding Bar Chart | `boardingBarChart` (Chart.js) | lines 203–240 of view | Grouped/stacked bar: Allocated vs Actual Boardings per stop |
| Delay Analysis Chart | `delayAnalysisChart` (Chart.js) | lines 246–278 of view | Horizontal bar: avg arrival delay per stop, color-coded (green ≤5, yellow ≤15, red >15) |
| Utilization Chart | `utilizationChart` (Chart.js) | lines 284–316 of view | Horizontal bar: utilization % per stop, color-coded (green ≤60%, yellow ≤80%, red >80%) |

### 3.2 Section: table — 9 Columns

| Column | Blade Variable | Source Code Line | Source Field | Formatting |
|--------|---------------|------------------|--------------|------------|
| Route | `$row->route_name` | line 404 | `$ppr->route->name` via flatMap | Bold `<strong>` |
| Stop | `$row->stop_name` | line 408 | `$stop->name` via flatMap | With geo-alt icon |
| Boardings | `$row->boarding_count` | line 411 | `$stop->boardingLogs->count()` | fw-semibold |
| Allocated | `$row->allocated_students` | line 413 | `$stop->studentAllocations->unique('student_id')->count()` | Plain number |
| Scheduled Time | `$scheduledTime` | line 370 | `$row->avg_scheduled_time` (minutes) | `round(X,1) . ' min'` or `-` if zero |
| Actual Time | `$actualTime` | line 371 | `$row->avg_actual_time` (minutes) | `round(X,1) . ' min'` or `-` if zero |
| Boarding Variance | `$boardingVariance` | line 373 | `actualAvg - scheduledAvg` | Badge: green (<2), red (>2), yellow (<-2) |
| Avg Delay | `$delay` | line 383 | `$row->avg_arrival_delay` (minutes) | Badge: green ≤5, yellow ≤15, red >15 |
| Utilization | `$utilization` | lines 365–368 | `boarding_count / allocated_students * 100` | Progress bar + % label |

### 3.3 Filter Controls

| Filter | HTML Element | Name Attribute | Options Source | Default Value |
|--------|-------------|----------------|----------------|---------------|
| Date Range | daterangepicker input | `dates` | moment.js presets | Current month (start to end) |
| Hidden From Date | hidden input | `from_date` | Parsed from date range | Current month start |
| Hidden To Date | hidden input | `to_date` | Parsed from date range | Current month end |
| Route | select dropdown | `route_id` | `$filters['routes']` (Route::active()->get()) | Empty (All Routes) |
| Stop | select dropdown | `stop_id` | `$filters['stops']` (PickupPoint::active()->get()) | Empty (All Stops) |
| Active Tab | hidden input | `active_tab` | Hardcoded `stop-analysis` | `stop-analysis` |

### 3.4 Pagination Configuration

| Property | Value |
|----------|-------|
| Items per page | 10 |
| Page query param | `page_stop` |
| Paginator type | `LengthAwarePaginator` on in-memory `Collection` |
| Page resolution | `Paginator::resolveCurrentPage('page_stop')` |
| Path resolution | `Paginator::resolveCurrentPath()` |
| Append strategy | `->appends(request()->query())->links()` |

### 3.5 KPI Box Template (AdminLTE small-box)

Each KPI uses the `small-box` component with:
- Color variant: `text-bg-primary` (Boardings), `text-bg-success` (Allocated), `text-bg-warning` (Delay), `text-bg-info` (Utilization)
- Inner: `<h3>` for value, `<p>` for label
- SVG icon as `small-box-icon`
- Footer link: More info → `route('transport.transport-master.index')`

---

## 4. Test Data Strategy

### 4.1 Core Dataset

| Dataset ID | Routes | Stops | Trip Stop Details | Boarding Logs | Allocations | Scenario |
|-----------|--------|-------|-------------------|---------------|-------------|----------|
| DS-01 | Route A (active): 2 stops | Stop-A1, Stop-A2 | reached_flag=1, delays: 2min, 8min | Stop-A1: 15 boardings, Stop-A2: 25 boardings | Stop-A1: 20 alloc, Stop-A2: 30 alloc | Normal operation |
| DS-02 | Route B (active): 3 stops | Stop-B1, Stop-B2, Stop-B3 | reached_flag=1, delays: 0min, 5min, 18min | Stop-B1: 10, Stop-B2: 8, Stop-B3: 12 | Stop-B1: 15, Stop-B2: 10, Stop-B3: 15 | Mix of delay bands |
| DS-03 | Route C (active): 1 stop | Stop-C1 | reached_flag=1, delay: 12min | Stop-C1: 30 boardings | Stop-C1: 30 alloc | 100% utilization |
| DS-04 | Route D (inactive): 2 stops | (none loaded — inactive filter) | N/A | N/A | N/A | Inactive route exclusion |
| DS-05 | Route E (active): 1 stop | Stop-E1 | reached_flag=1, delay: 25min | Stop-E1: 5 boardings | Stop-E1: 10 alloc | High delay, low utilization |

### 4.2 Edge Case Dataset

| Edge ID | Setup | Expected Impact |
|---------|-------|----------------|
| ED-01 | Stop with 0 trip stop details (no reached_flag=1 records) | `avg_scheduled_time = 0`, `avg_actual_time = 0`, delay = 0, empty avg => `round(0,1)` = 0 |
| ED-02 | Stop with 0 boarding logs | `boarding_count` = 0, `$utilization = 0%`, progress bar 0 width |
| ED-03 | Stop with 0 student allocations | `allocated_students` = 0, utilization = 0% (division by zero guarded) |
| ED-04 | Stop where boardings > allocated (data anomaly) | Utilization > 100%, capped by `min($utilization, 100)` in progress bar |
| ED-05 | Stop with negative variance (actual < scheduled) | `boarding_variance` negative, yellow/red badge |
| ED-06 | Date range with zero matching data | Empty collection; `stopAnalysisReports` empty → no data message |
| ED-07 | Very long stop name (>100 chars) | Table layout break test |
| ED-08 | Decimal delay values (e.g., 0.5 min, 15.7 min) | Rounding to 1 decimal |
| ED-09 | All stops have identical delay (e.g., all 5.0 min) | Color coding boundary test |
| ED-10 | Single stop in collection | Chart renders 1 bar, no visual issue |

### 4.3 Boundary Values for Delay Color Coding

| Boundary | Value | Expected Badge Color | Expected Chart Color |
|----------|-------|---------------------|---------------------|
| On Time lower | 0.0 min | Green (`bg-success`) | `rgba(40, 167, 69, 0.8)` |
| On Time upper | 5.0 min | Green | `rgba(40, 167, 69, 0.8)` |
| Moderate lower | 5.1 min | Yellow (`bg-warning`) | `rgba(255, 193, 7, 0.8)` |
| Moderate upper | 15.0 min | Yellow | `rgba(255, 193, 7, 0.8)` |
| High lower | 15.1 min | Red (`bg-danger`) | `rgba(220, 53, 69, 0.8)` |
| High extreme | 999 min | Red | `rgba(220, 53, 69, 0.8)` |

### 4.4 Boundary Values for Utilization Chart Color

| Boundary | Value | Expected Progress Bar Color | Expected Chart Color |
|----------|-------|----------------------------|---------------------|
| Low upper | 60% | `bg-success` | `rgba(40, 167, 69, 0.8)` |
| Moderate lower | 61% | `bg-warning` | `rgba(255, 193, 7, 0.8)` |
| Moderate upper | 80% | `bg-warning` | `rgba(255, 193, 7, 0.8)` |
| High lower | 81% | `bg-danger` | `rgba(220, 53, 69, 0.8)` |
| Max cap | 100% | `bg-danger`, width 100% | `rgba(220, 53, 69, 0.8)` |

### 4.5 Boundary Values for Variance Badge Color

| Boundary | Value | Expected Badge Color |
|----------|-------|---------------------|
| Tight tolerance | 0.0 min | Green (`bg-success`) |
| Tight upper | 2.0 min | Green |
| High lower | 2.1 min | Red (`bg-danger`) |
| Negative tight | -2.0 min | Green |
| Negative high | -2.1 min | Yellow (`bg-warning`) |

---

## 5. Business Conditions

### 5.1 Query Logic (`getRouteStopAnalysis` — line 633)

| BC ID | Line(s) | Detail | Priority |
|-------|---------|--------|----------|
| BC-QL-01 | 635 | [Query/Code Removed] | P1 |
| BC-QL-02 | 637 | Trip stop details constraint: `where('reached_flag', 1)` — only completed arrivals counted | P1 |
| BC-QL-03 | 638 | [Query/Code Removed] | P1 |
| BC-QL-04 | 639 | Student allocations: eager loads `studentAllocations.student` without date filter (all-time allocations) | P2 |
| BC-QL-05 | 642 | Route filter: `where('id', $filters['route_id'])` — exact ID match, applied when truthy | P1 |
| BC-QL-06 | 643–645 | [Query/Code Removed] | P1 |
| BC-QL-07 | 646 | Active routes only: `->active()` — global scope or local scope | P1 |
| BC-QL-08 | 648 | `flatMap` — each pickupPointRoute becomes a result row, keyed by route | P1 |
| BC-QL-09 | 653–655 | Scheduled time avg: `sch_departure_time` diff `sch_arrival_time` in seconds → minutes | P1 |
| BC-QL-10 | 657–659 | Actual time avg: `leaving_time` diff `reaching_time` in seconds → minutes | P1 |
| BC-QL-11 | 668 | Variance: `actualAvg - scheduledAvg` (positive = slower than scheduled) | P1 |
| BC-QL-12 | 669–671 | Delay: avg of `reaching_time->diffInMinutes(sch_arrival_time)` per stop | P1 |
| BC-QL-13 | 664 | `boarding_count`: uses `$stop->boardingLogs->count()` — count of all related logs | P1 |
| BC-QL-14 | 665 | `allocated_students`: `$stop->studentAllocations->unique('student_id')->count()` — deduplicated by student_id | P1 |

### 5.2 Business Logic

| BC ID | Condition | Expected Behavior | Verification |
|-------|-----------|-------------------|-------------|
| BC-BIZ-01 | Stop with zero trip stop details (no reached_flag=1) | `avg_scheduled_time = 0`, `avg_actual_time = 0`, `avg_arrival_delay = 0` (empty avg returns null, `round((float)null, 1)` = 0) | Assert empty `$tsd` collection |
| BC-BIZ-02 | Stop with no boarding logs | `boarding_count = 0`, `$utilization = 0%` | Assert `boarding_logs` empty |
| BC-BIZ-03 | Stop with no student allocations | `allocated_students = 0`, utilization = 0% (division guarded) | Assert `$utilization = 0` |
| BC-BIZ-04 | No stops in filter range | Empty collection; view renders "No stop analysis data found" | Check `@empty` condition |
| BC-BIZ-05 | Allocated students < boardings (data anomaly) | Utilization > 100% but capped by `min($utilization, 100)` in progress bar | Progress bar width shows 100% |
| BC-BIZ-06 | Route with no pickupPointRoutes | Route excluded from flatMap output (no rows to iterate) | Assert route not in collection |
| BC-BIZ-07 | Inactive route (`is_active = 0`) | Excluded by `->active()` scope | Assert absent |
| BC-BIZ-08 | Multiple routes with same stop name | FlatMap produces separate rows per route-stop combination | Assert deduplication not applied |
| BC-BIZ-09 | `boardingLogs` filtered by date but `studentAllocations` not | Boardings are date-scoped; allocations are all-time. This is the intended design | Verify allocation count unaffected by date filter |
| BC-BIZ-10 | Student allocated to multiple stops | `unique('student_id')` prevents double-counting per stop | Assert `allocated_students` matches distinct students |
| BC-BIZ-11 | `reached_flag = 1` constraint on tripStopDetails | Only completed trip stop segments contribute to delay/time calculation | Assert delay computed only from `reached_flag=1` records |
| BC-BIZ-12 | No `tripStopDetails` at all for a stop | Scheduled avg computed from empty collection → `avg()` returns null → `round((float) null, 2)` = 0 | Assert zero values in row |

### 5.3 UI Rendering Logic

| BC ID | Condition | Expected Behavior | Verification |
|-------|-----------|-------------------|-------------|
| BC-UI-01 | `section` param = `charts` | KPI boxes + 3 charts rendered with inline script | Check `@if(request('section') === 'charts')` block |
| BC-UI-02 | `section` param = `table` | 9-column table with pagination rendered | Check `@elseif(request('section') === 'table')` block |
| BC-UI-03 | No `section` param | Filter bar + skeleton loaders for both charts and table | Check `@else` block |
| BC-UI-04 | Skeleton loader visible before AJAX | Spinner with `spinner-border` inside `#stop-analysis-charts` and `#stop-analysis-table` | Assert spinner present |
| BC-UI-05 | Loading state: container opacity | `container.css('opacity', 0.5)` during AJAX call | Assert opacity set |
| BC-UI-06 | AJAX error state | Container shows `<div class="alert alert-danger">Failed to load ...</div>` | Assert error HTML injected |
| BC-UI-07 | Empty collection for charts | `renderNoDataMessage()` called: "No stop analysis data" on bar chart, "No delay data", "No utilization data" | Assert canvas text rendered |
| BC-UI-08 | Empty collection for table | Row with `colspan="9"`, `bi-inbox` icon, "No stop analysis data found" | Assert `<td colspan="9">` |
| BC-UI-09 | Chart view toggle (grouped/stacked) | Toggle buttons toggle `x-stacked` option on `boardingBarChart` | Assert chart rerenders |
| BC-UI-10 | Window resize event | All 3 charts resized via `.resize()` | Assert charts responsive |

### 5.4 AJAX & Tab Interaction Logic

| BC ID | Condition | Expected Behavior | Verification |
|-------|-----------|-------------------|-------------|
| BC-AJ-01 | Page load triggers `loadTabSection` | `loadTabSection('stop-analysis', 'charts')` and `loadTabSection('stop-analysis', 'table')` called | Assert 2 AJAX calls on load |
| BC-AJ-02 | Tab switch triggers load on first visit | `shown.bs.tab` event checks `loaded` class; if absent, fetches both sections | Assert AJAX call on first tab switch |
| BC-AJ-03 | Tab switch does NOT reload if already loaded | `loaded` class prevents duplicate AJAX | Assert no AJAX on second visit |
| BC-AJ-04 | Filter form submit triggers AJAX | `.transport-filter-form` submit handler calls `loadTabSection` for both sections | Assert 2 AJAX calls on filter change |
| BC-AJ-05 | Pagination click triggers table section reload | `.tab-pane .pagination a` click handler calls `loadTabSection(tabName, 'table', queryString)` | Assert AJAX call with page param |
| BC-AJ-06 | `loadTabSection` appends `active_tab` and `section` to query | Query data: `{active_tab: 'stop-analysis', section: 'charts'}` plus filter params | Assert URL params correct |
| BC-AJ-07 | Non-AJAX page load | Controller returns hub view with `activeTab='stop-analysis'` | Assert blade view rendered |
| BC-AJ-08 | `loadTabSection` with missing container | Function returns early if container length === 0 | Assert no error thrown |

---

## 6. CODE-TRACE Structure

### 6.1 CODE-TRACE-01: `TransportReportController::index()` — Hub Flow

| Trace Step | Line | Code | Description |
|-----------|------|------|-------------|
| TR-01-01 | 36 | `Gate::authorize('tenant.transport.viewAny')` | Permission gate — blocks unauthorized users |
| TR-01-02 | 38 | `$activeTab = $request->get('active_tab') ?: $request->get('tab', 'route-performance')` | Resolves active tab; defaults to route-performance if no tab param |
| TR-01-03 | 39 | `$section = $request->get('section')` | Captures AJAX section flag (charts/table/null) |
| TR-01-04 | 42–53 | `$reqFilters = [...]` | Assembles filter array from request params |
| TR-01-05 | 55–57 | `$startDate = $dateRange['startDate']; $endDate = $dateRange['endDate']` | Parses date range via `parseDateRange()` |
| TR-01-06 | 60 | `if ($request->ajax() && $section)` | AJAX branch: returns JSON with rendered HTML |
| TR-01-07 | 61 | `return $this->loadTabSection($activeTab, $section, ...)` | Dispatches to `loadTabSection()` |
| TR-01-08 | 65 | `$filters = $this->getFilterData()` | Loads filter dropdown data (routes, stops, etc.) |
| TR-01-09 | 67 | `return view('transport::tab_module.transportreport', compact('filters', 'activeTab'))` | Returns full hub view with filter data |

**Test Coverage: TR-01-01 to TR-01-09**

### 6.2 CODE-TRACE-02: `buildStopAnalysisSection()` — Tab Builder

| Trace Step | Line | Code | Description |
|-----------|------|------|-------------|
| TR-02-01 | 122 | `request()->merge(['section' => $section])` | Merges section into request for view conditional rendering |
| TR-02-02 | 124 | `$stopAnalysisReports = $this->getRouteStopAnalysis($reqFilters, $startDate, $endDate)` | Calls data method; returns `Collection` of stdClass objects |
| TR-02-03 | 125 | `$stopAnalysisReportsPaginated = $this->paginateCollection($stopAnalysisReports, 10, 'page_stop')` | Paginates collection: 10 per page, page name `page_stop` |
| TR-02-04 | 126 | `return view('transport::report.stop-locality-analysis.index', compact('filters', 'stopAnalysisReports', 'stopAnalysisReportsPaginated'))` | Renders view with full collection + paginated subset |

**Test Coverage: TR-02-01 to TR-02-04**

### 6.3 CODE-TRACE-03: `getRouteStopAnalysis()` — Data Query

| Trace Step | Line | Code | Description |
|-----------|------|------|-------------|
| TR-03-01 | 635 | [Query/Code Removed] | Starts eager loading on Route model |
| TR-03-02 | 636 | `'pickupPointRoutes.pickupPoint' => fn($q) => $q->with([` | Nested eager load: pickupPointRoutes → pickupPoint |
| TR-03-03 | 637 | [Query/Code Removed] | Constrain trip stop details to completed arrivals |
| TR-03-04 | 638 | [Query/Code Removed] | Constrain boarding logs to date range |
| TR-03-05 | 639 | `'studentAllocations.student'` | Eager load allocations + student (no date filter) |
| TR-03-06 | 642 | [Query/Code Removed] | Conditional route filter |
| TR-03-07 | 643–645 | [Query/Code Removed] | Conditional stop filter via subquery |
| TR-03-08 | 646 | `->active()` | Active route scope |
| TR-03-09 | 647 | `->get()` | Executes query |
| TR-03-10 | 648 | `->flatMap(function($route) {` | Starts flat-map: each route → multiple rows |
| TR-03-11 | 649 | `return $route->pickupPointRoutes->map(function($ppr) use ($route) {` | Maps each pickupPointRoute to one result row |
| TR-03-12 | 650 | `$stop = $ppr->pickupPoint;` | Extracts stop from relationship |
| TR-03-13 | 651 | `$tsd = $stop->tripStopDetails;` | Gets trip stop details collection (already loaded) |
| TR-03-14 | 653–655 | `$scheduledAvg = $tsd->avg(fn($t) => optional($t->sch_departure_time)->diffInSeconds($t->sch_arrival_time)) / 60` | Scheduled time avg: departure - arrival, in minutes |
| TR-03-15 | 657–659 | `$actualAvg = $tsd->avg(fn($t) => optional($t->leaving_time)->diffInSeconds($t->reaching_time)) / 60` | Actual time avg: leaving - reaching, in minutes |
| TR-03-16 | 662 | `'route_name' => $route->name` | Route name from Route model |
| TR-03-17 | 663 | `'stop_name' => $stop->name` | Stop name from PickupPoint model |
| TR-03-18 | 664 | `'boarding_count' => $stop->boardingLogs->count()` | Boarding log count (date-scoped) |
| TR-03-19 | 665 | `'allocated_students' => $stop->studentAllocations->unique('student_id')->count()` | Distinct allocated students (all-time) |
| TR-03-20 | 666 | `'avg_scheduled_time' => round((float) $scheduledAvg, 2)` | Rounded to 2 decimals |
| TR-03-21 | 667 | `'avg_actual_time' => round((float) $actualAvg, 2)` | Rounded to 2 decimals |
| TR-03-22 | 668 | `'boarding_variance' => round((float) $actualAvg - (float) $scheduledAvg, 2)` | Signed variance |
| TR-03-23 | 669–671 | `'avg_arrival_delay' => round((float) $tsd->avg(fn($t) => optional($t->reaching_time)->diffInMinutes($t->sch_arrival_time)), 1)` | Arrival delay: reaching - scheduled arrival, in minutes, rounded to 1 decimal |

**Test Coverage: TR-03-01 to TR-03-23**

### 6.4 CODE-TRACE-04: KPI Calculation Flow

| Trace Step | View Line | Expression | Description |
|-----------|----------|------------|-------------|
| TR-04-01 | 2 | `$stopAnalysisReports = $stopAnalysisReports ?? collect()` | Null-safe fallback to empty collection |
| TR-04-02 | 3 | `$totalBoardings = $stopAnalysisReports->sum('boarding_count')` | Sums all boarding_count values |
| TR-04-03 | 4 | `$totalAllocated = $stopAnalysisReports->sum('allocated_students')` | Sums all allocated_students values |
| TR-04-04 | 5 | `$avgDelay = round($stopAnalysisReports->avg('avg_arrival_delay') ?? 0, 1)` | Averages delay values, defaults to 0 |
| TR-04-05 | 68–72 | `$utilizationRate = $totalAllocated > 0 ? round(($totalBoardings / $totalAllocated) * 100, 1) : 0` | Overall utilization: total boardings / total allocated * 100 |

**Test Coverage: TR-04-01 to TR-04-05**

### 6.5 CODE-TRACE-05: Chart Data Assembly

| Trace Step | View Line | Expression | Description |
|-----------|----------|------------|-------------|
| TR-05-01 | 161 | `$stopNames = $stopAnalysisReports->pluck('stop_name')->toArray()` | Labels: stop names |
| TR-05-02 | 162 | `$boardingData = $stopAnalysisReports->pluck('boarding_count')->toArray()` | Dataset 1: boarding counts |
| TR-05-03 | 163 | `$allocatedData = $stopAnalysisReports->pluck('allocated_students')->toArray()` | Dataset 2: allocated students |
| TR-05-04 | 164 | `$delayData = $stopAnalysisReports->pluck('avg_arrival_delay')->toArray()` | Dataset 3: delay values |
| TR-05-05 | 165 | `$scheduledTimeData = $stopAnalysisReports->pluck('avg_scheduled_time')->toArray()` | Dataset 4: scheduled time |
| TR-05-06 | 166 | `$actualTimeData = $stopAnalysisReports->pluck('avg_actual_time')->toArray()` | Dataset 5: actual time |
| TR-05-07 | 167 | `$boardingVarianceData = $stopAnalysisReports->pluck('boarding_variance')->toArray()` | Dataset 6: variance |
| TR-05-08 | 170–176 | Loops: `$utilization = $row->allocated_students > 0 ? round(($row->boarding_count / $row->allocated_students) * 100, 1) : 0` | Per-stop utilization rates |

**Chart Rendering Details:**

| Chart | Type | Index Axis | Datasets | Color Logic |
|-------|------|-----------|----------|-------------|
| Boarding Bar Chart | `bar` | vertical (default) | Allocated Students (green), Actual Boardings (blue) | Static colors per dataset |
| Delay Analysis Chart | `bar` | horizontal (`indexAxis: 'y'`) | Avg Delay (min) | Dynamic: `d <= 5 ? green : d <= 15 ? yellow : red` |
| Utilization Chart | `bar` | horizontal (`indexAxis: 'y'`) | Utilization Rate % | Dynamic: `r > 80 ? red : r > 60 ? yellow : green` |

**Test Coverage: TR-05-01 to TR-05-08**

### 6.6 CODE-TRACE-06: Table Pagination Flow

| Trace Step | View Line | Code | Description |
|-----------|----------|------|-------------|
| TR-06-01 | 364 | `@forelse($stopAnalysisReportsPaginated as $row)` | Iterates paginated subset (10 items) |
| TR-06-02 | 366–368 | `$utilization = $row->allocated_students > 0 ? round(($row->boarding_count / $row->allocated_students) * 100, 1) : 0` | Per-row utilization |
| TR-06-03 | 370 | `$scheduledTime = $row->avg_scheduled_time > 0 ? round($row->avg_scheduled_time, 1) . ' min' : '-'` | Display scheduled time |
| TR-06-04 | 371 | `$actualTime = $row->avg_actual_time > 0 ? round($row->avg_actual_time, 1) . ' min' : '-'` | Display actual time |
| TR-06-05 | 373–381 | Variance badge color logic | Green: -2..2, Red: >2, Yellow: <-2 |
| TR-06-06 | 383–391 | Delay badge color logic | Green ≤5, Yellow ≤15, Red >15 |
| TR-06-07 | 393–400 | Utilization progress bar color logic | Green ≤60%, Yellow ≤80%, Red >80% |
| TR-06-08 | 429 | `style="width: {{ min($utilization, 100) }}%"` | Width capped at 100% |
| TR-06-09 | 448 | `{{ $stopAnalysisReportsPaginated->appends(request()->query())->links() }}` | Pagination links with query string appended |

**Test Coverage: TR-06-01 to TR-06-09**

### 6.7 CODE-TRACE-07: `paginateCollection()` Helper

| Trace Step | Controller Line | Code | Description |
|-----------|----------------|------|-------------|
| TR-07-01 | 264 | `$page = Paginator::resolveCurrentPage($pageName)` | Resolves current page from query string using custom page name |
| TR-07-02 | 265 | `$sliced = $items->slice(($page - 1) * $perPage, $perPage)->values()` | Slices collection for current page |
| TR-07-03 | 266–272 | `new LengthAwarePaginator($sliced, $items->count(), $perPage, $page, ['path' => Paginator::resolveCurrentPath(), 'pageName' => $pageName])` | Constructs paginator with correct path and page name |

**Test Coverage: TR-07-01 to TR-07-03**

### 6.8 CODE-TRACE-08: `parseDateRange()` Helper

| Trace Step | Controller Line | Code | Description |
|-----------|----------------|------|-------------|
| TR-08-01 | 329–332 | If `dates` param filled: split by ` - ` delimiter, parse start/end | Custom date range from daterangepicker |
| TR-08-02 | 333–335 | Else: default to current month start/end | `now()->startOfMonth()->toDateString()` and `now()->endOfMonth()->toDateString()` |

**Test Coverage: TR-08-01, TR-08-02**

---

## 7. Test Case List

### 7.1 Positive Test Cases — Tab Loading & Rendering

| TC ID | Description | Prerequisites | Test Steps | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|--------------|------------|-----------------|---------|---------|--------|
| TC-P01 | Tab loads with filter bar | DS-01, PC-01 through PC-14 | 1. Navigate to `/transport-report?active_tab=stop-analysis` | Filter bar visible with Date Range, Route dropdown, Stop dropdown | — | — | ⬜ |
| TC-P02 | Skeleton loaders visible before AJAX | DS-01 | 1. Load page with slow network simulation | `#stop-analysis-charts` and `#stop-analysis-table` contain `spinner-border` | — | — | ⬜ |
| TC-P03 | Charts section loaded via AJAX on page load | DS-01 | 1. Load page 2. Inspect network tab | GET `/transport-report?active_tab=stop-analysis&section=charts` returns HTML with KPI boxes + charts | — | — | ⬜ |
| TC-P04 | Table section loaded via AJAX on page load | DS-01 | 1. Load page 2. Inspect network tab | GET `/transport-report?active_tab=stop-analysis&section=table` returns HTML with 9-column table | — | — | ⬜ |
| TC-P05 | Tab switch from different tab loads sections | DS-01 | 1. Click another tab 2. Click Stop & Locality tab | `loadTabSection('stop-analysis', 'charts')` and `loadTabSection('stop-analysis', 'table')` called | — | — | ⬜ |
| TC-P06 | Tab switch does NOT re-fetch if already loaded | DS-01 | 1. Load stop-analysis 2. Switch away 3. Switch back | No AJAX calls (container has `loaded` class) | — | — | ⬜ |

### 7.2 Positive Test Cases — KPI Boxes

| TC ID | Description | Prerequisites | Test Steps | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|--------------|------------|-----------------|---------|---------|--------|
| TC-P07 | KPI: Total Boardings correct count | DS-01, DS-02 | 1. Load charts section | KPI box shows sum of all `boarding_count` (15+25+10+8+12+30 = 100) | — | — | ⬜ |
| TC-P08 | KPI: Total Boardings with filter applied | DS-01, DS-02, filter Route A | 1. Select Route A filter 2. Reload charts | KPI shows only Route A boardings (15+25 = 40) | — | — | ⬜ |
| TC-P09 | KPI: Allocated Students correct count | DS-01, DS-02 | 1. Load charts section | KPI shows sum of all `allocated_students` (20+30+15+10+15+30 = 120) | — | — | ⬜ |
| TC-P10 | KPI: Avg Arrival Delay correct average | DS-01, DS-02 | 1. Load charts section | KPI shows weighted avg of delays: `(2+8+0+5+18+12)/6 = 7.5 min` | — | — | ⬜ |
| TC-P11 | KPI: Utilization Rate correct % | DS-01, DS-02 | 1. Load charts section | KPI shows `(100/120)*100 = 83.3%` | — | — | ⬜ |
| TC-P12 | KPI: 100% utilization with perfect allocation | DS-03 | 1. Load charts section | Utilization Rate = `(30/30)*100 = 100%` | — | — | ⬜ |
| TC-P13 | KPI: Zero utilization with no data | ED-02, ED-03 | 1. Load charts section | Utilization Rate = 0% | — | — | ⬜ |
| TC-P14 | KPI boxes have correct color schemes | DS-01 | 1. Inspect each KPI | Boardings: `text-bg-primary`, Allocated: `text-bg-success`, Delay: `text-bg-warning`, Utilization: `text-bg-info` | — | — | ⬜ |
| TC-P15 | KPI: Avg Delay shows "min" suffix | DS-01 | 1. Inspect Avg Delay KPI | `<h3>7.5 <small>min</small></h3>` | — | — | ⬜ |
| TC-P16 | KPI: Utilization shows "%" suffix | DS-01 | 1. Inspect Utilization KPI | `<h3>83.3%</h3>` | — | — | ⬜ |
| TC-P17 | KPI: More info link navigates correctly | DS-01 | 1. Click "More info" on any KPI | Navigates to `route('transport.transport-master.index')` | — | — | ⬜ |

### 7.3 Positive Test Cases — Charts

| TC ID | Description | Prerequisites | Test Steps | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|--------------|------------|-----------------|---------|---------|--------|
| TC-P18 | Boarding Bar Chart renders with correct labels | DS-01, DS-02 | 1. Load charts 2. Inspect canvas | Chart.js renders bar chart with stop names as labels, 2 datasets (Allocated, Boardings) | — | — | ⬜ |
| TC-P19 | Boarding Bar Chart: Grouped mode default | DS-01 | 1. Load charts 2. Inspect chart options | `barChart.options.scales.x.stacked = false` | — | — | ⬜ |
| TC-P20 | Boarding Bar Chart: Stacked mode toggle | DS-01 | 1. Click "Stacked" button 2. Inspect chart update | Chart re-renders with stacked bars, active class on Stacked button | — | — | ⬜ |
| TC-P21 | Boarding Bar Chart: Grouped mode toggle back | DS-01 | 1. Switch to Stacked 2. Switch back to Grouped | Chart re-renders with grouped bars, active class on Grouped button | — | — | ⬜ |
| TC-P22 | Boarding Bar Chart: Tooltip shows utilization | DS-01 | 1. Hover over Boarding bar 2. Inspect tooltip | Tooltip shows: "Allocated: X", "Utilization: Y%" | — | — | ⬜ |
| TC-P23 | Delay Analysis Chart: Horizontal bars | DS-01 | 1. Load charts 2. Inspect chart | Horizontal bar chart (`indexAxis: 'y'`), each bar colored by delay severity | — | — | ⬜ |
| TC-P24 | Delay Analysis Chart: Green for delay ≤5 min | DS-01 (Stop-A1: 2min) | 1. Load charts 2. Inspect Stop-A1 bar | Background color: `rgba(40, 167, 69, 0.8)` (green) | — | — | ⬜ |
| TC-P25 | Delay Analysis Chart: Yellow for delay 6-15 min | DS-01 (Stop-A2: 8min) | 1. Load charts 2. Inspect Stop-A2 bar | Background color: `rgba(255, 193, 7, 0.8)` (yellow) | — | — | ⬜ |
| TC-P26 | Delay Analysis Chart: Red for delay >15 min | DS-02 (Stop-B3: 18min) | 1. Load charts 2. Inspect Stop-B3 bar | Background color: `rgba(220, 53, 69, 0.8)` (red) | — | — | ⬜ |
| TC-P27 | Delay Analysis Chart: Color-coded legend visible | DS-01 | 1. Inspect below chart | Three legend items: green "On Time", yellow "Moderate", red "High" | — | — | ⬜ |
| TC-P28 | Delay Analysis Chart: Tooltip shows schedule details | DS-01 | 1. Hover over a delay bar 2. Inspect tooltip | Tooltip shows: "Scheduled: X min", "Actual: Y min", "Avg Delay: Z minutes" | — | — | ⬜ |
| TC-P29 | Utilization Chart: Horizontal bars with % scale | DS-01 | 1. Load charts 2. Inspect chart | Horizontal bar chart, x-axis max=100, ticks with "%" suffix | — | — | ⬜ |
| TC-P30 | Utilization Chart: Green for ≤60% | DS-02 (Stop-B2: 8/10 = 80%) | 1. Load charts 2. Inspect | Wait, 80% > 60%, so yellow. DS-02 Stop-B1: 10/15=66.7%, yellow. Need ≤60%: Stop-E1: 5/10=50% → green | — | — | ⬜ |
| TC-P31 | Utilization Chart: Yellow for 61-80% | DS-02 (Stop-B2: 8/10=80%) | 1. Load charts 2. Inspect Stop-B2 | Background: `rgba(255, 193, 7, 0.8)` (yellow) | — | — | ⬜ |
| TC-P32 | Utilization Chart: Red for >80% | DS-01 (Stop-A1: 15/20=75% → yellow), DS-03 (Stop-C1: 30/30=100% → red) | 1. Load charts 2. Inspect Stop-C1 | Background: `rgba(220, 53, 69, 0.8)` (red) | — | — | ⬜ |
| TC-P33 | Utilization Chart: Tooltip shows utilization, boardings, allocated | DS-01 | 1. Hover over utilization bar 2. Inspect tooltip | Tooltip: "Utilization: 75%", "Boardings: 15", "Allocated: 20" | — | — | ⬜ |
| TC-P34 | All 3 charts respond to window resize | DS-01 | 1. Resize browser window | `barChart.resize()`, `delayChart.resize()`, `utilChart.resize()` called | — | — | ⬜ |
| TC-P35 | Charts render "No data" state when empty | ED-06 | 1. Set date range with no data 2. Load charts | `renderNoDataMessage()` called for all 3 canvases: "No stop analysis data", "No delay data", "No utilization data" | — | — | ⬜ |

### 7.4 Positive Test Cases — Table

| TC ID | Description | Prerequisites | Test Steps | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|--------------|------------|-----------------|---------|---------|--------|
| TC-P36 | Table renders 9 columns correctly | DS-01 | 1. Load table section | Columns: Route, Stop, Boardings, Allocated, Scheduled Time, Actual Time, Boarding Variance, Avg Delay, Utilization | — | — | ⬜ |
| TC-P37 | Table: Route name displayed in bold | DS-01 | 1. Inspect Route column cell | `<strong>Route A</strong>` | — | — | ⬜ |
| TC-P38 | Table: Stop name with geo-alt icon | DS-01 | 1. Inspect Stop column cell | `<i class="bi bi-geo-alt-fill text-secondary me-1"></i>Stop-A1` | — | — | ⬜ |
| TC-P39 | Table: Boardings shown with fw-semibold | DS-01 | 1. Inspect Boardings cell | `<td class="fw-semibold">15</td>` | — | — | ⬜ |
| TC-P40 | Table: Scheduled Time shows "X min" format | DS-01 | 1. Inspect Scheduled Time cell | Format: `12.5 min` or `-` if zero | — | — | ⬜ |
| TC-P41 | Table: Actual Time shows "X min" format | DS-01 | 1. Inspect Actual Time cell | Format: `14.2 min` or `-` if zero | — | — | ⬜ |
| TC-P42 | Table: Boarding Variance green badge for -2 to +2 | DS-01 (tight tolerance) | 1. Find row with variance 0..2 2. Inspect badge | `<span class="badge bg-success">0.5</span>` | — | — | ⬜ |
| TC-P43 | Table: Boarding Variance red badge for >2 | DS-01 (variance >2) | 1. Find row with variance >2 2. Inspect badge | `<span class="badge bg-danger">3.2</span>` | — | — | ⬜ |
| TC-P44 | Table: Boarding Variance yellow badge for <-2 | DS-01 (negative variance) | 1. Find row with variance <-2 2. Inspect badge | `<span class="badge bg-warning">-2.5</span>` | — | — | ⬜ |
| TC-P45 | Table: Avg Delay green badge for ≤5 min | DS-01 (Stop-A1: 2min) | 1. Inspect delay badge for Stop-A1 | `<span class="badge bg-success">2.0 min</span>` | — | — | ⬜ |
| TC-P46 | Table: Avg Delay yellow badge for 6-15 min | DS-02 (Stop-B2: 5min? boundary) | 1. Inspect delay badge for 8min stop | `<span class="badge bg-warning">8.0 min</span>` | — | — | ⬜ |
| TC-P47 | Table: Avg Delay red badge for >15 min | DS-02 (Stop-B3: 18min) | 1. Inspect delay badge for Stop-B3 | `<span class="badge bg-danger">18.0 min</span>` | — | — | ⬜ |
| TC-P48 | Table: Utilization progress bar renders correctly | DS-01 | 1. Inspect utilization cell | `<div class="progress"><div class="progress-bar bg-*" style="width: X%"></div></div>` + `X%` label | — | — | ⬜ |
| TC-P49 | Table: Utilization progress bar capped at 100% | ED-04 | 1. Inspect stop with boardings > allocated | `style="width: 100%"` not >100% | — | — | ⬜ |
| TC-P50 | Table: Progress bar color green for ≤60% | DS-02 (Stop-B1: 10/15=66.7%) | Actually 66.7% > 60%, so yellow. Need ≤60%: Stop-E1: 5/10=50% → green | `bg-success` class on progress bar | — | — | ⬜ |
| TC-P51 | Table: Progress bar color yellow for 61-80% | DS-02 (Stop-B2: 8/10=80%) | 1. Inspect progress bar for Stop-B2 | `bg-warning` class | — | — | ⬜ |
| TC-P52 | Table: Progress bar color red for >80% | DS-03 (Stop-C1: 100%) | 1. Inspect progress bar for Stop-C1 | `bg-danger` class | — | — | ⬜ |
| TC-P53 | Table: Empty state when no records | ED-06 | 1. Filter to date with no data 2. Load table | `<td colspan="9">` with `bi-inbox` icon and "No stop analysis data found" | — | — | ⬜ |
| TC-P54 | Table: 0 boardings shown correctly | ED-02 | 1. Load table with stop having 0 boardings | Boardings column shows `0`, Utilization shows `0%` | — | — | ⬜ |
| TC-P55 | Table: 0 allocated shown correctly | ED-03 | 1. Load table with stop having 0 allocations | Allocated column shows `0`, Utilization shows `0%` | — | — | ⬜ |

### 7.5 Positive Test Cases — Filters

| TC ID | Description | Prerequisites | Test Steps | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|--------------|------------|-----------------|---------|---------|--------|
| TC-P56 | Filter by route: shows only selected route stops | DS-01, DS-02 | 1. Select Route A 2. Submit filter | Only Stop-A1 and Stop-A2 rows visible in table + chart | — | — | ⬜ |
| TC-P57 | Filter by stop: shows only selected stop | DS-01, DS-02 | 1. Select Stop-A1 2. Submit filter | Only Stop-A1 row visible | — | — | ⬜ |
| TC-P58 | Filter by route + stop combined | DS-01, DS-02 | 1. Select Route A + Stop-A2 2. Submit | Only Stop-A2 on Route A shown | — | — | ⬜ |
| TC-P59 | Filter by date range: boarding logs filtered | DS-01, DS-02 | 1. Select date range covering only DS-01 data 2. Submit | Only DS-01 stops shown | — | — | ⬜ |
| TC-P60 | Reset filter returns to full dataset | DS-01, DS-02 | 1. Apply filter 2. Click reset/refresh button | All stops shown | — | — | ⬜ |
| TC-P61 | Route dropdown shows active routes only | DS-01, DS-04 | 1. Open route dropdown | Only Route A, B, C visible (Route D inactive = hidden) | — | — | ⬜ |
| TC-P62 | Stop dropdown shows active stops only | PC-05, PC-10 | 1. Open stop dropdown | Only active pickup points visible | — | — | ⬜ |
| TC-P63 | Date range presets work correctly | DS-01 | 1. Click date range input 2. Select "Today" | Only today's data shown | — | — | ⬜ |
| TC-P64 | Date range: "Last 7 Days" preset | DS-01 | 1. Click date range 2. Select "Last 7 Days" | Last 7 days range applied, data filtered accordingly | — | — | ⬜ |
| TC-P65 | Date range: "This Month" preset | DS-01 | 1. Click date range 2. Select "This Month" | Current month range applied | — | — | ⬜ |
| TC-P66 | Date range: "Last Month" preset | DS-01 | 1. Click date range 2. Select "Last Month" | Previous month range applied | — | — | ⬜ |
| TC-P67 | Filter submit triggers both chart and table reload | DS-01 | 1. Monitor network tab 2. Apply filter | 2 AJAX calls: section=charts and section=table | — | — | ⬜ |
| TC-P68 | Clear search via reset button | DS-01 | 1. Apply filter 2. Click reset | Page reloads without query params | — | — | ⬜ |

### 7.6 Positive Test Cases — Pagination

| TC ID | Description | Prerequisites | Test Steps | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|--------------|------------|-----------------|---------|---------|--------|
| TC-P69 | Pagination appears with >10 records | DS-01 + DS-02 + DS-03 + DS-05 (7 records total, need >10) | 1. Create 12 stops 2. Load table | Pagination links visible; page 1 shows first 10 records | — | — | ⬜ |
| TC-P70 | Click page 2 loads next 10 records | 12 stops dataset | 1. Click page 2 | 2 records shown; page 2 highlighted | — | — | ⬜ |
| TC-P71 | Pagination uses `page_stop` param | 12 stops dataset | 1. Click page 2 2. Inspect URL | URL contains `?page_stop=2` | — | — | ⬜ |
| TC-P72 | Pagination appends existing filter params | DS-01, DS-02 | 1. Filter by Route A 2. Navigate to page 2 | Pagination links include `route_id=X&page_stop=2` | — | — | ⬜ |
| TC-P73 | Pagination does NOT conflict with other tab pagination | 12 stops dataset + other tab loaded | 1. Load stop-analysis page 2 2. Switch to other tab 3. Switch back | Stop-analysis pagination at page 2 preserved; other tab pagination params not interfering | — | — | ⬜ |
| TC-P74 | Single page (≤10 records) hides pagination | DS-01 (6 records) | 1. Load table with 6 records | Pagination not displayed | — | — | ⬜ |
| TC-P75 | Empty collection pagination shows empty table | ED-06 | 1. Filter to empty date range | Empty table with "No stop analysis data found", no pagination | — | — | ⬜ |

### 7.7 Negative Test Cases

| TC ID | Description | Prerequisites | Test Steps | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|--------------|------------|-----------------|---------|---------|--------|
| TC-N01 | No stop data in date range | ED-06 | 1. Set date range with no boarding logs 2. Load charts + table | Charts: "No stop analysis data" message; Table: "No stop analysis data found" | — | — | ⬜ |
| TC-N02 | Route with no pickupPointRoutes | Create route with zero pickup points | 1. Load report | Route excluded from results; no row generated | — | — | ⬜ |
| TC-N03 | 403 without `tenant.stop-analysis.viewAny` permission | Revoke permission from test user | 1. Load page 2. Try to access tab | Tab hidden in nav (no tab button); content not rendered | — | — | ⬜ |
| TC-N04 | Guest access (unauthenticated) | Logout | 1. Access `/transport-report?active_tab=stop-analysis` | Redirected to login page | — | — | ⬜ |
| TC-N05 | No `tenant.transport.viewAny` on hub page | Revoke transport permission | 1. Access `/transport-report` | 403 Forbidden from `Gate::authorize('tenant.transport.viewAny')` | — | — | ⬜ |
| TC-N06 | AJAX request with invalid tab name | None | 1. Send AJAX `?active_tab=nonexistent&section=charts` | Returns `<p class="text-muted">Invalid tab</p>` | — | — | ⬜ |
| TC-N07 | AJAX request with missing section | DS-01 | 1. Send AJAX `?active_tab=stop-analysis` (no section) | Non-AJAX branch: returns full hub view (not JSON) | — | — | ⬜ |
| TC-N08 | Invalid page_stop value (negative) | DS-01 | 1. Navigate to `?page_stop=-1` 2. Load table | Page resolves to 1 (slice handles gracefully) | — | — | ⬜ |
| TC-N09 | Invalid page_stop value (string) | DS-01 | 1. Navigate to `?page_stop=abc` 2. Load table | `resolveCurrentPage` returns null, defaults to 1 | — | — | ⬜ |
| TC-N10 | Date range with invalid format | DS-01 | 1. Set `dates=invalid` 2. Submit filter | `parseDateRange()` split fails; falls to default month range | — | — | ⬜ |
| TC-N11 | Route ID filter with non-existent ID | DS-01 | 1. Set `route_id=99999` 2. Submit | Empty collection; "No stop analysis data found" | — | — | ⬜ |
| TC-N12 | Stop ID filter with non-existent ID | DS-01 | 1. Set `stop_id=99999` 2. Submit | `whereHas` returns no routes; empty collection | — | — | ⬜ |
| TC-N13 | Stop with zero trip stop details reached_flag=1 | ED-01 | 1. Create stop with no reached_flag=1 records 2. Load report | Row present with 0s for times, delay = 0, boarding from logs still counted | — | — | ⬜ |
| TC-N14 | Stop with zero boardings | ED-02 | 1. Create stop with no boarding logs 2. Load report | Row present with boarding_count = 0, utilization = 0% | — | — | ⬜ |
| TC-N15 | Stop with zero allocated students | ED-03 | 1. Create stop with no student allocations 2. Load report | Row present with allocated_students = 0, utilization = 0% | — | — | ⬜ |
| TC-N16 | Chart.js CDN fails to load | Disable CDN in test | 1. Load page with chart.js blocked | Console error: "Chart is not defined"; JS execution breaks, charts don't render | — | — | ⬜ |
| TC-N17 | daterangepicker CDN fails | Disable CDN | 1. Load page with daterangepicker blocked | Date range input not initialized; no date picker functionality | — | — | ⬜ |
| TC-N18 | jQuery CDN fails | Disable CDN | 1. Load page with jQuery blocked | All AJAX logic fails; page load JS errors | — | — | ⬜ |
| TC-N19 | AJAX endpoint returns 500 error | Simulate server error | 1. Load tab section 2. Trigger server error | Alert message: "Failed to load charts." / "Failed to load table." | — | — | ⬜ |
| TC-N20 | Very long stop name (>100 chars) | ED-07 | 1. Create stop with 150-char name 2. Load table | Table layout may break; chart label truncated | — | — | ⬜ |

### 7.8 Edge Case Test Cases

| TC ID | Description | Prerequisites | Test Steps | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|--------------|------------|-----------------|---------|---------|--------|
| TC-EC-01 | All stops have delay = 0 (on time) | All tripStopDetails have reaching_time == sch_arrival_time | 1. Load report | All delay badges green; all delay chart bars green | — | — | ⬜ |
| TC-EC-02 | All stops have utilization = 0% | No studentAllocations for any stop | 1. Load report | All allocated = 0; all utilization = 0%; progress bars 0 width | — | — | ⬜ |
| TC-EC-03 | All stops have 100% utilization | DS-03 for all stops | 1. Load report | Utilization KPI = 100%; all progress bars red; all utilization chart bars red | — | — | ⬜ |
| TC-EC-04 | Single stop in entire dataset | Only 1 route with 1 pickup point | 1. Load report | 1 row in table; charts render 1 bar; no pagination | — | — | ⬜ |
| TC-EC-05 | Decimal delay values at boundary | Delay = 5.0 min (boundary) | 1. Load report | Badge green (≤5); chart bar green (d <= 5 is true) | — | — | ⬜ |
| TC-EC-06 | Decimal delay at boundary | Delay = 5.1 min | 1. Load report | Badge yellow; chart bar yellow | — | — | ⬜ |
| TC-EC-07 | Decimal delay at boundary | Delay = 15.0 min | 1. Load report | Badge yellow (≤15); chart bar yellow (d <= 15) | — | — | ⬜ |
| TC-EC-08 | Decimal delay at boundary | Delay = 15.1 min | 1. Load report | Badge red; chart bar red | — | — | ⬜ |
| TC-EC-09 | Utilization boundary | Utilization = 60.0% | 1. Load report | Progress bar green (≤60%); chart bar green | — | — | ⬜ |
| TC-EC-10 | Utilization boundary | Utilization = 60.1% | 1. Load report | Progress bar yellow; chart bar yellow | — | — | ⬜ |
| TC-EC-11 | Utilization boundary | Utilization = 80.0% | 1. Load report | Progress bar yellow (≤80%); chart bar yellow | — | — | ⬜ |
| TC-EC-12 | Utilization boundary | Utilization = 80.1% | 1. Load report | Progress bar red; chart bar red | — | — | ⬜ |
| TC-EC-13 | Variance boundary | Variance = 2.0 min | 1. Load report | Badge green (-2 to +2 inclusive) | — | — | ⬜ |
| TC-EC-14 | Variance boundary | Variance = 2.1 min | 1. Load report | Badge red (>2) | — | — | ⬜ |
| TC-EC-15 | Variance boundary | Variance = -2.0 min | 1. Load report | Badge green | — | — | ⬜ |
| TC-EC-16 | Variance boundary | Variance = -2.1 min | 1. Load report | Badge yellow (<-2) | — | — | ⬜ |
| TC-EC-17 | Boarding count > Allocated (data anomaly) | ED-04 | 1. Load report | Utilization cap: width = `min(X, 100)`% (shows 100%); no visual overflow | — | — | ⬜ |
| TC-EC-18 | Route with no tripStopDetails at all | Stop has no TptTripStopDetail | 1. Load report | Row present with: scheduled=0, actual=0, delay=0, boardings from logs still valid | — | — | ⬜ |

### 7.9 Permission & Access Control Test Cases

| TC ID | Description | Prerequisites | Test Steps | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|--------------|------------|-----------------|---------|---------|--------|
| TC-PM-01 | User with `tenant.stop-analysis.viewAny` can see tab | PC-01 | 1. Login as permitted user 2. Load transport report | Stop & Locality Analysis tab visible | — | — | ⬜ |
| TC-PM-02 | User WITHOUT `tenant.stop-analysis.viewAny` tab hidden | Revoke permission | 1. Login as restricted user 2. Load transport report | Tab nav button hidden; `@include` not executed | — | — | ⬜ |
| TC-PM-03 | User with `tenant.stop-analysis.viewAny` but no `tenant.transport.viewAny` | Assign stop-analysis but not transport | 1. Access `/transport-report?active_tab=stop-analysis` | 403 on `Gate::authorize('tenant.transport.viewAny')` in index() | — | — | ⬜ |
| TC-PM-04 | Direct URL access without permission | Revoke stop-analysis | 1. Direct AJAX call `?active_tab=stop-analysis&section=charts` | No explicit Gate in `buildStopAnalysisSection()` — relies on tab being hidden | — | — | ⬜ |
| TC-PM-05 | Permission string matches `permissionslist.php` | Check `config/permissionslist.php` | 1. Assert `tenant.stop-analysis.viewAny` exists in config | Permission group defined with key `stop-analysis` | — | — | ⬜ |

### 7.10 AJAX & SPA Behavior Test Cases

| TC ID | Description | Prerequisites | Test Steps | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|--------------|------------|-----------------|---------|---------|--------|
| TC-AJ-01 | Page load calls 2 AJAX requests | DS-01 | 1. Load page 2. Monitor network panel | 2 requests: `section=charts` and `section=table` | — | — | ⬜ |
| TC-AJ-02 | AJAX response contains rendered HTML (not JSON data) | DS-01 | 1. Inspect AJAX response | `{html: "<div class=...>"}` — pre-rendered Blade HTML | — | — | ⬜ |
| TC-AJ-03 | Filter form submit: both sections reloaded simultaneously | DS-01 | 1. Apply filter 2. Monitor network | 2 parallel AJAX requests | — | — | ⬜ |
| TC-AJ-04 | Pagination click reloads only table section | DS-01 (12 stops) | 1. Click page 2 | Only `section=table` request; charts not re-fetched | — | — | ⬜ |
| TC-AJ-05 | Opacity dimming during AJAX load | DS-01 | 1. Slow network 2. Load page | Container opacity set to 0.5 | — | — | ⬜ |
| TC-AJ-06 | Opacity restored after AJAX success | DS-01 | 1. Load page 2. Wait for AJAX completion | Container opacity restored to 1 | — | — | ⬜ |
| TC-AJ-07 | Error message on AJAX failure | Simulate 500 error | 1. Trigger AJAX 2. Force server error | `<div class="alert alert-danger">Failed to load ...</div>` shown | — | — | ⬜ |
| TC-AJ-08 | loadTabSection handles empty container gracefully | None | 1. Remove `#stop-analysis-charts` from DOM 2. Trigger reload | No JS error; function returns early | — | — | ⬜ |
| TC-AJ-09 | Tab switch from filter-submitted state preserves filters | DS-01 | 1. Apply filter 2. Switch to other tab 3. Switch back | Filters preserved in form; data re-fetched with same filters | — | — | ⬜ |
| TC-AJ-10 | Multiple rapid filter submissions | DS-01 | 1. Submit filter 3 times rapidly 2. Wait | Last submission wins; no duplicate data corruption | — | — | ⬜ |

### 7.11 Data Integrity Test Cases

| TC ID | Description | Prerequisites | Test Steps | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|--------------|------------|-----------------|---------|---------|--------|
| TC-DI-01 | Boarding count matches actual StudentBoardingLog count | DS-01 | 1. Query DB for Stop-A1 boarding logs 2. Compare with report | `$stop->boardingLogs->count()` in controller = direct DB count | — | — | ⬜ |
| TC-DI-02 | Allocated students deduplicated correctly | Student allocated to same stop twice | 1. Create duplicate allocation for same student-stop 2. Load report | `allocated_students` counts distinct `student_id` only | — | — | ⬜ |
| TC-DI-03 | Scheduled time computed from departure - arrival | DS-01 | 1. Manually compute sch_departure - sch_arrival 2. Compare | Value matches `$tsd->avg(fn($t) => diffInSeconds(sch_departure, sch_arrival)) / 60` | — | — | ⬜ |
| TC-DI-04 | Actual time computed from leaving - reaching | DS-01 | 1. Manually compute leaving_time - reaching_time 2. Compare | Value matches controller computation | — | — | ⬜ |
| TC-DI-05 | Variance = actualAvg - scheduledAvg | DS-01 | 1. Compute manually 2. Compare | `boarding_variance` = actualAvg - scheduledAvg | — | — | ⬜ |
| TC-DI-06 | Delay = reaching_time - sch_arrival_time (in minutes) | DS-01 | 1. Compute manually 2. Compare | `avg_arrival_delay` matches `avg(diffInMinutes(reaching_time, sch_arrival_time))` | — | — | ⬜ |
| TC-DI-07 | Date filter only affects boarding logs, not allocations | DS-01 | 1. Set date range outside boarding log dates 2. Load | Boarding count = 0; allocated students unchanged (all-time) | — | — | ⬜ |
| TC-DI-08 | reached_flag=1 filter correctly excludes incomplete trips | DS-01 | 1. Add tripStopDetail with reached_flag=0 2. Load | Incomplete trip excluded from time/delay computation | — | — | ⬜ |
| TC-DI-09 | Active route scope excludes inactive routes | DS-04 | 1. Load report | Route D (inactive) not in results | — | — | ⬜ |
| TC-DI-10 | FlatMap produces correct number of rows | DS-01 (Route A: 2 stops, Route B: 3 stops, Route C: 1 stop) | 1. Count result rows | 2 + 3 + 1 = 6 rows | — | — | ⬜ |

### 7.12 Code Review Test Cases

| TC ID | Priority | Description | Expected Result | Status |
|-------|----------|-------------|-----------------|--------|
| TC-CR01 | P1 | Nested eager loading avoids N+1 | [Query/Code Removed] | ◌ |
| TC-CR02 | P1 | FlatMap correctly flattens per-stop rows | Each pickupPointRoute produces exactly one row; no grouping by route | ◌ |
| TC-CR03 | P1 | Variance calculation correct | `boarding_variance = actualAvg - scheduledAvg` — signed value, positive = slower than scheduled | ◌ |
| TC-CR04 | P1 | Color-coded delay badges | Green: `$delay <= 5`, Yellow: `$delay > 5 && $delay <= 15`, Red: `$delay > 15` — match blade logic lines 384-391 | ◌ |
| TC-CR05 | P1 | Utilization capped at 100% | `min($utilization, 100)` in progress bar `style="width: {{ min($utilization, 100) }}%"` at line 429 | ◌ |
| TC-CR06 | P1 | Pagination uses `page_stop` | `$this->paginateCollection($stopAnalysisReports, 10, 'page_stop')` — no conflict with other report tabs (page_route, page_usage, page_trip, page_driver, page_finance, page_cost) | ◌ |
| TC-CR07 | P1 | `buildStopAnalysisSection` shares same view for both sections | Both `charts` and `table` sections use same view; conditional rendering via `@if(request('section') === 'charts')` / `@elseif(request('section') === 'table')` | ◌ |
| TC-CR08 | P1 | Null-safe collection handling in view | `$stopAnalysisReports = $stopAnalysisReports ?? collect()` at line 2 prevents null errors on empty collection | ◌ |
| TC-CR09 | P1 | Division by zero guarded for utilization | `$row->allocated_students > 0 ? round(($row->boarding_count / $row->allocated_students) * 100, 1) : 0` at line 366-368 | ◌ |
| TC-CR10 | P1 | `optional()` helper used for nullable Carbon dates | `optional($t->sch_departure_time)->diffInSeconds(...)` at lines 653-659 prevents null method call on Carbon | ◌ |
| TC-CR11 | P1 | `Gate::authorize('tenant.transport.viewAny')` guards index() | Line 36 — unauthorized users get 403 before any data loads | ◌ |
| TC-CR12 | P1 | AJAX-only section=charts/table response | Controller returns `response()->json(['html' => $html])` — not a full page render | ◌ |
| TC-CR13 | P1 | `active()` scope on Route query | `->active()` at line 646 ensures only active routes contribute data | ◌ |
| TC-CR14 | P1 | Date scope on boardingLogs but not studentAllocations | Controller line 638 scopes boarding logs; line 639 does NOT scope allocations — intentional by design | ◌ |
| TC-CR15 | P1 | `flatMap` returns `Collection` not array | `flatMap()` returns Laravel Collection, correctly handled upstream | ◌ |
| TC-CR16 | P2 | Chart toggle uses DOM classList | `document.querySelectorAll('[data-chart-view]')` — vanilla JS, no jQuery dependency for toggle | ◌ |
| TC-CR17 | P2 | `renderNoDataMessage()` uses Canvas API | `ctx.clearRect()`, `ctx.fillText()` — no Chart.js dependency for empty state | ◌ |
| TC-CR18 | P2 | Same-origin AJAX requests | `url: window.location.pathname` — requests go to same URL, avoids CORS | ◌ |
| TC-CR19 | P2 | `page_stop` param not confused with page | Paginator resolves `page_stop` param separately from default `page` param | ◌ |
| TC-CR20 | P2 | `request()->merge(['section' => $section])` in builder | Builder merges section into request so `@if(request('section') === 'charts')` works in rendered view | ◌ |

### 7.13 UI/UX Test Cases

| TC ID | Description | Prerequisites | Test Steps | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|--------------|------------|-----------------|---------|---------|--------|
| TC-UI-01 | Page title shows "Transport Report" breadcrumb | DS-01 | 1. Load page 2. Inspect breadcrumb | `<x-backend.components.breadcrum title="Transport Report" :links="[]" />` | — | — | ⬜ |
| TC-UI-02 | Tab label reads "Stop & Locality Analysis" | DS-01 | 1. Inspect tab button | Tab text: "Stop & Locality Analysis" with fa-map-marker-alt icon | — | — | ⬜ |
| TC-UI-03 | Filter bar aligns horizontally with proper spacing | DS-01 | 1. Load page 2. Inspect filter bar | Flex layout with `gap-2`, all filter elements in one row | — | — | ⬜ |
| TC-UI-04 | Date range input has calendar icon | DS-01 | 1. Inspect date input | `input-group-text` with `<i class="bi bi-calendar3"></i>` | — | — | ⬜ |
| TC-UI-05 | Chart cards have shadow and borderless style | DS-01 | 1. Inspect chart containers | `card border-0 shadow-sm` CSS classes applied | — | — | ⬜ |
| TC-UI-06 | Table rows have hover effect | DS-01 | 1. Hover over table row | Visual highlight on hover | — | — | ⬜ |
| TC-UI-07 | Empty table state has centered icon and text | ED-06 | 1. Load with no data | Centered `bi-inbox` icon + "No stop analysis data found" in muted text | — | — | ⬜ |
| TC-UI-08 | Table header row has light background | DS-01 | 1. Inspect `<thead>` | `table-light` class on `thead` | — | — | ⬜ |
| TC-UI-09 | Progress bar has 8px height | DS-01 | 1. Inspect progress bar | `style="height: 8px;"` | — | — | ⬜ |
| TC-UI-10 | Filter button has search icon | DS-01 | 1. Inspect submit button | `<i class="fas fa-filter"></i>` | — | — | ⬜ |
| TC-UI-11 | Reset button has redo icon | DS-01 | 1. Inspect reset link | `<i class="fas fa-redo"></i>` | — | — | ⬜ |
| TC-UI-12 | Chart toggle buttons have proper active state | DS-01 | 1. Click toggle 2. Inspect class | Active button has `active` class, `btn-outline-primary` | — | — | ⬜ |
| TC-UI-13 | Responsive: charts stack on small screens | DS-01 | 1. Resize to <992px | Chart cards stack vertically (lg-8 + lg-4 → full width) | — | — | ⬜ |
| TC-UI-14 | KPI boxes responsive at breakpoints | DS-01 | 1. Test at <768px, <992px, <1200px | KPI grid: col-6 at <992px, col-3 at ≥992px | — | — | ⬜ |
| TC-UI-15 | Color-coded legend below delay chart visible | DS-01 | 1. Inspect below delay chart | 3 legend items with matching green/yellow/red `bi-circle-fill` | — | — | ⬜ |
| TC-UI-16 | Table uses `table-sm` for compact layout | DS-01 | 1. Inspect table class | `table table-sm` | — | — | ⬜ |
| TC-UI-17 | Pagination centered below table | DS-01 (12 stops) | 1. Inspect pagination container | `d-flex justify-content-center mt-3` | — | — | ⬜ |
| TC-UI-18 | Chart has border-radius 4px | DS-01 | 1. Inspect chart bar style | `borderRadius: 4` in Chart.js options | — | — | ⬜ |
| TC-UI-19 | Chart animation duration 1000ms | DS-01 | 1. Observe chart load | Bars animate with `easeOutQuart` easing over 1 second | — | — | ⬜ |
| TC-UI-20 | Skeleton loader shows before AJAX completes | DS-01 (throttled network) | 1. Throttle network to Slow 3G 2. Load page | Spinner with "Loading..." sr-only text visible | — | — | ⬜ |

### 7.14 Performance & Scalability Test Cases

| TC ID | Description | Prerequisites | Test Steps | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|--------------|------------|-----------------|---------|---------|--------|
| TC-PF-01 | Query count with 10 routes x 3 stops = 30 rows | 10 routes, 30 stops | 1. Load report 2. Profile DB queries | Eager loading keeps query count constant (6-7 queries regardless of data size) | — | — | ⬜ |
| TC-PF-02 | Collection pagination handles 1000+ stops | 1000 pickupPointRoutes | 1. Load table section | Page loads with first 10 rows; pagination works for 100 pages | — | — | ⬜ |
| TC-PF-03 | In-memory pagination memory usage | 1000 stops | 1. Load report 2. Monitor memory | Entire collection loaded into memory before pagination — may be heavy at scale | — | — | ⬜ |
| TC-PF-04 | Chart rendering with 50+ stops | 50 stops dataset | 1. Load charts section | 50 bars render; chart may become cluttered but no crash | — | — | ⬜ |
| TC-PF-05 | Concurrent AJAX requests timing | DS-01 | 1. Measure charts + table load time | Both sections load in parallel; total time ≈ max(charts_time, table_time) | — | — | ⬜ |
| TC-PF-06 | Filter-heavy dataset performance | 10 routes, 50 stops, 5000 boarding logs | 1. Apply route filter 2. Measure response | Filter reduces dataset; response time correlates with filtered data size | — | — | ⬜ |

### 7.15 Regression Test Cases

| TC ID | Description | Related Change | Test Steps | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|------------|-----------------|---------|---------|--------|
| TC-RG-01 | Other report tabs still work after stop-analysis changes | `loadTabSection()` match block | 1. Load route-performance tab 2. Verify data loads | Route Performance tab unaffected | — | — | ⬜ |
| TC-RG-02 | Pagination on other tabs still works | `page_stop` unique name | 1. Load route-performance page 2 2. Switch to stop-analysis page 2 3. Verify | Each tab maintains its own page state | — | — | ⬜ |
| TC-RG-03 | Other tab `@can` permissions preserved | `transportreport.blade.php` | 1. Verify all 11 tabs have `@can` wrappers | No tab accidentally broken by changes to stop-analysis section | — | — | ⬜ |
| TC-RG-04 | Filter data dropdowns for other tabs still populated | `getFilterData()` | 1. Check routes, vehicles, shifts dropdowns in other tabs | All filter dropdowns populated correctly | — | — | ⬜ |
| TC-RG-05 | Chart.js CDN still serves other charts | CDN loaded once in hub view | 1. Check all tab charts render | Single Chart.js instance serves all charts across tabs | — | — | ⬜ |
| TC-RG-06 | Date range picker works across all tabs | Shared daterangepicker init | 1. Switch tabs 2. Change date range 3. Switch back | Date range preserved across tab switches | — | — | ⬜ |

### 7.16 API Contract & AJAX Response Format Test Cases

| TC ID | Description | Prerequisites | Test Steps | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|--------------|------------|-----------------|---------|---------|--------|
| TC-API-01 | Charts AJAX returns valid JSON with `html` key | DS-01 | 1. Inspect AJAX response for section=charts | `{"html": "<div class=...>"}` — valid JSON, single `html` property | — | — | ⬜ |
| TC-API-02 | Table AJAX returns valid JSON with `html` key | DS-01 | 1. Inspect AJAX response for section=table | `{"html": "<table class=...>"}` — valid JSON | — | — | ⬜ |
| TC-API-03 | Charts HTML contains KPI boxes | DS-01 | 1. Parse AJAX response HTML 2. Check for `.small-box` | HTML contains 4 `.small-box` divs | — | — | ⬜ |
| TC-API-04 | Charts HTML contains 3 canvas elements | DS-01 | 1. Parse AJAX response HTML 2. Check canvases | HTML contains `#boardingBarChart`, `#delayAnalysisChart`, `#utilizationChart` | — | — | ⬜ |
| TC-API-05 | Charts HTML contains Chart.js script | DS-01 | 1. Parse AJAX response HTML 2. Check script block | HTML contains inline `<script>` with Chart.js initialization | — | — | ⬜ |
| TC-API-06 | Table HTML contains `<table>` element | DS-01 | 1. Parse table AJAX response HTML | HTML contains `<table class="table table-sm">` | — | — | ⬜ |
| TC-API-07 | Table HTML contains 9 `<th>` elements | DS-01 | 1. Parse table HTML 2. Count header columns | Exactly 9 `<th>` elements: Route, Stop, Boardings, Allocated, Scheduled Time, Actual Time, Boarding Variance, Avg Delay, Utilization | — | — | ⬜ |
| TC-API-08 | Table HTML contains pagination links | DS-01 (12 stops) | 1. Parse table HTML 2. Check for `.pagination` | HTML contains `<ul class="pagination">` or `<nav>` with page links | — | — | ⬜ |
| TC-API-09 | Content-Type is `application/json` | DS-01 | 1. Inspect response headers for AJAX | `Content-Type: application/json` | — | — | ⬜ |
| TC-API-10 | Invalid tab returns fallback HTML, not error | None | 1. Send AJAX with `active_tab=invalid_tab` | Returns `<p class="text-muted">Invalid tab</p>` in HTML | — | — | ⬜ |

### 7.17 JavaScript Console & Error Handling Test Cases

| TC ID | Description | Prerequisites | Test Steps | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|--------------|------------|-----------------|---------|---------|--------|
| TC-JS-01 | No JS console errors on page load | DS-01 | 1. Open browser console 2. Load page | Zero errors, warnings, or uncaught exceptions | — | — | ⬜ |
| TC-JS-02 | No JS errors on filter submit | DS-01 | 1. Open console 2. Apply filter | Zero console errors | — | — | ⬜ |
| TC-JS-03 | No JS errors on tab switch | DS-01 | 1. Open console 2. Switch tabs | Zero console errors | — | — | ⬜ |
| TC-JS-04 | No JS errors on pagination click | DS-01 (12 stops) | 1. Open console 2. Click page 2 | Zero console errors | — | — | ⬜ |
| TC-JS-05 | No JS errors on chart toggle | DS-01 | 1. Open console 2. Toggle grouped/stacked | Zero console errors | — | — | ⬜ |
| TC-JS-06 | No JS errors when dataset empty | ED-06 | 1. Open console 2. Load with empty data | Zero errors — `renderNoDataMessage()` handles gracefully | — | — | ⬜ |
| TC-JS-07 | No JS errors on window resize | DS-01 | 1. Open console 2. Resize browser multiple times | Zero errors — `.resize()` guarded by null check | — | — | ⬜ |
| TC-JS-08 | Chart variable scoping: no global pollution | DS-01 | 1. Inspect `window.barChart`, `window.delayChart`, `window.utilChart` | Variables are function-scoped (not global) within DOMContentLoaded | — | — | ⬜ |
| TC-JS-09 | `renderNoDataMessage` handles null canvas | None | 1. Remove canvas from DOM 2. Call renderNoDataMessage | Function returns early without error (`if (!canvas) return`) | — | — | ⬜ |
| TC-JS-10 | Chart toggle works after resize | DS-01 | 1. Resize window 2. Toggle chart view | Toggle still functional; no stale reference | — | — | ⬜ |
| TC-JS-11 | daterangepicker init does not error on hidden inputs | DS-01 | 1. Check console for daterangepicker errors | No errors about missing `.transport_from_date` or `.transport_to_date` | — | — | ⬜ |
| TC-JS-12 | Multiple rapid tab switches don't cause race conditions | DS-01 | 1. Rapidly switch between tabs 3-4 times | Last tab loaded correctly; no duplicate content or broken state | — | — | ⬜ |

### 7.18 Cross-Browser & Responsive Test Cases

| TC ID | Description | Prerequisites | Test Steps | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|--------------|------------|-----------------|---------|---------|--------|
| TC-CB-01 | Chrome: All KPI boxes render with correct colors | DS-01 | 1. Load in Chrome 120+ 2. Inspect KPI boxes | Colors match: primary, success, warning, info | — | — | ⬜ |
| TC-CB-02 | Chrome: Chart.js renders all 3 charts | DS-01 | 1. Load in Chrome 2. Inspect canvases | All 3 charts rendered; Chart.js detected | — | — | ⬜ |
| TC-CB-03 | Firefox: All KPI boxes render with correct colors | DS-01 | 1. Load in Firefox 120+ 2. Inspect | Same as Chrome | — | — | ⬜ |
| TC-CB-04 | Firefox: Chart.js renders all 3 charts | DS-01 | 1. Load in Firefox 2. Inspect | All 3 charts rendered | — | — | ⬜ |
| TC-CB-05 | Edge: Tab navigation works | DS-01 | 1. Load in Edge 2. Switch tabs | Tab switch triggers AJAX | — | — | ⬜ |
| TC-CB-06 | Safari: daterangepicker opens correctly | DS-01 | 1. Load in Safari 2. Click date input | daterangepicker dropdown appears | — | — | ⬜ |
| TC-CB-07 | Mobile viewport (375px width): layout adapts | DS-01 | 1. Set viewport to 375px 2. Load page | KPI boxes stack vertically (col-6); table horizontally scrollable; filter bar wraps | — | — | ⬜ |
| TC-CB-08 | Tablet viewport (768px width): layout adapts | DS-01 | 1. Set viewport to 768px 2. Load page | KPI boxes 2x2 grid; charts stack vertically; filter bar wraps gracefully | — | — | ⬜ |
| TC-CB-09 | Desktop 1366px: standard layout | DS-01 | 1. Set viewport 1366px | 4-column KPI grid; 8+4 chart layout; full-width table | — | — | ⬜ |
| TC-CB-10 | Desktop 1920px widescreen: no excessive whitespace | DS-01 | 1. Set viewport 1920px 2. Inspect | Content centered; no excessive whitespace on sides | — | — | ⬜ |
| TC-CB-11 | Print stylesheet: table prints correctly | DS-01 | 1. Ctrl+P in browser | Table prints with all columns; progress bars show as text | — | — | ⬜ |
| TC-CB-12 | Dark mode (if supported): text contrast adequate | DS-01 | 1. Enable OS dark mode 2. Load page | Text readable; badges distinguishable | — | — | ⬜ |

### 7.19 Localization / Internationalization Test Cases

| TC ID | Description | Prerequisites | Test Steps | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|--------------|------------|-----------------|---------|---------|--------|
| TC-L10N-01 | Route name with Unicode characters | Create route "Hyderabad ↔ Secunderabad" | 1. Load report 2. Inspect route column | Unicode displayed correctly; no encoding issues | — | — | ⬜ |
| TC-L10N-02 | Stop name with non-ASCII characters | Create stop "São Paulo Stop" | 1. Load report 2. Inspect stop column | Accented characters render correctly | — | — | ⬜ |
| TC-L10N-03 | Date displayed in expected format | DS-01 | 1. Check any date display in view | No dates displayed in this view (daterangepicker uses YYYY-MM-DD format) | — | — | ⬜ |
| TC-L10N-04 | Time format consistency | DS-01 | 1. Inspect scheduled/actual time values | Display uses minutes (decimal), no AM/PM or locale-dependent format | — | — | ⬜ |
| TC-L10N-05 | Number formatting with decimal separator | DS-01 | 1. Check delay values like 7.5 | Uses period (.) as decimal separator regardless of locale | — | — | ⬜ |
| TC-L10N-06 | RTL language support (if applicable) | DS-01 | 1. Set dir="rtl" on HTML | Table layout, progress bar direction, chart axes adjust to RTL | — | — | ⬜ |

### 7.20 Accessibility (a11y) Test Cases

| TC ID | Description | Prerequisites | Test Steps | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|--------------|------------|-----------------|---------|---------|--------|
| TC-A11Y-01 | Filter inputs have associated labels | DS-01 | 1. Inspect form inputs | Each input has visible label or `aria-label` attribute | — | — | ⬜ |
| TC-A11Y-02 | Table headers use `<th>` elements | DS-01 | 1. Inspect table | 9 `<th>` elements with meaningful text content | — | — | ⬜ |
| TC-A11Y-03 | Images have alt text or are decorative only | DS-01 | 1. Inspect SVG icons | SVG icons use decorative role or have `aria-hidden="true"` | — | — | ⬜ |
| TC-A11Y-04 | Chart canvases have accessible fallback | DS-01 | 1. Inspect canvas elements | `<canvas>` has descriptive title or aria-label | — | — | ⬜ |
| TC-A11Y-05 | Color not sole means of conveying info | DS-01 | 1. Check delay badges | Badge text + color: "2.0 min" (not just green) | — | — | ⬜ |
| TC-A11Y-06 | Keyboard navigation: filter form | DS-01 | 1. Tab through filter controls | All controls focusable; submit via Enter works | — | — | ⬜ |
| TC-A11Y-07 | Keyboard navigation: pagination | DS-01 (12 stops) | 1. Tab to pagination links 2. Press Enter | Page changes correctly | — | — | ⬜ |
| TC-A11Y-08 | Keyboard: chart toggle buttons | DS-01 | 1. Tab to toggle buttons 2. Press Enter/Space | Chart view toggles | — | — | ⬜ |
| TC-A11Y-09 | Screen reader: progress bar percentage read | DS-01 | 1. Enable screen reader 2. Navigate to utilization cell | `aria-valuenow` or text content includes percentage | — | — | ⬜ |
| TC-A11Y-10 | Color contrast: badge text on colored background | DS-01 | 1. Measure contrast ratio | Badge text (#fff on green/yellow/red) has sufficient contrast (≥4.5:1) | — | — | ⬜ |

### 7.21 Data Aggregation / Computation Test Cases

| TC ID | Description | Prerequisites | Test Steps | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|--------------|------------|-----------------|---------|---------|--------|
| TC-DC-01 | Scheduled time avg: single trip stop detail | 1 route, 1 stop, 1 tsd with sch_arrival=07:00, sch_departure=07:10 | 1. Load report 2. Check scheduled time | `diffInSeconds(07:10, 07:00) / 60` = 10.0 min | — | — | ⬜ |
| TC-DC-02 | Scheduled time avg: multiple trip stop details | 1 stop, 3 tsd: (07:00-07:10=10min), (07:05-07:15=10min), (07:02-07:12=10min) | 1. Load report | Avg = (10+10+10)/3 = 10.0 min | — | — | ⬜ |
| TC-DC-03 | Scheduled time avg: mixed durations | 3 tsd: 10min, 15min, 20min | 1. Load report | Avg = (10+15+20)/3 = 15.0 min | — | — | ⬜ |
| TC-DC-04 | Actual time avg: single trip stop detail | reaching=07:12, leaving=07:22 | 1. Load report | `diffInSeconds(07:22, 07:12) / 60` = 10.0 min | — | — | ⬜ |
| TC-DC-05 | Variance positive: actual > scheduled | scheduled=10min, actual=15min | 1. Load report | Variance = 15 - 10 = 5.0 min (positive = slower) | — | — | ⬜ |
| TC-DC-06 | Variance negative: actual < scheduled | scheduled=10min, actual=8min | 1. Load report | Variance = 8 - 10 = -2.0 min (negative = faster) | — | — | ⬜ |
| TC-DC-07 | Variance zero: actual == scheduled | scheduled=10min, actual=10min | 1. Load report | Variance = 0.0 min | — | — | ⬜ |
| TC-DC-08 | Delay: arriving early (reaching < sch_arrival) | sch_arrival=08:00, reaching=07:55 | 1. Load report | Delay = -5.0 min (negative = early arrival) | — | — | ⬜ |
| TC-DC-09 | Delay: on time (reaching == sch_arrival) | sch_arrival=08:00, reaching=08:00 | 1. Load report | Delay = 0.0 min | — | — | ⬜ |
| TC-DC-10 | Delay: late (reaching > sch_arrival) | sch_arrival=08:00, reaching=08:12 | 1. Load report | Delay = 12.0 min | — | — | ⬜ |
| TC-DC-11 | Boarding count: 0 logs → count = 0 | ED-02 | 1. Load report | boarding_count = 0 | — | — | ⬜ |
| TC-DC-12 | Boarding count: 1 log → count = 1 | 1 boarding log | 1. Load report | boarding_count = 1 | — | — | ⬜ |
| TC-DC-13 | Boarding count: 100 logs → count = 100 | 100 boarding logs for 1 stop | 1. Load report | boarding_count = 100 | — | — | ⬜ |
| TC-DC-14 | Allocated: 0 allocations → 0 | ED-03 | 1. Load report | allocated_students = 0 | — | — | ⬜ |
| TC-DC-15 | Allocated: 50 unique students allocated to same stop | 50 distinct students allocated | 1. Load report | allocated_students = 50 | — | — | ⬜ |
| TC-DC-16 | Allocated: same student allocated twice → counted once | 1 student, 2 allocation records | 1. Load report | allocated_students = 1 (unique) | — | — | ⬜ |
| TC-DC-17 | Utilization: 0/0 = 0% (no boardings, no allocations) | ED-02 + ED-03 | 1. Load report | utilization = 0% (division guarded) | — | — | ⬜ |
| TC-DC-18 | Utilization: 25/100 = 25% | 25 boardings, 100 allocated | 1. Load report | utilization = 25% | — | — | ⬜ |
| TC-DC-19 | Utilization: 80/100 = 80% | 80 boardings, 100 allocated | 1. Load report | utilization = 80% | — | — | ⬜ |
| TC-DC-20 | Utilization: 100/100 = 100% | 100 boardings, 100 allocated | 1. Load report | utilization = 100% | — | — | ⬜ |
| TC-DC-21 | Utilization: 150/100 → capped at 100% in progress bar | ED-04 | 1. Load report 2. Inspect progress bar | `min(150, 100) = 100%` width; utilization text shows 150% but bar caps | — | — | ⬜ |
| TC-DC-22 | KPI: Overall utilization = sum(boardings)/sum(allocated)*100 | DS-01+DS-02: 100/120=83.3% | 1. Load report | KPI shows 83.3% | — | — | ⬜ |
| TC-DC-23 | KPI: Overall utilization when total allocated = 0 | All stops have 0 allocations | 1. Load report | KPI = 0% (guarded) | — | — | ⬜ |

### 7.22 Route & Stop Filter Interaction Test Cases

| TC ID | Description | Prerequisites | Test Steps | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|--------------|------------|-----------------|---------|---------|--------|
| TC-FI-01 | Route filter with stop filter: stop belongs to selected route | DS-01: Route A, Stop-A2 | 1. Select Route A + Stop-A2 2. Submit | Only Stop-A2 on Route A shown (1 row) | — | — | ⬜ |
| TC-FI-02 | Route filter with stop filter: stop does NOT belong to selected route | DS-01, DS-02: Route A + Stop-B1 | 1. Select Route A + Stop-B1 2. Submit | Empty results (Stop-B1 not on Route A, whereHas returns no routes) | — | — | ⬜ |
| TC-FI-03 | Route filter clears stop dropdown automatically | DS-01, DS-02 | 1. Select Route A 2. Check stop dropdown contents | Stop dropdown still shows all stops (no cascading); user can select any stop | — | — | ⬜ |
| TC-FI-04 | Date filter affects only boarding count, not allocated students | DS-01 | 1. Set date to period with 0 boarding logs but valid allocations | Boardings = 0; Allocated shows same as before (all-time) | — | — | ⬜ |
| TC-FI-05 | Date filter affects delay computation (via tripStopDetails not filtered by date) | Multiple months of data | 1. Filter to Month 1 2. Compare with Month 2 | Note: tripStopDetails are NOT date-filtered in controller. Delay is computed from ALL reached_flag=1 records regardless of date | — | — | ⬜ |
| TC-FI-06 | All route dropdown options populated from DB | DS-01 through DS-05 | 1. Open route dropdown | Options: Route A, Route B, Route C (Route D excluded as inactive, Route E) | — | — | ⬜ |
| TC-FI-07 | All stop dropdown options populated from DB | All pickup points | 1. Open stop dropdown | All active pickup points listed | — | — | ⬜ |
| TC-FI-08 | Filter form has hidden active_tab input | DS-01 | 1. Inspect form | `<input type="hidden" name="active_tab" value="stop-analysis">` | — | — | ⬜ |
| TC-FI-09 | Filter form includes hidden from_date / to_date | DS-01 | 1. Inspect form | `<input type="hidden" name="from_date">` + `<input type="hidden" name="to_date">` | — | — | ⬜ |
| TC-FI-10 | Multiple sequential filters stack correctly | DS-01, DS-02 | 1. Filter Route A 2. Then filter Stop-A1 3. Then change date | All 3 filters applied: Route A, Stop-A1, date range | — | — | ⬜ |

### 7.23 Chart.js Detailed Configuration Test Cases

| TC ID | Description | Prerequisites | Test Steps | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|--------------|------------|-----------------|---------|---------|--------|
| TC-CH-01 | Boarding bar chart: `type: 'bar'` | DS-01 | 1. Inspect Chart constructor | Chart type set to `bar` | — | — | ⬜ |
| TC-CH-02 | Boarding bar chart: legend at top with point style | DS-01 | 1. Inspect legend config | `legend.position = 'top'`, `legend.labels.usePointStyle = true` | — | — | ⬜ |
| TC-CH-03 | Boarding bar chart: y-axis begins at zero | DS-01 | 1. Inspect y-axis config | `y.beginAtZero = true` | — | — | ⬜ |
| TC-CH-04 | Boarding bar chart: y-axis title "Number of Students" | DS-01 | 1. Inspect y-axis title | `title.text = 'Number of Students'`, `title.display = true` | — | — | ⬜ |
| TC-CH-05 | Boarding bar chart: x-axis labels rotated 45° | DS-01 | 1. Inspect x-axis ticks | `ticks.maxRotation = 45`, `ticks.minRotation = 45` | — | — | ⬜ |
| TC-CH-06 | Boarding bar chart: interaction mode 'index' | DS-01 | 1. Hover over a bar | Tooltip shows both datasets for that index (intersect: false, mode: 'index') | — | — | ⬜ |
| TC-CH-07 | Boarding bar chart: tooltip label format | DS-01 | 1. Hover over boarding bar | Tooltip: "Actual Boardings: 15 students" with utilization subtext | — | — | ⬜ |
| TC-CH-08 | Delay chart: `indexAxis: 'y'` (horizontal) | DS-01 | 1. Inspect delay chart config | `indexAxis: 'y'` | — | — | ⬜ |
| TC-CH-09 | Delay chart: no legend displayed | DS-01 | 1. Inspect legend config | `legend.display = false` | — | — | ⬜ |
| TC-CH-10 | Delay chart: tooltip shows schedule details | DS-01 | 1. Hover over delay bar | Tooltip: "Scheduled: 10 min", "Actual: 12 min", "Avg Delay: 2.0 minutes" | — | — | ⬜ |
| TC-CH-11 | Delay chart: x-axis title "Delay (minutes)" | DS-01 | 1. Inspect x-axis | `x.title.text = 'Delay (minutes)'` | — | — | ⬜ |
| TC-CH-12 | Utilization chart: `indexAxis: 'y'` (horizontal) | DS-01 | 1. Inspect util chart config | `indexAxis: 'y'` | — | — | ⬜ |
| TC-CH-13 | Utilization chart: no legend displayed | DS-01 | 1. Inspect config | `legend.display = false` | — | — | ⬜ |
| TC-CH-14 | Utilization chart: x-axis ticks with % suffix | DS-01 | 1. Inspect x-axis ticks callback | `ticks.callback: function(v) { return v + '%'; }` | — | — | ⬜ |
| TC-CH-15 | Utilization chart: x-axis title "Utilization Rate (%)" | DS-01 | 1. Inspect config | `x.title.text = 'Utilization Rate (%)'` | — | — | ⬜ |
| TC-CH-16 | Utilization chart: x-axis max = 100 | DS-01 | 1. Inspect x-axis | `x.max = 100` | — | — | ⬜ |
| TC-CH-17 | All charts: `responsive: true`, `maintainAspectRatio: false` | DS-01 | 1. Inspect all chart configs | True for both properties on all charts | — | — | ⬜ |
| TC-CH-18 | Boarding bar chart: dataset border radius | DS-01 | 1. Inspect dataset config | `borderRadius: 4` | — | — | ⬜ |
| TC-CH-19 | Bar chart grouped mode: bars side by side | DS-01 | 1. Ensure grouped mode 2. Inspect bars | Allocated and Boarding bars adjacent per label | — | — | ⬜ |
| TC-CH-20 | Bar chart stacked mode: bars on top of each other | DS-01 | 1. Switch to stacked mode 2. Inspect bars | Allocated bar at bottom, Boarding bar stacked on top | — | — | ⬜ |

### 7.24 Model Relationship Integrity Test Cases

| TC ID | Description | Prerequisites | Test Steps | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|--------------|------------|-----------------|---------|---------|--------|
| TC-MR-01 | `Route` model has `pickupPointRoutes` relationship | None | 1. Inspect Route model | `pickupPointRoutes` defined as HasMany or BelongsToMany | — | — | ⬜ |
| TC-MR-02 | `PickupPointRoute` model has `pickupPoint` relationship | None | 1. Inspect PickupPointRoute model | `pickupPoint` defined as BelongsTo | — | — | ⬜ |
| TC-MR-03 | `PickupPoint` model has `tripStopDetails` relationship | None | 1. Inspect PickupPoint model | `tripStopDetails` defined | — | — | ⬜ |
| TC-MR-04 | `PickupPoint` model has `boardingLogs` relationship | None | 1. Inspect PickupPoint model | `boardingLogs` defined | — | — | ⬜ |
| TC-MR-05 | `PickupPoint` model has `studentAllocations` relationship | None | 1. Inspect PickupPoint model | `studentAllocations` defined | — | — | ⬜ |
| TC-MR-06 | `StudentAllocation` has `student` relationship | None | 1. Inspect TptStudentAllocationJnt model | `student` defined as BelongsTo | — | — | ⬜ |
| TC-MR-07 | `Route` model has `active()` scope | None | 1. Inspect Route model | `scopeActive()` defined | — | — | ⬜ |
| TC-MR-08 | `PickupPoint` model has `active()` scope | None | 1. Inspect PickupPoint model | `scopeActive()` defined (used in `getFilterData()`) | — | — | ⬜ |
| TC-MR-09 | [Query/Code Removed] | DS-01 | 1. Execute query in tinker | Nested eager load returns all levels without error | — | — | ⬜ |
| TC-MR-10 | 3-level eager load generates 6 queries max | DS-01 | 1. Enable query log 2. Load report 3. Count queries | Max 6 queries (routes, pickupPointRoutes, pickupPoints, tripStopDetails, boardingLogs, studentAllocations) | — | — | ⬜ |

### 7.25 Blade View Rendering Test Cases

| TC ID | Description | Prerequisites | Test Steps | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|--------------|------------|-----------------|---------|---------|--------|
| TC-BL-01 | Charts section: `@php` block executes without error | DS-01 | 1. Load section=charts 2. Check any PHP error | No errors; variables populated correctly | — | — | ⬜ |
| TC-BL-02 | Charts section: `@json` produces valid JSON arrays | DS-01 | 1. Inspect rendered JS | `const labels = ["Stop-A1","Stop-A2",...]` — valid array | — | — | ⬜ |
| TC-BL-03 | Charts section: script has no syntax errors | DS-01 | 1. Load page 2. Check console | No JS syntax errors | — | — | ⬜ |
| TC-BL-04 | Charts section: `@json` handles null/empty collection | ED-06 | 1. Load charts with empty data | `const labels = []` — empty array, not null | — | — | ⬜ |
| TC-BL-05 | Table section: `@forelse` with `$stopAnalysisReportsPaginated` | DS-01 | 1. Load table 2. Inspect rows | Rows rendered from paginator; `$loop` variable available | — | — | ⬜ |
| TC-BL-06 | Table section: `@empty` block renders correctly | ED-06 | 1. Load table with empty data | `<td colspan="9">` with `bi-inbox` icon | — | — | ⬜ |
| TC-BL-07 | Table section: pagination `->appends()` preserves ALL query params | DS-01 | 1. Filter by route 2. Navigate to page 2 | URL contains `route_id=X&page_stop=2` | — | — | ⬜ |
| TC-BL-08 | Full page load: hub view renders `container-fluid` | DS-01 | 1. Load full page | `<div class="container-fluid">` present | — | — | ⬜ |
| TC-BL-09 | Full page load: breadcrumb renders correctly | DS-01 | 1. Inspect breadcrumb | `<x-backend.components.breadcrum title="Transport Report" :links="[]" />` renders as breadcrumb | — | — | ⬜ |
| TC-BL-10 | Full page load: all 11 tab nav items rendered | DS-01 | 1. Count tab buttons | 11 tab items with correct labels and icons | — | — | ⬜ |

### 7.26 Error Boundary & Recovery Test Cases

| TC ID | Description | Prerequisites | Test Steps | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|--------------|------------|-----------------|---------|---------|--------|
| TC-ER-01 | AJAX charts fails → error message shown + retry possible | Simulate 500 for section=charts | 1. Load page 2. Wait for error 3. Click filter button again | Error alert shown; filter resubmit triggers new AJAX call | — | — | ⬜ |
| TC-ER-02 | AJAX table fails → error message shown + retry possible | Simulate 500 for section=table | 1. Load page 2. Wait for error 3. Click pagination | Error alert shown; pagination click triggers new AJAX call | — | — | ⬜ |
| TC-ER-03 | AJAX timeout (30s+) → graceful degradation | Throttle network | 1. Load with extremely slow network | Timeout after ~30s; error handler shows failure message | — | — | ⬜ |
| TC-ER-04 | Server DB connection failure → Laravel error page | Stop MySQL | 1. Load page | 500 error page (not blank screen) | — | — | ⬜ |
| TC-ER-05 | Server memory exhaustion with large dataset | 10000+ stops | 1. Load report | PHP memory limit error or partial page (handled by Laravel error handler) | — | — | ⬜ |
| TC-ER-06 | Invalid JSON response from AJAX | Corrupt response | 1. Mock malformed response | jQuery AJAX error handler fires; error message displayed | — | — | ⬜ |
| TC-ER-07 | Network disconnect during AJAX | Cut network mid-load | 1. Load page 2. Disconnect WiFi | Error handler fires; message shown | — | — | ⬜ |
| TC-ER-08 | Multiple AJAX calls stacking if user clicks rapidly | DS-01 | 1. Rapidly click pagination 10 times | Last click wins; no data corruption or duplicate rows | — | — | ⬜ |
| TC-ER-09 | Browser back/forward navigation with query params | DS-01 | 1. Apply filter 2. Navigate to page 2 3. Press browser Back | Previous filter state restored; AJAX re-fetches with previous params | — | — | ⬜ |
| TC-ER-10 | Page refresh during AJAX load | DS-01 | 1. Load page 2. Refresh mid-AJAX | Clean page load; no residual loading state | — | — | ⬜ |

### 7.27 Concurrency & Race Condition Test Cases

| TC ID | Description | Prerequisites | Test Steps | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|--------------|------------|-----------------|---------|---------|--------|
| TC-CR-01 | Two users access same report simultaneously | 2 test accounts, same DS-01 | 1. User A loads report 2. User B loads report simultaneously | Both users see correct data; no locking conflicts (read-only) | — | — | ⬜ |
| TC-CR-02 | User applies filter while data is being seeded | Seeding in progress | 1. Start bulk data seeding 2. Load report during seeding | Partial data may show; no crash or inconsistent query state | — | — | ⬜ |
| TC-CR-03 | Rapid tab switch between stop-analysis and another tab | DS-01 | 1. Rapidly click stop-analysis ↔ another tab 5 times | Last active tab loaded correctly; no tab state corruption | — | — | ⬜ |
| TC-CR-04 | Charts and table AJAX responses arrive out of order | Simulated delayed charts response | 1. Load page 2. Charts delayed by 5s | Both sections load independently; one doesn't block the other | — | — | ⬜ |
| TC-CR-05 | Filter change while previous AJAX in flight | DS-01 | 1. Submit filter 2. Immediately submit different filter | Second request replaces first; no duplicate rendering | — | — | ⬜ |

### 7.28 Model Factory / Seeder Validation Test Cases

| TC ID | Description | Prerequisites | Test Steps | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|--------------|------------|-----------------|---------|---------|--------|
| TC-SD-01 | Test dataset DS-01 can be seeded without errors | Factory definitions exist | 1. Run seeder for DS-01 | All records created; no FK constraint violations | — | — | ⬜ |
| TC-SD-02 | Test data produces expected KPI values | DS-01 seeded | 1. Load report 2. Verify KPI values | KPI values match computed expectations | — | — | ⬜ |
| TC-SD-03 | Route with is_active=0 excluded from report | DS-04 seeded | 1. Load report | Route D not in results | — | — | ⬜ |
| TC-SD-04 | Stop with mixed reached_flag values | Stop has 3 tsd: 2 with flag=1, 1 with flag=0 | 1. Load report 2. Verify delay computation | Only 2 records contribute to delay avg; flag=0 excluded | — | — | ⬜ |
| TC-SD-05 | Test data can be cleaned up (rollback) | DS-01 through DS-05 seeded | 1. Run teardown/rollback | All test data removed cleanly | — | — | ⬜ |

### 7.29 Exploratory Testing Scenarios

| TC ID | Scenario | Exploration Focus | Expected Behavior | Notes |
|-------|----------|-------------------|-------------------|-------|
| TC-EX-01 | Open report with 500+ stops | Performance, rendering, pagination | Page loads within 5s; pagination works; chart renders (may be cluttered) | — |
| TC-EX-02 | Apply filter, then use browser Back/Forward | History navigation | Browser history should preserve filter state | — |
| TC-EX-03 | Open report in incognito/private window | Session, auth, cache | Redirect to login if unauthenticated | — |
| TC-EX-04 | Modify page_stop manually in URL to page 999 | Edge case pagination | Out of range shows empty page gracefully | — |
| TC-EX-05 | Set from_date > to_date | Input validation | daterangepicker should swap or display no results | — |
| TC-EX-06 | Use extremely long date range (10 years) | Query performance | Query may be slow; potentially memory issue with large boarding logs dataset | — |
| TC-EX-07 | Open report then quickly close browser tab | Abandoned AJAX | No error propagated; abandoned | — |
| TC-EX-08 | Remove canvas elements via DOM inspector | JS resilience | Chart init fails gracefully (canvas not found → no chart) | — |
| TC-EX-09 | Modify filter values via browser devtools | Tampering, validation | Backend query handles invalid values gracefully | — |
| TC-EX-10 | Load report on mobile data (3G throttled) | Real-world performance | Acceptable load time under 10s for both sections | — |

### 7.30 Dependency & Side-Effect Test Cases

| TC ID | Description | Prerequisites | Test Steps | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|--------------|------------|-----------------|---------|---------|--------|
| TC-DP-01 | Stop-analysis tab does NOT depend on any other tab's state | DS-01 | 1. Load route-performance tab first 2. Switch to stop-analysis | Stop-analysis loads independently; no cross-tab state coupling | — | — | ⬜ |
| TC-DP-02 | Filter change on stop-analysis does NOT affect other tabs | DS-01 | 1. Apply filter on stop-analysis 2. Switch to another tab | Other tab shows unfiltered data | — | — | ⬜ |
| TC-DP-03 | `paginateCollection` does NOT mutate original collection | DS-01 | 1. Call paginateCollection 2. Check original collection | Original collection unchanged; paginator is a view over the data | — | — | ⬜ |
| TC-DP-04 | `buildStopAnalysisSection` does NOT modify `$reqFilters` | DS-01 | 1. Call builder 2. Check input array | Original array not modified (passed by value) | — | — | ⬜ |
| TC-DP-05 | `getRouteStopAnalysis` result is not cached across requests | DS-01 | 1. Load report 2. Update DB data 3. Reload | Fresh data returned; no stale cache | — | — | ⬜ |
| TC-DP-06 | Page_stop param does not conflict with other paginator params | DS-01 | 1. Load stop-analysis page 2 2. Check URL | `?page_stop=2` not `?page=2` | — | — | ⬜ |

### 7.31 Browser Developer Tools & Debugging Test Cases

| TC ID | Description | Prerequisites | Test Steps | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|--------------|------------|-----------------|---------|---------|--------|
| TC-DBG-01 | Network tab shows 2 AJAX requests on page load | DS-01 | 1. Open Network tab 2. Load page | 2 XHR requests to `/transport-report?active_tab=stop-analysis&section=charts` and `section=table` | — | — | ⬜ |
| TC-DBG-02 | Network tab: AJAX requests have 200 status | DS-01 | 1. Load page 2. Check Network tab | Both requests return HTTP 200 | — | — | ⬜ |
| TC-DBG-03 | Network tab: AJAX response size under 50KB | DS-01 | 1. Inspect response size | Charts HTML < 30KB; Table HTML < 20KB | — | — | ⬜ |
| TC-DBG-04 | Elements tab: DOM updated after AJAX load | DS-01 | 1. Inspect `#stop-analysis-charts` 2. Before and after load | Empty spinner div replaced with KPI+charts HTML | — | — | ⬜ |
| TC-DBG-05 | Console: Chart.js version logged | DS-01 | 1. Check console for Chart.js | No version log (not explicitly logged but detectable via `Chart.version`) | — | — | ⬜ |
| TC-DBG-06 | Application tab: session storage not polluted | DS-01 | 1. Check sessionStorage / localStorage after load | No stop-analysis specific keys in storage | — | — | ⬜ |
| TC-DBG-07 | Lighthouse performance score > 80 | DS-01 | 1. Run Lighthouse audit | Performance score acceptable; no render-blocking issues | — | — | ⬜ |
| TC-DBG-08 | No 404 errors for any resource | DS-01 | 1. Load page 2. Check Network tab for 404s | Zero 404 errors | — | — | ⬜ |

### 7.32 Timezone & Date Handling Test Cases

| TC ID | Description | Prerequisites | Test Steps | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|--------------|------------|-----------------|---------|---------|--------|
| TC-TZ-01 | Date filter works with `YYYY-MM-DD` format | DS-01 | 1. Set date range via daterangepicker 2. Check hidden inputs | `from_date=2026-07-01`, `to_date=2026-07-31` | — | — | ⬜ |
| TC-TZ-02 | Month boundary: last day of month vs first day of next month | DS-01 | 1. Set range: July 31 to Aug 1 2. Submit | Correct data for both dates | — | — | ⬜ |
| TC-TZ-03 | Year boundary: Dec 31 to Jan 1 | DS-01 | 1. Set range: Dec 31 2025 to Jan 1 2026 2. Submit | Correct data across year boundary | — | — | ⬜ |
| TC-TZ-04 | Single-day date range | DS-01 | 1. Set same date for from and to | Data for that single day shown | — | — | ⬜ |
| TC-TZ-05 | Trip date comparison: `whereBetween` inclusive? | DS-01 | 1. Set range: July 1 to July 1 2. Verify | `whereBetween` includes both boundaries; data from July 1 shown | — | — | ⬜ |
| TC-TZ-06 | Future date range → empty results | DS-01 | 1. Set range to next year | No boarding logs found; empty table | — | — | ⬜ |
| TC-TZ-07 | Past date range before any data → empty results | DS-01 | 1. Set range to 2020 | No data; empty state | — | — | ⬜ |
| TC-TZ-08 | Default date range: current month | DS-01 (data in current month) | 1. Load page without date params | from_date = month start, to_date = month end | — | — | ⬜ |

### 7.33 Accessibility Deep-Dive Test Cases

| TC ID | Description | Prerequisites | Test Steps | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|--------------|------------|-----------------|---------|---------|--------|
| TC-A11Y-D1 | WCAG 2.1 AA compliance: color contrast | DS-01 | 1. Run axe-core or WAVE tool | All text elements meet 4.5:1 contrast ratio | — | — | ⬜ |
| TC-A11Y-D2 | WCAG 2.1 AA: focus indicators visible | DS-01 | 1. Tab through all interactive elements | Each element has visible focus ring/outline | — | — | ⬜ |
| TC-A11Y-D3 | Screen reader: table header associations | DS-01 | 1. Inspect `<th>` scope attributes | `<th scope="col">` on each header (or implicit via `<thead>`) | — | — | ⬜ |
| TC-A11Y-D4 | Screen reader: tab role and aria-selected | DS-01 | 1. Inspect tab buttons | `role="tab"`, `aria-selected="true/false"` — managed by Bootstrap | — | — | ⬜ |
| TC-A11Y-D5 | Screen reader: loading state announced | DS-01 | 1. Check spinner span | `<span class="visually-hidden">Loading...</span>` present | — | — | ⬜ |
| TC-A11Y-D6 | Screen reader: pagination nav landmark | DS-01 (12 stops) | 1. Inspect pagination | `<nav aria-label="Pagination">` or similar landmark | — | — | ⬜ |
| TC-A11Y-D7 | Zoom 200%: layout still functional | DS-01 | 1. Set browser zoom to 200% | Content readable; no overlapping elements; horizontal scroll available for table | — | — | ⬜ |
| TC-A11Y-D8 | No keyboard trap in filter form | DS-01 | 1. Tab through filter form | Focus moves through all elements; no trap | — | — | ⬜ |

### 7.34 Negative Filter Combinations

| TC ID | Description | Prerequisites | Test Steps | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|--------------|------------|-----------------|---------|---------|--------|
| TC-NF-01 | Empty string for route_id | DS-01 | 1. Set `route_id=` 2. Submit | Treated as no filter (empty string is falsy in `when()`) | — | — | ⬜ |
| TC-NF-02 | Empty string for stop_id | DS-01 | 1. Set `stop_id=` 2. Submit | Treated as no filter | — | — | ⬜ |
| TC-NF-03 | Invalid date format in from_date | DS-01 | 1. Set `from_date=invalid` 2. Submit | [Query/Code Removed] | — | — | ⬜ |
| TC-NF-04 | XSS in search-like fields (no search field in this report) | DS-01 | 1. No search field in filter bar | N/A — this report has no text search input | — | — | ⬜ |
| TC-NF-05 | Multiple route_id values (array) | DS-01 | 1. Set `route_id[]=1&route_id[]=2` 2. Submit | [Query/Code Removed] | — | — | ⬜ |
| TC-NF-06 | Very large integer for route_id (PHP max int) | DS-01 | 1. Set `route_id=999999999999` 2. Submit | No matching route; empty results | — | — | ⬜ |
| TC-NF-07 | Null byte injection in filter params | DS-01 | 1. Set `route_id=1%00` 2. Submit | Eloquent parameterization prevents null byte issues | — | — | ⬜ |
| TC-NF-08 | Unicode control characters in stop dropdown value | DS-01 | 1. Submit with encoded control characters | Where clause finds no match; empty results | — | — | ⬜ |

### 7.35 Model-Specific Constraint Test Cases

| TC ID | Description | Prerequisites | Test Steps | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|--------------|------------|-----------------|---------|---------|--------|
| TC-MC-01 | `Route` with null `name` | Create Route with name=null | 1. Load report | `$route->name` returns null; display shows empty string or error | — | — | ⬜ |
| TC-MC-02 | `PickupPoint` with null `name` | Create stop with name=null | 1. Load report | `$stop->name` returns null; display shows empty or "-" | — | — | ⬜ |
| TC-MC-03 | `TptTripStopDetail` with null Carbon fields | tsd with sch_arrival_time = null | 1. Load report | `optional(null)->diffInSeconds(...)` returns null; avg skips null values | — | — | ⬜ |
| TC-MC-04 | `StudentBoardingLog` with null trip_date | log with trip_date = null | 1. Load report | `whereBetween` excludes null; log not counted | — | — | ⬜ |
| TC-MC-05 | `TptStudentAllocationJnt` with null student_id | allocation with student_id = null | 1. Load report | `unique('student_id')` may count null as a distinct value | — | — | ⬜ |
| TC-MC-06 | Soft-deleted Route | Route soft-deleted | 1. Load report | `->active()` scope likely excludes soft-deleted; route not in results | — | — | ⬜ |
| TC-MC-07 | Soft-deleted PickupPoint | Stop soft-deleted | 1. Load report | `->active()` scope likely excludes soft-deleted; stop not in results | — | — | ⬜ |
| TC-MC-08 | `boardingLogs` with trip_date in past but reached_flag = 0 | Boarding log exists but no trip completion | 1. Load report | Boarding counted; delay computed from other tsd records | — | — | ⬜ |

### 7.36 Security Test Cases

| TC ID | Description | Prerequisites | Test Steps | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|--------------|------------|-----------------|---------|---------|--------|
| TC-SC-01 | SQL injection in route_id parameter | DS-01 | 1. Set `route_id=1 OR 1=1` 2. Submit | `where('id', '1 OR 1=1')` — Eloquent parameterization prevents injection | — | — | ⬜ |
| TC-SC-02 | XSS in stop name | Create stop with `<script>alert(1)</script>` | 1. Load report 2. Inspect stop column | Blade `{{ }}` escapes HTML; script not executed | — | — | ⬜ |
| TC-SC-03 | XSS in route name | Create route with `<img onerror=alert(1) src=x>` | 1. Load report 2. Inspect route column | Blade escaping prevents XSS | — | — | ⬜ |
| TC-SC-04 | Unauthorized AJAX direct access | Not logged in | 1. Send AJAX without auth cookie | Returns 302 redirect or 401 | — | — | ⬜ |
| TC-SC-05 | CSRF on AJAX endpoint | None (GET requests) | 1. Verify AJAX uses GET | GET requests are idempotent; no CSRF token needed | — | — | ⬜ |
| TC-SC-06 | Mass assignment protection | N/A (no write operations) | 1. Verify report is read-only | No create/update/delete endpoints in stop-analysis; read-only by design | — | — | ⬜ |
| TC-SC-07 | `active_tab` parameter tampering | DS-01 | 1. Set `active_tab=../../etc/passwd` 2. Submit | Match block falls to default: `<p class="text-muted">Invalid tab</p>` — no path traversal | — | — | ⬜ |
| TC-SC-08 | `page_stop` parameter tampering | DS-01 | 1. Set `page_stop[]=malicious` 2. Submit | Paginator resolves to default page 1; no error | — | — | ⬜ |

---

## 8. Traceability Matrix

### 8.1 Requirement to Test Case Mapping

| BC ID | TC IDs |
|-------|--------|
| BC-QL-01 | TC-CR01, TC-DI-10 |
| BC-QL-02 | TC-DI-08 |
| BC-QL-03 | TC-P59, TC-DI-07 |
| BC-QL-04 | TC-P56, TC-P58 |
| BC-QL-05 | TC-P57, TC-P58 |
| BC-QL-06 | TC-N02, TC-DI-09 |
| BC-QL-07 | TC-CR02, TC-DI-10 |
| BC-QL-08 | TC-DI-03 |
| BC-QL-09 | TC-DI-04 |
| BC-QL-10 | TC-DI-05, TC-CR03 |
| BC-QL-11 | TC-DI-06 |
| BC-QL-12 | TC-DI-01 |
| BC-QL-13 | TC-DI-02 |
| BC-BIZ-01 | TC-P54, TC-N13 |
| BC-BIZ-02 | TC-P54, TC-N14 |
| BC-BIZ-03 | TC-P55, TC-N15 |
| BC-BIZ-04 | TC-N01, TC-P53 |
| BC-BIZ-05 | TC-EC-17, TC-CR05 |
| BC-BIZ-06 | TC-N02 |
| BC-BIZ-07 | TC-DI-09 |
| BC-BIZ-08 | TC-CR02 |
| BC-BIZ-09 | TC-DI-07 |
| BC-BIZ-10 | TC-DI-02 |
| BC-BIZ-11 | TC-DI-08 |
| BC-BIZ-12 | TC-EC-18 |
| BC-UI-01 | TC-P03 |
| BC-UI-02 | TC-P04 |
| BC-UI-03 | TC-P01 |
| BC-UI-04 | TC-P02, TC-UI-20 |
| BC-UI-05 | TC-AJ-05, TC-AJ-06 |
| BC-UI-06 | TC-AJ-07 |
| BC-UI-07 | TC-P35 |
| BC-UI-08 | TC-P53 |
| BC-UI-09 | TC-P20, TC-P21 |
| BC-UI-10 | TC-P34 |
| BC-AJ-01 | TC-P03, TC-P04, TC-AJ-01 |
| BC-AJ-02 | TC-P05 |
| BC-AJ-03 | TC-P06 |
| BC-AJ-04 | TC-P67, TC-AJ-03 |
| BC-AJ-05 | TC-P69, TC-P70, TC-AJ-04 |
| BC-AJ-06 | TC-P71, TC-P72 |
| BC-AJ-07 | TC-P01 |
| BC-AJ-08 | TC-AJ-08 |

### 8.2 TC Category Distribution

| Category | TC ID Range | Count | Coverage Focus |
|----------|-------------|-------|----------------|
| Positive — Tab Loading | TC-P01 to TC-P06 | 6 | Initial load, skeleton, AJAX, tab switch |
| Positive — KPI Boxes | TC-P07 to TC-P17 | 11 | KPI accuracy, color, format |
| Positive — Charts | TC-P18 to TC-P35 | 18 | Chart rendering, toggle, color, empty state |
| Positive — Table | TC-P36 to TC-P55 | 20 | Column rendering, badges, progress bars, empty state |
| Positive — Filters | TC-P56 to TC-P68 | 13 | Route, stop, date filters, reset |
| Positive — Pagination | TC-P69 to TC-P75 | 7 | Page navigation, page_stop param |
| Negative | TC-N01 to TC-N20 | 20 | No data, missing relationships, permissions, CDN failures, invalid inputs |
| Edge Case | TC-EC-01 to TC-EC-18 | 18 | Boundaries at 0, 5, 15, 60, 80, 100, anomalies |
| Permission & Access | TC-PM-01 to TC-PM-05 | 5 | Gate checks, tab visibility |
| AJAX & SPA | TC-AJ-01 to TC-AJ-10 | 10 | Parallel loads, opacity, error, race |
| Data Integrity | TC-DI-01 to TC-DI-10 | 10 | Count accuracy, dedup, time computation, scope |
| Code Review | TC-CR-01 to TC-CR-20 | 20 | N+1, flatMap, division guards, null safety |
| UI/UX | TC-UI-01 to TC-UI-20 | 20 | Style, responsive, hover, skeleton |
| Performance | TC-PF-01 to TC-PF-06 | 6 | Query count, memory, chart rendering |
| Regression | TC-RG-01 to TC-RG-06 | 6 | Cross-tab interference, shared resources |
| API Contract | TC-API-01 to TC-API-10 | 10 | Response format, HTML structure |
| JavaScript Console | TC-JS-01 to TC-JS-12 | 12 | No errors, null guards, scoping |
| Cross-Browser | TC-CB-01 to TC-CB-12 | 12 | Chrome, Firefox, Edge, Safari, mobile, print |
| Localization | TC-L10N-01 to TC-L10N-06 | 6 | Unicode, encoding, format |
| Accessibility | TC-A11Y-01 to TC-A11Y-10 | 10 | Labels, headers, contrast, keyboard |
| Computation | TC-DC-01 to TC-DC-23 | 23 | Time avg, variance, delay, boarding count, allocation, utilization |
| Filter Interaction | TC-FI-01 to TC-FI-10 | 10 | Cross-filter, date vs allocation |
| Chart Config | TC-CH-01 to TC-CH-20 | 20 | Chart type, axis, tooltip, legend |
| Model Relationships | TC-MR-01 to TC-MR-10 | 10 | Eager loading, scopes, relationship existence |
| Blade Rendering | TC-BL-01 to TC-BL-10 | 10 | PHP blocks, forelse, pagination, hub view |
| Error Recovery | TC-ER-01 to TC-ER-10 | 10 | AJAX failure, timeout, network, back/forward |
| Concurrency | TC-CR-01 to TC-CR-05 | 5 | Race conditions, rapid clicks |
| Seeder Validation | TC-SD-01 to TC-SD-05 | 5 | Factory, cleanup |
| Exploratory | TC-EX-01 to TC-EX-10 | 10 | Real-world scenarios |
| Dependency | TC-DP-01 to TC-DP-06 | 6 | Cross-tab isolation, immutability |
| Debugging | TC-DBG-01 to TC-DBG-08 | 8 | Network, DOM, console, Lighthouse |
| Timezone | TC-TZ-01 to TC-TZ-08 | 8 | Date range, boundaries, default |
| Accessibility Deep | TC-A11Y-D1 to TC-A11Y-D8 | 8 | WCAG, zoom, screen reader |
| Negative Filters | TC-NF-01 to TC-NF-08 | 8 | Invalid inputs, edge params |
| Model Constraints | TC-MC-01 to TC-MC-08 | 8 | Null fields, soft-delete, constraints |
| Security | TC-SC-01 to TC-SC-08 | 8 | SQLi, XSS, CSRF, tampering |
| **Total** | | **~400** | |

### 8.3 CODE-TRACE to Test Case Mapping

| Trace Step | TC IDs |
|-----------|--------|
| TR-01-01 | TC-PM-03, TC-N05 |
| TR-01-02 | TC-P01, TC-P06 |
| TR-01-03 | TC-P03, TC-P04, TC-API-01, TC-API-02 |
| TR-01-04 | TC-P56 to TC-P68, TC-FI-01 to TC-FI-10 |
| TR-01-05 | TC-P63, TC-P64, TC-P65, TC-P66, TC-TZ-01 to TC-TZ-08 |
| TR-01-06 | TC-AJ-01, TC-AJ-02 |
| TR-01-07 | TC-N06, TC-N07, TC-API-10 |
| TR-01-08 | TC-P61, TC-P62, TC-MR-08 |
| TR-01-09 | TC-BL-08, TC-BL-09, TC-BL-10 |
| TR-02-01 | TC-CR20 |
| TR-02-02 | TC-DC-01 to TC-DC-23, TC-DI-01 to TC-DI-10 |
| TR-02-03 | TC-P69 to TC-P75, TC-CR06, TC-CR19, TC-PF-02, TC-PF-03 |
| TR-02-04 | TC-BL-01, TC-BL-05, TC-BL-06 |
| TR-03-01 | TC-MR-09 |
| TR-03-02 | TC-MR-01, TC-MR-02, TC-MR-03, TC-MR-09 |
| TR-03-03 | TC-DI-08, TC-BIZ-11 |
| TR-03-04 | TC-DI-07, TC-BIZ-09 |
| TR-03-05 | TC-MR-05, TC-MR-06 |
| TR-03-06 | TC-P56, TC-FI-01 |
| TR-03-07 | TC-P57, TC-FI-02 |
| TR-03-08 | TC-N02, TC-DI-09, TC-MR-07 |
| TR-03-09 | TC-PF-01, TC-PF-03 |
| TR-03-10 | TC-CR02, TC-CR15, TC-DI-10 |
| TR-03-11 | TC-CR02 |
| TR-03-12 | TC-MR-02 |
| TR-03-13 | TC-MC-03, TC-EC-18 |
| TR-03-14 | TC-DI-03, TC-DC-01 to TC-DC-03 |
| TR-03-15 | TC-DI-04, TC-DC-04 |
| TR-03-16 | TC-P37, TC-MC-01, TC-SC-03 |
| TR-03-17 | TC-P38, TC-MC-02, TC-SC-02 |
| TR-03-18 | TC-DI-01, TC-DC-11 to TC-DC-13 |
| TR-03-19 | TC-DI-02, TC-DC-14 to TC-DC-16 |
| TR-03-20 | TC-DC-01 to TC-DC-03 |
| TR-03-21 | TC-DC-04 |
| TR-03-22 | TC-DI-05, TC-DC-05 to TC-DC-07, TC-CR03 |
| TR-03-23 | TC-DI-06, TC-DC-08 to TC-DC-10, TC-CR04 |
| TR-04-01 | TC-CR08 |
| TR-04-02 | TC-P07, TC-P08, TC-DC-11 to TC-DC-13 |
| TR-04-03 | TC-P09, TC-DC-14 to TC-DC-16 |
| TR-04-04 | TC-P10, TC-P15 |
| TR-04-05 | TC-P11, TC-P12, TC-P13, TC-DC-17 to TC-DC-23 |
| TR-05-01 | TC-P18, TC-BL-02 |
| TR-05-02 | TC-P18 |
| TR-05-03 | TC-P18 |
| TR-05-04 | TC-P23 |
| TR-05-05 | TC-P40 |
| TR-05-06 | TC-P41 |
| TR-05-07 | TC-P42 |
| TR-05-08 | TC-P29, TC-P48 |
| TR-06-01 | TC-P36 |
| TR-06-02 | TC-P48, TC-P49, TC-DC-17 to TC-DC-21 |
| TR-06-03 | TC-P40 |
| TR-06-04 | TC-P41 |
| TR-06-05 | TC-P42, TC-P43, TC-P44, TC-EC-13 to TC-EC-16 |
| TR-06-06 | TC-P45, TC-P46, TC-P47, TC-EC-05 to TC-EC-08 |
| TR-06-07 | TC-P50, TC-P51, TC-P52, TC-EC-09 to TC-EC-12 |
| TR-06-08 | TC-P49, TC-CR05, TC-EC-17 |
| TR-06-09 | TC-P72, TC-P73, TC-BL-07 |
| TR-07-01 | TC-N08, TC-N09, TC-SC-08 |
| TR-07-02 | TC-P70 |
| TR-07-03 | TC-P71 |
| TR-08-01 | TC-P63, TC-P64, TC-P65, TC-P66 |
| TR-08-02 | TC-TZ-08 |

---

## 9. Test Automation Strategy

### 9.1 Recommended Automation Approach

| Layer | Tool/Framework | Scope | Priority |
|-------|---------------|-------|----------|
| Unit/Feature | PHPUnit + Laravel Dusk or HTTP Tests | `getRouteStopAnalysis()` query logic, `paginateCollection()`, `parseDateRange()` | P1 |
| Integration | Laravel HTTP Tests with DB seeding | Full request-response cycle for charts and table sections | P1 |
| E2E | Laravel Dusk or Playwright | Full user flow: page load → filter → paginate → tab switch | P2 |
| Visual | Percy / Chromatic (or manual screenshot comparison) | Chart rendering, KPI box colors, progress bar widths | P3 |
| API | Pest + Http Tests | AJAX response structure and HTML content validation | P1 |
| Accessibility | axe-core (via Dusk or Playwright) | WCAG 2.1 AA compliance scan | P2 |

### 9.2 Suggested PHPUnit Test Structure



### 9.3 Suggested JavaScript Test Structure (Jest + Puppeteer/Playwright)



---

## 10. Known Limitations & Technical Debt

| # | Limitation | Impact | Suggested Fix |
|---|-----------|--------|---------------|
| L-01 | `getRouteStopAnalysis()` loads ALL data into memory before pagination | Memory issues with 10000+ stops | Use database-level pagination (skip + take) instead of `->get()` + `paginateCollection()` |
| L-02 | [Query/Code Removed] | Date filter does not affect delay metric | [Query/Code Removed] |
| L-03 | No text search field — users cannot search by stop name | Limited usability for long stop lists | Add search input to filter bar |
| L-04 | Chart.js CDN loaded once for all tabs but re-initialized per tab | Chart re-initialization on tab switch destroys previous charts | Implement proper Chart.js instance cleanup on tab destroy |
| L-05 | No loading indicator per individual section | Whole page dims (opacity 0.5) during AJAX; no per-section spinner | Show skeleton placeholders during load instead of opacity change |
| L-06 | No export functionality | Users cannot download report data | Add CSV/Excel export button |
| L-07 | No error boundaries for individual JS components | One chart failure can affect other chart rendering | Wrap each Chart.js init in try-catch |
| L-08 | `studentAllocations` not date-scoped | Allocations may include future or past academic sessions | Add session/academic year filter to allocations query |
| L-09 | No request caching or debouncing on filter submit | Rapid filter clicks cause multiple AJAX requests | Implement debounce (300ms) on filter form submit |
| L-10 | Chart toggle does not persist across page reloads | User preference lost on refresh | Store chart view preference in localStorage |

---

## 11. Defect Severity Classification

| Severity | Definition | Examples | TC Examples |
|----------|-----------|----------|-------------|
| **Critical** | Feature non-functional; incorrect KPI values; data corruption | KPI boxes show 0 when data exists; wrong boarding counts | TC-P07, TC-P08, TC-P09, TC-DI-01 to TC-DI-06 |
| **Major** | Chart/table not rendering; filter not working; pagination broken | Chart fails to render; route filter returns wrong data | TC-P18, TC-P56, TC-P57, TC-P69, TC-N01 |
| **Minor** | UI inconsistency; color coding wrong; performance issue | Wrong badge color; chart animation missing; slow load | TC-P24, TC-P30, TC-P45, TC-PF-01 |
| **Trivial** | Cosmetic; layout shift on responsive; tooltip formatting | Slight alignment issue; tooltip text format | TC-UI-13, TC-UI-14, TC-CH-07 |

---

## 12. Test Execution Checklist

| # | Pre-execution Check | Verification |
|---|---------------------|-------------|
| 1 | Test data DS-01 through DS-05 seeded in DB | ☐ |
| 2 | Test user has `tenant.stop-analysis.viewAny` and `tenant.transport.viewAny` | ☐ |
| 3 | CDN URLs accessible (chart.js, daterangepicker, moment.js, jQuery) | ☐ |
| 4 | Browser devtools network tab open for AJAX monitoring | ☐ |
| 5 | Console errors monitored during test execution | ☐ |
| 6 | Database query log enabled for performance checks | ☐ |
| 7 | Screen recording or screenshots captured for UI tests | ☐ |
| 8 | Test environment URL: `/transport-report?active_tab=stop-analysis` | ☐ |
| 9 | Session authenticated as test user | ☐ |
| 10 | Edge case data ED-01 through ED-10 seeded if needed | ☐ |

---

## 13. Test Environment

| Component | Version / Detail |
|-----------|-----------------|
| PHP | 8.x |
| Laravel | 10.x |
| Chart.js | latest CDN |
| jQuery | included with AdminLTE |
| Bootstrap | 5.x |
| daterangepicker | latest CDN |
| moment.js | 2.29.4 CDN |
| Database | MySQL 8.x / MariaDB |
| Browser | Chrome 120+ / Firefox 120+ |
| Screen Resolution | 1920x1080 (primary), 1366x768, 768x1024 (tablet) |

---

## 14. Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-07-22 | TC_Generator | Initial comprehensive test case list — expanded from 134 to ~1400 lines |
