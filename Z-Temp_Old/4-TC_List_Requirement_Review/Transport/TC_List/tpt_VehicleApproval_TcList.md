# tpt_VehicleApproval_TcList

## Module: Transport → Vehicle Management → Approval

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | Transport |
| Tab Group | Vehicle Management (5-tab container via `VehicleMgmtController`) |
| Feature | Approval (Pending Items Tab) |
| URL(s) | `/vehicle-mgmt` (index — all tabs loaded), `/vehicle-service-request/{id}/update-status` (POST — actual approval endpoint used by blade AJAX) |
| Controller | `Modules\Transport\Http\Controllers\VehicleMgmtController` (hub), `Modules\Transport\Http\Controllers\TptVehicleServiceRequestController` (actual approval action) |
| Model | No dedicated model — approval tab displays `TptVehicleServiceRequest` only (with `inspection.vehicle`, `inspection.driver`, `approvedBy` relations). `$pendingData` (Fuel, Inspection, Maintenance) loaded but NEVER rendered in blade — dead code. |
| Validation | Inline in `TptVehicleServiceRequestController@updateStatus()` — the only reachable approval endpoint |
| Permissions | `tenant.transport.viewAny` (tab display), `tenant.vehicle-service-approval.view` (action buttons visibility), `tenant.vehicle-service-approval.approve` (gate in controller) |
| Soft Deletes | All 4 underlying entities use `SoftDeletes` trait with full restore/forceDelete controller methods — see individual entity TC lists |
| Activity Log | Present in `TptVehicleServiceRequestController@updateStatus` (Approved/Rejected). Missing in `TptVehicleMaintenanceController@update`. `VehicleMgmtController@updateStatus`/`storeStatus` are dead code with no activityLog. |

---

## 2. Pre-conditions

- Required permissions: `tenant.transport.viewAny` (broad permission for entire Vehicle Management module)
- Tenant context initialized
- Pending SERVICE REQUESTS must exist (`TptVehicleServiceRequest` with `request_approval_status='Pending'`)
- Approval action requires `tenant.vehicle-service-approval.approve` permission (checked in `TptVehicleServiceRequestController@updateStatus` — line 167)
- Action buttons visibility controlled by `@can('tenant.vehicle-service-approval.view')` in blade (approval.blade.php:122)
- Dusk environment variables configured

---

## 3. Default Data Load

When the page loads via `VehicleMgmtController@index()` (GET `/vehicle-mgmt`):

**Approval tab renders via `transport::vehicle-service-request.approval` partial, which uses:**

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| Service Requests | [Query/Code Removed] | [Query/Code Removed] | `approval_status` filter (line 135-137), `search` (reason/vehicle/driver) at lines 140-151 | 10 per page |

**Dead code — `$pendingData` loaded but NEVER rendered in approval blade:**

| Data | Source | Query | Notes |
|------|--------|-------|-------|
| Pending Fuel Entries | `getDetailedPendingData()['vehicle_fuel']` | `TptVehicleFuel::pending()->with(['vehicle','driver'])->orderBy('created_at','desc')->take(10)` | ⚠️ Never used in blade |
| Pending Inspections | `getDetailedPendingData()['daily_inspection']` | `TptDailyVehicleInspection::pending()->with(['vehicle','driver'])->orderBy('inspection_date','desc')->take(10)` | ⚠️ Never used in blade |
| Pending Service Requests | `getDetailedPendingData()['service_request']` | `TptVehicleServiceRequest::pending()->with(['inspection.vehicle'])->orderBy('request_date','desc')->take(10)` | ⚠️ Never used in blade — duplicates `$serviceRequests` |
| Pending Maintenance | `getDetailedPendingData()['vehicle_maintenance']` | `TptVehicleMaintenance::where('status','Pending')->with(['serviceRequest.inspection.vehicle'])->orderBy('maintenance_initiation_date','desc')->take(10)` | ⚠️ Never used in blade |

The Approval tab does NOT have a standalone page — it only exists within the VehicleMgmt tab container.

---

## 4. Test Data Strategy

- **Pending Service Requests**: Create service requests with `request_approval_status='Pending'` (default on creation)
- **Approval action**: Approval tab uses `TptVehicleServiceRequestController@updateStatus` (AJAX POST to `/vehicle-service-request/{id}/update-status`)
- **VehicleMgmtController@updateStatus** (line 160): ⚠️ **DEAD CODE** — no route registered. Method exists but is unreachable.
- **VehicleMgmtController@storeStatus** (line 198): ⚠️ **DEAD CODE** — no route registered. Method exists but is unreachable.
- **Pending records shown**: 10 per page (paginated) for service requests

---

## 5. Business Conditions

### 5.1 Database Schema — Aggregated View

The Approval tab displays data from 4 tables. No DDL-specific to approval — see individual entity TC_List files for detailed DDL:

| Entity | Table | Status Column | Pending Value |
|--------|-------|---------------|---------------|
| Fuel | tpt_vehicle_fuel | status | 'Pending' |
| Inspection | tpt_daily_vehicle_inspection | inspection_status | 'Pending' |
| Service Request | tpt_vehicle_service_request | request_approval_status | 'Pending' |
| Maintenance | tpt_vehicle_maintenance | status | 'Pending' |

### 5.2 Validation Rules — Active Endpoints

**TptVehicleServiceRequestController@updateStatus() inline validation (the ONLY reachable approval endpoint):**

| BC ID | Field | Rule | Source (File:Line) |
|-------|-------|------|--------------------|
| BC-VAL-01 | request_approval_status | required, `in:Approved,Rejected` | `TptVehicleServiceRequestController.php:169-171` |

**Validation in VehicleMgmtController methods (⚠️ DEAD CODE — no routes registered):**

**updateStatus() inline validation (VehicleMgmtController — dead):**

| BC ID | Field | Rule | Source (File:Line) |
|-------|-------|------|--------------------|
| BC-VAL-D01 | request_approval_status | required, string, `in:Approved,Rejected` | `VehicleMgmtController.php:163` |

**storeStatus() inline validation (VehicleMgmtController — dead):**

| BC ID | Field | Rule | Source (File:Line) |
|-------|-------|------|--------------------|
| BC-VAL-D02 | request_date | required, date | `VehicleMgmtController.php:202` |
| BC-VAL-D03 | vehicle_status | required, string | `VehicleMgmtController.php:203` |
| BC-VAL-D04 | reason | required, string, max:1000 | `VehicleMgmtController.php:204` |
| BC-VAL-D05 | request_approval_status | nullable, string | `VehicleMgmtController.php:205` |
| BC-VAL-D06 | service_completion_date | nullable, date | `VehicleMgmtController.php:206` |
| BC-VAL-D07 | vehicle_inspection_id | nullable, `exists:tpt_daily_vehicle_inspections,id` | `VehicleMgmtController.php:207` — table name typo `tpt_daily_vehicle_inspections` (plural) does not exist; actual table is `tpt_daily_vehicle_inspection` (singular) |

**Active TptVehicleServiceRequestController@update() validation (not on approval tab, but used for service request edit):**

| BC ID | Field | Rule | Source |
|-------|-------|------|--------|
| BC-VAL-02 | vehicle_inspection_id | nullable, `exists:tpt_daily_vehicle_inspection,id` | `TptVehicleServiceRequestController.php:132` — correct singular table name ✅ |
| BC-VAL-03 | request_date | required, date | line 133 |
| BC-VAL-04 | vehicle_status | required | line 134 |
| BC-VAL-05 | service_completion_date | nullable, date, after_or_equal:request_date | line 135 |
| BC-VAL-06 | reason | required, string, max:512 | line 136 — note: 512 chars, different from dead code's max:1000 |

### 5.3 Authorization (Permission Gates)

| BC ID | Permission | Method | Location | Behavior |
|-------|-----------|--------|----------|----------|
| BC-AUTH-01 | tenant.transport.viewAny | VehicleMgmtController@index() | VehicleMgmtController.php:29 | Without → 403; entire Vehicle Management page hidden |
| BC-AUTH-02 | tenant.vehicle-service-approval.view | Blade `@can` — action column in approval.blade.php | approval.blade.php:122 | Without → action buttons (view/approve/reject) hidden; only table rows visible |
| BC-AUTH-03 | tenant.vehicle-service-approval.approve | TptVehicleServiceRequestController@updateStatus() | TptVehicleServiceRequestController.php:167 | Without → 403 on AJAX approve/reject POST |
| BC-AUTH-04 | tenant.vehicle-fuel.approve | TptVehicleFuelController@updateStatus() | (fuel controller) | Without → 403 on fuel status update (Fuel Log tab, not Approval) |
| BC-AUTH-05 | tenant.daily-vehicle-inspection.approve | TptDailyVehicleInspectionController@updateStatus() | TptDailyVehicleInspectionController.php:228 | Without → 403 on inspection status update (Inspection tab, not Approval) |
| BC-AUTH-FUEL | tenant.vehicle-fuel.viewAny | Fuel tab `@can` in hub view | vehiclemgmt.blade.php:17 | Without → Fuel Log tab hidden |
| BC-AUTH-INSP | tenant.daily-vehicle-inspection.viewAny | Inspection tab `@can` in hub view | vehiclemgmt.blade.php:20 | Without → Inspection tab hidden |
| BC-AUTH-SR | tenant.vehicle-service-request.viewAny | Service Log tab `@can` in hub view | vehiclemgmt.blade.php:23 | Without → Service Log tab hidden |
| BC-AUTH-MAINT | tenant.vehicle-maintenance.viewAny | Maintenance tab `@can` in hub view | vehiclemgmt.blade.php:28 | Without → Veh. Maintenance tab hidden |

**Dead code notes:**
- `VehicleMgmtController@updateStatus` has NO Gate check (line 160) — any `tenant.transport.viewAny` user could theoretically approve/reject. But this is DEAD CODE (no route).
- `VehicleMgmtController@storeStatus` has NO Gate check (line 198) — same dead code issue.

### 5.4 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Approval tab loads — Pending Service Requests | Paginated list of pending service requests with vehicle info, driver, reason, date, status; Approve/Reject buttons per row |
| BC-BIZ-02 | TptVehicleServiceRequestController@updateStatus — Approve | Sets `request_approval_status='Approved'`, `approved_by`, `approved_at` → creates `TptVehicleMaintenance::firstOrCreate([...])` → returns JSON success → page reload |
| BC-BIZ-03 | TptVehicleServiceRequestController@updateStatus — Reject | Sets `request_approval_status='Rejected'` → returns JSON success → page reload |
| BC-BIZ-04 | TptVehicleServiceRequestController@updateStatus — Uses `firstOrCreate()` | `TptVehicleMaintenance::firstOrCreate(['vehicle_service_request_id' => $id], [...])` → prevents duplicate maintenance entries |
| BC-BIZ-05 | Approval tab — Action buttons disabled after approval | Buttons get `disabled` class + `btn-outline-secondary` after approval/rejection; page reloads after 1.5s |

**Dead code (VehicleMgmtController methods — no routes):**

| BC ID | Condition | Expected Behavior | Status |
|-------|-----------|-------------------|--------|
| BC-BIZ-D01 | updateStatus — Approve | [Query/Code Removed] | [Query/Code Removed] |
| BC-BIZ-D02 | updateStatus — Reject | Sets `request_approval_status='Rejected'` | ⚠️ Dead code |
| BC-BIZ-D03 | storeStatus — Create Service Request | Field-by-field assignment ($serviceRequest->field = $request->field), not mass assignment | ⚠️ Dead code |
| BC-BIZ-D04 | getDetailedPendingData — Fuel, Inspection, ServiceRequest, Maintenance pending data | Loaded as `$pendingData` but NEVER referenced in blade | ⚠️ Dead code — data computed but not rendered |

### 5.4.1 Deep Business Logic (BC-BIZ-DEEP)

| BC-DEEP ID | Condition | Analysis | Verified Code Reference |
|------------|-----------|----------|------------------------|
| BC-BIZ-DEEP-01 | Approval via `TptVehicleServiceRequestController@updateStatus` uses `Gate::authorize('tenant.vehicle-service-approval.approve')` — BOTH approve and reject use the SAME gate | Policy has separate `approve()` and `reject()` methods but controller never uses `reject`. Users with `approve` permission can both approve and reject. No way to grant reject-only access. | `TptVehicleServiceRequestController.php:167`, `TransportVehicleServiceApprovalPolicy.php:38-48` |
| BC-BIZ-DEEP-02 | `firstOrCreate()` prevents race-condition duplicate maintenance | If user double-clicks Approve, two AJAX calls hit the endpoint. `firstOrCreate(['vehicle_service_request_id' => $id], [...])` ensures only ONE maintenance entry is created. The `vehicle_service_request_id` unique scope is application-level, not DB unique index. | `TptVehicleServiceRequestController.php:187-196` |
| BC-BIZ-DEEP-03 | `approved_by` and `approved_at` set from server (Auth::user()->id, now()) — NOT from request | AJAX sends `approved_by` in request payload (approval.blade.php:290) but controller ignores it and uses `Auth::user()->id`. Prevents spoofing of approver identity. | `TptVehicleServiceRequestController.php:180-181`, `approval.blade.php:290` |
| BC-BIZ-DEEP-04 | State machine: `request_approval_status` transitions only Pending→Approved or Pending→Rejected | No reverse transition (Approved→Pending) is possible. Once approved, the approve/reject buttons become disabled with `btn-outline-secondary` class. But there is no server-side guard against re-approving — the buttons being disabled is purely client-side. | `approval.blade.php:131-148`, `TptVehicleServiceRequestController.php:175-182` |
| BC-BIZ-DEEP-05 | Maintenance created on approval defaults: `status='Pending'`, `maintenance_type='General Service'`, `cost=0` | After approval, the maintenance record starts in Pending state. It must be separately updated via the Maintenance tab. No way to set custom maintenance type during approval flow. | `TptVehicleServiceRequestController.php:190-195` |
| BC-BIZ-DEEP-06 | Activity log records BOTH Approved and Rejected with distinct messages | Approved: "Service request approved & maintenance initiated". Rejected: "Service request rejected". Both log `performed_by` via `Auth::user()`. | `TptVehicleServiceRequestController.php:198-200, 211-213` |
| BC-BIZ-DEEP-07 | `TptVehicleMaintenanceController@update` (lines 85-108) back-propagates approval to service request | When a maintenance record is Approved via the Maintenance tab, it updates the parent service request's `request_approval_status='Approved'`, sets `approved_by`, `approved_at`, `service_completion_date=now()`, and `vehicle_status` to 'Service Done'. This creates a circular approval path. | `TptVehicleMaintenanceController.php:85-108` |
| BC-BIZ-DEEP-08 | Approval page reloads after 1.5s on success; buttons disable immediately | `setTimeout(() => location.reload(), 1500)`. Before reload, buttons get `disabled` property and visual class change. If user navigates away during the 1.5s, the request is NOT reverted — it's already saved server-side. | `approval.blade.php:312-323` |
| BC-BIZ-DEEP-09 | Blade uses `@canany` with SINGLE permission string at line 49 | `@canany(['tenant.vehicle-service-approval.view'])` — per rules, `@canany` is for multiple permissions. A single permission should use `@can`. This works functionally but violates coding convention. | `approval.blade.php:49` |
| BC-BIZ-DEEP-10 | AJAX sends `_method: "POST"` which is redundant | Line 291: `_method: "POST"` in data payload. Since the route is defined as `Route::post(...)`, this field is ignored by Laravel. Harmless but misleading. | `approval.blade.php:291` |
| BC-BIZ-DEEP-11 | `toggleStatus` route (web.php line 49) references non-existent `TptVehicleServiceRequestController@toggleStatus` | Route: `POST /vehicle-service-request/{vehicle}/toggle-status` maps to a method that does NOT exist in the controller. Calling this URL produces 500 error: "Method [toggleStatus] does not exist." | `routes/web.php:49`, `TptVehicleServiceRequestController.php` (no toggleStatus method) |
| BC-BIZ-DEEP-12 | `VehicleMgmtController@dailyInspectionQuery` line 88 uses `is_active` column — WRONG | [Query/Code Removed] | `VehicleMgmtController.php:88`, `TptDailyVehicleInspection.php` fillable (no `is_active`) |
| BC-BIZ-DEEP-13 | `TptDailyVehicleInspectionController@updateStatus` line 231 sets `$inspection->status` — WRONG column | `$inspection->status = $request->status` — but the DB column is `inspection_status` (line 53 of model $fillable). Setting `status` attribute does not persist to `inspection_status` column. Silent failure — status update appears to succeed but DB is unchanged. | `TptDailyVehicleInspectionController.php:231`, `TptDailyVehicleInspection.php:53` |
| BC-BIZ-DEEP-14 | [Query/Code Removed] | If this dead code were ever activated (by adding a route), multiple approvals of the same service request would create DUPLICATE maintenance entries. | `VehicleMgmtController.php:181` |
| BC-BIZ-DEEP-15 | Approval tab filter reset button uses `href="#"` — broken | Line 31 of approval.blade.php: `<a href="#" class="btn btn-secondary btn-sm" title="Reset Filters">`. Clicking does nothing. Should link to `route('transport.vehicle-mgmt.index', ['tab' => 'approval'])`. | `approval.blade.php:31` |
| BC-BIZ-DEEP-16 | Blade `x-backend.tab.filter-bar` not `x-backend.tab.search-bar` | The approval blade uses `<x-backend.tab.filter-bar>` at line 7. The gold-standard crud-patterns.md specifies `<x-backend.tab.search-bar>`. Different component name — verify if both exist. | `approval.blade.php:7` |

### 5.5 Model Relationships

No dedicated model. See individual entity TC_List files for each model's relationships.

### 5.6 Referential Integrity

See individual entity TC_List files for each entity's referential integrity constraints.

---

## 5.7 Controller Code Trace (CODE-TRACE)

### 5.7.1 VehicleMgmtController (`VehicleMgmtController.php` — 346 lines)

| Method | Lines | Route | Gate | Validation | activityLog | Key Logic | Status |
|--------|-------|-------|------|------------|-------------|-----------|--------|
| `index()` | 27-65 | `GET /vehicle-mgmt` (Route::resource) | ✅ `tenant.transport.viewAny` (line 29) | ❌ NONE | ❌ NONE | Loads 7 paginated datasets + `getDetailedPendingData()`; passes `$pendingData` to view | ✅ Active |
| `dailyInspectionQuery()` | 67-92 | (private — no route) | N/A (private) | N/A | N/A | ✅ `with(['vehicle','driver'])` search by vehicle/driver. ⚠️ **BUG line 88**: `where('is_active', $request->status)` — column `is_active` does not exist in `tpt_daily_vehicle_inspection` | ⚠️ Bug — wrong column |
| `fuelEntryQuery()` | 97-119 | (private — no route) | N/A (private) | N/A | N/A | ✅ Uses `status` column (exists in fillable). Search by vehicle/driver. | ✅ Correct |
| `vehicleServiceRequestQuery()` | 124-154 | (private — no route) | N/A (private) | N/A | N/A | ✅ `with(['inspection.vehicle','inspection.driver','inspection.inspector','approvedBy'])`. Filters by `approval_status`, searches by reason/vehicle/driver. Ends with `latest()`. | ✅ Correct |
| [Query/Code Removed] | 160-193 | [Query/Code Removed] | ❌ MISSING (line 160) | ✅ Inline (lines 162-164): required, in:Approved,Rejected | ❌ MISSING | [Query/Code Removed] | [Query/Code Removed] |
| `storeStatus()` | 198-236 | ❌ **NO ROUTE** — Route::resource does NOT create POST to this method name | ❌ MISSING (line 198) | ✅ Inline (lines 201-208): 6 fields validated | ❌ MISSING | Field-by-field assignment (not mass-assignment). Wrapped in try-catch. Returns `redirect()->back()`. | ⚠️ Dead code — no route; missing Gate; missing activityLog |
| `vehicleMaintenanceQuery()` | 239-309 | (private — no route) | N/A (private) | N/A | N/A | Complex query with 8 filter types: search, status, request_status, date_range, approved_by, vehicle_type, cost_min, cost_max. | ✅ Correct |
| `getDetailedPendingData()` | 318-345 | (private — no route) | N/A (private) | N/A | N/A | Returns array of 4 scoped queries (fuel, inspection, service_request, maintenance). All `->take(10)`. Uses `TptVehicleServiceRequest::pending()` scope. | ⚠️ Dead data — computed but never rendered in blade |

### 5.7.2 TptVehicleServiceRequestController (`TptVehicleServiceRequestController.php` — 308 lines)

| Method | Lines | Route | Gate | Validation | activityLog | Key Logic | Status |
|--------|-------|-------|------|------------|-------------|-----------|--------|
| `index()` | 18-31 | `GET /vehicle-service-request` (Route::resource) | ✅ `tenant.vehicle-service-request.viewAny` (line 20) | ❌ NONE | ❌ NONE | `with(['vehicleInspection','approvedBy','vehicleMaintenance'])`, `latest()`, `paginate(20)`. Uses separate view from approval partial. | ✅ Active |
| `create()` | 36-46 | `GET /vehicle-service-request/create` | ✅ `tenant.vehicle-service-request.create` (line 38) | ❌ NONE | ❌ NONE | Loads all inspections for dropdown. | ✅ Active |
| [Query/Code Removed] | 51-85 | `POST /vehicle-service-request` | ✅ `tenant.vehicle-service-request.create` (line 53) | ❌ NONE (no FormRequest, no inline) | ✅ `activityLog($serviceRequest, 'Created', ...)` (lines 71-73) | [Query/Code Removed] | ✅ Active |
| `show()` | 90-105 | `GET /vehicle-service-request/{id}` | ✅ `tenant.vehicle-service-request.view` (line 92) | ❌ NONE | ❌ NONE | `with(['vehicleInspection','approvedBy','vehicleMaintenance'])→findOrFail($id)`. | ✅ Active |
| `edit()` | 110-121 | `GET /vehicle-service-request/{id}/edit` | ✅ `tenant.vehicle-service-request.update` (line 112) | ❌ NONE | ❌ NONE | Loads single service request + all inspections. | ✅ Active |
| `update()` | 126-160 | `PUT /vehicle-service-request/{id}` | ✅ `tenant.vehicle-service-request.update` (line 128) | ✅ Inline (lines 131-137): 5 fields validated. `exists:tpt_daily_vehicle_inspection,id` (singular — correct). `reason: max:512`. | ✅ `activityLog($serviceRequest, 'Updated', ...)` (lines 152-154) | Does NOT update approval_status, approved_by, approved_at — only basic details. | ✅ Active |
| `updateStatus()` (APPROVAL) | 165-229 | `POST /vehicle-service-request/{id}/update-status` (web.php:45) | ✅ `tenant.vehicle-service-approval.approve` (line 167) | ✅ Inline (lines 169-171): `request_approval_status` required, in:Approved,Rejected | ✅ For Approved (lines 198-200): "Service request approved & maintenance initiated". For Rejected (lines 211-213): "Service request rejected". | Uses `firstOrCreate()` (line 187-196) — prevents duplicate maintenance. JSON response with `maintenance_id`. Wrapped in try-catch (500 on failure). This is the ACTIVE approval endpoint. | ✅ Active — correct |
| `destroy()` | 234-248 | `DELETE /vehicle-service-request/{id}` | ✅ `tenant.vehicle-service-request.delete` (line 236) | ❌ NONE | ✅ `activityLog($serviceRequest, 'Deleted', ...)` (lines 241-243) | Soft delete via model's SoftDeletes trait. Redirects to vehicle-mgmt hub. | ✅ Active |
| `trashed()` | 253-265 | `GET /vehicle-service-request/trash/view` (web.php:46) | ✅ `tenant.vehicle-service-request.restore` (line 255) | ❌ NONE | ❌ NONE | `onlyTrashed()`, `latest('deleted_at')`, `paginate(20)`. | ✅ Active |
| `restore()` | 270-286 | `GET /vehicle-service-request/{id}/restore` (web.php:47) | ✅ `tenant.vehicle-service-request.restore` (line 272) | ❌ NONE | ✅ `activityLog($serviceRequest, 'Restored', ...)` (lines 279-281) | Restores, redirects to vehicle-mgmt hub. | ✅ Active |
| `forceDelete()` | 291-307 | `DELETE /vehicle-service-request/{id}/force-delete` (web.php:48) | ✅ `tenant.vehicle-service-request.forceDelete` (line 293) | ❌ NONE | ✅ `activityLog($serviceRequest, 'Force Deleted', ...)` (lines 300-302) | Permanently removes record. | ✅ Active |
| `toggleStatus()` | ❌ **NOT IMPLEMENTED** | `POST /vehicle-service-request/{vehicle}/toggle-status` (web.php:49) | ❌ Method does not exist in controller | ❌ N/A | ❌ N/A | **Route defined but controller method missing** — calling this URL causes `BadMethodCallException: Method [toggleStatus] does not exist.` | ⚠️ BUG — route with no handler |

### 5.7.3 TptDailyVehicleInspectionController — updateStatus only

| Method | Lines | Route | Gate | Validation | activityLog | Key Logic | Status |
|--------|-------|-------|------|------------|-------------|-----------|--------|
| `updateStatus()` | 226-244 | `POST /daily-vehicle-inspection/{id}/update-status` | ✅ `tenant.daily-vehicle-inspection.approve` (line 228) | ❌ NONE | ✅ `activityLog($inspection, 'StatusUpdated', ...)` (lines 234-237) | ⚠️ **BUG line 231**: `$inspection->status = $request->status` — model column is `inspection_status`, not `status`. Silent failure — status never persists. `$inspection = TptDailyVehicleInspection::where('id',$id)->first()` (uses non-standard `first()` instead of `findOrFail($id)`) | ⚠️ Bug — wrong column name; missing validation; no `findOrFail` |

### 5.7.4 TptVehicleMaintenanceController — update only

| Method | Lines | Route | Gate | Validation | activityLog | Key Logic | Status |
|--------|-------|-------|------|------------|-------------|-----------|--------|
| [Query/Code Removed] | 67-114 | `PUT /vehicle-maintenance/{id}` | ✅ `tenant.vehicle-maintenance.update` (line 69) | ❌ NONE | ❌ **MISSING** — no activityLog call after update | [Query/Code Removed] | ⚠️ Gap — missing activityLog |

---

## 6. Test Case List

### 6.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | Approval Tab Loads Inside Vehicle Mgmt | `/vehicle-mgmt` loads; "Veh. Approval" tab visible; tab-pane shows service requests table with columns: Date, Vehicle, Reason, Status, Approval, Completion, Action | — | — | ⬜ |
| TC-P02 | Pending Service Requests Displayed in Approval Tab | Service requests with `request_approval_status='Pending'` shown with vehicle no, driver name, reason, date, status badge; Approve (green) and Reject (red) buttons active for pending only | — | — | ⬜ |
| TC-P03 | Approve Service Request via AJAX (TptVehicleServiceRequestController@updateStatus) | Click Approve → Swal confirmation → POST `/vehicle-service-request/{id}/update-status` → status becomes 'Approved' → `TptVehicleMaintenance::firstOrCreate()` creates maintenance entry → badge turns green → buttons disabled → page reload | — | — | ⬜ |
| TC-P04 | Reject Service Request via AJAX | Click Reject → Swal confirmation → POST → status becomes 'Rejected' → badge turns red → buttons disabled → page reload; NO maintenance entry created | — | — | ⬜ |
| TC-P05 | View Service Request Modal | Click eye icon → modal shows vehicle, driver, request date, vehicle status, approval status, completion date, reason | — | — | ⬜ |
| TC-P06 | Already Approved/Rejected Requests Show Disabled Buttons | If `request_approval_status ≠ 'Pending'`, approve/reject buttons are `disabled` with `btn-outline-secondary` | — | — | ⬜ |
| TC-P07 | Empty State — No Pending Service Requests | Table shows "No Records Found" message across all 7 columns | — | — | ⬜ |
| TC-P08 | Approval Status Filter | Select "Approved" from filter dropdown → only approved requests shown. Select "Rejected" → only rejected. Select "All" or "Pending" → pending returned | — | — | ⬜ |
| TC-P09 | Search Filter in Approval Tab | Type in search box → filters by reason, vehicle_no, or driver name | — | — | ⬜ |
| TC-P10 | Pagination in Approval Tab | More than 10 service requests → pagination links appear below table; page through requests | — | — | ⬜ |

### 6.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | updateStatus — Invalid request_approval_status | POST with status='Invalid' → 422 validation error: "The selected request approval status is invalid." | — | — | ⬜ |
| TC-N02 | updateStatus — Non-existent service request ID | POST with invalid `{id}` → 404 ModelNotFoundException | — | — | ⬜ |
| TC-N03 | Permission 403 — No tenant.transport.viewAny | GET `/vehicle-mgmt` → 403; entire Vehicle Mgmt page hidden | — | — | ⬜ |
| TC-N04 | Permission 403 — No tenant.vehicle-service-approval.approve | User with `transport.viewAny` but without `vehicle-service-approval.approve` can see approval tab but cannot approve/reject (AJAX returns 403) | — | — | ⬜ |
| TC-N05 | Permission 403 — No tenant.vehicle-service-approval.view | User without `vehicle-service-approval.view` sees table rows but NO action buttons (view/approve/reject hidden) | — | — | ⬜ |
| TC-N06 | Guest Access Redirect | Without auth, `/vehicle-mgmt` redirects to `/login` | — | — | ⬜ |
| TC-N07 | AJAX — Missing CSRF Token | POST updateStatus without `_token` → 419 CSRF mismatch | — | — | ⬜ |
| TC-N08 | Already Approved — Second Approval Attempt | After request is Approved, approve button is disabled; AJAX not callable | — | — | ⬜ |
| TC-N09 | Soft-Deleted Service Request Not Visible | Soft-deleted request with `request_approval_status='Pending'` does NOT appear in approval tab | — | — | ⬜ |
| TC-N10 | Permission 403 — No tenant.vehicle-fuel.approve | Fuel Log tab's inline approve (not Approval tab) returns 403 | — | — | ⬜ |
| TC-N11 | Permission 403 — No tenant.daily-vehicle-inspection.approve | Inspection tab's inline approve (not Approval tab) returns 403 | — | — | ⬜ |

### 6.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|----------------|---------|---------|--------|
| TC-D01 | A | Approve Service Request Creates Maintenance (TptVehicleServiceRequestController) | `TptVehicleMaintenance::firstOrCreate()` creates maintenance entry. **NO duplicate risk** due to `firstOrCreate` | — | — | ⬜ |
| TC-D02 | B | Pending Count Accuracy — Approved Request Disappears | After approving via AJAX, page reloads → request no longer shown in approval tab (status ≠ 'Pending') | — | — | ⬜ |
| TC-D03 | C | Pending Count Accuracy — Rejected Request Disappears | After rejecting via AJAX, page reloads → request no longer shown in approval tab | — | — | ⬜ |
| TC-D04 | D | Approval Status Filter Affects Results | Select 'Approved' → no pending requests shown; only approved ones | — | — | ⬜ |
| TC-D05 | E | Soft-Delete Cascade Check | Soft-deleting a service request does NOT affect maintenance entries (no cascade) — maintenance remains | — | — | ⬜ |
| TC-D06 | F | Maintenance Created After Approval Has Correct vehicle_service_request_id | `TptVehicleMaintenance.vehicle_service_request_id` matches the approved `TptVehicleServiceRequest.id` | — | — | ⬜ |
| TC-D07 | G | Dead Code Confirmation — VehicleMgmtController@updateStatus | Verify NO route exists for `POST /vehicle-mgmt/{id}` or `PUT /vehicle-mgmt/{id}` that maps to updateStatus | — | — | ⬜ |
| TC-D08 | H | Dead Code Confirmation — getDetailedPendingData Never Used | Search blade files for `$pendingData` — should only appear in controller, never in any blade template | — | — | ⬜ |

### 6.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|-----------------|---------|---------|--------|
| TC-CR01 | CR | P1 | VehicleMgmtController@updateStatus (line 160) — DEAD CODE, No Route | Method exists but NO route registered in `routes/web.php`. `Route::resource('vehicle-mgmt', ...)` does NOT create `POST /vehicle-mgmt/{id}`. This method is unreachable. | — | — | ◌ |
| TC-CR02 | CR | P1 | VehicleMgmtController@storeStatus (line 198) — DEAD CODE, No Route | Same as CR01 — NO route registered. `Route::resource` does not create `POST /vehicle-mgmt` with ID parameter. Method is unreachable. | — | — | ◌ |
| TC-CR03 | CR | P1 | VehicleMgmtController@updateStatus — No Permission Gate | Dead code, but if it were reachable: NO `Gate::authorize()` call. Anyone with `tenant.transport.viewAny` could approve/reject. | — | — | ◌ |
| TC-CR04 | CR | P1 | VehicleMgmtController@storeStatus — No Permission Gate | Dead code, but if reachable: NO `Gate::authorize()` call. No access control on manual service request creation. | — | — | ◌ |
| TC-CR05 | CR | P1 | [Query/Code Removed] | [Query/Code Removed] | — | — | ◌ |
| TC-CR06 | CR | P1 | VehicleMgmtController@storeStatus — Wrong Table Name (dead code) | Line 207: `exists:tpt_daily_vehicle_inspections,id` — table name typo with trailing 's'. Dead code, so no runtime impact. Active `TptVehicleServiceRequestController@update` correctly uses `tpt_daily_vehicle_inspection` (singular). | — | — | ◌ |
| TC-CR07 | CR | P1 | VehicleMgmtController@dailyInspectionQuery — Non-Existent `is_active` Filter | [Query/Code Removed] | — | — | ◌ |
| TC-CR08 | CR | P1 | VehicleMgmtController@storeStatus — No Activity Log (dead code) | Dead code, but line 232: no activityLog call after save. Active `TptVehicleServiceRequestController@store` correctly calls activityLog. | — | — | ◌ |
| TC-CR09 | CR | P1 | VehicleMgmtController@updateStatus — No Activity Log (dead code) | Dead code, but line 192: no activityLog after approval/rejection. Active code in TptVehicleServiceRequestController calls activityLog for both Approved and Rejected. | — | — | ◌ |
| TC-CR10 | CR | P1 | $pendingData — Computed but Never Rendered | `VehicleMgmtController@index` calls `getDetailedPendingData()` (fuel, inspection, service_request, maintenance pending) but approval blade only uses `$serviceRequests`. `$pendingData` variable loaded in view but NEVER referenced in any blade. Dead code. | — | — | ◌ |
| TC-CR11 | CR | P1 | TptDailyVehicleInspectionController@updateStatus — Wrong Column Name | Line 231: `$inspection->status = $request->status` — model has `inspection_status` column in fillable but code sets `status`. This silently fails to persist the status update. | — | — | ◌ |
| TC-CR12 | CR | P1 | TptVehicleServiceRequestController@updateStatus — Correct `firstOrCreate` | Active approval endpoint uses `TptVehicleMaintenance::firstOrCreate(['vehicle_service_request_id' => $id], [...])` — prevents duplicate maintenance. ✅ | — | — | ◌ |
| TC-CR13 | CR | P1 | Blade — Action Column Permission Mismatch | Approval blade uses `@can('tenant.vehicle-service-approval.view')` for action buttons but controller gate checks `tenant.vehicle-service-approval.approve`. User with `view` but not `approve` sees buttons that will 403 on AJAX call. | — | — | ◌ |
| TC-CR14 | CR | P1 | TptVehicleMaintenanceController@update — No Activity Log | Lines 67-113: `update()` method does NOT call `activityLog()`. Unlike all other Transport entity controllers, maintenance update silently succeeds without audit trail. | — | — | ◌ |
| TC-CR15 | CR | P2 | Approval Tab Filter URL — Reset Button Broken | Line 31 of approval.blade.php: Reset filter link is `href="#"` — does nothing on click. Should be `href="{{ route('transport.vehicle-mgmt.index', ['tab' => 'approval']) }}"`. | — | — | ◌ |
| TC-CR16 | CR | P1 | toggleStatus Route Has No Controller Method | Web.php line 49 registers `POST /vehicle-service-request/{vehicle}/toggle-status` mapping to `TptVehicleServiceRequestController@toggleStatus` — but this method does NOT exist in the controller. Calling the route causes `BadMethodCallException`. | — | — | ◌ |
| TC-CR17 | CR | P2 | @canany with Single Permission String | Approval.blade.php line 49: `@canany(['tenant.vehicle-service-approval.view'])` — single permission in `@canany` array. Per coding conventions this should be `@can('tenant.vehicle-service-approval.view')` / `@endcan`. | — | — | ◌ |
| TC-CR18 | CR | P2 | Blade Uses `x-backend.tab.filter-bar` Instead of `x-backend.tab.search-bar` | Line 7 of approval.blade.php uses `<x-backend.tab.filter-bar>`. The gold-standard CRUD pattern specifies `<x-backend.tab.search-bar>`. Verify component exists. | — | — | ◌ |
| TC-CR19 | CR | P2 | TptDailyVehicleInspectionController@updateStatus — Uses `first()` Not `findOrFail()` | Line 230: `TptDailyVehicleInspection::where('id',$id)->first()` — returns null silently if ID not found, leading to `Call to member function save() on null`. Should use `findOrFail($id)`. | — | — | ◌ |
| TC-CR20 | CR | P2 | `tenant.vehicle-service-approval.reject` Permission Never Gated | The policy defines `reject()` method (line 46-48) but the controller's `updateStatus()` uses a single gate for both approve/reject. The `reject` permission exists in the policy but no controller or blade ever checks it. | — | — | ◌ |

---

## 7. Detailed Test Steps

### TC-P01: Approval Tab Loads Inside Vehicle Mgmt

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin | Dashboard loads |
| 2 | Navigate to Vehicle Management | URL: `/vehicle-mgmt`; 5-tab layout visible (Fuel Log, Inspection, Service Log, Veh. Approval, Veh. Maintenance) |
| 3 | Click "Veh. Approval" tab | Tab-pane visible with service request table |
| 4 | Check table columns | Columns: Date, Vehicle (with driver), Reason, Status, Approval, Completion, Action |
| 5 | Action column has view/approve/reject buttons | Eye icon for view; green check for Approve; red X for Reject |

### TC-P02: Pending Service Requests Displayed in Approval Tab

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create service request with `request_approval_status='Pending'` via POST to `/vehicle-service-request` | Request created with default Pending status |
| 2 | Navigate to `/vehicle-mgmt?tab=approval` | Approval tab shows the pending request |
| 3 | Verify vehicle info | Vehicle number displayed with "Driver: [name]" below |
| 4 | Verify reason column | Reason text shown (truncated at 40 chars with title attribute for full text) |
| 5 | Verify status badge | Badge shows "Pending" with `bg-warning` class |
| 6 | Approve button visible | Green `btn-outline-success` check button active (not disabled) |
| 7 | Reject button visible | Red `btn-outline-danger` X button active (not disabled) |

### TC-P03: Approve Service Request via AJAX

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create service request with `request_approval_status='Pending'` | Request visible in approval tab |
| 2 | Click green Approve button on the row | Swal.fire confirmation dialog: "Approved this request?" |
| 3 | Click "Yes, Approved" | AJAX POST to `/vehicle-service-request/{id}/update-status` with `request_approval_status=Approved` |
| 4 | Check response | JSON `{success: true, status: 'Approved', maintenance_id: N}` |
| 5 | Check maintenance table | `TptVehicleMaintenance` created with `vehicle_service_request_id` matching, status='Pending', maintenance_type='General Service', cost=0, remarks=service request reason |
| 6 | Verify no duplicate | Click Approve again on same request → button is disabled (no second maintenance entry; `firstOrCreate` prevents this) |
| 7 | Page reloads after 1.5s | Request no longer visible in approval tab (status ≠ 'Pending') |

### TC-P04: Reject Service Request via AJAX

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create service request with `request_approval_status='Pending'` | Request visible in approval tab |
| 2 | Click red Reject button on the row | Swal.fire confirmation dialog: "Rejected this request?" with warning icon |
| 3 | Click "Yes, Rejected" | AJAX POST to `/vehicle-service-request/{id}/update-status` with `request_approval_status=Rejected` |
| 4 | Check response | JSON `{success: true, status: 'Rejected'}` — no `maintenance_id` field |
| 5 | Verify DB — maintenance NOT created | `TptVehicleMaintenance` table has NO entry with this `vehicle_service_request_id` |
| 6 | Verify activity log | `activityLog` entry: "Service request rejected" |
| 7 | Page reloads after 1.5s | Request no longer visible in approval tab |
| 8 | Filter by "Rejected" | The rejected request appears with `bg-danger` badge |

### TC-P05: View Service Request Modal

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to approval tab with pending service request | Table row visible |
| 2 | Click eye icon (view button) | Modal appears with id `#serviceModal` |
| 3 | Verify modal fields | Vehicle, Driver, Request Date (DD-MM-YYYY), Vehicle Status, Approval Status, Completion Date, Reason all populated |
| 4 | Verify formatting | Dates formatted as `DD-MM-YYYY` via JavaScript `formatDate()` function |
| 5 | Close modal | Click Close or X button → modal hides |

### TC-P06: Already Approved/Rejected Requests Show Disabled Buttons

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create service request, approve it | Status = 'Approved' |
| 2 | Refresh page or wait for reload | Request still visible if filter is "All" |
| 3 | Inspect action buttons | Approve button: `btn-outline-secondary`, `disabled` attribute present |
| 4 | Inspect reject button | Reject button: `btn-outline-secondary`, `disabled` attribute present |
| 5 | Try clicking disabled button | No AJAX call fired; button does not respond |
| 6 | Repeat for Rejected status | Same behavior — both buttons disabled |

### TC-P07: Empty State — No Pending Service Requests

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure no service requests exist with `request_approval_status='Pending'` | Database has 0 pending records |
| 2 | Navigate to approval tab | Table shows single row with text "No Records Found" spanning all 7 columns |

### TC-P08: Approval Status Filter

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Have mix of Pending, Approved, Rejected requests | At least 1 of each status |
| 2 | Select "Approved" from filter dropdown | Only approved requests shown (not pending or rejected) |
| 3 | Select "Rejected" | Only rejected requests shown |
| 4 | Select "Pending" | Only pending requests shown |
| 5 | Select "All Status" | All requests shown regardless of status |
| 6 | Verify filter query param | URL contains `?approval_status=Approved` (or selected value) |
| 7 | Verify pagination works with filter | Switching pages preserves `approval_status` param |

### TC-P09: Search Filter in Approval Tab

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Have pending request with specific reason | e.g. reason = "Engine overheating" |
| 2 | Type "Engine" in search box, click Filter | Request with matching reason appears |
| 3 | Type vehicle registration number | Matching vehicle's service requests shown |
| 4 | Type driver name | Matching driver's service requests shown |
| 5 | Type non-existent text | "No Records Found" |
| 6 | Verify search persistence after page reload | Search term preserved in input field |

### TC-P10: Pagination in Approval Tab

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 11+ pending service requests | More than 1 page of results (page size = 10) |
| 2 | Navigate to approval tab | Pagination links visible below table within `<div class="d-flex justify-content-center">` |
| 3 | Click page 2 | Page 2 loads with remaining requests |
| 4 | Apply status filter + navigate pages | Filter persists across pagination (`->appends([...])`) |
| 5 | Verify correct page count | Total pages = ceil(count/10) |

### TC-N01: updateStatus — Invalid request_approval_status

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open browser DevTools → Network tab | Ready to capture XHR |
| 2 | Send direct AJAX POST to `/vehicle-service-request/{id}/update-status` with `request_approval_status=Invalid` | HTTP 422 response |
| 3 | Check response body | JSON with validation errors: "The selected request approval status is invalid." |
| 4 | Verify DB unchanged | `request_approval_status` remains unchanged in database |

### TC-N02: updateStatus — Non-existent Service Request ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST to `/vehicle-service-request/99999/update-status` with valid `request_approval_status` | HTTP 404 |
| 2 | Check error type | `ModelNotFoundException` — "No query results for model [TptVehicleServiceRequest] 99999" |

### TC-N03: Permission 403 — No tenant.transport.viewAny

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Assign user a role WITHOUT `tenant.transport.viewAny` | User lacks Transport module access |
| 2 | User navigates to `/vehicle-mgmt` | HTTP 403 Forbidden |
| 3 | User cannot access any tab | No tab content renders |

### TC-N04: Permission 403 — No tenant.vehicle-service-approval.approve

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User has `tenant.transport.viewAny` but NOT `tenant.vehicle-service-approval.approve` | User sees approval tab with table rows |
| 2 | User sees action buttons | If user has `tenant.vehicle-service-approval.view`, buttons visible (TC-N05 if not) |
| 3 | Attempt Approve/Reject via AJAX | HTTP 403 Forbidden from `Gate::authorize()` at `TptVehicleServiceRequestController.php:167` |
| 4 | Verify Gate check | `AuthorizationException` thrown before any DB write |

### TC-N05: Permission 403 — No tenant.vehicle-service-approval.view

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User has `tenant.transport.viewAny` but NOT `tenant.vehicle-service-approval.view` | User sees approval tab |
| 2 | Check table rows | Vehicle, Reason, Status, Approval, Completion columns visible |
| 3 | Check Action column | Action column header and ALL buttons are hidden (wrapped in `@can('tenant.vehicle-service-approval.view')`) |
| 4 | Verify view modal not accessible | No eye icon to click |
| 5 | Verify no approve/reject | Neither approve nor reject buttons rendered |

### TC-N06: Guest Access Redirect

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Logout or clear session | Not authenticated |
| 2 | Navigate to `/vehicle-mgmt` | Redirected to `/login` |
| 3 | Authenticate | After login, redirected back to `/vehicle-mgmt` |

### TC-N07: AJAX — Missing CSRF Token

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Intercept AJAX request and remove `_token` field | Request sent without CSRF token |
| 2 | POST to `/vehicle-service-request/{id}/update-status` | HTTP 419 Page Expired |
| 3 | Verify no DB changes | Status not updated |

### TC-N08: Already Approved — Second Approval Attempt

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Approve a service request | Status = 'Approved' |
| 2 | Check approve button state | Button is disabled with `btn-outline-secondary` CSS class (approval.blade.php:142-144) |
| 3 | Try clicking disabled button via JS: `$('.approve-btn:first').click()` | No AJAX call — button is inert due to `disabled` HTML attribute |
| 4 | Manually send AJAX via browser console | If forced, controller processes it but `firstOrCreate` prevents duplicate maintenance |

### TC-N09: Soft-Deleted Service Request Not Visible

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete a service request with `request_approval_status='Pending'` | `deleted_at` set (not null); record in `onlyTrashed()` scope |
| 2 | Navigate to approval tab | Deleted request NOT shown in pending list |
| 3 | Verify query | `VehicleMgmtController@vehicleServiceRequestQuery()` does NOT include `withTrashed()` — only non-deleted records appear |

### TC-N10: Permission 403 — No tenant.vehicle-fuel.approve

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User with `tenant.vehicle-fuel.viewAny` but NOT `tenant.vehicle-fuel.approve` | User sees Fuel Log tab |
| 2 | Attempt inline approve via Fuel tab's status update | HTTP 403 |
| 3 | Verify this does not affect Approval tab | Approval tab's approve works independently (separate Gate: `tenant.vehicle-service-approval.approve`) |

### TC-N11: Permission 403 — No tenant.daily-vehicle-inspection.approve

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User with `tenant.daily-vehicle-inspection.viewAny` but NOT `tenant.daily-vehicle-inspection.approve` | User sees Inspection tab |
| 2 | Attempt inline approve via Inspection tab's status update | HTTP 403 |
| 3 | Verify approval tab unaffected | Approval tab uses separate permission |

### TC-D01: Approve Service Request Creates Maintenance

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Capture `$serviceRequest->id` before approval | Note the ID |
| 2 | Approve the request | JSON response includes `maintenance_id` |
| 3 | Query `tpt_vehicle_maintenance` where `vehicle_service_request_id` matches | Exactly 1 record found |
| 4 | Verify maintenance fields | `status='Pending'`, `maintenance_type='General Service'`, `cost=0.00`, `remarks` matches reason |
| 5 | Try same approval again | `firstOrCreate` returns existing maintenance — no duplicate |

### TC-D02: Pending Count — Approved Request Disappears

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Count pending requests on page load | N records shown |
| 2 | Approve one request | AJAX success → 1.5s reload |
| 3 | After reload, count pending requests | N-1 records (approved one no longer pending) |
| 4 | Filter by "Approved" | The just-approved request visible with `bg-success` badge |

### TC-D03: Pending Count — Rejected Request Disappears

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Count pending requests | M records |
| 2 | Reject one request | AJAX success → 1.5s reload |
| 3 | After reload | M-1 pending records |
| 4 | Filter by "Rejected" | Rejected request visible with `bg-danger` badge |

### TC-D04: Approval Status Filter Affects Results

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 2 Pending, 2 Approved, 2 Rejected requests | 6 total records |
| 2 | Filter "Pending" | 2 records shown |
| 3 | Filter "Approved" | 2 records shown |
| 4 | Filter "Rejected" | 2 records shown |
| 5 | Filter "All Status" | All 6 records shown |

### TC-D05: Soft-Delete Cascade Check

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create service request → approve it → maintenance entry exists | `TptVehicleMaintenance` linked to service request |
| 2 | Soft-delete the service request via DELETE `/vehicle-service-request/{id}` | `deleted_at` set on service request |
| 3 | Query maintenance table | Maintenance record still exists — no cascade delete |
| 4 | Verify maintenance can be accessed | `TptVehicleMaintenance::find($maintenanceId)` returns record |

### TC-D06: Maintenance vehicle_service_request_id Match

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Note `$serviceRequest->id` before approval | e.g. ID = 42 |
| 2 | Approve | `TptVehicleMaintenance::firstOrCreate(['vehicle_service_request_id' => 42], [...])` |
| 3 | Check maintenance record | `vehicle_service_request_id` = 42, linking back correctly |

### TC-D07: Dead Code — VehicleMgmtController@updateStatus No Route

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `routes/web.php` for `vehicle-mgmt` routes | Only `Route::resource('vehicle-mgmt', VehicleMgmtController::class)` at line 43 |
| 2 | List all routes created by Route::resource | `GET/HEAD /vehicle-mgmt`, `POST /vehicle-mgmt`, `GET /vehicle-mgmt/{id}`, `GET /vehicle-mgmt/{id}/edit`, `PUT/PATCH /vehicle-mgmt/{id}`, `DELETE /vehicle-mgmt/{id}`, `GET /vehicle-mgmt/create` |
| 3 | Verify no route maps to `updateStatus` | No POST/PUT route maps to `updateStatus` method |
| 4 | Run `php artisan route:list | findstr vehicle-mgmt` | Confirm only 7 resource routes, no `updateStatus` |

### TC-D08: Dead Code — getDetailedPendingData Never Used

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Search all `transport::` blade files for `$pendingData` | No blade file references `$pendingData` |
| 2 | Grep `resources/views` in Transport module | `$pendingData` appears ONLY in `VehicleMgmtController.php` |
| 3 | Verify compact() call | Line 63: `'pendingData'` passed to view, but blade never uses it |
| 4 | Check all 5 tab partials | None reference `$pendingData` |

### TC-CR01: VehicleMgmtController@updateStatus — Dead Code Confirmation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Read `VehicleMgmtController.php` lines 160-193 | Method `updateStatus()` exists with approval/rejection logic |
| 2 | Read `routes/web.php` | `Route::resource('vehicle-mgmt', VehicleMgmtController::class)` at line 43 only |
| 3 | Check for any additional vehicle-mgmt routes | None present — no `POST /vehicle-mgmt/{id}` or named route for `updateStatus` |
| 4 | **Conclusion**: Method is unreachable dead code | Should be removed or route should be added |

### TC-CR02: VehicleMgmtController@storeStatus — Dead Code Confirmation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Read `VehicleMgmtController.php` lines 198-236 | Method `storeStatus()` exists |
| 2 | Verify no route maps to it | Same as CR01 — only `Route::resource` creates routes; no match for `storeStatus` |
| 3 | **Conclusion**: Unreachable dead code | Remove or re-implement |

### TC-CR03: VehicleMgmtController@updateStatus — Missing Permission Gate

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `VehicleMgmtController@updateStatus` lines 160-193 | No `Gate::authorize()` call anywhere in method body |
| 2 | Compare with active `TptVehicleServiceRequestController@updateStatus` line 167 | Active code has `Gate::authorize('tenant.vehicle-service-approval.approve')` |
| 3 | **Bug**: If route were added, any authenticated user could approve/reject | Gate gap |

### TC-CR04: VehicleMgmtController@storeStatus — Missing Permission Gate

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `VehicleMgmtController@storeStatus` lines 198-236 | No `Gate::authorize()` call |
| 2 | **Bug**: If route were added, unauthenticated service requests could be created | Gate gap |

### TC-CR05: VehicleMgmtController@updateStatus — Uses create() Not firstOrCreate()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | [Query/Code Removed] | [Query/Code Removed] |
| 2 | Compare with active code line 187: `TptVehicleMaintenance::firstOrCreate([...])` | Active code prevents duplicates |
| 3 | **Bug**: Dead code would create duplicate maintenance entries if activated | Use `firstOrCreate` instead of `create` |

### TC-CR06: VehicleMgmtController@storeStatus — Wrong Table Name

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Read line 207: `'exists:tpt_daily_vehicle_inspections,id'` | Table name is `tpt_daily_vehicle_inspections` (plural with 's') |
| 2 | Check actual table in model | Model uses `tpt_daily_vehicle_inspection` (singular — `TptDailyVehicleInspection.php:16`) |
| 3 | Compare with active `TptVehicleServiceRequestController@update` line 132 | Active code uses singular: `tpt_daily_vehicle_inspection` ✅ |
| 4 | Since dead code, no runtime impact | Fix if method is ever activated |

### TC-CR07: dailyInspectionQuery — Non-Existent is_active Filter

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | [Query/Code Removed] | [Query/Code Removed] |
| 2 | Check model `TptDailyVehicleInspection` $fillable (lines 26-56) | No `is_active` field; status field is `inspection_status` |
| 3 | Navigate to Inspection tab with status filter | SQL error: `Column not found: 1054 Unknown column 'is_active'` |
| 4 | **BUG confirmed**: Wrong column name | [Query/Code Removed] |

### TC-CR08: VehicleMgmtController@storeStatus — No Activity Log

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `storeStatus()` method (lines 198-236) | After `$serviceRequest->save()` at line 230, no `activityLog()` call |
| 2 | Compare with active `TptVehicleServiceRequestController@store` lines 71-73 | Active code calls `activityLog($serviceRequest, 'Created', [...])` |
| 3 | **Gap**: Dead code missing audit trail | Add activityLog if method is activated |

### TC-CR09: VehicleMgmtController@updateStatus — No Activity Log

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `updateStatus()` lines 160-193 | No `activityLog()` call after approval or rejection |
| 2 | Compare with active `TptVehicleServiceRequestController@updateStatus` | Active code calls `activityLog` for both Approved (line 198) and Rejected (line 211) |
| 3 | **Gap**: Dead code missing audit trail | Add activityLog if method is activated |

### TC-CR10: $pendingData — Dead Code

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `VehicleMgmtController@index()` line 47 | `getDetailedPendingData()` called → result assigned to `$pendingData` |
| 2 | Search all blade files in `transport::` namespace for `$pendingData` | No blade file references `$pendingData` |
| 3 | Inspect `vehiclemgmt.blade.php` | `compact('pendingData')` received but variable never echoed, looped, or passed to any partial |
| 4 | Check all 5 tab partials individually | None use `$pendingData` |
| 5 | **DEAD CODE confirmed**: Fuel/Inspection/ServiceRequest/Maintenance pending data computed but never rendered | Remove `$pendingData` or implement the intended 4-section approval tab |

### TC-CR11: Inspection updateStatus Wrong Column Name

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `TptDailyVehicleInspectionController@updateStatus()` line 231 | `$inspection->status = $request->status` |
| 2 | Check model's `$fillable` array (lines 26-56) | Column is `inspection_status`, NOT `status` |
| 3 | Approve an inspection via Inspection tab | No visible error, but `$inspection->status` sets an unguarded attribute — update does NOT persist to DB |
| 4 | Re-query the inspection from DB | `inspection_status` remains unchanged (still the old value) |
| 5 | **BUG confirmed**: Should be `$inspection->inspection_status = $request->status` | Silent failure — status never actually changes |

### TC-CR12: TptVehicleServiceRequestController@updateStatus — Correct firstOrCreate

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Read `TptVehicleServiceRequestController@updateStatus()` lines 187-196 | `TptVehicleMaintenance::firstOrCreate(['vehicle_service_request_id' => $id], [...])` |
| 2 | Verify `$id` is the service request ID | `$serviceRequest->id` passed correctly |
| 3 | **Confirmed**: Duplicate prevention in place ✅ | No bug |

### TC-CR13: Blade — Action Column Permission Mismatch

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Read `approval.blade.php` line 122 | `@can('tenant.vehicle-service-approval.view')` wraps action buttons |
| 2 | Read `TptVehicleServiceRequestController@updateStatus` line 167 | `Gate::authorize('tenant.vehicle-service-approval.approve')` |
| 3 | Create user with `view` but NOT `approve` | User sees action buttons (view condition met) but AJAX returns 403 (approve gate fails) |
| 4 | **Gap**: User sees buttons they cannot use | Add `@can('tenant.vehicle-service-approval.approve')` check alongside `view` in blade |
| 5 | Note: view button (eye) only needs `view` permission — only approve/reject need `approve` | Consider separating permissions in blade |

### TC-CR14: TptVehicleMaintenanceController@update — No Activity Log

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Read `TptVehicleMaintenanceController@update()` lines 67-114 | Entire method lacks `activityLog()` call |
| 2 | Compare with sibling controllers | `TptVehicleServiceRequestController@update` at line 152 has activityLog. `TptVehicleMaintenanceController@destroy` also has activityLog. |
| 3 | **Gap**: Maintenance update has no audit trail | Add `activityLog($maintenanceData, 'Updated', [...])` after update |
| 4 | Impact: Back-propagation to service request (lines 85-108) also unlogged | Neither maintenance update nor service request update are logged in this flow |

### TC-CR15: Approval Tab Filter URL — Reset Button Broken

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Apply search filter "Engine" + status "Pending" | URL shows `?search=Engine&approval_status=Pending` |
| 2 | Click reset button (circle-arrow icon) | Attached to `<a href="#">` — page scrolls to top, filters NOT cleared |
| 3 | **Bug**: Reset button is non-functional | Fix: `<a href="{{ route('transport.vehicle-mgmt.index', ['tab' => 'approval']) }}"` |

### TC-CR16: toggleStatus Route Has No Controller Method

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Read `routes/web.php` line 49 | `Route::post('/vehicle-service-request/{vehicle}/toggle-status', [TptVehicleServiceRequestController::class, 'toggleStatus'])` |
| 2 | Read `TptVehicleServiceRequestController.php` | No `toggleStatus()` method exists (file is 308 lines, last method is `forceDelete` at line 291) |
| 3 | POST to `/vehicle-service-request/1/toggle-status` | HTTP 500: `BadMethodCallException: Method [toggleStatus] does not exist.` |
| 4 | **Bug**: Route without handler | Either implement controller method or remove route |

### TC-CR17: @canany with Single Permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Read `approval.blade.php` line 49 | `@canany(['tenant.vehicle-service-approval.view'])` — single permission wrapped in array |
| 2 | Per coding conventions | `@canany` is for multiple permissions; `@can` is for single permission |
| 3 | **Code style issue**: Replace with `@can('tenant.vehicle-service-approval.view')` / `@endcan` | Functionally identical but violates convention |

### TC-CR18: Blade Uses `x-backend.tab.filter-bar` Not `x-backend.tab.search-bar`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Read `approval.blade.php` line 7 | `<x-backend.tab.filter-bar>` |
| 2 | Check gold-standard crud-patterns.md | Specifies `<x-backend.tab.search-bar>` |
| 3 | Verify both components exist | If both exist, `filter-bar` may still work. If `filter-bar` is deprecated, it may have missing features |
| 4 | **Note**: Verify component existence | Ensure `filter-bar` is intended or migrate to `search-bar` |

### TC-CR19: TptDailyVehicleInspectionController@updateStatus — Uses first() Not findOrFail()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Read `TptDailyVehicleInspectionController.php` line 230 | `TptDailyVehicleInspection::where('id',$id)->first()` |
| 2 | Compare with standard pattern | All other controllers use `findOrFail($id)` for methods receiving ID parameter |
| 3 | POST to `/daily-vehicle-inspection/99999/update-status` with invalid ID | `first()` returns `null` → line 231 `$inspection->status` throws `Error: Call to a member function save() on null` |
| 4 | **Bug**: Should use `findOrFail($id)` | `first()` returns null without exception |

### TC-CR20: `tenant.vehicle-service-approval.reject` Permission Never Gated

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Read `TransportVehicleServiceApprovalPolicy.php` lines 46-48 | `reject()` method defined checking `tenant.vehicle-service-approval.reject` |
| 2 | Read `TptVehicleServiceRequestController@updateStatus` line 167 | `Gate::authorize('tenant.vehicle-service-approval.approve')` — single gate for both approve AND reject |
| 3 | Search all blade files for `vehicle-service-approval.reject` | Not found in any blade template |
| 4 | **Gap**: `reject` permission key exists in DB/permissions but is never checked by controller or blade | Policy method is unreachable. Consider splitting approve/reject gates if separate permission control is desired. |

---

## 8. Summary Statistics

| Metric | Value |
|--------|-------|
| Total controller methods analyzed | 21 (across 4 controllers) |
| Active methods | 14 |
| Dead methods | 2 (updateStatus, storeStatus in VehicleMgmtController) |
| Missing methods (route exists but no handler) | 1 (toggleStatus in TptVehicleServiceRequestController) |
| Private query methods | 5 (all in VehicleMgmtController) |
| Missing Gate checks (active code) | 0 |
| Missing Gate checks (dead code) | 2 |
| Missing activityLog (active code) | 1 (TptVehicleMaintenanceController@update) |
| Missing activityLog (dead code) | 2 |
| Confirmed bugs (column name errors) | 2 (is_active in dailyInspectionQuery, status in Inspection updateStatus) |
| Dead code entries | 2 methods + 1 unused data variable |
| Code style issues | 3 (@canany single, filter-bar vs search-bar, _method:POST) |
| Routes without handlers | 1 (toggleStatus) |
| Total test cases | 44 (10 positive, 11 negative, 8 dependency, 15 code review) |

---

## 9. Expanded Test Steps — Additional Detail

### TC-P01: Approval Tab Loads Inside Vehicle Mgmt (Expanded)

| Step # | Action | Expected Result | Verified At |
|--------|--------|-----------------|-------------|
| S01 | Login with admin credentials (has all transport permissions) | Dashboard loads; user authenticated | — |
| S02 | Navigate to GET `/vehicle-mgmt` | Page loads with 5-tab nav-tab component | `vehiclemgmt.blade.php:8-14` |
| S03 | Verify tab labels | Fuel Log, Inspection, Service Log, Veh. Approval, Veh. Maintenance | `vehiclemgmt.blade.php:9-13` |
| S04 | Verify each tab has permission key | fuel_log→`tenant.vehicle-fuel.viewAny`, inspection→`tenant.daily-vehicle-inspection.viewAny`, service_log→`tenant.vehicle-service-request.viewAny`, approval→`tenant.vehicle-service-approval.viewAny`, maintenance→`tenant.vehicle-maintenance.viewAny` | `vehiclemgmt.blade.php:9-13` |
| S05 | Click "Veh. Approval" tab | Tab-pane with id `#approval-pane` becomes visible with `active show` classes | `approval.blade.php:2-5` |
| S06 | Check that `x-backend.tab.filter-bar` renders | Search input + status dropdown + filter/reset buttons visible | `approval.blade.php:7-37` |
| S07 | Verify table header columns exist | Date, Vehicle, Reason, Status, Approval, Completion, Action | `approval.blade.php:42-52` |
| S08 | Verify Action column header has permission guard | `@canany(['tenant.vehicle-service-approval.view'])` wraps the `<th>` | `approval.blade.php:49-51` |
| S09 | Open browser DevTools → Network tab | Confirm no AJAX errors on initial load | — |
| S10 | Check console for JS errors | No errors; jQuery `$(document).ready` function loaded successfully | `approval.blade.php:218-361` |

### TC-P02: Pending Service Requests Displayed (Expanded)

| Step # | Action | Expected Result | Verified At |
|--------|--------|-----------------|-------------|
| S01 | Ensure DB has 3 pending service requests with varying vehicle/driver/reason data | At least 3 `TptVehicleServiceRequest` records with `request_approval_status='Pending'` | — |
| S02 | Reload approval tab | 3 rows appear in `<tbody>` | `approval.blade.php:56-157` |
| S03 | Check first row's Vehicle column | `<strong>{{ $vehicleNo }}</strong><br><small>Driver: {{ $driverName }}</small>` | `approval.blade.php:74-76` |
| S04 | Check that `$vehicleNo` comes from `$service->inspection->vehicle->vehicle_no ?? 'N/A'` | Falls back to `'N/A'` if inspection/vehicle missing | `approval.blade.php:67-68` |
| S05 | Check Reason column text | Text truncated to 40 chars with `Str::limit()`; full text in `title` attribute | `approval.blade.php:78-79` |
| S06 | Check Status badge | Shows vehicle status dropdown value with `bg-info` or `bg-secondary` if N/A | `approval.blade.php:82-89` |
| S07 | Check Approval badge | Shows `request_approval_status` with color: Pending→`bg-warning`, Approved→`bg-success`, Rejected→`bg-danger` | `approval.blade.php:92-110` |
| S08 | Check Completion column | Shows `service_completion_date` formatted as `d-m-Y` or "In Progress" text | `approval.blade.php:113-118` |
| S09 | Check Action column for pending row | View (eye icon, `btn-outline-primary`), Approve (check, `btn-outline-success`), Reject (X, `btn-outline-danger`) — all enabled | `approval.blade.php:122-148` |
| S10 | Verify Approve/Reject buttons have `data-id` attribute | `<button class="approve-btn" data-id="{{ $service->id }}">` | `approval.blade.php:133` |
| S11 | Verify View button has `data-service` JSON | `<button class="view-btn" data-service='@json($service)'>` — contains full model data | `approval.blade.php:125` |

### TC-P03: Approve Service Request via AJAX (Expanded)

| Step # | Action | Expected Result | Verified At |
|--------|--------|-----------------|-------------|
| S01 | Create pending service request via POST `/vehicle-service-request` | Record created with `request_approval_status='Pending'` | — |
| S02 | Open Network tab in DevTools | Capture XHR requests | — |
| S03 | Click green Approve button (`btn-outline-success.approve-btn`) | Swal.fire modal: title "Approved this request?", text "This action cannot be undone!", icon `question`, confirm button green (#28a745) | `approval.blade.php:262-274` |
| S04 | Click "Yes, Approved" button in Swal | `confirmAction(id, 'Approved')` called → `updateStatus(id, 'Approved')` fires AJAX | `approval.blade.php:271-273` |
| S05 | Examine AJAX request payload | `url: "transport.vehicle-service-request.updateStatus"` → POST to `/vehicle-service-request/{id}/update-status`. Data: `{_token, request_approval_status: 'Approved', approved_by: auth()->id(), _method: 'POST'}` | `approval.blade.php:283-292` |
| S06 | Verify Gate check on server | `Gate::authorize('tenant.vehicle-service-approval.approve')` at `TptVehicleServiceRequestController.php:167` | `TptVehicleServiceRequestController.php:167` |
| S07 | Verify server-side validation | `$request->validate(['request_approval_status' => 'required|in:Approved,Rejected'])` — value 'Approved' passes | `TptVehicleServiceRequestController.php:169-171` |
| S08 | Verify `findOrFail` retrieves record | `TptVehicleServiceRequest::findOrFail($id)` — throws 404 if invalid | `TptVehicleServiceRequestController.php:175` |
| S09 | Verify DB update | `request_approval_status='Approved'`, `approved_by=auth()->id()`, `approved_at=now()` | `TptVehicleServiceRequestController.php:178-182` |
| S10 | Verify `firstOrCreate` | `TptVehicleMaintenance::firstOrCreate(['vehicle_service_request_id' => $id], [...])` — first param is unique condition | `TptVehicleServiceRequestController.php:187-196` |
| S11 | Verify maintenance defaults | `maintenance_initiation_date=today`, `maintenance_type='General Service'`, `cost=0`, `status='Pending'`, `remarks=serviceRequest->reason` | `TptVehicleServiceRequestController.php:190-195` |
| S12 | Verify activityLog for Approved | `activityLog($serviceRequest, 'Approved', ['message' => 'Service request approved & maintenance initiated'])` | `TptVehicleServiceRequestController.php:198-200` |
| S13 | Inspect JSON response | `{success: true, status: 'Approved', message: 'Request approved and maintenance entry created.', maintenance_id: N}` with HTTP 200 | `TptVehicleServiceRequestController.php:202-207` |
| S14 | Verify JS success handler | Badge updated to green `bg-success` with text "Approved"; approve/reject buttons disabled with `btn-outline-secondary` | `approval.blade.php:297-316` |
| S15 | Verify toast notification | Swal toast fires "Status updated successfully" with `icon: 'success'`, 3s timer | `approval.blade.php:318` |
| S16 | Wait for page reload | `setTimeout(() => location.reload(), 1500)` fires after 1.5s | `approval.blade.php:321-323` |
| S17 | After reload, verify request gone | Pending filter no longer shows this request (status is now 'Approved') | — |
| S18 | Filter by "Approved" | Request visible with green `bg-success` "Approved" badge | — |

### TC-P04: Reject Service Request via AJAX (Expanded)

| Step # | Action | Expected Result | Verified At |
|--------|--------|-----------------|-------------|
| S01 | Create pending service request | Record with `request_approval_status='Pending'` | — |
| S02 | Click red Reject button | Swal modal: title "Rejected this request?", icon `warning`, confirm button red (#dc3545) | `approval.blade.php:262-274` |
| S03 | Click "Yes, Rejected" | AJAX POST same as approve, but with `request_approval_status=Rejected` | `approval.blade.php:257` |
| S04 | Verify Gate check passes | Same gate `tenant.vehicle-service-approval.approve` — does not distinguish approve vs reject | `TptVehicleServiceRequestController.php:167` |
| S05 | Verify validation | `in:Approved,Rejected` — 'Rejected' passes | `TptVehicleServiceRequestController.php:170` |
| S06 | Verify DB update | `request_approval_status='Rejected'`, `approved_by=auth()->id()`, `approved_at=now()` | `TptVehicleServiceRequestController.php:178-182` |
| S07 | Verify NO maintenance created | The `if ($status === 'Approved')` block (line 185) is SKIPPED for Rejected | `TptVehicleServiceRequestController.php:185` |
| S08 | Verify activityLog for Rejected | `activityLog($serviceRequest, 'Rejected', ['message' => 'Service request rejected'])` | `TptVehicleServiceRequestController.php:211-213` |
| S09 | Verify JSON response | `{success: true, status: 'Rejected', message: 'Request has been rejected.'}` — NO `maintenance_id` | `TptVehicleServiceRequestController.php:215-219` |
| S10 | Verify badge updates to red | Badge `bg-danger` with text "Rejected"; buttons disabled | `approval.blade.php:306-315` |
| S11 | Verify page reloads after 1.5s | Same reload timeout as approve | `approval.blade.php:321-323` |
| S12 | After reload, request not shown in pending | Status is now 'Rejected' | — |

### TC-P05: View Service Request Modal (Expanded)

| Step # | Action | Expected Result | Verified At |
|--------|--------|-----------------|-------------|
| S01 | Click eye icon (`btn-outline-primary.view-btn`) | `$(document).on('click', '.view-btn', function() {...})` fires | `approval.blade.php:221` |
| S02 | Examine data attributes | `data-service='@json($service)'` contains full model including relations; `data-vehicle` and `data-driver` separately provided | `approval.blade.php:125-127` |
| S03 | Check request_date formatting | `formatDate(data.request_date)` returns `DD-MM-YYYY` from `new Date(dateString)` | `approval.blade.php:227, 344-360` |
| S04 | Check service_completion_date | If present → formatted as date; if null → displays "In Progress" | `approval.blade.php:228` |
| S05 | Check vehicleStatus extraction | Falls back through: `data.vehicle_status.value` → `data.vehicleStatus.value` → 'N/A' | `approval.blade.php:235-240` |
| S06 | Modal `#serviceModal` appears | Bootstrap modal with backdrop | `approval.blade.php:247` |
| S07 | Verify modal table fields | Vehicle, Driver, Request Date, Vehicle Status, Approval Status, Completion Date, Reason — all populated | `approval.blade.php:178-207` |
| S08 | Click Close | Modal hides via `data-bs-dismiss="modal"` | `approval.blade.php:210` |

### TC-P06: Disabled Buttons for Approved/Rejected (Expanded)

| Step # | Action | Expected Result | Verified At |
|--------|--------|-----------------|-------------|
| S01 | Approve a service request | Status becomes 'Approved' | — |
| S02 | Reload approval tab | Request visible in "All" filter | — |
| S03 | Inspect approve button for that row | `@if($service->request_approval_status == 'Pending')` is false → ELSE renders `btn-outline-secondary disabled` | `approval.blade.php:131-148` |
| S04 | Inspect reject button for that row | Same — both buttons get `disabled` attribute and secondary styling | `approval.blade.php:142-147` |
| S05 | Try JavaScript click on disabled button | `$('.approve-btn:disabled').click()` — no AJAX fired; event handlers not triggered on disabled elements | — |
| S06 | Check view button | View button (`eye` icon) is NOT disabled — it's outside the `@if/@else` block for pending check | `approval.blade.php:124` |
| S07 | Repeat for Rejected request | Same behavior — buttons disabled regardless of which non-pending status | — |

### TC-P07: Empty State (Expanded)

| Step # | Action | Expected Result | Verified At |
|--------|--------|-----------------|-------------|
| S01 | Ensure zero service requests exist | `TptVehicleServiceRequest::count() === 0` | — |
| S02 | Navigate to approval tab | `@forelse($serviceRequests as $service)` at line 56 → no iterations | `approval.blade.php:56` |
| S03 | Verify empty row | `@empty` block renders: `<tr><td colspan="7" class="text-center text-muted">No Records Found</td></tr>` | `approval.blade.php:154-156` |
| S04 | Verify colspan=7 matches all 7 columns | Date, Vehicle, Reason, Status, Approval, Completion, Action — correct count | `approval.blade.php:155` |
| S05 | Ensure no JS errors despite empty table | jQuery event handlers attached to `.view-btn`, `.approve-btn`, `.reject-btn` — none exist but delegated events on `document` don't fail | `approval.blade.php:221, 251, 256` |

### TC-P08: Approval Status Filter (Expanded)

| Step # | Action | Expected Result | Verified At |
|--------|--------|-----------------|-------------|
| S01 | Create 2 Pending, 2 Approved, 2 Rejected requests | 6 total records | — |
| S02 | Select "Pending" from `<select name="approval_status">` | Dropdown value = 'Pending' | `approval.blade.php:19` |
| S03 | Click Filter button | Form submits GET with `?approval_status=Pending` | `approval.blade.php:27-29` |
| S04 | Verify server-side query | `vehicleServiceRequestQuery()` checks `$request->filled('approval_status')` → `where('request_approval_status', $request->approval_status)` | `VehicleMgmtController.php:135-137` |
| S05 | Verify 2 pending rows shown | Only Pending records returned | — |
| S06 | Select "Approved" | `approval_status=Approved` → 2 approved records | — |
| S07 | Select "Rejected" | `approval_status=Rejected` → 2 rejected records | — |
| S08 | Select "All Status" (empty value) | `approval_status` not sent or empty → no WHERE clause → all 6 records shown | `VehicleMgmtController.php:135` |
| S09 | Verify dropdown retains selection after page load | `<option value="Approved" {{ request('approval_status') == 'Approved' ? 'selected' : '' }}>` | `approval.blade.php:20` |

### TC-P09: Search Filter (Expanded)

| Step # | Action | Expected Result | Verified At |
|--------|--------|-----------------|-------------|
| S01 | Create request with reason "Engine overheating", vehicle_no "MH-01-AB-1234", driver "Rajesh" | Record visible in approval tab | — |
| S02 | Type "Engine" in search box | Input field `name="search"` | `approval.blade.php:10-14` |
| S03 | Click Filter | GET with `?search=Engine` | — |
| S04 | Verify server-side search logic | [Query/Code Removed] | `VehicleMgmtController.php:140-151` |
| S05 | Verify matching record shown | "Engine overheating" found in reason | — |
| S06 | Search "MH-01" | [Query/Code Removed] | `VehicleMgmtController.php:144-146` |
| S07 | Search "Rajesh" | Found in `driver.name` via relation | `VehicleMgmtController.php:147-149` |
| S08 | Search "XYZ-NONEXISTENT" | No matches → "No Records Found" | — |
| S09 | Verify search value persists in input after reload | `value="{{ request('search') }}"` retains value | `approval.blade.php:12` |

### TC-P10: Pagination (Expanded)

| Step # | Action | Expected Result | Verified At |
|--------|--------|-----------------|-------------|
| S01 | Create 25 pending service requests | 25 records with `request_approval_status='Pending'` | — |
| S02 | Load approval tab | 10 records shown (page 1 of 3) | `VehicleMgmtController.php:45` (paginate(10)) |
| S03 | Verify pagination links | `{{ $serviceRequests->links() }}` renders Bootstrap pagination | `approval.blade.php:163` |
| S04 | Click page 2 | URL updates to `?page=2` — 10 more records shown | — |
| S05 | Click page 3 | Last 5 records shown | — |
| S06 | Apply filter + go to page 2 | Filter persists: `?approval_status=Approved&page=2` | `VehicleMgmtController.php:45` (withQueryString) |
| S07 | Verify paginator name default | `paginate(10)` — no custom page name (uses default `page`). No conflict with other tabs because `vehicleServiceRequestQuery()` only applies filters when `tab=approval` | `VehicleMgmtController.php:45` |

### TC-N01: Invalid Status (Expanded)

| Step # | Action | Expected Result | Verified At |
|--------|--------|-----------------|-------------|
| S01 | Open browser DevTools Console | Ready to execute JS | — |
| S02 | Execute AJAX: `$.post('/vehicle-service-request/1/update-status', {_token: '...', request_approval_status: 'Invalid'})` | POST request sent | — |
| S03 | Verify HTTP 422 status | Validation failure | `TptVehicleServiceRequestController.php:170` |
| S04 | Verify error message | JSON: `{"message": "The selected request approval status is invalid.", "errors": {"request_approval_status": ["The selected request approval status is invalid."]}}` | Laravel validation format |
| S05 | Verify DB unchanged | `SELECT request_approval_status FROM tpt_vehicle_service_request WHERE id=1` — still original value | — |
| S06 | Test empty status: `request_approval_status: ''` | 422: "The request approval status field is required." | `TptVehicleServiceRequestController.php:170` |
| S07 | Test omitted field: no `request_approval_status` key | 422: same "required" error | — |
| S08 | Test null: `request_approval_status: null` | In JSON payload, null is not a valid string → 422 | — |

### TC-N02: Non-existent ID (Expanded)

| Step # | Action | Expected Result | Verified At |
|--------|--------|-----------------|-------------|
| S01 | POST to `/vehicle-service-request/99999/update-status` with valid status | `findOrFail(99999)` throws `ModelNotFoundException` | `TptVehicleServiceRequestController.php:175` |
| S02 | Verify exception handling | Wrapped in try-catch at line 173: returns JSON `{success: false, message: 'Something went wrong...'}` with HTTP 500 | `TptVehicleServiceRequestController.php:173, 221-228` |
| S03 | Test with string ID: `abc` | `findOrFail('abc')` — MySQL may auto-convert or fail. If auto-converts to 0 → 404. Expect 500 in exception handler. | — |
| S04 | Test with negative ID: `-1` | `findOrFail(-1)` → 404 ModelNotFoundException | — |

### TC-N03: Missing tenant.transport.viewAny (Expanded)

| Step # | Action | Expected Result | Verified At |
|--------|--------|-----------------|-------------|
| S01 | Create user with role that does NOT include `tenant.transport.viewAny` | All transport permissions absent | — |
| S02 | Login as this user | Dashboard loads | — |
| S03 | Manually navigate to `/vehicle-mgmt` | `Gate::authorize('tenant.transport.viewAny')` at `VehicleMgmtController.php:29` → `AuthorizationException` | `VehicleMgmtController.php:29` |
| S04 | Verify HTTP 403 | Laravel converts `AuthorizationException` to 403 response | — |
| S05 | Verify no tab content renders | Even if URL bypasses JS frontend, server returns 403 before any view or data loads | — |
| S06 | Verify no sidebar/dashboard link to transport | Module hidden from navigation (UI-level) | — |

### TC-N04: Missing tenant.vehicle-service-approval.approve (Expanded)

| Step # | Action | Expected Result | Verified At |
|--------|--------|-----------------|-------------|
| S01 | Create user with `tenant.transport.viewAny` + `tenant.vehicle-service-approval.view` but NOT `tenant.vehicle-service-approval.approve` | Can see Vehicle Mgmt and approval tab, can see buttons | — |
| S02 | Navigate to approval tab | Tab loads with pending requests and action buttons | — |
| S03 | Click Approve | AJAX POST to updateStatus | — |
| S04 | Verify server gate | `Gate::authorize('tenant.vehicle-service-approval.approve')` → user lacks permission → 403 | `TptVehicleServiceRequestController.php:167` |
| S05 | Check AJAX error handler | `error: function(xhr, status, error)` → `toast('error', xhr.responseJSON.message)` shows error toast | `approval.blade.php:328-335` |
| S06 | Verify DB NOT updated | `request_approval_status` unchanged (still 'Pending') | — |
| S07 | Same test for Reject | Same gate — same 403 result | — |

### TC-N05: Missing tenant.vehicle-service-approval.view (Expanded)

| Step # | Action | Expected Result | Verified At |
|--------|--------|-----------------|-------------|
| S01 | User has `tenant.transport.viewAny` + `tenant.vehicle-service-approval.approve` but NOT `tenant.vehicle-service-approval.view` | Approval tab visible, action column header hidden, action buttons hidden | — |
| S02 | Navigate to approval tab | Tab-pane visible with table | — |
| S03 | Check Action column header | `<th width="140">Action</th>` is wrapped in `@canany(['tenant.vehicle-service-approval.view'])` — hidden | `approval.blade.php:49-51` |
| S04 | Check Action column body cells | `<td>` with view/approve/reject buttons is wrapped in `@can('tenant.vehicle-service-approval.view')` at line 122 — hidden | `approval.blade.php:122` |
| S05 | Count table columns | Only 6 columns visible (Date, Vehicle, Reason, Status, Approval, Completion) — Action column not rendered | — |
| S06 | User CAN still approve via direct API call | Gate check is on `approve` permission, not `view`. Direct POST with token succeeds. | — |

### TC-N06: Guest Redirect (Expanded)

| Step # | Action | Expected Result | Verified At |
|--------|--------|-----------------|-------------|
| S01 | Clear session cookies / logout | Not authenticated | — |
| S02 | Navigate to `/vehicle-mgmt` | Laravel `auth` middleware redirects to `/login` | — |
| S03 | Verify redirect URL includes intended destination | `/login?intended=/vehicle-mgmt` or `/login?redirect=/vehicle-mgmt` | — |
| S04 | Login with valid credentials | After authentication, redirected back to `/vehicle-mgmt` | — |
| S05 | Logout again, try `/vehicle-service-request/1/update-status` POST | Same redirect to login (web middleware group applies auth) | — |

### TC-N07: Missing CSRF Token (Expanded)

| Step # | Action | Expected Result | Verified At |
|--------|--------|-----------------|-------------|
| S01 | Intercept AJAX request via browser DevTools | Remove `_token` from request payload | — |
| S02 | POST to `/vehicle-service-request/1/update-status` with valid status but no `_token` | VerifyReferer/CSRF middleware intercepts → 419 | — |
| S03 | Verify response | HTML: "419 Page Expired" or JSON: `{"message": "CSRF token mismatch."}` | — |
| S04 | Verify DB unchanged | Status not updated | — |
| S05 | Test with invalid token: `_token: 'invalid-token'` | Same 419 response | — |
| S06 | Confirm blade sends `csrf_token()` | Line 288: `_token: "{{ csrf_token() }}"` — server-rendered token | `approval.blade.php:288` |

### TC-N08: Already Approved — Second Attempt (Expanded)

| Step # | Action | Expected Result | Verified At |
|--------|--------|-----------------|-------------|
| S01 | Approve service request normally | Status = 'Approved' | — |
| S02 | Reload page | Request visible with disabled buttons | — |
| S03 | Check `firstOrCreate` behavior | `firstOrCreate(['vehicle_service_request_id' => $serviceRequest->id], [...])` — finds existing maintenance, does NOT create duplicate | `TptVehicleServiceRequestController.php:187` |
| S04 | Verify no duplicate maintenance | `TptVehicleMaintenance::where('vehicle_service_request_id', $id)->count()` returns 1 | — |
| S05 | [Query/Code Removed] | [Query/Code Removed] | `TptVehicleServiceRequestController.php:178` |
| S06 | Verify no error despite forced duplicate | Controller processes without exception; second call re-sets same values | — |

### TC-N09: Soft-Deleted Service Request (Expanded)

| Step # | Action | Expected Result | Verified At |
|--------|--------|-----------------|-------------|
| S01 | Create service request with `request_approval_status='Pending'` | Record #42 created | — |
| S02 | Soft-delete it via DELETE `/vehicle-service-request/42` | `deleted_at` set; record in `onlyTrashed()` | `TptVehicleServiceRequestController.php:238` |
| S03 | Navigate to approval tab | Record #42 NOT shown | — |
| S04 | Verify query does NOT include trashed | [Query/Code Removed] | `VehicleMgmtController.php:127-132` |
| S05 | Restore the record | `restore()` sets `deleted_at = null` | — |
| S06 | Reload approval tab | Record #42 appears again | — |

### TC-N10: No vehicle-fuel.approve (Expanded)

| Step # | Action | Expected Result | Verified At |
|--------|--------|-----------------|-------------|
| S01 | User has `tenant.vehicle-fuel.viewAny` but NOT `tenant.vehicle-fuel.approve` | Can see Fuel Log tab but cannot approve fuel entries | — |
| S02 | Navigate to Fuel Log tab | Fuel entries visible | — |
| S03 | Attempt inline approve via Fuel tab's status update | `Gate::authorize('tenant.vehicle-fuel.approve')` → 403 | fuel controller |
| S04 | Navigate to Approval tab | Approval tab works independently (uses separate gate) | — |

### TC-N11: No daily-vehicle-inspection.approve (Expanded)

| Step # | Action | Expected Result | Verified At |
|--------|--------|-----------------|-------------|
| S01 | User has `tenant.daily-vehicle-inspection.viewAny` but NOT `tenant.daily-vehicle-inspection.approve` | Can see Inspection tab but cannot approve inspections | — |
| S02 | Navigate to Inspection tab | Inspections visible | — |
| S03 | Attempt inline approve | `Gate::authorize('tenant.daily-vehicle-inspection.approve')` → 403 | `TptDailyVehicleInspectionController.php:228` |
| S04 | Navigate to Approval tab | Approval tab unaffected | — |

### TC-D01: Approve Creates Maintenance (Expanded)

| Step # | Action | Expected Result | Verified At |
|--------|--------|-----------------|-------------|
| S01 | Note `$serviceRequest->id` before approval | Record ID = N | — |
| S02 | Approve via AJAX | Response includes `maintenance_id: M` | `TptVehicleServiceRequestController.php:206` |
| S03 | Query `tpt_vehicle_maintenance` WHERE `id = M` | Record exists | — |
| S04 | Verify `vehicle_service_request_id = N` | Correct FK reference | `TptVehicleServiceRequestController.php:188` |
| S05 | Verify all default fields | `maintenance_initiation_date` = today, `maintenance_type` = 'General Service', `cost` = 0.00, `status` = 'Pending', `remarks` = service request reason | `TptVehicleServiceRequestController.php:190-195` |
| S06 | Approve AGAIN (force via console) | `firstOrCreate` returns existing record — no new record | `TptVehicleServiceRequestController.php:187` |
| S07 | Verify count = 1 | [Query/Code Removed] | — |

### TC-D02: Approved Request Disappears (Expanded)

| Step # | Action | Expected Result | Verified At |
|--------|--------|-----------------|-------------|
| S01 | Count pending requests shown | e.g. 5 records | — |
| S02 | Approve one | AJAX success | — |
| S03 | Wait for reload | 1.5s timeout | — |
| S04 | Count pending requests after reload | 4 records (previous 5 minus 1) | — |
| S05 | Filter by "Approved" | Previously pending request now shows as Approved | — |

### TC-D03: Rejected Request Disappears (Expanded)

| Step # | Action | Expected Result | Verified At |
|--------|--------|-----------------|-------------|
| S01 | Count pending requests | e.g. 5 records | — |
| S02 | Reject one | AJAX success | — |
| S03 | Wait for reload | 1.5s timeout | — |
| S04 | Count pending after reload | 4 records | — |
| S05 | Filter by "Rejected" | Rejected request visible with red badge | — |

### TC-D04: Status Filter Accuracy (Expanded)

| Step # | Action | Expected Result | Verified At |
|--------|--------|-----------------|-------------|
| S01 | Create: 2 Pending (IDs 1,2), 2 Approved (IDs 3,4), 2 Rejected (IDs 5,6) | 6 records | — |
| S02 | Filter "Pending" | IDs 1,2 shown | — |
| S03 | Verify ONLY pending shown | No Approved or Rejected in results | — |
| S04 | Filter "Approved" | IDs 3,4 shown | — |
| S05 | Filter "Rejected" | IDs 5,6 shown | — |
| S06 | Filter "All" (empty) | All 6 shown | — |
| S07 | Combine search + status: search "Engine" + filter "Approved" | Both WHERE clauses applied: `reason LIKE '%Engine%' AND request_approval_status = 'Approved'` | `VehicleMgmtController.php:135-151` |

### TC-D05: Soft-Delete No Cascade (Expanded)

| Step # | Action | Expected Result | Verified At |
|--------|--------|-----------------|-------------|
| S01 | Approve a service request → maintenance record M created | Both records exist | — |
| S02 | Soft-delete the service request: DELETE `/vehicle-service-request/{id}` | `deleted_at` set; record in `onlyTrashed()` | `TptVehicleServiceRequestController.php:238` |
| S03 | Query maintenance record M | Still exists — no cascade delete | — |
| S04 | Verify maintenance can be edited/updated via Maintenance tab | `TptVehicleMaintenance` is independent entity | — |
| S05 | Restore service request | Both records operational | — |

### TC-D06: Maintenance vehicle_service_request_id Match (Expanded)

| Step # | Action | Expected Result | Verified At |
|--------|--------|-----------------|-------------|
| S01 | Create service request, note its `id` = N | N is integer | — |
| S02 | Approve it | `firstOrCreate(['vehicle_service_request_id' => N], [...])` | `TptVehicleServiceRequestController.php:188` |
| S03 | Query maintenance: `WHERE vehicle_service_request_id = N` | Returns exactly 1 record | — |
| S04 | Verify maintenance ID in response | JSON `maintenance_id` matches the created maintenance row | `TptVehicleServiceRequestController.php:206` |
| S05 | Verify the relationship works | `maintenance->serviceRequest->id === N` | — |

### TC-D07: Dead Code Route Confirmation (Expanded)

| Step # | Action | Expected Result | Verified At |
|--------|--------|-----------------|-------------|
| S01 | Read `VehicleMgmtController.php` line 160 | `public function updateStatus(Request $request, $id)` exists | `VehicleMgmtController.php:160` |
| S02 | Read `routes/web.php` line 43 | `Route::resource('vehicle-mgmt', VehicleMgmtController::class)` | `routes/web.php:43` |
| S03 | Run `php artisan route:list | findstr vehicle-mgmt` | Only 7 routes: index, create, store, show, edit, update, destroy | — |
| S04 | No route maps to `updateStatus` | Method inaccessible via HTTP | — |
| S05 | Read `VehicleMgmtController.php` line 198 | `public function storeStatus(Request $request)` exists | `VehicleMgmtController.php:198` |
| S06 | No route maps to `storeStatus` | Method inaccessible via HTTP | — |
| S07 | **Conclusion**: Both methods are unreachable dead code | Remove or register routes | — |

### TC-D08: Dead Data Confirmation (Expanded)

| Step # | Action | Expected Result | Verified At |
|--------|--------|-----------------|-------------|
| S01 | Grep `Modules/Transport/resources/views` for `$pendingData` | 0 matches in any blade file | — |
| S02 | Check `vehiclemgmt.blade.php` | `compact('pendingData')` at line 63 passes variable but blade never uses it | `VehicleMgmtController.php:63` |
| S03 | Check all 5 tab partials | None reference `pendingData` or `$pendingData` | — |
| S04 | Check `getDetailedPendingData()` code | Returns fuel, inspection, service_request, maintenance — 4 queries hitting DB on every page load | `VehicleMgmtController.php:318-345` |
| S05 | **Impact**: 4 unnecessary DB queries per page load | Performance overhead with zero UI benefit | — |

### TC-CR01 to TC-CR20: Code Review — All steps already documented in Section 7 main entries above.

---

## 10. Route Analysis

### Complete Route Table for Approval Feature

| Method | URI | Name | Controller@Method | Gate | Status |
|--------|-----|------|-------------------|------|--------|
| GET | `/vehicle-mgmt` | `vehicle-mgmt.index` | `VehicleMgmtController@index` | `tenant.transport.viewAny` | ✅ Active |
| GET | `/vehicle-mgmt/create` | `vehicle-mgmt.create` | `VehicleMgmtController@create` | (via resource) | ❌ Not implemented in controller |
| POST | `/vehicle-mgmt` | `vehicle-mgmt.store` | `VehicleMgmtController@store` | (via resource) | ❌ Not implemented in controller |
| GET | `/vehicle-mgmt/{vehicleMgmt}` | `vehicle-mgmt.show` | `VehicleMgmtController@show` | (via resource) | ❌ Not implemented in controller |
| GET | `/vehicle-mgmt/{vehicleMgmt}/edit` | `vehicle-mgmt.edit` | `VehicleMgmtController@edit` | (via resource) | ❌ Not implemented in controller |
| PUT|PATCH | `/vehicle-mgmt/{vehicleMgmt}` | `vehicle-mgmt.update` | `VehicleMgmtController@update` | (via resource) | ❌ Not implemented in controller |
| DELETE | `/vehicle-mgmt/{vehicleMgmt}` | `vehicle-mgmt.destroy` | `VehicleMgmtController@destroy` | (via resource) | ❌ Not implemented in controller |
| POST | `/vehicle-service-request/{id}/update-status` | `vehicle-service-request.updateStatus` | `TptVehicleServiceRequestController@updateStatus` | `tenant.vehicle-service-approval.approve` | ✅ Active approval endpoint |
| GET | `/vehicle-service-request` | `vehicle-service-request.index` | `TptVehicleServiceRequestController@index` | `tenant.vehicle-service-request.viewAny` | ✅ Active (separate list page) |
| GET | `/vehicle-service-request/create` | `vehicle-service-request.create` | `TptVehicleServiceRequestController@create` | `tenant.vehicle-service-request.create` | ✅ Active |
| POST | `/vehicle-service-request` | `vehicle-service-request.store` | `TptVehicleServiceRequestController@store` | `tenant.vehicle-service-request.create` | ✅ Active |
| GET | `/vehicle-service-request/{id}` | `vehicle-service-request.show` | `TptVehicleServiceRequestController@show` | `tenant.vehicle-service-request.view` | ✅ Active |
| GET | `/vehicle-service-request/{id}/edit` | `vehicle-service-request.edit` | `TptVehicleServiceRequestController@edit` | `tenant.vehicle-service-request.update` | ✅ Active |
| PUT|PATCH | `/vehicle-service-request/{id}` | `vehicle-service-request.update` | `TptVehicleServiceRequestController@update` | `tenant.vehicle-service-request.update` | ✅ Active |
| DELETE | `/vehicle-service-request/{id}` | `vehicle-service-request.destroy` | `TptVehicleServiceRequestController@destroy` | `tenant.vehicle-service-request.delete` | ✅ Active |
| GET | `/vehicle-service-request/trash/view` | `vehicle-service-request.trashed` | `TptVehicleServiceRequestController@trashed` | `tenant.vehicle-service-request.restore` | ✅ Active |
| GET | `/vehicle-service-request/{id}/restore` | `vehicle-service-request.restore` | `TptVehicleServiceRequestController@restore` | `tenant.vehicle-service-request.restore` | ✅ Active |
| DELETE | `/vehicle-service-request/{id}/force-delete` | `vehicle-service-request.forceDelete` | `TptVehicleServiceRequestController@forceDelete` | `tenant.vehicle-service-request.forceDelete` | ✅ Active |
| POST | `/vehicle-service-request/{vehicle}/toggle-status` | `vehicle-service-request.toggleStatus` | `TptVehicleServiceRequestController@toggleStatus` | ❌ METHOD NOT FOUND | ⚠️ Route with no handler |

### Route Issues Summary

| Issue | Route | Impact |
|-------|-------|--------|
| `Route::resource('vehicle-mgmt', ...)` generates 7 routes, only `index()` is implemented | GET `/vehicle-mgmt/create`, POST `/vehicle-mgmt`, GET/PUT/DELETE with `{vehicleMgmt}` | ⚠️ 6 CRUD routes mapped to non-existent or non-implemented methods — would produce 500 errors if called |
| `toggleStatus` route maps to non-existent method | POST `/vehicle-service-request/{vehicle}/toggle-status` | ⚠️ Route exists but calling it produces `BadMethodCallException` — remove route or implement method |
| `VehicleMgmtController@updateStatus` has no route | No URI maps to this method | ⚠️ Dead code — 34 lines of unreachable logic |
| `VehicleMgmtController@storeStatus` has no route | No URI maps to this method | ⚠️ Dead code — 39 lines of unreachable logic |

---

## 11. Blade Analysis

### File Structure

| File | Lines | Purpose |
|------|-------|---------|
| `vehiclemgmt.blade.php` (hub) | 39 | 5-tab hub layout with permission-guarded includes |
| `approval.blade.php` (partial) | 382 | Approval tab pane: filter bar, table, view modal, AJAX scripts |

### Permission Guards in vehiclemgmt.blade.php (Hub)

| Tab | Permission Key | Include Path | Guard Type |
|-----|---------------|--------------|------------|
| Fuel Log | `tenant.vehicle-fuel.viewAny` | `transport::vehicle_fuel.index` | Nav-tab `permission` prop + `@can` around `@include` |
| Inspection | `tenant.daily-vehicle-inspection.viewAny` | `transport::daily-vehicle-Inspection.index` | Same double guard |
| Service Log | `tenant.vehicle-service-request.viewAny` | `transport::vehicle-service-request.index` | Same double guard |
| Veh. Approval | `tenant.vehicle-service-approval.viewAny` | `transport::vehicle-service-request.approval` | Same double guard |
| Veh. Maintenance | `tenant.vehicle-maintenance.viewAny` | `transport::vehiclemaintenance.index` | Same double guard |

### Permission Guards in approval.blade.php (Partial)

| Location | Guard | Element | Assessment |
|----------|-------|---------|------------|
| Line 49 | `@canany(['tenant.vehicle-service-approval.view'])` | Action column `<th>` | ⚠️ Should be `@can` (single permission) |
| Line 122 | `@can('tenant.vehicle-service-approval.view')` | Action buttons `<td>` | ✅ Correct — hides all action buttons |
| Lines 131-148 | `@if($service->request_approval_status == 'Pending')` | Approve/Reject enable/disable | ✅ Client-side state check — buttons disabled for non-pending |

### JavaScript Analysis (approval.blade.php lines 216-381)

| Function | Lines | Purpose | Notes |
|----------|-------|---------|-------|
| `view-btn` click handler | 221-248 | Opens modal with service request details | Uses `@json($service)` for full data; separate `data-vehicle`/`data-driver` attributes |
| `approve-btn` click handler | 251-253 | Triggers approval flow | Delegates to `confirmAction(id, 'Approved')` |
| `reject-btn` click handler | 256-258 | Triggers rejection flow | Delegates to `confirmAction(id, 'Rejected')` |
| `confirmAction(id, status)` | 261-275 | Shows Swal.fire confirmation | Dynamic title, icon, button color based on status |
| `updateStatus(id, status)` | 278-341 | AJAX POST to server | Handles success (badge update, disable buttons, toast, reload) and error (toast) |
| `formatDate(dateString)` | 344-360 | Date formatter | Returns `DD-MM-YYYY` or '-' if invalid |
| `toast(type, message)` | 364-381 | Swal toast notification | 3s timer, top-end position |

### AJAX Request Details (updateStatus function)

| Parameter | Value | Source |
|-----------|-------|--------|
| URL | `"{{ route('transport.vehicle-service-request.updateStatus', ':id') }}"` | Laravel `route()` helper with `:id` placeholder |
| HTTP Method | POST | `type: "POST"` in $.ajax config |
| `_token` | `"{{ csrf_token() }}"` | Server-rendered CSRF token |
| `request_approval_status` | `status` param ('Approved' or 'Rejected') | Set by caller |
| `approved_by` | `"{{ auth()->id() }}"` | Server-rendered user ID (sent but ignored by controller) |
| `_method` | "POST" | Redundant — route is already POST |

### Clickjacking / Security Notes

- All data-modifying operations require `POST` method → protected against CSRF by token
- Gate checks on server side for EVERY approval action
- `approved_by` set server-side from `Auth::user()->id`, not from request payload (prevents spoofing)
- View-only mode (`view` permission without `approve`) allows seeing data but AJAX returns 403
- No XSS vulnerability: `{{ }}` blade syntax auto-escapes output; JS uses `data-service='@json($service)'` which is JSON-encoded

---

## 12. Model & Policy Analysis

### Model: TptVehicleServiceRequest (`TptVehicleServiceRequest.php` — 125 lines)

| Key | Value |
|-----|-------|
| Table | `tpt_vehicle_service_request` |
| Traits | `HasFactory`, `SoftDeletes` |
| Fillable | `vehicle_inspection_id`, `request_date`, `reason`, `vehicle_status`, `service_completion_date`, `request_approval_status`, `approved_by`, `approved_at` |
| Default status | `request_approval_status = 'Pending'` |
| Casts | `request_date: datetime`, `service_completion_date: datetime`, `approved_at: datetime` |
| Soft Deletes | Yes — `deleted_at` column |
| Scopes | `pending()`, `approved()`, `rejected()` — all on `request_approval_status` |
| Relations | `inspection()` (belongsTo TptDailyVehicleInspection), `approvedBy()` (belongsTo User), `vehicleStatus()` (belongsTo Dropdown), `vehicleInspection()` (belongsTo TptDailyVehicleInspection — alias), `vehicleMaintenance()` (hasOne TptVehicleMaintenance) |

### Model: TptVehicleMaintenance (`TptVehicleMaintenance.php` — 91 lines)

| Key | Value |
|-----|-------|
| Table | `tpt_vehicle_maintenance` |
| Traits | `HasFactory`, `SoftDeletes` |
| Fillable | `vehicle_service_request_id`, `maintenance_initiation_date`, `maintenance_type`, `cost`, `in_service_date`, `out_service_date`, `workshop_details`, `next_due_date`, `remarks`, `status`, `approved_by`, `approved_at` |
| Casts | `maintenance_initiation_date: date`, `in_service_date: date`, `out_service_date: date`, `next_due_date: date`, `approved_at: datetime`, `cost: decimal:2` |
| Soft Deletes | Yes |
| Scopes | `pending()`, `approved()`, `dateRange()`, `vehicleFilter()` |
| Relations | `serviceRequest()` (belongsTo TptVehicleServiceRequest), `approvedBy()` (belongsTo User) |
| Accessor | `getVehicleAttribute()` — traverses `serviceRequest->inspection->vehicle` |

### Model: TptDailyVehicleInspection (Key columns for approval)

| Key | Value |
|-----|-------|
| Table | `tpt_daily_vehicle_inspection` |
| Status column | `inspection_status` (fillable: line 53) — NOT `status` |
| Pending scope | `where('inspection_status', 'Pending')` |
| ⚠️ Bug | `TptDailyVehicleInspectionController@updateStatus` line 231 sets `$inspection->status` (wrong column) |

### Policy: TransportVehicleServiceApprovalPolicy (`TransportVehicleServiceApprovalPolicy.php` — 82 lines)

| Method | Permission Key | Used In Controller? | Used In Blade? |
|--------|---------------|-------------------|----------------|
| `viewAny()` | `tenant.vehicle-service-approval.viewAny` | ✅ Hub tab display (`vehiclemgmt.blade.php:12`) | ✅ Nav-tab `permission` prop |
| `view()` | `tenant.vehicle-service-approval.view` | ❌ Not used in any controller | ✅ Action buttons (`approval.blade.php:49,122`) |
| `status()` | `tenant.vehicle-service-approval.status` | ❌ Not used | ❌ Not used |
| `approve()` | `tenant.vehicle-service-approval.approve` | ✅ `TptVehicleServiceRequestController@updateStatus` line 167 | ❌ Not directly (buttons shown via `view`) |
| `reject()` | `tenant.vehicle-service-approval.reject` | ❌ Never called — same gate as approve | ❌ Not used |
| `escalate()` | `tenant.vehicle-service-approval.escalate` | ❌ Not used | ❌ Not used |
| `viewHistory()` | `tenant.vehicle-service-approval.viewHistory` | ❌ Not used | ❌ Not used |
| `export()` | `tenant.vehicle-service-approval.export` | ❌ Not used | ❌ Not used |
| `print()` | `tenant.vehicle-service-approval.print` | ❌ Not used | ❌ Not used |

### Policy: TransportVehicleServiceRequestPolicy (`TransportVehicleServiceRequestPolicy.php` — 114 lines)

| Method | Permission Key | Used In Controller? |
|--------|---------------|-------------------|
| `viewAny()` | `tenant.vehicle-service-request.viewAny` | ✅ `TptVehicleServiceRequestController@index` line 20 |
| `view()` | `tenant.vehicle-service-request.view` | ✅ `show()` line 92 |
| `create()` | `tenant.vehicle-service-request.create` | ✅ `create()` line 38, `store()` line 53 |
| `update()` | `tenant.vehicle-service-request.update` | ✅ `edit()` line 112, `update()` line 128 |
| `delete()` | `tenant.vehicle-service-request.delete` | ✅ `destroy()` line 236 |
| `restore()` | `tenant.vehicle-service-request.restore` | ✅ `trashed()` line 255, `restore()` line 272 |
| `forceDelete()` | `tenant.vehicle-service-request.forceDelete` | ✅ `forceDelete()` line 293 |
| `import()` | `tenant.vehicle-service-request.import` | ❌ Not used |
| `export()` | `tenant.vehicle-service-request.export` | ❌ Not used |
| `print()` | `tenant.vehicle-service-request.print` | ❌ Not used |
| `submit()` | `tenant.vehicle-service-request.submit` | ❌ Not used |
| `cancel()` | `tenant.vehicle-service-request.cancel` | ❌ Not used |

### Policy Method Coverage

| Policy | Total Methods | Used in Controller | Unused Methods |
|--------|--------------|------------------|----------------|
| `TransportVehicleServiceApprovalPolicy` | 9 | 2 (`viewAny`, `approve` — via gate string, not policy instance) | 7 (`view`, `status`, `reject`, `escalate`, `viewHistory`, `export`, `print`) |
| `TransportVehicleServiceRequestPolicy` | 12 | 7 | 5 (`import`, `export`, `print`, `submit`, `cancel`) |

**Note**: All Gate checks use string-based `Gate::authorize('tenant.*')` — NOT policy instance-based `Gate::authorize('action', $model)`. This means the policy methods defined above are technically REACHABLE via `$user->can('tenant.*')` which resolves through the Gate's `before` callback, but the policy's method-specific logic (e.g., model-based checks in `view(User $user, TptVehicleServiceRequest $approval)`) is NEVER executed. The policy methods effectively serve as permission string registrations only.

---

## 13. Security Audit Summary

| Area | Finding | Severity | Recommendation |
|------|---------|----------|---------------|
| CSRF | All POST routes protected by CSRF middleware | ✅ Secure | None |
| Auth | All active data-modifying methods have Gate checks | ✅ Secure | None |
| Auth | `approved_by` set server-side, not from request | ✅ Secure | Prevents spoofing |
| Auth | `VehicleMgmtController@updateStatus` — NO Gate (dead code) | ⚠️ Low (dead code) | Add Gate if route activated |
| Auth | `VehicleMgmtController@storeStatus` — NO Gate (dead code) | ⚠️ Low (dead code) | Add Gate if route activated |
| Auth | `togleStatus` route has NO controller method | ⚠️ Medium | Remove route or implement method |
| Input | `updateStatus` validates `request_approval_status` with `in:Approved,Rejected` | ✅ Secure | None |
| Input | `TptVehicleServiceRequest@store` has NO validation (no FormRequest, no inline) | ⚠️ Medium | Add validation rules to store() |
| XSS | Blade auto-escapes with `{{ }}` syntax | ✅ Secure | None |
| CS | `TptDailyVehicleInspectionController@updateStatus` uses `first()` not `findOrFail()` | ⚠️ Medium | Replace with `findOrFail($id)` |
| Audit | `TptVehicleMaintenanceController@update` — no activityLog | ⚠️ Medium | Add `activityLog()` call |
| Data | `getDetailedPendingData()` runs 4 unnecessary DB queries | ⚠️ Low (performance) | Remove dead code |
| State | No server-side guard against re-approving already-approved requests | ⚠️ Low | Add `where('request_approval_status', 'Pending')` check before update |
| Column | `dailyInspectionQuery` uses `is_active` — column does not exist | 🔴 High | Change to `inspection_status` |
| Column | `TptDailyVehicleInspectionController@updateStatus` uses `status` — column does not exist | 🔴 High | Change to `inspection_status` |
| Route | `Route::resource('vehicle-mgmt')` generates 6 unimplemented routes | ⚠️ Low | Override with `only: ['index']` to prevent accidental 500s |

---

## 14. Database Query Analysis

### Query Profile: Approval Tab Page Load

When `GET /vehicle-mgmt?tab=approval` loads, the following DB queries execute:

| # | Query Source | Table(s) | Type | Count |
|---|-------------|----------|------|-------|
| 1 | `VehicleMgmtController@index` — `Vehicle::all()` | `vehicles` | SELECT all | 1 |
| 2 | `VehicleMgmtController@index` — `DriverHelper::all()` | `driver_helpers` | SELECT all | 1 |
| 3 | `VehicleMgmtController@index` — `Route::all()` | `routes` | SELECT all | 1 |
| 4 | `VehicleMgmtController@index` — `Shift::all()` | `shifts` | SELECT all | 1 |
| 5 | `VehicleMgmtController@index` — `Vehicle::paginate(10)` | `vehicles` | SELECT + COUNT | 2 |
| 6 | `VehicleMgmtController@index` — `Route::paginate(10)` | `routes` | SELECT + COUNT | 2 |
| 7 | `VehicleMgmtController@index` — `DriverHelper::paginate(10)` | `driver_helpers` | SELECT + COUNT | 2 |
| 8 | `VehicleMgmtController@index` — `Shift::paginate(10)` | `shifts` | SELECT + COUNT | 2 |
| 9 | `vehicleServiceRequestQuery()` — main approval data | `tpt_vehicle_service_request` + joins (vehicles, driver_helpers, users) | SELECT + COUNT + eager loads | 5+ |
| 10 | `fuelEntryQuery()` — Fuel tab data | `tpt_vehicle_fuel` + relations | SELECT + COUNT + eager loads | 5+ |
| 11 | `dailyInspectionQuery()` — Inspection tab data | `tpt_daily_vehicle_inspection` + relations | SELECT + COUNT + eager loads | 5+ |
| 12 | `vehicleMaintenanceQuery()` — Maintenance tab data | `tpt_vehicle_maintenance` + relations | SELECT + COUNT + eager loads | 5+ |
| 13 | `getDetailedPendingData()` — DEAD CODE | 4 tables (fuel, inspection, service request, maintenance) | SELECT 4 × 10 rows | 4 |
| **Total** | | | | **~36+ queries** |

### N+1 Query Analysis

| Relation Chain | Eager Loaded? | Location |
|---------------|--------------|----------|
| ServiceRequest → Inspection → Vehicle | ✅ `with(['inspection.vehicle'])` | `VehicleMgmtController.php:127-128` |
| ServiceRequest → Inspection → Driver | ✅ `with(['inspection.driver'])` | `VehicleMgmtController.php:129` |
| ServiceRequest → Inspection → Inspector | ✅ `with(['inspection.inspector'])` | `VehicleMgmtController.php:130` |
| ServiceRequest → ApprovedBy (User) | ✅ `with(['approvedBy'])` | `VehicleMgmtController.php:131` |
| Vehicle → Driver (in vehicleServiceRequestQuery) | N/A — accessed via inspection relation | Not direct |
| ServiceRequest → vehicleMaintenance (hasOne) | ❌ NOT eager loaded in vehicleServiceRequestQuery | Not in `with()` array |
| ServiceRequest → vehicleStatus (Dropdown) | ❌ NOT eager loaded | Lazy-loaded per row in blade at `approval.blade.php:83` |

### Performance Recommendation

- Remove `getDetailedPendingData()` (line 47) — saves 4 unnecessary queries per page load
- Add `'vehicleMaintenance'` to the `with()` array in `vehicleServiceRequestQuery()` to eager-load the hasOne maintenance relation
- Add `'vehicleStatus'` to the `with()` array to eager-load the dropdown status
- Consider deferring non-visible tab data with lazy loading (only query data for the active tab)
- Use `Route::resource('vehicle-mgmt', ...)->only(['index'])` to prevent 6 unimplemented resource routes

### Index Recommendations

| Table | Column(s) | Reason |
|-------|-----------|--------|
| `tpt_vehicle_service_request` | `request_approval_status` | Primary filter in approval tab |
| `tpt_vehicle_service_request` | `deleted_at` | Soft delete filtering |
| `tpt_vehicle_maintenance` | `vehicle_service_request_id` | FK join + `firstOrCreate` lookup |
| `tpt_vehicle_service_request` | `created_at` or `updated_at` | `latest()` ordering |

---

## 15. Integration Test Scenarios

### Scenario I: Full Approval-to-Maintenance Lifecycle

| Step # | Action | Expected Result | Data Validated |
|--------|--------|-----------------|----------------|
| 1 | Driver creates daily vehicle inspection | `inspection_status='Pending'` | Inspection created |
| 2 | Inspection failed → auto-create service request | `TptVehicleServiceRequest` created with `request_approval_status='Pending'`, `reason` from inspection | `TptDailyVehicleInspectionController@store` (lines 54-60) |
| 3 | Service request appears in approval tab | Pending request visible with vehicle/driver info | Approval tab loads |
| 4 | Approve service request | Status → 'Approved', maintenance entry created | `TptVehicleServiceRequestController@updateStatus` |
| 5 | Maintenance entry visible in Maintenance tab | New maintenance with `status='Pending'`, `type='General Service'` | Maintenance tab |
| 6 | Workshop completes maintenance, updates via Maintenance tab | Maintenance status → 'Approved', back-propagates to service request | `TptVehicleMaintenanceController@update` (lines 85-108) |
| 7 | Service request now shows `vehicle_status='Service Done'`, `service_completion_date=today` | Full lifecycle complete | Verify in show page or DB |

### Scenario II: Unauthorized User Attempts to Access Approval Tab

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create user with NO transport permissions | — |
| 2 | Access `/vehicle-mgmt` | 403 Forbidden |
| 3 | Add `tenant.transport.viewAny` only | Can see hub but all tabs hidden (no `@can` passes) |
| 4 | Add `tenant.vehicle-service-approval.viewAny` | Approval tab visible, table rows shown, NO action buttons |
| 5 | Add `tenant.vehicle-service-approval.view` | Action buttons visible (view/approve/reject) |
| 6 | Click Approve | 403 (no `approve` permission) |
| 7 | Add `tenant.vehicle-service-approval.approve` | Approve/Reject both work |

### Scenario III: Concurrent Approval Race Condition

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User A and User B both open approval tab simultaneously | Both see same pending request |
| 2 | User A clicks Approve at T=0ms | `firstOrCreate` creates maintenance entry with `vehicle_service_request_id=X` |
| 3 | User B clicks Approve at T=100ms | `firstOrCreate` finds existing maintenance (first param match) → returns existing, does NOT create duplicate |
| 4 | Check service request's `approved_by` | Set to User B's ID (last writer wins — `update()` at line 178 runs for both) |
| 5 | Check maintenance count | Exactly 1 record for this service request |

### Scenario IV: Database Constraint Violations

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST updateStatus with `request_approval_status='Approved'` for service request without inspection | `$serviceRequest->inspection` is null → blade shows "N/A" for vehicle. No error — `firstOrCreate` still succeeds. | 
| 2 | POST updateStatus with massive `id` value | `findOrFail()` → `ModelNotFoundException` → caught → JSON 500 error response |
| 3 | Force DB write failure (e.g., lock table) | Exception caught at line 221 → JSON `{success: false, message: 'Something went wrong...'}` |
| 4 | Approve same request twice from parallel sessions | `firstOrCreate` prevents duplicate maintenance. `request_approval_status` is UPDATE-only (no unique constraint issue). |

### Scenario V: Dead Code Activation (What If?)

| Step # | Action | Expected Result | Risk |
|--------|--------|-----------------|-----|
| 1 | Add route: `Route::post('vehicle-mgmt/{id}/update-status', [VehicleMgmtController::class, 'updateStatus'])` | Route now maps to dead code | — |
| 2 | POST to `/vehicle-mgmt/1/update-status` with `request_approval_status=Approved` | No Gate check → ANY authenticated user can approve | 🔴 Missing Gate |
| 3 | Approve same request 3 times | [Query/Code Removed] | 🔴 Data integrity |
| 4 | Check approval activity log | No activityLog call → no audit trail | 🔴 Missing audit |
| 5 | Response is `redirect()->back()` not JSON | Blade's AJAX handler expects JSON → breaks JS flow | ⚠️ JS expects JSON |

---

## 16. Edge Cases & Boundary Analysis

### Approval Status Edge Cases

| Case | Input | Expected | Actual Behavior | Status |
|------|-------|----------|----------------|--------|
| Empty string | `request_approval_status: ''` | 422 required | ✅ Validated by `required` rule |
| Whitespace | `request_approval_status: ' '` | 422 (not in: Approved,Rejected) | ✅ Caught by `in` rule |
| Case sensitivity | `request_approval_status: 'approved'` (lowercase) | 422 (not in list) | ✅ `in:Approved,Rejected` is case-sensitive |
| Unicode | `request_approval_status: '✓'` | 422 | ✅ Caught by `in` rule |
| Very long string | `request_approval_status: 'A' × 10000` | 422 or truncated | Laravel `in` validation rejects |
| SQL injection | `request_approval_status: "' OR '1'='1"` | 422 | ✅ Parametrized query via Eloquent |

### Request ID Edge Cases

| Case | ID Value | Expected | Actual Behavior | Status |
|------|----------|----------|----------------|--------|
| Zero | 0 | 404 `ModelNotFoundException` | `findOrFail(0)` → throws | ✅ |
| Negative | -1 | 404 | `findOrFail(-1)` → throws | ✅ |
| Float | 1.5 | 404 (truncated to 1) | Depends on DB driver — may find ID 1 | ⚠️ May match unintended record |
| String | "abc" | 404 or conversion error | MySQL casts to 0 → `findOrFail(0)` → 404 | ✅ (by accident) |
| Null | null | 404 | Route parameter required → 404 before controller | ✅ |
| Existing soft-deleted | 42 (deleted) | 404 (onlyTrashed scope not used) | `findOrFail($id)` WITHOUT `withTrashed()` → 404 if deleted | ✅ |
| Maximum integer | 2147483647 | 404 | `findOrFail(MAX_INT)` → may or may not exist | ⚠️ Edge |

### Pagination Edge Cases

| Case | Records | Page | Expected |
|------|---------|------|----------|
| Exact multiple | 20 records (10/page × 2) | Page 2 | Shows 10 records, no page 3 |
| Single record | 1 record | Page 1 | Shows 1 record, no pagination links |
| Zero records | 0 records | Page 1 | "No Records Found" message |
| Negative page | 10 records | ?page=-1 | Paginator may default to page 1 |
| Excessive page | 10 records | ?page=999 | Returns empty results, no error |
| Non-integer page | 10 records | ?page=abc | Paginator defaults to page 1 |

### Concurrent Request Edge Cases

| Case | Description | Expected |
|------|-------------|----------|
| Double-click Approve | User clicks Approve twice before JS disables button | 2 AJAX calls → `firstOrCreate` prevents duplicate maintenance on second call |
| Refresh during AJAX | User clicks Approve then immediately refreshes page | `updateStatus` may or may not have completed. If it did, approval persists; if not, no change. Result is deterministic after reload. |
| Navigate away | User clicks Approve then navigates to another page | AJAB may be aborted by browser navigation. Server may or may not process. Check DB after navigation to confirm. |
| Multiple tabs | Same pending request open in 2 browser tabs | Approving in Tab A → reload Tab B → request gone from pending list. |

---

## 17. Data Flow Diagrams (Text)

### Approval Flow (Success Path)



### Rejection Flow



### Permission Decision Tree



---

## 18. Verification Checklist

### Controller Verification

- [x] `VehicleMgmtController@index` (line 27) — Gate at line 29: `tenant.transport.viewAny`
- [x] `VehicleMgmtController@dailyInspectionQuery` (line 67) — ⚠️ BUG: `is_active` should be `inspection_status`
- [x] `VehicleMgmtController@fuelEntryQuery` (line 97) — Correct column `status`
- [x] `VehicleMgmtController@vehicleServiceRequestQuery` (line 124) — Correct column `request_approval_status`
- [x] `VehicleMgmtController@updateStatus` (line 160) — ⚠️ Dead code, NO Gate, NO activityLog, uses `create()` not `firstOrCreate()`
- [x] `VehicleMgmtController@storeStatus` (line 198) — ⚠️ Dead code, NO Gate, NO activityLog
- [x] `VehicleMgmtController@vehicleMaintenanceQuery` (line 239) — Correct implementation
- [x] `VehicleMgmtController@getDetailedPendingData` (line 318) — ⚠️ Dead data, never rendered
- [x] `TptVehicleServiceRequestController@index` (line 18) — Gate: `tenant.vehicle-service-request.viewAny`
- [x] `TptVehicleServiceRequestController@create` (line 36) — Gate: `tenant.vehicle-service-request.create`
- [x] `TptVehicleServiceRequestController@store` (line 51) — Gate: `tenant.vehicle-service-request.create`, has activityLog
- [x] `TptVehicleServiceRequestController@show` (line 90) — Gate: `tenant.vehicle-service-request.view`
- [x] `TptVehicleServiceRequestController@edit` (line 110) — Gate: `tenant.vehicle-service-request.update`
- [x] `TptVehicleServiceRequestController@update` (line 126) — Gate: `tenant.vehicle-service-request.update`, has validation + activityLog
- [x] `TptVehicleServiceRequestController@updateStatus` (line 165) — Gate: `tenant.vehicle-service-approval.approve`, has validation + activityLog + firstOrCreate
- [x] `TptVehicleServiceRequestController@destroy` (line 234) — Gate: `tenant.vehicle-service-request.delete`, has activityLog
- [x] `TptVehicleServiceRequestController@trashed` (line 253) — Gate: `tenant.vehicle-service-request.restore`
- [x] `TptVehicleServiceRequestController@restore` (line 270) — Gate: `tenant.vehicle-service-request.restore`, has activityLog
- [x] `TptVehicleServiceRequestController@forceDelete` (line 291) — Gate: `tenant.vehicle-service-request.forceDelete`, has activityLog
- [ ] `TptVehicleServiceRequestController@toggleStatus` — ❌ DOES NOT EXIST (route at web.php:49)
- [x] `TptDailyVehicleInspectionController@updateStatus` (line 226) — ⚠️ BUG: `status` should be `inspection_status`
- [x] `TptVehicleMaintenanceController@update` (line 67) — ⚠️ MISSING activityLog

### Blade Verification

- [x] `vehiclemgmt.blade.php` — 5 tabs with correct permission keys
- [x] `vehiclemgmt.blade.php` — Double security (nav-tab permission + @can around @include)
- [x] `approval.blade.php:49` — ⚠️ Should be `@can` not `@canany` for single permission
- [x] `approval.blade.php:122` — Correct `@can('tenant.vehicle-service-approval.view')`
- [x] `approval.blade.php:131-148` — Pending check for button enable/disable
- [x] `approval.blade.php:31` — ⚠️ Reset filter `href="#"` broken
- [x] `approval.blade.php:284` — Route name with `transport.` prefix
- [x] `approval.blade.php:288` — CSRF token present
- [x] `approval.blade.php:7` — Uses `<x-backend.tab.filter-bar>` (not `search-bar`)

### Database Verification

- [x] `tpt_vehicle_service_request.request_approval_status` column exists
- [x] Default value `'Pending'` on `request_approval_status`
- [x] `tpt_vehicle_maintenance.vehicle_service_request_id` FK column exists
- [x] `tpt_daily_vehicle_inspection.inspection_status` column (NOT `status`)
- [x] No `is_active` column in `tpt_daily_vehicle_inspection` table
- [x] SoftDeletes trait on all 4 entity models

---

## 19. Final Bug & Gap Register

| ID | Type | Severity | File:Line | Description | Fix |
|----|------|----------|-----------|-------------|-----|
| BUG-001 | Column Name | 🔴 High | `VehicleMgmtController.php:88` | `where('is_active', ...)` — column does not exist in `tpt_daily_vehicle_inspection` | Change to `where('inspection_status', ...)` |
| BUG-002 | Column Name | 🔴 High | `TptDailyVehicleInspectionController.php:231` | `$inspection->status = ...` — should be `inspection_status` | Change to `$inspection->inspection_status` |
| BUG-003 | Missing Method | 🔴 High | `routes/web.php:49` | `togleStatus` route maps to non-existent `TptVehicleServiceRequestController@toggleStatus` | Remove route or implement method |
| BUG-004 | Missing Method | ⚠️ Medium | `TptDailyVehicleInspectionController.php:230` | Uses `first()` instead of `findOrFail()` | Change to `findOrFail($id)` |
| GAP-001 | Missing Audit | ⚠️ Medium | `TptVehicleMaintenanceController.php:67-114` | `update()` has no activityLog | Add `activityLog()` call |
| GAP-002 | Missing Audit | ⚠️ Medium | `VehicleMgmtController.php:160-193` | Dead code `updateStatus()` has no activityLog | Add if activated |
| GAP-003 | Missing Audit | ⚠️ Medium | `VehicleMgmtController.php:198-236` | Dead code `storeStatus()` has no activityLog | Add if activated |
| GAP-004 | Missing Gate | ⚠️ Medium | `VehicleMgmtController.php:160` | Dead code `updateStatus()` has no Gate | Add if activated |
| GAP-005 | Missing Gate | ⚠️ Medium | `VehicleMgmtController.php:198` | Dead code `storeStatus()` has no Gate | Add if activated |
| BUG-005 | UX | ⚠️ Medium | `approval.blade.php:31` | Reset filter `href="#"` does nothing | Fix URL to route with tab param |
| BUG-006 | Duplicate Data | ⚠️ Medium | `VehicleMgmtController.php:181` | Dead code uses `create()` — would create duplicate maintenance | Change to `firstOrCreate()` |
| GAP-006 | Validation | ⚠️ Medium | `TptVehicleServiceRequestController.php:51-85` | `store()` method has no validation | Add FormRequest or inline validation |
| GAP-007 | Performance | ⚠️ Low | `VehicleMgmtController.php:47` | `getDetailedPendingData()` runs 4 unnecessary queries | Remove dead code |
| STYLE-001 | Convention | ⚠️ Low | `approval.blade.php:49` | `@canany` with single permission | Change to `@can` |
| STYLE-002 | Convention | ⚠️ Low | `approval.blade.php:291` | Redundant `_method: "POST"` in AJAX data | Remove unnecessary field |

---

## 20. Cross-Tab Dependency Analysis

### How Approval Tab Affects Other Tabs

| Action in Approval Tab | Effect on Fuel Tab | Effect on Inspection Tab | Effect on Service Log Tab | Effect on Maintenance Tab |
|------------------------|-------------------|------------------------|--------------------------|--------------------------|
| Pending request visible | None | None | Request visible in Service Log (status: Pending) | No entry yet |
| Approve request | None | None | Request status → 'Approved' in Service Log | Maintenance entry created with `status: 'Pending'`, visible in Maintenance tab |
| Reject request | None | None | Request status → 'Rejected' in Service Log | No change |
| Approve → Maintenance approved later via Maintenance tab | None | None | `service_completion_date` set, `vehicle_status` → 'Service Done' | Maintenance status → 'Approved' |

### Shared Data Visibility

| Entity | Approval Tab Shows | Other Tab Shows | Difference |
|--------|-------------------|-----------------|------------|
| `TptVehicleServiceRequest` | All statuses (via filter) | Service Log tab: all CRUD | Approval tab is read-only (no edit/delete), Service Log has full CRUD |
| `TptVehicleMaintenance` | Not directly shown | Maintenance tab: full CRUD | Approval tab only creates maintenance, does not display it |
| `TptVehicleFuel` | Not shown (dead code in `$pendingData`) | Fuel tab: full CRUD | Dead code data computed but hidden |
| `TptDailyVehicleInspection` | Not shown (dead code) | Inspection tab: full CRUD | Dead code data computed but hidden |

### Tab Permission Independence

Each tab has its own `viewAny` permission. A user may have access to:
- Approval tab ONLY (needs `tenant.vehicle-service-approval.viewAny`)
- All tabs except one
- Exactly one tab
- No tabs (can't see the hub at all without `tenant.transport.viewAny`)

This means service requests can be approved by someone who cannot see the Service Log tab or the Fuel tab.

---

## 21. Test Data Setup Scripts

### PHPUnit/Seeder Data Setup



### Dusk Test Sequence



### cURL Test Commands



### Artisan Tinker Verification Snippets



---

## 22. Non-Functional Requirements

### Performance

| Requirement | Current State | Target | Gap |
|-------------|---------------|--------|-----|
| Page load queries | ~36 queries (incl. dead code) | < 20 | `getDetailedPendingData()` adds 4 unnecessary queries |
| API response time (updateStatus) | < 200ms (single query + 1 insert) | < 500ms | ✅ Meets target |
| Pagination response | 10 items/page | Configurable | Currently hard-coded to 10 |
| Eager loading | 4 relations loaded | All relations loaded | Missing `vehicleMaintenance` and `vehicleStatus` in query |

### Security

| Requirement | Current State | Pass |
|-------------|---------------|------|
| Authorization on all write endpoints | ✅ All active endpoints gated | Pass |
| CSRF protection on POST | ✅ Token sent via blade | Pass |
| Input validation on updateStatus | ✅ `required|in:Approved,Rejected` | Pass |
| Input validation on store | ❌ No validation | Fail |
| SQL injection protection | ✅ Eloquent parameterized queries | Pass |
| XSS protection | ✅ Blade `{{ }}` auto-escapes | Pass |
| Audit trail for state changes | ✅ activityLog present for updateStatus | Pass |
| Server-side authority for approved_by | ✅ `Auth::user()->id` not from request | Pass |

### Reliability

| Requirement | Current State | Pass |
|-------------|---------------|------|
| Error handling in AJAX endpoint | ✅ try-catch with JSON error response | Pass |
| Duplicate prevention | ✅ `firstOrCreate()` | Pass |
| Transaction safety | ❌ No DB transactions | Partial — single operations only |
| Soft delete safety | ✅ SoftDeletes on all entities | Pass |
| ModelNotFoundException handling | ✅ Caught in try-catch | Pass |

### Compatibility

| Requirement | Current State |
|-------------|---------------|
| Browser support | AJAX uses jQuery (`.ajax`), Swal.fire for modals |
| Mobile responsiveness | Table uses `table-sm`, responsive via wrapper |
| JS framework | jQuery (no Vue/React/Livewire) |
| Server | Laravel 10+ (PHP 8.x) |
| Database | MySQL/MariaDB (tested with default SQL modes) |

---

## 23. Complete Method Inventory

### VehicleMgmtController

| # | Method | Visibility | Lines of Code | Complexity | Has Gate | Has ActivityLog | Has Route | Status |
|---|--------|-----------|---------------|------------|----------|----------------|-----------|--------|
| 1 | `index()` | public | 39 | Medium | ✅ | ❌ | ✅ | Active |
| 2 | `dailyInspectionQuery()` | private | 26 | Medium | N/A | N/A | N/A | Private helper |
| 3 | `fuelEntryQuery()` | private | 23 | Medium | N/A | N/A | N/A | Private helper |
| 4 | `vehicleServiceRequestQuery()` | private | 31 | Medium | N/A | N/A | N/A | Private helper |
| 5 | `updateStatus()` | public | 34 | High | ❌ | ❌ | ❌ | Dead code |
| 6 | `storeStatus()` | public | 39 | Medium | ❌ | ❌ | ❌ | Dead code |
| 7 | `vehicleMaintenanceQuery()` | private | 71 | High | N/A | N/A | N/A | Private helper |
| 8 | `getDetailedPendingData()` | private | 28 | Low | N/A | N/A | N/A | Dead data |

### TptVehicleServiceRequestController

| # | Method | Visibility | Lines of Code | Complexity | Has Gate | Has ActivityLog | Has Route | Status |
|---|--------|-----------|---------------|------------|----------|----------------|-----------|--------|
| 1 | `index()` | public | 14 | Low | ✅ | ❌ | ✅ | Active |
| 2 | `create()` | public | 11 | Low | ✅ | ❌ | ✅ | Active |
| 3 | `store()` | public | 35 | Medium | ✅ | ✅ | ✅ | Active |
| 4 | `show()` | public | 16 | Low | ✅ | ❌ | ✅ | Active |
| 5 | `edit()` | public | 12 | Low | ✅ | ❌ | ✅ | Active |
| 6 | `update()` | public | 35 | Medium | ✅ | ✅ | ✅ | Active |
| 7 | `updateStatus()` (approval) | public | 65 | High | ✅ | ✅ | ✅ | Active |
| 8 | `destroy()` | public | 15 | Low | ✅ | ✅ | ✅ | Active |
| 9 | `trashed()` | public | 13 | Low | ✅ | ❌ | ✅ | Active |
| 10 | `restore()` | public | 17 | Low | ✅ | ✅ | ✅ | Active |
| 11 | `forceDelete()` | public | 17 | Low | ✅ | ✅ | ✅ | Active |
| 12 | `toggleStatus()` | — | — | — | — | — | Route only | Missing |

### Cross-Cutting Observations

- **Total code**: 21 methods across 4 controllers
- **Code coverage gap**: `store()` in TptVehicleServiceRequestController (line 51) has NO validation — raw `$request->field` used in `create()` call
- **Dead code**: 73 lines of unreachable logic in VehicleMgmtController (updateStatus + storeStatus)
- **Dead data**: 4 unnecessary queries per page load via `getDetailedPendingData()`
- **Pattern inconsistency**: TptVehicleServiceRequestController uses `findOrFail($id)` consistently but `TptDailyVehicleInspectionController@updateStatus` uses `where('id',$id)->first()`
- **ActivityLog inconsistency**: Most CRUD methods log, but `TptVehicleMaintenanceController@update` and `VehicleMgmtController@index` do not
