# Shift Master — TC_List

---

## 1. Feature Information

| Attribute | Details |
|-----------|---------|
| **Module** | Transport (TPT) |
| **Entity** | Shift Master (`tpt_shift`) |
| **Controller** | `Modules\Transport\Http\Controllers\ShiftController` — 11 methods — ⚠️ `index()` NOT called for tab listing; standalone route only |
| **Tab Container Controller** | `Modules\Transport\Http\Controllers\TransportMasterController@index()` — tab id `shift`, private `shiftsQuery()` for listing |
| **Model** | `Modules\Transport\Models\Shift` — SoftDeletes, `HasFactory`, `BaseModel`, 1 relationship (`routes`) |
| **Form Request** | `Modules\Transport\Http\Requests\ShiftRequest` — 6 validation rules + `prepareForValidation` |
| **Policy** | `Modules\Transport\Policies\ShiftPolicy` — 10 permission methods |
| **Route Prefix** | `transport.shift.*` (resource) + `trashed`, `restore`, `forceDelete`, `toggleStatus` |
| **Blade Views** | `shift/index.blade.php` (tab), `shift/create.blade.php`, `shift/edit.blade.php`, `shift/show.blade.php`, `shift/trash.blade.php` |
| **Tab Container** | `tab_module/transportmaster.blade.php` — tab id `shift`, permission `tenant.shift.viewAny` |
| **DB Table** | `tpt_shift` — 7 data columns + 3 timestamp columns |
| **Primary Screen** | Transport Master → Shift tab (paginated, searchable, status-filtered) |

---

## 2. Pre-conditions

| # | Pre-condition |
|---|--------------|
| PC-01 | User must be logged in as Transport Manager (or role with `tenant.shift.*` permissions) |
| PC-02 | Database `tpt_shift` table must exist with columns: `id`, `code`, `name`, `effective_from`, `effective_to`, `is_active`, `created_at`, `updated_at`, `deleted_at` |
| PC-03 | Unique constraints `uq_shift_code` and `uq_shift_name` must be enabled on `code` and `name` columns |
| PC-04 | At least one shift record exists in `tpt_shift` for list/show/update/delete tests |
| PC-05 | `ShiftController` must be registered in web routes with full resource + extra routes (lines 113-117 of `routes/web.php`) |
| PC-06 | `ShiftPolicy` must be registered in `AuthServiceProvider` |
| PC-07 | Shift tab must be included in `transportmaster.blade.php` with `@can('tenant.shift.viewAny')` guard (line 35-37) |
| PC-08 | Soft deletes must be enabled on `tpt_shift` via `$table->softDeletes()` in migration |
| PC-09 | Browser must support JavaScript for status toggle and AJAX operations |
| PC-10 | `activityLog()` helper must be available and configured |
| PC-11 | `flash()` helper must have translation keys: `created.shift`, `updated.shift`, `trashed.shift`, `restored.shift`, `force_deleted.shift`, `status_updated.shift`, `status_switch_failed.shift` |
| PC-12 | `ShiftRequest` must be type-hinted in `store()` and `update()` controller methods (lines 39, 81) |

---

## 3. Default Data Load

| # | Data Load Rule | Source |
|---|----------------|--------|
| DL-01 | Load shifts with pagination (10 per page) via `TransportMasterController::index() → shiftsQuery() [Tab-based]()` | `TransportMasterController.php:218-226` — `Shift::query()->when(tab check)->latest()->paginate(10, ['*'], 'shifts_page')` |
| DL-02 | Tab data loaded via `TransportMasterController@index()` with `@include('transport::shift.index')` | `transportmaster.blade.php:36` |
| DL-03 | List columns displayed: **Code**, **Name**, **Effective From**, **Effective To**, **Status**, **Action** | `shift/index.blade.php:41-48` |
| DL-04 | Date format: `d-m-Y` (DD-MM-YYYY) using `\Carbon\Carbon::parse()->format('d-m-Y')` | `shift/index.blade.php:58,64` |
| DL-05 | Status column uses `<x-backend.table.status-switch>` component with toggle functionality | `shift/index.blade.php:68` |
| DL-06 | Action column uses `<x-backend.table.action>` component — visible only for `@canany(['tenant.shift.edit', 'tenant.shift.delete'])` | `shift/index.blade.php:46,70` |
| DL-07 | Pagination links appended with `?tab=shift` query parameter via `$shifts->appends(['tab' => request('tab', 'shift')])->links()` | `shift/index.blade.php:88` |
| DL-08 | Search filters: `?search=` (Code, Name) and `?status=` (1=Active, 0=Inactive) | `shift/index.blade.php:9-17` |
| DL-09 | **⚠️ GAP**: Controller `index()` has no `$request` parameter — does NOT process search/status. Filters exist in Blade only. | `ShiftController.php:17-24`, `shift/index.blade.php:9-17` |
| DL-10 | Empty state: "No Data Found" displayed for colspan 6 | `shift/index.blade.php:77-79` |
| DL-11 | Trashed view loads via `ShiftController@trashed()` with `onlyTrashed()->paginate(10)` — columns: Code, Name, Effective From, Effective To, Action | `shift/trash.blade.php`, `ShiftController.php:140-146` |
| DL-12 | Create form renders standalone with `x-backend.layouts.app` layout | `shift/create.blade.php:1` |
| DL-13 | Edit form renders standalone with `x-backend.layouts.app` layout, uses `@method('PUT')` | `shift/edit.blade.php:1,28` |
| DL-14 | Show view renders standalone with `x-backend.layouts.app` layout | `shift/show.blade.php:1` |
| DL-15 | Search form includes hidden `<input type="hidden" name="tab" value="shift">` to preserve tab state | `shift/index.blade.php:9` |
| DL-16 | Reset button links to `transport.transport-master.index` with `tab=shift` | `shift/index.blade.php:23-25` |

---

## 4. Test Data Strategy

| # | Data Strategy | Details |
|---|---------------|---------|
| TD-01 | **Valid Shift Record** | `code='MORN'`, `name='Morning Shift'`, `effective_from='2026-04-01'`, `effective_to='2027-03-31'`, `is_active=1` |
| TD-02 | **Duplicate Code** | Create a second shift with `code='MORN'` but `name='Afternoon Shift'` — expects unique violation |
| TD-03 | **Duplicate Name** | Create a second shift with `name='Morning Shift'` but `code='AFTN'` — expects unique violation |
| TD-04 | **Invalid Date Range** | `effective_from='2026-06-01'`, `effective_to='2026-05-01'` (before start) — expects `after` validation failure |
| TD-05 | **Soft-Deleted Shift Code Reuse** | Delete shift with `code='MORN'`, then create new shift with same code — should succeed because unique ignores soft-deleted |
| TD-06 | **Inactive Shift** | `is_active=0` — should load in list, appear as Inactive badge, not appear in active dropdowns elsewhere |
| TD-07 | **Max Length Code** | Code = 20 characters `ABCDEFGHIJ1234567890` — DB limit |
| TD-08 | **Max Length Name** | Name = 100 characters — DB limit |
| TD-09 | **Minimal Dates** | `effective_from='2000-01-01'`, `effective_to='2099-12-31'` — boundary dates |
| TD-10 | **Model-DDL Phantom Fields** | Model `$fillable` includes `description`, `default_start_time`, `default_end_time`, `ordinal` — DDL has NO such columns. Any code path writing these will cause SQL error. |
| TD-11 | **Update with unchanged data** | Submit update form with no field changes — expects "No attributes changed" log message |
| TD-12 | **Restored shift state** | Soft-delete shift, then restore — expects `deleted_at=NULL`, `is_active=0` (not restored to active) |
| TD-13 | **Toggle on trashed shift** | Attempt to toggle status on a soft-deleted shift — expects 404 from route-model-binding (SoftDeletes excludes by default) |

---

## 5. Business Conditions (BC)

### BC-DB: Database Conditions

| ID | Condition | Expected | Source |
|----|-----------|----------|--------|
| BC-DB-01 | `code` — VARCHAR(20), NOT NULL, UNIQUE (`uq_shift_code`) | Max 20 chars, no nulls, no duplicates | Migration: `$table->string('code', 20)`, line 16 |
| BC-DB-02 | `name` — VARCHAR(100), NOT NULL, UNIQUE (`uq_shift_name`) | Max 100 chars, no nulls, no duplicates | Migration: `$table->string('name', 100)`, line 17 |
| BC-DB-03 | `effective_from` — DATE, NOT NULL | Valid date, no nulls | Migration: `$table->date('effective_from')`, line 18 |
| BC-DB-04 | `effective_to` — DATE, NOT NULL | Valid date, no nulls, must be after `effective_from` | Migration: `$table->date('effective_to')`, line 19 |
| BC-DB-05 | `is_active` — BOOLEAN/TINYINT(1), NOT NULL, DEFAULT 1 | 0 or 1, defaults to true | Migration: `$table->boolean('is_active')->default(true)`, line 20 |
| BC-DB-06 | `deleted_at` — TIMESTAMP NULL, via `$table->softDeletes()` | Soft deletes support | Migration line 27 |
| BC-DB-07 | `created_at` / `updated_at` — TIMESTAMP, via `$table->timestamps()` | Auto-managed by Eloquent | Migration line 26 |
| BC-DB-08 | `id` — INT UNSIGNED AUTO_INCREMENT | Primary key | Migration: `$table->increments('id')`, line 15 |
| BC-DB-09 | `description`, `default_start_time`, `default_end_time`, `ordinal` — NOT in DDL | Model `$fillable` has these 4 phantom fields — **GAP** | `Shift.php:15-25` vs migration |
| BC-DB-10 | `uq_shift_code` — UNIQUE index on `code` | Prevents duplicate codes | Migration line 23 |
| BC-DB-11 | `uq_shift_name` — UNIQUE index on `name` | Prevents duplicate names | Migration line 24 |

### BC-VAL: Validation Conditions

| ID | Condition | Rule | Source |
|----|-----------|------|--------|
| BC-VAL-01 | `code` — required, string, max:20, unique in `tpt_shift` ignoring soft-deleted | `required\|string\|max:20\|Rule::unique('tpt_shift','code')->ignore($shiftId)->whereNull('deleted_at')` | `ShiftRequest.php:31-38` |
| BC-VAL-02 | `name` — required, string, max:100, unique in `tpt_shift` ignoring soft-deleted | `required\|string\|max:100\|Rule::unique('tpt_shift','name')->ignore($shiftId)->whereNull('deleted_at')` | `ShiftRequest.php:40-47` |
| BC-VAL-03 | `effective_from` — required, date | `required\|date` | `ShiftRequest.php:49-52` |
| BC-VAL-04 | `effective_to` — required, date, after effective_from | `required\|date\|after:effective_from` | `ShiftRequest.php:54-58` |
| BC-VAL-05 | `is_active` — required, boolean (checkbox normalized from 'on'/absent via `prepareForValidation`) | `required\|boolean` | `ShiftRequest.php:60-63,70-76` |
| BC-VAL-06 | `prepareForValidation()`: merges `is_active` = `$this->has('is_active') && $this->input('is_active') === 'on'` | Checkbox 'on' → true, absent → false | `ShiftRequest.php:70-76` |
| BC-VAL-07 | `$shiftId = $this->route('shift')?->id` for unique ignore on update | Null on store (id from route binding) | `ShiftRequest.php:28` |

### BC-AUTH: Authorization Conditions

| ID | Permission | Controller Gate | Policy Method | Source |
|----|-----------|-----------------|---------------|--------|
| BC-AUTH-01 | `tenant.shift.viewAny` | Tab: `Gate::any([...tenant.shift.viewAny...])` in `TransportMasterController::index()` (line 28-41); Standalone: `Gate::authorize(...)` in `ShiftController::index()` (line 19) | `viewAny()` — line 13 | `TransportMasterController.php:28-41` |
| BC-AUTH-02 | `tenant.shift.view` | `Gate::authorize('tenant.shift.view')` in `show()` | `view()` — line 21 | `ShiftPolicy.php:21-24` |
| BC-AUTH-03 | `tenant.shift.create` | `Gate::authorize('tenant.shift.create')` in `create()` & `store()` | `create()` — line 29 | `ShiftPolicy.php:29-32` |
| BC-AUTH-04 | `tenant.shift.update` | `Gate::authorize('tenant.shift.update')` in `edit()` & `update()` & `toggleStatus()` | `update()` — line 37 | `ShiftPolicy.php:37-40` |
| BC-AUTH-05 | `tenant.shift.delete` | `Gate::authorize('tenant.shift.delete')` in `destroy()` | `delete()` — line 45 | `ShiftPolicy.php:45-48` |
| BC-AUTH-06 | `tenant.shift.restore` | `Gate::authorize('tenant.shift.restore')` in `trashed()` & `restore()` | `restore()` — line 53 | `ShiftPolicy.php:53-56` |
| BC-AUTH-07 | `tenant.shift.forceDelete` | `Gate::authorize('tenant.shift.forceDelete')` in `forceDelete()` | `forceDelete()` — line 61 | `ShiftPolicy.php:61-64` |
| BC-AUTH-08 | `tenant.shift.import` | — (not called in controller) | `import()` — line 69 | `ShiftPolicy.php:69-72` |
| BC-AUTH-09 | `tenant.shift.export` | — (not called in controller) | `export()` — line 75 | `ShiftPolicy.php:75-78` |
| BC-AUTH-10 | `tenant.shift.print` | — (not called in controller) | `print()` — line 81 | `ShiftPolicy.php:81-84` |

### BC-BIZ: Business Conditions

| ID | Condition | Expected | Source |
|----|-----------|----------|--------|
| BC-BIZ-01 | Shift code must be unique across all shifts (including inactive, excluding trashed) | DB unique constraint + Request validation with `whereNull('deleted_at')` | `ShiftRequest.php:35-37`, migration `uq_shift_code` |
| BC-BIZ-02 | Shift name must be unique across all shifts | DB unique constraint + Request validation with `whereNull('deleted_at')` | `ShiftRequest.php:44-46`, migration `uq_shift_name` |
| BC-BIZ-03 | `effective_to` must be after `effective_from` | Validation `after:effective_from` | `ShiftRequest.php:57` |
| BC-BIZ-04 | Delete sets `is_active=false` before soft-delete | `$shift->is_active = false; $shift->save(); $shift->delete();` | `ShiftController.php:124-126` |
| BC-BIZ-05 | Restore clears `deleted_at` but does NOT restore `is_active` | Restored shift comes back inactive | `ShiftController.php:156-157` — `$shift->restore()` without resetting `is_active` |
| BC-BIZ-06 | Status toggle flips `is_active` via AJAX | `POST /shift/{shift}/toggle-status` with `{is_active: 1|0}` | `ShiftController.php:190-217`, route `shift.toggleStatus` |
| BC-BIZ-07 | `update()` uses change tracking via `getOriginal()` and `getChanges()` | Builds `$changedAttributes` with old/new values for each changed field | `ShiftController.php:85-98` |
| BC-BIZ-08 | `update()` skips `updated_at` in change tracking | `if ($field === 'updated_at') continue;` | `ShiftController.php:92` |
| BC-BIZ-09 | `update()` logs "No attributes changed" when nothing changes | Fallback activity log message | `ShiftController.php:106-110` |
| BC-BIZ-10 | `store()` and `update()` use `$request->validated()` from FormRequest | Never raw `$request->input()` | `ShiftController.php:43,86` |
| BC-BIZ-11 | `forceDelete()` uses `withTrashed()->findOrFail()` | Can force-delete both trashed AND active records | `ShiftController.php:175` |
| BC-BIZ-12 | `restore()` uses `onlyTrashed()->findOrFail()` | Only finds trashed records for restore | `ShiftController.php:156` |
| BC-BIZ-13 | `trashed()` uses `onlyTrashed()->paginate(10)` | Paginated trashed list | `ShiftController.php:144` |
| BC-BIZ-14 | `index()` and `create()` and `show()` use manual `$id` param with `findOrFail()` | Inconsistent with `update()`/`destroy()` using route-model-binding | `ShiftController.php:57,69` vs `81,120,190` |
| BC-BIZ-15 | `toggleStatus()` inline validation before save | `$request->validate(['is_active' => 'required|boolean'])` | `ShiftController.php:194-196` |
| BC-BIZ-16 | `toggleStatus()` returns JSON success/failure based on `$shift->save()` | Dual return paths (line 205 vs 213) | `ShiftController.php:205-216` |

### BC-REL: Relationship Conditions

| ID | Relationship | Type | Foreign Key | Source |
|----|-------------|------|-------------|--------|
| BC-REL-01 | Shift → Route | `hasMany(Route::class, 'shift_id')` | `tpt_route.shift_id` → `tpt_shift.id` ON DELETE CASCADE | `Shift.php:42-45`, migration |
| BC-REL-02 | Shift → Pickup Points (via `tpt_pickup_points`) | FK in `tpt_pickup_points` | `tpt_pickup_points.shift_id` → `tpt_shift.id` ON DELETE CASCADE | Migration |
| BC-REL-03 | Shift → Pickup Points Route JNT | FK in `tpt_pickup_points_route_jnt` | `tpt_pickup_points_route_jnt.shift_id` → `tpt_shift.id` ON DELETE CASCADE | Migration |
| BC-REL-04 | Shift → Driver Route Vehicle JNT | FK in `tpt_driver_route_vehicle_jnt` | References `tpt_shift.id` | Migration |

### BC-REF: Reference & UI Conditions

| ID | Condition | Expected | Source |
|----|-----------|----------|--------|
| BC-REF-01 | Index tab loads in Transport Master with `@can('tenant.shift.viewAny')` | Tab shown only to authorized users | `transportmaster.blade.php:35-36` |
| BC-REF-02 | Action column in index shown only for `@canany(['tenant.shift.edit', 'tenant.shift.delete'])` | Conditional rendering | `shift/index.blade.php:46,70` |
| BC-REF-03 | Action column in trash shown only for `@canany(['tenant.shift.restore', 'tenant.shift.forceDelete'])` | Conditional rendering | `shift/trash.blade.php:20,32` |
| BC-REF-04 | Code input `maxlength="10"` in create/edit blades but DB VARCHAR(20) and Request `max:20` | **Discrepancy**: frontend 10 < backend 20 — valid entries between 11-20 chars rejected by browser | `shift/create.blade.php:37`, `shift/edit.blade.php:35` |
| BC-REF-05 | Name input `maxlength="50"` in create/edit blades but DB VARCHAR(100) and Request `max:100` | **Discrepancy**: frontend 50 < backend 100 — valid entries between 51-100 chars rejected by browser | `shift/create.blade.php:51`, `shift/edit.blade.php:42` |
| BC-REF-06 | Show view computes Duration (`diffInDays`) between `effective_from` and `effective_to` | Computed field, not stored | `shift/show.blade.php:62-66` |
| BC-REF-07 | Success flash messages use `flash()` helper: `created.shift`, `updated.shift`, `trashed.shift`, `restored.shift`, `force_deleted.shift`, `status_updated.shift`, `status_switch_failed.shift` | Flash keys must exist in lang file | `ShiftController.php:50,113,133,164,183,208,215` |
| BC-REF-08 | `shift/index.blade.php` is included inside tab-pane — standalone create/edit/show/trash use full layout | Dual context (tab + standalone) | File structure |
| BC-REF-09 | Show view displays `Created At` and `Updated At` formatted as `d M Y, h:i A` | Timestamps readable | `shift/show.blade.php:84-92` |
| BC-REF-10 | Show view has Edit button only for `@can('tenant.shift.edit')` | Conditional edit link | `shift/show.blade.php:15-19` |
| BC-REF-11 | Trash blade does NOT append `tab` parameter to pagination links | `$shifts->links()` without `appends()` | `shift/trash.blade.php:48` |
| BC-REF-12 | Create form uses `<x-backend.form.status-switch :isActive="old('is_active', true)" />` — defaults to active | Default `is_active=true` | `shift/create.blade.php:86` |
| BC-REF-13 | Edit form uses `<x-backend.form.status-switch :isActive="old('is_active', $shift->is_active)" />` — preserves current state | Pre-fills current status | `shift/edit.blade.php:62` |
| BC-REF-14 | Show view displays Status badge: `badge-success` for active, `badge-danger` for inactive | Visual status indicator | `shift/show.blade.php:76-81` |

### BC-BIZ-DEEP: Deep Business Conditions from Code Analysis

| ID | Condition | Expected | Source |
|----|-----------|----------|--------|
| BC-BIZ-DEEP-01 | `index()` has NO `$request` parameter — search/status filters in Blade never reach controller | Filters are client-side only; server returns ALL paginated shifts regardless of query params | `ShiftController.php:17-24` |
| BC-BIZ-DEEP-02 | `index()` paginates at 10 per page | `Shift::paginate(10)` | `ShiftController.php:21` |
| BC-BIZ-DEEP-03 | `store()` calls `Gate::authorize()` redundantly after `ShiftRequest::authorize()` | Both FormRequest and controller check `tenant.shift.create` | `ShiftRequest.php:16-17`, `ShiftController.php:41` |
| BC-BIZ-DEEP-04 | `update()` calls `Gate::authorize()` after `ShiftRequest::authorize()` | Both check `tenant.shift.update` | `ShiftRequest.php:19`, `ShiftController.php:83` |
| BC-BIZ-DEEP-05 | `activityLog()` in `store()` uses hardcoded string 'Some other information' for `other` key | Inconsistent with `update()` which uses `performed_by` instead | `ShiftController.php:47` |
| BC-BIZ-DEEP-06 | `activityLog()` in `restore()` and `forceDelete()` use `other` key while `destroy()` uses `performed_by` | Inconsistent activity log structure across methods | Compare `ShiftController.php:130,161,180` |
| BC-BIZ-DEEP-07 | Route model binding in `update()`, `destroy()`, `toggleStatus()` — auto-resolves with 404 | Implicit route-model-binding: `Shift $shift` parameter | `ShiftController.php:81,120,190` |
| BC-BIZ-DEEP-08 | Manual `findOrFail($id)` in `show()`, `edit()`, `restore()`, `forceDelete()` | Explicit find with 404 | `ShiftController.php:61,73,156,175` |
| BC-BIZ-DEEP-09 | `destroy()` does TWO DB writes: `$shift->save()` (set is_active=false) then `$shift->delete()` | Model saved before soft-delete | `ShiftController.php:124-126` |
| BC-BIZ-DEEP-10 | `destroy()` modifies the model in memory then saves — possible race condition if model changed between load and save | Two separate DB round-trips | `ShiftController.php:124-125` |
| BC-BIZ-DEEP-11 | `restore()` does NOT set `is_active=true` — restored shift stays inactive | Only `deleted_at` is cleared; `is_active` remains 0 | `ShiftController.php:156-157` |
| BC-BIZ-DEEP-12 | `forceDelete()` with `withTrashed()` finds both active and trashed records | Can force-delete a non-deleted shift (unlike restore which uses onlyTrashed) | `ShiftController.php:175` |
| BC-BIZ-DEEP-13 | `toggleStatus()` does NOT call `$shift->save()` before setting `is_active` — only calls `$shift->save()` after assignment | Single DB write per toggle | `ShiftController.php:198-205` |
| BC-BIZ-DEEP-14 | `toggleStatus()` saves the model AFTER the activityLog is recorded | Activity log happens before DB persists — if save fails, log exists but DB unchanged | `ShiftController.php:200-205` |
| BC-BIZ-DEEP-15 | `toggleStatus()` uses `$request->is_active` (dynamic property) not `$request->input('is_active')` | Laravel `Request` dynamic properties resolve via `__get()` → `input()` | `ShiftController.php:198` |
| BC-BIZ-DEEP-16 | No DB transaction wrapping in `destroy()` — `is_active=false` save and `delete()` are separate operations | If `save()` succeeds but `delete()` fails, shift is inactive but NOT soft-deleted | `ShiftController.php:124-126` |
| BC-BIZ-DEEP-17 | No DB transaction wrapping in `update()` — change tracking and update are not atomic | If `update()` partially fails, tracking data may be inconsistent | `ShiftController.php:85-98` |
| BC-BIZ-DEEP-18 | `$shift->getOriginal()` in `update()` captures state BEFORE the update | Correct for capturing old values | `ShiftController.php:85` |
| BC-BIZ-DEEP-19 | `$shift->getChanges()` in `update()` returns only dirty fields after `update()` | `updated_at` is always included (filtered out at line 92) | `ShiftController.php:88` |
| BC-BIZ-DEEP-20 | `$changedAttributes` uses null coalescing `?? null` for old values | If a field was null before, old value = null | `ShiftController.php:95` |
| BC-BIZ-DEEP-21 | `update()` never records `performed_by` in the WITH-changes log path | Only the "no changes" path includes `performed_by` | Compare `ShiftController.php:101-104` vs `107-109` |
| BC-BIZ-DEEP-22 | `ShiftRequest::authorize()` distinguishes POST vs non-POST for create/update permissions | `isMethod('POST')` → create, else → update | `ShiftRequest.php:16-19` |
| BC-BIZ-DEEP-23 | `ShiftRequest::prepareForValidation()` runs before validation rules | Normalizes checkbox 'on' to boolean | `ShiftRequest.php:70-76` |
| BC-BIZ-DEEP-24 | `$shiftId = $this->route('shift')?->id` in `ShiftRequest::rules()` uses null-safe operator | On store (create), `route('shift')` is null → `$shiftId` = null → `ignore()` ignored | `ShiftRequest.php:28` |
| BC-BIZ-DEEP-25 | `unique` rule with `whereNull('deleted_at')` allows soft-deleted duplicates | Soft-deleted records excluded from unique check | `ShiftRequest.php:37,46` |
| BC-BIZ-DEEP-26 | `Shift` model uses `BaseModel` which provides base functionality | BaseModel likely provides `$table` prefix, timestamps, etc. | `Shift.php:5` |
| BC-BIZ-DEEP-27 | `Shift` model `$casts` declares `effective_from` as `date`, `effective_to` as `date` | Carbon date objects | `Shift.php:28-29` |
| BC-BIZ-DEEP-28 | `Shift` model `$casts` declares `is_active` as `boolean` | Returns PHP bool, not int | `Shift.php:32` |
| BC-BIZ-DEEP-29 | `Shift` model `$casts` declares phantom fields `default_start_time` and `default_end_time` as `datetime:H:i:s` | Phantom casts on non-existent columns | `Shift.php:30-31` |
| BC-BIZ-DEEP-30 | `scopeActive()` defined in model but NOT used in controller | Dead code — no controller method calls `->active()` | `Shift.php:36-39` |
| BC-BIZ-DEEP-31 | `routes()` relationship defined but NOT eager-loaded in any controller method | N+1 possible if view accesses `$shift->routes` | `Shift.php:42-45` |
| BC-BIZ-DEEP-32 | `Shift::paginate(10)` in `index()` uses default query — no ordering | Order may be unpredictable (typically by PK) | `ShiftController.php:21` |
| BC-BIZ-DEEP-33 | `index()` Blade renders dates via `\Carbon\Carbon::parse()` not `$shift->effective_from->format()` | Redundant parse since model casts to date | `shift/index.blade.php:58,64` |
| BC-BIZ-DEEP-34 | `status-switch` component URL pattern: `url="transport.shift"` generates toggle route | Component likely builds `/shift/{id}/toggle-status` | `shift/index.blade.php:68` |
| BC-BIZ-DEEP-35 | `action` component URL pattern: `url="transport.shift"` generates show/edit/delete links | Component likely builds CRUD action buttons | `shift/index.blade.php:72` |
| BC-BIZ-DEEP-36 | Trash `action-trashed` component URL pattern: `url="transport.shift"` generates restore/forceDelete links | `<x-backend.table.action-trashed>` component | `shift/trash.blade.php:34` |
| BC-BIZ-DEEP-37 | No `is_system_defined` guard — all shifts are deletable | Unlike some entities that prevent deletion of system records | Controller code review |
| BC-BIZ-DEEP-38 | `toggleStatus()` JSON success response includes `message` from `flash()` | `{success: true, is_active: ..., message: "..."}` | `ShiftController.php:206-210` |
| BC-BIZ-DEEP-39 | `toggleStatus()` JSON failure response includes `message` only (no `is_active`) | `{success: false, message: "..."}` | `ShiftController.php:213-216` |
| BC-BIZ-DEEP-40 | `toggleStatus()` returns HTTP 200 even on failure (not 4xx/5xx) | Both success and failure return 200 with different JSON bodies | `ShiftController.php:205-216` |
| BC-BIZ-DEEP-41 | `prepareForValidation()` merges `is_active` — value becomes `true` if checkbox was 'on', else `false` | Normalized before rules run | `ShiftRequest.php:73-75` |
| BC-BIZ-DEEP-42 | `redirect()->route('transport.shift.trashed')` in `restore()` and `forceDelete()` | Redirects TO trash page | `ShiftController.php:164,183` |
| BC-BIZ-DEEP-43 | `redirect()->route('transport.transport-master.index')` in `store()`, `update()`, `destroy()` | Redirects TO transport master (Shift tab) | `ShiftController.php:50,113,133` |
| BC-BIZ-DEEP-44 | `show()` view uses `Badge` for code display | `<span class="badge badge-info">{{ $shift->code ?? '-' }}</span>` | `shift/show.blade.php:31` |
| BC-BIZ-DEEP-45 | `show()` view fallback `?? '-'` for all fields | Null-safe display | `shift/show.blade.php:31,36,44,54,69,86,90` |
| BC-BIZ-DEEP-46 | `show()` view checks `$shift->is_active == 1` (loose comparison) | `==` not `===` | `shift/show.blade.php:76` |
| BC-BIZ-DEEP-47 | `edit.blade.php` uses `$shift->effective_from?->format('Y-m-d')` (null-safe Carbon format) | Correct for cast-to-date objects | `shift/edit.blade.php:50` |
| BC-BIZ-DEEP-48 | `edit.blade.php` has `enctype="multipart/form-data"` — unnecessary (no file upload) | Minor: form encoding includes multipart with no file inputs | `shift/edit.blade.php:26` |
| BC-BIZ-DEEP-49 | `create.blade.php` does NOT have `enctype` attribute | Clean form (no files) | `shift/create.blade.php:25` |
| BC-BIZ-DEEP-50 | Create form has manual `<input>` tags, Edit form uses `<x-backend.form.input-text>` component | Inconsistent form field rendering | Compare `shift/create.blade.php:34-37` vs `shift/edit.blade.php:34-36` |
| BC-BIZ-DEEP-51 | Shift Policy `view()`, `update()`, `delete()`, `restore()`, `forceDelete()` accept `Shift $shift` param | Policy methods require model instance for authorization | `ShiftPolicy.php:21,37,45,53,61` |
| BC-BIZ-DEEP-52 | Shift Policy `viewAny()`, `create()`, `import()`, `export()`, `print()` accept only `User $user` | Model-less permissions | `ShiftPolicy.php:13,29,69,77,85` |
| BC-BIZ-DEEP-53 | `toggleStatus()` does not check if shift is trashed before toggling | Route-model-binding with SoftDeletes model — default query excludes trashed → 404 if trashed | `ShiftController.php:190` |
| BC-BIZ-DEEP-54 | `restore()` does not check if already restored (not trashed) | `onlyTrashed()->findOrFail()` throws 404 if already active | `ShiftController.php:156` |
| BC-BIZ-DEEP-55 | `forceDelete()` can be called on active (non-trashed) records | `withTrashed()` finds all records | `ShiftController.php:175` |
| BC-BIZ-DEEP-56 | `show()` view uses `?? '-'` fallback for all fields including code | Safe null display | `shift/show.blade.php:31,36,44,54,69,86,90` |
| BC-BIZ-DEEP-57 | `edit.blade.php` uses component `<x-backend.form.input-text>` for Code and Name fields | Consistent component usage for text inputs | `shift/edit.blade.php:34-43` |
| BC-BIZ-DEEP-58 | `create.blade.php` uses raw `<input>` tags for Code and Name (NOT the component) | Inconsistent with edit.blade.php — raw inputs with manual error display | `shift/create.blade.php:34-55` |
| BC-BIZ-DEEP-59 | `show.blade.php` evaluates Duration via `@php` directive | Inline PHP for computed field | `shift/show.blade.php:62-66` |
| BC-BIZ-DEEP-60 | Index blade uses `$shift->effective_from` directly in Carbon::parse (already a Carbon instance from cast) | `Carbon::parse()` on a Carbon object works (returns clone) but is redundant | `shift/index.blade.php:58` |
| BC-BIZ-DEEP-61 | Trash blade uses `$shift->effective_from?->format('d-m-Y')` directly (no Carbon::parse) | More efficient — uses Carbon object directly via null-safe operator | `shift/trash.blade.php:30-31` |
| BC-BIZ-DEEP-62 | Show blade uses `$shift->created_at->format('d M Y, h:i A')` directly (no Carbon::parse) | Direct Carbon format from Eloquet model's timestamps | `shift/show.blade.php:85,90` |
| BC-BIZ-DEEP-63 | Index blade search input `name="search"` sends `?search=` query param | Controller never reads `request('search')` — **filtering gap** | `shift/index.blade.php:10-11`, `ShiftController.php:17-24` |
| BC-BIZ-DEEP-64 | Index blade status filter `name="status"` sends `?status=` query param | Controller never reads `request('status')` — **filtering gap** | `shift/index.blade.php:13-17`, `ShiftController.php:17-24` |
| BC-BIZ-DEEP-65 | Tab parameter preserved in URL via hidden input AND pagination appends | Double preservation: form hidden + pagination appends | `shift/index.blade.php:9,88` |
| BC-BIZ-DEEP-66 | Status-switch component on index uses `url="transport.shift"` and `:model="$shift"` | Generic component generates route from URL prefix + model ID | `shift/index.blade.php:68` |
| BC-BIZ-DEEP-67 | Action component on index uses `:id="$shift->id" url="transport.shift" permissions="tenant.shift"` | Generic component generates show/edit/delete links | `shift/index.blade.php:72` |
| BC-BIZ-DEEP-68 | `action-trashed` component on trash uses same pattern with `permissions="tenant.shift"` | Generates restore/forceDelete links for trashed records | `shift/trash.blade.php:34` |
| BC-BIZ-DEEP-69 | Show view Back button links to `transport.transport-master.index` (no tab param) | Returns to Transport Master (defaults to first tab, not necessarily Shift tab) | `shift/show.blade.php:12` |
| BC-BIZ-DEEP-70 | Show view Edit link uses `transport.shift.edit` with `$shift->id` | Correct route to edit page | `shift/show.blade.php:16` |
| BC-BIZ-DEEP-71 | `transportmaster.blade.php` Shift tab uses permission `tenant.shift.viewAny` | Matches controller Gate in `index()` | `transportmaster.blade.php:10` |
| BC-BIZ-DEEP-72 | `ShiftPolicy` imports `User` from `Modules\SchoolSetup\Models\User` | Custom User model from SchoolSetup module | `ShiftPolicy.php:5` |
| BC-BIZ-DEEP-73 | `ShiftPolicy` `viewAny()`, `create()`, `import()`, `export()`, `print()` accept no `Shift` model | These are model-less gates | `ShiftPolicy.php:13,29,69,77,85` |
| BC-BIZ-DEEP-74 | `ShiftController` extends `App\Http\Controllers\Controller` | Standard base controller | `ShiftController.php:5,12` |
| BC-BIZ-DEEP-75 | All controller methods use `use Illuminate\Support\Facades\Auth;` but only `update()` and `destroy()` use `Auth::user()` | Unused import in other methods | `ShiftController.php:7,104,109,130` |

---

## 6. Test Case List

### TC-P: Positive Test Cases

| ID | Test Case | Summary | Expected Result |
|----|-----------|---------|-----------------|
| TC-P-01 | Create shift with valid data | Fill all required fields with valid values | Shift created, flash "created.shift", redirect to transport-master.index |
| TC-P-02 | Create shift with minimum data | Only required fields, default status active | Shift created with `is_active=true` |
| TC-P-03 | Edit shift name | Change name from "Morning Shift" to "AM Shift" | Updated, activity log records field-level change |
| TC-P-04 | Edit shift date range | Extend effective_to by 30 days | Updated, activity log captures old vs new dates |
| TC-P-05 | Toggle shift active→inactive | Click status switch to deactivate | AJAX response `{success:true, is_active:0}`, badge changes |
| TC-P-06 | Toggle shift inactive→active | Click status switch to activate | AJAX response `{success:true, is_active:1}`, badge changes |
| TC-P-07 | View shift details | Click view action on a shift record | Show page displays all fields with formatted dates |
| TC-P-08 | View shift list with pagination | Navigate through multiple pages of shifts | Paginated results, tab parameter preserved |
| TC-P-09 | Edit shift without changing any field | Submit unchanged form | "No attributes changed" logged, flash "updated.shift" |
| TC-P-10 | Create shift with same code as soft-deleted | Delete code "MORN", create new with same code | Success (unique ignores soft-deleted) |
| TC-P-11 | Create shift with max-length code | Code = exactly 20 chars | Successfully created (via API, not UI — UI limits to 10) |
| TC-P-12 | Create shift with max-length name | Name = exactly 100 chars | Successfully created (via API, not UI — UI limits to 50) |
| TC-P-13 | Restore soft-deleted shift | Go to trash, click restore | Shift restored (inactive), flash "restored.shift", redirect to trash |
| TC-P-14 | Delete shift (soft delete) | Click delete on existing shift | Shift deactivated (`is_active=0`), soft-deleted, flash "trashed.shift" |
| TC-P-15 | Force delete shift from trash | Go to trash, click force delete on trashed shift | Record permanently deleted, flash "force_deleted.shift" |
| TC-P-16 | View trashed shifts list | Navigate to trash page | Trashed shifts list with Action column showing restore/forceDelete |
| TC-P-17 | Force delete active (non-trashed) shift | Call forceDelete on active shift | Succeeds — `withTrashed()` finds active records too |
| TC-P-18 | Batch create multiple shifts sequentially | Create 3 shifts one after another | All created with unique codes/names |
| TC-P-19 | View shift on last page of pagination | Navigate to page with remaining items | Paginator shows correct results, `?page=N&tab=shift` preserved |
| TC-P-20 | Toggle status via direct POST with JSON | Send `{is_active: 1}` to toggleStatus endpoint | AJAX success, status flipped |

### TC-N: Negative Test Cases

| ID | Test Case | Summary | Expected Result |
|----|-----------|---------|-----------------|
| TC-N-01 | Create shift with empty code | Submit form without code | Validation error: "The code field is required." |
| TC-N-02 | Create shift with empty name | Submit form without name | Validation error: "The name field is required." |
| TC-N-03 | Create shift with duplicate code | Use existing code "MORN" | Validation error: "The code has already been taken." |
| TC-N-04 | Create shift with duplicate name | Use existing name "Morning Shift" | Validation error: "The name has already been taken." |
| TC-N-05 | Create shift with end date before start date | effective_from > effective_to | Validation error: "The effective to must be a date after effective from." |
| TC-N-06 | Create shift with invalid date format | Enter non-date value in effective_from | Validation error: "The effective from is not a valid date." |
| TC-N-07 | Update shift with code exceeding 20 chars | Enter 21-character code | Validation error: "The code must not be greater than 20 characters." |
| TC-N-08 | Update shift with name exceeding 100 chars | Enter 101-character name | Validation error: "The name must not be greater than 100 characters." |
| TC-N-09 | Submit form without is_active checkbox | Ensure checkbox is unchecked (off) | `is_active` defaults to `false` via `prepareForValidation()` |
| TC-N-10 | Access index without permission | User lacks `tenant.shift.viewAny` | 403 Access Denied |
| TC-N-11 | Access create without permission | User lacks `tenant.shift.create` | 403 Access Denied |
| TC-N-12 | Access edit without permission | User lacks `tenant.shift.update` | 403 Access Denied |
| TC-N-13 | Attempt delete without permission | User lacks `tenant.shift.delete` | 403 Access Denied |
| TC-N-14 | Attempt restore without permission | User lacks `tenant.shift.restore` | 403 Access Denied |
| TC-N-15 | Attempt forceDelete without permission | User lacks `tenant.shift.forceDelete` | 403 Access Denied |
| TC-N-16 | Save with phantom fields via direct model call | `Shift::create(['description'=>'test'])` | SQL error — column `description` not in DDL (GAP) |
| TC-N-17 | Access show without permission | User lacks `tenant.shift.view` | 403 Access Denied |
| TC-N-18 | Submit store (POST) without permission | User lacks `tenant.shift.create` | 403 — `ShiftRequest::authorize()` returns false |
| TC-N-19 | Submit update (PUT) without permission | User lacks `tenant.shift.update` | 403 — `ShiftRequest::authorize()` returns false |
| TC-N-20 | Toggle status without permission | User lacks `tenant.shift.update` | 403 Access Denied |
| TC-N-21 | Access trash page without permission | User lacks `tenant.shift.restore` | 403 Access Denied |
| TC-N-22 | Update with code exceeding 20 chars as API | POST/PUT via API with 21-char code | Validation error from ShiftRequest |
| TC-N-23 | Update with name exceeding 100 chars as API | POST/PUT via API with 101-char name | Validation error from ShiftRequest |
| TC-N-24 | Create shift with existing soft-deleted same name | Delete "Morning Shift", create new with same name | **Should succeed** — unique ignores soft-deleted |

### TC-D: Data Integrity Test Cases

| ID | Test Case | Summary | Expected Result |
|----|-----------|---------|-----------------|
| TC-D-01 | Delete shift with active routes | Delete a shift that has routes assigned | Shift soft-deleted, routes remain (CASCADE does NOT delete routes on soft-delete) |
| TC-D-02 | Restore shift that had routes | Restore trashed shift | Routes re-associated via FK, shift inactive |
| TC-D-03 | Force delete shift | Permanently remove trashed shift | Record deleted from DB, activity log records "Deleted" |
| TC-D-04 | Verify is_active=false before soft-delete | Query `is_active` for trashed record | `is_active=0` and `deleted_at` is NOT NULL |
| TC-D-05 | Verify restore does not reset is_active | Query `is_active` after restore | `is_active=0` (still inactive) — only `deleted_at` cleared |
| TC-D-06 | Duplicate code creation after force-delete | Hard-delete code "MORN", create new with same | Works — no conflict (no trashed record to ignore) |
| TC-D-07 | Verify unique constraint excludes soft-deleted | SQL query with `WHERE deleted_at IS NULL` | Unique check only on non-deleted records |
| TC-D-08 | Check DB columns match Request validation | Ensure code max:20 matches VARCHAR(20) | Consistent |
| TC-D-09 | Check DB columns match Request validation | Ensure name max:100 matches VARCHAR(100) | Consistent |
| TC-D-10 | **GAP**: Model fillable has 4 phantom columns | `description`, `default_start_time`, `default_end_time`, `ordinal` in `$fillable` but NOT in DDL | **CRITICAL**: Must be removed from `$fillable` or columns must be added to DDL |
| TC-D-11 | Force delete shift with active routes | Force-delete a trashed shift that has dependent `tpt_route` records | Route rows remain orphaned with `shift_id` pointing to deleted shift |
| TC-D-12 | Verify `toggleStatus()` persists to DB | Check DB `is_active` after toggle | Value matches toggle request |
| TC-D-13 | Verify `update()` change tracking accuracy | Change single field, check log | Only changed field appears in `$changedAttributes` |
| TC-D-14 | Verify `updated_at` excluded from change log | Update any field, check log | `updated_at` not in `$changedAttributes` |
| TC-D-15 | Verify no change = "No attributes changed" message | Submit update with identical data | Activity log says "No attributes changed" |
| TC-D-16 | Verify `prepareForValidation()` normalizes correctly | Checkbox 'on' → true, absent → false | `is_active` properly converted |
| TC-D-17 | Verify trashed list excludes active records | `onlyTrashed()` in `trashed()` | No active records in trash |

### TC-CR: Code Review Test Cases

| ID | Test Case | Source | Expected Result |
|----|-----------|--------|-----------------|
| TC-CR-01 | Verify `Gate::authorize()` call in `index()` (standalone route) | `ShiftController.php:19` | `tenant.shift.viewAny` gate checked before data load |
| TC-CR-01B | Verify `Gate::any()` in `TransportMasterController::index()` for Shift tab visibility | `TransportMasterController.php:28-41` | Aggregate gate includes `tenant.shift.viewAny` for tab display |
| TC-CR-02 | Verify `Gate::authorize()` call in `create()` | `ShiftController.php:31` | `tenant.shift.create` gate checked |
| TC-CR-03 | Verify `Gate::authorize()` call in `store()` | `ShiftController.php:41` | `tenant.shift.create` gate checked (redundant with create but present) |
| TC-CR-04 | Verify `Gate::authorize()` call in `show()` | `ShiftController.php:59` | `tenant.shift.view` gate checked |
| TC-CR-05 | Verify `Gate::authorize()` call in `edit()` | `ShiftController.php:71` | `tenant.shift.update` gate checked |
| TC-CR-06 | Verify `Gate::authorize()` call in `update()` | `ShiftController.php:83` | `tenant.shift.update` gate checked |
| TC-CR-07 | Verify `Gate::authorize()` call in `destroy()` | `ShiftController.php:122` | `tenant.shift.delete` gate checked |
| TC-CR-08 | Verify `Gate::authorize()` call in `trashed()` | `ShiftController.php:142` | `tenant.shift.restore` gate checked |
| TC-CR-09 | Verify `Gate::authorize()` call in `restore()` | `ShiftController.php:154` | `tenant.shift.restore` gate checked |
| TC-CR-10 | Verify `Gate::authorize()` call in `forceDelete()` | `ShiftController.php:173` | `tenant.shift.forceDelete` gate checked |
| TC-CR-11 | Verify `Gate::authorize()` call in `toggleStatus()` | `ShiftController.php:192` | `tenant.shift.update` gate checked |
| TC-CR-12 | Verify `activityLog()` call in `store()` | `ShiftController.php:45-48` | Log type "Stored", message "A new shift was created." |
| TC-CR-13 | Verify `activityLog()` call in `update()` with changes | `ShiftController.php:100-105` | Log type "Updated", includes `$changedAttributes` with old/new |
| TC-CR-14 | Verify `activityLog()` call in `update()` without changes | `ShiftController.php:106-110` | Log type "Updated", message "No attributes changed." |
| TC-CR-15 | Verify `activityLog()` call in `destroy()` | `ShiftController.php:128-131` | Log type "Trashed", message "Shift was deactivated and trashed." |
| TC-CR-16 | Verify `activityLog()` call in `restore()` | `ShiftController.php:159-162` | Log type "Restored", message "Shift was restored." |
| TC-CR-17 | Verify `activityLog()` call in `forceDelete()` | `ShiftController.php:178-181` | Log type "Deleted", message "Shift was permanently deleted." |
| TC-CR-18 | Verify `activityLog()` call in `toggleStatus()` | `ShiftController.php:200-203` | Log type "Toggled", message "Shift status was updated." |
| TC-CR-19 | Verify change tracking in `update()` | `ShiftController.php:85-98` | `$original = $shift->getOriginal()`, `$changes = $shift->getChanges()`, skips `updated_at`, builds `$changedAttributes` |
| TC-CR-20 | Verify `is_active=false` before `delete()` in `destroy()` | `ShiftController.php:124-126` | `$shift->is_active = false; $shift->save(); $shift->delete();` |
| TC-CR-21 | Verify `onlyTrashed()` in `trashed()` | `ShiftController.php:144` | `Shift::onlyTrashed()->paginate(10)` |
| TC-CR-22 | Verify `onlyTrashed()->findOrFail()` in `restore()` | `ShiftController.php:156` | `Shift::onlyTrashed()->findOrFail($id)` |
| TC-CR-23 | Verify `withTrashed()->findOrFail()` in `forceDelete()` | `ShiftController.php:175` | `Shift::withTrashed()->findOrFail($id)` |
| TC-CR-24 | Verify `toggleStatus()` inline validation | `ShiftController.php:194-196` | `$request->validate(['is_active' => 'required\|boolean'])` |
| TC-CR-25 | Verify `toggleStatus()` JSON response on success | `ShiftController.php:206-210` | `{success: true, is_active: ..., message: flash('status_updated.shift')}` |
| TC-CR-26 | Verify `toggleStatus()` JSON response on failure | `ShiftController.php:213-216` | `{success: false, message: flash('status_switch_failed.shift')}` |
| TC-CR-27 | Verify `ShiftRequest@authorize()` for POST | `ShiftRequest.php:16-17` | `Gate::allows('tenant.shift.create')` |
| TC-CR-28 | Verify `ShiftRequest@authorize()` for non-POST | `ShiftRequest.php:19` | `Gate::allows('tenant.shift.update')` |
| TC-CR-29 | Verify `ShiftRequest@prepareForValidation()` checkbox normalization | `ShiftRequest.php:71-75` | `$this->has('is_active') && $this->input('is_active') === 'on'` |
| TC-CR-30 | Verify redirect after store/update/destroy | All CRUD methods | `redirect()->route('transport.transport-master.index')` — NOT shift.index |
| TC-CR-31 | Verify redirect after restore/forceDelete | `restore()`, `forceDelete()` | `redirect()->route('transport.shift.trashed')` |
| TC-CR-32 | Verify `@can('tenant.shift.edit')` in show view | `shift/show.blade.php:15` | Edit button shown only if user has `tenant.shift.edit` |
| TC-CR-33 | Verify `@canany(['tenant.shift.edit', 'tenant.shift.delete'])` in index | `shift/index.blade.php:46,70` | Action column conditionally rendered |
| TC-CR-34 | Verify `@canany(['tenant.shift.restore', 'tenant.shift.forceDelete'])` in trash | `shift/trash.blade.php:20,32` | Action column conditionally rendered in trash |
| TC-CR-35 | Verify `flash()` helper keys exist | `ShiftController.php:50,113,133,164,183,208,215` | Keys: `created.shift`, `updated.shift`, `trashed.shift`, `restored.shift`, `force_deleted.shift`, `status_updated.shift`, `status_switch_failed.shift` |
| TC-CR-36 | Verify pagination appends `tab` parameter | `shift/index.blade.php:88` | `$shifts->appends(['tab' => request('tab', 'shift')])->links()` |
| TC-CR-37 | Verify search form includes hidden `tab=shift` | `shift/index.blade.php:9` | `<input type="hidden" name="tab" value="shift">` |
| TC-CR-38 | Verify status filter dropdown options | `shift/index.blade.php:13-17` | All, Active (1), Inactive (0) with `selected` on request match |
| TC-CR-39 | Verify `code` maxlength inconsistency: blade 10 vs request 20 vs DB 20 | `shift/create.blade.php:37`, `shift/edit.blade.php:35`, `ShiftRequest.php:33`, DDL | **Minor GAP**: Frontend restricts to 10 chars but backend/DB allows 20 |
| TC-CR-40 | Verify `name` maxlength inconsistency: blade 50 vs request 100 vs DB 100 | `shift/create.blade.php:51`, `shift/edit.blade.php:42`, `ShiftRequest.php:43`, DDL | **Minor GAP**: Frontend restricts to 50 chars but backend/DB allows 100 |
| TC-CR-41 | Verify show view computes Duration in days | `shift/show.blade.php:62-66` | `$from->diffInDays($to)` badge |
| TC-CR-42 | Verify show view displays `Created At` and `Updated At` | `shift/show.blade.php:84-92` | Formatted `d M Y, h:i A` |
| TC-CR-43 | Verify `$fillable` array in Shift model | `Shift.php:15-25` | Contains phantom fields: `description`, `default_start_time`, `default_end_time`, `ordinal` |
| TC-CR-44 | Verify `$casts` in Shift model | `Shift.php:27-33` | `effective_from=>date`, `effective_to=>date`, `default_start_time=>datetime:H:i:s` (phantom), `default_end_time=>datetime:H:i:s` (phantom), `is_active=>boolean` |
| TC-CR-45 | Verify `scopeActive()` in Shift model | `Shift.php:36-39` | `where('is_active', true)` — defined but never used in controller |
| TC-CR-46 | Verify `routes()` relationship | `Shift.php:42-45` | `$this->hasMany(Route::class, 'shift_id')` |
| TC-CR-47 | Verify route definitions | `routes/web.php:113-117` | `resource('shift', ...)`, `trashed`, `restore`, `forceDelete`, `toggleStatus` |
| TC-CR-48 | Verify `ShiftController` uses `ShiftRequest` type-hint | `ShiftController.php:9,39,81` | Constructor injection in `store()` and `update()` |
| TC-CR-49 | Verify `$request->validated()` in `store()` | `ShiftController.php:43` | `Shift::create($request->validated())` — never raw `$request->input()` |
| TC-CR-50 | Verify `$request->validated()` in `update()` | `ShiftController.php:86` | `$shift->update($request->validated())` — never raw `$request->input()` |
| TC-CR-51 | Verify route model binding pattern | `ShiftController.php:81,120,190` vs `57,69,152,171` | `update()`, `destroy()`, `toggleStatus()` use `Shift $shift` (route binding); `show($id)`, `edit($id)`, `restore($id)`, `forceDelete($id)` use manual `findOrFail($id)` — inconsistent pattern |
| TC-CR-52 | Verify `restore()` does NOT reset `is_active` | `ShiftController.php:156-157` | `$shift->restore()` called without setting `is_active=true` — restored shift remains inactive |
| TC-CR-53 | **GAP**: `index()` missing search/status filter handling | `ShiftController.php:17-24` | Controller has no `$request` parameter — search/status from Blade URL never processed |
| TC-CR-54 | **GAP**: Inconsistent `activityLog` `other` vs `performed_by` key | `ShiftController.php:47,130,161,180` | `store()` uses `other`, `destroy()` uses `performed_by`, `restore()` uses `other`, `forceDelete()` uses `other` |
| TC-CR-55 | **GAP**: `update()` missing `performed_by` in changes-path | `ShiftController.php:101-104` | Only no-changes path includes `Auth::user()->name` |
| TC-CR-56 | **GAP**: `toggleStatus()` logs BEFORE save | `ShiftController.php:200-205` | If save fails, activity log already written with "Toggled" |
| TC-CR-57 | **GAP**: `destroy()` no DB transaction | `ShiftController.php:124-126` | Two separate queries without transaction — partial failure possible |
| TC-CR-58 | **GAP**: No `->orderBy()` in `index()` or `trashed()` queries | `ShiftController.php:21,144` | Results order undefined (depends on DB default) |
| TC-CR-59 | **GAP**: `edit.blade.php` has unnecessary `enctype="multipart/form-data"` | `shift/edit.blade.php:26` | No file upload fields in form |
| TC-CR-60 | **GAP**: `index.blade.php` double-parses dates already cast to Carbon | `shift/index.blade.php:58,64` | `\Carbon\Carbon::parse($shift->effective_from)` — redundant as model already casts to date |

### CODE-TRACE: Per-Method Line-by-Line Execution

> ⚠️ **Note**: CODE-TRACE-01 traces the **standalone route** `/shift` → `ShiftController::index()`. The **primary tab listing** at `/transport/master?tab=shift` goes through `TransportMasterController::index()` → `shiftsQuery()` (see CODE-TRACE-A below).

#### CODE-TRACE-01: `index()` — ShiftController.php:17-24 (Standalone Route)

| Step # | Line(s) | Code | What It Does |
|--------|---------|------|-------------|
| 1 | 19 | `Gate::authorize('tenant.shift.viewAny')` | Aborts with 403 if user lacks `tenant.shift.viewAny` permission |
| 2 | 21 | `$shifts = Shift::paginate(10)` | Executes `SELECT * FROM tpt_shift WHERE deleted_at IS NULL LIMIT 10 OFFSET 0` + count query. Uses SoftDeletes global scope. Returns `LengthAwarePaginator` instance. |
| 3 | 23 | `return view('transport::shift.index', compact('shifts'))` | Renders `resources/views/shift/index.blade.php` with `$shifts` variable. **Note**: No search/status filtering despite Blade having search/status inputs. |

#### CODE-TRACE-A: `shiftsQuery(Request $request)` — TransportMasterController Lines 218-226 (Tab Listing)

| Step # | Line(s) | Code | What It Does |
|--------|---------|------|-------------|
| 1 | 28-41 | `Gate::any(['tenant.shift.viewAny', ...])` | Aggregate gate — user must have ANY transport master tab permission |
| 2 | 218 | `$query = Shift::query()` | Start query builder |
| 3 | 220 | `if ($request->input('tab') === 'shift')` | Only apply filters when Shift tab is active |
| 4 | 221-224 | `->when(search/status)` | Search on `code`/`name` + status filter (same as Blade UI) |
| 5 | 225 | `->latest()` | Order by created_at DESC |
| 6 | `index()` | `->paginate(10, ['*'], 'shifts_page')` | Paginate with unique page name `shifts_page` |
| 7 | `index()` | `->withQueryString()` | Preserve query params |
| 8 | `tab.blade.php` | `@include('transport::shift.index')` | Tab partial rendered inside transportmaster tab |

#### CODE-TRACE-02: `create()` — ShiftController.php:29-34

| Step # | Line(s) | Code | What It Does |
|--------|---------|------|-------------|
| 1 | 31 | `Gate::authorize('tenant.shift.create')` | Aborts with 403 if user lacks `tenant.shift.create` permission |
| 2 | 33 | `return view('transport::shift.create')` | Renders `resources/views/shift/create.blade.php` with no variables |

#### CODE-TRACE-03: `store(ShiftRequest $request)` — ShiftController.php:39-52

| Step # | Line(s) | Code | What It Does |
|--------|---------|------|-------------|
| 1 | 39 | `public function store(ShiftRequest $request)` | Laravel resolves `ShiftRequest` via the container. `ShiftRequest::authorize()` runs FIRST (before method body). For POST, checks `Gate::allows('tenant.shift.create')`. If fails, throws 403. `ShiftRequest::prepareForValidation()` runs: merges `is_active` = true if checkbox was 'on', else false. `ShiftRequest::rules()` runs: validates code (required, string, max:20, unique ignoring soft-deleted), name (required, string, max:100, unique ignoring soft-deleted), effective_from (required, date), effective_to (required, date, after:effective_from), is_active (required, boolean). If validation fails, redirects back with errors. |
| 2 | 41 | `Gate::authorize('tenant.shift.create')` | Second gate check in controller (redundant after FormRequest) |
| 3 | 43 | `$shift = Shift::create($request->validated())` | Inserts row into `tpt_shift`. `$request->validated()` returns only the validated fields: code, name, effective_from, effective_to, is_active. Returns the created `Shift` model instance. |
| 4 | 45-48 | `activityLog($shift, 'Stored', ['message' => 'A new shift was created.', 'other' => 'Some other information'])` | Records activity log entry with type "Stored". Note: uses `other` key (not `performed_by`). |
| 5 | 50-51 | `return redirect()->route('transport.transport-master.index')->with('success', flash('created.shift'))` | Redirects to Transport Master index page with success flash message from `flash('created.shift')` |

#### CODE-TRACE-04: `show($id)` — ShiftController.php:57-64

| Step # | Line(s) | Code | What It Does |
|--------|---------|------|-------------|
| 1 | 59 | `Gate::authorize('tenant.shift.view')` | Aborts with 403 if user lacks `tenant.shift.view` permission |
| 2 | 61 | `$shift = Shift::findOrFail($id)` | Executes `SELECT * FROM tpt_shift WHERE id = ? AND deleted_at IS NULL LIMIT 1`. Throws `ModelNotFoundException` (404) if not found. Respects SoftDeletes global scope — trashed shifts not found. |
| 3 | 63 | `return view('transport::shift.show', compact('shift'))` | Renders `resources/views/shift/show.blade.php` with `$shift` model instance |

#### CODE-TRACE-05: `edit($id)` — ShiftController.php:69-76

| Step # | Line(s) | Code | What It Does |
|--------|---------|------|-------------|
| 1 | 71 | `Gate::authorize('tenant.shift.update')` | Aborts with 403 if user lacks `tenant.shift.update` permission |
| 2 | 73 | `$shift = Shift::findOrFail($id)` | Same query as show(). Finds non-deleted shift by ID. 404 if not found. |
| 3 | 75 | `return view('transport::shift.edit', compact('shift'))` | Renders `resources/views/shift/edit.blade.php` with `$shift` model instance |

#### CODE-TRACE-06: `update(ShiftRequest $request, Shift $shift)` — ShiftController.php:81-115

| Step # | Line(s) | Code | What It Does |
|--------|---------|------|-------------|
| 1 | 81 | `public function update(ShiftRequest $request, Shift $shift)` | Laravel resolves `ShiftRequest` (authorize + validate). Also resolves `Shift` via route-model-binding: auto-query based on `{shift}` route param. Model NOT excluded by SoftDeletes (Eloquent global scope excludes trashed from queries). If shift is soft-deleted, route binding throws 404. `ShiftRequest::authorize()` for non-POST checks `Gate::allows('tenant.shift.update')`. Validation rules run: same as store but `$shiftId` = `$this->route('shift')?->id` for unique ignore. |
| 2 | 83 | `Gate::authorize('tenant.shift.update')` | Second gate check in controller (redundant after FormRequest) |
| 3 | 85 | `$original = $shift->getOriginal()` | Captures current DB values BEFORE update. Returns array of all attributes from the retrieved model. |
| 4 | 86 | `$shift->update($request->validated())` | Executes `UPDATE tpt_shift SET ... WHERE id = ?`. Only updates fields present in `$request->validated()`. `updated_at` auto-set by Eloquent. |
| 5 | 88 | `$changes = $shift->getChanges()` | Returns array of fields that changed (only those in the update query). Always includes `updated_at`. |
| 6 | 89 | `$changedAttributes = []` | Initialize empty array for tracking meaningful changes |
| 7 | 91-98 | `foreach ($changes as $field => $newValue) { if ($field === 'updated_at') continue; $changedAttributes[$field] = ['old' => $original[$field] ?? null, 'new' => $newValue]; }` | Iterates each changed field, skips `updated_at`, builds old/new array using `$original` captured before update. Uses `?? null` for old value fallback. |
| 8 | 100-105 | If `!empty($changedAttributes)`: `activityLog($shift, 'Updated', ['message' => 'Shift was updated.', 'changes' => $changedAttributes, 'performed_by' => Auth::user()->name])` | Logs update with field-level change details. Includes `performed_by`. |
| 9 | 106-110 | Else (no changes): `activityLog($shift, 'Updated', ['message' => 'Shift updated. No attributes changed.', 'performed_by' => Auth::user()->name])` | Logs "no changes" message. Also includes `performed_by`. |
| 10 | 113-114 | `return redirect()->route('transport.transport-master.index')->with('success', flash('updated.shift'))` | Redirects to Transport Master with success flash |

#### CODE-TRACE-07: `destroy(Shift $shift)` — ShiftController.php:120-135

| Step # | Line(s) | Code | What It Does |
|--------|---------|------|-------------|
| 1 | 120 | `public function destroy(Shift $shift)` | Route-model-binding resolves `$shift`. SoftDeletes global scope excludes trashed — if shift already deleted, 404. |
| 2 | 122 | `Gate::authorize('tenant.shift.delete')` | Aborts with 403 if user lacks `tenant.shift.delete` permission |
| 3 | 124 | `$shift->is_active = false` | Sets model attribute `is_active` to `false` in memory |
| 4 | 125 | `$shift->save()` | Executes `UPDATE tpt_shift SET is_active = 0, updated_at = NOW() WHERE id = ?`. Persists the deactivation. **⚠️ No DB transaction — if next query fails, shift is deactivated but NOT deleted.** |
| 5 | 126 | `$shift->delete()` | Executes `UPDATE tpt_shift SET deleted_at = NOW() WHERE id = ?`. Soft-deletes the record. Sets `deleted_at` timestamp. |
| 6 | 128-131 | `activityLog($shift, 'Trashed', ['message' => 'Shift was deactivated and trashed.', 'performed_by' => Auth::user()->name])` | Logs truncation activity. Uses `performed_by` key. |
| 7 | 133-134 | `return redirect()->route('transport.transport-master.index')->with('success', flash('trashed.shift'))` | Redirects to Transport Master with success flash |

#### CODE-TRACE-08: `trashed()` — ShiftController.php:140-147

| Step # | Line(s) | Code | What It Does |
|--------|---------|------|-------------|
| 1 | 142 | `Gate::authorize('tenant.shift.restore')` | Aborts with 403 if user lacks `tenant.shift.restore` permission |
| 2 | 144 | `$shifts = Shift::onlyTrashed()->paginate(10)` | Executes `SELECT * FROM tpt_shift WHERE deleted_at IS NOT NULL LIMIT 10 OFFSET 0` + count query. Overrides SoftDeletes global scope to show ONLY deleted records. Paginated at 10 per page. **⚠️ No `->orderBy()` — order undefined.** |
| 3 | 146 | `return view('transport::shift.trash', compact('shifts'))` | Renders `resources/views/shift/trash.blade.php` with paginated trashed shifts |

#### CODE-TRACE-09: `restore($id)` — ShiftController.php:152-166

| Step # | Line(s) | Code | What It Does |
|--------|---------|------|-------------|
| 1 | 152 | `public function restore($id)` | Manual `$id` parameter (NOT route-model-binding) |
| 2 | 154 | `Gate::authorize('tenant.shift.restore')` | Aborts with 403 if user lacks `tenant.shift.restore` permission |
| 3 | 156 | `$shift = Shift::onlyTrashed()->findOrFail($id)` | Executes `SELECT * FROM tpt_shift WHERE id = ? AND deleted_at IS NOT NULL LIMIT 1`. Throws 404 if record not found or if it's already active (not trashed). |
| 4 | 157 | `$shift->restore()` | Executes `UPDATE tpt_shift SET deleted_at = NULL, updated_at = NOW() WHERE id = ?`. Clears `deleted_at`. **Does NOT change `is_active`** — restored shift stays inactive. |
| 5 | 159-162 | `activityLog($shift, 'Restored', ['message' => 'Shift was restored.', 'other' => 'Some other information'])` | Logs restore activity. Uses `other` key (inconsistent with destroy which uses `performed_by`). |
| 6 | 164-165 | `return redirect()->route('transport.shift.trashed')->with('success', flash('restored.shift'))` | Redirects TO trash page (not transport-master). Success flash. |

#### CODE-TRACE-10: `forceDelete($id)` — ShiftController.php:171-185

| Step # | Line(s) | Code | What It Does |
|--------|---------|------|-------------|
| 1 | 171 | `public function forceDelete($id)` | Manual `$id` parameter (NOT route-model-binding) |
| 2 | 173 | `Gate::authorize('tenant.shift.forceDelete')` | Aborts with 403 if user lacks `tenant.shift.forceDelete` permission |
| 3 | 175 | `$shift = Shift::withTrashed()->findOrFail($id)` | Executes `SELECT * FROM tpt_shift WHERE id = ? LIMIT 1` (NO `deleted_at` filter). Throws 404 if ID doesn't exist at all. **Finds BOTH active and trashed records.** |
| 4 | 176 | `$shift->forceDelete()` | Executes `DELETE FROM tpt_shift WHERE id = ?`. Permanently removes the row from the database. |
| 5 | 178-181 | `activityLog($shift, 'Deleted', ['message' => 'Shift was permanently deleted.', 'other' => 'Some other information'])` | Logs permanent deletion. Uses `other` key. |
| 6 | 183-184 | `return redirect()->route('transport.shift.trashed')->with('success', flash('force_deleted.shift'))` | Redirects TO trash page. Success flash. |

#### CODE-TRACE-11: `toggleStatus(Request $request, Shift $shift)` — ShiftController.php:190-217

| Step # | Line(s) | Code | What It Does |
|--------|---------|------|-------------|
| 1 | 190 | `public function toggleStatus(Request $request, Shift $shift)` | Route-model-binding resolves `$shift`. Uses plain `Request` (NOT `ShiftRequest`). SoftDeletes global scope excludes trashed — 404 if deleted. |
| 2 | 192 | `Gate::authorize('tenant.shift.update')` | Aborts with 403 if user lacks `tenant.shift.update` permission |
| 3 | 194-196 | `$request->validate(['is_active' => 'required|boolean'])` | Inline validation. Expects `is_active` in request body, must be boolean-like (1, 0, "true", "false"). On failure, throws `ValidationException` → JSON error response for AJAX. |
| 4 | 198 | `$shift->is_active = $request->is_active` | Sets model attribute. `$request->is_active` uses dynamic property → `$request->input('is_active')`. Value is raw input (e.g., "1", "0", true, false). Model cast `is_active => boolean` will handle conversion on save. |
| 5 | 200-203 | `activityLog($shift, 'Toggled', ['message' => 'Shift status was updated.', 'other' => 'Some other information'])` | Logs toggle activity **BEFORE** save. **⚠️ If save fails, log entry is orphaned.** Uses `other` key. |
| 6 | 205 | `if ($shift->save())` | Executes `UPDATE tpt_shift SET is_active = ?, updated_at = NOW() WHERE id = ?`. Returns `true` on success. |
| 7 | 206-210 | Success: `return response()->json(['success' => true, 'is_active' => $shift->is_active, 'message' => flash('status_updated.shift')])` | JSON success response. `is_active` is the model's value (cast to bool via model cast). |
| 8 | 213-216 | Failure: `return response()->json(['success' => false, 'message' => flash('status_switch_failed.shift')])` | JSON failure response. Note: both success and failure return HTTP 200. |

---

## 7. Detailed Test Steps

### TC-P-01: Create shift with valid data

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user with `tenant.shift.create` permission | Authenticated session |
| 2 | Navigate to Shift create page: GET `/transport/shift/create` | `Gate::authorize('tenant.shift.create')` passes, view `transport::shift.create` renders |
| 3 | Enter valid code "MORN" in code input (maxlength=10 enforced by browser) | Field shows "MORN" |
| 4 | Enter valid name "Morning Shift" in name input (maxlength=50 enforced by browser) | Field shows "Morning Shift" |
| 5 | Select `effective_from` date "2026-04-01" in date input | Field shows "2026-04-01" |
| 6 | Select `effective_to` date "2027-03-31" in date input | Field shows "2027-03-31" |
| 7 | Ensure `is_active` status-switch is ON (checked) | `old('is_active', true)` = true → switch renders as ON |
| 8 | Click "Add Shift" button | Form submits POST to `/transport/shift` |
| 9 | **Verify**: `ShiftRequest::prepareForValidation()` runs first | `is_active` normalized from 'on' → true (since checkbox checked) |
| 10 | **Verify**: `ShiftRequest::authorize()` for POST checks `Gate::allows('tenant.shift.create')` | Returns true |
| 11 | **Verify**: `ShiftRequest::rules()` validate: code required, string, max:20, unique; name required, string, max:100, unique; effective_from required, date; effective_to required, date, after:effective_from; is_active required, boolean | All pass |
| 12 | **Verify**: `Gate::authorize('tenant.shift.create')` at controller line 41 | Passes (second gate check) |
| 13 | **Verify**: `Shift::create($request->validated())` executes INSERT | `INSERT INTO tpt_shift (code, name, effective_from, effective_to, is_active, created_at, updated_at) VALUES ('MORN', 'Morning Shift', '2026-04-01', '2027-03-31', 1, NOW(), NOW())` |
| 14 | **Verify**: `activityLog($shift, 'Stored', ...)` records entry | Log type "Stored", message "A new shift was created." |
| 15 | **Verify**: Redirect to route `transport.transport-master.index` | HTTP 302 redirect |
| 16 | **Verify**: Flash message `flash('created.shift')` in session | Success message displayed on redirect |
| 17 | **Verify**: New shift "MORN" appears in Shift tab list | `Shift::paginate(10)` includes new record |

### TC-P-02: Create shift with minimum data

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user with `tenant.shift.create` permission | Authenticated |
| 2 | Navigate to Shift create page | Form loads |
| 3 | Enter code "MIN" and name "Min Shift" | Valid entries |
| 4 | Select effective_from = "2026-01-01" and effective_to = "2026-12-31" | Valid date range |
| 5 | Leave is_active at default (status-switch renders as checked by `:isActive="old('is_active', true)"`) | Switch ON |
| 6 | Click "Add Shift" | POST to `/transport/shift` |
| 7 | **Verify**: `prepareForValidation()` sees checkbox submitted as 'on' → `is_active = true` | Normalized to boolean true |
| 8 | **Verify**: `$request->validated()` includes `is_active = true` | Passes `required|boolean` |
| 9 | **Verify**: `Shift::create()` stores `is_active = 1` | DB has `is_active = 1` |
| 10 | **Verify**: Redirect with success | Flash "created.shift" |

### TC-P-03: Edit shift name (change tracking)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user with `tenant.shift.update` permission | Authenticated |
| 2 | Navigate to edit page: GET `/transport/shift/{MORN-ID}/edit` | `Gate::authorize('tenant.shift.update')` passes, `Shift::findOrFail(id)` finds record, edit form renders with current values |
| 3 | Change name from "Morning Shift" to "AM Shift" | Input updated |
| 4 | Click "Update Shift" | Form submits PUT to `/transport/shift/{MORN-ID}` |
| 5 | **Verify**: `ShiftRequest::authorize()` for non-POST checks `Gate::allows('tenant.shift.update')` | Passes |
| 6 | **Verify**: `$original = $shift->getOriginal()` captures `['name' => 'Morning Shift', 'code' => 'MORN', ...]` | Pre-update state saved |
| 7 | **Verify**: `$shift->update($request->validated())` | `UPDATE tpt_shift SET name = 'AM Shift', updated_at = NOW() WHERE id = ...` |
| 8 | **Verify**: `$changes = $shift->getChanges()` includes `['name' => 'AM Shift', 'updated_at' => '...']` | Changes detected |
| 9 | **Verify**: `$changedAttributes` built with old/new: `['name' => ['old' => 'Morning Shift', 'new' => 'AM Shift']]` | `updated_at` filtered out at line 92 |
| 10 | **Verify**: `activityLog(..., 'Updated', ['changes' => ['name' => ['old' => 'Morning Shift', 'new' => 'AM Shift']]])` | Logged with field-level detail |
| 11 | **Verify**: Redirect to `transport.transport-master.index` | 302 redirect |
| 12 | **Verify**: Flash `flash('updated.shift')` | Success message |

### TC-P-04: Edit shift date range

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user with `tenant.shift.update` permission | Authenticated |
| 2 | Navigate to edit page for shift with effective_to = "2027-03-31" | Form pre-filled |
| 3 | Change effective_to to "2027-04-30" (+30 days) | New date entered |
| 4 | Click "Update Shift" | PUT submitted |
| 5 | **Verify**: `$original['effective_to']` = "2027-03-31" | Original captured |
| 6 | **Verify**: `$changedAttributes['effective_to']['old']` = "2027-03-31", `$changedAttributes['effective_to']['new']` = "2027-04-30" | Change tracked |
| 7 | **Verify**: DB row has updated effective_to | `SELECT effective_to FROM tpt_shift` = "2027-04-30" |

### TC-P-05: Toggle shift active→inactive

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user with `tenant.shift.update` permission | Authenticated |
| 2 | Navigate to Transport Master → Shift tab | Tab loaded via `@include('transport::shift.index')` |
| 3 | Click status toggle on an active shift (is_active=1) | AJAX POST to `/transport/shift/{shift}/toggle-status` with body `{is_active: 0}` |
| 4 | **Verify**: `Gate::authorize('tenant.shift.update')` | 403 if unauthorized |
| 5 | **Verify**: `$request->validate(['is_active' => 'required|boolean'])` | Inline validation passes for `is_active=0` |
| 6 | **Verify**: `$shift->is_active = $request->is_active` | Model attribute set to 0 |
| 7 | **Verify**: `activityLog(..., 'Toggled', ...)` records BEFORE save | Log entry created |
| 8 | **Verify**: `$shift->save()` returns true | `UPDATE tpt_shift SET is_active = 0, updated_at = NOW() WHERE id = ?` |
| 9 | **Verify**: JSON response: `{success: true, is_active: false, message: flash('status_updated.shift')}` | 200 with success JSON |
| 10 | **Verify**: Toggle switch updates to OFF state | UI component reflects `is_active=0` |

### TC-P-06: Toggle shift inactive→active

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.shift.update` | Authenticated |
| 2 | Navigate to Shift tab with inactive shift visible | List shows inactive badge |
| 3 | Click status toggle on inactive shift (is_active=0) | AJAX POST with `{is_active: 1}` |
| 4 | **Verify**: Inline validation accepts `is_active=1` | Passes `required|boolean` |
| 5 | **Verify**: `$shift->is_active = 1` | Set to 1 |
| 6 | **Verify**: JSON response: `{success: true, is_active: true}` | Success |
| 7 | **Verify**: Toggle switches to ON | UI updated |

### TC-P-07: View shift details

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.shift.view` permission | Authenticated |
| 2 | Navigate to show page: GET `/transport/shift/{id}` | `Gate::authorize('tenant.shift.view')` passes |
| 3 | **Verify**: `Shift::findOrFail($id)` returns shift with all attributes | Model found |
| 4 | **Verify**: Show view renders with `transport::shift.show` | Full layout page |
| 5 | **Verify**: Code displayed in `<span class="badge badge-info">` | `$shift->code ?? '-'` |
| 6 | **Verify**: Effective From formatted as "01 Apr 2026" via `Carbon::parse()->format('d M Y')` | `show.blade.php:42` |
| 7 | **Verify**: Effective To formatted similarly | `show.blade.php:52` |
| 8 | **Verify**: Duration computed as `$from->diffInDays($to)` and shown as badge | e.g., "364 Days" |
| 9 | **Verify**: Status badge: Active (success) or Inactive (danger) | `show.blade.php:76-81` |
| 10 | **Verify**: Created At / Updated At shown as "d M Y, h:i A" | `show.blade.php:85,90` |
| 11 | **Verify**: Edit button visible only if `@can('tenant.shift.edit')` | Conditional rendering |

### TC-P-08: View shift list with pagination

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.shift.viewAny` | Authenticated |
| 2 | Navigate to Transport Master → Shift tab | Tab `shift-pane` active |
| 3 | Ensure at least 11 shifts exist in DB | More than one page |
| 4 | **Verify**: Index loads with `Shift::paginate(10)` | 10 items on page 1 |
| 5 | **Verify**: Pagination links rendered: `$shifts->appends(['tab' => request('tab', 'shift')])->links()` | Links include `?tab=shift` |
| 6 | Click page 2 pagination link | GET with `?page=2&tab=shift` |
| 7 | **Verify**: Remaining shifts displayed | Items 11-... shown |
| 8 | **Verify**: `?tab=shift` preserved in URL | Tab state maintained |

### TC-P-09: Edit shift without changing any field

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.shift.update` | Authenticated |
| 2 | Navigate to edit page for existing shift | Form pre-filled |
| 3 | Click "Update Shift" without changing any field | PUT submitted |
| 4 | **Verify**: `$original = $shift->getOriginal()` | Pre-update state |
| 5 | **Verify**: `$shift->update($request->validated())` executes | UPDATE runs (with same values) |
| 6 | **Verify**: `$changes = $shift->getChanges()` only has `['updated_at' => '...']` | Only timestamp changed |
| 7 | **Verify**: `$changedAttributes` is empty (updated_at filtered) | `empty($changedAttributes)` = true |
| 8 | **Verify**: `activityLog(..., 'Updated', ['message' => 'Shift updated. No attributes changed.'])` | "No attributes changed" path |
| 9 | **Verify**: Flash `flash('updated.shift')` | Success message (even though nothing changed) |

### TC-P-10: Create shift with same code as soft-deleted (unique ignores trashed)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create shift with code="MORN", name="Morning Shift" | Active shift created |
| 2 | Soft-delete this shift via destroy() | `is_active=0`, `deleted_at` set |
| 3 | Navigate to create page | Form loads |
| 4 | Enter code="MORN" (same as trashed), name="New Morning" | Input filled |
| 5 | Enter valid dates, is_active=ON | Form complete |
| 6 | Click "Add Shift" | POST to store |
| 7 | **Verify**: `Rule::unique('tpt_shift', 'code')->whereNull('deleted_at')` | Unique excludes trashed records → validation passes |
| 8 | **Verify**: New shift created with id=new_id, code="MORN" | INSERT succeeds |
| 9 | **Verify**: DB now has 2 records with code="MORN": one trashed, one active | `deleted_at` distinguishes them |

### TC-P-11: Create shift with max-length code (20 chars via API)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Prepare code = "ABCDEFGHIJ1234567890" (exactly 20 chars) | Valid per ShiftRequest max:20 |
| 2 | Submit POST to `/transport/shift` via API/Postman (bypass browser maxlength=10) | Request reaches server |
| 3 | **Verify**: `ShiftRequest::rules()`: `max:20` passes | 20 ≤ 20, valid |
| 4 | **Verify**: DDL `VARCHAR(20)` accepts the value | `$table->string('code', 20)` |
| 5 | **Verify**: Shift created successfully | INSERT succeeds |

### TC-P-12: Create shift with max-length name (100 chars via API)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Prepare name = 100-char string | Valid per ShiftRequest max:100 |
| 2 | Submit POST via API | Request reaches server |
| 3 | **Verify**: `max:100` passes | 100 ≤ 100, valid |
| 4 | **Verify**: DDL `VARCHAR(100)` accepts | `$table->string('name', 100)` |
| 5 | **Verify**: Shift created | INSERT succeeds |

### TC-P-13: Restore soft-deleted shift

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.shift.restore` permission | Authenticated |
| 2 | Navigate to trash: GET `/transport/shift/trash/view` | `Gate::authorize('tenant.shift.restore')` passes, trashed list loads |
| 3 | Ensure at least one trashed shift exists | Row visible with Action column |
| 4 | Click restore icon on a trashed shift | GET `/transport/shift/{id}/restore` |
| 5 | **Verify**: `Gate::authorize('tenant.shift.restore')` at controller line 154 | Passes |
| 6 | **Verify**: `Shift::onlyTrashed()->findOrFail($id)` at line 156 | `SELECT ... WHERE id = ? AND deleted_at IS NOT NULL` — finds record |
| 7 | **Verify**: `$shift->restore()` at line 157 | `UPDATE tpt_shift SET deleted_at = NULL, updated_at = NOW() WHERE id = ?` |
| 8 | **Verify**: `is_active` NOT changed by restore | `is_active` remains 0 (was set to false during destroy) |
| 9 | **Verify**: `activityLog(..., 'Restored', ...)` | Log type "Restored" |
| 10 | **Verify**: Redirect to `transport.shift.trashed` (line 164) | User stays on trash page |
| 11 | **Verify**: Flash `flash('restored.shift')` | Success message |
| 12 | **Verify**: Shift no longer in trash list | `onlyTrashed()` excludes restored record |
| 13 | **Verify**: `deleted_at` is NULL in DB | `SELECT deleted_at FROM tpt_shift WHERE id = ?` → NULL |

### TC-P-14: Delete shift (soft delete)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.shift.delete` permission | Authenticated |
| 2 | Navigate to Transport Master → Shift tab | List shows active shifts |
| 3 | Click delete icon on an active shift | DELETE request to `/transport/shift/{shift}` |
| 4 | **Verify**: Route-model-binding resolves `Shift $shift` | Shift found (not trashed) |
| 5 | **Verify**: `Gate::authorize('tenant.shift.delete')` | Passes |
| 6 | **Verify**: `$shift->is_active = false` | Attribute set in memory |
| 7 | **Verify**: `$shift->save()` | `UPDATE tpt_shift SET is_active = 0, updated_at = NOW() WHERE id = ?` |
| 8 | **Verify**: `$shift->delete()` | `UPDATE tpt_shift SET deleted_at = NOW() WHERE id = ?` (soft delete) |
| 9 | **Verify**: `activityLog(..., 'Trashed', ...)` | Log type "Trashed" |
| 10 | **Verify**: Redirect to `transport.transport-master.index` | Flash `flash('trashed.shift')` |
| 11 | **Verify**: DB has `is_active=0`, `deleted_at` IS NOT NULL | SELECT confirms both changes |

### TC-P-15: Force delete shift from trash

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.shift.forceDelete` permission | Authenticated |
| 2 | Navigate to trash: GET `/transport/shift/trash/view` | Trash list |
| 3 | Ensure at least one trashed shift exists | Row visible |
| 4 | Click force delete icon on a trashed shift | DELETE to `/transport/shift/{id}/force-delete` |
| 5 | **Verify**: `Gate::authorize('tenant.shift.forceDelete')` | Passes |
| 6 | **Verify**: `Shift::withTrashed()->findOrFail($id)` | `SELECT * FROM tpt_shift WHERE id = ?` — finds record regardless of deleted_at |
| 7 | **Verify**: `$shift->forceDelete()` | `DELETE FROM tpt_shift WHERE id = ?` — permanent delete |
| 8 | **Verify**: `activityLog(..., 'Deleted', ...)` | Log type "Deleted" |
| 9 | **Verify**: Redirect to `transport.shift.trashed` | Flash `flash('force_deleted.shift')` |
| 10 | **Verify**: Record gone from DB | `SELECT * FROM tpt_shift WHERE id = ?` → 0 rows |

### TC-P-16: View trashed shifts list

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.shift.restore` permission | Authenticated |
| 2 | Navigate to `/transport/shift/trash/view` | URL hits `trashed()` method |
| 3 | **Verify**: `Gate::authorize('tenant.shift.restore')` | Passes |
| 4 | **Verify**: `Shift::onlyTrashed()->paginate(10)` | Only soft-deleted records, 10 per page |
| 5 | **Verify**: Table shows: Code, Name, Effective From, Effective To, Action | `shift/trash.blade.php:16-22` |
| 6 | **Verify**: Action column visible only if `@canany(['tenant.shift.restore', 'tenant.shift.forceDelete'])` | Conditional actions |
| 7 | **Verify**: Pagination links do NOT append `tab` parameter | `$shifts->links()` (no appends) |

### TC-P-17: Force delete active (non-trashed) shift

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.shift.forceDelete` permission | Authenticated |
| 2 | Note an active shift ID (deleted_at IS NULL) | Active record |
| 3 | Send DELETE to `/transport/shift/{id}/force-delete` | Direct API call |
| 4 | **Verify**: `Shift::withTrashed()->findOrFail($id)` | Finds the active record (no deleted_at filter) |
| 5 | **Verify**: `$shift->forceDelete()` | Permanently deletes the active record |
| 6 | **Verify**: Record removed from DB | `SELECT` returns 0 rows |
| 7 | **Note**: Unlike `restore()` which uses `onlyTrashed()` and would 404, `forceDelete()` with `withTrashed()` can delete active records | Different behavior than restore |

### TC-P-18: Batch create multiple shifts sequentially

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Shift A: code="A", name="Shift A" | Success |
| 2 | Create Shift B: code="B", name="Shift B" | Success |
| 3 | Create Shift C: code="C", name="Shift C" | Success |
| 4 | **Verify**: All 3 exist in index list | `Shift::paginate(10)` returns all 3 |

### TC-P-19: View shift on last page of pagination

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure 12 shifts exist (2 pages: 10 + 2) | Pagination active |
| 2 | Navigate to transport-master?tab=shift&page=2 | Page 2 loads |
| 3 | **Verify**: 2 shifts displayed on page 2 | Remaining records shown |
| 4 | **Verify**: Pagination links preserved with `?tab=shift` | `appends(['tab' => ...])` works |

### TC-P-20: Toggle status via direct POST with JSON

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.shift.update` | Authenticated |
| 2 | Send POST to `/transport/shift/{shift}/toggle-status` with JSON body `{"is_active": 1}` and `Content-Type: application/json` | AJAX-style request |
| 3 | **Verify**: `$request->validate(['is_active' => 'required|boolean'])` passes for JSON boolean true | Valid |
| 4 | **Verify**: `$request->is_active` = true (from JSON) | Dynamic property resolves |
| 5 | **Verify**: `$shift->save()` returns true | DB updated |
| 6 | **Verify**: JSON response `{success: true, is_active: true}` | Success |

### TC-N-01: Create shift with empty code

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.shift.create` | Authenticated |
| 2 | Navigate to create page | Form loads |
| 3 | Leave code field empty | `code = ""` |
| 4 | Fill all other fields with valid data | Name, dates filled |
| 5 | Click "Add Shift" | POST submitted |
| 6 | **Verify**: `ShiftRequest::rules()`: `code` → `required` fails | "The code field is required." |
| 7 | **Verify**: Form re-displayed with error | Alert box listing error |
| 8 | **Verify**: No record created | DB unchanged |

### TC-N-02: Create shift with empty name

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login, navigate to create | Form loads |
| 2 | Fill code, leave name empty | `name = ""` |
| 3 | Fill dates, is_active | Form complete |
| 4 | Click "Add Shift" | POST submitted |
| 5 | **Verify**: `name` → `required` fails | "The name field is required." |
| 6 | **Verify**: No record created | DB unchanged |

### TC-N-03: Create shift with duplicate code

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Pre-create shift with code="MORN" | Existing record |
| 2 | Login, navigate to create | Form loads |
| 3 | Enter code="MORN" | Duplicate |
| 4 | Enter different name="Afternoon Shift" | Different name |
| 5 | Fill dates, is_active | Valid |
| 6 | Click "Add Shift" | POST |
| 7 | **Verify**: `Rule::unique('tpt_shift', 'code')->whereNull('deleted_at')` checks existing non-deleted records with code="MORN" | Found existing → validation fails |
| 8 | **Verify**: Error: "The code has already been taken." | Validation error |
| 9 | **Verify**: No duplicate created | DB unchanged |

### TC-N-04: Create shift with duplicate name

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Pre-create shift with name="Morning Shift" | Existing record |
| 2 | Login, navigate to create | Form loads |
| 3 | Enter code="AFTN" | Different code |
| 4 | Enter name="Morning Shift" | Duplicate name |
| 5 | Click "Add Shift" | POST |
| 6 | **Verify**: `Rule::unique('tpt_shift', 'name')->whereNull('deleted_at')` | finds existing → fails |
| 7 | **Verify**: Error: "The name has already been taken." | Validation error |

### TC-N-05: Create shift with end date before start date

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login, navigate to create | Form loads |
| 2 | Enter code="INVALID", name="Invalid Range" | Valid |
| 3 | Select effective_from = "2026-06-01" | Start date |
| 4 | Select effective_to = "2026-05-01" (before start) | End before start |
| 5 | Click "Add Shift" | POST |
| 6 | **Verify**: `effective_to` → `after:effective_from` rule fails | "2026-05-01" is not after "2026-06-01" |
| 7 | **Verify**: Error: "The effective to must be a date after effective from." | Validation error |
| 8 | **Verify**: Form not submitted, no record created | DB unchanged |

### TC-N-06: Create shift with invalid date format

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login, navigate to create | Form loads |
| 2 | Enter valid code, name | OK |
| 3 | Enter "abc" in effective_from | Invalid date |
| 4 | Enter valid effective_to | OK |
| 5 | Click "Add Shift" | POST |
| 6 | **Verify**: `effective_from` → `date` rule fails | "The effective from is not a valid date." |

### TC-N-07: Update shift with code exceeding 20 chars

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.shift.update` | Authenticated |
| 2 | Navigate to edit page | Form loads |
| 3 | Enter code of 21 characters (bypass browser maxlength via API/DevTools) | `code = "ABCDEFGHIJKLMNOPQRSTU"` (21) |
| 4 | Click "Update Shift" | PUT |
| 5 | **Verify**: `code` → `max:20` fails | "The code must not be greater than 20 characters." |

### TC-N-08: Update shift with name exceeding 100 chars

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login, navigate to edit | Form loads |
| 2 | Enter name of 101 characters (bypass browser maxlength) | `name = "...101 chars..."` |
| 3 | Click "Update Shift" | PUT |
| 4 | **Verify**: `name` → `max:100` fails | "The name must not be greater than 100 characters." |

### TC-N-09: Submit form without is_active checkbox

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login, navigate to create | Form loads |
| 2 | Ensure `is_active` status-switch is OFF (unchecked) | Checkbox not submitted with form |
| 3 | Fill all other fields | Valid |
| 4 | Click "Add Shift" | POST |
| 5 | **Verify**: `prepareForValidation()` runs: `$this->has('is_active')` = false → `$this->merge(['is_active' => false])` | `is_active` = false |
| 6 | **Verify**: `is_active` → `required|boolean` passes (false is valid boolean) | Validation OK |
| 7 | **Verify**: `Shift::create()` stores `is_active = 0` | DB has is_active=0 |

### TC-N-10: Access index without permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user WITHOUT `tenant.shift.viewAny` | User lacks permission |
| 2 | Navigate to Transport Master → Shift tab | `transportmaster.blade.php:36` includes shift/index.blade.php |
| 3 | Direct access to any shift URL | 403 Access Denied |
| 4 | **Verify**: `Gate::authorize('tenant.shift.viewAny')` at controller line 19 throws `AuthorizationException` | 403 Forbidden |

### TC-N-11: Access create without permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login without `tenant.shift.create` | No create permission |
| 2 | GET `/transport/shift/create` | 403 Forbidden |
| 3 | **Verify**: `Gate::authorize('tenant.shift.create')` at line 31 throws | AuthorizationException → 403 |

### TC-N-12: Access edit without permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login without `tenant.shift.update` | No update permission |
| 2 | GET `/transport/shift/{id}/edit` | 403 Forbidden |
| 3 | **Verify**: `Gate::authorize('tenant.shift.update')` at line 71 | AuthorizationException |

### TC-N-13: Attempt delete without permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login without `tenant.shift.delete` | No delete permission |
| 2 | DELETE `/transport/shift/{shift}` | 403 Forbidden |
| 3 | **Verify**: `Gate::authorize('tenant.shift.delete')` at line 122 | AuthorizationException |

### TC-N-14: Attempt restore without permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login without `tenant.shift.restore` | No restore permission |
| 2 | GET `/transport/shift/{id}/restore` | 403 Forbidden |
| 3 | **Verify**: `Gate::authorize('tenant.shift.restore')` at line 154 | AuthorizationException |

### TC-N-15: Attempt forceDelete without permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login without `tenant.shift.forceDelete` | No forceDelete permission |
| 2 | DELETE `/transport/shift/{id}/force-delete` | 403 Forbidden |
| 3 | **Verify**: `Gate::authorize('tenant.shift.forceDelete')` at line 173 | AuthorizationException |

### TC-N-16: Save with phantom fields via direct model call (GAP)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a script that calls `Shift::create(['code'=>'TEST','name'=>'Test','effective_from'=>'2026-01-01','effective_to'=>'2026-12-31','description'=>'test','default_start_time'=>'09:00:00','default_end_time'=>'17:00:00','ordinal'=>1])` | Direct model call with phantom fields |
| 2 | **Verify**: Model `$fillable` includes `description`, `default_start_time`, `default_end_time`, `ordinal` | These fields pass mass-assignment |
| 3 | **Verify**: Migration DDL does NOT have these columns | Columns absent |
| 4 | **Verify**: SQL error thrown by MySQL | `Column not found: 1054 Unknown column 'description'` |
| 5 | **Impact**: Any code path that sets these fields causes 500 error | **CRITICAL GAP** |

### TC-N-17: Access show without permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login without `tenant.shift.view` | No view permission |
| 2 | GET `/transport/shift/{id}` | 403 Forbidden |
| 3 | **Verify**: `Gate::authorize('tenant.shift.view')` at line 59 | AuthorizationException |

### TC-N-18: Submit store (POST) without permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login without `tenant.shift.create` | No create permission |
| 2 | POST `/transport/shift` with valid data | Request hits controller |
| 3 | **Verify**: `ShiftRequest::authorize()` runs FIRST, returns `Gate::allows('tenant.shift.create')` = false | AuthorizationException thrown by FormRequest (before controller body) |
| 4 | **Verify**: 403 response returned | "This action is unauthorized." |

### TC-N-19: Submit update (PUT) without permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login without `tenant.shift.update` | No update permission |
| 2 | PUT `/transport/shift/{shift}` with valid data | Request hits controller |
| 3 | **Verify**: `ShiftRequest::authorize()` for non-POST returns `Gate::allows('tenant.shift.update')` = false | 403 before controller body |

### TC-N-20: Toggle status without permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login without `tenant.shift.update` | No update permission |
| 2 | POST `/transport/shift/{shift}/toggle-status` with `{is_active: 1}` | Request hits controller |
| 3 | **Verify**: `Gate::authorize('tenant.shift.update')` at line 192 | 403 AuthorizationException |

### TC-N-21: Access trash page without permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login without `tenant.shift.restore` | No restore permission |
| 2 | GET `/transport/shift/trash/view` | 403 Forbidden |
| 3 | **Verify**: `Gate::authorize('tenant.shift.restore')` at line 142 | AuthorizationException |

### TC-N-22: Update with code exceeding 20 chars via API

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send PUT with `code = "ABCDEFGHIJKLMNOPQRSTU"` (21 chars) | API request |
| 2 | **Verify**: `max:20` validation fails | "The code must not be greater than 20 characters." |

### TC-N-23: Update with name exceeding 100 chars via API

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send PUT with 101-char name | API request |
| 2 | **Verify**: `max:100` validation fails | "The name must not be greater than 100 characters." |

### TC-N-24: Create shift with existing soft-deleted same name

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create shift with name="Unique Name" | Active |
| 2 | Soft-delete this shift | Trashed |
| 3 | Create new shift with name="Unique Name" | POST |
| 4 | **Verify**: `Rule::unique('tpt_shift', 'name')->whereNull('deleted_at')` | Trashed record excluded → validation passes |
| 5 | **Verify**: New shift created with same name | DB has two "Unique Name" records: one trashed, one active |

### TC-D-01: Delete shift with active routes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure shift has at least one route assigned (via `routes()` relationship) | `tpt_route` has rows with this `shift_id` |
| 2 | Login with `tenant.shift.delete` | Authenticated |
| 3 | Delete the shift | destroy() called |
| 4 | **Verify**: Shift `is_active=0` and `deleted_at` is set | `UPDATE tpt_shift SET is_active=0; UPDATE tpt_shift SET deleted_at=NOW()` |
| 5 | **Verify**: Routes still exist in `tpt_route` with same `shift_id` | Soft-delete does NOT cascade to related models |
| 6 | **Verify**: Routes now reference a soft-deleted shift | `routes()->get()` still returns routes (FK still valid) |

### TC-D-02: Restore shift that had routes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Shift that was soft-deleted in TC-D-01 | Has routes in `tpt_route` |
| 2 | Restore the shift | `$shift->restore()` |
| 3 | **Verify**: `deleted_at` = NULL | Cleared |
| 4 | **Verify**: `is_active` = 0 (not restored) | Inactive |
| 5 | **Verify**: Routes still associated | `$shift->routes` returns same Routes collection |

### TC-D-03: Force delete shift

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete a shift (if not already) | `deleted_at` set |
| 2 | Force delete it | `forceDelete()` |
| 3 | **Verify**: Record removed from `tpt_shift` | `SELECT * FROM tpt_shift WHERE id = ?` → 0 rows |
| 4 | **Verify**: Activity log has "Deleted" entry | `activityLog(..., 'Deleted', ...)` |

### TC-D-04: Verify is_active=false before soft-delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Note shift ID with `is_active=1` | Active shift |
| 2 | Call destroy() on this shift | `$shift->is_active = false; $shift->save(); $shift->delete()` |
| 3 | Query DB: `SELECT is_active, deleted_at FROM tpt_shift WHERE id = ?` | `is_active = 0`, `deleted_at` IS NOT NULL |
| 4 | **Verify**: Both changes applied atomically (though no transaction) | Both queries executed |

### TC-D-05: Verify restore does not reset is_active

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Take the shift from TC-D-04 (is_active=0, deleted_at set) | Trashed and inactive |
| 2 | Restore it | `$shift->restore()` |
| 3 | Query DB: `SELECT is_active, deleted_at FROM tpt_shift WHERE id = ?` | `is_active = 0`, `deleted_at` IS NULL |
| 4 | **Verify**: Only `deleted_at` cleared, `is_active` unchanged | Restore does NOT set is_active=true |

### TC-D-06: Duplicate code creation after force-delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create shift with code="TEMP" | Active |
| 2 | Force-delete this shift | Permanently removed |
| 3 | Create new shift with code="TEMP" | POST |
| 4 | **Verify**: No trashed record with code="TEMP" exists (deleted permanently) | Unique check finds no conflicts |
| 5 | **Verify**: New shift created | Success |

### TC-D-07: Verify unique constraint excludes soft-deleted

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Run SQL: `SELECT COUNT(*) FROM tpt_shift WHERE code = 'MORN' AND deleted_at IS NULL` | Count of non-deleted duplicates |
| 2 | The `Rule::unique('tpt_shift', 'code')->whereNull('deleted_at')` uses the same WHERE clause | Consistent with SQL |
| 3 | Soft-deleted records are excluded from unique check | Confirmed |

### TC-D-08/09: DB column vs validation consistency

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check DDL: `$table->string('code', 20)` | VARCHAR(20) |
| 2 | Check Request: `max:20` | Matches DB |
| 3 | Check DDL: `$table->string('name', 100)` | VARCHAR(100) |
| 4 | Check Request: `max:100` | Matches DB |
| 5 | **Verify**: Code and Name length validation consistent with DDL | Consistent |

### TC-D-10: Phantom columns GAP

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `Shift.php:15-25` | `$fillable = ['code','name','description','effective_from','effective_to','default_start_time','default_end_time','ordinal','is_active']` |
| 2 | Compare with migration `2026_06_16_140603_create_tpt_shift_table.php:15-27` | Columns: `id`, `code`, `name`, `effective_from`, `effective_to`, `is_active`, `timestamps`, `softDeletes` |
| 3 | **Verify**: `description`, `default_start_time`, `default_end_time`, `ordinal` are in `$fillable` but NOT in migration | **CRITICAL GAP** |
| 4 | **Verify**: `$casts` references `default_start_time` and `default_end_time` as `datetime:H:i:s` | Phantom casts on non-existent columns |
| 5 | **Impact**: Any code path that sets these fields causes SQL "column not found" error | 500 error |

### TC-D-11: Force delete shift with active routes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure shift has routes in `tpt_route` with `shift_id` pointing to it | Dependent records exist |
| 2 | Force-delete the shift | `$shift->forceDelete()` → `DELETE FROM tpt_shift WHERE id = ?` |
| 3 | **Verify**: Shift record removed | SELECT returns 0 |
| 4 | **Verify**: Routes still exist with old `shift_id` | `SELECT * FROM tpt_route WHERE shift_id = ?` returns rows (FK CASCADE does NOT trigger because DELETE is on tpt_shift, not tpt_route) |
| 5 | **Note**: The ON DELETE CASCADE in related tables' FKs SHOULD cascade. Verify FK definition: if `$table->foreign('shift_id')->references('id')->on('tpt_shift')->onDelete('cascade')`, then route rows ARE deleted. If not, they become orphaned. | Check migration DDL for related tables |

### TC-D-12: Verify toggleStatus() persists to DB

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check current `is_active` for a shift: `1` | Active |
| 2 | Send toggleStatus with `is_active: 0` | POST |
| 3 | Query DB: `SELECT is_active FROM tpt_shift WHERE id = ?` | `0` |
| 4 | Send toggleStatus with `is_active: 1` | POST |
| 5 | Query DB: `SELECT is_active FROM tpt_shift WHERE id = ?` | `1` |

### TC-D-13: Verify update() change tracking accuracy

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Note current shift name = "Original", code = "CODE1" | Two fields |
| 2 | Update only the name to "Modified" | PUT with name changed, code unchanged |
| 3 | **Verify**: `$changedAttributes` has exactly one entry: `['name' => ['old' => 'Original', 'new' => 'Modified']]` | Only changed field tracked |
| 4 | **Verify**: `code` NOT in `$changedAttributes` | Unchanged fields excluded |

### TC-D-14: Verify updated_at excluded from change log

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Update any field on a shift | PUT |
| 2 | **Verify**: `$changes = $shift->getChanges()` includes `['updated_at' => '...', 'name' => '...']` | updated_at present in raw changes |
| 3 | **Verify**: `$changedAttributes` does NOT include `updated_at` | `if ($field === 'updated_at') continue;` at line 92 |

### TC-D-15: Verify no change = "No attributes changed" message

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit update form with NO field changes | PUT with identical values |
| 2 | **Verify**: `$changedAttributes` is empty | No fields changed except updated_at |
| 3 | **Verify**: `activityLog` message = "Shift updated. No attributes changed." | Fallback path at line 107 |

### TC-D-16: Verify prepareForValidation() normalizes correctly

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit create form with checkbox ON | `is_active` sent as "on" |
| 2 | **Verify**: `prepareForValidation()`: `$this->has('is_active')` = true, `$this->input('is_active')` = "on" → merged value = true | `true` |
| 3 | Submit create form with checkbox OFF | `is_active` not sent |
| 4 | **Verify**: `$this->has('is_active')` = false → merged value = false | `false` |

### TC-D-17: Verify trashed list excludes active records

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure at least 1 active and 1 trashed shift exist | Both types present |
| 2 | Navigate to `/transport/shift/trash/view` | `trashed()` method |
| 3 | **Verify**: `Shift::onlyTrashed()->paginate(10)` | Query has `WHERE deleted_at IS NOT NULL` |
| 4 | **Verify**: Active shifts NOT in trash list | Only soft-deleted records shown |

### TC-CR-01: Verify Gate in index()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `ShiftController.php:19` | `Gate::authorize('tenant.shift.viewAny')` |
| 2 | Test as user without permission | 403 thrown before query executes |

### TC-CR-02 through TC-CR-11: Verify Gate calls

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Verify each controller method has `Gate::authorize()` call | All 11 methods covered |
| 2 | Cross-reference each permission against ShiftPolicy | All 7 active permissions mapped correctly |
| 3 | `import`, `export`, `print` permissions exist in Policy but are never called in controller | Dead policy methods |

### TC-CR-12 through TC-CR-18: Verify activityLog calls

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check `store()`: `activityLog($shift, 'Stored', ['message' => 'A new shift was created.', 'other' => 'Some other information'])` | Present at line 45-48 |
| 2 | Check `update()`: `activityLog($shift, 'Updated', ...)` with changes | Present at line 100-105 |
| 3 | Check `update()`: `activityLog($shift, 'Updated', ...)` without changes | Present at line 106-110 |
| 4 | Check `destroy()`: `activityLog($shift, 'Trashed', ...)` | Present at line 128-131 |
| 5 | Check `restore()`: `activityLog($shift, 'Restored', ...)` | Present at line 159-162 |
| 6 | Check `forceDelete()`: `activityLog($shift, 'Deleted', ...)` | Present at line 178-181 |
| 7 | Check `toggleStatus()`: `activityLog($shift, 'Toggled', ...)` | Present at line 200-203 |

### TC-CR-19: Verify update() change tracking (getOriginal + getChanges)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `ShiftController.php:85-98` | Code block that captures original state, performs update, builds changes array |
| 2 | **Verify**: `$original = $shift->getOriginal()` at line 85 | Captures attribute values BEFORE the update query |
| 3 | **Verify**: `$shift->update($request->validated())` at line 86 | Executes UPDATE query |
| 4 | **Verify**: `$changes = $shift->getChanges()` at line 88 | Returns array of changed fields with new values only |
| 5 | **Verify**: `if ($field === 'updated_at') continue;` at line 92 | `updated_at` excluded from tracked changes |
| 6 | **Verify**: `$changedAttributes[$field] = ['old' => $original[$field] ?? null, 'new' => $newValue]` at lines 94-97 | Old/new structure uses null coalescing |
| 7 | **Test**: Update name from "Morning" to "Evening" | `$changedAttributes = ['name' => ['old' => 'Morning', 'new' => 'Evening']]` |

### TC-CR-20: Verify destroy() deactivation-before-delete sequence

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `ShiftController.php:124-126` | `$shift->is_active = false; $shift->save(); $shift->delete();` |
| 2 | **Verify**: `is_active = false` set before save | Model attribute changed in memory |
| 3 | **Verify**: `$shift->save()` writes to DB | `UPDATE tpt_shift SET is_active = 0, updated_at = NOW()` |
| 4 | **Verify**: `$shift->delete()` soft-deletes | `UPDATE tpt_shift SET deleted_at = NOW()` |
| 5 | **Test**: Call destroy on active shift, then query DB | `is_active=0`, `deleted_at` IS NOT NULL |

### TC-CR-21: Verify onlyTrashed() in trashed()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `ShiftController.php:144` | `Shift::onlyTrashed()->paginate(10)` |
| 2 | **Verify**: `onlyTrashed()` overrides SoftDeletes global scope | Query includes `WHERE deleted_at IS NOT NULL` |
| 3 | **Verify**: `paginate(10)` limits results | 10 per page |
| 4 | **Note**: No `->orderBy()` call | Order undefined |

### TC-CR-22: Verify onlyTrashed() in restore()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `ShiftController.php:156` | `Shift::onlyTrashed()->findOrFail($id)` |
| 2 | **Verify**: `onlyTrashed()` → only finds soft-deleted records | Active records cause 404 |
| 3 | **Verify**: `findOrFail()` → 404 if not found | `ModelNotFoundException` |
| 4 | **Test**: Call restore with active-shift ID → 404 | Correct behavior |

### TC-CR-23: Verify withTrashed() in forceDelete()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `ShiftController.php:175` | `Shift::withTrashed()->findOrFail($id)` |
| 2 | **Verify**: `withTrashed()` — NO `deleted_at` filter | Finds both active and trashed records |
| 3 | **Verify**: Differs from `restore()` which uses `onlyTrashed()` | `forceDelete` can delete active records, `restore` cannot restore active ones |

### TC-CR-24 through TC-CR-26: Verify toggleStatus validation and response

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `ShiftController.php:194-196` | `$request->validate(['is_active' => 'required|boolean'])` |
| 2 | **Verify**: Inline validation (not using FormRequest) | Plain `Request` type-hint, not `ShiftRequest` |
| 3 | Open `ShiftController.php:205-210` | Success: JSON with `success: true`, `is_active`, `message` |
| 4 | Open `ShiftController.php:213-216` | Failure: JSON with `success: false`, `message` only |
| 5 | **Verify**: Both paths return HTTP 200 (not 4xx/5xx for failure) | Frontend must distinguish by `success` flag |

### TC-CR-27 through TC-CR-28: Verify ShiftRequest authorize

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `ShiftRequest.php:16-17` | POST: `return Gate::allows('tenant.shift.create')` |
| 2 | Open `ShiftRequest.php:19` | Non-POST: `return Gate::allows('tenant.shift.update')` |
| 3 | **Verify**: No `view` guard in FormRequest (uses controller Gate for view) | Authorization split across FormRequest and controller |
| 4 | **Test**: POST without create permission → 403 | FormRequest throws before controller body |

### TC-CR-29: Verify prepareForValidation checkbox normalization

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `ShiftRequest.php:71-75` | `$this->has('is_active') && $this->input('is_active') === 'on'` |
| 2 | **Verify**: Checkbox checked → `has('is_active')` = true, `input('is_active')` = "on" → merged true | `is_active` = true |
| 3 | **Verify**: Checkbox unchecked → `has('is_active')` = false → merged false | `is_active` = false |

### TC-CR-30 through TC-CR-31: Verify redirect routes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `ShiftController.php:50` | `redirect()->route('transport.transport-master.index')` — after store |
| 2 | Open `ShiftController.php:113` | Same redirect — after update |
| 3 | Open `ShiftController.php:133` | Same redirect — after destroy |
| 4 | Open `ShiftController.php:164` | `redirect()->route('transport.shift.trashed')` — after restore |
| 5 | Open `ShiftController.php:183` | Same redirect — after forceDelete |
| 6 | **Verify**: Store/update/destroy → Transport Master, restore/forceDelete → Trash | Two different redirect targets |

### TC-CR-32 through TC-CR-34: Verify Blade conditional rendering

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `shift/show.blade.php:15` | `@can('tenant.shift.edit')` gates the Edit button |
| 2 | Open `shift/index.blade.php:46,70` | `@canany(['tenant.shift.edit', 'tenant.shift.delete'])` gates entire Action column |
| 3 | Open `shift/trash.blade.php:20,32` | `@canany(['tenant.shift.restore', 'tenant.shift.forceDelete'])` gates trash Action column |
| 4 | **Verify**: Consistent `@can` / `@canany` pattern | Authorization checks at view level |

### TC-CR-35 through TC-CR-38: Verify Flash keys and tab preservation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Search `ShiftController.php` for `flash(` | 7 calls: `created.shift`, `updated.shift`, `trashed.shift`, `restored.shift`, `force_deleted.shift`, `status_updated.shift`, `status_switch_failed.shift` |
| 2 | Open `shift/index.blade.php:9` | `<input type="hidden" name="tab" value="shift">` preserves tab in search form |
| 3 | Open `shift/index.blade.php:88` | `$shifts->appends(['tab' => request('tab', 'shift')])` preserves tab in pagination |
| 4 | Open `shift/index.blade.php:13-17` | Status filter dropdown with "All"/"Active"/"Inactive" options |

### TC-CR-39 through TC-CR-40: Verify maxlength discrepancies

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `shift/create.blade.php:37` | `maxlength="10"` on code input |
| 2 | Open `shift/edit.blade.php:35` | `maxlength="10"` on code input |
| 3 | Open `ShiftRequest.php:33` | `max:20` validation rule |
| 4 | Open DDL migration line 16 | `$table->string('code', 20)` |
| 5 | **Discrepancy**: Frontend = 10, Backend = 20, DDL = 20 | Characters 11-20 blocked by browser but accepted by server |
| 6 | Open `shift/create.blade.php:51` | `maxlength="50"` on name input |
| 7 | Open `shift/edit.blade.php:42` | `maxlength="50"` on name input |
| 8 | Open `ShiftRequest.php:43` | `max:100` validation rule |
| 9 | Open DDL migration line 17 | `$table->string('name', 100)` |
| 10 | **Discrepancy**: Frontend = 50, Backend = 100, DDL = 100 | Characters 51-100 blocked by browser but accepted by server |

### TC-CR-41 through TC-CR-42: Verify show view computed fields and timestamps

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `shift/show.blade.php:62-66` | `$from->diffInDays($to)` — Duration computed in days |
| 2 | Open `shift/show.blade.php:84-92` | `$shift->created_at->format('d M Y, h:i A')` and `$shift->updated_at->format('d M Y, h:i A')` |
| 3 | **Verify**: Duration is computed, not stored | No DB column for duration |

### TC-CR-43 through TC-CR-46: Verify Model definitions

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `Shift.php:15-25` | `$fillable = ['code','name','description','effective_from','effective_to','default_start_time','default_end_time','ordinal','is_active']` — **4 phantom fields** |
| 2 | Open `Shift.php:27-33` | `$casts` has 5 entries: `effective_from=>date`, `effective_to=>date`, `default_start_time=>datetime:H:i:s` (phantom), `default_end_time=>datetime:H:i:s` (phantom), `is_active=>boolean` |
| 3 | Open `Shift.php:36-39` | `scopeActive($query) { return $query->where('is_active', true); }` — defined but NEVER used in controller |
| 4 | Open `Shift.php:42-45` | `return $this->hasMany(Route::class, 'shift_id')` — relationship defined |
| 5 | **Verify**: SoftDeletes trait used | `use HasFactory, SoftDeletes;` at line 11 |

### TC-CR-47: Verify route definitions

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `routes/web.php:113-117` | `Route::resource('shift', ShiftController::class);` + 4 extra routes |
| 2 | **Verify**: Extra routes: `trashed` (GET), `restore` (GET), `forceDelete` (DELETE), `toggleStatus` (POST) | All registered |
| 3 | **Verify**: Route naming: `transport.shift.*` prefix | All routes under `transport.shift` namespace |

### TC-CR-48 through TC-CR-50: Verify validated() usage

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `ShiftController.php:43` | `Shift::create($request->validated())` — uses validated data only |
| 2 | Open `ShiftController.php:86` | `$shift->update($request->validated())` — uses validated data only |
| 3 | **Verify**: No raw `$request->input()` or `$request->all()` used in create/update | Safe from mass-assignment |

### TC-CR-51: Verify route model binding inconsistency

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open controller methods signatures | `update(ShiftRequest $request, Shift $shift)` — route binding |
| 2 | Open controller methods signatures | `destroy(Shift $shift)` — route binding |
| 3 | Open controller methods signatures | `toggleStatus(Request $request, Shift $shift)` — route binding |
| 4 | Open controller methods signatures | `show($id)` — manual ID |
| 5 | Open controller methods signatures | `edit($id)` — manual ID |
| 6 | Open controller methods signatures | `restore($id)` — manual ID |
| 7 | Open controller methods signatures | `forceDelete($id)` — manual ID |
| 8 | **Verify**: Inconsistent pattern — 3 use route binding, 4 use manual `$id` | Mixed approach |

### TC-CR-52: Verify restore does not reset is_active

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `ShiftController.php:156-157` | `$shift = Shift::onlyTrashed()->findOrFail($id); $shift->restore();` |
| 2 | **Verify**: No `$shift->is_active = true` before or after restore | `is_active` remains as-was (0 from destroy) |
| 3 | **Test**: Restore trashed shift → `SELECT is_active` returns 0 | Confirmed |

### TC-CR-53: GAP — index() ignores search and status filters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `ShiftController.php:17-24` | `index()` has NO `$request` parameter |
| 2 | Open `shift/index.blade.php:10-17` | Search input (`name="search"`) and Status select (`name="status"`) submit query params |
| 3 | **GAP**: URL loads as `/transport/transport-master?tab=shift&search=MORN&status=1` | Controller ignores all params |
| 4 | **Impact**: Search and status filter are decorative — do NOT filter results | All shifts always displayed |
| 5 | **Fix needed**: Add `$request` param to `index()`, add `where()` / `when()` clauses for search and status | `Shift::paginate(10)` → `Shift::when($request->search, fn...)->when($request->status, fn...)->paginate(10)` |

### TC-CR-54: GAP — Inconsistent activityLog keys

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `ShiftController.php:47` | `store()`: `'other' => 'Some other information'` |
| 2 | Open `ShiftController.php:130` | `destroy()`: `'performed_by' => Auth::user()->name` |
| 3 | Open `ShiftController.php:161` | `restore()`: `'other' => 'Some other information'` |
| 4 | Open `ShiftController.php:180` | `forceDelete()`: `'other' => 'Some other information'` |
| 5 | Open `ShiftController.php:202` | `toggleStatus()`: `'other' => 'Some other information'` |
| 6 | **GAP**: `destroy()` uses `performed_by` while others use `other` key with placeholder text | Inconsistent audit data — some entries record who, others don't |

### TC-CR-55: GAP — update() changes path missing performed_by

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `ShiftController.php:101-104` | Changes path: `'performed_by'` is NOT included |
| 2 | Open `ShiftController.php:107-109` | No-changes path: `'performed_by' => Auth::user()->name` IS included |
| 3 | **GAP**: When actual changes are made, `performed_by` is missing from activity log | Inconsistent — the no-changes path has MORE data than the changes path |

### TC-CR-56: GAP — toggleStatus logs before save

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `ShiftController.php:200-205` | `activityLog()` at line 200, `$shift->save()` at line 205 |
| 2 | **GAP**: Activity log is written BEFORE DB persistence | If save fails, log entry is orphaned — records a toggle that didn't happen |
| 3 | **Fix**: Move activityLog AFTER `$shift->save()` success check | Log only on successful save |

### TC-CR-57: GAP — destroy() no DB transaction

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `ShiftController.php:124-126` | `$shift->save()` (is_active=false) then `$shift->delete()` |
| 2 | **GAP**: No `DB::beginTransaction()` / `DB::commit()` wrapping | These are two separate UPDATE queries |
| 3 | **Risk**: If `save()` succeeds but `delete()` fails (e.g., FK constraint), shift is deactivated but NOT deleted | Inconsistent state: `is_active=0` but `deleted_at=NULL` |
| 4 | **Fix**: Wrap in `DB::transaction()` | Both queries succeed or both roll back |

### TC-CR-58: GAP — No ordering in index/trashed queries

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `ShiftController.php:21` | `Shift::paginate(10)` — no `->orderBy()` |
| 2 | Open `ShiftController.php:144` | `Shift::onlyTrashed()->paginate(10)` — no `->orderBy()` |
| 3 | **GAP**: No explicit ordering — results order depends on DB default (typically PK order, but not guaranteed) | Inconsistent list order across refreshes |
| 4 | **Fix**: Add `->orderBy('created_at', 'desc')` or `->orderBy('code')` | Predictable ordering |

### TC-CR-59: GAP — edit form unnecessary enctype

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `shift/edit.blade.php:26` | `enctype="multipart/form-data"` attribute on form |
| 2 | Review all form inputs in edit.blade.php | No file input fields exist |
| 3 | **GAP**: `multipart/form-data` encoding is unnecessary | Only needed when form contains `<input type="file">` |
| 4 | Compare with `shift/create.blade.php:25` | Create form does NOT have `enctype` — correct |
| 5 | **Impact**: Negligible — minor performance overhead | No functional impact |

### TC-CR-60: GAP — Redundant Carbon::parse in index.blade.php

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `shift/index.blade.php:58` | `\Carbon\Carbon::parse($shift->effective_from)->format('d-m-Y')` |
| 2 | Open `Shift.php:28` | `'effective_from' => 'date'` cast — model attribute is already a Carbon instance |
| 3 | **GAP**: `Carbon::parse()` on a Carbon object is redundant | `Carbon::parse()` returns a clone, but the format works either way |
| 4 | Compare with `shift/trash.blade.php:30` | Trash blade uses `$shift->effective_from?->format('d-m-Y')` directly — more efficient |
| 5 | **Fix**: Change to `$shift->effective_from->format('d-m-Y')` | Matches trash blade pattern |

### TC-CR-61: GAP — destroy() with trashed shift (route binding 404)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete a shift (already deleted) | `deleted_at` set |
| 2 | Call destroy() on the same shift again | Route-model-binding `Shift $shift` with SoftDeletes global scope → 404 |
| 3 | **GAP**: User cannot re-delete an already-trashed shift | `destroy()` uses route binding which excludes trashed records |
| 4 | **Note**: This is actually correct behavior — prevents double-delete | But differs from `restore()` and `forceDelete()` which use manual `$id` lookup |

### TC-CR-62: GAP — edit form uses different component pattern from create

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Compare `shift/create.blade.php:34-37` | Raw `<input type="text" name="code" ...>` with manual error display |
| 2 | Compare `shift/edit.blade.php:34-36` | `<x-backend.form.input-text type="text" name="code" ...>` component |
| 3 | **GAP**: Create form uses raw HTML, Edit form uses blade component | Inconsistent template patterns — maintenance burden, different behavior |
| 4 | **Impact**: Create form may not have same styling/features as component | e.g., error classes may differ |

### TC-CR-63: GAP — toggleStatus does NOT check if request has `is_active`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `ShiftController.php:198` | `$shift->is_active = $request->is_active` — no null check |
| 2 | **Verify**: `$request->validate(['is_active' => 'required|boolean'])` at line 194-196 | Validation ensures `is_active` is present |
| 3 | **Test**: Send toggleStatus without `is_active` key | `ValidationException` with "The is_active field is required." returned as JSON |
| 4 | **Note**: Inline validation catches this, but if validation was bypassed, `$request->is_active` = null | Model cast would convert null to false |

### TC-CR-64: GAP — No eager loading on routes relationship in show()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `ShiftController.php:61` | `Shift::findOrFail($id)` — no `->with('routes')` |
| 2 | Open `shift/show.blade.php` | Check if `$shift->routes` is accessed anywhere |
| 3 | **Verify**: show.blade.php does NOT iterate `$shift->routes` | No N+1 issue in current view |
| 4 | **Note**: If view is modified later to show route count, N+1 will occur | Lazily loaded |

### TC-CR-65: GAP — Controller imports `Auth` facade but 7 methods don't use it

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `ShiftController.php:7` | `use Illuminate\Support\Facades\Auth;` |
| 2 | Search controller for `Auth::` usage | Only used in `update()` lines 104,109 and `destroy()` line 130 |
| 3 | **Note**: `Auth::user()->name` used in activity logs | 8 other methods import Auth but don't use it — dead import in those methods |

---

## 8. Summary of Gaps and Defects

| ID | Severity | Category | Description | Location | Fix Recommendation |
|----|----------|----------|-------------|----------|-------------------|
| GAP-01 | **HIGH** | Data Integrity | Model `$fillable` has 4 phantom columns (`description`, `default_start_time`, `default_end_time`, `ordinal`) not present in DDL | `Shift.php:15-25` | Remove phantom fields from `$fillable` and `$casts`, or add columns to migration |
| GAP-02 | **HIGH** | Functionality | `index()` ignores `search` and `status` query params — search/filter UI is decorative | `ShiftController.php:17-24` | Add `$request` parameter and implement filtering logic |
| GAP-03 | **MEDIUM** | Consistency | `activityLog()` uses inconsistent key names: `other` vs `performed_by` across methods | `ShiftController.php:47,130,161,180,202` | Standardize all activityLog calls to use same structure |
| GAP-04 | **MEDIUM** | Consistency | `update()` changes path missing `performed_by` but no-changes path includes it | `ShiftController.php:101-109` | Add `performed_by` to changes path |
| GAP-05 | **MEDIUM** | Data Integrity | `toggleStatus()` logs activity BEFORE DB save — orphaned log if save fails | `ShiftController.php:200-205` | Move activityLog after successful save |
| GAP-06 | **LOW** | Data Integrity | `destroy()` has no DB transaction wrapping two separate UPDATE queries | `ShiftController.php:124-126` | Wrap in `DB::transaction()` |
| GAP-07 | **LOW** | Query Quality | `index()` and `trashed()` have no `->orderBy()` — result order undefined | `ShiftController.php:21,144` | Add `->orderBy('created_at', 'desc')` |
| GAP-08 | **LOW** | UI | Code input `maxlength=10` in blades but DB allows 20 | Multiple blade files | Update blade maxlength to 20 |
| GAP-09 | **LOW** | UI | Name input `maxlength=50` in blades but DB allows 100 | Multiple blade files | Update blade maxlength to 100 |
| GAP-10 | **LOW** | Consistency | Inconsistent parameter style: 3 methods use route-binding, 4 use manual `$id` | Various controller methods | Standardize to one pattern |
| GAP-11 | **LOW** | Code Quality | `edit.blade.php` has unnecessary `enctype="multipart/form-data"` | `shift/edit.blade.php:26` | Remove enctype |
| GAP-12 | **LOW** | Code Quality | `index.blade.php` uses redundant `Carbon::parse()` on already-Carbon values | `shift/index.blade.php:58,64` | Use Carbon methods directly (match trash blade pattern) |
| GAP-13 | **LOW** | Code Quality | `scopeActive()` defined in model but never used in controller | `Shift.php:36-39` | Either use in queries or remove dead code |
| GAP-14 | **LOW** | Consistency | Create form uses raw HTML inputs, Edit form uses blade components | `create.blade.php` vs `edit.blade.php` | Standardize on component usage |
| GAP-15 | **LOW** | Activity Log | `performed_by` consistently missing from store/restore/forceDelete/toggleStatus logs | Various | Add `performed_by` to all activityLog calls |

---

## Appendix: Route References

| Route Name | Method | URL | Controller Method |
|------------|--------|-----|-------------------|
| `transport.shift.index` | GET | `/transport/shift` | `index()` |
| `transport.shift.create` | GET | `/transport/shift/create` | `create()` |
| `transport.shift.store` | POST | `/transport/shift` | `store()` |
| `transport.shift.show` | GET | `/transport/shift/{shift}` | `show()` |
| `transport.shift.edit` | GET | `/transport/shift/{shift}/edit` | `edit()` |
| `transport.shift.update` | PUT/PATCH | `/transport/shift/{shift}` | `update()` |
| `transport.shift.destroy` | DELETE | `/transport/shift/{shift}` | `destroy()` |
| `transport.shift.trashed` | GET | `/transport/shift/trash/view` | `trashed()` |
| `transport.shift.restore` | GET | `/transport/shift/{id}/restore` | `restore()` |
| `transport.shift.forceDelete` | DELETE | `/transport/shift/{id}/force-delete` | `forceDelete()` |
| `transport.shift.toggleStatus` | POST | `/transport/shift/{shift}/toggle-status` | `toggleStatus()` |

---

*Template: tpt_PickupStopsList_TcList.md (Syllabus depth) | Entity: Shift | Date: 2026-07-21*

