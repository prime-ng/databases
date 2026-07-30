# tpt_FuelLog_TcList

## Module: Transport → Vehicle Management → Fuel Log

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | Transport |
| Tab Group | Vehicle Management (5-tab container via `VehicleMgmtController`) |
| Feature | Fuel Log |
| URL(s) | `/vehicle-fuel` (index), `/vehicle-fuel/create` (create), `/vehicle-fuel` (store), `/vehicle-fuel/{vehicleFuel}` (show), `/vehicle-fuel/{vehicleFuel}/edit` (edit), `/vehicle-fuel/{vehicleFuel}` (update PUT), `/vehicle-fuel/{vehicleFuel}` (destroy DELETE), `/vehicle-fuel/trash/view` (trash), `/vehicle-fuel/{id}/restore` (restore GET), `/vehicle-fuel/{id}/force-delete` (forceDelete DELETE), `/vehicle-fuel/{id}/update-status` (updateStatus POST) |
| Controller | `Modules\Transport\Http\Controllers\TptVehicleFuelController` |
| Tab Container Controller | `Modules\Transport\Http\Controllers\VehicleMgmtController@index()` |
| Model | `Modules\Transport\Models\TptVehicleFuel` — table: `tpt_vehicle_fuel` |
| Validation | `Modules\Transport\Http\Requests\TptVehicleFuelRequest` |
| Permissions | `tenant.vehicle-fuel.viewAny`, `tenant.vehicle-fuel.view`, `tenant.vehicle-fuel.create`, `tenant.vehicle-fuel.update`, `tenant.vehicle-fuel.delete`, `tenant.vehicle-fuel.restore`, `tenant.vehicle-fuel.forceDelete`, `tenant.vehicle-fuel.approve` |
| Soft Deletes | Yes (`SoftDeletes` trait) |
| Activity Log | Events: `Stored` (create), `Updated`, `Trashed` (soft delete), `Restored`, `Deleted` (force delete), `StatusUpdated` (updateStatus) |
| Status Workflow | `Pending` (default) → `Approved` / `Rejected` via `updateStatus()` AJAX endpoint |

---

## 2. Pre-conditions

- Required permissions: All `tenant.vehicle-fuel.*` permissions listed above
- Test user must have all above permissions (default admin user)
- Tenant context must be initialized via `tenancy()->initialize()`
- Required seed data: At least one active `Vehicle` (tpt_vehicle) and optional `DriverHelper` (tpt_personnel)
- Fuel type dropdown values must exist in `sys_dropdown` for `fuel_type` (FK reference — DDL shows `INT UNSIGNED NOT NULL`)
- Dusk environment variables: `DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD`
- The Fuel Log tab is loaded as part of VehicleMgmt — URL `/vehicle-mgmt` loads `VehicleMgmtController@index` with all vehicle management tabs simultaneously
- There is also a standalone (`/vehicle-fuel`) index page via `TptVehicleFuelController@index` — not embedded in tab

---

## 3. Default Data Load

When the page loads via `VehicleMgmtController@index()` (GET `/vehicle-mgmt`), all vehicle management tab data is fetched in a single request:

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| Fuel Entries Grid | `VehicleMgmtController@fuelEntryQuery()` | `TptVehicleFuel::with(['vehicle','driver','fuelType'])->orderBy('date','DESC')` | search (vehicle.registration_no, driver.name), status | 10/page via `->paginate(10)->withQueryString()` |
| Vehicles for filter | View dropdown (from `$all_vehicles` collection) | `Vehicle::all()` | None | None |
| Drivers for filter | View dropdown (from `$all_drivers` collection) | `DriverHelper::all()` | None | None |

Note: The standalone `/vehicle-fuel` GET page loads its own dedicated full-page view with `TptVehicleFuelController@index()` — independent of the tab container. Fuel logs can be viewed both inside VehicleMgmt tab and as standalone list.

---

## 4. Test Data Strategy

- **Unique suffix**: `now()->format('His') . random_int(100, 999)` via `uniqueSuffix()` method
- **vehicle_id**: Must reference an existing active `tpt_vehicle` record (FK: `fk_vfl_vehicle`, ON DELETE CASCADE)
- **driver_id**: Optional, references `tpt_personnel` (FK: `fk_vfl_driver`, ON DELETE SET NULL)
- **date**: DATE type, must be valid date string
- **quantity**: DECIMAL(10,3), min 0.001 (backend validation). Test boundary values: 0.001, 99999999.999
- **cost**: DECIMAL(12,2), min 0. Test boundary values: 0, 9999999999.99
- **fuel_type**: INT UNSIGNED — FK to sys_dropdown. Validation only checks `required`, no `exists` rule enforced
- **odometer_reading**: INT UNSIGNED, nullable. Must be non-negative integer when provided
- **remarks**: VARCHAR(512), nullable. Backend max:512
- **status**: ENUM(`'Approved'`, `'Pending'`, `'Rejected'`) — default `'Pending'` in model. Only changed via `updateStatus()` AJAX endpoint
- **Pre-test cleanup**: Delete created fuel entries by date+vehicle_id to avoid duplicate test data
- **Activity log cleanup**: Records cleaned up after force-delete tests
- **Soft delete behavior**: `destroy()` calls `$vehicleFuel->delete()` — does NOT set `is_active` (no is_active column on fuel table)
- **Restore behavior**: `restore()` calls `$fuelEntry->restore()` via `onlyTrashed()->findOrFail()`
- **Status update**: `updateStatus()` validates `status` field inline with `required|in:Approved,Rejected,Pending`; returns JSON `{success: true/false, status, message}`
- **Update change tracking**: `getOriginal()` captured before update; `getChanges()` compared after; `updated_at` excluded from log; changed attributes logged as old→new per field

---

## 5. Business Conditions

### 5.1 Database Schema — `tpt_vehicle_fuel`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | id | INT UNSIGNED | PK, auto-increment |
| BC-DB-02 | vehicle_id | INT UNSIGNED | NOT NULL, FK → `tpt_vehicle.id`, ON DELETE CASCADE |
| BC-DB-03 | driver_id | INT UNSIGNED | DEFAULT NULL, FK → `tpt_personnel.id`, ON DELETE SET NULL |
| BC-DB-04 | date | DATE | NOT NULL |
| BC-DB-05 | quantity | DECIMAL(10,3) | NOT NULL |
| BC-DB-06 | cost | DECIMAL(12,2) | NOT NULL |
| BC-DB-07 | fuel_type | INT UNSIGNED | NOT NULL (FK to sys_dropdown — no explicit FK in DDL) |
| BC-DB-08 | odometer_reading | INT UNSIGNED | DEFAULT NULL |
| BC-DB-09 | remarks | VARCHAR(512) | DEFAULT NULL |
| BC-DB-10 | status | ENUM('Approved','Pending','Rejected') | NOT NULL, DEFAULT 'Pending' |
| BC-DB-11 | created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |
| BC-DB-12 | updated_at | TIMESTAMP | ON UPDATE CURRENT_TIMESTAMP |
| BC-DB-13 | deleted_at | TIMESTAMP | NULLABLE (soft delete) |

### 5.2 Validation Rules — `TptVehicleFuelRequest`

| BC ID | Field | Rule | Error Message |
|-------|-------|------|---------------|
| BC-VAL-01 | vehicle_id | required, `exists:tpt_vehicle,id` | Default unique violation |
| BC-VAL-02 | driver_id | nullable, `exists:tpt_personnel,id` | — |
| BC-VAL-03 | date | required, date | — |
| BC-VAL-04 | quantity | required, numeric, min:0.001 | — |
| BC-VAL-05 | cost | required, numeric, min:0 | — |
| BC-VAL-06 | fuel_type | required (no `exists` rule — gap) | — |
| BC-VAL-07 | odometer_reading | nullable, integer, min:0 | — |
| BC-VAL-08 | remarks | nullable, string, max:512 | — |
| BC-VAL-09 | status | `Rule::in(['Approved','Pending','Rejected'])` (not `required`, so only validated if present) | — |

Note: `fuel_type` has NO `exists` validation rule even though DDL strongly implies FK reference to a dropdown/master table. This could allow invalid fuel_type IDs to be stored.

### 5.3 Authorization (Permission Gates)

| BC ID | Permission | Controller Method | Behavior |
|-------|-----------|-------------------|----------|
| BC-AUTH-01 | tenant.vehicle-fuel.viewAny | index() | Without → 403 |
| BC-AUTH-02 | tenant.vehicle-fuel.view | show() | Without → 403 |
| BC-AUTH-03 | tenant.vehicle-fuel.create | store(), create() | Without → 403; also in TptVehicleFuelRequest::authorize() |
| BC-AUTH-04 | tenant.vehicle-fuel.update | update(), edit() | Without → 403; also in TptVehicleFuelRequest::authorize() |
| BC-AUTH-05 | tenant.vehicle-fuel.delete | destroy() | Without → 403 |
| BC-AUTH-06 | tenant.vehicle-fuel.restore | restore(), trashed() | Without → 403 |
| BC-AUTH-07 | tenant.vehicle-fuel.forceDelete | forceDelete() | Without → 403 |
| BC-AUTH-08 | tenant.vehicle-fuel.approve | updateStatus() | Without → 403; this is an AJAX-only endpoint |

### 5.4 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Create via `TptVehicleFuel::create($request->validated())` | Fuel entry created; redirect to `transport.vehicle-mgmt.index` with flash `created.vehicle_fuel` |
| BC-BIZ-02 | Activity log on create | `activityLog($fuelEntry, 'Stored', ['message' => 'Vehicle fuel entry created.', 'performed_by' => Auth::user()->name])` |
| BC-BIZ-03 | Update via `$vehicleFuel->update($request->validated())` | Attributes updated; change tracking via getOriginal() vs getChanges() |
| BC-BIZ-04 | Change tracking detail on update | `updated_at` excluded; each changed field logged as old→new |
| BC-BIZ-05 | Update with zero changes | No explicit "no changes" message — changedAttributes will be empty, logged as null |
| BC-BIZ-06 | Activity log on update | `activityLog($vehicleFuel, 'Updated', ['message' => 'Vehicle fuel entry updated.', 'changes' => $changedAttributes ?: null, 'performed_by' => Auth::user()->name])` |
| BC-BIZ-07 | Soft delete via `destroy()` | `$vehicleFuel->delete()` directly (no is_active toggle — fuel has no is_active column) |
| BC-BIZ-08 | Activity log on soft delete | `activityLog($vehicleFuel, 'Trashed', ['message' => 'Vehicle fuel entry trashed.', 'performed_by' => Auth::user()->name])` |
| BC-BIZ-09 | Redirect after soft delete | Redirect to `transport.vehicle-mgmt.index` with flash `trashed.vehicle_fuel` |
| BC-BIZ-10 | Trash list via `trashed()` | `TptVehicleFuel::onlyTrashed()->latest('deleted_at')->paginate(10)` |
| BC-BIZ-11 | Restore via `restore($id)` | `TptVehicleFuel::onlyTrashed()->findOrFail($id)` → `$fuelEntry->restore()`; redirect to `transport.vehicle-mgmt.index` |
| BC-BIZ-12 | Activity log on restore | `activityLog($fuelEntry, 'Restored', ['message' => 'Vehicle fuel entry restored.'])` |
| BC-BIZ-13 | Force delete via `forceDelete($id)` | `TptVehicleFuel::withTrashed()->findOrFail($id)` → `$fuelEntry->forceDelete()` |
| BC-BIZ-14 | Activity log on force delete | `activityLog($fuelEntry, 'Deleted', ['message' => 'Vehicle fuel entry permanently deleted.'])` |
| BC-BIZ-15 | updateStatus via `updateStatus(Request, $vehicleFuel)` | Validates `status: required|in:Approved,Rejected,Pending`; saves status; returns JSON `{success: true, status, message}` |
| BC-BIZ-16 | updateStatus failure | Returns JSON `{success: false, message: 'Status update failed.'}` with HTTP 500 |
| BC-BIZ-17 | Activity log on status update | `activityLog($vehicleFuel, 'StatusUpdated', ['message' => "Fuel status changed to {$request->status}."])` |

### 5.5 Model Relationships

| BC ID | Relationship | Type | Foreign Key | Notes |
|-------|-------------|------|-------------|-------|
| BC-REL-01 | vehicle() | BelongsTo Vehicle | vehicle_id | Returns the vehicle associated with this fuel entry |
| BC-REL-02 | driver() | BelongsTo DriverHelper | driver_id | Returns the driver (optional) |
| BC-REL-03 | fuelType() | BelongsTo Dropdown | fuel_type | Returns the fuel type dropdown value |

### 5.6 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|------------------|----------------|
| BC-REF-01 | vehicle_id | tpt_vehicle (id) | CASCADE |
| BC-REF-02 | driver_id | tpt_personnel (id) | SET NULL |

### 5.7 BC-BIZ-DEEP: In-Depth Business Conditions (Code-Verified)

| BC ID | Condition | Expected Behavior | Code Trace |
|-------|-----------|-------------------|------------|
| BC-BIZ-DEEP-01 | Model default `status = 'Pending'` | New records without explicit status get 'Pending' | `TptVehicleFuel.php:42-44` — `$attributes = ['status' => 'Pending']` |
| BC-BIZ-DEEP-02 | Model `$fillable` matches DDL columns | 9 fillable fields: vehicle_id, driver_id, date, quantity, cost, fuel_type, odometer_reading, remarks, status | `TptVehicleFuel.php:27-37` — all 9 columns present; `id`, `created_at`, `updated_at`, `deleted_at` excluded |
| BC-BIZ-DEEP-03 | Model casts match DDL types | `date => date`, `quantity => decimal:3`, `cost => decimal:2` | `TptVehicleFuel.php:49-53` |
| BC-BIZ-DEEP-04 | Model uses SoftDeletes trait | `delete()` sets deleted_at; `onlyTrashed()` scope available | `TptVehicleFuel.php:12` — `use HasFactory, SoftDeletes;` |
| BC-BIZ-DEEP-05 | Model has 3 relationships | vehicle(), driver(), fuelType() | `TptVehicleFuel.php:63-76` — 3 BelongsTo |
| BC-BIZ-DEEP-06 | Model has 5 scopes | pending, approved, rejected, dateRange, vehicleFilter | `TptVehicleFuel.php:82-108` |
| BC-BIZ-DEEP-07 | Controller `index()` uses `->latest()->paginate(10)` | 10 per page, ordered by created_at DESC | `TptVehicleFuelController.php:23-25` |
| BC-BIZ-DEEP-08 | Controller `create()` loads active vehicles and drivers | `Vehicle::active()->get()`, `DriverHelper::active()->get()` | `TptVehicleFuelController.php:37-38` |
| BC-BIZ-DEEP-09 | Controller `store()` uses `$request->validated()` | Only validated data passed to create | `TptVehicleFuelController.php:50` |
| BC-BIZ-DEEP-10 | Controller `store()` redirects to vehicle-mgmt.index | Flash using `flash('created.vehicle_fuel')` | `TptVehicleFuelController.php:57-59` |
| BC-BIZ-DEEP-11 | Controller `show()` uses route-model-binding | Auto-resolved `TptVehicleFuel $vehicleFuel` → 404 on missing | `TptVehicleFuelController.php:65-69` |
| BC-BIZ-DEEP-12 | Controller `edit()` loads active vehicles/drivers + existing record | Same query as create() | `TptVehicleFuelController.php:79-82` |
| BC-BIZ-DEEP-13 | Controller `update()` change tracking logic | Captures `getOriginal()` before, `getChanges()` after, excludes `updated_at`, builds old→new array | `TptVehicleFuelController.php:93-106` |
| BC-BIZ-DEEP-14 | Controller `update()` passes `$changedAttributes ?: null` | Empty array becomes null in activity log | `TptVehicleFuelController.php:110` |
| BC-BIZ-DEEP-15 | Controller `destroy()` direct soft delete | `$vehicleFuel->delete()` — no is_active toggle | `TptVehicleFuelController.php:126` |
| BC-BIZ-DEEP-16 | Controller `trashed()` uses `onlyTrashed()->latest('deleted_at')` | Sorted by deletion time | `TptVehicleFuelController.php:145-147` |
| BC-BIZ-DEEP-17 | Controller `restore($id)` manual ID param | NOT route-model-binding; uses `onlyTrashed()->findOrFail($id)` | `TptVehicleFuelController.php:159` |
| BC-BIZ-DEEP-18 | Controller `forceDelete($id)` uses `withTrashed()` | Can force-delete both trashed and non-trashed records | `TptVehicleFuelController.php:179` |
| BC-BIZ-DEEP-19 | Controller `updateStatus()` uses route-model-binding | Auto-resolves `TptVehicleFuel $vehicleFuel` | `TptVehicleFuelController.php:195` |
| BC-BIZ-DEEP-20 | Controller `updateStatus()` inline validation | `$request->validate(['status' => 'required|in:Approved,Rejected,Pending'])` | `TptVehicleFuelController.php:199-201` |
| BC-BIZ-DEEP-21 | Controller `updateStatus()` returns different HTTP codes | Success: 200, Failure: 500 | `TptVehicleFuelController.php:211-221` |
| BC-BIZ-DEEP-22 | Request `authorize()` gates by HTTP method | POST → create, PUT → update | `TptVehicleFuelRequest.php:13-16` |
| BC-BIZ-DEEP-23 | Request `fuel_type` missing `exists` rule | Only `'required'` — no master table validation (gap) | `TptVehicleFuelRequest.php:47-49` — commented out `exists` line |
| BC-BIZ-DEEP-24 | Request `status` Rule::in not `required` | Status field only validated when present — model default applies otherwise | `TptVehicleFuelRequest.php:62-64` |
| BC-BIZ-DEEP-25 | Routes: 1 resource + 4 additional | resource() generates 7 routes; +trashed, restore, forceDelete, updateStatus | `web.php:250-254` |
| BC-BIZ-DEEP-26 | Routes: No toggleStatus for fuel | Fuel uses `updateStatus` for approval workflow | `web.php:254` — `POST vehicle-fuel/{id}/update-status` |
| BC-BIZ-DEEP-27 | VehicleMgmtController `fuelEntryQuery()` search logic | search by `vehicle.registration_no` or `driver.name` via LIKE | `VehicleMgmtController.php:102-111` |
| BC-BIZ-DEEP-28 | VehicleMgmtController `fuelEntryQuery()` status filter | `where('status', $request->status)` — expects ENUM values | `VehicleMgmtController.php:114-116` |
| BC-BIZ-DEEP-29 | VehicleMgmtController pendingData includes fuel | `TptVehicleFuel::pending()->with(['vehicle','driver'])->take(10)` | `VehicleMgmtController.php:321-325` |
| BC-BIZ-DEEP-30 | Index view `fuel_log-pane` tab | Tab pane id matches nav-tab | `index.blade.php:1` — `id="fuel_log-pane"` |
| BC-BIZ-DEEP-31 | Index view status dropdown uses 1/0 values | Options: value="" (All), value="1" (Active), value="0" (Inactive) | `index.blade.php:14-17` — BUG: should be ENUM values |
| BC-BIZ-DEEP-32 | Index view table columns | Date, Vehicle, Driver, Fuel, Qty, Cost, Status, Action | `index.blade.php:35-43` |
| BC-BIZ-DEEP-33 | Index view shows `fuel->fuelType->value` | Fuel type dropdown value shown | `index.blade.php:52` |
| BC-BIZ-DEEP-34 | Index view status as badges | Approved=bg-success, Rejected=bg-danger, Pending=bg-warning | `index.blade.php:57-61` |
| BC-BIZ-DEEP-35 | Show view displays all fields in table | Vehicle, Driver, Fuel Date, Fuel Type, Qty, Cost, Odometer, Remarks, Status, Created/Updated At | `show.blade.php:24-108` |
| BC-BIZ-DEEP-36 | Create view uses `x-backend.form.form-dropdown` for fuel_type | Dropdown key: `tpt_vehicle.fuel_type_id` — loads from sys_dropdown | `create.blade.php:115-121` |
| BC-BIZ-DEEP-37 | Edit view status dropdown shows all 3 ENUM values | Pending, Approved, Rejected | `edit.blade.php:162-172` |
| BC-BIZ-DEEP-38 | Trash view uses `x-backend.table.action-trashed` | Restore + Force Delete buttons per row | `trash.blade.php:47-50` |
| BC-BIZ-DEEP-39 | Vehiclemgmt tab container wraps fuel tab with `@can` | `@can('tenant.vehicle-fuel.viewAny')` around include | `vehiclemgmt.blade.php:17-19` |
| BC-BIZ-DEEP-40 | Permissionslist: vehicle-fuel = $crud | All 16 crud actions including 'approve' registered | `permissionslist.php:308` — `$crud` array includes approve |
| BC-BIZ-DEEP-41 | Update with no changes: `$changedAttributes` is empty | `getChanges()` returns empty array → `$changedAttributes = []` → `?: null` gives null | `TptVehicleFuelController.php:96,110` |
| BC-BIZ-DEEP-42 | Force delete from already-deleted record | `withTrashed()` finds both soft-deleted and active → forceDelete works on both | `TptVehicleFuelController.php:179-180` |
| BC-BIZ-DEEP-43 | Restore only works on soft-deleted records | `onlyTrashed()` → finds only records with deleted_at NOT NULL | `TptVehicleFuelController.php:159` |
| BC-BIZ-DEEP-44 | Permission gate in Request + Controller redundancy | Both check same gate: Request authorize (line 13-16) AND Controller Gate::authorize (line 48) for store | Double authorization |
| BC-BIZ-DEEP-45 | Migration has no FK on fuel_type | Column `fuel_type` INT UNSIGNED NOT NULL but no `$table->foreign()` defined | `migration.php:19` — no foreign() call |
| BC-BIZ-DEEP-46 | Migration FK naming: fk_vfl_vehicle, fk_vfl_driver | Prefix `fk_vfl` for Vehicle Fuel Log | `migration.php:28,30` |
| BC-BIZ-DEEP-47 | date cast as 'date' in model | `$casts = ['date' => 'date']` → Carbon instance | `TptVehicleFuel.php:50` |
| BC-BIZ-DEEP-48 | quantity decimal:3 cast | Ensures 3 decimal places returned | `TptVehicleFuel.php:51` |
| BC-BIZ-DEEP-49 | cost decimal:2 cast | Ensures 2 decimal places returned | `TptVehicleFuel.php:52` |
| BC-BIZ-DEEP-50 | Status filter dropdown bug (value mismatch) | Dropdown uses 1/0 but backend expects ENUM → filter returns empty | `index.blade.php:14-17` vs `VehicleMgmtController.php:114-116` |

---

## 6. Test Case List

### 6.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | Fuel Log Tab Loads Inside Vehicle Mgmt | `/vehicle-mgmt` loads Fuel tab with filter bar, table (Vehicle, Driver, Date, Qty, Cost, Fuel Type, Odometer, Status), Add and Trash buttons | — | — | ⬜ |
| TC-P02 | Standalone Fuel Index Page | GET `/vehicle-fuel` loads full-page index with all fuel entries paginated | — | — | ⬜ |
| TC-P03 | Create Fuel Entry With All Required Fields | POST `/vehicle-fuel` with vehicle_id, date, quantity, cost, fuel_type → entry created, redirect to vehicle-mgmt, flash success | — | — | ⬜ |
| TC-P04 | Create Fuel Entry With Optional Fields (driver_id, odometer_reading, remarks) | All optional fields saved correctly in DB | — | — | ⬜ |
| TC-P05 | View Fuel Entry Details | `/vehicle-fuel/{id}` shows Vehicle, Driver, Date, Quantity, Cost, Fuel Type, Odometer, Remarks, Status, Created At, Updated At | — | — | ⬜ |
| TC-P06 | Edit Fuel Entry Loads Pre-Filled Data | `/vehicle-fuel/{id}/edit` shows existing values in all form fields | — | — | ⬜ |
| TC-P07 | Update Fuel Entry — Change Quantity and Cost | PUT to `/vehicle-fuel/{id}` updates quantity and cost; activity log records old→new values | — | — | ⬜ |
| TC-P08 | Update Fuel Entry — No Changes Submitted | PUT with same values → activity log has empty changes (null) | — | — | ⬜ |
| TC-P09 | Soft Delete Fuel Entry | DELETE `/vehicle-fuel/{id}` → deleted_at set; entry hidden from main list | — | — | ⬜ |
| TC-P10 | Trash Page Shows Deleted Entries | GET `/vehicle-fuel/trash/view` → list of soft-deleted entries with Restore and Force Delete buttons | — | — | ⬜ |
| TC-P11 | Restore Fuel Entry From Trash | GET `/vehicle-fuel/{id}/restore` → deleted_at=NULL; entry visible on main list | — | — | ⬜ |
| TC-P12 | Force Delete Fuel Entry | DELETE `/vehicle-fuel/{id}/force-delete` → record permanently removed | — | — | ⬜ |
| TC-P13 | Approve Fuel Entry via AJAX | POST `/vehicle-fuel/{id}/update-status` with `status=Approved` → JSON `{success:true, status:'Approved'}` | — | — | ⬜ |
| TC-P14 | Reject Fuel Entry via AJAX | POST with `status=Rejected` → JSON `{success:true, status:'Rejected'}` | — | — | ⬜ |
| TC-P15 | Filter Fuel Entries By Status (VehicleMgmt tab) | Select status filter → table shows only matching entries | — | — | ⬜ |
| TC-P16 | Search Fuel Entries By Vehicle Registration No | Enter vehicle reg no in search → matching entries displayed | — | — | ⬜ |
| TC-P17 | Search Fuel Entries By Driver Name | Enter driver name → matching entries displayed | — | — | ⬜ |
| TC-P18 | Full Lifecycle | Create → View → Edit → Toggle Status → Delete → Trash → Restore → Force Delete; all steps succeed | — | — | ⬜ |
| TC-P19 | Empty State — No Fuel Entries | Table shows "No Data Found" message | — | — | ⬜ |
| TC-P20 | Pagination — Entries Exceed First Page | When 11+ entries exist, pagination links appear | — | — | ⬜ |
| TC-P21 | Activity Log — Create Fuel Entry | After POST `/vehicle-fuel`, `activity_log` table contains 'Stored' entry with message "Vehicle fuel entry created." and `performed_by` = current user name | — | — | ⬜ |
| TC-P22 | Activity Log — Update Fuel Entry (With Changes) | After PUT `/vehicle-fuel/{id}`, `activity_log` contains 'Updated' entry with `changes` showing old→new values for changed fields (excludes `updated_at`) | — | — | ⬜ |
| TC-P23 | Activity Log — Update Fuel Entry (No Changes) | After PUT with identical data, `activity_log` contains 'Updated' entry with `changes` = null or empty | — | — | ⬜ |
| TC-P24 | Activity Log — Soft Delete Fuel Entry | After DELETE `/vehicle-fuel/{id}`, `activity_log` contains 'Trashed' entry with message "Vehicle fuel entry trashed." | — | — | ⬜ |
| TC-P25 | Activity Log — Restore Fuel Entry | After GET `/vehicle-fuel/{id}/restore`, `activity_log` contains 'Restored' entry with message "Vehicle fuel entry restored." | — | — | ⬜ |
| TC-P26 | Activity Log — Force Delete Fuel Entry | After DELETE `/vehicle-fuel/{id}/force-delete`, `activity_log` contains 'Deleted' entry with message "Vehicle fuel entry permanently deleted." | — | — | ⬜ |
| TC-P27 | Activity Log — Status Update (Approve/Reject) | After POST `/vehicle-fuel/{id}/update-status`, `activity_log` contains 'StatusUpdated' entry with message "Fuel status changed to {status}." | — | — | ⬜ |
| TC-P28 | Create Fuel Entry with quantity at exact minimum 0.001 | Entry created with quantity=0.001 | — | — | ⬜ |
| TC-P29 | Create Fuel Entry with cost at exact minimum 0 | Entry created with cost=0 | — | — | ⬜ |
| TC-P30 | Fuel Entry With NULL driver_id Created Successfully | No driver required; entry created | — | — | ⬜ |
| TC-P31 | Standalone index paginates correctly | GET `/vehicle-fuel?page=2` → second page of results | — | — | ⬜ |
| TC-P32 | Create fuel entry sets default status='Pending' | No status submitted → DB column = 'Pending' | — | — | ⬜ |
| TC-P33 | VehicleMgmt tab paginates with query string | `/vehicle-mgmt?status=Approved&page=2` preserves filters | — | — | ⬜ |
| TC-P34 | Activity Log — performed_by is authenticated user name | All activity log entries contain `performed_by` = auth user's name | — | — | ⬜ |
| TC-P35 | Update status back from Approved to Pending | POST updateStatus with `status=Pending` → status reverted | — | — | ⬜ |

### 6.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | Required — Missing vehicle_id | Validation error: "The vehicle id field is required." | — | — | ⬜ |
| TC-N02 | Required — Missing date | Validation error: "The date field is required." | — | — | ⬜ |
| TC-N03 | Required — Missing quantity | Validation error: "The quantity field is required." | — | — | ⬜ |
| TC-N04 | Required — Missing cost | Validation error: "The cost field is required." | — | — | ⬜ |
| TC-N05 | Required — Missing fuel_type | Validation error: "The fuel type field is required." | — | — | ⬜ |
| TC-N06 | Invalid vehicle_id — Non-Existent Vehicle | "The selected vehicle id is invalid." | — | — | ⬜ |
| TC-N07 | Invalid driver_id — Non-Existent Driver | "The selected driver id is invalid." | — | — | ⬜ |
| TC-N08 | Invalid date Format | "The date is not a valid date." | — | — | ⬜ |
| TC-N09 | quantity = 0 (Below Minimum 0.001) | "The quantity must be at least 0.001." | — | — | ⬜ |
| TC-N10 | quantity Negative Value | "The quantity must be at least 0.001." | — | — | ⬜ |
| TC-N11 | quantity Non-Numeric String | "The quantity must be a number." | — | — | ⬜ |
| TC-N12 | cost = Negative Value | "The cost must be at least 0." | — | — | ⬜ |
| TC-N13 | cost Non-Numeric | "The cost must be a number." | — | — | ⬜ |
| TC-N14 | odometer_reading Negative | "The odometer reading must be at least 0." | — | — | ⬜ |
| TC-N15 | odometer_reading Non-Integer | "The odometer reading must be an integer." | — | — | ⬜ |
| TC-N16 | remarks Exceeds 512 Characters | "The remarks must not be greater than 512 characters." | — | — | ⬜ |
| TC-N17 | Invalid Status Value in updateStatus | POST with `status=InvalidStatus` → validation error: "The selected status is invalid." | — | — | ⬜ |
| TC-N18 | View With Invalid ID | GET `/vehicle-fuel/99999` → 404 | — | — | ⬜ |
| TC-N19 | Edit With Invalid ID | GET `/vehicle-fuel/99999/edit` → 404 | — | — | ⬜ |
| TC-N20 | Update With Invalid ID | PUT `/vehicle-fuel/99999` → 404 | — | — | ⬜ |
| TC-N21 | Delete With Invalid ID | DELETE `/vehicle-fuel/99999` → 404 | — | — | ⬜ |
| TC-N22 | Restore Non-Deleted Entry | GET `/vehicle-fuel/{id}/restore` where entry is not trashed → `onlyTrashed()->find()` returns null → 404 | — | — | ⬜ |
| TC-N23 | Permission 403 — No Fuel Permissions | 403 Forbidden on all CRUD endpoints for user without `tenant.vehicle-fuel.*` permissions | — | — | ⬜ |
| TC-N24 | Guest Access Redirect | All `/vehicle-fuel/*` URLs redirect to `/login` for unauthenticated users | — | — | ⬜ |
| TC-N25 | XSS Injection In remarks | `<script>alert('xss')</script>` stored as literal string; Blade `{{ }}` escapes output | — | — | ⬜ |

| TC-N26 | Permission Denied — No `viewAny` → Index 403 | User without `tenant.vehicle-fuel.viewAny` → GET `/vehicle-fuel` returns 403 | — | — | ⬜ |
| TC-N27 | Permission Denied — No `create` → Create Form 403 | User without `tenant.vehicle-fuel.create` → GET `/vehicle-fuel/create` returns 403 | — | — | ⬜ |
| TC-N28 | Permission Denied — No `create` → Store 403 | User without `tenant.vehicle-fuel.create` → POST `/vehicle-fuel` returns 403 | — | — | ⬜ |
| TC-N29 | Permission Denied — No `view` → Show 403 | User without `tenant.vehicle-fuel.view` → GET `/vehicle-fuel/{id}` returns 403 | — | — | ⬜ |
| TC-N30 | Permission Denied — No `update` → Edit Form 403 | User without `tenant.vehicle-fuel.update` → GET `/vehicle-fuel/{id}/edit` returns 403 | — | — | ⬜ |
| TC-N31 | Permission Denied — No `update` → PUT 403 | User without `tenant.vehicle-fuel.update` → PUT `/vehicle-fuel/{id}` returns 403 | — | — | ⬜ |
| TC-N32 | Permission Denied — No `delete` → Destroy 403 | User without `tenant.vehicle-fuel.delete` → DELETE `/vehicle-fuel/{id}` returns 403 | — | — | ⬜ |
| TC-N33 | Permission Denied — No `restore` → Trash Page 403 | User without `tenant.vehicle-fuel.restore` → GET `/vehicle-fuel/trash/view` returns 403 | — | — | ⬜ |
| TC-N34 | Permission Denied — No `restore` → Restore 403 | User without `tenant.vehicle-fuel.restore` → GET `/vehicle-fuel/{id}/restore` returns 403 | — | — | ⬜ |
| TC-N35 | Permission Denied — No `forceDelete` → Force Delete 403 | User without `tenant.vehicle-fuel.forceDelete` → DELETE `/vehicle-fuel/{id}/force-delete` returns 403 | — | — | ⬜ |
| TC-N36 | Permission Denied — No `approve` → updateStatus 403 | User without `tenant.vehicle-fuel.approve` → POST `/vehicle-fuel/{id}/update-status` returns 403 (AJAX — check HTTP status) | — | — | ⬜ |
| TC-N37 | quantity = 0.001 — Exact Boundary (Positive) | `min:0.001` passes; entry created | — | — | ⬜ |
| TC-N38 | quantity Exceeds DECIMAL(10,3) Precision | 99999999.9999 → validation or DB truncation | — | — | ⬜ |
| TC-N39 | cost Exceeds DECIMAL(12,2) Precision | 99999999999.99 → validation or DB truncation | — | — | ⬜ |
| TC-N40 | updateStatus With Missing status Field | `status` not sent → validation error "The status field is required." | — | — | ⬜ |
| TC-N41 | Force Delete Already Force-Deleted Record | ID no longer exists → 404 | — | — | ⬜ |
| TC-N42 | Restore Force-Deleted Record | Record permanently gone → `onlyTrashed()->findOrFail()` → 404 | — | — | ⬜ |
| TC-N43 | Duplicate fuel_type Not Validated (Gap) | fuel_type=99999 creates successfully (no exists rule) | — | — | ⬜ |
| TC-N44 | Edit Form With Invalid ID | `/vehicle-fuel/99999/edit` → route-model-binding → 404 | — | — | ⬜ |
| TC-N45 | Show With Invalid ID | `/vehicle-fuel/99999` → route-model-binding → 404 | — | — | ⬜ |

### 6.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|----------------|---------|---------|--------|
| TC-D01 | A | Vehicle Deletion Cascades To Fuel Entries (CASCADE) | Deleting a vehicle auto-deletes all fuel entries for that vehicle | — | — | ⬜ |
| TC-D02 | B | Driver Deletion Sets driver_id to NULL (SET NULL) | Deleting a driver sets driver_id=NULL in fuel entries (no data loss) | — | — | ⬜ |
| TC-D03 | C | Rapid Status Toggle | Rapid clicking update-status button → no data corruption or duplicate requests | — | — | ⬜ |
| TC-D04 | D | Fuel Entry Creation Without Driver | driver_id=NULL allowed; entry created successfully without driver | — | — | ⬜ |
| TC-D05 | A | Vehicle CASCADE — Delete Vehicle With Fuel Entries | Create fuel entry → delete parent vehicle → fuel entry auto-deleted (verify `deleted_at` is set — soft delete cascade or hard delete) | — | — | ⬜ |
| TC-D06 | B | Driver SET NULL — Delete Driver With Fuel Entries | Create fuel entry with driver → delete driver → fuel entry `driver_id` becomes NULL (no data loss) | — | — | ⬜ |
| TC-D07 | C | updateStatus Returns 500 on DB Failure | Mock DB failure → JSON `{success:false}` with HTTP 500 | — | — | ⬜ |
| TC-D08 | C | Concurrent Status Updates | Two simultaneous updateStatus calls → last write wins, no corruption | — | — | ⬜ |
| TC-D09 | A | Vehicle Delete CASCADE — Soft vs Hard | Verify FK `fk_vfl_vehicle` = ON DELETE CASCADE | — | — | ⬜ |
| TC-D10 | B | Driver Delete SET NULL — Verify DB | Driver delete → `driver_id = NULL` for associated fuel entries | — | — | ⬜ |

### 6.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|-----------------|---------|---------|--------|
| TC-CR01 | CR | P1 | Controller — Gate::authorize() Before Every State Change | index/create/store/show/edit/update/destroy/trashed/restore/forceDelete/updateStatus all have Gate::authorize() as early line | — | — | ◌ |
| TC-CR02 | CR | P1 | Controller — activityLog After Every CRUD | Stored, Updated, Trashed, Restored, Deleted, StatusUpdated — all events logged | — | — | ◌ |
| TC-CR03 | CR | P1 | Controller — Change Tracking on Update | getOriginal() captured; getChanges() compared; updated_at excluded; old→new logged | — | — | ◌ |
| TC-CR04 | CR | P1 | Controller — withTrashed() for forceDelete | forceDelete uses `TptVehicleFuel::withTrashed()->findOrFail()` — correct for both trashed and non-trashed | — | — | ◌ |
| TC-CR05 | CR | P1 | Controller — onlyTrashed() for Restore | restore uses `TptVehicleFuel::onlyTrashed()->findOrFail()` — only trashed records can be restored | — | — | ◌ |
| TC-CR06 | CR | P1 | Controller — updateStatus AJAX Response | JSON `{success: true/false, status, message}` with HTTP 500 on failure | — | — | ◌ |
| TC-CR07 | CR | P1 | Request — authorize() matches controller gate | Request checks create for POST, update for PUT/PATCH — same as controller | — | — | ◌ |
| TC-CR08 | CR | P1 | Request — Validation Rules Match DDL | quantity numeric matches DECIMAL(10,3); cost numeric matches DECIMAL(12,2); odometer_reading integer matches INT; remarks max:512 matches VARCHAR(512) | — | — | ◌ |
| TC-CR09 | CR | P1 | Request — fuel_type Missing `exists` Rule | `fuel_type` validated only as `required` but DDL is INT UNSIGNED FK — no exists rule allows invalid IDs | — | — | ◌ |
| TC-CR10 | CR | P1 | Request — status Rule::in Not Required | Rule::in defined but `required` not present — so validation passes even without status field (model defaults to 'Pending') | — | — | ◌ |
| TC-CR11 | CR | P1 | Model — Table Name and SoftDeletes | `protected $table = 'tpt_vehicle_fuel'` and `use SoftDeletes` trait present | — | — | ◌ |
| TC-CR12 | CR | P1 | Model — Fillable Matches DB Columns | $fillable: vehicle_id, driver_id, date, quantity, cost, fuel_type, odometer_reading, remarks, status — 9 fields all present | — | — | ◌ |
| TC-CR13 | CR | P1 | Model — Casts | `date => 'date'`, `quantity => 'decimal:3'`, `cost => 'decimal:2'` | — | — | ◌ |
| TC-CR14 | CR | P1 | Model — Default Attributes | `status => 'Pending'` — matches DDL default | — | — | ◌ |
| TC-CR15 | CR | P1 | Model — Relationships | 3 relationships present: vehicle(), driver(), fuelType() | — | — | ◌ |
| TC-CR16 | CR | P1 | Model — Scopes | pending(), approved(), rejected(), dateRange(), vehicleFilter() — 5 scopes | — | — | ◌ |
| TC-CR17 | CR | P1 | Routes — Resource + Additional Routes | web.php lines 250-255: `Route::resource('vehicle-fuel', ...)` + 4 additional routes (trashed, restore, forceDelete, updateStatus) | — | — | ◌ |
| TC-CR18 | CR | P1 | Routes — No toggleStatus Route | Unlike other entities, fuel has NO toggleStatus route — but does have updateStatus for approval workflow | — | — | ◌ |
| TC-CR19 | CR | P1 | VehicleMgmtController — fuelEntryQuery Filters | Search by vehicle.registration_no or driver.name; filter by status | — | — | ◌ |
| TC-CR20 | CR | P1 | VehicleMgmtController — Pending Data Count | `getDetailedPendingData()` shows `vehicle_fuel` pending entries (top 10) in approval pending section | — | — | ◌ |
| TC-CR21 | CR | P1 | View — Status Filter Dropdown Mismatch (bug) | `vehicle_fuel/index.blade.php` status dropdown uses values `1`/`0` but `fuelEntryQuery` expects ENUM values (`Approved`/`Pending`/`Rejected`) — filter always returns empty | — | — | ◌ |
| TC-CR22 | CR | P2 | Controller — All Methods Have Type Hints | Parameters: store(Request $request), show(TptVehicleFuel $vehicleFuel), update(Request $request, TptVehicleFuel $vehicleFuel), etc. | — | — | ◌ |
| TC-CR23 | CR | P2 | Controller — updateStatus inline validation | Status validated inline with `required|in:Approved,Rejected,Pending` | — | — | ◌ |
| TC-CR24 | CR | P2 | Request — driver_id marked required in blade but nullable in validation | Blade `create.blade.php:58` has `required` attribute but Request says `nullable` | — | — | ◌ |
| TC-CR25 | CR | P2 | Request — odometer_reading marked required in blade but nullable in validation | Blade `create.blade.php:134` has `required` attribute but Request says `nullable` | — | — | ◌ |
| TC-CR26 | CR | P2 | View — index.blade.php column count differs from BC spec | Index shows: Date, Vehicle, Driver, Fuel, Qty, Cost, Status, Action (8 cols) vs BC Spec says Odometer also | — | — | ◌ |
| TC-CR27 | CR | P2 | View — show.blade.php uses Carbon::parse for date | `\\Carbon\\Carbon::parse($vehicleFuel->date)->format('d M Y')` | — | — | ◌ |
| TC-CR28 | CR | P2 | Vehiclemgmt — nav-tab permission guard on fuel tab | Fuel tab only shows if `@can('tenant.vehicle-fuel.viewAny')` | — | — | ◌ |
| TC-CR29 | CR | P2 | Permissions — approve action registered for updateStatus | `approve` in `$crud` enables `tenant.vehicle-fuel.approve` used by `updateStatus()` | — | — | ◌ |
| TC-CR30 | CR | P2 | Migration — No FK constraint on fuel_type | `fuel_type` INT UNSIGNED NOT NULL with no `foreign()` defined — data integrity gap | — | — | ◌ |
| TC-CR31 | CR | P2 | Flash messages use flash() helper | `flash('created.vehicle_fuel')`, `flash('updated.vehicle_fuel')` etc. — translatable via flash key | — | — | ◌ |
| TC-CR32 | CR | P2 | Route parameter name: `vehicleFuel` vs `vehicle_fuel` | Resource uses `vehicle-fuel` URI but `{vehicleFuel}` param (camelCase) for route-model-binding | — | — | ◌ |

### 6.5 Mapped Permissions (permissionslist.php)

| Permission Group | Slug | Registered Actions | Matching Controller Gates |
|-----------------|------|--------------------|---------------------------|
| Vehicle Fuel | `vehicle-fuel` | `viewAny`, `view`, `create`, `update`, `delete`, `restore`, `forceDelete`, `approve` | All 8 gates match 1:1 (`tenant.vehicle-fuel.*`) |

Note: All `tenant.vehicle-fuel.*` permissions from `permissionslist.php` line 308 (`$crud` array) are used in the controller. No Policy class exists (`TptVehicleFuelPolicy` not found) — Gate::authorize() uses string-based gates which are resolved via the `Gate::before` super-admin bypass and the `permissionslist.php` group registration. The `approve` action in `$crud` enables `tenant.vehicle-fuel.approve` used by `updateStatus()`.

No extra permissions are registered in code that aren't in permissionslist.php, and no permissionslist.php entries for this slug go unused.

---

## 7. Detailed Test Steps

### TC-P01: Fuel Log Tab Loads Inside Vehicle Mgmt

| Step # | Action | Expected Result | Code Trace |
|--------|--------|-----------------|------------|
| 1 | Login as admin with all fuel permissions | Dashboard loads | — |
| 2 | Navigate to Vehicle Management | URL: `/vehicle-mgmt`; 5-tab layout visible | `vehiclemgmt.blade.php:8-14` — nav-tab with Fuel Log, Inspection, Service Log, Veh. Approval, Veh. Maintenance |
| 3 | Click "Fuel Log" tab | `fuel_log-pane` tab-pane visible with filter bar | `index.blade.php:1` — `id="fuel_log-pane"` |
| 4 | Check filter bar | Search input (placeholder "Search...Vehicle Registration No,Driver Name"), Status dropdown (All/Active/Inactive), Search + Reset buttons | `index.blade.php:10-25` |
| 5 | Check Add Fuel button | Button present via `x-backend.tab.search-bar` component | Uses `search-bar` component which includes Add button |
| 6 | Check table headers | Date, Vehicle, Driver, Fuel, Qty, Cost, Status, Action | `index.blade.php:35-43` — 8 columns |
| 7 | Check action buttons per row | View (eye), Edit (pencil), Delete (trash) via `x-backend.table.action` component | `index.blade.php:65` |
| 8 | Check data loads | Table populated with fuel entries from `$fuelEntries` | `index.blade.php:47` — `@forelse($fuelEntries as $fuel)` |
| 9 | Verify tab permission guard | Without `tenant.vehicle-fuel.viewAny`, fuel section not included | `vehiclemgmt.blade.php:17-19` — `@can('tenant.vehicle-fuel.viewAny')` |
| 10 | Check date format | Date displayed as `d-m-Y` format | `index.blade.php:49` — `$fuel->date?->format('d-m-Y')` |
| 11 | Check status badges | Approved=bg-success (green), Rejected=bg-danger (red), Pending=bg-warning (yellow) | `index.blade.php:57-61` |
| 12 | Check cost formatting | Cost prefixed with ₹ and formatted to 2 decimal places | `index.blade.php:54` — `₹ {{ number_format($fuel->cost, 2) }}` |

### TC-P02: Standalone Fuel Index Page

| Step # | Action | Expected Result | Code Trace |
|--------|--------|-----------------|------------|
| 1 | Login as admin | Dashboard loads | — |
| 2 | Navigate to GET `/vehicle-fuel` | Standalone full-page index (no tab container) | `TptVehicleFuelController.php:19-28` |
| 3 | Verify Gate authorization | `Gate::authorize('tenant.vehicle-fuel.viewAny')` passes | `TptVehicleFuelController.php:21` |
| 4 | Verify query | `TptVehicleFuel::with(['vehicle','driver','fuelType'])->latest()->paginate(10)` | `TptVehicleFuelController.php:23-25` |
| 5 | Verify view | `transport::vehicle_fuel.index` loaded (NOT inside tab container) | `TptVehicleFuelController.php:27` |
| 6 | Verify table content | Same blade file as tab: 8 columns rendered | Same `index.blade.php` |
| 7 | Verify pagination | `$fuelEntries->links()` renders paginator | `index.blade.php:76` `{{ $fuelEntries->links() }}` |
| 8 | Verify no tab wrapper | Page is full layout with breadcrumb, not tab-pane | Standalone route doesn't include vehiclemgmt layout |

### TC-P03: Create Fuel Entry With All Required Fields

| Step # | Action | Expected Result | Code Trace |
|--------|--------|-----------------|------------|
| 1 | Login as admin | Dashboard | — |
| 2 | Navigate to create form via Add Fuel button | GET `/vehicle-fuel/create` | `TptVehicleFuelController.php:33-41` |
| 3 | Verify Gate authorization | `Gate::authorize('tenant.vehicle-fuel.create')` passes | `TptVehicleFuelController.php:35` |
| 4 | Verify vehicles loaded | `$vehicles = Vehicle::active()->get()` — only active vehicles | `TptVehicleFuelController.php:37` |
| 5 | Verify drivers loaded | `$drivers = DriverHelper::active()->get()` — only active drivers | `TptVehicleFuelController.php:38` |
| 6 | Verify view | `transport::vehicle_fuel.create` loaded | `TptVehicleFuelController.php:40` |
| 7 | Fill Vehicle field | Select vehicle from `select[name=vehicle_id]` dropdown | `create.blade.php:38-46` |
| 8 | Fill Date field | Enter valid date in `input[name=date]` type=date | `create.blade.php:75-83` |
| 9 | Fill Quantity field | Enter 50.000 in `input[name=quantity]` type=number | `create.blade.php:90-98` |
| 10 | Fill Cost field | Enter 2500.00 in `input[name=cost]` type=number | `create.blade.php:103-111` |
| 11 | Select Fuel Type | Select from `select[name=fuel_type]` dropdown | `create.blade.php:115-121` — key `tpt_vehicle.fuel_type_id` |
| 12 | Submit form | POST `/vehicle-fuel` | Form action: `route('transport.vehicle-fuel.store')` |
| 13 | Verify Request authorization | POST → `Gate::allows('tenant.vehicle-fuel.create')` | `TptVehicleFuelRequest.php:13-14` |
| 14 | Verify Controller Gate | `Gate::authorize('tenant.vehicle-fuel.create')` again | `TptVehicleFuelController.php:48` |
| 15 | Verify validation rules pass | All required fields validated | `TptVehicleFuelRequest.php:25-49` |
| 16 | Verify create | `TptVehicleFuel::create($request->validated())` inserts row | `TptVehicleFuelController.php:50` |
| 17 | Verify activity log | `activityLog($fuelEntry, 'Stored', ['message' => 'Vehicle fuel entry created.', 'performed_by' => Auth::user()->name])` | `TptVehicleFuelController.php:52-55` |
| 18 | Verify redirect | Redirected to `route('transport.vehicle-mgmt.index')` | `TptVehicleFuelController.php:57-58` |
| 19 | Verify flash message | Flash `success` = `flash('created.vehicle_fuel')` | `TptVehicleFuelController.php:59` |
| 20 | Verify DB record | `SELECT * FROM tpt_vehicle_fuel ORDER BY id DESC LIMIT 1` → record exists with all input values | — |

### TC-P04: Create Fuel Entry With Optional Fields

| Step # | Action | Expected Result | Code Trace |
|--------|--------|-----------------|------------|
| 1 | Navigate to `/vehicle-fuel/create` | Create form loads | `TptVehicleFuelController.php:33-41` |
| 2 | Fill required fields | vehicle_id=valid, date=today, quantity=50.000, cost=2000.00, fuel_type=valid | Required fields filled |
| 3 | Select Driver | Select driver from `select[name=driver_id]` | `create.blade.php:57-65` |
| 4 | Fill Odometer Reading | Enter 45000 in `input[name=odometer_reading]` | `create.blade.php:128-136` |
| 5 | Fill Remarks | Enter "Regular fueling" in `textarea[name=remarks]` | `create.blade.php:143-146` |
| 6 | Submit form | POST `/vehicle-fuel` | — |
| 7 | Verify validation: driver_id nullable | `nullable, exists:tpt_personnel,id` — optional field | `TptVehicleFuelRequest.php:29-32` |
| 8 | Verify validation: odometer_reading nullable+integer+min:0 | 45000 passes all rules | `TptVehicleFuelRequest.php:51-55` |
| 9 | Verify validation: remarks nullable+string+max:512 | "Regular fueling" (15 chars) passes max:512 | `TptVehicleFuelRequest.php:56-60` |
| 10 | Verify DB has driver_id | `SELECT driver_id FROM tpt_vehicle_fuel WHERE id=X` → matches selected driver | — |
| 11 | Verify DB has odometer_reading | `SELECT odometer_reading` → 45000 | — |
| 12 | Verify DB has remarks | `SELECT remarks` → "Regular fueling" | — |

### TC-P05: View Fuel Entry Details

| Step # | Action | Expected Result | Code Trace |
|--------|--------|-----------------|------------|
| 1 | Create a fuel entry with known values | Entry id=X exists | — |
| 2 | Click View icon on the entry | GET `/vehicle-fuel/{id}` | Route model-binding |
| 3 | Verify Gate | `Gate::authorize('tenant.vehicle-fuel.view')` passes | `TptVehicleFuelController.php:67` |
| 4 | Verify view | `transport::vehicle_fuel.show` loaded with `$vehicleFuel` | `TptVehicleFuelController.php:69` |
| 5 | Verify Vehicle displayed | `$vehicleFuel->vehicle->vehicle_no` shown | `show.blade.php:31` |
| 6 | Verify Driver displayed | `$vehicleFuel->driver->name` shown (or '-') | `show.blade.php:38` |
| 7 | Verify Fuel Date displayed | `\Carbon\Carbon::parse($vehicleFuel->date)->format('d M Y')` | `show.blade.php:44-48` |
| 8 | Verify Fuel Type displayed | `$vehicleFuel->fuelType->value` (or '-') | `show.blade.php:55-57` |
| 9 | Verify Quantity displayed | With "Liters" suffix | `show.blade.php:63-64` |
| 10 | Verify Cost displayed | ₹ formatted with 2 decimals | `show.blade.php:70-71` |
| 11 | Verify Odometer displayed | With "KM" suffix (or '-') | `show.blade.php:77-78` |
| 12 | Verify Remarks displayed | Literal text (or '-') | `show.blade.php:84-85` |
| 13 | Verify Status displayed | Current ENUM value | `show.blade.php:92` |
| 14 | Verify Created At displayed | `format('d M Y, h:i A')` | `show.blade.php:99` |
| 15 | Verify Updated At displayed | `format('d M Y, h:i A')` | `show.blade.php:106` |
| 16 | Verify Back button | Link to `route('transport.vehicle-mgmt.index')` | `show.blade.php:12` |
| 17 | Verify Edit button | Link to `route('transport.vehicle-fuel.edit', $vehicleFuel->id)` | `show.blade.php:15` |

### TC-P06: Edit Fuel Entry Loads Pre-Filled Data

| Step # | Action | Expected Result | Code Trace |
|--------|--------|-----------------|------------|
| 1 | Create fuel entry with known values | id=X, vehicle_id=1, driver_id=2, date=2026-07-21, quantity=50.000, cost=2000.00, fuel_type=1, odometer=45000, remarks="test" | — |
| 2 | Click Edit icon | GET `/vehicle-fuel/{id}/edit` | Route model-binding |
| 3 | Verify Gate | `Gate::authorize('tenant.vehicle-fuel.update')` passes | `TptVehicleFuelController.php:77` |
| 4 | Verify vehicles loaded | `$vehicles = Vehicle::active()->get()` | `TptVehicleFuelController.php:79` |
| 5 | Verify drivers loaded | `$drivers = DriverHelper::active()->get()` | `TptVehicleFuelController.php:80` |
| 6 | Verify vehicle_id pre-selected | `old('vehicle_id', $vehicleFuel->vehicle_id)` selected | `edit.blade.php:43` |
| 7 | Verify driver_id pre-selected | `old('driver_id', $vehicleFuel->driver_id)` selected | `edit.blade.php:63` |
| 8 | Verify date pre-filled | `old('date', Carbon::parse($vehicleFuel->date)->format('Y-m-d'))` | `edit.blade.php:82` |
| 9 | Verify quantity pre-filled | `old('quantity', $vehicleFuel->quantity)` | `edit.blade.php:98` |
| 10 | Verify cost pre-filled | `old('cost', $vehicleFuel->cost)` | `edit.blade.php:111` |
| 11 | Verify fuel_type pre-selected | `old('fuel_type', $vehicleFuel->fuel_type)` | `edit.blade.php:120` |
| 12 | Verify odometer pre-filled | `old('odometer_reading', $vehicleFuel->odometer_reading)` | `edit.blade.php:136` |
| 13 | Verify remarks pre-filled | `old('remarks', $vehicleFuel->remarks)` | `edit.blade.php:147` |
| 14 | Verify status pre-selected | `old('status', $vehicleFuel->status)` matches one of 3 ENUM options | `edit.blade.php:163-172` |

### TC-P07: Update Fuel Entry — Change Quantity and Cost

| Step # | Action | Expected Result | Code Trace |
|--------|--------|-----------------|------------|
| 1 | Create fuel entry: quantity=50.000, cost=2000.00 | id=X | — |
| 2 | Edit form → change quantity to 75.000 and cost to 3000.00 | Form fields updated | — |
| 3 | Submit PUT `/vehicle-fuel/{id}` | Form action: PUT to update route | `edit.blade.php:25-27` |
| 4 | Verify Request authorization | `Gate::allows('tenant.vehicle-fuel.update')` for PUT | `TptVehicleFuelRequest.php:15-16` |
| 5 | Verify Controller Gate | `Gate::authorize('tenant.vehicle-fuel.update')` | `TptVehicleFuelController.php:90` |
| 6 | Verify `getOriginal()` captured | `$original = $vehicleFuel->getOriginal()` before update | `TptVehicleFuelController.php:93` |
| 7 | Verify `update()` called | `$vehicleFuel->update($request->validated())` | `TptVehicleFuelController.php:94` |
| 8 | Verify `getChanges()` captured | `$changes = $vehicleFuel->getChanges()` after update | `TptVehicleFuelController.php:96` |
| 9 | Verify change tracking: quantity old→new | `$changedAttributes['quantity'] = ['old' => '50.000', 'new' => '75.000']` | `TptVehicleFuelController.php:99-106` |
| 10 | Verify change tracking: cost old→new | `$changedAttributes['cost'] = ['old' => '2000.00', 'new' => '3000.00']` | — |
| 11 | Verify `updated_at` excluded from changes | `if ($field === 'updated_at') continue;` | `TptVehicleFuelController.php:100` |
| 12 | Verify activity log with changes | `activityLog($vehicleFuel, 'Updated', ['changes' => $changedAttributes])` | `TptVehicleFuelController.php:108-112` |
| 13 | Verify redirect | `->route('transport.vehicle-mgmt.index')` | `TptVehicleFuelController.php:114-115` |
| 14 | Verify flash | `flash('updated.vehicle_fuel')` | `TptVehicleFuelController.php:116` |
| 15 | Verify DB updated | `SELECT quantity, cost FROM tpt_vehicle_fuel WHERE id=X` → 75.000, 3000.00 | — |

### TC-P08: Update Fuel Entry — No Changes Submitted

| Step # | Action | Expected Result | Code Trace |
|--------|--------|-----------------|------------|
| 1 | Create fuel entry: quantity=50.000, cost=2000.00 | id=X | — |
| 2 | Edit form → submit WITHOUT changing any values | PUT with same data | — |
| 3 | Verify `getOriginal()` captured | `$original` has current values | `TptVehicleFuelController.php:93` |
| 4 | Verify `update()` called with same values | `$vehicleFuel->update($request->validated())` | `TptVehicleFuelController.php:94` |
| 5 | Verify `getChanges()` returns empty array | No fields actually changed | `TptVehicleFuelController.php:96` |
| 6 | Verify `$changedAttributes` is empty array | `foreach` has no iterations | `TptVehicleFuelController.php:99-106` |
| 7 | Verify `$changedAttributes ?: null` → null | Empty array evaluates to false → null passed | `TptVehicleFuelController.php:110` |
| 8 | Verify activity log with changes=null | `activityLog($vehicleFuel, 'Updated', ['changes' => null])` | — |
| 9 | Verify success flash | Still shows success even though nothing changed | `TptVehicleFuelController.php:116` |
| 10 | DB check: `updated_at` may have changed | `useCurrentOnUpdate()` updates timestamp even if data same | Migration line 24 |

### TC-P09: Soft Delete Fuel Entry

| Step # | Action | Expected Result | Code Trace |
|--------|--------|-----------------|------------|
| 1 | Create fuel entry with known values | id=X, deleted_at=NULL | — |
| 2 | Click Delete icon on the entry | DELETE `/vehicle-fuel/{id}` | Route model-binding |
| 3 | Verify Gate | `Gate::authorize('tenant.vehicle-fuel.delete')` | `TptVehicleFuelController.php:124` |
| 4 | Verify `delete()` called | `$vehicleFuel->delete()` — SoftDeletes sets deleted_at | `TptVehicleFuelController.php:126` |
| 5 | Verify no is_active toggle | No `is_active` column exists on fuel table (DDL has none) | Migration has no is_active column |
| 6 | Verify activity log | `activityLog($vehicleFuel, 'Trashed', ['message' => 'Vehicle fuel entry trashed.'])` | `TptVehicleFuelController.php:128-131` |
| 7 | Verify redirect | `->route('transport.vehicle-mgmt.index')` | `TptVehicleFuelController.php:133-134` |
| 8 | Verify flash | `flash('trashed.vehicle_fuel')` | `TptVehicleFuelController.php:135` |
| 9 | Verify DB: deleted_at set | `SELECT deleted_at FROM tpt_vehicle_fuel WHERE id=X` → IS NOT NULL | — |
| 10 | Verify entry hidden from main list | GET `/vehicle-fuel` → entry NOT visible (default scope excludes soft-deleted) | — |
| 11 | Verify entry visible in trash | GET `/vehicle-fuel/trash/view` → entry visible | `TptVehicleFuelController.php:145-147` |

### TC-P10: Trash Page Shows Deleted Entries

| Step # | Action | Expected Result | Code Trace |
|--------|--------|-----------------|------------|
| 1 | Soft-delete at least 1 fuel entry | id=X, deleted_at set | — |
| 2 | Navigate to Trash | GET `/vehicle-fuel/trash/view` | `web.php:251` |
| 3 | Verify Gate | `Gate::authorize('tenant.vehicle-fuel.restore')` | `TptVehicleFuelController.php:143` |
| 4 | Verify query | `TptVehicleFuel::onlyTrashed()->latest('deleted_at')->paginate(10)` | `TptVehicleFuelController.php:145-147` |
| 5 | Verify pagination | `$fuelEntries->links()` renders paginator | `trash.blade.php:63` |
| 6 | Verify table columns | Vehicle, Driver, Fuel Date, Fuel Type, Quantity, Cost, Action | `trash.blade.php:15-23` |
| 7 | Verify action buttons | Restore + Force Delete via `x-backend.table.action-trashed` | `trash.blade.php:47-50` |
| 8 | Verify vehicle displayed | `$fuel->vehicle?->vehicle_no ?? 'N/A'` — null-safe operator | `trash.blade.php:28` |
| 9 | Verify driver displayed | `$fuel->driver?->name ?? 'N/A'` — null-safe | `trash.blade.php:30` |
| 10 | Verify date format | `\Carbon\Carbon::parse($fuel->date)->format('d M Y')` | `trash.blade.php:33` |
| 11 | Verify empty state | No trashed records → "No Data Found" | `trash.blade.php:54-56` |

### TC-P11: Restore Fuel Entry From Trash

| Step # | Action | Expected Result | Code Trace |
|--------|--------|-----------------|------------|
| 1 | Ensure fuel entry id=X is soft-deleted | deleted_at IS NOT NULL | — |
| 2 | Click Restore on trashed entry | GET `/vehicle-fuel/{id}/restore` | `web.php:252` |
| 3 | Verify Gate | `Gate::authorize('tenant.vehicle-fuel.restore')` | `TptVehicleFuelController.php:157` |
| 4 | Verify query | `TptVehicleFuel::onlyTrashed()->findOrFail($id)` — must be trashed | `TptVehicleFuelController.php:159` |
| 5 | Verify `restore()` called | `$fuelEntry->restore()` — sets deleted_at=NULL | `TptVehicleFuelController.php:160` |
| 6 | Verify activity log | `activityLog($fuelEntry, 'Restored', ['message' => 'Vehicle fuel entry restored.'])` | `TptVehicleFuelController.php:162-165` |
| 7 | Verify redirect | `->route('transport.vehicle-mgmt.index')` | `TptVehicleFuelController.php:167-168` |
| 8 | Verify flash | `flash('restored.vehicle_fuel')` | `TptVehicleFuelController.php:169` |
| 9 | Verify DB: deleted_at=NULL | `SELECT deleted_at FROM tpt_vehicle_fuel WHERE id=X` → NULL | — |
| 10 | Verify entry visible in main list | GET `/vehicle-fuel` → entry visible again | — |
| 11 | Verify entry removed from trash | GET `/vehicle-fuel/trash/view` → entry NOT visible | — |

### TC-P12: Force Delete Fuel Entry

| Step # | Action | Expected Result | Code Trace |
|--------|--------|-----------------|------------|
| 1 | Ensure fuel entry id=X exists (can be active or trashed) | Record exists | — |
| 2 | Click Force Delete on entry (from trash) | DELETE `/vehicle-fuel/{id}/force-delete` | `web.php:253` |
| 3 | Verify Gate | `Gate::authorize('tenant.vehicle-fuel.forceDelete')` | `TptVehicleFuelController.php:177` |
| 4 | Verify query | `TptVehicleFuel::withTrashed()->findOrFail($id)` — finds active AND trashed | `TptVehicleFuelController.php:179` |
| 5 | Verify `forceDelete()` called | `$fuelEntry->forceDelete()` — removes from DB permanently | `TptVehicleFuelController.php:180` |
| 6 | Verify activity log | `activityLog($fuelEntry, 'Deleted', ['message' => 'Vehicle fuel entry permanently deleted.'])` | `TptVehicleFuelController.php:182-185` |
| 7 | Verify redirect | `->route('transport.vehicle-mgmt.index')` | `TptVehicleFuelController.php:187-188` |
| 8 | Verify flash | `flash('force_deleted.vehicle_fuel')` | `TptVehicleFuelController.php:189` |
| 9 | Verify DB: record gone | `SELECT * FROM tpt_vehicle_fuel WHERE id=X` → 0 rows (withTrashed also returns nothing) | — |
| 10 | Verify can force-delete non-trashed record | `withTrashed()` finds it → forceDelete works on active records too | `TptVehicleFuelController.php:179` |

### TC-P13: Approve Fuel Entry via AJAX

| Step # | Action | Expected Result | Code Trace |
|--------|--------|-----------------|------------|
| 1 | Create a fuel entry with status=Pending | Entry created, status='Pending' | — |
| 2 | POST `/vehicle-fuel/{id}/update-status` with `status=Approved` | AJAX request | `web.php:254` |
| 3 | Verify Gate | `Gate::authorize('tenant.vehicle-fuel.approve')` | `TptVehicleFuelController.php:197` |
| 4 | Verify inline validation | `$request->validate(['status' => 'required|in:Approved,Rejected,Pending'])` | `TptVehicleFuelController.php:199-201` |
| 5 | Verify status set | `$vehicleFuel->status = $request->status` | `TptVehicleFuelController.php:203` |
| 6 | Verify `save()` returns true | `$vehicleFuel->save()` → true | `TptVehicleFuelController.php:205` |
| 7 | Verify activity log | `activityLog($vehicleFuel, 'StatusUpdated', ['message' => "Fuel status changed to Approved."])` | `TptVehicleFuelController.php:206-209` |
| 8 | Verify JSON response | `{success: true, status: 'Approved', message: 'Status updated successfully.'}` HTTP 200 | `TptVehicleFuelController.php:211-215` |
| 9 | Verify DB status changed | `SELECT status FROM tpt_vehicle_fuel WHERE id={id}` → 'Approved' | — |
| 10 | Check activity_log table | Event='StatusUpdated', properties.message = "Fuel status changed to Approved." | — |

### TC-P14: Reject Fuel Entry via AJAX

| Step # | Action | Expected Result | Code Trace |
|--------|--------|-----------------|------------|
| 1 | Create fuel entry with status=Pending | id=X, status='Pending' | — |
| 2 | POST `/vehicle-fuel/{id}/update-status` with `status=Rejected` | AJAX request | — |
| 3 | Verify validation | `required|in:Approved,Rejected,Pending` — 'Rejected' valid | `TptVehicleFuelController.php:201` |
| 4 | Verify status set to 'Rejected' | `$vehicleFuel->status = 'Rejected'` | `TptVehicleFuelController.php:203` |
| 5 | Verify JSON response | `{success: true, status: 'Rejected', message: 'Status updated successfully.'}` | `TptVehicleFuelController.php:211-215` |
| 6 | Verify DB | `SELECT status FROM tpt_vehicle_fuel WHERE id={id}` → 'Rejected' | — |
| 7 | Verify activity log | "Fuel status changed to Rejected." | `TptVehicleFuelController.php:206-209` |

### TC-P15: Filter Fuel Entries By Status (VehicleMgmt tab)

| Step # | Action | Expected Result | Code Trace |
|--------|--------|-----------------|------------|
| 1 | Ensure entries exist with different statuses | At least 1 Approved, 1 Rejected, 1 Pending | — |
| 2 | Navigate to VehicleMgmt → Fuel tab | `/vehicle-mgmt` with fuel tab active | — |
| 3 | Select "Active" from status dropdown (value=1) | URL param `?status=1` | `index.blade.php:15` |
| 4 | Click Search | GET with `status=1` | — |
| 5 | BUG: fuelEntryQuery runs `WHERE status = '1'` | No ENUM '1' exists → 0 results | `VehicleMgmtController.php:114-116` |
| 6 | Select "Inactive" from status dropdown (value=0) | URL param `?status=0` | `index.blade.php:16` |
| 7 | BUG: Same — `WHERE status = '0'` | No ENUM '0' → 0 results | `VehicleMgmtController.php:114-116` |
| 8 | Select "All" (value="") | No status filter applied → all entries shown | `index.blade.php:14` |
| 9 | Workaround: Manually append `?status=Approved` | URL `/vehicle-mgmt?status=Approved` → filters correctly | Valid ENUM value |
| 10 | Verify `withQueryString()` preserves filter | Pagination links include `&status=Approved` | `VehicleMgmtController.php:43` |



### TC-P16: Search Fuel Entries By Vehicle Registration No

| Step # | Action | Expected Result | Code Trace |
|--------|--------|-----------------|------------|
| 1 | Ensure fuel entry exists for vehicle with registration_no "ABC-1234" | Fuel entry associated | — |
| 2 | Navigate to VehicleMgmt → Fuel tab | Fuel tab active | — |
| 3 | Enter "ABC" in search input | `search=ABC` in URL | `index.blade.php:10-11` |
| 4 | Click Search | GET `/vehicle-mgmt?search=ABC` | — |
| 5 | Verify search query | `whereHas('vehicle', fn($v) => $v->where('registration_no', 'LIKE', '%ABC%'))` | `VehicleMgmtController.php:104-107` |
| 6 | Verify matching entry displayed | Vehicle "ABC-1234" entry visible in table | — |
| 7 | Verify non-matching entries hidden | Vehicles without "ABC" in reg_no not shown | — |
| 8 | Verify search cleared with Reset button | Click reset → URL params cleared, all entries shown | `index.blade.php:22-24` |

### TC-P17: Search Fuel Entries By Driver Name

| Step # | Action | Expected Result | Code Trace |
|--------|--------|-----------------|------------|
| 1 | Ensure fuel entry exists for driver with name "John Doe" | Fuel entry with driver_id set | — |
| 2 | Navigate to VehicleMgmt → Fuel tab | Fuel tab active | — |
| 3 | Enter "John" in search input | `search=John` in URL | — |
| 4 | Click Search | GET `/vehicle-mgmt?search=John` | — |
| 5 | Verify search query includes driver name | `orWhereHas('driver', fn($d) => $d->where('name', 'LIKE', '%John%'))` | `VehicleMgmtController.php:108-110` |
| 6 | Verify matching entry displayed | "John Doe" entry visible | — |
| 7 | Verify entries without "John" in driver name not shown | Others filtered out | — |

### TC-P18: Full Lifecycle

| Step # | Action | Expected Result | Code Trace |
|--------|--------|-----------------|------------|
| 1 | Create fuel entry | POST `/vehicle-fuel` → entry created (id=X, status=Pending) | TC-P03 flow |
| 2 | View entry | GET `/vehicle-fuel/{id}` → details page with all fields | TC-P05 flow |
| 3 | Edit entry — change quantity+cost | PUT `/vehicle-fuel/{id}` → updated, changes logged | TC-P07 flow |
| 4 | Approve entry via AJAX | POST updateStatus with status=Approved → JSON success | TC-P13 flow |
| 5 | Soft delete entry | DELETE `/vehicle-fuel/{id}` → trashed | TC-P09 flow |
| 6 | View in trash | GET `/vehicle-fuel/trash/view` → entry visible | TC-P10 flow |
| 7 | Restore entry | GET `/vehicle-fuel/{id}/restore` → restored | TC-P11 flow |
| 8 | Verify entry back in main list | GET `/vehicle-fuel` → entry visible, status=Approved | — |
| 9 | Force delete entry | DELETE `/vehicle-fuel/{id}/force-delete` → permanently gone | TC-P12 flow |
| 10 | Verify entry gone | GET `/vehicle-fuel/{id}` → 404 | — |

### TC-P19: Empty State — No Fuel Entries

| Step # | Action | Expected Result | Code Trace |
|--------|--------|-----------------|------------|
| 1 | Ensure no fuel entries exist | `TptVehicleFuel::count()` = 0 | — |
| 2 | Navigate to VehicleMgmt → Fuel tab | Tab loads with empty table | — |
| 3 | Check table body | `@forelse` → `@empty` branch triggered | `index.blade.php:47,68-71` |
| 4 | Verify "No Data Found" message | `<td colspan="8" class="text-center">No Data Found</td>` | `index.blade.php:70` |
| 5 | Navigate to standalone `/vehicle-fuel` | Same empty state display (same blade file) | Same `index.blade.php` |

### TC-P20: Pagination — Entries Exceed First Page

| Step # | Action | Expected Result | Code Trace |
|--------|--------|-----------------|------------|
| 1 | Create 11+ fuel entries | 11+ records exist | — |
| 2 | Navigate to standalone `/vehicle-fuel` | First 10 entries shown, pagination links visible | `TptVehicleFuelController.php:25` → `paginate(10)` |
| 3 | Verify paginator | `$fuelEntries->links()` renders pagination nav | `index.blade.php:76` |
| 4 | Click page 2 | GET `/vehicle-fuel?page=2` → entries 11+ shown | — |
| 5 | Verify VehicleMgmt tab pagination | `/vehicle-mgmt` → same 10/page via `withQueryString()` | `VehicleMgmtController.php:43` |

### TC-P21: Activity Log — Create Fuel Entry

| Step # | Action | Expected Result | Code Trace |
|--------|--------|-----------------|------------|
| 1 | Create a fuel entry via POST `/vehicle-fuel` | Entry created, id=X | — |
| 2 | Query `activity_log` table | `SELECT * FROM activity_log WHERE subject_id = X AND event = 'Stored'` | — |
| 3 | Verify row exists | 1 row returned | `TptVehicleFuelController.php:52-55` |
| 4 | Verify `properties` contains `message` | `"message": "Vehicle fuel entry created."` | — |
| 5 | Verify `properties` contains `performed_by` | `"performed_by": "<auth user name>"` | — |
| 6 | Verify `properties` contains `subject_type` | Subject type = `Modules\Transport\Models\TptVehicleFuel` | Default activitylog behavior |

### TC-P22: Activity Log — Update Fuel Entry (With Changes)

| Step # | Action | Expected Result | Code Trace |
|--------|--------|-----------------|------------|
| 1 | Create fuel entry: quantity=10.000, cost=500.00 | id=X | — |
| 2 | PUT `/vehicle-fuel/{id}` with quantity=15.000, cost=750.00 | Entry updated | — |
| 3 | Query `activity_log` | `WHERE subject_id = X AND event = 'Updated'` | — |
| 4 | Verify `properties.changes` has quantity | `"quantity": {"old": "10.000", "new": "15.000"}` | `TptVehicleFuelController.php:102-105` |
| 5 | Verify `properties.changes` has cost | `"cost": {"old": "500.00", "new": "750.00"}` | — |
| 6 | Verify `updated_at` NOT in changes | `$field !== 'updated_at'` check | `TptVehicleFuelController.php:100` |
| 7 | Verify `performed_by` present | Auth user name in properties | `TptVehicleFuelController.php:111` |

### TC-P23: Activity Log — Update Fuel Entry (No Changes)

| Step # | Action | Expected Result | Code Trace |
|--------|--------|-----------------|------------|
| 1 | Create fuel entry: quantity=10.000, cost=500.00 | id=X | — |
| 2 | PUT `/vehicle-fuel/{id}` with EXACT same values | No actual changes | — |
| 3 | Query `activity_log` for 'Updated' event | Row exists | — |
| 4 | Verify `properties.changes` is null | `$changedAttributes ?: null` → null | `TptVehicleFuelController.php:110` |
| 5 | Verify `properties` still has `message` | `"message": "Vehicle fuel entry updated."` | — |

### TC-P24: Activity Log — Soft Delete Fuel Entry

| Step # | Action | Expected Result | Code Trace |
|--------|--------|-----------------|------------|
| 1 | Create fuel entry id=X | Entry exists | — |
| 2 | DELETE `/vehicle-fuel/{id}` | Soft deleted | — |
| 3 | Query `activity_log` | `WHERE subject_id = X AND event = 'Trashed'` | `TptVehicleFuelController.php:128-131` |
| 4 | Verify `properties.message` | `"message": "Vehicle fuel entry trashed."` | — |
| 5 | Verify `performed_by` present | Auth user name | — |

### TC-P25: Activity Log — Restore Fuel Entry

| Step # | Action | Expected Result | Code Trace |
|--------|--------|-----------------|------------|
| 1 | Ensure fuel entry id=X is trashed | deleted_at IS NOT NULL | — |
| 2 | GET `/vehicle-fuel/{id}/restore` | Entry restored | — |
| 3 | Query `activity_log` | `WHERE subject_id = X AND event = 'Restored'` | `TptVehicleFuelController.php:162-165` |
| 4 | Verify `properties.message` | `"message": "Vehicle fuel entry restored."` | — |

### TC-P26: Activity Log — Force Delete Fuel Entry

| Step # | Action | Expected Result | Code Trace |
|--------|--------|-----------------|------------|
| 1 | Ensure fuel entry id=X exists (any state) | Record exists | — |
| 2 | DELETE `/vehicle-fuel/{id}/force-delete` | Permanently deleted | — |
| 3 | Query `activity_log` before force delete | Capture log entry before record destroyed | — |
| 4 | Verify `event = 'Deleted'` | `activityLog($fuelEntry, 'Deleted', ...)` | `TptVehicleFuelController.php:182-185` |
| 5 | Verify `properties.message` | `"message": "Vehicle fuel entry permanently deleted."` | — |

### TC-P27: Activity Log — Status Update (Approve/Reject)

| Step # | Action | Expected Result | Code Trace |
|--------|--------|-----------------|------------|
| 1 | Create fuel entry with status=Pending | id=X | — |
| 2 | POST updateStatus with status=Approved | AJAX success | — |
| 3 | Query `activity_log` | `WHERE subject_id = X AND event = 'StatusUpdated'` | `TptVehicleFuelController.php:206-209` |
| 4 | Verify `properties.message` | `"message": "Fuel status changed to Approved."` | — |
| 5 | Repeat with status=Rejected | New StatusUpdated entry with "changed to Rejected." | — |

### TC-P28: Create Fuel Entry With quantity=0.001 (Min Boundary)

| Step # | Action | Expected Result | Code Trace |
|--------|--------|-----------------|------------|
| 1 | Create fuel entry with quantity=0.001 | Minimum valid value | — |
| 2 | Verify validation `min:0.001` passes | `0.001 >= 0.001` → OK | `TptVehicleFuelRequest.php:40` |
| 3 | Verify DB stores 0.001 | `DECIMAL(10,3)` → stored as 0.001 | — |
| 4 | Verify model cast returns 0.001 | `$casts = ['quantity' => 'decimal:3']` | `TptVehicleFuel.php:51` |

### TC-P29: Create Fuel Entry With cost=0 (Min Boundary)

| Step # | Action | Expected Result | Code Trace |
|--------|--------|-----------------|------------|
| 1 | Create fuel entry with cost=0 | Minimum valid value | — |
| 2 | Verify validation `min:0` passes | `0 >= 0` → OK | `TptVehicleFuelRequest.php:45` |
| 3 | Verify DB stores 0.00 | `DECIMAL(12,2)` → stored as 0.00 | — |

### TC-P30: Fuel Entry With NULL driver_id Created Successfully

| Step # | Action | Expected Result | Code Trace |
|--------|--------|-----------------|------------|
| 1 | Create fuel entry, leave driver_id empty | driver_id not sent or sent as empty | — |
| 2 | Verify `nullable` validation passes | `nullable, exists:tpt_personnel,id` → NULL allowed | `TptVehicleFuelRequest.php:29-32` |
| 3 | Verify DB: driver_id=NULL | `SELECT driver_id` → NULL | — |
| 4 | Verify index shows '-' for driver | `{{ optional($fuel->driver)->name ?? '-' }}` | `index.blade.php:51` |

### TC-P31: Standalone Index Paginates Correctly

| Step # | Action | Expected Result | Code Trace |
|--------|--------|-----------------|------------|
| 1 | Create 12 fuel entries | 12 records exist | — |
| 2 | GET `/vehicle-fuel` | Page 1: 10 entries, pagination with 2 pages | `TptVehicleFuelController.php:23-25` |
| 3 | GET `/vehicle-fuel?page=2` | Page 2: 2 entries | — |
| 4 | Verify `->paginate(10)` | 10 per page | `TptVehicleFuelController.php:25` |

### TC-P32: Create Fuel Entry Sets Default status='Pending'

| Step # | Action | Expected Result | Code Trace |
|--------|--------|-----------------|------------|
| 1 | Create fuel entry WITHOUT sending status field | No status in request | — |
| 2 | Verify `status` Rule::in not `required` | Validation passes without status | `TptVehicleFuelRequest.php:62-64` |
| 3 | Verify model default applies | `$attributes = ['status' => 'Pending']` | `TptVehicleFuel.php:42-44` |
| 4 | Verify DB: status = 'Pending' | `SELECT status` → 'Pending' | — |

### TC-P33: VehicleMgmt Tab Paginates With Query String

| Step # | Action | Expected Result | Code Trace |
|--------|--------|-----------------|------------|
| 1 | Ensure many fuel entries exist | 15+ entries with various statuses | — |
| 2 | Navigate to `/vehicle-mgmt` | Fuel tab loads with first 10 entries | — |
| 3 | Click page 2 | URL: `/vehicle-mgmt?page=2` — entries 11+ shown | — |
| 4 | Apply status=Approved filter, go to page 2 | URL: `/vehicle-mgmt?status=Approved&page=2` | `VehicleMgmtController.php:43` — `withQueryString()` preserves filter |

### TC-P34: Activity Log — performed_by Is Auth User Name

| Step # | Action | Expected Result | Code Trace |
|--------|--------|-----------------|------------|
| 1 | Login as user "Admin User" | Auth user name = "Admin User" | — |
| 2 | Create fuel entry | 'Stored' event logged | — |
| 3 | Query activity_log | `properties.performed_by` = "Admin User" | `TptVehicleFuelController.php:54` |
| 4 | Repeat for update, delete, restore, force-delete, status-update | All have `performed_by` with same user name | Throughout controller |

### TC-P35: Update Status Back From Approved To Pending

| Step # | Action | Expected Result | Code Trace |
|--------|--------|-----------------|------------|
| 1 | Create fuel entry, approve it | status='Approved' | — |
| 2 | POST updateStatus with `status=Pending` | Revert to pending | — |
| 3 | Verify validation accepts Pending | `in:Approved,Rejected,Pending` — Pending valid | `TptVehicleFuelController.php:201` |
| 4 | Verify JSON success | `{success: true, status: 'Pending'}` | — |
| 5 | Verify DB | `SELECT status` → 'Pending' | — |
| 6 | Verify activity log | "Fuel status changed to Pending." | — |

### TC-N01: Required — Missing vehicle_id

| Step # | Action | Expected Result | Code Trace |
|--------|--------|-----------------|------------|
| 1 | POST `/vehicle-fuel` with ALL fields except `vehicle_id` | vehicle_id omitted | — |
| 2 | Verify validation fails | `'vehicle_id' => ['required', 'exists:tpt_vehicle,id']` | `TptVehicleFuelRequest.php:25-28` |
| 3 | Verify error message | "The vehicle id field is required." | Default Laravel message |
| 4 | Verify redirect back with errors | Form re-displayed with error alert | `create.blade.php:14-21` |

### TC-N02: Required — Missing date

| Step # | Action | Expected Result | Code Trace |
|--------|--------|-----------------|------------|
| 1 | POST with all fields except `date` | date omitted | — |
| 2 | Verify `'date' => ['required', 'date']` fails | "The date field is required." | `TptVehicleFuelRequest.php:33-36` |

### TC-N03: Required — Missing quantity

| Step # | Action | Expected Result | Code Trace |
|--------|--------|-----------------|------------|
| 1 | POST with all fields except `quantity` | quantity omitted | — |
| 2 | Verify `'quantity' => ['required', 'numeric', 'min:0.001']` fails | "The quantity field is required." | `TptVehicleFuelRequest.php:37-41` |

### TC-N04: Required — Missing cost

| Step # | Action | Expected Result | Code Trace |
|--------|--------|-----------------|------------|
| 1 | POST with all fields except `cost` | cost omitted | — |
| 2 | Verify `'cost' => ['required', 'numeric', 'min:0']` fails | "The cost field is required." | `TptVehicleFuelRequest.php:42-46` |

### TC-N05: Required — Missing fuel_type

| Step # | Action | Expected Result | Code Trace |
|--------|--------|-----------------|------------|
| 1 | POST with all fields except `fuel_type` | fuel_type omitted | — |
| 2 | Verify `'fuel_type' => ['required']` fails | "The fuel type field is required." | `TptVehicleFuelRequest.php:47-49` |

### TC-N06: Invalid vehicle_id — Non-Existent Vehicle

| Step # | Action | Expected Result | Code Trace |
|--------|--------|-----------------|------------|
| 1 | POST with `vehicle_id=99999` (non-existent) | Invalid ID | — |
| 2 | Verify `exists:tpt_vehicle,id` fails | "The selected vehicle id is invalid." | `TptVehicleFuelRequest.php:27` |

### TC-N07: Invalid driver_id — Non-Existent Driver

| Step # | Action | Expected Result | Code Trace |
|--------|--------|-----------------|------------|
| 1 | POST with `driver_id=99999` (non-existent) | Invalid ID | — |
| 2 | Verify `exists:tpt_personnel,id` fails | "The selected driver id is invalid." | `TptVehicleFuelRequest.php:31` |

### TC-N08: Invalid date Format

| Step # | Action | Expected Result | Code Trace |
|--------|--------|-----------------|------------|
| 1 | POST with `date="not-a-date"` | Invalid format | — |
| 2 | Verify `'date' => ['date']` fails | "The date is not a valid date." | `TptVehicleFuelRequest.php:35` |

### TC-N09: quantity = 0 (Below Minimum 0.001)

| Step # | Action | Expected Result | Code Trace |
|--------|--------|-----------------|------------|
| 1 | POST with `quantity=0` | Below minimum | — |
| 2 | Verify `'quantity' => ['min:0.001']` fails | "The quantity must be at least 0.001." | `TptVehicleFuelRequest.php:40` |

### TC-N10: quantity Negative Value

| Step # | Action | Expected Result | Code Trace |
|--------|--------|-----------------|------------|
| 1 | POST with `quantity=-5` | Negative value | — |
| 2 | Verify `['numeric', 'min:0.001']` fails | "The quantity must be at least 0.001." | `TptVehicleFuelRequest.php:39-40` |

### TC-N11: quantity Non-Numeric String

| Step # | Action | Expected Result | Code Trace |
|--------|--------|-----------------|------------|
| 1 | POST with `quantity="abc"` | Non-numeric | — |
| 2 | Verify `['numeric']` fails | "The quantity must be a number." | `TptVehicleFuelRequest.php:39` |

### TC-N12: cost = Negative Value

| Step # | Action | Expected Result | Code Trace |
|--------|--------|-----------------|------------|
| 1 | POST with `cost=-100` | Negative cost | — |
| 2 | Verify `['numeric', 'min:0']` fails | "The cost must be at least 0." | `TptVehicleFuelRequest.php:44-45` |

### TC-N13: cost Non-Numeric

| Step # | Action | Expected Result | Code Trace |
|--------|--------|-----------------|------------|
| 1 | POST with `cost="xyz"` | Non-numeric | — |
| 2 | Verify `['numeric']` fails | "The cost must be a number." | `TptVehicleFuelRequest.php:44` |

### TC-N14: odometer_reading Negative

| Step # | Action | Expected Result | Code Trace |
|--------|--------|-----------------|------------|
| 1 | POST with `odometer_reading=-100` | Negative | — |
| 2 | Verify `['integer', 'min:0']` fails | "The odometer reading must be at least 0." | `TptVehicleFuelRequest.php:53-54` |

### TC-N15: odometer_reading Non-Integer

| Step # | Action | Expected Result | Code Trace |
|--------|--------|-----------------|------------|
| 1 | POST with `odometer_reading=45.5` | Float, not integer | — |
| 2 | Verify `['integer']` fails | "The odometer reading must be an integer." | `TptVehicleFuelRequest.php:53` |

### TC-N16: remarks Exceeds 512 Characters

| Step # | Action | Expected Result | Code Trace |
|--------|--------|-----------------|------------|
| 1 | POST with `remarks` = 513 character string | Exceeds max | — |
| 2 | Verify `['string', 'max:512']` fails | "The remarks must not be greater than 512 characters." | `TptVehicleFuelRequest.php:58-59` |

### TC-N17: Invalid Status Value in updateStatus

| Step # | Action | Expected Result | Code Trace |
|--------|--------|-----------------|------------|
| 1 | POST updateStatus with `status=InvalidStatus` | Not in allowed list | — |
| 2 | Verify inline validation | `required|in:Approved,Rejected,Pending` → 'InvalidStatus' rejected | `TptVehicleFuelController.php:201` |
| 3 | Verify error | "The selected status is invalid." | Default Laravel message |
| 4 | Verify HTTP 422 response | Validation error returns 422 | — |

### TC-N18: View With Invalid ID

| Step # | Action | Expected Result | Code Trace |
|--------|--------|-----------------|------------|
| 1 | GET `/vehicle-fuel/99999` | Non-existent ID | — |
| 2 | Route-model-binding resolves `TptVehicleFuel $vehicleFuel` | ModelNotFoundException | `TptVehicleFuelController.php:65` — implicit binding |
| 3 | Verify 404 response | HTTP 404 | Laravel automatic |

### TC-N19: Edit With Invalid ID

| Step # | Action | Expected Result | Code Trace |
|--------|--------|-----------------|------------|
| 1 | GET `/vehicle-fuel/99999/edit` | Non-existent ID | — |
| 2 | Route-model-binding → 404 | Same as show | `TptVehicleFuelController.php:75` |

### TC-N20: Update With Invalid ID

| Step # | Action | Expected Result | Code Trace |
|--------|--------|-----------------|------------|
| 1 | PUT `/vehicle-fuel/99999` | Non-existent ID | — |
| 2 | Route-model-binding → 404 | ModelNotFoundException | `TptVehicleFuelController.php:88` |

### TC-N21: Delete With Invalid ID

| Step # | Action | Expected Result | Code Trace |
|--------|--------|-----------------|------------|
| 1 | DELETE `/vehicle-fuel/99999` | Non-existent ID | — |
| 2 | Route-model-binding → 404 | ModelNotFoundException | `TptVehicleFuelController.php:122` |

### TC-N22: Restore Non-Deleted Entry

| Step # | Action | Expected Result | Code Trace |
|--------|--------|-----------------|------------|
| 1 | Create fuel entry (NOT deleted) | id=X, deleted_at=NULL | — |
| 2 | GET `/vehicle-fuel/{id}/restore` | Restore attempted | — |
| 3 | Verify `onlyTrashed()->findOrFail($id)` | `onlyTrashed()` filters to WHERE deleted_at IS NOT NULL | `TptVehicleFuelController.php:159` |
| 4 | Since deleted_at=NULL → not found | `findOrFail()` throws ModelNotFoundException | — |
| 5 | Verify 404 response | HTTP 404 | — |

### TC-N23: Permission 403 — No Fuel Permissions

| Step # | Action | Expected Result | Code Trace |
|--------|--------|-----------------|------------|
| 1 | Login as user with NO `tenant.vehicle-fuel.*` permissions | User has zero fuel permissions | — |
| 2 | Access any fuel URL: index, create, show, edit, delete, trash, restore, force-delete, update-status | All return 403 Forbidden | Each method has `Gate::authorize()` |
| 3 | Verify Auth guard: unauthenticated → redirect to `/login` | Login required | Laravel default |

### TC-N24: Guest Access Redirect

| Step # | Action | Expected Result | Code Trace |
|--------|--------|-----------------|------------|
| 1 | Logout (no authenticated user) | Guest session | — |
| 2 | Access GET `/vehicle-fuel` | Redirect to `/login` | Laravel auth middleware |
| 3 | Access GET `/vehicle-fuel/create` | Redirect to `/login` | — |
| 4 | Access POST `/vehicle-fuel` | Redirect to `/login` | — |
| 5 | Access any `/vehicle-fuel/*` URL | Redirect to `/login` | — |

### TC-N25: XSS Injection In remarks

| Step # | Action | Expected Result | Code Trace |
|--------|--------|-----------------|------------|
| 1 | POST fuel entry with `remarks=<script>alert('xss')</script>` | XSS payload submitted | — |
| 2 | Verify `['string', 'max:512']` passes | String validation allows it | `TptVehicleFuelRequest.php:58-59` |
| 3 | Verify stored in DB as literal string | `SELECT remarks` → `<script>alert('xss')</script>` | No sanitization |
| 4 | Navigate to show page | `{{ $vehicleFuel->remarks ?? '-' }}` — Blade `{{ }}` escapes | `show.blade.php:85` |
| 5 | Verify script NOT executed | HTML source shows `&lt;script&gt;alert('xss')&lt;/script&gt;` | Blade auto-escaping |

### TC-N26: Permission Denied — No `viewAny` → Index 403

| Step # | Action | Expected Result | Code Trace |
|--------|--------|-----------------|------------|
| 1 | Login as user without `tenant.vehicle-fuel.viewAny` | No viewAny permission | — |
| 2 | GET `/vehicle-fuel` | `Gate::authorize(...)` → 403 | `TptVehicleFuelController.php:21` |

### TC-N27: Permission Denied — No `create` → Create Form 403

| Step # | Action | Expected Result | Code Trace |
|--------|--------|-----------------|------------|
| 1 | Login as user without `tenant.vehicle-fuel.create` | No create permission | — |
| 2 | GET `/vehicle-fuel/create` | `Gate::authorize(...)` → 403 | `TptVehicleFuelController.php:35` |

### TC-N28: Permission Denied — No `create` → Store 403

| Step # | Action | Expected Result | Code Trace |
|--------|--------|-----------------|------------|
| 1 | Login as user without `tenant.vehicle-fuel.create` | No create permission | — |
| 2 | POST `/vehicle-fuel` with valid data | `Gate::authorize(...)` → 403 | `TptVehicleFuelController.php:48` |

### TC-N29: Permission Denied — No `view` → Show 403

| Step # | Action | Expected Result | Code Trace |
|--------|--------|-----------------|------------|
| 1 | Login as user without `tenant.vehicle-fuel.view` | No view permission | — |
| 2 | GET `/vehicle-fuel/{id}` | `Gate::authorize(...)` → 403 | `TptVehicleFuelController.php:67` |

### TC-N30: Permission Denied — No `update` → Edit Form 403

| Step # | Action | Expected Result | Code Trace |
|--------|--------|-----------------|------------|
| 1 | Login as user without `tenant.vehicle-fuel.update` | No update permission | — |
| 2 | GET `/vehicle-fuel/{id}/edit` | `Gate::authorize(...)` → 403 | `TptVehicleFuelController.php:77` |

### TC-N31: Permission Denied — No `update` → PUT 403

| Step # | Action | Expected Result | Code Trace |
|--------|--------|-----------------|------------|
| 1 | Login as user without `tenant.vehicle-fuel.update` | No update permission | — |
| 2 | PUT `/vehicle-fuel/{id}` | `Gate::authorize(...)` → 403 | `TptVehicleFuelController.php:90` |

### TC-N32: Permission Denied — No `delete` → Destroy 403

| Step # | Action | Expected Result | Code Trace |
|--------|--------|-----------------|------------|
| 1 | Login as user without `tenant.vehicle-fuel.delete` | No delete permission | — |
| 2 | DELETE `/vehicle-fuel/{id}` | `Gate::authorize(...)` → 403 | `TptVehicleFuelController.php:124` |

### TC-N33: Permission Denied — No `restore` → Trash Page 403

| Step # | Action | Expected Result | Code Trace |
|--------|--------|-----------------|------------|
| 1 | Login as user without `tenant.vehicle-fuel.restore` | No restore permission | — |
| 2 | GET `/vehicle-fuel/trash/view` | `Gate::authorize(...)` → 403 | `TptVehicleFuelController.php:143` |

### TC-N34: Permission Denied — No `restore` → Restore 403

| Step # | Action | Expected Result | Code Trace |
|--------|--------|-----------------|------------|
| 1 | Login as user without `tenant.vehicle-fuel.restore` | No restore permission | — |
| 2 | GET `/vehicle-fuel/{id}/restore` | `Gate::authorize(...)` → 403 | `TptVehicleFuelController.php:157` |

### TC-N35: Permission Denied — No `forceDelete` → Force Delete 403

| Step # | Action | Expected Result | Code Trace |
|--------|--------|-----------------|------------|
| 1 | Login as user without `tenant.vehicle-fuel.forceDelete` | No forceDelete permission | — |
| 2 | DELETE `/vehicle-fuel/{id}/force-delete` | `Gate::authorize(...)` → 403 | `TptVehicleFuelController.php:177` |

### TC-N36: Permission Denied — No `approve` → updateStatus 403

| Step # | Action | Expected Result | Code Trace |
|--------|--------|-----------------|------------|
| 1 | Login as user without `tenant.vehicle-fuel.approve` | No approve permission | — |
| 2 | Create fuel entry as admin first | Entry exists | — |
| 3 | POST `/vehicle-fuel/{id}/update-status` with `status=Approved` | `Gate::authorize(...)` → 403 (AJAX, check HTTP status) | `TptVehicleFuelController.php:197` |
| 4 | Verify HTTP 403 returned | AJAX error handler receives 403 | — |

### TC-N37: quantity = 0.001 — Exact Boundary

| Step # | Action | Expected Result | Code Trace |
|--------|--------|-----------------|------------|
| 1 | POST with `quantity=0.001` | Exact minimum | — |
| 2 | Verify `min:0.001` passes | `0.001 >= 0.001` → OK | `TptVehicleFuelRequest.php:40` |
| 3 | Entry created successfully | Positive boundary test | — |

### TC-N38: quantity Exceeds DECIMAL(10,3) Precision

| Step # | Action | Expected Result | Code Trace |
|--------|--------|-----------------|------------|
| 1 | POST with `quantity=99999999.999` | Max precision (10 digits, 3 decimal) | — |
| 2 | Verify numeric rule passes | Valid number | `TptVehicleFuelRequest.php:39` |
| 3 | Attempt `quantity=99999999.9999` | Exceeds 3 decimal places | — |
| 4 | DB truncation or validation error | Numeric value out of range | — |

### TC-N39: cost Exceeds DECIMAL(12,2) Precision

| Step # | Action | Expected Result | Code Trace |
|--------|--------|-----------------|------------|
| 1 | POST with `cost=9999999999.99` | Max precision (12 digits, 2 decimal) | — |
| 2 | Verify numeric rule passes | Valid number | `TptVehicleFuelRequest.php:44` |
| 3 | Attempt `cost=99999999999.99` | Exceeds 12 digits | — |
| 4 | DB truncation or validation error | Out of range | — |

### TC-N40: updateStatus With Missing status Field

| Step # | Action | Expected Result | Code Trace |
|--------|--------|-----------------|------------|
| 1 | POST updateStatus WITHOUT sending `status` field | No status | — |
| 2 | Verify `required` validation fails | "The status field is required." | `TptVehicleFuelController.php:200` |

### TC-N41: Force Delete Already Force-Deleted Record

| Step # | Action | Expected Result | Code Trace |
|--------|--------|-----------------|------------|
| 1 | Force delete fuel entry id=X | Permanently gone | — |
| 2 | Attempt force delete again on id=X | Record no longer exists | — |
| 3 | `withTrashed()->findOrFail($id)` throws ModelNotFoundException | 404 response | `TptVehicleFuelController.php:179` |

### TC-N42: Restore Force-Deleted Record

| Step # | Action | Expected Result | Code Trace |
|--------|--------|-----------------|------------|
| 1 | Force delete fuel entry id=X | Record permanently deleted | — |
| 2 | GET `/vehicle-fuel/{id}/restore` | `onlyTrashed()->findOrFail($id)` → ModelNotFoundException | `TptVehicleFuelController.php:159` |
| 3 | Verify 404 | Record gone permanently | — |

### TC-N43: Duplicate fuel_type Not Validated (Gap)

| Step # | Action | Expected Result | Code Trace |
|--------|--------|-----------------|------------|
| 1 | POST with `fuel_type=99999` (non-existent dropdown ID) | Invalid fuel_type | — |
| 2 | Verify validation passes | Only `'required'` — no `exists` rule | `TptVehicleFuelRequest.php:47-49` |
| 3 | Entry creates successfully | Fuel type 99999 stored | Gap — no FK constraint in migration either |
| 4 | View the entry | `$fuelEntry->fuelType` returns null → displays '-' | `show.blade.php:55-57` |

### TC-N44: Edit Form With Invalid ID

| Step # | Action | Expected Result | Code Trace |
|--------|--------|-----------------|------------|
| 1 | GET `/vehicle-fuel/99999/edit` | Non-existent ID | — |
| 2 | Route-model-binding resolves `$vehicleFuel` | `ModelNotFoundException` | `TptVehicleFuelController.php:75` |
| 3 | Verify 404 | HTTP 404 | — |

### TC-N45: Show With Invalid ID

| Step # | Action | Expected Result | Code Trace |
|--------|--------|-----------------|------------|
| 1 | GET `/vehicle-fuel/99999` | Non-existent ID | — |
| 2 | Route-model-binding → 404 | ModelNotFoundException | `TptVehicleFuelController.php:65` |
| 3 | Verify 404 | HTTP 404 | — |

### TC-D01: Vehicle Deletion Cascades To Fuel Entries (CASCADE)

| Step # | Action | Expected Result | Code Trace |
|--------|--------|-----------------|------------|
| 1 | Create fuel entry with vehicle_id=V | Entry references vehicle V | — |
| 2 | Verify FK `fk_vfl_vehicle` has `ON DELETE CASCADE` | Migration line 28 | `migration.php:28` |
| 3 | Delete vehicle V from DB | `DELETE FROM tpt_vehicle WHERE id=V` | DB-level operation |
| 4 | Check fuel entries for vehicle V | `SELECT COUNT(*) FROM tpt_vehicle_fuel WHERE vehicle_id=V` → 0 | CASCADE deleted |
| 5 | Note: CASCADE is DB-level, not testable via UI | Requires raw DB delete | — |

### TC-D02: Driver Deletion Sets driver_id to NULL (SET NULL)

| Step # | Action | Expected Result | Code Trace |
|--------|--------|-----------------|------------|
| 1 | Create fuel entry with driver_id=D | Entry references driver D | — |
| 2 | Verify FK `fk_vfl_driver` has `ON DELETE SET NULL` | Migration line 30 | `migration.php:30` |
| 3 | Delete driver D from DB | `DELETE FROM tpt_personnel WHERE id=D` | DB-level operation |
| 4 | Check fuel entry's driver_id | `SELECT driver_id FROM tpt_vehicle_fuel WHERE vehicle_id=V` → NULL | SET NULL fired |
| 5 | Check index display | `{{ optional($fuel->driver)->name ?? '-' }}` → '-' | `index.blade.php:51` |

### TC-D03: Rapid Status Toggle

| Step # | Action | Expected Result | Code Trace |
|--------|--------|-----------------|------------|
| 1 | Create fuel entry with status=Pending | id=X | — |
| 2 | Rapid-fire 10 updateStatus POSTs with alternating status=Approved, Rejected, Pending | All requests processed sequentially | — |
| 3 | Verify no data corruption | Status is always a valid ENUM value | DB ENUM constraint |
| 4 | Verify last write wins | Final status = last successful request's value | — |
| 5 | Verify activity log has all 10 entries | 10 StatusUpdated events logged | — |

### TC-D04: Fuel Entry Creation Without Driver

| Step # | Action | Expected Result | Code Trace |
|--------|--------|-----------------|------------|
| 1 | Create fuel entry, leave driver_id empty | driver_id not sent | — |
| 2 | Verify `nullable` rule passes | NULL allowed | `TptVehicleFuelRequest.php:29` |
| 3 | Verify DB: driver_id=NULL | `SELECT driver_id` → NULL | — |
| 4 | Verify FK constraint allows NULL | `driver_id` has DEFAULT NULL in DDL | `migration.php:29` |

### TC-D05: Vehicle CASCADE — Delete Vehicle With Fuel Entries

| Step # | Action | Expected Result | Code Trace |
|--------|--------|-----------------|------------|
| 1 | Create vehicle V and fuel entry referencing V | Entry exists | — |
| 2 | Delete vehicle V via its controller | Vehicle removed | — |
| 3 | Verify fuel entries for V are cascade-deleted | `ON DELETE CASCADE` fires | `migration.php:28` |
| 4 | Check deleted_at | Cascade delete is hard delete (not soft) — record fully removed | DB-level |

### TC-D06: Driver SET NULL — Delete Driver With Fuel Entries

| Step # | Action | Expected Result | Code Trace |
|--------|--------|-----------------|------------|
| 1 | Create driver D and fuel entry with driver_id=D | Entry references D | — |
| 2 | Delete driver D via its controller | Driver removed | — |
| 3 | Verify fuel entry's driver_id = NULL | `ON DELETE SET NULL` fires | `migration.php:30` |
| 4 | Verify no data loss | All other fields intact, only driver_id set to NULL | — |

### TC-D07: updateStatus Returns 500 on DB Failure

| Step # | Action | Expected Result | Code Trace |
|--------|--------|-----------------|------------|
| 1 | Create fuel entry | id=X | — |
| 2 | Mock DB save failure (e.g., disconnect DB) | `$vehicleFuel->save()` returns false | — |
| 3 | POST updateStatus | `if ($vehicleFuel->save())` → false branch | `TptVehicleFuelController.php:205` |
| 4 | Verify JSON response | `{success: false, message: 'Status update failed.'}` | `TptVehicleFuelController.php:218-221` |
| 5 | Verify HTTP 500 | Response status code 500 | — |

### TC-D08: Concurrent Status Updates

| Step # | Action | Expected Result | Code Trace |
|--------|--------|-----------------|------------|
| 1 | Create fuel entry with status=Pending | id=X | — |
| 2 | Send 2 simultaneous AJAX POSTs: one Approve, one Reject | Concurrent requests | — |
| 3 | Verify final status is one of the two valid values | Either 'Approved' or 'Rejected', never corrupted | — |
| 4 | Verify no duplicate activity logs | Exactly 1 or 2 StatusUpdated events | — |

### TC-D09: Vehicle Delete CASCADE — Soft vs Hard

| Step # | Action | Expected Result | Code Trace |
|--------|--------|-----------------|------------|
| 1 | Verify migration: FK `fk_vfl_vehicle` `onDelete('cascade')` | CASCADE | `migration.php:28` |
| 2 | Verify vehicle_id is NOT NULL | `unsignedInteger('vehicle_id')` — no `->nullable()` | `migration.php:27` |

### TC-D10: Driver Delete SET NULL — Verify DB

| Step # | Action | Expected Result | Code Trace |
|--------|--------|-----------------|------------|
| 1 | Verify migration: FK `fk_vfl_driver` `onDelete('set null')` | SET NULL | `migration.php:30` |
| 2 | Verify driver_id is nullable | `unsignedInteger('driver_id')->nullable()` | `migration.php:29` |

### TC-CR01: Controller — Gate::authorize() Before Every State Change

| Step # | Action | Expected Result | Code Trace |
|--------|--------|-----------------|------------|
| 1 | Open `TptVehicleFuelController.php:21` | `index()` has `Gate::authorize('tenant.vehicle-fuel.viewAny')` | Present |
| 2 | Open `TptVehicleFuelController.php:35` | `create()` has `Gate::authorize('tenant.vehicle-fuel.create')` | Present |
| 3 | Open `TptVehicleFuelController.php:48` | `store()` has `Gate::authorize('tenant.vehicle-fuel.create')` | Present |
| 4 | Open `TptVehicleFuelController.php:67` | `show()` has `Gate::authorize('tenant.vehicle-fuel.view')` | Present |
| 5 | Open `TptVehicleFuelController.php:77` | `edit()` has `Gate::authorize('tenant.vehicle-fuel.update')` | Present |
| 6 | Open `TptVehicleFuelController.php:90` | `update()` has `Gate::authorize('tenant.vehicle-fuel.update')` | Present |
| 7 | Open `TptVehicleFuelController.php:124` | `destroy()` has `Gate::authorize('tenant.vehicle-fuel.delete')` | Present |
| 8 | Open `TptVehicleFuelController.php:143` | `trashed()` has `Gate::authorize('tenant.vehicle-fuel.restore')` | Present |
| 9 | Open `TptVehicleFuelController.php:157` | `restore()` has `Gate::authorize('tenant.vehicle-fuel.restore')` | Present |
| 10 | Open `TptVehicleFuelController.php:177` | `forceDelete()` has `Gate::authorize('tenant.vehicle-fuel.forceDelete')` | Present |
| 11 | Open `TptVehicleFuelController.php:197` | `updateStatus()` has `Gate::authorize('tenant.vehicle-fuel.approve')` | Present |

### TC-CR02: Controller — activityLog After Every CRUD

| Step # | Action | Expected Result | Code Trace |
|--------|--------|-----------------|------------|
| 1 | Open store() line 52-55 | `activityLog($fuelEntry, 'Stored', ...)` — Event: Stored | Present |
| 2 | Open update() line 108-112 | `activityLog($vehicleFuel, 'Updated', ...)` — Event: Updated | Present |
| 3 | Open destroy() line 128-131 | `activityLog($vehicleFuel, 'Trashed', ...)` — Event: Trashed | Present |
| 4 | Open restore() line 162-165 | `activityLog($fuelEntry, 'Restored', ...)` — Event: Restored | Present |
| 5 | Open forceDelete() line 182-185 | `activityLog($fuelEntry, 'Deleted', ...)` — Event: Deleted | Present |
| 6 | Open updateStatus() line 206-209 | `activityLog($vehicleFuel, 'StatusUpdated', ...)` — Event: StatusUpdated | Present |

### TC-CR03: Controller — Change Tracking on Update

| Step # | Action | Expected Result | Code Trace |
|--------|--------|-----------------|------------|
| 1 | Open `TptVehicleFuelController.php:93` | `$original = $vehicleFuel->getOriginal()` — captured before update | Present |
| 2 | Open `TptVehicleFuelController.php:96` | `$changes = $vehicleFuel->getChanges()` — captured after update | Present |
| 3 | Open `TptVehicleFuelController.php:99-106` | Foreach loop builds old→new array | Present |
| 4 | Open `TptVehicleFuelController.php:100` | `if ($field === 'updated_at') continue;` — updated_at excluded | Present |
| 5 | Open `TptVehicleFuelController.php:110` | `$changedAttributes ?: null` — empty array → null | Present |

### TC-CR04: Controller — withTrashed() for forceDelete

| Step # | Action | Expected Result | Code Trace |
|--------|--------|-----------------|------------|
| 1 | Open `TptVehicleFuelController.php:179` | `TptVehicleFuel::withTrashed()->findOrFail($id)` | Uses `withTrashed()` — correct |
| 2 | Verify: Can force-delete both active AND trashed | Finds any record regardless of deleted_at | — |

### TC-CR05: Controller — onlyTrashed() for Restore

| Step # | Action | Expected Result | Code Trace |
|--------|--------|-----------------|------------|
| 1 | Open `TptVehicleFuelController.php:159` | `TptVehicleFuel::onlyTrashed()->findOrFail($id)` | Uses `onlyTrashed()` — correct |
| 2 | Verify: Only trashed records can be restored | Non-trashed records not found → 404 | — |

### TC-CR06: Controller — updateStatus AJAX Response

| Step # | Action | Expected Result | Code Trace |
|--------|--------|-----------------|------------|
| 1 | Open `TptVehicleFuelController.php:211-215` | Success: `{success: true, status, message}` HTTP 200 | Present |
| 2 | Open `TptVehicleFuelController.php:218-221` | Failure: `{success: false, message}` HTTP 500 | Present |

### TC-CR07: Request — authorize() matches Controller Gate

| Step # | Action | Expected Result | Code Trace |
|--------|--------|-----------------|------------|
| 1 | Open `TptVehicleFuelRequest.php:13-16` | POST → create; PUT → update | Matches controller |
| 2 | Controller `store()` line 48 use same gate | `tenant.vehicle-fuel.create` | Redundant but consistent |
| 3 | Controller `update()` line 90 same gate | `tenant.vehicle-fuel.update` | Redundant but consistent |

### TC-CR08: Request — Validation Rules Match DDL

| Step # | Action | Expected Result | Code Trace |
|--------|--------|-----------------|------------|
| 1 | quantity rule: `numeric` matches DECIMAL(10,3) | Consistent | `TptVehicleFuelRequest.php:38-40` |
| 2 | cost rule: `numeric` matches DECIMAL(12,2) | Consistent | `TptVehicleFuelRequest.php:43-45` |
| 3 | odometer_reading: `integer` matches INT UNSIGNED | Consistent | `TptVehicleFuelRequest.php:52-54` |
| 4 | remarks: `max:512` matches VARCHAR(512) | Consistent | `TptVehicleFuelRequest.php:58-59` |

### TC-CR09: Request — fuel_type Missing `exists` Rule

| Step # | Action | Expected Result | Code Trace |
|--------|--------|-----------------|------------|
| 1 | Open `TptVehicleFuelRequest.php:47-49` | `'fuel_type' => ['required']` — NO `exists` rule | Confirmed Gap |
| 2 | Commented out `// 'exists:sys_dropdown_table,id'` at line 49 | Developer acknowledged but disabled | Gap |
| 3 | Store with fuel_type=99999 | Passes validation (only required check) | Gap |
| 4 | Show page displays '-' for fuelType | `optional($fuel->fuelType)->value ?? '-'` | `index.blade.php:52` |

### TC-CR10: Request — status Rule::in Not Required

| Step # | Action | Expected Result | Code Trace |
|--------|--------|-----------------|------------|
| 1 | Open `TptVehicleFuelRequest.php:62-64` | `'status' => [Rule::in([...])]` — no `required` rule | Confirmed |
| 2 | POST without status field | Validation passes | — |
| 3 | Model default 'Pending' applied | `$attributes = ['status' => 'Pending']` | `TptVehicleFuel.php:42-44` |

### TC-CR11: Model — Table Name and SoftDeletes

| Step # | Action | Expected Result | Code Trace |
|--------|--------|-----------------|------------|
| 1 | Open `TptVehicleFuel.php:17` | `protected $table = 'tpt_vehicle_fuel'` | Present |
| 2 | Open `TptVehicleFuel.php:12` | `use HasFactory, SoftDeletes;` | Present |

### TC-CR12: Model — Fillable Matches DB Columns

| Step # | Action | Expected Result | Code Trace |
|--------|--------|-----------------|------------|
| 1 | Open `TptVehicleFuel.php:27-37` | 9 fillable fields | All present |
| 2 | Verify: id, created_at, updated_at, deleted_excluded | Not in fillable | Correct |

### TC-CR13: Model — Casts

| Step # | Action | Expected Result | Code Trace |
|--------|--------|-----------------|------------|
| 1 | Open `TptVehicleFuel.php:49-53` | `'date' => 'date'`, `'quantity' => 'decimal:3'`, `'cost' => 'decimal:2'` | Present |
| 2 | Note: odometer_reading NOT cast | Returns string from DB | — |

### TC-CR14: Model — Default Attributes

| Step # | Action | Expected Result | Code Trace |
|--------|--------|-----------------|------------|
| 1 | Open `TptVehicleFuel.php:42-44` | `$attributes = ['status' => 'Pending']` | Present |
| 2 | Verify matches DDL DEFAULT 'Pending' | Migration: `->default('Pending')` | `migration.php:22` |

### TC-CR15: Model — Relationships

| Step # | Action | Expected Result | Code Trace |
|--------|--------|-----------------|------------|
| 1 | Open `TptVehicleFuel.php:63-66` | `vehicle()` — BelongsTo Vehicle | Present |
| 2 | Open `TptVehicleFuel.php:68-71` | `driver()` — BelongsTo DriverHelper | Present |
| 3 | Open `TptVehicleFuel.php:73-76` | `fuelType()` — BelongsTo Dropdown | Present |

### TC-CR16: Model — Scopes

| Step # | Action | Expected Result | Code Trace |
|--------|--------|-----------------|------------|
| 1 | Open `TptVehicleFuel.php:82-85` | `scopePending()` | Present |
| 2 | Open `TptVehicleFuel.php:87-90` | `scopeApproved()` | Present |
| 3 | Open `TptVehicleFuel.php:92-95` | `scopeRejected()` | Present |
| 4 | Open `TptVehicleFuel.php:97-100` | `scopeDateRange()` | Present |
| 5 | Open `TptVehicleFuel.php:102-108` | `scopeVehicleFilter()` | Present |

### TC-CR17: Routes — Resource + Additional Routes

| Step # | Action | Expected Result | Code Trace |
|--------|--------|-----------------|------------|
| 1 | Open `web.php:250` | `Route::resource('vehicle-fuel', ...)` — 7 routes | Present |
| 2 | Open `web.php:251` | GET `/vehicle-fuel/trash/view` — `trashed()` | Present |
| 3 | Open `web.php:252` | GET `/vehicle-fuel/{id}/restore` — `restore()` | Present |
| 4 | Open `web.php:253` | DELETE `/vehicle-fuel/{id}/force-delete` — `forceDelete()` | Present |
| 5 | Open `web.php:254` | POST `/vehicle-fuel/{id}/update-status` — `updateStatus()` | Present |

### TC-CR18: Routes — No toggleStatus Route

| Step # | Action | Expected Result | Code Trace |
|--------|--------|-----------------|------------|
| 1 | Search web.php for `toggleStatus` in vehicle-fuel block | Not found | — |
| 2 | Compare with other entities that have toggleStatus | Fuel uses `updateStatus` instead (approval workflow) | Design decision |

### TC-CR19: VehicleMgmtController — fuelEntryQuery Filters

| Step # | Action | Expected Result | Code Trace |
|--------|--------|-----------------|------------|
| 1 | Open `VehicleMgmtController.php:102-111` | Search by vehicle.reg_no OR driver.name (LIKE) | Present |
| 2 | Open `VehicleMgmtController.php:114-116` | Status filter: `where('status', $request->status)` | Present |

### TC-CR20: VehicleMgmtController — Pending Data Count

| Step # | Action | Expected Result | Code Trace |
|--------|--------|-----------------|------------|
| 1 | Open `VehicleMgmtController.php:318-345` | `getDetailedPendingData()` with `vehicle_fuel` key | Present |
| 2 | Open `VehicleMgmtController.php:321-325` | `TptVehicleFuel::pending()->take(10)->get()` | Present |

### TC-CR21: View — Status Filter Dropdown Mismatch (Bug)

| Step # | Action | Expected Result | Code Trace |
|--------|--------|-----------------|------------|
| 1 | Open `index.blade.php:13-17` | Status values: "" (All), "1" (Active), "0" (Inactive) | Present |
| 2 | Open `VehicleMgmtController.php:114-116` | Filter expects ENUM values | Present |
| 3 | Select "Active" → `?status=1` | `WHERE status = '1'` → 0 rows | BUG |
| 4 | Select "Inactive" → `?status=0` | `WHERE status = '0'` → 0 rows | BUG |
| 5 | Root cause: Blade uses 1/0 but Fuel uses ENUM status | Fix: Change dropdown to Approved/Pending/Rejected or adjust query | BUG |

### TC-CR22: Controller — All Methods Have Type Hints

| Step # | Action | Expected Result | Code Trace |
|--------|--------|-----------------|------------|
| 1 | Check store() signature | `public function store(TptVehicleFuelRequest $request)` | Type hinted |
| 2 | Check show() signature | `public function show(TptVehicleFuel $vehicleFuel)` | Route-model-binding |
| 3 | Check update() signature | `public function update(TptVehicleFuelRequest $request, TptVehicleFuel $vehicleFuel)` | Both hinted |
| 4 | Check destroy() signature | `public function destroy(TptVehicleFuel $vehicleFuel)` | Route-model-binding |

### TC-CR23: Controller — updateStatus inline validation

| Step # | Action | Expected Result | Code Trace |
|--------|--------|-----------------|------------|
| 1 | Open `TptVehicleFuelController.php:199-201` | `$request->validate(['status' => 'required|in:Approved,Rejected,Pending'])` | Present |
| 2 | Note: No duplicate validation from FormRequest | Status not in TptVehicleFuelRequest rules (Rule::in only, no required) | Non-duplicating |

### TC-CR24: Request — driver_id blade vs validation mismatch

| Step # | Action | Expected Result | Code Trace |
|--------|--------|-----------------|------------|
| 1 | Open `create.blade.php:58` | `<select name="driver_id" ... required>` | Blade says required |
| 2 | Open `TptVehicleFuelRequest.php:29-32` | `['nullable', 'exists:tpt_personnel,id']` | Request says nullable |
| 3 | Mismatch: Browser enforces required but backend allows null | HTML5 validation blocks form without driver | Minor UX issue |

### TC-CR25: Request — odometer_reading blade vs validation mismatch

| Step # | Action | Expected Result | Code Trace |
|--------|--------|-----------------|------------|
| 1 | Open `create.blade.php:134` | `x-backend.form.input-text ... required="true"` | Blade says required |
| 2 | Open `TptVehicleFuelRequest.php:51-55` | `['nullable', 'integer', 'min:0']` | Request says nullable |
| 3 | Mismatch: Browser enforces required but backend allows null | Same pattern as driver_id | Minor UX issue |

### TC-CR26: View — index.blade.php column count differs from BC spec

| Step # | Action | Expected Result | Code Trace |
|--------|--------|-----------------|------------|
| 1 | Compare `index.blade.php:35-43` columns | Date, Vehicle, Driver, Fuel, Qty, Cost, Status, Action (8 cols) | Present |
| 2 | Compare with BC table header spec in Section 1 | BC spec mentions 10 columns including Odometer | Odometer omitted in index |
| 3 | Note: Odometer only visible in Show view | `show.blade.php:77-78` has odometer | Not a bug, just index omits it |

### TC-CR27: View — show.blade.php date formatting

| Step # | Action | Expected Result | Code Trace |
|--------|--------|-----------------|------------|
| 1 | Open `show.blade.php:44-48` | `\Carbon\Carbon::parse($vehicleFuel->date)->format('d M Y')` | Uses Carbon::parse |
| 2 | Note: Model casts date as 'date' → Carbon instance | Could use `$vehicleFuel->date->format('d M Y')` directly | Redundant parse |

### TC-CR28: Vehiclemgmt — nav-tab permission guard on fuel tab

| Step # | Action | Expected Result | Code Trace |
|--------|--------|-----------------|------------|
| 1 | Open `vehiclemgmt.blade.php:8-14` | nav-tab includes Fuel Log with `permission => tenant.vehicle-fuel.viewAny` | Present in tab definition |
| 2 | Open `vehiclemgmt.blade.php:17-19` | `@can('tenant.vehicle-fuel.viewAny')` wraps the include | Double guard: tab + content |

### TC-CR29: Permissions — approve action registered for updateStatus

| Step # | Action | Expected Result | Code Trace |
|--------|--------|-----------------|------------|
| 1 | Open `permissionslist.php:13-31` | `$crud` array includes 'approve' | Present |
| 2 | Open `permissionslist.php:308` | `'vehicle-fuel' => $crud` | Registers all crud actions |
| 3 | Open `TptVehicleFuelController.php:197` | `Gate::authorize('tenant.vehicle-fuel.approve')` | Uses approve permission |

### TC-CR30: Migration — No FK constraint on fuel_type

| Step # | Action | Expected Result | Code Trace |
|--------|--------|-----------------|------------|
| 1 | Open `migration.php:19` | `$table->unsignedInteger('fuel_type');` | No foreign() call |
| 2 | Search migration for fuel_type foreign | NOT found | Gap — no referential integrity |
| 3 | Compare with vehicle_id (has FK) | `$table->foreign('vehicle_id', 'fk_vfl_vehicle')->references('id')->on('tpt_vehicle')` | vehicle_id has FK |

### TC-CR31: Flash messages use flash() helper

| Step # | Action | Expected Result | Code Trace |
|--------|--------|-----------------|------------|
| 1 | Open `TptVehicleFuelController.php:59` | `flash('created.vehicle_fuel')` | Translatable flash key |
| 2 | Open `TptVehicleFuelController.php:116` | `flash('updated.vehicle_fuel')` | Translatable flash key |
| 3 | Open `TptVehicleFuelController.php:135` | `flash('trashed.vehicle_fuel')` | Translatable flash key |
| 4 | Open `TptVehicleFuelController.php:169` | `flash('restored.vehicle_fuel')` | Translatable flash key |
| 5 | Open `TptVehicleFuelController.php:189` | `flash('force_deleted.vehicle_fuel')` | Translatable flash key |

### TC-CR32: Route parameter name: `vehicleFuel` vs `vehicle_fuel`

| Step # | Action | Expected Result | Code Trace |
|--------|--------|-----------------|------------|
| 1 | Open `web.php:250` | `Route::resource('vehicle-fuel', TptVehicleFuelController::class)` | URI: kebab-case |
| 2 | Controller method params use camelCase | `show(TptVehicleFuel $vehicleFuel)` | Route-model-binding param: `vehicleFuel` |
| 3 | Additional routes use `{id}` not `{vehicleFuel}` | `restore($id)`, `forceDelete($id)` — manual ID param | Inconsistent parameter style |

---

*Template: tpt_PickupStopsList_TcList.md (Syllabus depth) | Entity: FuelLog | Date: 2026-07-21*
