# tpt_DailyTrip_TcList

## Module: Transport → Trip Management → Daily Trip

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | Transport |
| Tab Group | Trip Management |
| Feature | Daily Trip |
| URL(s) | `/transport/trip-management?tab=daily_trip` (index via tab, main listing), `/trip/create` (create form), `/trip` (store), `/trip/{id}` (show), `/trip/{id}/edit` (edit), `/trip/{id}` (update PUT), `/trip/{id}` (destroy DELETE), `/trip/trash/view` (trash), `/trip/{id}/restore` (restore GET), `/trip/{id}/force-delete` (forceDelete DELETE), `/trip/{trip}/toggle-status` (toggleStatus POST — route exists but NO controller method), `/trip/stop-action` (stopAction POST), `/trip/bulk-update-time` (bulkUpdateTime POST), `/trip/bulk-approve` (bulkApprove POST), `/trip/toggle-approve` (toggleApproval POST), `/trip/update-remark` (updateRemark POST), `/stop/details/prepare` (stopDetailsPrepare GET), `/trip/details/edits` (tripDetailsData GET), `/trip/details/updates` (tripDetailsUpdated POST), `/get-route-schedules` (getRouteSchedules GET) |
| Primary Controller | `Modules\Transport\Http\Controllers\TripController` — 19 methods: index, create, store, show, stopAction, edit, tripDetailsData, update, destroy, trashed, restore, forceDelete, stopDetailsPrepare, tripDetailsUpdated, bulkUpdateTime, toggleApproval, bulkApprove, updateRemark, getRouteSchedules |
| Tab Container Controller | `Modules\Transport\Http\Controllers\TripMgmtController@index()` — tab: `daily_trip` and `trip_approve` |
| Model | `Modules\Transport\Models\TptTrip` — table: `tpt_trip`, 17 fillable, 9 relationships, SoftDeletes, boot() compliance + status validation |
| Validation | `Modules\Transport\Http\Requests\TripRequest` — 9 field rules + 3 custom closures |
| Stop Details Model | `Modules\Transport\Models\TptTripStopDetail` — table: `tpt_trip_stop_detail` |
| Permissions | `tenant.trip.*` (7), `tenant.stop-details.*` (4), `tenant.trip-approve.*` (2) |
| Soft Deletes | Yes (`TptTrip` uses `SoftDeletes` trait) |
| Compliance Gating | Model boot() checks: driver license, vehicle fitness/insurance on create; status transitions Scheduled→Ongoing→Completed/Cancelled |
| Vendor Usage Log | On approval, creates `VndUsageLog` with distance= max(0, round(endOdo-startOdo, 2)) |
| Audited Gaps | `toggleStatus` route registered but no method; `created_by` and `shift_id` set in storeTrip but NOT in DDL |


## 2. Pre-conditions

| # | Pre-condition | Source |
|---|--------------|--------|
| PC-01 | Required permissions: `tenant.trip.*` and `tenant.stop-details.*` and `tenant.trip-approve.*` | Policy-based |
| PC-02 | Required seed data: Active `TptRouteSchedulerJnt`, `Route`, `Vehicle`, `DriverHelper`, `Shift` | FK constraints |
| PC-03 | `TripRequest` validates: trip_date unique per route_scheduler_id, vehicle fitness/insurance, driver license, helper != driver, end_time >= start_time, status in [Scheduled, Ongoing, Completed, Cancelled] | TripRequest.php |
| PC-04 | Compliance: driver license_valid_upto and vehicle fitness/insurance must be >= trip_date | TptTrip boot() creating + TripRequest closures |
| PC-05 | Route schedulers must exist for trip_date + shift for getRouteSchedules() | TripController:817-819 |
| PC-06 | Stop details require PickupPointRoute records for trip's route/shift | TripController:489-492 |
| PC-07 | Trip Approve tab uses same TripQuery() with tab=trip_approve filter | TripMgmtController:364 |

---

## 3. Default Data Load

When `/transport/trip-management?tab=daily_trip` loads via TripMgmtController@index():

| Data | Source | Query | Pagination |
|------|--------|-------|------------|
| Trip Data | `TripMgmtController@TripQuery()` | `TptTrip::with(['routeScheduler.route','vehicle','driver','helper','shift'])->latest('trip_date')` + filters | 10/page |
| Stop Details | `tripStopNew()` | `TptTripStopDetail::with('stop')` where trip_id from filters | 10/page |
| Stop Timeline | `tripStopTimeline()` | `PickupPointRoute::with('pickupPoint')` mapped with trip stop details by ordinal | Collection |
| Board/Unboard | `tripBordUnbord()` | `StudentBoardingLog::with('studentSession.student')` where trip_id or date | 10/page |
| Incidents | `incidentQuery()` | `TptTripIncidents::with('resolvedBy')` | 10/page |
| Scheduler | `SchedulerQuery()` | `TptRouteSchedulerJnt::with(['route','shift','vehicle','driver'])->withCount('trips')` | 10/page |
| Driver Roster | `driverRouteVehicleQuery()` | `DriverRouteVehicleJnt::with(['route','shift','vehicle','driver'])` | 10/page |
| Notification Log | `notificationLogQuery()` | `TptNotificationLog::with(['trip','boardingStop'])` | 10/page |
| Supporting Data | Direct query | `Vehicle::get()`, `Route::get()`, `DriverHelper::get()`, `Shift::get()`, `PickupPoint::get()`, `SchoolClass::get()`, `AttendanceDevice::get()`, `OrganizationAcademicSession::get()` | Collection |
| Driver-scoped route | Conditional | If logged-in user maps to DriverHelper, filter `Route::whereIn('id', driverRouteVehicleJnt route_ids)` | Collection |

---

## 4. Test Data Strategy

| # | Data Strategy | Details | Source |
|---|---------------|---------|--------|
| TD-01 | **Trip date**: Must be a date for which a valid route scheduler exists | getRouteSchedules uses scheduled_date matching | TripController:817-819 |
| TD-02 | **route_scheduler_id**: Must reference existing TptRouteSchedulerJnt record | FK restrict | TripRequest:58-61 |
| TD-03 | **vehicle_id/driver_id**: Must have valid fitness/license dates >= trip_date | boot() creating + TripRequest closures | TptTrip:66-97 |
| TD-04 | **Status transitions**: Scheduled→Ongoing|Cancelled, Ongoing→Completed|Cancelled, Completed→(none), Cancelled→(none) | TptTrip:99-117 |
| TD-05 | **Non-JSON delete**: destroy() manually deletes TptTripStopDetail records before soft-deleting trip | TripController:397-401 |
| TD-06 | **Restore**: Only restores trip record — stop details NOT restored (hard-deleted) | TripController:430-434 |
| TD-07 | **Approval**: When approved, creates VndUsageLog with distance=max(0, end_odo-start_odo); unapproved deletes log | TripController:647-694 |
| TD-08 | **Bulk operations**: bulkUpdateTime updates start/end_time and vehicle/driver for selected trips | TripController:570-630 |
| TD-09 | **Bulk approve**: Loops trips; skips already-approved; creates VndUsageLog | TripController:704-787 |
| TD-10 | **stopAction new_ ID**: `new_{jntId}` creates TptTripStopDetail on-the-fly; fallback to any active trip today | TripController:131-172 |
| TD-11 | **stopAction driver_id**: Gets from routeScheduler for updated_by/raised_by | TripController:184-185 |
| TD-12 | **Distance**: `max(0, round(endOdo - startOdo, 2))` in toggleApproval and bulkApprove | TripController:643-645, 759-761 |
| TD-13 | **Cancellation notification**: When update status='Cancelled', creates TptNotificationLog type='Cancelled' | TripController:369-376 |
| TD-14 | **stopDetailsPrepare dedup**: Skips existing TptTripStopDetail where trip_id+stop_id+pickup_drop match | TripController:500-508 |

---

## 5. Business Conditions

### 5.1 Database Schema — `tpt_trip`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | id | INT UNSIGNED | PK, auto-increment |
| BC-DB-02 | trip_date | DATE | NOT NULL |
| BC-DB-03 | route_scheduler_id | INT UNSIGNED | NOT NULL, FK -> tpt_route_scheduler_jnt.id, ON DELETE RESTRICT |
| BC-DB-04 | route_id | INT UNSIGNED | NOT NULL |
| BC-DB-05 | vehicle_id | INT UNSIGNED | NOT NULL, FK -> tpt_vehicle.id, ON DELETE RESTRICT |
| BC-DB-06 | driver_id | INT UNSIGNED | NOT NULL, FK -> tpt_personnel.id, ON DELETE RESTRICT |
| BC-DB-07 | helper_id | INT UNSIGNED | DEFAULT NULL, FK -> tpt_personnel.id, ON DELETE RESTRICT |
| BC-DB-08 | start_time | DATETIME | DEFAULT NULL |
| BC-DB-09 | end_time | DATETIME | DEFAULT NULL |
| BC-DB-10 | start_odometer_reading | DECIMAL(11,2) | DEFAULT 0.00 |
| BC-DB-11 | end_odometer_reading | DECIMAL(11,2) | DEFAULT 0.00 |
| BC-DB-12 | start_fuel_reading | DECIMAL(8,3) | DEFAULT 0.00 |
| BC-DB-13 | end_fuel_reading | DECIMAL(8,3) | DEFAULT 0.00 |
| BC-DB-14 | status | VARCHAR(20) | NOT NULL, DEFAULT 'Scheduled' |
| BC-DB-15 | approved | TINYINT(1) | NOT NULL, DEFAULT 0 |
| BC-DB-16 | approved_by | INT UNSIGNED | DEFAULT NULL |
| BC-DB-17 | approved_at | TIMESTAMP | NULL |
| BC-DB-18 | remarks | VARCHAR(512) | DEFAULT NULL |
| BC-DB-19 | created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |
| BC-DB-20 | updated_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP |
| BC-DB-21 | deleted_at | TIMESTAMP | NULL |

### 5.2 Validation Rules — `TripRequest`

| BC ID | Field | Rule | Custom Message |
|-------|-------|------|----------------|
| BC-VAL-01 | trip_date | required, date, unique (tpt_trip, trip_date) WHERE route_scheduler_id = X AND deleted_at IS NULL ->ignore($this->route('trip')) | 'A trip is already scheduled for this date with the selected route schedule.' |
| BC-VAL-02 | route_scheduler_id | required, `exists:tpt_route_scheduler_jnt,id` | 'Route schedule is required.' |
| BC-VAL-03 | vehicle_id | required, `exists:tpt_vehicle,id` + custom closure (fitness + insurance check) | 'Vehicle X has expired fitness/insurance' |
| BC-VAL-04 | driver_id | required, `exists:tpt_personnel,id` + custom closure (license check) | 'Driver X has an expired license' |
| BC-VAL-05 | helper_id | nullable, `exists:tpt_personnel,id`, `different:driver_id` | 'Driver and helper cannot be the same person.' |
| BC-VAL-06 | start_time | nullable, date | — |
| BC-VAL-07 | end_time | nullable, date, closure: after_or_equal:start_time | 'End time must be after or equal to start time.' |
| BC-VAL-08 | status | required, `Rule::in(['Scheduled','Ongoing','Completed','Cancelled'])` | — |
| BC-VAL-09 | remarks | nullable, string, max:512 | — |

### 5.3 Authorization (Permission Gates)

| BC ID | Permission | Controller Method | Behavior |
|-------|-----------|-------------------|----------|
| BC-AUTH-01 | tenant.trip.viewAny | index() | Without -> 403 |
| BC-AUTH-02 | tenant.trip.view | show(), getRouteSchedules() | Without -> 403 |
| BC-AUTH-03 | tenant.trip.create | create(), store() + TripRequest authorize() | Without -> 403 |
| BC-AUTH-04 | tenant.trip.update | edit(), update(), bulkUpdateTime(), updateRemark() | Without -> 403 |
| BC-AUTH-05 | tenant.trip.delete | destroy() | Without -> 403 |
| BC-AUTH-06 | tenant.trip.restore | trashed(), restore() | Without -> 403 |
| BC-AUTH-07 | tenant.trip.forceDelete | forceDelete() | Without -> 403 |
| BC-AUTH-08 | tenant.stop-details.update | stopAction(), tripDetailsUpdated() | Without -> 403 |
| BC-AUTH-09 | tenant.stop-details.view | tripDetailsData() | Without -> 403 |
| BC-AUTH-10 | tenant.stop-details.prepare | stopDetailsPrepare() | Without -> 403 |
| BC-AUTH-11 | tenant.trip-approve.approve | toggleApproval() | Without -> 403 |
| BC-AUTH-12 | tenant.trip-approve.bulkApprove | bulkApprove() | Without -> 403 |

### 5.4 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Create trip | Record created; redirect to trip-management with daily_trip tab |
| BC-BIZ-02 | Create with expired driver license | TripRequest closure fails + model boot() DomainException |
| BC-BIZ-03 | Create with expired vehicle fitness | TripRequest closure fails + model boot() DomainException |
| BC-BIZ-04 | Create with expired vehicle insurance | TripRequest closure fails + model boot() DomainException |
| BC-BIZ-05 | Update status Scheduled -> Ongoing | Allowed by model boot() |
| BC-BIZ-06 | Update status Ongoing -> Completed | Allowed |
| BC-BIZ-07 | Update status Completed -> Ongoing | Blocked: DomainException |
| BC-BIZ-08 | Activity log on update | `activityLog($trip, 'Updated', ['message' => 'Trip and stop details updated successfully.'])` |
| BC-BIZ-09 | Soft delete with stop details cascade | Manual: TptTripStopDetail::where('trip_id')->delete() THEN trip->delete() |
| BC-BIZ-10 | Activity log on soft delete | `activityLog($trip, 'Deleted', ['message' => 'Trip and related stop details deleted.'])` |
| BC-BIZ-11 | Restore from trash | `onlyTrashed()->find()` -> restore(); stop details NOT restored |
| BC-BIZ-12 | Force delete | `onlyTrashed()->find()` -> forceDelete() |
| BC-BIZ-13 | Approve trip (toggleApproval) | approved=1, approved_by=Auth::id(), approved_at=now; VndUsageLog created |
| BC-BIZ-14 | Unapprove trip (toggleApproval) | approved=0, approved_by=null, approved_at=null; VndUsageLog deleted |
| BC-BIZ-15 | Bulk approve | Each trip: skip if already approved; create VndUsageLog |
| BC-BIZ-16 | Bulk unapprove | Deletes VndUsageLog; resets approval fields |
| BC-BIZ-17 | Bulk update time | Updates start_time, end_time, vehicle_id, driver_id for selected trips |
| BC-BIZ-18 | Update remark | `$trip->remarks = $request->remarks; $trip->save()` -> JSON response |
| BC-BIZ-19 | stopDetailsPrepare | Creates TptTripStopDetail from PickupPointRoute for trip's route/shift |
| BC-BIZ-20 | stopAction start_trip | Creates TptNotificationLog 'TripStart'; updates trip start_time/odometer/fuel; status='Ongoing' |
| BC-BIZ-21 | stopAction reach | Updates reached_flag=1, reaching_time; creates ReachedStop or Delayed (>5min late) |
| BC-BIZ-22 | stopAction leave | Updates leaving_time; creates ApproachingStop notification |
| BC-BIZ-23 | stopAction end_trip | Updates end_time/odometer/fuel; status='Completed' |
| BC-BIZ-24 | stopAction emergency | Sets emergency_flag=1; creates TptTripIncidents record |
| BC-BIZ-25 | Bulk update no valid trips | `$trips->isEmpty()` -> back() with 'No valid trips selected!' |
| BC-BIZ-26 | Bulk update empty updateData | Skip if no fields changed |
| BC-BIZ-27 | toggleApproval no vendor | No VndUsageLog created |
| BC-BIZ-28 | bulkApprove distance | Same formula: max(0, round(endOdo-startOdo, 2)) |
| BC-BIZ-29 | stopDetailsPrepare skip existing | EXISTS check -> skipped++ |
| BC-BIZ-30 | getRouteSchedules include ID | `orWhere('id', $includeId)` ensures current scheduler always included |
| BC-BIZ-31 | stopAction new_ ordinal matching | Matches on trip_id, stop_id, pickup_drop, ordinal |
| BC-BIZ-32 | stopAction fallback trip | If no trip for route today -> any active trip today |
| BC-BIZ-33 | Cancellation notification in update | TptNotificationLog type='Cancelled' inside DB transaction |
| BC-BIZ-34 | tripDetailsUpdated activityLog BEFORE update | `activityLog()` before `$stop->update()` |
| BC-BIZ-35 | stopDetailsPrepare activityLog in loop | N+1 activityLog per created stop detail |

### 5.5 Model Relationships — `TptTrip`

| BC ID | Relationship | Type | Foreign Key |
|-------|-------------|------|-------------|
| BC-REL-01 | routeScheduler() | BelongsTo TptRouteSchedulerJnt | route_scheduler_id |
| BC-REL-02 | approvedBy() | BelongsTo User | approved_by |
| BC-REL-03 | route() | HasOneThrough Route via TptRouteSchedulerJnt | route_scheduler_id -> TptRouteSchedulerJnt.id -> route_id -> Route.id |
| BC-REL-04 | driver() | BelongsTo DriverHelper | driver_id |
| BC-REL-05 | vehicle() | BelongsTo Vehicle | vehicle_id |
| BC-REL-06 | helper() | BelongsTo DriverHelper | helper_id |
| BC-REL-07 | shift() | HasOneThrough Shift via TptRouteSchedulerJnt | route_scheduler_id -> TptRouteSchedulerJnt.id -> shift_id -> Shift.id |
| BC-REL-08 | tripStopDetail() | HasOne TptTripStopDetail | trip_id |
| BC-REL-09 | boardingLogs() | HasMany StudentBoardingLog | boarding_trip_id OR unboarding_trip_id |

---

## 6. Test Case List

### 6.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | Daily Trip Tab Loads | `/transport/trip-management?tab=daily_trip` loads trip grid with filters | — | — | ⬜ |
| TC-P02 | Create Trip Manually | POST `/trip` with valid data -> trip created; redirect to daily_trip tab | — | — | ⬜ |
| TC-P03 | View Trip Details | `/trip/{id}` shows all fields | — | — | ⬜ |
| TC-P04 | Edit Trip Loads Pre-Filled | `/trip/{id}/edit` shows existing values | — | — | ⬜ |
| TC-P05 | Update Status Scheduled -> Ongoing | PUT -> status updated; allowed by model | — | — | ⬜ |
| TC-P06 | Update Status Ongoing -> Completed | PUT -> status updated | — | — | ⬜ |
| TC-P07 | Update Trip Change Vehicle | PUT -> vehicle changed (with compliance check) | — | — | ⬜ |
| TC-P08 | Soft Delete Trip | DELETE -> trip and stop details soft-deleted | — | — | ⬜ |
| TC-P09 | Trash Page Shows Deleted Trips | `/trip/trash/view` -> list of trashed trips | — | — | ⬜ |
| TC-P10 | Restore Trip | GET `/trip/{id}/restore` -> trip restored; stop details still gone | — | — | ⬜ |
| TC-P11 | Force Delete Trip | DELETE `/trip/{id}/force-delete` -> permanently removed | — | — | ⬜ |
| TC-P12 | Approve Single Trip | POST `/trip/toggle-approve` -> approved=1; VndUsageLog created | — | — | ⬜ |
| TC-P13 | Unapprove Single Trip | POST `/trip/toggle-approve` -> approved=0; VndUsageLog deleted | — | — | ⬜ |
| TC-P14 | Bulk Approve Trips | POST `/trip/bulk-approve` -> multiple trips approved | — | — | ⬜ |
| TC-P15 | Bulk Update Time | POST `/trip/bulk-update-time` -> start/end times updated | — | — | ⬜ |
| TC-P16 | Update Remark | POST `/trip/update-remark` -> remark saved | — | — | ⬜ |
| TC-P17 | Prepare Stop Details | GET `/stop/details/prepare?trip_id=X` -> TptTripStopDetail records created | — | — | ⬜ |
| TC-P18 | Filter by Trip Date | Date filter -> matching trips shown | — | — | ⬜ |
| TC-P19 | Filter by Route/Vehicle/Driver | Dropdown filters work | — | — | ⬜ |
| TC-P20 | Filter by Approval Status | Approved/Unapproved filter | — | — | ⬜ |
| TC-P21 | Filter by Trip Status | Status filter | — | — | ⬜ |
| TC-P22 | Search by Route/Vehicle/Driver | Text search across related entities | — | — | ⬜ |
| TC-P23 | Empty State — No Trips | "No Data Found" | — | — | ⬜ |
| TC-P24 | Pagination | When 11+ trips, pagination appears | — | — | ⬜ |
| TC-P25 | Trip Approve Tab Filtering | `/transport/trip-management?tab=trip_approve` shows filters | — | — | ⬜ |
| TC-P26 | Get Route Schedules AJAX | GET `/get-route-schedules` returns filtered route scheduler JSON | — | — | ⬜ |
| TC-P27 | Trip Details Data AJAX | GET `/trip/details/edits` returns TptTripStopDetail JSON | — | — | ⬜ |
| TC-P28 | Trip Details Updated AJAX | POST `/trip/details/updates` updates reaching_time, leaving_time, emergency fields | — | — | ⬜ |
| TC-P29 | Stop Action start_trip | POST `/trip/stop-action` action=start_trip | — | — | ⬜ |
| TC-P30 | Stop Action reach | POST `/trip/stop-action` action=reach | — | — | ⬜ |
| TC-P31 | Stop Action leave | POST `/trip/stop-action` action=leave | — | — | ⬜ |
| TC-P32 | Stop Action end_trip | POST `/trip/stop-action` action=end_trip | — | — | ⬜ |
| TC-P33 | Stop Action emergency | POST `/trip/stop-action` action=emergency | — | — | ⬜ |
| TC-P34 | Trip Standalone Index | GET `/trip` loads paginated trip list via TripController@index | — | — | ⬜ |
| TC-P35 | Prepare Stop Details Skip Existing | GET with some already existing -> skipped count incremented | — | — | ⬜ |
| TC-P36 | Bulk Approve All Unapproved | POST with 3 unapproved -> all approved, VndUsageLog created | — | — | ⬜ |
| TC-P37 | Bulk Unapprove Approved Trips | POST with action=unapprove -> all reset, VndUsageLog deleted | — | — | ⬜ |
| TC-P38 | Bulk Update Time Start Only | POST with bulk_start_time only | — | — | ⬜ |
| TC-P39 | Bulk Update Vehicle Only | POST with vehicle_id only | — | — | ⬜ |
| TC-P40 | getRouteSchedules with include_id | Include ID ensures current scheduler always in results | — | — | ⬜ |

### 6.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | Required — Missing trip_date | Validation error | — | — | ⬜ |
| TC-N02 | Required — Missing route_scheduler_id | Validation error | — | — | ⬜ |
| TC-N03 | Required — Missing vehicle_id | Validation error | — | — | ⬜ |
| TC-N04 | Required — Missing driver_id | Validation error | — | — | ⬜ |
| TC-N05 | Duplicate trip_date + route_scheduler_id | Unique validation error | — | — | ⬜ |
| TC-N06 | Invalid status value | Rule::in validation error | — | — | ⬜ |
| TC-N07 | Helper equals Driver | different validation error | — | — | ⬜ |
| TC-N08 | End Time Before Start Time | Closure validation error | — | — | ⬜ |
| TC-N09 | Expired Driver License | Closure validation error | — | — | ⬜ |
| TC-N10 | Expired Vehicle Fitness | Closure validation error | — | — | ⬜ |
| TC-N11 | Expired Vehicle Insurance | Closure validation error | — | — | ⬜ |
| TC-N12 | Invalid Status Transition Completed -> Ongoing | Model boot() DomainException | — | — | ⬜ |
| TC-N13 | Invalid Status Transition Cancelled -> Scheduled | Model boot() DomainException | — | — | ⬜ |
| TC-N14 | View With Invalid ID | Redirect with error 'Trip not found.' (NOT 404) | — | — | ⬜ |
| TC-N15 | Edit With Invalid ID | Redirect with error 'Trip not found.' | — | — | ⬜ |
| TC-N16 | Update With Invalid ID | Redirect back with error 'Trip not found.' | — | — | ⬜ |
| TC-N17 | Delete With Invalid ID | Exception -> 500 error | — | — | ⬜ |
| TC-N18 | Restore Non-Deleted Trip | `onlyTrashed()->find()` null -> redirect error | — | — | ⬜ |
| TC-N19 | Force Delete Non-Trashed Trip | `onlyTrashed()->find()` null -> error | — | — | ⬜ |
| TC-N20 | Approve Non-Existent Trip | 404 JSON | — | — | ⬜ |
| TC-N21 | Permission 403 — No Trip Permissions | 403 on all CRUD endpoints | — | — | ⬜ |
| TC-N22 | Permission 403 — No stop-details.update | 403 on stopAction(), tripDetailsUpdated() | — | — | ⬜ |
| TC-N23 | Permission 403 — No stop-details.view | 403 on tripDetailsData() | — | — | ⬜ |
| TC-N24 | Permission 403 — No stop-details.prepare | 403 on stopDetailsPrepare() | — | — | ⬜ |
| TC-N25 | Permission 403 — No trip-approve.approve | 403 on toggleApproval() | — | — | ⬜ |
| TC-N26 | Permission 403 — No trip-approve.bulkApprove | 403 on bulkApprove() | — | — | ⬜ |
| TC-N27 | Guest Access Redirect | All URLs redirect to /login | — | — | ⬜ |
| TC-N28 | XSS Injection | `<script>` stored literal; Blade escapes | — | — | ⬜ |
| TC-N29 | Bulk Approve Already Approved Skipped | Already approved remains; VndUsageLog not duplicated | — | — | ⬜ |
| TC-N30 | Bulk Update No Valid Trips | back() with 'No valid trips selected!' | — | — | ⬜ |
| TC-N31 | Bulk Update Invalid vehicle_id | Inline validate fails | — | — | ⬜ |
| TC-N32 | Bulk Update Invalid time format | 'The bulk start time does not match the format H:i.' | — | — | ⬜ |
| TC-N33 | Approve without trip_id | 400/404 JSON | — | — | ⬜ |
| TC-N34 | stopAction invalid action value | Falls through switch, no error -> returns success silently | — | — | ⬜ |
| TC-N35 | stopAction non-existent stop ID | 404 JSON | — | — | ⬜ |
| TC-N36 | tripDetailsUpdated non-existent stop | 404 JSON | — | — | ⬜ |
| TC-N37 | stopDetailsPrepare without trip_id | 400 JSON | — | — | ⬜ |
| TC-N38 | stopDetailsPrepare invalid trip_id | 404 JSON | — | — | ⬜ |
| TC-N39 | updateRemark invalid trip_id | Inline validate fails | — | — | ⬜ |
| TC-N40 | tripDetailsData non-existent id | JSON with null (not 404 — uses first()) | — | — | ⬜ |

### 6.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|----------------|---------|---------|--------|
| TC-D01 | A | Delete Trip — Stop Details Hard-Deleted | Controller destroy(): TptTripStopDetail::where('trip_id')->delete() BEFORE $trip->delete() | — | — | ⬜ |
| TC-D02 | B | Delete Trip — NotificationLog SET NULL | DDL SET NULL on tpt_notification_log.trip_id | — | — | ⬜ |
| TC-D03 | C | Delete Trip — BoardingLog SET NULL | DDL SET NULL on boarding_trip_id/unboarding_trip_id | — | — | ⬜ |
| TC-D04 | D | Delete Trip — TripIncidents CASCADE | DDL CASCADE on tpt_trip_incidents.trip_id | — | — | ⬜ |
| TC-D05 | E | Delete Scheduler — Trip RESTRICT | DDL RESTRICT — cannot delete scheduler when trip references it | — | — | ⬜ |
| TC-D06 | F | Approve Trip — VndUsageLog Created | VndUsageLog with qty_used = max(0, round(endOdo-startOdo, 2)) | — | — | ⬜ |
| TC-D07 | G | Bulk Approve — Skip Already Approved | Already approved skipped; only unapproved processed | — | — | ⬜ |
| TC-D08 | H | Trip Generation Via storeTrip | Trips by RouteSchedulerController@storeTrip load in daily_trip tab | — | — | ⬜ |
| TC-D09 | I | Bulk Unapprove — VndUsageLog Deleted | Remarks-matching VndUsageLog deleted for each trip | — | — | ⬜ |
| TC-D10 | J | stopAction new_ Creates TptTripStopDetail | Fake ID new_{jntId} creates stop detail on-the-fly | — | — | ⬜ |
| TC-D11 | K | stopDetailsPrepare Activity Log N+1 | Each created stop gets individual activityLog inside foreach | — | — | ⬜ |
| TC-D12 | L | Update Cancelled Notification Created | TptNotificationLog 'Cancelled' inside DB transaction | — | — | ⬜ |
| TC-D13 | M | Approve with vendor firstOrCreate | firstOrCreate prevents duplicate VndUsageLog | — | — | ⬜ |

### 6.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|-----------------|---------|---------|--------|
| TC-CR01 | CR | P1 | Controller — Gate::authorize() Before All State Changes | Line-by-line verification of all public methods | — | — | ◌ |
| TC-CR02 | CR | P1 | Controller — activityLog After CRUD | Updated (update), Deleted (destroy), Restored (restore), ForceDeleted (forceDelete), Create (stopDetailsPrepare per-stop), Updated (tripDetailsUpdated) — 6 event types | — | — | ◌ |
| TC-CR03 | CR | P1 | Manual Stop Detail Deletion on destroy() | TptTripStopDetail::where('trip_id')->delete() BEFORE $trip->delete() | — | — | ◌ |
| TC-CR04 | CR | P1 | onlyTrashed() for restore and forceDelete | Both use onlyTrashed()->find() — null if not trashed | — | — | ◌ |
| TC-CR05 | CR | P1 | Model boot() Compliance Checks | Driver license, vehicle fitness, vehicle insurance on creating() | — | — | ◌ |
| TC-CR06 | CR | P1 | Model Status Transition Validation | saving() checks allowed transitions | — | — | ◌ |
| TC-CR07 | CR | P1 | Model Fillable Fields | 17 fillable fields (trip_date, route_scheduler_id, route_id, vehicle_id, driver_id, helper_id, start_time, end_time, start_odometer_reading, end_odometer_reading, start_fuel_reading, end_fuel_reading, status, remarks, approved, approved_by, approved_at) | — | — | ◌ |
| TC-CR08 | CR | P1 | Model Relationships | 9: routeScheduler, approvedBy, route(HOT), driver, vehicle, helper, shift(HOT), tripStopDetail, boardingLogs | — | — | ◌ |
| TC-CR09 | CR | P1 | created_by field in storeTrip | Sets created_by but column NOT in DDL — potential SQL error | — | — | ◌ |
| TC-CR10 | CR | P1 | Request authorize() matches controller | POST->create; PUT/PATCH->update | — | — | ◌ |
| TC-CR11 | CR | P1 | Compliance Validation in Closures | Driver license, vehicle fitness, vehicle insurance in custom closures | — | — | ◌ |
| TC-CR12 | CR | P1 | Unique trip_date + route_scheduler_id | Rule::unique()->where('route_scheduler_id',...)->whereNull('deleted_at')->ignore($this->route('trip')) | — | — | ◌ |
| TC-CR13 | CR | P1 | Routes — Resource + Many Additional Endpoints | Resource + 10+ custom routes | — | — | ◌ |
| TC-CR14 | CR | P1 | DDL Foreign Keys | scheduler(RESTRICT), vehicle(RESTRICT), driver(RESTRICT), helper(RESTRICT) | — | — | ◌ |
| TC-CR15 | CR | P1 | DDL Indexes | idx_trip_routeSched_tripDate, idx_trip_vehicle | — | — | ◌ |
| TC-CR16 | CR | P1 | GAP created_by not in DDL | storeTrip sets created_by but DDL has no such column — **CRITICAL BUG** | — | — | ◌ |
| TC-CR17 | CR | P1 | GAP shift_id not in DDL | storeTrip sets shift_id but DDL has no shift_id — **CRITICAL BUG** | — | — | ◌ |
| TC-CR18 | CR | P1 | GAP Restore does NOT restore stop details | Stop details hard-deleted; restore brings back only trip | — | — | ◌ |
| TC-CR19 | CR | P1 | GAP toggleStatus route exists no method | web.php links to TripController but no toggleStatus method | — | — | ◌ |
| TC-CR20 | CR | P1 | TripMgmtController TripQuery filters | trip_date, route_id, vehicle_id, driver_id, approval_status, status, search | — | — | ◌ |
| TC-CR21 | CR | P2 | activityLog in stopDetailsPrepare | N+1: each created stop logs Create inside loop | — | — | ◌ |
| TC-CR22 | CR | P2 | activityLog in tripDetailsUpdated | Logged BEFORE $stop->update() | — | — | ◌ |
| TC-CR23 | CR | P2 | Cancellation Notification on Update | When status='Cancelled', TptNotificationLog created inside transaction | — | — | ◌ |
| TC-CR24 | CR | P1 | stopAction new_ ID Handling | Fake ID new_{jntId} creates TptTripStopDetail on-the-fly | — | — | ◌ |
| TC-CR25 | CR | P2 | update() unique trip_date on update | TripRequest ignore() rule handles it | — | — | ◌ |
| TC-CR26 | CR | P2 | bulkUpdateTime uses inline validation | NOT TripRequest | — | — | ◌ |
| TC-CR27 | CR | P2 | bulkUpdateTime rollBack without beginTransaction | **BUG**: DB::rollBack() with no DB::beginTransaction() | — | — | ◌ |
| TC-CR28 | CR | P2 | bulkApprove optional() chain | routeScheduler->vehicle->vendor chain may break if null | — | — | ◌ |
| TC-CR29 | CR | P2 | store() route_id from scheduler | 'route_id'=>$routeScheduler->route_id — ignores request route_id | — | — | ◌ |
| TC-CR30 | CR | P2 | show() stop detail first() | Only fetches first stop detail for trip | — | — | ◌ |
| TC-CR31 | CR | P2 | boardingLogs() orWhere | ->orWhere('unboarding_trip_id',...) may cause SQL issues with eager loading | — | — | ◌ |
| TC-CR32 | CR | P1 | toggleStatus route no method | 500 error if called: "Method toggleStatus does not exist" | — | — | ◌ |

---

## 7. Detailed Test Steps

### TC-P01: Daily Trip Tab Loads

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user with `tenant.transport.viewAny` | Authenticated |
| 2 | Navigate to `/transport/trip-management?tab=daily_trip` | Page loads |
| 3 | **Verify**: `TripMgmtController@index()` Gate::authorize('tenant.transport.viewAny') passes | 200 OK |
| 4 | **Verify**: `TripQuery()` builds query: `TptTrip::with(['routeScheduler.route','vehicle','driver','helper','shift'])->latest('trip_date')` | Query built |
| 5 | **Verify**: `tripStopNew()` builds: `TptTripStopDetail::with('stop')` | Query built |
| 6 | **Verify**: `tripStopTimeline()` builds: `PickupPointRoute::with('pickupPoint')` | Query built |
| 7 | **Verify**: `tripBordUnbord()` builds: `StudentBoardingLog::with('studentSession.student')` | Query built |
| 8 | **Verify**: `incidentQuery()` builds | Query built |
| 9 | **Verify**: Trip grid rendered with columns (Date, Route, Vehicle, Driver, Helper, Status, Approved, Actions) | Table visible |
| 10 | **Verify**: Filter form: trip_date, route, vehicle, driver, approval_status, status, search | Filters visible |
| 11 | **Verify**: All supporting data loaded (vehicles, routes, driverHelpers, shifts, pickupPoints) | Dropdowns populated |

### TC-P02: Create Trip Manually

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.trip.create` permission | Authenticated |
| 2 | Navigate to Trip Management -> Daily Trip tab | Tab loaded |
| 3 | Click "Add Trip" button | Navigate to `/trip/create` |
| 4 | **Verify**: `Gate::authorize('tenant.trip.create')` passes | Authorized |
| 5 | **Verify**: Form loaded with routeSchedulers, shifts, vehicles, personnels, stops, today date | Form rendered |
| 6 | Select route scheduler from `select[name=route_scheduler_id]` | Scheduler selected |
| 7 | Enter trip_date (YYYY-MM-DD) | Date set |
| 8 | Vehicle auto-populated from scheduler (or manually select) | Vehicle selected |
| 9 | Driver auto-populated from scheduler (or manually select) | Driver selected |
| 10 | Select status "Scheduled" from `select[name=status]` | Status set |
| 11 | Click "Save" | POST `/trip` |
| 12 | **Verify**: `TripRequest::authorize()` POST -> `tenant.trip.create` | Authorized |
| 13 | **Verify**: `prepareForValidation()` converts empty strings to null, defaults status to 'Scheduled' | Data normalized |
| 14 | **Verify**: `TripRequest` field rules pass | No validation errors |
| 15 | **Verify**: `vehicle_id` closure: vehicle fitness_valid_upto >= trip_date | Pass |
| 16 | **Verify**: `vehicle_id` closure: vehicle insurance_valid_upto >= trip_date | Pass |
| 17 | **Verify**: `driver_id` closure: driver license_valid_upto >= trip_date | Pass |
| 18 | **Verify**: `helper_id` `different:driver_id` check | Pass |
| 19 | **Verify**: `end_time` after_or_equal `start_time` | Pass |
| 20 | **Verify**: `trip_date` unique per `route_scheduler_id` | Pass |
| 21 | **Verify**: `TripController@store()`: `$routeScheduler = TptRouteSchedulerJnt::find()` | Scheduler found |
| 22 | **Verify**: `TptTrip::create()` with all validated fields | Record created |
| 23 | **Verify**: Model boot() `creating`: compliance checks pass (license, fitness, insurance) | No DomainException |
| 24 | **Verify**: `route_id` set from `$routeScheduler->route_id` | Route assigned |
| 25 | **Verify**: `approved` default 0 | Not approved |
| 26 | DB check: `SELECT * FROM tpt_trip WHERE route_scheduler_id = X AND trip_date = Y` | Record exists |
| 27 | **Verify**: Redirect to `route('transport.trip-management.index', ['tab' => 'daily_trip'])` | Redirected |
| 28 | **Verify**: Flash message "Trip created successfully!" | Success message |

### TC-P03: View Trip Details

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.trip.view` permission | Authenticated |
| 2 | Navigate to `/trip/{id}` where {id} exists | Page loads |
| 3 | **Verify**: `Gate::authorize('tenant.trip.view')` passes | Authorized |
| 4 | **Verify**: `TptTrip::with(['routeScheduler','vehicle','driver','helper','shift'])->find($id)` | Record found |
| 5 | **Verify**: Trip date displayed | Visible |
| 6 | **Verify**: Route name (via routeScheduler.route) displayed | Visible |
| 7 | **Verify**: Vehicle number displayed | Visible |
| 8 | **Verify**: Driver name displayed | Visible |
| 9 | **Verify**: Helper name (or 'N/A' if null) displayed | Visible |
| 10 | **Verify**: Shift name displayed | Visible |
| 11 | **Verify**: Start/end times shown | Visible |
| 12 | **Verify**: Status shown | Visible |
| 13 | **Verify**: Odometer readings shown | Visible |
| 14 | **Verify**: Fuel readings shown | Visible |
| 15 | **Verify**: Stop detail section: `TptTripStopDetail::where('trip_id', $id)->first()` | Stop detail section visible |

### TC-P04: Edit Trip Loads Pre-Filled

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.trip.update` permission | Authenticated |
| 2 | Navigate to Daily Trip tab, click edit icon | GET `/trip/{id}/edit` |
| 3 | **Verify**: `Gate::authorize('tenant.trip.update')` passes | Authorized |
| 4 | **Verify**: `TptTrip::find($id)` returns record | Found |
| 5 | **Verify**: Form pre-filled with existing trip_date | Correct |
| 6 | **Verify**: route_scheduler_id pre-selected | Correct |
| 7 | **Verify**: vehicle_id pre-selected | Correct |
| 8 | **Verify**: driver_id pre-selected | Correct |
| 9 | **Verify**: helper_id pre-selected (or empty) | Correct |
| 10 | **Verify**: start_time/end_time pre-filled | Correct |
| 11 | **Verify**: status pre-selected | Correct |
| 12 | **Verify**: Supporting data: TptRouteSchedulerJnt::get(), Shift::get(), Vehicle::active()->get(), DriverHelper::active()->get(), PickupPoint::active()->get() | All loaded |

### TC-P05: Update Status Scheduled -> Ongoing

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create trip with status='Scheduled' | Existing trip |
| 2 | Navigate to edit, change status to 'Ongoing' | Form submitted |
| 3 | Click Save | PUT `/trip/{id}` |
| 4 | **Verify**: `TripRequest::authorize()` PUT -> `tenant.trip.update` | Authorized |
| 5 | **Verify**: `TripRequest` rules pass | Valid |
| 6 | **Verify**: `TripController@update()`: `TptTrip::find($id)` | Trip found |
| 7 | **Verify**: `DB::transaction()` wraps update + notification | Transaction active |
| 8 | **Verify**: `$trip->update()` with all fields | DB updated |
| 9 | **Verify**: Model boot() `saving()`: Scheduled->Ongoing allowed | Passes DomainException check |
| 10 | **Verify**: `activityLog($trip, 'Updated', ['message' => 'Trip and stop details updated successfully.'])` | Log entry created |
| 11 | **Verify**: DB transaction commits | Committed |
| 12 | DB check: `SELECT status FROM tpt_trip WHERE id = X` | 'Ongoing' |

### TC-P06: Update Status Ongoing -> Completed

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Trip exists with status='Ongoing' | Existing |
| 2 | Edit trip, change status to 'Completed' | Form |
| 3 | Save | PUT |
| 4 | **Verify**: Model boot() `saving()`: Ongoing->Completed allowed | Passes |
| 5 | DB check: status = 'Completed' | Updated |

### TC-P07: Update Trip Change Vehicle

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Trip exists with vehicle_id=V1 | Existing |
| 2 | Edit, change vehicle to V2 (valid fitness+insurance >= trip_date) | Form |
| 3 | Save | PUT |
| 4 | **Verify**: TripRequest vehicle_id closure: V2 fitness_valid_upto >= trip_date | Pass |
| 5 | **Verify**: TripRequest vehicle_id closure: V2 insurance_valid_upto >= trip_date | Pass |
| 6 | DB check: `SELECT vehicle_id FROM tpt_trip WHERE id = X` | V2 |
| 7 | **Note**: boot() `creating` only fires on create, not on update | No re-check on update |

### TC-P08: Soft Delete Trip

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Trip exists with id=X | Existing |
| 2 | Click delete on trip row | DELETE `/trip/{id}` |
| 3 | **Verify**: `Gate::authorize('tenant.trip.delete')` passes | Authorized |
| 4 | **Verify**: `DB::transaction()` starts | Transaction active |
| 5 | **Verify**: `TptTrip::find($id)` returns record | Found |
| 6 | **Verify**: `TptTripStopDetail::where('trip_id', X)->delete()` | Stop details hard-deleted |
| 7 | DB check: `SELECT * FROM tpt_trip_stop_detail WHERE trip_id = X` | 0 rows (hard-deleted) |
| 8 | **Verify**: `$trip->delete()` | Soft delete, deleted_at set |
| 9 | **Verify**: `activityLog($trip, 'Deleted', ['message' => 'Trip and related stop details deleted.'])` | Log entry created |
| 10 | **Verify**: `DB::commit()` | Committed |
| 11 | DB check: `SELECT deleted_at FROM tpt_trip WHERE id = X` | deleted_at IS NOT NULL |
| 12 | **Verify**: Redirect with flash 'trashed.trip' | Success message |

### TC-P09: Trash Page Shows Deleted Trips

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.trip.restore` permission | Authenticated |
| 2 | Navigate to `/trip/trash/view` | Trash page |
| 3 | **Verify**: `Gate::authorize('tenant.trip.restore')` passes | Authorized |
| 4 | **Verify**: `TptTrip::onlyTrashed()->latest()->paginate(20)` | Trashed records only |
| 5 | **Verify**: Only soft-deleted trips shown (deleted_at IS NOT NULL) | Filtered |
| 6 | **Verify**: Restore and Force Delete action buttons visible | Actions present |
| 7 | **Verify**: Pagination if >20 trashed trips | Pagination links |

### TC-P10: Restore Trip

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-deleted trip exists with id=X | Trashed |
| 2 | Click restore on trash page | GET `/trip/{id}/restore` |
| 3 | **Verify**: `Gate::authorize('tenant.trip.restore')` passes | Authorized |
| 4 | **Verify**: `TptTrip::onlyTrashed()->find($id)` returns record | Found |
| 5 | **Verify**: `$trip->restore()` | deleted_at = NULL |
| 6 | **Verify**: `activityLog($trip, 'Restored', ['message' => 'Trip restored successfully.'])` | Log entry |
| 7 | DB check: `SELECT deleted_at FROM tpt_trip WHERE id = X` | NULL |
| 8 | DB check: `SELECT * FROM tpt_trip_stop_detail WHERE trip_id = X` | 0 rows (hard-deleted, NOT restored) |
| 9 | **Verify**: Redirect with flash 'restored.trip' | Success message |

### TC-P11: Force Delete Trip

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-deleted trip exists with id=X | Trashed |
| 2 | Click force delete on trash page | DELETE `/trip/{id}/force-delete` |
| 3 | **Verify**: `Gate::authorize('tenant.trip.forceDelete')` passes | Authorized |
| 4 | **Verify**: `TptTrip::onlyTrashed()->find($id)` returns record | Found |
| 5 | **Verify**: `$trip->forceDelete()` | Permanently deleted |
| 6 | DB check: `SELECT * FROM tpt_trip WHERE id = X` | 0 rows |
| 7 | **Verify**: `activityLog($trip, 'ForceDeleted', ['message' => 'Trip permanently deleted.'])` | Log entry |

### TC-P12: Approve Single Trip

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Trip: approved=0, start_odometer=100, end_odometer=150, has vendor | Existing |
| 2 | POST `/trip/toggle-approve` with `id=X, status=1` | AJAX |
| 3 | **Verify**: `Gate::authorize('tenant.trip-approve.approve')` passes | Authorized |
| 4 | **Verify**: `TptTrip::find($request->id)` | Trip found |
| 5 | **Verify**: `$distanceUsed = max(0, round(150-100, 2)) = 50` | 50.00 |
| 6 | **Verify**: `$trip->update(['approved'=>1, 'approved_by'=>Auth::id(), 'approved_at'=>now()])` | DB updated |
| 7 | **Verify**: `VndUsageLog::firstOrCreate(...)` with qty_used=50 | Log created |
| 8 | DB check: `SELECT approved FROM tpt_trip WHERE id = X` | 1 |
| 9 | DB check: `SELECT qty_used FROM vnd_usage_logs WHERE remarks LIKE 'Trip Approved (Trip ID: X)'` | 50.00 |
| 10 | **Verify**: JSON response `{status: true, message: 'Trip approved'}` | 200 OK |

### TC-P13: Unapprove Single Trip

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Trip: approved=1, VndUsageLog exists | Approved trip |
| 2 | POST `/trip/toggle-approve` with `id=X, status=0` | AJAX |
| 3 | **Verify**: `$trip->update(['approved'=>0, 'approved_by'=>null, 'approved_at'=>null])` | DB updated |
| 4 | **Verify**: `VndUsageLog::where('remarks', "Trip Approved (Trip ID: X)")->delete()` | Log deleted |
| 5 | DB check: `SELECT approved FROM tpt_trip WHERE id = X` | 0 |
| 6 | DB check: `SELECT * FROM vnd_usage_logs WHERE remarks LIKE '%Trip Approved (Trip ID: X)%'` | 0 rows |
| 7 | **Verify**: JSON response `{status: true, message: 'Trip disapproved'}` | 200 OK |

### TC-P14: Bulk Approve Trips

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Trip A (approved=0, has vendor), Trip B (approved=1), Trip C (approved=0, no vendor) | 3 trips |
| 2 | POST `/trip/bulk-approve` with `trip_ids=[A,B,C], action=approve` | AJAX |
| 3 | **Verify**: `Gate::authorize('tenant.trip-approve.bulkApprove')` passes | Authorized |
| 4 | **Verify**: Inline validation: trip_ids required|array, action required|in:approve,unapprove | Valid |
| 5 | **Verify**: `TptTrip::whereIn('id', [A,B,C])->get()` | 3 records |
| 6 | **Trip B (approved=1)**: `if ($trip->approved) { continue; }` | Skipped |
| 7 | **Trip A (has vendor)**: approved=1, VndUsageLog created | Approved |
| 8 | **Trip C (no vendor)**: approved=1, VndUsageLog NOT created | Approved without log |
| 9 | DB check: Trip A approved=1 | Correct |
| 10 | DB check: Trip B approved=1 (unchanged) | Correct |
| 11 | DB check: Trip C approved=1 | Correct |
| 12 | **Verify**: JSON response `{status: true, message: '3 trip(s) updated successfully'}` | 200 OK |

### TC-P15: Bulk Update Time

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Trip A (start=null, end=null, vehicle=V1), Trip B (start=08:00, end=10:00, vehicle=V2) | Selected |
| 2 | POST with `trip_ids=[A,B], bulk_start_time=07:00, bulk_end_time=09:00, vehicle_id=V3` | AJAX |
| 3 | **Verify**: `Gate::authorize('tenant.trip.update')` passes | Authorized |
| 4 | **Verify**: Inline validate: trip_ids.required, bulk_start_time.date_format:H:i, bulk_end_time.date_format:H:i, vehicle_id.exists | Valid |
| 5 | **Verify**: `TptTrip::whereIn('id', [A,B])->get()` | 2 records |
| 6 | **Trip A**: start_time = Carbon::parse(trip_date)->setTime(7,0), end_time = setTime(9,0), vehicle_id=V3 | Updated |
| 7 | **Trip B**: same updates | Updated |
| 8 | **Verify**: Each gets remarks = 'Time updated via bulk update' | Remark set |
| 9 | DB check: Trip A start_time = '2026-07-21 07:00:00', end_time = '2026-07-21 09:00:00', vehicle_id=V3 | Correct |
| 10 | **Verify**: Redirect back with "2 trip(s) updated successfully!" | Success |

### TC-P16: Update Remark

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Trip with remarks=null | Existing |
| 2 | POST `/trip/update-remark` with `trip_id=X, remarks="Driver was late"` | AJAX |
| 3 | **Verify**: `Gate::authorize('tenant.trip.update')` passes | Authorized |
| 4 | **Verify**: Inline validate: trip_id.required|exists:tpt_trip,id, remarks.nullable|string|max:500 | Valid |
| 5 | **Verify**: `TptTrip::find($request->trip_id)` | Trip found |
| 6 | **Verify**: `$trip->remarks = "Driver was late"; $trip->save()` | Saved |
| 7 | DB check: `SELECT remarks FROM tpt_trip WHERE id = X` | 'Driver was late' |
| 8 | **Verify**: JSON `{status: true, message: 'Remark updated successfully'}` | 200 OK |

### TC-P17: Prepare Stop Details

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Trip: route_id=R1, routeScheduler.shift_id=S1 | Existing |
| 2 | PickupPointRoute: 3 stops for route=R1, shift=S1 | Stops A, B, C |
| 3 | GET `/stop/details/prepare?trip_id=X` | AJAX |
| 4 | **Verify**: `Gate::authorize('tenant.stop-details.prepare')` passes | Authorized |
| 5 | **Verify**: `TptTrip::with('routeScheduler')->find(tripId)` | Trip found |
| 6 | **Verify**: `PickupPointRoute::with('pickupPoint')->where('route_id',R1)->where('shift_id',S1)->get()` | 3 stops |
| 7 | **Verify**: `DB::beginTransaction()` | Transaction active |
| 8 | **Stop A**: not exists -> create TptTripStopDetail | Created |
| 9 | **Verify**: `activityLog($stop, 'Create', [...])` | Logged |
| 10 | **Stop B**: same process | Created |
| 11 | **Stop C**: same process | Created |
| 12 | **Verify**: `DB::commit()` | Committed |
| 13 | DB check: `SELECT * FROM tpt_trip_stop_detail WHERE trip_id = X` | 3 rows |
| 14 | **Verify**: JSON `{status: true, message: 'Trip stops prepared successfully', inserted: 3, skipped: 0}` | 200 OK |

### TC-P18 through TC-P25: Filter Tests

| TC ID | Step # | Action | Expected Result |
|-------|--------|--------|-----------------|
| TC-P18 | 1 | Enter trip_date = '2026-07-21' | Date set |
| TC-P18 | 2 | Submit | GET with trip_date |
| TC-P18 | 3 | TripQuery: `where('trip_date', '2026-07-21')` | Filter applied |
| TC-P19 | 1 | Select route_id=R1, vehicle_id=V1, driver_id=D1 | Filters |
| TC-P19 | 2 | TripQuery: `whereHas('routeScheduler', fn=>where('route_id',R1))->where('vehicle_id',V1)->where('driver_id',D1)` | 3 filters |
| TC-P20 | 1 | Select approval_status='approved' | Filter |
| TC-P20 | 2 | TripQuery: `where('approved', 1)` | Approved filter |
| TC-P21 | 1 | Select status='Ongoing' | Filter |
| TC-P21 | 2 | TripQuery: `where('status', 'Ongoing')` | Status filter |
| TC-P22 | 1 | Enter search='Main' | Search |
| TC-P22 | 2 | TripQuery: whereHas route name/code LIKE OR vehicle LIKE OR driver LIKE | Search across entities |
| TC-P23 | 1 | No trips match filters | Empty state |
| TC-P23 | 2 | "No Data Found" or equivalent | Empty message |
| TC-P24 | 1 | 15 trips exist (>10) | Data |
| TC-P24 | 2 | TripQuery paginate(10) -> page 1 shows 10 | Pagination |
| TC-P24 | 3 | Pagination links for page 2 | Links visible |
| TC-P25 | 1 | Navigate to tab=trip_approve | Tab loads |
| TC-P25 | 2 | TripQuery() same filters | Filters work |

### TC-P26: Get Route Schedules AJAX

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | GET `/get-route-schedules?trip_date=2026-07-21&shift_id=1` | AJAX |
| 2 | **Verify**: `Gate::authorize('tenant.trip.view')` passes | Authorized |
| 3 | **Verify**: `TptRouteSchedulerJnt::with(['route','shift'])->whereDate('scheduled_date','2026-07-21')->where('shift_id',1)->get()` | Matching schedulers |
| 4 | **Verify**: JSON: `[{id, route_name, shift_name, vehicle_id, driver_id, helper_id}, ...]` | Correct format |

### TC-P27: Trip Details Data AJAX

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | TptTripStopDetail exists with id=X | Existing |
| 2 | GET `/trip/details/edits?id=X` | AJAX |
| 3 | **Verify**: `Gate::authorize('tenant.stop-details.view')` passes | Authorized |
| 4 | **Verify**: `TptTripStopDetail::where('id', X)->first()` | Record fetched |
| 5 | **Verify**: JSON `{status: true, message: 'Trip Data Get successfully', inserted: {...}}` | 200 OK |

### TC-P28: Trip Details Updated AJAX

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | TptTripStopDetail with reaching_time=null | Existing |
| 2 | POST `/trip/details/updates` with `id=X, reaching_time=08:00, leaving_time=08:05` | AJAX |
| 3 | **Verify**: `Gate::authorize('tenant.stop-details.update')` passes | Authorized |
| 4 | **Verify**: `TptTripStopDetail::find($request->id)` | Found |
| 5 | **Verify**: `activityLog($stop, 'Updated', [...])` BEFORE update | Logged |
| 6 | **Verify**: `$stop->update(['reaching_time'=>'08:00', 'leaving_time'=>'08:05', ...])` | DB updated |
| 7 | **Verify**: JSON `{status: true}` | 200 OK |

### TC-P29: Stop Action start_trip

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Trip: status='Scheduled', start_time=null | Existing |
| 2 | POST with `id={stopId}, action=start_trip, extra={start_time:"07:00", start_odometer:1000, start_fuel:50}` | AJAX |
| 3 | **Verify**: `Gate::authorize('tenant.stop-details.update')` passes | Authorized |
| 4 | `$isNew = false` (existing stop ID) | Existing path |
| 5 | `TptTripStopDetail::with('trip.routeScheduler')->find(id)` | Found |
| 6 | `$updatedBy = $trip->routeScheduler->driver_id` | From scheduler |
| 7 | `$stop->update(['reached_flag'=>1, 'reaching_time'=>now, 'leaving_time'=>now, 'updated_by'=>$updatedBy])` | Stop first/last mark |
| 8 | `$request->filled('extra')` -> trip: status='Ongoing', start_time, odometer, fuel | Trip started |
| 9 | `TptNotificationLog::create(['notification_type'=>'TripStart', ...])` | Notification created |
| 10 | DB: status='Ongoing', start_time set, start_odometer=1000 | Correct |
| 11 | DB: notification_log has 'TripStart' | Notification exists |

### TC-P30: Stop Action reach

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Stop with reached_flag=0 | Existing |
| 2 | POST with `id={stopId}, action=reach` | AJAX |
| 3 | `$stop->update(['reached_flag'=>1, 'reaching_time'=>now, 'updated_by'=>$updatedBy])` | Stop reached |
| 4 | If now > sch_arrival_time + 5min -> 'Delayed', else 'ReachedStop' | Correct type |
| 5 | `TptNotificationLog::create(['notification_type'=>$notificationType])` | Notification |
| 6 | DB: reached_flag=1, reaching_time set | Correct |

### TC-P31: Stop Action leave

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Stop with leaving_time=null | Existing |
| 2 | POST with `id={stopId}, action=leave` | AJAX |
| 3 | `$stop->update(['leaving_time'=>now, 'updated_by'=>$updatedBy])` | Stop left |
| 4 | `TptNotificationLog::create(['notification_type'=>'ApproachingStop'])` | Notification |
| 5 | DB: leaving_time set | Correct |

### TC-P32: Stop Action end_trip

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Trip: status='Ongoing' | Existing |
| 2 | POST with `id={lastStopId}, action=end_trip, extra={end_time:"09:00", end_odometer:1050, end_fuel:40}` | AJAX |
| 3 | `$stop->update(['reached_flag'=>1, 'reaching_time'=>now, 'leaving_time'=>now])` | Last stop finalized |
| 4 | `$trip->update(['end_time'=>..., 'end_odometer_reading'=>1050, 'end_fuel_reading'=>40, 'status'=>'Completed'])` | Trip completed |
| 5 | DB: status='Completed', end_time set, end_odometer=1050 | Correct |
| 6 | **Note**: end_trip does NOT create a notification | No notification |

### TC-P33: Stop Action emergency

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Stop with emergency_flag=0 | Existing |
| 2 | POST with `id={stopId}, action=emergency, remark="Engine failure"` | AJAX |
| 3 | `$stop->update(['emergency_flag'=>1, 'emergency_time'=>now, 'emergency_remarks'=>'Engine failure', 'updated_by'=>$updatedBy])` | Emergency set |
| 4 | `TptTripIncidents::create(['trip_id'=>$stop->trip_id, 'incident_time'=>now, 'incident_type'=>0, 'description'=>'Engine failure', 'status'=>0, 'raised_by'=>$raisedBy, 'raised_at'=>now, 'severity'=>'MEDIUM'])` | Incident created |
| 5 | DB: emergency_flag=1 | Correct |
| 6 | DB: tpt_trip_incidents record exists | Incident logged |

### TC-P34: Trip Standalone Index

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | GET `/trip` (non-tab standalone index) | Page loads |
| 2 | **Verify**: `Gate::authorize('tenant.trip.viewAny')` passes | Authorized |
| 3 | **Verify**: `TptTrip::with(['routeScheduler','vehicle','driver','helper','shift'])->paginate(20)` | 20 per page |

### TC-P35: Prepare Stop Details Skip Existing

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | 2 stop details already exist for trip X (A, B) | Existing |
| 2 | GET `/stop/details/prepare?trip_id=X` where route has 5 stops | AJAX |
| 3 | Loop: stops A,B exist -> skip; C,D,E -> create | 3 inserted, 2 skipped |
| 4 | JSON: `{inserted: 3, skipped: 2}` | Correct counts |

### TC-P36: Bulk Approve All Unapproved

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | 3 unapproved trips all with vendors | 3 trips |
| 2 | POST with action=approve | Bulk approve |
| 3 | All 3 approved, 3 VndUsageLogs created | 3/3 |

### TC-P37: Bulk Unapprove

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | 2 approved trips with VndUsageLogs | 2 approved |
| 2 | POST with action=unapprove | Bulk unapprove |
| 3 | Loop: 'unapprove' -> VndUsageLog deleted, approved=0 | Both unapproved |

### TC-P38: Bulk Update Time Start Only

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST with bulk_start_time=08:00, no bulk_end_time | Partial |
| 2 | $updateData has only 'start_time' | No end_time |
| 3 | start_time updated, end_time unchanged | Partial |

### TC-P39: Bulk Update Vehicle Only

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST with vehicle_id=V2, no times, no driver | Vehicle only |
| 2 | $updateData has only 'vehicle_id' | Vehicle changed |

### TC-P40: getRouteSchedules with include_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Scheduler id=5 has scheduled_date=2026-07-20 (different) | Different date |
| 2 | GET `/get-route-schedules?trip_date=2026-07-21&shift_id=1&include_id=5` | Include ID |
| 3 | Query: `whereDate('scheduled_date','2026-07-21')->where('shift_id',1)->orWhere('id',5)` | Scheduler 5 included |

---

### TC-N01: Required — Missing trip_date

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to create form | Form loads |
| 2 | Fill all fields except trip_date | trip_date empty |
| 3 | Click Save | POST `/trip` |
| 4 | **Verify**: TripRequest rule: trip_date required | "The trip date field is required." |
| 5 | **Verify**: Error displayed on form | Validation error |

### TC-N02: Required — Missing route_scheduler_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Fill all fields except route_scheduler_id | Empty |
| 2 | Click Save | POST |
| 3 | **Verify**: TripRequest: route_scheduler_id required | "The route schedule is required." |

### TC-N03: Required — Missing vehicle_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Fill all fields except vehicle_id | Empty |
| 2 | Click Save | POST |
| 3 | **Verify**: TripRequest: vehicle_id required | "The vehicle is required." |

### TC-N04: Required — Missing driver_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Fill all fields except driver_id | Empty |
| 2 | Click Save | POST |
| 3 | **Verify**: TripRequest: driver_id required | "The driver is required." |

### TC-N05: Duplicate trip_date + route_scheduler_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create trip with trip_date=2026-07-21, route_scheduler_id=5 | Trip exists |
| 2 | Navigate to create form | Form loads |
| 3 | Enter same trip_date=2026-07-21, same route_scheduler_id=5 | Duplicate |
| 4 | Click Save | POST |
| 5 | **Verify**: TripRequest unique rule: `Rule::unique('tpt_trip','trip_date')->where('route_scheduler_id',5)->whereNull('deleted_at')` | Fires |
| 6 | **Verify**: "A trip is already scheduled for this date with the selected route schedule." | Error displayed |

### TC-N06: Invalid status value

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create form, set status = 'Invalid' | Invalid value |
| 2 | Click Save | POST |
| 3 | **Verify**: Rule::in(['Scheduled','Ongoing','Completed','Cancelled']) fails | "The selected status is invalid." |

### TC-N07: Helper equals Driver

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create form, set driver_id=D1, helper_id=D1 (same) | Same person |
| 2 | Click Save | POST |
| 3 | **Verify**: `different:driver_id` rule fails | "Driver and helper cannot be the same person." |

### TC-N08: End Time Before Start Time

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create form, start_time=10:00, end_time=09:00 | End before start |
| 2 | Click Save | POST |
| 3 | **Verify**: Closure: `if ($value && $this->start_time && strtotime($value) < strtotime($this->start_time))` | "End time must be after or equal to start time." |

### TC-N09: Expired Driver License

| Step # | Action | Expected Result |
|------- $driver = DriverHelper::find($value) |--------|-----------------|
| 1 | Driver D1 has license_valid_upto = 2026-01-01 (expired) | Expired license |
| 2 | Create trip with trip_date=2026-07-21, driver_id=D1 | After expiry |
| 3 | Click Save | POST |
| 4 | **Verify**: TripRequest closure: `$driver->license_valid_upto->lt(Carbon::parse($tripDate))` | "Driver 'X' has an expired license (valid upto: 2026-01-01)." |
| 5 | **Verify**: Model boot() creating also catches | DomainException |

### TC-N10: Expired Vehicle Fitness

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Vehicle V1 has fitness_valid_upto = 2026-01-01 (expired) | Expired |
| 2 | Create trip with trip_date=2026-07-21, vehicle_id=V1 | After expiry |
| 3 | **Verify**: TripRequest closure: `$vehicle->fitness_valid_upto->lt(Carbon::parse($tripDate))` | "Vehicle 'X' has an expired fitness certificate (valid upto: 2026-01-01)." |

### TC-N11: Expired Vehicle Insurance

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Vehicle V1 has insurance_valid_upto = 2026-01-01 (expired) | Expired |
| 2 | Create trip with trip_date=2026-07-21, vehicle_id=V1 | After expiry |
| 3 | **Verify**: TripRequest closure: `$vehicle->insurance_valid_upto->lt(Carbon::parse($tripDate))` | "Vehicle 'X' has expired insurance (valid upto: 2026-01-01)." |

### TC-N12: Invalid Status Transition (Completed -> Ongoing)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create trip with status='Scheduled' | Trip created |
| 2 | Update status to 'Completed' | Update succeeds |
| 3 | Try updating status back to 'Ongoing' | PUT with status='Ongoing' |
| 4 | **Verify**: Model boot() saving(): oldStatus='Completed', newStatus='Ongoing' | `$allowed['Completed'] = []` — no transitions allowed |
| 5 | **Verify**: `throw new \DomainException("Invalid trip status transition from Completed to Ongoing.")` | DomainException |
| 6 | DB check: Status remains 'Completed' | Unchanged |

### TC-N13: Invalid Status Transition (Cancelled -> Scheduled)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create trip with status='Scheduled' | Trip created |
| 2 | Update status to 'Cancelled' | Allowed |
| 3 | Try updating status back to 'Scheduled' | PUT with status='Scheduled' |
| 4 | **Verify**: `$allowed['Cancelled'] = []` — no transitions allowed | DomainException |
| 5 | DB check: Status remains 'Cancelled' | Unchanged |

### TC-N14: View With Invalid ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | GET `/trip/99999` with non-existent ID | Invalid ID |
| 2 | **Verify**: `TptTrip::find(99999)` returns null | null |
| 3 | **Verify**: Controller redirects: `return redirect()->route('transport.trip-management.index', ['tab' => 'daily_trip'])->with('error', 'Trip not found.')` | Redirect (NOT 404) |

### TC-N15 through TC-N19: Invalid ID Handling

| TC ID | Step | Action | Expected Result |
|-------|------|--------|-----------------|
| TC-N15 | 1 | GET `/trip/99999/edit` | Non-existent |
| TC-N15 | 2 | `TptTrip::find(99999)` null -> redirect with 'Trip not found.' | Redirect (NOT 404) |
| TC-N16 | 1 | PUT `/trip/99999` | Non-existent |
| TC-N16 | 2 | `TptTrip::find(99999)` null -> redirect back with 'Trip not found.' | Redirect (NOT 404) |
| TC-N17 | 1 | DELETE `/trip/99999` | Non-existent |
| TC-N17 | 2 | `TptTrip::find(99999)` null -> `throw new \Exception('Trip not found.')` | **500 error** (unlike others) |
| TC-N18 | 1 | GET `/trip/99999/restore` on active trip (not trashed) | Not trashed |
| TC-N18 | 2 | `TptTrip::onlyTrashed()->find(99999)` null -> redirect with 'Trip not found in trash.' | Redirect |
| TC-N19 | 1 | DELETE `/trip/99999/force-delete` on active trip | Not trashed |
| TC-N19 | 2 | `TptTrip::onlyTrashed()->find(99999)` null -> redirect with 'Trip not found in trash.' | Redirect |

### TC-N20: Approve Non-Existent Trip

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST `/trip/toggle-approve` with id=99999 | Non-existent |
| 2 | **Verify**: `TptTrip::find(99999)` null -> `return response()->json(['status'=>false,'message'=>'Trip not found.'], 404)` | 404 JSON |

### TC-N21 through TC-N26: Permission 403 Tests

| TC ID | Step | Action | Expected Result |
|-------|------|--------|-----------------|
| TC-N21 | 1 | GET `/trip` without tenant.trip.viewAny | 403 |
| TC-N21 | 2 | GET `/trip/create` without tenant.trip.create | 403 |
| TC-N21 | 3 | POST `/trip` without tenant.trip.create | 403 |
| TC-N21 | 4 | PUT `/trip/{id}` without tenant.trip.update | 403 |
| TC-N21 | 5 | DELETE `/trip/{id}` without tenant.trip.delete | 403 |
| TC-N22 | 1 | POST `/trip/stop-action` without tenant.stop-details.update | 403 |
| TC-N22 | 2 | POST `/trip/details/updates` without tenant.stop-details.update | 403 |
| TC-N23 | 1 | GET `/trip/details/edits` without tenant.stop-details.view | 403 |
| TC-N24 | 1 | GET `/stop/details/prepare` without tenant.stop-details.prepare | 403 |
| TC-N25 | 1 | POST `/trip/toggle-approve` without tenant.trip-approve.approve | 403 |
| TC-N26 | 1 | POST `/trip/bulk-approve` without tenant.trip-approve.bulkApprove | 403 |

### TC-N27: Guest Access Redirect

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Logout (no authenticated user) | Guest |
| 2 | Access ANY endpoint | Redirect to `/login` |

### TC-N28: XSS Injection

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create trip with remarks = `<script>alert('XSS')</script>` | Stored |
| 2 | Save | Trip created |
| 3 | DB check: remarks field contains `<script>` literal | Stored as-is |
| 4 | View trip show/edit page | Blade escapes: `{{ }}` -> `&lt;script&gt;` |

### TC-N29: Bulk Approve Already Approved Skipped

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Trip A: approved=1 (already approved), Trip B: approved=0 | Mixed |
| 2 | POST bulk-approve with action=approve, trip_ids=[A,B] | Process |
| 3 | **Verify**: Loop: A has approved=1 -> continue (skip) | Skipped |
| 4 | **Verify**: B has approved=0 -> approve + create log | Approved |
| 5 | **Verify**: VndUsageLog for A NOT duplicated | Single log for A remains |

### TC-N30: Bulk Update No Valid Trips

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST with trip_ids=[999, 998] (non-existent) | Invalid |
| 2 | **Verify**: `TptTrip::whereIn('id', [999,998])->get()` -> `$trips->isEmpty()` | true |
| 3 | `return back()->with('error', 'No valid trips selected!')` | Error message |

### TC-N31: Bulk Update Invalid vehicle_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST with vehicle_id=99999 | Invalid |
| 2 | **Verify**: Inline validation: `'vehicle_id' => 'nullable|exists:Modules\Transport\Models\Vehicle,id'` | Fails |

### TC-N32: Bulk Update Invalid time format

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST with bulk_start_time='25:00' | Invalid |
| 2 | **Verify**: `'bulk_start_time' => 'nullable|date_format:H:i'` | "does not match the format H:i." |

### TC-N33: Approve without trip_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST `/trip/toggle-approve` without id | Missing parameter |
| 2 | **Verify**: `TptTrip::find(null)` -> null | 404 JSON |

### TC-N34: stopAction invalid action

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST with action='invalid_action' | Unknown action |
| 2 | **Verify**: switch($request->action) no matching case, no default | Falls through |
| 3 | **Verify**: No state changes made | Silent success |

### TC-N35: stopAction non-existent stop

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST with id=99999 (non-existent stop) | Invalid |
| 2 | **Verify**: `TptTripStopDetail::with(...)->find(99999)` null | 404 JSON |

### TC-N36: tripDetailsUpdated non-existent stop

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST with id=99999 | Invalid |
| 2 | **Verify**: `TptTripStopDetail::find(99999)` null | 404 JSON "Stop Detail not found." |

### TC-N37: stopDetailsPrepare without trip_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | GET without trip_id | Missing |
| 2 | **Verify**: `empty($tripId)` -> 400 JSON "Trip ID is required" | 400 error |

### TC-N38: stopDetailsPrepare invalid trip_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | GET with trip_id=99999 | Invalid |
| 2 | **Verify**: `TptTrip::with('routeScheduler')->find(99999)` null | 404 JSON "Trip not found" |

### TC-N39: updateRemark invalid trip_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST with trip_id=99999 | Invalid |
| 2 | **Verify**: Inline validate: `'trip_id' => 'required|exists:tpt_trip,id'` | "The selected trip id is invalid." |

### TC-N40: tripDetailsData non-existent id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | GET with id=99999 | Invalid |
| 2 | **Verify**: `TptTripStopDetail::where('id', 99999)->first()` returns null | null |
| 3 | **Verify**: JSON response `{status: true, message: 'Trip Data Get successfully', inserted: null}` (NOT 404) | Null in response |

---

### TC-D01: Delete Trip Stop Details Manually Deleted

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Trip with 2 stop details | Existing |
| 2 | DELETE `/trip/{id}` | Destroy called |
| 3 | **Verify**: Controller destroy() line 397-398: `TptTripStopDetail::where('trip_id',X)->delete()` before `$trip->delete()` | Stop details hard-deleted first |
| 4 | DB check: `SELECT * FROM tpt_trip_stop_detail WHERE trip_id = X` | 0 rows |

### TC-D02: NotificationLog SET NULL

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check DDL: tpt_notification_log.trip_id FK | ON DELETE SET NULL |
| 2 | Delete trip with notifications | trip_id set to NULL on notifications |

### TC-D03: BoardingLog SET NULL

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check DDL: student_boarding_logs boarding_trip_id / unboarding_trip_id | ON DELETE SET NULL |

### TC-D04: TripIncidents CASCADE

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check DDL: tpt_trip_incidents.trip_id FK | ON DELETE CASCADE |
| 2 | Delete trip -> incidents auto-deleted | CASCADE removes related incidents |

### TC-D05: Scheduler RESTRICT

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check DDL: tpt_trip.route_scheduler_id FK | ON DELETE RESTRICT |
| 2 | Try deleting TptRouteSchedulerJnt that has trips | DB error: Cannot delete due to FK constraint |

### TC-D06: VndUsageLog Created with Distance

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Trip: start_odometer=100, end_odometer=150 -> distance=50 | Distance calc |
| 2 | Approve trip | VndUsageLog created |
| 3 | DB: `SELECT qty_used FROM vnd_usage_logs WHERE remarks LIKE '%Trip Approved (Trip ID: X)%'` | 50.00 |

### TC-D07: Bulk Approve Skip Already Approved

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Trip A (approved=0), Trip B (approved=1) | Mixed |
| 2 | Bulk approve both | Trip A approved, Trip B skipped |
| 3 | **Verify**: `if ($trip->approved) { continue; }` | Trip B not re-processed |

### TC-D08: Trip Generation Via storeTrip

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | RouteSchedulerController@storeTrip creates trip | Trip auto-generated |
| 2 | Navigate to daily_trip tab | Trip visible in listing |

### TC-D09: Bulk Unapprove VndUsageLog Deleted

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Trip A and B both have approved=1 and VndUsageLogs | Approved |
| 2 | POST bulk-approve action=unapprove | Each: log deleted, fields reset |

### TC-D10: stopAction new_ Creates TptTripStopDetail

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST with id='new_5', action=start_trip | new_ prefix |
| 2 | Parses jntId=5, finds PickupPointRoute | Junction found |
| 3 | No existing TptTripStopDetail -> creates one | New record inserted |

### TC-D11: stopDetailsPrepare N+1 Activity Log

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | GET stopDetailsPrepare for route with 3 stops | 3 stops created |
| 2 | **Verify**: activityLog called for EACH stop inside loop | 3 activity log entries |

### TC-D12: Cancellation Notification

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Update trip status to 'Cancelled' | PUT |
| 2 | **Verify**: Inside DB transaction: TptNotificationLog created with type='Cancelled' | Notification created |

### TC-D13: Approve With Vendor firstOrCreate

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST toggle-approve twice (idempotent) | Two calls |
| 2 | **Verify**: firstOrCreate prevents duplicate log | Single VndUsageLog |

---

### TC-CR01: Gate::authorize() Before All State Changes

| Step # | Code Location | Gate |
|--------|--------------|------|
| 1 | TripController:31 index() | `Gate::authorize('tenant.trip.viewAny')` |
| 2 | TripController:41 create() | `Gate::authorize('tenant.trip.create')` |
| 3 | TripController:69 store() | `Gate::authorize('tenant.trip.create')` |
| 4 | TripController:102 show() | `Gate::authorize('tenant.trip.view')` |
| 5 | TripController:125 stopAction() | `Gate::authorize('tenant.stop-details.update')` |
| 6 | TripController:312 edit() | `Gate::authorize('tenant.trip.update')` |
| 7 | TripController:329 tripDetailsData() | `Gate::authorize('tenant.stop-details.view')` |
| 8 | TripController:345 update() | `Gate::authorize('tenant.trip.update')` |
| 9 | TripController:390 destroy() | `Gate::authorize('tenant.trip.delete')` |
| 10 | TripController:418 trashed() | `Gate::authorize('tenant.trip.restore')` |
| 11 | TripController:429 restore() | `Gate::authorize('tenant.trip.restore')` |
| 12 | TripController:450 forceDelete() | `Gate::authorize('tenant.trip.forceDelete')` |
| 13 | TripController:468 stopDetailsPrepare() | `Gate::authorize('tenant.stop-details.prepare')` |
| 14 | TripController:549 tripDetailsUpdated() | `Gate::authorize('tenant.stop-details.update')` |
| 15 | TripController:573 bulkUpdateTime() | `Gate::authorize('tenant.trip.update')` |
| 16 | TripController:634 toggleApproval() | `Gate::authorize('tenant.trip-approve.approve')` |
| 17 | TripController:704 bulkApprove() | `Gate::authorize('tenant.trip-approve.bulkApprove')` |
| 18 | TripController:791 updateRemark() | `Gate::authorize('tenant.trip.update')` |
| 19 | TripController:810 getRouteSchedules() | `Gate::authorize('tenant.trip.view')` |

### TC-CR02: activityLog After CRUD

| Step # | Method | Event | Message |
|--------|--------|-------|---------|
| 1 | update() | 'Updated' | 'Trip and stop details updated successfully.' |
| 2 | destroy() | 'Deleted' | 'Trip and related stop details deleted.' |
| 3 | restore() | 'Restored' | 'Trip restored successfully.' |
| 4 | forceDelete() | 'ForceDeleted' | 'Trip permanently deleted.' |
| 5 | stopDetailsPrepare() | 'Create' | 'Trip Details Create successfully.' (per stop, N+1) |
| 6 | tripDetailsUpdated() | 'Updated' | 'Trip Details update successfully.' (before update call) |

### TC-CR03 through TC-CR32: Code Review Checks

| TC ID | Step | Code Location | Expected |
|-------|------|--------------|----------|
| TC-CR03 | 1 | TripController:397-398 | `TptTripStopDetail::where('trip_id',...)->delete()` before trip delete |
| TC-CR04 | 1 | TripController:430,451 | Both restore and forceDelete use `onlyTrashed()->find()` |
| TC-CR05 | 1 | TptTrip:65-97 | boot() creating: driver license, vehicle fitness, vehicle insurance |
| TC-CR06 | 1 | TptTrip:99-117 | boot() saving: status transitions via $allowed array |
| TC-CR07 | 1 | TptTrip:22-45 | 17 fillable fields |
| TC-CR08 | 1 | TptTrip:127-222 | 9 relationships |
| TC-CR09 | 1 | RouteSchedulerController storeTrip | Sets 'created_by' but column NOT in DDL |
| TC-CR10 | 1 | TripRequest:16-19 | POST -> create; PUT/PATCH -> update |
| TC-CR11 | 1 | TripRequest:66-96 | Closures: driver license, vehicle fitness, vehicle insurance |
| TC-CR12 | 1 | TripRequest:52-55 | Unique with whereNull('deleted_at')->ignore($this->route('trip')) |
| TC-CR13 | 1 | web.php | Resource + 10+ custom routes |
| TC-CR14 | 1 | DDL | All FKs: RESTRICT on scheduler, vehicle, driver, helper |
| TC-CR15 | 1 | DDL | Indexes: idx_trip_routeSched_tripDate, idx_trip_vehicle |
| TC-CR16 | 1 | storeTrip | **GAP**: created_by column not in DDL -> SQL error |
| TC-CR17 | 1 | storeTrip | **GAP**: shift_id column not in DDL -> SQL error |
| TC-CR18 | 1 | destroy + restore | Stop details hard-deleted, NOT restored |
| TC-CR19 | 1 | web.php | **GAP**: toggleStatus route registered, no method in controller |
| TC-CR20 | 1 | TripMgmtController:364-413 | TripQuery filters: trip_date, route_id, vehicle_id, driver_id, approval_status, status, search |
| TC-CR21 | 1 | TripController:519-521 | activityLog inside loop -> N+1 |
| TC-CR22 | 1 | TripController:556-558 | activityLog BEFORE $stop->update() |
| TC-CR23 | 1 | TripController:369-376 | Cancellation: TptNotificationLog inside transaction |
| TC-CR24 | 1 | TripController:131-172 | new_ ID: parse jntId, find/create stop detail |
| TC-CR25 | 1 | TripRequest:52-55 | ignore($this->route('trip')) handles update uniqueness |
| TC-CR26 | 1 | TripController:575-581 | Uses `$request->validate()` not TripRequest |
| TC-CR27 | 1 | TripController:626 | **BUG**: `DB::rollBack()` without `DB::beginTransaction()` |
| TC-CR28 | 1 | TripController:763-779 | optional()->routeScheduler->vehicle->vendor may break |
| TC-CR29 | 1 | TripController:86 | route_id from $routeScheduler, NOT from request |
| TC-CR30 | 1 | TripController:115 | first() only gets one stop detail |
| TC-CR31 | 1 | TptTrip:216-222 | boardingLogs() orWhere may cause SQL issues |
| TC-CR32 | 1 | web.php | **GAP**: toggleStatus route -> 500 error "Method not found" |

---
