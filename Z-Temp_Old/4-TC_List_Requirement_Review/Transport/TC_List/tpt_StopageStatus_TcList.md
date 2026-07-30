# tpt_StopageStatus_TcList

## Module: Transport → Trip Management → Stopage Status (Trip Stop Live Tracking)

---

## 1. Feature Information

| Attribute | Details |
|-----------|---------|
| **Module** | Transport (TPT) |
| **Entity** | Stopage Status — Live stop tracking actions (reach/leave/emergency/start_trip/end_trip) |
| **Primary Controller** | `Modules\Transport\Http\Controllers\TripController` — 4 stop-specific methods: `stopAction()`, `stopDetailsPrepare()`, `tripDetailsData()`, `tripDetailsUpdated()` |
| **Tab Container Controller** | `Modules\Transport\Http\Controllers\TripMgmtController@index()` — tab id `stop_status`, private `tripStopTimeline()` for timeline listing |
| **Primary Model** | `Modules\Transport\Models\TptTripStopDetail` — table: `tpt_trip_stop_detail`, SoftDeletes, 13 fillable fields, 3 relationships |
| **Related Models** | `TptTrip` (status/live tracking), `PickupPointRoute` (stop definitions), `TptTripIncidents` (emergency), `TptNotificationLog` (notifications), `PickupPoint` (stop name) |
| **Form Request** | None — `stopAction()` and `tripDetailsUpdated()` use raw `$request->input()` with NO validation request |
| **Policy** | `Modules\Transport\Policies\TransportStopDetailsPolicy` — 10 permission methods |
| **Route Prefix** | Stop action: `trip.stop-action` (POST `/trip/stop-action`); Prep: `stop-details.prepare` (GET `/stop/details/prepare`); Data: `trip.details.edits` (GET `/trip/details/edits`); Update: `trip.details.updates` (POST `/trip/details/updates`) |
| **Blade Views** | `trip-details/index.blade.php` (tab partial — Stopage Status Update tab) |
| **Tab Container** | `tab_module/tripmanagement.blade.php` — tab id `stop_status`, permission `tenant.stop-details.viewAny` |
| **DB Table** | `tpt_trip_stop_detail` — 17 columns |
| **Primary Screen** | Trip Management → Stopage Status Update tab (shift/route filter + timeline UI) |

### URL Map

| URL | Method | Controller Method | Permission | Purpose |
|-----|--------|-------------------|------------|---------|
| `/transport/trip-management` | GET | `TripMgmtController@index()` | `tenant.transport.viewAny` | Tab container — renders stop_status tab |
| `/trip/stop-action` | POST | `TripController@stopAction()` | `tenant.stop-details.update` | Live action: reach/leave/emergency/start_trip/end_trip |
| `/stop/details/prepare` | GET | `TripController@stopDetailsPrepare()` | `tenant.stop-details.prepare` | Bulk-prepare stop details from PickupPointRoute |
| `/trip/details/edits` | GET | `TripController@tripDetailsData()` | `tenant.stop-details.view` | Fetch single stop detail as JSON |
| `/trip/details/updates` | POST | `TripController@tripDetailsUpdated()` | `tenant.stop-details.update` | Update single stop detail fields |

### Tab Config (tripmanagement.blade.php)

| Tab ID | Label | Permission | View Partial |
|--------|-------|------------|--------------|
| `stop_status` | Stopage Status Update | `tenant.stop-details.viewAny` | `transport::trip-details.index` |

---

## 2. Pre-conditions

| # | Pre-condition |
|---|--------------|
| PC-01 | User must be logged in (role with `tenant.stop-details.*` and/or `tenant.transport.viewAny` permissions) |
| PC-02 | Database `tpt_trip_stop_detail` table must exist with all 17 columns and FKs |
| PC-03 | A trip must exist for today (`tpt_trip.trip_date = CURDATE()`) with valid `route_scheduler_id` |
| PC-04 | `tpt_pickup_points_route_jnt` records must exist defining stop sequence (arrival_time as minutes, departure_time, ordinal, pickup_drop, shift_id, route_id) |
| PC-05 | `tpt_pickup_points` must have stop records |
| PC-06 | `tpt_shift` and `tpt_route` must have records matching jnt |
| PC-07 | `TransportStopDetailsPolicy` must be registered in `AuthServiceProvider` |
| PC-08 | `TripController` and `TripMgmtController` must be registered in routes (lines 53, 141-168) |
| PC-09 | Soft deletes enabled on `tpt_trip_stop_detail` |
| PC-10 | Browser must support JavaScript for AJAX POST to `stop-action` |
| PC-11 | `activityLog()` helper must be available and configured |
| PC-12 | `flash()` helper must have translation keys |
| PC-13 | `tpt_driver_route_vehicle_jnt` entries linking drivers to routes for driver-filtered views |
| PC-14 | `DriverHelper` with `user_id = auth()->id()` for driver login detection |
| PC-15 | For `stopDetailsPrepare`: trip must have `routeScheduler` eager-loadable |


## 3. Default Data Load

The Trip Management page (`TripMgmtController@index()`) loads multiple data sources. For the **Stopage Status Update** tab:

| # | Data Load Rule | Source |
|---|----------------|--------|
| DL-01 | Trip Management page via `Route::resource('trip-management', TripMgmtController::class)` | `TripMgmtController@index()` |
| DL-02 | `Gate::authorize('tenant.transport.viewAny')` — single gate for entire page | `TripMgmtController.php:38` |
| DL-03 | Driver detection: if `DriverHelper::where('user_id', auth()->id())` exists, filter routes to assigned | `TripMgmtController.php:43-51` |
| DL-04 | Trip ID resolution: finds first trip matching `?date=`, `?shift_id=`, `?route_id=`; merges trip_id/tripe_id | `TripMgmtController.php:54-71` |
| DL-05 | **Stop Timeline** (`tripStopTimeline()`): loads `PickupPointRoute` with `pickupPoint`; filtered by shift/route/pickup_drop when tab=`trip_details` | `TripMgmtController.php:253-344` |
| DL-06 | Driver route filter on timeline: only PickupPointRoute records with route_id in driver's assigned routes | `TripMgmtController.php:259-270` |
| DL-07 | Stop details mapped: each PickupPointRoute → matches TptTripStopDetail by trip_id+stop_id+pickup_drop+ordinal → returns unified timeline object (ID=`detail.id` or `new_{jntId}`) | `TripMgmtController.php:307-344` |
| DL-08 | Scheduled times: if no detail, arrival_time/departure_time from PickupPointRoute (minutes) converted via `Carbon::createFromTime(0,0)->addMinutes($min)->format('H:i:s')` | `TripMgmtController.php:334-335` |
| DL-09 | Timeline ordered by `ordinal ASC` | `TripMgmtController.php:286` |
| DL-10 | Fallback trip: if no trip matches exact route_id, falls back to first trip of the day | `TripMgmtController.php:305` |
| DL-11 | **Stop Details New** (`tripStopNew()`): paginated TptTripStopDetail with `stop` relation, filtered by trip_id/date/route_id/pickup_drop when tab=`stop_details` | `TripMgmtController.php:204-232` |
| DL-12 | View variables: `vehicles`, `routes`, `driverHelpers`, `shifts`, `TripData`, `stopDetails`, `StopDetailsNew`, `bordUnBordData`, `pickupPoints`, `driveAttendance`, `driverLiveRoute`, `driverRouteVehicles`, `sheduleData`, `notificationLog` | `TripMgmtController.php:92-111` |
| DL-13 | **Stop Status Tab Blade** (`trip-details/index.blade.php`): renders timeline with action stop calculation | `trip-details/index.blade.php:48-58` |
| DL-14 | Filter form: hidden `tab=trip_details`, shift dropdown, route dropdown (driver-filtered), submit/reset buttons | `trip-details/index.blade.php:5-41` |
| DL-15 | Empty state: "No stops found for the selected criteria." | `trip-details/index.blade.php:43-47` |
| DL-16 | Timeline UI: route-container (65vh scroll), each stop as route-row with ordinal circle/line/card showing name+badge+timings+actions | `trip-details/index.blade.php:60-180` |
| DL-17 | Stops are CO collection (PickupPointRoute entries with matched details) NOT queried from TptTripStopDetail directly | `TripMgmtController.php:256` |
| DL-18 | `PickupPointRoute` table alias is `tpt_pickup_points_route_jnt` — junction table | Migration |
| DL-19 | Timeline empty when no PickupPointRoute records: `if ($stops->isEmpty()) return collect()` | `TripMgmtController.php:288` |
| DL-20 | Timeline empty when no trips today: `if ($todayTrips->isEmpty()) return collect()` | `TripMgmtController.php:302-304` |

### Action Stop Calculation Logic (Blade)

```php
$lastLeftStop = $stopDetails->whereNotNull('leaving_time')->last();
if ($lastLeftStop) {
    $nextStop = $stopDetails->firstWhere('id', '>', $lastLeftStop->id);
    $actionStopId = $nextStop?->id;
} else {
    $actionStopId = $stopDetails->first()?->id;
}
```

### Stop State Rendering

| State | Condition | Visual |
|-------|-----------|--------|
| `completed` | `$stop->reached_flag` OR `$stop->leaving_time` | Gray/neutral |
| `current` | `$stop->id === $actionStopId` | Highlighted — action buttons visible |
| `emergency` | `$stop->emergency_flag` (not completed/current) | Red alert banner |
| `upcoming` | Default (none) | Normal |

### Action Button Visibility Per Stop Position

| Stop | Condition | Buttons |
|------|-----------|---------|
| First | Not reached/left | ▶ Start Trip |
| Middle | Not reached | ✔ Reached, ➡ Leave (disabled), ⚠ Emergency (disabled) |
| Middle | Reached, not left | 👨‍🎓 Attendance, ➡ Leave, ⚠ Emergency |
| Last | Not left | ⏹ End Trip |
| Any | `emergency_flag=1` | Alert banner below card |

Action buttons only render when both `shift_id` AND `route_id` are selected.

---

## 4. Test Data Strategy

| # | Data Strategy | Details |
|---|---------------|---------|
| TD-01 | **Valid Trip with Stops** | Trip `trip_date=today`, `status='Scheduled'`; 5 PickupPointRoute stops (ordinal 1-5), mixed Pickup/Drop, times at 0,10,20,30,40 min from midnight |
| TD-02 | **Driver-Assigned Trip** | DriverRouteVehicleJnt: driver_id=X, route_id=Y; DriverHelper: user_id=matching login; Trip for route Y today |
| TD-03 | **Late Stop** | `sch_arrival_time` >5min before now → triggers "Delayed" notification |
| TD-04 | **On-Time Stop** | `sch_arrival_time` within 5min of now → "ReachedStop" notification |
| TD-05 | **Emergency on Middle Stop** | emergency_flag=0 → emergency action creates TptTripIncidents |
| TD-06 | **Multiple Trips Same Day** | Two trips with different route_ids for same date |
| TD-07 | **Mixed Pickup/Drop** | Stops with both Pickup and Drop in same route |
| TD-08 | **Existing + New IDs** | Pre-inserted TptTripStopDetail for some stops; others use `new_{jntId}` |
| TD-09 | **Already Ongoing Trip** | Trip status='Ongoing' — double start_trip test |
| TD-10 | **No Trip for Date** | Trip exists for today but filters point to another date |
| TD-11 | **Extra Data Payloads** | start_trip with start_time/start_odometer/start_fuel; end_trip with end_time/end_odometer/end_fuel |
| TD-12 | **Bulk Prep with Existing** | Some TptTripStopDetail exist before stopDetailsPrepare |
| TD-13 | **Bulk Prep Clean** | No existing TptTripStopDetail — all inserted |
| TD-14 | **Multiple Drivers** | Two drivers assigned to same route |
| TD-15 | **tripDetailsUpdated All Fields** | reaching_time, leaving_time, emergency_flag, emergency_remarks at once |


---

## 5. Business Conditions (BC)

### 5.1 BC-DB: Database Conditions — `tpt_trip_stop_detail`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | `id` | INT UNSIGNED | PK, auto-increment |
| BC-DB-02 | `trip_id` | INT UNSIGNED | NOT NULL, FK → `tpt_trip.id`, ON DELETE CASCADE |
| BC-DB-03 | `stop_id` | INT UNSIGNED | DEFAULT NULL, FK → `tpt_pickup_points.id`, ON DELETE SET NULL |
| BC-DB-04 | `pickup_drop` | ENUM('Pickup','Drop') | NOT NULL, DEFAULT 'Pickup' |
| BC-DB-05 | `ordinal` | SMALLINT UNSIGNED | NOT NULL, DEFAULT 1 |
| BC-DB-06 | `sch_arrival_time` | DATETIME | DEFAULT NULL |
| BC-DB-07 | `sch_departure_time` | DATETIME | DEFAULT NULL |
| BC-DB-08 | `reached_flag` | TINYINT(1) | NOT NULL, DEFAULT 0 |
| BC-DB-09 | `reaching_time` | TIMESTAMP | DEFAULT NULL |
| BC-DB-10 | `leaving_time` | TIMESTAMP | DEFAULT NULL |
| BC-DB-11 | `emergency_flag` | TINYINT(1) | DEFAULT 0 |
| BC-DB-12 | `emergency_time` | TIMESTAMP | DEFAULT NULL |
| BC-DB-13 | `emergency_remarks` | VARCHAR(512) | DEFAULT NULL |
| BC-DB-14 | `created_at` | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |
| BC-DB-15 | `updated_at` | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP |
| BC-DB-16 | `updated_by` | INT UNSIGNED | DEFAULT NULL, FK → `tpt_personnel.id`, ON DELETE SET NULL |
| BC-DB-17 | `deleted_at` | TIMESTAMP | NULL (SoftDeletes) |

### BC-VAL: Validation Conditions

| BC ID | Condition | Source | Analyzed Behavior |
|-------|-----------|--------|-------------------|
| BC-VAL-01 | `stopAction()` — NO `$request->validate()` | `TripController.php:123-304` | No validation; null/empty action passes through switch with no default |
| BC-VAL-02 | `stopAction()` — `$request->id` via `str_starts_with()` | `TripController.php:127` | Missing `id` → PHP warning on `str_starts_with(null, 'new_')` |
| BC-VAL-03 | `stopAction()` — switch has NO default case | `TripController.php:187-298` | Invalid action → no match → returns 200 success (false positive) |
| BC-VAL-04 | `stopDetailsPrepare()` — trip_id empty | `TripController.php:472-477` | 400 JSON "Trip ID is required" |
| BC-VAL-05 | `stopDetailsPrepare()` — trip not found | `TripController.php:479-485` | 404 JSON "Trip not found" |
| BC-VAL-06 | `tripDetailsUpdated()` — stop not found | `TripController.php:551-554` | 404 JSON "Stop Detail not found" |
| BC-VAL-07 | `tripDetailsUpdated()` — NO date validation | `TripController.php:560-565` | No format check on reaching_time/leaving_time |
| BC-VAL-08 | `tripDetailsData()` — NO existence check | `TripController.php:331` | 200 with `inserted: null` instead of 404 |
| BC-VAL-09 | `stopAction()` — PickupPointRoute not found | `TripController.php:136-138` | 404 "Junction stop not found" |
| BC-VAL-10 | `stopAction()` — no trip found (new_) | `TripController.php:150-152` | 404 "No active trip scheduled for today" |
| BC-VAL-11 | `stopAction()` — existing stop not found | `TripController.php:177-179` | 404 "Stop Detail not found" |
| BC-VAL-12 | **GAP**: No validation on extra data keys | `TripController.php:198-208` | Any malformed extra data passes without error |

### BC-AUTH: Authorization Conditions

| BC ID | Permission | Controller Method | Gate | Missing Behavior |
|-------|-----------|-------------------|------|------------------|
| BC-AUTH-01 | `tenant.stop-details.update` | `stopAction()` | `Gate::authorize(...)` at TripController.php:125 | 403 Forbidden |
| BC-AUTH-02 | `tenant.stop-details.update` | `tripDetailsUpdated()` | `Gate::authorize(...)` at TripController.php:549 | 403 Forbidden |
| BC-AUTH-03 | `tenant.stop-details.prepare` | `stopDetailsPrepare()` | `Gate::authorize(...)` at TripController.php:468 | 403 Forbidden |
| BC-AUTH-04 | `tenant.stop-details.view` | `tripDetailsData()` | `Gate::authorize(...)` at TripController.php:329 | 403 Forbidden |
| BC-AUTH-05 | `tenant.transport.viewAny` | `TripMgmtController@index()` | `Gate::authorize(...)` at TripMgmtController.php:38 | 403 Forbidden |
| BC-AUTH-06 | `tenant.stop-details.viewAny` | Tab visibility (blade) | `@can` in tripmanagement.blade.php:34 | Tab hidden from nav; include not rendered |
| BC-AUTH-07 | Guest (no auth) | Any stop endpoint | Laravel auth middleware | Redirect to `/login` |

### BC-BIZ: Business Conditions

| BC ID | Condition | Expected Behavior | Source |
|-------|-----------|-------------------|--------|
| BC-BIZ-01 | `start_trip` on first stop (new_ format) | Stop created: reached_flag=1, reaching_time=leaving_time=now; if extra: trip status='Ongoing'; TripStart notification | `TripController.php:189-217` |
| BC-BIZ-02 | `start_trip` with extra data | trip start_time, start_odometer_reading, start_fuel_reading updated; status='Ongoing' | `TripController.php:198-208` |
| BC-BIZ-03 | `start_trip` WITHOUT extra data | Trip status NOT updated (remains 'Scheduled'); stop + notification still created | `TripController.php:198-208` conditional |
| BC-BIZ-04 | `reach` on a stop | reached_flag=1, reaching_time=now; notification_type='ReachedStop' or 'Delayed' | `TripController.php:219-237` |
| BC-BIZ-05 | Delayed detection | `$now > sch_arrival_time + 5min` → notification_type='Delayed' (hardcoded 5-min threshold) | `TripController.php:227-228` |
| BC-BIZ-06 | On-time reach | Within 5 min → notification_type='ReachedStop' | `TripController.php:226` |
| BC-BIZ-07 | `leave` from a stop | leaving_time=now; ApproachingStop notification | `TripController.php:240-253` |
| BC-BIZ-08 | `end_trip` on last stop with extra | reached_flag=1, reaching_time=leaving_time=now; end_time, end_odometer, end_fuel; status='Completed' | `TripController.php:255-275` |
| BC-BIZ-09 | `end_trip` WITHOUT extra data | Trip status NOT updated; only stop detail updated | `TripController.php:264-274` conditional |
| BC-BIZ-10 | `emergency` on any stop | emergency_flag=1, emergency_time=now, remarks saved; TptTripIncidents: type=0, severity=MEDIUM | `TripController.php:277-297` |
| BC-BIZ-11 | New stop ID (`new_{jntId}`) | Lookup PickupPointRoute → find today's trip (with fallback) → create/find TptTripStopDetail | `TripController.php:131-174` |
| BC-BIZ-12 | Existing stop ID | Load TptTripStopDetail with trip.routeScheduler; update per action | `TripController.php:175-181` |
| BC-BIZ-13 | No trip for route today | Falls back to any trip today; if none → 404 | `TripController.php:146-152` |
| BC-BIZ-14 | `stopDetailsPrepare` bulk prep | Create TptTripStopDetail for all PickupPointRoute matching route_id+shift_id; skip existing; activityLog per insert; DB transaction | `TripController.php:466-544` |
| BC-BIZ-15 | Bulk prep DB transaction | `DB::beginTransaction()` / `DB::commit()` wraps all inserts | `TripController.php:487,536` |
| BC-BIZ-16 | `tripDetailsUpdated` existing stop | Update reaching_time, leaving_time, emergency_flag, emergency_remarks; activityLog('Updated') | `TripController.php:547-568` |
| BC-BIZ-17 | `tripDetailsData` existing stop | 200 JSON with stop detail data | `TripController.php:327-338` |
| BC-BIZ-18 | `tripDetailsData` nonexistent stop | 200 with `inserted: null` — no 404 | `TripController.php:331` |
| BC-BIZ-19 | `stopAction` — NO activityLog | **GAP**: stopAction never calls activityLog() | Full method check |
| BC-BIZ-20 | `$updatedBy` from scheduler driver_id | `optional($trip->routeScheduler)->driver_id` — nullable | `TripController.php:184` |
| BC-BIZ-21 | PickupPointRoute lookup in stopAction | `$jnt = PickupPointRoute::find($jntId)` — no auth check on jnt | `TripController.php:135` |
| BC-BIZ-22 | Dedup before create (stopAction) | `TptTripStopDetail::where(trip_id,stop_id,pickup_drop,ordinal)->first()` then create if null | `TripController.php:157-163` |
| BC-BIZ-23 | Dedup in stopDetailsPrepare | `exists()` check before insert | `TripController.php:500-503` |
| BC-BIZ-24 | Minutes-to-time conversion | `Carbon::createFromTime(0,0,0)->addMinutes($stop->arrival_time)->format('H:i:s')` | `TripController.php:511-517` |
| BC-BIZ-25 | Emergency hardcoded incident_type=0 | All emergencies logged as 'Stop Emergency' | `TripController.php:288` |
| BC-BIZ-26 | Notifications for start/reach/leave | TptNotificationLog created with sent_time=NOW, status='Sent' | `TripController.php:210-216,231-237,246-253` |
| BC-BIZ-27 | Emergency NO notification | Emergency does NOT create TptNotificationLog (unlike other actions) | `TripController.php:277-297` |
| BC-BIZ-28 | `$stop->load('trip.routeScheduler')` after new_ creation | Eager-loads scheduler for updated_by | `TripController.php:174` |
| BC-BIZ-29 | Timeline queries PickupPointRoute first | Primary query on jnt table, NOT TptTripStopDetail | `TripMgmtController.php:256-257` |
| BC-BIZ-30 | Timeline ID format: mixed types | `'id' => $detail?->id : 'new_' . $item->id` | `TripMgmtController.php:326` |
| BC-BIZ-31 | Timeline fallback: route match → first trip | `$todayTrips->first(function($t) { return $t->route_id == $item->route_id; })` → fallback to first | `TripMgmtController.php:309-314` |


### BC-BIZ-DEEP: Deep Business Conditions from Code Analysis

| ID | Condition | Expected Behavior | Source |
|----|-----------|-------------------|--------|
| BC-BIZ-DEEP-01 | stopAction switch has NO default case | Invalid/unknown action → no case matches → returns 200 `{status:true}` — false positive success | `TripController.php:187-298` |
| BC-BIZ-DEEP-02 | stopAction access to any route's stops | Only initial Gate check; PickupPointRoute::find(jntId) has no row-level auth | `TripController.php:135` |
| BC-BIZ-DEEP-03 | end_trip without extra: trip NOT completed | status update inside `if ($request->filled('extra'))` — trip remains 'Ongoing' | `TripController.php:264-274` |
| BC-BIZ-DEEP-04 | start_trip without extra: trip NOT marked Ongoing | status update inside extra block — trip stays 'Scheduled' | `TripController.php:198-208` |
| BC-BIZ-DEEP-05 | stopDetailsPrepare activityLog wrong model | `activityLog($stop, 'Create', ...)` references $stop from PickupPointRoute, not the newly created TptTripStopDetail | `TripController.php:519-524` |
| BC-BIZ-DEEP-06 | tripDetailsUpdated activityLog BEFORE update | Log runs at line 556 BEFORE $stop->update() at line 560 | `TripController.php:556-565` |
| BC-BIZ-DEEP-07 | tripDetailsUpdated has NO change tracking | No getOriginal()/getChanges() — simple overwrite without audit | `TripController.php:560-565` |
| BC-BIZ-DEEP-08 | tripDetailsUpdated activityLog incomplete | Only `message` key — missing `performed_by` and `changes` | `TripController.php:556-558` |
| BC-BIZ-DEEP-09 | stopDetailsPrepare no rollback handler | DB::beginTransaction without try-catch — if insert fails, transaction hangs | `TripController.php:487-536` |
| BC-BIZ-DEEP-10 | Timeline firstWhere('id','>',...) mixed types | `id` is int (existing) or 'new_XX' (string) — PHP > comparison on mixed types | `trip-details/index.blade.php:53` |
| BC-BIZ-DEEP-11 | Action buttons need shift_id AND route_id | `@if ($stop->id === $actionStopId && request('shift_id') && request('route_id'))` | `trip-details/index.blade.php:114` |
| BC-BIZ-DEEP-12 | Timeline mislabeled column: "Act" shows departure | sch_departure_time displayed under "Act:" label (should say "Dep") | `trip-details/index.blade.php:108` |
| BC-BIZ-DEEP-13 | reach overwrites reaching_time on double-reach | No guard: already-reached stop's reaching_time replaced | `TripController.php:219-224` |
| BC-BIZ-DEEP-14 | leave overwrites leaving_time on double-leave | No guard: already-left stop's leaving_time replaced | `TripController.php:240-244` |
| BC-BIZ-DEEP-15 | stopAction has NO transaction wrapping | Stop + trip + notification + incident writes across models — no DB::transaction | `TripController.php:187-298` |
| BC-BIZ-DEEP-16 | Emergency does NOT notify parents/caretakers | No TptNotificationLog created for emergency (unlike start/reach/leave) | `TripController.php:277-297` |
| BC-BIZ-DEEP-17 | end_trip without extra: NO notification | No trip completion notification (unlike start_trip which always creates one) | `TripController.php:255-274` |
| BC-BIZ-DEEP-18 | start_trip ALWAYS creates notification | Notification at lines 210-216 outside `if(extra)` block | `TripController.php:210-216` |
| BC-BIZ-DEEP-19 | tripDetailsData: NO eager loading | `TptTripStopDetail::where('id',$request->id)->first()` — N+1 if consumer accesses relationships | `TripController.php:331` |
| BC-BIZ-DEEP-20 | tripDetailsUpdated: NO eager loading | `TptTripStopDetail::find($request->id)` — no with() | `TripController.php:551` |
| BC-BIZ-DEEP-21 | stopAction existing stop: WITH eager loading | `TptTripStopDetail::with('trip.routeScheduler')->find($request->id)` — correct | `TripController.php:176` |
| BC-BIZ-DEEP-22 | stopAction response always has server time | `'time' => $now->format('Y-m-d H:i:s')` — not actual DB timestamp | `TripController.php:303` |
| BC-BIZ-DEEP-23 | Trip ID merge affects ALL tabs | `$request->merge(['trip_id'=>..., 'tripe_id'=>...])` — cross-tab side effect | `TripMgmtController.php:67` |
| BC-BIZ-DEEP-24 | Driver filter can show incorrect trip stops | Driver sees only assigned routes; if fallback trip for a different route exists, stops may show | `TripMgmtController.php:259-270` |
| BC-BIZ-DEEP-25 | No route-model-binding in any stop method | All use manual `find()`/`findOrFail()` — no implicit 404 | `TripController.php:135,176,331,551` |
| BC-BIZ-DEEP-26 | tripStopTimeline() private; tripStopNew() public | Inconsistent access modifiers | `TripMgmtController.php:204,253` |
| BC-BIZ-DEEP-27 | Timeline loads ALL PickupPointRoute (not filtered initially) | `$query = PickupPointRoute::with('pickupPoint')->whereNull('deleted_at')` — tab check filters later | `TripMgmtController.php:256-258` |
| BC-BIZ-DEEP-28 | Empty timeline when no PickupPointRoute | `if ($stops->isEmpty()) return collect()` | `TripMgmtController.php:288` |
| BC-BIZ-DEEP-29 | Empty timeline when no trips today | `if ($todayTrips->isEmpty()) return collect()` | `TripMgmtController.php:302-304` |
| BC-BIZ-DEEP-30 | stopDetailsPrepare shift filter uses optional chain | `$trip->routeScheduler?->shift_id` — null routeScheduler omits filter entirely | `TripController.php:491` |
| BC-BIZ-DEEP-31 | stopAction emergency incident_type hardcoded to 0 | All stop emergencies recorded as type 0 regardless of actual emergency nature | `TripController.php:288` |
| BC-BIZ-DEEP-32 | stopAction emergency severity hardcoded to MEDIUM | No HIGH/LOW option for severity | `TripController.php:293` |
| BC-BIZ-DEEP-33 | stopAction $now reused for ALL operations in single request | `$now = Carbon::now()` at line 128 — all actions share same timestamp | `TripController.php:128` |
| BC-BIZ-DEEP-34 | Timeline fallback can mix data across routes | Fallback trip may have different route_id than current PickupPointRoute stops | `TripMgmtController.php:305,314` |
| BC-BIZ-DEEP-35 | stopDetailsPrepare activityLog uses 'Create' type | `activityLog($stop, 'Create', ...)` — this is the 'create' event but logs before actual DB insert | `TripController.php:519` |
| BC-BIZ-DEEP-36 | stopDetailsPrepare no routeScheduler null check | `$trip->routeScheduler?->shift_id` could be null → WHERE shift_id IS NULL condition | `TripController.php:491` |
| BC-BIZ-DEEP-37 | stopAction's `str_starts_with('new_', ...)` only checks prefix | ID like 'new_' with no numeric suffix → `str_replace('new_', '', 'new_')` = '' → `find('')` → null | `TripController.php:127,133-135` |

### BC-REL: Relationship Conditions

| BC ID | Relationship | Type | Foreign Key | Source |
|-------|-------------|------|-------------|--------|
| BC-REL-01 | TptTripStopDetail → TptTrip | `belongsTo(TptTrip::class, 'trip_id')` | `trip_id` → `tpt_trip.id` ON DELETE CASCADE | `TptTripStopDetail.php:44-46` |
| BC-REL-02 | TptTripStopDetail → PickupPoint | `belongsTo(PickupPoint::class, 'stop_id')` | `stop_id` → `tpt_pickup_points.id` ON DELETE SET NULL | `TptTripStopDetail.php:48-51` |
| BC-REL-03 | TptTripStopDetail → DriverHelper | `belongsTo(DriverHelper::class, 'updated_by')` | `updated_by` → `tpt_personnel.id` ON DELETE SET NULL | `TptTripStopDetail.php:53-56` |
| BC-REL-04 | PickupPointRoute → PickupPoint | FK in `tpt_pickup_points_route_jnt` | `pickup_point_id` → `tpt_pickup_points.id` | Migration |
| BC-REL-05 | TptTrip → TptRouteSchedulerJnt | FK in `tpt_trip` | `route_scheduler_id` → `tpt_route_scheduler_jnt.id` | Migration |

### BC-MODEL: Model Conditions — TptTripStopDetail

| BC ID | Condition | Value | Source |
|-------|-----------|-------|--------|
| BC-MODEL-01 | Table name | `'tpt_trip_stop_detail'` | `TptTripStopDetail.php:12` |
| BC-MODEL-02 | SoftDeletes | Yes (use trait) | `TptTripStopDetail.php:10` |
| BC-MODEL-03 | Fillable — 13 fields | trip_id, stop_id, pickup_drop, ordinal, sch_arrival_time, sch_departure_time, reached_flag, reaching_time, leaving_time, emergency_flag, emergency_time, emergency_remarks, updated_by | `TptTripStopDetail.php:14-28` |
| BC-MODEL-04 | Cast — reached_flag | `boolean` | `TptTripStopDetail.php:31` |
| BC-MODEL-05 | Cast — emergency_flag | `boolean` | `TptTripStopDetail.php:32` |
| BC-MODEL-06 | Cast — sch_arrival_time | `datetime` | `TptTripStopDetail.php:33` |
| BC-MODEL-07 | Cast — sch_departure_time | `datetime` | `TptTripStopDetail.php:34` |
| BC-MODEL-08 | Cast — reaching_time | `datetime` | `TptTripStopDetail.php:35` |
| BC-MODEL-09 | Cast — leaving_time | `datetime` | `TptTripStopDetail.php:36` |
| BC-MODEL-10 | Cast — emergency_time | `datetime` | `TptTripStopDetail.php:37` |
| BC-MODEL-11 | Relationship — trip() | BelongsTo TptTrip | `TptTripStopDetail.php:43-46` |
| BC-MODEL-12 | Relationship — stop() | BelongsTo PickupPoint | `TptTripStopDetail.php:48-51` |
| BC-MODEL-13 | Relationship — updatedBy() | BelongsTo DriverHelper | `TptTripStopDetail.php:53-56` |
| BC-MODEL-14 | No `is_active` column | Not on this model (status derived from flags) | DDL |
| BC-MODEL-15 | No `status` column | Not on this model (derived from reached_flag/leaving_time/emergency_flag) | DDL |

### BC-GAP: Identified Gaps

| BC ID | Gap | Severity | Detail |
|-------|-----|----------|--------|
| BC-GAP-01 | No activityLog in stopAction | **HIGH** | All mutation methods log; stopAction is the only one that doesn't |
| BC-GAP-02 | No switch default case in stopAction | **MEDIUM** | Invalid action silently returns 200 success |
| BC-GAP-03 | tripDetailsData no 404 on missing record | **LOW** | Returns 200 with inserted:null |
| BC-GAP-04 | start_trip without extra doesn't set trip status | **MEDIUM** | Trip stays 'Scheduled' after first stop |
| BC-GAP-05 | end_trip without extra doesn't set trip status | **MEDIUM** | Trip stays 'Ongoing' after last stop |
| BC-GAP-06 | Emergency action no notification created | **MEDIUM** | No parent notification for emergency |
| BC-GAP-07 | end_trip no notification (without extra) | **LOW** | Trip completion not communicated |
| BC-GAP-08 | No DB transaction in stopAction | **MEDIUM** | Multiple writes across models |
| BC-GAP-09 | tripDetailsUpdated activityLog incomplete | **LOW** | Missing performed_by, missing changes |
| BC-GAP-10 | stopDetailsPrepare activityLog wrong model | **MEDIUM** | References PickupPointRoute not TptTripStopDetail |
| BC-GAP-11 | No validation on extra data keys | **LOW** | start_time/odometer format unchecked |
| BC-GAP-12 | Double-reach/leave overwrites timestamps | **LOW** | No guard against duplicate actions |
| BC-GAP-13 | Policy defines delete/restore/forceDelete but no endpoints | **MEDIUM** | Permissions exist but no controller methods |
| BC-GAP-14 | Timeline mislabeled column "Act" | **LOW** | Shows departure time under "Act:" label |
| BC-GAP-15 | stopDetailsPrepare no DB::rollback | **MEDIUM** | Transaction may hang on exception |


---

## 6. Test Case List

### 6.1 TC-P: Positive Test Cases

| ID | Test Case | Summary | Expected Result |
|----|-----------|---------|-----------------|
| TC-P-01 | Trip Details Tab Shows Stop Timeline | Navigate to Trip Management → Stopage Status tab | Timeline renders with stop list and action buttons |
| TC-P-02 | start_trip on First Stop (new_ format) | POST `/trip/stop-action` with action=start_trip, id=new_{jntId} | Stop created: reached_flag=1, reaching_time=leaving_time=now; TripStart notification |
| TC-P-03 | start_trip With Extra Data | POST with extra start_time, start_odometer, start_fuel | Trip fields updated; status='Ongoing' |
| TC-P-04 | start_trip WITHOUT Extra Data | POST start_trip without extra | Trip stays 'Scheduled'; stop still created |
| TC-P-05 | reach on Existing Stop | POST action=reach, ID=existing | reached_flag=1, reaching_time=now; ReachedStop notification |
| TC-P-06 | reach — Delayed Detection | Arrive >5min after sch_arrival_time | notification_type='Delayed' |
| TC-P-07 | reach — On-Time Detection | Arrive within 5min of sch_arrival_time | notification_type='ReachedStop' |
| TC-P-08 | leave From Stop | POST action=leave | leaving_time=now; ApproachingStop notification |
| TC-P-09 | end_trip on Last Stop With Extra Data | POST end_trip with end_time, end_odometer, end_fuel | reached_flag=1; status='Completed'; end_time set |
| TC-P-10 | end_trip WITHOUT Extra Data | POST end_trip without extra | reached_flag=1; trip status NOT updated |
| TC-P-11 | emergency on Any Stop | POST action=emergency, remark="Flat tire" | emergency_flag=1; TptTripIncidents created (type=0, severity=MEDIUM) |
| TC-P-12 | Prepare Stop Details (Bulk Insert) | GET `/stop/details/prepare?trip_id=X` | All PickupPointRoute stops inserted; JSON with inserted=N, skipped=0 |
| TC-P-13 | Prepare Stop Details — Skips Existing | Call prepare twice | Second call: inserted=0, skipped=N |
| TC-P-14 | Full Trip Lifecycle | start_trip → reach(stop1) → leave(stop1) → reach(stop2) → leave(stop2) → end_trip(last) | Complete lifecycle succeeds at each step |
| TC-P-15 | tripDetailsUpdated on Existing Stop | POST `/trip/details/updates` with id, reaching_time, leaving_time | Stop updated; activityLog 'Updated' |
| TC-P-16 | tripDetailsData Fetch Single Stop | GET `/trip/details/edits?id=X` | 200 JSON with stop detail data |
| TC-P-17 | Driver-Only View (Login as Driver) | Login as driver for route Y | Only route Y's stops in timeline |
| TC-P-18 | start_trip on Existing Stop Detail | POST start_trip on stop with existing detail | Detail updated (no duplicate) |
| TC-P-19 | No Filters: Timeline Loads Without Actions | No shift_id/route_id selected | Timeline renders but no action buttons |
| TC-P-20 | Filter by Shift and Route | Select shift + route | Timeline filtered to matching stops |

### 6.2 TC-N: Negative Test Cases

| ID | Test Case | Summary | Expected Result |
|----|-----------|---------|-----------------|
| TC-N-01 | Invalid Action Value | POST action=invalid | No switch case matches → 200 with false success (GAP BC-GAP-02) |
| TC-N-02 | Missing Action Parameter | POST without action | null action → no case match → 200 success (false positive) |
| TC-N-03 | Missing ID Parameter | POST without id | PHP warning on str_starts_with(null, 'new_') |
| TC-N-04 | Non-Existent PickupPointRoute (new_) | POST new_99999 | 404 "Junction stop not found" |
| TC-N-05 | No Trip for Date (new_ format) | POST new_1 on date with no trips | 404 "No active trip scheduled for today" |
| TC-N-06 | Non-Existent Stop ID (existing) | POST action=reach, id=99999 | 404 "Stop Detail not found" |
| TC-N-07 | Prepare Without Trip ID | GET `/stop/details/prepare` | 400 "Trip ID is required" |
| TC-N-08 | Prepare Non-Existent Trip | GET ?trip_id=99999 | 404 "Trip not found" |
| TC-N-09 | Permission 403 — No tenant.stop-details.update | POST stopAction | 403 Forbidden |
| TC-N-10 | Permission 403 — No tenant.stop-details.prepare | GET stopDetailsPrepare | 403 Forbidden |
| TC-N-11 | Permission 403 — No tenant.stop-details.view | GET tripDetailsData | 403 Forbidden |
| TC-N-12 | Permission 403 — No tenant.transport.viewAny | GET TripMgmtController@index | 403 Forbidden |
| TC-N-13 | Guest Access (unauthenticated) | Any stop endpoint | Redirect to `/login` |
| TC-N-14 | tripDetailsUpdated Nonexistent ID | POST with id=99999 | 404 "Stop Detail not found" |
| TC-N-15 | tripDetailsData Nonexistent ID | GET ?id=99999 | 200 with inserted:null (GAP BC-GAP-03) |
| TC-N-16 | Double start_trip on same stop | Call start_trip again | Stop updated again; notification duplicated |
| TC-N-17 | Double reach on same stop | Call reach on already-reached stop | reaching_time overwritten (GAP BC-GAP-12) |
| TC-N-18 | Double leave on same stop | Call leave on already-left stop | leaving_time overwritten (GAP BC-GAP-12) |
| TC-N-19 | Tab Hidden Without viewAny permission | User lacks tenant.stop-details.viewAny | Tab nav-item hidden; include not rendered |
| TC-N-20 | stopAction Switch Fallthrough (malformed action) | POST action="" | No case match → 200 success (GAP) |

### 6.3 TC-D: Data Integrity / Dependency Test Cases

| ID | Test Case | Summary | Expected Result |
|----|-----------|---------|-----------------|
| TC-D-01 | Trip Delete Cascades to Stop Details | Delete trip → TptTripStopDetail soft-deleted by FK CASCADE | stop_details.deleted_at set |
| TC-D-02 | PickupPoint Delete Sets stop_id NULL | Delete pickup point → stop_id SET NULL | stop_id = NULL (FK SET NULL) |
| TC-D-03 | Emergency Creates TripIncident | Verify TptTripIncidents row created | incident_type=0, severity=MEDIUM, status=0 |
| TC-D-04 | start_trip Creates NotificationLog | Verify TptNotificationLog type='TripStart' | Log exists for trip |
| TC-D-05 | reach Creates NotificationLog | Verify TptNotificationLog type='ReachedStop'/'Delayed' | Log exists for trip+stop |
| TC-D-06 | leave Creates NotificationLog | Verify TptNotificationLog type='ApproachingStop' | Log exists for trip+stop |
| TC-D-07 | Emergency Does NOT Create Notification | No TptNotificationLog for emergency | Confirmed gap (BC-GAP-06) |
| TC-D-08 | stopDetailsPrepare Uses DB Transaction | All inserts succeed or none | Transaction atomicity |
| TC-D-09 | stopDetailsPrepare Dedup Works | Call prepare twice, second call skips all | Second JSON: inserted=0, skipped=N |
| TC-D-10 | stopDetailsPrepare activityLog per Insert | Each stop creates activity_log entry | N entries for N stops |
| TC-D-11 | tripDetailsUpdated activityLog Created | After update, verify activity_log | Log type "Updated" exists |
| TC-D-12 | stopAction No activityLog | After any stopAction, verify no log | Confirmed gap (BC-GAP-01) |
| TC-D-13 | No Direct Stop-Delete/Restore/ForceDelete | No controller endpoints exist | Route returns 404 or not defined |
| TC-D-14 | Timeline Fallback Cross-Route | Stop route A matched to fallback trip route B | Timeline renders (may mix routes) |
| TC-D-15 | stopDetailsPrepare activityLog Wrong Model | Activity log references PickupPointRoute | Log has different model type (GAP) |
| TC-D-16 | end_trip Without Extra Leaves Trip Ongoing | Verify trip.status after end_trip | 'Ongoing' not 'Completed' |
| TC-D-17 | start_trip Without Extra Leaves Trip Scheduled | Verify trip.status after start_trip no extra | 'Scheduled' not 'Ongoing' |
| TC-D-18 | Double Notifications for Duplicate start_trip | Call start_trip twice | Two TripStart notifications for same trip |
| TC-D-19 | Emergency No Notification Verified | emergency action → check notification_log | No row created (confirmed GAP) |
| TC-D-20 | Timeline Renders Without Trip Today | No trips exist for today + PickupPointRoute exists | Empty timeline (collect returned) |

### 6.4 TC-CR: Code Review Test Cases

| ID | Category | Priority | Description | Expected Result |
|----|----------|----------|-------------|-----------------|
| TC-CR-01 | CR | P1 | Controller — Gate::authorize() at stopAction() start | `Gate::authorize('tenant.stop-details.update')` at line 125 |
| TC-CR-02 | CR | P1 | Controller — NO activityLog inside stopAction | stopAction never calls activityLog() — verified gap |
| TC-CR-03 | CR | P1 | Controller — Fallback trip logic (no exact route match) | Falls back to any trip today; if none → 404 |
| TC-CR-04 | CR | P1 | Controller — Notification creation for each action | TripStart, ReachedStop/Delayed, ApproachingStop |
| TC-CR-05 | CR | P1 | Controller — Emergency incident_type hardcoded to 0 | Always `incident_type => 0` |
| TC-CR-06 | CR | P1 | Controller — Delayed detection | `$now->gt(Carbon::parse($stop->sch_arrival_time)->addMinutes(5))` |
| TC-CR-07 | CR | P1 | Model — Fillable (TptTripStopDetail) | 13 fields defined |
| TC-CR-08 | CR | P1 | Model — Relationships | trip(), stop(), updatedBy() |
| TC-CR-09 | CR | P1 | DDL — FK Constraints | trip_id CASCADE, stop_id SET NULL, updated_by SET NULL |
| TC-CR-10 | CR | P1 | Routes — All stop endpoints defined | stop-action, details/prepare, details/edits, details/updates |
| TC-CR-11 | CR | P1 | **GAP** — No input validation in stopAction | No `$request->validate()` — action/id/extra unchecked |
| TC-CR-12 | CR | P1 | **GAP** — No authorization re-check on PickupPointRoute | Gate checked once, not on jnt lookup |
| TC-CR-13 | CR | P1 | **GAP** — Emergency incident_type hardcoded 0 | All emergencies type 0 |
| TC-CR-14 | CR | P1 | TripMgmtController — tripStopTimeline driver filter | Driver sees only assigned routes |
| TC-CR-15 | CR | P1 | Controller — stopDetailsPrepare Gate | `Gate::authorize('tenant.stop-details.prepare')` line 468 |
| TC-CR-16 | CR | P1 | Controller — tripDetailsUpdated Gate + activityLog | Gate line 549; activityLog line 556 |
| TC-CR-17 | CR | P1 | Controller — tripDetailsData Gate | `Gate::authorize('tenant.stop-details.view')` line 329 |
| TC-CR-18 | CR | P1 | Controller — TripMgmtController::index Gate | `Gate::authorize('tenant.transport.viewAny')` line 38 |
| TC-CR-19 | CR | P1 | **GAP** — tripDetailsData no 404 on missing | Returns 200 with inserted:null |
| TC-CR-20 | CR | P1 | **GAP** — stopAction no activityLog | All other mutation methods log; stopAction doesn't |
| TC-CR-21 | CR | P2 | **GAP** — No standalone delete/restore/forceDelete | Policy+permissions exist but no endpoints |
| TC-CR-22 | CR | P1 | Controller — stopAction switch has NO default | Missing default; invalid action = 200 success |
| TC-CR-23 | CR | P1 | Controller — start_trip without extra no status update | `if ($request->filled('extra'))` guards status |
| TC-CR-24 | CR | P1 | Controller — end_trip without extra no status update | Same pattern as start_trip |
| TC-CR-25 | CR | P1 | Controller — stopAction no DB transaction | Multiple writes with no atomicity |
| TC-CR-26 | CR | P1 | Controller — tripDetailsUpdated activityLog before update | Log line 556 before update line 560 |
| TC-CR-27 | CR | P1 | Controller — tripDetailsUpdated no change tracking | No getOriginal/getChanges pattern |
| TC-CR-28 | CR | P1 | **GAP** — stopDetailsPrepare activityLog wrong model | References PickupPointRoute, not TptTripStopDetail |
| TC-CR-29 | CR | P1 | **GAP** — stopDetailsPrepare no rollback on exception | DB::beginTransaction without try-catch |
| TC-CR-30 | CR | P2 | Blade — Timeline mislabeled "Act" column | Shows sch_departure_time under "Act:" |
| TC-CR-31 | CR | P2 | Blade — Action buttons require shift+route | `request('shift_id') && request('route_id')` guard |
| TC-CR-32 | CR | P2 | Blade — firstWhere('id','>',...) mixed types | int vs string comparison |
| TC-CR-33 | CR | P1 | Model — `$casts` definitions | reached_flag/emergency_flag boolean; all times datetime |
| TC-CR-34 | CR | P2 | Blade — First stop Start Trip guard | `@if (!$stop->reached_flag && !$stop->leaving_time)` |
| TC-CR-35 | CR | P2 | Blade — Last stop End Trip guard | `@if (!$stop->leaving_time)` |
| TC-CR-36 | CR | P2 | Blade — Middle stop action logic | Conditional on reached/leaving flags |
| TC-CR-37 | CR | P1 | **GAP** — Emergency no notification created | No TptNotificationLog for emergency |
| TC-CR-38 | CR | P1 | **GAP** — end_trip without extra no notification | Trip completion not logged |
| TC-CR-39 | CR | P2 | TripMgmtController — trip_id merge cross-tab | Affects all tab queries |
| TC-CR-40 | CR | P1 | Model casts — sch_* as datetime | Stored correctly |
| TC-CR-41 | CR | P1 | Controller — stopAction $now reused | Single Carbon::now() for all actions |
| TC-CR-42 | CR | P2 | Controller — stopAction $updatedBy nullable | optional chain may return null |
| TC-CR-43 | CR | P2 | **GAP** — No model events/observers | No event listeners on TptTripStopDetail |
| TC-CR-44 | CR | P2 | TripMgmtController — inconsistent access | tripStopNew() public, tripStopTimeline() private |
| TC-CR-45 | CR | P1 | Controller — emergency no notification | No parent notification for stop emergency |
| TC-CR-46 | CR | P1 | Controller — emergency severity hardcoded MEDIUM | No HIGH/LOW option |
| TC-CR-47 | CR | P2 | Controller — emergency incident_type hardcoded 0 | All type 0 |
| TC-CR-48 | CR | P1 | Blade — Tab permission check | `@can('tenant.stop-details.viewAny')` in tripmanagement.blade.php |
| TC-CR-49 | CR | P2 | Blade — Timeline scroll container | `max-height: 65vh; overflow-y: auto` |
| TC-CR-50 | CR | P2 | Blade — Emergency banner always shown | Alert rendered when emergency_flag set |
| TC-CR-51 | CR | P1 | Controller — No validation on emergency remark | `$request->remark` used directly without validation |
| TC-CR-52 | CR | P2 | Controller — dedup query fields match | trip_id+stop_id+pickup_drop+ordinal in both stopAction and stopDetailsPrepare |
| TC-CR-53 | CR | P1 | Controller — emergency incident_type=0 means 'Stop Emergency' | Policy/incident type enum must have matching value |
| TC-CR-54 | CR | P1 | **GAP** — tripDetailsUpdated activityLog missing performed_by | Activity log key inconsistency |

### CODE-TRACE: Line-by-Line Method Trace

#### CODE-TRACE-01: `TripMgmtController::index()` — Lines 36-112 (Hub Controller)

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 38 | `Gate::authorize('tenant.transport.viewAny')` | Authorization gate |
| 02 | 40 | `$authData = Auth::user()->id` | Get logged-in user ID |
| 03 | 41 | `$loginDriver = DriverHelper::where('user_id', $authData)->first()` | Detect if user is a driver |
| 04 | 42 | `$driverLiveRoute = Route::get()` | All routes (default) |
| 05 | 43-51 | If driver: filter routes via DriverRouteVehicleJnt | `whereIn('route_id', $driveRoute)` |
| 06 | 54-63 | `$tripIds = TptTrip::where('trip_date', $request->date)...` | Trip ID resolution |
| 07 | 66-71 | `$request->merge(['trip_id' => ..., 'tripe_id' => ...])` | Merge into request |
| 08 | 73-80 | Load reference data (Vehicle, Route, DriverHelper, Shift, etc.) | 8 reference collections |
| 09 | 83 | `$stopDetails = $this->tripStopTimeline($request)` | **Load timeline** |
| 10 | 84-90 | Other tab queries | tripStopNew, TripQuery, bordUnbord, incident, driverRouteVehicle, scheduler, notificationLog |
| 11 | 92-111 | `return view(...compact(...))` | 17 variables to view |

#### CODE-TRACE-02: `tripStopTimeline(Request $request)` — TripMgmtController.php:253-344

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 256-257 | `$query = PickupPointRoute::with('pickupPoint')->whereNull('deleted_at')` | Query jnt table |
| 02 | 259-270 | Driver filter: $loginDriver → $driveRoute IDs | `whereIn('route_id', $driveRoute)` |
| 03 | 272-284 | Tab check: if tab='trip_details' apply shift, route, pickup_drop filters | Conditional filter |
| 04 | 286 | `$stops = $query->orderBy('ordinal', 'asc')->get()` | Execute query |
| 05 | 288 | Early return: `if ($stops->isEmpty()) return collect()` | Empty guard |
| 06 | 290 | Date: `$request->date ?? now()->toDateString()` | Date resolution |
| 07 | 293-301 | `$todayTrips = TptTrip::whereDate('trip_date', $date)...` | Load today's trips |
| 08 | 302-304 | Empty trips: `if ($todayTrips->isEmpty()) return collect()` | No trips guard |
| 09 | 305 | `$fallbackTripId = $todayTrips->first()?->id ?? 0` | Fallback trip |
| 10 | 307-342 | `$results = $stops->map(function($item) use ($todayTrips, ...) { ... })` | Map each jnt stop to timeline object |
| 11 | 309-314 | `$trip = $todayTrips->first(function($t) use ($item) { return $t->route_id == $item->route_id; })` | Match trip by route_id |
| 12 | 316-322 | `$detail = TptTripStopDetail::where('trip_id',$tripId)->where('stop_id',$item->pickup_point_id)...->first()` | Find matching TptTripStopDetail |
| 13 | 325-341 | Build unified object: id (detail->id or 'new_'.$item->id), stop info, flags, times | Timeline row object |
| 14 | 334-335 | Time conversion: `Carbon::createFromTime(0,0)->addMinutes($item->arrival_time)->format('H:i:s')` | Minutes to H:i:s |
| 15 | 344 | `return $results->sortBy('ordinal')->values()` | Sorted result |


#### CODE-TRACE-03: `stopAction(Request $request)` — TripController.php:123-304

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 125 | `Gate::authorize('tenant.stop-details.update')` | Authorization gate |
| 02 | 127 | `$isNew = str_starts_with($request->id, 'new_')` | Determine new vs existing stop |
| 03 | 128-129 | `$now = Carbon::now(); $date = now()->toDateString()` | Capture current time |
| 04 | 131 | `if ($isNew) { ... }` | **NEW STOP PATH** |
| 05 | 133 | `$jntId = str_replace('new_', '', $request->id)` | Extract jnt ID |
| 06 | 135 | `$jnt = PickupPointRoute::find($jntId)` | Lookup PickupPointRoute |
| 07 | 136-138 | Not found: return 404 | "Junction stop not found" |
| 08 | 141-143 | `$trip = TptTrip::whereDate('trip_date', $date)->where('route_id', $jnt->route_id)->first()` | Find today's trip for route |
| 09 | 146-148 | Fallback: `$trip = TptTrip::whereDate('trip_date', $date)->first()` | Any trip today |
| 10 | 150-152 | No trip: return 404 | "No active trip scheduled for today" |
| 11 | 154-155 | `$schArrival = ...->addMinutes($jnt->arrival_time)...` | Convert minutes to time |
| 12 | 157-161 | Dedup check: `TptTripStopDetail::where(trip_id,stop_id,pickup_drop,ordinal)->first()` | Skip if exists |
| 13 | 163-171 | `$stop = TptTripStopDetail::create([...])` | Create new stop detail |
| 14 | 174 | `$stop->load('trip.routeScheduler')` | Eager-load scheduler |
| 15 | 175-181 | **EXISTING STOP PATH**: `$stop = TptTripStopDetail::with('trip.routeScheduler')->find($request->id)` | Load existing; 404 if not found |
| 16 | 184-185 | `$updatedBy = optional($trip->routeScheduler)->driver_id` | Get driver from scheduler |
| 17 | 187 | `switch ($request->action) {` | Action dispatch |
| 18 | 189-217 | **case 'start_trip':** update stop (reached=1, reach/leave=now); if extra: update trip (start_time, odometer, fuel, status='Ongoing'); create TripStart notification | start_trip handler |
| 19 | 219-237 | **case 'reach':** update stop (reached=1, reaching_time=now); check delayed (>5min late); create ReachedStop or Delayed notification | reach handler |
| 20 | 240-253 | **case 'leave':** update stop (leaving_time=now); create ApproachingStop notification | leave handler |
| 21 | 255-274 | **case 'end_trip':** update stop (reached=1, reach/leave=now); if extra: update trip (end_time, odometer, fuel, status='Completed') | end_trip handler |
| 22 | 277-297 | **case 'emergency':** update stop (emergency_flag=1, time=now, remarks); create TptTripIncidents (type=0, severity=MEDIUM) | emergency handler |
| 23 | 298 | `}` — end switch (NO default case) | Missing default → fallthrough |
| 24 | 300-304 | Return JSON: `{status:true, message:'Stop updated successfully', time: now}` | Success response |

#### CODE-TRACE-04: `stopDetailsPrepare(Request $request)` — TripController.php:466-544

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 468 | `Gate::authorize('tenant.stop-details.prepare')` | Authorization gate |
| 02 | 470 | `$tripId = $request->trip_id ?? $request->tripe_id` | Resolve trip ID |
| 03 | 472-477 | Empty check: return 400 | "Trip ID is required" |
| 04 | 479-485 | `$trip = TptTrip::with('routeScheduler')->find($tripId)` | Find trip; 404 if not found |
| 05 | 487 | `DB::beginTransaction()` | Start transaction |
| 06 | 489-492 | `$routeStops = PickupPointRoute::where('route_id', $trip->route_id)->where('shift_id', $trip->routeScheduler?->shift_id)->get()` | Load route stops |
| 07 | 494-495 | `$inserted = 0; $skipped = 0` | Init counters |
| 08 | 497 | `foreach ($routeStops as $stop) {` | Iterate stops |
| 09 | 500-503 | `$exists = TptTripStopDetail::where('trip_id',$tripId)->where('stop_id',$stop->pickup_point_id)->where('pickup_drop',$stop->pickup_drop)->exists()` | Dedup check |
| 10 | 505-507 | If exists: `$skipped++; continue` | Skip existing |
| 11 | 511-517 | Convert minutes to time: `Carbon::createFromTime(0,0,0)->addMinutes($stop->arrival_time)->format('H:i:s')` | Time conversion |
| 12 | 519-521 | `activityLog($stop, 'Create', ['message'=>'Trip Details Create successfully.'])` | Activity log (wrong model — logs PickupPointRoute, not TptTripStopDetail) |
| 13 | 524-531 | `TptTripStopDetail::create([trip_id, stop_id, pickup_drop, ordinal, sch_arrival_time, sch_departure_time])` | Insert new stop |
| 14 | 533 | `$inserted++` | Increment counter |
| 15 | 536 | `DB::commit()` | Commit transaction |
| 16 | 538-543 | Return JSON: `{status:true, message:'...', inserted:N, skipped:M}` | Response |

#### CODE-TRACE-05: `tripDetailsData(Request $request)` — TripController.php:327-338

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 329 | `Gate::authorize('tenant.stop-details.view')` | Authorization gate |
| 02 | 331 | `$tripDetails = TptTripStopDetail::where('id',$request->id)->first()` | Find by ID (no with, no findOrFail) |
| 03 | 333-337 | Return JSON: `{status:true, message:'...', inserted:$tripDetails}` | null if not found |

#### CODE-TRACE-06: `tripDetailsUpdated(Request $request)` — TripController.php:547-568

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 549 | `Gate::authorize('tenant.stop-details.update')` | Authorization gate |
| 02 | 551 | `$stop = TptTripStopDetail::find($request->id)` | Find by ID (no with, no findOrFail) |
| 03 | 552-554 | Not found: return 404 | "Stop Detail not found" |
| 04 | 556-558 | `activityLog($stop, 'Updated', ['message'=>'Trip Details update successfully.'])` | Log BEFORE update — no change tracking |
| 05 | 560-565 | `$stop->update([reaching_time, leaving_time, emergency_flag, emergency_remarks])` | Update stop fields |
| 06 | 567 | Return JSON: `{status:true}` | Success response |

---

## 7. Detailed Test Steps

### TC-P-02: start_trip on First Stop

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user with tenant.stop-details.update + tenant.transport.viewAny | Authenticated session |
| 2 | Navigate to Trip Management → Stopage Status Update tab | `GET /transport/trip-management?tab=trip_details` |
| 3 | Select shift_id and route_id in filters | Action buttons appear |
| 4 | Identify first stop's ID (ordinal=1) — format will be `new_{jntId}` if no detail exists | `data-id="new_5"` in the button |
| 5 | Click "▶ Start Trip" button on first stop | AJAX POST to `/trip/stop-action` |
| 6 | **Verify**: Gate::authorize('tenant.stop-details.update') passes | No 403 |
| 7 | **Verify**: `$isNew = true` (str_starts_with('new_5', 'new_')) | True |
| 8 | **Verify**: PickupPointRoute::find(5) returns jnt record | JNT found |
| 9 | **Verify**: `TptTrip::whereDate(today)->where('route_id', jnt.route_id)->first()` finds trip | Trip exists |
| 10 | **Verify**: `Carbon::createFromTime(0,0)->addMinutes(jnt.arrival_time)->format('H:i:s')` converts correctly | "07:30:00" |
| 11 | **Verify**: Dedup check: TptTripStopDetail::where(trip_id,stop_id,pickup_drop,ordinal)->first() returns null | No existing, proceeds to create |
| 12 | **Verify**: `TptTripStopDetail::create([...])` executes | INSERT with trip_id, stop_id, pickup_drop, ordinal, sch_arrival_time, sch_departure_time |
| 13 | **Verify**: Stop detail created in DB | `SELECT * FROM tpt_trip_stop_detail WHERE trip_id=X AND ordinal=1` → row exists |
| 14 | **Verify**: reached_flag=1, reaching_time NOT NULL, leaving_time NOT NULL | All three set |
| 15 | **Verify**: `$stop->load('trip.routeScheduler')` | RouteScheduler loaded |
| 16 | **Verify**: `switch($request->action)` matches 'start_trip' | Case 'start_trip' executed |
| 17 | **Verify**: `$stop->update(['reached_flag'=>1, 'reaching_time'=>$now, 'leaving_time'=>$now, 'updated_by'=>$updatedBy])` | Stop updated with all timestamps |
| 18 | **Verify**: If extra data provided: `$trip->update(['start_time'=>..., 'start_odometer_reading'=>..., 'status'=>'Ongoing'])` | Trip status = 'Ongoing' |
| 19 | **Verify**: `TptNotificationLog::create(['notification_type'=>'TripStart', ...])` | Notification created |
| 20 | **Verify**: JSON response: `{status:true, message:'Stop updated successfully', time:'...'}` | 200 OK |
| 21 | **Verify**: Timeline re-renders with stop marked as completed | Stop shows gray/completed state |

### TC-P-05: reach — Delayed Detection

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Pre-set sch_arrival_time to a time >5 minutes before current time | e.g., if now=10:00, sch_arrival_time=09:50 |
| 2 | Login, navigate to trip details tab, select shift+route | Timeline visible |
| 3 | Click "✔ Reached" on a middle stop | AJAX POST action=reach |
| 4 | **Verify**: `switch($request->action)` → case 'reach' | reach handler |
| 5 | **Verify**: `$stop->update(['reached_flag'=>1, 'reaching_time'=>$now])` | Stop marked reached |
| 6 | **Verify**: `$now->gt(Carbon::parse($stop->sch_arrival_time)->addMinutes(5))` evaluates to true | Late detection (e.g., 10:00 > 09:55) |
| 7 | **Verify**: `$notificationType = 'Delayed'` | Delayed set |
| 8 | **Verify**: `TptNotificationLog::create(['notification_type'=>'Delayed', ...])` | Notification type = 'Delayed' |
| 9 | **Verify**: DB has notification_log record with type='Delayed' for this trip+stop | Log exists |

### TC-P-10: end_trip on Last Stop With Extra Data

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login, navigate, select shift+route, ensure last stop is current | Timeline shows last stop as action stop |
| 2 | Click "⏹ End Trip" on the last stop | AJAX POST to `/trip/stop-action` with action=end_trip |
| 3 | **Verify**: `switch` → case 'end_trip' | Correct case |
| 4 | **Verify**: `$stop->update(['reached_flag'=>1, 'reaching_time'=>$now, 'leaving_time'=>$now])` | Last stop marked complete |
| 5 | **Verify**: `$request->filled('extra')` returns true (extra data sent with request) | Extra block entered |
| 6 | **Verify**: `$trip->update(['end_time'=>..., 'end_odometer_reading'=>..., 'end_fuel_reading'=>..., 'status'=>'Completed'])` | Trip completed |
| 7 | **Verify**: `SELECT status FROM tpt_trip WHERE id=X` → 'Completed' | Status updated |
| 8 | **Verify**: `SELECT end_time, end_odometer_reading, end_fuel_reading FROM tpt_trip WHERE id=X` | Extra fields saved |

### TC-P-12: Prepare Stop Details From Route

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user with tenant.stop-details.prepare | Authenticated |
| 2 | Ensure trip exists with route_id=Y and routeScheduler.shift_id=Z | Valid trip |
| 3 | Ensure PickupPointRoute has 3 records matching route_id=Y, shift_id=Z | 3 PPR records |
| 4 | Call: `GET /stop/details/prepare?trip_id={tripId}` | Request reaches stopDetailsPrepare |
| 5 | **Verify**: Gate::authorize('tenant.stop-details.prepare') passes | OK |
| 6 | **Verify**: `$tripId` resolved from request | OK |
| 7 | **Verify**: `$trip = TptTrip::with('routeScheduler')->find($tripId)` | Trip found |
| 8 | **Verify**: `PickupPointRoute::where('route_id',...)->where('shift_id',...)->get()` returns 3 records | 3 records |
| 9 | **Verify**: Loop: iteration 1 — `exists()` returns false, activityLog, create, inserted=1 | Stop 1 inserted |
| 10 | **Verify**: Loop: iteration 2 — similar, inserted=2 | Stop 2 inserted |
| 11 | **Verify**: Loop: iteration 3 — similar, inserted=3 | Stop 3 inserted |
| 12 | **Verify**: `DB::commit()` | Transaction committed |
| 13 | **Verify**: JSON response: `{status:true, inserted:3, skipped:0}` | Success |
| 14 | **Verify**: `SELECT COUNT(*) FROM tpt_trip_stop_detail WHERE trip_id=X` = 3 | 3 rows in DB |
| 15 | **CALL AGAIN**: Re-run same GET | Second call |
| 16 | **Verify**: Loop: all 3 iterations hit `exists()=true` → skipped++ | All skipped |
| 17 | **Verify**: JSON response: `{status:true, inserted:0, skipped:3}` | All skipped |

### TC-N-02: Missing Action Parameter

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with tenant.stop-details.update permission | Authenticated |
| 2 | POST to `/trip/stop-action` with only `id=new_5` and NO `action` field | Request body has 'id' but not 'action' |
| 3 | **Verify**: Gate::authorize() passes (user has permission) | OK |
| 4 | **Verify**: `str_starts_with('new_5', 'new_')` → true | New stop path |
| 5 | **Verify**: Stop created/found as in TC-P-02 steps 8-14 | Stop exists |
| 6 | **Verify**: `switch($request->action)` with null action | No case matches |
| 7 | **Verify**: No update performed (no case entered) | Stop unchanged |
| 8 | **Verify**: Returns 200 JSON: `{status:true, message:'Stop updated successfully'}` | **False positive** — no action actually executed |
| 9 | **Verify**: No notifications created, no trip status change | Nothing happened despite success response |
| 10 | **GAP confirmed**: Missing switch default case allows silent no-op | BC-GAP-02 |

### TC-N-09: Permission 403 — Without tenant.stop-details.update

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user without tenant.stop-details.update permission | Lacks update |
| 2 | POST to `/trip/stop-action` with valid action and ID | Request reaches TripController::stopAction |
| 3 | **Verify**: `Gate::authorize('tenant.stop-details.update')` at line 125 throws AuthorizationException | 403 Forbidden |
| 4 | **Verify**: No stop update or notification created | DB unchanged |

### TC-N-11: Permission 403 — Without tenant.stop-details.view

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user without tenant.stop-details.view permission | Lacks view |
| 2 | GET `/trip/details/edits?id=5` | Request reaches tripDetailsData |
| 3 | **Verify**: `Gate::authorize('tenant.stop-details.view')` at line 329 throws | 403 Forbidden |
| 4 | **Verify**: No data returned | 403 response |

### TC-D-01: Trip Delete Cascades to Stop Details

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure trip X has 3 TptTripStopDetail records | Stop details exist |
| 2 | Delete trip X via TripController::destroy (soft delete) | Trip soft-deleted |
| 3 | **Verify**: `TptTripStopDetail::where('trip_id', X)->get()` — all 3 soft-deleted | `deleted_at` IS NOT NULL for all 3 |
| 4 | **Verify**: FK CASCADE: DDL has `$table->foreign('trip_id')->references('id')->on('tpt_trip')->onDelete('cascade')` | Cascade works for soft-delete via manual delete in destroy() |
| 5 | **Verify**: TripController::destroy() manually calls `TptTripStopDetail::where('trip_id',...)->delete()` THEN `$trip->delete()` | Both soft-deleted |

### TC-D-03: Emergency Creates TripIncident

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login, navigate, ensure stop is current (reached, not left) | Middle stop ready |
| 2 | Click "⚠ Emergency" button | AJAX POST action=emergency |
| 3 | **Verify**: `switch($request->action)` → case 'emergency' | Emergency handler |
| 4 | **Verify**: `$stop->update(['emergency_flag'=>1, 'emergency_time'=>$now, 'emergency_remarks'=>$request->remark])` | Stop updated |
| 5 | **Verify**: `TptTripIncidents::create(['trip_id'=>$stop->trip_id, 'incident_time'=>$now, 'incident_type'=>0, 'description'=>$request->remark, 'status'=>0, 'raised_by'=>..., 'raised_at'=>$now, 'severity'=>'MEDIUM'])` | Incident created |
| 6 | **Verify**: `SELECT * FROM tpt_trip_incidents WHERE trip_id=X AND incident_type=0` | Row exists |
| 7 | **Verify**: incident_type=0, severity='MEDIUM', status=0 | Correct defaults |
| 8 | **Verify**: `description` matches the remark sent | e.g., "Flat tire" |

### TC-CR-01: Gate::authorize() at stopAction() start

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `TripController.php:125` | `Gate::authorize('tenant.stop-details.update')` |
| 2 | Verify it is the FIRST line of the method body (after variable declarations) | Yes, line 125 |
| 3 | Verify permission string: 'tenant.stop-details.update' | Matches permissionslist.php convention |

### TC-CR-11: GAP — No Input Validation in stopAction

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `stopAction()` method (`TripController.php:123-304`) | Full method |
| 2 | Search for `$request->validate()` call | **NOT FOUND** |
| 3 | Verify action, id, extra data all used directly without validation rules | Confirmed |
| 4 | Test: POST with missing `id` parameter | `str_starts_with(null, 'new_')` → PHP warning |
| 5 | Test: POST with missing `action` parameter | Switch on null → no case match → 200 false success |
| 6 | **Impact**: Malformed or missing parameters produce inconsistent errors | GAP |

### TC-CR-20: GAP — stopAction No activityLog

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `stopAction()` method | TripController.php:123-304 |
| 2 | Search for `activityLog(` call | **NOT FOUND** |
| 3 | Compare with tripDetailsUpdated which calls activityLog at line 556 | Contrast: other methods log; stopAction doesn't |
| 4 | Test: Perform any stop action and check `activity_log` table | No entry |
| 5 | **Impact**: No audit trail for live stop actions (reach/leave/emergency/start/end) | **HIGH** gap |


### TC-P-01: Trip Details Tab Shows Stop Timeline

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user with tenant.transport.viewAny | Authenticated session |
| 2 | Navigate to: `GET /transport/trip-management` | TripMgmtController@index renders |
| 3 | **Verify**: `Gate::authorize('tenant.transport.viewAny')` at TripMgmtController.php:38 passes | OK |
| 4 | **Verify**: Tab navigation renders with all tab items defined in tripmanagement.blade.php | 9 tabs visible |
| 5 | **Verify**: Stopage Status Update tab has id='stop_status' and label='Stopage Status Update' | `tripmanagement.blade.php:14` |
| 6 | **Verify**: `@can('tenant.stop-details.viewAny')` guard passes | Include renders |
| 7 | Click on Stopage Status Update tab | URL changes to `?tab=trip_details` |
| 8 | **Verify**: `trip-details/index.blade.php` renders inside tab pane | DOM has `id="stop_status-pane"` div |
| 9 | **Verify**: Filter form visible with shift dropdown, route dropdown, submit/reset buttons | Filter UI rendered |
| 10 | Select a shift and route, click Search | Form submits with `?shift_id=X&route_id=Y&tab=trip_details` |
| 11 | **Verify**: Timeline renders with stop list | Route-container with route-row elements |
| 12 | **Verify**: Each stop shows: ordinal, stop name, pickup_drop badge, scheduled time, actual time | 5 columns per row |
| 13 | **Verify**: Action buttons visible on current stop only | Single stop shows reach/leave/emergency |
| 14 | **Verify**: Completed stops (with reached_flag or leaving_time) show gray state | State class="completed" |
| 15 | **Verify**: Emergency stops show red alert banner with remarks | Alert div visible |

### TC-P-06: reach — Delayed Detection (Full Steps)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Setup: Pre-create trip with stop detail having sch_arrival_time = now-10min | `sch_arrival_time = 09:50` when `now=10:00` |
| 2 | Login, navigate to Stopage Status tab, select shift+route | Timeline renders |
| 3 | Click "✔ Reached" on the middle stop with pre-set late schedule | AJAX POST with action=reach |
| 4 | **Verify**: Gate passes | No 403 |
| 5 | **Verify**: `switch('reach')` matches case 'reach' | Handler entered |
| 6 | **Verify**: `$stop->update(['reached_flag'=>1, 'reaching_time'=>Carbon::now()])` | DB: reached_flag=1, reaching_time=10:00 |
| 7 | **Verify**: Delay calculation: `$now->gt(Carbon::parse('09:50')->addMinutes(5))` | 10:00 > 09:55 → TRUE |
| 8 | **Verify**: `$notificationType = 'Delayed'` | Delayed type |
| 9 | **Verify**: `TptNotificationLog::create(['notification_type'=>'Delayed', ...])` executed | Notification created |
| 10 | **Verify**: DB check: `SELECT notification_type FROM tpt_notification_log WHERE trip_id=X` | Returns 'Delayed' |

### TC-P-11: emergency on Any Stop

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Setup: Trip exists, stop in current state (reached, not left) | Middle stop ready |
| 2 | Login, navigate, select shift+route, ensure stop is current | Action buttons visible |
| 3 | Click "⚠ Emergency" button | AJAX POST action=emergency, id=stop_id, remark="Flat tire" |
| 4 | **Verify**: Gate passes | OK |
| 5 | **Verify**: Case 'emergency' matched | Handler entered |
| 6 | **Verify**: `$stop->update(['emergency_flag'=>1, 'emergency_time'=>$now, 'emergency_remarks'=>'Flat tire', 'updated_by'=>$updatedBy])` | Stop marked emergency |
| 7 | **Verify**: `SELECT emergency_flag, emergency_time, emergency_remarks FROM tpt_trip_stop_detail WHERE id=X` | emergency_flag=1, time set, remarks='Flat tire' |
| 8 | **Verify**: `TptTripIncidents::create([...])` — incident_type=0, severity='MEDIUM', description='Flat tire', status=0 | Incident record created |
| 9 | **Verify**: DB: `SELECT * FROM tpt_trip_incidents WHERE trip_id=X AND incident_type=0` | Row exists |
| 10 | **Verify**: JSON response: `{status:true, message:'Stop updated successfully'}` | 200 OK |
| 11 | **Verify**: Timeline re-renders: emergency banner visible on stop | Red alert shows "Flat tire" |
| 12 | **Verify**: NO TptNotificationLog created for this emergency | Confirmed gap BC-GAP-06 |

### TC-P-15: tripDetailsUpdated on Existing Stop

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with tenant.stop-details.update | Authenticated |
| 2 | Pre-ensure TptTripStopDetail record with id=5 exists | Record exists |
| 3 | POST `/trip/details/updates` with `{id:5, reaching_time:'2026-07-22 10:30:00', leaving_time:'2026-07-22 10:35:00'}` | Request to tripDetailsUpdated |
| 4 | **Verify**: Gate::authorize('tenant.stop-details.update') at line 549 passes | OK |
| 5 | **Verify**: `$stop = TptTripStopDetail::find(5)` returns record | Found |
| 6 | **Verify**: `activityLog($stop, 'Updated', ['message'=>'Trip Details update successfully.'])` at line 556 | Log created BEFORE update |
| 7 | **Verify**: `$stop->update(['reaching_time'=>'2026-07-22 10:30:00', 'leaving_time'=>'2026-07-22 10:35:00'])` | DB updated |
| 8 | **Verify**: JSON response: `{status:true}` | 200 OK |
| 9 | **Verify**: DB: `SELECT reaching_time, leaving_time FROM tpt_trip_stop_detail WHERE id=5` | Both values match input |
| 10 | **Verify**: activity_log has entry: type='Updated', message='Trip Details update successfully.' | Log exists |

### TC-N-04: Non-Existent PickupPointRoute (new_ format)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with tenant.stop-details.update | Authenticated |
| 2 | POST `/trip/stop-action` with `{action:'start_trip', id:'new_99999'}` | new_ format with non-existent jntId |
| 3 | **Verify**: Gate passes (user has permission) | OK |
| 4 | **Verify**: `$isNew = true` (str_starts_with('new_99999', 'new_')) | New path |
| 5 | **Verify**: `$jntId = 99999` | Integer extracted |
| 6 | **Verify**: `$jnt = PickupPointRoute::find(99999)` returns null | Not found |
| 7 | **Verify**: Return 404 JSON: `{status:false, message:'Junction stop not found.'}` | 404 response |
| 8 | **Verify**: No TptTripStopDetail created | DB unchanged |

### TC-N-13: Guest Access

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Logout (no authentication) | Guest session |
| 2 | POST `/trip/stop-action` | Request attempts to reach controller |
| 3 | **Verify**: Auth middleware redirects to login page | Redirect to `/login` (302) |
| 4 | Repeat for: GET `/stop/details/prepare`, GET `/trip/details/edits`, POST `/trip/details/updates`, GET `/transport/trip-management` | All redirect to login |

### TC-N-15: tripDetailsData Nonexistent Stop ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with tenant.stop-details.view | Authenticated |
| 2 | GET `/trip/details/edits?id=99999` | Non-existent ID |
| 3 | **Verify**: Gate::authorize('tenant.stop-details.view') passes | OK |
| 4 | **Verify**: `TptTripStopDetail::where('id', 99999)->first()` returns null | No record |
| 5 | **Verify**: Return 200 JSON: `{status:true, message:'Trip Data Get successfully', inserted:null}` | **200 with null, NOT 404** |
| 6 | **GAP confirmed**: Should return 404 but returns 200 with null data | BC-GAP-03 |

### TC-N-16: Double start_trip on same stop

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login, navigate, select shift+route, ensure first stop is current | Timeline with action buttons |
| 2 | Click "▶ Start Trip" — first start_trip | Stop created/updated; notification created |
| 3 | Click "▶ Start Trip" again on same stop (now completed state) | **Issue**: Button should be hidden after first start_trip |
| 4 | **Blade guard**: `@if (!$stop->reached_flag && !$stop->leaving_time)` — after first start_trip, both are set → button hidden | Correct: button no longer visible |
| 5 | If button bypassed via direct API: POST action=start_trip on already-reached stop | `$stop->update()` succeeds (reached_flag stays 1, times overwritten) |
| 6 | **Verify**: Another TripStart notification created | Duplicate notifications |

### TC-CR-22: stopAction Switch Has NO Default Case

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `TripController.php:187-298` | switch($request->action) statement |
| 2 | List defined cases: 'start_trip', 'reach', 'leave', 'end_trip', 'emergency' | 5 cases |
| 3 | Verify absence of `default:` clause | **NO DEFAULT** |
| 4 | Trace execution for unknown action: No case matches → skips entire switch | Falls through to line 300 |
| 5 | Line 300-304: returns 200 `{status:true, message:'Stop updated successfully'}` | False positive success |
| 6 | **Impact**: Invalid action parameters produce no error, no DB changes, but client sees success | Misleading response |

### TC-CR-25: stopAction No DB Transaction

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `stopAction()` method | TripController.php:123-304 |
| 2 | Search for `DB::transaction` or `DB::beginTransaction` | **NOT FOUND** |
| 3 | Verify multiple writes per action: stop update + trip update (if extra) + notification log + incident create (if emergency) | At least 2-4 separate DB writes |
| 4 | **Impact**: If any write fails after a previous one succeeds, partial data persists | No atomicity |
| 5 | Compare with `tripDetailsUpdated` which also has no transaction | Same gap |
| 6 | Compare with `TripController::update` which uses `DB::transaction` (line 350) | Inconsistent: trip uses transaction, stop doesn't |

### Blade UI Trace: trip-details/index.blade.php

| Step | Lines | Code | Purpose |
|------|-------|------|---------|
| 01 | 1-2 | `<div class="tab-pane fade p-4 bg-white rounded shadow-sm" id="stop_status-pane">` | Tab pane container |
| 02 | 5-41 | Filter form with shift_id, route_id dropdowns | Tab-specific filter |
| 03 | 7 | `<input type="hidden" name="tab" value="trip_details">` | Tab preservation |
| 04 | 10-17 | Shift dropdown from $shifts | Filter by shift |
| 05 | 18-25 | Route dropdown from $driverLiveRoute | Filter by route (driver-filtered) |
| 06 | 34-38 | Search + Reset buttons | Form actions |
| 07 | 43-46 | `@if ($stopDetails->isEmpty())` | Empty state |
| 08 | 48-58 | Action stop calculation (PHP block) | Determine current action stop |
| 09 | 50 | `$lastLeftStop = $stopDetails->whereNotNull('leaving_time')->last()` | Find last left stop |
| 10 | 53 | `$nextStop = $stopDetails->firstWhere('id', '>', $lastLeftStop->id)` | Find next stop after last left |
| 11 | 56 | `$actionStopId = $stopDetails->first()?->id` | Default to first stop |
| 12 | 60 | `<div class="route-container" style="max-height:65vh; overflow-y:auto;">` | Scrollable container |
| 13 | 62 | `@foreach ($stopDetails as $index => $stop)` | Loop through timeline |
| 14 | 64-82 | State calculation: completed/current/emergency/upcoming | CSS class assignment |
| 15 | 68-69 | `if ($stop->reached_flag || $stop->leaving_time) { $state='completed' }` | Completed state |
| 16 | 72-73 | `elseif ($stop->id === $actionStopId) { $state='current' }` | Current state |
| 17 | 76-77 | `elseif ($stop->emergency_flag) { $state='emergency' }` | Emergency state |
| 18 | 84 | `<div class="route-row {{ $state }}">` | Row with state class |
| 19 | 86-91 | Ordinal circle + connecting line | Visual route timeline |
| 20 | 93-176 | route-card: stop name + badge + timings + actions | Main card content |
| 21 | 96-103 | Stop name + pickup_drop badge | Stop identity |
| 22 | 106-111 | Sch/Act/Reach/Leave timing display | Time columns (note: "Act" mislabeled) |
| 23 | 114 | `@if ($stop->id === $actionStopId && request('shift_id') && request('route_id'))` | Action visibility guard |
| 24 | 117-125 | First stop: Start Trip button | `@if($loop->first)` and guard |
| 25 | 119-124 | `@if (!$stop->reached_flag && !$stop->leaving_time)` | Show Start Trip only if not started |
| 26 | 127-135 | Last stop: End Trip button | `@if($loop->last)` |
| 27 | 137-165 | Middle stops: conditional reach/leave/emergency | Position-specific actions |
| 28 | 139-147 | Not reached: Reached button enabled, Leave+Emergency disabled | Action progression |
| 29 | 149-164 | Reached, not left: Attendance link + Leave + Emergency buttons | Post-reach actions |
| 30 | 150-152 | Attendance link: `route('transport.student.attendances', ['stop_id'=>$stop->id])` | Student attendance |
| 31 | 170-174 | Emergency alert banner | `@if ($stop->emergency_flag)` |

### CODE-TRACE-A: Blade Action Button Data Flow

| Step | Element | Data Attributes | Purpose |
|------|---------|-----------------|---------|
| 01 | Start Trip button | `data-action="start_trip" data-id="{{ $stop->id }}"` | Button clicked → JS reads data-action and data-id |
| 02 | Reached button | `data-action="reach" data-id="{{ $stop->id }}"` | reach action |
| 03 | Leave button | `data-action="leave" data-id="{{ $stop->id }}"` | leave action |
| 04 | End Trip button | `data-action="end_trip" data-id="{{ $stop->id }}"` | end_trip action |
| 05 | Emergency button | `data-action="emergency" data-id="{{ $stop->id }}"` | emergency action |
| 06 | JS Handler | Reads `data-action` + `data-id`, POSTs to `/trip/stop-action` | AJAX request constructed from data attributes |
| 07 | Response handler | `{status: true, time: '...'}` → reloads tab section | UI refresh after action |

### Permission Key Reference (permissionslist.php)

| Permission Key | Used In | Notes |
|----------------|---------|-------|
| `tenant.stop-details.update` | stopAction(), tripDetailsUpdated() | Gate::authorize at method start |
| `tenant.stop-details.prepare` | stopDetailsPrepare() | Gate::authorize at method start |
| `tenant.stop-details.view` | tripDetailsData() | Gate::authorize at method start |
| `tenant.stop-details.viewAny` | tripmanagement.blade.php tab visibility | @can guard |
| `tenant.transport.viewAny` | TripMgmtController@index() | Gate::authorize at method start |
| `tenant.stop-details.delete` | NOT used (policy only) | No controller endpoint |
| `tenant.stop-details.restore` | NOT used (policy only) | No controller endpoint |
| `tenant.stop-details.forceDelete` | NOT used (policy only) | No controller endpoint |
| `tenant.stop-details.create` | NOT used (policy only) | No create/standalone form endpoint |
| `tenant.stop-details.status` | NOT used (policy only) | No status toggle for stop details |

### DB Migration Reference — tpt_trip_stop_detail DDL

| Column | Type | Nullable | Default | Extra |
|--------|------|----------|---------|-------|
| id | int(10) unsigned | NO | NULL | auto_increment |
| trip_id | int(10) unsigned | NO | NULL | FK → tpt_trip.id |
| stop_id | int(10) unsigned | YES | NULL | FK → tpt_pickup_points.id |
| pickup_drop | enum('Pickup','Drop') | NO | 'Pickup' | |
| ordinal | smallint(5) unsigned | NO | 1 | |
| sch_arrival_time | datetime | YES | NULL | |
| sch_departure_time | datetime | YES | NULL | |
| reached_flag | tinyint(1) | NO | 0 | |
| reaching_time | timestamp | YES | NULL | |
| leaving_time | timestamp | YES | NULL | |
| emergency_flag | tinyint(1) | YES | 0 | |
| emergency_time | timestamp | YES | NULL | |
| emergency_remarks | varchar(512) | YES | NULL | |
| created_at | timestamp | YES | current_timestamp() | |
| updated_at | timestamp | YES | current_timestamp() on update | |
| updated_by | int(10) unsigned | YES | NULL | FK → tpt_personnel.id |
| deleted_at | timestamp | YES | NULL | SoftDeletes |

### PickupPointRoute Junction Table Reference (`tpt_pickup_points_route_jnt`)

| Column | Type | Purpose |
|--------|------|---------|
| id | int unsigned | PK |
| route_id | int unsigned | FK → tpt_route.id |
| pickup_point_id | int unsigned | FK → tpt_pickup_points.id |
| shift_id | int unsigned | FK → tpt_shift.id |
| pickup_drop | enum('Pickup','Drop') | Direction |
| ordinal | smallint unsigned | Sequence number |
| arrival_time | int unsigned | Minutes from midnight (e.g., 450 = 07:30) |
| departure_time | int unsigned | Minutes from midnight |
| is_active | tinyint(1) | Active flag |
| deleted_at | timestamp | SoftDeletes |


### Additional TC-P Detailed Steps

#### TC-P-04: start_trip WITHOUT Extra Data

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with tenant.stop-details.update | Authenticated |
| 2 | Navigate to Stopage Status tab, select shift+route | Timeline renders |
| 3 | Click "▶ Start Trip" on first stop WITHOUT sending extra data | AJAX POST with only action=start_trip and id |
| 4 | **Verify**: Stop created with reached_flag=1, reaching_time=now, leaving_time=now | Stop marked |
| 5 | **Verify**: `$request->filled('extra')` evaluates to FALSE | Extra block skipped |
| 6 | **Verify**: Trip NOT updated — status remains 'Scheduled' | `SELECT status FROM tpt_trip` → 'Scheduled' |
| 7 | **Verify**: TripStart notification still created (outside extra block) | Notification exists |
| 8 | **GAP confirmed**: Trip not marked as Ongoing | BC-GAP-04 |

#### TC-P-10: end_trip WITHOUT Extra Data

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login, navigate, ensure last stop is current | Timeline with last stop |
| 2 | Click "⏹ End Trip" on last stop WITHOUT sending extra data | AJAX POST action=end_trip |
| 3 | **Verify**: `$stop->update(['reached_flag'=>1, 'reaching_time'=>$now, 'leaving_time'=>$now])` | Last stop marked complete |
| 4 | **Verify**: `$request->filled('extra')` → FALSE | Extra block skipped |
| 5 | **Verify**: Trip NOT updated — status remains whatever it was (e.g., 'Ongoing') | SELECT status → 'Ongoing' |
| 6 | **Verify**: No notification created for trip completion | No TptNotificationLog |
| 7 | **GAP confirmed**: Trip stays 'Ongoing' after end_trip without extra | BC-GAP-05 |

#### TC-P-17: Driver-Only View

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Setup: DriverHelper record exists linking user to driver_id=5 | Driver user |
| 2 | Setup: DriverRouteVehicleJnt: driver_id=5, route_id=10 (assigned route) | Route 10 assigned |
| 3 | Setup: DriverRouteVehicleJnt: driver_id=5, route_id=20 (another assigned route) | Route 20 assigned |
| 4 | Setup: Another driver has routes 30, 40 (NOT assigned to driver 5) | Route 30,40 exist |
| 5 | Setup: PickupPointRoute records exist for routes 10, 20, 30 | All have stops |
| 6 | Login as driver 5 | $loginDriver = DriverHelper::where('user_id', auth()->id()) returns driver 5 |
| 7 | Navigate to Trip Management → Stopage Status tab | TripMgmtController@index |
| 8 | **Verify**: Line 43-51: $loginDriver found → $driveRoute = [10, 20] | Routes 10,20 assigned |
| 9 | **Verify**: Line 50: $driverLiveRoute filtered to routes 10,20 | Other routes hidden in dropdown |
| 10 | **Verify**: Line 269: `$query->whereIn('route_id', [10, 20])` | Only stops for routes 10,20 loaded |
| 11 | **Verify**: Timeline shows only stops from routes 10,20 | Routes 30,40 stops excluded |

#### TC-P-13: Prepare Stop Details — Skips Existing

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Call stopDetailsPrepare first time (see TC-P-12) | 3 records inserted |
| 2 | Call stopDetailsPrepare SECOND TIME with same trip_id | Same GET request |
| 3 | **Verify**: Loop iteration 1: `exists()` = true (already inserted) | `$skipped++` |
| 4 | **Verify**: Loop iteration 2: `exists()` = true | `$skipped++` |
| 5 | **Verify**: Loop iteration 3: `exists()` = true | `$skipped++` |
| 6 | **Verify**: No new INSERT queries executed | Only SELECT for exists check |
| 7 | **Verify**: JSON response: `{status:true, inserted:0, skipped:3}` | All skipped |
| 8 | **Verify**: DB count unchanged: 3 records | No duplicates |

### Additional TC-N Detailed Steps

#### TC-N-06: Non-Existent Stop ID (existing format)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with tenant.stop-details.update | Authenticated |
| 2 | POST `/trip/stop-action` with `{action:'reach', id:99999}` | Existing format, non-existent ID |
| 3 | **Verify**: Gate passes | OK |
| 4 | **Verify**: `$isNew = false` (no 'new_' prefix) | Existing path |
| 5 | **Verify**: `$stop = TptTripStopDetail::with('trip.routeScheduler')->find(99999)` returns null | Not found |
| 6 | **Verify**: Return 404 JSON: `{status:false, message:'Stop Detail not found.'}` | 404 response |
| 7 | **Verify**: No DB changes | Unchanged |

#### TC-N-07: Prepare Without Trip ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with tenant.stop-details.prepare | Authenticated |
| 2 | GET `/stop/details/prepare` with NO trip_id parameter | No query params |
| 3 | **Verify**: Gate::authorize('tenant.stop-details.prepare') passes | OK |
| 4 | **Verify**: `$tripId = $request->trip_id ?? $request->tripe_id` = null | Empty |
| 5 | **Verify**: `if (empty($tripId))` → true | Guard triggered |
| 6 | **Verify**: Return 400 JSON: `{status:false, message:'Trip ID is required'}` | 400 response |
| 7 | **Verify**: No DB changes | Unchanged |

#### TC-N-08: Prepare Non-Existent Trip

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with tenant.stop-details.prepare | Authenticated |
| 2 | GET `/stop/details/prepare?trip_id=99999` | Non-existent trip ID |
| 3 | **Verify**: Gate passes | OK |
| 4 | **Verify**: `$trip = TptTrip::with('routeScheduler')->find(99999)` returns null | Not found |
| 5 | **Verify**: Return 404 JSON: `{status:false, message:'Trip not found'}` | 404 response |

#### TC-N-10: Permission 403 — No tenant.stop-details.prepare

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user WITHOUT tenant.stop-details.prepare | Lacks prepare |
| 2 | GET `/stop/details/prepare?trip_id=1` | Request to stopDetailsPrepare |
| 3 | **Verify**: `Gate::authorize('tenant.stop-details.prepare')` at line 468 throws | 403 Forbidden |
| 4 | **Verify**: No stop details prepared | DB unchanged |

#### TC-N-12: Permission 403 — No tenant.transport.viewAny

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user WITHOUT tenant.transport.viewAny | Lacks viewAny |
| 2 | GET `/transport/trip-management` | Request to TripMgmtController |
| 3 | **Verify**: `Gate::authorize('tenant.transport.viewAny')` at TripMgmtController.php:38 throws | 403 Forbidden |
| 4 | **Verify**: Tab page not rendered | 403 response |

### Additional TC-D Detailed Steps

#### TC-D-02: PickupPoint Delete Sets stop_id NULL

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure stop detail record has stop_id=5 referencing pickup point 5 | stop_id=5, pickup point 5 exists |
| 2 | Delete pickup point 5 (soft or hard delete via PickupPointController) | Pickup point removed |
| 3 | **Verify**: `SELECT stop_id FROM tpt_trip_stop_detail WHERE stop_id=5` | stop_id = NULL (FK SET NULL) |
| 4 | **Verify**: DDL: `$table->foreign('stop_id')->references('id')->on('tpt_pickup_points')->onDelete('set null')` | SET NULL behavior confirmed |

#### TC-D-06: leave Creates NotificationLog

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure stop is in reached-but-not-left state | reached_flag=1, leaving_time=NULL |
| 2 | POST action=leave on this stop | leave handler |
| 3 | **Verify**: `$stop->update(['leaving_time'=>$now])` | leaving_time set |
| 4 | **Verify**: `TptNotificationLog::create(['notification_type'=>'ApproachingStop', ...])` | Notification created |
| 5 | **Verify**: `SELECT * FROM tpt_notification_log WHERE trip_id=X AND notification_type='ApproachingStop'` | Row exists |

#### TC-D-07: Emergency Does NOT Create Notification (GAP Verification)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST action=emergency on a stop | See TC-P-11 steps |
| 2 | **Verify**: switch case 'emergency' executed | Case matched |
| 3 | **Verify**: `TptTripIncidents::create([...])` called | Incident created |
| 4 | **Verify**: Search entire case 'emergency' block for `TptNotificationLog::create()` | **NOT FOUND** |
| 5 | **Verify**: `SELECT * FROM tpt_notification_log WHERE trip_id=X` | No row for this emergency |
| 6 | **Compare** with case 'reach' which explicitly creates notification | Contrast: reach creates, emergency doesn't |
| 7 | **GAP confirmed**: Emergency has no notification | BC-GAP-06 |

#### TC-D-08: stopDetailsPrepare Uses DB Transaction

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open stopDetailsPrepare at TripController.php:487 | `DB::beginTransaction()` |
| 2 | Verify line 536: `DB::commit()` | Transaction commited |
| 3 | **Verify**: No `DB::rollback()` found | **GAP**: No rollback on exception |
| 4 | **Verify**: No try-catch block wrapping transaction | No error handling |

#### TC-D-14: Timeline Fallback Cross-Route

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Setup: Trip exists for route 10 today (trip A) | Trip A: route_id=10 |
| 2 | Setup: PickupPointRoute records for route 20 with stops | Route 20 stops exist |
| 3 | Setup: NO trip exists for route 20 today | Only trip A exists |
| 4 | Login, select route 20 in filter | Tab=route 20, but trip exists for route 10 |
| 5 | **Verify**: TripMgmtController line 305: `$fallbackTripId = $todayTrips->first()->id` = trip A's ID | Route 20 stops matched to trip A's ID |
| 6 | **Verify**: Timeline renders with route 20 stops but linked to trip A | Cross-route data mapping |
| 7 | **Verify**: TptTripStopDetail lookup uses trip A's ID for route 20 stops | Potentially incorrect trip association |

### Additional TC-CR Detailed Steps

#### TC-CR-23: start_trip Without Extra No Status Update

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `TripController.php:189-217` | case 'start_trip' |
| 2 | Verify lines 190-196: stop update ALWAYS runs | Stop updated unconditionally |
| 3 | Verify lines 198-208: `if ($request->filled('extra'))` guards trip update | Extra data block |
| 4 | Verify status='Ongoing' at line 206 is INSIDE extra block | Only set if extra provided |
| 5 | **Impact**: start_trip without extra does NOT set trip to Ongoing | BC-GAP-04 |

#### TC-CR-26: tripDetailsUpdated activityLog Before Update

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `TripController.php:547-568` | tripDetailsUpdated method |
| 2 | Note line 556: `activityLog($stop, 'Updated', [...])` | Runs BEFORE update |
| 3 | Note line 560: `$stop->update([...])` | Runs AFTER activityLog |
| 4 | **Verify**: If update fails (e.g., DB error), activity log already written | Orphaned log entry |
| 5 | **Compare** with standard CRUD pattern: activityLog AFTER successful update | Inverted order |

#### TC-CR-47: Emergency incident_type Hardcoded to 0

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `TripController.php:285-294` | Incident creation in emergency case |
| 2 | Verify line 288: `'incident_type' => 0` | Always 0 |
| 3 | Search for any mapping/configuration for this value | Not found |
| 4 | Determine what incident_type=0 represents in TptTripIncidents | 'Stop Emergency' (hardcoded) |
| 5 | **Impact**: No way to classify emergencies by type (mechanical, medical, etc.) | Limited incident categorization |

### Validation Rules Summary

| Endpoint | Method | Request Validation | Authorization | Activity Log |
|----------|--------|-------------------|---------------|-------------|
| stopAction | POST | NONE (gap) | Gate::authorize('tenant.stop-details.update') | NONE (gap) |
| stopDetailsPrepare | GET | Manual: trip_id empty check (400), trip exists (404) | Gate::authorize('tenant.stop-details.prepare') | activityLog($stop, 'Create', ...) per insert |
| tripDetailsData | GET | NONE (returns null, no 404) | Gate::authorize('tenant.stop-details.view') | NONE |
| tripDetailsUpdated | POST | Manual: stop exists (404) | Gate::authorize('tenant.stop-details.update') | activityLog($stop, 'Updated', ...) before update |

### Identified Gaps Summary

| # | Gap | File:Line | Severity |
|---|-----|-----------|----------|
| G-01 | stopAction no activityLog | TripController.php:123-304 | HIGH |
| G-02 | Switch has no default case (invalid action = false success) | TripController.php:187-298 | MEDIUM |
| G-03 | tripDetailsData returns 200 with null instead of 404 | TripController.php:331 | LOW |
| G-04 | start_trip without extra doesn't update trip status | TripController.php:198-208 | MEDIUM |
| G-05 | end_trip without extra doesn't update trip status | TripController.php:264-274 | MEDIUM |
| G-06 | Emergency action creates no notification | TripController.php:277-297 | MEDIUM |
| G-07 | end_trip without extra creates no notification | TripController.php:255-274 | LOW |
| G-08 | No DB transaction in stopAction | TripController.php:187-298 | MEDIUM |
| G-09 | tripDetailsUpdated activityLog missing performed_by/changes | TripController.php:556-558 | LOW |
| G-10 | stopDetailsPrepare activityLog references wrong model | TripController.php:519-521 | MEDIUM |
| G-11 | No validation on extra data keys in stopAction | TripController.php:198-208 | LOW |
| G-12 | Double-reach/leave overwrites timestamps | TripController.php:219-244 | LOW |
| G-13 | Delete/restore/forceDelete defined in policy but no endpoints | TransportStopDetailsPolicy | MEDIUM |
| G-14 | Timeline "Act" label mislabeled (shows departure) | trip-details/index.blade.php:108 | LOW |
| G-15 | stopDetailsPrepare no DB::rollback on exception | TripController.php:487-536 | MEDIUM |
| G-16 | Emergency incident_type always 0 | TripController.php:288 | LOW |
| G-17 | Emergency severity always MEDIUM | TripController.php:293 | LOW |
| G-18 | stopAction no validation on $request->id (missing) | TripController.php:127 | MEDIUM |
| G-19 | Trip ID merge cross-tab side effect | TripMgmtController.php:67 | LOW |
| G-20 | tripDetailsUpdated activityLog called before update | TripController.php:556-560 | LOW |

### Notification Type Reference

| Action | Notification Type | Created? |
|--------|-------------------|----------|
| start_trip | 'TripStart' | Yes (always, outside extra block) |
| reach (on-time) | 'ReachedStop' | Yes |
| reach (delayed) | 'Delayed' | Yes |
| leave | 'ApproachingStop' | Yes |
| end_trip (with extra) | NONE | No |
| end_trip (without extra) | NONE | No |
| emergency | NONE | No (gap G-06) |
| start_trip (repeated) | 'TripStart' again | Yes (duplicate possible) |

### Test Coverage Matrix

| Feature Area | TC-P | TC-N | TC-D | TC-CR | Total |
|-------------|------|------|------|-------|-------|
| Timeline Display (DL-01 to DL-20) | TC-P-01, TC-P-17, TC-P-19, TC-P-20 | TC-N-19 | TC-D-14 | TC-CR-30, TC-CR-31, TC-CR-32, TC-CR-34, TC-CR-35, TC-CR-36, TC-CR-39, TC-CR-49, TC-CR-50 | 16 |
| stopAction — start_trip (BC-BIZ-01 to BC-BIZ-03) | TC-P-02, TC-P-03, TC-P-04 | TC-N-16 | TC-D-17, TC-D-18 | TC-CR-23, TC-CR-51 | 7 |
| stopAction — reach (BC-BIZ-04 to BC-BIZ-06) | TC-P-05, TC-P-06, TC-P-07 | TC-N-17 | TC-D-05, TC-D-12 | TC-CR-12, TC-CR-27 | 7 |
| stopAction — leave (BC-BIZ-07) | TC-P-08 | TC-N-18 | TC-D-06 | — | 3 |
| stopAction — end_trip (BC-BIZ-08 to BC-BIZ-09) | TC-P-09, TC-P-10 | — | TC-D-16 | TC-CR-24 | 4 |
| stopAction — emergency (BC-BIZ-10) | TC-P-11 | — | TC-D-03, TC-D-07, TC-D-19 | TC-CR-05, TC-CR-13, TC-CR-37, TC-CR-45, TC-CR-46, TC-CR-47 | 10 |
| stopAction — General (BC-BIZ-11 to BC-BIZ-13) | TC-P-14, TC-P-16, TC-P-18 | TC-N-01, TC-N-02, TC-N-03, TC-N-04, TC-N-05, TC-N-06, TC-N-20 | TC-D-12 | TC-CR-01, TC-CR-02, TC-CR-03, TC-CR-04, TC-CR-11, TC-CR-15, TC-CR-19, TC-CR-20, TC-CR-22, TC-CR-25, TC-CR-41, TC-CR-42 | 22 |
| stopDetailsPrepare (BC-BIZ-14 to BC-BIZ-15) | TC-P-12, TC-P-13 | TC-N-07, TC-N-08 | TC-D-08, TC-D-09, TC-D-10, TC-D-15 | TC-CR-10, TC-CR-15, TC-CR-28, TC-CR-29 | 10 |
| tripDetailsUpdated (BC-BIZ-16) | TC-P-15 | TC-N-14 | TC-D-11, TC-D-13 | TC-CR-16, TC-CR-26, TC-CR-27, TC-CR-53 | 7 |
| tripDetailsData (BC-BIZ-17 to BC-BIZ-18) | TC-P-16 | TC-N-15 | — | TC-CR-17, TC-CR-19 | 3 |
| Authorization (BC-AUTH-01 to BC-AUTH-07) | — | TC-N-09, TC-N-10, TC-N-11, TC-N-12, TC-N-13 | — | TC-CR-01, TC-CR-15, TC-CR-16, TC-CR-17, TC-CR-18, TC-CR-48 | 10 |
| Data Integrity (FK + Cascade) | — | — | TC-D-01, TC-D-02, TC-D-04 | TC-CR-09 | 4 |
| Model (BC-MODEL-01 to BC-MODEL-15) | — | — | — | TC-CR-07, TC-CR-08, TC-CR-33, TC-CR-40, TC-CR-43, TC-CR-44 | 6 |
| Policy Gaps (BC-GAP-13) | — | — | TC-D-20 | TC-CR-21 | 2 |
| **Totals** | **20** | **20** | **20** | **54** | **114** |


---

### Database Table Reference (DDL Cross-Check)

| Table | Columns Used | FK References | On Delete | On Update |
|-------|-------------|---------------|-----------|-----------|
| `tpt_route_scheduler` | id, route_id, shift_type, date, start_date, end_date | route_id → tpt_route | CASCADE | CASCADE |
| `tpt_trip` | id, scheduler_id, trip_date, shift_type_id, route_id, status, start_time, end_time, extra_data | scheduler_id → tpt_route_scheduler | CASCADE | CASCADE |
| `tpt_trip_stop_detail` | id, trip_id, stop_id, stop_name, stop_order, reached_flag, reaching_time, leaving_time, extra_data | trip_id → tpt_trip (CASCADE), stop_id → tpt_pickup_points (SET NULL) | CASCADE/SET NULL | CASCADE |
| `tpt_pickup_points` | id, name, address, latitude, longitude | — | — | — |
| `tpt_pickup_point_route` | id, pickup_point_id, route_id, stop_order | pickup_point_id → tpt_pickup_points (CASCADE), route_id → tpt_route (CASCADE) | CASCADE | CASCADE |
| `tpt_trip_incidents` | id, trip_stop_detail_id, trip_id, incident_type, severity, description | trip_stop_detail_id → tpt_trip_stop_detail, trip_id → tpt_trip | CASCADE | CASCADE |
| `tpt_notification_log` | id, trip_stop_detail_id, trip_id, notification_type, message | trip_stop_detail_id → tpt_trip_stop_detail, trip_id → tpt_trip | CASCADE | CASCADE |
| `driver_route_vehicle_jnt` | id, driver_id, route_id, vehicle_id | driver_id → hrm_employee, route_id → tpt_route, vehicle_id → tpt_vehicle | CASCADE | CASCADE |
| `driver_helper` | id, user_id, driver_id | user_id → users, driver_id → hrm_employee | CASCADE | CASCADE |

### Data Flow Diagram (Summary)

```
User Action (Click Button on Timeline)
       │
       ▼
trip-details/index.blade.php (JS event → AJAX)
       │
       ▼
trip-details/index.js ($.ajax → POST /trip/stop-action)
       │
       ▼
TripController@stopAction (switch on $request->action)
       │
       ├── start_trip → Update stop(timestamps) + [OPTIONAL] Update trip(status=Ongoing)
       ├── reach → Update stop(reached_flag=1, reaching_time=now) + Create notification
       ├── leave → Update stop(leaving_time=now) + Create notification
       ├── end_trip → Update stop(timestamps) + [OPTIONAL] Update trip(status=Complete)
       └── emergency → Create TptTripIncidents record + [NO notification]
```

### Controller File Paths Reference

| File | Full Path | Key Methods |
|------|-----------|-------------|
| TripController | `Modules/Transport/Http/Controllers/TripController.php` | stopAction (L120-304), tripDetailsData (L306-340), tripDetailsUpdated (L542-568), stopDetailsPrepare (L466-536) |
| TripMgmtController | `Modules/Transport/Http/Controllers/TripMgmtController.php` | index (all lines), driverRoute (L43-51), tripData (L233-327), tripQuery (L329-343), filteredStops (L205-226), userRoutes (L112-115), timelineStops (L271-284) |
| TransportStopDetailsPolicy | `Modules/Transport/Policies/TransportStopDetailsPolicy.php` | viewAny, view, create, update, delete, restore, forceDelete |
| TptTripStopDetail Model | `Modules/Transport/Entities/TptTripStopDetail.php` | All casts, fillable, relations |
| TptTrip Model | `Modules/Transport/Entities/TptTrip.php` | All casts, fillable, relations |
| Blade: tab layout | `Modules/Transport/Resources/views/trip-details/index.blade.php` | Timeline render, act buttons, show-trip-detail modal |
| Blade: partials | `Modules/Transport/Resources/views/trip-details/trip-details.blade.php` | Trip data header |

### Requirement Traceability Matrix (Complete)

| Req ID | Description | TC-P | TC-N | TC-D | TC-CR |
|--------|-------------|------|------|------|-------|
| REQ-01 | Timeline shall display stops in order for selected route+shift | P-01, P-17, P-20 | N-19 | D-14 | CR-30, CR-31, CR-32, CR-34, CR-35, CR-36, CR-39, CR-49, CR-50 |
| REQ-02 | User shall start a trip from the first stop | P-02, P-03, P-04 | N-16 | D-17, D-18 | CR-23, CR-51 |
| REQ-03 | User shall mark a stop as reached | P-05, P-06, P-07 | N-17 | D-05, D-12 | CR-12, CR-27 |
| REQ-04 | User shall mark a stop as left (departed) | P-08 | N-18 | D-06 | — |
| REQ-05 | User shall end a trip from the last stop | P-09, P-10 | — | D-16 | CR-24 |
| REQ-06 | User shall report an emergency on any stop | P-11 | — | D-03, D-07, D-19 | CR-05, CR-13, CR-37, CR-45, CR-46, CR-47 |
| REQ-07 | System shall assign driver routes based on DriverHelper | P-17 | — | — | — |
| REQ-08 | System shall prepare stop details for a trip | P-12, P-13 | N-07, N-08 | D-08, D-09, D-10, D-15 | CR-10, CR-15, CR-28, CR-29 |
| REQ-09 | System shall display trip details data | P-16 | N-15 | — | CR-17, CR-19 |
| REQ-10 | User shall update trip details | P-15 | N-14 | D-11, D-13 | CR-16, CR-26, CR-27, CR-53 |
| REQ-11 | System shall enforce permissions | — | N-09, N-10, N-11, N-12, N-13 | — | CR-01, CR-15, CR-16, CR-17, CR-18, CR-48 |
| REQ-12 | System shall maintain referential integrity | — | — | D-01, D-02, D-04 | CR-09 |
| REQ-13 | System shall support toggle action | P-14 | N-01, N-02, N-03, N-04, N-05 | — | CR-11, CR-15, CR-22 |
| REQ-14 | System shall log stop action | P-18 | N-20 | — | CR-14, CR-15, CR-25 |
| REQ-15 | System shall handle extra data in stop/trip actions | P-03, P-06, P-07, P-09 | — | D-17, D-18 | CR-23, CR-24, CR-51 |

---

*Document generated by AI-assisted analysis. All code references point to specific file:line locations in the Transport module. Cross-check against latest codebase before test execution.*

---

### Policy Implementation Gap Analysis

#### TransportStopDetailsPolicy Methods vs Actual Endpoints

| Policy Method | Permission String | Defined In Policy? | Controller Method Exists? | Route Exists? | Gap? |
|--------------|-------------------|--------------------|--------------------------|---------------|------|
| viewAny | tenant.stop-details.viewAny | ✅ | ✅ TripMgmtController@index | ✅ /transport/trip-management | No |
| view | tenant.stop-details.view | ✅ | ✅ TripController@tripDetailsData | ✅ /trip/details/data | No |
| create | tenant.stop-details.create | ✅ | ❌ NONE | ❌ NONE | **GAP-13** |
| update | tenant.stop-details.update | ✅ | ✅ TripController@stopAction, tripDetailsUpdated | ✅ /trip/stop-action, /trip/details/update | No |
| delete | tenant.stop-details.delete | ✅ | ❌ NONE (no delete endpoint) | ❌ NONE | **GAP-13** |
| restore | tenant.stop-details.restore | ✅ | ❌ NONE | ❌ NONE | **GAP-13** |
| forceDelete | tenant.stop-details.forceDelete | ✅ | ❌ NONE | ❌ NONE | **GAP-13** |

**Impact**: `create`, `delete`, `restore`, `forceDelete` are defined in the policy but have no corresponding routes, controller methods, or blade UI — making them dead code. If a user is granted these permissions, they have no way to exercise them.

#### Permission String Mismatch: Policy vs Views vs permissionslist.php

| Component | String Used | Matches permissionslist.php? |
|-----------|-------------|------------------------------|
| TransportStopDetailsPolicy::viewAny | `tenant.stop-details.viewAny` | Cross-reference required |
| TripController@stopAction Gate | `tenant.stop-details.update` | Cross-reference required |
| TripController@tripDetailsData Gate | `tenant.stop-details.view` | Cross-reference required |
| TripController@tripDetailsUpdated Gate | `tenant.stop-details.update` | Cross-reference required |
| TripController@stopDetailsPrepare Gate | `tenant.stop-details.prepare` | Cross-reference required |
| TripMgmtController@index Gate | `tenant.transport.viewAny` | Cross-reference required |
| Blade @can('...update') in status-switch | `tenant.stop-details.update` | Cross-reference required |
| Blade @canany in action column | `['tenant.stop-details.view', 'tenant.stop-details.update', 'tenant.stop-details.delete']` | Cross-reference required |
| Blade @can('...create') Add button | ❌ NOT PRESENT (no Add button) | N/A |
| permissionslist.php group | `stop-details` | **SOURCE OF TRUTH** |

**⚠ Verify**: Check `config/permissionslist.php` for the exact group name matching `stop-details`. If it uses a different slug (e.g. `stopage-status`), ALL strings above are wrong and must be updated.

### Stop Segregation Logic: State Machine

```
                    start_trip
                    ┌──────────┐
                    │          ▼
         ┌──────────────────────────┐
         │   Not Started            │
         │   (reached_flag=0,       │
         │    reaching_time=NULL,   │
         │    leaving_time=NULL)    │
         └──────────────────────────┘
                    │
                    │ reach
                    ▼
         ┌──────────────────────────┐
         │   Reached                │
         │   (reached_flag=1,       │
         │    reaching_time=set,    │
         │    leaving_time=NULL)    │
         └──────────────────────────┘
                    │
                    │ leave
                    ▼
         ┌──────────────────────────┐
         │   Departed               │
         │   (reached_flag=1,       │
         │    reaching_time=set,    │
         │    leaving_time=set)     │
         └──────────────────────────┘
                    │
                    │ (next stop's reach)
                    ▼
         ┌──────────────────────────┐
         │   Next stop states       │
         └──────────────────────────┘

Emergency can happen from ANY state: Not Started / Reached / Departed
```

### Timeline Display Logic Pseudocode

```
FUNCTION renderTimeline(tripId, routeId):
    stops = GET stops FROM tpt_trip_stop_detail WHERE trip_id = tripId
             ORDER BY stop_order ASC
             WITH trip, trip.routeScheduler
    
    IF stops IS EMPTY:
        stops = GET stops FROM tpt_pickup_point_route WHERE route_id = routeId
                ORDER BY stop_order ASC
                WITH pickupPoint
        callback prepareStopDetails(tripId)  // Async prepare
    
    timelineHTML = ""
    totalStops = COUNT(stops)
    
    FOR EACH index, stop IN stops:
        actButton = ""
        
        IF index == 0 AND stop.leaving_time IS NULL:
            actButton = "▶ Start Trip"  // First stop, not yet started
        ELSE IF stop.reached_flag == 0 AND stop.leaving_time IS NULL:
            actButton = "📍 Mark Reached"  // Not yet reached, not left
        ELSE IF stop.reached_flag == 1 AND stop.leaving_time IS NULL:
            actButton = "🚀 Mark Leave"  // Reached but not left
        
        IF index == totalStops-1 AND stop.leaving_time IS NOT NULL:
            actButton = "⏹ End Trip"  // Last stop departed
        
        IF stop.emergencyExists:
            actButton += " 🆘 Emergency Reported"
        
        timelineHTML += renderStopCard(stop, actButton, index == totalStops-1)
    
    RETURN timelineHTML

FUNCTION determineActButton(stop, isFirst, isLast):
    IF isFirst AND stop.leaving_time IS NULL:
        RETURN "start_trip"
    IF stop.reached_flag == 0:
        RETURN "reach"
    IF stop.reached_flag == 1 AND stop.leaving_time IS NULL:
        RETURN "leave"
    IF isLast AND stop.leaving_time IS NOT NULL:
        RETURN "end_trip"
    RETURN "completed"  // Intermediate stop, both reached and left
```

### Timeline Labeling Map (Blade line 52-110)

| CSS Class / id | Condition | Label | Type |
|----------------|-----------|-------|------|
| `.timeline-item-danger` | Emergency exists (stop->incidents->isNotEmpty()) | "🆘" | Indicator |
| `.timeline-item-primary` | stop_order == 0 (first stop) | "Start Point" | Header |
| `.timeline-item-warning` | reached_flag=1 AND leaving_time≠NULL | "Arrived → Departed" | Status |
| `.timeline-item-info` | reached_flag=1 AND leaving_time=NULL | "Arrived" | Status |
| `.timeline-item-secondary` | reached_flag=0 AND leaving_time=NULL | "Not Yet Arrived" | Status |
| `.act` button (line 100-108) | Varies by state (see display logic) | "Reach / Leave / Start / End / Emergency" | Action |
| `.checkpoint-marker` | All stops after first | Stop order number | Visual |

### Test Execution Checklist

- [ ] Verify `config/permissionslist.php` contains `stop-details` group with all permission strings
- [ ] Verify all `Gate::authorize()` strings match `permissionslist.php` exactly
- [ ] Verify `@can` strings in all blade files match `Gate::authorize()` strings
- [ ] Verify DDL: `tpt_trip_stop_detail.stop_id` has `ON DELETE SET NULL`
- [ ] Verify DDL: `tpt_trip_stop_detail.trip_id` has `ON DELETE CASCADE`
- [ ] Verify `tpt_pickup_points` has FK to `tpt_pickup_point_route` via `tpt_pickup_points.id`
- [ ] Run `php artisan route:list | grep stop-action` — confirm route registered
- [ ] Run `php artisan route:list | grep trip-management` — confirm route registered
- [ ] Run `php artisan route:list | grep stop-details` — confirm all routes
- [ ] Check `crud-patterns.md` Section 3F for trash.blade.php compliance if delete/restore added in future
- [ ] Check `permission-rules.md` Rule 5 for @can/@canany symmetry in all blades
- [ ] Verify `tpt_route_scheduler` has valid date range overlapping trip date
- [ ] Verify `TptTripStopDetail` model has `$casts` for `reached_flag` (boolean) and timestamps
- [ ] Verify JS: AJAX success handler updates timeline without page reload
- [ ] Verify JS: AJAX error handler shows `notyf` error toast

### Code Style Compliance Check

| Rule Source | Rule | Compliance |
|-------------|------|------------|
| permission-rules.md Rule 1 | Dot-separated format: `tenant.<module-slug>.<action>` | ✅ Used throughout |
| permission-rules.md Rule 2 | `Gate::authorize()` at start of every controller method | ⚠ `stopAction` (L120) — Gate is first line ✅ |
| permission-rules.md Rule 3A | Table th/td symmetry | ⚠ Blade line 76 and 118 must be verified |
| permission-rules.md Rule 3B | Add button wrapped in @can | ⚠ No Add button exists |
| permission-rules.md Rule 4 | Every blade file must have @can checks | ✅ Present in both blades |
| permission-rules.md Rule 5 | Quick checklist | See checklist above |
| permission-rules.md Rule 6 | Dots vs hyphens consistency | ⚠ String: `tenant.stop-details.*` — verify vs permissionslist.php |
| crud-patterns.md Section 1 | Breadcrumbs with `:links="[]"` | ✅ Both blades use `:links="[]"` |
| crud-patterns.md Section 3B-3 | Tab partial has `<div class="tab-pane fade">` | ✅ trip-details.blade.php wraps content in `tab-pane` |
| crud-ui-rules.md Rule 0 | All use imports must be explicit in Controller | ⚠ Must verify TripController imports |
| crud-ui-rules.md Section 2 | Status badges use subtile colors | ⚠ Blade uses Bootstrap context classes |
| crud-ui-rules.md Section 7g | SweetAlert confirm on destructive actions | ⚠ Verify if AJAX actions have confirm dialogs |
| crud-ui-rules.md Rule 8 | NEVER modify component files | ✅ Assumed compliant |

### Action Button Visibility Matrix

| Stop Position | reached_flag | leaving_time | Action Button | Visible? |
|--------------|-------------|-------------|---------------|----------|
| First | 0 | NULL | start_trip | ✅ |
| First | 0 | set | start_trip | ✅ (unusual state) |
| First | 1 | NULL | leave | ✅ (re-reachable) |
| First | 1 | set | — (completed) | ❌ |
| Middle | 0 | NULL | reach | ✅ |
| Middle | 1 | NULL | leave | ✅ |
| Middle | 1 | set | — (completed) | ❌ |
| Last | 0 | NULL | reach | ✅ |
| Last | 1 | NULL | leave | ✅ |
| Last | 1 | set | end_trip | ✅ |
| Any | any | any | emergency | ✅ (always) |

### Key Model Relations (TptTripStopDetail)

```php
// From TptTripStopDetail model
public function trip() {
    return $this->belongsTo(TptTrip::class, 'trip_id');
}

public function incidents() {
    return $this->hasMany(TptTripIncidents::class, 'trip_stop_detail_id');
}

// From TptTrip model  
public function routeScheduler() {
    return $this->belongsTo(TptRouteScheduler::class, 'scheduler_id');
}

public function stopDetails() {
    return $this->hasMany(TptTripStopDetail::class, 'trip_id');
}

// Used in TripMgmtController@timelineStops (L271-284):
// $query->with(['trip.routeScheduler'])
// $query->with(['incidents'])  (if emergency_exists check needed)
```

### Common Fail Modes

| Scenario | Root Cause | Detection |
|----------|------------|-----------|
| Timeline empty | No trip exists for selected route+shift today | TripMgmtController L303: `$todayTrips->isEmpty()` |
| Timeline shows wrong stops | Fallback trip ID used for different route | Cross-route stop association (D-14) |
| Action button does nothing | stop_id doesn't match any record | 404 from stopAction |
| Status toggle doesn't persist | No `is_active` column on tpt_trip_stop_detail | Policy mismatch |
| 403 on all stop actions | User lacks `tenant.stop-details.update` | Gate throws AuthorizationException |
| Timeline loads but no buttons | Permission: user lacks `tenant.stop-details.update` but has `view` | Gate not checked in blade for button visibility |
| Stop details prepare hangs | DB transaction not committed (no rollback) | Connection stuck in transaction |
| Double-click on Reach causes two notifications | No idempotency check on reach | Two TptNotificationLog rows created |

*End of Document*
