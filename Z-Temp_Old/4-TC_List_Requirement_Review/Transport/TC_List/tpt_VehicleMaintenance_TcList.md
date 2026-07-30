# tpt_VehicleMaintenance_TcList

## Module: Transport → Vehicle Management → Vehicle Maintenance

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | Transport |
| Tab Group | Vehicle Management (5-tab container via `VehicleMgmtController`) |
| Feature | Vehicle Maintenance |
| URL(s) | `/vehicle-maintenance` (index), `/vehicle-maintenance/create` (create), `/vehicle-maintenance` (store — **NO CONTROLLER METHOD**), `/vehicle-maintenance/{id}` (show), `/vehicle-maintenance/{id}/edit` (edit), `/vehicle-maintenance/{id}` (update PUT), `/vehicle-maintenance/{id}` (destroy DELETE), `/vehicle-maintenance/trash/view` (trash), `/vehicle-maintenance/{id}/restore` (restore GET), `/vehicle-maintenance/{id}/force-delete` (forceDelete DELETE), `/vehicle-maintenance/{id}/update-status` (updateStatus POST — **NO CONTROLLER METHOD**) |
| Controller | `Modules\Transport\Http\Controllers\TptVehicleMaintenanceController` |
| Tab Container Controller | `Modules\Transport\Http\Controllers\VehicleMgmtController@index()` |
| Model | `Modules\Transport\Models\TptVehicleMaintenance` — table: `tpt_vehicle_maintenance` |
| Validation | `Modules\Transport\Http\Requests\TptVehicleMaintenanceRequest` (defined but **NOT USED** in controller) |
| Permissions | `tenant.vehicle-maintenance.viewAny`, `tenant.vehicle-maintenance.view`, `tenant.vehicle-maintenance.status`, `tenant.vehicle-maintenance.create`, `tenant.vehicle-maintenance.update`, `tenant.vehicle-maintenance.delete`, `tenant.vehicle-maintenance.restore`, `tenant.vehicle-maintenance.forceDelete`, `tenant.vehicle-maintenance.import`, `tenant.vehicle-maintenance.export`, `tenant.vehicle-maintenance.print`, `tenant.vehicle-maintenance.schedule`, `tenant.vehicle-maintenance.complete`, `tenant.vehicle-maintenance.viewHistory` |
| Soft Deletes | Yes (`SoftDeletes` trait) |
| Activity Log | Events: `Deleted`, `Restored`, `Force Delete` — No `Created` or `Updated` events |
| Registered Policy | `TransportVehicleMaintenancePolicy` (14 gates: viewAny, view, status, create, update, delete, restore, forceDelete, import, export, print, schedule, complete, viewHistory) |
| Unused Policy File | `TptVehicleMaintenancePolicy` — exists but NOT registered in `TransportServiceProvider`; has 8 gates (no import/export/print/schedule/complete/viewHistory) |
| Workflow | Maintenance created from Approved Service Request; update with status='Approved' updates linked service request |

---

## 2. Pre-conditions

- Required permissions: All `tenant.vehicle-maintenance.*` permissions
- Tenant context initialized
- Required seed data: A `TptVehicleServiceRequest` with status='Approved' or any status — maintenance requires `vehicle_service_request_id` (FK CASCADE)
- Maintenance should only be created via Service Request approval (DDL condition: direct entry not allowed)
- Dusk environment variables configured

---

## 3. Default Data Load

When the page loads via `VehicleMgmtController@index()` (GET `/vehicle-mgmt`):

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| Maintenance Grid | `VehicleMgmtController@vehicleMaintenanceQuery()` | `TptVehicleMaintenance::with(['serviceRequest.inspection.vehicle','serviceRequest.inspection.driver','approvedBy'])->orderBy('maintenance_initiation_date','DESC')` | search_maintenance (vehicle_no, registration_number, driver name, type, remarks, workshop), maintenance_status, request_status, date_range, cost_range, approved_by, vehicle_type | 10/page |

The standalone `/vehicle-maintenance` GET page loads via `TptVehicleMaintenanceController@index()` with `with(['vehicle', 'vendor', 'assignedTo'])` — **relationships that do not exist in the model** (will throw error).

---

## 4. Test Data Strategy

- **vehicle_service_request_id**: FK to `tpt_vehicle_service_request`. Normally set via service request approval workflow.
- **maintenance_initiation_date**: DATE, required — date vehicle entered garage/service
- **maintenance_type**: VARCHAR(120), required — manual entry
- **cost**: DECIMAL(12,2), required, min:0, max:9999999999.99
- **in_service_date**: DATE, nullable — date service started
- **out_service_date**: DATE, nullable — validated `after_or_equal:in_service_date` when both present
- **next_due_date**: DATE, nullable
- **workshop_details**: VARCHAR(512), nullable
- **remarks**: VARCHAR(512), nullable
- **status**: ENUM('Approved','Pending','Rejected'), default 'Pending'. In edit, Completed/Approved status blocks editing!
- **approved_by**: FK to sys_users, SET NULL on delete
- **Pre-test cleanup**: Delete by vehicle_service_request_id
- **Auto-creation**: Maintenance auto-created when Service Request is Approved
- **Note**: Controller index() calls `with(['vehicle', 'vendor', 'assignedTo'])` but model has NO `vendor` or `assignedTo` relationships — this will cause an error

---

## 5. Business Conditions

### 5.1 Database Schema — `tpt_vehicle_maintenance`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | id | INT UNSIGNED | PK, auto-increment |
| BC-DB-02 | vehicle_service_request_id | INT UNSIGNED | NOT NULL, FK → `tpt_vehicle_service_request.id`, ON DELETE CASCADE |
| BC-DB-03 | maintenance_initiation_date | DATE | NOT NULL |
| BC-DB-04 | maintenance_type | VARCHAR(120) | NOT NULL |
| BC-DB-05 | cost | DECIMAL(12,2) | NOT NULL |
| BC-DB-06 | in_service_date | DATE | DEFAULT NULL |
| BC-DB-07 | out_service_date | DATE | DEFAULT NULL |
| BC-DB-08 | workshop_details | VARCHAR(512) | DEFAULT NULL |
| BC-DB-09 | next_due_date | DATE | DEFAULT NULL |
| BC-DB-10 | remarks | VARCHAR(512) | DEFAULT NULL |
| BC-DB-11 | status | ENUM('Approved','Pending','Rejected') | NOT NULL, DEFAULT 'Pending' |
| BC-DB-12 | approved_by | INT UNSIGNED | DEFAULT NULL, FK → `sys_users.id`, ON DELETE SET NULL |
| BC-DB-13 | approved_at | TIMESTAMP | NULL DEFAULT NULL |
| BC-DB-14 | created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |
| BC-DB-15 | updated_at | TIMESTAMP | ON UPDATE CURRENT_TIMESTAMP |
| BC-DB-16 | deleted_at | TIMESTAMP | NULLABLE (soft delete) |

### 5.2 Validation Rules — `TptVehicleMaintenanceRequest` (DEFINED BUT NOT USED)

The request class exists but controller's `update()` method does NOT use it (uses `Request $request` directly with no validation).

| BC ID | Field | Rule | Error Message |
|-------|-------|------|---------------|
| BC-VAL-01 | vehicle_service_request_id | (POST only) required, `exists:tpt_vehicle_service_request,id`, unique (vehicle_service_request_id) whereNull(deleted_at) | "This service request already has a maintenance entry." |
| BC-VAL-02 | maintenance_initiation_date | required, date | "Maintenance initiation date is required." |
| BC-VAL-03 | maintenance_type | required, string, max:120 | "Maintenance type must not exceed 120 characters." |
| BC-VAL-04 | cost | required, numeric, min:0, max:9999999999.99 | "Cost must be at least 0." |
| BC-VAL-05 | in_service_date | nullable, date | "In service date must be a valid date." |
| BC-VAL-06 | out_service_date | nullable, date, `after_or_equal:in_service_date` (conditional) | "Out service date must be on or after in service date." |
| BC-VAL-07 | workshop_details | nullable, string, max:512 | "Workshop details must not exceed 512 characters." |
| BC-VAL-08 | next_due_date | nullable, date | "Next due date must be a valid date." |
| BC-VAL-09 | remarks | nullable, string, max:512 | "Remarks must not exceed 512 characters." |

### 5.3 Authorization (Permission Gates)

| BC ID | Permission | Controller Method | Behavior |
|-------|-----------|-------------------|----------|
| BC-AUTH-01 | tenant.vehicle-maintenance.viewAny | index() | Without → 403 |
| BC-AUTH-02 | tenant.vehicle-maintenance.view | show() | Without → 403 |
| BC-AUTH-03 | tenant.vehicle-maintenance.create | create() | Without → 403 |
| BC-AUTH-04 | tenant.vehicle-maintenance.update | update(), edit() | Without → 403 |
| BC-AUTH-05 | tenant.vehicle-maintenance.delete | destroy() | Without → 403 |
| BC-AUTH-06 | tenant.vehicle-maintenance.restore | restore(), trashed() | Without → 403 |
| BC-AUTH-07 | tenant.vehicle-maintenance.forceDelete | forceDelete() | Without → 403 |

| BC-AUTH-08 | tenant.vehicle-maintenance.status | (unused) | Policy has `status()` gate but controller has NO `updateStatus()` method — route exists but returns 500 |
| BC-AUTH-09 | tenant.vehicle-maintenance.import | (unused) | Policy gate exists but controller has no import feature |
| BC-AUTH-10 | tenant.vehicle-maintenance.export | (unused) | Policy gate exists but controller has no export feature |
| BC-AUTH-11 | tenant.vehicle-maintenance.print | (unused) | Policy gate exists but controller has no print feature |
| BC-AUTH-12 | tenant.vehicle-maintenance.schedule | (unused) | Policy gate exists but controller has no schedule feature |
| BC-AUTH-13 | tenant.vehicle-maintenance.complete | (unused) | Policy gate exists but controller has no complete feature |
| BC-AUTH-14 | tenant.vehicle-maintenance.viewHistory | (unused) | Policy gate exists but controller has no viewHistory feature |

**Missing**: No `approve` permission check for updating status to Approved (update() method handles approval without separate gate).

### 5.4 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | No store() method | Route::resource generates a store route but controller has NO store() method → POST to `/vehicle-maintenance` returns 405 Method Not Allowed |
| BC-BIZ-02 | index() with eager loading broken | `TptVehicleMaintenance::with(['vehicle', 'vendor', 'assignedTo'])` — model has NO `vendor` or `assignedTo` relationships → throws `BadMethodCallException` |
| BC-BIZ-03 | show() uses `where('id',$id)->first()` | Returns null on invalid ID instead of 404 |
| BC-BIZ-04 | edit() blocks Completed/Approved records | If `$maintenance->status === 'Completed' || $maintenance->approval_status === 'Approved'` → redirect back with error |
| BC-BIZ-05 | **edit() references non-existent `approval_status`** | DDL and model have `status` (ENUM), NOT `approval_status`. Controller checks `$maintenance->approval_status === 'Approved'` — this property does not exist |
| BC-BIZ-06 | update() does NOT use FormRequest | Uses `Request $request` with NO validation — all input blindly accepted |
| BC-BIZ-07 | update() uses raw mass update | `TptVehicleMaintenance::where('id', $id)->update([...])` — bypasses model events (no boot() callbacks) |
| BC-BIZ-08 | update() — no activity log | No `activityLog()` call unlike all other entity controllers |
| BC-BIZ-09 | update() — no change tracking | No `getOriginal()` / `getChanges()` comparison |
| BC-BIZ-10 | update() — auto-approve service request on Approved status | If `$request->status == 'Approved'` AND vehicle_service_request_id exists → linked service request updated: `vehicle_status='Service Done'`, `request_approval_status='Approved'`, `approved_by=Auth::user()`, `service_completion_date=now()` |
| BC-BIZ-11 | Soft delete via `destroy()` | `$maintenance->delete()`; redirect back with success |
| BC-BIZ-12 | Restore via `restore($id)` | `onlyTrashed()->findOrFail($id)` → `$maintenance->restore()` |
| BC-BIZ-13 | Force delete via `forceDelete($id)` | Uses `onlyTrashed()` → **cannot force-delete non-trashed records** (should use `withTrashed()`) |
| BC-BIZ-14 | No updateStatus method but route exists | Route `POST /vehicle-maintenance/{id}/update-status` registered but controller has NO `updateStatus()` method → 500 error |
| BC-BIZ-15 | edit() gate check order | Gate::authorize() called at line 55 (BEFORE fetch at line 57) — correct order compared to Inspection controller |

### 5.4B BC-BIZ-DEEP: Deep Business Logic (Cross-Reference Against Actual Controller Code)

| BC-DEEP ID | Controller Method | Line(s) | Condition / Trigger | Actual Code Behavior | Verification |
|------------|-------------------|---------|---------------------|----------------------|--------------|
| BC-DEEP-01 | index() | L22 | Any user with `tenant.vehicle-maintenance.viewAny` accesses GET /vehicle-maintenance | `Gate::authorize('tenant.vehicle-maintenance.viewAny')` called first. Then `TptVehicleMaintenance::with(['vehicle', 'vendor', 'assignedTo'])->paginate(10)`. The `vendor` and `assignedTo` relationships do NOT exist on the model. The `vehicle` is an accessor (`getVehicleAttribute`), not a relationship — cannot be eager-loaded. | The with() call on L24 will throw `BadMethodCallException: Relationship 'vendor' not found`. This makes the standalone index() completely unusable. |
| BC-DEEP-02 | index() | L24 | Eager loading chain `with(['vehicle', 'vendor', 'assignedTo'])` | `vehicle` = accessor (L57-60 model), `vendor` = NOT DEFINED, `assignedTo` = NOT DEFINED. Laravel's with() only works on relationships defined via `belongsTo()`, `hasMany()`, etc. Accessors are NOT relationships. | Confirmed: model TptVehicleMaintenance.php L44-60 only has `serviceRequest()` and `approvedBy()` as relationships. `getVehicleAttribute()` L57-60 is an accessor returning `$this->serviceRequest->inspection->vehicle ?? null`. |
| BC-DEEP-03 | create() | L35 | User with `tenant.vehicle-maintenance.create` accesses GET /vehicle-maintenance/create | `Gate::authorize('tenant.vehicle-maintenance.create')` at L35. View returned at L37: `transport::vehiclemaintenance.create`. No data passed to view. | No query executed. No relationship loading. Pure form rendering. |
| BC-DEEP-04 | show($id) | L45-46 | User with `tenant.vehicle-maintenance.view` accesses GET /vehicle-maintenance/{id} | `Gate::authorize('tenant.vehicle-maintenance.view')` at L45. Query: `TptVehicleMaintenance::where('id',$id)->first()` at L46 — returns null if ID not found (no `findOrFail`). | Uses `first()` not `findOrFail()`. On invalid ID, null passed to view → `$maintenance->status` on null causes ErrorException: "Trying to get property 'status' of non-object". |
| BC-DEEP-05 | edit($id) | L55-63 | User with `tenant.vehicle-maintenance.update` accesses GET /vehicle-maintenance/{id}/edit | `Gate::authorize('tenant.vehicle-maintenance.update')` at L55. `where('id',$id)->first()` at L57 (null on bad ID). Guard condition L59: `$maintenance->status === 'Completed' || $maintenance->approval_status === 'Approved'`. The `approval_status` property does not exist on model. | DDL has `status` ENUM('Approved','Pending','Rejected'). `approval_status` undefined → Laravel returns null. Condition `null === 'Approved'` is ALWAYS false. So Completed/Approved records are NOT blocked as intended. Null on bad ID also passes null to `$maintenance->status` check → error. |
| BC-DEEP-06 | edit($id) | L59 | `$maintenance->status` check string literal 'Completed' | ENUM DDL defines only 'Approved','Pending','Rejected'. There is NO 'Completed' value in the ENUM. | The check `$maintenance->status === 'Completed'` will NEVER match because status can never legally be 'Completed'. This guard is dead code. |
| BC-DEEP-07 | update() | L69-113 | User with `tenant.vehicle-maintenance.update` sends PUT /vehicle-maintenance/{id} | `Gate::authorize('tenant.vehicle-maintenance.update')` at L69. Two phase update: (1) Mass update L71-81 uses `TptVehicleMaintenance::where('id', $id)->update([...])` — this bypasses Eloquent events. (2) Conditional service request auto-approval at L85-108. | Phase 1 uses query builder mass update (no model events). Phase 2 re-fetches model at L83 via `where('id',$id)->first()`. If $request->status == 'Approved' AND vehicle_service_request_id not null, updates linked TptVehicleServiceRequest. |
| BC-DEEP-08 | update() | L71-81 | Phase 1: Mass update fields | Fields updated: maintenance_initiation_date, maintenance_type, cost, status, in_service_date, out_service_date, next_due_date, workshop_details, remarks. All taken directly from $request with NO validation. | 9 fields mass assigned. No `$request->validated()`. No date format validation. No numeric range check on cost. No string length check on workshop_details/remarks. |
| BC-DEEP-09 | update() | L85-108 | Phase 2: Conditional service request auto-approval | Condition: `$request->status == 'Approved' && $maintenanceData->vehicle_service_request_id`. If true: fetches TptVehicleServiceRequest via find(), looks up vehicle_status dropdown value 'Service Done' via `Dropdown::where('key','tpt_vehicle_service_request.vehicle_status.vehicle_status')->where('value','Service Done')->value('id')`, then updates SR with approved_by, service_completion_date, request_approval_status='Approved', approved_at, vehicle_status. Also updates maintenanceData's approved_by and approved_at. | This links maintenance approval workflow back to the originating service request. Uses Dropdown model for `vehicle_status` FK value lookup. If dropdown 'Service Done' not found, `$vehicleStatusId` is null (L102: `?? null`). |
| BC-DEEP-10 | update() | L111-113 | After update completes | Redirects to `route('transport.vehicle-mgmt.index')` with success flash 'Vehicle maintenance updated successfully.' | Redirects to the TAB hub page (vehicle-mgmt.index), NOT to vehicle-maintenance.index. Consistent with tab-based architecture. |
| BC-DEEP-11 | destroy($id) | L121-127 | User with `tenant.vehicle-maintenance.delete` sends DELETE /vehicle-maintenance/{id} | `Gate::authorize('tenant.vehicle-maintenance.delete')` at L121. `TptVehicleMaintenance::findOrFail($id)` at L122. `$maintenance->delete()` at L123 (soft delete). `activityLog($maintenance, 'Deleted', ['message' => 'Vehicle maintenance record moved to trash'])` at L125. | Uses `findOrFail()` — throws ModelNotFoundException on invalid ID. Does NOT set `is_active = false` before delete (unlike some other controllers in the codebase). |
| BC-DEEP-12 | trashed() | L135-137 | User with `tenant.vehicle-maintenance.restore` accesses GET /vehicle-maintenance/trash/view | `Gate::authorize('tenant.vehicle-maintenance.restore')` at L135. `TptVehicleMaintenance::onlyTrashed()->paginate(20)` at L136. View at L137 uses `compact('data')` variable name `data`. | Paginates 20 per page (not 10 like index). Variable name `data` passed to view (not `maintenances` or `records`). Custom pagination size. |
| BC-DEEP-13 | restore($id) | L145-151 | User with `tenant.vehicle-maintenance.restore` accesses GET /vehicle-maintenance/{id}/restore | `Gate::authorize('tenant.vehicle-maintenance.restore')` at L145. `TptVehicleMaintenance::onlyTrashed()->findOrFail($id)` at L146. `$maintenance->restore()` at L147. `activityLog($maintenance, 'Restored', ['message' => 'Vehicle maintenance record restored'])` at L149. | Uses `onlyTrashed()` — cannot restore non-trashed records. `findOrFail()` — 404 on invalid ID. Does NOT set `is_active = true` after restore (unlike vendor controller pattern). |
| BC-DEEP-14 | forceDelete($id) | L159-165 | User with `tenant.vehicle-maintenance.forceDelete` sends DELETE /vehicle-maintenance/{id}/force-delete | `Gate::authorize('tenant.vehicle-maintenance.forceDelete')` at L159. `TptVehicleMaintenance::onlyTrashed()->findOrFail($id)` at L160. `$maintenance->forceDelete()` at L161. `activityLog($maintenance, 'Force Delete', ['message' => 'Vehicle maintenance record permanently deleted'])` at L163. | Uses `onlyTrashed()` — this means ONLY trashed records can be force-deleted. Active records cannot be force-deleted (returns 404). Standard pattern is `withTrashed()` which allows force-deleting any record. |
| BC-DEEP-15 | update() | L90-95 | Dropdown key lookup for vehicle_status | `Dropdown::where('key', 'tpt_vehicle_service_request.vehicle_status.vehicle_status')->where('value', 'Service Done')->value('id')` | Dependent on seed data existence. If this dropdown entry does not exist, `$vehicleStatusId` is null → service request's `vehicle_status` set to null. |
| BC-DEEP-16 | VehicleMgmtController@updateStatus() | L160-193 | Service Request Approval creates Maintenance | `TptVehicleMaintenance::create([...])` at L181-188 with hardcoded default values: maintenance_type='General Service', cost=0.00, status='Pending', remarks = serviceRequest->reason | This is the ONLY way maintenance records are created in the codebase. The standalone create() method renders a form but has no corresponding store() method to POST. |
| BC-DEEP-17 | VehicleMgmtController@vehicleMaintenanceQuery() | L239-309 | Tab-based maintenance query inside Vehicle Mgmt | Uses `with(['serviceRequest.inspection.vehicle', 'serviceRequest.inspection.driver', 'approvedBy'])` — correctly chains through existing relationships. Filters: search_maintenance, maintenance_status, request_status (on service request), date range (maintenance_from/to), approved_by, vehicle_type, cost_min/cost_max. | This query WORKS (unlike the standalone controller index()). All eager loads and whereHas chains use valid relationships. |
| BC-DEEP-18 | Model scopeVehicleFilter() | L82-90 (model) | Vehicle filter by ID | `whereHas('serviceRequest.vehicleInspection', function($q) use ($vehicleId) { $q->where('vehicle_id', $vehicleId); })` | Uses `vehicleInspection` relationship name on TptVehicleServiceRequest. Must check if `vehicleInspection` relationship exists or if it's `inspection`. |
| BC-DEEP-19 | Model getVehicleAttribute() | L57-60 (model) | Accessor for vehicle | Returns `$this->serviceRequest->inspection->vehicle ?? null` | N+1 risk: accessing `->serviceRequest` lazily loads the relationship each time. Cannot be eager-loaded as a relationship. |
| BC-DEEP-20 | update() | L83 | Re-fetch after mass update | `$maintenanceData = TptVehicleMaintenance::where('id',$id)->first()` | After mass update at L71-81, re-fetches the model. This is needed because the mass update returns void (not the model). Uses `first()` not `findOrFail()` — null on deleted/not-found. |
| BC-DEEP-21 | Route:updateStatus | L271 (routes) | POST /vehicle-maintenance/{id}/update-status targeting non-existent method | Route registered to `[TptVehicleMaintenanceController::class, 'updateStatus']` at web.php L271. Controller has NO `updateStatus()` method. | Symfony Component Debug Exception: "Method Modules\Transport\Http\Controllers\TptVehicleMaintenanceController::updateStatus does not exist". |
| BC-DEEP-22 | destroy() | L122-123 | Soft delete behavior | `findOrFail($id)` then `$maintenance->delete()`. Does NOT set `is_active = false` before delete. | The model does NOT have an `is_active` column. Only `deleted_at` timestamp is set. No boolean active flag maintained. |
| BC-DEEP-23 | index() | L24 | Pagination size | `->paginate(10)` — 10 records per page | Uses default page name `page`. No custom page name. In tab context, could conflict with other tab paginators. |
| BC-DEEP-24 | trashed() | L136 | Trash pagination size | `->paginate(20)` — 20 records per page (double the index page size) | Inconsistent pagination: index=10, trash=20. |
| BC-DEEP-25 | edit() | L57 | Null safety on fetch | Uses `first()` not `findOrFail()` | If ID invalid, `$maintenance` is null. Accessing `$maintenance->status` at L59 throws "Trying to get property 'status' of non-object". |

### 5.4C BC-BIZ-DEEP: VehicleMgmtController Tab Hub Integration

| BC-DEEP ID | Method | Line(s) | Condition / Trigger | Actual Code Behavior | Verification |
|------------|--------|---------|---------------------|----------------------|--------------|
| BC-DEEP-VM-01 | VehicleMgmtController@index() | L46 | Loading maintenance tab data inside hub | Calls `$this->vehicleMaintenanceQuery($request)->paginate(10)->withQueryString()` and passes as `maintenanceEntries` to view. | Uses the private query method, not the controller's index(). No `with(['vehicle','vendor','assignedTo'])` — uses correct chain `serviceRequest.inspection.vehicle`. |
| BC-DEEP-VM-02 | VehicleMgmtController@updateStatus() | L181-188 | Auto-create maintenance on SR approval | `TptVehicleMaintenance::create(['vehicle_service_request_id' => $serviceRequest->id, 'maintenance_initiation_date' => now()->format('Y-m-d'), 'maintenance_type' => 'General Service', 'cost' => 0.00, 'status' => 'Pending', 'remarks' => $serviceRequest->reason])` | Hardcoded default `maintenance_type = 'General Service'`. Cost initialized to 0. Status always 'Pending'. Remarks copied from service request reason. |
| BC-DEEP-VM-03 | VehicleMgmtController@vehicleMaintenanceQuery() | L247-263 | Search filter on maintenance tab | Searches by: vehicle_no, registration_number (via vehicle), full_name (via driver), maintenance_type, remarks, workshop_details | Uses `orWhere` within a nested `where(function(...))` closure. Searches across 6 fields spanning 3 tables. |
| BC-DEEP-VM-04 | VehicleMgmtController@vehicleMaintenanceQuery() | L266-268 | Status filter | `$query->where('status', $request->maintenance_status)` | Exact match filter on maintenance status ENUM. |
| BC-DEEP-VM-05 | VehicleMgmtController@vehicleMaintenanceQuery() | L271-275 | Service Request approval status filter | `whereHas('serviceRequest', fn($q) => $q->where('request_approval_status', $request->request_status))` | Filters maintenance records by the approval status of their linked service request. |
| BC-DEEP-VM-06 | VehicleMgmtController@vehicleMaintenanceQuery() | L278-283 | Date range filter | `whereBetween('maintenance_initiation_date', [$request->maintenance_from, $request->maintenance_to])` | Single date field (initiation), not dual date (unlike model scopeDateRange which uses initiation OR in_service). |
| BC-DEEP-VM-07 | VehicleMgmtController@vehicleMaintenanceQuery() | L286-288 | Approved by filter | `$query->where('approved_by', $request->approved_by)` | Exact match on sys_users FK. |
| BC-DEEP-VM-08 | VehicleMgmtController@vehicleMaintenanceQuery() | L293-297 | Vehicle type filter | `whereHas('serviceRequest.inspection.vehicle', fn($q) => $q->where('vehicle_type', $request->vehicle_type))` | Filters via 3-level deep relationship: maintenance→serviceRequest→inspection→vehicle. |
| BC-DEEP-VM-09 | VehicleMgmtController@vehicleMaintenanceQuery() | L300-306 | Cost range filter | `where('cost', '>=', $request->cost_min)` and `where('cost', '<=', $request->cost_max)` | Independent min/max filters. Can use either or both. |
| BC-DEEP-VM-10 | VehicleMgmtController@vehicleMaintenanceQuery() | L241-245 | Default ordering | `->orderBy('maintenance_initiation_date', 'DESC')` | Sorted by initiation date descending (most recent first). |

### 5.5 Model Relationships

| BC ID | Relationship | Type | Foreign Key | Notes |
|-------|-------------|------|-------------|-------|
| BC-REL-01 | serviceRequest() | BelongsTo TptVehicleServiceRequest | vehicle_service_request_id | Source service request that triggered maintenance |
| BC-REL-02 | approvedBy() | BelongsTo User (SchoolSetup) | approved_by | User who approved the maintenance |
| BC-REL-03 | getVehicleAttribute() | Accessor (not relationship) | via serviceRequest→inspection→vehicle | Returns Vehicle model instance through chain. Used in views |

**MISSING relationships**: Controller index() calls `with(['vehicle', 'vendor', 'assignedTo'])` but these are NOT defined:
- `vehicle` is an accessor (`getVehicleAttribute`), not a relationship — cannot be eager loaded
- `vendor` — does not exist in model at all
- `assignedTo` — does not exist in model at all

### 5.6 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|------------------|----------------|
| BC-REF-01 | vehicle_service_request_id | tpt_vehicle_service_request (id) | CASCADE |
| BC-REF-02 | approved_by | sys_users (id) | SET NULL |

### 5.7 Model Scopes

| BC ID | Scope | Query Logic | Notes |
|-------|-------|-------------|-------|
| BC-SCOPE-01 | scopePending() | `where('status', 'Pending')` | Filter for pending maintenance records |
| BC-SCOPE-02 | scopeApproved() | `where('status', 'Approved')` | Filter for approved maintenance records |
| BC-SCOPE-03 | scopeDateRange($startDate, $endDate) | `whereBetween('maintenance_initiation_date', [$startDate, $endDate])` OR `whereBetween('in_service_date', [$startDate, $endDate])` | Dual date range: initiation OR in-service date |
| BC-SCOPE-04 | scopeVehicleFilter($vehicleId) | `whereHas('serviceRequest.vehicleInspection', fn => where('vehicle_id', $vehicleId))` | Uses `vehicleInspection` relationship on TptVehicleServiceRequest |

### 5.8 activityLog Events

| BC ID | Event | Trigger | Audit Data |
|-------|-------|---------|-----------|
| BC-LOG-01 | Deleted | destroy() | `activityLog($maintenance, 'Deleted', ['message' => 'Vehicle maintenance record moved to trash'])` |
| BC-LOG-02 | Restored | restore() | `activityLog($maintenance, 'Restored', ['message' => 'Vehicle maintenance record restored'])` |
| BC-LOG-03 | Force Delete | forceDelete() | `activityLog($maintenance, 'Force Delete', ['message' => 'Vehicle maintenance record permanently deleted'])` |
| BC-LOG-04 | (Missing) | update() | **NO activityLog call** — updates silently bypass audit trail (known bug) |

---

## 5C. CODE-TRACE: Controller Method Execution Flows

### CODE-TRACE-01: index()

| Step | Code / Query | Description |
|------|-------------|-------------|
| 1 | `Gate::authorize('tenant.vehicle-maintenance.viewAny')` | L22: Authorization gate check. Returns 403 if user lacks this permission. |
| 2 | `TptVehicleMaintenance::with(['vehicle', 'vendor', 'assignedTo'])` | L24: Attempts to eager-load three relationships. `vehicle` is an accessor (not a relationship). `vendor` and `assignedTo` do NOT exist on the model. |
| 3 | `->paginate(10)` | L24: Paginates results to 10 per page. Uses default `page` query parameter. |
| 4 | `return view('transport::vehiclemaintenance.index', compact('maintenances'))` | L27: Renders index view with paginated data. **CRASHES at step 2** before reaching this line. |
| **BUG** | BadMethodCallException: "Relationship 'vendor' not found" | Because `vendor` is not a defined relationship on the model, Laravel's `with()` throws an exception. The standalone index route is completely broken. |

### CODE-TRACE-02: create()

| Step | Code / Query | Description |
|------|-------------|-------------|
| 1 | `Gate::authorize('tenant.vehicle-maintenance.create')` | L35: Authorization gate check. Returns 403 if user lacks `tenant.vehicle-maintenance.create`. |
| 2 | `return view('transport::vehiclemaintenance.create')` | L37: Renders the create form view. No data passed to view. |

### CODE-TRACE-03: show($id)

| Step | Code / Query | Description |
|------|-------------|-------------|
| 1 | `Gate::authorize('tenant.vehicle-maintenance.view')` | L45: Authorization gate check. Returns 403 if user lacks `tenant.vehicle-maintenance.view`. |
| 2 | `TptVehicleMaintenance::where('id',$id)->first()` | L46: Queries the record by ID. Uses `first()` — returns null if not found (no exception). |
| 3 | `return view('transport::vehiclemaintenance.show', compact('maintenance'))` | L47: Renders show view. If `$maintenance` is null, the view receives null and accessing properties will cause ErrorException. |
| **GAP** | No `findOrFail()` | If ID is invalid, view receives null instead of a 404 response. |

### CODE-TRACE-04: edit($id)

| Step | Code / Query | Description |
|------|-------------|-------------|
| 1 | `Gate::authorize('tenant.vehicle-maintenance.update')` | L55: Authorization gate check. Returns 403 if user lacks `tenant.vehicle-maintenance.update`. |
| 2 | `TptVehicleMaintenance::where('id',$id)->first()` | L57: Queries the record by ID. Uses `first()` — null if not found. |
| 3 | `if ($maintenance->status === 'Completed' ...)` | L59: Checks if record is Completed. **BUG**: ENUM does not include 'Completed' → condition is always false. |
| 4 | `... || $maintenance->approval_status === 'Approved'` | L59: Checks `approval_status` property. **BUG**: Model has no `approval_status` attribute; DDL has `status` ENUM. This is ALWAYS null → always false. |
| 5 | `return redirect()->back()->with('error', ...)` | L60: Redirects if blocked. **NEVER REACHED** due to bugs above. |
| 6 | `return view('transport::vehiclemaintenance.edit', compact('maintenance'))` | L63: Renders edit form. |
| **BUG-1** | `approval_status` non-existent | The guard against editing Approved records NEVER triggers because `approval_status` is not a model attribute. The correct field is `status`. |
| **BUG-2** | `'Completed'` not in ENUM | The first branch `$maintenance->status === 'Completed'` never matches because 'Completed' is not a valid ENUM value. |
| **BUG-3** | Null safety | If `$id` is invalid, `$maintenance` is null → `$maintenance->status` on null throws error at L59 before any redirect. |

### CODE-TRACE-05: update(Request $request, $id)

| Step | Code / Query | Description |
|------|-------------|-------------|
| 1 | `Gate::authorize('tenant.vehicle-maintenance.update')` | L69: Authorization gate check. Returns 403 if user lacks `tenant.vehicle-maintenance.update`. |
| 2 | **PHASE 1**: `TptVehicleMaintenance::where('id', $id)->update([...])` | L71-81: Mass update using query builder (bypasses Eloquent events). Updates 9 fields: maintenance_initiation_date, maintenance_type, cost, status, in_service_date, out_service_date, next_due_date, workshop_details, remarks. NO validation performed. |
| 3 | `$maintenanceData = TptVehicleMaintenance::where('id',$id)->first()` | L83: Re-fetches the updated record. Uses `first()` — null if record was deleted mid-request. |
| 4 | `if ($request->status == 'Approved' && $maintenanceData->vehicle_service_request_id)` | L85: Checks if maintenance was approved AND linked to a service request. |
| 5 | `$serviceRequest = TptVehicleServiceRequest::find($maintenanceData->vehicle_service_request_id)` | L86: Fetches linked service request. |
| 6 | `Dropdown::where('key','tpt_vehicle_service_request.vehicle_status.vehicle_status')->where('value','Service Done')->value('id')` | L90-95: Looks up the dropdown ID for 'Service Done' vehicle status. Returns null if seed data missing. |
| 7 | `$serviceRequest->update([...])` | L97-103: Updates SR with approved_by (Auth::user()->id), service_completion_date (now), request_approval_status ('Approved'), approved_at (now), vehicle_status ($vehicleStatusId ?? null). |
| 8 | `$maintenanceData->update(['approved_by' => Auth::user()->id, 'approved_at' => now()])` | L104-107: Updates maintenance record with approval metadata. |
| 9 | `return redirect()->route('transport.vehicle-mgmt.index')->with('success', ...)` | L111-113: Redirects to Vehicle Management tab hub with success flash. |
| **GAP-1** | No validation | Uses raw `Request $request` with no validation rules. Any malformed data is accepted. |
| **GAP-2** | No activity log | Unlike destroy/restore/forceDelete, update() has NO `activityLog()` call. Changes are not audited. |
| **GAP-3** | No change tracking | No `getOriginal()`/`getChanges()` comparison. Cannot track what changed. |
| **GAP-4** | Null safety L83 | If record deleted concurrently, `$maintenanceData` is null → L85 throws "Trying to get property 'vehicle_service_request_id' of non-object". |
| **GAP-5** | Phase 1 bypasses events | Using `::where('id',$id)->update([...])` directly fires no Eloquent events (saving/saved/updating/updated). |

### CODE-TRACE-06: destroy($id)

| Step | Code / Query | Description |
|------|-------------|-------------|
| 1 | `Gate::authorize('tenant.vehicle-maintenance.delete')` | L121: Authorization gate check. Returns 403 if user lacks `tenant.vehicle-maintenance.delete`. |
| 2 | `TptVehicleMaintenance::findOrFail($id)` | L122: Fetches record or throws ModelNotFoundException (404). |
| 3 | `$maintenance->delete()` | L123: Soft deletes the record (sets `deleted_at` timestamp). Does NOT set `is_active = false`. |
| 4 | `activityLog($maintenance, 'Deleted', ['message' => 'Vehicle maintenance record moved to trash'])` | L125: Logs the soft delete event. |
| 5 | `return redirect()->back()->with('success', 'Maintenance record moved to trash.')` | L127: Redirects back with success flash. |

### CODE-TRACE-07: trashed()

| Step | Code / Query | Description |
|------|-------------|-------------|
| 1 | `Gate::authorize('tenant.vehicle-maintenance.restore')` | L135: Authorization gate check (uses restore permission, not a separate 'viewTrash' permission). |
| 2 | `TptVehicleMaintenance::onlyTrashed()->paginate(20)` | L136: Queries only soft-deleted records. Paginates 20 per page. |
| 3 | `return view('transport::vehiclemaintenance.trash', compact('data'))` | L137: Renders trash view. Variable name `data` (not `maintenances`). |

### CODE-TRACE-08: restore($id)

| Step | Code / Query | Description |
|------|-------------|-------------|
| 1 | `Gate::authorize('tenant.vehicle-maintenance.restore')` | L145: Authorization gate check. |
| 2 | `TptVehicleMaintenance::onlyTrashed()->findOrFail($id)` | L146: Fetches only from trashed records. 404 if record is active or doesn't exist. |
| 3 | `$maintenance->restore()` | L147: Restores the soft-deleted record (sets `deleted_at = null`). Does NOT set `is_active = true`. |
| 4 | `activityLog($maintenance, 'Restored', ['message' => 'Vehicle maintenance record restored'])` | L149: Logs the restore event. |
| 5 | `return redirect()->back()->with('success', 'Maintenance record restored successfully.')` | L151: Redirects back with success flash. |

### CODE-TRACE-09: forceDelete($id)

| Step | Code / Query | Description |
|------|-------------|-------------|
| 1 | `Gate::authorize('tenant.vehicle-maintenance.forceDelete')` | L159: Authorization gate check. |
| 2 | `TptVehicleMaintenance::onlyTrashed()->findOrFail($id)` | L160: Fetches only from trashed records. **Cannot force-delete active (non-trashed) records.** |
| 3 | `$maintenance->forceDelete()` | L161: Permanently removes the record from database. |
| 4 | `activityLog($maintenance, 'Force Delete', ['message' => 'Vehicle maintenance record permanently deleted'])` | L163: Logs the permanent deletion. |
| 5 | `return redirect()->back()->with('success', 'Maintenance record permanently deleted.')` | L165: Redirects back with success flash. |
| **BUG** | Uses `onlyTrashed()` instead of `withTrashed()` | Standard pattern for force-delete is `withTrashed()` to allow deleting any record (active or trashed). With `onlyTrashed()`, calling forceDelete on an active record returns 404. |

### CODE-TRACE-10: VehicleMgmtController@updateStatus (Maintenance Auto-Creation)

| Step | Code / Query | Description |
|------|-------------|-------------|
| 1 | `$request->validate(['request_approval_status' => 'required|string|in:Approved,Rejected'])` | VehicleMgmtController L162-164: Validates approval status input. |
| 2 | `TptVehicleServiceRequest::findOrFail($id)` | L167: Fetches the service request or 404. |
| 3 | `$serviceRequest->update(['request_approval_status' => $status, ...])` | L171-175: Updates SR with approval status, approver ID, and timestamp. |
| 4 | `if ($status === 'Approved')` | L178: Only auto-creates maintenance if status is 'Approved'. |
| 5 | `TptVehicleMaintenance::create([...])` | L181-188: Creates maintenance with hardcoded defaults: `maintenance_type='General Service'`, `cost=0.00`, `status='Pending'`, `remarks=$serviceRequest->reason`, `maintenance_initiation_date=today`. |
| 6 | `return redirect()->back()->with('success', ...)` | L190-192: Redirects back with appropriate success message. |

---

## 6. Test Case List

### 6.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | Maintenance Tab Loads Inside Vehicle Mgmt | `/vehicle-mgmt` loads Maintenance tab with filter bar | — | — | ⬜ |
| TC-P02 | View Maintenance Record Details | Show page displays Initiation Date, Type, Cost, In/Out Service Dates, Workshop, Status, Approval info | — | — | ⬜ |
| TC-P03 | Edit Maintenance Loads Pre-Filled Data | Edit form shows existing values (unless status is Completed/Approved) | — | — | ⬜ |
| TC-P04 | Update Maintenance — Change Type and Cost | PUT updates record; redirect with success flash | — | — | ⬜ |
| TC-P05 | Update Maintenance — Set status=Approved | Linked service request auto-updated to 'Service Done' and Approved | — | — | ⬜ |
| TC-P06 | Update Maintenance — Set out_service_date after in_service_date | Validation passes | — | — | ⬜ |
| TC-P07 | Soft Delete Maintenance | DELETE → deleted_at set | — | — | ⬜ |
| TC-P08 | Restore Maintenance | Restore → deleted_at=NULL | — | — | ⬜ |
| TC-P09 | Force Delete Trashed Maintenance | forceDelete → permanent removal | — | — | ⬜ |
| TC-P10 | Filter By Maintenance Status | maintenance_status filter → matching entries | — | — | ⬜ |
| TC-P11 | Filter By Date Range | maintenance_from / maintenance_to → filtered results | — | — | ⬜ |
| TC-P12 | Filter By Cost Range | cost_min / cost_max → filtered results | — | — | ⬜ |
| TC-P13 | Full Lifecycle (via service request approval) | Approve SR → Maintenance auto-created → View → Edit → Delete → Restore → Force Delete | — | — | ⬜ |
| TC-P14 | Create Form Loads | GET `/vehicle-maintenance/create` renders create.blade.php | — | — | ⬜ |
| TC-P15 | Trash Page Loads | GET `/vehicle-maintenance/trash/view` lists only soft-deleted records | — | — | ⬜ |
| TC-P16 | Destroy Logs Activity | `activityLog()` called with event='Deleted' and message about trash | — | — | ⬜ |
| TC-P17 | Restore Logs Activity | `activityLog()` called with event='Restored' after restore | — | — | ⬜ |
| TC-P18 | Force Delete Logs Activity | `activityLog()` called with event='Force Delete' after permanent delete | — | — | ⬜ |
| TC-P19 | Model Scope Pending | `TptVehicleMaintenance::pending()` returns only status='Pending' records | — | — | ⬜ |
| TC-P20 | Model Scope Approved | `TptVehicleMaintenance::approved()` returns only status='Approved' records | — | — | ⬜ |
| TC-P21 | Model Scope DateRange | `scopeDateRange($from, $to)` filters by initiation_date OR in_service_date | — | — | ⬜ |
| TC-P22 | Update Maintenance — Empty Optional Fields | Update with null in_service_date, out_service_date, next_due_date, workshop_details, remarks succeeds | — | — | ⬜ |
| TC-P23 | Update Maintenance — Approved Status Updates approved_by and approved_at | When status='Approved', the maintenance record's approved_by and approved_at fields are populated | — | — | ⬜ |
| TC-P24 | Restore After Force Delete Prevention | Once forceDeleted, the record is permanently gone and restore returns 404 | — | — | ⬜ |

### 6.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | Edit Completed Maintenance | Redirect back with error: "Completed or Approved maintenance records cannot be updated." | — | — | ⬜ |
| TC-N02 | Edit Maintenance — Non-Existent approval_status Field | Controller checks `$maintenance->approval_status === 'Approved'` but model has NO `approval_status` attribute (has `status`). This condition will NEVER match → Completed records can be edited incorrectly | — | — | ⬜ |
| TC-N03 | View With Invalid ID | show() uses `where('id',$id)->first()` → null → view may crash | — | — | ⬜ |
| TC-N04 | Edit With Invalid ID | `where('id',$id)->first()` returns null → null passed to view | — | — | ⬜ |
| TC-N05 | Force Delete Non-Trashed Record | forceDelete uses `onlyTrashed()` → 404 | — | — | ⬜ |
| TC-N06 | store() Not Implemented | POST `/vehicle-maintenance` → 405 Method Not Allowed | — | — | ⬜ |
| TC-N07 | updateStatus Route — No Controller Method | POST `/vehicle-maintenance/{id}/update-status` → 500 error | — | — | ⬜ |
| TC-N08 | Permission 403 — No Permissions | 403 on all endpoints | — | — | ⬜ |
| TC-N09 | Guest Access Redirect | Redirect to `/login` | — | — | ⬜ |
| TC-N10 | Update Does Not Log Activity | update() has no `activityLog()` call — changes silently bypass audit trail | — | — | ⬜ |
| TC-N11 | Update With Invalid Cost (Negative Value) | update() uses raw Request with NO validation — negative cost accepted into DB | — | — | ⬜ |
| TC-N12 | Update With Excessively Long workshop_details (>512 chars) | No validation — string truncated at DB level or stored as-is depending on DB mode | — | — | ⬜ |
| TC-N13 | Restore Active (Non-Trashed) Record | restore() uses `onlyTrashed()` → 404 on active record | — | — | ⬜ |
| TC-N14 | Permission 403 — Missing Specific Gate (view) | User with create but no view → 403 on show() | — | — | ⬜ |
| TC-N15 | Permission 403 — Missing Specific Gate (update) | User with view but no update → 403 on edit() and update() | — | — | ⬜ |

### 6.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|----------------|---------|---------|--------|
| TC-D01 | A | Maintenance Auto-Created From Service Request Approval | When service request approved, maintenance record created with status=Pending, cost=0 | — | — | ⬜ |
| TC-D02 | B | Service Request Deletion Cascades (CASCADE) | Deleting a service request auto-deletes its maintenance records | — | — | ⬜ |
| TC-D03 | C | Update Status to Approved — Service Request Auto-Update | Update maintenance status=Approved → linked service request status changes to 'Approved', vehicle_status='Service Done' | — | — | ⬜ |
| TC-D04 | C | Unused Policy Gates in TransportVehicleMaintenancePolicy | Policy has import/export/print/schedule/complete/viewHistory gates but controller has NO methods using them — dead permissions | — | — | ⬜ |
| TC-D05 | A | VehicleMgmtController @index loads all 5 tabs | Maintenance tab data loads correctly via vehicleMaintenanceQuery() (not standalone index) | — | — | ⬜ |
| TC-D06 | B | FK approved_by ON DELETE SET NULL | When approved_by user is deleted, maintenance record's approved_by is set to NULL | — | — | ⬜ |
| TC-D07 | C | Service Request Approved After Maintenance Update | When maintenance status updated to Approved with linked SR, the SR gets approved_by and completion_date set | — | — | ⬜ |

### 6.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|-----------------|---------|---------|--------|
| TC-CR01 | CR | P1 | Controller — index() Uses Non-Existent Relationships | Line 24: `TptVehicleMaintenance::with(['vehicle', 'vendor', 'assignedTo'])` — model has NO `vendor` or `assignedTo` relationships. `vehicle` is an accessor, not a relationship → **BadMethodCallException** | — | — | ◌ |
| TC-CR02 | CR | P1 | Controller — No store() Method | `Route::resource('vehicle-maintenance', ...)` generates store route but controller has NO store() method. POST returns 405 | — | — | ◌ |
| TC-CR03 | CR | P1 | Controller — update() Uses Raw `Request` Not FormRequest | Does NOT type-hint `TptVehicleMaintenanceRequest` — uses base `Request $request` with zero validation | — | — | ◌ |
| TC-CR04 | CR | P1 | Controller — update() No Activity Log | No `activityLog()` call — updates silently happen without audit trail | — | — | ◌ |
| TC-CR05 | CR | P1 | Controller — update() No Change Tracking | No getOriginal()/getChanges() comparison — no audit of what changed | — | — | ◌ |
| TC-CR06 | CR | P1 | Controller — edit() References Non-Existent `approval_status` | Line 59: `$maintenance->approval_status === 'Approved'` — model fillable has `status`, not `approval_status`. DDL has `status` ENUM. This condition ALWAYS evaluates to false/null | — | — | ◌ |
| TC-CR07 | CR | P1 | Controller — edit() Null Safety | `where('id',$id)->first()` returns null on bad ID → `$maintenance->status` on null → error | — | — | ◌ |
| TC-CR08 | CR | P1 | Controller — forceDelete Uses `onlyTrashed()` | Line 160: `TptVehicleMaintenance::onlyTrashed()->findOrFail($id)` — cannot force-delete active records; should use `withTrashed()` | — | — | ◌ |
| TC-CR09 | CR | P1 | Controller — No updateStatus Method Despite Route | Route line 271: `POST /vehicle-maintenance/{id}/update-status` registered but controller has NO `updateStatus()` method → 500 error | — | — | ◌ |
| TC-CR10 | CR | P1 | Request — Exists But Not Used | `TptVehicleMaintenanceRequest` fully defined with validation rules, messages, and attributes — but controller's update() ignores it | — | — | ◌ |
| TC-CR11 | CR | P1 | Model — Fillable Matches DDL | 12 fillable fields: vehicle_service_request_id, maintenance_initiation_date, maintenance_type, cost, in_service_date, out_service_date, workshop_details, next_due_date, remarks, status, approved_by, approved_at | — | — | ◌ |
| TC-CR12 | CR | P1 | Model — `vendor` and `assignedTo` Relationships Missing | Controller tries to eager-load these but they don't exist in model | — | — | ◌ |
| TC-CR13 | CR | P1 | Model — `getVehicleAttribute` Accessor vs Relationship | Accessor returns `$this->serviceRequest->inspection->vehicle` — cannot be eager-loaded; causes N+1 queries | — | — | ◌ |
| TC-CR14 | CR | P1 | Model — Incorrect `vehicleFilter` Scope | Line 85: `whereHas('serviceRequest.vehicleInspection', ...)` uses `vehicleInspection` but model's relationship is named `inspection` and `vehicleInspection` — this scope will NOT work | — | — | ◌ |
| TC-CR15 | CR | P1 | Activity Log — Only 3 Events | Only Deleted, Restored, Force Delete logged. No Created, Updated, Approved events unlike other entities | — | — | ◌ |
| TC-CR16 | CR | P2 | Two Policy Files Exist — One Unused | `TransportVehicleMaintenancePolicy` (registered) and `TptVehicleMaintenancePolicy` (NOT registered) are both present. The unused one has 8 gates and may cause confusion | — | — | ◌ |
| TC-CR17 | CR | P2 | `status` Permission Gate Exists but Unused in Controller | Policy has `status()` method checking `tenant.vehicle-maintenance.status` but `TptVehicleMaintenanceController` has NO `updateStatus()` method (route exists → 500). `VehicleMgmtController@updateStatus()` handles SR approval, not maintenance status | — | — | ◌ |
| TC-CR18 | CR | P2 | edit() Checks Non-Existent 'Completed' ENUM Value | Line 59 checks `$maintenance->status === 'Completed'` but ENUM only has 'Approved','Pending','Rejected'. This condition NEVER matches. | — | — | ◌ |
| TC-CR19 | CR | P2 | update() Bypasses Eloquent Events | Uses `TptVehicleMaintenance::where('id', $id)->update([...])` instead of `$maintenance->update([...])` — no model events fired | — | — | ◌ |
| TC-CR20 | CR | P2 | destroy() Does Not Set is_active | Unlike VendorController pattern, destroy() does NOT set `is_active = false` before soft delete | — | — | ◌ |
| TC-CR21 | CR | P2 | Inconsistent Pagination (index=10, trash=20) | index() paginates 10, trashed() paginates 20 — inconsistent user experience | — | — | ◌ |
| TC-CR22 | CR | P2 | Permissionslist Allows 14+ Actions but Controller Only Uses 7 | `vehicle-maintenance` in permissionslist.php uses full `$crud` array but controller only has 7 Gate::authorize() calls | — | — | ◌ |
| TC-CR23 | CR | P2 | update() Re-fetches Model Without findOrFail | L83 uses `first()` not `findOrFail()` — null on deleted record causes error at L85 | — | — | ◌ |

---

## 7. Detailed Test Steps

### TC-P01: Maintenance Tab Loads Inside Vehicle Mgmt

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Log in as user with `tenant.transport.viewAny` and `tenant.vehicle-maintenance.viewAny` permissions | Dashboard loads |
| 2 | Navigate to GET `/vehicle-mgmt` | Vehicle Management hub page loads with 5 tabs |
| 3 | Click the "Maintenance" tab (or tab with maintenance content) | Tab pane displays correctly with filter bar |
| 4 | Verify the search bar contains: search_maintenance input, maintenance_status dropdown, date range pickers, cost range inputs, vehicle_type dropdown | All filter controls visible |
| 5 | Verify the maintenance table headers are rendered | Table columns: Vehicle, Type, Initiation Date, Cost, Status, Workshop, Action |
| 6 | Verify no 500 errors in console/log | Page loads successfully, no exceptions in Laravel log |

### TC-P02: View Maintenance Record Details

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a maintenance record via Service Request approval (approve a service request) | Maintenance created with status='Pending' |
| 2 | Navigate to the maintenance record's show page: GET `/vehicle-maintenance/{id}` | Show page renders |
| 3 | Verify display of: maintenance_initiation_date, maintenance_type, cost, in_service_date (if set), out_service_date (if set), workshop_details, status, next_due_date, remarks | All fields displayed |
| 4 | Verify approval info section: approved_by, approved_at (shown if set) | Approval meta displayed when applicable |
| 5 | Verify Back button exists | `<a href="...">Back</a>` or action button present |

### TC-P03: Edit Maintenance Loads Pre-Filled Data

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a maintenance record with status='Pending' | Record ready |
| 2 | Navigate to GET `/vehicle-maintenance/{id}/edit` | Edit form loads with existing values pre-filled |
| 3 | Verify maintenance_type field shows current value | Input populated |
| 4 | Verify cost field shows current value | Input populated |
| 5 | Verify dates (in_service_date, out_service_date, next_due_date) are pre-filled if set | Date inputs show stored values |
| 6 | Verify status dropdown reflects current status | Default selected = current status |
| 7 | Verify workshop_details and remarks fields show current values | Textareas populated |

### TC-P04: Update Maintenance — Change Type and Cost

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Have a maintenance record with status='Pending', maintenance_type='Oil Change', cost=150.00 | Pre-condition met |
| 2 | Send PUT `/vehicle-maintenance/{id}` with: maintenance_type='Full Service', cost=350.00, status='Pending' | No validation error |
| 3 | Redirect to `/vehicle-mgmt` (Vehicle Management tab hub) | URL ends with `/vehicle-mgmt` |
| 4 | Verify flash message: "Vehicle maintenance updated successfully." | Success toast/alert displayed |
| 5 | Navigate to maintenance show page for same record | Verify maintenance_type='Full Service', cost=350.00 |
| 6 | Check database directly: `SELECT * FROM tpt_vehicle_maintenance WHERE id = {id}` | Fields updated correctly |

### TC-P05: Update Maintenance — Set status=Approved

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Have a maintenance record with status='Pending', vehicle_service_request_id pointing to a valid service request | Pre-condition met |
| 2 | Ensure a Dropdown entry exists: key='tpt_vehicle_service_request.vehicle_status.vehicle_status', value='Service Done' | Seed data present |
| 3 | Send PUT `/vehicle-maintenance/{id}` with: status='Approved' | Update succeeds |
| 4 | Check maintenance record: `approved_by` = current user ID, `approved_at` = now | Approval meta populated |
| 5 | Check linked service request at `tpt_vehicle_service_request`: `request_approval_status='Approved'`, `approved_by` = current user ID, `service_completion_date` = today, `approved_at` = now, `vehicle_status` = ID of 'Service Done' dropdown | Service request fully approved and completed |
| 6 | Verify redirect to `/vehicle-mgmt` with success flash | Operation completes cleanly |

### TC-P06: Update Maintenance — Set out_service_date After in_service_date

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Have a maintenance record | Pre-condition met |
| 2 | Send PUT `/vehicle-maintenance/{id}` with: in_service_date=2026-06-01, out_service_date=2026-06-05, status='Pending' | **NOTE**: No validation in controller → update succeeds regardless |
| 3 | Verify redirect with success flash | Update accepted |
| 4 | Verify in DB: in_service_date=2026-06-01, out_service_date=2026-06-05 | Values stored correctly |

### TC-P07: Soft Delete Maintenance

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Have an active maintenance record (deleted_at IS NULL) | Pre-condition met |
| 2 | Send DELETE `/vehicle-maintenance/{id}` | Request succeeds |
| 3 | Verify flash: "Maintenance record moved to trash." | Success message displayed |
| 4 | Check DB: `SELECT deleted_at FROM tpt_vehicle_maintenance WHERE id = {id}` | `deleted_at` is NOT NULL (timestamp set) |
| 5 | Query the model with `::withTrashed()->find(id)` | Record still exists with deleted_at set |

### TC-P08: Restore Maintenance

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Have a soft-deleted maintenance record | Pre-condition met |
| 2 | Navigate to GET `/vehicle-maintenance/trash/view` | Trash page shows the deleted record |
| 3 | Click Restore or send GET `/vehicle-maintenance/{id}/restore` | Redirect back with success |
| 4 | Verify flash: "Maintenance record restored successfully." | Success message displayed |
| 5 | Check DB: `SELECT deleted_at FROM tpt_vehicle_maintenance WHERE id = {id}` | `deleted_at` is NULL |
| 6 | Query with `::find(id)` | Record accessible again |

### TC-P09: Force Delete Trashed Maintenance

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Have a soft-deleted maintenance record | Pre-condition met |
| 2 | Navigate to GET `/vehicle-maintenance/trash/view` | Trash page shows the deleted record |
| 3 | Click Force Delete or send DELETE `/vehicle-maintenance/{id}/force-delete` | Redirect back with success |
| 4 | Verify flash: "Maintenance record permanently deleted." | Success message displayed |
| 5 | Check DB: `SELECT * FROM tpt_vehicle_maintenance WHERE id = {id}` | Record does NOT exist (permanently removed) |

### TC-P10: Filter By Maintenance Status

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Have multiple maintenance records with status='Pending' and status='Approved' | Mixed data |
| 2 | Navigate to `/vehicle-mgmt?tab=maintenance&maintenance_status=Pending` | Only Pending records shown |
| 3 | Verify table row count matches number of Pending records | Correct filter applied |
| 4 | Change filter to `maintenance_status=Approved` | Only Approved records shown |
| 5 | Clear filter | All records shown again |

### TC-P11: Filter By Date Range

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Have maintenance records with various initiation dates | Mixed dates |
| 2 | Navigate to `/vehicle-mgmt?tab=maintenance&maintenance_from=2026-01-01&maintenance_to=2026-06-30` | Only records with initiation_date in that range shown |
| 3 | Verify against known record dates | Results match date boundary |
| 4 | Test with empty results range (e.g. dates in 2025) | Empty table with "No records found" message |

### TC-P12: Filter By Cost Range

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Have maintenance records: cost=100, cost=500, cost=1000 | Mixed costs |
| 2 | Filter: `cost_min=200&cost_max=800` | Only record with cost=500 shown |
| 3 | Filter: `cost_min=500` without cost_max | Records with cost >= 500 shown |
| 4 | Filter: `cost_max=500` without cost_min | Records with cost <= 500 shown |

### TC-P13: Full Lifecycle (via Service Request Approval)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a Daily Vehicle Inspection | Inspection exists |
| 2 | Create a Service Request linked to that inspection | SR created with status='Pending' |
| 3 | Approve the Service Request via VehicleMgmtController@updateStatus with status='Approved' | SR approved, maintenance auto-created |
| 4 | Verify maintenance auto-created: `maintenance_type='General Service'`, `cost=0.00`, `status='Pending'`, `remarks=SR.reason`, `maintenance_initiation_date=today` | Auto-creation works |
| 5 | Navigate to show page for the new maintenance Record details visible | |
| 6 | Edit the maintenance: update type to 'Brake Repair', cost to 250.00 | Update succeeds |
| 7 | Soft delete the maintenance | Record moved to trash |
| 8 | Navigate to trash view | Record visible in trash |
| 9 | Restore the maintenance | Record restored |
| 10 | Force delete the maintenance | Record permanently removed |

### TC-P14: Create Form Loads

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Log in as user with `tenant.vehicle-maintenance.create` permission | Authenticated |
| 2 | Navigate to GET `/vehicle-maintenance/create` | Create form renders |
| 3 | Verify form elements present: maintenance_initiation_date, maintenance_type, cost, in_service_date, out_service_date, next_due_date, workshop_details, remarks | All fields present |
| 4 | Verify status field (default='Pending') | Status dropdown shows Pending as default |
| 5 | Verify submit button exists | Save/Create button present |
| 6 | **NOTE**: POST to this form will result in 405 since NO store() method exists in controller | Form is present but cannot be submitted |

### TC-P15: Trash Page Loads

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Have at least one soft-deleted maintenance record | Pre-condition |
| 2 | Navigate to GET `/vehicle-maintenance/trash/view` | Trash page renders |
| 3 | Verify only soft-deleted records shown (deleted_at IS NOT NULL) | No active records in list |
| 4 | Verify Restore and Force Delete action buttons present for each record | Actions available |
| 5 | Verify empty state when no trashed records exist | "No trashed records found" message |

### TC-P16: Destroy Logs Activity

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Have a maintenance record | Pre-condition |
| 2 | Send DELETE `/vehicle-maintenance/{id}` | Soft delete succeeds |
| 3 | Check activity_log table: event='Deleted', message='Vehicle maintenance record moved to trash', model_type='Modules\Transport\Models\TptVehicleMaintenance' | Activity logged |
| 4 | Verify performed_by shows current user name/ID | Performer captured |

### TC-P17: Restore Logs Activity

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Have a soft-deleted maintenance record | Pre-condition |
| 2 | Send GET `/vehicle-maintenance/{id}/restore` | Restore succeeds |
| 3 | Check activity_log table: event='Restored', message='Vehicle maintenance record restored' | Activity logged |

### TC-P18: Force Delete Logs Activity

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Have a soft-deleted maintenance record | Pre-condition |
| 2 | Send DELETE `/vehicle-maintenance/{id}/force-delete` | Force delete succeeds |
| 3 | Check activity_log table: event='Force Delete', message='Vehicle maintenance record permanently deleted' | Activity logged |

### TC-P19: Model Scope Pending

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Have records with status='Pending' and status='Approved' | Mixed data |
| 2 | Run in tinker: `TptVehicleMaintenance::pending()->get()` | Only records with status='Pending' returned |
| 3 | Verify SQL: `SELECT * FROM tpt_vehicle_maintenance WHERE status = 'Pending' AND deleted_at IS NULL` | Correct where clause |

### TC-P20: Model Scope Approved

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Have records with status='Pending' and status='Approved' | Mixed data |
| 2 | Run in tinker: `TptVehicleMaintenance::approved()->get()` | Only records with status='Approved' returned |
| 3 | Verify SQL: `SELECT * FROM tpt_vehicle_maintenance WHERE status = 'Approved' AND deleted_at IS NULL` | Correct where clause |

### TC-P21: Model Scope DateRange

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Have records with different maintenance_initiation_date and in_service_date values | Mixed data |
| 2 | Run in tinker: `TptVehicleMaintenance::dateRange('2026-01-01', '2026-06-30')->get()` | Records where initiation_date OR in_service_date falls in range returned |
| 3 | Verify SQL uses OR between the two date conditions | Correct dual-date logic |

### TC-P22: Update Maintenance — Empty Optional Fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Have a maintenance record with all optional fields populated | Pre-condition |
| 2 | Send PUT `/vehicle-maintenance/{id}` with: in_service_date='', out_service_date='', next_due_date='', workshop_details='', remarks='', status='Pending' | Update succeeds (no validation to reject empty strings) |
| 3 | Verify DB: in_service_date=NULL, out_service_date=NULL, next_due_date=NULL, workshop_details=NULL, remarks=NULL | Fields set to null/empty |
| 4 | **NOTE**: Empty string vs NULL depends on how PHP/DB handles it | May store '' instead of NULL |

### TC-P23: Update Maintenance — Approved Status Populates Approval Meta

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Have a maintenance with status='Pending', approved_by=NULL, approved_at=NULL | Pre-condition |
| 2 | Send PUT `/vehicle-maintenance/{id}` with status='Approved' | Update succeeds |
| 3 | Check DB: approved_by = current user's ID, approved_at is a valid timestamp | Approval meta populated at L104-107 |
| 4 | Verify these values via show page | Displayed as approved by user on date |

### TC-P24: Restore After Force Delete Prevention

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Have a soft-deleted maintenance record | Pre-condition |
| 2 | Force delete it via DELETE `/vehicle-maintenance/{id}/force-delete` | Permanently removed |
| 3 | Attempt GET `/vehicle-maintenance/{id}/restore` | 404 — record not found |
| 4 | Verify: record is gone from both active and trashed queries | Fully deleted |

---

### TC-N01: Edit Completed Maintenance

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a maintenance record with status='Approved' (via update) | Record exists |
| 2 | Navigate to GET `/vehicle-maintenance/{id}/edit` | **BUG**: Edit form loads because `approval_status` guard is non-functional |
| 3 | Check if any error flash appears: "Completed or Approved maintenance records cannot be updated." | **NO error shown** due to bug in guard condition |
| 4 | Attempt to update the record | Update succeeds (should have been blocked) |
| 5 | **BUG CONFIRMED**: The edit guard at line 59 never triggers because `approval_status` property doesn't exist and 'Completed' is not in ENUM | Approved records can be edited despite intent of guard |

### TC-N02: Edit Maintenance — Non-Existent approval_status Field

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Examine `TptVehicleMaintenance` model fillable array | Only `status` is in fillable, NOT `approval_status` |
| 2 | Examine DDL for `tpt_vehicle_maintenance` | Column `status` is ENUM('Approved','Pending','Rejected'). No `approval_status` column exists |
| 3 | In tinker: `$m = TptVehicleMaintenance::first(); $m->approval_status` | Returns null (Laravel model attribute access returns null for undefined attributes) |
| 4 | Verify the guard at controller line 59: `$maintenance->approval_status === 'Approved'` | ALWAYS evaluates to false because `approval_status` is null |
| 5 | **BUG CONFIRMED**: The guard is completely non-functional | Should check `$maintenance->status === 'Approved'` instead |

### TC-N03: View With Invalid ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to GET `/vehicle-maintenance/999999` (non-existent ID) | show() called with non-existent ID |
| 2 | Controller executes L46: `TptVehicleMaintenance::where('id',999999)->first()` | Returns null |
| 3 | View receives `$maintenance = null` | Layout renders but content section may error |
| 4 | If view accesses `$maintenance->status` or similar | ErrorException: "Trying to get property 'status' of non-object" |
| 5 | **BUG CONFIRMED**: Should use `findOrFail($id)` to return 404 | Null passed to view causes potential crash |

### TC-N04: Edit With Invalid ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to GET `/vehicle-maintenance/999999/edit` (non-existent ID) | edit() called |
| 2 | Controller executes L57: `TptVehicleMaintenance::where('id',999999)->first()` | Returns null |
| 3 | Controller L59: `$maintenance->status` on null | ErrorException before redirect or view |
| 4 | No redirect, no error flash — direct HTTP 500 | "Trying to get property 'status' of non-object" |
| 5 | **BUG CONFIRMED**: Null safety issue; should use `findOrFail()` | Null pointer exception |

### TC-N05: Force Delete Non-Trashed Record

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Have an active (non-deleted) maintenance record | deleted_at IS NULL |
| 2 | Send DELETE `/vehicle-maintenance/{id}/force-delete` | forceDelete() called |
| 3 | Controller L160: `TptVehicleMaintenance::onlyTrashed()->findOrFail($id)` | Throws ModelNotFoundException (404) because record is not in trashed scope |
| 4 | HTTP 404 response returned | Record not found error |
| 5 | **BUG CONFIRMED**: Should use `withTrashed()` not `onlyTrashed()` | Cannot force-delete active records |

### TC-N08: Permission 403 — No Permissions

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Log in as user with NO `tenant.vehicle-maintenance.*` permissions | Authenticated but unauthorized |
| 2 | Access GET `/vehicle-maintenance` | index() → Gate::authorize fails → 403 |
| 3 | Access GET `/vehicle-maintenance/create` | create() → Gate::authorize fails → 403 |
| 4 | Access GET `/vehicle-maintenance/{id}` | show() → Gate::authorize fails → 403 |
| 5 | Access GET `/vehicle-maintenance/{id}/edit` | edit() → Gate::authorize fails → 403 |
| 6 | Access GET `/vehicle-maintenance/trash/view` | trashed() → Gate::authorize fails → 403 |
| 7 | Send DELETE `/vehicle-maintenance/{id}` | destroy() → Gate::authorize fails → 403 |
| 8 | Send DELETE `/vehicle-maintenance/{id}/force-delete` | forceDelete() → Gate::authorize fails → 403 |

### TC-N09: Guest Access Redirect

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Log out or use incognito session | Unauthenticated |
| 2 | Access any `/vehicle-maintenance*` URL | Redirected to `/login` |
| 3 | Verify no 403 or 500 — clean redirect | 302 redirect to login page |

### TC-N10: Update Does Not Log Activity

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Have a maintenance record | Pre-condition |
| 2 | Send PUT `/vehicle-maintenance/{id}` with updated cost | Update succeeds |
| 3 | Check activity_log table for any entry with event='Updated' or similar | **NO entry found** for the update |
| 4 | Check for event='Deleted' (should not exist since we didn't delete) | Not present |
| 5 | **BUG CONFIRMED**: update() has NO activityLog() call | Update silently changes record without audit trail |

### TC-N11: Update With Invalid Cost (Negative Value)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Have a maintenance record | Pre-condition |
| 2 | Send PUT `/vehicle-maintenance/{id}` with cost=-100.00 | **BUG**: No validation — request accepted |
| 3 | Check DB: `SELECT cost FROM tpt_vehicle_maintenance WHERE id = {id}` | cost = -100.00 stored in DB |
| 4 | **BUG CONFIRMED**: No validation on cost field | Negative costs accepted and stored |
| 5 | Test with cost=99999999999.99 (exceeds max) | Stored as-is or truncated at DB level depending on DECIMAL precision |

### TC-N12: Update With Excessively Long workshop_details

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Generate a string of 600 characters | Test data |
| 2 | Send PUT `/vehicle-maintenance/{id}` with workshop_details={600-char string} | **BUG**: No validation — accepted |
| 3 | Check DB storage | May be truncated at VARCHAR(512) limit or error depending on strict mode |
| 4 | **BUG CONFIRMED**: No max:512 validation | Data integrity risk |

### TC-N13: Restore Active (Non-Trashed) Record

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Have an active maintenance record (deleted_at IS NULL) | Pre-condition |
| 2 | Send GET `/vehicle-maintenance/{id}/restore` | restore() called |
| 3 | Controller L146: `TptVehicleMaintenance::onlyTrashed()->findOrFail($id)` | ModelNotFoundException — record not in onlyTrashed scope |
| 4 | HTTP 404 | Cannot restore an active record |

### TC-N14: Permission 403 — Missing Specific Gate (view)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Log in as user with `tenant.vehicle-maintenance.viewAny` but NOT `tenant.vehicle-maintenance.view` | Partial permissions |
| 2 | Access GET `/vehicle-maintenance/{id}` | show() → Gate::authorize('tenant.vehicle-maintenance.view') → 403 |
| 3 | But the index page loads (viewAny permission suffices) | index() works, show() returns 403 |

### TC-N15: Permission 403 — Missing Specific Gate (update)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Log in as user with `tenant.vehicle-maintenance.view` but NOT `tenant.vehicle-maintenance.update` | Partial permissions |
| 2 | Access GET `/vehicle-maintenance/{id}/edit` | edit() → Gate::authorize('tenant.vehicle-maintenance.update') → 403 |
| 3 | Send PUT `/vehicle-maintenance/{id}` | update() → Gate::authorize('tenant.vehicle-maintenance.update') → 403 |
| 4 | Verify show() still works with view permission | show() returns 200 |

---

### TC-D01: Maintenance Auto-Created From Service Request Approval

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Have a TptDailyVehicleInspection record for a vehicle | Pre-condition A |
| 2 | Create a TptVehicleServiceRequest linked to that inspection, status='Pending' | SR exists |
| 3 | Send POST to VehicleMgmtController@updateStatus: `request_approval_status=Approved` | SR approved |
| 4 | Check tpt_vehicle_maintenance table for new record with vehicle_service_request_id = SR.id | New maintenance record created |
| 5 | Verify maintenance defaults: maintenance_type='General Service', cost=0.00, status='Pending', remarks=SR.reason | Hardcoded defaults applied (L181-188 of VehicleMgmtController) |
| 6 | Verify maintenance_initiation_date = today's date | Current date set |

### TC-D02: Service Request Deletion Cascades (CASCADE)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Have a maintenance record with vehicle_service_request_id = 100 | Pre-condition |
| 2 | DELETE FROM tpt_vehicle_service_request WHERE id = 100 (direct DB delete) | CASCADE trigger |
| 3 | Check tpt_vehicle_maintenance: record where vehicle_service_request_id = 100 | Maintenance record also DELETED (hard delete via CASCADE) |
| 4 | Check if maintenance uses SoftDeletes — CASCADE bypasses soft delete | Record is physically deleted, not soft-deleted. The FK CASCADE operates at DB level, bypassing Laravel's SoftDeletes |

### TC-D03: Update Status to Approved — Service Request Auto-Update

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Have a maintenance record with status='Pending', linked to a service request with request_approval_status='Pending' | Pre-condition |
| 2 | Verify dropdown 'Service Done' exists in dropdowns table: key='tpt_vehicle_service_request.vehicle_status.vehicle_status', value='Service Done' | Seed data check |
| 3 | Send PUT `/vehicle-maintenance/{id}` with status='Approved' | Update triggers approval workflow |
| 4 | Check maintenance record: approved_by set, approved_at set | Maintenance approved |
| 5 | Check service request: request_approval_status='Approved', approved_by=current user, service_completion_date=today, vehicle_status = 'Service Done' dropdown ID | Service request reflects maintenance approval |
| 6 | If dropdown does NOT exist: vehicle_status = null on SR (?? null fallback L102) | Graceful fallback |

### TC-D04: Unused Policy Gates

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `TransportVehicleMaintenancePolicy` | 14 gates defined |
| 2 | Check which methods exist in `TptVehicleMaintenanceController` | 10 methods: index, create, show, edit, update, destroy, trashed, restore, forceDelete (NO import/export/print/schedule/complete/viewHistory/status methods) |
| 3 | Verify `import` gate in policy → `$user->can('tenant.vehicle-maintenance.import')` | No controller method calls this gate |
| 4 | Verify `export` gate | No controller method calls this gate |
| 5 | Verify `print` gate | No controller method calls this gate |
| 6 | Verify `schedule` gate | No controller method calls this gate |
| 7 | Verify `complete` gate | No controller method calls this gate |
| 8 | Verify `viewHistory` gate | No controller method calls this gate |
| 9 | **OBSERVATION**: 7 out of 14 policy gates are dead code | Policy can be trimmed or future methods need implementation |

### TC-D05: VehicleMgmtController @index Loads All 5 Tabs

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Have data for: Vehicles, Routes, Driver Helpers, Shifts, Fuel, Inspections, Service Requests, Maintenance | All tabs have data |
| 2 | Navigate to GET `/vehicle-mgmt` | Page loads |
| 3 | Verify all 5 tabs render without error | Each tab pane has correct data |
| 4 | Check maintenance tab data loads via `vehicleMaintenanceQuery()` (private method L239) | Maintenance records load correctly with eager loading through serviceRequest → inspection → vehicle |
| 5 | No BadMethodCallException | Because VM controller uses correct relationship chain, not the broken standalone index() query |

### TC-D06: FK approved_by ON DELETE SET NULL

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Have maintenance with approved_by = user_id = 5 | Pre-condition |
| 2 | DELETE FROM sys_users WHERE id = 5 (direct DB or via user deletion) | User deleted |
| 3 | Check maintenance record: approved_by = NULL | SET NULL constraint fired |
| 4 | Verify maintenance record still exists (no cascade delete) | Only approved_by set to null, record intact |

### TC-D07: Service Request Approved After Maintenance Update

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create service request with request_approval_status='Pending' | SR pending |
| 2 | VehicleMgmtController@updateStatus approves SR → maintenance auto-created | Maintenance with status='Pending' created |
| 3 | Update maintenance via TptVehicleMaintenanceController@update with status='Approved' | Controller L85-108 triggers |
| 4 | Check SR: service_completion_date is set, approved_by is set, request_approval_status='Approved' | SR also approved by maintenance update |
| 5 | Verify the maintenance update also sets maintenance's own approved_by and approved_at | L104-107 fires |

---

### TC-CR01: Controller index() Uses Non-Existent Relationships

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `TptVehicleMaintenanceController@index()` line 24 | `$maintenances = TptVehicleMaintenance::with(['vehicle', 'vendor', 'assignedTo'])->paginate(10);` |
| 2 | Check TptVehicleMaintenance model relationships | Only `serviceRequest()` and `approvedBy()` exist. `vendor` and `assignedTo` are NOT defined. `vehicle` is an accessor (`getVehicleAttribute`), NOT a relationship |
| 3 | Navigate to `/vehicle-maintenance` | **BadMethodCallException**: "Relationship 'vendor' not found on TptVehicleMaintenance model" |
| 4 | **BUG confirmed**: index() is completely broken | The standalone index page crashes. Only VehicleMgmtController's maintenance query works (which uses different eager loading) |

### TC-CR02: No store() Method

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `TptVehicleMaintenanceController` methods | Methods present: index, create, show, edit, update, destroy, trashed, restore, forceDelete. NO `store()` method. |
| 2 | Run `php artisan route:list | grep vehicle-maintenance` | POST `/vehicle-maintenance` mapped to `TptVehicleMaintenanceController@store` |
| 3 | Send POST request to `/vehicle-maintenance` | Controller has no store() method → 405 Method Not Allowed |
| 4 | **BUG confirmed**: store() missing from controller | Create form at `/vehicle-maintenance/create` renders but cannot be submitted |

### TC-CR03: update() Uses Raw Request Not FormRequest

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `TptVehicleMaintenanceController@update()` signature line 67 | `public function update(Request $request, $id)` — type-hints `Illuminate\Http\Request`, NOT `TptVehicleMaintenanceRequest` |
| 2 | Compare with gold standard VendorController::update() | Vendor uses `VendorRequest $request` with validated() |
| 3 | Verify no validation occurs in update method body | All $request->field access (L71-81) is raw input, no validated() call |
| 4 | **BUG confirmed**: No request validation | All fields accepted as-is, no type/size/range checks |

### TC-CR04: update() No Activity Log

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect update() method body (L67-114) | No call to `activityLog()` anywhere |
| 2 | Compare with destroy() L125 | `activityLog($maintenance, 'Deleted', ...)` present in destroy |
| 3 | Compare with restore() L149 | `activityLog($maintenance, 'Restored', ...)` present in restore |
| 4 | **BUG confirmed**: update() missing activity log | Updates silently bypass audit |

### TC-CR05: update() No Change Tracking

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Examine update() method body (L67-114) | No `$record->getOriginal()` or `$record->getChanges()` call |
| 2 | Compare with VendorController::update() | Vendor controller captures getOriginal() before update and getChanges() after |
| 3 | **BUG confirmed**: No attribute change tracking | Cannot audit which fields changed during update |

### TC-CR06: edit() References Non-Existent approval_status

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `TptVehicleMaintenanceController@edit()` line 59 | `if ($maintenance->status === 'Completed' || $maintenance->approval_status === 'Approved')` |
| 2 | Check model fillable and DDL | Model: `status` in fillable. DDL: `status` ENUM('Approved','Pending','Rejected'). There is NO `approval_status` column or attribute |
| 3 | Check what `$maintenance->approval_status` returns | Since `approval_status` is not in $fillable, $casts, or $attributes, accessing non-existent attribute returns null (Laravel model behavior) |
| 4 | Create maintenance with `status = 'Approved'` via DB directly | Edit form loads successfully (because `approval_status` is null, not 'Approved') |
| 5 | **BUG confirmed**: The guard `$maintenance->approval_status === 'Approved'` NEVER evaluates to true | Approved maintenance records are NOT blocked from editing as intended. This should check `$maintenance->status === 'Approved'` or similar |

### TC-CR07: edit() Null Safety

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect edit() line 57 | `$maintenance = TptVehicleMaintenance::where('id',$id)->first();` — uses `first()` not `findOrFail()` |
| 2 | Navigate to `/vehicle-maintenance/99999/edit` with non-existent ID | `$maintenance` = null |
| 3 | Line 59 executes: `$maintenance->status` on null | ErrorException: "Trying to get property 'status' of non-object" |
| 4 | **BUG confirmed**: No null safety | Invalid ID causes crash instead of 404 |

### TC-CR08: forceDelete Uses onlyTrashed()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect forceDelete() line 160 | `$maintenance = TptVehicleMaintenance::onlyTrashed()->findOrFail($id)` |
| 2 | Compare with standard pattern | Standard forceDelete uses `withTrashed()` to delete any record (active or trashed) |
| 3 | Attempt to force-delete an active record (not in trash) | ModelNotFoundException — 404 |
| 4 | **BUG confirmed**: onlyTrashed restricts forceDelete to trashed records only | Cannot permanently delete active records without first soft-deleting them |

### TC-CR09: No updateStatus Method Despite Route

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect routes/web.php line 271 | `Route::post('/vehicle-maintenance/{id}/update-status', [TptVehicleMaintenanceController::class, 'updateStatus'])->name('vehicle-maintenance.updateStatus');` |
| 2 | Inspect TptVehicleMaintenanceController methods | 10 methods listed — NO `updateStatus()` |
| 3 | Send POST to `/vehicle-maintenance/1/update-status` | MethodNotAllowedException or FatalThrowableError: updateStatus() does not exist |
| 4 | **BUG confirmed**: Route targets non-existent controller method | Route always returns 500 error |

### TC-CR10: Request Exists But Not Used

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check `Modules/Transport/Http/Requests/TptVehicleMaintenanceRequest.php` exists | File exists with validation rules |
| 2 | Check `TptVehicleMaintenanceController` imports | Line 9: `use Modules\Transport\Http\Requests\TptVehicleMaintenanceRequest;` — imported but commented/unused |
| 3 | Check update() signature | Uses `Request $request` not `TptVehicleMaintenanceRequest $request` |
| 4 | **BUG confirmed**: Request class is fully defined but never injected | Validation rules defined but never executed |

### TC-CR11: Model Fillable Matches DDL

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect TptVehicleMaintenance model fillable array (L17-30) | 12 fields: vehicle_service_request_id, maintenance_initiation_date, maintenance_type, cost, in_service_date, out_service_date, workshop_details, next_due_date, remarks, status, approved_by, approved_at |
| 2 | Compare with DDL/tpt_vehicle_maintenance columns | All fillable fields match DDL columns |
| 3 | Verify `id`, `created_at`, `updated_at`, `deleted_at` are NOT in fillable | Correct — timestamps are auto-managed, id is PK |
| 4 | **PASS**: Fillable correctly matches DDL | No mismatch |

### TC-CR12: Model `vendor` and `assignedTo` Relationships Missing

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect TptVehicleMaintenance model relationships (L44-60) | Only two: `serviceRequest()`, `approvedBy()` |
| 2 | Check if `vendor` method exists | NOT FOUND |
| 3 | Check if `assignedTo` method exists | NOT FOUND |
| 4 | Check if `vendor` or `assignedTo` scope or attribute exists | NOT FOUND |
| 5 | **BUG confirmed**: Controller index() tries to eager-load non-existent relationships | The standalone index() page crashes |

### TC-CR13: getVehicleAttribute Accessor vs Relationship

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect TptVehicleMaintenance model getVehicleAttribute (L57-60) | `return $this->serviceRequest->inspection->vehicle ?? null;` |
| 2 | Note: This is an accessor, not a relationship | Cannot be used in `with()` eager loading |
| 3 | Check controller index() line 24 | `with(['vehicle', ...])` — trying to eager-load an accessor |
| 4 | **BUG confirmed**: Accessor cannot be eager-loaded | Causes N+1 query each time `$maintenance->vehicle` is accessed |
| 5 | VehicleMgmtController@vehicleMaintenanceQuery L241-245 | Uses `with(['serviceRequest.inspection.vehicle'])` — correct chain approach |

### TC-CR14: Model vehicleFilter Scope Uses vehicleInspection

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `TptVehicleMaintenance@scopeVehicleFilter()` model line 85 | `whereHas('serviceRequest.vehicleInspection', function($q) use ($vehicleId) { $q->where('vehicle_id', $vehicleId); })` |
| 2 | Check TptVehicleServiceRequest model for `vehicleInspection` relationship | Must verify if this relationship name is `vehicleInspection` or `inspection` |
| 3 | If relationship is named `inspection` (not `vehicleInspection`) | Scope will throw BadMethodCallException: "Relationship 'vehicleInspection' not found" |
| 4 | If relationship exists as `vehicleInspection` | Scope works correctly |
| 5 | Cross-check with controller eager loading: `TptVehicleServiceRequestController@index` uses `vehicleInspection` | Confirms relationship name is `vehicleInspection` → scope should work |

### TC-CR15: Activity Log — Only 3 Events

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Search for `activityLog` in TptVehicleMaintenanceController | Lines 125 (Deleted), 149 (Restored), 163 (Force Delete) |
| 2 | Check if activityLog exists in update() | NOT FOUND |
| 3 | Check if activityLog exists in create() or store() | NOT FOUND — no store() method exists |
| 4 | **GAP confirmed**: Only destroy, restore, forceDelete have activity logs | Created, Updated, Approved events have no audit trail |

### TC-CR16: Two Policy Files Exist — One Unused

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check `TransportServiceProvider@boot()` | `Gate::policy(TptVehicleMaintenance::class, TransportVehicleMaintenancePolicy::class)` — only `TransportVehicleMaintenancePolicy` is registered |
| 2 | List `Modules/Transport/app/Policies/` directory | Three policy files: `TransportVehicleMaintenancePolicy.php`, `TptVehicleMaintenancePolicy.php`, `CostMaintenanceReportPolicy.php` |
| 3 | Compare gate methods in `TptVehicleMaintenancePolicy` | 8 gates: viewAny, view, status, create, update, delete, restore, forceDelete — NO import/export/print/schedule/complete/viewHistory |
| 4 | Compare gate methods in `TransportVehicleMaintenancePolicy` | 14 gates: viewAny, view, status, create, update, delete, restore, forceDelete, import, export, print, schedule, complete, viewHistory |
| 5 | **OBSERVATION**: `TptVehicleMaintenancePolicy` is dead code | It is never resolved because `TransportServiceProvider` registers the other policy. It will never be instantiated |

### TC-CR17: `status` Permission Gate Exists but Unused in Controller

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `TptVehicleMaintenanceController` methods | Methods: index, create, show, edit, update, destroy, trashed, restore, forceDelete. NO `updateStatus()` method |
| 2 | Inspect route `POST /vehicle-maintenance/{id}/update-status` | Route registered targeting `TptVehicleMaintenanceController@updateStatus` — method does not exist → 500 |
| 3 | Inspect `TransportVehicleMaintenancePolicy@status()` | Returns `$user->can('tenant.vehicle-maintenance.status')` — but no code ever calls this gate |
| 4 | Inspect `VehicleMgmtController@updateStatus()` | This method handles **Service Request** approval (not maintenance status) — sets SR to Approved/Rejected, auto-creates maintenance entry. Different purpose entirely |
| 5 | **BUG confirmed**: `status` permission is defined in policy and route, but controller has no method to handle it | The `updateStatus` route will always return 500. The function should either be implemented or the route/policy method should be removed |

### TC-CR18: edit() Checks Non-Existent 'Completed' ENUM Value

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check DDL ENUM definition for `status` column | ENUM('Approved','Pending','Rejected') — NO 'Completed' |
| 2 | Check edit() line 59 first condition | `$maintenance->status === 'Completed'` |
| 3 | Since 'Completed' is not in ENUM, no record can have status='Completed' | This condition NEVER evaluates to true |
| 4 | **BUG confirmed**: Dead code in guard condition | The string literal 'Completed' matches no possible database value |

### TC-CR19: update() Bypasses Eloquent Events

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect update() line 71-81 | `TptVehicleMaintenance::where('id', $id)->update([...])` — Query Builder mass update |
| 2 | Compare with Eloquent approach | `$maintenance = TptVehicleMaintenance::findOrFail($id); $maintenance->update([...])` would fire Eloquent events |
| 3 | Check if model has boot() with event listeners | Model has NO boot() method with event listeners |
| 4 | **GAP confirmed**: Thought the model has no current listeners, the pattern bypasses potential future observer/listeners | Using query builder for update is non-standard Laravel practice |

### TC-CR20: destroy() Does Not Set is_active

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect destroy() line 122-123 | `$maintenance = TptVehicleMaintenance::findOrFail($id); $maintenance->delete();` |
| 2 | Compare with VendorController::destroy() pattern | Vendor controller sets `$record->is_active = false` before `$record->delete()` |
| 3 | Check if model has `is_active` column | Model DDL does NOT include `is_active` — only `deleted_at` for soft deletes |
| 4 | **OBSERVATION**: This model has no boolean active flag | Soft delete relies solely on deleted_at timestamp |

### TC-CR21: Inconsistent Pagination

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect index() line 24 | `->paginate(10)` — 10 per page |
| 2 | Inspect trashed() line 136 | `->paginate(20)` — 20 per page |
| 3 | **OBSERVATION**: Inconsistent pagination sizes | index uses 10, trash uses 20. Should be consistent for predictable UX |

### TC-CR22: Permissionslist Allows 14+ Actions but Controller Only Uses 7

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check config/permissionslist.php for 'vehicle-maintenance' | `'vehicle-maintenance' => $crud` — $crud includes create, view, viewAny, update, delete, restore, forceDelete, import, export, print, publish, status, email-schedule, remark, pdf, edit, approve (17 actions) |
| 2 | Count Gate::authorize() calls in controller | 7 calls: viewAny(index), view(show), create(create), update(edit+update), delete(destroy), restore(trashed+restore), forceDelete(forceDelete) |
| 3 | **OBSERVATION**: Only 7 out of 17 permission actions are used | Over-permissioned in config — 10 extra permission strings exist but are never checked |

### TC-CR23: update() Re-fetches Model Without findOrFail

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect update() line 83 | `$maintenanceData = TptVehicleMaintenance::where('id',$id)->first();` — uses `first()` not `findOrFail()` |
| 2 | Scenario: Record deleted by another user between L71 and L83 | `$maintenanceData` is null |
| 3 | Line 85: `$maintenanceData->vehicle_service_request_id` on null | ErrorException: "Trying to get property 'vehicle_service_request_id' of non-object" |
| 4 | **BUG confirmed**: Race condition / null safety issue | Concurrent delete causes crash in update()

---

## 5C. CODE-TRACE: VehicleMgmtController Integration (Tab Hub)

### CODE-TRACE-VM-01: vehicleMaintenanceQuery()

| Step | Code / Query | Description |
|------|-------------|-------------|
| 1 | `TptVehicleMaintenance::with(['serviceRequest.inspection.vehicle', 'serviceRequest.inspection.driver', 'approvedBy'])` | L241-245: Correct eager loading chain through existing relationships. `serviceRequest()` → BelongsTo TptVehicleServiceRequest → `inspection()` → BelongsTo TptDailyVehicleInspection → `vehicle()` and `driver()` relationships. |
| 2 | `->orderBy('maintenance_initiation_date', 'DESC')` | L245: Orders by initiation date descending. |
| 3 | **SEARCH**: `$request->filled('search_maintenance')` | L248: If search_maintenance has value, applies 6-field OR search across vehicle_no, registration_number, driver full_name, maintenance_type, remarks, workshop_details. |
| 4 | **STATUS FILTER**: `$request->filled('maintenance_status')` | L266: Exact match on status ENUM field. |
| 5 | **REQUEST STATUS FILTER**: `$request->filled('request_status')` | L271: Filters by linked service request's `request_approval_status` via whereHas. |
| 6 | **DATE RANGE**: `$request->filled('maintenance_from') && $request->filled('maintenance_to')` | L278: whereBetween on maintenance_initiation_date only (not on in_service_date like model scope). |
| 7 | **APPROVED BY**: `$request->filled('approved_by')` | L286: Exact match on approved_by FK. |
| 8 | **VEHICLE TYPE**: `$request->filled('vehicle_type')` | L293: 3-level deep whereHas: maintenance→serviceRequest→inspection→vehicle→vehicle_type. |
| 9 | **COST MIN**: `$request->filled('cost_min')` | L300: `where('cost', '>=', $cost_min)`. |
| 10 | **COST MAX**: `$request->filled('cost_max')` | L304: `where('cost', '<=', $cost_max)`. |

### CODE-TRACE-VM-02: updateStatus() — Service Request Approval + Maintenance Auto-Creation

| Step | Code / Query | Description |
|------|-------------|-------------|
| 1 | `$request->validate(['request_approval_status' => 'required|string|in:Approved,Rejected'])` | L162-164 (VehicleMgmtController): Validates the approval input. Only 'Approved' or 'Rejected' allowed. |
| 2 | `TptVehicleServiceRequest::findOrFail($id)` | L167: Fetches the service request or throws 404. |
| 3 | `$serviceRequest->update(['request_approval_status' => $status, 'approved_by' => auth()->id(), 'approved_at' => now()])` | L171-175: Updates SR status, approver, and timestamp. |
| 4 | `if ($status === 'Approved')` | L178: Only auto-creates maintenance if approved. |
| 5 | `TptVehicleMaintenance::create([...])` | L181-188: Creates maintenance with 6 hardcoded fields: vehicle_service_request_id = SR.id, maintenance_initiation_date = today, maintenance_type = 'General Service', cost = 0.00, status = 'Pending', remarks = SR.reason. |
| 6 | `return redirect()->back()->with('success', 'Request approved and maintenance entry has been created.')` | L190: Success redirect. |
| 7 | `return redirect()->back()->with('success', 'Request has been rejected.')` | L192: Rejection redirect. |

### CODE-TRACE-VM-03: VehicleMgmtController@index() — Hub Page Load

| Step | Code / Query | Description |
|------|-------------|-------------|
| 1 | `Gate::authorize('tenant.transport.viewAny')` | L29: Uses transport.viewAny permission (NOT vehicle-maintenance.viewAny). All 5 tabs require transport.viewAny. |
| 2 | `$all_vehicles = Vehicle::all()` | L32: Full list for dropdowns/filters. |
| 3 | `$vehicles = Vehicle::paginate(10)` | L37: Paginated vehicles for tab. |
| 4 | `$routes = Route::paginate(10)` | L38: Paginated routes. |
| 5 | `$driverHelpers = DriverHelper::paginate(10)` | L39: Paginated driver helpers. |
| 6 | `$shifts = Shift::paginate(10)` | L40: Paginated shifts. |
| 7 | `$fuelEntries = $this->fuelEntryQuery($request)->paginate(10)->withQueryString()` | L43: Fuel tab data. |
| 8 | `$dailyInspectionEntries = $this->dailyInspectionQuery($request)->paginate(10)->withQueryString()` | L44: Inspection tab data. |
| 9 | `$serviceRequests = $this->vehicleServiceRequestQuery($request)->paginate(10)->withQueryString()` | L45: Service request tab data. |
| 10 | `$maintenanceEntries = $this->vehicleMaintenanceQuery($request)->paginate(10)->withQueryString()` | L46: Maintenance tab data via private query (NOT standalone controller). |
| 11 | `$pendingData = $this->getDetailedPendingData()` | L47: Aggregated pending counts for dashboard badges. |
| 12 | `return view('transport::tab_module.vehiclemgmt', compact(...))` | L50-64: Renders hub view with all 14 data variables. |

## 5D. CODE-TRACE: Model Scopes & Relationships

### CODE-TRACE-MODEL-01: scopePending()

| Step | Code / Query | Description |
|------|-------------|-------------|
| 1 | `$query->where('status', 'Pending')` | Model L67: Adds WHERE clause for status='Pending'. |
| 2 | Usage: `TptVehicleMaintenance::pending()->get()` | Returns only records with status='Pending' and deleted_at IS NULL (SoftDeletes auto-applies). |

### CODE-TRACE-MODEL-02: scopeApproved()

| Step | Code / Query | Description |
|------|-------------|-------------|
| 1 | `$query->where('status', 'Approved')` | Model L72: Adds WHERE clause for status='Approved'. |
| 2 | Usage: `TptVehicleMaintenance::approved()->get()` | Returns only records with status='Approved' and deleted_at IS NULL. |

### CODE-TRACE-MODEL-03: scopeDateRange()

| Step | Code / Query | Description |
|------|-------------|-------------|
| 1 | `$query->whereBetween('maintenance_initiation_date', [$startDate, $endDate])` | Model L78: Checks initiation_date in range. |
| 2 | `->orWhereBetween('in_service_date', [$startDate, $endDate])` | Model L79: OR checks in_service_date in range. |
| 3 | Combined: `WHERE (initiation_date BETWEEN ? AND ?) OR (in_service_date BETWEEN ? AND ?)` | Dual-date range — matches if EITHER date falls within range. |

### CODE-TRACE-MODEL-04: scopeVehicleFilter()

| Step | Code / Query | Description |
|------|-------------|-------------|
| 1 | `if ($vehicleId) { return $query->whereHas('serviceRequest.vehicleInspection', ...)` | Model L84-85: Guard to skip filter if no ID provided. |
| 2 | `$q->where('vehicle_id', $vehicleId)` | Model L86: Filters by vehicle_id on the inspection table. |
| 3 | SQL: `WHERE EXISTS (SELECT 1 FROM tpt_vehicle_service_request sr INNER JOIN tpt_daily_vehicle_inspections dvi ON dvi.id = sr.vehicle_inspection_id WHERE dvi.vehicle_id = ? AND sr.id = tpt_vehicle_maintenance.vehicle_service_request_id)` | 3-table correlated subquery. |

### CODE-TRACE-MODEL-05: serviceRequest() Relationship

| Step | Code / Query | Description |
|------|-------------|-------------|
| 1 | `return $this->belongsTo(TptVehicleServiceRequest::class, 'vehicle_service_request_id')` | Model L44-47: Standard BelongsTo relationship. |
| 2 | Usage: `$maintenance->serviceRequest` | Returns TptVehicleServiceRequest model or null. |

### CODE-TRACE-MODEL-06: approvedBy() Relationship

| Step | Code / Query | Description |
|------|-------------|-------------|
| 1 | `return $this->belongsTo(User::class, 'approved_by')` | Model L49-52: BelongsTo to sys_users table via User model. |
| 2 | Usage: `$maintenance->approvedBy` | Returns User model or null (nullable FK). |

### CODE-TRACE-MODEL-07: getVehicleAttribute() Accessor

| Step | Code / Query | Description |
|------|-------------|-------------|
| 1 | `return $this->serviceRequest->inspection->vehicle ?? null` | Model L57-60: Chains through 3 relationships to get Vehicle. |
| 2 | N+1 Risk: Each call to `$maintenance->vehicle` executes: `SELECT * FROM tpt_vehicle_service_request WHERE id = ?` (if not loaded) + `SELECT * FROM tpt_daily_vehicle_inspections WHERE id = ?` (if not loaded) + `SELECT * FROM vehicles WHERE id = ?` (if not loaded) | Without eager loading, each accessor call generates 3 additional queries. |
| 3 | Cannot be eager-loaded via `->with('vehicle')` | Since this is an accessor (not a relationship), `with('vehicle')` throws BadMethodCallException. |

### CODE-TRACE-MODEL-08: Model Casts

| Step | Code / Query | Description |
|------|-------------|-------------|
| 1 | `'maintenance_initiation_date' => 'date'` | Model L33: Cast to Carbon date instance. |
| 2 | `'in_service_date' => 'date'` | Model L34: Cast to Carbon date instance. |
| 3 | `'out_service_date' => 'date'` | Model L35: Cast to Carbon date instance. |
| 4 | `'next_due_date' => 'date'` | Model L36: Cast to Carbon date instance. |
| 5 | `'approved_at' => 'datetime'` | Model L37: Cast to Carbon datetime instance. |
| 6 | `'cost' => 'decimal:2'` | Model L38: Cast to decimal with 2 precision. |
| 7 | `'created_at' => 'datetime'`, `'updated_at' => 'datetime'`, `'deleted_at' => 'datetime'` | Model L39-41: Timestamp casts. |

---

## 5E. CODE-TRACE: Blade Views Analysis

### CODE-TRACE-BLADE-01: index.blade.php (Standalone — Broken)

| Step | View Path | Expected Behavior | Actual Issue |
|------|-----------|-------------------|--------------|
| 1 | `transport::vehiclemaintenance.index` | Renders table of maintenance records | View NEVER renders because controller index() throws exception at L24 before reaching view |
| 2 | Receives `compact('maintenances')` | Variable `$maintenances` with paginated data | Controller crashes before compact() executes |
| 3 | `$maintenances->links()` | Pagination links | Unreachable |

### CODE-TRACE-BLADE-02: Tab Partial (Within Vehicle Mgmt Hub)

| Step | View Path | Expected Behavior | Analysis |
|------|-----------|-------------------|----------|
| 1 | `transport::tab_module.vehiclemgmt` | Hub view includes tab pane with `@include` for maintenance partial | Correct — uses hub architecture |
| 2 | Receives `$maintenanceEntries` (from private query) | Data with correct eager loading: serviceRequest→inspection→vehicle | Works correctly |
| 3 | Search bar with hidden `tab=maintenance` | Filters append tab name, pagination uses `maintenance_page` | Correct |

---

## 5F. Audit Trail Gap Analysis

| Gap ID | Operation | Expected activityLog Call | Actual | Severity |
|--------|-----------|--------------------------|--------|----------|
| AT-GAP-01 | Maintenance Created (via SR Approval) | `activityLog($maintenance, 'Created', ['message' => 'Vehicle maintenance record created from service request approval'])` | NO activityLog call in VehicleMgmtController@updateStatus | HIGH |
| AT-GAP-02 | Maintenance Updated | `activityLog($maintenance, 'Updated', ['message' => 'Vehicle maintenance record updated', 'changes' => [...]])` | NO activityLog call in TptVehicleMaintenanceController@update | HIGH |
| AT-GAP-03 | Maintenance Approved | `activityLog($maintenance, 'Approved', ['message' => 'Vehicle maintenance record approved, linked service request completed'])` | NO separate 'Approved' event; approval happens within update() with no log | MEDIUM |
| AT-GAP-04 | Maintenance Status Changed | `activityLog($maintenance, 'Status Updated', ['message' => 'Maintenance status changed from Pending to Approved'])` | No status change tracking anywhere | MEDIUM |

---

## 5G. Route Coverage Analysis

| Route | Method | Controller Action | Status | Notes |
|-------|--------|-------------------|--------|-------|
| `/vehicle-maintenance` | GET | index() | ❌ BROKEN | Crashes with BadMethodCallException at L24 |
| `/vehicle-maintenance` | POST | store() | ❌ MISSING | Route exists via resource, method not implemented |
| `/vehicle-maintenance/create` | GET | create() | ✅ OK | Gate check + view render |
| `/vehicle-maintenance/{id}` | GET | show() | ⚠️ GAP | Uses first() not findOrFail() — null on bad ID |
| `/vehicle-maintenance/{id}/edit` | GET | edit() | ❌ BUGS | 3 bugs in guard condition (approval_status, Completed, null safety) |
| `/vehicle-maintenance/{id}` | PUT | update() | ⚠️ GAPS | No validation, no activity log, no change tracking |
| `/vehicle-maintenance/{id}` | DELETE | destroy() | ✅ OK (no is_active, but model has none) |
| `/vehicle-maintenance/trash/view` | GET | trashed() | ✅ OK | Paginates 20, compact('data') |
| `/vehicle-maintenance/{id}/restore` | GET | restore() | ✅ OK | onlyTrashed findOrFail |
| `/vehicle-maintenance/{id}/force-delete` | DELETE | forceDelete() | ❌ BUG | Uses onlyTrashed() instead of withTrashed() |
| `/vehicle-maintenance/{id}/update-status` | POST | updateStatus() | ❌ MISSING | Route registered, method does NOT exist → 500 |

---

## 6. Security & Permission Analysis

### 6A. Gate Coverage

| Permission String | Used in Controller? | Used Where | Policy Method Exists? |
|-------------------|---------------------|------------|----------------------|
| tenant.vehicle-maintenance.viewAny | ✅ | index() L22 | ✅ TransportVehicleMaintenancePolicy@viewAny |
| tenant.vehicle-maintenance.view | ✅ | show() L45 | ✅ TransportVehicleMaintenancePolicy@view |
| tenant.vehicle-maintenance.create | ✅ | create() L35 | ✅ TransportVehicleMaintenancePolicy@create |
| tenant.vehicle-maintenance.update | ✅ | edit() L55, update() L69 | ✅ TransportVehicleMaintenancePolicy@update |
| tenant.vehicle-maintenance.delete | ✅ | destroy() L121 | ✅ TransportVehicleMaintenancePolicy@delete |
| tenant.vehicle-maintenance.restore | ✅ | trashed() L135, restore() L145 | ✅ TransportVehicleMaintenancePolicy@restore |
| tenant.vehicle-maintenance.forceDelete | ✅ | forceDelete() L159 | ✅ TransportVehicleMaintenancePolicy@forceDelete |
| tenant.vehicle-maintenance.status | ❌ | NOT USED | ✅ TransportVehicleMaintenancePolicy@status |
| tenant.vehicle-maintenance.import | ❌ | NOT USED | ✅ TransportVehicleMaintenancePolicy@import |
| tenant.vehicle-maintenance.export | ❌ | NOT USED | ✅ TransportVehicleMaintenancePolicy@export |
| tenant.vehicle-maintenance.print | ❌ | NOT USED | ✅ TransportVehicleMaintenancePolicy@print |
| tenant.vehicle-maintenance.schedule | ❌ | NOT USED | ✅ TransportVehicleMaintenancePolicy@schedule |
| tenant.vehicle-maintenance.complete | ❌ | NOT USED | ✅ TransportVehicleMaintenancePolicy@complete |
| tenant.vehicle-maintenance.viewHistory | ❌ | NOT USED | ✅ TransportVehicleMaintenancePolicy@viewHistory |

### 6B. Missing Authorization

| Endpoint | Missing Gate | Risk |
|----------|-------------|------|
| VehicleMgmtController@updateStatus (SR approval + maintenance auto-creation) | No Gate::authorize() call at all | Any authenticated user with transport.viewAny can create maintenance records via SR approval |
| VehicleMgmtController@storeStatus (SR creation) | No Gate::authorize() call | Any authenticated user can create service requests |
| Maintenance update() auto-approval | No separate `approve` permission for status='Approved' transition | update permission gates both regular edits AND approvals |

---

## 8. Complete Bug Inventory

| Bug ID | Severity | File | Line(s) | Description |
|--------|----------|------|---------|-------------|
| BUG-01 | CRITICAL | TptVehicleMaintenanceController | L24 | index() uses `with(['vehicle','vendor','assignedTo'])` — relationships don't exist → BadMethodCallException |
| BUG-02 | CRITICAL | TptVehicleMaintenanceController | (missing) | No store() method — POST /vehicle-maintenance returns 405 |
| BUG-03 | CRITICAL | TptVehicleMaintenanceController | L67 | update() uses raw `Request $request` with no validation — all input blindly accepted |
| BUG-04 | HIGH | TptVehicleMaintenanceController | L59 | edit() checks `$maintenance->approval_status === 'Approved'` — property does NOT exist (should be `status`) |
| BUG-05 | HIGH | TptVehicleMaintenanceController | L59 | edit() checks `$maintenance->status === 'Completed'` — 'Completed' is NOT in the ENUM ('Approved','Pending','Rejected') |
| BUG-06 | HIGH | TptVehicleMaintenanceController | L57 | edit() uses `first()` not `findOrFail()` — null on bad ID causes crash at L59 |
| BUG-07 | HIGH | TptVehicleMaintenanceController | L160 | forceDelete() uses `onlyTrashed()` instead of `withTrashed()` — cannot force-delete active records |
| BUG-08 | HIGH | TptVehicleMaintenanceController | (missing) | No updateStatus() method despite route registration → 500 |
| BUG-09 | HIGH | TptVehicleMaintenanceController | L125, L149, L163 | Only 3 activityLog events — missing Created (store/auto-create) and Updated |
| BUG-10 | MEDIUM | TptVehicleMaintenanceController | L83 | update() uses `first()` not `findOrFail()` for re-fetch — null on concurrent delete crashes at L85 |
| BUG-11 | MEDIUM | TptVehicleMaintenanceController | L71-81 | Mass update uses query builder, bypassing Eloquent events |
| BUG-12 | MEDIUM | TptVehicleMaintenanceController | L125 | destroy() does NOT set `is_active = false` before soft delete |
| BUG-13 | MEDIUM | TptVehicleMaintenanceController | L136 | trashed() uses paginate(20) vs index() paginate(10) — inconsistent |
| BUG-14 | MEDIUM | TptVehicleMaintenanceController | L46 | show() uses `first()` not `findOrFail()` — null on bad ID |
| BUG-15 | LOW | TransportVehicleMaintenancePolicy | L77-120 | 7 unused policy gates (import, export, print, schedule, complete, viewHistory, status) |
| BUG-16 | LOW | Permissionslist | `vehicle-maintenance` | Only 7 of 17 permission actions are actually used by controller |
| BUG-17 | LOW | VehicleMgmtController | L160-188 | No activityLog call when maintenance auto-created during SR approval |
| BUG-18 | LOW | VehicleMgmtController | L160-188 | No Gate::authorize() call in updateStatus() for maintenance creation |
| BUG-19 | LOW | Model TptVehicleMaintenance | L57-60 | `getVehicleAttribute()` accessor causes N+1 queries — should be eager-loadable relationship or cached |
| BUG-20 | LOW | Policies | Both files | Two policy files exist for same model; `TptVehicleMaintenancePolicy` is dead code (8 gates, never registered) |

---

## 9. Controller Code Quality Metrics

| Metric | Value |
|--------|-------|
| Total Controller Lines | 167 |
| Number of Methods | 10 |
| Number of Buggy Methods | 7 (index, show, edit, update, destroy (minor), forceDelete, missing: store + updateStatus) |
| Number of `Gate::authorize()` Calls | 10 (across 10 method calls, but distributed: index=1, create=1, show=1, edit=1, update=1, destroy=1, trashed=1, restore=1, forceDelete=1) |
| Number of `activityLog()` Calls | 3 |
| Number of `findOrFail()` Uses | 3 (destroy, restore, forceDelete) |
| Number of `first()` Instead of `findOrFail()` | 3 (show, edit, update) |
| Number of Private Query Methods | 0 (all in VehicleMgmtController, not here) |
| Number of BUG finds from this analysis | 20 |
| CRITICAL Bugs | 3 (BUG-01, BUG-02, BUG-03) |
| HIGH Bugs | 6 (BUG-04 through BUG-09) |
| MEDIUM Bugs | 5 (BUG-10 through BUG-14) |
| LOW Bugs/Issues | 6 (BUG-15 through BUG-20) |

---

## 10. Dependencies & Integration Points

| Dependency | Type | Direction | Impact |
|-----------|------|-----------|--------|
| TptVehicleServiceRequest | Model FK | Maintenance belongs to SR | CASCADE delete removes maintenance; SR approval creates maintenance |
| TptDailyVehicleInspection | 2-level deep chain | SR belongs to Inspection | Vehicle accessor chains: maintenance→SR→inspection→vehicle |
| Vehicle | 3-level deep chain | Inspection belongs to Vehicle | All vehicle filters and display depend on this chain |
| Dropdown (vehicle_status) | FK lookup value | update() uses Dropdown model | Must have seed data key='tpt_vehicle_service_request.vehicle_status.vehicle_status' value='Service Done' |
| User (sys_users) | FK (approved_by) | Maintenance.approved_by → User | SET NULL on delete |
| VehicleMgmtController | Tab hub | Contains main query + auto-creation | Standalone controller methods are secondary; main UX through hub |
| permissionslist.php | Config | Defines 17 permission strings | Only 7 used; config is source of truth |

---

## 11. Recommended Fixes (Priority Order)

| Priority | Fix | Affected File | Effort |
|----------|-----|---------------|--------|
| P0 | Fix index() eager loading: change `with(['vehicle','vendor','assignedTo'])` to `with(['serviceRequest.inspection.vehicle','approvedBy'])` | TptVehicleMaintenanceController L24 | 5 min |
| P0 | Add store() method to handle POST from create form | TptVehicleMaintenanceController (new method) | 30 min |
| P0 | Fix update() to use `TptVehicleMaintenanceRequest` instead of `Request` | TptVehicleMaintenanceController L67 | 15 min |
| P1 | Fix edit() guard: change `$maintenance->approval_status === 'Approved'` to `$maintenance->status === 'Approved'`, add null check | TptVehicleMaintenanceController L59 | 5 min |
| P1 | Fix forceDelete() to use `withTrashed()` instead of `onlyTrashed()` | TptVehicleMaintenanceController L160 | 2 min |
| P1 | Add updateStatus() method or remove route | TptVehicleMaintenanceController + routes | 30 min |
| P1 | Add activityLog() to update() with change tracking | TptVehicleMaintenanceController | 15 min |
| P1 | Fix show() and edit() to use `findOrFail()` | TptVehicleMaintenanceController L46, L57 | 5 min |
| P2 | Add activityLog to VehicleMgmtController@updateStatus for auto-created maintenance | VehicleMgmtController | 10 min |
| P2 | Add Gate::authorize() to VehicleMgmtController@updateStatus | VehicleMgmtController | 5 min |
| P2 | Remove dead code: `TptVehicleMaintenancePolicy` file | Policies directory | 2 min |
| P2 | Make pagination consistent (10 across all) | TptVehicleMaintenanceController L136 | 2 min |
| P3 | Remove unused policy gates or implement corresponding controller methods | Policy + Controller | varies |
| P3 | Align permissionslist.php to only used permissions | config/permissionslist.php | 15 min |

---

## 12. Detailed Request Class Analysis — TptVehicleMaintenanceRequest

| Aspect | Detail |
|--------|--------|
| File Location | `Modules/Transport/Http/Requests/TptVehicleMaintenanceRequest.php` |
| Defined Rules | 9 fields with validation rules and custom error messages |
| Controller Usage | `update()` at TptVehicleMaintenanceController L67 uses `Request $request` — NOT this class |
| Store Rules | POST-only: vehicle_service_request_id = required, exists:tpt_vehicle_service_request,id, unique (with whereNull deleted_at) |
| Update Rules | PUT/PATCH: same rules but vehicle_service_request_id becomes nullable (not needed for updates) |
| Conditional Rule | out_service_date: `after_or_equal:in_service_date` only when both are provided (nullable|date|after_or_equal:in_service_date) |
| Custom Messages | 17 custom error messages including "This service request already has a maintenance entry." for unique violation |
| Attribute Names | `attributes()` method returns 9 friendly field names for error messages |
| Authorization | `authorize()` method returns `Gate::authorize('tenant.vehicle-maintenance.create')` for store OR `'tenant.vehicle-maintenance.update'` for update |
| **GAP** | FormRequest is correctly implemented and would provide validation + authorization + error messages — but is NEVER instantiated because controller doesn't type-hint it |

## 13. Route Parameter Analysis

| Parameter | Routes Using It | Bound Model? | Notes |
|-----------|----------------|--------------|-------|
| `{id}` | show, edit, update, destroy, restore, forceDelete, updateStatus | No explicit Route Model Binding | All methods use manual `findOrFail($id)` or `where('id',$id)->first()` — no implicit binding via `TptVehicleMaintenance $maintenance` |
| `{id}` in VehicleMgmtController@updateStatus | Route is `/vehicle-mgmt/{id}/update-status` | No explicit binding | Uses `TptVehicleServiceRequest::findOrFail($id)` — different model than maintenance |
| Page Number | index (via `page`), trashed (via `page`), hub tabs (via unique page names) | N/A | Tab hub uses unique names like `vendors_page`, `items_page` but standalone maintenance index uses default `page` |

## 14. VehicleMgmtController Maintenance Tab — Complete Filter Matrix

| Filter Parameter | Type | Source Tab | Query Method | Line(s) |
|-----------------|------|-----------|-------------|---------|
| `search_maintenance` | String (LIKE %) | Maintenance | whereHas vehicle (vehicle_no, registration_number) OR whereHas driver (full_name) OR where(maintenance_type) OR where(remarks) OR where(workshop_details) | VM L248-263 |
| `maintenance_status` | ENUM exact match | Maintenance | where('status', $value) | VM L266-268 |
| `request_status` | ENUM exact match | Maintenance | whereHas serviceRequest → where('request_approval_status', $value) | VM L271-275 |
| `maintenance_from` | Date | Maintenance | whereBetween('maintenance_initiation_date', [$from, $to]) | VM L278-283 |
| `maintenance_to` | Date | Maintenance | Part of date range with `maintenance_from` | VM L278-283 |
| `approved_by` | Integer (FK) | Maintenance | where('approved_by', $value) | VM L286-288 |
| `vehicle_type` | String | Maintenance | whereHas serviceRequest→inspection→vehicle → where('vehicle_type', $value) | VM L293-297 |
| `cost_min` | Numeric | Maintenance | where('cost', '>=', $value) | VM L300-302 |
| `cost_max` | Numeric | Maintenance | where('cost', '<=', $value) | VM L304-306 |

## 15. Database Interaction Timing Analysis

| Operation | Queries Executed | Transaction Safety | N+1 Risk |
|-----------|-----------------|-------------------|----------|
| index() (standalone) | 1 (paginate) but CRASHES during with() resolution | N/A | N/A — never completes |
| show($id) | 1 (SELECT) | None | None for single record |
| edit($id) | 1 (SELECT) | None | None for single record |
| update() (status != Approved) | 2: UPDATE + SELECT | None — two separate queries | None |
| update() (status = Approved with SR) | 4-6: UPDATE + SELECT + SR SELECT + Dropdown SELECT + SR UPDATE + Maintenance UPDATE | **No DB::transaction()** — if SR update succeeds but maintenance update fails, data is inconsistent | None intentional, but Dropdown query each time |
| destroy() | 2: SELECT (findOrFail) + UPDATE (soft delete) + activityLog insert | None | None |
| restore() | 2: SELECT (onlyTrashed) + UPDATE (restore) + activityLog insert | None | None |
| forceDelete() | 2: SELECT (onlyTrashed) + DELETE + activityLog insert | None | None |
| VehicleMgmtController updateStatus() | 3: SELECT SR + UPDATE SR + INSERT maintenance | **No DB::transaction()** — if INSERT fails after UPDATE, SR is approved but maintenance not created | None |
| VehicleMgmtController vehicleMaintenanceQuery() | 2: paginate COUNT + SELECT with join chain | None | Eager loading prevents N+1 but chain depth may cause large joins |
| View getVehicleAttribute() (per record) | 3: Lazy load SR + lazy load Inspection + lazy load Vehicle | N/A | **HIGH**: Each call to `$maintenance->vehicle` in a loop causes 3N additional queries |

## 16. Database Schema vs Model vs Controller Field Usage Comparison

| Field | DDL | Model Fillable | Controller Update | Controller Uses |
|-------|-----|---------------|-------------------|-----------------|
| id | ✅ PK | ❌ Not fillable | N/A | Used in where() |
| vehicle_service_request_id | ✅ FK | ✅ Fillable | ❌ Not in update array | Used in getVehicleAttribute() and scopeVehicleFilter() |
| maintenance_initiation_date | ✅ DATE NOT NULL | ✅ Fillable | ✅ Updated | Shown in views |
| maintenance_type | ✅ VARCHAR(120) NOT NULL | ✅ Fillable | ✅ Updated | Used in search |
| cost | ✅ DECIMAL(12,2) NOT NULL | ✅ Fillable | ✅ Updated | Used in cost_min/cost_max filter |
| in_service_date | ✅ DATE NULL | ✅ Fillable | ✅ Updated | Used in scopeDateRange() |
| out_service_date | ✅ DATE NULL | ✅ Fillable | ✅ Updated | Shown in views |
| workshop_details | ✅ VARCHAR(512) NULL | ✅ Fillable | ✅ Updated | Used in search |
| next_due_date | ✅ DATE NULL | ✅ Fillable | ✅ Updated | Shown in views |
| remarks | ✅ VARCHAR(512) NULL | ✅ Fillable | ✅ Updated | Used in search + auto-creation |
| status | ✅ ENUM('Approved','Pending','Rejected') | ✅ Fillable | ✅ Updated | Used in scopes + filters + guard |
| approved_by | ✅ FK NULL | ✅ Fillable | ❌ **NOT in update array** but set via separate update L104-107 | Used in filter |
| approved_at | ✅ TIMESTAMP NULL | ✅ Fillable | ❌ **NOT in update array** but set via separate update L104-107 | Shown in views |
| created_at | ✅ TIMESTAMP | ❌ | N/A | Auto |
| updated_at | ✅ TIMESTAMP | ❌ | N/A | Auto |
| deleted_at | ✅ TIMESTAMP NULL | ❌ | N/A | SoftDeletes |

---

## 17. Complete Request-Response Lifecycle (Per Endpoint)

### Endpoint: GET /vehicle-maintenance (standalone index)

```
Browser → GET /vehicle-maintenance
  → Laravel Route Match: Route::resource → TptVehicleMaintenanceController@index()
    → Middleware: auth (redirect to /login if unauthenticated)
    → Middleware: tenant context
    → Controller@index() L22: Gate::authorize('tenant.vehicle-maintenance.viewAny')
      → Policy: TransportVehicleMaintenancePolicy@viewAny → $user->can('tenant.vehicle-maintenance.viewAny')
      → 403 if denied
    → L24: TptVehicleMaintenance::with(['vehicle', 'vendor', 'assignedTo'])->paginate(10)
      → ★ CRASH: BadMethodCallException "Relationship 'vendor' not found"
      → Stack trace: Laravel tries to resolve 'vendor' as relationship → calls vendor() method on model → method does not exist → exception bubbled to Laravel error handler
    → HTTP 500 Response (debug mode: exception details; production: generic error page)
```

### Endpoint: GET /vehicle-mgmt?tab=maintenance (hub tab — WORKS)

```
Browser → GET /vehicle-mgmt?tab=maintenance
  → VehicleMgmtController@index() L29: Gate::authorize('tenant.transport.viewAny')
  → L46: $this->vehicleMaintenanceQuery($request)->paginate(10)
    → Uses CORRECT eager loading: ['serviceRequest.inspection.vehicle', 'serviceRequest.inspection.driver', 'approvedBy']
    → All relationships exist → query succeeds
  → L50-64: return view(... compact('maintenanceEntries', ...))
  → Hub view renders → Maintenance tab pane partial included
  → Table rendered with maintenance data
  → HTTP 200 Response
```

### Endpoint: PUT /vehicle-maintenance/{id} (update — partial workflow)

```
Browser → PUT /vehicle-maintenance/{id}
  → Controller@update() L69: Gate::authorize('tenant.vehicle-maintenance.update')
  → L71-81: Mass update (9 fields via Query Builder)
  → L83: Re-fetch maintenance record
  ↓ (if $request->status == 'Approved' && vehicle_service_request_id exists)
  → L86: Find linked TptVehicleServiceRequest
  → L90-95: Dropdown lookup for 'Service Done' vehicle_status
  → L97-103: Update Service Request (approved_by, completion_date, status, approved_at, vehicle_status)
  → L104-107: Update maintenance approved_by, approved_at
  ↓ (end condition)
  → L111-113: redirect()->route('transport.vehicle-mgmt.index')->with('success', ...)
  → HTTP 302 Redirect to /vehicle-mgmt
```

### Endpoint: DELETE /vehicle-maintenance/{id} (soft delete)

```
Browser → DELETE /vehicle-maintenance/{id}
  → Controller@destroy() L121: Gate::authorize('tenant.vehicle-maintenance.delete')
  → L122: TptVehicleMaintenance::findOrFail($id) → 404 if not found
  → L123: $maintenance->delete()
    → Sets deleted_at = CURRENT_TIMESTAMP (SoftDeletes trait)
    → Does NOT set is_active (model has no is_active column)
  → L125: activityLog($maintenance, 'Deleted', ['message' => 'Vehicle maintenance record moved to trash'])
  → L127: redirect()->back()->with('success', 'Maintenance record moved to trash.')
  → HTTP 302 Redirect
```

### Endpoint: POST /vehicle-maintenance/{id}/update-status (BROKEN — always 500)

```
Browser → POST /vehicle-maintenance/{id}/update-status
  → Laravel Route Match: web.php L271 → [TptVehicleMaintenanceController::class, 'updateStatus']
  → Laravel calls Controller@updateStatus()
  → ★ FATAL ERROR: Method TptVehicleMaintenanceController::updateStatus() does not exist
  → Symfony\Component\Debug\Exception\FatalThrowableError
  → HTTP 500 Response
```

## 18. Activity Log Audit Trail Summary

| Event Type | Controller Method | Line | Data Passed | Frequency |
|-----------|-------------------|------|-------------|-----------|
| Deleted | destroy() | 125 | `['message' => 'Vehicle maintenance record moved to trash']` | Each soft delete |
| Restored | restore() | 149 | `['message' => 'Vehicle maintenance record restored']` | Each restore |
| Force Delete | forceDelete() | 163 | `['message' => 'Vehicle maintenance record permanently deleted']` | Each permanent delete |
| ✅ 3 events logged | | | | |
| ❌ Created | (missing — should be in VehicleMgmtController@updateStatus after create()) | — | — | NEVER logged |
| ❌ Updated | (missing — should be in update()) | — | — | NEVER logged |
| ❌ Approved | (missing — should be in update() when status='Approved') | — | — | NEVER logged |

## 19. Policy Registration Verification

| Policy Class | File Exists? | Registered in ServiceProvider? | Gate Methods | Status |
|-------------|-------------|-------------------------------|-------------|--------|
| TransportVehicleMaintenancePolicy | ✅ `Policies/TransportVehicleMaintenancePolicy.php` | ✅ `TransportServiceProvider L111: Gate::policy(TptVehicleMaintenance::class, TransportVehicleMaintenancePolicy::class)` | 14 (viewAny, view, status, create, update, delete, restore, forceDelete, import, export, print, schedule, complete, viewHistory) | ✅ ACTIVE — this is the policy Laravel resolves |
| TptVehicleMaintenancePolicy | ✅ `Policies/TptVehicleMaintenancePolicy.php` | ❌ NOT registered anywhere | 8 (viewAny, view, status, create, update, delete, restore, forceDelete) | ❌ DEAD CODE — never instantiated, never called, never used |

**Confirmation**: `TransportServiceProvider.php` L111 explicitly registers `TransportVehicleMaintenancePolicy`. The other policy file at `TptVehicleMaintenancePolicy.php` exists on disk but is never registered — it is unreachable dead code and can be safely deleted.

## 20. Testing Environment Dependencies

| Dependency | Required For | Setup Notes |
|-----------|-------------|-------------|
| Authenticated user with tenant context | All test cases | Must initialize tenant session |
| `tenant.vehicle-maintenance.*` permissions | Permission tests | Assign via role or direct DB |
| Seeded TptVehicleServiceRequest | TC-D01, TC-P05, TC-P13 | Must have at least one SR with known ID |
| Dropdown key 'tpt_vehicle_service_request.vehicle_status.vehicle_status' with value 'Service Done' | TC-P05, TC-D03 | Check `dropdowns` table for existence before testing |
| Soft-deleted maintenance record | TC-P08, TC-P09, TC-P15 | Pre-create and soft-delete for trash/restore tests |
| Maintenance with status='Approved' | TC-N01, TC-N02 | Update status to Approved for edit-blocking tests |
| Non-existent ID (e.g., 999999) | TC-N03, TC-N04, TC-N05 | Use an ID that does not exist in DB |
| User with partial permissions | TC-N08, TC-N14, TC-N15 | Create user without specific permissions |
| Guest/unauthenticated session | TC-N09 | Use browser incognito or clear session |
