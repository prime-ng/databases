# tpt_Inspection_TcList

## Module: Transport → Vehicle Management → Daily Vehicle Inspection

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | Transport |
| Tab Group | Vehicle Management (5-tab container via `VehicleMgmtController`) |
| Feature | Daily Vehicle Inspection |
| URL(s) | `/daily-vehicle-inspection` (index), `/daily-vehicle-inspection/create` (create), `/daily-vehicle-inspection` (store), `/daily-vehicle-inspection/{id}` (show), `/daily-vehicle-inspection/{id}/edit` (edit), `/daily-vehicle-inspection/{id}` (update PUT), `/daily-vehicle-inspection/{id}` (destroy DELETE), `/daily-vehicle-inspection/trash/view` (trash), `/daily-vehicle-inspection/{id}/restore` (restore GET), `/daily-vehicle-inspection/{id}/force-delete` (forceDelete DELETE), `/daily-vehicle-inspection/{id}/update-status` (updateStatus POST) |
| Controller | `Modules\Transport\Http\Controllers\TptDailyVehicleInspectionController` |
| Tab Container Controller | `Modules\Transport\Http\Controllers\VehicleMgmtController@index()` |
| Model | `Modules\Transport\Models\TptDailyVehicleInspection` — table: `tpt_daily_vehicle_inspection` |
| Validation | `Modules\Transport\Http\Requests\TptDailyVehicleInspectionRequest` |
| Permissions | `tenant.daily-vehicle-inspection.viewAny`, `tenant.daily-vehicle-inspection.view`, `tenant.daily-vehicle-inspection.create`, `tenant.daily-vehicle-inspection.update`, `tenant.daily-vehicle-inspection.delete`, `tenant.daily-vehicle-inspection.restore`, `tenant.daily-vehicle-inspection.forceDelete`, `tenant.daily-vehicle-inspection.approve`, `tenant.daily-vehicle-inspection.status` (blade status column), `tenant.daily-vehicle-inspection.edit` (blade action column) |
| Soft Deletes | Yes (`SoftDeletes` trait) |
| Activity Log | Events: `Created`, `Updated`, `Trashed`, `Restored`, `ForceDeleted`, `StatusUpdated` |
| Auto-Workflow | Failed inspection → auto-creates `TptVehicleServiceRequest` + sets `Vehicle.availability_status = false` |

---

## 2. Pre-conditions

- Required permissions: All `tenant.daily-vehicle-inspection.*` permissions listed above
- Tenant context must be initialized
- Required seed data: At least one `Vehicle` (tpt_vehicle) and optional `DriverHelper` (tpt_personnel)
- Dusk environment variables: `DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD`
- Inspection tab loads inside `VehicleMgmt` — URL `/vehicle-mgmt` loads all tabs simultaneously
- Standalone index page available at `/daily-vehicle-inspection`

---

## 3. Default Data Load

When the page loads via `VehicleMgmtController@index()` (GET `/vehicle-mgmt`):

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| Inspections Grid | `VehicleMgmtController@dailyInspectionQuery()` | `TptDailyVehicleInspection::with(['vehicle','driver'])->orderBy('inspection_date','DESC')` | search_inspection (vehicle.registration_no, driver.name) | 10/page |
| Vehicles for filter | View dropdown | `Vehicle::all()` | None | None |

The standalone `/daily-vehicle-inspection` GET page loads via `TptDailyVehicleInspectionController@index()` with same eager loading and pagination.

---

## 4. Test Data Strategy

- **vehicle_id**: Must reference existing `tpt_vehicle`. Store also uses `Vehicle::where('availability_status', true)` for create dropdown
- **driver_id**: Optional, FK to `tpt_personnel`
- **inspection_date**: TIMESTAMP type, must be valid date
- **odometer_reading**: INT UNSIGNED, nullable, min:0
- **fuel_level_reading**: DECIMAL(6,2), nullable, min:0, max:100
- **15 condition fields**: TINYINT(1), default 0, cast to boolean in model. Request converts string booleans via `prepareForValidation()`
- **inspection_status**: ENUM(`'Passed'`, `'Failed'`, `'Pending'`). Default `'Pending'`
- **Failed inspection side effects**: Creates `TptVehicleServiceRequest` + sets `Vehicle.availability_status = false`
- **Pre-test cleanup**: Delete created inspections by vehicle_id+inspection_date
- **Note**: show/edit/destroy methods use `where('id',$id)->first()` NOT `findOrFail()` — returns null on missing ID instead of 404

---

## 5. Business Conditions

### 5.1 Database Schema — `tpt_daily_vehicle_inspection`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | id | INT UNSIGNED | PK, auto-increment |
| BC-DB-02 | vehicle_id | INT UNSIGNED | NOT NULL, FK → `tpt_vehicle.id`, ON DELETE CASCADE |
| BC-DB-03 | driver_id | INT UNSIGNED | DEFAULT NULL, FK → `tpt_personnel.id`, ON DELETE SET NULL |
| BC-DB-04 | inspection_date | TIMESTAMP | NOT NULL |
| BC-DB-05 | odometer_reading | INT UNSIGNED | DEFAULT NULL |
| BC-DB-06 | fuel_level_reading | DECIMAL(6,2) | DEFAULT NULL |
| BC-DB-07 | tire_condition_ok | BOOLEAN/TINYINT(1) | NOT NULL, DEFAULT false |
| BC-DB-08 | lights_condition_ok | BOOLEAN/TINYINT(1) | NOT NULL, DEFAULT false |
| BC-DB-09 | brakes_condition_ok | BOOLEAN/TINYINT(1) | NOT NULL, DEFAULT false |
| BC-DB-10 | engine_condition_ok | BOOLEAN/TINYINT(1) | NOT NULL, DEFAULT false |
| BC-DB-11 | battery_condition_ok | BOOLEAN/TINYINT(1) | NOT NULL, DEFAULT false |
| BC-DB-12 | fire_extinguisher_condition_ok | BOOLEAN/TINYINT(1) | NOT NULL, DEFAULT false |
| BC-DB-13 | first_aid_kit_condition_ok | BOOLEAN/TINYINT(1) | NOT NULL, DEFAULT false |
| BC-DB-14 | seat_belts_condition_ok | BOOLEAN/TINYINT(1) | NOT NULL, DEFAULT false |
| BC-DB-15 | headlights_condition_ok | BOOLEAN/TINYINT(1) | NOT NULL, DEFAULT false |
| BC-DB-16 | tailights_condition_ok | BOOLEAN/TINYINT(1) | NOT NULL, DEFAULT false (typo: `tailights` missing 'l') |
| BC-DB-17 | wipers_condition_ok | BOOLEAN/TINYINT(1) | NOT NULL, DEFAULT false |
| BC-DB-18 | mirrors_condition_ok | BOOLEAN/TINYINT(1) | NOT NULL, DEFAULT false |
| BC-DB-19 | steering_wheel_condition_ok | BOOLEAN/TINYINT(1) | NOT NULL, DEFAULT false |
| BC-DB-20 | emergency_tools_condition_ok | BOOLEAN/TINYINT(1) | NOT NULL, DEFAULT false |
| BC-DB-21 | cleanliness_ok | BOOLEAN/TINYINT(1) | NOT NULL, DEFAULT false |
| BC-DB-22 | any_issues_found | BOOLEAN/TINYINT(1) | NOT NULL, DEFAULT false |
| BC-DB-23 | issues_description | VARCHAR(512) | DEFAULT NULL |
| BC-DB-24 | remarks | VARCHAR(512) | DEFAULT NULL |
| BC-DB-25 | inspection_status | ENUM('Failed','Passed','Pending') | NOT NULL, DEFAULT 'Pending' |
| BC-DB-26 | inspected_at | TIMESTAMP | NULL DEFAULT NULL |
| BC-DB-27 | created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |
| BC-DB-28 | updated_at | TIMESTAMP | ON UPDATE CURRENT_TIMESTAMP |
| BC-DB-29 | deleted_at | TIMESTAMP | NULLABLE (soft delete) |
| BC-DB-30 | vehicle_id FK | `fk_dvil_vehicle` | ON DELETE CASCADE → tpt_vehicle.id |
| BC-DB-31 | driver_id FK | `fk_dvil_driver` | ON DELETE SET NULL → tpt_personnel.id |
| BC-DB-32 | inspected_by FK | `fk_dvil_inspectedBy` | ON DELETE SET NULL → sys_users.id |

Note: DDL has `tailights_condition_ok` (typo — missing 'l' in 'taillights'). Model, Request, and DDL all consistently use the same misspelling, so it's internally consistent.

### 5.2 Validation Rules — `TptDailyVehicleInspectionRequest`

| BC ID | Field | Rule | Error Message |
|-------|-------|------|---------------|
| BC-VAL-01 | vehicle_id | required, `exists:tpt_vehicle,id` | "Please select a vehicle." |
| BC-VAL-02 | driver_id | nullable, `exists:tpt_personnel,id` | "The selected driver does not exist." |
| BC-VAL-03 | inspection_date | required, date | "Inspection date is required." |
| BC-VAL-04 | odometer_reading | nullable, integer, min:0 | "Odometer reading must be a whole number." |
| BC-VAL-05 | fuel_level_reading | nullable, numeric, min:0, max:100 | "Fuel level cannot exceed 100%." |
| BC-VAL-06 | tire_condition_ok | boolean | "This field must be either Yes or No." |
| BC-VAL-07 | lights_condition_ok | boolean | "This field must be either Yes or No." |
| BC-VAL-08 | brakes_condition_ok | boolean | "This field must be either Yes or No." |
| BC-VAL-09 | engine_condition_ok | boolean | "This field must be either Yes or No." |
| BC-VAL-10 | battery_condition_ok | boolean | "This field must be either Yes or No." |
| BC-VAL-11 | fire_extinguisher_condition_ok | boolean | "This field must be either Yes or No." |
| BC-VAL-12 | first_aid_kit_condition_ok | boolean | "This field must be either Yes or No." |
| BC-VAL-13 | seat_belts_condition_ok | boolean | "This field must be either Yes or No." |
| BC-VAL-14 | headlights_condition_ok | boolean | "This field must be either Yes or No." |
| BC-VAL-15 | tailights_condition_ok | boolean | "This field must be either Yes or No." |
| BC-VAL-16 | wipers_condition_ok | boolean | "This field must be either Yes or No." |
| BC-VAL-17 | mirrors_condition_ok | boolean | "This field must be either Yes or No." |
| BC-VAL-18 | steering_wheel_condition_ok | boolean | "This field must be either Yes or No." |
| BC-VAL-19 | emergency_tools_condition_ok | boolean | "This field must be either Yes or No." |
| BC-VAL-20 | cleanliness_ok | boolean | "This field must be either Yes or No." |
| BC-VAL-21 | any_issues_found | boolean | "Please indicate if any issues were found." |
| BC-VAL-22 | issues_description | nullable, string, max:512 | "Issues description cannot exceed 512 characters." |
| BC-VAL-23 | remarks | nullable, string, max:512 | "Remarks cannot exceed 512 characters." |
| BC-VAL-24 | inspection_status | required, `Rule::in(['Passed','Failed','Pending'])` | "Please select a valid inspection status." |
| BC-VAL-25 | inspected_by | nullable, `exists:sys_users,id` | "The selected inspector does not exist." |
| BC-VAL-26 | inspected_at | nullable, date | — |
| BC-VAL-27 | Conditional: if Failed | any_issues_found=required+boolean, issues_description=required+max:512 | "Issues description is required when inspection is Failed." |

### 5.3 Authorization (Permission Gates)

| BC ID | Permission | Controller Method / Blade | Behavior |
|-------|-----------|--------------------------|----------|
| BC-AUTH-01 | tenant.daily-vehicle-inspection.viewAny | index() | Without → 403 |
| BC-AUTH-02 | tenant.daily-vehicle-inspection.view | show() | Without → 403 |
| BC-AUTH-03 | tenant.daily-vehicle-inspection.create | store(), create() | Without → 403; also in Request |
| BC-AUTH-04 | tenant.daily-vehicle-inspection.update | update(), edit() | Without → 403; also in Request |
| BC-AUTH-05 | tenant.daily-vehicle-inspection.delete | destroy() | Without → 403 |
| BC-AUTH-06 | tenant.daily-vehicle-inspection.restore | restore(), trashed() | Without → 403 |
| BC-AUTH-07 | tenant.daily-vehicle-inspection.forceDelete | forceDelete() | Without → 403 |
| BC-AUTH-08 | tenant.daily-vehicle-inspection.approve | updateStatus() | Without → 403 |
| BC-AUTH-09 | tenant.daily-vehicle-inspection.status | Blade — status `<th>` / `<td>` | Hides status column |
| BC-AUTH-10 | tenant.daily-vehicle-inspection.edit | Blade — action `<th>` / `<td>` | Hides edit button in action column |

### 5.4 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Create inspection (Passed) | Inspection created; NO service request created; vehicle availability unchanged |
| BC-BIZ-02 | Create inspection (Failed) | Inspection created + service request auto-generated with `request_approval_status='Pending'` + `Vehicle.availability_status = false` |
| BC-BIZ-03 | Failed inspection auto-service-request | `TptVehicleServiceRequest::create([vehicle_inspection_id, request_date=>now(), reason=>issues_description ?? default, request_approval_status=>'Pending'])` |
| BC-BIZ-04 | Failed inspection — old pending service requests deleted | `TptVehicleServiceRequest::where('vehicle_inspection_id', $inspection->id)->delete()` before creating new |
| BC-BIZ-05 | Activity log on create | `activityLog($inspection, 'Created', ['message' => 'Daily vehicle inspection created. Status: ' . $inspection->inspection_status])` |
| BC-BIZ-06 | Update via `$inspection->update($request->validated())` | Attributes updated; change tracking via getOriginal() vs getChanges() |
| BC-BIZ-07 | Change tracking on update | `updated_at` excluded; old→new per field logged |
| BC-BIZ-08 | Update — no changes | `$changes` empty → logged as null |
| BC-BIZ-09 | Soft delete via `destroy()` | `$inspection->delete()` directly (no is_active toggle) |
| BC-BIZ-10 | Restore via `restore($id)` | `onlyTrashed()->findOrFail($id)` → `$inspection->restore()` |
| BC-BIZ-11 | Force delete via `forceDelete($id)` | `withTrashed()->findOrFail($id)` → `$inspection->forceDelete()` |
| BC-BIZ-12 | updateStatus via `updateStatus(Request, $id)` | No inline validation; directly sets `status = $request->status` and saves (note: `status` is not a column on this table — likely bug, should be `inspection_status`) |
| BC-BIZ-13 | show() uses `where('id',$id)->first()` | If ID does not exist, returns `null` → view receives null → potentially crashes |
| BC-BIZ-14 | edit() fetches record BEFORE gate check | `$inspection = TptVehicleInspection::where('id',$id)->first()` executed at line 99, Gate::authorize() at line 100 |
| BC-BIZ-15 | update() uses `findOrFail($id)` — proper 404 | Line 118: correct pattern, unlike show/edit/destroy |
| BC-BIZ-16 | destroy() uses `where('id',$id)->first()` | Line 157: `$inspection->delete()` called on null if bad ID → error |
| BC-BIZ-17 | store() redirects to `/vehicle-mgmt` | Line 79-81: `redirect()->route('transport.vehicle-mgmt.index')` |
| BC-BIZ-18 | update() uses `$inspection->getOriginal()` before update | Line 121: captured before `$inspection->update()` |
| BC-BIZ-19 | update() iterates `getChanges()` to build changes array | Line 128-137: `foreach ($inspection->getChanges() as $field => $newValue)` |
| BC-BIZ-20 | Store failed inspection sets `availability_status = false` | Line 70-71: `Vehicle::where('id', $inspection->vehicle_id)->update(['availability_status' => false])` |
| BC-BIZ-21 | Store failed inspection ONLY sets availability_status to false (no reset on Pass) | Line 54-72: Side-effects only in `if ($inspection->inspection_status === 'Failed')` block |
| BC-BIZ-22 | Update from Failed→Passed does NOT reset availability_status | No reverse logic in update() — vehicle stays unavailable |
| BC-BIZ-23 | updateStatus sets `status` column not `inspection_status` | Line 231: `$inspection->status = $request->status` — `status` is NOT a DDL column |
| BC-BIZ-24 | updateStatus returns JSON response | Line 239-243: `return response()->json([...])` |
| BC-BIZ-25 | create() filters vehicles by availability_status=true | Line 38: `Vehicle::where('availability_status', true)->get()` |
| BC-BIZ-26 | create() filters drivers by active scope | Line 39: `DriverHelper::active()->get()` |
| BC-BIZ-27 | edit() loads all active vehicles (no availability filter) | Line 102: `Vehicle::active()->get()` — different from create() |
| BC-BIZ-28 | trashed() orders by deleted_at DESC | Line 177-179: `onlyTrashed()->latest('deleted_at')->paginate(10)` |

### 5.5 Model Relationships

| BC ID | Relationship | Type | Foreign Key | Notes |
|-------|-------------|------|-------------|-------|
| BC-REL-01 | vehicle() | BelongsTo Vehicle | vehicle_id | Vehicle inspected |
| BC-REL-02 | driver() | BelongsTo DriverHelper | driver_id | Driver of vehicle |
| BC-REL-03 | inspector() | BelongsTo User (\Modules\SchoolSetup\Models\User) | inspected_by | Person who performed inspection |

### 5.6 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|------------------|----------------|
| BC-REF-01 | vehicle_id | tpt_vehicle (id) | CASCADE |
| BC-REF-02 | driver_id | tpt_personnel (id) | SET NULL |
| BC-REF-03 | inspected_by | sys_users (id) | SET NULL |

### 5.7 BC-BIZ-DEEP — Deep Business Logic Verification

| BC ID | Condition | Expected Behavior | Source |
|-------|-----------|-------------------|--------|
| BC-BIZ-DEEP-01 | Default attributes in model | `$attributes = ['inspection_status' => 'Pending', 'any_issues_found' => 0]` | `TptDailyVehicleInspection.php:61-64` |
| BC-BIZ-DEEP-02 | Boolean casts on all 16 condition fields | All 15 condition fields + any_issues_found cast to `boolean` | `TptDailyVehicleInspection.php:75-91` |
| BC-BIZ-DEEP-03 | inspection_date cast to datetime | `'inspection_date' => 'datetime'` | `TptDailyVehicleInspection.php:70` |
| BC-BIZ-DEEP-04 | fuel_level_reading cast to decimal:2 | `'fuel_level_reading' => 'decimal:2'` | `TptDailyVehicleInspection.php:73` |
| BC-BIZ-DEEP-05 | Fillable array has 26 fields | All 26 fields match DDL (no `id`, timestamps, `deleted_at`) | `TptDailyVehicleInspection.php:26-56` |
| BC-BIZ-DEEP-06 | prepareForValidation converts 16 boolean strings | `$this->merge([$field => $value === true || $value === 'true' || $value === '1' || $value === 1 ? 1 : 0])` | `TptDailyVehicleInspectionRequest.php:144-176` |
| BC-BIZ-DEEP-07 | prepareForValidation sets defaults to 0 for missing booleans | If field not present in request → `$this->merge([$field => 0])` | `TptDailyVehicleInspectionRequest.php:171-175` |
| BC-BIZ-DEEP-08 | Auto-check any_issues_found=1 when Failed | `if ($this->input('inspection_status') === 'Failed' && !$this->has('any_issues_found')) { merge any_issues_found => 1 }` | `TptDailyVehicleInspectionRequest.php:178-183` |
| BC-BIZ-DEEP-09 | Request authorize() double-gates | `isMethod('POST')` → checks create; otherwise checks update | `TptDailyVehicleInspectionRequest.php:14-19` |
| BC-BIZ-DEEP-10 | Request `messages()` has 18 custom messages | All field-specific error messages defined | `TptDailyVehicleInspectionRequest.php:79-100` |
| BC-BIZ-DEEP-11 | Request `attributes()` has 24 custom attribute names | User-friendly names for all validated fields | `TptDailyVehicleInspectionRequest.php:106-135` |
| BC-BIZ-DEEP-12 | Conditional validation fires when Failed | `if ($this->input('inspection_status') === 'Failed')` adds required rules | `TptDailyVehicleInspectionRequest.php:68-71` |
| BC-BIZ-DEEP-13 | Model scopePending() | `return $query->where('inspection_status', 'Pending')` | `TptDailyVehicleInspection.php:116-119` |
| BC-BIZ-DEEP-14 | Model scopePassed() | `return $query->where('inspection_status', 'Passed')` | `TptDailyVehicleInspection.php:121-124` |
| BC-BIZ-DEEP-15 | Model scopeFailed() | `return $query->where('inspection_status', 'Failed')` | `TptDailyVehicleInspection.php:126-129` |
| BC-BIZ-DEEP-16 | VehicleMgmtController passes dailyInspectionEntries | `$dailyInspectionEntries = $this->dailyInspectionQuery($request)->paginate(10)->withQueryString()` | `VehicleMgmtController.php:44` |
| BC-BIZ-DEEP-17 | dailyInspectionQuery search searches registration_no and driver.name | `whereHas('vehicle', fn=>where registration_no LIKE) OR whereHas('driver', fn=>where name LIKE)` | `VehicleMgmtController.php:73-84` |
| BC-BIZ-DEEP-18 | dailyInspectionQuery status filter uses `is_active` (BUG) | `$query->where('is_active', $request->status)` — table has NO `is_active` column | `VehicleMgmtController.php:87-89` |
| BC-BIZ-DEEP-19 | Standalone index() has no `$request` parameter | `public function index()` — no `Request $request`, no filters, just `->latest()->paginate(10)` | `TptDailyVehicleInspectionController.php:20-28` |
| BC-BIZ-DEEP-20 | Standalone index() does NOT pass `$all_vehicles`/`$all_drivers` | View variable missing; blade may crash if it references these | `TptDailyVehicleInspectionController.php:28` |
| BC-BIZ-DEEP-21 | VehicleMgmt index() passes `$all_vehicles` and `$all_drivers` | `Vehicle::all()` and `DriverHelper::all()` loaded for all tabs | `VehicleMgmtController.php:32-33` |
| BC-BIZ-DEEP-22 | create() shows only available vehicles | `Vehicle::where('availability_status', true)->get()` | `TptDailyVehicleInspectionController.php:38` |
| BC-BIZ-DEEP-23 | edit() shows all active vehicles (regardless of availability) | `Vehicle::active()->get()` — different from create() | `TptDailyVehicleInspectionController.php:102` |
| BC-BIZ-DEEP-24 | updateStatus has NO input validation | `$inspection->status = $request->status; $inspection->save();` — no `validate()` call | `TptDailyVehicleInspectionController.php:230-232` |
| BC-BIZ-DEEP-25 | updateStatus sets `status` (non-existent column) | `$inspection->status` is NOT a DDL column — `status` vs `inspection_status` mismatch | `TptDailyVehicleInspectionController.php:231` |
| BC-BIZ-DEEP-26 | Store service request `vehicle_status` set to null | `'vehicle_status' => null` — explicitly set null | `TptDailyVehicleInspectionController.php:65` |
| BC-BIZ-DEEP-27 | Store service request `request_date` set to now() | `'request_date' => now()` — current timestamp | `TptDailyVehicleInspectionController.php:62` |
| BC-BIZ-DEEP-28 | Store service request reason fallback to default | `$inspection->issues_description ?? 'Automatic request generated due to failed inspection.'` | `TptDailyVehicleInspectionController.php:63-64` |
| BC-BIZ-DEEP-29 | Activity log `performed_by` uses `Auth::user()->name` | Uses name instead of user ID | `TptDailyVehicleInspectionController.php:76` |
| BC-BIZ-DEEP-30 | Flash messages use `flash()` helper | `flash('created.dailyvehicleInspection')` — translatable key | `TptDailyVehicleInspectionController.php:81` |
| BC-BIZ-DEEP-31 | destroy() calls `$inspection->delete()` after `->first()` | `first()` may return null → `null->delete()` → error | `TptDailyVehicleInspectionController.php:157-158` |
| BC-BIZ-DEEP-32 | restore() uses `onlyTrashed()->findOrFail($id)` | Proper pattern | `TptDailyVehicleInspectionController.php:191` |
| BC-BIZ-DEEP-33 | forceDelete() uses `withTrashed()->findOrFail($id)` | Proper pattern | `TptDailyVehicleInspectionController.php:210` |
| BC-BIZ-DEEP-34 | trashed() paginates at 10 | `->paginate(10)` — consistent with other tabs | `TptDailyVehicleInspectionController.php:179` |
| BC-BIZ-DEEP-35 | getDetailedPendingData loads pending inspections | `TptDailyVehicleInspection::pending()->with(['vehicle','driver'])->orderBy('inspection_date','desc')->take(10)->get()` | `VehicleMgmtController.php:327-330` |
| BC-BIZ-DEEP-36 | Activity log message uses string interpolation | `'Daily vehicle inspection created. Status: ' . $inspection->inspection_status` | `TptDailyVehicleInspectionController.php:75` |
| BC-BIZ-DEEP-37 | Update activity log: changes=null when empty | `'changes' => !empty($changes) ? $changes : null` | `TptDailyVehicleInspectionController.php:142` |
| BC-BIZ-DEEP-38 | Update activity log: excludes updated_at from changes | `if ($field === 'updated_at') { continue; }` | `TptDailyVehicleInspectionController.php:129-131` |
| BC-BIZ-DEEP-39 | Controller imports Vehicle from Transport module | `use Modules\Transport\Models\Vehicle;` | `TptDailyVehicleInspectionController.php:12` |
| BC-BIZ-DEEP-40 | inspected_by is nullable FK in migration | `$table->unsignedInteger('inspected_by')->nullable(); $table->foreign(...)->onDelete('set null')` | Migration line 47-48 |
| BC-BIZ-DEEP-41 | DDL enum order: `['Failed','Passed','Pending']` | Failed first in enum definition | Migration line 37 |
| BC-BIZ-DEEP-42 | DDL has NO `is_active` column | Confirmed: `is_active` does NOT exist in this table | Migration full file |
| BC-BIZ-DEEP-43 | DDL `tailights_condition_ok` typo | Column named `tailights` not `taillights` — internally consistent | Migration line 28 |
| BC-BIZ-DEEP-44 | Vehicle->inspections() HasMany relationship | `return $this->hasMany(TptDailyVehicleInspection::class, 'vehicle_id')` | `Vehicle.php:60-63` |
| BC-BIZ-DEEP-45 | Vehicle availability_status cast to boolean | `'availability_status' => 'boolean'` | `Vehicle.php:48` |
| BC-BIZ-DEEP-46 | All 6 activityLog event types defined | Created, Updated, Trashed, Restored, ForceDeleted, StatusUpdated | Controller lines 74,140,160,194,213,234 |
| BC-BIZ-DEEP-47 | destroy() does NOT set `is_active` before soft-delete | No `is_active` column — direct `->delete()` correct | `TptDailyVehicleInspectionController.php:157-158` |
| BC-BIZ-DEEP-48 | update() does NOT trigger auto-service-request | Only `store()` has side-effect logic | `TptDailyVehicleInspectionController.php:111-149` |
| BC-BIZ-DEEP-49 | update() does NOT reverse vehicle availability | No availability logic in update() at all | `TptDailyVehicleInspectionController.php:111-149` |
| BC-BIZ-DEEP-50 | show() view receives `$inspection` which may be null | `compact('inspection')` — view must handle null | `TptDailyVehicleInspectionController.php:91` |
| BC-BIZ-DEEP-51 | edit() view receives 3 variables | `compact('inspection', 'vehicles','drivers')` | `TptDailyVehicleInspectionController.php:105` |
| BC-BIZ-DEEP-52 | dailyInspectionQuery returns query builder (not paginated) | Returns `$query` — pagination done in index() at line 44 | `VehicleMgmtController.php:91` |
| BC-BIZ-DEEP-53 | Seeder clears inspections before seeding | `DB::table('tpt_daily_vehicle_inspection')->delete()` | `TransportModuleSeeder.php:41` |
| BC-BIZ-DEEP-54 | Seeder does NOT seed inspection records | No `TptDailyVehicleInspection::create()` in seeder | `TransportModuleSeeder.php` full |
| BC-BIZ-DEEP-55 | Table name mismatch: `tpt_daily_vehicle_inspections` (plural) vs `tpt_daily_vehicle_inspection` (singular) | VehicleMgmtController uses wrong plural name at line 207 | `VehicleMgmtController.php:207` vs actual table |

---

## 6. Test Case List

### 6.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | Inspection Tab Loads Inside Vehicle Mgmt | `/vehicle-mgmt` loads Inspection tab with filter bar and table | — | — | ⬜ |
| TC-P02 | Standalone Inspection Index Page | GET `/daily-vehicle-inspection` loads full-page index | — | — | ⬜ |
| TC-P03 | Create Inspection — Passed (All Conditions OK) | All 15 condition fields set to true; inspection_status=Passed; no service request created | — | — | ⬜ |
| TC-P04 | Create Inspection — Failed (With Issues Description) | inspection_status=Failed; auto-creates service request; vehicle availability set to false | — | — | ⬜ |
| TC-P05 | Create Inspection — Pending | inspection_status=Pending; no side effects | — | — | ⬜ |
| TC-P06 | View Inspection Details | Show page displays Vehicle, Driver, Date, all 15 conditions, Issues, Status, Inspector details | — | — | ⬜ |
| TC-P07 | Edit Inspection Loads Pre-Filled Data | Edit form shows existing values for all condition checkboxes and text fields | — | — | ⬜ |
| TC-P08 | Update Inspection — Change Status Passed→Failed | Activity log tracks change; update does NOT trigger auto-service-request (only store() has this logic) | — | — | ⬜ |
| TC-P09 | Update Inspection — Toggle Condition Field | Condition field value changed; change tracking logged | — | — | ⬜ |
| TC-P10 | Soft Delete Inspection | DELETE → deleted_at set; entry hidden from main list | — | — | ⬜ |
| TC-P11 | Restore Inspection From Trash | Restore → deleted_at=NULL | — | — | ⬜ |
| TC-P12 | Force Delete Inspection | Permanent removal; activity log "ForceDeleted" | — | — | ⬜ |
| TC-P13 | Update Status via AJAX | POST with `status=Approved` → JSON success | — | — | ⬜ |
| TC-P14 | Filter Inspections By Vehicle Registration No | Search → matching entries displayed | — | — | ⬜ |
| TC-P15 | Empty State — No Inspections | Table shows "No Data Found" | — | — | ⬜ |
| TC-P16 | Create Inspection — Passed (Minimal Fields) | Only required fields filled; all conditions default to 0/No | — | — | ⬜ |
| TC-P17 | Create Inspection — With Driver Assignment | driver_id set to existing driver; relationship loaded in view | — | — | ⬜ |
| TC-P18 | Create Inspection — With Odometer & Fuel Readings | odometer_reading=15000, fuel_level_reading=75.50 | — | — | ⬜ |
| TC-P19 | Create Inspection — With Remarks Only | remarks field populated; no issues | — | — | ⬜ |
| TC-P20 | Update Inspection — Clear Odometer/Fuel to Null | Update sets odometer_reading and fuel_level_reading to null | — | — | ⬜ |
| TC-P21 | Create Inspection — All 15 Conditions Mixed | Some true, some false; inspection_status=Passed | — | — | ⬜ |
| TC-P22 | Filter Inspections By Driver Name | search_inspection filters by driver.name | — | — | ⬜ |
| TC-P23 | Tab Persists Active State After CRUD | After create/update/delete, redirect back to vehicle-mgmt with inspection tab active | — | — | ⬜ |
| TC-P24 | Pagination in Standalone Index | 11+ inspections → page 2 loads correctly | — | — | ⬜ |
| TC-P25 | Update Inspection — No Changes Submitted | Submit edit form with no changes → activity log changes=null | — | — | ⬜ |

### 6.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | Required — Missing vehicle_id | "Please select a vehicle." | — | — | ⬜ |
| TC-N02 | Required — Missing inspection_date | "Inspection date is required." | — | — | ⬜ |
| TC-N03 | Required — Missing inspection_status | "Inspection status is required." | — | — | ⬜ |
| TC-N04 | Invalid inspection_status Value | "Please select a valid inspection status." | — | — | ⬜ |
| TC-N05 | Invalid vehicle_id | "The selected vehicle does not exist." | — | — | ⬜ |
| TC-N06 | fuel_level_reading > 100 | "Fuel level cannot exceed 100%." | — | — | ⬜ |
| TC-N07 | fuel_level_reading Negative | "Fuel level cannot be less than 0%." | — | — | ⬜ |
| TC-N08 | odometer_reading Negative | "Odometer reading cannot be negative." | — | — | ⬜ |
| TC-N09 | odometer_reading Non-Integer | "Odometer reading must be a whole number." | — | — | ⬜ |
| TC-N10 | issues_description Exceeds 512 | "Issues description cannot exceed 512 characters." | — | — | ⬜ |
| TC-N11 | remarks Exceeds 512 | "Remarks cannot exceed 512 characters." | — | — | ⬜ |
| TC-N12 | Failed Status Without issues_description | "Issues description is required when inspection is Failed." | — | — | ⬜ |
| TC-N13 | View With Invalid ID (null return) | show() uses `where('id',$id)->first()` → returns null → view crash or error | — | — | ⬜ |
| TC-N14 | Edit With Invalid ID | `where('id',$id)->first()` returns null → edit() passes null to view → view crash | — | — | ⬜ |
| TC-N15 | Delete With Invalid ID | `where('id',$id)->first()` returns null → `$inspection->delete()` on null → error | — | — | ⬜ |
| TC-N16 | Permission 403 — No Permissions | 403 on all endpoints | — | — | ⬜ |
| TC-N17 | Guest Access Redirect | Redirect to `/login` | — | — | ⬜ |
| TC-N18 | Failed status with any_issues_found=false | Conditional validation requires any_issues_found=required when Failed | — | — | ⬜ |
| TC-N19 | odometer_reading Non-Numeric String | integer rule rejects strings | — | — | ⬜ |
| TC-N20 | fuel_level_reading Non-Numeric | numeric rule rejects alphabetic | — | — | ⬜ |
| TC-N21 | Invalid driver_id (non-existent) | "The selected driver does not exist." | — | — | ⬜ |
| TC-N22 | Store with inspection_date in invalid format | date rule requires valid date format | — | — | ⬜ |
| TC-N23 | updateStatus with no status parameter | `$request->status` = null → sets null on non-existent column | — | — | ⬜ |
| TC-N24 | updateStatus with user without approve permission | POST to updateStatus → 403 | — | — | ⬜ |
| TC-N25 | Trash access without restore permission | GET /daily-vehicle-inspection/trash/view → 403 | — | — | ⬜ |

### 6.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|----------------|---------|---------|--------|
| TC-D01 | A | Failed Inspection Creates Service Request | Service request created with inspection reference; vehicle availability = false | — | — | ⬜ |
| TC-D02 | A | Failed Inspection Creates Duplicate Cleanup | Old pending service requests for same inspection_id are deleted before new one created | — | — | ⬜ |
| TC-D03 | B | Vehicle Deletion Cascades (CASCADE) | Deleting vehicle auto-deletes its inspections | — | — | ⬜ |
| TC-D04 | C | Driver Deletion Sets driver_id NULL | Driver deleted → inspection records preserved, driver_id=NULL | — | — | ⬜ |
| TC-D05 | D | Update from Passed→Failed Does NOT Trigger Auto-Workflow | Only store() has auto-creation logic; update() does NOT create service request | — | — | ⬜ |
| TC-D06 | C | Request authorize() Double-Gates Create/Update | FormRequest authorize() redundant with controller Gate::authorize() | — | — | ⬜ |
| TC-D07 | A | Standalone index Loads Without Crash | No `$request` param, no filters, just `->latest()->paginate(10)` — must not crash despite missing modal variables | — | — | ⬜ |
| TC-D08 | D | Fail Inspection — prepareForValidation Auto-Fills any_issues_found | POST with Failed + no any_issues_found → prepareForValidation sets it to 1 | — | — | ⬜ |
| TC-D09 | B | Inspected By User Deletion Sets inspected_by NULL | FK `fk_dvil_inspectedBy` has ON DELETE SET NULL | — | — | ⬜ |
| TC-D10 | D | VehicleMgmt Status Filter Broken (is_active BUG) | `dailyInspectionQuery()` uses `is_active` column which doesn't exist → MySQL error or empty results | — | — | ⬜ |
| TC-D11 | A | Multiple Failed Inspections on Same Vehicle | availability_status stays false (set repeatedly, no toggle) | — | — | ⬜ |
| TC-D12 | D | Table Name Mismatch: `tpt_daily_vehicle_inspections` vs `tpt_daily_vehicle_inspection` | VehicleMgmtController line 207 uses wrong plural name | — | — | ⬜ |

### 6.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|-----------------|---------|---------|--------|
| TC-CR01 | CR | P1 | show() Uses `where()->first()` Instead of `findOrFail()` | Line 90: returns null on bad ID → view may crash | — | — | ◌ |
| TC-CR02 | CR | P1 | edit() Fetches Before Gate Check | Line 99: executed BEFORE Gate::authorize() at line 100 — unnecessary DB query | — | — | ◌ |
| TC-CR03 | CR | P1 | destroy() Uses `where()->first()` Instead of `findOrFail()` | Line 157: `$inspection->delete()` on null if bad ID → error | — | — | ◌ |
| TC-CR04 | CR | P1 | updateStatus Sets `status` Field (Wrong Column) | Line 231: `$inspection->status` — table has `inspection_status`, not `status` | — | — | ◌ |
| TC-CR05 | CR | P1 | updateStatus No Inline Validation | No `$request->validate()` — any string accepted | — | — | ◌ |
| TC-CR06 | CR | P1 | Activity Log Events — 6 Types | Created, Updated, Trashed, Restored, ForceDeleted, StatusUpdated | — | — | ◌ |
| TC-CR07 | CR | P1 | Change Tracking on Update | getOriginal() + getChanges(); updated_at excluded | — | — | ◌ |
| TC-CR08 | CR | P1 | withTrashed() for forceDelete | Correct pattern at line 210 | — | — | ◌ |
| TC-CR09 | CR | P1 | onlyTrashed() for Restore | Correct pattern at line 191 | — | — | ◌ |
| TC-CR10 | CR | P1 | Conditional Validation for Failed Status | Adds required rules for issues fields in Request | — | — | ◌ |
| TC-CR11 | CR | P1 | prepareForValidation Boolean Conversion | 16 boolean fields converted from string to integer | — | — | ◌ |
| TC-CR12 | CR | P1 | Custom Error Messages | 18 custom messages via `messages()` method | — | — | ◌ |
| TC-CR13 | CR | P1 | Custom Attribute Names | 24 user-friendly field names via `attributes()` | — | — | ◌ |
| TC-CR14 | CR | P1 | Fillable Matches DDL | 26 fillable fields match DDL columns | — | — | ◌ |
| TC-CR15 | CR | P1 | Boolean Casts | 16 fields cast to boolean in model | — | — | ◌ |
| TC-CR16 | CR | P1 | Model Default Values | `inspection_status => 'Pending'`, `any_issues_found => 0` | — | — | ◌ |
| TC-CR17 | CR | P1 | DDL Typo `tailights_condition_ok` | Missing 'l' in 'taillights' — internally consistent | — | — | ◌ |
| TC-CR18 | CR | P1 | Routes — Resource + Additional | Resource + trashed/restore/forceDelete/updateStatus routes | — | — | ◌ |
| TC-CR19 | CR | P1 | dailyInspectionQuery Status Filter Bug | `where('is_active', ...)` — NO `is_active` column exists | — | — | ◌ |
| TC-CR20 | CR | P1 | Store Side-Effect — Vehicle Availability | Set to false on failed; no reverse on pass/restore | — | — | ◌ |
| TC-CR21 | CR | P1 | Activity Log — Create | operation='Created', message includes status | — | — | ◌ |
| TC-CR22 | CR | P1 | Activity Log — Update with Change Tracking | operation='Updated', changes array; updated_at excluded | — | — | ◌ |
| TC-CR23 | CR | P1 | Activity Log — Trashed | operation='Trashed', message='Moved to trash.' | — | — | ◌ |
| TC-CR24 | CR | P1 | Activity Log — Restored | operation='Restored', message='Restored.' | — | — | ◌ |
| TC-CR25 | CR | P1 | Activity Log — ForceDeleted | operation='ForceDeleted', message='Permanently deleted.' | — | — | ◌ |
| TC-CR26 | CR | P1 | Activity Log — StatusUpdated | operation='StatusUpdated', message includes new status | — | — | ◌ |
| TC-CR27 | CR | P2 | prepareForValidation Auto-Fills any_issues_found When Failed | Sets `any_issues_found=1` before validation | — | — | ◌ |
| TC-CR28 | CR | P2 | Standalone index() Missing Modal Variables | Does NOT pass `$all_vehicles`/`$all_drivers` → undefined variable in blade | — | — | ◌ |
| TC-CR29 | CR | P2 | update() Uses findOrFail — Inconsistent | update() line 118: findOrFail; show/edit/destroy: where()->first() | — | — | ◌ |
| TC-CR30 | CR | P1 | updateStatus Column Mismatch | `$inspection->status` sets non-existent attribute; not `inspection_status` | — | — | ◌ |
| TC-CR31 | CR | P2 | VehicleMgmtController storeStatus — Wrong Table Name | Line 207: `exists:tpt_daily_vehicle_inspections` (plural, wrong) | — | — | ◌ |
| TC-CR32 | CR | P2 | ServiceRequestController — Correct Table Name | Line 132: `exists:tpt_daily_vehicle_inspection` (singular, correct) | — | — | ◌ |

### 6.5 Activity Log Test Cases

| TC ID | Description | Expected ActivityLog Entry | V1 Test | V2 Test | Status |
|-------|-------------|---------------------------|---------|---------|--------|
| TC-AL01 | Create triggers activityLog | operation='Created', message='Daily vehicle inspection created. Status: Passed/Failed/Pending', performed_by=Auth::user() | — | — | ⬜ |
| TC-AL02 | Update triggers activityLog | operation='Updated', changes array with old→new per field; updated_at excluded; null if no real changes | — | — | ⬜ |
| TC-AL03 | Soft delete triggers activityLog | operation='Trashed', message='Daily vehicle inspection moved to trash.' | — | — | ⬜ |
| TC-AL04 | Restore triggers activityLog | operation='Restored', message='Daily vehicle inspection restored.' | — | — | ⬜ |
| TC-AL05 | Force delete triggers activityLog | operation='ForceDeleted', message='Daily vehicle inspection permanently deleted.' | — | — | ⬜ |
| TC-AL06 | updateStatus triggers activityLog | operation='StatusUpdated', message='Inspection status changed to {status}.' | — | — | ⬜ |

### 6.6 Permission Denied Test Cases

| TC ID | Description | Endpoint | Required Permission | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------|-------------------|-----------------|---------|---------|--------|
| TC-PD01 | index() without viewAny | GET /daily-vehicle-inspection | tenant.daily-vehicle-inspection.viewAny | 403 | — | — | ⬜ |
| TC-PD02 | create() without create | GET /daily-vehicle-inspection/create | tenant.daily-vehicle-inspection.create | 403 | — | — | ⬜ |
| TC-PD03 | store() without create | POST /daily-vehicle-inspection | tenant.daily-vehicle-inspection.create | 403 (Request authorize) | — | — | ⬜ |
| TC-PD04 | show() without view | GET /daily-vehicle-inspection/{id} | tenant.daily-vehicle-inspection.view | 403 | — | — | ⬜ |
| TC-PD05 | edit() without update | GET /daily-vehicle-inspection/{id}/edit | tenant.daily-vehicle-inspection.update | 403 | — | — | ⬜ |
| TC-PD06 | update() without update | PUT /daily-vehicle-inspection/{id} | tenant.daily-vehicle-inspection.update | 403 (Gate + Request) | — | — | ⬜ |
| TC-PD07 | destroy() without delete | DELETE /daily-vehicle-inspection/{id} | tenant.daily-vehicle-inspection.delete | 403 | — | — | ⬜ |
| TC-PD08 | trashed() without restore | GET /daily-vehicle-inspection/trash/view | tenant.daily-vehicle-inspection.restore | 403 | — | — | ⬜ |
| TC-PD09 | restore() without restore | GET /daily-vehicle-inspection/{id}/restore | tenant.daily-vehicle-inspection.restore | 403 | — | — | ⬜ |
| TC-PD10 | forceDelete() without forceDelete | DELETE /daily-vehicle-inspection/{id}/force-delete | tenant.daily-vehicle-inspection.forceDelete | 403 | — | — | ⬜ |
| TC-PD11 | updateStatus() without approve | POST /daily-vehicle-inspection/{id}/update-status | tenant.daily-vehicle-inspection.approve | 403 | — | — | ⬜ |

---

## 7. Detailed Test Steps

### TC-P01: Inspection Tab Loads Inside Vehicle Mgmt

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin with all `tenant.daily-vehicle-inspection.*` permissions | Success |
| 2 | Navigate to `/vehicle-mgmt` | `VehicleMgmtController@index()` loads |
| 3 | **Verify**: `Gate::authorize('tenant.transport.viewAny')` passes at line 29 | Authorized |
| 4 | **Verify**: Line 32-33: `$all_vehicles = Vehicle::all()`, `$all_drivers = DriverHelper::all()` | Master data loaded |
| 5 | **Verify**: Line 44: `$dailyInspectionEntries = $this->dailyInspectionQuery($request)->paginate(10)->withQueryString()` | Inspections query built |
| 6 | **Verify**: `dailyInspectionQuery()` line 69-70: with(['vehicle','driver'])->orderBy('inspection_date','DESC') | Eager loading + ordering |
| 7 | **Verify**: View receives `compact('dailyInspectionEntries', 'all_vehicles', 'all_drivers', ...)` | All 14 variables passed |
| 8 | Click Inspection tab in the 5-tab container | Tab pane activates |
| 9 | **Verify**: Filter bar with search_inspection input and status dropdown | Filter UI present |
| 10 | **Verify**: Table columns: Vehicle, Driver, Date, Odometer, Fuel, Conditions, Issues, Status, Action | Column headers match |
| 11 | **Verify**: Pagination links present (10 per page) | `->links()` rendered |
| 12 | **Verify**: If no inspections exist → "No Data Found" message | Empty state works |

### TC-P02: Standalone Inspection Index Page

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.daily-vehicle-inspection.viewAny` permission | Authenticated |
| 2 | Navigate directly to GET `/daily-vehicle-inspection` | Controller@index() |
| 3 | **Verify**: Gate::authorize('tenant.daily-vehicle-inspection.viewAny') at line 22 | Authorized |
| 4 | **Verify**: Line 24-26: with(['vehicle','driver'])->latest()->paginate(10) | Same query as tab |
| 5 | **Verify**: View `transport::daily-vehicle-Inspection.index` rendered | Blade loads |
| 6 | **Verify**: `$inspections` variable has paginated results | Paginator instance |
| 7 | **Verify**: Full-page layout (not tab-pane) | Different layout from tab |
| 8 | **Note**: `$all_vehicles`/`$all_drivers` NOT passed (BC-BIZ-DEEP-20) | May cause undefined variable |

### TC-P03: Create Inspection — Passed (All Conditions OK)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin with create permission | Success |
| 2 | Navigate to Vehicle Mgmt → Inspection tab | Tab loaded |
| 3 | Click "Add Inspection" | GET `/daily-vehicle-inspection/create` |
| 4 | **Verify**: Gate::authorize('tenant.daily-vehicle-inspection.create') at line 36 | Authorized |
| 5 | **Verify**: Line 38: `Vehicle::where('availability_status', true)->get()` | Only available vehicles shown |
| 6 | **Verify**: Line 39: `DriverHelper::active()->get()` | Only active drivers shown |
| 7 | Select vehicle from dropdown (must have availability_status=1) | Vehicle selected |
| 8 | Enter inspection_date: today's date | Date filled |
| 9 | Set all 15 condition checkboxes to Yes (checked) | All conditions=1 |
| 10 | Set any_issues_found = No (unchecked) | No issues |
| 11 | Leave issues_description empty | Null |
| 12 | Select inspection_status = "Passed" | Status selected |
| 13 | Click Submit | POST `/daily-vehicle-inspection` |
| 14 | **Verify**: `TptDailyVehicleInspectionRequest` rules pass | Validation ok |
| 15 | **Verify**: `prepareForValidation()` converts booleans | 'true' → 1 for all 15 conditions |
| 16 | **Verify**: `TptDailyVehicleInspection::create($request->validated())` | Record created |
| 17 | **Verify**: `inspection_status === 'Failed'` is false → no side effects | Service request NOT created |
| 18 | **Verify**: `activityLog($inspection, 'Created', ...)` called | Logged |
| 19 | **Verify**: Redirect to `transport.vehicle-mgmt.index` | `redirect()->route(...)` |
| 20 | **Verify**: Flash `'created.dailyvehicleInspection'` | Success message |
| 21 | DB: `SELECT * FROM tpt_daily_vehicle_inspection ORDER BY id DESC LIMIT 1` | Record exists, all conditions=1, inspection_status='Passed' |
| 22 | DB: `SELECT COUNT(*) FROM tpt_vehicle_service_request WHERE vehicle_inspection_id = X` | 0 (no service request) |
| 23 | DB: `SELECT availability_status FROM tpt_vehicle WHERE id = Y` | Unchanged (stays true if was true) |

### TC-P04: Create Inspection — Failed (With Auto-Workflow)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin with create permission | Success |
| 2 | Navigate to `/daily-vehicle-inspection/create` | Create form |
| 3 | Select vehicle (ensure availability_status=1 initially) | Vehicle selected |
| 4 | Enter inspection_date = today | Date filled |
| 5 | Set tire_condition_ok = false, engine_condition_ok = false (2 failures) | 2 conditions false |
| 6 | Set any_issues_found = true | Issues flagged |
| 7 | Enter issues_description = "Engine overheating, tire worn out" | Description filled |
| 8 | Select inspection_status = "Failed" | Status selected |
| 9 | Click Submit | POST `/daily-vehicle-inspection` |
| 10 | **Verify**: `prepareForValidation()` auto-sets any_issues_found=1 | Override if needed |
| 11 | **Verify**: Conditional validation for Failed: issues_description required | Passes |
| 12 | **Verify**: `TptDailyVehicleInspection::create()` succeeds | Inspection created |
| 13 | **Verify**: `$inspection->inspection_status === 'Failed'` | true |
| 14 | **Verify**: `TptVehicleServiceRequest::where('vehicle_inspection_id', $id)->delete()` | Cleans old |
| 15 | **Verify**: `TptVehicleServiceRequest::create([...])` | Service request created |
| 16 | **Verify**: `request_date = now()` | Current timestamp |
| 17 | **Verify**: `reason = 'Engine overheating, tire worn out'` | From issues_description |
| 18 | **Verify**: `request_approval_status = 'Pending'` | Default status |
| 19 | **Verify**: `vehicle_status = null` | Explicit null |
| 20 | **Verify**: `Vehicle::where('id', $vehicle_id)->update(['availability_status' => false])` | Vehicle unavailable |
| 21 | **Verify**: `activityLog($inspection, 'Created', ['message' => '...Status: Failed'])` | Logged |
| 22 | DB: `SELECT * FROM tpt_vehicle_service_request WHERE vehicle_inspection_id = X` | 1 row, status='Pending' |
| 23 | DB: `SELECT availability_status FROM tpt_vehicle WHERE id = Y` | 0 (false) |
| 24 | Navigate to create form again | Vehicle no longer in dropdown (availability_status=false) |

### TC-P05: Create Inspection — Pending

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with create permission | Success |
| 2 | Navigate to create form | Create form |
| 3 | Select vehicle, enter date, set all conditions OK | Valid data |
| 4 | Select inspection_status = "Pending" | Status selected |
| 5 | Click Submit | POST |
| 6 | **Verify**: `TptDailyVehicleInspection::create()` succeeds | Record with status='Pending' |
| 7 | **Verify**: `$inspection->inspection_status === 'Failed'` is false | No side effects |
| 8 | DB: NO service request created | tpt_vehicle_service_request empty for this ID |
| 9 | DB: Vehicle availability_status unchanged | No update query |

### TC-P06: View Inspection Details

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create inspection with vehicle, driver, all fields populated | id=X |
| 2 | Navigate to `/daily-vehicle-inspection/X` | show() |
| 3 | **Verify**: Gate::authorize('tenant.daily-vehicle-inspection.view') at line 89 | Authorized |
| 4 | **Verify**: Line 90: `TptDailyVehicleInspection::where('id',$id)->first()` | Record fetched |
| 5 | **Verify**: View `transport::daily-vehicle-Inspection.show` | Rendered |
| 6 | **Verify**: Vehicle registration_no displayed | Relationship loaded |
| 7 | **Verify**: Driver name displayed (or N/A if null) | Relationship loaded |
| 8 | **Verify**: inspection_date formatted | Date displayed |
| 9 | **Verify**: All 15 condition fields displayed (Yes/No) | Boolean rendered |
| 10 | **Verify**: issues_description displayed (or N/A) | Issues section |
| 11 | **Verify**: inspection_status displayed (Passed/Failed/Pending) | Status badge |
| 12 | **Verify**: odometer_reading, fuel_level_reading displayed | Numeric values |

### TC-P07: Edit Inspection Loads Pre-Filled Data

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create inspection with known values | id=X |
| 2 | Navigate to `/daily-vehicle-inspection/X/edit` | edit() |
| 3 | **Verify**: Line 99: record fetched BEFORE Gate check at line 100 | Unnecessary DB query if unauthorized |
| 4 | **Verify**: Gate::authorize('tenant.daily-vehicle-inspection.update') at line 100 | Authorized |
| 5 | **Verify**: Line 102: `Vehicle::active()->get()` (not availability filter) | All active vehicles |
| 6 | **Verify**: Line 103: `DriverHelper::active()->get()` | Active drivers |
| 7 | **Verify**: Edit form pre-filled with inspection's current values | vehicle_id, driver_id, date, conditions, status |
| 8 | **Verify**: Condition checkboxes reflect stored boolean values | Checked=true, unchecked=false |

### TC-P08: Update Inspection — Change Status Passed→Failed

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create inspection with status='Passed', conditions=all true | id=X, vehicle Y available |
| 2 | Navigate to edit form for X | Edit form |
| 3 | Change inspection_status to "Failed" | Status changed |
| 4 | Set any_issues_found = true | Issues flagged |
| 5 | Enter issues_description = "Found issue during re-check" | Description |
| 6 | Click Update | PUT `/daily-vehicle-inspection/X` |
| 7 | **Verify**: Gate::authorize('...update') at line 115 | Authorized |
| 8 | **Verify**: Line 118: `TptDailyVehicleInspection::findOrFail($id)` | Found (uses findOrFail) |
| 9 | **Verify**: Line 121: `$original = $inspection->getOriginal()` | Original captured |
| 10 | **Verify**: Line 124: `$inspection->update($request->validated())` | Updated |
| 11 | **Verify**: Line 128-137: Changes array built | inspection_status: old='Passed', new='Failed' |
| 12 | **Verify**: Line 129-131: updated_at excluded from changes | Not in array |
| 13 | **Verify**: Line 140-144: `activityLog($inspection, 'Updated', ['changes' => [...]])` | Logged |
| 14 | **Verify**: Redirect to vehicle-mgmt with success flash | Success |
| 15 | **CRITICAL**: DB: `SELECT COUNT(*) FROM tpt_vehicle_service_request WHERE vehicle_inspection_id = X` | 0 — update does NOT create service request |
| 16 | **CRITICAL**: DB: `SELECT availability_status FROM tpt_vehicle WHERE id = Y` | Unchanged — update does NOT set false |
| 17 | **BUG CONFIRMED**: Failed on update has no side effects (BC-BIZ-48, BC-BIZ-49) | No auto-workflow |

### TC-P09: Update Inspection — Toggle Condition Field

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create inspection with tire_condition_ok=true | id=X |
| 2 | Edit: change tire_condition_ok to false | Toggle off |
| 3 | Submit update | PUT |
| 4 | **Verify**: Change tracking captures `tire_condition_ok: old=1, new=0` | In changes array |
| 5 | **Verify**: Activity log includes the change | 'changes' has tire_condition_ok |

### TC-P10: Soft Delete Inspection

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create inspection with known ID | id=X |
| 2 | Call DELETE `/daily-vehicle-inspection/X` | destroy(X) |
| 3 | **Verify**: Gate::authorize('...delete') at line 156 | Authorized |
| 4 | **Verify**: Line 157: `TptDailyVehicleInspection::where('id',$id)->first()` | Fetched (risky: may return null) |
| 5 | **Verify**: Line 158: `$inspection->delete()` | Soft delete |
| 6 | DB: `SELECT deleted_at FROM tpt_daily_vehicle_inspection WHERE id = X` | deleted_at IS NOT NULL |
| 7 | **Verify**: Line 160-163: `activityLog($inspection, 'Trashed', ...)` | Logged |
| 8 | **Verify**: Redirect to vehicle-mgmt with success flash | Success |

### TC-P11: Restore Inspection From Trash

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete inspection | id=X, deleted_at set |
| 2 | Call GET `/daily-vehicle-inspection/X/restore` | restore(X) |
| 3 | **Verify**: Gate::authorize('...restore') at line 189 | Authorized |
| 4 | **Verify**: Line 191: `onlyTrashed()->findOrFail($id)` | Found in trash |
| 5 | **Verify**: Line 192: `$inspection->restore()` | deleted_at = NULL |
| 6 | DB: `SELECT deleted_at FROM tpt_daily_vehicle_inspection WHERE id = X` | NULL |
| 7 | **Verify**: `activityLog($inspection, 'Restored', ...)` at line 194 | Logged |
| 8 | **Verify**: Redirect + flash | Success |

### TC-P12: Force Delete Inspection

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create inspection | id=X |
| 2 | Soft-delete it first | deleted_at set |
| 3 | Call DELETE `/daily-vehicle-inspection/X/force-delete` | forceDelete(X) |
| 4 | **Verify**: Gate::authorize('...forceDelete') at line 208 | Authorized |
| 5 | **Verify**: Line 210: `withTrashed()->findOrFail($id)` | Found (active or trashed) |
| 6 | **Verify**: Line 211: `$inspection->forceDelete()` | Permanently deleted |
| 7 | DB: `SELECT * FROM tpt_daily_vehicle_inspection WHERE id = X` | No rows |
| 8 | **Verify**: `activityLog($inspection, 'ForceDeleted', ...)` at line 213 | Logged |

### TC-P13: Update Status via AJAX

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create inspection with status='Pending' | id=X |
| 2 | POST `/daily-vehicle-inspection/X/update-status` with body `{status: "Approved"}` | updateStatus() |
| 3 | **Verify**: Gate::authorize('...approve') at line 228 | Authorized |
| 4 | **Verify**: Line 230: `where('id',$id)->first()` | Fetched |
| 5 | **Verify**: Line 231: `$inspection->status = $request->status` | Sets `status` not `inspection_status` (BUG) |
| 6 | **Verify**: Line 232: `$inspection->save()` | Persisted |
| 7 | **BUG**: $inspection->status sets non-existent column `status` | No effect on `inspection_status` |
| 8 | **Verify**: Line 234-237: activityLog with 'StatusUpdated' | Logged |
| 9 | **Verify**: JSON response `{success: true, status: "Approved", message: "Status updated successfully."}` | 200 OK |

### TC-P14: Filter Inspections By Vehicle Registration No

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure inspection exists for vehicle with reg_no='ABC123' | Matching record |
| 2 | Navigate to Vehicle Mgmt → Inspection tab | Tab loaded |
| 3 | Enter search_inspection = "ABC123" | Search term |
| 4 | Click Search/Filter | GET with query string |
| 5 | **Verify**: `dailyInspectionQuery()` line 74: `$request->filled('search_inspection')` | true |
| 6 | **Verify**: Line 77-78: `whereHas('vehicle', fn => where('registration_no','LIKE','%ABC123%'))` | Subquery added |
| 7 | **Verify**: Grid shows only matching inspection | Filtered result |
| 8 | Clear search, test with partial: "ABC" | Partial match works |

### TC-P15: Empty State — No Inspections

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure no inspections exist (clean DB or filter that yields none) | Empty set |
| 2 | Navigate to Inspection tab or standalone index | Page loads |
| 3 | **Verify**: `$inspections->isEmpty()` is true | Empty collection |
| 4 | **Verify**: Blade renders "No Data Found" or equivalent message | Empty state visible |

### TC-P16: Create Inspection — Passed (Minimal Fields)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to create form | Form loads |
| 2 | Select vehicle only (required) | vehicle_id set |
| 3 | Enter inspection_date only (required) | Date filled |
| 4 | Select inspection_status = "Passed" (required) | Status set |
| 5 | Do NOT touch any condition checkboxes | Default to unchecked (0/false) |
| 6 | Click Submit | POST |
| 7 | **Verify**: `prepareForValidation()` sets all missing booleans to 0 | All 16 booleans = 0 |
| 8 | **Verify**: `TptDailyVehicleInspection::create()` with defaults | All conditions=false |
| 9 | DB: `SELECT tire_condition_ok, engine_condition_ok, ... FROM ...` | All 0 |

### TC-P17: Create Inspection — With Driver Assignment

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create form | Loaded |
| 2 | Select vehicle | Vehicle selected |
| 3 | Select driver from dropdown | driver_id populated |
| 4 | Fill remaining required fields | Complete |
| 5 | Submit | POST |
| 6 | DB: `SELECT driver_id FROM tpt_daily_vehicle_inspection` | Matches selected driver |
| 7 | Show page: driver relationship loaded | Driver name displayed |

### TC-P18: Create Inspection — With Odometer & Fuel Readings

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create form | Loaded |
| 2 | Fill required fields + odometer_reading=15000, fuel_level_reading=75.50 | Values entered |
| 3 | Submit | POST |
| 4 | DB: `SELECT odometer_reading, fuel_level_reading` | 15000, 75.50 |
| 5 | Verify model cast: fuel_level_reading → decimal:2 | Stored as 75.50 |

### TC-P19: Create Inspection — With Remarks Only

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create form | Loaded |
| 2 | Fill required fields | Complete |
| 3 | Enter remarks = "Scheduled maintenance check" | Comments |
| 4 | Submit | POST |
| 5 | DB: `SELECT remarks` | 'Scheduled maintenance check' |

### TC-P20: Update Inspection — Clear Odometer/Fuel to Null

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create inspection with odometer=15000, fuel=75.50 | id=X |
| 2 | Edit: clear both fields (set to empty/null) | Odometer=null, Fuel=null |
| 3 | Submit update | PUT |
| 4 | DB: `SELECT odometer_reading, fuel_level_reading WHERE id = X` | NULL, NULL |
| 5 | **Verify**: Change tracking includes both fields | odometer: old=15000→new=null |

### TC-P21: Create Inspection — Mixed Conditions

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create form | Loaded |
| 2 | Set: tire=OK, lights=OK, brakes=OK, engine=NOT OK, battery=OK, fire_extinguisher=OK, first_aid=OK, seat_belts=NOT OK, headlights=OK, tailights=OK, wipers=OK, mirrors=OK, steering=OK, emergency_tools=NOT OK, cleanliness=OK | 3 false, 12 true |
| 3 | inspection_status = "Passed" (allows mixed; only Failed triggers workflow) | Status set |
| 4 | Submit | POST |
| 5 | DB: `SELECT engine_condition_ok, seat_belts_condition_ok, emergency_tools_condition_ok` | 0, 0, 0 |
| 6 | All other 12 conditions = 1 | true |

### TC-P22: Filter Inspections By Driver Name

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure inspection exists for driver named "Ramesh" | Matching record |
| 2 | In Inspection tab filter: enter "Ramesh" in search | Search term |
| 3 | **Verify**: `dailyInspectionQuery()` line 80-82: `orWhereHas('driver', fn=>where('name','LIKE','%Ramesh%'))` | Subquery added |
| 4 | Grid shows matching inspection | Filtered |

### TC-P23: Tab Persists Active State After CRUD

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to `/vehicle-mgmt` | All tabs load |
| 2 | Click Inspection tab | Active |
| 3 | Create inspection via the "Add" button on tab | Redirects back with tab param |
| 4 | **Verify**: URL contains `?tab=inspection` or similar | Tab state preserved |
| 5 | Update/delete should also redirect back with tab | Consistent UX |

### TC-P24: Pagination in Standalone Index

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed 15 inspection records | 15 rows |
| 2 | Navigate to `/daily-vehicle-inspection` | Page 1, 10 items |
| 3 | **Verify**: Paginator shows 2 pages | Page 1 of 2 |
| 4 | Click page 2 | 5 items (10-15) |
| 5 | **Verify**: `->paginate(10)` at line 26 | Correct count |

### TC-P25: Update Inspection — No Changes Submitted

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create inspection with specific values | id=X |
| 2 | Navigate to edit form | Pre-filled |
| 3 | Submit without changing any field | PUT |
| 4 | **Verify**: `$changes` array is empty (or has updated_at only) | Empty after updated_at excluded |
| 5 | **Verify**: Activity log: `'changes' => null` | `!empty($changes)` = false → null |
| 6 | DB: updated_at timestamp updated | Timestamp changes |

### TC-N01: Missing vehicle_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to create form | Form loads |
| 2 | Leave vehicle dropdown empty | No selection |
| 3 | Fill inspection_date, select status | Other fields filled |
| 4 | Click Submit | POST |
| 5 | **Verify**: Validation rule `vehicle_id => required|exists:tpt_vehicle,id` | "Please select a vehicle." |
| 6 | **Verify**: Form re-displayed with error | Error message shown |

### TC-N02: Missing inspection_date

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create form, select vehicle, select status | Date empty |
| 2 | Submit | POST |
| 3 | **Verify**: `inspection_date => required|date` | "Inspection date is required." |
| 4 | Error displayed | On form |

### TC-N03: Missing inspection_status

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create form, fill all except status | Status empty |
| 2 | Submit | POST |
| 3 | **Verify**: `inspection_status => required|in:Passed,Failed,Pending` | "Inspection status is required." |
| 4 | Error displayed | On form |

### TC-N04: Invalid inspection_status Value

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create form, fill required fields | Valid otherwise |
| 2 | Submit with inspection_status = "Approved" (invalid) | Not in ENUM |
| 3 | **Verify**: `Rule::in(['Passed','Failed','Pending'])` | "Please select a valid inspection status." |
| 4 | Also test: "approved", "pass", "" | All rejected |

### TC-N05: Invalid vehicle_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create form | Loaded |
| 2 | Manipulate vehicle_id = 99999 (non-existent) | Invalid FK |
| 3 | Submit | POST |
| 4 | **Verify**: `exists:tpt_vehicle,id` | "The selected vehicle does not exist." |

### TC-N06: fuel_level_reading > 100

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create form, enter fuel_level_reading = 150 | Exceeds max |
| 2 | Submit | POST |
| 3 | **Verify**: `max:100` | "Fuel level cannot exceed 100%." |

### TC-N07: fuel_level_reading Negative

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create form, enter fuel_level_reading = -10 | Negative |
| 2 | Submit | POST |
| 3 | **Verify**: `min:0` | "Fuel level cannot be less than 0%." |

### TC-N08: odometer_reading Negative

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create form, enter odometer_reading = -500 | Negative |
| 2 | Submit | POST |
| 3 | **Verify**: `min:0` | "Odometer reading cannot be negative." |

### TC-N09: odometer_reading Non-Integer

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create form, enter odometer_reading = "ABC" | String |
| 2 | Submit | POST |
| 3 | **Verify**: `integer` rule | "Odometer reading must be a whole number." |

### TC-N10: issues_description Exceeds 512

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create form, set status=Failed | Required issues |
| 2 | Enter issues_description = 513+ characters | Exceeds max |
| 3 | Submit | POST |
| 4 | **Verify**: `max:512` | "Issues description cannot exceed 512 characters." |

### TC-N11: remarks Exceeds 512

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create form, enter remarks = 513+ characters | Exceeds max |
| 2 | Submit | POST |
| 3 | **Verify**: `max:512` | "Remarks cannot exceed 512 characters." |

### TC-N12: Failed Status Without issues_description

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create form, select inspection_status="Failed" | Status selected |
| 2 | Leave issues_description empty | Not filled |
| 3 | Set any_issues_found = true | Issues flagged |
| 4 | Click Submit | POST |
| 5 | **Verify**: Conditional validation at line 68-71: `issues_description => required` | "Issues description is required when inspection is Failed." |

### TC-N13: View With Invalid ID (null return BUG)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to `/daily-vehicle-inspection/99999` | Non-existent ID |
| 2 | **Verify**: Line 90: `TptDailyVehicleInspection::where('id',99999)->first()` | Returns null |
| 3 | **Verify**: View receives `$inspection = null` | `compact('inspection')` passes null |
| 4 | View tries `$inspection->vehicle` etc. | **Error**: "Call to a member function vehicle() on null" |
| 5 | **BUG**: Should use `findOrFail()` for proper 404 | Compare with update() line 118 which uses findOrFail |

### TC-N14: Edit With Invalid ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to `/daily-vehicle-inspection/99999/edit` | Non-existent ID |
| 2 | **Verify**: Line 99: `where('id',99999)->first()` | Returns null |
| 3 | **Verify**: Line 100: Gate::authorize() runs on null | Gate passes (not model-dependent) |
| 4 | View receives `$inspection = null` | Crash on view access |
| 5 | **BUG**: No existence check before view | Should use findOrFail() |

### TC-N15: Delete With Invalid ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Call DELETE `/daily-vehicle-inspection/99999` | Non-existent ID |
| 2 | **Verify**: Line 157: `where('id',99999)->first()` | Returns null |
| 3 | **Verify**: Line 158: `$inspection->delete()` | **Error**: Call to delete() on null |
| 4 | **BUG**: should use findOrFail() or null check | 500 error instead of 404 |

### TC-N16: Permission 403 — No Permissions

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user with NO `tenant.daily-vehicle-inspection.*` permissions | No access |
| 2 | GET `/daily-vehicle-inspection` | 403 (viewAny) |
| 3 | GET `/daily-vehicle-inspection/create` | 403 (create) |
| 4 | POST `/daily-vehicle-inspection` | 403 (create via Request authorize) |
| 5 | GET `/daily-vehicle-inspection/1` | 403 (view) |
| 6 | GET `/daily-vehicle-inspection/1/edit` | 403 (update) |
| 7 | PUT `/daily-vehicle-inspection/1` | 403 (update via Gate + Request) |
| 8 | DELETE `/daily-vehicle-inspection/1` | 403 (delete) |
| 9 | GET `/daily-vehicle-inspection/trash/view` | 403 (restore) |
| 10 | GET `/daily-vehicle-inspection/1/restore` | 403 (restore) |
| 11 | DELETE `/daily-vehicle-inspection/1/force-delete` | 403 (forceDelete) |
| 12 | POST `/daily-vehicle-inspection/1/update-status` | 403 (approve) |

### TC-N17: Guest Access Redirect

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Logout (no authenticated user) | Guest |
| 2 | GET `/daily-vehicle-inspection` | Redirect to `/login` |
| 3 | All other inspection endpoints | Redirect to `/login` |

### TC-N18: Failed Without any_issues_found

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create form, select inspection_status="Failed" | Failed selected |
| 2 | Set any_issues_found = false (unchecked) | False |
| 3 | Enter issues_description = "Test issue" | Description filled |
| 4 | Submit | POST |
| 5 | **Verify**: `prepareForValidation()` auto-fills any_issues_found=1 when Failed (BC-BIZ-DEEP-08) | Override happens BEFORE validation |
| 6 | **Verify**: Validation passes (any_issues_found now = 1) | No error |
| 7 | DB: `any_issues_found = 1` | Auto-filled |

### TC-N19: odometer_reading Non-Numeric String

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create form, enter odometer_reading = "fifty thousand" | String |
| 2 | Submit | POST |
| 3 | **Verify**: `integer` rule | "Odometer reading must be a whole number." |

### TC-N20: fuel_level_reading Non-Numeric

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create form, enter fuel_level_reading = "full" | Alphabetic |
| 2 | Submit | POST |
| 3 | **Verify**: `numeric` rule | "Fuel level must be a number." |

### TC-N21: Invalid driver_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create form, manipulate driver_id = 99999 | Non-existent |
| 2 | Submit | POST |
| 3 | **Verify**: `exists:tpt_personnel,id` | "The selected driver does not exist." |

### TC-N22: Invalid inspection_date Format

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create form, enter inspection_date = "not-a-date" | Invalid |
| 2 | Submit | POST |
| 3 | **Verify**: `date` rule | "Please provide a valid inspection date." |

### TC-N23: updateStatus with No Status Parameter

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create inspection | id=X |
| 2 | POST `/daily-vehicle-inspection/X/update-status` with empty body | No status in request |
| 3 | **Verify**: `$request->status` is null | No validation to catch |
| 4 | **Verify**: `$inspection->status = null` | Sets null on non-existent column |
| 5 | **BUG**: No validation — any payload accepted | Silent failure |

### TC-N24: updateStatus Without Approve Permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user without `tenant.daily-vehicle-inspection.approve` | No approve |
| 2 | POST `/daily-vehicle-inspection/1/update-status` | 403 |

### TC-N25: Trash Without Restore Permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login without `tenant.daily-vehicle-inspection.restore` | No restore |
| 2 | GET `/daily-vehicle-inspection/trash/view` | 403 |

### TC-D01: Failed Inspection Creates Service Request

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create inspection with status=Failed, issues_description="Brake failure" | id=X, vehicle_id=Y |
| 2 | DB: `SELECT * FROM tpt_vehicle_service_request WHERE vehicle_inspection_id = X` | 1 row |
| 3 | **Verify**: `request_date` = today | now() |
| 4 | **Verify**: `reason` = "Brake failure" | From issues_description |
| 5 | **Verify**: `request_approval_status` = "Pending" | Pending |
| 6 | **Verify**: `vehicle_status` = NULL | Explicit null |
| 7 | DB: `SELECT availability_status FROM tpt_vehicle WHERE id = Y` | 0 (false) |

### TC-D02: Failed Inspection — Old Service Request Cleanup

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create inspection #1 with status=Failed for vehicle Y | id=X1, SR created |
| 2 | Create inspection #2 for same vehicle Y, also Failed | id=X2 |
| 3 | **Note**: store() does NOT clean old SRs by vehicle_id — only by inspection_id | `where('vehicle_inspection_id', $inspection->id)->delete()` — deletes only for THIS inspection |
| 4 | **Verify**: Old SR from X1 still exists | Not deleted |
| 5 | DB: `SELECT COUNT(*) FROM tpt_vehicle_service_request WHERE vehicle_inspection_id IN (X1, X2)` | 2 rows |

### TC-D03: Vehicle Deletion Cascades

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create inspection referencing vehicle Y | id=X |
| 2 | Delete vehicle Y from tpt_vehicle | `DELETE FROM tpt_vehicle WHERE id = Y` |
| 3 | FK `fk_dvil_vehicle` has ON DELETE CASCADE | Auto-deletes inspection X |
| 4 | DB: `SELECT * FROM tpt_daily_vehicle_inspection WHERE id = X` | No rows |
| 5 | **Verify**: Not testable via UI (vehicle has its own controller/deletion flow) | DB-level integrity |

### TC-D04: Driver Deletion Sets driver_id NULL

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create inspection with driver Z | driver_id = Z |
| 2 | Delete driver Z from tpt_personnel | `DELETE FROM tpt_personnel WHERE id = Z` |
| 3 | FK `fk_dvil_driver` has ON DELETE SET NULL | driver_id set to NULL |
| 4 | DB: `SELECT driver_id FROM tpt_daily_vehicle_inspection WHERE id = X` | NULL |

### TC-D05: Update Passed→Failed Does NOT Trigger Auto-Workflow

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create inspection with status=Passed | id=X, no SR |
| 2 | Update status to Failed, add issues_description | PUT |
| 3 | DB: `SELECT * FROM tpt_vehicle_service_request WHERE vehicle_inspection_id = X` | 0 rows |
| 4 | **CONFIRMED**: update() has no side-effect logic | Only store() creates SR |

### TC-D06: Request authorize() Double-Gates

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `TptDailyVehicleInspectionRequest.php:14-19` | `authorize()` checks permission |
| 2 | Open controller store() line 48 | `Gate::authorize('...create')` |
| 3 | Both check same permission for POST | Redundant |
| 4 | **Impact**: Minor redundancy — no functional bug | Both must pass |

### TC-D07: Standalone Index Loads Without Crash

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to `/daily-vehicle-inspection` | Standalone index |
| 2 | **Verify**: `index()` at line 20: no `$request` parameter | No filters |
| 3 | **Verify**: Line 24-26: `with(['vehicle','driver'])->latest()->paginate(10)` | Works |
| 4 | **Verify**: Line 28: `compact('inspections')` only | Only one variable |
| 5 | **Check**: If blade references `$all_vehicles` or `$all_drivers` | Undefined variable error |
| 6 | **BUG**: Standalone index may crash if shared blade uses modal variables | TC-CR28 |

### TC-D08: Fail Inspection — prepareForValidation Auto-Fills

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST with inspection_status="Failed", no any_issues_found field | Not sent |
| 2 | **Verify**: `prepareForValidation()` line 179-183: condition met | `$this->input('inspection_status') === 'Failed' && !$this->has('any_issues_found')` |
| 3 | **Verify**: `$this->merge(['any_issues_found' => 1])` | Merged |
| 4 | **Verify**: `any_issues_found => required|boolean` passes | Field now = 1 |

### TC-D09: Inspected By User Deletion

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create inspection with inspected_by = user W | inspector set |
| 2 | Delete user W from sys_users | `DELETE FROM sys_users WHERE id = W` |
| 3 | FK `fk_dvil_inspectedBy` has ON DELETE SET NULL | inspected_by = NULL |
| 4 | DB: `SELECT inspected_by FROM tpt_daily_vehicle_inspection WHERE id = X` | NULL |

### TC-D10: VehicleMgmt Status Filter Broken (is_active BUG)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `VehicleMgmtController.php:87-89` | `$query->where('is_active', $request->status)` |
| 2 | Verify DDL of `tpt_daily_vehicle_inspection` | NO `is_active` column (BC-BIZ-DEEP-42) |
| 3 | Apply status filter in Inspection tab | Query fails with MySQL "Unknown column 'is_active'" or empty results |
| 4 | **BUG**: Filter is broken — references non-existent column | Should filter by `inspection_status` |

### TC-D11: Multiple Failed Inspections Same Vehicle

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Failed inspection #1 for vehicle Y | availability_status = false |
| 2 | Create Failed inspection #2 for same vehicle Y | availability_status = false (set again) |
| 3 | DB stays false — no toggle behavior | Consistent |

### TC-D12: Table Name Mismatch

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `VehicleMgmtController.php:207` | `exists:tpt_daily_vehicle_inspections` (plural — WRONG) |
| 2 | Open `TptVehicleServiceRequestController.php:132` | `exists:tpt_daily_vehicle_inspection` (singular — CORRECT) |
| 3 | Verify actual table name in migration | `Schema::create('tpt_daily_vehicle_inspection', ...)` — singular |
| 4 | **BUG**: VehicleMgmtController validation references non-existent table `tpt_daily_vehicle_inspections` | Validation error: "Table not found" |

### TC-CR02: edit() Fetches Before Gate Check

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `TptDailyVehicleInspectionController.php:97-106` | edit() method |
| 2 | Line 99: `$inspection = TptDailyVehicleInspection::where('id',$id)->first()` | DB query executed |
| 3 | Line 100: `Gate::authorize('tenant.daily-vehicle-inspection.update')` | Gate check AFTER query |
| 4 | **Impact**: If user lacks permission, unnecessary DB query already ran | Performance issue |
| 5 | **Fix**: Move Gate::authorize() to line 98, before DB query | Reorder lines |

### TC-CR04: updateStatus Sets Wrong Column (`status` vs `inspection_status`)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `TptDailyVehicleInspectionController.php:226-244` | updateStatus() |
| 2 | Line 231: `$inspection->status = $request->status` | Sets `status` attribute |
| 3 | Check DDL: column is `inspection_status`, not `status` | `status` does NOT exist |
| 4 | `$inspection->save()` persists `status` to DB | No matching column → attribute stored in model but not persisted |
| 5 | **BUG**: updateStatus has NO EFFECT on inspection_status | Should be `$inspection->inspection_status = $request->status` |

### TC-CR19: dailyInspectionQuery Status Filter Bug

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `VehicleMgmtController.php:86-89` | Status filter block |
| 2 | Line 88: `$query->where('is_active', $request->status)` | References `is_active` |
| 3 | Search DDL for `is_active` in `tpt_daily_vehicle_inspection` | Column does NOT exist |
| 4 | The correct column is `inspection_status` | `$query->where('inspection_status', $request->status)` |
| 5 | **BUG**: Filter silently fails (no error if MySQL strict mode allows) | All inspections returned regardless of filter |

### TC-CR27: prepareForValidation Auto-Fills any_issues_found When Failed

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `TptDailyVehicleInspectionRequest.php:178-183` | Auto-fill block |
| 2 | Condition: `$this->input('inspection_status') === 'Failed' && !$this->has('any_issues_found')` | True when Failed + missing field |
| 3 | Action: `$this->merge(['any_issues_found' => 1])` | Sets to 1 |
| 4 | Purpose: Ensures conditional validation `any_issues_found => required` passes | Validation succeeds |

### TC-CR28: Standalone index() Missing Modal Variables

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `TptDailyVehicleInspectionController.php:20-28` | index() method |
| 2 | Line 28: `compact('inspections')` | Only passes `$inspections` |
| 3 | Check if shared `index.blade.php` references `$all_vehicles` or `$all_drivers` | These are passed in VehicleMgmtController but NOT in standalone |
| 4 | **BUG**: If blade references these variables, standalone page crashes | Undefined variable error |

### TC-CR30: updateStatus Column Mismatch — status vs inspection_status

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `TptDailyVehicleInspectionController.php:231` | `$inspection->status = $request->status` |
| 2 | Check model fillable: `'inspection_status'` | `status` is NOT fillable |
| 3 | Direct property assignment `$inspection->status` sets a dynamic attribute | Not mapped to any DB column |
| 4 | `$inspection->save()` runs UPDATE query | Column `status` is not in table → ignored |
| 5 | **Result**: The `inspection_status` column never changes via updateStatus | **BUG: updateStatus does nothing** |

### TC-CR31: VehicleMgmtController storeStatus — Wrong Table Name

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `VehicleMgmtController.php:207` | Validation rule |
| 2 | `'vehicle_inspection_id' => 'nullable|exists:tpt_daily_vehicle_inspections,id'` | References PLURAL table name |
| 3 | Actual table: `tpt_daily_vehicle_inspection` (singular) | Mismatch |
| 4 | **BUG**: This validation will always fail because the table `tpt_daily_vehicle_inspections` doesn't exist | 422 error on valid inspection IDs |

### TC-AL01: Create Inspection Activity Log

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create inspection with status='Passed' | Created |
| 2 | Check activity_log table (or activityLog function output) | Entry: operation='Created', message='Daily vehicle inspection created. Status: Passed', performed_by=Auth::user()->name |
| 3 | Create another with status='Failed' | Message: '...Status: Failed' |
| 4 | Create another with status='Pending' | Message: '...Status: Pending' |

### TC-AL02: Update Inspection Activity Log

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create inspection with tire_condition_ok=true | id=X |
| 2 | Update: set tire_condition_ok=false, inspect_status='Failed' | PUT |
| 3 | **Verify**: `$original` captured the old values | Original stored |
| 4 | **Verify**: `getChanges()` has both changed fields | tire_condition_ok + inspection_status |
| 5 | **Verify**: updated_at excluded | Not in changes |
| 6 | **Verify**: Activity log: operation='Updated', changes array with old→new pairs | Logged |

### TC-AL03: Soft Delete Activity Log

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create inspection | id=X |
| 2 | Soft delete | destroy(X) |
| 3 | **Verify**: `activityLog($inspection, 'Trashed', ['message' => 'Daily vehicle inspection moved to trash.'])` | Logged |

### TC-AL04: Restore Activity Log

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Restore inspection from trash | restore(X) |
| 2 | **Verify**: `activityLog($inspection, 'Restored', ['message' => 'Daily vehicle inspection restored.'])` | Logged |

### TC-AL05: Force Delete Activity Log

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Force delete inspection | forceDelete(X) |
| 2 | **Verify**: `activityLog($inspection, 'ForceDeleted', ['message' => 'Daily vehicle inspection permanently deleted.'])` | Logged |

### TC-AL06: UpdateStatus Activity Log

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST updateStatus with status='Approved' | updateStatus() |
| 2 | **Verify**: `activityLog($inspection, 'StatusUpdated', ['message' => 'Inspection status changed to Approved.'])` | Logged |

### TC-PD01 through TC-PD11: Permission Denied

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | For each PD test: login as user WITHOUT the specific permission | 403 expected |
| 2 | Call the endpoint listed in the table | 403 Forbidden response |
| 3 | **Verify**: `Gate::authorize()` throws `AuthorizationException` | Laravel converts to 403 |
| 4 | **Verify**: No data is created/updated/deleted | No side effects |

### BC-BIZ-DEEP-01: Model Default Attributes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `TptDailyVehicleInspection.php:61-64` | `$attributes = ['inspection_status' => 'Pending', 'any_issues_found' => 0]` |
| 2 | Create inspection without setting these fields | Defaults applied |
| 3 | DB: `SELECT inspection_status, any_issues_found` | 'Pending', 0 |

### BC-BIZ-DEEP-06: Boolean Conversion in prepareForValidation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST with `tire_condition_ok = 'true'` (string) | prepareForValidation converts to 1 |
| 2 | POST with `tire_condition_ok = 'false'` (string) | Converts to 0 |
| 3 | POST with `tire_condition_ok = '1'` (string) | Converts to 1 |
| 4 | POST with `tire_condition_ok = '0'` (string) | Converts to 0 |
| 5 | POST with `tire_condition_ok = true` (boolean) | Converts to 1 |
| 6 | POST with `tire_condition_ok = false` (boolean) | Converts to 0 |
| 7 | POST without `tire_condition_ok` | Default to 0 (line 171-175) |

### BC-BIZ-DEEP-18: is_active Filter Bug (Code Trace)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `VehicleMgmtController.php:86-89` | `if ($request->filled('status')) { $query->where('is_active', $request->status); }` |
| 2 | DDL: `tpt_daily_vehicle_inspection` has NO `is_active` | Migration line 14-50 |
| 3 | Expected: should filter by `inspection_status` | `$query->where('inspection_status', $request->status)` |
| 4 | Impact: Status dropdown filter broken | No error, but no filtering |

### BC-BIZ-DEEP-25: updateStatus Uses Non-existent `status` Column (Code Trace)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `TptDailyVehicleInspectionController.php:231` | `$inspection->status = $request->status;` |
| 2 | Check `$fillable` in model | `'inspection_status'` — NOT `'status'` |
| 3 | Check DDL columns | `inspection_status` (ENUM) — NO `status` column |
| 4 | `$inspection->save()` | Dynamic attribute `status` is NOT a DB column |
| 5 | **BUG**: updateStatus has no effect on inspection_status | The column `inspection_status` remains unchanged |

### BC-BIZ-DEEP-55: Table Name Mismatch (Code Trace)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `VehicleMgmtController.php:207` | `'vehicle_inspection_id' => 'nullable|exists:tpt_daily_vehicle_inspections,id'` |
| 2 | Open actual migration file | `Schema::create('tpt_daily_vehicle_inspection', ...)` — singular |
| 3 | Expected table: `tpt_daily_vehicle_inspection` | Actual correct name |
| 4 | **BUG**: Validation rule references non-existent table `tpt_daily_vehicle_inspections` | Will fail with "Table not found" SQL error |

### BC-BIZ-DEEP-02: Model Boolean Casts (Code Trace)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `TptDailyVehicleInspection.php:69-91` | 16 boolean casts defined |
| 2 | Create inspection with `tire_condition_ok = 1` in DB | Model returns `true` (boolean) |
| 3 | Access `$inspection->tire_condition_ok` in Blade | `true` not `1` |
| 4 | **Verify**: boolean cast affects JSON serialization | `inspection.toJSON()` has boolean not int |

### BC-BIZ-DEEP-03: inspection_date Timestamp Cast

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open model line 70 | `'inspection_date' => 'datetime'` |
| 2 | Create inspection with `inspection_date = '2026-07-21 10:30:00'` | Stored as TIMESTAMP |
| 3 | Access `$inspection->inspection_date` | Carbon instance |
| 4 | Format: `$inspection->inspection_date->format('Y-m-d')` | '2026-07-21' |

### BC-BIZ-DEEP-07: Missing Boolean Fields Default to 0

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST without ANY condition fields in request | All 16 booleans absent |
| 2 | `prepareForValidation()` line 163-176: iterate $booleans array | Each field checked via `$this->has($field)` |
| 3 | Line 171-175: `$this->merge([$field => 0])` | All 16 fields merged as 0 |
| 4 | Validation: boolean rule receives 0 | Passes (0 is valid boolean) |

### BC-BIZ-DEEP-08: prepareForValidation Auto-Fill When Failed (Edge Case)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST with `inspection_status='Failed'`, `any_issues_found` absent | No issues field |
| 2 | Line 179: `$this->input('inspection_status') === 'Failed'` | true |
| 3 | Line 179: `!$this->has('any_issues_found')` | true (not present) |
| 4 | Line 180-182: `$this->merge(['any_issues_found' => 1])` | Auto-set to 1 |
| 5 | Conditional validation `any_issues_found => required|boolean` passes | Field now 1 |

### BC-BIZ-DEEP-09: Request authorize() Authorization Flow

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `TptDailyVehicleInspectionRequest.php:14-19` | `authorize()` method |
| 2 | POST request → `$this->isMethod('POST')` = true | `Gate::allows('tenant.daily-vehicle-inspection.create')` |
| 3 | PUT/PATCH request → `isMethod('POST')` = false | `Gate::allows('tenant.daily-vehicle-inspection.update')` |
| 4 | Any other method → falls to update check | Conservative default |

### BC-BIZ-DEEP-17: dailyInspectionQuery Search — Empty String Edge Case

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `VehicleMgmtController.php:72-84` | Search block |
| 2 | Submit search with empty string: `search_inspection = ''` | `$request->filled('search_inspection')` = false (empty string NOT filled) |
| 3 | No search filter applied | All results returned |
| 4 | Submit search with whitespace: `search_inspection = ' '` | `filled()` returns true for whitespace string |
| 5 | LIKE '% %' matches many records | Unexpected broad results |

### BC-BIZ-DEEP-22 vs BC-BIZ-DEEP-23: create() vs edit() Vehicle Filtering Difference

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Vehicle with `availability_status=false, is_active=true` | Unavailable but active |
| 2 | Navigate to `create()` | Vehicle NOT in dropdown (`availability_status=true` filter) |
| 3 | Navigate to `edit()` | Vehicle IS in dropdown (`active()` scope = is_active, not availability_status) |
| 4 | **Inconsistency**: Create hides unavailable; Edit shows them | create() uses `availability_status`, edit() uses `is_active` |

### BC-BIZ-DEEP-29: Activity Log Uses `Auth::user()->name` vs ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open store() line 76 | `'performed_by' => Auth::user()->name` |
| 2 | Open update() line 143 | Same: `Auth::user()->name` |
| 3 | Check other controllers in the module | Some may use `Auth::id()` or `Auth::user()->id` |
| 4 | **Note**: Username can change (user edits profile) | Audit trail becomes inaccurate if name changes |

### BC-BIZ-DEEP-30: Flash Message Keys vs Hardcoded Strings

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open store() line 80-81 | `flash('created.dailyvehicleInspection')` |
| 2 | Open update() line 147-148 | `flash('updated.dailyvehicleInspection')` |
| 3 | Open destroy() line 166-167 | `flash('trashed.dailyvehicleInspection')` |
| 4 | Open restore() line 199-200 | `flash('restored.dailyvehicleInspection')` |
| 5 | Open forceDelete() line 219-220 | `flash('force_deleted.dailyvehicleInspection')` |
| 6 | **Consistent**: All use `flash()` helper | Translatable key pattern (unlike PickupStopsList which uses hardcoded strings) |

### BC-BIZ-DEEP-35: VehicleMgmt getDetailedPendingData — 4 Pending Counts

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `VehicleMgmtController.php:318-345` | `getDetailedPendingData()` |
| 2 | `vehicle_fuel`: `TptVehicleFuel::pending()->take(10)->get()` | Fuel with pending status |
| 3 | `daily_inspection`: `TptDailyVehicleInspection::pending()->with(['vehicle','driver'])->take(10)->get()` | Pending inspections |
| 4 | `service_request`: `TptVehicleServiceRequest::pending()->take(10)->get()` | Pending service requests |
| 5 | `vehicle_maintenance`: `TptVehicleMaintenance::where('status','Pending')->take(10)->get()` | Pending maintenance |

### BC-BIZ-DEEP-40: Migration inspected_by Column + FK

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open migration lines 47-48 | `$table->unsignedInteger('inspected_by')->nullable(); $table->foreign('inspected_by', 'fk_dvil_inspectedBy')->references('id')->on('sys_users')->onDelete('set null');` |
| 2 | inspected_by is nullable | Not required |
| 3 | ON DELETE SET NULL | Deleting user sets field to null |
| 4 | No `inspected_by` in $fillable? | Check model: line 55 has `'inspected_by'` in fillable |

### BC-BIZ-DEEP-41: DDL Enum Order — Failed First

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open migration line 37 | `$table->enum('inspection_status', ['Failed', 'Passed', 'Pending'])->default('Pending');` |
| 2 | Enum values: Failed first, then Passed, then Pending | Unusual ordering |
| 3 | Default: 'Pending' | Matches model default |
| 4 | **Note**: Enum order matters for MySQL internal storage | No functional impact |

### BC-BIZ-DEEP-42: No `deleted_by` Column

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Search DDL for `deleted_by` | NOT present |
| 2 | Soft delete logs via activityLog only | No `deleted_by` column in table |
| 3 | Who deleted? Tracked via activityLog operation='Trashed' | Audit trail only in activity_log table |

### BC-BIZ-DEEP-44: Vehicle Model HasMany Inspections

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `Vehicle.php:60-63` | `public function inspections() { return $this->hasMany(TptDailyVehicleInspection::class, 'vehicle_id'); }` |
| 2 | `$vehicle->inspections` eager loads all inspections for vehicle | Relationship available |
| 3 | **Note**: Not used in InspectionController | Used in Vehicle context |

### BC-BIZ-DEEP-46: Activity Log Event Types — 6 Total

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Count activityLog calls in controller | 6 calls: store(1), update(1), destroy(1), restore(1), forceDelete(1), updateStatus(1) |
| 2 | Operation values: Created, Updated, Trashed, Restored, ForceDeleted, StatusUpdated | 6 distinct operations |
| 3 | Each has unique message format | Consistent pattern |

### BC-BIZ-DEEP-47: Destroy Does NOT Set is_active (No Such Column)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open destroy() line 157-158 | `$inspection->delete()` directly |
| 2 | No `is_active` toggle before delete | Correct because column doesn't exist |
| 3 | Compare with other entities that have `is_active` + `deleted_at` | Inspection uses only `deleted_at` |

### BC-BIZ-DEEP-52: dailyInspectionQuery Returns Builder — Paginated at Caller

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `VehicleMgmtController.php:67-92` | `dailyInspectionQuery()` returns `$query` |
| 2 | Line 44: `$this->dailyInspectionQuery($request)->paginate(10)->withQueryString()` | Pagination applied at caller |
| 3 | **Design**: Query method is reusable | Can be used with get(), paginate(), etc. |

### BC-BIZ-DEEP-54: Seeder Omits Inspection Records

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `TransportModuleSeeder.php:31-378` | Full seeder |
| 2 | Search for `TptDailyVehicleInspection::create` | NOT found |
| 3 | Only line 41: `DB::table('tpt_daily_vehicle_inspection')->delete()` | Clears but doesn't seed |
| 4 | **Impact**: Inspection tab shows empty after seeding | Manual creation required for testing |

### CODE-TRACE-01: Controller Method Flow — store()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `Gate::authorize('tenant.daily-vehicle-inspection.create')` | Permission check |
| 2 | `TptDailyVehicleInspection::create($request->validated())` | Model creation via mass assignment |
| 3 | `if ($inspection->inspection_status === 'Failed')` | Conditional side-effect block |
| 4 | `TptVehicleServiceRequest::where('vehicle_inspection_id', $id)->delete()` | Cleanup old SRs |
| 5 | `TptVehicleServiceRequest::create([...])` | Create new SR |
| 6 | `Vehicle::where('id', $vehicle_id)->update(['availability_status' => false])` | Mark vehicle unavailable |
| 7 | `activityLog($inspection, 'Created', [...])` | Audit log |
| 8 | `redirect()->route('transport.vehicle-mgmt.index')->with('success', flash(...))` | Response |

### CODE-TRACE-02: Controller Method Flow — update()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `Gate::authorize('tenant.daily-vehicle-inspection.update')` | Permission check |
| 2 | `TptDailyVehicleInspection::findOrFail($id)` | Fetch with 404 |
| 3 | `$original = $inspection->getOriginal()` | Snapshot before changes |
| 4 | `$inspection->update($request->validated())` | Update record |
| 5 | `foreach ($inspection->getChanges() as $field => $newValue)` | Build changes array |
| 6 | `if ($field === 'updated_at') { continue; }` | Exclude timestamp |
| 7 | `activityLog($inspection, 'Updated', ['changes' => $changes ?? null])` | Audit log |
| 8 | `redirect()->route('transport.vehicle-mgmt.index')->with('success', flash(...))` | Response |

### CODE-TRACE-03: Controller Method Flow — destroy()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `Gate::authorize('tenant.daily-vehicle-inspection.delete')` | Permission check |
| 2 | `TptDailyVehicleInspection::where('id',$id)->first()` | Fetch (may return null — BUG) |
| 3 | `$inspection->delete()` | Soft delete (crashes if null) |
| 4 | `activityLog($inspection, 'Trashed', [...])` | Audit log |
| 5 | Redirect with success | Response |

### CODE-TRACE-04: Controller Method Flow — updateStatus()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `Gate::authorize('tenant.daily-vehicle-inspection.approve')` | Permission check |
| 2 | `TptDailyVehicleInspection::where('id',$id)->first()` | Fetch (may return null) |
| 3 | `$inspection->status = $request->status` | Set non-existent attribute (BUG) |
| 4 | `$inspection->save()` | Save (status not persisted to DB) |
| 5 | `activityLog($inspection, 'StatusUpdated', [...])` | Audit log |
| 6 | `return response()->json([...])` | JSON response |

### CODE-TRACE-05: Validation Flow — prepareForValidation() + rules()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Request hits `TptDailyVehicleInspectionRequest` | FormRequest handling |
| 2 | `prepareForValidation()` runs FIRST | Before validation rules |
| 3 | Iterate 16 boolean fields: convert to 1/0, default missing to 0 | All booleans normalized |
| 4 | Check Failed auto-fill: set any_issues_found=1 if Failed+missing | Auto-set |
| 5 | `rules()` method returns validation rules array | Dynamic rules |
| 6 | If `inspection_status === 'Failed'` conditional added | issues_description=required |
| 7 | `messages()` provides custom error messages | User-friendly errors |
| 8 | `attributes()` provides field-name replacements | Error: "inspection status" not "inspection_status" |
| 9 | `authorize()` checks permission | Gate check |

### CODE-TRACE-06: VehicleMgmtController — 5-Tab Data Loading

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | GET `/vehicle-mgmt` | `VehicleMgmtController@index()` |
| 2 | `Gate::authorize('tenant.transport.viewAny')` | Master permission |
| 3 | `Vehicle::all()`, `DriverHelper::all()` | Master data |
| 4 | 5 paginated queries: vehicles, routes, driverHelpers, shifts, fuelEntries, dailyInspectionEntries, serviceRequests, maintenanceEntries | 8 datasets loaded |
| 5 | `$this->dailyInspectionQuery($request)->paginate(10)->withQueryString()` | Inspection specific |
| 6 | `$this->getDetailedPendingData()` | Pending counts for dashboard |
| 7 | View receives 14 compact variables | Full data |

### CODE-TRACE-07: Standalone vs Tab — Variable Differences

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Standalone `/daily-vehicle-inspection` controller index() | Only `$inspections` passed |
| 2 | Tab `/vehicle-mgmt` via dailyInspectionQuery | `$dailyInspectionEntries` passed |
| 3 | Different variable names: `$inspections` vs `$dailyInspectionEntries` | View must use correct name per context |
| 4 | Tab passes `$all_vehicles`, `$all_drivers` | Standalone does NOT |
| 5 | Shared blade must handle both contexts | Conditional `@isset($all_vehicles)` wrapping |

### CODE-TRACE-08: Seeder Cleanup Order — FK Constraints

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `TransportModuleSeeder.php:37-53` | FK-safe delete block |
| 2 | `Schema::disableForeignKeyConstraints()` | Temporarily disable FK checks |
| 3 | Delete inspection table FIRST (before vehicle) | FK `fk_dvil_vehicle` doesn't block |
| 4 | Delete vehicle table LAST | Dependent tables emptied first |
| 5 | `Schema::enableForeignKeyConstraints()` | Re-enable FK checks |

### CODE-TRACE-09: Route Definitions — web.php

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Resource route: `Route::resource('daily-vehicle-inspection', TptDailyVehicleInspectionController::class)` | 7 standard routes |
| 2 | `Route::get('daily-vehicle-inspection/trash/view', [..., 'trashed'])` | Trash listing |
| 3 | `Route::get('daily-vehicle-inspection/{id}/restore', [..., 'restore'])` | Restore |
| 4 | `Route::delete('daily-vehicle-inspection/{id}/force-delete', [..., 'forceDelete'])` | Force delete |
| 5 | `Route::post('daily-vehicle-inspection/{id}/update-status', [..., 'updateStatus'])` | Status update |

### CODE-TRACE-10: Service Request Auto-Creation — Full Sub-Flow

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `TptVehicleServiceRequest::where('vehicle_inspection_id', $inspection->id)->delete()` | Deletes old entries for same inspection |
| 2 | `TptVehicleServiceRequest::create(['vehicle_inspection_id' => $inspection->id, 'request_date' => now(), 'reason' => $inspection->issues_description ?? 'Automatic request generated due to failed inspection.', 'vehicle_status' => null, 'request_approval_status' => 'Pending'])` | New SR created |
| 3 | `Vehicle::where('id', $inspection->vehicle_id)->update(['availability_status' => false])` | Vehicle flagged unavailable |
| 4 | Note: `vehicle_status` set to null explicitly | Can be filled later by approval workflow |
| 5 | Note: No `vehicle_id` on service request | Vehicle identified through inspection relationship |

### CODE-TRACE-11: Daily Inspection Table Columns vs Blade Columns

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | DDL columns: inspection_date, odometer_reading, fuel_level_reading, 15 conditions, any_issues_found, issues_description, remarks, inspection_status, inspected_at | 29 columns total |
| 2 | Likely blade columns: Vehicle (reg_no), Driver (name), Date, Odometer, Fuel, Conditions, Issues, Status, Action | ~9 visible columns |
| 3 | Conditions column likely shows summary: "12/15 OK" | Not individual checkboxes |
| 4 | Status column shows badge: Passed (green), Failed (red), Pending (yellow) | Color-coded |

### CODE-TRACE-12: Blade Permission Gates for Column Visibility

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `@can('tenant.daily-vehicle-inspection.status')` wraps status `<th>`/`<td>` | Status column hidden without permission |
| 2 | `@can('tenant.daily-vehicle-inspection.edit')` wraps action column | Edit/delete buttons hidden without permission |
| 3 | Users without status permission see no status column | Clean UI |
| 4 | Users without edit permission see table without action buttons | View-only mode |

---

*Template: tpt_PickupStopsList_TcList.md (Syllabus depth) | Entity: Inspection | Date: 2026-07-21*
