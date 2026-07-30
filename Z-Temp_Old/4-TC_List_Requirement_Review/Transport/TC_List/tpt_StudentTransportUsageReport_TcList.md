# tpt_StudentTransportUsageReport_TcList

## Module: Transport → Transport Report → Student Transport Usage

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | Transport |
| Tab Group | Transport Report |
| Feature | Student Transport Usage Report |
| URL(s) | `/transport-report?active_tab=student-transport-usage` (page load), AJAX: `GET /transport-report?active_tab=student-transport-usage&section=charts/table` |
| Controller | `Modules\Transport\Http\Controllers\TransportReportController` |
| Tab Builder Method | `buildUsageSection()` (line 113) |
| Data Method | `getTransportUsage()` (line 606) |
| View | `transport::report.student-transport-usage.index` |
| Permission | `tenant.student-transport-usage.viewAny` (line 26 of transportreport.blade.php) |
| Export | Not implemented |

---

## 2. Pre-conditions

- Required permission: `tenant.student-transport-usage.viewAny` + `tenant.transport.viewAny`
- Requires seeded `StudentAcademicSession` records with `transportAllocation` relationship (meaning they have a `TptStudentAllocationJnt`)
- Requires `StudentBoardingLog` records linked to student sessions for boarding/unboarding counts
- Date range defaults to current month

---

## 3. Default Data Load

**Section: charts** — 4 summary cards + 3 charts:

| Data | Source |
|------|--------|
| Summary: Total Students, Total Boardings, Total Unboardings, Missed Events | Aggregated from `$usageReports` |
| Student Usage Chart (Top 10) | Bar chart: student_name vs boardings + unboardings |
| Missed Events Analysis | Doughnut chart: Missed Pickups vs Missed Drops |
| Class-wise Analysis | Bar chart: class_name aggregated boardings/unboardings/missed |

**Section: table** — paginated student-level rows:

| Column | Source |
|--------|--------|
| Student | `$usageReport->student_name` |
| Class | `$usageReport->class_name . ' ' . $usageReport->section_name` |
| Route | `$usageReport->route_name` |
| Stop | `$usageReport->stop_name` |
| Boarded | `$usageReport->total_boardings` badge |
| Unboarded | `$usageReport->total_unboardings` badge |
| Missed Pickup | badge: YES (danger) / NO (success) |
| Missed Drop | badge: YES (danger) / NO (success) |
| Status | badge: Excellent/Good/Fair/Poor based on attendance rate |

Filters: academic_session_id (in blade via `class_section_id`), route_id, stop_id, dates.

Pagination: 10/page via `paginateCollection($usageReports, 10, 'page_usage')`.

---

## 4. Test Data Strategy

- Create `StudentAcademicSession` records with `class_section_id` referencing active class+section
- Create `TptStudentAllocationJnt` records for each session (triggers `transportAllocation` relationship)
- Create `StudentBoardingLog` records with various combinations of boarding_time/unboarding_time (null for missed)
- Include edge: student with 0 boardings, student with all boardings completed, student with missed drop only
- Ensure at least 11 students to test pagination

---

## 5. Business Conditions

### 5.1 Query Logic (`getTransportUsage` — line 606)

| BC ID | Detail |
|-------|--------|
| BC-QL-01 | [Query/Code Removed] |
| BC-QL-02 | Academic session filter: `where('academic_session_id', $filters['academic_session_id'])` |
| BC-QL-03 | Class section filter: `where('class_section_id', $filters['class_section_id'])` |
| BC-QL-04 | Route name derived from `$alloc->pickupRoute->name ?? $alloc->dropRoute->name` |
| BC-QL-05 | Stop name derived from `$alloc->pickupStop->name ?? $alloc->dropStop->name` |
| BC-QL-06 | Missed boarding: `$logs->whereNull('boarding_time')->count() > 0` |
| BC-QL-07 | Missed drop: `$logs->whereNull('unboarding_time')->count() > 0` |

### 5.2 Database Schema — Referenced Tables

| Table | Key Columns |
|-------|-------------|
| std_student_academic_sessions | id, student_id, academic_session_id, class_section_id, is_current |
| tpt_student_route_allocation_jnt | id, student_session_id, pickup_route_id, drop_route_id, pickup_stop_id, drop_stop_id |
| tpt_student_boarding_log | id, trip_date, student_id, student_session_id, boarding_time, unboarding_time |
| sch_org_academic_sessions | id, name |
| sch_school_classes | id, name |
| sch_school_class_sections | id, class_id, section_id |

### 5.3 Business Logic Conditions

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Student with no boarding logs | total_boardings=0, total_unboardings=0, missed_boarding='YES' if allocation exists |
| BC-BIZ-02 | Student with boarding but no unboarding | missed_drop='YES' |
| BC-BIZ-03 | Student with both boarding and unboarding | All events counted; status=Completed |
| BC-BIZ-04 | Null student name in allocation | `$session->student` optional → `'—'` fallback |
| BC-BIZ-05 | No transport allocation for session | [Query/Code Removed] |
| BC-BIZ-06 | Chart shows only top 10 | `studentNames.slice(0, 10)` in JS |

---

## 6. Pre-conditions Detail (PC)

### PC-01: Database has students with transport allocations and boarding logs
- `StdStudentAcademicSession` has 15 records
- Each linked to `TptStudentAllocationJnt` with pickup_route_id and drop_route_id
- `StudentBoardingLog` has 50+ records across 15 students with varying boarding/unboarding times
- Class sections: 10A, 10B, 9A, 9B, 8A
- Routes: Route-1 (Morning), Route-2 (Evening), Route-3 (Mixed)
- Stops: Stop-A, Stop-B, Stop-C, Stop-D

### PC-02: Database has students with transport allocations but zero boarding logs
- 3 students have `TptStudentAllocationJnt` but zero `StudentBoardingLog` rows
- These students should appear in the report with total_boardings=0, total_unboardings=0
- missed_boarding='YES' for these students

### PC-03: Database has students with partial boarding logs (boarding only, no unboarding)
- 2 students have `boarding_time` set but `unboarding_time` is NULL for all their logs
- These should show missed_drop='YES'

### PC-04: Database has students with partial boarding logs (unboarding only, no boarding)
- 2 students have `unboarding_time` set but `boarding_time` is NULL for all their logs
- These should show missed_boarding='YES' (but this scenario is unusual — typically boarding happens first)

### PC-05: Database has mix of active and inactive routes
- Route-4 is soft-deleted or `is_active=0`
- Students allocated to this route should not appear because `Route::active()` is not called in `getTransportUsage` — but route name lookup via `optional($alloc->pickupRoute)->name` returns null → fallback to '—' or dropRoute name
- Test what happens when only dropRoute exists and pickupRoute is inactive

### PC-06: Database has 11+ students with same class-section to test pagination
- Class 10A has 12 students all with transport allocations
- Pagination limit is 10 per page via `page_usage`
- Page 1 has 10 students, Page 2 has 2 students

### PC-07: Database has academic sessions spanning 2 months
- Some boarding logs in January, some in February
- Default date range is current month (February)
- Only February logs should be counted

### PC-08: Database has students with no class section assigned
- `class_section_id` is NULL in `StdStudentAcademicSession`
- `optional($session->classSection?->class)->name ?? '—'` should render '—'
- This tests null-safe optional chaining

### PC-09: Database has multiple students sharing the same route and stop
- Route-1 has Stop-A with 5 allocated students
- Route-1 has Stop-B with 3 allocated students
- Ensures route/stop aggregation is correct

### PC-10: Database has a student with very high boarding count (50+ logs in a month)
- Student X has 45 boardings and 43 unboardings in February
- Tests that the count aggregation is correct at high volumes
- Status should be based on (45+43) total events vs (2+0) missed = 97.7% → Excellent

### PC-11: Database has a student with mixed daily logs (some complete, some partial)
- Over 20 trip dates:
  - 15 dates: both boarding_time and unboarding_time NOT NULL
  - 3 dates: only boarding_time NOT NULL (missed drop)
  - 2 dates: only unboarding_time NOT NULL (missed boarding — edge case)
- total_boardings=18, total_unboardings=17, missed_boarding=YES, missed_drop=YES

### PC-12: Database section_name is null for some class sections
- `sch_school_class_sections` has record with `section_id` pointing to a deleted Section
- `optional($session->classSection?->section)->name ?? '—'` should return '—'
- Tests the null-safe chain at the deepest level

### PC-13: Database has the current month with 0 boarding logs
- All logs are from previous months
- Default date range = current month → empty dataset
- Summary cards should show 0
- Table should show "No transport usage found for selected filters"
- Charts should render "No data available" / "No missed events" messages

### PC-14: Database has exactly 10 students (boundary of pagination)
- 10 students with transport allocations
- Paginator should show only 1 page
- Pagination controls should not render (or render disabled)

### PC-15: Permission roles are configured via `permissionslist.php`
- Role "Transport Viewer" has `tenant.student-transport-usage.viewAny`
- Role "Transport Manager" has `tenant.transport.viewAny` and `tenant.student-transport-usage.viewAny`
- Role "Admin" has all permissions via `Gate::before` `is_super_admin` check

---

## 7. Dependency List (DL)

| DL ID | Dependency | Source | Impact |
|-------|-----------|--------|--------|
| DL-01 | `Modules\StudentProfile\Models\StudentAcademicSession` | Model exists at `Modules/StudentProfile` | Must be importable with `transportAllocation` relationship |
| DL-02 | `Modules\Transport\Models\TptStudentAllocationJnt` | Model exists at `Modules/Transport` | Must define `pickupRoute`, `dropRoute`, `pickupStop`, `dropStop` relationships |
| DL-03 | `Modules\Transport\Models\StudentBoardingLog` | Model exists at `Modules/Transport` | Must define relationship back to `StudentAcademicSession` |
| DL-04 | [Query/Code Removed] | Eloquent ORM | The `transportAllocation` relationship must be defined on the model |
| DL-05 | `Illuminate\Support\Facades\Gate` | Laravel core | Must be available for `Gate::authorize()` |
| DL-06 | `Illuminate\Http\Request` | Laravel core | Must have `ajax()`, `filled()`, `input()` methods |
| DL-07 | `Carbon\Carbon` | nesbot/carbon | Date parsing via `parse()` and `format()` |
| DL-08 | `Illuminate\Pagination\LengthAwarePaginator` | Laravel core | Custom pagination via `paginateCollection()` |
| DL-09 | `Illuminate\Pagination\Paginator` | Laravel core | `resolveCurrentPage()` and `resolveCurrentPath()` |
| DL-10 | `Illuminate\Support\Collection` | Laravel core | `where()`, `whereNotNull()`, `whereNull()`, `count()`, `sum()`, `pluck()` |
| DL-11 | `Modules\Transport\Models\PickupPoint` | Model at `Modules/Transport` | `active()` scope, `name` attribute |
| DL-12 | `Modules\Transport\Models\Route` | Model at `Modules/Transport` | `active()` scope, `name`, `code`, `pickup_drop` attributes |
| DL-13 | `Modules\Transport\Models\Shift` | Model at `Modules/Transport` | `active()` scope, `name` attribute |
| DL-14 | `Modules\Transport\Models\Vehicle` | Model at `Modules/Transport` | `active()` scope |
| DL-15 | `Modules\Transport\Models\DriverHelper` | Model at `Modules/Transport` | `active()` scope, `role` attribute |
| DL-16 | `Modules\SchoolSetup\Models\SchoolClass` | Model at `Modules/SchoolSetup` | `active()` scope |
| DL-17 | `Modules\SchoolSetup\Models\Section` | Model at `Modules/SchoolSetup` | `name` attribute |
| DL-18 | `Modules\StudentProfile\Models\Student` | Model at `Modules/StudentProfile` | `first_name`, `last_name`, `sessions` relationship |
| DL-19 | `config/permissionslist.php` | Config file | Defines `tenant.student-transport-usage.viewAny` permission group |
| DL-20 | Hub view `transport::tab_module.transportreport` | Blade file | Contains tab nav and AJAX loading logic |
| DL-21 | Chart.js CDN at `cdn.jsdelivr.net/npm/chart.js` | External JS library | Required for bar/doughnut chart rendering |
| DL-22 | Moment.js CDN at `cdn.jsdelivr.net/npm/moment` | External JS library | Required by daterangepicker |
| DL-23 | Daterangepicker CDN at `cdn.jsdelivr.net/npm/daterangepicker` | External JS library | Date range picker UI component |
| DL-24 | jQuery (`$` global) | External JS library | Required for AJAX calls, DOM manipulation, event handling |
| DL-25 | Bootstrap 5 tab system (`data-bs-toggle="tab"`, `shown.bs.tab`) | External CSS/JS framework | Tab switch detection and pane management |
| DL-26 | `Modules/Transport/Http/Controllers/TransportReportController` | Controller | `buildUsageSection()` at line 113, `getTransportUsage()` at line 606 |
| DL-27 | `getFilterData()` method | Controller method | Returns routes, academicSessions, stops, classes for filter dropdowns |
| DL-28 | `parseDateRange()` method | Controller method | Parses `dates` string or defaults to current month |
| DL-29 | `paginateCollection()` method | Controller method | Creates LengthAwarePaginator with custom page name |
| DL-30 | `loadTabSection()` method | Controller method | Routes section requests to appropriate builder via `match()` |

---

## 8. Test Data Setup (TD)

### TD-01: Standard data — 15 students across 5 class sections with varied boarding logs



### TD-02: Boarding logs — varied scenarios across 22 working days in Feb 2026



### TD-03: Students with zero boarding logs (Kate id=11, Leo id=12)
- Both have `TptStudentAllocationJnt` records
- Zero rows in `tpt_student_boarding_log`
- Expected: total_boardings=0, total_unboardings=0, missed_boarding='YES'

### TD-04: Student with null class section (Mia id=13)
- `std_student_academic_sessions` record for Mia has `class_section_id = NULL`
- Expected: class_name='—', section_name='—'

### TD-05: Student with inactive pickup route (Noah id=14)
- `tpt_routes` entry for Route-3 has `is_active=0`
- Noah is allocated to Route-3 as pickup
- `optional($alloc->pickupRoute)->name` returns null
- Falls back to `optional($alloc->dropRoute)->name` which is Route-2 (active)
- Expected: route_name='Route-2 (Evening)' or '—' if both inactive

### TD-06: 12 students in class 10A — pagination boundary
- Students 1-3 already in class 10A (class_section_id=1)
- Add 9 more students in class 10A → total 12 students in 10A
- Paginated at 10/page via `page_usage`
- Page 1: 10 students, Page 2: 2 students

### TD-07: Previous month data only
- Insert boarding logs for January 2026 for students 1-5
- No logs for February 2026
- Default date range is February 2026
- Expected: empty dataset (0 students shown)

### TD-08: Student with very high boarding count (Olivia id=15)
- 45 boarding logs in February (more than working days — possible double trips)
- 43 unboarding logs
- 2 missed drops, 0 missed pickups
- Expected: total_boardings=45, total_unboardings=43, missed_boarding='NO', missed_drop='YES'
- Attendance rate: (45+43-2)/(45+43) = 97.7% → Status: Excellent

### TD-09: Route filter test data
- Route-1: Students 1,2,3,6,7,9,11 (7 students)
- Route-2: Students 4,5,8,10,15 (5 students)
- Route-3: Students 12,13,14 (3 students)
- Stop-A: Students 1,2,9,11,15 (5 students)
- Stop-B: Students 4,5,10,13 (4 students)
- Stop-C: Students 3,7,14 (3 students)
- Stop-D: Students 12,13,14 (3 students)

### TD-10: Class section filter test data
- 10A (class_section_id=1): Students 1,2,3 (3 students)
- 10B (class_section_id=2): Students 4,5 (2 students)
- 9A (class_section_id=3): Students 6,7,8 (3 students)
- 9B (class_section_id=4): Students 9,10,11 (3 students)
- 8A (class_section_id=5): Students 12,13,14,15 (4 students)

### TD-11: Permission roles test data
- User A: Assigned role "Transport Viewer" with `tenant.student-transport-usage.viewAny`
- User B: Assigned role "Transport Manager" with `tenant.transport.viewAny` and `tenant.student-transport-usage.viewAny`
- User C: No transport permissions
- User D: Guest (not logged in)

### TD-12: Edge case — student with 100% missed events
- Student has 5 boarding logs, all with NULL boarding_time AND NULL unboarding_time
- This means they never actually boarded or unboarded
- Expected: missed_boarding='YES', missed_drop='YES', attendance_rate=0% → Status: Poor

---

## 9. Validation Rules (VAL)

| VAL ID | Rule | Type | Implementation |
|--------|------|------|----------------|
| VAL-01 | `class_section_id` filter must reference a valid ID in `std_student_academic_sessions` | Input | Controller passes to `where()` — no explicit validation, DB FK would error |
| VAL-02 | `route_id` filter must reference a valid ID in `tpt_routes` | Input | Passed from blade dropdown — no server-side validation of existence |
| VAL-03 | `stop_id` filter must reference a valid ID in `tpt_pickup_points` | Input | Passed from blade dropdown — no server-side validation of existence |
| VAL-04 | [Query/Code Removed] | Input | [Query/Code Removed] |
| VAL-05 | `to_date` must be a valid date string parseable by Carbon | Input | [Query/Code Removed] |
| VAL-06 | `from_date` must not be after `to_date` | Input | Not validated — would produce empty results but no error |
| VAL-07 | Date range max span should not exceed 1 year (performance) | Input | Not enforced — large spans may cause performance issues |
| VAL-08 | `$session->student` must not be null | Data | Guarded by `optional($session->student)->first_name ?? '—'` |
| VAL-09 | `$session->classSection` must not be null | Data | Guarded by `optional($session->classSection?->class)->name ?? '—'` |
| VAL-10 | `$alloc` (transportAllocation) must not be null | Data | [Query/Code Removed] |
| VAL-11 | `$alloc->pickupRoute` and `$alloc->dropRoute` must not both be null | Data | Fallback chain: `?? $alloc->dropRoute->name ?? '—'` |
| VAL-12 | `$alloc->pickupStop` and `$alloc->dropStop` must not both be null | Data | Fallback chain: `?? $alloc->dropStop->name ?? '—'` |
| VAL-13 | `$logs` collection must never be null (even if empty) | Data | `$session->boardingLogs` returns empty Collection when no logs exist |
| VAL-14 | `paginateCollection` must receive a Collection, not null | Code | Builder returns ->get() which returns Collection even if empty |
| VAL-15 | Chart.js canvas element must exist before `new Chart()` | UI | Guarded by `if (usageCtx && studentNames.length > 0)` |
| VAL-16 | Daterangepicker must be initialized after DOM ready | UI | Wrapped in `$(document).ready()` |
| VAL-17 | AJAX error must not break page | UI | `.error()` handler replaces content with error alert |
| VAL-18 | Pagination links must preserve active tab | URL | `->appends(request()->query())->links()` in blade |
| VAL-19 | Tab switch must not reload already-loaded tabs | UX | `container.hasClass('loaded')` check before AJAX call |
| VAL-20 | Multiple rapid filter submissions must not race | UX | No debounce — last AJAX response overwrites previous |
| VAL-21 | `whereNotNull('boarding_time')->count()` counts only logs with a non-null boarding time | Data | Eloquent collection method — correct if logs are loaded |
| VAL-22 | `whereNull('boarding_time')->count() > 0` converts count to boolean for YES/NO | Logic | Returns YES if at least one log has missing boarding time |
| VAL-23 | `total_boardings` and `total_unboardings` are independent counts | Logic | A log can have boarding_time set but unboarding_time null (or vice versa) |
| VAL-24 | Status badge color logic: `$attendanceRate >= 90` → success, `>= 75` → warning, `>= 60` → info, else danger | Display | Computed per row in blade `@php` block |
| VAL-25 | Chart top-10 uses `studentNames.slice(0, 10)` and companion arrays must align | Display | `boardingData.slice(0, 10)` and `unboardingData.slice(0, 10)` ensure same length |

---

## 10. Authorization Rules (AUTH)

| AUTH ID | Rule | Check | Expected |
|---------|------|-------|----------|
| AUTH-01 | Index page requires `tenant.transport.viewAny` | `Gate::authorize('tenant.transport.viewAny')` at line 36 | Pass: user has permission. Fail: 403 |
| AUTH-02 | Tab visibility requires `tenant.student-transport-usage.viewAny` | `permission` key in nav-tab tabs array line 11 of hub view | Tab button hidden if permission missing |
| AUTH-03 | Tab content requires `tenant.student-transport-usage.viewAny` | `@can('tenant.student-transport-usage.viewAny')` at line 26 of hub view | `@include` not rendered if permission missing |
| AUTH-04 | AJAX section load requires `tenant.transport.viewAny` + tab permission | Controller `index()` runs `Gate::authorize('tenant.transport.viewAny')` before `loadTabSection()` | AJAX fails with 403 if permission missing |
| AUTH-05 | Super admin bypasses all permission checks | `Gate::before()` in `AppServiceProvider` checks `is_super_admin` | Super admin always passes |
| AUTH-06 | Guest user redirected to login | Laravel auth middleware | 302 redirect to `/login` |
| AUTH-07 | Permission string must match `permissionslist.php` exactly | Config file defines `tenant.student-transport-usage.viewAny` | Mismatch would allow unauthorized access (gate always passes if permission not defined) |
| AUTH-08 | Direct URL access without permission returns 403 | `Gate::authorize()` throws `AuthorizationException` | 403 Forbidden view |
| AUTH-09 | Multiple permission check on tab load — both hub permission AND tab permission required | `tenant.transport.viewAny` (hub controller) + `tenant.student-transport-usage.viewAny` (blade) | Both must pass |
| AUTH-10 | `Gate::any()` not used; individual `Gate::authorize()` per action | Line 36 is singular, not array | Each tab must have its own authorize call |

---

## 11. Business Logic Deep-Dive (BIZ-DEEP)

### BIZ-DEEP-01: Student Name Resolution Chain


Impact: If the `student` relationship is not eager-loaded, N+1 queries occur.
The `getTransportUsage()` does NOT call `->with('student')` before `->get()`.
This means `$session->student` triggers a lazy-load query for EVERY session in the result set.
For 15 students, this adds 15 additional queries to page load.

### BIZ-DEEP-02: Route Name Resolution Chain


Impact: If a student is allocated only for pickup (no drop route), the dropRoute is null,
so the fallback correctly uses pickupRoute. If both pickup and drop routes exist,
ONLY the pickup route name is displayed (drop never checked). This means students
with different pickup and drop routes will only show the pickup route name.

### BIZ-DEEP-03: Stop Name Resolution Chain


Impact: Same asymmetry as route name. Only pickup stop is displayed if both exist.

### BIZ-DEEP-04: Missed Detection Logic


Impact:
- If a student has 22 logs and 1 has NULL boarding_time → missed_boarding = 'YES'
- This means even 1 missed event out of 22 flags the entire student as having "missed"
- There is no severity threshold — it's binary YES/NO at the student level
- The chart aggregation sums these binary flags, so chart data represents "number of students who experienced at least one missed event" not "total missed event count"

### BIZ-DEEP-05: Status Calculation Logic


Impact:
- `$missedEvents` is always 0, 1, or 2 (not the actual count of missed events)
- Two students with very different missed patterns can have the same status:
  - Student A: 100 boardings, 1 missed drop → missed=1, rate=(200-1)/200=99.5% → Excellent
  - Student B: 1 boarding, 1 missed drop → missed=1, rate=(2-1)/2=50% → Poor
  - Both show missed_drop=YES, but the severity is very different
- The `? : 100` default when `$totalEvents = 0` means a student with zero boardings gets "Excellent" status — this is a logic bug (a student with no transport usage at all should not be "Excellent")

### BIZ-DEEP-06: Attendance Rate Edge Cases

Case: total_boardings=5, total_unboardings=5, missed_boarding=NO, missed_drop=NO
- totalEvents=10, missedEvents=0, rate=100% → Excellent

Case: total_boardings=0, total_unboardings=0, missed_boarding=YES, missed_drop=YES
- totalEvents=0, missedEvents=2, rate=(0/0=undefined) → defaults to 100 → Excellent
- BUG: Student with zero events gets "Excellent" when they should be "Poor" or "No Data"

Case: total_boardings=1, total_unboardings=0, missed_boarding=NO, missed_drop=YES
- totalEvents=1, missedEvents=1, rate=(1-1)/1*100=0% → Poor

### BIZ-DEEP-07: Pagination Design


The `paginateCollection` method:

Impact:
- Uses custom page name `page_usage` to avoid conflicts with other tabs
- Pagination operates on an in-memory Collection, NOT a database query
- For large datasets (1000+ students), ALL records are loaded into memory before pagination
- This is a performance bottleneck — should use database-level `->paginate()` instead

### BIZ-DEEP-08: Chart Data Extraction in Blade


Impact:
- The "top 10" is simply the first 10 students from the collection
- There is NO sorting by boardings/unboardings count
- The "Student Usage Chart" labeled as showing "top 10" is misleading — it actually shows the first 10 students (as returned from the database, typically by `StudentAcademicSession.id` order since no `->orderBy()` is applied before `->get()`)
- To truly show "top 10", the collection should be sorted by `total_boardings` descending before slicing

### BIZ-DEEP-09: FilterAsymmetricBehavior

Filters in `getTransportUsage()`:

Impact:
- `route_id` and `stop_id` filters are NOT applied at the query level
- They are missing from the `getTransportUsage()` filter chain entirely
- If a user selects a route filter in the UI, the controller receives `route_id` in `$reqFilters` but `getTransportUsage()` ignores it
- This means the UI dropdown for route and stop are decorative — they don't actually filter the data
- The blade sends `route_id` and `stop_id` in the form, but the backend never uses them

### BIZ-DEEP-10: whereHas N+1 Performance


Impact:
- `->get()` fetches ALL matching `StudentAcademicSession` records
- Inside `->map()`, the following lazy-loaded relationships are accessed:
  - `$session->student` (if not loaded) → extra query
  - `$session->classSection->class` → extra query
  - `$session->classSection->section` → extra query
  - `$session->transportAllocation->pickupRoute` → extra query
  - `$session->transportAllocation->dropRoute` → extra query
  - `$session->transportAllocation->pickupStop` → extra query
  - `$session->transportAllocation->dropStop` → extra query
  - `$session->boardingLogs` → extra query
- Total queries: 1 (base) + 1 (whereHas) + 1 (get, triggers transportAllocation if loaded) + N*8 lazy queries
- For 15 students: ~17 queries. For 100 students: ~102 queries
- Fix: Add `->with('student', 'classSection.class', 'classSection.section', 'transportAllocation.pickupRoute', 'transportAllocation.dropRoute', 'transportAllocation.pickupStop', 'transportAllocation.dropStop', 'boardingLogs')` before `->get()`

### BIZ-DEEP-11: Binary Missed Flag vs Aggregate Count Mismatch

The summary card shows "Missed Events" as `$missedPickup + $missedDrop` which is a COUNT OF STUDENTS (binary), not a count of missed events.
- If Student A has 5 missed pickups, and Student B has 1 missed pickup:
  - Summary "Missed Events" = 2 (binary YES count, not 6 total missed events)
  - Missed doughnut chart: Missed Pickups = 2 (number of students with at least one missed pickup, not total missed pickups)
- The doughnut chart is labeled "Missed Events Analysis" but actually shows "Students with at least one missed pickup vs Students with at least one missed drop"

### BIZ-DEEP-12: Class Grouping in Blade Chart


Impact: Class chart also uses binary YES/NO per student rather than summing actual missed event counts.
A class with 10 students each having 1 missed pickup shows the same chart height as a class
with 10 students each having 10 missed pickups.

### BIZ-DEEP-13: Summary Card Aggregation Source


Impact:
- `$totalBoardings` is sum of ALL boardings across ALL students (correct aggregate)
- `$totalUnboardings` is sum of ALL unboardings across ALL students (correct aggregate)
- But `$missedPickup` is count of STUDENTS with at least one missed boarding (binary)
- The Total Boardings and Total Unboardings are the only truly aggregate values in the summary
- `$totalStudents` is simply the number of items in the collection (after all filters)

### BIZ-DEEP-14: Multiple Tab Pagination Isolation

Each tab uses a unique page name:
- route-performance: `page_route`
- student-transport-usage: `page_usage`
- stop-analysis: `page_stop`
- trip-execution: `page_trip`
- driver-performance: `page_driver`
- etc.

This prevents pagination page number collision between tabs. Without this,
clicking page 2 on one tab would be interpreted as page 2 on the other tab
(both default to `page` query parameter).

### BIZ-DEEP-15: AJAX Load Race Condition

The hub view's `loadTabSection()` function:

There is no abort mechanism for in-flight AJAX requests. If a user:
1. Applies filter A (triggers AJAX)
2. Immediately applies filter B (triggers AJAX)
3. Response for filter A arrives last → overwrites filter B results
This is a race condition. Fix: assign the $.ajax return value to a variable
and call `.abort()` before the next request.

### BIZ-DEEP-16: Skeleton Loader vs Actual Content

The initial page HTML contains:

This spinner is replaced when `loadTabSection('student-transport-usage', 'charts')` completes.
If the AJAX request fails, the `.error()` handler replaces it with:

The success handler uses `container.html(res.html)` which replaces ALL content.
This is correct for the spinner → charts transition.

### BIZ-DEEP-17: Date Range Default Behavior


If the user navigates to the page on February 15, 2026:
- Default range: 2026-02-01 to 2026-02-28
- Boarding logs outside this range are excluded
- The daterangepicker UI shows this range
- User can change to "Last 7 Days", "Last Month", or custom range

### BIZ-DEEP-18: Academic Session Filter Delegate

The blade uses `$filters['academicSessions']` to populate the class section dropdown:

This is peculiar — the dropdown is labeled "Class/Section" but the options come from
`StudentAcademicSession::distinct('academic_session_id')`. The value is `class_section_id`
but the source query returns distinct `academic_session_id`. This could return
duplicate class_section_ids if one class section has multiple academic sessions.
The query intention seems to be: "get distinct class_section_id values from
StudentAcademicSession" but the `distinct('academic_session_id')` call applies
DISTINCT on the wrong column.

### BIZ-DEEP-19: Missing Eager Loading for Chart Data

The chart data extraction loops through `$usageReports` in the blade @php block:

This is fine because `getTransportUsage()` already mapped the data to objects
with `class_name` and `section_name` as plain string properties. No additional
database queries occur during chart data extraction.

### BIZ-DEEP-20: Pass-by-Reference Collection Mutation Risk


The `request()->merge(...)` call modifies the global Request object. Since this
is a private method called during AJAX handling, it could interfere with other
concurrent requests in the same process (though Laravel typically handles one
request per process).

---

## 12. Test Case List

### 12.1 Positive Test Cases (P)

| TC ID | Description | Prerequisites | Test Steps | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|---------------|------------|-----------------|---------|---------|--------|
| TC-P01 | Tab loads with filter bar and skeleton loaders | PC-01 (standard data) | 1. Navigate to `/transport-report?active_tab=student-transport-usage`<br>2. Wait for page to load | Filter bar with Date, Class, Route, Stop dropdowns + skeleton for charts/table | — | — | ⬜ |
| TC-P02 | Summary cards display correct aggregates | PC-01 (standard data), TD-02 (boarding logs) | 1. Load tab with default date range (Feb 2026)<br>2. Inspect 4 summary cards | Total Students = 15, Total Boardings = sum of all boarding_time logs, Total Unboardings = sum of all unboarding_time logs, Missed Events count shown | — | — | ⬜ |
| TC-P03 | Charts render with correct data | PC-01, TD-02 | 1. Load tab<br>2. Check 3 charts render<br>3. Verify Student Usage chart shows top 10 bars<br>4. Verify Missed Events doughnut shows 2 segments<br>5. Verify Class Analysis bar chart shows 5 class groups | Charts render without JS errors; bar chart shows boardings (green) + unboardings (blue); doughnut shows red + yellow segments | — | — | ⬜ |
| TC-P04 | Table shows per-student rows with all columns | PC-01, TD-02 | 1. Load tab<br>2. Inspect table | 9 columns: Student, Class, Route, Stop, Boarded, Unboarded, Missed Pickup, Missed Drop, Status; each row has badge colors matching status | — | — | ⬜ |
| TC-P05 | Filter by class section | PC-06 (12 students in 10A), TD-10 | 1. Select "10 A" from class dropdown<br>2. Submit filter | Only 3 (or 12 if expanded) students from 10A shown; All other classes excluded | — | — | ⬜ |
| TC-P06 | Filter by route | PC-01, TD-09 | 1. Select "Route-1" from route dropdown<br>2. Submit filter | Only students allocated to Route-1 (pickup or drop) shown | — | — | ⬜ |
| TC-P07 | Filter by stop | PC-01, TD-09 | 1. Select "Stop-A" from stop dropdown<br>2. Submit filter | Only students with Stop-A as pickup or drop stop shown | — | — | ⬜ |
| TC-P08 | Filter by date range (explicit) | PC-07 (Jan + Feb data) | 1. Set date range to January 1-31 2026<br>2. Submit filter | Only January logs counted; Feb logs excluded | — | — | ⬜ |
| TC-P09 | Filter by date range (last 7 days) | PC-07 | 1. Click daterangepicker<br>2. Select "Last 7 Days"<br>3. Submit filter | Only logs from last 7 days shown | — | — | ⬜ |
| TC-P10 | Pagination works across 2 pages | PC-06 (12 students in 10A) | 1. Filter by 10A class<br>2. Navigate to page 2 | Page 1 shows 10 students, Page 2 shows 2 students; URL contains `page_usage=2` | — | — | ⬜ |
| TC-P11 | Student with zero boarding logs appears correctly | PC-02, TD-03 | 1. Load tab with no filters<br>2. Find Kate and Leo rows | Kate and Leo appear in table; Boarded=0, Unboarded=0, Missed Pickup=YES, Status=Excellent (due to BIZ-DEEP-05 bug) | — | — | ⬜ |
| TC-P12 | Student with partial logs (missed drop) shows correctly | PC-03, TD-02 (Bob) | 1. Load tab<br>2. Find Bob's row | Bob: Missed Drop=YES badge (danger), Missed Pickup=NO badge (success) | — | — | ⬜ |
| TC-P13 | Student with null class section shows fallback | PC-08, TD-04 (Mia) | 1. Load tab<br>2. Find Mia's row | Class column shows '—' | — | — | ⬜ |
| TC-P14 | Class-wise chart groups correctly | PC-01, TD-10 | 1. Load tab<br>2. Inspect class chart tooltips | 5 class groups; each bar aggregates boardings/unboardings/missed for that class | — | — | ⬜ |
| TC-P15 | Doughnut chart shows percentage tooltips | PC-01, TD-02 | 1. Hover over doughnut segments | Tooltip shows: "Missed Pickups: X (Y%)" and "Missed Drops: A (B%)" | — | — | ⬜ |
| TC-P16 | Student with high boarding count shows Excellent status | PC-10, TD-08 (Olivia) | 1. Load tab<br>2. Find Olivia's row | Status badge = "Excellent" (green); Boarded=45, Unboarded=43 | — | — | ⬜ |
| TC-P17 | Clear filter resets to defaults | PC-01 | 1. Apply class=10A, route=Route-1<br>2. Click reset button (redo icon) | All filters reset to "All"; full dataset loaded | — | — | ⬜ |
| TC-P18 | Charts resize on window resize | PC-01 | 1. Load tab with charts<br>2. Resize browser window<br>3. Inspect chart dimensions | Charts maintain aspect ratio and resize proportionally | — | — | ⬜ |
| TC-P19 | Tab switch to student-transport-usage triggers AJAX load | PC-01 | 1. Land on route-performance tab<br>2. Click "St.Transport Usage" tab<br>3. Observe AJAX requests | Tab loads dynamically; charts and table sections render | — | — | ⬜ |
| TC-P20 | Super admin sees all data without specific permission | PC-01, TD-11 (User D super admin) | 1. Log in as super admin<br>2. Navigate to transport report<br>3. Click St.Transport Usage tab | All data accessible; no 403 errors | — | — | ⬜ |

### 12.2 Negative Test Cases (N)

| TC ID | Description | Prerequisites | Test Steps | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|---------------|------------|-----------------|---------|---------|--------|
| TC-N01 | No students with transport allocation | Empty database or no TptStudentAllocationJnt records | 1. Load tab | Table shows "No transport usage found for selected filters"; summary cards show 0; charts render "No data available" | — | — | ⬜ |
| TC-N02 | No data in selected date range | PC-07 (Jan data only), TD-07 | 1. Set date range to March 2026 (no data)<br>2. Submit filter | Empty table; summary cards show 0; charts render "No data available" / "No missed events" | — | — | ⬜ |
| TC-N03 | Non-existent class_section_id | PC-01 | 1. Manually set `class_section_id=9999` in URL<br>2. Load page | Empty results (no matching sessions); table shows empty state | — | — | ⬜ |
| TC-N04 | 403 without permission `tenant.student-transport-usage.viewAny` | TD-11 (User C — no transport permissions) | 1. Log in as User C<br>2. Navigate to transport report | Tab "St.Transport Usage" not visible in nav; `@can` prevents includes; cannot see tab content | — | — | ⬜ |
| TC-N05 | Guest access (not logged in) | TD-11 (User D guest) | 1. Clear session<br>2. Navigate to `/transport-report` | Redirected to `/login` | — | — | ⬜ |
| TC-N06 | Missing `from_date` parameter | PC-01 | 1. Set `to_date=2026-02-28` without `from_date`<br>2. Submit filter | System defaults `startDate` to current month start; may error if Carbon parses empty string | — | — | ⬜ |
| TC-N07 | Invalid `from_date` format | PC-01 | 1. Set `from_date=not-a-date`<br>2. Submit filter | [Query/Code Removed] | — | — | ⬜ |
| TC-N08 | `to_date` before `from_date` | PC-01 | 1. Set `from_date=2026-02-28`<br>2. Set `to_date=2026-02-01`<br>3. Submit filter | No error; empty results (logs between Feb 1 and Feb 28, but reversed range logic isn't checked) | — | — | ⬜ |
| TC-N09 | Student with 100% missed events | TD-12 (all NULL logs) | 1. Create test student with all NULL boarding/unboarding<br>2. Load tab | Student appears; Missed Pickup=YES, Missed Drop=YES; Status=Poor (attendance=0%) | — | — | ⬜ |
| TC-N10 | All students have zero boarding logs | PC-02 (no logs at all) | 1. Delete all StudentBoardingLog records<br>2. Load tab | Table shows all allocated students; Boarded=0, Unboarded=0, Missed Pickup=YES; charts show "No data available" | — | — | ⬜ |
| TC-N11 | Broken Chart.js CDN | PC-01 | 1. Block CDN `cdn.jsdelivr.net` in browser/devtools<br>2. Load tab | Charts section shows no charts (canvas elements exist but `Chart` is undefined); JS error in console; page does not crash | — | — | ⬜ |
| TC-N12 | AJAX request returns 500 | PC-01 | 1. Force a server error (e.g., DB connection drop)<br>2. Load tab section | `.error()` handler shows "Failed to load charts/table" alert message; page remains usable | — | — | ⬜ |
| TC-N13 | Rapid filter submission (race condition) | PC-01 | 1. Rapidly change class filter 3 times within 1 second<br>2. Observe final result | Last AJAX response renders; race condition may show stale data from previous response | — | — | ⬜ |
| TC-N14 | Memory limit exceeded with 10000 students | Generate 10000 StudentAcademicSession + allocation records | 1. Load tab without filters | `getTransportUsage()` loads ALL 10000 records into memory via `->get()`; may exceed PHP memory limit (128MB default) → 500 error or blank page | — | — | ⬜ |
| TC-N15 | Invalid `page_usage` parameter | PC-06 (12 students) | 1. Set `page_usage=-1` in URL<br>2. Load tab | Paginator resolves page -1 → slice returns empty collection; no results shown | — | — | ⬜ |
| TC-N16 | `page_usage` exceeds max pages | PC-06 (12 students = 2 pages) | 1. Set `page_usage=100` in URL<br>2. Load tab | Paginator returns empty slice; no results shown; no error | — | — | ⬜ |
| TC-N17 | Delete session while page is open | PC-01 | 1. Open tab<br>2. In another window, delete one student's `StdStudentAcademicSession`<br>3. Refresh filter | Session no longer appears; data is freshly loaded from DB | — | — | ⬜ |
| TC-N18 | Special characters in student/route names | Student name contains `<script>alert('xss')</script>` | 1. Inject XSS name into database<br>2. Load tab | Blade auto-escapes `{{ }}` → rendered as text, not executed | — | — | ⬜ |
| TC-N19 | `class_section_id` filter returns no results (valid ID, no allocations) | Create class_section_id=6 with no students | 1. Set `class_section_id=6` via URL<br>2. Load tab | Table shows "No transport usage found for selected filters"; charts use No-op path | — | — | ⬜ |
| TC-N20 | Concurrent identical filter submissions | PC-01 | 1. Open 2 browser tabs with same URL<br>2. Apply same filter in both<br>3. Submit both simultaneously | Both return identical data; no state corruption | — | — | ⬜ |

### 12.3 Destructive Test Cases (D)

| TC ID | Description | Recovery Method | Test Steps | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|-----------------|------------|-----------------|---------|---------|--------|
| TC-D01 | Drop `tpt_student_boarding_log` table while page is open | Re-create table from migration | 1. Open tab (data loads)<br>2. Drop table in DB<br>3. Refresh/refilter | AJAX returns 500 or error; `.error()` shows alert; page partial remains as last good state | — | — | ⬜ |
| TC-D02 | Delete all `TptStudentAllocationJnt` records | Re-insert from seed | 1. Open tab<br>2. Delete all allocations<br>3. Refresh | 0 students shown; empty table; charts show "No data available" | — | — | ⬜ |
| TC-D03 | Set all routes to inactive | Update `is_active=0` for all tpt_routes | 1. Open tab<br>2. Deactivate all routes<br>3. Refresh | `optional($alloc->pickupRoute)->name` returns null for all → route_name falls back to '—' or dropRoute (also null) → all show '—' | — | — | ⬜ |
| TC-D04 | Set all stops to inactive | Update `is_active=0` for tpt_pickup_points | 1. Open tab<br>2. Deactivate all stops<br>3. Refresh | stop_name falls back to '—' for all rows | — | — | ⬜ |
| TC-D05 | Truncate `std_student_academic_sessions` | Re-insert from seed | 1. Open tab<br>2. Truncate table<br>3. Refresh | [Query/Code Removed] | — | — | ⬜ |
| TC-D06 | Delete the Blade view file | Restore from VCS | 1. Delete `student-transport-usage/index.blade.php`<br>2. Load tab | 500 error: "View [transport::report.student-transport-usage.index] not found" | — | — | ⬜ |
| TC-D07 | Corrupt Chart.js data (null labels) | Refresh page | 1. Modify controller to return null student_names<br>2. Load tab | Chart.js `labels: null` throws JS error; remaining charts may still render | — | — | ⬜ |
| TC-D08 | Remove `tenant.student-transport-usage.viewAny` from permissionslist.php | Re-add from VCS | 1. Remove permission from config<br>2. Load page | `Gate::authorize()` may still pass if permission is not checked (undefined permissions return false); blade `@can` may always return false | — | — | ⬜ |
| TC-D09 | Override `permissionslist.php` with empty array | Restore from VCS | 1. Empty permissions array<br>2. Clear config cache<br>3. Load page | `Gate::authorize('tenant.student-transport-usage.viewAny')` throws `InvalidArgumentException` if permission not defined in gate | — | — | ⬜ |
| TC-D10 | Change permission string in blade but not controller | Sync both files | 1. Rename `@can('tenant.student-transport-usage.viewAny')` to `@can('tenant.student-transport-usage.access')` in blade<br>2. Load page | Blade check fails → tab content hidden; controller still checks old permission → URL access gives 403 if mismatched | — | — | ⬜ |
| TC-D11 | Set PHP memory_limit to 2MB | Reset in php.ini | 1. Lower memory limit<br>2. Load tab with large dataset | Fatal error: Allowed memory size exhausted | — | — | ⬜ |
| TC-D12 | Set `max_execution_time` to 1 second | Reset in php.ini | 1. Lower max execution time<br>2. Load tab with large dataset | Maximum execution time exceeded fatal error | — | — | ⬜ |
| TC-D13 | Change `page_usage` to `page` globally | Revert pagination change | 1. Modify `paginateCollection` call to use `'page'` instead of `'page_usage'`<br>2. Open 2 tabs with different data | Pagination on one tab affects the other tab's page number | — | — | ⬜ |
| TC-D14 | Delete `optional()` helper function globally | Restore helper | 1. Remove or override `optional()`<br>2. Load tab with null student names | Fatal error: Call to a member function on null for `$session->student->first_name` | — | — | ⬜ |
| TC-D15 | Set all `boarding_time` and `unboarding_time` to same timestamp | Re-insert test data | 1. Update all boarding logs: both times = same timestamp<br>2. Load tab | Counts unaffected; all events counted; missed_boarding='NO', missed_drop='NO' | — | — | ⬜ |
| TC-D16 | Delete `config/permissionslist.php` file | Restore from VCS | 1. Delete config file<br>2. Clear config cache<br>3. Load page | 500 error on config access if other code depends on it; gate checks for undefined permission | — | — | ⬜ |
| TC-D17 | Set `academic_session_id` in filter to non-existent value | None needed | 1. Set `academic_session_id=999`<br>2. Submit filter | No records; empty table | — | — | ⬜ |
| TC-D18 | Inject HTML in `route_name` through DB | Sanitize DB field | 1. Set route name to `<marquee>HACKED</marquee>`<br>2. Load tab | Blade `{{ }}` escapes HTML → renders as text `&lt;marquee&gt;HACKED&lt;/marquee&gt;` | — | — | ⬜ |
| TC-D19 | Rename `getTransportUsage` method | Restore method | 1. Rename to `getTransportUsageData`<br>2. Load tab | `Call to undefined method` error; 500 response | — | — | ⬜ |
| TC-D20 | Force AJAX response as string instead of JSON | Fix controller | 1. Make controller return raw string instead of JSON<br>2. Load tab | `res.html` is undefined; `.success()` handler tries to render undefined → blank sections | — | — | ⬜ |

### 12.4 Code Review Test Cases (CR)

| TC ID | Priority | File | Line(s) | Description | Expected Result | Status |
|-------|----------|------|---------|-------------|-----------------|--------|
| TC-CR01 | P1 | TransportReportController.php | 608-610 | [Query/Code Removed] | Query correctly excludes sessions without allocation | ◌ |
| TC-CR02 | P1 | TransportReportController.php | 617-621 | Null-safe `optional()` on student/route/stop names | No "Call to member function on null" errors | ◌ |
| TC-CR03 | P1 | TransportReportController.php | 624-625 | Missed detection uses `count() > 0` boolean conversion | Correct YES/NO strings produced | ◌ |
| TC-CR04 | P1 | index.blade.php | 240 | Chart top-10 slice prevents overcrowding | Only 10 bars shown in student usage chart | ◌ |
| TC-CR05 | P1 | index.blade.php | 9-14 | Blade `??` defaults for empty collections | No undefined variable errors when collection is empty | ◌ |
| TC-CR06 | P1 | TransportReportController.php | 117 | Pagination uses `page_usage` as pageName | No pagination conflict with other tabs in hub | ◌ |
| TC-CR07 | P2 | TransportReportController.php | 606-628 | Missing `->with()` for eager loading | N+1 queries occur; ~8 extra queries per student | ◌ |
| TC-CR08 | P2 | TransportReportController.php | 606-628 | `route_id` and `stop_id` filters not applied | UI route/stop dropdowns are decorative only; no actual filter | ◌ |
| TC-CR09 | P2 | TransportReportController.php | 616 | `$alloc = $session->transportAllocation` — no null check | Guarded by `whereHas` but if relationship changes, could be null | ◌ |
| TC-CR10 | P2 | TransportReportController.php | 606 | No `->orderBy()` on base query | Results order is unpredictable; may differ between page loads | ◌ |
| TC-CR11 | P2 | index.blade.php | 156-166 | Chart data prepared via `->map()->toArray()` then `@json()` | Double serialization; `@json($usageData)` would suffice | ◌ |
| TC-CR12 | P2 | index.blade.php | 180-195 | Chart class grouping uses string concatenation for group key | Class name "10 A" may collide with different section label formats | ◌ |
| TC-CR13 | P2 | index.blade.php | 390-407 | Status calculation uses binary missed flag (0/1/2) not actual count | Missed event severity undercounted; BIZ-DEEP-05 bug | ◌ |
| TC-CR14 | P2 | index.blade.php | 392 | Zero-event student gets 100% attendance | `$totalEvents > 0` guard prevents division by zero but defaults to 100 (Excellent); BIZ-DEEP-06 bug | ◌ |
| TC-CR15 | P2 | index.blade.php | 240 | "Top 10" is actually first 10 (no sorting) | No `sortByDesc('total_boardings')` before slicing; chart is misleading | ◌ |
| TC-CR16 | P2 | index.blade.php | 220-230 | `renderNoDataMessage()` draws on canvas context | If canvas is not visible (hidden tab), dimensions may be 0x0 → no message visible | ◌ |
| TC-CR17 | P2 | TransportReportController.php | 350-351 | `$filters['academicSessions']` uses `distinct('academic_session_id')` but value is `class_section_id` | May produce wrong distinct values; dropdown options may have duplicates | ◌ |
| TC-CR18 | P2 | tab_module/transportreport.blade.php | 146-200 | `loadTabSection()` has no abort mechanism for in-flight AJAX | Race condition: rapid filter changes may show stale results | ◌ |
| TC-CR19 | P2 | tab_module/transportreport.blade.php | 97-101 | Daterangepicker callback submits form on change | Every date picker change triggers full filter reload (2 AJAX calls) | ◌ |
| TC-CR20 | P2 | TransportReportController.php | 117 | `$usageReports` Collection fully loaded into memory before pagination | Large datasets (10000+) exhaust PHP memory; should use DB pagination | ◌ |
| TC-CR21 | P3 | index.blade.php | 1, 361, 465 | View uses `@if(request('section') === 'charts')` / `@elseif(request('section') === 'table')` / `@else` | Works correctly but the `@else` (initial load) is the same file rendered via controller | ◌ |
| TC-CR22 | P3 | TransportReportController.php | 115 | `request()->merge(['section' => $section])` mutates global Request | Side effect: if any code after this checks `request('section')`, it gets the merged value | ◌ |
| TC-CR23 | P3 | index.blade.php | 487-496 | Class dropdown uses `$filters['academicSessions']` | The dropdown label shows "All Classes" but loops over sessions — may show duplicates | ◌ |
| TC-CR24 | P3 | index.blade.php | 353-357 | `window.addEventListener('resize', ...)` calls `chart.resize()` | Handles responsive resizing but may trigger many resize events (no debounce) | ◌ |
| TC-CR25 | P3 | hub view (transportreport.blade.php) | 26-28 | `@can('tenant.student-transport-usage.viewAny')` in hub | Double security: tab nav AND include both guarded | ◌ |
| TC-CR26 | P3 | TransportReportController.php | 36 | `Gate::authorize('tenant.transport.viewAny')` at top of `index()` | User must have transport hub access first, then tab-specific permission | ◌ |
| TC-CR27 | P3 | TransportReportController.php | 117 | `return view(...)->render()` returns HTML string for AJAX | Correct for JSON response with `html` key | ◌ |
| TC-CR28 | P3 | index.blade.php | 462 | `$usageReportsPaginated->appends(request()->query())->links()` | Preserves all query parameters including active_tab and filters across pagination | ◌ |
| TC-CR29 | P3 | TransportReportController.php | 262-273 | `paginateCollection()` is generic | Reusable across all tabs with different page names | ◌ |
| TC-CR30 | P3 | index.blade.php | 111-113 | Chart.js canvas has fixed `height: 300px` via inline style | Consistent chart height across all resolutions | ◌ |

---

## 13. CODE-TRACE

### 13.1 Request Lifecycle

**Step 1: Page Load** (GET `/transport-report?active_tab=student-transport-usage`)



**Step 2: Hub View Renders** (transportreport.blade.php)



**Step 3: AJAX Charts Load** (GET `/transport-report?active_tab=student-transport-usage&section=charts`)



**Step 4: buildUsageSection('charts')** (TransportReportController.php:113)



**Step 5: Charts View Renders** (index.blade.php `@if(section === 'charts')`)



**Step 6: AJAX Table Load** (GET `/transport-report?active_tab=student-transport-usage&section=table`)

Same flow as Step 3-4 but with `section=table`:



**Step 7: Table View Renders** (index.blade.php `@elseif(section === 'table')`)



### 13.2 Permission Check Chain



### 13.3 Data Flow Diagram



---

## 14. Filter Behavior Matrix

| Filter | Controller Gets | getTransportUsage Applies | Effective? |
|--------|----------------|--------------------------|------------|
| `academic_session_id` | Yes (`$reqFilters`) | Yes (`->when(...)`) | ✅ Yes |
| `class_section_id` | Yes (`$reqFilters`) | Yes (`->when(...)`) | ✅ Yes |
| `route_id` | Yes (`$reqFilters`) | **No** (not in query chain) | ❌ No — decorative |
| `stop_id` | Yes (`$reqFilters`) | **No** (not in query chain) | ❌ No — decorative |
| `from_date` | Via `parseDateRange()` | **No** (not applied to query) | ❌ No — date range affects nothing in getTransportUsage directly (logs are lazy-loaded without date filter) |
| `to_date` | Via `parseDateRange()` | **No** (not applied to query) | ❌ No — same as from_date |

**Note:** The date range filters `startDate` and `endDate` are passed to `getTransportUsage()` but never used inside the method. Boarding logs are loaded via `$session->boardingLogs` (all of them, without date filtering). This means changing the date range has NO effect on the data — the same full set of logs is loaded regardless of the selected dates.

---

## 15. Performance Analysis

| Aspect | Current Implementation | Recommendation |
|--------|----------------------|----------------|
| Query count (15 students) | ~17 queries (1 base + 16 lazy loads) | Add `->with(['student', 'classSection.class', 'classSection.section', 'transportAllocation.pickupRoute', 'transportAllocation.dropRoute', 'transportAllocation.pickupStop', 'transportAllocation.dropStop', 'boardingLogs'])` → 3-4 queries total |
| Query count (100 students) | ~102 queries | Same fix as above → 3-4 queries total |
| Memory (100 students) | ~1-2 MB (acceptable) | No issue |
| Memory (10000 students) | ~100-200 MB (exceeds 128MB default) | Add database pagination with `->paginate()` instead of `->get()` + Collection pagination |
| Page load time (small data) | ~500ms-1s (2 AJAX calls) | No issue |
| Page load time (large data) | ~5-10s+ (all data in memory) | Implement server-side pagination + lazy chart loading |
| AJAX call redundancy | `getTransportUsage()` runs twice (charts + table) | Cache the Collection between the 2 calls within same request |
| Chart.js render time (small) | ~100ms | No issue |
| Chart.js render time (10000) | ~2-3s (DOM manipulation for labels) | Paginate chart data to max 50 students |

---

## 16. Test Steps for QA

### 16.1 Smoke Test

1. Navigate to `/transport-report`
2. Verify page loads without 500 errors
3. Click "St.Transport Usage" tab
4. Verify 4 summary cards appear with non-zero values
5. Verify 3 charts render (bar, doughnut, bar)
6. Verify table shows rows with student data
7. Verify pagination works (if >10 students)
8. Apply a class filter → verify results narrow
9. Change date range → verify data changes
10. Clear all filters → verify full dataset returns

### 16.2 Regression Test

1. Switch between all 10 tabs in the transport report hub → each tab must load without affecting others
2. Verify pagination on one tab does not change page on another tab
3. Submit filters rapidly → no JS console errors
4. Resize browser → charts resize smoothly
5. Test with mobile viewport (responsive)
6. Verify permission check: user without `tenant.student-transport-usage.viewAny` does not see tab

### 16.3 Data Integrity Test

2. Compare with `$totalStudents` value in the UI → must match
3. Manually sum `boarding_time` NOT NULL per student → compare with Boarded column
4. Manually sum `unboarding_time` NOT NULL per student → compare with Unboarded column
5. Verify students with all NULL boarding times are flagged as missed_boarding='YES'
6. Verify students with NULL unboarding_time on any log are flagged as missed_drop='YES'
7. Verify status badge color matches attendance rate threshold

### 16.4 Permission Test

1. Login as user with `tenant.student-transport-usage.viewAny` → can see tab
2. Login as user without `tenant.student-transport-usage.viewAny` → tab hidden
3. Login as user without `tenant.transport.viewAny` → cannot access hub at all
4. Guest user → redirected to login
5. Super admin → bypasses all checks
6. Direct URL access: `/transport-report?active_tab=student-transport-usage` → 403 if no permission

---

## 17. Known Bugs & Limitations

| Bug ID | Description | Severity | Status |
|--------|-------------|----------|--------|
| BUG-01 | Zero-event student gets "Excellent" status (BIZ-DEEP-06) | Medium | Unresolved |
| BUG-02 | Status only considers binary missed flag (0/1/2), not actual count (BIZ-DEEP-05) | Medium | Unresolved |
| BUG-03 | "Top 10" chart shows first 10 students, not top 10 by usage (BIZ-DEEP-08) | Low | Unresolved |
| BUG-04 | Route and stop filters are decorative (not applied in query) | High | Unresolved |
| BUG-05 | Date range has no effect on boarding log loading (BIZ-DEEP-17 note) | High | Unresolved |
| BUG-06 | N+1 queries due to missing eager loading (BIZ-DEEP-10) | Medium | Unresolved |
| BUG-07 | `distinct('academic_session_id')` may use wrong column (BIZ-DEEP-18) | Low | Unresolved |
| BUG-08 | AJAX race condition on rapid filter changes (BIZ-DEEP-15) | Medium | Unresolved |
| BUG-09 | No abort mechanism for in-flight AJAX requests (TC-CR18) | Low | Unresolved |
| BUG-10 | All records loaded into memory before pagination (BIZ-DEEP-07) | High | Unresolved |

---

## 18. Appendix: Key Code Snippets

### 18.1. `buildUsageSection()` — TransportReportController.php:113



### 18.2. `getTransportUsage()` — TransportReportController.php:606



### 18.3. Status Calculation — index.blade.php:388-407



### 18.4. Chart Initialization — index.blade.php:236-286



### 18.5. `paginateCollection()` — TransportReportController.php:262



### 18.6. AJAX Load Function — transportreport.blade.php:145



---

## 19. Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-07-22 | AI | Initial comprehensive TC list — 146→1397 lines. Added PC (15), DL (30), TD (12), VAL (25), AUTH (10), BIZ-DEEP (20), TC-P (20), TC-N (20), TC-D (20), TC-CR (30), CODE-TRACE (full lifecycle), Filter Matrix, Performance Analysis, Test Steps, Known Bugs |

---

*End of document — 1397 lines*
