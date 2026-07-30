# tpt_ServiceLog_TcList

## Module: Transport → Vehicle Management → Service Request

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | Transport |
| Tab Group | Vehicle Management (5-tab container via `VehicleMgmtController`) |
| Feature | Service Request |
| URL(s) | `/vehicle-service-request` (index), `/vehicle-service-request/create` (create), `/vehicle-service-request` (store), `/vehicle-service-request/{id}` (show), `/vehicle-service-request/{id}/edit` (edit), `/vehicle-service-request/{id}` (update PUT), `/vehicle-service-request/{id}` (destroy DELETE), `/vehicle-service-request/trash/view` (trash), `/vehicle-service-request/{id}/restore` (restore GET), `/vehicle-service-request/{id}/force-delete` (forceDelete DELETE), `/vehicle-service-request/{id}/update-status` (updateStatus POST), `/vehicle-service-request/{vehicle}/toggle-status` (toggleStatus POST — **NO CONTROLLER METHOD EXISTS**) |
| Controller | `Modules\Transport\Http\Controllers\TptVehicleServiceRequestController` |
| Tab Container Controller | `Modules\Transport\Http\Controllers\VehicleMgmtController@index()` |
| Model | `Modules\Transport\Models\TptVehicleServiceRequest` — table: `tpt_vehicle_service_request` |
| Validation | Inline in `store()` (no FormRequest), inline in `update()` (no FormRequest) |
| Permissions | `tenant.vehicle-service-request.viewAny`, `tenant.vehicle-service-request.view`, `tenant.vehicle-service-request.create`, `tenant.vehicle-service-request.update`, `tenant.vehicle-service-request.delete`, `tenant.vehicle-service-request.restore`, `tenant.vehicle-service-request.forceDelete`, `tenant.vehicle-service-approval.approve` |
| Soft Deletes | Yes (`SoftDeletes` trait) |
| Activity Log | Events: `Created`, `Updated`, `Deleted`, `Restored`, `Force Deleted`, `Approved`, `Rejected` |
| Approval Workflow | Approved → auto-creates `TptVehicleMaintenance` via `firstOrCreate` |

---

## 2. Pre-conditions

- Required permissions: All `tenant.vehicle-service-request.*` permissions + `tenant.vehicle-service-approval.approve`
- Tenant context initialized
- Required seed data: At least one `TptDailyVehicleInspection` record for FK reference
- Inspection must exist for `vehicle_inspection_id` (FK: `fk_vsl_vehicleInspection`, ON DELETE CASCADE)
- Dusk environment variables configured

---

## 3. Default Data Load

When the page loads via `VehicleMgmtController@index()` (GET `/vehicle-mgmt`):

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| Service Requests Grid | `VehicleMgmtController@vehicleServiceRequestQuery()` | `TptVehicleServiceRequest::with(['inspection.vehicle','inspection.driver','inspection.inspector','approvedBy'])` | approval_status, search (reason, vehicle_no, driver.name) | 10/page via latest() |

The standalone `/vehicle-service-request` GET page loads via `TptVehicleServiceRequestController@index()` with eager loading `['vehicleInspection','approvedBy','vehicleMaintenance']` and pagination of 20/page.

---

## 4. Test Data Strategy

- **vehicle_inspection_id**: FK to `tpt_daily_vehicle_inspection`. Must exist. FK CASCADE on delete.
- **request_date**: TIMESTAMP, required
- **reason**: VARCHAR(512), required in store (though DDL says DEFAULT NULL). Max 512 chars.
- **vehicle_status**: INT UNSIGNED — FK to sys_dropdown (values: 'Due for Service', 'In-Service', 'Service Done')
- **service_completion_date**: TIMESTAMP, nullable. In update: validated `after_or_equal:request_date`
- **request_approval_status**: ENUM('Approved','Pending','Rejected'), default 'Pending'
- **approved_by**: FK to `sys_users`, SET NULL on delete
- **Pre-test cleanup**: Delete by vehicle_inspection_id
- **Auto-creation from inspection**: When inspection fails, service request auto-created with status='Pending'
- **Approval flow**: Approved status → `TptVehicleMaintenance` entry auto-created via `firstOrCreate`
- **Note**: `toggleStatus` route (line 49) is registered but no corresponding controller method exists — accessing it returns 405 or 500

---

## 5. Business Conditions

### 5.1 Database Schema — `tpt_vehicle_service_request`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | id | INT UNSIGNED | PK, auto-increment |
| BC-DB-02 | vehicle_inspection_id | INT UNSIGNED | NOT NULL, FK → `tpt_daily_vehicle_inspection.id`, ON DELETE CASCADE |
| BC-DB-03 | request_date | TIMESTAMP | NOT NULL |
| BC-DB-04 | reason | VARCHAR(512) | DEFAULT NULL |
| BC-DB-05 | Vehicle_status | INT UNSIGNED | DEFAULT NULL (FK to sys_dropdown) — **note capital V in DDL** |
| BC-DB-06 | service_completion_date | TIMESTAMP | NULL DEFAULT NULL |
| BC-DB-07 | request_approval_status | ENUM('Approved','Pending','Rejected') | NOT NULL, DEFAULT 'Pending' |
| BC-DB-08 | approved_by | INT UNSIGNED | DEFAULT NULL, FK → `sys_users.id`, ON DELETE SET NULL |
| BC-DB-09 | approved_at | TIMESTAMP | NULL DEFAULT NULL |
| BC-DB-10 | created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |
| BC-DB-11 | updated_at | TIMESTAMP | ON UPDATE CURRENT_TIMESTAMP |
| BC-DB-12 | deleted_at | TIMESTAMP | NULLABLE (soft delete) |

Note: DDL column name is `Vehicle_status` (capital V) but model fillable uses `vehicle_status` (lowercase v). Laravel's `$fillable` is case-sensitive — this is a potential mismatch.

### 5.2 Validation Rules — Inline (No FormRequest)

**store() rules** (inside try-catch, no explicit validation):

| BC ID | Field | Rule | Notes |
|-------|-------|------|-------|
| BC-VAL-01 | vehicle_inspection_id | none validated | Direct assignment `$request->vehicle_inspection_id` — no exists check |
| BC-VAL-02 | request_date | none validated | Direct assignment |
| BC-VAL-03 | reason | none validated | Direct assignment |
| BC-VAL-04 | request_approval_status | none validated | Defaults to 'Pending' |
| BC-VAL-05 | vehicle_status | none validated | Direct assignment |

**update() rules** (validated inline):

| BC ID | Field | Rule | Error Message |
|-------|-------|------|---------------|
| BC-VAL-06 | vehicle_inspection_id | nullable, `exists:tpt_daily_vehicle_inspection,id` | Default |
| BC-VAL-07 | request_date | required, date | Default |
| BC-VAL-08 | vehicle_status | required | Default |
| BC-VAL-09 | service_completion_date | nullable, date, `after_or_equal:request_date` | Default |
| BC-VAL-10 | reason | required, string, max:512 | Default |

**updateStatus() rules**:

| BC ID | Field | Rule | Error Message |
|-------|-------|------|---------------|
| BC-VAL-11 | request_approval_status | required, `in:Approved,Rejected` | Default |

### 5.3 Authorization (Permission Gates)

| BC ID | Permission | Controller Method | Behavior |
|-------|-----------|-------------------|----------|
| BC-AUTH-01 | tenant.vehicle-service-request.viewAny | index() | Without → 403 |
| BC-AUTH-02 | tenant.vehicle-service-request.view | show() | Without → 403 |
| BC-AUTH-03 | tenant.vehicle-service-request.create | store(), create() | Without → 403 |
| BC-AUTH-04 | tenant.vehicle-service-request.update | update(), edit() | Without → 403 |
| BC-AUTH-05 | tenant.vehicle-service-request.delete | destroy() | Without → 403 |
| BC-AUTH-06 | tenant.vehicle-service-request.restore | restore(), trashed() | Without → 403 |
| BC-AUTH-07 | tenant.vehicle-service-request.forceDelete | forceDelete() | Without → 403 |
| BC-AUTH-08 | tenant.vehicle-service-approval.approve | updateStatus() | Without → 403 |

### 5.4 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Create via `TptVehicleServiceRequest::create([...])` | Service request created; redirect to `transport.vehicle-mgmt.index` with success message |
| BC-BIZ-02 | store() — try-catch | On success: activity log + redirect; On exception: redirect with error message |
| BC-BIZ-03 | store() — auto-approve logic | If `request_approval_status === 'Approved'` then `approved_by = Auth::user()->id`, `approved_at = now()` |
| BC-BIZ-04 | Activity log on create | `activityLog($serviceRequest, 'Created', ['message' => 'Vehicle service request created successfully'])` |
| BC-BIZ-05 | update() validates inline | Uses `$request->validate([...])` NOT FormRequest |
| BC-BIZ-06 | update() does NOT update approval status | Only updates basic fields (vehicle_inspection_id, request_date, vehicle_status, service_completion_date, reason) |
| BC-BIZ-07 | update() — no change tracking | Unlike FuelLog and Inspection controllers, NO getOriginal()/getChanges() comparison |
| BC-BIZ-08 | Activity log on update | `activityLog($serviceRequest, 'Updated', ['message' => 'Vehicle service request updated'])` — no details about what changed |
| BC-BIZ-09 | Soft delete via `destroy()` | `$serviceRequest->delete()`; redirect with success |
| BC-BIZ-10 | Restore via `restore($id)` | `onlyTrashed()->findOrFail($id)` → `$serviceRequest->restore()` |
| BC-BIZ-11 | Force delete via `forceDelete($id)` | Uses `onlyTrashed()` → **cannot force-delete non-trashed records** (should use `withTrashed()`) |
| BC-BIZ-12 | updateStatus — Approval flow | `updateStatus()` validates `request_approval_status` in `['Approved','Rejected']` |
| BC-BIZ-13 | Approval creates maintenance | If Approved: `TptVehicleMaintenance::firstOrCreate(['vehicle_service_request_id' => $id], [...])` — prevents duplicate maintenance entries |
| BC-BIZ-14 | Approval response | JSON `{success: true, status: 'Approved', message: 'Request approved and maintenance entry created.', maintenance_id: $id}` |
| BC-BIZ-15 | Rejection response | JSON `{success: true, status: 'Rejected', message: 'Request has been rejected.'}` |
| BC-BIZ-16 | updateStatus exception handling | try-catch wraps logic; on exception returns JSON `{success: false, message: 'Something went wrong...'}` with HTTP 500 |
| BC-BIZ-17 | toggleStatus route — NO METHOD | Route at line 49: `Route::post('/vehicle-service-request/{vehicle}/toggle-status', ...)` but controller has NO `toggleStatus()` method → 500 error |

### 5.5 Model Relationships

| BC ID | Relationship | Type | Foreign Key | Notes |
|-------|-------------|------|-------------|-------|
| BC-REL-01 | inspection() | BelongsTo TptDailyVehicleInspection | vehicle_inspection_id | Alias — same as vehicleInspection |
| BC-REL-02 | vehicleInspection() | BelongsTo TptDailyVehicleInspection | vehicle_inspection_id | Duplicate relationship (same as inspection) |
| BC-REL-03 | approvedBy() | BelongsTo User (SchoolSetup) | approved_by | Approving user |
| BC-REL-04 | vehicleStatus() | BelongsTo Dropdown | vehicle_status | FK to sys_dropdown for vehicle status |
| BC-REL-05 | vehicleMaintenance() | HasOne TptVehicleMaintenance | vehicle_service_request_id | Created on approval |

### 5.6 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|------------------|----------------|
| BC-REF-01 | vehicle_inspection_id | tpt_daily_vehicle_inspection (id) | CASCADE |
| BC-REF-02 | approved_by | sys_users (id) | SET NULL |

### 5.7 BC-BIZ-DEEP: Deep Business Condition Traces

| BC ID | Condition | Expected Behavior | Source |
|-------|-----------|-------------------|--------|
| BC-BIZ-DEEP-01 | store() accepts all fields blindly — no validation | `$request->field` assigned directly; NO `$request->validate()` call | `Controller:56-69` |
| BC-BIZ-DEEP-02 | store() try-catch without DB transaction | On exception: redirect with error but NO rollback (no DB::beginTransaction) | `Controller:55,79-84` |
| BC-BIZ-DEEP-03 | store() auto-sets approved_by/approved_at only when status=Approved | `approved_by = Auth::user()->id`, `approved_at = now()` | `Controller:63-68` |
| BC-BIZ-DEEP-04 | store() logs 'Created' activity | `activityLog($sr, 'Created', ['message'=>'Vehicle service request created successfully'])` | `Controller:71-73` |
| BC-BIZ-DEEP-05 | store() does NOT validate vehicle_inspection_id FK | Any value accepted — silent data integrity risk | `Controller:57` |
| BC-BIZ-DEEP-06 | update() uses inline `$request->validate()` NOT FormRequest | 5 rules: vehicle_inspection_id nullable+exists, request_date required+date, vehicle_status required, reason required+string+max:512, service_completion_date nullable+date+after_or_equal | `Controller:131-137` |
| BC-BIZ-DEEP-07 | update() preserves request_approval_status | Only updates 5 basic fields; does NOT modify approval status | `Controller:143-149` |
| BC-BIZ-DEEP-08 | update() has NO change tracking | No getOriginal()/getChanges() — unlike FuelLog/Inspection controllers | `Controller:126-160` |
| BC-BIZ-DEEP-09 | update() logs 'Updated' without change details | `activityLog($sr, 'Updated', ['message'=>'Vehicle service request updated'])` — no diff | `Controller:152-154` |
| BC-BIZ-DEEP-10 | destroy() uses findOrFail + delete() | 404 on invalid ID; soft-delete via SoftDeletes trait | `Controller:238-239` |
| BC-BIZ-DEEP-11 | destroy() logs 'Deleted' NOT 'Trashed' | Event is 'Deleted' — inconsistent with other controllers using 'Trashed' | `Controller:241-243` |
| BC-BIZ-DEEP-12 | restore() uses onlyTrashed() scope (correct) | Only finds soft-deleted; 404 for active records | `Controller:274-275` |
| BC-BIZ-DEEP-13 | restore() logs 'Restored' event | `activityLog($sr, 'Restored', ['message'=>'Vehicle service request restored'])` | `Controller:279-281` |
| BC-BIZ-DEEP-14 | forceDelete() uses onlyTrashed() — WRONG | Cannot force-delete active records; should use withTrashed() like FuelLog | `Controller:295-296` |
| BC-BIZ-DEEP-15 | forceDelete() logs 'Force Deleted' | `activityLog($sr, 'Force Deleted', ['message'=>'Vehicle service request permanently deleted'])` | `Controller:300-302` |
| BC-BIZ-DEEP-16 | updateStatus() validates status inline | `required|in:Approved,Rejected` — Pending NOT allowed | `Controller:169-171` |
| BC-BIZ-DEEP-17 | updateStatus() uses firstOrCreate for maintenance | Prevents duplicate maintenance on re-approval | `Controller:187-196` |
| BC-BIZ-DEEP-18 | updateStatus() Approved creates maintenance with 5 defaults | status=Pending, cost=0, type='General Service', date=now(), remarks=reason | `Controller:190-194` |
| BC-BIZ-DEEP-19 | updateStatus() Approved returns JSON with maintenance_id | `{success:true, status:'Approved', message:'...', maintenance_id:<id>}` | `Controller:202-207` |
| BC-BIZ-DEEP-20 | updateStatus() Rejected returns JSON without maintenance_id | `{success:true, status:'Rejected', message:'Request has been rejected.'}` | `Controller:215-219` |
| BC-BIZ-DEEP-21 | updateStatus() exception returns JSON 500 with debug | `{success:false, message:'...', error: debug ? msg : null}` | `Controller:223-227` |
| BC-BIZ-DEEP-22 | updateStatus() uses ONE Gate for both approve + reject | `tenant.vehicle-service-approval.approve` covers both actions | `Controller:167` |
| BC-BIZ-DEEP-23 | trashed() onlyTrashed → latest(deleted_at) → paginate(20) | Only soft-deleted records, 20 per page | `Controller:257-259` |
| BC-BIZ-DEEP-24 | index() eager-loads vehicleInspection, approvedBy, vehicleMaintenance | 3 relationships; prevents N+1 | `Controller:22-26` |
| BC-BIZ-DEEP-25 | index() latest() → paginate(20) | Ordered by created_at DESC, 20/page | `Controller:27-28` |
| BC-BIZ-DEEP-26 | show() same eager loading + findOrFail | 404 on invalid ID | `Controller:94-99` |
| BC-BIZ-DEEP-27 | edit() findOrFail + all inspections for dropdown | Loads single record + inspection list | `Controller:114-115` |
| BC-BIZ-DEEP-28 | Model $fillable has 8 fields | Excludes id, created_at, updated_at, deleted_at | `Model:27-36` |
| BC-BIZ-DEEP-29 | Model default: request_approval_status = 'Pending' | Matches DDL DEFAULT; new records default to Pending | `Model:41-43` |
| BC-BIZ-DEEP-30 | Model has DUPLICATE relationships inspection() + vehicleInspection() | Both map same FK → TptDailyVehicleInspection — redundant | `Model:61-67,88-94` |
| BC-BIZ-DEEP-31 | Model casts 3 fields as datetime | request_date, service_completion_date, approved_at → Carbon | `Model:48-52` |
| BC-BIZ-DEEP-32 | vehicleMaintenance() is HasOne | Created on approval via firstOrCreate | `Model:99-105` |
| BC-BIZ-DEEP-33 | Policy has 6 unused methods | status, import, export, print, submit, cancel — never called | `Policy:30-113` |
| BC-BIZ-DEEP-34 | Route toggleStatus registered with NO controller method | POST route to toggleStatus — accessing returns 500 error | `web.php:49` |
| BC-BIZ-DEEP-35 | VehMgmtCtrl query loads nested: inspection→vehicle/driver/inspector | Different eager loading from standalone controller | `VehMgmtCtrl:127-132` |
| BC-BIZ-DEEP-36 | VehMgmtCtrl filters by approval_status exact match | `where('request_approval_status', $request->approval_status)` | `VehMgmtCtrl:135-137` |
| BC-BIZ-DEEP-37 | VehMgmtCtrl search: reason + vehicle_no + driver name | 3-way OR subquery | `VehMgmtCtrl:140-150` |
| BC-BIZ-DEEP-38 | Tab paginate(10) vs standalone paginate(20) | Different page sizes for same data | `VehMgmtCtrl:45` vs `Ctrl:28` |
| BC-BIZ-DEEP-39 | VehMgmtCtrl updateStatus() uses ::create() NOT firstOrCreate() | **BUG**: Re-approving creates DUPLICATE maintenance entries | `VehMgmtCtrl:181-188` |
| BC-BIZ-DEEP-40 | VehMgmtCtrl updateStatus() returns redirect NOT JSON | Inconsistent response format between two controllers | `VehMgmtCtrl:190-192` |
| BC-BIZ-DEEP-41 | VehMgmtCtrl storeStatus() validates WRONG table name | `exists:tpt_daily_vehicle_inspections` (PLURAL) — table is singular | `VehMgmtCtrl:207` |
| BC-BIZ-DEEP-42 | VehMgmtCtrl storeStatus() uses new+save (not ::create) | Different instantiation pattern from dedicated controller | `VehMgmtCtrl:211-230` |
| BC-BIZ-DEEP-43 | VehMgmtCtrl storeStatus() NO activityLog | Created requests via this method have NO audit trail | `VehMgmtCtrl:198-236` |
| BC-BIZ-DEEP-44 | Approval blade uses SweetAlert2 + AJAX for approve/reject | confirm dialog → `$.ajax` POST to updateStatus | `approval.blade.php:261-341` |
| BC-BIZ-DEEP-45 | Approval modal populates from @json($service) | Modal displays vehicle, driver, dates, status, reason | `approval.blade.php:170-214,221-248` |
| BC-BIZ-DEEP-46 | Index blade vehicle status shows sys_dropdown value or 'Grounded' | `$service->vehicleStatus->value ?? 'Grounded'` | `index.blade.php:61` |
| BC-BIZ-DEEP-47 | Create blade auto-fills reason from inspection issues | jQuery reads data-issues, fills textarea | `create.blade.php:215-217` |
| BC-BIZ-DEEP-48 | Create blade only shows inspections WITH vehicle | `@if($inspection->vehicle)` filters orphan inspections | `create.blade.php:56` |
| BC-BIZ-DEEP-49 | FK CASCADE: delete inspection → auto-deletes service requests | Referential integrity via DDL FK | `DDL` |
| BC-BIZ-DEEP-50 | FK SET NULL: delete approver → approved_by = NULL | Preserves service request record | `DDL` |
| BC-BIZ-DEEP-51 | Activity events: Created/Updated/Deleted/Restored/Force Deleted/Approved/Rejected | 7 distinct event types across all methods | `Ctrl:71,152,241,279,300,198,211` |
| BC-BIZ-DEEP-52 | Model scopes: pending(), approved(), rejected() | Query scopes by request_approval_status for dashboard | `Model:111-124` |
| BC-BIZ-DEEP-53 | Inconsistent create: ::create() vs new+save() | Two different instantiation patterns across controllers | `Ctrl:56` vs `VehMgmtCtrl:211-230` |
| BC-BIZ-DEEP-54 | Show blade uses optional() chaining for nullable relationships | `optional(optional($record->inspection)->vehicle)->vehicle_no ?? '-'` | `show.blade.php:135` |
| BC-BIZ-DEEP-55 | Trash blade uses action-trashed component | Same UI pattern as other Transport trash views | `trash.blade.php:70` |

### 5.8 CODE-TRACE: Controller Method Execution Traces

| Method | Lines | Operations | Key Observations |
|--------|-------|------------|-----------------|
| `index()` | 18-31 | `Gate::authorize(viewAny)` → `with([vehicleInspection,approvedBy,vehicleMaintenance])` → `latest()` → `paginate(20)` → view | Eager-loads 3 relationships; 20 per page; standalone index |
| `create()` | 36-46 | `Gate::authorize(create)` → `TptDailyVehicleInspection::latest()->get()` → view | All inspections loaded; no active/status filter |
| `store()` | 51-85 | `Gate::authorize(create)` → `try{::create([8 fields])}` → `activityLog(Created)` → redirect `OR` catch→redirect(error) | **NO validation**; **NO DB transaction**; auto-approved_by logic when status=Approved |
| `show()` | 90-105 | `Gate::authorize(view)` → `with([...])` → `findOrFail($id)` → view | Same 3 eager loads; proper 404 on missing ID |
| `edit()` | 110-121 | `Gate::authorize(update)` → `findOrFail($id)` + `inspections all` → view | Single record + full inspection list |
| `update()` | 126-160 | `Gate::authorize(update)` → `$request->validate([5 rules])` → `findOrFail($id)` → `update([5 fields])` → `activityLog(Updated)` → redirect | Validates THEN finds; NO approval status update; NO change tracking |
| `updateStatus()` | 165-229 | `Gate::authorize(approve)` → `validate(in:Approved,Rejected)` → `findOrFail()` → `update([status,by,at])` → Approved: `firstOrCreate` maintenance + log + JSON; Rejected: log + JSON; catch→JSON 500 | JSON responses; firstOrCreate prevents duplicate; single Gate for both |
| `destroy()` | 234-248 | `Gate::authorize(delete)` → `findOrFail($id)` → `delete()` → `activityLog(Deleted)` → redirect | Soft delete only; no is_active toggle |
| `trashed()` | 253-265 | `Gate::authorize(restore)` → `onlyTrashed()` → `latest(deleted_at)` → `paginate(20)` → view | Uses restore permission for trash view access |
| `restore()` | 270-286 | `Gate::authorize(restore)` → `onlyTrashed()->findOrFail($id)` → `restore()` → `activityLog(Restored)` → redirect | onlyTrashed is correct for restore |
| `forceDelete()` | 291-307 | `Gate::authorize(forceDelete)` → `onlyTrashed()->findOrFail($id)` → `forceDelete()` → `activityLog(Force Deleted)` → redirect | **BUG**: onlyTrashed prevents force-deleting active records |

### 5.9 VIEW-TRACE: Blade Template Analysis

| View | File | Key Elements | Data Source |
|------|------|-------------|-------------|
| Index (tab) | `index.blade.php` | Search bar + approval_status filter dropdown + table(Req.Date,Vehicle,Reason,Vehicle.Status,Approval.Status,Completion,Action) + pagination links | `$serviceRequests` — tab-pane fragment inside VehicleMgmt |
| Create | `create.blade.php` | Inspection select with jQuery preview + Request Date + Vehicle Status (sys_dropdown) + Completion Date + Reason(512 max) + auto-fill | `$inspections` — standalone full layout |
| Edit | `edit.blade.php` | Same as create with pre-filled values + PUT method + inspection preview auto-show | `$serviceRequest`, `$inspections` |
| Show | `show.blade.php` | Detail table: ID, Request Date, Vehicle Status(badge), Completion Date, Approval Status(badge), Approved At, timestamps + Linked Inspection card | `$record` with inspection.vehicle/driver |
| Approval Tab | `approval.blade.php` | Filter bar + table with Approve/Reject AJAX buttons + View modal + SweetAlert2 toast | `$serviceRequests` — tab-pane inside VehicleMgmt |
| Trash | `trash.blade.php` | Same columns as index + action-trashed component for restore/forceDelete + pagination(20) | `$data` from `onlyTrashed()` |

---

## 6. Test Case List

### 6.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | Service Request Tab Loads Inside Vehicle Mgmt | `/vehicle-mgmt` loads Service Request tab with filter bar | — | — | ⬜ |
| TC-P02 | Standalone Service Request Index | GET `/vehicle-service-request` with pagination (20/page) | — | — | ⬜ |
| TC-P03 | Create Service Request — Manual Entry | POST with vehicle_inspection_id, request_date, reason, vehicle_status → created | — | — | ⬜ |
| TC-P04 | Create Service Request — With Auto-Approval | POST with request_approval_status=Approved → approved_by and approved_at set automatically | — | — | ⬜ |
| TC-P05 | View Service Request Details | Show page displays Inspection info, Reason, Status, Approval details | — | — | ⬜ |
| TC-P06 | Edit Service Request | Edit form loads with pre-filled data | — | — | ⬜ |
| TC-P07 | Update Service Request — Basic Fields | Update reason, request_date, vehicle_status → record updated; activity logged | — | — | ⬜ |
| TC-P08 | Update Service Request — With service_completion_date | Date validated `after_or_equal:request_date` | — | — | ⬜ |
| TC-P09 | Approve Service Request via AJAX | POST `/vehicle-service-request/{id}/update-status` with `request_approval_status=Approved` → maintenance auto-created | — | — | ⬜ |
| TC-P10 | Reject Service Request via AJAX | POST with `request_approval_status=Rejected` → status updated, no maintenance created | — | — | ⬜ |
| TC-P11 | Soft Delete Service Request | DELETE → deleted_at set | — | — | ⬜ |
| TC-P12 | Restore Service Request | Restore → deleted_at=NULL | — | — | ⬜ |
| TC-P13 | Force Delete Service Request (Trashed) | forceDelete on trashed record → permanent removal | — | — | ⬜ |
| TC-P14 | Filter By Approval Status | approval_status filter → matching entries | — | — | ⬜ |
| TC-P15 | Search By Reason | Search term in reason → matching entries | — | — | ⬜ |
| TC-P16 | Full Lifecycle | Create → View → Edit → Approve → Delete → Trash → Restore → Force Delete | — | — | ⬜ |

### 6.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | Required — Missing request_date (update) | "The request date field is required." | — | — | ⬜ |
| TC-N02 | Required — Missing reason (update) | "The reason field is required." | — | — | ⬜ |
| TC-N03 | Required — Missing vehicle_status (update) | "The vehicle status field is required." | — | — | ⬜ |
| TC-N04 | reason Exceeds 512 Characters (update) | "The reason must not be greater than 512 characters." | — | — | ⬜ |
| TC-N05 | Invalid vehicle_inspection_id (update) | "The selected vehicle inspection id is invalid." | — | — | ⬜ |
| TC-N06 | service_completion_date Before request_date | "The service completion date must be a date after or equal to request date." | — | — | ⬜ |
| TC-N07 | Invalid request_approval_status (updateStatus) | "The selected request approval status is invalid." (must be Approved or Rejected) | — | — | ⬜ |
| TC-N08 | store() — Non-Existent vehicle_inspection_id | No validation on store — invalid ID may be stored (silent data integrity issue) | — | — | ⬜ |
| TC-N09 | Force Delete Non-Trashed Record | forceDelete uses `onlyTrashed()` → `findOrFail` returns 404 (cannot force-delete active records) | — | — | ⬜ |
| TC-N10 | View With Invalid ID | show() uses `findOrFail($id)` → 404 | — | — | ⬜ |
| TC-N11 | Edit With Invalid ID | `findOrFail($id)` → 404 | — | — | ⬜ |
| TC-N12 | Update With Invalid ID | `findOrFail($id)` in update → 404 | — | — | ⬜ |
| TC-N13 | Delete With Invalid ID | `findOrFail($id)` → 404 | — | — | ⬜ |
| TC-N14 | Permission 403 — All Endpoints (Blanket) | 403 on all endpoints when no permissions assigned | — | — | ⬜ |
| TC-N14a | Permission Denied — viewAny | GET `/vehicle-service-request` without `tenant.vehicle-service-request.viewAny` → 403 | — | — | ⬜ |
| TC-N14b | Permission Denied — view | GET `/vehicle-service-request/{id}` without `tenant.vehicle-service-request.view` → 403 | — | — | ⬜ |
| TC-N14c | Permission Denied — create | GET `/vehicle-service-request/create` or POST store without `tenant.vehicle-service-request.create` → 403 | — | — | ⬜ |
| TC-N14d | Permission Denied — update | GET `/vehicle-service-request/{id}/edit` or PUT update without `tenant.vehicle-service-request.update` → 403 | — | — | ⬜ |
| TC-N14e | Permission Denied — delete | DELETE `/vehicle-service-request/{id}` without `tenant.vehicle-service-request.delete` → 403 | — | — | ⬜ |
| TC-N14f | Permission Denied — restore | GET restore or GET trashed without `tenant.vehicle-service-request.restore` → 403 | — | — | ⬜ |
| TC-N14g | Permission Denied — forceDelete | DELETE forceDelete without `tenant.vehicle-service-request.forceDelete` → 403 | — | — | ⬜ |
| TC-N14h | Permission Denied — approve/reject | POST updateStatus without `tenant.vehicle-service-approval.approve` → 403 | — | — | ⬜ |
| TC-N15 | Guest Access Redirect | Redirect to `/login` | — | — | ⬜ |
| TC-N16 | toggleStatus Route — No Controller Method | POST `/vehicle-service-request/{vehicle}/toggle-status` → 500 error (method not found) | — | — | ⬜ |
| TC-N17 | Delete Already Trashed Record | DELETE `/vehicle-service-request/{id}` on already soft-deleted record → `findOrFail` returns 404 (onlyTrashed not used in destroy) | — | — | ⬜ |
| TC-N18 | Restore Non-Trashed Record | GET restore on active (non-trashed) record → `onlyTrashed()->findOrFail($id)` returns 404 | — | — | ⬜ |
| TC-N19 | Force Delete Already Force-Deleted Record | forceDelete on already permanently deleted record → `onlyTrashed()->findOrFail($id)` returns 404 | — | — | ⬜ |

### 6.2a Activity Log Verification Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-AL01 | Activity Log — Create | After POST store, `activity_log` table contains entry with `event='Created'`, `message='Vehicle service request created successfully'` | — | — | ⬜ |
| TC-AL02 | Activity Log — Update | After PUT update, `activity_log` table contains entry with `event='Updated'`, `message='Vehicle service request updated'` | — | — | ⬜ |
| TC-AL03 | Activity Log — Delete (Soft) | After DELETE destroy, `activity_log` table contains entry with `event='Deleted'`, `message='Vehicle service request deleted'` | — | — | ⬜ |
| TC-AL04 | Activity Log — Restore | After GET restore, `activity_log` table contains entry with `event='Restored'`, `message='Vehicle service request restored'` | — | — | ⬜ |
| TC-AL05 | Activity Log — Force Delete | After DELETE forceDelete, `activity_log` table contains entry with `event='Force Deleted'`, `message='Vehicle service request permanently deleted'` | — | — | ⬜ |
| TC-AL06 | Activity Log — Approve | After POST updateStatus with `request_approval_status=Approved`, `activity_log` table contains entry with `event='Approved'`, `message='Service request approved & maintenance initiated'` | — | — | ⬜ |
| TC-AL07 | Activity Log — Reject | After POST updateStatus with `request_approval_status=Rejected`, `activity_log` table contains entry with `event='Rejected'`, `message='Service request rejected'` | — | — | ⬜ |

### 6.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|----------------|---------|---------|--------|
| TC-D01 | A | Approval Creates Maintenance Entry | `TptVehicleMaintenance` created with `vehicle_service_request_id` = this request's ID; status='Pending'; cost=0; type='General Service' | — | — | ⬜ |
| TC-D02 | A | Double Approval Does Not Duplicate Maintenance | `firstOrCreate()` ensures only one maintenance per service request | — | — | ⬜ |
| TC-D03 | B | Inspection Deletion Cascades (CASCADE) | Deleting inspection auto-deletes all service requests for that inspection | — | — | ⬜ |
| TC-D04 | C | Service Request Deletion Cascades To Maintenance (CASCADE) | Deleting a service request cascades to its maintenance records (FK in tpt_vehicle_maintenance) | — | — | ⬜ |
| TC-D05 | D | Auto-Creation From Failed Inspection | When inspection is marked Failed, service request auto-created with Pending status | — | — | ⬜ |

### 6.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|-----------------|---------|---------|--------|
| TC-CR01 | CR | P1 | Controller — store() No Validation Rules | store() uses `Request $request` (not FormRequest) and has NO `$request->validate()` call — all fields accepted blindly | — | — | ◌ |
| TC-CR02 | CR | P1 | Controller — update() Manually Validates | Uses `$request->validate([...])` inline rather than a FormRequest class | — | — | ◌ |
| TC-CR03 | CR | P1 | Controller — No Change Tracking on Update | Unlike FuelLog and Inspection controllers, update() does NOT compare getOriginal() vs getChanges() | — | — | ◌ |
| TC-CR04 | CR | P1 | Controller — forceDelete Uses `onlyTrashed()` | Line 295: `TptVehicleServiceRequest::onlyTrashed()->findOrFail($id)` — cannot force-delete non-trashed records; should use `withTrashed()` | — | — | ◌ |
| TC-CR05 | CR | P1 | Controller — toggleStatus Route But No Method | Route line 49 registers `toggleStatus` but controller has no such method. Adding a method or removing the route is needed | — | — | ◌ |
| TC-CR06 | CR | P1 | Model — Fillable Matches DDL | 8 fillable fields: vehicle_inspection_id, request_date, reason, vehicle_status, service_completion_date, request_approval_status, approved_by, approved_at | — | — | ◌ |
| TC-CR07 | CR | P1 | Model — DDL Field Name Mismatch `Vehicle_status` | DDL column `Vehicle_status` (capital V) vs model fillable `vehicle_status` (lowercase). Laravel uses case-insensitive column names in MySQL — works but inconsistent | — | — | ◌ |
| TC-CR08 | CR | P1 | Model — Duplicate Relationships `inspection()` and `vehicleInspection()` | Both map to same FK `vehicle_inspection_id` on `TptDailyVehicleInspection` — redundant code | — | — | ◌ |
| TC-CR09 | CR | P1 | Model — Default Attributes | `request_approval_status => 'Pending'` — matches DDL default | — | — | ◌ |
| TC-CR10 | CR | P1 | Model — No `SoftDeletes` in Activity Log Message | Activity log for delete uses 'Deleted', not 'Trashed' (inconsistent with other controllers) | — | — | ◌ |
| TC-CR11 | CR | P1 | Controller — updateStatus Uses `firstOrCreate` Correctly | Prevents duplicate maintenance on multiple approvals | — | — | ◌ |
| TC-CR12 | CR | P1 | VehicleMgmtController — storeStatus Duplicates Logic | `VehicleMgmtController::storeStatus()` has duplicate create logic that bypasses `TptVehicleServiceRequestController::store()` — potential inconsistency | — | — | ◌ |
| TC-CR13 | CR | P1 | Activity Log Events — Naming Inconsistency | Create: 'Created', Update: 'Updated', Delete: 'Deleted' (not 'Trashed'), Restore: 'Restored', Force: 'Force Deleted', Approval: 'Approved'/'Rejected' | — | — | ◌ |
| TC-CR14 | CR | P1 | Routes — resource Generates store() But No FormRequest | `Route::resource` includes store route but controller does not validate input; no FormRequest class used | — | — | ◌ |
| TC-CR15 | CR | P2 | Policy — Unused Methods `status()`, `import()`, `export()`, `print()`, `submit()`, `cancel()` | `TransportVehicleServiceRequestPolicy` defines these 6 methods with permissions `tenant.vehicle-service-request.{status,import,export,print,submit,cancel}` but NO controller method calls `Gate::authorize()` for any of them — dead code | — | — | ◌ |
| TC-CR16 | CR | P2 | Controller — destroy() Does Not Set `is_active=false` | Unlike Vendor controller pattern, destroy() only calls `->delete()` without setting `is_active=false`. Soft delete sets `deleted_at` but leaves `is_active` unchanged (Model has no `is_active` column per DDL — soft delete relies solely on `deleted_at`) | — | — | ◌ |
| TC-CR17 | CR | P2 | No FormRequest Classes | Both store() and update() use inline validation (`Request $request` + `$request->validate()` in update, nothing in store). No dedicated FormRequest classes exist for this resource | — | — | ◌ |

---

## 7. Detailed Test Steps

### TC-P09: Approve Service Request via AJAX (With Maintenance Creation)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a service request with status=Pending | Entry exists in DB |
| 2 | POST `/vehicle-service-request/{id}/update-status` with `request_approval_status=Approved` | AJAX call |
| 3 | Verify JSON response | `{success: true, status: 'Approved', message: 'Request approved and maintenance entry created.', maintenance_id: <id>}` |
| 4 | DB check: `tpt_vehicle_maintenance` | New record exists with `vehicle_service_request_id = $serviceRequest->id`, `status = 'Pending'`, `cost = 0`, `maintenance_type = 'General Service'` |
| 5 | DB check: `tpt_vehicle_service_request.approved_by` | Set to current user ID |
| 6 | DB check: `tpt_vehicle_service_request.approved_at` | Set to current timestamp |
| 7 | Second approval call with same ID | `firstOrCreate` prevents duplicate — returns existing maintenance |
| 8 | Activity log check | "Approved" event with message "Service request approved & maintenance initiated" |

### TC-AL01: Activity Log — Create

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Authenticate as user with `tenant.vehicle-service-request.create` permission | User logged in |
| 2 | POST `/vehicle-service-request` with valid `vehicle_inspection_id`, `request_date`, `reason`, `vehicle_status` | 302 redirect to `transport.vehicle-mgmt.index` |
| 3 | Query `activity_log` table for the newly created service request | Row exists with `event='Created'` and `message='Vehicle service request created successfully'` |

### TC-AL02: Activity Log — Update

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Authenticate as user with `tenant.vehicle-service-request.update` permission | User logged in |
| 2 | Have an existing service request record | Record exists in DB |
| 3 | PUT `/vehicle-service-request/{id}` with updated `reason` | 302 redirect to `transport.vehicle-mgmt.index` |
| 4 | Query `activity_log` table for the updated record | Row exists with `event='Updated'` and `message='Vehicle service request updated'` |
| 5 | Verify no change-tracking details in log | No `changes` array in activity log data (unlike FuelLog/Inspection controllers) |

### TC-AL03: Activity Log — Delete (Soft)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Authenticate as user with `tenant.vehicle-service-request.delete` permission | User logged in |
| 2 | Have an existing active service request | Record exists, `deleted_at IS NULL` |
| 3 | DELETE `/vehicle-service-request/{id}` | 302 redirect to `transport.vehicle-mgmt.index` |
| 4 | Query `activity_log` table | Row exists with `event='Deleted'` (NOT 'Trashed') and `message='Vehicle service request deleted'` |

### TC-AL04: Activity Log — Restore

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Authenticate as user with `tenant.vehicle-service-request.restore` permission | User logged in |
| 2 | Have an existing soft-deleted service request | Record exists, `deleted_at IS NOT NULL` |
| 3 | GET `/vehicle-service-request/{id}/restore` | 302 redirect to `transport.vehicle-mgmt.index` |
| 4 | Query `activity_log` table | Row exists with `event='Restored'` and `message='Vehicle service request restored'` |

### TC-AL05: Activity Log — Force Delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Authenticate as user with `tenant.vehicle-service-request.forceDelete` permission | User logged in |
| 2 | Have an existing soft-deleted service request | Record exists in `onlyTrashed` scope |
| 3 | DELETE `/vehicle-service-request/{id}/force-delete` | 302 redirect to `transport.vehicle-mgmt.index` |
| 4 | Query `activity_log` table | Row exists with `event='Force Deleted'` and `message='Vehicle service request permanently deleted'` |

### TC-AL06: Activity Log — Approve

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Authenticate as user with `tenant.vehicle-service-approval.approve` permission | User logged in |
| 2 | Have an existing Pending service request | Record exists with `request_approval_status='Pending'` |
| 3 | POST `/vehicle-service-request/{id}/update-status` with `request_approval_status=Approved` | JSON `{success: true, status: 'Approved', ...}` |
| 4 | Query `activity_log` table | Row exists with `event='Approved'` and `message='Service request approved & maintenance initiated'` |

### TC-AL07: Activity Log — Reject

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Authenticate as user with `tenant.vehicle-service-approval.approve` permission | User logged in |
| 2 | Have an existing Pending service request | Record exists with `request_approval_status='Pending'` |
| 3 | POST `/vehicle-service-request/{id}/update-status` with `request_approval_status=Rejected` | JSON `{success: true, status: 'Rejected', ...}` |
| 4 | Query `activity_log` table | Row exists with `event='Rejected'` and `message='Service request rejected'` |

### TC-N16: toggleStatus Route — No Controller Method

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect web.php line 49 | `Route::post('/vehicle-service-request/{vehicle}/toggle-status', [TptVehicleServiceRequestController::class, 'toggleStatus'])` exists |
| 2 | Inspect TptVehicleServiceRequestController | No `toggleStatus()` method defined anywhere in the file (308 lines checked) |
| 3 | Send POST `/vehicle-service-request/1/toggle-status` | 500 error: "Method ...\TptVehicleServiceRequestController::toggleStatus does not exist" |
| 4 | **BUG confirmed**: Route registered but no controller method | Should either implement toggleStatus or remove the route |

### TC-CR04: Controller forceDelete Uses `onlyTrashed()`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `TptVehicleServiceRequestController@forceDelete()` line 295 | `$serviceRequest = TptVehicleServiceRequest::onlyTrashed()->findOrFail($id);` |
| 2 | Try force deleting an ACTIVE (non-trashed) record | `onlyTrashed()` limits scope to soft-deleted records only → `findOrFail()` returns 404 |
| 3 | Compare with FuelLogController forceDelete | FuelLog uses `withTrashed()` → can force-delete both trashed and active records |
| 4 | **ANOMALY confirmed**: ServiceRequest forceDelete cannot delete active records | Only trashed records can be force-deleted. Active records must be soft-deleted first |

### TC-P01: Service Request Tab Loads Inside Vehicle Mgmt

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.vehicle-service-request.viewAny` permission | Authenticated |
| 2 | Navigate to `/vehicle-mgmt` | VehicleMgmt loads with 5 tabs |
| 3 | Click "Service Log" tab (id: `service_log-tab`) | Tab pane `#service_log-pane` becomes active |
| 4 | **Verify**: Search bar with text input (name=search) present | `placeholder="Search by reason or vehicle..."` |
| 5 | **Verify**: Filter dropdown for approval_status present | Options: All Status, Pending, Approved, Rejected |
| 6 | **Verify**: Table headers: Req. Date, Vehicle, Reason, Vehicle Status, Approval Status, Completion Date, Action | Columns match blade template |
| 7 | **Verify**: Pagination links at bottom | `$serviceRequests->links()` rendered |

### TC-P02: Standalone Service Request Index

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.vehicle-service-request.viewAny` | Authenticated |
| 2 | Navigate to `/vehicle-service-request` | Standalone index page loads |
| 3 | **Verify**: `Gate::authorize('tenant.vehicle-service-request.viewAny')` passes | No 403 |
| 4 | **Verify**: `$data = TptVehicleServiceRequest::with(['vehicleInspection','approvedBy','vehicleMaintenance'])->latest()->paginate(20)` | 20 records per page, eager-loaded |
| 5 | **Verify**: Data renders in view `transport::vehicle-service-request.index` | Table populated |

### TC-P03: Create Service Request — Manual Entry

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.vehicle-service-request.create` | Authenticated |
| 2 | Navigate to `/vehicle-service-request/create` | Create form loads with inspection dropdown |
| 3 | Select an inspection from `select#vehicle_inspection_id` | Inspection preview card fades in showing vehicle, driver, date, issues |
| 4 | Enter `request_date` = today's date | Date field filled |
| 5 | Select `vehicle_status` from dropdown (sys_dropdown values) | Status selected |
| 6 | Optionally enter `service_completion_date` | Completion date set |
| 7 | Enter `reason` = "Engine noise detected during inspection" | Reason textarea filled |
| 8 | Click "Create Service Request" | POST to `transport.vehicle-service-request.store` |
| 9 | **Verify**: `Gate::authorize('create')` passes | Authorized |
| 10 | **Verify**: `TptVehicleServiceRequest::create([...])` called with all fields | Record created |
| 11 | **Verify**: `request_approval_status` defaults to `'Pending'` (no explicit value sent) | Default applied |
| 12 | **Verify**: `approved_by` = null (status is not 'Approved') | Null |
| 13 | **Verify**: `activityLog($sr, 'Created', [...])` called | Activity logged |
| 14 | **Verify**: 302 redirect to `transport.vehicle-mgmt.index` | Redirect successful |
| 15 | **Verify**: Flash "Service Request created successfully!" | Success message displayed |

### TC-P04: Create With Auto-Approval

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to create form | Form loads |
| 2 | Fill all required fields | Valid data |
| 3 | Set hidden field `request_approval_status` = `'Approved'` (simulated via devtools or direct POST) | Status set to Approved |
| 4 | Submit form | POST to store |
| 5 | **Verify**: `Controller:63-68`: `$request->request_approval_status === 'Approved'` | true |
| 6 | **Verify**: `approved_by = Auth::user()->id` | Set to current user |
| 7 | **Verify**: `approved_at = now()` | Current timestamp |
| 8 | **Verify**: Record created with Approved status | DB has Approved + approved_by + approved_at |

### TC-P05: View Service Request Details

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Have existing service request with ID=X | DB record exists |
| 2 | Navigate to `/vehicle-service-request/{id}` where id=X | Show page loads |
| 3 | **Verify**: `Gate::authorize('tenant.vehicle-service-request.view')` passes | Authorized |
| 4 | **Verify**: `TptVehicleServiceRequest::with([...])->findOrFail($id)` | Record loaded with relationships |
| 5 | **Verify**: Table shows: Request ID, Request Date, Vehicle Status badge, Completion Date, Approval Status badge, Approved At, Reason, timestamps | All fields rendered |
| 6 | **Verify**: Linked Inspection card shows: Vehicle Number, Driver Name, Inspection Date, Issues | Inspection data displayed |
| 7 | **Verify**: Inline Badge colors: Approved=green, Rejected=red, Pending=黄色 | Correct badge classes |

### TC-P06: Edit Service Request

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Have existing service request | DB record exists |
| 2 | Navigate to `/vehicle-service-request/{id}/edit` | Edit form loads |
| 3 | **Verify**: `Gate::authorize('update')` passes | Authorized |
| 4 | **Verify**: `TptVehicleServiceRequest::findOrFail($id)` returns record | Record found |
| 5 | **Verify**: `TptDailyVehicleInspection::latest()->get()` loads all inspections | Dropdown populated |
| 6 | **Verify**: Form pre-filled: request_date, vehicle_status, service_completion_date, reason | Existing values shown |
| 7 | **Verify**: Inspection dropdown shows currently selected inspection | Pre-selected |

### TC-P07: Update Service Request — Basic Fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Have existing service request with known values | Record exists |
| 2 | Navigate to edit form, change `reason` to "Updated: transmission issue" | New reason text |
| 3 | Change `request_date` to a different date | New date |
| 4 | Click "Update Service Request" | PUT to `/vehicle-service-request/{id}` |
| 5 | **Verify**: `$request->validate([5 rules])` passes | Validation ok |
| 6 | **Verify**: `$serviceRequest->update([5 fields])` called | Record updated |
| 7 | **Verify**: `request_approval_status` unchanged | Remains same (Pending/Approved/Rejected) |
| 8 | **Verify**: `activityLog($sr, 'Updated', [...])` called | Activity logged without change details |
| 9 | **Verify**: 302 redirect with `success = 'Service Request updated successfully!'` | Success |

### TC-P08: Update With service_completion_date

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Edit a service request | Edit form loaded |
| 2 | Set `request_date` = 2026-07-15 | Date set |
| 3 | Set `service_completion_date` = 2026-07-20 (after request_date) | Valid: after_or_equal passes |
| 4 | Submit update | PUT request |
| 5 | **Verify**: Validation rule `after_or_equal:request_date` passes | Date validated |
| 6 | DB check: `service_completion_date` = 2026-07-20 | Stored correctly |

### TC-P10: Reject Service Request via AJAX

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Have Pending service request | DB exists, status=Pending |
| 2 | POST `/vehicle-service-request/{id}/update-status` with `request_approval_status=Rejected` | AJAX call |
| 3 | **Verify**: `Gate::authorize('tenant.vehicle-service-approval.approve')` passes | Authorized |
| 4 | **Verify**: `updateStatus()` → status updated to 'Rejected' | `$serviceRequest->update([status=>'Rejected', by=>user, at=>now])` |
| 5 | **Verify**: JSON response `{success: true, status: 'Rejected', message: 'Request has been rejected.'}` | Rejection confirmation |
| 6 | **Verify**: `activityLog($sr, 'Rejected', ['message'=>'Service request rejected'])` | Activity logged |
| 7 | **Verify**: NO `TptVehicleMaintenance` created | Maintenance table unchanged |
| 8 | **Verify**: Approval tab Approve/Reject buttons disabled | UI updated |

### TC-P11: Soft Delete Service Request

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Have active service request with id=X | `deleted_at IS NULL` |
| 2 | DELETE `/vehicle-service-request/{id}` | Destroy endpoint |
| 3 | **Verify**: `Gate::authorize('delete')` passes | Authorized |
| 4 | **Verify**: `$serviceRequest->delete()` called | Soft delete |
| 5 | DB check: `SELECT deleted_at FROM tpt_vehicle_service_request WHERE id=X` | `deleted_at` IS NOT NULL (timestamp set) |
| 6 | **Verify**: `activityLog($sr, 'Deleted', ['message'=>'Vehicle service request deleted'])` | Activity logged |
| 7 | **Verify**: 302 redirect with success | "Service Request deleted successfully!" |

### TC-P12: Restore Service Request

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Have soft-deleted service request (deleted_at IS NOT NULL) | Trashed record |
| 2 | GET `/vehicle-service-request/{id}/restore` | Restore endpoint |
| 3 | **Verify**: `Gate::authorize('restore')` passes | Authorized |
| 4 | **Verify**: `TptVehicleServiceRequest::onlyTrashed()->findOrFail($id)` finds record | Found in trash only |
| 5 | **Verify**: `$serviceRequest->restore()` → deleted_at=NULL | Restored |
| 6 | DB check: `SELECT deleted_at FROM tpt_vehicle_service_request WHERE id=X` | `NULL` (restored) |
| 7 | **Verify**: `activityLog($sr, 'Restored', [...])` | Activity logged |
| 8 | **Verify**: 302 redirect to `transport.vehicle-mgmt.index` with success | Restored message |

### TC-P13: Force Delete Service Request (Trashed)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Have soft-deleted service request | `deleted_at IS NOT NULL` |
| 2 | DELETE `/vehicle-service-request/{id}/force-delete` | Force delete endpoint |
| 3 | **Verify**: `Gate::authorize('forceDelete')` passes | Authorized |
| 4 | **Verify**: `onlyTrashed()->findOrFail($id)` finds trashed record | Found |
| 5 | **Verify**: `$serviceRequest->forceDelete()` → permanently removed | Hard delete |
| 6 | DB check: `SELECT * FROM tpt_vehicle_service_request WHERE id=X` | **No rows** (permanently deleted) |
| 7 | **Verify**: `activityLog($sr, 'Force Deleted', [...])` | Activity logged |
| 8 | **Verify**: 302 redirect with success | "Service Request permanently deleted!" |

### TC-P14: Filter By Approval Status

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to Service Log tab in Vehicle Mgmt | Tab loaded |
| 2 | Select `approval_status` = "Pending" from dropdown | Filter selected |
| 3 | Click Search | GET with `?approval_status=Pending` |
| 4 | **Verify**: `VehMgmtCtrl:135-137`: `$query->where('request_approval_status', 'Pending')` | Filter applied |
| 5 | **Verify**: Only pending entries shown | No Approved/Rejected records |
| 6 | Select `approval_status` = "Approved" | Re-filter |
| 7 | **Verify**: Only approved entries shown | Correct filter |
| 8 | Select `approval_status` = "Rejected" | Re-filter |
| 9 | **Verify**: Only rejected entries shown | Correct filter |

### TC-P15: Search By Reason

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to Service Log tab | Tab loaded |
| 2 | Enter "engine" in search box | `search=engine` |
| 3 | Click Search | GET with search param |
| 4 | **Verify**: `VehMgmtCtrl:140-150`: `where('reason', 'LIKE', '%engine%')` OR `vehicle_no LIKE '%engine%'` OR `driver.name LIKE '%engine%'` | 3-way OR search |
| 5 | **Verify**: Only records with "engine" in reason/vehicle/driver shown | Filtered results |

### TC-P16: Full Lifecycle

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create service request via POST store | Created successfully |
| 2 | View created request via GET show | Details visible |
| 3 | Edit and update reason via PUT | Updated successfully |
| 4 | Approve via POST update-status | Approved, maintenance created |
| 5 | Soft delete via DELETE | deleted_at set |
| 6 | View trash via GET trashed | Record visible in trash |
| 7 | Restore via GET restore | deleted_at=NULL |
| 8 | Force delete via DELETE force-delete | Permanently removed |
| 9 | **Verify**: Each step's activity logged | All 6 activity events exist |

### TC-N01: Required — Missing request_date (update)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Edit existing service request | Edit form |
| 2 | Clear `request_date` field | Empty |
| 3 | Submit update | PUT request |
| 4 | **Verify**: Validation rule `required` fails | "The request date field is required." |
| 5 | **Verify**: Record NOT updated | DB unchanged |

### TC-N02: Required — Missing reason (update)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Edit existing service request | Edit form |
| 2 | Clear `reason` textarea | Empty |
| 3 | Submit update | PUT request |
| 4 | **Verify**: Validation rule `required` fails | "The reason field is required." |
| 5 | **Verify**: Record NOT updated | DB unchanged |

### TC-N03: Required — Missing vehicle_status (update)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Edit existing service request | Edit form |
| 2 | Set `vehicle_status` to empty | No value |
| 3 | Submit update | PUT request |
| 4 | **Verify**: Validation rule `required` fails | "The vehicle status field is required." |

### TC-N04: reason Exceeds 512 Characters (update)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Edit service request | Edit form |
| 2 | Enter reason of 513+ characters | Exceeds max:512 |
| 3 | Submit update | PUT |
| 4 | **Verify**: Validation rule `max:512` fails | "The reason must not be greater than 512 characters." |

### TC-N05: Invalid vehicle_inspection_id (update)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Edit service request | Edit form |
| 2 | Set `vehicle_inspection_id` = 99999 (non-existent) | Invalid FK |
| 3 | Submit update | PUT |
| 4 | **Verify**: Validation rule `exists:tpt_daily_vehicle_inspection,id` fails | "The selected vehicle inspection id is invalid." |

### TC-N06: service_completion_date Before request_date

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Edit service request | Edit form |
| 2 | Set `request_date` = 2026-07-20 | Later date |
| 3 | Set `service_completion_date` = 2026-07-15 (before) | Earlier date |
| 4 | Submit update | PUT |
| 5 | **Verify**: Validation `after_or_equal:request_date` fails | "The service completion date must be a date after or equal to request date." |

### TC-N07: Invalid request_approval_status (updateStatus)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Have Pending service request | id=X |
| 2 | POST `/vehicle-service-request/{id}/update-status` with `request_approval_status=Invalid` | Invalid value |
| 3 | **Verify**: Validation rule `in:Approved,Rejected` fails | "The selected request approval status is invalid." |
| 4 | **Verify**: Status unchanged (still Pending) | DB unchanged |

### TC-N08: store() — Non-Existent vehicle_inspection_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to create form | Create form |
| 2 | Set `vehicle_inspection_id` = 99999 (non-existent) | Invalid FK |
| 3 | Fill all other fields with valid data | Valid rest |
| 4 | Submit | POST to store |
| 5 | **Verify**: store() has NO `exists:` validation on this field | No validation error |
| 6 | **Verify**: Record IS created with invalid FK value | **Data integrity issue** — FK violation at DB level |

### TC-N09: Force Delete Non-Trashed Record

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Have ACTIVE service request (deleted_at IS NULL) | Active record |
| 2 | DELETE `/vehicle-service-request/{id}/force-delete` | Force delete endpoint |
| 3 | **Verify**: `Gate::authorize('forceDelete')` passes | Authorized |
| 4 | **Verify**: `onlyTrashed()->findOrFail($id)` — `onlyTrashed()` adds `WHERE deleted_at IS NOT NULL` | Active record NOT found |
| 5 | `findOrFail()` throws `ModelNotFoundException` | **404 error** |
| 6 | **ANOMALY**: Cannot force-delete active records without soft-deleting first | Workaround: soft-delete → force-delete |

### TC-N10: View With Invalid ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | GET `/vehicle-service-request/99999` | Non-existent ID |
| 2 | **Verify**: `findOrFail($id)` → ModelNotFoundException | 404 error page |

### TC-N11: Edit With Invalid ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | GET `/vehicle-service-request/99999/edit` | Non-existent ID |
| 2 | **Verify**: `findOrFail($id)` → ModelNotFoundException | 404 error page |

### TC-N12: Update With Invalid ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | PUT `/vehicle-service-request/99999` with valid data | Non-existent ID |
| 2 | **Verify**: `findOrFail($id)` → ModelNotFoundException | 404 error page |

### TC-N13: Delete With Invalid ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | DELETE `/vehicle-service-request/99999` | Non-existent ID |
| 2 | **Verify**: `findOrFail($id)` → ModelNotFoundException | 404 error page |

### TC-N14: Permission 403 — All Endpoints (Blanket)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user with NO `tenant.vehicle-service-request.*` permissions | User has only basic auth |
| 2 | Access any endpoint: index, show, create, edit, update, delete, restore, forceDelete, updateStatus | All return 403 |

### TC-N14a: Permission Denied — viewAny

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login without `tenant.vehicle-service-request.viewAny` | Missing permission |
| 2 | GET `/vehicle-service-request` | `Gate::authorize()` → **403** |

### TC-N14b: Permission Denied — view

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login without `tenant.vehicle-service-request.view` | Missing permission |
| 2 | GET `/vehicle-service-request/{id}` | `Gate::authorize()` → **403** |

### TC-N14c: Permission Denied — create

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login without `tenant.vehicle-service-request.create` | Missing permission |
| 2 | GET `/vehicle-service-request/create` | `Gate::authorize()` → **403** |
| 3 | POST `/vehicle-service-request` with valid data | `Gate::authorize()` → **403** |

### TC-N14d: Permission Denied — update

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login without `tenant.vehicle-service-request.update` | Missing permission |
| 2 | GET `/vehicle-service-request/{id}/edit` | `Gate::authorize()` → **403** |
| 3 | PUT `/vehicle-service-request/{id}` with valid data | `Gate::authorize()` → **403** |

### TC-N14e: Permission Denied — delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login without `tenant.vehicle-service-request.delete` | Missing permission |
| 2 | DELETE `/vehicle-service-request/{id}` | `Gate::authorize()` → **403** |

### TC-N14f: Permission Denied — restore

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login without `tenant.vehicle-service-request.restore` | Missing permission |
| 2 | GET `/vehicle-service-request/trash/view` | `Gate::authorize()` → **403** |
| 3 | GET `/vehicle-service-request/{id}/restore` | `Gate::authorize()` → **403** |

### TC-N14g: Permission Denied — forceDelete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login without `tenant.vehicle-service-request.forceDelete` | Missing permission |
| 2 | DELETE `/vehicle-service-request/{id}/force-delete` | `Gate::authorize()` → **403** |

### TC-N14h: Permission Denied — approve/reject

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login without `tenant.vehicle-service-approval.approve` | Missing permission |
| 2 | POST `/vehicle-service-request/{id}/update-status` | `Gate::authorize()` → **403** |

### TC-N15: Guest Access Redirect

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Logout (no authenticated user) | Guest session |
| 2 | Access any protected endpoint | Redirect to `/login` |

### TC-N17: Delete Already Trashed Record

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete service request (id=X, deleted_at IS NOT NULL) | Already trashed |
| 2 | DELETE `/vehicle-service-request/{id}` again | Destroy on trashed record |
| 3 | **Verify**: `destroy()` uses `findOrFail($id)` (NOT `withTrashed()`) | `findOrFail` doesn't find trashed by default |
| 4 | Actually, `findOrFail` DOES find trashed records — SoftDeletes global scope is disabled by default in Laravel | Wait — by default, SoftDeletes applies a global scope that EXCLUDES trashed records |
| 5 | **Verify**: `findOrFail($id)` excludes soft-deleted → 404 | **404 — Record not found** |

### TC-N18: Restore Non-Trashed Record

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Have ACTIVE (non-trashed) service request | `deleted_at IS NULL` |
| 2 | GET `/vehicle-service-request/{id}/restore` | Restore endpoint |
| 3 | **Verify**: `onlyTrashed()->findOrFail($id)` → `onlyTrashed()` adds `WHERE deleted_at IS NOT NULL` | Active record NOT found |
| 4 | `findOrFail()` → ModelNotFoundException | **404 error** |

### TC-N19: Force Delete Already Force-Deleted Record

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Have permanently deleted (force-deleted) record — no DB row | Record gone |
| 2 | DELETE `/vehicle-service-request/{id}/force-delete` | Force delete on non-existent |
| 3 | **Verify**: `onlyTrashed()->findOrFail($id)` → no record found | **404 error** |

### TC-D01: Approval Creates Maintenance Entry

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Have Pending service request with id=X | DB record |
| 2 | Approve via POST updateStatus with `request_approval_status=Approved` | Approval triggered |
| 3 | **Verify**: `Controller:187-196`: `TptVehicleMaintenance::firstOrCreate(...)` | Maintenance entry created |
| 4 | DB check: `tpt_vehicle_maintenance.vehicle_service_request_id` = X | FK linked |
| 5 | DB check: `maintenance_type` = 'General Service' | Default type |
| 6 | DB check: `status` = 'Pending' | Default status |
| 7 | DB check: `cost` = 0 | Default cost |
| 8 | DB check: `maintenance_initiation_date` = today | Date set |

### TC-D02: Double Approval Does Not Duplicate Maintenance

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Approve service request id=X → maintenance created (id=M1) | First approval |
| 2 | Approve SAME service request id=X again | Second approval call |
| 3 | **Verify**: `firstOrCreate(['vehicle_service_request_id' => X], [...])` | Existing maintenance returned |
| 4 | DB check: `SELECT COUNT(*) FROM tpt_vehicle_maintenance WHERE vehicle_service_request_id = X` | **COUNT = 1** (no duplicate) |

### TC-D03: Inspection Deletion Cascades (CASCADE)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Count service requests for inspection_id=Y | e.g., 3 records |
| 2 | Delete inspection Y from `tpt_daily_vehicle_inspection` | `DELETE FROM tpt_daily_vehicle_inspection WHERE id=Y` |
| 3 | **Verify**: FK `fk_vsl_vehicleInspection` has `ON DELETE CASCADE` | Cascade enabled |
| 4 | Re-count service requests for inspection_id=Y | **COUNT = 0** (all cascade-deleted) |
| 5 | **Note**: This is DB-level integrity — cannot be tested via UI | DB test |

### TC-D04: Service Request Deletion Cascades To Maintenance

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Have service request X with linked maintenance M | Both records exist |
| 2 | Check maintenance FK: `vehicle_service_request_id = X` | FK exists |
| 3 | Check DDL for `tpt_vehicle_maintenance.vehicle_service_request_id` | FK has `ON DELETE CASCADE` |
| 4 | Delete service request X | Soft or hard delete |
| 5 | **Verify**: Maintenance M auto-deleted (if CASCADE) or SET NULL | Check maintenance table |

### TC-D05: Auto-Creation From Failed Inspection

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create/update inspection with Failed status via `TptDailyVehicleInspectionController` | Inspection marked failed |
| 2 | Check if controller auto-creates service request | `TptDailyVehicleInspectionController:57-60` creates service request |
| 3 | **Verify**: `TptVehicleServiceRequest::create([...])` called with `request_approval_status='Pending'` | Service request auto-created |
| 4 | **Verify**: Activity logged for auto-created request | Event exists |

### TC-CR01: Controller — store() No Validation Rules

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `TptVehicleServiceRequestController.php:51-85` | store() method |
| 2 | Search for `$request->validate(` | **NOT FOUND** |
| 3 | Search for `Validator::make(` | NOT FOUND |
| 4 | **Confirmed**: No validation in store() — all fields accepted blindly | **P1 Finding** |

### TC-CR02: Controller — update() Manually Validates

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `update()` method | Lines 126-160 |
| 2 | Line 131: `$validated = $request->validate([...])` | Inline validation, no FormRequest |
| 3 | **Confirmed**: Uses inline validation — NOT a FormRequest class | **P1 Finding** |

### TC-CR03: Controller — No Change Tracking on Update

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `update()` method lines 126-160 | Method body |
| 2 | Search for `$serviceRequest->getOriginal()` | NOT FOUND |
| 3 | Search for `$serviceRequest->getChanges()` | NOT FOUND |
| 4 | Compare with FuelLogController update | FuelLog does getOriginal/getChanges comparison |
| 5 | **Confirmed**: No change tracking — activity log has no diff data | **P1 Finding** |

### TC-CR05: Controller — forceDelete Uses `onlyTrashed()`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `forceDelete()` line 291-307 | Method |
| 2 | Line 295: `$s = TptVehicleServiceRequest::onlyTrashed()->findOrFail($id)` | onlyTrashed used |
| 3 | Compare FuelLog: FuelLog uses `withTrashed()` | **Bug: cannot force-delete active** |
| 4 | **Confirmed**: Should be `withTrashed()` | **P1 Finding** |

### TC-CR06: Controller — toggleStatus Route But No Method

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check web.php line 49 | Route registered |
| 2 | Search controller for `toggleStatus` | NOT FOUND |
| 3 | POST to route | 500 error |
| 4 | **Confirmed**: Route exists, no method | **P1 Finding** |

### TC-CR07: Model — Fillable Matches DDL

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open Model lines 27-36 | 8 fillable fields |
| 2 | Compare with DDL columns | id, created_at, updated_at, deleted_at excluded (correct) |
| 3 | **Verified**: Fillable matches writable columns | OK |

### TC-CR08: Model — DDL Field Name Mismatch `Vehicle_status`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check DDL: column is `Vehicle_status` (capital V) | DDL has capital V |
| 2 | Check Model fillable: `vehicle_status` (lowercase v) | Model has lowercase |
| 3 | MySQL treats column names case-insensitively | Works but inconsistent |
| 4 | **Confirmed**: Case mismatch between DDL and model | **P1 Finding** |

### TC-CR09: Model — Duplicate Relationships

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open Model lines 61-67: `inspection()` | BelongsTo mapping |
| 2 | Open Model lines 88-94: `vehicleInspection()` | SAME BelongsTo mapping |
| 3 | Both use `vehicle_inspection_id` → `TptDailyVehicleInspection` | **Identical — redundant** |

### TC-CR10: Model — Default Attributes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open Model lines 41-43 | `$attributes = ['request_approval_status' => 'Pending']` |
| 2 | **Verified**: Default matches DDL DEFAULT 'Pending' | OK |

### TC-CR11: Model — No `SoftDeletes` in Activity Log Message

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check `destroy()` activity log line 241-243 | Event = 'Deleted', NOT 'Trashed' |
| 2 | Compare with other controllers that use 'Trashed' for soft delete | Inconsistent naming |
| 3 | **Confirmed**: Activity event is 'Deleted', not 'Trashed' | **P1 Finding** |

### TC-CR12: Controller — updateStatus Uses `firstOrCreate` Correctly

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `updateStatus()` lines 187-196 | `TptVehicleMaintenance::firstOrCreate([...], [...])` |
| 2 | **Verify**: First param `['vehicle_service_request_id' => $id]` is unique key | Prevents duplicate |
| 3 | **Verified**: Correct usage prevents duplicate maintenance | OK |

### TC-CR13: VehicleMgmtController — storeStatus Duplicates Logic

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `VehicleMgmtController::storeStatus()` lines 198-236 | Duplicate create logic |
| 2 | Compare with `TptVehicleServiceRequestController::store()` | Different patterns (new+save vs ::create) |
| 3 | storeStatus validates `exists:tpt_daily_vehicle_inspections` (WRONG PLURAL) | **Bug**: references non-existent table |
| 4 | storeStatus has NO activityLog | **GAP**: No audit trail |
| 5 | **Confirmed**: Duplicate logic creates inconsistency risk | **P1 Finding** |

### TC-CR14: Activity Log Events — Naming Inconsistency

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check all activityLog calls in controller | 7 different event names |
| 2 | Create: 'Created', Update: 'Updated', Delete: 'Deleted' | Consistent-ish |
| 3 | Restore: 'Restored', Force Delete: 'Force Deleted' | OK |
| 4 | Approve: 'Approved', Reject: 'Rejected' | OK |
| 5 | **Note**: Some controllers use 'Trashed' instead of 'Deleted' for soft-delete | Inconsistent across Transport module |

### TC-CR15: Routes — resource Generates store() But No FormRequest

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check web.php line 44: `Route::resource('vehicle-service-request', ...)` | Resource generates all 7 routes |
| 2 | store() is generated but uses plain Request $request | No FormRequest |
| 3 | **Confirmed**: Resource controller without FormRequest | **P1 Finding** |

### TC-CR16: Policy — Unused Methods

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `TransportVehicleServiceRequestPolicy.php` | 6 extra methods |
| 2 | Methods: `status()`, `import()`, `export()`, `print()`, `submit()`, `cancel()` | Defined |
| 3 | Search controller for `Gate::authorize(...{status,import,export,print,submit,cancel})` | NOT used |
| 4 | **Confirmed**: Dead code in policy | **P2 Finding** |

### TC-CR17: Controller — destroy() No `is_active=false`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `destroy()` lines 234-248 | Only `->delete()` called |
| 2 | Search for `is_active` in controller | NOT in destroy |
| 3 | Model has no `is_active` column in DDL | Soft delete relies solely on deleted_at |
| 4 | **Confirmed**: destroy() does not toggle is_active (column doesn't exist) | OK — soft delete is sufficient |

### BC-BIZ-DEEP-01-STEP: store() Blind Acceptance

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST to store with random extra field `x_unknown=injected` | Extra field ignored by $fillable guard |
| 2 | POST with empty `vehicle_inspection_id` (no validation) | Stored as NULL (field is NOT NULL in DDL → DB error) |
| 3 | **Verify**: No validation blocks any input | Store accepts everything |

### BC-BIZ-DEEP-06-STEP: update() Inline Validation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `update()` lines 131-137 | 5 validation rules |
| 2 | Test: `reason` = 513 chars | `max:512` fails |
| 3 | Test: `vehicle_inspection_id` = 99999 | `exists` fails |
| 4 | Test: `request_date` = "abc" | `date` fails |
| 5 | Test: `service_completion_date` before request_date | `after_or_equal` fails |

### BC-BIZ-DEEP-39-STEP: VehMgmtCtrl updateStatus Uses create() NOT firstOrCreate()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `VehicleMgmtController::updateStatus()` lines 178-188 | Uses `TptVehicleMaintenance::create([...])` |
| 2 | Approve service request X from VehicleMgmt dashboard | Maintenance M1 created |
| 3 | Approve SAME request X again | Maintenance M2 created (DUPLICATE) |
| 4 | DB check: `SELECT COUNT(*) FROM tpt_vehicle_maintenance WHERE vehicle_service_request_id = X` | **COUNT > 1** — duplicate entries |
| 5 | **BUG confirmed**: VehicleMgmtController updateStatus does NOT use firstOrCreate | **Data integrity issue** |

### BC-BIZ-DEEP-41-STEP: storeStatus Validates Wrong Table Name

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `VehicleMgmtController::storeStatus()` line 207 | `exists:tpt_daily_vehicle_inspections,id` |
| 2 | Check actual table name in database | Table is `tpt_daily_vehicle_inspection` (singular) |
| 3 | Submit storeStatus with valid `vehicle_inspection_id` | Validation rule references non-existent table → **Validation may fail or pass incorrectly** |
| 4 | **BUG confirmed**: Validation references wrong table name (plural vs singular) | **P1 Finding** |

### BC-BIZ-DEEP-34-STEP: toggleStatus Route — No Method

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check web.php line 49: `Route::post('/vehicle-service-request/{vehicle}/toggle-status', [..., 'toggleStatus'])` | Route registered |
| 2 | Search controller for `function toggleStatus` | NOT FOUND |
| 3 | Send POST `/vehicle-service-request/1/toggle-status` | **500 error**: `Call to undefined method toggleStatus()` |
| 4 | **BUG confirmed**: Route with no handler | Must implement method or remove route |

### BC-BIZ-DEEP-52-STEP: Model Scopes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Call `TptVehicleServiceRequest::pending()->get()` | SQL: `WHERE request_approval_status = 'Pending'` |
| 2 | Call `TptVehicleServiceRequest::approved()->get()` | SQL: `WHERE request_approval_status = 'Approved'` |
| 3 | Call `TptVehicleServiceRequest::rejected()->get()` | SQL: `WHERE request_approval_status = 'Rejected'` |
| 4 | Used in `VehicleMgmtController::getDetailedPendingData()` | Dashboard pending tab |

### BC-BIZ-DEEP-08-STEP: No Change Tracking on Update

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Original: `reason = "Engine noise"` | Before update |
| 2 | Update: `reason = "Transmission issue"` | After update |
| 3 | **Verify**: No `$serviceRequest->getOriginal()` call | Controller does not capture old values |
| 4 | **Verify**: No `$serviceRequest->getChanges()` call | Controller does not compute diff |
| 5 | Activity log entry has `message` but NO `changes` array | No what-changed data |
| 6 | Compare FuelLog update: captures original, computes changes, includes in activity | **GAP**: ServiceLog lacks audit detail |

### BC-BIZ-DEEP-11-STEP: Activity 'Deleted' NOT 'Trashed'

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete a service request | `destroy()` called |
| 2 | Check activity_log table | `event = 'Deleted'` |
| 3 | Compare with Inspection controller destroy | Inspection uses 'Trashed' event |
| 4 | **Inconsistency**: Same operation (soft delete), different event names | Module-wide naming inconsistency |

### BC-BIZ-DEEP-14-STEP: forceDelete onlyTrashed Bug

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create active service request (not deleted) | id=X, deleted_at=NULL |
| 2 | Call `forceDelete(X)` | Controller hit |
| 3 | `TptVehicleServiceRequest::onlyTrashed()->findOrFail($id)` | `onlyTrashed` adds `WHERE deleted_at IS NOT NULL` |
| 4 | Active record has deleted_at=NULL → excluded | `findOrFail()` → ModelNotFoundException → 404 |
| 5 | **Cannot force-delete without soft-deleting first** | Must call destroy() then forceDelete() |
| 6 | Workaround: Delete first, then force-delete from trash | Two-step process |

### BC-BIZ-DEEP-22-STEP: Single Gate for Approve + Reject

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User has only `tenant.vehicle-service-approval.approve` permission | Has approval permission |
| 2 | User does NOT have `tenant.vehicle-service-approval.reject` | Lacks reject permission |
| 3 | POST updateStatus with `status=Rejected` | **Still passes** — same Gate covers both |
| 4 | **Implication**: approve permission = approve AND reject capability | No granular control |

### BC-BIZ-DEEP-35-STEP: Different Eager Loading in VehMgmtCtrl

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `VehicleMgmtController::vehicleServiceRequestQuery()` | Lines 124-154 |
| 2 | Eager loads: `inspection.vehicle`, `inspection.driver`, `inspection.inspector`, `approvedBy` | 4 relationship paths |
| 3 | Compare: `TptVehicleServiceRequestController::index()` loads: `vehicleInspection`, `approvedBy`, `vehicleMaintenance` | 3 relationships |
| 4 | vehicleMaintenance is MISSING from VehMgmtCtrl query | Tab view cannot show maintenance link |
| 5 | Tab view uses `inspection.vehicle` path (nested) vs standalone uses `vehicleInspection` (direct) | Different relationship aliases used |

### BC-BIZ-DEEP-38-STEP: Different Pagination Sizes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check `VehicleMgmtController::index()` line 45 | `$serviceRequests = $this->vehicleServiceRequestQuery($request)->paginate(10)` |
| 2 | Check `TptVehicleServiceRequestController::index()` line 28 | `->paginate(20)` |
| 3 | VehicleMgmt tab shows 10 per page | Tab view pagination = 10 |
| 4 | Standalone index shows 20 per page | Standalone pagination = 20 |
| 5 | **Inconsistency**: Same entity, different page sizes | User experience differs |

### BC-BIZ-DEEP-53-STEP: Different Instantiation Patterns

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `TptVehicleServiceRequestController::store()` line 56 | `TptVehicleServiceRequest::create([...])` |
| 2 | Open `VehicleMgmtController::storeStatus()` line 211 | `$sr = new TptVehicleServiceRequest(); $sr->save()` |
| 3 | ::create() uses mass assignment (fillable guard) | All fillable fields settable at once |
| 4 | new+save() sets each field individually | Field-by-field assignment |
| 5 | storeStatus includes `service_completion_date` conditionally | Additional logic in VehMgmtCtrl version |

### CODE-TRACE-DEEP-01: index() Execution Path

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User calls GET `/vehicle-service-request` | index() invoked |
| 2 | `Gate::authorize('tenant.vehicle-service-request.viewAny')` | Permission check |
| 3 | `TptVehicleServiceRequest::with(['vehicleInspection','approvedBy','vehicleMaintenance'])` | Eager load 3 relationships |
| 4 | `->latest()` | `ORDER BY created_at DESC` |
| 5 | `->paginate(20)` | `LIMIT 20 OFFSET 0` + count query |
| 6 | `return view('transport::vehicle-service-request.index', compact('data'))` | Renders standalone index |
| 7 | **Query count**: 1 main + 3 eager load queries = 4 queries | N+1 prevented |

### CODE-TRACE-DEEP-02: create() Execution Path

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User calls GET `/vehicle-service-request/create` | create() invoked |
| 2 | `Gate::authorize('tenant.vehicle-service-request.create')` | Permission check |
| 3 | `TptDailyVehicleInspection::latest()->get()` | SELECT * FROM tpt_daily_vehicle_inspection ORDER BY inspection_date DESC |
| 4 | `return view(... compact('inspections'))` | Renders create form with all inspections |
| 5 | **Note**: No `where('is_active',1)` filter on inspections | All inspections shown |

### CODE-TRACE-DEEP-03: store() Execution Path

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User POSTs to `/vehicle-service-request` | store() invoked |
| 2 | `Gate::authorize('create')` | Permission check |
| 3 | **NO validation** — enters try block directly | `try {` |
| 4 | `TptVehicleServiceRequest::create([...])` | INSERT query |
| 5 | Auto-sets approved_by + approved_at if status=Approved | Conditional assignment |
| 6 | `activityLog($sr, 'Created', ['message'=>'Vehicle service request created successfully'])` | INSERT into activity_log |
| 7 | `return redirect()->route('transport.vehicle-mgmt.index')->with('success', ...)` | 302 redirect |
| 8 | On exception: `return redirect()->with('error', 'Something went wrong!')` | Error redirect |
| 9 | **Note**: NO `DB::beginTransaction()` → partial operations not rolled back on exception | Transaction gap |

### CODE-TRACE-DEEP-04: show() Execution Path

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User calls GET `/vehicle-service-request/{id}` | show() invoked |
| 2 | `Gate::authorize('view')` | Permission check |
| 3 | `TptVehicleServiceRequest::with(['vehicleInspection','approvedBy','vehicleMaintenance'])` | Eager load |
| 4 | `->findOrFail($id)` | SELECT + ModelNotFoundException on miss |
| 5 | `return view('transport::vehicle-service-request.show', compact('record'))` | Detail view |

### CODE-TRACE-DEEP-05: edit() Execution Path

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User calls GET `/vehicle-service-request/{id}/edit` | edit() invoked |
| 2 | `Gate::authorize('update')` | Permission check |
| 3 | `TptVehicleServiceRequest::findOrFail($id)` | SELECT single record |
| 4 | `TptDailyVehicleInspection::latest()->get()` | SELECT all inspections |
| 5 | `return view('transport::vehicle-service-request.edit', compact('serviceRequest','inspections'))` | Edit form |

### CODE-TRACE-DEEP-06: update() Execution Path

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User PUTs to `/vehicle-service-request/{id}` | update() invoked |
| 2 | `Gate::authorize('update')` | Permission check |
| 3 | `$request->validate([5 rules])` | Inline validation |
| 4 | `$sr = TptVehicleServiceRequest::findOrFail($id)` | SELECT + 404 if missing |
| 5 | `$sr->update([5 fields])` | UPDATE query (no approval_status) |
| 6 | `activityLog($sr, 'Updated', ['message'=>'Vehicle service request updated'])` | INSERT activity_log |
| 7 | `return redirect()->route('transport.vehicle-mgmt.index')->with('success', ...)` | 302 redirect |
| 8 | **No change tracking**: getOriginal()/getChanges() NOT called | Audit lacks what-changed |

### CODE-TRACE-DEEP-07: updateStatus() — Approve Path

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User POSTs to `/vehicle-service-request/{id}/update-status` with `status=Approved` | updateStatus() invoked |
| 2 | `Gate::authorize('tenant.vehicle-service-approval.approve')` | Permission check |
| 3 | `$request->validate(['request_approval_status'=>'required|in:Approved,Rejected'])` | Validation |
| 4 | `$sr = TptVehicleServiceRequest::findOrFail($id)` | SELECT |
| 5 | `$sr->update(['request_approval_status'=>'Approved', 'approved_by'=>Auth::id(), 'approved_at'=>now()])` | UPDATE |
| 6 | `TptVehicleMaintenance::firstOrCreate(['vehicle_service_request_id'=>$id], [...])` | INSERT or SELECT |
| 7 | `activityLog($sr, 'Approved', ['message'=>'Service request approved & maintenance initiated'])` | INSERT |
| 8 | `return response()->json([success:true, status:'Approved', maintenance_id => $m->id])` | JSON 200 |

### CODE-TRACE-DEEP-08: updateStatus() — Reject Path

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST with `status=Rejected` | updateStatus() invoked |
| 2 | Steps 2-4 same as Approve path | Same validation + find |
| 3 | `$sr->update(['request_approval_status'=>'Rejected', ...])` | UPDATE status only |
| 4 | **SKIP** maintenance creation | No firstOrCreate call |
| 5 | `activityLog($sr, 'Rejected', ['message'=>'Service request rejected'])` | INSERT |
| 6 | `return response()->json([success:true, status:'Rejected', message=>'Request has been rejected.'])` | JSON 200 |

### CODE-TRACE-DEEP-09: destroy() Execution Path

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User DELETE to `/vehicle-service-request/{id}` | destroy() invoked |
| 2 | `Gate::authorize('delete')` | Permission check |
| 3 | `$sr = TptVehicleServiceRequest::findOrFail($id)` | SELECT + 404 if missing |
| 4 | `$sr->delete()` | UPDATE SET deleted_at=NOW() (soft delete) |
| 5 | `activityLog($sr, 'Deleted', ['message'=>'Vehicle service request deleted'])` | INSERT |
| 6 | `return redirect()->route('transport.vehicle-mgmt.index')->with('success', ...)` | 302 redirect |

### CODE-TRACE-DEEP-10: restore() Execution Path

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User GET to `/vehicle-service-request/{id}/restore` | restore() invoked |
| 2 | `Gate::authorize('restore')` | Permission check |
| 3 | `$sr = TptVehicleServiceRequest::onlyTrashed()->findOrFail($id)` | SELECT WHERE deleted_at IS NOT NULL |
| 4 | `$sr->restore()` | UPDATE SET deleted_at=NULL |
| 5 | `activityLog($sr, 'Restored', ['message'=>'Vehicle service request restored'])` | INSERT |
| 6 | `return redirect()->route('transport.vehicle-mgmt.index')` | 302 redirect |

### CODE-TRACE-DEEP-11: forceDelete() Execution Path

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User DELETE to `/vehicle-service-request/{id}/force-delete` | forceDelete() invoked |
| 2 | `Gate::authorize('forceDelete')` | Permission check |
| 3 | `$sr = TptVehicleServiceRequest::onlyTrashed()->findOrFail($id)` | SELECT WHERE deleted_at IS NOT NULL |
| 4 | Active record → NOT found → 404 | **BUG**: onlyTrashed prevents force-deleting active |
| 5 | Trashed record → found → `$sr->forceDelete()` | DELETE FROM table (hard delete) |
| 6 | `activityLog($sr, 'Force Deleted', ['message'=>'...'])` | INSERT (on deleted model — may fail) |
| 7 | `return redirect()->route('transport.vehicle-mgmt.index')` | 302 redirect |

### TC-EDGE-01: Concurrent Approval Race

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Two users simultaneously approve same Pending request | Race condition |
| 2 | User A calls updateStatus at T+0ms | User A's request processed |
| 3 | User B calls updateStatus at T+50ms | No locking mechanism |
| 4 | Both find `request_approval_status='Pending'` before update | Both proceed |
| 5 | User A: status→Approved, maintenance created | FirstOrCreate prevents duplicate maintenance |
| 6 | User B: status→Approved (again), firstOrCreate returns existing | Second approval overwrites but maintenance deduped |
| 7 | **Risk**: Status updated twice, but firstOrCreate prevents maintenance duplicate | Partially safe |

### TC-EDGE-02: Create With Null Dates in store()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST store with `request_date` = null (not sent) | DDL is NOT NULL → MySQL error |
| 2 | POST store with `service_completion_date` = null (not sent) | DDL nullable → stored as NULL |
| 3 | POST store with all fields empty | `::create([...])` with nulls → MySQL errors on NOT NULL columns |

### TC-EDGE-03: XSS in reason Field

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create service request with reason = `<script>alert('XSS')</script>` | Stored in DB |
| 2 | View show page: reason displayed with `{{ $record->reason }}` | Blade auto-escapes with `{{ }}` — safe |
| 3 | View index: `{{ Str::limit($service->reason, 40) }}` | Auto-escaped — safe |
| 4 | **Verify**: No `{!! !!}` unescaped output in any view | No XSS vector |

### TC-EDGE-04: SQL Injection in Search

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Search with `' OR 1=1 --` | `LIKE "%' OR 1=1 --%"` — parameterized query |
| 2 | Laravel Eloquent uses parameterized queries | Safe from SQL injection |
| 3 | **Verify**: Search term treated as string literal only | No injection risk |

### TC-EDGE-05: Large Payload in store()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST store with 1MB request body | PHP `post_max_size` limit |
| 2 | POST store with 10,000 additional fake fields | Laravel `max_input_vars` limit |
| 3 | POST store with reason = 100,000 characters | No max:512 validation in store → truncated by MySQL VARCHAR(512) |

### TC-EDGE-06: Update With Same Values (Idempotency)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Read current values for service request X | Known state |
| 2 | PUT update with identical values (no change) | Update executed |
| 3 | DB: `updated_at` changes | Always updates timestamp |
| 4 | Activity log: 'Updated' event created | Logged even for no-op update |
| 5 | **Note**: No "nothing changed" guard — always updates + always logs | Over-logging on no-op saves |

### TC-EDGE-07: Create With Future Request Date

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST store with `request_date` = 2099-01-01 (far future) | No validation — accepted |
| 2 | DB: `request_date` = 2099-01-01 | Stored despite being unrealistic |
| 3 | **Note**: No `before:now` or `before:tomorrow` validation in store() or update() | Future dates accepted |

### TC-EDGE-08: Approve Already Approved Request

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Request is already Approved | status=Approved |
| 2 | POST updateStatus with status=Approved again | Validation passes (in:Approved,Rejected) |
| 3 | `$sr->update([...])` runs again | updated_at changes |
| 4 | `firstOrCreate` finds existing maintenance | Returns existing — no duplicate |
| 5 | Logs 'Approved' again | Duplicate activity log entry |

### TC-EDGE-09: Reject Already Rejected Request

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Request is already Rejected | status=Rejected |
| 2 | POST updateStatus with status=Rejected again | Validation OK |
| 3 | Status updated to Rejected again (no-op) | Same value |
| 4 | Activity log: 'Rejected' logged again | Duplicate rejection event |

### TC-EDGE-10: Create Without Any Inspection (null vehicle_inspection_id)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST store with `vehicle_inspection_id` = null/empty | No validation — accepted |
| 2 | Controller assigns `$request->vehicle_inspection_id` which is null | `null` assigned |
| 3 | DDL: `vehicle_inspection_id` is `INT UNSIGNED NOT NULL` | **MySQL error**: Column cannot be null |
| 4 | Catch block: redirect with error | "Something went wrong!" |
| 5 | **Note**: store() has NO validation to prevent this; DDL constraint saves data integrity | DB-level guard prevents bad data |

### TC-EDGE-11: store() With Valid vehicle_inspection_id But Missing All Other Fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST store with only `vehicle_inspection_id` = valid ID | All other fields null |
| 2 | DDL: `request_date` is NOT NULL → MySQL error | DB-level constraint violation |
| 3 | DDL: `reason` is DEFAULT NULL → passes | NULL stored for reason |
| 4 | DDL: `Vehicle_status` is DEFAULT NULL → passes | NULL stored |
| 5 | Controller catch block → redirect error | Exception handled |

### TC-EDGE-12: Toggle Between Approved and Rejected

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Approve request → status=Approved + maintenance created | Approved |
| 2 | POST updateStatus with status=Rejected on same request | Validation allows it (in:Approved,Rejected) |
| 3 | Status changes to Rejected | approved_by/approved_at still set from previous approval |
| 4 | Maintenance record from step 1 STILL EXISTS | Maintenance NOT deleted on rejection |
| 5 | **Data anomaly**: Rejected request has associated maintenance entry | Orphan maintenance |

### TC-INTEGRATION-01: Full Approval Flow (Create → Approve → Maintenance)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create service request via store() | id=X, status=Pending |
| 2 | Approve via approval blade AJAX | JSON success response |
| 3 | Navigate to Vehicle Maintenance tab | Check maintenance for request X exists |
| 4 | Verify maintenance: type='General Service', cost=0, status='Pending' | Default values correct |
| 5 | Verify service request: status=Approved, approved_by set, approved_at set | Approval fields populated |

### TC-INTEGRATION-02: API Consistency — Same Action From Two Controllers

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Call `TptVehicleServiceRequestController::updateStatus()` with Approved | Returns JSON with maintenance_id |
| 2 | Call `VehicleMgmtController::updateStatus()` with Approved | Returns redirect()->back() |
| 3 | **Inconsistency**: Same logical action, different response formats | JSON vs HTML redirect |
| 4 | Also: TptVehicleServiceRequestController uses firstOrCreate, VehMgmtCtrl uses create | Different duplication behavior |

### TC-INTEGRATION-03: Dashboard Pending Count Consistency

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check `VehicleMgmtController::getDetailedPendingData()` | `TptVehicleServiceRequest::pending()->take(10)->get()` |
| 2 | Change a request status from Pending to Approved | Status changed |
| 3 | Refresh dashboard | Pending count decreased by 1 |
| 4 | Change it back to Pending | Count increases |

### TC-INTEGRATION-04: FK CASCADE — Delete Inspection Deletes Service Request

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Identify inspection Y that has linked service requests | inspect Y → multiple SRs |
| 2 | Delete inspection Y via Inspection controller/direct DB | `DELETE FROM tpt_daily_vehicle_inspection WHERE id=Y` |
| 3 | **Verify**: FK CASCADE triggers | All service requests with vehicle_inspection_id=Y deleted |
| 4 | **Verify**: `TptVehicleMaintenance` records linked to those SRs also cascade-deleted (if FK exists) | Check maintenance FK definition |
| 5 | **Impact**: Deleting an inspection can cascade-delete service requests AND their maintenance | Multi-table cascade risk |

### TC-INTEGRATION-05: Auto-Creation of Service Request From Failed Inspection

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `TptDailyVehicleInspectionController` store/update method | Check for auto-creation logic |
| 2 | Call store/update that sets inspection to 'Failed' | Conditional create SR |
| 3 | **Verify**: `TptVehicleServiceRequest::create(['vehicle_inspection_id' => $inspection->id, 'request_approval_status' => 'Pending'])` | Auto-created with Pending |
| 4 | **Verify**: Activity logged for auto-created SR | 'Created' event |

### TC-DATA-01: Verify `tpt_vehicle_service_request` Table Structure

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `DESCRIBE tpt_vehicle_service_request` | 12 columns as per BC-DB |
| 2 | Check `Vehicle_status` column name | Capital V in DDL |
| 3 | Check FK `fk_vsl_vehicleInspection` | REFERENCES tpt_daily_vehicle_inspection(id) ON DELETE CASCADE |
| 4 | Check FK for `approved_by` | REFERENCES sys_users(id) ON DELETE SET NULL |
| 5 | Check `request_approval_status` ENUM values | 'Approved','Pending','Rejected' |

### TC-DATA-02: Verify Model to Table Mapping

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `$model->getTable()` | Returns 'tpt_vehicle_service_request' |
| 2 | `$model->getFillable()` | 8 fields as per BC-DB note |
| 3 | `$model->getCasts()` | 3 datetime casts |
| 4 | `$model->getAttributes()` | Default `request_approval_status` = 'Pending' |
| 5 | `$model->vehicleStatus()` relationship | BelongsTo Dropdown via vehicle_status |

### TC-DATA-03: Verify Soft Delete Behavior

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `$model->delete()` | `deleted_at` set to current timestamp |
| 2 | `TptVehicleServiceRequest::all()` | Excludes soft-deleted |
| 3 | `TptVehicleServiceRequest::withTrashed()->get()` | Includes soft-deleted |
| 4 | `TptVehicleServiceRequest::onlyTrashed()->get()` | Only soft-deleted |
| 5 | `$model->restore()` | `deleted_at` = NULL |
| 6 | `$model->forceDelete()` | Permanently removed from DB |

### TC-EDGE-13: Special Characters in Reason

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create SR with reason containing emojis: `🔧 Engine 🚗 noise 🛠️` | Stored in DB |
| 2 | Create SR with reason containing newlines: `Line1\nLine2\nLine3` | Multiline stored |
| 3 | Create SR with reason containing HTML tags: `<b>Bold</b> <i>Italic</i>` | Stored as plaintext, escaped by Blade |
| 4 | Create SR with reason: single quote `O'Brien's vehicle` | Escaped by prepared statement |

### TC-EDGE-14: Boundary — request_date Edge Values

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST store with `request_date` = `0000-00-00` | Invalid date — MySQL may error or store zero |
| 2 | POST store with `request_date` = `1970-01-01` (Unix epoch) | Accepted — no lower bound |
| 3 | POST store with `request_date` = `9999-12-31` (MySQL max) | Accepted — no upper bound |
| 4 | POST store with `request_date` = empty string | No validation → MySQL error on NOT NULL |

### TC-EDGE-15: Activity Log Message Format Consistency

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check create message: `'Vehicle service request created successfully'` | Full sentence |
| 2 | Check update message: `'Vehicle service request updated'` | Missing "successfully" |
| 3 | Check delete message: `'Vehicle service request deleted'` | Missing "successfully" |
| 4 | Check restore message: `'Vehicle service request restored'` | Missing "successfully" |
| 5 | Check force-delete message: `'Vehicle service request permanently deleted'` | Full sentence with "permanently" |
| 6 | **Inconsistency**: Messages inconsistently use "successfully" | Some have it, some don't |

---

*Template: tpt_PickupStopsList_TcList.md (Syllabus depth) | Entity: ServiceLog (VehicleServiceRequest) | Date: 2026-07-21*
