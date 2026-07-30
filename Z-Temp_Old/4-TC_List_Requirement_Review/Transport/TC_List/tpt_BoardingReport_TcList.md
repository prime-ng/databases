# tpt_BoardingReport_TcList

## Module: Transport → Transport Report → Student Boarding / Unboarding

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | Transport |
| Tab Group | Transport Report |
| Feature | Student Boarding / Unboarding Report |
| URL(s) | `/transport-report?active_tab=student-boarding` (page load), AJAX: `GET /transport-report?active_tab=student-boarding&section=charts/table` |
| Controller | `Modules\Transport\Http\Controllers\TransportReportController` |
| Tab Builder Method | `buildStudentBoardingSection()` (line 221) |
| Data Method | `getStudentBoardingReport()` (line 905) |
| View | `transport::report.student-boarding-unboarding.index` |
| Permission Config Key | `'student-boarding' => $crud` (line 345 of `config/permissionslist.php`) |
| Tab Permission | `tenant.student-boarding.viewAny` (line 18 of transportreport.blade.php) |
| Controller Gate | `Gate::authorize('tenant.transport.viewAny')` in `index()` |
| Core Table | `tpt_student_boarding_log` (model: `StudentBoardingLog`) |
| Supporting Tables | `tpt_route`, `tpt_pickup_points`, `students`, `student_academic_sessions` |
| Pagination | 10 per page, page name `page_boarding` |
| Export | Not implemented |
| Auto-refresh | Not implemented |
| AJAX Load | Lazy-loaded charts + table sections after tab activation |

---

## 2. Architecture Overview

### 2.1 Request Flow



### 2.2 Component Tree



### 2.3 Data Model Relationships



### 2.4 Permission Hierarchy

| Permission Key | Scope | Used In |
|----------------|-------|---------|
| `tenant.transport.viewAny` | Controller-level Gate | `TransportReportController::index()` |
| `tenant.student-boarding.viewAny` | Tab visibility + view rendering | `transportreport.blade.php:18,47` |
| `tenant.student-boarding.view` | (defined in $crud) | Future use |
| `tenant.student-boarding.create` | (defined in $crud) | Future use |
| `tenant.student-boarding.update` | (defined in $crud) | Future use |
| `tenant.student-boarding.delete` | (defined in $crud) | Future use |
| `tenant.student-boarding.export` | (defined in $crud) | Future use |

**Note:** Currently only `viewAny` is used for the report tab. The full CRUD permission set exists in `permissionslist.php` (`$crud` = create, view, viewAny, update, delete, restore, forceDelete, import, export, print, publish, status, email-schedule, remark, pdf, edit, approve) but is NOT wired to any controller method for this report — this is a GAP.

---

## 3. Pre-conditions

| # | Pre-condition | Detail |
|---|---------------|--------|
| PC-01 | Required permission: `tenant.student-boarding.viewAny` | Tab hidden without it; 403 on direct access via AJAX |
| PC-02 | Requires `StudentBoardingLog` records with `trip_date` in range | At least 1 log for non-empty state |
| PC-03 | Requires `StudentAcademicSession` records with `academic_session_id` | Session filter dropdown populated |
| PC-04 | Requires `PickupPoint` records for `boarding_stop` / `unboarding_stop` names | Stop filter dropdown populated |
| PC-05 | Requires `Route` records for `boarding_route_id` / `unboarding_route_id` | Route filter dropdown populated |
| PC-06 | Requires `Student` records linked via `student_id` | Student name display in table |
| PC-07 | Date range defaults to current month (`startOfMonth` → `endOfMonth`) | When no `from_date`/`to_date` in request |
| PC-08 | Controller-level `tenant.transport.viewAny` must also pass | `index()` Gate check before tab renders |
| PC-09 | `$reqFilters` array collects: academic_session_id, route_id, stop_id, student_id | These are the only filter keys passed to `getStudentBoardingReport` |
| PC-10 | `paginateCollection()` helper requires Collection + perPage(10) + pageName('page_boarding') | Paginator resolves current page from query string |

### PC GAP Analysis

| GAP ID | Description |
|--------|-------------|
| GAP-PC-01 | `stop_id` filter is defined in the blade dropdown UI but is NOT used in `getStudentBoardingReport()` query — the `$filters` array pulls it from request but the query does not have a `->when($filters['stop_id'], ...)` clause |
| GAP-PC-02 | No `class_section_id` or `student_id` search field in the blade filter UI — student filter exists in controller but no UI element |
| GAP-PC-03 | The `student_id` parameter is accepted by controller but no dropdown/search is rendered for it in the view |
| GAP-PC-04 | `$crud` has 17 actions per permissionslist.php, but only `viewAny` is enforced — the report controller never uses create/view/update/delete/export/print/etc. for boarding |

---

## 4. Default Data Load

### 4.1 Section: charts — 4 Summary Cards + 2 Charts

| Data Item | Source | Notes |
|-----------|--------|-------|
| Total Records | `$boardingSummary->total` = `$studentBoardingReports->count()` | KPI card 1 (blue, `text-bg-primary`) |
| Completed Boardings | `$boardingSummary->completed` = where('status','Completed')->count() | KPI card 2 (green, `text-bg-success`) |
| Partial Boardings | `$boardingSummary->total - $boardingSummary->completed` | Computed in-view; KPI card 3 (yellow, `text-bg-warning`) |
| Safety Risks | `$boardingSummary->safety_risks` = where('safety_risk','Yes')->count() | KPI card 4 (red, `text-bg-danger`) |
| Daily Boarding Trend Chart | Bar chart: X=dates, Y=count | Boardings (green bars) + Unboardings (blue bars) per day |
| Boarding Status Distribution | Doughnut chart | 4 segments: Completed (green), Partial (yellow), Missed Boarding (red), Missed Drop (orange) |

### 4.2 Section: table — 9 Columns

| # | Column | Source | Display |
|---|--------|--------|---------|
| 1 | `#` | `$index + 1` | Auto-increment row number |
| 2 | Student | `$report->student_name` | `<div class="fw-semibold">` |
| 3 | Class/Section | Hardcoded "Class/Section Data" + `<small>N/A</small>` | **KNOWN BUG** — No real field in collection |
| 4 | Date | `$report->trip_date` | Formatted `d M Y` via Carbon |
| 5 | Route | Hardcoded "Route Info" + `$report->boarding_stop` | **KNOWN BUG** — No route_name in collection |
| 6 | Boarding | `$report->boarding_time` + computed status | Badge: green (On Time) / red (Missed) |
| 7 | Unboarding | `$report->unboarding_time` + computed status | Badge: green (Completed) / red (Missed) |
| 8 | Status | Computed from both times | Badge: green "Completed" / yellow "Partial" |
| 9 | Safety | `$report->safety_risk` | Badge: green "SAFE" / red "RISK" with icon |

### 4.3 Filter Bar Controls

| Control | Type | Source | Default |
|---------|------|--------|---------|
| Academic Session | `<select>` | `$filters['academicSessions']` | Empty (All Sessions) |
| Route | `<select>` | `$filters['routes']` | Empty (All Routes) |
| Stop | `<select>` | `$filters['stops']` | Empty (All Stops) |
| Date Range | Daterangepicker + 2 hidden inputs | Moment.js + `$request->dates` | Current month |

### 4.4 AJAX Loading Behavior

| Step | Action |
|------|--------|
| 1 | Page loads hub view with default tab pane + loading spinners |
| 2 | JS `$(document).ready` → calls `loadTabSection('student-boarding', 'charts')` |
| 3 | JS `$(document).ready` → calls `loadTabSection('student-boarding', 'table')` |
| 4 | AJAX GET → controller `loadTabSection()` → `buildStudentBoardingSection()` |
| 5 | Response HTML injected into `#student-boarding-charts` / `#student-boarding-table` |
| 6 | On tab switch: if pane not `.loaded`, repeat steps 2-5 for new tab |
| 7 | Filter form submit: preventDefault → AJAX reload both sections |
| 8 | Pagination click: preventDefault → AJAX reload table section only |

---

## 5. Test Data Strategy

| TD ID | Strategy | Details |
|-------|----------|---------|
| TD-01 | Both times present (Completed) | Create `StudentBoardingLog` with `boarding_time` and `unboarding_time` both set to valid timestamps |
| TD-02 | Boarding only (Missed Drop) | Create log with `boarding_time` set, `unboarding_time = null` → Status=Partial, Safety=RISK |
| TD-03 | Unboarding only (Missed Boarding) | Create log with `unboarding_time` set, `boarding_time = null` → Status=Partial, Safety=SAFE |
| TD-04 | Neither time present | Create log with `boarding_time = null`, `unboarding_time = null` → Status=Partial, Safety=SAFE |
| TD-05 | 11+ logs for pagination | Create exactly 11 logs across multiple dates to force page 2 |
| TD-06 | Multiple academic sessions | Create logs under session_id=1 and session_id=2 to test session filter |
| TD-07 | Multiple routes | Create logs with different `boarding_route_id` and `unboarding_route_id` values |
| TD-08 | Single day spike | Create 5+ logs all on same date to test daily bar aggregation |
| TD-09 | Null student_id edge | Insert log with `student_id = null` (if DB allows) or orphaned FK |
| TD-10 | Future date range | Create logs where `trip_date > endDate` → should not appear |
| TD-11 | Past date range | Create logs where `trip_date < startDate` → should not appear |
| TD-12 | Zero data state | No `StudentBoardingLog` records in date range → empty table + "No data" on charts |
| TD-13 | Large dataset | 1000+ logs across 30 days to test scroll/pagination performance |
| TD-14 | Mixed stop scenarios | Create logs where `boarding_stop_id` differs from `unboarding_stop_id` |
| TD-15 | Same boarding_time for multiple students | Multiple students boarded at same timestamp → group rendering |
| TD-16 | Boarding after midnight edge | `boarding_time` = `00:05` next day → check date grouping |

---

## 6. Business Conditions

### 6.1 Database Constraints & Schema (DB)

| DB ID | Constraint | Source | Implication |
|-------|-----------|--------|-------------|
| DB-01 | `tpt_student_boarding_log.trip_date` is `DATE` (not nullable) | Migration | All records must have a date; `whereBetween` always valid |
| DB-02 | `student_id` has FK to `students.id` | Migration | Orphaned student_ids cause `optional($log->student)` to return null → `student_name = ' '` |
| DB-03 | `student_session_id` has FK to `student_academic_sessions.id` | Migration | whereHas('studentSession') requires valid FK |
| DB-04 | `boarding_route_id` FK → `tpt_route.id` | Migration | Filter by route_id works via direct FK match |
| DB-05 | `unboarding_route_id` FK → `tpt_route.id` | Migration | Route filter uses OR between boarding/unboarding route |
| DB-06 | `boarding_stop_id` FK → `tpt_pickup_points.id` | Migration | `optional($log->boardingStop)->name` for stop name |
| DB-07 | `boarding_time` / `unboarding_time` are nullable `DATETIME` | Migration | Null = missed event; used to determine Status and Safety Risk |
| DB-08 | `deleted_at` nullable for SoftDeletes | Model trait | Soft-deleted logs excluded from default query (no `withTrashed()`) |
| DB-09 | No unique constraint on (student_id, trip_date) | Schema | Same student can have multiple logs per day (morning + afternoon) |
| DB-10 | `boarding_trip_id` / `unboarding_trip_id` FKs → `tpt_trips.id` | Migration | Links to trip execution data (not used in report query) |

### 6.2 Validation Logic (VAL)

| VAL ID | Condition | Expected Behavior | Source |
|--------|-----------|-------------------|--------|
| VAL-01 | `$startDate` > `$endDate` (reversed dates) | `whereBetween` returns empty collection — no error | Core Laravel behavior |
| VAL-02 | Invalid date string in `dates` field | [Query/Code Removed] | [Query/Code Removed] |
| VAL-03 | Non-numeric `route_id` in request | `where('boarding_route_id', 'abc')` → no results (no error) | Query string coercion |
| VAL-04 | `page_boarding` = -1 in URL | Paginator resolves to page 1 (clamped) | `Paginator::resolveCurrentPage()` |
| VAL-05 | `page_boarding` = 9999 (beyond max) | Paginator returns empty slice | `paginateCollection()` |
| VAL-06 | XSS in `search` or filter fields | No search field in this tab — no XSS vector | By design (no search input) |
| VAL-07 | `stop_id` filter submitted but not used | Filter silently ignored — no error, no effect | GAP: query missing stop_id where clause |
| VAL-08 | `academic_session_id` = 0 or empty string | `$filters['academic_session_id']` is falsy → when() skipped | Correct behavior |
| VAL-09 | Malformed `dates` separator | `explode(' - ', $request->dates, 2)` returns single element → `$to = null` → Carbon error | Missing `$to` causes exception |

### 6.3 Authorization Logic (AUTH)

| AUTH ID | Condition | Expected Behavior | Source |
|---------|-----------|-------------------|--------|
| AUTH-01 | User lacks `tenant.transport.viewAny` | `Gate::authorize()` throws `AuthorizationException` → 403 page | Controller index() line 36 |
| AUTH-02 | User lacks `tenant.student-boarding.viewAny` | Tab nav button hidden; `@can` block skipped; no include rendered | Blade lines 18, 47 |
| AUTH-03 | Direct AJAX call without permission | `@can` in blade prevents rendering → empty response | Blade guard |
| AUTH-04 | Guest (unauthenticated) user | Redirected to login page | Laravel auth middleware |
| AUTH-05 | User has `viewAny` but no other CRUD permissions | All UI renders correctly (only viewAny used) | By design |
| AUTH-06 | Super admin bypass | `Gate::before` in `AuthServiceProvider` returns true for is_super_admin | Global policy |

### 6.4 Business Logic — Query Layer (BIZ-QL)

| BIZ-QL ID | Condition | Expected Behavior | Source |
|-----------|-----------|-------------------|--------|
| BIZ-QL-01 | Base query: date range filter | [Query/Code Removed] | line 907 |
| BIZ-QL-02 | Academic session filter | [Query/Code Removed] | lines 908-909 |
| BIZ-QL-03 | Route filter | `where('boarding_route_id', $route_id)->orWhere('unboarding_route_id', $route_id)` — matches either direction | lines 910-911 |
| BIZ-QL-04 | Student filter | `where('student_id', $student_id)` | line 912 |
| BIZ-QL-05 | Stop filter | NOT IMPLEMENTED — `$filters['stop_id']` collected but no `->when()` clause | GAP |
| BIZ-QL-06 | No ordering in query | Logs returned in PK order (no `->orderBy()` or `->latest()` on base query) | line 907-913 |
| BIZ-QL-07 | No eager loading | `optional($log->student)` fires N+1 for each log's student relationship | lines 920-921 |
| BIZ-QL-08 | No withTrashed() call | Soft-deleted logs excluded automatically | Model uses SoftDeletes |
| BIZ-QL-09 | `get()` returns ALL matching records (no pagination at query level) | Entire result set loaded into memory then sliced by `paginateCollection()` | line 913 |
| BIZ-QL-10 | `studentSession` relationship uses `student_session_id` FK | StudentAcademicSession::where('academic_session_id', ...) filters correctly | line 908-909 |

### 6.5 Business Logic — Mapping Layer (BIZ-MAP)

| BIZ-MAP ID | Input | Mapping Rule | Output | Source |
|------------|-------|-------------|--------|--------|
| BIZ-MAP-01 | `boarding_time` + `unboarding_time` both set | `status = 'Completed'` | Green badge | line 922 |
| BIZ-MAP-02 | `boarding_time` set, `unboarding_time` NOT set | `status = 'Partial'`, `safety_risk = 'Yes'` | Yellow badge + RED RISK | lines 922-923 |
| BIZ-MAP-03 | `boarding_time` NOT set, `unboarding_time` set | `status = 'Partial'`, `safety_risk = 'No'` | Yellow badge + GREEN SAFE | lines 922-923 |
| BIZ-MAP-04 | Both times null | `status = 'Partial'`, `safety_risk = 'No'` | Yellow badge + GREEN SAFE | lines 922-923 |
| BIZ-MAP-05 | `$log->student` relationship null | `optional($log->student)->first_name` returns null → `' ' . ' ' . ' '` = `'  '` (double space) | Student name displays as blank | line 916 |
| BIZ-MAP-06 | `$log->boardingStop` relationship null | `optional($log->boardingStop)->name` returns null → `'—'` rendered by view default | Stop = "—" | line 460 |
| BIZ-MAP-07 | `boarding_time` has value | `$log->boarding_time->format('H:i')` | `'08:15'` format | line 918 |
| BIZ-MAP-08 | `boarding_time` is null | `'—'` (em dash) | Display "—" in table | line 918 |
| BIZ-MAP-09 | `trip_date` Carbon instance | `$log->trip_date->format('d M Y')` | `'15 Jan 2026'` format | line 917 |
| BIZ-MAP-10 | Pagination edge: page > total pages | `paginateCollection` returns empty `LengthAwarePaginator` | Table shows "No boarding records found" | line 498-504 |

### 6.6 Business Logic — Aggregation Layer (BIZ-AGG)

| BIZ-AGG ID | Aggregation | Formula | Source |
|-------------|-------------|---------|--------|
| BIZ-AGG-01 | Total Records | `$studentBoardingReports->count()` | line 226 |
| BIZ-AGG-02 | Completed Boardings | [Query/Code Removed] | line 227 |
| BIZ-AGG-03 | Partial Boardings | `$boardingSummary->total - $boardingSummary->completed` | Blade line 34 |
| BIZ-AGG-04 | Safety Risks | [Query/Code Removed] | line 228 |
| BIZ-AGG-05 | Completion Rate | `total>0 ? round((completed/total)*100, 1) : 0` | line 229-231 |
| BIZ-AGG-06 | Daily Boarding Count | JS: `reports.filter(r => r.boarding_time !== '—').length` grouped by date | JS lines 129-134 |
| BIZ-AGG-07 | Daily Unboarding Count | JS: `reports.filter(r => r.unboarding_time !== '—').length` grouped by date | JS lines 133-134 |
| BIZ-AGG-08 | Status Distribution | JS: 4 counters for Completed/Partial/Missed Boarding/Missed Drop | JS lines 138-149 |
| BIZ-AGG-09 | Safety Distribution | JS: Safe vs Risk counters from `report.safety_risk` | JS lines 151-156 |

### 6.7 Business Logic — View Rendering Layer (BIZ-VIEW)

| BIZ-VIEW ID | Logic | Source |
|-------------|-------|--------|
| BIZ-VIEW-01 | Boarding status in view: if `boarding_time` is null or `'—'` → `$boardingStatus = 'Missed'` else `'On Time'` | Blade lines 431-434 |
| BIZ-VIEW-02 | Unboarding status in view: if `unboarding_time` is null or `'—'` → `$unboardingStatus = 'Missed'` else `'Completed'` | Blade lines 437-440 |
| BIZ-VIEW-03 | Overall status: if either boarding or unboarding is Missed → `$overallStatus = 'Partial'` else `'Completed'` | Blade lines 443-446 |
| BIZ-VIEW-04 | Safety badge: `$report->safety_risk == 'Yes'` → RED `bg-danger` RISK badge else GREEN `bg-success` SAFE badge | Blade lines 486-495 |
| BIZ-VIEW-05 | Empty table: colspan=9 with inbox icon + "No boarding records found" | Blade lines 498-503 |
| BIZ-VIEW-06 | Branding: Summary cards use `small-box` pattern with icons and "More info" links | Blade lines 5-56 |
| BIZ-VIEW-07 | Chart empty state: JS `renderNoDataMessage()` draws text on canvas | JS lines 176-190 |
| BIZ-VIEW-08 | Status doughnut single-segment center text: renders value + label at canvas center | JS lines 367-389 |
| BIZ-VIEW-09 | Class/Section column is hardcoded to display "Class/Section Data" + `<small>N/A</small>` regardless of actual data | Blade lines 453-456 (KNOWN BUG) |
| BIZ-VIEW-10 | Route column displays "Route Info" + boarding_stop name; no actual route_name from relationship | Blade lines 458-461 (KNOWN BUG) |

### 6.8 Business Logic — Known Issues & Gaps (BIZ-GAP)

| BIZ-GAP ID | Issue | Impact | Severity |
|-------------|-------|--------|----------|
| BIZ-GAP-01 | `stop_id` filter in blade UI but NOT wired in `getStudentBoardingReport()` query | Stop filter has no effect on data | P2 |
| BIZ-GAP-02 | Class/Section column hardcoded as "Class/Section Data" + "N/A" | Misleading display; no actual class info shown | P1 |
| BIZ-GAP-03 | Route column shows only "Route Info" + boarding_stop name — no route_name | User cannot see which route the record belongs to | P1 |
| BIZ-GAP-04 | No `->orderBy('trip_date')` or `->latest()` in query | Results are in PK insertion order, not date order | P2 |
| BIZ-GAP-05 | No eager loading (`->with('student', 'boardingStop', ...)`) | N+1 query problem for each row's student + stop relationships | P2 |
| BIZ-GAP-06 | `paginateCollection` loads ALL records into memory | Memory pressure with large datasets (10K+ logs) | P2 |
| BIZ-GAP-07 | Missing student name search/filter in UI | User must know student_id (system PK) to filter by student | P3 |
| BIZ-GAP-08 | No export functionality (PDF/XLS) | Users cannot download or print the report | P3 |
| BIZ-GAP-09 | No auto-refresh or real-time polling | Safety risks may appear stale until manual refresh | P3 |
| BIZ-GAP-10 | `safety_risk = 'Yes'` only when boarding_time present AND unboarding_time absent | Biz rule does not consider the inverse (unboarding present but boarding absent) as risk | P3 |

### 6.9 Performance & Edge Cases (BIZ-PERF)

| BIZ-PERF ID | Scenario | Expected Behavior |
|-------------|----------|-------------------|
| BIZ-PERF-01 | 10,000+ logs in date range | `get()` loads all into memory → paginateCollection slices; page load slow |
| BIZ-PERF-02 | 365 days of data | Bar chart has 365 labels → cramped x-axis rendering |
| BIZ-PERF-03 | All records have same status | Doughnut chart single segment with center text overlay |
| BIZ-PERF-04 | 0 logs in date range | KPI cards show 0, chart → "No data available", table → empty state |
| BIZ-PERF-05 | Concurrent filter + pagination | Pagination uses `?page_boarding=2` but filter AJAX resets page to 1? Verify |
| BIZ-PERF-06 | `dates` range spans 1 year | Performance: query scans large date range, chart aggregates many days |
| BIZ-PERF-07 | `stop_id` param submitted (ignored) | Unused param in URL but silently ignored — no error |
| BIZ-PERF-08 | Page load with no AJAX (JS disabled) | Tab pane shows loading spinners indefinitely (no fallback) |

---

## 7. Test Case List

### 7.1 Positive (P)

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | Tab loads with filter bar | Filters: Academic Session, Route, Stop, Date Range rendered | — | — | ⬜ |
| TC-P02 | Summary cards show boarding aggregates | 4 KPI cards: Total, Completed, Partial (Total-Completed), Safety Risks | — | — | ⬜ |
| TC-P03 | Table shows per-log rows | All 9 columns: #, Student, Class/Section, Date, Route, Boarding, Unboarding, Status, Safety | — | — | ⬜ |
| TC-P04 | Daily Boarding Trend bar chart | Bar chart with dates on x-axis, green Boardings + blue Unboardings datasets | — | — | ⬜ |
| TC-P05 | Boarding Status doughnut chart | Doughnut with Completed/Partial/Missed Boarding/Missed Drop segments | — | — | ⬜ |
| TC-P06 | Filter by academic session | Only logs whose `studentSession.academic_session_id` matches selected session | — | — | ⬜ |
| TC-P07 | Filter by route | Only logs where `boarding_route_id` OR `unboarding_route_id` matches selected route | — | — | ⬜ |
| TC-P08 | Date range filter | Logs constrained to `trip_date BETWEEN start AND end` | — | — | ⬜ |
| TC-P09 | Completed status badge | Green "Completed" badge when both `boarding_time` and `unboarding_time` present | — | — | ⬜ |
| TC-P10 | Partial status badge (boarding only) | Yellow "Partial" badge when only `boarding_time` present | — | — | ⬜ |
| TC-P11 | Partial status badge (unboarding only) | Yellow "Partial" badge when only `unboarding_time` present | — | — | ⬜ |
| TC-P12 | SAFE badge (both times / unboarding only) | Green "SAFE" with checkmark when `safety_risk != 'Yes'` | — | — | ⬜ |
| TC-P13 | RISK badge (boarding only, no unboarding) | Red "RISK" with exclamation when `boarding_time` present AND `unboarding_time` absent | — | — | ⬜ |
| TC-P14 | Pagination with 11+ logs | Pagination controls appear; page_booking=2 loads next page; 10 rows/page | — | — | ⬜ |
| TC-P15 | AJAX filter + pagination combined | Filter by route → pagination links keep route filter applied via `appends(request()->query())` | — | — | ⬜ |
| TC-P16 | Filter reset link clears all filters | Reset link (`href="{{ request()->url() }}"`) removes all query params | — | — | ⬜ |
| TC-P17 | Daterangepicker preset ranges | "Today", "Last 7 Days", "This Month", "Last Month" presets work | — | — | ⬜ |
| TC-P18 | Multi-month date range | Data aggregated across months in bar chart | — | — | ⬜ |
| TC-P19 | Boarding_time badge shows H:i format | Time displayed as e.g. "08:15" not full datetime | — | — | ⬜ |
| TC-P20 | Completion rate displayed in view | `$boardingSummary->completion_rate` computed as rounded percentage | — | — | ⬜ |
| TC-P21 | Tab switch loads boarding section via AJAX | Switching from another tab to student-boarding triggers `loadTabSection` | — | — | ⬜ |
| TC-P22 | Charts section renders independently of table | Section=charts returns only KPI + charts HTML, no table | — | — | ⬜ |
| TC-P23 | Table section renders independently of charts | Section=table returns only table HTML, no KPI/charts | — | — | ⬜ |
| TC-P24 | "More info" links in KPI cards navigate correctly | Each KPI card has `a.small-box-footer` linking to `transport.transport-master.index` | — | — | ⬜ |
| TC-P25 | Doughnut chart shows percentage in tooltip | Tooltip: "Completed: 45 (60.0%)" format | — | — | ⬜ |

### 7.2 Negative (N)

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | No boarding logs in date range | Table: "No boarding records found" empty state with icon; Charts: "No data available" on canvas; KPIs: all 0 | — | — | ⬜ |
| TC-N02 | Log with null student_id | `optional($log->student)` returns null; `student_name = ' '` (space); table row shows blank student name | — | — | ⬜ |
| TC-N03 | Log with null boarding_stop_id | `boarding_stop` name = null → view renders `'—'` in Route column | — | — | ⬜ |
| TC-N04 | Both boarding_time AND unboarding_time null | Status = "Partial", Safety = "SAFE", Boarding= "—" Missed, Unboarding= "—" Missed | — | — | ⬜ |
| TC-N05 | 403 without `tenant.transport.viewAny` | Controller `Gate::authorize()` throws exception → 403 error page | — | — | ⬜ |
| TC-N06 | 403 without `tenant.student-boarding.viewAny` | Tab button hidden; AJAX returns empty; user cannot access via direct URL | — | — | ⬜ |
| TC-N07 | Guest (unauthenticated) access | Redirect to login page | — | — | ⬜ |
| TC-N08 | Invalid date range (start > end) | `whereBetween` returns empty collection; empty state shown | — | — | ⬜ |
| TC-N09 | Non-existent route_id filter | Query returns empty set (no matching boarding_route_id or unboarding_route_id) | — | — | ⬜ |
| TC-N10 | Non-existent academic_session_id | `whereHas` subquery returns no matches → empty set | — | — | ⬜ |
| TC-N11 | Orphaned student_session_id (points to deleted session) | [Query/Code Removed] | — | — | ⬜ |
| TC-N12 | `page_boarding` = 0 or negative | Paginator clamps to page 1; first page of results shown | — | — | ⬜ |
| TC-N13 | `page_boarding` value > total pages | Paginator returns empty slice; table shows empty state | — | — | ⬜ |
| TC-N14 | Malformed `dates` string (no separator) | [Query/Code Removed] | — | — | ⬜ |
| TC-N15 | SQL injection attempt via `route_id` | Eloquent parameter binding prevents injection; returns empty result set | — | — | ⬜ |
| TC-N16 | XSS attempt via `student_name` | Blade `{{ }}` auto-escapes HTML; displayed as text | — | — | ⬜ |
| TC-N17 | Stop filter submitted with valid stop_id | **GAP:** Filter silently ignored — same results as without filter | — | — | ⬜ |
| TC-N18 | Multiple `page_boarding` params in URL | Laravel uses first or last value (varies by version); test behavior | — | — | ⬜ |

### 7.3 Destructive / Edge (D)

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-D01 | 10,000 logs in date range | Page loads (may be slow); AJAX returns paginated set; chart aggregates all | — | — | ⬜ |
| TC-D02 | All logs marked `safety_risk = 'Yes'` | Safety Risks KPI = Total; all rows show RISK badge; doughnut all Missed Drop | — | — | ⬜ |
| TC-D03 | All logs marked `Completed` | Partial KPI = 0; Safety Risks = 0; doughnut = 100% Completed | — | — | ⬜ |
| TC-D04 | Single log in date range | KPI = 1/1/0/0; table shows 1 row; chart has 1 date bar | — | — | ⬜ |
| TC-D05 | Single day with 50 logs | Bar shows 50 boardings + variable unboardings on one date label | — | — | ⬜ |
| TC-D06 | `boarding_time` identical for all records | Bar chart shows high boarding count, zero variance | — | — | ⬜ |
| TC-D07 | Data spanning 12+ months | Query works; chart x-axis may be dense; pagination handles it | — | — | ⬜ |
| TC-D08 | Route appears only as `unboarding_route_id` never as `boarding_route_id` | Route filter via OR catches it; record still appears | — | — | ⬜ |
| TC-D09 | All records have null `boarding_stop_id` | Route column shows "Route Info" + "—" for all rows | — | — | ⬜ |
| TC-D10 | Session filter with no matching `student_session_id` across all logs | Empty set; empty state displayed | — | — | ⬜ |

### 7.4 Code Review (CR)

| TC ID | Priority | Description | Expected Result | Status |
|-------|----------|-------------|-----------------|--------|
| TC-CR01 | P1 | Route filter uses OR condition | `where('boarding_route_id', ...)->orWhere('unboarding_route_id', ...)` correctly matches either direction | ◌ |
| TC-CR02 | P1 | Safety risk logic correct | Risk = Yes iff `boarding_time` AND NOT `unboarding_time` | ◌ |
| TC-CR03 | P1 | View — Class/Section column is hardcoded N/A | The column does NOT display actual class/section data from the collection | ◌ |
| TC-CR04 | P1 | View — Route column is hardcoded "Route Info" | Does NOT display actual route name from relationship | ◌ |
| TC-CR05 | P1 | Pagination uses `page_boarding` | No conflict with other report tabs (`page_route`, `page_usage`, etc.) | ◌ |
| TC-CR06 | P1 | Null-safe student name | `optional($log->student)->first_name . ' ' . optional($log->student)->last_name` — but missing trim: if both null, result is `' '` (double space) not `''` | ◌ |
| TC-CR07 | P1 | `stop_id` filter not wired in query | Collected in `$reqFilters` but no `->when($filters['stop_id'], ...)` in `getStudentBoardingReport()` | ◌ |
| TC-CR08 | P1 | No `->orderBy` on query | Results in PK insertion order, not date order; inconsistent UX | ◌ |
| TC-CR09 | P2 | N+1 query for student + stop relationships | `$log->student`, `$log->boardingStop`, `$log->unboardingStop` each fire a query per row | ◌ |
| TC-CR10 | P2 | All records loaded into memory before pagination | `get()` loads entire result set before `paginateCollection` slices it | ◌ |
| TC-CR11 | P2 | `buildStudentBoardingSection()` calls `request()->merge(['section' => $section])` | Mutates global request state — could interfere with other tabs in same request | ◌ |
| TC-CR12 | P1 | `parseDateRange('dates')` — `explode` without count validation | If `dates` has no ` - ` separator, `$to` may be null, leading to Carbon error | ◌ |
| TC-CR13 | P2 | Date format inconsistency: `trip_date` format `d M Y` in mapped collection, then JS `new Date(a)` may fail | Format `d M Y` (e.g., "15 Jan 2026") is not ISO — `new Date()` may produce NaN in some browsers | ◌ |
| TC-CR14 | P2 | JS Chart `calculateChartData()` counts '—' string literal | View maps null to '—' before passing to JS; JS checks `!== '—'` which is fragile if format changes | ◌ |
| TC-CR15 | P2 | `renderNoDataMessage()` uses fixed canvas dimensions | Canvas may have 0 width/height if not properly sized by CSS | ◌ |
| TC-CR16 | P3 | Doughnut chart colors hardcoded in JS | Should be in CSS variables or config for theme support | ◌ |
| TC-CR17 | P2 | No `@push('scripts')` — charts JS is inline in `@if(section === 'charts')` | Charts JS reloaded every time section=charts is fetched via AJAX; event listeners may stack | ◌ |
| TC-CR18 | P1 | `$crud` has 17 permissions but only `viewAny` is used | Report controller does not enforce `tenant.student-boarding.view/create/update/delete/export` etc. | ◌ |
| TC-CR19 | P2 | Permission key `tenant.student-boarding.viewAny` vs controller `tenant.transport.viewAny` | Two-level gate: controller checks transport, tab checks student-boarding — possible mismatch | ◌ |
| TC-CR20 | P2 | `toggleStatus` and other CRUD routes not applicable for report | Report is read-only; no routes exist for boarding report CRUD (that's in StudentBoardUnboard module) | ◌ |
| TC-CR21 | P3 | JS `loadTabSection` uses `window.location.pathname` for AJAX URL | Hardcoded in JS; if route changes, AJAX breaks | ◌ |
| TC-CR22 | P2 | `transport_daterange` class used by all tabs | All transport report tabs share same daterangepicker JS class; form submissions are scoped by transport-filter-form class | ◌ |
| TC-CR23 | P1 | `$filters` array key `academicSessions` (camelCase) vs `stops`/`routes` | Inconsistent naming convention within filter data | ◌ |
| TC-CR24 | P2 | No `hasPages()` check on paginator in table section | Pagination link div always rendered even for single page | ◌ |
| TC-CR25 | P2 | `section=charts` view uses `$studentBoardingReports` (unpaginated collection) while `section=table` uses `$studentBoardingReportsPaginated` | Two different variable names for same underlying data | ◌ |
| TC-CR26 | P3 | "More info" links hardcode `transport.transport-master.index` route | Generic route — may navigate away from report without context preservation | ◌ |
| TC-CR27 | P2 | JS filter operation `Object.keys(chartData.dailyData).sort((a,b) => new Date(a) - new Date(b))` | Date format `d M Y` may cause incorrect sort order across months | ◌ |
| TC-CR28 | P2 | No `@endsection` or `@stop` marker for chart section in blade | Section logic uses `@if(request('section') === 'charts')` / `@elseif` / `@else` — no proper `@push` for scripts | ◌ |
| TC-CR29 | P3 | Doughnut chart hover offsets and animation are hardcoded | `hoverOffset: 15`, `animateScale: true`, `animateRotate: true` | ◌ |
| TC-CR30 | P2 | Blade view computes `$boardingStatus` and `$unboardingStatus` locally per row | Duplicates status logic already computed in PHP `getStudentBoardingReport()` mapping | ◌ |

### 7.5 Integration (I)

| TC ID | Description | Expected Result | Status |
|-------|-------------|-----------------|--------|
| TC-I01 | Route Performance tab filters affect boarding tab | No cross-contamination — each tab has separate AJAX state and filter forms | ◌ |
| TC-I02 | Management Dashboard uses `getStudentBoardingReport()` for boarding summary | Dashboard `buildDashboardSection()` calls same data method with same filters | ◌ |
| TC-I03 | Boarding tab with global transport filter changes | Changing date range on one tab does NOT affect other tabs (verified by `transport-filter-form` scope) | ◌ |
| TC-I04 | Student transport usage tab reports same boarding counts | Cross-tab consistency: same `StudentBoardingLog` source data | ◌ |
| TC-I05 | Tab context preserved after page refresh | `active_tab` query param persists tab selection after full page reload | ◌ |

### 7.6 UI / UX (U)

| TC ID | Description | Expected Result | Status |
|-------|-------------|-----------------|--------|
| TC-U01 | Page title/breadcrumb shows "Transport Report" | `<x-backend.components.breadcrum title="Transport Report">` | ◌ |
| TC-U02 | Loading spinner displayed during AJAX | Spinner `<div class="spinner-border">` shown in charts + table container | ◌ |
| TC-U03 | Empty state has icon + message | "No boarding records found" with `bi-inbox` icon; canvas shows "No data available" | ◌ |
| TC-U04 | Responsive layout: 4 cards  per row on desktop, 2 per row on mobile | `col-lg-3 col-6` → 4 cols on lg+, 2 cols on smaller | ◌ |
| TC-U05 | Table responsive via `.table-responsive` | Horizontal scroll on small screens | ◌ |
| TC-U06 | Daterangepicker opens on left | `opens: 'left'` ensures picker visible in layout | ◌ |
| TC-U07 | Reset filter link preserves tab context | `request()->url()` removes all query params but keeps base URL | ◌ |
| TC-U08 | Chart.js canvas has fixed height container | `.chart-container` style `height: 350px` prevents chart collapse | ◌ |
| TC-U09 | KPI cards use semantic color coding | Primary (blue), Success (green), Warning (yellow), Danger (red) | ◌ |
| TC-U10 | Status badges use color semantics | Completed=green, Partial=yellow, RISK=red, SAFE=green | ◌ |

### 7.7 Performance (PERF)

| TC ID | Scenario | Acceptable Threshold | Status |
|-------|----------|---------------------|--------|
| TC-PERF-01 | 1,000 logs, date range 30 days | Page load < 2s, AJAX response < 1s | ◌ |
| TC-PERF-02 | 10,000 logs, date range 90 days | Page load < 5s, AJAX response < 3s | ◌ |
| TC-PERF-03 | 100,000 logs, date range 1 year | Memory usage < 128MB for Collection | ◌ |
| TC-PERF-04 | Concurrent filter requests (10 simultaneous) | No deadlocks, all return within 5s | ◌ |
| TC-PERF-05 | Chart rendering with 365 daily labels | Chart renders within 2s, labels auto-skip | ◌ |

### 7.8 Security (SEC)

| TC ID | Description | Expected Result | Status |
|-------|-------------|-----------------|--------|
| TC-SEC-01 | Direct URL access without authentication | Redirect to login | ◌ |
| TC-SEC-02 | AJAX endpoint with expired session | Returns 401/redirect; JS error handler shows alert | ◌ |
| TC-SEC-03 | SQL injection via filter parameters | Eloquent parameter binding prevents injection | ◌ |
| TC-SEC-04 | XSS via student name with script tags | Blade `{{ }}` escapes HTML; rendered as text | ◌ |
| TC-SEC-05 | CSRF via AJAX endpoint | GET requests are idempotent — no state mutation | ◌ |

---

## 8. Code Trace

### 8.1 Index Flow



### 8.2 AJAX Dispatch



### 8.3 buildStudentBoardingSection (line 221)



### 8.4 getStudentBoardingReport (line 905)



### 8.5 View Assembly



### 8.6 paginateCollection Helper (line 262)



### 8.7 Chart.js Dataflow Diagram



---

## 9. Detailed Test Steps

### 9.1 Positive Test Steps

#### TC-P01: Tab loads with filter bar
1. Login as user with `tenant.student-boarding.viewAny` + `tenant.transport.viewAny`
2. Navigate to `/transport-report?active_tab=student-boarding`
3. **Verify** page loads with heading "Transport Report"
4. **Verify** "Student Boarding / Unboarding" tab button is visible in nav
5. Click the tab button
6. **Verify** Filter bar shows: Academic Session (select), Route (select), Stop (select), Date Range (daterangepicker), Filter button, Reset button
7. **Verify** Loading spinner is replaced by KPI cards + charts + table within 3s

#### TC-P02: Summary cards show boarding aggregates
1. Pre-condition: At least 10 logs with mixture of Completed/Partial/SafetyRisk
2. Load boarding tab
3. **Verify** 4 cards visible in row:
   - Total Records = count of all logs in date range
   - Completed Boardings = count of logs with both times
   - Partial Boardings = Total - Completed
   - Safety Risks = count of logs with safety_risk = 'Yes'

#### TC-P03: Table shows per-log rows
1. Pre-condition: At least 5 logs with various statuses
2. Load boarding tab → table section
3. **Verify** Column headers: #, Student, Class/Section, Date, Route, Boarding, Unboarding, Status, Safety
4. **Verify** Each row shows:
   - # = auto-increment
   - Student = student name (first_name last_name)
   - Class/Section = "Class/Section Data" + "N/A" (KNOWN BUG)
   - Date = formatted `d M Y`
   - Route = "Route Info" + boarding_stop name (KNOWN BUG)
   - Boarding = time badge + "On Time" or "Missed"
   - Unboarding = time badge + "Completed" or "Missed"
   - Status = "Completed" or "Partial" badge
   - Safety = "SAFE" or "RISK" badge

#### TC-P04: Daily Boarding Trend bar chart
1. Pre-condition: Logs across at least 3 different dates
2. Load boarding tab → charts section
3. **Verify** Canvas `#dailyBoardingChart` is rendered
4. **Verify** X-axis labels show dates
5. **Verify** Green bars = Boardings, Blue bars = Unboardings
6. **Verify** Y-axis label "Number of Students"
7. **Verify** Hover tooltip shows dataset label + count

#### TC-P05: Boarding Status doughnut chart
1. Pre-condition: Mixture of Completed, Partial, Missed Boarding, Missed Drop records
2. Load boarding tab → charts section
3. **Verify** Canvas `#boardingStatusChart` is rendered
4. **Verify** Doughnut chart has 2-4 colored segments
5. **Verify** Legend shows labels with count + percentage in tooltip
6. **Verify** Hover expands segment (hoverOffset: 15)

#### TC-P06: Filter by academic session
1. Pre-condition: Logs exist for session_id=1 and session_id=2
2. Load boarding tab
3. Select session_id=1 from Academic Session dropdown
4. Click Filter button
5. **Verify** AJAX reloads data showing only logs whose `studentSession.academic_session_id = 1`
6. Change to session_id=2
7. **Verify** Data changes accordingly

#### TC-P07: Filter by route
1. Pre-condition: Logs with route_id=5 as boarding_route_id and route_id=5 as unboarding_route_id
2. Load boarding tab
3. Select route_id=5 from Route dropdown
4. Click Filter button
5. **Verify** All records shown have boarding_route_id=5 OR unboarding_route_id=5
6. Switch to a route with no records
7. **Verify** Empty state shown

#### TC-P08: Date range filter
1. Pre-condition: Logs exist in week 1 month 1 and week 3 month 1
2. Load boarding tab (default: current month)
3. **Verify** All logs in current month shown
4. Change date range to month 2 (with no logs)
5. **Verify** Empty state displayed
6. Change date range back to month 1 week 1 only
7. **Verify** Only week 1 logs shown

#### TC-P09: Completed status badge
1. Pre-condition: Log with `boarding_time = '2026-01-15 08:15:00'`, `unboarding_time = '2026-01-15 15:30:00'`
2. Load boarding tab
3. **Verify** Status column: green badge "Completed"
4. **Verify** `status` field mapping: `Completed` from line 922

#### TC-P10: Partial status badge (boarding only)
1. Pre-condition: Log with `boarding_time = '2026-01-15 08:15:00'`, `unboarding_time = null`
2. Load boarding tab
3. **Verify** Status column: yellow badge "Partial"
4. **Verify** Boarding column: time shown, status "On Time"
5. **Verify** Unboarding column: "—" shown, status "Missed"

#### TC-P11: Partial status badge (unboarding only)
1. Pre-condition: Log with `boarding_time = null`, `unboarding_time = '2026-01-15 15:30:00'`
2. Load boarding tab
3. **Verify** Status column: yellow badge "Partial"
4. **Verify** Boarding column: "—" shown, status "Missed"
5. **Verify** Unboarding column: time shown, status "Completed"

#### TC-P12: SAFE badge
1. Pre-condition: Log with both times present OR only unboarding time
2. Load boarding tab
3. **Verify** Safety column: green badge with checkmark + "SAFE"
4. **Verify** `safety_risk = 'No'`

#### TC-P13: RISK badge
1. Pre-condition: Log with `boarding_time` present, `unboarding_time = null`
2. Load boarding tab
3. **Verify** Safety column: red badge with exclamation + "RISK"
4. **Verify** `safety_risk = 'Yes'`

#### TC-P14: Pagination
1. Pre-condition: Exactly 11 logs in date range
2. Load boarding tab → table section
3. **Verify** 10 rows on page 1
4. **Verify** Pagination controls visible
5. Click page 2
6. **Verify** 1 row on page 2
7. **Verify** URL contains `page_boarding=2`

#### TC-P15: Combined filter + pagination
1. Pre-condition: 15 logs matching route_id=3, 5 logs for other routes
2. Select route_id=3, apply filter
3. **Verify** 10 rows shown
4. Click page 2
5. **Verify** 5 rows shown
6. **Verify** URL contains `route_id=3` + `page_boarding=2`

#### TC-P16: Filter reset
1. Apply several filters
2. Click Reset link
3. **Verify** URL returns to base `/transport-report?active_tab=student-boarding` (no params)
4. **Verify** All filter controls reset to defaults

### 9.2 Negative Test Steps

#### TC-N01: Empty data state
1. Pre-condition: No `StudentBoardingLog` records in date range (e.g., future date)
2. Load boarding tab
3. **Verify** KPI cards all show 0
4. **Verify** Bar chart canvas shows "No data available"
5. **Verify** Doughnut chart canvas shows "No data available"
6. **Verify** Table shows "No boarding records found" with inbox icon

#### TC-N02: Null student_id
1. Pre-condition: Log with `student_id = null` (or FK violation → skip insert, test via query)
2. If log exists with null student
3. **Verify** Table row shows blank/empty for student name
4. **Verify** No 500 error from `optional($log->student)` null chain

#### TC-N03: Null boarding_stop_id
1. Pre-condition: Log with `boarding_stop_id = null`
2. **Verify** Route column shows "Route Info" + "—"

#### TC-N04: Both times null
1. Pre-condition: Log with `boarding_time = null`, `unboarding_time = null`
2. **Verify** Status = "Partial" (yellow)
3. **Verify** Safety = "SAFE" (green)
4. **Verify** Boarding badge = "—" + "Missed"
5. **Verify** Unboarding badge = "—" + "Missed"

#### TC-N05: 403 tenant.transport.viewAny
1. Login as user with `tenant.student-boarding.viewAny` but NOT `tenant.transport.viewAny`
2. Navigate to `/transport-report?active_tab=student-boarding`
3. **Verify** 403 error page

#### TC-N06: 403 student-boarding.viewAny
1. Login as user with `tenant.transport.viewAny` but NOT `tenant.student-boarding.viewAny`
2. Navigate to `/transport-report?active_tab=student-boarding`
3. **Verify** Tab button for "Student Boarding / Unboarding" is hidden
4. **Verify** Accessing URL directly → tab shows but body is empty (include skipped)

#### TC-N07: Guest access
1. Logout
2. Navigate to `/transport-report`
3. **Verify** Redirected to login page

#### TC-N08: Invalid date range (start > end)
1. Set `from_date=2026-02-01&to_date=2026-01-01`
2. **Verify** Empty result set returned
3. **Verify** Empty state rendered (no crash)

### 9.3 Destructive Test Steps

#### TC-D01: Large dataset (10,000 logs)
1. Seed 10,000 logs across 90 days
2. Load boarding tab
3. **Verify** Page loads within 5 seconds
4. **Verify** Pagination shows 1,000 pages
5. **Verify** Chart renders 90 daily labels (may be dense)

#### TC-D02: All safety risks
1. Seed all logs as `boarding_time` set, `unboarding_time = null`
2. **Verify** Safety Risks KPI = Total Records
3. **Verify** All table rows show red RISK badge
4. **Verify** Doughnut shows 100% Missed Drop

#### TC-D03: All Completed
1. Seed all logs with both times set
2. **Verify** Partial KPI = 0, Safety Risks = 0
3. **Verify** All rows show green Completed + SAFE
4. **Verify** Doughnut = 100% Completed

### 9.4 Code Review Verification Steps

#### TC-CR01: Route filter OR logic
1. Inspect `getStudentBoardingReport()` lines 910-911

#### TC-CR06: Null-safe student name
1. Inspect line 916: `optional($log->student)->first_name . ' ' . optional($log->student)->last_name`
2. **Verify** If both `first_name` and `last_name` are null, result is `'  '` (double space) not empty string

#### TC-CR07: stop_id filter GAP
1. Inspect `getStudentBoardingReport()` — lines 907-913
2. **Verify** No `->when($filters['stop_id'], ...)` exists
3. **Verify** `$reqFilters['stop_id']` is collected in `index()` line 48 but never used in boarding query

#### TC-CR13: Date format in JS
1. Inspect JS line 199: `new Date(a) - new Date(b)`
2. **Verify** Input format is `'d M Y'` (e.g., "15 Jan 2026")
3. **Verify** `new Date('15 Jan 2026')` may produce `Invalid Date` in Safari (non-standard format)

---

---

## 10. Migration Schema Reference

### 10.1 `tpt_student_boarding_log` Table Structure

| Column | Type | Nullable | Default | Notes |
|--------|------|----------|---------|-------|
| `id` | bigint(20) UNSIGNED | NO | AUTO_INCREMENT | Primary Key |
| `trip_date` | date | NO | — | Date of trip |
| `student_id` | bigint(20) UNSIGNED | YES | NULL | FK → `students.id` |
| `student_session_id` | bigint(20) UNSIGNED | YES | NULL | FK → `student_academic_sessions.id` |
| `boarding_route_id` | bigint(20) UNSIGNED | YES | NULL | FK → `tpt_routes.id` |
| `boarding_trip_id` | bigint(20) UNSIGNED | YES | NULL | FK → `tpt_trips.id` |
| `boarding_stop_id` | bigint(20) UNSIGNED | YES | NULL | FK → `tpt_pickup_points.id` |
| `boarding_time` | datetime | YES | NULL | Timestamp of boarding event |
| `unboarding_route_id` | bigint(20) UNSIGNED | YES | NULL | FK → `tpt_routes.id` |
| `unboarding_trip_id` | bigint(20) UNSIGNED | YES | NULL | FK → `tpt_trips.id` |
| `unboarding_stop_id` | bigint(20) UNSIGNED | YES | NULL | FK → `tpt_pickup_points.id` |
| `unboarding_time` | datetime | YES | NULL | Timestamp of unboarding event |
| `device_id` | bigint(20) UNSIGNED | YES | NULL | FK → `driver_attendances.id` |
| `created_at` | timestamp | YES | NULL | Laravel default |
| `updated_at` | timestamp | YES | NULL | Laravel default |
| `deleted_at` | timestamp | YES | NULL | SoftDeletes |

### 10.2 Indexes

| Index Name | Columns | Type |
|-----------|---------|------|
| PRIMARY | `id` | BTREE |
| `tpt_student_boarding_log_student_id_index` | `student_id` | BTREE |
| `tpt_student_boarding_log_trip_date_index` | `trip_date` | BTREE |


---

## 11. Business Logic Deep-Dive (BIZ-DEEP)

### 11.1 Boarding/Unboarding Status Matrix



### 11.2 Status Count Duplication in JS Chart

The JS `calculateChartData()` function (lines 138-149) classifies each record into status categories. **Important:** A "Missed Boarding" or "Missed Drop" record is ALSO counted as "Partial". This means `statusCounts.Partial` = (Missed Boarding + Missed Drop) while `statusCounts.Completed` stands alone. The doughnut chart's "Partial" slice includes ALL records where at least one event was missed — this is the sum of Missed Boarding + Missed Drop + Neither.

This creates a discrepancy:
- `$boardingSummary->completed` counts `status === 'Completed'` (both times present)
- `$boardingSummary->total - $boardingSummary->completed` counts all other records
- JS `statusCounts.Partial` is the count of records with at least one miss

These should be equivalent, and they ARE because the map function returns 'Partial' for any record where either time is missing — same logic.

### 11.3 Two-Level Gate Redundancy



**Issue:** `transport.viewAny` and `student-boarding.viewAny` are independent. A user might have `transport.viewAny` (passes controller Gate) but not `student-boarding.viewAny` (tab hidden, body empty). Conversely, a user with only `student-boarding.viewAny` but NOT `transport.viewAny` gets 403 at controller level before the tab permission even matters.

### 11.4 Filter Parameter Flow



---

## 12. Edge Case Scenarios — Combined Complexity (BIZ-COMBO)

| COMBO ID | Filters Applied | Expected Data Shape | Notes |
|----------|----------------|---------------------|-------|
| COMBO-01 | Session=A + Route=R1 + Date=Jan | Only logs matching ALL three (intersection) | `when()` clauses are AND — each filters the previous result |
| COMBO-02 | Route=R1 (appears only as boarding) + Route=R1 (appears only as unboarding) | All matching logs — OR catches both | Confirm no double-counting if same log matches both |
| COMBO-03 | Session=A (exists) + Route=9999 (non-existent) | Empty set, no error | Route filter produces empty query result |
| COMBO-04 | Date=week1 + Pagination page=2 with page_boarding | Page 2 of week1-only data | Appends work correctly with combined params |
| COMBO-05 | Date=Jan + Route=R1 + Session filter applied → then Reset | Returns to full Jan data | Reset link strips all params |
| COMBO-06 | 50 records, 10 pages — navigate to page 5 → change date range | Pagination resets to page 1 with new data | Verify: pagination `page_boarding` param is in URL; changing filters triggers AJAX which doesn't carry page param by default |
| COMBO-07 | Empty session filter (default "All Sessions") + date range | All sessions for that date range (no session filter applied) | `when($filters['academic_session_id'], ...)` — empty string is falsy, skipped correctly |
| COMBO-08 | Rapid filter changes (3 clicks in 1 second) | Last AJAX response renders; previous responses discarded | Browser cancels pending AJAX on new send? Verify jQuery ajax behavior |

---

## 13. Detailed Test Steps — Continued

### 13.1 Positive Test Steps (Continued)

#### TC-P17: Daterangepicker preset ranges
1. Load boarding tab
2. Click date range input to open daterangepicker
3. Click "Today" preset
4. **Verify** `from_date` and `to_date` both set to today
5. **Verify** AJAX fires with updated dates
6. Repeat for "Last 7 Days", "This Month", "Last Month"
7. **Verify** each preset applies correct date range

#### TC-P18: Multi-month date range
1. Set date range = January 1 to March 31 (quarter)
2. **Verify** Bar chart shows bars for Jan, Feb, Mar dates
3. **Verify** Data aggregates correctly across months
4. **Verify** Pagination spans all months' records

#### TC-P19: Boarding_time format
1. Pre-condition: Log with `boarding_time` = `2026-01-15 08:05:00`
2. **Verify** Table cell shows "08:05" (not full datetime)
3. **Verify** Same for `unboarding_time` → "15:30" format

#### TC-P20: Completion rate
1. Pre-condition: 5 Completed + 5 Partial = 10 total
2. **Verify** Completion rate = 50.0%
3. Pre-condition: 0 Completed + 10 Partial = 10 total
4. **Verify** Completion rate = 0.0%
5. Pre-condition: 0 total
6. **Verify** Completion rate = 0 (not division by zero error)

#### TC-P21: Tab switch AJAX loading
1. Load another tab (e.g., Route Performance)
2. Click "Student Boarding / Unboarding" tab
3. **Verify** `loadTabSection` called for both charts and table
4. **Verify** Loading spinner shown during AJAX
5. **Verify** Content replaces spinner

#### TC-P22: Charts section independent rendering
1. AJAX: `section=charts`
2. **Verify** Response HTML contains: 4 KPI cards + 2 chart canvases + chart JS
3. **Verify** Response does NOT contain: table HTML, pagination

#### TC-P23: Table section independent rendering
1. AJAX: `section=table`
2. **Verify** Response HTML contains: table with headers + rows + pagination
3. **Verify** Response does NOT contain: KPI cards, chart canvases, chart JS

#### TC-P24: "More info" links
1. **Verify** Each KPI card has a footer link
2. Click "More info" on any card
3. **Verify** Navigates to `transport.transport-master.index` route
4. **Verify** Link opens in same tab

#### TC-P25: Doughnut percentage tooltip
1. Hover over doughnut chart segment
2. **Verify** Tooltip shows: `{Label}: {count} ({percentage}%)`
3. Example: "Completed: 45 (60.0%)"
4. **Verify** Percentage = (segmentValue / total) * 100, rounded to 1 decimal

### 13.2 Negative Test Steps (Continued)

#### TC-N09: Non-existent route_id
1. Set `route_id=99999` (no route with this ID exists)
2. Apply filter
3. **Verify** Query returns empty collection (no matching boarding_route_id or unboarding_route_id)
4. **Verify** Empty state displayed

#### TC-N10: Non-existent academic_session_id
1. Set `academic_session_id=99999`
2. Apply filter
4. **Verify** Empty state displayed

#### TC-N11: Orphaned student_session_id
1. Pre-condition: Log has `student_session_id` pointing to deleted/null session
3. **Verify** Log does NOT appear in table
4. **Verify** Log is NOT counted in any summary metric

#### TC-N12: Negative page number
1. Set `page_boarding=-1`
2. Load table section
3. **Verify** Paginator resolves to page 1
4. **Verify** First 10 records shown

#### TC-N13: Page beyond total
1. Pre-condition: 5 total logs (1 page)
2. Set `page_boarding=5`
3. **Verify** Paginator returns empty slice
4. **Verify** Empty state "No boarding records found"
5. **Verify** No error or exception

#### TC-N14: Malformed dates string
1. Set `dates=2026-01-15` (single date, no separator)
2. **Verify** `explode(' - ', $dates, 2)` returns `['2026-01-15']`
3. **Verify** `$to = null` → Carbon parse on null may error
4. **Verify** Expected: error 500 OR fallback to default date range

#### TC-N15: SQL injection attempt
2. Apply filter
3. **Verify** Eloquent PDO parameter binding treats input as string
4. **Verify** No matching route_id (expected) → empty result

#### TC-N16: XSS in student_name
1. If student name contains `<script>alert('xss')</script>`
2. **Verify** Blade `{{ }}` escapes to `&lt;script&gt;alert('xss')&lt;/script&gt;`
3. **Verify** No script execution

#### TC-N17: Stop filter submitted (GAP verification)
1. Pre-condition: Logs at stop_id=1 and stop_id=2 both exist
2. Set `stop_id=1`
3. Apply filter
4. **Verify** Both stop_id=1 and stop_id=2 records still shown (filter has no effect)
5. Document as confirmed GAP

#### TC-N18: Double page_boarding param
1. Set URL: `?active_tab=student-boarding&page_boarding=2&page_boarding=5`
2. **Verify** Laravel uses last value (page=5) or first value (depends on version)
3. **Verify** No crash or error

### 13.3 Destructive Test Steps (Continued)

#### TC-D04: Single log
1. Pre-condition: Exactly 1 log in date range
2. **Verify** KPI: Total=1, Completed or Partial=1 or 0, Safety Risks=0 or 1
3. **Verify** Table: 1 row, no pagination controls
4. **Verify** Bar chart: 1 date with value=1 bar
5. **Verify** Doughnut: 1 segment = 100%

#### TC-D05: 50 logs on single day
1. Seed 50 logs all on same date
2. **Verify** Bar chart shows 1 date with Boardings=50 (+ variable unboardings)
3. **Verify** All 50 records paginated (5 pages of 10)
4. **Verify** Doughnut chart proportions based on status distribution

#### TC-D06: Same boarding_time
1. All 50 logs have same `boarding_time = '08:15:00'`
2. **Verify** Table shows same "08:15" for all boarding columns
3. **Verify** No crash or duplicate key violations

#### TC-D07: 12+ month data span
1. Seed logs monthly for 14 months
2. Set date range spanning all 14 months
3. **Verify** Query returns all matching records
4. **Verify** Bar chart renders (may have dense x-axis)
5. **Verify** Pagination works correctly across all records

#### TC-D08: Route only as unboarding_route_id
1. Seed route_id=10 only as `unboarding_route_id` (never as `boarding_route_id`)
2. Filter by route_id=10
3. **Verify** Records with `unboarding_route_id=10` appear in results
4. **Verify** Route filter's OR condition works correctly

#### TC-D09: All null boarding_stop_id
1. Seed all logs with `boarding_stop_id = null`
2. **Verify** Route column shows "Route Info" + "—" for all rows
3. **Verify** No error from `optional($log->boardingStop)->name`

#### TC-D10: Session filter returns empty
1. Pre-condition: Logs exist for session_id=1 only
2. Filter by session_id=2
3. **Verify** Empty state displayed
4. Filter by session_id=1 again
5. **Verify** Data reappears correctly

### 13.4 Integration Test Steps

#### TC-I01: Cross-tab filter isolation
1. Load "Student Transport Usage" tab, set route_id=5
2. Switch to "Student Boarding / Unboarding" tab
3. **Verify** Route filter is NOT carried over (each tab maintains own filter state)
4. **Verify** Boarding data shows ALL routes, not just route_id=5

#### TC-I02: Dashboard boarding summary consistency
1. Pre-condition: Known set of boarding logs
2. Load Management Dashboard tab
3. **Verify** Boarding summary metrics match those on Student Boarding tab
4. **Verify** `getStudentBoardingReport()` called with same date range and filters

#### TC-I03: Date range change isolation
1. Set date range to last month on "Route Performance" tab
2. Switch to "Student Boarding" tab
3. **Verify** Date range defaults to current month (not carried over)
4. **Verify** Daterangepicker initializes with current month

#### TC-I04: Cross-tab data consistency
1. Load Student Boarding tab → note total records count
2. Load Student Transport Usage tab → note total boardings aggregate
3. **Verify** Total boarding events in Student Transport Usage >= total records in Student Boarding (usage aggregates per-student may differ)
4. Document any discrepancy

#### TC-I05: Tab persistence on page refresh
1. Navigate to `/transport-report?active_tab=student-boarding`
2. **Verify** URL shows `active_tab=student-boarding`
3. Refresh page
4. **Verify** Student Boarding tab is active after refresh
5. **Verify** `$activeTab = $request->get('active_tab') ?: $request->get('tab', 'route-performance')` resolves correctly

---

## 14. Code Coverage Matrix

| Layer | File | Lines | Coverage |
|-------|------|-------|----------|
| Controller Gate | `TransportReportController::index()` | 36 | `tenant.transport.viewAny` |
| Tab Dispatch | `TransportReportController::loadTabSection()` | 86 | `match` to `buildStudentBoardingSection` |
| Builder | `TransportReportController::buildStudentBoardingSection()` | 221-235 | Summary + pagination + view |
| Data Query | `TransportReportController::getStudentBoardingReport()` | 905-926 | Filters + map + status logic |
| Pagination | `TransportReportController::paginateCollection()` | 262-273 | Slice + LengthAwarePaginator |
| View — Charts | `student-boarding-unboarding/index.blade.php` | 1-406 | KPI + Bar + Doughnut + JS |
| View — Table | `student-boarding-unboarding/index.blade.php` | 408-512 | 9-col table + status badges + pagination |
| View — Filter | `student-boarding-unboarding/index.blade.php` | 516-570 | Filter form + loading spinners |
| Layout | `transportreport.blade.php` | 18, 47-49 | Tab nav permission + include guard |
| Config | `permissionslist.php` | 345 | `'student-boarding' => $crud` |

---

## 15. Known Issues — Consolidated

| # | Issue | Location | Severity | Fix Recommendation |
|---|-------|----------|----------|-------------------|
| 1 | Class/Section column hardcoded as "Class/Section Data" + "N/A" | `index.blade.php` lines 453-456 | P1 | Add `class_name` and `section_name` to `getStudentBoardingReport()` map output (eager load via `student.studentSession.classSection`) |
| 2 | Route column shows "Route Info" + boarding_stop, never route_name | `index.blade.php` lines 458-461 | P1 | Add `route_name` to map: `'route_name' => optional($log->boardingRoute)->name ?? optional($log->unboardingRoute)->name` |
| 3 | `stop_id` filter not wired in query | [Query/Code Removed] | P2 | [Query/Code Removed] |
| 4 | No `->orderBy()` on query | `getStudentBoardingReport()` line 913 | P2 | Add `->orderBy('trip_date')->orderBy('boarding_time')` before `->get()` |
| 5 | N+1 for student + stop relationships | `getStudentBoardingReport()` lines 916-921 | P2 | Add `->with('student', 'boardingStop', 'unboardingStop', 'boardingRoute', 'unboardingRoute')` |
| 6 | All records loaded into memory before pagination | `getStudentBoardingReport()` line 913 + `paginateCollection()` | P2 | Use query-level pagination (`->paginate()`) instead of collection-level |
| 7 | `parseDateRange()` can produce null `$to` | `parseDateRange()` lines 329-332 | P2 | Add count check: `if (count($parts) < 2) return [default range]` |
| 8 | JS date parsing of non-ISO format | JS line 199 (`new Date(a)`) | P2 | Pass ISO format (`Y-m-d`) from PHP instead of `d M Y` |

---

## 16. Report Summary

| Metric | Count |
|--------|-------|
| Feature Information sections | 1 |
| Architecture Overview sections | 4 |
| Pre-conditions (PC) | 10 |
| PC GAPs | 4 |
| Default Data Load items | 4 |
| Test Data Strategies (TD) | 16 |
| Database Constraints (DB) | 10 |
| Validation Logic (VAL) | 9 |
| Authorization Logic (AUTH) | 6 |
| Business Logic — Query Layer (BIZ-QL) | 10 |
| Business Logic — Mapping Layer (BIZ-MAP) | 10 |
| Business Logic — Aggregation Layer (BIZ-AGG) | 9 |
| Business Logic — View Rendering Layer (BIZ-VIEW) | 10 |
| Business Logic — Known Issues & Gaps (BIZ-GAP) | 10 |
| Business Logic — Performance & Edge Cases (BIZ-PERF) | 8 |
| Positive Test Cases (P) | 25 |
| Negative Test Cases (N) | 18 |
| Destructive / Edge Test Cases (D) | 10 |
| Code Review Test Cases (CR) | 30 |
| Integration Test Cases (I) | 5 |
| UI/UX Test Cases (U) | 10 |
| Performance Test Cases (PERF) | 5 |
| Security Test Cases (SEC) | 5 |
| Code Trace sections | 7 |
| Detailed Test Steps | 25+ |
| **Total Known Bugs/Gaps** | **3 (Class/Section, Route, Stop Filter)** |
