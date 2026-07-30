# tpt_TripApprove_TcList

## Module: Transport → Trip Management → Trip Approval

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | Transport |
| Tab Group | Trip Management |
| Feature | Trip Approval |
| URL(s) | `/transport/trip-management?tab=trip_approve` (index via tab — same as daily_trip with approval filters), `/transport/trip/toggle-approve` (toggleApproval POST — approve/disapprove single trip), `/transport/trip/bulk-approve` (bulkApprove POST — approve/unapprove multiple trips) |
| Controller | `Modules\Transport\Http\Controllers\TripController@toggleApproval()` (line 632) and `@bulkApprove()` (line 702) |
| Tab Container Controller | `Modules\Transport\Http\Controllers\TripMgmtController@index()` (line 36) — tab: `trip_approve` |
| Model | `Modules\Transport\Models\TptTrip` — table: `tpt_trip` (same as DailyTrip) |
| Policy | `Modules\Transport\Policies\TransportTripApprovePolicy` (89 lines, confirmed present) |
| Permissions (confirmed in test) | `tenant.trip-approve.viewAny`, `tenant.trip-approve.view`, `tenant.trip-approve.approve`, `tenant.trip-approve.bulkApprove`, `tenant.trip-approve.edit`, `tenant.trip-approve.delete`, `tenant.transport.viewAny` |
| Permissions (policy defined, unused in controller) | `tenant.trip-approve.reject`, `tenant.trip-approve.viewHistory`, `tenant.trip-approve.export`, `tenant.trip-approve.print`, `tenant.trip-approve.viewPending`, `tenant.trip-approve.override` |
| Permissions (in blade, missing from policy) | `tenant.trip-approve.status` — used in `@canany` for approval switch column, no corresponding policy method |
| Vendor Integration | On approval, creates `VndUsageLog` with calculated distance; on unapprove, deletes the log |
| Route Definitions | `POST /transport/trip/toggle-approve` → `TripController@toggleApproval` (web.php:166), `POST /transport/trip/bulk-approve` → `TripController@bulkApprove` (web.php:165) |
| Blade Views | `resources/views/trip_approve/index.blade.php` (tab partial, 153 lines), `resources/views/trip_approve/js.blade.php` (JS+CSS, 160 lines), `resources/views/trip_approve/model.blade.php` (modal) |
| CSS/JS Dependencies | Included via `@include('transport::trip_approve.js')` and `@include('transport::trip_approve.model')` at bottom of index partial |
| Tab Container Blade | `resources/views/tab_module/tripmanagement.blade.php` (60 lines) — tab 8 of 9 |

---

## 2. Pre-conditions

- Required permissions: `tenant.trip-approve.approve` (single), `tenant.trip-approve.bulkApprove` (bulk)
- Parent permission: `tenant.transport.viewAny` (required to access any transport tab)
- A trip must exist (approval conceptually makes sense only for completed trips, though code doesn't enforce this)
- Distance calculation: `max(0, round(end_odometer_reading - start_odometer_reading, 2))`
- Vendor must exist on the vehicle's routeScheduler for VndUsageLog creation
- Route scheduler must have vehicle with vendor relationship chain intact for full VndUsageLog
- For bulk operations: at least one trip checkbox must be selected in the UI
- Test data prerequisites: shift, route, vehicle, driver, routeScheduler records must exist in DB
- Authentication: user must be logged in (guest → redirect to /login)

---

## 3. Default Data Load

The trip_approve tab uses the same `TripMgmtController@TripQuery()` as daily_trip:

| Data | Source | Query | Filters |
|------|--------|-------|---------|
| Trips for Approval | `TripMgmtController@TripQuery()` | Same as daily_trip with tab=trip_approve | trip_date, route_id, vehicle_id, driver_id, approval_status, status, search |

Both `daily_trip` and `trip_approve` tabs share the identical `TripQuery()` method (TripMgmtController line 348) — filter conditions are OR'd together within the same `if ($tab === 'daily_trip' || $tab === 'trip_approve')` block. The pagination variable `$TripData` is shared across both tabs.

### Data Loading Sequence (TripMgmtController@index):

```
Step 1: Gate::authorize('tenant.transport.viewAny')  ← Parent gate (line 38)
Step 2: Auth user resolution + driver login detection (lines 40-51)
Step 3: Trip ID pre-fetch via date+shift+route filters (lines 53-71)
Step 4: Fetch reference data: vehicles, routes, drivers, shifts (lines 73-80)
Step 5: Execute 7 sub-queries (lines 83-90):
  ├── tripStopTimeline()     → $stopDetails
  ├── tripStopNew()          → $StopDetailsNew (paginated)
  ├── TripQuery()            → $TripData (paginated, 10/page) ← SHARED with daily_trip
  ├── tripBordUnbord()       → $bordUnBordData
  ├── incidentQuery()        → $incidentData
  ├── driverRouteVehicleQuery() → $driverRouteVehicles
  ├── SchedulerQuery()       → $sheduleData
  └── notificationLogQuery() → $notificationLog
Step 6: Return tab_module.tripmanagement view with all data (lines 92-111)
```

---

## 4. Test Data Strategy

- **Toggle approval**: POST `/transport/trip/toggle-approve` with `id` and `status` (1=approve, 0=disapprove)
- **Bulk approve**: POST `/transport/trip/bulk-approve` with `trip_ids` array and `action` (approve/unapprove)
- Approval sets: `approved=1`, `approved_by=Auth::id()`, `approved_at=now()`
- Disapproval resets: `approved=0`, `approved_by=null`, `approved_at=null`
- VndUsageLog is created on approve, deleted on unapprove
- Bulk approve skips already-approved trips
- Test trips must be created with `start_odometer_reading` and `end_odometer_reading` for distance calculation verification
- For VndUsageLog verification: route scheduler must have vehicle with vendor assigned
- Test trips created directly via DB insert (not through controller) to avoid model boot hooks when testing approval in isolation
- Cleanup strategy: createdTripIds array tracked in Dusk test, delete in tearDown()

### Test Data Factory Pattern (from Dusk test createTripDirectly):

```php
$data = [
    'trip_date' => now()->format('Y-m-d'),
    'route_scheduler_id' => $this->routeSchedulerId,
    'route_id'           => $this->routeId,
    'vehicle_id'         => $this->vehicleId,
    'driver_id'          => $this->driverId,
    'helper_id'          => null,
    'start_time'         => null,
    'end_time'           => null,
    'start_odometer_reading' => 0.00,
    'end_odometer_reading'   => 0.00,
    'start_fuel_reading'     => 0.00,
    'end_fuel_reading'       => 0.00,
    'status'             => 'Scheduled',
    'approved'           => 0,
    'remarks'            => 'Trip Approve test - {suffix}',
];
```

---

## 5. Business Conditions

### 5.1 Database Schema

Uses `tpt_trip` table — see `tpt_DailyTrip_TcList.md` section 5.1 for full schema.

Approval-related columns:
- `approved` TINYINT(1) NOT NULL DEFAULT 0
- `approved_by` INT UNSIGNED DEFAULT NULL → FK to sys_users
- `approved_at` TIMESTAMP NULL

Additional columns relevant to approval:
- `start_odometer_reading` DECIMAL(10,2) DEFAULT 0.00 — used for distance calc
- `end_odometer_reading` DECIMAL(10,2) DEFAULT 0.00 — used for distance calc
- `status` VARCHAR(255) DEFAULT 'Scheduled' — trip lifecycle state (not checked by approval)
- `deleted_at` TIMESTAMP NULL — soft delete (approval survives soft delete)

### 5.2 Validation (Inline)

| BC ID | Endpoint | Validation | Location | Severity |
|-------|----------|------------|----------|----------|
| BC-VAL-01 | toggleApproval | None — `$request->id` and `$request->status` not explicitly validated | `TripController:632-634` | MEDIUM |
| BC-VAL-02 | bulkApprove | `trip_ids` => required|array, `action` => required|in:approve,unapprove | `TripController:706-709` | NONE (adequate) |
| BC-VAL-03 | toggleApproval | No trip status validation — any trip status can be approved | GAP — no guard | HIGH |
| BC-VAL-04 | bulkApprove | No validation that trip_ids contain only integers | `whereIn('id', $request->trip_ids)` accepts mixed types | LOW |

### 5.3 Authorization (Permission Gates)

| BC ID | Permission | Method | Behavior | Location |
|-------|-----------|--------|----------|----------|
| BC-AUTH-01 | tenant.trip-approve.viewAny | index() via tab | Without → 403 or tab hidden | `tripmanagement.blade.php:22` |
| BC-AUTH-02 | tenant.trip-approve.approve | toggleApproval() | Without → 403 | `TripController:634` |
| BC-AUTH-03 | tenant.trip-approve.bulkApprove | bulkApprove() | Without → 403 | `TripController:704` |
| BC-AUTH-04 | tenant.trip-approve.view | (used in blade action column) | Without → action button hidden | `index.blade.php:122` |
| BC-AUTH-05 | tenant.trip-approve.edit | (used in blade) | Without → edit remark button hidden | `index.blade.php:127` |
| BC-AUTH-06 | tenant.trip-approve.delete | (used in blade @canany) | Without → action column hidden — but no actual delete button rendered | `index.blade.php:73` |
| BC-AUTH-07 | tenant.transport.viewAny | index() parent gate | Without → 403 on entire transport module | `TripMgmtController:38` |
| BC-AUTH-08 | tenant.trip-approve.status | (used in blade for Approval column th/td) | Without → approval switch column hidden | `index.blade.php:70` |
| BC-AUTH-09 | tenant.trip-approve.reject | policy defined | No controller method uses this permission | GAP — orphaned |

### 5.4 Business Logic

| BC ID | Condition | Expected Behavior | Location |
|-------|-----------|-------------------|----------|
| BC-BIZ-01 | Approve single trip (status=1) | approved=1, approved_by set, approved_at=now; VndUsageLog created with distance calculation; JSON 'Trip approved' | `TripController:647-676` |
| BC-BIZ-02 | Unapprove single trip (status=0) | approved=0, approved_by=null, approved_at=null; VndUsageLog deleted; JSON 'Trip disapproved' | `TripController:678-694` |
| BC-BIZ-03 | Approve — VndUsageLog creation | firstOrCreate by remarks "Trip Approved (Trip ID: {id})"; sets vendor_id, agreement_item_id, usage_date, qty_used=distance, logged_by | `TripController:662-673` |
| BC-BIZ-04 | Approve — no vendor on vehicle | Optional chain: vendor check `if ($vendor && $vendor->id)` — skips log creation if no vendor | `TripController:660` |
| BC-BIZ-05 | Bulk approve — skip already approved | foreach: if trip->approved, continue; only processes unapproved | `TripController:743-745` |
| BC-BIZ-06 | Bulk approve — duplicate VndUsageLog prevention | Uses `exists()` check before create (DIFFERENT from toggleApproval's firstOrCreate — inconsistent) | `TripController:764-769` |
| BC-BIZ-07 | Bulk unapprove | Deletes VndUsageLog by remarks; resets approval fields | `TripController:720-736` |
| BC-BIZ-08 | Distance calculation | `max(0, round($endOdo - $startOdo, 2))` — never negative | `TripController:645` (toggle), `761` (bulk) |
| BC-BIZ-09 | toggleApproval — no findOrFail | Uses `TptTrip::find($request->id)` — returns 404 JSON manually if null | `TripController:637-640` |
| BC-BIZ-10 | Bulk approve — `whereIn` with empty array | `whereIn('id', [])` returns empty collection → no trips processed; success message still shows count | `TripController:711, 785` |
| BC-BIZ-11 | toggleApproval — status field not validated | `$request->status` used directly; no boolean/integer casting | `TripController:647` |
| BC-BIZ-12 | toggleApproval — Auth::user() not checked | `Auth::user()->id` could throw if session expired | `TripController:653` |

### 5.5 Policy — `TransportTripApprovePolicy`

Policy file found at `Modules/Transport/Policies/TransportTripApprovePolicy.php` (89 lines).

| BC ID | Method | Permission | Confirmed By | Code Location |
|-------|--------|------------|--------------|---------------|
| BC-POL-01 | viewAny() | tenant.trip-approve.viewAny | Dusk test `test_forbidden_without_view_any_permission` | `TransportTripApprovePolicy:13-16` |
| BC-POL-02 | view() | tenant.trip-approve.view | Dusk test `grantTripApprovePermissions()` | `TransportTripApprovePolicy:21-24` |
| BC-POL-03 | approve() | tenant.trip-approve.approve | Dusk test `test_forbidden_without_approve_permission` | `TransportTripApprovePolicy:29-32` |
| BC-POL-04 | bulkApprove() | tenant.trip-approve.bulkApprove | Dusk test `test_forbidden_without_bulk_approve_permission` | `TransportTripApprovePolicy:69-72` |
| BC-POL-05 | edit() | tenant.trip-approve.edit | Dusk test `grantTripApprovePermissions()` | `TransportTripApprovePolicy:29-32` |
| BC-POL-06 | delete() | tenant.trip-approve.delete | Dusk test `grantTripApprovePermissions()` | uses TripPolicy delete |
| BC-POL-07 | — (parent gate) | tenant.transport.viewAny | Dusk test `grantTripApprovePermissions()` | `TripMgmtController:38` |

### 5.6 Policy Methods — Controller Coverage Analysis

| Method in Policy | Controller Uses It? | Route Exists? | Gap Severity |
|-----------------|---------------------|---------------|-------------|
| viewAny() | Yes — tab gate (blade @can + nav-tab permission key) | N/A (tab system) | — |
| view() | Indirect — blade `@can('tenant.trip-approve.view')` on eye button | Yes — TripController@show at `/trip/{id}` | — |
| approve() | Yes — toggleApproval | POST `/transport/trip/toggle-approve` | — |
| reject() | **No** | **No** | **HIGH** — Policy has reject but no controller/route uses it |
| viewHistory() | **No** | **No** | **MEDIUM** — Policy has viewHistory but no UI/route |
| export() | **No** | **No** | **MEDIUM** — Policy has export but no implementation |
| print() | **No** | **No** | **LOW** — Policy has print but no implementation |
| bulkApprove() | Yes — bulkApprove | POST `/transport/trip/bulk-approve` | — |
| viewPending() | **No** | **No** | **LOW** — Policy has viewPending; filtering exists via approval_status filter |
| override() | **No** | **No** | **LOW** — Policy has override but no use case defined |

### 5.7 BC-BIZ-DEEP (Extended Business Logic Analysis — 40+ Scenarios)

| BC ID | Scenario | Trigger | Code Path | Expected Behavior | Gap Analysis |
|-------|----------|---------|-----------|-------------------|--------------|
| BC-BIZ-D01 | Approve with zero odometer (both 0) | toggleApproval status=1, start_odo=0, end_odo=0 | `max(0, round(0-0, 2))` = 0 | VndUsageLog created with qty_used=0.00 | Valid edge case |
| BC-BIZ-D02 | Approve with negative distance (end < start) | toggleApproval status=1, start_odo=100, end_odo=50 | `max(0, round(50-100, 2))` = max(0, -50) = 0 | VndUsageLog created with qty_used=0.00 | max() clamp works correctly |
| BC-BIZ-D03 | Approve with null odometer | toggleApproval status=1, start_odo=NULL, end_odo=NULL | `(float)(null??0) = 0` → max(0, 0-0) = 0 | VndUsageLog created with qty_used=0.00 | Null coalescing prevents error |
| BC-BIZ-D04 | Approve same trip twice | First toggleApproval status=1, second toggleApproval status=1 | firstOrCreate finds existing log → no duplicate | Second approve returns success, no duplicate log | firstOrCreate prevents duplicate |
| BC-BIZ-D05 | Approve, then unapprove, then approve again | toggleApproval 1→0→1 | VndUsageLog deleted on unapprove, recreated on approve | Full lifecycle works | Log identified by remarks string |
| BC-BIZ-D06 | Bulk approve with mix of approved/unapproved | 3 approved + 2 unapproved in trip_ids | Loop skips approved (continue), processes 2 | Success message: "5 trip(s) updated" — **misleading** | 🔴 `count($request->trip_ids)` includes skipped |
| BC-BIZ-D07 | Bulk approve with all already approved | trip_ids all have approved=1 | Loop skips all, no updates | VndUsageLog: none created. JSON: "N trip(s) updated" — all skipped | 🔴 Misleading success count |
| BC-BIZ-D08 | Bulk unapprove with all already unapproved | trip_ids all have approved=0 | Deletes VndUsageLog by remarks (may find none), resets approval (already 0) | No error, redundant updates | Idempotent but wasteful |
| BC-BIZ-D09 | Bulk approve with trip from different tenant | Cross-tenant trip_id in trip_ids | `whereIn('id', ...)` has no tenant scope | Could approve cross-tenant trips | 🔴 No tenant isolation in query |
| BC-BIZ-D10 | VndUsageLog relationship chain null | Vehicle has no vendor OR vendor has no agreement | `optional($vendor->agreement?->agreementSingleItem)->id` = null | VndUsageLog created with agreement_item_id = NULL | Silent null in foreign key |
| BC-BIZ-D11 | Approve trip with 'Completed' status | toggleApproval, trip status='Completed' | No status check, approval proceeds | Trip approved | Correct flow |
| BC-BIZ-D12 | Approve trip with 'Scheduled' status (not started) | toggleApproval, trip status='Scheduled' | No status check, approval proceeds | Trip approved despite not being completed | 🔴 No business logic guard |
| BC-BIZ-D13 | Approve trip with 'Ongoing' status (in progress) | toggleApproval, trip status='Ongoing' | No status check, approval proceeds | Trip approved while trip is still active | 🔴 No business logic guard |
| BC-BIZ-D14 | Approve trip with 'Cancelled' status | toggleApproval, trip status='Cancelled' | No status check, approval proceeds | Trip approved for cancelled trip | 🔴 Illogical approval |
| BC-BIZ-D15 | Bulk unapprove — VndUsageLog doesn't exist | No prior VndUsageLog for trip ID | `where('remarks', "...")->delete()` deletes 0 rows | No error, continues | Silent skip |
| BC-BIZ-D16 | toggleApproval with status=1 but request->id is null | Missing id parameter | `TptTrip::find(null) = null`, JSON 404 | 'Trip not found.' | No 400 validation for missing id |
| BC-BIZ-D17 | toggleApproval with status=0 but trip never approved | approved already 0, approved_by null, approved_at null | Sets to 0/null/null (redundant), deletes VndUsageLog (may not exist) | Redundant but harmless | Idempotent |
| BC-BIZ-D18 | toggleApproval — message wording 'disapproved' vs 'unapproved' | status=1 → 'Trip approved'; status=0 → 'Trip disapproved' | JSON response key 'message' | Response uses 'disapproved', UI uses 'unapprove' — inconsistent wording | 🔴 Minor inconsistency |
| BC-BIZ-D19 | Bulk approve — agreement_item_id direct chain failure | `$trip->routeScheduler->vehicle->vendor->agreement->agreementSingleItem` | Any null in chain before vendor → ErrorException | 🔴 Potential crash if chain breaks | `optional()` only wraps final `->id` |
| BC-BIZ-D20 | Bulk approve — VndUsageLog remarks hardcoded string | 'Trip Approved (Trip ID: {$trip->id})' | consistent with toggleApproval | Same string used for both single and bulk | Fragile — if format changes, orphaned logs |
| BC-BIZ-D21 | toggleApproval — status=1 but no trip_date on model | trip_date not validated as required | `$trip->trip_date ?? now()` | Falls back to current date for usage_date | Safe fallback |
| BC-BIZ-D22 | Bulk approve — trip_ids with duplicate values | trip_ids=[5,5,5] | `whereIn('id', [5,5,5])` returns trip 5 once | Only 1 trip processed despite 3 IDs | SQL dedup by whereIn |
| BC-BIZ-D23 | toggleApproval — approve trip that is soft-deleted | Soft-deleted trip | `TptTrip::find($id)` — SoftDeletes trait excludes trashed | Returns null, JSON 404 | find() respects SoftDeletes |
| BC-BIZ-D24 | toggleApproval — invalid status field value (string 'abc') | status='abc' | `$request->status == 1` → 'abc' != 1 → enters disapproved branch | Treated as unapprove | Loose comparison quirk |
| BC-BIZ-D25 | toggleApproval — status=0 but VndUsageLog was already deleted manually | Log manually removed | `where('remarks',"...")->delete()` deletes 0 rows | No error, disapproval succeeds | Silent skip |
| BC-BIZ-D26 | Bulk approve — action='approve' with empty $trips collection | No matching IDs in DB | foreach runs 0 iterations | Response: '0 trip(s) updated' | Validation passes, no-op |
| BC-BIZ-D27 | Bulk approve — VndUsageLog create with agreement_item_id from different tenant | Cross-tenant vendor agreement | `optional(...)->id` fetches across tenant boundaries | Potential data leak if tenancy not isolated | Depends on tenancy implementation |
| BC-BIZ-D28 | Toggle approval with Auth user session expired | Timed-out session | `Auth::user()` returns null → `null->id` → ErrorException | 🔴 ErrorException: Call to member function id on null | No user authentication check inside method |
| BC-BIZ-D29 | Bulk approve with trip_ids containing string values | trip_ids=['abc','def'] | `whereIn('id', ['abc','def'])` → MySQL casts to 0 | Returns trips where id=0 (if any exist) | SQL injection vector possible |
| BC-BIZ-D30 | Bulk approve with action='approve' + trip with no routeScheduler relationship | route_scheduler_id = NULL | `$trip->routeScheduler` is null → `->vehicle` on null | 🔴 ErrorException | No null check on routeScheduler in bulk path |
| BC-BIZ-D31 | Approve trip with floating point odometer edge case | start=0.01, end=0.02 | `max(0, round(0.01, 2))` = 0.01 | Log created with qty_used=0.01 | Precision maintained |
| BC-BIZ-D32 | Bulk approve with 500 trip_ids in single request | 500 valid IDs | Loop iterates 500 times, creates 500 VndUsageLogs | Potential memory/timeout issue | No batch processing |
| BC-BIZ-D33 | toggleApproval — status=1 boolean true (not int) | status=true (JS boolean) | `true == 1` → true | Enters approve branch | Loose comparison works |
| BC-BIZ-D34 | Bulk approve — routeScheduler to vehicle chain has soft-deleted vehicle | vehicle_id FK points to soft-deleted vehicle | `$trip->routeScheduler->vehicle` returns null (SoftDeletes) | vendor access fails → ErrorException | 🔴 Model::find excludes trashed by default |
| BC-BIZ-D35 | toggleApproval — approved_by set to non-existent user ID | `Auth::user()->id` references valid user | No FK validation | approved_by set to valid ID | DB FK constraint ensures integrity |
| BC-BIZ-D36 | Approve trip with max decimal precision odometer | start=99999999.99, end=99999999.99 | `max(0, round(0, 2)) = 0.00` | Works within DECIMAL(10,2) limits | Odometer limit = 10^8 |
| BC-BIZ-D37 | Bulk approve — whereIn with string trip_ids | trip_ids=['abc','def'] | `whereIn('id', ['abc','def'])` → MySQL casts to 0 | Returns trips with id=0 if any exist | SQL injection risk (LOW) |
| BC-BIZ-D38 | toggleApproval — Auth user deleted between requests | Session user deleted by admin concurrently | `Auth::user()` returns null user model | `Auth::user()->id` returns guest ID or throws | Depends on Auth implementation |
| BC-BIZ-D39 | Bulk approve — trip_ids containing both valid and cross-tenant IDs | Mixed tenant IDs | No tenant scope in whereIn | All approved regardless of tenant | 🔴 Tenant isolation gap |
| BC-BIZ-D40 | Approve trip with pending incident linked to trip | Trip has unresolved incident | No check on incident status | Approval proceeds with open incident | No cross-entity validation |
| BC-BIZ-D41 | Bulk approve — trips with mixed vendor assignment | Some trips have vendor, some don't | Each trip processed independently per its vehicle's vendor | VndUsageLog created only for trips with vendor | Expected per-vendor behavior |
| BC-BIZ-D42 | Approve trip after driver license expired but trip already created | Trip created before license expiry, approved after | `creating()` hook only fires on create, not on update | Approval succeeds (model boot does not revalidate) | License expiry not rechecked on approval |
| BC-BIZ-D43 | Bulk approve — whereIn returns empty collection due to all soft-deleted | All trip_ids reference soft-deleted trips | `whereIn` respects SoftDeletes → returns empty | No trips processed, '0 trip(s) updated' | Silent no-op |
| BC-BIZ-D44 | toggleApproval — status=1 integer vs status='1' string | Both int 1 and string '1' passed | Loose `== 1` comparison | Both enter approve branch | Expected PHP behavior |
| BC-BIZ-D45 | Bulk approve — action='approve' with 1000 trip_ids performance | Large payload | Loop with 1000 iterations, each doing DB writes | May exceed execution time/memory limits | No batch/chunk processing |
| BC-BIZ-D46 | Approve trip with remarks containing SQL injection attempt | remarks field with `'; DROP TABLE tpt_trip; --` | Stored as literal string in VndUsageLog | No injection — Eloquent parameterizes | Safe via ORM |
| BC-BIZ-D47 | Bulk unapprove — VndUsageLog soft-delete vs forceDelete | VndUsageLog uses SoftDeletes trait | `->delete()` soft-deletes the log | Log moved to trash, not permanently deleted | Soft delete may leave recoverable records |
| BC-BIZ-D48 | toggleApproval — approve with status='on' (from HTML checkbox) | HTML checkbox submits 'on' when checked | `'on' == 1` → false | Enters disapproved branch | 🔴 HTML checkbox 'on' value causes unexpected unapprove |

---

### 5.8 Compliance & Legal Conditions (Trip Approval)

| BC ID | Condition | Expected Behavior | Source |
|-------|-----------|-------------------|--------|
| BC-COMP-01 | Driver license expiry checked at trip creation | `creating()` hook throws DomainException if license expired before trip_date | `TptTrip.php:69-77` |
| BC-COMP-02 | Vehicle fitness certificate checked at trip creation | `creating()` hook throws DomainException if fitness expired | `TptTrip.php:82-86` |
| BC-COMP-03 | Vehicle insurance checked at trip creation | `creating()` hook throws DomainException if insurance expired | `TptTrip.php:87-93` |
| BC-COMP-04 | License/insurance not rechecked on approval | These checks only fire on `creating()`, not on `updating()` | Approval does not trigger these checks |
| BC-COMP-05 | No compliance check during trip approval | Approval only checks permission, not trip validity | `TripController:634` |
| BC-COMP-06 | Status transition enforced on trip save | `saving()` hook validates FSM transitions | `TptTrip.php:99-117` |
| BC-COMP-07 | Status transition NOT enforced on approval update | `toggleApproval` directly calls `update()` which fires `saving()` but approval does not change `status` field | Trip status unchanged during approval |

---

## 6. Test Case List

### 6.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | Trip Approve Tab Loads | `/transport/trip-management?tab=trip_approve` shows trip grid with approval filters | — | — | ⬜ |
| TC-P02 | Approve Single Trip (Completed) | POST `/transport/trip/toggle-approve` with id=X, status=1 → approved=1; VndUsageLog created | — | — | ⬜ |
| TC-P03 | Unapprove Single Trip | POST `/transport/trip/toggle-approve` with status=0 → approved=0; VndUsageLog deleted | — | — | ⬜ |
| TC-P04 | Bulk Approve Multiple Trips | POST `/transport/trip/bulk-approve` with trip_ids=[1,2,3], action=approve → all 3 approved; VndUsageLogs created | — | — | ⬜ |
| TC-P05 | Bulk Unapprove Multiple Trips | POST `/transport/trip/bulk-approve` with action=unapprove → all approval fields reset; logs deleted | — | — | ⬜ |
| TC-P06 | Bulk Approve — Skip Already Approved | Mix of approved + unapproved trips → only unapproved processed; skips logged | — | — | ⬜ |
| TC-P07 | Filter by Approval Status | Select "Approved" → only approved trips; "Unapproved" → only unapproved | — | — | ⬜ |
| TC-P08 | Approve Trip Without Vendor (no vendor log) | Vehicle has no vendor → approval succeeds; no VndUsageLog created | — | — | ⬜ |
| TC-P09 | Empty State — No Trips | "No Data Found" | — | — | ⬜ |
| TC-P10 | Table Displays Trip Data | Table renders with columns: Trip Date, Route, Vehicle, Driver, Status, Approval; approve-switch present | — | — | ⬜ |
| TC-P11 | Search by Route/Vehicle/Driver | Search by route name → filtered results match | — | — | ⬜ |
| TC-P12 | Pagination Shows with 11+ Records | Pagination controls visible when records exceed per-page limit | — | — | ⬜ |
| TC-P13 | Pagination Hidden with <=10 Records | Pagination hidden when records fit on one page | — | — | ⬜ |
| TC-P14 | Pagination Navigates to Page 2 and Back | Click page 2 → URL contains page=2 & tab=trip_approve; click page 1 → returns | — | — | ⬜ |
| TC-P15 | Pagination Preserves Tab Parameter | Pagination links contain `tab=trip_approve` query parameter | — | — | ⬜ |
| TC-P16 | DDL Schema Validation | `tpt_trip` table has correct columns: approved, approved_by, approved_at, soft-delete | — | — | ⬜ |
| TC-P17 | Approve Trip — VndUsageLog qty_used equals distance | start_odo=100, end_odo=150 → qty_used=50.00 | — | — | ⬜ |
| TC-P18 | Approve Trip Zero Distance | start_odo=100, end_odo=100 → qty_used=0.00 | — | — | ⬜ |
| TC-P19 | Approve Trip Negative Odometer | start_odo=150, end_odo=100 → qty_used=0.00 (clamped) | — | — | ⬜ |
| TC-P20 | Bulk Approve VndUsageLog Created for Each Trip | 3 trips with varying distances → 3 VndUsageLogs with correct qty_used | — | — | ⬜ |
| TC-P21 | Bulk Unapprove — VndUsageLogs Deleted | Previously approved trips → bulk unapprove removes all VndUsageLogs | — | — | ⬜ |
| TC-P22 | Approve Then Approve Again (Duplicate) | Toggle approve same trip twice → VndUsageLog not duplicated | — | — | ⬜ |
| TC-P23 | Bulk Approve — Empty trip_ids Array Returns 0 Success | trip_ids=[] → JSON '0 trip(s) updated successfully' | — | — | ⬜ |
| TC-P24 | Approve Trip with approval_status Filter Cleared | Set filter then reset → all trips visible | — | — | ⬜ |
| TC-P25 | Bulk Approve with Mix of Completed and Uncompleted Trips | Both Completed and Scheduled trips included → all approved (no status guard) | — | — | ⬜ |
| TC-P26 | Approve Trip After Trip Date Changed | Trip date changed after creation but before approval → VndUsageLog usage_date uses updated trip_date | — | — | ⬜ |
| TC-P27 | Bulk Approve with Large Set (50 trips) | 50 unapproved trips → all approved within timeout | — | — | ⬜ |
| TC-P28 | Toggle Approve from AJAX Switch in UI | Click approve-switch → AJAX POST → switch stays checked | — | — | ⬜ |
| TC-P29 | Bulk Action Bar Appears on Checkbox Select | Select 1+ checkboxes → bulkActionBar visible with count | — | — | ⬜ |
| TC-P30 | Bulk Action Bar Hides on Deselect All | Deselect all → bulkActionBar hidden again | — | — | ⬜ |
| TC-P31 | Select All Checkbox Toggles All Rows | Click #selectAll → all trip-checkboxes checked; click again → all unchecked | — | — | ⬜ |
| TC-P32 | Approve Trip Sets approved_by to Auth User ID | approved_by = logged-in user's ID | — | — | ⬜ |
| TC-P33 | Approve Trip Sets approved_at to Current Timestamp | approved_at within 5 seconds of request time | — | — | ⬜ |
| TC-P34 | Bulk Approve Preserves Helper ID on Trip | After approval, helper_id field unchanged | — | — | ⬜ |

### 6.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | Approve Non-Existent Trip | POST `/transport/trip/toggle-approve` with id=99999 → find() fails → error JSON | — | — | ⬜ |
| TC-N02 | Missing trip_id in toggleApproval | No validation → `$request->id` is null → error | — | — | ⬜ |
| TC-N03 | Bulk Approve Without trip_ids | POST `/transport/trip/bulk-approve` no trip_ids → validation error: 'trip_ids is required' | — | — | ⬜ |
| TC-N04 | Bulk Approve Invalid Action | POST `/transport/trip/bulk-approve` with action=invalid → validation error: 'action must be approve or unapprove' | — | — | ⬜ |
| TC-N05 | Bulk Approve Empty trip_ids Array | `whereIn('id', [])` returns empty collection → forEach does nothing; JSON success with 0 message (misleading) | — | — | ⬜ |
| TC-N06 | Permission 403 — Without tenant.trip-approve.approve | 403 on toggleApproval | — | — | ⬜ |
| TC-N07 | Permission 403 — Without tenant.trip-approve.bulkApprove | 403 on bulkApprove | — | — | ⬜ |
| TC-N08 | Guest Access (Unauthenticated) | Redirect to `/login` | — | — | ⬜ |
| TC-N09 | Permission 403 — Without tenant.trip-approve.viewAny on Tab | Tab access returns 403/Forbidden | — | — | ⬜ |
| TC-N10 | XSS Injection in Remarks | `<script>` stored literal; Blade escapes | — | — | ⬜ |
| TC-N11 | Bulk Approve with Non-Array trip_ids | String or null → validation fails | — | — | ⬜ |
| TC-N12 | toggleApproval with status=2 (invalid) | No validation → status cast to int → update happened with status=2 but treated as truthy | — | — | ⬜ |
| TC-N13 | Bulk Approve Mix of Valid and Invalid trip_ids | whereIn only returns matching rows; non-existent IDs silently ignored | — | — | ⬜ |
| TC-N14 | toggleApproval with String status='abc' | Loose comparison 'abc' != 1 → enters disapproval branch (unexpected behavior) | — | — | ⬜ |
| TC-N15 | Permission 403 — Without tenant.trip-approve.status in Blade | Approval column hidden from view | — | — | ⬜ |
| TC-N16 | Bulk Approve with Duplicate trip_ids | trip_ids=[5,5,5] → SQL dedup returns single trip | — | — | ⬜ |
| TC-N17 | Bulk Approve with Soft-Deleted Trip | Soft-deleted trip in trip_ids → whereIn only returns non-deleted; trip not processed | — | — | ⬜ |
| TC-N18 | CSRF Token Missing on toggle-approve | POST without _token → 419 Page Expired | — | — | ⬜ |
| TC-N19 | toggleApproval with status as boolean true (JSON true) | true == 1 → enters approve branch (correct) | — | — | ⬜ |

### 6.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|----------------|---------|---------|--------|
| TC-D01 | A | Approve Then Unapprove — VndUsageLog Lifecycle | Log created on approve; deleted on unapprove | — | — | ⬜ |
| TC-D02 | B | VndUsageLog firstOrCreate Prevents Duplicates | Approve same trip twice → second approve finds existing log via firstOrCreate | — | — | ⬜ |
| TC-D03 | C | Trip Deletion — VndUsageLog Orphaned | VndUsageLog remains after trip deletion (no FK constraint) | — | — | ⬜ |
| TC-D04 | D | Approve Trip — Vendor Usage Log Created | `VndUsageLog` record with qty_used=distance, vendor_id from vehicle->vendor | — | — | ⬜ |
| TC-D05 | E | Bulk Approve + Unapprove — No Double Processing | Bulk approve then bulk unapprove same trips → each action processes correctly | — | ⬜ | ⬜ |
| TC-D06 | F | Approve with Zero/Null Odometer Readings | Both odometer readings 0 or null → qty_used=0 in VndUsageLog | — | — | ⬜ |
| TC-D07 | G | Activity Log — Approve Single Trip | `activityLog()` called on toggleApproval with status=1 | — | — | ⬜ |
| TC-D08 | H | Activity Log — Unapprove Single Trip | `activityLog()` called on toggleApproval with status=0 | — | — | ⬜ |
| TC-D09 | I | Activity Log — Bulk Approve | `activityLog()` called per trip in bulkApprove with action=approve | — | — | ⬜ |
| TC-D10 | J | Activity Log — Bulk Unapprove | `activityLog()` called per trip in bulkApprove with action=unapprove | — | — | ⬜ |
| TC-D11 | K | VndUsageLog — agreement_item_id Null When No Agreement | Vehicle vendor exists but no agreement → agreement_item_id=NULL | — | — | ⬜ |
| TC-D12 | L | VndUsageLog — vendor_id From Vehicle Chain | Vehicle->routeScheduler->vehicle->vendor_id used | — | — | ⬜ |
| TC-D13 | M | Trip Status Transition — Approve Does Not Change Trip Status | Approve completed trip → status remains 'Completed' | — | — | ⬜ |
| TC-D14 | N | VndUsageLog — logged_by Is Auth User | logged_by = Auth::id() in both single and bulk | — | — | ⬜ |
| TC-D15 | O | VndUsageLog FirstOrCreate With SoftDeletes | VndUsageLog uses SoftDeletes → firstOrCreate may find soft-deleted log if not excluded | — | — | ⬜ |
| TC-D16 | P | Approve With Different Auth Users | User1 approves → approved_by=User1; User2 unapproves → approved_by=NULL; User3 approves again → approved_by=User3 | — | — | ⬜ |
| TC-D17 | Q | Bulk Approve — VndUsageLog Deletion Cascade | Trip approved → VndUsageLog created → Trip unapproved → VndUsageLog deleted → Trip approved again → VndUsageLog recreated | — | — | ⬜ |
| TC-D18 | R | TptTrip Model Boot — License/Insurance Validation (creating hook) | Creating trip with expired driver license → DomainException thrown (affects approval data setup) | — | — | ⬜ |

### 6.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|-----------------|---------|---------|--------|
| TC-CR01 | CR | P1 | Controller — Gate::authorize() in toggleApproval | `Gate::authorize('tenant.trip-approve.approve')` at line 634 | — | — | ◌ |
| TC-CR02 | CR | P1 | Controller — Gate::authorize() in bulkApprove | `Gate::authorize('tenant.trip-approve.bulkApprove')` at line 704 | — | — | ◌ |
| TC-CR03 | CR | P1 | Controller — No activityLog in approval methods | Trip approval does NOT log to activity_log | — | — | ◌ |
| TC-CR04 | CR | P1 | Controller — No input validation in toggleApproval | `$request->id` and `$request->status` not validated at lines 632-634 | — | — | ◌ |
| TC-CR05 | CR | P1 | Controller — Distance calculation | `max(0, round($endOdo - $startOdo, 2))` at lines 645, 761 | — | — | ◌ |
| TC-CR06 | CR | P1 | Controller — VndUsageLog firstOrCreate in toggleApproval | Uses firstOrCreate to prevent duplicate logs at line 662 | — | — | ◌ |
| TC-CR07 | CR | P1 | Controller — VndUsageLog exists() check in bulkApprove | Checks exists() before creating at line 764; firstOrCreate NOT used (inconsistent with toggle) | — | — | ◌ |
| TC-CR08 | CR | P1 | Controller — Redirect vs JSON | Both toggleApproval and bulkApprove return JSON | — | — | ◌ |
| TC-CR09 | CR | P1 | Policy — Methods confirmed in Dusk test | 6 confirmed methods: viewAny, view, approve, bulkApprove, edit, delete. 6 defined but not tested: reject, viewHistory, export, print, viewPending, override | — | — | ◌ |
| TC-CR10 | CR | P1 | Policy — No soft delete/restore/forceDelete for approval | Approval has no trash or permanent delete operations | — | — | ◌ |
| TC-CR11 | CR | P1 | Routes — toggle-approve and bulk-approve | Both POST routes defined in web.php:165-166 under `/transport/trip/` prefix | — | — | ◌ |
| TC-CR12 | CR | P1 | Gap — No status transition check before approval | Trip can be approved even if status is 'Scheduled' or 'Ongoing' — no enforcement of Completed status | — | — | ◌ |
| TC-CR13 | CR | P1 | Gap — No audit log for approval/disapproval actions | No activity_log entry for approve/unapprove. Compare with update() at line 378 which calls activityLog() | — | — | ◌ |
| TC-CR14 | CR | P1 | Gap — VndUsageLog deletion by remarks string is fragile | `where('remarks', "Trip Approved (Trip ID: {$trip->id})")->delete()` at lines 688-691 — if remarks format changes, log orphaned | — | — | ◌ |
| TC-CR15 | CR | P1 | Gap — Agreement relationship chain may be null | `optional($vendor->agreement?->agreementSingleItem)->id` at line 666 — long optional chain; null if any part missing | — | — | ◌ |
| TC-CR16 | CR | P2 | Gap — Bulk approve success message counts input not processed | `count($request->trip_ids)` at line 785 includes skipped/already-approved trips | — | — | ◌ |
| TC-CR17 | CR | P2 | Gap — Bulk approve uses exists() while toggle uses firstOrCreate | Inconsistent duplicate prevention between single (firstOrCreate) and bulk (exists+create) methods | — | — | ◌ |
| TC-CR18 | CR | P2 | Gap — No delete button in trip_approve action column | Blade `@can('tenant.trip-approve.delete')` in @canany at line 73 but no delete form/button rendered | — | — | ◌ |
| TC-CR19 | CR | P2 | Gap — trip_approve pagination does not append tab parameter | `{{ $TripData->links() }}` at line 146 without `->appends(['tab' => 'trip_approve'])` | — | — | ◌ |
| TC-CR20 | CR | P2 | Gap — Bulk approve direct optional chain without null safety | `optional($trip->routeScheduler->vehicle->vendor->agreement->agreementSingleItem)->id` at line 772 — only final ->id has optional() | — | — | ◌ |
| TC-CR21 | CR | P2 | Policy — reject() defined but no controller action | `reject` method at policy line 37, no route or controller method references `tenant.trip-approve.reject` | — | — | ◌ |
| TC-CR22 | CR | P2 | Policy — viewHistory() defined but no controller action | `viewHistory` at policy line 45, no implementation | — | — | ◌ |
| TC-CR23 | CR | P2 | Policy — export() defined but no controller action | `export` at policy line 53, no implementation | — | — | ◌ |
| TC-CR24 | CR | P2 | Policy — print() defined but no controller action | `print` at policy line 61, no implementation | — | — | ◌ |
| TC-CR25 | CR | P2 | Policy — viewPending() defined but no controller action | `viewPending` at policy line 77, no implementation | — | — | ◌ |
| TC-CR26 | CR | P2 | Policy — override() defined but no controller action | `override` at policy line 85, no implementation | — | — | ◌ |
| TC-CR27 | CR | P2 | Gap — Blade uses @canany for single permission | `@canany(['tenant.trip-approve.status'])` at line 70 — should be `@can` for single permission | — | — | ◌ |
| TC-CR28 | CR | P2 | Gap — delete permission in @canany but no delete UI | Action column @canany at line 73 includes 'delete' but only view and edit buttons rendered | — | — | ◌ |
| TC-CR29 | CR | P2 | Gap — Trip approval has no concurrent/race condition guard | Two simultaneous POST requests could both pass Gate check before first completes | — | — | ◌ |
| TC-CR30 | CR | P2 | Gap — Pagination not using unique paginator name | `$TripData` paginated with default page name (no `*_page` suffix as specified in gold standard) | — | — | ◌ |
| TC-CR31 | CR | P2 | Gap — No Auth::check() before Auth::user() | If session expired, `Auth::user()` returns null → `null->id` ErrorException | — | — | ◌ |
| TC-CR32 | CR | P2 | Gap — VndUsageLog soft-delete not considered in exists() | `exists()` at line 764 checks non-deleted only; firstOrCreate at line 662 also checks non-deleted only | — | — | ◌ |
| TC-CR33 | CR | P2 | Gap — toggleApproval checks `$request->status == 1` (loose) | Loose comparison can cause unexpected branch entry for edge values | — | — | ◌ |
| TC-CR34 | CR | P2 | Gap — No bulk select limit on UI | User can select all trips on all pages (if pagination broken), causing large bulk request | — | — | ◌ |

### 6.5 CODE-TRACE Entries (Line-by-Line Execution Trace)

| CT ID | Method | File:Line | Trace Description |
|-------|--------|-----------|-------------------|
| CT-01 | toggleApproval | TripController:632 | Method signature: `public function toggleApproval(Request $request)` — uses base Request, no FormRequest |
| CT-02 | toggleApproval | TripController:634 | `Gate::authorize('tenant.trip-approve.approve')` — throws `AuthorizationException` (403) if user lacks 'approve' permission |
| CT-03 | toggleApproval | TripController:637 | `$trip = TptTrip::find($request->id)` — Eloquent find() respects SoftDeletes (trashed trips excluded). `$request->id` raw input |
| CT-04 | toggleApproval | TripController:638-640 | Null check: `if (!$trip)` returns JSON 404 `['status'=>false, 'message'=>'Trip not found.']` with HTTP 404 |
| CT-05 | toggleApproval | TripController:643 | `$startOdo = (float) ($trip->start_odometer_reading ?? 0)` — null-coalescing to 0, cast to float |
| CT-06 | toggleApproval | TripController:644 | `$endOdo = (float) ($trip->end_odometer_reading ?? 0)` — same pattern |
| CT-07 | toggleApproval | TripController:645 | `$distanceUsed = max(0, round($endOdo - $startOdo, 2))` — distance is never negative |
| CT-08 | toggleApproval | TripController:647 | Branch: `if ($request->status == 1)` — loose comparison `==` not strict `===`. Values 1, '1', true pass |
| CT-09 | toggleApproval | TripController:651-655 | Approve: `$trip->update(['approved'=>1, 'approved_by'=>Auth::user()->id, 'approved_at'=>now()])` — 3 fields updated |
| CT-10 | toggleApproval | TripController:657 | `$vendor = optional($trip->routeScheduler?->vehicle?->vendor)` — PHP 8 null-safe operator `?->` stops chain at first null. `optional()` wraps result |
| CT-11 | toggleApproval | TripController:660 | Guard: `if ($vendor && $vendor->id)` — falsy check. If vendor null or id null/0, entire VndUsageLog creation skipped |
| CT-12 | toggleApproval | TripController:662-673 | `VndUsageLog::firstOrCreate(['remarks'=>"Trip Approved (Trip ID: {$trip->id})"], [...])` — unique constraint by remarks string |
| CT-13 | toggleApproval | TripController:666 | `agreement_item_id => optional($vendor->agreement?->agreementSingleItem)->id` — double Optional + null-safe on agreement chain |
| CT-14 | toggleApproval | TripController:667 | `usage_date => $trip->trip_date ?? now()->toDateString()` — fallback to today if trip_date is null |
| CT-15 | toggleApproval | TripController:670 | `qty_used => $distanceUsed` — float value, stored as DECIMAL in DB |
| CT-16 | toggleApproval | TripController:671 | `logged_by => Auth::user()->id` — same as approved_by |
| CT-17 | toggleApproval | TripController:676 | `$message = 'Trip approved'` — message for approve branch |
| CT-18 | toggleApproval | TripController:678 | Else branch: reached when `$request->status != 1` (loose not-equal) |
| CT-19 | toggleApproval | TripController:681-685 | Disapprove: `$trip->update(['approved'=>0, 'approved_by'=>null, 'approved_at'=>null])` — 3 fields reset to null |
| CT-20 | toggleApproval | TripController:688-691 | `VndUsageLog::where('remarks', "Trip Approved (Trip ID: {$trip->id})")->delete()` — deletes by remarks string, no FK |
| CT-21 | toggleApproval | TripController:693 | `$message = 'Trip disapproved'` — message for disapproved branch |
| CT-22 | toggleApproval | TripController:696-700 | Return: `response()->json(['status'=>true, 'message'=>$message])` — always status=true, error returns at line 639 |
| CT-23 | bulkApprove | TripController:702 | Method signature: `public function bulkApprove(Request $request)` — same as toggle, uses base Request |
| CT-24 | bulkApprove | TripController:704 | `Gate::authorize('tenant.trip-approve.bulkApprove')` — different permission from toggleApproval |
| CT-25 | bulkApprove | TripController:706-709 | Validation: `$request->validate(['trip_ids'=>'required|array', 'action'=>'required|in:approve,unapprove'])` |
| CT-26 | bulkApprove | TripController:711 | `$trips = TptTrip::whereIn('id', $request->trip_ids)->get()` — fetches only existing, non-trashed trips matching IDs |
| CT-27 | bulkApprove | TripController:713 | `foreach ($trips as $trip)` — iterates over DB-matched trips only (not input IDs) |
| CT-28 | bulkApprove | TripController:720-736 | Unapprove branch: `$request->action === 'unapprove'` — deletes VndUsageLog by remarks, resets approved=0/null, `continue` |
| CT-29 | bulkApprove | TripController:723-726 | Bulk unapprove log deletion: same remarks pattern as toggleApproval |
| CT-30 | bulkApprove | TripController:729-733 | Bulk unapprove field reset: same pattern as toggleApproval |
| CT-31 | bulkApprove | TripController:735 | `continue` — skips to next iteration after unapprove |
| CT-32 | bulkApprove | TripController:743-745 | Skip guard: `if ($trip->approved) { continue; }` — only for approve action |
| CT-33 | bulkApprove | TripController:752-756 | Approve: same field pattern as toggleApproval — sets approved=1, approved_by, approved_at |
| CT-34 | bulkApprove | TripController:759-761 | Distance calc: identical formula to toggleApproval — `max(0, round($endOdo - $startOdo, 2))` |
| CT-35 | bulkApprove | TripController:764-769 | `$exists = VndUsageLog::where('remarks', "...")->exists()` — checks existence BEFORE create. Different from toggleApproval's firstOrCreate |
| CT-36 | bulkApprove | TripController:770-779 | `if (!$exists) { VndUsageLog::create([...]) }` — manual create after exists check |
| CT-37 | bulkApprove | TripController:771 | `'vendor_id' => optional($trip->routeScheduler->vehicle)->vendor_id` — optional() only wraps vehicle, NOT full chain |
| CT-38 | bulkApprove | TripController:772-774 | `'agreement_item_id' => optional($trip->routeScheduler->vehicle->vendor->agreement->agreementSingleItem)->id` — only `->id` has optional wrapper |
| CT-39 | bulkApprove | TripController:783-786 | Return: `response()->json(['status'=>true, 'message'=>count($request->trip_ids).' trip(s) updated successfully'])` — counts INPUT IDs |
| CT-40 | TripMgmtController.index | TripMgmtController:36 | Method signature: `public function index(Request $request)` — handles all 9 tabs |
| CT-41 | TripMgmtController.index | TripMgmtController:38 | `Gate::authorize('tenant.transport.viewAny')` — parent gate, required for any transport access |
| CT-42 | TripMgmtController.index | TripMgmtController:40-51 | Driver detection: if logged-in user is a driver, filter routes to driver's assigned routes |
| CT-43 | TripMgmtController.index | TripMgmtController:54-71 | Trip ID pre-fetch: find first trip matching date/shift/route filters, merge into request |
| CT-44 | TripMgmtController.index | TripMgmtController:85 | `$TripData = $this->TripQuery($request)->paginate(10)->withQueryString()` — 10 per page, shared tab |
| CT-45 | TripMgmtController.TripQuery | TripMgmtController:364 | Tab filter: `if ($tab === 'daily_trip' || $tab === 'trip_approve')` — shared filter block |
| CT-46 | TripMgmtController.TripQuery | TripMgmtController:366-367 | `if ($request->filled('trip_date'))` — filters by trip_date |
| CT-47 | TripMgmtController.TripQuery | TripMgmtController:371-375 | `if ($request->filled('route_id'))` — filters via routeScheduler relationship |
| CT-48 | TripMgmtController.TripQuery | TripMgmtController:388-391 | `if ($request->filled('approval_status'))` — maps 'approved'=>1, 'unapproved'=>0 |
| CT-49 | TripMgmtController.TripQuery | TripMgmtController:394-396 | `if ($request->filled('status'))` — trip status filter (Scheduled/Ongoing/Completed) |
| CT-50 | TripMgmtController.TripQuery | TripMgmtController:399-413 | Search: OR condition across route name/code, vehicle no, driver name |
| CT-51 | blade index | trip_approve/index.blade.php:1-5 | Tab pane: `<div class="tab-pane fade p-4 bg-white rounded shadow-sm" id="trip_approve-pane">` |
| CT-52 | blade index | trip_approve/index.blade.php:10-32 | Filter form: hidden tab input, approval_status dropdown, search input, submit/reset buttons |
| CT-53 | blade index | trip_approve/index.blade.php:13-17 | Approval status dropdown: options '' (All), 'approved', 'unapproved' |
| CT-54 | blade index | trip_approve/index.blade.php:35-48 | Bulk action bar: hidden initially (`d-none`), shows selected count, Approve/Unapprove buttons |
| CT-55 | blade index | trip_approve/index.blade.php:55 | Select-all checkbox: `#selectAll` in thead |
| CT-56 | blade index | trip_approve/index.blade.php:70-72 | Approval th: `@canany(['tenant.trip-approve.status'])` wraps the `<th>Approval</th>` |
| CT-57 | blade index | trip_approve/index.blade.php:73-75 | Action th: `@canany(['tenant.trip-approve.edit','tenant.trip-approve.delete'])` wraps Action header |
| CT-58 | blade index | trip_approve/index.blade.php:83-86 | Trip checkbox: `<input class="trip-checkbox" value="{{ $item->id }}">` per row |
| CT-59 | blade index | trip_approve/index.blade.php:94-97 | Status badge: `bg-success` for Completed, `bg-warning` for others |
| CT-60 | blade index | trip_approve/index.blade.php:111-118 | Approve switch: `<input class="approve-switch" data-id="{{ $item->id }}" {{ $item->approved ? 'checked' : '' }}>` |
| CT-61 | blade index | trip_approve/index.blade.php:122-124 | View button: `@can('tenant.trip-approve.view')` → eye icon linking to trip show |
| CT-62 | blade index | trip_approve/index.blade.php:127-129 | Edit remark button: `@can('tenant.trip-approve.edit')` → pen icon, modal trigger |
| CT-63 | blade index | trip_approve/index.blade.php:133-138 | Empty state: `<td colspan="10" class="text-center text-muted py-3">No trips found</td>` |
| CT-64 | blade index | trip_approve/index.blade.php:145-147 | Pagination: `{{ $TripData->links() }}` — NO `->appends(['tab' => 'trip_approve'])` |
| CT-65 | blade js | trip_approve/js.blade.php:2 | `$(document).ready(function () {` — jQuery DOM ready |
| CT-66 | blade js | trip_approve/js.blade.php:4-16 | `updateBulkBar()` — shows/hides bulk action bar, updates selected count, handles selectAll state |
| CT-67 | blade js | trip_approve/js.blade.php:18-21 | `#selectAll` handler — checks/unchecks all .trip-checkbox |
| CT-68 | blade js | trip_approve/js.blade.php:26-59 | `.approve-switch` change handler — AJAX POST to toggle-approve, reverts on error, shows toast |
| CT-69 | blade js | trip_approve/js.blade.php:35-42 | Toggle AJAX: url `{{ route('transport.trip.toggle-approve') }}`, data: id, status, _token |
| CT-70 | blade js | trip_approve/js.blade.php:43-49 | Toggle success: `showToast('success', 'Trip Status Updated successfully')` — generic message |
| CT-71 | blade js | trip_approve/js.blade.php:61-62 | Bulk button binding: `#bulkApproveBtn` → `bulkAction('approve')`, `#bulkUnapproveBtn` → `bulkAction('unapprove')` |
| CT-72 | blade js | trip_approve/js.blade.php:64-89 | `bulkAction(action)` — collects checked IDs, POST to bulk-approve, reloads page on success |
| CT-73 | blade js | trip_approve/js.blade.php:72-80 | Bulk AJAX: url `{{ route('transport.trip.bulk-approve') }}`, data: trip_ids, action, _token |
| CT-74 | blade js | trip_approve/js.blade.php:92-101 | `showToast(type, message)` — SweetAlert2 toast notification, 2.5s timer |
| CT-75 | blade js | trip_approve/js.blade.php:122-132 | `.edit-remark-btn` click — opens remark modal, populates trip_id and current remark |
| CT-76 | blade js | trip_approve/js.blade.php:133-159 | `#saveRemarkBtn` click — AJAX POST to update-remark, reloads on success |
| CT-77 | model TptTrip | TptTrip.php:61-97 | `creating()` hook — validates driver license, vehicle fitness, vehicle insurance expiry |
| CT-78 | model TptTrip | TptTrip.php:99-117 | `saving()` hook — enforces status transition FSM (Scheduled→Ongoing/Cancelled→Completed→Terminal) |
| CT-79 | model TptTrip | TptTrip.php:136-138 | `approvedBy()` — belongsTo relationship to User via approved_by FK |
| CT-80 | Tab container | tripmanagement.blade.php:22 | Tab definition: `['id'=>'trip_approve', 'label'=>'Trip Approve', 'icon'=>'fa-solid fa-check', 'permission'=>'tenant.trip-approve.viewAny']` |
| CT-81 | Tab container | tripmanagement.blade.php:46-48 | Include guard: `@can('tenant.trip-approve.viewAny') @include('transport::trip_approve.index') @endcan` |
| CT-82 | Routes | web.php:165 | `Route::post('trip/bulk-approve', [TripController::class, 'bulkApprove'])->name('trip.bulk-approve')` |
| CT-83 | Routes | web.php:166 | `Route::post('trip/toggle-approve', [TripController::class, 'toggleApproval'])->name('trip.toggle-approve')` |
| CT-84 | Dusk test | trn_TripApprove_TestCas.php:711-733 | `grantTripApprovePermissions()` — grants 6 trip-approve + 1 transport permissions |
| CT-85 | Dusk test | trn_TripApprove_TestCas.php:832-858 | `createTripDirectly()` — inserts trip directly into DB bypassing model hooks |
| CT-86 | Tab container | tripmanagement.blade.php:56-58 | Includes: `@include('transport::css.css') @include('transport::js.js') @include('transport::model.model')` — global transport assets |
| CT-87 | blade model | trip_approve/model.blade.php | Remark edit modal: bootstrap modal with #remark_trip_id hidden input, #remark_text textarea, #saveRemarkBtn |
| CT-88 | Dusk test | trn_TripApprove_TestCas.php:36-50 | `setUp()` — initializes tenant URL, admin email/password, calls initializeTenantContext(), resolveAdminUser(), resolveDependencies() |
| CT-89 | Dusk test | trn_TripApprove_TestCas.php:52-61 | `tearDown()` — calls cleanupCreatedTrips(), ends tenancy if initialized |
| CT-90 | Dusk test | trn_TripApprove_TestCas.php:68-138 | `test_ddl_conditions()` — asserts column types, defaults, and indexes for tpt_trip table via information_schema |
| CT-91 | Dusk test | trn_TripApprove_TestCas.php:140-157 | `test_tab_pane_renders()` — visits tab, waits for pane, asserts filter controls, bulk bar, checkboxes |
| CT-92 | Dusk test | trn_TripApprove_TestCas.php:159-182 | `test_table_displays_trip_data()` — creates trip, asserts table columns and approve-switch present |
| CT-93 | Dusk test | trn_TripApprove_TestCas.php:184-213 | `test_search_by_route_vehicle_driver()` — creates 2 trips, searches by route name, asserts results |
| CT-94 | Dusk test | trn_TripApprove_TestCas.php:215-246 | `test_filter_by_approval_status()` — creates approved + unapproved trips, filters each way, verifies via separate browser sessions |
| CT-95 | Dusk test | trn_TripApprove_TestCas.php:248-278 | `test_individual_approve_toggle()` — POST to toggle-approve with status=1, asserts approved=1, approved_by NOT NULL, approved_at NOT NULL |
| CT-96 | Dusk test | trn_TripApprove_TestCas.php:280-308 | `test_individual_unapprove_toggle()` — POST to toggle-approve with status=0, asserts approved=0 |
| CT-97 | Dusk test | trn_TripApprove_TestCas.php:310-345 | `test_bulk_approve_action()` — POST to bulk-approve with 3 trip_ids, asserts all 3 approved=1 |
| CT-98 | Dusk test | trn_TripApprove_TestCas.php:347-378 | `test_bulk_unapprove_action()` — POST to bulk-approve with action=unapprove, asserts all approved=0 |
| CT-99 | Dusk test | trn_TripApprove_TestCas.php:380-395 | `test_empty_state_no_trips()` — cleans all trips, asserts 'No trips found' text |
| CT-100 | Dusk test | trn_TripApprove_TestCas.php:397-419 | `test_pagination_shows_with_11_records()` — creates 11 trips, asserts `.pagination` element present |
| CT-101 | Dusk test | trn_TripApprove_TestCas.php:421-443 | `test_pagination_hidden_with_5_records()` — creates 5 trips, asserts `.pagination` element absent |
| CT-102 | Dusk test | trn_TripApprove_TestCas.php:445-480 | `test_pagination_navigates_to_page_2_and_back()` — clicks page 2 link, asserts URL has page=2 and tab=trip_approve; clicks back to page 1 |
| CT-103 | Dusk test | trn_TripApprove_TestCas.php:482-524 | `test_pagination_preserves_tab_parameter()` — asserts pagination link href contains tab=trip_approve parameter |
| CT-104 | Dusk test | trn_TripApprove_TestCas.php:526-533 | `test_guest_redirect()` — visits tab without auth, asserts redirect to /login |
| CT-105 | Dusk test | trn_TripApprove_TestCas.php:535-565 | `test_403_forbidden()` — revokes viewAny permission, asserts 403/Unauthorized, then restores permissions |
| CT-106 | Dusk test | trn_TripApprove_TestCas.php:567-591 | `test_forbidden_without_view_any_permission()` — creates restricted user without viewAny, asserts 403 |
| CT-107 | Dusk test | trn_TripApprove_TestCas.php:593-617 | `test_forbidden_without_approve_permission()` — restricted user with viewAny but without approve, POST toggle-approve → 403 |
| CT-108 | Dusk test | trn_TripApprove_TestCas.php:619-645 | `test_forbidden_without_bulk_approve_permission()` — restricted user with viewAny+approve but without bulkApprove, POST bulk-approve → 403 |
| CT-109 | Dusk test | trn_TripApprove_TestCas.php:677-694 | `initializeTenantContext()` — resolves tenant domain, initializes tenancy |
| CT-110 | Dusk test | trn_TripApprove_TestCas.php:696-708 | `resolveAdminUser()` — finds admin user by email, falls back to first user, grants permissions |
| CT-111 | Dusk test | trn_TripApprove_TestCas.php:756-830 | `resolveDependencies()` — creates or finds shift, route, vehicle, driver, routeScheduler records for test data |
| CT-112 | Dusk test | trn_TripApprove_TestCas.php:832-858 | `createTripDirectly()` — inserts trip directly into tpt_trip table, bypasses TptTrip model boot() hooks (license/insurance checks) |
| CT-113 | Dusk test | trn_TripApprove_TestCas.php:860-882 | `deleteTripById()` — deletes related records (stop_details, incidents, event_logs, gps_logs) then deletes trip |
| CT-114 | Dusk test | trn_TripApprove_TestCas.php:884-897 | `cleanupCreatedTrips()` — iterates createdTripIds array and deletes each trip with related records |
| CT-115 | Dusk test | trn_TripApprove_TestCas.php:899-913 | Helper methods: `tenantUrl()`, `currentPath()`, `uniqueSuffix()` — URL builder, path extractor, unique string generator |
| CT-116 | blade model | trip_approve/model.blade.php | Remark modal structure: `.modal-header` with title + close, `.modal-body` with trip_id hidden + remark textarea, `.modal-footer` with save button |
| CT-117 | blade css (inline) | js.blade.php:105-119 | Styles: checkbox scale transform, table hover highlight, bulkActionBar sticky positioning |
| CT-118 | VndUsageLog model | VndUsageLog.php:1-42 | Uses SoftDeletes, fillable: vendor_id, agreement_item_id, usage_date, qty_used, remarks, logged_by |
| CT-119 | VndUsageLog model | VndUsageLog.php:27-30 | `vendor()` belongsTo Vendor; `agreementItem()` belongsTo VndAgreementItem |
| CT-120 | TptRouteSchedulerJnt | TptRouteSchedulerJnt.php:38-46 | `vehicle()` belongsTo Vehicle — chain: Trip → routeScheduler → vehicle → vendor |
| CT-121 | Vehicle model (implied) | Vehicle.php (not read) | `vendor()` belongsTo Vendor — used via routeScheduler->vehicle->vendor |
| CT-122 | Blade @can layering | tripmanagement.blade.php:46-48 | Double security: `x-backend.tab.nav-tab` hides tab via permission key + `@can` prevents body rendering |
| CT-123 | Blade @can double security | trip_approve/index.blade.php | Inside @can('tenant.trip-approve.viewAny'), the tab-pane renders — individual element @can checks provide second layer |
| CT-124 | Blade colspan | index.blade.php:135 | Empty state `<td colspan="10">` — counts columns including Approval and Action which may be hidden by @can |
| CT-125 | Blade colspan gap | index.blade.php:135 | If Approval or Action columns are hidden by @can, colspan=10 causes misalignment in empty state row |
| CT-126 | Pagination withQueryString | TripMgmtController:85 | `->withQueryString()` preserves ALL query params in pagination links, BUT blade's `$TripData->links()` should still work with appends |
| CT-127 | Filter form reset link | index.blade.php:29 | Reset link: `{{ url()->current() . '?tab=trip_approve' }}` — correctly preserves tab param while clearing filters |

---

## 7. Detailed Test Steps

### TC-P02: Approve Single Trip

**Preconditions:**
- Authenticated user with `tenant.trip-approve.approve` permission
- Existing trip with `status='Completed'` (or any status), `start_odometer_reading=100`, `end_odometer_reading=150`
- Route scheduler linked to vehicle with vendor assigned

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to Trip Management → Trip Approve tab | Trip grid visible with `#trip_approve-pane` |
| 2 | Ensure trip exists with start_odometer=100, end_odometer=150 | Distance = 50 |
| 3 | Click Approve switch on the trip row (toggle from unchecked to checked) | JS fires on change → POST `/transport/trip/toggle-approve` with `id={tripId}&status=1` |
| 4 | Verify AJAX sends: _token, id, status=1 | Request body matches expected fields |
| 5 | Verify JSON response | `{status: true, message: 'Trip approved'}` |
| 6 | Verify switch stays checked (no revert) | `.approve-switch` remains `checked` |
| 7 | DB check: `SELECT approved, approved_by, approved_at FROM tpt_trip WHERE id={tripId}` | approved=1, approved_by NOT NULL (matches Auth user ID), approved_at NOT NULL (within 5s of now) |
| 8 | DB check: `SELECT qty_used FROM vnd_usage_logs WHERE remarks LIKE '%Trip ID: {tripId}%'` | Log exists with qty_used=50.00 |
| 9 | DB check: `SELECT vendor_id, agreement_item_id, logged_by FROM vnd_usage_logs WHERE remarks LIKE '%Trip ID: {tripId}%'` | vendor_id matches vehicle vendor, logged_by matches Auth ID |

### TC-P02a: Approve Single Trip — API Direct (no UI)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST `/transport/trip/toggle-approve` with `id={tripId}&status=1` and CSRF token | HTTP 200 |
| 2 | Response body | `{"status":true,"message":"Trip approved"}` |
| 3 | Refresh trip from DB | `approved = 1` |
| 4 | Verify VndUsageLog exists | `SELECT * FROM vnd_usage_logs WHERE remarks = 'Trip Approved (Trip ID: {tripId})'` → 1 row |

### TC-P03: Unapprove Single Trip

**Preconditions:**
- Pre-approved trip: `approved=1, approved_by=someUserId, approved_at=someTimestamp`
- VndUsageLog exists with remarks "Trip Approved (Trip ID: {tripId})"

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create trip with approved=1, approved_by=1, approved_at=now() | Pre-approved trip |
| 2 | Create VndUsageLog with remarks "Trip Approved (Trip ID: {tripId})" | Usage log exists |
| 3 | Click approve switch to uncheck (toggle from checked to unchecked) | JS fires on change → POST with `id={tripId}&status=0` |
| 4 | Verify JSON response | `{status: true, message: 'Trip disapproved'}` |
| 5 | DB check: `SELECT approved, approved_by, approved_at FROM tpt_trip WHERE id={tripId}` | approved=0, approved_by=NULL, approved_at=NULL |
| 6 | DB check: `SELECT * FROM vnd_usage_logs WHERE remarks LIKE '%Trip ID: {tripId}%'` | No rows returned (log deleted) |

### TC-P04: Bulk Approve Multiple Trips

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 3 trips with approved=0, start_odo=50, end_odo=100 | Trips exist (distance=50 each) |
| 2 | Ensure each trip's routeScheduler→vehicle has vendor assigned | Vendor chain intact |
| 3 | POST `/transport/trip/bulk-approve` with trip_ids=[id1,id2,id3], action=approve | Validation passes |
| 4 | Verify JSON response | `{status: true, message: '3 trip(s) updated successfully'}` |
| 5 | DB check each trip: `SELECT approved FROM tpt_trip WHERE id IN (id1,id2,id3)` | All 3 have approved=1 |
| 6 | DB check each trip: `SELECT approved_by FROM tpt_trip WHERE id=id1` | approved_by = Auth user ID |
| 7 | DB check each trip: `SELECT approved_at FROM tpt_trip WHERE id=id1` | approved_at NOT NULL |
| 8 | DB check: `SELECT COUNT(*) FROM vnd_usage_logs WHERE remarks LIKE 'Trip Approved (Trip ID:%'` | 3 logs exist |
| 9 | Verify each log's qty_used: | `SELECT qty_used, remarks FROM vnd_usage_logs WHERE remarks LIKE '%Trip ID: id1%'` → 50.00 |

### TC-P05: Bulk Unapprove Multiple Trips

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 3 trips with approved=1, approved_by=1, approved_at=now() | Pre-approved trips |
| 2 | Create VndUsageLog for each trip (3 total) | 3 logs exist |
| 3 | POST `/transport/trip/bulk-approve` with trip_ids=[id1,id2,id3], action=unapprove | Validation passes |
| 4 | Verify JSON response | `{status: true, message: '3 trip(s) updated successfully'}` |
| 5 | DB check each trip: `SELECT approved FROM tpt_trip WHERE id IN (...)` | All 3 have approved=0 |
| 6 | DB check each trip: approved_by, approved_at | Both NULL for all 3 |
| 7 | DB check: `SELECT COUNT(*) FROM vnd_usage_logs WHERE remarks LIKE 'Trip Approved (Trip ID:%'` | 0 logs remain (all deleted) |

### TC-P06: Bulk Approve — Skip Already Approved

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create tripA with approved=1, tripB with approved=0, tripC with approved=0 | Mixed approved/unapproved |
| 2 | POST `/transport/trip/bulk-approve` with trip_ids=[idA,idB,idC], action=approve | Validation passes |
| 3 | Verify JSON response | Message says '3 trip(s) updated successfully' |
| 4 | DB check: `SELECT approved FROM tpt_trip WHERE id=idA` | approved=1 (unchanged — was skipped via continue at line 743) |
| 5 | DB check: `SELECT approved FROM tpt_trip WHERE id=idB` | approved=1 (was processed) |
| 6 | DB check: `SELECT approved FROM tpt_trip WHERE id=idC` | approved=1 (was processed) |
| 7 | DB check VndUsageLog count: `SELECT COUNT(*) FROM vnd_usage_logs WHERE remarks LIKE 'Trip Approved (Trip ID:%'` | Only 2 logs created (for idB and idC) |
| 8 | Document gap: `count($request->trip_ids)` returned 3 despite only 2 actual updates | 🔴 Misleading response message |

### TC-P07: Filter by Approval Status

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create tripA with approved=1, tripB with approved=0 | Mix of statuses |
| 2 | Navigate to tab | URL: `/transport/trip-management?tab=trip_approve` |
| 3 | Select "Approved" in dropdown, click Search | URL contains `approval_status=approved` |
| 4 | Table shows only tripA (approved=1) | tripB not visible in table |
| 5 | Select "Unapproved" in dropdown, click Search | URL contains `approval_status=unapproved` |
| 6 | Table shows only tripB (approved=0) | tripA not visible |
| 7 | Clear filter (click reset button) | URL: `/transport/trip-management?tab=trip_approve` (no approval_status param) |
| 8 | Table shows both trips | Both visible |

### TC-N05: Bulk Approve Empty trip_ids Array

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST `/transport/trip/bulk-approve` with `trip_ids=[]` and `action=approve` | Validation passes (empty array is still array, passes `required|array`) |
| 2 | Check response | JSON `{status: true, message: '0 trip(s) updated successfully'}` |
| 3 | This is misleading | No trips were processed but response says "successfully" |
| 4 | No DB changes expected | No approval fields modified, no VndUsageLog created |

### TC-CR12: Gap — No Status Transition Check Before Approval

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create trip with status='Scheduled' (not yet started) | Trip exists |
| 2 | Approve the scheduled trip | POST with id=X, status=1 |
| 3 | Check result | Approval succeeds — no validation that trip must be 'Completed' first |
| 4 | This is a gap | Business logic should require trip to be 'Completed' before approval is possible |

### TC-BIZ-D12: Approve Trip With 'Scheduled' Status

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create trip with status='Scheduled', approved=0, start_odo=0, end_odo=0 | Scheduled trip, never started |
| 2 | POST `/transport/trip/toggle-approve` with id={tripId}, status=1 | Gate check passes (applies only to trip-approve.approve, not trip status) |
| 3 | DB: `SELECT approved, status FROM tpt_trip WHERE id={tripId}` | approved=1 **but status='Scheduled'** — trip never ran |
| 4 | Business concern: approval of never-executed trip creates fake VndUsageLog with 0 distance | Log created with qty_used=0.00 |
| 5 | This is a data integrity gap | Completed trips should be the only eligible candidates for approval |

### TC-BIZ-D19: Bulk Approve Direct Chain Failure

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create trip with routeScheduler → vehicle → no vendor assigned | vendor relationship null |
| 2 | POST `/transport/trip/bulk-approve` with trip_ids=[tripId], action=approve | Code executes line 771-774 |
| 3 | Code executes: `$trip->routeScheduler->vehicle->vendor->agreement->agreementSingleItem` | If routeScheduler is null → `ErrorException: Call to a member function vehicle() on null` |
| 4 | Note: toggleApproval uses `optional($vendor...)` which wraps null safely, but bulkApprove does NOT use optional() for the full chain | 🔴 bulkApprove line 771 can throw ErrorException if routeScheduler, vehicle, or vendor is null |
| 5 | Workaround: ensure all trips have full relationship chain before bulk approve | Not enforced in code |

### TC-CR19: Pagination Does Not Append Tab Parameter

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to Trip Approve tab with 11+ trips | Pagination links visible |
| 2 | Inspect pagination link href attribute | URL contains `?page=2` but 🔴 **MISSING** `&tab=trip_approve` |
| 3 | Click page 2 | Page loads but 🔴 `tab` parameter is lost → defaults to first tab (daily_trip) |
| 4 | View shows Daily Trip content instead of Trip Approve | User must re-select Trip Approve tab |
| 5 | Compare with Vendor module gold standard: `$records->appends(['tab' => '{tab_id}'])->links()` | Gold standard preserves tab; trip_approve does not |
| 6 | Root cause: TripMgmtController index() paginates `$TripData` at line 85 with `->withQueryString()`, but pagination links in blade at line 146 use `{{ $TripData->links() }}` without additional appends |

### TC-CR20: Bulk Approve Optional Chain vs Toggle Approve — Side by Side

| Step # | Aspect | toggleApproval (line 657-666) | bulkApprove (line 771-774) |
|--------|--------|-------------------------------|----------------------------|
| 1 | Code pattern | `$vendor = optional($trip->routeScheduler?->vehicle?->vendor)` — null-safe operator inside optional() | Direct chain: `$trip->routeScheduler->vehicle->vendor->agreement->agreementSingleItem` |
| 2 | Null safety | `if ($vendor && $vendor->id)` guards the entire block | `optional(...)->id` wraps ONLY the final `->id` access |
| 3 | If routeScheduler null | `$vendor` becomes null (null-safe stops at `?->`) → block skipped safely | 🔴 **ErrorException: Call to a member function vehicle() on null** |
| 4 | If vehicle null | `$vendor` becomes null → block skipped | 🔴 **ErrorException** |
| 5 | If vendor null | `$vendor->id` fails → block skipped | 🔴 **ErrorException** |
| 6 | vendor_id source | `$vendor->id` (from resolved vendor object) | `$trip->routeScheduler->vehicle->vendor_id` — directly from vehicle's FK |
| 7 | Duplicate prevention | `VndUsageLog::firstOrCreate(...)` | `exists()` check + `VndUsageLog::create(...)` |
| 8 | Policy method | `Gate::authorize('tenant.trip-approve.approve')` | `Gate::authorize('tenant.trip-approve.bulkApprove')` |

### TC-CR29: Concurrent Approval Race Condition

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User A clicks Approve, User B clicks Approve simultaneously | Both requests arrive at toggleApproval nearly simultaneously |
| 2 | Both pass `Gate::authorize()` | Both pass permission check |
| 3 | Both execute `TptTrip::find($request->id)` | Both find same trip |
| 4 | Both reach approve logic (line 647) | First request sets approved=1, approved_by=A, approved_at=ts1 |
| 5 | Second request overwrites (line 651) | approved_by set to B, approved_at set to ts2 (overwrites A's approval) |
| 6 | VndUsageLog: firstOrCreate runs for both | firstOrCreate prevents duplicate — second finds existing log |
| 7 | Result: final approved_by = User B (not User A) | No transaction/atomicity guarantees for approval fields |
| 8 | Recommend: `DB::transaction()` + `lockForUpdate()` around the approval block | Currently no locking mechanism |

### TC-P17: Approve Trip — VndUsageLog qty_used Verification

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create trip with start_odometer_reading=125.50, end_odometer_reading=198.75 | Distance = 73.25 |
| 2 | Approve the trip | POST toggle-approve with status=1 |
| 3 | DB: `SELECT qty_used FROM vnd_usage_logs WHERE remarks LIKE '%Trip ID: {tripId}%'` | qty_used = 73.25 |
| 4 | Verify precision: round to 2 decimal places | 73.25 (not 73.3 or 73) |
| 5 | Verify DECIMAL storage: `SELECT COLUMN_TYPE FROM information_schema.COLUMNS WHERE TABLE_NAME='vnd_usage_logs' AND COLUMN_NAME='qty_used'` | decimal(10,2) or similar |

### TC-P18: Approve Trip Zero Distance

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create trip with start_odometer_reading=100, end_odometer_reading=100 | Distance = 0 |
| 2 | Approve the trip | POST toggle-approve |
| 3 | DB check vnd_usage_logs | Log exists with qty_used = 0.00 |
| 4 | Verify zero-distance log is created | Document behavior: 0-distance logs may be business-valid or not |

### TC-P19: Approve Trip Negative Odometer (Clamping)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create trip with start_odometer_reading=200, end_odometer_reading=100 | Raw distance = -100 |
| 2 | Approve the trip | POST toggle-approve |
| 3 | Code: `max(0, round(100-200, 2))` = max(0, -100) = 0 | Clamped to 0 |
| 4 | DB check vnd_usage_logs | Log exists with qty_used = 0.00 (not -100.00) |

### TC-P22: Approve Then Approve Again (Duplicate Prevention)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Approve trip via toggle-approve (status=1) | VndUsageLog created |
| 2 | Approve same trip again via toggle-approve (status=1) | firstOrCreate finds existing log |
| 3 | DB: `SELECT COUNT(*) FROM vnd_usage_logs WHERE remarks LIKE '%Trip ID: {tripId}%'` | COUNT = 1 (no duplicate) |
| 4 | Confirm: if firstOrCreate triggers create on second call | It won't — remarks already exists, uses first record |

### TC-BIZ-D10: Null Agreement Chain in VndUsageLog

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create vehicle with vendor assigned but no agreement on vendor | Vehicle->vendor exists, vendor->agreement is null |
| 2 | Create routeScheduler pointing to that vehicle | Schedule exists |
| 3 | Create trip with that routeScheduler | Trip exists |
| 4 | Approve the trip | toggleApproval processes |
| 5 | Code at line 666: `optional($vendor->agreement?->agreementSingleItem)->id` | `$vendor->agreement` is null → `->agreementSingleItem` is null via null-safe → `->id` results in null (via optional) |
| 6 | DB: `SELECT agreement_item_id FROM vnd_usage_logs WHERE remarks LIKE '%Trip ID: {tripId}%'` | agreement_item_id = NULL |
| 7 | Business impact: usage log exists without linking to agreement item | May be acceptable or a data quality gap |

### TC-P10: Table Column Verification

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to trip_approve tab with at least 1 trip | Table visible |
| 2 | Verify column headers match | Trip Date, Route, Vehicle, Driver, Status, Start Time, End Time, Start Odo, End Odo, Start Fuel, End Fuel, Approval, Action |
| 3 | Verify approval switch exists per row | `.approve-switch` input present for each trip row |
| 4 | Verify `#selectAll` checkbox exists | Select-all checkbox in thead |
| 5 | Verify bulk action bar hidden initially | `#bulkActionBar` has class `d-none` |
| 6 | Click a trip checkbox | Bulk action bar appears (d-none removed) |
| 7 | Verify row data: trip_date formatted | `{{ $item->trip_date?->format('d M Y') }}` |
| 8 | Verify row data: status badge | Completed → `bg-success`, others → `bg-warning` |
| 9 | Verify row data: time formatted | `start_time?->format('h:i A')` |

### TC-P01: Tab Loads Correctly

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to `/transport/trip-management?tab=trip_approve` | HTTP 200 |
| 2 | Verify tab pane visible | `#trip_approve-pane` present and has class `active show` |
| 3 | Verify filter controls | `select[name="approval_status"]` present |
| 4 | Verify search input | `input[name="search"]` present |
| 5 | Verify bulk action bar | `#bulkActionBar` present |
| 6 | Verify trip checkboxes | `.trip-checkbox` elements present if trips exist |

### TC-P11: Search by Route/Vehicle/Driver

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create trip with route name 'Morning Express' | Trip exists |
| 2 | Type 'Morning' in search box, click Search | URL contains `search=Morning&tab=trip_approve` |
| 3 | Verify filtered results show only matching trip | Route name displayed contains 'Morning' |
| 4 | Search by vehicle number | Vehicle number filter works |
| 5 | Search by driver name | Driver name filter works |

### TC-P08: Approve Trip Without Vendor

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create vehicle with vendor_id=NULL | Vehicle has no vendor |
| 2 | Create trip with this vehicle | Trip exists |
| 3 | Approve the trip | POST toggle-approve with status=1 |
| 4 | Verify response | `{status: true, message: 'Trip approved'}` |
| 5 | Code path: line 657 `$vendor = optional(...)` → vendor is null | `$vendor->id` check fails at line 660 |
| 6 | Code continues without creating VndUsageLog | No usage log created (expected) |
| 7 | DB: `SELECT * FROM vnd_usage_logs WHERE remarks LIKE '%Trip ID: {tripId}%'` | 0 rows (correct — vendor-free approval) |

### TC-N01: Approve Non-Existent Trip

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST `/transport/trip/toggle-approve` with id=99999, status=1 | Route: line 632 |
| 2 | Code: `TptTrip::find(99999)` returns null | Line 637 |
| 3 | Code: `if (!$trip)` → true | Line 638 |
| 4 | Response: `response()->json(['status'=>false, 'message'=>'Trip not found.'], 404)` | Line 639 |
| 5 | Verify HTTP status | 404 |

### TC-N02: Missing trip_id in toggleApproval

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST `/transport/trip/toggle-approve` without 'id' parameter | No validation rule checks for 'id' |
| 2 | Code: `$request->id` resolves to null | Line 637 |
| 3 | Code: `TptTrip::find(null)` returns null | Where id = NULL → no match |
| 4 | Response: 404 JSON | Same as non-existent trip |
| 5 | Gap: no 400 Bad Request for missing required parameter | HTTP 404 returned instead of 400 |

### TC-CR13: Gap — No activityLog in toggleApproval

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Approve trip | POST toggle-approve |
| 2 | Check `activity_log` table | No entry for 'Trip approved' |
| 3 | Compare with TripController@update (line 378) | update() calls `activityLog($trip, 'Updated', ['message' => '...'])` |
| 4 | Compare with destroy() (line 403) | destroy() calls `activityLog($trip, 'Deleted', ['message' => '...'])` |
| 5 | Gap confirmed | toggleApproval is the only mutation method without activity logging |

### TC-CR14: Gap — VndUsageLog Deletion by Remarks String

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Approve trip | VndUsageLog created with remarks "Trip Approved (Trip ID: 42)" |
| 2 | Manually modify VndUsageLog.remarks (simulate format change) | Remarks changed to "Trip 42 approved" |
| 3 | Unapprove the trip | Code looks for remarks "Trip Approved (Trip ID: 42)" |
| 4 | Code: `where('remarks', "Trip Approved (Trip ID: 42)")->delete()` | 🔴 Deletes 0 rows — log orphaned |
| 5 | Risk: if a developer changes the remarks string format, all existing logs become undeletable | No migration or FK-based cleanup |

### TC-P29: Bulk Action Bar UI

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to trip_approve tab with trips | Bulk action bar hidden (class `d-none`) |
| 2 | Click first trip checkbox | `updateBulkBar()` fires at line 4 |
| 3 | Verify: `#selectedCount` text updated to '1' | Line 9 |
| 4 | Verify: `#bulkActionBar` loses `d-none` class | Line 10-11 |
| 5 | Click Approve Selected button | `bulkAction('approve')` fires at line 61 |
| 6 | Verify: only checked trip IDs sent in AJAX | Line 66-68: `$('.trip-checkbox:checked').map(...)` |

### TC-P31: Select All Checkbox

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to trip_approve tab with 5 trips | 5 `.trip-checkbox` elements |
| 2 | Click `#selectAll` checkbox | Line 19: `$('.trip-checkbox').prop('checked', true)` |
| 3 | Verify all 5 checkboxes checked | Each has `checked` property |
| 4 | Verify `#selectedCount` shows '5' | Line 9 executes |
| 5 | Click `#selectAll` again | All unchecked |
| 6 | Uncheck one trip checkbox | `#selectAll` becomes unchecked (line 15: `selected === total` is false) |

### TC-N06: Permission 403 Without approve Permission

**Preconditions:**
- Restricted user with `tenant.trip-approve.viewAny` but WITHOUT `tenant.trip-approve.approve`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as restricted user | Authenticated |
| 2 | POST `/transport/trip/toggle-approve` with any valid id and status=1 | Route enters TripController@toggleApproval at line 632 |
| 3 | Code: `Gate::authorize('tenant.trip-approve.approve')` at line 634 | User lacks 'approve' permission → throws `AuthorizationException` |
| 4 | Verify response | HTTP 403 with message 'This action is unauthorized.' |
| 5 | Verify DB: trip `approved` field unchanged | approved remains 0 (or original value) |

### TC-N07: Permission 403 Without bulkApprove Permission

**Preconditions:**
- Restricted user with `tenant.trip-approve.viewAny` AND `tenant.trip-approve.approve` but WITHOUT `tenant.trip-approve.bulkApprove`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as restricted user | Authenticated |
| 2 | POST `/transport/trip/bulk-approve` with trip_ids=[1,2] and action=approve | Route enters TripController@bulkApprove at line 702 |
| 3 | Code: `Gate::authorize('tenant.trip-approve.bulkApprove')` at line 704 | User lacks 'bulkApprove' permission → throws `AuthorizationException` |
| 4 | Verify response | HTTP 403 with message 'This action is unauthorized.' |
| 5 | Verify DB: no trips updated | All trip `approved` fields unchanged |

### TC-N08: Guest Access Redirect

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open browser, clear all session/cookies | No auth state |
| 2 | Navigate to `/transport/trip-management?tab=trip_approve` | HTTP redirect |
| 3 | Check redirect URL | `/login` or configured login path |
| 4 | Verify no DB mutations occurred | No trips modified |

### TC-N10: XSS Injection in Remarks

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create trip with remarks containing `<script>alert('xss')</script>` | Trip created with script literal in remarks |
| 2 | Navigate to trip_approve tab | Table renders |
| 3 | Click edit-remark button on the trip | Modal opens |
| 4 | Check remark_text value | `<script>alert('xss')</script>` shown as literal text |
| 5 | Save remark with new XSS payload: `</textarea><script>alert(1)</script>` | AJAX POST to update-remark |
| 6 | Reload page and check rendered output | Blade's `{{ }}` escapes HTML → `<script>` shown as text |
| 7 | Verify no script execution | No alert dialog appears |

### TC-BIZ-D01: Approve with Zero Odometer Readings

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create trip with start_odometer_reading=0, end_odometer_reading=0 | Trip exists |
| 2 | POST toggle-approve with status=1 | Approved |
| 3 | Code: `max(0, round(0-0, 2))` = 0 | Line 645 |
| 4 | DB: `SELECT qty_used FROM vnd_usage_logs WHERE remarks LIKE '%Trip ID: {id}%'` | qty_used = 0.00 |
| 5 | Decision: Is zero-distance approval valid? | Business rule needed |

### TC-BIZ-D02: Approve with Negative Odometer (End < Start)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create trip with start_odometer_reading=500, end_odometer_reading=100 | Raw distance = -400 |
| 2 | POST toggle-approve with status=1 | Approved |
| 3 | Code: `max(0, round(100-500, 2))` = max(0, -400) = 0 | Line 645 clamps to 0 |
| 4 | DB: `SELECT qty_used FROM vnd_usage_logs WHERE remarks LIKE '%Trip ID: {id}%'` | qty_used = 0.00 |
| 5 | Note: Negative odometer may indicate data entry error | Silent clamping hides the anomaly |

### TC-BIZ-D04: Duplicate Approval Prevention (firstOrCreate)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Approve trip via toggle-approve (status=1) | Line 662: `VndUsageLog::firstOrCreate(['remarks'=>"Trip Approved (Trip ID: 1)"], [...])` creates log |
| 2 | Approve same trip again via toggle-approve (status=1) | Line 662: `firstOrCreate` finds existing log by remarks → returns existing record |
| 3 | DB: `SELECT COUNT(*) FROM vnd_usage_logs WHERE remarks = 'Trip Approved (Trip ID: 1)'` | COUNT = 1 (no duplicate) |
| 4 | Verify that `created_at` of the log is the FIRST creation time | Timestamp unchanged from first approval |

### TC-BIZ-D05: Full Lifecycle (Approve → Unapprove → Approve)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST toggle-approve status=1 | approved=1, VndUsageLog created |
| 2 | POST toggle-approve status=0 | approved=0, VndUsageLog deleted (by remarks) |
| 3 | DB: `SELECT COUNT(*) FROM vnd_usage_logs WHERE remarks LIKE '%Trip ID: {id}%'` | 0 logs |
| 4 | POST toggle-approve status=1 | approved=1, VndUsageLog recreated |
| 5 | DB: `SELECT COUNT(*) FROM vnd_usage_logs WHERE remarks LIKE '%Trip ID: {id}%'` | 1 log (recreated) |
| 6 | Verify qty_used in recreated log | Same distance as first approval |

### TC-BIZ-D48: HTML Checkbox 'on' Value Bug

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect the approve-switch element in the browser | When unchecked, checkbox submits `status=0` (or no value) |
| 2 | When checked, checkbox submits `status=1` (or `status='on'` depending on implementation) | HTML checkbox spec: checked checkbox sends `value="on"` by default |
| 3 | If the checkbox sends `status='on'`: | `'on' == 1` → false in PHP loose comparison |
| 4 | Code enters `else` branch (disapprove) instead of approve | 🔴 **Logical bug**: Checking the switch UN-approves the trip |
| 5 | Verify the frontend JS sends `status: 1` (integer) in the AJAX payload, not the HTML checkbox value | JS `.is(':checked') ? 1 : 0` sends proper integer |
| 6 | Confirm: Frontend works correctly; direct POST with HTML form would trigger the bug | JS-mediated request is safe |

### TC-N14: toggleApproval with String status='abc'

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST `/transport/trip/toggle-approve` with id={validId}, status='abc' | No validation rejects this |
| 2 | Code: `$request->status == 1` where `'abc' == 1` | PHP loose comparison: `'abc' == 1` → false (string 'abc' converts to 0, 0 != 1) |
| 3 | Code enters `else` branch | Enters disapproval path at line 678 |
| 4 | DB: `SELECT approved FROM tpt_trip WHERE id={id}` | approved=0 (unexpectedly disapproved) |
| 5 | This is a gap: no input validation allows garbage input to cause unintended unapproval | 🔴 Tighten with `in:0,1` validation |

### TC-CR31: Auth::user() Returns Null on Expired Session

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Simulate expired session (e.g., session file deleted server-side) | User is logged in client-side but session data gone server-side |
| 2 | Make AJAX POST to toggle-approve | Request enters TripController@toggleApproval |
| 3 | Gate::authorize passes (Laravel auth middleware should have caught this, but if bypassed...) | If no `auth` middleware on route, `Auth::user()` returns null |
| 4 | Code at line 653: `Auth::user()->id` | `null->id` → `ErrorException: Call to a member function id on null` |
| 5 | Route check: `web.php:166` — no explicit `->middleware('auth')` on the route | Route relies on parent middleware group for auth |
| 6 | Risk level: LOW if parent group has auth middleware | Verify middleware stack on transport routes |

### TC-CR33: Loose Comparison Status Check

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST with status=1 (int) | `1 == 1` → true → approve branch |
| 2 | POST with status='1' (string) | `'1' == 1` → true → approve branch |
| 3 | POST with status=true (bool) | `true == 1` → true → approve branch |
| 4 | POST with status=0 (int) | `0 == 1` → false → else (disapprove) branch |
| 5 | POST with status=null | `null == 1` → false → else (disapprove) branch |
| 6 | POST with status='' (empty string) | `'' == 1` → false → else (disapprove) branch |
| 7 | POST with status='0' (string zero) | `'0' == 1` → false → else (disapprove) branch |
| 8 | Risk: `status` completely missing from request | Same as `status=null` → enters disapproval |

### TC-P16: DDL Schema Validation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check `tpt_trip` table exists | `Schema::hasTable('tpt_trip')` → true |
| 2 | Check `approved` column | TINYINT(1), NOT NULL, DEFAULT '0' |
| 3 | Check `approved_by` column | INT UNSIGNED, DEFAULT NULL |
| 4 | Check `approved_at` column | TIMESTAMP NULL |
| 5 | Check `deleted_at` column | TIMESTAMP NULL (soft delete) |
| 6 | Check `start_odometer_reading` | DECIMAL, DEFAULT '0.00' |
| 7 | Check `end_odometer_reading` | DECIMAL, DEFAULT '0.00' |
| 8 | Verify indexes | `idx_trip_routeSched_tripDate` and `idx_trip_vehicle` exist |

---

## 8. Gap Summary

| # | Gap | Severity | Component | File:Line |
|---|-----|----------|-----------|-----------|
| G01 | No `activityLog()` call in toggleApproval | HIGH | Controller | `TripController:632-700` |
| G02 | No `activityLog()` call in bulkApprove | HIGH | Controller | `TripController:702-787` |
| G03 | No trip status validation before approval (can approve Scheduled/Ongoing/Cancelled) | HIGH | Controller | `TripController:647` |
| G04 | Bulk approve success message counts input trip_ids, not actually processed trips | MEDIUM | Controller | `TripController:785` |
| G05 | Bulk approve uses `exists()` check while single uses `firstOrCreate` (inconsistent) | MEDIUM | Controller | `TripController:764 vs 662` |
| G06 | Bulk approve optional chain can throw ErrorException on null routeScheduler/vehicle | HIGH | Controller | `TripController:771` |
| G07 | No input validation on toggleApproval (`id` and `status` unvalidated) | MEDIUM | Controller | `TripController:632` |
| G08 | Pagination does not append `tab=trip_approve` parameter | MEDIUM | Blade | `index.blade.php:146` |
| G09 | `@canany(['tenant.trip-approve.status'])` uses @canany for single permission | LOW | Blade | `index.blade.php:70` |
| G10 | `tenant.trip-approve.delete` in @canany but no delete button rendered | LOW | Blade | `index.blade.php:73` |
| G11 | Policy `reject()` defined but no controller/route uses it | LOW | Policy | `TransportTripApprovePolicy:37` |
| G12 | Policy `viewHistory()` defined but no controller/route uses it | LOW | Policy | `TransportTripApprovePolicy:45` |
| G13 | Policy `export()` defined but no controller/route uses it | LOW | Policy | `TransportTripApprovePolicy:53` |
| G14 | Policy `print()` defined but no controller/route uses it | LOW | Policy | `TransportTripApprovePolicy:61` |
| G15 | Policy `viewPending()` defined but no controller/route uses it | LOW | Policy | `TransportTripApprovePolicy:77` |
| G16 | Policy `override()` defined but no controller/route uses it | LOW | Policy | `TransportTripApprovePolicy:85` |
| G17 | VndUsageLog deletion by remarks string is fragile (no FK-based cleanup) | MEDIUM | Controller | `TripController:688` |
| G18 | No concurrent modification guard (race condition on approval) | MEDIUM | Controller | `TripController:632-700` |
| G19 | No tenant isolation on bulk approve `whereIn` | HIGH | Controller | `TripController:711` |
| G20 | No `Auth::check()` before `Auth::user()->id` — may throw if session expired | MEDIUM | Controller | `TripController:653,671,754,778` |
| G21 | Pagination not using unique paginator name (`TripData` shared across tabs) | MEDIUM | Controller | `TripMgmtController:85` |
| G22 | Blade uses 'disapproved' message but UI labels use 'unapprove' | LOW | Controller | `TripController:693` |
| G23 | No Dusk test for VndUsageLog creation verification (only checks approval fields) | MEDIUM | Test | Dusk test |
| G24 | No Dusk test for bulk approve skip-already-approved scenario | MEDIUM | Test | Dusk test |
| G25 | No Dusk test for empty trip_ids in bulk approve | LOW | Test | Dusk test |

---

## 9. Permissions List Cross-Reference

Permissions defined in `config/permissionslist.php` line 325: `'trip-approve' => $crud` (all standard actions from $crud array with 17 items).

| Permission | In Policy? | Controller? | Blade? | Dusk Tested? | Notes |
|-----------|-----------|-------------|--------|-------------|-------|
| tenant.trip-approve.viewAny | ✅ viewAny() | ✅ (tab gate) | ✅ | ✅ | Tab permission key |
| tenant.trip-approve.view | ✅ view() | ❌ (TripPolicy used) | ✅ eye button | ✅ | Delegated to TripPolicy |
| tenant.trip-approve.create | ❌ | ❌ | ❌ | ❌ | No create for approval |
| tenant.trip-approve.update | ❌ | ❌ | ❌ | ❌ | TripPolicy handles update |
| tenant.trip-approve.delete | ✅ delete() | ❌ | ✅ (nocode but in @canany) | ✅ | Referenced in blade, no delete UI |
| tenant.trip-approve.restore | ❌ | ❌ | ❌ | ❌ | No trash for approval |
| tenant.trip-approve.forceDelete | ❌ | ❌ | ❌ | ❌ | No forceDelete |
| tenant.trip-approve.import | ❌ | ❌ | ❌ | ❌ | Not applicable |
| tenant.trip-approve.export | ✅ export() | ❌ | ❌ | ❌ | Orphaned policy method |
| tenant.trip-approve.print | ✅ print() | ❌ | ❌ | ❌ | Orphaned policy method |
| tenant.trip-approve.publish | ❌ | ❌ | ❌ | ❌ | Not applicable |
| tenant.trip-approve.status | ❌ | ❌ | ✅ approval column | ❌ | **Missing policy method** |
| tenant.trip-approve.email-schedule | ❌ | ❌ | ❌ | ❌ | Not applicable |
| tenant.trip-approve.remark | ❌ | ❌ | ❌ | ❌ | Not applicable |
| tenant.trip-approve.pdf | ❌ | ❌ | ❌ | ❌ | Not applicable |
| tenant.trip-approve.edit | ✅ (via approve()) | ❌ | ✅ edit remark | ✅ | Uses approve() in policy |
| tenant.trip-approve.approve | ✅ approve() | ✅ toggleApproval | ❌ | ✅ | Core approval permission |
| tenant.trip-approve.bulkApprove | ✅ bulkApprove() | ✅ bulkApprove | ❌ | ✅ | Core bulk permission |
| tenant.trip-approve.reject | ✅ reject() | ❌ | ❌ | ❌ | Orphaned policy method |
| tenant.trip-approve.viewHistory | ✅ viewHistory() | ❌ | ❌ | ❌ | Orphaned policy method |
| tenant.trip-approve.viewPending | ✅ viewPending() | ❌ | ❌ | ❌ | Orphaned policy method |
| tenant.trip-approve.override | ✅ override() | ❌ | ❌ | ❌ | Orphaned policy method |

Note: `tenant.trip-approve.status` is used in blade but is NOT defined in `TransportTripApprovePolicy`. The blade references it directly via `@canany`, and it falls through to the Gate facade which checks against the generic ability. The `$crud` array in `permissionslist.php` includes 'status', so the permission exists in the DB permission list. This is a **missing policy method** gap.

---

## 10. Control Flow Diagram (Text)

```
User Action                         Server Processing                    Database Effect
─────────────                       ────────────────                    ───────────────

[Tab Click] trip_approve
  │
  ├─► TripMgmtController@index()
  │     ├─ Gate::authorize('tenant.transport.viewAny')
  │     ├─ Gate::authorize('tenant.trip-approve.viewAny') [blade @can]
  │     ├─ TripQuery() → TptTrip::with([...])
  │     │     └─ paginate(10) → $TripData
  │     └─ return view('tab_module.tripmanagement')
  │
  └─► trip_approve/index.blade.php
        ├─ Filter form (approval_status, search)
        ├─ Table rows with $TripData
        ├─ Approve switch per row
        └─ Bulk action bar

[Toggle Single] approve-switch change
  │
  ├─► JS AJAX POST → toggle-approve
  │     │
  │     ├─► TripController@toggleApproval()
  │     │     ├─ Gate::authorize('tenant.trip-approve.approve')
  │     │     ├─ TptTrip::find($request->id)
  │     │     ├─ if status == 1:
  │     │     │     ├─ UPDATE tpt_trip SET approved=1, approved_by, approved_at
  │     │     │     ├─ if vendor exists:
  │     │     │     │     └─ VndUsageLog::firstOrCreate(remarks, [data])
  │     │     │     └─ message = 'Trip approved'
  │     │     └─ else (disapprove):
  │     │           ├─ UPDATE tpt_trip SET approved=0, approved_by=NULL, approved_at=NULL
  │     │           └─ VndUsageLog::where(remarks)->delete()
  │     │
  │     └─ JSON response {status: true, message}
  │
  └─► JS success: showToast, or error: revert checkbox

[Bulk] Approve/Unapprove Selected
  │
  ├─► JS AJAX POST → bulk-approve
  │     │
  │     ├─► TripController@bulkApprove()
  │     │     ├─ Gate::authorize('tenant.trip-approve.bulkApprove')
  │     │     ├─ $request->validate(trip_ids|required|array, action|required|in:approve,unapprove)
  │     │     ├─ TptTrip::whereIn('id', $request->trip_ids)->get()
  │     │     ├─ foreach ($trips as $trip):
  │     │     │     ├─ if action == 'unapprove':
  │     │     │     │     ├─ VndUsageLog::where(remarks)->delete()
  │     │     │     │     └─ UPDATE tpt_trip SET approved=0, approved_by=NULL, approved_at=NULL
  │     │     │     ├─ elseif $trip->approved: continue (skip)
  │     │     │     └─ else (approve):
  │     │     │           ├─ UPDATE trip SET approved=1, approved_by, approved_at
  │     │     │           ├─ if !VndUsageLog::where(remarks)->exists():
  │     │     │           │     └─ VndUsageLog::create([...])
  │     │     │           └─ // no activityLog
  │     │     └─ JSON response {status: true, message: 'N trip(s) updated'}
  │     │
  │     └─ JS success: reload page after 800ms
  │
  └─► Page reload → updated approval status visible
```

---

## 11. Response Format Reference

### toggleApproval Success (Approve)
```json
{"status": true, "message": "Trip approved"}
```

### toggleApproval Success (Disapprove)
```json
{"status": true, "message": "Trip disapproved"}
```

### toggleApproval Error (Trip Not Found)
```json
{"status": false, "message": "Trip not found."}
```
HTTP Status: 404

### bulkApprove Success (N trips)
```json
{"status": true, "message": "3 trip(s) updated successfully"}
```

### bulkApprove Validation Error (missing trip_ids)
```json
{"message": "The trip ids field is required.", "errors": {"trip_ids": ["The trip ids field is required."]}}
```
HTTP Status: 422

### bulkApprove Validation Error (invalid action)
```json
{"message": "The action field is required.", "errors": {"action": ["The selected action is invalid."]}}
```
HTTP Status: 422

### Authorization Error
```json
{"message": "This action is unauthorized."}
```
HTTP Status: 403

### Guest Redirect
Status: 302 → Location: `/login`

---

## 12. Dusk Test Coverage Matrix

Maps existing Dusk tests to TC IDs from Section 6:

| Dusk Test Method | TC ID(s) Covered | Coverage | Gap |
|-----------------|-------------------|----------|-----|
| `test_ddl_conditions()` | TC-P16 | Full DDL | — |
| `test_tab_pane_renders()` | TC-P01 | Tab loads | — |
| `test_table_displays_trip_data()` | TC-P10 | Columns visible | — |
| `test_search_by_route_vehicle_driver()` | TC-P11 | Search works | — |
| `test_filter_by_approval_status()` | TC-P07 | Filter works | — |
| `test_individual_approve_toggle()` | TC-P02 | Approve single | **Missing: VndUsageLog verification** |
| `test_individual_unapprove_toggle()` | TC-P03 | Unapprove single | **Missing: VndUsageLog deletion check** |
| `test_bulk_approve_action()` | TC-P04 | Bulk approve | **Missing: VndUsageLog count check** |
| `test_bulk_unapprove_action()` | TC-P05 | Bulk unapprove | **Missing: VndUsageLog deletion check** |
| `test_empty_state_no_trips()` | TC-P09 | Empty state | — |
| `test_pagination_shows_with_11_records()` | TC-P12 | Pagination visible | — |
| `test_pagination_hidden_with_5_records()` | TC-P13 | Pagination hidden | — |
| `test_pagination_navigates_to_page_2_and_back()` | TC-P14 | Page navigation | — |
| `test_pagination_preserves_tab_parameter()` | TC-P15 | Tab param preserved | **Blade test passes, but links() may lose tab in real usage** |
| `test_guest_redirect()` | TC-N08 | Guest redirect | — |
| `test_403_forbidden()` | TC-N09 | 403 on tab | — |
| `test_forbidden_without_view_any_permission()` | TC-N09 | 403 no viewAny | — |
| `test_forbidden_without_approve_permission()` | TC-N06 | 403 no approve | — |
| `test_forbidden_without_bulk_approve_permission()` | TC-N07 | 403 no bulkApprove | — |

### Dusk Test Gaps Summary

| Missing Test | Priority | Reason |
|-------------|----------|--------|
| VndUsageLog creation verification | HIGH | No test asserts qty_used, vendor_id, or agreement_item_id |
| VndUsageLog deletion on unapprove | HIGH | No test verifies log removed after unapprove |
| Bulk approve skip already-approved | MEDIUM | No test with mixed approved/unapproved inputs |
| Empty trip_ids in bulk approve | MEDIUM | No test for `trip_ids=[]` behavior |
| Non-existent trip IDs | MEDIUM | No test for 404 on toggle with id=99999 |
| Duplicate approval (firstOrCreate) | MEDIUM | No test for approving same trip twice |
| Approve with zero/null odometer | LOW | Edge case for distance calculation |
| Approve 'Scheduled' trip (gap demo) | MEDIUM | Demonstrates missing status guard |
| XSS injection in remarks | LOW | Security boundary test |

---

## 13. Test Data Dependency Chain

To execute Trip Approval tests, the following DB records must exist:

```
tpt_shift ──┐
             ├──► tpt_route_scheduler_jnt ──┐
tpt_route ───┘                              │
                                            ├──► tpt_trip
tpt_vehicle ────────────────────────────────┘       │
     │                                               ├── approved
     │                                               ├── approved_by
     └── vendor_id ──► vendor ──► agreement         ├── approved_at
                             └──► VndUsageLog       ├── start_odometer_reading
                                                     ├── end_odometer_reading
                                                     ├── status (Scheduled/Ongoing/Completed)
                                                     └── trip_date
```

### Dependency Resolution in Dusk Tests (resolveDependencies):
```
1. shift:    tpt_shift          → creates if not exists
2. route:    tpt_route          → creates if not exists (with route_geometry)
3. vehicle:  tpt_vehicle        → creates if not exists
4. driver:   tpt_personnel      → creates if not exists
5. scheduler: tpt_route_scheduler_jnt → creates if not exists (links all above)
```

### Trip Creation (createTripDirectly):
- Inserts directly via `DB::table('tpt_trip')->insertGetId(...)`
- Bypasses `TptTrip` model `creating()` and `saving()` boot hooks
- Reason: boot hooks check license/fitness/insurance which may not exist or be expired in test DB
- Bypassing model hooks means FSM status transitions are NOT enforced during test data creation

---

## 14. Edge Case Combinatorial Matrix

This matrix identifies combinations of input parameters that produce unique code paths:

| # | status | id | trip_ids | action | trip approved | trip exists | trip status | Route |
|---|--------|----|----------|--------|---------------|-------------|-------------|-------|
| 1 | 1 | valid | — | — | 0 | yes | Completed | Toggle approve |
| 2 | 1 | valid | — | — | 1 | yes | Completed | Toggle approve (duplicate) |
| 3 | 0 | valid | — | — | 1 | yes | Completed | Toggle unapprove |
| 4 | 0 | valid | — | — | 0 | yes | Completed | Toggle unapprove (redundant) |
| 5 | 1 | null | — | — | — | — | — | Toggle: missing id → 404 |
| 6 | 1 | 99999 | — | — | — | no | — | Toggle: not found → 404 |
| 7 | — | — | [1,2,3] | approve | 0,0,0 | yes,3 | any | Bulk approve 3 |
| 8 | — | — | [1,2,3] | approve | 1,0,0 | yes,3 | any | Bulk approve, skip 1 |
| 9 | — | — | [1,2,3] | approve | 1,1,1 | yes,3 | any | Bulk approve, skip all |
| 10 | — | — | [1,2] | unapprove | 1,1 | yes,2 | any | Bulk unapprove |
| 11 | — | — | [] | approve | — | — | — | Empty array |
| 12 | — | — | [999] | approve | — | no | — | Non-existent ID |
| 13 | — | — | [1] | invalid | — | yes | — | Invalid action → 422 |
| 14 | — | — | [1,2,3] | approve | 0,0,0 | yes,3 | Scheduled | No status guard |
| 15 | — | — | [1,2,3] | approve | 0,0,0 | yes,3 | Ongoing | No status guard |
| 16 | — | — | [1,2,3] | approve | 0,0,0 | yes,3 | Cancelled | No status guard |
| 17 | 'abc' | valid | — | — | — | yes | — | Invalid status string |
| 18 | true | valid | — | — | 0 | yes | — | Boolean true → approve |
| 19 | false | valid | — | — | 0 | yes | — | Boolean false → unapprove |
| 20 | 'on' | valid | — | — | 0 | yes | — | HTML checkbox value → unapprove |
| 21 | — | — | [valid1] | approve | 0 | yes, no vendor | Completed | Bulk approve, no vendor → skip VndUsageLog |
| 22 | — | — | [valid1] | approve | 0 | yes, vendor no agreement | Completed | Bulk approve, no agreement → null agreement_item_id |
| 23 | — | — | [valid1,valid2] | unapprove | 0,0 | yes | Completed | Bulk unapprove already-unapproved |
| 24 | — | — | [soft-deleted] | approve | — | soft-deleted | — | Bulk approve soft-deleted → skipped by SoftDeletes |
| 25 | — | — | [1,2,3] | approve | 0,0,0 | yes | Scheduled, Ongoing, Completed | Bulk approve mixed statuses → all approved |

### Edge Case: VndUsageLog Duplicate Prevention Approach Comparison

| Aspect | toggleApproval (line 662) | bulkApprove (line 764) |
|--------|---------------------------|----------------------|
| Approach | `firstOrCreate(['remarks' => ...], [...])` | `exists()` check + `create()` |
| Race condition safe? | ✅ Yes — atomic find-or-create | ❌ No — non-atomic check-then-create |
| Readable? | ✅ Single ORM call | ❌ Two-step process |
| Returns model | ✅ Returns existing or new model | ❌ Must re-fetch if needed |
| Performance | ✅ Single query | ❌ Two queries per trip (exists + create) |
| Consistency | Used here | Different approach |
| SQL generated | `SELECT ... WHERE remarks=?` then `INSERT` or none | `SELECT COUNT(*) WHERE remarks=?` then `INSERT` |

### Unique Code Paths Identified:
- **Path A**: Toggle approve with vendor → full log creation (BC-BIZ-01)
- **Path B**: Toggle approve without vendor → skip log (BC-BIZ-04)
- **Path C**: Toggle unapprove with existing log → delete log (BC-BIZ-02)
- **Path D**: Toggle unapprove without log → silent delete 0 rows (BC-BIZ-D15)
- **Path E**: Bulk approve with all unapproved → process all (BC-BIZ-05 opposite)
- **Path F**: Bulk approve with mix → skip some (BC-BIZ-05)
- **Path G**: Bulk approve with all approved → skip all (BC-BIZ-D07)
- **Path H**: Bulk unapprove → delete logs + reset (BC-BIZ-07)
- **Path I**: Missing/non-existent trip → 404 (BC-BIZ-09)
- **Path J**: Invalid action → 422 validation (BC-VAL-02)

---

## 15. Comparison with Gold Standard (Vendor Module)

| Aspect | Gold Standard (Vendor Module) | Trip Approval | Gap |
|--------|------------------------------|---------------|-----|
| Controller Gate::authorize() | At start of every method | ✅ toggleApproval, bulkApprove | — |
| FormRequest validation | Uses `$request->validated()` | ❌ toggleApproval uses raw `$request->id` | G07 |
| activityLog() after mutation | Every create/update/delete | ❌ Not called in either method | G01, G02 |
| Pagination appends tab param | `$records->appends(['tab'=>'{id}'])->links()` | ❌ Uses plain `$TripData->links()` | G08 |
| Paginator unique name per tab | Unique page names per tab | ❌ Shared `TripData` with default page name | G21 |
| Tab permission double security | permission key + @can | ✅ Both implemented | — |
| Th/td symmetrical @can | Matched wrapper pairs | ✅ Mostly matched (status, action) | — |
| Policy method for every permission | All used in controller | ❌ 6 orphaned policy methods | G11-G16 |
| Delete button in action column | Present with form | ❌ delete permission in @canany but no button | G10 |
| Form type="text" required | Always passed | N/A (no create/edit for approval) | — |

---

## 16. Test Environment Requirements

| Requirement | Value | Notes |
|-------------|-------|-------|
| PHP Version | 8.0+ (uses null-safe operator `?->` on line 657) | PHP 8.0+ required |
| Laravel Version | 8.x / 9.x | Gate::authorize, SoftDeletes |
| Database | MySQL / MariaDB | `information_schema` queries used in DDL test |
| Dusk | Laravel Dusk | Browser automation for UI tests |
| Vendor Module | `Modules\Vendor` | Required for VndUsageLog creation |
| Tenancy | Multi-tenant (stancl/tenancy) | `tenancy()->initialize()` in test setUp |
| Browser | Chrome + ChromeDriver | Dusk requirement |
| Seed Data | Shift, Route, Vehicle, Driver, RouteScheduler | Required for trip creation |

### Required Seed Data Insertion Order:
```sql
-- 1. Shift (tpt_shift)
INSERT INTO tpt_shift (code, name, effective_from, effective_to, is_active)
VALUES ('SH-TA-001', 'Morning Shift', '2026-01-01', '2026-12-31', 1);

-- 2. Route (tpt_route) -- requires route_geometry (MSSQL specific)
INSERT INTO tpt_route (code, name, pickup_drop, shift_id, route_geometry, is_active)
VALUES ('RT-TA-001', 'Route 1', 'Pickup', 1, geometry::STGeomFromText('LINESTRING(0 0, 1 1)', 0), 1);

-- 3. Vehicle (tpt_vehicle)
INSERT INTO tpt_vehicle (vehicle_no, registration_no, capacity, max_capacity, is_active, availability_status)
VALUES ('VH-TA-001', 'REG-TA-001', 40, 50, 1, 1);

-- 4. Driver (tpt_personnel)
INSERT INTO tpt_personnel (user_qr_code, id_card_type, name, role, is_active)
VALUES ('QR-TA-001', 'QR', 'Driver Test', 'Driver', 1);

-- 5. Route Scheduler (tpt_route_scheduler_jnt)
INSERT INTO tpt_route_scheduler_jnt (scheduled_date, shift_id, route_id, vehicle_id, driver_id, pickup_drop, is_active)
VALUES ('2026-07-22', 1, 1, 1, 1, 'Pickup', 1);

-- 6. Trip (tpt_trip) — for approval testing
INSERT INTO tpt_trip (trip_date, route_scheduler_id, route_id, vehicle_id, driver_id, status, start_odometer_reading, end_odometer_reading, approved)
VALUES ('2026-07-22', 1, 1, 1, 1, 'Completed', 100.00, 150.00, 0);
```

### Test Cleanup SQL:
```sql
-- Cleanup order matters (child records first)
DELETE FROM tpt_trip_stop_detail WHERE trip_id IN (SELECT id FROM tpt_trip WHERE remarks LIKE 'Trip Approve test -%');
DELETE FROM tpt_trip_incidents WHERE trip_id IN (SELECT id FROM tpt_trip WHERE remarks LIKE 'Trip Approve test -%');
DELETE FROM tpt_student_event_log WHERE trip_id IN (SELECT id FROM tpt_trip WHERE remarks LIKE 'Trip Approve test -%');
DELETE FROM tpt_gps_trip_log WHERE trip_id IN (SELECT id FROM tpt_trip WHERE remarks LIKE 'Trip Approve test -%');
DELETE FROM vnd_usage_logs WHERE remarks LIKE 'Trip Approved (Trip ID:%';
DELETE FROM tpt_trip WHERE remarks LIKE 'Trip Approve test -%';
```

---

## 17. Dusk Test Implementation Status

| Test Method | Status | Lines | Key Assertions | Missing Coverage |
|-------------|--------|-------|----------------|------------------|
| test_ddl_conditions | ✅ Implemented | 71 | Column types, defaults, indexes | None |
| test_tab_pane_renders | ✅ Implemented | 18 | Pane visible, filters present | None |
| test_table_displays_trip_data | ✅ Implemented | 24 | Columns visible, approve-switch | None |
| test_search_by_route_vehicle_driver | ✅ Implemented | 30 | Search filter works | Exact match count |
| test_filter_by_approval_status | ✅ Implemented | 32 | Filter approved/unapproved | Dual browser sessions used |
| test_individual_approve_toggle | ✅ Implemented | 31 | approved=1, by, at | VndUsageLog not checked |
| test_individual_unapprove_toggle | ✅ Implemented | 29 | approved=0 | VndUsageLog deletion not checked |
| test_bulk_approve_action | ✅ Implemented | 36 | All 3 approved | VndUsageLog count not checked |
| test_bulk_unapprove_action | ✅ Implemented | 32 | All 0 | VndUsageLog deletion not checked |
| test_empty_state_no_trips | ✅ Implemented | 16 | 'No trips found' | None |
| test_pagination_shows_with_11_records | ✅ Implemented | 23 | .pagination exists | None |
| test_pagination_hidden_with_5_records | ✅ Implemented | 23 | .pagination missing | None |
| test_pagination_navigates_page_2 | ✅ Implemented | 36 | URL has page=2, tab param | None |
| test_pagination_preserves_tab | ✅ Implemented | 43 | Links contain tab param | None |
| test_guest_redirect | ✅ Implemented | 8 | Redirect to /login | None |
| test_403_forbidden | ✅ Implemented | 31 | 403 without viewAny | Permission restore verified |
| test_forbidden_without_view_any | ✅ Implemented | 25 | 403 restricted user | None |
| test_forbidden_without_approve | ✅ Implemented | 25 | 403 no approve perm | Uses trip_id param (not id) |
| test_forbidden_without_bulk_approve | ✅ Implemented | 27 | 403 no bulkApprove perm | None |

### Implementation Quirks Noted in Dusk Tests:
1. `test_forbidden_without_approve_permission` (line 607): POSTs with `trip_id` instead of `id` — testing that missing `id` param causes the 403 gate error first (not the 404). Since Gate throws before validation, this is fine.
2. `test_filter_by_approval_status`: Uses TWO separate browser sessions (lines 234, 236) instead of one session with sequential filter changes.
3. `resolveDependencies()` (line 756): Uses raw DB inserts, not factories — faster but less realistic (bypasses model boot hooks).

---

## 18. SQL Query Reference for Test Validation

### Verify Approval State After Toggle
```sql
SELECT id, approved, approved_by, approved_at,
       start_odometer_reading, end_odometer_reading,
       (SELECT MAX(0, ROUND(end_odometer_reading - start_odometer_reading, 2))) AS calculated_distance
FROM tpt_trip WHERE id = {tripId};
```

### Verify VndUsageLog Created
```sql
SELECT ul.id, ul.vendor_id, ul.agreement_item_id,
       ul.usage_date, ul.qty_used, ul.remarks, ul.logged_by,
       v.vendor_name AS vendor_name
FROM vnd_usage_logs ul
LEFT JOIN vnd_vendors v ON v.id = ul.vendor_id
WHERE ul.remarks LIKE 'Trip Approved (Trip ID: {tripId}%';
```

### Verify Approval Filters in Tab Query
```sql
-- Simulates TripQuery() approval_status filter
SELECT * FROM tpt_trip
WHERE approved = 1  -- or 0 for unapproved
ORDER BY trip_date DESC
LIMIT 10;
```

### Verify VndUsageLog Deleted After Unapprove
```sql
SELECT COUNT(*) AS log_count
FROM vnd_usage_logs
WHERE remarks = 'Trip Approved (Trip ID: {tripId})';
-- Expected: 0
```

### Check for Orphaned VndUsageLogs (logs with no matching trip)
```sql
SELECT ul.*
FROM vnd_usage_logs ul
WHERE ul.remarks LIKE 'Trip Approved (Trip ID:%'
  AND NOT EXISTS (
    SELECT 1 FROM tpt_trip t
    WHERE CONCAT('Trip Approved (Trip ID: ', t.id, ')') = ul.remarks
  );
```

### Permission Assignment Check
```sql
-- Check a user's trip-approve permissions
SELECT p.name, p.guard_name
FROM permissions p
JOIN model_has_permissions mhp ON mhp.permission_id = p.id
WHERE mhp.model_id = {userId}
  AND p.name LIKE 'tenant.trip-approve.%';
```

---

## 19. Remediation Recommendations

| Gap ID | Recommendation | Effort | Impact |
|--------|---------------|--------|--------|
| G01, G02 | Add `activityLog()` calls in toggleApproval and bulkApprove | 1 hour | HIGH — audit trail |
| G03 | Add trip status validation: only allow approve if `$trip->status === 'Completed'` | 1 hour | HIGH — data integrity |
| G04 | Fix success message: count actually processed trips, not input IDs | 30 min | MEDIUM — accurate reporting |
| G05 | Standardize: use `firstOrCreate` in bulkApprove (same as toggle) | 30 min | MEDIUM — consistency |
| G06 | Add null-safe chain or `optional()` wrapper on entire chain in bulkApprove | 30 min | HIGH — prevent crash |
| G07 | Add `$request->validate(['id'=>'required|integer', 'status'=>'required|in:0,1'])` | 1 hour | MEDIUM — input validation |
| G08 | Change `$TripData->links()` to `$TripData->appends(['tab'=>'trip_approve'])->links()` | 30 min | MEDIUM — UX |
| G10 | Either add delete button or remove delete from @canany | 30 min | LOW — clarity |
| G11-G16 | Either implement controller methods for these policies or remove orphaned policy methods | 4 hours | MEDIUM — dead code |
| G17 | Add `trip_id` column to VndUsageLog or use Eloquent relationship for deletion | 2 hours | MEDIUM — data integrity |
| G18 | Wrap approval logic in `DB::transaction()` with row lock | 2 hours | MEDIUM — concurrency |
| G19 | Add tenant scope to bulk approve query: `->whereHas('routeScheduler', tenantScope)` | 2 hours | HIGH — tenant isolation |
| G20 | Add `Auth::check()` guard before using `Auth::user()->id` | 30 min | MEDIUM — stability |
| G21 | Add unique paginator name for trip_approve data | 15 min | LOW — avoids cross-tab pagination conflicts |
| G22 | Use strict comparison `$request->status === 1` or add `in:0,1` validation | 15 min | LOW — prevents type confusion |
| G23 | Add test for VndUsageLog creation in approve scenario | 2 hours | HIGH — test coverage gap |
| G24 | Add test for VndUsageLog deletion in unapprove scenario | 2 hours | HIGH — test coverage gap |

---

## 20. Controller Code Anomalies Log

| # | Anomaly | Location | Detail |
|---|---------|----------|--------|
| A01 | Duplicate comment line | TripController:648-650 | `// ✅ APPROVE` appears twice (lines 648 and 650) |
| A02 | Inconsistent `!=` vs `!==` | TripController:678 | Uses `$request->status != 1` (loose) — should consider `!==` for strictness |
| A03 | Missing blank line after Gate | TripController:634-636 | Extra blank line before trip find (cosmetic) |
| A04 | Optional chain inconsistency | TripController:657 vs 771 | toggle uses `$trip->routeScheduler?->vehicle?->vendor`, bulk uses `$trip->routeScheduler->vehicle->vendor` |
| A05 | Variable naming | TripController:645,761 | `$distanceUsed` in toggle vs same calc in bulk (unnamed in bulk, part of larger expression) |
| A06 | SoftDeletes behaviour | TripController:637 | `TptTrip::find()` respects SoftDeletes — deleted trips not found. May surprise testers who soft-delete then try to approve |
| A07 | Blade colspan hardcoded | index.blade.php:135 | `colspan="10"` — if columns are conditionally hidden, colspan value is wrong |
| A08 | Blade @canany misuse | index.blade.php:70 | `@canany(['tenant.trip-approve.status'])` — array with single item should be `@can` |
| A09 | No CSRF exemption | web.php:165-166 | Routes not in `except` array — JS properly sends `_token` |
| A10 | Controller imports unused | TripController:8 | `Modules\Transport\Http\Requests\TripRequest` imported but not used in approval methods |

---

(End of file)
