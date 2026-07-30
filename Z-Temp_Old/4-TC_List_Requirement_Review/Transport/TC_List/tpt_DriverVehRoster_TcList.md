# tpt_DriverVehRoster_TcList

## Module: Transport → Trip Management → Driver Route Vehicle Roster

---

## 1. Feature Information

| Attribute | Details |
|-----------|---------|
| **Module** | Transport (TPT) |
| **Tab Group** | Trip Management |
| **Feature** | Driver Route Vehicle Roster — assign drivers to routes/vehicles with effective date ranges, auto-generating daily scheduler entries |
| **URL(s)** | `/transport/trip-management?tab=driver_roster` (working tab-hub index via TripMgmtController), `/driver-route-vehicle` (standalone CRUD index — **BROKEN**: no data passed to view), `/driver-route-vehicle/create`, `/driver-route-vehicle` (store), `/driver-route-vehicle/{id}` (show), `/driver-route-vehicle/{id}/edit`, `/driver-route-vehicle/{id}` (update PUT), `/driver-route-vehicle/{id}` (destroy DELETE), `/driver-route-vehicle/trash/view` (trash), `/driver-route-vehicle/{id}/restore` (restore GET), `/driver-route-vehicle/{id}/force-delete` (forceDelete DELETE), `/driver-route-vehicle/{vehicle}/toggle-status` (toggleStatus POST — route param `{vehicle}` but controller receives `$id`) |
| **Controller** | `Modules\Transport\Http\Controllers\DriverRouteVehicleController` — 11 methods: index, create, store, show, edit, update, destroy, trashed, restore, forceDelete, toggleStatus |
| **Tab Container Ctlr** | `Modules\Transport\Http\Controllers\TripMgmtController@index()` — tab: `driver_roster` |
| **Model** | `Modules\Transport\Models\DriverRouteVehicleJnt` — table: `tpt_driver_route_vehicle_jnt`, 5 relationships, 10 fillable fields, SoftDeletes via BaseModel |
| **Validation** | `Modules\Transport\Http\Requests\DriverRouteVehicleRequest` — 7 field rules, authorize(), prepareForValidation() |
| **Permissions** | `tenant.driver-route-vehicle.viewAny`, `.view`, `.create`, `.update`, `.delete`, `.restore`, `.forceDelete` |
| | Permission `edit` exists in blade (`@can('...edit')`) but controller `edit()` uses `Gate::authorize('...update')` — **mismatch** |
| | Permission `status` exists in blade (`@can('...status')`) but controller `toggleStatus()` uses `Gate::authorize('...update')` — **mismatch** |
| **Soft Deletes** | Yes (`BaseModel` with `SoftDeletes` trait) |
| **Activity Log** | Events: `Created`, `Updated`, `Deleted`, `Restore`, `ForceDelete`, `Toggled` |
| **Auto Scheduler** | On store/update, automatically creates/rebuilds daily `TptRouteSchedulerJnt` records for each date in effective range |
| **DB Table** | `tpt_driver_route_vehicle_jnt` — 14 columns + 5 FKs + 1 DDL trigger (`trg_driver_route_vehicle_unique_assignment`) |
| **Key Features** | Date-range overlap prevention, auto-scheduler generation, Pickup/Drop/Both expansion, DDL trigger for race-condition protection |

---

## 2. Pre-conditions

| # | Pre-condition | Source |
|---|--------------|--------|
| PC-01 | User must have `tenant.driver-route-vehicle.*` permissions | Policy + Gate::authorize() in every method |
| PC-02 | At least one active `tpt_shift` must exist (FK `shift_id` CASCADE) | Migration + `Shift::active()->get()` |
| PC-03 | At least one active `tpt_route` must exist (FK `route_id` CASCADE) | Migration + `Route::active()->get()` |
| PC-04 | At least one active `tpt_vehicle` must exist (FK `vehicle_id` CASCADE) | Migration + `Vehicle::active()->get()` |
| PC-05 | At least one active `tpt_personnel` with role Driver/Helper must exist | Migration + `DriverHelper::active()->get()` |
| PC-06 | Tenant context initialized via `tenancy()->initialize()` | Multi-tenant arch |
| PC-07 | Tab `driver_roster` registered with permission check | `tripmanagement.blade.php:10` |
| PC-08 | `effective_from` and `effective_to` must form valid range | Controller store line 52 + Request rule `after_or_equal:effective_from` |
| PC-09 | Date overlap validation prevents duplicate assignments | Controller store lines 59-91, update lines 248-260 |
| PC-10 | NULL `effective_to` defaults to +10 years for scheduler | Controller store line 119 |
| PC-11 | `pickup_drop` ENUM only accepts `'Pickup'` or `'Drop'` — `'Both'` NOT valid at DB level | Migration ENUM |
| PC-12 | Standalone `/driver-route-vehicle` index is **BROKEN** — no variables passed to view | Controller index line 27 |

---

## 3. Default Data Load

| # | Data Load Rule | Details | Source |
|---|----------------|---------|--------|
| DL-01 | Tab container loads ALL Trip Management data in single TripMgmtController@index() call | TripMgmtController.php:36-112 |
| DL-02 | Driver Route Vehicle Roster fetched via `driverRouteVehicleQuery($request)->paginate(10)->withQueryString()` | TripMgmtController.php:88 |
| DL-03 | Eager loads: `with(['route','shift','vehicle','driver'])` — **helper NOT loaded** (potential N+1) | TripMgmtController.php:120 |
| DL-04 | Ordered by `id DESC` (latest first) | TripMgmtController.php:121 |
| DL-05 | Paginated at 10 per page, query string preserved | TripMgmtController.php:88 |
| DL-06 | Search filter: `whereHas('route',name/code) OR whereHas('vehicle',registration_no) OR whereHas('driver',name)` | TripMgmtController.php:132-143 |
| DL-07 | Direct filters: shift_id, route_id, vehicle_id, driver_id, helper_id — all AND via loop | TripMgmtController.php:156-168 |
| DL-08 | Status filter: `$request->has('status') && $request->status !== ''` on `is_active` column | TripMgmtController.php:149-151 |
| DL-09 | Data also loaded for dropdowns: `$vehicles`, `$routes`, `$driverHelpers`, `$shifts` | TripMgmtController.php:73-76 |
| DL-10 | Supporting entities (Vehicle/Route/DriverHelper/Shift) — ALL records, no active filter | TripMgmtController.php:73-76 |
| DL-11 | Tab id `driver_roster` registered with permission `tenant.driver-route-vehicle.viewAny` | tripmanagement.blade.php:10 |
| DL-12 | Standalone index (`/driver-route-vehicle`) returns empty view — NO data loaded | DriverRouteVehicleController.php:27 |

---

## 4. Test Data Strategy

| # | Data Strategy | Details | Source |
|---|---------------|---------|--------|
| TD-01 | **Unique suffix**: `now()->format('His') . random_int(100,999)` via `uniqueSuffix()` | Standard test helper |
| TD-02 | Shift/Route/Vehicle/Driver/Helper: reference existing active records via IDs | FK constraints |
| TD-03 | `effective_from`/`effective_to`: required date range, `after_or_equal:effective_from` | Request + Controller check |
| TD-04 | **Date overlap**: NOT checked in FormRequest — done in controller with complex date-overlap query | Controller store lines 59-91 |
| TD-05 | `pickup_drop`: supports `Pickup`, `Drop`, `Both` — `Both` creates scheduler entries for both types | Controller store lines 124-134 |
| TD-06 | `is_active`: boolean via `$request->boolean('is_active')` in `prepareForValidation` | DriverRouteVehicleRequest.php:78 |
| TD-07 | **Scheduler auto-generation**: create → loop dates; update → force-delete old + upsert new | Controller store lines 116-183, update lines 300-340 |
| TD-08 | Pre-test cleanup: delete created records by known IDs | Standard |
| TD-09 | **Soft delete**: blocks if today within range; deletes scheduler rows first, then main record | Controller destroy lines 361-400 |
| TD-10 | **Restore**: restores main record + onlyTrashed scheduler by shift/route/pickup_drop | Controller restore lines 415-448 |
| TD-11 | **Force delete**: `onlyTrashed()->findOrFail()` then scheduler delete + main forceDelete | Controller forceDelete lines 453-476 |
| TD-12 | **ToggleStatus**: flips `is_active` on main + syncs all scheduler records | Controller toggleStatus lines 482-512 |

---

## 5. Business Conditions (BC)

### 5.1 BC-DB: Database Schema — `tpt_driver_route_vehicle_jnt`

| BC ID | Column | Type (DDL) | Constraints | Source |
|-------|--------|-----------|-------------|--------|
| BC-DB-01 | id | INT UNSIGNED | PK, auto-increment | Migration |
| BC-DB-02 | shift_id | INT UNSIGNED | NOT NULL, FK → tpt_shift.id, ON DELETE CASCADE | Migration |
| BC-DB-03 | route_id | INT UNSIGNED | NOT NULL, FK → tpt_route.id, ON DELETE CASCADE | Migration |
| BC-DB-04 | vehicle_id | INT UNSIGNED | DEFAULT NULL, FK → tpt_vehicle.id, ON DELETE CASCADE | Migration |
| BC-DB-05 | driver_id | INT UNSIGNED | DEFAULT NULL, FK → tpt_personnel.id, ON DELETE CASCADE | Migration |
| BC-DB-06 | helper_id | INT UNSIGNED | DEFAULT NULL, FK → tpt_personnel.id, ON DELETE SET NULL | Migration |
| BC-DB-07 | pickup_drop | ENUM('Pickup','Drop') | NOT NULL, DEFAULT 'Pickup' | Migration |
| BC-DB-08 | effective_from | DATE | NOT NULL | Migration |
| BC-DB-09 | effective_to | DATE | DEFAULT NULL | Migration |
| BC-DB-10 | total_students | INT | NOT NULL, DEFAULT 0 | Migration |
| BC-DB-11 | is_active | TINYINT(1) | NOT NULL, DEFAULT 1 | Migration |
| BC-DB-12 | created_at | TIMESTAMP | NULL, DEFAULT CURRENT_TIMESTAMP | Migration |
| BC-DB-13 | updated_at | TIMESTAMP | NULL, DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP | Migration |
| BC-DB-14 | deleted_at | TIMESTAMP | NULL (soft delete) | Migration |
| BC-DB-15 | DDL Trigger | `trg_driver_route_vehicle_unique_assignment` | BEFORE INSERT — prevents overlapping assignments (SIGNAL SQLSTATE '45000') | DB Trigger |

### 5.2 BC-VAL: Validation Rules — `DriverRouteVehicleRequest`

| BC ID | Field | Rule | Error Message | Source |
|-------|-------|------|---------------|--------|
| BC-VAL-01 | shift_id | required, `exists:tpt_shift,id` | Default | DriverRouteVehicleRequest.php:31-34 |
| BC-VAL-02 | route_id | required, `exists:tpt_route,id` | Default | DriverRouteVehicleRequest.php:36-39 |
| BC-VAL-03 | vehicle_id | required, `exists:tpt_vehicle,id` | Default | DriverRouteVehicleRequest.php:41-44 |
| BC-VAL-04 | driver_id | required (no `exists` check) | Default | DriverRouteVehicleRequest.php:46-48 |
| BC-VAL-05 | helper_id | nullable (no `exists` check) | — | DriverRouteVehicleRequest.php:50-52 |
| BC-VAL-06 | effective_from | required, date | Default | DriverRouteVehicleRequest.php:54-57 |
| BC-VAL-07 | effective_to | required, date, `after_or_equal:effective_from` | Default | DriverRouteVehicleRequest.php:59-63 |
| BC-VAL-08 | is_active | required, boolean (normalized via `prepareForValidation` → `$this->boolean('is_active')`) | Default | DriverRouteVehicleRequest.php:65-68,75-80 |

**Gaps**: `pickup_drop` and `total_students` are NOT in request validation rules (only in `$fillable`). `driver_id` and `helper_id` lack `exists:tpt_personnel,id` checks.

### 5.3 BC-AUTH: Authorization (Permission Gates)

| BC ID | Permission | Controller Method | Behavior | Source |
|-------|-----------|-------------------|----------|--------|
| BC-AUTH-01 | tenant.driver-route-vehicle.viewAny | index() (both) | Tab hidden without; standalone → 403 | DriverRouteVehicleController.php:25 |
| BC-AUTH-02 | tenant.driver-route-vehicle.view | show() | Without → 403 | DriverRouteVehicleController.php:229 |
| BC-AUTH-03 | tenant.driver-route-vehicle.create | store(), create() | Without → 403; also in FormRequest.authorize() | DriverRouteVehicleController.php:35,49 |
| BC-AUTH-04 | tenant.driver-route-vehicle.update | update(), edit() | Without → 403; also in FormRequest.authorize() | DriverRouteVehicleController.php:211,241 |
| BC-AUTH-05 | tenant.driver-route-vehicle.delete | destroy() | Without → 403 | DriverRouteVehicleController.php:359 |
| BC-AUTH-06 | tenant.driver-route-vehicle.restore | restore(), trashed() | Without → 403 | DriverRouteVehicleController.php:407,417 |
| BC-AUTH-07 | tenant.driver-route-vehicle.forceDelete | forceDelete() | Without → 403 | DriverRouteVehicleController.php:455 |
| BC-AUTH-08 | tenant.driver-route-vehicle.update | toggleStatus() | Without → 403 (uses update gate) | DriverRouteVehicleController.php:484 |

#### Blade-Controller Permission Mismatches

| BC ID | View Permission | Controller Gate | Impact | Source |
|-------|----------------|-----------------|--------|--------|
| BC-AUTH-09 | `@can('...edit')` for Edit button | `edit()` uses `Gate::authorize('...update')` | User with `update` but not `edit` sees button → 403. User with `edit` but not `update` has button hidden but can access URL. | index.blade.php:91 vs ctlr:211 |
| BC-AUTH-10 | `@can('...status')` for toggle | `toggleStatus()` uses `Gate::authorize('...update')` | User with `status` but not `update` sees toggle → 403. User with `update` but not `status` can toggle via URL. | index.blade.php:88 vs ctlr:484 |

### 5.4 BC-BIZ: Business Logic

| BC ID | Condition | Expected Behavior | Source |
|-------|-----------|-------------------|--------|
| BC-BIZ-01 | Create via `DriverRouteVehicleJnt::create([...])` in DB transaction | New record + daily scheduler entries for date range | ctlr store:99-183 |
| BC-BIZ-02 | Create with `pickup_drop=Both` | Two scheduler entries per day (Pickup + Drop) | ctlr store:124-134 |
| BC-BIZ-03 | Create with `effective_to=NULL` | Scheduler generated for 10 years from effective_from | ctlr store:119 |
| BC-BIZ-04 | Create with overlapping assignment | Controller overlap check → back with `date_range` error | ctlr store:59-96 |
| BC-BIZ-05 | Create with `effective_to < effective_from` | Controller date check → back with error | ctlr store:52-56 |
| BC-BIZ-06 | Activity log on create | `activityLog($driverRoute, 'Created', [...])` | ctlr store:185-187 |
| BC-BIZ-07 | Update record | Old scheduler force-deleted; new scheduler upserted | ctlr update:300-340 |
| BC-BIZ-08 | Activity log on update | `activityLog($drv, 'Updated', [...])` | ctlr update:291-293 |
| BC-BIZ-09 | Soft delete (today outside range) | Scheduler rows deleted (soft) + main record soft-deleted | ctlr destroy:380-397 |
| BC-BIZ-10 | Soft delete (today within range) | BLOCKED → error 'Cannot delete. This assignment is active for today.' | ctlr destroy:368-378 |
| BC-BIZ-11 | Activity log on soft delete | `activityLog($drv, 'Deleted', [...])` | ctlr destroy:394-396 |
| BC-BIZ-12 | Restore | Main record restored + onlyTrashed scheduler restored | ctlr restore:429-438 |
| BC-BIZ-13 | Activity log on restore | `activityLog($drv, 'Restore', [...])` | ctlr restore:425-427 |
| BC-BIZ-14 | Force delete | Scheduler rows deleted (soft), main record force-deleted | ctlr forceDelete:457-475 |
| BC-BIZ-15 | Force delete requires onlyTrashed | Prevents deleting non-trashed records | ctlr forceDelete:458 |
| BC-BIZ-16 | Activity log on force delete | `activityLog($drv, 'ForceDelete', [...])` | ctlr forceDelete:460-462 |
| BC-BIZ-17 | Toggle status | `$model->is_active = !$model->is_active` + sync scheduler is_active | ctlr toggleStatus:486-493 |
| BC-BIZ-18 | Toggle success response | JSON `{success: true, is_active: bool, message: flash(...)}` | ctlr toggleStatus:501-505 |
| BC-BIZ-19 | Toggle failure response | JSON `{success: false, message: flash(...)}` | ctlr toggleStatus:508-511 |
| BC-BIZ-20 | FormRequest.authorize() | POST → `...create`; PUT/PATCH → `...update` | DriverRouteVehicleRequest.php:14-19 |
| BC-BIZ-21 | All methods use Gate::authorize() first | Gate check at start of every method | Throughout controller |
| BC-BIZ-22 | Tab filter `driverRouteVehicleQuery()` | Search + status + direct filters stacked | TripMgmtController.php:117-171 |
| BC-BIZ-23 | DDL trigger overlap prevention | MySQL trigger blocks overlapping inserts at DB level | DB Trigger |

### 5.5 BC-REL: Model Relationships — `DriverRouteVehicleJnt`

| BC ID | Relationship | Type | Foreign Key | Notes | Source |
|-------|-------------|------|-------------|-------|--------|
| BC-REL-01 | shift() | BelongsTo Shift | shift_id | | DriverRouteVehicleJnt.php:25-28 |
| BC-REL-02 | route() | BelongsTo Route | route_id | | DriverRouteVehicleJnt.php:30-33 |
| BC-REL-03 | vehicle() | BelongsTo Vehicle | vehicle_id | | DriverRouteVehicleJnt.php:35-38 |
| BC-REL-04 | driver() | BelongsTo DriverHelper | driver_id | | DriverRouteVehicleJnt.php:40-43 |
| BC-REL-05 | helper() | BelongsTo DriverHelper | helper_id | | DriverRouteVehicleJnt.php:45-48 |

### 5.6 BC-REF: Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) | Source |
|-------|-----------|------------------|----------------|--------|
| BC-REF-01 | shift_id | tpt_shift (id) | CASCADE | Migration |
| BC-REF-02 | route_id | tpt_route (id) | CASCADE | Migration |
| BC-REF-03 | vehicle_id | tpt_vehicle (id) | CASCADE | Migration |
| BC-REF-04 | driver_id | tpt_personnel (id) | CASCADE | Migration |
| BC-REF-05 | helper_id | tpt_personnel (id) | SET NULL | Migration |

### 5.7 BC-BIZ-DEEP: Deep Implementation Conditions

| BC-BIZ-DEEP ID | Condition | Expected Behavior | Source |
|----------------|-----------|-------------------|--------|
| BC-BIZ-DEEP-01 | Model table and fillable | `$table = 'tpt_driver_route_vehicle_jnt'`; 10 fillable fields | DriverRouteVehicleJnt.php:10-23 |
| BC-BIZ-DEEP-02 | Model has no custom casts | No `$casts` property; defaults to string for all fields | DriverRouteVehicleJnt.php |
| BC-BIZ-DEEP-03 | Soft deletes via BaseModel | BaseModel uses SoftDeletes; `deleted_at` column in migration | DriverRouteVehicleJnt.php:7 |
| BC-BIZ-DEEP-04 | store() uses DB::transaction | `DB::beginTransaction()` → try/catch → commit/rollback | ctlr store:99-201 |
| BC-BIZ-DEEP-05 | store() overlap check — 4 match conditions + date logic | shift_id, route_id, vehicle_id, driver_id, helper_id (or both NULL), pickup_drop; date: `existing.from <= new.to AND (existing.to IS NULL OR existing.to >= new.from)` | ctlr store:59-91 |
| BC-BIZ-DEEP-06 | store() helper null matching conditional | `$request->helper_id ? where('helper_id', id) : whereNull('helper_id')` | ctlr store:64-69 |
| BC-BIZ-DEEP-07 | store() expands pickup_drop types | `switch()`: 'Pickup'→['Pickup'], 'Drop'→['Drop'], 'Both'→['Pickup','Drop'] | ctlr store:124-134 |
| BC-BIZ-DEEP-08 | store() scheduler loop skips weekends (commented) | `// if ($currentDate->isWeekend()) { ... continue; }` — disabled | ctlr store:140-143 |
| BC-BIZ-DEEP-09 | store() checks scheduler existence before create | `->exists()` check; existing rows get `->update()` instead | ctlr store:147-179 |
| BC-BIZ-DEEP-10 | store() NULL effective_to → +10 years | `$endDate = $request->effective_to ? Carbon::parse(...) : Carbon::parse(...)->addYears(10)` | ctlr store:117-119 |
| BC-BIZ-DEEP-11 | create() loads only active dropdown data | `Route::active()->get()`, `Shift::active()->get()`, `Vehicle::active()->get()`, `DriverHelper::active()->get()` | ctlr create:37-40 |
| BC-BIZ-DEEP-12 | create() uses variable name `VehiclesData` (camelCase capital V) | `'VehiclesData' => Vehicle::active()->get()` — must match view | ctlr create:39 |
| BC-BIZ-DEEP-13 | edit() uses findOrFail | `DriverRouteVehicleJnt::findOrFail($id)` → 404 on missing | ctlr edit:213 |
| BC-BIZ-DEEP-14 | edit() loads full supporting data | Route/Shift/Vehicle/DriverHelper — all active; `VehiclesData` variable name | ctlr edit:214-217 |
| BC-BIZ-DEEP-15 | show() eager-loads ALL 5 relationships | `->with(['route','shift','vehicle','driver','helper'])` — helper IS loaded here | ctlr show:230-231 |
| BC-BIZ-DEEP-16 | update() overlap excludes current ID | `->where('id', '!=', $id)` prevents self-conflict | ctlr update:255 |
| BC-BIZ-DEEP-17 | update() overlap uses SIMPLER date logic than store() | `where('effective_from','<=', request.to)->where('effective_to','>=', request.from)` — no NULL handling | ctlr update:257-258 |
| BC-BIZ-DEEP-18 | update() force-deletes old scheduler | `TptRouteSchedulerJnt::withTrashed()->forceDelete()` — permanently removed | ctlr update:300-306 |
| BC-BIZ-DEEP-19 | update() uses upsert for rebuilt scheduler | `TptRouteSchedulerJnt::upsert($rows, [unique-by], [updateable])` | ctlr update:336-340 |
| BC-BIZ-DEEP-20 | **BUG** update() 'Both' NOT expanded in rebuild | Scheduler rows get `pickup_drop = $request->pickup_drop` directly ('Both' string), NOT ['Pickup','Drop'] | ctlr update:324 |
| BC-BIZ-DEEP-21 | update() uses `$request->boolean('is_active')` | Correct boolean parsing | ctlr update:288 |
| BC-BIZ-DEEP-22 | update() catches Throwable (not just Exception) | `catch (\Throwable $e)` — includes TypeErrors | ctlr update:348 |
| BC-BIZ-DEEP-23 | destroy() blocks if today in range | `$today >= effective_from && $today <= effective_to` — blocked | ctlr destroy:368-378 |
| BC-BIZ-DEEP-24 | destroy() scheduler scope: driver+vehicle+route | `TptRouteSchedulerJnt::where(driver_id,vehicle_id,route_id)->delete()` | ctlr destroy:383-387 |
| BC-BIZ-DEEP-25 | destroy() uses DB::transaction closure | `DB::transaction(function() use ($drv) { ... })` — auto commit/rollback | ctlr destroy:380-397 |
| BC-BIZ-DEEP-26 | destroy() soft-deletes scheduler (not force) | Uses `->delete()` not `->forceDelete()` on scheduler | ctlr destroy:383-387 |
| BC-BIZ-DEEP-27 | restore() uses manual beginTransaction/commit | `DB::beginTransaction()` + `DB::commit()` — not closure | ctlr restore:418,440 |
| BC-BIZ-DEEP-28 | restore() only restores trashed scheduler | `TptRouteSchedulerJnt::onlyTrashed()->where(shift_id,route_id,pickup_drop)->restore()` | ctlr restore:434-438 |
| BC-BIZ-DEEP-29 | **GAP** restore() scope does NOT include driver/vehicle | Restores by shift+route+pickup_drop only; mismatches destroy() scope (driver+vehicle+route) | ctlr restore:434-438 vs destroy:383-387 |
| BC-BIZ-DEEP-30 | forceDelete() uses onlyTrashed() | `DriverRouteVehicleJnt::onlyTrashed()->findOrFail($id)` — prevents deleting active | ctlr forceDelete:458 |
| BC-BIZ-DEEP-31 | forceDelete() logs activity BEFORE deletion | `activityLog()` at line 460 before `$drv->forceDelete()` at line 471 | ctlr forceDelete:460-471 |
| BC-BIZ-DEEP-32 | **BUG** toggleStatus() saves model TWICE | `$model->save()` at line 487 AND `if ($model->save())` at line 500 — redundant | ctlr toggleStatus:487,500 |
| BC-BIZ-DEEP-33 | toggleStatus() scheduler sync uses driver+vehicle+route | `TptRouteSchedulerJnt::where(driver_id,vehicle_id,route_id)->update(['is_active'=>$model->is_active])` | ctlr toggleStatus:490-493 |
| BC-BIZ-DEEP-34 | toggleStatus() flips is_active directly | `$model->is_active = !$model->is_active` — plain boolean flip | ctlr toggleStatus:486 |
| BC-BIZ-DEEP-35 | toggleStatus() route param is `{vehicle}` but controller uses `$id` | Route snippet vs method signature mismatch | routes line 125, ctlr:482 |
| BC-BIZ-DEEP-36 | trashed() paginates at 10 | `DriverRouteVehicleJnt::onlyTrashed()->paginate(10)` | ctlr trashed:408 |
| BC-BIZ-DEEP-37 | Tab query missing `helper` in eager load | `->with(['route','shift','vehicle','driver'])` — 4 rels, NO helper. N+1 if blade accesses helper->name | TripMgmtController.php:120 |
| BC-BIZ-DEEP-38 | Tab search crosses 3 related tables (OR) | `whereHas('route') OR whereHas('vehicle') OR whereHas('driver')` | TripMgmtController.php:132-143 |
| BC-BIZ-DEEP-39 | **GAP** Request: no `exists:tpt_personnel,id` for driver_id | `'driver_id' => ['required']` — any value accepted | DriverRouteVehicleRequest.php:46-48 |
| BC-BIZ-DEEP-40 | **GAP** Request: no `exists:tpt_personnel,id` for helper_id | `'helper_id' => ['nullable']` — any value accepted | DriverRouteVehicleRequest.php:50-52 |
| BC-BIZ-DEEP-41 | **GAP** pickup_drop not in request validation | Not in `rules()` array; only in model fillable; DB ENUM is last defense | DriverRouteVehicleRequest.php:25-69 |
| BC-BIZ-DEEP-42 | **GAP** total_students never set by controller | Field fillable in model (DEFAULT 0) but never set via form/controller | DriverRouteVehicleJnt.php:21 |
| BC-BIZ-DEEP-43 | **GAP** effective_to required in request but DDL allows NULL | Request: `required`; DDL: `DEFAULT NULL`; Controller handles NULL as +10 years but request prevents reaching controller | DriverRouteVehicleRequest.php:59-63 |
| BC-BIZ-DEEP-44 | **BUG** store() with pickup_drop='Both' crashes on main record | `pickup_drop` ENUM('Pickup','Drop') does NOT accept 'Both'. Controller passes `$request->pickup_drop` directly to create(). If user selects 'Both', DB INSERT fails with ENUM violation. | ctlr store:111 + Migration ENUM |
| BC-BIZ-DEEP-45 | Web.php defines resource + 4 extra routes | `Route::resource(...)` (7 routes) + trashed GET + restore GET + forceDelete DELETE + toggleStatus POST = 11 routes | routes/web.php:121-125 |
| BC-BIZ-DEEP-46 | Route names prefixed with `transport.` | `transport.driver-route-vehicle.index`, `.store`, `.update`, `.trashed`, etc. | routes/web.php:121-125 |
| BC-BIZ-DEEP-47 | Store redirects to `transport.trip-management.index` | NOT back to driver-route-vehicle index; goes to tab container | ctlr store:191 |
| BC-BIZ-DEEP-48 | Update redirects to `transport.trip-management.index` | Same redirect as store | ctlr update:344-346 |
| BC-BIZ-DEEP-49 | Destroy/restore/forceDelete redirect back | `return back()->with(...)` — previous page | ctlr destroy:399, restore:442, forceDelete:475 |
| BC-BIZ-DEEP-50 | Flash messages: store uses hardcoded string, others use flash() | Store: `'Driver Route Vehicle created successfully.'` (not translatable); others: `flash('key')` pattern | ctlr store:192 vs update:346, destroy:399 |
| BC-BIZ-DEEP-51 | destroy() scheduler scope is BROAD (may delete unrelated rows) | Deletes by driver_id+vehicle_id+route_id only — no shift_id/pickup_drop/helper_id filter | ctlr destroy:383-387 |
| BC-BIZ-DEEP-52 | forceDelete() scheduler scope same broad problem | Same scope as destroy: driver+vehicle+route only | ctlr forceDelete:465-468 |
| BC-BIZ-DEEP-53 | `driverRouteVehicleQuery()` lives in TripMgmtController NOT TransportMasterController | Private method in TripMgmtController.php:117; also duplicated in StudentRouteFeesController.php:423 | TripMgmtController.php:117 |
| BC-BIZ-DEEP-54 | ToggleStatus() has NO DB::transaction wrapping | Scheduler update not in transaction; partial failure → inconsistent state | ctlr toggleStatus:486-493 |
| BC-BIZ-DEEP-55 | forceDelete() has NO try/catch (unlike other methods) | `DB::beginTransaction()` but no try/catch block; exception propagates to Laravel handler | ctlr forceDelete:456-476 |
| BC-BIZ-DEEP-56 | update() logs activity BEFORE scheduler rebuild | `activityLog('Updated')` at line 291 before scheduler forceDelete at line 300. If rebuild fails, log is rolled back (transaction wraps both). | ctlr update:291,300 |
| BC-BIZ-DEEP-57 | store() scheduler update of existing rows only updates helper+is_active | Does NOT update shift_id, route_id, vehicle_id, driver_id on existing scheduler entries | ctlr store:174-178 |
| BC-BIZ-DEEP-58 | DDL trigger prevents race at DB level | `trg_driver_route_vehicle_unique_assignment` fires BEFORE INSERT; SIGNAL on overlap | DB Trigger |
| BC-BIZ-DEEP-59 | No `is_system_defined` guard in controller | Unlike some entities, all DriverVehRoster records are editable/deletable | Throughout controller |
| BC-BIZ-DEEP-60 | Model does NOT use `scopeActive()` | No `scopeActive` defined on model; queries rely on `is_active` column directly | DriverRouteVehicleJnt.php |

### 5.8 CODE-TRACE: Method Implementation Trace

| CT ID | Method | Lines | Code Flow |
|-------|--------|-------|-----------|
| CT-01 | index() | 23-28 | `Gate::authorize('...viewAny')` → `return view('transport::driver_route_vehicle.index')` — **NO data** → `Undefined variable` errors |
| CT-02 | create() | 33-42 | `Gate::authorize('...create')` → load 4 active datasets → `view('...create', [routes, shifts, VehiclesData, driverHelpers])` |
| CT-03 | store() | 47-202 | `Gate::authorize('...create')` → date range check → 4-condition overlap query → `DB::beginTransaction()` → `DriverRouteVehicleJnt::create([...])` → expand pickup_drop types → loop date range → check+create/update scheduler → `activityLog('Created')` → `DB::commit()` → redirect to trip-management.index |
| CT-04 | edit() | 209-219 | `Gate::authorize('...update')` → `findOrFail($id)` → load supporting data → `view('...edit', [...])` |
| CT-05 | show() | 227-234 | `Gate::authorize('...view')` → `with(['route','shift','vehicle','driver','helper'])->findOrFail($id)` → `view('...show', compact)` |
| CT-06 | update() | 239-352 | `Gate::authorize('...update')` → overlap check (exclude self) → `DB::beginTransaction()` → `$drv->update([...])` → `activityLog('Updated')` → `TptRouteSchedulerJnt::withTrashed()->forceDelete()` by shift/route/vehicle/driver/pickup_drop → rebuild via upsert → `DB::commit()` → redirect to trip-management.index |
| CT-07 | destroy() | 357-400 | `Gate::authorize('...delete')` → `findOrFail()` → check today in range → `DB::transaction(function(){...})`: delete scheduler by driver/vehicle/route → `$drv->delete()` → `activityLog('Deleted')` → redirect back |
| CT-08 | trashed() | 405-410 | `Gate::authorize('...restore')` → `onlyTrashed()->paginate(10)` → `view('...trash', compact)` |
| CT-09 | restore() | 415-448 | `Gate::authorize('...restore')` → `DB::beginTransaction()` → `onlyTrashed()->findOrFail()` → `$drv->restore()` → `activityLog('Restore')` → `TptRouteSchedulerJnt::onlyTrashed()->where(shift_id,route_id,pickup_drop)->restore()` → `DB::commit()` → redirect back |
| CT-10 | forceDelete() | 453-476 | `Gate::authorize('...forceDelete')` → `DB::beginTransaction()` → `onlyTrashed()->findOrFail()` → `activityLog('ForceDelete')` → scheduler delete by driver/vehicle/route → `$drv->forceDelete()` → `DB::commit()` → redirect back |
| CT-11 | toggleStatus() | 482-512 | `Gate::authorize('...update')` → `findOrFail()` → `$model->is_active = !$model->is_active` → `$model->save()` (1st) → scheduler update by driver/vehicle/route → `activityLog('Toggled')` → `$model->save()` (2nd, redundant) → JSON response |
| CT-12 | driverRouteVehicleQuery() | TM:117-171 | Private: `DriverRouteVehicleJnt::query()->with(['route','shift','vehicle','driver'])->orderByDesc('id')` → if `tab === 'driver_roster'` → search (OR across 3 relations) → status filter → direct filters loop → return query |
| CT-13 | FormRequest.authorize() | DRVR:14-19 | `if ($this->isMethod('POST'))` → `Gate::allows('...create')` else → `Gate::allows('...update')` |
| CT-14 | FormRequest.prepareForValidation() | DRVR:75-80 | `$this->merge(['is_active' => $this->boolean('is_active')])` — normalizes checkbox value to boolean |

---

## 6. Test Case List

### 6.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | Driver Route Vehicle Tab Loads Inside Trip Management | `/transport/trip-management?tab=driver_roster` loads with filter bar, table, Add/Trash buttons | — | — | ⬜ |
| TC-P01a | Standalone Index Page — **BROKEN** | `/driver-route-vehicle` throws `Undefined variable` — controller passes no data to view | — | — | ⬜ |
| TC-P02 | Create Roster With All Required Fields (Pickup) | POST with shift/route/vehicle/driver/from/to/is_active/pickup_drop=Pickup → record + 7 scheduler entries | — | — | ⬜ |
| TC-P03 | Create Roster With Both Pickup/Drop | pickup_drop=Both → 2 scheduler entries per day (Pickup+Drop) | — | — | ⬜ |
| TC-P04 | Create Roster With Helper | Helper assigned to record and all scheduler entries | — | — | ⬜ |
| TC-P05 | Create Roster With NULL effective_to (bypass required) | Scheduler generated for 10 years ✅ needs API call (FormRequest requires effective_to) | — | — | ⬜ |
| TC-P06 | View Roster Details | `/driver-route-vehicle/{id}` shows all fields with relationships | — | — | ⬜ |
| TC-P07 | Edit Roster Loads Pre-Filled Data | `/driver-route-vehicle/{id}/edit` shows existing values in form | — | — | ⬜ |
| TC-P08 | Update Roster — Change Dates | PUT → effective range updated; old scheduler rebuilt; activity log created | — | — | ⬜ |
| TC-P09 | Update Roster — Change Driver Assignment | Old scheduler force-deleted; new scheduler rebuilt with new driver | — | — | ⬜ |
| TC-P10 | Soft Delete Roster (Today Outside Range) | DELETE → scheduler rows soft-deleted; main record soft-deleted | — | — | ⬜ |
| TC-P11 | Trash Page Shows Deleted Rosters | `/driver-route-vehicle/trash/view` → list with Restore and Force Delete | — | — | ⬜ |
| TC-P12 | Restore Roster From Trash | GET restore → main + scheduler restored | — | — | ⬜ |
| TC-P13 | Force Delete Roster | DELETE force-delete → permanently removed | — | — | ⬜ |
| TC-P14 | Toggle Status Active → Inactive | POST toggle-status → is_active flipped; scheduler synced; JSON response | — | — | ⬜ |
| TC-P15 | Full Lifecycle | Create → View → Edit → Toggle → Delete → Trash → Restore → Force Delete | — | — | ⬜ |
| TC-P16 | Filter by Search (Route) | Search route name → matching records | — | — | ⬜ |
| TC-P17 | Filter by Search (Vehicle) | Search vehicle reg_no → matching records | — | — | ⬜ |
| TC-P18 | Filter by Shift | Select shift → filtered | — | — | ⬜ |
| TC-P19 | Filter by Status | Active/Inactive filter | — | — | ⬜ |
| TC-P20 | Empty State — No Rosters | "No Data Found" displayed | — | — | ⬜ |
| TC-P21 | Empty State — No Trashed Rosters | Trash shows "No Data Found" | — | — | ⬜ |
| TC-P22 | Pagination — Records Exceed First Page | 11+ records → pagination links | — | — | ⬜ |
| TC-P23 | Scheduler Auto-Creation Verify | 3-day range → 3 scheduler rows in tpt_route_scheduler_jnt | — | — | ⬜ |
| TC-P24 | Activity Log — Create | Event `Created` with specific message | — | — | ⬜ |
| TC-P25 | Activity Log — Update | Event `Updated` | — | — | ⬜ |
| TC-P26 | Activity Log — Soft Delete | Event `Deleted` | — | — | ⬜ |
| TC-P27 | Activity Log — Restore | Event `Restore` | — | — | ⬜ |
| TC-P28 | Activity Log — Force Delete | Event `ForceDelete` | — | — | ⬜ |
| TC-P29 | Activity Log — Toggle Status | Event `Toggled` | — | — | ⬜ |

### 6.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | Required — Missing shift_id | Validation error | — | — | ⬜ |
| TC-N02 | Required — Missing route_id | Validation error | — | — | ⬜ |
| TC-N03 | Required — Missing vehicle_id | Validation error | — | — | ⬜ |
| TC-N04 | Required — Missing driver_id | Validation error | — | — | ⬜ |
| TC-N05 | Required — Missing effective_from | Validation error | — | — | ⬜ |
| TC-N06 | Required — Missing effective_to | Validation error | — | — | ⬜ |
| TC-N07 | Invalid Date Range — effective_to before effective_from | `after_or_equal` validation error | — | — | ⬜ |
| TC-N08 | Invalid shift_id — Non-existent | `exists` validation error | — | — | ⬜ |
| TC-N09 | Invalid route_id — Non-existent | `exists` validation error | — | — | ⬜ |
| TC-N10 | Invalid vehicle_id — Non-existent | `exists` validation error | — | — | ⬜ |
| TC-N11 | Date Overlap — Same shift/route/vehicle/driver overlapping dates | Controller 'already assigned' error | — | — | ⬜ |
| TC-N12 | Delete Roster Active Today | `destroy()` blocked when today within range | — | — | ⬜ |
| TC-N13 | View With Invalid ID (99999) | 404 via findOrFail | — | — | ⬜ |
| TC-N14 | Edit With Invalid ID (99999) | 404 via findOrFail | — | — | ⬜ |
| TC-N15 | Update With Invalid ID (99999) | 404 via findOrFail | — | — | ⬜ |
| TC-N16 | Delete With Invalid ID (99999) | 404 via findOrFail | — | — | ⬜ |
| TC-N17 | Restore Non-Deleted Record | `onlyTrashed()->findOrFail()` → 404 | — | — | ⬜ |
| TC-N18 | Force Delete Non-Trashed Record | `onlyTrashed()->findOrFail()` → 404 | — | — | ⬜ |
| TC-N19 | Toggle Status With Invalid ID | findOrFail → 404 | — | — | ⬜ |
| TC-N20 | Permission 403 — No Permissions | 403 on all CRUD endpoints | — | — | ⬜ |
| TC-N21 | Guest Access Redirect | All URLs redirect to `/login` | — | — | ⬜ |
| TC-N22 | XSS Injection In Fields | `<script>` stored literal; Blade escapes output | — | — | ⬜ |
| TC-N23 | Duplicate DDL Trigger (Race Condition) | Bypass controller validation → MySQL trigger SIGNAL | — | — | ⬜ |
| TC-N24 | Permission Denied — viewAny | 403 on index; tab hidden | — | — | ⬜ |
| TC-N25 | Permission Denied — view | 403 on show | — | — | ⬜ |
| TC-N26 | Permission Denied — create | 403 on create/store | — | — | ⬜ |
| TC-N27 | Permission Denied — update | 403 on edit/update/toggleStatus | — | — | ⬜ |
| TC-N28 | Permission Denied — delete | 403 on destroy | — | — | ⬜ |
| TC-N29 | Permission Denied — restore | 403 on trashed/restore | — | — | ⬜ |
| TC-N30 | Permission Denied — forceDelete | 403 on forceDelete | — | — | ⬜ |
| TC-N31 | Invalid pickup_drop value ("InvalidValue") | Request passes (no validation) → DB ENUM violation | — | — | ⬜ |
| TC-N32 | Invalid helper_id (99999, non-existent) | Request passes (nullable, no exists) → FK violation | — | — | ⬜ |
| TC-N33 | Invalid driver_id (99999, non-existent) | Request passes (required, no exists) → FK violation | — | — | ⬜ |
| TC-N34 | **BUG** Create with pickup_drop='Both' | ENUM('Pickup','Drop') rejects 'Both' → DB error 500 | — | — | ⬜ |

### 6.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|----------------|---------|---------|--------|
| TC-D01 | A | Soft-Delete → Scheduler Cascade | Related scheduler rows also soft-deleted | — | — | ⬜ |
| TC-D02 | B | Restore → Scheduler Also Restored | Related scheduler restored via onlyTrashed()->restore() | — | — | ⬜ |
| TC-D03 | C | Route Deletion Cascades to Roster | DDL CASCADE on route_id FK | — | — | ⬜ |
| TC-D04 | C | Vehicle Deletion Cascades to Roster | DDL CASCADE on vehicle_id FK | — | — | ⬜ |
| TC-D05 | D | Shift Deletion Cascades to Roster | DDL CASCADE on shift_id FK | — | — | ⬜ |
| TC-D06 | E | Driver (Personnel) Deletion → Helper SET NULL | DDL SET NULL on helper_id | — | — | ⬜ |
| TC-D07 | F | Update effective range — Old scheduler replaced | Old force-deleted; new upserted | — | — | ⬜ |
| TC-D08 | G | Concurrent Create — Two Users Same Assignment | DDL trigger blocks second insert | — | — | ⬜ |
| TC-D09 | H | Driver Deletion Cascades to Roster | DDL CASCADE on driver_id FK | — | — | ⬜ |

### 6.4 Code Review Test Cases

| TC ID | Priority | Description | Expected Result | V1 | V2 | Status |
|-------|----------|-------------|-----------------|----|----|--------|
| TC-CR01 | P1 | Gate::authorize() Before Every State Change | Every method has Gate check as first line | — | — | ◌ |
| TC-CR02 | P1 | activityLog After Every CRUD | All 6 CRUD events logged (Created, Updated, Deleted, Restore, ForceDelete, Toggled) | — | — | ◌ |
| TC-CR03 | P1 | Date Overlap in store() — 4 conditions + date logic | Complex overlap query with effective_from/effective_to | — | — | ◌ |
| TC-CR04 | P1 | Date Overlap in update() with `id != $id` | Excludes current record; simpler date logic (no NULL handling) | — | — | ◌ |
| TC-CR05 | P1 | DB::transaction for store/update/destroy/restore/forceDelete | Consistent transactional boundaries (5 of 6 state-change methods) | — | — | ◌ |
| TC-CR06 | P1 | Scheduler Auto-generation on store() | Daily loop; Pickup/Drop/Both handled; existence check before create | — | — | ◌ |
| TC-CR07 | P1 | Scheduler forceDelete on update() | `withTrashed()->forceDelete()` then upsert | — | — | ◌ |
| TC-CR08 | P1 | destroy() blocks active assignments | `$today >= from && $today <= to` → blocked | — | — | ◌ |
| TC-CR09 | P1 | restore() restores scheduler from onlyTrashed | `TptRouteSchedulerJnt::onlyTrashed()->where(...)->restore()` | — | — | ◌ |
| TC-CR10 | P1 | forceDelete() uses onlyTrashed() | Prevents deleting non-trashed | — | — | ◌ |
| TC-CR11 | P1 | toggleStatus() syncs scheduler is_active | Updates all scheduler for same driver/vehicle/route | — | — | ◌ |
| TC-CR12 | P1 | FormRequest.authorize() matches controller gates | POST→create; PUT/PATCH→update | — | — | ◌ |
| TC-CR13 | P1 | Request Validation Rules | 7 field rules present | — | — | ◌ |
| TC-CR14 | P1 | **GAP** pickup_drop not validated in request | Not in rules() — any value passes | — | — | ◌ |
| TC-CR15 | P1 | Model Table Name | `$table = 'tpt_driver_route_vehicle_jnt'` | — | — | ◌ |
| TC-CR16 | P1 | Model Fillable Matches DB | 10 fields match DB columns | — | — | ◌ |
| TC-CR17 | P1 | Model Relationships Defined | 5 BelongsTo relationships | — | — | ◌ |
| TC-CR18 | P1 | Routes — Resource + Additional | 11 routes total | — | — | ◌ |
| TC-CR19 | P1 | DDL Trigger Exists | `trg_driver_route_vehicle_unique_assignment` | — | — | ◌ |
| TC-CR20 | P1 | Foreign Keys With CASCADE/SET NULL | 5 FKs correct | — | — | ◌ |
| TC-CR21 | P1 | **GAP** total_students not validated | Field exists in DB/fillable but never set by code | — | — | ◌ |
| TC-CR22 | P1 | **GAP** effective_to required in request but DDL allows NULL | Request prevents NULL from reaching controller | — | — | ◌ |
| TC-CR23 | P1 | **GAP** driver_id/helper_id no exists check | Any value accepted; FK constraint at DB level | — | — | ◌ |
| TC-CR24 | P1 | Tab query filters correct | Search + status + direct filters stack correctly | — | — | ◌ |
| TC-CR25 | P1 | **BUG** Blade-Controller mismatch — edit permission | View uses edit, controller uses update | — | — | ◌ |
| TC-CR26 | P1 | **BUG** Blade-Controller mismatch — status permission | View uses status, controller uses update | — | — | ◌ |
| TC-CR27 | P2 | **BUG** Update 'Both' not expanded into Pickup+Drop | Rebuild scheduler with `pickup_drop=$request->pickup_drop` directly | — | — | ◌ |
| TC-CR28 | P2 | **GAP** helper not eager-loaded in tab query | Missing 'helper' in with() → N+1 risk | — | — | ◌ |
| TC-CR29 | P1 | **BUG** Standalone index() returns view with no data | No variables passed to view → Undefined variable | — | — | ◌ |
| TC-CR30 | P2 | **GAP** transport::index includes partial without data | View includes partial without passing required variables | — | — | ◌ |
| TC-CR31 | P1 | **BUG** toggleStatus saves model TWICE | `$model->save()` called twice | — | — | ◌ |
| TC-CR32 | P2 | **GAP** restore() scheduler scope mismatches destroy() scope | Destroy by driver/vehicle/route; Restore by shift/route/pickup_drop | — | — | ◌ |
| TC-CR33 | P2 | **GAP** toggleStatus() no transaction wrapping | Scheduler update not in transaction | — | — | ◌ |
| TC-CR34 | P2 | **GAP** forceDelete() missing try/catch | No exception handling | — | — | ◌ |
| TC-CR35 | P2 | **GAP** 'Both' ENUM crash on store() | ENUM('Pickup','Drop') rejects 'Both' → DB error | — | — | ◌ |

---

## 7. Detailed Test Steps

### TC-P02: Create Roster With All Required Fields (Pickup)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.driver-route-vehicle.create` | Success |
| 2 | Navigate to Trip Management → Driver Route Vehicle tab | Tab loaded via TripMgmtController@index |
| 3 | Click "Add" button | GET `/driver-route-vehicle/create` |
| 4 | Verify Gate::authorize at ctlr line 35 | Authorized |
| 5 | View receives `$routes`, `$shifts`, `$VehiclesData`, `$driverHelpers` (all active) | Supporting data loaded |
| 6 | Select shift from dropdown | shift_id set |
| 7 | Select route from dropdown | route_id set |
| 8 | Select vehicle from dropdown | vehicle_id set |
| 9 | Select driver from dropdown | driver_id set |
| 10 | Leave helper as "None" | helper_id = null |
| 11 | Enter effective_from: today | Date set |
| 12 | Enter effective_to: today + 7 days | Date set |
| 13 | Select pickup_drop = "Pickup" | pickup_drop = "Pickup" |
| 14 | Status toggle ON | is_active = true |
| 15 | Click Save | POST `/driver-route-vehicle` |
| 16 | Verify Gate::authorize at ctlr line 49 | Authorized |
| 17 | FormRequest rules pass (DriverRouteVehicleRequest.php:30-69) | All required + exists OK |
| 18 | prepareForValidation normalizes is_active | boolean(true) |
| 19 | Date range check line 52: from(2026-01-01) <= to(2026-01-08) | Passes |
| 20 | Overlap query lines 59-91: $exists = false | No conflict |
| 21 | DB::beginTransaction() at line 99 | Started |
| 22 | DriverRouteVehicleJnt::create([...]) lines 103-113 | Record created |
| 23 | Verify pickup_drop stored as "Pickup" (NOT 'Both') | ENUM('Pickup','Drop') accepts |
| 24 | is_active = `$request->is_active ? 1 : 0` = 1 | Active |
| 25 | Scheduler start = Carbon::parse(effective_from) | Start = today |
| 26 | Scheduler end = Carbon::parse(effective_to) | End = today + 7 |
| 27 | pickupDropTypes = ['Pickup'] (switch case) | Single type |
| 28 | While loop: 7 iterations (8 - 1 dates) | Each date processed |
| 29 | Existence check per date: `->exists()` = false | New entries |
| 30 | TptRouteSchedulerJnt::create() per date | 7 scheduler rows |
| 31 | activityLog($driverRoute, 'Created', [...]) | Logged |
| 32 | DB::commit() at line 189 | Committed |
| 33 | Redirect to route('transport.trip-management.index') | Success |
| 34 | DB: SELECT * FROM tpt_driver_route_vehicle_jnt WHERE ... | Record present |
| 35 | Scheduler: SELECT COUNT(*) FROM tpt_route_scheduler_jnt WHERE ... | 7 rows |
| 36 | Activity log: event `Created` | Log entry exists |

### TC-P03: Create With Both Pickup/Drop

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Follow TC-P02 steps 1-14 with pickup_drop="Both", 3-day range | Form filled |
| 2 | Verify switch(case 'Both') → `$pickupDropTypes = ['Pickup', 'Drop']` | Two types |
| 3 | While loop: 3 days × 2 types = 6 scheduler rows | 6 entries |
| 4 | DB: 3 Pickup rows + 3 Drop rows | Each date has both |
| 5 | **BUG CHECK**: If ENUM('Pickup','Drop') rejects 'Both' at main record insert → 500 error | Main record insert fails at line 111! |

### TC-P04: Create Roster With Helper

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Follow TC-P02 with additional helper selection | Helper_id set |
| 2 | Controller line 108: `'helper_id' => $request->helper_id` | Helper stored |
| 3 | Scheduler rows also contain helper_id | All entries have helper |
| 4 | DB: SELECT helper_id FROM main record | Helper ID matches |
| 5 | DB: SELECT DISTINCT helper_id FROM scheduler | Same helper across all rows |

### TC-P06: View Roster Details

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click View icon on roster | GET `/driver-route-vehicle/{id}` |
| 2 | Gate::authorize('...view') line 229 | Authorized |
| 3 | `with(['route','shift','vehicle','driver','helper'])->findOrFail($id)` | All 5 relationships loaded |
| 4 | View displays: Shift, Route, Vehicle, Driver, Helper, Eff From/To, Pickup/Drop, Status | All fields |

### TC-P07: Edit Roster Loads Pre-Filled Data

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click Edit icon | GET `/driver-route-vehicle/{id}/edit` |
| 2 | Gate::authorize('...update') line 211 | Authorized |
| 3 | findOrFail($id) line 213 | Existing record loaded |
| 4 | Supporting data: all active entities | Dropdowns populated |
| 5 | Form fields pre-filled with current values | Shift, Route, Vehicle, Driver, Helper, dates, pickup_drop, status match |
| 6 | Form action = route('transport.driver-route-vehicle.update') | PUT method |

### TC-P08: Update Roster — Change Dates

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Edit existing roster, shift effective_from +1 day | Dates changed |
| 2 | Click Save | PUT `/driver-route-vehicle/{id}` |
| 3 | Gate check line 241 | Authorized |
| 4 | FormRequest rules pass | Validation OK |
| 5 | Overlap check with `where('id', '!=', $id)` line 255 | Self excluded |
| 6 | DB::beginTransaction() line 268 | Started |
| 7 | findOrFail($id) line 277 | Found |
| 8 | $drv->update([...]) with boolean('is_active') | Main record updated |
| 9 | activityLog('Updated') line 291 | Logged |
| 10 | withTrashed()->forceDelete() lines 300-306 | Old scheduler permanently removed |
| 11 | Rebuild loop: new effective_from to new effective_to | New scheduler rows |
| 12 | upsert($rows, unique-by, updateable) lines 336-340 | Bulk insert |
| 13 | DB::commit() line 342 | Committed |
| 14 | DB: main record dates updated | Changed |
| 15 | Scheduler: old dates gone, new dates present | Replaced |

### TC-P10: Soft Delete (Today Outside Range)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Find roster with effective range ending yesterday | Today outside range |
| 2 | Click Delete icon | Confirm dialog |
| 3 | Confirm | DELETE `/driver-route-vehicle/{id}` |
| 4 | Gate::authorize('...delete') line 359 | Authorized |
| 5 | findOrFail($id) line 361 | Found |
| 6 | `$today >= from && $today <= to` = false | Not blocked |
| 7 | DB::transaction(function(){...}) line 380 | Closure |
| 8 | Scheduler delete(driver_id,vehicle_id,route_id) lines 383-387 | Scheduler soft-deleted |
| 9 | $drv->delete() line 392 | Main soft-deleted |
| 10 | activityLog('Deleted') line 394 | Logged |
| 11 | Redirect back with success flash | Done |
| 12 | DB: deleted_at NOT NULL on main record | Soft-deleted |
| 13 | DB: deleted_at NOT NULL on scheduler rows | Cascaded |

### TC-P12: Restore Roster From Trash

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | In trash, click Restore | GET `/driver-route-vehicle/{id}/restore` |
| 2 | Gate::authorize('...restore') line 417 | Authorized |
| 3 | DB::beginTransaction() line 418 | Started |
| 4 | onlyTrashed()->findOrFail($id) line 422 | Found in trash |
| 5 | $drv->restore() line 423 | deleted_at = NULL |
| 6 | activityLog('Restore') line 425 | Logged |
| 7 | onlyTrashed()->where(shift_id,route_id,pickup_drop)->restore() lines 434-438 | Scheduler restored |
| 8 | DB::commit() line 440 | Committed |
| 9 | DB: main record deleted_at = NULL | Restored |
| 10 | DB: scheduler rows deleted_at = NULL | Restored |

### TC-P13: Force Delete Roster

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Roster must be soft-deleted first (in trash) | deleted_at NOT NULL |
| 2 | Click "Force Delete" | DELETE `/driver-route-vehicle/{id}/force-delete` |
| 3 | Gate::authorize('...forceDelete') line 455 | Authorized |
| 4 | DB::beginTransaction() line 456 | Started |
| 5 | onlyTrashed()->findOrFail($id) line 458 | Found |
| 6 | activityLog('ForceDelete') line 460 | Logged BEFORE deletion |
| 7 | Scheduler delete(driver_id,vehicle_id,route_id) lines 465-468 | Scheduler deleted |
| 8 | $drv->forceDelete() line 471 | Permanently removed |
| 9 | DB::commit() line 473 | Committed |
| 10 | DB: SELECT * FROM main WHERE id=X | 0 rows (gone) |

### TC-P14: Toggle Status

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Find active roster | is_active=1 |
| 2 | Click toggle switch | POST `/driver-route-vehicle/{id}/toggle-status` |
| 3 | Gate::authorize('...update') line 484 | Authorized |
| 4 | findOrFail($id) line 485 | Found |
| 5 | `$model->is_active = !$model->is_active` → false | Flipped |
| 6 | `$model->save()` (1st) at line 487 | DB updated to is_active=0 |
| 7 | Scheduler update(driver_id,vehicle_id,route_id) lines 490-493 | All scheduler entries synced to inactive |
| 8 | activityLog('Toggled') line 495 | Logged |
| 9 | `$model->save()` (2nd, redundant) line 500 | Returns true (no changes) |
| 10 | JSON response: `{success:true, is_active:false, message:flash(...)}` | 200 OK |
| 11 | DB: main is_active = 0 | Inactive |
| 12 | DB: scheduler is_active = 0 (all rows) | Synced |

### TC-N11: Date Overlap

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create: shift=X, route=Y, vehicle=Z, driver=W, helper=NULL, pickup='Pickup', from=2026-01-01, to=2026-01-31 | Created |
| 2 | Create same combo with from=2026-01-15, to=2026-02-15 | Overlap: existing.from(01-01) <= new.to(02-15) AND existing.to(01-31) >= new.from(01-15) → $exists=true → error |
| 3 | Create same combo with from=2025-12-01, to=2025-12-15 | existing.from(01-01) <= new.to(12-15)? NO → $exists=false → created |
| 4 | Create same combo but different pickup_drop='Drop' | Different pickup_drop → $exists=false → created (shift/route/vehicle/driver same, different type allowed) |

### TC-N12: Delete Active Today

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure roster with from<=today<=to | Active today |
| 2 | DELETE this roster | Controller hit |
| 3 | `$today >= $drv->effective_from && $today <= $drv->effective_to` = true | BLOCKED |
| 4 | Error message: 'Cannot delete. This assignment is active for today.' | Returned |
| 5 | DB: deleted_at still NULL | Not deleted |

### TC-N34: BUG — Create with pickup_drop='Both' ENUM crash

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit POST with pickup_drop="Both" | Request passes (no pickup_drop validation) |
| 2 | Controller line 111: `'pickup_drop' => $request->pickup_drop` | Tries to insert 'Both' into ENUM('Pickup','Drop') |
| 3 | **DB INSERT fails**: `Data truncated for column 'pickup_drop'` (strict mode) or ENUM violation | 500 error |
| 4 | DB::rollBack() at line 194 | Transaction rolled back |
| 5 | Error logged: 'DriverRouteVehicle Store Error: ...' | Logged |
| 6 | **Severity**: CRITICAL — 'Both' option in form causes 500 error on save | Cannot create roster with Both via normal UI |

### TC-CR25: BUG — Blade-Controller Permission Mismatch (edit)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User with `update` but NOT `edit` | Login |
| 2 | Blade `@can('tenant.driver-route-vehicle.edit')` = false | Edit button HIDDEN |
| 3 | Navigate directly to `/driver-route-vehicle/{id}/edit` | Controller `Gate::authorize('...update')` PASSES |
| 4 | **Bug**: Button hidden but URL accessible | UI/UX inconsistency |
| 5 | User with `edit` but NOT `update` | Login |
| 6 | Blade `@can('...edit')` = true | Edit button VISIBLE |
| 7 | Click Edit → controller `Gate::authorize('...update')` FAILS | 403 error |
| 8 | **Bug**: Button visible but click leads to 403 | User confusion |

### TC-CR27: BUG — Update 'Both' Not Expanded

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create roster with pickup_drop='Both' ✅ (via bypass or fixed code) | Scheduler has Pickup+Drop per day |
| 2 | Edit roster, keep pickup_drop='Both', click Save | PUT request |
| 3 | Old scheduler force-deleted lines 300-306 | Old rows removed |
| 4 | Rebuild loop: `'pickup_drop' => $request->pickup_drop` = 'Both' | Single value 'Both', NOT expanded |
| 5 | If scheduler ENUM restricts to 'Pickup'/'Drop' → DB error | 500 error |
| 6 | If scheduler accepts 'Both' → wrong data | Scheduler has 'Both' type (invalid) |
| 7 | **Bug**: update() does NOT expand 'Both' into ['Pickup','Drop'] like store() does | Data inconsistency |

### TC-CR31: BUG — toggleStatus Double Save

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open toggleStatus() at line 482 | Method body |
| 2 | Line 487: `$model->save()` — 1st save | Persists is_active change |
| 3 | Lines 490-493: scheduler sync | Separate operation |
| 4 | Line 500: `if ($model->save())` — 2nd save | Redundant, no changes, always returns true |

### TC-CR32: GAP — Restore/Destroy Scope Mismatch

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create roster: shift=S1, route=R1, vehicle=V1, driver=D1, pickup='Pickup' | Record |
| 2 | Destroy: scheduler deleted by `driver=D1, vehicle=V1, route=R1` | Broad scope |
| 3 | Restore: scheduler restored by `shift=S1, route=R1, pickup='Pickup'` | Different scope |
| 4 | **Gap**: If another roster shared same driver/vehicle/route with different shift → destroy picks it up, restore doesn't | Scheduler rows left trashed |

### TC-D01: Soft-Delete Scheduler Cascade

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create roster with 3-day range | 3 scheduler rows |
| 2 | Delete roster | destroy() |
| 3 | Scheduler: all 3 rows have deleted_at NOT NULL | Cascaded |
| 4 | Main record: deleted_at NOT NULL | Soft-deleted |

### TC-D03: Route Deletion Cascade

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create roster with route_id=R1 | FK references route |
| 2 | DELETE FROM tpt_route WHERE id=R1 | Cascade |
| 3 | Roster auto-deleted (CASCADE) | 0 rows for route_id=R1 |

### TC-D06: Helper SET NULL

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create roster with helper_id=H1 | Helper assigned |
| 2 | DELETE FROM tpt_personnel WHERE id=H1 | SET NULL |
| 3 | DB: helper_id = NULL on roster | SET NULL behavior |

### TC-P22: Pagination

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure 12+ roster records | >10 rows |
| 2 | Navigate to roster tab | First page: 10 records |
| 3 | Pagination links visible | `->paginate(10)->withQueryString()` |
| 4 | Click page 2 | Remaining records |

### TC-P23: Scheduler Auto-Creation Verify

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create: from=2026-01-01, to=2026-01-03 | 3-day range |
| 2 | SELECT COUNT(*) FROM tpt_route_scheduler_jnt WHERE driver=X, shift=Y, route=Z | 3 rows |
| 3 | Dates: 2026-01-01, 2026-01-02, 2026-01-03 | Correct range |
| 4 | All scheduler fields match main record | shift_id, route_id, vehicle_id, driver_id, helper_id, is_active same |

### TC-CR01: Gate::authorize() Before Every Method

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | index line 25 | `Gate::authorize('...viewAny')` |
| 2 | create line 35 | `Gate::authorize('...create')` |
| 3 | store line 49 | `Gate::authorize('...create')` |
| 4 | show line 229 | `Gate::authorize('...view')` |
| 5 | edit line 211 | `Gate::authorize('...update')` |
| 6 | update line 241 | `Gate::authorize('...update')` |
| 7 | destroy line 359 | `Gate::authorize('...delete')` |
| 8 | trashed line 407 | `Gate::authorize('...restore')` |
| 9 | restore line 417 | `Gate::authorize('...restore')` |
| 10 | forceDelete line 455 | `Gate::authorize('...forceDelete')` |
| 11 | toggleStatus line 484 | `Gate::authorize('...update')` |
| 12 | All 11 methods have Gate as first executable line | Consistent |

### TC-CR03: Date Overlap Query in store()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Match shift_id | `where('shift_id', ...)` |
| 2 | Match route_id | `where('route_id', ...)` |
| 3 | Match vehicle_id | `where('vehicle_id', ...)` |
| 4 | Match driver_id | `where('driver_id', ...)` |
| 5 | Match helper_id (same or both NULL) | Conditional null handling |
| 6 | Match pickup_drop | Exact match |
| 7 | Date overlap Case 1 (new has end): `existing.from <= new.to AND (existing.to IS NULL OR existing.to >= new.from)` | Covers all overlap scenarios |
| 8 | Date overlap Case 2 (new no end): `existing.to IS NULL OR existing.to >= new.from` | Handles open-ended |

### TC-CR06: Scheduler Auto-generation Code Path

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | $startDate = Carbon::parse(effective_from) | Start |
| 2 | $endDate = effective_to OR effective_from + 10 years | Handles NULL |
| 3 | $pickupDropTypes switch: Pickup/Drop/Both | 1 or 2 types |
| 4 | while($currentDate->lte($endDate)) | Daily iteration |
| 5 | foreach($pickupDropTypes as $type) | Per type |
| 6 | Existence check: `->exists()` | Prevents duplicates |
| 7 | If exists: `->update([helper_id, is_active])` | Updates existing |
| 8 | If not exists: `TptRouteSchedulerJnt::create([...])` | Creates new |
| 9 | $currentDate->addDay() | Increment |

### TC-BIZ-DEEP-32: toggleStatus Double Save Verification

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Line 486: `$model->is_active = !$model->is_active` | is_active flipped |
| 2 | Line 487: `$model->save()` — saves false | DB updated, returns true |
| 3 | Lines 490-493: scheduler update | Executes |
| 4 | Line 500: `if ($model->save())` — no changes → Eloquent save() returns true (no changes detected, still returns true) | Always true |
| 5 | **Impact**: No functional harm, just unnecessary DB write | Minor code smell |

### TC-BIZ-DEEP-44: 'Both' ENUM Crash Test

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check DB: `SHOW COLUMNS FROM tpt_driver_route_vehicle_jnt LIKE 'pickup_drop'` | ENUM('Pickup','Drop') — NO 'Both' |
| 2 | Check controller line 111: `'pickup_drop' => $request->pickup_drop` | Passes raw value |
| 3 | POST with pickup_drop='Both' | Request passes (no validation) |
| 4 | INSERT tries 'Both' into ENUM('Pickup','Drop') | **DB ERROR**: Data too long / Illegal enum value |
| 5 | **Severity**: P1 bug — blocks core feature | 'Both' option unusable via normal flow |

### TC-CR19: DDL Trigger Verification

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `SHOW TRIGGERS WHERE` Table = 'tpt_driver_route_vehicle_jnt' | Trigger `trg_driver_route_vehicle_unique_assignment` exists |
| 2 | Timing: BEFORE INSERT | Pre-insert validation |
| 3 | Action: SIGNAL SQLSTATE '45000' | Error on overlap |
| 4 | Purpose: Race condition prevention | DB-level enforcement |

### TC-P15: Full Lifecycle Test

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create roster (TC-P02) | Record created + scheduler |
| 2 | View details (TC-P06) | All fields visible |
| 3 | Edit — change shift (TC-P08) | Updated, scheduler rebuilt |
| 4 | Toggle off (TC-P14) | Inactive, scheduler synced |
| 5 | Soft delete (TC-P10) | In trash |
| 6 | View trash (TC-P11) | Visible in trash |
| 7 | Restore (TC-P12) | Restored |
| 8 | Soft delete again | Back in trash |
| 9 | Force delete (TC-P13) | Permanently gone |
| 10 | Verify: `withTrashed()` finds nothing | No trace |

### TC-N20: Permission 403 Suite

| Step # | URL / Action | Expected |
|--------|-------------|----------|
| 1 | GET `/driver-route-vehicle` | 403 (viewAny) |
| 2 | GET `/driver-route-vehicle/create` | 403 (create) |
| 3 | POST `/driver-route-vehicle` | 403 (create) |
| 4 | GET `/driver-route-vehicle/{id}` | 403 (view) |
| 5 | GET `/driver-route-vehicle/{id}/edit` | 403 (update) |
| 6 | PUT `/driver-route-vehicle/{id}` | 403 (update) |
| 7 | DELETE `/driver-route-vehicle/{id}` | 403 (delete) |
| 8 | GET `/driver-route-vehicle/trash/view` | 403 (restore) |
| 9 | GET `/driver-route-vehicle/{id}/restore` | 403 (restore) |
| 10 | DELETE `/driver-route-vehicle/{id}/force-delete` | 403 (forceDelete) |
| 11 | POST `/driver-route-vehicle/{id}/toggle-status` | 403 (update) |

### TC-CR05: DB::transaction for State Changes

| Step # | Method | Transaction Pattern |
|--------|--------|-------------------|
| 1 | store() line 99 | `DB::beginTransaction()` → try/catch → commit/rollback |
| 2 | update() line 268 | `DB::beginTransaction()` → try/catch → commit/rollback |
| 3 | destroy() line 380 | `DB::transaction(function(){...})` closure |
| 4 | restore() line 418 | `DB::beginTransaction()` → try/catch → commit/rollback |
| 5 | forceDelete() line 456 | `DB::beginTransaction()` → NO try/catch → commit |
| 6 | toggleStatus() | **NO transaction** — GAP |

### TC-P01: Tab Load Inside Trip Management

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with viewAny permission | Success |
| 2 | Navigate to `/transport/trip-management` | Dashboard loads |
| 3 | Tab `driver_roster` present in tab nav | tripmanagement.blade.php:10 |
| 4 | Click "Driver/Vehicle Roster" tab | GET ?tab=driver_roster |
| 5 | driverRouteVehicleQuery() runs | Paginated data |
| 6 | Search/filter bar visible | Search + status + dropdowns |
| 7 | Table columns: Route, Shift, Vehicle, Driver, Helper, Eff From/To, Status, Action | Blade renders |
| 8 | "Add" button visible | Conditional on create permission |
| 9 | "Trash" button visible | Link to trash |

### TC-P01a: Standalone Index BROKEN

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to `/driver-route-vehicle` | Controller@index line 24 |
| 2 | Gate check passes | Authorized |
| 3 | `return view('transport::driver_route_vehicle.index')` | No data passed |
| 4 | View references `$shifts`, `$routes`, `$vehicles`, `$driverHelpers`, `$driverRouteVehicles` | **Error**: Undefined variable |
| 5 | **Fix needed**: Add all 5 variables to view() call | Currently broken |

### TC-N07: Invalid Date Range

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | effective_from=2026-02-01, effective_to=2026-01-01 | End before start |
| 2 | Controller line 52: from > to? | true |
| 3 | Error: 'Effective To date cannot be before Effective From date.' | Returned withInput |
| 4 | Also: form request `after_or_equal:effective_from` would catch | Double validation |
| 5 | DB: no record created | Unchanged |

### TC-CR18: Routes Registration

| Step # | Route Definition | Name |
|--------|-----------------|------|
| 1 | `Route::resource('driver-route-vehicle', ...)` — 7 routes | `transport.driver-route-vehicle.*` |
| 2 | `GET /.../trash/view` | `...trashed` |
| 3 | `GET /.../{id}/restore` | `...restore` |
| 4 | `DELETE /.../{id}/force-delete` | `...forceDelete` |
| 5 | `POST /.../{vehicle}/toggle-status` | `...toggleStatus` |
| 6 | Total: 11 routes | All named with `transport.` prefix |
| 7 | Note: toggleStatus param is `{vehicle}` but controller uses `$id` | Route-model binding NOT used |

### TC-CR14: GAP — pickup_drop Not Validated

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open DriverRouteVehicleRequest.php rules() | pickup_drop NOT present |
| 2 | Check model fillable | pickup_drop IS in fillable |
| 3 | Controller line 111: directly uses request value | No validation |
| 4 | Only DB ENUM provides constraint | Last defense |

### TC-CR23: GAP — driver_id/helper_id No Exists Check

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | driver_id rule: `['required']` | No exists check |
| 2 | helper_id rule: `['nullable']` | No exists check |
| 3 | Post with driver_id=99999 | Request passes |
| 4 | DB: FK constraint `tpt_personnel.id` violation | 500 error |

### TC-CR33: GAP — toggleStatus No Transaction

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open toggleStatus() lines 482-512 | No DB::transaction anywhere |
| 2 | Main record save succeeds | is_active toggled |
| 3 | Scheduler update fails (e.g., connection issue) | Inconsistent: main toggled, scheduler not synced |
| 4 | No rollback mechanism | Partial update |

### TC-CR34: GAP — forceDelete No try/catch

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open forceDelete() lines 453-476 | DB::beginTransaction at 456 |
| 2 | No try/catch block | Exception → Laravel handler |
| 3 | Transaction auto-rolls back on exception | Safe but no error message |
| 4 | Compare with store/update/restore which have try/catch + error messages | Inconsistent error handling |

### TC-D07: Update Effective Range — Full Rebuild

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create: from=2026-01-01, to=2026-01-05 | 5 scheduler rows |
| 2 | Update: from=2026-02-01, to=2026-02-03 | 3-day new range |
| 3 | Old scheduler: withTrashed()->forceDelete() | 5 rows permanently removed |
| 4 | New scheduler: upsert for 3 days | 3 rows created |
| 5 | COUNT = 3 (old ones gone) | Full replacement |

### TC-D08: Concurrent Create — DDL Trigger

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User A and B simultaneously create same roster | Race |
| 2 | Both pass controller overlap check (before commit) | Race window |
| 3 | User A commits | Row inserted |
| 4 | User B INSERT fails: trigger fires | SIGNAL SQLSTATE '45000' |
| 5 | User B gets error → rollback | 1 record only |

### TC-BIZ-DEEP-37: Missing Helper Eager Load

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open TripMgmtController.php:120 | `->with(['route','shift','vehicle','driver'])` |
| 2 | Note: `'helper'` is missing | N+1 risk |
| 3 | Compare show() line 230 | `->with(['route','shift','vehicle','driver','helper'])` — correct |
| 4 | If tab view accesses `$item->helper->name` | Each row → separate DB query |

---

## 8. Bug Summary

| Bug ID | Severity | Description | Controller Location |
|--------|----------|-------------|-------------------|
| BUG-01 | P1 | Standalone index() returns view with no data — `$shifts`, `$routes`, `$vehicles`, `$driverHelpers`, `$driverRouteVehicles` missing | ctlr index:27 |
| BUG-02 | P1 | Blade `@can('...edit')` vs controller `Gate::authorize('...update')` — permission mismatch | ctlr edit:211, index.blade:91 |
| BUG-03 | P1 | Blade `@can('...status')` vs controller `Gate::authorize('...update')` — permission mismatch | ctlr toggleStatus:484, index.blade:88 |
| BUG-04 | P1 | Create with pickup_drop='Both' causes ENUM violation — ENUM('Pickup','Drop') rejects 'Both' | ctlr store:111 + Migration |
| BUG-05 | P2 | Update 'Both' not expanded into ['Pickup','Drop'] for scheduler — passes raw 'Both' string | ctlr update:324 |
| BUG-06 | P2 | toggleStatus saves model twice — redundant second `$model->save()` | ctlr toggleStatus:487,500 |
| BUG-07 | P2 | toggleStatus has no DB::transaction — partial update possible | ctlr toggleStatus:486-493 |
| BUG-08 | P2 | restore() scheduler scope (shift+route+pickup_drop) mismatches destroy() scope (driver+vehicle+route) | ctlr restore:434-438 vs destroy:383-387 |
| BUG-09 | P2 | forceDelete() missing try/catch — no error handling unlike other methods | ctlr forceDelete:456-476 |
| BUG-10 | P2 | driver_id and helper_id lack `exists:tpt_personnel,id` validation | DriverRouteVehicleRequest.php:46-52 |

---

| R-09 | NULL effective_to bypass required validation | Feature not testable via normal form | Medium | Either remove 'required' from request or fix controller to handle both paths |
| R-10 | helper not eager-loaded in tab | N+1 queries for each roster row if helper displayed | Low | Add 'helper' to with() array in driverRouteVehicleQuery() |

---

## 13. Key Code References

| File | Lines | Purpose |
|------|-------|---------|
| `DriverRouteVehicleController.php` | 1-513 | Full controller with 11 methods |
| `TripMgmtController.php` | 117-171 | private driverRouteVehicleQuery() for tab |
| `DriverRouteVehicleRequest.php` | 1-81 | FormRequest with 7 rules + authorize + prepare |
| `DriverRouteVehicleJnt.php` | 1-49 | Model: table, fillable, 5 relationships |
| `TptRouteSchedulerJnt.php` | 1-61 | Scheduler model with SoftDeletes, trips() HasMany |
| `routes/web.php` | 121-125 | Route definitions (resource + 4 extra) |
| `tripmanagement.blade.php` | 10 | Tab registration with permission check |
| `driver_route_vehicle/index.blade.php` | 1-120 | Index view with search, filters, table, permission checks |
| `TransportDriverRouteVehiclePolicy.php` | 1-95 | Policy with viewAny, view, status, create, update, delete, restore, forceDelete, import, export, print |


## 9. Data Flow Diagrams (Text)

### Store Flow

```
User POST → Gate::authorize(create) → DateRangeCheck → OverlapQuery(4 conditions)
  → DB::beginTransaction → DriverRouteVehicleJnt::create (pickup_drop may crash ENUM!)
  → Parse dates → expand pickup_drop types → while(day <= end)
    → foreach(type) → TptRouteSchedulerJnt::exists? → create or update
  → activityLog('Created') → DB::commit → redirect(trip-management)
```

### Update Flow

```
User PUT → Gate::authorize(update) → OverlapCheck(exclude self) → DB::beginTransaction
  → DriverRouteVehicleJnt::findOrFail → update(all fields) → activityLog('Updated')
  → TptRouteSchedulerJnt::withTrashed()->forceDelete(shift,route,vehicle,driver,pickup)
  → rebuild date loop → TptRouteSchedulerJnt::upsert(rows)
  → DB::commit → redirect(trip-management)
```

### Destroy Flow

```
User DELETE → Gate::authorize(delete) → findOrFail → today in range? → BLOCKED or
  DB::transaction {
    TptRouteSchedulerJnt::delete(driver,vehicle,route)  // BROAD scope!
    DriverRouteVehicleJnt::delete()  // soft
    activityLog('Deleted')
  } → redirect back
```

### ToggleStatus Flow

```
User POST → Gate::authorize(update) → findOrFail → flip is_active → save(1st)
  → TptRouteSchedulerJnt::update(driver,vehicle,route, is_active)  // NO transaction!
  → activityLog('Toggled')
  → save(2nd, redundant) → JSON response
```

---

## 10. Route Map

| Method | HTTP Verb | URL | Controller Method | View |
|--------|-----------|-----|-------------------|------|
| index | GET | `/driver-route-vehicle` | index() | `transport::driver_route_vehicle.index` (BROKEN) |
| create | GET | `/driver-route-vehicle/create` | create() | `transport::driver_route_vehicle.create` |
| store | POST | `/driver-route-vehicle` | store() | redirect to trip-management |
| show | GET | `/driver-route-vehicle/{id}` | show() | `transport::driver_route_vehicle.show` |
| edit | GET | `/driver-route-vehicle/{id}/edit` | edit() | `transport::driver_route_vehicle.edit` |
| update | PUT | `/driver-route-vehicle/{id}` | update() | redirect to trip-management |
| destroy | DELETE | `/driver-route-vehicle/{id}` | destroy() | redirect back |
| trashed | GET | `/driver-route-vehicle/trash/view` | trashed() | `transport::driver_route_vehicle.trash` |
| restore | GET | `/driver-route-vehicle/{id}/restore` | restore() | redirect back |
| forceDelete | DELETE | `/driver-route-vehicle/{id}/force-delete` | forceDelete() | redirect back |
| toggleStatus | POST | `/driver-route-vehicle/{vehicle}/toggle-status` | toggleStatus() | JSON response |

---

## 11. Edge Cases & Risk Assessment

| Risk ID | Scenario | Impact | Likelihood | Mitigation |
|---------|----------|--------|------------|------------|
| R-01 | 'Both' ENUM crash on store | Cannot create roster with 'Both' via UI | High | Fix: store 'Pickup' for main record, create both types for scheduler |
| R-02 | Destroy overscopes scheduler | Unrelated rosters lose scheduler entries | Medium | Fix: add shift_id + pickup_drop + id filters to scheduler delete scope |
| R-03 | Restore does not find all scheduler rows | Scheduler left in trashed state | Medium | Fix: align restore scope with delete scope (use driver/vehicle/route) |
| R-04 | toggleStatus partial update | Main record toggled but scheduler not synced | Low | Fix: wrap in DB::transaction |
| R-05 | forceDelete exception | No user-friendly error message | Low | Fix: add try/catch like other methods |
| R-06 | driver_id/helper_id without exists validation | FK violation on invalid IDs | Medium | Fix: add `exists:tpt_personnel,id` validation rules |
| R-07 | update() overlap simpler than store() | Overlap not detected for NULL effective_to scenarios | Medium | Fix: align update overlap logic with store overlap logic |
| R-08 | index() standalone broken | Feature unusable outside tab container | High | Fix: pass required variables to view in index() |
| R-09 | NULL effective_to bypass required validation | Feature not testable via normal form | Medium | Either remove 'required' from request or fix controller to handle both paths |
| R-10 | helper not eager-loaded in tab | N+1 queries for each roster row if helper displayed | Low | Add 'helper' to with() array in driverRouteVehicleQuery() |

---

## 12. Key Code References

| File | Lines | Purpose |
|------|-------|---------|
| `DriverRouteVehicleController.php` | 1-513 | Full controller with 11 methods |
| `TripMgmtController.php` | 117-171 | private driverRouteVehicleQuery() for tab |
| `DriverRouteVehicleRequest.php` | 1-81 | FormRequest with 7 rules + authorize + prepare |
| `DriverRouteVehicleJnt.php` | 1-49 | Model: table, fillable, 5 relationships |
| `TptRouteSchedulerJnt.php` | 1-61 | Scheduler model with SoftDeletes, trips() HasMany |
| `routes/web.php` | 121-125 | Route definitions (resource + 4 extra) |
| `tripmanagement.blade.php` | 10 | Tab registration with permission check |
| `driver_route_vehicle/index.blade.php` | 1-120 | Index view with search, filters, table, permission checks |
| `TransportDriverRouteVehiclePolicy.php` | 1-95 | Policy with viewAny, view, status, create, update, delete, restore, forceDelete, import, export, print |


---

*Template: tpt_PickupStopsList_TcList.md (Syllabus depth) | Entity: DriverVehRoster | Date: 2026-07-21*
