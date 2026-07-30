# Transport Stops (Pickup Points) — TC_List

---

## 1. Feature Information

| Attribute | Details |
|-----------|---------|
| **Module** | Transport (TPT) |
| **Entity** | Transport Stops / Pickup Points (`tpt_pickup_points`) |
| **Controller** | `Modules\Transport\Http\Controllers\PickupPointController` — 11 methods + `getPickupPointsByShift()` |
| **Model** | `Modules\Transport\Models\PickupPoint` — BaseModel, SoftDeletes, 11 fillable fields, 5 relationships (route, shift, tripStopDetails, boardingLogs, studentAllocations) |
| **Form Request** | `Modules\Transport\Http\Requests\PickupPointRequest` — 11 validation rules + `prepareForValidation()` checkbox normalize + `authorize()` with POST/create vs non-POST/update |
| **Policy** | `Modules\Transport\Policies\PickupPointPolicy` — 10 permission methods (viewAny, view, status, create, update, delete, restore, forceDelete, import, export, print) |
| **Route Prefix** | `transport.pickup-point.*` (resource) + `trashed`, `restore`, `forceDelete`, `toggleStatus`, `get-by-shift` |
| **Blade Views** | `pickup_point/index.blade.php` (tab), `create`, `edit`, `show`, `trash`, `pickup_point.blade.php` |
| **Tab Container** | `transportmaster.blade.php` — tab id `trans_stops`, permission `tenant.pickup-point.viewAny` |
| **DB Table** | `tpt_pickup_points` — 10 data columns + spatial `location` POINT SRID 4326 + softDeletes + 2 unique keys + 1 FK + 1 spatial index |
| **Primary Screen** | Transport Master → Trans. Stops tab (paginated 10/page, searchable by name/code/location, filtered by shift + stop type + status) |

---

## 2. Pre-conditions

| # | Pre-condition | Source |
|---|--------------|--------|
| PC-01 | User must be logged in with `tenant.pickup-point.*` permissions | Policy-based |
| PC-02 | `tpt_pickup_points` table must exist with spatial POINT column `location` SRID 4326 | Migration `2026_06_16_140611` line 21 |
| PC-03 | `tpt_shift` must have active shifts for `shift_id` FK (fk_pickupPoint_shiftId ON DELETE CASCADE) | Migration line 31 |
| PC-04 | Spatial index `sp_idx_pickup_location` must exist for geospatial queries | Migration line 40 |
| PC-05 | Unique constraints `uq_pickup_code` on `code` and `uq_pickup_name` on `name` | Migration lines 34-35 |
| PC-06 | `PickupPoint` model extends `BaseModel` with `SoftDeletes` trait | `PickupPoint.php:7,12` |
| PC-07 | Google Maps API key configured in `config('transport.google_maps_api_key')` for autocomplete + distance matrix | `create.blade.php:165`, `edit.blade.php:171` |
| PC-08 | Browser location permission required for distance calculation in create/edit | `create.blade.php:183-195` |

---

## 3. Default Data Load

| # | Data Load Rule | Source |
|---|----------------|--------|
| DL-01 | Load pickup points with eager `route` and `shift` relationships, 10 per page | `TransportMasterController.php:305,74` (hub controller manages tab data via `pickupPointsQuery()`) |
| DL-02 | Search: Name, Code, Location (3 fields in hub's `pickupPointsQuery()`) | `TransportMasterController.php:313-316` |
| DL-03 | Filters: `?shift_id=`, `?pickup_drop=` (Pickup/Drop/All), `?status=` (1/0/All) + `?search=` | `pickup_point/index.blade.php:13-37` |
| DL-04 | List columns in index tab: Code, Name, Location, (Route commented out), Shift, Stop Type, Status, Action | `pickup_point/index.blade.php:57-66` |
| DL-05 | Shift filter dropdown populated with `$shifts` from hub (all shifts, no active filter) | `pickup_point/index.blade.php:13-21` |
| DL-06 | `toggleStatus()` — no `$request->boolean()` helper, direct `$request->is_active` assignment | `PickupPointController.php:205` |
| DL-07 | `getPickupPointsByShift()` — AJAX endpoint returning JSON for map display, filters by shift_id + is_active | `PickupPointController.php:42-71` |
| DL-08 | `pickupPointsQuery()` in hub uses `PickupPoint::with(['route', 'shift'])->latest()` | `TransportMasterController.php:305` |
| DL-09 | Hub search includes `location` field (not just name/code) unlike standalone controller | `TransportMasterController.php:315` |
| DL-10 | Default `stop_type='Both'`, `is_active=true` in model `$attributes` | `PickupPoint.php:49-52` |
| DL-11 | `$pickupPoints->appends(['tab'=>request('tab','trans_stops')])->links()` for pagination | `pickup_point/index.blade.php:97` |

---

## 4. Test Data Strategy

| # | Data Strategy | Details |
|---|---------------|---------|
| TD-01 | **Valid Stop — Pickup** | code="MG-ROAD", name="MG Road Stop", stop_type="Pickup", shift_id=valid |
| TD-02 | **Valid Stop — Drop** | code="SCHOOL-GATE", name="School Gate", stop_type="Drop" |
| TD-03 | **Valid Stop — Both** | code="MAIN-GATE", name="Main Gate", stop_type="Both" |
| TD-04 | **Invalid lat/lng** | latitude=100 (beyond 90) — expects `between:-90,90` error |
| TD-05 | **Duplicate code** | Same code as existing — expects unique violation |
| TD-06 | **Duplicate name** | Same name as existing — expects unique violation |
| TD-07 | **Invalid shift_id** | shift_id=99999 — expects `exists` error |
| TD-08 | **Boundary lat** | latitude=90 (exact max), longitude=180 (exact max) — valid boundary |
| TD-09 | **Negative lat** | latitude=-90 — valid boundary min |
| TD-10 | **Zero coordinates** | lat=0, lng=0 — valid Equator/Prime Meridian |

---

## 5. Business Conditions (BC)

### BC-DB: Database Conditions — `tpt_pickup_points`

| ID | Column | Type (Migration) | Constraints | Source |
|----|--------|------------------|-------------|--------|
| BC-DB-01 | `id` | INT UNSIGNED AUTO_INCREMENT | PK | Migration line 16 |
| BC-DB-02 | `code` | VARCHAR(50), NOT NULL | UNIQUE (uq_pickup_code) | Migration lines 17,34 |
| BC-DB-03 | `name` | VARCHAR(200), NOT NULL | UNIQUE (uq_pickup_name) | Migration lines 18,35 |
| BC-DB-04 | `latitude` | DECIMAL(10,7), NULLABLE | Precision 10, scale 7 | Migration line 19 |
| BC-DB-05 | `longitude` | DECIMAL(10,7), NULLABLE | Precision 10, scale 7 | Migration line 20 |
| BC-DB-06 | `location` | POINT (geometry), SRID 4326, NOT NULL | Spatial type, SRID 4326 | Migration line 21 |
| BC-DB-07 | `total_distance` | DECIMAL(7,2), NULLABLE | Precision 7, scale 2 | Migration line 22 |
| BC-DB-08 | `estimated_time` | INT, NULLABLE | Integer minutes | Migration line 23 |
| BC-DB-09 | `stop_type` | ENUM('Both','Drop','Pickup'), DEFAULT 'Both' | Must match enum (order: Both,Drop,Pickup) | Migration line 24 |
| BC-DB-10 | `is_active` | BOOLEAN/TINYINT, DEFAULT true | NOT NULL | Migration line 25 |
| BC-DB-11 | `shift_id` | INT UNSIGNED, NOT NULL | FK → `tpt_shift.id` ON DELETE CASCADE (`fk_pickupPoint_shiftId`) | Migration lines 30-31 |
| BC-DB-12 | SPATIAL INDEX | `location` column | `sp_idx_pickup_location` | Migration line 40 |
| BC-DB-13 | Soft Deletes | `deleted_at` TIMESTAMP NULL | `$table->softDeletes()` | Migration line 37 |

### BC-VAL: Validation Conditions — `PickupPointRequest`

| ID | Field | Rule | Source |
|----|-------|------|--------|
| BC-VAL-01 | `code` | required, string, max:50, unique:tpt_pickup_points,code (ignore $pickupPointId) | `PickupPointRequest.php:24-29` |
| BC-VAL-02 | `name` | required, string, max:200, unique:tpt_pickup_points,name (ignore $pickupPointId) | `PickupPointRequest.php:31-36` |
| BC-VAL-03 | `location` | required, string, max:255 | `PickupPointRequest.php:39-43` |
| BC-VAL-04 | `latitude` | nullable, numeric, between:-90,90 | `PickupPointRequest.php:46-50` |
| BC-VAL-05 | `longitude` | nullable, numeric, between:-180,180 | `PickupPointRequest.php:52-56` |
| BC-VAL-06 | `total_distance` | nullable, numeric, min:0, max:9999.99 | `PickupPointRequest.php:59-64` |
| BC-VAL-07 | `estimated_time` | nullable, integer, min:0 | `PickupPointRequest.php:67-71` |
| BC-VAL-08 | `stop_type` | required, in: Pickup/Drop/Both | `PickupPointRequest.php:73-76` |
| BC-VAL-09 | `shift_id` | required, exists:tpt_shift,id | `PickupPointRequest.php:78-81` |
| BC-VAL-10 | `is_active` | required, boolean (normalized in prepareForValidation) | `PickupPointRequest.php:83-86` |
| BC-VAL-11 | **GAP**: `location` in DDL is POINT spatial type but validated as `string` | Spatial data not handled in form | DDL vs Request mismatch |
| BC-VAL-12 | `prepareForValidation()` normalizes checkbox `is_active` | `$this->has('is_active') && $this->input('is_active') === 'on'` | `PickupPointRequest.php:90-96` |

### BC-AUTH: Authorization Conditions

| ID | Permission | Controller Gate | Source |
|----|-----------|-----------------|--------|
| BC-AUTH-01 | `tenant.pickup-point.viewAny` | Tab: `Gate::any([...tenant.pickup-point.viewAny...])` in `TransportMasterController::index()` (line 28-41); Standalone: `/pickup-point` route gate is `view` not `viewAny` (see BC-AUTH-02 anomaly) | `TransportMasterController.php:28-41`, `PickupPointPolicy.php:13-15` |
| BC-AUTH-02 | `tenant.pickup-point.view` (NOT viewAny) | Standalone `PickupPointController::index()` uses `view` — **ANOMALY** (gold standard says `index()` should use `viewAny`) | `PickupPointController.php:18` |
| BC-AUTH-03 | `tenant.pickup-point.view` (NOT restore) | `trashed()` uses `view` — **ANOMALY** (gold standard says use `restore`) | `PickupPointController.php:156` |
| BC-AUTH-04 | `tenant.pickup-point.create` | `create()`, `store()` | `PickupPointController.php:86,97` |
| BC-AUTH-05 | `tenant.pickup-point.edit` (NOT update) | `edit()`, `update()`, `toggleStatus()` use `edit` — **ANOMALY** | `PickupPointController.php:112,124,201` |
| BC-AUTH-06 | `tenant.pickup-point.delete` | `destroy()`, `forceDelete()` | `PickupPointController.php:140,182` |
| BC-AUTH-07 | `tenant.pickup-point.restore` | `restore()` | `PickupPointController.php:166` |
| BC-AUTH-08 | **MISSING**: `getPickupPointsByShift()` has NO Gate | No auth check | `PickupPointController.php:42` — **ANOMALY** |
| BC-AUTH-09 | `PickupPointRequest@authorize()` uses `update` but controller uses `edit` | **MISMATCH**: Request checks `tenant.pickup-point.update`, controller gates check `tenant.pickup-point.edit` | `PickupPointRequest.php:16` vs controller lines 112,124,201 |
| BC-AUTH-10 | `update()` policy method exists but controller never calls it | Policy has `tenant.pickup-point.update` permission, controller uses `tenant.pickup-point.edit` | `PickupPointPolicy.php:46-48` — **ANOMALY** |
| BC-AUTH-11 | Policy has `status()`, `import()`, `export()`, `print()` methods never referenced in controller | `PickupPointPolicy.php:29-97` | Unused policy methods — dead code |
| BC-AUTH-12 | `forceDelete()` uses `delete` permission, not `forceDelete` | Controller uses `tenant.pickup-point.delete` but policy has `forceDelete` | `PickupPointController.php:182` vs `PickupPointPolicy.php:70-73` |

### BC-BIZ: Business Conditions

| ID | Condition | Expected | Source |
|----|-----------|----------|--------|
| BC-BIZ-01 | Delete does NOT set `is_active=false` before soft-delete | **Inconsistent** with other entities (Route/Shift set false first) | `PickupPointController.php:142-143` |
| BC-BIZ-02 | `forceDelete()` uses `onlyTrashed()` not `withTrashed()` | **Inconsistent** — will fail for non-trashed records | `PickupPointController.php:184` |
| BC-BIZ-03 | `getPickupPointsByShift()` returns JSON with location data | AJAX endpoint for map | `PickupPointController.php:42-71` |
| BC-BIZ-04 | `index()` uses `tenant.pickup-point.view` instead of `viewAny` | Gate inconsistency | `PickupPointController.php:18` |
| BC-BIZ-05 | `destroy()` redirects to `transport.transport-master.index` (hub) not `transport.pickup-point.index` | Redirect to hub tab page | `PickupPointController.php:149` |
| BC-BIZ-06 | `forceDelete()` redirects to `transport.pickup-point.index` (standalone) not hub | **Inconsistent** with `destroy()` redirect | `PickupPointController.php:191` |
| BC-BIZ-07 | `toggleStatus()` uses route-model binding `PickupPoint $pickupPoint` | Unlike other CRUD methods which use `$id` + `findOrFail` | `PickupPointController.php:199` |
| BC-BIZ-08 | Hub `pickupPointsQuery()` also searches `location` field (not just name/code) | Search includes location | `TransportMasterController.php:313-316` |
| BC-BIZ-09 | `store()` redirects to hub (`transport.transport-master.index`) | Consistent with destroy | `PickupPointController.php:105` |
| BC-BIZ-10 | `restore()` redirects to hub | Consistent | `PickupPointController.php:175` |

### BC-REF: Reference & UI Conditions

| ID | Condition | Source |
|----|-----------|--------|
| BC-REF-01 | Tab id `trans_stops-pane` in transportmaster, hidden input `tab=trans_stops` | `pickup_point/index.blade.php:2,9` |
| BC-REF-02 | Shift filter dropdown + pickup_drop type filter + status filter | `pickup_point/index.blade.php:13-37` |
| BC-REF-03 | Shift display via `optional($point->shift)->name ?? '-'` | `pickup_point/index.blade.php:76` |
| BC-REF-04 | Route column header AND cell both commented out | `<th>` at line 60, `<td>` at line 75 |
| BC-REF-05 | Flash messages as plain strings (not flash() helper) | "Pickup Point added successfully." etc. |
| BC-REF-06 | Status toggle via `<x-backend.table.status-switch>` generic component | `pickup_point/index.blade.php:79` |
| BC-REF-07 | Action column gated with `@canany(['tenant.pickup-point.edit', 'tenant.pickup-point.delete'])` | `pickup_point/index.blade.php:64,81` |
| BC-REF-08 | Trash page uses `<x-backend.table.action-trashed>` | `pickup_point/trash.blade.php:38` |
| BC-REF-09 | Google Maps Places Autocomplete on location input in create/edit | `create.blade.php:200-206` |

---

## 6. Test Case List

### TC-P: Positive

| ID | Test Case | Summary | Expected |
|----|-----------|---------|----------|
| TC-P-01 | Create stop with all fields | code, name, location, lat/lng, shift, stop_type=Both | Created, activity log "Created" |
| TC-P-02 | Create stop with minimum fields | code, name, location, shift_id, stop_type | Created with defaults (is_active=true, stop_type=Both) |
| TC-P-03 | Create stop with lat/lng boundaries | lat=90, lng=180 | Valid (boundary values) |
| TC-P-04 | Edit stop details | Change code/name | Updated, activity log "Updated" |
| TC-P-05 | Toggle status | Click switch | AJAX success |
| TC-P-06 | View stop details | Show page | All fields displayed |
| TC-P-07 | Restore soft-deleted stop | Trash → Restore | Restored, activity log "Restored" |
| TC-P-08 | Permanently delete (forceDelete) trashed stop | Trash → Force Delete | Permanently deleted, activity log "Deleted Permanently" |
| TC-P-09 | View trashed stops page | Navigate to trash | Lists soft-deleted records with Restore/ForceDelete actions |
| TC-P-10 | Toggle status — activate/inactivate | Click status switch | AJAX success, `is_active` toggled, activity log "Status Toggled" |
| TC-P-11 | Create with negative latitude | lat=-90, lng=0 | Valid boundary |
| TC-P-12 | Create with negative longitude | lat=0, lng=-180 | Valid boundary |
| TC-P-13 | Search hub by location text | enter location text | Matches on `location` field |

### TC-N: Negative

| ID | Test Case | Summary | Expected |
|----|-----------|---------|----------|
| TC-N-01 | Create with empty code | No code | "The code field is required." |
| TC-N-02 | Create with duplicate code | Existing code | "The code has already been taken." |
| TC-N-03 | Create with duplicate name | Existing name | "The name has already been taken." |
| TC-N-04 | Create with invalid stop_type | stop_type="Invalid" | "The selected stop type is invalid." |
| TC-N-05 | Create with invalid shift_id | shift_id=99999 | "The selected shift id is invalid." |
| TC-N-06 | Create with latitude > 90 | lat=95 | "The latitude must be between -90 and 90." |
| TC-N-07 | Create with longitude < -180 | lng=-200 | "The longitude must be between -180 and 180." |
| TC-N-08 | Access without `tenant.pickup-point.view` | No view permission → `index()`, `show()` | 403 |
| TC-N-09 | Access without `tenant.pickup-point.create` | No create permission → `create()`, `store()` | 403 |
| TC-N-10 | Access without `tenant.pickup-point.edit` | No edit permission → `edit()`, `update()`, `toggleStatus()` | 403 |
| TC-N-11 | Access without `tenant.pickup-point.delete` | No delete permission → `destroy()`, `forceDelete()` | 403 |
| TC-N-12 | Access without `tenant.pickup-point.restore` | No restore permission → `restore()` | 403 |
| TC-N-13 | Access without `tenant.pickup-point.view` → `trashed()` | No view permission | 403 |
| TC-N-14 | Code > 50 chars | code="A"...x51 | "The code must not be greater than 50." |
| TC-N-15 | Name > 200 chars | name="B"...x201 | "The name must not be greater than 200." |
| TC-N-16 | Location > 255 chars | location="C"...x256 | "The location must not be greater than 255." |
| TC-N-17 | total_distance negative | total_distance=-1 | "The total distance must be at least 0." |
| TC-N-18 | estimated_time negative | estimated_time=-5 | "The estimated time must be at least 0." |
| TC-N-19 | total_distance > 9999.99 | total_distance=10000 | "The total distance must not be greater than 9999.99." |
| TC-N-20 | Access `getPickupPointsByShift()` with invalid shift_id | shift_id=99999 | Empty data array returned |

### TC-D: Data Integrity

| ID | Test Case | Summary | Expected |
|----|-----------|---------|----------|
| TC-D-01 | Delete stop — verify is_active NOT set to false | No pre-delete deactivation | `is_active` unchanged, `deleted_at` set |
| TC-D-02 | Force delete non-trashed record | Call forceDelete on active record | Fails — `onlyTrashed()` won't find it |
| TC-D-03 | Verify shift CASCADE delete | Delete shift with stops | Stops also deleted (CASCADE) |
| TC-D-04 | **GAP**: location validated as string but DDL is POINT spatial | Form treats location as text | Spatial data handled inconsistently |
| TC-D-05 | `destroy()` redirects to hub (`transport.transport-master.index`) not `transport.pickup-point.index` | Redirect behavior | `PickupPointController.php:149` |
| TC-D-06 | `forceDelete()` redirects to `transport.pickup-point.index` (standalone) — inconsistent with `destroy()` | Redirect inconsistency | `PickupPointController.php:191` |
| TC-D-07 | `toggleStatus()` uses route-model binding — method signature `toggleStatus(Request $request, PickupPoint $pickupPoint)` | Unlike other CRUD methods using `$id` | `PickupPointController.php:199` |
| TC-D-08 | `toggleStatus()` direct assignment $request->is_active (no boolean helper) | `$pickupPoint->is_active = $request->is_active` | `PickupPointController.php:205` |
| TC-D-09 | Model default attributes: is_active=true, stop_type='Both' | Values set when not provided | `PickupPoint.php:49-52` |
| TC-D-10 | Unique constraint `uq_pickup_code` at DB level | Duplicate code insert via DB query | Integrity constraint violation |

### TC-CR: Code Review

| ID | Test Case | Source | Expected |
|----|-----------|--------|----------|
| TC-CR-01 | **ANOMALY**: `index()` uses `view` not `viewAny` | `PickupPointController.php:18` | Should use `viewAny` for consistency |
| TC-CR-02 | **ANOMALY**: `edit()`/`update()`/`toggleStatus()` use `edit` not `update` | `PickupPointController.php:112,124,201` | Permission name mismatch with other entities |
| TC-CR-03 | **ANOMALY**: `forceDelete()` uses `delete` not `forceDelete` | `PickupPointController.php:182` | Wrong permission check |
| TC-CR-04 | **ANOMALY**: No `is_active=false` before delete | `PickupPointController.php:142-143` | Inconsistent with Route/Shift/Vehicle pattern |
| TC-CR-05 | **ANOMALY**: `forceDelete()` uses `onlyTrashed()` not `withTrashed()` | `PickupPointController.php:184` | Will fail for non-trashed or already-force-deleted |
| TC-CR-06 | `toggleStatus()` — no `$request->boolean()` helper | `PickupPointController.php:205` | Direct assignment `$request->is_active` |
| TC-CR-07 | `activityLog()` present on store/update/destroy/restore/forceDelete/toggleStatus | All methods | Correct log messages |
| TC-CR-08 | `PickupPointRequest@authorize()` POST vs non-POST | `PickupPointRequest.php:12-17` | create vs update |
| TC-CR-09 | `prepareForValidation()` checkbox normalization | `PickupPointRequest.php:90-96` | `$this->has() && $this->input() === 'on'` |
| TC-CR-10 | `$fillable` — location, latitude, longitude, total_distance, estimated_time | `PickupPoint.php:19-30` | Matches DDL except location is string (DDL is POINT) |
| TC-CR-11 | DDL location is POINT SRID 4326 — model treats as string | Migration line 21 vs `PickupPoint.php:25` | **CRITICAL GAP**: Spatial type mismatch |
| TC-CR-12 | Route: `get-by-shift` AJAX endpoint | `routes/web.php` | `pickup-point.get-by-shift` |
| TC-CR-13 | Shift eager-loaded with `optional()` null-safe | `pickup_point/index.blade.php:76` | `optional($point->shift)->name ?? '-'` |
| TC-CR-14 | **ANOMALY**: `trashed()` uses `tenant.pickup-point.view` instead of `restore` | `PickupPointController.php:156` | Gold standard: `trashed()` should use `restore` permission — **MISSING** |
| TC-CR-15 | **MISMATCH**: `PickupPointRequest@authorize()` uses `tenant.pickup-point.update` but controller uses `tenant.pickup-point.edit` | `PickupPointRequest.php:16` vs `PickupPointController.php:112,124,201` | `update` vs `edit` — **Gate NEVER fires** on policy's `update()` method |
| TC-CR-16 | **MISSING GATE**: `getPickupPointsByShift()` has NO `Gate::authorize()` | `PickupPointController.php:42` | Unauthenticated users can access JSON endpoint |
| TC-CR-17 | `toggleStatus()` uses route-model binding vs `$id` pattern | `PickupPointController.php:199` | Signature: `toggleStatus(Request $request, PickupPoint $pickupPoint)` — implicit findOrFail |
| TC-CR-18 | Policy has `status()`, `import()`, `export()`, `print()` methods never referenced in controller | `PickupPointPolicy.php:29-97` | Unused policy methods — dead code |
| TC-CR-19 | `toggleStatus()` activity log message is plain string (not flash helper) | `PickupPointController.php:215` | `'message' => 'Pickup Point status updated.'` |
| TC-CR-20 | `create()` loads `Route::active()->get()` and `Shift::active()->get()` | `PickupPointController.php:88-89` | Uses scopeActive |
| TC-CR-21 | `edit()` loads `Route::active()->get()` and `Shift::active()->get()` | `PickupPointController.php:115-116` | Same pattern |
| TC-CR-22 | `forceDelete()` redirects to standalone index NOT hub | `PickupPointController.php:191` | **Inconsistency**: all others redirect to hub |
| TC-CR-23 | `restore()` uses `onlyTrashed()->findOrFail($id)` | `PickupPointController.php:168` | Correct for restore |
| TC-CR-24 | `PickupPointRequest` uses `$this->route('pickup_point')` for ignore on update | `PickupPointRequest.php:21` | Route-model-binding name |
| TC-CR-25 | `toggleStatus()` validates inline: `$request->validate(['is_active'=>'required|boolean'])` | `PickupPointController.php:203` | Inline, not FormRequest |

### BC-BIZ-DEEP: Deep Dive Business Conditions

| ID | Condition | Expected | Source |
|----|-----------|----------|--------|
| BC-BIZ-DEEP-01 | Model `$attributes` defaults: `is_active=true`, `stop_type='Both'` | Applied on create if not explicitly set | `PickupPoint.php:49-52` |
| BC-BIZ-DEEP-02 | Model `$casts`: latitude/longitude→decimal:7, total_distance→decimal:2, estimated_time→integer, is_active→boolean | Type-safe attribute access | `PickupPoint.php:35-44` |
| BC-BIZ-DEEP-03 | `getPickupPointsByShift()` casts lat/lng to float in map response | (float) cast ensures numeric JSON | `PickupPointController.php:54-55` |
| BC-BIZ-DEEP-04 | `getPickupPointsByShift()` filters by `is_active=1` AND `shift_id` | Only active stops for given shift | `PickupPointController.php:45-46` |
| BC-BIZ-DEEP-05 | `getPickupPointsByShift()` returns 12 fields including location text | Map display payload | `PickupPointController.php:48-63` |
| BC-BIZ-DEEP-06 | `store()` uses `$request->validated()` for mass assignment | All validated fields passed to create | `PickupPointController.php:99` |
| BC-BIZ-DEEP-07 | `update()` uses `$request->validated()` for mass assignment | Same pattern | `PickupPointController.php:127` |
| BC-BIZ-DEEP-08 | `destroy()` redirects to hub with flash 'Pickup Point moved to trash.' | Consistent redirect | `PickupPointController.php:149-150` |
| BC-BIZ-DEEP-09 | `index()` paginates 10 per page with `withQueryString()` | Maintains filter state | `PickupPointController.php:33` |
| BC-BIZ-DEEP-10 | Hub `pickupPointsQuery()` uses `->latest()` ordering | Newest first | `TransportMasterController.php:305` |
| BC-BIZ-DEEP-11 | Hub pickupPointsQuery uses `$request->filled()` for shift_id and pickup_drop filters | Different from `isset()` used in other tabs | `TransportMasterController.php:320,325` |
| BC-BIZ-DEEP-12 | Hub pickupPointsQuery uses `isset($request->status)` for status filter | 0-safe (distinguishes 0 from absent) | `TransportMasterController.php:330` |
| BC-BIZ-DEEP-13 | Tab container gate: `Gate::any([...'tenant.pickup-point.viewAny'...])` at hub level | User must have at least one transport permission | `TransportMasterController.php:28-41` |
| BC-BIZ-DEEP-14 | `show()` uses `PickupPoint::with(['route','shift'])->findOrFail($id)` | Proper 404 on missing | `PickupPointController.php:78` |
| BC-BIZ-DEEP-15 | `show()` view uses `optional($pickupPoint->shift)->name` for null-safe shift | Prevents null error on deleted shift | `show.blade.php:104-108` |
| BC-BIZ-DEEP-16 | `show()` displays coordinates with Google Maps link when lat+lng present | `https://www.google.com/maps?q=lat,lng` | `show.blade.php:170` |
| BC-BIZ-DEEP-17 | `show()` stop_type rendered with colored badges (Pickup=success, Drop=danger, Both=warning) | Visual type indicator | `show.blade.php:57-77` |
| BC-BIZ-DEEP-18 | `show()` timestamps formatted as `d M Y, h:i A` | Readable date display | `show.blade.php:190,197` |
| BC-BIZ-DEEP-19 | Create form has latitude/longitude READONLY — auto-filled by Google Maps API | User cannot manually type coordinates | `create.blade.php:76,86` |
| BC-BIZ-DEEP-20 | Create form total_distance and estimated_time READONLY — auto-calculated by Distance Matrix API | User cannot manually type | `create.blade.php:96-97,110-111` |
| BC-BIZ-DEEP-21 | Google Maps API uses Places Autocomplete library for location field | `libraries=places` | `create.blade.php:165` |
| BC-BIZ-DEEP-22 | Distance Matrix Service calculates driving distance in KM and time in minutes | `DRIVING` mode, `METRIC` units | `create.blade.php:236-237` |
| BC-BIZ-DEEP-23 | If geolocation permission denied → distance calculation blocked | Alert 'Location permission required' | `create.blade.php:192` |
| BC-BIZ-DEEP-24 | If place has no geometry → alert 'Please select location from dropdown' | No lat/lng → no distance | `create.blade.php:210-212` |
| BC-BIZ-DEEP-25 | `trashed()` uses `->paginate(10)` without `withQueryString()` | Pagination only (no filter appends) | `PickupPointController.php:158` |
| BC-BIZ-DEEP-26 | Trash blade shows Code, Name, Location, Latitude, Longitude, Stop Type, Action | Different columns from index | `trash.blade.php:14-23` |
| BC-BIZ-DEEP-27 | Trash action column gated by `@canany(['restore','forceDelete'])` | User must have either permission | `trash.blade.php:21,36` |
| BC-BIZ-DEEP-28 | Trash route column also commented out (same as index) | `{{-- <td>{{ $point->route->name ?? '-' }}</td> --}}` | `trash.blade.php:31` |
| BC-BIZ-DEEP-29 | Trash pagination does NOT append tab parameter | `$pickupPoints->links()` without appends | `trash.blade.php:54` |
| BC-BIZ-DEEP-30 | `toggleStatus()` JSON response includes `is_active` value | {success, is_active, message} | `PickupPointController.php:212-216` |
| BC-BIZ-DEEP-31 | `toggleStatus()` activity log uses `'Status Toggled'` event type | Distinct from other events | `PickupPointController.php:208` |
| BC-BIZ-DEEP-32 | `PickupPointRequest::authorize()` returns Gate::allows() directly (not Gate::authorize()) | Boolean return, no 403 thrown | `PickupPointRequest.php:13-16` |
| BC-BIZ-DEEP-33 | `PickupPointRequest::rules()` uses `Rule::unique(...)->ignore($pickupPointId)` | Ignores current record on update | `PickupPointRequest.php:28,35` |
| BC-BIZ-DEEP-34 | Hub index tab shows pagination links with `appends(['tab'=>request('tab','trans_stops')])` | Tab state preserved across pages | `pickup_point/index.blade.php:97` |
| BC-BIZ-DEEP-35 | Hub search bar form submits GET to `transport.pickup-point` but actual data loaded via hub | Search URL vs data source mismatch | `pickup_point/index.blade.php:7-8` |
| BC-BIZ-DEEP-36 | Index blade renders `@empty` state `No Data Found` with colspan=8 | Empty state matches column count | `pickup_point/index.blade.php:87-91` |
| BC-BIZ-DEEP-37 | Pickup Point create/edit form does NOT have a route_id field | Route relationship exists but user doesn't assign on form | `create.blade.php` — no route dropdown |
| BC-BIZ-DEEP-38 | `total_distance` in create/edit is auto-calculated from Google Distance Matrix | Not manually editable | `create.blade.php:251` |
| BC-BIZ-DEEP-39 | `estimated_time` in create/edit is auto-calculated from Google Duration | Rounded up with `Math.ceil()` | `create.blade.php:252` |
| BC-BIZ-DEEP-40 | `forceDelete()` behavior: after forceDelete, redirects to `transport.pickup-point.index` | Redirect to STANDALONE index, not hub | `PickupPointController.php:191` |
| BC-BIZ-DEEP-41 | `forceDelete()` calls `activityLog` AFTER forceDelete (record gone) | Log references now-deleted record | `PickupPointController.php:187-189` |
| BC-BIZ-DEEP-42 | `restore()` calls `activityLog` AFTER restore (record back) | Log references restored record | `PickupPointController.php:171-173` |
| BC-BIZ-DEEP-43 | `destroy()` calls `activityLog` BEFORE delete (record still exists) | Log references pre-delete record | `PickupPointController.php:145-147` |
| BC-BIZ-DEEP-44 | Index filters: shift_id uses `$request->filled()` in hub, but blank option value="" | When empty, no shift filter applied | `pickup_point/index.blade.php:14` |
| BC-BIZ-DEEP-45 | Status filter dropdown values: ""=All, "1"=Active, "0"=Inactive | String values compared with `request('status')` | `pickup_point/index.blade.php:33-37` |
| BC-BIZ-DEEP-46 | Reset button links to `transport.transport-master.index?tab=trans_stops` | Clears all filters | `pickup_point/index.blade.php:43-45` |
| BC-BIZ-DEEP-47 | `stop_type` ENUM values in migration order: `['Both','Drop','Pickup']` (alphabetical would be Both,Drop,Pickup) | MySQL enum order is both,Drop,Pickup | Migration line 24 |
| BC-BIZ-DEEP-48 | `show()` method name has Hindi comment: `// ✅ SHOW METHOD - YEH MISSING THA` | Dev note indicating show was added later | `PickupPointController.php:73` |
| BC-BIZ-DEEP-49 | `toggleStatus()` uses `$pickupPoint->save()` not `->update()` | Different persistence pattern | `PickupPointController.php:206` |
| BC-BIZ-DEEP-50 | `toggleStatus()` returns JSON response, not redirect | AJAX endpoint behavior | `PickupPointController.php:212-216` |
| BC-BIZ-DEEP-51 | `toggleStatus()` does NOT call activityLog for success | It DOES call activityLog at line 208 | `PickupPointController.php:208` |
| BC-BIZ-DEEP-52 | Hub index blade has Route column commented out in BOTH header AND cell | Inconsistent with other tabs that show route | `pickup_point/index.blade.php:60,75` |
| BC-BIZ-DEEP-53 | Model `route()` relationship uses `belongsTo(Route::class, 'route_id')` | But DDL has no `route_id` column — route relationship is conceptual only | `PickupPoint.php:73-75` |
| BC-BIZ-DEEP-54 | `getPickupPointsByShift()` returns `location` as text string, not spatial | No spatial query handled | `PickupPointController.php:59` |
| BC-BIZ-DEEP-55 | `getPickupPointsByShift()` returns `data` array, `count`, `success` | Standard JSON envelope | `PickupPointController.php:65-68` |

---

## 6a. CODE-TRACE: Controller Flow Analysis

### CODE-TRACE-01: store() flow — PickupPointController

| Step | Action | Code | Line |
|------|--------|------|------|
| 1 | Gate check | `Gate::authorize('tenant.pickup-point.create')` | 97 |
| 2 | Validation | `PickupPointRequest` runs rules() + authorize() + prepareForValidation() | 95 |
| 3 | Mass create | `PickupPoint::create($request->validated())` | 99 |
| 4 | Activity log | `activityLog($pickupPoint, 'Created', ['message'=>'Pickup Point created successfully.'])` | 101-103 |
| 5 | Redirect | `redirect()->route('transport.transport-master.index')->with('success', '...')` | 105-106 |

### CODE-TRACE-02: index() flow — PickupPointController

| Step | Action | Code | Line |
|------|--------|------|------|
| 1 | Gate check | `Gate::authorize('tenant.pickup-point.view')` | 18 |
| 2 | Base query | `PickupPoint::with(['route','shift'])` | 20 |
| 3 | Search filter | `if ($request->filled('search')) -> where(name LIKE or code LIKE)` | 22-27 |
| 4 | Status filter | `if ($request->filled('status')) -> where('is_active', $request->status)` | 29-31 |
| 5 | Paginate | `->paginate(10)->withQueryString()` | 33 |
| 6 | Return view | `view('transport::pickup_point.index', compact('pickupPoints'))` | 35 |

### CODE-TRACE-03: hub pickupPointsQuery() flow — TransportMasterController

| Step | Action | Code | Line |
|------|--------|------|------|
| 1 | Base query | `PickupPoint::with(['route','shift'])->latest()` | 305 |
| 2 | Tab guard | `if ($request->tab === 'trans_stops')` | 307 |
| 3 | Search filter | `where(name LIKE or code LIKE or location LIKE)` | 309-317 |
| 4 | Shift filter | `if ($request->filled('shift_id')) -> where('shift_id', ...)` | 320-322 |
| 5 | Stop type filter | `if ($request->filled('pickup_drop')) -> where('stop_type', ...)` | 325-327 |
| 6 | Status filter | `if (isset($request->status)) -> where('is_active', ...)` | 330-332 |
| 7 | Return to hub | Paginated and passed to `transportmaster` view | 74 |

### CODE-TRACE-04: getPickupPointsByShift() flow

| Step | Action | Code | Line |
|------|--------|------|------|
| 1 | **NO GATE** | Missing `Gate::authorize()` — **ANOMALY** | 42 |
| 2 | Query | `PickupPoint::where('shift_id', ...)->where('is_active', 1)->get()` | 45-47 |
| 3 | Map to array | 12 fields including (float) lat/lng, location text | 48-63 |
| 4 | JSON response | `{success: true, data: [...], count: N}` | 65-69 |

### CODE-TRACE-05: toggleStatus() flow

| Step | Action | Code | Line |
|------|--------|------|------|
| 1 | Route-model binding | `toggleStatus(Request $request, PickupPoint $pickupPoint)` | 199 |
| 2 | Gate check | `Gate::authorize('tenant.pickup-point.edit')` | 201 |
| 3 | Inline validation | `$request->validate(['is_active'=>'required|boolean'])` | 203 |
| 4 | Direct assignment | `$pickupPoint->is_active = $request->is_active` (NOT boolean()) | 205 |
| 5 | Save | `$pickupPoint->save()` | 206 |
| 6 | Activity log | `activityLog($pickupPoint, 'Status Toggled', ...)` | 208-210 |
| 7 | JSON response | `{success: true, is_active: ..., message: '...'}` | 212-216 |

### CODE-TRACE-06: destroy() soft-delete flow

| Step | Action | Code | Line |
|------|--------|------|------|
| 1 | Gate check | `Gate::authorize('tenant.pickup-point.delete')` | 140 |
| 2 | Find | `PickupPoint::findOrFail($id)` | 142 |
| 3 | **GAP**: No is_active=false before delete | Direct `->delete()` | 143 |
| 4 | Activity log | `activityLog($pickupPoint, 'Deleted', ['message'=>'Pickup Point moved to trash.'])` | 145-147 |
| 5 | Redirect to hub | `redirect()->route('transport.transport-master.index')->with('success', ...)` | 149-150 |

### CODE-TRACE-07: forceDelete() flow

| Step | Action | Code | Line |
|------|--------|------|------|
| 1 | Gate check | `Gate::authorize('tenant.pickup-point.delete')` — uses `delete` not `forceDelete` | 182 |
| 2 | **GAP**: onlyTrashed() | `PickupPoint::onlyTrashed()->findOrFail($id)` — won't find active records | 184 |
| 3 | Force delete | `$pickupPoint->forceDelete()` | 185 |
| 4 | Activity log | `activityLog($pickupPoint, 'Deleted Permanently', ...)` | 187-189 |
| 5 | Redirect to STANDALONE index | `redirect()->route('transport.pickup-point.index')` — **NOT hub** | 191 |

### CODE-TRACE-08: restore() flow

| Step | Action | Code | Line |
|------|--------|------|------|
| 1 | Gate check | `Gate::authorize('tenant.pickup-point.restore')` | 166 |
| 2 | Find trashed | `PickupPoint::onlyTrashed()->findOrFail($id)` | 168 |
| 3 | Restore | `$pickupPoint->restore()` | 169 |
| 4 | Activity log | `activityLog($pickupPoint, 'Restored', ...)` | 171-173 |
| 5 | Redirect to hub | `redirect()->route('transport.transport-master.index')` | 175 |

### CODE-TRACE-09: PickupPointRequest validation flow

| Step | Action | Code | Line |
|------|--------|------|------|
| 1 | authorize() POST | `Gate::allows('tenant.pickup-point.create')` | 13-14 |
| 2 | authorize() non-POST | `Gate::allows('tenant.pickup-point.update')` — **MISMATCH** with controller's `edit` | 16 |
| 3 | prepareForValidation() | Normalize is_active: `$this->has('is_active') && $this->input('is_active') === 'on'` | 90-96 |
| 4 | rules() code | required+string+max:50 + unique ignore $pickupPointId | 24-29 |
| 5 | rules() name | required+string+max:200 + unique ignore $pickupPointId | 31-36 |
| 6 | rules() location | required+string+max:255 | 39-43 |
| 7 | rules() lat/lng | nullable+numeric+between | 46-56 |
| 8 | rules() stop_type | required+in:Pickup/Drop/Both | 73-76 |
| 9 | rules() shift_id | required+exists:tpt_shift,id | 78-81 |
| 10 | rules() is_active | required+boolean | 83-86 |

---

## 7. Detailed Test Steps

### TC-P-01: Create stop with all fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.pickup-point.create` permission | Success |
| 2 | Navigate to Transport Master → click "Add" in Trans. Stops tab | GET to `/transport/pickup-point/create` |
| 3 | **Verify**: `Gate::authorize('tenant.pickup-point.create')` passes | Authorized |
| 4 | **Verify**: `Route::active()->get()` and `Shift::active()->get()` loaded | 2 dropdowns populated |
| 5 | **Verify**: Google Maps API script loaded with Places library | `libraries=places` in URL |
| 6 | Enter code = "MG-ROAD" | `<input name="code">` filled |
| 7 | Enter name = "MG Road Stop" | `<input name="name">` filled |
| 8 | Enter location = "MG Road, Bangalore" | Google Places Autocomplete activates |
| 9 | Select location from autocomplete dropdown | `place_changed` event fires |
| 10 | **Verify**: latitude auto-filled (readonly) | `latInput.value = place.geometry.location.lat()` |
| 11 | **Verify**: longitude auto-filled (readonly) | `lngInput.value = place.geometry.location.lng()` |
| 12 | **Verify**: total_distance auto-calculated (readonly) | Distance Matrix returns KM value |
| 13 | **Verify**: estimated_time auto-calculated (readonly) | Duration / 60, `Math.ceil()` |
| 14 | Select Stop Type = "Both" | `<select name="stop_type">` = "Both" |
| 15 | Select Shift = valid shift | `<select name="shift_id">` = valid ID |
| 16 | Ensure Active switch = ON | `is_active` normalized to true |
| 17 | Click "Add Pickup Point" | POST to `transport.pickup-point.store` |
| 18 | **Verify**: `PickupPointRequest@authorize()` returns true for POST | `Gate::allows('create')` passes |
| 19 | **Verify**: `prepareForValidation()` normalizes is_active | `has('is_active') && input === 'on'` → boolean |
| 20 | **Verify**: All rules pass (code, name, location, lat, lng, total_distance, estimated_time, stop_type, shift_id, is_active) | Validated |
| 21 | **Verify**: `Gate::authorize('tenant.pickup-point.create')` controller-level | Passes |
| 22 | **Verify**: `PickupPoint::create($request->validated())` | INSERT into tpt_pickup_points |
| 23 | DB check: `code` = "MG-ROAD" | Stored correctly |
| 24 | DB check: `name` = "MG Road Stop" | Stored correctly |
| 25 | DB check: `location` = text address string | Stored (not spatial POINT — GAP) |
| 26 | DB check: `latitude` = 12.9715987 (decimal:7) | Stored |
| 27 | DB check: `longitude` = 77.5945627 (decimal:7) | Stored |
| 28 | DB check: `stop_type` = "Both" | ENUM value |
| 29 | DB check: `shift_id` = valid FK | References tpt_shift |
| 30 | DB check: `is_active` = 1 | TRUE |
| 31 | DB check: `deleted_at` = NULL | Not soft-deleted |
| 32 | **Verify**: `activityLog()` called with `'Created'` event | Activity record created |
| 33 | **Verify**: Redirect to `transport.transport-master.index` | URL has `transport-master` |
| 34 | **Verify**: Flash message "Pickup Point added successfully." | Session success |
| 35 | Navigate to Trans. Stops tab | New stop visible in table |

### TC-P-02: Create stop with minimum fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to create form | Form loads |
| 2 | Enter code = "MIN" | Minimal valid code |
| 3 | Enter name = "Minimum Stop" | Minimal valid name |
| 4 | Enter location = "Test Location" | Text address |
| 5 | Select Stop Type = "Pickup" | Required |
| 6 | Select Shift = valid | Required |
| 7 | Leave lat/lng empty (don't use autocomplete) | NULL in DB |
| 8 | Leave total_distance, estimated_time empty | NULL in DB |
| 9 | Leave Active switch = default ON | Default true |
| 10 | Click Submit | Form POST |
| 11 | **Verify**: Validation passes for nullable fields | lat/lng/distance/time all nullable |
| 12 | **Verify**: `PickupPoint::create()` with provided fields + defaults | Row created |
| 13 | DB check: `latitude` = NULL | Nullable |
| 14 | DB check: `longitude` = NULL | Nullable |
| 15 | DB check: `total_distance` = NULL | Nullable |
| 16 | DB check: `estimated_time` = NULL | Nullable |
| 17 | DB check: `is_active` = 1 | Default from model `$attributes` |
| 18 | DB check: `stop_type` = "Pickup" | As selected (not default 'Both') |

### TC-P-03: Create stop with lat/lng boundaries

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create form with latitude=90, longitude=180 | Boundary values |
| 2 | **Verify**: Rule `between:-90,90` accepts 90 | Passes |
| 3 | **Verify**: Rule `between:-180,180` accepts 180 | Passes |
| 4 | Submit | Created successfully |
| 5 | DB check: `latitude` = 90.0000000 | decimal:7 precision |
| 6 | DB check: `longitude` = 180.0000000 | decimal:7 precision |

### TC-P-04: Edit stop details

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to Trans. Stops list | Existing stop visible |
| 2 | Click edit icon | GET to `/transport/pickup-point/{id}/edit` |
| 3 | **Verify**: `Gate::authorize('tenant.pickup-point.edit')` passes | Authorized |
| 4 | **Verify**: `PickupPoint::findOrFail($id)` loads record | Form pre-filled |
| 5 | **Verify**: `Route::active()->get()`, `Shift::active()->get()` loaded | Dropdowns |
| 6 | Change code from "MG-ROAD" to "MG-ROAD-UPDATED" | Updated input |
| 7 | Change name to "MG Road Updated" | Updated input |
| 8 | Change Stop Type to "Drop" | From "Both" |
| 9 | Click "Update Pickup Point" | PUT to `transport.pickup-point.update` |
| 10 | **Verify**: `PickupPointRequest@authorize()` for non-POST | `Gate::allows('update')` |
| 11 | **Verify**: `Rule::unique(...)->ignore($pickupPointId)` | Unique check excludes current ID |
| 12 | **Verify**: `Gate::authorize('tenant.pickup-point.edit')` controller-level | Passes |
| 13 | **Verify**: `$pickupPoint->update($request->validated())` | DB updated |
| 14 | DB check: `code` = "MG-ROAD-UPDATED" | Updated |
| 15 | DB check: `name` = "MG Road Updated" | Updated |
| 16 | DB check: `stop_type` = "Drop" | Changed from "Both" |
| 17 | **Verify**: `activityLog()` called with `'Updated'` event | Activity record |
| 18 | **Verify**: Redirect to hub with "Pickup Point updated successfully." | Success |

### TC-P-05: Toggle status ON→OFF

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to Trans. Stops tab | Stop with status=Active visible |
| 2 | Click the status toggle switch | AJAX POST to `transport.pickup-point.toggleStatus` |
| 3 | **Verify**: `toggleStatus(Request, PickupPoint $pickupPoint)` route-model binding | Auto-resolved model |
| 4 | **Verify**: `Gate::authorize('tenant.pickup-point.edit')` | Authorized |
| 5 | **Verify**: `$request->validate(['is_active'=>'required|boolean'])` | `is_active` sent as "0" or false |
| 6 | **Verify**: `$pickupPoint->is_active = $request->is_active` | Direct assignment (not boolean()) |
| 7 | **Verify**: `$pickupPoint->save()` | Persisted |
| 8 | **Verify**: `activityLog(..., 'Status Toggled', ...)` | Activity logged |
| 9 | **Verify**: JSON response `{success: true, is_active: 0, message: 'Pickup Point status updated.'}` | 200 OK |
| 10 | **Verify**: Toggle switch UI updates to OFF | Front-end state change |

### TC-P-06: View stop details

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to Trans. Stops list | Table visible |
| 2 | Click view/show icon | GET to `/transport/pickup-point/{id}` |
| 3 | **Verify**: `Gate::authorize('tenant.pickup-point.view')` | Authorized |
| 4 | **Verify**: `PickupPoint::with(['route','shift'])->findOrFail($id)` | Record+relations loaded |
| 5 | **Verify**: Code displayed with badge | `badge-info` |
| 6 | **Verify**: Name displayed bold | `<strong>` tag |
| 7 | **Verify**: Location displayed | Text value |
| 8 | **Verify**: Stop Type badge color correct (Pickup=green, Drop=red, Both=orange) | Conditional CSS |
| 9 | **Verify**: Total Distance shown as "X km" or "-" if null | Icon + value |
| 10 | **Verify**: Estimated Time shown as "X minutes" or "-" if null | Icon + value |
| 11 | **Verify**: Shift name + code displayed | `badge-success` with code subtitle |
| 12 | **Verify**: Status badge Active/Inactive | Icon + text |
| 13 | **Verify**: Latitude and Longitude in `<code>` block | Code formatting |
| 14 | **Verify**: Google Maps link present if lat+lng | `href="https://www.google.com/maps?q=lat,lng"` |
| 15 | **Verify**: Created_at formatted `d M Y, h:i A` | Timestamp display |
| 16 | **Verify**: Updated_at formatted similarly | Timestamp display |
| 17 | **Verify**: Edit button gated by `@can('tenant.pickup-point.edit')` | Conditional render |

### TC-P-07: Restore soft-deleted stop

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to trash page `/transport/pickup-point/trash` | Trash listing |
| 2 | **Verify**: `Gate::authorize('tenant.pickup-point.view')` — uses view, not restore (**ANOMALY**) | Authorized |
| 3 | **Verify**: `PickupPoint::onlyTrashed()->paginate(10)` | Only trashed records |
| 4 | Click "Restore" on a trashed stop | GET to `/transport/pickup-point/{id}/restore` |
| 5 | **Verify**: `Gate::authorize('tenant.pickup-point.restore')` | Authorized |
| 6 | **Verify**: `PickupPoint::onlyTrashed()->findOrFail($id)` | Found only if trashed |
| 7 | **Verify**: `$pickupPoint->restore()` | `deleted_at` = NULL |
| 8 | **Verify**: `activityLog(..., 'Restored', ...)` | Activity logged |
| 9 | **Verify**: Redirect to hub with "Pickup Point restored successfully." | Success |
| 10 | DB check: `deleted_at` = NULL | Restored |
| 11 | DB check: `is_active` unchanged | Same as before delete |

### TC-P-08: Force delete trashed stop

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to trash page | Trashed records listed |
| 2 | Click "Force Delete" on a trashed stop | GET to `/transport/pickup-point/{id}/force-delete` |
| 3 | **Verify**: `Gate::authorize('tenant.pickup-point.delete')` — uses delete, not forceDelete | Authorized |
| 4 | **Verify**: `PickupPoint::onlyTrashed()->findOrFail($id)` | Found only if already trashed |
| 5 | **Verify**: `$pickupPoint->forceDelete()` | Permanently deleted |
| 6 | **Verify**: `activityLog(..., 'Deleted Permanently', ...)` | Activity logged |
| 7 | **Verify**: Redirect to `transport.pickup-point.index` — **NOT hub (ANOMALY)** | Standalone index |
| 8 | DB check: record removed from `tpt_pickup_points` | Gone |

### TC-P-09: View trashed stops page

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to `/transport/pickup-point/trash` | Trash page |
| 2 | **Verify**: `Gate::authorize('tenant.pickup-point.view')` | Authorized |
| 3 | **Verify**: Only soft-deleted records shown | `deleted_at` IS NOT NULL |
| 4 | **Verify**: Paginated at 10 per page | `->paginate(10)` |
| 5 | **Verify**: Columns: Code, Name, Location, Latitude, Longitude, Stop Type, Action | Correct columns |
| 6 | **Verify**: Action column gated by `@canany(['restore','forceDelete'])` | Conditional |
| 7 | **Verify**: Pagination links present | `$pickupPoints->links()` |
| 8 | **Verify**: Route column commented out | `{{-- ... --}}` |

### TC-P-10: Toggle status OFF→ON (activate)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Find stop with is_active=0 (Inactive) | Inactive stop |
| 2 | Click toggle switch | AJAX POST |
| 3 | **Verify**: `$request->is_active` = "1" (from switch) | Boolean rule passes |
| 4 | **Verify**: `$pickupPoint->is_active = "1"` | Set to "1" |
| 5 | **Verify**: `$pickupPoint->save()` | DB updated |
| 6 | **Verify**: JSON response `is_active: 1` | Returns new value |
| 7 | DB check: `is_active` = 1 | Toggled ON |

### TC-P-11: Create with negative latitude

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create form with latitude = -90 | From autocomplete or manual |
| 2 | **Verify**: `between:-90,90` accepts -90 | Passes |
| 3 | Submit | Created |
| 4 | DB check: `latitude` = -90.0000000 | Stored |

### TC-P-12: Create with negative longitude

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create form with longitude = -180 | Valid |
| 2 | **Verify**: `between:-180,180` accepts -180 | Passes |
| 3 | Submit | Created |

### TC-P-13: Search hub by location text

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to hub Trans. Stops tab | Tab loaded |
| 2 | Enter location search text in search bar | Search input |
| 3 | Click search | GET with `tab=trans_stops&search=...` |
| 4 | **Verify**: Hub query: `where('location', 'LIKE', '%text%')` | Matches location |
| 5 | **Verify**: Standalone controller (PickupPointController) does NOT search location | Only hub searches location |

### TC-N-01: Create with empty code

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create form with code="" (empty) | Required field missing |
| 2 | Fill all other fields valid | All others OK |
| 3 | Click Submit | Validation fails |
| 4 | **Verify**: Rule `required` on code | "The code field is required." |

### TC-N-02: Create with duplicate code

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Existing stop with code="MG-ROAD" | In DB |
| 2 | Create form with same code="MG-ROAD" | Duplicate |
| 3 | Click Submit | Validation fails |
| 4 | **Verify**: `Rule::unique('tpt_pickup_points', 'code')` | "The code has already been taken." |

### TC-N-03: Create with duplicate name

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Existing stop with name="MG Road Stop" | In DB |
| 2 | Create form with same name="MG Road Stop" | Duplicate |
| 3 | Click Submit | Validation fails |
| 4 | **Verify**: `Rule::unique('tpt_pickup_points', 'name')` | "The name has already been taken." |

### TC-N-04: Create with invalid stop_type

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create form with stop_type="Invalid" | Not in enum |
| 2 | Click Submit | Validation fails |
| 3 | **Verify**: `Rule::in(['Pickup','Drop','Both'])` | "The selected stop type is invalid." |

### TC-N-05: Create with invalid shift_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create form with shift_id=99999 | Non-existent |
| 2 | Click Submit | Validation fails |
| 3 | **Verify**: `exists:tpt_shift,id` | "The selected shift id is invalid." |

### TC-N-06: Create with latitude > 90

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create form with latitude=95 | Over max |
| 2 | Click Submit | Validation fails |
| 3 | **Verify**: `between:-90,90` | "The latitude must be between -90 and 90." |

### TC-N-07: Create with longitude < -180

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create form with longitude=-200 | Under min |
| 2 | Click Submit | Validation fails |
| 3 | **Verify**: `between:-180,180` | "The longitude must be between -180 and 180." |

### TC-N-08: Access index without view permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user WITHOUT `tenant.pickup-point.view` | No view permission |
| 2 | Navigate to transport-master → Trans. Stops tab | Tab container shows but data query may still fail |
| 3 | Navigate directly to `/transport/pickup-point` | `Gate::authorize('tenant.pickup-point.view')` → **403** |

### TC-N-09: Access create without create permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login WITHOUT `tenant.pickup-point.create` | No create permission |
| 2 | Navigate to `/transport/pickup-point/create` | `Gate::authorize('create')` → 403 |
| 3 | POST to `/transport/pickup-point` with valid data | `PickupPointRequest@authorize()` returns false → 403 |

### TC-N-10: Access edit without edit permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login WITHOUT `tenant.pickup-point.edit` | No edit permission |
| 2 | Navigate to `/transport/pickup-point/{id}/edit` | `Gate::authorize('edit')` → 403 |
| 3 | PUT to `/transport/pickup-point/{id}` | `PickupPointRequest@authorize()` checks `update` → false → 403 |
| 4 | POST to toggleStatus | `Gate::authorize('edit')` → 403 |

### TC-N-11: Access delete without delete permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login WITHOUT `tenant.pickup-point.delete` | No delete permission |
| 2 | DELETE to `/transport/pickup-point/{id}` | `Gate::authorize('delete')` → 403 |
| 3 | GET to `/transport/pickup-point/{id}/force-delete` | `Gate::authorize('delete')` → 403 |

### TC-N-12: Access restore without restore permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login WITHOUT `tenant.pickup-point.restore` | No restore permission |
| 2 | GET to `/transport/pickup-point/{id}/restore` | `Gate::authorize('restore')` → 403 |

### TC-N-13: Access trashed without view permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login WITHOUT `tenant.pickup-point.view` | No view permission |
| 2 | Navigate to `/transport/pickup-point/trash` | `Gate::authorize('view')` → 403 |

### TC-N-14: Code > 50 characters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create form with code = 51-character string | Over max |
| 2 | Click Submit | Validation fails |
| 3 | **Verify**: `max:50` | "The code must not be greater than 50 characters." |

### TC-N-15: Name > 200 characters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create form with name = 201-character string | Over max |
| 2 | Click Submit | Validation fails |
| 3 | **Verify**: `max:200` | "The name must not be greater than 200 characters." |

### TC-N-16: Location > 255 characters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create form with location = 256-character string | Over max |
| 2 | Click Submit | Validation fails |
| 3 | **Verify**: `max:255` | "The location must not be greater than 255 characters." |

### TC-N-17: total_distance negative

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Manipulate total_distance = -1 | Negative value (bypass readonly) |
| 2 | Click Submit | Validation fails |
| 3 | **Verify**: `min:0` | "The total distance must be at least 0." |

### TC-N-18: estimated_time negative

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Manipulate estimated_time = -5 | Negative value (bypass readonly) |
| 2 | Click Submit | Validation fails |
| 3 | **Verify**: `integer`, `min:0` | "The estimated time must be at least 0." |

### TC-N-19: total_distance > 9999.99

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Manipulate total_distance = 10000 | Over max |
| 2 | Click Submit | Validation fails |
| 3 | **Verify**: `max:9999.99` | "The total distance must not be greater than 9999.99." |

### TC-N-20: getPickupPointsByShift with invalid shift

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Call GET `/transport/pickup-point/get-by-shift?shift_id=99999` | AJAX |
| 2 | **Verify**: No Gate check — accessible by anyone (**ANOMALY**) | No authorization |
| 3 | **Verify**: Query returns empty collection | No matching records |
| 4 | **Verify**: JSON `{success: true, data: [], count: 0}` | Empty response |

### TC-D-01: Delete stop — verify is_active unchanged

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Note is_active value of stop X | e.g., is_active = 1 |
| 2 | Call destroy(X) | Soft delete |
| 3 | **Verify**: `$pickupPoint->delete()` called directly | No is_active=false before delete |
| 4 | DB check: `SELECT is_active, deleted_at FROM tpt_pickup_points WHERE id = X` | `is_active=1`, `deleted_at` IS NOT NULL |
| 5 | **Compare** with Route/Shift pattern that sets is_active=false first | **GAP**: inconsistent behavior |

### TC-D-02: Force delete non-trashed record

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create stop X (active, not deleted) | deleted_at = NULL |
| 2 | Call forceDelete(X) | Controller hit |
| 3 | **Verify**: `PickupPoint::onlyTrashed()->findOrFail($id)` | `onlyTrashed()` → WHERE deleted_at IS NOT NULL |
| 4 | Active record has deleted_at=NULL → not found | `findOrFail()` throws ModelNotFoundException |
| 5 | **Verify**: 404 "No query results" | Error page |
| 6 | **Compare** with correct pattern: `withTrashed()` would find active records | **GAP**: forceDelete unusable on active records |

### TC-D-03: Verify CASCADE on shift delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Count pickup points for shift_id=S1 | e.g., 5 points |
| 2 | Delete Shift S1 from DB | `DELETE FROM tpt_shift WHERE id=S1` |
| 3 | Verify FK `fk_pickupPoint_shiftId` has `ON DELETE CASCADE` | Migration line 31 |
| 4 | **Verify**: All 5 points for shift S1 auto-deleted | COUNT=0 |
| 5 | **Note**: Test at DB level; UI delete through Shift controller also cascades | CASCADE behavior |

### TC-D-04: GAP — location validated as string vs POINT spatial

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | DDL: `$table->geometry('location', 'point', 4326)` | Spatial POINT with SRID 4326 |
| 2 | Request: `'location' => ['required', 'string', 'max:255']` | Validated as plain string |
| 3 | Model `$fillable: 'location'` | Stored as string in location column |
| 4 | **GAP**: Spatial type expects POINT geometry data but form sends text string | Inconsistent — POINT never constructed |
| 5 | **Impact**: Spatial index on location column may store string data as POINT | Potential MySQL spatial type mismatch |

### TC-D-05: destroy() redirects to hub

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Call destroy($id) | Controller line 138-151 |
| 2 | **Verify**: `redirect()->route('transport.transport-master.index')` | Redirect to HUB (transport-master) |
| 3 | Flash: "Pickup Point moved to trash." | Session message |

### TC-D-06: forceDelete() redirect inconsistency

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Call forceDelete($id) | Controller line 180-193 |
| 2 | **Verify**: `redirect()->route('transport.pickup-point.index')` | Redirect to STANDALONE index |
| 3 | Compare with destroy() which redirects to hub (`transport-master.index`) | **INCONSISTENT** |
| 4 | **Impact**: After forceDelete, user sees standalone pickup point listing, not hub | Different UX |

### TC-D-07: toggleStatus() route-model binding

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Method signature | `toggleStatus(Request $request, PickupPoint $pickupPoint)` |
| 2 | **Verify**: Laravel auto-resolves `PickupPoint` from route `{pickupPoint}` | Implicit Route Model Binding |
| 3 | **Verify**: `PickupPoint $pickupPoint` → 404 if not found | Auto 404 |
| 4 | Compare with `destroy($id)` which uses `findOrFail` | Inconsistent parameter style |

### TC-D-08: toggleStatus() direct assignment

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST to toggleStatus with `is_active=1` | Request received |
| 2 | **Verify**: `$pickupPoint->is_active = $request->is_active` | Direct assignment (string "1") |
| 3 | **Verify**: No `$request->boolean('is_active')` helper | Raw value assigned |
| 4 | DB check: `is_active` = 1 (string "1" cast by MySQL) | Works but inconsistent |

### TC-D-09: Model default attributes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `PickupPoint.php:49-52` | `$attributes = ['is_active' => true, 'stop_type' => 'Both']` |
| 2 | Create without setting is_active | Defaults to true |
| 3 | Create without setting stop_type | Defaults to 'Both' |
| 4 | Override stop_type = "Pickup" | Uses explicit value, not default |

### TC-D-10: DB unique constraint on code

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Insert duplicate code directly via DB | `INSERT INTO tpt_pickup_points(code) VALUES('MG-ROAD')` twice |
| 2 | **Verify**: MySQL integrity constraint violation | `Duplicate entry 'MG-ROAD' for key 'uq_pickup_code'` |
| 3 | **Note**: Form validation should catch this before DB, but DB constraint is final guard | Two-layer protection |

### TC-CR-01: ANOMALY — index() uses view not viewAny

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `PickupPointController.php:18` | `Gate::authorize('tenant.pickup-point.view')` |
| 2 | Policy has `viewAny()` method | `PickupPointPolicy.php:13-15` |
| 3 | Other entities (Route, Shift, Vehicle) use `viewAny` for index | Consistent pattern |
| 4 | **Impact**: Permission name `tenant.pickup-point.view` used for listing | Naming inconsistency |

### TC-CR-02: ANOMALY — edit/update/toggleStatus use edit not update

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `edit()` line 112 | `Gate::authorize('tenant.pickup-point.edit')` |
| 2 | Open `update()` line 124 | `Gate::authorize('tenant.pickup-point.edit')` |
| 3 | Open `toggleStatus()` line 201 | `Gate::authorize('tenant.pickup-point.edit')` |
| 4 | Policy has `update()` method with `tenant.pickup-point.update` | `PickupPointPolicy.php:46-48` |
| 5 | **Impact**: `update` permission exists but is never triggered by controller | Policy's update() is dead code |

### TC-CR-03: ANOMALY — forceDelete uses delete not forceDelete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `forceDelete()` line 182 | `Gate::authorize('tenant.pickup-point.delete')` |
| 2 | Policy has `forceDelete()` method with `tenant.pickup-point.forceDelete` | `PickupPointPolicy.php:70-73` |
| 3 | **Impact**: `forceDelete` permission exists but never used | Policy's forceDelete() is dead code |
| 4 | User with delete permission can also force-delete | Broader access than intended |

### TC-CR-04: ANOMALY — no is_active=false before delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `destroy()` lines 142-143 | `$pickupPoint = findOrFail($id); $pickupPoint->delete();` |
| 2 | No `$pickupPoint->update(['is_active'=>false])` before delete | **MISSING** |
| 3 | Compare with RouteController pattern (sets is_active=false first) | **INCONSISTENT** |
| 4 | **Impact**: Trashed records remain is_active=true | Active status after soft-delete |

### TC-CR-05: ANOMALY — forceDelete uses onlyTrashed()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `forceDelete()` line 184 | `PickupPoint::onlyTrashed()->findOrFail($id)` |
| 2 | `onlyTrashed()` adds `WHERE deleted_at IS NOT NULL` | Active records excluded |
| 3 | Correct pattern for forceDelete: `withTrashed()` | Includes both active and trashed |
| 4 | **Impact**: forceDelete fails for active records | User must soft-delete first, then force-delete |

### TC-CR-06: toggleStatus() — no boolean helper

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open line 205 | `$pickupPoint->is_active = $request->is_active` |
| 2 | `$request->is_active` returns raw value (string "1" or "0") | Not cast to boolean |
| 3 | Model casts `is_active` as `boolean` | Cast handles it |
| 4 | Compare with `$request->boolean('is_active')` which returns true/false | Different approach |

### TC-CR-07: activityLog present on all CUD

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Search controller for `activityLog` | 6 calls found |
| 2 | store(): `activityLog($pickupPoint, 'Created', ...)` | Line 101 |
| 3 | update(): `activityLog($pickupPoint, 'Updated', ...)` | Line 129 |
| 4 | destroy(): `activityLog($pickupPoint, 'Deleted', ...)` | Line 145 |
| 5 | restore(): `activityLog($pickupPoint, 'Restored', ...)` | Line 171 |
| 6 | forceDelete(): `activityLog($pickupPoint, 'Deleted Permanently', ...)` | Line 187 |
| 7 | toggleStatus(): `activityLog($pickupPoint, 'Status Toggled', ...)` | Line 208 |

### TC-CR-08: PickupPointRequest authorize POST vs non-POST

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `PickupPointRequest.php:11-17` | `authorize()` method |
| 2 | If POST → `Gate::allows('tenant.pickup-point.create')` | Create permission |
| 3 | If not POST (PUT/PATCH) → `Gate::allows('tenant.pickup-point.update')` | Update permission |
| 4 | **Note**: Uses `Gate::allows()` (returns bool), not `Gate::authorize()` (throws) | FormRequest handles 403 via `authorize()` return value |

### TC-CR-09: prepareForValidation() checkbox normalization

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `PickupPointRequest.php:90-96` | `prepareForValidation()` |
| 2 | Checkbox checked → `$this->has('is_active')` = true, `$this->input('is_active')` = "on" | Normalized to boolean true |
| 3 | Checkbox unchecked → `$this->has('is_active')` = false | Normalized to boolean false |
| 4 | After merge: `$this->get('is_active')` = true/false (boolean) | Rule `boolean` passes |

### TC-CR-10: $fillable fields match DDL

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `PickupPoint.php:19-30` | 10 fillable fields |
| 2 | Match with DDL migration columns | shift_id, code, name, latitude, longitude, location, total_distance, estimated_time, stop_type, is_active |
| 3 | **Note**: `id`, `route_id` (not in DDL), `created_at`, `updated_at`, `deleted_at` NOT in fillable | Correct — managed by framework |

### TC-CR-11: DDL location is POINT — model treats as string

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | DDL line 21: `$table->geometry('location', 'point', 4326)` | Spatial POINT type |
| 2 | Model line 25: `'location'` in `$fillable` | Treated as string |
| 3 | Request line 42: `'location' => 'string'` | Validated as string |
| 4 | **CRITICAL GAP**: Spatial POINT never constructed from form data | Data stored as string in POINT column |
| 5 | **Impact**: Spatial index queries may fail or return unexpected results | `ST_Distance_Sphere` etc. may not work |

### TC-CR-12: Route get-by-shift AJAX

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Route defined in `routes/web.php` | `pickup-point.get-by-shift` |
| 2 | Method: `getPickupPointsByShift(Request)` | `PickupPointController.php:42` |
| 3 | Returns JSON with success, data, count | Standard envelope |
| 4 | **Note**: No Gate — accessible by any authenticated user | **ANOMALY** |

### TC-CR-13: Shift null-safe in blade

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Blade line 76: `{{ optional($point->shift)->name ?? '-' }}` | Null-safe operator |
| 2 | If shift exists → displays name | `optional()->name` |
| 3 | If shift is null (deleted) → displays '-' | `?? '-'` fallback |

### TC-CR-14: ANOMALY — trashed() uses view not restore

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `trashed()` line 156 | `Gate::authorize('tenant.pickup-point.view')` |
| 2 | Gold standard: `trashed()` should use `restore` permission | Like other entities |
| 3 | **Impact**: User with view permission can see trash (without restore permission) | Broader access |

### TC-CR-15: MISMATCH — Request authorize vs Controller Gate

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `PickupPointRequest@authorize()` line 16 (update/PUT) | `Gate::allows('tenant.pickup-point.update')` |
| 2 | `PickupPointController@update()` line 124 | `Gate::authorize('tenant.pickup-point.edit')` |
| 3 | Permission `update` vs `edit` | **DIFFERENT PERMISSIONS** |
| 4 | Policy has `update()` method but controller never calls it | Policy's update is dead code |
| 5 | **Impact**: `tenant.pickup-point.update` in FormRequest, `tenant.pickup-point.edit` in controller | Two separate permissions checked |

### TC-CR-16: MISSING GATE on getPickupPointsByShift

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `getPickupPointsByShift()` lines 42-71 | Method body |
| 2 | Search for `Gate::authorize()` or `$this->authorize()` | **NOT FOUND** |
| 3 | Any authenticated user can call this endpoint | No permission check |
| 4 | **Impact**: Unauthenticated or unauthorized users can list pickup points | Data exposure |

### TC-CR-17: toggleStatus route-model binding

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `toggleStatus(Request $request, PickupPoint $pickupPoint)` | Typed parameter → implicit binding |
| 2 | Route `{pickupPoint}` → auto-resolves | `findOrFail` equivalent |
| 3 | Contrast with `destroy($id)` → manual `findOrFail` | Inconsistent patterns |

### TC-CR-18: Unused policy methods

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `PickupPointPolicy.php:29-31` | `status()` — never used |
| 2 | `PickupPointPolicy.php:78-81` | `import()` — never used |
| 3 | `PickupPointPolicy.php:86-89` | `export()` — never used |
| 4 | `PickupPointPolicy.php:94-97` | `print()` — never used |
| 5 | **Impact**: Dead code in policy | No controller references these methods |

### TC-CR-19: toggleStatus message format

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `toggleStatus()` line 215 | `'message' => 'Pickup Point status updated.'` |
| 2 | Plain string in JSON response | Not wrapped in `__()` or translation |
| 3 | Consistent with other flash messages in controller (all plain strings) | Pattern: no localization |

### TC-CR-20: create() loads active routes/shifts

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `create()` line 88 | `Route::active()->get()` — only active routes |
| 2 | `create()` line 89 | `Shift::active()->get()` — only active shifts |
| 3 | Inactive routes/shifts hidden from dropdown | User cannot select inactive |

### TC-CR-21: edit() loads active routes/shifts

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `edit()` line 115 | `Route::active()->get()` |
| 2 | `edit()` line 116 | `Shift::active()->get()` |
| 3 | Consistent with create() | Same pattern |

### TC-CR-22: forceDelete redirect inconsistency

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `destroy()` line 149 | `redirect()->route('transport.transport-master.index')` → hub |
| 2 | `forceDelete()` line 191 | `redirect()->route('transport.pickup-point.index')` → standalone |
| 3 | **INCONSISTENT**: Same entity, different redirect targets | User confusion possible |

### TC-CR-23: restore() uses onlyTrashed correctly

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `restore()` line 168 | `PickupPoint::onlyTrashed()->findOrFail($id)` |
| 2 | `onlyTrashed()` is correct for restore | Only trashed records can be restored |
| 3 | **Verify**: Non-trashed record → 404 | Correct behavior |

### TC-CR-24: Route-model-binding name in Request

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `PickupPointRequest.php:21` | `$pickupPointId = $this->route('pickup_point')` |
| 2 | Route resource name: `transport.pickup-point` | Parameter name: `pickup_point` |
| 3 | Used for unique ignore on update | Excludes current record from unique check |

### TC-CR-25: toggleStatus inline validation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `toggleStatus()` line 203 | `$request->validate(['is_active'=>'required|boolean'])` |
| 2 | Inline validation, not PickupPointRequest | Different validation path |
| 3 | `required|boolean` ensures valid input | Protects against malformed requests |

### BC-BIZ-DEEP-01: Model $attributes defaults

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `PickupPoint.php:49-52` | Defaults: `is_active=true, stop_type='Both'` |
| 2 | Create stop without setting is_active | `PickupPoint::create([...])` without is_active → defaults to true |
| 3 | Create without setting stop_type | Defaults to 'Both' |
| 4 | **Override**: stop_type="Pickup" → uses explicit value | `stop_type` = 'Pickup' |

### BC-BIZ-DEEP-02: Model casts

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `PickupPoint.php:35-44` | Casts defined |
| 2 | `latitude → decimal:7` | Retrieves with 7 decimal places |
| 3 | `longitude → decimal:7` | Same |
| 4 | `total_distance → decimal:2` | 2 decimal places |
| 5 | `estimated_time → integer` | Whole number |
| 6 | `is_active → boolean` | True/false (PHP bool) |

### BC-BIZ-DEEP-03: getPickupPointsByShift lat/lng cast to float

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `PickupPointController.php:54-55` | `(float) $point->latitude` and `(float) $point->longitude` |
| 2 | Input: "12.9715987" → (float) 12.9715987 | JSON numeric, not string |
| 3 | Input: null → (float) null = 0.0 | Fallback when no coordinates |

### BC-BIZ-DEEP-04: getPickupPointsByShift active filter

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `PickupPointController.php:45-46` | `where('shift_id', ...)->where('is_active', 1)` |
| 2 | Only active stops returned | Inactive stops excluded from map display |
| 3 | **Note**: Correct filtering for map visualization | Map only shows active stops |

### BC-BIZ-DEEP-05: getPickupPointsByShift response payload

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `PickupPointController.php:48-63` | 12 fields mapped |
| 2 | Fields: id, shift_id, code, name, latitude, longitude, total_distance, estimated_time, stop_type, location, created_at, updated_at | Full payload |
| 3 | JSON: `{success: true, data: [...], count: N}` | Wrapped envelope |

### BC-BIZ-DEEP-06 through BC-BIZ-DEEP-55

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| BC-BIZ-DEEP-06 | `store()` uses `$request->validated()` | All validated fields passed to `PickupPoint::create()` |
| BC-BIZ-DEEP-07 | `update()` uses `$request->validated()` | Same pattern as store |
| BC-BIZ-DEEP-08 | `destroy()` redirects to hub | `redirect()->route('transport.transport-master.index')` |
| BC-BIZ-DEEP-09 | `index()` paginate 10 withQueryString | Maintains search/filter across pages |
| BC-BIZ-DEEP-10 | Hub query uses `->latest()` | Newest records first |
| BC-BIZ-DEEP-11 | Hub uses `$request->filled()` for shift_id/pickup_drop | Correctly checks non-empty values |
| BC-BIZ-DEEP-12 | Hub uses `isset($request->status)` for status | 0-safe check |
| BC-BIZ-DEEP-13 | Hub Gate::any checks `tenant.pickup-point.viewAny` | At least one transport permission required |
| BC-BIZ-DEEP-14 | `show()` uses `findOrFail($id)` | 404 on missing |
| BC-BIZ-DEEP-15 | Show blade uses `optional($pickupPoint->shift)` | Null-safe display |
| BC-BIZ-DEEP-16 | Google Maps link in show: `q={{$pickupPoint->latitude}},{{$pickupPoint->longitude}}` | Directs to Maps |
| BC-BIZ-DEEP-17 | Stop type badges: Pickup→success, Drop→danger, Both→warning | Color-coded |
| BC-BIZ-DEEP-18 | Timestamps formatted as `d M Y, h:i A` | Readable date |
| BC-BIZ-DEEP-19 | Lat/lng fields readonly in create/edit | Auto-filled by Google Places |
| BC-BIZ-DEEP-20 | Distance/time fields readonly in create/edit | Auto-calculated by Distance Matrix |
| BC-BIZ-DEEP-21 | Google Maps API loaded with `libraries=places` | Autocomplete functionality |
| BC-BIZ-DEEP-22 | Distance Matrix: DRIVING mode, METRIC units | Road distance in KM |
| BC-BIZ-DEEP-23 | Geolocation denied → alert shown | User notified |
| BC-BIZ-DEEP-24 | Place without geometry → alert | Prevents invalid coordinates |
| BC-BIZ-DEEP-25 | `trashed()` paginate 10, no withQueryString | Simple pagination |
| BC-BIZ-DEEP-26 | Trash columns: Code, Name, Location, Lat, Lng, Stop Type, Action | Different from index |
| BC-BIZ-DEEP-27 | Trash action gated by `@canany(['restore','forceDelete'])` | Permission-based visibility |
| BC-BIZ-DEEP-28 | Trash route column commented out | Same as index |
| BC-BIZ-DEEP-29 | Trash pagination: `->links()` without appends | No tab parameter |
| BC-BIZ-DEEP-30 | toggleStatus JSON includes is_active value | Front-end can sync state |
| BC-BIZ-DEEP-31 | toggleStatus activity uses 'Status Toggled' | Distinct event name |
| BC-BIZ-DEEP-32 | FormRequest authorize returns Gate::allows() | Boolean, not exception |
| BC-BIZ-DEEP-33 | unique rule ignores current ID | Update doesn't fail on own values |
| BC-BIZ-DEEP-34 | Pagination appends `tab=trans_stops` | Tab state preserved |
| BC-BIZ-DEEP-35 | Hub search submits to `transport.pickup-point` URL | Data loaded via hub query, not direct controller |
| BC-BIZ-DEEP-36 | Empty state colspan=8 matches 8 columns | Proper layout |
| BC-BIZ-DEEP-37 | No route_id field in form | Route relationship exists but not assigned via create |
| BC-BIZ-DEEP-38 | total_distance auto-calculated | Not manually editable |
| BC-BIZ-DEEP-39 | estimated_time Math.ceil(duration/60) | Rounded up |
| BC-BIZ-DEEP-40 | forceDelete redirects to standalone index | Different from all other CUD |
| BC-BIZ-DEEP-41 | activityLog after forceDelete | References now-deleted record |
| BC-BIZ-DEEP-42 | activityLog after restore | References restored record |
| BC-BIZ-DEEP-43 | activityLog before destroy | References pre-delete record |
| BC-BIZ-DEEP-44 | Shift filter blank value="" → no filter | Proper empty handling |
| BC-BIZ-DEEP-45 | Status filter values ""=All, "1"=Active, "0"=Inactive | String comparison in blade |
| BC-BIZ-DEEP-46 | Reset button links to hub+tab | Clears all filters |
| BC-BIZ-DEEP-47 | stop_type ENUM order: ['Both','Drop','Pickup'] | MySQL enum |
| BC-BIZ-DEEP-48 | show() Hindi comment: "YEH MISSING THA" | Dev note, show() was added later |
| BC-BIZ-DEEP-49 | toggleStatus uses `$pickupPoint->save()` | Different from `->update()` |
| BC-BIZ-DEEP-50 | toggleStatus returns JSON, not redirect | AJAX endpoint |
| BC-BIZ-DEEP-51 | toggleStatus calls activityLog | Line 208 |
| BC-BIZ-DEEP-52 | Route column commented out in both header and cell | Incomplete UI |
| BC-BIZ-DEEP-53 | Model has `route()` relationship but DDL has no `route_id` | Route relation is conceptual via shift |
| BC-BIZ-DEEP-54 | getPickupPointsByShift returns location as text | Not spatial POINT |
| BC-BIZ-DEEP-55 | JSON envelope: {success, data, count} | Standard format |

### TC-CR-26: Verify PickupPointRoute model for cross-reference

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `PickupPointRoute.php:12-25` | 12 fillable fields including pickup_point_id FK |
| 2 | **Verify**: FK on `tpt_pickup_points_route_jnt.pickup_point_id` → `tpt_pickup_points.id` | CASCADE on delete |
| 3 | **Verify**: When PickupPoint is deleted, all related PickupPointRoutes cascade | Juction records auto-removed |

### TC-CR-27: Browser test cross-check — PickupPointCrudTest

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `tests/Browser/Modules/Transport/PickupPointCrudTest.php` | Browser test file |
| 2 | **Verify**: Test covers CRUD operations | Create, Edit, View, Delete scenarios |
| 3 | **Verify**: Test checks migration schema | `$this->assertStringContainsString("Schema::create('tpt_pickup_points'", ...)` |

### TC-N-21: Submit without location

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create form with all fields valid except location="" | Location empty |
| 2 | Click Submit | Validation fails |
| 3 | **Verify**: Rule `required` on location | "The location field is required." |

### TC-N-22: Submit without stop_type

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create form, leave stop_type unselected | Empty value |
| 2 | Click Submit | Validation fails |
| 3 | **Verify**: Rule `required` + `in:Pickup/Drop/Both` | "The stop type field is required." |

### TC-N-23: Submit without shift_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create form with shift_id="" (unselected) | Empty |
| 2 | Click Submit | Validation fails |
| 3 | **Verify**: Rule `required` + `exists:tpt_shift,id` | "The shift id field is required." |

### TC-N-24: Update with duplicate code (of another record)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Record A has code="CODE-A", Record B has code="CODE-B" | Both exist |
| 2 | Edit Record A, change code to "CODE-B" (B's code) | Duplicate |
| 3 | Click Submit | Validation fails |
| 4 | **Verify**: `Rule::unique(...)->ignore(RecordA->id)` detects conflict | "The code has already been taken." |

### TC-N-25: Update with invalid stop_type

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Edit stop, change stop_type="Invalid" | Not in allowed list |
| 2 | Click Submit | Validation fails |
| 3 | **Verify**: `Rule::in(['Pickup','Drop','Both'])` | Error on stop_type |

### TC-D-11: Verify toggleStatus toggles correctly both ways

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Stop X has is_active=1 | Active |
| 2 | Call toggleStatus with is_active=0 | Set to 0 |
| 3 | DB check: is_active=0 | Toggled OFF |
| 4 | Call toggleStatus with is_active=1 | Set to 1 |
| 5 | DB check: is_active=1 | Toggled ON |
| 6 | **Verify**: `$request->validate(['is_active'=>'required|boolean'])` allows both 0 and 1 | Both directions work |

### TC-D-12: Verify activity log messages differ per operation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create stop → activityLog event = 'Created' | "Pickup Point created successfully." |
| 2 | Update stop → activityLog event = 'Updated' | "Pickup Point updated successfully." |
| 3 | Delete stop → activityLog event = 'Deleted' | "Pickup Point moved to trash." |
| 4 | Restore stop → activityLog event = 'Restored' | "Pickup Point restored successfully." |
| 5 | Force delete stop → activityLog event = 'Deleted Permanently' | "Pickup Point permanently deleted." |
| 6 | Toggle status → activityLog event = 'Status Toggled' | "Pickup Point status updated." |

### TC-D-13: Verify `show()` works with soft-deleted records

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete stop X | deleted_at set |
| 2 | Call show(X) | `findOrFail($id)` includes soft-deleted (SoftDeletes trait) |
| 3 | **Verify**: Show page renders for trashed record | Soft-deleted visible |

### TC-D-14: Verify unique constraint on name at DB level

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Insert duplicate name directly via DB | `INSERT INTO tpt_pickup_points(name) VALUES('MG Road Stop')` twice |
| 2 | **Verify**: MySQL constraint `uq_pickup_name` | Duplicate entry error |

### TC-D-15: Verify `index()` pagination maintains search params

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to index with `?search=MG&shift_id=1&status=1` | Filtered results |
| 2 | Click page 2 | URL includes `?search=MG&shift_id=1&status=1&page=2` |
| 3 | **Verify**: `withQueryString()` preserves all params | Pagination links include current filters |

### TC-EDGE-01: Lat/lng with extreme precision

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter latitude = 12.9715987123456 | More than 7 decimal places |
| 2 | **Verify**: DECIMAL(10,7) stores rounded to 7 decimals | 12.9715987 |
| 3 | Model casts `decimal:7` | PHP float with 7 decimals |

### TC-EDGE-02: total_distance max precision

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter total_distance = 9999.99 | Max allowed |
| 2 | **Verify**: `max:9999.99` passes | Valid |
| 3 | DB: DECIMAL(7,2) → 9999.99 | Stored |

### TC-EDGE-03: estimated_time = 0

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter estimated_time = 0 | Min allowed |
| 2 | **Verify**: `integer`, `min:0` passes | Valid |
| 3 | DB: 0 | Stored |

### TC-EDGE-04: Stop with very long location string (255 chars)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter location = 255-character string | Max allowed |
| 2 | **Verify**: `max:255` passes | Valid |
| 3 | DB: stored | Passes |

### TC-EDGE-05: Toggle status with missing is_active field

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST to toggleStatus WITHOUT is_active field | Missing parameter |
| 2 | **Verify**: `$request->validate(['is_active'=>'required|boolean'])` | "The is_active field is required." |
| 3 | JSON error response (422) | Standard validation error format |

### TC-EDGE-06: getPickupPointsByShift with no shift_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Call `/transport/pickup-point/get-by-shift` without shift_id param | Missing parameter |
| 2 | **Verify**: `$request->shift_id` is null | `where('shift_id', null)` returns empty |
| 3 | **Verify**: JSON `{success: true, data: [], count: 0}` | Empty result |

### TC-EDGE-07: destroy() on already-deleted (trashed) record

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Stop X already soft-deleted (deleted_at set) | Trashed |
| 2 | Call destroy(X) | `findOrFail($id)` finds it (SoftDeletes includes trashed) |
| 3 | **Verify**: `$pickupPoint->delete()` called again | No error (idempotent) |
| 4 | **Verify**: deleted_at unchanged | Still trashed |
| 5 | **Note**: `findOrFail` with SoftDeletes finds ALL records including trashed | Can re-delete a deleted record |

### TC-EDGE-08: restore() on non-trashed (active) record

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Stop X is active (deleted_at = NULL) | Not trashed |
| 2 | Call restore(X) | `onlyTrashed()` → WHERE deleted_at IS NOT NULL |
| 3 | Active record not found | `findOrFail()` → 404 |
| 4 | **Verify**: Cannot restore non-trashed record | Correct behavior |

### TC-EDGE-09: toggleStatus() with invalid boolean string

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST to toggleStatus with is_active="abc" | Invalid boolean |
| 2 | **Verify**: Rule `boolean` fails | "The is_active field must be true or false." |
| 3 | Laravel boolean rule accepts: true, false, 1, 0, "1", "0" | But not "abc" |

### TC-EDGE-10: Parallel toggleStatus race condition

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User A and User B simultaneously toggle same stop | Two concurrent requests |
| 2 | A sends is_active=0, B sends is_active=1 | Race condition |
| 3 | **Note**: No locking mechanism | Last write wins |
| 4 | Final DB value depends on which save() completes last | Unpredictable |

### TC-EDGE-11: Soft-delete then create new with same code

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete stop with code="MG-ROAD" | deleted_at set, but code still in DB |
| 2 | Try to create new stop with code="MG-ROAD" | `Rule::unique('tpt_pickup_points', 'code')` checks DB |
| 3 | **Verify**: Unique check considers soft-deleted records | "The code has already been taken." |
| 4 | **Note**: Soft-deleted records still count for unique validation | Cannot reuse code after soft-delete |

### TC-EDGE-12: Force delete already-force-deleted record

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Stop X force-deleted (gone from DB) | No record |
| 2 | Call forceDelete(X) | `PickupPoint::onlyTrashed()->findOrFail($id)` |
| 3 | **Verify**: Record not found | 404 exception |
| 4 | **Impact**: forceDelete is not idempotent | Cannot force-delete twice |

### TC-EDGE-13: update() with all same values (no change)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Edit stop, submit without changing any fields | PUT request with same values |
| 2 | **Verify**: `unique` rule ignores current ID | Passes (same code/name) |
| 3 | **Verify**: `$pickupPoint->update($request->validated())` | DB updated_at changes |
| 4 | **Verify**: activityLog still called with 'Updated' | Even if no real changes |

### TC-EDGE-14: Hub tab loads without any filters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to Transport Master with tab=trans_stops | Tab loaded |
| 2 | No search, no shift, no type, no status filters | All filters empty |
| 3 | **Verify**: `pickupPointsQuery()` returns all records (paginated) | `PickupPoint::with(['route','shift'])->latest()->paginate(10)` |
| 4 | **Verify**: All 10 records per page | Full listing |

### TC-EDGE-15: Create with is_active=false (inactive by default)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create form with Active switch = OFF | `is_active` not sent (checkbox unchecked) |
| 2 | **Verify**: `prepareForValidation()` → `$this->has('is_active')` = false | Normalized to false |
| 3 | **Verify**: `is_active` = false in merged data | Stored as 0 |
| 4 | **Note**: Model default is true, but explicit false overrides | Works correctly |

### TC-EDGE-16: Multiple sequential toggles

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Toggle OFF (is_active=0) | DB: is_active=0 |
| 2 | Toggle ON (is_active=1) | DB: is_active=1 |
| 3 | Toggle OFF (is_active=0) | DB: is_active=0 |
| 4 | **Verify**: Status toggles correctly each time | Toggle is reversible |

### CODE-TRACE-10: show() view rendering flow

| Step | Blade Line | Action | Expected Output |
|------|-----------|--------|-----------------|
| 1 | 35-40 | Display code | `<span class="badge badge-info">{{ $pickupPoint->code ?? '-' }}</span>` |
| 2 | 42-46 | Display name | `<strong>{{ $pickupPoint->name ?? '-' }}</strong>` |
| 3 | 48-52 | Display location | Text value or '-' |
| 4 | 57-77 | Display stop_type with badge | Pickup→badge-success, Drop→badge-danger, Both→badge-warning |
| 5 | 80-89 | Display total_distance | Value + "km" or '-' |
| 6 | 91-100 | Display estimated_time | Value + "minutes" or '-' |
| 7 | 102-113 | Display shift | `$pickupPoint->shift->name` with `($pickupPoint->shift->code)` |
| 8 | 115-127 | Display status | Active→badge-success, Inactive→badge-danger |
| 9 | 141-165 | Display lat/lng in code blocks | `<code>{{ $pickupPoint->latitude }}</code>` |
| 10 | 168-175 | Google Maps link | `href="https://www.google.com/maps?q=lat,lng"` |
| 11 | 188-199 | Display timestamps | `d M Y, h:i A` format |

### CODE-TRACE-11: Hub tab guard Gate flow

| Step | Action | Code | Line |
|------|--------|------|------|
| 1 | Hub index() called | `TransportMasterController@index` | 26 |
| 2 | Gate::any() with 11 permissions | `['transport.viewAny', 'vehicle.viewAny', ..., 'pickup-point.viewAny', ...]` | 28-41 |
| 3 | If ANY permission true → access granted | `Gate::any([...])` | 28 |
| 4 | If NONE true → `abort(403)` | `|| abort(403)` | 41 |
| 5 | PickupPoint data loaded regardless of which permission matched | `$this->pickupPointsQuery($request)->paginate(10)` | 74 |
| 6 | **Note**: User could have only `vehicle.viewAny` but still see pickup points in hub | Tab-level data accessible if any transport permission held |

### CODE-TRACE-12: Flash message patterns across controller

| Method | Flash Key | Message | Line |
|--------|-----------|---------|------|
| store() | `success` | "Pickup Point added successfully." | 106 |
| update() | `success` | "Pickup Point updated successfully." | 134 |
| destroy() | `success` | "Pickup Point moved to trash." | 150 |
| restore() | `success` | "Pickup Point restored successfully." | 176 |
| forceDelete() | `success` | "Pickup Point permanently deleted." | 192 |
| toggleStatus() | JSON `message` | "Pickup Point status updated." | 215 |

### TC-CR-28: Blade conditional action column rendering

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `pickup_point/index.blade.php:64,81` | `@canany(['tenant.pickup-point.edit', 'tenant.pickup-point.delete'])` |
| 2 | User with edit OR delete permission → Action column visible | Both `<th>` and `<td>` rendered |
| 3 | User with neither → Action column hidden | Column header also hidden |
| 4 | Action column uses `<x-backend.table.action>` component | Generic component with id, url, permissions |

### TC-CR-29: Blade status-switch component

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `pickup_point/index.blade.php:79` | `<x-backend.table.status-switch url="transport.pickup-point" :model="$point" />` |
| 2 | Component generates toggle URL based on model ID | POST to `transport.pickup-point.toggleStatus/{id}` |
| 3 | Component sends is_active = 0 or 1 via AJAX | Toggle functionality |

### TC-CR-30: Create form error display

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `create.blade.php:14-22` | Error alert block |
| 2 | `@if ($errors->any())` → show alert-danger | Validation errors displayed |
| 3 | `@foreach ($errors->all() as $error)` → list each error | All field errors shown |

### TC-CR-31: Edit form pre-fills values

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `edit.blade.php:42` | `value="{{ old('code', $pickupPoint->code) }}"` |
| 2 | `old()` fallback to model value | Pre-filled with current value |
| 3 | Same pattern for name, location, lat, lng, distance, time | All fields pre-filled |
| 4 | Stop type uses `old('stop_type', $pickupPoint->stop_type) == 'Pickup' ? 'selected'` | Correct option selected |
| 5 | Shift uses `old('shift_id', $pickupPoint->shift_id) == $shift->id ? 'selected'` | Correct shift selected |

### TC-CR-32: Google Maps API key fallback

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `create.blade.php:165` | `src="https://maps.googleapis.com/maps/api/js?key={{ config('transport.google_maps_api_key') }}&libraries=places"` |
| 2 | If API key not configured → URL loads without key | Google Maps may fail |
| 3 | **Verify**: `config('transport.google_maps_api_key')` must be set | Required for autocomplete + distance |

### TC-CR-33: Edit form uses same Google Maps patterns as create

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `edit.blade.php:170-172` | Same Google Maps API script |
| 2 | Open `edit.blade.php:176-263` | Same JS logic (autocomplete + distance matrix) |
| 3 | Both create and edit have identical JS | Duplicated code (not extracted to partial) |

### TC-CR-34: No CSRF exemption on AJAX endpoints

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | toggleStatus is a POST AJAX endpoint | CSRF token required |
| 2 | getPickupPointsByShift is GET | No CSRF needed |
| 3 | **Verify**: No `except` entries in VerifyCsrfToken middleware for these routes | CSRF protection active |

### TC-CR-35: Soft delete cascade from PickupPoint to child entities

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `PickupPoint.php:93-124` | 3 hasMany relationships: tripStopDetails, boardingLogs, studentAllocations |
| 2 | **Note**: Soft-deleting PickupPoint does NOT cascade to child tables | Child records keep stop_id but pickup point is trashed |
| 3 | **Verify**: DB has no CASCADE on PickupPoint delete for child tables | Only `fk_pickupPoint_shiftId` has CASCADE |

### TC-P-14: Create stop with Pickup type

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create form, select stop_type="Pickup" | Valid |
| 2 | Fill all required fields | OK |
| 3 | Submit | Created |
| 4 | DB: `stop_type` = "Pickup" | Stored correctly |

### TC-P-15: Create stop with Drop type

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create form, select stop_type="Drop" | Valid |
| 2 | Submit | Created |
| 3 | DB: `stop_type` = "Drop" | Stored correctly |

### TC-P-16: Edit stop — change only status

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Edit stop, toggle status switch only | No other changes |
| 2 | Submit | Updated |
| 3 | DB: `is_active` toggled, other fields unchanged | Partial update |

### TC-P-17: Bulk operations — create 5 stops sequentially

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create stop 1 with code="STOP-01" | Success |
| 2 | Create stop 2 with code="STOP-02" | Success |
| 3 | Create stop 3 with code="STOP-03" | Success |
| 4 | Create stop 4 with code="STOP-04" | Success |
| 5 | Create stop 5 with code="STOP-05" | Success |
| 6 | **Verify**: All 5 exist in DB | 5 rows |
| 7 | **Verify**: Activity logs for each creation | 5 'Created' events |

### TC-N-26: total_distance = 9999.991 (overflow)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set total_distance = 9999.991 | More than 2 decimal places |
| 2 | **Verify**: DECIMAL(7,2) rounds to 9999.99 | Model cast to decimal:2 |
| 3 | **Verify**: `max:9999.99` passes (value after rounding) | Validation may accept |

### TC-N-27: Update with empty location

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Edit stop, clear location field | location="" |
| 2 | Submit | Validation fails |
| 3 | **Verify**: `required` rule on location | "The location field is required." |

### TC-D-16: Verify getPickupPointsByShift response format

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Call getPickupPointsByShift with valid shift_id | JSON response |
| 2 | **Verify**: `success: true` | Top-level flag |
| 3 | **Verify**: `data` is array of objects | Each object has 12 fields |
| 4 | **Verify**: `count` matches data.length | Correct count |
| 5 | **Verify**: lat/lng are numeric (not string) | `(float)` cast |
| 6 | **Verify**: location is string | Text address |

### TC-D-17: Verify hub tab preserves state after CRUD

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to hub with filters active | URL: `?tab=trans_stops&shift_id=1&status=1` |
| 2 | Create new stop | Redirect to `transport.transport-master.index` (no params) |
| 3 | **Verify**: After redirect, tab=trans_stops is default | Tab still shows |
| 4 | **Verify**: Filters are reset | User must re-apply filters |

---

*Template: tpt_PickupStopsList_TcList.md (Syllabus depth) | Entity: TransStops (PickupPoint) | Date: 2026-07-21*
