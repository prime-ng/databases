# tpt_StopageDetails_TcList

## Module: Transport → Trip Management → Stopage Details

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | Transport |
| Tab Group | Trip Management |
| Feature | Stopage Details (Manual edit of trip stop detail times/emergency via modal) + Stop Action (Reach/Leave/Emergency/Start Trip/End Trip live timeline actions) |
| URL(s) | `/stop/details/prepare` (stopDetailsPrepare GET — bulk prepare stops from route), `/trip/details/edits` (tripDetailsData GET — fetch single stop detail for edit modal), `/trip/details/updates` (tripDetailsUpdated POST — update single stop detail fields), `/trip/stop-action` (stopAction POST — reach/leave/emergency/start_trip/end_trip live action) |
| Controller | `Modules\Transport\Http\Controllers\TripController` |
| Tab Container Controller | `TripMgmtController@index()` — tabs: `stop_details` (grid/edits modal), `stop_status` (live timeline actions), `trip_details` (internal filter alias) |
| Model | `Modules\Transport\Models\TptTripStopDetail` — table: `tpt_trip_stop_detail` |
| Permissions | `tenant.stop-details.viewAny` (tab visibility `stop_status`), `tenant.stop-details.prepare` (tab visibility `stop_details` + prepare endpoint), `tenant.stop-details.view` (fetch single), `tenant.stop-details.update` (manual edit + stopAction live actions) |
| Permission Config | `config/permissionslist.php` lines 321–322: `'stop-details' => $crud, 'stop-details.prepare' => $crud,` — under `tenant.transport` |
| Policy | `Modules\Transport\Policies\TransportStopDetailsPolicy` — defines: viewAny, view, status, create, update, delete, restore, forceDelete, import, export, print, prepare, viewSequence, updateTimings. **Policy methods are never invoked by controller** (controller uses string `Gate::authorize()`) |
| Soft Deletes | Yes (`TptTripStopDetail` uses `SoftDeletes` trait) |
| Activity Log | `Create` (on stopDetailsPrepare — logged per stop with message 'Trip Details Create successfully.'), `Updated` (on tripDetailsUpdated — 'Trip Details update successfully.'). **No activityLog in stopAction** — gap. |

---

## 2. Pre-conditions

- Required permissions: `tenant.stop-details.prepare`, `tenant.stop-details.view`, `tenant.stop-details.update`
- A trip must exist to load/prepare stop details
- Stop details tab (`stop_details`) shows existing TptTripStopDetail records for a given trip
- The prepare endpoint auto-generates stop detail records from PickupPointRoute definitions
- For `stop_status` timeline (live actions): a shift_id AND route_id must be selected for action buttons to appear (see `details-list.blade.php:114`)
- `TptNotificationLog` model must have fillable attributes defined (currently empty — **CRITICAL BUG**)
- PickupPointRoute records must exist for the trip's route and shift

---

## 3. Default Data Load

When `tab=stop_details` is active via TripMgmtController@index():

| Data | Source | Query | Filters |
|------|--------|-------|---------|
| Stop Details Grid | `TripMgmtController@tripStopNew()` | `TptTripStopDetail::with('stop')->orderBy('id')` | tab=stop_details: trip_id/tripe_id, date, route_id, pickup_drop |

When `tab=stop_status` or `tab=trip_details` is active:

| Data | Source | Query | Filters |
|------|--------|-------|---------|
| Stop Status Timeline | `TripMgmtController@tripStopTimeline()` | `PickupPointRoute::with('pickupPoint')` where `deleted_at IS NULL` | tab=trip_details: shift_id, route_id, pickup_drop. Falls back to today's trips by route_id match. Uses driver route scoping for logged-in driver users. |

### 3.1 Cross-Tab Filter Sync

When tab=stop_details is active, TripMgmtController@index() executes a **trip ID pre-fetch** (lines 54–71):
- Queries `TptTrip::where('trip_date', $request->date)` with routeScheduler sub-filters (shift_id, route_id)
- Merges `trip_id` and `tripe_id` into request with the found trip's ID
- If no trip matches filters, both are set to null — preventing stale data display
- This means `stop_details` tab always shows data for the SINGLE trip matching date+shift+route filters, not all trips

| Filter | Effect on stop_details query |
|--------|------------------------------|
| date + shift + route | Finds exact trip, sets trip_id; stop details filtered by that trip |
| trip_id directly | Uses the provided trip_id from merged request |
| pickup_drop | Further filters by Pickup/Drop type |

---

## 4. Test Data Strategy

- `stopDetailsPrepare` auto-creates TptTripStopDetail records from PickupPointRoute for the trip's route
- Already existing stop details are skipped (checked by trip_id + stop_id + pickup_drop)
- `tripDetailsData` fetches a single stop detail by ID for frontend editing
- `tripDetailsUpdated` allows manual override of reaching_time, leaving_time, emergency_flag, emergency_remarks
- `stopAction` works on both existing TptTripStopDetail IDs AND pseudo-IDs (`new_{jntId}` format for in-memory stops)

---

## 5. Business Conditions

### 5.1 Database Schema (DDL — Migration: 2026_06_16_140624)

```sql
CREATE TABLE tpt_trip_stop_detail (
    id                   INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    pickup_drop          ENUM('Drop', 'Pickup') DEFAULT 'Pickup',
    ordinal              SMALLINT UNSIGNED DEFAULT 1,
    sch_arrival_time     DATETIME NULL,
    sch_departure_time   DATETIME NULL,
    reached_flag         TINYINT(1) DEFAULT 0,
    reaching_time        TIMESTAMP NULL,
    leaving_time         TIMESTAMP NULL,
    emergency_flag       TINYINT(1) DEFAULT 0,
    emergency_time       TIMESTAMP NULL,
    emergency_remarks    VARCHAR(512) NULL,
    created_at           TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at           TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    trip_id              INT UNSIGNED NOT NULL,
    stop_id              INT UNSIGNED NULL,
    updated_by           INT UNSIGNED NULL,
    deleted_at           TIMESTAMP NULL,
    -- FK constraints:
    CONSTRAINT fk_trip_stop_detail_trip FOREIGN KEY (trip_id) REFERENCES tpt_trip(id) ON DELETE CASCADE,
    CONSTRAINT fk_trip_stop_detail_stop FOREIGN KEY (stop_id) REFERENCES tpt_pickup_points(id) ON DELETE SET NULL,
    CONSTRAINT fk_trip_stop_detail_updated_by FOREIGN KEY (updated_by) REFERENCES tpt_personnel(id) ON DELETE SET NULL
);
```

### 5.2 Authorization (Permission Gates)

| BC ID | Permission | Method | Behavior | Source File:Line |
|-------|-----------|--------|----------|------------------|
| BC-AUTH-01 | tenant.stop-details.prepare | stopDetailsPrepare() | Without → 403 | TripController:468 |
| BC-AUTH-02 | tenant.stop-details.view | tripDetailsData() | Without → 403 | TripController:329 |
| BC-AUTH-03 | tenant.stop-details.update | tripDetailsUpdated() | Without → 403 | TripController:549 |
| BC-AUTH-04 | tenant.stop-details.update | stopAction() | Without → 403 | TripController:125 |
| BC-AUTH-05 | tenant.transport.viewAny | TripMgmtController@index() | Without → 403 | TripMgmtController:38 |

### 5.3 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | stopDetailsPrepare with valid trip_id | Creates all missing TptTripStopDetail records from route's PickupPointRoute; returns JSON with inserted/skipped counts |
| BC-BIZ-02 | stopDetailsPrepare — Skip Existing | Already-existing stop details are skipped (same trip_id + stop_id + pickup_drop) |
| BC-BIZ-03 | stopDetailsPrepare — Activity Log per stop | `activityLog($stop, 'Create', ['message' => 'Trip Details Create successfully.'])` for each inserted stop |
| BC-BIZ-04 | tripDetailsData with valid ID | Returns JSON `{status: true, message: 'Trip Data Get successfully', inserted: $tripDetails}` |
| BC-BIZ-05 | tripDetailsUpdated with valid ID | Updates reaching_time, leaving_time, emergency_flag, emergency_remarks; JSON `{status: true}` |
| BC-BIZ-06 | tripDetailsUpdated — Activity Log | `activityLog($stop, 'Updated', ['message' => 'Trip Details update successfully.'])` |
| BC-BIZ-07 | stopAction — reach | reaching_time set to now, reached_flag=1; TptNotificationLog created with ReachedStop/Delayed |
| BC-BIZ-08 | stopAction — leave | leaving_time set to now; TptNotificationLog created with ApproachingStop |
| BC-BIZ-09 | stopAction — emergency | emergency_flag=1, emergency_time=now, emergency_remarks set; TptTripIncidents created |
| BC-BIZ-10 | stopAction — start_trip | reached_flag=1, reaching_time=leaving_time=now; trip start_time/status updated; notification sent |
| BC-BIZ-11 | stopAction — end_trip | reached_flag=1, reaching_time=leaving_time=now; trip end_time/status=Completed updated |
| BC-BIZ-12 | stopAction — updated_by set from routeScheduler.driver_id | `updated_by` = `optional($trip->routeScheduler)->driver_id` |

### 5.4 Deep-Dive Business Condition Analysis (BC-BIZ-DEEP)

| BC-DEEP ID | Condition | Code Path Analysis | Edge Case / Gap |
|------------|-----------|--------------------|-----------------|
| BC-BIZ-DEEP-01 | stopDetailsPrepare — trip_id fallback (`$request->trip_id ?? $request->tripe_id`) | TripController:470 — accepts two param names for flexibility. Then `empty()` check at 472 returns 400 if both null | `empty()` considers `0` and `'0'` as empty. If trip_id=0 is somehow passed → returns 400 incorrectly instead of 404 |
| BC-BIZ-DEEP-02 | stopDetailsPrepare — manual 400 response not using `$request->validate()` | TripController:472-477 uses `empty()` + manual `response()->json([...], 400)` — no FormRequest, no `$request->validate()`. Inconsistent with rest of app. | Gap: no validation rule for trip_id type (expects integer, but any string passes `empty()` check) |
| BC-BIZ-DEEP-03 | stopDetailsPrepare — shift_id filtering on PickupPointRoute query | TripController:491 — `->where('shift_id', $trip->routeScheduler?->shift_id)` uses optional. If `routeScheduler` is null → null passed to where → no shift filter applied → ALL route stops prepared instead of shift-specific | **Gap:** Null routeScheduler silently ignored |
| BC-BIZ-DEEP-04 | stopDetailsPrepare — DB::beginTransaction() without try/catch rollback | TripController:487 `DB::beginTransaction()`, 536 `DB::commit()`. If any exception occurs between them (e.g., DB error, activityLog failure), transaction is never rolled back | **Gap: No rollback on failure.** Leaves partial data. |
| BC-BIZ-DEEP-05 | stopDetailsPrepare — activityLog on $stop BEFORE create | TripController:519 — `activityLog($stop, 'Create', [...])` passes `$stop` which is a `PickupPointRoute` model (the loop variable from line 497 `foreach ($routeStops as $stop)`). The newly created `TptTripStopDetail` at line 524 is NOT logged | **Gap: Wrong model type in activity log.** The log references PickupPointRoute, not TptTripStopDetail. |
| BC-BIZ-DEEP-06 | stopDetailsPrepare — activityLog call order vs create | TripController:519 activityLog, THEN 524 TptTripStopDetail::create(). Activity log captures state BEFORE the record exists | **Gap: activityLog references object that hasn't been created yet.** Logged object has no ID in DB. |
| BC-BIZ-DEEP-07 | tripDetailsUpdated — activityLog BEFORE update | TripController:556-558 activityLog, THEN 560-565 $stop->update(). Changes captured in log are the OLD values, not new values | **Gap: Stale log.** Should call activityLog AFTER update with getChanges(). |
| BC-BIZ-DEEP-08 | tripDetailsUpdated — no validation on request fields | TripController:560-565 passes request fields directly to fill without validation. `emergency_flag` could be 'abc', reaching_time could be 'invalid' | **Gap: No format/type validation.** Potentially corrupts data. |
| BC-BIZ-DEEP-09 | stopAction — TptNotificationLog $fillable = [] | `TptNotificationLog` model (line 18) has `protected $fillable = []`. All `::create()` calls in stopAction will throw `MassAssignmentException` because no attributes are mass-assignable | **CRITICAL BUG: All notification logs silently fail.** |
| BC-BIZ-DEEP-10 | stopAction — TptTripIncidents `severity` hardcoded as 'MEDIUM' | TripController:293 — `'severity' => 'MEDIUM'` always set regardless of emergency context. The policy has `severity` const with all three values but only MEDIUM is ever used | **Minor: No dynamic severity logic.** All incidents get MEDIUM. |
| BC-BIZ-DEEP-11 | stopAction — updated_by type mismatch (DriverHelper vs tpt_personnel) | Model `TptTripStopDetail:54`: `updatedBy()` belongsTo `DriverHelper`. Migration FK (line 35): `references('id')->on('tpt_personnel')`. Controller sets `$updatedBy = $trip->routeScheduler->driver_id` which is a DriverHelper ID. | **FK reference mismatch:** code sets driver_id (DriverHelper PK), FK expects tpt_personnel.id. Two different tables. |
| BC-BIZ-DEEP-12 | stopAction — start_trip extra data injection | TripController:198 — `$request->filled('extra')` checks if extra JSON payload present. Uses `$request->extra['start_time']` array access without null guard on the key | **Gap: potential undefined array key warning** if `extra` is present but `start_time` key missing |
| BC-BIZ-DEEP-13 | stopAction — end_trip extra data injection | Same pattern as start_trip (line 264). `$request->extra['end_time']` without null guard | Same gap as DEEP-12 |
| BC-BIZ-DEEP-14 | stopAction — delayed detection threshold | TripController:227 — delay is >5 min after sch_arrival_time. Uses `$now->gt(Carbon::parse($stop->sch_arrival_time)->addMinutes(5))` | **Minor:** `sch_arrival_time` is cast as datetime. If null, Carbon::parse(null) returns now → delayed never triggers when arrival is null |
| BC-BIZ-DEEP-15 | stopAction — no DB transaction for atomicity | Multiple related writes (stop update, notification log, trip update, incident creation) in one request without wrapping in `DB::transaction()` | **Gap: Partial writes on failure.** If notification log fails (MassAssignmentException), the stop update still persists |
| BC-BIZ-DEEP-16 | stopAction — raised_by uses driver_id too | TripController:185 — `$raisedBy = optional($trip->routeScheduler)->driver_id`. Same value as updatedBy. `TptTripIncidents.raised_by` FK references User ID but driver_id is DriverHelper ID | **Data integrity gap:** Wrong FK target for raised_by |
| BC-BIZ-DEEP-17 | stopAction — emergency notification NOT created | BC-BIZ-09 handles reach/leave notification logs. For emergency action, TripController:285-294 creates TptTripIncidents but creates NO TptNotificationLog for the emergency | **Gap: No emergency notification sent.** Only incident record created. |
| BC-BIZ-DEEP-18 | stopDetailsPrepare — deleted_at check not performed | The `$exists` check on line 500-503 queries `TptTripStopDetail::where(...)->exists()`. Since the model uses `SoftDeletes`, this INCLUDES soft-deleted records. Prepared stops match trashed records → incorrectly skipped | **Bug: Soft-deleted records match as "existing".** |
| BC-BIZ-DEEP-19 | stopDetailsPrepare — routeStops without pickuppoint relationship | Line 489 uses `->with('pickupPoint')` but only uses it for `$stop->pickupPoint->name` in blade. If pickupPoint is null (deleted), the stop still gets created with `stop_id=$stop->pickup_point_id` which references a deleted PickupPoint | **Potential FK violation:** stop_id FK has ON DELETE SET NULL, but code inserts the original ID. If pickupPoint is deleted, stop_id becomes orphaned reference. |
| BC-BIZ-DEEP-20 | tripStopNew() — no eager loading for security | TripMgmtController:206 — `TptTripStopDetail::with('stop')->orderBy('id')`. No `whereHas` for tenant scoping. If user has permission, they can see ALL stops across all trips | **Security gap: No tenant isolation.** All stops across tenants could be visible if permissions overlap. |

### 5.5 Authorization (Permission Gaps from Blade)

| BC-AUTH-GAP ID | Blade File:Line | @can String Used | Defined in permissionslist.php? | Effect |
|----------------|-----------------|-------------------|-------------------------------|--------|
| BC-AUTH-GAP-01 | `details-list.blade.php:70` | `tenant.stop-details.prepare.create` | **NO** — only `tenant.stop-details.prepare` exists | `@can` ALWAYS evaluates false → Add button always hidden |
| BC-AUTH-GAP-02 | `details-list.blade.php:98` | `tenant.stop-details.prepare.edit` | **NO** — only `tenant.stop-details.prepare` exists | `@can` ALWAYS evaluates false → Action column header always hidden |
| BC-AUTH-GAP-03 | `details-list.blade.php:119` | `tenant.stop-details.prepare.edit` | **NO** | Edit buttons ALWAYS hidden — users cannot edit any stop details |
| BC-AUTH-GAP-04 | `tripmanagement.blade.php:16` | `tenant.stop-details.prepare` (tab visibility) | YES — `'stop-details.prepare' => $crud` | tab nav-tab entry uses `tenant.stop-details.prepare`, which EXISTS in permissionslist.php as a group → grants all CRUD actions under that group. Actually works but grants broader access than intended |

---

## 6. Test Case List

### 6.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | Stop Details Tab Shows Existing Records | `/transport/trip-management?tab=stop_details` with trip_id filter → stop detail grid rows | — | — | ⬜ |
| TC-P02 | Prepare Stop Details (first time) | GET `/stop/details/prepare?trip_id=X` → all route stops created as TptTripStopDetail | — | — | ⬜ |
| TC-P03 | Prepare Stop Details (re-run — no new stops) | GET same URL → inserted=0, skipped=N | — | — | ⬜ |
| TC-P04 | Fetch Single Stop Detail Data | GET `/trip/details/edits?id=X` → JSON with stop detail fields | — | — | ⬜ |
| TC-P05 | Update Stop Detail Times | POST `/trip/details/updates` with id, reaching_time, leaving_time → fields updated; JSON success | — | — | ⬜ |
| TC-P06 | Update Stop Detail Emergency Flag | POST with emergency_flag=1, emergency_remarks="Late" → fields updated | — | — | ⬜ |
| TC-P07 | Filter Stop Details by Trip ID | Select trip from dropdown → matching stop details shown | — | — | ⬜ |
| TC-P08 | Filter Stop Details by Date + Route | Date + route filters → stop details via trip relationship | — | — | ⬜ |
| TC-P09 | Filter by Pickup/Drop | Select pickup→ only pickup stops; Drop→ only drop stops | — | — | ⬜ |
| TC-P10 | Stop Action — Reach | POST `/trip/stop-action` with action=reach, id=X → reaching_time set, reached_flag=1, notification logged | — | — | ⬜ |
| TC-P11 | Stop Action — Leave | POST `/trip/stop-action` with action=leave, id=X → leaving_time set, notification logged | — | — | ⬜ |
| TC-P12 | Stop Action — Emergency | POST with action=emergency, id=X, remark="Late" → emergency_flag=1, emergency_remarks set, TptTripIncidents created | — | — | ⬜ |
| TC-P13 | Stop Action — Start Trip (first stop) | POST with action=start_trip, id=X → reached_flag=1, reaching_time=leaving_time=now, trip start_time set | — | — | ⬜ |
| TC-P14 | Stop Action — End Trip (last stop) | POST with action=end_trip, id=X → reached_flag=1, reaching_time=leaving_time=now, trip status=Completed | — | — | ⬜ |
| TC-P15 | Stop Action with New (unsaved) Stop ID | POST with id=new_5 (jntId format) → auto-creates TptTripStopDetail + applies action | — | — | ⬜ |
| TC-P16 | Stop Status Timeline Filters by Shift + Route | Select shift+route → filtered stop timeline shown | — | — | ⬜ |
| TC-P17 | Prepare Stop Details via tripe_id param | GET with tripe_id=X instead of trip_id=X → works same as trip_id | — | — | ⬜ |
| TC-P18 | Stop Details Tab Cross-Tab Filter Sync | Tab=stop_details with date+shift+route → trip_id locked to matched trip | — | — | ⬜ |

### 6.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | Prepare Stop Details Without trip_id | 400 JSON "Trip ID is required" | — | — | ⬜ |
| TC-N02 | Prepare Stop Details For Non-Existent Trip | 404 JSON "Trip not found" | — | — | ⬜ |
| TC-N03 | Fetch Stop Detail With Invalid ID | GET `/trip/details/edits?id=99999` → first() returns null → JSON with null data | — | — | ⬜ |
| TC-N04 | Update Stop Detail With Invalid ID | POST with id=99999 → find() returns null → 404 JSON "Stop Detail not found." | — | — | ⬜ |
| TC-N05 | Permission 403 — Without stop-details.prepare | 403 on stopDetailsPrepare | — | — | ⬜ |
| TC-N06 | Permission 403 — Without stop-details.view | 403 on tripDetailsData | — | — | ⬜ |
| TC-N07 | Permission 403 — Without stop-details.update | 403 on tripDetailsUpdated | — | — | ⬜ |
| TC-N08 | Guest Access | All URLs redirect to `/login` | — | — | ⬜ |
| TC-N09 | Stop Action With Invalid ID | POST with id=99999 → 404 JSON "Stop Detail not found." | — | — | ⬜ |
| TC-N10 | Permission 403 — Without stop-details.update on stopAction | 403 on stopAction | — | — | ⬜ |
| TC-N11 | Prepare Stop Details with trip_id=0 | `empty(0)` → 400 JSON incorrectly | — | — | ⬜ |
| TC-N12 | Stop Action with invalid action string | POST with action=invalid → switch hits no case → returns success JSON without any writes | — | — | ⬜ |
| TC-N13 | Stop Action without id parameter | Missing id → `$request->id` is null → `find(null)` → 404 "Stop Detail not found." | — | — | ⬜ |
| TC-N14 | tripDetailsUpdated with empty reaching_time | No validation → empty string saved to datetime column → DB error or null | — | — | ⬜ |
| TC-N15 | Stop Details Tab with no trip matched | date+shift+route with no matching trip → trip_id=null → empty grid | — | — | ⬜ |

### 6.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|----------------|---------|---------|--------|
| TC-D01 | A | Prepare in Wrong Order — no PickupPointRoute exists for route | 0 records inserted; JSON `{inserted: 0, skipped: 0}` | — | — | ⬜ |
| TC-D02 | B | Trip Deletion — Stop Details Manual Delete | `TptTripStopDetail::where('trip_id', $trip->id)->delete()` in TripController::destroy() — not FK CASCADE | — | — | ⬜ |
| TC-D03 | C | Updated_by relationship to DriverHelper | When stop is updated via stopAction, updated_by is set to driver_id from routeScheduler | — | — | ⬜ |
| TC-D04 | D | RouteScheduler with null shift_id in prepare | shift_id=null → where('shift_id', null) → no shift filter → all route stops prepared | — | — | ⬜ |
| TC-D05 | E | Soft-deleted stop detail matched as existing | Delete a stop detail, re-prepare → skipped because exists() picks up soft-deleted row | — | — | ⬜ |

### 6.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|-----------------|---------|---------|--------|
| TC-CR01 | CR | P1 | Controller — Gate::authorize() Before Each Method | All 3 methods have Gate as first line | — | — | ◌ |
| TC-CR02 | CR | P1 | Controller — activityLog on stopDetailsPrepare Per Stop | Logged inside loop for each inserted record | — | — | ◌ |
| TC-CR03 | CR | P1 | Controller — activityLog on tripDetailsUpdated | `activityLog($stop, 'Updated', ['message' => 'Trip Details update successfully.'])` | — | — | ◌ |
| TC-CR04 | CR | P1 | Controller — No activityLog on tripDetailsData | Read-only fetch, no log expected | — | — | ◌ |
| TC-CR05 | CR | P1 | Controller — DB::beginTransaction/commit on stopDetailsPrepare | Uses `DB::beginTransaction()` + `DB::commit()` (NOT `DB::transaction()` closure). Missing rollback on exception — gap. | — | — | ◌ |
| TC-CR06 | CR | P1 | Controller — Skip logic for existing stop details | Check: where trip_id, stop_id, pickup_drop → exists() | — | — | ◌ |
| TC-CR07 | CR | P1 | Controller — Trip existence check (tripe_id fallback) | `$tripId = $request->trip_id ?? $request->tripe_id` — handles both param names. Followed by `if (empty($tripId))` manual check returning 400 | — | — | ◌ |
| TC-CR08 | CR | P1 | Model — TptTripStopDetail fillable/casts | See Status TCList section 6.4 | — | — | ◌ |
| TC-CR09 | CR | P1 | Routes — All 3 stop-details routes defined | prepare, edits, updates all present | — | — | ◌ |
| TC-CR10 | CR | P1 | DDL — FK Constraints | trip_id CASCADE, stop_id SET NULL, updated_by SET NULL | — | — | ◌ |
| TC-CR11 | CR | P1 | Gap — stopDetailsPrepare uses manual empty() check instead of `$request->validate()` | Uses `if (empty($tripId))` returning 400 JSON — no FormRequest or `$request->validate()` call | — | — | ◌ |
| TC-CR12 | CR | P1 | Gap — tripDetailsUpdated no validation on request fields | No validation for reaching_time, leaving_time formats; emergency_flag not validated as boolean | — | — | ◌ |
| TC-CR13 | CR | P1 | Gap — stopAction has no activityLog | stopAction() performs DB writes (reach/leave/emergency) but does NOT call `activityLog()` | — | — | ◌ |
| TC-CR14 | CR | P1 | Gap — Policy defines delete/restore/forceDelete but no controller endpoints | `TransportStopDetailsPolicy` defines `delete`, `restore`, `forceDelete` (permissions exist) but no controller method uses them. Stop deletion only happens via trip's destroy. | — | — | ◌ |
| TC-CR15 | CR | P1 | Gap — Blade uses `tenant.stop-details.prepare.create` / `.edit` not defined in policy | `details-list.blade.php` lines 70, 98, 119 use these strings but policy only has `prepare`. These `@can` checks always fail | — | — | ◌ |
| TC-CR16 | CR | P1 | Gap — stopAction — TptNotificationLog $fillable empty array | `TptNotificationLog` model line 18 `protected $fillable = []` → all `::create()` calls throw MassAssignmentException | — | — | ◌ |
| TC-CR17 | CR | P1 | Gap — stopDetailsPrepare activityLog logs wrong model type | Line 519 passes `$stop` (PickupPointRoute) instead of newly created TptTripStopDetail | — | — | ◌ |
| TC-CR18 | CR | P1 | Gap — tripDetailsUpdated activityLog called before update | Line 556-558 activityLog BEFORE line 560-565 update → captures old state, not changes | — | — | ◌ |
| TC-CR19 | CR | P2 | Gap — stopAction updated_by references DriverHelper but FK points to tpt_personnel | Model belongsTo DriverHelper, FK references tpt_personnel.id — mismatch | — | — | ◌ |
| TC-CR20 | CR | P2 | Gap — No DB transaction in stopAction for atomicity | stopAction makes multiple DB writes without wrapping in DB::transaction() | — | — | ◌ |
| TC-CR21 | CR | P2 | Gap — Soft-deleted records counted as existing in prepare | `exists()` query does not exclude deleted records (SoftDeletes with global scope) | — | — | ◌ |
| TC-CR22 | CR | P2 | Gap — bulkUpdateTime calls DB::rollBack() without beginTransaction | Line 626 `DB::rollBack()` — no matching `DB::beginTransaction()`. Rollback does nothing. | — | — | ◌ |
| TC-CR23 | CR | P2 | Gap — toggleStatus route exists but method missing in TripController | Route line 160 `Route::post('/trip/{trip}/toggle-status'...` registered but TripController has NO toggleStatus method | — | — | ◌ |
| TC-CR24 | CR | P2 | Gap — stopAction — no emergency notification sent | Emergency action creates TptTripIncidents but no TptNotificationLog for emergency alert | — | — | ◌ |
| TC-CR25 | CR | P2 | Gap — stopAction — raised_by type mismatch | TripController:291 sets raised_by = driver_id (DriverHelper) but FK references users.id | — | — | ◌ |
| TC-CR26 | CR | P2 | Gap — TransportStopDetailsPolicy prepare() expects model but never called | Policy method `prepare(User $user, TptTripStopDetail $stopDetail)` expects model instance. Controller uses string gate `Gate::authorize('tenant.stop-details.prepare')` — never calls policy | — | — | ◌ |
| TC-CR27 | CR | P2 | Gap — No tenant isolation on tripStopNew query | TripMgmtController:206 — raw `TptTripStopDetail::with('stop')` without tenant scoping | — | — | ◌ |
| TC-CR28 | CR | P3 | Gap — stopAction missing default in switch | No `default:` case in switch($request->action). Unknown action falls through without error or response | — | — | ◌ |

---

## 7. Detailed Test Steps

### TC-P01: Stop Details Tab Shows Existing Records

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user with `tenant.stop-details.prepare` permission | Authenticated |
| 2 | Navigate to `/transport/trip-management?tab=stop_details&date=YYYY-MM-DD&shift_id=X&route_id=Y` | Page loads with stop_details tab active |
| 3 | Verify grid table renders with columns: #, Stop, Sch Arr, Sch Dep, Actual Arr, Actual Dep, Emergency, Remark, Action | All columns present |
| 4 | Verify each row shows stop name from relationship `$row->stop->name` | Stop names displayed |
| 5 | Verify pagination works if >10 records | Pagination links shown |

### TC-P02: Prepare Stop Details (First Time)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure trip_id=X exists with route_id=Y | Trip with route exists |
| 2 | Ensure 5 PickupPointRoute records for route Y | 5 stop definitions |
| 3 | GET `/stop/details/prepare?trip_id=X` | JSON: `{status: true, inserted: 5, skipped: 0}` |
| 4 | DB check: `SELECT * FROM tpt_trip_stop_detail WHERE trip_id=X` | 5 records; ordinals 1-5; sch_arrival_time and sch_departure_time converted from minutes to H:i:s |
| 5 | Activity log check | 5 activity log entries with 'Trip Details Create successfully.' |
| 6 | Verify each activity log's subject_type is `Modules\Transport\Models\PickupPointRoute` (WRONG — should be TptTripStopDetail) | Gap confirmed: wrong model type logged |

### TC-P03: Prepare Stop Details (Re-run — No New Stops)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure trip_id=X already has 5 stop details prepared | Existing records |
| 2 | GET `/stop/details/prepare?trip_id=X` | JSON: `{status: true, inserted: 0, skipped: 5}` |
| 3 | DB check: no duplicate records created | Still exactly 5 records |

### TC-P04: Fetch Single Stop Detail Data

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure stop_detail_id=X exists | Record exists |
| 2 | GET `/trip/details/edits?id=X` | JSON: `{status: true, message: 'Trip Data Get successfully', inserted: {...stopDetailData...}}` |
| 3 | Verify fields | reaching_time, leaving_time, emergency_flag, emergency_remarks included |
| 4 | If stop_detail doesn't exist | JSON: `{status: true, message: 'Trip Data Get successfully', inserted: null}` — **API returns success even when no data found** (uses `first()` not `findOrFail()`) |

### TC-P05: Update Stop Detail Times

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure stop_detail_id=X exists | Record exists |
| 2 | POST `/trip/details/updates` with `id=X, reaching_time=09:30, leaving_time=09:35` | JSON `{status: true}` |
| 3 | DB check: reaching_time='09:30:00', leaving_time='09:35:00' | Fields updated |
| 4 | Activity log check: message 'Trip Details update successfully.' | Logged before update — captures old values |

### TC-P06: Update Stop Detail Emergency Flag

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure stop_detail_id=X exists | Record exists |
| 2 | POST `/trip/details/updates` with `id=X, emergency_flag=1, emergency_remarks="Late"` | JSON success |
| 3 | DB check: emergency_flag=1, emergency_remarks="Late" | Fields updated |

### TC-P07: Filter Stop Details by Trip ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure Trip X exists with 3 stop details and Trip Y with 5 stop details | Two trips with stops |
| 2 | Navigate to `/transport/trip-management?tab=stop_details&trip_id=X` | Only Trip X's 3 stops shown |
| 3 | Change trip_id param to Y | Trip Y's 5 stops shown |

### TC-P08: Filter Stop Details by Date + Route

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure trips exist on different dates and routes | Data prepared |
| 2 | Navigate to tab=stop_details with date and route_id but no trip_id | System finds matching trip via TripMgmtController@index lines 54-64, sets trip_id automatically |
| 3 | Verify grid shows only that trip's stop details | Filtered correctly |

### TC-P09: Filter by Pickup/Drop

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure trip has both Pickup and Drop stops | Mixed stop types |
| 2 | Navigate to tab=stop_details with pickup_drop=Pickup | Only Pickup stops shown |
| 3 | Navigate with pickup_drop=Drop | Only Drop stops shown |

### TC-P10: Stop Action — Reach

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure stop_detail_id=X exists with reached_flag=0 | Record ready for reach |
| 2 | POST `/trip/stop-action` with `id=X, action=reach` | JSON `{status: true, message: "Stop updated successfully"}` |
| 3 | DB check: `reached_flag=1, reaching_time` set to now | Fields updated |
| 4 | DB check: `tpt_notification_log` has entry for this trip/stop with notification_type=ReachedStop | Notification created (NOTE: may silently fail — see TC-CR16) |

### TC-P11: Stop Action — Leave

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure stop_detail_id=X has reached_flag=1, leaving_time=null | Record ready for leave |
| 2 | POST `/trip/stop-action` with `id=X, action=leave` | JSON success |
| 3 | DB check: `leaving_time` set to now | Field updated |
| 4 | DB check: notification_log with ApproachingStop | Notification created |

### TC-P12: Stop Action — Emergency

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure stop_detail_id=X exists | Record exists |
| 2 | POST `/trip/stop-action` with `id=X, action=emergency, remark="Late arrival"` | JSON success |
| 3 | DB check: emergency_flag=1, emergency_time=now, emergency_remarks="Late arrival" | Fields updated |
| 4 | DB check: `tpt_trip_incidents` created with incident_type=0, severity=MEDIUM | Incident record created |
| 5 | DB check: NO notification_log for emergency | Gap confirmed — no notification sent for emergency |

### TC-P13: Stop Action — Start Trip (First Stop)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure stop_detail_id=X is first stop (ordinal=1) with reached_flag=0 | First stop ready |
| 2 | POST `/trip/stop-action` with `id=X, action=start_trip` | JSON success |
| 3 | DB check: reached_flag=1, reaching_time=now, leaving_time=now | Stop marked as reached AND left simultaneously |
| 4 | DB check: trip.start_time set to now, trip.status='Ongoing' | Trip started |
| 5 | DB check: notification_log with TripStart | Notification created |

### TC-P14: Stop Action — End Trip (Last Stop)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure stop_detail_id=X is last stop (ordinal=max) with reached_flag=0 | Last stop ready |
| 2 | POST `/trip/stop-action` with `id=X, action=end_trip` | JSON success |
| 3 | DB check: reached_flag=1, reaching_time=now, leaving_time=now | Stop marked completed |
| 4 | DB check: trip.end_time set to now, trip.status='Completed' | Trip ended |

### TC-P15: Stop Action with New (Unsaved) Stop ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure PickupPointRoute jnt_id=5 exists | Junction record exists |
| 2 | POST `/trip/stop-action` with `id=new_5, action=reach` | JSON success |
| 3 | DB check: New TptTripStopDetail created from junction data | Auto-created |
| 4 | DB check: reached_flag=1 on the new record | Action applied |

### TC-P16: Stop Status Timeline Filters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to tab=stop_status with shift_id=X&route_id=Y | Timeline loads |
| 2 | Verify action buttons appear only when both shift_id and route_id are selected | Per blade:114 condition |
| 3 | Verify each stop shows: ordinal, stop name, pickup/drop badge, sch/actual times | All stop cards render |
| 4 | Verify first stop shows "Start Trip" button, last shows "End Trip", middle shows "Reached"/"Leave"/"Emergency" | Correct buttons per position |

### TC-P17: Prepare via tripe_id Params

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | GET `/stop/details/prepare?tripe_id=X` instead of trip_id | Same behavior as trip_id param |
| 2 | Verify JSON response matches TC-P02 | Inserted count correct |

### TC-P18: Cross-Tab Filter Sync

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to tab=stop_details with date=2026-07-22&shift_id=1&route_id=2 | TripMgmtController resolves trip_id to matching trip |
| 2 | Verify trip_id input field in filter bar shows the resolved trip ID | Readonly trip_id shown |
| 3 | Verify grid shows only stops for the matched trip | Correct data |

### TC-N01: Prepare Without trip_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | GET `/stop/details/prepare` (no trip_id) | 400 JSON `{status: false, message: "Trip ID is required"}` |

### TC-N02: Prepare For Non-Existent Trip

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | GET `/stop/details/prepare?trip_id=99999` (non-existent) | 404 JSON `{status: false, message: "Trip not found"}` |

### TC-N03: Fetch Detail With Invalid ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | GET `/trip/details/edits?id=99999` | JSON `{status: true, message: "Trip Data Get successfully", inserted: null}` — returns success with null data |
| 2 | **Note:** This is a design issue — returns 200 with null instead of 404. Consider whether this is acceptable. | |

### TC-N04: Update With Invalid ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST `/trip/details/updates` with id=99999 | 404 JSON `{status: false, message: "Stop Detail not found."}` |

### TC-N05: Permission 403 — Without stop-details.prepare

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user without `tenant.stop-details.prepare` | Authenticated |
| 2 | GET `/stop/details/prepare?trip_id=1` | 403 Forbidden |

### TC-N06: Permission 403 — Without stop-details.view

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user without `tenant.stop-details.view` | Authenticated |
| 2 | GET `/trip/details/edits?id=1` | 403 Forbidden |

### TC-N07: Permission 403 — Without stop-details.update

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user without `tenant.stop-details.update` | Authenticated |
| 2 | POST `/trip/details/updates` with valid id | 403 Forbidden |

### TC-N08: Guest Access

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Logout (guest session) | Not authenticated |
| 2 | GET `/stop/details/prepare?trip_id=1` | Redirect to `/login` |
| 3 | GET `/trip/details/edits?id=1` | Redirect to `/login` |
| 4 | POST `/trip/details/updates` | Redirect to `/login` |
| 5 | POST `/trip/stop-action` | Redirect to `/login` |

### TC-N09: Stop Action With Invalid ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST `/trip/stop-action` with id=99999 | 404 JSON `{status: false, message: "Stop Detail not found."}` |

### TC-N10: Permission 403 — stopAction Without stop-details.update

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user without `tenant.stop-details.update` | Authenticated |
| 2 | POST `/trip/stop-action` with valid id | 403 Forbidden |

### TC-N11: Prepare with trip_id=0

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | GET `/stop/details/prepare?trip_id=0` | 400 JSON — `empty(0)` evaluates to true in PHP |
| 2 | **Bug:** trip_id=0 is incorrectly rejected as empty | |

### TC-N12: Stop Action with Invalid Action

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST `/trip/stop-action` with action=invalid | switch hits no case → returns `{status: true, message: "Stop updated successfully"}` with NO writes |
| 2 | DB check: No changes to stop or trip | Nothing modified |
| 3 | **Bug:** False positive success response for invalid action | |

### TC-N13: Stop Action Without ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST `/trip/stop-action` with no id parameter | `$request->id` is null → `find(null)` returns null → 404 JSON |

### TC-N14: tripDetailsUpdated With Empty Fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST `/trip/details/updates` with id=X, reaching_time='' | Empty string saved to datetime column → DB silently converts to NULL or throws error depending on DB mode |
| 2 | **Gap:** No validation prevents empty/falsy values | |

### TC-N15: No Trip Matched in Tab

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to tab=stop_details with date that has no trips | trip_id set to null in request merge |
| 2 | Grid shows empty table with "No data found" | Empty state rendered |

### TC-P18: Cross-Tab Filter Sync (Detailed)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure Trip A exists on date=2026-07-22 with shift_id=1, route_id=2 | Trip exists |
| 2 | Ensure Trip B exists on same date with shift_id=3, route_id=4 | Trip B exists, different shift/route |
| 3 | Navigate to tab=stop_details with date=2026-07-22&shift_id=1&route_id=2 | TripMgmtController lines 54-71 resolve trip_id to Trip A's ID |
| 4 | Verify readonly trip_id input shows Trip A's ID | Correct trip ID shown |
| 5 | Verify grid shows only Trip A's stops | Trip B's stops NOT shown |
| 6 | Change filters to date=2026-07-22&shift_id=3&route_id=4 & submit | Trip ID syncs to Trip B |
| 7 | Grid now shows Trip B's stops | Correct |

### TC-P03: Prepare Re-Run (Detailed Edge Cases)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure trip_id=X has 5 stop details. Manually delete 1 via soft delete. | 4 visible + 1 soft-deleted |
| 2 | GET `/stop/details/prepare?trip_id=X` | JSON `{inserted: 0, skipped: 5}` — **BUG: soft-deleted record counted as existing** |
| 3 | Verify via DB: `SELECT * FROM tpt_trip_stop_detail WHERE trip_id=X` | 5 records total (including deleted) |
| 4 | Check if the non-deleted 4 records still exist | Yes, all 5 still exist |
| 5 | **Expected (correct behavior):** inserted=1, skipped=4 | The soft-deleted record should be re-creatable |

### TC-P07: Filter Stop Details by Trip ID (Detailed)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Trip X with 3 Pickup stop details, Trip Y with 5 Drop stop details | Test data ready |
| 2 | Navigate: `/transport/trip-management?tab=stop_details&trip_id=X` | tripStopNew where trip_id=X |
| 3 | Grid shows 3 rows, all with stop details belonging to Trip X | Correct |
| 4 | Verify pickup_drop column shows "Pickup" for Trip X's stops | Depending on route definition |
| 5 | Change URL to `trip_id=Y` | tripStopNew where trip_id=Y |
| 6 | Grid shows 5 rows, all belonging to Trip Y | Correct |

### TC-P08: Filter by Date + Route (Detailed)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure Trip X on date=D1, route=R1. Trip Z on date=D1, route=R2. | Two trips same date diff routes |
| 2 | Navigate: tab=stop_details with date=D1&route_id=R1 | Index lines 54-63: finds Trip X by date + routeScheduler.route_id |
| 3 | trip_id resolved to Trip X's ID | Merged into request |
| 4 | tripStopNew filters by that trip_id | Only Trip X's stops shown |
| 5 | Verify Trip Z's stops are NOT in the grid | Correct |

### TC-P09: Filter by Pickup/Drop (Detailed)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure trip has mix of Pickup and Drop stops via PickupPointRoute definitions | 3 Pickup + 2 Drop |
| 2 | Navigate: tab=stop_details with trip_id=X&pickup_drop=Pickup | tripStopNew line 226: where pickup_drop='Pickup' |
| 3 | Grid shows 3 rows, all with pickup_drop='Pickup' | Only pickup stops |
| 4 | Change to pickup_drop=Drop | Grid shows 2 rows with pickup_drop='Drop' |

### TC-P05: Update Stop Detail Times (Detailed Edge Cases)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure stop_detail_id=X with reaching_time=null, leaving_time=null | Clean record |
| 2 | POST: id=X, reaching_time=09:30, leaving_time=09:35 | JSON `{status: true}` |
| 3 | DB: reaching_time='09:30:00', leaving_time='09:35:00' | Updated |
| 4 | POST: id=X, reaching_time=invalid (garbage text) | **BUG: No validation** → DB error or silently stores null |
| 5 | POST: id=X, reaching_time=25:00 (invalid time) | **BUG: No validation** → DB error on invalid time format |
| 6 | POST: id=X, emergency_flag=abc (non-boolean) | **BUG: No boolean validation** → string stored in boolean field |
| 7 | Reaching time set to a past value | Allowed (no validation constraints on time ordering) |

### TC-P06: Update Emergency Flag (Detailed)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST: id=X, emergency_flag=1, emergency_remarks="Vehicle arrived late" | JSON success |
| 2 | DB: emergency_flag=1, emergency_remarks="Vehicle arrived late" | Updated |
| 3 | POST: id=X, emergency_flag=0, emergency_remarks="" | Flag cleared, remarks cleared |
| 4 | DB: emergency_flag=0, emergency_remarks="" | Updated again |

### TC-P13: Start Trip with Extra Data (Detailed)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST: id=X, action=start_trip | JSON success, reached_flag=1, reaching/leaving both now |
| 2 | POST: id=X, action=start_trip, extra={start_time:"2026-07-22T08:00", start_odometer:12345, start_fuel:50} | Trip updated with start fields |
| 3 | DB trip check: start_time=2026-07-22 08:00, start_odometer=12345, start_fuel=50, status='Ongoing' | All fields set |
| 4 | POST: id=X, action=start_trip, extra={} (empty but present) | **BUG:** Line 198 `$request->filled('extra')` is true for empty object. Line 200 `$request->extra['start_time']` → undefined array key warning. Use `isset()` check. |

### TC-P14: End Trip with Extra Data (Detailed)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST: id=X, action=end_trip | JSON success |
| 2 | DB check: reached_flag=1, reaching_time=now, leaving_time=now | Stop completed |
| 3 | POST: id=X, action=end_trip, extra={end_time:"2026-07-22T09:00", end_odometer:12600, end_fuel:48} | Trip updated with end fields |
| 4 | DB trip check: end_time set, end_odometer=12600, end_fuel=48, status='Completed' | Trip completed |

### TC-P15: New Stop Action (Detailed)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure PickupPointRoute jnt_id=5 exists for route R, shift S | Junction record active |
| 2 | Ensure trip exists for today with route_id=R | Today's trip present |
| 3 | POST: id=new_5, action=reach | JSON success |
| 4 | DB: New TptTripStopDetail created with trip_id matched, stop_id=jnt.pickup_point_id | Auto-created from junction data |
| 5 | DB: reached_flag=1, reaching_time set on the new record | Action applied to new record |
| 6 | POST same request again: id=new_5, action=reach | Finds existing record (line 157-161) → updates it, no duplicate |

### TC-P16: Stop Status Timeline (Detailed)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to tab=stop_status without shift_id or route_id | Timeline loads but NO action buttons shown (line 114 condition) |
| 2 | Select a shift_id and route_id, submit | Action buttons appear |
| 3 | Verify first stop in timeline shows "Start Trip" button | Correct per blade lines 117-125 |
| 4 | Verify last stop shows "End Trip" button | Correct per blade lines 127-135 |
| 5 | Verify middle stops show "Reached" / "Leave" / "Emergency" buttons | Correct per blade lines 137-164 |
| 6 | Click "Reached" on a stop | stopAction called, stop marked reached |
| 7 | After reached, verify "Attendance" link appears and "Reached" button disappears | Blade lines 149-163 logic |
| 8 | After reached, verify "Leave" button becomes active | Correct |

### TC-D04: RouteScheduler Null shift_id (Detailed)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create trip with routeScheduler that has shift_id=NULL | Trip exists |
| 2 | GET `/stop/details/prepare?trip_id=X` | stopDetailsPrepare line 491: `$trip->routeScheduler?->shift_id` = null |
| 3 | PickupPointRoute query: `->where('shift_id', null)` → where NULL clause added | **Semantic issue:** where('shift_id', null) works in SQL but `->whereNull('shift_id')` is more intentional |
| 4 | All PickupPointRoutes with shift_id=NULL for the route are fetched | Possibly unintended stops prepared |

### TC-D05: Soft-Deleted Stop Details (Detailed)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | trip_id=X has 5 stop details. Force delete one via DB (`forceDelete`) | 4 records remain + 1 hard removed |
| 2 | GET `/stop/details/prepare?trip_id=X` | JSON `inserted: 1, skipped: 4` |
| 3 | Verify new record created for the previously deleted stop | Correct — only soft-deletes cause the bug, not force-deletes |

### TC-CR05: Missing Rollback (Detailed Steps)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Simulate DB failure during stopDetailsPrepare (e.g., kill DB mid-operation) | Exception thrown between lines 487-536 |
| 2 | `DB::beginTransaction()` at line 487 already executed | Transaction is open |
| 3 | Exception propagates → `DB::commit()` at line 536 never reached | Transaction stays open |
| 4 | **Result:** Transaction never committed or rolled back → locks/connection leak | MySQL eventually rolls back on connection close, but PHP-FPM connection pooling may retain |

### TC-CR16: TptNotificationLog Fillable (Detailed Steps)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST: id=X, action=reach | Gate passes, stop updated |
| 2 | Line 231: `TptNotificationLog::create([...])` called | `MassAssignmentException` thrown because `$fillable = []` |
| 3 | Exception propagates uncaught | Laravel returns 500 error |
| 4 | **But:** `$stop->update()` at line 220-224 already executed successfully | Stop IS updated but notification fails |
| 5 | User sees 500 error (or in some Laravel configs, a generic error page) | User thinks action failed but stop was actually updated |

### TC-CR11: Manual empty() Check Edge Cases (Detailed)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST with empty string `trip_id=` | empty('') = true → 400 |
| 2 | POST with whitespace `trip_id=%20` | empty(' ') = false → `find(' ')` = null → 404 |
| 3 | POST with `trip_id[]=1&trip_id[]=2` (array) | `$request->trip_id` returns array → `find(array)` returns Collection → behavior differs |
| 4 | POST with `trip_id=abc` (non-numeric) | `find('abc')` returns null → 404 JSON. No type validation to reject non-integer |

### TC-CR22: bulkUpdateTime Rollback Without BeginTransaction (Detailed)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST /trip/bulk-update-time with valid trip_ids | try block executes |
| 2 | Exception occurs during update (e.g., DB error) | catch block runs |
| 3 | Line 626: `DB::rollBack()` called | **No matching beginTransaction** → rollBack does nothing |
| 4 | Line 627: `Log::error(...)` logs the error | Error logged |
| 5 | **Result:** Partial updates — some trips may have been updated before the error | Data inconsistency |

### TC-CR23: Missing toggleStatus Method (Detailed)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST /trip/1/toggle-status with is_active=1 | Route line 160 matches |
| 2 | TripController dispatch | Method resolution fails: NO `toggleStatus()` method |
| 3 | Laravel returns 500 error with `BadMethodCallException` | TripController has no toggleStatus method |
| 4 | **Impact:** No way to toggle trip active/inactive via API | UI feature broken if exposed |

---

## 8. Code Tracing (CODE-TRACE)

### CODE-TRACE-01: stopDetailsPrepare Full Code Path

**File:** `Modules/Transport/Http/Controllers/TripController.php` (lines 466–545)

```
TripController::stopDetailsPrepare(Request $request)
│
├── [468] Gate::authorize('tenant.stop-details.prepare')
│     └── 403 if not authorized
│
├── [470] $tripId = $request->trip_id ?? $request->tripe_id
│     └── Accepts both param names (trip_id / tripe_id)
│
├── [472–477] if (empty($tripId)) → 400 JSON
│     └── Bug: empty() treats 0 and '0' as empty
│
├── [479] $trip = TptTrip::with('routeScheduler')->find($tripId)
│     └── [480–485] if !$trip → 404 JSON
│
├── [487] DB::beginTransaction()
│     └── ⚠️ No try/catch → no rollback on exception
│
├── [489–492] PickupPointRoute::with('pickupPoint')
│     ├── ->where('route_id', $trip->route_id)
│     └── ->where('shift_id', $trip->routeScheduler?->shift_id)
│         └── ⚠️ If routeScheduler null → shift_id = null → no shift filter
│
├── [494–495] $inserted = 0; $skipped = 0;
│
├── [497–533] foreach ($routeStops as $stop)
│   │
│   ├── [500–503] $exists = TptTripStopDetail::where(...)->exists()
│   │   ├── Checks: trip_id, stop_id, pickup_drop
│   │   └── ⚠️ SoftDeletes global scope — includes deleted records
│   │
│   ├── [505–508] if ($exists) → $skipped++; continue
│   │
│   ├── [511–517] Convert arrival_time/departure_time from minutes to H:i:s
│   │   └── Carbon::createFromTime(0,0)->addMinutes($minutes)->format('H:i:s')
│   │
│   ├── [519–521] activityLog($stop, 'Create', [...])
│   │   └── ⚠️ $stop is PickupPointRoute — WRONG model type
│   │   └── ⚠️ Logged BEFORE TptTripStopDetail::create()
│   │
│   ├── [524–531] TptTripStopDetail::create([...])
│   │   └── Fields: trip_id, stop_id, pickup_drop, ordinal, sch_arrival_time, sch_departure_time
│   │
│   └── [533] $inserted++;
│
├── [536] DB::commit()
│
└── [538–543] return JSON → {status: true, inserted, skipped}
```

### CODE-TRACE-02: tripDetailsData Full Code Path

**File:** `Modules/Transport/Http/Controllers/TripController.php` (lines 327–338)

```
TripController::tripDetailsData(Request $request)
│
├── [329] Gate::authorize('tenant.stop-details.view')
│     └── 403 if not authorized
│
├── [331] $tripDetails = TptTripStopDetail::where('id', $request->id)->first()
│     └── Uses first() NOT findOrFail() → returns null if not found
│     └── ⚠️ No 404 response; always returns 200
│
└── [333–337] return JSON
      └── {status: true, message: "Trip Data Get successfully", inserted: $tripDetails}
      └── If null: {status: true, inserted: null} — misleading success
```

### CODE-TRACE-03: tripDetailsUpdated Full Code Path

**File:** `Modules/Transport/Http/Controllers/TripController.php` (lines 547–568)

```
TripController::tripDetailsUpdated(Request $request)
│
├── [549] Gate::authorize('tenant.stop-details.update')
│     └── 403 if not authorized
│
├── [551] $stop = TptTripStopDetail::find($request->id)
│     └── [552–554] if !$stop → 404 JSON
│
├── [556–558] activityLog($stop, 'Updated', [...])
│     └── ⚠️ Called BEFORE update — captures OLD state
│     └── Should be AFTER update to capture getChanges()
│
├── [560–565] $stop->update([...])
│     ├── reaching_time ← $request->reaching_time (NO validation)
│     ├── leaving_time ← $request->leaving_time (NO validation)
│     ├── emergency_flag ← $request->emergency_flag (NO boolean validation)
│     └── emergency_remarks ← $request->emergency_remarks (NO string validation)
│
└── [567] return JSON {status: true}
```

### CODE-TRACE-04: stopAction Full Code Path

**File:** `Modules/Transport/Http/Controllers/TripController.php` (lines 123–305)

```
TripController::stopAction(Request $request)
│
├── [125] Gate::authorize('tenant.stop-details.update')
│     └── 403 if not authorized
│
├── [127] $isNew = str_starts_with($request->id, 'new_')
│     └── If true: extract jntId from 'new_{jntId}' format
│     └── If false: find existing TptTripStopDetail
│
├── [131–181] Resolve $stop and $trip
│   ├── NEW stop path (lines 132–174):
│   │   ├── PickupPointRoute::find($jntId) → 404 if not found
│   │   ├── Find today's trip by route_id (fallback to any trip today)
│   │   ├── Check if TptTripStopDetail already exists for this junction
│   │   └── If not: TptTripStopDetail::create() from junction data
│   ├── EXISTING stop path (lines 175–181):
│   │   └── TptTripStopDetail::with('trip.routeScheduler')->find($id) → 404
│   └── [183–185] $updatedBy = optional($trip->routeScheduler)->driver_id
│       └── ⚠️ driver_id is DriverHelper FK, migration expects tpt_personnel
│
├── [187–297] switch($request->action)
│   │
│   ├── case 'start_trip' (lines 189–217):
│   │   ├── $stop->update([reached_flag=1, reaching_time=now, leaving_time=now, updated_by])
│   │   ├── if $request->filled('extra') → trip update with start_time, odometer, fuel, status
│   │   │   └── ⚠️ $request->extra['start_time'] without null guard
│   │   └── TptNotificationLog::create([...])
│   │       └── ⚠️ CRITICAL: $fillable=[] → MassAssignmentException
│   │
│   ├── case 'reach' (lines 219–238):
│   │   ├── $stop->update([reached_flag=1, reaching_time=now, updated_by])
│   │   ├── Delay detection: if sch_arrival_time +5min < now → 'Delayed' else 'ReachedStop'
│   │   │   └── ⚠️ sch_arrival_time null → Carbon::parse(null) → now → never triggers Delayed
│   │   └── TptNotificationLog::create([...]) → ⚠️ MassAssignmentException
│   │
│   ├── case 'leave' (lines 240–253):
│   │   ├── $stop->update([leaving_time=now, updated_by])
│   │   └── TptNotificationLog::create([...]) → ⚠️ MassAssignmentException
│   │
│   ├── case 'end_trip' (lines 255–275):
│   │   ├── $stop->update([reached_flag=1, reaching_time=now, leaving_time=now, updated_by])
│   │   ├── if $request->filled('extra') → trip update with end_time, odometer, fuel, status
│   │   │   └── ⚠️ $request->extra['end_time'] without null guard
│   │   └── ⚠️ No notification created for end_trip
│   │
│   ├── case 'emergency' (lines 277–297):
│   │   ├── $stop->update([emergency_flag=1, emergency_time=now, emergency_remarks, updated_by])
│   │   ├── TptTripIncidents::create([...])
│   │   │   └── severity=MEDIUM (always, never LOW or HIGH)
│   │   │   └── ⚠️ raised_by = driver_id (wrong FK)
│   │   └── ⚠️ No notification created for emergency
│   │
│   └── default: ⚠️ MISSING — no default case, no error handling
│
├── [300–304] return JSON {status: true, message: "Stop updated successfully"}
│     └── ⚠️ Returns success even for unknown actions (no default case)
│
└── ⚠️ No activityLog anywhere in stopAction
```

### CODE-TRACE-05: tripStopNew (TripMgmtController) Code Path

**File:** `Modules/Transport/Http/Controllers/TripMgmtController.php` (lines 204–232)

```
TripMgmtController::tripStopNew(Request $request)
│
├── [206] $query = TptTripStopDetail::with('stop')->orderBy('id')
│
├── [208] $tab = $request->input('tab')
│
├── [210–229] if ($tab === 'stop_details')
│   │
│   ├── [211] if trip_id or tripe_id filled:
│   │   └── $query->where('trip_id', $trip_id ?? $tripe_id)
│   │
│   ├── [213–223] else if date or route_id filled:
│   │   └── $query->whereHas('trip', function($q) use ($request)
│   │       ├── where('trip_date', $request->date)
│   │       └── where('route_id', $request->route_id)
│   │
│   └── [226–228] if pickup_drop filled:
│       └── $query->where('pickup_drop', $request->pickup_drop)
│
└── [231] return $query
```

### CODE-TRACE-06: tripStopTimeline Code Path

**File:** `Modules/Transport/Http/Controllers/TripMgmtController.php` (lines 253–345)

```
TripMgmtController::tripStopTimeline(Request $request)
│
├── [256–257] $query = PickupPointRoute::with('pickupPoint')->whereNull('deleted_at')
│
├── [259–270] Driver-user scoping
│   └── If logged-in user is a DriverHelper → filter routes by DriverRouteVehicleJnt assignments
│
├── [274–284] if ($tab === 'trip_details')
│   ├── where('shift_id') if filled
│   ├── where('route_id') if filled
│   └── where('pickup_drop') if filled
│
├── [286] $stops = $query->orderBy('ordinal', 'asc')->get()
│
├── [288] If empty → return empty collection
│
├── [290] Determine date: $request->date ?? today
│
├── [293–305] Fetch today's trips (with optional driver scoping)
│
├── [307–342] Map each PickupPointRoute to a timeline object
│   ├── Match trip by route_id (relaxed match)
│   ├── Find matching TptTripStopDetail by trip_id + stop_id + pickup_drop + ordinal
│   └── Build object with: id (or 'new_jntId' if not in DB), sch times, actual times, flags
│
└── [344] Return sorted by ordinal
```

### CODE-TRACE-07: TripMgmtController@index Trip ID Pre-fetch

**File:** `Modules/Transport/Http/Controllers/TripMgmtController.php` (lines 54–71)

```
TripMgmtController::index() — Trip ID Resolution
│
├── [54–63] $tripIds = TptTrip::where('trip_date', $request->date)
│   ├── whereHas('routeScheduler', shift_id filter)
│   ├── whereHas('routeScheduler', route_id filter)
│   └── ->first()
│
├── [66–67] If trip found:
│   └── $request->merge(['trip_id' => $tripIds->id, 'tripe_id' => $tripIds->id])
│
└── [69–71] If no trip found:
    └── $request->merge(['trip_id' => null, 'tripe_id' => null])
```

---

## 9. Gap Summary Table

| # | Gap ID | Severity | File:Line | Description |
|---|--------|----------|-----------|-------------|
| 1 | GAP-CRITICAL-01 | CRITICAL | `TptNotificationLog.php:18` | `$fillable = []` — all `::create()` calls throw `MassAssignmentException`. All notification logs silently fail. |
| 2 | GAP-CRITICAL-02 | CRITICAL | `details-list.blade.php:70,98,119` | `@can('tenant.stop-details.prepare.create')` and `.edit` — these permission strings do NOT exist in `permissionslist.php`. Add button and Action column/buttons are ALWAYS hidden. **Users cannot edit any stop details from the UI.** |
| 3 | GAP-HIGH-01 | HIGH | `TripController:519` | `activityLog($stop, 'Create', ...)` logs `$stop` which is `PickupPointRoute` (from loop), not the newly created `TptTripStopDetail`. Wrong model type and wrong ID in activity log. |
| 4 | GAP-HIGH-02 | HIGH | `TripController:556-558` | `activityLog()` called BEFORE `$stop->update()` at line 560. Log captures old values, not the actual changes made. |
| 5 | GAP-HIGH-03 | HIGH | `TripController:125-305` | `stopAction()` performs STOP updates + TRIP updates + NOTIFICATION creates + INCIDENT creates — NO `activityLog()` call anywhere. |
| 6 | GAP-HIGH-04 | HIGH | `TripController:183` | `updated_by` set to `$trip->routeScheduler->driver_id` (DriverHelper PK). Model `belongsTo(DriverHelper::class)` but migration FK references `tpt_personnel.id`. **Two different tables.** |
| 7 | GAP-HIGH-05 | HIGH | `TripController:560-565` | `tripDetailsUpdated()` passes raw `$request->reaching_time`, `$request->leaving_time`, `$request->emergency_flag`, `$request->emergency_remarks` to `update()` without ANY validation. |
| 8 | GAP-HIGH-06 | HIGH | `TripController:470` | `empty($tripId)` treats 0 and '0' as empty — valid ID of 0 would be rejected. No type validation either. |
| 9 | GAP-MED-01 | MEDIUM | `TripController:487` | `DB::beginTransaction()` without try/catch. Any exception between begin/commit leaks the open transaction. |
| 10 | GAP-MED-02 | MEDIUM | `TripController:125-305` | Multiple DB writes (stop, trip, notification, incident) in `stopAction` without wrapping in `DB::transaction()`. Partial writes on failure. |
| 11 | GAP-MED-03 | MEDIUM | `TripController:285-294` | Emergency action creates `TptTripIncidents` but creates NO `TptNotificationLog` — parents/guardians are not notified of emergencies. |
| 12 | GAP-MED-04 | MEDIUM | `TripController:291` | `raised_by` = `driver_id` (DriverHelper PK). `TptTripIncidents.raised_by` FK references `users.id` — **wrong FK target.** |
| 13 | GAP-MED-05 | MEDIUM | `TripController:500-503` | `exists()` query includes soft-deleted records via `SoftDeletes` global scope. Preparing after a trip deletion would skip stops incorrectly. |
| 14 | GAP-MED-06 | MEDIUM | `TripMgmtController:206` | `tripStopNew()` raw query without tenant scoping. Cross-tenant data exposure possible. |
| 15 | GAP-MED-07 | MEDIUM | `TripController:187-297` | `switch($request->action)` has NO `default:` case. Unknown action returns 200 success with no DB writes — false positive. |
| 16 | GAP-MED-08 | MEDIUM | `TripController:198,264` | `$request->extra['start_time']` and `['end_time']` accessed without null guard on the array key. |
| 17 | GAP-LOW-01 | LOW | `TripController:227` | `sch_arrival_time` could be null → `Carbon::parse(null)` = now → delay detection never triggers when arrival_time is null. |
| 18 | GAP-LOW-02 | LOW | `TripController:490-492` | `trip->routeScheduler?->shift_id` — if routeScheduler null, no shift filter applied to PickupPointRoute query. |
| 19 | GAP-LOW-03 | LOW | `TripController:626` | `bulkUpdateTime()` calls `DB::rollBack()` without matching `DB::beginTransaction()`. Rollback does nothing. |
| 20 | GAP-LOW-04 | LOW | `TripController:toggleStatus[]` | Route `trip.toggleStatus` registered but TripController has NO `toggleStatus()` method. Route call causes 500 error. |
| 21 | GAP-LOW-05 | LOW | `TransportStopDetailsPolicy.php` | Policy's `prepare()` expects model instance but controller uses string `Gate::authorize()`. Policy method is dead code. |
| 22 | GAP-LOW-06 | LOW | `TripController:331` | `tripDetailsData()` uses `first()` not `findOrFail()`. Invalid ID returns 200 with `inserted: null`. |
| 23 | GAP-LOW-07 | LOW | `TripController:293` | `severity` always = 'MEDIUM' — no dynamic severity calculation. |
| 24 | GAP-LOW-08 | LOW | `tripmanagement.blade.php:16` | Tab `stop_details` uses `tenant.stop-details.prepare` as permission key. Since `'stop-details.prepare' => $crud` in permissionslist, this grants all CRUD actions — broader than intended. |

---

## 10. Route Mapping

| Route Name | Method | URL | Controller Method | Permission Gate |
|------------|--------|-----|-------------------|-----------------|
| `stop-details.prepare` | GET | `/stop/details/prepare` | `TripController@stopDetailsPrepare` | `tenant.stop-details.prepare` |
| `trip.details.edits` | GET | `/trip/details/edits` | `TripController@tripDetailsData` | `tenant.stop-details.view` |
| `trip.details.updates` | POST | `/trip/details/updates` | `TripController@tripDetailsUpdated` | `tenant.stop-details.update` |
| `trip.stop-action` | POST | `/trip/stop-action` | `TripController@stopAction` | `tenant.stop-details.update` |
| `trip.trashed` | GET | `/trip/trash/view` | `TripController@trashed` | `tenant.trip.restore` |
| `trip.restore` | GET | `/trip/{id}/restore` | `TripController@restore` | `tenant.trip.restore` |
| `trip.forceDelete` | DELETE | `/trip/{id}/force-delete` | `TripController@forceDelete` | `tenant.trip.forceDelete` |
| `trip.toggleStatus` | POST | `/trip/{trip}/toggle-status` | **MISSING** — route exists, no method | N/A (500 error) |

---

## 11. Model Definitions

### TptTripStopDetail (Modules\Transport\Models\TptTripStopDetail)

| Property | Value |
|----------|-------|
| Table | `tpt_trip_stop_detail` |
| Traits | `SoftDeletes` |
| Fillable | trip_id, stop_id, pickup_drop, ordinal, sch_arrival_time, sch_departure_time, reached_flag, reaching_time, leaving_time, emergency_flag, emergency_time, emergency_remarks, updated_by |
| Casts | reached_flag (boolean), emergency_flag (boolean), sch_arrival_time (datetime), sch_departure_time (datetime), reaching_time (datetime), leaving_time (datetime), emergency_time (datetime) |
| Relations | trip() → belongsTo(TptTrip), stop() → belongsTo(PickupPoint), updatedBy() → belongsTo(DriverHelper) |

### PickupPointRoute (Modules\Transport\Models\PickupPointRoute)

| Property | Value |
|----------|-------|
| Table | `tpt_pickup_points_route_jnt` |
| Fillable | shift_id, route_id, pickup_drop, pickup_point_id, ordinal, arrival_time, departure_time, total_distance, estimated_time, pickup_drop_fare, both_side_fare, is_active |
| Casts | is_active (boolean), total_distance (decimal:2), pickup_drop_fare (decimal:2), both_side_fare (decimal:2), ordinal (integer), arrival_time (integer — **minutes from midnight**), departure_time (integer — **minutes from midnight**), estimated_time (integer) |
| Relations | route() → belongsTo(Route), pickupPoint() → belongsTo(PickupPoint), shift() → belongsTo(Shift) |

### TptNotificationLog (Modules\Transport\Models\TptNotificationLog)

| Property | Value |
|----------|-------|
| Table | `tpt_notification_log` |
| Traits | HasFactory |
| Fillable | **[] (EMPTY — CRITICAL BUG)** |
| Relations | trip(), boardingStop() |

### TptTripIncidents (Modules\Transport\Models\TptTripIncidents)

| Property | Value |
|----------|-------|
| Table | `tpt_trip_incidents` |
| Traits | HasFactory, SoftDeletes |
| Fillable | trip_id, incident_time, incident_type, severity, latitude, longitude, description, status, raised_by, raised_at, resolved_at, resolved_by |
| Casts | incident_time (datetime), raised_at (datetime), resolved_at (datetime), latitude (decimal:7), longitude (decimal:7) |
| Constants | TYPE: 0=StopEmergency, 1=VehicleBreakdown, 2=Accident, 3=RouteBlocked; STATUS: 0=OPEN, 1=RESOLVED; SEVERITY: LOW, MEDIUM, HIGH |
| Relations | trip(), raisedBy(), raisedByUser(), incidentType(), statusMaster(), resolvedBy() |

---

## 12. Blade View Structure Summary

| Blade File | Purpose | Tab | Permission Required |
|------------|---------|-----|---------------------|
| `tab_module/tripmanagement.blade.php` | Hub container with all tabs (lines 9-24) | ALL | `tenant.transport.viewAny` |
| `trip-details/index.blade.php` | Stop Status timeline (live actions) | `stop_status` | `tenant.stop-details.viewAny` |
| `trip-details/details-list.blade.php` | Stop Details grid (table + edit modal trigger) | `stop_details` | `tenant.stop-details.prepare` |
| `trip-details/js.blade.php` | AJAX handlers for prepare, edit, save | — | — |
| `trip-details/model.blade.php` | Edit Stop Modal + Start Trip Modal + End Trip Modal | — | — |

### Blade Permission Decorations

| File:Line | @can | Covers | Effect |
|-----------|------|--------|--------|
| details-list:70 | `tenant.stop-details.prepare.create` | Add Entry button | ❌ Always hidden (undefined permission) |
| details-list:98 | `tenant.stop-details.prepare.edit` | Action `<th>` column | ❌ Always hidden (undefined permission) |
| details-list:119 | `tenant.stop-details.prepare.edit` | Edit buttons in rows | ❌ Always hidden (undefined permission) |
| index.blade:114 | Shift+Route check | Action buttons visibility | Only shown when `request('shift_id') && request('route_id')` |

---

## 13. Gap Remediation Recommendations

### GAP-CRITICAL-01: TptNotificationLog $fillable

**Problem:** `TptNotificationLog` has `protected $fillable = [];` — all `::create()` calls throw `MassAssignmentException`.

**Fix:** Add all columns used in `stopAction` and other controller methods to `$fillable`:

```php
protected $fillable = [
    'trip_id', 'boarding_stop_id', 'notification_type', 'sent_time',
    'app_notification_status', 'message', 'recipient_type',
    'recipient_id', 'created_at', 'updated_at',
];
```

### GAP-CRITICAL-02: Blade Permission Strings Don't Exist

**Problem:** `details-list.blade.php` uses `tenant.stop-details.prepare.create` and `tenant.stop-details.prepare.edit` but `permissionslist.php` only has `stop-details.prepare` (a group, not an action) and `stop-details` (a group with `$crud`).

**Fix Option A (Recommended):** Replace blade permissions with correct existing strings:
- `@can('tenant.stop-details.prepare')` for Add button (the prepare group grant)
- `@can('tenant.stop-details.update')` for Edit action column

**Fix Option B:** Add the specific permission keys to `permissionslist.php`:
```php
'stop-details.prepare.create' => $crud,
'stop-details.prepare.edit' => $crud,
```

### GAP-HIGH-01: Wrong activityLog Model Type

**Problem:** Line 519 `activityLog($stop, 'Create', ...)` passes `$stop` (PickupPointRoute).

**Fix:** Move activityLog AFTER `TptTripStopDetail::create()` and pass the new record:

```php
$newStop = TptTripStopDetail::create([...]);
activityLog($newStop, 'Create', ['message' => 'Trip Details Create successfully.']);
$inserted++;
```

### GAP-HIGH-02: activityLog Before Update

**Problem:** Lines 556-558 activityLog before line 560-565 update.

**Fix:** Move activityLog AFTER update and include changes:

```php
$stop->update([...]);
$changes = [];
foreach ($stop->getChanges() as $field => $newValue) {
    if ($field === 'updated_at') continue;
    $changes[$field] = ['old' => $stop->getOriginal($field), 'new' => $newValue];
}
activityLog($stop, 'Updated', [
    'message' => empty($changes) ? 'Stop details updated. No changes.' : 'Stop details updated.',
    'changes' => $changes,
]);
```

### GAP-HIGH-03: No activityLog in stopAction

**Problem:** `stopAction()` performs DB writes but never calls `activityLog()`.

**Fix:** Add activityLog for each switch case after DB writes:

```php
activityLog($stop, 'Updated', [
    'message' => "Stop action '{$request->action}' performed.",
    'performed_by' => Auth::user()->name,
]);
```

### GAP-HIGH-04: updated_by FK Target Mismatch

**Problem:** Model `belongsTo(DriverHelper::class)` but migration FK references `tpt_personnel.id`.

**Fix:** Align model relationship with actual FK target:
- If `tpt_personnel` is correct table → change model to `belongsTo(Personnel::class)` or equivalent
- If `tpt_personnel` should be `tpt_personnel` (driver helpers) → change migration FK

### GAP-HIGH-05: No Request Validation

**Problem:** `tripDetailsUpdated()` passes raw request values to `update()` without validation.

**Fix:** Add validation:

```php
$request->validate([
    'reaching_time'     => 'nullable|date_format:H:i',
    'leaving_time'      => 'nullable|date_format:H:i',
    'emergency_flag'    => 'nullable|in:0,1',
    'emergency_remarks' => 'nullable|string|max:512',
]);
```

### GAP-MED-01: Missing Rollback

**Problem:** `stopDetailsPrepare()` uses `DB::beginTransaction()` without try/catch.

**Fix:** Wrap in try/catch with rollback:

```php
DB::beginTransaction();
try {
    // ... existing logic ...
    DB::commit();
} catch (\Exception $e) {
    DB::rollBack();
    return response()->json(['status' => false, 'message' => 'Failed to prepare stops.'], 500);
}
```

### GAP-MED-02: No Transaction in stopAction

**Problem:** Multiple DB writes (stop, trip, notification, incident) without atomicity.

**Fix:** Wrap entire action logic in `DB::transaction()`:

```php
DB::transaction(function () use ($request) {
    // all action logic here
});
```

### GAP-MED-07: Missing default in switch

**Problem:** `switch($request->action)` has no `default:` — unknown actions return false positive success.

**Fix:** Add default case:

```php
default:
    return response()->json(['status' => false, 'message' => 'Invalid action.'], 400);
```

---

## 14. Error Handling Matrix

| Scenario | Endpoint | Error Response | HTTP Code | Error Location |
|----------|----------|---------------|-----------|----------------|
| Missing trip_id | stopDetailsPrepare | `{status: false, message: "Trip ID is required"}` | 400 | TripController:472-477 |
| Non-existent trip | stopDetailsPrepare | `{status: false, message: "Trip not found"}` | 404 | TripController:480-485 |
| Invalid stop detail ID (first/find) | tripDetailsData | `{status: true, inserted: null}` | 200 (misleading) | TripController:331 |
| Invalid stop detail ID (find) | tripDetailsUpdated | `{status: false, message: "Stop Detail not found."}` | 404 | TripController:552-554 |
| Invalid stop detail ID (find) | stopAction | `{status: false, message: "Stop Detail not found."}` | 404 | TripController:177-179 |
| Invalid new_ jnt ID | stopAction | `{status: false, message: "Junction stop not found."}` | 404 | TripController:136-138 |
| No active trip for new_ stop | stopAction | `{status: false, message: "No active trip scheduled for today."}` | 404 | TripController:150-152 |
| Invalid action string | stopAction | `{status: true, message: "Stop updated successfully"}` | 200 (**false positive**) | TripController:300-304 (no default) |
| Missing id | stopAction | `{status: false, message: "Stop Detail not found."}` | 404 | TripController:177 |
| Missing Gate permission | All endpoints | Symfony HTTP 403 Forbidden | 403 | Middleware |
| Guest access | All URLs | Redirect to /login | 302 | Laravel auth middleware |
| DB exception in prepare | stopDetailsPrepare | **Unhandled** — no try/catch | 500 | TripController:487-536 |
| TptNotificationLog create failure | stopAction | **MassAssignmentException** (silent) | 500 | TptNotificationLog.php:18 |

### Error Response Gap Summary

- **GAP-ERR-01:** `tripDetailsData` returns 200 with null data for invalid IDs — should return 404.
- **GAP-ERR-02:** `stopAction` returns 200 success for unknown `action` values — should return 400.
- **GAP-ERR-03:** `stopDetailsPrepare` has no exception handling for DB errors — transaction leak on failure.
- **GAP-ERR-04:** No centralized error logging — exceptions are not logged except in `bulkUpdateTime`.

---

## 15. Security Analysis

### 15.1 Authorization Coverage

| Endpoint | Gate Check | Policy Used | Tenant Scoped |
|----------|-----------|-------------|---------------|
| stopDetailsPrepare | ✅ `tenant.stop-details.prepare` | ❌ (string gate) | ❌ No tenant filter |
| tripDetailsData | ✅ `tenant.stop-details.view` | ❌ (string gate) | ❌ No tenant filter |
| tripDetailsUpdated | ✅ `tenant.stop-details.update` | ❌ (string gate) | ❌ No tenant filter |
| stopAction | ✅ `tenant.stop-details.update` | ❌ (string gate) | ❌ No tenant filter |

### 15.2 Security Gaps

| Security Gap | Severity | Details |
|-------------|----------|---------|
| No tenant isolation on stop detail queries | MEDIUM | `tripStopNew()` queries `TptTripStopDetail` without `whereHas('trip.routeScheduler.tenant')` or similar tenant scope. If tenant context isn't enforced elsewhere, users from one tenant could see another tenant's stop details. |
| Policy dead code | LOW | `TransportStopDetailsPolicy` defines `prepare()` with model parameter but controller never uses it. `Gate::authorize('prepare', $stopDetail)` is never called. |
| Mass assignment on notification logs | CRITICAL | Empty `$fillable` means all `::create()` calls are blocked. Notifications silently fail. |
| No rate limiting on stopAction | LOW | Multiple rapid POST requests to stopAction could create excessive notification log entries (if fillable were fixed) and incident records. |
| Missing input sanitization | MEDIUM | `emergency_remarks` stored directly from `$request->remark` without sanitization in stopAction emergency case. |

### 15.3 CSRF Protection

All POST routes (`trip/details/updates`, `trip/stop-action`) are protected by Laravel's default CSRF middleware. The frontend JS in `js.blade.php` properly includes `_token: '{{ csrf_token() }}'` in the payload.

---

## 16. Performance Considerations

| Aspect | Analysis | Recommendation |
|--------|----------|---------------|
| stopDetailsPrepare N+1 query | Single query for PickupPointRoute (eager loaded pickupPoint) then loop-based individual `exists()` and `create()` calls. O(n) DB round trips for n stops. | Acceptable for typical route sizes (10-30 stops). No action needed. |
| tripStopNew eager loading | `TptTripStopDetail::with('stop')` — single join. | Optimal. |
| tripStopTimeline collection operations | Fetches all PickupPointRoutes then maps in PHP using `first()` on collection. No N+1 beyond initial query. | Acceptable. |
| stopAction repeated trip fallback | For new_ stops, falls back to any today's trip if route-specific trip not found. Uses `first()` on filtered query. | Acceptable. |
| activityLog loop per stop | In stopDetailsPrepare, activityLog is called inside foreach. Each call is a separate DB insert. | Acceptable for <50 stops. For bulk operations, could batch. |
| Pagination naming conflict | Tab-based pagination uses unique names: `stop_details` grid uses default pagination (no name override). Could conflict if other tabs use same pagination page name. | Ensure unique page names across tabs. |

---

## 17. Complete Test Case Traceability Matrix

| TC ID | BC ID(s) Covered | Section 7 Steps | Source File(s) | Method(s) |
|-------|------------------|-----------------|----------------|-----------|
| TC-P01 | BC-AUTH-01 (via tab), BC-BIZ-DEEP-20 | ✅ | TripMgmtController:204-232 | tripStopNew |
| TC-P02 | BC-BIZ-01, BC-BIZ-02, BC-BIZ-03, BC-BIZ-DEEP-01, BC-BIZ-DEEP-04, BC-BIZ-DEEP-05, BC-BIZ-DEEP-18 | ✅ | TripController:466-545 | stopDetailsPrepare |
| TC-P03 | BC-BIZ-02 | ✅ | TripController:500-508 | stopDetailsPrepare (skip) |
| TC-P04 | BC-BIZ-04, BC-AUTH-02 | ✅ | TripController:327-338 | tripDetailsData |
| TC-P05 | BC-BIZ-05, BC-BIZ-06, BC-AUTH-03, BC-BIZ-DEEP-07, BC-BIZ-DEEP-08 | ✅ | TripController:547-568 | tripDetailsUpdated |
| TC-P06 | BC-BIZ-05, BC-BIZ-06 | ✅ | TripController:560-565 | tripDetailsUpdated |
| TC-P07 | BC-BIZ-DEEP-20 | ✅ | TripMgmtController:210-212 | tripStopNew filter |
| TC-P08 | — | ✅ | TripMgmtController:54-71, 213-223 | index + tripStopNew |
| TC-P09 | — | ✅ | TripMgmtController:226-228 | tripStopNew pickup_drop filter |
| TC-P10 | BC-BIZ-07, BC-BIZ-12, BC-AUTH-04, BC-BIZ-DEEP-09, BC-BIZ-DEEP-14 | ✅ | TripController:219-238 | stopAction reach |
| TC-P11 | BC-BIZ-08, BC-BIZ-12, BC-AUTH-04, BC-BIZ-DEEP-09 | ✅ | TripController:240-253 | stopAction leave |
| TC-P12 | BC-BIZ-09, BC-BIZ-12, BC-AUTH-04, BC-BIZ-DEEP-10, BC-BIZ-DEEP-16, BC-BIZ-DEEP-17 | ✅ | TripController:277-297 | stopAction emergency |
| TC-P13 | BC-BIZ-10, BC-BIZ-DEEP-12 | ✅ | TripController:189-217 | stopAction start_trip |
| TC-P14 | BC-BIZ-11, BC-BIZ-DEEP-13 | ✅ | TripController:255-275 | stopAction end_trip |
| TC-P15 | BC-BIZ-DEEP-11 | ✅ | TripController:131-181 | stopAction new_ path |
| TC-P16 | — | ✅ | TripMgmtController:253-345 | tripStopTimeline |
| TC-P17 | BC-BIZ-DEEP-01 | ✅ | TripController:470 | stopDetailsPrepare param fallback |
| TC-P18 | — | ✅ | TripMgmtController:54-71 | index trip ID pre-fetch |
| TC-N01 | BC-BIZ-DEEP-01 | ✅ | TripController:472-477 | stopDetailsPrepare empty check |
| TC-N02 | — | ✅ | TripController:479-485 | stopDetailsPrepare not found |
| TC-N03 | BC-BIZ-DEEP-22 | ✅ | TripController:331 | tripDetailsData first() |
| TC-N04 | — | ✅ | TripController:551-554 | tripDetailsUpdated find |
| TC-N05 | BC-AUTH-01 | ✅ | TripController:468 | Gate check |
| TC-N06 | BC-AUTH-02 | ✅ | TripController:329 | Gate check |
| TC-N07 | BC-AUTH-03 | ✅ | TripController:549 | Gate check |
| TC-N08 | — | ✅ | Middleware | Guest redirect |
| TC-N09 | — | ✅ | TripController:177-179 | stopAction find |
| TC-N10 | BC-AUTH-04 | ✅ | TripController:125 | Gate check |
| TC-N11 | BC-BIZ-DEEP-01 | ✅ | TripController:472 | empty(0) edge case |
| TC-N12 | BC-BIZ-DEEP-28 | ✅ | TripController:187-297 | switch no default |
| TC-N13 | — | ✅ | TripController:176 | null id |
| TC-N14 | BC-BIZ-DEEP-08 | ✅ | TripController:560-565 | no validation |
| TC-N15 | — | ✅ | TripMgmtController:69-71 | no trip matched |
| TC-D01 | — | — | PickupPointRoute query | Dependency |
| TC-D02 | — | — | TripController:388-411 | destroy cascade |
| TC-D03 | BC-BIZ-12 | — | TripController:183-185 | updated_by source |
| TC-D04 | BC-BIZ-DEEP-03 | — | TripController:491 | shift_id null |
| TC-D05 | BC-BIZ-DEEP-18 | — | TptTripStopDetail scope | SoftDeletes |

## 18. Test Data Setup Scripts

### 18.1 Prerequisites for All Tests

```sql
-- Insert a pickup point
INSERT INTO tpt_pickup_points (id, name, latitude, longitude, is_active, created_at, updated_at)
VALUES (1, 'Main Gate', 12.3456, 78.9012, 1, NOW(), NOW());

-- Insert a route
INSERT INTO tpt_routes (id, name, code, description, is_active, created_at, updated_at)
VALUES (1, 'Route A', 'RT-A', 'School to City Center', 1, NOW(), NOW());

-- Insert a shift
INSERT INTO tpt_shifts (id, name, start_time, end_time, is_active, created_at, updated_at)
VALUES (1, 'Morning Shift', '07:00:00', '09:00:00', 1, NOW(), NOW());

-- Insert a vehicle
INSERT INTO tpt_vehicles (id, registration_no, vehicle_no, is_active, created_at, updated_at)
VALUES (1, 'KA-01-AB-1234', 'Bus 01', 1, NOW(), NOW());

-- Insert a driver
INSERT INTO tpt_personnel (id, name, type, user_id, is_active, created_at, updated_at)
VALUES (1, 'Driver Raj', 'DRIVER', NULL, 1, NOW(), NOW());
```

### 18.2 Stop Details Prepare Test Data

```sql
-- Insert route scheduler
INSERT INTO tpt_route_scheduler_jnt (id, route_id, shift_id, vehicle_id, driver_id, scheduled_date, is_active, created_at, updated_at)
VALUES (1, 1, 1, 1, 1, CURDATE(), 1, NOW(), NOW());

-- Insert pickup point route stops (5 stops)
INSERT INTO tpt_pickup_points_route_jnt (id, shift_id, route_id, pickup_drop, pickup_point_id, ordinal, arrival_time, departure_time)
VALUES
(1, 1, 1, 'Pickup', 1, 1, 0, 5),      -- Stop 1: minute 0-5
(2, 1, 1, 'Pickup', 1, 2, 10, 15),     -- Stop 2: minute 10-15
(3, 1, 1, 'Pickup', 1, 3, 20, 25),     -- Stop 3: minute 20-25
(4, 1, 1, 'Pickup', 1, 4, 30, 35),     -- Stop 4: minute 30-35
(5, 1, 1, 'Drop', 1, 5, 40, 45);       -- Stop 5: minute 40-45

-- Insert trip
INSERT INTO tpt_trip (id, trip_date, route_scheduler_id, route_id, vehicle_id, driver_id, status, approved, created_at, updated_at)
VALUES (1, CURDATE(), 1, 1, 1, 1, 'Scheduled', 0, NOW(), NOW());
```

### 18.3 Stop Action Test Data (Existing Stop Detail)

```sql
-- Prepare a single stop detail manually (skip prepare endpoint)
INSERT INTO tpt_trip_stop_detail (id, trip_id, stop_id, pickup_drop, ordinal, sch_arrival_time, sch_departure_time, reached_flag, reaching_time, leaving_time, emergency_flag, created_at, updated_at)
VALUES (1, 1, 1, 'Pickup', 1, '2026-07-22 07:00:00', '2026-07-22 07:05:00', 0, NULL, NULL, 0, NOW(), NOW());
```

### 18.4 New Stop Action Test Data (No Existing Stop Detail)

```sql
-- Ensure PickupPointRoute jnt_id=1 exists (from 18.2)
-- Ensure today's trip for route_id=1 exists (from 18.2)
-- No TptTripStopDetail record needed — stopAction creates one via new_{jntId} path
```

### 18.5 Permission / 403 Test Setup

```sql
-- Create a user without stop-details permissions
INSERT INTO users (id, name, email, password, tenant_id, created_at, updated_at)
VALUES (100, 'Limited User', 'limited@test.com', '$2y$10$...', 1, NOW(), NOW());

-- No role/permission assignment for stop-details
-- Access via limited@test.com → 403 for all stop-details endpoints
```

### 18.6 Soft-Delete Edge Case Setup

```sql
-- Prepare stop details first (creates 5 records)
-- Then soft-delete one record
UPDATE tpt_trip_stop_detail SET deleted_at = NOW() WHERE id = 1;
-- Now trip_id=1 has 4 visible + 1 soft-deleted
```

---

## 19. Frontend JS Code Tracing (FE-TRACE)

### FE-TRACE-01: Add Entry Button Click (Prepare)

**File:** `Modules/Transport/resources/views/trip-details/js.blade.php` (lines 1–45)

```
User clicks #addEntryBtn
│
├── js.blade:4 – $(document).ready handler
│
├── js.blade:9 – Serialize #stopFilterForm
│   └── Captures: tab, date, shift_id, route_id, pickup_drop, trip_id
│
├── js.blade:10-13 – Form validation:
│   ├── if !route_id → showToast("error", "Please select Route and Shift first!")
│   └── if !shift_id → showToast("error", "Please select Route and Shift first!")
│
├── js.blade:14-41 – $.ajax GET → route('transport.stop-details.prepare')
│   ├── success (line 18-30):
│   │   ├── if res.status → showToast("success", "Trip Stops Prepared | Added: X, Skipped: Y")
│   │   └── else → showToast("error", res.message)
│   └── error (line 32-36):
│       └── showToast("error", xhr.responseJSON?.message ?? "Add Trip Details Failed!")
│
└── complete (line 38-40):
    └── #addEntryBtn.prop('disabled', false) — re-enables button
```

### FE-TRACE-02: Edit Stop Button Click

**File:** `Modules/Transport/resources/views/trip-details/js.blade.php` (lines 59–106)

```
User clicks .editStopBtn
│
├── js.blade:59-64 – Confirm dialog:
│   └── Swal.fire with 'Sure to Edit?' →
│   │   ├── If confirmed → continue
│   │   └── If cancelled → stop
│
├── js.blade:73 – let id = $(this).data('id')
│
├── js.blade:80-101 – $.ajax GET → route('transport.trip.details.edits')
│   └── success (line 84-96):
│       ├── let data = res.inserted
│       ├── $('#edit_id').val(data.id)
│       ├── $('#edit_reaching_time').val(timeFromISO(data.reaching_time))
│       ├── $('#edit_leaving_time').val(timeFromISO(data.leaving_time))
│       ├── $('#edit_emergency_flag').val(boolToInt(data.emergency_flag))
│       ├── $('#edit_emergency_remarks').val(data.emergency_remarks ?? '')
│       └── Show Bootstrap 5 modal #editStopModal
│
│   └── error (line 98-101):
│       └── showToast('error', 'Failed to load stop details')
│
└── Helper functions:
    ├── timeFromISO(dateTime) → extracts HH:MM from ISO string (line 108-111)
    └── boolToInt(val) → 1 if truthy else 0 (line 113-115)
```

### FE-TRACE-03: Save Stop Button Click (Update)

**File:** `Modules/Transport/resources/views/trip-details/js.blade.php` (lines 117–156)

```
User clicks #saveStopBtn
│
├── js.blade:120-127 – Build payload:
│   ├── _token: '{{ csrf_token() }}'
│   ├── id: $('#edit_id').val()
│   ├── reaching_time: $('#edit_reaching_time').val()
│   ├── leaving_time: $('#edit_leaving_time').val()
│   ├── emergency_flag: $('#edit_emergency_flag').val()
│   └── emergency_remarks: $('#edit_emergency_remarks').val()
│
├── js.blade:129-155 – $.ajax POST → route('transport.trip.details.updates')
│   ├── beforeSend (line 133-135):
│   │   └── #saveStopBtn.prop('disabled', true)
│   ├── success (line 136-148):
│   │   ├── showToast('success', 'Trip Details Data Updated Successfully')
│   │   ├── Close Bootstrap 5 modal #editStopModal
│   │   └── setTimeout location.reload() after 3s
│   └── error (line 150-153):
│       ├── console.error(xhr.responseText)
│       ├── showToast('error', 'Server error occurred')
│       └── #saveStopBtn.prop('disabled', false)
```

---

## 20. Complete File Inventory

| File Path | Lines | Purpose | Relevance to Stopage Details |
|-----------|-------|---------|------------------------------|
| `Modules/Transport/Http/Controllers/TripController.php` | 841 | Stop prepare, fetch, update, stopAction | **Main controller** — lines 123-305 (stopAction), 327-338 (tripDetailsData), 466-545 (stopDetailsPrepare), 547-568 (tripDetailsUpdated) |
| `Modules/Transport/Http/Controllers/TripMgmtController.php` | 538 | Tab container with tripStopNew, tripStopTimeline | Lines 36-112 (index with trip ID pre-fetch), 204-232 (tripStopNew), 253-345 (tripStopTimeline) |
| `Modules/Transport/Models/TptTripStopDetail.php` | 57 | Stop detail model with SoftDeletes | Full file — main model |
| `Modules/Transport/Models/TptTrip.php` | 223 | Trip model with boot() validation | Trip relationships, status FSM |
| `Modules/Transport/Models/PickupPointRoute.php` | 63 | Route-junction model (source for prepare) | Minutes→time conversion, relationships |
| `Modules/Transport/Models/TptNotificationLog.php` | 24 | Notification log model — **$fillable=[] BUG** | Full file — critical bug |
| `Modules/Transport/Models/TptTripIncidents.php` | 148 | Incident model — created on emergency action | Incident creation in stopAction |
| `Modules/Transport/Policies/TransportStopDetailsPolicy.php` | 122 | Policy with all CRUD permissions | Dead code — controller uses string gates |
| `Modules/Transport/routes/web.php` | 294 | All transport routes | Lines 141-167 (trip routes including stop details) |
| `config/permissionslist.php` | 747 | Permission definitions | Lines 321-322 (stop-details permissions) |
| `resources/views/trip-details/details-list.blade.php` | 141 | Stop details grid view | Full file — **broken @can permissions** |
| `resources/views/trip-details/index.blade.php` | 181 | Stop status timeline view | Full file |
| `resources/views/trip-details/js.blade.php` | 157 | JS handlers for AJAX operations | Full file |
| `resources/views/trip-details/model.blade.php` | 111 | Edit/Start/End modals | Full file |
| `resources/views/tab_module/tripmanagement.blade.php` | 60 | Tab container hub | Lines 9-24 (tab definitions), 34-39 (tab includes) |
| `database/migrations/tenant/2026_06_16_140624_create_tpt_trip_stop_detail_table.php` | 47 | DDL migration | Full file — schema definition |

---

## 21. Permission String Cross-Reference

| Permission String | Where Used | Defined in permissionslist.php? | Match Status |
|-------------------|-----------|-------------------------------|--------------|
| `tenant.stop-details.viewAny` | tripmanagement.blade tab `stop_status`, `TransportStopDetailsPolicy::viewAny()` | ✅ Yes, via `'stop-details' => $crud` (line 321) | ✅ Matches |
| `tenant.stop-details.prepare` | tripmanagement.blade tab `stop_details`, TripController::stopDetailsPrepare() Gate | ✅ Yes, `'stop-details.prepare' => $crud` (line 322) | ✅ Matches |
| `tenant.stop-details.view` | TripController::tripDetailsData() Gate, `TransportStopDetailsPolicy::view()` | ✅ Yes, via `'stop-details' => $crud` | ✅ Matches |
| `tenant.stop-details.update` | TripController::tripDetailsUpdated() Gate, TripController::stopAction() Gate, `TransportStopDetailsPolicy::update()` | ✅ Yes, via `'stop-details' => $crud` | ✅ Matches |
| `tenant.stop-details.create` | `TransportStopDetailsPolicy::create()` | ✅ Yes, via `'stop-details' => $crud` | ✅ Matches (policy only) |
| `tenant.stop-details.delete` | `TransportStopDetailsPolicy::delete()` | ✅ Yes, via `'stop-details' => $crud` | ✅ Matches (policy only) |
| `tenant.stop-details.restore` | `TransportStopDetailsPolicy::restore()` | ✅ Yes, via `'stop-details' => $crud` | ✅ Matches (policy only) |
| `tenant.stop-details.forceDelete` | `TransportStopDetailsPolicy::forceDelete()` | ✅ Yes, via `'stop-details' => $crud` | ✅ Matches (policy only) |
| `tenant.stop-details.prepare.create` | **details-list.blade.php:70** — Add button @can | ❌ **NOT DEFINED** | ❌ **BROKEN** |
| `tenant.stop-details.prepare.edit` | **details-list.blade.php:98,119** — Action column + edit buttons @can | ❌ **NOT DEFINED** | ❌ **BROKEN** |
| `tenant.transport.viewAny` | TripMgmtController::index() Gate | ✅ Yes, `'transport' => $crud` (line 289) | ✅ Matches |

---

## 22. Key Metrics Summary

| Metric | Value |
|--------|-------|
| Total Positive Test Cases | 18 (P01-P18) |
| Total Negative Test Cases | 15 (N01-N15) |
| Total Dependency Test Cases | 5 (D01-D05) |
| Total Code Review Test Cases | 28 (CR01-CR28) |
| **Total Test Cases** | **66** |
| BC-BIZ (Business Conditions) | 12 (BC-BIZ-01 to -12) |
| BC-BIZ-DEEP (Deep-Dive Conditions) | 20 (BC-BIZ-DEEP-01 to -20) |
| BC-AUTH (Authorization) | 5 (BC-AUTH-01 to -05) |
| BC-AUTH-GAP (Permission Gaps) | 4 (BC-AUTH-GAP-01 to -04) |
| Code Traces | 7 (CODE-TRACE-01 to -07) |
| Frontend Traces | 3 (FE-TRACE-01 to -03) |
| Gaps (Critical) | 2 (GAP-CRITICAL-01 to -02) |
| Gaps (High) | 6 (GAP-HIGH-01 to -06) |
| Gaps (Medium) | 8 (GAP-MED-01 to -08) |
| Gaps (Low) | 8 (GAP-LOW-01 to -08) |
| **Total Gaps** | **24** |
| Error Handling Cases | 11 (Error Matrix rows) |
| Error Response Gaps | 4 (GAP-ERR-01 to -04) |
| Security Gaps | 5 (Section 15.2) |
| Controller Files Analyzed | 2 (TripController, TripMgmtController) |
| Model Files Analyzed | 5 (TptTripStopDetail, TptTrip, PickupPointRoute, TptNotificationLog, TptTripIncidents) |
| Blade Files Analyzed | 5 (tripmanagement, details-list, index, js, model) |
| Route Entries (stop-details related) | 4 (prepare, edits, updates, stop-action) |
| DDL Columns (tpt_trip_stop_detail) | 17 (including FK, timestamps, soft-delete) |
| Migration FKs | 3 (trip_id→tpt_trip CASCADE, stop_id→tpt_pickup_points SET NULL, updated_by→tpt_personnel SET NULL) |

(End of file)
