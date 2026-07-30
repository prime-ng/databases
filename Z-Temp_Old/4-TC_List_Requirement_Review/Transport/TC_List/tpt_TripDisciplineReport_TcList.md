# tpt_TripDisciplineReport_TcList

## Module: Transport → Transport Report → Trip & Discipline

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | Transport |
| Tab Group | Transport Report |
| Feature | Trip & Discipline Report |
| URL(s) | `/transport-report?active_tab=trip-execution` (page load), AJAX: `GET /transport-report?active_tab=trip-execution&section=charts/table` |
| Controller | `Modules\Transport\Http\Controllers\TransportReportController` |
| Tab Builder Method | `buildTripExecutionSection()` (line 129) |
| Data Method | `getTripExecutionReport()` (line 680) |
| View | `transport::report.trip-execution-discipline.index` |
| Hub View | `transport::tab_module.transportreport.blade.php` |
| Permission | `tenant.trip-execution.viewAny` (line 32 of transportreport.blade.php) |
| Export | Not implemented |
| Pagination Strategy | Custom `paginateCollection()` with unique page name `page_trip` to avoid cross-tab pagination conflicts |
| AJAX Architecture | Two independent section loads (`charts` and `table`), each fetched via separate AJAX GET requests |
| Section Builder | `buildTripExecutionSection()` takes `$section` param — returns only charts HTML or only table HTML |
| Summary Object | `$tripSummary` with `total_trips`, `safe_trips`, `risk_trips`, `avg_completion`, `avg_delay` |
| Chart Libraries | Chart.js via CDN, initialized in `$(function(){...})` block inside the `charts` section blade |
| Date Range Picker | Moment.js + daterangepicker, default range = current month |
| Filter Form | Inline form with date range, route, vehicle, driver dropdowns; submit triggered on daterange change or button click |

---

## 2. Pre-conditions

### 2.1 Permission & Access

| # | Condition | Detail |
|---|-----------|--------|
| PRE-01 | Required permission | `tenant.trip-execution.viewAny` must be granted to the user role |
| PRE-02 | Tab definition | Tab `trip-execution` must exist in `x-backend.tab.nav-tab` tabs array in `transportreport.blade.php` line 13 |
| PRE-03 | Hub view `@can` | The `@can('tenant.trip-execution.viewAny')` directive on line 32 of `transportreport.blade.php` must allow the `@include` |
| PRE-04 | Permission string match | Must match exactly in `config/permissionslist.php`, controller `Gate::authorize()`, and blade `@can` directives |
| PRE-05 | Tab aria mapping | Tab target `#trip-execution-pane` must match the `id` attribute on the tab-pane div in the partial view |

### 2.2 Database Records

| # | Condition | Detail |
|---|-----------|--------|
| PRE-06 | TptTrip records | Must have `TptTrip` rows with `trip_date` falling within the selected date range |
| PRE-07 | TptRouteSchedulerJnt | Trips must have a valid `route_scheduler_id` referencing a row in `tpt_route_scheduler_jnt` |
| PRE-08 | Route records | `tpt_route_scheduler_jnt.route_id` must reference a valid `Route` record |
| PRE-09 | Vehicle records | `tpt_trip.vehicle_id` must reference a valid `Vehicle` record |
| PRE-10 | Driver records | `tpt_trip.driver_id` must reference a valid `DriverHelper` record where `role = 'Driver'` |
| PRE-11 | StudentBoardingLog | Boarding/unboarding counts rely on `tpt_student_boarding_log` rows linked to the trip via `boarding_trip_id` |
| PRE-12 | TptTripStopDetail | Delay calculation uses `tpt_trip_stop_detail.reaching_time` and `sch_arrival_time` — only the first related record via singular `tripStopDetail` relationship |
| PRE-13 | Student allocations | `planned_boardings` uses `studentAllocationsAll` relationship on the route — unique by `student_id` |

### 2.3 System State

| # | Condition | Detail |
|---|-----------|--------|
| PRE-14 | Filter data available | `getFilterData()` must return non-empty `routes`, `vehicles`, `drivers` collections for dropdown rendering |
| PRE-15 | Chart.js loaded | CDN script `https://cdn.jsdelivr.net/npm/chart.js` must be accessible |
| PRE-16 | Moment.js + daterangepicker loaded | CDN scripts for Moment.js and daterangepicker must load before initialization |
| PRE-17 | AJAX endpoint functional | `TransportReportController@index` must respond to `GET` with `active_tab` + `section` params returning JSON `{html: '...'}` |
| PRE-18 | jQuery available | AJAX calls use `$.ajax` — jQuery must be loaded in the layout |

---

## 3. Default Data Load

### 3.1 Architecture Overview

The tab uses a two-phase lazy-load AJAX pattern:

1. **Page load**: `loadTabSection('trip-execution', 'charts')` + `loadTabSection('trip-execution', 'table')` called on `$(document).ready()`
2. **Tab switch**: Same calls when `shown.bs.tab` fires, but only if tab pane `#trip-execution-pane` does NOT have class `loaded`
3. **Filter change**: `loadTabSection('trip-execution', 'charts', formData)` + `loadTabSection('trip-execution', 'table', formData)` on `submit` of `.transport-filter-form`
4. **Pagination click**: `loadTabSection('trip-execution', 'table', queryString)` on `.pagination a` click

Each section load hits the controller which calls `buildTripExecutionSection('charts', ...)` or `buildTripExecutionSection('table', ...)` respectively.

### 3.2 Section: charts — 4 Summary KPIs

| Data | Source Logic |
|------|-------------|
| Total Trips | `$tripExecutionReports->count()` |
| Safe Trips | [Query/Code Removed] |
| Risk Trips | [Query/Code Removed] |
| Safety Rate | `$tripSummary->total_trips > 0 ? round(($tripSummary->safe_trips / $tripSummary->total_trips) * 100, 1) : 0` |
| Avg Completion | `$tripExecutionReports->avg('completion_rate') ?? 0`, rounded to 1 decimal |
| Avg Delay | `$tripExecutionReports->avg('delay_minutes') ?? 0`, rounded to 1 decimal |

### 3.3 Section: charts — 3 Charts

| Chart ID | Type | Data Source | Visual Details |
|----------|------|-------------|----------------|
| `tripSafetyChart` | Doughnut | Safe Trips count vs Risk Trips count | Green (`#28a745`) for SAFE, Red (`#dc3545`) for RISK; tooltip shows count + percentage; cutout 60%; animateScale + animateRotate |
| `completionRateChart` | Bar | completion_rate per route name | Per-bar color: green >=90%, yellow >=70%, red <70%; Y axis 0–100 with `%` suffix; X axis route names rotated 45deg; border-radius 4px |
| `tripPerformanceChart` | Grouped/Stacked bar | Planned Boardings (gray), Actual Boardings (blue), Actual Unboardings (green) | Toggleable via `[data-chart-view]` buttons (grouped/stacked); interaction mode `index` with crosshair; tooltip shows per-dataset + completion % for Boardings dataset; Y axis "Number of Students"; X axis route names |

### 3.4 Section: table — 11 Columns

| Column | Blade Source | Formatting |
|--------|-------------|------------|
| Date | `trip_date_formatted` + `start_time` - `end_time` | Bold date, small muted time range below (`d M Y` + `H:i` - `H:i`) |
| Route | `route_name` | With `bi-signpost-2-fill` icon in primary color |
| Trip Type | `trip_type` | `bg-info` badge — values like "shift" or "pickup_drop" |
| Vehicle | `vehicle_no` | Bold text |
| Driver | `driver_name` | Plain text |
| Planned | `planned_boardings` | fw-semibold |
| Boarded | `actual_boardings` | fw-semibold text-primary |
| Unboarded | `actual_unboardings` | fw-semibold text-success |
| Completion | `completion_rate` | Progress bar (8px height) + percentage; color: `bg-success` >=90%, `bg-warning` >=70%, `bg-danger` <70%; capped to `min(100%)` |
| Delay | `delay_minutes` | Badge: `bg-success` <=5min, `bg-warning` <=15min, `bg-danger` >15min; rounded to 1 decimal + "min" suffix |
| Status | `trip_status` | Badge: `bg-success` + `bi-check-circle-fill` for SAFE, `bg-danger` + `bi-exclamation-triangle-fill` for RISK |

### 3.5 Helper Computations in Blade

| Variable | Logic |
|----------|-------|
| `$completionStatusClass` | `>=90 → bg-success`, `>=70 → bg-warning`, `<70 → bg-danger` |
| `$delayStatusClass` | `>15 → bg-danger`, `>5 → bg-warning`, `<=5 → bg-success` |
| `$statusClass` | `SAFE → bg-success`, `RISK → bg-danger` |
| `$statusIcon` | `SAFE → bi-check-circle-fill`, `RISK → bi-exclamation-triangle-fill` |
| `$balance` | `actual_boardings - actual_unboardings` |
| `$balanceText` | `>0 → "+N"`, `<0 → "-N"`, `=0 → "0"` |
| `$startTime` / `$endTime` | From `trip->start_time` / `trip->end_time`; default `'-'` |

### 3.6 Section: Default (Full Tab Pane)

Rendered when `request('section')` is neither `charts` nor `table` (i.e., on initial full page load — though in practice this code path is never hit for AJAX requests):

| Element | Description |
|---------|-------------|
| Filter bar | Date range picker (260px) + Route select (18%) + Vehicle select (18%) + Driver select (18%) + Filter button + Reset button |
| Charts container | `#trip-execution-charts` div with spinner placeholder |
| Table container | `#trip-execution-table` div with spinner placeholder |
| Hidden inputs | `active_tab = trip-execution`, `from_date`, `to_date` |

### 3.7 Data Flow Summary



### 3.8 Filters

| Filter | Input Type | Source | Default |
|--------|-----------|--------|---------|
| Date Range | Daterangepicker (text input + hidden from/to) | User selection or preset ranges | Current month start → end |
| Route | `<select>` populated from `$filters['routes']` | `Route::active()->get()` | All Routes (empty string) |
| Vehicle | `<select>` populated from `$filters['vehicles']` | `Vehicle::active()->get()` | All Vehicles (empty string) |
| Driver | `<select>` populated from `$filters['drivers']` | `DriverHelper::where('role', 'Driver')->active()->get()` | All Drivers (empty string) |

---

## 4. Test Data Strategy

### 4.1 Core Data Setup



### 4.2 Safety Status Scenarios



### 4.3 Completion Rate Scenarios



### 4.4 Delay Scenarios (via tpt_trip_stop_detail as singular relationship)



### 4.5 Student Allocation Scenarios per Route



### 4.6 Boarding Log Counts per Trip



### 4.7 Edge Case Records



---

## 5. Business Conditions

### 5.1 Query Logic (`getTripExecutionReport` — line 680)

| BC ID | Detail |
|-------|--------|
| BC-QL-01 | [Query/Code Removed] |
| BC-QL-02 | [Query/Code Removed] |
| BC-QL-03 | Vehicle filter: `where('vehicle_id', $filters['vehicle_id'])` |
| BC-QL-04 | Driver filter: `where('driver_id', $filters['driver_id'])` |
| BC-QL-05 | Safety status: `SAFE` if `boardings === unboardings`, else `RISK` |
| BC-QL-06 | Completion rate: `$actualBoardings / $plannedBoardings * 100` |
| BC-QL-07 | Delay: `reaching_time->diffInMinutes(sch_arrival_time)` from first `tripStopDetail` |
| BC-QL-08 | Planned boardings: `$route->studentAllocationsAll->unique('student_id')->count()` |
| BC-QL-09 | Actual boardings: `$trip->boardingLogs->whereNotNull('boarding_time')->count()` |
| BC-QL-10 | Actual unboardings: `$trip->boardingLogs->whereNotNull('unboarding_time')->count()` |
| BC-QL-11 | Route name fallback: `optional($route)->name ?? '—'` |
| BC-QL-12 | Vehicle number fallback: `optional($trip->vehicle)->vehicle_no ?? '—'` |
| BC-QL-13 | Driver name fallback: `optional($trip->driver)->name ?? '—'` |
| BC-QL-14 | Trip type fallback: `optional($trip->shift)->name ?? optional($route)->pickup_drop ?? '—'` |
| BC-QL-15 | Status class via `match(true)`: `RISK → danger`, `<70 → warning`, `<90 → info`, `else → success` |
| BC-QL-16 | Pagination: `paginateCollection($tripExecutionReports, 10, 'page_trip')` — manual slice on collection, not DB-level paginate |
| BC-QL-17 | Collection is fully loaded from DB THEN mapped → ALL trips in range fetched every time, regardless of page |

### 5.2 Database Schema — Referenced Tables

| Table | Key Columns | Relationships Used |
|-------|-------------|-------------------|
| tpt_trip | id, trip_date, route_scheduler_id, shift_id, route_id, vehicle_id, driver_id, status, start_time, end_time, created_at, updated_at | Main query table |
| tpt_route_scheduler_jnt | id, route_id, shift_id, is_active | `$trip->routeScheduler` → `$routeScheduler->route` |
| routes | id, name, code, shift_id, pickup_drop, is_active | Route name + studentAllocationsAll |
| vehicles | id, vehicle_no, vehicle_type, seating_capacity, is_active | Vehicle number display |
| driver_helper | id, name, role (Driver/Helper), employee_code, is_active | Driver name display |
| tpt_trip_stop_detail | id, trip_id, stop_id, sch_arrival_time, reaching_time, sch_departure_time, leaving_time, reached_flag | Delay calculation (singular `tripStopDetail`) |
| tpt_student_boarding_log | id, student_id, trip_date, boarding_trip_id, unboarding_trip_id, boarding_time, unboarding_time, boarding_route_id, unboarding_route_id | Boarding/unboarding counts |
| tpt_student_allocation_jnt | id, student_session_id, route_id, pickup_point_id, is_active | Planned boarding count via route->studentAllocationsAll |

### 5.3 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Trip with no route scheduler | `optional($trip->routeScheduler)->route` returns null → route_name = '—' |
| BC-BIZ-02 | Trip with no boarding logs | actual_boardings = 0, actual_unboardings = 0; completion_rate = 0; status = RISK |
| BC-BIZ-03 | Trip with equal boardings and unboardings | status = SAFE |
| BC-BIZ-04 | Planned boardings = 0 | completion_rate = 0 (division by zero guard) |
| BC-BIZ-05 | No trips in date range | Empty table: "No trip execution data found for selected filters" |
| BC-BIZ-06 | Delay only from first stop detail | Uses `$trip->tripStopDetail` (singular — first related record, not all) |
| BC-BIZ-07 | Trip with no stop detail | delay_minutes = 0 (default) |
| BC-BIZ-08 | Boardings > Unboardings (excess on bus) | status = RISK, balance shows "+N" |
| BC-BIZ-09 | Unboardings > Boardings (extra exits) | status = RISK, balance shows "-N" |
| BC-BIZ-10 | Zero trips and zero boardings | status = SAFE (0 === 0); completion_rate = 0 |
| BC-BIZ-11 | No filter selected | All trips in date range shown |
| BC-BIZ-12 | Filter returns zero results | Empty table with no-data message; charts render with empty datasets |
| BC-BIZ-13 | Single trip in range | Table shows 1 row; charts render with single datapoint |
| BC-BIZ-14 | Completion rate > 100% (more boardings than planned) | Clamped to `min(100%)` in progress bar width; rate shown as-is in text |
| BC-BIZ-15 | Delay is negative (early arrival) | diffInMinutes returns negative → badge shows negative minutes? |
| BC-BIZ-16 | Multiple filter combination | All filters AND-ed: trips must satisfy ALL selected filters |
| BC-BIZ-17 | Pagination with filters applied | Page navigation preserves all active filter parameters via `->appends(request()->query())->links()` |
| BC-BIZ-18 | Tab switch to trip-execution from another tab | AJAX loads charts + table sections only if not already loaded |

### 5.4 View Rendering Logic

The blade file `index.blade.php` uses a three-way `@if` / `@elseif` / `@else` conditional controlled by `request('section')`:

| Section Value | Rendered Content |
|---------------|------------------|
| `'charts'` | KPI cards (4 small-box) + Safety doughnut chart + Completion rate bar chart + Performance overview bar chart + inline Chart.js `<script>` block |
| `'table'` | 11-column `<table>` with progress bars, badges, status icons + pagination `->links()` |
| Any other / null | Full tab pane with filter bar + chart loading spinner div (`#trip-execution-charts`) + table loading spinner div (`#trip-execution-table`) |

### 5.5 Chart.js Initialization Flow



### 5.6 Hub JavaScript Initialization Flow (transportreport.blade.php)



### 5.7 `loadTabSection()` Function Details



### 5.8 JavaScript Variables Mapped From PHP

| JS Variable | PHP Source | Data Type | Example |
|-------------|-----------|-----------|---------|
| `tripData` | `@json($tripExecutionReports->toArray())` | Array of objects | `[{trip_date: "...", route_name: "...", ...}]` |
| `tripDates` | `$tripExecutionReports->pluck('trip_date_formatted')->toArray()` | String array | `["01 Jun 2026", "02 Jun 2026"]` |
| `routeNames` | `$tripExecutionReports->pluck('route_name')->toArray()` | String array | `["Alpha Route", "Beta Route"]` |
| `plannedData` | `$tripExecutionReports->pluck('planned_boardings')->toArray()` | Int array | `[5, 8, 4]` |
| `boardedData` | `$tripExecutionReports->pluck('actual_boardings')->toArray()` | Int array | `[5, 8, 4]` |
| `unboardedData` | `$tripExecutionReports->pluck('actual_unboardings')->toArray()` | Int array | `[5, 6, 7]` |
| `completionData` | `$tripExecutionReports->pluck('completion_rate')->toArray()` | Float array | `[100.0, 40.0, 80.0]` |
| `delayData` | `$tripExecutionReports->pluck('delay_minutes')->toArray()` | Float array | `[0.0, 2.0, 2.0]` |
| `tripStatusData` | `$tripExecutionReports->pluck('trip_status')->toArray()` | String array | `["SAFE", "RISK", "SAFE"]` |
| `safeTrips` | [Query/Code Removed] | Integer | `4` |
| `riskTrips` | [Query/Code Removed] | Integer | `6` |

### 5.4 AJAX Architecture

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-AJX-01 | `section=charts` on page load | Returns KPI cards + 3 charts + Chart.js `<script>` block |
| BC-AJX-02 | `section=table` on page load | Returns `<table>` with 11 columns + pagination links |
| BC-AJX-03 | AJAX request with missing/invalid `section` | Controller responds with empty error state (else block renders full tab pane) |
| BC-AJX-04 | AJAX error (network failure) | `.fail()` handler shows `<div class="alert alert-danger">Failed to load ...</div>` |
| BC-AJX-05 | Container opacity during load | `container.css('opacity', 0.5)` before AJAX, reset to `1` on success/error |
| BC-AJX-06 | Pagination link click | Only table section re-fetched; charts section remains unchanged |
| BC-AJX-07 | Filter change | Both charts AND table sections re-fetched simultaneously |
| BC-AJX-08 | AJAX request while previous in-flight | No abort/queue mechanism — concurrent requests may race |

---

## 6. Test Case List

### 6.1 Positive — Tab Load & Initial State

| TC ID | Description | Prerequisites | Test Steps | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|---------------|------------|-----------------|---------|---------|--------|
| TC-P01 | Tab renders on page load with spinner | trip-execution is default tab | 1. Navigate to `/transport-report`<br>2. Observe tab content | `#trip-execution-pane` is visible; charts and table containers show spinner | — | — | ⬜ |
| TC-P02 | AJAX loads charts section on initial load | Trips exist in current month | 1. Load page<br>2. Wait for AJAX to complete | Charts container has KPI cards + 3 chart canvases; no spinner | — | — | ⬜ |
| TC-P03 | AJAX loads table section on initial load | Trips exist in current month | 1. Load page<br>2. Wait for AJAX to complete | Table container has `<table>` with data rows; no spinner | — | — | ⬜ |
| TC-P04 | Summary KPI cards show correct aggregates | Mix of SAFE/RISK trips | 1. Load page<br>2. Observe 4 small-box cards | Total Trips (blue), Safe Trips (green), Risk Trips (red), Safety Rate % (info) shown with correct counts | — | — | ⬜ |
| TC-P05 | Total Trips card value matches count | 10 trips in range | 1. Load page<br>2. Read Total Trips value | Shows "10" in the h3 element inside `text-bg-primary` box | — | — | ⬜ |
| TC-P06 | Safe Trips card value matches count | 4 SAFE trips | 1. Load page<br>2. Read Safe Trips value | Shows "4" in the h3 element inside `text-bg-success` box | — | — | ⬜ |
| TC-P07 | Risk Trips card value matches count | 6 RISK trips | 1. Load page<br>2. Read Risk Trips value | Shows "6" in the h3 element inside `text-bg-danger` box | — | — | ⬜ |
| TC-P08 | Safety Rate percentage calculated correctly | 4 safe out of 10 total | 1. Load page<br>2. Read Safety Rate value | Shows "40%" (4/10 × 100) in the h3 element inside `text-bg-info` box | — | — | ⬜ |
| TC-P09 | Safety Rate shows 0% when no trips | Zero trips in range | 1. Load page with date range having no trips<br>2. Read Safety Rate | Shows "0%" — calculated from `0 / 0 * 100 = 0` via ternary guard | — | — | ⬜ |
| TC-P10 | Safety Rate shows 100% when all trips safe | All trips are SAFE | 1. Load page with data where all trips have boardings == unboardings<br>2. Read Safety Rate | Shows "100%" | — | — | ⬜ |

### 6.2 Positive — Table Columns & Data Display

| TC ID | Description | Prerequisites | Test Steps | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|---------------|------------|-----------------|---------|---------|--------|
| TC-P11 | Table renders all 11 header columns | At least 1 trip in range | 1. Load page<br>2. Observe table `<thead>` | Columns: Date, Route, Trip Type, Vehicle, Driver, Planned, Boarded, Unboarded, Completion, Delay, Status | — | — | ⬜ |
| TC-P12 | Date column shows formatted date + time range | Trip with start/end times | 1. Load page<br>2. Observe Date cell | Shows bold "01 Jun 2026" with muted "07:00 - 08:30" below | — | — | ⬜ |
| TC-P13 | Date column shows only date when times are null | Trip with null start/end | 1. Create trip with null start_time and end_time<br>2. Load page | Shows "01 Jun 2026" only; no time range rendered | — | — | ⬜ |
| TC-P14 | Route column shows route name with icon | Trip with valid route | 1. Load page<br>2. Observe Route cell | Shows `bi-signpost-2-fill` icon + "Alpha Route" | — | — | ⬜ |
| TC-P15 | Route column shows em-dash when no route | Trip with null route_scheduler_id | 1. Create trip with route_scheduler_id = null<br>2. Load page | Shows "—" | — | — | ⬜ |
| TC-P16 | Trip Type column shows badge | Trip with shift name | 1. Load page<br>2. Observe Trip Type cell | Shows `bg-info` badge with shift name (e.g. "Morning Shift") | — | — | ⬜ |
| TC-P17 | Trip Type falls back to pickup_drop | Trip type from route attribute | 1. Create trip where shift is null but route has pickup_drop<br>2. Load page | Shows route's `pickup_drop` value | — | — | ⬜ |
| TC-P18 | Trip Type shows em-dash for missing everything | Trip with null shift + null pickup_drop | 1. Create trip with null shift + route with null pickup_drop<br>2. Load page | Shows "—" | — | — | ⬜ |
| TC-P19 | Vehicle column shows vehicle number | Trip with valid vehicle | 1. Load page<br>2. Observe Vehicle cell | Shows bold "BUS-001" | — | — | ⬜ |
| TC-P20 | Vehicle column shows em-dash when no vehicle | Trip with null vehicle_id | 1. Create trip with vehicle_id = null<br>2. Load page | Shows "—" | — | — | ⬜ |
| TC-P21 | Driver column shows driver name | Trip with valid driver | 1. Load page<br>2. Observe Driver cell | Shows "Alice" | — | — | ⬜ |
| TC-P22 | Driver column shows em-dash when no driver | Trip with null driver_id | 1. Create trip with driver_id = null<br>2. Load page | Shows "—" | — | — | ⬜ |
| TC-P23 | Planned column shows unique student count | Route has 5 allocated students | 1. Load page<br>2. Observe Planned cell | Shows "5" (fw-semibold) for trips on route_alpha | — | — | ⬜ |
| TC-P24 | Boarded column shows actual boarding count | 4 boardings logged | 1. Load page<br>2. Observe Boarded cell | Shows "4" (text-primary fw-semibold) | — | — | ⬜ |
| TC-P25 | Unboarded column shows actual unboarding count | 7 unboardings logged | 1. Load page<br>2. Observe Unboarded cell | Shows "7" (text-success fw-semibold) | — | — | ⬜ |
| TC-P26 | Completion column shows progress bar + percentage | 80% completion rate | 1. Load page<br>2. Observe Completion cell | Progress bar at 80% width; text "80%" | — | — | ⬜ |
| TC-P27 | Completion progress bar color green for >=90% | 100% completion | 1. Load page (trip_01)<br>2. Observe Completion bar | Progress bar has class `bg-success` | — | — | ⬜ |
| TC-P28 | Completion progress bar color yellow for >=70% | 80% completion | 1. Load page (trip_03)<br>2. Observe Completion bar | Progress bar has class `bg-warning` | — | — | ⬜ |
| TC-P29 | Completion progress bar color red for <70% | 40% completion | 1. Load page (trip_02)<br>2. Observe Completion bar | Progress bar has class `bg-danger` | — | — | ⬜ |
| TC-P30 | Completion progress bar width clamped to min(100%) | Rate >100% scenario | 1. Create trip with boardings > planned<br>2. Load page | Bar width = `min(rate, 100)`%; text shows actual rate >100% | — | — | ⬜ |
| TC-P31 | Delay column shows badge with minutes | 15 min delay | 1. Load page (trip_04)<br>2. Observe Delay cell | Shows badge "15.0 min" | — | — | ⬜ |
| TC-P32 | Delay badge color green for <=5 min | 2 min delay | 1. Load page (trip_02)<br>2. Observe Delay badge | Badge class `bg-success` | — | — | ⬜ |
| TC-P33 | Delay badge color yellow for >5 and <=15 min | 15 min delay | 1. Load page (trip_04)<br>2. Observe Delay badge | Badge class `bg-warning` | — | — | ⬜ |
| TC-P34 | Delay badge color red for >15 min | 25 min delay | 1. Load page (trip_05)<br>2. Observe Delay badge | Badge class `bg-danger` | — | — | ⬜ |
| TC-P35 | Delay shows 0 min for missing stop detail | No tripStopDetail | 1. Load page (trip_11)<br>2. Observe Delay | Shows badge "0.0 min" with `bg-success` class | — | — | ⬜ |
| TC-P36 | Status badge shows SAFE with green + check icon | trip_status = SAFE | 1. Load page<br>2. Observe trip_01 row | Badge `bg-success` with `bi-check-circle-fill` icon + "SAFE" text | — | — | ⬜ |
| TC-P37 | Status badge shows RISK with red + exclamation icon | trip_status = RISK | 1. Load page<br>2. Observe trip_02 row | Badge `bg-danger` with `bi-exclamation-triangle-fill` icon + "RISK" text | — | — | ⬜ |
| TC-P38 | Balance text computed in blade but not rendered | Any trip | 1. Load page<br>2. Inspect HTML source | Variable `$balanceText` exists but is not displayed in the table (latent) | — | — | ⬜ |

### 6.3 Positive — Trip Safety Chart (Doughnut)

| TC ID | Description | Prerequisites | Test Steps | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|---------------|------------|-----------------|---------|---------|--------|
| TC-P39 | Trip Safety Chart is doughnut type | At least 1 trip | 1. Load page<br>2. Inspect chart config | Chart type = 'doughnut', cutout = '60%' | — | — | ⬜ |
| TC-P40 | Safety Chart shows SAFE / RISK labels | 4 safe, 6 risk | 1. Load page<br>2. Inspect chart data | Labels array: ['Safe Trips', 'Risk Trips']; data: [4, 6] | — | — | ⬜ |
| TC-P41 | Safety Chart color: green for SAFE, red for RISK | Any data | 1. Load page<br>2. Inspect dataset colors | backgroundColor[0] = rgba(40,167,69,0.8) (green), backgroundColor[1] = rgba(220,53,69,0.8) (red) | — | — | ⬜ |
| TC-P42 | Safety Chart hover offset increases segment | Any data | 1. Hover over chart segment<br>2. Observe animation | Segment grows outward via hoverOffset: 15 | — | — | ⬜ |
| TC-P43 | Safety Chart tooltip shows count + percentage | 4 safe, 6 risk | 1. Hover over SAFE segment<br>2. Read tooltip | Shows "Safe Trips: 4 (40%)" | — | — | ⬜ |
| TC-P44 | Safety Chart renders with zero trips (empty state) | No trips in range | 1. Load page with empty range<br>2. Inspect chart | Chart initializes with data = [0, 0]; tooltip displays "(0%)" | — | — | ⬜ |
| TC-P45 | Safety Chart uses pointStyle legend | Any data | 1. Load page<br>2. Observe legend | Legend items use circle pointStyle with 15px padding | — | — | ⬜ |
| TC-P46 | Safety Chart animation: animateScale + animateRotate | Any data | 1. Load page fresh<br>2. Observe chart entrance | Chart animates in with both scale and rotation | — | — | ⬜ |

### 6.4 Positive — Completion Rate Chart (Bar)

| TC ID | Description | Prerequisites | Test Steps | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|---------------|------------|-----------------|---------|---------|--------|
| TC-P47 | Completion chart is bar type | At least 1 trip | 1. Load page<br>2. Inspect chart config | Chart type = 'bar', labels = route names array | — | — | ⬜ |
| TC-P48 | Completion chart X axis shows route names | Multiple routes | 1. Load page with trips on multiple routes<br>2. Observe X axis labels | Shows "Alpha Route", "Beta Route", "Gamma Route" rotated 45deg | — | — | ⬜ |
| TC-P49 | Completion chart Y axis 0-100 with % suffix | Any data | 1. Load page<br>2. Inspect Y axis | beginAtZero: true, max: 100, ticks show "0%", "50%", "100%" | — | — | ⬜ |
| TC-P50 | Completion bar color: green >=90% | 100% completion | 1. Load page (trip_01)<br>2. Inspect bar color | backgroundColor = rgba(40,167,69,0.8) (green) | — | — | ⬜ |
| TC-P51 | Completion bar color: yellow >=70% | 80% completion | 1. Load page (trip_03)<br>2. Inspect bar color | backgroundColor = rgba(255,193,7,0.8) (yellow) | — | — | ⬜ |
| TC-P52 | Completion bar color: red <70% | 40% completion | 1. Load page (trip_02)<br>2. Inspect bar color | backgroundColor = rgba(220,53,69,0.8) (red) | — | — | ⬜ |
| TC-P53 | Completion chart tooltip shows route + rate + planned + actual | Any bar | 1. Hover over bar<br>2. Read tooltip | Shows Route: name, Completion: X%, Planned: Y, Actual: Z | — | — | ⬜ |
| TC-P54 | Completion chart has borderRadius | Any data | 1. Load page<br>2. Inspect bar border radius | borderRadius: 4 on dataset | — | — | ⬜ |
| TC-P55 | Completion chart hides legend | Any data | 1. Load page<br>2. Observe | legend.display = false | — | — | ⬜ |
| TC-P56 | Completion chart renders single bar for single trip | Only 1 trip | 1. Load page with data for 1 route only<br>2. Observe chart | Single bar rendered for that route | — | — | ⬜ |
| TC-P57 | Completion chart handles 0% bar correctly | 0% completion trip | 1. Load page (trip_07, trip_10, trip_11)<br>2. Observe bars with 0% | Bars rendered at 0 height, colored red | — | — | ⬜ |

### 6.5 Positive — Trip Performance Overview Chart (Grouped/Stacked Toggle)

| TC ID | Description | Prerequisites | Test Steps | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|---------------|------------|-----------------|---------|---------|--------|
| TC-P58 | Performance chart has 3 datasets | At least 1 trip | 1. Load page<br>2. Inspect chart data | Datasets: Planned Boardings (gray), Actual Boardings (blue), Actual Unboardings (green) | — | — | ⬜ |
| TC-P59 | Performance chart default view is grouped | Any data | 1. Load page<br>2. Observe | options.scales.x.stacked = false; "Grouped" button has `.active` class | — | — | ⬜ |
| TC-P60 | Click "Stacked" button toggles to stacked view | Any data | 1. Load page<br>2. Click "Stacked" button | Chart updates: bars stack; "Stacked" button has `.active`; "Grouped" loses `.active` | — | — | ⬜ |
| TC-P61 | Click "Grouped" button returns to grouped view | Currently stacked | 1. Switch to stacked<br>2. Click "Grouped" again | Chart returns to grouped mode; both axes stacked = false; categoryPercentage = 0.6 | — | — | ⬜ |
| TC-P62 | Performance chart tooltip shows dataset label + value | Any bar | 1. Hover over any bar<br>2. Read tooltip | Shows "Planned Boardings: 5 students" | — | — | ⬜ |
| TC-P63 | Performance chart tooltip shows extra info for Boardings dataset | Any bar | 1. Hover over Actual Boardings bar (index=1)<br>2. Read tooltip afterLabel | After label shows "Planned: 5" and "Completion: 80%" | — | — | ⬜ |
| TC-P64 | Performance chart X axis shows route names | Multiple routes | 1. Load page<br>2. Observe X axis | Route names displayed, rotated 45deg | — | — | ⬜ |
| TC-P65 | Performance chart Y axis shows "Number of Students" | Any data | 1. Load page<br>2. Inspect Y axis title | Title text = "Number of Students", bold font | — | — | ⬜ |
| TC-P66 | Performance chart interaction mode is 'index' | Multiple datasets | 1. Hover near bar border<br>2. Observe tooltip | Tooltip shows all datasets for that index (crosshair behavior via intersect:false, mode:'index') | — | — | ⬜ |
| TC-P67 | Performance chart legend uses pointStyle | Any data | 1. Load page<br>2. Observe legend | Legend items use circle pointStyle with 20px padding | — | — | ⬜ |
| TC-P68 | Performance chart handles empty data | No trips | 1. Load page with empty range<br>2. Inspect chart | Chart initializes with empty arrays; no JS errors | — | — | ⬜ |
| TC-P69 | Chart resize handler attached to window | Any data | 1. Load page<br>2. Inspect console | `window.addEventListener('resize', ...)` calls `safetyChart.resize()`, `completionChart.resize()`, `performanceChart.resize()` | — | — | ⬜ |

### 6.6 Positive — Filters

| TC ID | Description | Prerequisites | Test Steps | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|---------------|------------|-----------------|---------|---------|--------|
| TC-P70 | Filter bar renders with 4 filter controls | Tab loaded | 1. Load page<br>2. Observe filter bar | Date range input (260px) + Route select (18%) + Vehicle select (18%) + Driver select (18%) + Filter button + Reset button | — | — | ⬜ |
| TC-P71 | Route select shows "All Routes" + route options | Routes exist | 1. Load page<br>2. Open Route dropdown | Options: "All Routes" (value="") + "Alpha Route" + "Beta Route" + "Gamma Route" | — | — | ⬜ |
| TC-P72 | Vehicle select shows "All Vehicles" + vehicle options | Vehicles exist | 1. Load page<br>2. Open Vehicle dropdown | Options: "All Vehicles" (value="") + "BUS-001" + "BUS-002" | — | — | ⬜ |
| TC-P73 | Driver select shows "All Drivers" + driver options | Drivers exist | 1. Load page<br>2. Open Driver dropdown | Options: "All Drivers" (value="") + "Alice" + "Bob" | — | — | ⬜ |
| TC-P74 | Filter by single route | 2 routes with data | 1. Select "Alpha Route"<br>2. Click Filter button | Only trips on Alpha Route shown; KPI/charts reflect filtered data | — | — | ⬜ |
| TC-P75 | Filter by single vehicle | 2 vehicles with data | 1. Select "BUS-001"<br>2. Click Filter button | Only trips with BUS-001 shown | — | — | ⬜ |
| TC-P76 | Filter by single driver | 2 drivers with data | 1. Select "Alice"<br>2. Click Filter button | Only trips assigned to Alice shown | — | — | ⬜ |
| TC-P77 | Filter by date range | Trips on Jun 1 and Jun 2 | 1. Set date range = Jun 1 - Jun 2<br>2. Click Filter button | Only Jun 1 and Jun 2 trips shown; Jun 3+ excluded | — | — | ⬜ |
| TC-P78 | Combined filter: route + vehicle + driver | Specific combination | 1. Select Alpha Route + BUS-001 + Alice<br>2. Click Filter button | Only trips satisfying ALL three filters shown (trip_01, trip_05) | — | — | ⬜ |
| TC-P79 | Combined filter with date range | All filters active | 1. Select Alpha + BUS-001 + Alice + Jun 1-2<br>2. Filter | Only trip_01 (Jun 1) and trip_05 (Jun 2) shown; trip_09 (Jun 3, same route/vehicle/driver) excluded | — | — | ⬜ |
| TC-P80 | Filter reset button returns to unfiltered state | Filter active | 1. Apply any filter<br>2. Click Reset (redo) button | All selects reset to "All" empty values; date range resets to current month; page reloads without filter params | — | — | ⬜ |
| TC-P81 | Filter form submits via AJAX (no page reload) | Any filter | 1. Select a filter<br>2. Click Filter button<br>3. Observe URL | URL does not change; charts div and table div content updates via AJAX | — | — | ⬜ |
| TC-P82 | Date range presets work | Today's date has trips | 1. Open date picker<br>2. Select "Today" preset<br>3. Observe | Date range set to today; form auto-submits; charts/table reloaded | — | — | ⬜ |
| TC-P83 | Date range "Last 7 Days" preset | 7 days with some trips | 1. Open date picker<br>2. Select "Last 7 Days" | Range = last 7 days; trips within those 7 days shown | — | — | ⬜ |
| TC-P84 | Date range "This Month" preset | Default state | 1. Load page fresh<br>2. Observe date picker | Shows current month (1st to last day) | — | — | ⬜ |
| TC-P85 | Date range "Last Month" preset | Last month has trips | 1. Open date picker<br>2. Select "Last Month" | Last month selected; trips from last month shown | — | — | ⬜ |

### 6.7 Positive — Pagination

| TC ID | Description | Prerequisites | Test Steps | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|---------------|------------|-----------------|---------|---------|--------|
| TC-P86 | Pagination appears when >10 trips exist | 12 trips in range | 1. Load page with 12 trips<br>2. Observe bottom of table | Pagination links shown at center below table | — | — | ⬜ |
| TC-P87 | First page shows first 10 records | 12 trips total | 1. Load page<br>2. Count table rows | 10 rows visible (excluding paginator meta) | — | — | ⬜ |
| TC-P88 | Click page 2 shows remaining 2 records | 12 trips total | 1. Click page 2 link<br>2. Observe rows | 2 rows visible; from page=2 of `page_trip` paginator | — | — | ⬜ |
| TC-P89 | Pagination preserves filter parameters | Filter + page 2 | 1. Select "Alpha Route" filter<br>2. Click page 2 | Alpha-only trips page 2 shown; filter applied | — | — | ⬜ |
| TC-P90 | Pagination page name is `page_trip` (unique per tab) | Any pagination | 1. Click page 2<br>2. Observe URL parameter | Query string contains `page_trip=2` (not generic `page`) | — | — | ⬜ |
| TC-P91 | Pagination does not affect other tab paginators | Another tab has data | 1. Switch to another tab<br>2. Paginate to page 2<br>3. Switch back to trip-execution | `page_trip` value is independent from other paginators | — | — | ⬜ |
| TC-P92 | Pagination links use `appends(request()->query())` | Filter + page | 1. Apply filter<br>2. Observe pagination links | All current query params preserved in pagination URLs | — | — | ⬜ |
| TC-P93 | Pagination hides when <=10 trips | 5 trips in range | 1. Load page with 5 trips<br>2. Observe bottom | No pagination links rendered (`$records->hasPages()` would be false — but note: blade does NOT check `hasPages()`, it always renders paginator) | — | — | ⬜ |
| TC-P94 | Pagination AJAX click reloads only table section | Charts + table loaded | 1. Click page 2<br>2. Observe page | Charts section unchanged; table section re-fetched with new page | — | — | ⬜ |

### 6.8 Positive — AJAX Architecture

| TC ID | Description | Prerequisites | Test Steps | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|---------------|------------|-----------------|---------|---------|--------|
| TC-P95 | `loadTabSection` called twice on page load | Any data | 1. Load page<br>2. Monitor network tab | Two XHR requests: one for `section=charts`, one for `section=table` | — | — | ⬜ |
| TC-P96 | Charts section request returns JSON with html | Trips exist | 1. Load page<br>2. Inspect charts XHR response | Response JSON: `{"html": "<div class=\"row mt-3\">...<script>...</script>"}` | — | — | ⬜ |
| TC-P97 | Table section request returns JSON with html | Trips exist | 1. Load page<br>2. Inspect table XHR response | Response JSON: `{"html": "<table class=\"table table-sm\">...<div class=\"d-flex justify-content-center...\">"}` | — | — | ⬜ |
| TC-P98 | Tab switch from another tab triggers load | trip-execution not yet loaded | 1. Switch to trip-execution from another tab<br>2. Monitor network | Two XHR requests fire; trip-execution-pane gets class `loaded` | — | — | ⬜ |
| TC-P99 | Tab switch does NOT reload if already loaded | trip-execution has class `loaded` | 1. Load trip-execution tab<br>2. Switch to another tab<br>3. Switch back | No XHR requests; content restored from cached state | — | — | ⬜ |
| TC-P100 | Filter change fires two simultaneous AJAX calls | Form submitted | 1. Apply filter<br>2. Monitor network | Two simultaneous requests: charts + table | — | — | ⬜ |
| TC-P101 | Container opacity shows loading state | Slow network (throttled) | 1. Apply filter<br>2. Observe container during load | Container opacity = 0.5 during request; restored to 1 on success | — | — | ⬜ |
| TC-P102 | AJAX error shows alert message | Network interrupted | 1. Disconnect network<br>2. Apply filter or switch tab | Alert `<div class="alert alert-danger">Failed to load charts/table.</div>` appears | — | — | ⬜ |

### 6.9 Negative — Empty States & Edge Cases

| TC ID | Description | Prerequisites | Test Steps | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|---------------|------------|-----------------|---------|---------|--------|
| TC-N01 | No trips in date range | Date range with zero trips | 1. Set date range to distant past (e.g. 2020-01-01 to 2020-01-31)<br>2. Click Filter | Empty table: `<td colspan="11">` shows "No trip execution data found for selected filters" with `bi-inbox` empty icon | — | — | ⬜ |
| TC-N02 | No trips in date range — charts section | Same as above | 1. Set empty date range<br>2. Observe charts | Charts render with zero data; KPI cards show 0/0/0/0%; no JS errors | — | — | ⬜ |
| TC-N03 | Trip with no stop detail | Trip_11 (no tripStopDetail record) | 1. Load page<br>2. Observe Delay for trip_11 | Delay = 0.0 min (bg-success badge) | — | — | ⬜ |
| TC-N04 | Trip with stop detail but null reaching_time | Created in edge cases | 1. Create tripStopDetail with reaching_time = null<br>2. Load page | delay_minutes = 0 (ternary guard prevents calculation) | — | — | ⬜ |
| TC-N05 | Trip with stop detail but null sch_arrival_time | Created in edge cases | 1. Create tripStopDetail with sch_arrival_time = null<br>2. Load page | delay_minutes = 0 (ternary guard) | — | — | ⬜ |
| TC-N06 | Trip with 0 planned boardings (no allocations) | trip_10 on route_beta (0 allocations) | 1. Load page<br>2. Observe trip_10 row | Planned = 0, Boarded = 1, Completion = 0% (division by zero guard), Status = RISK | — | — | ⬜ |
| TC-N07 | Trip with 0 planned boardings AND 0 boardings | trip_07 (0 allocations, 0 logs) | 1. Load page<br>2. Observe trip_07 | Planned = 0, Boarded = 0, Completion = 0%, Status = SAFE (0 === 0) | — | — | ⬜ |
| TC-N08 | Trip with no boarding logs (null boarding_time) | trip_11 (logs exist but all boarding_time=null) | 1. Load page<br>2. Observe trip_11 | Boarded = 0, Unboarded = 0, Completion = 0%, Status = RISK | — | — | ⬜ |
| TC-N09 | Trip with null route_scheduler_id | Orphan trip | 1. Create TptTrip with route_scheduler_id = null<br>2. Load page | route_name = '—'; trip_type = '—' | — | — | ⬜ |
| TC-N10 | Trip with null vehicle_id | Orphan trip | 1. Create TptTrip with vehicle_id = null<br>2. Load page | vehicle_no = '—' | — | — | ⬜ |
| TC-N11 | Trip with null driver_id | Orphan trip | 1. Create TptTrip with driver_id = null<br>2. Load page | driver_name = '—' | — | — | ⬜ |
| TC-N12 | Trip with both start_time and end_time null | Incomplete trip | 1. Load page<br>2. Observe Date column | Shows date only; no time range `<small>` rendered | — | — | ⬜ |
| TC-N13 | Trip where status class logic produces unexpected match | RISK but completion >90% | 1. Create trip where boardings != unboardings (RISK) but completion_rate = 95<br>2. Load page | `match(true)` first matches `$safetyStatus === 'RISK'` → status_class = 'danger' | — | — | ⬜ |
| TC-N14 | Only 1 trip in range — charts and table still render | Single trip | 1. Date range with exactly 1 trip<br>2. Load page | Table shows 1 row; charts render with single datapoint; no errors | — | — | ⬜ |
| TC-N15 | Very long route name in chart X axis | Route name with 50+ chars | 1. Create route with name "Very Long Route Name That Exceeds Normal Width"<br>2. Load page | X axis label rotates and may truncate via Chart.js auto-sizing | — | — | ⬜ |
| TC-N16 | Zero trips route appears in filter dropdown | Route with no trips in range | 1. Select a route that has zero trips in current date range<br>2. Click Filter | Empty table state shown; charts render with zero data | — | — | ⬜ |

### 6.10 Negative — Permission & Security

| TC ID | Description | Prerequisites | Test Steps | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|---------------|------------|-----------------|---------|---------|--------|
| TC-N17 | 403 without `tenant.trip-execution.viewAny` permission | User role lacks permission | 1. Log in as user without this permission<br>2. Navigate to `/transport-report?active_tab=trip-execution` | Tab button hidden; `@can` prevents `@include`; tab pane does not render | — | — | ⬜ |
| TC-N18 | Direct AJAX access without permission | Same as above | 1. Remove permission<br>2. Send `GET /transport-report?active_tab=trip-execution&section=charts` | `Gate::authorize('tenant.transport.viewAny')` at controller `index()` blocks with 403 | — | — | ⬜ |
| TC-N19 | Guest (unauthenticated) access | Not logged in | 1. Clear session<br>2. Navigate to `/transport-report` | Redirected to login page | — | — | ⬜ |
| TC-N20 | CSRF not required (GET request) | Any state | 1. Send forged GET to transport-report URL | GET requests are not CSRF-protected; data is returned (read-only, acceptable) | — | — | ⬜ |
| TC-N21 | Permission string mismatch test | Wrong permission string | 1. Temporarily change `@can` to `tenant.trip-execution.view` (no "Any")<br>2. Load page | Tab button hidden; include not rendered | — | — | ⬜ |
| TC-N22 | Tab not visible in nav-tab when permission missing | User lacks all tab permissions | 1. Remove all transport report permissions<br>2. Load page | Nav-tab hides the trip-execution tab button via `permission` key | — | — | ⬜ |
| TC-N23 | SQL injection attempt in filter params | Any | 1. Set route_id to `1 OR 1=1`<br>2. Submit filter | Eloquent `whereHas` uses parameterized query; no injection; `(int)` casting may fail but `when()` skips non-numeric | — | — | ⬜ |
| TC-N24 | XSS via filter param | Any | 1. Set driver_id to `<script>alert('xss')</script>`<br>2. Submit filter | Parameter passed in query string; rendered in HTML only inside `selected` attribute which is quoted; no XSS vector | — | — | ⬜ |

### 6.11 Code Review

| TC ID | Priority | Description | Code Location | Expected Result | Status |
|-------|----------|-------------|---------------|-----------------|--------|
| TC-CR01 | P1 | Safety status logic correct | `getTripExecutionReport()` line 699 | `SAFE` iff boardings == unboardings; `RISK` otherwise | ◌ |
| TC-CR02 | P1 | Delay uses singular tripStopDetail | `getTripExecutionReport()` line 701 | `$trip->tripStopDetail` (singular Eloquent relationship) — only first stop detail used, not all | ◌ |
| TC-CR03 | P1 | Division by zero guard | `getTripExecutionReport()` line 698 | `$plannedBoardings ? round(($actualBoardings / $plannedBoardings) * 100, 1) : 0` — safe ternary | ◌ |
| TC-CR04 | P1 | Null-safe route name | `getTripExecutionReport()` line 715 | `optional($route)->name ?? '—'` — falls back to em-dash | ◌ |
| TC-CR05 | P1 | Completion rate status class thresholds | `getTripExecutionReport()` lines 705-710 | `match(true)`: RISK → danger, <70 → warning, <90 → info, else → success | ◌ |
| TC-CR06 | P1 | Pagination uses unique `page_trip` | `buildTripExecutionSection()` line 140 | `paginateCollection($tripExecutionReports, 10, 'page_trip')` — unique name prevents cross-tab pagination conflicts | ◌ |
| TC-CR07 | P1 | Activity log NOT present in controller | `getTripExecutionReport()` is read-only query method | No activity logging needed for data retrieval (only for mutations) | ◌ |
| TC-CR08 | P1 | Blade `@can` uses `viewAny` not `view` | `transportreport.blade.php` line 32 | `@can('tenant.trip-execution.viewAny')` — correct for tab listing visibility | ◌ |
| TC-CR09 | P2 | All trips fetched before pagination | `getTripExecutionReport()` returns Collection (not paginated query) | Memory concern: all matching trips loaded into memory; pagination happens on Collection, not DB | ◌ |
| TC-CR10 | P2 | `studentAllocationsAll` eager loading not explicit | `getTripExecutionReport()` — no `with()` on base query | N+1 risk: `$route->studentAllocationsAll` loaded via lazy eager loading per trip (implicit) | ◌ |
| TC-CR11 | P2 | `boardingLogs` eager loading not explicit | `getTripExecutionReport()` — no `with('boardingLogs')` | N+1 risk: `$trip->boardingLogs` loaded lazily per trip | ◌ |
| TC-CR12 | P2 | `tripStopDetail` eager loading not explicit | `getTripExecutionReport()` — no `with('tripStopDetail')` | N+1 risk: `$trip->tripStopDetail` loaded lazily per trip | ◌ |
| TC-CR13 | P2 | `vehicle` and `driver` relationships lazy-loaded | `getTripExecutionReport()` — no `with('vehicle', 'driver')` | N+1 risk: each trip triggers additional queries for vehicle and driver | ◌ |
| TC-CR14 | P2 | `shift` relationship lazy-loaded | `getTripExecutionReport()` line 716 | `optional($trip->shift)->name` triggers lazy load per trip | ◌ |
| TC-CR15 | P2 | `routeScheduler.route` chain lazy-loaded | `getTripExecutionReport()` line 690 | `optional($trip->routeScheduler)->route` — 2-level deep lazy load per trip | ◌ |
| TC-CR16 | P2 | No `->orderBy()` on base query | `getTripExecutionReport()` line 682 | Trips returned in arbitrary DB order; no explicit ordering before `->get()` | ◌ |
| TC-CR17 | P2 | [Query/Code Removed] | [Query/Code Removed] | [Query/Code Removed] | ◌ |
| TC-CR18 | P2 | Safety Rate computed in blade, not controller | `index.blade.php` lines 10-12 | Computed as `$tripSummary->safe_trips / $tripSummary->total_trips * 100` with zero guard | ◌ |
| TC-CR19 | P2 | Charts HTML and table HTML in same view file | `index.blade.php` uses `@if(request('section') === 'charts')` / `@elseif(request('section') === 'table')` / `@else` | Single view file serves 3 different response types via conditional sections | ◌ |
| TC-CR20 | P2 | Unused `$balanceText` variable in blade | `index.blade.php` line 444 | `$balance` and `$balanceText` computed but never rendered in table; latent display logic | ◌ |
| TC-CR21 | P2 | Progress bar width capped to `min(100%)` | `index.blade.php` line 474 | `style="width: {{ min($completionRate, 100) }}%"` — prevents overflow for >100% cases | ◌ |
| TC-CR22 | P2 | Delay badge class uses bg- prefix directly | `index.blade.php` line 431-437 | Classes `bg-success`, `bg-warning`, `bg-danger` hardcoded; uses Bootstrap 5 utility classes | ◌ |
| TC-CR23 | P3 | `trip_12` outside default month — not shown on first load | Test data outside current month | Trip exists but not shown until date range expanded — confirms date filter works | ◌ |
| TC-CR24 | P3 | Non-unique `id` attributes across tab partials | `index.blade.php` — chart canvases use generic IDs | `tripSafetyChart`, `completionRateChart`, `tripPerformanceChart` IDs may conflict if multiple tabs loaded in same DOM | ◌ |
| TC-CR25 | P3 | KPI cards use `<h3>` for values | `index.blade.php` lines 26, 42, 57, 72 | Semantic heading level may cause accessibility issues if other h3 elements exist on page | ◌ |
| TC-CR26 | P3 | No loading skeleton — only spinner | `index.blade.php` lines 558-571 | Spinner-only loading state; no skeleton placeholder for content dimensions | ◌ |

### 6.12 Integration — Cross-Tab Behavior

| TC ID | Description | Prerequisites | Test Steps | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|---------------|------------|-----------------|---------|---------|--------|
| TC-I01 | Switch to trip-execution from route-performance | Both tabs valid | 1. Load route-performance<br>2. Click "Trip & Discipline" tab | `shown.bs.tab` fires; `loadTabSection` called; charts + table loaded | — | — | ⬜ |
| TC-I02 | Switch away and back to trip-execution (cached) | trip-execution already loaded | 1. Load trip-execution<br>2. Switch to another tab<br>3. Switch back | No new XHR; content already in DOM with class `loaded` | — | — | ⬜ |
| TC-I03 | Filter in trip-execution does not affect other tabs | Another tab has its own filter | 1. Filter trip-execution by route<br>2. Switch to another tab | Other tab's content unchanged (separate state not shared) | — | — | ⬜ |
| TC-I04 | Pagination page names don't conflict across tabs | Multiple tabs paginated | 1. Go to page 2 in trip-execution (`page_trip=2`)<br>2. Go to page 3 in driver-performance (`page_driver=3`)<br>3. Switch between tabs | Each tab's pagination page preserved correctly | — | — | ⬜ |
| TC-I05 | `management-dashboard` tab uses same trip data | Dashboard uses `getTripExecutionReport()` | 1. Load management-dashboard tab<br>2. Observe tripSummary | Dashboard shows same Total/Safe/Risk trip counts as trip-execution tab (same data method) | — | — | ⬜ |
| TC-I06 | Filter form reset clears all shared query params | Other tabs may share params | 1. Apply filters<br>2. Click Reset button | URL cleared of all filter params; page reloads | — | — | ⬜ |
| TC-I07 | Daterangepicker value shared across tabs | One date input per report | 1. Set date range in trip-execution<br>2. Switch to another tab<br>3. Observe date input | Daterangepicker input shows the same value; form hidden inputs maintained | — | — | ⬜ |

### 6.13 Performance

| TC ID | Description | Prerequisites | Test Steps | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|---------------|------------|-----------------|---------|---------|--------|
| TC-PF01 | Load time with 100 trips in 30-day range | 100 TptTrip records | 1. Seed 100 trips across 30 days<br>2. Load page<br>3. Measure time | Charts load <2s; table load <2s (note: N+1 queries cause slowdown) | — | — | ⬜ |
| TC-PF02 | Load time with 1000 trips | 1000 records | 1. Seed 1000 trips<br>2. Load page | May be slow due to N+1 issues; Collection loaded entirely in memory (not paginated at DB level) | — | — | ⬜ |
| TC-PF03 | Memory usage with large dataset | 5000 trips | 1. Seed 5000 trips<br>2. Load page<br>3. Monitor PHP memory | All 5000 TptTrip models + all relations loaded into Collection; potential memory exhaustion | — | — | ⬜ |
| TC-PF04 | Network payload size | 10 trips per page | 1. Load page<br>2. Inspect charts XHR response size | charts HTML ~5-8KB (including inline Chart.js code); table HTML ~3-5KB | — | — | ⬜ |
| TC-PF05 | Concurrent AJAX requests on filter submit | Two simultaneous XHR | 1. Apply filter<br>2. Monitor network | Both requests fire simultaneously; no request queuing | — | — | ⬜ |
| TC-PF06 | Rapid filter changes (debounce absent) | User spams filter button | 1. Rapidly click Filter button 10 times<br>2. Monitor network | 20 requests fire (2 per click); no debounce/throttle mechanism | — | — | ⬜ |
| TC-PF07 | Chart.js render performance with 50+ routes | 50 distinct route names | 1. Create 50 routes with trips<br>2. Load page<br>3. Observe browser | Bar/Performance charts have 50+ labels; rendering may lag; X axis labels may overlap | — | — | ⬜ |
| TC-PF08 | CDN fallback when Chart.js unavailable | Network blocked for CDN | 1. Block `cdn.jsdelivr.net`<br>2. Load page | Chart.js script fails; `Chart` is undefined → JS errors; charts section broken | — | — | ⬜ |

### 6.14 Data Integrity

| TC ID | Description | Prerequisites | Test Steps | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|---------------|------------|-----------------|---------|---------|--------|
| TC-DI01 | Trip with boardings > planned (over-capacity) | 6 boardings, 5 planned | 1. Create such trip<br>2. Load page | Completion rate = 120%; progress bar width = 100% (capped); text shows "120%" | — | — | ⬜ |
| TC-DI02 | Unboardings > boardings (impossible state) | 2 boardings, 5 unboardings | 1. Create such trip<br>2. Load page | Status = RISK (2 !== 5); balance = -3; the system accepts the data as-is | — | — | ⬜ |
| TC-DI03 | Same student boarded and unboarded multiple times | Duplicate logs for same student | 1. Create 2 boarding logs for same student on same trip<br>2. Load page | `count()` counts both → double-counts student; planned uses `unique()` but actual does NOT | — | — | ⬜ |
| TC-DI04 | Student boarded but allocation removed mid-month | Alloc deleted after trip | 1. Create trip with boardings for a student whose allocation was soft-deleted<br>2. Load page | Boarded still counts (join on boarding_log, not allocation); planned count unaffected | — | — | ⬜ |
| TC-DI05 | Trip date outside academic session | Trip exists but no session boundary | 1. Load page with trip in summer break<br>2. Observe | Trip appears in report (no session filter in query); appears as normal row | — | — | ⬜ |
| TC-DI06 | Multiple trip stop details for same trip (only first used) | 3 tripStopDetail rows | 1. Create 3 stop detail records for one trip<br>2. Load page | Delay calculated from first relationship only (`$trip->tripStopDetail` singular, not `tripStopDetails`) | — | — | ⬜ |

### 6.15 UI / UX

| TC ID | Description | Prerequisites | Test Steps | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|---------------|------------|-----------------|---------|---------|--------|
| TC-UI01 | Responsive: 4 KPI cards on large screen | Any data | 1. Set viewport to 1200px+<br>2. Observe | 4 cards in one row (col-lg-3) | — | — | ⬜ |
| TC-UI02 | Responsive: 2 KPI cards per row on tablet | Any data | 1. Set viewport to 768px<br>2. Observe | 2 cards per row (col-6) | — | — | ⬜ |
| TC-UI03 | Responsive: charts stack vertically on small screens | Any data | 1. Set viewport to 576px<br>2. Observe | Trip Safety and Completion Rate charts stack (each col-lg-6 → full width) | — | — | ⬜ |
| TC-UI04 | Responsive: table horizontally scrollable | Many columns | 1. Set viewport to 576px<br>2. Observe table | Table not in `table-responsive` wrapper → horizontal overflow may occur | — | — | ⬜ |
| TC-UI05 | Chart.js canvas responsive | Any data | 1. Resize browser window<br>2. Observe charts | Charts resize via `responsive: true, maintainAspectRatio: false` + resize event handler | — | — | ⬜ |
| TC-UI06 | Hover color change on safety doughnut | Any data | 1. Hover over chart segment<br>2. Observe | Segment "pops out" via `hoverOffset: 15` | — | — | ⬜ |
| TC-UI07 | Completion chart bar hover brightness | Any bar | 1. Hover over a bar<br>2. Observe | `hoverBackgroundColor` with 0.9 opacity (slightly brighter) | — | — | ⬜ |
| TC-UI08 | KPI cards have "More info" footer link | Any data | 1. Click "More info" on Total Trips card | Navigates to `route('transport.trip-management.index')` | — | — | ⬜ |
| TC-UI09 | Empty state icon renders in table | No data | 1. Filter with no results<br>2. Observe empty cell | `bi-inbox` icon shown above "No trip execution data found" text | — | — | ⬜ |
| TC-UI10 | Filter form elements aligned horizontally | Any | 1. Load page<br>2. Observe filter bar | Filter elements in flex-wrap row; date picker 260px; selects 18% each; buttons at end | — | — | ⬜ |
| TC-UI11 | Tab pane has rounded shadow container | Any | 1. Load page<br>2. Inspect #trip-execution-pane | Classes: `tab-pane fade p-3 bg-white rounded shadow-sm` | — | — | ⬜ |
| TC-UI12 | Chart card headers styled consistently | Any | 1. Inspect chart card headers | `bg-light`, `py-3`, `fw-semibold`, icon + title | — | — | ⬜ |
| TC-UI13 | Performance overview toggle buttons bootstrap group | Any | 1. Observe toggle buttons | `btn-group btn-group-sm` with `btn-outline-primary`; active has `.active` class | — | — | ⬜ |

### 6.16 Chart.js Script Integrity

| TC ID | Description | Prerequisites | Test Steps | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|---------------|------------|-----------------|---------|---------|--------|
| TC-CJ01 | Chart data populated from PHP via @json | Trips exist | 1. Load page<br>2. Inspect generated JS | `const tripDates = @json($tripDates)` produces correct JS array literal | — | — | ⬜ |
| TC-CJ02 | Doughnut chart data: safeTrips + riskTrips | 4 safe, 6 risk | 1. Load page<br>2. Inspect chart dataset | `data: [4, 6]` | — | — | ⬜ |
| TC-CJ03 | Safe count 0 → chart renders correctly | All trips are RISK | 1. Create all trips as RISK<br>2. Load safety chart | Doughnut shows 0% green, 100% red; data: [0, N] | — | — | ⬜ |
| TC-CJ04 | Risk count 0 → chart renders correctly | All trips are SAFE | 1. Create all trips as SAFE<br>2. Load safety chart | Doughnut shows 100% green, 0% red; data: [N, 0] | — | — | ⬜ |
| TC-CJ05 | Bar chart color mapping uses per-bar logic | Mixed rates | 1. Load page with mixed rates<br>2. Inspect backgroundColor array | Array matches per-bar conditional: >=90 → green, >=70 → yellow, else red | — | — | ⬜ |
| TC-CJ06 | Toggle between grouped/stacked updates chart correctly | Any data | 1. Click "Stacked"<br>2. Inspect chart options after update | `performanceChart.options.scales.x.stacked = true`; `performanceChart.options.scales.y.stacked = true` | — | — | ⬜ |
| TC-CJ07 | Chart update called after toggle | Any data | 1. Click toggle<br>2. Check if `update()` called | `performanceChart.update()` invoked after setting options | — | — | ⬜ |
| TC-CJ08 | Multiple canvases on same page do not conflict | Switch tabs | 1. Load trip-execution<br>2. Switch to another tab that also has Chart.js canvases<br>3. Switch back | Canvases unique IDs prevent collision; `document.getElementById('tripSafetyChart')` returns correct element | — | — | ⬜ |
| TC-CJ09 | Chart.js CDN loaded after jQuery | Page initialization | 1. Load page<br>2. Check script load order | Chart.js script loaded before inline chart init code; `$(function(){...})` ensures DOM ready | — | — | ⬜ |

### 6.17 Routing & URL

| TC ID | Description | Prerequisites | Test Steps | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|---------------|------------|-----------------|---------|---------|--------|
| TC-RT01 | `active_tab=trip-execution` sets correct tab active | URL param | 1. Navigate to `/transport-report?active_tab=trip-execution` | Trip & Discipline tab is active on page load | — | — | ⬜ |
| TC-RT02 | `tab=trip-execution` also works (fallback) | URL param | 1. Navigate to `/transport-report?tab=trip-execution` | `$request->get('active_tab') ?: $request->get('tab', 'route-performance')` → trip-execution active | — | — | ⬜ |
| TC-RT03 | Invalid active_tab defaults to route-performance | URL param | 1. Navigate to `/transport-report?active_tab=nonexistent-tab` | Defaults to 'route-performance' (first tab in nav-tab) | — | — | ⬜ |
| TC-RT04 | AJAX URL does not include full path | AJAX request | 1. Inspect AJAX request via network tab | URL = `window.location.pathname` (same page, not a separate endpoint) | — | — | ⬜ |
| TC-RT05 | `section` param in AJAX correctly routes to builder | AJAX request | 1. Inspect XHR with section=charts | Controller `match 'trip-execution'` → `buildTripExecutionSection('charts', ...)` | — | — | ⬜ |
| TC-RT06 | Reset button URL uses `url()->current()` | Filter active | 1. Apply filters<br>2. Click Reset | Navigates to current URL without query params; page reloads | — | — | ⬜ |

### 6.18 Model Relationships (Data Source Verification)

| TC ID | Description | Expected Relationship | Code Path | Status |
|-------|-------------|----------------------|-----------|--------|
| TC-MR01 | TptTrip → routeScheduler | `$trip->routeScheduler()` returns `BelongsTo` to `TptRouteSchedulerJnt` | `getTripExecutionReport()` line 690 | ◌ |
| TC-MR02 | TptRouteSchedulerJnt → route | `$routeScheduler->route()` returns `BelongsTo` to `Route` | `getTripExecutionReport()` line 690: `$trip->routeScheduler->route` | ◌ |
| TC-MR03 | TptTrip → vehicle | `$trip->vehicle()` returns `BelongsTo` to `Vehicle` | `getTripExecutionReport()` line 717: `$trip->vehicle` | ◌ |
| TC-MR04 | TptTrip → driver | `$trip->driver()` returns `BelongsTo` to `DriverHelper` | `getTripExecutionReport()` line 718: `$trip->driver` | ◌ |
| TC-MR05 | TptTrip → shift | `$trip->shift()` returns `BelongsTo` to `Shift` | `getTripExecutionReport()` line 716: `$trip->shift` | ◌ |
| TC-MR06 | TptTrip → boardingLogs | `$trip->boardingLogs()` returns `HasMany` to `StudentBoardingLog` | `getTripExecutionReport()` lines 695-696 | ◌ |
| TC-MR07 | TptTrip → tripStopDetail (singular) | `$trip->tripStopDetail()` returns `HasOne` to `TptTripStopDetail` | `getTripExecutionReport()` line 701 | ◌ |
| TC-MR08 | Route → studentAllocationsAll | `$route->studentAllocationsAll()` — likely `HasMany` to `TptStudentAllocationJnt` | `getTripExecutionReport()` line 691 | ◌ |
| TC-MR09 | Route → pickup_drop | `$route->pickup_drop` attribute — string column on `routes` table | `getTripExecutionReport()` line 716 (fallback) | ◌ |

### 6.19 Edge Cases — Special Dates & Boundaries

| TC ID | Description | Prerequisites | Test Steps | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|---------------|------------|-----------------|---------|---------|--------|
| TC-EC01 | Trip on first day of month (boundary) | trip_date = month start | 1. Set date range = current month<br>2. Load page | Trip on 1st of month included | — | — | ⬜ |
| TC-EC02 | Trip on last day of month (boundary) | trip_date = month end | 1. Set date range = current month<br>2. Load page | Trip on last day of month included | — | — | ⬜ |
| TC-EC03 | Trip at 00:00 start_time (midnight) | start_time = 00:00 | 1. Create trip with midnight start<br>2. Load page | Time displays "00:00" correctly | — | — | ⬜ |
| TC-EC04 | Trip at 23:59 end_time | end_time = 23:59 | 1. Create trip with 23:59 end<br>2. Load page | Time displays "23:59" correctly | — | — | ⬜ |
| TC-EC05 | Date range spanning 12 months | Cross-year range | 1. Set range = Jan 2025 - Dec 2025<br>2. Load page | All trips in 2025 shown; no overflow errors | — | — | ⬜ |
| TC-EC06 | Date range with from_date > to_date | Reversed dates | 1. Set from_date = Jun 30, to_date = Jun 1<br>2. Load page | Daterangepicker prevents selection with from > to; if forced via hidden inputs, `whereBetween` returns empty set | — | — | ⬜ |
| TC-EC07 | Date range far future (no data) | 2030-01-01 to 2030-12-31 | 1. Load page with future range<br>2. Observe | Empty table state; charts render with zero data | — | — | ⬜ |
| TC-EC08 | Date range far past (no data) | 2000-01-01 to 2000-12-31 | 1. Set range to year 2000<br>2. Load page | Empty table state; no data expected | — | — | ⬜ |

### 6.20 Edge Cases — Driver & Vehicle Specific

| TC ID | Description | Prerequisites | Test Steps | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|---------------|------------|-----------------|---------|---------|--------|
| TC-EC09 | Driver name with special characters | Driver name = "Alice O'Brien" | 1. Create driver with apostrophe<br>2. Load page | Name displays correctly as "Alice O'Brien" in table and filter dropdown | — | — | ⬜ |
| TC-EC10 | Driver name very long | Name = 100 characters | 1. Create driver with long name<br>2. Load page | Name wraps or overflows in table cell; filter select may truncate | — | — | ⬜ |
| TC-EC11 | Vehicle number with alphanumeric mix | vehicle_no = "BUS 001-A" | 1. Create vehicle with complex number<br>2. Load page | Displays as "BUS 001-A" in table and filter | — | — | ⬜ |
| TC-EC12 | No drivers in dropdown (all inactive) | No active DriverHelper records | 1. Deactivate all drivers<br>2. Load page | Driver dropdown shows "All Drivers" only; trips with null driver show '—' | — | — | ⬜ |
| TC-EC13 | Deactivated vehicle still shows in table | Vehicle soft-deleted | 1. Soft-delete a vehicle assigned to a trip<br>2. Load page | `optional($trip->vehicle)->vehicle_no` still returns vehicle_no (eloquent loads soft-deleted by default if not `->active()` scoped) | — | — | ⬜ |

### 6.21 Edge Cases — Route & Stop Specific

| TC ID | Description | Prerequisites | Test Steps | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|---------------|------------|-----------------|---------|---------|--------|
| TC-EC14 | Route name with HTML entities | Route name = "Alpha & Beta" | 1. Create route with ampersand<br>2. Load page | Displays as "Alpha & Beta" (escaped by Blade) | — | — | ⬜ |
| TC-EC15 | Deactivated route | Route is_active = 0 | 1. Deactivate a route that has trips<br>2. Load page | Route appears in filter dropdown? `getFilterData` uses `Route::active()` → NOT in dropdown. But trip still shows route name in table row | — | — | ⬜ |
| TC-EC16 | Route with no student allocations | route with 0 allocations | 1. Load page<br>2. Observe trip with route that has 0 allocations | Planned = 0, completion = 0% or N/A | — | — | ⬜ |
| TC-EC17 | Route scheduler is_active = 0 | Deactivated scheduler | 1. Deactivate a route scheduler<br>2. Load page | `$trip->routeScheduler` still loads (no `active()` scope applied in query) | — | — | ⬜ |
| TC-EC18 | All routes inactive → filter dropdown empty | No active routes | 1. Deactivate all routes<br>2. Load page | [Query/Code Removed] | — | — | ⬜ |

### 6.22 Edge Cases — Boarding Log Specific

| TC ID | Description | Prerequisites | Test Steps | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|---------------|------------|-----------------|---------|---------|--------|
| TC-EC19 | Boarding log with boarding_time but null unboarding_time | Partial log | 1. Create log with boarding_time set, unboarding_time = null<br>2. Load page | `whereNotNull('unboarding_time')->count()` = 0 for that trip; status likely RISK | — | — | ⬜ |
| TC-EC20 | Boarding log with unboarding_time but null boarding_time | Partial log (unboarded without boarding) | 1. Create log with null boarding, set unboarding<br>2. Load page | `whereNotNull('boarding_time')->count()` = 0; unusual scenario — status = RISK | — | — | ⬜ |
| TC-EC21 | 500+ boarding logs for one trip | Mass boarding scenario | 1. Create one trip with 500 boarding logs<br>2. Load page | Table row shows 500 boarded / 500 unboarded; performance may be impacted | — | — | ⬜ |
| TC-EC22 | Boarding logs with same boarding_trip_id across multiple trips | Data integrity issue | 1. Create logs with same boarding_trip_id but different trip_date<br>2. Load page | `$trip->boardingLogs` only returns logs for this specific trip (proper FK constraint) | — | — | ⬜ |
| TC-EC23 | Zero boarding logs but trip exists (trip_07 case) | Trip with no logs at all | 1. Load page<br>2. Observe trip_07 | Boarded = 0, Unboarded = 0, Planned = 0, Completion = 0%, Status = SAFE | — | — | ⬜ |
| TC-EC24 | Boarding log count differs from allocation count | 3 boardings planned, 5 actual | 1. Create scenario where boardings exceed planned<br>2. Load page | Completion = 166.7%; progress bar capped to 100%; status based on boardings == unboardings | — | — | ⬜ |

### 6.23 Edge Cases — Trip Delay

| TC ID | Description | Prerequisites | Test Steps | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|---------------|------------|-----------------|---------|---------|--------|
| TC-EC25 | Negative delay (early arrival) | reaching_time < sch_arrival_time | 1. Create stop detail with 2 min early arrival<br>2. Load page | `diffInMinutes` returns -2; badge shows "-2.0 min" with `bg-success` class? | — | — | ⬜ |
| TC-EC26 | Delay = 5.0 min boundary (green) | Exactly 5 min delay | 1. Create stop detail with exactly 5 min delay<br>2. Load page | Badge `bg-success` (condition `>5` is false) | — | — | ⬜ |
| TC-EC27 | Delay = 5.1 min boundary (yellow) | 5.1 min delay | 1. Create stop detail with 5.1 min delay<br>2. Load page | Badge `bg-warning` (condition `>5` is true, `>15` is false) | — | — | ⬜ |
| TC-EC28 | Delay = 15.0 min boundary (yellow) | Exactly 15 min delay | 1. Create stop detail with 15 min delay<br>2. Load page | Badge `bg-warning` (condition `>15` is false) | — | — | ⬜ |
| TC-EC29 | Delay = 15.1 min boundary (red) | 15.1 min delay | 1. Create stop detail with 15.1 min delay<br>2. Load page | Badge `bg-danger` (condition `>15` is true) | — | — | ⬜ |
| TC-EC30 | Delay = 0 min (on-time) | reaching == sch | 1. Create stop detail with 0 delay<br>2. Load page | Badge "0.0 min" with `bg-success` | — | — | ⬜ |
| TC-EC31 | Very large delay (999 min) | reaching 999 min late | 1. Create stop detail with huge delay<br>2. Load page | Badge "999.0 min" with `bg-danger`; no overflow | — | — | ⬜ |

### 6.24 Blade Rendering Edge Cases

| TC ID | Description | Prerequisites | Test Steps | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|---------------|------------|-----------------|---------|---------|--------|
| TC-BL01 | `$tripSummary` defaults when null (charts section) | `$tripSummary` not passed | 1. Simulate view with missing `$tripSummary`<br>2. Observe | Null coalescing: `$tripSummary = $tripSummary ?? (object)[...defaults...]` at line 3 | — | — | ⬜ |
| TC-BL02 | `$tripExecutionReports` defaults when null | Reports collection missing | 1. Simulate missing variable<br>2. Observe | `$tripExecutionReports = $tripExecutionReports ?? collect()` at line 13 | — | — | ⬜ |
| TC-BL03 | Blade `@php` block handles empty collection gracefully | Empty data | 1. Load page with empty data<br>2. Observe | `$tripExecutionReports->pluck('trip_date_formatted')` returns empty array; `->toArray()` = `[]` | — | — | ⬜ |
| TC-BL04 | `@forelse` renders empty row when no records | Empty table | 1. Load page with empty data<br>2. Observe table body | `<tr><td colspan="11">` with icon and "No trip execution data found" | — | — | ⬜ |
| TC-BL05 | `optinal()` helper handles null relationships | Null relations | 1. Load page with all null FK trips<br>2. Observe | All optional() calls return null → em-dashes throughout; no errors | — | — | ⬜ |
| TC-BL06 | Filter select `@selected` directive works | Filter applied | 1. Select "Alpha Route" + apply<br>2. Reload with filter | `@selected(request('route_id')==$route->id)` → Alpha Route selected in dropdown | — | — | ⬜ |

### 6.25 Paginator Collection Edge Cases

| TC ID | Description | Prerequisites | Test Steps | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|---------------|------------|-----------------|---------|---------|--------|
| TC-PG01 | `page_trip` = 0 (invalid) | Manual URL manipulation | 1. Navigate to `?page_trip=0`<br>2. Observe table | `Paginator::resolveCurrentPage('page_trip')` returns 0; `slice((-1)*10, 10)` returns empty collection; table shows empty state | — | — | ⬜ |
| TC-PG02 | `page_trip` = -1 (invalid negative) | Manual URL | 1. Navigate to `?page_trip=-1`<br>2. Observe | Similar to page 0; empty table | — | — | ⬜ |
| TC-PG03 | `page_trip` = 999 (beyond last page) | 12 trips | 1. Navigate to `?page_trip=999`<br>2. Observe | `slice` returns empty collection; table shows empty state; paginator still shows links | — | — | ⬜ |
| TC-PG04 | `page_trip` = abc (non-numeric) | Manual URL | 1. Navigate to `?page_trip=abc`<br>2. Observe | `resolveCurrentPage` casts to int → 1; first page shown | — | — | ⬜ |
| TC-PG05 | Pagination with 0 total items | No trips | 1. Load page with no data<br>2. Observe pagination | `LengthAwarePaginator` with 0 items; `->links()` still renders? | — | — | ⬜ |
| TC-PG06 | Pagination with exactly 10 items (no pagination needed) | 10 trips | 1. Load page with 10 trips<br>2. Observe | Paginator rendered (10 items, 1 page) → link to page 1 shown | — | — | ⬜ |
| TC-PG07 | Pagination with 11 items (2 pages, page 1 = 10, page 2 = 1) | 11 trips | 1. Load page<br>2. Click page 2 | Page 2 shows 1 row | — | — | ⬜ |

### 6.26 Permission & Policy Verification

| TC ID | Priority | Description | Expected String | Location | Status |
|-------|----------|-------------|-----------------|----------|--------|
| TC-PM01 | P1 | Controller `Gate::authorize` in `index()` | `tenant.transport.viewAny` | `TransportReportController@index` line 36 | ◌ |
| TC-PM02 | P1 | Blade `@can` for tab include | `tenant.trip-execution.viewAny` | `transportreport.blade.php` line 32 | ◌ |
| TC-PM03 | P1 | Nav-tab `permission` key | `tenant.trip-execution.viewAny` | `transportreport.blade.php` line 13 | ◌ |
| TC-PM04 | P1 | Permission group in permissionslist.php | `trip-execution` | `config/permissionslist.php` | ◌ |
| TC-PM05 | P2 | Policy class exists for trip-execution | `TptTripPolicy` or `TripExecutionPolicy` | Check `app/Policies/` or `Modules/Transport/Policies/` | ◌ |
| TC-PM06 | P2 | Dots vs hyphens consistency check | Uses hyphens: `tenant.trip-execution.viewAny` | Consistent across controller, blade, and nav-tab | ◌ |

### 6.27 Database Migration Verification

| TC ID | Description | Table | Key Columns to Verify | Status |
|-------|-------------|-------|----------------------|--------|
| TC-DB01 | tpt_trip has all required columns | tpt_trip | id, trip_date, route_scheduler_id, shift_id, route_id, vehicle_id, driver_id, status, start_time, end_time | ◌ |
| TC-DB02 | tpt_trip relationships defined in model | tpt_trip Model | `routeScheduler()`, `vehicle()`, `driver()`, `shift()`, `boardingLogs()`, `tripStopDetail()` | ◌ |
| TC-DB03 | tpt_route_scheduler_jnt has route_id FK | tpt_route_scheduler_jnt | id, route_id, shift_id, is_active | ◌ |
| TC-DB04 | tpt_trip_stop_detail has trip_id FK | tpt_trip_stop_detail | id, trip_id, sch_arrival_time, reaching_time, sch_departure_time, leaving_time, reached_flag | ◌ |
| TC-DB05 | tpt_student_boarding_log has boarding_trip_id FK | tpt_student_boarding_log | id, student_id, trip_date, boarding_trip_id, unboarding_trip_id, boarding_time, unboarding_time | ◌ |
| TC-DB06 | routes table has `pickup_drop` column | routes | id, name, code, shift_id, pickup_drop, is_active | ◌ |

### 6.28 Accessibility

| TC ID | Description | Expected Behavior | Status |
|-------|-------------|-------------------|--------|
| TC-A11Y01 | Chart canvases have accessible labels | Chart.js renders to canvas (not accessible by default); no aria-labels on canvas elements | ◌ |
| TC-A11Y02 | Table has proper `<thead>` | Proper `<thead>` with `<th>` elements per column | ◌ |
| TC-A11Y03 | Status icons have no aria-hidden | `bi-check-circle-fill` and `bi-exclamation-triangle-fill` icons may lack `aria-hidden="true"` or screen reader text | ◌ |
| TC-A11Y04 | Filter form `<label>` elements | Check if form selects have associated `<label>` tags | ◌ |
| TC-A11Y05 | Pagination links accessible | Paginator `->links()` generates Bootstrap-compatible pagination with proper `aria` attributes | ◌ |
| TC-A11Y06 | Color not sole indicator for status | SAFE/RISK uses color + icon + text; Completion uses color + percentage text; Delay uses color + text | ◌ |
| TC-A11Y07 | Tab pane uses `role="tabpanel"` | `#trip-execution-pane` has `role="tabpanel"` and `aria-labelledby` | ◌ |
| TC-A11Y08 | KPI small-box semantic structure | Uses `<h3>` for values and `<p>` for labels — hierarchical heading structure | ◌ |

### 6.29 Data Consistency Check

| TC ID | Description | Check | Expected | Status |
|-------|-------------|-------|----------|--------|
| TC-DC01 | Sum(SAFE) + Sum(RISK) = Total Trips | KPIs | safe_trips + risk_trips == total_trips | ◌ |
| TC-DC02 | Safety Rate = (Safe / Total) * 100 | KPIs | Correct percentage calculation | ◌ |
| TC-DC03 | Completion Rate column matches bar chart | Cross-reference | Table per-trip completion_rate values match bar chart heights | ◌ |
| TC-DC04 | Total trips count matches table row count | Cross-reference | total_trips KPI == paginator total + across pages | ◌ |
| TC-DC05 | Sum of Planned column matches planned chart data | Cross-reference | Planned dataset values match table Planned column values | ◌ |
| TC-DC06 | Delay values consistently calculated | Cross-reference | Same delay value in table cell, avg_delay KPI, and (if shown) chart | ◌ |

### 6.30 Security — Data Leakage

| TC ID | Description | Prerequisites | Test Steps | Expected Result | Status |
|-------|-------------|---------------|------------|-----------------|--------|
| TC-SEC01 | Trip data from other tenants not leaked | Multi-tenant setup | 1. Log in as tenant A<br>2. Load trip-execution | Only tenant A's trips shown (model uses tenant scoping via `Gate::authorize` at controller level) | ◌ |
| TC-SEC02 | No sensitive data in HTML source | PII in comments | 1. Inspect HTML page source | No student PII, passwords, or tokens in the rendered HTML | ◌ |
| TC-SEC03 | AJAX response contains only HTML, no raw data | Any filter | 1. Inspect XHR response JSON | Response has `{"html": "..."}` only; no raw JSON data dump of trips | ◌ |
| TC-SEC04 | Filter dropdowns not enumerable for IDs | Route dropdown | 1. Inspect select options | Route names displayed, not internal IDs | ◌ |

---

## 7. Test Environment Setup

### 7.1 Required Seed Data



### 7.2 Testing Tools

| Tool | Purpose |
|------|---------|
| Laravel Dusk / PHPUnit | Automated browser testing for AJAX interactions |
| Laravel Telescope / Debugbar | Monitor N+1 queries, memory usage, SQL queries |
| Chrome DevTools Network tab | Monitor XHR requests, response sizes, timing |
| Chrome DevTools Console | Check for JS errors (Chart.js, AJAX failures) |
| Postman / cURL | Direct API testing for AJAX endpoints |

### 7.3 Test User Roles

| Role | Permissions |
|------|------------|
| Super Admin | All permissions, including `tenant.trip-execution.viewAny` |
| Transport Manager | `tenant.trip-execution.viewAny` only |
| School Admin | No transport report permissions |
| Guest | Not authenticated |

---

## 8. Defect Classification Guide

| Severity | Definition | Example |
|----------|------------|---------|
| P1 — Critical | Feature broken; data incorrect; security issue | Safety status reversed; wrong permission check; SQL injection |
| P2 — Major | Functional but with incorrect display or performance issue | N+1 query; chart colors wrong; pagination conflicting with other tabs |
| P3 — Minor | Cosmetic or non-functional | Icon not showing; alignment off; unused variable in blade |
| P4 — Enhancement | Suggestion for improvement | Add debounce to filter; add skeleton loading; add export |

---

### 6.31 KPI Card Visual Verification

| TC ID | Description | Prerequisites | Test Steps | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|---------------|------------|-----------------|---------|---------|--------|
| TC-KPI01 | Total Trips card uses `text-bg-primary` | Any data | 1. Load page<br>2. Inspect Total Trips card classes | Small-box has class `text-bg-primary` (blue background) | — | — | ⬜ |
| TC-KPI02 | Safe Trips card uses `text-bg-success` | Any SAFE trips | 1. Load page<br>2. Inspect Safe Trips card | Small-box has class `text-bg-success` (green background) | — | — | ⬜ |
| TC-KPI03 | Risk Trips card uses `text-bg-danger` | Any RISK trips | 1. Load page<br>2. Inspect Risk Trips card | Small-box has class `text-bg-danger` (red background) | — | — | ⬜ |
| TC-KPI04 | Safety Rate card uses `text-bg-info` | Any data | 1. Load page<br>2. Inspect Safety Rate card | Small-box has class `text-bg-info` (teal background) | — | — | ⬜ |
| TC-KPI05 | KPI cards render SVG icons | Any data | 1. Inspect each KPI card<br>2. Check for `<svg>` element | Each card has a unique SVG icon in `small-box-icon` class | — | — | ⬜ |
| TC-KPI06 | KPI "More info" footer link points to trip management | Any data | 1. Click "More info" link on any KPI card<br>2. Check href | `href="{{ route('transport.trip-management.index') }}"` — navigates to trip management module | — | — | ⬜ |
| TC-KPI07 | KPI cards render in single row on xl screens | 1920px viewport | 1. Load page at 1920px width<br>2. Observe KPI row | 4 cards in one row (`col-lg-3 col-6` each = 25% width) | — | — | ⬜ |
| TC-KPI08 | KPI cards wrap to 2 per row on small screens | 768px viewport | 1. Resize to 768px<br>2. Observe KPI row | Cards wrap to 2 per row (`col-6` = 50% width each) | — | — | ⬜ |

### 6.32 Chart Card Container Verification

| TC ID | Description | Prerequisites | Test Steps | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|---------------|------------|-----------------|---------|---------|--------|
| TC-CC01 | Trip Safety card uses `border-0 shadow-sm h-100` | Any data | 1. Inspect Safety chart card | Card has classes `border-0 shadow-sm h-100` | — | — | ⬜ |
| TC-CC02 | Completion Rate card uses same styling | Any data | 1. Inspect Completion chart card | Same `border-0 shadow-sm h-100` classes | — | — | ⬜ |
| TC-CC03 | Performance Overview card full width below | Any data | 1. Inspect Performance card | Card `mt-4 border-0 shadow-sm` with full width; no `h-100` | — | — | ⬜ |
| TC-CC04 | Chart container has fixed height | Any data | 1. Inspect chart container div | `style="position: relative; height: 300px;"` for safety/completion; `height: 350px` for performance | — | — | ⬜ |
| TC-CC05 | Card headers contain icons + titles | Any data | 1. Inspect each chart card header | Icons: `bi-shield-check` (safety), `bi-percent` (completion), `bi-bar-chart-fill` (performance) | — | — | ⬜ |

### 6.33 Filter Form Specific Behavior

| TC ID | Description | Prerequisites | Test Steps | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|---------------|------------|-----------------|---------|---------|--------|
| TC-FF01 | Date picker opens on click | Any | 1. Click date range input<br>2. Observe | Daterangepicker dropdown appears with preset ranges | — | — | ⬜ |
| TC-FF02 | Date picker auto-applies on selection | Any | 1. Select a date range<br>2. Observe | `autoApply: true` closes picker immediately after selection | — | — | ⬜ |
| TC-FF03 | Date picker opens to the left | Any | 1. Click date input<br>2. Observe position | `opens: 'left'` — dropdown opens left-aligned with input | — | — | ⬜ |
| TC-FF04 | Filter button has search icon | Any | 1. Inspect filter button | Button contains `fas fa-filter` icon | — | — | ⬜ |
| TC-FF05 | Reset button has redo icon | Any | 1. Inspect reset button | Button contains `fas fa-redo` icon | — | — | ⬜ |
| TC-FF06 | Filter select dropdowns show active records only | Inactive records exist | 1. Deactivate one route<br>2. Load page | Deactivated route NOT shown in route filter dropdown | — | — | ⬜ |
| TC-FF07 | Filter form method is GET | Any | 1. Inspect form tag | `method="GET"` — aligns with AJAX query string construction | — | — | ⬜ |
| TC-FF08 | Hidden from/to date inputs updated on picker change | Any | 1. Select new date range<br>2. Inspect hidden inputs | `from_date` and `to_date` hidden inputs updated with new values | — | — | ⬜ |

### 6.34 AJAX Loader & Transition States

| TC ID | Description | Prerequisites | Test Steps | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|---------------|------------|-----------------|---------|---------|--------|
| TC-AJ01 | Spinner visible in charts container before AJAX completes | Slow network | 1. Throttle network to Slow 3G<br>2. Load page | `#trip-execution-charts` shows spinner `spinner-border text-primary` | — | — | ⬜ |
| TC-AJ02 | Spinner visible in table container before AJAX completes | Slow network | 1. Same as above<br>2. Observe table container | `#trip-execution-table` shows spinner | — | — | ⬜ |
| TC-AJ03 | Spinner replaced by content on AJAX success | Normal network | 1. Load page<br>2. Wait for AJAX | Spinner elements replaced by KPI/charts HTML and table HTML | — | — | ⬜ |
| TC-AJ04 | Loading state uses opacity, not spinner, on subsequent loads | Filter change | 1. Load page<br>2. Apply filter | Container opacity set to 0.5 during AJAX; spinner NOT shown again | — | — | ⬜ |
| TC-AJ05 | Opacity restored on AJAX complete | Any | 1. Apply filter<br>2. Wait for response | Container opacity returns to 1 | — | — | ⬜ |
| TC-AJ06 | AJAX done callback uses `res.html` | Any | 1. Listen to AJAX success<br>2. Inspect response handling | `container.html(res.html)` — response JSON property is `html` | — | — | ⬜ |
| TC-AJ07 | AJAX type is GET not POST | Any | 1. Monitor network for XHR<br>2. Check request method | All requests use HTTP GET | — | — | ⬜ |

### 6.35 Tab Switch Behavior

| TC ID | Description | Prerequisites | Test Steps | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|---------------|------------|-----------------|---------|---------|--------|
| TC-TS01 | Tab click triggers `shown.bs.tab` event | Any tab | 1. Click on a different tab<br>2. Monitor event | Bootstrap tab `shown.bs.tab` event fires | — | — | ⬜ |
| TC-TS02 | Lazy load checks `loaded` class before fetching | Tab A already loaded | 1. Load tab A<br>2. Switch to tab B<br>3. Switch back to A | Tab A has class `loaded`; no XHR re-fetch | — | — | ⬜ |
| TC-TS03 | First tab load adds `loaded` class | Any tab | 1. Click a tab<br>2. Inspect pane after AJAX | Tab pane element gets class `loaded` added | — | — | ⬜ |
| TC-TS04 | Tab pane id derived from tab name | Any tab | 1. Click `trip-execution` tab<br>2. Inspect target pane | Pane id = `#trip-execution-pane` (tab id + "-pane" suffix) | — | — | ⬜ |
| TC-TS05 | `show.bs.tab` not used (only `shown.bs.tab`) | Any | 1. Attach listener to show event<br>2. Click tab | Only `shown.bs.tab` handler fires (not `show.bs.tab`) — content loads after animation completes | — | — | ⬜ |

### 6.36 Daterangepicker Specific

| TC ID | Description | Prerequisites | Test Steps | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|---------------|------------|-----------------|---------|---------|--------|
| TC-DR01 | Default start date = 1st of current month | Page fresh load | 1. Load page<br>2. Observe date input | Shows current month's first day as start | — | — | ⬜ |
| TC-DR02 | Default end date = last day of current month | Page fresh load | 1. Load page<br>2. Observe date input | Shows current month's last day as end | — | — | ⬜ |
| TC-DR03 | Daterangepicker format is YYYY-MM-DD | Any | 1. Open picker<br>2. Inspect date format | `locale.format = 'YYYY-MM-DD'` | — | — | ⬜ |
| TC-DR04 | Date range from `from_date`/`to_date` query params restored | URL with params | 1. Navigate to `?from_date=2026-06-01&to_date=2026-06-15`<br>2. Observe picker | Picker shows Jun 1 → Jun 15 from query params | — | — | ⬜ |
| TC-DR05 | Date range hidden inputs initially set | Page load | 1. Load page<br>2. Inspect hidden `from_date` and `to_date` | Values match current month start/end | — | — | ⬜ |
| TC-DR06 | Date range change auto-submits filter form | Any range | 1. Select new range<br>2. Observe | Picker callback triggers `.transport-filter-form`.submit() | — | — | ⬜ |

### 6.37 Trip Type Specific Scenarios

| TC ID | Description | Prerequisites | Test Steps | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|---------------|------------|-----------------|---------|---------|--------|
| TC-TT01 | Trip type "shift" renders as badge | shift.name = "Morning Shift" | 1. Create trip with this shift<br>2. Load page | Badge shows "Morning Shift" with `bg-info` | — | — | ⬜ |
| TC-TT02 | Trip type "pickup_drop" renders as badge | route.pickup_drop = "Drop Only" | 1. Create trip where shift is null<br>2. Load page | Badge shows "Drop Only" | — | — | ⬜ |
| TC-TT03 | Trip type "—" when everything null | null shift + null pickup_drop | 1. Create trip with both null<br>2. Load page | Badge shows "—" | — | — | ⬜ |
| TC-TT04 | Trip type varies by scheduler shift | Different shift per route | 1. Create trips on different shifts<br>2. Load page | Each row shows the correct shift name for its route scheduler | — | — | ⬜ |

### 6.38 Student Boarding Log Edge Cases (Expanded)

| TC ID | Description | Prerequisites | Test Steps | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|---------------|------------|-----------------|---------|---------|--------|
| TC-SB01 | Boarding log with boarding_time set to null | Incomplete log | 1. Create log with boarding_time = null, unboarding_time = null<br>2. Load page | Log not counted in either count; `whereNotNull` filters it out | — | — | ⬜ |
| TC-SB02 | Boarding log with both times set to same timestamp | Same-time board/unboard | 1. Set both times to same value<br>2. Load page | Counted in both; boardings == unboardings → SAFE if counts match | — | — | ⬜ |
| TC-SB03 | Boarding logs from different trips with same trip_date | Multiple trips same date | 1. Create 2 trips on same date<br>2. Add logs to both<br>3. Load page | Each trip's logs counted independently via FK | — | — | ⬜ |
| TC-SB04 | Boarding logs with only unboarding_time (no boarding) | Partial data | 1. Create log with null boarding, set unboarding<br>2. Load page | Boarded = 0, Unboarded = count; Status = RISK (0 !== count) | — | — | ⬜ |
| TC-SB05 | 0 boarding logs for trip with active route allocations | No attendance | 1. Trip exists, route has allocations, no logs<br>2. Load page | Planned > 0, Boarded = 0, Completion = 0%, Status = RISK | — | — | ⬜ |

### 6.39 Filter Clearing & Re-applying

| TC ID | Description | Prerequisites | Test Steps | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|---------------|------------|-----------------|---------|---------|--------|
| TC-FC01 | Clear filter then re-apply same filter | Filter active | 1. Apply route=Alpha<br>2. Click Reset<br>3. Re-apply route=Alpha | Both requests return same data; no caching issues | — | — | ⬜ |
| TC-FC02 | Filter then clear shows all data | Filter active | 1. Apply route=Alpha<br>2. Click Reset | All routes shown again; 3 routes visible | — | — | ⬜ |
| TC-FC03 | Filter with no matching data shows empty state | Non-existent driver ID | 1. Set driver_id param to invalid value<br>2. Submit filter | Empty table; no matching trips | — | — | ⬜ |
| TC-FC04 | Rapid filter changes (debounce test) | Multiple sequential filters | 1. Select route Alpha → wait for load<br>2. Select route Beta → wait for load<br>3. Select route Gamma | Each filter applied correctly; final state shows Gamma trips only | — | — | ⬜ |

### 6.40 Sort Order Verification

| TC ID | Description | Prerequisites | Test Steps | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|---------------|------------|-----------------|---------|---------|--------|
| TC-SO01 | Trips ordered by latest trip_date | 3 trips on different dates | 1. Load page<br>2. Observe table row order | Rows ordered by `trip_date` descending (query uses no explicit orderBy — depends on DB default) | — | — | ⬜ |
| TC-SO02 | No explicit `->orderBy()` in query | Any data | 1. Inspect `getTripExecutionReport()` line 682 | No `->orderBy('trip_date', 'desc')` — relies on DB/Model default ordering (PK desc?) | — | — | ⬜ |
| TC-SO03 | Same-date trips order | 2 trips on same date | 1. Create 2 trips on same date<br>2. Load page | Order between same-date trips is arbitrary (DB-dependent) | — | — | ⬜ |

### 6.41 Browser Compatibility

| TC ID | Description | Prerequisites | Test Steps | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|---------------|------------|-----------------|---------|---------|--------|
| TC-BR01 | Chrome latest | Any data | 1. Load in Chrome 120+<br>2. Verify all elements | Charts render, AJAX works, table displays correctly | — | — | ⬜ |
| TC-BR02 | Firefox latest | Same | 1. Load in Firefox 120+<br>2. Verify | Same as Chrome — Chart.js is cross-browser compatible | — | — | ⬜ |
| TC-BR03 | Safari latest | Same | 1. Load in Safari 17+<br>2. Verify | Daterangepicker and Chart.js work in Safari | — | — | ⬜ |
| TC-BR04 | Edge latest | Same | 1. Load in Edge 120+<br>2. Verify | Works as Chromium-based browser | — | — | ⬜ |
| TC-BR05 | Mobile viewport (375px) | Any data | 1. Load in mobile viewport<br>2. Observe responsive layout | Filter elements wrap; table may overflow; KPI cards 2 per row; charts stack vertically | — | — | ⬜ |
| TC-BR06 | Tablet viewport (768px) | Any data | 1. Load at 768px<br>2. Observe | KPI cards 2 per row; filter form wraps; charts side by side | — | — | ⬜ |

### 6.42 Chart.js Specific Rendering

| TC ID | Description | Prerequisites | Test Steps | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|---------------|------------|-----------------|---------|---------|--------|
| TC-CH01 | Safety chart `cutout: 60%` creates donut hole | Any data | 1. Load page<br>2. Inspect chart rendering | Chart has visible hollow center (60% cutout) | — | — | ⬜ |
| TC-CH02 | Safety chart animation on initial render | Any data | 1. Load page fresh<br>2. Observe chart entrance | `animateScale: true, animateRotate: true` — chart grows and rotates into view | — | — | ⬜ |
| TC-CH03 | Completion chart animation easeOutQuart | Any data | 1. Load page<br>2. Observe bar entrance | `animation.duration: 1000, easing: 'easeOutQuart'` — bars animate with deceleration curve | — | — | ⬜ |
| TC-CH04 | Performance chart interaction mode | Hover near bar | 1. Hover near but not directly on a bar<br>2. Observe tooltip | `interaction.intersect: false, mode: 'index'` — tooltip shows even when not directly on element | — | — | ⬜ |
| TC-CH05 | Chart.js `@json` produces valid JS | Complex data | 1. Inspect generated page source<br>2. Check JS literals | `@json($tripExecutionReports->toArray())` produces valid JSON array embedded in JS | — | — | ⬜ |
| TC-CH06 | Chart canvases have unique IDs | Multiple tabs loaded | 1. Load page<br>2. Check for duplicate IDs | `tripSafetyChart`, `completionRateChart`, `tripPerformanceChart` — unique across all tabs | — | — | ⬜ |

### 6.43 HTTP Response Verification

| TC ID | Description | Prerequisites | Test Steps | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|---------------|------------|-----------------|---------|---------|--------|
| TC-HT01 | Initial page load returns 200 | Any | 1. Load `/transport-report?active_tab=trip-execution`<br>2. Check HTTP status | HTTP 200 OK | — | — | ⬜ |
| TC-HT02 | AJAX charts request returns 200 | Any data | 1. Send XHR with section=charts<br>2. Check response | HTTP 200; Content-Type: application/json | — | — | ⬜ |
| TC-HT03 | AJAX table request returns 200 | Any data | 1. Send XHR with section=table<br>2. Check response | HTTP 200; JSON body with `html` key | — | — | ⬜ |
| TC-HT04 | AJAX response has correct JSON structure | Any data | 1. Inspect XHR response | `{"html":"<string>"}` — single key-value pair | — | — | ⬜ |
| TC-HT05 | Page without permission returns 403 | No permission | 1. Access page without permission<br>2. Check response | `Gate::authorize()` at controller level throws `AuthorizationException` → 403 page | — | — | ⬜ |
| TC-HT06 | Guest access returns 302 redirect | Not logged in | 1. Access page while logged out<br>2. Check response | HTTP 302 redirect to login page | — | — | ⬜ |

### 6.44 Read-Only Verification

| TC ID | Description | Prerequisites | Test Steps | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|---------------|------------|-----------------|---------|---------|--------|
| TC-RO01 | Report page performs no write operations | Any | 1. Monitor DB queries during page load<br>2. Check for INSERT/UPDATE/DELETE | Only SELECT queries executed; no mutations | — | — | ⬜ |
| TC-RO02 | No POST forms on the tab | Any | 1. Inspect HTML on trip-execution tab<br>2. Count POST forms | Zero `<form method="POST">` elements; only GET forms | — | — | ⬜ |
| TC-RO03 | Controller methods are GET-only | Any | 1. Check routes<br>2. Attempt POST to same URL | Request via POST would not match the GET-only route; returns 405 | — | — | ⬜ |

### 6.45 Multi-Tenant Data Isolation

| TC ID | Description | Prerequisites | Test Steps | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|---------------|------------|-----------------|---------|---------|--------|
| TC-MT01 | Tenant A trips not visible to Tenant B | 2 tenants with data | 1. Log in as Tenant A<br>2. Load page<br>3. Switch to Tenant B | Tenant A sees only own trips; Tenant B sees only own trips (assuming tenant scoping via `Gate::authorize` + global scope) | — | — | ⬜ |
| TC-MT02 | Filter dropdowns show only tenant's active records | 2 tenants | 1. Log in as Tenant A<br>2. Open route dropdown | Only Tenant A's routes shown (tenant scoped in `getFilterData()`) | — | — | ⬜ |

### 6.46 CSRF and Request Security

| TC ID | Description | Prerequisites | Test Steps | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|---------------|------------|-----------------|---------|---------|--------|
| TC-CS01 | GET request does not require CSRF token | Any | 1. Submit filter form<br>2. Check headers | No `X-CSRF-TOKEN` header required for GET requests | — | — | ⬜ |
| TC-CS02 | AJAX GET does not include CSRF token | Any | 1. Monitor XHR request headers<br>2. Check for CSRF | `X-Requested-With: XMLHttpRequest` present; CSRF not required | — | — | ⬜ |
| TC-CS03 | JSON response cannot be used for CSRF injection | Any | 1. Check response MIME type | `Content-Type: application/json` prevents browser from executing as script | — | — | ⬜ |

### 6.47 Rendered HTML Verification

| TC ID | Description | Prerequisites | Test Steps | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|---------------|------------|-----------------|---------|---------|--------|
| TC-HTML01 | Table has `table table-sm` classes | Any data | 1. Inspect `<table>` element | Classes: `table table-sm` | — | — | ⬜ |
| TC-HTML02 | Progress bar has correct width percentage | 80% completion | 1. Inspect progress bar div | `style="width: 80%"` with class `bg-warning` | — | — | ⬜ |
| TC-HTML03 | Status badge has correct icon | SAFE status | 1. Inspect status badge | `<i class="bi bi-check-circle-fill me-1"></i>` | — | — | ⬜ |
| TC-HTML04 | Status badge has correct icon for RISK | RISK status | 1. Inspect RISK badge | `<i class="bi bi-exclamation-triangle-fill me-1"></i>` | — | — | ⬜ |
| TC-HTML05 | Date column uses `<strong>` for date | Any | 1. Inspect Date cell | `<strong>01 Jun 2026</strong>` | — | — | ⬜ |
| TC-HTML06 | Time range uses `<small class="text-muted">` | Times present | 1. Inspect time range element | `<small class="text-muted">07:00 - 08:30</small>` | — | — | ⬜ |
| TC-HTML07 | Empty state uses colspan=11 | No data | 1. Load empty state<br>2. Inspect empty cell | `<td colspan="11">` spanning all columns | — | — | ⬜ |
| TC-HTML08 | Filter select uses `@selected` for persistence | Filter applied | 1. Apply Alpha Route filter<br>2. Inspect select element | `<option value="1" selected>` | — | — | ⬜ |

### 6.48 Date Handling Edge Cases

| TC ID | Description | Prerequisites | Test Steps | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|---------------|------------|-----------------|---------|---------|--------|
| TC-DH01 | trip_date stored as date (not datetime) | DB schema | 1. Check migration | `$table->date('trip_date')` — no time component | — | — | ⬜ |
| TC-DH02 | trip_date format in blade matches `d M Y` | Any date | 1. Check formatted output | `$trip->trip_date->format('d M Y')` = "01 Jun 2026" | — | — | ⬜ |
| TC-DH03 | start_time and end_time stored as time or datetime | DB schema | 1. Check migration | `$table->time('start_time')->nullable()` — or datetime | — | — | ⬜ |
| TC-DH04 | start_time format in blade matches `H:i` | Any time | 1. Check formatted output | `$trip->start_time->format('H:i')` = "07:00" | — | — | ⬜ |
| TC-DH05 | Carbon date parsing handles null safely | null start_time | 1. Create trip with null start_time<br>2. Load page | `optional($trip->start_time)->format('H:i')` returns null → '-' | — | — | ⬜ |

### 6.49 View Partial & Include Verification

| TC ID | Description | Prerequisites | Test Steps | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|---------------|------------|-----------------|---------|---------|--------|
| TC-VI01 | `@include` path matches blade file | None | 1. Check `transportreport.blade.php` line 33 | `@include('transport::report.trip-execution-discipline.index')` — file exists at `Modules/Transport/resources/views/report/trip-execution-discipline/index.blade.php` | — | — | ⬜ |
| TC-VI02 | Tab pane id in partial matches nav-tab target | None | 1. Check `index.blade.php` tab-pane div | `id="trip-execution-pane"` matches nav tab `data-bs-target="#trip-execution-pane"` | — | — | ⬜ |
| TC-VI03 | `@can` permission string matches nav-tab | None | 1. Check both files | `@can('tenant.trip-execution.viewAny')` in `transportreport.blade.php:32` matches `'permission' => 'tenant.trip-execution.viewAny'` in `transportreport.blade.php:13` | — | — | ⬜ |
| TC-VI04 | No `x-backend.layouts.app` in partial (no double layout) | None | 1. Check `index.blade.php` | File does NOT contain `x-backend.layouts.app` (it's a partial, not a full page) | — | — | ⬜ |
| TC-VI05 | Every `@if` has matching `@endif` | None | 1. Scan blade directives | Balanced: `@if`(`section === 'charts'`)...`@elseif`(table)...`@else`...`@endif` | — | — | ⬜ |

### 6.50 Console Error & Warning Verification

| TC ID | Description | Prerequisites | Test Steps | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|---------------|------------|-----------------|---------|---------|--------|
| TC-CN01 | No JS errors on page load | Any data | 1. Load page<br>2. Check browser console | Zero errors; Chart.js, jQuery, daterangepicker all initialize cleanly | — | — | ⬜ |
| TC-CN02 | No JS errors on filter change | Any | 1. Apply filter<br>2. Check console | No errors from chart re-rendering or DOM updates | — | — | ⬜ |
| TC-CN03 | No JS errors on tab switch | Any | 1. Switch tabs back and forth<br>2. Check console | No "Chart is already initialized" or canvas-related errors | — | — | ⬜ |
| TC-CN04 | No JS errors on pagination click | 11+ trips | 1. Click page 2<br>2. Check console | No errors from paginator AJAX replacing table content | — | — | ⬜ |
| TC-CN05 | No PHP warnings in Laravel log | All edge cases | 1. Run through edge case trips<br>2. Check `storage/logs/laravel.log` | No "Trying to get property 'name' of non-object" or similar warnings | — | — | ⬜ |

---

## 7. Test Environment Setup

### 7.1 Required Seed Data



### 7.2 Testing Tools

| Tool | Purpose |
|------|---------|
| Laravel Dusk / PHPUnit | Automated browser testing for AJAX interactions |
| Laravel Telescope / Debugbar | Monitor N+1 queries, memory usage, SQL queries |
| Chrome DevTools Network tab | Monitor XHR requests, response sizes, timing |
| Chrome DevTools Console | Check for JS errors (Chart.js, AJAX failures) |
| Postman / cURL | Direct API testing for AJAX endpoints |

### 7.3 Test User Roles

| Role | Permissions |
|------|------------|
| Super Admin | All permissions, including `tenant.trip-execution.viewAny` |
| Transport Manager | `tenant.trip-execution.viewAny` only |
| School Admin | No transport report permissions |
| Guest | Not authenticated |

---

## 8. Defect Classification Guide

| Severity | Definition | Example |
|----------|------------|---------|
| P1 — Critical | Feature broken; data incorrect; security issue | Safety status reversed; wrong permission check; SQL injection |
| P2 — Major | Functional but with incorrect display or performance issue | N+1 query; chart colors wrong; pagination conflicting with other tabs |
| P3 — Minor | Cosmetic or non-functional | Icon not showing; alignment off; unused variable in blade |
| P4 — Enhancement | Suggestion for improvement | Add debounce to filter; add skeleton loading; add export |

---

## 9. Automation Checklist

| TC IDs | Automatable? | Suggested Tool | Notes |
|--------|-------------|----------------|-------|
| TC-P01 to TC-P10 | Yes | Laravel Dusk | Assert element visibility, text content, and class presence |
| TC-P11 to TC-P38 | Yes | Laravel Dusk | Assert table cell values, badge colors, progress bar widths |
| TC-P39 to TC-P69 | Partial | Dusk + JS evaluation | Assert canvas exists; visual regression testing recommended |
| TC-P70 to TC-P85 | Yes | Dusk | Select options, submit, assert table content changes |
| TC-P86 to TC-P94 | Yes | Dusk | Click pagination links, assert row count changes |
| TC-N01 to TC-N16 | Yes | Dusk + seed | Seed specific edge data, assert empty states and fallbacks |
| TC-N17 to TC-N24 | Yes | Dusk with roles | Login as different role, assert 403/hidden elements |
| TC-CR01 to TC-CR26 | Manual | Code review | Static analysis; PHPStan; review against CR checklist |
| TC-PF01 to TC-PF08 | Manual | Chrome DevTools | Measure timing, memory, network payload |
| TC-DI01 to TC-DI06 | Yes | PHPUnit | Seed specific data, call data method, assert computed properties |
| TC-UI01 to TC-UI13 | Manual | Visual / Chrome responsive mode | Visual inspection at various viewports |
| TC-BR01 to TC-BR06 | Manual | Cross-browser testing | Load in each browser, verify functionality |

---

## 10. Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| N+1 query performance degradation with large datasets | High | Medium | Add eager loading (`->with('vehicle','driver','shift','boardingLogs','tripStopDetail','routeScheduler.route.studentAllocationsAll')`) |
| Chart.js CDN failure breaks charts section | Low | High | Add local fallback or integrity hash |
| Cross-tab pagination page name collision | Low | High | Already mitigated with unique `page_trip` name |
| Race condition on rapid filter changes | Medium | Low | Implement debounce or abort previous request |
| Memory exhaustion with 5000+ trips in range | Medium | High | Convert to DB-level pagination instead of in-memory collection pagination |
| Delayed CDN resources block rendering | Low | Medium | Preload critical scripts; use async/defer |

---

## 11. Version History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-07-22 | Test Team | Initial TC_List creation (149 lines) |
| 2.0 | 2026-07-22 | Test Team | Expanded to comprehensive coverage with 300+ test cases across 50 sections |

---

## 12. Test Case Count Summary

| Section | Count | Range |
|---------|-------|-------|
| 6.1 Positive — Tab Load & Initial State | 10 | TC-P01 to TC-P10 |
| 6.2 Positive — Table Columns & Data Display | 28 | TC-P11 to TC-P38 |
| 6.3 Positive — Trip Safety Chart (Doughnut) | 8 | TC-P39 to TC-P46 |
| 6.4 Positive — Completion Rate Chart (Bar) | 11 | TC-P47 to TC-P57 |
| 6.5 Positive — Trip Performance Overview Chart | 12 | TC-P58 to TC-P69 |
| 6.6 Positive — Filters | 16 | TC-P70 to TC-P85 |
| 6.7 Positive — Pagination | 9 | TC-P86 to TC-P94 |
| 6.8 Positive — AJAX Architecture | 8 | TC-P95 to TC-P102 |
| 6.9 Negative — Empty States & Edge Cases | 16 | TC-N01 to TC-N16 |
| 6.10 Negative — Permission & Security | 8 | TC-N17 to TC-N24 |
| 6.11 Code Review | 26 | TC-CR01 to TC-CR26 |
| 6.12 Integration — Cross-Tab Behavior | 7 | TC-I01 to TC-I07 |
| 6.13 Performance | 8 | TC-PF01 to TC-PF08 |
| 6.14 Data Integrity | 6 | TC-DI01 to TC-DI06 |
| 6.15 UI / UX | 13 | TC-UI01 to TC-UI13 |
| 6.16 Chart.js Script Integrity | 9 | TC-CJ01 to TC-CJ09 |
| 6.17 Routing & URL | 6 | TC-RT01 to TC-RT06 |
| 6.18 Model Relationships | 9 | TC-MR01 to TC-MR09 |
| 6.19 Edge Cases — Dates & Boundaries | 8 | TC-EC01 to TC-EC08 |
| 6.20 Edge Cases — Driver & Vehicle | 5 | TC-EC09 to TC-EC13 |
| 6.21 Edge Cases — Route & Stop | 5 | TC-EC14 to TC-EC18 |
| 6.22 Edge Cases — Boarding Log | 6 | TC-EC19 to TC-EC24 |
| 6.23 Edge Cases — Trip Delay | 7 | TC-EC25 to TC-EC31 |
| 6.24 Blade Rendering Edge Cases | 6 | TC-BL01 to TC-BL06 |
| 6.25 Paginator Collection Edge Cases | 7 | TC-PG01 to TC-PG07 |
| 6.26 Permission & Policy Verification | 6 | TC-PM01 to TC-PM06 |
| 6.27 Database Migration Verification | 6 | TC-DB01 to TC-DB06 |
| 6.28 Accessibility | 8 | TC-A11Y01 to TC-A11Y08 |
| 6.29 Data Consistency Check | 6 | TC-DC01 to TC-DC06 |
| 6.30 Security — Data Leakage | 4 | TC-SEC01 to TC-SEC04 |
| 6.31 KPI Card Visual Verification | 8 | TC-KPI01 to TC-KPI08 |
| 6.32 Chart Card Container Verification | 5 | TC-CC01 to TC-CC05 |
| 6.33 Filter Form Specific Behavior | 8 | TC-FF01 to TC-FF08 |
| 6.34 AJAX Loader & Transition States | 7 | TC-AJ01 to TC-AJ07 |
| 6.35 Tab Switch Behavior | 5 | TC-TS01 to TC-TS05 |
| 6.36 Daterangepicker Specific | 6 | TC-DR01 to TC-DR06 |
| 6.37 Trip Type Specific Scenarios | 4 | TC-TT01 to TC-TT04 |
| 6.38 Student Boarding Log Edge Cases (Expanded) | 5 | TC-SB01 to TC-SB05 |
| 6.39 Filter Clearing & Re-applying | 4 | TC-FC01 to TC-FC04 |
| 6.40 Sort Order Verification | 3 | TC-SO01 to TC-SO03 |
| 6.41 Browser Compatibility | 6 | TC-BR01 to TC-BR06 |
| 6.42 Chart.js Specific Rendering | 6 | TC-CH01 to TC-CH06 |
| 6.43 HTTP Response Verification | 6 | TC-HT01 to TC-HT06 |
| 6.44 Read-Only Verification | 3 | TC-RO01 to TC-RO03 |
| 6.45 Multi-Tenant Data Isolation | 2 | TC-MT01 to TC-MT02 |
| 6.46 CSRF and Request Security | 3 | TC-CS01 to TC-CS03 |
| 6.47 Rendered HTML Verification | 8 | TC-HTML01 to TC-HTML08 |
| 6.48 Date Handling Edge Cases | 5 | TC-DH01 to TC-DH05 |
| 6.49 View Partial & Include Verification | 5 | TC-VI01 to TC-VI05 |
| 6.50 Console Error & Warning Verification | 5 | TC-CN01 to TC-CN05 |
| **Total** | **330+** | — |
