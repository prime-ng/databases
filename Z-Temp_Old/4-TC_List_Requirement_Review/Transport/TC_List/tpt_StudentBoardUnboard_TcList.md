# tpt_StudentBoardUnboard_TcList

## Module: Transport → Trip Management → Student Boarding / Unboarding

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | Transport |
| Tab Group | Trip Management |
| Feature | Student Boarding / Unboarding |
| URL(s) | `/student/bording` (studentBordingStore GET — bulk create boarding logs), `/student/bord/unbord/edits` (studentBordingEdit GET — fetch single boarding log), `/student/bord/updates` (studentBordUnbordUpdate POST — update boarding log) |
| Controller | `Modules\Transport\Http\Controllers\StudentBoardingController` |
| Tab Container Controller | `Modules\Transport\Http\Controllers\TripMgmtController@index()` — tab: `student_bord_unbord` |
| Model | `Modules\Transport\Models\StudentBoardingLog` — table: `tpt_student_boarding_log` |
| Request Validation | Inline in `studentBordUnbordUpdate()`: `id => required`, `boarding_route_id => nullable|exists:tpt_route,id`, `unboarding_route_id => nullable|exists:tpt_route,id` |
| Permissions | `tenant.student.bording.viewAny`, `tenant.student.bording.create`, `tenant.student.bording.update`, `tenant.student.bording.edit` (controller `Gate::authorize`); blade uses `.edit` while controller uses `.update` — mismatch) |
| Soft Deletes | Yes (`StudentBoardingLog` uses `SoftDeletes` trait) |
| Route Names (blade) | `transport.student.bording.store`, `transport.student.bord.unbord.edits`, `transport.student.bord.updates` |

---

## 2. Pre-conditions

- Required permissions: `tenant.student.bording.*`
- Student allocations must exist in `tpt_student_route_allocation_jnt` for the selected route
- A trip must exist for the given date
- No dedicated CRUD resources — only bulk-create, fetch-edit, and update actions

---

## 3. Default Data Load

| Data | Source | Query | Filters |
|------|--------|-------|---------|
| Boarding Log Grid | `TripMgmtController@tripBordUnbord()` | `StudentBoardingLog::with(['studentSession.student'])->orderBy('id')` | tab=student_bord_unbord: **trip_id first** (if present), **elseif date** — mutually exclusive |
| Routes (for dropdown) | `TripMgmtController@index()` | `Route::get()` | none |
| Shifts (for dropdown) | `TripMgmtController@index()` | `Shift::get()` | none |
| Pickup Points (for dropdown) | `TripMgmtController@index()` | `PickupPoint::get()` | none |
| Attendance Devices (for dropdown) | `TripMgmtController@index()` | `AttendanceDevice::get()` — variable name `$driveAttendance` | none |
| Trip ID (for filter) | `TripMgmtController@index()` | `TptTrip::where('trip_date', $request->date)->whereHas('routeScheduler', ...)->first()` | shift_id, route_id, date |

---

## 4. Test Data Strategy

- `studentBordingStore` finds all student allocations for the given `route_id` and creates boarding log entries for each
- Skips entries that already exist for the same `trip_date + student_session_id + boarding_trip_id`
- Stores `boarding_trip_id` and `unboarding_trip_id` as the same trip ID
- `studentBordingEdit` fetches a single log by ID
- `studentBordUnbordUpdate` updates boarding/unboarding routes, stops, times, and device

---

## 5. Business Conditions

### 5.1 Database Schema — `tpt_student_boarding_log`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | id | INT UNSIGNED | PK, auto-increment |
| BC-DB-02 | trip_date | DATE | NOT NULL |
| BC-DB-03 | student_id | INT UNSIGNED | DEFAULT NULL, FK → std_students.id, ON DELETE SET NULL |
| BC-DB-04 | student_session_id | INT UNSIGNED | DEFAULT NULL, FK → std_student_academic_sessions.id, ON DELETE SET NULL |
| BC-DB-05 | boarding_route_id | INT UNSIGNED | DEFAULT NULL, FK → tpt_route.id, ON DELETE SET NULL |
| BC-DB-06 | boarding_trip_id | INT UNSIGNED | DEFAULT NULL, FK → tpt_trip.id, ON DELETE SET NULL |
| BC-DB-07 | boarding_stop_id | INT UNSIGNED | DEFAULT NULL, FK → tpt_pickup_points.id, ON DELETE SET NULL |
| BC-DB-08 | boarding_time | DATETIME | DEFAULT NULL |
| BC-DB-09 | unboarding_route_id | INT UNSIGNED | DEFAULT NULL, FK → tpt_route.id, ON DELETE SET NULL |
| BC-DB-10 | unboarding_trip_id | INT UNSIGNED | DEFAULT NULL, FK → tpt_trip.id, ON DELETE SET NULL |
| BC-DB-11 | unboarding_stop_id | INT UNSIGNED | DEFAULT NULL, FK → tpt_pickup_points.id, ON DELETE SET NULL |
| BC-DB-12 | unboarding_time | DATETIME | DEFAULT NULL |
| BC-DB-13 | device_id | INT UNSIGNED | DEFAULT NULL, FK → tpt_attendance_device.id, ON DELETE SET NULL |
| BC-DB-14 | created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |
| BC-DB-15 | updated_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP |
| BC-DB-16 | deleted_at | TIMESTAMP | NULL |

### 5.2 Validation Rules (Inline in studentBordUnbordUpdate)

| BC ID | Field | Rule |
|-------|-------|------|
| BC-VAL-01 | id | required |
| BC-VAL-02 | boarding_route_id | nullable, `exists:tpt_route,id` |
| BC-VAL-03 | unboarding_route_id | nullable, `exists:tpt_route,id` |
| BC-VAL-04 | boarding_stop_id | **NO validation** — passed directly to update() |
| BC-VAL-05 | boarding_time | **NO validation** — passed directly to update() |
| BC-VAL-06 | unboarding_stop_id | **NO validation** — passed directly to update() |
| BC-VAL-07 | unboarding_time | **NO validation** — passed directly to update() |
| BC-VAL-08 | device_id | **NO validation** — passed directly to update() |

### 5.3 Authorization (Permission Gates)

| BC ID | Permission | Method | Behavior |
|-------|-----------|--------|----------|
| BC-AUTH-01 | tenant.student.bording.viewAny | index() | Without → tab hidden |
| BC-AUTH-02 | tenant.student.bording.create | studentBordingStore() | Without → 403 |
| BC-AUTH-03 | tenant.student.bording.update | studentBordingEdit(), studentBordUnbordUpdate() | Without → 403 |
| BC-AUTH-04 | tenant.student.bording.edit | index.blade.php action column (`@can`) | **MISMATCH:** Blade uses `@can('tenant.student.bording.edit')` but Controller uses `Gate::authorize('...update')`. The permission `tenant.student.bording.edit` IS defined in `$crud` in `permissionslist.php` (line 29: `'edit'`), so it exists in DB. However, a user assigned `.edit` but NOT `.update` would see buttons but get 403; conversely, a user with `.update` but NOT `.edit` could edit via URL but never see buttons in the table |
| BC-AUTH-05 | tenant.transport.viewAny | TripMgmtController@index() | Without → cannot access trip management page at all; all tabs hidden |

### 5.4 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Bulk create boarding logs from route allocations | Gets all `TptStudentAllocationJnt` for pickup_route_id; creates StudentBoardingLog for each with trip_date, student_id, student_session_id, boarding_trip_id |
| BC-BIZ-02 | Skip existing boarding log | Check: trip_date + student_session_id + boarding_trip_id already exists → skipped |
| BC-BIZ-03 | No allocations found | JSON `{status: false, message: 'No student allocation found for this route'}` |
| BC-BIZ-04 | Fetch single log for editing | Returns JSON with all log fields |
| BC-BIZ-05 | Update boarding/unboarding details | Updates routes, stops, times, device_id |
| BC-BIZ-06 | Both boarding and unboarding use same trip_id | `boarding_trip_id => request->trip_id`, `unboarding_trip_id => request->trip_id` — same trip |

### 5.5 BC-BIZ-DEEP: Deep Business Logic Analysis

| BC-DEEP ID | Category | Analysis | Code Location | Implication |
|------------|----------|----------|---------------|-------------|
| BC-BIZ-DEEP-01 | Query | `tripBordUnbord()` is declared as `public` (not `private` or `protected`) | `TripMgmtController.php:234` | Unlike all other query helper methods in the same class which are `private` (`tripStopTimeline`, `TripQuery`, `incidentQuery`, `notificationLogQuery`, `SchedulerQuery`, `driverRouteVehicleQuery`), `tripBordUnbord()` is `public`. This could accidentally expose it as a routable action if Route Model Binding or explicit routing matches it. Risk: low but inconsistent |
| BC-BIZ-DEEP-02 | Filter | Filter logic is `trip_id` first, **elseif** `date` second — mutually exclusive | `TripMgmtController.php:241-245` | When BOTH `trip_id` and `date` are present, ONLY `trip_id` filter applies. The date parameter is completely ignored. This means data could show logs from wrong dates if the trip_id spans multiple dates (edge case since a trip_id belongs to one date) |
| BC-BIZ-DEEP-03 | Fallback | When `trip_id` is null, `tripBordUnbord()` shows ALL boarding logs unfiltered | `TripMgmtController.php:240-246` | If no trip_id and no date are provided, the query returns ALL boarding logs from ALL dates/trips. In production with years of data, this could be a massive un-filtered dataset. No `->limit()` or pagination guard on the un-filtered query |
| BC-BIZ-DEEP-04 | Trip ID Sync | `TripMgmtController@index()` finds trip by date+shift+route, then overwrites `trip_id` in request | `TripMgmtController.php:54-71` | The trip lookup uses `->first()` (not `->firstOrFail()`), so if no matching trip exists, `$tripIds` is null and the request `trip_id` is set to null. The boarding tab then shows ALL records (see BC-BIZ-DEEP-03) |
| BC-BIZ-DEEP-05 | Allocation Source | `studentBordingStore()` queries `TptStudentAllocationJnt` by `pickup_route_id` | `StudentBoardingController.php:33` | Uses `pickup_route_id` field — this means ONLY pickup route allocations generate boarding logs. Drop route allocations are ignored. If a student only has a drop route assigned (no pickup), they never get a boarding log entry |
| BC-BIZ-DEEP-06 | Skip Granularity | Skip check uses `trip_date + student_session_id + boarding_trip_id` | `StudentBoardingController.php:54-58` | The skip is per-student-session. If a student changes allocation mid-trip, the old allocation blocks the new one. Also, `boarding_trip_id` comparison uses `??` with `$request->tripe_id` (a typo-fallback field) |
| BC-BIZ-DEEP-07 | `tripe_id` typo-fallback | Code references `$request->tripe_id` throughout (typo of `trip_id`) | `StudentBoardingController.php:56,69-70`; `TripMgmtController.php:67,70` | TripMgmtController merges BOTH `trip_id` and `tripe_id` into the request. The StudentBoardingController checks `$request->trip_id ?? $request->tripe_id`. This is defensive coding for a typo — the typo should be corrected rather than perpetuated |
| BC-BIZ-DEEP-08 | student_id Resolution | Uses `$allocation->studentSessions->student_id ?? null` | `StudentBoardingController.php:67` | This accesses student_id through the `studentSessions` relationship (from `StudentAcademicSession` model). If the academic session record exists but the student_id inside it is null, student_id is stored as null in the log. No fallback to `$allocation->student_id` which is also on the JNT table |
| BC-BIZ-DEEP-09 | No Unboarding on Create | Only boarding fields are populated during bulk create | `StudentBoardingController.php:65-73` | Unboarding fields (`unboarding_route_id`, `unboarding_stop_id`, `unboarding_time`) are NOT set during bulk create. They remain null until explicitly updated via the edit modal |
| BC-BIZ-DEEP-10 | Edit returns null object | `studentBordingEdit()` returns `first()` which can be null, but wraps it in JSON `{status: true, message: '...', inserted: null}` | `StudentBoardingController.php:89-94` | Status is `true` even when no record is found. The front-end tries to access properties on null (`data.id`) which would cause JS errors  |
| BC-BIZ-DEEP-11 | Update throws 500 on null | `studentBordUnbordUpdate()` calls `$log->update()` without checking if `$log` is null | `StudentBoardingController.php:107-108` | If ID is invalid, `$log` is null, and `$log->update()` throws `Call to a member function update() on null` — results in HTTP 500 with no meaningful error message to the client |
| BC-BIZ-DEEP-12 | Blade eager-load mismatch | `tripBordUnbord()` eager-loads `['studentSession.student']` but blade uses `$row->student` directly | `TripMgmtController.php:236` vs `index.blade.php:133` | The eager load is wasted; `$row->student` loads through the separate `student()` relationship (FK: `student_id`), causing N+1 queries for student names |
| BC-BIZ-DEEP-13 | Missing eager loads for related data | Blade accesses `$row->boardingTrip->routeScheduler->route->name` and `$row->boardingTrip->tripStopDetail->stop->name` | `index.blade.php:129-130` | These traverse up to 4 levels of relationships without eager loading. `boardingTrip`, `routeScheduler`, `route`, `tripStopDetail`, and `stop` are all lazy-loaded, causing significant N+1 query overhead per row |
| BC-BIZ-DEEP-14 | `$i` counter starts at 1 | Blade uses `$i+1` for ordinal number, initialized via `$i => $row` from `$bordUnBordData` | `index.blade.php:126,128` | Since it uses `forelse($bordUnBordData as $i => $row)` where `$i` is the array key (0-indexed from paginator), `$i+1` works correctly. However, `forelse` is used without `@empty` directive — if no data, the `<tbody>` remains empty |
| BC-BIZ-DEEP-15 | Modal edit form uses `btn-sm` | The update submit button uses `btn-sm` class but per CRUD rules it should be default size | `model.blade.php:137` | Violates CRUD UI Rule 4 which states sidebar/modals should use default size, not `btn-sm` or `btn-lg` |
| BC-BIZ-DEEP-16 | `tripe_id` filter in `tripBordUnbord()` ignored | Blades's filter form sends `trip_id` (readonly field) but `tripBordUnbord()` only checks `$request->filled('trip_id')` | `index.blade.php:56` vs `TripMgmtController.php:241` | The `tripe_id` fallback is NOT checked in `tripBordUnbord()` (unlike in `studentBordingStore()` and `tripStopNew()`). If request has `tripe_id` but not `trip_id`, the filter is silently ignored |
| BC-BIZ-DEEP-17 | `tripe_id` handled in store but not grid filter | `StudentBoardingController::studentBordingStore()` uses `$request->trip_id ?? $request->tripe_id` but `tripBordUnbord()` only checks `trip_id` | `StudentBoardingController.php:56,69` vs `TripMgmtController.php:241` | Creates boarding logs with `tripe_id` value stored as `boarding_trip_id`, but the grid filter won't find those records when filtering by the same `tripe_id` since it only checks `boarding_trip_id` against `$request->trip_id` |
| BC-BIZ-DEEP-18 | No `@empty` in blade forelse | Table body uses `@forelse` but no `@empty` handler | `index.blade.php:126-150` | When no records exist, table body renders nothing — no "No records found" row. Per CRUD UI rules, an empty state should be shown |
| BC-BIZ-DEEP-19 | Missing `@canany` wrap for action header rowspan | The `<th rowspan="2">Action</th>` is wrapped in `@can('tenant.student.bording.edit')` but the `<td>` below is also wrapped — correct symmetry but uses `@can` not `@canany` | `index.blade.php:100-102,140-147` | Both th and td have same wrapper — good. But editing has only one permission (`edit`) so `@can` is appropriate, not `@canany` |
| BC-BIZ-DEEP-20 | Student name display pattern not followed | Blade shows `$row->student->first_name` without student ID below | `index.blade.php:133` | Per CRUD UI Rule 7h, student name should be followed by `<br><small class="text-muted">#{{ $record->student_id }}</small>`. The student ID is missing |
| BC-BIZ-DEEP-21 | Model `device()` relationship points to wrong model | `StudentBoardingLog::device()` returns `belongsTo(DriverAttendance::class, 'device_id')` | `StudentBoardingLog.php:161-167` | The FK `device_id` references `tpt_attendance_device.id` but the relationship targets `DriverAttendance` model instead of `AttendanceDevice` model. This may cause incorrect query joins or missing related data |
| BC-BIZ-DEEP-22 | `$driveAttendance` variable name mismatch | View receives `$driveAttendance` (AttendanceDevice records) but the variable name suggests driver attendance | `TripMgmtController.php:79,106` vs `model.blade.php:118` | Variable is loaded from `AttendanceDevice::get()` but named `$driveAttendance` — misleading. Works functionally but reduces code clarity |
| BC-BIZ-DEEP-23 | `$driveAttendance` loaded on every tab view | `AttendanceDevice::get()` is called even when the `student_bord_unbord` tab is not active | `TripMgmtController.php:79` | Unnecessary DB query when user views Driver Roster, Scheduler, or other tabs. Should be conditionally loaded only for boarding tab |
| BC-BIZ-DEEP-24 | `$pickupPoints` loaded on every tab view | `PickupPoint::get()` is called for all tabs but only used in boarding and trip-details modals | `TripMgmtController.php:78` | Similar unnecessary DB query on tabs that don't need pickup points |

### 5.6 Data Flow Analysis

| DFA ID | Flow Step | Source | Target | Data | Notes |
|--------|-----------|--------|--------|------|-------|
| DFA-01 | Tab Load | User clicks Student Bord Unbord tab | `TripMgmtController@index()` | tab=student_bord_unbord | TripMgmtController merges trip_id into request via Trip lookup (date+shift+route) |
| DFA-02 | Query Boarding Logs | `TripMgmtController@tripBordUnbord()` | `StudentBoardingLog` table | trip_id OR date filter | With `['studentSession.student']` eager load |
| DFA-03 | Render Grid | `tripmanagement.blade.php` → `student-bord-unbord/index.blade.php` | Browser | Paginated `$bordUnBordData` | Permission-gated at both tab nav and @include |
| DFA-04 | Bulk Create (Add button) | JS in `js.blade.php` builds formData from filter form → GET `/student/bording` | `StudentBoardingController@studentBordingStore()` | route_id, shift_id, date from filter form | Uses GET, not POST. CSRF not required |
| DFA-05 | Fetch Allocations | `studentBordingStore()` | `TptStudentAllocationJnt` by `pickup_route_id` | All records matching route_id | No active_status filter; gets ALL allocations including inactive |
| DFA-06 | Check Exists | `studentBordingStore()` | `StudentBoardingLog` | trip_date + student_session_id + boarding_trip_id | Per-student-session check |
| DFA-07 | Create Logs | `StudentBoardingLog::create()` | DB insert | boarding fields only; unboarding=null | Mass assignment via $fillable |
| DFA-08 | Fetch Single (Edit) | JS clicks edit button → GET `/student/bord/unbord/edits?id=X` | `StudentBoardingController@studentBordingEdit()` | log ID | Returns JSON with full record |
| DFA-09 | Show Modal | JS fills modal form fields with returned data | Browser DOM | boarding_route_id, boarding_stop_id, boarding_time, etc | `formatDateTimeLocal()` converts to HTML datetime-local format |
| DFA-10 | Submit Update | POST `/student/bord/updates` with form data | `StudentBoardingController@studentBordUnbordUpdate()` | All modal fields | CSRF token required. Inline validation for id, boarding_route_id, unboarding_route_id |
| DFA-11 | Reload Page | JS `location.reload()` on success | Browser | Page refresh | Loses any pagination state; resets to page 1 |

### 5.7 State Transition Analysis

| STATE ID | Current State | Trigger | Next State | Effect |
|----------|---------------|---------|------------|--------|
| ST-01 | No boarding logs exist for trip | User clicks "Add" button | Boarding logs created (boarding only) | `inserted=N`, `skipped=0` |
| ST-02 | Boarding logs exist for trip | User clicks "Add" button again | Existing logs preserved, no new logs | `inserted=0`, `skipped=N` |
| ST-03 | Boarding log exists with null unboarding fields | User edits via modal, sets unboarding data | Boarding log with boarding+unboarding data | `unboarding_route_id`, `unboarding_stop_id`, `unboarding_time` updated |
| ST-04 | Boarding log exists with boarding+unboarding | User edits via modal, changes boarding time | Boarding log with updated boarding time | `boarding_time` updated |
| ST-05 | Boarding log exists | User edits via modal, sets device | Boarding log with device_id | `device_id` updated |
| ST-06 | Any state | Soft delete | **NOT POSSIBLE** | No delete route/method exists |
| ST-07 | Soft-deleted | Restore | **NOT POSSIBLE** | No restore route/method exists |
| ST-08 | Soft-deleted | Force delete | **NOT POSSIBLE** | No forceDelete route/method exists |

---

## 6. Test Case List

### 6.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | Student Board/Unboard Tab Loads | `/transport/trip-management?tab=student_bord_unbord` with trip_id/date filter → grid of boarding logs. Requires BOTH `tenant.transport.viewAny` (TripMgmtController@index) AND `tenant.student.bording.viewAny` (tab) | — | — | ⬜ |
| TC-P02 | Bulk Create Boarding Logs from Allocations | GET `/student/bording?route_id=X&date=Y&trip_id=Z` → logs created for all allocated students | — | — | ⬜ |
| TC-P03 | Bulk Create — Skip Already Existing | Run same request again → skipped=N; inserted=0; message reflects skips | — | — | ⬜ |
| TC-P04 | Fetch Single Boarding Log for Edit | GET `/student/bord/unbord/edits?id=X` → JSON with log data | — | — | ⬜ |
| TC-P05 | Update Boarding Details | POST `/student/bord/updates` with id, boarding_route_id, boarding_stop_id, boarding_time → fields updated; JSON success | — | — | ⬜ |
| TC-P06 | Update Unboarding Details | POST with unboarding_route_id, unboarding_stop_id, unboarding_time → fields updated | — | — | ⬜ |
| TC-P07 | Update Device ID | POST with device_id → device_id updated | — | — | ⬜ |
| TC-P08 | Filter Boarding Logs by Trip ID | Select trip via filter form (TripMgmtController merges trip_id) → `tripBordUnbord` filters by `boarding_trip_id` | — | — | ⬜ |
| TC-P09 | Filter Boarding Logs by Date | When no trip_id, `tripBordUnbord` falls back to `trip_date` filter (elseif — mutually exclusive with trip_id) | — | — | ⬜ |
| TC-P10 | Tab Loads with No Filters | Access `/transport/trip-management?tab=student_bord_unbord` without trip_id or date → paginated list of ALL boarding logs (unfiltered) | — | — | ⬜ |
| TC-P11 | Pagination Keeps Tab Active | Click page 2 on paginated boarding log grid | URL maintains `?tab=student_bord_unbord&page=2` | — | — | ⬜ |
| TC-P12 | AJAX Add Button Uses Filter Form Data | Click "Add" button with route_id=5, shift_id=2, date=2026-07-21 selected → GET `/student/bording` includes all filter params | — | — | ⬜ |
| TC-P13 | Edit Modal Opens with Pre-filled Data | Click edit button on a row → modal shows with existing boarding/unboarding data and device | — | — | ⬜ |
| TC-P14 | Update All Fields Together | POST with all fields (boarding_route_id, boarding_stop_id, boarding_time, unboarding_route_id, unboarding_stop_id, unboarding_time, device_id) → all updated | — | — | ⬜ |
| TC-P15 | Update with Null Fields | POST with boarding_route_id=null, boarding_stop_id=null → fields set to NULL | — | — | ⬜ |

### 6.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | Bulk Create — No Student Allocations for Route | GET `/student/bording?route_id=X` → JSON `{status: false, message: 'No student allocation found for this route'}` | — | — | ⬜ |
| TC-N02 | Bulk Create — Missing route_id | No validation on input; `where('pickup_route_id', null)` returns empty → JSON `{status: false, message: 'No student allocation found for this route'}` | — | — | ⬜ |
| TC-N03 | Fetch Log With Invalid ID | GET `/student/bord/unbord/edits?id=99999` → first() returns null → JSON with null data, but status=true | — | — | ⬜ |
| TC-N04 | Update Log With Invalid ID | POST with id=99999 → `StudentBoardingLog::where('id', $id)->first()` returns null → `$log->update()` throws `Call to a member function update() on null` → 500 error | — | — | ⬜ |
| TC-N05 | Update With Invalid boarding_route_id | `exists:tpt_route,id` validation error | — | — | ⬜ |
| TC-N06 | Update With Invalid unboarding_route_id | `exists:tpt_route,id` validation error | — | — | ⬜ |
| TC-N07 | Permission 403 — Without student.bording.create | 403 on studentBordingStore | — | — | ⬜ |
| TC-N08 | Permission 403 — Without student.bording.update | 403 on studentBordingEdit/studentBordUnbordUpdate | — | — | ⬜ |
| TC-N09 | Guest Access | All URLs redirect to `/login` | — | — | ⬜ |
| TC-N10 | Invalid `allocation.studentSessions` is null | Loop continues with `continue;` if student_session_id is null; but if student_session_id is set and relation fails, `$allocation->studentSessions->student_id ?? null` uses null coalescing → sets student_id to null, no error | — | — | ⬜ |
| TC-N11 | Permission 403 — Without tenant.student.bording.viewAny | Access `StudentBoardingController@index` without permission → 403 | — | — | ⬜ |
| TC-N12 | Permission 403 — Without tenant.student.bording.viewAny on Tab | `TripMgmtController@index` requires `tenant.transport.viewAny`, but the tab also requires `tenant.student.bording.viewAny`; without the tab permission, the `Student Bord Unbord` tab nav is hidden | — | — | ⬜ |
| TC-N13 | Delete Not Implemented | No route or controller method exists for `DELETE` on boarding logs → 404 | — | — | ⬜ |
| TC-N14 | Restore Not Implemented | No route or controller method exists for restoring soft-deleted boarding logs → 404 | — | — | ⬜ |
| TC-N15 | Force-Delete Not Implemented | No route or controller method exists for force-deleting boarding logs → 404 | — | — | ⬜ |
| TC-N16 | Bulk Create — Missing date parameter | No validation; `$request->date` is null → `where('trip_date', null)` potentially creates logs with null trip_date | — | — | ⬜ |
| TC-N17 | Bulk Create — Missing trip_id parameter | `$request->trip_id ?? $request->tripe_id` → both null → `boarding_trip_id` stored as null | — | — | ⬜ |
| TC-N18 | Update with non-existent valid route IDs | `boarding_route_id=99999` where 99999 doesn't exist in tpt_route → 422 validation error | — | — | ⬜ |
| TC-N19 | Update — Missing id parameter | POST without id → inline validation says `id => required` → 422 error | — | — | ⬜ |
| TC-N20 | JS Edit Button — No ID on element | Click edit button with missing `data-id` attribute → JS console error, no modal opens | — | — | ⬜ |

### 6.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|----------------|---------|---------|--------|
| TC-D01 | A | Trip Deletion — BoardingLog SET NULL | FK SET NULL → boarding_trip_id/unboarding_trip_id becomes NULL | — | — | ⬜ |
| TC-D02 | B | Route Deletion — BoardingLog SET NULL | FK SET NULL on boarding_route_id/unboarding_route_id | — | — | ⬜ |
| TC-D03 | C | PickupPoint Deletion — BoardingLog SET NULL | FK SET NULL on boarding_stop_id/unboarding_stop_id | — | — | ⬜ |
| TC-D04 | D | Student Deletion — BoardingLog SET NULL | FK SET NULL on student_id | — | — | ⬜ |
| TC-D05 | E | StudentSession Deletion — BoardingLog SET NULL | FK SET NULL on student_session_id | — | — | ⬜ |
| TC-D06 | F | Attendance Device Deletion — BoardingLog SET NULL | FK SET NULL on device_id | — | — | ⬜ |
| TC-D07 | G | Student Allocation Deletion — No Impact | Allocation JNT is source data only; no FK from boarding log to allocation JNT | — | — | ⬜ |

### 6.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|-----------------|---------|---------|--------|
| TC-CR01 | CR | P1 | Controller — Gate::authorize() Before Each Method | All **4** methods (`index`, `studentBordingStore`, `studentBordingEdit`, `studentBordUnbordUpdate`) have `Gate::authorize()` as first line | — | — | ◌ |
| TC-CR02 | CR | P1 | Controller — No activityLog in StudentBoardingController | Boarding operations do NOT log to activity_log | — | — | ◌ |
| TC-CR03 | CR | P1 | Controller — No validation on studentBordingStore input | route_id, date, trip_id not validated | — | — | ◌ |
| TC-CR04 | CR | P1 | Controller — Skip logic for existing logs | Checked by trip_date + student_session_id + boarding_trip_id | — | — | ◌ |
| TC-CR05 | CR | P1 | Controller — studentBordingEdit uses first() not findOrFail() | Returns null object if not found; no 404 handling | — | — | ◌ |
| TC-CR06 | CR | P1 | Controller — studentBordUnbordUpdate uses first() not findOrFail() | Can cause update() on null → 500 error | — | — | ◌ |
| TC-CR07 | CR | P1 | Controller — Same trip for boarding and unboarding | Both boarding_trip_id and unboarding_trip_id set to same request->trip_id | — | — | ◌ |
| TC-CR08 | CR | P1 | Model — Table Name | `protected $table = 'tpt_student_boarding_log'` | — | — | ◌ |
| TC-CR09 | CR | P1 | Model — Fillable Fields | **12** fillable fields: trip_date, student_id, student_session_id, boarding_route_id, boarding_trip_id, boarding_stop_id, boarding_time, unboarding_route_id, unboarding_trip_id, unboarding_stop_id, unboarding_time, device_id | — | — | ◌ |
| TC-CR10 | CR | P1 | Model — Relationships | student(), studentSession(), boardingRoute(), boardingTrip(), boardingStop(), unboardingRoute(), unboardingTrip(), unboardingStop(), device() — 9 relationships | — | — | ◌ |
| TC-CR11 | CR | P1 | DDL — All FKs Are SET NULL | 9 FKs all use ON DELETE SET NULL | — | — | ◌ |
| TC-CR12 | CR | P1 | Routes — Non-RESTful pattern | GET for store (not POST) — studentBordingStore is GET, not POST | — | — | ◌ |
| TC-CR13 | CR | P1 | Gap — GET used for mutation (studentBordingStore) | Creating data via GET violates HTTP spec; should be POST | — | — | ◌ |
| TC-CR14 | CR | P1 | Gap — No soft delete / restore / force delete implemented | StudentBoardingLog has SoftDeletes trait but no restore/forceDelete routes or methods | — | — | ◌ |
| TC-CR15 | CR | P1 | Gap — studentBordUnbordUpdate nullable inline validation | Only boarding_route_id and unboarding_route_id have exists validation; all other fields (boarding_stop_id, boarding_time, unboarding_stop_id, unboarding_time, device_id) are NOT validated | — | — | ◌ |
| TC-CR16 | CR | P1 | Gap — Blade uses `tenant.student.bording.edit` vs Controller uses `tenant.student.bording.update` | `index.blade.php` action column uses `@can('tenant.student.bording.edit')`. Controller `Gate::authorize('...update')`. Both permissions exist in `$crud`. Mismatch: user with `.edit` but not `.update` sees buttons but gets 403; user with `.update` but not `.edit` can edit via URL but has no buttons | — | — | ◌ |
| TC-CR17 | CR | P1 | Gap — No delete/restore/forceDelete routes/controller methods despite SoftDeletes trait | Model `StudentBoardingLog` uses `SoftDeletes` and `$table->softDeletes()` exists in DDL, but no Route or Controller method implements destroy/restore/forceDelete for boarding logs. Records can never be deleted or restored via UI/API | — | — | ◌ |
| TC-CR18 | CR | P1 | Gap — No activityLog calls in StudentBoardingController | None of the 4 controller methods call `activityLog()`. Creates/updates are not tracked in the activity_log table | — | — | ◌ |
| TC-CR19 | CR | P2 | Policy — `TransportStudentBoardingPolicy` has unused permissions | Policy defines `markBoarding()`, `markAlighting()`, `viewReports()`, `generateBoardingPass()`, `import()`, `export()`, `print()` methods — none of these are referenced in Controller or Blade views | — | — | ◌ |
| TC-CR20 | CR | P2 | Controller — Method visibility inconsistency | `tripBordUnbord()` is `public` while all other query helpers in TripMgmtController are `private` | — | — | ◌ |
| TC-CR21 | CR | P2 | Blade — Missing `@empty` in forelse | No empty-state row when no boarding logs exist | — | — | ◌ |
| TC-CR22 | CR | P2 | Blade — No tab filter reset button uses wrong URL | Reset link uses `url()->current()` which loses the tab parameter | `index.blade.php:63` | — | ◌ |
| TC-CR23 | CR | P2 | Blade — `$driveAttendance` variable name misleading | Variable holds AttendanceDevice records but name suggests driver attendance | — | — | ◌ |
| TC-CR24 | CR | P2 | Model — `device()` relationship mis-targeted | `belongsTo(DriverAttendance::class, 'device_id')` but FK references `tpt_attendance_device.id`, not `tpt_driver_attendance.id` | — | — | ◌ |
| TC-CR25 | CR | P2 | Controller — `$request->tripe_id` typo perpetuated | Both controllers reference `$request->tripe_id` which is a typo of `trip_id`. TripMgmtController merges both into request | — | — | ◌ |
| TC-CR26 | CR | P2 | Performance — Unnecessary eager load | `tripBordUnbord()` loads `studentSession.student` but blade uses `$row->student` | — | — | ◌ |
| TC-CR27 | CR | P2 | Performance — Missing eager loads for deep relationships | `$row->boardingTrip->routeScheduler->route->name` causes N+1 queries for trip, routeScheduler, route, tripStopDetail, stop | — | — | ◌ |
| TC-CR28 | CR | P2 | Performance — Unconditional queries on every tab | `PickupPoint::get()`, `AttendanceDevice::get()` loaded for all tabs, not just student_bord_unbord | — | — | ◌ |
| TC-CR29 | CR | P2 | Blade — Student name display doesn't include ID | Per CRUD UI Rule 7h, should show `Student Name<br><small>#student_id</small>` | — | — | ◌ |

---

## 7. Detailed Test Steps

### TC-P01: Student Board/Unboard Tab Loads

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Log in as user with `tenant.transport.viewAny` and `tenant.student.bording.viewAny` permissions | Authenticated |
| 2 | Navigate to `/transport/trip-management` | Trip Management page loads with all tabs |
| 3 | Verify `Student Bord Unbord` tab is visible in the tab navigation bar | Tab labeled "Student Bord Unbord" is present |
| 4 | Click `Student Bord Unbord` tab or navigate to `?tab=student_bord_unbord` | URL changes to include `tab=student_bord_unbord` |
| 5 | Select a date and route via the filter form, click search | TripMgmtController resolves trip_id from date+route+shift |
| 6 | Verify boarding logs grid appears with correct pagination | Table with columns: Ord.No., Route, Stop Name, Arrival Time, Departure Time, Student Name, Boarding Route, Boarding Stop, Board Time, Un-Board Route, Un-Board Stop, Un-Board Time, Action |
| 7 | Verify no JavaScript errors in console | Console clean |

### TC-P02: Bulk Create Boarding Logs from Allocations

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure 10 student allocations exist for route_id=5 | 10 allocations with student_session_id in `tpt_student_route_allocation_jnt` |
| 2 | Ensure trip_id=100 exists for date=2026-07-21 in `tpt_trip` | Trip exists with matching date |
| 3 | GET `/student/bording?route_id=5&date=2026-07-21&trip_id=100` | JSON: `{status: true, inserted: 10, skipped: 0}` |
| 4 | DB check: `SELECT COUNT(*) FROM tpt_student_boarding_log WHERE trip_date='2026-07-21' AND boarding_trip_id=100` | 10 records |
| 5 | Verify each log has boarding_trip_id=100, unboarding_trip_id=100 | All 10 have same trip for both |
| 6 | Verify boarding_route_id, boarding_stop_id, boarding_time are NULL | Unboarding fields not populated on create |
| 7 | Run same GET again | JSON: `{status: true, inserted: 0, skipped: 10}` |

### TC-P03: Bulk Create — Skip Already Existing

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Run TC-P02 first to create 10 boarding logs | 10 records exist |
| 2 | GET `/student/bording?route_id=5&date=2026-07-21&trip_id=100` (same params) | JSON: `{status: true, inserted: 0, skipped: 10}` |
| 3 | DB count remains 10 | `SELECT COUNT(*) FROM tpt_student_boarding_log` = 10 |
| 4 | Verify skip logic matched on trip_date + student_session_id + boarding_trip_id | Composite key prevented duplicate |
| 5 | Partially modify: change trip_id to 101 (different trip same date) | GET with trip_id=101 → inserted=10 (all new because boarding_trip_id differs) |

### TC-P04: Fetch Single Boarding Log for Edit

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a boarding log with id=5 via TC-P02 | Record exists |
| 2 | GET `/student/bord/unbord/edits?id=5` | JSON: `{status: true, message: 'Student Log Get successfully', inserted: {id:5, trip_date:'...', ...}}` |
| 3 | Verify JSON contains all model fields | id, trip_date, student_id, student_session_id, boarding_route_id, boarding_trip_id, boarding_stop_id, boarding_time, unboarding_route_id, unboarding_trip_id, unboarding_stop_id, unboarding_time, device_id, created_at, updated_at |
| 4 | Verify field values match DB record | Cross-check against DB query |

### TC-P05: Update Boarding Details

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create boarding log with null boarding fields | boarding_route_id=NULL, boarding_stop_id=NULL, boarding_time=NULL |
| 2 | POST `/student/bord/updates` with `id=X&boarding_route_id=3&boarding_stop_id=7&boarding_time=2026-07-21T07:30:00` | JSON: `{status: true, message: 'Student Boarding / Un-Boarding updated successfully'}` |
| 3 | DB check: `SELECT boarding_route_id, boarding_stop_id, boarding_time FROM tpt_student_boarding_log WHERE id=X` | boarding_route_id=3, boarding_stop_id=7, boarding_time=2026-07-21 07:30:00 |
| 4 | Verify updated_at timestamp changed | updated_at is recent |

### TC-P06: Update Unboarding Details

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create boarding log with null unboarding fields | unboarding fields NULL |
| 2 | POST `/student/bord/updates` with `id=X&unboarding_route_id=4&unboarding_stop_id=9&unboarding_time=2026-07-21T14:30:00` | JSON success |
| 3 | DB check: `SELECT unboarding_route_id, unboarding_stop_id, unboarding_time FROM tpt_student_boarding_log WHERE id=X` | unboarding_route_id=4, unboarding_stop_id=9, unboarding_time=2026-07-21 14:30:00 |

### TC-P07: Update Device ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create boarding log with device_id=NULL | device_id is NULL |
| 2 | Ensure device_id=2 exists in `tpt_attendance_device` | Device exists |
| 3 | POST `/student/bord/updates` with `id=X&device_id=2` | JSON success |
| 4 | DB check: `SELECT device_id FROM tpt_student_boarding_log WHERE id=X` | device_id=2 |

### TC-P08: Filter Boarding Logs by Trip ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 5 boarding logs with trip_id=100, 3 with trip_id=200 | 8 total logs, 2 different trips |
| 2 | Navigate to `/transport/trip-management?tab=student_bord_unbord` | All 8 logs show in unfiltered grid |
| 3 | Set filter: select date and route that resolves to trip_id=100 | TripMgmtController merges `trip_id=100` into request |
| 4 | Submit filter form | Only 5 logs with boarding_trip_id=100 appear in grid |
| 5 | Verify pagination count shows 5 | Correct filtered count |

### TC-P09: Filter Boarding Logs by Date

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 4 boarding logs with trip_date=2026-07-21, 6 with trip_date=2026-07-22 | 10 logs on 2 dates |
| 2 | Navigate to `?tab=student_bord_unbord&date=2026-07-21` without trip_id | Only 4 logs with trip_date=2026-07-21 appear |
| 3 | Verify `trip_id` is NOT in the filter (date filter is elseif branch) | Date filter applied, trip_id filter not |
| 4 | Verify trip_id filter takes priority: add `&trip_id=200` (belongs to 2026-07-22) | trip_id filter overrides; shows 6 logs from 2026-07-22, ignoring the 2026-07-21 date param |

### TC-P10: Tab Loads with No Filters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure 100+ boarding logs exist across multiple dates | Data exists |
| 2 | Navigate to `/transport/trip-management?tab=student_bord_unbord` with no filter params | **BUG**: ALL boarding logs from ALL dates are loaded |
| 3 | Verify page loads with paginated results | 10 per page |
| 4 | Note: No limit or guard prevents full table scan | Performance risk on large datasets |

### TC-P11: Pagination Keeps Tab Active

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Load tab: `?tab=student_bord_unbord` with many records | Page 1 of N |
| 2 | Click pagination link (page 2) | URL: `?tab=student_bord_unbord&page=2` — tab stays active |
| 3 | Verify page 2 data loads in same tab | Correct records on page 2 |
| 4 | Click back to page 1 | Previous state restored |

### TC-P12: AJAX Add Button Uses Filter Form Data

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set filter form: route_id=5, shift_id=2, date=2026-07-21 | Form fields populated |
| 2 | Click "Add" button (`#addEntryBtns`) | JS serializes form data and sends GET to `/student/bording` |
| 3 | Verify AJAX request URL includes `route_id=5&shift_id=2&date=2026-07-21` | Network tab shows correct params |
| 4 | Verify TripMgmtController index() already resolved trip_id (trip_id is in the readonly input) | Readonly trip_id field also submitted |
| 5 | Verify success toast shown upon completion | Toast: "Boarding entries created successfully" |

### TC-P13: Edit Modal Opens with Pre-filled Data

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click edit button on a boarding log row | SweetAlert confirmation: "Sure to Edit?" |
| 2 | Click "Yes, proceed!" | AJAX GET to `/student/bord/unbord/edits?id=X` |
| 3 | Modal `#editStudentBoardingModal` appears | Modal visible with data loaded |
| 4 | Verify boarding route dropdown is pre-selected | `#edit_boarding_route_id` has correct option selected |
| 5 | Verify boarding stop dropdown is pre-selected | `#edit_boarding_stop_id` has correct option selected |
| 6 | Verify boarding time input is pre-filled | `#edit_boarding_time` has datetime-local formatted value |
| 7 | Verify unboarding route/stop/time are pre-filled | Correct values |
| 8 | Verify device dropdown is pre-selected | `#edit_device_id` has correct option |

### TC-P14: Update All Fields Together

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open edit modal for a boarding log | Log data loaded into modal |
| 2 | Change all 7 fields: boarding_route_id=3, boarding_stop_id=5, boarding_time=07:30, unboarding_route_id=4, unboarding_stop_id=9, unboarding_time=14:30, device_id=2 | All fields changed |
| 3 | Click "Update" button | POST to `/student/bord/updates` |
| 4 | DB check all 7 fields updated | Each field matches new value |
| 5 | Page reloads automatically | `location.reload()` fires |

### TC-P15: Update with Null Fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open edit modal for a log with boarding_route_id=3 | Has existing value |
| 2 | Clear boarding_route_id dropdown (select empty option) | Value becomes null |
| 3 | Click Update | POST with boarding_route_id empty |
| 4 | DB check: `boarding_route_id` is NULL | Null accepted (nullable column) |

### TC-N01: Bulk Create — No Student Allocations for Route

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure route_id=999 has NO allocations in `tpt_student_route_allocation_jnt` | Zero records |
| 2 | GET `/student/bording?route_id=999&date=2026-07-21&trip_id=100` | JSON: `{status: false, message: 'No student allocation found for this route'}` |
| 3 | Verify no boarding logs were created | `SELECT COUNT(*) FROM tpt_student_boarding_log WHERE boarding_trip_id=100` = 0 |

### TC-N02: Bulk Create — Missing route_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | GET `/student/bording` (no route_id parameter) | `$request->route_id` is null |
| 2 | Code flows: `TptStudentAllocationJnt::where('pickup_route_id', null)->get()` | Empty result |
| 3 | Response: `{status: false, message: 'No student allocation found for this route'}` | Graceful handling but no validation error |

### TC-N03: Fetch Log With Invalid ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | GET `/student/bord/unbord/edits?id=99999` | `StudentBoardingLog::where('id', 99999)->first()` returns null |
| 2 | Response: `{status: true, message: 'Student Log Get successfully', inserted: null}` | **BUG**: status is `true` but data is null |
| 3 | Frontend receives `res.inserted` as null | JS: `$('#edit_ids').val(data.id)` → error trying to access `.id` on null |
| 4 | Console error logged from `error` callback | `showToast('error','Failed to load stop details')` |

### TC-N04: Update Log With Invalid ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST `/student/bord/updates` with `id=99999&boarding_route_id=3` | Inline validation passes (id is numeric) |
| 2 | `StudentBoardingLog::where('id', 99999)->first()` returns null | `$log` = null |
| 3 | `$log->update(...)` executes | **CRITICAL BUG**: `Call to a member function update() on null` → PHP Error |
| 4 | HTTP 500 returned to client | Error message: "Server error" with no details |
| 5 | `try-catch` does NOT exist around the update call | Unhandled exception |

### TC-N05: Update With Invalid boarding_route_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST `/student/bord/updates` with `id=1&boarding_route_id=99999` (99999 not in tpt_route) | Inline validation: `boarding_route_id => nullable|exists:tpt_route,id` |
| 2 | HTTP 422 response with validation errors | JSON: `{message: "...", errors: {boarding_route_id: ["The selected boarding route id is invalid."]}}` |
| 3 | No DB changes | Record unchanged |

### TC-N06: Update With Invalid unboarding_route_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST with `id=1&unboarding_route_id=99999` | 422 validation error for unboarding_route_id |

### TC-N07: Permission 403 — Without student.bording.create

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Log in as user WITHOUT `tenant.student.bording.create` | Authenticated |
| 2 | GET `/student/bording?route_id=5&date=2026-07-21&trip_id=100` | Gate::authorize() throws AuthorizationException |
| 3 | HTTP 403 Forbidden response | `{message: "This action is unauthorized."}` |
| 4 | Verify "Add" button is NOT visible in UI | `@can('tenant.student.bording.create')` hides the button |

### TC-N08: Permission 403 — Without student.bording.update

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Log in as user WITHOUT `tenant.student.bording.update` | Authenticated |
| 2 | GET `/student/bord/unbord/edits?id=5` | 403 Forbidden |
| 3 | POST `/student/bord/updates` with valid data | 403 Forbidden |
| 4 | Verify edit buttons are NOT visible in grid | `@can('tenant.student.bording.edit')` — note: uses `.edit` not `.update` |
| 5 | Note: if user has `.edit` but not `.update`, buttons show but both edit and update return 403 | Permission mismatch between blade and controller |

### TC-N09: Guest Access

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Log out / clear session | Guest user |
| 2 | GET `/student/bording?route_id=5&date=2026-07-21&trip_id=100` | Redirect to `/login` |
| 3 | GET `/student/bord/unbord/edits?id=5` | Redirect to `/login` |
| 4 | POST `/student/bord/updates` | Redirect to `/login` |
| 5 | GET `/transport/trip-management` | Redirect to `/login` |

### TC-N10: Invalid `allocation.studentSessions` null

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure a student allocation exists with student_session_id=999 where `std_student_academic_sessions.id=999` does NOT exist (orphaned FK) | Allocation exists, relation fails |
| 2 | Also ensure one allocation has student_session_id=NULL | Allocation exists with null session |
| 3 | Run studentBordingStore for that route | Loop processes each allocation |
| 4 | For allocation with student_session_id=NULL: `if (!$allocation->student_session_id) { continue; }` | Skipped — no log created for this allocation |
| 5 | For allocation with orphaned student_session_id=999: `$allocation->studentSessions` returns null | `$allocation->studentSessions->student_id ?? null` → null coalescing returns null |
| 6 | Log is created with student_id=NULL | No error thrown |

### TC-N11: Permission 403 — Without tenant.student.bording.viewAny

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Log in as user with `tenant.transport.viewAny` but WITHOUT `tenant.student.bording.viewAny` | Authenticated |
| 2 | Direct access to `StudentBoardingController@index()` by hitting its URL | Gate::authorize('tenant.student.bording.viewAny') throws 403 |
| 3 | Note: `StudentBoardingController@index()` renders `transport::student-boarding.index` which is a separate view (not the tab) | This is a standalone index view, not the tab partial |

### TC-N12: Permission — Without tenant.student.bording.viewAny on Tab

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Log in as user with `tenant.transport.viewAny` but WITHOUT `tenant.student.bording.viewAny` | Authenticated |
| 2 | Navigate to `/transport/trip-management` | Tab navigation loads; "Student Bord Unbord" tab is **hidden** |
| 3 | Check HTML for the tab nav-link | Element not rendered |
| 4 | Try to manually navigate to `?tab=student_bord_unbord` | Tab content NOT rendered because `@can('tenant.student.bording.viewAny')` around `@include` fails |

### TC-N13: Delete Not Implemented

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check `routes/web.php` for any `DELETE` route targeting StudentBoardingController | No delete route exists |
| 2 | Check `StudentBoardingController.php` for a `destroy()` method | No destroy method exists |
| 3 | Send `DELETE /student/bording/5` | 404 Not Found |
| 4 | Any boarding log once created can never be removed via UI | Permanent record unless manually deleted from DB |

### TC-N14: Restore Not Implemented

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check `routes/web.php` for any restore route targeting StudentBoardingLog | No restore route exists |
| 2 | Check `StudentBoardingController.php` for a `restore()` method | No restore method exists |

### TC-N15: Force-Delete Not Implemented

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check `routes/web.php` for any force-delete route | No force-delete route exists |
| 2 | Check `StudentBoardingController.php` for a `forceDelete()` method | No forceDelete method exists |

### TC-N16: Bulk Create — Missing date parameter

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | GET `/student/bording?route_id=5&trip_id=100` (no date) | `$request->date` is null |
| 2 | Skip check: `StudentBoardingLog::where('trip_date', null)...` | Matches records with null trip_date (if any) |
| 3 | Insert: `'trip_date' => null` | trip_date stored as NULL (column is NOT NULL in DDL) |
| 4 | **DB behavior**: MySQL in strict mode may reject null for NOT NULL column | Possible SQL error or warning depending on DB mode |

### TC-N17: Bulk Create — Missing trip_id parameter

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | GET `/student/bording?route_id=5&date=2026-07-21` (no trip_id) | `$request->trip_id` and `$request->tripe_id` both null |
| 2 | `'boarding_trip_id' => null`, `'unboarding_trip_id' => null` | trip_id stored as NULL |
| 3 | Grid filter: `tripBordUnbord` runs without trip_id filter | Shows all logs (unfiltered) — these null-trip logs appear |
| 4 | But they cannot be filtered by trip_id later | Orphaned logs with no trip association |

### TC-N18: Update with non-existent valid route IDs

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST with `boarding_route_id=99999` where 99999 doesn't exist in tpt_route | 422 validation error: "The selected boarding route id is invalid." |
| 2 | POST with `unboarding_route_id=99999` where 99999 doesn't exist | Same 422 error |

### TC-N19: Update — Missing id parameter

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST `/student/bord/updates` without `id` in request body | Validation: `'id' => 'required'` fails |
| 2 | HTTP 422 with validation error | `{message: "...", errors: {id: ["The id field is required."]}}` |

### TC-N20: JS Edit Button — No ID on Element

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Manually craft a row without `data-id` attribute on `.editStopBtns` button | Button exists but has no data-id |
| 2 | Click the button | `let id = $(this).data('id');` → undefined |
| 3 | `if (!id)` condition triggers | `console.error('Stop ID not found')` — no modal, no AJAX |

### TC-D01: Trip Deletion — BoardingLog SET NULL

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create boarding log with boarding_trip_id=100, unboarding_trip_id=100 | Both FKs set |
| 2 | Delete trip with id=100 from `tpt_trip` (soft delete or hard delete — depends on DB FK action) | FK: ON DELETE SET NULL |
| 3 | Check `tpt_student_boarding_log` for the log | boarding_trip_id=NULL, unboarding_trip_id=NULL |
| 4 | Grid now shows log without trip context | Route, Stop, Arrival/Departure fields all empty |

### TC-D02: Route Deletion — BoardingLog SET NULL

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create boarding log with boarding_route_id=3 | Route assigned |
| 2 | Delete route id=3 from `tpt_route` | FK SET NULL |
| 3 | DB: boarding_route_id becomes NULL | Boarding route reference lost |

### TC-D03: PickupPoint Deletion — BoardingLog SET NULL

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create boarding log with boarding_stop_id=7 | Stop assigned |
| 2 | Delete pickup point id=7 from `tpt_pickup_points` | FK SET NULL |
| 3 | DB: boarding_stop_id becomes NULL | Stop reference lost |

### TC-D04: Student Deletion — BoardingLog SET NULL

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create boarding log with student_id=50 | Student assigned |
| 2 | Delete student id=50 from `std_students` | FK SET NULL (ON DELETE SET NULL on student_id FK) |
| 3 | DB: student_id becomes NULL | Student reference lost; student name not displayed in grid |

### TC-D05: StudentSession Deletion — BoardingLog SET NULL

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create boarding log with student_session_id=200 | Session assigned |
| 2 | Delete academic session id=200 from `std_student_academic_sessions` | FK SET NULL |
| 3 | DB: student_session_id becomes NULL | Session reference lost |

### TC-D06: Attendance Device Deletion — BoardingLog SET NULL

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create boarding log with device_id=5 | Device assigned |
| 2 | Delete device id=5 from `tpt_attendance_device` | FK SET NULL |
| 3 | DB: device_id becomes NULL | Device reference lost |

### TC-D07: Student Allocation Deletion — No Impact

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 5 boarding logs from route_id=5 allocations | Logs reference trip_id, not allocation_id |
| 2 | Delete all allocations from `tpt_student_route_allocation_jnt` where pickup_route_id=5 | No FK from boarding log to allocation JNT |
| 3 | Boarding logs remain intact | No impact on existing logs |

### TC-CR01: Gate::authorize() Before Each Method

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `StudentBoardingController.php` line 20 | `index()`: `Gate::authorize('tenant.student.bording.viewAny')` — present |
| 2 | Inspect line 30 | `studentBordingStore()`: `Gate::authorize('tenant.student.bording.create')` — present |
| 3 | Inspect line 87 | `studentBordingEdit()`: `Gate::authorize('tenant.student.bording.update')` — present |
| 4 | Inspect line 99 | `studentBordUnbordUpdate()`: `Gate::authorize('tenant.student.bording.update')` — present |
| 5 | All 4 methods have Gate::authorize as first executable line | ✅ PASS |

### TC-CR02: No activityLog Calls

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Search `StudentBoardingController.php` for `activityLog` | Not found — 0 occurrences |
| 2 | Compare with TripController which calls activityLog on update, delete, restore | Contrast: TripController logs actions |
| 3 | Boarding operations are not auditable | Creates and updates of student boarding logs are invisible in audit trail |

### TC-CR03: No Validation on studentBordingStore Input

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `studentBordingStore()` method from line 28-83 | No `$request->validate()` call anywhere |
| 2 | route_id, date, trip_id are used directly without validation | All three can be null, empty, or malformed |
| 3 | Non-numeric route_id would still execute query | `where('pickup_route_id', $request->route_id)` with string input returns empty |

### TC-CR04: Skip Logic for Existing Logs

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect skip check at lines 54-58 | `where('trip_date', $request->date)->where('student_session_id', ...)->where('boarding_trip_id', ...)->exists()` |
| 2 | Composite uniqueness: trip_date + student_session_id + boarding_trip_id | Prevents duplicate boarding logs for same student on same trip |
| 3 | Note: No unique constraint in DB schema | Relies on application-level check; race condition possible with concurrent requests |

### TC-CR05: studentBordingEdit Uses first() Not findOrFail()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect line 89 | `StudentBoardingLog::where('id', $request->id)->first()` |
| 2 | When ID not found: returns null | No 404, no exception |
| 3 | Returned as JSON `{status: true, inserted: null}` | Status is misleadingly true |

### TC-CR06: studentBordUnbordUpdate Uses first() Not findOrFail()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect line 107 | `StudentBoardingLog::where('id', $request->id)->first()` |
| 2 | When ID not found: `$log` is null | Subsequent `$log->update()` throws error |
| 3 | No try-catch around update | Unhandled `Error: Call to a member function update() on null` |

### TC-CR07: Same Trip for Boarding and Unboarding

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect lines 69-70 | `'boarding_trip_id' => $request->trip_id ?? $request->tripe_id` and same for unboarding |
| 2 | Both set to same value | Boarding and unboarding always reference the same trip |
| 3 | Business implication: Assumes a single trip covers both pickup and drop | If a student uses different trips for boarding vs unboarding, this model doesn't support it |

### TC-CR08: Model Table Name

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `StudentBoardingLog.php` line 24 | `protected $table = 'tpt_student_boarding_log'` |
| 2 | Matches DDL | ✅ Correct |

### TC-CR09: Model Fillable Fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `StudentBoardingLog.php` lines 34-54 | 12 fillable fields |
| 2 | List: trip_date, student_id, student_session_id, boarding_route_id, boarding_trip_id, boarding_stop_id, boarding_time, unboarding_route_id, unboarding_trip_id, unboarding_stop_id, unboarding_time, device_id | Complete set |
| 3 | Note: `id`, `created_at`, `updated_at`, `deleted_at` are NOT fillable | Protected — correct |

### TC-CR10: Model Relationships

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Count relationships in `StudentBoardingLog.php` | 9 relationships: student(), studentSession(), boardingRoute(), boardingTrip(), boardingStop(), unboardingRoute(), unboardingTrip(), unboardingStop(), device() |
| 2 | Verify each uses correct FK | All mapped correctly except `device()` targets `DriverAttendance` instead of `AttendanceDevice` (see TC-CR24) |

### TC-CR11: DDL — All FKs SET NULL

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect migration DDL for all 9 FK definitions | All use ON DELETE SET NULL |
| 2 | FKs: student_id, student_session_id, boarding_route_id, boarding_trip_id, boarding_stop_id, unboarding_route_id, unboarding_trip_id, unboarding_stop_id, device_id | 9 FKs confirmed |
| 3 | Implication: Deleting referenced records silently nullifies boarding log fields | Data integrity maintained but orphaned records possible |

### TC-CR12: Routes — Non-RESTful Pattern

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `web.php` lines 171-176 | `Route::get('student/bording', ...)` — GET |
| 2 | `Route::get('student/bord/unbord/edits', ...)` — GET (acceptable for read) | This is a read operation, GET is acceptable |
| 3 | `Route::post('student/bord/updates', ...)` — POST | Acceptable for update |

### TC-CR13: Gap — GET Used for Mutation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `web.php` line 171 | `Route::get('student/bording', ...)` |
| 2 | Confirm this route creates DB records | Yes — `StudentBoardingLog::create()` is called |
| 3 | GET requests can be cached, prefetched, or crawled | Risk: search engines, browser prefetch, proxy caches could trigger unwanted data creation |
| 4 | CSRF not required for GET | No CSRF token needed; any `<img>` or `<link>` tag could trigger creation |
| 5 | Should be changed to POST | Violates HTTP specification (GET must be safe/read-only) |

### TC-CR14: Gap — No Soft Delete/Restore/ForceDelete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Search `routes/web.php` for StudentBoardingController in delete/restore/forceDelete | Not found |
| 2 | Check `StudentBoardingController.php` for destroy/restore/forceDelete methods | Not present |
| 3 | Check model: `use SoftDeletes` | Trait is present, so `->delete()` would soft-delete |
| 4 | Check DDL: `$table->softDeletes()` | deleted_at column exists |
| 5 | Conclusion: Model CAN be soft-deleted but no UI/API exposes it | Dead code path |

### TC-CR15: Gap — Partial Validation in studentBordUnbordUpdate

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect validation at lines 101-105 | Only `id`, `boarding_route_id`, `unboarding_route_id` validated |
| 2 | Fields NOT validated: boarding_stop_id, boarding_time, unboarding_stop_id, unboarding_time, device_id | 5 fields passed directly to update() without rules |
| 3 | Risk: Invalid stop IDs, future dates, non-datetime strings could be stored | No data integrity check |

### TC-CR16: Gap — Blade .edit vs Controller .update Mismatch

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `index.blade.php` line 100 | Action `<th>` uses `@can('tenant.student.bording.edit')` |
| 2 | Inspect `index.blade.php` line 140 | Action `<td>` uses `@can('tenant.student.bording.edit')` |
| 3 | Inspect `TransportStudentBoardingPolicy.php` | Policy has `update()` method but NO `edit()` method |
| 4 | Inspect `config/permissionslist.php` line 13-31 | `$crud` includes `'edit'` (line 29) — SO `.edit` IS defined |
| 5 | Inspect `StudentBoardingController.php` | Controller uses `Gate::authorize('tenant.student.bording.update')` |
| 6 | Result: User with `.edit` permission sees buttons but gets 403 on both edit fetch and update. User with `.update` can access URLs directly but has no visible buttons. Real mismatch: `.edit` (blade gate) vs `.update` (controller gate) |

### TC-CR17: Gap — No Delete/Restore/ForceDelete Despite SoftDeletes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Same as TC-CR14 | Confirmed: No routes, no controller methods |
| 2 | SoftDeletes trait is useless without routes | Trait provides `->delete()`, `->restore()`, `->forceDelete()` but no code calls them |
| 3 | DDL `deleted_at` column is populated by `SoftDeletes` but only if explicit delete call is made | Column remains NULL forever |

### TC-CR18: Gap — No activityLog Calls

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Same as TC-CR02 | No activityLog in StudentBoardingController |
| 2 | Contrast with TripController which logs create, update, delete, restore, forceDelete | Missing audit trail |

### TC-CR19: Policy — Unused Permissions

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | List all methods in `TransportStudentBoardingPolicy.php` | viewAny, view, create, update, delete, restore, forceDelete, import, export, print, markBoarding, markAlighting, viewReports, generateBoardingPass |
| 2 | Cross-reference with `StudentBoardingController.php` | Only viewAny, create, update used |
| 3 | Cross-reference with blade views | Only `viewAny`, `create`, `edit` used |
| 4 | Unused methods: markBoarding, markAlighting, viewReports, generateBoardingPass, import, export, print | 7 methods with no caller |

### TC-CR20: Method Visibility Inconsistency

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check `tripBordUnbord()` visibility in `TripMgmtController.php` | `public function tripBordUnbord(...)` |
| 2 | Check other query helpers: `tripStopTimeline`, `TripQuery`, `incidentQuery`, `notificationLogQuery`, `SchedulerQuery`, `driverRouteVehicleQuery` | All `private function` |
| 3 | Reason for difference is unclear | All should be private for consistency |

### TC-CR21: Missing @empty in forelse

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `index.blade.php` line 126 | `@forelse($bordUnBordData as $i => $row)` |
| 2 | Check for `@empty` directive | NOT present |
| 3 | When no records: empty tbody renders | No "No records found" message to user |

### TC-CR22: Tab Filter Reset Uses Wrong URL

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `index.blade.php` line 63 | Reset link: `href="{{ url()->current() }}"` |
| 2 | `url()->current()` returns current URL WITHOUT query string | Example: `/transport/trip-management` |
| 3 | Without `?tab=student_bord_unbord`, clicking reset switches to default tab | User unexpectedly leaves the student boarding tab |
| 4 | Should use `route('transport.trip-management.index', ['tab' => 'student_bord_unbord'])` instead | Tab context preserved |

### TC-CR23: $driveAttendance Variable Name

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `TripMgmtController.php` line 79 | `$driveAttendance = AttendanceDevice::get();` |
| 2 | Inspect view usage in `model.blade.php` line 118 | `@foreach ($driveAttendance as $device)` |
| 3 | Variable holds AttendanceDevice records but name suggests driver attendance | Misleading but functional |

### TC-CR24: Model device() Relationship Mis-targeted

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `StudentBoardingLog.php` line 161-167 | `return $this->belongsTo(DriverAttendance::class, 'device_id');` |
| 2 | Check DDL: `device_id` FK → `tpt_attendance_device.id` | FK references `tpt_attendance_device` table |
| 3 | `DriverAttendance` model likely maps to `tpt_driver_attendance` table | **MISMATCH**: relationship targets wrong table |
| 4 | If `DriverAttendance` and `AttendanceDevice` are different models/table, this query silently fails or returns incorrect results | Potential data integrity issue |

### TC-CR25: $request->tripe_id Typo

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Search `StudentBoardingController.php` for `tripe_id` | Lines 56, 69, 70 — references `$request->tripe_id` |
| 2 | Search `TripMgmtController.php` for `tripe_id` | Lines 67, 70 — also references `$request->tripe_id` |
| 3 | Check routing: who sends `tripe_id`? | TripMgmtController merges it (line 67, 70) |
| 4 | No route/input ever naturally produces `tripe_id` param | It's always artificially merged by TripMgmtController as a typo of `trip_id` |
| 5 | Should be corrected to `trip_id` everywhere | Defensive fallback masks the root cause |

### TC-CR26: Unnecessary Eager Load

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `TripMgmtController.php` line 236 | `with(['studentSession.student'])` |
| 2 | Inspect `index.blade.php` line 133 | `{{ $row->student->first_name }}` — uses direct `student()` relationship, NOT `studentSession.student` |
| 3 | Eager load is wasted; DB still queries student() relation separately per row | N+1 queries for student data despite eager load |
| 4 | Should be: `with(['student'])` instead of `with(['studentSession.student'])` | Fix the eager load to match blade usage |

### TC-CR27: Missing Eager Loads for Deep Relationships

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Trace blade line 129: `$row->boardingTrip->routeScheduler->route->name` | 4 separate lazy-loaded queries: boardingTrip (1), routeScheduler (N), route (N) |
| 2 | Trace blade line 130: `$row->boardingTrip->tripStopDetail->stop->name` | 2 more lazy-loaded queries: tripStopDetail (N), stop (N) |
| 3 | With 10 rows per page: 1 (boardingTrip) + 10 (routeScheduler) + 10 (route) + 10 (tripStopDetail) + 10 (stop) = **41 extra queries** | Significant N+1 performance issue |
| 4 | Fix: Add eager loads: `with(['boardingTrip.routeScheduler.route', 'boardingTrip.tripStopDetail.stop'])` | Should be in `tripBordUnbord()` |

### TC-CR28: Unconditional Queries on Every Tab

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `TripMgmtController@index()` lines 73-80 | All queries run unconditionally regardless of active tab |
| 2 | `PickupPoint::get()`, `AttendanceDevice::get()` run even on driver_roster or scheduler tabs | Unnecessary DB load |
| 3 | These are only used by student_bord_unbord tab modals | Move into conditional loading |

### TC-CR29: Student Name Display Missing ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `index.blade.php` line 133 | `{{ $row->student->first_name }}` — only first name |
| 2 | Per CRUD UI Rule 7h: should be `{{ $student->first_name }} {{ $student->last_name }}<br><small class="text-muted">#{{ $student_id }}</small>` | Student ID and full name not shown |

### TC-CR30: JS — No Loading State on Edit Fetch

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click edit button with slow network | No loading indicator; modal appears empty until data loads |
| 2 | If AJAX fails, error toast shown but modal state unclear | Should disable button and show spinner during fetch |

### TC-CR31: JS — No Debounce on Add Button

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Rapidly click "Add" button 5 times | 5 duplicate GET requests sent |
| 2 | Each request creates logs independently | Potentially creates duplicate records if requests race past the exists check |
| 3 | No client-side debounce/throttle | Server-side has no unique constraint either — race condition can create duplicates |

### TC-CR32: Blade — Missing Trip ID Display Context

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Table shows student name but not trip ID or trip date | User cannot easily cross-reference the trip |
| 2 | Trip date is implied from filter but not displayed in row | Each row has trip_date but it's not shown |

---

## 8. CODE-TRACE: Execution Flow Analysis

### CODE-TRACE-01: Full Tab Load Flow

```
User clicks tab or navigates to ?tab=student_bord_unbord
  │
  ├─► 1. HTTP GET /transport/trip-management?tab=student_bord_unbord[&date=&shift_id=&route_id=]
  │
  ├─► 2. TripMgmtController@index() [TripMgmtController.php:36]
  │     ├─ Gate::authorize('tenant.transport.viewAny')  [line 38]
  │     │
  │     ├─ Find matching trip ID:  [line 54-63]
  │     │   TptTrip::where('trip_date', $request->date)
  │     │     ->whereHas('routeScheduler', fn($q) =>
  │     │         $q->where('shift_id', ...)->where('route_id', ...)
  │     │     )->first()
  │     │
  │     ├─ If trip found: merge trip_id + tripe_id into request [line 67]
  │     │   Else: merge null into both [line 70]
  │     │
  │     ├─ Load ALL reference data (unconditional):  [lines 73-80]
  │     │   Vehicle::get(), Route::get(), DriverHelper::get(),
  │     │   Shift::get(), SchoolClass::get(), PickupPoint::get(),
  │     │   AttendanceDevice::get(), OrganizationAcademicSession::get()
  │     │
  │     ├─ Execute ALL tab queries (unconditional):  [lines 83-90]
  │     │   tripStopTimeline(), tripStopNew(), TripQuery(),
  │     │   tripBordUnbord(), incidentQuery(), driverRouteVehicleQuery(),
  │     │   SchedulerQuery(), notificationLogQuery()
  │     │
  │     └─ Return view('transport::tab_module.tripmanagement', compact(...))  [line 92]
  │
  ├─► 3. Tripmanagement.blade.php renders with x-backend.tab.nav-tab  [line 9-52]
  │
  ├─► 4. Tab nav renders "Student Bord Unbord" if user has permission  [line 18]
  │     permission: 'tenant.student.bording.viewAny'
  │
  └─► 5. @can('tenant.student.bording.viewAny')  [line 40-42]
        └─ @include('transport::student-bord-unbord.index')
             │
             └─► 6. index.blade.php renders boarding log table
                   ├─ Filter form with hidden tab=student_bord_unbord  [line 11]
                   ├─ Table columns with permission-gated Action column  [lines 86-153]
                   └─ Pagination: $bordUnBordData->appends(['tab' => 'student_bord_unbord'])->links()
```

### CODE-TRACE-02: Bulk Create Boarding Logs (Add Button)

```
User clicks "Add" button (#addEntryBtns)
  │
  ├─► 1. JS: serialize #studentFilterForm → get route_id, shift_id, date, trip_id  [js.blade.php:6-7]
  │
  ├─► 2. JS Validation: route_id and shift_id required  [line 10-11]
  │     If missing → showToast("error", "Please select Route and Shift first!") — STOP
  │
  ├─► 3. AJAX GET /student/bording?route_id=X&shift_id=Y&date=Z&trip_id=W  [line 14-17]
  │
  ├─► 4. StudentBoardingController@studentBordingStore(Request)  [StudentBoardingController.php:28]
  │     ├─ Gate::authorize('tenant.student.bording.create')  [line 30]
  │     │   If fails → 403 Forbidden
  │     │
  │     ├─ NO validation of input params  [GAP]
  │     │
  │     ├─ TptStudentAllocationJnt::where('pickup_route_id', $request->route_id)->get()  [line 33-34]
  │     │   If empty → return {status: false, message: 'No student allocation found'}  [line 36-41]
  │     │
  │     ├─ Loop over each allocation:  [line 47]
  │     │   ├─ Skip if student_session_id is null  [line 49-51]
  │     │   ├─ Check exists: trip_date + student_session_id + boarding_trip_id  [line 54-58]
  │     │   │   If exists → skip++
  │     │   └─ Insert:  [line 65-72]
  │     │       StudentBoardingLog::create([
  │     │         'trip_date'          => $request->date,
  │     │         'student_id'         => $allocation->studentSessions->student_id ?? null,
  │     │         'student_session_id' => $allocation->student_session_id,
  │     │         'boarding_trip_id'   => $request->trip_id ?? $request->tripe_id,
  │     │         'unboarding_trip_id' => $request->trip_id ?? $request->tripe_id,
  │     │       ]);
  │     │       // NOTE: boarding_route_id, boarding_stop_id, boarding_time, 
  │     │       // unboarding_* fields, device_id NOT set on create
  │     │
  │     └─ Return JSON {status: true, message: '...', inserted: N, skipped: N}  [line 77-82]
  │
  ├─► 5. JS success callback:  [js.blade.php:19-45]
  │     If status=true AND inserted>0 → showToast("success", "Boarding entries created...")
  │     If status=true AND inserted=0 → showToast("info", "All boarding entries already exist.")
  │     If status=false → showToast("error", res.message)
  │
  └─► No page reload after store (unless manual)
```

### CODE-TRACE-03: Edit Boarding Log Flow

```
User clicks edit button (.editStopBtns)
  │
  ├─► 1. JS: SweetAlert confirmation dialog  [js.blade.php:79-87]
  │     "Sure to Edit?" → "Yes, proceed!" / "Cancel"
  │     If Cancel → STOP
  │
  ├─► 2. Get data-id from button  [line 90]
  │     If no id → console.error('Stop ID not found') — STOP
  │
  ├─► 3. AJAX GET /student/bord/unbord/edits?id=X  [line 97-101]
  │
  ├─► 4. StudentBoardingController@studentBordingEdit(Request)  [StudentBoardingController.php:85]
  │     ├─ Gate::authorize('tenant.student.bording.update')  [line 87]
  │     │   If fails → 403 Forbidden
  │     │
  │     ├─ StudentBoardingLog::where('id', $request->id)->first()  [line 89]
  │     │   Returns model or null (NOT 404)
  │     │
  │     └─ Return JSON {status: true, inserted: $studentLog}  [line 90-94]
  │         Even if null!
  │
  ├─► 5. JS success callback:  [js.blade.php:102-133]
  │     ├─ let data = res.inserted;
  │     ├─ Populate form fields:
  │     │   #edit_ids = data.id
  │     │   #edit_boarding_route_id = data.boarding_route_id
  │     │   #edit_boarding_stop_id = data.boarding_stop_id
  │     │   #edit_boarding_time = formatDateTimeLocal(data.boarding_time)
  │     │   #edit_unboarding_route_id = data.unboarding_route_id
  │     │   #edit_unboarding_stop_id = data.unboarding_stop_id
  │     │   #edit_unboarding_time = formatDateTimeLocal(data.unboarding_time)
  │     │   #edit_device_id = data.device_id
  │     │
  │     └─ Show modal: $('#editStudentBoardingModal').modal('show')  [line 133]
  │
  └─► If AJAX fails → showToast('error','Failed to load stop details')
```

### CODE-TRACE-04: Update Boarding Log Flow

```
User submits edit modal form (#editBoardingForms)
  │
  ├─► 1. JS: preventDefault(), collect form data  [js.blade.php:162-177]
  │     Data: _token, id, boarding_route_id, boarding_stop_id, boarding_time,
  │            unboarding_route_id, unboarding_stop_id, unboarding_time, device_id
  │
  ├─► 2. Disable submit button, AJAX POST /student/bord/updates  [line 179-182]
  │
  ├─► 3. StudentBoardingController@studentBordUnbordUpdate(Request)  [StudentBoardingController.php:97]
  │     ├─ Gate::authorize('tenant.student.bording.update')  [line 99]
  │     │   If fails → 403 Forbidden
  │     │
  │     ├─ Inline validation:  [line 101-105]
  │     │   ├─ id ⇒ required (passes)
  │     │   ├─ boarding_route_id ⇒ nullable|exists:tpt_route,id
  │     │   ├─ unboarding_route_id ⇒ nullable|exists:tpt_route,id
  │     │   └─ If fails → 422 with errors
  │     │
  │     ├─ Find log: StudentBoardingLog::where('id', $request->id)->first()  [line 107]
  │     │   If null → **500 CRASH** (update() on null)
  │     │
  │     ├─ Update:  [line 108-116]
  │     │   $log->update([
  │     │     'boarding_route_id'   => $request->boarding_route_id,
  │     │     'boarding_stop_id'    => $request->boarding_stop_id,
  │     │     'boarding_time'       => $request->boarding_time,
  │     │     'unboarding_route_id' => $request->unboarding_route_id,
  │     │     'unboarding_stop_id'  => $request->unboarding_stop_id,
  │     │     'unboarding_time'     => $request->unboarding_time,
  │     │     'device_id'           => $request->device_id,
  │     │   ]);
  │     │   // NOTE: trip_date, student_id, student_session_id, 
  │     │   // boarding_trip_id, unboarding_trip_id NOT updated
  │     │
  │     └─ Return JSON {status: true, message: '...'}  [line 118-121]
  │
  ├─► 4. JS success callback:  [js.blade.php:186-197]
  │     ├─ showToast('success', 'Updated successfully')
  │     ├─ Hide modal: $('#editStudentBoardingModal').modal('hide')
  │     └─ location.reload() — full page reload
  │
  └─► If AJAX fails:
        ├─ 422: loop validation errors → showToast each
        └─ Other: showToast('error', 'Something went wrong')
```

### CODE-TRACE-05: tripBordUnbord Query Construction

```
tripBordUnbord(Request $request)  [TripMgmtController.php:234-249]
  │
  ├─ Base query:
  │   StudentBoardingLog::with(['studentSession.student'])->orderBy('id')
  │
  ├─ Tab guard: if ($tab === 'student_bord_unbord')  [line 240]
  │   ├─ if trip_id IS present [line 241-242]:
  │   │   $query->where('boarding_trip_id', $request->trip_id)
  │   │   // NOTE: Only checks $request->trip_id, NOT $request->tripe_id
  │   │   // NOTE: Does NOT filter by unboarding_trip_id
  │   │
  │   └─ elseif date IS present [line 243-244]:
  │       $query->where('trip_date', $request->date)
  │       // NOTE: Mutually exclusive with trip_id filter
  │       // If BOTH exist, ONLY trip_id filter applies; date ignored
  │
  └─ Return $query  [line 248]
      // If neither trip_id nor date: UNFILTERED — ALL records returned
```

### CODE-TRACE-06: Data Dependency Chain

```
tpt_student_route_allocation_jnt (SOURCE)
  │  pickup_route_id ─────────────► tpt_route.id
  │  student_session_id ──────────► std_student_academic_sessions.id
  │       └─ student_id ─────────► std_students.id
  │
  ▼  studentBordingStore() reads from JNT to populate:
  │
tpt_student_boarding_log (TARGET)
  │  boarding_trip_id ───────────► tpt_trip.id
  │       └─ route_scheduler_id ─► tpt_route_scheduler_jnt.id
  │            └─ route_id ──────► tpt_route.id
  │            └─ shift_id ──────► shift.id
  │            └─ driver_id ─────► driver_helper.id
  │            └─ vehicle_id ────► vehicle.id
  │  boarding_route_id ──────────► tpt_route.id
  │  boarding_stop_id ───────────► tpt_pickup_points.id
  │  unboarding_route_id ────────► tpt_route.id
  │  unboarding_stop_id ─────────► tpt_pickup_points.id
  │  device_id ──────────────────► tpt_attendance_device.id
  │  student_id ─────────────────► std_students.id
  │  student_session_id ─────────► std_student_academic_sessions.id
  │
  ▼  tripStopDetail (accessed via boardingTrip->tripStopDetail)
  │
tpt_trip_stop_detail
  │  stop_id ────────────────────► tpt_pickup_points.id
  └─ trip_id ────────────────────► tpt_trip.id
```

### CODE-TRACE-07: Race Condition Window in Bulk Create

```
Concurrent Request A ──────────────┐        Concurrent Request B ──────────────┐
                                   │                                         │
  GET /student/bording?route_id=5  │         GET /student/bording?route_id=5  │
  (same date, same trip_id)         │         (same date, same trip_id)        │
                                   │                                         │
  Step A1: Query allocations        │         Step B1: Query allocations       │
  → 2 records found                │         → 2 records found                │
                                   │                                         │
  Step A2: Check exists for student1│         Step B2: Check exists for stud1  │
  → NOT exists → create            │         → NOT exists (A hasn't written)  │
                                   │         → ALSO creates!                  │
  Step A3: Check exists for student2│                                         │
  → NOT exists → create            │         Step B3: Check exists for stud2  │
                                   │         → NOT exists → create            │
                                   │         → ALSO creates!                  │
  Step A4: INSERT student_1_log     │                                         │
  Step A5: INSERT student_2_log     │         Step B4: INSERT student_1_log    │
                                   │         → DUPLICATE ENTRY!               │
                                   │         Step B5: INSERT student_2_log    │
                                   │         → DUPLICATE ENTRY!               │
                                                                              
  RESULT: 4 records instead of 2    │
  DB has NO unique constraint to     │
  prevent this                      │
```

---

## 9. Gap Analysis Summary

| Gap ID | Severity | Category | Description | Component | Impact |
|--------|----------|----------|-------------|-----------|--------|
| GAP-01 | CRITICAL | Security | GET used for DB mutation (studentBordingStore) | Routes/Controller | CSRF not required; browser prefetch/crawlers can create data |
| GAP-02 | HIGH | Stability | update() on null causes 500 error | Controller | Invalid ID crashes with no error handling |
| GAP-03 | HIGH | Data | No activityLog calls — operations not auditable | Controller | Cannot trace who created/updated boarding logs |
| GAP-04 | HIGH | Data | No delete/restore/forceDelete routes despite SoftDeletes | Routes/Controller | Records can never be removed; dead code path |
| GAP-05 | HIGH | Permission | `.edit` vs `.update` mismatch between blade and controller | Blade/Controller | Users with one permission but not the other experience broken UX |
| GAP-06 | MEDIUM | Validation | No validation on studentBordingStore input (route_id, date, trip_id) | Controller | Invalid/malicious input accepted silently |
| GAP-07 | MEDIUM | Validation | Only 2 of 7 update fields have validation rules | Controller | Invalid data can be stored in 5 fields |
| GAP-08 | MEDIUM | Validation | Inline validation instead of FormRequest | Controller | Not reusable; violates project pattern |
| GAP-09 | MEDIUM | Performance | Unnecessary eager load (studentSession.student) not matching blade usage | Controller/Blade | Wasted query; plus N+1 for boardingTrip chain |
| GAP-10 | MEDIUM | Performance | 4+ level deep lazy-loaded relationships cause 41+ extra queries per page | Controller/Blade | Significant N+1 performance issue |
| GAP-11 | MEDIUM | Performance | Unconditional queries (PickupPoint, AttendanceDevice) on every tab | Controller | Redundant DB load when viewing other tabs |
| GAP-12 | MEDIUM | UI/UX | No `@empty` handler in forelse — empty state not shown | Blade | Empty table renders with no message |
| GAP-13 | LOW | UI/UX | Tab reset link loses tab context | Blade | User unexpectedly leaves boarding tab |
| GAP-14 | LOW | UI/UX | Student name displayed without student ID | Blade | Violates CRUD UI Rule 7h |
| GAP-15 | LOW | UI/UX | Modal uses `btn-sm` on submit button | Blade | Violates CRUD UI Rule 4 |
| GAP-16 | MEDIUM | Correctness | Model `device()` relationship targets wrong model (DriverAttendance vs AttendanceDevice) | Model | Wrong DB table joined; possible incorrect results |
| GAP-17 | LOW | Correctness | `$request->tripe_id` typo perpetuated in both controllers | Controller | Should be fixed to `trip_id` |
| GAP-18 | LOW | Consistency | `tripBordUnbord()` is public while all other query helpers are private | Controller | Inconsistent encapsulation |
| GAP-19 | LOW | Consistency | `$driveAttendance` variable name misleading | Controller/Blade | Variable named for driver attendance holds device records |
| GAP-20 | MEDIUM | Race Condition | No DB unique constraint on (trip_date, student_session_id, boarding_trip_id) | DB/Controller | Concurrent requests can create duplicate records |
| GAP-21 | LOW | JS | No debounce on Add button — rapid clicks cause duplicate requests | JS | Exacerbates race condition (GAP-20) |
| GAP-22 | LOW | JS | No loading state on edit fetch | JS | No visual feedback during AJAX |
| GAP-23 | MEDIUM | Reliability | `studentBordingEdit` returns `status: true` with null data | Controller | Frontend tries to access properties of null |
| GAP-24 | LOW | Data | Allocations filtered only by pickup_route_id; drop allocations ignored | Controller | Drop-only students never get boarding logs |
| GAP-25 | MEDIUM | Filter | `tripBordUnbord()` doesn't check `tripe_id` fallback | Controller | Filter silently ignored when request has tripe_id instead of trip_id |
| GAP-26 | LOW | Filter | No limit guard when neither trip_id nor date provided | Controller | Full table scan on large datasets |
| GAP-27 | LOW | Policy | 7 unused permission methods in TransportStudentBoardingPolicy | Policy | Dead code; increases maintenance surface |

---

## 10. Technical Debt Register

| TDR ID | Item | Effort | Priority | Remediation |
|--------|------|--------|----------|-------------|
| TDR-01 | Change `Route::get('student/bording', ...)` to `Route::post(...)` | 1h | CRITICAL | Update route, controller method name, AJAX call, and CSRF handling |
| TDR-02 | Add try-catch with proper error response in studentBordUnbordUpdate | 30m | HIGH | Wrap update in try-catch; return 404 JSON response for invalid ID |
| TDR-03 | Add activityLog calls to all 4 controller methods | 1h | HIGH | Add activityLog() after create and update operations |
| TDR-04 | Add FormRequest validation for studentBordingStore | 2h | HIGH | Create StudentBoardingStoreRequest with rules for route_id, date, trip_id |
| TDR-05 | Add FormRequest validation for studentBordUnbordUpdate | 2h | HIGH | Create StudentBoardingUpdateRequest with validation for all 7 fields |
| TDR-06 | Align blade permission: change `@can('...edit')` to `@can('...update')` | 30m | HIGH | Keep consistent with controller Gate::authorize |
| TDR-07 | Add restore/forceDelete/destroy routes and controller methods | 3h | HIGH | Implement standard CRUD resource pattern matching SoftDeletes trait |
| TDR-08 | Fix eager loading: `with(['student', 'boardingTrip.routeScheduler.route', 'boardingTrip.tripStopDetail.stop'])` | 1h | MEDIUM | Replace `with(['studentSession.student'])` with correct relations |
| TDR-09 | Add conditional loading: move PickupPoint::get(), AttendanceDevice::get() behind tab check | 1h | MEDIUM | Only load when tab=student_bord_unbord |
| TDR-10 | Fix model device() relationship to target AttendanceDevice | 1h | MEDIUM | Change `belongsTo(DriverAttendance::class)` to `belongsTo(AttendanceDevice::class)` |
| TDR-11 | Remove `$request->tripe_id` references throughout | 1h | MEDIUM | Replace with consistent `$request->trip_id` |
| TDR-12 | Add DB unique constraint on (trip_date, student_session_id, boarding_trip_id) | 1h | MEDIUM | Add migration with $table->unique() |
| TDR-13 | Change `tripBordUnbord()` visibility to `private` | 5m | LOW | Make consistent with other query helpers |
| TDR-14 | Add @empty handler in blade forelse | 15m | LOW | Add `<tr><td colspan="12" class="text-center">No records found</td></tr>` |
| TDR-15 | Fix filter reset link to preserve tab context | 15m | LOW | Use `route('transport.trip-management.index', ['tab' => 'student_bord_unbord'])` |
| TDR-16 | Update student name display per CRUD UI Rule 7h | 15m | LOW | Add full name + student ID below |
| TDR-17 | Remove unused policy methods | 30m | LOW | Remove markBoarding, markAlighting, viewReports, generateBoardingPass from policy |
| TDR-18 | Add JS debounce on Add button | 30m | LOW | Disable button during AJAX; prevent rapid re-click |
| TDR-19 | Add JS loading state on edit fetch | 15m | LOW | Show spinner/disable button during fetch |
| TDR-20 | Fix studentBordingEdit to return status:false when log not found | 15m | LOW | Check for null and return 404 response |
| TDR-21 | Add trip ID column to blade table for context | 15m | LOW | Show boarding_trip_id in each row |
| TDR-22 | Rename $driveAttendance to $attendanceDevices | 15m | LOW | Meaningful variable name |

---

## 11. Dependency Tree

```
tpt_student_boarding_log
├── relies on: tpt_student_route_allocation_jnt (source for bulk create)
│   ├── relies on: tpt_route (pickup_route_id FK)
│   ├── relies on: std_student_academic_sessions (student_session_id FK)
│   └── relies on: std_students (student_id FK via academic session)
├── relies on: tpt_trip (boarding_trip_id / unboarding_trip_id FK)
│   ├── relies on: tpt_route_scheduler_jnt (route_scheduler_id FK)
│   │   ├── relies on: tpt_route (route_id FK)
│   │   ├── relies on: shift (shift_id FK)
│   │   ├── relies on: driver_helper (driver_id FK)
│   │   └── relies on: vehicle (vehicle_id FK)
│   └── relies on: tpt_trip_stop_detail (trip_id FK, stop context)
│       └── relies on: tpt_pickup_points (stop_id FK)
├── relies on: tpt_route (boarding_route_id / unboarding_route_id FK)
├── relies on: tpt_pickup_points (boarding_stop_id / unboarding_stop_id FK)
├── relies on: tpt_attendance_device (device_id FK)
└── relies on: std_students (student_id FK)
```

---

## 12. Route Map Summary

| Method | URL | Controller Method | Route Name | Purpose |
|--------|-----|-------------------|------------|---------|
| GET | `/student/bording` | `studentBordingStore` | `transport.student.bording.store` | Bulk create boarding logs from allocations |
| GET | `/student/bord/unbord/edits` | `studentBordingEdit` | `transport.student.bord.unbord.edits` | Fetch single log for editing |
| POST | `/student/bord/updates` | `studentBordUnbordUpdate` | `transport.student.bord.updates` | Update boarding/unboarding details |
| (any) | `/transport/trip-management` | `TripMgmtController@index` | `transport.trip-management.index` | Tab container — houses student_bord_unbord tab |

---

## 13. Known Bug Tracker

| Bug ID | Severity | Description | Affected File(s) |
|--------|----------|-------------|------------------|
| BUG-001 | CRITICAL | GET method creates DB records (violates HTTP spec) | `web.php:171`, `StudentBoardingController.php:28-83` |
| BUG-002 | HIGH | `studentBordUnbordUpdate()` crashes with 500 on invalid ID | `StudentBoardingController.php:107-108` |
| BUG-003 | HIGH | No audit trail for boarding operations | `StudentBoardingController.php` (entire file) |
| BUG-004 | HIGH | Blade permission `.edit` vs Controller permission `.update` mismatch | `index.blade.php:100,140`, `StudentBoardingController.php:87,99` |
| BUG-005 | HIGH | SoftDeletes model has no delete/restore/forceDelete routes | `web.php`, `StudentBoardingController.php` |
| BUG-006 | MEDIUM | Model `device()` relation targets wrong model/table | `StudentBoardingLog.php:161-167` |
| BUG-007 | MEDIUM | `studentBordingEdit()` returns `status:true` with null data | `StudentBoardingController.php:89-94` |
| BUG-008 | MEDIUM | `tripe_id` typo creates hidden dependency | `StudentBoardingController.php:56,69,70`, `TripMgmtController.php:67,70` |
| BUG-009 | MEDIUM | No DB unique constraint — race condition can duplicate records | DDL/tpt_student_boarding_log migration |
| BUG-010 | MEDIUM | `tripBordUnbord()` does not check `tripe_id` fallback | `TripMgmtController.php:241` |
| BUG-011 | LOW | Blade filter reset link loses tab context | `index.blade.php:63` |
| BUG-012 | LOW | Missing `@empty` handler in forelse | `index.blade.php:126-150` |
| BUG-013 | LOW | N+1 queries for deeply nested relationships (41+ extra Q per page) | `index.blade.php:129-130` |
| BUG-014 | LOW | Unnecessary eager load (`studentSession.student`) not matching blade usage | `TripMgmtController.php:236` |
| BUG-015 | LOW | `$driveAttendance` variable name misrepresents its contents | `TripMgmtController.php:79` |

---

## 14. Security Analysis

| SEC ID | Threat | Vector | Impact | Existing Mitigation | Recommendation |
|--------|--------|--------|--------|-------------------|----------------|
| SEC-01 | CSRF Bypass on Bulk Create | `studentBordingStore` uses GET; no CSRF token required | Attacker can craft `<img src="/student/bording?route_id=5&date=...&trip_id=...">` on any page to trigger boarding log creation for any logged-in user who views the page | None — GET requests bypass CSRF middleware entirely | Change to POST route with CSRF protection |
| SEC-02 | Mass Boarding Log Creation | No rate limiting on `studentBordingStore` | Attacker can create thousands of boarding logs by repeatedly calling GET | None | Add rate limiting; convert to POST with proper throttling |
| SEC-03 | Missing Authorization in Blade Filter | Unauthorized users can brute-force trip filtering | Sensitive trip data visible if tab permissions misconfigured | Tab has `@can` guard on both nav and include | Keep double-layer permission; add Gate::any() check in controller for all tab permissions |
| SEC-04 | IDOR — Log Viewing by ID | `studentBordingEdit` accepts any ID without ownership check | Any authenticated user with `.update` permission can view any boarding log | Gate::authorize('update') limits by role but not by data ownership | Add ownership/filter check if multi-tenant data isolation is required |
| SEC-05 | Mass Assignment — Unvalidated Fields | `studentBordUnbordUpdate` passes 5 unvalidated fields directly to `$log->update()` | Attacker can inject arbitrary data types, future dates, or SQL injection attempts | `$fillable` whitelist on model prevents injection of non-fillable fields | Add explicit validation rules for all 7 fields |
| SEC-06 | SQL Injection via null trip_id | No input validation; raw request values used in WHERE clauses | `$request->route_id` used directly in `where('pickup_route_id', $request->route_id)` without casting to int | Eloquent's parameter binding prevents SQL injection |  Low risk but should cast to int for type safety |
| SEC-07 | Permission Enumeration | Different error messages for 403 (no permission) vs empty data | Attacker can distinguish "no permission to create" from "no allocations exist" | Response messages differ — `{status: false, message: 'No student allocation...'}` vs 403 `This action is unauthorized.` | Keep messages generic; avoid revealing existence of data |
| SEC-08 | No Logging of Admin Actions | Operations not recorded in activity_log | Admins could create/edit boarding logs without trace | None | Add activityLog() calls |

---

## 15. Integration Points Analysis

| INT ID | Integration | Direction | Data Exchanged | Failure Impact |
|--------|-------------|-----------|----------------|---------------|
| INT-01 | StudentProfile Module (std_students) | Read | Student name, student_id FK in boarding log | Broken FK reference → student_id=NULL → student name not displayed |
| INT-02 | StudentProfile Module (std_student_academic_sessions) | Read | Academic session info; source of student_id in bulk create | Null student_id stored if relation fails |
| INT-03 | Transport Module — Trip (tpt_trip) | Read | Trip context for boarding log; trip_id FK | Grid filtering broken; N+1 queries for trip details |
| INT-04 | Transport Module — Route (tpt_route) | Read | Route names for boarding/unboarding dropdown; FK references | Dropdown shows empty; Route names missing in grid |
| INT-05 | Transport Module — PickupPoint (tpt_pickup_points) | Read | Stop names for boarding/unboarding dropdown | Dropdown shows empty; Stop names missing in grid |
| INT-06 | Transport Module — AttendanceDevice (tpt_attendance_device) | Read | Device names for modal dropdown | Model `device()` relationship targets wrong model — possible incorrect data |
| INT-07 | Transport Module — RouteScheduler (tpt_route_scheduler_jnt) | Read (through Trip) | Route name, shift context for grid display | N+1 queries; grid columns show empty if relation fails |
| INT-08 | Transport Module — TripStopDetail (tpt_trip_stop_detail) | Read (through Trip) | Stop arrival/departure times for grid display | N+1 queries; times show empty if relation fails |
| INT-09 | Transport Module — TptStudentAllocationJnt | Read | Source data for bulk create boarding logs | No records created if allocation setup incomplete |
| INT-10 | Transport Module — TripMgmtController index() | Tab container | Date/shift/route filters → resolved trip_id | If trip resolution fails, grid shows ALL records unfiltered |

---

## 16. CODE-TRACE: JavaScript Flow Analysis

### CODE-TRACE-08: Add Button AJAX Call — Full Trace

```
js.blade.php #addEntryBtns.click handler
  │
  ├─► 1. Get filter form: $('#studentFilterForm')  [line 6]
  │
  ├─► 2. Serialize form: form.serialize()  [line 7]
  │     Produces: tab=student_bord_unbord&date=2026-07-21&shift_id=2&route_id=5&pickup_drop=Pickup&trip_id=100
  │
  ├─► 3. Client-side validation:  [line 10-12]
  │     ├─ Checks: form.find('select[name="route_id"]').val()
  │     ├─ Checks: form.find('select[name="shift_id"]').val()
  │     └─ If either empty → showToast("error", "Please select Route and Shift first!") — STOP
  │     NOTE: Does NOT check 'date' or 'trip_id'
  │
  ├─► 4. AJAX GET:  [line 14-17]
  │     url: "{{ route('transport.student.bording.store') }}"  → /student/bording
  │     type: "GET"
  │     data: formData (serialized filter form)
  │
  ├─► 5. Success handler:  [line 18-45]
  │     ├─ res.status === true:
  │     │   ├─ res.inserted > 0: showToast("success", "Boarding entries created... Added: N, Skipped: N")
  │     │   └─ res.inserted = 0: showToast("info", "All boarding entries already exist.")
  │     └─ res.status === false:
  │         └─ showToast("error", res.message)
  │
  ├─► 6. Error handler:  [line 47-53]
  │     ├─ Tries xhr.responseJSON?.message
  │     └─ Falls back to "Server error occurred..."
  │
  └─► 7. Complete handler:  [line 55-57]
        └─ Re-enable button: $btn.prop('disabled', false)
        NOTE: $btn variable is never defined! ReferenceError in console
```

### CODE-TRACE-09: Edit Button — SweetAlert to Modal Flow

```
js.blade.php .editStopBtns click handler (delegated)
  │
  ├─► 1. preventDefault()  [line 76]
  │
  ├─► 2. Show SweetAlert confirmation:  [line 79-87]
  │     icon: 'warning'
  │     confirmButtonColor: '#3085d6',
  │     cancelButtonColor: '#d33',
  │     Title: "Sure to Edit?"
  │     Text: "Do you want to proceed to edit?"
  │     ├─ If Cancel → STOP (no further action)
  │     └─ If confirmed:
  │
  ├─► 3. Get data-id: $(this).data('id')  [line 90]
  │     ├─ If undefined/null → console.error('Stop ID not found') — STOP
  │     └─ If valid:
  │
  ├─► 4. AJAX GET:  [line 97-101]
  │     url: "{{ route('transport.student.bord.unbord.edits') }}" → /student/bord/unbord/edits
  │     type: "GET"
  │     data: { id: id }
  │
  ├─► 5. Success handler:  [line 102-133]
  │     ├─ let data = res.inserted;   // COULD BE NULL (BUG-007)
  │     ├─ Populate hidden ID: $('#edit_ids').val(data.id)
  │     ├─ Populate Boarding fields:
  │     │   ├─ $('#edit_boarding_route_id').val(data.boarding_route_id ?? '')
  │     │   ├─ $('#edit_boarding_stop_id').val(data.boarding_stop_id ?? '')
  │     │   └─ $('#edit_boarding_time').val(formatDateTimeLocal(data.boarding_time))
  │     ├─ Populate Unboarding fields:
  │     │   ├─ $('#edit_unboarding_route_id').val(data.unboarding_route_id ?? '')
  │     │   ├─ $('#edit_unboarding_stop_id').val(data.unboarding_stop_id ?? '')
  │     │   └─ $('#edit_unboarding_time').val(formatDateTimeLocal(data.unboarding_time))
  │     ├─ Populate Device: $('#edit_device_id').val(data.device_id ?? '')
  │     └─ Show modal: $('#editStudentBoardingModal').modal('show')
  │
  └─► 6. Error handler:  [line 135-138]
        └─ console.error(xhr.responseText)
        └─ showToast('error','Failed to load stop details')
```

### CODE-TRACE-10: Update Form Submit — Full AJAX Cycle

```
js.blade.php #editBoardingForms submit handler
  │
  ├─► 1. preventDefault()  [line 162]
  │
  ├─► 2. Build formData object from modal form fields:  [line 164-177]
  │     {
  │       _token: "{{ csrf_token() }}",
  │       id: $('#edit_ids').val(),
  │       boarding_route_id: $('#edit_boarding_route_id').val(),
  │       boarding_stop_id: $('#edit_boarding_stop_id').val(),
  │       boarding_time: $('#edit_boarding_time').val(),
  │       unboarding_route_id: $('#edit_unboarding_route_id').val(),
  │       unboarding_stop_id: $('#edit_unboarding_stop_id').val(),
  │       unboarding_time: $('#edit_unboarding_time').val(),
  │       device_id: $('#edit_device_id').val()
  │     }
  │
  ├─► 3. beforeSend: disable submit button  [line 183-185]
  │     $('.btn-success').prop('disabled', true)
  │
  ├─► 4. AJAX POST:  [line 179-182]
  │     url: "{{ route('transport.student.bord.updates') }}" → /student/bord/updates
  │     type: "POST"
  │     data: formData
  │
  ├─► 5. Success handler:  [line 186-197]
  │     ├─ res.status true:
  │     │   ├─ showToast('success', res.message)
  │     │   ├─ Hide modal
  │     │   └─ location.reload() — FULL PAGE RELOAD
  │     └─ res.status false: showToast('error', res.message)
  │
  ├─► 6. Error handler (422 validation):  [line 199-209]
  │     ├─ If 422: parse errors object
  │     │   Object.values(errors).forEach(msg => showToast('error', msg[0]))
  │     └─ Other: showToast('error', 'Something went wrong')
  │
  └─► 7. Complete handler:  [line 211-213]
        └─ $('.btn-success').prop('disabled', false)
```

### CODE-TRACE-11: formatDateTimeLocal() — Date Conversion

```
formatDateTimeLocal(datetime)  [js.blade.php:145-157]
  │
  ├─ Input: datetime string (e.g., "2026-07-21 07:30:00" from MySQL)
  │
  ├─ Step 1: if (!datetime) return ''  [line 146]
  │   └─ Null/undefined/empty returns empty string
  │
  ├─ Step 2: new Date(datetime)  [line 148]
  │   └─ JS Date parsing — may produce unexpected results for non-standard formats
  │   NOTE: MySQL DATETIME format "YYYY-MM-DD HH:MM:SS" is NOT ISO 8601
  │   Safari/iOS may fail to parse "2026-07-21 07:30:00" (needs "T" separator)
  │   Returns "Invalid Date" on some browsers
  │
  ├─ Step 3: Extract components  [line 150-154]
  │   ├─ yyyy = date.getFullYear()
  │   ├─ mm = String(date.getMonth() + 1).padStart(2, '0')
  │   ├─ dd = String(date.getDate()).padStart(2, '0')
  │   ├─ hh = String(date.getHours()).padStart(2, '0')
  │   └─ ii = String(date.getMinutes()).padStart(2, '0')
  │
  └─ Output: "${yyyy}-${mm}-${dd}T${hh}:${ii}"  [line 156]
      └─ e.g., "2026-07-21T07:30" — valid datetime-local input
      NOTE: Seconds are stripped (00 always lost)
```

### CODE-TRACE-12: TripMgmtController — Trip ID Resolution Logic

```
TripMgmtController@index() — Trip Resolution  [lines 54-71]
  │
  ├─ Input: $request->date, $request->shift_id, $request->route_id
  │
  ├─ Query:  [line 54-63]
  │   TptTrip::where('trip_date', $request->date)
  │     ->whereHas('routeScheduler', fn($q) =>
  │         $q->where('shift_id', $request->shift_id)
  │           ->where('route_id', $request->route_id)
  │     )
  │     ->first()
  │
  ├─ If trip FOUND:  [line 66-68]
  │   ├─ $tripId = true
  │   ├─ $request->merge(['trip_id' => $tripIds->id])
  │   └─ $request->merge(['tripe_id' => $tripIds->id])
  │   NOTE: Both 'trip_id' and 'tripe_id' are set to the same value
  │
  ├─ If trip NOT FOUND (null):  [line 69-71]
  │   ├─ $tripId = false
  │   ├─ $request->merge(['trip_id' => null])
  │   └─ $request->merge(['tripe_id' => null])
  │
  └─ Result:
      ├─ tripBordUnbord() checks $request->filled('trip_id')  → false if null → falls to elseif(date)
      └─ boarding store checks $request->trip_id ?? $request->tripe_id → both null → stores null
```

---

## 17. CODE-TRACE: Blade Rendering Analysis

### CODE-TRACE-13: index.blade.php — Column Rendering Matrix

```
Table Structure — Index Partial  [index.blade.php:86-153]
  │
  ├─ Row 1: <tr class="table-warning fw-bold">
  │   ├─ <th rowspan="2">Ord.<br>No.</th>             → Always rendered
  │   ├─ <th colspan="5">Scheduled Detail</th>          → 5 columns: Route, Stop Name, Arrival Time, Departure Time, Student Name
  │   ├─ <th colspan="6">Actual Boarding Detail</th>   → 6 columns: Boarding Route, Boarding Stop, Board Time, Un-Board Route, Un-Board Stop, Un-Board Time
  │   └─ @can('tenant.student.bording.edit')
  │       <th rowspan="2">Action</th>                   → 1 action column (permission-gated)
  │       @endcan
  │
  ├─ Row 2: <tr class="table-warning fw-bold">
  │   ├─ (none for Ord.No.)
  │   ├─ <th>Route</th>, <th>Stop Name</th>, <th>Arrival Time</th>, <th>Departure Time</th>, <th>Student Name</th>
  │   ├─ <th>Boarding Route</th>, <th>Boarding Stop</th>, <th>Board Time</th>, <th>Un-Board Route</th>, <th>Un-Board Stop</th>, <th>Un-Board Time</th>
  │   └─ (none for Action — rowspan=2 covers it)
  │
  ├─ Data Row (per record):
  │   ├─ <td>{{ $i+1 }}</td>                             → Ordinal (1-indexed)
  │   ├─ <td>{{ boardingTrip->routeScheduler->route->name }}</td> → [N+1] 4 levels deep
  │   ├─ <td>{{ boardingTrip->tripStopDetail->stop->name }}</td>  → [N+1] 4 levels deep
  │   ├─ <td>{{ boardingTrip->tripStopDetail->sch_arrival_time }}</td> → [N+1]
  │   ├─ <td>{{ boardingTrip->tripStopDetail->sch_departure_time }}</td> → [N+1]
  │   ├─ <td>{{ student->first_name }}</td>              → [N+1] direct relation
  │   ├─ <td>{{ boardingRoute->name }}</td>              → [N+1] direct relation
  │   ├─ <td>{{ boardingStop->name }}</td>               → [N+1] direct relation
  │   ├─ <td>{{ boarding_time }}</td>                    → Direct column (no DB query)
  │   ├─ <td>{{ unboardingRoute->name }}</td>            → [N+1] direct relation
  │   ├─ <td>{{ unboardingStop->name }}</td>             → [N+1] direct relation
  │   └─ <td>{{ unboarding_time }}</td>                  → Direct column (no DB query)
  │
  └─ Action cell:
      └─ @can('tenant.student.bording.edit')
          <button class="editStopBtns" data-id="{{ $row->id }}"> → Edit icon button
          @endcan
```

### CODE-TRACE-14: model.blade.php — Modal Form Field Map

```
#editStudentBoardingModal  [model.blade.php:1-145]
  │
  ├─ TYPE: Bootstrap 5 modal (modal-lg modal-dialog-centered)
  │
  ├─ Form: #editBoardingForms  [line 14]
  │   ├─ Hidden: @csrf + <input name="id" id="edit_ids">  [line 15-16]
  │   │
  │   ├─ Section: "Boarding Details"  [line 22-65]
  │   │   ├─ Select: boarding_route_id → options from $routes
  │   │   ├─ Select: boarding_stop_id → options from $pickupPoints
  │   │   └─ Input (datetime-local): boarding_time
  │   │
  │   ├─ Section: "Un-Boarding Details"  [line 67-110]
  │   │   ├─ Select: unboarding_route_id → options from $routes
  │   │   ├─ Select: unboarding_stop_id → options from $pickupPoints
  │   │   └─ Input (datetime-local): unboarding_time
  │   │
  │   └─ Section: Device  [line 112-124]
  │       └─ Select: device_id → options from $driveAttendance  [variable name confusion]
  │
  └─ Footer:  [line 130-141]
      ├─ Cancel button (btn-secondary btn-sm, data-bs-dismiss)
      └─ Update button (btn-success btn-sm) — NOTE: btn-sm violates CRUD UI Rule 4
```

### CODE-TRACE-15: TripMgmtController — Boarding Tab Query Execution Context

```
Full Tab Execution Context (student_bord_unbord)
  │
  ├─ 1. TripMgmtController@index() receives request
  │
  ├─ 2. Trip Resolution (lines 54-71):
  │     └─ Finds first trip matching date+shift+route
  │         └─ Merges trip_id into request
  │
  ├─ 3. Load ALL reference data (lines 73-80):
  │     └─ Includes PickupPoint::get() and AttendanceDevice::get()
  │         └─ These are needed by model.blade.php for dropdowns
  │
  ├─ 4. Execute tripBordUnbord() (line 86):
  │     ├─ Eager load: with(['studentSession.student'])
  │     ├─ Filter: by trip_id (primary) OR date (fallback)
  │     └─ Order: orderBy('id')
  │
  ├─ 5. Pass to view:
  │     $bordUnBordData (paginated query result)
  │     $pickupPoints (for modal dropdown)
  │     $driveAttendance (for modal dropdown)
  │     $routes (for modal dropdown)
  │     $tripIds (for readonly trip_id display)
  │
  └─ 6. View renders tripmanagement.blade.php
        └─ @include('transport::student-bord-unbord.index')
            └─ Uses $bordUnBordData, $routes, $pickupPoints, $driveAttendance, $tripIds
```

### CODE-TRACE-16: Gate Authorization Chain

```
Authorization Decision Tree
  │
  ├─ User navigates to /transport/trip-management
  │   │
  │   ├─ TripMgmtController@index()
  │   │   └─ Gate::authorize('tenant.transport.viewAny')
  │   │       ├─ PASS → continues to render page
  │   │       └─ FAIL → 403 Forbidden, page does not load
  │   │
  │   └─ Page renders tripmanagement.blade.php
  │       │
  │       ├─ x-backend.tab.nav-tab checks PER-TAB permission:
  │       │   └─ 'tenant.student.bording.viewAny'
  │       │       ├─ HAS permission → tab nav link is VISIBLE
  │       │       └─ NO permission → tab nav link is HIDDEN
  │       │
  │       └─ @can('tenant.student.bording.viewAny')
  │           └─ @include('transport::student-bord-unbord.index')
  │               ├─ HAS permission → tab body RENDERED
  │               └─ NO permission → tab body SKIPPED (empty)
  │
  ├─ User clicks "Add" button on boarding tab
  │   └─ studentBordingStore()
  │       └─ Gate::authorize('tenant.student.bording.create')
  │           ├─ HAS permission → creates logs
  │           └─ NO permission → 403 Forbidden (but "Add" button hidden by @can in blade)
  │
  └─ User clicks "Edit" button on a row
      ├─ studentBordingEdit() → Gate::authorize('tenant.student.bording.update')
      │   ├─ HAS permission → returns JSON data
      │   └─ NO permission → 403 Forbidden
      │
      └─ studentBordUnbordUpdate() → Gate::authorize('tenant.student.bording.update')
          ├─ HAS permission → updates record
          └─ NO permission → 403 Forbidden
```

---

## 18. Migration / DDL Analysis

| DDL ID | Column | Migration Flag | Index | Notes |
|--------|--------|---------------|-------|-------|
| DDL-01 | id | auto-increment | PK | Standard |
| DDL-02 | trip_date | NOT NULL | None | No date index — query by trip_date may be slow on large datasets |
| DDL-03 | student_id | DEFAULT NULL, FK SET NULL | None | Index recommended for JOIN performance |
| DDL-04 | student_session_id | DEFAULT NULL, FK SET NULL | None | No unique constraint |
| DDL-05 | boarding_route_id | DEFAULT NULL, FK SET NULL | None | |
| DDL-06 | boarding_trip_id | DEFAULT NULL, FK SET NULL | None | Critical for filter query — no index |
| DDL-07 | boarding_stop_id | DEFAULT NULL, FK SET NULL | None | |
| DDL-08 | boarding_time | DATETIME DEFAULT NULL | None | |
| DDL-09 | unboarding_route_id | DEFAULT NULL, FK SET NULL | None | |
| DDL-10 | unboarding_trip_id | DEFAULT NULL, FK SET NULL | None | No index despite being used in queries |
| DDL-11 | unboarding_stop_id | DEFAULT NULL, FK SET NULL | None | |
| DDL-12 | unboarding_time | DATETIME DEFAULT NULL | None | |
| DDL-13 | device_id | DEFAULT NULL, FK SET NULL | None | |
| DDL-14 | deleted_at | TIMESTAMP NULL | None | Soft deletes |

**Missing Indexes:**
- `boarding_trip_id` — used in WHERE clause for grid filter
- `trip_date` — used in WHERE clause for date filter
- `student_session_id` — used in WHERE clause for skip check
- Composite index on `(trip_date, student_session_id, boarding_trip_id)` — would optimize skip check and serve as unique enforcement

**Missing Constraints:**
- No UNIQUE constraint on `(trip_date, student_session_id, boarding_trip_id)` — risk of duplicate records

---

## 19. Performance Impact Analysis

| PERF ID | Scenario | Query Count per Page (10 rows) | Data Volume | Improvement Strategy |
|---------|----------|-------------------------------|-------------|---------------------|
| PERF-01 | Boarding tab load (no filters) | 1 (base) + N for each lazy relation | Full table scan | Add pagination guards; require filter |
| PERF-02 | Grid display with eager load (current) | 1 (base) + 10 (boardingTrip) + 10 (routeScheduler) + 10 (route) + 10 (tripStopDetail) + 10 (stop) + 10 (student) = **51+ queries** | All records matching filter | Fix eager loads: `with(['boardingTrip.routeScheduler.route', 'boardingTrip.tripStopDetail.stop', 'student'])` → reduces to 5 queries |
| PERF-03 | Bulk create (10 allocations) | 1 (allocations) + 10 (exists check) + 10 (studentSession) = **21 queries** | Small | Use `with('studentSessions')` on allocations query |
| PERF-04 | TripMgmtController unconditional loads | 8 tab queries + 8 reference queries = **16 queries** per page load regardless of active tab | Reference data | Move non-active-tab queries to conditional |
| PERF-05 | Without trip_id/date filter | Full table scan on `tpt_student_boarding_log` | All rows (potentially millions) | Add pagination + require filter or add `->limit()` guard |

---

## 20. Error Handling Matrix

| ERR ID | Trigger | Current Behavior | Expected Behavior | Severity |
|--------|---------|-----------------|-------------------|----------|
| ERR-01 | studentBordUnbordUpdate with invalid ID | 500 Server Error (update() on null) | 404 JSON with error message | HIGH |
| ERR-02 | studentBordingEdit with invalid ID | JSON `{status: true, inserted: null}` | JSON `{status: false}` with proper error | MEDIUM |
| ERR-03 | studentBordingStore with missing params | Silent fail (empty result, false status) | Validation error with specific field messages | MEDIUM |
| ERR-04 | studentBordingStore with non-existent route_id | Empty allocation query → false status | Same behavior, but could add validation for clarity | LOW |
| ERR-05 | Trip resolution failure in index() | trip_id=null → all records shown | Could show "No trip found. Select a valid date/route/shift." | LOW |
| ERR-06 | Unexpected JS error (e.g., $btn undefined) | Console error, then page continues working | Define $btn or handle gracefully | LOW |
| ERR-07 | formatDateTimeLocal() with invalid date | Returns "Invalid Date" formatted string | Should return empty string on parse failure | LOW |
| ERR-08 | `@can('...edit')` but user has `.update` only | Action column hidden — no edit buttons visible | Action column should use `@can('...update')` | HIGH |

---

## 21. Compliance and Standards Checklist

| Standard | Requirement | Current Status | Compliance |
|----------|-------------|----------------|------------|
| HTTP RFC 7231 | GET must be safe (no side effects) | `studentBordingStore` creates DB records via GET | ❌ FAIL |
| Laravel CRUD Pattern | Gate::authorize at start of each method | All 4 methods have Gate::authorize | ✅ PASS |
| Laravel CRUD Pattern | Use $request->validated() from FormRequest | Uses inline validation; no FormRequest | ❌ FAIL |
| Laravel CRUD Pattern | SoftDeletes + destroy/restore/forceDelete routes | SoftDeletes present but no routes | ❌ FAIL |
| Laravel CRUD Pattern | activityLog on create/update/delete | Not present | ❌ FAIL |
| Project Permission Rules | Symmetrical @can on th and td | Action column (th + td) uses @can correctly | ✅ PASS |
| Project Permission Rules | @canany closed with @endcanany (not @endcan) | No @canany used (only @can) | ✅ PASS |
| Project Permission Rules | Permission strings match permissionslist.php | 'student.bording' in $crud → all actions valid | ✅ PASS |
| Project Permission Rules | Controller & view use same permission string | Blade uses `.edit`, Controller uses `.update` → MISMATCH | ❌ FAIL |
| Project CRUD UI Rules | @empty in forelse | Missing in index.blade.php | ❌ FAIL |
| Project CRUD UI Rules | Tab filter bar search pattern | Filter bar present with date/shift/route/stop dropdowns | ✅ PASS |
| Project CRUD UI Rules | Student name + ID display | Only first_name, no student ID | ❌ FAIL |
| Project CRUD UI Rules | Pagination with appends | `->appends(['tab' => 'student_bord_unbord'])` | ✅ PASS |
| OWASP CSRF Protection | State-changing operations use POST/CSRF token | Bulk create uses GET → no CSRF | ❌ FAIL |

---

## 22. CODE-TRACE: TripMgmtController @index — All Unconditional Queries

```
TripMgmtController@index() Unconditional Query List  [lines 73-90]
  │
  ├─ Reference Data (always loads regardless of active tab):
  │   ├─ Vehicle::get()                    → All vehicles
  │   ├─ Route::get()                      → All routes  
  │   ├─ DriverHelper::get()               → All driver/helpers
  │   ├─ Shift::get()                      → All shifts
  │   ├─ SchoolClass::get()                → All classes
  │   ├─ PickupPoint::get()                → All pickup points (needed only by boarding tab)
  │   ├─ AttendanceDevice::get()           → All devices (needed only by boarding tab)
  │   └─ OrganizationAcademicSession::get()→ All academic sessions
  │   └─ TOTAL: 8 queries always executed
  │
  ├─ Tab Queries (always executes ALL regardless of active tab):
  │   ├─ $this->tripStopTimeline($request)       → PickupPointRoute query (tab: trip_details)
  │   ├─ $this->tripStopNew($request)            → TptTripStopDetail query (tab: stop_details)
  │   ├─ $this->TripQuery($request)              → TptTrip query (tab: daily_trip)
  │   ├─ $this->tripBordUnbord($request)          → StudentBoardingLog query (tab: student_bord_unbord)
  │   ├─ $this->incidentQuery($request)          → TptTripIncidents query (tab: trip_incidents)
  │   ├─ $this->driverRouteVehicleQuery($request) → DriverRouteVehicleJnt query (tab: driver_roster)
  │   ├─ $this->SchedulerQuery($request)         → TptRouteSchedulerJnt query (tab: scheduler)
  │   └─ $this->notificationLogQuery($request)   → TptNotificationLog query (tab: notification_log)
  │   └─ TOTAL: 8 more queries always executed
  │
  └─ GRAND TOTAL: 16 queries per page load MINIMUM
      └─ Only 1-2 queries are relevant to the active tab
      └─ Wasted queries: 14-15 per page load
      └── Optimization: Move queries behind tab==='{tab_id}' checks
```

## 23. CODE-TRACE: Request Parameter Flow Map

```
Browser → TripMgmtController → StudentBoardingController — Parameter Flow
  │
  ├─ Browser Sends (via filter form):
  │   ├─ tab = "student_bord_unbord"
  │   ├─ date = "2026-07-21"
  │   ├─ shift_id = "2"
  │   ├─ route_id = "5"
  │   ├─ pickup_drop = "Pickup"
  │   └─ trip_id = "" (empty/readonly)
  │
  ├─ TripMgmtController@index() processes:
  │   ├─ Finds trip by date+shift_id+route_id  [line 54-63]
  │   ├─ Merges: $request->merge(['trip_id' => 100, 'tripe_id' => 100])  [line 67]
  │   │   └─ Overrides the empty trip_id from the form
  │   │
  │   └─ Sends to tripBordUnbord():
  │       $request->trip_id = 100 (filled)
  │       $request->date = "2026-07-21" (also filled but IGNORED)
  │
  ├─ tripBordUnbord() applies filter:
  │   ├─ trip_id IS filled → where('boarding_trip_id', 100)  [line 241-242]
  │   └─ date is NOT checked (elseif branch is skipped)
  │
  ├─ Browser clicks "Add" button:
  │   ├─ JS serializes form including MERGED trip_id=100
  │   └─ GET /student/bording?tab=...&date=...&shift_id=2&route_id=5&trip_id=100
  │
  └─ studentBordingStore() receives:
      ├─ $request->route_id = 5
      ├─ $request->date = "2026-07-21"
      ├─ $request->trip_id = 100
      ├─ $request->shift_id = 2 (NOT USED in store logic)
      └─ $request->pickup_drop = "Pickup" (NOT USED in store logic)
```

## 24. CODE-TRACE: Blade Permission Decision Matrix

```
Permission Matrix — Who Sees What
  │
  ├─ User has 'tenant.student.bording.viewAny' ONLY:
  │   ├─ Tab visible: YES
  │   ├─ Table grid visible: YES (boarding logs loaded)
  │   ├─ "Add" button: NO (needs .create)
  │   └─ Edit buttons: NO (needs .edit)
  │
  ├─ User has 'tenant.student.bording.create' ONLY (no viewAny):
  │   ├─ Tab visible: NO (needs .viewAny)
  │   ├─ Table grid: NO
  │   ├─ "Add" button: NO (tab not visible)
  │   └─ Can still call API directly (GET /student/bording) until tab permission refactored
  │
  ├─ User has 'tenant.student.bording.edit' ONLY:
  │   ├─ Tab visible: NO (needs .viewAny)
  │   ├─ Action buttons: NO (tab not visible)
  │   └─ Can still call API (edit/update) directly
  │
  ├─ User has 'tenant.student.bording.update' ONLY (no .edit):
  │   ├─ Tab: needs .viewAny
  │   ├─ Action buttons visible: NO (blade checks .edit)
  │   └─ API accessible: YES (controller checks .update)
  │
  └─ User has ALL: 'tenant.student.bording.viewAny', '.create', '.update':
      ├─ Tab: YES
      ├─ Add button: YES
      └─ Edit buttons: YES (has .edit from $crud)
```

## 25. CODE-TRACE: SQL Query Log (Typical Page Load)

```
-- QUERIES GENERATED FOR ONE ROW (with current code):

-- 1. TripMgmtController — find trip
SELECT * FROM tpt_trip WHERE trip_date = '2026-07-21' 
  AND EXISTS (SELECT 1 FROM tpt_route_scheduler_jnt WHERE ...) LIMIT 1

-- 2. tripBordUnbord — base query
SELECT * FROM tpt_student_boarding_log ORDER BY id LIMIT 10

-- 3. Eager load: studentSession.student (WASTED — blade uses direct student())
SELECT * FROM std_student_academic_sessions WHERE id IN (...)
SELECT * FROM std_students WHERE id IN (...)  -- Never used by blade!

-- PER ROW:
-- 4. Lazy load: boardingTrip
SELECT * FROM tpt_trip WHERE id = $boarding_trip_id

-- 5. Lazy load: boardingTrip->routeScheduler
SELECT * FROM tpt_route_scheduler_jnt WHERE id = $route_scheduler_id

-- 6. Lazy load: routeScheduler->route  
SELECT * FROM tpt_route WHERE id = $route_id

-- 7. Lazy load: boardingTrip->tripStopDetail
SELECT * FROM tpt_trip_stop_detail WHERE trip_id = $trip_id LIMIT 1

-- 8. Lazy load: tripStopDetail->stop
SELECT * FROM tpt_pickup_points WHERE id = $stop_id

-- 9. Lazy load: student (direct relation, despite eager load of studentSession.student)
SELECT * FROM std_students WHERE id = $student_id

-- 10. Lazy load: boardingRoute
SELECT * FROM tpt_route WHERE id = $boarding_route_id

-- 11. Lazy load: boardingStop
SELECT * FROM tpt_pickup_points WHERE id = $boarding_stop_id

-- 12. Lazy load: unboardingRoute
SELECT * FROM tpt_route WHERE id = $unboarding_route_id

-- 13. Lazy load: unboardingStop
SELECT * FROM tpt_pickup_points WHERE id = $unboarding_stop_id

-- TOTAL: 3 (base) + 10 × 10 (lazy per row) = ~103 queries per page
```

## 26. CODE-TRACE: Controller Method Signature Comparison

| Method | Visibility | Parameters | Return | Validation | ActivityLog |
|--------|-----------|------------|--------|------------|-------------|
| `index()` | public | Request | View | None | No |
| `studentBordingStore()` | public | Request | JSON | None | No |
| `studentBordingEdit()` | public | Request | JSON | None | No |
| `studentBordUnbordUpdate()` | public | Request | JSON | Inline (partial) | No |

**Contrast with TripController methods:**

| Method | Visibility | Parameters | Return | Validation | ActivityLog |
|--------|-----------|------------|--------|------------|-------------|
| `index()` | public | TripRequest | View | FormRequest | No |
| `store()` | public | TripRequest | Redirect | FormRequest | No |
| `update()` | public | TripRequest, $id | Redirect | FormRequest | Yes |
| `destroy()` | public | $id | Redirect | Route Model Binding | Yes |
| `restore()` | public | $id | Redirect | Route Model Binding | Yes |
| `forceDelete()` | public | $id | Redirect | Route Model Binding | Yes |

**Key Differences:**
- TripController uses FormRequest (`TripRequest`) — StudentBoardingController uses inline/no validation
- TripController uses Route Model Binding (`findOrFail`) — StudentBoardingController uses manual `first()` with null risk
- TripController logs ALL mutations via `activityLog()` — StudentBoardingController logs nothing
- TripController has complete CRUD resource pattern — StudentBoardingController is ad-hoc

---

## 27. CODE-TRACE: Blade Component Usage Compliance

| Line | Component | Usage | Compliant? | Issue |
|------|-----------|-------|------------|-------|
| index.blade.php:6 | x-backend.tab.filter-bar | Filter bar wrapper | ✅ | Correct |
| index.blade.php:10-67 | form | Inline filter form with hidden tab input | ✅ | Correct per CRUD tab pattern |
| index.blade.php:14 | input[type=date] | Date picker for trip date filter | ✅ | Correct |
| index.blade.php:20 | select | Shift dropdown | ✅ | Correct |
| index.blade.php:32 | select | Route dropdown | ✅ | Correct |
| index.blade.php:44 | select | Pickup/Drop dropdown | ✅ | Correct |
| index.blade.php:60-62 | button.btn-primary | Search button | ✅ | Correct |
| index.blade.php:63-65 | a.btn-secondary | Reset button | ⚠️ | `url()->current()` loses tab context |
| index.blade.php:86 | table.table-sm | Standard table | ✅ | Correct |
| index.blade.php:133 | `{{ $row->student->first_name }}` | Student name display | ❌ | Missing student ID per Rule 7h |
| index.blade.php:142 | `.btn-outline-warning.btn-sm` | Edit button | ✅ | btn-sm is correct for table action buttons |
| model.blade.php:137 | `.btn-success.btn-sm` | Update submit | ❌ | btn-sm violates CRUD UI Rule 4 (modal buttons should use default size) |

---

(End of file)
