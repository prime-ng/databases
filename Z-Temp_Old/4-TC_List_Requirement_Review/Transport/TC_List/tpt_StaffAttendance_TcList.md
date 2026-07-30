# Staff Attendance (Driver Attendance) — TC_List

---

## 1. Feature Information

| Attribute | Details |
|-----------|---------|
| **Module** | Transport (TPT) |
| **Entity** | Staff Attendance — Driver Attendance (`TptDriverAttendance`) |
| **Controller** | `Modules\Transport\Http\Controllers\DriverAttendanceController` — 14 methods (index, create, store, show, edit, update, destroy, trashed, restore, forceDelete, showQr, scan, scanQrAttendance, manualAttendance) — `index()` return hub view `transport::tab_module.staffmgmt` with paginated attendance list |
| **Model** | `Modules\Transport\Models\TptDriverAttendance` — SoftDeletes, HasFactory, 1 relationship (driver() → DriverHelper) |
| **Form Request** | `Modules\Transport\Http\Requests\DriverAttendanceRequest` — 6 validation rules + `prepareForValidation` |
| **Policy** | `Modules\Transport\Policies\DriverAttendancePolicy` — 7 permission methods: `viewAny`, `view`, `create`, `update`, `delete`, `restore`, `forceDelete` |
| **Route Prefix** | `transport.driver-attendance.*` (resource) + `trashed`, `restore`, `forceDelete`, `toggleStatus` + `qr`, `mark-attendance`, `manual` |
| **Blade Views** | `tab_module/staffmgmt.blade.php` (hub), `driver-attendance/index.blade.php` (tab partial), `driver-attendance/create.blade.php`, `driver-attendance/edit.blade.php`, `driver-attendance/show.blade.php`, `driver-attendance/trash.blade.php`, `driver-attendance/qr.blade.php` (QR scanner + manual) |
| **Tab Container** | `tab_module/staffmgmt.blade.php` — standalone tab group (Staff Management), tab id `driver_attendance`, permission `tenant.driver-attendance.viewAny` |
| **DB Table** | `tpt_driver_attendance` — 7 data columns + SoftDeletes + timestamps |
| **Secondary Table** | `tpt_driver_attendance_log` — scan log with device_id, lat/lng, scan_method (Manual/NFC/QR/RFID) |
| **Media Library** | NONE — no Spatie MediaLibrary usage |
| **Primary Screen** | `/transport?tab=driver_attendance` → Staff Management tab → Staff Attendance pane (paginated, filterable by driver & status) |
| **Mobile API** | Mobile API endpoints in `MobileAttendanceService` — scan & manual attendance via companion app |

---

## 2. Pre-conditions

| # | Pre-condition |
|---|--------------|
| PC-01 | User must be logged in with `tenant.driver-attendance.*` permissions |
| PC-02 | Database `tpt_driver_attendance` table must exist with all 7 data columns + `deleted_at` |
| PC-03 | `tpt_driver_attendance_log` table must exist for scan audit trail (device_id references `tpt_attendance_device`) |
| PC-04 | `tpt_personnel` table must have at least one driver record (via `DriverHelper` model) with `user_qr_code` populated for QR scanning |
| PC-05 | `tpt_attendance_device` table must exist with device records for scan log FK reference |
| PC-06 | `sys_dropdown_table` must have entries referenced by `attendance_status` FK — **⚠️ GAP: Controller uses string values ('Present', 'Absent') but DDL defines `unsignedInteger` FK** |
| PC-07 | `DriverAttendanceController` must be registered in web routes with full resource + extra routes |
| PC-08 | `DriverAttendancePolicy` must be registered in `AuthServiceProvider` |
| PC-09 | Staff Attendance tab must be included in `staffmgmt.blade.php` with `@can('tenant.driver-attendance.viewAny')` guard |
| PC-10 | Soft deletes must be enabled on `tpt_driver_attendance` (`deleted_at` column via v2 migration) |
| PC-11 | Browser must support JavaScript for QR scanning (`Html5Qrcode` library) and manual attendance |
| PC-12 | `MobileAttendanceService` must be registered for companion app attendance marking |
| PC-13 | Route `driver-attendance.toggleStatus` defined in web.php:186 but **⚠️ GAP: Controller has NO `toggleStatus()` method** |

---

## 3. Default Data Load

| # | Data Load Rule | Source |
|---|----------------|--------|
| DL-01 | Load attendance records with pagination (20 per page) via `DriverAttendanceController::index()` | `DriverAttendanceController.php:40-41` — `$query->orderBy('id','DESC')->paginate(20)` |
| DL-02 | Driver relationship eager-loaded via `->with(['driver'])` to prevent N+1 | `DriverAttendanceController.php:23` — `TptDriverAttendance::with(['driver'])` |
| DL-03 | Search filter: `?driver_id=` (exact driver match) | `DriverAttendanceController.php:25-27` — `where('driver_id', $request->driver_id)` |
| DL-04 | Status filter: `?status=present` → `where('attendance_status', 'Present')`, `?status=leave` → `where('attendance_status', 'Absent')`, other → `LIKE '%value%'` | `DriverAttendanceController.php:29-38` |
| DL-05 | Filter form loads active drivers via `DriverHelper::active()->get()` | `DriverAttendanceController.php:43` — passed as `$driverHelpers` |
| DL-06 | List columns displayed: **Driver**, **Date**, **Check-in**, **Check-out**, **Duration**, **Location**, **Action** | `driver-attendance/index.blade.php:44-51` |
| DL-07 | Duration computed in Blade as `$lastOut->diff($firstIn)->format('%Hh %Im')` | `driver-attendance/index.blade.php:62-66` |
| DL-08 | Action column uses `<x-backend.table.action>` with `permissions="tenant.driver-attendance"` — visible only for `@canany(['tenant.driver-attendance.edit', 'tenant.driver-attendance.delete'])` | `driver-attendance/index.blade.php:50-52,100-104` |
| DL-09 | Pagination uses default Laravel `->links()` without tab param appending | `driver-attendance/index.blade.php:124` — No `->appends(['tab'=>'driver_attendance'])` |
| DL-10 | Empty state: "No attendance found" displayed for colspan 7 | `driver-attendance/index.blade.php:108-112` |
| DL-11 | Create form loads active drivers via `DriverHelper::active()->get()` | `DriverAttendanceController.php:54-55` |
| DL-12 | Edit form loads active drivers + existing attendance record | `DriverAttendanceController.php:113-114` |
| DL-13 | QR page loads active drivers for manual attendance dropdown | `DriverAttendanceController.php:220` — `DriverHelper::active()->get()` |
| DL-14 | **⚠️ GAP: Pagination does NOT append `?tab=driver_attendance`** — switching page will lose tab context | `driver-attendance/index.blade.php:124` |
| DL-15 | **⚠️ GAP: `withQueryString()` NOT used in paginator** — search/driver_id/status filters lost on page change | `DriverAttendanceController.php:41` |

---

## 4. Test Data Strategy

| # | Data Strategy | Details |
|---|---------------|---------|
| TD-01 | **Valid Full Attendance** | driver_id=valid, attendance_date=today, first_in_time=08:00, last_out_time=17:00, via_app=true, attendance_status='Present' |
| TD-02 | **Clock-In Only** | driver_id=valid, first_in_time set, last_out_time=null, total_work_minutes=null, status='IN_PROGRESS' |
| TD-03 | **Clock-Out Without Clock-In** | driver_id=valid, first_in_time=null, last_out_time set, via_app=true |
| TD-04 | **Duplicate Attendance Date** | Same driver_id + attendance_date combination — expects unique violation |
| TD-05 | **QR Scan Clock-In** | Valid user_qr_code with scan_type='IN' |
| TD-06 | **QR Scan Clock-Out** | Valid user_qr_code with scan_type='OUT' after clock-in |
| TD-07 | **QR Scan Clock-Out Without Clock-In** | Valid user_qr_code with scan_type='OUT', no prior attendance |
| TD-08 | **Invalid QR Code** | Scan non-existent user_qr_code |
| TD-09 | **Manual Attendance (Web IN)** | POST to manualAttendance with type='IN' |
| TD-10 | **Manual Attendance (Web OUT)** | POST to manualAttendance with type='OUT', has prior IN |
| TD-11 | **Manual Attendance (Web OUT without IN)** | POST to manualAttendance with type='OUT', no prior IN |
| TD-12 | **Soft-Deleted Record** | Attendance record with deleted_at set, not loaded in index() |
| TD-13 | **Half-Day Attendance** | first_in_time=08:00, last_out_time=13:00, total_work_minutes=300 |
| TD-14 | **"On Leave" Display** | No first_in_time AND no last_out_time → badge "On Leave" |
| TD-15 | **Mobile App Scan IN** | `MobileAttendanceService.scanDriverAttendance()` with scan_type='IN' |
| TD-16 | **Mobile App Scan OUT** | `MobileAttendanceService.scanDriverAttendance()` with scan_type='OUT' |
| TD-17 | **Mobile App Manual IN** | `MobileAttendanceService.manualDriverAttendance()` with type='IN' |

---

## 5. Business Conditions (BC)

### BC-DB: Database Conditions

| ID | Condition | Expected | Source |
|----|-----------|----------|--------|
| BC-DB-01 | `id` — INT UNSIGNED, AUTO_INCREMENT, PRIMARY KEY | Unique per record | Migration: `tpt_driver_attendance` line 15 |
| BC-DB-02 | `driver_id` — INT UNSIGNED, NOT NULL, FK → `tpt_personnel.id` ON DELETE CASCADE | Required driver reference | Migration: line 16, 25 |
| BC-DB-03 | `attendance_date` — DATE, NOT NULL | Date only (no time), part of composite unique | Migration: line 17 |
| BC-DB-04 | `first_in_time` — DATETIME, NULLABLE | Nullable — not required for clock-out-only records | Migration: line 18 |
| BC-DB-05 | `last_out_time` — DATETIME, NULLABLE | Nullable — not required for clock-in-only records | Migration: line 19 |
| BC-DB-06 | `total_work_minutes` — INTEGER, NULLABLE | Computed as diffInMinutes between first_in and last_out | Migration: line 20 |
| BC-DB-07 | `attendance_status` — UNSIGNED INTEGER, FK → `sys_dropdown_table.id` ON DELETE CASCADE | **⚠️ GAP: DDL defines FK to sys_dropdown_table but controller/views use string values** | Migration: line 21, 26 |
| BC-DB-08 | `via_app` — BOOLEAN, DEFAULT true | 1=App/QR entry, 0=Manual web entry | Migration: line 22 |
| BC-DB-09 | `created_at` — TIMESTAMP, useCurrent | Auto-set on create | Migration: line 23 |
| BC-DB-10 | `deleted_at` — TIMESTAMP, NULLABLE (soft-deletes via v2 migration) | Added by `2026_06_27_000001_add_deleted_at_to_tpt_driver_attendance_table.php` | Migration v2 |
| BC-DB-11 | UNIQUE KEY `uq_driver_day` on (`driver_id`, `attendance_date`) | Prevents duplicate attendance per driver per day | Migration: line 29 |
| BC-DB-12 | `tpt_driver_attendance_log` — `attendance_id` FK → `tpt_driver_attendance.id` ON DELETE CASCADE | Scan log cascade deletes with attendance | Log migration: line 27 |
| BC-DB-13 | `tpt_driver_attendance_log` — `device_id` FK → `tpt_attendance_device.id` ON DELETE CASCADE | Device reference for scan audit | Log migration: line 29 |
| BC-DB-14 | `tpt_driver_attendance_log` — `scan_method` ENUM('Manual','NFC','QR','RFID') | Tracks origin of scan | Log migration: line 19 |
| BC-DB-15 | `tpt_driver_attendance_log` — `scan_status` ENUM('Duplicate','Rejected','Valid') DEFAULT 'Valid' | Flags problematic scans | Log migration: line 22 |
| BC-DB-16 | `tpt_driver_attendance_log` — `latitude`/`longitude` DECIMAL(10,6), NULLABLE | Geo-location of scan device | Log migration: line 20-21 |

### BC-VAL: Validation Conditions

| ID | Condition | Rule | Source |
|----|-----------|------|--------|
| BC-VAL-01 | `driver_id` — required, exists in `tpt_personnel`, unique per driver+date | `required\|exists:tpt_personnel,id\|Rule::unique(...)->where('attendance_date', ...)->ignore(...)->whereNull('deleted_at')` | `DriverAttendanceRequest.php:28-35` |
| BC-VAL-02 | `attendance_date` — required, date, unique per driver+date | `required\|date\|Rule::unique(...)->where(fn => query where driver_id = ...)->ignore(...)` | `DriverAttendanceRequest.php:37-45` |
| BC-VAL-03 | `first_in_time` — required | `required` | `DriverAttendanceRequest.php:48-50` |
| BC-VAL-04 | `last_out_time` — required | `required` | `DriverAttendanceRequest.php:52-54` |
| BC-VAL-05 | `via_app` — required, boolean | `required\|boolean` | `DriverAttendanceRequest.php:56-59` |
| BC-VAL-06 | `via_app` normalization in `prepareForValidation()` | `filter_var($this->via_app, FILTER_VALIDATE_BOOLEAN)` | `DriverAttendanceRequest.php:66-71` |
| BC-VAL-07 | Custom message: `attendance_date.unique` | "Attendance for this driver on the selected date already exists." | `DriverAttendanceRequest.php:79-81` |
| BC-VAL-08 | Custom message: `last_out_time.after` | "Last out time must be after first in time." — ⚠️ **No `after` rule exists in rules array** | `DriverAttendanceRequest.php:82-83` — dead message |
| BC-VAL-09 | QR scan validation: `qr_code` required, exists in `tpt_personnel.user_qr_code` | `required\|exists:tpt_personnel,user_qr_code` | `DriverAttendanceController.php:242` |
| BC-VAL-10 | QR scan validation: `scan_type` required, in `['IN','OUT']` | `required\|in:IN,OUT` | `DriverAttendanceController.php:243` |
| BC-VAL-11 | Manual attendance validation: `driver_id` required, exists in `tpt_personnel` | `required\|exists:tpt_personnel,id` | `DriverAttendanceController.php:343` |
| BC-VAL-12 | Manual attendance validation: `type` required, in `['IN','OUT']` | `required\|in:IN,OUT` | `DriverAttendanceController.php:344` |
| BC-VAL-13 | **⚠️ GAP: `last_out_time.after` message defined but NO `after:first_in_time` rule exists** | Dead custom message | `DriverAttendanceRequest.php:82-83` |
| BC-VAL-14 | **⚠️ GAP: `attendance_status` NOT validated in FormRequest** — no rule defined for attendance_status field | Field passed via mass-assignment without validation | `DriverAttendanceRequest.php:27-60` |
| BC-VAL-15 | **⚠️ GAP: `total_work_minutes` NOT validated — computed server-side** | Computed via Carbon `diffInMinutes()`, no user input | Controller logic |

### BC-AUTH: Authorization Conditions

| ID | Permission | Controller Gate | Policy Method | Source |
|----|-----------|-----------------|---------------|--------|
| BC-AUTH-01 | `tenant.driver-attendance.viewAny` | `Gate::authorize('tenant.driver-attendance.viewAny')` in `index()` (line 21), `showQr()` (line 218), `scan()` (line 230) | `viewAny()` | `DriverAttendancePolicy.php:12-15` |
| BC-AUTH-02 | `tenant.driver-attendance.view` | `Gate::authorize('tenant.driver-attendance.view')` in `show()` (line 99) | `view()` | `DriverAttendancePolicy.php:17-20` |
| BC-AUTH-03 | `tenant.driver-attendance.create` | `Gate::authorize('tenant.driver-attendance.create')` in `create()` (line 52), `store()` (line 64), `scanQrAttendance()` (line 240), `manualAttendance()` (line 341) | `create()` | `DriverAttendancePolicy.php:22-25` |
| BC-AUTH-04 | `tenant.driver-attendance.update` | `Gate::authorize('tenant.driver-attendance.update')` in `edit()` (line 111), `update()` (line 124) | `update()` | `DriverAttendancePolicy.php:27-30` |
| BC-AUTH-05 | `tenant.driver-attendance.delete` | `Gate::authorize('tenant.driver-attendance.delete')` in `destroy()` (line 161) | `delete()` | `DriverAttendancePolicy.php:32-35` |
| BC-AUTH-06 | `tenant.driver-attendance.restore` | `Gate::authorize('tenant.driver-attendance.restore')` in `trashed()` (line 177), `restore()` (line 189) | `restore()` | `DriverAttendancePolicy.php:37-40` |
| BC-AUTH-07 | `tenant.driver-attendance.forceDelete` | `Gate::authorize('tenant.driver-attendance.forceDelete')` in `forceDelete()` (line 205) | `forceDelete()` | `DriverAttendancePolicy.php:42-45` |
| BC-AUTH-08 | `tenant.driver-attendance.*` (all CRUD) | Permissions group defined in `config/permissionslist.php:316` with `$crud` | All CRUD methods | `permissionslist.php:316` |

### BC-BIZ: Business Conditions

| ID | Condition | Expected | Source |
|----|-----------|----------|--------|
| BC-BIZ-01 | Unique attendance per driver per day via composite unique `uq_driver_day` | DB unique constraint + Request unique rules | Migration line 29 |
| BC-BIZ-02 | Work minutes computed as `$firstIn->diffInMinutes($lastOut)` | `total_work_minutes = last_out - first_in` in minutes | `DriverAttendanceController.php:75-77` |
| BC-BIZ-03 | Default attendance_status = 'IN_PROGRESS' if not provided | `$request->attendance_status ?: 'IN_PROGRESS'` | `DriverAttendanceController.php:85` |
| BC-BIZ-04 | `via_app` normalization using `filter_var($val, FILTER_VALIDATE_BOOLEAN)` | Converts "1"/"true"/"on" to boolean true | `DriverAttendanceRequest.php:68-69` |
| BC-BIZ-05 | QR scan clock-in: creates new record with `first_in_time=now()`, `attendance_status='Present'`, `via_app=1` | Instant clock-in via QR | `DriverAttendanceController.php:269-275` |
| BC-BIZ-06 | QR scan clock-in warning: if prior attendance exists with no last_out_time | "You clocked in earlier but did not clock out." | `DriverAttendanceController.php:265-267` |
| BC-BIZ-07 | QR scan clock-out: updates existing record's `last_out_time` and computes `total_work_minutes` | Updates, does NOT create new | `DriverAttendanceController.php:300-304` |
| BC-BIZ-08 | QR scan clock-out warning when no prior clock-in: creates new record + warning "You are clocking out without a previous clock in." | Creates with only last_out_time | `DriverAttendanceController.php:310-317` |
| BC-BIZ-09 | Web manual attendance clock-in (JSON): creates with `first_in_time=now()`, `via_app=1` | AJAX POST response | `DriverAttendanceController.php:364-377` |
| BC-BIZ-10 | Web manual attendance clock-out (JSON): updates last_out_time if prior IN exists; else creates with warning | Same pattern as QR | `DriverAttendanceController.php:382-409` |
| BC-BIZ-11 | `showQr()` and `scan()` use `viewAny` gate (both require same permission) | Consistent gate | `DriverAttendanceController.php:218,230` |
| BC-BIZ-12 | `destroy()` does NOT set `is_active=false` before soft-delete | Direct `$attendance->delete()` — no deactivation step | `DriverAttendanceController.php:163-164` |
| BC-BIZ-13 | `restore()` does NOT reactivate `is_active` | Simple `$attendance->restore()` — no `is_active=true` step | `DriverAttendanceController.php:191-192` |
| BC-BIZ-14 | `forceDelete()` uses `onlyTrashed()` NOT `withTrashed()` | Can only force-delete already soft-deleted records | `DriverAttendanceController.php:207` |
| BC-BIZ-15 | All CRUD operations (store, update, destroy, restore, forceDelete) call `activityLog()` | Consistent logging pattern | Controller methods |
| BC-BIZ-16 | `store()` and `update()` manually parse `first_in_time` and `last_out_time` combining date + time | `Carbon::parse($date->toDateString().' '.$request->first_in_time)` | `DriverAttendanceController.php:67-69` |
| BC-BIZ-17 | `show()` eager-loads driver relationship | `TptDriverAttendance::with(['driver'])->findOrFail($id)` | `DriverAttendanceController.php:101` |
| BC-BIZ-18 | Index lists attendance ordered by `id DESC` (most recent first) | `->orderBy('id', 'DESC')` | `DriverAttendanceController.php:40` |
| BC-BIZ-19 | Location column in index defaults to 'Depot' if no geo data | `$item->geo_lat && $item->geo_lng ? ... : 'Depot'` | `driver-attendance/index.blade.php:96` |
| BC-BIZ-20 | Duration format: `%Hh %Im` (e.g., "8h 30m") | Computed in Blade using Carbon::diff() | `driver-attendance/index.blade.php:63-65` |
| BC-BIZ-21 | "On Leave" badge shown when BOTH first_in_time and last_out_time are null | `$leave = !$item->first_in_time && !$item->last_out_time` | `driver-attendance/index.blade.php:59-60` |
| BC-BIZ-22 | Date column formatted as `d M, Y` (e.g., "22 Jul, 2026") | Carbon::parse()->format() | `driver-attendance/index.blade.php:74` |
| BC-BIZ-23 | Time columns formatted as `h:i A` (12-hour with AM/PM) | Carbon::parse()->format('h:i A') | `driver-attendance/index.blade.php:82,88` |
| BC-BIZ-24 | QR scan debounce via COOLDOWN=3000ms — prevents duplicate scans within 3 seconds | `now - lastScanAt < COOLDOWN` check | `qr.blade.php:236` |
| BC-BIZ-25 | QR scan entry type indicator shows "CLOCK IN" or "CLOCK OUT" badge | JS `showEntryType(type)` | `qr.blade.php:374-381` |
| BC-BIZ-26 | Manual attendance flow via modal: select driver → click type button → confirm → save | 4-step modal flow | `qr.blade.php:84-124` |
| BC-BIZ-27 | Success/error feedback via SweetAlert2 toasts (8s timer) | `Swal.fire({..., timer: 8000, toast: true})` | `qr.blade.php:155-167` |
| BC-BIZ-28 | Mobile API: `MobileAttendanceService.scanDriverAttendance()` uses `firstOrNew` pattern | Separate from web controller logic | `MobileAttendanceService.php:36` |
| BC-BIZ-29 | Mobile API: `MobileAttendanceService.manualDriverAttendance()` also uses `firstOrNew` pattern | Consistent `firstOrNew` across both mobile methods | `MobileAttendanceService.php:141` |
| BC-BIZ-30 | Mobile API returns JSON with `status='ok'` (not `true`) and `attendance` object | Different format from web controller JSON | `MobileAttendanceService.php:61-76` |
| BC-BIZ-31 | `DriverAttendanceRequest@authorize()` returns different permissions for POST vs non-POST | POST: `tenant.driver-attendance.create`, else: `tenant.driver-attendance.update` | `DriverAttendanceRequest.php:16-19` |
| BC-BIZ-32 | Unique rule in Request ignores current record on update via `$this->route('driver_attendance') ?? $this->route('driver-attendance') ?? $this->id` | Tries 3 possible route parameter names | `DriverAttendanceRequest.php:33,41` |
| BC-BIZ-33 | `scanQrAttendance()` uses inline `Validator::make()` NOT `DriverAttendanceRequest` | Separate validation from FormRequest | `DriverAttendanceController.php:241-243` |
| BC-BIZ-34 | `manualAttendance()` uses `$request->validate()` inline, NOT FormRequest | Separate validation | `DriverAttendanceController.php:342-344` |
| BC-BIZ-35 | `destroy()` redirects to `transport.transport-master.index` NOT driver-attendance.index | Redirects to Transport Master hub, not attendance index | `DriverAttendanceController.php:168` |

### BC-BIZ-DEEP: Deep Business Conditions

| # | Condition | Expected Behavior |
|---|-----------|-------------------|
| BC-BIZ-DEEP-01 | Pagination at 20 per page in index() | `->paginate(20)` — 20 records per page |
| BC-BIZ-DEEP-02 | `withQueryString()` NOT used — filter params lost on page change | Pagination links do NOT preserve `?driver_id=` or `?status=` params |
| BC-BIZ-DEEP-03 | Pagination does NOT append `?tab=driver_attendance` | Tab context lost on page switch — wrong tab may display |
| BC-BIZ-DEEP-04 | Index view returned is `transport::tab_module.staffmgmt` (hub view) not standalone | Returns full hub layout with the tab pane |
| BC-BIZ-DEEP-05 | `$driverHelpers` loaded for filter dropdown in index even when not filtering | `DriverHelper::active()->get()` — loads ALL active drivers |
| BC-BIZ-DEEP-06 | `show()` loads record via `findOrFail` — 404 if not found | Proper ModelNotFoundException handling |
| BC-BIZ-DEEP-07 | `create()` returns view with drivers list only | Simple view, no model binding needed |
| BC-BIZ-DEEP-08 | `store()` manually parses date+time into Carbon before create | Combines `attendance_date` + `first_in_time`/`last_out_time` into DateTime |
| BC-BIZ-DEEP-09 | `store()` computes work minutes server-side | `$firstIn->diffInMinutes($lastOut)` |
| BC-BIZ-DEEP-10 | `store()` does NOT call `activityLog()` — **⚠️ GAP: Missing activity log on create** | No activityLog() call in store method |
| BC-BIZ-DEEP-11 | `update()` does NOT call `activityLog()` — **⚠️ GAP: Missing activity log on update** | No activityLog() call in update method |
| BC-BIZ-DEEP-12 | `destroy()` calls `activityLog()` with type 'Deleted' and message 'Driver attendance moved to trash' | Activity log present |
| BC-BIZ-DEEP-13 | `restore()` calls `activityLog()` with type 'Restored' and message 'Driver attendance restored' | Activity log present |
| BC-BIZ-DEEP-14 | `forceDelete()` calls `activityLog()` with type 'ForceDelete' and message 'Driver attendance permanently deleted' | Activity log present |
| BC-BIZ-DEEP-15 | `update()` does NOT track attribute changes (no `getOriginal()`/`getChanges()`) | No change tracking — only manual field recomputation |
| BC-BIZ-DEEP-16 | `store()` does NOT use `$request->validated()` directly — manually maps fields | Uses `$request->driver_id`, `$request->attendance_date`, etc. manually |
| BC-BIZ-DEEP-17 | `update()` also manually maps fields rather than `$request->validated()` | Inconsistent with standard pattern |
| BC-BIZ-DEEP-18 | `scanQrAttendance()` returns JSON with `status=true/false` (boolean) on 422 | `status: false` with 422 HTTP code |
| BC-BIZ-DEEP-19 | `manualAttendance()` returns JSON with `status=true` on success | `status: true` (boolean) |
| BC-BIZ-DEEP-20 | QR scan clock-in sets `attendance_status='Present'` hardcoded | Always marks 'Present' regardless of time |
| BC-BIZ-DEEP-21 | QR scan clock-in does NOT set `total_work_minutes` | Only set on clock-out |
| BC-BIZ-DEEP-22 | Web manual clock-in does NOT set `attendance_status` at all **⚠️ GAP** | `via_app` set, but status defaults to DB/not set |
| BC-BIZ-DEEP-23 | Web manual clock-out updates existing attendance (if prior IN) — does NOT create new record | Reuses same row — modifies last_out_time and total_work_minutes |
| BC-BIZ-DEEP-24 | QR scan returns driver info: name, role, phone in response | `$driver->name, $driver->role, $driver->phone` |
| BC-BIZ-DEEP-25 | Web manual attendance returns driver via `$attendance->load('driver')` | Eager-loads after create for response |
| BC-BIZ-DEEP-26 | QR scan page has BOTH QR scanner tab AND manual attendance tab | Dual-mode UI in a single page |
| BC-BIZ-DEEP-27 | QR scanner uses `Html5Qrcode` library from unpkg CDN | External dependency via `<script src="https://unpkg.com/html5-qrcode">` |
| BC-BIZ-DEEP-28 | QR scanner uses `facingMode: "environment"` (rear camera) | Prefers rear camera for QR scanning |
| BC-BIZ-DEEP-29 | QR scanner FPS: 10, QR box: 250px | Performance/accuracy configuration |
| BC-BIZ-DEEP-30 | Duplicate QR code detection via `lastQr` + `lastScanAt` with 3s cooldown | Prevents double-scan within window |
| BC-BIZ-DEEP-31 | QR scan result auto-clears after 5 seconds (`setTimeout(resetScan, 5000)`) | Auto-reset for next scan |
| BC-BIZ-DEEP-32 | Scan-type badge shows color-coded: CLOCK IN = bg-warning, result IN = bg-success, result OUT = bg-danger | Visual differentiation |
| BC-BIZ-DEEP-33 | Live clock display on QR scan page — updates every second | `startLiveTime()` with `setInterval(tick, 1000)` |
| BC-BIZ-DEEP-34 | Manual attendance page shows live date/time + driver dropdown | Dual-info display |
| BC-BIZ-DEEP-35 | `destroy()` redirects to `transport.transport-master.index` not `transport.driver-attendance.index` **⚠️ GAP** | Returns to Transport Master instead of Staff Management tab |
| BC-BIZ-DEEP-36 | `restore()` redirects to `transport.transport-master.index` — not trash page | Inconsistent pattern — should redirect to trash |
| BC-BIZ-DEEP-37 | `forceDelete()` redirects to `transport.transport-master.index` | Same as restore — not trash |
| BC-BIZ-DEEP-38 | `destroy()` uses `flash('trashed.driver_attendance')` flash key | Must exist in lang file |
| BC-BIZ-DEEP-39 | `restore()` uses `flash('restored.driver_attendance')` flash key | Must exist in lang file |
| BC-BIZ-DEEP-40 | `forceDelete()` uses `flash('force_deleted.driver_attendance')` flash key | Must exist in lang file |
| BC-BIZ-DEEP-41 | `store()` and `update()` use hardcoded success messages NOT flash() helper | `->with('success', 'Driver attendance saved successfully')` — hardcoded string |
| BC-BIZ-DEEP-42 | `DriverAttendanceRequest` `ignore()` tries 3 route parameter names: `driver_attendance`, `driver-attendance`, `id` | Covers both resource route param variations |
| BC-BIZ-DEEP-43 | Status filter maps 'present' → 'Present', 'leave' → 'Absent', else → `LIKE '%val%'` | Three-tier mapping |
| BC-BIZ-DEEP-44 | Driver filter is exact match (`where('driver_id', $request->driver_id)`) | No LIKE/partial matching |
| BC-BIZ-DEEP-45 | No filter for `attendance_date` range in index — only driver and status | Date-based filtering not available in UI |
| BC-BIZ-DEEP-46 | **⚠️ GAP: `toggleStatus` route defined but controller method does NOT exist** | Route `POST /driver-attendance/{driver-attendance}/toggle-status` → 500 error if called |
| BC-BIZ-DEEP-47 | **⚠️ GAP: `attendance_status` DDL type mismatch** — DB stores INT FK to sys_dropdown_table, controller stores string | Data integrity risk — insertion would fail FK constraint |
| BC-BIZ-DEEP-48 | `attendance_status` NOT cast in model (`$casts` does NOT include it) | Will be returned as-is from DB — string or int depending on storage |
| BC-BIZ-DEEP-49 | `via_app` cast as boolean in model `$casts` | `'via_app' => 'boolean'` — returns true/false in JSON |
| BC-BIZ-DEEP-50 | `attendance_date` cast as `date` in model | Carbon date instance — no time component |
| BC-BIZ-DEEP-51 | `first_in_time` and `last_out_time` cast as `datetime` in model | Carbon datetime instances |
| BC-BIZ-DEEP-52 | `total_work_minutes` cast as `integer` in model | Integer value — could overflow for very long shifts |
| BC-BIZ-DEEP-53 | `qr.blade.php` uses inline `<style>` for #qr-reader sizing | `max-width: 400px, aspect-ratio: 4/3` |
| BC-BIZ-DEEP-54 | `qr.blade.php` uses `fetch()` API for AJAX calls (no jQuery) | `fetch(url, { method: "POST", headers: {...}, body: JSON.stringify({...}) })` |
| BC-BIZ-DEEP-55 | `scanQrAttendance()` response includes `warning` key even when null | `'warning' => $warning` — null if no warning |
| BC-BIZ-DEEP-56 | `manualAttendance()` response includes `warning` key | Same pattern as scanQrAttendance |
| BC-BIZ-DEEP-57 | Mobile API scan returns `status='ok'` (string) not `status=true` (boolean) | Different format from web controller |
| BC-BIZ-DEEP-58 | Mobile API uses `firstOrNew()` — creates OR updates existing attendance for same day | Single record per driver per day |
| BC-BIZ-DEEP-59 | Mobile API wraps logic in try-catch with `report($e)` | Exception logged but not re-thrown |
| BC-BIZ-DEEP-60 | Mobile API returns 422 for validation failure, 500 for exceptions | Standard error code usage |
| BC-BIZ-DEEP-61 | `store()` uses `Carbon::parse($date->toDateString().' '.$request->first_in_time)` — time-only input combined with date | Time input format must be `H:i` (24-hour) |
| BC-BIZ-DEEP-62 | `index()` does NOT use `->when()` helper for search filter — uses `if ($request->filled())` | Manual if-blocks instead of query builder when() |
| BC-BIZ-DEEP-63 | Index blade status filter shows only 2 options: "Present" and "On Leave" (maps to 'leave') | No 'Half-Day' or 'Late' filter options even though model defines them |
| BC-BIZ-DEEP-64 | Model defines STATUSES constant: `['Present', 'Absent', 'Half-Day', 'Late']` | 4 statuses defined but only 2 filterable in UI |
| BC-BIZ-DEEP-65 | `create.blade.php` has `attendance_status` dropdown with 4 text values but DB expects INT FK | **⚠️ GAP: Form would fail on submit due to FK constraint** |
| BC-BIZ-DEEP-66 | `create.blade.php` select for attendance_status has bug: `{{ old('attendance_status') }}` without comparison to `$status` | No option will be pre-selected |
| BC-BIZ-DEEP-67 | `edit.blade.php` attendance_status correctly uses `{{ old('attendance_status', $record->attendance_status) == $status ? 'selected' : '' }}` | Proper old-value comparison |
| BC-BIZ-DEEP-68 | Create form does NOT include `attendance_date` in `old('attendance_date', now()->toDateString())` | Defaults to today |
| BC-BIZ-DEEP-69 | Edit form attendance_date uses `old('attendance_date', $record->attendance_date?->toDateString())` | Pre-filled from record |
| BC-BIZ-DEEP-70 | `show()` view displays Via App badge: green "Yes" or grey "No" | `bg-success` for true, `bg-secondary` for false |
| BC-BIZ-DEEP-71 | `show()` view displays attendance_status as `ucfirst($record->attendance_status)` | Title-cased |
| BC-BIZ-DEEP-72 | **⚠️ GAP: Trash blade uses `check_in_time` and `check_out_time` field names that DO NOT exist** | `trash.blade.php:38,53,58` — references `$item->check_in_time` and `$item->check_out_time` — should be `first_in_time`/`last_out_time` |
| BC-BIZ-DEEP-73 | **⚠️ GAP: Trash blade references `geo_lat` and `geo_lng` fields that DO NOT exist in model/migration** | `trash.blade.php:64` — no geo columns in tpt_driver_attendance |
| BC-BIZ-DEEP-74 | **⚠️ GAP: Trash blade date uses `$item->created_at` instead of `$item->attendance_date`** | `trash.blade.php:45` — shows created date, not attendance date |
| BC-BIZ-DEEP-75 | **⚠️ GAP: `staffmgmt.blade.php` missing `:active="request('tab', 'driver_attendance')"`** | Default active tab not set — may default to first tab incorrectly |
| BC-BIZ-DEEP-76 | Breadcrumb config has BOTH `staff-mgmt` and `drive-attendance` pointing to `driver_attendance` | Two route aliases for same breadcrumb entry |
| BC-BIZ-DEEP-77 | `permissionslist.php` defines `driver-attendance` under "Transport Staff Management" section | Permission group in dedicated section |
| BC-BIZ-DEEP-78 | Index blade permission check uses `tenant.driver-attendance.edit` but permission is `tenant.driver-attendance.update` **⚠️ GAP** | `@canany(['tenant.driver-attendance.edit','tenant.driver-attendance.delete'])` — 'edit' not a valid permission |
| BC-BIZ-DEEP-79 | `store()` flash message hardcoded: "Driver attendance saved successfully" | Not using flash() helper — inconsistent with other modules |
| BC-BIZ-DEEP-80 | `update()` flash message hardcoded: "Driver attendance updated successfully" | Not using flash() helper — inconsistent with other modules |

### BC-REL: Relationship Conditions

| ID | Relationship | Type | Source |
|----|-------------|------|--------|
| BC-REL-01 | TptDriverAttendance → DriverHelper (driver) | `belongsTo(DriverHelper::class, 'driver_id')` | `TptDriverAttendance.php:54-57` |
| BC-REL-02 | TptDriverAttendance → TptDriverAttendanceLog (scan log) | One-to-many via `attendance_id` FK in log table | Log migration: line 27 |
| BC-REL-03 | DriverHelper → TptAttendanceDevice | One-to-many via `user_id` FK in device table | Device migration: line 33 |

### BC-FSM: State Transitions

| ID | From State | To State | Trigger | Validation | Source |
|----|-----------|----------|---------|------------|--------|
| FSM-01 | null (no record) | IN_PROGRESS | Manual create with only first_in_time | driver_id + attendance_date unique | `DriverAttendanceController.php:79-87` |
| FSM-02 | null (no record) | Present | QR scan Clock-In | qr_code exists + scan_type=IN | `DriverAttendanceController.php:269-275` |
| FSM-03 | IN_PROGRESS | Present | Manual update setting both times | FormRequest validation | `DriverAttendanceController.php:141-148` |
| FSM-04 | Present (has IN only) | Present (complete) | QR scan Clock-Out updates last_out_time | Last attendance has no out time | `DriverAttendanceController.php:300-304` |
| FSM-05 | Present (complete) | Deleted (trashed) | destroy() | Gate::delete | `DriverAttendanceController.php:163-164` |
| FSM-06 | Deleted (trashed) | Present (restored) | restore() | Gate::restore, `onlyTrashed()->findOrFail()` | `DriverAttendanceController.php:191-192` |
| FSM-07 | Deleted (trashed) | Permanently Deleted | forceDelete() | Gate::forceDelete, `onlyTrashed()->findOrFail()` | `DriverAttendanceController.php:207-208` |

### BC-REF: Reference & UI Conditions

| ID | Condition | Expected | Source |
|----|-----------|----------|--------|
| BC-REF-01 | Staff Management tab loads with `@can('tenant.driver-attendance.viewAny')` | Tab conditional | `staffmgmt.blade.php:15-18` |
| BC-REF-02 | Action column in index shown only for `@canany(['tenant.driver-attendance.edit', 'tenant.driver-attendance.delete'])` **⚠️ GAP: 'edit' not valid permission, should be 'update'** | Conditional | `driver-attendance/index.blade.php:50-52,100-104` |
| BC-REF-03 | Create form — driver dropdown + time inputs + via_app switch + date + status | 6 field types | `driver-attendance/create.blade.php:35-113` |
| BC-REF-04 | QR page dual-mode: Scan QR tab + Manual tab | Two operational modes | `driver-attendance/qr.blade.php:24-38` |
| BC-REF-05 | QR page uses `Html5Qrcode` library — external CDN dependency | `unpkg.com/html5-qrcode` | `qr.blade.php:136` |
| BC-REF-06 | QR page uses SweetAlert2 for toast warnings | `cdn.jsdelivr.net/npm/sweetalert2@11` | `qr.blade.php:137` |
| BC-REF-07 | **⚠️ GAP: Trash blade references non-existent `check_in_time`/`check_out_time` fields** | Blade will show blank/null | `trash.blade.php:38,53,58` |
| BC-REF-08 | **⚠️ GAP: Trash blade references non-existent `geo_lat`/`geo_lng` fields** | Always shows 'Depot' | `trash.blade.php:64` |
| BC-REF-09 | **⚠️ GAP: `staffmgmt.blade.php` missing `:active` attribute on nav-tab** | Default tab may not be driver_attendance | `staffmgmt.blade.php:14-16` |
| BC-REF-10 | **⚠️ GAP: `@can` check uses `tenant.driver-attendance.edit` — should be `tenant.driver-attendance.update`** | Permission mismatch | `driver-attendance/index.blade.php:50,100` |
| BC-REF-11 | Breadcrumb config: `staff-mgmt` → `driver_attendance`, `drive-attendance` → `driver_attendance` | Two aliases | `breadcrumb.php:681-682` |
| BC-REF-12 | Flash keys used: `trashed.driver_attendance`, `restored.driver_attendance`, `force_deleted.driver_attendance` | Must exist in lang file | `DriverAttendanceController.php:169,197,213` |

---

## 6. Test Case List

### TC-P: Positive Test Cases

| ID | Test Case | Summary | Expected Result |
|----|-----------|---------|-----------------|
| TC-P-01 | Create manual attendance with full details | Fill all fields: driver, date, check-in, check-out, status=Present, via_app=false | Record created, work minutes computed, redirect with success |
| TC-P-02 | Create manual attendance — clock-in only | Fill driver, date, check-in only, leave check-out empty, status=IN_PROGRESS | Record created with null last_out_time, null total_work_minutes |
| TC-P-03 | View attendance details | Click show action on existing record | Show page with driver name, date, times, status, via_app badge |
| TC-P-04 | Edit attendance — change times | Update first_in_time and last_out_time | Work minutes recomputed, redirect with success |
| TC-P-05 | Edit attendance — change driver | Change driver_id | Updated with new driver, unique re-validated |
| TC-P-06 | Soft-delete (destroy) attendance | Delete existing record | Record soft-deleted, activity logged, redirect to Transport Master |
| TC-P-07 | Restore trashed attendance | Restore from trash | Record restored (no reactivation), activity logged |
| TC-P-08 | Force delete trashed attendance | Permanently delete | Record permanently removed, activity logged |
| TC-P-09 | List trashed attendance | View trash page | Only soft-deleted records shown |
| TC-P-10 | QR scan clock-in | Scan valid QR code with scan_type=IN | Record created with first_in_time=now, Present, via_app=1 |
| TC-P-11 | QR scan clock-out after clock-in | Scan valid QR code with scan_type=OUT after IN | Last_out_time updated, work minutes computed |
| TC-P-12 | QR scan clock-out without prior IN | Scan OUT with no prior attendance | Record created with only last_out_time, warning message |
| TC-P-13 | Web manual attendance clock-in | POST manualAttendance with type='IN' driver_id | Clock-in recorded, JSON response with driver info |
| TC-P-14 | Web manual attendance clock-out | POST manualAttendance with type='OUT' after IN | Clock-out time set, work minutes computed |
| TC-P-15 | Web manual attendance clock-out without IN | POST manualAttendance type='OUT' with no prior IN | Record created with last_out_time, warning |
| TC-P-16 | Filter attendance by driver | Select driver from dropdown, submit search | Only matching driver attendance shown |
| TC-P-17 | Filter attendance by status = Present | Select "Present" status filter | Only Present records shown (`attendance_status = 'Present'`) |
| TC-P-18 | Filter attendance by status = On Leave | Select "On Leave" status filter | Only Absent records shown (`attendance_status = 'Absent'`) |
| TC-P-19 | QR page loads with driver dropdown populated | Navigate to `/transport/driver-attendance/qr` | Form has driver list, both scan and manual tabs functional |
| TC-P-20 | Tab loads with attendance listing via Staff Management tab | Staff Management tab clicked | Driver Attendance pane loaded with paginated data |

### TC-N: Negative Test Cases

| ID | Test Case | Summary | Expected Result |
|----|-----------|---------|-----------------|
| TC-N-01 | Create duplicate attendance for same driver+date | Submit with existing driver_id and attendance_date | "Attendance for this driver on the selected date already exists." |
| TC-N-02 | Create with invalid driver_id | driver_id=99999 (non-existent) | "The selected driver id is invalid." |
| TC-N-03 | Create with empty first_in_time | Submit without check-in time (required field) | "The first in time field is required." |
| TC-N-04 | Create with non-boolean via_app | via_app='xyz' (not boolean) | Validation error on via_app |
| TC-N-05 | Access index without tenant.driver-attendance.viewAny | User lacks permission | 403 Access Denied |
| TC-N-06 | Access create without tenant.driver-attendance.create | User lacks create permission | 403 Access Denied |
| TC-N-07 | Access edit without tenant.driver-attendance.update | User lacks update permission | 403 Access Denied |
| TC-N-08 | Attempt destroy without tenant.driver-attendance.delete | User lacks delete permission | 403 Access Denied |
| TC-N-09 | Access trash without tenant.driver-attendance.restore | User lacks restore permission | 403 Access Denied |
| TC-N-10 | Attempt forceDelete without tenant.driver-attendance.forceDelete | User lacks forceDelete permission | 403 Access Denied |
| TC-N-11 | QR scan with invalid QR code | Scan non-existent qr_code | 422 "The selected qr code is invalid." |
| TC-N-12 | QR scan with invalid scan_type | scan_type='INVALID' (not IN/OUT) | 422 "The selected scan type is invalid." |
| TC-N-13 | QR scan with missing qr_code | Send blank qr_code | 422 "The qr code field is required." |
| TC-N-14 | Manual attendance with invalid driver_id | POST driver_id=-1 | 422 validation error |
| TC-N-15 | Manual attendance with invalid type | POST type='INVALID' | 422 validation error |
| TC-N-16 | Restore non-trashed (active) record | Call restore on non-deleted record | 404 — `onlyTrashed()` finds no record |
| TC-N-17 | Force delete non-trashed record | Call forceDelete on active record | 404 — `onlyTrashed()` finds no record |
| TC-N-18 | Edit non-existent ID | `/transport/driver-attendance/99999/edit` | 404 from `findOrFail()` |
| TC-N-19 | Show non-existent ID | `/transport/driver-attendance/99999` | 404 from `findOrFail()` |
| TC-N-20 | Store POST without tenant.driver-attendance.create | DriverAttendanceRequest authorize fails | 403 Access Denied |
| TC-N-21 | Update PUT without tenant.driver-attendance.update | DriverAttendanceRequest authorize fails | 403 Access Denied |

### TC-D: Data Integrity Test Cases

| ID | Test Case | Summary | Expected Result |
|----|-----------|---------|-----------------|
| TC-D-01 | Verify `uq_driver_day` unique constraint at DB level | Insert duplicate (driver_id, attendance_date) via raw SQL | DB constraint violation error |
| TC-D-02 | Verify soft-delete preserves data | Delete record, check DB | `deleted_at` IS NOT NULL, all data preserved |
| TC-D-03 | Verify restore does NOT reactivate | Restore trashed record | Record restored, no `is_active` flag set (no such column) |
| TC-D-04 | Verify force delete permanently removes record | Force delete, check DB | Record removed from `tpt_driver_attendance` |
| TC-D-05 | Verify scan log cascade on attendance delete | Delete attendance with scan logs | `tpt_driver_attendance_log` rows cascade-deleted |
| TC-D-06 | Verify driver FK constraint on attendance | Delete driver that has attendance records | FK CASCADE deletes attendance records |
| TC-D-07 | Verify `via_app` cast as boolean | Create with via_app=1, query model | `$record->via_app` returns `true` (boolean) |
| TC-D-08 | Verify `attendance_date` cast as date | Query model, check type | `$record->attendance_date` is Carbon instance (date only) |
| TC-D-09 | Verify `total_work_minutes` is integer | Query model | `$record->total_work_minutes` is int or null |
| TC-D-10 | **⚠️ GAP: Verify attendance_status DDL vs form mismatch** | Insert via form with string 'Present' | FK constraint violation — DDL expects INT referencing sys_dropdown_table |
| TC-D-11 | **⚠️ GAP: Verify trash blade field `check_in_time` doesn't exist** | Trash page for attendance with times | Blank/null displayed instead of formatted time |
| TC-D-12 | **⚠️ GAP: Verify toggleStatus route returns 500** | POST to `/transport/driver-attendance/{id}/toggle-status` | 500 error — method does not exist |
| TC-D-13 | Verify activity_log entry on destroy | Check activity_log table | Entry: type='Deleted', message='Driver attendance moved to trash' |
| TC-D-14 | Verify activity_log entry on restore | Check activity_log table | Entry: type='Restored', message='Driver attendance restored' |
| TC-D-15 | Verify activity_log entry on forceDelete | Check activity_log table | Entry: type='ForceDelete', message='Driver attendance permanently deleted' |

### TC-CR: Code Review Test Cases

| ID | Priority | Test Case | Source | Expected Result |
|----|----------|-----------|--------|-----------------|
| TC-CR-01 | P1 | Verify `Gate::authorize()` in `index()` | `DriverAttendanceController.php:21` | `tenant.driver-attendance.viewAny` |
| TC-CR-02 | P1 | Verify `Gate::authorize()` in `create()` | `DriverAttendanceController.php:52` | `tenant.driver-attendance.create` |
| TC-CR-03 | P1 | Verify `Gate::authorize()` in `store()` | `DriverAttendanceController.php:64` | `tenant.driver-attendance.create` |
| TC-CR-04 | P1 | Verify `Gate::authorize()` in `show()` | `DriverAttendanceController.php:99` | `tenant.driver-attendance.view` |
| TC-CR-05 | P1 | Verify `Gate::authorize()` in `edit()` | `DriverAttendanceController.php:111` | `tenant.driver-attendance.update` |
| TC-CR-06 | P1 | Verify `Gate::authorize()` in `update()` | `DriverAttendanceController.php:124` | `tenant.driver-attendance.update` |
| TC-CR-07 | P1 | Verify `Gate::authorize()` in `destroy()` | `DriverAttendanceController.php:161` | `tenant.driver-attendance.delete` |
| TC-CR-08 | P1 | Verify `Gate::authorize()` in `trashed()` | `DriverAttendanceController.php:177` | `tenant.driver-attendance.restore` |
| TC-CR-09 | P1 | Verify `Gate::authorize()` in `restore()` | `DriverAttendanceController.php:189` | `tenant.driver-attendance.restore` |
| TC-CR-10 | P1 | Verify `Gate::authorize()` in `forceDelete()` | `DriverAttendanceController.php:205` | `tenant.driver-attendance.forceDelete` |
| TC-CR-11 | P1 | Verify `activityLog()` in `destroy()` | `DriverAttendanceController.php:166` | "Driver attendance moved to trash" |
| TC-CR-12 | P1 | Verify `activityLog()` in `restore()` | `DriverAttendanceController.php:194` | "Driver attendance restored" |
| TC-CR-13 | P1 | Verify `activityLog()` in `forceDelete()` | `DriverAttendanceController.php:210` | "Driver attendance permanently deleted" |
| TC-CR-14 | P2 | **⚠️ GAP: Verify `activityLog()` MISSING in `store()`** | `DriverAttendanceController.php:79-87` | No activityLog() call after create |
| TC-CR-15 | P2 | **⚠️ GAP: Verify `activityLog()` MISSING in `update()`** | `DriverAttendanceController.php:141-148` | No activityLog() call after update |
| TC-CR-16 | P2 | Verify `DriverAttendanceRequest@authorize()` for POST | `DriverAttendanceRequest.php:16-17` | `tenant.driver-attendance.create` |
| TC-CR-17 | P2 | Verify `DriverAttendanceRequest@authorize()` for PUT/PATCH | `DriverAttendanceRequest.php:19` | `tenant.driver-attendance.update` |
| TC-CR-18 | P2 | Verify `prepareForValidation()` normalizes `via_app` | `DriverAttendanceRequest.php:68-69` | `filter_var($this->via_app, FILTER_VALIDATE_BOOLEAN)` |
| TC-CR-19 | P2 | Verify unique rule on `driver_id` ignores current record | `DriverAttendanceRequest.php:31-34` | 3 fallback route params for ignore |
| TC-CR-20 | P2 | Verify unique rule on `attendance_date` uses `where` clause | `DriverAttendanceRequest.php:40-44` | `where('driver_id', $this->driver_id)` |
| TC-CR-21 | P2 | Verify `show()` eager-loads driver | `DriverAttendanceController.php:101` | `TptDriverAttendance::with(['driver'])` |
| TC-CR-22 | P2 | Verify `index()` eager-loads driver | `DriverAttendanceController.php:23` | `TptDriverAttendance::with(['driver'])` |
| TC-CR-23 | P2 | Verify `forceDelete()` uses `onlyTrashed()` not `withTrashed()` | `DriverAttendanceController.php:207` | Only trashed records can be force-deleted |
| TC-CR-24 | P2 | **⚠️ GAP: Verify `toggleStatus` route has no controller method** | `web.php:186` vs Controller | Route registered but method NOT implemented |
| TC-CR-25 | P2 | **⚠️ GAP: Verify index blade uses `tenant.driver-attendance.edit` (wrong permission)** | `driver-attendance/index.blade.php:50,100` | 'edit' not valid — should be 'update' |
| TC-CR-26 | P2 | Verify `destroy()` redirects to `transport.transport-master.index` | `DriverAttendanceController.php:168` | Redirect to Transport Master hub |
| TC-CR-27 | P2 | **⚠️ GAP: Verify `trash.blade.php` uses non-existent `check_in_time`** | `trash.blade.php:38,53,58` | Field does not exist — should be `first_in_time`/`last_out_time` |
| TC-CR-28 | P2 | **⚠️ GAP: Verify `trash.blade.php` uses non-existent `geo_lat`/`geo_lng`** | `trash.blade.php:64` | Geo columns not in migration |
| TC-CR-29 | P2 | **⚠️ GAP: Verify `trash.blade.php` uses `created_at` instead of `attendance_date`** | `trash.blade.php:45` | Should show attendance_date |
| TC-CR-30 | P2 | Verify `store()` manually maps fields instead of `$request->validated()` | `DriverAttendanceController.php:79-87` | Deviates from standard pattern |
| TC-CR-31 | P2 | Verify `update()` manually maps fields instead of `$request->validated()` | `DriverAttendanceController.php:141-148` | Deviates from standard pattern |
| TC-CR-32 | P2 | **⚠️ GAP: Verify `attendance_status` has no validation rule in FormRequest** | `DriverAttendanceRequest.php:27-60` | No rule defined — mass-assignment without validation |
| TC-CR-33 | P3 | **⚠️ GAP: Verify `last_out_time.after` message is dead code** | `DriverAttendanceRequest.php:82-83` | Message defined but no `after:first_in_time` rule exists |
| TC-CR-34 | P2 | Verify `store()` flash message is hardcoded not using `flash()` | `DriverAttendanceController.php:89-91` | `->with('success', 'Driver attendance saved successfully')` |
| TC-CR-35 | P2 | Verify `update()` flash message is hardcoded | `DriverAttendanceController.php:151-153` | `->with('success', 'Driver attendance updated successfully')` |
| TC-CR-36 | P2 | **⚠️ GAP: Verify DDL `attendance_status` is UNSIGNED INT FK but controller stores strings** | Migration line 21 vs Controller line 85 | Data type mismatch — potential FK violation |
| TC-CR-37 | P2 | Verify `staffmgmt.blade.php` missing `:active` attribute | `staffmgmt.blade.php:14` | No default tab specified |
| TC-CR-38 | P2 | Verify no `withQueryString()` on index paginator | `DriverAttendanceController.php:41` | Filter params not preserved across pages |
| TC-CR-39 | P2 | Verify no `->appends(['tab'=>'driver_attendance'])` on pagination | `driver-attendance/index.blade.php:124` | Tab context lost on page change |
| TC-CR-40 | P2 | Verify `permissionslist.php` has `driver-attendance` group | `permissionslist.php:316` | `'driver-attendance' => $crud` under Staff Management |
| TC-CR-41 | P3 | Verify breadcrumb config has two entries | `breadcrumb.php:681-682` | Both `staff-mgmt` and `drive-attendance` |
| TC-CR-42 | P2 | Verify model `$casts` — all datetime fields | `TptDriverAttendance.php:31-37` | `attendance_date`=date, `first_in_time`=datetime, `last_out_time`=datetime, `total_work_minutes`=integer, `via_app`=boolean |
| TC-CR-43 | P2 | Verify `DriverAttendancePolicy` has 7 methods | `DriverAttendancePolicy.php:12-45` | viewAny, view, create, update, delete, restore, forceDelete |
| TC-CR-44 | P2 | Verify no `update()` change tracking | `DriverAttendanceController.php:124-149` | No `getOriginal()`/`getChanges()` — audit gap |
| TC-CR-45 | P2 | Verify `scanQrAttendance()` inline validation | `DriverAttendanceController.php:241-244` | `Validator::make()` with 2 rules |
| TC-CR-46 | P2 | Verify `manualAttendance()` inline validation | `DriverAttendanceController.php:342-344` | `$request->validate()` with 2 rules |
| TC-CR-47 | P2 | **⚠️ GAP: Verify `create.blade.php` attendance_status select value bug** | `create.blade.php:109` | `{{ old('attendance_status') }}` without `== $status` — no option selected |
| TC-CR-48 | P1 | Verify `staffmgmt.blade.php` has `@can('tenant.driver-attendance.viewAny')` for include | `staffmgmt.blade.php:17-18` | Double security: nav-tab permission + @can guard |
| TC-CR-49 | P2 | Verify `restore()` does NOT set `is_active=true` | `DriverAttendanceController.php:191-192` | Only `restore()` called — no reactivation |
| TC-CR-50 | P3 | Verify `destroy()` does NOT set `is_active=false` before delete | `DriverAttendanceController.php:163-164` | Direct `delete()` — no deactivation step (no is_active column) |

---

## 7. CODE-TRACE: Line-by-Line Method Trace

### CODE-TRACE-01: `index(Request $request)` — DriverAttendanceController Lines 19-44

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 21 | `Gate::authorize('tenant.driver-attendance.viewAny')` | Authorization gate — user must have viewAny permission |
| 02 | 23 | `$query = TptDriverAttendance::with(['driver'])` | Start query builder with eager-loaded driver relationship |
| 03 | 25-27 | `if ($request->filled('driver_id')) { $query->where('driver_id', $request->driver_id); }` | Conditional exact-match driver filter |
| 04 | 29-38 | `if ($request->filled('status')) { ... 'present' → 'Present', 'leave' → 'Absent', else → LIKE }` | Conditional status filter with 3-tier mapping |
| 05 | 40 | `$query->orderBy('id', 'DESC')` | Order by id descending (most recent first) |
| 06 | 40-41 | `->paginate(20)` | Paginate 20 per page — **NO `withQueryString()`** |
| 07 | 43 | `$driverHelpers = DriverHelper::active()->get()` | Load active drivers for filter dropdown |
| 08 | 44 | `return view('transport::tab_module.staffmgmt', compact('driverAttendance','driverHelpers'))` | Return hub layout with attendance data |

> 🔁 **Tab Flow**: `staffmgmt.blade.php` at line 14-19 renders `x-backend.tab.nav-tab` with tab id `driver_attendance` and `@include('transport::driver-attendance.index')` inside `@can('tenant.driver-attendance.viewAny')`. The `index.blade.php` partial renders the paginated table.

### CODE-TRACE-02: `create()` — DriverAttendanceController Lines 50-56

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 52 | `Gate::authorize('tenant.driver-attendance.create')` | Authorization gate — create permission |
| 02 | 54-55 | `return view('transport::driver-attendance.create', ['drivers' => DriverHelper::active()->get()])` | Return create form with active drivers list |

### CODE-TRACE-03: `store(DriverAttendanceRequest $request)` — DriverAttendanceController Lines 62-91

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 64 | `Gate::authorize('tenant.driver-attendance.create')` | Authorization gate — create permission |
| 02 | 65 | `$date = Carbon::parse($request->attendance_date)` | Parse date string to Carbon |
| 03 | 67-69 | `$firstIn = Carbon::parse($date->toDateString().' '.$request->first_in_time)` | Combine date + time into full DateTime |
| 04 | 71-73 | `$lastOut = $request->last_out_time ? Carbon::parse(...) : null` | Parse last_out_time if provided, else null |
| 05 | 75-77 | `$totalMinutes = $lastOut ? $firstIn->diffInMinutes($lastOut) : null` | Compute work minutes only if both times present |
| 06 | 79-87 | `TptDriverAttendance::create([...])` | Mass-assign all fields manually (not via validated()) |
| 07 | 85 | `'attendance_status' => $request->attendance_status ?: 'IN_PROGRESS'` | Default status = 'IN_PROGRESS' if not provided |
| 08 | 89-91 | `return redirect()->route('transport.driver-attendance.index')->with('success', 'Driver attendance saved successfully')` | Redirect with hardcoded success message |
| 09 | — | **⚠️ GAP: No `activityLog()` call after create** | Activity log missing |

### CODE-TRACE-04: `show($id)` — DriverAttendanceController Lines 97-103

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 99 | `Gate::authorize('tenant.driver-attendance.view')` | Authorization gate — view permission |
| 02 | 101 | `$record = TptDriverAttendance::with(['driver'])->findOrFail($id)` | Eager-load driver, 404 if not found |
| 03 | 103 | `return view('transport::driver-attendance.show', compact('record'))` | Return show view |

### CODE-TRACE-05: `edit($id)` — DriverAttendanceController Lines 109-116

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 111 | `Gate::authorize('tenant.driver-attendance.update')` | Authorization gate — update permission |
| 02 | 113-114 | `$record = TptDriverAttendance::findOrFail($id)` | Find record or 404 |
| 03 | 115 | `'drivers' => DriverHelper::active()->get()` | Load active drivers for dropdown |
| 04 | 113-115 | `return view('transport::driver-attendance.edit', compact('record', 'drivers'))` | Return edit form with data |

### CODE-TRACE-06: `update(DriverAttendanceRequest $request, $id)` — DriverAttendanceController Lines 122-154

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 124 | `Gate::authorize('tenant.driver-attendance.update')` | Authorization gate — update permission |
| 02 | 125 | `$attendance = TptDriverAttendance::findOrFail($id)` | Find record or 404 |
| 03 | 127 | `$date = Carbon::parse($request->attendance_date)` | Parse date string to Carbon |
| 04 | 129-131 | `$firstIn = Carbon::parse($date->toDateString().' '.$request->first_in_time)` | Combine date + time |
| 05 | 133-135 | `$lastOut = $request->last_out_time ? Carbon::parse(...) : null` | Parse last_out_time if provided |
| 06 | 137-139 | `$totalMinutes = $lastOut ? $firstIn->diffInMinutes($lastOut) : null` | Recompute work minutes |
| 07 | 141-149 | `$attendance->update([...])` | Mass-assign all fields manually |
| 08 | 151-153 | `return redirect()->route('transport.driver-attendance.index')->with('success', 'Driver attendance updated successfully')` | Redirect with hardcoded success message |
| 09 | — | **⚠️ GAP: No `activityLog()` call after update** | Activity log missing |
| 10 | — | **⚠️ GAP: No change tracking (`getOriginal()`/`getChanges()`)** | No audit trail of changes |

### CODE-TRACE-07: `destroy($id)` — DriverAttendanceController Lines 159-169

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 161 | `Gate::authorize('tenant.driver-attendance.delete')` | Authorization gate — delete permission |
| 02 | 163 | `$attendance = TptDriverAttendance::findOrFail($id)` | Find record or 404 |
| 03 | 164 | `$attendance->delete()` | Soft-delete (sets deleted_at) — NO is_active deactivation |
| 04 | 166 | `activityLog($attendance, 'Deleted', ['message' => 'Driver attendance moved to trash'])` | Activity log entry |
| 05 | 168-169 | `return redirect()->route('transport.transport-master.index')->with('success', flash('trashed.driver_attendance'))` | Redirect to Transport Master hub |

### CODE-TRACE-08: `trashed()` — DriverAttendanceController Lines 175-181

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 177 | `Gate::authorize('tenant.driver-attendance.restore')` | Authorization gate — restore permission |
| 02 | 179 | `$data = TptDriverAttendance::onlyTrashed()->paginate(20)` | Fetch only soft-deleted records, paginated |
| 03 | 181 | `return view('transport::driver-attendance.trash', compact('data'))` | Return trash view |

### CODE-TRACE-09: `restore($id)` — DriverAttendanceController Lines 187-197

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 189 | `Gate::authorize('tenant.driver-attendance.restore')` | Authorization gate — restore permission |
| 02 | 191 | `$attendance = TptDriverAttendance::onlyTrashed()->findOrFail($id)` | Find soft-deleted record or 404 |
| 03 | 192 | `$attendance->restore()` | Restore (sets deleted_at = NULL) — NO is_active reactivation |
| 04 | 194 | `activityLog($attendance, 'Restored', ['message' => 'Driver attendance restored'])` | Activity log entry |
| 05 | 196-197 | `return redirect()->route('transport.transport-master.index')->with('success', flash('restored.driver_attendance'))` | Redirect to Transport Master hub |

### CODE-TRACE-10: `forceDelete($id)` — DriverAttendanceController Lines 203-213

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 205 | `Gate::authorize('tenant.driver-attendance.forceDelete')` | Authorization gate — forceDelete permission |
| 02 | 207 | `$attendance = TptDriverAttendance::onlyTrashed()->findOrFail($id)` | Find ONLY soft-deleted record (⚠️ not withTrashed) |
| 03 | 208 | `$attendance->forceDelete()` | Permanently delete from DB |
| 04 | 210 | `activityLog($attendance, 'ForceDelete', ['message' => 'Driver attendance permanently deleted'])` | Activity log entry |
| 05 | 212-213 | `return redirect()->route('transport.transport-master.index')->with('success', flash('force_deleted.driver_attendance'))` | Redirect to Transport Master hub |

### CODE-TRACE-11: `showQr()` — DriverAttendanceController Lines 216-221

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 218 | `Gate::authorize('tenant.driver-attendance.viewAny')` | Authorization gate — uses viewAny |
| 02 | 219-220 | `return view('transport::driver-attendance.qr', ['drivers' => DriverHelper::active()->get()])` | Return QR scanner + manual attendance page |

### CODE-TRACE-12: `scan()` — DriverAttendanceController Lines 228-232

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 230 | `Gate::authorize('tenant.driver-attendance.viewAny')` | Authorization gate — uses viewAny |
| 02 | 231 | `return view('transport::driver-attendance.scan')` | Return scan page (⚠️ no scan.blade.php exists) |

> **⚠️ GAP: `scan()` references `transport::driver-attendance.scan` view which does NOT exist in the file system. This would cause a ViewNotFoundException.**

### CODE-TRACE-13: `scanQrAttendance(Request $request)` — DriverAttendanceController Lines 238-331

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 240 | `Gate::authorize('tenant.driver-attendance.create')` | Authorization gate — create permission |
| 02 | 241-244 | `$validator = Validator::make(...)` | Inline validation: qr_code required+exists, scan_type required+in:IN,OUT |
| 03 | 246-250 | `if ($validator->fails()) { return response()->json([...], 422) }` | Return validation error JSON with 422 |
| 04 | 253 | `$driver = DriverHelper::where('user_qr_code', $request->qr_code)->firstOrFail()` | Find driver by QR code |
| 05 | 254-258 | `$today = now()->toDateString(); $lastAttendance = TptDriverAttendance::where('driver_id', $driver->id)->whereDate('attendance_date', $today)->latest('id')->first()` | Find today's latest attendance for driver |
| 06 | 261-288 | **CLOCK IN branch:** if scan_type === 'IN' | |
| 07 | 265-267 | `if ($lastAttendance && is_null($lastAttendance->last_out_time)) { $warning = 'You clocked in earlier but did not clock out.'; }` | Warning only — does NOT prevent clock-in |
| 08 | 269-275 | `$attendance = TptDriverAttendance::create([... first_in_time=now(), attendance_status='Present', via_app=1])` | Create new attendance with Present status |
| 09 | 277-288 | `return response()->json([status=true, type='IN', msg, warning, attendance, driver])` | JSON success response |
| 10 | 293-331 | **CLOCK OUT branch:** scan_type === 'OUT' | |
| 11 | 295-304 | `if ($lastAttendance && !is_null($lastAttendance->first_in_time) && is_null($lastAttendance->last_out_time))` | Has prior IN without OUT — update existing |
| 12 | 301-305 | `$lastAttendance->update([last_out_time=now(), total_work_minutes=diffInMinutes])` | Complete the attendance record |
| 13 | 310-317 | `else { $warning = 'You are clocking out without a previous clock in.'; TptDriverAttendance::create([last_out_time=now(), via_app=1]) }` | Clock-out only (no prior IN) — creates record with only last_out_time |
| 14 | 320-331 | `return response()->json([status=true, type='OUT', msg, warning, attendance, driver])` | JSON success response |

### CODE-TRACE-14: `manualAttendance(Request $request)` — DriverAttendanceController Lines 339-410

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 341 | `Gate::authorize('tenant.driver-attendance.create')` | Authorization gate — create permission |
| 02 | 342-344 | `$request->validate([driver_id => required|exists:tpt_personnel,id, type => required|in:IN,OUT])` | Inline validation |
| 03 | 347-354 | `$now = now(); $today = $now->toDateString(); $last = TptDriverAttendance::where('driver_id', ...)->whereDate('attendance_date', $today)->latest('id')->first()` | Find today's latest attendance |
| 04 | 358-377 | **CLOCK IN branch:** if type === 'IN' | |
| 05 | 360-361 | `if ($last && $last->first_in_time && !$last->last_out_time) { $warning = 'Previous clock-in was not clocked out.'; }` | Warning for orphaned IN |
| 06 | 364-369 | `$attendance = TptDriverAttendance::create([first_in_time=now(), via_app=1])` | Create clock-in — ⚠️ does NOT set attendance_status |
| 07 | 371-377 | `return response()->json([status=true, type='IN', msg, attendance->load('driver'), warning])` | JSON success with eager-loaded driver |
| 08 | 382-409 | **CLOCK OUT branch:** type === 'OUT' | |
| 09 | 382-388 | `if ($last && $last->first_in_time && !$last->last_out_time) { $last->update([last_out_time=now(), total_work_minutes=diffInMinutes]) }` | Complete existing attendance |
| 10 | 393-399 | `else { $warning = 'Clock-out recorded without a previous clock-in.'; TptDriverAttendance::create([last_out_time=now(), via_app=1]) }` | Clock-out only record |
| 11 | 403-409 | `return response()->json([status=true, type='OUT', msg, attendance->load('driver'), warning])` | JSON success response |

---

## 8. Detailed Test Steps

### TC-P-01: Create manual attendance with full details

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user with `tenant.driver-attendance.create` permission | Success |
| 2 | Navigate to Attendance create page (`/transport/driver-attendance/create`) | Create form displayed with driver dropdown |
| 3 | **Verify**: `Gate::authorize('tenant.driver-attendance.create')` at `DriverAttendanceController.php:52` passes | Authorized |
| 4 | **Verify**: `$drivers = DriverHelper::active()->get()` | Driver dropdown populated |
| 5 | Select a driver from the dropdown | Driver selected |
| 6 | Enter attendance_date = today's date (default pre-filled) | Date shown |
| 7 | Enter first_in_time = "08:00" (24h format) | Time input filled |
| 8 | Enter last_out_time = "17:00" | Time input filled |
| 9 | Select attendance_status = "Present" | Dropdown selected |
| 10 | Set via_app switch = OFF (manually unchecked) | via_app = false |
| 11 | Click "Save Attendance" | POST to `/transport/driver-attendance` |
| 12 | **Verify**: `Gate::authorize('tenant.driver-attendance.create')` at line 64 passes | Authorized |
| 13 | **Verify**: `DriverAttendanceRequest` validates: driver_id exists, attendance_date unique for this driver, first_in_time required, last_out_time required, via_app boolean | Validation passes |
| 14 | **Verify**: `$date = Carbon::parse($request->attendance_date)` | Date parsed |
| 15 | **Verify**: `$firstIn = Carbon::parse($date->toDateString().' '.$request->first_in_time)` → "2026-07-22 08:00:00" | Full DateTime |
| 16 | **Verify**: `$lastOut = Carbon::parse(...)` → "2026-07-22 17:00:00" | Full DateTime |
| 17 | **Verify**: `$totalMinutes = $firstIn->diffInMinutes($lastOut)` = 540 (9 hours) | Work minutes computed |
| 18 | **Verify**: `TptDriverAttendance::create([...])` inserts all fields | DB row created |
| 19 | **Verify**: `attendance_status` = 'Present' (as selected) | Status set |
| 20 | **Verify**: `via_app` = false (checkbox unchecked) | Manual entry flagged |
| 21 | **Verify**: Redirected to `transport.driver-attendance.index` | Staff Management tab reloaded |
| 22 | **⚠️ GAP**: `activityLog()` NOT called on store | No activity log entry for create |
| 23 | **Verify**: Attendance record visible in index table | Driver, Date, Check-in 08:00 AM, Check-out 05:00 PM, Duration 9h 0m displayed |

### TC-P-02: Create manual attendance — clock-in only

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with create permission | Success |
| 2 | Navigate to create page | Form displayed |
| 3 | Select driver + enter date + first_in_time = "08:00" | Clock-in filled |
| 4 | Leave last_out_time EMPTY | Check-out omitted |
| 5 | Leave attendance_status UNCHANGED (default = 'IN_PROGRESS') | Status takes DB default |
| 6 | Click "Save" | POST to store |
| 7 | **Verify**: Validation — last_out_time is `required` in Request → **⚠️ Validation FAILS** because `last_out_time` rule is `required` | Form error: "The last out time field is required." |
| 8 | **Note**: FormRequest has `last_out_time` as `required` — cannot create clock-in-only via web form | Workaround: send via direct DB or modify Request |

> **⚠️ GAP: FormRequest requires `last_out_time` as mandatory field (`required` rule), making it impossible to create a clock-in-only record through the web form. The controller logic supports null last_out_time, but the validation layer blocks it.**

### TC-P-03: View attendance details

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user with `tenant.driver-attendance.view` permission | Success |
| 2 | Navigate to Staff Management → Staff Attendance tab | Attendance list |
| 3 | Click show/view action on an attendance row | GET `/transport/driver-attendance/{id}` |
| 4 | **Verify**: `Gate::authorize('tenant.driver-attendance.view')` at line 99 passes | Authorized |
| 5 | **Verify**: `TptDriverAttendance::with(['driver'])->findOrFail($id)` | Record loaded with driver |
| 6 | **Verify**: Show view renders: Driver name, Attendance Date (d M Y format), First In Time (h:i A), Last Out Time (h:i A), Total Work Minutes, Attendance Status (badge), Via App badge | All fields displayed |
| 7 | **Verify**: Via App = Yes (green badge) if true, No (grey badge) if false | Conditional badge colors |
| 8 | **Verify**: Back button links to `transport.driver-attendance.index` | Navigation works |
| 9 | **Verify**: Edit button visible only for users with `tenant.driver-attendance.update` | Conditional rendering |

### TC-P-04: Edit attendance — change times

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user with `tenant.driver-attendance.update` permission | Success |
| 2 | Navigate to Staff Management → find attendance record | List displayed |
| 3 | Click edit action on record | GET `/transport/driver-attendance/{id}/edit` |
| 4 | **Verify**: `Gate::authorize('tenant.driver-attendance.update')` at line 111 passes | Authorized |
| 5 | **Verify**: `TptDriverAttendance::findOrFail($id)` loads existing data | Form pre-filled with current values |
| 6 | **Verify**: Driver dropdown shows `old('driver_id', $record->driver_id)` pre-selected | Correct driver |
| 7 | Change first_in_time from "08:00" to "09:00" | Input updated |
| 8 | Change last_out_time from "17:00" to "18:00" | Input updated |
| 9 | Ensure via_app checkbox reflects current value with hidden 0 fallback | Switch state correct |
| 10 | Click "Update Attendance" | PUT `/transport/driver-attendance/{id}` |
| 11 | **Verify**: `Gate::authorize('tenant.driver-attendance.update')` at line 124 passes | Authorized |
| 12 | **Verify**: `DriverAttendanceRequest` validates (unique ignores current record) | Validation passes |
| 13 | **Verify**: `$firstIn` recomputed as `Carbon::parse($date.' 09:00')` | New time used |
| 14 | **Verify**: `$totalMinutes = $firstIn->diffInMinutes($lastOut)` = 540 (9h) | Work minutes recomputed |
| 15 | **Verify**: `$attendance->update([...])` persists all changes | DB updated |
| 16 | **⚠️ GAP**: No `activityLog()` called after update | No audit trail |
| 17 | **⚠️ GAP**: No change tracking — `getOriginal()`/`getChanges()` not used | Old values not logged |
| 18 | **Verify**: Redirected to `transport.driver-attendance.index` with hardcoded success message | "Driver attendance updated successfully" |

### TC-P-05: Edit attendance — change driver

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with update permission | Success |
| 2 | Edit an attendance record | Edit form loaded |
| 3 | Change driver_id to a different active driver | New driver selected |
| 4 | Keep date same, adjust times if needed | Form complete |
| 5 | Click "Update" | PUT request |
| 6 | **Verify**: `Rule::unique('tpt_driver_attendance', 'driver_id')->where('attendance_date', ...)->ignore(...)` | Unique check passes if new driver doesn't have attendance for same date |
| 7 | **Verify**: If new driver already has attendance on same date → "Attendance for this driver on the selected date already exists." | Unique violation blocks change |

### TC-P-06: Soft-delete (destroy) attendance

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user with `tenant.driver-attendance.delete` permission | Success |
| 2 | Navigate to Staff Management → Staff Attendance tab | Attendance list |
| 3 | Click delete action on an attendance record | Confirm dialog (browser native or Swal) |
| 4 | Confirm deletion | DELETE `/transport/driver-attendance/{id}` |
| 5 | **Verify**: `Gate::authorize('tenant.driver-attendance.delete')` at line 161 passes | Authorized |
| 6 | **Verify**: `TptDriverAttendance::findOrFail($id)` | Record found |
| 7 | **Verify**: `$attendance->delete()` — soft-delete (sets deleted_at) | `deleted_at` IS NOT NULL |
| 8 | **Verify**: `activityLog($attendance, 'Deleted', ['message' => 'Driver attendance moved to trash'])` | Activity log entry created |
| 9 | **Verify**: Redirected to `transport.transport-master.index` (⚠️ not driver-attendance.index) | Transport Master hub |
| 10 | **Verify**: Flash message `flash('trashed.driver_attendance')` | Success notification |
| 11 | **Verify**: Record no longer visible in index (onlyTrashed not queried) | Removed from active list |

### TC-P-07: Restore trashed attendance

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user with `tenant.driver-attendance.restore` permission | Success |
| 2 | Navigate to trash page (`/transport/driver-attendance/trash/view`) | Trashed records list |
| 3 | **Verify**: `Gate::authorize('tenant.driver-attendance.restore')` at line 177 passes | Authorized |
| 4 | **Verify**: `TptDriverAttendance::onlyTrashed()->paginate(20)` | Soft-deleted records only |
| 5 | Locate a trashed attendance record | Record with deleted_at IS NOT NULL |
| 6 | Click Restore action | GET `/transport/driver-attendance/{id}/restore` |
| 7 | **Verify**: `Gate::authorize('tenant.driver-attendance.restore')` at line 189 passes | Authorized |
| 8 | **Verify**: `TptDriverAttendance::onlyTrashed()->findOrFail($id)` | Only trashed record found |
| 9 | **Verify**: `$attendance->restore()` sets `deleted_at = NULL` | Record restored |
| 10 | **Verify**: `activityLog($attendance, 'Restored', ['message' => 'Driver attendance restored'])` | Activity log entry |
| 11 | **Verify**: Redirected to `transport.transport-master.index` | Transport Master hub |
| 12 | **Verify**: Flash message `flash('restored.driver_attendance')` | Success notification |
| 13 | **Verify**: Record visible again in active index list | Restored data intact |

### TC-P-08: Force delete trashed attendance

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user with `tenant.driver-attendance.forceDelete` permission | Success |
| 2 | Navigate to trash page | Trashed records list |
| 3 | Locate a trashed attendance record | Record with deleted_at IS NOT NULL |
| 4 | Click Force Delete action | DELETE `/transport/driver-attendance/{id}/force-delete` |
| 5 | **Verify**: `Gate::authorize('tenant.driver-attendance.forceDelete')` at line 205 passes | Authorized |
| 6 | **Verify**: `TptDriverAttendance::onlyTrashed()->findOrFail($id)` | Only trashed record found |
| 7 | **Verify**: `$attendance->forceDelete()` | Record permanently removed from DB |
| 8 | **Verify**: `activityLog($attendance, 'ForceDelete', ['message' => 'Driver attendance permanently deleted'])` | Activity log entry |
| 9 | **Verify**: Redirected to `transport.transport-master.index` | Transport Master hub |
| 10 | **Verify**: Flash message `flash('force_deleted.driver_attendance')` | Success notification |
| 11 | DB check: `tpt_driver_attendance WHERE id = X` | 0 rows (permanently gone) |
| 12 | DB check: `tpt_driver_attendance_log WHERE attendance_id = X` | 0 rows (cascade deleted) |

### TC-P-09: List trashed attendance

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user with `tenant.driver-attendance.restore` permission | Success |
| 2 | Navigate to `/transport/driver-attendance/trash/view` | Trash page |
| 3 | **Verify**: `Gate::authorize('tenant.driver-attendance.restore')` at line 177 passes | Authorized |
| 4 | **Verify**: `TptDriverAttendance::onlyTrashed()->paginate(20)` | Paginated trashed records |
| 5 | **Verify**: Table columns: Date, Driver, Check-in, Check-out, Duration, Location, Action | Columns rendered |
| 6 | **Verify**: Action column uses `x-backend.table.action-trashed` with restore/forceDelete permissions | Trash actions conditional |
| 7 | **⚠️ GAP**: Check-in/Check-out columns show blank — blade uses non-existent `check_in_time`/`check_out_time` | Bug: fields don't exist |
| 8 | **Verify**: Empty state: "No Trashed Records Found" when no soft-deleted records | Empty message displayed |

### TC-P-14: Web manual attendance clock-out after clock-in

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure driver has a clock-in today (first_in_time set, last_out_time null) | Existing IN |
| 2 | Navigate to QR page → Manual tab | QR page |
| 3 | Click "Clock-Out" button | `openManual('OUT')` called |
| 4 | Select same driver from dropdown | Driver selected |
| 5 | Click "Save" | `saveManual()` |
| 6 | **Verify**: `$last = TptDriverAttendance::where(...)->whereDate(..., $today)->latest('id')->first()` | Finds existing IN record |
| 7 | **Verify**: `$last->first_in_time && !$last->last_out_time` = true | Eligible for clock-out |
| 8 | **Verify**: `$last->update([last_out_time=now(), total_work_minutes=diffInMinutes])` | Existing record updated |
| 9 | **Verify**: Response `{status: true, type: 'OUT', attendance: {..., last_out_time, total_work_minutes}}` | Updated record in response |
| 10 | **Verify**: `showManualResult()` displays driver name, type badge "Clocked OUT", out time | UI updated |

### TC-P-15: Web manual attendance clock-out without clock-in

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure driver has NO attendance today | No prior IN |
| 2 | QR page → Manual tab → Click Clock-Out | Manual mode |
| 3 | Select driver, click Save | POST |
| 4 | **Verify**: `$last` is null (no prior record) | No prior attendance |
| 5 | **Verify**: Falls to `else` block at line 393 | Warning path |
| 6 | **Verify**: `$warning = 'Clock-out recorded without a previous clock-in.'` | Warning set |
| 7 | **Verify**: `TptDriverAttendance::create([last_out_time=now(), via_app=1])` | Creates record with only out time |
| 8 | **Verify**: Response includes `warning` text | Warning displayed via Swal toast |

### TC-P-16: Filter attendance by driver

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user with viewAny permission | Success |
| 2 | Navigate to Staff Management → Staff Attendance tab | Attendance list with filter |
| 3 | **Verify**: Driver filter dropdown populated with `$driverHelpers` (active drivers) | Dropdown has options |
| 4 | Select a specific driver from the dropdown | Driver selected |
| 5 | Click "Search" button | GET with `?driver_id=X` |
| 6 | **Verify**: `DriverAttendanceController.php:25-27` → `$query->where('driver_id', $request->driver_id)` | Exact match applied |
| 7 | **Verify**: Only attendance records for selected driver shown | Filtered results |
| 8 | **Verify**: Other drivers' records excluded | Not in results |
| 9 | **⚠️ GAP**: `withQueryString()` NOT used → navigating to page 2 loses filter | Filter param dropped |

### TC-P-17: Filter attendance by status = Present

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with viewAny | Success |
| 2 | Staff Attendance tab | List displayed |
| 3 | Select "Present" from Status dropdown | `status=present` |
| 4 | Click "Search" | GET `?status=present` |
| 5 | **Verify**: `DriverAttendanceController.php:31-32` → `where('attendance_status', 'Present')` | Exact match |
| 6 | **Verify**: Only Present records shown | Filter correct |

### TC-P-18: Filter attendance by status = On Leave

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with viewAny | Success |
| 2 | Select "On Leave" from Status dropdown | `status=leave` |
| 3 | Click "Search" | GET `?status=leave` |
| 4 | **Verify**: `DriverAttendanceController.php:33-34` → `where('attendance_status', 'Absent')` | Mapped to 'Absent' |
| 5 | **Verify**: Only Absent records shown | Filter correct |

### TC-P-19: QR page loads with driver dropdown populated

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with viewAny permission | Success |
| 2 | Navigate to `/transport/driver-attendance/qr` | QR page |
| 3 | **Verify**: `Gate::authorize('tenant.driver-attendance.viewAny')` at line 218 passes | Authorized |
| 4 | **Verify**: Scan QR tab is active by default | First tab active |
| 5 | **Verify**: Manual tab available with driver dropdown | Second tab present |
| 6 | Click "Manual" tab | Manual mode |
| 7 | **Verify**: `$drivers` populated via `DriverHelper::active()->get()` passed to view | Driver dropdown has options |
| 8 | **Verify**: Clock-In and Clock-Out buttons visible in both Scan and Manual tabs | Dual buttons |
| 9 | **Verify**: QR scanner area hidden initially (shown only after clicking Clock-In/Out) | Scanner starts on demand |

### TC-P-20: Tab loads with attendance listing via Staff Management tab

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with viewAny permission | Success |
| 2 | Navigate to `/transport` (Transport module) | Page loads |
| 3 | Click "Staff Management" tab | Tab group switches |
| 4 | **Verify**: `staffmgmt.blade.php` renders `x-backend.tab.nav-tab` with `['id' => 'driver_attendance', 'label' => 'Staff Attendance', 'permission' => 'tenant.driver-attendance.viewAny']` | Tab visible |
| 5 | **Verify**: `@can('tenant.driver-attendance.viewAny')` passes → `@include('transport::driver-attendance.index')` rendered | Tab content loaded |
| 6 | **Verify**: `driverAttendance` paginated list (20 per page) displayed | Table with data |
| 7 | **Verify**: Columns: Driver, Date, Check-in, Check-out, Duration, Location, Action | All columns present |
| 8 | **Verify**: Action column conditional on `@canany(['tenant.driver-attendance.edit','tenant.driver-attendance.delete'])` | Buttons shown/hidden based on permissions |

### TC-P-21: Mobile API scan driver attendance IN

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Companion app sends POST to mobile API `driver-attendance/scan` with `{qr_code: "...", scan_type: "IN"}` | API call |
| 2 | **Verify**: `MobileAttendanceService.scanDriverAttendance()` called | Service method invoked |
| 3 | **Verify**: Validator checks qr_code required+exists, scan_type required+in:IN,OUT | Validation passes |
| 4 | **Verify**: `DriverHelper::where('user_qr_code', ...)->firstOrFail()` | Driver found |
| 5 | **Verify**: `TptDriverAttendance::firstOrNew([driver_id, attendance_date => today])` | Existing or new record |
| 6 | **Verify**: If new: `fill([first_in_time=now(), attendance_status='Present', via_app=1])->save()` | New record created |
| 7 | **Verify**: If existing with prior IN and no OUT: warning set but still updates first_in_time | Warning returned |
| 8 | **Verify**: Response `{status: 'ok', type: 'IN', message: 'Clocked In Successfully', attendance: {id, clock_in, date}, driver: {name, role, phone}}` | JSON response |

### TC-P-22: Mobile API manual driver attendance OUT

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Companion app POST to `driver-attendance/manual` with `{driver_id: X, type: 'OUT'}` | API call |
| 2 | **Verify**: `MobileAttendanceService.manualDriverAttendance()` called | Service method invoked |
| 3 | **Verify**: Validator checks driver_id required+exists, type required+in:IN,OUT | Validation passes |
| 4 | **Verify**: `firstOrNew` finds existing today's attendance | Record found |
| 5 | **Verify**: Existing record has first_in_time and no last_out_time → updates with last_out_time=now + total_work_minutes | Record completed |
| 6 | **Verify**: If no prior IN → warning set, creates record with only last_out_time | Warning path |
| 7 | **Verify**: Response `{status: 'ok', type: 'OUT', attendance: {id, clock_in, clock_out, work_minutes, date}, driver: {name, role}}` | JSON response |

### TC-P-23: Mobile API scan attendance with prior unmatched IN — warning

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Driver has today's attendance with first_in_time set, last_out_time null | Unmatched IN |
| 2 | Companion app sends scan IN again | Second clock-in |
| 3 | **Verify**: `$attendance->exists` = true, `$attendance->first_in_time && !$attendance->last_out_time` | Warning condition met |
| 4 | **Verify**: `$warning = 'Previous clock-in was not clocked out.'` | Warning set |
| 5 | **Verify**: `$attendance->first_in_time = $now` (updated to latest) | First_in_time overwritten |
| 6 | **Verify**: Response includes `warning` key | Client shows warning |

### TC-P-24: Filter with status custom value

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send GET with `?status=Half-Day` | Custom status value |
| 2 | **Verify**: Falls to `else` branch at line 36: `where('attendance_status', 'like', '%Half-Day%')` | LIKE match |
| 3 | **Verify**: Records with 'Half-Day' in attendance_status returned | Partial match |

### TC-P-25: Show QR page with dual mode tabs

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with viewAny | Success |
| 2 | Navigate to `/transport/driver-attendance/qr` | QR page |
| 3 | **Verify**: Two tabs rendered: "Scan QR" (active) and "Manual" | Bootstrap nav-tabs |
| 4 | **Verify**: Scan tab has Clock-In (btn-success) and Clock-Out (btn-danger) buttons | Buttons visible |
| 5 | **Verify**: Manual tab has same Clock-In/Out buttons + hidden driver dropdown form | Dual mode ready |
| 6 | Click Clock-In on Scan tab | Scanner activates with green badge "CLOCK IN" |
| 7 | **Verify**: Live date and time display updates every second | Real-time clock |

### TC-P-10: QR scan clock-in

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user with `tenant.driver-attendance.create` permission | Success |
| 2 | Navigate to QR page (`/transport/driver-attendance/qr`) | QR page with Scan QR and Manual tabs |
| 3 | **Verify**: `Gate::authorize('tenant.driver-attendance.viewAny')` at `DriverAttendanceController.php:218` passes | Authorized |
| 4 | Click "Clock-In" button on Scan QR tab | Scan mode set to 'IN', scanner activates |
| 5 | **Verify**: `startScan('IN')` called → `scanType = 'IN'` | Entry type indicator shows "CLOCK IN" |
| 6 | **Verify**: QR scanner initializes with `Html5Qrcode` using rear camera (`facingMode: "environment"`) | Camera viewfinder visible |
| 7 | Point camera at a valid driver QR code (exists in `tpt_personnel.user_qr_code`) | QR code decoded |
| 8 | **Verify**: `onScan(decodedText)` called → debounce check passes (not duplicate within 3s) | Scanning locked |
| 9 | **Verify**: `fetch()` POST to `/transport/driver-attendance/mark-attendance` with `{qr_code: "...", scan_type: "IN"}` | AJAX request sent |
| 10 | **Verify**: `Gate::authorize('tenant.driver-attendance.create')` at line 240 passes | Authorized |
| 11 | **Verify**: `Validator::make()` validates qr_code exists + scan_type IN | Validation passes |
| 12 | **Verify**: `DriverHelper::where('user_qr_code', ...)->firstOrFail()` | Driver found |
| 13 | **Verify**: `$today = now()->toDateString()` | Today's date used |
| 14 | **Verify**: `$lastAttendance = TptDriverAttendance::where(...)->latest('id')->first()` | Prior today's attendance checked |
| 15 | **Verify**: Since scan_type='IN', `TptDriverAttendance::create([first_in_time=now(), attendance_status='Present', via_app=1])` | New attendance created |
| 16 | **Verify**: `return response()->json([status=true, type='IN', msg='Clocked In Successfully', driver data])` | JSON response received |
| 17 | **Verify**: `showScanResult(res)` called → result box shows driver name, role, Clocked IN badge, time | UI updated |
| 18 | **Verify**: If prior unmatched IN exists, `warning` populated → SweetAlert2 warning toast | Warning shown (auto-dismiss 8s) |
| 19 | **Verify**: After 5s timeout `resetScan()` → scanner ready for next scan | Auto-reset |

### TC-P-11: QR scan clock-out after clock-in

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure driver has an attendance record today with first_in_time set, last_out_time null | Prior IN exists |
| 2 | Click "Clock-Out" button on QR page | Scan mode set to 'OUT' |
| 3 | Scan same driver's QR code | QR decoded |
| 4 | **Verify**: `scanQrAttendance()` receives scan_type='OUT' | Clock-out branch |
| 5 | **Verify**: `$lastAttendance` found (existing IN record) | Prior attendance exists |
| 6 | **Verify**: `$lastAttendance->first_in_time` NOT null AND `$lastAttendance->last_out_time` IS null | Eligible for clock-out |
| 7 | **Verify**: `$lastAttendance->update([last_out_time=now(), total_work_minutes=diffInMinutes(...)])` | Record updated — NOT created |
| 8 | **Verify**: `total_work_minutes` computed correctly | e.g., 480 min for 8h shift |
| 9 | **Verify**: Response `{status: true, type: 'OUT', msg: 'Clocked Out Successfully', attendance: {..., last_out_time, total_work_minutes}}` | JSON success |

### TC-P-12: QR scan clock-out without prior clock-in

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure driver has NO attendance record today | No prior IN |
| 2 | Click "Clock-Out", scan driver QR | QR decoded |
| 3 | **Verify**: `$lastAttendance` is null | No prior record |
| 4 | **Verify**: Falls to `else` block at line 309 | Warning path |
| 5 | **Verify**: `$warning = 'You are clocking out without a previous clock in.'` | Warning set |
| 6 | **Verify**: `TptDriverAttendance::create([last_out_time=now(), via_app=1])` | Record created with only out time |
| 7 | **Verify**: `first_in_time` is null in created record | Only clock-out |
| 8 | **Verify**: Response includes `warning` text | Warning displayed via Swal |

### TC-P-13: Web manual attendance clock-in

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to QR page | QR page loaded |
| 2 | Click "Manual" tab | Manual mode displayed |
| 3 | Click "Clock-In" button | `openManual('IN')` called |
| 4 | **Verify**: Manual form box visible with driver dropdown + live clock | UI ready |
| 5 | Select a driver from dropdown | Driver selected |
| 6 | Click "Save" button | `saveManual()` called |
| 7 | **Verify**: `fetch()` POST to `/transport/driver-attendance/manual` with `{driver_id, type: 'IN'}` | AJAX request |
| 8 | **Verify**: `Gate::authorize('tenant.driver-attendance.create')` at line 341 passes | Authorized |
| 9 | **Verify**: `$request->validate([driver_id => required|exists:tpt_personnel,id, type => required|in:IN,OUT])` | Validation passes |
| 10 | **Verify**: `TptDriverAttendance::create([first_in_time=now(), via_app=1])` | Clock-in created |
| 11 | **⚠️ GAP**: `attendance_status` NOT set in manual clock-in | Status will be null/default |
| 12 | **Verify**: Response JSON `{status: true, type: 'IN', attendance: {..., driver: {name, role}}}` | Success response |
| 13 | **Verify**: `showWarning(res.warning)` called (null = no toast) | No warning |

### TC-N-01: Create duplicate attendance for same driver+date

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create attendance for driver_id=1, attendance_date=2026-07-22 | First entry created |
| 2 | Try to create another attendance for same driver+date | POST request |
| 3 | **Verify**: `DriverAttendanceRequest` rule `Rule::unique('tpt_driver_attendance', 'driver_id')->where('attendance_date', '2026-07-22')` triggers | "Attendance for this driver on the selected date already exists." |
| 4 | **Verify**: No duplicate row in DB | One record only |
| 5 | **Verify**: DB-level `uq_driver_day` unique constraint also prevents | Error if bypassing Request |

### TC-N-02: Create with invalid driver_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to create page | Form displayed |
| 2 | Select driver_id = 99999 (non-existent) | Not in dropdown (can't select) |
| 3 | **Note**: Dropdown only shows active drivers from DB — can only test via direct POST | Direct POST attack |
| 4 | Send POST directly to `/transport/driver-attendance` with `driver_id=99999` | Request bypasses UI |
| 5 | **Verify**: `DriverAttendanceRequest` rule `exists:tpt_personnel,id` | "The selected driver id is invalid." |
| 6 | **Verify**: No record created | DB unchanged |

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create attendance for driver_id=1, attendance_date=2026-07-22 | First entry created |
| 2 | Try to create another attendance for same driver+date | POST request |
| 3 | **Verify**: `DriverAttendanceRequest` rule `Rule::unique('tpt_driver_attendance', 'driver_id')->where('attendance_date', '2026-07-22')` triggers | "Attendance for this driver on the selected date already exists." |
| 4 | **Verify**: No duplicate row in DB | One record only |
| 5 | **Verify**: DB-level `uq_driver_day` unique constraint also prevents | Error if bypassing Request |

### TC-N-03: Create with empty first_in_time

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to create page | Form displayed |
| 2 | Fill driver, date, last_out_time (only), status | first_in_time left empty |
| 3 | Click "Save" | POST to store |
| 4 | **Verify**: `DriverAttendanceRequest` rule `required` on `first_in_time` | "The first in time field is required." |
| 5 | **Verify**: Form re-displayed with validation error | Error message visible |

### TC-N-04: Create with empty last_out_time

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to create page | Form displayed |
| 2 | Fill driver, date, first_in_time only, leave last_out_time empty | last_out_time omitted |
| 3 | Click "Save" | POST to store |
| 4 | **Verify**: `DriverAttendanceRequest` rule `required` on `last_out_time` | "The last out time field is required." |
| 5 | **Verify**: Form re-displayed with error | Validation error visible |

### TC-N-05: Create with non-boolean via_app

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send POST with `via_app='xyz'` (non-boolean string) | Malformed request |
| 2 | **Verify**: `DriverAttendanceRequest` rule `boolean` on `via_app` | "The via app field must be true or false." |
| 3 | **Verify**: `prepareForValidation()` `filter_var('xyz', FILTER_VALIDATE_BOOLEAN)` returns false | Normalized to false — passes validation as boolean false |
| 4 | **Note**: `FILTER_VALIDATE_BOOLEAN` accepts many values as false — validation may pass | Edge case: non-boolean strings become false silently |

### TC-N-06: Access index without viewAny permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user WITHOUT `tenant.driver-attendance.viewAny` permission | No viewAny |
| 2 | Navigate to Staff Management tab | Tab is hidden via `@can('tenant.driver-attendance.viewAny')` |
| 3 | Direct access: navigate to `/transport/drive-attendance` (index route) | 403 Access Denied |
| 4 | **Verify**: `Gate::authorize('tenant.driver-attendance.viewAny')` at line 21 throws 403 | Forbidden |

### TC-N-07: Access create without create permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login WITHOUT `tenant.driver-attendance.create` | No create |
| 2 | Navigate to `/transport/driver-attendance/create` | 403 Access Denied |
| 3 | **Verify**: `Gate::authorize('tenant.driver-attendance.create')` at line 52 throws 403 | Forbidden |

### TC-N-08: Access edit without update permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login WITHOUT `tenant.driver-attendance.update` | No update |
| 2 | Navigate to `/transport/driver-attendance/{id}/edit` | 403 Access Denied |
| 3 | **Verify**: `Gate::authorize('tenant.driver-attendance.update')` at line 111 throws 403 | Forbidden |

### TC-N-09: Attempt destroy without delete permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login WITHOUT `tenant.driver-attendance.delete` | No delete |
| 2 | Send DELETE to `/transport/driver-attendance/{id}` | 403 Access Denied |
| 3 | **Verify**: `Gate::authorize('tenant.driver-attendance.delete')` at line 161 throws 403 | Forbidden |

### TC-N-10: Access trash without restore permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login WITHOUT `tenant.driver-attendance.restore` | No restore |
| 2 | Navigate to `/transport/driver-attendance/trash/view` | 403 Access Denied |
| 3 | **Verify**: `Gate::authorize('tenant.driver-attendance.restore')` at line 177 throws 403 | Forbidden |

### TC-N-11: QR scan with invalid QR code

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open QR scan page | Scanner active |
| 2 | Point camera at a QR code that does NOT exist in `tpt_personnel.user_qr_code` | QR decoded |
| 3 | **Verify**: `scanQrAttendance()` `Validator::make(qr_code => 'exists:tpt_personnel,user_qr_code')` fails | Validation error |
| 4 | **Verify**: `response()->json([status: false, msg: '...'], 422)` returned | 422 JSON error |
| 5 | **Verify**: Frontend `catch()` shows "Server error" status | Error handled |

### TC-N-12: QR scan with invalid scan_type

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST `/transport/driver-attendance/mark-attendance` with `{qr_code: "valid", scan_type: "INVALID"}` | Invalid scan_type |
| 2 | **Verify**: `Validator::make(scan_type => 'required|in:IN,OUT')` fails | "The selected scan type is invalid." |
| 3 | **Verify**: 422 JSON response with error message | Validation error returned |

### TC-N-13: QR scan with missing qr_code

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST `/transport/driver-attendance/mark-attendance` with `{scan_type: "IN"}` (no qr_code) | Missing field |
| 2 | **Verify**: `Validator::make(qr_code => 'required|exists:...')` fails | "The qr code field is required." |
| 3 | **Verify**: 422 JSON response | Validation error |

### TC-N-14: Manual attendance with invalid driver_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST `/transport/driver-attendance/manual` with `{driver_id: 99999, type: "IN"}` | Non-existent driver |
| 2 | **Verify**: `$request->validate([driver_id => 'required|exists:tpt_personnel,id'])` fails | "The selected driver id is invalid." |
| 3 | **Verify**: 422 validation response | Error returned |

### TC-N-15: Manual attendance with invalid type

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST `/transport/driver-attendance/manual` with `{driver_id: 1, type: "INVALID"}` | Invalid type |
| 2 | **Verify**: `$request->validate([type => 'required|in:IN,OUT'])` fails | "The selected type is invalid." |
| 3 | **Verify**: 422 validation response | Error returned |

### TC-N-16: Restore non-trashed (active) record

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Identify an active attendance record (deleted_at IS NULL) | Active record |
| 2 | Call GET `/transport/driver-attendance/{id}/restore` | Route hit |
| 3 | **Verify**: `Gate::authorize('tenant.driver-attendance.restore')` passes | Authorized |
| 4 | **Verify**: `TptDriverAttendance::onlyTrashed()->findOrFail($id)` | `onlyTrashed()` scopes to deleted_at IS NOT NULL |
| 5 | Active record has deleted_at=NULL → not found | `ModelNotFoundException` |
| 6 | **Verify**: 404 error response | "No query results" |

### TC-N-17: Force delete non-trashed (active) record

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Identify an active record (deleted_at IS NULL) | Active record |
| 2 | Call DELETE `/transport/driver-attendance/{id}/force-delete` | Route hit |
| 3 | **Verify**: `Gate::authorize('tenant.driver-attendance.forceDelete')` passes | Authorized |
| 4 | **Verify**: `TptDriverAttendance::onlyTrashed()->findOrFail($id)` | `onlyTrashed()` → active record not found |
| 5 | Active record not in trashed scope → 404 | ModelNotFoundException |

### TC-N-18: Edit non-existent ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to `/transport/driver-attendance/99999/edit` | Non-existent ID |
| 2 | **Verify**: `TptDriverAttendance::findOrFail(99999)` | ModelNotFoundException |
| 3 | **Verify**: 404 error | "No query results" |

### TC-N-19: Show non-existent ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to `/transport/driver-attendance/99999` | Non-existent ID |
| 2 | **Verify**: `TptDriverAttendance::findOrFail(99999)` | 404 |

### TC-N-20: Store POST without create permission (FormRequest authorize fails)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login WITHOUT `tenant.driver-attendance.create` | No create |
| 2 | POST valid data to `/transport/driver-attendance` | Request submitted |
| 3 | **Verify**: `DriverAttendanceRequest::authorize()` returns false (POST → `Gate::allows('tenant.driver-attendance.create')` = false) | 403 Access Denied |
| 4 | **Verify**: No record created | DB unchanged |

### TC-N-21: Update PUT without update permission (FormRequest authorize fails)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login WITHOUT `tenant.driver-attendance.update` | No update |
| 2 | PUT valid data to `/transport/driver-attendance/{id}` | Request submitted |
| 3 | **Verify**: `DriverAttendanceRequest::authorize()` returns false (non-POST → `Gate::allows('tenant.driver-attendance.update')` = false) | 403 Access Denied |

### TC-N-22: Mobile API scan with missing fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Companion app sends POST with empty body | No data |
| 2 | **Verify**: `MobileAttendanceService::scanDriverAttendance()` validator fails | `qr_code` required + `scan_type` required |
| 3 | **Verify**: 422 `{status: 'error', message: '...'}` | Validation error |

### TC-N-23: Mobile API scan with non-existent driver QR

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST with `{qr_code: "NONEXISTENT", scan_type: "IN"}` | Invalid QR |
| 2 | **Verify**: Validator `exists:tpt_personnel,user_qr_code` fails | 422 error |
| 3 | **Verify**: `DriverHelper::where('user_qr_code', 'NONEXISTENT')` returns null | Driver not found |

### TC-N-24: Duplicate QR scan (debounce within 3s)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Scan a valid QR code once | First scan processed |
| 2 | Immediately scan the SAME QR code again (within 3 seconds) | Second scan blocked |
| 3 | **Verify**: `onScan()` checks `scanning` flag + `lastQr` + `lastScanAt` cooldown | `decodedText === lastQr && now - lastScanAt < COOLDOWN(3000)` → return early |
| 4 | **Verify**: No duplicate POST sent to server | Single attendance recorded |

### TC-N-25: Access QR page without viewAny permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login WITHOUT `tenant.driver-attendance.viewAny` | No viewAny |
| 2 | Navigate to `/transport/driver-attendance/qr` | 403 Access Denied |
| 3 | **Verify**: `Gate::authorize('tenant.driver-attendance.viewAny')` at line 218 throws 403 | Forbidden |

### TC-N-26: Force delete without forceDelete permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login WITHOUT `tenant.driver-attendance.forceDelete` | No forceDelete |
| 2 | DELETE `/transport/driver-attendance/{id}/force-delete` | 403 Access Denied |
| 3 | **Verify**: `Gate::authorize('tenant.driver-attendance.forceDelete')` at line 205 throws 403 | Forbidden |

### TC-N-27: Store with empty driver_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send POST with `driver_id` left empty | Missing driver_id |
| 2 | **Verify**: `DriverAttendanceRequest` rule `required` on `driver_id` | "The driver id field is required." |
| 3 | **Verify**: No record created | DB unchanged |

### TC-N-28: Store with empty attendance_date

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send POST with `attendance_date` empty | Missing date |
| 2 | **Verify**: `DriverAttendanceRequest` rule `required|date` on `attendance_date` | "The attendance date field is required." |
| 3 | **Verify**: No record created | DB unchanged |

### TC-D-01: Verify `uq_driver_day` unique constraint at DB level

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open DB `tpt_driver_attendance` table and check indexes | Index `uq_driver_day` exists on (driver_id, attendance_date) |
| 2 | Insert first record with driver_id=1, attendance_date=2026-07-22 | Success (UNIQUE constraint passes) |
| 3 | Attempt to insert second record with same driver_id=1, attendance_date=2026-07-22 via raw SQL | SQL error: "Duplicate entry '1-2026-07-22' for key 'uq_driver_day'" |
| 4 | **Verify**: `Rule::unique()` in FormRequest provides same protection at application layer | Double protection (app + DB) |

### TC-D-02: Verify soft-delete preserves data

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Note all fields of a record before deletion | driver_id=1, date=2026-07-22, first_in=08:00, last_out=17:00, etc. |
| 2 | Call destroy() on the record | Soft-delete |
| 3 | Query DB directly: `SELECT * FROM tpt_driver_attendance WHERE id = X` | All columns preserved, `deleted_at` IS NOT NULL |
| 4 | Query via `onlyTrashed()` scope | Record returned |
| 5 | Query via standard `TptDriverAttendance::find()` | Null (excluded by SoftDeletes global scope) |

### TC-D-03: Verify restore does NOT reactivate (no is_active column)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete a record | `deleted_at` set |
| 2 | Call restore() on trashed record | `deleted_at = NULL` |
| 3 | **Verify**: No `is_active` column exists in table | Migration does NOT define is_active — only deleted_at |
| 4 | **Verify**: Record is now visible in standard queries | Active listing shows record |

### TC-D-04: Verify force delete permanently removes record

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete attendance record first | Record trashed |
| 2 | Call forceDelete() on trashed record | `forceDelete()` called |
| 3 | DB check: `SELECT * FROM tpt_driver_attendance WHERE id = X` | 0 rows — permanently deleted |
| 4 | DB check: `tpt_driver_attendance_log WHERE attendance_id = X` | 0 rows — cascade deleted |

### TC-D-05: Verify scan log cascade on attendance delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure attendance record has scan log entries in `tpt_driver_attendance_log` | Log records exist |
| 2 | Force delete the attendance record | Permanently removed |
| 3 | DB check: `SELECT * FROM tpt_driver_attendance_log WHERE attendance_id = X` | 0 rows — cascade FK constraint deletes logs |
| 4 | **Verify**: FK constraint `fk_da_attendance` ON DELETE CASCADE works | DDL: line 27 |

### TC-D-06: Verify driver FK constraint on attendance

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Identify a driver with attendance records | Driver with multiple attendance |
| 2 | Delete the driver from `tpt_personnel` | FK CASCADE per DDL `fk_da_driver` |
| 3 | DB check: `SELECT * FROM tpt_driver_attendance WHERE driver_id = X` | 0 rows — all cascade deleted |
| 4 | **Verify**: FK constraint `fk_da_driver` ON DELETE CASCADE | Migration line 25 |

### TC-D-07: Verify `via_app` cast as boolean

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create attendance with `via_app = 1` (integer) | Record created |
| 2 | Query model: `$record = TptDriverAttendance::find(X); var_dump($record->via_app)` | `bool(true)` — cast to boolean |
| 3 | Create attendance with `via_app = 0` | Record created |
| 4 | Query: `$record->via_app` | `bool(false)` |

### TC-D-08: Verify `attendance_date` cast as date

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Query attendance record | `$record->attendance_date` |
| 2 | Check type: `get_class($record->attendance_date)` | `Carbon\Carbon` instance |
| 3 | Check format: `$record->attendance_date->toDateString()` | "2026-07-22" (date only, no time) |
| 4 | **Verify**: Cast `'attendance_date' => 'date'` in model | Carbon with date precision |

### TC-D-09: Verify first_in_time/last_out_time cast as datetime

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Query record with first_in_time set | `$record->first_in_time` |
| 2 | Check type: `get_class($record->first_in_time)` | `Carbon\Carbon` instance |
| 3 | Check includes time: `$record->first_in_time->format('Y-m-d H:i:s')` | e.g., "2026-07-22 08:00:00" |
| 4 | **Verify**: Cast `'first_in_time' => 'datetime'`, `'last_out_time' => 'datetime'` | Full DateTime Carbon |

### TC-D-10: Verify attendance_status DDL vs form mismatch

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review DDL: `attendance_status` column defined as `unsignedInteger` with FK → `sys_dropdown_table.id` | INT FK expected |
| 2 | Review controller: `store()` sets `'attendance_status' => $request->attendance_status ?: 'IN_PROGRESS'` | String value 'IN_PROGRESS' |
| 3 | Review blade: dropdown options = `['Present', 'Absent', 'Half-Day', 'Late']` | String values in UI |
| 4 | **Impact**: Form submission with string 'Present' would fail FK constraint | DB reject due to type mismatch |
| 5 | **Root Cause**: Migration DDL defines INT FK but controller/form code uses string enums | Inconsistent design |

### TC-D-11: Verify trash blade field `check_in_time` doesn't exist

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to trash page (`/transport/driver-attendance/trash/view`) | Trash listing |
| 2 | Locate a trashed attendance record | Record visible |
| 3 | **Verify**: Check-in column displays `$item->check_in_time` | `check_in_time` is NOT a column on `tpt_driver_attendance` |
| 4 | **Expected**: Blank/null shown instead of formatted time | Blade references non-existent field |
| 5 | **Source**: `trash.blade.php:53` — `$item->check_in_time` should be `$item->first_in_time` | Bug in trash template |
| 6 | Same bug for `check_out_time` at line 58 | Should be `last_out_time` |

### TC-CR-01: Verify Gate::authorize() in index()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `DriverAttendanceController.php:21` | `Gate::authorize('tenant.driver-attendance.viewAny')` |
| 2 | Verify permission string matches `permissionslist.php:316` | `driver-attendance` group has `viewAny` |
| 3 | Verify policy method exists | `DriverAttendancePolicy.php:12-15` — `viewAny()` |
| 4 | **Result**: index() properly gated | Access controlled |

### TC-CR-02: Verify Gate::authorize() in create()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `DriverAttendanceController.php:52` | `Gate::authorize('tenant.driver-attendance.create')` |
| 2 | Verify policy method exists | `DriverAttendancePolicy.php:22-25` — `create()` |
| 3 | **Result**: create() properly gated | Access controlled |

### TC-CR-03: Verify Gate::authorize() in store()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `DriverAttendanceController.php:64` | `Gate::authorize('tenant.driver-attendance.create')` |
| 2 | **Result**: store() properly gated | Access controlled |

### TC-CR-04: Verify Gate::authorize() in show()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `DriverAttendanceController.php:99` | `Gate::authorize('tenant.driver-attendance.view')` |
| 2 | **Result**: show() properly gated | Access controlled |

### TC-CR-05: Verify Gate::authorize() in edit()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `DriverAttendanceController.php:111` | `Gate::authorize('tenant.driver-attendance.update')` |
| 2 | **Result**: edit() properly gated | Access controlled |

### TC-CR-06: Verify Gate::authorize() in update()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `DriverAttendanceController.php:124` | `Gate::authorize('tenant.driver-attendance.update')` |
| 2 | **Result**: update() properly gated | Access controlled |

### TC-CR-07: Verify Gate::authorize() in destroy()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `DriverAttendanceController.php:161` | `Gate::authorize('tenant.driver-attendance.delete')` |
| 2 | **Result**: destroy() properly gated | Access controlled |

### TC-CR-08: Verify Gate::authorize() in trashed()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `DriverAttendanceController.php:177` | `Gate::authorize('tenant.driver-attendance.restore')` |
| 2 | **Result**: trashed() properly gated (uses restore permission) | Access controlled |

### TC-CR-09: Verify Gate::authorize() in restore()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `DriverAttendanceController.php:189` | `Gate::authorize('tenant.driver-attendance.restore')` |
| 2 | **Result**: restore() properly gated | Access controlled |

### TC-CR-10: Verify Gate::authorize() in forceDelete()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `DriverAttendanceController.php:205` | `Gate::authorize('tenant.driver-attendance.forceDelete')` |
| 2 | **Result**: forceDelete() properly gated | Access controlled |

### TC-CR-11: Verify Gate::authorize() in scanQrAttendance()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `DriverAttendanceController.php:240` | `Gate::authorize('tenant.driver-attendance.create')` |
| 2 | **Result**: scanQrAttendance() uses create permission | Access controlled |

### TC-CR-12: Verify Gate::authorize() in manualAttendance()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `DriverAttendanceController.php:341` | `Gate::authorize('tenant.driver-attendance.create')` |
| 2 | **Result**: manualAttendance() uses create permission | Access controlled |

### TC-CR-13: Verify Gate::authorize() in showQr() and scan()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `DriverAttendanceController.php:218` | `Gate::authorize('tenant.driver-attendance.viewAny')` |
| 2 | Open `DriverAttendanceController.php:230` | `Gate::authorize('tenant.driver-attendance.viewAny')` |
| 3 | **Result**: Both QR pages use viewAny (same as index) | Consistent |

### TC-CR-14: Verify activityLog() in destroy()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `DriverAttendanceController.php:166` | `activityLog($attendance, 'Deleted', ['message' => 'Driver attendance moved to trash'])` |
| 2 | **Verify**: Log type='Deleted', message matches | Activity log entry created |

### TC-CR-15: Verify activityLog() in restore()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `DriverAttendanceController.php:194` | `activityLog($attendance, 'Restored', ['message' => 'Driver attendance restored'])` |
| 2 | **Verify**: Log type='Restored' | Activity log entry created |

### TC-CR-16: Verify activityLog() in forceDelete()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `DriverAttendanceController.php:210` | `activityLog($attendance, 'ForceDelete', ['message' => 'Driver attendance permanently deleted'])` |
| 2 | **Verify**: Log type='ForceDelete' | Activity log entry created |

### TC-CR-17: ⚠️ GAP: Verify activityLog() MISSING in store()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Search `DriverAttendanceController.php:62-91` (store method) | NO call to `activityLog()` |
| 2 | **Verify**: All other CRUD methods have activityLog — store does NOT | Inconsistent — missing audit trail for create |

### TC-CR-18: ⚠️ GAP: Verify activityLog() MISSING in update()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Search `DriverAttendanceController.php:122-154` (update method) | NO call to `activityLog()` |
| 2 | **Verify**: update() has no audit trail | Missing change tracking + activity log |

### TC-CR-19: Verify DriverAttendanceRequest@authorize() for POST

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `DriverAttendanceRequest.php:16-17` | `if ($this->isMethod('POST')) { return Gate::allows('tenant.driver-attendance.create'); }` |
| 2 | **Verify**: POST requires create permission | Correct |

### TC-CR-20: Verify DriverAttendanceRequest@authorize() for PUT/PATCH

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `DriverAttendanceRequest.php:18-19` | `return Gate::allows('tenant.driver-attendance.update');` |
| 2 | **Verify**: Non-POST requires update permission | Correct |

### TC-CR-21: Verify `prepareForValidation()` normalizes via_app

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `DriverAttendanceRequest.php:66-71` | `$this->merge(['via_app' => filter_var($this->via_app, FILTER_VALIDATE_BOOLEAN)])` |
| 2 | **Verify**: Input "1" → true, "0" → false, "true" → true, "false" → false | Boolean normalization |

### TC-CR-22: Verify unique rule on driver_id ignores current record

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `DriverAttendanceRequest.php:28-35` | `Rule::unique('tpt_driver_attendance', 'driver_id')->where('attendance_date', ...)->ignore($this->route('driver_attendance') ?? $this->route('driver-attendance') ?? $this->id)->whereNull('deleted_at')` |
| 2 | **Verify**: 3 fallback route parameter names tried | Handles `driver_attendance`, `driver-attendance`, and `id` |
| 3 | **Verify**: `whereNull('deleted_at')` — ignores soft-deleted records | Soft-deleted duplicates allowed |

### TC-CR-23: Verify unique rule on attendance_date uses where clause

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `DriverAttendanceRequest.php:37-45` | `Rule::unique('tpt_driver_attendance', 'attendance_date')->ignore(...)->where(function($q) { $q->where('driver_id', $this->driver_id)->whereNull('deleted_at') })` |
| 2 | **Verify**: Date unique is scoped by driver_id | Composite unique enforced |

### TC-CR-25: Verify show() eager-loads driver

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `DriverAttendanceController.php:101` | `TptDriverAttendance::with(['driver'])->findOrFail($id)` |
| 2 | **Verify**: Driver relationship eager-loaded | N+1 query prevented |

### TC-CR-26: Verify index() eager-loads driver

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `DriverAttendanceController.php:23` | `TptDriverAttendance::with(['driver'])` |
| 2 | **Verify**: Driver relationship eager-loaded in list | N+1 prevented for 20 records per page |

### TC-CR-27: Verify forceDelete() uses onlyTrashed() NOT withTrashed()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `DriverAttendanceController.php:207` | `TptDriverAttendance::onlyTrashed()->findOrFail($id)` |
| 2 | **Verify**: Can ONLY force-delete already soft-deleted records | Cannot force-delete active record directly |

### TC-CR-28: ⚠️ GAP: Verify toggleStatus route has no controller method

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `web.php:186` | `Route::post('/driver-attendance/{driver-attendance}/toggle-status', [DriverAttendanceController::class, 'toggleStatus'])->name('driver-attendance.toggleStatus')` |
| 2 | Review `DriverAttendanceController.php` methods | **No `toggleStatus()` method exists** |
| 3 | POST to `/transport/driver-attendance/1/toggle-status` with `{is_active: 0}` | 500 error: "Call to undefined method toggleStatus()" |
| 4 | **Impact**: Status switch component cannot function | Dead route — unreachable functionality |

### TC-CR-29: ⚠️ GAP: Verify index blade uses `tenant.driver-attendance.edit` (wrong permission)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `driver-attendance/index.blade.php:50` | `@canany(['tenant.driver-attendance.edit','tenant.driver-attendance.delete'])` |
| 2 | Check `permissionslist.php:316` | Permission group `driver-attendance` → CRUD includes `update` NOT `edit` |
| 3 | Check `DriverAttendancePolicy.php:27-30` | Policy method is `update()` for `tenant.driver-attendance.update` |
| 4 | **Conclusion**: `tenant.driver-attendance.edit` is NOT a valid permission | Users with 'update' permission won't see the action column |
| 5 | **Fix**: Replace `edit` with `update` in both `@canany` calls (lines 50 and 100) | Permission string must match policy |

### TC-CR-30: ⚠️ GAP: Verify trash.blade.php uses non-existent `check_in_time`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `trash.blade.php:53` | `$item->check_in_time ? \Carbon\Carbon::parse($item->check_in_time)->format('h:i A') : '-'` |
| 2 | Check model `$fillable` in `TptDriverAttendance.php:18-26` | No `check_in_time` — field is `first_in_time` |
| 3 | Check migration columns | No `check_in_time` column |
| 4 | **Conclusion**: `check_in_time` does NOT exist — always null | Check-in column always shows '-' |
| 5 | Same bug at line 38 and 58 for `check_out_time` (should be `last_out_time`) | Both fields broken |

### TC-CR-31: ⚠️ GAP: Verify trash.blade.php uses non-existent `geo_lat`/`geo_lng`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `trash.blade.php:64` | `$item->geo_lat && $item->geo_lng ? "Lat: {$item->geo_lat}, Lng: {$item->geo_lng}" : 'Depot'` |
| 2 | Check migration columns | NO `geo_lat` or `geo_lng` columns in `tpt_driver_attendance` |
| 3 | **Conclusion**: Always shows 'Depot' because geo fields never set | Location column always defaults |

### TC-CR-32: ⚠️ GAP: Verify trash.blade.php uses `created_at` instead of `attendance_date`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `trash.blade.php:45` | `\Carbon\Carbon::parse($item->created_at)->format('d M Y')` |
| 2 | **Verify**: Shows record creation date, not the actual attendance date | Should be `$item->attendance_date` |
| 3 | **Impact**: Incorrect date displayed in trash listing | Misleading data |

### TC-CR-33: ⚠️ GAP: Verify `staffmgmt.blade.php` missing `:active` attribute

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `staffmgmt.blade.php:14-16` | `<x-backend.tab.nav-tab :tabs="[...]" >` — NO `:active="request('tab', 'driver_attendance')"` |
| 2 | **Verify**: Default active tab is not explicitly set | Tab component may default to first tab or no tab |

### TC-CR-34: ⚠️ GAP: Verify no `withQueryString()` on index paginator

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `DriverAttendanceController.php:40-41` | `$query->orderBy('id', 'DESC')->paginate(20)` |
| 2 | **Verify**: No `->withQueryString()` chained | Search/filter params lost on page 2 |

### TC-CR-35: ⚠️ GAP: Verify no `->appends(['tab'=>'driver_attendance'])` on pagination

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `driver-attendance/index.blade.php:124` | `{{ $driverAttendance->links() }}` |
| 2 | **Verify**: No tab param appended | Page navigation loses active tab context |

### TC-CR-36: Verify store() manually maps fields instead of validated()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `DriverAttendanceController.php:79-87` | `TptDriverAttendance::create([...driver_id=>$request->driver_id, attendance_date=>$date...])` |
| 2 | **Verify**: Uses `$request->driver_id`, `$request->first_in_time` etc. — NOT `$request->validated()` | Deviates from standard Laravel pattern |
| 3 | **Note**: `$request->validated()` would return only the validated subset — manual mapping risks unvalidated field inclusion | Risk: `attendance_status` not validated but included in create() |

### TC-CR-37: Verify update() manually maps fields instead of validated()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `DriverAttendanceController.php:141-148` | `$attendance->update([...driver_id=>$request->driver_id, attendance_date=>$date...])` |
| 2 | **Verify**: Same pattern as store() — manual field mapping | Inconsistent with standard CRUD pattern |

### TC-CR-38: ⚠️ GAP: Verify `attendance_status` has no validation rule

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `DriverAttendanceRequest.php:27-60` | Rules array has: driver_id, attendance_date, first_in_time, last_out_time, via_app |
| 2 | Search for `attendance_status` in rules array | **NOT FOUND** — no validation rule |
| 3 | Open `DriverAttendanceController.php:85` | `'attendance_status' => $request->attendance_status ? $request->attendance_status : 'IN_PROGRESS'` |
| 4 | **Conclusion**: `attendance_status` is mass-assigned without any validation | Data integrity risk |

### TC-CR-39: ⚠️ GAP: Verify `last_out_time.after` message is dead code

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `DriverAttendanceRequest.php:82-83` | `'last_out_time.after' => 'Last out time must be after first in time.'` |
| 2 | Search rules array for `after:first_in_time` on `last_out_time` | **NOT FOUND** — no such rule |
| 3 | **Conclusion**: Custom message defined but validation rule does NOT exist | Dead code — message never displayed |

### TC-CR-40: Verify store() flash message hardcoded

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `DriverAttendanceController.php:89-91` | `->with('success', 'Driver attendance saved successfully')` |
| 2 | **Verify**: Hardcoded string — NOT using `flash('created.driver_attendance')` | Inconsistent with destroy/restore/forceDelete |

### TC-CR-41: Verify update() flash message hardcoded

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `DriverAttendanceController.php:151-153` | `->with('success', 'Driver attendance updated successfully')` |
| 2 | **Verify**: Hardcoded string | Inconsistent pattern |

### TC-CR-42: Verify model `$casts` definition

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `TptDriverAttendance.php:31-37` | `['attendance_date' => 'date', 'first_in_time' => 'datetime', 'last_out_time' => 'datetime', 'total_work_minutes' => 'integer', 'via_app' => 'boolean']` |
| 2 | **Verify**: All relevant fields cast | Datetime fields → Carbon, integer field, boolean field |

### TC-CR-43: Verify `DriverAttendancePolicy` has 7 methods

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `DriverAttendancePolicy.php:12-45` | Methods: viewAny, view, create, update, delete, restore, forceDelete |
| 2 | All 7 match `permissionslist.php` CRUD actions | viewAny, view, create, update, delete, restore, forceDelete |
| 3 | **Verify**: No extra methods (no status/import/export/print) | Clean policy — all methods used |

### TC-CR-44: ⚠️ GAP: Verify no update() change tracking

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Search `DriverAttendanceController.php:122-154` for `getOriginal()` or `getChanges()` | NOT FOUND |
| 2 | Compare with standard CRUD pattern (VehicleController uses change tracking) | Missing change tracking = no audit of what changed |

### TC-CR-45: Verify scanQrAttendance() inline validation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `DriverAttendanceController.php:241-244` | `Validator::make($request->all(), ['qr_code' => 'required|exists:tpt_personnel,user_qr_code', 'scan_type' => 'required|in:IN,OUT'])` |
| 2 | **Verify**: 2 rules — qr_code must exist in DB, scan_type must be IN or OUT | Proper validation |

### TC-CR-46: Verify manualAttendance() inline validation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `DriverAttendanceController.php:342-344` | `$request->validate(['driver_id' => 'required|exists:tpt_personnel,id', 'type' => 'required|in:IN,OUT'])` |
| 2 | **Verify**: 2 rules — driver_id must exist, type IN/OUT | Proper validation |

### TC-CR-47: ⚠️ GAP: Verify `create.blade.php` attendance_status select value bug

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `create.blade.php:109` | `{{ old('attendance_status') }}>` |
| 2 | Open `edit.blade.php:117` | `{{ old('attendance_status', $record->attendance_status) == $status ? 'selected' : '' }}` |
| 3 | **Compare**: edit.blade.php correctly compares with `== $status`, create.blade.php only outputs old() value | create.blade.php: no option will be marked 'selected' — all options look the same |

### TC-CR-48: Verify `staffmgmt.blade.php` has `@can` guard for include

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `staffmgmt.blade.php:17-18` | `@can('tenant.driver-attendance.viewAny')` / `@include('transport::driver-attendance.index')` / `@endcan` |
| 2 | **Verify**: Double-layer security — tab nav-tab has permission key + @can wraps include content | Both hide tab content if permission missing |

### TC-CR-49: Verify restore() does NOT set is_active=true

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `DriverAttendanceController.php:191-192` | `$attendance = ...onlyTrashed()->findOrFail($id); $attendance->restore();` |
| 2 | **Verify**: No `$attendance->is_active = true` or `$attendance->save()` after restore | Record restored but no active flag set (no is_active column exists) |

### TC-CR-50: Verify destroy() does NOT set is_active=false before delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `DriverAttendanceController.php:163-164` | `$attendance = ...findOrFail($id); $attendance->delete();` |
| 2 | **Verify**: Direct delete() — no deactivation step before soft-delete | Different from Vehicle pattern which sets is_active=false first |

### TC-CR-51: Verify `permissionslist.php` has driver-attendance group

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `config/permissionslist.php:315-317` | `// begin::Transport Staff Management here`, `'driver-attendance' => $crud,` |
| 2 | **Verify**: Under "Transport Staff Management" section | Correct group placement |

### TC-CR-52: Verify breadcrumb config has two entries

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `config/breadcrumb.php:681-682` | `'staff-mgmt' => 'driver_attendance'`, `'drive-attendance' => 'driver_attendance'` |
| 2 | **Verify**: Two route aliases point to same breadcrumb | cover both URL variants |

### TC-CR-53: Verify MobileAttendanceService scanDriverAttendance() firstOrNew pattern

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `MobileAttendanceService.php:36-38` | `$attendance = TptDriverAttendance::firstOrNew(['driver_id' => $driver->id, 'attendance_date' => $today])` |
| 2 | **Verify**: Uses firstOrNew — creates if not exists, loads if exists | Differs from web controller which always creates new record |

### TC-CR-54: Verify MobileAttendanceService wraps in try-catch

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `MobileAttendanceService.php:120-123` | `catch (\Exception $e) { report($e); return response()->json(['status' => 'error', 'message' => $e->getMessage()], 500) }` |
| 2 | **Verify**: Exception logged via `report()` and 500 JSON returned | Graceful error handling |

### TC-CR-55: Verify scan() view file exists

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | **Verify**: `DriverAttendanceController.php:231` | `return view('transport::driver-attendance.scan')` |
| 2 | Check file system: `Modules/Transport/resources/views/driver-attendance/scan.blade.php` | **FILE NOT FOUND** — only qr.blade.php exists |
| 3 | **Conclusion**: `scan()` method references non-existent view | Calling this route causes ViewNotFoundException |

### TC-CR-56: Verify `@can` closing tag match in index.blade.php

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `driver-attendance/index.blade.php:50-52` | `@canany(['...edit','...delete'])` → `@endcanany` |
| 2 | Open `driver-attendance/index.blade.php:100-104` | `@canany(['...edit','...delete'])` → `@endcanany` |
| 3 | **Verify**: Both use `@endcanany` (not `@endcan`) | Correct closing directives |

### TC-CR-57: Verify trash.blade.php `@canany` with correct closing

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `trash.blade.php:24-26` | `@canany(['tenant.driver-attendance.forceDelete','tenant.driver-attendance.restore'])` → `@endcanany` |
| 2 | Open `trash.blade.php:67-72` | Same pattern → `@endcanany` |
| 3 | **Verify**: Correct permissions ('restore' and 'forceDelete') and correct closing | Proper implementation |

### TC-CR-58: Verify `@can('viewAny')` on staffmgmt.blade.php

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `staffmgmt.blade.php:15` | `'permission' => 'tenant.driver-attendance.viewAny'` |
| 2 | Open `staffmgmt.blade.php:17-18` | `@can('tenant.driver-attendance.viewAny')` around @include |
| 3 | **Verify**: Permission key matches between nav-tab and @can | Consistent permission string |

### TC-CR-59: Verify `driver()` relationship definition

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `TptDriverAttendance.php:54-57` | `public function driver() { return $this->belongsTo(DriverHelper::class, 'driver_id'); }` |
| 2 | **Verify**: Foreign key `driver_id` references `DriverHelper` (`tpt_personnel`) | Correct FK mapping |

### TC-CR-60: Verify model `$fillable` contains all 7 columns

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `TptDriverAttendance.php:18-26` | `['driver_id', 'attendance_date', 'first_in_time', 'last_out_time', 'total_work_minutes', 'attendance_status', 'via_app']` |
| 2 | **Verify**: All 7 data columns mass-assignable | No guarded columns unintentionally exposed |

### TC-CR-61: ⚠️ GAP: Verify web manual clock-in does NOT set attendance_status

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `DriverAttendanceController.php:364-369` (manual IN) | Creates with first_in_time=now(), via_app=1 — NO attendance_status |
| 2 | Compare with `scanQrAttendance` clock-IN: line 273 sets `'attendance_status' => 'Present'` | Manual clock-in does NOT set status |
| 3 | **Conclusion**: Web manual clock-in leaves attendance_status as null/default | Inconsistent with QR scan behavior |

### TC-CR-62: Verify MobileAttendanceService manualDriverAttendance returns driver details

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `MobileAttendanceService.php:175-178` | `'driver' => ['name' => $driver?->name, 'role' => $driver?->role]` |
| 2 | **Verify**: Null-safe operator `$driver?->name` used | Handles null driver gracefully |

### TC-CR-63: Verify total_work_minutes computed only when last_out_time exists

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `DriverAttendanceController.php:75-77` | `$totalMinutes = $lastOut ? $firstIn->diffInMinutes($lastOut) : null` |
| 2 | **Verify**: Null if no clock-out | Prevents diffInMinutes on null |

### TC-CR-64: Verify `store()` redirect route

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `DriverAttendanceController.php:89-91` | `redirect()->route('transport.driver-attendance.index')` |
| 2 | **Verify**: Redirects to driver-attendance.index (which returns tab hub view) | Stays in Staff Management context |

### TC-CR-65: Verify `showQr()` passes drivers list to view

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `DriverAttendanceController.php:219-220` | `return view('transport::driver-attendance.qr', ['drivers' => DriverHelper::active()->get()])` |
| 2 | **Verify**: Drivers list available for manual attendance dropdown | Manual tab driver select populated |

---

## Summary of Gaps Found

| # | Gap | Severity | Source |
|---|-----|----------|--------|
| G-01 | `toggleStatus()` route defined but controller method does NOT exist | HIGH | `web.php:186` |
| G-02 | `attendance_status` DDL type mismatch: INT FK vs string values | HIGH | Migration vs Controller |
| G-03 | `store()` and `update()` missing `activityLog()` calls | MEDIUM | Controller |
| G-04 | `update()` missing change tracking (no getOriginal/getChanges) | MEDIUM | Controller |
| G-05 | Index blade uses `tenant.driver-attendance.edit` (invalid) instead of `tenant.driver-attendance.update` | MEDIUM | `index.blade.php:50,100` |
| G-06 | Trash blade uses non-existent `check_in_time`/`check_out_time` fields | HIGH | `trash.blade.php:38,53,58` |
| G-07 | Trash blade uses non-existent `geo_lat`/`geo_lng` fields | MEDIUM | `trash.blade.php:64` |
| G-08 | Trash blade uses `created_at` instead of `attendance_date` | MEDIUM | `trash.blade.php:45` |
| G-09 | `staffmgmt.blade.php` missing `:active` attribute on nav-tab | MEDIUM | `staffmgmt.blade.php:14` |
| G-10 | No `withQueryString()` on index paginator — filter params lost | LOW | Controller line 41 |
| G-11 | No `->appends(['tab'=>'driver_attendance'])` on pagination — tab context lost | LOW | `index.blade.php:124` |
| G-12 | `last_out_time` FormRequest rule is `required` — prevents clock-in-only creation | MEDIUM | `DriverAttendanceRequest.php:52-54` |
| G-13 | `last_out_time.after` custom message defined but no `after` validation rule | LOW | `DriverAttendanceRequest.php:82-83` |
| G-14 | `attendance_status` has NO validation rule in FormRequest | MEDIUM | `DriverAttendanceRequest.php:27-60` |
| G-15 | `scan()` references non-existent `transport::driver-attendance.scan` view | HIGH | `DriverAttendanceController.php:231` |
| G-16 | `create.blade.php` attendance_status `<option>` missing selected comparison | LOW | `create.blade.php:109` |
| G-17 | Flash messages hardcoded instead of using `flash()` helper | LOW | Controller lines 90-91, 152-153 |
| G-18 | `destroy()` redirects to Transport Master instead of Staff Management | LOW | Controller line 168 |
| G-19 | Web manual clock-in does NOT set `attendance_status` | MEDIUM | Controller lines 364-369 |
