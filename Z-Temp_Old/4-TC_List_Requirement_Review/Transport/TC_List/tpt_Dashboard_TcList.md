# tpt_Dashboard_TcList

## Module: Transport → Transport Master → Dashboard

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | Transport |
| Tab Group | Transport Master |
| Feature | Dashboard |
| URL(s) | `/transport/transport-master` (page load via tab), `/transport/dashboard/data` (AJAX data endpoint GET) |
| Controller | `Modules\Transport\Http\Controllers\TransportDashboardController@index()` |
| Tab Container Controller | `Modules\Transport\Http\Controllers\TransportMasterController@index()` |
| Model | No dedicated Dashboard model. Reads from: `Vehicle`, `DriverHelper`, `TptTrip`, `TptStudentAllocationJnt`, `DriverRouteVehicleJnt`, `TptVehicleMaintenance`, `TptTripIncidents`, `TptVehicleFuel`, `TptDriverAttendance` |
| Request | None — no FormRequest, uses `Illuminate\Http\Request` directly |
| Permissions | `tenant.transport-dashboard.viewAny` (gate in controller); tab is guarded by `@can('tenant.transport-dashboard.viewAny')` in transportmaster.blade.php |
| Policy | `Modules\Transport\Policies\TransportDashboardPolicy` — 7 gates defined (viewAny, view, create, update, delete, restore, forceDelete) but only `viewAny` is used in controller |
| Soft Deletes | N/A (no dashboard model) |
| Activity Log | None — this is a read-only analytics endpoint |

---

## 2. Pre-conditions

- Required permission: `tenant.transport-dashboard.viewAny`
- Test user must have the above permission (default admin user)
- Tenant context must be initialized via `tenancy()->initialize()`
- Dusk environment variables: `DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD`
- Seed data required: At least 1 `Vehicle` (active), 1 `DriverHelper`, 3+ `TptTrip` records with varied statuses (Scheduled/Completed/Cancelled/Ongoing), 1 `TptStudentAllocationJnt` (active_status=1), 1 `DriverRouteVehicleJnt` (is_active=1), 1 `TptVehicleFuel` (Approved), 1 `TptDriverAttendance` for today, 1 `TptTripIncidents`
- Dashboard loads as part of TransportMaster — the URL `/transport/transport-master?tab=transport_dashboard` loads TransportMasterController@index with all master tabs simultaneously
- Dashboard data is fetched via AJAX after page load (not server-side rendered)

---

## 3. Default Data Load

When the page loads via TransportMasterController@index() (GET /transport/transport-master), the dashboard tab is included:

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| Dashboard Tab Container | `TransportMasterController@index()` | All master data loaded (vehicles, routes, shifts, etc.) — returns `transport::tab_module.transportmaster` view | tab=transport_dashboard | N/A |
| Dashboard Tab Partial | view: `transport::dashboard.index` | Included inside `transportmaster.blade.php` via `@include('transport::dashboard.index')` wrapped in `@can('tenant.transport-dashboard.viewAny')` | N/A | N/A |
| **Dashboard KPI/Analytics** | **NOT server-rendered** — loaded via AJAX `GET /transport/dashboard/data` from JavaScript `loadDashboardData()` | See Section 5.2 | from_date, to_date (default: month-to-date) | N/A |

### 3.1 Dashboard Tab Content (Static HTML)

The dashboard tab renders placeholder elements that get populated via AJAX:
- KPI Cards section `(TransportDashboardController.php:53-76)`: totalActiveVehicles, totalActiveDrivers, todaysTrips, transportStudents
- Trip Completion Chart section `(TransportDashboardController.php:78-136)`: Chart.js line chart with 4 datasets (Scheduled, Completed, Cancelled, Ongoing)
- Vehicle Status section `(TransportDashboardController.php:138-173)`: total, onRoute, available, maintenance, outOfService, utilizationRate
- Active Routes table `(TransportDashboardController.php:185-214)`: route name, shift, vehicle, driver, students (top 10)
- Maintenance Alerts table `(TransportDashboardController.php:216-275)`: fitness/insurance/maintenance with status badges
- Fuel Consumption metric `(TransportDashboardController.php:282-297)`: monthly fuel, cost, month-over-month change
- Driver Attendance metric `(TransportDashboardController.php:299-308)`: today's attendance rate, present/total
- Incident Reports metric `(TransportDashboardController.php:310-339)`: total incidents (resolved/high/medium/low)
- Recent Trip Logs table `(TransportDashboardController.php:342-365)`: trip_id, date_time, route, vehicle, driver, status, duration (top 10)

---

## 4. Test Data Strategy

- **Date range**: Defaults to current month (`now()->startOfMonth()` to `now()->endOfMonth()`). Use fixed dates for reproducible tests.
- **Vehicles**: Create at least 3 `Vehicle` records with varied `is_active` and `availability_status` to test vehicle status breakdown
- **Trips**: Create at least 4 trips per day with statuses: 'Scheduled', 'Completed', 'Cancelled', 'Ongoing' spread across the date range
- **Maintenance alerts**: Create vehicles with `fitness_valid_upto` in past (overdue), within 7 days (due_soon), and far future (upcoming)
- **Driver attendance**: Create `TptDriverAttendance` records for today with `attendance_status` = Present (some) and Absent (some)
- **Fuel**: Create `TptVehicleFuel` records with `status = 'Approved'` for current month and previous month
- **Incidents**: Create `TptTripIncidents` with varied `severity` (HIGH, MEDIUM, LOW) and `status` (resolved vs null)
- **No modification**: Dashboard is read-only AJAX — tests should not modify data via dashboard
- **No dedicated model**: There is no Dashboard model/table — all data is aggregated from other transport tables

---

## 5. Business Conditions

### 5.1 Database Schema

The Dashboard does NOT have its own DDL table. It aggregates from the following tables:

| BC ID | Source Table | Key Columns Used | Purpose |
|-------|-------------|------------------|---------|
| BC-DB-01 | `tpt_vehicle` | id, is_active, registration_no, fitness_valid_upto, insurance_valid_upto, availability_status | Active vehicles count, vehicle status breakdown, maintenance alerts |
| BC-DB-02 | `tpt_personnel` | id, name, role | Active drivers count (DriverHelper scope via `DriverHelper::count()`) |
| BC-DB-03 | `tpt_trip` | id, trip_date, start_time, end_time, status, vehicle_id, route_id, driver_id | Trip counts (total/completed/scheduled/cancelled/ongoing), recent trips, on-route vehicles |
| BC-DB-04 | `tpt_student_route_allocation_jnt` | id, active_status, effective_from | Transport students count (where active_status=1 AND effective_from <= toDate) |
| BC-DB-05 | `tpt_driver_route_vehicle_jnt` | id, route_id, vehicle_id, driver_id, effective_from, effective_to, is_active, total_students | Active routes list, on-route vehicle count |
| BC-DB-06 | `tpt_vehicle_maintenance` | id, vehicle_service_request_id, status, out_service_date, next_due_date, in_service_date | Maintenance alerts (Pending/Approved without out_service_date) |
| BC-DB-07 | `tpt_vehicle_fuel` | id, date, quantity, cost, status | Fuel consumption (current month vs previous month, status=Approved) |
| BC-DB-08 | `tpt_driver_attendance` | id, driver_id, attendance_date, attendance_status | Today's driver attendance rate |
| BC-DB-09 | `tpt_trip_incidents` | id, trip_id, severity, status, created_at | Incident reports (current month metrics) |

### 5.2 AJAX Response Shape — `TransportDashboardController@index()`

| BC ID | JSON Key | Type | Source Method | Description |
|-------|----------|------|---------------|-------------|
| BC-AJX-01 | kpi.activeVehicles | int | `getKpiData()` line 59 | `Vehicle::active()->count()` |
| BC-AJX-02 | kpi.activeDrivers | int | `getKpiData()` line 60 | `DriverHelper::count()` |
| BC-AJX-03 | kpi.todaysTrips | int | `getKpiData()` line 63 | `TptTrip::whereBetween('trip_date', [$fromDate, $toDate])->count()` |
| BC-AJX-04 | kpi.transportStudents | int | `getKpiData()` line 66-68 | `TptStudentAllocationJnt::where('active_status',1)->where('effective_from','<=',$toDate)->count()` |
| BC-AJX-05 | tripChart.labels | string[] | `getTripChartData()` line 94 | Per-day labels "d M" format |
| BC-AJX-06 | tripChart.datasets[0-3] | object[] | `getTripChartData()` lines 96-110 | 4 datasets: Scheduled, Completed, Cancelled, Ongoing (daily counts) |
| BC-AJX-07 | vehicleStatus.total | int | `getVehicleStatus()` line 143 | `Vehicle::count()` |
| BC-AJX-08 | vehicleStatus.onRoute | int | `getVehicleStatus()` line 145 via `getOnRouteVehiclesCount()` | Distinct vehicles in Ongoing/Scheduled trips |
| BC-AJX-09 | vehicleStatus.available | int | `getVehicleStatus()` line 163 | `availableVehicles - onRouteVehicles - maintenanceVehicles` (clamped to 0) |
| BC-AJX-10 | vehicleStatus.maintenance | int | `getVehicleStatus()` line 148-154 | Vehicles with Approved service requests having maintenance between dates |
| BC-AJX-11 | vehicleStatus.outOfService | int | `getVehicleStatus()` lines 156-161 | Vehicles where is_active=0 OR (is_active=1 AND availability_status=0) |
| BC-AJX-12 | vehicleStatus.utilizationRate | int | `getVehicleStatus()` line 171 | `round((onRoute / total) * 100)` |
| BC-AJX-13 | activeRoutes[] | array | `getActiveRoutes()` lines 185-214 | Top 10 active driver-route-vehicle assignments with route/shift/vehicle/driver/students |
| BC-AJX-14 | maintenanceAlerts[] | array | `getMaintenanceAlerts()` lines 216-275 | Up to 10 alerts: fitness cert, insurance, maintenance with status (overdue/due_soon/upcoming) |
| BC-AJX-15 | additionalMetrics.fuel | object | `getAdditionalMetrics()` lines 282-297 | consumption, cost, month-over-month change % |
| BC-AJX-16 | additionalMetrics.attendance | object | `getAdditionalMetrics()` lines 299-308 | rate%, present, total (today) |
| BC-AJX-17 | additionalMetrics.incidents | object | `getAdditionalMetrics()` lines 310-339 | total, resolved, high, medium, low (current month) |
| BC-AJX-18 | recentTrips[] | array | `getRecentTrips()` lines 342-365 | Top 10 trips by trip_date DESC, start_time DESC with formatted trip_id (TRP-00001) |
| BC-AJX-19 | dateRange | object | `index()` lines 43-47 | from, to, display string ("M j - M j, Y") |

### 5.3 Authorization (Permission Gates)

| BC ID | Permission | Controller Method | Behavior |
|-------|-----------|-------------------|----------|
| BC-AUTH-01 | tenant.transport-dashboard.viewAny | `TransportDashboardController@index()` line 30 | `Gate::authorize('tenant.transport-dashboard.viewAny')` → without it, 403 |
| BC-AUTH-02 | tenant.transport-dashboard.viewAny | `TransportMasterController@index()` line 30 | Tab container gate check; without it, dashboard data endpoint is inaccessible |
| BC-AUTH-03 | tenant.transport-dashboard.viewAny | Blade `@can` in transportmaster.blade.php line 23 | Without → Dashboard tab-pane is hidden entirely |

### 5.4 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Dashboard tab is first/default tab | Tab is `active show` on initial page load (transportmaster.blade.php — first tab-pane has `active show` class) |
| BC-BIZ-02 | AJAX call on tab shown | `$('#transport_dashboard-tab').on('shown.bs.tab', loadDashboardData)` — data loaded when tab activates |
| BC-BIZ-03 | AJAX call on initial load | If pane already has `active show` class, `loadDashboardData()` called immediately in `initializeTransportDashboard()` |
| BC-BIZ-04 | Date range picker change triggers reload | `$('#transport_daterange').daterangepicker({...})` callback calls `loadDashboardData()` |
| BC-BIZ-05 | KPI data empty state | When count = 0, all cards show "0" |
| BC-BIZ-06 | Chart with no trip data | All dataset values are 0; Chart.js renders flat line at 0 |
| BC-BIZ-07 | No active routes | Table shows "No active routes" in one merged row |
| BC-BIZ-08 | No maintenance alerts | Table shows "No alerts" in one merged row |
| BC-BIZ-09 | No recent trips | Table shows "No recent trips" in one merged row |
| BC-BIZ-10 | AJAX error handling | `xhr.error` → `showError('Failed to load dashboard data')` — alert() function |
| BC-BIZ-11 | Trip ID formatting | `TRP-` + str_pad(id, 5, '0', STR_PAD_LEFT) → e.g., "TRP-00001" |
| BC-BIZ-12 | Trip duration calculation | If both start_time and end_time are Carbon instances: `diff()->format('%hh %im')` |
| BC-BIZ-13 | Vehicle status utilization rate | `round(($onRoute / $total) * 100)` — when total=0, utilizationRate=0 (ternary guards) |
| BC-BIZ-14 | Maintenance alert status determination | `<= now()` → "overdue"; `<= now()->addDays(7)` → "due_soon"; else "upcoming" |
| BC-BIZ-15 | Fitness/insurance alerts query | Both use `Vehicle::get()` (no date filter on query — commented out whereBetween). Returns ALL vehicles, mapped regardless of dates |
| BC-BIZ-16 | Fuel change calculation | `((current - prev) / prev) * 100` — if prev=0, fuelChange=0 (ternary guard line 296-297) |
| BC-BIZ-17 | Driver attendance calculation | `round((present / total) * 100)` — if total=0, attendanceRate=0 |
| BC-BIZ-18 | Active routes query effective date logic | `effective_from BETWEEN dates` OR (`effective_from <= start` AND (`effective_to IS NULL` OR `effective_to >= end`)) |
| BC-BIZ-19 | Active routes limit to 10 | `->limit(10)` at `TransportDashboardController.php:202` |
| BC-BIZ-20 | Trip chart uses `whereDate()` for daily breakdown | Separate queries per day in loop from start to end date |
| BC-BIZ-21 | onRoute vehicles uses DISTINCT vehicle_id | `TptTrip::whereIn('status', ['Ongoing','Scheduled'])->distinct('vehicle_id')->count('vehicle_id')` |

### 5.5 Model Relationships (Referenced by Dashboard)

| BC ID | Model | Relationship/Query | Purpose |
|-------|-------|--------------------|---------|
| BC-REL-01 | Vehicle | `scopeActive()` | `Vehicle::active()->count()` |
| BC-REL-02 | DriverHelper | `DriverHelper::count()` | All personnel (no active scope) |
| BC-REL-03 | TptTrip | `whereBetween('trip_date', [from, to])` | Trip counts, chart data |
| BC-REL-04 | TptStudentAllocationJnt | `where('active_status',1)->where('effective_from','<=',$toDate)` | Transport student count |
| BC-REL-05 | DriverRouteVehicleJnt | `with(['route','vehicle','driver'])->where('is_active',1)->limit(10)` | Active routes list |
| BC-REL-06 | Vehicle (serviceRequests) | `whereHas('serviceRequests', fn=> where('request_approval_status','Approved')...` | Maintenance vehicle count |
| BC-REL-07 | Vehicle (insurance/fitness) | `Vehicle::get()` then manual PHP mapping | Fitness/insurance alerts |

### 5.6 Computational Logic

| BC ID | Expression | Location | Description |
|-------|-----------|----------|-------------|
| BC-CMP-01 | `available = active - onRoute - maintenance` | `TransportDashboardController.php:163` | Clamped to `max(0, available)` |
| BC-CMP-02 | `utilization = round((onRoute / total) * 100)` | `TransportDashboardController.php:171` | Percent utilization |
| BC-CMP-03 | `fuelChange = round(((curr - prev) / prev) * 100, 1)` | `TransportDashboardController.php:296-297` | MoM fuel comparison |
| BC-CMP-04 | `attendanceRate = round((present / total) * 100)` | `TransportDashboardController.php:307-308` | Today's attendance % |
| BC-CMP-05 | Trip ID: `TRP-` . str_pad(id, 5, '0', STR_PAD_LEFT) | `TransportDashboardController.php:355` | Formatted trip ID |
| BC-CMP-06 | Duration: `start_time->diff(end_time)->format('%hh %im')` | `TransportDashboardController.php:351` | Only if both are Carbon instances |

### 5.7 Deep Business Logic Analysis (BC-BIZ-DEEP)

Each private method is analyzed below with line-by-line code tracing and edge case documentation.

#### DEEP-01: `getKpiData()` — Lines 53-76

| Step | Line(s) | Code | Analysis |
|------|---------|------|----------|
| 1 | 55-56 | `Carbon::parse($fromDate)`, `Carbon::parse($toDate)` | Parses string dates to Carbon; will throw `InvalidFormatException` if non-date string passed (GAP: no validation) |
| 2 | 59 | `Vehicle::active()->count()` | Uses `scopeActive()` which applies `WHERE is_active=1`. Includes soft-deleted? Only if model uses SoftDeletes — Vehicle model MUST use SoftDeletes for this to respect trashed filter. Check model for `SoftDeletes` trait. |
| 3 | 60 | `DriverHelper::count()` | Counts ALL `tpt_personnel` records — no active filter, no role filter. **GAP:** This counts drivers + helpers + transport managers, not just "Active Drivers" as the label claims |
| 4 | 63 | `TptTrip::whereBetween('trip_date', [$fromDate, $toDate])->count()` | Counts ALL trips in date range regardless of status — includes Scheduled, Completed, Cancelled, Ongoing. Label says "Today's Trips" but actually uses the full from-to range |
| 5 | 66-68 | `TptStudentAllocationJnt::where('active_status',1)->where('effective_from','<=',$toDate)->count()` | Active allocations where effective_from is on or before the range end date. Does NOT check `effective_to` — an allocation that expired before the range start would still be counted if `effective_from` is old enough. **GAP:** No `effective_to` check — could count expired allocations |
| 6 | 70-75 | Return array | Returns 4 integers. Key naming mismatch: `activeVehicles` (correct), `activeDrivers` (misleading), `todaysTrips` (misleading — actually date-range scoped), `transportStudents` (correct) |

#### DEEP-02: `getTripChartData()` — Lines 78-136

| Step | Line(s) | Code | Analysis |
|------|---------|------|----------|
| 1 | 80-81 | `Carbon::parse($fromDate)`, `Carbon::parse($toDate)` | Same parsing risk as DEEP-01 |
| 2 | 83-87 | Initialize arrays | `$labels`, `$completed`, `$scheduled`, `$cancelled`, `$ongoing` |
| 3 | 89 | `$currentDate = $startDate->copy()` | Start from beginning of range |
| 4 | 91 | `while ($currentDate <= $endDate)` | Iterates day-by-day. If date range is 3 months (92 days), runs 92 iterations × 4 queries = **368 queries**. **GAP:** N+1 query problem — one query per status per day instead of grouping by date |
| 5 | 93-94 | Format date for label and query | Labels: `d M` (e.g., "01 Jan"). Queries use `$date` (Y-m-d) |
| 6 | 96-110 | 4 queries per day: `whereDate('trip_date', $date)->where('status', 'X')->count()` | Each is a separate COUNT query. For 30-day range = 120 queries. **GAP:** Could be optimized to 1 query with GROUP BY date + status |
| 7 | 112 | `$currentDate->addDay()` | Advance one day |
| 8 | 115-135 | Return structured array with 4 datasets | Chart-ready format for Chart.js. Dataset order: Scheduled, Completed, Cancelled, Ongoing |

#### DEEP-03: `getVehicleStatus()` — Lines 138-173

| Step | Line(s) | Code | Analysis |
|------|---------|------|----------|
| 1 | 140-141 | Carbon parse | Standard date parsing |
| 2 | 143 | `Vehicle::count()` | Total vehicles INCLUDING inactive and soft-deleted (if not using SoftDeletes). **GAP:** Does NOT use `active()` scope unlike `getKpiData()` line 59 |
| 3 | 144 | `Vehicle::where('is_active','1')->count()` | `is_active` compared as string '1', not boolean true. Works in MySQL but technically type mismatch |
| 4 | 145 | `$this->getOnRouteVehiclesCount($startDate, $endDate)` | See DEEP-04 |
| 5 | 148-154 | Maintenance vehicles: `whereHas('serviceRequests', subquery)` | Nested whereHas → whereHas. Three levels deep. Performance concern on large datasets. Uses `whereBetween('out_service_date', [$startDate, $endDate])` which correctly respects date range |
| 6 | 156-161 | Out of service: `is_active=0 OR (is_active=1 AND availability_status=0)` | Correct logic. But note: `outOfService` count may overlap with `maintenanceVehicles` count — a vehicle could be both in maintenance AND out of service. **GAP:** Sets are not mutually exclusive → progress bar percentages could exceed 100% |
| 7 | 163 | `$availableCount = $availableVehicles - $onRouteVehicles - $maintenanceVehicles` | Subtraction formula. If total active vehicles = 5, onRoute = 3, maintenance = 2, available = 0. But if onRoute + maintenance > available, available could go negative → `max(0, available)` fixes this |
| 8 | 165-172 | Return array with 6 keys + utilizationRate | `utilizationRate` computed from `onRoute / total`, not from `onRoute / activeVehicles`. **GAP:** Using total (includes inactive) as denominator underestimates utilization |

#### DEEP-04: `getOnRouteVehiclesCount()` — Lines 175-183

| Step | Line(s) | Code | Analysis |
|------|---------|------|----------|
| 1 | 177-178 | Carbon parse | Standard |
| 2 | 179-182 | `TptTrip::whereBetween('trip_date', [$startDate, $endDate])->whereIn('status', ['Ongoing', 'Scheduled'])->distinct('vehicle_id')->count('vehicle_id')` | Returns count of UNIQUE vehicles that have at least one Ongoing or Scheduled trip in the date range. **GAP:** If a vehicle has 5 Ongoing trips in the range, it counts as 1 (correct for distinct). However, a vehicle could be both in a Completed trip and an Ongoing trip on the same day — it would still be counted as onRoute (correct behavior). |
| 3 | — | Method name says "OnRouteVehiclesCount" | **GAP:** Checks Scheduled trips too, not just currently-on-route. A vehicle with only Scheduled future trips appears as "on route" |

#### DEEP-05: `getActiveRoutes()` — Lines 185-214

| Step | Line(s) | Code | Analysis |
|------|---------|------|----------|
| 1 | 187-188 | Carbon parse | Standard |
| 2 | 189 | `DriverRouteVehicleJnt::with(['route', 'vehicle', 'driver'])` | Eager loads relationships. Without this, N+1 on each of the 10 rows. Correctly implemented |
| 3 | 190-199 | Date range filter: `whereBetween('effective_from', [dates]) OR (effective_from <= start AND (effective_to IS NULL OR effective_to >= end))` | Complex date logic: assignments that STARTED within range OR were ACTIVE throughout the range. Correct logic |
| 4 | 200 | `->where('is_active', 1)` | Only active assignments |
| 5 | 201 | `->orderBy('created_at', 'desc')` | Most recently created first |
| 6 | 202 | `->limit(10)` | Hard limit. **GAP:** No pagination — if more than 10, extra records invisible on dashboard |
| 7 | 203 | `->get()` | Execute query |
| 8 | 204-212 | `->map(...)` | Shape response with null-safe `?? 'N/A'` operators. Route name, shift name, vehicle reg no, driver name, total_students |
| 9 | 213 | `->toArray()` | Convert collection to array |

#### DEEP-06: `getMaintenanceAlerts()` — Lines 216-275

| Step | Line(s) | Code | Analysis |
|------|---------|------|----------|
| 1 | 218-219 | Carbon parse | Standard |
| 2 | 220 | `$alerts = []` | Initialize empty array |
| 3 | 223-234 | Fitness alerts: `Vehicle::get()` → map | **GAP-CR14:** `whereBetween('fitness_valid_upto', ...)` is COMMENTED OUT at line 223-224. Loads ALL vehicles. No date filter |
| 4 | 224 | Comment: `// ->whereBetween('fitness_valid_upto', [$startDate, $endDate])` | The intended date filter exists as commented-out code. Either incomplete refactoring or deliberate choice to show all vehicles |
| 5 | 226-233 | Map function computes status: `<= now()` → "overdue", `<= now()->addDays(7)` → "due_soon", else "upcoming" | Status computed relative to `now()`, NOT relative to the date range selected. **GAP:** The date range picker has NO effect on alert status computation |
| 6 | 231 | Null-safe `$vehicle->fitness_valid_upto?->format(...)` | Uses PHP 8 null-safe operator. If `fitness_valid_upto` is null, `due_date` = 'N/A' and status comparison on line 231-232 may return unexpected result since null <= now() is... actually Carbon won't call `<=` on null because `?->` short-circuits. **Edge case**: `$vehicle->fitness_valid_upto` is null → status line `$vehicle->fitness_valid_upto <= now()` is never reached → status is 'upcoming'. **GAP:** Null fitness dates show "Upcoming" status which is misleading |
| 7 | 239-250 | Insurance alerts: Same pattern | Same GAP: commented-out date filter at line 240 |
| 8 | 255-271 | Maintenance alerts: `TptVehicleMaintenance::with('serviceRequest.inspection.vehicle')` | Chains 4 levels deep. Performance concern |
| 9 | 256 | Comment: `// ->whereBetween('created_at', [$startDate, $endDate])` | **GAP-CR21:** Same pattern — date filter commented out |
| 10 | 257-261 | Status filter: `->where('status', 'Pending')->orWhere(function(...))` | **GAP:** The `orWhere` at line 258 is NOT wrapped with the parent `where`. Due to SQL operator precedence, this could return records where `status = 'Approved' AND out_service_date IS NULL` regardless of the Pending filter. The intended logic should be: `where(function($q) { $q->where('status','Pending')->orWhere(...) })` |
| 11 | 263 | `->limit(5)` | Maintenance alerts limited to 5 before merge |
| 12 | 274 | `array_slice(array_merge($alerts, $maintenanceAlerts->toArray()), 0, 10)` | Merges fitness + insurance (unlimited, all vehicles) + maintenance (max 5) and returns top 10. **GAP:** If there are 20 vehicles, fitness + insurance = 40 alerts, plus 5 maintenance = 45 → only 10 returned. The `array_slice` silently truncates |

#### DEEP-07: `getAdditionalMetrics()` — Lines 277-340

| Step | Line(s) | Code | Analysis |
|------|---------|------|----------|
| 1 | 279-280 | Carbon parse | Standard (but `$startDate`/`$endDate` parsed then **NEVER USED** for fuel/attendance/incidents). **GAP:** Fuel, attendance, and incident queries all ignore the date range parameter |
| 2 | 283-287 | Fuel current month: `whereMonth('date', $currentMonth)->where('status', 'Approved')->select(SUM(quantity), SUM(cost))` | Uses `now()->month` (line 283), NOT `$fromDate`. **GAP:** Date range picker doesn't affect fuel data |
| 3 | 290-294 | Fuel previous month: same but `$prevMonth = $currentMonth - 1` | Month subtraction: if current month is January (1), prevMonth = 0 → `whereMonth('date', 0)` returns no results. **GAP:** January comparison returns 0 previous data because month 0 doesn't exist |
| 4 | 296-297 | Fuel change: `prev > 0 ? round((curr - prev) / prev * 100, 1) : 0` | Division by zero guard at line 296 |
| 5 | 300-305 | Driver attendance today: `whereDate('attendance_date', today())` | Uses `today()` NOT `$fromDate`/`$toDate`. **GAP:** Date range picker doesn't affect driver attendance |
| 6 | 307-308 | Attendance rate: `total > 0 ? round((present / total) * 100) : 0` | Division by zero guard. However, line 307 reads `$todayAttendance->total > 0` — if `$todayAttendance` is null (no records at all), this `->total` access would fail with "Call to a member function on null". **GAP:** No null check on `$todayAttendance` before accessing `->total` |
| 7 | 310-319 | Incidents current month: `whereBetween('created_at', [now()->startOfMonth(), now()->endOfMonth()])` | Uses `now()` NOT `$fromDate`/`$toDate`. **GAP:** Date range picker doesn't affect incident data |
| 8 | 321-339 | Return structured array | 3 sub-objects: fuel, attendance, incidents |

#### DEEP-08: `getRecentTrips()` — Lines 342-365

| Step | Line(s) | Code | Analysis |
|------|---------|------|----------|
| 1 | 344-346 | `TptTrip::orderBy('trip_date', 'desc')->orderBy('start_time', 'desc')->limit(10)->get()` | Most recent 10 trips. No date range filter — always returns latest 10 regardless of selected range. **GAP:** Date range picker does not affect recent trips |
| 2 | 349-351 | Duration: `if ($trip->start_time && $trip->end_time && $trip->start_time instanceof Carbon && $trip->end_time instanceof Carbon)` | Checks both truthiness AND type. If times are strings (not cast to Carbon), duration = null. Heavy type-checking may indicate inconsistent DB casting |
| 3 | 355 | Trip ID: `'TRP-' . str_pad((string) $trip->id, 5, '0', STR_PAD_LEFT)` | Pads with leading zeroes. ID 1 → "TRP-00001", ID 12345 → "TRP-12345" |
| 4 | 357 | `$trip->routeScheduler->route->name ?? 'N/A'` | Chains through 2 relationships (routeScheduler → route). If any is null, shows 'N/A' |
| 5 | 358 | `$trip->routeScheduler->vehicle->registration_no ?? 'N/A'` | Same 2-level chain for vehicle |
| 6 | 359 | `$trip->routeScheduler->driver->name ?? 'N/A'` | Same 2-level chain for driver |
| 7 | 360 | `'status' => $trip->status` | Returns raw DB status (likely "Completed", "Scheduled", etc. — PascalCase). **GAP:** Blade JS (line 626-628) matches against lowercase ("completed", "in_progress", "cancelled"). Case mismatch → all status badges fall to `bg-secondary` default |
| 8 | 362 | `->toArray()` | Final conversion |

#### DEEP-09: `index()` Response Assembly — Lines 28-51

| Step | Line(s) | Code | Analysis |
|------|---------|------|----------|
| 1 | 30 | `Gate::authorize('tenant.transport-dashboard.viewAny')` | Authorization first — correct pattern |
| 2 | 32-33 | Date range defaults | `$request->get('from_date', now()->startOfMonth()->format('Y-m-d'))` — if not provided, uses current month start |
| 3 | 35-48 | Assemble $data array | Calls 8 private methods + dateRange display string |
| 4 | 43-47 | Date range display: `Carbon::parse($fromDate)->format('M j') . ' - ' . Carbon::parse($toDate)->format('M j, Y')` | Formatted string. Example: "Jan 1 - Jan 31, 2026" |
| 5 | 50 | `return response()->json($data)` | JSON response — not a view. This is a pure API endpoint |

### 5.8 Code Trace Matrix (CODE-TRACE)

| CTR ID | Method | Lines | Access | Called By | Query Count | Gaps Found |
|--------|--------|-------|--------|-----------|-------------|------------|
| CTR-01 | `index()` | 28-51 | public | Route `GET /dashboard/data` | 0 (assembles responses) | No date validation |
| CTR-02 | `getKpiData()` | 53-76 | private | `index()` line 36 | 4 queries | No effective_to check; DriverHelper counts all roles |
| CTR-03 | `getTripChartData()` | 78-136 | private | `index()` line 37 | 4 × N days — N=30→120 queries | Massive N+1 per day per status |
| CTR-04 | `getVehicleStatus()` | 138-173 | private | `index()` line 38 | 4-5 queries | Non-mutually-exclusive sets; uses total not active for denominator |
| CTR-05 | `getOnRouteVehiclesCount()` | 175-183 | private | `getVehicleStatus()` line 145 | 1 query | Name mismatch (includes Scheduled) |
| CTR-06 | `getActiveRoutes()` | 185-214 | private | `index()` line 39 | 1 query + eager loads | Hard limit 10, no pagination |
| CTR-07 | `getMaintenanceAlerts()` | 216-275 | private | `index()` line 40 | 3 queries | 3 commented-out date filters; orWhere not grouped; all vehicles loaded |
| CTR-08 | `getAdditionalMetrics()` | 277-340 | private | `index()` line 41 | 4 queries | Ignores date range; January fuel bug; null attendance |
| CTR-09 | `getRecentTrips()` | 342-365 | private | `index()` line 42 | 1 query | No date range filter; JS status case mismatch |

---

## 6. Test Case List

### 6.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | Dashboard Tab Loads Inside Transport Master | `/transport/transport-master` loads Dashboard tab as first/active tab with KPI cards, chart placeholders, tables with loading spinners | — | — | ⬜ |
| TC-P02 | AJAX Data Loads on Tab Click | Clicking Dashboard tab triggers `loadDashboardData()` → data populated in all sections | — | — | ⬜ |
| TC-P03 | AJAX Data Loads on Initial Page Load | When Dashboard is active tab on page load, `loadDashboardData()` fires immediately | — | — | ⬜ |
| TC-P04 | KPI Cards Display Correct Values | Active Vehicles, Active Drivers, Today's Trips, Transport Students show correct counts matching DB | — | — | ⬜ |
| TC-P05 | Trip Completion Chart Renders | Chart.js line chart with 4 datasets renders correctly with labels as dates | — | — | ⬜ |
| TC-P06 | Vehicle Status Breakdown Displays | Total, On Route, Available, Maintenance, Out of Service values shown with utilization rate | — | — | ⬜ |
| TC-P07 | Active Routes Table Populated | Top 10 active routes with Route, Shift, Vehicle, Driver, Students columns populated | — | — | ⬜ |
| TC-P08 | Maintenance Alerts Table Populated | Fitness, Insurance, Maintenance alerts shown with vehicle, type, due date, status badge | — | — | ⬜ |
| TC-P09 | Fuel Consumption Metric Displayed | Current month fuel consumption (L), total cost (₹), month-over-month change % | — | — | ⬜ |
| TC-P10 | Driver Attendance Metric Displayed | Today's attendance %, present/total counts, absent count | — | — | ⬜ |
| TC-P11 | Incident Reports Metric Displayed | Total incidents, resolved count, severity badges (High/Medium/Low) | — | — | ⬜ |
| TC-P12 | Recent Trips Table Populated | Top 10 recent trips with Trip ID, Date/Time, Route, Vehicle, Driver, Status, Duration | — | — | ⬜ |
| TC-P13 | Date Range Filter Changes Data | Changing date range in daterangepicker → reloads dashboard data for new range | — | — | ⬜ |
| TC-P14 | Active Routes with Null Relationships Gracefully Displayed | Route/vehicle/driver with null FK shows "N/A" instead of error | — | — | ⬜ |
| TC-P15 | Trip Duration Calculated Correctly | Trips with start_time and end_time show formatted duration "2h 30m" | — | — | ⬜ |
| TC-P16 | Trip Date Range Label Updated | `$('#tripDateRange')` text updated with new date range on AJAX success | — | — | ⬜ |
| TC-P17 | Vehicle Status Progress Bar Renders | Colored progress bar segments for available/maintenance/outOfService | — | — | ⬜ |
| TC-P18 | Chart Destroys and Recreates on Reload | Previous Chart.js instance destroyed before new one created | — | — | ⬜ |
| TC-P19 | Utilization Rate Updates on Data Change | Utilization rate recalculates correctly when date range changes | — | — | ⬜ |
| TC-P20 | Full Dashboard Load Sequence | Page load → spinners shown → AJAX success → all sections populated → chart rendered | — | — | ⬜ |

### 6.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | No Data — Dashboard Empty State | All KPI cards show 0; chart shows flat line at 0; all tables show "No..." messages | — | — | ⬜ |
| TC-N02 | AJAX Endpoint Error (500) | `showError()` called; user sees alert "Failed to load dashboard data" | — | — | ⬜ |
| TC-N03 | Invalid Date Range Parameters | Passing non-date string as from_date/to_date → Carbon parse may fail with exception; no validation in controller | — | — | ⬜ |
| TC-N04 | Permission 403 — No Dashboard Permission | User without `tenant.transport-dashboard.viewAny` → Dashboard tab is hidden (no @can) | — | — | ⬜ |
| TC-N05 | Direct AJAX Endpoint Access Without Permission | GET `/transport/dashboard/data` with no permission → 403 Forbidden | — | — | ⬜ |
| TC-N06 | Guest Access to Dashboard Tab | `/transport/transport-master` redirects to `/login` for unauthenticated users | — | — | ⬜ |
| TC-N07 | Zero Vehicles in System | vehicleStatus: total=0, onRoute=0, available=0, maintenance=0, outOfService=0, utilizationRate=0 | — | — | ⬜ |
| TC-N08 | Zero Drivers in System | KPI shows activeDrivers=0; attendance shows 0% with 0/0 | — | — | ⬜ |
| TC-N09 | Zero Trips in Date Range | KPI todaysTrips=0; chart datasets all zeros; recentTrips empty; onRoute=0 | — | — | ⬜ |
| TC-N10 | Fitness/Insurance Date Null | Vehicle with null fitness_valid_upto → map uses `?? 'N/A'` for due_date; status comparison may fail | — | — | ⬜ |
| TC-N11 | AJAX During Loading Shows Spinner | Tables show spinner-border HTML before AJAX success callback | — | — | ⬜ |
| TC-N12 | Chart Canvas Not Found | If `#tripChart` element missing → console.error "Trip chart canvas not found" — no crash | — | — | ⬜ |
| TC-N13 | Trip Duration with Null Times | Trip with null start_time or end_time → duration = null → shows '-' in table | — | — | ⬜ |
| TC-N14 | Active Routes with Zero Assignments | No DriverRouteVehicleJnt records → activeRoutes array empty → table shows "No active routes" | — | — | ⬜ |
| TC-N15 | Maintenance Alerts returns 0 results | No fitness/insurance/maintenance alerts → alerts array empty → table shows "No alerts" | — | — | ⬜ |
| TC-N16 | Permission 403 — No Transport Permissions at All | User without ANY transport permission hits `/transport/transport-master` → 403 from `Gate::any()` in `TransportMasterController@index()` before any tab renders | — | — | ⬜ |
| TC-N17 | Permission 403 — AJAX Endpoint Direct Hit Without Permission | Direct `GET /transport/dashboard/data` (no session/no permission) → `Gate::authorize('tenant.transport-dashboard.viewAny')` returns 403 Forbidden; no data leaked | — | — | ⬜ |
| TC-N18 | Permission 403 — Expired Session | Expired/non-existent session → `/transport/transport-master` redirects to login; `/transport/dashboard/data` returns 401/419 (CSRF) or redirects to login | — | — | ⬜ |
| TC-N19 | Permission — Gate::any() Partial Denial | User with `tenant.transport-dashboard.viewAny` but NO other transport permissions → Dashboard tab renders but all other tabs hidden (nav-tab `permission` keys + `@can` guards). Neither tab nav items nor bodies render for unauthorized tabs | — | — | ⬜ |
| TC-N20 | Activity Log — Dashboard Load Does NOT Create activity_log Entries | Load dashboard tab / call AJAX endpoint → verify `activity_log` table has NO new rows attributed to dashboard endpoint (confirmed read-only) | — | — | ⬜ |

### 6.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|----------------|---------|---------|--------|
| TC-D01 | A | KPI activeVehicles Count Mirrors Vehicle::active() | Creating/deleting active vehicles reflects in dashboard KPI on next load | — | — | ⬜ |
| TC-D02 | A | KPI todaysTrips Mirrors Trip Count in Date Range | Creating trips between from/to date updates trip count | — | — | ⬜ |
| TC-D03 | B | Vehicle Deletion Cascades to Fuel/Maintenance Counts | DDL CASCADE on tpt_vehicle→tpt_vehicle_fuel and tpt_vehicle→tpt_vehicle_maintenance → fuel consumption and maintenance alerts change | — | — | ⬜ |
| TC-D04 | C | DriverAttendance Data Affects Attendance Metric | Creating today's driver attendance changes attendance rate | — | — | ⬜ |
| TC-D05 | D | Trip Status Change Affects Chart Data | Changing trip.status from Scheduled→Completed updates chart daily breakdown | — | — | ⬜ |
| TC-D06 | E | Active Routes Query Filters Expired Assignments | DriverRouteVehicleJnt with effective_to < fromDate is excluded from active routes | — | — | ⬜ |
| TC-D07 | F | Fuel Data Accuracy — Month Boundary | Fuel entries for current vs previous month correctly separated | — | — | ⬜ |
| TC-D08 | G | Rapid Date Range Changes | Rapid daterangepicker changes → multiple AJAX calls → last call data displayed; no stale data | — | — | ⬜ |

### 6.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|-----------------|---------|---------|--------|
| TC-CR01 | CR | P1 | Controller — Gate::authorize() at Method Start | `TransportDashboardController@index()` line 30: `Gate::authorize('tenant.transport-dashboard.viewAny')` is first executable statement | — | — | ◌ |
| TC-CR02 | CR | P1 | Controller — No FormRequest, Raw Request Used | `index(Request $request)` uses `$request->get()` directly — no validation rules for date format | — | — | ◌ |
| TC-CR03 | CR | P1 | Controller — Date Range Defaults | `$fromDate = $request->get('from_date', now()->startOfMonth()->format('Y-m-d'))` and `$toDate = $request->get('to_date', now()->endOfMonth()->format('Y-m-d'))` | — | — | ◌ |
| TC-CR04 | CR | P1 | Controller — JSON Response Only | Method returns `response()->json($data)` — never returns a view | — | — | ◌ |
| TC-CR05 | CR | P1 | Controller — No Activity Logging (Read-only Verification) | Dashboard index() is read-only (only SELECT queries, no INSERT/UPDATE/DELETE); no activityLog() calls exist. Confirms analytics endpoint writes NOTHING to `activity_log` table on data load | — | — | ◌ |
| TC-CR06 | CR | P1 | View — Blade `@can` Directive | `transportmaster.blade.php` line 23: `@can('tenant.transport-dashboard.viewAny')` wraps `@include('transport::dashboard.index')` | — | — | ◌ |
| TC-CR07 | CR | P1 | View — Tab Definition in nav-tab | `transportmaster.blade.php` line 7: `['id' => 'transport_dashboard', 'label' => 'Dashboard', 'icon' => 'fa-solid fa-gauge-high', 'permission' => 'tenant.transport-dashboard.viewAny']` — first tab, default | — | — | ◌ |
| TC-CR08 | CR | P1 | View — Dashboard Index JS Uses ES5+ | `dashboard/index.blade.php` uses `let`, `const`, arrow functions, template literals — requires modern browser | — | — | ◌ |
| TC-CR09 | CR | P1 | View — AJAX URL Via Named Route | `const apiBaseUrl = "{{ route('transport.dashboard.data') }}"` — correct named route resolution | — | — | ◌ |
| TC-CR10 | CR | P1 | View — Daterangepicker External Dependency | Uses `cdn.jsdelivr.net/npm/daterangepicker` — requires CDN availability | — | — | ◌ |
| TC-CR11 | CR | P1 | View — Chart.js External Dependency | Uses `cdn.jsdelivr.net/npm/chart.js` — requires CDN availability | — | — | ◌ |
| TC-CR12 | CR | P1 | Route — Named Route Defined | `web.php` line 40: `Route::get('dashboard/data', [TransportDashboardController::class, 'index'])->name('dashboard.data');` | — | — | ◌ |
| TC-CR13 | CR | P1 | Policy — TransportDashboardPolicy Defined | 7 gates: viewAny, view, create, update, delete, restore, forceDelete — but only viewAny used | — | — | ◌ |
| TC-CR14 | CR | P1 | GAP — Fitness/Insurance Queries Have Commented-Out Date Filter | `TransportDashboardController.php:223-224, 240`: `// ->whereBetween('fitness_valid_upto', [$startDate, $endDate])` — queries load ALL vehicles without date filtering. All vehicles always appear regardless of date range | — | — | ◌ |
| TC-CR15 | CR | P1 | GAP — `$todayAttendance->present` and `$todayAttendance->total` May Be Null | `TransportDashboardController.php:329-330`: `$todayAttendance->present ?? 0` — null coalescing guards present; but line 307-308 does `$todayAttendance->total > 0` which could fail if total is null | — | — | ◌ |
| TC-CR16 | CR | P1 | GAP — Active Routes: No Pagination, Hard Limit 10 | `TransportDashboardController.php:202`: hard-coded `->limit(10)` — if more than 10 active assignments exist, only 10 shown; no pagination on dashboard | — | — | ◌ |
| TC-CR17 | CR | P1 | GAP — No Input Validation for Date Parameters | Controller accepts any string as `from_date`/`to_date`; if non-date string passed, `Carbon::parse()` throws exception → 500 error. No try-catch or date format validation | — | — | ◌ |
| TC-CR18 | CR | P1 | GAP — `getOnRouteVehiclesCount` Counts All Trips In Date Range, Not Just Today | Method name says `getOnRouteVehiclesCount` but it counts ALL trips in date range with status Ongoing/Scheduled, not just current on-route vehicles | — | — | ◌ |
| TC-CR19 | CR | P1 | GAP — `activeDrivers` Counts All Personnel Not Just Drivers | `DriverHelper::count()` counts ALL personnel (Drivers + Helpers + Transport Managers) — label says "Active Drivers" which is misleading | — | — | ◌ |
| TC-CR20 | CR | P1 | Route — No `/transport-master` resource cleanup | `Route::resource('transport-master', TransportMasterController::class)` — creates ALL resource routes (create, store, show, edit, update, destroy) but only index() is implemented | — | — | ◌ |
| TC-CR21 | CR | P1 | GAP — Maintenance Query Also Has Commented-Out Date Filter | `TransportDashboardController.php:256`: `// ->whereBetween('created_at', [$startDate, $endDate])` — same pattern as fitness/insurance filters. Maintenance alerts list ALL pending/approved records regardless of date range, not filtered by `created_at` | — | — | ◌ |
| TC-CR22 | CR | P1 | GAP — Hub View Missing `:active` Parameter on nav-tab | `transportmaster.blade.php` line 18: `x-backend.tab.nav-tab` component called without `:active="request('tab', 'transport_dashboard')"`. First tab show relies on hardcoded `active show` in `dashboard/index.blade.php` line 1 instead of component-driven active state | — | — | ◌ |
| TC-CR23 | CR | P1 | GAP — orWhere Not Grouped in Maintenance Query | `TransportDashboardController.php:257-261`: `->where('status', 'Pending')->orWhere(...)` — the `orWhere` at line 258 lacks parent grouping. SQL interpretation: `WHERE status = 'Pending' OR (status = 'Approved' AND out_service_date IS NULL)` which returns ALL Pending records plus Approved-without-date records. The intended logic likely required parenthesized grouping | — | — | ◌ |
| TC-CR24 | CR | P1 | GAP — Trip Status Case Mismatch (PHP vs JS) | Controller returns raw DB status (e.g., "Completed", "Scheduled" — PascalCase). Blade JS `updateRecentTrips()` (line 626-628) matches against lowercase: `trip.status === 'completed'`, `'in_progress'`, `'cancelled'`. **Result:** ALL trip status badges render as `bg-secondary` (default) because the string comparison never matches. Status badges show raw DB value but with wrong color | — | — | ◌ |
| TC-CR25 | CR | P1 | GAP — Policy Has Dead Code Methods | `TransportDashboardPolicy.php`: `view()`, `create()`, `update()`, `delete()`, `restore()`, `forceDelete()` methods defined with `Vehicle $vehicle` parameter but dashboard has no Vehicle-specific CRUD. These are never called. Dead code that could confuse developers | — | — | ◌ |
| TC-CR26 | CR | P1 | GAP — permissionslist.php Defines Full $crud for transport-dashboard But Only viewAny Is Used | `config/permissionslist.php:291`: `'transport-dashboard' => $crud` — all 17 actions (create, view, viewAny, update, delete, restore, forceDelete, import, export, print, publish, status, email-schedule, remark, pdf, edit, approve) are defined but controller only uses `viewAny`. The other 16 permissions are registered in the system but never referenced | — | — | ◌ |
| TC-CR27 | CR | P1 | GAP — AdditionalMetrics Ignores Date Range Parameter | Despite `getAdditionalMetrics()` receiving `$fromDate`/`$toDate` (lines 279-280), fuel uses `now()->month` (line 283), attendance uses `today()` (line 300), incidents use `now()->startOfMonth()` (line 311). **The date range picker has NO effect on these 3 metrics** | — | — | ◌ |
| TC-CR28 | CR | P1 | GAP — January Fuel Comparison Bug | `TransportDashboardController.php:290`: `$prevMonth = $currentMonth - 1` — if current month is January (1), prevMonth = 0. `whereMonth('date', 0)` returns no results because MySQL months are 1-12. **Result:** In January, fuel change % is always 0 because previous month data is never found | — | — | ◌ |
| TC-CR29 | CR | P1 | GAP — Recent Trips Ignores Date Range | `getRecentTrips()` (line 342-365) has no date filter and no parameters. Always returns the 10 most recent trips regardless of the selected date range in the dashboard | — | — | ◌ |
| TC-CR30 | CR | P1 | GAP — Vehicle Status Uses Total (Not Active) for Utilization Denominator | `TransportDashboardController.php:171`: `$onRouteVehicles / $totalVehicles` where `$totalVehicles = Vehicle::count()` (line 143, ALL vehicles including inactive). If 5 active + 3 inactive = 8 total vehicles, 3 onRoute → utilization = 37% (not 60%). **Underestimates utilization rate** | — | — | ◌ |
| TC-CR31 | CR | P1 | GAP — Vehicle Status Categories May Overlap | A vehicle in maintenance (whereHas serviceRequest Approved) may ALSO have `is_active=0` or `availability_status=0`, meaning it appears in BOTH `maintenanceVehicles` AND `outOfService` counts. This causes progress bar widths to exceed 100% when summed (lines 519-521) | — | — | ◌ |
| TC-CR32 | CR | P1 | GAP — Trip Chart N+1 Query Pattern | `getTripChartData()` executes 4 COUNT queries per day in the date range. For a 30-day range: 120 separate SQL queries. For a 3-month range (~90 days): 360 queries. No caching or aggregation optimization | — | — | ◌ |
| TC-CR33 | CR | P1 | GAP — Null DriverAttendance Causes Error | `TransportDashboardController.php:307`: `$todayAttendance->total > 0` — if no attendance records exist for today, `$todayAttendance` is null → `Call to a member function total on null` error. Line 329-330 uses `?? 0` which only works if `$todayAttendance` is not null (it guards the property, not the object) | — | — | ◌ |
| TC-CR34 | CR | P1 | GAP — transport Permission Group Defined But Unused | `config/permissionslist.php:289`: `'transport' => $crud` creates permission strings like `tenant.transport.viewAny`, `tenant.transport.create`, etc. But `Gate::any()` in `TransportMasterController@index()` uses `tenant.transport.viewAny` (line 29). No controller uses `tenant.transport.create/update/delete`. This permission group is only partially used | — | — | ◌ |
| TC-CR35 | CR | P1 | GAP — Maintenance Alert Status "Upcoming" for Null Dates | `TransportDashboardController.php:231-232`: When `fitness_valid_upto` is null, `$vehicle->fitness_valid_upto?->format(...)` returns 'N/A' and the `<= now()` comparison is skipped, falling through to 'upcoming' status. A vehicle with NO fitness certificate shows as "Upcoming" rather than "Missing" or "N/A" — misleading | — | — | ◌ |
| TC-CR36 | CR | P1 | GAP — Maintenance Alerts Limited to 10 Without Warning | `TransportDashboardController.php:274`: `array_slice(array_merge(...), 0, 10)` — with 20+ vehicles generating 40+ fitness+insurance alerts plus 5 maintenance, only 10 are shown. No "View All" link or indicator that data is truncated | — | — | ◌ |
| TC-CR37 | CR | P1 | GAP — DriverAttendance Query Has No Year Restriction | `TptDriverAttendance` line 300: `whereDate('attendance_date', today())` — today's date includes year-month-day. However the `today()` call returns current date at midnight — no year boundary issue, but if `attendance_date` stores timestamps, the `whereDate` comparison may have timezone issues if app and DB use different timezones | — | — | ◌ |
| TC-CR38 | CR | P2 | View — Hardcoded `active show` on Tab Pane | `dashboard/index.blade.php` line 1: `class="tab-pane fade p-4 active show"` — hardcoded active state means dashboard is ALWAYS the first visible tab on page load, regardless of URL tab parameter. If user navigates to `?tab=vehicle`, both dashboard AND vehicle panes would have `active show` | — | — | ◌ |
| TC-CR39 | CR | P2 | GAP — JS Fuel Comparison Arrow Logic | `dashboard/index.blade.php` line 213: `Compared to last month: <span class="text-success">↓ 0%</span>` — hardcoded `text-success` and `↓` down arrow regardless of actual change direction. If consumption increases (worse), it still shows green down arrow (positive). Should dynamically flip arrow/color based on increase vs decrease | — | — | ◌ |
| TC-CR40 | CR | P2 | GAP — JS Attendance Absent Calculation | `dashboard/index.blade.php` line 609: `const absent = metrics.attendance.total - metrics.attendance.present` — computed client-side from server data. If server sends present=3, total=3 → absent=0 (correct). But if total < present (data inconsistency), absent goes negative: shows "Absent: -1 drivers" | — | — | ◌ |
| TC-CR41 | CR | P2 | GAP — No CSRF Token on AJAX Endpoint | `dashboard/index.blade.php` line 448-455: jQuery AJAX call sends `from_date` and `to_date` only — no `_token` or CSRF header. Since endpoint uses GET method (not POST/PUT/DELETE), CSRF protection typically not enforced on GET. But if middleware changes, this could break | — | — | ◌ |
| TC-CR42 | CR | P1 | GAP — getKpiData activeDrivers Has No Active Scope | `TransportDashboardController.php:60`: `DriverHelper::count()` — counts ALL records including inactive/soft-deleted depending on SoftDeletes trait. Unlike `Vehicle::active()->count()` which uses `scopeActive()` for `is_active=1`, drivers have NO active filter. Inactive personnel appear as "Active Drivers" | — | — | ◌ |

---

## 8. Blade/JS Code Trace & Analysis

### 8.1 File Overview

The dashboard Blade view at `dashboard/index.blade.php` (752 lines) is a self-contained single-file component containing:
- HTML markup for all dashboard sections (lines 1-306)
- Inline CSS styles (lines 308-365)
- CDN script includes (lines 366-368)
- Inline JavaScript with all dashboard logic (lines 370-752)

### 8.2 HTML Structure Trace

| Line Range | Element | ID | Description |
|-----------|---------|-----|-------------|
| 1 | `<div class="tab-pane ...">` | `transport_dashboard-pane` | Main dashboard container — hardcoded `active show` (GAP-CR22) |
| 5-7 | `<h5>`, `<p>` | — | Dashboard title and subtitle |
| 12-20 | Date range picker group | `transport_daterange`, `transport_from_date` (hidden), `transport_to_date` (hidden) | Input group with calendar icon |
| 24-37 | KPI Card | `#totalActiveVehicles` | First KPI: Active Vehicles (blue/primary) |
| 38-52 | KPI Card | `#totalActiveDrivers` | Second KPI: Active Drivers (green/success) |
| 55-70 | KPI Card | `#totalTodaysTrips` | Third KPI: Today's Trips (yellow/warning) |
| 71-84 | KPI Card | `#totalTransportStudents` | Fourth KPI: Transport Students (red/danger) |
| 90-103 | Chart Card | `#tripChart` (canvas) | Trip Completion Status — Chart.js line chart |
| 96 | Date range label | `#tripDateRange` | Shows "Weekly trip performance overview" default, updated via AJAX |
| 105-119 | Vehicle Status Card | `#vehicleStatusSection` | Replaced entirely by JS with progress bar + stats |
| 125-156 | Active Routes Table | `#activeRoutesBody` | 5-column table (Route, Shift, Vehicle, Driver, Students) |
| 157-190 | Maintenance Alerts Table | `#maintenanceAlertsBody` | 4-column table (Vehicle, Alert Type, Due Date, Status) |
| 194-216 | Fuel Consumption Card | `#totalFuelConsumption`, `#fuelCost`, `#fuelComparison` | Monthly fuel, cost, trend |
| 219-241 | Driver Attendance Card | `#attendanceRate`, `#presentDrivers`, `#absentDrivers` | Today's attendance |
| 242-266 | Incident Reports Card | `#totalIncidents`, `#resolvedIncidents`, `#incidentBadges` | Monthly incidents with severity badges |
| 271-305 | Recent Trip Logs Table | `#recentTripsBody` | 7-column table (Trip ID, Date/Time, Route, Vehicle, Driver, Status, Duration) |

### 8.3 CSS Trace

| Line Range | Selector | Purpose |
|-----------|----------|---------|
| 309-316 | `.small-box` | KPI card container: border-radius, shadow, overflow hidden |
| 318-333 | `.small-box > .inner`, `h3`, `p` | KPI text styling: 2.2rem bold numbers, 0.9rem labels |
| 335-344 | `.small-box .small-box-icon` | Background SVG icon: absolute positioned, 70px, 15% opacity |
| 346-355 | `.small-box-footer` | "More info" link: semi-transparent background, centered |
| 357-364 | `.progress`, `.progress-bar` | Custom progress bar: 8px height, rounded |

### 8.4 JavaScript CODE-TRACE

#### CTR-JS-01: `initializeTransportDashboard()` — Lines 380-400

| Step | Line(s) | Code | Analysis |
|------|---------|------|----------|
| 1 | 382-383 | Get DOM elements by ID | `transport_dashboard-tab` and `transport_dashboard-pane` |
| 2 | 385-388 | Guard: if elements not found | `console.error('Transport dashboard elements not found')` — silent fail, no crash |
| 3 | 390 | `initDateRangePicker()` | Initialize daterangepicker plugin |
| 4 | 393-395 | Check if pane has `active show` | If yes → `loadDashboardData()` immediately (initial load) |
| 5 | 397-399 | Add `shown.bs.tab` event listener | On tab click → `loadDashboardData()` |
| 6 | — | Called from | `$(document).ready(function() { initializeTransportDashboard(); })` at line 749-751 |

#### CTR-JS-02: `initDateRangePicker()` — Lines 405-435

| Step | Line(s) | Code | Analysis |
|------|---------|------|----------|
| 1 | 407-408 | Guard: check `#transport_daterange` exists | If missing → return early |
| 2 | 410-411 | Default dates: `moment().startOf('month')` and `moment().endOf('month')` | Matches PHP defaults in controller |
| 3 | 413-427 | Initialize daterangepicker | opens: 'left', startDate/endDate, 6 range presets (Today, Yesterday, Last 7 Days, Last 30 Days, This Month, Last Month) |
| 4 | 428-432 | Callback on date change | Updates hidden fields `#transport_from_date` and `#transport_to_date` with YYYY-MM-DD, then calls `loadDashboardData()` |
| 5 | 434-435 | Set initial hidden field values | from_date = month start, to_date = month end |

#### CTR-JS-03: `loadDashboardData()` — Lines 441-476

| Step | Line(s) | Code | Analysis |
|------|---------|------|----------|
| 1 | 443-447 | Read hidden date fields with fallback | If fields empty, defaults to current month (matches controller defaults) |
| 2 | 449-455 | jQuery AJAX GET | `url: apiBaseUrl`, `data: { from_date, to_date }`, `dataType: "json"` |
| 3 | 459-469 | `success` callback | Calls 7 update functions sequentially + updates date range label |
| 4 | 471-474 | `error` callback | `console.error` with responseText, `showError()` alert to user |
| 5 | — | No `complete` callback | Spinners removed only on success — if AJAX fails, spinners persist forever |

#### CTR-JS-04: `updateKPICards()` — Lines 480-485

| Step | Line(s) | Code | Analysis |
|------|---------|------|----------|
| 1 | 481 | `$('#totalActiveVehicles').text(kpi.activeVehicles)` | Direct text replacement |
| 2 | 482 | `$('#totalActiveDrivers').text(kpi.activeDrivers)` | Same |
| 3 | 483 | `$('#totalTodaysTrips').text(kpi.todaysTrips)` | Same |
| 4 | 484 | `$('#totalTransportStudents').text(kpi.transportStudents)` | Same |

#### CTR-JS-05: `updateVehicleStatus()` — Lines 490-530

| Step | Line(s) | Code | Analysis |
|------|---------|------|----------|
| 1 | 492-527 | Build HTML string with template literals | Replaces entire `#vehicleStatusSection` contents |
| 2 | 495-497 | Total + On Route header | Side-by-side display |
| 3 | 503-516 | Available / Maintenance / Out of Service breakdown | 3 columns with color-coded numbers |
| 4 | 518-522 | Progress bar with 3 segments | green (available%), yellow (maintenance%), red (outOfService%) |
| 5 | 524-526 | Utilization rate display | `strong` element with percentage |

#### CTR-JS-06: `updateActiveRoutes()` — Lines 535-556

| Step | Line(s) | Code | Analysis |
|------|---------|------|----------|
| 1 | 539-540 | Empty state check | `if (!routes.length) → "No active routes"` |
| 2 | 542-552 | Loop through routes | 5 columns: route, shift, vehicle, driver, students |
| 3 | 555 | Replace tbody | `$('#activeRoutesBody').html(html)` |

#### CTR-JS-07: `updateMaintenanceAlerts()` — Lines 560-592

| Step | Line(s) | Code | Analysis |
|------|---------|------|----------|
| 1 | 564-565 | Empty state check | `if (!alerts.length) → "No alerts"` |
| 2 | 569-578 | Status badge mapping | `overdue` → `bg-danger`/"Overdue", `due_soon` → `bg-warning`/"Due Soon", `scheduled` → `bg-success`/"Scheduled" |
| 3 | 580-588 | Build rows | 4 columns: vehicle, alert_type, due_date, status badge |
| 4 | 591 | Missing: `upcoming` status handling | `upcoming` from controller has no matching `if` → falls to default `bg-warning`/"Due Soon" instead of being green "Upcoming" |

#### CTR-JS-08: `updateAdditionalMetrics()` — Lines 597-614

| Step | Line(s) | Code | Analysis |
|------|---------|------|----------|
| 1 | 599 | Fuel consumption + unit | `${metrics.fuel.consumption} L` |
| 2 | 600 | Fuel cost with ₹ | `₹` + `metrics.fuel.cost.toLocaleString()` |
| 3 | 602-603 | Attendance rate + present count | Percentage + integer |
| 4 | 605-607 | Attendance progress bar width | CSS `width`, `aria-valuenow` |
| 5 | 609-610 | Absent drivers calculation | `total - present` (client-side subtraction) |
| 6 | 612-613 | Incidents total + resolved | Simple text replacement |

#### CTR-JS-09: `updateRecentTrips()` — Lines 616-645

| Step | Line(s) | Code | Analysis |
|------|---------|------|----------|
| 1 | 620-621 | Empty state | `if (!trips.length) → "No recent trips"` |
| 2 | 625-628 | Status badge color map | **BUG (TC-CR24):** Matches `'completed'`, `'in_progress'`, `'cancelled'` (lowercase) but controller returns PascalCase `"Completed"`, `"Ongoing"`, `"Cancelled"` |
| 3 | 630-641 | Build 7-column row | Trip ID, Date/Time, Route, Vehicle, Driver, Status badge, Duration |
| 4 | 638 | Duration null coalesce | `${trip.duration ?? '-'}` — ES6 nullish coalescing |

#### CTR-JS-10: `updateTripChart()` — Lines 647-708

| Step | Line(s) | Code | Analysis |
|------|---------|------|----------|
| 1 | 649-652 | Guard: validate chartData | `if (!chartData || !chartData.datasets) → console.error + return` |
| 2 | 654-658 | Guard: validate canvas element | `document.getElementById('tripChart')` → null check; `console.error('Trip chart canvas not found')` |
| 3 | 660-662 | Destroy previous instance | `if (tripChartInstance) { tripChartInstance.destroy(); }` — prevents memory leak |
| 4 | 664-705 | Create new Chart.js instance | Type: 'line', data from server, colors from `getTripColor()`/`getTripBgColor()` |
| 5 | 675 | Dataset map with colors | Dynamic color per dataset label |
| 6 | 691-703 | Chart options | `responsive: true`, `beginAtZero: true`, Y-axis title "Number of Trips", X-grid hidden |

#### CTR-JS-11: `getTripColor()` / `getTripBgColor()` — Lines 710-738

| Step | Line(s) | Code | Analysis |
|------|---------|------|----------|
| 1 | 711-722 | switch on label | Blue → Scheduled, Green → Completed, Red → Cancelled, Orange → Ongoing |
| 2 | 725-738 | switch on label (background rgba) | Same colors with 0.1 opacity for fill |
| 3 | — | Default case | Always returns gray `#6c757d` |

#### CTR-JS-12: `showError()` — Lines 743-745

| Step | Line(s) | Code | Analysis |
|------|---------|------|----------|
| 1 | 744 | `alert(message)` | Native browser alert dialog — intrusive UX, no modern toast/Swal notification |

#### CTR-JS-13: DOM Ready Handler — Lines 749-751

| Step | Line(s) | Code | Analysis |
|------|---------|------|----------|
| 1 | 749 | `$(document).ready(function() { ... })` | jQuery DOM ready — waits for full DOM including CDN scripts |

### 8.5 External Dependencies Summary

| Dependency | Type | Version | CDN URL | Risk if Unavailable |
|-----------|------|---------|---------|---------------------|
| Bootstrap Icons | CSS | Latest | `cdn.jsdelivr.net/npm/bootstrap-icons` (indirect via layout) | Icons missing |
| Moment.js | JS | 2.29.4 | `cdn.jsdelivr.net/npm/moment@2.29.4/min/moment.min.js` | Daterangepicker fails |
| Chart.js | JS | Latest | `cdn.jsdelivr.net/npm/chart.js` | Chart rendering fails |
| Daterangepicker | JS+CSS | Latest | `cdn.jsdelivr.net/npm/daterangepicker` | Date picker entirely non-functional |

### 8.6 JS Gap Analysis Summary

| Gap ID | Line(s) | Description | Severity |
|--------|---------|-------------|----------|
| GAP-JS-01 | 626-628 | Trip status case mismatch (lowercase vs PascalCase) | P1 — All badges show wrong color |
| GAP-JS-02 | 569-578 | Missing `upcoming` status badge mapping | P2 — "Upcoming" shows as "Due Soon" (yellow) |
| GAP-JS-03 | 213 | Hardcoded green arrow regardless of fuel change direction | P2 — Misleading visual indicator |
| GAP-JS-04 | 609 | Absent calculation may go negative if data inconsistent | P2 — UI shows negative number |
| GAP-JS-05 | 456-474 | No `complete` callback — spinners persist on AJAX error | P2 — Loading state never clears on failure |
| GAP-JS-06 | 744 | `alert()` for error notification | P3 — Intrusive UX, should use Swal/SweetAlert2 |
| GAP-JS-07 | 375 | `apiBaseUrl` rendered via Blade at page load | P3 — If page cached, URL might be stale |
| GAP-JS-08 | 366-368 | 4 CDN scripts loaded synchronously | P2 — Blocking scripts delay page rendering |

---

### 8.7 JavaScript Function Call Graph

```
$(document).ready()
  └── initializeTransportDashboard()
        ├── initDateRangePicker()
        │     ├── moment() defaults (startOfMonth, endOfMonth)
        │     ├── $().daterangepicker({...}, callback)
        │     │     └── callback: update hidden fields → loadDashboardData()
        │     └── Set initial hidden field values
        │
        ├── [if pane has 'active show']
        │     └── loadDashboardData()
        │
        └── transportTab.addEventListener('shown.bs.tab')
              └── loadDashboardData()

loadDashboardData()
  ├── $.ajax({ url: apiBaseUrl, data: {from_date, to_date} })
  │     ├── success:
  │     │     ├── updateKPICards(data.kpi)
  │     │     │     └── 4x .text() calls on #totalActiveVehicles etc.
  │     │     ├── updateTripChart(data.tripChart)
  │     │     │     ├── if !chartData || !chartData.datasets → console.error
  │     │     │     ├── if !ctx (#tripChart) → console.error
  │     │     │     ├── if tripChartInstance → tripChartInstance.destroy()
  │     │     │     └── new Chart(ctx, {type:'line', data:{...}})
  │     │     │           └── getTripColor(label) / getTripBgColor(label)
  │     │     ├── updateVehicleStatus(data.vehicleStatus)
  │     │     │     └── .html() replacement of #vehicleStatusSection
  │     │     ├── updateActiveRoutes(data.activeRoutes)
  │     │     │     ├── if empty → "No active routes"
  │     │     │     └── $.each → build 5-column rows
  │     │     ├── updateMaintenanceAlerts(data.maintenanceAlerts)
  │     │     │     ├── if empty → "No alerts"
  │     │     │     ├── map status → badge color
  │     │     │     └── $.each → build 4-column rows
  │     │     ├── updateAdditionalMetrics(data.additionalMetrics)
  │     │     │     ├── Fuel: consumption L, cost ₹, progress bar
  │     │     │     ├── Attendance: rate%, present, absent (calc), progress
  │     │     │     └── Incidents: total, resolved, badges (static)
  │     │     ├── updateRecentTrips(data.recentTrips)
  │     │     │     ├── if empty → "No recent trips"
  │     │     │     ├── map status → badge color (BUG: lowercase match)
  │     │     │     └── $.each → build 7-column rows
  │     │     └── $('#tripDateRange').text(data.dateRange.display)
  │     │
  │     └── error:
  │           ├── console.error()
  │           └── showError('Failed to load dashboard data...')
  │                 └── alert() — native browser dialog
```

### 8.8 Data Flow: Controller → AJAX Response → Blade Rendering

```
TransportDashboardController@index()
  │
  ├── getKpiData() → { activeVehicles, activeDrivers, todaysTrips, transportStudents }
  │     └── AJAX → updateKPICards() → .text() into 4 KPI <h3> elements
  │
  ├── getTripChartData() → { labels[], datasets[{label, data}...] }
  │     └── AJAX → updateTripChart() → new Chart(ctx, {data: chartData})
  │           └── datasets[0-3]: Scheduled (blue), Completed (green), Cancelled (red), Ongoing (orange)
  │
  ├── getVehicleStatus() → { total, onRoute, available, maintenance, outOfService, utilizationRate }
  │     └── AJAX → updateVehicleStatus() → .html() replaces spinner with progress bars
  │
  ├── getActiveRoutes() → [{ route, shift, vehicle, driver, students }...] (max 10)
  │     └── AJAX → updateActiveRoutes() → tbody#activeRoutesBody rows
  │
  ├── getMaintenanceAlerts() → [{ vehicle, alert_type, due_date, status }...] (max 10)
  │     └── AJAX → updateMaintenanceAlerts() → tbody#maintenanceAlertsBody rows
  │
  ├── getAdditionalMetrics() → { fuel:{...}, attendance:{...}, incidents:{...} }
  │     └── AJAX → updateAdditionalMetrics() → fuel/attendance/incident cards
  │
  ├── getRecentTrips() → [{ trip_id, date_time, route, vehicle, driver, status, duration }...] (max 10)
  │     └── AJAX → updateRecentTrips() → tbody#recentTripsBody rows
  │
  └── dateRange → { from, to, display }
        └── AJAX → $('#tripDateRange').text(display)
```

### 8.9 Blade External Dependency Chain

```
Dashboard Tab Click / Page Load
  │
  ├── [CDN] moment.js (2.29.4) — required for daterangepicker
  │     └── [CDN] daterangepicker.js — date range UI
  │           └── [CDN] daterangepicker.css — date picker styles
  │
  ├── [CDN] Chart.js — trip completion chart
  │
  └── [Internal] Backend AJAX endpoint (/transport/dashboard/data)
        └── Requires: Auth session, Tenant context, DB connectivity
```

---

### 9.1 Query Performance Audit

| Method | Queries per Load | DB Impact (30-day range) | Optimization Opportunity |
|--------|-----------------|-------------------------|-------------------------|
| `getKpiData()` | 4 | 4 total | Low impact; already efficient |
| `getTripChartData()` | 4 × N days | 120 queries for 30 days | **Critical.** Replace with single GROUP BY query: `SELECT DATE(trip_date) as date, status, COUNT(*) FROM tpt_trip WHERE trip_date BETWEEN ? AND ? GROUP BY DATE(trip_date), status` |
| `getVehicleStatus()` | 4-5 | 4-5 | Moderate. merge `$availableVehicles` with `Vehicle::count()` using single query |
| `getOnRouteVehiclesCount()` | 1 | 1 | Efficient; uses distinct count |
| `getActiveRoutes()` | 1 + 3 eager loads | 4 | Acceptable with eager loading |
| `getMaintenanceAlerts()` | 3 | Vehicle::get() loads ALL vehicles | **High impact.** `Vehicle::get()` with no limit — if 10,000 vehicles, all loaded into memory. Must add limit/pagination and re-enable date filters |
| `getAdditionalMetrics()` | 4 | 4 | Low impact (but ignores date range — see GAP-CR27) |
| `getRecentTrips()` | 1 | 1 | Efficient with limit 10 |

**Total DB queries per dashboard load (30-day range): ~137-139 queries**
**Total DB queries per dashboard load (3-month range): ~365+ queries**

### 9.2 Memory Profile

| Method | Data Loaded | Risk |
|--------|------------|------|
| `getMaintenanceAlerts()` | `Vehicle::get()` — ALL vehicles with ALL columns | High if >5000 vehicles. No select() to limit columns — loads `*` including text fields |
| `getActiveRoutes()` | 10 rows with 3 eager relationships | Low |
| `getRecentTrips()` | 10 rows | Low |
| `getVehicleStatus()` | `Vehicle::count()`, `Vehicle::where()->count()` | Low — COUNT queries return scalar |
| `getTripChartData()` | 4 × N COUNT queries | Moderate — 120+ round trips, but each returns scalar |

### 9.3 Caching Strategy Recommendations

| Data Segment | TTL | Cache Key | Rationale |
|-------------|-----|-----------|-----------|
| KPI Data | 5 minutes | `transport:dashboard:kpi:{tenant}:{from}:{to}` | Counts change infrequently |
| Trip Chart | 5 minutes | `transport:dashboard:chart:{tenant}:{from}:{to}` | Daily trip data is static once day ends |
| Vehicle Status | 5 minutes | `transport:dashboard:vehicles:{tenant}` | Vehicle status changes infrequently |
| Active Routes | 2 minutes | `transport:dashboard:routes:{tenant}` | Route assignments may change during day |
| Maintenance Alerts | 10 minutes | `transport:dashboard:alerts:{tenant}` | Alerts are slow-changing |
| Recent Trips | 1 minute | `transport:dashboard:recent-trips:{tenant}` | Trips update frequently — short TTL |
| Additional Metrics | 5 minutes | `transport:dashboard:metrics:{tenant}:{month}` | Monthly data is mostly static |

### 9.4 Recommended Architecture Improvements

1. **Replace loop queries with aggregation**: `getTripChartData()` should use a single `GROUP BY DATE(trip_date), status` query and map results into the 4 datasets in PHP.

2. **Re-enable date filters in maintenance queries**: Lines 223, 240, 256 have commented-out `whereBetween()` calls. These should be uncommented to respect the date range.

3. **Add Model::select() to limit columns**: `Vehicle::get()` loads all columns. Add `->select(['id', 'registration_no', 'fitness_valid_upto', 'insurance_valid_upto'])` for maintenance alerts.

4. **Add pagination or "View All" link**: Active routes limited to 10 with no way to see more. Consider linking to the full DriverRouteVehicle management page.

5. **Date range respect for all metrics**: Ensure fuel, attendance, incidents, and recent trips all respect the selected date range (currently they use fixed `now()`/`today()` values).

6. **Cache hot data**: Dashboard is fetched on every tab click — caching would reduce DB load significantly for this high-frequency endpoint.

---

## 10. Recommendations Summary

### P1 — Must Fix (Production Bugs)

| # | Gap ID | Description | Impact | Fix Suggestion |
|---|--------|-------------|--------|----------------|
| 1 | TC-CR24 | Trip status case mismatch (JS vs PHP) | All trip badges show wrong color, misleading status display | Normalize statuses: convert to lowercase in controller OR use a lookup map in JS |
| 2 | TC-CR33 | Null DriverAttendance causes PHP fatal error | Dashboard crashes when no attendance records exist | Add null check before accessing `$todayAttendance->total` |
| 3 | TC-CR17 | No date validation on from_date/to_date | Invalid date causes 500 error | Add `$request->validate()` or try-catch with default fallback |
| 4 | TC-CR27 | AdditionalMetrics ignores date range | Users changing date range see unchanged fuel/attendance/incidents | Replace `now()`/`today()` with date-parsed values from `$fromDate`/`$toDate` (with month extraction for fuel) |
| 5 | TC-CR28 | January fuel comparison returns 0 | Fuel change % always 0 in January | Use `Carbon::parse($fromDate)->subMonth()->month` instead of `now()->month - 1` |

### P2 — Should Fix (Data Accuracy)

| # | Gap ID | Description | Impact | Fix Suggestion |
|---|--------|-------------|--------|----------------|
| 6 | TC-CR14 | Fitness/Insurance alerts ignore date range | All vehicles shown regardless of filter | Uncomment `whereBetween()` filters |
| 7 | TC-CR21 | Maintenance alerts ignore date range | Same as above | Uncomment `whereBetween()` filter |
| 8 | TC-CR19 | activeDrivers counts all personnel | Misleading metric — not just drivers | Add `whereIn('role', ['Driver', 'driver'])` or separate count |
| 9 | TC-CR30 | Utilization rate uses total (not active) vehicles | Underestimates real utilization | Use `$availableVehicles` (active) as denominator instead of `$totalVehicles` |
| 10 | TC-CR31 | Vehicle status categories may overlap | Progress bar can exceed 100% | Ensure mutually exclusive categories (e.g., outOfService excludes maintenance vehicles) |
| 11 | TC-CR29 | Recent trips ignore date range | Date range filter has no effect on trips list | Add `whereBetween('trip_date', [$fromDate, $toDate])` to `getRecentTrips()` |

### P3 — Nice to Have (UX/Code Quality)

| # | Gap ID | Description | Impact | Fix Suggestion |
|---|--------|-------------|--------|----------------|
| 12 | TC-CR32 | Trip chart N+1 queries | Performance degrades with larger date ranges | Replace loop with GROUP BY query |
| 13 | TC-CR22 | Missing `:active` parameter on nav-tab | Hardcoded active state may conflict with URL tab parameter | Add `:active="request('tab', 'transport_dashboard')"` |
| 14 | TC-CR26 | Full $crud defined but only viewAny used | UI shows unused permissions | Reduce to `['viewAny']` or add gates for the other 16 actions |
| 15 | TC-CR25 | Policy has dead code methods | Confusing for maintenance | Remove unused methods or keep as documentation but add comments |
| 16 | TC-CR39 | Hardcoded green arrow for fuel change | Misleading direction indicator | Dynamically set color/arrow based on positive vs negative change |
| 17 | TC-CR40 | Absent calculation may go negative | UI shows negative number | Use `Math.max(0, metrics.attendance.total - metrics.attendance.present)` |
| 18 | TC-CR36 | Maintenance alerts silently limited to 10 | Missing data without user awareness | Add "View All" link or counter showing total available alerts |
| 19 | TC-CR42 | DriverHelper::count() has no active scope | Inactive personnel counted as "Active Drivers" | Add `where('is_active', 1)` or use scope if exists |

---

## 11. Test Execution Matrix

| TC ID | Type | Priority | Automation Feasibility | Estimated Effort (hrs) | Dependencies |
|-------|------|----------|----------------------|----------------------|--------------|
| TC-P01 | Positive | P1 | Dusk (browser) | 1.0 | Seed data: at least 1 record per table |
| TC-P02 | Positive | P1 | Dusk (browser) | 0.5 | TC-P01 seed data |
| TC-P03 | Positive | P1 | Dusk (browser) | 0.5 | TC-P01 seed data |
| TC-P04 | Positive | P1 | PHPUnit (API) | 0.5 | Known seed counts |
| TC-P05 | Positive | P1 | Dusk (visual + API) | 1.0 | Trips across multiple days |
| TC-P06 | Positive | P1 | PHPUnit (API) | 0.5 | Vehicles with varied status |
| TC-P07 | Positive | P1 | PHPUnit (API) | 0.5 | 5+ DriverRouteVehicleJnt |
| TC-P08 | Positive | P1 | PHPUnit (API) | 0.5 | Vehicles with dates, maintenance records |
| TC-P09 | Positive | P1 | PHPUnit (API) | 0.5 | Fuel records current + prev month |
| TC-P10 | Positive | P1 | PHPUnit (API) | 0.5 | DriverAttendance for today |
| TC-P11 | Positive | P1 | PHPUnit (API) | 0.5 | TptTripIncidents with varied severity |
| TC-P12 | Positive | P1 | PHPUnit (API) | 0.5 | 10+ trip records |
| TC-P13 | Positive | P1 | Dusk (browser) | 1.0 | Date range picker interaction |
| TC-P14 | Positive | P1 | PHPUnit (API) | 0.5 | Null FK records |
| TC-P15 | Positive | P1 | PHPUnit (API) | 0.5 | Trips with varied time data |
| TC-P16 | Positive | P2 | Dusk (browser) | 0.5 | Visual assertion |
| TC-P17 | Positive | P2 | Dusk (browser) | 0.5 | Visual assertion |
| TC-P18 | Positive | P2 | Dusk (browser) | 0.5 | JS console check |
| TC-P19 | Positive | P1 | PHPUnit (API) | 0.5 | Multi-range data |
| TC-P20 | Positive | P2 | Dusk (browser) | 1.0 | Full integration |
| TC-N01 | Negative | P1 | PHPUnit (API) | 0.5 | Empty tables |
| TC-N02 | Negative | P1 | PHPUnit (API) | 0.5 | Mock 500 response |
| TC-N03 | Negative | P1 | PHPUnit (API) | 0.5 | Invalid date strings |
| TC-N04 | Negative | P1 | Dusk (browser) | 1.0 | Alternate user without permission |
| TC-N05 | Negative | P1 | PHPUnit (API) | 0.5 | Unauthorized user |
| TC-N06 | Negative | P1 | Dusk (browser) | 0.5 | Guest session |
| TC-N07 | Negative | P1 | PHPUnit (API) | 0.5 | Zero vehicles |
| TC-N08 | Negative | P1 | PHPUnit (API) | 0.5 | Zero drivers |
| TC-N09 | Negative | P1 | PHPUnit (API) | 0.5 | Zero trips in range |
| TC-N10 | Negative | P1 | PHPUnit (API) | 0.5 | Null dates on vehicles |
| TC-N11 | Negative | P2 | Dusk (browser) | 0.5 | Visual spinner assertion |
| TC-N12 | Negative | P2 | Dusk (browser) | 0.5 | DOM manipulation + JS console |
| TC-N13 | Negative | P1 | PHPUnit (API) | 0.5 | Trip with null times |
| TC-N14 | Negative | P1 | PHPUnit (API) | 0.5 | No route assignments |
| TC-N15 | Negative | P1 | PHPUnit (API) | 0.5 | No alerts data |
| TC-N16 | Negative | P1 | Dusk (browser) | 1.0 | User with zero transport permissions |
| TC-N17 | Negative | P1 | PHPUnit (API) | 0.5 | Unauthorized user + direct URL |
| TC-N18 | Negative | P1 | Dusk (browser) | 0.5 | Session timeout |
| TC-N19 | Negative | P2 | Dusk (browser) | 1.0 | Partial permission user |
| TC-N20 | Negative | P2 | PHPUnit (API + DB) | 0.5 | Assert activity_log table |
| TC-D01 | Dependency | P1 | PHPUnit (API) | 1.0 | Multi-step create/load assertions |
| TC-D02 | Dependency | P1 | PHPUnit (API) | 1.0 | Multi-step create/load assertions |
| TC-D03 | Dependency | P2 | PHPUnit (API) | 1.0 | Cascade delete verification |
| TC-D04 | Dependency | P1 | PHPUnit (API) | 0.5 | Multi-step attendance create |
| TC-D05 | Dependency | P1 | PHPUnit (API) | 0.5 | Status update affects chart |
| TC-D06 | Dependency | P1 | PHPUnit (API) | 0.5 | Date range boundary test |
| TC-D07 | Dependency | P2 | PHPUnit (API) | 0.5 | January month boundary |
| TC-D08 | Dependency | P2 | Dusk (browser) | 1.0 | Rapid interaction, network throttle |
| TC-CR01 | Code Review | P1 | Static analysis | 0.25 | N/A — code review |
| TC-CR02 | Code Review | P1 | Static analysis | 0.25 | N/A — code review |
| TC-CR03 | Code Review | P1 | Static analysis | 0.25 | N/A — code review |
| TC-CR04 | Code Review | P1 | Static analysis | 0.25 | N/A — code review |
| TC-CR05 | Code Review | P1 | Static analysis | 0.25 | N/A — code review |
| TC-CR06 | Code Review | P1 | Static analysis | 0.25 | N/A — code review |
| TC-CR07 | Code Review | P1 | Static analysis | 0.25 | N/A — code review |
| TC-CR08 | Code Review | P1 | Static analysis | 0.25 | N/A — code review |
| TC-CR09 | Code Review | P1 | Static analysis | 0.25 | N/A — code review |
| TC-CR10 | Code Review | P1 | Static analysis | 0.25 | N/A — code review |
| TC-CR11 | Code Review | P1 | Static analysis | 0.25 | N/A — code review |
| TC-CR12 | Code Review | P1 | Static analysis | 0.25 | N/A — code review |
| TC-CR13 | Code Review | P1 | Static analysis | 0.25 | N/A — code review |
| TC-CR14 | Gap | P1 | PHPUnit | 0.5 | Code + data verification |
| TC-CR15 | Gap | P1 | PHPUnit | 0.5 | Zero attendance scenario |
| TC-CR16 | Gap | P1 | PHPUnit | 0.5 | 15+ active assignments |
| TC-CR17 | Gap | P1 | PHPUnit | 0.5 | Invalid date input |
| TC-CR18 | Gap | P1 | Static + PHPUnit | 0.5 | Scheduled-only trips scenario |
| TC-CR19 | Gap | P1 | Static + PHPUnit | 0.5 | Mixed personnel roles |
| TC-CR20 | Gap | P1 | Static analysis | 0.25 | Route list check |
| TC-CR21 | Gap | P1 | Static + PHPUnit | 0.5 | Out-of-range maintenance dates |
| TC-CR22 | Gap | P1 | Static + Dusk | 0.5 | Tab parameter conflict |
| TC-CR23 | Gap | P1 | Static + PHPUnit | 0.5 | SQL query analysis |
| TC-CR24 | Gap | P1 | Static + Dusk | 0.5 | JS badge color assertion |
| TC-CR25 | Gap | P1 | Static analysis | 0.25 | Policy file review |
| TC-CR26 | Gap | P1 | Static analysis | 0.25 | permissionslist.php review |
| TC-CR27 | Gap | P1 | PHPUnit | 0.5 | Date range vs metric values |
| TC-CR28 | Gap | P1 | PHPUnit | 0.5 | January date boundary |
| TC-CR29 | Gap | P1 | PHPUnit | 0.5 | Out-of-range trips in recent |
| TC-CR30 | Gap | P1 | PHPUnit | 0.5 | Utilization rate calculation |
| TC-CR31 | Gap | P1 | PHPUnit | 0.5 | Vehicle in multiple categories |
| TC-CR32 | Gap | P1 | Static + profiling | 0.5 | Query log analysis |
| TC-CR33 | Gap | P1 | PHPUnit | 0.5 | Zero attendance causing error |
| TC-CR34 | Gap | P1 | Static analysis | 0.25 | permissionslist.php |
| TC-CR35 | Gap | P1 | PHPUnit | 0.5 | Null fitness date |
| TC-CR36 | Gap | P1 | PHPUnit | 0.5 | 15+ vehicles alert truncation |
| TC-CR37 | Gap | P2 | Static + PHPUnit | 0.5 | Timezone configuration check |
| TC-CR38 | Gap | P2 | Static + Dusk | 0.5 | Tab URL parameter test |
| TC-CR39 | Gap | P2 | Static + Dusk | 0.5 | Fuel arrow direction check |
| TC-CR40 | Gap | P2 | Static + PHPUnit | 0.5 | Attendance data inconsistency |
| TC-CR41 | Gap | P2 | Static analysis | 0.25 | CSRF middleware review |
| TC-CR42 | Gap | P1 | PHPUnit | 0.5 | Inactive personnel in count |

### 11.1 Test Execution Effort Summary

| Category | Count | Est. Hours (Automation) | Est. Hours (Manual) |
|----------|-------|------------------------|---------------------|
| Positive Tests | 20 | 11.0 | 16.0 |
| Negative Tests | 20 | 11.5 | 18.0 |
| Dependency Tests | 8 | 5.5 | 8.0 |
| Code Review/Gap Tests | 42 | 16.0 | 24.0 |
| **Total** | **90** | **44.0** | **66.0** |

---

## 12. Document Summary

This expanded test case document covers all 9 private methods in `TransportDashboardController` (366 lines) and the full Blade view `dashboard/index.blade.php` (752 lines) with 752 lines of inline JavaScript. Key findings:

| Metric | Count |
|--------|-------|
| Total Test Cases | 90 |
| — Positive (P) | 20 |
| — Negative (N) | 20 |
| — Dependency (D) | 8 |
| — Code Review / Gaps (CR) | 42 |
| BC-AJX Response Shape Entries | 19 |
| BC-BIZ Business Logic Entries | 21 |
| BC-BIZ-DEEP Deep Analysis Entries | 9 (DEEP-01 through DEEP-09) |
| CODE-TRACE Entries | 9 (CTR-01 through CTR-09) + 13 JS CTRs (CTR-JS-01 through CTR-JS-13) |
| BC-CMP Computational Logic Entries | 6 |
| BC-DB Schema Dependencies | 9 |
| BC-AUTH Permission Checks | 3 |
| BC-REL Model Relationships | 7 |
| Gaps Identified (P1) | 28 |
| Gaps Identified (P2/P3) | 14 |
| Performance Issues | 3 (N+1 query in chart, unlimited Vehicle::get(), 137+ queries per load) |
| JS Bugs | 2 (status case mismatch, missing upcoming badge mapping) |
| External CDN Dependencies | 4 (moment.js, Chart.js, daterangepicker JS + CSS) |

**Most Critical Issues:** Trip status case mismatch (TC-CR24) causes all trip badges to render with wrong colors — this is a visible production bug. Null DriverAttendance (TC-CR33) causes dashboard crash when no attendance data exists. The N+1 query pattern in trip chart (TC-CR32) generates 120+ DB queries for a 30-day range.

---

## 7. Detailed Test Steps

### TC-P01: Dashboard Tab Loads Inside Transport Master

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin with `tenant.transport-dashboard.viewAny` permission | Dashboard loads |
| 2 | Expand "Transport" sidebar menu → Click "Transport Master" | URL: `/transport/transport-master` |
| 3 | Check that Dashboard tab is first and active | `#transport_dashboard-pane` has classes `tab-pane fade active show`; `#transport_dashboard-tab` has `active` class |
| 4 | Check Dashboard header | Title: "Transport Dashboard", subtitle with description text |
| 5 | Check KPI cards row | 4 cards: Active Vehicles (blue), Active Drivers (green), Today's Trips (yellow/warning), Transport Students (red/danger) |
| 6 | Check KPI card values | All show "0" initially (before AJAX loads) |
| 7 | Check Trip Chart section | Canvas element `#tripChart` present inside card with header "Trip Completion Status" |
| 8 | Check Vehicle Status section | Card with header "Vehicle Status" showing loading spinner |
| 9 | Check Active Routes table | Table with headers: Route, Shift, Vehicle, Driver, Students — showing loading spinner |
| 10 | Check Maintenance Alerts table | Table with headers: Vehicle, Alert Type, Due Date, Status — showing loading spinner |
| 11 | Check Fuel Consumption card | Header "Fuel Consumption" with "0 L" and "₹0" |
| 12 | Check Driver Attendance card | Header "Driver Attendance" with "0%" and "0 Present" |
| 13 | Check Incident Reports card | Header "Incident Reports" with severity badges |
| 14 | Check Recent Trips table | Table with headers: Trip ID, Date & Time, Route, Vehicle, Driver, Status, Duration — showing loading spinner |
| 15 | Check date range picker | Input with calendar icon showing current month range |

### TC-P02: AJAX Data Loads on Tab Click

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to Transport Master → click "Shift" tab | Shift tab visible |
| 2 | Click "Dashboard" tab | `shown.bs.tab` event fires → `loadDashboardData()` called |
| 3 | Check Network tab | `GET /transport/dashboard/data?from_date=...&to_date=...` with 200 status |
| 4 | Check KPI cards update | 4 KPI values populated from response.kpi |
| 5 | Check chart renders | Chart.js canvas shows line chart with 4 colored lines |
| 6 | Check vehicle status | Vehicle status section updated with count, progress bars, utilization rate |
| 7 | Check active routes | Routes table populated |
| 8 | Check maintenance alerts | Alerts table populated |
| 9 | Check bottom metrics | Fuel, Attendance, Incidents, Recent Trips all populated |

### TC-P03: AJAX Data Loads on Initial Page Load

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate directly to `/transport/transport-master` with no tab parameter | Page loads, Dashboard tab has `active show` |
| 2 | Check Network tab immediately after page load | `GET /transport/dashboard/data` AJAX call fires within ~100ms of DOM ready |
| 3 | Verify request URL | Contains `from_date` and `to_date` query parameters |
| 4 | Check that `initializeTransportDashboard()` was called | From `$(document).ready(function() { initializeTransportDashboard(); })` |
| 5 | Verify pane check | JS condition `if ($(transportPane).hasClass('active show'))` evaluates true → calls `loadDashboardData()` |
| 6 | Confirm no double-load | Only 1 AJAX call fires on initial load (not 2) |

### TC-P04: KPI Cards Display Correct Values

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure seeded: 5 active vehicles, 3 drivers, 10 trips in date range, 20 transport students | DB state |
| 2 | Load Dashboard tab | AJAX fires |
| 3 | Verify `#totalActiveVehicles` | Shows "5" |
| 4 | Verify `#totalActiveDrivers` | Shows "3" |
| 5 | Verify `#totalTodaysTrips` | Shows "10" |
| 6 | Verify `#totalTransportStudents` | Shows "20" |
| 7 | DB query: `SELECT COUNT(*) FROM tpt_vehicle WHERE is_active=1 AND deleted_at IS NULL` | Matches 5 |
| 8 | DB query: `SELECT COUNT(*) FROM tpt_personnel WHERE deleted_at IS NULL` | Matches 3 |
| 9 | DB query: `SELECT COUNT(*) FROM tpt_trip WHERE trip_date BETWEEN 'from' AND 'to'` | Matches 10 |
| 10 | DB query: `SELECT COUNT(*) FROM tpt_student_route_allocation_jnt WHERE active_status=1 AND effective_from <= 'to'` | Matches 20 |

### TC-P05: Trip Completion Chart Renders

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed trips across 5 days with statuses: Day1=2S+1C+1O, Day2=1S+3C, etc. | DB state |
| 2 | Load Dashboard | AJAX with chart data |
| 3 | Check console for "Trip chart rendered successfully" | Console log confirms render |
| 4 | Verify chart canvas `#tripChart` contains rendered chart | Canvas has chart.js pixels |
| 5 | Check legend: 4 items — Scheduled (blue), Completed (green), Cancelled (red), Ongoing (orange) | Legend present with colored markers |
| 6 | Hover over data point | Tooltip shows mode: 'index', intersect: false |
| 7 | Check Y-axis title | "Number of Trips" label present |
| 8 | Check X-axis labels | Date format "d M" (e.g., "01 Jan", "02 Jan") |
| 9 | Verify line tension | Lines are curved (tension: 0.4) |
| 10 | Verify data point values | Daily counts match DB queries per status per day |

### TC-P06: Vehicle Status Breakdown Displays

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed: 8 vehicles total — 3 active on-route, 2 active available, 1 in maintenance, 2 out-of-service | DB state |
| 2 | Load Dashboard | Vehicle status AJAX data |
| 3 | Check total displayed | "8" in Total Vehicles |
| 4 | Check onRoute displayed | "3" in On Route |
| 5 | Check available displayed | "2" in Available (computed as 5 active - 3 onRoute - 0 maintenance = 2; but with 1 maintenance it's 5-3-1=1) |
| 6 | Check maintenance displayed | "1" in Maintenance |
| 7 | Check outOfService displayed | "2" in Out of Service |
| 8 | Check utilization rate | `round((3/8)*100) = 38%` |
| 9 | Verify progress bar | 3 segments: green (available %), yellow (maintenance %), red (outOfService %) |
| 10 | Verify progress bar segments don't exceed 100% combined | Total width ≤ 100% |

### TC-P07: Active Routes Table Populated

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed 5 `DriverRouteVehicleJnt` records with varied route/vehicle/driver assignments, all is_active=1 | DB state |
| 2 | Ensure assignments have valid relationships | route, shift, vehicle, driver all populated |
| 3 | Load Dashboard | AJAX data |
| 4 | Check `#activeRoutesBody` has 5 rows | 5 `<tr>` elements |
| 5 | Verify each row has 5 columns | Route, Shift, Vehicle, Driver, Students |
| 6 | Check route name matches `$assignment->route->name` | Correct route display |
| 7 | Check shift name matches `$assignment->route->shift->name` | Correct shift display |
| 8 | Check vehicle matches `$assignment->vehicle->registration_no` | Correct vehicle display |
| 9 | Check driver matches `$assignment->driver->name` | Correct driver display |
| 10 | Check students matches `$assignment->total_students` | Correct count |

### TC-P08: Maintenance Alerts Table Populated

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed: Vehicle A with fitness_valid_upto = past date (overdue), Vehicle B with fitness_valid_upto = 3 days from now (due_soon), Vehicle C with fitness_valid_upto = 1 year from now (upcoming) | DB state |
| 2 | Seed 1 Vehicle with insurance_valid_upto = past date (overdue) | DB state |
| 3 | Seed 1 TptVehicleMaintenance with status = 'Pending' | DB state |
| 4 | Load Dashboard | AJAX data |
| 5 | Check `#maintenanceAlertsBody` has rows | Multiple alert rows |
| 6 | Verify alert types appear | Fitness Certificate, Insurance Renewal, Maintenance |
| 7 | Verify status badges | "Overdue" (red), "Due Soon" (yellow), "Upcoming" (green for scheduled) |
| 8 | Check vehicle column shows registration_no | Correct vehicle identified |
| 9 | Check due_date column shows formatted date | "M j, Y" format |
| 10 | Verify total alerts ≤ 10 | At most 10 rows (array_slice limit) |

### TC-P09: Fuel Consumption Metric Displayed

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed: TptVehicleFuel for current month: quantity=500, cost=25000, status='Approved' | DB state |
| 2 | Seed: TptVehicleFuel for previous month: quantity=400, cost=20000, status='Approved' | DB state |
| 3 | Load Dashboard | AJAX data |
| 4 | Check `#totalFuelConsumption` | Shows "500 L" |
| 5 | Check `#fuelCost` | Shows "₹25,000" |
| 6 | Check `#fuelComparison` | Shows "Compared to last month: ↑ 25%" (500-400)/400*100 = 25% |
| 7 | Verify fuel progress bar | Width proportional to consumption |
| 8 | Change date range to a different month | Fuel data does NOT change (GAP: ignores date range) |

### TC-P10: Driver Attendance Metric Displayed

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed: 5 TptDriverAttendance for today — 3 Present, 2 Absent | DB state |
| 2 | Load Dashboard | AJAX data |
| 3 | Check `#attendanceRate` | Shows "60%" (3/5*100) |
| 4 | Check `#presentDrivers` | Shows "3" |
| 5 | Check `#absentDrivers` | Shows "Absent: 2 drivers" |
| 6 | Verify progress bar width = 60% | `#attendanceProgress` has `width: 60%` |
| 7 | Add 2 more Present records today | Attendance rate updates to 71% (5/7) |

### TC-P11: Incident Reports Metric Displayed

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed: 5 TptTripIncidents this month — 2 resolved, 3 unresolved; severity: 1 High, 2 Medium, 2 Low | DB state |
| 2 | Load Dashboard | AJAX data |
| 3 | Check `#totalIncidents` | Shows "5" |
| 4 | Check `#resolvedIncidents` | Shows "2" |
| 5 | Check badges: High, Medium, Low | Badges show "High: 1", "Medium: 2", "Low: 2" |
| 6 | Verify resolution time | Shows "Avg. resolution time: 0 days" (no real computation — placeholder) |

### TC-P12: Recent Trips Table Populated

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed 10+ TptTrip records with varied dates, statuses, routes, vehicles, drivers | DB state |
| 2 | Load Dashboard | AJAX data |
| 3 | Check `#recentTripsBody` has up to 10 rows | ≤ 10 `<tr>` elements |
| 4 | Verify Trip ID format | "TRP-00001", "TRP-00002", ... "TRP-00010" |
| 5 | Verify Date & Time format | "Jan 15, 2026 14:30" |
| 6 | Verify Route column | Shows route name or "N/A" |
| 7 | Verify Vehicle column | Shows registration_no or "N/A" |
| 8 | Verify Driver column | Shows driver name or "N/A" |
| 9 | Verify Status badge | Badge color reflects status (GAP: check if colors work — see TC-CR24) |
| 10 | Verify Duration column | Shows "2h 30m" or "-" |
| 11 | Verify order: most recent trip_date first, then start_time DESC | Correct chronological order |

### TC-P13: Date Range Filter Changes Data

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Load Dashboard with default month range | Data loaded for current month |
| 2 | Change date range picker to "Last 7 Days" | Daterangepicker callback fires |
| 3 | Verify hidden fields updated | `#transport_from_date` = 7 days ago, `#transport_to_date` = today |
| 4 | Verify Network tab | New AJAX call with updated `from_date` and `to_date` |
| 5 | Check KPI trips count updated | Should reflect 7-day count, not full month |
| 6 | Check chart labels updated | X-axis shows 7 dates, not 30 |
| 7 | Check date range label updated | `#tripDateRange` text updated |
| 8 | Verify vehicle status may change | If trips exist only in narrowed range, onRoute count could change |
| 9 | Note: Fuel, Attendance, Incidents, Recent Trips do NOT change | These 4 metrics ignore date range (GAP) |

### TC-P14: Active Routes with Null Relationships Gracefully Displayed

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed DriverRouteVehicleJnt with null `route_id`, null `vehicle_id`, null `driver_id` | DB state |
| 2 | Load Dashboard | AJAX data |
| 3 | Check activeRoutes array includes the record | Record appears with "N/A" values |
| 4 | Verify route column shows "N/A" | `$assignment->route->name ?? 'N/A'` |
| 5 | Verify shift column shows "N/A" | `$assignment->route->shift->name ?? 'N/A'` (shift is nested under route) |
| 6 | Verify vehicle column shows "N/A" | `$assignment->vehicle->registration_no ?? 'N/A'` |
| 7 | Verify driver column shows "N/A" | `$assignment->driver->name ?? 'N/A'` |
| 8 | Verify students column shows 0 or null | `$assignment->total_students` |
| 9 | No JavaScript errors in console | Graceful null handling |

### TC-P15: Trip Duration Calculated Correctly

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed TptTrip with start_time=08:00, end_time=10:30, both as Carbon instances | DB state |
| 2 | Seed TptTrip with start_time=null, end_time=null | DB state |
| 3 | Seed TptTrip with start_time=08:00, end_time=null | DB state |
| 4 | Load Dashboard | AJAX |
| 5 | Check trip with both times | Duration = "2h 30m" |
| 6 | Check trip with null times | Duration = null → shows "-" in table |
| 7 | Check trip with only start_time | Duration = null (end_time check fails) → shows "-" |

### TC-P16: Trip Date Range Label Updated

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Load Dashboard with default range | `#tripDateRange` shows "Weekly trip performance overview" initially |
| 2 | Wait for AJAX success | `dateRange.display` text applied |
| 3 | Check `#tripDateRange` text | Shows formatted range, e.g., "Jan 1 - Jan 31, 2026" |
| 4 | Change date range to "Last 7 Days" | Date range picker fires new AJAX |
| 5 | Check `#tripDateRange` updated | Shows "Jan 15 - Jan 22, 2026" |

### TC-P17: Vehicle Status Progress Bar Renders

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed vehicles: 5 available, 3 maintenance, 2 out-of-service | DB state |
| 2 | Load Dashboard | Vehicle status data |
| 3 | Check progress bar container | `<div class="progress" style="height:8px">` exists |
| 4 | Check green segment | `progress-bar bg-success` with width 50% (5/10*100) |
| 5 | Check yellow segment | `progress-bar bg-warning` with width 30% |
| 6 | Check red segment | `progress-bar bg-danger` with width 20% |
| 7 | Verify all 3 segments sum ≤ 100% | Combined width check |

### TC-P18: Chart Destroys and Recreates on Reload

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Load Dashboard | Chart renders |
| 2 | Open browser console | Check `tripChartInstance` global variable |
| 3 | Check `tripChartInstance` is not null | Chart instance exists |
| 4 | Change date range | New AJAX call → `updateTripChart()` called |
| 5 | Check `tripChartInstance.destroy()` was called | Old chart destroyed before new one created |
| 6 | Verify `tripChartInstance` is a new Chart instance | Chart ID changed (internal Chart.js tracking) |

### TC-P19: Utilization Rate Updates on Data Change

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed: 5 active vehicles, 2 on-route (in Ongoing or Scheduled trips) | DB state |
| 2 | Load Dashboard | Utilization = round(2/5*100) = 40% |
| 3 | Change date range to exclude on-route trips | Trips excluded → onRoute = 0 → utilization = 0% |
| 4 | Verify utilization rate changed | UI shows updated percentage |
| 5 | Add 2 more active vehicles (total 7) | Utilization recalculates |

### TC-P20: Full Dashboard Load Sequence

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Clear browser cache, navigate to Transport Master | Page loads |
| 2 | Observe spinners in all table areas | Loading indicators visible |
| 3 | Check Network tab for AJAX request | Request fires within 500ms |
| 4 | Verify all 7 update functions called | `updateKPICards`, `updateTripChart`, `updateVehicleStatus`, `updateActiveRoutes`, `updateMaintenanceAlerts`, `updateAdditionalMetrics`, `updateRecentTrips` |
| 5 | Verify spinners replaced with data | No spinner elements remain in DOM |
| 6 | Verify chart canvas rendered | Chart.js initialized |
| 7 | Verify no JS errors in console | Clean console |
| 8 | Verify entire flow < 5 seconds | Performance benchmark |

---

### TC-N01: No Data — Dashboard Empty State

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure transport tables are empty (truncate or use empty tenant) | Zero records across all tables |
| 2 | Load Dashboard | AJAX fires |
| 3 | Check KPI cards | All show "0": 0 Active Vehicles, 0 Active Drivers, 0 Today's Trips, 0 Transport Students |
| 4 | Check chart | Flat line at 0 for all 4 datasets |
| 5 | Check active routes | Table shows "No active routes" in merged row |
| 6 | Check maintenance alerts | Table shows "No alerts" in merged row |
| 7 | Check fuel consumption | Shows "0 L" and "₹0" |
| 8 | Check driver attendance | Shows "0%" and "0 Present", "Absent: 0 drivers" |
| 9 | Check incidents | Shows "0" total, "0" resolved, all badges "High: 0", "Medium: 0", "Low: 0" |
| 10 | Check recent trips | Table shows "No recent trips" in merged row |

### TC-N02: AJAX Endpoint Error (500)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Load Dashboard normally | Data loads |
| 2 | Simulate 500 error — modify controller to throw exception | AJAX endpoint returns 500 |
| 3 | Check error handler | `showError('Failed to load dashboard data. Please try again.')` called |
| 4 | Check browser alert | `alert()` dialog with error message |
| 5 | Verify console error | `console.error('Dashboard AJAX Error:', xhr.responseText)` logged |
| 6 | Check page state | Previously loaded data remains unchanged (error callback doesn't clear existing data) |

### TC-N03: Invalid Date Range Parameters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Load Dashboard normally | Data loads |
| 2 | Open browser console | |
| 3 | Execute: `$('#transport_from_date').val('invalid-date'); loadDashboardData();` | AJAX fires with `from_date=invalid-date` |
| 4 | Check server response | 500 Internal Server Error |
| 5 | Check error message | `Carbon\Exceptions\InvalidFormatException: Unexpected data 'invalid-date'` |
| 6 | Verify no graceful handling | No try-catch in controller — unhandled exception |
| 7 | Document as GAP-CR17 | No input validation on date parameters |

### TC-N04: Permission 403 — No Dashboard Permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user WITHOUT `tenant.transport-dashboard.viewAny` | User has other transport permissions |
| 2 | Navigate to `/transport/transport-master` | Transport Master loads |
| 3 | Check Dashboard tab is NOT present | `@can('tenant.transport-dashboard.viewAny')` prevents tab rendering |
| 4 | Check other tabs are visible | Vehicle, Staff, Shift, Route etc. visible (if user has those permissions) |
| 5 | Check page does NOT contain dashboard content | No `#transport_dashboard-pane` in DOM |
| 6 | Directly navigate to AJAX endpoint: `GET /transport/dashboard/data` | 403 Forbidden |

### TC-N05: Direct AJAX Endpoint Access Without Permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user WITHOUT `tenant.transport-dashboard.viewAny` | Authenticated but unauthorized |
| 2 | Open browser or curl: `GET /transport/dashboard/data` | |
| 3 | Check response status | 403 Forbidden |
| 4 | Check response body | Gate::authorize exception message or blank 403 page |
| 5 | Verify no dashboard data leaked | Response does not contain KPI, trips, or vehicle data |

### TC-N06: Guest Access to Dashboard Tab

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Logout from application | Session expired |
| 2 | Navigate to `/transport/transport-master` | Redirected to `/login` |
| 3 | Login with valid credentials | After login, redirected back to transport master |
| 4 | Navigate to `GET /transport/dashboard/data` without login | Redirected to `/login` (302) |
| 5 | Request AJAX endpoint with expired session | 401 Unauthorized or redirect to login |

### TC-N07: Zero Vehicles in System

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure no Vehicle records exist | Zero vehicles in tpt_vehicle |
| 2 | Load Dashboard | AJAX fires |
| 3 | Check vehicleStatus.total | 0 |
| 4 | Check vehicleStatus.onRoute | 0 |
| 5 | Check vehicleStatus.available | max(0, 0-0-0) = 0 |
| 6 | Check vehicleStatus.maintenance | 0 |
| 7 | Check vehicleStatus.outOfService | 0 |
| 8 | Check vehicleStatus.utilizationRate | round(0/0*100) → ternary guard → 0 |
| 9 | Check progress bar | All segments 0 width |

### TC-N08: Zero Drivers in System

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure no DriverHelper records and no DriverAttendance records | No personnel, no attendance |
| 2 | Load Dashboard | AJAX fires |
| 3 | Check KPI activeDrivers | 0 |
| 4 | Check attendance rate | 0% (total=0 → ternary guard → 0) |
| 5 | Check present drivers | 0 |
| 6 | Check absent drivers | "Absent: 0 drivers" |

### TC-N09: Zero Trips in Date Range

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure no TptTrip records exist in the selected date range | Zero trips |
| 2 | Load Dashboard | AJAX fires |
| 3 | Check KPI todaysTrips | 0 |
| 4 | Check chart datasets | All 4 datasets filled with zeros for each day |
| 5 | Check onRoute vehicles | 0 (no Ongoing/Scheduled trips) |
| 6 | Check recent trips | Table shows "No recent trips" (unless there are trips outside date range — gap: recentTrips ignores date range) |
| 7 | Inspect chart visually | Flat line at 0 |

### TC-N10: Fitness/Insurance Date Null

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed Vehicle with `fitness_valid_upto = NULL` | DB state |
| 2 | Seed Vehicle with `insurance_valid_upto = NULL` | DB state |
| 3 | Load Dashboard | AJAX fires |
| 4 | Check fitness alert for null-vehicle | `due_date` = "N/A", status = "upcoming" (falls through due to null-safe operator) |
| 5 | Check insurance alert for null-vehicle | Same as above |
| 6 | Verify no JavaScript error | alert renders correctly with "N/A" |

### TC-N11: AJAX During Loading Shows Spinner

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Load Dashboard fresh page | Browser sends request |
| 2 | Before AJAX completes, inspect DOM | All tables show spinner elements: `<div class="spinner-border spinner-border-sm">` |
| 3 | Wait for AJAX complete | Spinners replaced with actual data |
| 4 | No "loading" text visible after AJAX | All sections populated |

### TC-N12: Chart Canvas Not Found

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Use browser DevTools to remove `#tripChart` canvas element | Canvas removed from DOM |
| 2 | Trigger `loadDashboardData()` via tab switch | AJAX completes |
| 3 | Check browser console | `console.error('Trip chart canvas not found')` logged |
| 4 | Verify no JavaScript crash | Page continues to function — other sections still update |
| 5 | Verify chart is not rendered | No Chart.js errors |

### TC-N13: Trip Duration with Null Times

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed TptTrip with start_time = null, end_time = null | DB state |
| 2 | Seed TptTrip with start_time and end_time as strings (not Carbon) | DB state |
| 3 | Load Dashboard | AJAX |
| 4 | Check trip with null times | duration = null → shows "-" |
| 5 | Check trip with string times | `$trip->start_time instanceof Carbon` check fails → duration = null → shows "-" |
| 6 | Verify no error when accessing null duration | Blade uses `?? '-'` at line 638: `${trip.duration ?? '-'}` |

### TC-N14: Active Routes with Zero Assignments

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure no DriverRouteVehicleJnt records exist (or all are is_active=0) | No active assignments |
| 2 | Load Dashboard | AJAX |
| 3 | Check activeRoutes array | Empty array `[]` |
| 4 | Check `#activeRoutesBody` | Shows "No active routes" as merged row |
| 5 | Verify colspan = 5 | Correct column span |

### TC-N15: Maintenance Alerts Returns 0 Results

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure no fitness or insurance dates set on any vehicle, no maintenance records | No alerts |
| 2 | Load Dashboard | AJAX |
| 3 | Check maintenanceAlerts array | Empty array `[]` |
| 4 | Check `#maintenanceAlertsBody` | Shows "No alerts" as merged row |
| 5 | Verify colspan = 4 | Correct column span |

### TC-N16: Permission 403 — No Transport Permissions at All

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user with NO transport permissions | Authenticated but no transport access |
| 2 | Navigate to `/transport/transport-master` | |
| 3 | Check response | 403 Forbidden |
| 4 | Check `Gate::any()` evaluation in `TransportMasterController@index()` | All permission checks fail → `abort(403)` |
| 5 | Verify no transport tabs visible | Entire page is forbidden, not just dashboard |

### TC-N17: Permission 403 — AJAX Endpoint Direct Hit Without Permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user without `tenant.transport-dashboard.viewAny` | Authenticated |
| 2 | Direct HTTP GET to `/transport/dashboard/data` | |
| 3 | Check response status | 403 Forbidden |
| 4 | Verify Gate::authorize() exception | Exception thrown at line 30 |
| 5 | Confirm no data leaked | Empty response body |

### TC-N18: Permission 403 — Expired Session

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open private/incognito browser window | No active session |
| 2 | Navigate to `/transport/transport-master` | Redirected to login page |
| 3 | Send AJAX request to `/transport/dashboard/data` without cookies/auth | 401 Unauthorized or redirect to login |
| 4 | Login, then wait for session to expire (or clear session via another tab) | Session invalidated |
| 5 | Click Dashboard tab again | AJAX fails → AJAX error handler fires |

### TC-N19: Permission — Gate::any() Partial Denial

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user with ONLY `tenant.transport-dashboard.viewAny` | No other transport permissions |
| 2 | Navigate to `/transport/transport-master` | Page loads (Gate::any passes because dashboard permission is in the list) |
| 3 | Check tab bar | Only Dashboard tab visible — all other tabs hidden by `permission` key in nav-tab |
| 4 | Check tab bodies (inspect HTML) | Only `#transport_dashboard-pane` present in DOM — other `@include` blocks not rendered |
| 5 | Verify no other tab content accidentally visible | Dashboard is the only accessible section |
| 6 | Verify AJAX endpoint works | `GET /transport/dashboard/data` returns 200 |

### TC-N20: Activity Log — Dashboard Load Does NOT Create activity_log Entries

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check current activity_log table count | Record baseline |
| 2 | Load Dashboard tab | AJAX fires and completes |
| 3 | Check activity_log table again | Count unchanged (no new entries) |
| 4 | Verify controller has no `activityLog()` calls | Grep confirms zero activityLog calls in TransportDashboardController |
| 5 | Verify controller only performs SELECT queries | No INSERT/UPDATE/DELETE operations |
| 6 | Check after date range change | Still no activity_log entries created |

---

### TC-D01: KPI activeVehicles Count Mirrors Vehicle::active()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Record current active vehicles: `Vehicle::active()->count()` | Baseline N |
| 2 | Load Dashboard, check activeVehicles | Shows "N" |
| 3 | Create 2 new active vehicles | DB now has N+2 |
| 4 | Load Dashboard again | activeVehicles shows "N+2" |
| 5 | Soft-delete 1 vehicle | Vehicle still active but soft-deleted → `active()` scope likely filters `deleted_at IS NULL` |
| 6 | Load Dashboard again | activeVehicles should decrease by 1 if SoftDeletes respected |

### TC-D02: KPI todaysTrips Mirrors Trip Count in Date Range

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Record current trip count in date range | Baseline N |
| 2 | Load Dashboard | todaysTrips = N |
| 3 | Create 3 new trips within date range | DB now has N+3 |
| 4 | Load Dashboard | todaysTrips = N+3 |
| 5 | Delete 1 trip (soft delete) | DB count decreases by 1 |
| 6 | Load Dashboard | todaysTrips = N+2 |

### TC-D03: Vehicle Deletion Cascades to Fuel/Maintenance Counts

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed Vehicle A with 2 TptVehicleFuel records (Approved) | Fuel linked to Vehicle A |
| 2 | Seed Vehicle A with 1 TptVehicleMaintenance (Pending) | Maintenance linked to Vehicle A |
| 3 | Load Dashboard | Fuel count includes Vehicle A's fuel |
| 4 | Delete Vehicle A (cascade removes fuel + maintenance) | DB cascade |
| 5 | Load Dashboard | Fuel count decreases (Vehicle A's fuel gone) |
| 6 | Check maintenance alerts count | Decreases (Vehicle A's maintenance gone) — depends on cascade implementation |

### TC-D04: DriverAttendance Data Affects Attendance Metric

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure no attendance for today | attendanceRate = 0% |
| 2 | Create 3 Present, 1 Absent records for today | DB state (4 total) |
| 3 | Load Dashboard | attendanceRate = 75%, present = 3, total = 4 |
| 4 | Add 1 more Present record today | DB: 4 Present, 1 Absent = 5 total |
| 5 | Load Dashboard | attendanceRate = 80% |

### TC-D05: Trip Status Change Affects Chart Data

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed: 1 trip on Jan 15 with status = 'Scheduled' | DB state |
| 2 | Load Dashboard | Chart shows 1 Scheduled trip on Jan 15, 0 Completed |
| 3 | Update trip status: 'Scheduled' → 'Completed' | DB updated |
| 4 | Load Dashboard | Chart shows 0 Scheduled, 1 Completed on Jan 15 |
| 5 | Change status to 'Cancelled' | Chart updates again |
| 6 | Change status to 'Ongoing' | Chart shows 1 Ongoing on Jan 15 |

### TC-D06: Active Routes Query Filters Expired Assignments

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed DriverRouteVehicleJnt: effective_from = 2025-01-01, effective_to = 2025-06-01, is_active = 1 | DB state |
| 2 | Set date range to 2026-01-01 to 2026-01-31 (after effective_to) | |
| 3 | Load Dashboard | This assignment is EXCLUDED (effective_to < range end) |
| 4 | Verify activeRoutes does NOT include expired assignment | Query filters correctly |
| 5 | Create another assignment with effective_to = null | This assignment appears regardless of date range (no end date = always active) |

### TC-D07: Fuel Data Accuracy — Month Boundary

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed fuel: Jan 2026 = 1000L, Feb 2026 = 800L, both Approved | DB state |
| 2 | Set system date to February 2026 | now()->month = 2 |
| 3 | Load Dashboard | Current month = Feb → consumption = 800L, prev month = Jan → 1000L, change = -20% |
| 4 | Set system date to January 2026 | Current month = Jan, prevMonth = 0 → previous fuel query returns 0 results → fuelChange = 0% (GAP-CR28) |

### TC-D08: Rapid Date Range Changes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open browser Network tab (slow 3G throttling) | Throttled network |
| 2 | Rapidly click 3 different daterangepicker presets: "Today", "Last 7 Days", "Last 30 Days" | 3 AJAX calls fired rapidly |
| 3 | Check that each call has a distinct `from_date`/`to_date` | 3 different request payloads |
| 4 | Wait for all calls to complete | All complete |
| 5 | Check final dashboard state | Shows data for "Last 30 Days" (last call wins) |
| 6 | Verify no stale data from earlier calls | Final call's data displayed |

---

### TC-CR01: Controller — Gate::authorize() at Method Start

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `TransportDashboardController.php` line 30 | `Gate::authorize('tenant.transport-dashboard.viewAny')` |
| 2 | Verify it's before any data processing | Line 30 is before line 32-48 data assembly |
| 3 | Confirm no data leaks if permission check fails | Gate throws exception before any DB queries |

### TC-CR02: Controller — No FormRequest, Raw Request Used

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `index()` method signature | `index(Request $request)` — no FormRequest type hint |
| 2 | Check for any validation calls | No `$request->validate()` or Validator calls |
| 3 | Verify raw `$request->get()` usage | Lines 32-33: `$request->get('from_date', ...)` |

### TC-CR03: Controller — Date Range Defaults

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `index()` lines 32-33 | `$fromDate = $request->get('from_date', now()->startOfMonth()->format('Y-m-d'))` |
| 2 | Inspect `$toDate` default | `$toDate = $request->get('to_date', now()->endOfMonth()->format('Y-m-d'))` |
| 3 | Verify defaults apply when params missing | Call endpoint without params → uses current month |

### TC-CR04: Controller — JSON Response Only

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `index()` line 50 | `return response()->json($data)` |
| 2 | Confirm no Blade view returned | Method never calls `view()` |
| 3 | Verify response headers | Content-Type: application/json |

### TC-CR05: Controller — No Activity Logging

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Search entire `TransportDashboardController.php` for `activityLog` | Zero matches |
| 2 | Confirm no INSERT queries | Only SELECT/Eloquent get/count/paginate |
| 3 | Verify activity_log table after dashboard load | No new entries from dashboard |

### TC-CR06: View — Blade `@can` Directive

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `transportmaster.blade.php` line 23 | `@can('tenant.transport-dashboard.viewAny')` |
| 2 | Verify matching `@endcan` | Line 25: `@endcan` |
| 3 | Check `@include` is inside the `@can` block | `@include('transport::dashboard.index')` on line 24 |

### TC-CR07: View — Tab Definition in nav-tab

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `transportmaster.blade.php` line 7 | Dashboard is first tab entry in `x-backend.tab.nav-tab` |
| 2 | Verify `permission` key | `'permission' => 'tenant.transport-dashboard.viewAny'` |
| 3 | Verify Dashboard tab is first in array | Index 0 of tabs array |

### TC-CR08: View — Dashboard Index JS Uses ES5+

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `dashboard/index.blade.php` | Uses `let` (line 374), `const` (line 375), arrow functions (line 397), template literals (line 526) |
| 2 | Verify browser compatibility | Requires modern browser (Chrome 49+, Firefox 45+, Edge 13+, not IE) |

### TC-CR09: View — AJAX URL Via Named Route

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect line 375 | `const apiBaseUrl = "{{ route('transport.dashboard.data') }}"` |
| 2 | Check routes/web.php line 40 | `Route::get('dashboard/data', ...)->name('dashboard.data')` |
| 3 | Verify correct URL resolution | `/transport/dashboard/data` (under the module's route group prefix) |

### TC-CR10: View — Daterangepicker External Dependency

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect line 368 | CDN script: `https://cdn.jsdelivr.net/npm/daterangepicker/daterangepicker.min.js` |
| 2 | Inspect line 307 | CDN CSS: `https://cdn.jsdelivr.net/npm/daterangepicker/daterangepicker.css` |
| 3 | Verify offline behavior | Dashboard date range picker fails if CDN unavailable |

### TC-CR11: View — Chart.js External Dependency

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect line 367 | CDN script: `https://cdn.jsdelivr.net/npm/chart.js` |
| 2 | Verify offline behavior | Chart render fails if CDN unavailable |
| 3 | Check `moment.js` dependency | Line 366: moment.js CDN (required by daterangepicker) |

### TC-CR12: Route — Named Route Defined

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `routes/web.php` line 40 | `Route::get('dashboard/data', [TransportDashboardController::class, 'index'])->name('dashboard.data')` |
| 2 | Verify route is inside tenant-scoped group | Correct route prefix applied |
| 3 | Run `php artisan route:list | grep dashboard.data` | Route registered with correct name |

### TC-CR13: Policy — TransportDashboardPolicy Defined

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `TransportDashboardPolicy.php` | 7 gate methods: viewAny, view, create, update, delete, restore, forceDelete |
| 2 | Verify only viewAny is used in controller | All other 6 methods are never called |
| 3 | Check `view()` method signature | `view(User $user, Vehicle $vehicle)` — typed with Vehicle, but no Vehicle-specific dashboard actions exist |

### TC-CR14: GAP — Fitness/Insurance Queries Have Commented-Out Date Filter

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `TransportDashboardController.php:223-224` | Line 223: `// ->whereBetween('fitness_valid_upto', [$startDate, $endDate])` — date filter is commented out |
| 2 | Verify same for insurance | Line 240: same pattern — `// ->whereBetween('insurance_valid_upto', [$startDate, $endDate])` |
| 3 | Create vehicles with fitness dates far outside current date range | Vehicle with fitness_valid_upto = 2030-01-01 still appears in alerts |
| 4 | Verify alert appears regardless of date range selection | Alert type "Fitness Certificate" shows vehicles with dates outside picker range |
| 5 | Document as GAP | Date range filter does NOT affect fitness/insurance alerts — ALL vehicles evaluated regardless |

### TC-CR15: GAP — Null DriverAttendance total Access

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure NO TptDriverAttendance records exist for today | Zero attendance records |
| 2 | Load Dashboard | AJAX fires |
| 3 | Check if error occurs | `$todayAttendance` is null at line 300 → line 307: `$todayAttendance->total > 0` → PHP error "Call to a member function total on null" |
| 4 | Check lines 329-330 | `$todayAttendance->present ?? 0` and `$todayAttendance->total ?? 0` — these use null coalescing on the PROPERTY, but if $todayAttendance itself is null, accessing `->total` on null fails BEFORE `??` runs |
| 5 | Confirm error handling | Unhandled error unless there's at least 1 attendance record |

### TC-CR16: GAP — Active Routes: No Pagination, Hard Limit 10

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 15 active DriverRouteVehicleJnt records | DB state |
| 2 | Load Dashboard | AJAX |
| 3 | Check activeRoutes array length | 10 (not 15) |
| 4 | Verify no "View More" link | No pagination in dashboard |
| 5 | Check controller line 202 | `->limit(10)` — hard-coded, no override |

### TC-CR17: GAP — No Input Validation for Date Parameters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to Transport Master → Dashboard tab | Dashboard loaded |
| 2 | Open browser console → Network tab | |
| 3 | Execute JS: `loadDashboardData()` with default params | Normal response |
| 4 | Inject invalid date via browser console: `$('#transport_from_date').val('invalid-date'); loadDashboardData();` | AJAX call with `from_date=invalid-date` |
| 5 | Check server response | `Carbon\Exceptions\InvalidFormatException` — 500 error, no graceful handling |
| 6 | Document as GAP | No validation on `from_date`/`to_date` format in controller; Carbon::parse throws unhandled exception |

### TC-CR18: GAP — getOnRouteVehiclesCount Name Mismatch

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `getOnRouteVehiclesCount()` lines 175-183 | Queries trips with `status IN ('Ongoing', 'Scheduled')` |
| 2 | Create trips with status='Scheduled' for future dates | These trips are NOT "on route" yet |
| 3 | Load Dashboard | onRoute count includes vehicles with only Scheduled trips |
| 4 | Verify method name is misleading | Counts "scheduled or ongoing" not just "on route" |

### TC-CR19: GAP — activeDrivers Counts All Personnel

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed 2 Drivers, 1 Helper, 1 Transport Manager in tpt_personnel | 4 personnel records |
| 2 | Load Dashboard | activeDrivers = 4 (not 2) |
| 3 | Verify KPI label says "Active Drivers" | Label is misleading — should say "Active Personnel" or similar |
| 4 | Check controller line 60 | `DriverHelper::count()` — no role filter |

### TC-CR20: Route — Unused Resource Routes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `routes/web.php` line 36 | `Route::resource('transport-master', TransportMasterController::class)` |
| 2 | Check TransportMasterController methods | Only `index()` and `vehiclesAjax()` exist — no create/store/show/edit/update/destroy |
| 3 | Run `php artisan route:list | grep transport-master` | 7 routes registered but only index() implemented |
| 4 | Verify non-implemented routes return 500 | GET/POST to create/store etc. give error |

### TC-CR21: GAP — Maintenance Query Commented-Out Date Filter

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `TransportDashboardController.php:256` | `// ->whereBetween('created_at', [$startDate, $endDate])` — commented out |
| 2 | Create TptVehicleMaintenance with created_at far outside range | Still appears in alerts |
| 3 | Verify no date filtering applied | Maintenance alerts ignore date range |

### TC-CR22: GAP — nav-tab Missing `:active` Parameter

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `transportmaster.blade.php` line 18 | `<x-backend.tab.nav-tab :tabs="[...]" >` — note: `:active` parameter is MISSING |
| 2 | Verify `dashboard/index.blade.php` line 1 | `class="tab-pane fade p-4 active show"` — hardcoded active state |
| 3 | Navigate to `?tab=vehicle` | Both dashboard AND vehicle tab panes may show as active (hardcoded + programmatic) |

### TC-CR23: GAP — orWhere Not Grouped in Maintenance Query

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `TransportDashboardController.php:257-261` | `->where('status', 'Pending')->orWhere(function($query) { $query->where('status', 'Approved')->whereNull('out_service_date'); })` |
| 2 | Verify SQL interpretation | `WHERE status = 'Pending' OR (status = 'Approved' AND out_service_date IS NULL)` |
| 3 | Seed: 1 Pending maintenance, 1 Approved maintenance WITH out_service_date, 1 Approved WITHOUT out_service_date | All 3 returned (Pending + Approved without date) |
| 4 | If intended grouping was: `WHERE (status='Pending' OR (status='Approved' AND out_service_date IS NULL))`, then the orWhere is actually correct without extra grouping. | The query may be intentional — return all Pending OR Approved-without-date. But without parentheses around the whole WHERE clause combining with other conditions, this could break. |

### TC-CR24: GAP — Trip Status Case Mismatch (PHP vs JS)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect DB trip status values | Likely "Completed", "Scheduled", "Cancelled", "Ongoing" (PascalCase) |
| 2 | Inspect `dashboard/index.blade.php` lines 626-628 | JS matches: `trip.status === 'completed'`, `'in_progress'`, `'cancelled'` (lowercase) |
| 3 | Load Dashboard with Completed trip | Status badge shows `bg-secondary` (default) instead of `bg-success` |
| 4 | Verify ALL status badges are gray | Every trip shows as secondary color due to case mismatch |
| 5 | Also check: JS uses `'in_progress'` but DB likely has `'Ongoing'` | Double mismatch |

### TC-CR25: GAP — Policy Dead Code

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `TransportDashboardPolicy.php` | 6 unused methods: view, create, update, delete, restore, forceDelete |
| 2 | Verify each method has `Vehicle $vehicle` parameter | Dashboard has no Vehicle-specific actions — these methods are misleading |
| 3 | Confirm controller never uses policy-based Gate::authorize | Only uses string gate `Gate::authorize('tenant.transport-dashboard.viewAny')` |

### TC-CR26: GAP — permissionslist.php Full $crud for transport-dashboard

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `config/permissionslist.php` line 291 | `'transport-dashboard' => $crud` — 17 actions defined |
| 2 | Confirm only viewAny is used | Only `tenant.transport-dashboard.viewAny` referenced anywhere in codebase |
| 3 | Check if other permissions serve any purpose | They exist in permission assignment UI but have no gate checks |

### TC-CR27: GAP — AdditionalMetrics Ignores Date Range

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `getAdditionalMetrics()` lines 279-280 | Carbon parses `$fromDate`, `$toDate` but NEVER uses them |
| 2 | Verify fuel uses `now()->month` (line 283) | Not date range |
| 3 | Verify attendance uses `today()` (line 300) | Not date range |
| 4 | Verify incidents use `now()->startOfMonth()` (line 311) | Not date range |
| 5 | Change date range on dashboard | Fuel, Attendance, Incidents values remain unchanged |

### TC-CR28: GAP — January Fuel Comparison Bug

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed: January 2026 fuel data exists | DB state |
| 2 | Set current date to January 2026 | now()->month = 1 |
| 3 | Load Dashboard | Fuel for current month (Jan) found, prevMonth = 0 → `whereMonth('date', 0)` returns nothing |
| 4 | Check fuelChange | 0% (should show comparison if Jan vs Dec data exists) |
| 5 | Document as GAP | Month 0 doesn't exist in MySQL — January comparison always shows 0% change |

### TC-CR29: GAP — Recent Trips Ignores Date Range

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set date range to "Last 7 Days" | Date range narrowed |
| 2 | Seed trips from 6 months ago (outside range) | DB has old trips |
| 3 | Load Dashboard | recentTrips includes the 6-month-old trips (no date filter) |
| 4 | Change date range to "Today" | recentTrips still shows the 6-month-old trips |

### TC-CR30: GAP — Utilization Rate Denominator

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed: 10 total vehicles, 5 active, 3 on-route | DB state (5 inactive) |
| 2 | Load Dashboard | utilizationRate = round(3/10*100) = 30% |
| 3 | Verify expected rate if using active denominator | Expected: round(3/5*100) = 60% |
| 4 | Verify actual rate | 30% — undercount due to inactive vehicles in denominator |

### TC-CR31: GAP — Vehicle Status Category Overlap

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed: Vehicle A with is_active=0 AND has Approved maintenance request in date range | Vehicle appears in BOTH maintenance AND outOfService |
| 2 | Load Dashboard | maintenance count includes A, outOfService count includes A |
| 3 | Check progress bar total width | available% + maintenance% + outOfService% > 100% because A counted twice |
| 4 | Document as GAP | Non-mutually-exclusive categories cause visual overlap |

### TC-CR32: GAP — Trip Chart N+1 Query Pattern

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enable DB query logging | Log all queries |
| 2 | Load Dashboard with 30-day date range | 120+ trip count queries logged (30 days × 4 statuses) |
| 3 | Count queries | Far more than necessary; could be done with 1 GROUP BY query |
| 4 | Document performance concern | N+1 pattern does not scale |

### TC-CR33: GAP — Null DriverAttendance Causes Error

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Truncate TptDriverAttendance table | Zero attendance records |
| 2 | Load Dashboard | PHP Error: "Call to a member function total on null" at line 307 |
| 3 | Check error details | `$todayAttendance` = null (no records for today) → line 307 tries `$todayAttendance->total` |

### TC-CR34: GAP — transport Permission Group Partially Used

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `config/permissionslist.php` line 289 | `'transport' => $crud` — full CRUD defined |
| 2 | Search for `tenant.transport.` usage | Only `tenant.transport.viewAny` used in `TransportMasterController@index()` line 29 |
| 3 | Verify no create/update/delete/restore/forceDelete used | No other `tenant.transport.*` gates exist |

### TC-CR35: GAP — Null Fitness Date Shows "Upcoming" Status

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed Vehicle with `fitness_valid_upto = NULL` | DB state |
| 2 | Load Dashboard | Fitness alert for this vehicle shows: status = "upcoming" (green badge → "Scheduled") |
| 3 | Verify misleading status | Vehicle with NO fitness certificate labeled "Scheduled/Upcoming" — should be "Missing" or "N/A" |
| 4 | Check controller logic | `null <= now()` is never evaluated (null-safe `?->` short-circuits) → falls to else → "upcoming" |

### TC-CR36: GAP — Maintenance Alerts Silently Limited to 10

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 15 vehicles, each with fitness + insurance dates → 30 alerts | DB state |
| 2 | Create 5 maintenance alerts → 35 total | DB state |
| 3 | Load Dashboard | Only 10 alerts shown (fitness + insurance most recent first, maintenance included up to 10) |
| 4 | Verify no indication of truncation | No "View All" link or count indicator |

### TC-CR37: GAP — DriverAttendance Timezone

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check app timezone config | `config/app.php` timezone |
| 2 | Check DB timezone | MySQL timezone setting |
| 3 | If timezones differ: Create attendance at 11 PM UTC (which is 4:30 AM next day IST) | `whereDate('attendance_date', today())` may return different set depending on timezone used |
| 4 | Document potential timezone issue | No timezone normalization between app and DB |

### TC-CR38: GAP — Hardcoded `active show` on Tab Pane

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to `/transport/transport-master?tab=vehicle` | URL specifies Vehicle tab |
| 2 | Inspect page DOM | Two tab panes have `active show`: `#transport_dashboard-pane` (hardcoded line 1) AND `#vehicle-pane` (via nav-tab JS) |
| 3 | Verify visual state | Both tab contents may be visible |

---

