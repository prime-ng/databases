# tpt_TransportFinanceReport_TcList

## Module: Transport → Transport Report → Transport Finance & Leakage

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | Transport |
| Tab Group | Transport Report |
| Feature | Transport Finance & Leakage Report |
| URL(s) | `/transport-report?active_tab=transport-finance` (page load), AJAX: `GET /transport-report?active_tab=transport-finance&section=charts/table` |
| Controller | `Modules\Transport\app\Http\Controllers\TransportReportController` |
| Tab Builder Method | `buildFinanceSection()` (line 158) |
| Data Method | `getFinanceLeakageReport()` (line 794) |
| Leakage Detection | `determineLeakage()` (line 931) |
| Chart Data | `prepareChartData()` (line 967) |
| View | `transport::report.transport-finance.index` |
| View Path | `Modules/Transport/resources/views/report/transport-finance/index.blade.php` (461 lines) |
| Permission | `tenant.transport-finance.viewAny` (permissionslist.php:342, `$crud` group) |
| Tab ID | `transport-finance` (transportreport.blade.php:15) |
| Hub View | `transport::tab_module.transportreport` |
| Pagination | Custom Collection-based: `paginateCollection()` at line 262, page name `page_finance` |
| Export | Not implemented |
| Section loading | Two AJAX sections: `charts` (KPI + charts), `table` (paginated table) |
| Date range parser | `parseDateRange()` at line 327 — default: current month |

---

## 2. Pre-conditions

| PRE ID | Condition | Detail |
|--------|-----------|--------|
| PRE-01 | Required permission | `tenant.transport-finance.viewAny` — must be assigned to role |
| PRE-02 | Tab container permission | `tenant.transport.viewAny` required to load the parent Transport Report page (controller line 36) |
| PRE-03 | Minimum tenant context | `tenancy()->initialize()` must have been called (multi-tenant) |
| PRE-04 | StudentAcademicSession records | Must exist with `transportAllocation` relationship |
| PRE-05 | TptStudentAllocationJnt records | Must be linked via `transportAllocation` on StudentAcademicSession |
| PRE-06 | StudentPayLog records | Must exist with `module_name = 'Transport'` for payment data |
| PRE-07 | StudentBoardingLog records | Must exist linked via `boardingLogs` on StudentAcademicSession |
| PRE-08 | TptStudentFeeCollection records | Optional — only used in universal transport report, NOT in this finance leakage report |
| PRE-09 | Dusk environment | `DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD` must be configured |
| PRE-10 | Chart.js library | Must be loaded via CDN (transportreport.blade.php:68): `https://cdn.jsdelivr.net/npm/chart.js` |
| PRE-11 | Date range picker lib | Must be loaded via CDN: daterangepicker + moment.js (blade lines 69-71) |
| PRE-12 | jQuery | Required for AJAX loading logic — assumed loaded by layout |
| PRE-13 | Academic session seeded | At least one `academic_session_id` present in StudentAcademicSession for filter dropdown |
| PRE-14 | SchoolClass records | Required for class filter dropdown rendering |
| PRE-15 | Route records (active) | Required for route filter dropdown — `Route::active()->get()` |

---

## 3. Architecture Overview

### 3.1 Data Flow



### 3.2 AJAX Section Loading Architecture

The view uses `@if(request('section') === 'charts')`, `@elseif(request('section') === 'table')`, `@else` to render three distinct fragments:

| Section | Request Trigger | Renders |
|---------|----------------|---------|
| `charts` | AJAX with `section=charts` | 4 KPI cards, 2 charts (doughnut + horizontal bar), Chart.js initialization script |
| `table` | AJAX with `section=table` | 10-column table with pagination |
| (default) | Page load (no section) | Filter bar + loading spinners for both charts and table containers |

The default (no section) is the initial server-rendered content that shows the filter form and placeholder divs. The AJAX calls then populate those placeholders.

### 3.3 View Structure (461 lines)



---

## 4. Pre-conditions (Detail)

- Required permission: `tenant.transport-finance.viewAny`
- Requires `StudentAcademicSession` records with `transportAllocation` (TptStudentAllocationJnt)
- Requires `StudentPayLog` with `module_name = 'Transport'` for payment data
- Requires `StudentBoardingLog` for attendance day counts
- Requires `TptStudentFeeCollection` (via `feeMaster.std_academic_sessions_id` join) — only for universal report, NOT finance
- Dusk environment: `DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD`

---

## 5. Default Data Load

### 5.1 Section: charts — 4 KPI cards + 2 charts

| Data | Source |
|------|--------|
| KPI: Fee Assigned | `$chartData['total_fee_assigned']` (sum of all fare from transportAllocation) |
| KPI: Fee Collected | `$chartData['total_fee_collected']` (sum of payments from StudentPayLog) |
| KPI: Total Balance | `$chartData['total_balance']` (fee - collected) |
| KPI: Leakage Cases | Count of records with non-empty `leakage_flag` |
| Payment Status Doughnut | `$chartData['paid_vs_unpaid']` — Paid (≥100%), Partial (1-99%), Unpaid (0%) |
| Leakage Type Distribution | Horizontal bar: top 5 leakage types by count (computed in PHP at blade lines 194-208) |

### 5.2 Section: table — 10 columns

| Column | Source | Display Format |
|--------|--------|----------------|
| Student | `$record['student_name']` | Student first + last name |
| Class | `$record['class']` | Class name + Section name |
| Attendance Days | `$record['attendance_days']` | Integer, center-aligned |
| Fee Assigned | `$record['fee_assigned']` | ₹number_format(x,2), fw-semibold |
| Fee Collected | `$record['fee_collected']` | ₹number_format(x,2), fw-semibold |
| Balance | `$record['balance']` | ₹number_format(x,2), text-danger if >0, text-success if =0 |
| Attendance % | `$record['attendance_percentage']` | Progress bar: green ≥80%, yellow ≥50%, red <50% |
| Collection % | `$record['collection_percentage']` | Progress bar: green ≥90%, yellow ≥70%, red <70% |
| Leakage Flag | `$record['leakage_flag']` | Badge: No Payment (danger), Partial Payment (warning), (info for others) |
| Leakage Type | `$record['leakage_type']` | Badge bg-info — composite string (may be multi-value) |

### 5.3 Filters

| Filter | Type | Source | Default |
|--------|------|--------|---------|
| Date Range | Date range picker (hidden from/to) | `parseDateRange()` | Current month (start → end) |
| Academic Session | Dropdown | `StudentAcademicSession::distinct()->with('academicSession')` | All Sessions |
| Class | Dropdown | `SchoolClass::active()->get()` | All Classes |
| Route | Dropdown | `Route::active()->get()` | All Routes |

### 5.4 Filter URL Parameter Mapping

| URL Param | Controller Usage |
|-----------|-----------------|
| `from_date` | [Query/Code Removed] |
| `to_date` | [Query/Code Removed] |
| `academic_session_id` | `StudentAcademicSession::where('academic_session_id', ...)` |
| `class_id` | Mapped via `class_section_id` in controller filters — `StudentAcademicSession::where('class_section_id', ...)` |
| `route_id` | NOT used in `getFinanceLeakageReport()` — only in filter config, passed as `reqFilters['route_id']` but never applied to the query |

### 5.5 GAP Identified

| GAP ID | Severity | File:Line | Description |
|--------|----------|-----------|-------------|
| GAP-01 | 🔴 Critical | Controller:797-799 | **`route_id` filter is defined in `$reqFilters` (line 44) and passed to `getFinanceLeakageReport()` (line 161) as `$filters['route_id']`, but `getFinanceLeakageReport()` only applies `academic_session_id`, `class_section_id`, and `student_id` filters. The `route_id` filter has NO effect** — users selecting a route will see all students regardless of route. |
| GAP-02 | 🟡 Medium | Controller:803 | **N+1 query problem**: `$session->boardingLogs->count()` accesses a lazy-loaded relationship. If 100 StudentAcademicSession records are returned, 101 queries execute (1 master + 100 boardingLogs). Should use `withCount('boardingLogs')`. |
| GAP-03 | 🟡 Medium | Controller:806-809 | **N+1 query problem**: `StudentPayLog::where(...)` inside `->map()` executes one query per student. Should batch-load all payments before the map loop. |
| GAP-04 | 🟡 Medium | View:42, 62, 82 | **All 4 KPI cards link to `route('transport.trip-management.index')`** — this is the SAME hardcoded link for all cards. Should link to relevant sections (e.g., Fee Collection module) or be removed. |
| GAP-05 | 🟢 Low | Controller:826 | **Hardcoded 22 working days**: `round(($boardings / 22) * 100, 1)` — assumes exactly 22 working days regardless of the actual date range. For a shorter month or holiday period, this percentage is incorrect. |
| GAP-06 | 🔴 Critical | View:443-457 | **Loading spinners never replaced if AJAX fails**: The error handler at view:196-198 in transportreport.blade.php sets the container HTML to an alert, but if the AJAX section view file itself has a PHP error, the response never reaches the success handler, and the spinner remains indefinitely. |
| GAP-07 | 🟢 Low | Controller:262-273 | **In-memory pagination**: `paginateCollection()` slices a Collection, not a Query. For large datasets (1000+ students), ALL records are loaded into memory, then only 10 are displayed. |
| GAP-08 | 🔴 Critical | Controller:794-830 | **Missing `route_id` filter entirely**: The `$filters['route_id']` variable is available but completely ignored. Students are filtered only by academic_session_id, class_section_id, and student_id |

---

## 6. Test Data Strategy

| TD ID | Setup | Purpose |
|-------|-------|---------|
| TD-01 | Create 15 StudentAcademicSession records with transportAllocation: 5 with fare=12000, 5 with fare=8000, 5 with fare=5000 | Test KPI aggregation, pagination (15 > 10/page) |
| TD-02 | For 5 students (fare=12000): create StudentPayLog with amount=12000 (full payment) | Test "Paid" classification, balance=0 |
| TD-03 | For 5 students (fare=8000): create StudentPayLog with amount=4000 (partial payment) | Test "Partial Payment" leakage, balance>0 |
| TD-04 | For 3 students (fare=5000): NO StudentPayLog records (zero payment) | Test "No Payment" leakage |
| TD-05 | For 2 students (fare=5000): NO boarding logs AND no payment | Test "No Attendance" leakage |
| TD-06 | Create StudentBoardingLog across 15 days for each student in TD-02/03/04 | Test attendance % calculation |
| TD-07 | Create zero boarding logs for TD-05 students | Test "No Attendance" detection |
| TD-08 | Create one student with fare=0 (transportAllocation.fare = NULL/0) | Test division guard: collection_percentage = 0 |
| TD-09 | Create StudentPayLog with module_name != 'Transport' (e.g., 'Tuition') | Test scope filter — should NOT be counted |
| TD-10 | Create 2 students with multiple payment logs (split payments) summing to > fare | Test overpayment scenario (balance could go negative) |
| TD-11 | Set dates to cover 1 month with 22 working days exactly | Test attendance_percentage against hardcoded 22-day divisor |
| TD-12 | Create StudentPayLog records outside the selected date range | Test date range filter — should NOT be included |
| TD-13 | No records at all | Test empty state: 0 KPI values, empty table |
| TD-14 | Records in multiple class_section_ids | Test class filter |
| TD-15 | Records in multiple academic_session_ids | Test academic session filter |
| TD-16 | Set attendance_percentage scenarios: ≥80% (green), 50-79% (yellow), <50% (red) | Test progress bar colour logic |
| TD-17 | Set collection_percentage scenarios: ≥90% (green), 70-89% (yellow), <70% (red) | Test progress bar colour logic |
| TD-18 | Create StudentAcademicSession with transportAllocation = null | [Query/Code Removed] |
| TD-19 | Create StudentPayLog with amount=0 | Test zero-amount payment — may be counted as payment |
| TD-20 | Date range with 0 working days (weekend range or holiday) | Test attendance_percentage with 0 divisor |

---

## 7. Business Conditions

### 7.1 Query Logic (`getFinanceLeakageReport` — line 794)

| BC ID | Detail |
|-------|--------|
| BC-QL-01 | [Query/Code Removed] |
| BC-QL-02 | [Query/Code Removed] |
| BC-QL-03 | [Query/Code Removed] |
| BC-QL-04 | [Query/Code Removed] |
| BC-QL-05 | Route filter: **DEFINED but NOT APPLIED** — `$filters['route_id']` exists in input but has no `when()` clause in query (GAP-01) |
| BC-QL-06 | [Query/Code Removed] |
| BC-QL-07 | Boardings: `$session->boardingLogs->count()` — lazy-loaded relationship count |
| BC-QL-08 | Leakage determined by `determineLeakage()`: No Attendance, No Payment, Partial Payment |

### 7.2 Leakage Detection Logic (`determineLeakage` — line 931)

| Condition | Flag | Type |
|-----------|------|------|
| `$boardings == 0 && $fee > 0` | 'No Attendance' | 'No Attendance' |
| `$boardings > 0 && $payments == 0` | 'No Payment' | 'No Payment' |
| `$boardings > 0 && $payments < $fee` | 'Partial Payment' | 'Partial Payment' |
| Multiple conditions true | Comma-separated flags (implode) | Pipe-separated types (implode) |
| No conditions met | Empty string (flag) | 'No Leakage' (type) |

### 7.3 Chart Data Logic (`prepareChartData` — line 967)

| BC ID | Key | Computation |
|-------|-----|-------------|
| BC-CRD-01 | `paid_vs_unpaid.paid` | Count where `collection_percentage >= 100` |
| BC-CRD-02 | `paid_vs_unpaid.unpaid` | Count where `collection_percentage == 0` |
| BC-CRD-03 | `paid_vs_unpaid.partial` | Count where `collection_percentage` is BETWEEN 1 AND 99 inclusive |
| BC-CRD-04 | `leakage_summary.with_leakage` | Count where `leakage_flag` is NOT empty |
| BC-CRD-05 | `leakage_summary.without_leakage` | Total - with_leakage |
| BC-CRD-06 | `total_fee_assigned` | `$financeData->sum('fee_assigned')` |
| BC-CRD-07 | `total_fee_collected` | `$financeData->sum('fee_collected')` |
| BC-CRD-08 | `total_balance` | `$financeData->sum('balance')` |
| BC-CRD-09 | Balance is NOT independently verified | Total balance = sum of individual balances. There is no cross-check that `total_balance === total_fee_assigned - total_fee_collected`. If a record has inconsistent data, the aggregate could be wrong. |

### 7.4 View-Level Computation (Leakage Type Distribution — blade lines 194-208)

| BC ID | Step | Description |
|-------|------|-------------|
| BC-VIEW-01 | Collect | Iterate all `$financeLeakage` records, group by `leakage_type` value |
| BC-VIEW-02 | Sort | `arsort()` — descending by count |
| BC-VIEW-03 | Slice | `array_slice(..., 0, 5, true)` — top 5 leakage types only |
| BC-VIEW-04 | Render | Horizontal bar chart with intensity-scaled red coloring |

### 7.5 Chart.js Configuration (View)

| BC ID | Chart | Config Detail |
|-------|-------|---------------|
| BC-CHART-01 | Payment Status | Type: `doughnut`, cutout: `70%`, colors: green/warning/danger, legend disabled |
| BC-CHART-02 | Payment Status tooltip | Shows count + percentage of total |
| BC-CHART-03 | Leakage Type | Type: `bar`, indexAxis: `y` (horizontal), borderRadius: 3, barThickness: 15 |
| BC-CHART-04 | Leakage Type color | Dynamic `rgba(220,53,69,alpha)` where alpha = 0.4 + (value/max)*0.6 |
| BC-CHART-05 | Leakage Type tooltip | Shows `{x} cases` |
| BC-CHART-06 | X-axis | `beginAtZero: true`, stepSize: 1, precision: 0 |

### 7.6 Authorization (Permission Gates)

| BC ID | Permission | Location | Behavior |
|-------|-----------|----------|----------|
| BC-AUTH-01 | `tenant.transport.viewAny` | Controller:36 — `index()` gate | Without → 403 for entire Transport Report page |
| BC-AUTH-02 | `tenant.transport-finance.viewAny` | Blade line 38 — `@can('tenant.transport-finance.viewAny')` | Without → tab-pane hidden, no @include renders |
| BC-AUTH-03 | `tenant.transport-finance.viewAny` | Blade line 15 — tab nav-tab `permission` key | Without → tab button hidden |
| BC-AUTH-04 | `tenant.transport-finance.viewAny` | permissionslist.php:342 — `'transport-finance' => $crud` | Source of truth: permission group exists in config |
| BC-AUTH-05 | `$crud` generates 17 actions | permissionslist.php:13-31 | create, view, viewAny, update, delete, restore, forceDelete, import, export, print, publish, status, email-schedule, remark, pdf, edit, approve |
| BC-AUTH-06 | Only `viewAny` used | Controller uses `viewAny` once; no other permissions checked | 16/17 registered permissions are unused |

### 7.7 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Full payment collected | balance = 0, no leakage flag, type = 'No Leakage' |
| BC-BIZ-02 | No payment with attendance > 0 | Leakage flag = 'No Payment', type = 'No Payment' |
| BC-BIZ-03 | Partial payment (0 < amount < fee) | Leakage flag = 'Partial Payment', type = 'Partial Payment' |
| BC-BIZ-04 | No attendance despite fee > 0 | Leakage flag = 'No Attendance', type = 'No Attendance' |
| BC-BIZ-05 | No fee assigned (fare = 0 or NULL) | fee_assigned = 0, collection_percentage = 0 (division guard at line 827) |
| BC-BIZ-06 | No data in range | Empty table: "No finance leakage records found" with colspan=10 |
| BC-BIZ-07 | Multiple leakages on same student | Flag: comma-separated (e.g., 'No Payment, Partial Payment'); Type: pipe-separated (e.g., 'No Payment \| Partial Payment') |
| BC-BIZ-08 | Attendance % ≥ 80% | Progress bar: bg-success (green) |
| BC-BIZ-09 | Attendance % 50-79% | Progress bar: bg-warning (yellow) |
| BC-BIZ-10 | Attendance % < 50% | Progress bar: bg-danger (red) |
| BC-BIZ-11 | Collection % ≥ 90% | Progress bar: bg-success (green) |
| BC-BIZ-12 | Collection % 70-89% | Progress bar: bg-warning (yellow) |
| BC-BIZ-13 | Collection % < 70% | Progress bar: bg-danger (red) |
| BC-BIZ-14 | Balance > 0 | text-danger class applied |
| BC-BIZ-15 | Balance = 0 | text-success class applied |
| BC-BIZ-16 | Payment from non-Transport module | Excluded from sum — `where('module_name', 'Transport')` filter |
| BC-BIZ-17 | Payment outside date range | [Query/Code Removed] |
| BC-BIZ-18 | No transportAllocation | [Query/Code Removed] |
| BC-BIZ-19 | Overpayment (payments > fee) | Balance goes negative. The `balance = fee - payments` formula allows this. Flag logic still works: `$payments < $fee` is false → no leakage. UNPAID students logic: `collection_percentage >= 100` for paid chart. |
| BC-BIZ-20 | Fare is NULL | `(float) ($alloc->fare ?? 0)` → treated as 0. fee_assigned = 0, collection_percentage = 0 |
| BC-BIZ-21 | 11+ records in table | Pagination via `page_finance` — page 2 shows records 11-20 |
| BC-BIZ-22 | Filter change triggers reload | JS submits form → AJAX reloads both charts AND table sections |
| BC-BIZ-23 | Page load initial state | Filter bar visible, both chart and table divs show spinner |
| BC-BIZ-24 | Reset button | Link to `request()->url()` (same URL without query params) — clears all filters |
| BC-BIZ-25 | Date picker change | daterangepicker callback fills hidden from_date/to_date and submits form |
| BC-BIZ-26 | Tab switch | If tab not yet loaded, AJAX loads both sections; if already loaded, no action |

### 7.8 Session-like Behavior Analysis

This report is **read-only** — there are no create/update/delete operations. However, the data it reads is mutable:

| Behavior | Impact | Risk |
|----------|--------|------|
| StudentPayLog can be edited after report view | Report data changes between views | 🟡 Medium — no cached snapshot |
| StudentBoardingLog can be edited after report view | Attendance days and leakage classifications change | 🟡 Medium |
| TransportAllocation fare can be updated mid-session | Fee assigned changes retroactively | 🟡 Medium |
| No data freeze mechanism | Historical report numbers are not immutable | 🟡 Medium — audit risk |
| Concurrent AJAX requests | Two simultaneous filter submissions could cause race condition in rendering | 🟢 Low |
| No locking or transactions | All reads, no writes — acceptable for read-only report | 🟢 Low |

### 7.9 Performance Analysis

| Metric | Detail | Assessment |
|--------|--------|------------|
| DB Queries per load | 1 (master) + N (boardingLogs) + N (payments) + N (transportAllocation) + N (student) + N (classSection→class→section) = **~5N+1** | 🔴 High — N+1 on every relationship |
| Memory per load | All matching StudentAcademicSession records + all related models + full Collection in memory | 🟡 Medium — scales linearly with students |
| View render time | PHP loops + Chart.js JSON serialization | 🟢 Low |
| AJAX latency | 2 sequential round trips (charts + table) | 🟢 Low |
| CDN dependency | Chart.js, moment.js, daterangepicker loaded from CDN | 🟡 Medium — offline/firewalled environments break |
| Pagination | In-memory on full Collection, not DB-level | 🟡 Medium — sorting entire dataset per page request |
| Missing index recommendations | `student_pay_log(student_id, module_name, log_date)`, `student_boarding_log(student_session_id)`, `student_academic_sessions(academic_session_id, class_section_id)` | 🟡 Medium — could cause slow queries on large datasets |

### 7.10 CSS/Visual Style Analysis

| Element | Style Source | Detail |
|---------|-------------|--------|
| KPI cards | `small-box text-bg-{color}` | AdminLTE small-box component for each metric |
| KPI colours | primary (blue), success (green), warning (yellow), danger (red) | Consistent color coding by metric type |
| SVG icons | Inline SVGs | Shield, checkmark, warning triangle, alert circle icons |
| Chart cards | `card border-0 shadow-sm h-100` | Borderless shadow cards for modern look |
| Chart headers | `bg-white border-bottom py-2` | Clean header with icon and title |
| Chart containers | `position: relative; height: 180px;` | Fixed height charts |
| Legend badges | `badge bg-{color} rounded-pill` | Pill-shaped badges below doughnut chart |
| Table | `table table-sm` | Small, compact table |
| Progress bars | `progress flex-grow-1` style="height: 6px" | Thin progress bars with percentage label |
| Empty state | `text-center text-muted py-3` | Centered muted text with inbox icon |
| Filter bar | `x-backend.tab.filter-bar` component | Consistent with other report tabs |
| Spinner | `spinner-border text-primary` | Bootstrap spinner during AJAX load |

### 7.11 Deep Business Logic Analysis (BC-BIZ-DEEP)

#### DEEP-01: `getFinanceLeakageReport()` — Lines 794-830

| Step | Line(s) | Code | Analysis |
|------|---------|------|----------|
| 1 | 794 | `getFinanceLeakageReport(array $filters, string $startDate, string $endDate): Collection` | Takes filters, start/end date strings. Returns a Collection (not paginated). |
| 2 | 796 | [Query/Code Removed] | [Query/Code Removed] |
| 3 | 797 | [Query/Code Removed] | [Query/Code Removed] |
| 4 | 798 | [Query/Code Removed] | Conditional student filter. Used for detail drill-down. |
| 5 | 799 | [Query/Code Removed] | Eliminates students without transport allocation. Critical for data integrity. |
| 6 | 800 | `->get()` | Executes query — loads ALL matching records into memory. No pagination at DB level. |
| 7 | 801 | `->map(function($session) use ($startDate, $endDate) {` | Maps over every record in PHP. This is where N+1 issues happen. |
| 8 | 802 | `$alloc = $session->transportAllocation;` | Accesses relationship — lazy-loaded, so executes another query per student. |
| 9 | 803 | `$boardings = $session->boardingLogs->count();` | **N+1**: lazy-loads boardingLogs for each student separately. |
| 10 | 806-809 | [Query/Code Removed] | **N+1**: queries payments per-student in loop. Should batch with GROUP BY. |
| 11 | 811 | `$fee = (float) ($alloc->fare ?? 0);` | Casts fare to float, defaults to 0 if null. |
| 12 | 812 | `$balance = $fee - $payments;` | Simple subtraction. Can produce negative values (overpayment). |
| 13 | 815 | `$leakage = $this->determineLeakage($boardings, $fee, $payments);` | Delegates to helper method. |
| 14 | 817-828 | Return array | Maps to 10-field array. Two calculated fields: `attendance_percentage` (hardcoded 22 days), `collection_percentage` (division guarded). |

#### DEEP-02: `determineLeakage()` — Lines 931-943

| Step | Line(s) | Code | Analysis |
|------|---------|------|----------|
| 1 | 931 | `determineLeakage(int $boardings, float $fee, float $payments): array` | Type-hinted: boardings must be int, fee and payments must be float |
| 2 | 933 | `$flags = [];` | Empty array accumulator |
| 3 | 935 | `if ($boardings == 0 && $fee > 0) $flags[] = 'No Attendance';` | Edge: student allocated, fee assigned, but never boarded |
| 4 | 936 | `if ($boardings > 0 && $payments == 0) $flags[] = 'No Payment';` | Edge: student boarded but paid nothing |
| 5 | 937 | `if ($boardings > 0 && $payments < $fee) $flags[] = 'Partial Payment';` | Edge: student boarded but paid less than fee |
| 6 | 939-942 | Return `['flag' => implode(', ', $flags), 'type' => empty($flags) ? 'No Leakage' : implode(' | ', $flags)]` | Flag: comma-separated (for display), Type: pipe-separated (for chart grouping). If no flags, type = 'No Leakage'. Note: condition at line 935 tests `$boardings == 0 && $fee > 0` — if both are 0, no flag is set. If boardings > 0 AND $payments == 0 AND fee is 0: line 936 sets 'No Payment', line 937 does NOT (0 < 0 is false). |
| 7 | — | Edge: `$boardings > 0`, `$payments == 0`, `$fee == 0` | Condition 935: false (boardings > 0). Condition 936: true (payments == 0) → 'No Payment'. Condition 937: false (0 < 0 is false). Result: 'No Payment' flag — misleading because fee is 0, nothing is owed. |

#### DEEP-03: `prepareChartData()` — Lines 967-987

| Step | Line(s) | Code | Analysis |
|------|---------|------|----------|
| 1 | 969 | `$total = $financeData->count();` | Total students in report |
| 2 | 970 | `$withLeakage = $financeData->filter(fn($item) => !empty($item['leakage_flag']))->count();` | Count of records with non-empty leakage_flag |
| 3 | 973-977 | `'paid_vs_unpaid' => ['paid' => ..., 'unpaid' => ..., 'partial' => ...]` | Three-way split based on collection_percentage ranges |
| 4 | 974 | [Query/Code Removed] | Students who have paid ≥ 100% of fee. Includes overpayments. |
| 5 | 975 | [Query/Code Removed] | Students with 0% collection — includes those with fee=0 AND those with no payment |
| 6 | 976 | [Query/Code Removed] | Partial payers. Strict comparison: includes exactly 1 and exactly 99. |
| 7 | 978-982 | `'leakage_summary' => [...]` | Summary: with/without leakage breakdown + total |
| 8 | 983-985 | KPI sums | Simple summation of fee_assigned, fee_collected, balance |

#### DEEP-04: `buildFinanceSection()` — Lines 158-165

| Step | Line(s) | Code | Analysis |
|------|---------|------|----------|
| 1 | 160 | `request()->merge(['section' => $section]);` | Overwrites the section parameter in request — critical for view conditional rendering |
| 2 | 161 | `$financeLeakage = $this->getFinanceLeakageReport(...);` | Loads ALL finance data (unpaginated collection) |
| 3 | 162 | `$chartData = $this->prepareChartData($financeLeakage, $startDate, $endDate);` | Computes KPIs and chart data from the full collection |
| 4 | 163 | `$financeLeakagePaginated = $this->paginateCollection($financeLeakage, 10, 'page_finance');` | Paginates the same collection — charts use full data, table shows 10/page |
| 5 | 164 | Returns rendered view | View uses `request('section')` to determine which fragment to render |

#### DEEP-05: `paginateCollection()` — Lines 262-273

| Step | Line(s) | Code | Analysis |
|------|---------|------|----------|
| 1 | 264 | `$page = Paginator::resolveCurrentPage($pageName);` | Resolves page from query string `?page_finance=N` |
| 2 | 265 | `$sliced = $items->slice(($page - 1) * $perPage, $perPage)->values();` | In-memory slice — ALL data was loaded by `get()` in step 6 of DEEP-01 |
| 3 | 266-272 | Returns `LengthAwarePaginator` | Wraps slice + total count into paginator for the view |

#### DEEP-06: AJAX Tab Loading — `transportreport.blade.php` JS

| Step | Line(s) | Code | Analysis |
|------|---------|------|----------|
| 1 | 106-109 | `loadTabSection(activeTab, 'charts')` then `loadTabSection(activeTab, 'table')` | Both sections loaded on initial page render via JS. |
| 2 | 112-121 | `$('button[data-bs-toggle="tab"]').on('shown.bs.tab', ...)` | Tab switch triggers lazy load if tab-pane doesn't have `.loaded` class. |
| 3 | 124-131 | `$(document).on('submit', '.transport-filter-form', ...)` | Filter form submission triggers reload of both sections. |
| 4 | 145-200 | `function loadTabSection(tabName, sectionName, formData)` | Makes AJAX GET request. Uses `window.location.pathname` (no hardcoded URL). Sets container opacity to 0.5 during load. |
| 5 | 191-198 | Success/Error handlers | Success: sets inner HTML. Error: sets alert message. |

### 7.9 Database Schema (Referenced Tables)

| BC ID | Table | Key Columns | Purpose in Report |
|-------|-------|-------------|-------------------|
| BC-DB-01 | `std_student_academic_sessions` | `id`, `student_id`, `academic_session_id`, `class_section_id` | Student enrollment base — primary query target |
| BC-DB-02 | `tpt_student_route_allocation_jnt` | `id`, `student_session_id`, `fare`, `pickup_route_id`, `drop_route_id` | Transport allocation — linked via `transportAllocation` relationship on StudentAcademicSession |
| BC-DB-03 | `tpt_student_boarding_log` | `id`, `student_session_id`, `student_id`, `trip_date` | Boarding records — accessed via `boardingLogs` relationship on StudentAcademicSession |
| BC-DB-04 | `std_student_pay_log` | `id`, `student_id`, `module_name`, `log_date`, `amount` | Payment records — filtered by `module_name = 'Transport'` |
| BC-DB-05 | `std_students` | `id`, `first_name`, `last_name` | Student name — accessed via `student` relationship on StudentAcademicSession |
| BC-DB-06 | `std_class_sections` | `id`, `class_id`, `section_id` | Class-section join — accessed via `classSection` on StudentAcademicSession |
| BC-DB-07 | `std_school_classes` | `id`, `name` | Class name — accessed via `classSection.class` |
| BC-DB-08 | `std_sections` | `id`, `name` | Section name — accessed via `classSection.section` |
| BC-DB-09 | `tpt_routes` | `id`, `name` | Route name — NOT used in this report's query despite filter dropdown |
| BC-DB-10 | `academic_sessions` | `id`, `name` | Session name for dropdown — accessed via `academicSession` relationship |

---

## 8. Test Case List

### 8.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | Tab loads with filter bar | Filters: Date Range, Academic Session, Class, Route with search functionality and reset button | — | — | ⬜ |
| TC-P02 | KPI cards show financial aggregates | Fee Assigned, Fee Collected, Total Balance, Leakage Cases with ₹ formatting via `number_format(x, 2)` | — | — | ⬜ |
| TC-P03 | Table shows student-level financial data | All 10 columns with ₹ formatting on monetary fields (Fee Assigned, Fee Collected, Balance) | — | — | ⬜ |
| TC-P04 | Payment Status doughnut chart renders | Chart.js doughnut with 3 segments: Paid (green), Partial (yellow), Unpaid (red) — legend badges below | — | — | ⬜ |
| TC-P05 | Leakage Type Distribution horizontal bar chart | Top 5 leakage types by count with intensity-scaled red bars | — | — | ⬜ |
| TC-P06 | Filter by academic session | Only students from selected academic session shown | — | — | ⬜ |
| TC-P07 | Filter by class | Only students from selected class shown | — | — | ⬜ |
| TC-P08 | Filter by route | **Not working** — route_id filter is NOT applied in query (GAP-01) | — | — | ⬜ |
| TC-P09 | Date range constrains payments | Payments outside selected range excluded from fee_collected | — | — | ⬜ |
| TC-P10 | Attendance % progress bar | Green bar (bg-success) for ≥80%, Yellow (bg-warning) for ≥50%, Red (bg-danger) for <50% | — | — | ⬜ |
| TC-P11 | Collection % progress bar | Green bar (bg-success) for ≥90%, Yellow (bg-warning) for ≥70%, Red (bg-danger) for <70% | — | — | ⬜ |
| TC-P12 | Balance colour coding | Positive balance = text-danger, Zero = text-success | — | — | ⬜ |
| TC-P13 | Pagination works | 15 records → 2 pages via `page_finance` query parameter | — | — | ⬜ |
| TC-P14 | Full payment → No Leakage | Student with fee=12000 and payment=12000: balance=0, no flag, type='No Leakage' | — | — | ⬜ |
| TC-P15 | Partial payment → Partial Leakage | Student with fee=12000 and payment=4000: balance=8000, flag='Partial Payment' | — | — | ⬜ |
| TC-P16 | No payment with attendance → No Payment Leakage | Student with fee=8000, payment=0, boardings>0: flag='No Payment' | — | — | ⬜ |
| TC-P17 | No attendance with fee → No Attendance | Student with fee=8000, payment=0, boardings=0: flag='No Attendance' | — | — | ⬜ |
| TC-P18 | Date picker range change triggers reload | Selecting new date range in daterangepicker auto-submits the filter form | — | — | ⬜ |
| TC-P19 | Reset button clears all filters | Clicking reset → URL without query params, all dropdowns reset to default | — | — | ⬜ |
| TC-P20 | Both charts and table load simultaneously | Initial page load shows both sections populated (not just one) | — | — | ⬜ |
| TC-P21 | Tab switch AJAX lazy load | Clicking another tab and returning to finance tab triggers load only if not previously loaded | — | — | ⬜ |
| TC-P22 | Chart tooltip shows percentage | Hovering over doughnut segment shows "Label: 5 (33%)" with total calculation | — | — | ⬜ |
| TC-P23 | KPI cards have hover/footer links | Each card has "More info" link to transport trip management | — | — | ⬜ |
| TC-P24 | Collection % shows percentage text | Each progress bar has a percentage label beside it (e.g., "75%") | — | — | ⬜ |
| TC-P25 | Payment from Transport module only counted | StudentPayLog with module_name='Tuition' is excluded from fee_collected sum | — | — | ⬜ |
| TC-P26 | Multiple leakage types on one student (No Attendance + No Payment) | Flag: 'No Attendance, No Payment'; Type: 'No Attendance \| No Payment'; both badges visible | — | — | ⬜ |
| TC-P27 | Student with zero attendance but partial payment (boardings=0, payments=2000, fee=12000) | Leakage: 'No Attendance' (boardings=0 && fee>0) + 'Partial Payment' (0<12000); Flag: 'No Attendance, Partial Payment' | — | — | ⬜ |
| TC-P28 | Multiple filter combination: academic_session + class + route | All three filters applied simultaneously; intersection of all conditions shown | — | — | ⬜ |
| TC-P29 | Pagination with filtered data | Apply class filter → 8 results (1 page); no pagination shown. Change filter → 12 results → 2 pages | — | — | ⬜ |
| TC-P30 | Date range spanning exactly 22 working days | Attendance % = (boardings / 22) * 100 should equal exactly 100% if student boarded all days | — | — | ⬜ |

### 8.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | No students with transport allocation | Empty collection → all KPIs = 0 or empty; table shows "No finance leakage records found" | — | — | ⬜ |
| TC-N02 | No payment records in date range | All students have fee_collected = 0; all with attendance flagged as 'No Payment'; balance = fee_assigned | — | — | ⬜ |
| TC-N03 | All fee assigned = 0 | collection_percentage = 0 for all (division guard); all go to 'unpaid' chart bucket (collection_percentage == 0 is true) | — | — | ⬜ |
| TC-N04 | 403 without `tenant.transport-finance.viewAny` | Tab hidden in nav; direct URL access to `/transport-report` causes 403 at controller level from `tenant.transport.viewAny` gate | — | — | ⬜ |
| TC-N05 | 403 without `tenant.transport.viewAny` | Full page 403 — cannot access Transport Report at all | — | — | ⬜ |
| TC-N06 | Guest access | Redirect to login page (Laravel auth middleware) | — | — | ⬜ |
| TC-N07 | AJAX error on chart load | transportreport.blade.php error handler shows alert: "Failed to load charts." | — | — | ⬜ |
| TC-N08 | AJAX error on table load | transportreport.blade.php error handler shows alert: "Failed to load table." | — | — | ⬜ |
| TC-N09 | Student with NULL fare | fare cast to 0 via `(float)($alloc->fare ?? 0)`; fee_assigned = 0; collection_percentage = 0 | — | — | ⬜ |
| TC-N10 | No boarding logs at all | All students have attendance_days = 0; attendance_percentage = 0%; no 'No Payment' leakage triggered (boardings == 0 prevents it); only 'No Attendance' for those with fee > 0 | — | — | ⬜ |
| TC-N11 | Payment amounts are negative | If pay_log has negative amount (refund/adjustment), fee_collected could be less than actual payments | — | — | ⬜ |
| TC-N12 | Multiple payments exceeding fee | balance goes negative; chart puts student in 'paid' bucket (collection_percentage >= 100) | — | — | ⬜ |
| TC-N13 | Invalid date range format | [Query/Code Removed] | — | — | ⬜ |
| TC-N14 | Invalid academic_session_id | Query returns empty result; empty state shown | — | — | ⬜ |
| TC-N15 | Student has transportAllocation but no student name | `optional($session->student)->first_name` — if student relationship is null, name shows " " (space) due to concatenation | — | — | ⬜ |
| TC-N16 | ClassSection relationship is null | `optional($session->classSection->class)->name` — if classSection is null, chained optional will show empty string | — | — | ⬜ |
| TC-N17 | 0 records in MySQL query but non-zero view defaults | View defaults: `$financeLeakage = $financeLeakage ?? collect()` prevents undefined variable errors | — | — | ⬜ |
| TC-N18 | Collection percentage exactly 0 | Goes to 'unpaid' bucket in chart; progress bar shows red (collection < 70) | — | — | ⬜ |
| TC-N19 | Collection percentage exactly 100 | Goes to 'paid' bucket in chart; progress bar shows green (collection >= 90) | — | — | ⬜ |
| TC-N20 | Attendance percentage exactly 50 | Yellow progress bar (>= 50 condition matched before < 50) | — | — | ⬜ |
| TC-N21 | Collection percentage exactly 70 | Yellow progress bar (>= 70 condition matched before < 70) | — | — | ⬜ |
| TC-N22 | Collection percentage exactly 90 | Green progress bar (>= 90) | — | — | ⬜ |
| TC-N23 | Large dataset stress test (10000+ students) | Page should not crash; memory limit may be exceeded due to in-memory Collection | — | — | ⬜ |
| TC-N24 | Chart.js library fails to load (CDN down) | KPI cards show correctly; chart areas show empty canvas or JS error; no data loss in table | — | — | ⬜ |
| TC-N25 | Daterangepicker library fails to load | Date range input shows as plain text field; no date picker UI but user can still type dates (no validation) | — | — | ⬜ |

### 8.3 Destructive / Exception Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-D01 | Delete all StudentPayLog for Transport module | KPIs show fee_collected = 0; leakage flags become 'No Payment' for all with attendance | — | — | ⬜ |
| TC-D02 | Delete all StudentBoardingLog records | All students have attendance_days = 0; leakage = 'No Attendance' for those with fee > 0 | — | — | ⬜ |
| TC-D03 | Remove transportAllocation from a student | Student disappears from report entirely (whereHas filter) | — | — | ⬜ |
| TC-D04 | Change academic_session_id to non-existent | Empty report — zero records match | — | — | ⬜ |
| TC-D05 | Change StudentPayLog.module_name away from 'Transport' | Payment excluded; student appears as unpaid | — | — | ⬜ |
| TC-D06 | Set StudentPayLog.log_date outside report range | Payment excluded; student shows lower fee_collected | — | — | ⬜ |
| TC-D07 | Set all transportAllocation.fare = 0 | All fee_assigned = 0; no student has fee > 0 so 'No Attendance' never triggers; all go to 'unpaid' bucket | — | — | ⬜ |
| TC-D08 | Remove `tenant.transport-finance.viewAny` from permissionslist.php | Gate::authorize('tenant.transport-finance.viewAny') throws InvalidArgumentException if permission is undefined; 500 error or 403 depending on gate behavior | — | — | ⬜ |
| TC-D09 | Set both from_date and to_date to same day | Report shows data for a single day; attendance can be 0 or 1 | — | — | ⬜ |
| TC-D10 | Set to_date before from_date | parseDateRange passes both on; query returns no payment records (date range invalid) | — | — | ⬜ |
| TC-D11 | Bulk delete all StudentAcademicSession records | Empty collection; all KPIs = 0; empty table state | — | — | ⬜ |
| TC-D12 | Change all StudentPayLog.module_name to NULL | `where('module_name', 'Transport')` compares NULL; no payments matched unless MySQL NULL comparison works | — | — | ⬜ |
| TC-D13 | Duplicate StudentPayLog records for same student | Fee_collected double-counted; balance decreased; potential negative balance | — | — | ⬜ |
| TC-D14 | Remove class_section_id from StudentAcademicSession | `optional($session->classSection->class)->name` returns null; class column shows empty | — | — | ⬜ |
| TC-D15 | Add future-dated payment logs | [Query/Code Removed] | — | — | ⬜ |

### 8.4 Code Review Test Cases

| TC ID | Priority | Description | Expected Result | Status |
|-------|----------|-------------|-----------------|--------|
| TC-CR01 | P1 | Payment query scoped to `module_name = 'Transport'` | Only transport-related payments summed; non-transport payments excluded | ◌ |
| TC-CR02 | P1 | Collection % division guard | `(float) $fee > 0 ? round(...) : 0` prevents division by zero | ◌ |
| TC-CR03 | P1 | Attendance % uses 22 working days (hardcoded) | `round(($boardings / 22) * 100, 1)` — always divides by 22 regardless of actual working days in range | ◌ |
| TC-CR04 | P1 | Leakage flag composite (multiple conditions) | `implode(', ', $flags)` — multiple flags comma-separated in flag field; pipe-separated in type field | ◌ |
| TC-CR05 | P1 | Chart data computed in `prepareChartData()` | Separate method for cleaner controller; called once and shared between charts and KPI cards | ◌ |
| TC-CR06 | P1 | Pagination uses `page_finance` | Unique page name prevents pagination conflicts with other tabs on the same page | ◌ |
| TC-CR07 | P1 | N+1 in boardingLogs count | `$session->boardingLogs->count()` lazy-loads per record — should use `withCount('boardingLogs')` | ◌ |
| TC-CR08 | P1 | N+1 in payment query | `StudentPayLog::where(...)->sum()` inside `->map()` = 1 query per student | ◌ |
| TC-CR09 | P2 | `route_id` filter not applied (GAP-01) | `$filters['route_id']` is never used in query builder — route filter has no effect | ◌ |
| TC-CR10 | P2 | In-memory pagination for large datasets | All records loaded into Collection via `get()`, then sliced by `paginateCollection()` — memory-intensive for 1000+ students | ◌ |
| TC-CR11 | P2 | [Query/Code Removed] | [Query/Code Removed] | ◌ |
| TC-CR12 | P2 | Chart.js loaded via CDN (no fallback) | If CDN fails, charts don't render; no error boundary | ◌ |
| TC-CR13 | P2 | Leakage type chart limited to top 5 | `array_slice(..., 0, 5)` — if there are more than 5 leakage types, only top 5 shown | ◌ |
| TC-CR14 | P2 | Balance calculation is simple subtraction | `$fee - $payments` — can produce negative values for overpayment; no overflow protection | ◌ |
| TC-CR15 | P2 | KPI cards all link to same route | Four different KPI cards all link to `route('transport.trip-management.index')` | ◌ |
| TC-CR16 | P2 | Empty leakage_type shows 'No Leakage' | `determineLeakage()` returns type='No Leakage' when no flags; view shows badge with text | ◌ |
| TC-CR17 | P2 | No server-side export/PDF | Export not implemented for this report — no download buttons exist | ◌ |
| TC-CR18 | P3 | `request()->merge(['section' => $section])` in builder | Section is overridden in request — this is how the view conditional `@if(request('section') === 'charts')` works | ◌ |
| TC-CR19 | P3 | Blade handles both array and object records | View uses `is_array($record) ? $record['key'] : $record->key` — handles mixed data types | ◌ |
| TC-CR20 | P3 | KPI values use ₹ prefix | `₹{{ number_format($totalFeeAssigned, 2) }}` — Indian Rupee symbol hardcoded | ◌ |
| TC-CR21 | P3 | Permission group `transport-finance` uses full `$crud` | Only `viewAny` is used; 16 other permissions defined but unused | ◌ |
| TC-CR22 | P3 | Doughnut chart cutout at 70% | `cutout: '70%'` — inner circle takes 70% of radius, leaving thin doughnut ring | ◌ |
| TC-CR23 | P3 | Collection_percentage boundary logic in chart | `>= 100` = paid, `== 0` = unpaid, `between 1 and 99` = partial — exact integer comparisons, no floating point edge cases | ◌ |
| TC-CR24 | P3 | Fee formatting with number_format | `number_format($totalFeeAssigned, 2)` — 2 decimal places, comma separator for thousands | ◌ |
| TC-CR25 | P3 | AJAX URL uses `window.location.pathname` | No hardcoded URL; works with any base path | ◌ |
| TC-CR26 | P3 | Student name concatenation uses optional() | `optional($session->student)->first_name . ' ' . optional($session->student)->last_name` — if null, shows " " (single space) | ◌ |
| TC-CR27 | P3 | Class/section name uses chained optional() | `optional($session->classSection->class)->name . ' ' . optional($session->classSection->section)->name` — triple nesting, any null breaks chain | ◌ |
| TC-CR28 | P2 | KPI card links use hardcoded route name | `route('transport.trip-management.index')` repeated 4 times — fragile if route name changes | ◌ |
| TC-CR29 | P3 | View has both `$financeLeakage` and `$financeLeakagePaginated` | Full collection used for charts; paginated subset used for table — same data, two variables | ◌ |
| TC-CR30 | P3 | Leakage type chart data computed in blade, not controller | `foreach($financeLeakage as $record) { ... }` in blade line 196-204 — business logic in view layer | ◌ |

### 8.5 CODE-TRACE (End-to-End Code Path)

#### TC-TRACE-01: Page Load → Tab Render → Data Display

| Step | Component | File:Line | Action |
|------|-----------|-----------|--------|
| 1 | User request | Browser | `GET /transport-report?active_tab=transport-finance` |
| 2 | Router | `Modules/Transport/routes/web.php` | Maps to `TransportReportController@index` |
| 3 | Gate check | Controller:36 | `Gate::authorize('tenant.transport.viewAny')` |
| 4 | Parse dates | Controller:55-57 | `parseDateRange($request)` → $startDate, $endDate (default: current month) |
| 5 | Load filters | Controller:65 | `getFilterData()` → dropdown lists (sessions, classes, routes, etc.) |
| 6 | Render view | Controller:67 | `return view('transport::tab_module.transportreport', compact('filters', 'activeTab'))` |
| 7 | Tab nav renders | View:transportreport.blade.php:15 | Tab nav item 'transport-finance' shown (permission check) |
| 8 | Tab body includes | View:transportreport.blade.php:38-39 | `@can('tenant.transport-finance.viewAny') @include('transport::report.transport-finance.index')` |
| 9 | Default section | View:index.blade.php:385-459 | `@else` block renders filter bar + loading spinners |
| 10 | JS init | View:transportreport.blade.php:106-108 | `loadTabSection('transport-finance', 'charts')` and `loadTabSection('transport-finance', 'table')` |
| 11 | AJAX request | JS line 187-200 | `GET /transport-report?active_tab=transport-finance&section=charts` (plus filters) |
| 12 | Controller AJAX | Controller:60-61 | `$request->ajax() && $section` → `loadTabSection('transport-finance', 'charts', ...)` |
| 13 | Tab switch | Controller:83 | `match('transport-finance') → $this->buildFinanceSection('charts', ...)` |
| 14 | Build section | Controller:158-165 | `getFinanceLeakageReport()` → `prepareChartData()` → `paginateCollection()` → render view |
| 15 | Query data | Controller:794-830 | `getFinanceLeakageReport()` — query + map + determineLeakage |
| 16 | Detect leakage | Controller:931-943 | `determineLeakage()` — 3-condition logic |
| 17 | Compute charts | Controller:967-987 | `prepareChartData()` — KPI aggregates + payment status counts |
| 18 | Paginate | Controller:262-273 | `paginateCollection()` — in-memory slice for table |
| 19 | Render section=charts | View:index.blade.php:1-263 | KPI cards + doughnut chart + horizontal bar chart + Chart.js init |
| 20 | Render section=table | View:index.blade.php:265-383 | 10-column table + pagination links |
| 21 | AJAX response | JS line 191-193 | `container.html(res.html)` — populates chart div / table div |

#### TC-TRACE-02: Filter Submission

| Step | Component | File:Line | Action |
|------|-----------|-----------|--------|
| 1 | User selects filter | Browser | Changes dropdown, clicks filter button |
| 2 | JS intercept | transportreport.blade.php:124-131 | `$(document).on('submit', '.transport-filter-form', ...)` → prevents default, serializes form |
| 3 | AJAX call (2x) | JS line 129-130 | `loadTabSection('transport-finance', 'charts', formData)` + `loadTabSection('transport-finance', 'table', formData)` |
| 4 | Controller | Same flow as steps 12-20 above | Filters applied via `$reqFilters` array |
| 5 | Response | Both sections loaded | Filtered data displayed |

#### TC-TRACE-03: `determineLeakage()` Edge Cases

| Scenario | boardings | fee | payments | Condition 1 (b=0,f>0) | Condition 2 (b>0,p=0) | Condition 3 (b>0,p<f) | Flag | Type |
|----------|-----------|-----|----------|----------------------|----------------------|----------------------|------|------|
| Normal paid | 15 | 12000 | 12000 | ✗ | ✗ | ✗ | '' | 'No Leakage' |
| No payment | 15 | 12000 | 0 | ✗ | ✓ | ✓ | 'No Payment, Partial Payment' | 'No Payment \| Partial Payment' |
| Partial payment | 15 | 12000 | 4000 | ✗ | ✗ | ✓ | 'Partial Payment' | 'Partial Payment' |
| No attendance | 0 | 12000 | 0 | ✓ | ✗ | ✓ | 'No Attendance, Partial Payment' | 'No Attendance \| Partial Payment' |
| No attendance + no fee | 0 | 0 | 0 | ✗ | ✗ | ✗ | '' | 'No Leakage' |
| Fee=0, boarded, no pay | 15 | 0 | 0 | ✗ | ✓ | ✗ | 'No Payment' | 'No Payment' |
| Fee=0, boarded, paid 0 | 15 | 0 | 0 | ✗ | ✓ | ✗ | 'No Payment' | 'No Payment' |
| All three conditions | 0 | 12000 | 0 | ✓ | ✗ | ✓ | 'No Attendance, Partial Payment' | 'No Attendance \| Partial Payment' |

#### TC-TRACE-04: View Rendering Logic (index.blade.php)

| Step | Section | Line(s) | Description |
|------|---------|---------|-------------|
| 1 | section=charts | 5-13 | PHP defaults: `$financeLeakage ?? collect()`, `$chartData` with default zeros |
| 2 | section=charts | 15-83 | 4 KPI small-box cards with ₹ formatting, SVG icons, links |
| 3 | section=charts | 85-142 | Two chart cards: doughnut (payment status) + horizontal bar (leakage types) |
| 4 | section=charts | 96 | `canvas id="paymentChart"` — rendered by Chart.js |
| 5 | section=charts | 98-116 | Badge legend: Paid (bg-success), Partial (bg-warning), Unpaid (bg-danger) |
| 6 | section=charts | 132 | `canvas id="leakageTypeChart"` — rendered by Chart.js |
| 7 | section=charts | 145-262 | Inline `<script>`: Chart.js initialization with doughnut + horizontal bar configs |
| 8 | section=charts | 194-208 | PHP loop: builds `$leakageTypes` array from `$financeLeakage`, sorts desc, takes top 5 |
| 9 | section=charts | 211-212 | `@json()`: passes PHP arrays to JS |
| 10 | section=table | 286-330 | PHP: extracts each record's fields, computes status classes for progress bars, badges |
| 11 | section=table | 298-306 | Attendance status: >=80 green, >=50 yellow, <50 red |
| 12 | section=table | 308-315 | Collection status: >=90 green, >=70 yellow, <70 red |
| 13 | section=table | 317 | Balance class: `$balance > 0 ? 'text-danger' : 'text-success'` |
| 14 | section=table | 319-330 | Leakage badge: 'Partial Payment' → bg-warning, 'No Payment' → bg-danger, others → bg-info |
| 15 | section=table | 332-377 | Table rows with 10 columns, progress bars, badges |
| 16 | section=table | 370-376 | Empty state: colspan=10 "No finance leakage records found" |
| 17 | section=table | 381-383 | Pagination: `$financeLeakagePaginated->appends(request()->query())->links()` |
| 18 | default | 386-458 | Filter bar form + loading spinners for charts and table divs |

---

## 9. Detailed Test Steps

### 9.1 Environment Setup



### 9.2 Tab Visibility Test



### 9.3 KPI Cards Verification



### 9.4 Payment Status Doughnut Chart Verification



### 9.5 Leakage Type Distribution Chart Verification



### 9.6 Table Verification



### 9.7 Filter Verification



### 9.8 AJAX Verification



### 9.9 Pagination Verification



### 9.10 Permission Boundary Test



### 9.11 Chart Visual Regression Tests



### 9.12 Pagination Edge Cases



### 9.13 Data Integrity Tests



### 9.14 Edge Case: Leakage Detection Matrix



---

## 10. Perceived Issues & Recommendations

| Issue ID | Severity | File:Line | Description | Recommendation |
|----------|----------|-----------|-------------|----------------|
| ISS-01 | 🔴 Critical | Controller:794-830 | route_id filter not applied — route selection has no effect | [Query/Code Removed] |
| ISS-02 | 🔴 Critical | Controller:803 | N+1 on boardingLogs count | Replace with `->withCount('boardingLogs')` on the query |
| ISS-03 | 🔴 Critical | Controller:806-809 | N+1 on payment queries per student | [Query/Code Removed] |
| ISS-04 | 🟡 Medium | Controller:826 | Hardcoded 22 working days | Use `calculateWorkingDays($startDate, $endDate)` instead of magic number 22 |
| ISS-05 | 🟡 Medium | Controller:262-273 | In-memory pagination for all records | Move pagination to DB level with `->paginate()` on the query before `->get()` |
| ISS-06 | 🟡 Medium | View:42,62,82 | All KPI cards link to same trip management page | Remove links or add context-specific URLs |
| ISS-07 | 🟢 Low | Controller:327-339 | No date validation in parseDateRange | [Query/Code Removed] |
| ISS-08 | 🟢 Low | View:145-262 | Chart.js inline script inside @if(section=charts) | Move to separate JS file or use @push('scripts') |
| ISS-09 | 🟢 Low | View:194-208 | Leakage type computation in blade (2D rendering) | Move to prepareChartData() or a dedicated method |
| ISS-10 | 🟢 Low | View:286-330 | Heavy PHP logic inline in blade for status classes | Create a dedicated PHP helper or ViewModel |

---

## 11. Dependency Map



---

## 12. Appendix: Key Code Snippets

### 12.1 getFinanceLeakageReport() (Controller:794-830)


### 12.2 determineLeakage() (Controller:931-943)


### 12.3 prepareChartData() (Controller:967-987)


### 12.4 buildFinanceSection() (Controller:158-165)


### 12.5 paginateCollection() (Controller:262-273)


### 12.6 parseDateRange() (Controller:327-339)


---

## 13. Summary

| Metric | Count |
|--------|-------|
| Feature Information | 21 items |
| Pre-conditions | 15 |
| Architecture Overview | 3 sections + detailed data flow diagram |
| Default Data Load | 4 KPIs + 2 charts + 10 columns + 4 filters + 5 GAPs |
| GAPs Identified | 8 (3 Critical, 3 Medium, 2 Low) |
| Test Data Strategy | 20 setups |
| Business Conditions (Total) | 85+ |
| DB Schema BCs | 10 |
| Query Logic BCs | 8 |
| Leakage Detection BCs | 6 |
| Chart Data BCs | 9 |
| View-Level BCs | 4 |
| Chart.js Config BCs | 6 |
| Authorization BCs | 6 |
| Business Logic BCs | 26 |
| Session-like Behavior Analysis | 6 items |
| Performance Analysis | 7 items |
| CSS/Visual Style Analysis | 12 items |
| Deep Business Logic (DEEP) | 6 analyses (each step level) |
| Detailed CODE-TRACE | 4 end-to-end paths + truth table |
| Total Test Cases | 90 |
| Positive Test Cases (P) | 30 |
| Negative Test Cases (N) | 25 |
| Destructive Test Cases (D) | 15 |
| Code Review Test Cases (CR) | 30 |
| Detailed Test Steps | 14 sections |
| Perceived Issues | 10 (3 Critical, 3 Medium, 4 Low) |
| Dependency Map | Full |
| Key Code Snippets | 6 |

---

## 14. Risk Assessment

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Route filter has no effect (GAP-01) | Certain | High | Add route filter to query; impacts users who filter by route and expect correct results |
| N+1 query performance degrades at scale (1000+ students) | High | Medium | Batch-load relationships; use withCount() for boarding logs; batch payment sum query |
| Chart.js CDN outage renders charts non-functional | Low | Medium | Add fallback or self-host Chart.js |
| In-memory pagination exhausts PHP memory on large datasets (10000+ students) | Low | Critical | Move pagination to DB-level query |
| [Query/Code Removed] | Medium | Medium | Wrap parseDateRange in try/catch with fallback to defaults |
| All 4 KPI cards link to same unrelated page | Medium | Low | Remove links or add feature-specific URLs |
| Permission `transport-finance` defines 17 actions but only 1 used | Low | Low | Reduce permissionslist.php to only used actions |

---

## 15. Automation Readiness

| Aspect | Readiness | Notes |
|--------|-----------|-------|
| Dusk/Browser tests | 🟡 Partial | Tab loading, filter interaction, KPI rendering can be automated. Chart rendering requires visual diff tools |
| API/Unit tests | 🟢 Ready | `getFinanceLeakageReport()`, `determineLeakage()`, `prepareChartData()` are pure methods suitable for PHPUnit |
| Database seeders | 🟢 Ready | Seeder can create StudentAcademicSession + transportAllocation + boardingLogs + StudentPayLog |
| Data assertions | 🟢 Ready | KPI values, leakage flags, percentages all have deterministic expected values |
| Chart validation | 🔴 Not Ready | Chart.js renders on Canvas — no DOM elements to assert against without visual testing tool |
