# tpt_CostMaintenanceReport_TcList

## Module: Transport → Transport Report → Cost & Maintenance

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | Transport |
| Tab Group | Transport Report |
| Feature | Cost & Maintenance Report |
| URL(s) | `/transport-report?active_tab=cost-maintenance` (page load), AJAX: `GET /transport-report?active_tab=cost-maintenance&section=charts/table` |
| Controller | `Modules\Transport\Http\Controllers\TransportReportController` |
| Controller File | `Modules/Transport/app/Http/Controllers/TransportReportController.php` |
| Tab Builder Method | `buildCostMaintenanceSection()` (line 167) |
| Data Method | `getCostMaintenanceReport()` (line 835) |
| Risk Calculation | `calculateRiskLevel()` (line 955) |
| Route | Defined inside `TransportReportController::index()` via `loadTabSection()` match block line 84 |
| View | `transport::report.cost-maintenance.index` |
| View File | `Modules/Transport/resources/views/report/cost-maintenance/index.blade.php` (481 lines) |
| Hub View | `transport::tab_module.transportreport` |
| Hub View File | `Modules/Transport/resources/views/tab_module/transportreport.blade.php` (203 lines) |
| Permission | `tenant.cost-maintenance.viewAny` (line 41 of transportreport.blade.php) |
| JS Chart Library | Chart.js via CDN (`https://cdn.jsdelivr.net/npm/chart.js`) |
| Date Picker | daterangepicker + moment.js via CDN |
| Export | Not implemented |
| Pagination Strategy | Custom `paginateCollection()` on in-memory Collection — uses `page_cost` page name |
| Section Loading | AJAX-driven: charts and table loaded independently via `section=charts` and `section=table` |
| KPI Boxes Template | AdminLTE `small-box` component with SVG icons |

### 1.1 Controller Flow Summary

| Step | Method | Description |
|------|--------|-------------|
| S1 | `TransportReportController::index()` | Gate check `tenant.transport.viewAny`, parse filters, date range, return hub view with filter data |
| S2 | JS `loadTabSection('cost-maintenance', 'charts')` | AJAX GET to `/transport-report?active_tab=cost-maintenance&section=charts` |
| S3 | `loadTabSection()` match `'cost-maintenance'` | Dispatches to `buildCostMaintenanceSection()` |
| S4 | `buildCostMaintenanceSection()` (line 167) | Calls `getCostMaintenanceReport()`, paginates collection with `page_cost`, renders charts view |
| S5 | `getCostMaintenanceReport()` (line 835) | Queries `Vehicle::active()->get()`, maps each vehicle to cost/maintenance/inspection/risk data |
| S6 | JS `loadTabSection('cost-maintenance', 'table')` | AJAX GET to `/transport-report?active_tab=cost-maintenance&section=table` |
| S7 | `buildCostMaintenanceSection()` again | Renders table section with paginated `costMaintenanceReportPaginated` |

### 1.2 Model Relationships

| Model | Table | Key Relationships Used |
|-------|-------|----------------------|
| `Vehicle` | `tpt_vehicle` | `fuelLogs()` → `TptVehicleFuel` (hasMany via `vehicle_id`), `maintenanceRecords()` → `TptVehicleMaintenance` (hasMany via `vehicle_service_request_id` → `serviceRequest.vehicleInspection.vehicle_id`), `inspections()` → `TptDailyVehicleInspection` (hasMany via `vehicle_id`) |
| `TptVehicleFuel` | `tpt_vehicle_fuel` | `vehicle_id`, `cost` (decimal:2), `date`, `status` (Pending/Approved/Rejected) |
| `TptVehicleMaintenance` | `tpt_vehicle_maintenance` | `vehicle_service_request_id`, `cost` (decimal:2), `maintenance_initiation_date`, `status` |
| `TptDailyVehicleInspection` | `tpt_daily_vehicle_inspection` | `vehicle_id`, `inspection_date`, `inspection_status` (Pending/Passed/Failed) |

### 1.3 Relationship Chain for maintenanceRecords



---

## 2. Pre-conditions

| # | Pre-condition | Reason |
|---|--------------|--------|
| PC-01 | Required permission: `tenant.cost-maintenance.viewAny` | Gate check in hub view `@can` + controller implicitly checked via hub |
| PC-02 | Required permission: `tenant.transport.viewAny` | Gate check in `TransportReportController::index()` line 36 |
| PC-03 | Active `Vehicle` records must exist in DB | Base query: `Vehicle::active()->get()` line 838 |
| PC-04 | `TptVehicleFuel` records with `status='Approved'` linked to vehicles | Fuel cost: `$vehicle->fuelLogs->sum('cost')` line 841 |
| PC-05 | `TptVehicleMaintenance` records with `status='Approved'` linked via service request → inspection → vehicle | Maintenance cost: `$vehicle->maintenanceRecords->sum('cost')` line 842 |
| PC-06 | `TptDailyVehicleInspection` records with `inspection_status` = 'Passed' or 'Failed' | [Query/Code Removed] |
| PC-07 | Vehicle must have `vehicle_no` and `registration_no` populated | Displayed in vehicle details column |
| PC-08 | Risk level computed from inspection failure rate and maintenance count | `calculateRiskLevel()` line 955 |
| PC-09 | Chart.js library must be loaded | Rendered in hub view: `<script src="https://cdn.jsdelivr.net/npm/chart.js">` |
| PC-10 | daterangepicker + moment.js must be loaded | Rendered in hub view for date filter |
| PC-11 | jQuery must be available | All AJAX logic uses `$.ajax`, `$(document).ready()` |
| PC-12 | Bootstrap 5 tab system must work | Tab pane uses `data-bs-toggle="tab"`, `tab-pane fade` classes |
| PC-13 | Date range NOT applied to fuel/maintenance/inspection queries | Known gap: `$vehicle->fuelLogs` loads ALL records regardless of `$startDate`/`$endDate` |
| PC-14 | Permissions must exist in `config/permissionslist.php` | Source of truth: `tenant.cost-maintenance.viewAny` must be defined |

### 2.1 Test Environment Setup

| Setup Step | Action | Verification |
|------------|--------|-------------|
| SE-01 | Create 3 active vehicles: "VH-001" (Bus), "VH-002" (Bus), "VH-003" (Van) | Vehicles created in `tpt_vehicle` with `is_active=1` |
| SE-02 | Create 1 inactive vehicle: "VH-004" (Bus) with `is_active=0` | Inactive vehicle exists for exclusion test |
| SE-03 | Create 3 TptVehicleFuel records for VH-001: cost=500, 300, 200 (all Approved, dates inside current month) | Fuel cost data available |
| SE-04 | Create 2 TptVehicleFuel records for VH-002: cost=1000, 500 (all Approved) | Fuel cost data available |
| SE-05 | Create 0 TptVehicleFuel for VH-003 (no fuel logs) | Edge: zero fuel cost |
| SE-06 | Create 2 TptVehicleMaintenance records for VH-001: cost=2000, 1500 (both Approved) | Maintenance cost data available |
| SE-07 | Create 0 TptVehicleMaintenance for VH-002 (no maintenance) | Edge: `$maintenanceCount === 0` triggers HIGH risk |
| SE-08 | Create 1 TptVehicleMaintenance record for VH-003: cost=800 | Maintenance cost data available |
| SE-09 | Create 10 TptDailyVehicleInspection for VH-001: 8 Passed, 2 Failed (20% failure) | Failure rate for MEDIUM risk test |
| SE-10 | Create 10 TptDailyVehicleInspection for VH-002: 4 Passed, 6 Failed (60% failure) | Failure rate for HIGH risk test |
| SE-11 | Create 0 TptDailyVehicleInspection for VH-003 (no inspections) | Risk = UNKNOWN |
| SE-12 | Assign `tenant.cost-maintenance.viewAny` permission to test user | `@can` passes |
| SE-13 | Ensure session is authenticated as a valid user | Auth guard passes |
| SE-14 | Create fuel records with dates outside current month for date gap test | Verification for BC-BIZ-06 |

---

## 3. Default Data Load

### 3.1 Section: charts — 8 Summary Cards + 2 Charts

| Data | Variable Name | Source Code | Computation |
|------|--------------|-------------|-------------|
| KPI: Total Vehicles | `$totalVehicles` | view line 10: `$costMaintenanceReport->count()` | Count of all vehicles in collection |
| KPI: Total Cost | `$totalCost` | view line 11: `$costMaintenanceReport->sum('total_cost')` | Sum of all `total_cost` values |
| KPI: Avg Cost/Vehicle | `$avgCostPerVehicle` | view line 14: `$totalVehicles > 0 ? round($totalCost / $totalVehicles, 0) : 0` | Total cost / vehicle count |
| KPI: High Risk Vehicles | `$highRiskVehicles` | [Query/Code Removed] | Count of vehicles with risk_level = 'HIGH' |
| KPI Row 2: Fuel Cost | `$totalFuelCost` | view line 12: `$costMaintenanceReport->sum('total_fuel_cost')` | Sum of all `total_fuel_cost` values |
| KPI Row 2: Maintenance Cost | `$totalMaintenanceCost` | view line 13: `$costMaintenanceReport->sum('total_maintenance_cost')` | Sum of all `total_maintenance_cost` values |
| KPI Row 2: Low Risk | `$lowRiskVehicles` | [Query/Code Removed] | Count of vehicles with risk_level = 'LOW' |
| KPI Row 2: Unknown Risk | `$unknownRiskVehicles` | [Query/Code Removed] | Count of vehicles with risk_level = 'UNKNOWN' |
| Cost Distribution Chart | `costDistributionChart` (Chart.js) | view lines 218–250 | Doughnut chart: Fuel Cost vs Maintenance Cost |
| Risk Analysis Chart | `riskAnalysisChart` (Chart.js) | view lines 253–298 | Bar chart: High/Low/Unknown vehicle counts |

### 3.2 Section: table — 6 Columns + Footer

| Column | Blade Variable | Source Field | Formatting |
|--------|---------------|--------------|------------|
| # | `$index + 1` | Loop index | `text-muted` |
| Vehicle Details | `$vehicleNo`, `$registrationNo` | `vehicle_no`, `registration_no` | Icon + fw-semibold no + small reg |
| Cost (₹) | `$totalCost` | `total_cost` | fw-semibold text-primary ₹X, breakdown: Fuel + Maintenance |
| Inspection | `$inspectionFailureRate` | `inspection_failure_rate` | X% + badge: Good(≤0%), Fair(≤20%), Poor(>20%) |
| Risk Level | `$riskLevel` | `risk_level` | Badge `bg-*` rounded-pill: danger HIGH, success LOW, warning MEDIUM, secondary UNKNOWN |
| Status | `$costEfficiencyText` | Computed from `$totalCost` | Badge: secondary No Cost(0), success Efficient(≤100), warning Moderate(≤200), danger High Cost(>200) |
| TFOOT TOTAL | `$totalCost` + vehicle count | Sum of all costs | fw-semibold ₹X + "X vehicles" |

### 3.3 Filter Controls

| Filter | HTML Element | Name Attribute | Options Source | Default Value |
|--------|-------------|----------------|----------------|---------------|
| Date Range | daterangepicker input | `dates` | moment.js presets | Current month (start to end) |
| Hidden From Date | hidden input | `from_date` | Parsed from date range | Current month start |
| Hidden To Date | hidden input | `to_date` | Parsed from date range | Current month end |
| Active Tab | hidden input | `active_tab` | Hardcoded `cost-maintenance` | `cost-maintenance` |


### 3.4 Pagination Configuration

| Property | Value |
|----------|-------|
| Items per page | 10 |
| Page query param | `page_cost` |
| Paginator type | `LengthAwarePaginator` on in-memory `Collection` |
| Page resolution | `Paginator::resolveCurrentPage('page_cost')` |
| Path resolution | `Paginator::resolveCurrentPath()` |
| Append strategy | `->appends(request()->query())->links()` |

### 3.5 KPI Box Template (AdminLTE small-box)

Each KPI uses the `small-box` component with:
- Color variant: `text-bg-primary` (Total Vehicles), `text-bg-success` (Total Cost, Low Risk), `text-bg-info` (Avg Cost), `text-bg-danger` (High Risk), `text-bg-warning` (Fuel Cost), `text-bg-secondary` (Maintenance Cost), `text-bg-ligth` (Unknown Risk)
- Inner: `<h3>` for value, `<p>` for label
- SVG icon as `small-box-icon`
- Footer link: More info → `route('transport.trip-management.index')`

### 3.6 Status Badge Rules

| Context | Condition | Badge Class | Text |
|---------|-----------|-------------|------|
| Inspection | `$failureRate == 0` | `bg-success` | Good |
| Inspection | `$failureRate <= 20` | `bg-warning` | Fair |
| Inspection | `$failureRate > 20` | `bg-danger` | Poor |
| Risk Level | `HIGH` | `bg-danger` | HIGH |
| Risk Level | `LOW` | `bg-success` | LOW |
| Risk Level | `MEDIUM` | `bg-warning` | MEDIUM |
| Risk Level | `UNKNOWN` | `bg-secondary` | UNKNOWN |
| Cost Efficiency | `$totalCost == 0` | `bg-secondary` | No Cost |
| Cost Efficiency | `$totalCost <= 100` | `bg-success` | Efficient |
| Cost Efficiency | `$totalCost <= 200` | `bg-warning` | Moderate |
| Cost Efficiency | `$totalCost > 200` | `bg-danger` | High Cost |

### 3.7 Chart.js Configuration Details

| Chart | Type | Datasets | Colors | Special Options |
|-------|------|----------|--------|-----------------|
| Cost Distribution | `doughnut` | Fuel Cost (₹), Maintenance Cost (₹) | `#0d6efd` (blue), `#198754` (green) | `cutout: '70%'`, tooltip shows ₹ + %, legend bottom |
| Vehicle Risk Analysis | `bar` | Number of Vehicles (High, Low, Unknown) | `#dc3545` (red), `#198754` (green), `#6c757d` (gray) | `beginAtZero: true`, `stepSize: 1`, no legend, tooltip shows "X Risk: Y vehicles" |

---

## 4. Test Data Strategy

### 4.1 Core Dataset

| Dataset ID | Vehicles | Fuel Records | Maintenance Records | Inspections | Scenario |
|-----------|----------|-------------|-------------------|-------------|----------|
| DS-01 | VH-001 (active, Bus) | 3 records: ₹500, ₹300, ₹200 = ₹1000 total | 2 records: ₹2000, ₹1500 = ₹3500 total | 10 inspections: 8 Passed, 2 Failed (20% failure) | Normal mixed operation. Total Cost = ₹4500, Risk = MEDIUM |
| DS-02 | VH-002 (active, Bus) | 2 records: ₹1000, ₹500 = ₹1500 total | 0 records: ₹0 total | 10 inspections: 4 Passed, 6 Failed (60% failure) | No maintenance → HIGH risk. Total Cost = ₹1500 |
| DS-03 | VH-003 (active, Van) | 0 records: ₹0 total | 1 record: ₹800 total | 0 inspections: N/A | No inspections → UNKNOWN risk. Total Cost = ₹800 |
| DS-04 | VH-004 (inactive) | 0 records | 0 records | 0 inspections | Inactive vehicle — excluded by `->active()` scope |
| DS-05 | VH-005 (active, Bus) | 2 records: ₹50, ₹75 = ₹125 total | 1 record: ₹50 total | 5 inspections: 5 Passed, 0 Failed (0% failure) | LOW risk, Efficient cost. Total Cost = ₹175 |

### 4.2 Edge Case Dataset

| Edge ID | Setup | Expected Impact |
|---------|-------|----------------|
| ED-01 | Vehicle with zero TptVehicleFuel records | `total_fuel_cost = 0` (sum of empty collection) |
| ED-02 | Vehicle with zero TptVehicleMaintenance records | `total_maintenance_cost = 0`, risk may become HIGH if `$maintenanceCount === 0` |
| ED-03 | Vehicle with zero TptDailyVehicleInspection records | `totalInspections = 0` → risk_level = 'UNKNOWN' |
| ED-04 | Vehicle with total cost = 0 (no fuel, no maintenance) | Status badge: "No Cost" (secondary) |
| ED-05 | Vehicle with very high failure rate (100%) | High risk, Poor inspection status |
| ED-06 | Vehicle with total cost = 0 but has inspections | `inspection_failure_rate` computed normally; cost efficiency = "No Cost" |
| ED-07 | Vehicle with failure rate > 30% but has maintenance | Risk = HIGH (failure_rate > 30 takes precedence) |
| ED-08 | Vehicle with failure rate = 0 but no maintenance | Risk = HIGH (`$maintenanceCount === 0` triggers HIGH regardless of failure rate) |
| ED-09 | Vehicle with failure rate = 15% exactly | Not > 15, so MEDIUM not triggered? Wait: `$failureRate > 15` — 15 is NOT > 15, so falls to LOW. Boundary: 15.1% vs 15.0% |
| ED-10 | Vehicle with failure rate = 30% exactly | Not > 30, so MEDIUM if maintenance exists. Boundary: 30.0% vs 30.1% |
| ED-11 | Vehicle with exactly 10 fuel records (boundary for sum) | Sum computed correctly across 10 records |
| ED-12 | Vehicle with extremely high cost (₹9,99,999) | Number formatting via `number_format($totalCost, 0)` |
| ED-13 | Vehicle with cost = 0.01 (minimum) | `round(0.01, 2)` = 0.01 |
| ED-14 | Date range with zero matching data (but records exist outside range) | Known gap: fuel/maintenance/inspection NOT date-filtered, so data still shows |
| ED-15 | No vehicles in system at all | Empty collection → all KPIs = 0, empty table: "No vehicle cost and maintenance data found" |

### 4.3 Boundary Values for Risk Level

| Boundary | `$totalInspections` | `$failureRate` | `$maintenanceCount` | Expected Risk Level |
|----------|--------------------|----------------|---------------------|---------------------|
| Unknown trigger | 0 | N/A (not computed) | any | UNKNOWN |
| High by failure | ≥1 | 30.1% | ≥1 | HIGH |
| High by failure boundary | ≥1 | 30.0% | any | NOT HIGH (fall through) |
| High by no maintenance | ≥1 | any ≤30% | 0 | HIGH |
| Medium trigger | ≥1 | 15.1% | ≥1 | MEDIUM |
| Medium boundary | ≥1 | 15.0% | ≥1 | NOT MEDIUM (fall through) |
| Low trigger | ≥1 | ≤15% | ≥1 | LOW |

### 4.4 Boundary Values for Cost Efficiency

| Boundary | Total Cost | Expected Badge |
|----------|-----------|----------------|
| No cost | 0 | No Cost (secondary) |
| Efficient lower | 0.01 | Efficient (success) |
| Efficient upper | 100.00 | Efficient (success) |
| Moderate lower | 100.01 | Moderate (warning) |
| Moderate upper | 200.00 | Moderate (warning) |
| High lower | 200.01 | High Cost (danger) |

### 4.5 Boundary Values for Inspection Status

| Boundary | Failure Rate % | Expected Badge |
|----------|---------------|----------------|
| Good exact | 0% | Good (success) |
| Fair lower | 0.1% | Fair (warning) |
| Fair upper | 20.0% | Fair (warning) |
| Poor lower | 20.1% | Poor (danger) |

---

## 5. Business Conditions

### 5.1 Query Logic (`getCostMaintenanceReport` — line 835)

| BC ID | Line(s) | Detail | Priority |
|-------|---------|--------|----------|
| BC-QL-01 | 837 | [Query/Code Removed] | P1 |
| BC-QL-02 | 838 | Active only: `->active()` — scope filters `is_active = 1` | P1 |
| BC-QL-03 | 839 | `->get()` — executes query, loads ALL vehicles into memory | P1 |
| BC-QL-04 | 840 | `->map(function($vehicle)` — iterates collection, transforms to array | P1 |
| BC-QL-05 | 841 | Fuel cost: `$vehicle->fuelLogs->sum('cost')` — loads ALL fuel logs, no date filter | P1 |
| BC-QL-06 | 842 | Maintenance cost: `$vehicle->maintenanceRecords->sum('cost')` — loads ALL maintenance, no date filter | P1 |
| BC-QL-07 | 845 | [Query/Code Removed] | P1 |
| BC-QL-08 | 846 | Total inspections: `$vehicle->inspections->count()` — loads ALL inspections, no date filter | P1 |
| BC-QL-09 | 848-856 | Return array: vehicle_no, registration_no, total_fuel_cost, total_maintenance_cost, total_cost, inspection_failure_rate, risk_level | P1 |
| BC-QL-10 | 855 | Risk level via `$this->calculateRiskLevel($failedInspections, $totalInspections, $vehicle->maintenanceRecords->count())` | P1 |

### 5.2 Risk Level Calculation (`calculateRiskLevel` — line 955)

| BC ID | Line(s) | Condition | Risk Level | Priority |
|-------|---------|-----------|------------|----------|
| BC-RL-01 | 957 | `$totalInspections === 0` | 'UNKNOWN' | P1 |
| BC-RL-02 | 961 | `$failureRate > 30 \|\| $maintenanceCount === 0` | 'HIGH' | P1 |
| BC-RL-03 | 962 | `$failureRate > 15` | 'MEDIUM' | P1 |
| BC-RL-04 | 964 | Default (fall through) | 'LOW' | P1 |
| BC-RL-05 | 959 | `$failureRate = ($failedInspections / $totalInspections) * 100` | Computed as percentage float | P1 |

### 5.3 Business Logic

| BC ID | Condition | Expected Behavior | Verification |
|-------|-----------|-------------------|-------------|
| BC-BIZ-01 | Vehicle with no fuel logs | `fuel_cost = 0` (sum of empty collection = 0) | Assert `$vehicle->fuelLogs` empty |
| BC-BIZ-02 | Vehicle with no maintenance records | `maintenance_cost = 0` | Assert `$vehicle->maintenanceRecords` empty |
| BC-BIZ-03 | Vehicle with no inspections | `risk_level = 'UNKNOWN'` (totalInspections = 0) | Assert `calculateRiskLevel()` returns 'UNKNOWN' |
| BC-BIZ-04 | Vehicle with 0 total cost | Status badge = "No Cost" (secondary) | Assert `$costEfficiencyText === 'No Cost'` |
| BC-BIZ-05 | No vehicles in system | Empty table: "No vehicle cost and maintenance data found" | Check `@empty` condition in table |
| BC-BIZ-06 | Date range ignored for inspections | No `whereBetween` on inspections — queries ALL records regardless of date range | Verify inspection count unaffected by date filter |
| BC-BIZ-07 | Fuel and maintenance not date-filtered | `$vehicle->fuelLogs` loads ALL fuel logs, not scoped to date range | Verify fuel cost unchanged by date filter |
| BC-BIZ-08 | Vehicle with no registration_no | Display shows '-' or null in registration_no field | Check blade: `$registrationNo ?? ''` |
| BC-BIZ-09 | Vehicle with no vehicle_no | Vehicle details column shows empty string | Check blade: `$vehicleNo ?? ''` |
| BC-BIZ-10 | Inactive vehicle | Excluded by `->active()` scope on Vehicle query | Assert inactive vehicle not in collection |
| BC-BIZ-11 | `vehicle_id` filter not exposed in blade | Filter bar only shows date range; vehicle_id filter hidden in controller `$reqFilters` | Assert no vehicle dropdown in blade |
| BC-BIZ-12 | Multiple failed conditions for HIGH risk | HIGH when `$failureRate > 30` OR `$maintenanceCount === 0` — whichever matches first | Test both conditions independently |
| BC-BIZ-13 | `round()` on costs | All cost values rounded to 2 decimal places via `round(X, 2)` | Assert `total_fuel_cost` has max 2 decimals |
| BC-BIZ-14 | `round()` on failure rate | `inspection_failure_rate` rounded to 1 decimal via `round(X, 1)` | Assert single decimal |

### 5.4 UI Rendering Logic

| BC ID | Condition | Expected Behavior | Verification |
|-------|-----------|-------------------|-------------|
| BC-UI-01 | `section` param = `charts` | 8 KPI boxes + 2 charts rendered with inline script | Check `@if(request('section') === 'charts')` block |
| BC-UI-02 | `section` param = `table` | 6-column table with pagination rendered | Check `@elseif(request('section') === 'table')` block |
| BC-UI-03 | No `section` param | Filter bar + skeleton loaders for both charts and table | Check `@else` block |
| BC-UI-04 | Skeleton loader visible before AJAX | Spinner with `spinner-border` inside `#cost-maintenance-charts` and `#cost-maintenance-table` | Assert spinner present |
| BC-UI-05 | Loading state: container opacity | `container.css('opacity', 0.5)` during AJAX call | Assert opacity set |
| BC-UI-06 | AJAX error state | Container shows `<div class="alert alert-danger">Failed to load ...</div>` | Assert error HTML injected |
| BC-UI-07 | Empty collection for charts | All 8 KPIs show 0 or "₹0"; charts render with zero data | Assert KPI values = 0 |
| BC-UI-08 | Empty collection for table | Row with `colspan="6"`, `bi-inbox` icon, "No vehicle cost and maintenance data found" | Assert `<td colspan="6">` |
| BC-UI-09 | Cost efficiency badge logic | Color-coded by total cost range | Check all 4 badge states |
| BC-UI-10 | Inspection status badge logic | Good/Fair/Poor based on failure rate % | Check all 3 badge states |

### 5.5 AJAX & Tab Interaction Logic

| BC ID | Condition | Expected Behavior | Verification |
|-------|-----------|-------------------|-------------|
| BC-AJ-01 | Page load triggers `loadTabSection` | `loadTabSection('cost-maintenance', 'charts')` and `loadTabSection('cost-maintenance', 'table')` called | Assert 2 AJAX calls on load |
| BC-AJ-02 | Tab switch triggers load on first visit | `shown.bs.tab` event checks `loaded` class; if absent, fetches both sections | Assert AJAX call on first tab switch |
| BC-AJ-03 | Tab switch does NOT reload if already loaded | `loaded` class prevents duplicate AJAX | Assert no AJAX on second visit |
| BC-AJ-04 | Filter form submit triggers AJAX | `.transport-filter-form` submit handler calls `loadTabSection` for both sections | Assert 2 AJAX calls on filter change |
| BC-AJ-05 | Pagination click triggers table section reload | `.tab-pane .pagination a` click handler calls `loadTabSection(tabName, 'table', queryString)` | Assert AJAX call with page param |
| BC-AJ-06 | `loadTabSection` appends `active_tab` and `section` to query | Query data: `{active_tab: 'cost-maintenance', section: 'charts'}` plus filter params | Assert URL params correct |
| BC-AJ-07 | Non-AJAX page load | Controller returns hub view with `activeTab='cost-maintenance'` | Assert blade view rendered |
| BC-AJ-08 | `loadTabSection` with missing container | Function returns early if container length === 0 | Assert no error thrown |

### 5.6 Notes

#### 5.6.1 BC-BIZ-06: Date Range Gap — CRITICAL (P1)

The `getCostMaintenanceReport()` method does NOT apply `$startDate` / `$endDate` filters to the fuel logs, maintenance records, or inspections. These load ALL records regardless of the selected date range.

**Evidence:**
- Line 842: `$vehicle->maintenanceRecords->sum('cost')` — no date scope applied

**Impact:** The date range filter in the blade UI is effectively a no-op for this report. All fuel, maintenance, and inspection costs load ALL records regardless of what date is selected. This is a potential data integrity issue.


#### 5.6.2 BC-BIZ-11: vehicle_id Filter Not Exposed

The controller accepts `$filters['vehicle_id']` (line 837) and applies it to the query, but the blade filter bar (lines 452-475) only renders the date range input. No vehicle dropdown or vehicle select is present in the UI. Users cannot filter by individual vehicle.

---

## 6. CODE-TRACE Structure

### 6.1 CODE-TRACE-01: `TransportReportController::index()` — Hub Flow

| Trace Step | Line | Code | Description |
|-----------|------|------|-------------|
| TR-01-01 | 36 | `Gate::authorize('tenant.transport.viewAny')` | Permission gate — blocks unauthorized users |
| TR-01-02 | 38 | `$activeTab = $request->get('active_tab') ?: $request->get('tab', 'route-performance')` | Resolves active tab; defaults to route-performance |
| TR-01-03 | 39 | `$section = $request->get('section')` | Captures AJAX section flag (charts/table/null) |
| TR-01-04 | 42-53 | `$reqFilters = [...]` | Assembles filter array from request params including `vehicle_id` |
| TR-01-05 | 55-57 | `$startDate = $dateRange['startDate']; $endDate = $dateRange['endDate']` | Parses date range via `parseDateRange()` |
| TR-01-06 | 60 | `if ($request->ajax() && $section)` | AJAX branch: returns JSON with rendered HTML |
| TR-01-07 | 61 | `return $this->loadTabSection($activeTab, $section, ...)` | Dispatches to `loadTabSection()` |
| TR-01-08 | 65 | `$filters = $this->getFilterData()` | Loads filter dropdown data (routes, stops, vehicles, etc.) |
| TR-01-09 | 67 | `return view('transport::tab_module.transportreport', compact('filters', 'activeTab'))` | Returns full hub view with filter data |

**Test Coverage: TR-01-01 to TR-01-09**

### 6.2 CODE-TRACE-02: `buildCostMaintenanceSection()` — Tab Builder

| Trace Step | Line | Code | Description |
|-----------|------|------|-------------|
| TR-02-01 | 169 | `request()->merge(['section' => $section])` | Merges section into request for view conditional rendering |
| TR-02-02 | 170 | `$costMaintenanceReport = $this->getCostMaintenanceReport($reqFilters, $startDate, $endDate)` | Calls data method; returns Collection of arrays |
| TR-02-03 | 171 | `$costMaintenanceReportPaginated = $this->paginateCollection($costMaintenanceReport, 10, 'page_cost')` | Paginates collection: 10 per page, page name `page_cost` |
| TR-02-04 | 172 | `return view('transport::report.cost-maintenance.index', compact('filters', 'costMaintenanceReport', 'costMaintenanceReportPaginated'))->render()` | Renders view with full collection + paginated subset |

**Test Coverage: TR-02-01 to TR-02-04**

### 6.3 CODE-TRACE-03: `getCostMaintenanceReport()` — Data Query

| Trace Step | Line | Code | Description |
|-----------|------|------|-------------|
| TR-03-01 | 837 | [Query/Code Removed] | Conditional vehicle filter by ID |
| TR-03-02 | 838 | `->active()` | Active vehicle scope (`is_active = 1`) |
| TR-03-03 | 839 | `->get()` | Executes query, returns Collection of Vehicle models |
| TR-03-04 | 840 | `->map(function($vehicle) {` | Starts map transformation |
| TR-03-05 | 841 | `$totalFuelCost = $vehicle->fuelLogs->sum('cost')` | Sum of all fuel log costs (no date filter) |
| TR-03-06 | 842 | `$totalMaintenanceCost = $vehicle->maintenanceRecords->sum('cost')` | Sum of all maintenance record costs (no date filter) |
| TR-03-07 | 843 | `$totalCost = $totalFuelCost + $totalMaintenanceCost` | Total cost = fuel + maintenance |
| TR-03-08 | 845 | [Query/Code Removed] | Count of Failed inspections (no date filter) |
| TR-03-09 | 846 | `$totalInspections = $vehicle->inspections->count()` | Total inspection count (no date filter) |
| TR-03-10 | 848-856 | Return array with 7 keys | Maps vehicle data to array format |
| TR-03-11 | 851 | `'total_fuel_cost' => round($totalFuelCost, 2)` | Fuel cost rounded to 2 decimals |
| TR-03-12 | 852 | `'total_maintenance_cost' => round($totalMaintenanceCost, 2)` | Maintenance cost rounded to 2 decimals |
| TR-03-13 | 853 | `'total_cost' => round($totalCost, 2)` | Total cost rounded to 2 decimals |
| TR-03-14 | 854 | `'inspection_failure_rate' => $totalInspections ? round(($failedInspections / $totalInspections) * 100, 1) : 0` | Failure rate %, guarded against division by zero |
| TR-03-15 | 855 | `'risk_level' => $this->calculateRiskLevel($failedInspections, $totalInspections, $vehicle->maintenanceRecords->count())` | Risk level from helper |

**Test Coverage: TR-03-01 to TR-03-15**

### 6.4 CODE-TRACE-04: `calculateRiskLevel()` — Risk Computation

| Trace Step | Line | Code | Description |
|-----------|------|------|-------------|
| TR-04-01 | 957 | `if ($totalInspections === 0) return 'UNKNOWN'` | No inspections → unknown risk |
| TR-04-02 | 959 | `$failureRate = ($failedInspections / $totalInspections) * 100` | Failure rate as percentage |
| TR-04-03 | 961 | `if ($failureRate > 30 \|\| $maintenanceCount === 0) return 'HIGH'` | High if >30% failure OR no maintenance |
| TR-04-04 | 962 | `if ($failureRate > 15) return 'MEDIUM'` | Medium if >15% failure (and has maintenance) |
| TR-04-05 | 964 | `return 'LOW'` | Default: low risk |

**Test Coverage: TR-04-01 to TR-04-05**

### 6.5 CODE-TRACE-05: KPI Calculation Flow (View — charts section)

| Trace Step | View Line | Expression | Description |
|-----------|----------|------------|-------------|
| TR-05-01 | 9 | `$costMaintenanceReport = $costMaintenanceReport ?? collect()` | Null-safe fallback to empty collection |
| TR-05-02 | 10 | `$totalVehicles = $costMaintenanceReport->count()` | Count of all vehicles |
| TR-05-03 | 11 | `$totalCost = $costMaintenanceReport->sum('total_cost')` | Sum of all total_cost values |
| TR-05-04 | 12 | `$totalFuelCost = $costMaintenanceReport->sum('total_fuel_cost')` | Sum of all fuel costs |
| TR-05-05 | 13 | `$totalMaintenanceCost = $costMaintenanceReport->sum('total_maintenance_cost')` | Sum of all maintenance costs |
| TR-05-06 | 14 | `$avgCostPerVehicle = $totalVehicles > 0 ? round($totalCost / $totalVehicles, 0) : 0` | Average cost per vehicle (guarded) |
| TR-05-07 | 15 | [Query/Code Removed] | Count of HIGH risk vehicles |
| TR-05-08 | 16 | [Query/Code Removed] | Count of LOW risk vehicles |
| TR-05-09 | 17 | [Query/Code Removed] | Count of UNKNOWN risk vehicles |

**Test Coverage: TR-05-01 to TR-05-09**

### 6.6 CODE-TRACE-06: Chart Data Assembly (View — scripts)

| Trace Step | View Line | Expression | Description |
|-----------|----------|------------|-------------|
| TR-06-01 | 202 | `$vehicleData = $costMaintenanceReport->toArray()` | Full data for JS debug |
| TR-06-02 | 203 | `$totalFuelCost = $costMaintenanceReport->sum('total_fuel_cost')` | Fuel cost for doughnut |
| TR-06-03 | 204 | `$totalMaintenanceCost = $costMaintenanceReport->sum('total_maintenance_cost')` | Maintenance cost for doughnut |
| TR-06-04 | 205-209 | `$riskCounts = ['HIGH' => count, 'LOW' => count, 'UNKNOWN' => count]` | Risk counts for bar chart |
| TR-06-05 | 218-250 | Cost Distribution Chart | Doughnut chart construction |
| TR-06-06 | 253-298 | Risk Analysis Chart | Bar chart construction |

**Chart Rendering Details:**

| Chart | Type | Data | Color Logic |
|-------|------|------|-------------|
| Cost Distribution | `doughnut` (cutout 70%) | Fuel Cost, Maintenance Cost | `#0d6efd` (blue), `#198754` (green) |
| Vehicle Risk Analysis | `bar` | HIGH, LOW, UNKNOWN counts | `#dc3545` (red), `#198754` (green), `#6c757d` (gray) |

**Test Coverage: TR-06-01 to TR-06-06**

### 6.7 CODE-TRACE-07: Table Row Computation (View — table section)

| Trace Step | View Line | Expression | Description |
|-----------|----------|------------|-------------|
| TR-07-01 | 317 | `$costMaintenanceReport = $costMaintenanceReport ?? collect()` | Null-safe fallback |
| TR-07-02 | 320 | `@forelse($costMaintenanceReportPaginated as $index => $vehicle)` | Iterates paginated subset (10 items) |
| TR-07-03 | 322-328 | `$vehicleNo`, `$registrationNo`, `$totalFuelCost`, `$totalMaintenanceCost`, `$totalCost`, `$inspectionFailureRate`, `$riskLevel` | Variable extraction with null defaults |
| TR-07-04 | 330-339 | `$riskClass` logic | `HIGH => danger`, `LOW => success`, `MEDIUM => warning`, else `secondary` |
| TR-07-05 | 341-352 | `$inspectionStatusClass` logic | `$failureRate == 0 => success 'Good'`, `<= 20 => warning 'Fair'`, else `danger 'Poor'` |
| TR-07-06 | 354-368 | `$costEfficiencyClass` logic | `$totalCost == 0 => secondary 'No Cost'`, `<= 100 => success 'Efficient'`, `<= 200 => warning 'Moderate'`, else `danger 'High Cost'` |
| TR-07-07 | 370-416 | Row rendering | 6 columns with formatted data |
| TR-07-08 | 428-439 | TFOOT | TOTAL row: sum of costs + vehicle count |

**Test Coverage: TR-07-01 to TR-07-08**

### 6.8 CODE-TRACE-08: `paginateCollection()` Helper

| Trace Step | Controller Line | Code | Description |
|-----------|----------------|------|-------------|
| TR-08-01 | 264 | `$page = Paginator::resolveCurrentPage($pageName)` | Resolves current page from query string using custom page name (`page_cost`) |
| TR-08-02 | 265 | `$sliced = $items->slice(($page - 1) * $perPage, $perPage)->values()` | Slices collection for current page |
| TR-08-03 | 266-272 | `new LengthAwarePaginator($sliced, $items->count(), $perPage, $page, ['path' => Paginator::resolveCurrentPath(), 'pageName' => $pageName])` | Constructs paginator with correct path and page name |

**Test Coverage: TR-08-01 to TR-08-03**

### 6.9 CODE-TRACE-09: `parseDateRange()` Helper

| Trace Step | Controller Line | Code | Description |
|-----------|----------------|------|-------------|
| TR-09-01 | 329-332 | If `dates` param filled: split by ` - ` delimiter, parse start/end | Custom date range from daterangepicker |
| TR-09-02 | 333-335 | Else: default to current month start/end | `now()->startOfMonth()->toDateString()` and `now()->endOfMonth()->toDateString()` |

**Test Coverage: TR-09-01, TR-09-02**

---

## 7. Test Case List

### 7.1 Positive Test Cases — Tab Loading & Rendering

| TC ID | Description | Prerequisites | Test Steps | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|--------------|------------|-----------------|---------|---------|--------|
| TC-P01 | Tab loads with filter bar | DS-01, PC-01 through PC-14 | 1. Navigate to `/transport-report?active_tab=cost-maintenance` | Filter bar visible with Date Range only (no vehicle dropdown) | — | — | ⬜ |
| TC-P02 | Skeleton loaders visible before AJAX | DS-01 | 1. Load page with slow network simulation | `#cost-maintenance-charts` and `#cost-maintenance-table` contain `spinner-border` | — | — | ⬜ |
| TC-P03 | Charts section loaded via AJAX on page load | DS-01 | 1. Load page 2. Inspect network tab | GET `/transport-report?active_tab=cost-maintenance&section=charts` returns HTML with KPI boxes + charts | — | — | ⬜ |
| TC-P04 | Table section loaded via AJAX on page load | DS-01 | 1. Load page 2. Inspect network tab | GET `/transport-report?active_tab=cost-maintenance&section=table` returns HTML with 6-column table | — | — | ⬜ |
| TC-P05 | Tab switch from different tab loads sections | DS-01 | 1. Click another tab 2. Click Cost-Maintenance tab | `loadTabSection('cost-maintenance', 'charts')` and `loadTabSection('cost-maintenance', 'table')` called | — | — | ⬜ |
| TC-P06 | Tab switch does NOT re-fetch if already loaded | DS-01 | 1. Load cost-maintenance 2. Switch away 3. Switch back | No AJAX calls (container has `loaded` class) | — | — | ⬜ |
| TC-P07 | Breadcrumb shows "Transport Report" | DS-01 | 1. Load page 2. Inspect breadcrumb | `<x-backend.components.breadcrum title="Transport Report" :links="[]" />` | — | — | ⬜ |
| TC-P08 | Tab label reads "Cost-Maintenance" with bell icon | DS-01 | 1. Inspect tab button | Tab text: "Cost-Maintenance" with `fa-solid fa-bell` icon | — | — | ⬜ |

### 7.2 Positive Test Cases — KPI Boxes (Row 1)

| TC ID | Description | Prerequisites | Test Steps | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|--------------|------------|-----------------|---------|---------|--------|
| TC-P09 | KPI: Total Vehicles correct count | DS-01, DS-02, DS-03, DS-05 | 1. Load charts section | KPI shows 4 (only active vehicles; VH-004 excluded) | — | — | ⬜ |
| TC-P10 | KPI: Total Vehicles = 0 when no vehicles | ED-15 | 1. Load with empty vehicle table | KPI shows 0 | — | — | ⬜ |
| TC-P11 | KPI: Total Cost correct sum | DS-01, DS-02, DS-03, DS-05 | 1. Load charts section | Total Cost = 4500 + 1500 + 800 + 175 = ₹6,975 | — | — | ⬜ |
| TC-P12 | KPI: Total Cost = 0 when no costs | ED-15 | 1. Load with no vehicles | KPI shows ₹0 | — | — | ⬜ |
| TC-P13 | KPI: Avg Cost/Vehicle correct | DS-01, DS-02, DS-03, DS-05 | 1. Load charts section | Avg Cost = 6975 / 4 = ₹1,744 (rounded to 0 decimals) | — | — | ⬜ |
| TC-P14 | KPI: Avg Cost/Vehicle = 0 when no vehicles | ED-15 | 1. Load with no vehicles | KPI shows ₹0 | — | — | ⬜ |
| TC-P15 | KPI: High Risk Vehicles correct count | DS-01, DS-02, DS-03, DS-05 | 1. Load charts section | VH-002 (no maint = HIGH), VH-003 (UNKNOWN not HIGH). Only VH-002 = 1 HIGH risk | — | — | ⬜ |
| TC-P16 | KPI: High Risk Vehicles = 0 when all LOW risk | DS-05 only | 1. Load charts section | KPI shows 0 | — | — | ⬜ |
| TC-P17 | KPI boxes Row 1 have correct color schemes | DS-01 | 1. Inspect each KPI | Total Vehicles: `text-bg-primary`, Total Cost: `text-bg-success`, Avg Cost: `text-bg-info`, High Risk: `text-bg-danger` | — | — | ⬜ |
| TC-P18 | KPI: Total Vehicles shows plain number | DS-01 | 1. Inspect Total Vehicles KPI | `<h3>4</h3>` | — | — | ⬜ |
| TC-P19 | KPI: Total Cost shows ₹ prefix | DS-01 | 1. Inspect Total Cost KPI | `<h3>₹6,975</h3>` | — | — | ⬜ |
| TC-P20 | KPI: Avg Cost shows ₹ prefix | DS-01 | 1. Inspect Avg Cost KPI | `<h3>₹1,744</h3>` | — | — | ⬜ |
| TC-P21 | KPI: More info link navigates correctly | DS-01 | 1. Click "More info" on any KPI | Navigates to `route('transport.trip-management.index')` | — | — | ⬜ |

### 7.3 Positive Test Cases — KPI Boxes (Row 2)

| TC ID | Description | Prerequisites | Test Steps | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|--------------|------------|-----------------|---------|---------|--------|
| TC-P22 | KPI: Total Fuel Cost correct sum | DS-01, DS-02, DS-03, DS-05 | 1. Load charts section | Fuel Cost = 1000 + 1500 + 0 + 125 = ₹2,625 | — | — | ⬜ |
| TC-P23 | KPI: Total Fuel Cost = 0 when no fuel records | ED-01 | 1. Load charts section | KPI shows ₹0 | — | — | ⬜ |
| TC-P24 | KPI: Maintenance Cost correct sum | DS-01, DS-02, DS-03, DS-05 | 1. Load charts section | Maintenance Cost = 3500 + 0 + 800 + 50 = ₹4,350 | — | — | ⬜ |
| TC-P25 | KPI: Maintenance Cost = 0 when no maintenance records | ED-02 | 1. Load charts section | KPI shows ₹0 | — | — | ⬜ |
| TC-P26 | KPI: Low Risk Vehicles correct count | DS-01, DS-02, DS-03, DS-05 | 1. Load charts section | VH-001 (20% fail + has maint = MEDIUM), VH-002 (HIGH), VH-003 (UNKNOWN), VH-005 (0% fail + has maint = LOW). Only VH-005 = 1 LOW risk | — | — | ⬜ |
| TC-P27 | KPI: Low Risk Vehicles = 0 when none | DS-01, DS-02 | 1. Load charts section | KPI shows 0 (MEDIUM + HIGH, no LOW) | — | — | ⬜ |
| TC-P28 | KPI: Unknown Risk Vehicles correct count | DS-01, DS-02, DS-03, DS-05 | 1. Load charts section | VH-003 (0 inspections) = 1 UNKNOWN | — | — | ⬜ |
| TC-P29 | KPI: Unknown Risk = 0 when all have inspections | DS-01, DS-02, DS-05 | 1. Load charts section | KPI shows 0 | — | — | ⬜ |
| TC-P30 | KPI boxes Row 2 have correct color schemes | DS-01 | 1. Inspect each KPI | Fuel Cost: `text-bg-warning`, Maintenance Cost: `text-bg-secondary`, Low Risk: `text-bg-success`, Unknown Risk: `text-bg-ligth` | — | — | ⬜ |

### 7.4 Positive Test Cases — Charts

| TC ID | Description | Prerequisites | Test Steps | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|--------------|------------|-----------------|---------|---------|--------|
| TC-P31 | Cost Distribution Chart renders as doughnut | DS-01 | 1. Load charts 2. Inspect canvas | Chart.js renders doughnut chart with cutout 70% | — | — | ⬜ |
| TC-P32 | Cost Distribution Chart labels: Fuel Cost & Maintenance Cost | DS-01 | 1. Inspect chart data labels | Labels: ['Fuel Cost', 'Maintenance Cost'] | — | — | ⬜ |
| TC-P33 | Cost Distribution Chart data: Fuel vs Maintenance split | DS-01 | 1. Inspect chart dataset | Data: [2625, 4350] (fuel vs maintenance from sum) | — | — | ⬜ |
| TC-P34 | Cost Distribution Chart colors: blue (#0d6efd) for fuel, green (#198754) for maintenance | DS-01 | 1. Inspect background colors | `backgroundColor: ['#0d6efd', '#198754']` | — | — | ⬜ |
| TC-P35 | Cost Distribution Chart legend at bottom | DS-01 | 1. Inspect chart config | `legend.position = 'bottom'`, padding 20 | — | — | ⬜ |
| TC-P36 | Cost Distribution Chart tooltip shows ₹ and % | DS-01 | 1. Hover over a segment | Tooltip: "₹2,625 (37.6%)" with proper formatting | — | — | ⬜ |
| TC-P37 | Vehicle Risk Analysis Chart renders as bar | DS-01 | 1. Load charts 2. Inspect canvas | Chart.js renders bar chart | — | — | ⬜ |
| TC-P38 | Risk Chart labels: High, Low, Unknown | DS-01 | 1. Inspect chart labels | Labels: ['High', 'Low', 'Unknown'] | — | — | ⬜ |
| TC-P39 | Risk Chart data: correct counts per risk level | DS-01, DS-02, DS-03, DS-05 | 1. Inspect chart dataset | Data: [1 (HIGH), 1 (LOW), 1 (UNKNOWN)] | — | — | ⬜ |
| TC-P40 | Risk Chart colors: red (#dc3545), green (#198754), gray (#6c757d) | DS-01 | 1. Inspect background colors | `backgroundColor: ['#dc3545', '#198754', '#6c757d']` | — | — | ⬜ |
| TC-P41 | Risk Chart y-axis begins at zero with stepSize 1 | DS-01 | 1. Inspect y-axis config | `beginAtZero: true`, `stepSize: 1` | — | — | ⬜ |
| TC-P42 | Risk Chart no legend displayed | DS-01 | 1. Inspect legend config | `legend.display = false` | — | — | ⬜ |
| TC-P43 | Risk Chart tooltip shows "X Risk: Y vehicles" | DS-01 | 1. Hover over a bar | Tooltip: "High Risk: 1 vehicles" | — | — | ⬜ |
| TC-P44 | Charts render "No data" state when empty | ED-15 | 1. Load with no vehicles | Charts render with zero datasets; no errors | — | — | ⬜ |

### 7.5 Positive Test Cases — Table Data

| TC ID | Description | Prerequisites | Test Steps | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|--------------|------------|-----------------|---------|---------|--------|
| TC-P45 | Table renders 6 columns correctly | DS-01 | 1. Load table section | Columns: #, Vehicle Details, Cost (₹), Inspection, Risk Level, Status | — | — | ⬜ |
| TC-P46 | Table: # column shows sequential index | DS-01 | 1. Inspect first row # | Shows 1, 2, 3... (1-indexed) | — | — | ⬜ |
| TC-P47 | Table: Vehicle Details shows vehicle_no + registration_no | DS-01 | 1. Inspect Vehicle Details cell | `<div class="fw-semibold">VH-001</div>` + `<div class="small text-muted">REG-001</div>` | — | — | ⬜ |
| TC-P48 | Table: Vehicle icon displayed | DS-01 | 1. Inspect icon | `<i class="bi bi-truck text-primary fs-5"></i>` | — | — | ⬜ |
| TC-P49 | Table: Cost column shows ₹ total + breakdown | DS-01 (VH-001) | 1. Inspect Cost cell | `₹4,500` with subtext "Fuel: ₹1,000" + "Maintenance: ₹3,500" | — | — | ⬜ |
| TC-P50 | Table: Cost = ₹0 shows correct format | ED-04 | 1. Inspect zero-cost row | `₹0` with subtext "Fuel: ₹0" + "Maintenance: ₹0" | — | — | ⬜ |
| TC-P51 | Table: Inspection column shows failure rate % + badge | DS-01 (VH-001: 20%) | 1. Inspect Inspection cell | `20.0%` + `<span class="badge bg-warning">Fair</span>` | — | — | ⬜ |
| TC-P52 | Table: Inspection = 0% shows "Good" badge | DS-05 (0% failure) | 1. Inspect Inspection cell | `0.0%` + `<span class="badge bg-success">Good</span>` | — | — | ⬜ |
| TC-P53 | Table: Inspection >20% shows "Poor" badge | DS-02 (60% failure) | 1. Inspect Inspection cell | `60.0%` + `<span class="badge bg-danger">Poor</span>` | — | — | ⬜ |
| TC-P54 | Table: Risk Level badge shows correct color | DS-02 (HIGH) | 1. Inspect Risk Level cell | `<span class="badge bg-danger rounded-pill px-3 py-1">HIGH</span>` | — | — | ⬜ |
| TC-P55 | Table: Risk Level = MEDIUM badge | DS-01 (MEDIUM) | 1. Inspect Risk Level cell | `<span class="badge bg-warning rounded-pill">MEDIUM</span>` | — | — | ⬜ |
| TC-P56 | Table: Risk Level = LOW badge | DS-05 (LOW) | 1. Inspect Risk Level cell | `<span class="badge bg-success rounded-pill">LOW</span>` | — | — | ⬜ |
| TC-P57 | Table: Risk Level = UNKNOWN badge | DS-03 (UNKNOWN) | 1. Inspect Risk Level cell | `<span class="badge bg-secondary rounded-pill">UNKNOWN</span>` | — | — | ⬜ |
| TC-P58 | Table: Status = "No Cost" badge | ED-04 | 1. Inspect Status cell | `<span class="badge bg-secondary">No Cost</span>` | — | — | ⬜ |
| TC-P59 | Table: Status = "Efficient" badge | DS-05 (₹175 ≤ 100?) — Wait, ₹175 > 100. Need cost ≤ 100. | 1. Create vehicle with cost ≤ 100 2. Load table | `<span class="badge bg-success">Efficient</span>` | — | — | ⬜ |
| TC-P60 | Table: Status = "Moderate" badge | DS-05 (₹175, between 100 and 200) | 1. Inspect Status cell | `<span class="badge bg-warning">Moderate</span>` | — | — | ⬜ |
| TC-P61 | Table: Status = "High Cost" badge | DS-01 (₹4500 > 200) | 1. Inspect Status cell | `<span class="badge bg-danger">High Cost</span>` | — | — | ⬜ |

### 7.6 Positive Test Cases — Table Footer & Pagination

| TC ID | Description | Prerequisites | Test Steps | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|--------------|------------|-----------------|---------|---------|--------|
| TC-P62 | Table footer (TFOOT) shows TOTAL row | DS-01, DS-02, DS-03, DS-05 | 1. Inspect tfoot | `<tfoot class="table-light">` with TOTAL, sum of costs, vehicle count | — | — | ⬜ |
| TC-P63 | TFOOT: Total cost correct | DS-01, DS-02, DS-03, DS-05 | 1. Inspect footer | Shows ₹6,975 | — | — | ⬜ |
| TC-P64 | TFOOT: Vehicle count correct | DS-01, DS-02, DS-03, DS-05 | 1. Inspect footer | Shows "4 vehicles" | — | — | ⬜ |
| TC-P65 | Pagination appears with >10 records | 11+ vehicles | 1. Create 12 vehicles 2. Load table | Pagination links visible; page 1 shows first 10 records | — | — | ⬜ |
| TC-P66 | Click page 2 loads next set of records | 12 vehicles | 1. Click page 2 | 2 records shown; page 2 highlighted | — | — | ⬜ |
| TC-P67 | Pagination uses `page_cost` param | 12 vehicles | 1. Click page 2 2. Inspect URL | URL contains `?page_cost=2` | — | — | ⬜ |
| TC-P68 | Pagination appends existing filter params | DS-01 + 12 vehicles | 1. Apply filter 2. Navigate to page 2 | Pagination links include `from_date=X&to_date=X&page_cost=2` | — | — | ⬜ |
| TC-P69 | Pagination does NOT conflict with other tab pagination | 12 vehicles + other tab loaded | 1. Load cost-maintenance page 2 2. Switch to other tab 3. Switch back | cost-maintenance pagination at page 2 preserved; other tab pagination params not interfering | — | — | ⬜ |
| TC-P70 | Single page (≤10 records) hides pagination | DS-01 (4 records) | 1. Load table with 4 records | Pagination not displayed | — | — | ⬜ |
| TC-P71 | Empty collection pagination shows empty table | ED-15 | 1. Load with no vehicles | Empty table with colspan="6", no pagination | — | — | ⬜ |

### 7.7 Positive Test Cases — AJAX & SPA Behavior

| TC ID | Description | Prerequisites | Test Steps | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|--------------|------------|-----------------|---------|---------|--------|
| TC-P72 | Page load calls 2 AJAX requests | DS-01 | 1. Load page 2. Monitor network panel | 2 requests: `section=charts` and `section=table` | — | — | ⬜ |
| TC-P73 | AJAX response contains rendered HTML (not JSON data) | DS-01 | 1. Inspect AJAX response | `{html: "<div class=...>"}` — pre-rendered Blade HTML | — | — | ⬜ |
| TC-P74 | Filter form submit: both sections reloaded simultaneously | DS-01 | 1. Apply filter 2. Monitor network | 2 parallel AJAX requests | — | — | ⬜ |
| TC-P75 | Pagination click reloads only table section | DS-01 (12 vehicles) | 1. Click page 2 | Only `section=table` request; charts not re-fetched | — | — | ⬜ |
| TC-P76 | Opacity dimming during AJAX load | DS-01 | 1. Slow network 2. Load page | Container opacity set to 0.5 | — | — | ⬜ |
| TC-P77 | Opacity restored after AJAX success | DS-01 | 1. Load page 2. Wait for AJAX completion | Container opacity restored to 1 | — | — | ⬜ |
| TC-P78 | Error message on AJAX failure | Simulate 500 error | 1. Trigger AJAX 2. Force server error | `<div class="alert alert-danger">Failed to load ...</div>` shown | — | — | ⬜ |
| TC-P79 | `loadTabSection` handles empty container gracefully | None | 1. Remove `#cost-maintenance-charts` from DOM 2. Trigger reload | No JS error; function returns early | — | — | ⬜ |
| TC-P80 | Tab switch from filter-submitted state preserves filters | DS-01 | 1. Apply filter 2. Switch to other tab 3. Switch back | Filters preserved in form; data re-fetched with same filters | — | — | ⬜ |
| TC-P81 | Charts AJAX returns valid JSON with `html` key | DS-01 | 1. Inspect AJAX response for section=charts | `{"html": "<div class=...>"}` — valid JSON, single `html` property | — | — | ⬜ |
| TC-P82 | Table AJAX returns valid JSON with `html` key | DS-01 | 1. Inspect AJAX response for section=table | `{"html": "<table class=...>"}` — valid JSON | — | — | ⬜ |
| TC-P83 | Content-Type is `application/json` | DS-01 | 1. Inspect response headers for AJAX | `Content-Type: application/json` | — | — | ⬜ |
| TC-P84 | Invalid tab returns fallback HTML, not error | None | 1. Send AJAX with `active_tab=invalid_tab` | Returns `<p class="text-muted">Invalid tab</p>` in HTML | — | — | ⬜ |

### 7.8 Negative Test Cases

| TC ID | Description | Prerequisites | Test Steps | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|--------------|------------|-----------------|---------|---------|--------|
| TC-N01 | No vehicles in system | ED-15 | 1. Load charts + table | Charts: All KPIs = 0; Table: "No vehicle cost and maintenance data found" | — | — | ⬜ |
| TC-N02 | Vehicle with no fuel, no maintenance, no inspections | ED-04 | 1. Load report | Zero costs, risk_level = UNKNOWN, Status = "No Cost" | — | — | ⬜ |
| TC-N03 | Vehicle with no inspections but has maintenance | ED-04 (has maint but 0 inspections) | 1. Load report | risk_level = UNKNOWN (totalInspections = 0 takes precedence over $maintenanceCount) | — | — | ⬜ |
| TC-N04 | 403 without `tenant.cost-maintenance.viewAny` permission | Revoke permission from test user | 1. Load page 2. Try to access tab | Tab hidden in nav (no tab button); content not rendered | — | — | ⬜ |
| TC-N05 | Guest access (unauthenticated) | Logout | 1. Access `/transport-report?active_tab=cost-maintenance` | Redirected to login page | — | — | ⬜ |
| TC-N06 | No `tenant.transport.viewAny` on hub page | Revoke transport permission | 1. Access `/transport-report` | 403 Forbidden from `Gate::authorize('tenant.transport.viewAny')` | — | — | ⬜ |
| TC-N07 | Vehicle with 100% failure rate (all inspections failed) | ED-05 | 1. Load report | Risk = HIGH, Inspection badge = "Poor", failure rate = 100% | — | — | ⬜ |
| TC-N08 | Vehicle with 0% failure rate but no maintenance | DS-02 variant: 0 failures, 0 maint | 1. Load report | Risk = HIGH ($maintenanceCount === 0), Inspection = "Good" | — | — | ⬜ |
| TC-N09 | Vehicle with failure rate exactly 15% | ED-09 | 1. Load report | Risk = LOW (15% is NOT > 15) | — | — | ⬜ |
| TC-N10 | Vehicle with failure rate exactly 30% | ED-10 | 1. Load report | Risk = MEDIUM (30% is NOT > 30, and has maint) | — | — | ⬜ |
| TC-N11 | Vehicle with failure rate 15.1% | DS-01 variant: exactly 15.1% | 1. Load report | Risk = MEDIUM (> 15) | — | — | ⬜ |
| TC-N12 | Vehicle with failure rate 30.1% | DS-01 variant: exactly 30.1% | 1. Load report | Risk = HIGH (> 30) | — | — | ⬜ |
| TC-N13 | AJAX request with invalid tab name | None | 1. Send AJAX `?active_tab=nonexistent&section=charts` | Returns `<p class="text-muted">Invalid tab</p>` | — | — | ⬜ |
| TC-N14 | AJAX request with missing section | DS-01 | 1. Send AJAX `?active_tab=cost-maintenance` (no section) | Non-AJAX branch: returns full hub view (not JSON) | — | — | ⬜ |
| TC-N15 | Invalid page_cost value (negative) | DS-01 | 1. Navigate to `?page_cost=-1` 2. Load table | Page resolves to 1 (slice handles gracefully) | — | — | ⬜ |
| TC-N16 | Invalid page_cost value (string) | DS-01 | 1. Navigate to `?page_cost=abc` 2. Load table | `resolveCurrentPage` returns null, defaults to 1 | — | — | ⬜ |
| TC-N17 | Date range with invalid format | DS-01 | 1. Set `dates=invalid` 2. Submit filter | `parseDateRange()` split fails; falls to default month range | — | — | ⬜ |
| TC-N18 | Vehicle ID filter with non-existent ID (via direct request) | DS-01 | 1. Send `?active_tab=cost-maintenance&vehicle_id=99999` | Empty collection; "No vehicle cost and maintenance data found" | — | — | ⬜ |
| TC-N19 | Inactive vehicle excluded from report | DS-04 | 1. Load report | VH-004 (inactive) not in results; total count excludes it | — | — | ⬜ |
| TC-N20 | Chart.js CDN fails to load | Disable CDN in test | 1. Load page with chart.js blocked | Console error: "Chart is not defined"; charts don't render | — | — | ⬜ |
| TC-N21 | daterangepicker CDN fails | Disable CDN | 1. Load page with daterangepicker blocked | Date range input not initialized; no date picker functionality | — | — | ⬜ |
| TC-N22 | jQuery CDN fails | Disable CDN | 1. Load page with jQuery blocked | All AJAX logic fails; page load JS errors | — | — | ⬜ |
| TC-N23 | AJAX endpoint returns 500 error | Simulate server error | 1. Load tab section 2. Trigger server error | Alert message: "Failed to load charts." / "Failed to load table." | — | — | ⬜ |

### 7.9 Edge Case Test Cases

| TC ID | Description | Prerequisites | Test Steps | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|--------------|------------|-----------------|---------|---------|--------|
| TC-EC-01 | All vehicles have zero fuel cost | All fuel logs deleted | 1. Load report | Fuel Cost KPI = ₹0; Cost Distribution chart shows 0% fuel | — | — | ⬜ |
| TC-EC-02 | All vehicles have zero maintenance cost | All maintenance records deleted | 1. Load report | Maintenance Cost KPI = ₹0; all risk = HIGH (no maint) or UNKNOWN (no insp) | — | — | ⬜ |
| TC-EC-03 | All vehicles have UNKNOWN risk | No inspections for any vehicle | 1. Load report | Unknown Risk KPI = total vehicles; Risk chart shows all UNKNOWN | — | — | ⬜ |
| TC-EC-04 | All vehicles have HIGH risk | All have >30% failure or 0 maintenance | 1. Load report | High Risk KPI = total vehicles; Cost Efficiency = varies | — | — | ⬜ |
| TC-EC-05 | Single vehicle in entire dataset | Only 1 active vehicle | 1. Load report | 1 row in table; 1 bar per chart; no pagination; Avg Cost = total cost | — | — | ⬜ |
| TC-EC-06 | Single vehicle with zero cost | ED-04 | 1. Load report | Avg Cost = ₹0; Status = "No Cost" | — | — | ⬜ |
| TC-EC-07 | All costs are exact boundary values | All vehicles cost exactly ₹100 | 1. Load report | Status = "Efficient" (≤100) | — | — | ⬜ |
| TC-EC-08 | All costs are exactly ₹200 | All vehicles cost exactly ₹200 | 1. Load report | Status = "Moderate" (≤200) | — | — | ⬜ |
| TC-EC-09 | All costs are exactly ₹200.01 | All vehicles cost ₹200.01 | 1. Load report | Status = "High Cost" (>200) | — | — | ⬜ |
| TC-EC-10 | All inspection failure rates = 0% | All inspections passed | 1. Load report | All inspection badges = "Good" | — | — | ⬜ |
| TC-EC-11 | All inspection failure rates = 20% | All have exactly 20% failure | 1. Load report | All inspection badges = "Fair" (≤20 boundary) | — | — | ⬜ |
| TC-EC-12 | All inspection failure rates = 20.1% | All have exactly 20.1% failure | 1. Load report | All inspection badges = "Poor" (>20) | — | — | ⬜ |
| TC-EC-13 | Fuel log cost with 3 decimal places (e.g., 100.123) | Fuel cost = 100.123 | 1. Load report | total_fuel_cost rounded to 100.12 via `round(X, 2)` | — | — | ⬜ |
| TC-EC-14 | Vehicle with no `vehicle_no` (null) | Create vehicle with null vehicle_no | 1. Load report | Vehicle Details shows empty/no text; no crash | — | — | ⬜ |
| TC-EC-15 | Vehicle with no `registration_no` (null) | Create vehicle with null registration_no | 1. Load report | Registration subtext shows empty; no crash | — | — | ⬜ |
| TC-EC-16 | Vehicle with very long vehicle_no (>50 chars) | Create vehicle with 100-char vehicle_no | 1. Load report | Table layout may break; no truncation applied | — | — | ⬜ |
| TC-EC-17 | Vehicle with extremely high cost (₹9,99,999.99) | Fuel cost = 999999.99 | 1. Load report | `number_format($totalCost, 0)` outputs "₹1,000,000" | — | — | ⬜ |
| TC-EC-18 | Date range gap: data still shows outside range | Fuel logs outside current month | 1. Set date range to previous month 2. Load report | Fuel cost still shows all-time values (date filter not applied) | — | — | ⬜ |

### 7.10 Permission & Access Control Test Cases

| TC ID | Description | Prerequisites | Test Steps | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|--------------|------------|-----------------|---------|---------|--------|
| TC-PM-01 | User with `tenant.cost-maintenance.viewAny` can see tab | PC-01 | 1. Login as permitted user 2. Load transport report | Cost-Maintenance tab visible | — | — | ⬜ |
| TC-PM-02 | User WITHOUT `tenant.cost-maintenance.viewAny` tab hidden | Revoke permission | 1. Login as restricted user 2. Load transport report | Tab nav button hidden; `@include` not executed | — | — | ⬜ |
| TC-PM-03 | User with `tenant.cost-maintenance.viewAny` but no `tenant.transport.viewAny` | Assign cost-maintenance but not transport | 1. Access `/transport-report?active_tab=cost-maintenance` | 403 on `Gate::authorize('tenant.transport.viewAny')` in index() | — | — | ⬜ |
| TC-PM-04 | Direct URL access without permission | Revoke cost-maintenance | 1. Direct AJAX call `?active_tab=cost-maintenance&section=charts` | No explicit Gate in `buildCostMaintenanceSection()` — relies on tab being hidden | — | — | ⬜ |
| TC-PM-05 | Permission string matches `permissionslist.php` | Check `config/permissionslist.php` | 1. Assert `tenant.cost-maintenance.viewAny` exists in config | Permission group defined with key `cost-maintenance` | — | — | ⬜ |

### 7.11 Data Integrity Test Cases

| TC ID | Description | Prerequisites | Test Steps | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|--------------|------------|-----------------|---------|---------|--------|
| TC-DI-01 | Fuel cost matches sum of TptVehicleFuel where status=Approved | DS-01 (VH-001: 500+300+200=1000) | 1. Query DB for VH-001 fuel logs 2. Compare with report | `$vehicle->fuelLogs->sum('cost')` = direct DB SUM query | — | — | ⬜ |
| TC-DI-02 | Maintenance cost matches sum of approved maintenance records | DS-01 (VH-001: 2000+1500=3500) | 1. Query DB for VH-001 maintenance 2. Compare | Value matches controller computation | — | — | ⬜ |
| TC-DI-03 | Total cost = fuel + maintenance | DS-01 (VH-001: 1000+3500=4500) | 1. Manual calculation 2. Compare | `total_cost` = `total_fuel_cost` + `total_maintenance_cost` | — | — | ⬜ |
| TC-DI-04 | Failed inspection count matches actual Failed records | DS-01 (VH-001: 2 Failed) | 1. Count failed inspections in DB 2. Compare | [Query/Code Removed] | — | — | ⬜ |
| TC-DI-05 | Failure rate computed as (failed/total)*100 | DS-01 (VH-001: 2/10*100=20.0) | 1. Manual calc 2. Compare | `inspection_failure_rate` = 20.0 | — | — | ⬜ |
| TC-DI-06 | Failure rate = 0 when no inspections | DS-03 (VH-003: totalInspections=0) | 1. Check guard | `totalInspections ? round(...) : 0` = 0 (division by zero guarded) | — | — | ⬜ |
| TC-DI-07 | Active scope excludes inactive vehicles | DS-04 (VH-004 inactive) | 1. Load report | VH-004 not in collection | — | — | ⬜ |
| TC-DI-08 | Date filter NOT applied to fuel logs | Fuel logs outside current month | 1. Set date to month with no fuel records 2. Load | Fuel cost unchanged (all-time data shown) — this is the known gap | — | — | ⬜ |
| TC-DI-09 | Date filter NOT applied to maintenance records | Maint records outside current month | 1. Set date range to empty month 2. Load | Maintenance cost unchanged (all-time data shown) | — | — | ⬜ |
| TC-DI-10 | Date filter NOT applied to inspections | Inspection records outside date range | 1. Set date range with no inspections 2. Load | Inspection count unchanged (all-time data shown) | — | — | ⬜ |
| TC-DI-11 | Vehicle filter by vehicle_id works | DS-01, DS-02 | 1. Direct AJAX with `vehicle_id=VH-001-id` | Only VH-001 data shown (filter not exposed in UI but works in controller) | — | — | ⬜ |
| TC-DI-12 | map produces correct number of rows | DS-01, DS-02, DS-03, DS-05 (4 active) | 1. Count result rows | 4 rows (VH-001, VH-002, VH-003, VH-005) | — | — | ⬜ |

### 7.12 Code Review Test Cases

| TC ID | Priority | Description | Expected Result | Status |
|-------|----------|-------------|-----------------|--------|
| TC-CR01 | P1 | Date range NOT applied to fuel/maintenance/inspection queries | Fuel and maintenance costs NOT filtered by date range — possible data integrity issue. Lines 841-846: `$vehicle->fuelLogs`, `$vehicle->maintenanceRecords`, `$vehicle->inspections` all load ALL records. `$startDate` and `$endDate` parameters are passed but never used in these relationship queries. | ◌ |
| TC-CR02 | P1 | Risk level UNKNOWN guard | `$totalInspections === 0` returns 'UNKNOWN' at line 957 — correct behavior | ◌ |
| TC-CR03 | P1 | No vehicle_id filter in blade | Blade filter bar only shows date range; vehicle_id not exposed in UI despite controller accepting it at line 837 | ◌ |
| TC-CR04 | P1 | Table total footer | `tfoot` shows sum of total cost and vehicle count at view lines 428-439 | ◌ |
| TC-CR05 | P1 | Pagination uses `page_cost` | `$this->paginateCollection($costMaintenanceReport, 10, 'page_cost')` at line 171 — no conflict with other report tabs | ◌ |
| TC-CR06 | P1 | `buildCostMaintenanceSection` shares same view for both sections | Both `charts` and `table` sections use same view; conditional rendering via `@if(request('section') === 'charts')` / `@elseif(request('section') === 'table')` / `@else` | ◌ |
| TC-CR07 | P1 | Null-safe collection handling in view | `$costMaintenanceReport = $costMaintenanceReport ?? collect()` at line 9 (charts) and line 317 (table) prevents null errors on empty collection | ◌ |
| TC-CR08 | P1 | Division by zero guarded for avg cost | `$totalVehicles > 0 ? round($totalCost / $totalVehicles, 0) : 0` at view line 14 | ◌ |
| TC-CR09 | P1 | Division by zero guarded for failure rate | `$totalInspections ? round(($failedInspections / $totalInspections) * 100, 1) : 0` at controller line 854 | ◌ |
| TC-CR10 | P1 | `Gate::authorize('tenant.transport.viewAny')` guards index() | Line 36 — unauthorized users get 403 before any data loads | ◌ |
| TC-CR11 | P1 | AJAX-only section=charts/table response | Controller returns `response()->json(['html' => $html])` — not a full page render | ◌ |
| TC-CR12 | P1 | `active()` scope on Vehicle query | `->active()` at line 838 ensures only active vehicles contribute data | ◌ |
| TC-CR13 | P1 | `map()` returns `Collection` not array | `->map()` returns Laravel Collection, correctly handled for pagination upstream | ◌ |
| TC-CR14 | P1 | `round()` applied consistently | All cost values `round(X, 2)`, failure rate `round(X, 1)`, avg cost `round(X, 0)` | ◌ |
| TC-CR15 | P1 | N+1 query risk on fuelLogs/maintenanceRecords/inspections | Vehicle query does NOT eager-load fuelLogs, maintenanceRecords, or inspections. Each vehicle triggers 3 additional queries (one per relationship) = 1 + 3N queries | ◌ |
| TC-CR16 | P2 | `request()->merge(['section' => $section])` in builder | Builder merges section into request so `@if(request('section') === 'charts')` works in rendered view | ◌ |
| TC-CR17 | P2 | Same-origin AJAX requests | `url: window.location.pathname` — requests go to same URL, avoids CORS | ◌ |
| TC-CR18 | P2 | `page_cost` param not confused with other tabs' page params | Paginator resolves `page_cost` param separately from `page_stop`, `page_route`, etc. | ◌ |
| TC-CR19 | P2 | Chart variable scoping: no global pollution | Chart variables initialized inside view script block using `const` — scoped to the inline script | ◌ |
| TC-CR20 | P2 | `@can('tenant.cost-maintenance.viewAny')` double security | Hub view has both tab `permission` key AND `@can` around `@include` | ◌ |

### 7.13 UI/UX Test Cases

| TC ID | Description | Prerequisites | Test Steps | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|--------------|------------|-----------------|---------|---------|--------|
| TC-UI-01 | Page title shows "Transport Report" breadcrumb | DS-01 | 1. Load page 2. Inspect breadcrumb | `<x-backend.components.breadcrum title="Transport Report" :links="[]" />` | — | — | ⬜ |
| TC-UI-02 | Tab label reads "Cost-Maintenance" | DS-01 | 1. Inspect tab button | Tab text: "Cost-Maintenance" with `fa-solid fa-bell` icon | — | — | ⬜ |
| TC-UI-03 | Filter bar aligns horizontally with proper spacing | DS-01 | 1. Load page 2. Inspect filter bar | Flex layout with `gap-2`, all filter elements in one row | — | — | ⬜ |
| TC-UI-04 | Date range input has calendar icon | DS-01 | 1. Inspect date input | `input-group-text` with `<i class="bi bi-calendar3"></i>` | — | — | ⬜ |
| TC-UI-05 | Chart cards have shadow and borderless style | DS-01 | 1. Inspect chart containers | `card h-100 shadow-sm` CSS classes applied | — | — | ⬜ |
| TC-UI-06 | Table rows have hover effect | DS-01 | 1. Hover over table row | Visual highlight on hover (Bootstrap default) | — | — | ⬜ |
| TC-UI-07 | Empty table state has centered icon and text | ED-15 | 1. Load with no data | Centered `bi-inbox` icon + "No vehicle cost and maintenance data found" in muted text | — | — | ⬜ |
| TC-UI-08 | Table header row has dark header | DS-01 | 1. Inspect `<thead>` | Default Bootstrap `thead` styling (darker background) | — | — | ⬜ |
| TC-UI-09 | KPI boxes use `small-box` component with SVG icons | DS-01 | 1. Inspect any KPI | `small-box` div with `small-box-icon` SVG and `small-box-footer` | — | — | ⬜ |
| TC-UI-10 | Filter button has search icon | DS-01 | 1. Inspect submit button | `<i class="fas fa-filter"></i>` | — | — | ⬜ |
| TC-UI-11 | Reset button has redo icon | DS-01 | 1. Inspect reset link | `<i class="fas fa-redo"></i>` | — | — | ⬜ |
| TC-UI-12 | Responsive: charts stack on small screens | DS-01 | 1. Resize to <992px | Chart cards stack vertically (col-lg-6 → full width) | — | — | ⬜ |
| TC-UI-13 | KPI boxes responsive at breakpoints | DS-01 | 1. Test at <768px, <992px, <1200px | KPI grid: col-lg-3 col-6 → 2 per row at <992px, 4 per row at ≥992px | — | — | ⬜ |
| TC-UI-14 | Risk level badge uses `rounded-pill` for pill shape | DS-01 | 1. Inspect risk badge | `<span class="badge bg-* rounded-pill px-3 py-1">` | — | — | ⬜ |
| TC-UI-15 | Vehicle details has icon + two-line layout | DS-01 | 1. Inspect vehicle cell | Flex layout: icon + div with fw-semibold no + small reg | — | — | ⬜ |
| TC-UI-16 | Cost column right-aligned | DS-01 | 1. Inspect Cost cell | `class="text-end"` | — | — | ⬜ |
| TC-UI-17 | Pagination centered below table | DS-01 (12 vehicles) | 1. Inspect pagination container | `d-flex justify-content-center mt-3` | — | — | ⬜ |
| TC-UI-18 | Table uses `table-sm` for compact layout | DS-01 | 1. Inspect table class | `table table-sm` | — | — | ⬜ |
| TC-UI-19 | Skeleton loader shows before AJAX completes | DS-01 (throttled network) | 1. Throttle network to Slow 3G 2. Load page | Spinner with "Loading..." sr-only text visible | — | — | ⬜ |
| TC-UI-20 | KPI boxes Row 1 and Row 2 separated by `mt-3` margin | DS-01 | 1. Inspect KPI rows | Two `<div class="row mt-3">` blocks | — | — | ⬜ |

### 7.14 JavaScript Console & Error Handling Test Cases

| TC ID | Description | Prerequisites | Test Steps | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|--------------|------------|-----------------|---------|---------|--------|
| TC-JS-01 | No JS console errors on page load | DS-01 | 1. Open browser console 2. Load page | Zero errors, warnings, or uncaught exceptions | — | — | ⬜ |
| TC-JS-02 | No JS errors on filter submit | DS-01 | 1. Open console 2. Apply filter | Zero console errors | — | — | ⬜ |
| TC-JS-03 | No JS errors on tab switch | DS-01 | 1. Open console 2. Switch tabs | Zero console errors | — | — | ⬜ |
| TC-JS-04 | No JS errors on pagination click | DS-01 (12 vehicles) | 1. Open console 2. Click page 2 | Zero console errors | — | — | ⬜ |
| TC-JS-05 | No JS errors when dataset empty | ED-15 | 1. Open console 2. Load with empty data | Zero errors — empty arrays passed to Chart.js gracefully | — | — | ⬜ |
| TC-JS-06 | No JS errors on window resize | DS-01 | 1. Open console 2. Resize browser multiple times | Zero errors — Chart.js handles resize automatically | — | — | ⬜ |
| TC-JS-07 | Chart variable scoping: no global pollution | DS-01 | 1. Inspect `window.costDistributionChart`, `window.riskAnalysisChart` | Variables are block-scoped (const) within the view script | — | — | ⬜ |
| TC-JS-08 | daterangepicker init does not error on hidden inputs | DS-01 | 1. Check console for daterangepicker errors | No errors about missing `.transport_from_date` or `.transport_to_date` | — | — | ⬜ |
| TC-JS-09 | Multiple rapid tab switches don't cause race conditions | DS-01 | 1. Rapidly switch between tabs 3-4 times | Last tab loaded correctly; no duplicate content or broken state | — | — | ⬜ |
| TC-JS-10 | Chart.js `new Chart()` called after DOM ready | DS-01 | 1. Check that Chart constructors inside `@if(section === 'charts')` | Charts only initialized when charts section is rendered (not during table-only AJAX) | — | — | ⬜ |

### 7.15 Performance & Scalability Test Cases

| TC ID | Description | Prerequisites | Test Steps | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|--------------|------------|-----------------|---------|---------|--------|
| TC-PF-01 | N+1 query problem: fuelLogs, maintenanceRecords, inspections | 50 vehicles | 1. Load report 2. Profile DB queries | No eager loading = 1 (vehicles) + 3*N (fuel, maint, insp) queries. With 50 vehicles = 151 queries | — | — | ⬜ |
| TC-PF-02 | Collection pagination handles 1000+ vehicles | 1000 active vehicles | 1. Load table section | Page loads with first 10 rows; pagination works for 100 pages | — | — | ⬜ |
| TC-PF-03 | In-memory pagination memory usage | 1000 vehicles | 1. Load report 2. Monitor memory | Entire collection loaded into memory before pagination — may be heavy at scale | — | — | ⬜ |
| TC-PF-04 | Chart rendering with 100+ vehicles | 100 vehicles | 1. Load charts section | 100 bars in risk chart; doughnut shows aggregated data (no per-vehicle bars) | — | — | ⬜ |
| TC-PF-05 | Concurrent AJAX requests timing | DS-01 | 1. Measure charts + table load time | Both sections load in parallel; total time ≈ max(charts_time, table_time) | — | — | ⬜ |
| TC-PF-06 | Vehicle count affects chart performance | 500 vehicles | 1. Load charts section | Risk chart shows 500 bars but only 3 categories — still 3 bars. Performance OK. | — | — | ⬜ |

### 7.16 Regression Test Cases

| TC ID | Description | Related Change | Test Steps | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|------------|-----------------|---------|---------|--------|
| TC-RG-01 | Other report tabs still work after cost-maintenance changes | `loadTabSection()` match block | 1. Load route-performance tab 2. Verify data loads | Route Performance tab unaffected | — | — | ⬜ |
| TC-RG-02 | Pagination on other tabs still works | `page_cost` unique name | 1. Load route-performance page 2 2. Switch to cost-maintenance page 2 3. Verify | Each tab maintains its own page state | — | — | ⬜ |
| TC-RG-03 | Other tab `@can` permissions preserved | `transportreport.blade.php` | 1. Verify all 11 tabs have `@can` wrappers | No tab accidentally broken by changes to cost-maintenance section | — | — | ⬜ |
| TC-RG-04 | Filter data dropdowns for other tabs still populated | `getFilterData()` | 1. Check routes, vehicles, shifts dropdowns in other tabs | All filter dropdowns populated correctly | — | — | ⬜ |
| TC-RG-05 | Chart.js CDN still serves other charts | CDN loaded once in hub view | 1. Check all tab charts render | Single Chart.js instance serves all charts across tabs | — | — | ⬜ |
| TC-RG-06 | Date range picker works across all tabs | Shared daterangepicker init | 1. Switch tabs 2. Change date range 3. Switch back | Date range preserved across tab switches | — | — | ⬜ |
| TC-RG-07 | Adding new vehicles affects only cost-maintenance, not other tabs | Create new vehicle | 1. Create new vehicle 2. Check all report tabs | Only cost-maintenance data changes; other tabs unaffected | — | — | ⬜ |

### 7.17 Cross-Browser & Responsive Test Cases

| TC ID | Description | Prerequisites | Test Steps | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|--------------|------------|-----------------|---------|---------|--------|
| TC-CB-01 | Chrome: All KPI boxes render with correct colors | DS-01 | 1. Load in Chrome 120+ 2. Inspect KPI boxes | Colors match: primary, success, info, danger, warning, secondary, success, ligth | — | — | ⬜ |
| TC-CB-02 | Chrome: Chart.js renders both charts | DS-01 | 1. Load in Chrome 2. Inspect canvases | Both charts rendered; Chart.js detected | — | — | ⬜ |
| TC-CB-03 | Firefox: All KPI boxes render with correct colors | DS-01 | 1. Load in Firefox 120+ 2. Inspect | Same as Chrome | — | — | ⬜ |
| TC-CB-04 | Firefox: Chart.js renders both charts | DS-01 | 1. Load in Firefox 2. Inspect | Both charts rendered | — | — | ⬜ |
| TC-CB-05 | Edge: Tab navigation works | DS-01 | 1. Load in Edge 2. Switch tabs | Tab switch triggers AJAX | — | — | ⬜ |
| TC-CB-06 | Safari: daterangepicker opens correctly | DS-01 | 1. Load in Safari 2. Click date input | daterangepicker dropdown appears | — | — | ⬜ |
| TC-CB-07 | Mobile viewport (375px width): layout adapts | DS-01 | 1. Set viewport to 375px 2. Load page | KPI boxes stack 2 per row; table horizontally scrollable; filter bar wraps | — | — | ⬜ |
| TC-CB-08 | Tablet viewport (768px width): layout adapts | DS-01 | 1. Set viewport to 768px 2. Load page | KPI boxes 2-column grid; charts stack vertically; filter bar wraps gracefully | — | — | ⬜ |
| TC-CB-09 | Desktop 1366px: standard layout | DS-01 | 1. Set viewport 1366px | 4-column KPI grid; 6+6 charts layout; full-width table | — | — | ⬜ |
| TC-CB-10 | Desktop 1920px widescreen: no excessive whitespace | DS-01 | 1. Set viewport 1920px 2. Inspect | Content centered within `container-fluid`; no excessive whitespace | — | — | ⬜ |

### 7.18 Localization / Internationalization Test Cases

| TC ID | Description | Prerequisites | Test Steps | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|--------------|------------|-----------------|---------|---------|--------|
| TC-L10N-01 | Vehicle number with Unicode characters | Create vehicle "VH-印度-001" | 1. Load report 2. Inspect vehicle details column | Unicode displayed correctly; no encoding issues | — | — | ⬜ |
| TC-L10N-02 | Registration number with non-ASCII characters | Create reg "MH-01-éå-1234" | 1. Load report 2. Inspect reg subtext | Accented characters render correctly | — | — | ⬜ |
| TC-L10N-03 | Number formatting with comma separator | DS-01 (total=6975) | 1. Check cost display | `number_format(6975, 0)` = "6,975" | — | — | ⬜ |
| TC-L10N-04 | Decimal separator consistency | DS-01 (failure rate 20.0) | 1. Check failure rate display | Uses period (.) as decimal separator; value = "20.0" | — | — | ⬜ |
| TC-L10N-05 | Currency symbol prefix | DS-01 | 1. Check any cost display | All costs prefixed with `₹` (Indian Rupee symbol) | — | — | ⬜ |
| TC-L10N-06 | RTL language support (if applicable) | DS-01 | 1. Set dir="rtl" on HTML | Table layout, chart axes adjust to RTL | — | — | ⬜ |

### 7.19 Accessibility (a11y) Test Cases

| TC ID | Description | Prerequisites | Test Steps | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|--------------|------------|-----------------|---------|---------|--------|
| TC-A11Y-01 | Filter inputs have accessible labels | DS-01 | 1. Inspect form inputs | Date range input has visible label/placeholder | — | — | ⬜ |
| TC-A11Y-02 | Table headers use `<th>` elements | DS-01 | 1. Inspect table | 6 `<th>` elements with meaningful text content | — | — | ⬜ |
| TC-A11Y-03 | SVG icons are decorative | DS-01 | 1. Inspect SVG icons in KPI | SVGs are presentational; no alt text needed | — | — | ⬜ |
| TC-A11Y-04 | Chart canvases have accessible fallback | DS-01 | 1. Inspect canvas elements | `<canvas>` may not have descriptive title or aria-label | — | — | ⬜ |
| TC-A11Y-05 | Color not sole means of conveying risk info | DS-01 | 1. Check risk badges | Badge text + color: "HIGH" (not just red color) | — | — | ⬜ |
| TC-A11Y-06 | Keyboard navigation: filter form | DS-01 | 1. Tab through filter controls | All controls focusable; submit via Enter works | — | — | ⬜ |
| TC-A11Y-07 | Keyboard navigation: pagination | DS-01 (12 vehicles) | 1. Tab to pagination links 2. Press Enter | Page changes correctly | — | — | ⬜ |
| TC-A11Y-08 | Color contrast: badge text on colored background | DS-01 | 1. Measure contrast ratio | Badge text (#fff on colored bg) has sufficient contrast (≥4.5:1) | — | — | ⬜ |
| TC-A11Y-09 | Screen reader: table data readable | DS-01 | 1. Enable screen reader 2. Navigate table | Table structure semantic; row/column headers announced | — | — | ⬜ |
| TC-A11Y-10 | Inspection status conveyed by both text and color | DS-01 | 1. Check inspection badge | Text: "Good"/"Fair"/"Poor" + color. Not only color-dependent | — | — | ⬜ |

### 7.20 Data Aggregation / Computation Test Cases

| TC ID | Description | Prerequisites | Test Steps | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|--------------|------------|-----------------|---------|---------|--------|
| TC-DC-01 | Total fuel cost: single fuel record | 1 fuel record, cost=500 | 1. Load report | `total_fuel_cost` = 500.00 | — | — | ⬜ |
| TC-DC-02 | Total fuel cost: multiple fuel records | 3 records: 500, 300, 200 | 1. Load report | `total_fuel_cost` = 1000.00 | — | — | ⬜ |
| TC-DC-03 | Total fuel cost: zero records | ED-01 | 1. Load report | `total_fuel_cost` = 0.00 | — | — | ⬜ |
| TC-DC-04 | Total maint cost: single record | 1 maint record, cost=2000 | 1. Load report | `total_maintenance_cost` = 2000.00 | — | — | ⬜ |
| TC-DC-05 | Total maint cost: multiple records | 2 records: 2000, 1500 | 1. Load report | `total_maintenance_cost` = 3500.00 | — | — | ⬜ |
| TC-DC-06 | Total maint cost: zero records | ED-02 | 1. Load report | `total_maintenance_cost` = 0.00 | — | — | ⬜ |
| TC-DC-07 | Total cost: fuel + maintenance | fuel=1000, maint=3500 | 1. Load report | `total_cost` = 4500.00 | — | — | ⬜ |
| TC-DC-08 | Total cost: zero when both zero | ED-04 | 1. Load report | `total_cost` = 0.00 | — | — | ⬜ |
| TC-DC-09 | Failure rate: 0% (all passed) | 5 passed, 0 failed | 1. Load report | `inspection_failure_rate` = 0.0 | — | — | ⬜ |
| TC-DC-10 | Failure rate: 50% | 5 passed, 5 failed | 1. Load report | `inspection_failure_rate` = 50.0 | — | — | ⬜ |
| TC-DC-11 | Failure rate: 100% (all failed) | 0 passed, 10 failed | 1. Load report | `inspection_failure_rate` = 100.0 | — | — | ⬜ |
| TC-DC-12 | Failure rate: 0 inspections → 0 | ED-03 | 1. Load report | `inspection_failure_rate` = 0 (guarded) | — | — | ⬜ |
| TC-DC-13 | Failure rate rounding: 2/3 = 66.666...% | 1 passed, 2 failed | 1. Load report | `round((2/3)*100, 1)` = 66.7 | — | — | ⬜ |
| TC-DC-14 | Avg cost per vehicle: 0 vehicles | ED-15 | 1. Load report | `avgCostPerVehicle` = 0 (guarded) | — | — | ⬜ |
| TC-DC-15 | Avg cost per vehicle: single vehicle | Only VH-001 (cost=4500) | 1. Load report | `avgCostPerVehicle` = 4500 | — | — | ⬜ |
| TC-DC-16 | Avg cost per vehicle: rounding to integer | 6975 / 4 = 1743.75 | 1. Load report | `round(1743.75, 0)` = 1744 | — | — | ⬜ |
| TC-DC-17 | KPI Total Cost = sum of all total_cost | DS-01, DS-02, DS-03, DS-05 | 1. Verify | 4500 + 1500 + 800 + 175 = 6975 | — | — | ⬜ |
| TC-DC-18 | KPI Total Fuel Cost = sum of all total_fuel_cost | DS-01, DS-02, DS-03, DS-05 | 1. Verify | 1000 + 1500 + 0 + 125 = 2625 | — | — | ⬜ |
| TC-DC-19 | KPI Total Maint Cost = sum of all total_maintenance_cost | DS-01, DS-02, DS-03, DS-05 | 1. Verify | 3500 + 0 + 800 + 50 = 4350 | — | — | ⬜ |
| TC-DC-20 | KPI High Risk = count where risk_level=HIGH | DS-01, DS-02, DS-03, DS-05 | 1. Verify | VH-002 = HIGH (no maint) = 1 | — | — | ⬜ |
| TC-DC-21 | KPI Low Risk = count where risk_level=LOW | DS-01, DS-02, DS-03, DS-05 | 1. Verify | VH-005 = LOW = 1 | — | — | ⬜ |
| TC-DC-22 | KPI Unknown Risk = count where risk_level=UNKNOWN | DS-01, DS-02, DS-03, DS-05 | 1. Verify | VH-003 = UNKNOWN (no insp) = 1 | — | — | ⬜ |

### 7.21 Chart.js Data Assembly Test Cases

| TC ID | Description | Prerequisites | Test Steps | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|--------------|------------|-----------------|---------|---------|--------|
| TC-CH-01 | Cost Distribution: doughnut type | DS-01 | 1. Inspect Chart constructor | Chart type set to `doughnut` | — | — | ⬜ |
| TC-CH-02 | Cost Distribution: cutout 70% | DS-01 | 1. Inspect options | `cutout: '70%'` | — | — | ⬜ |
| TC-CH-03 | Cost Distribution: data arrays correct | DS-01 | 1. Inspect dataset data | `data: [totalFuelCost, totalMaintenanceCost]` = `[2625, 4350]` | — | — | ⬜ |
| TC-CH-04 | Cost Distribution: legend at bottom with padding | DS-01 | 1. Inspect legend config | `legend.position = 'bottom'`, `padding: 20` | — | — | ⬜ |
| TC-CH-05 | Cost Distribution: tooltip shows percentage | DS-01 | 1. Hover over segment | Tooltip callback: `(value/total)*100` = "₹X (Y%)" | — | — | ⬜ |
| TC-CH-06 | Cost Distribution: both segments sum to 100% | DS-01 | 1. Hover both segments | Fuel% + Maint% = 100% | — | — | ⬜ |
| TC-CH-07 | Risk Analysis: bar type | DS-01 | 1. Inspect Chart constructor | Chart type set to `bar` | — | — | ⬜ |
| TC-CH-08 | Risk Analysis: data arrays correct | DS-01, DS-02, DS-03, DS-05 | 1. Inspect dataset data | `data: [riskCounts.HIGH, riskCounts.LOW, riskCounts.UNKNOWN]` = `[1, 1, 1]` | — | — | ⬜ |
| TC-CH-09 | Risk Analysis: y-axis beginAtZero | DS-01 | 1. Inspect y-axis | `beginAtZero: true` | — | — | ⬜ |
| TC-CH-10 | Risk Analysis: y-axis stepSize 1 | DS-01 | 1. Inspect ticks | `stepSize: 1` — integer step for vehicle counts | — | — | ⬜ |
| TC-CH-11 | Risk Analysis: no legend | DS-01 | 1. Inspect legend | `legend.display = false` | — | — | ⬜ |
| TC-CH-12 | Risk Analysis: tooltip format | DS-01 | 1. Hover bar | Tooltip: "High Risk: 1 vehicles" | — | — | ⬜ |
| TC-CH-13 | Risk Analysis: responsive, maintainAspectRatio false | DS-01 | 1. Inspect options | `responsive: true, maintainAspectRatio: false` | — | — | ⬜ |
| TC-CH-14 | Cost Distribution: border between segments | DS-01 | 1. Inspect dataset | `borderWidth: 2, borderColor: '#fff'` — white separator | — | — | ⬜ |
| TC-CH-15 | All chart data read from PHP `@json` | DS-01 | 1. Inspect script block | `const vehicleData = @json($vehicleData)` — blade JSON directive correctly serializes PHP to JS | — | — | ⬜ |

### 7.22 Cost Efficiency Boundary Test Cases

| TC ID | Description | Prerequisites | Test Steps | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|--------------|------------|-----------------|---------|---------|--------|
| TC-CE-01 | Cost = 0.00 → "No Cost" | Vehicle with exactly 0.00 cost | 1. Load report | Badge: secondary "No Cost" | — | — | ⬜ |
| TC-CE-02 | Cost = 0.01 → "Efficient" | Vehicle with 0.01 total cost | 1. Load report | Badge: success "Efficient" | — | — | ⬜ |
| TC-CE-03 | Cost = 100.00 → "Efficient" | Vehicle with exactly 100.00 cost | 1. Load report | Badge: success "Efficient" (≤100 inclusive) | — | — | ⬜ |
| TC-CE-04 | Cost = 100.01 → "Moderate" | Vehicle with 100.01 cost | 1. Load report | Badge: warning "Moderate" | — | — | ⬜ |
| TC-CE-05 | Cost = 200.00 → "Moderate" | Vehicle with exactly 200.00 cost | 1. Load report | Badge: warning "Moderate" (≤200 inclusive) | — | — | ⬜ |
| TC-CE-06 | Cost = 200.01 → "High Cost" | Vehicle with 200.01 cost | 1. Load report | Badge: danger "High Cost" | — | — | ⬜ |
| TC-CE-07 | Cost = 999999.99 → "High Cost" | Vehicle with very high cost | 1. Load report | Badge: danger "High Cost" | — | — | ⬜ |

### 7.23 Inspection Status Boundary Test Cases

| TC ID | Description | Prerequisites | Test Steps | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|--------------|------------|-----------------|---------|---------|--------|
| TC-IS-01 | Failure rate = 0.0% → "Good" | All inspections passed | 1. Load report | Badge: success "Good" | — | — | ⬜ |
| TC-IS-02 | Failure rate = 0.1% → "Fair" | 1 failed out of 1000 | 1. Load report | Badge: warning "Fair" | — | — | ⬜ |
| TC-IS-03 | Failure rate = 20.0% → "Fair" | Exactly 20% failure (2/10) | 1. Load report | Badge: warning "Fair" (≤20 inclusive) | — | — | ⬜ |
| TC-IS-04 | Failure rate = 20.1% → "Poor" | >20% failure | 1. Load report | Badge: danger "Poor" | — | — | ⬜ |
| TC-IS-05 | Failure rate = 100.0% → "Poor" | All inspections failed | 1. Load report | Badge: danger "Poor" | — | — | ⬜ |

### 7.24 TFOOT / Footer Edge Cases

| TC ID | Description | Prerequisites | Test Steps | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|--------------|------------|-----------------|---------|---------|--------|
| TC-TF-01 | TFOOT visible with multiple vehicles | DS-01, DS-02, DS-03, DS-05 | 1. Load table | TFOOT row present with TOTAL label | — | — | ⬜ |
| TC-TF-02 | TFOOT sum correct for single vehicle | Only 1 vehicle | 1. Load table | TFOOT shows that vehicle's total cost | — | — | ⬜ |
| TC-TF-03 | TFOOT shows 0 cost when no vehicles | ED-15 | 1. Load table | No TFOOT shown (empty table has colspan="6" row instead) | — | — | ⬜ |
| TC-TF-04 | TFOOT shows correct vehicle count | 4 vehicles | 1. Inspect TFOOT | "4 vehicles" text | — | — | ⬜ |
| TC-TF-05 | TFOOT uses `table-light` class | DS-01 | 1. Inspect tfoot | `<tfoot class="table-light">` | — | — | ⬜ |

### 7.25 Filter Interaction (vehicle_id via direct request)

| TC ID | Description | Prerequisites | Test Steps | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|--------------|------------|-----------------|---------|---------|--------|
| TC-FI-01 | vehicle_id filter via direct URL query (not exposed in UI but works in controller) | DS-01, DS-02 | 1. Send AJAX `?active_tab=cost-maintenance&vehicle_id=<VH-001-ID>&section=table` | Only VH-001 row shown in table | — | — | ⬜ |
| TC-FI-02 | vehicle_id filter with non-existent ID | DS-01 | 1. Send `?vehicle_id=99999` | Empty collection; "No vehicle cost and maintenance data found" | — | — | ⬜ |
| TC-FI-03 | vehicle_id filter with multiple vehicles | DS-01, DS-02 | 1. Send `?vehicle_id=<VH-001-ID>` | Only VH-001 data in both charts and table | — | — | ⬜ |
| TC-FI-04 | Date range filter applied: should not change data (known gap) | DS-01 + outside-month data | 1. Set date to previous month 2. Submit | Data unchanged — fuel/maintenance/inspection still shows all-time records (BC-BIZ-06) | — | — | ⬜ |
| TC-FI-05 | Filter form has hidden active_tab input | DS-01 | 1. Inspect form | `<input type="hidden" name="active_tab" value="cost-maintenance">` | — | — | ⬜ |
| TC-FI-06 | Filter form includes hidden from_date / to_date | DS-01 | 1. Inspect form | `<input type="hidden" name="from_date">` + `<input type="hidden" name="to_date">` | — | — | ⬜ |
| TC-FI-07 | Reset button clears filters and reloads | DS-01 | 1. Set date range 2. Click reset/refresh button | Page reloads without query params | — | — | ⬜ |

### 7.26 Blade View Rendering — Conditional Section Logic

| TC ID | Description | Prerequisites | Test Steps | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|--------------|------------|-----------------|---------|---------|--------|
| TC-BV-01 | `section=charts` renders KPI boxes + charts + inline script | DS-01 | 1. Inspect charts response | 8 small-box KPIs, 2 canvas elements, `<script>` with Chart.js init | — | — | ⬜ |
| TC-BV-02 | `section=table` renders table + pagination | DS-01 | 1. Inspect table response | `<table class="table table-sm">` with 6 columns, tfoot, pagination links | — | — | ⬜ |
| TC-BV-03 | `section=charts` does NOT include table HTML | DS-01 | 1. Inspect charts response HTML | No `<table>` element present | — | — | ⬜ |
| TC-BV-04 | `section=table` does NOT include chart canvases | DS-01 | 1. Inspect table response HTML | No `<canvas>` element present | — | — | ⬜ |
| TC-BV-05 | No section param: renders filter bar + skeleton loaders | DS-01 | 1. Load page without AJAX | Filter bar form visible, 2 spinner divs for charts and table | — | — | ⬜ |
| TC-BV-06 | Skeleton loader uses spinner-border | DS-01 | 1. Inspect initial container | `<div class="spinner-border text-primary"><span class="visually-hidden">Loading...</span></div>` | — | — | ⬜ |
| TC-BV-07 | Chart container IDs: `cost-maintenance-charts` and `cost-maintenance-table` | DS-01 | 1. Inspect container elements | `id="cost-maintenance-charts"` and `id="cost-maintenance-table"` | — | — | ⬜ |
| TC-BV-08 | Filter bar uses `x-backend.tab.filter-bar` component | DS-01 | 1. Inspect filter bar | `<x-backend.tab.filter-bar>` wrapping the form | — | — | ⬜ |

### 7.27 CODE-TRACE Coverage Map — Cost & Maintenance Report

| CODE-TRACE ID | Section | Key Lines | Test Coverage |
|--------------|---------|-----------|---------------|
| TR-01 | Hub Index Flow | 36, 38, 39, 42-53, 55-57, 60, 61, 65, 67 | TC-PM-01 through TC-PM-05, TC-AJ-01 through TC-AJ-08 |
| TR-02 | buildCostMaintenanceSection | 169, 170, 171, 172 | TC-P01, TC-P03, TC-P04, TC-BV-01 through TC-BV-08 |
| TR-03 | getCostMaintenanceReport | 837, 838, 839, 840, 841, 842, 843, 845, 846, 848-856 | TC-DI-01 through TC-DI-12, TC-DC-01 through TC-DC-22 |
| TR-04 | calculateRiskLevel | 957, 959, 961, 962, 964 | TC-N02, TC-N03, TC-N07 through TC-N12, TC-EC-01 through TC-EC-05 |
| TR-05 | KPI Calculation (View) | 10, 11, 12, 13, 14, 15, 16, 17 | TC-P09 through TC-P30 |
| TR-06 | Chart Data Assembly | 202-209, 218-250, 253-298 | TC-P31 through TC-P44, TC-CH-01 through TC-CH-15 |
| TR-07 | Table Row Computation | 322-368, 370-416, 428-439 | TC-P45 through TC-P71, TC-CE-01 through TC-CE-07, TC-IS-01 through TC-IS-05 |
| TR-08 | paginateCollection | 264, 265, 266-272 | TC-P65 through TC-P71 |
| TR-09 | parseDateRange | 329-332, 333-335 | TC-N17 |

### 7.28 N+1 Query Impact Test Cases

| TC ID | Description | Prerequisites | Test Steps | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|--------------|------------|-----------------|---------|---------|--------|
| TC-N1-01 | Query count with 5 vehicles | DS-01, DS-02, DS-03, DS-05 plus 1 extra | 1. Load report 2. Profile DB queries | Expected: 1 (vehicles) + 5*3 (fuel, maint, insp) = 16 queries | — | — | ⬜ |
| TC-N1-02 | Query count with 1 vehicle | 1 vehicle only | 1. Load report 2. Profile | 1 + 3 = 4 queries | — | — | ⬜ |
| TC-N1-03 | Query count with 50 vehicles | 50 active vehicles | 1. Load report 2. Profile | 1 + 150 = 151 queries — significant N+1 problem | — | — | ⬜ |
| TC-N1-04 | Eager loading suggestion: add `->with(['fuelLogs', 'maintenanceRecords', 'inspections'])` | Any dataset | 1. Add eager loads to controller line 838 2. Profile | Query count drops to 1 + 3 = 4 queries regardless of vehicle count | — | — | ⬜ |
| TC-N1-05 | Response time impact with N+1 | 100 vehicles (no eager load) | 1. Measure page load time | Response time degrades linearly with vehicle count due to N+1 | — | — | ⬜ |

### 7.29 Chart Empty State / Zero Data Test Cases

| TC ID | Description | Prerequisites | Test Steps | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|--------------|------------|-----------------|---------|---------|--------|
| TC-ED-01 | Cost Distribution Chart with zero fuel and zero maintenance | All vehicles have zero fuel and maint | 1. Load charts section | Doughnut chart renders with data=[0, 0] — both segments invisible but chart does not crash | — | — | ⬜ |
| TC-ED-02 | Cost Distribution Chart with only fuel cost > 0 | No maintenance records exist | 1. Load charts section | Doughnut shows 100% fuel, 0% maintenance; label shows "100%" for fuel | — | — | ⬜ |
| TC-ED-03 | Cost Distribution Chart with only maintenance cost > 0 | No fuel records exist | 1. Load charts section | Doughnut shows 0% fuel, 100% maintenance | — | — | ⬜ |
| TC-ED-04 | Risk Analysis Chart with all vehicles UNKNOWN | No inspections for any vehicle | 1. Load charts section | Bar chart shows 1 bar (Unknown) with count = total vehicles; High = 0, Low = 0 | — | — | ⬜ |
| TC-ED-05 | Risk Analysis Chart with all vehicles HIGH | All have >30% failure or 0 maint | 1. Load charts section | Bar chart shows 1 bar (High) with count = total; Low = 0, Unknown = 0 | — | — | ⬜ |
| TC-ED-06 | Risk Analysis Chart with all vehicles LOW | All have ≤15% failure and have maint | 1. Load charts section | Bar chart shows 1 bar (Low) with count = total; High = 0, Unknown = 0 | — | — | ⬜ |
| TC-ED-07 | Risk Analysis Chart with zero vehicles | ED-15 | 1. Load charts section | Bar chart renders with data=[0, 0, 0]; no visual bars, no crash | — | — | ⬜ |
| TC-ED-08 | Tooltip on zero-value segment | ED-07 | 1. Hover over zero-height bar | Tooltip shows "High Risk: 0 vehicles" correctly | — | — | ⬜ |

### 7.30 Blade `@can` / Permission Coverage Test Cases

| TC ID | Description | Prerequisites | Test Steps | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|--------------|------------|-----------------|---------|---------|--------|
| TC-CAN-01 | `@can('tenant.cost-maintenance.viewAny')` wraps `@include` in hub view | PC-01 | 1. Inspect transportreport.blade.php line 41 | View included only when permission active | — | — | ⬜ |
| TC-CAN-02 | `x-backend.tab.nav-tab` has `permission => 'tenant.cost-maintenance.viewAny'` | PC-01 | 1. Inspect tab config in hub view | Tab nav entry line 16 has correct permission key | — | — | ⬜ |
| TC-CAN-03 | Double security: tab hidden BOTH by nav-tab permission AND @can | Revoke permission | 1. Load as restricted user | Tab button hidden AND `@include` not executed (both guards prevent rendering) | — | — | ⬜ |
| TC-CAN-04 | Closing directive `@endcan` not `@endcanany` | None | 1. Inspect hub blade | `@can` correctly closed with `@endcan` (line 43) | — | — | ⬜ |

### 7.31 Hub View Tab Configuration Test Cases

| TC ID | Description | Prerequisites | Test Steps | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|--------------|------------|-----------------|---------|---------|--------|
| TC-HUB-01 | Tab id `cost-maintenance` matches blade pane id | DS-01 | 1. Compare tab id with pane id | Tab `id` = `cost-maintenance` matches `#cost-maintenance-pane` | — | — | ⬜ |
| TC-HUB-02 | Tab icon `fa-solid fa-bell` renders | DS-01 | 1. Inspect tab nav | `<i class="fa-solid fa-bell"></i>` before tab label | — | — | ⬜ |
| TC-HUB-03 | Tab label "Cost-Maintenance" is correct | DS-01 | 1. Inspect tab text | Tab button text exactly "Cost-Maintenance" | — | — | ⬜ |
| TC-HUB-04 | `activeTab` default is NOT cost-maintenance | DS-01 | 1. Load page without tab param | Active tab defaults to 'route-performance' | — | — | ⬜ |
| TC-HUB-05 | `active_tab=cost-maintenance` sets correct active tab | DS-01 | 1. Load `/transport-report?active_tab=cost-maintenance` | Cost-Maintenance tab is active on page load | — | — | ⬜ |

### 7.32 `paginateCollection()` Helper — Detailed Test Cases

| TC ID | Description | Prerequisites | Test Steps | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|--------------|------------|-----------------|---------|---------|--------|
| TC-PG-01 | Page 1 returns first 10 items | 25 vehicles | 1. Load table section page 1 | Items 1-10 returned | — | — | ⬜ |
| TC-PG-02 | Page 2 returns items 11-20 | 25 vehicles | 1. Load `?page_cost=2` | Items 11-20 returned | — | — | ⬜ |
| TC-PG-03 | Page 3 returns remaining 5 items | 25 vehicles | 1. Load `?page_cost=3` | Items 21-25 returned | — | — | ⬜ |
| TC-PG-04 | Page beyond total returns empty slice | 25 vehicles | 1. Load `?page_cost=4` | Empty slice; paginator still shows last page as 3 | — | — | ⬜ |
| TC-PG-05 | `page_cost=-1` resolves to page 1 | 25 vehicles | 1. Load `?page_cost=-1` | Slice starts at 0; shows first 10 items | — | — | ⬜ |
| TC-PG-06 | `page_cost=abc` resolves to page 1 | 25 vehicles | 1. Load `?page_cost=abc` | `resolveCurrentPage` returns null; defaults to page 1 | — | — | ⬜ |
| TC-PG-07 | `page_cost=0` resolves to page 1 | 25 vehicles | 1. Load `?page_cost=0` | Slice starts at (0-1)*10 = -10 → slice(-10) wraps to 0; shows first 10 | — | — | ⬜ |
| TC-PG-08 | Path resolved correctly for pagination links | 25 vehicles | 1. Inspect pagination URLs | `Paginator::resolveCurrentPath()` returns current URL path | — | — | ⬜ |
| TC-PG-09 | Only `page_cost` param used (no conflict with `page` param) | 25 vehicles | 1. Load `?page=2&page_cost=1` (page param for other tab) | cost-maintenance shows page 1 data | — | — | ⬜ |

### 7.33 `parseDateRange()` Helper — Detailed Test Cases

| TC ID | Description | Prerequisites | Test Steps | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|--------------|------------|-----------------|---------|---------|--------|
| TC-PD-01 | Valid date range `dates=2026-01-01 - 2026-01-31` | None | 1. Submit with dates param | `from_date = 2026-01-01`, `to_date = 2026-01-31` | — | — | ⬜ |
| TC-PD-02 | No dates param → defaults to current month | None | 1. Load without dates | `startDate = YYYY-MM-01` (month start), `endDate = YYYY-MM-28/29/30/31` (month end) | — | — | ⬜ |
| TC-PD-03 | Invalid dates format → falls to default | None | 1. Submit with `dates=invalid` | `split(' - ')` fails; falls to current month default | — | — | ⬜ |
| TC-PD-04 | Single date (no separator) → falls to default | None | 1. Submit with `dates=2026-01-01` (no ` - `) | Split produces 1 element; falls to default | — | — | ⬜ |
| TC-PD-05 | Date range with time component | None | 1. Submit with `dates=2026-01-01 00:00 - 2026-01-31 23:59` | Trim applied; dates parsed from '2026-01-01' and '2026-01-31' | — | — | ⬜ |

### 7.34 JavaScript Chart.js Initialization Details

| TC ID | Description | Prerequisites | Test Steps | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|--------------|------------|-----------------|---------|---------|--------|
| TC-JC-01 | Chart constructor called with `document.getElementById('costDistributionChart')` | DS-01 | 1. Inspect script | `new Chart(document.getElementById('costDistributionChart'), {...})` | — | — | ⬜ |
| TC-JC-02 | Chart constructor called with `document.getElementById('riskAnalysisChart')` | DS-01 | 1. Inspect script | `new Chart(document.getElementById('riskAnalysisChart'), {...})` | — | — | ⬜ |
| TC-JC-03 | Chart data uses `@json()` Blade directive for PHP-to-JS | DS-01 | 1. Inspect rendered script | `const totalFuelCost = @json($totalFuelCost)` produces `const totalFuelCost = 2625` | — | — | ⬜ |
| TC-JC-04 | Chart data refreshed when charts section re-renders | DS-01 | 1. Apply filter 2. Check chart data | New Chart instances created with updated data after AJAX reload | — | — | ⬜ |
| TC-JC-05 | Old Chart instances destroyed before re-creation | DS-01 | 1. Apply filter 2. Check for duplicate canvases | No duplicate canvas IDs; Chart.js uses existing `getElementById` | — | — | ⬜ |
| TC-JC-06 | Chart canvas has consistent height (300px) | DS-01 | 1. Inspect canvas container | `<div style="height:300px;">` wraps each canvas | — | — | ⬜ |
| TC-JC-07 | Chart canvas ID uniqueness | DS-01 | 1. Inspect both canvases | Unique IDs: `costDistributionChart` and `riskAnalysisChart` | — | — | ⬜ |

### 7.35 Controller `loadTabSection()` Match Routing

| TC ID | Description | Prerequisites | Test Steps | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|--------------|------------|-----------------|---------|---------|--------|
| TC-LT-01 | `active_tab=cost-maintenance` dispatches to `buildCostMaintenanceSection()` | DS-01 | 1. Trace match block line 84 | `'cost-maintenance' => $this->buildCostMaintenanceSection(...)` | — | — | ⬜ |
| TC-LT-02 | `buildCostMaintenanceSection()` receives `$section`, `$reqFilters`, `$startDate`, `$endDate`, `$filterData` | DS-01 | 1. Check method signature line 167 | 5 parameters: string $section, array $reqFilters, string $startDate, string $endDate, array $filters | — | — | ⬜ |
| TC-LT-03 | `getCostMaintenanceReport()` receives `$reqFilters` and date range | DS-01 | 1. Check call line 170 | `$this->getCostMaintenanceReport($reqFilters, $startDate, $endDate)` | — | — | ⬜ |
| TC-LT-04 | `cost-maintenance` tab not in `$request->ajax()` early return | DS-01 | 1. Load page non-AJAX | Hub view returned; `loadTabSection` NOT called on server side | — | — | ⬜ |
| TC-LT-05 | AJAX returns JSON with `html` key | DS-01 | 1. Send AJAX for charts | `response()->json(['html' => $html])` line 92 | — | — | ⬜ |

### 7.36 Blade Variable Scope & Null Safety

| TC ID | Description | Prerequisites | Test Steps | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|--------------|------------|-----------------|---------|---------|--------|
| TC-VS-01 | `$costMaintenanceReport` null coalesced in charts section | DS-01 | 1. View line 9 | `$costMaintenanceReport = $costMaintenanceReport ?? collect()` prevents null | — | — | ⬜ |
| TC-VS-02 | `$costMaintenanceReport` null coalesced in table section | DS-01 | 1. View line 317 | Same null coalesce pattern in table section | — | — | ⬜ |
| TC-VS-03 | `$costMaintenanceReportPaginated` available in table section | DS-01 | 1. View line 320 | `$costMaintenanceReportPaginated` iterated in `@forelse` | — | — | ⬜ |
| TC-VS-04 | `$filters` variable available in view | DS-01 | 1. View compact line 172 | `compact('filters', 'costMaintenanceReport', 'costMaintenanceReportPaginated')` | — | — | ⬜ |
| TC-VS-05 | Vehicle array keys accessed with `??` default | DS-01 | 1. View lines 322-328 | All keys accessed via `$vehicle['key'] ?? 0` or `?? ''` | — | — | ⬜ |
| TC-VS-06 | `loop.index` alternative: `$index + 1` used for row number | DS-01 | 1. View line 371 | Row number computed as `$index + 1` (0-based index → 1-based display) | — | — | ⬜ |

### 7.37 Blade `@php` / Computation Blocks

| TC ID | Description | Prerequisites | Test Steps | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|--------------|------------|-----------------|---------|---------|--------|
| TC-BP-01 | Charts section computes all 8 KPI values in `@php` block | DS-01 | 1. View lines 8-18 | 8 computed variables: totalVehicles, totalCost, totalFuelCost, totalMaintenanceCost, avgCostPerVehicle, highRiskVehicles, lowRiskVehicles, unknownRiskVehicles | — | — | ⬜ |
| TC-BP-02 | Table section computes per-row variables in `@php` block | DS-01 | 1. View lines 321-368 | Per-row computations: vehicleNo, regNo, costs, riskClass, inspectionStatus, costEfficiency | — | — | ⬜ |
| TC-BP-03 | SVG icon paths in KPI boxes are static | DS-01 | 1. Inspect any KPI icon | Hardcoded SVG `<path>` elements — no dynamic computation | — | — | ⬜ |
| TC-BP-04 | `number_format()` applied to cost display | DS-01 | 1. View lines 42, 60, 99, 117 | `number_format($totalCost, 0)` — comma-separated thousands | — | — | ⬜ |

### 7.38 Table HTML Structure Compliance

| TC ID | Description | Prerequisites | Test Steps | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|--------------|------------|-----------------|---------|---------|--------|
| TC-TH-01 | Table has `<thead>`, `<tbody>`, `<tfoot>` | DS-01 | 1. Inspect table structure | All 3 table sections present | — | — | ⬜ |
| TC-TH-02 | `<thead>` has 6 `<th>` elements | DS-01 | 1. Count th elements | 6 headers: #, Vehicle Details, Cost (₹), Inspection, Risk Level, Status | — | — | ⬜ |
| TC-TH-03 | `<tbody>` iterates via `@forelse` | DS-01 | 1. Inspect tbody | `@forelse($costMaintenanceReportPaginated as $index => $vehicle)` | — | — | ⬜ |
| TC-TH-04 | `@empty` directive for empty state | ED-15 | 1. Load with no data | `<td colspan="6">` with icon and "No vehicle cost and maintenance data found" | — | — | ⬜ |
| TC-TH-05 | `<tfoot>` has colspan matching header | DS-01 | 1. Inspect tfoot | `colspan="2"` on label, `colspan` on vehicle count cell = 1 | — | — | ⬜ |
| TC-TH-06 | Table uses `table-sm` class | DS-01 | 1. Inspect table | `<table class="table table-sm">` | — | — | ⬜ |
| TC-TH-07 | Pagination uses `d-flex justify-content-center mt-3` | DS-01 | 1. Inspect pagination container | Pagination centered below table | — | — | ⬜ |

### 7.39 `request()->merge(['section' => $section])` Impact

| TC ID | Description | Prerequisites | Test Steps | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|--------------|------------|-----------------|---------|---------|--------|
| TC-RM-01 | `request('section')` equals 'charts' after builder merge | DS-01 | 1. View condition when section=charts passed | `@if(request('section') === 'charts')` evaluates to true | — | — | ⬜ |
| TC-RM-02 | `request('section')` equals 'table' after builder merge | DS-01 | 1. View condition when section=table passed | `@elseif(request('section') === 'table')` evaluates to true | — | — | ⬜ |
| TC-RM-03 | `request('section')` is null when no section param | DS-01 | 1. Load page without section | `@else` block renders (no section = filter bar + skeleton) | — | — | ⬜ |
| TC-RM-04 | `request()->merge()` affects only current request | DS-01 | 1. Check that merge doesn't persist across requests | Merge only affects the rendered view string; subsequent requests have clean state | — | — | ⬜ |

### 7.40 Cost Data Rounding Precision

| TC ID | Description | Prerequisites | Test Steps | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|--------------|------------|-----------------|---------|---------|--------|
| TC-RP-01 | `total_fuel_cost` rounded to 2 decimal places | Fuel cost = 100.456 | 1. Create fuel record with cost = 100.456 2. Load report | `round(100.456, 2)` = 100.46 | — | — | ⬜ |
| TC-RP-02 | `total_maintenance_cost` rounded to 2 decimal places | Maint cost = 200.789 | 1. Create maint record with cost = 200.789 2. Load report | `round(200.789, 2)` = 200.79 | — | — | ⬜ |
| TC-RP-03 | `total_cost` rounded to 2 decimal places | fuel=100.456, maint=200.789 | 1. Load report | `round(301.245, 2)` = 301.25 | — | — | ⬜ |
| TC-RP-04 | `inspection_failure_rate` rounded to 1 decimal place | 2 failed out of 3 = 66.666...% | 1. Load report | `round(66.666, 1)` = 66.7 | — | — | ⬜ |
| TC-RP-05 | `avgCostPerVehicle` rounded to 0 decimal places | 6975 / 4 = 1743.75 | 1. Load report | `round(1743.75, 0)` = 1744 | — | — | ⬜ |

### 7.41 AJAX Loading State — Visual Feedback

| TC ID | Description | Prerequisites | Test Steps | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|--------------|------------|-----------------|---------|---------|--------|
| TC-AV-01 | Container opacity set to 0.5 during AJAX | DS-01 | 1. Monitor container style during XHR | `container.css('opacity', 0.5)` applied | — | — | ⬜ |
| TC-AV-02 | Container opacity restored to 1 after success | DS-01 | 1. Wait for AJAX completion | `container.css('opacity', 1)` in success callback | — | — | ⬜ |
| TC-AV-03 | Container opacity restored to 1 on error | Simulate 500 | 1. Trigger AJAX error 2. Check opacity | `container.css('opacity', 1)` in error callback | — | — | ⬜ |
| TC-AV-04 | Error HTML injected on AJAX failure | Simulate 500 | 1. Check container HTML after error | `<div class="alert alert-danger">Failed to load ...</div>` | — | — | ⬜ |

### 7.42 Date Picker Configuration

| TC ID | Description | Prerequisites | Test Steps | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|--------------|------------|-----------------|---------|---------|--------|
| TC-DP-01 | daterangepicker initialized with `autoApply: true` | DS-01 | 1. Open date range picker | Picker auto-applies on selection; no "Apply" button | — | — | ⬜ |
| TC-DP-02 | daterangepicker starts with current month | DS-01 | 1. Open picker | Start date = month start, end date = month end | — | — | ⬜ |
| TC-DP-03 | Presets available: Today, Last 7 Days, This Month, Last Month | DS-01 | 1. Open picker 2. Check ranges | 4 presets listed in dropdown | — | — | ⬜ |
| TC-DP-04 | Date range change triggers filter form submit | DS-01 | 1. Select new date range | `$('.transport-filter-form').first().submit()` called | — | — | ⬜ |
| TC-DP-05 | Date format YYYY-MM-DD used | DS-01 | 1. Select date 2. Check hidden inputs | `from_date` format: `2026-01-01` | — | — | ⬜ |
| TC-DP-06 | Picker opens to left | DS-01 | 1. Inspect daterangepicker config | `opens: 'left'` | — | — | ⬜ |

### 7.43 AJAX Query String Construction Test Cases

| TC ID | Description | Prerequisites | Test Steps | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|--------------|------------|-----------------|---------|---------|--------|
| TC-QS-01 | `active_tab` and `section` appended to query data | DS-01 | 1. Trace `loadTabSection` function | QueryData always includes `active_tab` and `section` keys | — | — | ⬜ |
| TC-QS-02 | Filter params extracted from form data | DS-01 | 1. Submit filter form 2. Monitor query params | `from_date`, `to_date` included in AJAX query | — | — | ⬜ |
| TC-QS-03 | `active_tab` excluded from form data passthrough | DS-01 | 1. Trace form data parsing | `if (key !== 'active_tab' && key !== 'section')` filters out these keys | — | — | ⬜ |
| TC-QS-04 | Pagination URL query string parsed correctly | DS-01 | 1. Click page 2 2. Check query params | `page_cost=2` extracted from pagination URL and passed to `loadTabSection` | — | — | ⬜ |
| TC-QS-05 | URL encoding/decoding handled | DS-01 | 1. Submit filter with special chars | `decodeURIComponent()` applied to both keys and values | — | — | ⬜ |

### 7.44 Vehicle `maintenanceRecords` Relationship Chain

| TC ID | Description | Prerequisites | Test Steps | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|--------------|------------|-----------------|---------|---------|--------|
| TC-MR-01 | [Query/Code Removed] | Vehicle with 2 maint records | 1. Inspect relationship in Vehicle model line 79-85 | [Query/Code Removed] | — | — | ⬜ |
| TC-MR-02 | Maintenance record linked via valid service request + inspection | VH-001: 2 records | 1. Create maintenance with valid service_request_id 2. Verify cost summed | Maintenance cost includes only records where chain resolves to correct vehicle | — | — | ⬜ |
| TC-MR-03 | Maintenance record with orphaned service_request_id excluded | VH-001: orphaned record | 1. Create maintenance with non-existent service_request_id | `whereHas` returns false; orphaned record excluded from sum | — | — | ⬜ |
| TC-MR-04 | Maintenance record linked to different vehicle excluded | VH-001: maint for VH-002 | 1. Create maintenance linked to different vehicle's inspection | `whereHas` filters by current vehicle id; excluded | — | — | ⬜ |

### 7.45 Vehicle `fuelLogs` Relationship

| TC ID | Description | Prerequisites | Test Steps | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|--------------|------------|-----------------|---------|---------|--------|
| TC-FL-01 | `fuelLogs()` uses `hasMany(TptVehicleFuel, 'vehicle_id')` | Vehicle with 3 fuel records | 1. Inspect model line 92-94 | Direct `hasMany` on `vehicle_id` — no chain needed | — | — | ⬜ |
| TC-FL-02 | Fuel records with any status included in sum | VH-001: 2 Approved, 1 Pending | 1. Load report | All 3 records summed (no `Approved` scope applied in controller) | — | — | ⬜ |
| TC-FL-03 | Fuel records linked to different vehicle excluded | VH-001: fuel for VH-002 | 1. Load report | Only VH-001's fuel records summed | — | — | ⬜ |

### 7.46 Vehicle `inspections` Relationship

| TC ID | Description | Prerequisites | Test Steps | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|--------------|------------|-----------------|---------|---------|--------|
| TC-IN-01 | `inspections()` uses `hasMany(TptDailyVehicleInspection, 'vehicle_id')` | Vehicle with 10 inspections | 1. Inspect model line 60-63 | Direct `hasMany` on `vehicle_id` | — | — | ⬜ |
| TC-IN-02 | Both Passed and Failed inspections counted for total | VH-001: 8 Passed, 2 Failed | 1. Load report | `totalInspections` = 10 (all records) | — | — | ⬜ |
| TC-IN-03 | Only `inspection_status = 'Failed'` counted for failures | VH-001: 2 Failed | 1. Load report | [Query/Code Removed] | — | — | ⬜ |
| TC-IN-04 | Pending inspections excluded from Failed count but counted in total | 1 Pending, 4 Passed, 1 Failed | 1. Load report | `totalInspections` = 6, `failedInspections` = 1 (Pending not Failed) | — | — | ⬜ |

### 7.47 MEDIUM Risk Level — Detailed Boundary

| TC ID | Description | Prerequisites | Test Steps | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|--------------|------------|-----------------|---------|---------|--------|
| TC-MD-01 | Failure rate = 15.0% → LOW (NOT > 15) | 15 failures out of 100 | 1. Load report | Risk = LOW (falls through `>15` check) | — | — | ⬜ |
| TC-MD-02 | Failure rate = 15.1% → MEDIUM | 151 failures out of 1000 | 1. Load report | Risk = MEDIUM (15.1 > 15) | — | — | ⬜ |
| TC-MD-03 | Failure rate = 30.0% → MEDIUM (NOT > 30) | 30 failures out of 100 | 1. Load report | Risk = MEDIUM (30 > 15, but 30 is NOT > 30) | — | — | ⬜ |
| TC-MD-04 | Failure rate = 30.1% + has maint → HIGH | 301 failures out of 1000 | 1. Load report | Risk = HIGH (30.1 > 30) | — | — | ⬜ |
| TC-MD-05 | Failure rate = 30.1% + no maint → HIGH (both conditions true) | 301 failures, 0 maint | 1. Load report | Risk = HIGH (both `>30` AND `maintenanceCount === 0`) | — | — | ⬜ |
| TC-MD-06 | Failure rate = 0% + has maint → LOW | 0 failures, has maint | 1. Load report | Risk = LOW (falls through all checks) | — | — | ⬜ |

### 7.48 Total Cost = 0 Edge Cases

| TC ID | Description | Prerequisites | Test Steps | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|--------------|------------|-----------------|---------|---------|--------|
| TC-ZC-01 | Vehicle with zero fuel, zero maint, zero inspections | No records at all | 1. Load report | total_cost=0, risk=UNKNOWN, Status="No Cost", inspection="-" | — | — | ⬜ |
| TC-ZC-02 | Vehicle with zero fuel, zero maint, has inspections | Inspections exist but no costs | 1. Load report | total_cost=0, risk from inspections only, Status="No Cost" | — | — | ⬜ |
| TC-ZC-03 | Avg cost = 0 when all vehicles have 0 cost | All vehicles zero cost | 1. Load report | Avg Cost KPI shows ₹0 | — | — | ⬜ |
| TC-ZC-04 | Fuel cost = 0, maint cost = 0 → total = 0 | DS-03 variant | 1. Load report | total_cost = 0.00 | — | — | ⬜ |

### 7.49 Data Consistency — Cross-Tab Filtering

| TC ID | Description | Prerequisites | Test Steps | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|--------------|------------|-----------------|---------|---------|--------|
| TC-XT-01 | Changing date filter resets cost-maintenance data (even though gap exists) | DS-01 | 1. Change date 2. Reload cost-maintenance | AJAX refetches both sections with new date params (but data unchanged due to gap) | — | — | ⬜ |
| TC-XT-02 | Other tab filters do not affect cost-maintenance data | DS-01 | 1. Apply route filter in Stop Analysis tab 2. Switch to cost-maintenance | Cost-maintenance loads without route filter applied | — | — | ⬜ |
| TC-XT-03 | Cost-maintenance uses separate `page_cost` pagination param | DS-01, other tab with page params | 1. Load cost-maintenance page 2 2. Check URL | URL contains `page_cost=2`, no other tab's page param | — | — | ⬜ |

### 7.50 Full Page Load (Non-AJAX) Flow

| TC ID | Description | Prerequisites | Test Steps | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|--------------|------------|-----------------|---------|---------|--------|
| TC-FP-01 | Non-AJAX page load renders hub view with filter data | DS-01 | 1. Load `/transport-report?active_tab=cost-maintenance` without AJAX | Full hub view rendered; `$filters` populated from `getFilterData()` | — | — | ⬜ |
| TC-FP-02 | `$filters` contains vehicles, routes, stops, drivers, shifts | DS-01 | 1. Inspect `$filters` variable | `getFilterData()` returns all dropdown lists | — | — | ⬜ |
| TC-FP-03 | `$activeTab` set to 'cost-maintenance' | DS-01 | 1. Inspect `$activeTab` variable | `$activeTab = 'cost-maintenance'` | — | — | ⬜ |
| TC-FP-04 | Chart.js CDN loaded in hub view | DS-01 | 1. Inspect hub script | `<script src="https://cdn.jsdelivr.net/npm/chart.js"></script>` included | — | — | ⬜ |
| TC-FP-05 | daterangepicker + moment CDN loaded | DS-01 | 1. Inspect hub scripts | Both CDN scripts loaded after Chart.js | — | — | ⬜ |

### 7.51 Daterangepicker JS Initialization Test Cases

| TC ID | Description | Prerequisites | Test Steps | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|--------------|------------|-----------------|---------|---------|--------|
| TC-DR-01 | `$('.transport_daterange').daterangepicker({...})` initialized on DOM ready | DS-01 | 1. Load page 2. Check daterangepicker init | Picker attached to input with class `transport_daterange` | — | — | ⬜ |
| TC-DR-02 | `startDate` and `endDate` set from request params when available | DS-01 with `from_date=2026-01-01&to_date=2026-01-31` | 1. Load with query params | Start = Jan 1, End = Jan 31 | — | — | ⬜ |
| TC-DR-03 | `startDate` defaults to month start when no params | DS-01 without from/to | 1. Load page | Start = `moment().startOf('month')` | — | — | ⬜ |
| TC-DR-04 | `endDate` defaults to month end when no params | DS-01 without from/to | 1. Load page | End = `moment().endOf('month')` | — | — | ⬜ |
| TC-DR-05 | `from_date` and `to_date` hidden inputs updated on date change | DS-01 | 1. Select new date range | `$('.transport_from_date').val(start.format(...))` and `$('.transport_to_date').val(end.format(...))` called | — | — | ⬜ |
| TC-DR-06 | Form auto-submitted on date range selection | DS-01 | 1. Select new date 2. Check form submit | `$('.transport-filter-form').first().submit()` called after hidden inputs updated | — | — | ⬜ |

### 7.52 Development / Debugging Notes

| Note ID | Category | Details |
|---------|----------|---------|
| DEV-01 | Known Bug | Date range filter is a no-op. All fuel, maintenance, and inspection data loads ALL records regardless of `$startDate`/`$endDate`. The `getCostMaintenanceReport()` method accepts date params but never uses them in relationship queries (lines 841-846). |
| DEV-02 | Known Bug | N+1 query problem. Vehicle query at line 838-839 uses `Vehicle::active()->get()` without eager-loading `fuelLogs`, `maintenanceRecords`, or `inspections`. Each vehicle triggers 3 additional lazy-loaded queries = 1 + 3N total queries. Fix: add `->with(['fuelLogs', 'maintenanceRecords', 'inspections'])`. |
| DEV-03 | Design Limitation | `vehicle_id` filter exists in `$reqFilters` (line 46) and controller logic (line 837) but is NOT exposed in the blade filter bar. Users cannot filter by vehicle via UI. |
| DEV-04 | Design Note | Risk calculation uses `$maintenanceCount === 0` as a HIGH risk trigger. A vehicle with perfect inspections but zero maintenance records is flagged HIGH risk. This may be intended (no maintenance = neglect) but could also be a false positive for new vehicles. |
| DEV-05 | Design Note | Fuel records are NOT filtered by `status = 'Approved'` in the controller. All fuel records regardless of status (Pending, Approved, Rejected) contribute to `total_fuel_cost`. |
| DEV-06 | Design Note | The `maintenanceRecords()` relationship goes through a 3-level chain: `Vehicle → TptVehicleMaintenance (via vehicle_service_request_id) → TptVehicleServiceRequest (via id) → TptDailyVehicleInspection (via vehicle_inspection_id) → vehicle_id`. This is more complex than direct `hasMany` and may have performance implications. |
| DEV-07 | Missing Feature | Export (PDF/CSV) is not implemented for this report. |
| DEV-08 | Missing Feature | No "View All" link from KPIs to detailed table (small-box footer links point to `transport.trip-management.index` — a different section). |
| DEV-09 | CSS Note | KPI "Unknown Risk" box uses `text-bg-ligth` (typo: should be `text-bg-light`). This may cause the KPI to render without proper background color. |

### 7.53 Total Test Case Summary

| Section | Test Case Count |
|---------|----------------|
| 7.1 — Tab Loading & Rendering | 8 (TC-P01 to TC-P08) |
| 7.2 — KPI Row 1 | 13 (TC-P09 to TC-P21) |
| 7.3 — KPI Row 2 | 9 (TC-P22 to TC-P30) |
| 7.4 — Charts | 14 (TC-P31 to TC-P44) |
| 7.5 — Table Data | 17 (TC-P45 to TC-P61) |
| 7.6 — Footer & Pagination | 10 (TC-P62 to TC-P71) |
| 7.7 — AJAX & SPA | 13 (TC-P72 to TC-P84) |
| 7.8 — Negative | 23 (TC-N01 to TC-N23) |
| 7.9 — Edge Cases | 18 (TC-EC-01 to TC-EC-18) |
| 7.10 — Permission & Access | 5 (TC-PM-01 to TC-PM-05) |
| 7.11 — Data Integrity | 12 (TC-DI-01 to TC-DI-12) |
| 7.12 — Code Review | 20 (TC-CR01 to TC-CR20) |
| 7.13 — UI/UX | 20 (TC-UI-01 to TC-UI-20) |
| 7.14 — JS Console | 10 (TC-JS-01 to TC-JS-10) |
| 7.15 — Performance | 6 (TC-PF-01 to TC-PF-06) |
| 7.16 — Regression | 7 (TC-RG-01 to TC-RG-07) |
| 7.17 — Cross-Browser | 10 (TC-CB-01 to TC-CB-10) |
| 7.18 — Localization | 6 (TC-L10N-01 to TC-L10N-06) |
| 7.19 — Accessibility | 10 (TC-A11Y-01 to TC-A11Y-10) |
| 7.20 — Data Aggregation | 22 (TC-DC-01 to TC-DC-22) |
| 7.21 — Chart.js Assembly | 15 (TC-CH-01 to TC-CH-15) |
| 7.22 — Cost Efficiency Boundaries | 7 (TC-CE-01 to TC-CE-07) |
| 7.23 — Inspection Boundaries | 5 (TC-IS-01 to TC-IS-05) |
| 7.24 — TFOOT Edges | 5 (TC-TF-01 to TC-TF-05) |
| 7.25 — Filter Interaction | 7 (TC-FI-01 to TC-FI-07) |
| 7.26 — Blade View Rendering | 8 (TC-BV-01 to TC-BV-08) |
| 7.27 — CODE-TRACE Coverage | 9 (coverage map) |
| 7.28 — N+1 Query Impact | 5 (TC-N1-01 to TC-N1-05) |
| 7.29 — Chart Empty / Zero Data | 8 (TC-ED-01 to TC-ED-08) |
| 7.30 — @can Permission | 4 (TC-CAN-01 to TC-CAN-04) |
| 7.31 — Hub Tab Config | 5 (TC-HUB-01 to TC-HUB-05) |
| 7.32 — paginateCollection | 9 (TC-PG-01 to TC-PG-09) |
| 7.33 — parseDateRange | 5 (TC-PD-01 to TC-PD-05) |
| 7.34 — Chart.js Init | 7 (TC-JC-01 to TC-JC-07) |
| 7.35 — loadTabSection Routing | 5 (TC-LT-01 to TC-LT-05) |
| 7.36 — Blade Variable Scope | 6 (TC-VS-01 to TC-VS-06) |
| 7.37 — @php / Computations | 4 (TC-BP-01 to TC-BP-04) |
| 7.38 — Table HTML Structure | 7 (TC-TH-01 to TC-TH-07) |
| 7.39 — request()->merge | 4 (TC-RM-01 to TC-RM-04) |
| 7.40 — Rounding Precision | 5 (TC-RP-01 to TC-RP-05) |
| 7.41 — AJAX Visual Feedback | 4 (TC-AV-01 to TC-AV-04) |
| 7.42 — Date Picker Config | 6 (TC-DP-01 to TC-DP-06) |
| 7.43 — AJAX Query String | 5 (TC-QS-01 to TC-QS-05) |
| 7.44 — maintenanceRecords Chain | 4 (TC-MR-01 to TC-MR-04) |
| 7.45 — fuelLogs Relationship | 3 (TC-FL-01 to TC-FL-03) |
| 7.46 — inspections Relationship | 4 (TC-IN-01 to TC-IN-04) |
| 7.47 — MEDIUM Risk Boundary | 6 (TC-MD-01 to TC-MD-06) |
| 7.48 — Zero Cost Edge Cases | 4 (TC-ZC-01 to TC-ZC-04) |
| 7.49 — Cross-Tab Filtering | 3 (TC-XT-01 to TC-XT-03) |
| 7.50 — Full Page Load | 5 (TC-FP-01 to TC-FP-05) |
| 7.51 — Daterangepicker Init | 6 (TC-DR-01 to TC-DR-06) |

**Total Test Cases: 397+**

---

## 8. Test Steps

### 8.1 Manual Test Execution Steps

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| TS-01 | Login as user with `tenant.cost-maintenance.viewAny` and `tenant.transport.viewAny` permissions | Authenticated successfully |
| TS-02 | Navigate to `/transport-report?active_tab=cost-maintenance` | Page loads; Cost-Maintenance tab is active; skeleton loaders visible |
| TS-03 | Wait for AJAX charts section to load | 8 KPI boxes render in 2 rows; 2 chart canvases visible |
| TS-04 | Wait for AJAX table section to load | 6-column table renders with data rows |
| TS-05 | Verify KPI Row 1: Total Vehicles = expected count, Total Cost = sum, Avg Cost = avg, High Risk = count | Values match computed expectations from DS-01+DS-02+DS-03+DS-05 |
| TS-06 | Verify KPI Row 2: Fuel Cost, Maintenance Cost, Low Risk, Unknown Risk | Values match computed expectations |
| TS-07 | Hover over Cost Distribution Chart segments | Tooltip shows ₹ amount and percentage |
| TS-08 | Hover over Risk Analysis Chart bars | Tooltip shows risk level and vehicle count |
| TS-09 | Scroll through table rows | Cost breakdown, inspection badge, risk badge, status badge rendered correctly |
| TS-10 | Check table TFOOT footer | TOTAL row with sum of costs and vehicle count |
| TS-11 | Change date range and submit filter | Both charts and table reload via AJAX (data unchanged due to known date gap) |
| TS-12 | (If 12+ vehicles) Click pagination | Next 10 records load; URL contains `page_cost=2` |
| TS-13 | Check browser console for errors | Zero JS errors |
| TS-14 | Resize browser to mobile width | Layout responsive; KPI boxes stack; table scrollable |

### 8.2 Automated Test Suggestions

| Test Type | Tool/Framework | Test Scenario |
|-----------|---------------|---------------|
| Unit | PHPUnit | `calculateRiskLevel(0, 0, 0)` returns 'UNKNOWN' |
| Unit | PHPUnit | `calculateRiskLevel(5, 10, 1)` — 50% failure with maint → 'HIGH' |
| Unit | PHPUnit | `calculateRiskLevel(2, 10, 1)` — 20% failure with maint → 'MEDIUM' |
| Unit | PHPUnit | `calculateRiskLevel(1, 10, 1)` — 10% failure with maint → 'LOW' |
| Unit | PHPUnit | `calculateRiskLevel(3, 10, 0)` — 30% failure with NO maint → 'HIGH' (both conditions trigger) |
| Unit | PHPUnit | `getCostMaintenanceReport()` returns correct structure: array with 7 keys |
| Feature | Laravel Dusk / Pest | Tab loads with correct KPIs for known dataset |
| Feature | Laravel Dusk / Pest | AJAX section loading returns HTML (not JSON data) |
| Feature | Laravel Dusk / Pest | Chart.js canvases rendered in DOM after charts section loaded |
| Integration | PHPUnit | Date range params passed but NOT applied to subsidiary queries |
| Static Analysis | PHPStan | Type safety of `$costMaintenanceReport` as Collection of arrays |
| Mutation | Infection | Risk level boundary conditions (15%, 30% exact values) |

---

## 9. Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-07-22 | AI Assistant | Initial creation from controller analysis (buildCostMaintenanceSection, getCostMaintenanceReport, calculateRiskLevel) and view analysis (index.blade.php) |
| 1.1 | 2026-07-22 | AI Assistant | Deepened from 143 to 1400+ lines with full CODE-TRACE structure, 53 test case sections, 397+ test cases, model relationship docs, boundary value tables, and complete test step documentation |

