# Vehicle Master — TC_List

---

## 1. Feature Information

| Attribute | Details |
|-----------|---------|
| **Module** | Transport (TPT) |
| **Entity** | Vehicle Master (`tpt_vehicle`) |
| **Controller** | `Modules\Transport\Http\Controllers\VehicleController` — 11 methods (show, create, store, edit, update, destroy, trashed, restore, forceDelete, toggleStatus) — ⚠️ `index()` NOT called; tab listing uses `TransportMasterController` |
| **Tab Container Controller** | `Modules\Transport\Http\Controllers\TransportMasterController@index()` — tab id `vehicle`, private `vehiclesQuery()` for listing |
| **Model** | `Modules\Transport\Models\Vehicle` — SoftDeletes, InteractsWithMedia, 10 relationships |
| **Form Request** | `Modules\Transport\Http\Requests\VehicleRequest` — 16 validation rules + `prepareForValidation` |
| **Policy** | `Modules\Transport\Policies\VehiclePolicy` — 11 permission methods: `viewAny`, `view`, `status`, `create`, `update`, `delete`, `restore`, `forceDelete`, `import`, `export`, `print` |
| **Route Prefix** | `transport.vehicle.*` (resource) + `trashed`, `restore`, `forceDelete`, `toggleStatus` |
| **Blade Views** | `vehicle/index.blade.php` (tab), `vehicle/create.blade.php`, `vehicle/edit.blade.php`, `vehicle/show.blade.php`, `vehicle/trash.blade.php`, `vehicle/partials/table.blade.php` |
| **Tab Container** | `tab_module/transportmaster.blade.php` — tab id `vehicle`, permission `tenant.vehicle.viewAny` |
| **DB Table** | `tpt_vehicle` — 26 data columns + 3 timestamp columns |
| **Media Library** | Spatie MediaLibrary — 8 single-file collections (`registration_img`, `pollution_img`, `fitness_img`, `insurance_img`, `vehicle_photo`, `vehicle_emission_cert_img`, `fire_extinguisher_cert_img`, `gps_device_cert_img`) + 1 photo conversion (small 150x150, medium 300x300) |
| **Primary Screen** | Transport Master → Vehicle tab (paginated, searchable, status-filtered, AJAX partial-load) |

---

## 2. Pre-conditions

| # | Pre-condition |
|---|--------------|
| PC-01 | User must be logged in as Transport Manager (or role with `tenant.vehicle.*` permissions) |
| PC-02 | Database `tpt_vehicle` table must exist with all 26 data columns |
| PC-03 | `sys_dropdown_table` must have entries for: vehicle_type_id (BUS/VAN/CAR), fuel_type_id (Diesel/Petrol/CNG/Electric), ownership_type_id (Owned/Leased/Rented), vehicle_emission_class_id (BS IV/BS V/BS VI) |
| PC-04 | `vnd_vendors` table must have at least one vendor with `vendor_type_id` matching Dropdown key `vnd_vendors.vendor_type_id` |
| PC-05 | Spatie MediaLibrary tables (`media`) must exist for document uploads |
| PC-06 | `VehicleController` must be registered in web routes with full resource + extra routes |
| PC-07 | `VehiclePolicy` must be registered in `AuthServiceProvider` |
| PC-08 | Vehicle tab must be included in `transportmaster.blade.php` with `@can('tenant.vehicle.viewAny')` guard |
| PC-09 | Soft deletes must be enabled on `tpt_vehicle` (`deleted_at` column) |
| PC-10 | Browser must support JavaScript for status toggle, AJAX search, and file uploads |

---

## 3. Default Data Load

| # | Data Load Rule | Source |
|---|----------------|--------|
| DL-01 | Load vehicles with pagination (10 per page) via `TransportMasterController::index() → vehiclesQuery() [Tab-based]()` | `TransportMasterController.php:85-95` — `Vehicle::query()->when(search/status)->latest()->paginate(10)->withQueryString()` |
| DL-02 | Search filters: `?search=` (Vehicle No, Registration No) and `?status=` (1=Active, 0=Inactive) | `TransportMasterController.php:86-93` |
| DL-03 | AJAX request returns partial view only (no layout) | `TransportMasterController.php:89-91` — `if ($request->ajax()) { return view(...)->render(); }` |
| DL-04 | List columns displayed: **Vehicle No**, **Registration No**, **Model**, **Fuel Type**, **Capacity**, **Status**, **Action** | `vehicle/index.blade.php:31-39` |
| DL-05 | Fuel Type displayed via `$vehicle->fuelType->value` (Dropdown relationship) | `vehicle/index.blade.php:48` |
| DL-06 | Status column uses `<x-backend.table.status-switch>` component | `vehicle/index.blade.php:51` |
| DL-07 | Action column uses `<x-backend.table.action>` — visible only for `@canany(['tenant.vehicle.edit', 'tenant.vehicle.delete'])` | `vehicle/index.blade.php:37,53` |
| DL-08 | Pagination links appended with `?tab=vehicle` query parameter | `vehicle/index.blade.php:70` |
| DL-09 | Empty state: "No Data Found" displayed for colspan 7 | `vehicle/index.blade.php:60-62` |
| DL-10 | Create form loads vendors filtered by `vnd_vendors.vendor_type_id` dropdown key | `VehicleController.php:65-66` |
| DL-11 | Edit form loads same vendor list + existing vehicle data | `VehicleController.php:122-124` |

---

## 4. Test Data Strategy

| # | Data Strategy | Details |
|---|---------------|---------|
| TD-01 | **Valid Vehicle** | `vehicle_no='MH12AB1234'`, `registration_no='GJ05XY6789'`, `capacity=40`, `max_capacity=45`, vendor+dropdown IDs valid, all dates valid |
| TD-02 | **Duplicate Vehicle No** | Create second vehicle with same `vehicle_no` — expects unique violation |
| TD-03 | **Duplicate Registration No** | Create second vehicle with same `registration_no` — expects unique violation |
| TD-04 | **Capacity > Max Capacity** | `capacity=50`, `max_capacity=40` — expects `gte:capacity` validation failure |
| TD-05 | **Invalid Vendor ID** | `vendor_id=99999` — expects `exists:vnd_vendors,id` failure |
| TD-06 | **Missing Required Dropdown** | Leave `vehicle_type_id` empty — expects `required\|integer` failure |
| TD-07 | **All 8 Document Uploads** | Upload all 8 media files (registration_img, pollution_img, fitness_img, insurance_img, vehicle_photo, vehicle_emission_cert_img, fire_extinguisher_cert_img, gps_device_cert_img) |
| TD-08 | **Document Replace on Update** | Upload new insurance_img on edit — old file cleared, new file attached |
| TD-09 | **DDL Upload Flag Discrepancy** | DDL has 8 `*_upload` tinyint flags (`vehicle_photo_upload`, `registration_cert_upload`, etc.) but Model `$fillable` only has `documents_uploaded` (single field) — **GAP** |
| TD-10 | **Soft-Deleted Vehicle No Reuse** | Delete vehicle, create new with same vehicle_no — should succeed |

---

## 5. Business Conditions (BC)

### BC-DB: Database Conditions

| ID | Condition | Expected | Source |
|----|-----------|----------|--------|
| BC-DB-01 | `vehicle_no` — VARCHAR(20), NOT NULL | Max 20 chars, no nulls | DDL: `tpt_vehicle` line 12 |
| BC-DB-02 | `registration_no` — VARCHAR(30), NOT NULL | Max 30 chars, no nulls | DDL: `tpt_vehicle` line 13 |
| BC-DB-03 | UNIQUE KEY on (`registration_no`, `vehicle_no`) | Composite unique across both fields | DDL: `tpt_vehicle` line 41 |
| BC-DB-04 | `model` — VARCHAR(50), NULLABLE | Max 50 chars | DDL: `tpt_vehicle` line 14 |
| BC-DB-05 | `manufacturer` — VARCHAR(50), NULLABLE | Max 50 chars | DDL: `tpt_vehicle` line 15 |
| BC-DB-06 | `vehicle_type_id` — INT UNSIGNED, FK → `sys_dropdown_table.id` CASCADE | Required dropdown reference | DDL: `tpt_vehicle` line 16,42 |
| BC-DB-07 | `fuel_type_id` — INT UNSIGNED, FK → `sys_dropdown_table.id` CASCADE | Required dropdown reference | DDL: `tpt_vehicle` line 17,43 |
| BC-DB-08 | `capacity` — INT UNSIGNED, DEFAULT 40 | Min 1, default 40 | DDL: `tpt_vehicle` line 18 |
| BC-DB-09 | `max_capacity` — INT UNSIGNED, DEFAULT 40 | Must be >= capacity | DDL: `tpt_vehicle` line 19 |
| BC-DB-10 | `ownership_type_id` — INT UNSIGNED, FK → `sys_dropdown_table.id` CASCADE | Required dropdown reference | DDL: `tpt_vehicle` line 20,44 |
| BC-DB-11 | `vendor_id` — INT UNSIGNED, FK → `vnd_vendors.id` CASCADE | Required vendor reference | DDL: `tpt_vehicle` line 21,45 |
| BC-DB-12 | 5 date columns: `fitness_valid_upto`, `insurance_valid_upto`, `pollution_valid_upto`, `fire_extinguisher_valid_upto` — DATE NOT NULL | Required dates | DDL: `tpt_vehicle` line 22-24,26 |
| BC-DB-13 | `vehicle_emission_class_id` — INT UNSIGNED, FK → `sys_dropdown_table.id` CASCADE | Required dropdown reference | DDL: `tpt_vehicle` line 25,46 |
| BC-DB-14 | `gps_device_id` — VARCHAR(50), NULLABLE | Max 50 chars | DDL: `tpt_vehicle` line 27 |
| BC-DB-15 | 8 `*_upload` TINYINT(1) flags in DDL (`vehicle_photo_upload`, `registration_cert_upload`, etc.) | DEFAULT 0, separate upload flags per document type | DDL: `tpt_vehicle` line 28-35 |
| BC-DB-16 | `availability_status` — TINYINT(1), DEFAULT 1 | 0=Not Available, 1=Available | DDL: `tpt_vehicle` line 36 |
| BC-DB-17 | `is_active` — TINYINT(1), DEFAULT 1 | Active flag | DDL: `tpt_vehicle` line 37 |

### BC-VAL: Validation Conditions

| ID | Condition | Rule | Source |
|----|-----------|------|--------|
| BC-VAL-01 | `vehicle_no` — required, string, max:20, unique in `tpt_vehicle` | `required\|string\|max:20\|Rule::unique(...)` | `VehicleRequest.php:25-30` |
| BC-VAL-02 | `registration_no` — required, string, max:30, unique in `tpt_vehicle` | `required\|string\|max:30\|Rule::unique(...)` | `VehicleRequest.php:32-37` |
| BC-VAL-03 | `model` — nullable, string, max:50 | `nullable\|string\|max:50` | `VehicleRequest.php:39` |
| BC-VAL-04 | `manufacturer` — nullable, string, max:50 | `nullable\|string\|max:50` | `VehicleRequest.php:40` |
| BC-VAL-05 | `vehicle_type_id` — required, integer | `required\|integer` | `VehicleRequest.php:43` |
| BC-VAL-06 | `fuel_type_id` — required, integer | `required\|integer` | `VehicleRequest.php:44` |
| BC-VAL-07 | `ownership_type_id` — required, integer | `required\|integer` | `VehicleRequest.php:45` |
| BC-VAL-08 | `vehicle_emission_class_id` — required, integer | `required\|integer` | `VehicleRequest.php:46` |
| BC-VAL-09 | `capacity` — required, integer, min:1 | `required\|integer\|min:1` | `VehicleRequest.php:48-52` |
| BC-VAL-10 | `max_capacity` — required, integer, gte:capacity | `required\|integer\|gte:capacity` | `VehicleRequest.php:54-58` |
| BC-VAL-11 | `fitness_valid_upto` — required, date | `required\|date` | `VehicleRequest.php:60-63` |
| BC-VAL-12 | `insurance_valid_upto` — required, date | `required\|date` | `VehicleRequest.php:65-68` |
| BC-VAL-13 | `pollution_valid_upto` — required, date | `required\|date` | `VehicleRequest.php:70-73` |
| BC-VAL-14 | `fire_extinguisher_valid_upto` — required, date | `required\|date` | `VehicleRequest.php:75-78` |
| BC-VAL-15 | `vendor_id` — required, integer, exists:vnd_vendors,id | `required\|integer\|exists:vnd_vendors,id` | `VehicleRequest.php:80-84` |
| BC-VAL-16 | `gps_device_id` — nullable, string, max:50 | `nullable\|string\|max:50` | `VehicleRequest.php:86` |
| BC-VAL-17 | `is_active` — sometimes, boolean (normalized via `$this->boolean()`) | `sometimes\|boolean` | `VehicleRequest.php:88,93-98` |
| BC-VAL-18 | **GAP**: Unique constraint on (`registration_no`, `vehicle_no`) — composite unique in DDL but Request only has individual unique rules | Individual fields unique; composite unique prevents (A,B) and (B,A) combos | DDL vs Request mismatch |

### BC-AUTH: Authorization Conditions

| ID | Permission | Controller Gate | Policy Method | Source |
|----|-----------|-----------------|---------------|--------|
| BC-AUTH-01 | `tenant.vehicle.viewAny` | Tab: `Gate::any([...])` in `TransportMasterController::index()` (line 28-41); Standalone: `Gate::authorize(...)` in `VehicleController::index()` (line 21) | `viewAny()` | `TransportMasterController.php:28-41` |
| BC-AUTH-02 | `tenant.vehicle.view` | `Gate::authorize('tenant.vehicle.view')` in `show()` and `create()` | `view()` | `VehiclePolicy.php:21, VehicleController.php:50,62` |
| BC-AUTH-03 | `tenant.vehicle.status` | — (policy method exists but not used in controller) | `status()` | `VehiclePolicy.php:29` |
| BC-AUTH-04 | `tenant.vehicle.create` | `Gate::authorize('tenant.vehicle.create')` in `store()` | `create()` | `VehiclePolicy.php:37, VehicleController.php:75` |
| BC-AUTH-05 | `tenant.vehicle.update` | `Gate::authorize('tenant.vehicle.update')` in `edit()` & `update()` & `toggleStatus()` | `update()` | `VehiclePolicy.php:45` |
| BC-AUTH-06 | `tenant.vehicle.delete` | `Gate::authorize('tenant.vehicle.delete')` in `destroy()` | `delete()` | `VehiclePolicy.php:53` |
| BC-AUTH-07 | `tenant.vehicle.restore` | `Gate::authorize('tenant.vehicle.restore')` in `trashed()` & `restore()` | `restore()` | `VehiclePolicy.php:61` |
| BC-AUTH-08 | `tenant.vehicle.forceDelete` | `Gate::authorize('tenant.vehicle.forceDelete')` in `forceDelete()` | `forceDelete()` | `VehiclePolicy.php:69` |
| BC-AUTH-09 | `tenant.vehicle.import` | — (not used in controller) | `import()` | `VehiclePolicy.php:77` |
| BC-AUTH-10 | `tenant.vehicle.export` | — (not used in controller) | `export()` | `VehiclePolicy.php:85` |
| BC-AUTH-11 | `tenant.vehicle.print` | — (not used in controller) | `print()` | `VehiclePolicy.php:93` |

### BC-BIZ: Business Conditions

| ID | Condition | Expected | Source |
|----|-----------|----------|--------|
| BC-BIZ-01 | Vehicle number must be unique (ignoring soft-deleted) | DB composite unique + Request unique | `VehicleRequest.php:29` |
| BC-BIZ-02 | `max_capacity` must be >= `capacity` | Validation `gte:capacity` | `VehicleRequest.php:57` |
| BC-BIZ-03 | Delete sets `is_active=false` before soft-delete | `$vehicle->is_active = false; $vehicle->save(); $vehicle->delete();` | `VehicleController.php:191-193` |
| BC-BIZ-04 | Store uploads up to 8 document files via Spatie MediaLibrary | `addMediaFromRequest()` for each of 8 fields | `VehicleController.php:79-103` |
| BC-BIZ-05 | Update replaces documents: clears old collection, adds new file | `clearMediaCollection($field)` then `addMediaFromRequest($field)` | `VehicleController.php:151-155` |
| BC-BIZ-06 | Vehicle photo gets image conversions (small 150x150, medium 300x300) | Conversions only for `vehicle_photo` collection | `Vehicle.php:142-152` |
| BC-BIZ-07 | `create()` uses `tenant.vehicle.view` gate (unusual — should be `tenant.vehicle.create`) | **Anomaly**: Create form uses `view` permission instead of `create` | `VehicleController.php:62` |

### BC-REL: Relationship Conditions

| ID | Relationship | Type | Source |
|----|-------------|------|--------|
| BC-REL-01 | Vehicle → TptDailyVehicleInspection | `hasMany(inspections)` | `Vehicle.php:61-63` |
| BC-REL-02 | Vehicle → DriverRouteVehicleJnt | `hasMany(driverRouteVehicles)` | `Vehicle.php:67-69` |
| BC-REL-03 | Vehicle → TptVehicleFuel | `hasMany(fuelLogs)` | `Vehicle.php:92-94` |
| BC-REL-04 | Vehicle → Vendor | `belongsTo(vendor)` | `Vehicle.php:88-90` |
| BC-REL-05 | Vehicle → Dropdown (vehicle_type) | `belongsTo(vehicleType)` | `Vehicle.php:97-99` |
| BC-REL-06 | Vehicle → Dropdown (fuel_type) | `belongsTo(fuelType)` | `Vehicle.php:102-104` |
| BC-REL-07 | Vehicle → Dropdown (ownership_type) | `belongsTo(ownershipType)` | `Vehicle.php:107-109` |
| BC-REL-08 | Vehicle → Dropdown (emission_class) | `belongsTo(emissionClass)` | `Vehicle.php:112-114` |

### BC-REF: Reference & UI Conditions

| ID | Condition | Expected | Source |
|----|-----------|----------|--------|
| BC-REF-01 | Index tab loads in Transport Master with `@can('tenant.vehicle.viewAny')` | Tab conditional | `transportmaster.blade.php` |
| BC-REF-02 | Search bar with `tenant.vehicle` permission | Conditional toolbar | `vehicle/index.blade.php:5` |
| BC-REF-03 | Action column in index shown only for `@canany(['tenant.vehicle.edit', 'tenant.vehicle.delete'])` | Conditional | `vehicle/index.blade.php:37,53` |
| BC-REF-04 | Create form — 10+ dropdown/input fields + 8 file uploads | Complex form with media | `vehicle/create.blade.php` |
| BC-REF-05 | **GAP**: `create()` uses `tenant.vehicle.view` gate instead of `tenant.vehicle.create` | Users with `view` can access create form | `VehicleController.php:62` |
| BC-REF-06 | **GAP**: DDL has 8 individual `*_upload` TINYINT flags but Model only has `documents_uploaded` (single field) | Individual cert tracking not possible via model | DDL vs `Vehicle.php` fillable |
| BC-REF-07 | Flash keys: `created.vehicle`, `updated.vehicle`, `trashed.vehicle`, `restored.vehicle`, `force_deleted.vehicle`, `status_updated.vehicle`, `status_switch_failed.vehicle` | Must exist in lang file | `VehicleController.php` |
| BC-REF-08 | AJAX requests return partial view (used for tab switching) | `$request->ajax()` check in `index()` | `VehicleController.php:37-38` |
| BC-REF-09 | **OBSERVATION**: `restore()` activityLog() missing `performed_by` key | Inconsistent with all other activityLog calls | `VehicleController.php:227-230` |
| BC-REF-10 | Tab parameter `?tab=vehicle` appended to pagination links | `vehicle/index.blade.php:70` — Blade appends tab=vehicle | `withQueryString()` preserves search/status |
| BC-REF-11 | Status switch component renders toggle with JS | AJAX POST to `toggleStatus` route | `vehicle/index.blade.php:51` |
| BC-REF-12 | Empty state colspan=7 in table | "No Data Found" shown when no vehicles | `vehicle/index.blade.php:60-62` |
| BC-REF-13 | create() loads empty Vehicle model instance for form binding | `$vehicle = new Vehicle()` — empty model passed to view | `VehicleController.php:63` |

### BC-BIZ-DEEP: Deep Business Conditions

| # | Condition | Expected Behavior |
|---|-----------|-------------------|
| BC-BIZ-DEEP-01 | Pagination at 10 per page in index() | `Vehicle::query()->...->paginate(10)` — 10 records per page | 
| BC-BIZ-DEEP-02 | `withQueryString()` preserves search/status filter params across pagination | Pagination links include `?search=` and `?status=` params | 
| BC-BIZ-DEEP-03 | AJAX index() returns rendered partial view (no layout) | `$request->ajax()` → `return view(...)->render()` — used for tab switching | 
| BC-BIZ-DEEP-04 | create() loads vendors via Dropdown key `vnd_vendors.vendor_type_id` | `Dropdown::where('key','vnd_vendors.vendor_type_id')->first()` → fetches vendor_type_id, then `Vendor::where('vendor_type_id', $id)->get()` | 
| BC-BIZ-DEEP-05 | store() uploads 8 media files via Spatie MediaLibrary loop | `foreach ($mediaFields as $field)` → `addMediaFromRequest($field)->usingFileName(time().'_'.$origName)->toMediaCollection($field)` | 
| BC-BIZ-DEEP-06 | Filename collision prevention via `time()` prefix | `time() . '_' . $request->file($field)->getClientOriginalName()` — unix timestamp prefix | 
| BC-BIZ-DEEP-07 | `documentsUploaded` flag tracks whether any document was uploaded | `$documentsUploaded = 0;` → set to 1 if any file uploaded. Variable declared but NOT persisted (no assignment to model) | 
| BC-BIZ-DEEP-08 | update() clears old media before adding replacement | `$vehicle->clearMediaCollection($field)` before `addMediaFromRequest()` — old file physically deleted | 
| BC-BIZ-DEEP-09 | Change tracking via `getOriginal()` + `getChanges()` in update() | `$original = $vehicle->getOriginal()` before update, then `$changes = $vehicle->getChanges()` after, skips `updated_at` | 
| BC-BIZ-DEEP-10 | destroy() sets `is_active=false` before soft-delete | `$vehicle->is_active = false; $vehicle->save(); $vehicle->delete();` — 3-step process | 
| BC-BIZ-DEEP-11 | toggleStatus() returns JSON success/failure response | Success: `{success: true, is_active: bool, message: flash(...)}` — Failure: `{success: false, ...}` | 
| BC-BIZ-DEEP-12 | restore() uses `onlyTrashed()` to find deleted records | `Vehicle::onlyTrashed()->findOrFail($id)` — only finds soft-deleted records | 
| BC-BIZ-DEEP-13 | forceDelete() uses `withTrashed()` to find any record (deleted or not) | `Vehicle::withTrashed()->findOrFail($id)` — finds both active and trashed | 
| BC-BIZ-DEEP-14 | activityLog() called in every CRUD method (store, update, destroy, restore, forceDelete, toggleStatus) | Consistent logging pattern across 6 methods | 
| BC-BIZ-DEEP-15 | All flash messages use `flash('key')` pattern, not hardcoded strings | Keys: `created.vehicle`, `updated.vehicle`, `trashed.vehicle`, `restored.vehicle`, `force_deleted.vehicle`, `status_updated.vehicle`, `status_switch_failed.vehicle` | 
| BC-BIZ-DEEP-16 | Route-model-binding used in show, update, destroy, toggleStatus | `show(Vehicle $vehicle)`, `update(VehicleRequest $request, Vehicle $vehicle)`, `destroy(Vehicle $vehicle)`, `toggleStatus(Request $request, Vehicle $vehicle)` | 
| BC-BIZ-DEEP-17 | Manual ID lookup in edit, restore, forceDelete | `edit($id)` → `Vehicle::where('id', $id)->first()`, `restore($id)` → `onlyTrashed()->findOrFail($id)`, `forceDelete($id)` → `withTrashed()->findOrFail($id)` | 
| BC-BIZ-DEEP-18 | search filter applies LIKE on vehicle_no and registration_no | `$q->where('vehicle_no', 'like', "%{$request->search}%")->orWhere('registration_no', 'like', "%{$request->search}%")` — both fields | 
| BC-BIZ-DEEP-19 | status filter uses exact match on `is_active` column | `$q->where('is_active', $request->status)` — 1=Active, 0=Inactive | 
| BC-BIZ-DEEP-20 | Latest ordering applied to index query | `->latest()` — orders by `created_at DESC` | 
| BC-BIZ-DEEP-21 | Media conversions only on `vehicle_photo` collection | `registerMediaConversions()` checks `$this->collection_name === 'vehicle_photo'` → small 150x150, medium 300x300, non-queued | 
| BC-BIZ-DEEP-22 | All 8 media collections are single-file | `registerMediaCollections()` calls `->singleFile()` on each — any new upload replaces the previous | 
| BC-BIZ-DEEP-23 | toggleStatus() uses `$request->boolean('is_active')` for normalization | Converts "1"/"0"/"true"/"false" strings to proper boolean | 
| BC-BIZ-DEEP-24 | restore() activityLog() missing `performed_by` key | Only passes `message` + `other` — inconsistent with all other activityLog calls which include `performed_by` | 
| BC-BIZ-DEEP-25 | `create()` gate anomaly: uses `tenant.vehicle.view` instead of `tenant.vehicle.create` | Users with view-only permission can access create form, but store() gate requires create permission | 
| BC-BIZ-DEEP-26 | Policy has 4 unused permission methods: `status()`, `import()`, `export()`, `print()` | Defined in policy but never called from any controller method | 
| BC-BIZ-DEEP-27 | DDL has 8 individual `*_upload` TINYINT flags but Model `$fillable` only has `documents_uploaded` | Individual cert upload tracking not possible via mass-assignment | 
| BC-BIZ-DEEP-28 | `availability_status` is in `$fillable` but has NO validation rule in `VehicleRequest` | Defaults to DB DEFAULT 1 — can be set via mass-assignment without validation | 
| BC-BIZ-DEEP-29 | `vehicle_no` unique rule ignores soft-deleted records | `Rule::unique('tpt_vehicle', 'vehicle_no')->ignore($this->vehicle?->id ?? null)` — ignores current record on update, but NOT soft-deleted records | 
| BC-BIZ-DEEP-30 | `registration_no` unique rule ignores soft-deleted records | Same pattern as vehicle_no — soft-deleted records not checked for uniqueness, allowing reuse | 
| BC-BIZ-DEEP-31 | `scopeActive()` defined on model but NEVER used in any controller query | `scopeActive($query) { return $query->where('is_active', true); }` — dead code | 
| BC-BIZ-DEEP-32 | Composite UNIQUE (`vehicle_no`, `registration_no`) in DDL vs individual unique rules in Request | DDL: composite prevents (A,B) and (B,A) without conflict. Request: individual unique on each field. Composite provides additional protection at DB level | 
| BC-BIZ-DEEP-33 | Tab visibility controlled by `@can('tenant.vehicle.viewAny')` guard | Vehicle tab hidden from users without viewAny permission | 
| BC-BIZ-DEEP-34 | Action column in index uses `@canany` with edit and delete | Conditional rendering of action icons based on user permissions | 
| BC-BIZ-DEEP-35 | Capacity validation `gte:capacity` ensures max_capacity >= capacity | `max_capacity` must be greater than or equal to `capacity` — prevents illogical capacity ranges | 
| BC-BIZ-DEEP-36 | Four required date fields for certificate validity periods | `fitness_valid_upto`, `insurance_valid_upto`, `pollution_valid_upto`, `fire_extinguisher_valid_upto` — all required, date type | 
| BC-BIZ-DEEP-37 | Vendor `exists` validation checks `vnd_vendors.id` table | `exists:vnd_vendors,id` — vendor must exist in vendor master | 
| BC-BIZ-DEEP-38 | store() redirects to `transport.transport-master.index` after success | All CRUD operations (store, update, destroy) redirect to transport-master.index (the tab container) | 
| BC-BIZ-DEEP-39 | restore() and forceDelete() redirect to `transport.vehicle.trashed` after operation | Trash management operations return to trash listing | 
| BC-BIZ-DEEP-40 | Status toggle route is `transport.vehicle.toggleStatus` with POST method | Separate route from resource controller, uses POST with JSON response | 
| BC-BIZ-DEEP-41 | Fuel type displayed via `$vehicle->fuelType->value` relationship | Dropdown relationship on `fuel_type_id` → displays dropdown value text | 
| BC-BIZ-DEEP-42 | Status column uses `<x-backend.table.status-switch>` Blade component | Reusable toggle component with AJAX integration | 
| BC-BIZ-DEEP-43 | `VehicleRequest@prepareForValidation()` normalizes `is_active` to boolean | `$this->boolean('is_active')` — converts string "0"/"1" to boolean | 
| BC-BIZ-DEEP-44 | `VehicleRequest@authorize()` returns different permissions for POST vs PUT | POST (create): `tenant.vehicle.create`, PUT/PATCH (update): `Gate::allows('tenant.vehicle.update')` | 
| BC-BIZ-DEEP-45 | Soft-delete pattern with is_active flag creates an inactive trashed record | `is_active=false` → `save()` → `delete()` — trashed records are always inactive | 
| BC-BIZ-DEEP-46 | No AJAX pagination — page changes cause full page reload | Paginator links are standard `<a>` tags, not AJAX-loaded | 
| BC-BIZ-DEEP-47 | edit() blade uses old vehicle data pre-filled for all fields | Existing model data bound to form inputs | 
| BC-BIZ-DEEP-48 | `show()` view displays formatted dates and media previews | Dates formatted via Carbon, media images shown via Spatie `$vehicle->getFirstMediaUrl()` | 
| BC-BIZ-DEEP-49 | `trashed()` paginates at 10 per page — same as index() | `Vehicle::onlyTrashed()->paginate(10)` — consistent pagination with main list | 
| BC-BIZ-DEEP-50 | `Vehicle::query()` in index() — no default scope applied | Raw query builder, no `->active()` or other scopes | 
| BC-BIZ-DEEP-51 | All 8 media fields use same upload pattern in both store() and update() | Identical `$mediaFields` array in both methods | 
| BC-BIZ-DEEP-52 | `addMediaFromRequest()` uses the uploaded file directly without temporary storage | Streams directly from Request to MediaLibrary | 
| BC-BIZ-DEEP-53 | `usingFileName()` in store() but NOT in update() — inconsistency | store() renames files with timestamp prefix, update() uses original filename | 
| BC-BIZ-DEEP-54 | update() change tracking excludes `updated_at` from changes array | `if ($field === 'updated_at') { continue; }` — timestamp field skipped | 
| BC-BIZ-DEEP-55 | `changedAttributes` built as `[field => ['old' => value, 'new' => value]]` in update() | Passed to `activityLog()` as `changes` key for audit trail | 
| BC-BIZ-DEEP-56 | `toggleStatus()` validates `is_active` inline (`$request->validate`) not via FormRequest | Uses `required|boolean` rule — separate from VehicleRequest validation | 
| BC-BIZ-DEEP-57 | `toggleStatus()` success/failure returns same HTTP 200, only `success` bool differs | Both branches return 200 with JSON — no 4xx/5xx for failure | 
| BC-BIZ-DEEP-58 | `documentsUploaded` variable in store() is declared but never persisted to model | `$documentsUploaded = 1` in loop, but no `$vehicle->documents_uploaded = $documentsUploaded` — dead assignment | 
| BC-BIZ-DEEP-59 | `is_active` normalization differs between VehicleRequest and toggleStatus | Request uses `$this->boolean()`, toggleStatus uses `$request->boolean()` — same result, different context | 
| BC-BIZ-DEEP-60 | No file type/extension validation on media uploads (no mimes:jpeg,png rule in Request) | MediaLibrary accepts any file; validation relies on frontend accept attribute | 

### CODE-TRACE: Line-by-Line Method Trace

> ⚠️ **Note**: This traces the **standalone route** `/transport/vehicle` → `VehicleController::index()`. The **primary tab listing** at `/transport/master?tab=vehicle` goes through `TransportMasterController::index()` → `vehiclesQuery()` (see CODE-TRACE-A below).

#### CODE-TRACE-01: `index(Request $request)` — VehicleController Lines 19-43 (Standalone Route)

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 21 | `Gate::authorize('tenant.vehicle.viewAny')` | Authorization gate — user must have viewAny permission |
| 02 | 24 | `$vehicles = Vehicle::query()` | Start query builder on Vehicle model |
| 03 | 25-28 | `->when($request->filled('search'), fn($q) => $q->where('vehicle_no','like',"...{$request->search}%")->orWhere('registration_no','like',"...{$request->search}%"))` | Conditional search filter on vehicle_no and registration_no (LIKE) |
| 04 | 29-31 | `->when($request->filled('status'), fn($q) => $q->where('is_active', $request->status))` | Conditional status filter (exact match on is_active) |
| 05 | 32 | `->latest()` | Order by created_at DESC |
| 06 | 33 | `->paginate(10)` | Paginate 10 per page |
| 07 | 34 | `->withQueryString()` | Preserve query params in pagination links |
| 08 | 37-38 | `if ($request->ajax()) { return view(...)->render(); }` | AJAX request returns partial view (no layout) |
| 09 | 42 | `return view('transport::vehicle.index', compact('vehicles'))` | Full page load returns complete view with layout |

> 🔁 **Tab Flow**: `TransportMasterController::index()` (line 28-41) runs `Gate::any([...tenant.vehicle.viewAny...])` then calls `vehiclesQuery()` (line 85-95) with same query logic + ajax handling + `->withQueryString()`. Sets `$vendors` variable on paginator name `vehicles_page`.

#### CODE-TRACE-A: `vehiclesQuery(Request $request)` — TransportMasterController Lines 85-95 (Tab Listing)

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 28-41 | `Gate::any(['tenant.vehicle.viewAny', ...])` | Aggregate gate — user must have ANY transport master tab permission |
| 02 | 85 | `$query = Vehicle::query()` | Start query builder |
| 03 | 87 | `if ($request->input('tab') === 'vehicle')` | Only apply filters when Vehicle tab is active |
| 04 | 88-91 | `->when(search/status)` | Same search + status filters as standalone |
| 05 | 93 | `->latest()` | Order by created_at DESC |
| 06 | `index()` | `->paginate(10, ['*'], 'vehicles_page')` | Paginate with unique page name `vehicles_page` |
| 07 | `index()` | `->withQueryString()` | Preserve query params |
| 08 | `tab.blade.php` | `@include('transport::vehicle.index')` | Tab partial rendered inside transportmaster tab |

#### CODE-TRACE-02: `show(Vehicle $vehicle)` — Lines 48-55

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 50 | `Gate::authorize('tenant.vehicle.view')` | Authorization gate — view permission |
| 02 | 54 | `return view('transport::vehicle.show', compact('vehicle'))` | Route-model-binding resolves $vehicle automatically; returns show view |

#### CODE-TRACE-03: `create()` — Lines 60-68

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 62 | `Gate::authorize('tenant.vehicle.view')` | **ANOMALY**: Uses `view` instead of `create` — allows read-only users to access create form |
| 02 | 63 | `$vehicle = new Vehicle()` | Empty model instance for form binding |
| 03 | 65 | `Dropdown::where('key','vnd_vendors.vendor_type_id')->first()` | Fetch dropdown entry for vendor type |
| 04 | 66 | `Vendor::where('vendor_type_id',$dropdwon->id)->get()` | Load vendors filtered by vendor type |
| 05 | 67 | `return view('transport::vehicle.create', compact('vehicle','vendors'))` | Return create form view |

#### CODE-TRACE-04: `store(VehicleRequest $request)` — Lines 73-113

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 75 | `Gate::authorize('tenant.vehicle.create')` | Authorization gate — create permission |
| 02 | 77 | `$vehicle = Vehicle::create($request->validated())` | Mass-assign validated data to new Vehicle record |
| 03 | 79-88 | `$mediaFields = ['registration_img','pollution_img','fitness_img','insurance_img','vehicle_photo','vehicle_emission_cert_img','fire_extinguisher_cert_img','gps_device_cert_img']` | 8 document field names defined |
| 04 | 90 | `$documentsUploaded = 0` | Initialize counter flag |
| 05 | 92-103 | `foreach($mediaFields as $field) { if ($request->hasFile($field)) { ... } }` | Loop through all 8 fields, upload each if present |
| 06 | 95-99 | `$vehicle->addMediaFromRequest($field)->usingFileName(time().'_'.$request->file($field)->getClientOriginalName())->toMediaCollection($field)` | Upload file to Spatie MediaLibrary with timestamp prefix |
| 07 | 101 | `$documentsUploaded = 1` | Flag set but **NOT persisted** to model — dead assignment |
| 08 | 105-108 | `activityLog($vehicle, 'Stored', ['message' => 'Vehicle created successfully', 'performed_by' => auth()->user()->name])` | Activity log entry |
| 09 | 110-112 | `return redirect()->route('transport.transport-master.index')->with('success', flash('created.vehicle'))` | Redirect to transport master with success flash |

#### CODE-TRACE-05: `edit($id)` — Lines 118-126

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 120 | `Gate::authorize('tenant.vehicle.update')` | Authorization gate — update permission |
| 02 | 122 | `$vehicle = Vehicle::where('id',$id)->first()` | **Manual lookup** (not route-model-binding) — returns null if not found |
| 03 | 123 | `Dropdown::where('key','vnd_vendors.vendor_type_id')->first()` | Fetch dropdown entry for vendor type (same as create) |
| 04 | 124 | `Vendor::where('vendor_type_id',$dropdwon->id)->get()` | Load filtered vendors |
| 05 | 125 | `return view('transport::vehicle.edit', compact('vehicle','vendors'))` | Return edit form view |

#### CODE-TRACE-06: `update(VehicleRequest $request, Vehicle $vehicle)` — Lines 131-181

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 133 | `Gate::authorize('tenant.vehicle.update')` | Authorization gate — update permission |
| 02 | 135 | `$original = $vehicle->getOriginal()` | Capture pre-update state for change tracking |
| 03 | 137 | `$vehicle->update($request->validated())` | Mass-assign validated data |
| 04 | 139-148 | `$mediaFields = [...]` (same 8 fields) | Document field list |
| 05 | 150-156 | `foreach($mediaFields as $field) { if ($request->hasFile($field)) { $vehicle->clearMediaCollection($field); $vehicle->addMediaFromRequest($field)->toMediaCollection($field); } }` | Replace each document: clear old → add new |
| 06 | 158-170 | `$changes = $vehicle->getChanges(); $changedAttributes = []; foreach ($changes as $field => $newValue) { if ($field === 'updated_at') continue; $changedAttributes[$field] = ['old' => $original[$field] ?? null, 'new' => $newValue]; }` | Build change tracking array excluding updated_at |
| 07 | 172-176 | `activityLog($vehicle, 'Updated', ['message' => 'Vehicle updated successfully', 'changes' => $changedAttributes, 'performed_by' => Auth::user()->name])` | Activity log with detailed changes |
| 08 | 178-181 | `return redirect()->route('transport.transport-master.index')->with('success', flash('updated.vehicle'))` | Redirect with success flash |

#### CODE-TRACE-07: `destroy(Vehicle $vehicle)` — Lines 187-203

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 189 | `Gate::authorize('tenant.vehicle.delete')` | Authorization gate — delete permission |
| 02 | 191 | `$vehicle->is_active = false` | Deactivate vehicle before soft-delete |
| 03 | 192 | `$vehicle->save()` | Persist is_active change |
| 04 | 193 | `$vehicle->delete()` | Soft-delete (sets deleted_at) |
| 05 | 195-198 | `activityLog($vehicle, 'Trashed', ['message' => 'Vehicle was deactivated and deleted.', 'performed_by' => Auth::user()->name])` | Activity log entry |
| 06 | 200-202 | `return redirect()->route('transport.transport-master.index')->with('success', flash('trashed.vehicle'))` | Redirect with success flash |

#### CODE-TRACE-08: `trashed()` — Lines 208-215

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 210 | `Gate::authorize('tenant.vehicle.restore')` | Authorization gate — restore permission |
| 02 | 212 | `$vehicles = Vehicle::onlyTrashed()->paginate(10)` | Fetch only soft-deleted vehicles, paginated |
| 03 | 214 | `return view('transport::vehicle.trash', compact('vehicles'))` | Return trash view |

#### CODE-TRACE-09: `restore($id)` — Lines 220-235

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 222 | `Gate::authorize('tenant.vehicle.restore')` | Authorization gate — restore permission |
| 02 | 224 | `$vehicle = Vehicle::onlyTrashed()->findOrFail($id)` | Find soft-deleted record or 404 |
| 03 | 225 | `$vehicle->restore()` | Restore (sets deleted_at = NULL) — is_active remains FALSE |
| 04 | 227-230 | `activityLog($vehicle, 'Restored', ['message' => 'Vehicle was restored.', 'other' => 'some other information'])` | Activity log — **NOTE**: missing `performed_by` key |
| 05 | 232-234 | `return redirect()->route('transport.vehicle.trashed')->with('success', flash('restored.vehicle'))` | Redirect to trash page |

#### CODE-TRACE-10: `forceDelete($id)` — Lines 240-255

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 242 | `Gate::authorize('tenant.vehicle.forceDelete')` | Authorization gate — forceDelete permission |
| 02 | 244 | `$vehicle = Vehicle::withTrashed()->findOrFail($id)` | Find ANY record (active or trashed) or 404 |
| 03 | 245 | `$vehicle->forceDelete()` | Permanently delete from DB (media cascade deleted) |
| 04 | 247-250 | `activityLog($vehicle, 'Deleted', ['message' => 'Vehicle was permanently deleted.', 'performed_by' => Auth::user()->name])` | Activity log entry |
| 05 | 252-254 | `return redirect()->route('transport.vehicle.trashed')->with('success', flash('force_deleted.vehicle'))` | Redirect to trash page |

#### CODE-TRACE-11: `toggleStatus(Request $request, Vehicle $vehicle)` — Lines 260-288

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 262 | `Gate::authorize('tenant.vehicle.update')` | Authorization gate — update permission |
| 02 | 264-266 | `$request->validate(['is_active' => 'required|boolean'])` | Inline validation for is_active |
| 03 | 268 | `$vehicle->is_active = $request->boolean('is_active')` | Set status from boolean-normalized input |
| 04 | 270-274 | `activityLog($vehicle, 'Toggled', ['message' => 'Vehicle status updated.', 'performed_by' => Auth::user()->name])` | Activity log entry |
| 05 | 275 | `if ($vehicle->save())` | Persist and check success |
| 06 | 276-280 | `return response()->json(['success' => true, 'is_active' => $vehicle->is_active, 'message' => flash('status_updated.vehicle')])` | Success JSON response |
| 07 | 283-287 | `return response()->json(['success' => false, 'is_active' => $vehicle->is_active, 'message' => flash('status_switch_failed.vehicle')])` | Failure JSON response (save returned false) |

---

## 6. Test Case List

### TC-P: Positive Test Cases

| ID | Test Case | Summary | Expected Result |
|----|-----------|---------|-----------------|
| TC-P-01 | Create vehicle with all fields | Fill all fields + 8 document uploads | Vehicle created, media collections populated, flash "created.vehicle" |
| TC-P-02 | Create vehicle with minimum fields | Only required fields, no documents | Vehicle created, no media, activity log "Stored" |
| TC-P-03 | Edit vehicle vehicle_no | Change vehicle number | Updated, change tracking logs old/new |
| TC-P-04 | Edit vehicle capacity | Increase capacity from 40 to 45 | Updated, validated max_capacity >= capacity |
| TC-P-05 | Replace document on edit | Upload new insurance image | Old file cleared, new file in `insurance_img` collection |
| TC-P-06 | Toggle vehicle active→inactive | Click status switch | AJAX response `{success:true, is_active:0}` |
| TC-P-07 | View vehicle details | Click show action | Show page with all fields, formatted dates, media previews |
| TC-P-08 | Search vehicle by registration no | Type partial registration | Filtered results |
| TC-P-09 | Filter by active status | Select "Active" | Only active vehicles |
| TC-P-10 | AJAX partial load | Switch to Vehicle tab via JS | Partial view returned (no layout) |
| TC-P-11 | Restore soft-deleted vehicle | Trash → Restore | Vehicle restored (inactive), flash "restored.vehicle" |
| TC-P-12 | Create vehicle max vehicle_no length | vehicle_no = 20 chars | Successfully created |
| TC-P-13 | Force delete trashed vehicle | Soft-delete → Trash → Force Delete | Vehicle + media permanently removed, flash "force_deleted.vehicle" |

### TC-N: Negative Test Cases

| ID | Test Case | Summary | Expected Result |
|----|-----------|---------|-----------------|
| TC-N-01 | Create vehicle with empty vehicle_no | Submit without vehicle_no | "The vehicle no field is required." |
| TC-N-02 | Create vehicle with empty registration_no | Submit without registration_no | "The registration no field is required." |
| TC-N-03 | Create vehicle with duplicate vehicle_no | Use existing vehicle_no | "The vehicle no has already been taken." |
| TC-N-04 | Create vehicle with duplicate registration_no | Use existing registration_no | "The registration no has already been taken." |
| TC-N-05 | Create vehicle with capacity > max_capacity | capacity=50, max_capacity=40 | "The max capacity must be greater than or equal to capacity." |
| TC-N-06 | Create vehicle with invalid vendor_id | vendor_id=99999 | "The selected vendor id is invalid." |
| TC-N-07 | Create vehicle with empty vehicle_type_id | Skip dropdown | "The vehicle type id field is required." |
| TC-N-08 | Upload non-image file to vehicle_photo | Upload .txt file | MediaLibrary validation error |
| TC-N-09 | Access index without permission | User lacks `tenant.vehicle.viewAny` | 403 Access Denied |
| TC-N-10 | Access create without `tenant.vehicle.view` | User lacks view permission | 403 Access Denied |
| TC-N-11 | Access edit without permission | User lacks `tenant.vehicle.update` | 403 Access Denied |
| TC-N-12 | Attempt delete without permission | User lacks `tenant.vehicle.delete` | 403 Access Denied |
| TC-N-13 | Attempt store/POST without `tenant.vehicle.create` | User lacks create permission | 403 Access Denied (Gate in `store()`) |
| TC-N-14 | Access trashed page without `tenant.vehicle.restore` | User lacks restore permission | 403 Access Denied |
| TC-N-15 | Attempt forceDelete without `tenant.vehicle.forceDelete` | User lacks forceDelete permission | 403 Access Denied |
| TC-N-16 | Restore non-trashed (active) vehicle | Call restore on vehicle not in trash | 404 — `onlyTrashed()->findOrFail()` returns no record |
| TC-N-17 | Show non-existent vehicle ID | Route-model-binding on deleted ID | 404 — implicit `findOrFail` from route-model-binding |
| TC-N-18 | Toggle status with invalid `is_active` value | Send `is_active=2` (non-boolean) | Validation error: "The is active field must be true or false." |

### TC-D: Data Integrity Test Cases

| ID | Test Case | Summary | Expected Result |
|----|-----------|---------|-----------------|
| TC-D-01 | Delete vehicle with active assignments | Vehicle assigned to driver-route | Vehicle soft-deleted, assignments remain (FK SET NULL for personnel, CASCADE for inspections) |
| TC-D-02 | Force delete vehicle with media | Permanently remove trashed vehicle | Vehicle + media records deleted from DB |
| TC-D-03 | Verify is_active=false before soft-delete | Query trashed vehicle | `is_active=0`, `deleted_at` NOT NULL |
| TC-D-04 | Verify composite unique on (vehicle_no, registration_no) | Insert (ABC, XYZ) then (XYZ, ABC) | DB allows both (composite unique on pair). However, Request-layer individual unique rules on each field would block swapped pairs — test only works at DB level bypassing Request |
| TC-D-05 | Verify 8 `*_upload` flags exist in DDL but Model has single `documents_uploaded` | **GAP**: DDL has 8 individual upload tracking columns | Model cannot track individual cert upload status — only single flag |
| TC-D-06 | Duplicate vehicle_no after force-delete | Hard-delete vehicle_no "MH12", create new with same | Allowed (no conflict) |
| TC-D-07 | Vendor FK constraint on vehicle | Delete vendor that has vehicles referencing it | DB FK CASCADE or RESTRICT per DDL (`vnd_vendors.id` CASCADE) |
| TC-D-08 | Dropdown FK constraint on vehicle | Delete `sys_dropdown_table` entry referenced by vehicle_type_id/fuel_type_id/etc. | DB FK CASCADE deletes the referenced dropdown value |
| TC-D-09 | Toggle status inactive→active | Click status switch on inactive vehicle | AJAX response `{success:true, is_active:1}` — toggleStatus works bidirectionally |

### TC-CR: Code Review Test Cases

| ID | Test Case | Source | Expected Result |
|----|-----------|--------|-----------------|
| TC-CR-01 | Verify `Gate::authorize()` in `index()` | `VehicleController.php:21` | `tenant.vehicle.viewAny` |
| TC-CR-02 | Verify `Gate::authorize()` in `show()` | `VehicleController.php:50` | `tenant.vehicle.view` |
| TC-CR-03 | **ANOMALY**: `create()` uses `tenant.vehicle.view` instead of `tenant.vehicle.create` | `VehicleController.php:62` | Should be `tenant.vehicle.create` — bug? |
| TC-CR-04 | Verify `Gate::authorize()` in `store()` | `VehicleController.php:75` | `tenant.vehicle.create` |
| TC-CR-05 | Verify `Gate::authorize()` in `edit()` | `VehicleController.php:120` | `tenant.vehicle.update` |
| TC-CR-06 | Verify `Gate::authorize()` in `update()` | `VehicleController.php:133` | `tenant.vehicle.update` |
| TC-CR-07 | Verify `Gate::authorize()` in `destroy()` | `VehicleController.php:189` | `tenant.vehicle.delete` |
| TC-CR-08 | Verify `Gate::authorize()` in `toggleStatus()` | `VehicleController.php:262` | `tenant.vehicle.update` |
| TC-CR-09 | Verify `activityLog()` in `store()` | `VehicleController.php:105-108` | "Vehicle created successfully" |
| TC-CR-10 | Verify `activityLog()` in `update()` with change tracking | `VehicleController.php:158-176` | `$vehicle->getChanges()`, builds `$changedAttributes` |
| TC-CR-11 | Verify `activityLog()` in `destroy()` | `VehicleController.php:195-198` | "Vehicle was deactivated and deleted." |
| TC-CR-12 | Verify `activityLog()` in `restore()` | `VehicleController.php:227-230` | "Vehicle was restored." |
| TC-CR-13 | Verify `activityLog()` in `forceDelete()` | `VehicleController.php:247-250` | "Vehicle was permanently deleted." |
| TC-CR-14 | Verify `activityLog()` in `toggleStatus()` | `VehicleController.php:270-273` | "Vehicle status updated." |
| TC-CR-15 | Verify media upload loop in `store()` | `VehicleController.php:79-103` | 8 media fields, `addMediaFromRequest()`, `usingFileName()` with timestamp |
| TC-CR-16 | Verify media replace in `update()` | `VehicleController.php:139-156` | `clearMediaCollection()` then `addMediaFromRequest()` |
| TC-CR-17 | Verify `is_active=false` before `delete()` in `destroy()` | `VehicleController.php:191-193` | Pattern: `is_active=false → save() → delete()` |
| TC-CR-18 | Verify `VehicleRequest@authorize()` for POST | `VehicleRequest.php:14-15` | `tenant.vehicle.create` |
| TC-CR-19 | Verify `VehicleRequest@prepareForValidation()` | `VehicleRequest.php:93-98` | `$this->boolean('is_active')` |
| TC-CR-20 | Verify redirect after store/update/destroy | All CRUD | `transport.transport-master.index` |
| TC-CR-21 | Verify redirect after restore/forceDelete | `restore()`, `forceDelete()` | `transport.vehicle.trashed` |
| TC-CR-22 | Verify `$fillable` includes `documents_uploaded` | `Vehicle.php:42` | Single flag (DDL has 8 individual flags — GAP) |
| TC-CR-23 | Verify `$casts` for dates | `Vehicle.php:50-53` | `*_valid_upto` as `date` |
| TC-CR-24 | Verify `registerMediaCollections()` | `Vehicle.php:120-133` | 8 single-file collections |
| TC-CR-25 | Verify `registerMediaConversions()` only for `vehicle_photo` | `Vehicle.php:139-153` | Small 150x150, Medium 300x300, nonQueued |
| TC-CR-26 | Verify `scopeActive()` | `Vehicle.php:159-162` | `where('is_active', true)` |
| TC-CR-27 | Verify vendor loading via Dropdown key `vnd_vendors.vendor_type_id` | `VehicleController.php:65-66,123-124` | Dropdown key lookup on `vnd_vendors.vendor_type_id` |
| TC-CR-28 | Verify AJAX handling in `index()` | `VehicleController.php:37-38` | `$request->ajax()` → `->render()` |
| TC-CR-29 | Verify `withQueryString()` on paginator | `VehicleController.php:34` | Preserves search/status params |
| TC-CR-30 | Verify `@canany(['tenant.vehicle.edit', 'tenant.vehicle.delete'])` in index blade | `vehicle/index.blade.php:37,53` | Action column conditional |
| TC-CR-31 | Verify DDL has 8 `*_upload` TINYINT flags | DDL lines 28-35 | Individual flags per cert type — **GAP**: model doesn't use them |
| TC-CR-32 | Verify `VehiclePolicy` has `status()` method | `VehiclePolicy.php:29-32` | `tenant.vehicle.status` — not used in any controller |
| TC-CR-33 | **OBSERVATION**: `restore()` activityLog lacks `performed_by` | `VehicleController.php:227-230` | Only `message` and `other` keys passed — no `performed_by`. Inconsistent with all other activityLog calls |
| TC-CR-34 | Verify `VehicleRequest@authorize()` for PUT/PATCH | `VehicleRequest.php:17` | Returns `Gate::allows('tenant.vehicle.update')` for non-POST methods (edit/update) |
| TC-CR-35 | Verify `toggleStatus()` returns both success/false JSON paths | `VehicleController.php:275-287` | Success branch returns `{success:true}`, save-fail branch returns `{success:false}` |
| TC-CR-36 | Verify `scopeActive()` on model | `Vehicle.php:159-162` | `where('is_active', true)` — not used in any controller query |
| TC-CR-37 | Verify `availability_status` in fillable but absent from Request | `Vehicle.php:40` vs `VehicleRequest.php` | Field is fillable but has no validation rule — defaults to DB DEFAULT 1 |
| TC-CR-38 | Verify `documentsUploaded` variable never persisted | `VehicleController.php:90,101` | Variable set to 1 but never assigned to model — dead code |
| TC-CR-39 | Verify `usingFileName()` in store() but not in update() | `VehicleController.php:96-98` vs 153-154 | store() renames files, update() uses original — inconsistency |
| TC-CR-40 | Verify redirect route for all CRUD methods | `VehicleController.php:110,178,200,232,252` | All redirect to `transport.transport-master.index` except restore/forceDelete which go to `transport.vehicle.trashed` |
| TC-CR-41 | Verify `is_active` field absence from `$fillable` | `Vehicle.php:39-44` | `is_active` NOT in fillable — must be set via `$vehicle->is_active = ...` then `save()` |
| TC-CR-42 | Verify `availability_status` in `$fillable` with no validation exposure | `Vehicle.php:40` | Fillable but unvalidated — potential mass-assignment risk |
| TC-CR-43 | Verify `Vehicle` model `$casts` for dates | `Vehicle.php:50-53` | `*_valid_upto` as `date` → Carbon instances |
| TC-CR-44 | Verify `Vehicle` model `$casts` for booleans | `Vehicle.php:47-49` | `is_active`, `availability_status`, `documents_uploaded` as `boolean` |
| TC-CR-45 | Verify `Vehicle` model `$casts` for foreign keys | `Vehicle.php:46` | `vendor_id`, FK fields as `integer` |
| TC-CR-46 | Verify Gate consistency: index=viewAny, show/view=view, create=view (anomaly) | `VehicleController.php:21,50,62` | create() uses view instead of create — **documented anomaly** |
| TC-CR-47 | Verify `Auth::user()->name` vs `auth()->user()->name` inconsistency | `VehicleController.php:107,173,197,248,272` | store() uses `auth()->user()`, others use `Auth::user()` — functionally same, style inconsistency |
| TC-CR-48 | Verify no file size validation on media uploads | `VehicleRequest.php` | No `max:2048` or size rule — any size file accepted |
| TC-CR-49 | Verify `vehicle_photo` conversion is non-queued | `Vehicle.php:145-150` | `nonQueued()` — conversions run synchronously during upload |
| TC-CR-50 | Verify `$vehicle->save()` return value check only in toggleStatus | `VehicleController.php:275` | Only toggleStatus checks save() return; other methods assume success |

---

## 7. Detailed Test Steps

### TC-P-01: Create vehicle with all fields + documents

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user with `tenant.vehicle.create` permission | Success |
| 2 | Navigate to Vehicle create page (`/transport/vehicle/create`) | Create form displayed with all fields and vendor dropdown |
| 3 | Fill: vehicle_no="MH12AB1234", registration_no="GJ05XY6789", model="ABC 2024", manufacturer="Tata" | Fields populated |
| 4 | Select: vehicle_type="BUS", fuel_type="Diesel", ownership_type="Owned" | Dropdowns selected |
| 5 | Enter: capacity=40, max_capacity=45 | Numeric fields filled |
| 6 | Select: vehicle_emission_class="BS VI" | Dropdown selected |
| 7 | Select: fitness_valid_upto="2027-06-30", insurance_valid_upto="2027-06-30", pollution_valid_upto="2027-06-30", fire_extinguisher_valid_upto="2027-06-30" | Date pickers set |
| 8 | Select vendor from dropdown | Vendor selected |
| 9 | Upload 8 document files (images) — registration_img, pollution_img, fitness_img, insurance_img, vehicle_photo, vehicle_emission_cert_img, fire_extinguisher_cert_img, gps_device_cert_img | All 8 files queued for upload |
| 10 | Click "Save" | POST to `/transport/vehicle` with all data + files |
| 11 | **Verify**: `Gate::authorize('tenant.vehicle.create')` at `VehicleController.php:75` passes | Authorization ok |
| 12 | **Verify**: `VehicleRequest` rules pass (all 16 fields validated) | No validation errors |
| 13 | **Verify**: `Vehicle::create($request->validated())` inserts row in `tpt_vehicle` | DB has vehicle_no="MH12AB1234" |
| 14 | **Verify**: Foreach loop over 8 `$mediaFields`: `addMediaFromRequest($field)->usingFileName(...)->toMediaCollection($field)` | 8 media records in `media` table, each with `collection_name` matching field |
| 15 | **Verify**: Filenames prefixed with `time()_` + original name | Files named e.g. `1723456789_registration.jpg` |
| 16 | **Verify**: `activityLog()` called with type "Stored" | Activity log: "Vehicle created successfully" by user |
| 17 | **Verify**: Redirected to `transport.transport-master.index` with `?tab=vehicle` | Transport Master page loaded |
| 18 | **Verify**: Flash message `flash('created.vehicle')` displayed | Success notification visible |
| 19 | **Verify**: Vehicle appears in paginated index list | Vehicle No "MH12AB1234" visible |
| 20 | **Verify**: Fuel type displayed via `$vehicle->fuelType->value` relationship | e.g. "Diesel" shown |

### TC-P-02: Create vehicle with minimum fields (no documents)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.vehicle.create` permission | Success |
| 2 | Navigate to create page | Create form displayed |
| 3 | Fill only required fields: vehicle_no="MIN01", registration_no="MINREG01", vehicle_type, fuel_type, ownership_type, capacity=20, max_capacity=25, vehicle_emission_class, 4 date fields, vendor_id | Only required fields filled |
| 4 | Leave all 8 file uploads empty | No files selected |
| 5 | Leave optional fields empty: model, manufacturer, gps_device_id | Nullable fields omitted |
| 6 | Click "Save" | POST to store |
| 7 | **Verify**: Validation passes — nullable fields not required | No errors |
| 8 | **Verify**: Vehicle created with `documents_uploaded=0` (default) | DB row inserted |
| 9 | **Verify**: No media records created | `media` table has no entries for this vehicle |
| 10 | **Verify**: `activityLog()` recorded | Activity log: "Stored — Vehicle created successfully" |
| 11 | **Verify**: Redirect + flash success | Success message shown |

### TC-P-03: Edit vehicle vehicle_no

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.vehicle.update` permission | Success |
| 2 | Navigate to Transport Master → Vehicle tab | Vehicle list displayed |
| 3 | Click edit icon on existing vehicle "MH12AB1234" | GET to `/transport/vehicle/{id}/edit` |
| 4 | **Verify**: `Gate::authorize('tenant.vehicle.update')` at `VehicleController.php:120` passes | Authorized |
| 5 | **Verify**: `Vehicle::where('id',$id)->first()` loads existing data | Edit form pre-filled |
| 6 | **Verify**: Vendor dropdown loaded via Dropdown key lookup | Vendors available |
| 7 | Change vehicle_no from "MH12AB1234" to "MH12CD5678" | Input updated |
| 8 | Click "Update" | PUT to `/transport/vehicle/{id}` |
| 9 | **Verify**: `$original = $vehicle->getOriginal()` captures pre-state | Original vehicle_no = "MH12AB1234" |
| 10 | **Verify**: `$vehicle->update($request->validated())` | DB updated, vehicle_no changed |
| 11 | **Verify**: `$changes = $vehicle->getChanges()` includes `vehicle_no` | `changes[vehicle_no][old]="MH12AB1234"`, `changes[vehicle_no][new]="MH12CD5678"` |
| 12 | **Verify**: `updated_at` excluded from change tracking | No `updated_at` in `$changedAttributes` |
| 13 | **Verify**: `activityLog()` with type "Updated" and `changes` array | Activity log shows old/new values |
| 14 | **Verify**: Redirect + flash `flash('updated.vehicle')` | Success message displayed |

### TC-P-04: Edit vehicle capacity

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.vehicle.update` | Success |
| 2 | Edit vehicle with capacity=40, max_capacity=45 | Pre-filled form |
| 3 | Change capacity from 40 to 42, keep max_capacity=45 | capacity < max_capacity (valid) |
| 4 | Click "Update" | PUT request |
| 5 | **Verify**: Validation `gte:capacity` passes (45 >= 42) | No error |
| 6 | **Verify**: `update()` persists new capacity=42 | DB capacity=42 |
| 7 | **Verify**: Change tracking logs `capacity` old=40, new=42 | Activity log entry |

### TC-P-05: Replace document on update

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user with `tenant.vehicle.update` permission | Success |
| 2 | Navigate to edit existing vehicle | Edit form with current data |
| 3 | Note existing insurance_img document | Current file attached |
| 4 | Upload new insurance_img file (different image) | New file selected |
| 5 | Click "Update" | PUT request |
| 6 | **Verify**: `$request->hasFile('insurance_img')` = true | File detected |
| 7 | **Verify**: `$vehicle->clearMediaCollection('insurance_img')` called | Old media record removed from `media` table |
| 8 | **Verify**: `$vehicle->addMediaFromRequest('insurance_img')->toMediaCollection('insurance_img')` | New media record attached |
| 9 | **Verify**: `media` table has exactly 1 record for `insurance_img` collection (replaced) | Single file |
| 10 | **Verify**: Activity log records "Updated" with change details | Entry created |
| 11 | **Verify**: Redirect + flash success | Confirmation shown |

### TC-P-06: Toggle vehicle active→inactive

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.vehicle.update` permission | Success |
| 2 | Navigate to Transport Master → Vehicle tab | Vehicle list |
| 3 | Locate an active vehicle status toggle switch | Toggle is ON (green/checked) |
| 4 | Click the status toggle switch | AJAX POST to `/transport/vehicle/{vehicle}/toggle-status` |
| 5 | **Verify**: `Gate::authorize('tenant.vehicle.update')` at `VehicleController.php:262` passes | Authorized |
| 6 | **Verify**: `$request->validate(['is_active' => 'required|boolean'])` passes | Inline validation ok |
| 7 | **Verify**: `$request->boolean('is_active')` returns false (toggle sends current opposite state) | False |
| 8 | **Verify**: `$vehicle->is_active = false` | Property set |
| 9 | **Verify**: `$vehicle->save()` returns true | DB updated |
| 10 | **Verify**: JSON response `{success: true, is_active: false, message: '...'}` (200 OK) | `flash('status_updated.vehicle')` message |
| 11 | **Verify**: Toggle switch now OFF (grey/unchecked) | UI updated via JS callback |

### TC-P-07: View vehicle details

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.vehicle.view` permission | Success |
| 2 | Navigate to Transport Master → Vehicle tab | Vehicle list |
| 3 | Click view/show icon on a vehicle row | GET to `/transport/vehicle/{id}` |
| 4 | **Verify**: `Gate::authorize('tenant.vehicle.view')` at `VehicleController.php:50` passes | Authorized |
| 5 | **Verify**: Route-model-binding resolves `Vehicle $vehicle` | Vehicle found |
| 6 | **Verify**: Show view renders all fields: vehicle_no, registration_no, model, manufacturer, vehicle_type, fuel_type, ownership_type, capacity, max_capacity, emission_class, 4 valid_upto dates, vendor, gps_device_id, is_active, availability_status | All data displayed |
| 7 | **Verify**: Dates formatted via Carbon (cast as `date`) | Human-readable date format |
| 8 | **Verify**: Media previews shown for uploaded documents via `getFirstMediaUrl()` | Image thumbnails visible |
| 9 | **Verify**: Vehicle photo conversion (small 150x150) displayed | Conversion registered for vehicle_photo |

### TC-P-08: Search vehicle by registration no

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.vehicle.viewAny` | Success |
| 2 | Navigate to Transport Master → Vehicle tab | Vehicle list with search bar |
| 3 | Type partial registration number "GJ05" in search box | Search input filled |
| 4 | Submit search (press Enter or click search icon) | GET with `?search=GJ05` |
| 5 | **Verify**: Controller line 25-28: `->when($request->filled('search'), fn => where('vehicle_no','like','%GJ05%')->orWhere('registration_no','like','%GJ05%'))` | Query applied |
| 6 | **Verify**: `->paginate(10)` with `->withQueryString()` | Pagination preserves `search=GJ05` param |
| 7 | **Verify**: Only vehicles with "GJ05" in registration_no displayed | Filtered results |
| 8 | **Verify**: Non-matching vehicles excluded | Not in results |
| 9 | Click pagination page 2 (if applicable) | URL: `?search=GJ05&page=2` — search param preserved |

### TC-P-09: Filter by active status

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.vehicle.viewAny` | Success |
| 2 | Navigate to Vehicle tab | List with status filter dropdown |
| 3 | Select "Active" from status filter | `status=1` filter |
| 4 | Submit filter | GET with `?status=1` |
| 5 | **Verify**: Controller line 29-31: `->when($request->filled('status'), fn => where('is_active', 1))` | Query applied |
| 6 | **Verify**: Only is_active=1 vehicles displayed | No inactive vehicles |
| 7 | Change to "Inactive" filter | `?status=0` — only inactive displayed |
| 8 | **Verify**: Status filter + search work together | `?search=&status=` params combined |

### TC-P-10: AJAX partial load

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user with `tenant.vehicle.viewAny` | Success |
| 2 | Navigate to Transport Master page | Page loads with active tab |
| 3 | Click Vehicle tab (if not already active) | JS fires AJAX GET to `/transport/vehicle` with `X-Requested-With: XMLHttpRequest` |
| 4 | **Verify**: Controller line 37-38: `if ($request->ajax())` = true | AJAX path taken |
| 5 | **Verify**: `return view('transport::vehicle.index', compact('vehicles'))->render()` | HTML fragment returned (no `<html>/<body>` layout) |
| 6 | **Verify**: Tab content updated with rendered HTML | Vehicle list displayed correctly inside tab pane |
| 7 | **Verify**: Pagination links contain `?tab=vehicle` | Tab param preserved |
| 8 | **Verify**: Status toggles and action buttons functional in loaded fragment | JS bound to new DOM elements |

### TC-P-11: Restore soft-deleted vehicle

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.vehicle.restore` permission | Success |
| 2 | Navigate to trash page (`/transport/vehicle/trash`) | Only soft-deleted vehicles |
| 3 | **Verify**: `Gate::authorize('tenant.vehicle.restore')` at `VehicleController.php:210` passes | Authorized |
| 4 | **Verify**: `Vehicle::onlyTrashed()->paginate(10)` | 10 trashed vehicles per page |
| 5 | Click "Restore" on a trashed vehicle | GET to `/transport/vehicle/{id}/restore` |
| 6 | **Verify**: `Vehicle::onlyTrashed()->findOrFail($id)` | Record found (deleted_at IS NOT NULL) |
| 7 | **Verify**: `$vehicle->restore()` sets `deleted_at = NULL` | Vehicle restored |
| 8 | **Verify**: `is_active` remains FALSE (was set false during destroy) | `is_active=0` |
| 9 | **Verify**: `activityLog($vehicle, 'Restored', [...])` | Activity log: "Vehicle was restored." |
| 10 | **Note**: `performed_by` missing from activityLog — **OBSERVATION** | Log entry lacks user reference |
| 11 | **Verify**: Redirect to `transport.vehicle.trashed` | Back to trash page |
| 12 | **Verify**: Flash `flash('restored.vehicle')` | Success message |
| 13 | **Verify**: Vehicle removed from trash list | No longer visible in trash |
| 14 | Navigate to active Vehicle tab | Vehicle visible (inactive status) |

### TC-P-12: Create vehicle with max vehicle_no length

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.vehicle.create` | Success |
| 2 | Navigate to create page | Form loaded |
| 3 | Enter vehicle_no = "ABCDEFGHIJ1234567890" (20 chars — max length) | Input accepts 20 characters |
| 4 | Fill all other required fields with valid data | Complete form |
| 5 | Click "Save" | POST to store |
| 6 | **Verify**: `VehicleRequest` rule `max:20` passes | No error |
| 7 | **Verify**: Vehicle created with 20-char vehicle_no | DB stores full value |
| 8 | **Verify**: Redirect + flash success | Confirmation |

### TC-P-13: Force delete trashed vehicle

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.vehicle.forceDelete` permission | Success |
| 2 | Navigate to trash page (`/transport/vehicle/trash`) | Trashed vehicles listed |
| 3 | Locate a trashed vehicle | Vehicle with `deleted_at` IS NOT NULL |
| 4 | Click "Force Delete" (permanent delete action) | GET to `/transport/vehicle/{id}/force-delete` |
| 5 | **Verify**: `Gate::authorize('tenant.vehicle.forceDelete')` at `VehicleController.php:242` passes | Authorized |
| 6 | **Verify**: `Vehicle::withTrashed()->findOrFail($id)` | Record found (even though soft-deleted) |
| 7 | **Verify**: `$vehicle->forceDelete()` | Record permanently deleted from `tpt_vehicle` |
| 8 | **Verify**: Associated media records cascade-deleted | `media` table entries removed |
| 9 | **Verify**: `activityLog($vehicle, 'Deleted', [...])` | Activity log: "Vehicle was permanently deleted." |
| 10 | **Verify**: Redirect to `transport.vehicle.trashed` + flash `flash('force_deleted.vehicle')` | Success message |
| 11 | **Verify**: Vehicle removed from trash list | No longer visible |

### TC-P-14: Create vehicle with gps_device_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.vehicle.create` | Success |
| 2 | Fill all required fields + enter gps_device_id = "GPS-2024-001" | Optional field filled |
| 3 | Click "Save" | POST to store |
| 4 | **Verify**: `VehicleRequest` rule `nullable|string|max:50` passes | Valid |
| 5 | **Verify**: `gps_device_id` stored as "GPS-2024-001" | DB column populated |

### TC-P-15: Edit with all document replacements simultaneously

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.vehicle.update` | Success |
| 2 | Edit existing vehicle | Form pre-filled |
| 3 | Upload new files for ALL 8 document fields simultaneously | 8 files selected |
| 4 | Click "Update" | PUT request |
| 5 | **Verify**: Foreach over `$mediaFields`: `clearMediaCollection()` + `addMediaFromRequest()` called 8 times | All 8 collections cleared and repopulated |
| 6 | **Verify**: `media` table has exactly 8 records for this vehicle | One per collection |
| 7 | **Verify**: Each collection has exactly 1 file | Single-file constraint maintained |

### TC-P-16: Search by vehicle_no

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.vehicle.viewAny` | Success |
| 2 | Navigate to Vehicle tab | List displayed |
| 3 | Search "MH12" | GET with `?search=MH12` |
| 4 | **Verify**: Controller `where('vehicle_no','like','%MH12%')` | Matching by vehicle_no |
| 5 | **Verify**: Only vehicles with "MH12" in vehicle_no | Filtered |

### TC-P-17: Pagination navigation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure 15+ vehicles exist in DB | At least 2 pages |
| 2 | Navigate to Vehicle tab | Page 1 with 10 vehicles |
| 3 | Verify pagination links visible | `1 2 Next »` or similar |
| 4 | Click page 2 | GET with `?page=2` |
| 5 | **Verify**: `->paginate(10)` returns page 2 | Records 11-20 displayed |
| 6 | **Verify**: `withQueryString()` preserves any active search/status filters | Params in URL |

### TC-P-18: Toggle vehicle inactive→active (bidirectional)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.vehicle.update` | Success |
| 2 | Find an inactive vehicle | is_active=0 |
| 3 | Click status toggle switch | AJAX POST to toggleStatus |
| 4 | **Verify**: `$request->boolean('is_active')` returns true | Toggle sends is_active=true |
| 5 | **Verify**: `$vehicle->is_active = true` | Property set |
| 6 | **Verify**: JSON response `{success: true, is_active: true}` | Toggle now ON |

### TC-P-19: Edit vehicle with same data (no changes)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.vehicle.update` | Success |
| 2 | Edit vehicle, keep all values unchanged | Submit same data |
| 3 | Click "Update" | PUT request |
| 4 | **Verify**: Validation passes | No errors |
| 5 | **Verify**: `$changes = $vehicle->getChanges()` | May be empty (no attributes changed) |
| 6 | **Verify**: `activityLog()` still called with "Updated" | Activity log recorded even with no changes |
| 7 | **Verify**: Redirect + flash success | Confirmation shown |

### TC-P-20: Filter by inactive status

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.vehicle.viewAny` | Success |
| 2 | Select "Inactive" from status filter | `status=0` |
| 3 | Submit | GET with `?status=0` |
| 4 | **Verify**: `->when($request->filled('status'), fn => where('is_active', 0))` | Only inactive vehicles |
| 5 | **Verify**: All displayed vehicles have `is_active=0` | Filter correct |

### TC-N-01: Create vehicle with empty vehicle_no

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.vehicle.create` | Success |
| 2 | Navigate to create page | Form displayed |
| 3 | Leave vehicle_no EMPTY, fill all other required fields | vehicle_no omitted |
| 4 | Click "Save" | POST request |
| 5 | **Verify**: `VehicleRequest` rule `required` on `vehicle_no` | Validation error: "The vehicle no field is required." |
| 6 | **Verify**: No vehicle created | DB unchanged |
| 7 | **Verify**: Form re-displayed with validation error | Error message visible |

### TC-N-02: Create vehicle with empty registration_no

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.vehicle.create` | Success |
| 2 | Navigate to create page | Form displayed |
| 3 | Leave registration_no EMPTY, fill all other fields | registration_no omitted |
| 4 | Click "Save" | POST request |
| 5 | **Verify**: `VehicleRequest` rule `required` on `registration_no` | "The registration no field is required." |
| 6 | **Verify**: No vehicle created | DB unchanged |

### TC-N-03: Create vehicle with duplicate vehicle_no

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure vehicle with vehicle_no="MH12AB1234" exists | Existing record |
| 2 | Create new vehicle with same vehicle_no="MH12AB1234" | Duplicate |
| 3 | Click "Save" | POST request |
| 4 | **Verify**: `VehicleRequest` rule `Rule::unique('tpt_vehicle', 'vehicle_no')` | "The vehicle no has already been taken." |
| 5 | **Verify**: No duplicate created | DB has 1 record with that vehicle_no |

### TC-N-04: Create vehicle with duplicate registration_no

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure vehicle with registration_no="GJ05XY6789" exists | Existing record |
| 2 | Create new vehicle with same registration_no="GJ05XY6789" | Duplicate |
| 3 | Click "Save" | POST request |
| 4 | **Verify**: `VehicleRequest` unique rule on `registration_no` | "The registration no has already been taken." |
| 5 | **Verify**: No duplicate created | DB unique maintained |

### TC-N-05: Capacity > max_capacity

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.vehicle.create` permission | Success |
| 2 | Navigate to create page | Form displayed |
| 3 | Enter capacity=50, max_capacity=40 | Violates gte:capacity rule |
| 4 | Click "Save" | POST request |
| 5 | **Verify**: `VehicleRequest` rule `gte:capacity` | "The max capacity must be greater than or equal to capacity." |
| 6 | **Verify**: Error on `max_capacity` field | Field-specific error |
| 7 | **Verify**: No vehicle created | DB unchanged |
| 8 | **Verify**: Form re-displayed with validation error | Error message visible on form |

### TC-N-06: Create vehicle with invalid vendor_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.vehicle.create` | Success |
| 2 | Create vehicle with vendor_id=99999 | Non-existent vendor |
| 3 | Click "Save" | POST request |
| 4 | **Verify**: `VehicleRequest` rule `exists:vnd_vendors,id` | "The selected vendor id is invalid." |
| 5 | **Verify**: No vehicle created | DB unchanged |

### TC-N-07: Create vehicle with empty vehicle_type_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.vehicle.create` | Success |
| 2 | Leave vehicle_type_id unselected, fill all other fields | Dropdown not chosen |
| 3 | Click "Save" | POST request |
| 4 | **Verify**: `VehicleRequest` rule `required|integer` on `vehicle_type_id` | "The vehicle type id field is required." |
| 5 | **Verify**: No vehicle created | DB unchanged |

### TC-N-08: Upload non-image file to vehicle_photo

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.vehicle.create` | Success |
| 2 | Navigate to create page | Form displayed |
| 3 | Fill all required fields with valid data | Complete form |
| 4 | Upload a `.txt` file to vehicle_photo upload field | Non-image file |
| 5 | Click "Save" | POST request |
| 6 | **Verify**: Spatie MediaLibrary rejects non-image | MediaLibrary validation error (mime type) |
| 7 | **Note**: VehicleRequest has NO `mimes:jpeg,png` rule — relies on MediaLibrary | No explicit file type validation in Request |
| 8 | **Verify**: Vehicle not created (or created without photo) | Behavior depends on error handling |

### TC-N-09: Access index without permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user WITHOUT `tenant.vehicle.viewAny` permission | No viewAny |
| 2 | Navigate to Transport Master → Vehicle tab | **Tab is hidden** via `@can('tenant.vehicle.viewAny')` |
| 3 | Direct access: navigate to `/transport/vehicle` | **Verify**: `Gate::authorize('tenant.vehicle.viewAny')` at `VehicleController.php:21` throws 403 |
| 4 | **Verify**: 403 Access Denied response | Forbidden page |

### TC-N-10: Access create without view permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user WITHOUT `tenant.vehicle.view` permission | No view |
| 2 | Navigate to `/transport/vehicle/create` | **Verify**: `Gate::authorize('tenant.vehicle.view')` at `VehicleController.php:62` throws 403 |
| 3 | **Anomaly**: Gate uses `view` instead of `create` | 403 even though user might have create permission but not view |

### TC-N-11: Access edit without update permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user WITHOUT `tenant.vehicle.update` | No update |
| 2 | Navigate to `/transport/vehicle/{id}/edit` | **Verify**: `Gate::authorize('tenant.vehicle.update')` at `VehicleController.php:120` throws 403 |
| 3 | **Verify**: 403 Access Denied | Forbidden |

### TC-N-12: Attempt delete without permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user WITHOUT `tenant.vehicle.delete` | No delete |
| 2 | Send DELETE to `/transport/vehicle/{id}` | **Verify**: `Gate::authorize('tenant.vehicle.delete')` at `VehicleController.php:189` throws 403 |
| 3 | **Verify**: 403 Access Denied | Forbidden |

### TC-N-13: Attempt store without create permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user WITHOUT `tenant.vehicle.create` | No create |
| 2 | POST valid data to `/transport/vehicle` | **Verify**: `Gate::authorize('tenant.vehicle.create')` at `VehicleController.php:75` throws 403 |
| 3 | **Verify**: 403 Access Denied | Forbidden — no vehicle created |

### TC-N-14: Access trash without restore permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user WITHOUT `tenant.vehicle.restore` | No restore |
| 2 | Navigate to `/transport/vehicle/trash` | **Verify**: `Gate::authorize('tenant.vehicle.restore')` at `VehicleController.php:210` throws 403 |
| 3 | **Verify**: 403 Access Denied | Forbidden |

### TC-N-15: Attempt forceDelete without permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user WITHOUT `tenant.vehicle.forceDelete` | No forceDelete |
| 2 | Navigate to `/transport/vehicle/{id}/force-delete` | **Verify**: `Gate::authorize('tenant.vehicle.forceDelete')` at `VehicleController.php:242` throws 403 |
| 3 | **Verify**: 403 Access Denied | Forbidden |

### TC-N-16: Restore non-trashed (active) vehicle

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure vehicle exists with `deleted_at=NULL` (active, not trashed) | Active vehicle |
| 2 | Call restore route: GET `/transport/vehicle/{id}/restore` | Route hit |
| 3 | **Verify**: `Gate::authorize('tenant.vehicle.restore')` passes | Authorized |
| 4 | **Verify**: `Vehicle::onlyTrashed()->findOrFail($id)` | `onlyTrashed()` filters WHERE deleted_at IS NOT NULL |
| 5 | Active record has deleted_at=NULL → not found | `findOrFail()` throws ModelNotFoundException |
| 6 | **Verify**: 404 error response | "No query results" — record not found in trash scope |

### TC-N-17: Show non-existent vehicle ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Call `/transport/vehicle/99999` (non-existent ID) | Route-model-binding `Vehicle $vehicle` |
| 2 | **Verify**: Implicit route-model-binding fails | `ModelNotFoundException` |
| 3 | **Verify**: 404 error response | "No query results for model Vehicle" |

### TC-N-18: Toggle status with invalid is_active value

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.vehicle.update` | Success |
| 2 | Send AJAX POST to toggleStatus with `is_active=2` (non-boolean) | Invalid value |
| 3 | **Verify**: `$request->validate(['is_active' => 'required|boolean'])` | "The is active field must be true or false." |
| 4 | **Verify**: JSON validation error response | 422 Unprocessable Entity with error details |
| 5 | **Verify**: Vehicle status unchanged | DB is_active remains previous value |

### TC-N-19: Edit non-existent vehicle ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to `/transport/vehicle/99999/edit` | Non-existent ID |
| 2 | **Verify**: `Vehicle::where('id',99999)->first()` returns null | No record |
| 3 | **Verify**: Null `$vehicle` passed to edit view | Potential 500 error (view expects Vehicle object) |
| 4 | **Note**: No `findOrFail()` in `edit()` — uses `first()` instead | No 404, null model passed to view |

### TC-N-20: Store with vehicle_no exceeding max length

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create vehicle with vehicle_no = 21 characters (exceeds max:20) | Over limit |
| 2 | Click "Save" | POST request |
| 3 | **Verify**: `VehicleRequest` rule `max:20` | "The vehicle no must not be greater than 20 characters." |
| 4 | **Verify**: No vehicle created | DB unchanged |

### TC-N-21: Store with registration_no exceeding max length

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create vehicle with registration_no = 31 characters (exceeds max:30) | Over limit |
| 2 | Click "Save" | POST request |
| 3 | **Verify**: `VehicleRequest` rule `max:30` | "The registration no must not be greater than 30 characters." |

### TC-N-22: Toggle status without is_active parameter

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.vehicle.update` | Success |
| 2 | Send AJAX POST to toggleStatus WITHOUT `is_active` parameter | Missing param |
| 3 | **Verify**: `required|boolean` validation | "The is active field is required." |
| 4 | **Verify**: 422 response | Validation error JSON |

### TC-N-23: Update with invalid vendor_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.vehicle.update` | Success |
| 2 | Edit vehicle, change vendor_id to non-existent value (99999) | Invalid vendor |
| 3 | Click "Update" | PUT request |
| 4 | **Verify**: `VehicleRequest` rule `exists:vnd_vendors,id` | "The selected vendor id is invalid." |

### TC-N-24: Create vehicle with capacity=0 (below minimum)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create vehicle with capacity=0 | Below min:1 |
| 2 | Click "Save" | POST request |
| 3 | **Verify**: `VehicleRequest` rule `min:1` on capacity | "The capacity must be at least 1." |

### TC-D-01: Delete vehicle with active assignments

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure vehicle has related records: inspections, driver-route assignments, fuel logs | Related data exists |
| 2 | Call destroy on this vehicle | DELETE request |
| 3 | **Verify**: `$vehicle->is_active = false; $vehicle->save(); $vehicle->delete()` | Soft-delete executed |
| 4 | DB check: `tpt_vehicle` — `is_active=0`, `deleted_at` IS NOT NULL | Vehicle deactivated + soft-deleted |
| 5 | DB check: `tpt_daily_vehicle_inspections` where `vehicle_id=X` | Records remain (FK may SET NULL or CASCADE per migration) |
| 6 | DB check: `tpt_vehicle_fuel` where `vehicle_id=X` | Fuel log records remain |

### TC-D-02: Force delete vehicle with media

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure vehicle has media records in `media` table | 8 media records |
| 2 | First soft-delete: call destroy() | is_active=false, deleted_at set |
| 3 | Call forceDelete() on trashed vehicle | Permanently delete |
| 4 | **Verify**: `Vehicle::withTrashed()->findOrFail($id)` | Record found |
| 5 | **Verify**: `$vehicle->forceDelete()` | Record removed from `tpt_vehicle` |
| 6 | DB check: `tpt_vehicle WHERE id=X` | 0 rows (permanently deleted) |
| 7 | DB check: `media WHERE model_id=X AND model_type=Vehicle` | 0 rows (cascade deleted) |
| 8 | **Verify**: Activity log "Deleted — Vehicle was permanently deleted." | Log entry created |

### TC-D-03: Verify is_active=false before soft-delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Note current vehicle state: is_active=1, deleted_at=NULL | Active |
| 2 | Call destroy on vehicle | Soft-delete |
| 3 | DB check: `SELECT is_active, deleted_at FROM tpt_vehicle WHERE id=X` | `is_active=0`, `deleted_at` IS NOT NULL |
| 4 | **Verify**: Destroy set `is_active=false` BEFORE `delete()` | Code path: `$vehicle->is_active = false → $vehicle->save() → $vehicle->delete()` |
| 5 | **Verify**: Trashed vehicle is inactive | Restored vehicle will be inactive |

### TC-D-04: Composite unique on (vehicle_no, registration_no)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create vehicle with (vehicle_no="ABC", registration_no="XYZ") | Success |
| 2 | Attempt to create vehicle with swapped pair (vehicle_no="XYZ", registration_no="ABC") | Individual unique rules check each field separately |
| 3 | Since "XYZ" doesn't exist as vehicle_no, and "ABC" doesn't exist as registration_no, individual unique rules pass | Request validation passes |
| 4 | DB-level composite unique `UNIQUE(registration_no, vehicle_no)` allows (ABC,XYZ) and (XYZ,ABC) as different pairs | DB allows both — composite unique is on the pair, not each field |
| 5 | **Note**: Composite unique prevents duplicate pairs (ABC,XYZ) + (ABC,XYZ) but allows swapped pairs | Test valid only at DB level bypassing Request |

### TC-D-05: DDL upload flag discrepancy (GAP)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review DDL for `tpt_vehicle` lines 28-35 | 8 individual `*_upload` TINYINT(1) columns exist: `vehicle_photo_upload`, `registration_cert_upload`, `pollution_cert_upload`, `fitness_cert_upload`, `insurance_cert_upload`, `emission_cert_upload`, `fire_extinguisher_cert_upload`, `gps_device_cert_upload` |
| 2 | Review `Vehicle.php` `$fillable` array | Only `documents_uploaded` (single boolean field) |
| 3 | Search controller for any `*_upload` field assignment | No code path sets individual upload flags |
| 4 | **Impact**: Cannot track which specific documents are uploaded via model | Only binary "all or nothing" flag available |
| 5 | **Recommendation**: Either remove DDL columns or add individual fillable + logic | Model-DDL inconsistency |

### TC-D-06: Duplicate vehicle_no after force-delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create vehicle with vehicle_no="UNIQUE01" | Vehicle exists |
| 2 | Soft-delete vehicle (destroy) | Trashed, is_active=false |
| 3 | Force-delete vehicle | Permanently removed |
| 4 | Create new vehicle with vehicle_no="UNIQUE01" (same number) | Unique rule does NOT check force-deleted records (no conflict) |
| 5 | **Verify**: New vehicle created successfully with vehicle_no="UNIQUE01" | DB allows — no trace of previous record |

### TC-D-07: Vendor FK reference from vehicle

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Identify a vendor that has vehicles referencing it | Vendor with vehicles |
| 2 | Attempt to delete that vendor from `vnd_vendors` | FK constraint action per DDL |
| 3 | Check DDL: `fk_vehicle_vendor` with `ON DELETE CASCADE` | If CASCADE: vehicles auto-deleted → soft-delete check needed |
| 4 | **Verify**: DB enforces FK constraint | Behavior depends on migration definition |

### TC-D-08: Dropdown FK reference from vehicle

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Identify a dropdown entry referenced by vehicle_type_id/fuel_type_id/etc. | Dropdown value in use |
| 2 | Attempt to delete dropdown entry from `sys_dropdown_table` | FK constraint per DDL |
| 3 | Check DDL: `fk_vehicle_type` type FKs | CASCADE or RESTRICT behavior |
| 4 | **Verify**: DB integrity maintained | Cannot orphan vehicle dropdown references |

### TC-D-09: Toggle status inactive→active (bidirectional)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Find vehicle with is_active=0 (inactive) | Inactive vehicle |
| 2 | Click status toggle switch | AJAX POST to toggleStatus |
| 3 | **Verify**: `$request->boolean('is_active')` = true | Toggle sends true |
| 4 | **Verify**: `$vehicle->is_active = true` | Set to active |
| 5 | **Verify**: JSON `{success: true, is_active: true}` | Success response |
| 6 | DB check: `is_active=1` for this vehicle | Persisted |

### TC-D-10: Verify `documents_uploaded` flag not persisted

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `VehicleController.php:90` | `$documentsUploaded = 0` — declared |
| 2 | Review `VehicleController.php:101` | `$documentsUploaded = 1` — set in loop |
| 3 | Search for any assignment `$vehicle->documents_uploaded = $documentsUploaded` | **NOT FOUND** — variable not persisted to model |
| 4 | **Impact**: Dead code — `$documentsUploaded` variable is useless | Always defaults to 0 in DB |

### TC-D-11: Verify usingFileName in store() but not update()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review store() lines 96-98 | `->usingFileName(time().'_'.$request->file($field)->getClientOriginalName())` |
| 2 | Review update() lines 153-154 | `->addMediaFromRequest($field)->toMediaCollection($field)` — NO `usingFileName()` |
| 3 | **Impact**: store() renames files with timestamp prefix, update() uses original filename | Inconsistent naming convention |

### TC-D-12: Verify toggleStatus JSON response format

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review success branch: `VehicleController.php:276-280` | `{success: true, is_active: bool, message: flash('status_updated.vehicle')}` |
| 2 | Review failure branch: `VehicleController.php:283-287` | `{success: false, is_active: bool, message: flash('status_switch_failed.vehicle')}` |
| 3 | Both return HTTP 200 | Same status code, different body content |
| 4 | **Note**: Frontend must check `success` field, not HTTP status | Conditional on response body |

### TC-D-13: Verify `availability_status` mass-assignment exposure

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `Vehicle.php:40` — `$fillable` | `availability_status` is fillable |
| 2 | Review `VehicleRequest.php` — search for `availability_status` | **NO validation rule** exists |
| 3 | Submit request with `availability_status=1` in POST body | Accepted via mass-assignment with no validation |
| 4 | **Risk**: Any value accepted — no sanitization | Potential data integrity issue |

### TC-CR-01: Verify Gate::authorize() in index()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `VehicleController.php:21` | `Gate::authorize('tenant.vehicle.viewAny')` |
| 2 | Verify permission string | `tenant.vehicle.viewAny` |
| 3 | Verify policy method exists | `VehiclePolicy.php:13` — `viewAny()` |
| 4 | **Result**: index() properly gated | Access controlled |

### TC-CR-02: Verify Gate::authorize() in show()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `VehicleController.php:50` | `Gate::authorize('tenant.vehicle.view')` |
| 2 | Verify permission string | `tenant.vehicle.view` |
| 3 | **Result**: show() properly gated | Access controlled |

### TC-CR-03: Create gate anomaly

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `VehicleController.php:62` | `Gate::authorize('tenant.vehicle.view')` — **NOT** `tenant.vehicle.create` |
| 2 | Compare with store() line 75 | store() uses `tenant.vehicle.create` |
| 3 | Compare with ShiftController pattern | `ShiftController.php:31` uses `tenant.shift.create` for create form |
| 4 | **Impact**: Users with `tenant.vehicle.view` (read-only) can access create form UI | But store() still requires create permission → form submission fails with 403 |
| 5 | **Severity**: Medium — UI inconsistency | Form renders but cannot be submitted without proper permission |

### TC-CR-04: Verify Gate::authorize() in store()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `VehicleController.php:75` | `Gate::authorize('tenant.vehicle.create')` |
| 2 | **Result**: store() properly gated | `tenant.vehicle.create` |

### TC-CR-05: Verify Gate::authorize() in edit()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `VehicleController.php:120` | `Gate::authorize('tenant.vehicle.update')` |
| 2 | **Result**: edit() properly gated | `tenant.vehicle.update` |

### TC-CR-06: Verify Gate::authorize() in update()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `VehicleController.php:133` | `Gate::authorize('tenant.vehicle.update')` |
| 2 | **Result**: update() properly gated | `tenant.vehicle.update` |

### TC-CR-07: Verify Gate::authorize() in destroy()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `VehicleController.php:189` | `Gate::authorize('tenant.vehicle.delete')` |
| 2 | **Result**: destroy() properly gated | `tenant.vehicle.delete` |

### TC-CR-08: Verify Gate::authorize() in toggleStatus()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `VehicleController.php:262` | `Gate::authorize('tenant.vehicle.update')` |
| 2 | **Result**: toggleStatus() reuses update gate | `tenant.vehicle.update` (not a separate `status` gate) |
| 3 | **Note**: Policy has `status()` method (line 29) but it's never called | Unused policy method |

### TC-CR-09: Verify activityLog in store()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `VehicleController.php:105-108` | `activityLog($vehicle, 'Stored', ['message' => 'Vehicle created successfully', 'performed_by' => auth()->user()->name])` |
| 2 | Verify type parameter | `'Stored'` |
| 3 | Verify message key | `'message' => 'Vehicle created successfully'` |
| 4 | Verify performed_by | `auth()->user()->name` |

### TC-CR-10: Verify activityLog in update() with change tracking

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `VehicleController.php:158-176` | `$vehicle->getChanges()` loop |
| 2 | Verify `$original` captured before update | `$original = $vehicle->getOriginal()` at line 135 |
| 3 | Verify `updated_at` excluded | `if ($field === 'updated_at') { continue; }` |
| 4 | Verify `$changedAttributes` structure | `[field => ['old' => value, 'new' => value]]` |
| 5 | Verify activityLog call | `activityLog($vehicle, 'Updated', ['message' => 'Vehicle updated successfully', 'changes' => $changedAttributes, 'performed_by' => Auth::user()->name])` |

### TC-CR-11: Verify activityLog in destroy()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `VehicleController.php:195-198` | `activityLog($vehicle, 'Trashed', ['message' => 'Vehicle was deactivated and deleted.', 'performed_by' => Auth::user()->name])` |
| 2 | Verify type | `'Trashed'` |
| 3 | Verify performed_by | `Auth::user()->name` |

### TC-CR-12: Verify activityLog in restore()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `VehicleController.php:227-230` | `activityLog($vehicle, 'Restored', ['message' => 'Vehicle was restored.', 'other' => 'some other information'])` |
| 2 | **Verify**: `performed_by` key is MISSING | Only `message` and `other` keys |
| 3 | Compare with all other activityLog calls | All others include `performed_by` |
| 4 | **GAP**: restore() log entry lacks user attribution | Audit trail incomplete |

### TC-CR-13: Verify activityLog in forceDelete()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `VehicleController.php:247-250` | `activityLog($vehicle, 'Deleted', ['message' => 'Vehicle was permanently deleted.', 'performed_by' => Auth::user()->name])` |
| 2 | Verify type | `'Deleted'` (different from destroy's 'Trashed') |
| 3 | Verify performed_by | `Auth::user()->name` |

### TC-CR-14: Verify activityLog in toggleStatus()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `VehicleController.php:270-274` | `activityLog($vehicle, 'Toggled', ['message' => 'Vehicle status updated.', 'performed_by' => Auth::user()->name])` |
| 2 | Verify type | `'Toggled'` |
| 3 | Verify performed_by | `Auth::user()->name` |

### TC-CR-15: Verify media upload loop in store()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `VehicleController.php:79-103` | `$mediaFields` array with 8 field names |
| 2 | Verify foreach loop iterates all 8 | `foreach ($mediaFields as $field)` |
| 3 | Verify `$request->hasFile($field)` check | Only processes if file present |
| 4 | Verify `addMediaFromRequest($field)` | Spatie method |
| 5 | Verify `usingFileName(time().'_'.$originalName)` | Timestamp prefix for uniqueness |
| 6 | Verify `toMediaCollection($field)` | Each field goes to named collection |

### TC-CR-16: Verify media replace in update()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `VehicleController.php:139-156` | Same `$mediaFields` array |
| 2 | Verify `clearMediaCollection($field)` before add | Old file deleted entirely |
| 3 | Verify `addMediaFromRequest($field)->toMediaCollection($field)` | New file added |
| 4 | **Note**: No `usingFileName()` in update() | Filename not renamed (unlike store) |

### TC-CR-17: Verify is_active=false before delete()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `VehicleController.php:191-193` | `$vehicle->is_active = false; $vehicle->save(); $vehicle->delete()` |
| 2 | Verify order: set false → save → delete | Proper 3-step process |
| 3 | **Result**: Trashed vehicle safely deactivated | Inactive in trash |

### TC-CR-18: Verify VehicleRequest@authorize() for POST

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `VehicleRequest.php:14-15` | `$this->isMethod('POST')` → `Gate::allows('tenant.vehicle.create')` |
| 2 | Verify POST creates use create permission | `tenant.vehicle.create` |

### TC-CR-19: Verify VehicleRequest@prepareForValidation()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `VehicleRequest.php:93-98` | `$this->merge(['is_active' => $this->boolean('is_active')])` |
| 2 | Verify boolean normalization | String "0"/"1" → boolean true/false |

### TC-CR-20: Verify redirect after store/update/destroy

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open store() line 111 | `->route('transport.transport-master.index')` |
| 2 | Open update() line 179 | Same route |
| 3 | Open destroy() line 201 | Same route |
| 4 | **Result**: All CRUD redirects to transport master tab | Consistent redirect target |

### TC-CR-21: Verify redirect after restore/forceDelete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open restore() line 233 | `->route('transport.vehicle.trashed')` |
| 2 | Open forceDelete() line 253 | Same route |
| 3 | **Result**: Trash operations redirect back to trash list | Consistent |

### TC-CR-22: Verify $fillable includes documents_uploaded

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `Vehicle.php:42` | `'documents_uploaded'` in `$fillable` |
| 2 | Check DDL | 8 individual `*_upload` flags exist but only 1 fillable field |
| 3 | **GAP**: DDL has 8 flags, model has 1 | Cannot track per-document upload status |

### TC-CR-23: Verify $casts for dates

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `Vehicle.php:50-53` | `'fitness_valid_upto' => 'date'`, `'insurance_valid_upto' => 'date'`, `'pollution_valid_upto' => 'date'`, `'fire_extinguisher_valid_upto' => 'date'` |
| 2 | Verify all 4 date fields cast | Each casts to Carbon/DateTime |

### TC-CR-24: Verify registerMediaCollections()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `Vehicle.php:120-133` | 8 `$this->addMediaCollection(name)->singleFile()` calls |
| 2 | Verify collection names match `$mediaFields` | All 8 match controller field names |
| 3 | Verify `singleFile()` on each | Replaces old file on new upload |

### TC-CR-25: Verify registerMediaConversions() only for vehicle_photo

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `Vehicle.php:139-153` | `if ($this->collection_name === 'vehicle_photo')` guard |
| 2 | Verify small conversion | `small` 150x150 |
| 3 | Verify medium conversion | `medium` 300x300 |
| 4 | Verify `nonQueued()` | Conversions run synchronously |

### TC-CR-26: Verify scopeActive()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `Vehicle.php:159-162` | `scopeActive($query) { return $query->where('is_active', true); }` |
| 2 | Search controller for `->active()` | **NOT USED** in any controller method |
| 3 | **Result**: Dead scope — defined but unused | Available for future use |

### TC-CR-27: Verify vendor loading via Dropdown key

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `VehicleController.php:65-66` | `Dropdown::where('key','vnd_vendors.vendor_type_id')->first()` → `$dropdwon->id` |
| 2 | Open `VehicleController.php:123-124` | Same pattern in edit() |
| 3 | **Result**: Vendor type resolved via dropdown config | Consistent vendor filtering |

### TC-CR-28: Verify AJAX handling in index()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `VehicleController.php:37-38` | `if ($request->ajax()) { return view(...)->render(); }` |
| 2 | **Verify**: Returns partial without layout | Used for tab switching without full reload |

### TC-CR-29: Verify withQueryString() on paginator

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `VehicleController.php:34` | `->withQueryString()` chained to `->paginate(10)` |
| 2 | **Result**: Pagination links preserve `search`, `status`, `tab` params | Filter state maintained across pages |

### TC-CR-30: Verify @canany in index blade

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `vehicle/index.blade.php:37,53` | `@canany(['tenant.vehicle.edit', 'tenant.vehicle.delete'])` |
| 2 | **Result**: Action column renders only if user has edit or delete permission | Conditional UI |

### TC-CR-31: Verify DDL has 8 *_upload TINYINT flags

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review DDL lines 28-35 | 8 individual upload tracking columns |
| 2 | Compare with `Vehicle.php` fillable | Only `documents_uploaded` (single field) |
| 3 | **GAP**: DDL columns are unused | No code writes to individual `*_upload` flags |

### TC-CR-32: Verify VehiclePolicy has status() method

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `VehiclePolicy.php:29-32` | `status()` method with `tenant.vehicle.status` |
| 2 | Search controller for `tenant.vehicle.status` | **NOT FOUND** — unused |
| 3 | Compare: toggleStatus uses `tenant.vehicle.update` | Policy method exists but is dead code |

### TC-CR-33: restore() activityLog missing performed_by

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `VehicleController.php:227-230` | `activityLog($vehicle, 'Restored', ['message' => 'Vehicle was restored.', 'other' => 'some other information'])` |
| 2 | Check for `performed_by` key | **MISSING** — not passed |
| 3 | Compare with store/update/destroy/toggleStatus/forceDelete | All others include `performed_by` |
| 4 | **GAP**: Inconsistent logging — restore lacks user attribution | Audit incompleteness |

### TC-CR-34: Verify VehicleRequest@authorize() for PUT/PATCH

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `VehicleRequest.php:17` | `return Gate::allows('tenant.vehicle.update');` for non-POST |
| 2 | Verify PUT/PATCH uses update permission | `tenant.vehicle.update` |

### TC-CR-35: Verify toggleStatus() returns both JSON paths

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `VehicleController.php:275-287` | `if ($vehicle->save()) { ... success JSON }` else `{ ... failure JSON }` |
| 2 | Success path | `{success: true, is_active: bool, message: flash('status_updated.vehicle')}` |
| 3 | Failure path | `{success: false, is_active: bool, message: flash('status_switch_failed.vehicle')}` |
| 4 | Both return 200 | Same HTTP status, different body |

### TC-CR-36: Verify scopeActive() not used in controller

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `Vehicle.php:159-162` | `scopeActive()` defined |
| 2 | Grep controller for `->active()` | **NOT CALLED** anywhere |
| 3 | **Result**: Dead code — scope never applied | No active-only default filter |

### TC-CR-37: Verify availability_status in fillable but absent from Request

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `Vehicle.php:40` | `'availability_status'` in `$fillable` |
| 2 | Open `VehicleRequest.php` | No validation rule for `availability_status` |
| 3 | **GAP**: Field can be mass-assigned without validation | Risk: any value accepted |

### TC-CR-38: Verify documentsUploaded variable never persisted

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `VehicleController.php:90` | `$documentsUploaded = 0` — initialized |
| 2 | Open `VehicleController.php:101` | `$documentsUploaded = 1` — set in loop |
| 3 | Search for `$vehicle->documents_uploaded = $documentsUploaded` | **NOT FOUND** |
| 4 | **GAP**: Dead variable — no assignment to model | Flag never saved to DB |

### TC-CR-39: Verify usingFileName() in store() but not update()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open store() line 96-98 | `->usingFileName(time().'_'.$request->file($field)->getClientOriginalName())` |
| 2 | Open update() line 153-154 | `->addMediaFromRequest($field)->toMediaCollection($field)` — no usingFileName |
| 3 | **Inconsistency**: update() doesn't rename files | Original filenames used for updated documents |

### TC-CR-40: Verify redirect routes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | store() redirect | `transport.transport-master.index` |
| 2 | update() redirect | `transport.transport-master.index` |
| 3 | destroy() redirect | `transport.transport-master.index` |
| 4 | restore() redirect | `transport.vehicle.trashed` |
| 5 | forceDelete() redirect | `transport.vehicle.trashed` |
| 6 | **Pattern**: CRUD → master tab, Trash ops → trash listing | Consistent |

### TC-CR-41: Verify is_active not in $fillable

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `Vehicle.php:39-44` | `$fillable` array — `is_active` NOT listed |
| 2 | Check how is_active is set | `$vehicle->is_active = false` then `$vehicle->save()` (direct property, not mass-assignment) |
| 3 | **Result**: is_active protected from mass-assignment | Proper security pattern |

### TC-CR-42: Verify availability_status mass-assignment risk

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `Vehicle.php:40` | `availability_status` in `$fillable` |
| 2 | Open `VehicleRequest.php` | No validation rule |
| 3 | **Risk**: Unvalidated field can be set via mass-assignment | User could submit `availability_status` without constraint |

### TC-CR-43: Verify model casts for dates

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `Vehicle.php:50-53` | 4 date casts: `fitness_valid_upto`, `insurance_valid_upto`, `pollution_valid_upto`, `fire_extinguisher_valid_upto` |
| 2 | **Result**: All return Carbon instances | Date formatting available |

### TC-CR-44: Verify model casts for booleans

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `Vehicle.php:47-49` | `is_active` → boolean, `availability_status` → boolean, `documents_uploaded` → boolean |
| 2 | **Result**: DB tinyint auto-casts to PHP bool | Convenient conditional checks |

### TC-CR-45: Verify model casts for integers

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `Vehicle.php:46` | `vendor_id`, FKs cast as `integer` |
| 2 | **Result**: DB values return as PHP ints | Clean type handling |

### TC-CR-46: Verify Gate consistency

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | index() uses `tenant.vehicle.viewAny` | Consistent pattern |
| 2 | show() uses `tenant.vehicle.view` | Consistent pattern |
| 3 | **Anomaly**: create() uses `tenant.vehicle.view` instead of `tenant.vehicle.create` | `VehicleController.php:62` — should be create |
| 4 | store() uses `tenant.vehicle.create` | Correct |
| 5 | edit()/update() use `tenant.vehicle.update` | Correct |
| 6 | destroy() uses `tenant.vehicle.delete` | Correct |
| 7 | **Summary**: One anomaly found | create() gate mismatch |

### TC-CR-47: Verify auth() vs Auth::() inconsistency

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | store() line 107: `auth()->user()->name` | Helper function |
| 2 | update() line 176: `Auth::user()->name` | Facade |
| 3 | destroy() line 197: `Auth::user()->name` | Facade |
| 4 | forceDelete() line 249: `Auth::user()->name` | Facade |
| 5 | toggleStatus() line 272: `Auth::user()->name` | Facade |
| 6 | **Style inconsistency**: store() uses helper, others use facade | Minor, functionally identical |

### TC-CR-48: Verify no file size validation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `VehicleRequest.php` | Search for `max:` or `size` — **NOT FOUND** |
| 2 | **Result**: No file size validation | Any size file can be uploaded (potential performance issue) |

### TC-CR-49: Verify vehicle_photo conversion nonQueued

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `Vehicle.php:151` | `->nonQueued()` |
| 2 | **Result**: Conversions run synchronously during upload | User waits for conversion to complete |

### TC-CR-50: Verify save() return check only in toggleStatus

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | toggleStatus() line 275: `if ($vehicle->save())` | Checked — success/failure branches |
| 2 | store() line 77: `Vehicle::create(...)` — no check | Assumes success |
| 3 | update() line 137: `$vehicle->update(...)` — no check | Assumes success |
| 4 | destroy() line 192-193: `save()` + `delete()` — no check | Assumes success |
| 5 | **Result**: Only toggleStatus handles save failure | Other methods optimistic |

### TC-CR-51: Verify Activity Log Types

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | store(): `'Stored'` | Type: Stored |
| 2 | update(): `'Updated'` | Type: Updated |
| 3 | destroy(): `'Trashed'` | Type: Trashed |
| 4 | restore(): `'Restored'` | Type: Restored |
| 5 | forceDelete(): `'Deleted'` | Type: Deleted |
| 6 | toggleStatus(): `'Toggled'` | Type: Toggled |
| 7 | **Pattern**: Each operation has unique type string | Clear audit categorization |

### TC-CR-52: Verify Policy has unused methods

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `VehiclePolicy.php:29` | `status()` — unused |
| 2 | `VehiclePolicy.php:77` | `import()` — unused |
| 3 | `VehiclePolicy.php:85` | `export()` — unused |
| 4 | `VehiclePolicy.php:93` | `print()` — unused |
| 5 | **Result**: 4 of 11 policy methods are dead code | Future feature stubs |

### TC-CR-53: Verify edit() uses first() not findOrFail()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `VehicleController.php:122` | `Vehicle::where('id',$id)->first()` |
| 2 | If ID not found, returns null | Null passed to view |
| 3 | View may crash on null access | Potential 500 error |
| 4 | Compare with route-model-binding methods (show/update/destroy) which auto-404 | Inconsistency: edit doesn't 404 on missing ID |

### TC-CR-54: Verify Dropdown key spelling error

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `VehicleController.php:65` | `$dropdwon = Dropdown::where('key','vnd_vendors.vendor_type_id')->first()` |
| 2 | **Spelling**: `$dropdwon` (missing 'o') | Variable misnamed but functional |
| 3 | Same at `VehicleController.php:123` | Consistent misspelling |

### TC-CR-55: Verify trashed() paginate(10)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `VehicleController.php:212` | `Vehicle::onlyTrashed()->paginate(10)` |
| 2 | **Result**: Trash list paginated same as index | 10 per page |

---

*Template: tpt_PickupStopsList_TcList.md (Syllabus depth) | Entity: Vehicle | Date: 2026-07-21*

