# Device Setup (Attendance Device) — TC_List

---

## 1. Feature Information

| Attribute | Details |
|-----------|---------|
| **Module** | Transport (TPT) |
| **Tab Group** | Transport Master → Device Setup |
| **Feature** | Attendance Device Management — register devices (Mobile/Tablet/Laptop/Desktop) for driver/attendant attendance tracking |
| **URL(s)** | `/transport/transport-master` (index via tab `device_setup`), `/transport/attendance-device/create`, `/transport/attendance-device/{attendanceDevice}`, `/transport/attendance-device/{attendanceDevice}/edit`, `/transport/attendance-device/trash`, `/transport/attendance-device/{id}/restore`, `/transport/attendance-device/{id}/force-delete`, `/transport/attendance-device/{attendanceDevice}/toggle-status`, `/transport/attendance-device/update-last-seen/{deviceUuid}` |
| **Controller** | `Modules\Transport\Http\Controllers\AttendanceDeviceController` — 12 methods — ⚠️ `index()` NOT called for tab listing; standalone route only |
| **Tab Container Controller** | `Modules\Transport\Http\Controllers\TransportMasterController@index()` — tab id `device_setup`, private `attendanceDevicesQuery()` for listing |
| **Model** | `Modules\Transport\Models\AttendanceDevice` — SoftDeletes, 3 relationships, 6 scopes |
| **Validation** | `Modules\Transport\Http\Requests\AttendanceDeviceRequest` — 11 rules + conditional UUID + custom messages |
| **Permissions** | `tenant.attendance-device.*` (viewAny, view, create, update, delete, restore, forceDelete) |
| **Soft Deletes** | Yes (`SoftDeletes` trait on model) |
| **Activity Log** | All 6 CUD operations logged: `Stored`, `Updated`, `Trashed`, `Restored`, `Deleted`, `Toggled` |
| **DB Table** | `tpt_attendance_device` — 15 columns + 2 UNIQUE indexes + FK CASCADE |
| **Key Features** | Auto UUID generation with uniqueness check across trashed records, `updateLastSeen` endpoint by UUID (not ID), Dropdown-based device_type/device_os FK, change tracking in update(), is_active=false before soft-delete |
| **Known Gaps** | Variable name mismatch (index), DDL device_type ENUM vs code Dropdown FK, 3 DDL NOT NULL columns nullable in request, no DB::transaction wrapping in any CUD method |

---

## 2. Pre-conditions

| # | Pre-condition |
|---|--------------|
| PC-01 | User must have `tenant.attendance-device.*` permissions |
| PC-02 | `tpt_personnel` must have at least one record for device assignment (FK `fk_attendance_device_user`) |
| PC-03 | `sys_dropdown_table` must have records for `tpt_attendance_device.device_type.type` and `tpt_attendance_device.device_os.type` |
| PC-04 | Tab id `device_setup-pane` registered in transportmaster.blade.php |
| PC-05 | Migration must run with ENUM('Desktop','Laptop','Mobile','Tablet') for `device_type` (see BC-CR-02 GAP) |
| PC-06 | `activityLog()` helper function must be globally available |
| PC-07 | `flash()` helper must have keys: `created.attendance_device`, `updated.attendance_device`, `trashed.attendance_device`, `restored.attendance_device`, `force_deleted.attendance_device`, `status_updated.attendance_device` |
| PC-08 | At least one `tpt_personnel` record for `DriverHelper::get()` to populate user dropdown |
| PC-09 | Device UUID uniqueness enforced at DB level via `uq_device` and `uq_user_device` unique indexes |
| PC-10 | Soft deletes enabled: `deleted_at` TIMESTAMP NULL column present in DDL |

---

## 3. Default Data Load

| # | Data Load Rule | Source |
|---|----------------|--------|
| DL-01 | Devices loaded with eager loading: `deviceType:id,value`, `operatingSystem:id,value`, `user:id,name` | `AttendanceDeviceController.php:24-28` |
| DL-02 | Pagination: 10 records per page | `AttendanceDeviceController.php:36` |
| DL-03 | Table columns: Device Name, Device Type (dropdown label), Location, Status (toggle switch), Action | `attendance_device/index.blade.php:53-58` |
| DL-04 | Search filter: device_name OR device_uuid `like %search%` | `AttendanceDeviceController.php:29-31` |
| DL-05 | Status filter: `is_active` = 1 or 0 | `AttendanceDeviceController.php:33-35` |
| DL-06 | Status toggle via `<x-backend.table.status-switch>` component | `attendance_device/index.blade.php:75-77` |
| DL-07 | No UUID, OS version, FCM token columns displayed in index table | `attendance_device/index.blade.php` |
| DL-08 | `$transportDriveStaff` loaded for create/edit form dropdown from `DriverHelper::get()` | `AttendanceDeviceController.php:39` |
| DL-09 | **BUG**: Controller sends `$devices` variable but blade expects `$attendanceDevices` | `AttendanceDeviceController.php:42` vs `attendance_device/index.blade.php:64` |
| DL-10 | `attendance_device/show.blade.php` renders single device with deviceType/operatingSystem/user relationships | `AttendanceDeviceController.php:97` |
| DL-11 | `attendance_device/trash.blade.php` shows only soft-deleted devices, paginated at 10 per page | `AttendanceDeviceController.php:184` |
| DL-12 | `attendance_device/create.blade.php` renders Device Type/OS as dropdowns from `sys_dropdown_table` via `<x-backend.form.form-dropdown>` | Blade component |
| DL-13 | `attendance_device/edit.blade.php` pre-selects current values for all dropdowns, UUID shown as read-only text | Edit blade |
| DL-14 | `paginate(10)->withQueryString()` preserves search/status filter params in pagination links | `AttendanceDeviceController.php:36-37` |

---

## 4. Test Data Strategy

| # | Data Strategy | Details |
|---|---------------|---------|
| TD-01 | **Valid Device** | device_name="Driver Mobile-1", user_id=valid personnel, device_type=Mobile (Dropdown FK), device_os=Android (Dropdown FK), os_version="12.0", device_model="Samsung Galaxy" |
| TD-02 | **Auto UUID** | Submit without device_uuid → auto-generated via `Str::uuid()` loop |
| TD-03 | **Duplicate UUID** | Same UUID across 2 records → unique violation |
| TD-04 | **Duplicate user+UUID** | Same user_id + device_uuid → composite unique violation |
| TD-05 | **Non-nullable DDL column gets null** | Insert null for os_version, pg_fcm_token, device_model (nullable in request but NOT NULL in migration) → **GAP** |
| TD-06 | **Toggle status** | Device with is_active=1 → toggle to 0 → verify DB and JSON response |
| TD-07 | **Soft delete + restore cycle** | Create → delete → verify trashed → restore → verify active again (is_active remains false) |
| TD-08 | **Force delete trashed** | Soft delete first → force delete → verify permanently removed |
| TD-09 | **updateLastSeen by UUID** | Call endpoint with valid device_uuid → verify pg_last_seen_at updated |
| TD-10 | **updateLastSeen invalid UUID** | Fake UUID → 404 JSON response |
| TD-11 | **Change tracking on update** | Update device_name + location → verify activityLog captures both old and new values |
| TD-12 | **DDL ENUM vs Dropdown FK** | Attempt to create with device_type=1 (integer FK) → DDL expects ENUM string → **CRITICAL GAP** |
| TD-13 | **Permission boundaries** | User with viewAny only → can list but cannot create/edit/delete |
| TD-14 | **UUID uniqueness across trashed** | Create device → soft delete → create same UUID → controller do-while blocks due to `withTrashed()` check |

---

## 5. Business Conditions (BC)

### BC-DB: Database Conditions

| BC ID | Column | Type (Migration) | Constraints |
|-------|--------|------------------|-------------|
| BC-DB-01 | `id` | INT UNSIGNED AUTO_INCREMENT | PK |
| BC-DB-02 | `device_uuid` | CHAR(36) | NOT NULL, UNIQUE (`uq_device`) |
| BC-DB-03 | `device_type` | ENUM('Desktop','Laptop','Mobile','Tablet') | NOT NULL — **GAP**: Code treats as INT FK to dropdown |
| BC-DB-04 | `device_os` | INTEGER | NOT NULL — FK via code to `sys_dropdown_table` |
| BC-DB-05 | `os_version` | VARCHAR(50) | **NOT NULL** in DDL but nullable in request — **GAP** |
| BC-DB-06 | `device_name` | VARCHAR(100) | NOT NULL |
| BC-DB-07 | `device_model` | VARCHAR(100) | **NOT NULL** in DDL but nullable in request — **GAP** |
| BC-DB-08 | `pg_app_version` | VARCHAR(20) | NOT NULL in DDL |
| BC-DB-09 | `pg_fcm_token` | TEXT | **NOT NULL** in DDL but nullable in request — **GAP** |
| BC-DB-10 | `location` | VARCHAR(150) | NULLABLE |
| BC-DB-11 | `pg_first_registered_at` | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |
| BC-DB-12 | `pg_last_seen_at` | TIMESTAMP NULL | Nullable, updated on device activity |
| BC-DB-13 | `is_active` | BOOLEAN/TINYINT | DEFAULT true, NOT NULL |
| BC-DB-14 | `user_id` | INT UNSIGNED | FK → `tpt_personnel.id` ON DELETE CASCADE |
| BC-DB-15 | UNIQUE INDEX `uq_device` | (device_uuid) | One device per UUID globally |
| BC-DB-16 | UNIQUE INDEX `uq_user_device` | (user_id, device_uuid) | One device per user per UUID |
| BC-DB-17 | FK `fk_attendance_device_user` | CASCADE | Deleting personnel deletes device |
| BC-DB-18 | INDEX `idx_attendance_device_user` | (user_id) | Efficient user-based lookups |
| BC-DB-19 | `deleted_at` | TIMESTAMP NULL | Soft delete support |
| BC-DB-20 | `created_at` | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |
| BC-DB-21 | `updated_at` | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP ON UPDATE |

### BC-VAL: Validation Conditions

| BC ID | Field | Rule | Source |
|-------|-------|------|--------|
| BC-VAL-01 | `user_id` | required, integer, exists:tpt_personnel,id | `AttendanceDeviceRequest.php:22-26` |
| BC-VAL-02 | `device_name` | required, string, max:100 | `AttendanceDeviceRequest.php:28-32` |
| BC-VAL-03 | `device_type` | required, integer, exists:sys_dropdown_table,id | `AttendanceDeviceRequest.php:34-38` — **GAP**: DDL expects ENUM string |
| BC-VAL-04 | `device_os` | required, integer, exists:sys_dropdown_table,id | `AttendanceDeviceRequest.php:40-44` |
| BC-VAL-05 | `os_version` | nullable, string, max:50 | `AttendanceDeviceRequest.php:46` — **GAP**: DDL NOT NULL |
| BC-VAL-06 | `device_model` | nullable, string, max:100 | `AttendanceDeviceRequest.php:47` — **GAP**: DDL NOT NULL |
| BC-VAL-07 | `pg_app_version` | nullable, string, max:20 | `AttendanceDeviceRequest.php:48` |
| BC-VAL-08 | `pg_fcm_token` | nullable, string | `AttendanceDeviceRequest.php:49` — **GAP**: DDL NOT NULL |
| BC-VAL-09 | `location` | nullable, string, max:150 | `AttendanceDeviceRequest.php:50` |
| BC-VAL-10 | `is_active` | sometimes, boolean | `AttendanceDeviceRequest.php:51` |
| BC-VAL-11 | `device_uuid` | NOT in rules array (no validation rules for store) | Handled only in controller do-while loop |

### BC-VAL-CUSTOM: Validation Behaviors

| BC ID | Behavior | Explanation | Source |
|-------|----------|-------------|--------|
| BC-VAL-C01 | `prepareForValidation()` normalizes is_active | `$this->merge(['is_active' => $this->boolean('is_active')])` converts "on"/"1"/true to boolean | `AttendanceDeviceRequest.php:64-69` |
| BC-VAL-C02 | device_uuid NOT validated by FormRequest | The field `device_uuid` is absent from `$rules` — controller handles via do-while loop | `AttendanceDeviceRequest.php:21-61` |
| BC-VAL-C03 | Unique validation on device_uuid for update | Only conditionally applied: if changing UUID, line 56-58 removes unique rule if UUID unchanged | `AttendanceDeviceRequest.php:55-59` |
| BC-VAL-C04 | Custom error messages defined | `device_uuid.unique`, `user_id.exists`, `device_type.exists`, `device_os.exists` | `AttendanceDeviceRequest.php:71-79` |
| BC-VAL-C05 | Double authorization: controller Gate + FormRequest authorize | `store()` has `Gate::authorize()` (line 62) AND `AttendanceDeviceRequest::authorize()` (line 13-17) | Both layers |

### BC-AUTH: Authorization Conditions

| BC ID | Permission | Controller Method | Source |
|-------|-----------|-------------------|--------|
| BC-AUTH-01 | `tenant.attendance-device.viewAny` | `index()` — Gate present | `AttendanceDeviceController.php:22` |
| BC-AUTH-02 | `tenant.attendance-device.create` | `create()` + `store()` — Gate present in both | `AttendanceDeviceController.php:52,62` |
| BC-AUTH-03 | `tenant.attendance-device.view` | `show()` — Gate present | `AttendanceDeviceController.php:95` |
| BC-AUTH-04 | `tenant.attendance-device.update` | `edit()` + `update()` + `toggleStatus()` + `updateLastSeen()` — Gate present | `AttendanceDeviceController.php:110,125,237,263` |
| BC-AUTH-05 | `tenant.attendance-device.delete` | `destroy()` — Gate present | `AttendanceDeviceController.php:162` |
| BC-AUTH-06 | `tenant.attendance-device.restore` | `trashed()` + `restore()` — Gate present | `AttendanceDeviceController.php:182,197` |
| BC-AUTH-07 | `tenant.attendance-device.forceDelete` | `forceDelete()` — Gate present | `AttendanceDeviceController.php:217` |
| BC-AUTH-08 | **Double auth on store()** | Controller Gate (line 62) + FormRequest authorize (line 13) — redundant but not harmful | Both layers |

### BC-BIZ-DEEP: Business Conditions — Model & Behavior Deep Dives


#### BC-BIZ-DEEP-01: Model table and fillable fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `AttendanceDevice.php:15` | `protected $table = 'tpt_attendance_device'` |
| 2 | Open `AttendanceDevice.php:17-31` | 13 fillable fields: user_id, device_uuid, device_name, device_type, device_os, os_version, device_model, pg_app_version, pg_fcm_token, location, pg_first_registered_at, pg_last_seen_at, is_active |
| 3 | Verify DDL columns NOT in fillable | `id`, `created_at`, `updated_at`, `deleted_at` are NOT in fillable — correct |

#### BC-BIZ-DEEP-02: Model casts

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `AttendanceDevice.php:33-37` | `is_active` → `boolean`, `pg_first_registered_at` → `datetime`, `pg_last_seen_at` → `datetime` |
| 2 | Query: `$device->is_active` where DB=1 | Returns `true` (boolean, not int) |
| 3 | Query: `$device->pg_first_registered_at` | Returns Carbon instance |

#### BC-BIZ-DEEP-03: Model relationships

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `AttendanceDevice.php:40-43` | `user()` — `belongsTo(DriverHelper::class, 'user_id')` |
| 2 | Open `AttendanceDevice.php:45-48` | `deviceType()` — `belongsTo(Dropdown::class, 'device_type')` — **GAP**: DDL is ENUM, code treats as FK |
| 3 | Open `AttendanceDevice.php:60-63` | `operatingSystem()` — `belongsTo(Dropdown::class, 'device_os')` |
| 4 | Eager loading in index(): `->with(['deviceType:id,value', 'operatingSystem:id,value', 'user:id,name'])` | Selects only needed columns |

#### BC-BIZ-DEEP-04: Model accessors

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `getDeviceTypeLabelAttribute()` | Returns `$this->deviceType?->value` (e.g., "Mobile") |
| 2 | `getDeviceOsLabelAttribute()` | Returns `$this->operatingSystem?->value` (e.g., "Android") |
| 3 | `getStatusAttribute()` | Returns 'Active' if `is_active=true`, else 'Inactive' |

#### BC-BIZ-DEEP-05: Model scopes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `scopeActive` | `$query->where('is_active', true)` |
| 2 | `scopeByDeviceType($type)` | `$query->where('device_type', $type)` |
| 3 | `scopeByUser($userId)` | `$query->where('user_id', $userId)` |
| 4 | `scopeMobileDevices` | `whereHas('deviceType', fn => where('value', 'Mobile'))` |
| 5 | `scopeByOperatingSystem($osId)` | `$query->where('device_os', $osId)` |

#### BC-BIZ-DEEP-06: Model helper methods

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `markAsSeen()` | `$this->update(['pg_last_seen_at' => now()])` — returns `$this` |
| 2 | `getDeviceTypes()` | `Dropdown::where('type', 'tpt_attendance_device.device_type.type')->get()` |
| 3 | `getDeviceOS()` | `Dropdown::where('type', 'tpt_attendance_device.device_os.type')->get()` |

#### BC-BIZ-DEEP-07: index() — Gate authorization

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `AttendanceDeviceController.php:22` | `Gate::authorize('tenant.attendance-device.viewAny')` |
| 2 | User without `viewAny` permission | 403 Forbidden response |
| 3 | User with `viewAny` permission | Proceeds to query execution |

#### BC-BIZ-DEEP-08: index() — Eager loading

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `with(['deviceType:id,value','operatingSystem:id,value','user:id,name'])` | 3 eager load queries |
| 2 | deviceType query | `SELECT id, value FROM sys_dropdown_table WHERE id IN (...)` |
| 3 | operatingSystem query | `SELECT id, value FROM sys_dropdown_table WHERE id IN (...)` |
| 4 | user query | `SELECT id, name FROM tpt_personnel WHERE id IN (...)` |

#### BC-BIZ-DEEP-09: index() — Search filter

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `when($request->search, fn => ...)` | `WHERE device_name LIKE '%search%' OR device_uuid LIKE '%search%'` |
| 2 | No search param | No WHERE clause added |

#### BC-BIZ-DEEP-10: index() — Status filter

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `when($request->filled('status'), fn => ...)` | `WHERE is_active = $request->status` |
| 2 | `?status=1` | Only active devices |
| 3 | `?status=0` | Only inactive devices |
| 4 | No status param | Shows both active and inactive |

#### BC-BIZ-DEEP-11: index() — Pagination

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `->paginate(10)->withQueryString()` | 10 records per page |
| 2 | Records = 25 | 3 pages with query string params preserved |

#### BC-BIZ-DEEP-12: index() — Variable name mismatch BUG

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `compact('devices', 'transportDriveStaff')` | **BUG**: should be `$attendanceDevices` |
| 2 | Blade: `@forelse($attendanceDevices as $device)` | Expects `$attendanceDevices` — **Undefined variable error** |
| 3 | `trashed()` line 184 uses `$attendanceDevices` | Consistent naming — unlike index() |

#### BC-BIZ-DEEP-13: index() — transportDriveStaff

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `$transportDriveStaff = DriverHelper::get()` | Loads personnel list for user dropdown |
| 2 | Used in index, create, edit views | Assigned User dropdown population |

#### BC-BIZ-DEEP-14: create() — Gate and view

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `Gate::authorize('tenant.attendance-device.create')` | Authorization |
| 2 | `view('...create', compact('transportDriveStaff'))` | Create form with all device fields |

#### BC-BIZ-DEEP-15: store() — Authorization + validation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `Gate::authorize(...)` + FormRequest authorize | Double authorization |
| 2 | `$data = $request->validated()` | Only validated fields returned |

#### BC-BIZ-DEEP-16: store() — UUID auto-generation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `do...while` with `Str::uuid()` | Generates unique UUID v4 |
| 2 | `withTrashed()->where('device_uuid', ...)->exists()` | Checks across ALL records including trashed |
| 3 | Collision → loop regenerates | Guaranteed unique UUID |

#### BC-BIZ-DEEP-17: store() — pg_last_seen_at and is_active

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `$data['pg_last_seen_at'] = now()` | Set on creation |
| 2 | `$data['is_active'] = $data['is_active'] ?? true` | Defaults to true if not provided |

#### BC-BIZ-DEEP-18: store() — DB insert and activity log

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `AttendanceDevice::create($data)` | INSERT query |
| 2 | `activityLog($device, 'Stored', ...)` | Activity log entry created |
| 3 | Redirect with flash | Success message |

#### BC-BIZ-DEEP-19: store() — No DB::transaction (GAP)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Search for `DB::beginTransaction()` | NOT found in any method |
| 2 | create + activityLog not atomic | **GAP**: server crash creates row without audit |

#### BC-BIZ-DEEP-20: store() — DDL ENUM vs Dropdown FK CRITICAL GAP

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | DDL: ENUM('Desktop','Laptop','Mobile','Tablet') | Expects string value |
| 2 | Request: `exists:sys_dropdown_table,id` | Expects integer FK |
| 3 | Insert with device_type=1 | **CRITICAL ERROR**: ENUM column rejects integer |
| 4 | Fix: change DDL or change code | All device creation blocked |

#### BC-BIZ-DEEP-21: store() — DDL NOT NULL vs nullable GAP

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | os_version, device_model, pg_fcm_token are DDL NOT NULL | Request rules say nullable |
| 2 | Submit null for all 3 → validation passes | But DB INSERT crashes |
| 3 | **Impact**: 3 columns mismatch | Form passes validation but DB rejects |

#### BC-BIZ-DEEP-22: show() — Gate and route model binding

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `AttendanceDevice $attendanceDevice` | Route-model-binding auto-resolves |
| 2 | `Gate::authorize('tenant.attendance-device.view')` | Authorization |
| 3 | `$attendanceDevice->load(['deviceType','operatingSystem','user'])` | Lazy loads 3 relationships |

#### BC-BIZ-DEEP-23: show() — Lazy loading vs eager

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | show() loads ALL columns for each relation | Heavier than index() which selects id,value only |
| 2 | deviceType/operatingSystem/user queries | Single-record lookups via WHERE id = ? |

#### BC-BIZ-DEEP-24: edit() — Gate and data

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `Gate::authorize('tenant.attendance-device.update')` | Authorization |
| 2 | `compact('attendanceDevice','transportDriveStaff')` | Pre-filled edit form |
| 3 | UUID shown as read-only | Immutable after creation |

#### BC-BIZ-DEEP-25: update() — Original data capture

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `$original = $attendanceDevice->getOriginal()` | Captures pre-update state |
| 2 | `$data = $request->validated()` | Validated input |

#### BC-BIZ-DEEP-26: update() — pg_last_seen_at comment contradiction

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Comment: "only if provided" | Code: `$data['pg_last_seen_at'] = now()` — always runs |
| 2 | Editing device_name only | Also updates pg_last_seen_at (side effect) |

#### BC-BIZ-DEEP-27: update() — Change tracking

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `foreach ($attendanceDevice->getChanges() as $field => $value)` | Iterates actually-changed fields |
| 2 | `if ($field === 'updated_at') continue;` | Excludes auto-timestamp |
| 3 | `$changes[$field] = ['old' => $original[$field], 'new' => $value]` | Old/new pair per changed field |
| 4 | No changes → `$changes = []` → stored as null | Clean activity log |

#### BC-BIZ-DEEP-28: update() — Activity log and redirect

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `activityLog(..., 'Updated', ['changes' => ...])` | Full change tracking logged |
| 2 | Redirect with `flash('updated.attendance_device')` | Success |

#### BC-BIZ-DEEP-29: destroy() — Gate and deactivation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `Gate::authorize('tenant.attendance-device.delete')` | Authorization |
| 2 | `$attendanceDevice->update(['is_active' => false])` | Deactivates before delete |
| 3 | `$attendanceDevice->delete()` | Soft delete |
| 4 | `activityLog(..., 'Trashed', ...)` | Trash event logged |

#### BC-BIZ-DEEP-30: destroy() — Route model binding safety

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `AttendanceDevice $attendanceDevice` | Auto-resolved, auto-404 on invalid ID |
| 2 | No manual findOrFail needed | Guaranteed non-null |

#### BC-BIZ-DEEP-31: trashed() — Gate and query

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `Gate::authorize('tenant.attendance-device.restore')` | Authorization |
| 2 | `onlyTrashed()->paginate(10)` | Soft-deleted records only, 10 per page |
| 3 | Variable: `$attendanceDevices` | **Consistent** with blade (unlike index bug) |

#### BC-BIZ-DEEP-32: restore() — Gate and findOrFail

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `Gate::authorize('tenant.attendance-device.restore')` | Authorization |
| 2 | `onlyTrashed()->findOrFail($id)` | Only finds soft-deleted |
| 3 | `$device->restore()` | Sets deleted_at = NULL |

#### BC-BIZ-DEEP-33: restore() — is_active stays false

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | After restore: `is_active` remains 0 | Not auto-re-enabled |
| 2 | User must manually toggle active | Post-restore step required |

#### BC-BIZ-DEEP-34: forceDelete() — Gate and correct withTrashed()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `Gate::authorize('tenant.attendance-device.forceDelete')` | Authorization |
| 2 | `withTrashed()->findOrFail($id)` | **CORRECT** — finds both active and trashed |
| 3 | `$device->forceDelete()` | Permanent deletion |

#### BC-BIZ-DEEP-35: forceDelete() — Activity log

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `activityLog($device, 'Deleted', ...)` | Deleted event logged |
| 2 | Direct permanent deletion allowed | No prior soft-delete required |

#### BC-BIZ-DEEP-36: toggleStatus() — Gate and inline validation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `Gate::authorize('tenant.attendance-device.update')` | Authorization |
| 2 | `$request->validate(['is_active' => 'required|boolean'])` | Inline validation, NOT FormRequest |
| 3 | Missing/Invalid is_active | Validation error returned |

#### BC-BIZ-DEEP-37: toggleStatus() — Update and JSON response

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `$attendanceDevice->is_active = $request->is_active; $attendanceDevice->save()` | Property set and save |
| 2 | `activityLog(..., 'Toggled', ...)` | Toggle event logged |
| 3 | JSON: `{success: true, is_active: bool, message: ...}` | 200 OK response |

#### BC-BIZ-DEEP-38: updateLastSeen() — Gate and UUID query

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `Gate::authorize('tenant.attendance-device.update')` | Authorization |
| 2 | `where('device_uuid', $deviceUuid)->first()` | Lookup by UUID string, not ID |
| 3 | Uses `first()` not `findOrFail()` | Manual null check |

#### BC-BIZ-DEEP-39: updateLastSeen() — Success and 404

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Device found → update pg_last_seen_at | JSON success 200 |
| 2 | Device not found → 404 JSON | `{success: false, message: 'Device not found'}` |
| 3 | No activity log for this endpoint | Correct — system heartbeat |

#### BC-BIZ-DEEP-40: Model SoftDeletes trait

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `use SoftDeletes;` | Trait included |
| 2 | `delete()` sets `deleted_at` | Soft delete |
| 3 | `withTrashed()` includes all | Both active and deleted |
| 4 | `onlyTrashed()` excludes active | Only deleted |

#### BC-BIZ-DEEP-41: Dropdown FK relationship

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `deviceType()`: `belongsTo(Dropdown::class, 'device_type')` | FK to sys_dropdown_table |
| 2 | `device_type` DDL is ENUM but FK expects INT | **MISMATCH** |

#### BC-BIZ-DEEP-42: ActivityLog coverage

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | All 6 mutation methods logged | Stored, Updated, Trashed, Restored, Deleted, Toggled |
| 2 | updateLastSeen NOT logged | Correct — automated |
| 3 | Read methods NOT logged | Correct — read-only |

#### BC-BIZ-DEEP-43: Permission granularity

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | 7 distinct permissions | viewAny, view, create, update, delete, restore, forceDelete |
| 2 | Each maps to specific methods | Clean authorization model |

#### BC-BIZ-DEEP-44: No device_uuid validation rule

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | device_uuid absent from `$rules` | No FormRequest validation |
| 2 | Controller do-while handles uniqueness | UUID managed in controller |

#### BC-BIZ-DEEP-45: prepareForValidation — is_active

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `$this->boolean('is_active')` | Normalizes checkbox value |
| 2 | "on", "1", true → true | Consistent boolean input |

#### BC-BIZ-DEEP-46: Conditional UUID unique on update

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | If UUID unchanged → remove unique rule | Line 55-59 |
| 2 | Compares request UUID with model UUID | Only validates if changed |

#### BC-BIZ-DEEP-47: Str::uuid() generation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | UUID v4 format: xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx | 36 chars |
| 2 | Unique check across trashed records | Full coverage |

#### BC-BIZ-DEEP-48: Index — zero results edge case

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Search returns no matches | Empty paginator |
| 2 | `@forelse` / `@empty` handles empty | No errors |

#### BC-BIZ-DEEP-49: show() — All fields displayed

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Device Type, OS labels via relationship | Dropdown values displayed |
| 2 | User name, UUID, status, all fields | Complete detail view |

#### BC-BIZ-DEEP-50: edit() — UUID read-only

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | UUID field disabled/read-only | Immutable |
| 2 | FormRequest checks UUID unchanged | Consistency |

#### BC-BIZ-DEEP-51: getChanges() logic

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Only truly changed fields captured | Diff between original and new |
| 2 | Field with same value NOT in getChanges | No false positives |
| 3 | updated_at explicitly excluded | Clean audit |

#### BC-BIZ-DEEP-52: Changes array in activity log

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `['device_name' => ['old' => 'Old', 'new' => 'New']]` | Structured format |
| 2 | No changes → `changes => null` | Clean activity entry |

#### BC-BIZ-DEEP-53: Force delete on active record

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `withTrashed()` finds active record | Direct permanent deletion |
| 2 | No prior soft-delete needed | Works on both states |

#### BC-BIZ-DEEP-54: toggleStatus() — route-model-binding

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `{attendanceDevice}` auto-resolved | Auto 404 on invalid ID |
| 2 | `save()` after property set | Updates is_active only |

#### BC-BIZ-DEEP-55: updateLastSeen() — no binding

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `$deviceUuid` is string param | Manual query by UUID |
| 2 | First()+null check vs findOrFail() | Manual 404 handling |

#### BC-BIZ-DEEP-56: No DB::transaction in any CUD

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check store, update, destroy, restore, forceDelete, toggleStatus | NONE have DB::beginTransaction() |
| 2 | **Impact**: no atomicity | Crash risk between operation and log |

#### BC-BIZ-DEEP-57: Inconsistent parameter handling

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | destroy uses route-model-binding | `AttendanceDevice $attendanceDevice` |
| 2 | restore/forceDelete use manual $id | `$id` parameter |
| 3 | updateLastSeen uses string $deviceUuid | String parameter |

#### BC-BIZ-DEEP-58: Flash messages use flash() helper

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | All 6 success messages use `flash('key')` | Translatable pattern |
| 2 | Keys: created, updated, trashed, restored, force_deleted, status_updated | Consistent naming |

#### BC-BIZ-DEEP-59: pg_first_registered_at — DEFAULT

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | DDL: DEFAULT CURRENT_TIMESTAMP | Auto-set on INSERT |
| 2 | Not explicitly set by controller | Uses DB default |

#### BC-BIZ-DEEP-60: pg_last_seen_at — Three update points

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | store(): `now()` on create | Set on creation |
| 2 | update(): `now()` on every edit | Always overwritten |
| 3 | updateLastSeen(): independent endpoint | Heartbeat mechanism |

#### BC-BIZ-DEEP-61: uq_user_device composite unique

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | (user_id, device_uuid) | One device per user per UUID |
| 2 | Controller only checks UUID globally | Composite not pre-checked |

#### BC-BIZ-DEEP-62: FK CASCADE on user delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | ON DELETE CASCADE | Devices hard-deleted when user deleted |
| 2 | Bypasses soft-delete | DB-level deletion |

#### BC-BIZ-DEEP-63: Blade @forelse variable

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `@forelse($attendanceDevices as $device)` | Blade expects `$attendanceDevices` |
| 2 | Controller sends `$devices` | **BUG**: variable name mismatch |

#### BC-BIZ-DEEP-64: Status toggle AJAX flow

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User clicks toggle | AJAX POST to toggle-status |
| 2 | Inline validation + save | JSON response 200 |

#### BC-BIZ-DEEP-65: trashed() consistent naming

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `$attendanceDevices` in trashed() | Matches blade expectation |
| 2 | Contrast with index() BUG | Inconsistent naming across methods |

#### BC-BIZ-DEEP-66: Action column permissions

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `@can('tenant.attendance-device.view')` | Show icon conditional |
| 2 | `@can('tenant.attendance-device.update')` | Edit icon conditional |
| 3 | `@can('tenant.attendance-device.delete')` | Delete icon conditional |

#### BC-BIZ-DEEP-67: Device Type/OS labels

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `$device->deviceType?->value` | Dropdown label displayed |
| 2 | **GAP**: DDL ENUM vs FK mismatch | Display logic depends on relationship |

#### BC-BIZ-DEEP-68: Search + status + pagination

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | All params combined: `?search=...&status=1&page=2` | Works simultaneously |
| 2 | `withQueryString()` preserves params | All links functional |

#### BC-BIZ-DEEP-69: store vs update is_active

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | store: `?? true` defaults to true | New device active by default |
| 2 | update: key may be absent | DB field unchanged if not sent |

#### BC-BIZ-DEEP-70: create vs update permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User with create only | Cannot edit |
| 2 | User with update only | Cannot create |

#### BC-BIZ-DEEP-71: UUID optional in form, required in DDL

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Form: optional text input | Controller auto-generates when empty |
| 2 | DDL: CHAR(36) NOT NULL | DB requires value |

#### BC-BIZ-DEEP-72: Index columns NOT shown

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Hidden: uuid, os_version, model, app_version, fcm_token, registered_at, last_seen_at, user_id, device_os | 9 columns not displayed |
| 2 | Rationale: detail view for full data | List view is minimal |

#### BC-BIZ-DEEP-73: No auto-reactivate after restore

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | is_active stays 0 after restore | Manual toggle needed |
| 2 | Different from some other modules | Intentional design |

#### BC-BIZ-DEEP-74: Toggle event 'Toggled'

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Distinct event type for status changes | Not 'Updated' |
| 2 | Logged with performed_by | Full audit trail |

#### BC-BIZ-DEEP-75: FormDropdown key convention

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `key="tpt_attendance_device.device_type.type"` | Queries sys_dropdown_table |
| 2 | `key="tpt_attendance_device.device_os.type"` | Same pattern for OS |

#### BC-BIZ-DEEP-76: Soft-delete no cascade

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | No FKs reference tpt_attendance_device | No child entities affected |
| 2 | Only FK CASCADE from tpt_personnel | Parent deletion cascades |

#### BC-BIZ-DEEP-77: Consistent pagination (10/page)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | index(): `paginate(10)` | 10 per page |
| 2 | trashed(): `paginate(10)` | 10 per page |

#### BC-BIZ-DEEP-78: Device UUID CHAR(36)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Fixed 36-char for UUID v4 | Standard format |
| 2 | No length validation for user-supplied UUID | But DB column is fixed size |

#### BC-BIZ-DEEP-79: All 4 string columns DDL NOT NULL mismatch

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | os_version, device_model, pg_app_version, pg_fcm_token | All NOT NULL in DDL |
| 2 | All nullable in request | Systematic validation gap |

#### BC-BIZ-DEEP-80: Blade `required="true"` on UUID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Blade says required | Client-side validation |
| 2 | Controller auto-generates when empty | Actually optional |

#### BC-BIZ-DEEP-81: `forgot password` not applicable

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Device entity has no auth | No password field |

#### BC-BIZ-DEEP-82: No system_defined guard

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | No is_system_defined column | All devices editable/deletable |

#### BC-BIZ-DEEP-83: toggleStatus uses save() not update()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `$model->prop = val; $model->save()` | Alternative to update() |
| 2 | Both achieve same result | Style preference |

#### BC-BIZ-DEEP-84: `sometimes` rule for is_active

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Validates only when present | Conditional validation |
| 2 | `prepareForValidation()` normalizes | Consistent boolean type |

#### BC-BIZ-DEEP-85: No unique validation for device_uuid in request

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | UNIQUE not in rules array | DB uniquely enforces |
| 2 | Controller do-while prevents duplicate | Protection at application layer |

#### BC-BIZ-DEEP-86: index — orWhere UUID search

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `orWhere('device_uuid', 'like', ...)` | Search also scans UUID |
| 2 | Both name and UUID searchable | User convenience |

#### BC-BIZ-DEEP-87: Controller does NOT set pg_first_registered_at

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Field not in $data assignment | DDL DEFAULT applies |
| 2 | Fillable includes it though | Can be set if provided via request |

#### BC-BIZ-DEEP-88: markAsSeen() helper unused

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Model has `markAsSeen()` method | Available but not called in controller |
| 2 | Controller uses inline update instead | Manual approach |

#### BC-BIZ-DEEP-89: Activity log performed_by uses name

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `Auth::user()->name` | User's name stored in log |
| 2 | Consistent across all 6 events | Audit trail |

#### BC-BIZ-DEEP-90: No Gate in Request authorize fallback

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Non-POST/PUT methods fallback to update | Safe default |
| 2 | GET requests get update permission check | Conservative approach |

### BC-REF: Reference & UI Conditions

| BC ID | Condition | Source |
|-------|-----------|--------|
| BC-REF-01 | Tab id `device_setup-pane`, hidden `tab=device_setup` | `attendance_device/index.blade.php:2,15` |
| BC-REF-02 | Device Type displayed via `$device->deviceType?->value` (dropdown label) | `attendance_device/index.blade.php:69` |
| BC-REF-03 | Status toggle via `<x-backend.table.status-switch>` component | `attendance_device/index.blade.php:75-77` |
| BC-REF-04 | Create form: Device Name, Device OS (dropdown), Device Type (dropdown), UUID (text, optional), Device Model, OS Version, App Version, FCM Token, First Registered At, Location (textarea), Assigned User (select), Status toggle | `attendance_device/create.blade.php` |
| BC-REF-05 | Device Type/OS loaded from `sys_dropdown_table` via `<x-backend.form.form-dropdown key="...">` | `attendance_device/create.blade.php:51,56` |
| BC-REF-06 | Device UUID input is `required="true"` in blade but controller auto-generates if empty | `attendance_device/create.blade.php:70` vs `AttendanceDeviceController.php:68` |
| BC-REF-07 | `$transportDriveStaff` from `DriverHelper::get()` populates user dropdown | `AttendanceDeviceController.php:39` |
| BC-REF-08 | Show view displays all fields read-only with relationship labels | `attendance_device/show.blade.php` |
| BC-REF-09 | Edit view pre-selects current dropdown values, UUID displayed as read-only text | `attendance_device/edit.blade.php` |
| BC-REF-10 | Trash view: only soft-deleted devices, restore and force-delete action buttons | `attendance_device/trash.blade.php` |

---

## 6. Test Case List

### TC-P: Positive Test Cases

| ID | Test Case | Summary | Expected Result |
|----|-----------|---------|-----------------|
| TC-P-01 | Create device with auto UUID | Submit without UUID → auto-generated | Created, activityLog "Stored", pg_last_seen_at=now |
| TC-P-02 | Create device with explicit UUID | Provide specific UUID | Stored with that UUID |
| TC-P-03 | Create device with all optional fields | Fill FCM token, app version, model, etc. | All fields saved |
| TC-P-04 | Edit device_name | Change name | Updated, change tracking captures old/new |
| TC-P-05 | Toggle status ON→OFF | Click status toggle | AJAX success, is_active=0 |
| TC-P-06 | Update last seen via UUID | Call `updateLastSeen` endpoint | pg_last_seen_at updated, JSON success |
| TC-P-07 | Soft delete + restore | Delete → trash → restore | is_active=false, restored (stays inactive), activityLog "Restored" |
| TC-P-08 | Force delete trashed device | Permanent delete after soft-delete | Removed, activityLog "Deleted" |
| TC-P-09 | Search by device_name | "Driver Mobile" in search | Filtered results |
| TC-P-10 | Filter by Active status | status=1 | Only active devices |
| TC-P-11 | View single device details | Click show | All relationship data displayed |
| TC-P-12 | List trashed devices | Navigate to trash | Only soft-deleted items, paginated 10/page |
| TC-P-13 | Edit device location only | Change location field | Only location updated, change tracking captures single field |
| TC-P-14 | Force delete active (non-trashed) device | Direct force-delete without prior soft-delete | Success (withTrashed() finds it) |
| TC-P-15 | Create device with is_active=0 | Submit with status unchecked | Created but inactive |
| TC-P-16 | Navigate index with no search params | Default list | All devices paginated 10/page |
| TC-P-17 | Toggle status OFF→ON | Click toggle on inactive device | AJAX success, is_active=1 |
| TC-P-18 | Update last seen multiple times | Call endpoint 3 times | pg_last_seen_at updated each time |

### TC-N: Negative Test Cases

| ID | Test Case | Summary | Expected Result |
|----|-----------|---------|-----------------|
| TC-N-01 | Create without device_name | Empty name | "The device name field is required." |
| TC-N-02 | Create with invalid user_id | user_id=99999 | "The selected user does not exist." |
| TC-N-03 | Create with invalid device_type | non-existent dropdown ID | "The selected device type is invalid." |
| TC-N-04 | Duplicate device_uuid | Same UUID as existing | Database unique constraint violation |
| TC-N-05 | Duplicate user+uuid | Same user_id + UUID pair | Composite unique violation |
| TC-N-06 | Update last seen with invalid UUID | Fake UUID | 404 "Device not found" |
| TC-N-07 | Access without permission | No tenant.attendance-device.* | 403 |
| TC-N-08 | Restore non-trashed device | Active record | `onlyTrashed()` → 404 |
| TC-N-09 | Null on NOT NULL column | Submit device_model, os_version, pg_fcm_token as null | **GAP**: DDL NOT NULL, request nullable → DB error |
| TC-N-10 | Access store without create permission | User with viewAny only | Gate → 403 |
| TC-N-11 | Access edit without update permission | User with viewAny only | Gate → 403 |
| TC-N-12 | Force delete non-existent ID | ID=99999 | `findOrFail()` → 404 |
| TC-N-13 | Restore non-existent ID | ID=99999 | `findOrFail()` → 404 |
| TC-N-14 | Create with device_name exceeding max length | 101+ characters | "The device name must not be greater than 100 characters." |
| TC-N-15 | Create with invalid device_os | non-existent OS dropdown ID | "The selected operating system is invalid." |
| TC-N-16 | Toggle status with missing is_active param | AJAX without is_active | "The is_active field is required." |

### TC-D: Data Integrity Test Cases

| ID | Test Case | Summary | Expected Result |
|----|-----------|---------|-----------------|
| TC-D-01 | UUID uniqueness across soft-deleted | Create → delete → same UUID | Controller do-while with withTrashed() blocks duplicate |
| TC-D-02 | is_active=false before soft-delete | Check DB after destroy | is_active=0 AND deleted_at set |
| TC-D-03 | pg_last_seen_at on create | Store device | pg_last_seen_at = now() |
| TC-D-04 | Change tracking captures all changed fields | Edit device_name + location | activityLog has both with old+new |
| TC-D-05 | FK CASCADE on user delete | Delete personnel with device | Device auto-deleted (hard) |
| TC-D-06 | is_active stays false after restore | Delete → restore → check | is_active=0 (remains false) |
| TC-D-07 | pg_last_seen_at updated on every edit | Edit name only → check timestamp | Timestamp changes (side effect) |
| TC-D-08 | DDL ENUM prevents invalid string | Insert 'InvalidType' directly | MySQL ENUM constraint violation |
| TC-D-09 | updated_at excluded from changes | Edit device → check log | updated_at NOT in $changes |
| TC-D-10 | withTrashed() includes both states | forceDelete query | No deleted_at filter |
| TC-D-11 | onlyTrashed() excludes active | trashed() query | WHERE deleted_at IS NOT NULL |
| TC-D-12 | Composite unique uq_user_device | Insert same user+UUID | "Duplicate entry" error |

### TC-CR: Code Review Test Cases

| ID | Test Case | Steps | Expected |
|----|-----------|-------|----------|
| TC-CR-01 | **BUG: Variable name mismatch** | 1. Controller `compact('devices', ...)` | `$devices` should be `$attendanceDevices` |
| | | 2. Blade `@forelse($attendanceDevices...)` | Undefined variable error |
| TC-CR-02 | **GAP: ENUM vs Dropdown FK** | 1. Migration: ENUM('Desktop','Laptop','Mobile','Tablet') | Expects string |
| | | 2. Request: `exists:sys_dropdown_table,id` | Expects integer FK — **CRITICAL** |
| TC-CR-03 | **GAP: NOT NULL vs nullable** | 1. 3 DDL columns are NOT NULL | Request says nullable |
| | | 2. Insert null → MySQL error | Systematic validation gap |
| TC-CR-04 | UUID do-while loop | Controller lines 67-73 | `Str::uuid()` with uniqueness via withTrashed() |
| TC-CR-05 | Change tracking in update() | Lines 127-144 | getOriginal/getChanges, excludes updated_at |
| TC-CR-06 | is_active=false before destroy | Lines 164-165 | Deactivate then soft-delete |
| TC-CR-07 | forceDelete withTrashed() correct | Line 219 | `withTrashed()->findOrFail()` — correct |
| TC-CR-08 | updateLastSeen by UUID | Line 265 | `where('device_uuid', ...)` not ID |
| TC-CR-09 | updateLastSeen 404 JSON | Lines 278-281 | `response()->json([...], 404)` |
| TC-CR-10 | No device_uuid in rules | `AttendanceDeviceRequest.php:20-52` | Controlled only in controller |
| TC-CR-11 | destroy route-model-binding | Line 160 | `AttendanceDevice $attendanceDevice` |
| TC-CR-12 | prepareForValidation | Lines 64-69 | `$this->boolean('is_active')` normalization |
| TC-CR-13 | toggleStatus inline validation | Lines 239-241 | `$request->validate()` not FormRequest |
| TC-CR-14 | **GAP: No DB::transaction** | All 6 CUD methods | No beginTransaction/commit/rollback |
| TC-CR-15 | pg_last_seen_at contradiction | Line 132 | Code contradicts comment |
| TC-CR-16 | store() double auth | Line 62 + FormRequest | Redundant but safe |
| TC-CR-17 | UUID: required blade vs optional code | Blade `required="true"` vs controller | Contradictory UX |
| TC-CR-18 | restore onlyTrashed() correct | Line 199 | Correct for restore operation |
| TC-CR-19 | trashed() consistent naming | Line 184 | `$attendanceDevices` matches blade |
| TC-CR-20 | Inconsistent parameter handling | destroy vs restore vs forceDelete vs updateLastSeen | Mixed binding/non-binding |

---

## 7. Detailed Test Steps + CODE-TRACE


### TC-P-01: Create device with auto UUID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.attendance-device.create` | Success |
| 2 | Navigate to /transport/attendance-device/create | Create form |
| 3 | Enter device_name = "Driver Mobile-1" | Text input |
| 4 | Select Device OS, Device Type from dropdown | Dropdowns populated |
| 5 | Leave device_uuid blank | Controller auto-generates |
| 6 | Fill optional fields: model, version, app version, FCM, location | Optional data |
| 7 | Select Assigned User, is_active=checked | Dropdown + toggle |
| 8 | Click Submit | POST to store |
| 9 | **Verify**: Request validation passes | All rules ok |
| 10 | **Verify**: `Str::uuid()` generates UUID | Auto-generated |
| 11 | **Verify**: `withTrashed()->exists()` returns false | Unique |
| 12 | **Verify**: `pg_last_seen_at = now()` | Timestamp set |
| 13 | **Verify**: `is_active` defaulted to true | `?? true` |
| 14 | **Verify**: `AttendanceDevice::create($data)` | Row inserted |
| 15 | **Verify**: `activityLog($device, 'Stored', ...)` | Logged |
| 16 | **Verify**: Redirect with flash | Success |

### TC-P-02: Create device with explicit UUID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to create, fill required fields | Valid data |
| 2 | Enter device_uuid = "custom-uuid-001" | Explicit UUID |
| 3 | Submit | POST |
| 4 | **Verify**: `$data['device_uuid'] ?? Str::uuid()` uses provided value | Skips generation |
| 5 | **Verify**: DB has provided UUID | Stored exactly |

### TC-P-03: Create device with all optional fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Fill ALL fields including optional ones | Complete data |
| 2 | Submit | POST |
| 3 | **Verify**: All optional fields saved | os_version, device_model, pg_app_version, pg_fcm_token, location, pg_first_registered_at |

### TC-P-04: Edit device_name

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Edit device, change name to "Updated" | Form pre-filled |
| 2 | Submit update | PUT |
| 3 | **Verify**: `getOriginal()` captures old name | Before state |
| 4 | **Verify**: `getChanges()` captures new name | Changed field |
| 5 | **Verify**: `$changes['device_name'] = ['old'=>'...', 'new'=>'...']` | Old/new pair logged |
| 6 | **Verify**: `activityLog` with changes | Audit trail |

### TC-P-05: Toggle status ON→OFF

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click status toggle on active device | AJAX POST |
| 2 | **Verify**: Gate passes | Authorized |
| 3 | **Verify**: `is_active=0` saved | DB updated |
| 4 | **Verify**: JSON `{success: true, is_active: false}` | 200 OK |
| 5 | **Verify**: Toggle shows OFF | UI updated |

### TC-P-06: Update last seen via UUID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Call POST update-last-seen with valid UUID | Endpoint hit |
| 2 | **Verify**: Gate passes | Authorized |
| 3 | **Verify**: `where('device_uuid', ...)` finds device | Found |
| 4 | **Verify**: `pg_last_seen_at` updated | Timestamp changed |
| 5 | **Verify**: JSON `{success: true}` | 200 OK |

### TC-P-07: Soft delete + restore

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click delete | DELETE to destroy |
| 2 | **Verify**: is_active=false + deleted_at set | Deactivated and trashed |
| 3 | **Verify**: activityLog 'Trashed' | Logged |
| 4 | Navigate to trash, click restore | Device restored |
| 5 | **Verify**: `onlyTrashed()->findOrFail()` finds it | Found in trash |
| 6 | **Verify**: `restore()` sets deleted_at=NULL | Restored |
| 7 | **Verify**: is_active stays false | Not re-enabled |
| 8 | **Verify**: activityLog 'Restored' | Logged |

### TC-P-08: Force delete trashed device

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to trash, click force-delete | DELETE to forceDelete |
| 2 | **Verify**: `withTrashed()->findOrFail()` finds it | Found |
| 3 | **Verify**: `forceDelete()` removes permanently | Deleted |
| 4 | **Verify**: activityLog 'Deleted' | Logged |
| 5 | **Verify**: Row no longer exists in DB | 0 rows |

### TC-P-09: Search by device_name

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter "Driver Mobile" in search | Search field |
| 2 | Click Search | GET with ?search=... |
| 3 | **Verify**: Query: `WHERE device_name LIKE '%Driver%' OR device_uuid LIKE '%Driver%'` | Filtered |

### TC-P-10: Filter by Active status

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select status=1 filter | GET with ?status=1 |
| 2 | **Verify**: `WHERE is_active = 1` | Only active |
| 3 | Select status=0 | Only inactive |

### TC-P-11: View single device details

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click "View" icon | GET to show |
| 2 | **Verify**: Gate passes | Authorized |
| 3 | **Verify**: `$attendanceDevice->load([...])` | 3 relationships loaded |
| 4 | **Verify**: All fields displayed with labels | Full detail view |

### TC-P-12: List trashed devices

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to /transport/attendance-device/trash | Trash view |
| 2 | **Verify**: `onlyTrashed()->paginate(10)` | Only soft-deleted, 10/page |

### TC-P-13: Edit device location only

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Change location only in edit form | Single field change |
| 2 | Submit | PUT |
| 3 | **Verify**: `$changes` has ONLY location | Single field tracked |
| 4 | **Verify**: `updated_at` excluded from changes | Clean |

### TC-P-14: Force delete active device

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Call forceDelete on active (non-deleted) device | Controller hit |
| 2 | **Verify**: `withTrashed()` finds active record | Found |
| 3 | **Verify**: `forceDelete()` succeeds | Permanent deletion |
| 4 | **Verify**: No prior soft-delete needed | Works directly |

### TC-P-15: Create device with is_active=0

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Uncheck "Active" toggle, submit | is_active=false |
| 2 | **Verify**: `$data['is_active'] ?? true` keeps 0 | Created inactive |

### TC-P-16: Navigate index with no params

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open Device Setup tab | Index view |
| 2 | **Verify**: All devices paginated 10/page | Default list |

### TC-P-17: Toggle status OFF→ON

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click toggle on inactive device | AJAX POST |
| 2 | **Verify**: `is_active=1` saved | DB updated |
| 3 | **Verify**: JSON `{success: true, is_active: true}` | 200 OK |

### TC-P-18: Update last seen multiple times

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Call endpoint 3 times in succession | 3 API calls |
| 2 | **Verify**: Each call advances timestamp | T3 > T2 > T1 |

### TC-N-01: Create without device_name

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit form with empty device_name | Validation fails: required |
| 2 | No record created | DB unchanged |

### TC-N-02: Create with invalid user_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set user_id=99999 | Validation: exists:tpt_personnel fails |
| 2 | Error: "The selected user does not exist." | Form error |

### TC-N-03: Create with invalid device_type

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set device_type=99999 | Validation: exists:sys_dropdown_table fails |
| 2 | Error: "The selected device type is invalid." | Form error |

### TC-N-04: Duplicate device_uuid

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create device with UUID X, try second with same UUID | Controller do-while regenerates |
| 2 | Alternatively bypass controller → DB unique violation | uq_device constraint |

### TC-N-05: Duplicate user+UUID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Same user_id + UUID pair | Controller loop avoids duplicate |
| 2 | Direct DB insert → uq_user_device violation | Composite unique |

### TC-N-06: Invalid UUID in updateLastSeen

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Call endpoint with non-existent UUID | Device not found → 404 JSON |
| 2 | **Verify**: `{success: false, message: 'Device not found'}` | 404 response |

### TC-N-07: Access without permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without any attendance-device permissions | 403 on all pages |
| 2 | index, create, edit, delete all blocked | Full authorization |

### TC-N-08: Restore non-trashed device

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Call restore on active (non-deleted) device | `onlyTrashed()` finds nothing → 404 |

### TC-N-09: Null on NOT NULL columns (GAP)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit with os_version, device_model, pg_fcm_token all null | Validation passes (nullable rules) |
| 2 | DB INSERT fails: Integrity constraint violation | **GAP**: 3 columns mismatch |

### TC-N-10: Store without create permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User with only viewAny → POST to store | Gate → 403 |

### TC-N-11: Edit without update permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User with only viewAny → GET edit or PUT update | Gate → 403 |

### TC-N-12: Force delete non-existent ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Call forceDelete(99999) | `withTrashed()->findOrFail(99999)` → 404 |

### TC-N-13: Restore non-existent ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Call restore(99999) | `onlyTrashed()->findOrFail(99999)` → 404 |

### TC-N-14: device_name exceeding max length

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter 101+ characters for device_name | Validation: max:100 fails |

### TC-N-15: Invalid device_os

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set device_os=99999 | Validation: exists:sys_dropdown_table fails |

### TC-N-16: Toggle status missing is_active

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST toggle-status without is_active param | Inline validation: required fails |

### TC-D-01: UUID uniqueness across trashed

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create → delete → create same UUID | Controller do-while with withTrashed() blocks |
| 2 | New UUID generated | Duplicate avoided |

### TC-D-02: is_active=false before soft-delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Destroy device, query DB | `SELECT is_active, deleted_at` → 0 + NOT NULL |

### TC-D-03: pg_last_seen_at on create

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create device, query DB | Timestamp ≈ current time |

### TC-D-04: Change tracking all fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Edit 2 fields simultaneously | Both captured in $changes with old/new |

### TC-D-05: FK CASCADE on user delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Delete personnel with devices | Devices hard-deleted (no audit) |

### TC-D-06: is_active stays false after restore

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Delete → restore → check is_active | Still 0 (false) |

### TC-D-07: pg_last_seen_at on every edit

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Edit only device_name, check last_seen | Also updated (side effect) |

### TC-D-08: DDL ENUM prevents invalid type

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Insert 'InvalidType' directly | MySQL ENUM constraint violation |

### TC-D-09: updated_at excluded from changes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Edit device, check activity log changes | updated_at NOT in array |

### TC-D-10: withTrashed() includes both states

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Query withTrashed() on active and trashed records | Both returned, no deleted_at filter |

### TC-D-11: onlyTrashed() excludes active

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Query onlyTrashed() | WHERE deleted_at IS NOT NULL |

### TC-D-12: Composite unique uq_user_device

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Insert duplicate (user_id, device_uuid) | Duplicate entry error |

### TC-CR-01: Variable name mismatch BUG

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Controller line 42: `compact('devices', ...)` | Should be `attendanceDevices` |
| 2 | Blade line 64: `@forelse($attendanceDevices...)` | Undefined variable error |
| 3 | Fix: rename variable to match blade | Consistent with trashed() |

### TC-CR-02: DDL ENUM vs Dropdown FK CRITICAL

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Migration: ENUM('Desktop','Laptop','Mobile','Tablet') | Expects string |
| 2 | Request: `exists:sys_dropdown_table,id` | Expects integer FK |
| 3 | Insert device_type=1 | Data type mismatch error → **ALL CREATES FAIL** |

### TC-CR-03: NOT NULL vs nullable GAP

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | DDL: os_version, device_model, pg_fcm_token = NOT NULL | Request rules say nullable |
| 2 | Valid form (per validation) crashes on INSERT | **3 GAPS** |

### TC-CR-04: UUID generation loop

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | do...while with Str::uuid() + withTrashed()->exists() | Guarantees unique UUID across all records |

### TC-CR-05: Change tracking in update

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | getOriginal() → update() → getChanges() | Full old/new tracking |
| 2 | updated_at excluded | Clean changes array |

### TC-CR-06: is_active=false before destroy

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | update(['is_active'=>false]) then delete() | Deactivate before soft-delete |

### TC-CR-07: forceDelete withTrashed() correct

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | withTrashed()->findOrFail($id) | **CORRECT** — finds both active and trashed |

### TC-CR-08: updateLastSeen by UUID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | where('device_uuid', $deviceUuid)->first() | Lookup by UUID, not ID |

### TC-CR-09: updateLastSeen 404 JSON

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | response()->json([...], 404) | Consistent JSON API |

### TC-CR-10: No device_uuid in rules

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | device_uuid absent from $rules array | Handled in controller only |

### TC-CR-11: destroy route-model-binding

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | AttendanceDevice $attendanceDevice | Auto 404 on invalid ID |

### TC-CR-12: prepareForValidation is_active

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | $this->boolean('is_active') normalization | Converts checkbox to bool |

### TC-CR-13: toggleStatus inline validation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | $request->validate([...]) not FormRequest | Simpler for AJAX |

### TC-CR-14: No DB::transaction GAP

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | All 6 CUD methods lack transaction wrapping | No atomicity with activityLog |

### TC-CR-15: pg_last_seen_at contradiction

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Comment: "only if provided" but code always sets | Code contradicts comment |

### TC-CR-16: store() double authorization

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Controller Gate + FormRequest authorize | Redundant but safe |

### TC-CR-17: Blade required vs optional UUID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Blade `required="true"` but controller auto-generates | Contradictory UX |

### TC-CR-18: restore onlyTrashed() correct

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | onlyTrashed()->findOrFail($id) | Correct for restore |

### TC-CR-19: trashed() consistent naming

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | $attendanceDevices matches blade | Unlike index() BUG |

### TC-CR-20: Inconsistent parameter handling

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | destroy uses binding, restore/forceDelete use manual ID | Mixed convention |

---

## CODE-TRACE: Method Execution Traces

### CODE-TRACE: index() method

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `Gate::authorize('tenant.attendance-device.viewAny')` | Authorization check → 403 if unauthorized |
| 2 | `AttendanceDevice::with(['deviceType:id,value','operatingSystem:id,value','user:id,name'])` | Eager load 3 relationships (selective columns) |
| 3 | `->when($request->search, fn => ...)` | Optional search filter on name OR UUID |
| 4 | `->when($request->filled('status'), fn => where('is_active', ...))` | Optional status filter |
| 5 | `->paginate(10)->withQueryString()` | `SELECT * FROM tpt_attendance_device ... LIMIT 10 OFFSET 0` + count |
| 6 | `$transportDriveStaff = DriverHelper::get()` | Load personnel for dropdown |
| 7 | `compact('devices', 'transportDriveStaff')` **BUG** | Should be `$attendanceDevices`, not `$devices` |
| 8 | Return view `transport::attendance_device.index` | Blade renders table with pagination |

### CODE-TRACE: create() method

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `Gate::authorize('tenant.attendance-device.create')` | Authorization check → 403 if unauthorized |
| 2 | `$transportDriveStaff = DriverHelper::get()` | Load personnel for user dropdown |
| 3 | `view('transport::attendance_device.create', compact('transportDriveStaff'))` | Create form rendered |

### CODE-TRACE: store() method

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `AttendanceDeviceRequest` injected → `authorize()` check | `tenant.attendance-device.create` (POST) |
| 2 | `AttendanceDeviceRequest::rules()` executed | All 11 field validations run |
| 3 | `prepareForValidation()` normalizes `is_active` | `$this->boolean('is_active')` |
| 4 | Validation passes → `$request->validated()` returns array | `$data` with all validated fields |
| 5 | `Gate::authorize('tenant.attendance-device.create')` | Second authorization check (redundant) |
| 6 | `do { $data['device_uuid'] = $data['device_uuid'] ?? Str::uuid()->toString(); } while(...)` | UUID auto-generation with uniqueness loop |
| 7 | `AttendanceDevice::withTrashed()->where('device_uuid', ...)->exists()` | Check across ALL records (including trashed) |
| 8 | `$data['pg_last_seen_at'] = now()` | Timestamp set to current time |
| 9 | `$data['is_active'] = $data['is_active'] ?? true` | Default to true if not provided |
| 10 | `$device = AttendanceDevice::create($data)` | `INSERT INTO tpt_attendance_device (...)` |
| 11 | `activityLog($device, 'Stored', ...)` | Activity log entry created |
| 12 | Redirect to index with success flash | Success |

### CODE-TRACE: show() method

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Route-model-binding: `AttendanceDevice $attendanceDevice` | `SELECT * FROM tpt_attendance_device WHERE id = ?` |
| 2 | `Gate::authorize('tenant.attendance-device.view')` | Authorization check → 403 if unauthorized |
| 3 | `$attendanceDevice->load(['deviceType', 'operatingSystem', 'user'])` | 3 lazy load queries (full columns) |
| 4 | `view('transport::attendance_device.show', compact('attendanceDevice'))` | Show view with all relationships |

### CODE-TRACE: edit() method

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Route-model-binding: `AttendanceDevice $attendanceDevice` | Model auto-resolved |
| 2 | `Gate::authorize('tenant.attendance-device.update')` | Authorization check → 403 |
| 3 | `$transportDriveStaff = DriverHelper::get()` | Load personnel for dropdown |
| 4 | `view('transport::attendance_device.edit', compact(...))` | Edit form pre-filled |

### CODE-TRACE: update() method

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Route-model-binding: `AttendanceDevice $attendanceDevice` | Model auto-resolved |
| 2 | FormRequest `authorize()` + `rules()` | Validation + authorization |
| 3 | `Gate::authorize('tenant.attendance-device.update')` | Second auth check |
| 4 | `$original = $attendanceDevice->getOriginal()` | Capture pre-update state |
| 5 | `$data = $request->validated()` | Validated input |
| 6 | `$data['pg_last_seen_at'] = now()` | Always overwrites last-seen |
| 7 | `$attendanceDevice->update($data)` | `UPDATE tpt_attendance_device SET ... WHERE id = ?` |
| 8 | `foreach ($attendanceDevice->getChanges() as $field => $value)` | Iterate changed fields |
| 9 | `if ($field === 'updated_at') continue;` | Exclude auto-timestamp |
| 10 | `$changes[$field] = ['old' => $original[$field], 'new' => $value]` | Build old/new change array |
| 11 | `activityLog($attendanceDevice, 'Updated', ['changes' => $changes ?: null])` | Activity log with changes |
| 12 | Redirect with flash | Success |

### CODE-TRACE: destroy() method

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Route-model-binding: `AttendanceDevice $attendanceDevice` | Model auto-resolved |
| 2 | `Gate::authorize('tenant.attendance-device.delete')` | Authorization |
| 3 | `$attendanceDevice->update(['is_active' => false])` | `UPDATE SET is_active=0 WHERE id = ?` |
| 4 | `$attendanceDevice->delete()` | `UPDATE SET deleted_at=NOW() WHERE id = ?` |
| 5 | `activityLog($attendanceDevice, 'Trashed', ...)` | Activity log entry |
| 6 | Redirect with flash | Success |

### CODE-TRACE: trashed() method

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `Gate::authorize('tenant.attendance-device.restore')` | Authorization |
| 2 | `$attendanceDevices = AttendanceDevice::onlyTrashed()->paginate(10)` | `SELECT * FROM tpt_attendance_device WHERE deleted_at IS NOT NULL LIMIT 10 OFFSET 0` |
| 3 | `view('transport::attendance_device.trash', compact('attendanceDevices'))` | Trash view with paginated results |

### CODE-TRACE: restore() method

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `Gate::authorize('tenant.attendance-device.restore')` | Authorization |
| 2 | `$device = AttendanceDevice::onlyTrashed()->findOrFail($id)` | `SELECT * FROM tpt_attendance_device WHERE deleted_at IS NOT NULL AND id = ?` |
| 3 | `$device->restore()` | `UPDATE SET deleted_at=NULL, updated_at=NOW() WHERE id = ?` |
| 4 | `activityLog($device, 'Restored', ...)` | Activity log entry |
| 5 | Redirect with flash | Success |

### CODE-TRACE: forceDelete() method

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `Gate::authorize('tenant.attendance-device.forceDelete')` | Authorization |
| 2 | `$device = AttendanceDevice::withTrashed()->findOrFail($id)` | `SELECT * FROM tpt_attendance_device WHERE id = ?` (no deleted_at filter) **CORRECT** |
| 3 | `$device->forceDelete()` | `DELETE FROM tpt_attendance_device WHERE id = ?` |
| 4 | `activityLog($device, 'Deleted', ...)` | Activity log entry |
| 5 | Redirect with flash | Success |

### CODE-TRACE: toggleStatus() method

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Route-model-binding: `AttendanceDevice $attendanceDevice` | Model auto-resolved |
| 2 | `Gate::authorize('tenant.attendance-device.update')` | Authorization |
| 3 | `$request->validate(['is_active' => 'required|boolean'])` | Inline validation |
| 4 | `$attendanceDevice->is_active = $request->is_active; $attendanceDevice->save()` | `UPDATE SET is_active=? WHERE id = ?` |
| 5 | `activityLog($attendanceDevice, 'Toggled', ...)` | Activity log entry |
| 6 | `response()->json(['success'=>true, 'is_active'=>..., 'message'=>...])` | JSON 200 OK |

### CODE-TRACE: updateLastSeen() method

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `Gate::authorize('tenant.attendance-device.update')` | Authorization |
| 2 | `$device = AttendanceDevice::where('device_uuid', $deviceUuid)->first()` | `SELECT * FROM tpt_attendance_device WHERE device_uuid = ? LIMIT 1` |
| 3 | `if ($device)` → `$device->update(['pg_last_seen_at' => now()])` | `UPDATE SET pg_last_seen_at=NOW() WHERE id = ?` |
| 4 | Return JSON success (200) | `{success: true, message: '...'}` |
| 5 | `else` → return JSON 404 | `{success: false, message: 'Device not found'}` |

---

*Template: tpt_DeviceSetup_TcList.md (Syllabus depth) | Entity: DeviceSetup (AttendanceDevice) | Date: 2026-07-22*
