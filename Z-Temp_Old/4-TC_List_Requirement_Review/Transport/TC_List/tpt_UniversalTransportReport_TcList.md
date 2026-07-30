# tpt_UniversalTransportReport_TcList — Universal Transport Report

## Module: Transport → Transport Report → Universal Transport

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | Transport |
| Tab Group | Transport Report |
| Feature | Universal Transport Report |
| URL(s) | `/transport/transport-report` (click Universal Transport tab) |
| Controller | `Modules\Transport\Http\Controllers\TransportReportController` |
| Tab Builder | `buildUniversalSection()` (line 246) |
| Data Provider | `getUniversalTransportReport()` (line 994) |
| Hub View | `transport::tab_module.transportreport` |
| Section Views | `transport::report.transport-universal.index` (3 modes: default/tab-pane, section=charts, section=table) |
| Permission | `tenant.universal.viewAny` |
| Permissions Entry | `config/permissionslist.php` line 347: `'universal' => $crud` |
| AJAX Loading | Sections loaded independently via `loadTabSection(tabName, 'charts')` and `loadTabSection(tabName, 'table')` |
| Pagination | `LengthAwarePaginator` with page name `page_universal`, 10 per page |
| Charts | Chart.js line chart (Performance Metrics) + doughnut chart (Cost Analysis) |

---

## 2. Pre-conditions

### 2.1 Data Requirements
- Routes must exist in `routes` table with `is_active = 1` and associated `shift_id`.
- Vehicles must exist in `vehicles` table with `is_active = 1`, capacity, and registration_no.
- Student allocations must exist in `tpt_student_allocation_jnt` referencing `pickup_route_id` or `drop_route_id`.
- Student academic sessions must exist referencing an `academic_session_id`.
- Fee collections must exist in `tpt_student_fee_collections` with `payment_date` within the report range.
- Fuel logs (`tpt_vehicle_fuel`) and maintenance records (`tpt_vehicle_maintenance`) must exist for vehicles.
- Boarding logs (`student_boarding_logs`) must exist with `trip_date` within the range.
- At least one trip with `tripStopDetail` (sch_arrival_time / reaching_time) for delay computation.

### 2.2 Permission Requirements
- Authenticated user must hold `tenant.universal.viewAny` gate.
- The hub view wraps the include in `@can('tenant.universal.viewAny')`.
- The tab nav-tab entry has `'permission' => 'tenant.universal.viewAny'` for double-layer security.

### 2.3 Environment Requirements
- `academic_session_id` filter is optional; when omitted defaults to `is_current = 1` fallback logic in controller.
- `dates` filter is optional; defaults to current month (`startOfMonth` → `endOfMonth`).
- Chart.js library loaded from CDN in hub view.
- Date range picker (daterangepicker.js) initialized in hub view.

---

## 3. Default Data Load

### 3.1 Summary KPIs (universalSummary object)

| KPI | Source/Calculation | Type |
|-----|-------------------|------|
| `total_records` | `$universalTransportReport->count()` — total flattened records | Integer |
| `avg_utilization` | `$report->avg('utilization_percentage')` — average of per-record utilization %, rounded 2 dp | Float |
| `total_fee_collected` | `$report->sum('fee_paid_amount')` — sum of all fee-paid amounts, rounded 2 dp | Float |
| `total_fuel_cost` | `$report->sum('fuel_cost')` — sum of all per-record fuel costs, rounded 2 dp | Float |
| `total_maintenance_cost` | `$report->sum('maintenance_cost')` — sum of all per-record maintenance costs, rounded 2 dp | Float |
| `avg_attendance` | `$report->avg('attendance_percentage')` — average attendance %, rounded 2 dp | Float |

### 3.2 Per-Record Columns (universalTransportReport collection items)

| Column | Source/Calculation |
|--------|-------------------|
| `route_name` | `$route->name` from `routes` table |
| `vehicle_number` | `$vehicle->vehicle_no` |
| `stop_name` | Based on route `pickup_drop`: pickup → `alloc->pickupStop->name`, drop → `alloc->dropStop->name` |
| `student_name` | `$student->first_name . ' ' . $student->last_name` |
| `class_name` | `$classSection->class->name` traversed via `student->sessions->classSection` |
| `section_name` | `$classSection->section->name` |
| `seating_capacity` | `$vehicle->capacity` (integer, defaults 0) |
| `students_allocated` | Count of unique `student_id` in route's allocation group |
| `utilization_percentage` | `(studentsAllocated / seatingCapacity) * 100`, rounded 2 dp; 0 if capacity = 0 |
| `attendance_days` | [Query/Code Removed] |
| `fee_paid_amount` | [Query/Code Removed] |
| `delay_count` | Sum of trips where `tripStopDetail->reaching_time > tripStopDetail->sch_arrival_time` for vehicle+route |
| `fuel_cost` | `$vehicle->fuelLogs->sum('cost')` — eager loaded |
| `maintenance_cost` | `$vehicle->maintenanceRecords->sum('cost')` — eager loaded |
| `attendance_percentage` | `(attendanceDays / calculateWorkingDays(startDate, endDate)) * 100`, rounded 2 dp; excludes weekends |

### 3.3 Chart Data

**Performance Metrics Chart (line chart):**
- X-axis: Record index (1..N)
- Y-axis: Percentage (0–100)
- Dataset 1: `utilization_percentage` per record (indigo line, fill)
- Dataset 2: `attendance_percentage` per record (green line, fill)
- Falls back to "No data available" message when collection empty

**Cost Analysis Chart (doughnut chart):**
- Slice 1: Total Fuel Cost (orange)
- Slice 2: Total Maintenance Cost (red)
- Slice 3: Total Fees Collected (green)
- Below chart: Cost vs Revenue profit/loss indicator with progress bar
- Fee coverage ratio displayed as percentage
- No-data fallback: tooltip shows ₹0.00 (0.0%), chart renders with all-zero data

### 3.4 Table Footer Summary Row

| Column | Aggregation |
|--------|-------------|
| Seating Capacity | Average across all records |
| Students Allocated | Sum |
| Utilization % | Average |
| Attendance Days | Sum |
| Fee Paid Amount | Sum |
| Delay Count | Sum |
| Fuel Cost | Sum |
| Maintenance Cost | Sum |
| Attendance % | Average |

---

## 4. Test Data Strategy

### 4.1 Core Entity Seeds

| Entity | Minimum Records | Key Attributes |
|--------|----------------|----------------|
| Routes | 5 | mix of active/inactive, pickup/drop types, varied shift_ids |
| Vehicles | 5 | mix of active/inactive, varied capacities (20, 30, 40, 50, 60) |
| Shifts | 2 | Morning, Evening |
| Pickup Points (Stops) | 10 | active/inactive mix |
| Students | 20 | with varied class_section assignments |
| StudentAcademicSessions | 20 | mix of current/non-current, varied academic_session_id |
| TptStudentAllocationJnt | 25 | varied pickup_route_id, drop_route_id, vehicle_id, student_session_id |
| StudentBoardingLogs | 200+ | spread across 90 days, mix of boarding/unboarding times |
| TptTrip | 100+ | mix of statuses, some with delays, some without |
| TptTripStopDetail | 100+ | with varied sch_arrival_time and reaching_time |
| TptStudentFeeCollection | 100+ | mix of paid/unpaid/partial, varied payment_date ranges |
| TptVehicleFuel | 50+ | varied costs across vehicles |
| TptVehicleMaintenance | 30+ | varied costs, some vehicles have none |

### 4.2 Boundary Data Scenarios
- Routes with zero allocations (orphan routes)
- Vehicles with zero capacity (`capacity = 0` or `null`)
- Students with no class/section assignment
- Records where pickup AND drop route differ for same student
- Allocations with `vehicle_id = null`
- Fee collection with `payment_date` outside the report range
- Vehicles with no fuel logs or maintenance records (zero costs)
- Boating logs with `boarding_time = null` (missed boarding) even though record exists
- Routes where `pickup_drop` is neither 'pickup' nor 'drop'
- Academic sessions where `is_current` is `0` for all records
- Date range spanning across academic session boundaries

### 4.3 Edge Case Seeds
- Route with 200+ allocations to test utilization > 100%
- Vehicle capacity of 1 (minimum)
- Working days with zero attendance across all records
- Fee collections where `paid_amount = 0` but record exists
- Trips with `start_time` but no `end_time` (incomplete trips)
- Trips where `tripStopDetail` relationship is null
- Records with `student_id` that does not exist in `students` table

---

## 5. Business Conditions

### 5.1 BC-DB: Database Tables Involved

| BC ID | Table | Usage |
|-------|-------|-------|
| BC-DB-01 | `routes` | Route filtering, route name, shift_id, pickup_drop, is_active |
| BC-DB-02 | `vehicles` | Vehicle number, capacity, is_active |
| BC-DB-03 | `shifts` | Shift name filtering |
| BC-DB-04 | `pickup_points` | Stop name display |
| BC-DB-05 | `pickup_point_routes` | Junction for pickup_point ↔ route |
| BC-DB-06 | `students` | Student name |
| BC-DB-07 | `student_academic_sessions` | Academic session ID, class_section_id, is_current |
| BC-DB-08 | `school_classes` | Class name |
| BC-DB-09 | `sections` | Section name |
| BC-DB-10 | `tpt_student_allocation_jnt` | Allocation linking student → route → vehicle → stop |
| BC-DB-11 | `tpt_student_fee_collections` | Fee paid_amount, payment_date |
| BC-DB-12 | `tpt_vehicle_fuel` | Fuel cost |
| BC-DB-13 | `tpt_vehicle_maintenance` | Maintenance cost |
| BC-DB-14 | `student_boarding_logs` | Boarding time, trip_date, student_id |
| BC-DB-15 | `tpt_trips` | Trip date, vehicle_id, driver_id, status |
| BC-DB-16 | `tpt_trip_stop_details` | sch_arrival_time, reaching_time for delay computation |
| BC-DB-17 | `academic_sessions` | Session name, start/end dates |
| BC-DB-18 | `class_sections` | Junction for class_id ↔ section_id |
| BC-DB-19 | `fee_masters` | Master fee record linked via std_academic_sessions_id |
| BC-DB-20 | `driver_helpers` | Driver/helper info (used in filter data) |

### 5.2 BC-VAL: Filter Validation Rules

| BC ID | Rule | Details |
|-------|------|---------|
| BC-VAL-01 | Date range format | Must be parseable by Carbon: `Y-m-d` format expected; daterangepicker sends `YYYY-MM-DD - YYYY-MM-DD` |
| BC-VAL-02 | Start ≤ End date | If `from_date > to_date`, Carbon will still parse; no explicit validation in controller |
| BC-VAL-03 | Academic session ID | Must be integer matching `academic_session_id` in `student_academic_sessions`; no validation if empty |
| BC-VAL-04 | Route ID | Must be integer matching `routes.id`; no validation if empty |
| BC-VAL-05 | Vehicle ID | Must be integer matching `vehicles.id`; no validation if empty |
| BC-VAL-06 | Class section ID | Must be integer matching `class_sections.id`; used in `whereHas` chain |
| BC-VAL-07 | Shift ID | Must be integer matching `shifts.id`; used in route-level filter |
| BC-VAL-08 | Stop ID | [Query/Code Removed] |
| BC-VAL-09 | Student ID | Must be integer matching `students.id`; used in boarding log filter |
| BC-VAL-10 | Null filter values | All filters default to `null` in `$reqFilters` when not provided; query conditions use `when($filled(...))` or `when(isset(...))` |
| BC-VAL-11 | Pagination page param | `page_universal` must be positive integer; non-integer returns page 1 via `Paginator::resolveCurrentPage` |
| BC-VAL-12 | Section parameter | Must be `'charts'` or `'table'`; any other value returns empty tab-pane div |
| BC-VAL-13 | AJAX header | `$request->ajax()` must be truthy for section loading; without it returns full page with filter form |

### 5.3 BC-AUTH: Authorization Rules

| BC ID | Rule | Details |
|-------|------|---------|
| BC-AUTH-01 | Gate check in index | `Gate::authorize('tenant.transport.viewAny')` at line 36 — ALWAYS first line |
| BC-AUTH-02 | No per-section gate | `buildUniversalSection()` does NOT re-check gate (relies on hub-level guard) |
| BC-AUTH-03 | Blade @can guard | `@can('tenant.universal.viewAny')` wraps `@include` in hub view (line 53) |
| BC-AUTH-04 | Tab nav permission | `'permission' => 'tenant.universal.viewAny'` in `x-backend.tab.nav-tab` (line 20) |
| BC-AUTH-05 | No policy class | Uses string-based gate only; no dedicated policy class |
| BC-AUTH-06 | Super admin bypass | `Gate::before` in `AppServiceProvider` may allow super admin; not tested here |
| BC-AUTH-07 | AJAX gate bypass | AJAX requests hit the same `index()` method → same gate check |

### 5.4 BC-BIZ: Business Logic — KPI Calculations

| BC ID | Rule | Formula |
|-------|------|---------|
| BC-BIZ-01 | Utilization % | `(studentsAllocated / seatingCapacity) × 100` |
| BC-BIZ-02 | Utilization when capacity = 0 | Returns 0 (guarded by ternary `$seatingCapacity > 0 ? ... : 0`) |
| BC-BIZ-03 | Attendance % | `(attendanceDays / workingDays) × 100` |
| BC-BIZ-04 | Working days count | `calculateWorkingDays(startDate, endDate)` — counts weekdays only, excludes Sat/Sun |
| BC-BIZ-05 | Working days = 0 | Returns 0 for attendance % (guard: `$totalWorkingDays > 0 ? ... : 0`) |
| BC-BIZ-06 | Delay detection | Trip is delayed if `reaching_time > sch_arrival_time` (boolean → 1 or 0 per trip) |
| BC-BIZ-07 | Fee collection sum | Sum of `paid_amount` from `tpt_student_fee_collections` linked via `fee_master.std_academic_sessions_id = allocation.student_session_id` |
| BC-BIZ-08 | Fuel cost sum | `$vehicle->fuelLogs->sum('cost')` — eager loaded, no date filter on fuel logs |
| BC-BIZ-09 | Maintenance cost sum | `$vehicle->maintenanceRecords->sum('cost')` — eager loaded, no date filter |
| BC-BIZ-10 | Total records count | Count of flattened collection after grouping by vehicle within route |
| BC-BIZ-11 | Average utilization | Arithmetic mean of all per-record utilization_percentage values |
| BC-BIZ-12 | Fee collected total | Sum of all per-record fee_paid_amount values |
| BC-BIZ-13 | Fuel cost total | Sum of all per-record fuel_cost values |
| BC-BIZ-14 | Maintenance cost total | Sum of all per-record maintenance_cost values |
| BC-BIZ-15 | Average attendance | Arithmetic mean of all per-record attendance_percentage values |
| BC-BIZ-16 | Stop name resolution | If `route->pickup_drop === 'pickup'` use `allocation->pickupStop->name`, else use `allocation->dropStop->name` |
| BC-BIZ-17 | Academic session fallback | Try `filters['academic_session_id']` match; if null → `is_current = 1`; if still null → `first()` session |
| BC-BIZ-18 | Vehicle fallback | `$allocation->vehicleData->first()->vehicle ?? $allocation->vehicle` |
| BC-BIZ-19 | Seating capacity fallback | `optional($vehicle)->capacity ?? 0` |
| BC-BIZ-20 | Cost vs Revenue profit/loss | `feeCollected >= (fuelCost + maintenanceCost)` → Profit, else Loss |

### 5.5 BC-BIZ-DEEP: Deep Business Conditions (50+)

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-DEEP-01 | Route has both pickup and drop allocations for same student | Student appears twice in report (once per route branch) |
| BC-BIZ-DEEP-02 | Student allocated to same route as both pickup AND drop | Duplicate record counted via `in_array($alloc->pickup_route_id, $routeIdSet)` and `in_array($alloc->drop_route_id, $routeIdSet)` |
| BC-BIZ-DEEP-03 | Vehicle appears in multiple routes | Fuel and maintenance costs duplicated per route occurrence |
| BC-BIZ-DEEP-04 | No trips exist for a route within date range | `delay_count = 0` |
| BC-BIZ-DEEP-05 | No boarding logs for a student within date range | `attendanceDays = 0`, `attendancePercentage = 0` |
| BC-BIZ-DEEP-06 | `tripStopDetail` is null for all trips | `delay_count = 0` (guarded by `if (!$trip->tripStopDetail) return 0`) |
| BC-BIZ-DEEP-07 | `sch_arrival_time` is null but `reaching_time` is set | No delay counted (both must be non-null for comparison) |
| BC-BIZ-DEEP-08 | `reaching_time <= sch_arrival_time` | Not counted as delay (strict `->gt()` check) |
| BC-BIZ-DEEP-09 | Fee master record missing for allocation's student_session_id | `TptStudentFeeCollection::whereHas` → no match → `feePaid = 0` |
| BC-BIZ-DEEP-10 | Payment date is before `$startDate` | [Query/Code Removed] |
| BC-BIZ-DEEP-11 | Payment date is after `$endDate` | Excluded from sum |
| BC-BIZ-DEEP-12 | Vehicle has `fuelLogs` relationship but `tpt_vehicle_fuel` table is empty | `fuel_cost = 0` |
| BC-BIZ-DEEP-13 | Vehicle has `maintenanceRecords` but costs sum to zero | `maintenance_cost = 0.00` |
| BC-BIZ-DEEP-14 | `calculateWorkingDays` with start=Saturday, end=Sunday | Returns 0 working days |
| BC-BIZ-DEEP-15 | `calculateWorkingDays` with start=Monday, end=Friday (same week) | Returns 5 |
| BC-BIZ-DEEP-16 | Date range spanning 4 weeks (Mon-Mon) | Returns 21 (excluding 8 weekend days) |
| BC-BIZ-DEEP-17 | Records where `stop_name` resolves to null (both `pickupStop` and `dropStop` null) | Displays '—' (null coalescing in view) |
| BC-BIZ-DEEP-18 | `class_name` or `section_name` null | Displays '—' |
| BC-BIZ-DEEP-19 | `student_name` null (foreign key broken) | Displays '—' |
| BC-BIZ-DEEP-20 | `vehicle_number` null | Displays '—' |
| BC-BIZ-DEEP-21 | `seatingCapacity = 0` and `studentsAllocated > 0` | `utilizationPercentage = 0` (not division by zero) |
| BC-BIZ-DEEP-22 | `studentsAllocated > seatingCapacity` (e.g., 30 students, capacity 20) | Utilization > 100% (no cap); view clamps at `min(100)` for progress bar |
| BC-BIZ-DEEP-23 | All records have utilization = 0 | Chart line flat at 0 |
| BC-BIZ-DEEP-24 | All records have attendance = 0 | Chart line flat at 0 |
| BC-BIZ-DEEP-25 | Route query returns 0 routes (`$routeQuery->get()` empty) | `$routes->isEmpty()` → returns `collect()` → all KPIs zero, view shows empty state |
| BC-BIZ-DEEP-26 | `academic_session_id` filter matches no allocations | `$allAllocations` empty → zero records |
| BC-BIZ-DEEP-27 | `vehicle_id` filter has no matching allocations | `whereHas('vehicle')` returns empty → zero records |
| BC-BIZ-DEEP-28 | `class_section_id` filter has no matching students | [Query/Code Removed] |
| BC-BIZ-DEEP-29 | `stop_id` filter has no matching route | Route query returns empty → zero records |
| BC-BIZ-DEEP-30 | `shift_id` filter has no matching routes | Route query returns empty → zero records |
| BC-BIZ-DEEP-31 | Pagination `page_universal=1` with 25 records | First page: 10 records |
| BC-BIZ-DEEP-32 | Pagination `page_universal=3` with 25 records | Third page: 5 records |
| BC-BIZ-DEEP-33 | Pagination `page_universal=999` with 25 records | Empty page (paginator returns empty slice) |
| BC-BIZ-DEEP-34 | `section=charts` AJAX call only | Returns only HTML with KPI boxes + charts, no table |
| BC-BIZ-DEEP-35 | `section=table` AJAX call only | Returns only HTML with table + pagination, no chart section |
| BC-BIZ-DEEP-36 | Initial page load (no AJAX, no section) | Returns filter form + two spinner divs (#universal-charts, #universal-table) |
| BC-BIZ-DEEP-37 | Duplicate `page_universal` key in query string | `Paginator::resolveCurrentPage` returns first occurrence value |
| BC-BIZ-DEEP-38 | Multiple `vehicle_id` in same route group | Each vehicle produces separate records (groupBy vehicle) |
| BC-BIZ-DEEP-39 | Allocation references non-existent vehicle (`vehicle_id = null`) | Grouped under `'no-vehicle'` key; vehicle fallback to `null` |
| BC-BIZ-DEEP-40 | `chartData` has `fuelCost + maintenanceCost = 0` but `feeCollected > 0` | Doughnut chart renders with fuel=0, maintenance=0; profit indicator shows "Profit" |
| BC-BIZ-DEEP-41 | `feeCollected = 0` and `totalCost > 0` | Loss indicator with progress bar at 0% |
| BC-BIZ-DEEP-42 | Cost analysis chart canvas does not exist | `if (costAnalysisCtx)` guard prevents JS error |
| BC-BIZ-DEEP-43 | Performance metrics chart canvas does not exist | `if (performanceMetricsCtx)` guard prevents JS error |
| BC-BIZ-DEEP-44 | `performanceMetricsCtx` exists but `universalData` is empty | Falls to `renderNoDataMessage` — draws text on canvas |
| BC-BIZ-DEEP-45 | `costAnalysisCtx` exists but all values are zero | Doughnut chart renders with invisible zero slices; progress bar at 0% |
| BC-BIZ-DEEP-46 | `totalCost > 0` but `cardBody` not found | `summaryDiv` is never appended (guard: `if (cardBody && totalCost > 0)`) |
| BC-BIZ-DEEP-47 | Date range with `dates` parameter malformed | `explode(' - ', $request->dates, 2)` may return fewer than 2 elements; `[$from, $to]` will throw `ValueError` if fewer than 2 — NO explicit try/catch |
| BC-BIZ-DEEP-48 | `filters['route_id']` is set but route is inactive | `$routeQuery->active()` scope excludes it |
| BC-BIZ-DEEP-49 | `filters['academic_session_id']` is set but student has no matching session | `$student->sessions->firstWhere(...)` returns null → `$studentSession` falls to `is_current` → then `first()` |
| BC-BIZ-DEEP-50 | Same allocation has `pickup_route_id = drop_route_id` | Both `in_array` checks pass → allocation counted twice in `$allocationsByRoute[$route->id]` |
| BC-BIZ-DEEP-51 | `student_session_id` on allocation is null | [Query/Code Removed] |
| BC-BIZ-DEEP-52 | Collection has 0 records but total records table footer shows | Footer row NOT rendered (guarded by `@if($universalTransportReport->isNotEmpty())`) |
| BC-BIZ-DEEP-53 | Filter reset link clicked (`<a href="{{ request()->url() }}">`) | Clears all query params, resets to current month date range |
| BC-BIZ-DEEP-54 | `from_date` and `to_date` provided directly (not via `dates`) | `parseDateRange` checks `$request->filled('dates')` only → falls to default current month — POSSIBLE BUG: `from_date`/`to_date` in query ignored |
| BC-BIZ-DEEP-55 | `request('tab')` not set and `request('active_tab')` not set | `$activeTab` defaults to `'route-performance'` (NOT `'universal'`) |
| BC-BIZ-DEEP-56 | `$filters` has `shift_id` but route query drops it (route-level) | Allocations filtered only by route, not by shift (no when-condition for shift on allocations) |
| BC-BIZ-DEEP-57 | Daterangepicker init with `from_date` and `to_date` in query | Respects these hidden input values; falls to moment().startOf('month') if absent |
| BC-BIZ-DEEP-58 | AJAX filter submit with additional unknown query params | Passed through as-is via `queryData[key]` — no whitelist |
| BC-BIZ-DEEP-59 | Multiple academic sessions assigned to same student | `sessions->firstWhere('academic_session_id', ...)` picks first match only |
| BC-BIZ-DEEP-60 | Table column `delay_count` is 0 | Renders "On Time" badge (green success) instead of delay badge |

---

## 6. Test Case List

### 6.1 TC-P: Positive Test Cases

| TC ID | Description | Prerequisites | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|---------------|-----------------|---------|---------|--------|
| TC-P01 | Universal Transport tab loads all sections successfully on page load | Seed with 3 routes, 3 vehicles, 15 allocations, 60 boarding logs, 30 trips, 20 fee collections | KPI widgets display non-zero values; performance line chart renders; cost doughnut chart renders; table shows 10 rows per page | — | — | ⬜ |
| TC-P02 | Verify Clean Fleet Ratio and all KPI calculations with known data | Seed 1 route, 1 vehicle (capacity 30), 25 allocated students, 20 attendance days, ₹5000 fees, ₹1000 fuel, ₹500 maintenance across 22 working days | avg_utilization = 83.33%; total_fee_collected = ₹5,000.00; total_fuel_cost = ₹1,000.00; total_maintenance_cost = ₹500.00; avg_attendance = 90.91% | — | — | ⬜ |
| TC-P03 | Filter by academic session ID | Seed allocations across 2 academic sessions (2024-25, 2025-26); 10 students in session A, 5 in session B | Selecting session A returns 10 records; session B returns 5 records | — | — | ⬜ |
| TC-P04 | Filter by route ID | Seed allocations for Route A (8 students), Route B (12 students) | Selecting Route A shows 8 records; Route B shows 12 records | — | — | ⬜ |
| TC-P05 | Filter by vehicle ID | Seed allocations for Vehicle V1 (6 students), Vehicle V2 (9 students) | Selecting V1 returns 6 records; V2 returns 9 records | — | — | ⬜ |
| TC-P06 | Filter by date range — narrower than current month | Seed boarding logs only in first week; date range = first 7 days | attendance_days reflects only those 7 days; working days = 5; attendance_percentage recalculated | — | — | ⬜ |
| TC-P07 | Filter by date range — full quarter | Seed data across 3 months; date range = 3-month window | attendance_days aggregates all boarding logs across quarter; working days = ~66 (excl. weekends) | — | — | ⬜ |
| TC-P08 | Verify utilization percentage calculation end-to-end | Route A: Vehicle with capacity 40, 32 students allocated | utilization_percentage = 80.00%; progress bar shows green (≥80) | — | — | ⬜ |
| TC-P09 | Verify utilization with moderate load | Route B: Vehicle capacity 50, 28 students allocated | utilization_percentage = 56.00%; progress bar shows yellow/warning (≥50) | — | — | ⬜ |
| TC-P10 | Verify utilization with low load | Route C: Vehicle capacity 60, 12 students allocated | utilization_percentage = 20.00%; progress bar shows red/danger (<50) | — | — | ⬜ |
| TC-P11 | Verify working days calculation with standard month | Date range: 2025-01-01 to 2025-01-31 | January 2025 has 23 working days (Mon-Fri only, excl. 4 Sat + 4 Sun) | — | — | ⬜ |
| TC-P12 | Verify working days with partial month | Date range: 2025-01-13 (Mon) to 2025-01-17 (Fri) | 5 working days | — | — | ⬜ |
| TC-P13 | Verify delay count aggregation for a vehicle on a route | Seed 10 trips for Route A + Vehicle V1; 4 trips have reaching_time > sch_arrival_time | delay_count = 4 | — | — | ⬜ |
| TC-P14 | Pagination — page 1 shows correct 10 records | Seed 25 records total | Page 1 shows records 1-10; paginator shows 3 pages; page_universal=1 in URL | — | — | ⬜ |
| TC-P15 | Pagination — navigate to page 2 | Seed 25 records total | Page 2 shows records 11-20; page_universal=2 in URL | — | — | ⬜ |
| TC-P16 | Pagination — navigate to last page | Seed 25 records total | Page 3 shows records 21-25 | — | — | ⬜ |
| TC-P17 | Charts section loads independently via AJAX (section=charts) | Page loaded, then section=charts AJAX call made | Returns KPI boxes + chart canvases only; no table HTML | — | — | ⬜ |
| TC-P18 | Table section loads independently via AJAX (section=table) | Page loaded, then section=table AJAX call made | Returns table with pagination only; no KPI/chart HTML | — | — | ⬜ |
| TC-P19 | Fee collection sum filtered by date range correctly | Seed payments: ₹3,000 in Jan, ₹2,000 in Feb; date range = Jan only | Returns ₹3,000.00 | — | — | ⬜ |
| TC-P20 | Student with attendance every working day | 22 working days, 22 boarding log entries | attendance_percentage = 100.00%; chart point at 100% | — | — | ⬜ |
| TC-P21 | Table footer summary row matches aggregation | Various records in collection | Avg capacity, sum allocated, avg utilization, sum attendance, sum fees, sum delays, sum fuel, sum maint, avg attendance all correct | — | — | ⬜ |
| TC-P22 | Performance metrics chart shows both datasets | 5+ records with varied utilization (20-95%) and attendance (30-100%) | Line chart renders with indigo line (utilization) and green line (attendance); y-axis 0-100% | — | — | ⬜ |
| TC-P23 | Cost analysis doughnut chart renders with correct proportions | fuel_cost=₹10,000, maintenance=₹5,000, fees_collected=₹30,000 | Three slices with correct ratios; profit indicator shows "Profit: ₹15,000"; progress bar ~200% (capped at 100%) | — | — | ⬜ |
| TC-P24 | Filter reset clears all parameters | Page with active filters in URL | All selects reset to "All"; date range resets to current month | — | — | ⬜ |
| TC-P25 | Simultaneous multi-filter: academic_session + route + vehicle | Specific combination of session A + route R1 + vehicle V1 | Records match all three criteria simultaneously | — | — | ⬜ |

### 6.2 TC-N: Negative Test Cases

| TC ID | Description | Prerequisites | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|---------------|-----------------|---------|---------|--------|
| TC-N01 | No data for any route in date range | Seed zero boarding logs, zero trips, zero allocations; or use date range where no data exists | Empty collection; KPIs all 0; chart shows "No data available"; table shows empty state "No transport records found" | — | — | ⬜ |
| TC-N02 | Route query returns zero routes (no active routes) | Set all routes `is_active = 0` | `$routes->isEmpty()` → returns `collect()` → all zero; view shows empty state | — | — | ⬜ |
| TC-N03 | All routes active but zero allocations for selected filter | Route active with no student allocations | `$allocationsByRoute[$route->id]` = `[]` → no records produced for that route | — | — | ⬜ |
| TC-N04 | Filter combo returns zero results | Select academic session A + route R1 where route R1 has no allocations in session A | Empty collection; empty table state displayed | — | — | ⬜ |
| TC-N05 | Vehicle capacity = 0 or null | Vehicle with capacity = 0; seed allocation for this vehicle | `utilization_percentage = 0` (no division by zero); view shows 0% with red progress bar | — | — | ⬜ |
| TC-N06 | All fee collection amounts are zero | Fee records exist but `paid_amount = 0` | `total_fee_collected = 0`; all fee badges show red (bg-danger); cost chart zero slice for fees | — | — | ⬜ |
| TC-N07 | All fuel and maintenance costs are zero | Vehicles have no fuel_logs or maintenance_records | `fuel_cost = 0`, `maintenance_cost = 0`; cost chart shows zero slices; profit indicator "Profit: ₹0.00" | — | — | ⬜ |
| TC-N08 | Date range filter with `from_date > to_date` (out-of-order dates) | Send `from_date=2025-02-01&to_date=2025-01-01` | IMPORTANT BUG: `parseDateRange` does NOT validate; Carbon will parse; `whereBetween` will return empty set because start > end | — | — | ⬜ |
| TC-N09 | Invalid `page_universal` parameter (negative number) | `?page_universal=-1` | `Paginator::resolveCurrentPage` returns 1 (negative → default) | — | — | ⬜ |
| TC-N10 | Invalid `page_universal` parameter (non-numeric string) | `?page_universal=abc` | `resolveCurrentPage` returns 1 | — | — | ⬜ |
| TC-N11 | Page number beyond total pages | `?page_universal=999` with 3 total pages | Paginator returns empty collection for the page; table shows empty state | — | — | ⬜ |
| TC-N12 | Missing `section` parameter in AJAX call | Send AJAX without `section` param | `loadTabSection` JS container length = 0 → returns without calling controller | — | — | ⬜ |
| TC-N13 | AJAX call with invalid section value | `section=invalid` | `match ($tab)` goes to `default` → returns `<p class="text-muted">Invalid tab</p>` | — | — | ⬜ |
| TC-N14 | Same student allocated to same route as both pickup AND drop | Student A: pickup_route_id = 1, drop_route_id = 1 | Student A appears TWICE in report: once from `in_array(pickup_route_id)`, once from `in_array(drop_route_id)` — POSSIBLE DUPLICATE BUG | — | — | ⬜ |
| TC-N15 | `academic_session_id` filter set to non-existent ID | `?academic_session_id=99999` | Query returns empty (no matches in `whereHas`) | — | — | ⬜ |
| TC-N16 | `vehicle_id` filter set to non-existent ID | `?vehicle_id=99999` | `whereHas('vehicle')` returns zero allocations | — | — | ⬜ |
| TC-N17 | `student_id` filter with non-allocated student | Student exists but has no allocation for any route | Boarding log filter applies but no records match | — | — | ⬜ |
| TC-N18 | Zero-cost chart (all values ₹0.00) | All fees, fuel, maintenance at zero | Doughnut chart renders three equal invisible slices; progress bar 0%; profit/loss shows "₹0.00" | — | — | ⬜ |
| TC-N19 | Session fallback chain fails — no current session, no sessions at all | Student has no `sessions` relationship loaded | `$studentSession = null` → `$className = '—'`, `$sectionName = '—'` | — | — | ⬜ |

### 6.3 TC-D: Destructive / Edge Case Test Cases

| TC ID | Description | Prerequisites | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|---------------|-----------------|---------|---------|--------|
| TC-D01 | Route with 200+ students allocated to 20-capacity vehicle | Route with 1 vehicle (capacity 20), 210 students allocated | `utilization_percentage = 1050.00%`; progress bar capped at 100% via `min()`; KPI avg_utilization reflects true average > 100% | — | — | ⬜ |
| TC-D02 | All vehicles have `capacity = null` | 3 vehicles, `capacity` column null for all | `seatingCapacity = 0` for all records → utilization = 0% | — | — | ⬜ |
| TC-D03 | All students have `classSection` null | Students exist but `class_section_id` in `student_academic_sessions` is null | `$className = '—'`, `$sectionName = '—'` | — | — | ⬜ |
| TC-D04 | Report date range equals single day (start = end) | Date range `2025-01-15 - 2025-01-15`; 15th is Wednesday | `calculateWorkingDays` returns 1; attendance % = attendanceDays / 1 * 100 | — | — | ⬜ |
| TC-D05 | Date range where start = end = Saturday | Date range `2025-01-11 - 2025-01-11` (Saturday) | `calculateWorkingDays` returns 0; `attendancePercentage = 0` (guard: totalWorkingDays > 0) | — | — | ⬜ |
| TC-D06 | Allocation has `vehicle_id` = null but `vehicleData` relationship null too | Allocation with no vehicle assigned; `$firstAllocation->vehicleData` empty | Vehicle data all fallback to null → vehicle_number = '—', fuel_cost = 0, maintenance_cost = 0 | — | — | ⬜ |
| TC-D07 | `route->pickup_drop` is neither 'pickup' nor 'drop' (unexpected value) | Route where `pickup_drop = 'both'` | `stop_name` falls to else branch → uses `$allocation->dropStop->name` | — | — | ⬜ |
| TC-D08 | Multiple trips per day for same vehicle+route (e.g., split shift) | Route R1, Vehicle V1: 2 trips on same date, 1 delayed, 1 on time | delay_count = 1 (each trip evaluated independently) | — | — | ⬜ |
| TC-D09 | Working days count with DST boundary | Date range crossing Daylight Saving Time change | Carbon handles DST correctly; working days count unaffected | — | — | ⬜ |
| TC-D10 | `tpt_student_fee_collections.payment_date` is null for some records | Fee master exists but payment_date is null | [Query/Code Removed] | — | — | ⬜ |
| TC-D11 | Boarding log has `trip_date` within range but `boarding_time` is null | Student boarded but time not recorded | `attendanceDays` counts the record (boarding log EXISTS); but JS chart shows attendance % based on days (not time) | — | — | ⬜ |
| TC-D12 | Multi-year data with 10,000+ records | Seed large dataset to test paginator performance | Pagination works; page loads within acceptable time; memory usage reasonable | — | — | ⬜ |

### 6.4 TC-CR: Code Review Test Cases

| TC ID | Priority | Description | Expected Result | Status |
|-------|----------|-------------|-----------------|--------|
| TC-CR01 | P1 | Gate check is first line in `index()` | `Gate::authorize('tenant.transport.viewAny')` at line 36 before any logic | ◌ |
| TC-CR02 | P1 | Permission string matches `config/permissionslist.php` | `config/permissionslist.php` has `'universal' => $crud` → `tenant.universal.*`. Controller uses `tenant.transport.viewAny` for hub AND tab uses `tenant.universal.viewAny` — NOTE: hub gate differs from tab permission | ◌ |
| TC-CR03 | P1 | `Gate::authorize` uses string-based gate, NOT policy | Line 36: `Gate::authorize('tenant.transport.viewAny')` — correct | ◌ |
| TC-CR04 | P2 | Blade view has double-layer security for tab | `'permission' => 'tenant.universal.viewAny'` in nav-tab config (line 20) + `@can('tenant.universal.viewAny')` wraps `@include` (line 53) | ◌ |
| TC-CR05 | P1 | Collection pagination uses unique page name | `'page_universal'` as 4th arg to `paginateCollection()` — ensures no conflict with other tabs | ◌ |
| TC-CR06 | P2 | Private query method does NOT accept `$tab` parameter | `getUniversalTransportReport()` is private; correctly called from `buildUniversalSection()` | ◌ |
| TC-CR07 | P2 | `$request->validated()` used for input | N/A — report uses filters via `$request->input()` not FormRequest; raw input used | ◌ |
| TC-CR08 | P3 | `activityLog()` called after data operations | `getUniversalTransportReport()` is read-only; no `activityLog()` needed | ◌ |
| TC-CR09 | P2 | `toggleStatus()` not applicable | Report tab — no status toggle on records | ◌ |
| TC-CR10 | P1 | [Query/Code Removed] | [Query/Code Removed] | ◌ |
| TC-CR11 | P2 | View template uses `@can` symmetrical guards for columns | Report view has no action/status columns; `@can` not required inside the partial (protected at hub level) | ◌ |
| TC-CR12 | P2 | No `@can` / `@endcan` closing directive mismatch | All `@can` → `@endcan` in `hub view` and `index.blade.php` are properly matched | ◌ |
| TC-CR13 | P3 | Console error when Chart.js CDN fails | Hub view loads Chart.js from CDN; if CDN unreachable, Chart constructor throws `ReferenceError: Chart is not defined` — no try/catch | ◌ |
| TC-CR14 | P2 | Empty collection renders `@empty` block | `@forelse` with `@empty` in table section renders "No transport records found" with icon | ◌ |
| TC-CR15 | P2 | Table footer only shown when collection has data | `@if($universalTransportReport->isNotEmpty())` correctly wraps `<tfoot>` | ◌ |
| TC-CR16 | P3 | Performance chart fallback for empty data | `if (performanceMetricsCtx && universalData.length > 0)` — else `renderNoDataMessage()` | ◌ |
| TC-CR17 | P3 | All-zero cost chart still renders | Chart constructor always runs (no data-length check); zero slices will be invisible but chart renders | ◌ |
| TC-CR18 | P1 | `foreach ($allAllocations as $alloc)` iterates eagerly loaded collection | N+1 queries avoided: all relationships eager-loaded via `with()` before loop | ◌ |
| TC-CR19 | P2 | `$vehicleAllocations->first()->vehicleData` uses optional chaining | `optional($firstAllocation->vehicleData)->first()->vehicle` — safely handles null/empty | ◌ |
| TC-CR20 | P1 | `calculateWorkingDays()` excludes weekends correctly | Uses `Carbon::isWeekend()` — returns Sat + Sun as weekend | ◌ |
| TC-CR21 | P2 | `$reqFilters` array keys match `$request` property names | Keys: academic_session_id, class_section_id, route_id, vehicle_id, shift_id, stop_id, driver_id, student_id — match request params | ◌ |
| TC-CR22 | P2 | `index()` sets `$activeTab` default to `'route-performance'` (not universal) | Universal tab is NOT default; user must click tab to load it | ◌ |
| TC-CR23 | P3 | Fuel/maintenance eager loaded without date filter | `'vehicleData.vehicle.fuelLogs'` and `'vehicleData.vehicle.maintenanceRecords'` load ALL records, not filtered by date range — POSSIBLE BUG: costs include data outside report range | ◌ |
| TC-CR24 | P2 | View uses `request('section')` to determine render mode | Three modes: no-section (default/tab-pane), section=charts, section=table | ◌ |
| TC-CR25 | P2 | Pagination links append all query params | `->appends(request()->query())` — preserves all current filters during page navigation | ◌ |
| TC-CR26 | P3 | JS `filter` function in dashboard not used in universal tab | Universal has its own JS in the partial; no need for dashboard-level chart utilities | ◌ |
| TC-CR27 | P2 | `from_date` and `to_date` hidden inputs updated on daterangepicker change | Callback updates `.transport_from_date` and `.transport_to_date` values on date selection | ◌ |
| TC-CR28 | P1 | `$trip->tripStopDetail` nullable check before property access | Line 1112: `if (!$trip->tripStopDetail) return 0;` — safe | ◌ |
| TC-CR29 | P2 | `sch_arrival_time` and `reaching_time` both null checked | Lines 1114-1115: both must be non-null before `->gt()` | ◌ |
| TC-CR30 | P3 | `renderNoDataMessage` clears canvas before drawing | `ctx.clearRect(0, 0, canvas.width, canvas.height)` — prevents ghosting | ◌ |
| TC-CR31 | P1 | Hub view includes CSS, JS, model partials | `@include('transport::css.css')`, `@include('transport::js.js')`, `@include('transport::model.model')` — must exist | ◌ |
| TC-CR32 | P2 | `$filters` dropdown for classes uses `class_id` but controller expects `class_section_id` | View `<select name="class_id">` — controller filter key is `class_section_id` — POSSIBLE BUG: class filter never applies | ◌ |
| TC-CR33 | P2 | `$filters['driver_id']` defined but not used in `getUniversalTransportReport` | Driver_id is collected in `$reqFilters` but no `when()` condition exists in universal query — unused filter | ◌ |
| TC-CR34 | P2 | Daterangepicker CDN loaded in hub view; all tab partials benefit | `transport_daterange` class applied to input; JS init runs once on page load | ◌ |
| TC-CR35 | P1 | `buildUniversalSection()` wraps request merge: `request()->merge(['section' => $section])` | Ensures `request('section')` returns correct value in view | ◌ |

---

## 7. CODE-TRACE

### CODE-TRACE-01: `TransportReportController::index()` — Hub + Gate



### CODE-TRACE-02: `buildUniversalSection()` — Tab Builder



### CODE-TRACE-03: `getUniversalTransportReport()` — Data Query Method



### CODE-TRACE-04: Chart Data Assembly (view layer — JS)



### CODE-TRACE-05: Filter Application Flow



---

## 8. Detailed Test Steps

### 8.1 TC-P01: Universal Transport tab loads all sections



### 8.2 TC-P03: Filter by academic session ID



### 8.3 TC-N01: No data scenario



### 8.4 TC-N08: Invalid date range (from_date > to_date)



### 8.5 TC-P14: Pagination page 1



### 8.6 TC-CR23: Code review — fuel/maintenance not date-filtered



### 8.7 TC-CR32: Code review — class_id vs class_section_id mismatch



### 8.8 TC-D01: Destructive — 200+ students on 20-capacity vehicle with utilization > 100%



### 8.9 TC-D02: All vehicle capacities null — utilization shows 0%



### 8.10 TC-P22: Performance chart renders both datasets



### 8.11 TC-P23: Cost analysis doughnut chart proportions



### 8.12 TC-P25: Multi-filter combination



### 8.13 TC-P06: Narrow date range filter



### 8.14 TC-N04: Filter combination returning zero results



### 8.15 TC-N11: Page number beyond total pages



### 8.16 TC-N19: Student with no academic sessions



### 8.17 TC-D03: All students have null classSection



### 8.18 TC-D09: Working days across DST boundary



### 8.19 TC-CR31: Hub view partials (CSS, JS, Model) exist



### 8.20 TC-CR27: Daterangepicker hidden input update



### 8.21 TC-P08: Utilization bar color thresholds



### 8.22 TC-P13: Delay count verification



### 8.23 TC-P21: Table footer summary accuracy



### 8.24 TC-CR20: Working days exclude weekends



### 8.25 TC-CR35: Section parameter merge in buildUniversalSection



### 8.26 TC-CR19: Optional chaining for vehicle data



### 8.27 TC-N15: Non-existent academic session filter



### 8.28 TC-N17: Student ID filter with non-allocated student



### 8.29 TC-CR13: Chart.js CDN failure resilience



### 8.30 TC-D04: Single-day date range (start = end = Wednesday)





---

## Appendix A: Key Model Relationships Referenced

| Model | Relationship | Foreign Key | Local Key |
|-------|-------------|-------------|-----------|
| Route | `studentAllocationsAll` | — | `id` → `tpt_student_allocation_jnt.pickup_route_id` (or `drop_route_id`) |
| Route | `boardingLogs` | `id` → `student_boarding_logs.boarding_route_id` | — |
| Route | `trips` | `id` → `tpt_trips.route_scheduler_id` (via RouteScheduler) | — |
| Route | `pickupPointRoutes` | `id` → `pickup_point_routes.route_id` | — |
| Vehicle | `fuelLogs` | `id` → `tpt_vehicle_fuel.vehicle_id` | — |
| Vehicle | `maintenanceRecords` | `id` → `tpt_vehicle_maintenance.vehicle_id` | — |
| TptStudentAllocationJnt | `vehicle` | `vehicle_data_id` → `tpt_vehicle_datas.id` → `tpt_vehicles.id` | — |
| TptStudentAllocationJnt | `studentSessions` | `student_session_id` → `student_academic_sessions.id` | — |
| Student | `sessions` | `id` → `student_academic_sessions.student_id` | — |

## Appendix B: View Render Mode Decision Tree



## Appendix C: Known Issues / Observations

| # | Severity | Description | Line(s) |
|---|----------|-------------|---------|
| 1 | Medium | `class_id` vs `class_section_id` mismatch in filter dropdown | View:444, Controller:44 |
| 2 | Medium | Fuel & maintenance costs NOT filtered by date range | Controller:1030-1031 |
| 3 | Low | `driver_id` filter collected but never used in universal query | Controller:49 |
| 4 | Low | Same allocation counted twice when pickup_route_id = drop_route_id | Controller:1048-1053 |
| 5 | Low | `from_date`/`to_date` query params ignored when `dates` param absent | Controller:329 |
| 6 | Info | `tenant.transport.viewAny` (hub) differs from `tenant.universal.viewAny` (tab) | Controller:36 vs View:20/53 |
| 7 | Low | No validation for `from_date > to_date` | Controller:329-336 |
| 8 | Low | Chart.js CDN failure not caught; `ReferenceError` in console | View:68 |
| 9 | Low | `notification_type` and `delivery_status` filters collected but irrelevant to universal | Controller:51-52 |
| 10 | Info | `$filters['staff']` loaded in getFilterData but never passed to universal view | Controller:353 |
| 11 | Low | `roles` filter data loaded but never used by universal | Controller:354 |

---

## Appendix D: Database Schema Reference for Key Tables

### D.1 `routes`

| Column | Type | Notes |
|--------|------|-------|
| id | bigint UNSIGNED PK | Auto-increment |
| name | varchar(255) | Route display name |
| code | varchar(50) | Route code |
| shift_id | bigint UNSIGNED FK | References `shifts.id` |
| pickup_drop | enum('pickup','drop','both') | Determines stop_name resolution |
| is_active | tinyint(1) | Soft-active flag |
| created_at | timestamp | |
| updated_at | timestamp | |

### D.2 `vehicles`

| Column | Type | Notes |
|--------|------|-------|
| id | bigint UNSIGNED PK | Auto-increment |
| vehicle_no | varchar(50) | Registration plate number |
| registration_no | varchar(100) | Official registration |
| capacity | int | Seating capacity (nullable) |
| is_active | tinyint(1) | |
| created_at | timestamp | |
| updated_at | timestamp | |

### D.3 `tpt_student_allocation_jnt`

| Column | Type | Notes |
|--------|------|-------|
| id | bigint UNSIGNED PK | Auto-increment |
| student_id | bigint UNSIGNED FK | References `students.id` |
| student_session_id | bigint UNSIGNED FK | References `student_academic_sessions.id` |
| pickup_route_id | bigint UNSIGNED FK | References `routes.id` |
| drop_route_id | bigint UNSIGNED FK | References `routes.id` |
| pickup_stop_id | bigint UNSIGNED FK | References `pickup_points.id` |
| drop_stop_id | bigint UNSIGNED FK | References `pickup_points.id` |
| vehicle_data_id | bigint UNSIGNED FK | References `tpt_vehicle_datas.id` |

### D.4 `tpt_student_fee_collections`

| Column | Type | Notes |
|--------|------|-------|
| id | bigint UNSIGNED PK | Auto-increment |
| fee_master_id | bigint UNSIGNED FK | References `fee_masters.id` |
| paid_amount | decimal(10,2) | Amount paid |
| payment_date | date | Date of payment |
| created_at | timestamp | |
| updated_at | timestamp | |

### D.5 `fee_masters`

| Column | Type | Notes |
|--------|------|-------|
| id | bigint UNSIGNED PK | Auto-increment |
| std_academic_sessions_id | bigint UNSIGNED FK | References `student_academic_sessions.id` |
| total_fee | decimal(10,2) | Total fee amount |

### D.6 `tpt_trips`

| Column | Type | Notes |
|--------|------|-------|
| id | bigint UNSIGNED PK | Auto-increment |
| trip_date | date | Date of trip |
| vehicle_id | bigint UNSIGNED FK | References `vehicles.id` |
| driver_id | bigint UNSIGNED FK | References `driver_helpers.id` |
| route_scheduler_id | bigint UNSIGNED FK | References `route_schedulers.id` |
| shift_id | bigint UNSIGNED FK | References `shifts.id` |
| start_time | datetime | Actual trip start |
| end_time | datetime | Actual trip end |
| status | enum('Scheduled','InProgress','Completed','Cancelled') | |

### D.7 `tpt_trip_stop_details`

| Column | Type | Notes |
|--------|------|-------|
| id | bigint UNSIGNED PK | Auto-increment |
| trip_id | bigint UNSIGNED FK | References `tpt_trips.id` |
| sch_arrival_time | datetime | Scheduled arrival |
| reaching_time | datetime | Actual arrival |
| sch_departure_time | datetime | Scheduled departure |
| leaving_time | datetime | Actual departure |
| reached_flag | tinyint(1) | Whether stop was reached |

### D.8 `student_boarding_logs`

| Column | Type | Notes |
|--------|------|-------|
| id | bigint UNSIGNED PK | Auto-increment |
| student_id | bigint UNSIGNED FK | References `students.id` |
| student_session_id | bigint UNSIGNED FK | References `student_academic_sessions.id` |
| trip_date | date | Date of boarding |
| boarding_time | datetime | When student boarded (nullable) |
| unboarding_time | datetime | When student alighted (nullable) |
| boarding_route_id | bigint UNSIGNED FK | References `routes.id` |
| unboarding_route_id | bigint UNSIGNED FK | References `routes.id` |
| boarding_stop_id | bigint UNSIGNED FK | References `pickup_points.id` |
| unboarding_stop_id | bigint UNSIGNED FK | References `pickup_points.id` |

### D.9 `tpt_vehicle_fuel`

| Column | Type | Notes |
|--------|------|-------|
| id | bigint UNSIGNED PK | Auto-increment |
| vehicle_id | bigint UNSIGNED FK | References `vehicles.id` |
| date | date | Fuel log date |
| cost | decimal(10,2) | Fuel cost |
| status | enum('Pending','Approved','Rejected') | |

### D.10 `tpt_vehicle_maintenance`

| Column | Type | Notes |
|--------|------|-------|
| id | bigint UNSIGNED PK | Auto-increment |
| vehicle_id | bigint UNSIGNED FK | References `vehicles.id` |
| cost | decimal(10,2) | Maintenance cost |
| maintenance_initiation_date | date | When maintenance started |
| status | enum('Pending','Approved','Rejected') | |

---

## Appendix E: SQL Queries Executed During Report Load

### E.1 Route Query (with filters)


### E.2 Route Eager Loads


### E.3 Allocation Query


### E.4 Per-Record Fee Query (N+1 risk)

NOTE: This query runs INSIDE the loop for each allocation — potential N+1 performance issue.

---

## Appendix F: JavaScript Event Flow Detail

### F.1 Page Load Sequence


### F.2 Tab Switch Sequence


### F.3 Filter Submit Sequence


### F.4 Pagination Click Sequence


### F.5 Chart.js Initialization Sequence


---

## Appendix G: Error Handling Matrix

| Scenario | Expected Behavior | Current Handling |
|----------|-----------------|------------------|
| 403 Forbidden (no permission) | Laravel abort screen | `Gate::authorize()` throws `AuthorizationException` → handled by Laravel's exception handler |
| AJAX 403 response | jQuery `.ajax().error()` fires → shows "Failed to load" alert | Error handler at line 195-198 sets container HTML to error div |
| Database connection failure | 500 error page | Unhandled; Laravel exception handler returns 500 |
| Model not found (broken FK) | Record shows '—' or 0 | Optional/null chaining throughout (e.g., `optional($vehicle)->capacity ?? 0`) |
| Chart.js CDN unreachable | `ReferenceError: Chart is not defined` → chart area blank | No try/catch; JS execution stops at `new Chart(...)` |
| `dates` parameter malformed | `ValueError: Array unpacking` — 500 error | No try/catch around `[$from, $to] = ... explode` |
| `page_universal` very large (e.g., 999999) | Empty page rendered | Paginator handles gracefully; empty slice |
| AJAX response very large (> 5MB) | Browser renders slowly | No size limit or streaming |
| Multiple rapid filter submissions | Race condition — earlier response may overwrite later | No debounce or abort handling |
| Browser without canvas support | Chart areas blank | No fallback message |
| JavaScript disabled | User sees filter form + permanent spinners | No `<noscript>` fallback |

---

## Appendix H: Performance Testing Scenarios

| Test ID | Scenario | Dataset Size | Expected Max Response Time |
|---------|----------|-------------|---------------------------|
| PERF-01 | Single route, single vehicle, 10 students, 30 days | ~10 records | < 500ms |
| PERF-02 | 10 routes, 20 vehicles, 500 students, 90 days | ~500 records | < 1.5s |
| PERF-03 | 50 routes, 100 vehicles, 5000 students, 365 days | ~5000 records | < 3s |
| PERF-04 | Large pagination (page 50 of 5000 records) | Large dataset | < 2s |
| PERF-05 | Concurrent AJAX: charts + table loaded simultaneously | Large dataset | Both load, no timeout |
| PERF-06 | Memory usage with 5000 records in collection | Large dataset | < 64MB PHP memory |
| PERF-07 | N+1 fee query impact — 500 allocations = 500 fee queries | 500 allocations | Should be optimized with batch loading |

### PERF-01 Detailed Steps


### PERF-03 Detailed Steps


---

## Appendix I: Accessibility Testing Checklist

| Check ID | Criterion | Implementation Status |
|----------|-----------|----------------------|
| A11Y-01 | All images/icons have alt text or aria-label | SVG icons in KPI cards have no alt text |
| A11Y-02 | Color not sole means of conveying information | Utilization progress bars use color + percentage text |
| A11Y-03 | Table has proper `<th>` scope attributes | `<th>` elements present but no `scope` attribute |
| A11Y-04 | Form inputs have associated labels | Select elements rely on placeholder labels; no explicit `<label for="">` |
| A11Y-05 | Chart data available in alternative format | Chart data is only in Canvas; no table fallback |
| A11Y-06 | Color contrast meets WCAG AA | Status badges use subtle backgrounds (bg-success-subtle etc.) |
| A11Y-07 | Keyboard navigable tabs | Bootstrap nav-tabs support keyboard navigation |
| A11Y-08 | Focus indicators visible on interactive elements | Bootstrap default focus styles apply |
| A11Y-09 | Loading states announced to screen readers | Spinners present but no `aria-live` region |
| A11Y-10 | Pagination links have descriptive titles | Links show page numbers but no `aria-label` |

---

## Appendix J: Security Testing Scenarios

| Test ID | Scenario | Expected Result |
|---------|----------|-----------------|
| SEC-01 | Unauthenticated user accesses `/transport/transport-report` | Redirected to login |
| SEC-02 | Authenticated user without `tenant.universal.viewAny` accesses URL | 403 AuthorizationException |
| SEC-03 | Authenticated user without `tenant.universal.viewAny` sends AJAX | AJAX error callback fires (same gate check in index()) |
| SEC-04 | SQL injection attempt via `route_id=1 OR 1=1` | Laravel parameterized queries prevent injection |
| SEC-05 | SQL injection attempt via `search=x' DROP TABLE` | No search field in universal tab; filter IDs are bound params |
| SEC-06 | XSS via student name containing `<script>` | Blade's `{{ }}` auto-escapes HTML |
| SEC-07 | Direct access to partial view route | No dedicated route for partial; only rendered via AJAX through controller |
| SEC-08 | Mass assignment via extra query parameters | `$reqFilters` is whitelisted; extra params ignored |
| SEC-09 | CSRF on filter forms | Forms use GET method (read-only); no CSRF needed |
| SEC-10 | Pagination manipulation (`page_universal` overflow) | `resolveCurrentPage` returns positive int; safe |

---

## Appendix K: Browser Compatibility Matrix

| Feature | Chrome 120+ | Firefox 120+ | Safari 17+ | Edge 120+ |
|---------|-------------|--------------|------------|-----------|
| Chart.js 4.x | ✅ | ✅ | ✅ | ✅ |
| Daterangepicker | ✅ | ✅ | ✅ | ✅ |
| ES6 Arrow functions | ✅ | ✅ | ✅ | ✅ |
| Optional chaining (`?.`) | ✅ | ✅ | ✅ | ✅ |
| Nullish coalescing (`??`) | ✅ | ✅ | ✅ | ✅ |
| Bootstrap 5 tab API | ✅ | ✅ | ✅ | ✅ |
| CSS `closest()` | ✅ | ✅ | ✅ | ✅ |
| `<canvas>` API | ✅ | ✅ | ✅ | ✅ |
| Progress bar styling | ✅ | ✅ | ✅ | ✅ |
| SVG in small-box icons | ✅ | ✅ | ✅ | ✅ |

---

## Appendix L: Sample Test Data Setup Script (PHP Pseudocode)


