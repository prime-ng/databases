# tpt_DriverAttendantReport_TcList

## Module: Transport → Transport Report → Driver & Attendant

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | Transport |
| Tab Group | Transport Report |
| Feature | Driver & Attendant Performance Report |
| URL(s) | `/transport/transport-report` (page load), AJAX: `GET /transport/transport-report?active_tab=driver-performance&section=charts/table` |
| Controller | `Modules\Transport\Http\Controllers\TransportReportController` |
| index() | Line 34 — Gate check + date parse + AJAX dispatch or full page render |
| Tab Builder Method | `buildDriverPerformanceSection()` (line 144) |
| Data Method | `getDriverPerformanceReport()` (line 735) |
| Helper | `calculatePerformanceScore()` (line 945) |
| Pagination | `paginateCollection()` (line 262) — 10 per page, page name `page_driver` |
| View | `transport::report.driver-attendant.index` |
| Hub View | `transport::tab_module.transportreport` (line 35: `@can('tenant.driver-performance.viewAny')` / `@include`) |
| Permission | `tenant.driver-performance.viewAny` |
| Filters | driver_id, role (Driver/Helper/Both), route_id, date range (from_date, to_date) |
| Sections | charts (4 summary KPIs + 3 charts), table (8-column paginated grid) |
| Export | Not implemented |
| Models Used | `DriverHelper`, `TptTrip`, `TptTripIncidents`, `TptDriverAttendance` |
| DB Tables | `tpt_personnel`, `tpt_driver_attendance`, `tpt_trips`, `tpt_trip_stop_details`, `tpt_trip_incidents` |
| Chart JS | Chart.js via CDN (doughnut, scatter, bar/radar toggle) |

---

## 2. Pre-conditions

| PC ID | Condition | Details |
|-------|-----------|---------|
| PC-01 | PHP 8.1+ / Laravel 10 | Controller uses `match(true)` (PHP 8.0+), `str_contains`, typed properties |
| PC-02 | Module installed | `Modules/Transport` registered in `modules_statuses.json` |
| PC-03 | Permission seeded | `tenant.driver-performance.viewAny` exists in `permissionslist.php` |
| PC-04 | Permission assigned | Authenticated user has `tenant.driver-performance.viewAny` via role |
| PC-05 | `DriverHelper` model exists | `Modules\Transport\Models\DriverHelper` with `active()` scope |
| PC-06 | `TptDriverAttendance` model exists | Attendance records linked via `attendance()` relation on `DriverHelper` |
| PC-07 | `TptTrip` model exists | Trip records linked via `driverTrips()` and `helperTrips()` relations |
| PC-08 | `TptTripIncidents` model exists | Incident records linked via `incidents()` relation on `DriverHelper` |
| PC-09 | `TptTripStopDetail` model exists | Delay calculation uses `tripStopDetail` relation on `TptTrip` |
| PC-10 | `paginateCollection()` helper available | Defined at line 262 in `TransportReportController` |
| PC-11 | DriverHelper records exist | Minimum 2 Driver + 2 Helper records with `is_active = 1` |
| PC-12 | Attendance records exist | `TptDriverAttendance` with `attendance_date` in current month |
| PC-13 | Trip records exist | `TptTrip` with `trip_date` in current month, linked to drivers/helpers |
| PC-14 | Date range picker renders | `transport_daterange` class triggers daterangepicker JS |
| PC-15 | Chart.js loaded | CDN script in hub view: `https://cdn.jsdelivr.net/npm/chart.js` |
| PC-16 | AJAX route not cached | `GET /transport/transport-report` supports AJAX responses |
| PC-17 | `getFilterData()` returns staff list | `$filters['staff']` = `DriverHelper::active()->get()` |
| PC-18 | `getFilterData()` returns roles list | `$filters['roles']` = `['Driver', 'Helper', 'Both']` |
| PC-19 | `getFilterData()` returns routes list | `$filters['routes']` = `Route::active()->get()` |
| PC-20 | Blade section routing works | `@if(request('section') === 'charts')` / `@elseif(request('section') === 'table')` |
| PC-21 | Skeleton loaders present | `#driver-performance-charts` and `#driver-performance-table` show spinners initially |

---

## 3. Default Data Load

### 3.1 Summary KPIs (4 cards)

| KPI | Source | CSS Class | Icon |
|-----|--------|-----------|------|
| Total Staff | `$driverSummary->total_staff` = `$reports->count()` | `text-bg-primary` | Person SVG |
| Avg Attendance Rate | `round($reports->avg('attendance_rate'), 1)` | `text-bg-success` | Checkmark SVG |
| Avg Performance Score | `$driverSummary->avg_performance` = `round((float) ($reports->avg('performance_score') ?? 0), 1)` | `text-bg-warning` | Clock SVG |
| Excellent Performers | [Query/Code Removed] | `text-bg-info` | Star SVG |

### 3.2 Chart 1 — Performance Distribution (Doughnut)

| Segment | Score Range | Color | Label Format |
|---------|------------|-------|--------------|
| Excellent | >= 90 | `rgba(40, 167, 69, 0.8)` | Excellent (90+) |
| Good | 80–89 | `rgba(25, 135, 84, 0.8)` | Good (80-89) |
| Average | 70–79 | `rgba(255, 193, 7, 0.8)` | Average (70-79) |
| Needs Improvement | 60–69 | `rgba(253, 126, 20, 0.8)` | Needs Improvement (60-69) |
| Poor | < 60 | `rgba(220, 53, 69, 0.8)` | Poor (<60) |

### 3.3 Chart 2 — Attendance vs Performance (Scatter)

| Config | Value |
|--------|-------|
| X-axis | Attendance Rate (%) — range 0–100 |
| Y-axis | Performance Score — range 0–100 |
| Point radius | 8 (fixed) |
| Point color | Mapped by performance tier (same 5-tier scheme) |
| Tooltip | Staff name, Role, Attendance %, Performance Score, Trips, Avg Delay |

### 3.4 Chart 3 — Role-wise Performance (Bar/Radar toggle)

| Dataset | Calculation |
|---------|-------------|
| Drivers Avg Performance | `$drivers->avg('performance_score')` |
| Helpers Avg Performance | `$helpers->avg('performance_score')` |
| Drivers Avg Attendance | `$drivers->avg('attendance_rate')` |
| Helpers Avg Attendance | `$helpers->avg('attendance_rate')` |
| Drivers Avg Trips | `$drivers->avg('trips_handled')` |
| Helpers Avg Trips | `$helpers->avg('trips_handled')` |
| Drivers Avg Delay | `$drivers->avg('avg_delay')` |
| Helpers Avg Delay | `$helpers->avg('avg_delay')` |

### 3.5 Table Columns (8 columns)

| # | Column | Source | Format/Widget |
|---|--------|--------|---------------|
| 1 | Staff | `$staff->staff_name` + avatar | Avatar circle + name + role subtitle |
| 2 | Role | `$staff->role` | Badge: Driver = `bg-primary`, Helper = `bg-info` |
| 3 | Attendance | `$staff->attendance_rate` | Progress bar (success >= 90, warning >= 80, danger < 80) + % |
| 4 | Trips Handled | `$staff->trips_handled` | Integer, centered |
| 5 | Avg Delay | `$staff->avg_delay` | Badge: success <= 5 min, warning <= 15 min, danger > 15 min |
| 6 | Incidents | `$staff->incidents` | Badge: success = 0, danger > 0 |
| 7 | Performance | `$staff->performance_score` | Progress bar (success/warning/info/danger/dark) + score |
| 8 | Status | `$staff->status` | Badge: Excellent/Good/Average/Needs Improvement/Poor |

### 3.6 Radar Chart Dimensions (toggled)

| Axis | Drivers | Helpers |
|------|---------|---------|
| Performance | `driverAvgPerformance` | `helperAvgPerformance` |
| Attendance | `driverAvgAttendance` | `helperAvgAttendance` |
| Trips | `driverAvgTrips` | `helperAvgTrips` |
| Delay (inverted) | `max(0, 100 - driverAvgDelay)` | `max(0, 100 - helperAvgDelay)` |
| Efficiency | `min(100, (perf + att) / 2)` | `min(100, (perf + att) / 2)` |

---

## 4. Test Data Strategy

### 4.1 Seed Data Requirements

| Entity | Minimum Records | Key Fields |
|--------|----------------|------------|
| DriverHelper (Driver) | 3 | `role = 'Driver'`, `is_active = 1` |
| DriverHelper (Helper) | 3 | `role = 'Helper'`, `is_active = 1` |
| TptDriverAttendance | 10 per staff | `attendance_status`, `attendance_date` spanning current month |
| TptTrip | 5 per staff | `trip_date`, linked via `driverTrips`/`helperTrips`, with `tripStopDetail` |
| TptTripIncidents | 2–3 staff only | `incident_time`, linked to specific staff |

### 4.2 Performance Profile Matrix

Create staff records with these specific profiles:

| Profile | Attendance | Avg Delay | Incidents | Trips | Expected Score | Expected Status |
|---------|-----------|-----------|-----------|-------|----------------|-----------------|
| Star Driver (Staff A) | 100% (10/10) | 0 min | 0 | 12 | 100.0 | Excellent |
| Good Driver (Staff B) | 90% (9/10) | 3 min | 0 | 8 | 87.2 | Good |
| Average Driver (Staff C) | 80% (8/10) | 8 min | 1 | 6 | 68.4 | Average |
| Needs Improvement (Staff D) | 70% (7/10) | 12 min | 2 | 4 | 52.2 | Needs Improvement |
| Poor Helper (Staff E) | 40% (4/10) | 20 min | 5 | 2 | 10.0 | Poor |
| Perfect Helper (Staff F) | 100% (10/10) | 1 min | 0 | 25 | 100.0 | Excellent |
| No Trip Helper (Staff G) | 50% (5/10) | 0 (no trips) | 0 | 0 | 20.0 | Poor |
| High Delay Driver (Staff H) | 85% (8.5/10) | 30 min | 0 | 10 | 35.0 | Poor |

### 4.3 Edge Case Records

| Record | Purpose |
|--------|---------|
| Staff with 0 attendance (all absent) | Tests `$totalDays = 0` → `attendance_rate = 0` |
| Staff with no trips at all | Tests `$totalTrips = 0` → `avg_delay = 0`, `trips_handled = 0` |
| Staff with both driverTrips and helperTrips | Tests `$staff->driverTrips->merge($staff->helperTrips)` |
| Staff with extremely high delay (60+ min) | Tests `max(0, 100 - (60*2))` = 0 from delay component |
| Staff with > 20 incidents | Tests `max(0, 100 - (20*10))` = 0 from incidents component |
| Inactive staff (`is_active = 0`) | Must be excluded by `->active()` scope |
| Staff with no `tripStopDetail` | Tests `$trip->tripStopDetail && ...` guard = 0 delay |

### 4.4 Cross-Tab Data Isolation

Ensure staff/trip records exist with timestamps OUTSIDE the default date range (current month) to verify date range filtering. Also ensure records for OTHER tabs (route-performance, trip-execution) exist to verify `page_driver` paginator isolation.

---

## 5. Business Conditions

### 5.1 Database / Query Logic (DB)

| DB ID | Condition | Source | Details |
|-------|-----------|--------|---------|
| DB-01 | [Query/Code Removed] | Line 738 | Loads `TptDriverAttendance` relation |
| DB-02 | Attendance filtered by `attendance_date BETWEEN` | Line 738 | Constrained to `$startDate`..`$endDate` |
| DB-03 | [Query/Code Removed] | Line 739 | Loads trips where staff is driver |
| DB-04 | [Query/Code Removed] | Line 740 | Loads trips where staff is helper |
| DB-05 | Trips constrained to `trip_date BETWEEN` | Lines 739–740 | Filtered by date range |
| DB-06 | Trips eager load `tripStopDetail` | Lines 739–740 | For delay calculation |
| DB-07 | [Query/Code Removed] | Line 741 | Loads `TptTripIncidents` relation |
| DB-08 | Incidents constrained to `incident_time BETWEEN` | Line 741 | Filtered by date range |
| DB-09 | Staff filter: `isset($filters['staff_id']) && !empty()` | Line 744 | Prevents SQL error when key missing |
| DB-10 | [Query/Code Removed] | Line 744 | Single staff lookup |
| DB-11 | Role filter: `in_array($filters['role'], ['Driver', 'Helper', 'Both'])` | Line 745 | Validation before applying |
| DB-12 | [Query/Code Removed] | Line 746 | Applied only for Driver/Helper (not Both) |
| DB-13 | `->active()` scope | Line 747 | Excludes `is_active = 0` records |
| DB-14 | `->get()` executes query | Line 748 | Collection returned for in-memory map |
| DB-15 | `$staff->driverTrips->count()` | Line 750 | Driver role trips count |
| DB-16 | `$staff->helperTrips->count()` | Line 750 | Helper role trips count |
| DB-17 | [Query/Code Removed] | Line 751 | Present days only |
| DB-18 | `$staff->attendance->count()` | Line 752 | Total attendance records |
| DB-19 | `$staff->driverTrips->merge($staff->helperTrips)` | Line 755 | Combined trips collection |
| DB-20 | `$allTrips->avg(...)` for delay | Line 756 | Average of all trip delays |
| DB-21 | `$staff->incidents->count()` | Line 771 | Incidents from eager loaded relation |
| DB-22 | `paginateCollection(..., 10, 'page_driver')` | Line 154 | Paginates mapped collection with unique name |

### 5.2 Validation Logic (VAL)

| VAL ID | Condition | Source | Details |
|--------|-----------|--------|---------|
| VAL-01 | Date range parsing | Line 55 | `parseDateRange($request)` returns `['startDate', 'endDate']` |
| VAL-02 | `$reqFilters` array build | Lines 42–53 | Keys set even when null |
| VAL-03 | `staff_id` not in URL | Default safe | `isset()` + `!empty()` prevents SQL error |
| VAL-04 | `role` not in URL | Default safe | `in_array()` returns false → no filter applied |
| VAL-05 | `route_id` not in URL | `$reqFilters['route_id']` = null | Not consumed by `getDriverPerformanceReport()` |
| VAL-06 | Empty `from_date`/`to_date` | Line 55 | Falls back to `startOfMonth()` / `endOfMonth()` |
| VAL-07 | Non-AJAX page load | Lines 60–67 | Returns full hub view with spinners |
| VAL-08 | AJAX with no `section` param | Line 60 | Returns full hub view, not partial |
| VAL-09 | Invalid `active_tab` value | Line 89 | `default` case: `<p class="text-muted">Invalid tab</p>` |
| VAL-10 | `$staff->tripStopDetail` null check | Line 757 | `&&` short-circuit prevents error on null |
| VAL-11 | `$staff->tripStopDetail->reaching_time` null check | Line 757 | Null coalescing prevents error |
| VAL-12 | `$staff->tripStopDetail->sch_arrival_time` null check | Line 757 | Null coalescing prevents error |
| VAL-13 | `$totalDays ? ... : 0` division guard | Line 762 | Prevents division by zero |
| VAL-14 | `round(..., 1)` on all metrics | Lines 762, 770 | Ensures consistent decimal precision |
| VAL-15 | `$performanceScore >= 90` match order | Lines 773–779 | First match wins; ordering matters |

### 5.3 Authorization Logic (AUTH)

| AUTH ID | Condition | Source | Details |
|---------|-----------|--------|---------|
| AUTH-01 | `Gate::authorize('tenant.transport.viewAny')` | Line 36 | Top of `index()` — gate on full report access |
| AUTH-02 | `@can('tenant.driver-performance.viewAny')` | Hub line 35 | Blade guard around `@include` in hub view |
| AUTH-03 | `'permission' => 'tenant.driver-performance.viewAny'` | Hub line 14 | Tab nav-tab hides button without permission |
| AUTH-04 | No `Gate::authorize` in `buildDriverPerformanceSection` | Line 144 | Relies on `index()` auth — but internal builder is private |
| AUTH-05 | No `Gate::authorize` in `getDriverPerformanceReport` | Line 735 | Private data method, not route-accessible |
| AUTH-06 | Permission string must match `permissionslist.php` | Config | `tenant.driver-performance.viewAny` (hyphens, not dots) |
| AUTH-07 | 403 returned when Gate denies | Laravel | `Gate::authorize()` throws `AuthorizationException` → 403 |
| AUTH-08 | Guest redirects to login | Laravel | `auth` middleware on route or controller constructor |
| AUTH-09 | `is_super_admin` bypass | Gate `before()` | Super admin sees all tabs regardless of permissions |
| AUTH-10 | Tab-based double security: nav + body | Hub view | Both `permission` key AND `@can` guard the tab |

### 5.4 Business Logic (BIZ)

| BIZ ID | Condition | Expected Behavior |
|--------|-----------|-------------------|
| BIZ-01 | Staff with zero attendance records | `$totalDays = 0` → `$attendanceRate = 0`, score component = 0 |
| BIZ-02 | Staff with zero trips | `$totalTrips = 0` → `$avgDelay = 0` (avg of empty = 0), `trips_handled = 0` |
| BIZ-03 | Staff with no incidents | `$staff->incidents->count()` returns 0 → incidents = 0 |
| BIZ-04 | No staff matching filters | Empty collection → table shows "No driver performance data found" |
| BIZ-05 | Role = 'Both' | No `where('role')` clause → all roles included |
| BIZ-06 | Role = 'Driver' | [Query/Code Removed] |
| BIZ-07 | Role = 'Helper' | [Query/Code Removed] |
| BIZ-08 | Perfect score scenario | 100% att + 0 delay + 0 incidents + 20+ trips → score = 100 |
| BIZ-09 | Score capped at 100 | `min($score, 100)` prevents overflow |
| BIZ-10 | Attendance rate capped at 100 | `min($attendanceRate, 100) * 0.4` — over 100% impossible but guarded |
| BIZ-11 | Delay component floor at 0 | `max(0, 100 - ($avgDelay * 2))` — never negative |
| BIZ-12 | Incidents component floor at 0 | `max(0, 100 - ($incidents * 10))` — never negative |
| BIZ-13 | Trips experience capped at 100 | `min($tripsHandled * 5, 100) * 0.1` — max contribution = 10 |
| BIZ-14 | Staff with only `driverTrips` | `$staff->helperTrips->count()` = 0 → total = driver trips only |
| BIZ-15 | Staff with only `helperTrips` | `$staff->driverTrips->count()` = 0 → total = helper trips only |
| BIZ-16 | Staff with both role trip types | Merge combines both → total trips count includes all |
| BIZ-17 | Status threshold: >= 90 | 'Excellent' with 'success' class |
| BIZ-18 | Status threshold: >= 80 | 'Good' with 'info' class |
| BIZ-19 | Status threshold: >= 70 | 'Average' with 'warning' class |
| BIZ-20 | Status threshold: >= 60 | 'Needs Improvement' with 'danger' class |
| BIZ-21 | Status threshold: < 60 | 'Poor' with 'secondary' class |
| BIZ-22 | Pagination page name isolation | `page_driver` prevents conflict with `page_route`, `page_trip`, etc. |
| BIZ-23 | `->latest()` ordering | No explicit `latest()` in `getDriverPerformanceReport` — uses DB order |

## 5A. Database Schema Reference

### 5A.1 `tpt_personnel` (DriverHelper Model)

| Column | Type | Notes |
|--------|------|-------|
| `id` | BIGINT PK | Auto-increment |
| `name` | VARCHAR(255) | Staff full name |
| `role` | ENUM('Driver','Helper') | Role classification |
| `email` | VARCHAR(255) | Contact email |
| `phone` | VARCHAR(20) | Contact number |
| `is_active` | TINYINT(1) | Soft-active flag; `active()` scope uses this |
| `created_at` | TIMESTAMP | Laravel auto |
| `updated_at` | TIMESTAMP | Laravel auto |
| `deleted_at` | TIMESTAMP NULL | Soft delete support |

### 5A.2 `tpt_driver_attendance`

| Column | Type | Notes |
|--------|------|-------|
| `id` | BIGINT PK | Auto-increment |
| `personnel_id` | BIGINT FK | `->references('id')->on('tpt_personnel')` |
| `attendance_date` | DATE | Date of attendance |
| `attendance_status` | ENUM('Present','Absent','Half Day','Leave') | Status for the day |
| `remarks` | TEXT | Optional notes |
| `created_at` | TIMESTAMP | Laravel auto |

### 5A.3 `tpt_trips`

| Column | Type | Notes |
|--------|------|-------|
| `id` | BIGINT PK | Auto-increment |
| `route_scheduler_id` | BIGINT FK | References route scheduler |
| `driver_id` | BIGINT FK NULL | References `tpt_personnel.id` (Driver) |
| `helper_id` | BIGINT FK NULL | References `tpt_personnel.id` (Helper) |
| `vehicle_id` | BIGINT FK | Assigned vehicle |
| `trip_date` | DATE | Date of trip |
| `start_time` | DATETIME | Actual start |
| `end_time` | DATETIME | Actual end |
| `trip_status` | ENUM('SCHEDULED','IN_PROGRESS','COMPLETED','CANCELLED') | Status |
| `created_at` | TIMESTAMP | Laravel auto |

### 5A.4 `tpt_trip_stop_details`

| Column | Type | Notes |
|--------|------|-------|
| `id` | BIGINT PK | Auto-increment |
| `trip_id` | BIGINT FK | References `tpt_trips.id` |
| `stop_order` | INT | Sequence order |
| `pickup_point_id` | BIGINT FK | Route stop |
| `sch_arrival_time` | DATETIME | Scheduled arrival |
| `reaching_time` | DATETIME | Actual arrival |
| `students_boarded` | INT | Count |
| `created_at` | TIMESTAMP | Laravel auto |

### 5A.5 `tpt_trip_incidents`

| Column | Type | Notes |
|--------|------|-------|
| `id` | BIGINT PK | Auto-increment |
| `trip_id` | BIGINT FK | References `tpt_trips.id` |
| `personnel_id` | BIGINT FK | References `tpt_personnel.id` |
| `incident_type` | VARCHAR(100) | Type classification |
| `incident_time` | DATETIME | When incident occurred |
| `description` | TEXT | Details |
| `severity` | ENUM('Low','Medium','High','Critical') | Severity level |
| `created_at` | TIMESTAMP | Laravel auto |

### 5A.6 Relationship Map



## 5B. Model Relationship Details

| Relation | Type | FK | Local Key |
|----------|------|----|-----------|
| `DriverHelper.attendance()` | `hasMany` | `tpt_driver_attendance.personnel_id` | `id` |
| `DriverHelper.driverTrips()` | `hasMany` | `tpt_trips.driver_id` | `id` |
| `DriverHelper.helperTrips()` | `hasMany` | `tpt_trips.helper_id` | `id` |
| `DriverHelper.incidents()` | `hasMany` | `tpt_trip_incidents.personnel_id` | `id` |
| `TptTrip.tripStopDetail()` | `hasOne` | `tpt_trip_stop_details.trip_id` | `id` |
| `DriverHelper.active()` | `scope` | `where('is_active', 1)` | — |

## 5C. Filter Interaction Matrix

| Filter Combination | `staff_id` | `role` | `route_id` | `from_date`/`to_date` | SQL/Query Effect |
|--------------------|------------|--------|------------|----------------------|------------------|
| None (default) | — | — | — | current month | Active staff only, all roles, current month range |
| Role only | — | 'Driver' | — | current month | `WHERE role = 'Driver' AND is_active = 1` + date filter |
| Staff only | 5 | — | — | current month | `WHERE id = 5 AND is_active = 1` + date filter |
| Role + Staff | 5 | 'Helper' | — | current month | `WHERE id = 5 AND role = 'Helper' AND is_active = 1` |
| Date only | — | — | — | custom range | Attendance/trips/incidents constrained to custom range |
| Role + Date | — | 'Both' | — | custom range | All roles (Both = no role filter) + custom dates |
| Role + Staff + Date | 5 | 'Driver' | — | custom range | All three constraints |
| Route filter | — | — | 10 | current month | `$reqFilters['route_id']` passed but NOT consumed by `getDriverPerformanceReport()` — NO EFFECT |
| Empty staff_id | "" | — | — | — | `!empty("")` = false → ignored |
| Invalid staff_id | "abc" | — | — | — | `where('id', 'abc')` → no match → empty results |

## 5D. JavaScript Execution Flow (Chart Assembly)



## 5E. SQL Query Decomposition

The `getDriverPerformanceReport()` method executes the following SQL (approximately):



## 5F. In-Memory Processing Pipeline



### 5.5 Deep Business Logic (BIZ-DEEP)

| BIZ-DEEP ID | Scenario | Expected Behavior |
|-------------|----------|-------------------|
| BIZ-DEEP-01 | Single trip with delay = 0 | `diffInMinutes(..., ...)` = 0 → avg delay = 0 |
| BIZ-DEEP-02 | Multiple trips with varying delay | `$allTrips->avg()` averages all non-zero and zero delays |
| BIZ-DEEP-03 | `reaching_time` > `sch_arrival_time` | Positive diff → positive delay minutes |
| BIZ-DEEP-04 | `reaching_time` before `sch_arrival_time` | `diffInMinutes` returns absolute? Check `Carbon::diffInMinutes` behavior |
| BIZ-DEEP-05 | `tripStopDetail` missing `reaching_time` | Guard returns 0 → no contribution to avg |
| BIZ-DEEP-06 | `tripStopDetail` missing `sch_arrival_time` | Guard returns 0 → no contribution to avg |
| BIZ-DEEP-07 | `tripStopDetail` relation is null | `$trip->tripStopDetail` = null → `$trip->tripStopDetail && ...` = false → 0 |
| BIZ-DEEP-08 | Attendance status = 'Present' only | Only `where('attendance_status', 'Present')` counts as present |
| BIZ-DEEP-09 | Attendance status = 'Absent' | Not counted in present → lower attendance rate |
| BIZ-DEEP-10 | Attendance status = 'Half Day' | Not counted as present → reduces attendance rate |
| BIZ-DEEP-11 | Attendance status = 'Leave' | Not counted as present → reduces attendance rate |
| BIZ-DEEP-12 | Identical drivers and helpers performance | Bar chart equal height, scatter points overlapping |
| BIZ-DEEP-13 | Only 1 staff in results | Charts render with single data point; table shows 1 row |
| BIZ-DEEP-14 | Exactly 10 staff (no pagination) | All on page 1; no pagination controls rendered |
| BIZ-DEEP-15 | Exactly 11 staff (pagination triggers) | 10 on page 1, 1 on page 2; paginator link visible |
| BIZ-DEEP-16 | All staff have identical score | Distribution chart = single segment at 100%; scatter = single cluster |
| BIZ-DEEP-17 | No drivers, only helpers | Role chart shows helpers as 0 on driver side; distribution still $filters |
| BIZ-DEEP-18 | Delay = 50 min | `max(0, 100 - 100) * 0.3` = 0 from delay component |
| BIZ-DEEP-19 | 15 incidents recorded | `max(0, 100 - 150) * 0.2` = 0 from incidents component |
| BIZ-DEEP-20 | Score = 99.9 (borderline Excellent) | `>= 90` → Excellent. Format `round(..., 1)` keeps 99.9 |
| BIZ-DEEP-21 | Score = 90.0 | `>= 90` → Excellent (boundary value) |
| BIZ-DEEP-22 | Score = 89.9 | `>= 80` → Good (boundary just below Excellent) |
| BIZ-DEEP-23 | Score = 80.0 | `>= 80` → Good (boundary value) |
| BIZ-DEEP-24 | Score = 79.9 | `>= 70` → Average (boundary just below Good) |
| BIZ-DEEP-25 | Score = 70.0 | `>= 70` → Average (boundary value) |
| BIZ-DEEP-26 | Score = 69.9 | `>= 60` → Needs Improvement |
| BIZ-DEEP-27 | Score = 60.0 | `>= 60` → Needs Improvement (boundary value) |
| BIZ-DEEP-28 | Score = 59.9 | `default` → Poor (just below Needs Improvement) |
| BIZ-DEEP-29 | All attendance records outside date range | `$totalDays = 0` → attendance_rate = 0 → performance_score penalized |
| BIZ-DEEP-30 | All trips outside date range | `$totalTrips = 0` → trips_handled = 0, avg_delay = 0 |
| BIZ-DEEP-31 | Incidents outside date range | `$staff->incidents->count()` = 0 (constrained `whereBetween`) |
| BIZ-DEEP-32 | Staff with `is_active = 0` | Excluded by `->active()` scope → not in results |
| BIZ-DEEP-33 | Chart resize on window resize | `window.addEventListener('resize', ...)` triggers `resize()` on all 3 charts |
| BIZ-DEEP-34 | Chart type toggle Bar → Radar | `roleChart.destroy()` then new `Chart(ctx, { type: 'radar' })` |
| BIZ-DEEP-35 | Radar delay axis inverted | `Math.max(0, 100 - avgDelay)` — high delay = low radar value |
| BIZ-DEEP-36 | Doughnut hover offset | `hoverOffset: 15` — hovered segment expands outward |
| BIZ-DEEP-37 | Scatter tooltip shows 5 fields | Staff, Role, Attendance, Performance, Trips, Avg Delay |
| BIZ-DEEP-38 | Empty state icon | `<i class="bi bi-inbox fs-4 d-block mb-2"></i>` in empty table cell |
| BIZ-DEEP-39 | Progress bar width = score | `<div style="width: {{ $performanceScore }}%">` — matches value |
| BIZ-DEEP-40 | AJAX error handler | Shows `<div class="alert alert-danger">Failed to load ...</div>` |
| BIZ-DEEP-41 | Tab not `driver-performance` | `buildDriverPerformanceSection()` never called; data not loaded |
| BIZ-DEEP-42 | `$filters['staff']` includes both roles | `DriverHelper::active()->get()` returns all active staff regardless of role |
| BIZ-DEEP-43 | `$filters['roles']` hardcoded | `['Driver', 'Helper', 'Both']` — no DB query |
| BIZ-DEEP-44 | Filter bar: Clear/Reset button | `<a href="{{ url()->current() }}" class="btn btn-outline-secondary btn-sm">` with redo icon |
| BIZ-DEEP-45 | Skeleton loader before AJAX | `<div class="spinner-border text-primary">` in each section container |
| BIZ-DEEP-46 | `loadTabSection()` called twice per tab | Once for 'charts', once for 'table' — two separate AJAX calls |
| BIZ-DEEP-47 | Active tab persisted via `request('active_tab')` | Passed in every AJAX call and filter form |
| BIZ-DEEP-48 | Pagination uses `->appends(request()->query())` | Preserves all existing query params on page change |
| BIZ-DEEP-49 | Filter form uses `transport-filter-form` class | JS targets `.transport-filter-form` for AJAX submission |
| BIZ-DEEP-50 | Daterangepicker triggers form submit on change | Callback calls `$('.transport-filter-form').first().submit()` |
| BIZ-DEEP-51 | `$reqFilters` passes `route_id` but it is NOT consumed | `getDriverPerformanceReport()` never references `$filters['route_id']` — filter has NO effect |
| BIZ-DEEP-52 | `$reqFilters` passes `driver_id` but it maps to `staff_id` | Check controller: `'driver_id' => $request->driver_id` (line 49) vs `'staff_id'` in `getDriverPerformanceReport()` (line 744) — different key names! |
| BIZ-DEEP-53 | Filter bar shows Route dropdown but it is inert | Users can select a route but it changes nothing in the driver-performance report |
| BIZ-DEEP-54 | Both `driver_id` and `staff_id` in request | `$reqFilters['driver_id']` set (line 49) but never used; `$filters['staff_id']` not in `$reqFilters` — mismatch |
| BIZ-DEEP-55 | Chart toggle active class management | `btn.classList.remove('active')` on all, then `this.classList.add('active')` — only one button active at a time |
| BIZ-DEEP-56 | Radar chart delay axis is inverted | High delay → low radar value (`Math.max(0, 100 - avgDelay)`). A driver with 0 delay gets 100 on delay axis |
| BIZ-DEEP-57 | Radar chart efficiency axis = avg of performance + attendance | `Math.min(100, (perf + att) / 2)` — simple average without delay/incidents factored in |
| BIZ-DEEP-58 | `$driverPerformanceReportsPaginated` not paginated in charts section | Charts section receives full collection; only table section uses paginated |
| BIZ-DEEP-59 | `$excellentCount` computed twice | Lines 14 (PHP template) and 165 (PHP in script) — identical logic |
| BIZ-DEEP-60 | Empty Staff dropdown when no records | `$filters['staff']` returns empty collection → only `<option value="">All Staff</option>` rendered |
| BIZ-DEEP-61 | Empty Role dropdown fallback | `$filters['roles']` hardcoded → always shows Driver, Helper, Both |
| BIZ-DEEP-62 | Role filter persists across page reload | URL query string preserved by `@selected(request('role')==$role)` |
| BIZ-DEEP-63 | Date range persists across tab switch | Form data re-serialized on tab switch; hidden from_date/to_date preserved |
| BIZ-DEEP-64 | Tab not loaded indicator | `.loaded` class added after initial load; prevents re-load on repeated tab clicks |
| BIZ-DEEP-65 | AJAX error does not block tab switching | Error handler just shows alert in the failed section; other sections still load |
| BIZ-DEEP-66 | Multiple concurrent AJAX requests | No abort on previous request; filter changes can cause race conditions |
| BIZ-DEEP-67 | Daterangepicker ranges use moment.js | Ranges: Today, Last 7 Days, This Month, Last Month — all computed client-side |
| BIZ-DEEP-68 | Filter bar reset uses `url()->current()` | Clears all query params; does NOT reset to default date range |
| BIZ-DEEP-69 | Pagination links in partials | `$driverPerformanceReportsPaginated->appends(request()->query())->links()` preserves ALL query params |
| BIZ-DEEP-70 | Performance score = 0 when all components fail | 0% attendance + 50+ min delay + 10+ incidents + 0 trips = 0 + 0 + 0 + 0 = 0 |
| BIZ-DEEP-71 | Performance score = 50 exactly middle | 50% att + 0 delay + 0 incidents + 0 trips = 20 + 30 + 20 + 0 = 70 (not 50) |
| BIZ-DEEP-72 | Performance score with 1 incident only | `max(0, 100-10)*0.2` = 18 from incidents (was 20) |
| BIZ-DEEP-73 | Performance score with 2 incidents only | `max(0, 100-20)*0.2` = 16 from incidents (was 20) |
| BIZ-DEEP-74 | Delay contribution at exactly 50 min | `max(0, 100-100)*0.3` = 0 (boundary where delay contribution hits zero) |
| BIZ-DEEP-75 | Delay contribution at 49.9 min | `max(0, 100-99.8)*0.3` = 0.06 (barely positive contribution) |
| BIZ-DEEP-76 | Incidents at exactly 10 | `max(0, 100-100)*0.2` = 0 (boundary where incident contribution hits zero) |
| BIZ-DEEP-77 | Incidents at 9 | `max(0, 100-90)*0.2` = 2.0 (barely positive contribution) |
| BIZ-DEEP-78 | 1 trip handled: `min(1*5, 100)*0.1` = 0.5 | Trips contribution = 0.5 out of max 10 |
| BIZ-DEEP-79 | 20 trips handled: `min(100, 100)*0.1` = 10 | Max trips contribution reached at 20 trips |
| BIZ-DEEP-80 | Performance score with decimal avgDelay | `$avgDelay = 3.3` → `round(3.3, 1)` = 3.3 → `max(0, 100-6.6)*0.3` = 28.02 |

---

## 6. Test Case List — Extended

### 6.5 Positive — Filter Combinations

| TC ID | Description | Pre-condition | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|---------------|----------------|---------|---------|--------|
| TC-P26 | Filter by Staff_ID + Role = Driver | Staff B is Driver | Only Staff B row shown (redundant but valid combination) | — | — | ⬜ |
| TC-P27 | Filter by date range = last 30 days | Some records outside range | Only records within last 30 days counted; date picker shows correct range | — | — | ⬜ |
| TC-P28 | Filter by date range = custom 2-week window | Attendance/trips exist in that window | Metrics computed for that window only | — | — | ⬜ |
| TC-P29 | Filter bar: select Staff then change Role | Both filters active | Both constraints applied simultaneously | — | — | ⬜ |
| TC-P30 | Filter: Role = Driver + Date = Last 7 Days | 2 drivers have trips in last 7 days | 2 Driver rows, metrics for last 7 days only | — | — | ⬜ |

### 6.6 Negative — Edge Cases

| TC ID | Description | Pre-condition | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|---------------|----------------|---------|---------|--------|
| TC-N18 | Only inactive staff exist | All DriverHelper `is_active = 0` | `->active()` scope excludes all → empty table | — | — | ⬜ |
| TC-N19 | Empty staff_id query param | `staff_id=` | `!empty('')` = false → no filter → all staff | — | — | ⬜ |
| TC-N20 | staff_id = 0 (sent as query param) | `staff_id=0` | `!empty(0)` = false → no filter → all staff | — | — | ⬜ |
| TC-N21 | staff_id = non-existent ID (e.g. 99999) | No staff with ID 99999 | `where('id', 99999)` → empty collection → empty table | — | — | ⬜ |
| TC-N22 | Role filter SQL injection attempt | `role=1' OR '1'='1` | `in_array()` returns false for any value not in ['Driver','Helper','Both'] → ignored | — | — | ⬜ |
| TC-N23 | XSS in staff name | Staff name = `<script>alert('xss')</script>` | Escaped by Blade `{{ }}` → rendered as text, not executed | — | — | ⬜ |
| TC-N24 | Very long staff name (255+ chars) | Staff name exceeds column limit | Truncated at DB level; display may wrap but no error | — | — | ⬜ |
| TC-N25 | Special characters in staff name | Name = "John O'Brien & Sons" | Blade escaping handles special chars; displays correctly | — | — | ⬜ |
| TC-N26 | Tab switched before AJAX completes | Rapidly click Route Performance tab | AJAX for driver-performance may still be in-flight; response discarded when container removed | — | — | ⬜ |
| TC-N27 | Network failure during AJAX load | Disconnect network after filter | Error handler shows alert: "Failed to load charts." | — | — | ⬜ |

### 6.7 Destructive — Data Volume & Stress

| TC ID | Description | Pre-condition | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|---------------|----------------|---------|---------|--------|
| TC-D15 | 500 attendance records for single staff | Staff A has daily attendance for 500 days | attendance_rate computed across all 500; progress bar may overflow visually | — | — | ⬜ |
| TC-D16 | 1000 trips for single staff | Staff A has 1000 driverTrips | trips_handled = 1000; `min(1000*5, 100)` = 100 → max trips contribution | — | — | ⬜ |
| TC-D17 | All staff have identical names | 10 staff all named "John Doe" | Table shows 10 identical names — no way to distinguish except ID | — | — | ⬜ |
| TC-D18 | Very long date range (1 year) | from_date=2025-01-01, to_date=2025-12-31 | All attendance/trips/incidents for full year processed in memory; each staff may have 200+ attendance records | — | — | ⬜ |
| TC-D19 | 50 staff records | 50 DriverHelper with data | Pagination: 5 pages of 10; distribution chart has 50 data points | — | — | ⬜ |
| TC-D20 | All attendance_status = 'Absent' for all staff | 10 staff, 10 days each = 100 absent records | Each staff: attendance_rate = 0; score = 0 + delay*0.3 + incidents*0.2 + trips*0.1 | — | — | ⬜ |
| TC-D21 | All attendance_status = 'Half Day' for all staff | Same as above but 'Half Day' | Not counted as Present → same as Absent → attendance_rate = 0 | — | — | ⬜ |
| TC-D22 | Zero trips but some attendance | Staff with 80% attendance but 0 trips | score = 32 + 30 + 20 + 0 = 82 → "Good" (but no trips handled) | — | — | ⬜ |
| TC-D23 | All trips cancelled/no start_time | Trips exist but no `reaching_time` | `$trip->tripStopDetail->reaching_time` = null → 0 delay | — | — | ⬜ |
| TC-D24 | Browser Refresh mid-AJAX | Refresh while loadTabSection in-flight | AJAX aborted; page reloads fresh; no partial state corruption | — | — | ⬜ |
| TC-D25 | Multiple filter changes before AJAX response | Rapidly click filter 3 times | Each click fires AJAX; last response wins; intermediate responses discarded | — | — | ⬜ |

### 6.8 Code Review — Edge Cases

| TC ID | Priority | Description | Expected Result | Status |
|-------|----------|-------------|-----------------|--------|
| TC-CR19 | P2 | View receives `$driverPerformanceReportsPaginated` as paginated object | `$driverPerformanceReportsPaginated->links()` is a paginator method, works correctly | ◌ |
| TC-CR20 | P2 | `$driverPerformanceReportsPaginated` is paginated from the FULL collection | Charts section uses `$driverPerformanceReports` (unpaginated) correctly | ◌ |
| TC-CR21 | P2 | `$driverPerformanceReports` shared between charts and paginator | Both sections reference same collection → paginator slices it, charts use full | ◌ |
| TC-CR22 | P3 | No `latest()` or `orderBy()` in `getDriverPerformanceReport()` | Records returned in `tpt_personnel` table order (usually PK ASC) | ◌ |
| TC-CR23 | P3 | `match(true)` for status uses `>=` not `>` | All boundaries are inclusive: >=90, >=80, etc. — no gaps | ◌ |
| TC-CR24 | P3 | `match(true)` for status_class uses same boundaries | Same thresholds → guaranteed same tier assignment | ◌ |
| TC-CR25 | P3 | `$excellentCount` and `$excellentStaff` calculate same value | Both count `where('performance_score', '>=', 90)` — identical | ◌ |
| TC-CR26 | P3 | Staff name uses `$staff->name` not `first_name` + `last_name` | `DriverHelper` model has single `name` column; display = `$staff->name` | ◌ |
| TC-CR27 | P3 | Progress bar width derived from score without max check | `style="width: {{ $performanceScore }}%"` — score capped at 100 by `calculatePerformanceScore()` | ◌ |
| TC-CR28 | P3 | `$staff->incidents->count()` called twice | Line 771 AND inside `calculatePerformanceScore()` line 949 — double count | ◌ |
| TC-CR29 | P3 | `$staff->driverTrips->merge($staff->helperTrips)` duplicates ID if same trip | If a trip is linked via BOTH driver_id and helper_id for same staff, merge may contain duplicate trip IDs | ◌ |
| TC-CR30 | P3 | `round()` on avgDelay applied AFTER `$allTrips->avg()` | `round((float) $avgDelay, 1)` — avgDelay already has many decimals | ◌ |
| TC-CR31 | P3 | `$presentDays / $totalDays * 100` — integer division hazard | PHP does float division automatically; `round(..., 1)` ensures consistent precision | ◌ |
| TC-CR32 | P3 | Daterangepicker locale format = `YYYY-MM-DD` | Matches MySQL date format — no conversion needed for DB queries | ◌ |
| TC-CR33 | P3 | Hidden from_date/to_date updated on daterange change | JS: `$('.transport_from_date').val(...)` and `.transport_to_date.val(...)` | ◌ |
| TC-CR34 | P3 | Paginator name `page_driver` unique across all tabs | Check other tab paginators: `page_route`, `page_trip`, `page_usage`, `page_stop`, `page_finance`, `page_cost` — all unique | ◌ |
| TC-CR35 | P3 | Filter form uses class not ID | `.transport-filter-form` — allows multiple forms per page; each tab has its own | ◌ |

### 6.9 Data Integrity (DI)

| TC ID | Description | Pre-condition | Expected Result | Status |
|-------|-------------|---------------|-----------------|--------|
| TC-DI01 | Staff A: 10 attendance days, 8 Present | Matches BIZ-01 | attendance_rate = 80.0% | ◌ |
| TC-DI02 | Staff A: 5 trips, all 0 delay | Matches BIZ-02 | avg_delay = 0; trips_handled = 5 | ◌ |
| TC-DI03 | Staff A: 0 incidents | Matches BIZ-03 | incidents = 0 | ◌ |
| TC-DI04 | Perfect Staff: 100% att, 0 delay, 0 incidents, 20 trips | Matches BIZ-08 | score = `100*0.4 + 100*0.3 + 100*0.2 + 100*0.1` = 100.0 | ◌ |
| TC-DI05 | Staff B: 5 attendance days = 10 days | DB has only 5 records for Staff B | `$totalDays = 5` → attendance_rate = 100% if all present | ◌ |
| TC-DI06 | Orphan attendance (no parent staff) | TptDriverAttendance with personnel_id=99999 | Not loaded (no matching DriverHelper) → no effect | ◌ |
| TC-DI07 | Duplicate attendance on same date | 2 attendance records for Staff A on 2025-01-15 | `attendance->count()` double-counts → inflates totalDays and presentDays | ◌ |
| TC-DI08 | Staff linked as BOTH driver and helper on same trip | Trip 100: driver_id=5, helper_id=5 | `driverTrips` includes trip 100, `helperTrips` includes trip 100 → `merge()` may duplicate | ◌ |
| TC-DI09 | Trip with driver_id = Staff A AND same staff in helperTrips | Different trips, same staff | `merge()` produces 2 unique trips; correct count | ◌ |
| TC-DI10 | Incident with severity 'Critical' | Staff A has 1 Critical incident | Still counts as 1 incident (no severity weighting) | ◌ |

---

## 7. CODE-TRACE: Full Request Flow

### 7.1 `index(Request $request)` — Line 34



### 7.2 Page Render — Hub View (`transportreport.blade.php`)



### 7.3 `loadTabSection()` — Line 73 (AJAX Dispatch)



### 7.4 `buildDriverPerformanceSection()` — Line 144



### 7.5 `getDriverPerformanceReport()` — Line 735



### 7.6 `calculatePerformanceScore()` — Line 945



### 7.7 Chart Assembly (View Side — `index.blade.php`)



---

## 8. Test Steps

### 8.1 Environment Setup Steps

| Step | Action | Expected Result |
|------|--------|-----------------|
| S-01 | Ensure `Modules/Transport` is enabled in `modules_statuses.json` | Module listed with `"status": true` |
| S-02 | Run `php artisan migrate` for Transport module | All transport tables created |
| S-03 | Seed `permissionslist.php` with `tenant.driver-performance.viewAny` | Permission exists in DB |
| S-04 | Assign `tenant.driver-performance.viewAny` to test role | Role has permission attached |
| S-05 | Create test DriverHelper records (3 Drivers + 3 Helpers) via seeder/factory | 6 records in `tpt_personnel` with `is_active = 1` |
| S-06 | Create TptDriverAttendance records (10 per staff for last 30 days) | 60 attendance records; mix of Present/Absent/Half Day |
| S-07 | Create TptTrip records (5 per staff with tripStopDetail) | 30 trip records with stop details |
| S-08 | Create TptTripIncidents (2-3 staff only, 1-2 incidents each) | 4-6 incidents across selected staff |
| S-09 | Login as admin user with test role | Dashboard loads; user authenticated |
| S-10 | Navigate to `/transport/transport-report` | Transport Report hub page loads with all tabs |
| S-11 | Verify "Driver & Attendant" tab exists in nav | Tab labeled "Driver & Attendant" with shield icon visible |
| S-12 | Click "Driver & Attendant" tab | Tab pane shows filter bar + skeleton loaders |
| S-13 | Wait for AJAX charts section to load | Spinner replaced by 4 summary KPIs + 3 charts |
| S-14 | Wait for AJAX table section to load | Spinner replaced by table with 8 columns |

### 8.2 Positive Test Execution Steps

| Step | TC Ref | Action | Expected Result |
|------|--------|--------|-----------------|
| P01-01 | TC-P01 | Inspect filter bar elements | Role dropdown with "All Roles" / "Driver" / "Helper" / "Both" |
| P01-02 | TC-P01 | Inspect Staff dropdown | Lists all 6 staff as "Name (Role)" |
| P01-03 | TC-P01 | Inspect Route dropdown | Lists active routes |
| P01-04 | TC-P01 | Verify Date range picker field | Shows daterangepicker with calendar icon |
| P01-05 | TC-P01 | Verify Filter button | Button with filter icon |
| P01-06 | TC-P01 | Verify Reset button | Button with redo/refresh icon |
| P02-01 | TC-P02 | Read Total Staff KPI | Shows "6" (box with primary background) |
| P02-02 | TC-P02 | Read Avg Attendance KPI | Matches computed average (success background) |
| P02-03 | TC-P02 | Read Avg Performance Score KPI | Matches computed average (warning background) |
| P02-04 | TC-P02 | Read Excellent Performers KPI | Count of staff with score >= 90 (info background) |
| P03-01 | TC-P03 | Observe doughnut chart | 5 colored segments visible |
| P03-02 | TC-P03 | Hover over green segment | Tooltip: "Excellent (90+): 1 (17%)" |
| P03-03 | TC-P03 | Hover over red segment | Tooltip: "Poor (<60): 1 (17%)" |
| P03-04 | TC-P03 | Verify doughnut cutout | Center hole visible (cutout: '60%') |
| P04-01 | TC-P04 | Observe scatter chart | 6 points on grid, color-coded by performance tier |
| P04-02 | TC-P04 | Hover highest point | Tooltip shows staff name, 100% attendance, 100 score |
| P04-03 | TC-P04 | Hover lowest point | Tooltip shows staff name, low attendance, low score |
| P04-04 | TC-P04 | Verify X-axis label | "Attendance Rate (%)" |
| P04-05 | TC-P04 | Verify Y-axis label | "Performance Score" |
| P04-06 | TC-P04 | Verify axis ranges | X: 0-100, Y: 0-100 |
| P05-01 | TC-P05 | Observe role bar chart | "Drivers" and "Helpers" groups on X-axis |
| P05-02 | TC-P05 | Verify 4 datasets per group | Avg Performance (blue), Avg Attendance (green), Avg Trips (yellow), Avg Delay (red) bars |
| P06-01 | TC-P06 | Verify Staff column | Avatar circle + staff name + role subtitle |
| P06-02 | TC-P06 | Verify Role column | Badge: Driver=primary (blue), Helper=info (teal) |
| P06-03 | TC-P06 | Verify Attendance column | Progress bar + percentage; color by threshold |
| P06-04 | TC-P06 | Verify Trips Handled column | Integer centered in cell |
| P06-05 | TC-P06 | Verify Avg Delay column | Badge with minutes; color by threshold |
| P06-06 | TC-P06 | Verify Incidents column | Badge; green=0, red>=1 |
| P06-07 | TC-P06 | Verify Performance column | Progress bar + score; color by tier |
| P06-08 | TC-P06 | Verify Status column | Badge with status text; color by tier |
| P07-01 | TC-P07 | Select Role = "Driver", click Filter | Table shows only Driver rows (3 rows); charts recalculate |
| P07-02 | TC-P07 | Verify Total Staff KPI updated | Shows "3" |
| P08-01 | TC-P08 | Select Role = "Helper", click Filter | Table shows only Helper rows (3 rows) |
| P08-02 | TC-P08 | Verify Role badges all "info" | All role badges show Helper style |
| P09-01 | TC-P09 | Select Role = "Both" (default), click Filter | All 6 staff rows visible |
| P10-01 | TC-P10 | Select specific staff from dropdown, click Filter | Single row for selected staff |
| P10-02 | TC-P10 | Verify charts show 1 data point | Doughnut: single segment; Scatter: single point |
| P11-01 | TC-P11 | Click date range field, select "Last 7 Days" | Form auto-submits; metrics recalculate |
| P11-02 | TC-P11 | Verify hidden from_date/to_date updated | Values reflect last 7 days |
| P12-01 | TC-P12 | Locate toggle button group | "Bar" (active) and "Radar" buttons visible |
| P12-02 | TC-P12 | Click "Radar" toggle | Chart redraws as radar with 5 axes |
| P12-03 | TC-P12 | Verify radar axes labels | Performance, Attendance, Trips, Delay, Efficiency |
| P13-01 | TC-P13 | Click "Bar" toggle | Chart redraws as grouped bar |
| P14-01 | TC-P14 | Find staff A (Excellent) | Status badge: `bg-success` "Excellent" |
| P15-01 | TC-P15 | Find staff B (Good) | Status badge: `bg-info` "Good" |
| P16-01 | TC-P16 | Find staff C (Average) | Status badge: `bg-warning` "Average" |
| P17-01 | TC-P17 | Find staff D (Needs Improvement) | Status badge: `bg-danger` "Needs Improvement" |
| P18-01 | TC-P18 | Find staff E (Poor) | Status badge: `bg-secondary` "Poor" |
| P19-01 | TC-P19 | Create 6 more staff (12 total), reload | Paginator shows 2 pages; page 1 has 10 rows |
| P19-02 | TC-P19 | Click page 2 | URL: `?page_driver=2`; rows 11-12 show |
| P20-01 | TC-P20 | Role=Driver + 12 drivers total | Page 1: 10 drivers; page 2: 2 drivers |
| P20-02 | TC-P20 | Navigate to page 2 | Role filter persists in URL |
| P22-01 | TC-P22 | Apply Role=Driver filter, click Reset | URL cleans; all filters return to defaults |
| P23-01 | TC-P23 | Verify Staff A attendance progress bar | Width = 100%, `bg-success` |
| P24-01 | TC-P24 | Verify Staff E attendance progress bar | Width = 40%, `bg-danger` |
| P25-01 | TC-P25 | Open Staff dropdown | Options show "John Doe (Driver)" format |
| P26-01 | TC-P26 | Select Staff B + Role=Driver | 1 row for Staff B |
| P27-01 | TC-P27 | Date range = Last 30 days | Metrics computed for 30-day window |
| P28-01 | TC-P28 | Date range = custom 2-week window | Metrics constrained to that window |
| P29-01 | TC-P29 | Select Staff, change Role | Both filters applied; intersection of criteria |
| P30-01 | TC-P30 | Role=Driver + Last 7 Days | Driver metrics for 7-day window |

### 8.3 Negative Test Execution Steps

| Step | TC Ref | Action | Expected Result |
|------|--------|--------|-----------------|
| N01-01 | TC-N01 | Delete all DriverHelper records, reload tab | Table: "No driver performance data found"; charts show empty/zero state |
| N02-01 | TC-N02 | Create staff G with 50% att, 0 trips, 0 incidents | Score = `50*0.4 + 100*0.3 + 100*0.2 + 0` = 70.0 → Average badge |
| N03-01 | TC-N03 | Set role=Invalid in URL query, submit | No filter applied; all staff shown |
| N04-01 | TC-N04 | Set role=empty, submit | No filter applied; all staff shown |
| N05-01 | TC-N05 | Remove staff_id from query entirely | No filter applied; all staff shown |
| N06-01 | TC-N06 | Set staff_id= (empty string) in URL | No filter applied; all staff shown |
| N07-01 | TC-N07 | Set staff_id=0 in URL | `!empty(0)` = false → no filter → all staff |
| N08-01 | TC-N08 | Remove permission from role, reload page | Tab not visible in nav; body not rendered |
| N09-01 | TC-N09 | Remove `tenant.transport.viewAny` | 403 on `/transport/transport-report` |
| N10-01 | TC-N10 | Logout, navigate to URL | Redirected to login |
| N11-01 | TC-N11 | Clear from_date/to_date, submit | Defaults to current month start/end |
| N18-01 | TC-N18 | Set all staff `is_active = 0` | Empty table (all excluded by `->active()`) |
| N19-01 | TC-N19 | staff_id= in query | Ignored → all staff shown |
| N20-01 | TC-N20 | staff_id=0 in query | Ignored → all staff shown |
| N21-01 | TC-N21 | staff_id=99999 (non-existent) | Empty table |
| N22-01 | TC-N22 | role="1' OR '1'='1" in URL | `in_array()` returns false → no filter → all staff |
| N23-01 | TC-N23 | Create staff with XSS name | Name displayed as text; script not executed |
| N26-01 | TC-N26 | Click another tab before AJAX completes | Current tab content disappears; new tab loads |
| N27-01 | TC-N27 | Disconnect network, apply filter | Error: "Failed to load charts." alert |

### 8.4 Destructive Test Execution Steps

| Step | TC Ref | Action | Expected Result |
|------|--------|--------|-----------------|
| D01-01 | TC-D01 | Insert 5000 DriverHelper records | Page loads; pagination shows 500 pages of 10 |
| D02-01 | TC-D02 | Delete all attendance records | All staff: attendance_rate = 0 |
| D03-01 | TC-D03 | Delete all TptTrip records | All staff: trips_handled = 0, avg_delay = 0 |
| D04-01 | TC-D04 | Create 3 staff named "John Doe" | Table shows 3 identical names |
| D05-01 | TC-D05 | Make all staff scores >= 90 | Doughnut: 100% green; scatter: all green; table: all Excellent |
| D06-01 | TC-D06 | Make all staff scores < 60 | Doughnut: 100% red; scatter: all red; table: all Poor |
| D07-01 | TC-D07 | Set all trip delays to 120 min | Delay contribution = 0 for all |
| D08-01 | TC-D08 | Assign 100 trips to Staff A | trips_handled = 100; score capped at max |
| D09-01 | TC-D09 | Assign 50 incidents to Staff A | Badge: red "50"; incident contribution = 0 |
| D15-01 | TC-D15 | Create 500 attendance records for Staff A | attendance_rate computed across 500 records |
| D16-01 | TC-D16 | Create 1000 trips for Staff A | trips_handled = 1000; `min(5000, 100) * 0.1` = 10 max |
| D17-01 | TC-D17 | All 10 staff named identically | Table: 10 identical name rows; no distinction |
| D18-01 | TC-D18 | Set date range to full year | All records for full year processed |
| D20-01 | TC-D20 | All attendance = "Absent" for all staff | attendance_rate = 0 for all |
| D21-01 | TC-D21 | All attendance = "Half Day" for all staff | attendance_rate = 0 (Half Day ≠ Present) |
| D22-01 | TC-D22 | 80% attendance, 0 trips | Score = `32 + 30 + 20 + 0` = 82 → Good |
| D23-01 | TC-D23 | Trips exist but no reaching_time | Delay = 0 for those trips |
| D24-01 | TC-D24 | Refresh browser mid-AJAX | Page reloads cleanly; no partial state |
| D25-01 | TC-D25 | Rapidly click filter 3 times | Last response wins; intermediate discarded |

### 8.5 Data Integrity Verification Steps

| Step | TC Ref | Action | Expected Result |
|------|--------|--------|-----------------|
| DI01-01 | TC-DI01 | Staff A: 10 attendance days, 8 Present | attendance_rate = 80.0% |
| DI02-01 | TC-DI02 | Staff A: 5 trips, all 0 delay | avg_delay = 0; trips_handled = 5 |
| DI03-01 | TC-DI03 | Staff A: 0 incidents | incidents = 0 |
| DI04-01 | TC-DI04 | Perfect Staff: 100% att, 0 delay, 0 incidents, 20 trips | score = `40 + 30 + 20 + 10` = 100.0 |
| DI07-01 | TC-DI07 | Duplicate attendance for same date | `count()` double-counts date |

---

## 9. Performance Considerations

| Area | Concern | Impact | Mitigation |
|------|---------|--------|------------|
| Eager loading | 4 `with()` calls per staff query | 5 total queries (1 parent + 4 children) | Already optimal — single query per relation |
| Collection processing | `->get()->map()` processes all in PHP | Memory usage grows with staff count | Acceptable for < 5000 records |
| In-memory avg computation | `avg()`, `sum()`, `count()` on Collection | O(n) per metric | Only 4 metrics; negligible impact |
| Chart rendering | Chart.js processes all staff points | Client-side only | No server impact |
| Pagination | `paginateCollection()` on already-loaded collection | All data loaded into memory before pagination | **Potential bottleneck** at 10k+ records |
| Multiple AJAX calls | 2 parallel calls per tab (charts + table) | Double server load per tab view | Acceptable; requests are lightweight |
| Daterangepicker | CDN: moment.js + daterangepicker.css | ~100KB extra load | Browser cached after first load |
| Chart.js | CDN: chart.js full library | ~200KB extra load | Browser cached |
| No DB pagination | `->get()` then `paginateCollection()` | All rows fetched from DB regardless of page | **Gap**: Should use DB pagination for large datasets |
| Blade rendering | `@json($collection->toArray())` serializes all data | JSON size grows with staff count | Only sent once in charts section |
| Tab loading strategy | Lazy load on first tab click | Only active tab data fetched | Non-visible tabs not loaded |

### 9.1 Optimization Recommendations

| # | Issue | Recommendation | Priority |
|---|-------|---------------|----------|
| 1 | In-memory pagination | Replace `->get()->paginateCollection()` with `->paginate()` at DB level for large datasets | Medium |
| 2 | Duplicate PHP/JS data prep `$excellentCount` | Compute once in PHP, pass to JS as single variable | Low |
| 3 | No debounce on filter | Add `setTimeout` debounce (300ms) on filter form submit | Low |
| 4 | Chart.resize() on every window resize | Debounce resize handler to 100ms | Low |
| 5 | `roleChart.destroy()` + recreate on toggle | Cache both chart configs; use `chart.update()` instead of destroy+create | Low |

---

## 10. Security Checklist

| Check | Status | Evidence / Notes |
|-------|--------|------------------|
| Gate::authorize on index() | ✅ | Line 36: `Gate::authorize('tenant.transport.viewAny')` |
| Blade @can on tab visibility | ✅ | Hub line 14: `'permission' => 'tenant.driver-performance.viewAny'` |
| Blade @can on tab body | ✅ | Hub line 35: `@can('tenant.driver-performance.viewAny')` wrapping `@include` |
| Permission string matches permissionslist.php | ✅ | `tenant.driver-performance.viewAny` (hyphens, tenant prefix) |
| No raw SQL injection in filters | ✅ | All `where()` use Eloquent parameter binding |
| `in_array()` validates role enum before use | ✅ | Line 745: `in_array($filters['role'], ['Driver', 'Helper', 'Both'])` |
| `isset()` guard prevents undefined key access | ✅ | Line 744: `isset($filters['staff_id']) && !empty()` |
| No mass assignment vulnerability | ✅ | No `create()`/`update()` operations in report controller |
| CSRF protection on AJAX | ✅ | GET requests only (no state mutation) |
| Data scoped to active records | ✅ | `->active()` scope on `DriverHelper::query()` |
| XSS protection via Blade escaping | ✅ | All output uses `{{ }}` (auto-escaped) |
| No sensitive data exposure | ✅ | Only staff name, role, performance metrics — no PII/credentials |
| Private methods not route-accessible | ✅ | `buildDriverPerformanceSection()`, `getDriverPerformanceReport()`, `calculatePerformanceScore()` are all `private` |
| Chart.js from CDN with integrity | ❌ | No `integrity` hash on CDN script tag — supply chain risk |
| Daterangepicker from CDN | ❌ | No integrity hash on CDN links |

---

## 11. Known Bugs & Gap Analysis

| Bug/Gap ID | Severity | Description | Impact | Recommendation |
|------------|----------|-------------|--------|---------------|
| BUG-01 | Medium | `route_id` filter passed in `$reqFilters` but NOT consumed by `getDriverPerformanceReport()` | Route filter in filter bar does nothing for driver-performance tab | Either consume `route_id` by filtering trips by route, or remove the Route dropdown from the filter bar |
| BUG-02 | Medium | `driver_id` vs `staff_id` key mismatch | `$reqFilters['driver_id']` (line 49) set but never used; `getDriverPerformanceReport()` expects `$filters['staff_id']` but it's not in `$reqFilters` | Rename to `staff_id` or add mapping layer |
| BUG-03 | Low | `$excellentCount` computed twice in same view | Lines 14-18 (PHP template) and lines 165-169 (PHP in script block) compute same value | Consolidate to single computation |
| BUG-04 | Low | Mergeb may duplicate trips if same staff is both driver and helper on same trip | `$staff->driverTrips->merge($staff->helperTrips)` at line 755 — if trip has same `driver_id` and `helper_id` for same staff, trip duplicated | Use `->unique('id')` after merge |
| BUG-05 | Low | No `latest()` ordering in `getDriverPerformanceReport()` | Records returned in arbitrary PK order | Add `->latest()` for consistent ordering |
| BUG-06 | Medium | In-memory pagination loads ALL data | `->get()` fetches all records before pagination; no DB-level `LIMIT` | Use DB pagination for large datasets |
| BUG-07 | Low | No `integrity` hash on CDN scripts | Chart.js and daterangepicker loaded without SRI | Add integrity hashes |
| BUG-08 | Low | No debounce on filter submit | Rapid filter changes cause multiple in-flight AJAX requests | Add 300ms debounce |
| BUG-09 | Low | `$staff->incidents->count()` called twice | Line 771 AND inside `calculatePerformanceScore()` at line 949 | Pass pre-computed count to helper |
| BUG-10 | Low | `roleChart.destroy()` + full recreation on toggle | Inefficient; chart configs hardcoded twice (bar + radar) | Cache configs and use `chart.config` update |

---

## 12. Automation Checklist

| Test Type | Tool | Priority | Automatable? | Notes |
|-----------|------|----------|--------------|-------|
| Permission checks | PHPUnit Feature Test | P1 | ✅ | Test Gate::authorize throws 403 without permission |
| Data processing | PHPUnit Unit Test | P1 | ✅ | Test `calculatePerformanceScore()` with known inputs |
| Query logic | PHPUnit Feature Test | P1 | ✅ | Test `getDriverPerformanceReport()` returns correct structure |
| Filter logic | PHPUnit Feature Test | P2 | ✅ | Test role filter, staff filter, date range |
| Pagination | PHPUnit Feature Test | P2 | ✅ | Test `page_driver` paginator name and count |
| Edge cases | PHPUnit Unit Test | P2 | ✅ | Test division by zero, empty collections, null values |
| Charts rendering | Jest/Cypress | P3 | ⚠️ Partial | Test data serialization (`@json`); visual testing harder |
| AJAX loading | Laravel Dusk/Cypress | P3 | ⚠️ Partial | Test skeleton loaders appear then content loads |
| Toggle interaction | Cypress | P3 | ⚠️ Partial | Test bar/radar toggle button state |
| Browser responsiveness | Manual | P4 | ❌ | Visual testing only |

---

## 13. Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-07-22 | TC Generator | Initial comprehensive test case document |
| 1.1 | 2026-07-22 | TC Generator | Added DB schema, filter matrix, JS flow, SQL queries, in-memory pipeline, extended BIZ-DEEP to 80 conditions, added sections 6.5-6.9 with 30+ new test cases, expanded test steps, added automation checklist, bug inventory |

---

## 14. Dry-Run Formula Verification Table

### 14.1 Score Calculation Cross-Check

| Profile | Attendance % | Delay (min) | Incidents | Trips | Att Component (40%) | Delay Component (30%) | Incidents Component (20%) | Trips Component (10%) | Raw Sum | Min(100) | Expected Status |
|---------|-------------|-------------|-----------|-------|---------------------|----------------------|--------------------------|----------------------|---------|----------|-----------------|
| Star Driver A | 100.0 | 0.0 | 0 | 12 | 100*0.4 = 40.0 | 100*0.3 = 30.0 | 100*0.2 = 20.0 | 60*0.1 = 6.0 | 96.0 | 96.0 | Excellent |
| Good Driver B | 90.0 | 3.0 | 0 | 8 | 90*0.4 = 36.0 | (100-6)*0.3 = 28.2 | 100*0.2 = 20.0 | 40*0.1 = 4.0 | 88.2 | 88.2 | Good |
| Average Driver C | 80.0 | 8.0 | 1 | 6 | 80*0.4 = 32.0 | (100-16)*0.3 = 25.2 | (100-10)*0.2 = 18.0 | 30*0.1 = 3.0 | 78.2 | 78.2 | Average |
| Needs Improvement D | 70.0 | 12.0 | 2 | 4 | 70*0.4 = 28.0 | (100-24)*0.3 = 22.8 | (100-20)*0.2 = 16.0 | 20*0.1 = 2.0 | 68.8 | 68.8 | Needs Improvement |
| Poor Helper E | 40.0 | 20.0 | 5 | 2 | 40*0.4 = 16.0 | (100-40)*0.3 = 18.0 | (100-50)*0.2 = 10.0 | 10*0.1 = 1.0 | 45.0 | 45.0 | Poor |
| Perfect Helper F | 100.0 | 1.0 | 0 | 25 | 100*0.4 = 40.0 | (100-2)*0.3 = 29.4 | 100*0.2 = 20.0 | 100*0.1 = 10.0 | 99.4 | 99.4 | Excellent |
| No Trip Helper G | 50.0 | 0.0 | 0 | 0 | 50*0.4 = 20.0 | 100*0.3 = 30.0 | 100*0.2 = 20.0 | 0*0.1 = 0.0 | 70.0 | 70.0 | Average |
| High Delay Driver H | 85.0 | 30.0 | 0 | 10 | 85*0.4 = 34.0 | (100-60)*0.3 = 12.0 | 100*0.2 = 20.0 | 50*0.1 = 5.0 | 71.0 | 71.0 | Average |
| Zero Attendance Z | 0.0 | 5.0 | 3 | 0 | 0*0.4 = 0.0 | (100-10)*0.3 = 27.0 | (100-30)*0.2 = 14.0 | 0*0.1 = 0.0 | 41.0 | 41.0 | Poor |
| Boundary Test X1 | 100.0 | 50.0 | 0 | 20 | 100*0.4 = 40.0 | 0*0.3 = 0.0 | 100*0.2 = 20.0 | 100*0.1 = 10.0 | 70.0 | 70.0 | Average |
| Boundary Test X2 | 100.0 | 0.0 | 10 | 20 | 100*0.4 = 40.0 | 100*0.3 = 30.0 | 0*0.2 = 0.0 | 100*0.1 = 10.0 | 80.0 | 80.0 | Good |
| Max Score | 100.0 | 0.0 | 0 | 20+ | 40.0 | 30.0 | 20.0 | 10.0 | 100.0 | 100.0 | Excellent |

## 15. Test Environment Requirements

| Requirement | Specification |
|-------------|---------------|
| PHP Version | 8.1+ |
| Laravel Version | 10.x |
| Database | MySQL 8.0+ / MariaDB 10.6+ |
| Node/NPM | Not required (CDN-based Chart.js) |
| Browser | Chrome 90+, Firefox 88+, Edge 90+ |
| Screen Resolution | Minimum 1366x768 (table has 8 columns) |
| Internet | Required for Chart.js CDN and daterangepicker CDN |
| Storage | Module files ~2MB; seed data ~10MB |
| Memory Limit | PHP `memory_limit` >= 128MB (256MB recommended for 5000+ staff) |
| Execution Time | PHP `max_execution_time` >= 60 seconds for large datasets |

## 16. Edge Case Decision Matrix

| Input | Decision | Rationale |
|-------|----------|-----------|
| `$filters['role'] = 'Both'` | Ignore role filter | Show all roles — Both means no restriction |
| `$filters['role'] = 'Invalid'` | Ignore role filter | `in_array()` returns false; safe fallback |
| `$filters['staff_id']` not set | Ignore staff filter | `isset()` returns false; default to all |
| `$filters['staff_id'] = ''` | Ignore staff filter | `!empty('')` = false |
| `$filters['staff_id'] = 0` | Ignore staff filter | `!empty(0)` = false (PHP quirk) |
| `$totalDays = 0` | `$attendanceRate = 0` | Division guard: `$totalDays ? ... : 0` |
| `$allTrips->count() = 0` | `$avgDelay = 0` | `avg()` on empty Collection returns null → `(float) null = 0` |
| `$performanceScore > 100` | `min($score, 100)` | Cap at 100 |
| `delay = 50+ min` | `max(0, 100 - 100) = 0` | Delay component floors at 0 |
| `incidents = 10+` | `max(0, 100 - 100) = 0` | Incident component floors at 0 |
| `tripsHandled < 20` | `min(trips*5, 100)` | Linear contribution up to 20 trips |
| `tripsHandled >= 20` | `min(100, 100) = 100` | Max contribution at 20 trips |
| `reaching_time` is null | Return 0 delay | `&&` short-circuit guard |
| `sch_arrival_time` is null | Return 0 delay | `&&` short-circuit guard |
| `tripStopDetail` is null | Return 0 delay | `$trip->tripStopDetail && ...` guard |
| Attendance status != 'Present' | Not counted | [Query/Code Removed] |
| `is_active = 0` | Excluded | `->active()` scope = `where('is_active', 1)` |

---

## 17. Related Files

| File | Path | Role |
|------|------|------|
| Controller | `Modules/Transport/Http/Controllers/TransportReportController.php` | All report logic (index, builders, data methods, helpers) |
| Hub View | `Modules/Transport/resources/views/tab_module/transportreport.blade.php` | Tab container with nav-tab + AJAX JS |
| Report View | `Modules/Transport/resources/views/report/driver-attendant/index.blade.php` | Charts + Table rendering |
| Model | `Modules/Transport/Models/DriverHelper` | Staff entity with attendance/trip/incident relations |
| Model | `Modules/Transport/Models/TptTrip` | Trip entity with tripStopDetail relation |
| Model | `Modules/Transport/Models/TptTripIncidents` | Incident entity linked to personnel |
| Model | `Modules/Transport/Models/TptDriverAttendance` | Attendance entity linked to personnel |
| Permission Config | `config/permissionslist.php` | Source of truth for all permission strings |
| DDL | Transport module migrations | Schema definitions for all transport tables |
| CRUD Patterns | `rules/crud-patterns.md` | Gold-standard controller/view implementation patterns |
| Permission Rules | `rules/permission-rules.md` | Permission naming conventions and Blade guard rules |
