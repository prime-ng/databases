# Staff (Personnel) — TC_List

---

## 1. Feature Information

| Attribute | Details |
|-----------|---------|
| **Module** | Transport (TPT) |
| **Tab Group** | Transport Master → Staff |
| **Entity** | Staff / Personnel (`tpt_personnel`) |
| **Controller** | `Modules\Transport\Http\Controllers\DriverHelperController` — 12 methods — ⚠️ `index()` NOT called for tab listing; standalone route only |
| **Tab Container Controller** | `Modules\Transport\Http\Controllers\TransportMasterController@index()` — tab id `staff`, private `driverHelpersQuery()` for listing |
| **Model** | `Modules\Transport\Models\DriverHelper` — SoftDeletes, InteractsWithMedia, 6 relationships, 32 fillable fields, 15 casts, 7 default attributes |
| **Form Request** | `Modules\Transport\Http\Requests\DriverHelperRequest` — 13 validation rules + `withValidator` (3 custom checks) + `prepareForValidation` (boolean normalization) |
| **Policy** | `Modules\Transport\Policies\DriverHelperPolicy` — 11 permission methods (viewAny, view, status, create, update, delete, restore, forceDelete, import, export, print) |
| **Route Prefix** | `transport.driver-helper.*` (resource) + named: trashed, restore, forceDelete, toggleStatus, print-id-card |
| **Blade Views** | `driver_helper/index.blade.php` (tab), `create`, `edit`, `show`, `trash` |
| **Tab Container** | `transportmaster.blade.php` — tab id `staff`, permission `tenant.driver-helper.viewAny` |
| **DB Table** | `tpt_personnel` — 18 data columns + 3 timestamps (created_at, updated_at, deleted_at) |
| **Media Library** | 5 single-file collections (`personnel_photo`, `id_card_document`, `driving_license`, `police_verification_certificate`, `address_proof_document`) + 3 image conversions (small 100x100, medium 250x250, large 500x500, sharpen 10) |
| **Unique Features** | Auto-generated personnel code (`PER-YYYYMMDD-NNN`), custom after-validation (inactive+vehicle conflict, vehicle role conflict, user re-assignment conflict), ID card printing via TemplateEngine, soft-delete with is_active=false first |

---

## 2. Pre-conditions

| # | Pre-condition | Source |
|---|--------------|--------|
| PC-01 | User must be logged in with `tenant.driver-helper.*` permissions | Policy-based |
| PC-02 | `tpt_personnel` table must exist with all columns + FKs to `sys_users` (ON DELETE SET NULL) and `tpt_vehicle` (ON DELETE SET NULL) | DDL migration |
| PC-03 | `tpt_vehicle` must have active vehicles for assignment dropdown | `Vehicle::where('is_active', 1)->get()` in `create()` |
| PC-04 | `Employee` records with Transport department (`LOWER(name) LIKE '%transport%'`) for user linking | `DriverHelperController.php:42-46` |
| PC-05 | `Employee` has `employeeProfiles.department` or `teacherProfiles.department` relationship | `whereHas` clause |
| PC-06 | `TemplatePurpose` with code `TRANSPORT_STAFF_ID_CARD` + active template assignment for ID card print | `printIdCard()` lines 320-324 |
| PC-07 | Spatie MediaLibrary tables must exist for document uploads | `InteractsWithMedia` trait |
| PC-08 | `DriverHelperController` registered in routes with all 12 routes (7 resource + 5 named: trashed, restore, forceDelete, toggleStatus, print-id-card) | `routes/web.php:89-96` |
| PC-09 | `DriverHelperPolicy` registered in `AuthServiceProvider` | Policy registration |
| PC-10 | `TemplateEngine` service class must be available for ID card rendering | `Modules\Template\Services\TemplateEngine` |
| PC-11 | `activityLog()` helper function must be available globally | Helper function in global scope |
| PC-12 | Tenant context must be active for multi-tenant permission checks | Permissions prefixed `tenant.*` |

---

## 3. Default Data Load

| # | Data Load Rule | Details | Source |
|---|----------------|---------|--------|
| DL-01 | Personnel listing: `DriverHelper::with(['vehicle', 'user'])->paginate(10)` | Eager loads vehicle + user, 10 per page | `DriverHelperController.php:28` |
| DL-02 | List columns: **Name**, **Phone**, **Role**, **License No**, **Valid Upto** (with Expired badge), **Assigned Vehicle**, **User**, **Status**, **Action** | `driver_helper/index.blade.php:31-41` |
| DL-03 | Vehicle display via `$driverHelper->vehicle?->vehicle_no ?? 'Not Assigned'` | Null-safe operator | `driver_helper/index.blade.php:62` |
| DL-04 | User display via `$driverHelper->user?->name ?? 'N/A'` | Null-safe operator | `driver_helper/index.blade.php:63` |
| DL-05 | License expiry badge: red "Expired" if `license_valid_upto < now()` | `driver_helper/index.blade.php:54-56` |
| DL-06 | Search: Name, Role, Phone, License No | `driver_helper/index.blade.php:8` |
| DL-07 | Action column: `@canany(['tenant.driver-helper.edit', 'tenant.driver-helper.delete'])` | `driver_helper/index.blade.php:39,67` |
| DL-08 | Create/Edit form: loads active vehicles + Transport-department users | `DriverHelperController.php:40-50,135-145` |
| DL-09 | Personnel code auto-generated: `PER-YYYYMMDD-NNN` with `lockForUpdate()` | `DriverHelperController.php:65-71` |
| DL-10 | Trash list: `DriverHelper::onlyTrashed()->with(['vehicle','user'])->paginate(10)` | Soft-deleted only | `DriverHelperController.php:236-238` |
| DL-11 | Create form: `Vehicle::where('is_active', 1)->get()` | Only active vehicles | `DriverHelperController.php:40` |
| DL-12 | Create form: Users filtered by Transport-department employees | `DriverHelperController.php:42-50` |
| DL-13 | Trash actions column: `@canany(['tenant.driver-helper.restore', 'tenant.driver-helper.forceDelete'])` | `driver_helper/trash.blade.php:25,67` |

---

## 4. Test Data Strategy

| # | Data Strategy | Details |
|---|---------------|---------|
| TD-01 | **Valid Driver** | name="Rajesh Kumar", role="Driver", id_card_type="QR", id_type="Aadhaar Card", id_no="1234-5678-9012", license_no="DL-123456", license_valid_upto=future date, assigned_vehicle_id=valid active vehicle, driving_exp_months=60, address="123, MG Road, Bangalore", police_verification_done=true, is_active=true, 5 upload files |
| TD-02 | **Valid Helper** | name="Suresh", role="Helper", no license fields (null), no vehicle, is_active=true |
| TD-03 | **Valid Both** | name="Amit", role="Both", license_no="DL-789012", license_valid_upto=future, with vehicle |
| TD-04 | **Duplicate License** | Two drivers with same license_no — unique constraint violation |
| TD-05 | **Expired License** | license_valid_upto = past date — "after:today" validation fails |
| TD-06 | **Inactive + Vehicle Conflict** | is_active=false + assigned_vehicle_id set — custom validation error |
| TD-07 | **Vehicle Role Conflict** | Assign two active drivers with same role to same vehicle — custom validation error |
| TD-08 | **User Re-assignment Conflict** | User already linked to another vehicle — custom validation error |
| TD-09 | **5 Document Uploads** | Upload photo, id_card, driving_license, police_verification_certificate, address_proof_document |
| TD-10 | **Soft-Deleted License Reuse** | Soft-delete driver, create new with same license_no — allowed (unique ignores soft-deleted) |
| TD-11 | **All ID Types** | id_type ∈ {Aadhaar Card, Licence Number, PAN Card, Voter ID, Passport} |
| TD-12 | **All ID Card Types** | id_card_type ∈ {QR, RFID, NFC, Barcode} |
| TD-13 | **Force-deleted License Reuse** | Force-delete driver, create new with same license_no — allowed |
| TD-14 | **Missing Employee Records** | No Transport-department employees — user dropdown renders empty |

---

## 5. Business Conditions (BC)

### BC-DB: Database Conditions — `tpt_personnel`

| BC ID | Column | Type (DDL) | Constraints | Source |
|-------|--------|------------|-------------|--------|
| BC-DB-01 | `id` | BIGINT UNSIGNED AUTO_INCREMENT | PK | DDL line 47 |
| BC-DB-02 | `user_qr_code` | VARCHAR(30) | NOT NULL | DDL line 52 |
| BC-DB-03 | `id_card_type` | ENUM('QR','RFID','NFC','Barcode') | NOT NULL, DEFAULT 'QR' | DDL line 53 |
| BC-DB-04 | `name` | VARCHAR(100) | NOT NULL | DDL line 54 |
| BC-DB-05 | `phone` | VARCHAR(20) | NULLABLE | DDL line 55 |
| BC-DB-06 | `id_type` | VARCHAR(50) | NULLABLE | DDL line 56 |
| BC-DB-07 | `id_no` | VARCHAR(50) | NULLABLE | DDL line 57 |
| BC-DB-08 | `role` | VARCHAR(20) | NOT NULL (Driver/Helper/Both) | DDL line 58 |
| BC-DB-09 | `license_no` | VARCHAR(50) | UNIQUE, NULLABLE | DDL line 59 |
| BC-DB-10 | `license_valid_upto` | DATE | NULLABLE | DDL line 60 |
| BC-DB-11 | `assigned_vehicle_id` | BIGINT UNSIGNED | FK → `tpt_vehicle.id` ON DELETE SET NULL, NULLABLE | DDL line 61,75 |
| BC-DB-12 | `driving_exp_months` | INT | NULLABLE | DDL line 62 |
| BC-DB-13 | `police_verification_done` | TINYINT(1) | DEFAULT 0 | DDL line 63 |
| BC-DB-14 | `address` | TEXT | NULLABLE | DDL line 64 |
| BC-DB-15 | `photo_upload` | TINYINT(1) | DEFAULT 0 | DDL line 65 |
| BC-DB-16 | `id_card_upload` | TINYINT(1) | DEFAULT 0 | DDL line 66 |
| BC-DB-17 | `driving_license_upload` | TINYINT(1) | DEFAULT 0 | DDL line 67 |
| BC-DB-18 | `police_verification_upload` | TINYINT(1) | DEFAULT 0 | DDL line 68 |
| BC-DB-19 | `address_proof_upload` | TINYINT(1) | DEFAULT 0 | DDL line 69 |
| BC-DB-20 | `is_active` | TINYINT(1) | DEFAULT 1 | DDL line 70 |
| BC-DB-21 | `user_id` | BIGINT UNSIGNED | FK → `sys_users.id` ON DELETE SET NULL, NULLABLE | DDL line 51,74 |
| BC-DB-22 | `created_at` | TIMESTAMP NULL | NULLABLE | DDL line 71 |
| BC-DB-23 | `updated_at` | TIMESTAMP NULL | NULLABLE | DDL line 72 |
| BC-DB-24 | `deleted_at` | TIMESTAMP NULL | NULLABLE (SoftDeletes) | DDL line 73 |

### BC-VAL: Validation Conditions — `DriverHelperRequest`

| BC ID | Field | Rule | Details | Source |
|-------|-------|------|---------|--------|
| BC-VAL-01 | `name` | required, string, max:80 | `required\|string\|max:80` | `DriverHelperRequest.php:35` |
| BC-VAL-02 | `phone` | nullable, string, max:20 | `nullable\|string\|max:20` | `DriverHelperRequest.php:37-41` |
| BC-VAL-03 | `role` | required, in: Driver/Helper/Both | `Rule::in(['Driver','Helper','Both'])` using Model const | `DriverHelperRequest.php:43-46` |
| BC-VAL-04 | `id_card_type` | required, in: QR/RFID/NFC/Barcode | `Rule::in(['QR','RFID','NFC','Barcode'])` | `DriverHelperRequest.php:48-51` |
| BC-VAL-05 | `id_type` | nullable, in: ID_TYPES constants | `Rule::in(DriverHelper::ID_TYPES)` — 5 types | `DriverHelperRequest.php:53-56` |
| BC-VAL-06 | `id_no` | nullable, string, max:50 | `nullable\|string\|max:50` | `DriverHelperRequest.php:58-62` |
| BC-VAL-07 | `license_no` | requiredIf role=Driver/Both, nullable, string, max:50, unique ignoring soft-deleted | `Rule::requiredIf(...)`, `Rule::unique('tpt_personnel')->whereNull('deleted_at')` | `DriverHelperRequest.php:65-73` |
| BC-VAL-08 | `license_valid_upto` | requiredIf role=Driver/Both, nullable, date, after:today | `Rule::requiredIf(...)`, `date`, `after:today` | `DriverHelperRequest.php:75-80` |
| BC-VAL-09 | `assigned_vehicle_id` | nullable, integer, exists:tpt_vehicle,id | `nullable\|integer\|exists:tpt_vehicle,id` | `DriverHelperRequest.php:83-87` |
| BC-VAL-10 | `driving_exp_months` | nullable, integer, min:0, max:600 | `nullable\|integer\|min:0\|max:600` | `DriverHelperRequest.php:89-94` |
| BC-VAL-11 | `address` | nullable, string, max:512 | `nullable\|string\|max:512` | `DriverHelperRequest.php:96-100` |
| BC-VAL-12 | `user_id` | nullable, exists:sys_users,id | `nullable\|exists:sys_users,id` | `DriverHelperRequest.php:102-105` |
| BC-VAL-13 | `is_active` | required, boolean (normalized via prepareForValidation) | `required\|boolean`, `$this->boolean('is_active')` | `DriverHelperRequest.php:107,112-115` |

### BC-VAL-CUSTOM: Custom After-Validations (`withValidator`)

| BC ID | Condition | Error Message | Fields | Source |
|-------|-----------|---------------|-------|--------|
| BC-VAL-C01 | `is_active=false` AND `assigned_vehicle_id` is set | "Inactive personnel cannot be assigned" | `assigned_vehicle_id` | `DriverHelperRequest.php:125-130` |
| BC-VAL-C02 | Same `assigned_vehicle_id` + same `role` on another active, non-deleted record | "Vehicle already has an active {Role}" | `assigned_vehicle_id` | `DriverHelperRequest.php:133-147` |
| BC-VAL-C03 | `user_id` already linked to a DIFFERENT `assigned_vehicle_id` on another active record | "This personnel is already assigned to another vehicle" | `assigned_vehicle_id` | `DriverHelperRequest.php:150-165` |

### BC-AUTH: Authorization Conditions

| BC ID | Permission | Controller Method | Source |
|-------|-----------|-------------------|--------|
| BC-AUTH-01 | `tenant.driver-helper.viewAny` | `index()` | `DriverHelperController.php:26` |
| BC-AUTH-02 | `tenant.driver-helper.view` | `show()`, `printIdCard()` | `DriverHelperController.php:120,317` |
| BC-AUTH-03 | `tenant.driver-helper.create` | `create()`, `store()` | `DriverHelperController.php:38,60` |
| BC-AUTH-04 | `tenant.driver-helper.update` | `edit()`, `update()`, `toggleStatus()` | `DriverHelperController.php:132,159,297` |
| BC-AUTH-05 | `tenant.driver-helper.delete` | `destroy()` | `DriverHelperController.php:215` |
| BC-AUTH-06 | `tenant.driver-helper.restore` | `trashed()`, `restore()` | `DriverHelperController.php:234,248` |
| BC-AUTH-07 | `tenant.driver-helper.forceDelete` | `forceDelete()` | `DriverHelperController.php:267` |
| BC-AUTH-08 | `tenant.driver-helper.create` | `DriverHelperRequest@authorize()` when POST | `DriverHelperRequest.php:15-16` |
| BC-AUTH-09 | `tenant.driver-helper.update` | `DriverHelperRequest@authorize()` when NOT POST | `DriverHelperRequest.php:18` |
| BC-AUTH-10 | `tenant.driver-helper.status` | Policy method defined but NOT used in controller | `DriverHelperPolicy.php:26-29` (UNTESTED code path) |
| BC-AUTH-11 | `tenant.driver-helper.import` | Policy method defined but NOT used in controller | `DriverHelperPolicy.php:73-76` (UNTESTED code path) |
| BC-AUTH-12 | `tenant.driver-helper.export` | Policy method defined but NOT used in controller | `DriverHelperPolicy.php:81-84` (UNTESTED code path) |
| BC-AUTH-13 | `tenant.driver-helper.print` | Policy method defined but NOT used in controller (`printIdCard` uses `view` instead) | `DriverHelperPolicy.php:89-92` (UNTESTED code path) |

### BC-BIZ: Business Conditions

| BC ID | Condition | Expected | Source |
|-------|-----------|----------|--------|
| BC-BIZ-01 | Personnel code auto-generated with daily counter | `PER-YYYYMMDD-NNN`, locked via `lockForUpdate()` in transaction | `DriverHelperController.php:65-71` |
| BC-BIZ-02 | Delete sets `is_active=false` then soft-deletes | `$driverHelper->update(['is_active'=>false]); $driverHelper->delete()` | `DriverHelperController.php:217-218` |
| BC-BIZ-03 | Store: upload status flags set to `true` if file present | `'photo_upload' => $request->hasFile('photo_upload')` — 5 flags | `DriverHelperController.php:81-86` |
| BC-BIZ-04 | Store: media mapping 5 form fields → 5 collections | `photo_upload→personnel_photo`, `id_card_upload→id_card_document`, `driving_license_upload→driving_license`, `police_verification_upload→police_verification_certificate`, `address_proof_upload→address_proof_document` | `DriverHelperController.php:89-95` |
| BC-BIZ-05 | Update: old media cleared, new file added, flag updated to `true` | `clearMediaCollection()` + `addMediaFromRequest()` + `update([$flagField=>true])` | `DriverHelperController.php:177-185` |
| BC-BIZ-06 | Force delete: all 5 media collections cleared before delete | Loop over collection names → `clearMediaCollection()` | `DriverHelperController.php:271-279` |
| BC-BIZ-07 | ID card printing via `TemplateEngine::render('TRANSPORT_STAFF_ID_CARD')` | Template assignment must be active, abort(404) if missing | `DriverHelperController.php:315-333` |
| BC-BIZ-08 | Store wrapped in `DB::transaction()` | Code generation + create + media upload + activityLog in atomic transaction | `DriverHelperController.php:62-108` |
| BC-BIZ-09 | `police_verification_done` normalized via `$request->boolean()` | Converts string "1"/"0"/"on"/"true" to boolean | `DriverHelperController.php:78,165` |
| BC-BIZ-10 | `update()` captures original values before save for change tracking | `$original = $driverHelper->getOriginal()` then compares `getChanges()` | `DriverHelperController.php:161,190-196` |
| BC-BIZ-11 | Update change tracking excludes `updated_at` from log | `if ($field !== 'updated_at')` | `DriverHelperController.php:191` |
| BC-BIZ-12 | Activity log includes `performed_by` in update | `'performed_by' => Auth::user()->name` | `DriverHelperController.php:202` |
| BC-BIZ-13 | `restore()` does NOT revert `is_active` to true | Record stays inactive after restore | `DriverHelperController.php:246-259` |
| BC-BIZ-14 | `forceDelete()` uses `withTrashed()` (correct — can force-delete active or trashed) | `DriverHelper::withTrashed()->findOrFail($id)` | `DriverHelperController.php:269` |
| BC-BIZ-15 | `restore()` uses `onlyTrashed()` (correct — only restore trashed) | `DriverHelper::onlyTrashed()->findOrFail($id)` | `DriverHelperController.php:250` |
| BC-BIZ-16 | `toggleStatus()` uses inline `$request->validate()` NOT FormRequest | `$request->validate(['is_active' => 'required|boolean'])` | `DriverHelperController.php:299-301` |
| BC-BIZ-17 | `toggleStatus()` returns JSON response | `response()->json(['success'=>true, 'is_active'=>..., 'message'=>...])` | `DriverHelperController.php:305-309` |
| BC-BIZ-18 | `printIdCard()` renders student view (not staff-specific view) | `view('studentprofile::student.id-card')` with staff name | `DriverHelperController.php:329-332` |
| BC-BIZ-19 | `edit()` uses route-model-binding parameter `$id` (NOT implicit binding) | `edit($id)` then `DriverHelper::findOrFail($id)` | `DriverHelperController.php:130,134` |
| BC-BIZ-20 | `show()` same pattern: `show($id)` then `findOrFail($id)` | Manual ID parameter, explicit findOrFail | `DriverHelperController.php:118,122` |
| BC-BIZ-21 | `update()` uses route-model-binding `DriverHelper $driverHelper` (implicit) | Auto-resolved by Laravel | `DriverHelperController.php:157` |
| BC-BIZ-22 | `destroy()` uses route-model-binding `DriverHelper $driverHelper` (implicit) | Auto-resolved by Laravel | `DriverHelperController.php:213` |
| BC-BIZ-23 | `toggleStatus()` uses route-model-binding with `Request` as first param | `toggleStatus(Request $request, DriverHelper $driverHelper)` | `DriverHelperController.php:295` |

### BC-REL: Relationship Conditions

| BC ID | Relationship | Type | Foreign Key | Source |
|-------|-------------|------|-------------|--------|
| BC-REL-01 | DriverHelper → User | `belongsTo(User, user_id)` | `user_id` → `sys_users.id` | `DriverHelper.php:108-111` |
| BC-REL-02 | DriverHelper → Vehicle | `belongsTo(Vehicle, assigned_vehicle_id)` | `assigned_vehicle_id` → `tpt_vehicle.id` | `DriverHelper.php:114-117` |
| BC-REL-03 | DriverHelper → TptDriverAttendance (as driver) | `hasMany(TptDriverAttendance, driver_id)` | `id` → `tpt_driver_attendance.driver_id` | `DriverHelper.php:120-123` |
| BC-REL-04 | DriverHelper → TptTrip (as driver) | `hasMany(TptTrip, driver_id)` | `id` → `tpt_trip.driver_id` | `DriverHelper.php:126-129` |
| BC-REL-05 | DriverHelper → TptTrip (as helper) | `hasMany(TptTrip, helper_id)` | `id` → `tpt_trip.helper_id` | `DriverHelper.php:132-135` |
| BC-REL-06 | DriverHelper → TptTripIncidents (via driverTrips) | `hasManyThrough(TptTripIncidents, TptTrip, driver_id, trip_id, id, id)` | Through driverTrips | `DriverHelper.php:138-148` |

### BC-REF: Reference & UI Conditions

| BC ID | Condition | Expected | Source |
|-------|-----------|----------|--------|
| BC-REF-01 | Tab id `staff` in transportmaster, hidden input `tab=staff` | `driver_helper/index.blade.php:2,6` |
| BC-REF-02 | Search placeholder: "Search... Name,Role,Phone,License No" | `driver_helper/index.blade.php:8` |
| BC-REF-03 | License expiry badge shown conditionally in red | `driver_helper/index.blade.php:54-56` |
| BC-REF-04 | `driver-helper.print-id-card` route for ID card generation | `routes/web.php:96` |
| BC-REF-05 | Flash keys: `created.driver_helper`, `updated.driver_helper`, `trashed.driver_helper`, `restored.driver_helper`, `force_deleted.driver_helper`, `status_updated.driver_helper` | `DriverHelperController.php` |
| BC-REF-06 | Personnel code uses `lockForUpdate()` to prevent race conditions | `DriverHelperController.php:68` |
| BC-REF-07 | Show page has "Print ID Card" button linking to print-id-card route | `driver_helper/show.blade.php:67,152` |
| BC-REF-08 | Trash page has Restore + Force Delete buttons guarded by `@canany` | `driver_helper/trash.blade.php:25,67` |
| BC-REF-09 | Index page status toggle uses `<x-backend.table.status-switch>` component | Generic switch component |
| BC-REF-10 | ID card prints via `/transport/driver-helper/{id}/print-id-card` URL | New tab/window for printing |

### BC-BIZ-DEEP: Deep Business Conditions (Code-Level)

| BC ID | Condition | Expected Behavior | Source |
|-------|-----------|-------------------|--------|
| BC-BIZ-DEEP-01 | `store()` uses `$request->validated()` spread for mass assignment | `DriverHelper::create([...$request->validated(), ...overrides])` | `DriverHelperController.php:74-76` |
| BC-BIZ-DEEP-02 | `store()` overrides `police_verification_done` with `$request->boolean()` | Normalized boolean | `DriverHelperController.php:78` |
| BC-BIZ-DEEP-03 | `store()` sets upload flags via `$request->hasFile()` BEFORE media upload | DB record created first, media added after | `DriverHelperController.php:81-86` |
| BC-BIZ-DEEP-04 | `store()` media loop: `addMediaFromRequest` → `toMediaCollection` | Spatie Media Library attachment | `DriverHelperController.php:97-103` |
| BC-BIZ-DEEP-05 | `store()` activity log message: "Driver/Helper created successfully." | Activity stored via `activityLog()` helper | `DriverHelperController.php:105-107` |
| BC-BIZ-DEEP-06 | `store()` redirects to `transport.transport-master.index` (NOT driver-helper.index) | Tab-based navigation | `DriverHelperController.php:110-112` |
| BC-BIZ-DEEP-07 | `update()` override: `police_verification_done` via `$request->boolean()` | Same normalization as store | `DriverHelperController.php:165` |
| BC-BIZ-DEEP-08 | `update()` media loop: `clearMediaCollection` THEN `addMediaFromRequest` | Old file replaced per collection | `DriverHelperController.php:177-186` |
| BC-BIZ-DEEP-09 | `update()` uses `$formField` variable as both form field name AND DB flag column | `$flagField = $formField` (they match 1:1) | `DriverHelperController.php:183-184` |
| BC-BIZ-DEEP-10 | `update()` change tracking loops `getChanges()`, builds old/new array per field | Excludes `updated_at` | `DriverHelperController.php:190-197` |
| BC-BIZ-DEEP-11 | `update()` activity log message: "Driver/Helper updated." with changes | Includes diff | `DriverHelperController.php:199-203` |
| BC-BIZ-DEEP-12 | `destroy()` sets `is_active=false` before soft-delete | Two-step deactivation | `DriverHelperController.php:217-218` |
| BC-BIZ-DEEP-13 | `destroy()` activity log message: "Driver/Helper deactivated." | "Trashed" event type | `DriverHelperController.php:220-222` |
| BC-BIZ-DEEP-14 | `destroy()` redirects to `transport.transport-master.index` | Tab-based navigation | `DriverHelperController.php:224-226` |
| BC-BIZ-DEEP-15 | `trashed()` permission: `tenant.driver-helper.restore` (NOT viewAny) | Restore permission gates trash listing | `DriverHelperController.php:234` |
| BC-BIZ-DEEP-16 | `trashed()` query: `DriverHelper::onlyTrashed()->with(['vehicle','user'])->paginate(10)` | Same eager loading + pagination as index | `DriverHelperController.php:236-238` |
| BC-BIZ-DEEP-17 | `restore()` finds only trashed records | `onlyTrashed()` then `->restore()` | `DriverHelperController.php:250-251` |
| BC-BIZ-DEEP-18 | `restore()` does NOT set `is_active=true` | Restored record stays inactive | Code review: no `update(['is_active'=>true])` call |
| BC-BIZ-DEEP-19 | `restore()` redirects to `transport.driver-helper.trashed` | Returns to trash listing | `DriverHelperController.php:257-258` |
| BC-BIZ-DEEP-20 | `forceDelete()` uses `withTrashed()` (NOT `onlyTrashed()`) | Can force-delete BOTH active and trashed records | `DriverHelperController.php:269` |
| BC-BIZ-DEEP-21 | `forceDelete()` clears media using form field names as collection keys | BUT form field names do NOT match collection names — **POTENTIAL BUG** | `DriverHelperController.php:271-279` |
| BC-BIZ-DEEP-22 | `forceDelete()` media clear loop iterates: photo_upload, id_card_upload, driving_license_upload, police_verification_upload, address_proof_upload | These are FORM FIELD names, NOT collection names (personnel_photo, id_card_document, driving_license, etc.) | `DriverHelperController.php:271-279` |
| BC-BIZ-DEEP-23 | **GAP**: `forceDelete()` uses form field names (e.g. `photo_upload`) as collection identifiers in `clearMediaCollection()` | Should use collection names (`personnel_photo`). Spatie Media Library collections are registered as `personnel_photo` etc. — calling `clearMediaCollection('photo_upload')` does NOT match any registered collection | `DriverHelperController.php:271-279` vs `DriverHelper.php:173-177` |
| BC-BIZ-DEEP-24 | `forceDelete()` activity log: "Driver/Helper permanently deleted." | "Deleted" event type | `DriverHelperController.php:283-285` |
| BC-BIZ-DEEP-25 | `toggleStatus()` validates inline with `$request->validate()` | Does NOT use DriverHelperRequest | `DriverHelperController.php:299-301` |
| BC-BIZ-DEEP-26 | `toggleStatus()` updates using `$request->is_active` (NOT `$request->boolean()`) | Assumes value already boolean from validation | `DriverHelperController.php:303` |
| BC-BIZ-DEEP-27 | `toggleStatus()` returns JSON with `is_active` from refreshed model | `$driverHelper->is_active` after update | `DriverHelperController.php:305-309` |
| BC-BIZ-DEEP-28 | `toggleStatus()` does NOT call activityLog | Status changes not logged | Code review |
| BC-BIZ-DEEP-29 | `printIdCard()` does NOT use `activityLog()` | ID card print events not tracked | Code review |
| BC-BIZ-DEEP-30 | `printIdCard()` queries `TemplatePurpose::where('code', 'TRANSPORT_STAFF_ID_CARD')->first()` | Hardcoded purpose code | `DriverHelperController.php:320` |
| BC-BIZ-DEEP-31 | `printIdCard()` uses `->first()` not `->firstOrFail()` | Manual `abort(404)` if not found | `DriverHelperController.php:321` |
| BC-BIZ-DEEP-32 | `printIdCard()` checks `$assignment = $purpose->assignments()->where('is_active', true)->first()` | Active template assignment required | `DriverHelperController.php:323-324` |
| BC-BIZ-DEEP-33 | `printIdCard()` uses `TemplateEngine::render()` with 7 null params + 1 context param | `$engine->render('TRANSPORT_STAFF_ID_CARD', [], null, null, null, null, null, ['staff_id' => $staff->id])` | `DriverHelperController.php:327` |
| BC-BIZ-DEEP-34 | `printIdCard()` renders student profile ID card view, not staff-specific view | `view('studentprofile::student.id-card')` — reuses student view | `DriverHelperController.php:329-332` |
| BC-BIZ-DEEP-35 | `printIdCard()` creates anonymous object `(object)['full_name' => $staff->name]` | Staff name passed as student name to shared view | `DriverHelperController.php:330` |
| BC-BIZ-DEEP-36 | Model `$attributes` defaults: `is_active=true`, `police_verification_done=false`, all 5 upload flags=false | Defaults for new records | `DriverHelper.php:84-93` |
| BC-BIZ-DEEP-37 | Model `$casts`: `license_valid_upto` → `date`, all upload flags → `boolean`, `is_active` → `boolean` | Type casting | `DriverHelper.php:59-78` |
| BC-BIZ-DEEP-38 | Model `$fillable` includes ALL 19 columns (including upload flags) | Mass-assignable | `DriverHelper.php:23-54` |
| BC-BIZ-DEEP-39 | Model `scopeActive`: `where('is_active', true)` | Scope defined but NOT used in controller queries | `DriverHelper.php:98-101` |
| BC-BIZ-DEEP-40 | `registerMediaCollections()`: 5 single-file collections | One file per collection only | `DriverHelper.php:171-178` |
| BC-BIZ-DEEP-41 | `registerMediaConversions()`: 3 sizes with sharpen(10) | small(100x100), medium(250x250), large(500x500) | `DriverHelper.php:183-199` |
| BC-BIZ-DEEP-42 | `payee_mode` and `attachment` fields are NOT in model — incorrect mapping in file | DDL has `payee_mode` VARCHAR(20) and `attachment` VARCHAR(255) but NOT in $fillable | DDL vs model discrepancy |
| BC-BIZ-DEEP-43 | `DriverHelperRequest::getCurrentId()` handles both Model instances and scalar IDs | `$this->route('driver_helper') instanceof Model ? ...->id : ...` | `DriverHelperRequest.php:21-26` |
| BC-BIZ-DEEP-44 | `prepareForValidation()` normalizes `is_active` via `$this->boolean()` | Converts "on"/"1"/"true" to true, "0"/"false"/null to false | `DriverHelperRequest.php:112-115` |
| BC-BIZ-DEEP-45 | `DriverHelperRequest::authorize()` uses POST check for create vs update | `$this->isMethod('POST')` → create, else → update | `DriverHelperRequest.php:15-18` |
| BC-BIZ-DEEP-46 | License unique rule: `->whereNull('deleted_at')` allows soft-deleted duplicates | Soft-deleted records excluded from unique check | `DriverHelperRequest.php:70-72` |
| BC-BIZ-DEEP-47 | Vehicle role conflict check: same `assigned_vehicle_id` + same `role` + `is_active=1` + `deleted_at IS NULL` + `id != currentId` | Conflicts only with active, non-deleted records | `DriverHelperRequest.php:134-139` |
| BC-BIZ-DEEP-48 | User re-assignment check: same `user_id` + different `assigned_vehicle_id` + `is_active=1` + `deleted_at IS NULL` + `id != currentId` | Prevents user being assigned to two different vehicles | `DriverHelperRequest.php:150-157` |
| BC-BIZ-DEEP-49 | User re-assignment check requires BOTH `assigned_vehicle_id` AND `user_id` to be set | `if ($this->assigned_vehicle_id && $this->user_id)` — guard condition | `DriverHelperRequest.php:150` |
| BC-BIZ-DEEP-50 | User re-assignment check excludes records where `assigned_vehicle_id` IS NULL | `->whereNotNull('assigned_vehicle_id')` | `DriverHelperRequest.php:155` |
| BC-BIZ-DEEP-51 | Employee query uses TWO `whereHas` with OR: `employeeProfiles.department` OR `teacherProfiles.department` | Both profile types with Transport department | `DriverHelperController.php:42-46` |
| BC-BIZ-DEEP-52 | Employee query: `->pluck('user_id')->filter()->toArray()` | Filters out null user_ids, returns plain array | `DriverHelperController.php:46` |
| BC-BIZ-DEEP-53 | Users loaded: `User::where('is_active', true)->whereIn('id', $userIds)->get()` | Only active users with Transport dept | `DriverHelperController.php:48-50` |
| BC-BIZ-DEEP-54 | `index()` does NOT filter by `is_active` — shows active AND inactive | `DriverHelper::with(...)->paginate(10)` no whereActive call | `DriverHelperController.php:28` |
| BC-BIZ-DEEP-55 | `create()` loads ALL active vehicles (no department/type filter) | `Vehicle::where('is_active', 1)->get()` | `DriverHelperController.php:40` |
| BC-BIZ-DEEP-56 | Code generation: `$count = DriverHelper::whereDate('created_at', Carbon::today())->lockForUpdate()->count() + 1` | Race-condition safe daily counter | `DriverHelperController.php:67-69` |
| BC-BIZ-DEEP-57 | Code format: `'PER-' . $today . '-' . str_pad($count, 3, '0', STR_PAD_LEFT)` | Zero-padded 3-digit, e.g. PER-20260721-001 | `DriverHelperController.php:71` |
| BC-BIZ-DEEP-58 | Code generation runs INSIDE `DB::transaction()` | Atomic with record creation | `DriverHelperController.php:62-108` |
| BC-BIZ-DEEP-59 | Store redirect uses `flash('created.driver_helper')` — translation key pattern | Consistent with other Transport controllers | `DriverHelperController.php:112` |
| BC-BIZ-DEEP-60 | `printIdCard()` does NOT soft-delete or trashed-check — shows for active AND deleted | `DriverHelper::findOrFail($id)` — finds any record | `DriverHelperController.php:318` |

---

## 6. Test Case List

### TC-P: Positive Test Cases

| ID | Test Case | Summary | Expected Result |
|----|-----------|---------|-----------------|
| TC-P-01 | Create driver with all fields + 5 documents | Full driver record with all uploads | Created, auto-code PER-YYYYMMDD-NNN, 5 media collections, flags=true |
| TC-P-02 | Create helper (no license) | Role=Helper, no license fields | Created successfully, license fields null |
| TC-P-03 | Create "Both" role with license | Role=Both, all license fields required | Created successfully |
| TC-P-04 | Edit personnel name/phone | Change basic info | Updated, change tracking logs fields |
| TC-P-05 | Replace document on update | Upload new driving_license | Old media cleared, new uploaded, flag=true |
| TC-P-06 | Toggle status active→inactive | Click status switch | AJAX success, is_active flips |
| TC-P-07 | View personnel details | Click show | Show page with all fields, formatted dates, media |
| TC-P-08 | Print ID card | Click "Print ID Card" | Renders template via TemplateEngine |
| TC-P-09 | Restore soft-deleted personnel | Trash → Restore | Restored (inactive), flash restored |
| TC-P-10 | Search by name | Type partial name | Filtered results matching name |
| TC-P-11 | Create with all 5 ID types | id_type = Aadhaar/PAN/Voter/Passport/Licence | All accepted |
| TC-P-12 | Create with all 4 ID card types | id_card_type = QR/RFID/NFC/Barcode | All accepted |
| TC-P-13 | Create without phone/address | Optional fields empty | Created successfully, null stored |
| TC-P-14 | Create without vehicle assignment | assigned_vehicle_id=null | Created, null FK |
| TC-P-15 | Create without user linking | user_id=null | Created, null FK |
| TC-P-16 | Duplicate license after soft-delete | Delete driver, create new with same license | Allowed |
| TC-P-17 | View trashed personnel | Navigate to trash | Only soft-deleted records shown |
| TC-P-18 | Force delete trashed personnel | Permanently delete | Media cleared, record gone |
| TC-P-19 | Force delete active (non-trashed) personnel | Permanently delete active record | Works (uses withTrashed) |
| TC-P-20 | List pagination | 10+ records | Paginated at 10 per page |

### TC-N: Negative Test Cases

| ID | Test Case | Summary | Expected Result |
|----|-----------|---------|-----------------|
| TC-N-01 | Create with empty name | Submit without name | "The name field is required." |
| TC-N-02 | Create with invalid role | role="Supervisor" | "The selected role is invalid." |
| TC-N-03 | Create driver without license_no | role=Driver, no license | "The license no field is required." |
| TC-N-04 | Create driver with expired license date | license_valid_upto = past date | "The license valid upto must be a date after today." |
| TC-N-05 | Create with duplicate license_no | Same license as existing driver | "The license no has already been taken." |
| TC-N-06 | Assign vehicle to inactive personnel | is_active=false + vehicle | "Inactive personnel cannot be assigned" |
| TC-N-07 | Assign same vehicle+role to two drivers | Second driver, same vehicle, same role | "Vehicle already has an active Driver" |
| TC-N-08 | Link user already assigned to another vehicle | user_id already linked elsewhere with different vehicle | "This personnel is already assigned to another vehicle" |
| TC-N-09 | Access without permission | No tenant.driver-helper.* | 403 Access Denied |
| TC-N-10 | Create without create permission | No `tenant.driver-helper.create`, POST to store | `Gate::authorize()` throws 403 |
| TC-N-11 | Update without update permission | No `tenant.driver-helper.update`, PUT to update | `Gate::authorize()` throws 403 |
| TC-N-12 | Delete without delete permission | No `tenant.driver-helper.delete`, DELETE to destroy | `Gate::authorize()` throws 403 |
| TC-N-13 | Create with invalid id_card_type | id_card_type="Magnetic" | "The selected id card type is invalid." |
| TC-N-14 | Create with invalid id_type | id_type="Invalid Type" | "The selected id type is invalid." |
| TC-N-15 | Create with name > 80 chars | name = 81-character string | "The name must not be greater than 80 characters." |
| TC-N-16 | Create with phone > 20 chars | phone = 21-character string | "The phone must not be greater than 20 characters." |
| TC-N-17 | Create with negative driving_exp_months | driving_exp_months = -1 | "The driving exp months must be at least 0." |
| TC-N-18 | Create with driving_exp_months > 600 | driving_exp_months = 601 | "The driving exp months must not be greater than 600." |
| TC-N-19 | Create with invalid assigned_vehicle_id | assigned_vehicle_id = 99999 | "The selected assigned vehicle id is invalid." |
| TC-N-20 | Create with invalid user_id | user_id = 99999 | "The selected user id is invalid." |
| TC-N-21 | Print ID card without TemplatePurpose | No TRANSPORT_STAFF_ID_CARD in DB | abort(404) |
| TC-N-22 | Print ID card without active template assignment | Purpose exists but no active assignment | abort(404) |
| TC-N-23 | Update with expired license date | license_valid_upto = past date | "must be a date after today" |
| TC-N-24 | Toggle status without permission | No update permission | 403 |
| TC-N-25 | Print ID card without view permission | No view permission | 403 |

### TC-D: Data Integrity Test Cases

| ID | Test Case | Summary | Expected Result |
|----|-----------|---------|-----------------|
| TC-D-01 | Delete personnel with active trips | Driver assigned to trips | Soft-deleted, trips remain (FK ON DELETE SET NULL) |
| TC-D-02 | Force delete with media | Permanently remove | All 5 media collections cleared, record forceDeleted |
| TC-D-03 | Verify `is_active=false` before soft-delete | Query trashed | `is_active=0`, `deleted_at` set |
| TC-D-04 | Verify auto-code daily counter reset | Create 2 records same day | PER-20260721-001, PER-20260721-002 |
| TC-D-05 | Duplicate license after force-delete | Hard-delete, recreate same license | Allowed (unique check only filters WHERE deleted_at IS NULL) |
| TC-D-06 | Verify user FK ON DELETE SET NULL | Delete linked sys_user | `user_id` becomes NULL |
| TC-D-07 | Verify vehicle FK ON DELETE SET NULL | Delete assigned vehicle | `assigned_vehicle_id` becomes NULL |
| TC-D-08 | Print ID card — TemplatePurpose missing | No purpose in DB | `abort(404)` with message |
| TC-D-09 | Print ID card — no active template assignment | Purpose exists, no active assignment | `abort(404)` with message |
| TC-D-10 | Employee Transport-department query empty | Zero Employee records with Transport | User dropdown empty |
| TC-D-11 | MediaLibrary tables missing | Missing Spatie tables | Store/update throws integrity error |
| TC-D-12 | Verify `user_qr_code` stored format | Check DB value | `PER-20260721-001` format |
| TC-D-13 | Verify `license_valid_upto` date cast | DB stores date, model casts to Carbon | Carbon instance when accessed |
| TC-D-14 | Verify all 5 upload flags default to false | New record, no files | All flags = 0 in DB |
| TC-D-15 | Verify `police_verification_done` defaults to false | New record | `police_verification_done = 0` |
| TC-D-16 | Verify concurrent code generation | Two simultaneous requests | Different codes, no race condition |

### TC-CR: Code Review Test Cases

| ID | Test Case | Source | Expected Result |
|----|-----------|--------|-----------------|
| TC-CR-01 | `Gate::authorize()` in all 12 methods | `DriverHelperController.php` | Correct permission per method |
| TC-CR-02 | `activityLog()` in store/update/destroy/restore/forceDelete | All CRUD methods | Log with appropriate message |
| TC-CR-03 | Personnel code generation with `lockForUpdate()` | `DriverHelperController.php:65-71` | Race-condition safe daily counter |
| TC-CR-04 | Media mapping: form field → collection | `DriverHelperController.php:89-95` | 5 mappings correctly aligned |
| TC-CR-05 | Upload status flags set from `hasFile()` | `DriverHelperController.php:81-86` | Boolean per document type |
| TC-CR-06 | Update media replacement with flag update | `DriverHelperController.php:177-185` | `clearMediaCollection` then `addMediaFromRequest`, flag→true |
| TC-CR-07 | Force delete clears all media | `DriverHelperController.php:271-279` | Loop over 5 FORM FIELD names (see BC-BIZ-DEEP-23 for gap) |
| TC-CR-08 | `withValidator()` 3 custom checks | `DriverHelperRequest.php:118-167` | Inactive+vehicle, role+vehicle conflict, user re-assignment |
| TC-CR-09 | `registerMediaCollections()` 5 collections | `DriverHelper.php:171-178` | singleFile() for each |
| TC-CR-10 | `registerMediaConversions()` 3 sizes | `DriverHelper.php:183-199` | Small 100x100, Medium 250x250, Large 500x500, sharpen(10) |
| TC-CR-11 | `$fillable` matches DDL columns | `DriverHelper.php:23-54` | All DDL columns present, no phantom fields |
| TC-CR-12 | `$attributes` defaults | `DriverHelper.php:84-93` | is_active=true, police_verification=false, all upload flags=false |
| TC-CR-13 | `printIdCard()` renders via TemplateEngine | `DriverHelperController.php:315-333` | Uses `TRANSPORT_STAFF_ID_CARD` purpose |
| TC-CR-14 | `DriverHelperRequest@authorize()` POST vs non-POST | `DriverHelperRequest.php:14-18` | create vs update |
| TC-CR-15 | Redirect: store/update/destroy → transport-master.index | All CRUD | Not driver-helper.index |
| TC-CR-16 | Redirect: restore/forceDelete → driver-helper.trashed | `restore()`, `forceDelete()` | Correct trashed route |
| TC-CR-17 | Employee query for Transport department | `DriverHelperController.php:42-46` | `LOWER(name) LIKE '%transport%'` on department name |
| TC-CR-18 | Null-safe: `$driverHelper->vehicle?->vehicle_no ?? 'Not Assigned'` | `driver_helper/index.blade.php:62` | Graceful handle null vehicle |
| TC-CR-19 | Null-safe: `$driverHelper->user?->name ?? 'N/A'` | `driver_helper/index.blade.php:63` | Graceful handle null user |
| TC-CR-20 | Expired license badge red | `driver_helper/index.blade.php:54-56` | `$driverHelper->license_valid_upto < now()` |
| TC-CR-21 | **GAP**: `forceDelete()` uses form field names NOT collection names in `clearMediaCollection()` | `DriverHelperController.php:271-279` vs `DriverHelper.php:173-177` | Calls `clearMediaCollection('photo_upload')` but collection is `personnel_photo` — media NOT cleared |
| TC-CR-22 | **GAP**: `toggleStatus()` no activity log | `DriverHelperController.php:295-310` | Status changes not audited |
| TC-CR-23 | **GAP**: `printIdCard()` no activity log | `DriverHelperController.php:315-333` | Print events not tracked |
| TC-CR-24 | **GAP**: `printIdCard()` reuses student view | `DriverHelperController.php:329-332` | No dedicated staff ID card view |
| TC-CR-25 | **GAP**: Policy has 4 unused permission methods (status, import, export, print) | `DriverHelperPolicy.php:26-92` | Methods defined but never called |
| TC-CR-26 | `scopeActive` defined but unused | `DriverHelper.php:98-101` | No controller query uses `->active()` |
| TC-CR-27 | `restore()` does NOT revert `is_active` | `DriverHelperController.php:250-251` | Record stays inactive after restore |
| TC-CR-28 | `printIdCard()` uses `findOrFail` (NOT `onlyTrashed` or `withTrashed`) | `DriverHelperController.php:318` | Active AND deleted records can print ID card |
| TC-CR-29 | Code generation runs inside `DB::transaction()` | `DriverHelperController.php:62-71` | Rollback on failure reverts code counter increment |
| TC-CR-30 | `update()` uses route-model-binding; `restore()`/`forceDelete()` use manual `$id` | `DriverHelperController.php:157,246,265` | Inconsistent parameter binding |

---

## 7. Detailed Test Steps

### TC-P-01: Create full driver record with all fields + 5 documents

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with user having `tenant.driver-helper.create` permission | Authenticated |
| 2 | Navigate to `/transport/driver-helper/create` | Create form loads |
| 3 | **Verify**: `Gate::authorize('tenant.driver-helper.create')` passes (controller line 38) | Authorized |
| 4 | **Verify**: Vehicles dropdown populated: `Vehicle::where('is_active', 1)->get()` (line 40) | Active vehicles listed |
| 5 | **Verify**: Users dropdown populated: Transport department employees (lines 42-50) | Users listed |
| 6 | Enter `name = "Rajesh Kumar"` | Field populated |
| 7 | Enter `phone = "9876543210"` | Field populated |
| 8 | Select `role = "Driver"` from dropdown | Role set to Driver |
| 9 | Select `id_card_type = "QR"` from dropdown | id_card_type set to QR |
| 10 | Select `id_type = "Aadhaar Card"` from dropdown | id_type set |
| 11 | Enter `id_no = "1234-5678-9012"` | Field populated |
| 12 | Enter `license_no = "DL-123456789"` | Field populated (required for Driver) |
| 13 | Enter `license_valid_upto = "2028-06-30"` | Future date, after:today |
| 14 | Select `assigned_vehicle_id` from dropdown | Active vehicle selected |
| 15 | Enter `driving_exp_months = 60` | Within 0-600 range |
| 16 | Enter `address = "123, MG Road, Bangalore"` | Field populated |
| 17 | Check `police_verification_done = true` | Checkbox checked |
| 18 | Upload file for `photo_upload` | File attached |
| 19 | Upload file for `id_card_upload` | File attached |
| 20 | Upload file for `driving_license_upload` | File attached |
| 21 | Upload file for `police_verification_upload` | File attached |
| 22 | Upload file for `address_proof_upload` | File attached |
| 23 | Ensure `is_active = ON` | Switch/checkbox on |
| 24 | Click Save | Form POST to `transport.driver-helper.store` |
| 25 | **Verify**: `DriverHelperController::store()` called | Controller hit |
| 26 | **Verify**: `Gate::authorize('tenant.driver-helper.create')` passes (line 60) | Authorized |
| 27 | **Verify**: `$request->validated()` returns all filtered fields | Validation passes |
| 28 | **Verify**: `prepareForValidation()` normalizes `is_active = true` | Boolean normalized |
| 29 | **Verify**: `prepareForValidation()` normalizes `police_verification_done = true` | Boolean normalized |
| 30 | **Verify**: `withValidator()` 3 custom checks pass | No inactive+vehicle, no role conflict, no user reassignment conflict |
| 31 | **Verify**: `DB::transaction()` starts (line 62) | Transaction active |
| 32 | **Verify**: `DriverHelper::whereDate('created_at', today())->lockForUpdate()->count()` (line 67-68) | Row-level lock acquired |
| 33 | **Verify**: `$count + 1` calculated | e.g., count=0, next=1 |
| 34 | **Verify**: `$personnelCode = 'PER-20260721-001'` generated (line 71) | PER-YYYYMMDD-NNN format |
| 35 | **Verify**: `DriverHelper::create([...$request->validated(), 'user_qr_code' => 'PER-...', ...])` (lines 74-86) | Record created |
| 36 | **Verify**: `user_qr_code` stored as `PER-20260721-001` | DB has correct code |
| 37 | **Verify**: `photo_upload = true` (hasFile check, line 81) | Flag set to true |
| 38 | **Verify**: `id_card_upload = true` (line 82) | Flag set to true |
| 39 | **Verify**: `driving_license_upload = true` (line 83) | Flag set to true |
| 40 | **Verify**: `police_verification_upload = true` (line 84) | Flag set to true |
| 41 | **Verify**: `address_proof_upload = true` (line 85) | Flag set to true |
| 42 | **Verify**: Media loop: `photo_upload` → `personnel_photo` collection (line 90) | Media attached |
| 43 | **Verify**: Media loop: `id_card_upload` → `id_card_document` collection (line 91) | Media attached |
| 44 | **Verify**: Media loop: `driving_license_upload` → `driving_license` collection (line 92) | Media attached |
| 45 | **Verify**: Media loop: `police_verification_upload` → `police_verification_certificate` collection (line 93) | Media attached |
| 46 | **Verify**: Media loop: `address_proof_upload` → `address_proof_document` collection (line 94) | Media attached |
| 47 | **Verify**: `activityLog()` called with message "Driver/Helper created successfully." (lines 105-107) | Log entry created |
| 48 | **Verify**: `DB::transaction()` commits (implicit) | All changes persisted |
| 49 | **Verify**: Redirect to `route('transport.transport-master.index')` (line 111) | Redirected |
| 50 | **Verify**: Flash `flash('created.driver_helper')` (line 112) | Success message shown |
| 51 | **Verify**: DB has 5 media records in Spatie media table | `media.model_type = DriverHelper`, `model_id = new_id` |
| 52 | **Verify**: DB: `SELECT * FROM tpt_personnel WHERE id = new_id` | All fields match input |

### TC-P-02: Create helper (no license, no vehicle)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to create form | Form loads |
| 2 | Enter `name = "Suresh"`, select `role = "Helper"` | Basic fields |
| 3 | Leave `license_no`, `license_valid_upto`, `assigned_vehicle_id` empty | Optional fields null |
| 4 | Leave `driving_exp_months` empty | Null |
| 5 | Click Save | Form POST |
| 6 | **Verify**: `requiredIf` for license_no is FALSE (role=Helper) | No validation error |
| 7 | **Verify**: `requiredIf` for license_valid_upto is FALSE | No validation error |
| 8 | **Verify**: Record created with `license_no = NULL`, `license_valid_upto = NULL` | Stored as null |
| 9 | **Verify**: `assigned_vehicle_id = NULL` | Vehicle not assigned |
| 10 | **Verify**: `driving_exp_months = NULL` | Stored as null |

### TC-P-03: Create "Both" role with license

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to create form | Form loads |
| 2 | Enter `name = "Amit"`, select `role = "Both"` | Basic fields |
| 3 | Enter `license_no = "DL-789012"`, `license_valid_upto = "2028-12-31"` | Required for Both role |
| 4 | Select `assigned_vehicle_id` | Vehicle set |
| 5 | Click Save | Success |
| 6 | **Verify**: `requiredIf` triggers for Both role | License + valid_upto required |
| 7 | **Verify**: Record created with all fields | Success |

### TC-P-04: Edit personnel name/phone

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to personnel list | Index loads |
| 2 | Click edit on "Rajesh Kumar" | GET to `/transport/driver-helper/{id}/edit` |
| 3 | **Verify**: `Gate::authorize('tenant.driver-helper.update')` passes (line 132) | Authorized |
| 4 | **Verify**: `DriverHelper::findOrFail($id)` (line 134) | Record found |
| 5 | **Verify**: `Vehicle::where('is_active', 1)->get()` (line 135) | Active vehicles loaded |
| 6 | **Verify**: Employee query (lines 137-145) | Transport-department users loaded |
| 7 | Change `name` to "Rajesh Kumar Sharma" | Updated name |
| 8 | Change `phone` to "9988776655" | Updated phone |
| 9 | Click Save | PUT to `/transport/driver-helper/{id}` |
| 10 | **Verify**: `Gate::authorize('tenant.driver-helper.update')` passes (line 159) | Authorized |
| 11 | **Verify**: `$original = $driverHelper->getOriginal()` (line 161) | Original values captured |
| 12 | **Verify**: `$driverHelper->update([...$request->validated()])` (lines 163-166) | DB updated |
| 13 | **Verify**: `$driverHelper->getChanges()` includes name and phone (lines 190-196) | Changes detected |
| 14 | **Verify**: `activityLog()` called with changes array (lines 199-203) | Log with diff |
| 15 | **Verify**: Redirect + flash `updated.driver_helper` | Success |
| 16 | **Verify**: DB: `name = "Rajesh Kumar Sharma"`, `phone = "9988776655"` | Values updated |

### TC-P-05: Replace document on update

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Edit existing personnel with existing `driving_license_upload = true` | Has current license doc |
| 2 | Upload a NEW file for `driving_license_upload` | Different file |
| 3 | Click Save | PUT request |
| 4 | **Verify**: `$request->hasFile('driving_license_upload')` = true (line 178) | File detected |
| 5 | **Verify**: `$driverHelper->clearMediaCollection('driving_license')` (line 179) | Old media removed |
| 6 | **Verify**: `$driverHelper->addMediaFromRequest('driving_license_upload')->toMediaCollection('driving_license')` (line 180) | New media attached |
| 7 | **Verify**: `$driverHelper->update(['driving_license_upload' => true])` (line 184) | Flag stays true |
| 8 | **Verify**: Old media record deleted from Spatie table | Only 1 media record per collection |

### TC-P-06: Toggle status active→inactive

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to personnel list | Index with status switches |
| 2 | Click status switch ON for active personnel | AJAX POST to `/transport/driver-helper/{driverHelper}/toggle-status` |
| 3 | **Verify**: `Gate::authorize('tenant.driver-helper.update')` passes (line 297) | Authorized |
| 4 | **Verify**: `$request->validate(['is_active' => 'required|boolean'])` (lines 299-301) | Inline validation passes |
| 5 | **Verify**: `$driverHelper->update(['is_active' => $request->is_active])` (line 303) | is_active flipped to false |
| 6 | **Verify**: JSON response: `{success: true, is_active: false, message: flash('status_updated.driver_helper')}` (lines 305-309) | 200 OK |
| 7 | **Verify**: UI switch shows OFF state | Visual update |
| 8 | **GAP**: No activityLog call | Status change not tracked (see TC-CR-22) |

### TC-P-07: View personnel details

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to personnel list | Index loads |
| 2 | Click "Show" on a personnel | GET to `/transport/driver-helper/{id}` |
| 3 | **Verify**: `Gate::authorize('tenant.driver-helper.view')` passes (line 120) | Authorized |
| 4 | **Verify**: `DriverHelper::with(['vehicle', 'user'])->findOrFail($id)` (line 122) | Record + relationships loaded |
| 5 | **Verify**: Show page displays: name, phone, role, id card type, license, vehicle, user, address, police verification, upload flags, dates | All fields visible |
| 6 | **Verify**: "Print ID Card" button present (links to `transport.driver-helper.print-id-card`) | Button rendered |
| 7 | **Verify**: Media images shown (if uploaded) | Image tags present |

### TC-P-08: Print ID card

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with user having `tenant.driver-helper.view` permission | Authenticated |
| 2 | Navigate to show page for existing personnel | Show page |
| 3 | Click "Print ID Card" button | GET to `/transport/driver-helper/{id}/print-id-card` |
| 4 | **Verify**: `Gate::authorize('tenant.driver-helper.view')` passes (line 317) | Authorized |
| 5 | **Verify**: `DriverHelper::findOrFail($id)` (line 318) | Staff found |
| 6 | **Verify**: `TemplatePurpose::where('code', 'TRANSPORT_STAFF_ID_CARD')->first()` (line 320) | Purpose found |
| 7 | **Verify**: `$purpose->assignments()->where('is_active', true)->first()` (line 323) | Active template found |
| 8 | **Verify**: `TemplateEngine::render('TRANSPORT_STAFF_ID_CARD', [], null, null, null, null, null, ['staff_id' => $staff->id])` (line 327) | HTML rendered |
| 9 | **Verify**: `view('studentprofile::student.id-card', ['student' => (object)['full_name' => $staff->name], 'html' => $html])` (lines 329-331) | View returned |
| 10 | **Verify**: Page displays ID card with staff name and rendered HTML | Printable format |

### TC-P-09: Restore soft-deleted personnel

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to trash list `/transport/driver-helper/trash/view` | Only trashed personnel shown |
| 2 | **Verify**: `Gate::authorize('tenant.driver-helper.restore')` passes (line 234) | Authorized |
| 3 | **Verify**: `DriverHelper::onlyTrashed()->with(['vehicle','user'])->paginate(10)` (lines 236-238) | Trashed records |
| 4 | Click "Restore" on a trashed personnel | GET to `/transport/driver-helper/{id}/restore` |
| 5 | **Verify**: `Gate::authorize('tenant.driver-helper.restore')` passes (line 248) | Authorized |
| 6 | **Verify**: `DriverHelper::onlyTrashed()->findOrFail($id)` (line 250) | Found in trash |
| 7 | **Verify**: `$driverHelper->restore()` (line 251) | `deleted_at` set to NULL |
| 8 | **Verify**: `activityLog()` called with "Driver/Helper restored." (lines 253-255) | Log entry |
| 9 | **Verify**: Redirect to `route('transport.driver-helper.trashed')` (line 258) | Back to trash |
| 10 | **Verify**: Flash `flash('restored.driver_helper')` (line 259) | Success message |
| 11 | DB check: `SELECT deleted_at, is_active FROM tpt_personnel WHERE id = X` | `deleted_at = NULL`, `is_active = 0` (stays inactive) |
| 12 | **GAP**: `is_active` NOT reverted to `true` after restore | Record is inactive (see TC-CR-27) |

### TC-P-10: Search by name

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to personnel list | Index loads |
| 2 | Enter "Rajesh" in search box | Search text entered |
| 3 | Click search/submit | GET with search query |
| 4 | **Verify**: Controller processes default `index()` with `$request->search` | Search applied via query builder or index default (index does NOT filter — see note) |
| 5 | **Note**: `index()` does NOT have search filtering — search is handled client-side or via DataTable | Verify blade JS for client-side filtering |

### TC-P-11: Create with all 5 ID types

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create driver with `id_type = "Aadhaar Card"` | Passes `Rule::in(DriverHelper::ID_TYPES)` |
| 2 | Create driver with `id_type = "Licence Number"` | Passes |
| 3 | Create driver with `id_type = "PAN Card"` | Passes |
| 4 | Create driver with `id_type = "Voter ID"` | Passes |
| 5 | Create driver with `id_type = "Passport"` | Passes |
| 6 | **Verify**: All 5 accepted | DB stores each correctly |

### TC-P-12: Create with all 4 ID card types

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create with `id_card_type = "QR"` | Passes |
| 2 | Create with `id_card_type = "RFID"` | Passes |
| 3 | Create with `id_card_type = "NFC"` | Passes |
| 4 | Create with `id_card_type = "Barcode"` | Passes |
| 5 | **Verify**: All 4 accepted | DB stores each correctly |

### TC-P-13: Create without optional fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create with only required fields: name, role (Helper), id_card_type, is_active | Minimal data |
| 2 | Leave phone, id_type, id_no, address empty | All null |
| 3 | Click Save | Success |
| 4 | **Verify**: Phone, id_type, id_no, address = NULL in DB | Null stored |
| 5 | **Verify**: Model defaults: all 5 upload flags = false, police_verification = false | Defaults applied |

### TC-P-14: Create without vehicle assignment

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create driver WITHOUT selecting `assigned_vehicle_id` | Null |
| 2 | Click Save | Success |
| 3 | **Verify**: `assigned_vehicle_id = NULL` in DB | FK null |
| 4 | **Verify**: List shows "Not Assigned" | `$driverHelper->vehicle?->vehicle_no ?? 'Not Assigned'` |

### TC-P-15: Create without user linking

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create driver WITHOUT selecting `user_id` | Null |
| 2 | Click Save | Success |
| 3 | **Verify**: `user_id = NULL` in DB | FK null |
| 4 | **Verify**: List shows "N/A" | `$driverHelper->user?->name ?? 'N/A'` |

### TC-P-16: Duplicate license after soft-delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create driver A with `license_no = "DL-UNIQUE"` | Created |
| 2 | Soft-delete driver A | `deleted_at` set |
| 3 | Create driver B with same `license_no = "DL-UNIQUE"` | **Allowed** |
| 4 | **Verify**: Unique rule: `->whereNull('deleted_at')` excludes soft-deleted | Validation passes |
| 5 | **Verify**: Driver B created successfully | Second record with same license |

### TC-P-17: View trashed personnel

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to `/transport/driver-helper/trash/view` | Trash page |
| 2 | **Verify**: Only trashed records shown | `onlyTrashed()` applied |
| 3 | **Verify**: 10 per page pagination | `paginate(10)` |
| 4 | **Verify**: Restore + Force Delete buttons visible (if permitted) | `@canany(['restore','forceDelete'])` |

### TC-P-18: Force delete trashed personnel

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to trash | Trash list |
| 2 | Click "Force Delete" on a trashed personnel | DELETE to `/transport/driver-helper/{id}/force-delete` |
| 3 | **Verify**: `Gate::authorize('tenant.driver-helper.forceDelete')` passes (line 267) | Authorized |
| 4 | **Verify**: `DriverHelper::withTrashed()->findOrFail($id)` (line 269) | Record found (trashed) |
| 5 | **Verify**: Loop: `clearMediaCollection('photo_upload')` — form field name used (lines 271-279) | `clearMediaCollection` called |
| 6 | **GAP**: `clearMediaCollection('photo_upload')` uses FORM FIELD name, not collection name `personnel_photo` | Media NOT actually cleared (see TC-CR-21) |
| 7 | **Verify**: `$driverHelper->forceDelete()` (line 281) | Record permanently deleted |
| 8 | **Verify**: `activityLog()` called with "Driver/Helper permanently deleted." (lines 283-285) | Log entry |
| 9 | **Verify**: Redirect to `route('transport.driver-helper.trashed')` (line 288) | Back to trash |
| 10 | **Verify**: Flash `flash('force_deleted.driver_helper')` (line 289) | Success message |
| 11 | **Verify**: DB: Record no longer exists | `SELECT * FROM tpt_personnel WHERE id = X` → empty |

### TC-P-19: Force delete active (non-trashed) personnel

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to personnel list (active personnel) | Index |
| 2 | Note: No direct "Force Delete" button on active list | UI hidden |
| 3 | Direct URL: DELETE to `/transport/driver-helper/{id}/force-delete` on active record | Controller hit |
| 4 | **Verify**: `DriverHelper::withTrashed()->findOrFail($id)` (line 269) | Finds active record (deleted_at=NULL) |
| 5 | **Verify**: `$driverHelper->forceDelete()` | Record permanently deleted |
| 6 | **Note**: `withTrashed()` allows force-deleting active records (unlike `onlyTrashed()` which would 404) | Correct behavior |

### TC-P-20: List pagination

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure 15 records exist in `tpt_personnel` | 15 records |
| 2 | Navigate to personnel list | Index page 1 |
| 3 | **Verify**: 10 records shown | `paginate(10)` |
| 4 | **Verify**: Page 2 link visible | Pagination links |
| 5 | Click page 2 | Remaining 5 records shown |

### TC-N-01: Create with empty name

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit create form with `name = ""` | Empty name |
| 2 | Fill all other required fields | Others valid |
| 3 | Click Save | Validation fails |
| 4 | **Verify**: Rule `required` on `name` | "The name field is required." |
| 5 | **Verify**: Form re-displayed with error | No redirect |

### TC-N-02: Create with invalid role

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit create form with `role = "Supervisor"` | Invalid role |
| 2 | Click Save | Validation fails |
| 3 | **Verify**: Rule `Rule::in(['Driver','Helper','Both'])` | "The selected role is invalid." |

### TC-N-03: Create driver without license_no

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set `role = "Driver"` | License required |
| 2 | Leave `license_no` empty | Not provided |
| 3 | Click Save | Validation fails |
| 4 | **Verify**: `Rule::requiredIf(fn => in_array($this->role, ['Driver','Both']))` | "The license no field is required." |

### TC-N-04: Create driver with expired license date

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set `role = "Driver"` | License required |
| 2 | Enter `license_valid_upto = "2020-01-01"` | Past date |
| 3 | Click Save | Validation fails |
| 4 | **Verify**: `after:today` rule | "The license valid upto must be a date after today." |

### TC-N-05: Create with duplicate license_no

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure existing driver has `license_no = "DL-EXISTING"` | Existing record |
| 2 | Create new driver with same `license_no = "DL-EXISTING"` | Duplicate |
| 3 | Click Save | Validation fails |
| 4 | **Verify**: `Rule::unique('tpt_personnel', 'license_no')->whereNull('deleted_at')` | "The license no has already been taken." |

### TC-N-06: Assign vehicle to inactive personnel

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set `is_active = false` (unchecked) | Inactive |
| 2 | Select `assigned_vehicle_id` from dropdown | Vehicle set |
| 3 | Click Save | Validation fails |
| 4 | **Verify**: Custom check 1: `!$this->is_active && $this->assigned_vehicle_id` (line 125) | "Inactive personnel cannot be assigned" |
| 5 | **Verify**: Error on `assigned_vehicle_id` field | Error displayed |

### TC-N-07: Assign same vehicle+role to two drivers

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Driver A: role="Driver", assigned_vehicle_id=V1, is_active=true | Success |
| 2 | Create Driver B: role="Driver", assigned_vehicle_id=V1, is_active=true | Conflict |
| 3 | Click Save for Driver B | Validation fails |
| 4 | **Verify**: Custom check 2: `DriverHelper::where('assigned_vehicle_id', V1)->where('role','Driver')->where('is_active',1)->whereNull('deleted_at')->exists()` (lines 134-139) | "Vehicle already has an active Driver" |
| 5 | **Verify**: Error on `assigned_vehicle_id` | Error displayed |

### TC-N-08: Link user already assigned to another vehicle

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Driver A: user_id=U1, assigned_vehicle_id=V1 | Success |
| 2 | Create Driver B: user_id=U1, assigned_vehicle_id=V2 (different vehicle) | Conflict |
| 3 | Click Save for Driver B | Validation fails |
| 4 | **Verify**: Custom check 3: `DriverHelper::where('user_id',U1)->where('assigned_vehicle_id','!=',V2)->whereNotNull('assigned_vehicle_id')->where('is_active',1)->whereNull('deleted_at')->exists()` | "This personnel is already assigned to another vehicle" |

### TC-N-09 through TC-N-12: Permission-based negative tests

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user WITHOUT any `tenant.driver-helper.*` permissions | No permissions |
| 2 | Navigate to `index` | `Gate::authorize('viewAny')` → 403 |
| 3 | GET to `create` | `Gate::authorize('create')` → 403 |
| 4 | POST to `store` | `Gate::authorize('create')` → 403 |
| 5 | GET to `show/{id}` | `Gate::authorize('view')` → 403 |
| 6 | GET to `edit/{id}` | `Gate::authorize('update')` → 403 |
| 7 | PUT to `update/{id}` | `Gate::authorize('update')` → 403 |
| 8 | DELETE to `destroy/{id}` | `Gate::authorize('delete')` → 403 |
| 9 | GET to `trashed` | `Gate::authorize('restore')` → 403 |
| 10 | GET to `restore/{id}` | `Gate::authorize('restore')` → 403 |
| 11 | DELETE to `forceDelete/{id}` | `Gate::authorize('forceDelete')` → 403 |
| 12 | POST to `toggleStatus/{id}` | `Gate::authorize('update')` → 403 |
| 13 | GET to `printIdCard/{id}` | `Gate::authorize('view')` → 403 |

### TC-N-13: Invalid id_card_type

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit create with `id_card_type = "Magnetic"` | Invalid |
| 2 | **Verify**: `Rule::in(['QR','RFID','NFC','Barcode'])` | "The selected id card type is invalid." |

### TC-N-14: Invalid id_type

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit create with `id_type = "Invalid Type"` | Not in ID_TYPES |
| 2 | **Verify**: `Rule::in(DriverHelper::ID_TYPES)` | "The selected id type is invalid." |

### TC-N-15: Name > 80 chars

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter 81-character name | Overflow |
| 2 | Click Save | "The name must not be greater than 80 characters." |

### TC-N-16: Phone > 20 chars

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter 21-character phone | Overflow |
| 2 | Click Save | "The phone must not be greater than 20 characters." |

### TC-N-17: Negative driving_exp_months

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter `driving_exp_months = -1` | Negative |
| 2 | Click Save | "The driving exp months must be at least 0." |

### TC-N-18: driving_exp_months > 600

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter `driving_exp_months = 601` | Over max |
| 2 | Click Save | "The driving exp months must not be greater than 600." |

### TC-N-19: Invalid assigned_vehicle_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter `assigned_vehicle_id = 99999` | Non-existent |
| 2 | Click Save | "The selected assigned vehicle id is invalid." |

### TC-N-20: Invalid user_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter `user_id = 99999` | Non-existent |
| 2 | Click Save | "The selected user id is invalid." |

### TC-N-21: Print ID card — TemplatePurpose not found

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Delete or rename `TemplatePurpose` where code = `TRANSPORT_STAFF_ID_CARD` | Purpose missing |
| 2 | Navigate to print ID card for any staff | Controller hit |
| 3 | **Verify**: Line 320: `TemplatePurpose::where('code', 'TRANSPORT_STAFF_ID_CARD')->first()` = null | Not found |
| 4 | **Verify**: Line 321: `abort(404, "Purpose 'TRANSPORT_STAFF_ID_CARD' not found.")` | 404 page |

### TC-N-22: Print ID card — no active template assignment

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure `TemplatePurpose` with code `TRANSPORT_STAFF_ID_CARD` exists | Purpose exists |
| 2 | Ensure NO active assignment exists | `$assignment = null` |
| 3 | Navigate to print ID card | Controller hit |
| 4 | **Verify**: Line 323: `$purpose->assignments()->where('is_active', true)->first()` = null | No active assignment |
| 5 | **Verify**: Line 324: `abort(404, "No active template assigned for Transport Staff ID Card")` | 404 page |

### TC-N-23: Update with expired license date

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Edit existing driver | Edit form |
| 2 | Change `license_valid_upto` to past date | 2020-01-01 |
| 3 | Click Save | Validation fails |
| 4 | **Verify**: `after:today` rule fires | "must be a date after today" |

### TC-N-24: Toggle status without permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user without `tenant.driver-helper.update` | No update |
| 2 | POST to `/transport/driver-helper/{id}/toggle-status` | AJAX |
| 3 | **Verify**: `Gate::authorize('tenant.driver-helper.update')` at line 297 | 403 response |

### TC-N-25: Print ID card without view permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user without `tenant.driver-helper.view` | No view |
| 2 | GET to `/transport/driver-helper/{id}/print-id-card` | 403 |
| 3 | **Verify**: `Gate::authorize('tenant.driver-helper.view')` at line 317 | 403 response |

### TC-D-01: Delete personnel with active trips

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Driver D1 with trips assigned | Has related trips in `tpt_trip` |
| 2 | Delete Driver D1 | Soft delete |
| 3 | **Verify**: Line 217: `$driverHelper->update(['is_active'=>false])` | is_active=0 |
| 4 | **Verify**: Line 218: `$driverHelper->delete()` | deleted_at set |
| 5 | DB: `SELECT * FROM tpt_trip WHERE driver_id = D1.id` | Trips still exist (FK stays, ON DELETE SET NULL only applies to direct FK delete) |
| 6 | **Note**: DriverHelper FK in tpt_trip is `driver_id` — there is NO FK constraint on this column from DDL review | Trips remain with driver_id intact |

### TC-D-02: Force delete with media

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create personnel with 5 uploaded documents | All 5 collections have media |
| 2 | Force delete the personnel | `forceDelete()` called |
| 3 | **Verify**: Spatie media table: `SELECT * FROM media WHERE model_id = X` | Media records may STILL exist due to BC-BIZ-DEEP-23 gap |
| 4 | **Verify**: Record removed from `tpt_personnel` | `forceDelete()` executes |

### TC-D-03: Verify is_active=false before soft-delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create personnel with is_active=true | Active |
| 2 | Delete the personnel | `destroy()` called |
| 3 | DB: `SELECT is_active, deleted_at FROM tpt_personnel WHERE id = X` | `is_active = 0`, `deleted_at IS NOT NULL` |
| 4 | **Verify**: Two-step process executed | `update(is_active=false)` then `delete()` |

### TC-D-04: Verify auto-code daily counter

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 2 personnel on same day | Day 1 records |
| 2 | DB: `SELECT user_qr_code FROM tpt_personnel ORDER BY id DESC LIMIT 2` | PER-20260721-001, PER-20260721-002 |
| 3 | Create 1 personnel on next day | Day 2 |
| 4 | DB: Check newest code | PER-20260722-001 (counter resets) |
| 5 | **Verify**: `whereDate('created_at', Carbon::today())` scopes by date | Daily reset |

### TC-D-05: Duplicate license after force-delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create driver with `license_no = "DL-FORCE"` | Active |
| 2 | Force delete this driver | Record gone |
| 3 | Create new driver with `license_no = "DL-FORCE"` | Allowed |
| 4 | **Verify**: `->whereNull('deleted_at')` on unique rule | No conflict (record was force-deleted, no deleted_at) |

### TC-D-06: Verify user FK ON DELETE SET NULL

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create personnel with `user_id = U1` | Linked |
| 2 | Delete sys_user U1 from `sys_users` table | User deleted |
| 3 | DB: `SELECT user_id FROM tpt_personnel WHERE user_id = U1` | `NULL` |
| 4 | **Verify**: DDL FK `ON DELETE SET NULL` (line 51,74) | FK constraint executed |

### TC-D-07: Verify vehicle FK ON DELETE SET NULL

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create personnel with `assigned_vehicle_id = V1` | Vehicle assigned |
| 2 | Delete vehicle V1 from `tpt_vehicle` | Vehicle deleted |
| 3 | DB: `SELECT assigned_vehicle_id FROM tpt_personnel WHERE assigned_vehicle_id = V1` | `NULL` |
| 4 | **Verify**: DDL FK `ON DELETE SET NULL` (line 61,75) | FK constraint executed |

### TC-D-08: Print ID card — TemplatePurpose missing

Same as TC-N-21 — verified at the DB integrity level.

### TC-D-09: Print ID card — no active assignment

Same as TC-N-22 — verified at the DB integrity level.

### TC-D-10: Employee Transport-department query empty

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure NO Employee records have Transport department | Zero matches |
| 2 | Navigate to create form | Form loads |
| 3 | **Verify**: Line 46: `->pluck('user_id')->filter()->toArray()` = `[]` | Empty array |
| 4 | **Verify**: Lines 48-50: `User::whereIn('id', [])` returns empty collection | `$users = collect()` |
| 5 | **Verify**: User dropdown has no options | Empty select |

### TC-D-11: MediaLibrary tables missing

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Drop/disable Spatie Media Library tables | Tables missing |
| 2 | Create personnel with file upload | Store called |
| 3 | **Verify**: `addMediaFromRequest()` fails | Integrity constraint error or exception |
| 4 | **Verify**: Transaction rollback (store is in `DB::transaction()`) | No partial record |

### TC-D-12: Verify user_qr_code stored format

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create personnel on 2026-07-21 | Code generated |
| 2 | DB: `SELECT user_qr_code FROM tpt_personnel ORDER BY id DESC LIMIT 1` | `PER-20260721-00N` format |

### TC-D-13: Verify license_valid_upto date cast

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create driver with date `2028-06-30` | Stored |
| 2 | Access `$driverHelper->license_valid_upto` in PHP | Returns Carbon instance |
| 3 | **Verify**: Model cast `'license_valid_upto' => 'date'` | Carbon object |

### TC-D-14: Upload flags default to false

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create personnel without any file uploads | No files |
| 2 | DB: `SELECT photo_upload, id_card_upload, driving_license_upload, police_verification_upload, address_proof_upload` | All = 0 |
| 3 | **Verify**: `$attributes` defaults (lines 88-92) | Default applied |

### TC-D-15: police_verification_done defaults to false

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create personnel without checking police_verification | Not checked |
| 2 | DB: `SELECT police_verification_done` | 0 |
| 3 | **Verify**: `$attributes` default (line 86) | Default false |

### TC-D-16: Verify concurrent code generation race condition

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send 2 simultaneous create requests | Both in transaction |
| 2 | **Verify**: `lockForUpdate()` on count query (line 68) | Second request waits |
| 3 | First completes → count=1, code=PER-...-001 | Code 001 |
| 4 | Second completes → count=2, code=PER-...-002 | Code 002 |
| 5 | **Verify**: No duplicate codes generated | Codes unique |

### TC-CR-01: Gate::authorize() verification

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `DriverHelperController.php` | All 12 methods checked |
| 2 | `index()` line 26: `Gate::authorize('tenant.driver-helper.viewAny')` | Present |
| 3 | `create()` line 38: `Gate::authorize('tenant.driver-helper.create')` | Present |
| 4 | `store()` line 60: `Gate::authorize('tenant.driver-helper.create')` | Present |
| 5 | `show()` line 120: `Gate::authorize('tenant.driver-helper.view')` | Present |
| 6 | `edit()` line 132: `Gate::authorize('tenant.driver-helper.update')` | Present |
| 7 | `update()` line 159: `Gate::authorize('tenant.driver-helper.update')` | Present |
| 8 | `destroy()` line 215: `Gate::authorize('tenant.driver-helper.delete')` | Present |
| 9 | `trashed()` line 234: `Gate::authorize('tenant.driver-helper.restore')` | Present |
| 10 | `restore()` line 248: `Gate::authorize('tenant.driver-helper.restore')` | Present |
| 11 | `forceDelete()` line 267: `Gate::authorize('tenant.driver-helper.forceDelete')` | Present |
| 12 | `toggleStatus()` line 297: `Gate::authorize('tenant.driver-helper.update')` | Present |
| 13 | `printIdCard()` line 317: `Gate::authorize('tenant.driver-helper.view')` | Present |

### TC-CR-02: activityLog() verification

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `store()` lines 105-107: `activityLog($driverHelper, 'Stored', ['message' => 'Driver/Helper created successfully.'])` | Present |
| 2 | `update()` lines 199-203: `activityLog($driverHelper, 'Updated', ['message' => 'Driver/Helper updated.', 'changes' => $changes, 'performed_by' => Auth::user()->name])` | Present |
| 3 | `destroy()` lines 220-222: `activityLog($driverHelper, 'Trashed', ['message' => 'Driver/Helper deactivated.'])` | Present |
| 4 | `restore()` lines 253-255: `activityLog($driverHelper, 'Restored', ['message' => 'Driver/Helper restored.'])` | Present |
| 5 | `forceDelete()` lines 283-285: `activityLog($driverHelper, 'Deleted', ['message' => 'Driver/Helper permanently deleted.'])` | Present |
| 6 | **GAP**: `toggleStatus()` — NO activityLog | Missing (see TC-CR-22) |
| 7 | **GAP**: `printIdCard()` — NO activityLog | Missing (see TC-CR-23) |

### TC-CR-03: Personnel code generation with lockForUpdate()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `DriverHelperController.php:65-71` | Code block |
| 2 | **Verify**: `$today = Carbon::today()->format('Ymd')` | YYYYMMDD format |
| 3 | **Verify**: `DriverHelper::whereDate('created_at', Carbon::today())->lockForUpdate()->count() + 1` | Race-condition safe |
| 4 | **Verify**: `str_pad($count, 3, '0', STR_PAD_LEFT)` | Zero-padded 3 digits |
| 5 | **Verify**: Inside `DB::transaction()` | Atomic operation |
| 6 | **Verify**: Format: `'PER-' . $today . '-' . padded_count` | PER-20260721-001 |

### TC-CR-04: Media mapping

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `DriverHelperController.php:89-95` | Mapping array |
| 2 | `photo_upload` → `personnel_photo` | Correct |
| 3 | `id_card_upload` → `id_card_document` | Correct |
| 4 | `driving_license_upload` → `driving_license` | Correct |
| 5 | `police_verification_upload` → `police_verification_certificate` | Correct |
| 6 | `address_proof_upload` → `address_proof_document` | Correct |

### TC-CR-05: Upload status flags from hasFile()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `DriverHelperController.php:81-86` | Flag set block |
| 2 | `'photo_upload' => $request->hasFile('photo_upload')` | Boolean |
| 3 | `'id_card_upload' => $request->hasFile('id_card_upload')` | Boolean |
| 4 | `'driving_license_upload' => $request->hasFile('driving_license_upload')` | Boolean |
| 5 | `'police_verification_upload' => $request->hasFile('police_verification_upload')` | Boolean |
| 6 | `'address_proof_upload' => $request->hasFile('address_proof_upload')` | Boolean |

### TC-CR-06: Update media replacement

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `DriverHelperController.php:177-185` | Update media block |
| 2 | Loop over `$mediaMapping` | 5 iterations |
| 3 | `$request->hasFile($formField)` check | File present check |
| 4 | `$driverHelper->clearMediaCollection($collection)` | Old media removed |
| 5 | `$driverHelper->addMediaFromRequest($formField)->toMediaCollection($collection)` | New media added |
| 6 | `$driverHelper->update([$flagField => true])` | Flag refreshed |

### TC-CR-07: Force delete media clearing

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `DriverHelperController.php:271-279` | Media clear loop |
| 2 | Collections array: `['photo_upload', 'id_card_upload', 'driving_license_upload', 'police_verification_upload', 'address_proof_upload']` | Form field names |
| 3 | **GAP**: These are FORM FIELD names, NOT registered collection names | See BC-BIZ-DEEP-23 |
| 4 | **Expected fix**: Should use `['personnel_photo', 'id_card_document', 'driving_license', 'police_verification_certificate', 'address_proof_document']` | Collection names needed |

### TC-CR-08: Custom after-validation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `DriverHelperRequest.php:118-167` | `withValidator` |
| 2 | Check 1 (line 125-130): `!$this->is_active && $this->assigned_vehicle_id` | Inactive+vehicle error |
| 3 | Check 2 (line 133-147): Same vehicle+role conflict | Role conflict error |
| 4 | Check 3 (line 150-165): User reassignment conflict | User conflict error |
| 5 | All checks use `$currentId` (line 122) to skip current record | Update-safe |

### TC-CR-09: Media collections registration

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `DriverHelper.php:171-178` | `registerMediaCollections()` |
| 2 | `addMediaCollection('personnel_photo')->singleFile()` | Present |
| 3 | `addMediaCollection('id_card_document')->singleFile()` | Present |
| 4 | `addMediaCollection('driving_license')->singleFile()` | Present |
| 5 | `addMediaCollection('police_verification_certificate')->singleFile()` | Present |
| 6 | `addMediaCollection('address_proof_document')->singleFile()` | Present |

### TC-CR-10: Media conversions

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `DriverHelper.php:183-199` | `registerMediaConversions()` |
| 2 | `small`: width(100), height(100), sharpen(10) | 100x100 |
| 3 | `medium`: width(250), height(250), sharpen(10) | 250x250 |
| 4 | `large`: width(500), height(500), sharpen(10) | 500x500 |

### TC-CR-11: $fillable matches DDL

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `DriverHelper.php:23-54` | 22 fillable fields |
| 2 | Verify each DDL column is in fillable | All present |
| 3 | Note: DDL has `payee_mode` and `attachment` but NOT in fillable | Model mismatch per BC-BIZ-DEEP-42 |

### TC-CR-12: $attributes defaults

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `DriverHelper.php:84-93` | Defaults block |
| 2 | `is_active => true` | Active by default |
| 3 | `police_verification_done => false` | Not done by default |
| 4 | All 5 upload flags => false | No uploads by default |

### TC-CR-13: printIdCard TemplateEngine usage

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `DriverHelperController.php:315-333` | `printIdCard()` |
| 2 | `TemplatePurpose::where('code', 'TRANSPORT_STAFF_ID_CARD')` | Hardcoded purpose code |
| 3 | `app(TemplateEngine::class)->render(...)` | Engine renders |
| 4 | `view('studentprofile::student.id-card', ...)` | Reuses student view |

### TC-CR-14: FormRequest authorize

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `DriverHelperRequest.php:14-18` | `authorize()` method |
| 2 | POST → `tenant.driver-helper.create` | Create gate |
| 3 | NOT POST → `tenant.driver-helper.update` | Update gate |

### TC-CR-15: CRUD redirects to transport-master

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `store()` line 111: `route('transport.transport-master.index')` | Correct |
| 2 | `update()` line 206: `route('transport.transport-master.index')` | Correct |
| 3 | `destroy()` line 225: `route('transport.transport-master.index')` | Correct |

### TC-CR-16: Restore/forceDelete redirect to trashed

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `restore()` line 258: `route('transport.driver-helper.trashed')` | Correct |
| 2 | `forceDelete()` line 288: `route('transport.driver-helper.trashed')` | Correct |

### TC-CR-17: Employee Transport department query

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `DriverHelperController.php:42-46` | Employee query |
| 2 | `Employee::whereHas('employeeProfiles.department', fn => $q->whereRaw('LOWER(name) LIKE ?', ['%transport%']))` | employeeProfile path |
| 3 | `->orWhereHas('teacherProfiles.department', fn => $q->whereRaw('LOWER(name) LIKE ?', ['%transport%']))` | teacherProfile path |
| 4 | `->pluck('user_id')->filter()->toArray()` | Filtered user_ids |

### TC-CR-18: Null-safe vehicle display

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Index blade line 62: `$driverHelper->vehicle?->vehicle_no ?? 'Not Assigned'` | Null-safe |
| 2 | Test with null vehicle | Shows "Not Assigned" |
| 3 | Test with assigned vehicle | Shows vehicle number |

### TC-CR-19: Null-safe user display

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Index blade line 63: `$driverHelper->user?->name ?? 'N/A'` | Null-safe |
| 2 | Test with null user | Shows "N/A" |
| 3 | Test with assigned user | Shows user name |

### TC-CR-20: Expired license badge

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Index blade line 54-56: `$driverHelper->license_valid_upto < now()` | Condition |
| 2 | Test with future date | No badge |
| 3 | Test with past date | Red "Expired" badge |

### TC-CR-21: GAP — forceDelete uses wrong collection names

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Compare `DriverHelperController.php:271-279` with `DriverHelper.php:171-178` | Mismatch |
| 2 | Controller uses: `photo_upload`, `id_card_upload`, `driving_license_upload`, `police_verification_upload`, `address_proof_upload` | Form field names |
| 3 | Model registers: `personnel_photo`, `id_card_document`, `driving_license`, `police_verification_certificate`, `address_proof_document` | Collection names |
| 4 | `clearMediaCollection('photo_upload')` does NOT match collection `personnel_photo` | Media NOT cleared |
| 5 | **Impact**: Force-deleted personnel will still have orphaned media records | Data integrity issue |

### TC-CR-22: GAP — toggleStatus no activity log

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `DriverHelperController.php:295-310` | `toggleStatus()` |
| 2 | Search for `activityLog` in method | NOT found |
| 3 | **Impact**: Status changes are not audited | No trace of who toggled status or when |

### TC-CR-23: GAP — printIdCard no activity log

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `DriverHelperController.php:315-333` | `printIdCard()` |
| 2 | Search for `activityLog` in method | NOT found |
| 3 | **Impact**: ID card print events not tracked | Can't audit who printed cards |

### TC-CR-24: GAP — printIdCard reuses student view

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `DriverHelperController.php:329-331` | `view('studentprofile::student.id-card')` |
| 2 | View expects `$student` object with `full_name` | Anonymous object created |
| 3 | **Impact**: Staff ID card reuses student ID card layout | May not display all staff-specific fields |

### TC-CR-25: GAP — unused policy methods

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `DriverHelperPolicy.php:26-92` | 11 permission methods |
| 2 | `status()` (line 26) | NOT called in controller |
| 3 | `import()` (line 73) | NOT called in controller |
| 4 | `export()` (line 81) | NOT called in controller |
| 5 | `print()` (line 89) | NOT called in controller (uses `view` instead) |
| 6 | **Impact**: 4 defined permissions are dead code | Unused policy methods |

### TC-CR-26: scopeActive defined but unused

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `DriverHelper.php:98-101` | `scopeActive` |
| 2 | Search controller for `->active()` | Not used |
| 3 | **Impact**: Index shows inactive personnel | No default active filter |

### TC-CR-27: GAP — restore does not revert is_active

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `DriverHelperController.php:250-251` | `restore()` body |
| 2 | `$driverHelper->restore()` | Only restores deleted_at |
| 3 | No `update(['is_active'=>true])` call | is_active stays false |
| 4 | **Impact**: Restored personnel are inactive | Must manually toggle status |

### TC-CR-28: printIdCard findOrFail vs trashed

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `DriverHelperController.php:318` | `DriverHelper::findOrFail($id)` |
| 2 | **Note**: Uses `findOrFail` (not `onlyTrashed` or `withTrashed`) | Finds ANY record (active, inactive, trashed) |
| 3 | Print ID card works for soft-deleted staff | No restriction |

### TC-CR-29: Code generation in transaction

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `DriverHelperController.php:62-71` | Inside `DB::transaction()` |
| 2 | Code gen runs first, then record creation | If create fails, transaction rolls back |
| 3 | **Verify**: Counter increment `$count` is NOT reverted by rollback | `lockForUpdate()` counter is within transaction, so ROLLBACK means next attempt re-counts |

### TC-CR-30: Inconsistent parameter binding

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `update()` uses `DriverHelper $driverHelper` (route-model-binding) | Auto-resolved |
| 2 | `destroy()` uses `DriverHelper $driverHelper` (route-model-binding) | Auto-resolved |
| 3 | `toggleStatus()` uses `DriverHelper $driverHelper` (route-model-binding) | Auto-resolved |
| 4 | `restore($id)` uses manual `$id` | Manual findOrFail |
| 5 | `forceDelete($id)` uses manual `$id` | Manual findOrFail |
| 6 | `show($id)` uses manual `$id` | Manual findOrFail |
| 7 | `edit($id)` uses manual `$id` | Manual findOrFail |
| 8 | **Inconsistency**: 3 methods use implicit binding, 4 use manual ID | Mixed pattern |

### CODE-TRACE-01: index() — Complete Code Trace

| Step | Code Line | What Happens |
|------|-----------|--------------|
| 1 | `DriverHelperController.php:26` | `Gate::authorize('tenant.driver-helper.viewAny')` — checks viewAny permission |
| 2 | `DriverHelperController.php:28` | `DriverHelper::with(['vehicle', 'user'])->paginate(10)` — eager loads 2 relationships, paginates 10 |
| 3 | `DriverHelperController.php:30` | `return view('transport::driver_helper.index', compact('driverHelpers'))` — renders index view |

### CODE-TRACE-02: create() — Complete Code Trace

| Step | Code Line | What Happens |
|------|-----------|--------------|
| 1 | `DriverHelperController.php:38` | `Gate::authorize('tenant.driver-helper.create')` — checks create permission |
| 2 | `DriverHelperController.php:40` | `Vehicle::where('is_active', 1)->get()` — loads all active vehicles |
| 3 | `DriverHelperController.php:42-46` | `Employee::whereHas('employeeProfiles.department', ...)->orWhereHas('teacherProfiles.department', ...)->pluck('user_id')->filter()->toArray()` — queries both employee and teacher profiles for Transport dept |
| 4 | `DriverHelperController.php:48-50` | `User::where('is_active', true)->whereIn('id', $userIds)->get()` — loads active Transport-department users |
| 5 | `DriverHelperController.php:52` | `return view('transport::driver_helper.create', compact('vehicles', 'users'))` — renders create view with 2 data sets |

### CODE-TRACE-03: store() — Complete Code Trace

| Step | Code Line | What Happens |
|------|-----------|--------------|
| 1 | `DriverHelperController.php:60` | `Gate::authorize('tenant.driver-helper.create')` — checks create permission |
| 2 | `DriverHelperController.php:62` | `DB::transaction(function () use ($request) {` — starts DB transaction |
| 3 | `DriverHelperController.php:65` | `$today = Carbon::today()->format('Ymd')` — generates date string, e.g. "20260721" |
| 4 | `DriverHelperController.php:67-69` | `$count = DriverHelper::whereDate('created_at', Carbon::today())->lockForUpdate()->count() + 1` — race-condition-safe daily counter |
| 5 | `DriverHelperController.php:71` | `$personnelCode = 'PER-' . $today . '-' . str_pad($count, 3, '0', STR_PAD_LEFT)` — format: PER-YYYYMMDD-NNN |
| 6 | `DriverHelperController.php:74-86` | `DriverHelper::create([...$request->validated(), 'user_qr_code' => $personnelCode, ...upload flags])` — creates record with validated data + overrides |
| 7 | `DriverHelperController.php:78` | `'police_verification_done' => $request->boolean('police_verification_done')` — boolean normalization |
| 8 | `DriverHelperController.php:81-86` | Upload flags set from `$request->hasFile()` — 5 boolean flags |
| 9 | `DriverHelperController.php:89-95` | Media mapping array: form fields → collection names (5 entries) |
| 10 | `DriverHelperController.php:97-103` | Loop: `if hasFile → addMediaFromRequest → toMediaCollection` — uploads 5 files |
| 11 | `DriverHelperController.php:105-107` | `activityLog($driverHelper, 'Stored', ['message' => 'Driver/Helper created successfully.'])` — logs creation |
| 12 | DriverHelperController.php:108 (implicit) | `DB::transaction()` commits automatically |
| 13 | `DriverHelperController.php:110-112` | `redirect()->route('transport.transport-master.index')->with('success', flash('created.driver_helper'))` — redirects to master tab |

### CODE-TRACE-04: show() — Complete Code Trace

| Step | Code Line | What Happens |
|------|-----------|--------------|
| 1 | `DriverHelperController.php:120` | `Gate::authorize('tenant.driver-helper.view')` — checks view permission |
| 2 | `DriverHelperController.php:122` | `DriverHelper::with(['vehicle', 'user'])->findOrFail($id)` — eager loads relationships, 404 if not found |
| 3 | `DriverHelperController.php:124` | `return view('transport::driver_helper.show', compact('driverHelper'))` — renders show view |

### CODE-TRACE-05: edit() — Complete Code Trace

| Step | Code Line | What Happens |
|------|-----------|--------------|
| 1 | `DriverHelperController.php:132` | `Gate::authorize('tenant.driver-helper.update')` — checks update permission |
| 2 | `DriverHelperController.php:134` | `DriverHelper::findOrFail($id)` — loads existing record |
| 3 | `DriverHelperController.php:135` | `Vehicle::where('is_active', 1)->get()` — loads active vehicles |
| 4 | `DriverHelperController.php:137-145` | Employee → User query (same as create) — loads Transport-department users |
| 5 | `DriverHelperController.php:147-151` | `return view('transport::driver_helper.edit', compact('driverHelper', 'vehicles', 'users'))` — renders edit view |

### CODE-TRACE-06: update() — Complete Code Trace

| Step | Code Line | What Happens |
|------|-----------|--------------|
| 1 | `DriverHelperController.php:159` | `Gate::authorize('tenant.driver-helper.update')` — checks update permission |
| 2 | `DriverHelperController.php:161` | `$original = $driverHelper->getOriginal()` — captures current DB state |
| 3 | `DriverHelperController.php:163-166` | `$driverHelper->update([...$request->validated(), 'police_verification_done' => $request->boolean(...)])` — updates record |
| 4 | `DriverHelperController.php:169-175` | Media mapping array (same as store) |
| 5 | `DriverHelperController.php:177-185` | Loop: `if hasFile → clearMediaCollection → addMediaFromRequest → update([flag => true])` — replaces media per collection |
| 6 | `DriverHelperController.php:190-196` | `foreach ($driverHelper->getChanges() as $field => $newValue)` — builds changes array (excludes updated_at) |
| 7 | `DriverHelperController.php:199-203` | `activityLog($driverHelper, 'Updated', ['message' => 'Driver/Helper updated.', 'changes' => $changes, 'performed_by' => Auth::user()->name])` — logs update with diff |
| 8 | `DriverHelperController.php:205-207` | `redirect()->route('transport.transport-master.index')->with('success', flash('updated.driver_helper'))` — redirects |

### CODE-TRACE-07: destroy() — Complete Code Trace

| Step | Code Line | What Happens |
|------|-----------|--------------|
| 1 | `DriverHelperController.php:215` | `Gate::authorize('tenant.driver-helper.delete')` — checks delete permission |
| 2 | `DriverHelperController.php:217` | `$driverHelper->update(['is_active' => false])` — deactivates before soft-delete |
| 3 | `DriverHelperController.php:218` | `$driverHelper->delete()` — soft deletes (sets deleted_at) |
| 4 | `DriverHelperController.php:220-222` | `activityLog($driverHelper, 'Trashed', ['message' => 'Driver/Helper deactivated.'])` — logs deletion |
| 5 | `DriverHelperController.php:224-226` | `redirect()->route('transport.transport-master.index')->with('success', flash('trashed.driver_helper'))` — redirects |

### CODE-TRACE-08: trashed() — Complete Code Trace

| Step | Code Line | What Happens |
|------|-----------|--------------|
| 1 | `DriverHelperController.php:234` | `Gate::authorize('tenant.driver-helper.restore')` — checks restore permission (NOT viewAny) |
| 2 | `DriverHelperController.php:236-238` | `DriverHelper::onlyTrashed()->with(['vehicle', 'user'])->paginate(10)` — soft-deleted only, 10 per page |
| 3 | `DriverHelperController.php:240` | `return view('transport::driver_helper.trash', compact('driverHelpers'))` — renders trash view |

### CODE-TRACE-09: restore() — Complete Code Trace

| Step | Code Line | What Happens |
|------|-----------|--------------|
| 1 | `DriverHelperController.php:248` | `Gate::authorize('tenant.driver-helper.restore')` — checks restore permission |
| 2 | `DriverHelperController.php:250` | `DriverHelper::onlyTrashed()->findOrFail($id)` — finds trashed record, 404 if not trashed |
| 3 | `DriverHelperController.php:251` | `$driverHelper->restore()` — sets deleted_at to NULL (does NOT revert is_active) |
| 4 | `DriverHelperController.php:253-255` | `activityLog($driverHelper, 'Restored', ['message' => 'Driver/Helper restored.'])` — logs restore |
| 5 | `DriverHelperController.php:257-259` | `redirect()->route('transport.driver-helper.trashed')->with('success', flash('restored.driver_helper'))` — redirects back to trash |

### CODE-TRACE-10: forceDelete() — Complete Code Trace

| Step | Code Line | What Happens |
|------|-----------|--------------|
| 1 | `DriverHelperController.php:267` | `Gate::authorize('tenant.driver-helper.forceDelete')` — checks forceDelete permission |
| 2 | `DriverHelperController.php:269` | `DriverHelper::withTrashed()->findOrFail($id)` — finds ANY record (active or trashed) |
| 3 | `DriverHelperController.php:271-279` | Loop over 5 form field names: `clearMediaCollection('photo_upload')` etc. — attempts media cleanup (see BC-BIZ-DEEP-23 for gap) |
| 4 | `DriverHelperController.php:281` | `$driverHelper->forceDelete()` — permanently removes record from DB |
| 5 | `DriverHelperController.php:283-285` | `activityLog($driverHelper, 'Deleted', ['message' => 'Driver/Helper permanently deleted.'])` — logs permanent deletion |
| 6 | `DriverHelperController.php:287-289` | `redirect()->route('transport.driver-helper.trashed')->with('success', flash('force_deleted.driver_helper'))` — redirects to trash |

### CODE-TRACE-11: toggleStatus() — Complete Code Trace

| Step | Code Line | What Happens |
|------|-----------|--------------|
| 1 | `DriverHelperController.php:297` | `Gate::authorize('tenant.driver-helper.update')` — checks update permission |
| 2 | `DriverHelperController.php:299-301` | `$request->validate(['is_active' => 'required|boolean'])` — inline validation (not FormRequest) |
| 3 | `DriverHelperController.php:303` | `$driverHelper->update(['is_active' => $request->is_active])` — flips status |
| 4 | `DriverHelperController.php:305-309` | `return response()->json(['success' => true, 'is_active' => $driverHelper->is_active, 'message' => flash('status_updated.driver_helper')])` — JSON response |
| 5 | No activityLog call | **GAP**: Status changes not audited |

### CODE-TRACE-12: printIdCard() — Complete Code Trace

| Step | Code Line | What Happens |
|------|-----------|--------------|
| 1 | `DriverHelperController.php:317` | `Gate::authorize('tenant.driver-helper.view')` — checks view permission (NOT print permission) |
| 2 | `DriverHelperController.php:318` | `DriverHelper::findOrFail($id)` — finds any staff record (active, inactive, or trashed) |
| 3 | `DriverHelperController.php:320` | `TemplatePurpose::where('code', 'TRANSPORT_STAFF_ID_CARD')->first()` — queries purpose |
| 4 | `DriverHelperController.php:321` | `if (!$purpose) abort(404, "Purpose 'TRANSPORT_STAFF_ID_CARD' not found.")` — 404 if purpose missing |
| 5 | `DriverHelperController.php:323` | `$assignment = $purpose->assignments()->where('is_active', true)->first()` — checks active assignment |
| 6 | `DriverHelperController.php:324` | `if (!$assignment) abort(404, "No active template assigned for Transport Staff ID Card")` — 404 if no assignment |
| 7 | `DriverHelperController.php:326` | `$engine = app(TemplateEngine::class)` — resolves TemplateEngine service |
| 8 | `DriverHelperController.php:327` | `$html = $engine->render('TRANSPORT_STAFF_ID_CARD', [], null, null, null, null, null, ['staff_id' => $staff->id])` — renders template |
| 9 | `DriverHelperController.php:329-332` | `return view('studentprofile::student.id-card', ['student' => (object)['full_name' => $staff->name], 'html' => $html])` — returns view (reuses student profile view) |

### TC-BIZ-DEEP-61: Flash keys pattern

| BC ID | Condition | Source |
|-------|-----------|--------|
| BC-BIZ-DEEP-61 | `store()` uses `flash('created.driver_helper')` | `DriverHelperController.php:112` |
| BC-BIZ-DEEP-62 | `update()` uses `flash('updated.driver_helper')` | `DriverHelperController.php:207` |
| BC-BIZ-DEEP-63 | `destroy()` uses `flash('trashed.driver_helper')` | `DriverHelperController.php:226` |
| BC-BIZ-DEEP-64 | `restore()` uses `flash('restored.driver_helper')` | `DriverHelperController.php:259` |
| BC-BIZ-DEEP-65 | `forceDelete()` uses `flash('force_deleted.driver_helper')` | `DriverHelperController.php:289` |
| BC-BIZ-DEEP-66 | `toggleStatus()` uses `flash('status_updated.driver_helper')` | `DriverHelperController.php:308` |
| BC-BIZ-DEEP-67 | All flash keys use dotted translation pattern (`created.driver_helper`) | Consistent with Laravel localization |

### TC-BIZ-DEEP-68: Route registration details

| BC ID | Route | Method | URI | Name |
|-------|-------|--------|-----|------|
| BC-BIZ-DEEP-68 | index | GET | `/transport/driver-helper` | `transport.driver-helper.index` |
| BC-BIZ-DEEP-69 | create | GET | `/transport/driver-helper/create` | `transport.driver-helper.create` |
| BC-BIZ-DEEP-70 | store | POST | `/transport/driver-helper` | `transport.driver-helper.store` |
| BC-BIZ-DEEP-71 | show | GET | `/transport/driver-helper/{driver_helper}` | `transport.driver-helper.show` |
| BC-BIZ-DEEP-72 | edit | GET | `/transport/driver-helper/{driver_helper}/edit` | `transport.driver-helper.edit` |
| BC-BIZ-DEEP-73 | update | PUT/PATCH | `/transport/driver-helper/{driver_helper}` | `transport.driver-helper.update` |
| BC-BIZ-DEEP-74 | destroy | DELETE | `/transport/driver-helper/{driver_helper}` | `transport.driver-helper.destroy` |
| BC-BIZ-DEEP-75 | trashed | GET | `/transport/driver-helper/trash/view` | `transport.driver-helper.trashed` |
| BC-BIZ-DEEP-76 | restore | GET | `/transport/driver-helper/{id}/restore` | `transport.driver-helper.restore` |
| BC-BIZ-DEEP-77 | forceDelete | DELETE | `/transport/driver-helper/{id}/force-delete` | `transport.driver-helper.forceDelete` |
| BC-BIZ-DEEP-78 | toggleStatus | POST | `/transport/driver-helper/{driverHelper}/toggle-status` | `transport.driver-helper.toggleStatus` |
| BC-BIZ-DEEP-79 | printIdCard | GET | `/transport/driver-helper/{id}/print-id-card` | `transport.driver-helper.print-id-card` |

### TC-BIZ-DEEP-80: Update change tracking — detailed field comparison

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `$original = $driverHelper->getOriginal()` captures ALL current DB values | Array of original values |
| 2 | `$driverHelper->update([...])` changes some fields | DB updated |
| 3 | `$driverHelper->getChanges()` returns only changed fields | `['name' => 'New Name', 'phone' => 'New Phone']` |
| 4 | Loop excludes `updated_at` from change log | `if ($field !== 'updated_at')` |
| 5 | Each change logged as `['old' => original, 'new' => current]` | Full before/after per field |

### TC-BIZ-DEEP-81: Activity log performed_by consistency

| Method | performed_by included? | Source |
|--------|-----------------------|--------|
| `store()` | NO | `DriverHelperController.php:105-107` |
| `update()` | YES (`Auth::user()->name`) | `DriverHelperController.php:202` |
| `destroy()` | NO | `DriverHelperController.php:220-222` |
| `restore()` | NO | `DriverHelperController.php:253-255` |
| `forceDelete()` | NO | `DriverHelperController.php:283-285` |
| **Inconsistency**: Only `update()` includes `performed_by` | Other methods omit who performed action | |

### TC-BIZ-DEEP-82: Policy method coverage vs controller usage

| Policy Method | Permission String | Used In Controller? |
|---------------|-------------------|---------------------|
| `viewAny()` | `tenant.driver-helper.viewAny` | YES — `index()` |
| `view()` | `tenant.driver-helper.view` | YES — `show()`, `printIdCard()` |
| `status()` | `tenant.driver-helper.status` | **NO** |
| `create()` | `tenant.driver-helper.create` | YES — `create()`, `store()`, FormRequest |
| `update()` | `tenant.driver-helper.update` | YES — `edit()`, `update()`, `toggleStatus()`, FormRequest |
| `delete()` | `tenant.driver-helper.delete` | YES — `destroy()` |
| `restore()` | `tenant.driver-helper.restore` | YES — `trashed()`, `restore()` |
| `forceDelete()` | `tenant.driver-helper.forceDelete` | YES — `forceDelete()` |
| `import()` | `tenant.driver-helper.import` | **NO** |
| `export()` | `tenant.driver-helper.export` | **NO** |
| `print()` | `tenant.driver-helper.print` | **NO** (printIdCard uses `view`) |

### TC-BIZ-DEEP-83: Blade view structure and templates

| Blade File | Path | Purpose |
|------------|------|---------|
| `index.blade.php` | `driver_helper/index.blade.php` | Tab listing with search, status toggle, action buttons |
| `create.blade.php` | `driver_helper/create.blade.php` | Create form with vehicle/user dropdowns, file uploads |
| `edit.blade.php` | `driver_helper/edit.blade.php` | Edit form pre-populated with existing data |
| `show.blade.php` | `driver_helper/show.blade.php` | Detail view with all fields, media, Print ID Card button |
| `trash.blade.php` | `driver_helper/trash.blade.php` | Trashed records with Restore/ForceDelete actions |

### TC-BIZ-DEEP-84: Model constants

| Constant | Value | Usage |
|----------|-------|-------|
| `DriverHelper::ID_TYPES` | `['Aadhaar Card', 'Licence Number', 'PAN Card', 'Voter ID', 'Passport']` | Validation `Rule::in()` for `id_type` field |
| `DriverHelper::DRIVER_HELPER_TYPES` | `['Driver', 'Helper', 'Both']` | Defined but NOT used in controller — validation uses inline array instead |

### TC-BIZ-DEEP-85: `prepareForValidation()` normalization details

| Input Value | `$this->boolean()` Result | Stored Value |
|-------------|--------------------------|--------------|
| `"1"` (string) | `true` | `1` |
| `"0"` (string) | `false` | `0` |
| `"on"` (HTML checkbox) | `true` | `1` |
| `"true"` (string) | `true` | `1` |
| `"false"` (string) | `false` | `0` |
| `null` (missing field) | `false` | `0` |
| `1` (integer) | `true` | `1` |
| `0` (integer) | `false` | `0` |

---

*Template: tpt_PickupStopsList_TcList.md (Syllabus depth) | Entity: Staff (DriverHelper) | Date: 2026-07-21*
