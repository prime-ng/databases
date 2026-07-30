# tpt_ManagementSummaryReport_TcList

## Module: Transport → Transport Report → Management Summary

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | Transport |
| Tab Group | Transport Report |
| Feature | Management Summary (Dashboard) |
| URL(s) | `/transport-report?active_tab=management-dashboard` (page load), AJAX: `GET /transport-report?active_tab=management-dashboard&section=charts` (table section returns "not available" message) |
| Controller | `Modules\Transport\Http\Controllers\TransportReportController` |
| Tab Builder Method | `buildDashboardSection()` (line 175) |
| Data Methods | `getManagementDashboard()` (line 863), `getRouteReport()` (line 561), `getTripExecutionReport()` (line 680), `getDriverPerformanceReport()` (line 735), `getStudentBoardingReport()` (line 905), `getFinanceLeakageReport()` (line 794), `getCostMaintenanceReport()` (line 835) |
| Hub View | `transport::tab_module.transportreport` |
| View | `transport::report.management-dashboard.index` |
| Blade Path | `Modules/Transport/resources/views/report/management-dashboard/index.blade.php` |
| Default Active Tab | `route-performance` |
| Trigger Tab ID | `management-dashboard` |
| Permission | `tenant.management-dashboard.viewAny` (permissionslist.php line 344) |
| Permission Group | `management-dashboard` → full CRUD (14 actions) |
| Gate Check | `Gate::authorize('tenant.transport.viewAny')` in `index()` — then tab visibility via blade `@can('tenant.management-dashboard.viewAny')` |
| Export | Not implemented |
| Table Section | Returns message: "Table view is not available for Management Dashboard." |
| Chart Section | 3 charts: Financial Overview (doughnut), Leakage Analysis (bar), Cost Breakdown (bar) |
| KPI Cards | 8 total — Row 1: Routes, Utilization, Profit/Loss, Leakage — Row 2: Trips, Boarded Students, Staff, Boardings |
| Performance Cards | 3 cards: Trip Performance, Driver Performance, Boarding Summary |
| Finance Summary Row | 4 metrics: Fee Assigned, Fee Collected, Total Balance, Total Leakage |
| Chart.js Version | Via CDN: `cdn.jsdelivr.net/npm/chart.js` |
| Date Picker | Daterangepicker via CDN with moment.js |
| AJAX Mechanism | `loadTabSection()` JS function — separate calls for charts and table |
| Pagination | Not applicable — no table on this tab |

---

## 2. Pre-conditions (PC)

### PC-01: Required Permission
- User must have `tenant.management-dashboard.viewAny` permission assigned via role
- Without it: tab hidden in nav, 403 if directly accessed
- Source: blade line 44 `@can('tenant.management-dashboard.viewAny')` + permissionslist.php line 344

### PC-02: Data Dependency
- Requires data from ALL 7 data sources:
  1. `getRouteReport()` — route objects with allocations, boardings, delays
  2. `getTripExecutionReport()` — trip objects with status, completion rate, delays
  3. `getDriverPerformanceReport()` — driver/staff objects with attendance, trips, incidents
  4. `getStudentBoardingReport()` — boarding log objects with completion, safety flags
  5. `getFinanceLeakageReport()` — student academic sessions with payments, fees, balances
  6. `getCostMaintenanceReport()` — vehicle objects with fuel/maintenance costs
  7. `getManagementDashboard()` — aggregate KPI data (routes, boardings, revenue, costs)

### PC-03: Academic Session Requirement
- Requires `StudentAcademicSession` records with `is_current = 1` for default fallback
- Without this: `getManagementDashboard()` line 865 returns `null` for `$academicSessionId`
- Filter dropdown populated via `getFilterData()` line 350: `StudentAcademicSession::distinct('academic_session_id')->with('academicSession')->get()`

### PC-04: Financial Data Requirement
- Revenue: Requires `StudentPayLog` records with `module_name = 'Transport'` (line 878)
- Costs: Requires `TptVehicleFuel` AND `TptVehicleMaintenance` both with `status = 'Approved'` (lines 883-888)

### PC-05: Route & Boarding Data Requirement
- Total Routes: Requires `Route` model with `studentAllocationsAll.studentSessions` relation matching academic session (line 868-870)
- Total Boardings: Requires `StudentBoardingLog` with `boarding_time NOT NULL` and trip_date in date range (lines 872-876)

### PC-06: Filter Data Availability
- `getFilterData()` loads: routes, vehicles, shifts, academic sessions, stops, drivers, staff, roles, classes, students, notification types
- All must be seeded for filter dropdowns to render
- Academic session filter defaults to empty string (line 738: `<option value="">All Sessions</option>`)

### PC-07: Controller Route Registration
- Route: `management-dashboard` tab handled via `buildDashboardSection()` in `loadTabSection()` match block (line 85)
- Hub route: `Route::resource('transport-report', TransportReportController::class)` — single resourceful controller
- No custom routes for management-dashboard specifically

### PC-08: JavaScript Dependencies
- jQuery required (used for AJAX, DOM manipulation)
- Chart.js required (3 charts render)
- moment.js + daterangepicker required for date filter
- All loaded via CDN in hub view (transportreport.blade.php lines 68-71)

### PC-09: Blade Section Structure
- Section `charts`: Renders all KPI cards, charts, performance cards, finance summary (line 106)
- Section `table`: Returns "not available" message (line 710-715)
- No section (initial load): Renders filter bar + skeleton loaders (lines 717-773)

### PC-10: Environment Prerequisites
- Tenant context must be established (multi-tenant app)
- Database migrations must be up-to-date for all tpt_* tables
- Academic sessions must be created and active

---

## 3. Default Data Load (DL)

### DL-01: Page Initial Load (no section)
| Component | Content |
|-----------|---------|
| Filter Bar | Date range picker + Academic Session dropdown |
| Charts Container | Spinner loader in `#management-dashboard-charts` |
| Table Container | Spinner loader in `#management-dashboard-table` |
| JavaScript | `loadTabSection('management-dashboard', 'charts')` + `loadTabSection('management-dashboard', 'table')` fired on page load |

### DL-02: Charts Section Load (AJAX response)
| Component | Content |
|-----------|---------|
| KPI Row 1 | 4 cards: Total Routes, Avg Utilization %, Net Profit/Loss (₹), Leakage Cases |
| KPI Row 2 | 4 cards: Total Trips, Boarded Students, Total Staff, Total Boardings |
| Financial Overview Chart | Doughnut chart with Revenue / Costs / Net Profit or Loss segments |
| Leakage Analysis Chart | Bar chart: Partial Payment / Unpaid / Total cases |
| Cost Breakdown Chart | Bar chart: Fuel / Maintenance / Other Costs / Total Costs / Revenue |
| Trip Performance Card | Completion rate progress bar, avg delay, safe/risk trip counts |
| Driver Performance Card | Avg performance score, trips handled, total staff, incidents |
| Boarding Summary Card | Boarding completion rate, total boardings, completed count, safety risks |
| Finance Summary Row | Fee Assigned, Fee Collected, Total Balance, Total Leakage amounts + Paid/Partial/Unpaid badges |

### DL-03: Table Section Load (AJAX response)
| Component | Content |
|-----------|---------|
| Message | "Table view is not available for Management Dashboard." with table icon |
| Status | Static HTML — no data queries executed for table section |

### DL-04: Default Values When No Data
| Variable | Default | Source |
|----------|---------|--------|
| `$dashboardData` | `['total_routes'=>0,'total_boardings'=>0,'revenue'=>0,'costs'=>0,'net_profit'=>0,'profit_loss'=>'Loss']` | Blade @php block line 3-10 |
| `$summary` | `(object)['total_routes'=>0,'total_students'=>0,'boarded_students'=>0,'avg_pickup_delay'=>0]` | Blade @php block line 13-18 |
| `$tripSummary` | `(object)['total_trips'=>0,'safe_trips'=>0,'risk_trips'=>0,'avg_completion'=>0,'avg_delay'=>0]` | Blade @php block line 21-27 |
| `$driverSummary` | `(object)['total_staff'=>0,'avg_performance'=>0,'total_trips'=>0,'total_incidents'=>0]` | Blade @php block line 30-35 |
| `$boardingSummary` | `(object)['total'=>0,'completed'=>0,'safety_risks'=>0,'completion_rate'=>0]` | Blade @php block line 38-43 |
| `$paidVsUnpaid` | `['paid'=>0,'unpaid'=>0,'partial'=>0]` | Blade @php block line 46 |
| `$leakageSummary` | `['with_leakage'=>0,'without_leakage'=>0,'total'=>0]` | Blade @php block line 47 |
| `$totalFeeAssigned` | `0` | Blade @php block line 48 |
| `$totalFeeCollected` | `0` | Blade @php block line 49 |
| `$totalBalance` | `0` | Blade @php block line 50 |

### DL-05: Chart.js Initialization Defaults
| Chart | Type | Labels | Data Source |
|-------|------|--------|-------------|
| Financial Overview | Doughnut | Revenue, Costs, Net Profit/Loss | `$revenue`, `$costs`, `abs($net)` |
| Leakage Analysis | Bar | Partial Payment, Unpaid, Total | `$partialPaymentCount`, `$unpaidCount`, `$leakageCount` |
| Cost Breakdown | Bar | Fuel, Maintenance, Other Costs, Total Costs, Revenue | `$fuelCost`, `$maintenanceCost`, `$otherCosts`, `$costs`, `$revenue` |

### DL-06: Date Range Default
- From: `now()->startOfMonth()->toDateString()` (first day of current month)
- To: `now()->endOfMonth()->toDateString()` (last day of current month)
- Source: `parseDateRange()` line 334-335 when no `dates` param provided

---

## 4. Test Data Strategy (TD)

### TD-01: Core Data Requirements
| Table | Minimum Records | Key Fields |
|-------|-----------------|------------|
| `routes` | 3-5 active routes | `name`, `is_active=1` |
| `tpt_student_allocations_jnt` | 10+ allocations | `pickup_route_id`, `drop_route_id`, `student_session_id` |
| `student_academic_sessions` | 2 sessions (1 current) | `is_current=1` on one |
| `student_boarding_logs` | 20+ logs (half completed, half partial) | `boarding_time`, `unboarding_time`, `trip_date` |
| `student_pay_logs` | 5+ transport payments | `module_name='Transport'`, `amount`, `log_date` |
| `tpt_vehicle_fuel` | 3+ approved fuel records | `status='Approved'`, `cost`, `date` |
| `tpt_vehicle_maintenance` | 3+ approved maintenance | `status='Approved'`, `cost`, `maintenance_initiation_date` |
| `tpt_trips` | 10+ trips (mix SAFE and RISK) | `trip_date`, `trip_status` |
| `driver_helpers` | 3+ drivers/helpers | `role`, `is_active=1` |
| `tpt_trip_incidents` | 2+ incidents | `incident_time` in range |
| `vehicles` | 3+ active vehicles | `capacity` |

### TD-02: KPI Validation Data
| KPI | Seed Strategy | Expected Calculation |
|-----|--------------|---------------------|
| Total Routes | Count routes with allocations in session | [Query/Code Removed] |
| Revenue | Sum of StudentPayLog where module='Transport' | `StudentPayLog::sum('amount')` |
| Costs | Sum of approved fuel + maintenance costs | `Fuel::sum('cost') + Maintenance::sum('cost')` |
| Net Profit | revenue - costs | Positive, negative, zero scenarios |
| Total Trips | Count of trips in date range | `TptTrip::count()` |
| Safe Trips | Trips where boarding == unboarding | `where('trip_status','SAFE')->count()` |
| Risk Trips | Trips where boarding != unboarding | `where('trip_status','RISK')->count()` |
| Driver Performance | Weighted formula | `attendance*0.4 + delay*0.3 + incidents*0.2 + trips*0.1` |

### TD-03: Leakage Test Data Matrix
| Scenario | Boardings | Fee | Payments | Expected Leakage Flag |
|----------|-----------|-----|----------|----------------------|
| Full Compliance | >0 | 1000 | 1000 | No Leakage |
| No Payment | >0 | 1000 | 0 | No Payment |
| Partial Payment | >0 | 1000 | 500 | Partial Payment |
| No Attendance | 0 | 1000 | >0 | No Attendance |
| Zero Fee | >0 | 0 | 0 | No Leakage (empty) |
| Multiple Flags | >0 | 1000 | 200 | Partial Payment |

### TD-04: Trip Performance Scenarios
| Scenario | Boarding Count | Unboarding Count | Expected Status |
|----------|---------------|------------------|-----------------|
| Perfect Match | 20 | 20 | SAFE |
| Mismatch | 20 | 15 | RISK |
| Zero Boardings | 0 | 0 | SAFE |
| Partial Unboarding | 15 | 10 | RISK |

### TD-05: Financial Edge Cases
| Scenario | Revenue | Costs | Net | Expected Label |
|----------|---------|-------|-----|---------------|
| Profit | 100000 | 60000 | 40000 | "Net Profit" (green) |
| Loss | 50000 | 80000 | -30000 | "Net Loss" (red) |
| Break Even | 75000 | 75000 | 0 | "Net Profit" (green) — `0 >= 0` = true |
| Zero Activity | 0 | 0 | 0 | "Net Profit" (green, zero) |

### TD-06: Chart Data Scenarios
| Scenario | Revenue | Costs | Net | Partial | Unpaid | Leakage |
|----------|---------|-------|-----|---------|--------|---------|
| Full Data | 500000 | 300000 | 200000 | 5 | 3 | 10 |
| Only Revenue | 500000 | 0 | 500000 | 0 | 0 | 0 |
| Only Costs | 0 | 300000 | -300000 | 2 | 1 | 3 |
| Zero All | 0 | 0 | 0 | 0 | 0 | 0 |

### TD-07: Driver Performance Edge Cases
| Scenario | Attendance | Avg Delay | Incidents | Trips | Expected Score |
|----------|-----------|-----------|-----------|-------|---------------|
| Excellent | 100% | 0 min | 0 | 20 | 90-100 |
| Poor Attendance | 50% | 10 min | 2 | 5 | 50-65 |
| High Incidents | 90% | 5 min | 5 | 15 | 55-70 |
| Zero Activity | 0% | 0 min | 0 | 0 | 0 |

---

## 5. Business Conditions

### 5.1 Database Conditions (DB)

| DB ID | Condition | Table/Column | Detail | Impact |
|-------|-----------|-------------|--------|--------|
| DB-01 | `student_academic_sessions.is_current = 1` not set for any record | `student_academic_sessions` | `getManagementDashboard()` line 865 returns null → no session filter applied | All KPIs calculated without academic session scope |
| DB-02 | `student_academic_sessions` has multiple `is_current = 1` | `student_academic_sessions` | `value()` returns first match only | Only first current session used |
| DB-03 | `student_pay_logs.module_name` value not `'Transport'` | `student_pay_logs` | Revenue query filters by `module_name = 'Transport'` (line 878) | Non-transport payments excluded from revenue |
| DB-04 | `tpt_vehicle_fuel.status` not `'Approved'` | `tpt_vehicle_fuel` | Cost query filters `status = 'Approved'` (line 883) | Pending/rejected fuel costs excluded |
| DB-05 | `tpt_vehicle_maintenance.status` not `'Approved'` | `tpt_vehicle_maintenance` | Cost query filters `status = 'Approved'` (line 886) | Pending/rejected maintenance costs excluded |
| DB-06 | `student_boarding_logs.boarding_time` IS NULL | `student_boarding_logs` | Total boardings count filters `whereNotNull('boarding_time')` (line 875) | Only confirmed boardings counted |
| DB-07 | `routes.is_active = 0` | `routes` | `getRouteReport()` uses `->active()` scope (line 574) | Inactive routes excluded from all KPIs |
| DB-08 | `vehicles.is_active = 0` | `vehicles` | `getCostMaintenanceReport()` uses `->active()` scope (line 838) | Inactive vehicle costs excluded |
| DB-09 | `driver_helpers.is_active = 0` | `driver_helpers` | `getDriverPerformanceReport()` uses `->active()` scope (line 747) | Inactive staff excluded |
| DB-10 | `tpt_trips.trip_date` out of date range | `tpt_trips` | [Query/Code Removed] | Trips outside range excluded |
| DB-11 | `student_boarding_logs.trip_date` out of date range | `student_boarding_logs` | [Query/Code Removed] | Boardings outside range excluded |
| DB-12 | `student_pay_logs.log_date` out of date range | `student_pay_logs` | [Query/Code Removed] | Payments outside range excluded |
| DB-13 | `tpt_vehicle_fuel.date` out of date range | `tpt_vehicle_fuel` | [Query/Code Removed] | Fuel costs outside range excluded |
| DB-14 | `tpt_vehicle_maintenance.maintenance_initiation_date` out of range | `tpt_vehicle_maintenance` | [Query/Code Removed] | Maintenance costs outside range excluded |
| DB-15 | No `tpt_student_allocations_jnt` for a route | `tpt_student_allocations_jnt` | Route excluded from `whereHas` check (line 868-869) | Route not counted in total |
| DB-16 | Route has `studentAllocationsAll` but no matching `studentSessions` | pivot | [Query/Code Removed] | Route excluded from total |
| DB-17 | `vehicles.capacity = 0` | `vehicles` | Utilization calculation: `seatingCapacity > 0` check (line 1096) | Utilization = 0% (division by zero avoided) |
| DB-18 | `tpt_trip_incidents.incident_time` NULL | `tpt_trip_incidents` | Incident count via relationship (line 741) | Incident not counted |

### 5.2 Validation Conditions (VAL)

| VAL ID | Condition | Scope | Expected Behavior |
|--------|-----------|-------|-------------------|
| VAL-01 | `academic_session_id` invalid (non-existent) | Filter | Dropdown shows option but query returns empty — no records match |
| VAL-02 | `academic_session_id` empty string | Filter | Condition `empty($filters['academic_session_id'])` — falls back to `is_current=1` (line 865) |
| VAL-03 | `from_date` > `to_date` | Date Range | Daterangepicker prevents this client-side, but server: `whereBetween` returns empty |
| VAL-04 | `from_date` / `to_date` invalid format | Date Range | [Query/Code Removed] |
| VAL-05 | `from_date` missing but `to_date` present | Date Range | `parseDateRange()` — if `dates` param absent, defaults to current month |
| VAL-06 | XSS in search/filter params | All Inputs | Blade `{{ }}` auto-escapes output |
| VAL-07 | SQL injection via filter params | All Inputs | Eloquent parameter binding prevents injection |
| VAL-08 | CSRF attack on filter form | Form Submit | No state-changing operations — GET request only |
| VAL-09 | Invalid `active_tab` value | URL | `loadTabSection()` match returns `'<p class="text-muted">Invalid tab</p>'` (line 89) |
| VAL-10 | `section` parameter missing | AJAX | `index()` checks `$section` — if empty, returns full page view (line 60) |
| VAL-11 | `section` value not `charts` or `table` | AJAX | View's `@if(request('section') === 'charts')` and `@elseif(request('section') === 'table')` — any other value falls through to `@else` (filter bar + loaders) |
| VAL-12 | Pagination page param sent | URL | Management dashboard has no pagination — page param ignored |

### 5.3 Authorization Conditions (AUTH)

| AUTH ID | Condition | Expected Behavior | Source |
|---------|-----------|-------------------|--------|
| AUTH-01 | User has `tenant.transport.viewAny` but NOT `tenant.management-dashboard.viewAny` | Tab NOT visible in nav; direct AJAX call returns 403 from `index()` | Gate at controller line 36, blade @can at line 44 |
| AUTH-02 | User has NO transport permissions | `Gate::authorize('tenant.transport.viewAny')` throws `AuthorizationException` → 403 page | Controller line 36 |
| AUTH-03 | Unauthenticated user | Redirected to login page | Laravel auth middleware |
| AUTH-04 | User has `tenant.management-dashboard.viewAny` but NOT `tenant.transport.viewAny` | 403 at controller level before tab logic runs | Controller line 36 — gate check is universal for all tabs |
| AUTH-05 | Super admin bypass | `Gate::before()` allows all — all tabs visible, all data accessible | Global Gate policy |
| AUTH-06 | AJAX request with expired session | Returns 403/redirect — AJAX error handler shows "Failed to load" message | `loadTabSection()` error callback line 197 |

### 5.4 Business Logic Conditions (BIZ)

| BIZ ID | Condition | Expected Behavior | Source |
|--------|-----------|-------------------|--------|
| BIZ-01 | Academic session filter not provided (null/empty) | Falls back to `StudentAcademicSession::where('is_current', 1)->value('academic_session_id')` | `getManagementDashboard()` line 865 |
| BIZ-02 | Net profit >= 0 | Label = "Net Profit", green styling (`text-bg-success`) | Blade line 42: `$profitLossClass = $net >= 0 ? 'success' : 'danger'` |
| BIZ-03 | Net profit < 0 | Label = "Net Loss", red styling (`text-bg-danger`) | Blade line 62 |
| BIZ-04 | Revenue = 0 and Costs = 0 | All financial KPIs show 0; profit/loss label = "Profit" (since `0 >= 0` is true) | Blade lines 55-58, 62 |
| BIZ-05 | No data in date range | All summary cards show 0; charts render with zero datasets | Defaults at blade lines 3-50 |
| BIZ-06 | Table section requested (`request('section') === 'table'`) | Returns: "Table view is not available for Management Dashboard." static div | Blade lines 710-715 |
| BIZ-07 | `partialPaymentCount == 0 && unpaidCount == 0` with `$leakageCount > 0` | Uses `$leakageCount` as default for `$partialPaymentCount` | Blade lines 101-103 |
| BIZ-08 | Net profit/loss label in chart | Chart label dynamically uses `Net Profit` or `Net Loss` based on `$net >= 0` | Blade line 505: `Net {{ $net >= 0 ? "Profit" : "Loss" }}` |
| BIZ-09 | Chart color for net segment | Uses `chartColors.success` if profit >= 0, `chartColors.danger` if loss | Blade line 515 |
| BIZ-10 | Avg utilization calculation | `$totalStudents > 0 ? ($boardedStudents / $totalStudents) * 100 : 0` | Blade line 67 |
| BIZ-11 | Other costs calculation | `max(0, $costs - $fuelCost - $maintenanceCost)` — ensures non-negative | Blade line 76 |
| BIZ-12 | Leakage iteration — `$record` is array vs object | Blade checks `is_array($record)` to access `balance` and `leakage_flag` | Blade lines 87-88 |
| BIZ-13 | Trip completion progress bar width | `min($tripSummary->avg_completion, 100)` — capped at 100% | Blade line 332 |
| BIZ-14 | Avg delay progress bar width | `min($tripSummary->avg_delay, 100)` — capped at 100% | Blade line 341 |
| BIZ-15 | Driver trips progress bar width | `min($driverSummary->total_trips, 100)` — capped at 100% | Blade line 379 |
| BIZ-16 | Boarding total progress bar width | `min($boardingSummary->total, 100)` — capped at 100% | Blade line 416 |
| BIZ-17 | Financial Overview chart — `abs($net)` for third segment | Negative net profit displayed as absolute value in chart | Blade line 509 |
| BIZ-18 | Chart tooltip format | Shows: `Label: ₹amount (percentage%)` | Blade lines 539-544 |
| BIZ-19 | Bar chart y-axis step size = 1 | Case counts as integers — stepSize enforced for integer display | Blade lines 592-594 |
| BIZ-20 | KPI card "More info" links | All 8 KPI cards link to `transport.transport-master.index` or `transport.trip-management.index` | Blade lines 118, 132, 146, 160, 177, 191, 205, 219 |
| BIZ-21 | Financial Overview footer displays Revenue vs Total Costs | Revenue (green) on left, Total Costs (red) on right | Blade lines 243-251 |
| BIZ-22 | Leakage Analysis footer displays total leakage amount | Badge + bold text: `Total Leakage: ₹amount` | Blade lines 272-275 |
| BIZ-23 | Cost Breakdown footer displays Fuel/Maintenance/Other | 3-column layout with color-coded badges | Blade lines 299-311 |
| BIZ-24 | Finance Summary badges for Paid/Partial/Unpaid | 3 badges: `bg-success` for Paid, `bg-warning` for Partial, `bg-danger` for Unpaid | Blade lines 462-477 |
| BIZ-25 | Net Profit KPI card shows absolute value | `number_format(abs($net), 0)` — always positive display | Blade line 142 |
| BIZ-26 | Window resize event for charts | Debounced resize handler (250ms) calls `chart.resize()` on all 3 charts | Blade lines 693-707 |
| BIZ-27 | Boarding completion rate calculation | `(completed / total) * 100` with guard for zero total | Blade lines 209-213 |
| BIZ-28 | Driver performance status class mapping | >=90: Excellent (success), >=80: Good (info), >=70: Average (warning), >=60: Needs Improvement (danger), else: Poor (secondary) | Controller lines 773-786 |
| BIZ-29 | `profit_loss` string in `$dashboardData` | Determined by `$net >= 0 ? 'Profit' : 'Loss'` — used in blade but overridden by inline `$net >= 0` check | Controller line 898 |
| BIZ-30 | Empty `$financeLeakage` collection | Blade `foreach` on line 86 simply doesn't iterate | Defaults to zero counts |
| BIZ-31 | Boarding Summary safety_risks display | Shows count in red text, no progress bar | Blade lines 425-428 |
| BIZ-32 | Driver Performance incidents display | Shows count in muted small text | Blade lines 387-389 |

### 5.5 Deep Business Logic Conditions (BIZ-DEEP)

| BIZ-DEEP ID | Condition | Expected Behavior | Technical Detail |
|-------------|-----------|-------------------|------------------|
| BIZ-DEEP-01 | `$routeReports` empty collection (no routes) | All `$summary` properties = 0 (count, sum, avg of empty = 0) | `buildDashboardSection()` line 188-192 |
| BIZ-DEEP-02 | `$tripExecutionReports` empty | `$tripSummary` all 0, `avg_completion` = 0 | `avg('completion_rate')` on empty = 0 |
| BIZ-DEEP-03 | `$driverPerformanceReports` empty | `$driverSummary` all 0, `avg_performance` = 0 | `avg('performance_score')` on empty = 0 |
| BIZ-DEEP-04 | `$studentBoardingReports` empty | `$boardingSummary` all 0, `completion_rate` = 0 | Count=0 triggers ternary: `0 ? round(...) : 0` |
| BIZ-DEEP-05 | `$financeLeakage` collection empty | `prepareChartData()` returns all zeros: `paid=0, unpaid=0, partial=0, with_leakage=0` | `filter()` on empty returns empty |
| BIZ-DEEP-06 | `$costMaintenanceReport` empty | `$fuelCost=0`, `$maintenanceCost=0`, `$otherCosts = max(0, $costs-0-0)` | Blade line 74-76 |
| BIZ-DEEP-07 | `$dashboardData['revenue']` is null/not set | `floatval(null) = 0` via null coalescing | Blade line 55 |
| BIZ-DEEP-08 | `$dashboardData['costs']` not set | `floatval(0) = 0` via null coalescing | Blade line 56 |
| BIZ-DEEP-09 | `employeePayLog` joins across tenant boundary | Revenue scoped to current tenant via implicit global scope | Multi-tenant architecture |
| BIZ-DEEP-10 | Date range spans across academic session boundaries | Different sessions may have different allocation data | Academic session filter overrides date-based session inference |
| BIZ-DEEP-11 | AJAX `section=charts` called multiple times (duplicate loading) | Charts re-initialize on same canvas — Chart.js throws warning: "Canvas already in use" | No singleton guard on chart initialization |
| BIZ-DEEP-12 | `active_tab=management-dashboard` but `section` not sent | Falls through to `@else` branch — renders filter bar + skeleton loaders but charts never load | `loadTabSection()` only called by JS |
| BIZ-DEEP-13 | `$tripSummary->avg_completion` is null | `?? 0` in blade line 329 — displays "0%" | `avg()` on collection with non-numeric values returns null |
| BIZ-DEEP-14 | `$driverSummary->avg_performance` is null | `?? 0` not used in blade — displays "0/100" but progress bar: `style="width: 0%"` | Blade line 370 |
| BIZ-DEEP-15 | DashboardData profit_loss = 'Loss' but net = 0 | Blade checks `$net >= 0` independently (line 62) — overrides controller's profit_loss | Inconsistency if controller says Loss but math says break-even |
| BIZ-DEEP-16 | Chart.js CDN fails to load | Chart constructors throw ReferenceError — entire charts section breaks | No fallback for CDN failure |
| BIZ-DEEP-17 | Daterangepicker CDN fails | Date filter input stays as plain text input — form submission still works with default dates | Graceful degradation |
| BIZ-DEEP-18 | All 7 data methods called on single AJAX request | 7 separate DB query executions per chart load | Performance impact: each method may fire multiple sub-queries |
| BIZ-DEEP-19 | `getRouteReport()` calls `->active()` scope | Inactive routes excluded from summary KPI (total_routes, boarded_students) | `getManagementDashboard()` does NOT use `->active()` scope but uses `whereHas` which returns counts only |
| BIZ-DEEP-20 | `$totalBoardings` vs `$summary->boarded_students` | `$totalBoardings` = StudentBoardingLog count (unique log entries); `$summary->boarded_students` = sum of unique students per route | These are fundamentally different metrics despite similar labels |
| BIZ-DEEP-21 | Leakage amount calculation iterates ALL financeLeakage records | `$totalLeakageAmount += $balance` for any record with balance > 0 | Costly iteration — not aggregated in query |
| BIZ-DEEP-22 | Chart tooltip percentage calculation | `(context.raw / total) * 100` — if total = 0, percentage = NaN | Total of [0,0,0] = 0 → division by zero → "NaN%" in tooltip |
| BIZ-DEEP-23 | Cost breakdown: `$otherCosts = max(0, $costs - $fuelCost - $maintenanceCost)` | If fuel+maintenance > total costs, other = 0 (never negative) | Blade line 76 |
| BIZ-DEEP-24 | Finance leakage data: `$record` is array — `$record['balance']` and `$record['leakage_flag']` | `getFinanceLeakageReport()` returns array (not object) at line 817-828 | Blade must handle both array and object access |
| BIZ-DEEP-25 | Filter reset link: `url()->current()` | Resets all query params except... actually it resets ALL params including `active_tab` | Blade line 751: `href="{{ url()->current() }}"` — loses `active_tab` context on reset |
| BIZ-DEEP-26 | AJAX pagination click handler | Applied globally via `$(document).on('click', '.tab-pane .pagination a')` | WON'T fire for management dashboard — no table/pagination exists |
| BIZ-DEEP-27 | `getManagementDashboard()` uses `$filters['academic_session_id']` | If filter array key missing (not just null), uses `??` null coalescing | Line 865: `$filters['academic_session_id'] ?? StudentAcademicSession::...` |
| BIZ-DEEP-28 | Academic session dropdown shows `academicSession->name` via nested relation | Blade line 741: `$session->academicSession->name` — if relation null, throws error | Potential "Trying to get property 'name' of non-object" |
| BIZ-DEEP-29 | `$boardingSummary->completion_rate` already calculated in controller | `buildDashboardSection()` lines 206-213 — duplicate calculation also in `buildStudentBoardingSection()` | Same logic in two places — maintenance risk |
| BIZ-DEEP-30 | `$net` in blade is re-calculated as `$netProfit` from `$dashboardData['net_profit']` | But KPI card line 142 uses `abs($net)` AND line 143 uses `$net >= 0` | Consistent since `$net = $netProfit` at blade line 61 |
| BIZ-DEEP-31 | `$tripExecutionReports` contains non-standard `trip_status` values | [Query/Code Removed] | [Query/Code Removed] |
| BIZ-DEEP-32 | [Query/Code Removed] | [Query/Code Removed] | [Query/Code Removed] |
| BIZ-DEEP-33 | Blade `@php` block runs on EVERY render including table section | Even table section (which returns static message) executes @php calculations | Wasted computation — all dashboard data calculations run even when only table section requested |
| BIZ-DEEP-34 | `$costs` from `getManagementDashboard()` vs `getCostMaintenanceReport()` sum | `getManagementDashboard()` sums ALL approved fuel + maintenance; `getCostMaintenanceReport()` sums per-vehicle | Blade `$costs` (total from dashboard) used in cost breakdown chart alongside `$fuelCost`/`$maintenanceCost` (from cost report) — different data sources |
| BIZ-DEEP-35 | Date range default: current month (`now()->startOfMonth()` / `now()->endOfMonth()`) | If server TZ differs from user's TZ, date range may not match expectation | No user-specific timezone handling |
| BIZ-DEEP-36 | [Query/Code Removed] | [Query/Code Removed] | Blade iterates empty collection → all leakage counts = 0 |
| BIZ-DEEP-37 | Driver performance: `$staff->attendance->count()` = 0 causes division by zero guard | `$attendanceRate = $totalDays ? round(...) : 0` — guarded | Controller line 762 |
| BIZ-DEEP-38 | Trip completion: `$plannedBoardings` = unique student allocations count | If route has no studentAllocationsAll, `$plannedBoardings = 0` and `$completionRate = 0` | Controller line 698: `$plannedBoardings ? round(...) : 0` |
| BIZ-DEEP-39 | Cost maintenance: `$vehicle->fuelLogs->sum('cost')` loads ALL fuel logs in memory | No date filtering on fuelLogs relation in getCostMaintenanceReport() | Controller line 841 — may include fuel costs OUTSIDE report date range |
| BIZ-DEEP-40 | Management dashboard tab ID mismatch risk | Tab ID is `management-dashboard` (with hyphen) in blade, URL, and AJAX | Must match exactly across: nav-tab id, pane id, `loadTabSection()` parameter, and controller match block |
| BIZ-DEEP-41 | `loadTabSection()` sends `active_tab` in AJAX data but `loadTabSection` function also reads tab name from parameter | Both `active_tab` and tab name parameter sent — potential conflict | JS function line 152: `active_tab: tabName` — parameter name and variable are redundant |
| BIZ-DEEP-42 | AJAX error handler overwrites ALL container HTML | `container.html('<div class="alert alert-danger">Failed to load...</div>')` | Previous content (skeleton/spinner) replaced with error message — good UX but no retry mechanism |
| BIZ-DEEP-43 | `loaded` CSS class prevents duplicate tab loads | Once `$('#tab-pane').addClass('loaded')`, subsequent tab clicks skip AJAX | `loadTabSection()` not called for already-loaded tabs — data NOT refreshed on revisit |
| BIZ-DEEP-44 | Filter form submits via AJAX without page reload | `e.preventDefault()` + manual `loadTabSection()` call | URL never updates with query params — user cannot bookmark filtered state |
| BIZ-DEEP-45 | Chart.js `hoverOffset: 20` on doughnut | Visual feedback on hover — segment expands 20px outward | Standard Chart.js configuration; no functional concern |
| BIZ-DEEP-46 | `font-weight: 400` on chart labels (default Chart.js) | Labels appear lighter than surrounding UI text | Aesthetic concern only |
| BIZ-DEEP-47 | Cost breakdown chart x-axis `ticks.font.size: 11` | Smaller font for 5 category labels | Prevents label overlap on narrow screens |
| BIZ-DEEP-48 | Leakage chart y-axis `precision: 0` | Forces integer tick values — appropriate for count data | Blade line 593 |
| BIZ-DEEP-49 | All 3 charts use `maintainAspectRatio: false` | Charts stretch to fill container height (250-300px) | Responsive behavior controlled by CSS container size |
| BIZ-DEEP-50 | KPI cards use AdminLTE `small-box` component classes | `small-box text-bg-primary/info/success/warning/danger/secondary` | Consistent with AdminLTE theme; card footer contains "More info" link |

---

## 6. Test Case List

### 6.1 Positive Test Cases (P)

| TC ID | Description | Prerequisites | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|---------------|----------------|---------|---------|--------|
| TC-P01 | Tab loads with filter bar on initial page load | User has permission, seed data exists | Filter bar visible with Date Range picker + Academic Session dropdown; skeleton loaders present in charts and table containers | — | — | ⬜ |
| TC-P02 | AJAX loads KPI Row 1 with 4 cards after tab activation | Routes/allocations seeded, active session set | 4 cards displayed: Total Routes (integer), Avg Utilization (%), Net Profit/Loss (₹), Leakage Cases (integer) | — | — | ⬜ |
| TC-P03 | AJAX loads KPI Row 2 with 4 cards | Trips/boardings/staff seeded | 4 cards: Total Trips, Boarded Students, Total Staff, Total Boardings | — | — | ⬜ |
| TC-P04 | Financial Overview doughnut chart renders with correct segments | Revenue + Costs seeded ≥ 0 | Doughnut chart with 3 segments: Revenue (green), Costs (red), Net (dynamic color) | — | — | ⬜ |
| TC-P05 | Leakage Analysis bar chart renders correctly | Finance leakage data seeded | Bar chart with 3 bars: Partial Payment (warning), Unpaid (danger), Total (info) | — | — | ⬜ |
| TC-P06 | Cost Breakdown bar chart renders with 5 bars | Vehicle fuel + maintenance seeded | Bar chart with Fuel (warning), Maintenance (info), Other Costs (light), Total Costs (danger), Revenue (success) | — | — | ⬜ |
| TC-P07 | Trip Performance card shows completion rate + safe/risk counts | Trip execution data seeded (mix SAFE + RISK) | Card shows: completion rate progress bar, avg delay progress bar, safe trips count (green), risk trips count (red) | — | — | ⬜ |
| TC-P08 | Driver Performance card shows avg score + staff/incident counts | Driver performance data seeded | Card shows: avg score progress bar, trips handled progress bar, total staff count, incidents count | — | — | ⬜ |
| TC-P09 | Boarding Summary card shows completion + safety risks | Boarding data seeded (mix Completed + safety_risk=Yes) | Card shows: completion rate %, total boardings, completed count, safety risks count | — | — | ⬜ |
| TC-P10 | Finance Summary row shows all 4 metrics with badges | Finance leakage seeded (mix paid/partial/unpaid) | Fee Assigned, Fee Collected, Total Balance, Total Leakage amounts with Paid/Partial/Unpaid badges | — | — | ⬜ |
| TC-P11 | Filter by academic session recalculates all KPIs | 2+ academic sessions with different data | Selecting different session changes all KPI values, charts, and performance cards | — | — | ⬜ |
| TC-P12 | Net Profit display — positive profit (green card) | Revenue > Costs | Card shows `text-bg-success`, label "Net Profit", value with ₹ | — | — | ⬜ |
| TC-P13 | Net Profit display — negative loss (red card) | Revenue < Costs | Card shows `text-bg-danger`, label "Net Loss", value with ₹ | — | — | ⬜ |
| TC-P14 | Net Profit display — break even (green card, zero) | Revenue = Costs | Card shows `text-bg-success`, label "Net Profit", value ₹0 | — | — | ⬜ |
| TC-P15 | Filter by date range narrows data scope | Data spread across multiple months | Selecting shorter range shows fewer records; wider range shows more | — | — | ⬜ |
| TC-P16 | Tab switch from another tab to management-dashboard loads data via AJAX | Initially on route-performance tab | Clicking "Management Summary" tab triggers AJAX calls; charts + KPI cards load dynamically | — | — | ⬜ |
| TC-P17 | All 3 Chart.js tooltips show correct formatting | Data seeded | Hover: Revenue shows ₹ amount and %; Leakage shows case count; Cost shows ₹ amount | — | — | ⬜ |
| TC-P18 | Window resize triggers chart redraw | Charts loaded | Resizing browser window triggers debounced chart.resize() on all 3 charts | — | — | ⬜ |
| TC-P19 | Clean filter link resets to default date range + all sessions | Filters applied | Clicking "redo" button (`.btn-outline-secondary`) reloads page without query params | — | — | ⬜ |
| TC-P20 | Total Routes KPI matches route count with allocations | 5 routes with allocations, 2 without | KPI shows 5 (routes WITH allocations in selected session) | — | — | ⬜ |

### 6.2 Negative Test Cases (N)

| TC ID | Description | Prerequisites | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|---------------|----------------|---------|---------|--------|
| TC-N01 | No academic session with `is_current = 1` | All sessions have `is_current = 0` or null | `$academicSessionId` = null → session filter not applied → KPIs calculated without session scope | — | — | ⬜ |
| TC-N02 | No data at all in any table | Empty database | All 8 KPI cards show 0; charts render with zero datasets; all performance cards show 0/0% | — | — | ⬜ |
| TC-N03 | Table section explicitly requested via URL | Any data state | "Table view is not available for Management Dashboard." message displayed; no table rendered | — | — | ⬜ |
| TC-N04 | 403 when user lacks `management-dashboard.viewAny` | Authenticated user without this specific permission | Tab hidden in nav; if URL accessed directly, controller's Gate throws 403 | — | — | ⬜ |
| TC-N05 | Guest (unauthenticated) access | Not logged in | Redirected to login page | — | — | ⬜ |
| TC-N06 | Date range with no matching records | Data exists only outside selected range | All cards show 0; charts show zero datasets; no errors thrown | — | — | ⬜ |
| TC-N07 | Invalid `active_tab` value in URL | Any data state | Tab builder returns "Invalid tab" message or fallback to default tab | — | — | ⬜ |
| TC-N08 | Academic session ID that doesn't exist | Non-existent ID in dropdown (manually crafted URL) | No records match → all KPIs = 0 | — | — | ⬜ |
| TC-N09 | `section` = `charts` but AJAX fails (network error) | Network disconnect or server error | Error handler: container shows "Failed to load charts." alert | — | — | ⬜ |
| TC-N10 | Revenue data exists but not for Transport module | Payments with module_name != 'Transport' | Revenue KPI = 0; revenue not counted | — | — | ⬜ |
| TC-N11 | Fuel costs exist but status != 'Approved' | Fuel records with Draft/Pending status | Fuel costs excluded from cost calculations | — | — | ⬜ |
| TC-N12 | All vehicle inspections failed with no maintenance records | High failure rate, zero maintenance | `calculateRiskLevel()` returns 'HIGH' (failureRate > 30 OR maintenanceCount == 0) | — | — | ⬜ |
| TC-N13 | `from_date` after `to_date` (invalid range) | Manually crafted URL | Daterangepicker prevents client-side; server: `whereBetween` with invalid range returns empty set | — | — | ⬜ |
| TC-N14 | Filter form submitted with empty academic session AND no current session | All sessions have `is_current=0` | `$academicSessionId` = null → no session WHERE clause → all data across ALL sessions returned | — | — | ⬜ |
| TC-N15 | `partialPaymentCount == 0 && unpaidCount == 0` with `$leakageCount == 0` | No leakage data at all | Default fallback sets `$partialPaymentCount = 0` — all three values = 0 | — | — | ⬜ |
| TC-N16 | Large string in search field (XSS attempt) | `<script>alert('xss')</script>` in URL param | Blade `{{ }}` auto-escapes — param ignored by query logic (no search on dashboard) | — | — | ⬜ |
| TC-N17 | Route exists but `studentAllocationsAll` relation returns empty | Route with zero student allocations | [Query/Code Removed] | — | — | ⬜ |

### 6.3 Destructive Test Cases (D)

| TC ID | Description | Prerequisites | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|---------------|----------------|---------|---------|--------|
| TC-D01 | Rapid tab switching floods AJAX | All data seeded | Multiple simultaneous AJAX requests — last one wins; no race condition crashes page | — | — | ⬜ |
| TC-D02 | Chart.js CDN blocked/offline | Block chart.js CDN in browser devtools | Chart constructors throw ReferenceError; page renders without charts; no JS crash | — | — | ⬜ |
| TC-D03 | Extremely large dataset (10k+ records) | Seed 10000 trips, 5000 boardings, 2000 payments | Page loads but may be slow — all 7 collection methods load ALL records into memory (no pagination) | — | — | ⬜ |
| TC-D04 | Concurrent filter submissions | Rapid filter change clicks | Multiple AJAX requests in flight — last response updates UI; no duplicate chart instances | — | — | ⬜ |
| TC-D05 | Server returns 500 error on data method | Temporarily break one of the 7 query methods (e.g., invalid column) | Charts section fails to load; error message displayed; page structure intact | — | — | ⬜ |
| TC-D06 | Multiple `is_current = 1` academic sessions | 2+ sessions flagged as current | `value()` returns first only — second current session ignored | — | — | ⬜ |
| TC-D07 | Extremely long date range (5+ years) | Seed data spanning 2019-2026 | Massive dataset loaded into memory — potential memory exhaustion or timeout | — | — | ⬜ |
| TC-D08 | Simultaneous AJAX from multiple browser tabs | Same user, same URL, 3+ tabs | Each tab fires independent AJAX — no shared state or locking — possible duplicate DB load | — | — | ⬜ |
| TC-D09 | Zero-capacity vehicles with utilization calculation | `vehicles.capacity = 0` for all vehicles | `seatingCapacity > 0` check prevents division by zero → utilization = 0% | — | — | ⬜ |
| TC-D10 | Delete route while dashboard is loaded | Route deleted by another user | Dashboard data is snapshot from AJAX response — stale data persists until next reload | — | — | ⬜ |

### 6.4 Code Review Test Cases (CR)

| TC ID | Priority | Description | Expected Result | Status |
|-------|----------|-------------|-----------------|--------|
| TC-CR01 | P1 | All 7 data methods called on single tab load | `getRouteReport`, `getTripExecutionReport`, `getDriverPerformanceReport`, `getStudentBoardingReport`, `getFinanceLeakageReport`, `getCostMaintenanceReport`, `getManagementDashboard` — 7 calls per AJAX charts request | ◌ |
| TC-CR02 | P1 | Default academic session fallback | `$filters['academic_session_id'] ?? StudentAcademicSession::where('is_current', 1)->value('academic_session_id')` | ◌ |
| TC-CR03 | P1 | Revenue scoped to `module_name = 'Transport'` | `StudentPayLog::where('module_name', 'Transport')` — only transport payments counted | ◌ |
| TC-CR04 | P1 | Costs scoped to `status = 'Approved'` | `TptVehicleFuel::where('status', 'Approved')` + `TptVehicleMaintenance::where('status', 'Approved')` | ◌ |
| TC-CR05 | P1 | Table section disabled | `request('section') === 'table'` returns static "not available" view | ◌ |
| TC-CR06 | P1 | KPI defaults in blade | All summary objects have `?? (object)[...zeros]` fallbacks in @php block | ◌ |
| TC-CR07 | P2 | Duplicate completion rate calculation | `buildDashboardSection()` lines 207-213 AND `buildStudentBoardingSection()` lines 226-232 — same logic duplicated | ◌ |
| TC-CR08 | P2 | `profit_loss` in `$dashboardData` overridden by blade | Controller sets 'Profit'/'Loss' at line 898 but blade independently checks `$net >= 0` at line 62 | ◌ |
| TC-CR09 | P2 | Blade `$net = $netProfit` is redundant | `$netProfit` and `$net` hold same value — variable aliasing | ◌ |
| TC-CR10 | P2 | No pagination for dashboard | All 7 data methods loaded in-memory — `paginateCollection()` not called in `buildDashboardSection()` | ◌ |
| TC-CR11 | P2 | Leakage default fallback logic | If `partialPaymentCount == 0 && unpaidCount == 0`, blade sets `$partialPaymentCount = $leakageCount` — may be incorrect if there truly are zero cases | ◌ |
| TC-CR12 | P2 | `getManagementDashboard()` doesn't use `active()` scope for routes | Route count uses `whereHas` without `->active()` — unlike `getRouteReport()` which uses `->active()` | ◌ |
| TC-CR13 | P2 | Chart.js re-initialization on same canvas | If `loadTabSection` called twice for same tab, Chart.js creates new chart on same canvas without destroying previous instance | ◌ |
| TC-CR14 | P2 | `$otherCosts = max(0, $costs - $fuelCost - $maintenanceCost)` | If fuel/maintenance costs exceed total costs (shouldn't happen but possible), other = 0 | ◌ |
| TC-CR15 | P2 | No loading state on chart cards individually | Only container has `opacity: 0.5` — individual cards don't show skeleton/spinner during reload | ◌ |
| TC-CR16 | P3 | Filter reset button loses active_tab context | `url()->current()` resets ALL params — user returns to default tab, not management-dashboard | ◌ |
| TC-CR17 | P3 | Division by zero in chart tooltip | `let total = context.dataset.data.reduce((a, b) => a + b, 0)` then `(context.raw / total) * 100` — if total=0, result is NaN | ◌ |
| TC-CR18 | P3 | KPI card "More info" links go to generic routes | All 8 cards link to either `transport-master.index` or `trip-management.index` — no context-aware drill-down | ◌ |
| TC-CR19 | P3 | Blade `$session->academicSession->name` may throw error | If `academicSession` relation is null, accessing `->name` throws "Trying to get property of non-object" | ◌ |
| TC-CR20 | P3 | `total_routes` vs `total_routes` in management dashboard vs summary | Management dashboard returns `total_routes` via count query; `$summary->total_routes` comes from `$routeReports->count()` — both count routes but through different queries | ◌ |
| TC-CR21 | P3 | Blade `total_boardings` KPI uses `$dashboardData['total_boardings']` NOT `$summary` | KPI row 2 "Total Boardings" uses `$totalBoardings` (line 215) which comes from `getManagementDashboard()` — different source than boarded_students | ◌ |
| TC-CR22 | P2 | [Query/Code Removed] | [Query/Code Removed] | ◌ |
| TC-CR23 | P2 | No eager loading in `getManagementDashboard()` — uses `whereHas` (subquery) | Performance is fine for count queries — no N+1 risk | ◌ |
| TC-CR24 | P3 | `getCostMaintenanceReport()` scoped to active vehicles only | `Vehicle::active()` — if cost data exists for inactive vehicle, it's excluded | ◌ |
| TC-CR25 | P2 | [Query/Code Removed] | [Query/Code Removed] | ◌ |

---

## 7. CODE-TRACE

### 7.1 Route → Controller Entry



### 7.2 Hub View Renders



### 7.3 JavaScript AJAX Call



### 7.4 Tab Section Dispatcher



### 7.5 buildDashboardSection() — KPI Assembly



### 7.6 getManagementDashboard() — Core KPI Queries



### 7.7 View Rendering — Blade Logic Flow



### 7.8 Chart.js Configuration Details



### 7.9 Data Flow Summary



### 7.10 Performance Characteristics

| Aspect | Detail |
|--------|--------|
| Query Count per AJAX | 7 primary data methods + their sub-queries (eager loads) |
| In-Memory Collections | ALL records loaded into memory — no pagination on any dataset |
| Route Report Sub-queries | 5 eager loads: studentAllocationsAll, boardingLogs, tripStopDetails, trips, pickupPointRoutes |
| Driver Report Sub-queries | 4 eager loads: attendance, driverTrips, helperTrips, incidents |
| Boarding Report Processing | `->get()->map()` — Collection transformation per record |
| Finance Report Processing | `->get()->map()` — Collection with `determineLeakage()` per record |
| Cost Report Processing | `->get()->map()` — Collection with `calculateRiskLevel()` per vehicle |
| Chart.js Rendering | Client-side — 3 Chart instances created per tab activation |
| CDN Dependencies | jQuery (local assumed), Chart.js (CDN), moment.js (CDN), daterangepicker (CDN) |

---

## 8. Test Steps

### 8.1 Step-by-Step: Positive Test Execution



### 8.2 Step-by-Step: Negative Test Execution



### 8.3 Step-by-Step: Destructive Test Execution



### 8.4 Step-by-Step: Code Review Verification



---

---

## 9. Request/Response Payload Analysis

### 9.1 Initial Page Load Request



### 9.2 AJAX Charts Request



### 9.3 AJAX Table Request



### 9.4 AJAX Filter Submit Request



### 9.5 Error Response (Invalid Tab)



### 9.6 Error Response (Unauthenticated)



### 9.7 Error Response (Unauthorized — no transport.viewAny)



---

## 10. JavaScript Event Flow

### 10.1 Page Load Sequence



### 10.2 Tab Switch Sequence



### 10.3 Filter Submit Sequence



### 10.4 Date Range Change Sequence



### 10.5 Chart Rendering Sequence



### 10.6 Window Resize Handler Sequence



### 10.7 Error Recovery Sequence



---

## 11. Filter Interaction Matrix

### 11.1 Filter Behavior by Component

| Component | Academic Session Filter | Date Range Filter | Affected Data Sources |
|-----------|------------------------|-------------------|----------------------|
| KPI: Total Routes | [Query/Code Removed] | NO | [Query/Code Removed] |
| KPI: Total Boardings | YES — `whereHas('studentSession')` | YES — `whereBetween('trip_date')` | [Query/Code Removed] |
| KPI: Revenue | YES — `whereHas('student.sessions')` | YES — `whereBetween('log_date')` | [Query/Code Removed] |
| KPI: Costs | NO | [Query/Code Removed] | [Query/Code Removed] |
| KPI: Total Trips | NO (session not passed to trip report) | YES — `whereBetween('trip_date')` | [Query/Code Removed] |
| KPI: Driver Performance | NO | YES — attendance/trips/incidents date scope | `getDriverPerformanceReport()` |
| KPI: Boarding Summary | YES — `whereHas('studentSession')` | YES — `whereBetween('trip_date')` | [Query/Code Removed] |
| KPI: Finance Leakage | YES — `where('academic_session_id')` | YES — `whereBetween('log_date')` | [Query/Code Removed] |
| KPI: Cost Breakdown | NO | YES — fuel date + maintenance date | `getCostMaintenanceReport()` |
| Trip Performance Card | NO | YES | `getTripExecutionReport()` |
| Driver Performance Card | NO | YES | `getDriverPerformanceReport()` |
| Boarding Summary Card | YES | YES | `getStudentBoardingReport()` |
| Finance Summary Row | YES | YES | `getFinanceLeakageReport()` + `prepareChartData()` |
| Financial Overview Chart | YES (revenue only) | YES | `getManagementDashboard()` |
| Leakage Analysis Chart | YES | YES | `getFinanceLeakageReport()` |
| Cost Breakdown Chart | NO | YES | `getCostMaintenanceReport()` + `getManagementDashboard()` |

### 11.2 Filter Combination Matrix

| Combination | Expected Behavior |
|-------------|-------------------|
| No filter (default) | Current month data, first current session (or all if none current) |
| Academic session ONLY | All dates in current month, filtered to session |
| Date range ONLY | All sessions, filtered to date range |
| Both filters | Data scoped to BOTH session AND date range |
| Neither (null session + no current) | ALL data across all sessions + dates (session=null disables session WHERE) |
| Reset/clear | Returns to default state (current month, no session) |

### 11.3 Data Source Filter Sensitivity

| Data Method | Session Sensitive | Date Sensitive | Route Sensitive | Vehicle Sensitive |
|-------------|-------------------|---------------|-----------------|-------------------|
| `getManagementDashboard()` | YES (routes, boardings, revenue) | YES (boardings, revenue, costs) | NO | NO |
| `getRouteReport()` | YES | YES | YES | YES (trips relation) |
| `getTripExecutionReport()` | NO | YES | YES | YES |
| `getDriverPerformanceReport()` | NO | YES | NO | NO |
| `getStudentBoardingReport()` | YES | YES | YES | NO |
| `getFinanceLeakageReport()` | YES | YES | NO | NO |
| `getCostMaintenanceReport()` | NO | NO (uses ALL fuel/maintenance) | NO | YES |

---

## 12. Model Relationships

### 12.1 Core Models Used by Management Dashboard



---

## 13. Permissions Matrix

### 13.1 Permission Keys and Their Impact

| Permission Key | Level | Impact on Management Dashboard |
|----------------|-------|-------------------------------|
| `tenant.transport.viewAny` | Controller Gate | REQUIRED — without this, ALL tab content blocked, 403 returned |
| `tenant.management-dashboard.viewAny` | Tab Visibility | Controls tab nav visibility AND blade @include for body content |
| `tenant.route-performance.viewAny` | Other Tab | Not required for dashboard, but data used from route report queries |
| `tenant.trip-execution.viewAny` | Other Tab | Not required for dashboard, but trip data used in trip execution query |
| `tenant.driver-performance.viewAny` | Other Tab | Not required for dashboard, but driver data used |
| `tenant.student-boarding.viewAny` | Other Tab | Not required for dashboard, but boarding data used |
| `tenant.transport-finance.viewAny` | Other Tab | Not required for dashboard, but finance data used |
| `tenant.cost-maintenance.viewAny` | Other Tab | Not required for dashboard, but cost data used |

### 13.2 Permission Bypass Analysis

| Scenario | Can Access Dashboard? | Data Shown |
|----------|----------------------|------------|
| Has `transport.viewAny` + `management-dashboard.viewAny` | YES | Full dashboard with all data |
| Has `transport.viewAny` but NOT `management-dashboard.viewAny` | NO (tab hidden, 403 on direct) | N/A |
| Has `management-dashboard.viewAny` but NOT `transport.viewAny` | NO (403 at controller level) | N/A |
| Super admin (Gate::before returns true) | YES | Full access regardless of assigned permissions |
| Has `transport.viewAny` but lacks all other report permissions | YES | Dashboard still loads ALL 7 data methods internally — reports are backend queries, not permission-gated |

### 13.3 Hub View Permission Layers



---

## 14. Accessibility & UI/UX Analysis

### 14.1 Accessibility Considerations

| Aspect | Current State | Recommendation |
|--------|--------------|----------------|
| Chart alternative text | Canvas elements have no `aria-label` or fallback text | Add `aria-label` describing chart content |
| Color coding | Profit/Loss uses green/red only — no pattern/text indicator | Add text label or icon in addition to color |
| Keyboard navigation | Tab switch works via Bootstrap events — keyboard accessible | Verify `role="tabpanel"` and `aria-labelledby` attributes |
| Screen reader for charts | Chart.js renders visual-only — no accessible data table | Add hidden data table below each chart for screen readers |
| Focus management | After AJAX load, focus stays on trigger element | Move focus to first new content element after load |
| Color contrast | `text-bg-light` on white background may have low contrast | Verify contrast ratio meets WCAG AA standards |

### 14.2 UX Flow Analysis

| Flow | Steps | Feedback | Risk |
|------|-------|----------|------|
| Page Load | → skeleton loaders → AJAX → content | Opacity 0.5 during load, spinner | Slow AJAX leaves user waiting |
| Tab Switch | → click → AJAX → content | No spinner on tab switch, only loaded class check | If network slow, tab appears empty briefly |
| Filter Submit | → change/click → AJAX → content | Form auto-submits on date change | Users may be surprised by auto-refresh |
| Error State | → AJAX fail → error message | Red error box replaces content | No retry mechanism |
| Reset Filters | → click reset → full page reload | Page refresh with default params | Loses scroll position, all state |

---

## 15. Sequence Diagrams (Textual)

### 15.1 Full Page Load Flow



### 15.2 Filter Change Flow



---

## 16. Security Analysis

### 16.1 Threat Vectors

| Threat | Risk Level | Mitigation | Status |
|--------|-----------|------------|--------|
| SQL Injection via filter params | LOW | Eloquent parameter binding | ✅ Protected |
| XSS via filter values | LOW | Blade `{{ }}` auto-escapes | ✅ Protected |
| CSRF on filter form | LOW | GET requests only — no state change | ✅ No CSRF risk |
| Unauthorized data access via AJAX | MEDIUM | Gate check on every AJAX request (same as page load) | ✅ Protected |
| Permission escalation via tab ID | MEDIUM | `loadTabSection` uses same Gate; bad tab returns "Invalid" | ✅ Protected |
| Data leakage via direct URL | MEDIUM | `Gate::authorize()` blocks without proper permission | ✅ Protected |
| IDOR via academic_session_id | LOW | Academic sessions scoped to tenant — no cross-tenant access | ✅ Tenant scoped |

### 16.2 Data Privacy

| Data Type | Displayed in Dashboard | Sensitivity |
|-----------|----------------------|-------------|
| Student names | NO — only counts/KPIs | N/A |
| Financial amounts | YES — aggregated revenue/costs/leakage | Medium — aggregate only |
| Route names | NO — only counts | N/A |
| Driver names | NO — only aggregate scores | N/A |
| Trip details | NO — only counts | N/A |
| Boarding logs | NO — only counts | N/A |

---

## 17. Dependency Graph

### 17.1 Method Dependency Tree



### 17.2 External Library Dependencies

| Library | Version | Purpose | Fallback |
|---------|---------|---------|----------|
| jQuery | (assumed bundled) | AJAX, DOM manipulation, event handling | None — app depends on jQuery |
| Chart.js | (latest via CDN) | 3 charts: doughnut + 2 bar | None — charts fail to render if CDN is down |
| moment.js | 2.29.4 | Date formatting for daterangepicker | None — date range picker fails |
| daterangepicker | (latest via CDN) | Date range selection UI | Falls back to plain text input |
| Bootstrap 5 | (assumed bundled) | Tab navigation, grid layout, cards | App framework dependency |
| AdminLTE | (assumed bundled) | small-box KPI cards, layout | App theme dependency |
| font-awesome | (assumed bundled) | Icons for cards, charts, buttons | Icons missing but layout intact |

---

## 9. Database Tables Used

| Table | Purpose | Accessed By |
|-------|---------|-------------|
| `routes` | Route count and route report data | `getManagementDashboard()`, `getRouteReport()` |
| `student_academic_sessions` | Session resolution, finance leakage | `getManagementDashboard()`, `getFinanceLeakageReport()`, `getFilterData()` |
| `student_boarding_logs` | Boarding count and boarding report | `getManagementDashboard()`, `getStudentBoardingReport()` |
| `student_pay_logs` | Revenue calculation | `getManagementDashboard()`, `getFinanceLeakageReport()` |
| `tpt_vehicle_fuel` | Fuel cost calculation | `getManagementDashboard()`, `getCostMaintenanceReport()` |
| `tpt_vehicle_maintenance` | Maintenance cost calculation | `getManagementDashboard()`, `getCostMaintenanceReport()` |
| `tpt_trips` | Trip execution report | `getTripExecutionReport()` |
| `tpt_trip_incidents` | Driver incident count | `getDriverPerformanceReport()` |
| `driver_helpers` | Driver/staff performance data | `getDriverPerformanceReport()` |
| `vehicles` | Vehicle cost and inspection data | `getCostMaintenanceReport()` |
| `tpt_student_allocations_jnt` | Route allocation count | Univeral report, route report |
| `tpt_daily_vehicle_inspection` | Inspection risk calculation | `getCostMaintenanceReport()` |
| `pickup_point_routes` | Stop analysis, route data | Route report, stop analysis |
| `pickup_points` | Stop/locality data | Stop analysis |
| `shifts` | Shift filter dropdown | `getFilterData()` |

---

## 10. Known Issues & Observations

| ID | Issue | Severity | Impact |
|----|-------|----------|--------|
| KN-01 | Management Dashboard loads ALL 7 data sources per AJAX call | Medium | 7 separate query methods fire on tab load — performance concern |
| KN-02 | Some cost data may double-count across reports | Low | Route report + management dashboard both query costs independently |
| KN-03 | Filtering not applied uniformly across sub-queries | Medium | Some queries use `$reqFilters` directly, others have independent filter logic |
| KN-04 | Chart.js re-initialization without destroy() | Medium | Switching tabs back and forth creates new Chart instances on same canvas |
| KN-05 | Filter reset link loses active_tab context | Low | `url()->current()` removes all query params including `active_tab` |
| KN-06 | Division by zero in chart tooltip when all values are 0 | Low | `(context.raw / total)` with total=0 produces NaN% |
| KN-07 | Blade `$session->academicSession->name` may throw error | Medium | If relation is null, accessing ->name causes PHP error |
| KN-08 | Leakage default fallback logic may mask zero cases | Low | If both partial and unpaid are truly 0, blade assigns `$leakageCount` as partial count |
| KN-09 | profit_loss string overridden by blade logic | Low | Controller's 'Profit'/'Loss' label set but blade re-calculates independently |
| KN-10 | No pagination on any dashboard data | High | All 7 data methods load complete datasets into memory — not scalable |
| KN-11 | Duplicate completion rate calculation in two controllers | Low | Same logic in `buildDashboardSection()` and `buildStudentBoardingSection()` |
| KN-12 | KPI card "More info" links lack context | Low | All links go to generic list routes, not filtered drill-down views |

---

*End of Document — Total Lines: ~1365*
