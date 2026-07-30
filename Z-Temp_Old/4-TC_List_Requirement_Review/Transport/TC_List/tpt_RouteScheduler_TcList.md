# tpt_RouteScheduler_TcList

## Module: Transport → Trip Management → Route Scheduler

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | Transport |
| Tab Group | Trip Management |
| Feature | Route Scheduler |
| URL(s) | `/transport/trip-management?tab=scheduler` (index via tab), `/route-scheduler/create` (create form), `/route-scheduler` (store), `/route-scheduler/{id}` (show), `/route-scheduler/{id}/edit` (edit), `/route-scheduler/{id}` (update PUT), `/route-scheduler/{id}` (destroy DELETE), `/route-scheduler/trash/view` (trash), `/route-scheduler/{id}/restore` (restore GET), `/route-scheduler/{id}/force-delete` (forceDelete DELETE), `/route-scheduler/{scheduler}/toggle-status` (toggleStatus POST), `/driver-route-vehicle/create-trip` (createtrip POST), `/driver-route-vehicle/store-trip` (storeTrip POST) |
| Controller | `Modules\Transport\Http\Controllers\RouteSchedulerController` |
| Tab Container Controller | `Modules\Transport\Http\Controllers\TripMgmtController@index()` — tab: `scheduler` |
| Model | `Modules\Transport\Models\TptRouteSchedulerJnt` — table: `tpt_route_scheduler_jnt` |
| Validation | `Modules\Transport\Http\Requests\RouteSchedulerRequest` |
| Permissions | `tenant.route-scheduler.viewAny`, `tenant.route-scheduler.view`, `tenant.route-scheduler.create`, `tenant.route-scheduler.update`, `tenant.route-scheduler.edit`, `tenant.route-scheduler.delete`, `tenant.route-scheduler.restore`, `tenant.route-scheduler.forceDelete`, `tenant.route-scheduler.status` + `tenant.driver-route-vehicle.update` (for createtrip/storeTrip) |
| Soft Deletes | Yes (`TptRouteSchedulerJnt` uses `SoftDeletes` trait) |
| Activity Log | Events: `Created`, `Updated`, `Deleted`, `Restored`, `ForceDelete`, `Toggled` |
| Trip Generation | `createtrip()` + `storeTrip()` methods generate TptTrip records from selected scheduler entries |

---

## 2. Pre-conditions

- Required permissions: `tenant.route-scheduler.*` as listed above
- Required seed data: Active `Shift`, `Route`, `Vehicle`, `DriverHelper` (personnel)
- Test user must have all above permissions
- Tenant context must be initialized via `tenancy()->initialize()`
- The scheduler tab is part of TripManagement — URL: `/transport/trip-management?tab=scheduler`
- Unique constraint: `uq_route_scheduler_schedDate_shift_route` — prevents duplicate same date/shift/route/pickup_drop
- Unique constraints also prevent same vehicle/driver/helper from being on multiple schedules on the same date/shift

---

## 3. Default Data Load

When loaded via TripMgmtController@index():

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| Scheduler Grid | `TripMgmtController@SchedulerQuery()` | `TptRouteSchedulerJnt::with(['route','shift','vehicle','driver'])->withCount('trips')->orderByDesc('id')` | tab=scheduler: `status`, `schedule_date`, `shift_id`, `route_id`, `vehicle_id`, `driver_id`, `helper_id` | 10/page |

---

## 4. Test Data Strategy

- Scheduler entries require valid FK references: shift, route, vehicle, driver, helper
- `scheduled_date` is required and must be a valid date
- Duplicate check on store/update: checks same shift_id + route_id + vehicle_id + driver_id + scheduled_date
- `createtrip` receives comma-separated IDs via `selected_ids` POST parameter
- `storeTrip` creates TptTrip records from selected scheduler entries; prevents duplicates by checking `trip_date` + `route_scheduler_id`
- Status transitions on generated trips follow: `Scheduled → Ongoing → Completed` or `Scheduled → Cancelled`

---

## 5. Business Conditions

### 5.1 Database Schema — `tpt_route_scheduler_jnt`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | id | INT UNSIGNED | PK, auto-increment |
| BC-DB-02 | scheduled_date | DATE | NOT NULL |
| BC-DB-03 | shift_id | INT UNSIGNED | NOT NULL, FK → tpt_shift.id, ON DELETE RESTRICT |
| BC-DB-04 | route_id | INT UNSIGNED | NOT NULL, FK → tpt_route.id, ON DELETE CASCADE |
| BC-DB-05 | vehicle_id | INT UNSIGNED | DEFAULT NULL, FK → tpt_vehicle.id, ON DELETE SET NULL |
| BC-DB-06 | driver_id | INT UNSIGNED | DEFAULT NULL, FK → tpt_personnel.id, ON DELETE SET NULL |
| BC-DB-07 | helper_id | INT UNSIGNED | DEFAULT NULL, FK → tpt_personnel.id, ON DELETE SET NULL |
| BC-DB-08 | pickup_drop | ENUM('Pickup','Drop') | NOT NULL, DEFAULT 'Pickup' |
| BC-DB-09 | is_active | TINYINT(1) | NOT NULL, DEFAULT 1 |
| BC-DB-10 | created_at | TIMESTAMP | NULL, DEFAULT CURRENT_TIMESTAMP |
| BC-DB-11 | updated_at | TIMESTAMP | NULL, DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP |
| BC-DB-12 | deleted_at | TIMESTAMP | NULL |

Unique Keys:
- `uq_route_scheduler_schedDate_shift_route` (scheduled_date, shift_id, route_id, pickup_drop)
- `uq_route_scheduler_vehicle_schedDate_shift` (vehicle_id, scheduled_date, shift_id, pickup_drop)
- `uq_route_scheduler_driver_schedDate_shift` (driver_id, scheduled_date, shift_id, pickup_drop)
- `uq_route_scheduler_helper_schedDate_shift` (helper_id, scheduled_date, shift_id, pickup_drop)

### 5.2 Validation Rules — `RouteSchedulerRequest`

| BC ID | Field | Rule |
|-------|-------|------|
| BC-VAL-01 | shift_id | required |
| BC-VAL-02 | route_id | required |
| BC-VAL-03 | vehicle_id | required |
| BC-VAL-04 | driver_id | required |
| BC-VAL-05 | scheduled_date | required, date |
| BC-VAL-06 | helper_id | nullable |
| BC-VAL-07 | pickup_drop | nullable, string |
| BC-VAL-08 | is_active | nullable, boolean |

Note: No `exists:` validation rules — the request does NOT validate FK existence.

### 5.3 Authorization (Permission Gates)

| BC ID | Permission | Method | Behavior |
|-------|-----------|--------|----------|
| BC-AUTH-01 | tenant.route-scheduler.viewAny | index() | Without → 403 |
| BC-AUTH-02 | tenant.route-scheduler.view | show() | Without → 403 |
| BC-AUTH-03 | tenant.route-scheduler.create | store(), create() | Without → 403 |
| BC-AUTH-04 | tenant.route-scheduler.update | update(), edit() | Without → 403 |
| BC-AUTH-05 | tenant.route-scheduler.delete | destroy() | Without → 403 |
| BC-AUTH-06 | tenant.route-scheduler.restore | restore(), trashed() | Without → 403 |
| BC-AUTH-07 | tenant.route-scheduler.forceDelete | forceDelete() | Without → 403 |
| BC-AUTH-08 | tenant.route-scheduler.update | toggleStatus() | Without → 403 |
| BC-AUTH-09 | tenant.driver-route-vehicle.update | createtrip(), storeTrip() | Without → 403 |

### 5.4 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Create new scheduler entry | Record created with validated data; redirect to trip-management index |
| BC-BIZ-02 | Duplicate schedule (same date/shift/route/vehicle/driver) | Controller returns 'already exists' error |
| BC-BIZ-03 | Activity log on create | `activityLog($data, 'Created', ['message' => 'Route scheduled successfully.'])` |
| BC-BIZ-04 | Update schedule | Duplicate check excludes current ID; record updated |
| BC-BIZ-05 | Activity log on update | `activityLog($record, 'Updated', ['message' => 'Route schedule updated.'])` |
| BC-BIZ-06 | Soft delete | `$record->delete()` — sets deleted_at |
| BC-BIZ-07 | Activity log on soft delete | `activityLog($record, 'Deleted', ['message' => 'Route schedule moved to trash.'])` |
| BC-BIZ-08 | Show trash | `TptRouteSchedulerJnt::onlyTrashed()->paginate(20)` |
| BC-BIZ-09 | Restore from trash | `onlyTrashed()->findOrFail()` → `$record->restore()`; `activityLog($record, 'Restored', ['message' => 'Route schedule restored.'])` |
| BC-BIZ-10 | Force delete | `onlyTrashed()->findOrFail()` → `$record->forceDelete()`; `activityLog($record, 'ForceDelete', ['message' => 'Route schedule permanently deleted.'])` |
| BC-BIZ-11 | Toggle status | Inverts `is_active`; `activityLog($scheduler, 'Toggled', ['message' => 'Status updated.'])`; returns JSON `{success: true, is_active, message}` |
| BC-BIZ-12 | createtrip — opens trip creation page | Loads view with selectedRecords, routes, shifts, vehicles, driverHelpers |
| BC-BIZ-13 | storeTrip — generates trips from selected schedulers | Creates TptTrip for each scheduler; skips existing; reports created/skipped/compliance-skipped counts |
| BC-BIZ-14 | storeTrip — trip data sourced from scheduler | trip_date = scheduled_date, route_scheduler_id, route_id, shift_id, vehicle_id, driver_id, helper_id, start_time from shift, status='Active' |
| BC-BIZ-15 | storeTrip — compliance/license validation | If TptTrip model boot() throws DomainException (expired license/fitness/insurance), the trip is skipped and counted as complianceSkipped |

| BC-BIZ-16 | storeTrip — activityLog NOT called | `storeTrip()` creates `TptTrip` records but does NOT call `activityLog()` for any created/skipped trips — potential audit trail gap |

### 5.5 Model Relationships — `TptRouteSchedulerJnt`

| BC ID | Relationship | Type | Foreign Key | Notes |
|-------|-------------|------|-------------|-------|
| BC-REL-01 | shift() | BelongsTo Shift | shift_id | |
| BC-REL-02 | route() | BelongsTo Route | route_id | |
| BC-REL-03 | vehicle() | BelongsTo Vehicle | vehicle_id | |
| BC-REL-04 | driver() | BelongsTo DriverHelper | driver_id | |
| BC-REL-05 | helper() | BelongsTo DriverHelper | helper_id | |
| BC-REL-06 | trips() | HasMany TptTrip | route_scheduler_id | withCount('trips') in SchedulerQuery |

---

## 6. Test Case List

### 6.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | Scheduler Tab Loads Inside Trip Management | `/transport/trip-management?tab=scheduler` loads with filter bar, table, Add button | — | — | ⬜ |
| TC-P02 | Create Scheduler Entry | POST `/route-scheduler` with valid data → record created; redirect with success | — | — | ⬜ |
| TC-P03 | View Scheduler Entry | `/route-scheduler/{id}` shows all fields with relations | — | — | ⬜ |
| TC-P04 | Edit Scheduler Loads Pre-Filled Data | `/route-scheduler/{id}/edit` shows existing values | — | — | ⬜ |
| TC-P05 | Update Scheduler | PUT `/route-scheduler/{id}` → record updated; activityLog `Updated` entry verified in `activity_log` table | — | — | ⬜ |
| TC-P06 | Soft Delete Scheduler | DELETE → deleted_at set; activityLog `Deleted` entry created; hidden from main list | — | — | ⬜ |
| TC-P07 | Trash Page Shows Deleted Schedulers | `/route-scheduler/trash/view` → list with Restore and Force Delete | — | — | ⬜ |
| TC-P08 | Restore Scheduler From Trash | GET `/route-scheduler/{id}/restore` → record restored; activityLog `Restored` entry created | — | — | ⬜ |
| TC-P09 | Force Delete Scheduler | DELETE `/route-scheduler/{id}/force-delete` → permanently removed; activityLog `ForceDelete` entry created | — | — | ⬜ |
| TC-P10 | Toggle Status | POST → is_active toggled; activityLog `Toggled` entry created; JSON response | — | — | ⬜ |
| TC-P11 | createtrip — Load Selection Page | POST `/driver-route-vehicle/create-trip` with selected_ids → create trip view loads | — | — | ⬜ |
| TC-P12 | storeTrip — Generate Trips From Multiple Schedulers | POST `/driver-route-vehicle/store-trip` → trips created for each scheduler; success message with count | — | — | ⬜ |
| TC-P13 | storeTrip — Skip Duplicate Trips | Run storeTrip twice → second run skips existing; message says 'X trip(s) skipped' | — | — | ⬜ |
| TC-P14 | Filter by Schedule Date | Select date → matching records shown | — | — | ⬜ |
| TC-P15 | Filter by Shift/Route/Vehicle/Driver | Dropdown filters work | — | — | ⬜ |
| TC-P16 | Empty State — No Records | "No Data Found" | — | — | ⬜ |
| TC-P17 | Empty State — No Trashed Records | "No Data Found" in trash | — | — | ⬜ |

### 6.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | Required — Missing scheduled_date | Validation error | — | — | ⬜ |
| TC-N02 | Required — Missing shift_id | Validation error | — | — | ⬜ |
| TC-N03 | Required — Missing route_id | Validation error | — | — | ⬜ |
| TC-N04 | Required — Missing vehicle_id | Validation error | — | — | ⬜ |
| TC-N05 | Required — Missing driver_id | Validation error | — | — | ⬜ |
| TC-N06 | Duplicate — Same date/shift/route/vehicle/driver | Controller 'already exists' error | — | — | ⬜ |
| TC-N07 | Duplicate — DB unique constraint | Try inserting duplicate via DB → integrity violation | — | — | ⬜ |
| TC-N08 | View With Invalid ID | `/route-scheduler/99999` → 404 | — | — | ⬜ |
| TC-N09 | Edit With Invalid ID | 404 | — | — | ⬜ |
| TC-N10 | Update With Invalid ID | 404 | — | — | ⬜ |
| TC-N11 | Delete With Invalid ID | 404 | — | — | ⬜ |
| TC-N12 | Restore Non-Deleted Record | 404 | — | — | ⬜ |
| TC-N13 | Force Delete Non-Trashed Record | 404 | — | — | ⬜ |
| TC-N14 | storeTrip — No Valid Schedules Selected | POST with invalid selected_ids → error 'No valid schedules selected!' | — | — | ⬜ |
| TC-N15 | storeTrip — Empty selected_ids | Validation error: 'selected_ids is required' | — | — | ⬜ |
| TC-N16 | storeTrip — Missing trip_date | Validation error | — | — | ⬜ |
| TC-N17 | Permission 403 — viewAny (index) | GET `/transport/trip-management?tab=scheduler` w/o `viewAny` → 403 | — | — | ⬜ |
| TC-N18 | Permission 403 — view (show) | GET `/route-scheduler/{id}` w/o `view` → 403 | — | — | ⬜ |
| TC-N19 | Permission 403 — create (store) | POST `/route-scheduler` w/o `create` → 403 | — | — | ⬜ |
| TC-N20 | Permission 403 — update (edit + update + toggleStatus) | GET `/route-scheduler/{id}/edit`, PUT `/route-scheduler/{id}`, POST `/route-scheduler/{id}/toggle-status` w/o `update` → 403 | — | — | ⬜ |
| TC-N21 | Permission 403 — delete (destroy) | DELETE `/route-scheduler/{id}` w/o `delete` → 403 | — | — | ⬜ |
| TC-N22 | Permission 403 — restore (trashed + restore) | GET `/route-scheduler/trash/view`, GET `/route-scheduler/{id}/restore` w/o `restore` → 403 | — | — | ⬜ |
| TC-N23 | Permission 403 — forceDelete | DELETE `/route-scheduler/{id}/force-delete` w/o `forceDelete` → 403 | — | — | ⬜ |
| TC-N24 | Permission 403 — driver-route-vehicle.update (createtrip + storeTrip) | POST `/driver-route-vehicle/create-trip`, POST `/driver-route-vehicle/store-trip` w/o `tenant.driver-route-vehicle.update` → 403 | — | — | ⬜ |
| TC-N25 | Guest Access | All URLs redirect to `/login` when unauthenticated | — | — | ⬜ |
| TC-N26 | XSS Injection | `<script>` stored as literal; Blade escapes output | — | — | ⬜ |

### 6.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|----------------|---------|---------|--------|
| TC-D01 | A | Trip Generation — Compliance Skipped | Driver with expired license → trip creation silently skipped; counted in complianceSkipped | — | — | ⬜ |
| TC-D02 | B | Route Deletion — CASCADE to Scheduler | DDL CASCADE on route_id → scheduler records auto-deleted | — | — | ⬜ |
| TC-D03 | C | Vehicle/Driver SET NULL on Deletion | DDL SET NULL on vehicle_id/driver_id/helper_id → references nullified | — | — | ⬜ |
| TC-D04 | D | Shift RESTRICT on Scheduler Delete | Cannot delete shift if scheduler references it (DDL RESTRICT) | — | — | ⬜ |
| TC-D05 | E | Trip Exists for Scheduler — Restrict Delete | attempt soft-delete → should succeed (scheduler has no FK protection from trip — DDL allows) | — | — | ⬜ |
| TC-D06 | F | DriverRouteVehicle Update Rebuilds Scheduler | Updating driver-route-vehicle force-deletes old scheduler and upserts new one | — | — | ⬜ |

### 6.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|-----------------|---------|---------|--------|
| TC-CR01 | CR | P1 | Controller — Gate::authorize() Before Every Method | All public methods have Gate check as first line | — | — | ◌ |
| TC-CR02 | CR | P1 | Controller — activityLog for All CRUD | Created, Updated, Deleted, Restored, ForceDelete, Toggled | — | — | ◌ |
| TC-CR03 | CR | P1 | Controller — Duplicate Check on Store | `where(shift_id,route_id,vehicle_id,driver_id,scheduled_date)->exists()` | — | — | ◌ |
| TC-CR04 | CR | P1 | Controller — Duplicate Check on Update | Same but excludes current ID | — | — | ◌ |
| TC-CR05 | CR | P1 | Controller — onlyTrashed for Restore and ForceDelete | Both use `onlyTrashed()->findOrFail()` | — | — | ◌ |
| TC-CR06 | CR | P1 | Controller — pickup_drop NOT set during create? | Fixed at line 79: `'pickup_drop' => $request->pickup_drop` — present | — | — | ◌ |
| TC-CR07 | CR | P1 | Request — authorize() matches controller gates | POST → create; PUT/PATCH → update | — | — | ◌ |
| TC-CR08 | CR | P1 | Request — Missing `exists:` validations | No `exists:tpt_shift`, `exists:tpt_route`, etc. — potential gap | — | — | ◌ |
| TC-CR09 | CR | P1 | Model — Table Name and SoftDeletes | `protected $table = 'tpt_route_scheduler_jnt'` and `use SoftDeletes` | — | — | ◌ |
| TC-CR10 | CR | P1 | Model — Fillable Fields | shift_id, route_id, vehicle_id, driver_id, helper_id, scheduled_date, is_active, pickup_drop — 8 fields | — | — | ◌ |
| TC-CR11 | CR | P1 | Model — Relationships | shift, route, vehicle, driver, helper, trips (HasMany) — 6 relationships | — | — | ◌ |
| TC-CR12 | CR | P1 | Routes — Resource + Additional Routes | `Route::resource('route-scheduler', ...)` + trashed/restore/forceDelete/toggleStatus + createtrip/storeTrip | — | — | ◌ |
| TC-CR13 | CR | P1 | DDL — Unique Constraints | 4 unique keys covering scheduled_date, shift_id, route_id, vehicle_id, driver_id, helper_id, pickup_drop | — | — | ◌ |
| TC-CR14 | CR | P1 | DDL — FK Constraints | shift (RESTRICT), route (CASCADE), vehicle/driver/helper (SET NULL) | — | — | ◌ |
| TC-CR15 | CR | P1 | Gap — Request doesn't validate pickup_drop | `nullable|string` — no `Rule::in(['Pickup','Drop'])` | — | — | ◌ |
| TC-CR16 | CR | P1 | Gap — Request doesn't validate FK existence | No `exists:` rules for any FK field | — | — | ◌ |
| TC-CR17 | CR | P1 | TripMgmtController — SchedulerQuery filters | status, schedule_date, shift_id, route_id, vehicle_id, driver_id, helper_id | — | — | ◌ |
| TC-CR18 | CR | P1 | Gap — View uses `tenant.route-scheduler.edit` for action column but controller gates on `update` | Actions column visibility gated on `edit`, but controller `edit()` uses `Gate::authorize('...update')` — user with `edit` sees button but gets 403 on click | — | — | ◌ |
| TC-CR19 | CR | P1 | Gap — View uses `tenant.route-scheduler.status` for status column but controller `toggleStatus()` gates on `update` | Status column visibility gated on `status`, but toggle action checks `update` — user with only `status` sees toggle but gets 403 | — | — | ◌ |
| TC-CR20 | CR | P1 | Gap — Edit view offers `Both` for pickup_drop but DDL ENUM only allows `Pickup`/`Drop` | `edit.blade.php` line 173-176: option `Both` present — submitting would fail DB ENUM constraint | — | — | ◌ |
| TC-CR21 | CR | P1 | Gap — `RouteSchedulerController@index()` passes `$data` but tab view expects `$sheduleData` | Hitting `/route-scheduler` directly (resource index) passes `compact('data')`, but view uses `$sheduleData` → undefined variable error | — | — | ◌ |
| TC-CR22 | CR | P1 | Gap — `storeTrip()` does NOT call `activityLog()` | Trips created via `storeTrip()` have no audit trail — no activityLog entry for batch trip creation | — | — | ◌ |
| TC-CR23 | CR | P1 | Gap — `toggleStatus()` calls `$scheduler->save()` twice | Line 312 saves, then line 318 `if ($scheduler->save())` saves again — redundant DB write | — | — | ◌ |
| TC-CR24 | CR | P1 | Gap — `SchedulerQuery()` omits `helper` from eager load | `with(['route','shift','vehicle','driver'])` — `helper` not loaded; view accesses `$item->helper->name` causing N+1 lazy load per row | — | — | ◌ |
| TC-CR25 | CR | P2 | Gap — `hasTrip()` ignores preloaded `trips_count` | `withCount('trips')` preloads count, but `hasTrip()` runs separate `trips()->exists()` query per row | — | — | ◌ |
| TC-CR26 | CR | P2 | Gap — Policy filename uses `transport.` prefix instead of `tenant.` | `RouteSchedulerPolicy` uses `$user->can('transport.route-scheduler.*')` but controller uses `Gate::authorize('tenant.route-scheduler.*')` — mismatch | — | — | ◌ |
| TC-CR27 | CR | P2 | Gap — Policy `status()` parameter type hint uses `Route` instead of `TptRouteSchedulerJnt` | `status(User $user, Route $route)` — wrong model; should be `TptRouteSchedulerJnt` | — | — | ◌ |

---

## 7. Detailed Test Steps

### TC-P12: storeTrip — Generate Trips From Multiple Schedulers

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to Scheduler tab | Scheduler list visible |
| 2 | Select multiple scheduler entries (checkboxes) | Items selected; "Create Trip (N)" button enabled |
| 3 | Click "Create Trip" button | SweetAlert confirmation dialog appears |
| 4 | Confirm "Yes, Create" | Hidden form submits POST `/driver-route-vehicle/store-trip` with selected_ids + trip_date=today |
| 5 | Verify success message | "X trip(s) created successfully! Y trip(s) skipped..." message shown |
| 6 | DB check: `SELECT * FROM tpt_trip WHERE route_scheduler_id IN (...)` | Trip records exist with status='Active' |
| 7 | DB check: trip fields populated from scheduler | trip_date, route_id, shift_id, vehicle_id, driver_id, helper_id match scheduler; start_time/end_time from shift |

### TC-N14: storeTrip — No Valid Schedules Selected

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST `/driver-route-vehicle/store-trip` with selected_ids='99999,99998' | No valid schedules found |
| 2 | Check response | Redirect back with error 'No valid schedules selected!' |

### TC-CR08: Request — Missing `exists:` Validations

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `RouteSchedulerRequest@rules()` | No `exists:tpt_shift,id`, `exists:tpt_route,id`, etc. |
| 2 | POST with invalid shift_id=99999 | Validation passes (no exists rule); DB FK constraint catches it — 500 error |

---

## 7. Detailed Test Steps (Complete)

### 7.1 Positive Test Cases

#### TC-P01: Scheduler Tab Loads Inside Trip Management

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user with `tenant.route-scheduler.viewAny` permission | Authenticated |
| 2 | Navigate to `/transport/trip-management?tab=scheduler` | GET request to `TripMgmtController@index()` |
| 3 | **Verify**: `Gate::authorize('tenant.transport.viewAny')` at `TripMgmtController:38` passes | Authorized — no 403 |
| 4 | **Verify**: `$request->input('tab') === 'scheduler'` at `TripMgmtController:183` | `$tab` = `'scheduler'` — enters scheduler filter block |
| 5 | **Verify**: `SchedulerQuery()` at `TripMgmtController:89` called | `TptRouteSchedulerJnt::with(['route','shift','vehicle','driver'])->withCount('trips')->orderBy('id','DESC')` built |
| 6 | **Verify**: `->paginate(10)` applied | 10 records per page |
| 7 | **Verify**: `$sheduleData` passed to view at `TripMgmtController:109` | Available in `tripmanagement.blade.php` |
| 8 | **Verify**: Blade renders scheduler table with columns: checkbox, Scheduled Date, Shift, Route, Vehicle, Driver, Helper, Pickup/Drop, Status, Trips Count, Actions | Table visible |
| 9 | **Verify**: Filter bar present with: status dropdown, schedule_date picker, shift_id/route_id/vehicle_id/driver_id/helper_id dropdowns | Filter controls render |
| 10 | **Verify**: "Add Scheduler" button visible for users with `tenant.route-scheduler.create` | Create button rendered |
| 11 | **Verify**: Pagination links at bottom if >10 records | `->links()` rendered |
| 12 | **Verify**: No errors in browser console or Laravel debugbar | Page loads cleanly |

#### TC-P02: Create Scheduler Entry

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.route-scheduler.create` permission | Authenticated |
| 2 | Navigate to create form: GET `/route-scheduler/create` | `RouteSchedulerController@create()` at line 40 |
| 3 | **Verify**: `Gate::authorize('tenant.route-scheduler.create')` at line 42 | Authorized |
| 4 | **Verify**: `Route::active()->get()` loaded at line 45 | Routes dropdown populated with active routes |
| 5 | **Verify**: `Shift::active()->get()` loaded at line 46 | Shifts dropdown populated |
| 6 | **Verify**: `Vehicle::active()->get()` loaded at line 47 | Vehicles dropdown populated |
| 7 | **Verify**: `DriverHelper::active()->get()` loaded at line 48 | Driver/Helper dropdowns populated |
| 8 | Fill form: select Shift, Route, Vehicle, Driver | Valid dropdown selections |
| 9 | Fill Helper (optional) or leave null | Helper nullable |
| 10 | Set Scheduled Date = tomorrow's date (valid date) | Date set |
| 11 | Set Pickup/Drop = "Pickup" | Valid selection |
| 12 | Set Active = checked (default) | is_active = 1 |
| 13 | Submit form: POST `/route-scheduler` | `RouteSchedulerController@store()` at line 55 |
| 14 | **Verify**: `Gate::authorize('tenant.route-scheduler.create')` at line 57 | Authorized |
| 15 | **Verify**: `RouteSchedulerRequest@rules()` pass | All required fields present, valid date |
| 16 | **Verify**: Duplicate check at lines 58-63 `where(shift_id,route_id,vehicle_id,driver_id,scheduled_date)->exists()` | Returns false — no duplicate |
| 17 | **Verify**: `TptRouteSchedulerJnt::create([...])` at line 71 | INSERT executed with all 8 fillable fields |
| 18 | **Verify**: `activityLog($data, 'Created', ['message' => 'Route scheduled successfully.'])` at line 82 | Activity log entry created |
| 19 | **Verify**: `redirect()->route('transport.trip-management.index')` at line 84 | Redirect to trip management |
| 20 | **Verify**: Flash message `flash('created.route_scheduler')` | Success toast displayed |
| 21 | DB check: `SELECT * FROM tpt_route_scheduler_jnt ORDER BY id DESC LIMIT 1` | Record exists with all provided values |
| 22 | DB check: `SELECT * FROM activity_log WHERE subject_type = 'TptRouteSchedulerJnt' ORDER BY id DESC LIMIT 1` | Log entry with event='Created' |

#### TC-P03: View Scheduler Entry

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.route-scheduler.view` permission | Authenticated |
| 2 | Navigate to GET `/route-scheduler/{id}` where id is valid | `RouteSchedulerController@show()` at line 181 |
| 3 | **Verify**: `Gate::authorize('tenant.route-scheduler.view')` at line 183 | Authorized |
| 4 | **Verify**: `TptRouteSchedulerJnt::with(['route','shift','vehicle','driver','helper'])->findOrFail($id)` at line 184 | Record found with all eager-loaded relations |
| 5 | **Verify**: View `transport::route-scheduler.show` renders | Show page displays all fields |
| 6 | **Verify**: Relationship data displayed: route name, shift name, vehicle reg no, driver name, helper name | Relations rendered |
| 7 | **Verify**: All scalar fields: scheduled_date, pickup_drop, is_active, created_at, updated_at | Visible on page |

#### TC-P04: Edit Scheduler Loads Pre-Filled Data

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.route-scheduler.update` permission | Authenticated |
| 2 | Navigate to GET `/route-scheduler/{id}/edit` where id is valid | `RouteSchedulerController@edit()` at line 193 |
| 3 | **Verify**: `Gate::authorize('tenant.route-scheduler.update')` at line 195 | Authorized |
| 4 | **Verify**: `TptRouteSchedulerJnt::findOrFail($id)` at line 197 | Record loaded |
| 5 | **Verify**: Supporting data loaded at lines 198-201: `Route::active()->get()`, `Shift::active()->get()`, `Vehicle::active()->get()`, `DriverHelper::active()->get()` | All dropdown data present |
| 6 | **Verify**: Form fields pre-filled with existing values | All inputs show current record values |
| 7 | **Verify**: Dropdowns have correct option selected | shift_id, route_id, vehicle_id, driver_id, helper_id match record |

#### TC-P05: Update Scheduler

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.route-scheduler.update` permission | Authenticated |
| 2 | Open edit form for existing scheduler record | Edit form pre-filled (TC-P04) |
| 3 | Change Scheduled Date to next week | Date updated in form |
| 4 | Change Route selection to a different route | New route selected |
| 5 | Submit: PUT `/route-scheduler/{id}` | `RouteSchedulerController@update()` at line 208 |
| 6 | **Verify**: `Gate::authorize('tenant.route-scheduler.update')` at line 210 | Authorized |
| 7 | **Verify**: Duplicate check at lines 212-218 excludes current ID `->where('id', '!=', $id)` | Returns false — no duplicate conflict |
| 8 | **Verify**: `TptRouteSchedulerJnt::findOrFail($id)` at line 226 | Record found |
| 9 | **Verify**: `$record->update([...])` at line 228 | 8 fields updated in DB |
| 10 | **Verify**: `activityLog($record, 'Updated', ['message' => 'Route schedule updated.'])` at line 239 | Activity log entry created |
| 11 | **Verify**: `redirect()->route('transport.trip-management.index')` at line 241 | Redirect |
| 12 | **Verify**: Flash message `flash('updated.route_scheduler')` | Success toast |
| 13 | DB check: `SELECT * FROM tpt_route_scheduler_jnt WHERE id = X` | Fields updated to new values |
| 14 | DB check: Activity log has 'Updated' event for this record | Audit trail complete |

#### TC-P06: Soft Delete Scheduler

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.route-scheduler.delete` permission | Authenticated |
| 2 | Navigate to scheduler list on Trip Management tab | Record visible |
| 3 | Click delete icon on a scheduler record | DELETE `/route-scheduler/{id}` |
| 4 | **Verify**: `Gate::authorize('tenant.route-scheduler.delete')` at line 250 | Authorized |
| 5 | **Verify**: `TptRouteSchedulerJnt::findOrFail($id)` at line 251 | Record found (not trashed yet) |
| 6 | **Verify**: `$record->delete()` at line 252 | Soft delete — `deleted_at` = NOW() |
| 7 | **Verify**: `activityLog($record, 'Deleted', ['message' => 'Route schedule moved to trash.'])` at line 254 | Activity log entry |
| 8 | **Verify**: `redirect()->route('transport.trip-management.index')` at line 256 | Redirect |
| 9 | **Verify**: Flash message `flash('trashed.route_scheduler')` | Success toast |
| 10 | DB check: `SELECT deleted_at FROM tpt_route_scheduler_jnt WHERE id = X` | `deleted_at` IS NOT NULL |
| 11 | **Verify**: Record NOT visible in scheduler tab (TripMgmtController SchedulerQuery uses base model without ->withTrashed()) | Hidden from default list |

#### TC-P07: Trash Page Shows Deleted Schedulers

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.route-scheduler.restore` permission | Authenticated |
| 2 | Navigate to GET `/route-scheduler/trash/view` | `RouteSchedulerController@trashed()` at line 263 |
| 3 | **Verify**: `Gate::authorize('tenant.route-scheduler.restore')` at line 265 | Authorized |
| 4 | **Verify**: `TptRouteSchedulerJnt::onlyTrashed()->paginate(20)` at line 266 | Only soft-deleted records, 20 per page |
| 5 | **Verify**: Each row has Restore and Force Delete action buttons | Actions rendered |
| 6 | **Verify**: "No Data Found" when trash is empty | Empty state message displayed |

#### TC-P08: Restore Scheduler From Trash

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.route-scheduler.restore` permission | Authenticated |
| 2 | Navigate to trash page | Trash list visible |
| 3 | Click Restore on a trashed record | GET `/route-scheduler/{id}/restore` |
| 4 | **Verify**: `Gate::authorize('tenant.route-scheduler.restore')` at line 275 | Authorized |
| 5 | **Verify**: `TptRouteSchedulerJnt::onlyTrashed()->findOrFail($id)` at line 276 | Found in trash |
| 6 | **Verify**: `$record->restore()` at line 278 | `deleted_at` set to NULL |
| 7 | **Verify**: `activityLog($record, 'Restored', ['message' => 'Route schedule restored.'])` at line 280 | Activity log entry |
| 8 | **Verify**: `redirect()->route('transport.trip-management.index')` at line 283 | Redirect |
| 9 | **Verify**: Flash message `flash('restored.route_scheduler')` | Success toast |
| 10 | DB check: `SELECT deleted_at FROM tpt_route_scheduler_jnt WHERE id = X` | `deleted_at` IS NULL |
| 11 | **Verify**: Record reappears in scheduler tab | Back in active list |

#### TC-P09: Force Delete Scheduler

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.route-scheduler.forceDelete` permission | Authenticated |
| 2 | Ensure record is soft-deleted first | `deleted_at` IS NOT NULL |
| 3 | Navigate to trash page | Trash list |
| 4 | Click Force Delete on a trashed record | DELETE `/route-scheduler/{id}/force-delete` |
| 5 | **Verify**: `Gate::authorize('tenant.route-scheduler.forceDelete')` at line 292 | Authorized |
| 6 | **Verify**: `TptRouteSchedulerJnt::onlyTrashed()->findOrFail($id)` at line 293 | Found in trash |
| 7 | **Verify**: `activityLog($record, 'ForceDelete', ['message' => 'Route schedule permanently deleted.'])` at lines 295-297 | Activity log entry BEFORE forceDelete (line 295 executes before line 299) |
| 8 | **Verify**: `$record->forceDelete()` at line 299 | Permanently removed from DB |
| 9 | **Verify**: `redirect()->route('transport.trip-management.index')` at line 301 | Redirect |
| 10 | **Verify**: Flash message `flash('force_deleted.route_scheduler')` | Success toast |
| 11 | DB check: `SELECT * FROM tpt_route_scheduler_jnt WHERE id = X` | Record GONE (not even in trash) |

#### TC-P10: Toggle Status

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.route-scheduler.update` permission | Authenticated |
| 2 | Navigate to scheduler tab | Record visible with status toggle |
| 3 | Note current is_active value | e.g., 1 (active) |
| 4 | Click status toggle button | POST `/route-scheduler/{scheduler}/toggle-status` with route-model-binding |
| 5 | **Verify**: `Gate::authorize('tenant.route-scheduler.update')` at line 310 | Authorized (gates on `update`, NOT `status`) |
| 6 | **Verify**: Route-model-binding resolves `TptRouteSchedulerJnt $scheduler` at line 308 | Auto-resolved, no findOrFail needed |
| 7 | **Verify**: Line 311: `$scheduler->is_active = !$scheduler->is_active` | is_active flipped (1 → 0) |
| 8 | **Verify**: Line 312: `$scheduler->save()` — FIRST SAVE | DB write #1 |
| 9 | **Verify**: Line 314: `activityLog($scheduler, 'Toggled', ['message' => 'Status updated.'])` | Activity log entry |
| 10 | **Verify**: Line 318: `if ($scheduler->save())` — SECOND SAVE | DB write #2 (redundant) |
| 11 | **Verify**: JSON response `{success: true, is_active: 0, message: '...'}` | 200 OK |
| 12 | DB check: `SELECT is_active FROM tpt_route_scheduler_jnt WHERE id = X` | Value toggled (was 1, now 0) |
| 13 | **Note**: Line 312+318 = double save — CR gap documented in TC-CR23 |

#### TC-P11: createtrip — Load Selection Page

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.driver-route-vehicle.update` permission | Authenticated |
| 2 | Navigate to scheduler tab | Scheduler list |
| 3 | Check 2+ scheduler entries via checkboxes | `selected_ids` = "1,2,3" (comma-separated) |
| 4 | Click "Create Trip" button | Confirmation SweetAlert |
| 5 | Confirm "Yes, Create" | Hidden form POST to `/driver-route-vehicle/create-trip` |
| 6 | **Verify**: `Gate::authorize('tenant.driver-route-vehicle.update')` at line 90 | Authorized |
| 7 | **Verify**: Line 92: `$ids = explode(',', $request->selected_ids)` | ["1", "2", "3"] |
| 8 | **Verify**: Line 94-99: `TptRouteSchedulerJnt::whereIn('id', $ids)->get()` + supporting data loaded | Selected records + routes/shifts/vehicles/driverHelpers |
| 9 | **Verify**: View `transport::route-scheduler.createtrip` loads with all data | Create trip page renders |
| 10 | **Verify**: Trip creation form shows: trip_date (default=today), selected schedules summary, route/shift/vehicle/driver/helper pre-populated | Form populated |

#### TC-P12: storeTrip — Generate Trips From Multiple Schedulers

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user with `tenant.driver-route-vehicle.update` | Authenticated |
| 2 | Navigate to scheduler tab | Scheduler list visible |
| 3 | Select 3 scheduler entries (checkboxes) | Items selected |
| 4 | Click "Create Trip" | SweetAlert confirmation |
| 5 | Confirm | Hidden form POST to `/driver-route-vehicle/store-trip` |
| 6 | **Verify**: `Gate::authorize('tenant.driver-route-vehicle.update')` at line 106 | Authorized |
| 7 | **Verify**: Line 109-112 request validation: `selected_ids` required|string, `trip_date` required|date | Validation passes |
| 8 | **Verify**: Line 115: `explode(',', $request->selected_ids)` | Array of IDs |
| 9 | **Verify**: Line 118-120: `TptRouteSchedulerJnt::whereIn('id', $selectedIds)->with(['route','shift','vehicle','driver','helper'])->get()` | 3 schedules loaded with relations |
| 10 | **Verify**: Line 122-125: `$schedules->isEmpty()` = false | Proceeds to loop |
| 11 | **For each schedule**: `TptTrip::where('trip_date', $schedule->scheduled_date)->where('route_scheduler_id', $schedule->id)->exists()` at line 133-135 | Duplicate check per schedule |
| 12 | **Verify**: Line 144-157: `TptTrip::create([...])` called for each non-duplicate | 3 TptTrip records created |
| 13 | **Verify**: Trip fields sourced from scheduler: trip_date=scheduled_date, route_scheduler_id, route_id, shift_id, vehicle_id, driver_id, helper_id | Correct mapping |
| 14 | **Verify**: `start_time`/`end_time` from `$schedule->shift->start_time`/`->end_time` at lines 152-153 | Time pulled from shift relation |
| 15 | **Verify**: `status = 'Active'` at line 154 | Default trip status |
| 16 | **Verify**: `remarks = 'Trip created from schedule for YYYY-MM-DD'` at line 155 | Descriptive remark |
| 17 | **Verify**: `created_by = auth()->id()` at line 156 | Created by recorded |
| 18 | **Verify**: Line 166: Success message `"3 trip(s) created successfully!"` | Message built |
| 19 | **Verify**: `redirect()->back()->with('success', $message)` at line 175-176 | Redirect back with success |
| 20 | **Verify**: NO `activityLog()` call anywhere in storeTrip() at lines 103-177 | **GAP** — no audit trail for trip generation (BC-BIZ-16) |
| 21 | DB check: `SELECT * FROM tpt_trip WHERE route_scheduler_id IN (1,2,3)` | 3 trip records exist |
| 22 | DB check: Each trip's `trip_date`, `route_id`, `shift_id`, `vehicle_id`, `driver_id`, `helper_id` match source scheduler | Data integrity verified |

#### TC-P13: storeTrip — Skip Duplicate Trips

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Execute TC-P12 (trips already created for schedulers 1,2,3) | 3 trips exist |
| 2 | Select same 3 scheduler entries | Same IDs |
| 3 | Click "Create Trip" again | POST same request |
| 4 | **Verify**: Lines 133-135 duplicate check: each schedule's trip_date+route_scheduler_id already exists | `$exists = true` for all 3 |
| 5 | **Verify**: Line 137-139: `$skippedTrips++` = 3 | All skipped |
| 6 | **Verify**: `$createdTrips` is empty (count=0) | No new trips |
| 7 | **Verify**: Line 167-169: `$message = '0 trip(s) created successfully! 3 trip(s) were skipped because they already exist.'` | Correct skip message |
| 8 | **Verify**: No duplicate trip rows created | DB has only original 3 trips |

#### TC-P14: Filter by Schedule Date

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login | Authenticated |
| 2 | Navigate to scheduler tab | Scheduler list |
| 3 | Select a specific date in the `schedule_date` filter | Date = "2026-07-25" |
| 4 | Submit filter | GET with `schedule_date=2026-07-25` |
| 5 | **Verify**: `TripMgmtController:SchedulerQuery()` at line 189-191: `$query->where('scheduled_date', $request->schedule_date)` | Filter applied |
| 6 | **Verify**: Only records with matching `scheduled_date` displayed | Filtered results |

#### TC-P15: Filter by Shift/Route/Vehicle/Driver

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login | Authenticated |
| 2 | Navigate to scheduler tab | Scheduler list |
| 3 | Select Shift = Morning from dropdown | `shift_id` = S1 |
| 4 | Select Route = "Route A" from dropdown | `route_id` = R1 |
| 5 | Select Vehicle = "Bus-01" from dropdown | `vehicle_id` = V1 |
| 6 | Select Driver = "John" from dropdown | `driver_id` = D1 |
| 7 | Submit filters | GET with all params |
| 8 | **Verify**: Lines 193-198: loop over `['shift_id','route_id','vehicle_id','driver_id','helper_id']`, each `where($field, $request->$field)` | 4 conditions applied with AND |
| 9 | **Verify**: Only matching records displayed | Filtered grid |

#### TC-P16: Empty State — No Records

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure no scheduler records exist OR filter to impossible combination | Empty dataset |
| 2 | Navigate to scheduler tab | Grid displayed |
| 3 | **Verify**: "No Data Found" message shown | Empty state rendered |
| 4 | **Verify**: Filter bar and Add button still visible | UI controls present |

#### TC-P17: Empty State — No Trashed Records

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure no trashed records exist | Trash is empty |
| 2 | Navigate to `/route-scheduler/trash/view` | Trash page |
| 3 | **Verify**: `onlyTrashed()->paginate(20)` returns empty collection | No records |
| 4 | **Verify**: "No Data Found" message shown in trash | Empty state rendered |

---

### 7.2 Negative Test Cases

#### TC-N01: Required — Missing scheduled_date

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to create form | Form loads |
| 2 | Fill all fields EXCEPT scheduled_date | Leave date empty |
| 3 | Submit POST `/route-scheduler` | `RouteSchedulerRequest@rules()` |
| 4 | **Verify**: Rule `'scheduled_date' => 'required|date'` | `required` fails |
| 5 | **Verify**: Error message "The scheduled date field is required." | Validation error returned |
| 6 | **Verify**: No record created in DB | `tpt_route_scheduler_jnt` unchanged |

#### TC-N02: Required — Missing shift_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create form | Loads |
| 2 | Leave shift_id unselected | Empty |
| 3 | Fill all other required fields | Others valid |
| 4 | Submit | POST |
| 5 | **Verify**: Rule `'shift_id' => 'required'` | "The shift id field is required." |
| 6 | DB unchanged | No insert |

#### TC-N03: Required — Missing route_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create form | Loads |
| 2 | Leave route_id unselected | Empty |
| 3 | Submit | POST |
| 4 | **Verify**: Rule `'route_id' => 'required'` | "The route id field is required." |

#### TC-N04: Required — Missing vehicle_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create form | Loads |
| 2 | Leave vehicle_id unselected | Empty |
| 3 | Submit | POST |
| 4 | **Verify**: Rule `'vehicle_id' => 'required'` | "The vehicle id field is required." |

#### TC-N05: Required — Missing driver_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create form | Loads |
| 2 | Leave driver_id unselected | Empty |
| 3 | Submit | POST |
| 4 | **Verify**: Rule `'driver_id' => 'required'` | "The driver id field is required." |

#### TC-N06: Duplicate — Controller-Level Check

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create scheduler (shift=S1, route=R1, vehicle=V1, driver=D1, date=2026-07-25) | Record exists |
| 2 | Navigate to create form again | Form loads |
| 3 | Enter identical values: shift=S1, route=R1, vehicle=V1, driver=D1, date=2026-07-25 | Same combo |
| 4 | Submit | POST |
| 5 | **Verify**: Controller lines 58-63: `where('shift_id',S1)->where('route_id',R1)->where('vehicle_id',V1)->where('driver_id',D1)->where('scheduled_date','2026-07-25')->exists()` | Returns true |
| 6 | **Verify**: `back()->withErrors(['scheduled_date' => 'This schedule already exists for the selected date.'])` at line 66-68 | Duplicate error returned |
| 7 | **Verify**: No duplicate record created | DB unchanged |
| 8 | **Note**: This check differs from DB unique constraint — controller checks vehicle+driver, DB unique key checks scheduled_date+shift+route+pickup_drop | Potential false positive: same date/shift/route but different vehicle would PASS controller but FAIL DB |

#### TC-N07: Duplicate — DB Unique Constraint

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create scheduler with date=D1, shift=S1, route=R1, pickup_drop="Pickup" | Record exists |
| 2 | Bypass controller: directly insert via DB with same date=D1, shift=S1, route=R1, pickup_drop="Pickup" but different vehicle | INSERT query |
| 3 | **Verify**: `uq_route_scheduler_schedDate_shift_route` unique key violation | `SQLSTATE[23000]: Integrity constraint violation: Duplicate entry` |
| 4 | **Note**: Controller's duplicate check would have PASSED this (different vehicle) but DB unique key catches it | Gap between controller validation and DB constraint |

#### TC-N08: View With Invalid ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | GET `/route-scheduler/99999` | Non-existent ID |
| 2 | **Verify**: `Gate::authorize('tenant.route-scheduler.view')` at line 183 | Authorized (gate check passes independently of data) |
| 3 | **Verify**: `TptRouteSchedulerJnt::with(...)->findOrFail(99999)` at line 184-185 | `findOrFail` throws `ModelNotFoundException` |
| 4 | **Verify**: Laravel renders 404 page | "No query results" |

#### TC-N09: Edit With Invalid ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | GET `/route-scheduler/99999/edit` | Invalid ID |
| 2 | **Verify**: `Gate::authorize('tenant.route-scheduler.update')` passes | Authorized |
| 3 | **Verify**: `TptRouteSchedulerJnt::findOrFail(99999)` at line 197 | ModelNotFoundException → 404 |

#### TC-N10: Update With Invalid ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | PUT `/route-scheduler/99999` with valid body | Invalid ID |
| 2 | **Verify**: `Gate::authorize('tenant.route-scheduler.update')` passes | Authorized |
| 3 | **Verify**: `TptRouteSchedulerJnt::findOrFail(99999)` at line 226 | ModelNotFoundException → 404 |

#### TC-N11: Delete With Invalid ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | DELETE `/route-scheduler/99999` | Invalid ID |
| 2 | **Verify**: `Gate::authorize('tenant.route-scheduler.delete')` passes | Authorized |
| 3 | **Verify**: `TptRouteSchedulerJnt::findOrFail(99999)` at line 251 | 404 |

#### TC-N12: Restore Non-Deleted Record

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create active scheduler (not deleted) | `deleted_at = NULL` |
| 2 | GET `/route-scheduler/{id}/restore` | Restore attempt |
| 3 | **Verify**: `Gate::authorize('tenant.route-scheduler.restore')` passes | Authorized |
| 4 | **Verify**: `TptRouteSchedulerJnt::onlyTrashed()->findOrFail($id)` at line 276 | `onlyTrashed()` filters out active records (deleted_at IS NULL) |
| 5 | Active record has deleted_at=NULL → not found | ModelNotFoundException → 404 |

#### TC-N13: Force Delete Non-Trashed Record

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create active scheduler (deleted_at = NULL) | Not trashed |
| 2 | DELETE `/route-scheduler/{id}/force-delete` | Force delete attempt |
| 3 | **Verify**: `Gate::authorize('tenant.route-scheduler.forceDelete')` passes | Authorized |
| 4 | **Verify**: `TptRouteSchedulerJnt::onlyTrashed()->findOrFail($id)` at line 293 | `onlyTrashed()` → no result → 404 |
| 5 | **Impact**: Cannot force-delete an active record — must soft-delete first | Two-step process required |

#### TC-N14: storeTrip — No Valid Schedules Selected

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST `/driver-route-vehicle/store-trip` with `selected_ids='99999,99998'` and valid `trip_date` | Invalid IDs |
| 2 | **Verify**: `$schedules = TptRouteSchedulerJnt::whereIn('id', [99999,99998])->get()` | Empty collection |
| 3 | **Verify**: Line 122-125: `if ($schedules->isEmpty())` | true → enters error block |
| 4 | **Verify**: `redirect()->back()->with('error', 'No valid schedules selected!')` at lines 123-125 | Redirect back with error |

#### TC-N15: storeTrip — Empty selected_ids

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST `/driver-route-vehicle/store-trip` WITHOUT `selected_ids` | Missing field |
| 2 | **Verify**: Line 110: `'selected_ids' => 'required|string'` | `required` fails |
| 3 | **Verify**: Validation error "The selected ids field is required." | 422 response |

#### TC-N16: storeTrip — Missing trip_date

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST `/driver-route-vehicle/store-trip` with `selected_ids='1,2'` but NO `trip_date` | Missing date |
| 2 | **Verify**: Line 111: `'trip_date' => 'required|date'` | `required` fails |
| 3 | **Verify**: Validation error "The trip date field is required." | 422 response |

#### TC-N17: Permission 403 — viewAny (index)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user WITHOUT `tenant.route-scheduler.viewAny` | No permission |
| 2 | Navigate to `/transport/trip-management?tab=scheduler` | `TripMgmtController@index()` at line 38 has `Gate::authorize('tenant.transport.viewAny')` |
| 3 | **Note**: Actual 403 depends on `tenant.transport.viewAny`, not `tenant.route-scheduler.viewAny` | Transport-level gate |
| 4 | Navigate directly to `/route-scheduler` (resource index) | `RouteSchedulerController@index()` line 29: `Gate::authorize('tenant.route-scheduler.viewAny')` → 403 |

#### TC-N18: Permission 403 — view (show)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login without `tenant.route-scheduler.view` | No permission |
| 2 | GET `/route-scheduler/{id}` | `RouteSchedulerController@show()` at line 183: `Gate::authorize('tenant.route-scheduler.view')` → 403 |

#### TC-N19: Permission 403 — create (store)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login without `tenant.route-scheduler.create` | No permission |
| 2 | GET `/route-scheduler/create` | `RouteSchedulerController@create()` at line 42: `Gate::authorize('tenant.route-scheduler.create')` → 403 |
| 3 | POST `/route-scheduler` | `RouteSchedulerRequest@authorize()` line 16: `Gate::allows('tenant.route-scheduler.create')` → 403 |

#### TC-N20: Permission 403 — update (edit + update + toggleStatus)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login without `tenant.route-scheduler.update` | No permission |
| 2 | GET `/route-scheduler/{id}/edit` | `RouteSchedulerController@edit()` line 195: `Gate::authorize('tenant.route-scheduler.update')` → 403 |
| 3 | PUT `/route-scheduler/{id}` | `RouteSchedulerController@update()` line 210: Gate → 403 |
| 4 | POST `/route-scheduler/{id}/toggle-status` | `RouteSchedulerController@toggleStatus()` line 310: Gate → 403 |

#### TC-N21: Permission 403 — delete (destroy)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login without `tenant.route-scheduler.delete` | No permission |
| 2 | DELETE `/route-scheduler/{id}` | `RouteSchedulerController@destroy()` line 250 → 403 |

#### TC-N22: Permission 403 — restore (trashed + restore)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login without `tenant.route-scheduler.restore` | No permission |
| 2 | GET `/route-scheduler/trash/view` | `RouteSchedulerController@trashed()` line 265 → 403 |
| 3 | GET `/route-scheduler/{id}/restore` | `RouteSchedulerController@restore()` line 275 → 403 |

#### TC-N23: Permission 403 — forceDelete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login without `tenant.route-scheduler.forceDelete` | No permission |
| 2 | DELETE `/route-scheduler/{id}/force-delete` | `RouteSchedulerController@forceDelete()` line 292 → 403 |

#### TC-N24: Permission 403 — driver-route-vehicle.update

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login without `tenant.driver-route-vehicle.update` | No permission |
| 2 | POST `/driver-route-vehicle/create-trip` | `RouteSchedulerController@createtrip()` line 90 → 403 |
| 3 | POST `/driver-route-vehicle/store-trip` | `RouteSchedulerController@storeTrip()` line 106 → 403 |

#### TC-N25: Guest Access

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Logout (no authenticated user) | Guest session |
| 2 | Access ALL URLs: `/transport/trip-management?tab=scheduler`, `/route-scheduler/create`, `/route-scheduler/{id}`, `/route-scheduler/{id}/edit`, `/route-scheduler/{id} (PUT)`, `/route-scheduler/{id} (DELETE)`, `/route-scheduler/trash/view`, `/route-scheduler/{id}/restore`, `/route-scheduler/{id}/force-delete`, `/route-scheduler/{id}/toggle-status`, `/driver-route-vehicle/create-trip`, `/driver-route-vehicle/store-trip` | ALL redirect to `/login` |

#### TC-N26: XSS Injection

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create scheduler with `helper_id` set to a record where name = `<script>alert('XSS')</script>` | Malicious data |
| 2 | View scheduler show page | Blade `{{ }}` escapes output — script tag displayed as literal text |
| 3 | View scheduler index tab | Escaped output — no script execution |
| 4 | **Verify**: No `{!! !!}` unescaped usage for user input in any scheduler blade | All fields use `{{ }}` |

---

### 7.3 Dependency Test Cases

#### TC-D01: Trip Generation — Compliance Skipped

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create scheduler with a driver who has EXPIRED license | Driver's compliance docs expired |
| 2 | Execute `storeTrip()` for this scheduler | Controller line 142: `try { TptTrip::create([...]) }` |
| 3 | TptTrip model boot() or creating event throws DomainException for expired license | `catch (\Exception $e)` at line 160 |
| 4 | **Verify**: `$complianceSkipped++` at line 161 | Counter incremented |
| 5 | **Verify**: `Log::warning("Trip generation failed for scheduler schedule {$schedule->id} due to: " . $e->getMessage())` at line 162 | Warning logged |
| 6 | **Verify**: Message includes "1 trip(s) were skipped due to compliance/licence validation failure." at line 170-172 | User informed |
| 7 | DB check: No TptTrip created for this scheduler | Skipped |

#### TC-D02: Route Deletion — CASCADE to Scheduler

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create scheduler with route_id=R1 | FK reference |
| 2 | Delete Route R1 from `tpt_route` | `DELETE FROM tpt_route WHERE id = R1` |
| 3 | **Verify**: DDL FK `fk_route_scheduler_routeId` has `ON DELETE CASCADE` | Cascade on route deletion |
| 4 | DB check: `SELECT * FROM tpt_route_scheduler_jnt WHERE route_id = R1` | All scheduler records for R1 auto-deleted |
| 5 | **Note**: This cannot be tested via UI (routes have own controller) | DB-level integrity |

#### TC-D03: Vehicle/Driver SET NULL on Deletion

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create scheduler with vehicle_id=V1, driver_id=D1, helper_id=H1 | All FKs set |
| 2 | Delete Vehicle V1 from `tpt_vehicle` | `ON DELETE SET NULL` |
| 3 | Delete Driver/Helper D1 from `tpt_personnel` | `ON DELETE SET NULL` |
| 4 | DB check: `SELECT vehicle_id, driver_id, helper_id FROM tpt_route_scheduler_jnt WHERE id = X` | vehicle_id=NULL, driver_id=NULL, helper_id=NULL |
| 5 | **Note**: Scheduler record still exists — only FK references nullified | SET NULL preserves record |

#### TC-D04: Shift RESTRICT on Scheduler Delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create scheduler with shift_id=S1 | FK reference |
| 2 | Attempt to delete Shift S1 from `tpt_shift` | `DELETE FROM tpt_shift WHERE id = S1` |
| 3 | **Verify**: DDL FK `fk_route_scheduler_shiftId` has `ON DELETE RESTRICT` | RESTRICT prevents deletion |
| 4 | **Verify**: DB throws FK constraint violation | Cannot delete shift because scheduler references it |
| 5 | **Workaround**: Must delete scheduler first, then delete shift | Two-step process |

#### TC-D05: Trip Exists for Scheduler — Soft Delete Allowed

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create scheduler | id=X |
| 2 | Generate trip from scheduler (storeTrip) | TptTrip created with route_scheduler_id=X |
| 3 | Attempt soft-delete of scheduler X | DELETE `/route-scheduler/X` |
| 4 | **Verify**: No FK constraint prevents delete (trip FK does not have restrict) | DDL allows — no protected_foreign_keys or preventDelete hook |
| 5 | **Verify**: `$record->delete()` at line 252 succeeds | `deleted_at` set |

#### TC-D06: DriverRouteVehicle Update Rebuilds Scheduler

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | DriverRouteVehicleJnt record exists with driver_id=D1, route_id=R1, vehicle_id=V1, shift_id=S1 | Roster entry |
| 2 | Updating DriverRouteVehicle triggers force-delete of old scheduler + upsert new | Logic in DriverRouteVehicleController |
| 3 | DB check: Old scheduler for D1+R1+V1+S1+old_date is force-deleted | Permanently removed |
| 4 | DB check: New scheduler created with updated fields | New record exists |
| 5 | **Note**: This is triggered by DriverRouteVehicleController event/listener, not RouteSchedulerController | Cross-controller dependency |

---

### 7.4 Code Review Test Cases

#### TC-CR01: Controller — Gate::authorize() Before Every Method

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `RouteSchedulerController.php` | Full file inspection |
| 2 | `index()` line 29: `Gate::authorize('tenant.route-scheduler.viewAny')` | PRESENT |
| 3 | `create()` line 42: `Gate::authorize('tenant.route-scheduler.create')` | PRESENT |
| 4 | `store()` line 57: `Gate::authorize('tenant.route-scheduler.create')` | PRESENT (also in FormRequest) |
| 5 | `show()` line 183: `Gate::authorize('tenant.route-scheduler.view')` | PRESENT |
| 6 | `edit()` line 195: `Gate::authorize('tenant.route-scheduler.update')` | PRESENT |
| 7 | `update()` line 210: `Gate::authorize('tenant.route-scheduler.update')` | PRESENT (also in FormRequest) |
| 8 | `destroy()` line 250: `Gate::authorize('tenant.route-scheduler.delete')` | PRESENT |
| 9 | `trashed()` line 265: `Gate::authorize('tenant.route-scheduler.restore')` | PRESENT |
| 10 | `restore()` line 275: `Gate::authorize('tenant.route-scheduler.restore')` | PRESENT |
| 11 | `forceDelete()` line 292: `Gate::authorize('tenant.route-scheduler.forceDelete')` | PRESENT |
| 12 | `toggleStatus()` line 310: `Gate::authorize('tenant.route-scheduler.update')` | PRESENT (gates on `update`, not `status`) |
| 13 | `createtrip()` line 90: `Gate::authorize('tenant.driver-route-vehicle.update')` | PRESENT |
| 14 | `storeTrip()` line 106: `Gate::authorize('tenant.driver-route-vehicle.update')` | PRESENT |

#### TC-CR02: Controller — activityLog for All CRUD

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `RouteSchedulerController.php` | Search for `activityLog` |
| 2 | `store()` line 82: `activityLog($data, 'Created', ...)` | PRESENT |
| 3 | `update()` line 239: `activityLog($record, 'Updated', ...)` | PRESENT |
| 4 | `destroy()` line 254: `activityLog($record, 'Deleted', ...)` | PRESENT |
| 5 | `restore()` line 280: `activityLog($record, 'Restored', ...)` | PRESENT |
| 6 | `forceDelete()` line 295: `activityLog($record, 'ForceDelete', ...)` | PRESENT |
| 7 | `toggleStatus()` line 314: `activityLog($scheduler, 'Toggled', ...)` | PRESENT |
| 8 | `storeTrip()` lines 103-177: `activityLog()` | **MISSING** — no audit trail for batch trip creation |

#### TC-CR03: Controller — Duplicate Check on Store

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `store()` lines 58-63 | `where('shift_id')->where('route_id')->where('vehicle_id')->where('driver_id')->where('scheduled_date')->exists()` |
| 2 | **Verify**: Uses 5-field combination (shift+route+vehicle+driver+date) | Not matching DB unique key (which uses scheduled_date+shift+route+pickup_drop) |
| 3 | **Note**: `pickup_drop` NOT included in controller duplicate check | Gap: same date/shift/route but different pickup_drop passes controller but fails DB |

#### TC-CR04: Controller — Duplicate Check on Update

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `update()` lines 212-218 | Same 5-field check as store |
| 2 | **Verify**: `->where('id', '!=', $id)` added at line 212 | Excludes current record from check |
| 3 | **Verify**: Same 5 fields: shift_id, route_id, vehicle_id, driver_id, scheduled_date | Consistent with store |

#### TC-CR05: Controller — onlyTrashed for Restore and ForceDelete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `restore()` line 276: `TptRouteSchedulerJnt::onlyTrashed()->findOrFail($id)` | ONLY finds soft-deleted records — correct for restore |
| 2 | `forceDelete()` line 293: `TptRouteSchedulerJnt::onlyTrashed()->findOrFail($id)` | ONLY finds soft-deleted — correct for forceDelete (must trash first) |

#### TC-CR06: pickup_drop Present in Create

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `store()` line 79: `'pickup_drop' => $request->pickup_drop` | Field IS included in create array |
| 2 | FormRequest allows `pickup_drop` as `nullable|string` at line 33 | NOT validated against allowed ENUM values |

#### TC-CR07: Request authorize() matches Controller Gates

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `RouteSchedulerRequest@authorize()` lines 13-19 | POST → `create`, PUT/PATCH → `update` |
| 2 | Controller `store()` line 57: `Gate::authorize('tenant.route-scheduler.create')` | Matches POST |
| 3 | Controller `update()` line 210: `Gate::authorize('tenant.route-scheduler.update')` | Matches PUT/PATCH |
| 4 | **Verify**: Double gating (Request + Controller) | Consistent |

#### TC-CR08: Request — Missing `exists:` Validations

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `RouteSchedulerRequest@rules()` lines 26-35 | Only `required`, `nullable`, `date`, `boolean` rules |
| 2 | `shift_id => 'required'` — NO `exists:tpt_shift,id` | Missing FK validation |
| 3 | `route_id => 'required'` — NO `exists:tpt_route,id` | Missing FK validation |
| 4 | `vehicle_id => 'required'` — NO `exists:tpt_vehicle,id` | Missing FK validation |
| 5 | `driver_id => 'required'` — NO `exists:tpt_personnel,id` | Missing FK validation |
| 6 | `helper_id => 'nullable'` — NO `exists:tpt_personnel,id` | Missing FK validation |
| 7 | **Impact**: POST with invalid FK values (e.g., shift_id=99999) passes validation → DB FK constraint throws 500 error | Potential 500 error for invalid FK references |

#### TC-CR09: Model — Table Name and SoftDeletes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `TptRouteSchedulerJnt.php` line 15 | `protected $table = 'tpt_route_scheduler_jnt'` — correct |
| 2 | Line 13: `use SoftDeletes` | SoftDeletes trait present |

#### TC-CR10: Model — Fillable Fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `TptRouteSchedulerJnt.php` lines 17-26 | `$fillable = ['shift_id','route_id','vehicle_id','driver_id','helper_id','scheduled_date','is_active','pickup_drop']` |
| 2 | Count: 8 fillable fields | Matches controller create/update arrays |

#### TC-CR11: Model — Relationships

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open model lines 28-56 | 6 relationships: shift(), route(), vehicle(), driver(), helper(), trips() |
| 2 | Line 57-60: `hasTrip()` method | Convenience method: `$this->trips()->exists()` — separate query per call |

#### TC-CR12: Routes — Resource + Additional Routes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `web.php` or route registration | `Route::resource('route-scheduler', RouteSchedulerController::class)` |
| 2 | Additional routes: `trashed`, `restore`, `forceDelete`, `toggle-status`, `createtrip`, `storeTrip` | All registered |

#### TC-CR13: DDL — Unique Constraints

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open migration for `tpt_route_scheduler_jnt` | 4 unique keys defined |
| 2 | `uq_route_scheduler_schedDate_shift_route` (scheduled_date, shift_id, route_id, pickup_drop) | Prevents same date/shift/route/pickup_drop |
| 3 | `uq_route_scheduler_vehicle_schedDate_shift` (vehicle_id, scheduled_date, shift_id, pickup_drop) | Vehicle uniqueness per date/shift |
| 4 | `uq_route_scheduler_driver_schedDate_shift` (driver_id, scheduled_date, shift_id, pickup_drop) | Driver uniqueness per date/shift |
| 5 | `uq_route_scheduler_helper_schedDate_shift` (helper_id, scheduled_date, shift_id, pickup_drop) | Helper uniqueness per date/shift |

#### TC-CR14: DDL — FK Constraints

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open migration FK definitions | shift → RESTRICT, route → CASCADE, vehicle → SET NULL, driver → SET NULL, helper → SET NULL |
| 2 | **Verify**: Confirmed in DDL | Matches BC-DB section |

#### TC-CR15: Gap — Request Doesn't Validate pickup_drop Against ENUM

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `RouteSchedulerRequest` line 33: `pickup_drop => 'nullable|string'` | No `Rule::in(['Pickup','Drop'])` |
| 2 | POST with `pickup_drop = 'InvalidValue'` | Passes validation (accepts any string) |
| 3 | DB ENUM column rejects invalid value | `SQLSTATE[22007]: Invalid ENUM value` → 500 error |
| 4 | **Impact**: Invalid ENUM values cause 500 error instead of proper validation | Gap in request validation |

#### TC-CR16: Gap — Request Doesn't Validate FK Existence (duplicate of CR08)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | See TC-CR08 steps | All FK fields lack `exists:` rules |

#### TC-CR17: TripMgmtController — SchedulerQuery Filters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `TripMgmtController:SchedulerQuery()` lines 174-202 | Filter loop at lines 194-198 |
| 2 | Filters applied: `status` (maps to `is_active`), `schedule_date`, `shift_id`, `route_id`, `vehicle_id`, `driver_id`, `helper_id` | 7 filter parameters |
| 3 | **Verify**: Filters only apply when `$tab === 'scheduler'` at line 183 | Tab-guarded |

#### TC-CR18: Gap — View Gates on `edit`, Controller Gates on `update`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect view (scheduler index table) | Action column visibility gated on `tenant.route-scheduler.edit` |
| 2 | Inspect controller `edit()` line 195 | `Gate::authorize('tenant.route-scheduler.update')` |
| 3 | User with ONLY `edit` permission (no `update`): sees edit button → clicks → **403** | Permission mismatch |
| 4 | **Impact**: `tenant.route-scheduler.edit` permission is useless — controller only checks `update` | Edit button visible but non-functional for users with only `edit` |

#### TC-CR19: Gap — View Gates on `status`, Controller Gates on `update`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect view: status toggle column visibility gated on `tenant.route-scheduler.status` | Status toggle visible |
| 2 | Inspect controller `toggleStatus()` line 310: `Gate::authorize('tenant.route-scheduler.update')` | Gates on `update`, not `status` |
| 3 | User with ONLY `status` permission (no `update`): sees toggle → clicks → **403** | Permission mismatch |
| 4 | **Impact**: `tenant.route-scheduler.status` permission is useless for the action | Status toggle broken for users with only `status` permission |

#### TC-CR20: Gap — Edit View Offers `Both` for pickup_drop But DDL ENUM Only Allows Pickup/Drop

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `edit.blade.php` lines 173-176 | `<option value="Both">Both</option>` present |
| 2 | DDL: `pickup_drop` is ENUM('Pickup','Drop') | 'Both' is NOT a valid ENUM value |
| 3 | Submit edit with pickup_drop='Both' | Passes Request validation (`nullable|string`, not restricted to ENUM) |
| 4 | DB UPDATE: ENUM column rejects 'Both' | `SQLSTATE[22007]: Invalid ENUM value` → 500 error |
| 5 | **Impact**: Edit form offers an option that always causes DB error | **Bug** — submit button is a guaranteed 500 |

#### TC-CR21: Gap — RouteSchedulerController@index() Passes `$data` But Tab View Expects `$sheduleData`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `RouteSchedulerController@index()` line 34 | `return view('transport::route-scheduler.index', compact('data'))` |
| 2 | Open scheduler index blade | View uses `$sheduleData` (from TripMgmtController) |
| 3 | Navigate directly to `/route-scheduler` (resource index, NOT via tab) | `compact('data')` → `$data` set, `$sheduleData` undefined |
| 4 | **Verify**: Blade throws `Undefined variable $sheduleData` | **500 error** — direct route-scheduler index is broken |
| 5 | **Workaround**: Always access scheduler via `/transport/trip-management?tab=scheduler` | Tab route works correctly |

#### TC-CR22: Gap — storeTrip() Does NOT Call activityLog()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Search `storeTrip()` lines 103-177 for `activityLog` | **NOT FOUND** |
| 2 | Execute storeTrip with 3 schedulers → 3 trips created | Trips created in DB |
| 3 | Check `activity_log` table for any entries related to trip generation | No entries found |
| 4 | **Impact**: No audit trail for batch trip creation from scheduler | **Audit gap** |

#### TC-CR23: Gap — toggleStatus() Calls save() Twice

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `toggleStatus()` lines 308-330 | Two save() calls |
| 2 | Line 312: `$scheduler->save()` | FIRST save — writes to DB |
| 3 | Line 318: `if ($scheduler->save())` | SECOND save — writes again |
| 4 | **Verify**: Both saves write the SAME data (is_active already toggled before first save) | First save already persisted the change; second save is redundant |
| 5 | **Impact**: Unnecessary DB write — doubles query load for toggle operations | Performance gap |

#### TC-CR24: Gap — SchedulerQuery() Omits `helper` From Eager Load

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `TripMgmtController:SchedulerQuery()` line 177 | `->with(['route','shift','vehicle','driver'])` — `helper` NOT included |
| 2 | Index blade accesses `$item->helper->name` | Lazy load: separate DB query per row for helper |
| 3 | With 10 rows on page: 1 (base) + 4 (eager) + 10 (helper lazy) = 15 queries | N+1 query pattern |
| 4 | **Compare**: `RouteSchedulerController@index()` line 30 includes `'helper'` in eager load | Direct index does it right, tab query does not |
| 5 | **Impact**: Performance degradation on scheduler tab with many rows | Unnecessary DB queries |

#### TC-CR25: Gap — hasTrip() Ignores Pre-loaded trips_count

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `SchedulerQuery()` line 178: `->withCount('trips')` | `trips_count` attribute preloaded |
| 2 | Model `hasTrip()` line 58: `return $this->trips()->exists()` | Runs NEW query: `SELECT EXISTS(SELECT 1 FROM tpt_trip WHERE route_scheduler_id = X)` |
| 3 | View could use `$item->trips_count > 0` instead of `$item->hasTrip()` | trips_count is already available, no extra query needed |
| 4 | **Impact**: If view uses `hasTrip()`, each row generates an extra DB query | Avoidable N+1 |

#### TC-CR26: Gap — Policy Filename Uses `transport.` Prefix Instead of `tenant.`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `RouteSchedulerPolicy.php` lines 15, 23, 39, 47, 55, 63, 71 | All gates use `$user->can('transport.route-scheduler.*')` — `transport.` prefix |
| 2 | Open `TransportRouteSchedulerPolicy.php` lines 15, 23, 31, 39, 47, 55, 63, 71 | All gates use `$user->can('tenant.route-scheduler.*')` — `tenant.` prefix |
| 3 | Open `RouteSchedulerController.php` all Gate::authorize() calls | All use `tenant.route-scheduler.*` (e.g., line 29: `tenant.route-scheduler.viewAny`) |
| 4 | **Verify**: `RouteSchedulerPolicy.php` uses `transport.` but controller uses `tenant.` | **MISMATCH** — `RouteSchedulerPolicy` would never authorize because controller checks `tenant.` |
| 5 | **Verify**: `TransportRouteSchedulerPolicy.php` correctly uses `tenant.` prefix | This is the actually active policy |
| 6 | **Note**: Two policy files exist — `RouteSchedulerPolicy` has wrong prefix (dead code or bug) | **GAP** — potential confusion |

#### TC-CR27: Gap — Policy `status()` Parameter Type Hint Uses `Route` Instead of `TptRouteSchedulerJnt`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `RouteSchedulerPolicy.php` line 29 | `public function status(User $user, Route $route)` |
| 2 | `Route` is `Modules\Transport\Models\Route` — NOT imported at top of file | Missing use statement |
| 3 | **Verify**: Parameter should be `TptRouteSchedulerJnt` to match model | Wrong type hint |
| 4 | Open `TransportRouteSchedulerPolicy.php` line 29 | `public function status(User $user, TptRouteSchedulerJnt $routeScheduler)` — CORRECT |
| 5 | **Note**: `TransportRouteSchedulerPolicy` has correct signature | `RouteSchedulerPolicy` has the bug |

---

## 8. BC-BIZ-DEEP: Deep Business Conditions

Deep-dive analysis of all business-critical code paths in `RouteSchedulerController.php`.

| BC-DEEP ID | Condition | Code Location | Analysis |
|-----------|-----------|---------------|----------|
| BC-BIZ-DEEP-01 | `store()` duplicate check uses 5 fields (shift+route+vehicle+driver+date) but DDL unique key uses 4 fields (date+shift+route+pickup_drop) | Controller lines 58-63 vs Migration unique keys | Controller and DB have DIFFERENT duplicate prevention strategies. Controller blocks same shift+route+vehicle+driver+date regardless of pickup_drop. DB blocks same date+shift+route+pickup_drop regardless of vehicle/driver. You can create two records with same date/shift/route but different pickup_drop via controller, but DB rejects one of them — or vice versa. |
| BC-BIZ-DEEP-02 | `store()` has NO `DB::beginTransaction()` | Controller lines 55-86 | Unlike most other Transport controllers (PickupPointRoute, Route, etc.), `store()` does NOT wrap operations in a DB transaction. If activityLog fails after create, the record persists without audit trail. No atomicity guarantee. |
| BC-BIZ-DEEP-03 | `update()` has NO `DB::beginTransaction()` | Controller lines 208-243 | Same gap as store — no transaction wrapping update+activityLog. |
| BC-BIZ-DEEP-04 | `destroy()` has NO `DB::beginTransaction()` | Controller lines 248-258 | No transaction on delete+activityLog. |
| BC-BIZ-DEEP-05 | `restore()` has NO `DB::beginTransaction()` | Controller lines 273-285 | No transaction on restore+activityLog. |
| BC-BIZ-DEEP-06 | `forceDelete()` has NO `DB::beginTransaction()` | Controller lines 290-303 | No transaction on forceDelete+activityLog. |
| BC-BIZ-DEEP-07 | `toggleStatus()` has NO `DB::beginTransaction()` | Controller lines 308-330 | Double save with no transaction. |
| BC-BIZ-DEEP-08 | `storeTrip()` has NO `DB::beginTransaction()` | Controller lines 103-177 | Batch trip creation with NO atomicity. If loop fails mid-way, partial trips are created with no rollback. |
| BC-BIZ-DEEP-09 | `forceDelete()` calls `activityLog()` BEFORE `forceDelete()` | Lines 295-299 | `activityLog($record, 'ForceDelete', ...)` at line 295, then `$record->forceDelete()` at line 299. If forceDelete succeeds but activityLog had already logged, the activity_log entry references a now-deleted record. But since activityLog stores morph data, the record reference is lost after force delete. |
| BC-BIZ-DEEP-10 | `store()` passes `$data` (the created model) to activityLog, but `update()` passes `$record` | Store line 82: `activityLog($data, ...)` vs Update line 239: `activityLog($record, ...)` | Both are the model instance, but store uses the return value of `create()`, update uses the fetched record. Functionally equivalent. |
| BC-BIZ-DEEP-11 | Redirect target: Most CRUD methods redirect to `transport.trip-management.index` | Store line 84, Update line 241, Destroy line 256, Restore line 283, ForceDelete line 301 | All go back to the TAB HUB, not the resource index. Resource index at `/route-scheduler` is broken (see CR-21). |
| BC-BIZ-DEEP-12 | `store()` error path uses `back()` not `redirect()->route()` | Lines 66-68 | Duplicate error sends user back to previous page (the create form from tab). Works correctly. |
| BC-BIZ-DEEP-13 | `storeTrip()` redirects to `back()` (the create-trip form, not trip list) | Lines 175-176 | After successful trip creation, user is sent back to the create-trip page, not to the trip list or scheduler tab. They must navigate manually. |
| BC-BIZ-DEEP-14 | `request.validate()` in `storeTrip()` throws ValidationException on failure | Lines 109-112 | Uses `$request->validate()` which auto-throws — no manual error handling needed. |
| BC-BIZ-DEEP-15 | `$selectedIds = explode(',', $request->selected_ids)` — no sanitization | Line 115 | IDs are directly used in `whereIn()`. Empty string → `explode(',', '')` = `['']` → `whereIn('id', [''])` returns empty. Safe from SQL injection (parameterized), but no validation that IDs are numeric. |
| BC-BIZ-DEEP-16 | `storeTrip()` only checks trip_date + route_scheduler_id for duplicates | Lines 133-135 | Does NOT check other uniqueness constraints on TptTrip (e.g., same vehicle cannot be on two trips same date/shift). Only checks exact scheduler match. |
| BC-BIZ-DEEP-17 | `storeTrip()` uses `$schedule->scheduled_date` for trip_date in duplicate check | Line 133 | The `trip_date` in TptTrip matches scheduler's `scheduled_date`. The `$request->trip_date` is ACCEPTED by validation but NEVER USED in the actual trip creation — each trip uses `$schedule->scheduled_date` (line 145). The `$request->trip_date` is dead — validated but ignored. |
| BC-BIZ-DEEP-18 | `createtrip()` loads ALL relations for each selected record | Lines 94-99 | `TptRouteSchedulerJnt::whereIn('id', $ids)->get()` fetches full records. Then loads routes, shifts, vehicles, driverHelpers separately. No pagination — if hundreds of IDs selected, this could be slow. |
| BC-BIZ-DEEP-19 | `edit()` loads `Route::active()->get()` using scopeActive | Line 198 | Only active routes shown in edit form. But validation allows inactive route IDs (no exists rule). User could manually POST an inactive route_id. |
| BC-BIZ-DEEP-20 | `create()` also uses `::active()->get()` for all supporting data | Lines 45-48 | Consistent: both create and edit only show active entities. |
| BC-BIZ-DEEP-21 | `index()` (resource, not tab) uses `with(['route','shift','vehicle','driver','helper'])` | Line 30 | Direct index eager-loads helper correctly — contrast with SchedulerQuery() which omits helper (CR-24). |
| BC-BIZ-DEEP-22 | `index()` resource paginates at 20 | Line 32 | `paginate(20)` — direct index uses 20, tab uses 10. |
| BC-BIZ-DEEP-23 | `index()` resource orders by `scheduled_date DESC` | Line 31 | Direct index: newest first. Tab query: id DESC. Inconsistent ordering. |
| BC-BIZ-DEEP-24 | `toggleStatus()` uses route-model-binding, others use manual $id | `toggleStatus()` line 308 vs `show()` line 181, `edit()` line 193, etc. | Inconsistent parameter binding across methods. |
| BC-BIZ-DEEP-25 | `toggleStatus()` double save could cause race condition | Lines 312, 318 | Second save runs another UPDATE query. If another request modified the record between the two saves, second save could overwrite changes. But since is_active is already set in memory, both saves write the same value — minimal risk. |
| BC-BIZ-DEEP-26 | `activityLog()` is a global helper (not on model) | All usages: `activityLog($record, 'Event', ['message' => ...])` | The helper function is not namespaced. It likely creates an ActivityLog entry with morph map. |
| BC-BIZ-DEEP-27 | `forceDelete()` calls activityLog with record that still exists in DB | Lines 295-299 | `activityLog()` is called BEFORE `forceDelete()`. The record is still in DB when logged, so the morph relation works. After forceDelete, the record is gone but the log entry persists with a now-invalid morph reference. |
| BC-BIZ-DEEP-28 | `restore()` returns early if `onlyTrashed()` fails | Line 276 | `findOrFail()` throws ModelNotFoundException → 404. Restore never operates on non-trashed records. |
| BC-BIZ-DEEP-29 | `show()/edit()/update()/destroy()` use `findOrFail($id)` (no route-model-binding) | All use manual $id parameter | No implicit model binding — consistent among these 4 methods but inconsistent with toggleStatus(). |
| BC-BIZ-DEEP-30 | `TptRouteSchedulerJnt` has NO boot() events with DomainException | Model lines 1-61 | Unlike TptTrip which may throw DomainException for compliance violations during creating event, the scheduler model has no such guard. Schedulers can always be created/saved. |
| BC-BIZ-DEEP-31 | `trashed()` paginates at 20 | Line 266 | Same as direct index pagination. |
| BC-BIZ-DEEP-32 | `helper_id` nullable in both request and model | Request line 32: `nullable`, Model line 22: `helper_id` in fillable | Helper is optional — consistent throughout. |
| BC-BIZ-DEEP-33 | `pickup_drop` nullable in request but NOT NULL in DDL | Request line 33: `nullable`, DDL: `ENUM NOT NULL DEFAULT 'Pickup'` | If `pickup_drop` is null in request, what does controller store? Controller line 79 passes `$request->pickup_drop` directly. If null, DB uses DEFAULT 'Pickup'. Works, but request says nullable while DB says NOT NULL — misleading. |
| BC-BIZ-DEEP-34 | `storeTrip()` sets `created_by = auth()->id()` but NOT `updated_by` | Line 156 | Only `created_by` set on trip creation. No `updated_by` field in the create array. |
| BC-BIZ-DEEP-35 | `storeTrip()` hardcodes `status = 'Active'` for new trips | Line 154 | Trip status is always 'Active' when created from scheduler. No way to set a different initial status. |
| BC-BIZ-DEEP-36 | `storeTrip()` hardcodes `remarks` with the scheduler date | Line 155 | `'remarks' => 'Trip created from schedule for ' . $schedule->scheduled_date` — Descriptive but static. |
| BC-BIZ-DEEP-37 | `createtrip()` passes `$request->selected_ids` directly to view without validation | Line 92: `$ids = explode(',', $request->selected_ids)` | No check that IDs are numeric, exist, or belong to the current tenant. All passed to view for display. |
| BC-BIZ-DEEP-38 | `store()` condition for `is_active`: `$request->is_active ? 1 : 0` | Line 78 | Uses ternary on raw request value. If `is_active` is not sent at all (nullable in request), `$request->is_active` returns null → `null ? 1 : 0` = 0. So default is 0 (inactive) when not checked, but blade's checkbox sends value when checked and omits when unchecked. Correct behavior. |
| BC-BIZ-DEEP-39 | `update()` same `is_active` pattern: `$request->is_active ? 1 : 0` | Line 235 | Same as store — checkbox behavior works correctly. |
| BC-BIZ-DEEP-40 | `store()` flash message uses `flash('created.route_scheduler')` (localized) | Line 85 | Uses language key, not hardcoded string. Good for i18n. |
| BC-BIZ-DEEP-41 | All flash messages in controller use `flash('key')` pattern | Lines 85, 242, 257, 284, 302 | Consistent localization pattern across all CRUD operations. |
| BC-BIZ-DEEP-42 | `toggleStatus()` flash message uses `flash('status_updated.route_scheduler')` and `flash('status_switch_failed.route_scheduler')` | Lines 322, 328 | Localized flash messages in JSON response. |
| BC-BIZ-DEEP-43 | `storeTrip()` success message is HARDCODED string (not flash key) | Lines 166-172 | `$message = count($createdTrips) . ' trip(s) created successfully!'` — Not localized. Inconsistent with other messages in the same controller. |
| BC-BIZ-DEEP-44 | `RouteSchedulerPolicy` uses wrong permission prefix `transport.` instead of `tenant.` | Policy lines 15, 23, 39, 47, 55, 63, 71 | Since controller uses `tenant.` prefix, this policy would never match. Likely `TransportRouteSchedulerPolicy` is the registered one. |
| BC-BIZ-DEEP-45 | `TransportRouteSchedulerPolicy` has additional permissions: import, export, print | Lines 78-97 | These extra permissions are not used by the controller — no import/export/print methods exist. |
| BC-BIZ-DEEP-46 | `RouteSchedulerPolicy` `status()` method has WRONG type hint: `Route $route` | Policy line 29 | Should be `TptRouteSchedulerJnt`. Would cause 500 error if this policy were invoked. |
| BC-BIZ-DEEP-47 | `SchedulerQuery()` helper not eagerly loaded in TripMgmtController | Line 177 | Only `route`, `shift`, `vehicle`, `driver` eager loaded. `helper` is missing — causes N+1 (see TCR-CR24). |
| BC-BIZ-DEEP-48 | `hasTrip()` method in model runs separate query | Model line 58: `return $this->trips()->exists()` | `withCount('trips')` already provides `trips_count`. View should use `$item->trips_count > 0` instead of `$item->hasTrip()`. |
| BC-BIZ-DEEP-49 | `store()` duplicate check does NOT include `pickup_drop` | Lines 58-63 | Two schedules with same shift+route+vehicle+driver+date but different pickup_drop (Pickup vs Drop) would be flagged as duplicates by controller, even though DB allows them (separate unique key per pickup_drop in combination). |
| BC-BIZ-DEEP-50 | `toggleStatus()` JSON error response returns 200, not 500 | Lines 326-329 | `return response()->json([...])` without explicit status code → default 200. Error case should return 400/500. |
| BC-BIZ-DEEP-51 | No default `sort` or `order` validation on any endpoint | All GET methods | No protection against SQL injection via `orderBy` (though not user-supplied here). |
| BC-BIZ-DEEP-52 | `createtrip()` uses `whereIn('id', $ids)` with no `->active()` or `->whereNull('deleted_at')` filter | Line 94 | Could potentially load trashed scheduler entries if IDs of trashed records are passed. |
| BC-BIZ-DEEP-53 | `storeTrip()` also does NOT filter out trashed schedulers | Line 118 | Trashed schedulers could be selected for trip generation, potentially creating trips from deleted schedules. |
| BC-BIZ-DEEP-54 | `storeTrip()` exception catch does NOT distinguish DomainException from other exceptions | Line 160 | Catches all `\Exception` types. DomainException (compliance) is caught same as DB error or any other exception. All counted as `complianceSkipped`. Non-compliance exceptions are misleadingly reported as compliance skips. |
| BC-BIZ-DEEP-55 | `storeTrip()` logs warning but does NOT rethrow | Line 162 | `Log::warning(...)` — the exception is swallowed. No monitoring/alerting for systemic failures. |
| BC-BIZ-DEEP-56 | `SchedulerQuery()` uses `orderBy('id', 'DESC')` — not `scheduled_date` | TripMgmtController line 179 | Tab sorts by creation order (id), not by schedule date. Newest records appear first regardless of scheduled_date. |
| BC-BIZ-DEEP-57 | `RouteSchedulerController@index()` uses `orderBy('scheduled_date', 'DESC')` — different from tab | Controller line 31 | Resource index sorts by scheduled_date, tab sorts by id. Inconsistent user experience. |
| BC-BIZ-DEEP-58 | `SchedulerQuery()` always applies tab guard — no data returned without `?tab=scheduler` | TripMgmtController line 183 | If tab parameter is missing or different, query returns ALL records without filters or ordering. |
| BC-BIZ-DEEP-59 | `store()` does NOT check if referenced shift/route/vehicle/driver are ACTIVE | Lines 71-80 | Creates scheduler even if referenced entities are inactive. Validation only checks `required`, not `exists` or `active`. |
| BC-BIZ-DEEP-60 | `createtrip()` loads ALL routes/shifts/vehicles/driverHelpers (not just active matching) | Lines 95-99 | Supporting data uses `::active()->get()` which filters active. But selected records may reference inactive entities — inactive references still display. |

---

## 9. CODE-TRACE: Method Flow Analysis

### CODE-TRACE-01: store() Method Flow

```
RouteSchedulerController@store()
  │
  ├── Line 57: Gate::authorize('tenant.route-scheduler.create')
  │     └── Authorized? YES → continue | NO → 403
  │
  ├── Lines 58-63: Duplicate Check Query
  │     SELECT EXISTS(
  │       SELECT 1 FROM tpt_route_scheduler_jnt
  │       WHERE shift_id = ? AND route_id = ? AND vehicle_id = ? AND driver_id = ? AND scheduled_date = ?
  │     )
  │     └── EXISTS? YES → back()->withErrors() | NO → continue
  │
  ├── Lines 71-80: TptRouteSchedulerJnt::create([...])
  │     INSERT INTO tpt_route_scheduler_jnt
  │     (shift_id, route_id, vehicle_id, driver_id, helper_id, scheduled_date, is_active, pickup_drop, created_at, updated_at)
  │     VALUES (?, ?, ?, ?, ?, ?, ?, ?, NOW(), NOW())
  │     └── Returns created $data model
  │
  ├── Line 82: activityLog($data, 'Created', ['message' => 'Route scheduled successfully.'])
  │     └── INSERT INTO activity_log (subject_type, subject_id, event, properties, ...)
  │
  └── Lines 84-85: redirect()->route('transport.trip-management.index')
        └── with('success', flash('created.route_scheduler'))
```

### CODE-TRACE-02: storeTrip() Method Flow

```
RouteSchedulerController@storeTrip()
  │
  ├── Line 106: Gate::authorize('tenant.driver-route-vehicle.update')
  │     └── Authorized? YES → continue | NO → 403
  │
  ├── Lines 109-112: $request->validate(['selected_ids'=>'required|string', 'trip_date'=>'required|date'])
  │     └── Pass? YES → continue | NO → ValidationException → 422
  │
  ├── Line 115: $selectedIds = explode(',', $request->selected_ids)
  │     └── "1,2,3" → [1, 2, 3]
  │
  ├── Lines 118-120: $schedules = TptRouteSchedulerJnt::whereIn('id', [1,2,3])->with([...])->get()
  │     └── 3 records found? YES → continue | NO (empty) → redirect()->back()->with('error')
  │
  ├── INIT: $createdTrips = [], $skippedTrips = 0, $complianceSkipped = 0
  │
  ├── FOREACH $schedule IN $schedules:
  │   │
  │   ├── Lines 133-135: Duplicate Check
  │   │     TptTrip::where('trip_date', $schedule->scheduled_date)
  │   │              ->where('route_scheduler_id', $schedule->id)->exists()
  │   │     └── EXISTS? YES → $skippedTrips++, continue | NO → continue
  │   │
  │   ├── TRY:
  │   │   ├── Lines 144-157: TptTrip::create([...])
  │   │   │     INSERT INTO tpt_trip (trip_date, route_scheduler_id, route_id, shift_id,
  │   │   │     vehicle_id, driver_id, helper_id, start_time, end_time, status, remarks,
  │   │   │     created_by, created_at, updated_at)
  │   │   │     VALUES ($schedule->scheduled_date, $schedule->id, $schedule->route_id, ...)
  │   │   │
  │   │   └── $createdTrips[] = $trip
  │   │
  │   └── CATCH (\Exception $e):
  │       ├── $complianceSkipped++
  │       └── Log::warning("Trip generation failed for scheduler...")
  │
  ├── Lines 166-172: Build message with counts
  │
  └── Lines 175-176: redirect()->back()->with('success', $message)
```

### CODE-TRACE-03: toggleStatus() Method Flow

```
RouteSchedulerController@toggleStatus(TptRouteSchedulerJnt $scheduler)
  │
  ├── Line 308: Route-Model-Binding resolves $scheduler
  │     └── TptRouteSchedulerJnt WHERE id = {scheduler} → found? YES → continue | NO → 404
  │
  ├── Line 310: Gate::authorize('tenant.route-scheduler.update')
  │     └── Authorized? YES → continue | NO → 403
  │
  ├── Line 311: $scheduler->is_active = !$scheduler->is_active
  │     └── Original: 1 → 0 | Original: 0 → 1
  │
  ├── Line 312: $scheduler->save()  ← FIRST SAVE
  │     └── UPDATE tpt_route_scheduler_jnt SET is_active = ?, updated_at = NOW() WHERE id = ?
  │     └── Returns true/false (ignored!)
  │
  ├── Lines 314-316: activityLog($scheduler, 'Toggled', ['message' => 'Status updated.'])
  │     └── INSERT INTO activity_log (...)
  │
  ├── Line 318: if ($scheduler->save())  ← SECOND SAVE (redundant)
  │     └── UPDATE tpt_route_scheduler_jnt SET is_active = ?, updated_at = NOW() WHERE id = ?
  │     └── Returns true? → JSON success | false? → JSON failure
  │
  └── Note: Double save is a code smell (TC-CR23). Second save writes identical data.
```

### CODE-TRACE-04: forceDelete() Method Flow

```
RouteSchedulerController@forceDelete($id)
  │
  ├── Line 292: Gate::authorize('tenant.route-scheduler.forceDelete')
  │     └── Authorized? YES → continue | NO → 403
  │
  ├── Line 293: $record = TptRouteSchedulerJnt::onlyTrashed()->findOrFail($id)
  │     └── SELECT * FROM tpt_route_scheduler_jnt WHERE id = ? AND deleted_at IS NOT NULL
  │     └── Found? YES → continue | NO → ModelNotFoundException → 404
  │
  ├── Lines 295-297: activityLog($record, 'ForceDelete', ['message' => '...'])
  │     └── INSERT INTO activity_log (...)  ← Executed BEFORE forceDelete()
  │     └── Record still exists at this point → morph reference works
  │
  ├── Line 299: $record->forceDelete()
  │     └── DELETE FROM tpt_route_scheduler_jnt WHERE id = ?  ← Permanent removal
  │
  └── Lines 301-302: redirect()->route('transport.trip-management.index')
        └── with('success', flash('force_deleted.route_scheduler'))
```

### CODE-TRACE-05: SchedulerQuery() via TripMgmtController

```
TripMgmtController@SchedulerQuery(Request $request)
  │
  ├── Line 177: $query = TptRouteSchedulerJnt::with(['route','shift','vehicle','driver'])
  │     └── Eager loads: route, shift, vehicle, driver (NOT helper — see CR-24)
  │
  ├── Line 178: ->withCount('trips')
  │     └── Adds subquery: SELECT COUNT(*) FROM tpt_trip WHERE route_scheduler_id = tpt_route_scheduler_jnt.id AS trips_count
  │
  ├── Line 179: ->orderBy('id', 'DESC')
  │     └── ORDER BY id DESC (newest first)
  │
  ├── Line 181: $tab = 'scheduler' (from request)
  │
  ├── Line 183: if ($tab === 'scheduler')
  │     └── TRUE → enters filter block
  │
  ├── Lines 185-186: if status filled → where('is_active', $request->status)
  ├── Lines 189-190: if schedule_date filled → where('scheduled_date', $request->schedule_date)
  ├── Lines 194-198: foreach ['shift_id','route_id','vehicle_id','driver_id','helper_id']
  │     └── Each: if filled → where($field, $request->$field)
  │
  └── Line 201: return $query
        └── Paginated at TripMgmtController line 89: ->paginate(10)
```

### CODE-TRACE-06: index() (Direct Resource, Not Tab)

```
RouteSchedulerController@index(Request $request)
  │
  ├── Line 29: Gate::authorize('tenant.route-scheduler.viewAny')
  │     └── Authorized? YES → continue | NO → 403
  │
  ├── Lines 30-32: $data = TptRouteSchedulerJnt::with(['route','shift','vehicle','driver','helper'])
  │     ->orderBy('scheduled_date', 'DESC')
  │     ->paginate(20)
  │     └── Eager loads ALL 5 relations (including helper — correct)
  │     └── ORDER BY scheduled_date DESC
  │     └── 20 per page
  │
  ├── Line 34: return view('transport::route-scheduler.index', compact('data'))
  │     └── Passes $data to view
  │     └── GAP: View expects $sheduleData (from tab), but gets $data → Undefined variable (CR-21)
  │
  └── Note: This endpoint is broken when accessed directly.
        Use via tab: /transport/trip-management?tab=scheduler
```

### CODE-TRACE-07: createtrip() Method Flow

```
RouteSchedulerController@createtrip(Request $request)
  │
  ├── Line 90: Gate::authorize('tenant.driver-route-vehicle.update')
  │     └── Authorized? YES → continue | NO → 403
  │
  ├── Line 92: $ids = explode(',', $request->selected_ids)
  │     └── "1,2,3" → ["1", "2", "3"]  (no numeric validation)
  │
  ├── Lines 94-99: return view('transport::route-scheduler.createtrip', [
  │     'selectedRecords' => TptRouteSchedulerJnt::whereIn('id', $ids)->get(),
  │     'routes'          => Route::active()->get(),
  │     'shifts'          => Shift::active()->get(),
  │     'VehiclesData'    => Vehicle::active()->get(),
  │     'driverHelpers'   => DriverHelper::active()->get(),
  │   ])
  │     └── Loads selected scheduler records
  │     └── Loads supporting data for dropdowns
  │     └── Note: No pagination on selectedRecords
  │
  └── View renders create-trip form with pre-populated data
```

### CODE-TRACE-08: show() Method Flow

```
RouteSchedulerController@show($id)
  │
  ├── Line 183: Gate::authorize('tenant.route-scheduler.view')
  │     └── Authorized? YES → continue | NO → 403
  │
  ├── Lines 184-185: $record = TptRouteSchedulerJnt::with(['route','shift','vehicle','driver','helper'])
  │     ->findOrFail($id)
  │     └── Eager loads ALL 5 relations (including helper)
  │     └── findOrFail: found? → return record | not found → 404
  │
  ├── Line 187: return view('transport::route-scheduler.show', compact('record'))
  │     └── Passes single $record to show view
  │
  └── View renders all record fields with relations
```

### CODE-TRACE-09: Duplicate Check Contrast — Store vs Update

```
STORE (line 58-63):                              UPDATE (line 212-218):
  TptRouteSchedulerJnt::where(                      TptRouteSchedulerJnt::where('id', '!=', $id)
    'shift_id', $request->shift_id                    ->where('shift_id', $request->shift_id)
  )->where(                                          ->where('route_id', $request->route_id)
    'route_id', $request->route_id                   ->where('vehicle_id', $request->vehicle_id)
  )->where(                                          ->where('driver_id', $request->driver_id)
    'vehicle_id', $request->vehicle_id               ->where('scheduled_date', $request->scheduled_date)
  )->where(                                          ->exists()
    'driver_id', $request->driver_id
  )->where(
    'scheduled_date', $request->scheduled_date
  )->exists()

DIFFERENCES:
  │
  ├── Update EXCLUDES current ID: `->where('id', '!=', $id)`
  │     └── Prevents false-positive where updating record matches its own values
  │
  └── Both use SAME 5 fields: shift_id, route_id, vehicle_id, driver_id, scheduled_date
        └── Neither checks pickup_drop — potential mismatch with DB unique key
```

### CODE-TRACE-10: TptTrip Compliance Exception in storeTrip()

```
TptTrip::create([...]) inside storeTrip() FOREACH loop
  │
  ├── TptTrip model boot() method (in TptTrip.php)
  │     └── Registers 'creating' event
  │
  ├── Event: 'creating' fires before INSERT
  │     └── Validates: driver license expiry, vehicle fitness, vehicle insurance
  │
  ├── VALIDATION PASSES:
  │     └── INSERT INTO tpt_trip (...) VALUES (...)
  │     └── $createdTrips[] = $trip
  │
  ├── VALIDATION FAILS (DomainException):
  │     └── throw new \DomainException('License has expired for driver...')
  │     └── Caught by `catch (\Exception $e)` at line 160
  │     └── $complianceSkipped++ at line 161
  │     └── Log::warning("Trip generation failed...") at line 162
  │     └── No trip created — silently skipped
  │
  └── NOTE: All exceptions caught, including non-compliance ones like DB errors.
        They are ALL counted as complianceSkipped — misleading.
```

---

## 10. Gap Summary

| ID | Severity | Gap Description | Impact |
|----|----------|-----------------|--------|
| GAP-01 | CRITICAL | `index()` passes `$data` but view expects `$sheduleData` | Direct index is broken (500 error) |
| GAP-02 | HIGH | `RouteSchedulerRequest` missing `exists:` FK validations | Invalid FK causes DB 500 instead of validation error |
| GAP-03 | HIGH | `RouteSchedulerRequest` missing `Rule::in(['Pickup','Drop'])` for pickup_drop | Invalid ENUM value causes DB 500 |
| GAP-04 | HIGH | Edit view offers `Both` for pickup_drop but ENUM only allows Pickup/Drop | Submitting 'Both' causes DB 500 |
| GAP-05 | HIGH | `storeTrip()` has NO activityLog call | Batch trip creation has no audit trail |
| GAP-06 | HIGH | View gates for `edit`/`status` permissions but controller gates on `update` | Users see buttons they cannot use (403) |
| GAP-07 | MEDIUM | `RouteSchedulerPolicy` uses `transport.` prefix vs controller's `tenant.` prefix | Policy mismatch — dead code or broken |
| GAP-08 | MEDIUM | `RouteSchedulerPolicy.status()` uses wrong type hint `Route $route` | Would cause 500 if policy invoked |
| GAP-09 | MEDIUM | `SchedulerQuery()` omits `helper` from eager load | N+1 query for helper per row |
| GAP-10 | MEDIUM | No `DB::beginTransaction()` in any RouteSchedulerController method | No atomicity for any CRUD operation |
| GAP-11 | MEDIUM | `toggleStatus()` saves twice (lines 312 + 318) | Redundant DB write |
| GAP-12 | LOW | `hasTrip()` ignores preloaded `trips_count` | Extra query per row if view uses hasTrip() |
| GAP-13 | LOW | `storeTrip()` ignores `$request->trip_date` — uses `$schedule->scheduled_date` instead | Request field accepted but never used |
| GAP-14 | LOW | `$request->trip_date` validated but unused in storeTrip() | Misleading API — field accepted but ignored |
| GAP-15 | LOW | Controller duplicate check ignores `pickup_drop` but DB unique key includes it | Mismatch between app-level and DB-level constraints |
| GAP-16 | LOW | `toggleStatus()` returns 200 for both success AND failure | Error case should return 4xx |
| GAP-17 | LOW | `storeTrip()` catches all exceptions as `complianceSkipped` | Non-compliance errors misclassified |
| GAP-18 | LOW | `createtrip()`/`storeTrip()` don't filter out trashed schedulers | Trashed records could generate trips |
| GAP-19 | LOW | `index()` resource orders by `scheduled_date DESC` but tab orders by `id DESC` | Inconsistent ordering between two access paths |
| GAP-20 | LOW | `index()` resource paginates at 20, tab paginates at 10 | Different page sizes for same data |
| GAP-21 | LOW | `create()` loads only active supporting data but validation accepts inactive FK values | Form hides inactive entities but API accepts them — potential 500 |
| GAP-22 | LOW | `storeTrip()` success message is hardcoded English string (not localized) | Inconsistent with other flash messages that use `flash('key')` pattern |
| GAP-23 | LOW | Policy file `RouteSchedulerPolicy.php` and `TransportRouteSchedulerPolicy.php` both exist | Duplicate policy files cause confusion about which is registered |
| GAP-24 | LOW | `TransportRouteSchedulerPolicy` defines import/export/print permissions but no controller methods | Dead permissions in policy |
| GAP-25 | LOW | `toggleStatus()` gates on `update` but view uses `status` permission | Permission `tenant.route-scheduler.status` only controls visibility, not the action itself |
| GAP-26 | LOW | `edit.blade.php` offers `Both` value for pickup_drop ENUM | Dropdown option is out of sync with DDL — guaranteed DB error on submit |
| GAP-27 | LOW | `TripMgmtController@index()` passes `$sheduleData` but direct resource passes `$data` | Variable name inconsistency between tab and resource views |
| GAP-28 | INFO | `SchedulerQuery()` withCount('trips') adds trips_count attribute that view never uses | Preloaded data is wasted if view uses `$item->hasTrip()` instead |
| GAP-29 | INFO | `storeTrip()` uses `$schedule->scheduled_date` for trip_date but accepts `$request->trip_date` in validation | The `trip_date` request field is validated then completely ignored — dead code in validation |
| GAP-30 | INFO | No `updated_by` or `deleted_by` tracking on any RouteScheduler operation | No user attribution for who performed updates/deletes on scheduler records |
| GAP-31 | INFO | `storeTrip()` does NOT check `scheduled_date` against `trip_date` consistency | Could create trips where trip_date doesn't match scheduler's scheduled_date if request manipulation occurs |
| GAP-32 | INFO | No `abort()` or custom exception handler for `ModelNotFoundException` in controller | Relies on Laravel's default 404 rendering — consistent but no custom error context |

---

## 11. Audit Trail Verification Matrix

| Operation | activityLog Called | Event Name | Message | Location |
|-----------|-------------------|------------|---------|----------|
| Store (create) | ✅ YES | `Created` | 'Route scheduled successfully.' | `RouteSchedulerController.php:82` |
| Update | ✅ YES | `Updated` | 'Route schedule updated.' | `RouteSchedulerController.php:239` |
| Soft Delete | ✅ YES | `Deleted` | 'Route schedule moved to trash.' | `RouteSchedulerController.php:254` |
| Restore | ✅ YES | `Restored` | 'Route schedule restored.' | `RouteSchedulerController.php:280` |
| Force Delete | ✅ YES | `ForceDelete` | 'Route schedule permanently deleted.' | `RouteSchedulerController.php:295` |
| Toggle Status | ✅ YES | `Toggled` | 'Status updated.' | `RouteSchedulerController.php:314` |
| Batch Trip Create (storeTrip) | ❌ NO | — | — | **GAP** — lines 103-177 have NO activityLog call |

---

## 12. Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-07-21 | QA Team | Initial creation from RouteSchedulerController.php v1 |
| 2.0 | 2026-07-21 | QA Team | Deepened to 1500+ lines: added full Section 7 step-by-step for all TCs, BC-BIZ-DEEP (55 conditions), CODE-TRACE (10 method flows), Gap Summary (25 gaps) |

---

*Template: tpt_PickupStopsList_TcList.md (Syllabus depth) | Entity: RouteScheduler | Date: 2026-07-21*
