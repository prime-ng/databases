# tt_TimingProfiles_TcList

## Module: TimetableFoundation → Timetable Masters → Timing Profiles & Shifts

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | TimetableFoundation |
| Tab Group | Timetable Masters |
| Feature | Timing Profiles & Shifts (three sub-entities: Shifts tab, Timing Profiles resource, School Timing Profiles resource) |
| URL(s) | **Shifts:** `GET /timetable-foundation/timetable-masters?tab=shifts` (multi-tab page via `timetableMasters()`) — `GET /timetable-foundation/shift/create` (create form) — `POST /timetable-foundation/shift` (store) — `GET /timetable-foundation/shift/{shift}` (show) — `GET /timetable-foundation/shift/{shift}/edit` (edit form) — `PUT /timetable-foundation/shift/{shift}` (update) — `DELETE /timetable-foundation/shift/{shift}` (destroy) — `GET /timetable-foundation/shift/trash/view` (trashed list) — `GET /timetable-foundation/shift/{id}/restore` (restore) — `DELETE /timetable-foundation/shift/{id}/force-delete` (forceDelete) — `POST /timetable-foundation/shift/{shift}/toggle-status` (toggleStatus); **Timing Profiles:** `GET /timetable-foundation/timing-profile` (index) — `GET /timetable-foundation/timing-profile/create` (create) — `POST /timetable-foundation/timing-profile` (store) — `GET /timetable-foundation/timing-profile/{timing_profile}` (show) — `GET /timetable-foundation/timing-profile/{timing_profile}/edit` (edit) — `PUT /timetable-foundation/timing-profile/{timing_profile}` (update) — `DELETE /timetable-foundation/timing-profile/{timing_profile}` (destroy) — `GET /timetable-foundation/timing-profile/trash/view` (trashedPeriod) — `GET /timetable-foundation/timing-profile/{id}/restore` (restore) — `DELETE /timetable-foundation/timing-profile/{id}/force-delete` (forceDelete) — `POST /timetable-foundation/timing-profile/{timing_profile}/toggle-status` (toggleStatus); **School Timing Profiles:** `GET /timetable-foundation/school-timing-profile` (index) — `GET /timetable-foundation/school-timing-profile/create` (create) — `POST /timetable-foundation/school-timing-profile` (store) — `GET /timetable-foundation/school-timing-profile/{school_timing_profile}` (show) — `GET /timetable-foundation/school-timing-profile/{school_timing_profile}/edit` (edit) — `PUT /timetable-foundation/school-timing-profile/{school_timing_profile}` (update) — `DELETE /timetable-foundation/school-timing-profile/{school_timing_profile}` (destroy) — `GET /timetable-foundation/school-timing-profile/trash/view` (trashedPeriod) — `GET /timetable-foundation/school-timing-profile/{id}/restore` (restore) — `DELETE /timetable-foundation/school-timing-profile/{id}/force-delete` (forceDelete) — `POST /timetable-foundation/school-timing-profile/{school_timing_profile}/toggle-status` (toggleStatus) |
| Controller | `Modules\TimetableFoundation\Http\Controllers\SchoolShiftController` (227 lines) — inline validation; `Modules\TimetableFoundation\Http\Controllers\TimingProfileController` (264 lines) — uses `TimingProfileRequest`; `Modules\TimetableFoundation\Http\Controllers\SchoolTimingProfileController` (208 lines) — uses `SchoolTimingProfileRequest`; Shifts list loaded by `TimetableFoundationController@timetableMasters()` |
| Model(s) | `Modules\TimetableFoundation\Models\SchoolShift` (table: `tt_shifts`, SoftDeletes); `Modules\TimetableFoundation\Models\TimingProfile` (table: `tt_timing_profile`, SoftDeletes — aliased to SchoolShift via AppServiceProvider naming collision); `Modules\TimetableFoundation\Models\SchoolTimingProfile` (table: `school_timing_profiles`, SoftDeletes — aliased to SchoolShift) |
| Validation (Create) | Shifts: Inline in `SchoolShiftController@store()` — no separate FormRequest. Timing Profiles: `Modules\TimetableFoundation\Http\Requests\TimingProfileRequest`. School Timing Profiles: `Modules\TimetableFoundation\Http\Requests\SchoolTimingProfileRequest`. |
| Validation (Update) | Shifts: Inline in `SchoolShiftController@update()`. Timing Profiles: `TimingProfileRequest` (same request). School Timing Profiles: `SchoolTimingProfileRequest` (same request). |
| Policy | `Modules\TimetableFoundation\Policies\SchoolShiftPolicy` (6 gates: viewAny, view, create, update, delete, restore, forceDelete) — **registered** in `TimetableFoundationServiceProvider`; `Modules\TimetableFoundation\Policies\TimingProfilePolicy` (6 gates) — **NOT registered**; `Modules\TimetableFoundation\Policies\SchoolTimingProfilePolicy` (6 gates) — **NOT registered** |
| Permissions (Shift) | `timetable-foundation.shift.viewAny`, `.view`, `.create`, `.update`, `.delete`, `.restore`, `.forceDelete` |
| Permissions (TP) | `timetable-foundation.timing-profile.viewAny`, `.view`, `.create`, `.update`, `.delete`, `.restore`, `.forceDelete` |
| Permissions (STP) | `timetable-foundation.school-timing-profile.viewAny`, `.view`, `.create`, `.update`, `.delete`, `.restore`, `.forceDelete` |
| Pagination | Shifts list: no pagination (`->get()`, all records). Timing Profiles index: 10 records per page via `->paginate(10)`. School Timing Profiles index: 10 records per page via `->paginate(10)`. All trash views: 10 records per page via `->paginate(10)`. |
| Soft Deletes | Yes — all three models use `SoftDeletes` trait. `SchoolShift` and `SchoolTimingProfile` deactivate (`is_active=false`) before soft-delete; `TimingProfile` deletes directly without deactivation. `SchoolShift` reactivates (`is_active=true`) on restore; `TimingProfile` and `SchoolTimingProfile` do NOT reactivate. |
| Activity Log | Events: `Stored`, `Updated`, `Trashed`, `Restored`, `Deleted`, `Toggled` (all three controllers). Note: SchoolShift does NOT log `Stored` on create. TimingProfile update logs `changes` array with old/new values and `performed_by`. SchoolTimingProfile update logs `changes` array with old/new values and `performed_by`. |

---

## 2. Pre-conditions

- Required permissions: `timetable-foundation.*` viewAny + all feature-specific permissions for `shift.*`, `timing-profile.*`, and `school-timing-profile.*` as listed above
- Required seed data: At least 2 seed shifts from `TtShiftSeeder` (Morning, Afternoon). No seed data needed for `tt_timing_profile` or `school_timing_profiles` (empty tables by default).
- For filter tests: At least 3 shifts with varying `is_active` values (e.g., 2 active, 1 inactive)
- For Timing Profile tests: At least 3 timing profiles with varying data
- For School Timing Profile tests: At least 3 school timing profiles with varying data
- For pagination tests on Timing Profiles / School Timing Profiles: Create 11+ records for each
- For pagination overflow in trash: Create 11+ soft-deleted records per entity
- For FK constraint tests: At least one `PeriodConfig`, `PeriodSet`, and `TimetableType` record referencing an existing shift
- Test user must have all above permissions (default admin user)
- Tenant context must be initialized via `tenancy()->initialize()`
- Dusk environment variables: `DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD`

---

## 3. Default Data Load


When the Timetable Masters page loads via `TimetableFoundationController@timetableMasters()` (`GET /timetable-foundation/timetable-masters?tab=shifts`), the shifts tab data is fetched as part of the shared view.

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| Shifts Grid | `timetableMasters()` | `SchoolShift::query()->when(shift_search, search name/code)->when(shift_status, filter is_active)->ordered()->get()` | `shift_search` (text search on name, code), `shift_status` (1=active, 0=inactive, ''=all) | None (all matching records) |
| Trashed Shifts | `SchoolShiftController@trashedShift()` | `SchoolShift::onlyTrashed()->orderBy('ordinal')->paginate(10)` | None | 10/page (`page` param) |


| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| Timing Profile Grid | `TimingProfileController@index()` | `TimingProfile::paginate(10)` | None | 10/page (`page` param) |
| Trashed Timing Profiles | `TimingProfileController@trashedPeriod()` | `TimingProfile::onlyTrashed()->paginate(10)` | None | 10/page (`page` param) |


| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| School Timing Profile Grid | `SchoolTimingProfileController@index()` | `SchoolTimingProfile::paginate(10)` | None | 10/page (`page` param) |
| Trashed School Timing Profiles | `SchoolTimingProfileController@trashedPeriod()` | `SchoolTimingProfile::onlyTrashed()->paginate(10)` + `Period::onlyTrashed()->paginate(10)` — two paginated result sets | None | 10/page (`page` param) |

> **Data Source:** The `tt_shifts`, `tt_timing_profile`, and `school_timing_profiles` tables are wholly owned by TimetableFoundation. Note: `TimingProfile` and `SchoolTimingProfile` models are aliases of `SchoolShift` via AppServiceProvider — each uses its own dedicated table but shares the same underlying model class.

---

## 4. Test Data Strategy

- **Unique identifier:** Use `now()->format('YmdHis')` as a timestamp suffix for `code`, `name`, `profile_code`, `profile_name` to avoid unique constraint violations (e.g., `MORNING_TEST_20260718123456`).
- **Time values:** Use consistent test times — shift defaults: `07:30` – `14:50` (Morning), `12:00` – `18:00` (Afternoon). Timing profile total_periods: 8 or 10.
- **Pre-test cleanup:** Delete created records by code prefix before and after tests to avoid unique constraint violations on `uq_shift_code`, `uq_shift_name`, `uq_shift_ordinal`, `tt_timing_profile_profile_code_unique`, `school_timing_profiles_profile_name_unique`.
- **Pagination overflow for index:** Create 11+ timing profile records and 11+ school timing profile records to verify `paginate(10)` limit.
- **Pagination overflow for trash:** Create 11+ soft-deleted records per entity to verify `paginate(10)` on trash views.
- **Cross-module data:** Ensure at least one active `PeriodConfig`, `PeriodSet`, and `TimetableType` record reference an existing shift for FK constraint tests.
- **Known gaps:** The naming collision (SchoolShift aliased as TimingProfile / SchoolTimingProfile in AppServiceProvider) prevents policy registration for TimingProfilePolicy and SchoolTimingProfilePolicy — tests document the current behaviour.

---

## 5. Business Conditions

### 5.1 Database Schema — `tt_shifts`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | `id` | TINYINT UNSIGNED | PK, AUTO_INCREMENT |
| BC-DB-02 | `code` | VARCHAR(20) | NOT NULL, UNIQUE (`uq_shift_code`) |
| BC-DB-03 | `name` | VARCHAR(100) | NOT NULL, UNIQUE (`uq_shift_name`) |
| BC-DB-04 | `description` | VARCHAR(255) | DEFAULT NULL |
| BC-DB-05 | `default_start_time` | TIME | DEFAULT NULL |
| BC-DB-06 | `default_end_time` | TIME | DEFAULT NULL |
| BC-DB-07 | `ordinal` | TINYINT UNSIGNED | DEFAULT 1, UNIQUE (`uq_shift_ordinal`) |
| BC-DB-08 | `is_active` | TINYINT(1) | NOT NULL DEFAULT 1 |
| BC-DB-09 | `created_at` | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |
| BC-DB-10 | `updated_at` | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP |
| BC-DB-11 | `deleted_at` | TIMESTAMP | NULLABLE (soft delete) |
| BC-DB-12 | **UNIQUE KEY** `uq_shift_ordinal` | — | ON (`ordinal`) |
| BC-DB-13 | **UNIQUE KEY** `uq_shift_code` | — | ON (`code`) |
| BC-DB-14 | **UNIQUE KEY** `uq_shift_name` | — | ON (`name`) |

### 5.2 Database Schema — `tt_timing_profile`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-15 | `id` | BIGINT UNSIGNED | PK, AUTO_INCREMENT |
| BC-DB-16 | `profile_code` | VARCHAR(50) | NOT NULL, UNIQUE (`tt_timing_profile_profile_code_unique`) |
| BC-DB-17 | `name` | VARCHAR(200) | NOT NULL |
| BC-DB-18 | `total_periods` | INT UNSIGNED | NOT NULL |
| BC-DB-19 | `timezone` | VARCHAR(64) | DEFAULT NULL |
| BC-DB-20 | `notes` | VARCHAR(500) | DEFAULT NULL |
| BC-DB-21 | `is_active` | TINYINT(1) | NOT NULL DEFAULT 1 |
| BC-DB-22 | `deleted_at` | TIMESTAMP | NULLABLE (soft delete) |
| BC-DB-23 | `created_at` | TIMESTAMP | NULL DEFAULT NULL |
| BC-DB-24 | `updated_at` | TIMESTAMP | NULL DEFAULT NULL |
| BC-DB-25 | **UNIQUE KEY** `tt_timing_profile_profile_code_unique` | — | ON (`profile_code`) |

### 5.3 Database Schema — `school_timing_profiles`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-26 | `id` | BIGINT UNSIGNED | PK, AUTO_INCREMENT |
| BC-DB-27 | `profile_name` | VARCHAR(100) | NOT NULL, UNIQUE (`school_timing_profiles_profile_name_unique`) |
| BC-DB-28 | `short_name` | VARCHAR(20) | DEFAULT NULL, UNIQUE (`school_timing_profiles_short_name_unique`) |
| BC-DB-29 | `description` | VARCHAR(200) | DEFAULT NULL |
| BC-DB-30 | `is_active` | TINYINT(1) | NOT NULL DEFAULT 1 |
| BC-DB-31 | `deleted_at` | TIMESTAMP | NULLABLE (soft delete) |
| BC-DB-32 | `created_at` | TIMESTAMP | NULL DEFAULT NULL |
| BC-DB-33 | `updated_at` | TIMESTAMP | NULL DEFAULT NULL |
| BC-DB-34 | **UNIQUE KEY** `school_timing_profiles_profile_name_unique` | — | ON (`profile_name`) |
| BC-DB-35 | **UNIQUE KEY** `school_timing_profiles_short_name_unique` | — | ON (`short_name`) |

### 5.4 Validation Rules — SchoolShiftController@store (Create)

| BC ID | Field | Rule(s) | Error Message |
|-------|-------|---------|---------------|
| BC-VAL-01 | `code` | required, string, max:20, `Rule::unique('tt_shifts', 'code')->whereNull('deleted_at')` | "The code has already been taken." |
| BC-VAL-02 | `name` | required, string, max:100, `Rule::unique('tt_shifts', 'name')->whereNull('deleted_at')` | "The name has already been taken." |
| BC-VAL-03 | `description` | nullable, string, max:255 | — |
| BC-VAL-04 | `default_start_time` | nullable, `date_format:H:i` | — |
| BC-VAL-05 | `default_end_time` | nullable, `date_format:H:i`, `after:default_start_time` | "The default end time must be a date after default start time." |
| BC-VAL-06 | `ordinal` | required, integer, min:1, `Rule::unique('tt_shifts', 'ordinal')->whereNull('deleted_at')` | "The ordinal has already been taken." / "The ordinal must be at least 1." |
| BC-VAL-07 | `is_active` | nullable (boolean via `$request->boolean()`) | — |

### 5.5 Validation Rules — `SchoolShiftController@update` (Update)

All Create rules apply with `->ignore($shift->id)` for unique rules:

| BC ID | Field | Rule(s) | Error Message |
|-------|-------|---------|---------------|
| BC-VAL-U01 | `code` | unique + `->ignore($shift->id)->whereNull('deleted_at')` | "The code has already been taken." |
| BC-VAL-U02 | `name` | unique + `->ignore($shift->id)->whereNull('deleted_at')` | "The name has already been taken." |
| BC-VAL-U03 | `ordinal` | unique + `->ignore($shift->id)->whereNull('deleted_at')` | "The ordinal has already been taken." |
| BC-VAL-U04 | `default_end_time` | `after:default_start_time` | "The default end time must be a date after default start time." |

### 5.6 Validation Rules — `TimingProfileRequest` (Create & Update)

| BC ID | Field | Rule(s) | Error Message |
|-------|-------|---------|---------------|
| BC-VAL-T01 | `profile_code` | required, string, max:50, `unique:tt_timing_profile,profile_code,{id},id` | "The profile code has already been taken." |
| BC-VAL-T02 | `name` | required, string, max:50, `unique:tt_timing_profile,name,{id},id` | "The name has already been taken." |
| BC-VAL-T03 | `total_periods` | required, integer, min:1 | "The total periods must be at least 1." |
| BC-VAL-T04 | `timezone` | nullable, string, max:64 | — |
| BC-VAL-T05 | `notes` | nullable, string, max:500 | — |
| BC-VAL-T06 | `is_active` | nullable, boolean | — |
| BC-VAL-T07 | **`prepareForValidation()`** | Converts checkbox `"on"` to boolean; converts empty strings to `null` for `timezone` and `notes` | — |

### 5.7 Validation Rules — `SchoolTimingProfileRequest` (Create & Update)

| BC ID | Field | Rule(s) | Error Message |
|-------|-------|---------|---------------|
| BC-VAL-S01 | `profile_name` | required, string, max:100, `unique:school_timing_profiles,profile_name,{id}` | "The profile name has already been taken." |
| BC-VAL-S02 | `short_name` | nullable, string, max:20, `unique:school_timing_profiles,short_name,{id}` | "The short name has already been taken." |
| BC-VAL-S03 | `description` | nullable, string, max:200 | — |
| BC-VAL-S04 | `is_active` | boolean | — |
| BC-VAL-S05 | **`prepareForValidation()`** | Converts checkbox `"on"` to boolean for `is_active` | — |

### 5.8 Authorization

| BC ID | Permission | Controller Method(s) | Behavior |
|-------|-----------|----------------------|----------|
| BC-AUTH-01 | `timetable-foundation.shift.viewAny` | `SchoolShiftController@index()` | Without → 403 Forbidden |
| BC-AUTH-02 | `timetable-foundation.shift.view` | `SchoolShiftController@show()` | Without → 403 Forbidden |
| BC-AUTH-03 | `timetable-foundation.shift.create` | `SchoolShiftController@create()`, `store()` | Without → 403 Forbidden |
| BC-AUTH-04 | `timetable-foundation.shift.update` | `SchoolShiftController@edit()`, `update()`, `toggleStatus()` | Without → 403 Forbidden |
| BC-AUTH-05 | `timetable-foundation.shift.delete` | `SchoolShiftController@destroy()` | Without → 403 Forbidden |
| BC-AUTH-06 | `timetable-foundation.shift.restore` | `SchoolShiftController@trashedShift()`, `restore()` | Without → 403 Forbidden |
| BC-AUTH-07 | `timetable-foundation.shift.forceDelete` | `SchoolShiftController@forceDelete()` | Without → 403 Forbidden |
| BC-AUTH-08 | `timetable-foundation.timing-profile.viewAny` | `TimingProfileController@index()` | Without → 403 Forbidden |
| BC-AUTH-09 | `timetable-foundation.timing-profile.view` | `TimingProfileController@show()` | Without → 403 Forbidden |
| BC-AUTH-10 | `timetable-foundation.timing-profile.create` | `TimingProfileController@create()`, `store()` | Without → 403 Forbidden |
| BC-AUTH-11 | `timetable-foundation.timing-profile.update` | `TimingProfileController@edit()`, `update()`, `toggleStatus()` | Without → 403 Forbidden |
| BC-AUTH-12 | `timetable-foundation.timing-profile.delete` | `TimingProfileController@destroy()` | Without → 403 Forbidden |
| BC-AUTH-13 | `timetable-foundation.timing-profile.restore` | `TimingProfileController@trashedPeriod()`, `restore()` | Without → 403 Forbidden |
| BC-AUTH-14 | `timetable-foundation.timing-profile.forceDelete` | `TimingProfileController@forceDelete()` | Without → 403 Forbidden |
| BC-AUTH-15 | `timetable-foundation.school-timing-profile.viewAny` | `SchoolTimingProfileController@index()` | Without → 403 Forbidden |
| BC-AUTH-16 | `timetable-foundation.school-timing-profile.view` | `SchoolTimingProfileController@show()` | Without → 403 Forbidden |
| BC-AUTH-17 | `timetable-foundation.school-timing-profile.create` | `SchoolTimingProfileController@create()`, `store()` | Without → 403 Forbidden |
| BC-AUTH-18 | `timetable-foundation.school-timing-profile.update` | `SchoolTimingProfileController@edit()`, `update()`, `toggleStatus()` | Without → 403 Forbidden |
| BC-AUTH-19 | `timetable-foundation.school-timing-profile.delete` | `SchoolTimingProfileController@destroy()` | Without → 403 Forbidden |
| BC-AUTH-20 | `timetable-foundation.school-timing-profile.restore` | `SchoolTimingProfileController@trashedPeriod()`, `restore()` | Without → 403 Forbidden |
| BC-AUTH-21 | `timetable-foundation.school-timing-profile.forceDelete` | `SchoolTimingProfileController@forceDelete()` | Without → 403 Forbidden |
| BC-AUTH-22 | Guest access | All routes | Redirect to `/login` |

### 5.9 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Shifts tab loads via `timetableMasters()` at `GET /timetable-foundation/timetable-masters?tab=shifts` | Shifts list rendered with search bar (`shift_search`), status filter (`shift_status`), table with columns (#, Code, Name, Description, Start Time, End Time, Ordinal, Status Toggle, Actions). Create button present. |
| BC-BIZ-02 | Search by `shift_search` (name + code) | Shifts filtered to show only records whose `name` or `code` contains the search string |
| BC-BIZ-03 | Filter by `shift_status` | Shifts filtered to show active (1) or inactive (0); no default means all |
| BC-BIZ-04 | Shift list ordered by `ordinal` | Model scope `ordered()` applies `orderBy('ordinal')` to all queries |
| BC-BIZ-05 | Create shift with required fields (code, name, ordinal) | Shift created with `is_active=true`, default_start_time=null, default_end_time=null, description=null. Redirect to masters page with `flash('created.shift')`. |
| BC-BIZ-06 | Default start/end time validation | `default_end_time` must be `after:default_start_time`; both accept `H:i` format |
| BC-BIZ-07 | Shift unique constraints on code, name, ordinal | Each validated with `Rule::unique('tt_shifts', 'column')->whereNull('deleted_at')` — soft-deleted records are excluded from uniqueness checks |
| BC-BIZ-08 | Shift soft delete deactivates before delete | `destroy()` sets `is_active=false` BEFORE calling `$shift->delete()`. Activity logged as 'Trashed'. |
| BC-BIZ-09 | Shift restore reactivates | `restore()` calls `$shift->restore()` THEN sets `is_active=true`. Activity logged as 'Restored'. |
| BC-BIZ-10 | Shift toggleStatus returns JSON | `toggleStatus()` validates `is_active`, updates, returns `{success, is_active, message}`. Activity logged as 'Toggled'. |
| BC-BIZ-11 | Timing Profile index paginated at 10 per page | `index()` calls `TimingProfile::paginate(10)`. Page 2 loads via `?page=2`. |
| BC-BIZ-12 | Timing Profile store() persists only 4 fields | `store()` uses `$request->only(['profile_code', 'name', 'total_periods', 'is_active'])` — `timezone` and `notes` are NOT persisted on create (known bug). |
| BC-BIZ-13 | Timing Profile update() persists all 6 fields | `update()` uses `$request->only(['profile_code', 'name', 'total_periods', 'timezone', 'notes', 'is_active'])` — includes timezone and notes. |
| BC-BIZ-14 | Timing Profile update tracks changes | Controller captures `getOriginal()` and `getChanges()`, builds `$changedAttributes` array with old/new pairs, excludes `updated_at`. Logs with `changes` and `performed_by`. |
| BC-BIZ-15 | Timing Profile delete does NOT deactivate | `destroy()` calls `$timingProfile->delete()` directly — `is_active` value is preserved. Activity logged as 'Trashed'. |
| BC-BIZ-16 | Timing Profile restore does NOT reactivate | `restore()` calls `$timingProfile->restore()` — `is_active` remains as it was at time of delete. Activity logged as 'Restored'. |
| BC-BIZ-17 | Timing Profile prepareForValidation() normalizes | `is_active` checkbox `"on"` converted to boolean; empty strings for `timezone` and `notes` converted to `null` |
| BC-BIZ-18 | School Timing Profile index paginated at 10 per page | `index()` calls `SchoolTimingProfile::paginate(10)` |
| BC-BIZ-19 | School Timing Profile store uses validated() | `store()` uses `$request->validated()` from Form Request (best practice). Activity logged as 'Stored'. |
| BC-BIZ-20 | School Timing Profile update converts checkbox | `$data['is_active'] = $request->has('is_active') ? 1 : 0` — manual checkbox handling |
| BC-BIZ-21 | School Timing Profile update tracks changes | Same change-tracking pattern as TimingProfile: `getOriginal()` / `getChanges()` with `$changedAttributes` array |
| BC-BIZ-22 | School Timing Profile soft delete deactivates | `destroy()` sets `is_active=false` BEFORE calling `$profile->delete()`. Activity logged as 'Trashed'. |
| BC-BIZ-23 | School Timing Profile restore does NOT reactivate | `restore()` calls `$profile->restore()` but does NOT set `is_active=true`. Activity logged as 'Restored'. |
| BC-BIZ-24 | School Timing Profile trashed view loads two entities | `trashedPeriod()` fetches BOTH `SchoolTimingProfile::onlyTrashed()->paginate(10)` AND `Period::onlyTrashed()->paginate(10)` |
| BC-BIZ-25 | Timing Profile redirects to timetable-foundation.index | Both `store()` and `update()` on TimingProfile and SchoolTimingProfile redirect to `route('timetable-foundation.index')`, NOT their own index |
| BC-BIZ-26 | Shift redirects to timetableMasters tab | All shift actions redirect to `route('timetable-foundation.menu.timetableMasters', ['tab' => 'shifts'])` |
| BC-BIZ-27 | Naming collision: TimingProfile/SchoolTimingProfile policies NOT registered | `TimingProfilePolicy` and `SchoolTimingProfilePolicy` classes exist but are NOT registered in `TimetableFoundationServiceProvider::registerPolicies()`. Gate fallback to permission-string checks. |
| BC-BIZ-28 | Known bug: SchoolShift store() does NOT log activity | SchoolShiftController@store() creates the record without calling `activityLog()` — no 'Stored' event recorded |

### 5.10 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|------------------|----------------|
| BC-REF-01 | `tt_shifts.id` (referenced by `tt_period_configs.shift_id`) | `tt_period_configs` | RESTRICT |
| BC-REF-02 | `tt_shifts.id` (referenced by `tt_period_sets.shift_id`) | `tt_period_sets` | RESTRICT |
| BC-REF-03 | `tt_shifts.id` (referenced by `tt_timetable_types.shift_id`) | `tt_timetable_types` | Not specified (default RESTRICT) |
| BC-REF-04 | `tt_timing_profile` and `school_timing_profiles` | — (no FK relationships to other tables in current schema) | — |

---

## 6. Test Case List

### 6.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | Shifts Tab Loads With All UI Elements | Tab pane loads at `GET /timetable-foundation/timetable-masters?tab=shifts` with search input (`shift_search`), status filter dropdown, table columns (#, Code, Name, Description, Start Time, End Time, Ordinal, Status Toggle, Actions), and Create button. Pre-seeded shifts (Morning, Afternoon) displayed. | — | — | ⬜ |
| TC-P02 | Filter Shifts By Name/Code Search | Enter a search term matching a shift's name or code; grid shows only matching shifts. Enter non-matching term; grid is empty. | — | — | ⬜ |
| TC-P03 | Filter Shifts By Status | Select "Inactive" from status filter; grid shows only inactive shifts. Select "All"; all shifts shown. | — | — | ⬜ |
| TC-P04 | Shift List Ordered By Ordinal | Shifts displayed in ascending ordinal order (Morning=1, Afternoon=2). DB query confirms `orderBy('ordinal')`. | — | — | ⬜ |
| TC-P05 | Create Shift With Required Fields Only | Fill code="TEST1", name="Test Shift 1", ordinal=3. Submit POST to `/timetable-foundation/shift`. Shift created with `is_active=true`, default_start_time=null, default_end_time=null, description=null. Redirect to `timetable-foundation.menu.timetableMasters?tab=shifts` with success flash. | — | — | ⬜ |
| TC-P06 | Create Shift With All Fields | Fill code="TEST2", name="Test Shift 2", description="A test shift", default_start_time=08:00, default_end_time=16:00, ordinal=4, is_active=ON. All values persisted in DB. | — | — | ⬜ |
| TC-P07 | Create Shift With `is_active=false` | Create shift with is_active=OFF. Shift created with `is_active=0`. | — | — | ⬜ |
| TC-P08 | Create Shift Without Default End Time | Fill all fields except default_end_time. Shift created with default_end_time=null. | — | — | ⬜ |
| TC-P09 | View Shift Details | Click View on a shift row. Show page (`GET /timetable-foundation/shift/{id}`) loads with all fields displayed: code, name, description, default_start_time, default_end_time, ordinal, is_active badge, timestamps. | — | — | ⬜ |
| TC-P10 | Edit Shift Loads Pre-Filled Data | Click Edit on a shift row. Edit form (`GET /timetable-foundation/shift/{id}/edit`) loads with existing values for all fields. | — | — | ⬜ |
| TC-P11 | Update Shift Name and Code | Change name and code via PUT to `/timetable-foundation/shift/{id}`. Shift updated. Redirect with success flash. Activity logged as 'Updated' with message 'Shift details updated'. | — | — | ⬜ |
| TC-P12 | Update Shift — Modify Start/End Times | Change default_start_time from 07:30 to 08:00 and default_end_time from 14:50 to 15:00. Values updated in DB. | — | — | ⬜ |
| TC-P13 | Toggle Shift Status Active → Inactive | Click status toggle on an active shift. AJAX POST to `toggle-status`. Shift becomes inactive. JSON response `{success: true, is_active: false, message: "..."}`. Activity logged as 'Toggled'. UI badge updates. | — | — | ⬜ |
| TC-P14 | Toggle Shift Status Inactive → Active | Same as TC-P13 reversing; shift becomes active; JSON returns `is_active: true`. | — | — | ⬜ |
| TC-P15 | Soft Delete Active Shift | Click Delete on an active shift. `is_active` set to false, then soft-deleted. Redirect with success flash. Record appears in trash view (`GET /timetable-foundation/shift/trash/view`). Activity logged as 'Trashed' with message 'Shift was deactivated and moved to trash.'. | — | — | ⬜ |
| TC-P16 | View Trashed Shifts List | Navigate to trash view; all soft-deleted shifts listed with name, code, deleted_at timestamp, and Restore / Force Delete action buttons. Paginated at 10 per page. | — | — | ⬜ |
| TC-P17 | Restore Soft-Deleted Shift | Click Restore on a trashed shift. `deleted_at` nullified, `is_active=true`. Redirect to trash with success flash. Shift reappears in main active list. Activity logged as 'Restored'. | — | — | ⬜ |
| TC-P18 | Force Delete Shift (No Dependencies) | Click Force Delete on a trashed shift that has NO child records. Shift permanently removed from DB. Redirect with success flash. Activity logged as 'Deleted'. | — | — | ⬜ |
| TC-P19 | Timing Profile Index Loads Paginated | `GET /timetable-foundation/timing-profile` returns paginated list with 10 records per page. Page links present. Table columns: profile_code, name, total_periods, timezone, notes, status, actions. | — | — | ⬜ |
| TC-P20 | Create Timing Profile With Required Fields | Fill profile_code="PROF_TEST", name="Profile Test", total_periods=8. Submit via POST. Profile created with `is_active=true`, timezone=null, notes=null. Redirect to `timetable-foundation.index`. Activity logged as 'Stored'. | — | — | ⬜ |
| TC-P21 | Create Timing Profile With All Fields | Fill profile_code="PROF_FULL", name="Profile Full", total_periods=10, timezone="Asia/Kolkata", notes="Test notes", is_active=ON. Only profile_code, name, total_periods, is_active persisted (timezone and notes are NOT persisted on create — known bug). | — | — | ⬜ |
| TC-P22 | View Timing Profile Details | Click View. Show page loads with all fields. | — | — | ⬜ |
| TC-P23 | Edit Timing Profile Loads Pre-Filled Data | Click Edit. Edit form loads with existing values. | — | — | ⬜ |
| TC-P24 | Update Timing Profile With All Fields (Including timezone and notes) | Change name, profile_code, total_periods, set timezone="Asia/Kolkata", notes="Updated notes". Update via PUT. All 6 fields persisted (timezone and notes ARE included on update). Redirect with success flash. Activity logged as 'Updated' with `changes` array and `performed_by`. | — | — | ⬜ |
| TC-P25 | Toggle Timing Profile Status | AJAX POST to `toggle-status` flips `is_active`. JSON response `{success, is_active, message}`. Activity logged as 'Toggled'. | — | — | ⬜ |
| TC-P26 | Soft Delete Timing Profile | Click Delete. Profile soft-deleted WITHOUT deactivating `is_active` first (is_active remains as-is). Redirect with success flash. Activity logged as 'Trashed'. | — | — | ⬜ |
| TC-P27 | Restore Soft-Deleted Timing Profile | Click Restore. Profile restored but `is_active` is NOT set to true (is_active remains false). Redirect to trash. Activity logged as 'Restored'. | — | — | ⬜ |
| TC-P28 | School Timing Profile Index Loads Paginated | `GET /timetable-foundation/school-timing-profile` returns paginated list with 10 per page. Table columns: profile_name, short_name, description, status, actions. | — | — | ⬜ |
| TC-P29 | Create School Timing Profile With Required Fields | Fill profile_name="School Test". Submit via POST. Profile created with `is_active=true`, short_name=null, description=null. Redirect to `timetable-foundation.index`. Activity logged as 'Stored'. | — | — | ⬜ |
| TC-P30 | Create School Timing Profile With All Fields | Fill profile_name="School Full", short_name="SF", description="Test desc", is_active=OFF. All values persisted. | — | — | ⬜ |
| TC-P31 | Update School Timing Profile | Change profile_name and short_name. Update via PUT. Values updated. Activity logged with `changes` array and `performed_by`. Redirect with success flash. | — | — | ⬜ |
| TC-P32 | Toggle School Timing Profile Status | AJAX POST flips `is_active`. JSON response returned. Activity logged as 'Toggled'. | — | — | ⬜ |
| TC-P33 | Soft Delete School Timing Profile | Click Delete. `is_active` set to false BEFORE soft-delete. Redirect with success flash. Activity logged as 'Trashed'. | — | — | ⬜ |
| TC-P34 | Restore Soft-Deleted School Timing Profile | Click Restore. Profile restored but `is_active` is NOT reactivated (remains false). Redirect to trash. Activity logged as 'Restored'. | — | — | ⬜ |
| TC-P35 | Force Delete School Timing Profile | Force Delete a trashed profile with no children. Record permanently removed. Activity logged as 'Deleted'. | — | — | ⬜ |
| TC-P36 | School Timing Profile Trash View Shows Two Entities | Trash view (`GET /timetable-foundation/school-timing-profile/trash/view`) lists both soft-deleted SchoolTimingProfiles (paginated at 10) AND soft-deleted Periods (paginated at 10). | — | — | ⬜ |
| TC-P37 | Pagination Overflow — Timing Profiles Index | Create 11+ timing profiles. Page 1 shows 10; page 2 shows remaining 1+. | — | — | ⬜ |
| TC-P38 | Pagination Overflow — School Timing Profiles Index | Create 11+ school timing profiles. Page 1 shows 10; page 2 shows remaining 1+. | — | — | ⬜ |
| TC-P39 | Pagination Overflow — Shift Trash | Create 11+ soft-deleted shifts. Trash view shows 10 per page. Page 2 shows remaining records. | — | — | ⬜ |
| TC-P40 | Pagination Overflow — Timing Profile Trash | Create 11+ soft-deleted timing profiles. Trash view shows 10 per page. | — | — | ⬜ |
| TC-P41 | Empty State — No Shifts Exist | When no shift records (or all deleted), table shows empty state message. | — | — | ⬜ |
| TC-P42 | Empty State — No Trashed Shifts | When no trashed shifts, trash view shows empty state. | — | — | ⬜ |
| TC-P43 | Full Lifecycle — Shift: Create → View → Edit → Toggle → Soft Delete → Restore → Force Delete | Each step succeeds; data transitions correctly: is_active goes true→false→true→false; deleted_at goes null→timestamp→null→timestamp→permanently removed. | — | — | ⬜ |
| TC-P44 | Full Lifecycle — Timing Profile: Create → View → Edit → Toggle → Soft Delete → Restore → Force Delete | Each step succeeds; note that is_active is NOT deactivated on delete and NOT reactivated on restore. | — | — | ⬜ |
| TC-P45 | Full Lifecycle — School Timing Profile: Create → View → Edit → Toggle → Soft Delete → Restore → Force Delete | Each step succeeds; is_active deactivated on delete but NOT reactivated on restore. | — | — | ⬜ |

### 6.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | Shift — Missing `code` | Validation error: "The code field is required." | — | — | ⬜ |
| TC-N02 | Shift — Missing `name` | Validation error: "The name field is required." | — | — | ⬜ |
| TC-N03 | Shift — Missing `ordinal` | Validation error: "The ordinal field is required." | — | — | ⬜ |
| TC-N04 | Shift — Duplicate `code` | Create two shifts with same code. Second fails unique validation (deleted_at IS NULL scope). | — | — | ⬜ |
| TC-N05 | Shift — Duplicate `name` | Create two shifts with same name. Second fails unique validation. | — | — | ⬜ |
| TC-N06 | Shift — Duplicate `ordinal` | Create two shifts with same ordinal. Second fails unique validation. | — | — | ⬜ |
| TC-N07 | Shift — `code` > 20 Characters | Validation fails on max:20. | — | — | ⬜ |
| TC-N08 | Shift — `name` > 100 Characters | Validation fails on max:100. | — | — | ⬜ |
| TC-N09 | Shift — `ordinal` = 0 or Negative | Validation fails on min:1. | — | — | ⬜ |
| TC-N10 | Shift — `default_end_time` Before `default_start_time` | Set start=14:00, end=13:00. Validation rule `after:default_start_time` triggers. | — | — | ⬜ |
| TC-N11 | Shift — `default_start_time` Wrong Format | Enter "25:00" or "abc". Validation fails on `date_format:H:i`. | — | — | ⬜ |
| TC-N12 | Shift — `default_end_time` Wrong Format | Enter invalid time format. Validation fails on `date_format:H:i`. | — | — | ⬜ |
| TC-N13 | Timing Profile — Missing `profile_code` | Validation error: "The profile code field is required." | — | — | ⬜ |
| TC-N14 | Timing Profile — Missing `name` | Validation error: "The name field is required." | — | — | ⬜ |
| TC-N15 | Timing Profile — Missing `total_periods` | Validation error: "The total periods field is required." | — | — | ⬜ |
| TC-N16 | Timing Profile — Duplicate `profile_code` | Create two timing profiles with same profile_code. Second fails unique validation. | — | — | ⬜ |
| TC-N17 | Timing Profile — Duplicate `name` | Create two timing profiles with same name. Second fails unique validation. | — | — | ⬜ |
| TC-N18 | Timing Profile — `total_periods` = 0 | Validation fails on min:1. | — | — | ⬜ |
| TC-N19 | Timing Profile — `profile_code` > 50 Characters | Validation fails on max:50. | — | — | ⬜ |
| TC-N20 | Timing Profile — `name` > 50 Characters | Validation fails on max:50. | — | — | ⬜ |
| TC-N21 | Timing Profile — `notes` > 500 Characters | Validation fails on max:500. | — | — | ⬜ |
| TC-N22 | Timing Profile — `timezone` > 64 Characters | Validation fails on max:64. | — | — | ⬜ |
| TC-N23 | School Timing Profile — Missing `profile_name` | Validation error: "The profile name field is required." | — | — | ⬜ |
| TC-N24 | School Timing Profile — Duplicate `profile_name` | Create two with same profile_name. Second fails unique validation. | — | — | ⬜ |
| TC-N25 | School Timing Profile — Duplicate `short_name` | Create two with same short_name. Second fails unique validation. | — | — | ⬜ |
| TC-N26 | School Timing Profile — `profile_name` > 100 Characters | Validation fails on max:100. | — | — | ⬜ |
| TC-N27 | School Timing Profile — `short_name` > 20 Characters | Validation fails on max:20. | — | — | ⬜ |
| TC-N28 | School Timing Profile — `description` > 200 Characters | Validation fails on max:200. | — | — | ⬜ |
| TC-N29 | Permission 403 — No `shift.viewAny` | User without shift.viewAny → 403 on accessing shifts tab page. | — | — | ⬜ |
| TC-N30 | Permission 403 — No `timing-profile.viewAny` | User without timing-profile.viewAny → 403 on timing profile index. | — | — | ⬜ |
| TC-N31 | Permission 403 — No `school-timing-profile.viewAny` | User without school-timing-profile.viewAny → 403 on school timing profile index. | — | — | ⬜ |
| TC-N32 | Permission 403 — No `shift.create` | User without shift.create → 403 on create form (GET) and store (POST). | — | — | ⬜ |
| TC-N33 | Permission 403 — No `shift.update` | User without shift.update → 403 on edit, update, and toggleStatus. | — | — | ⬜ |
| TC-N34 | Permission 403 — No `shift.delete` | User without shift.delete → 403 on destroy. | — | — | ⬜ |
| TC-N35 | Permission 403 — No `shift.restore` | User without shift.restore → 403 on trash view and restore action. | — | — | ⬜ |
| TC-N36 | Permission 403 — No `shift.forceDelete` | User without shift.forceDelete → 403 on forceDelete. | — | — | ⬜ |
| TC-N37 | Guest Access Redirect | Unauthenticated user accessing any shift/timing-profile/school-timing-profile route → redirected to `/login`. | — | — | ⬜ |
| TC-N38 | View Non-Existent Shift (404) | `GET /timetable-foundation/shift/99999` → 404 via `findOrFail`. | — | — | ⬜ |
| TC-N39 | Update Non-Existent Timing Profile (404) | `PUT /timetable-foundation/timing-profile/99999` → 404 via `findOrFail`. | — | — | ⬜ |
| TC-N40 | Delete Non-Existent School Timing Profile (404) | `DELETE /timetable-foundation/school-timing-profile/99999` → 404 via implicit model binding. | — | — | ⬜ |
| TC-N41 | Toggle Status On Non-Existent Shift (404) | `POST /timetable-foundation/shift/99999/toggle-status` → 404 via implicit model binding. | — | — | ⬜ |
| TC-N42 | Force Delete Shift With Active PeriodConfig FK | Force Delete a shift that has existing period_config records referencing its id. FK constraint `fk_pc_shift` (RESTRICT) prevents deletion; DB exception thrown. | — | — | ⬜ |
| TC-N43 | Force Delete Shift With Active PeriodSet FK | Force Delete a shift with existing period_set records. FK constraint `fk_periodset_shift` (RESTRICT) prevents deletion. | — | — | ⬜ |
| TC-N44 | Force Delete Shift With Active TimetableType FK | Force Delete a shift with existing timetable_type records referencing shift_id. FK constraint `fk_tttype_shift` (RESTRICT) prevents deletion. | — | — | ⬜ |
| TC-N45 | Timing Profile — Soft-Deleted Unique Violation Not Checked | Create timing profile P1, delete it, create P2 with same profile_code. P2 creation should succeed (application only checks non-deleted, but DB unique key includes deleted rows — may fail at DB level). Document current behaviour. | — | — | ⬜ |
| TC-N46 | School Timing Profile — Soft-Deleted Name Unique Violation | Create STP S1, delete it, create S2 with same profile_name. Unique check includes soft-deleted (no `whereNull('deleted_at')`) → validation error. | — | — | ⬜ |

### 6.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|----------------|---------|---------|--------|
| TC-D01 | A | Shift — Soft Delete Sets `is_active=false` | `destroy()` sets `is_active=false` before `delete()`; after delete, record has `is_active=0`, `deleted_at` set. | — | — | ⬜ |
| TC-D02 | A | Shift — Restore Sets `is_active=true` | After restore, `is_active=true`, `deleted_at=NULL`. | — | — | ⬜ |
| TC-D03 | B | Timing Profile — Delete Does NOT Deactivate | `destroy()` calls `$timingProfile->delete()` without setting `is_active=false`. `is_active` value remains as-is. | — | — | ⬜ |
| TC-D04 | B | Timing Profile — Restore Does NOT Reactivate | After restore, `is_active` remains false (if it was false at time of delete). | — | — | ⬜ |
| TC-D05 | C | School Timing Profile — Delete Deactivates | `destroy()` sets `is_active=false` BEFORE `delete()`. | — | — | ⬜ |
| TC-D06 | C | School Timing Profile — Restore Does NOT Reactivate | After restore, `is_active` remains false (different from SchoolShift behaviour). | — | — | ⬜ |
| TC-D07 | D | Shift — `toggleStatus()` Returns JSON | AJAX POST returns `{success: true/false, is_active: bool, message: string}`. | — | — | ⬜ |
| TC-D08 | D | Timing Profile — `toggleStatus()` Returns JSON | Same JSON shape as Shift. | — | — | ⬜ |
| TC-D09 | D | School Timing Profile — `toggleStatus()` Returns JSON | Same JSON shape. | — | — | ⬜ |
| TC-D10 | E | DB UNIQUE — `uq_shift_code` on `tt_shifts.code` | Direct DB INSERT of duplicate code fails with integrity constraint violation. | — | — | ⬜ |
| TC-D11 | E | DB UNIQUE — `uq_shift_name` on `tt_shifts.name` | Direct DB INSERT of duplicate name fails with integrity constraint violation. | — | — | ⬜ |
| TC-D12 | E | DB UNIQUE — `uq_shift_ordinal` on `tt_shifts.ordinal` | Direct DB INSERT of duplicate ordinal fails with integrity constraint violation. | — | — | ⬜ |
| TC-D13 | F | DB UNIQUE — `tt_timing_profile_profile_code_unique` | Direct DB INSERT of duplicate profile_code fails with integrity constraint violation. | — | — | ⬜ |
| TC-D14 | G | DB UNIQUE — `school_timing_profiles_profile_name_unique` | Direct DB INSERT of duplicate profile_name fails with integrity constraint violation. | — | — | ⬜ |
| TC-D15 | G | DB UNIQUE — `school_timing_profiles_short_name_unique` | Direct DB INSERT of duplicate short_name fails with integrity constraint violation. | — | — | ⬜ |
| TC-D16 | H | Integration — Activity Logged After CRUD — Shift | `activityLog('Updated')` after update; `activityLog('Trashed')` after destroy; `activityLog('Restored')` after restore; `activityLog('Deleted')` after forceDelete; `activityLog('Toggled')` after toggleStatus. Note: no `activityLog('Stored')` on create. | — | — | ⬜ |
| TC-D17 | I | Integration — Activity Logged After CRUD — Timing Profile | `activityLog('Stored')` after create with message; `activityLog('Updated')` after update with `changes` array and `performed_by`; `activityLog('Trashed')` after destroy; `activityLog('Restored')` after restore; `activityLog('Deleted')` after forceDelete; `activityLog('Toggled')` after toggleStatus. | — | — | ⬜ |
| TC-D18 | J | Integration — Activity Logged After CRUD — School Timing Profile | Same pattern as Timing Profile with `changes` array on update. | — | — | ⬜ |
| TC-D19 | K | Unit — SchoolShift Model `$casts` — Boolean/Integer/DateTime Casting | `is_active` stored as TINYINT accessed as boolean; `ordinal` as integer; `default_start_time`, `default_end_time` as datetime (cast as `datetime` even though they are TIME fields — date portion set to current date). | — | — | ⬜ |
| TC-D20 | L | Unit — SchoolShift Model `$fillable` Matches DDL | `$fillable` contains: code, name, description, default_start_time, default_end_time, ordinal, is_active. `id`, `created_at`, `updated_at`, `deleted_at` NOT fillable. | — | — | ⬜ |
| TC-D21 | M | Unit — SchoolShift Model — SoftDeletes | `delete()` sets `deleted_at`; `restore()` nullifies `deleted_at`; `withTrashed()` includes soft-deleted; `onlyTrashed()` filters to deleted only. | — | — | ⬜ |
| TC-D22 | N | Unit — SchoolShift Model — Scopes | `scopeActive()` filters `where('is_active', true)`. `scopeOrdered()` applies `orderBy('ordinal')`. | — | — | ⬜ |
| TC-D23 | O | Unit — SchoolShift Model — hasMany TimetableTypes | `$shift->timetableTypes` returns all TimetableType records where `shift_id` = shift id. | — | — | ⬜ |
| TC-D24 | P | Integration — Controller `findOrFail` — All Methods With Valid/Invalid IDs | Valid ID loads model; Invalid ID throws `ModelNotFoundException` → HTTP 404 for all methods across all three controllers. | — | — | ⬜ |
| TC-D25 | Q | Integration — Controller `Gate::authorize()` — Before All Methods | Every controller method across all three controllers calls `Gate::authorize()` with its respective permission string before business logic. | — | — | ⬜ |
| TC-D26 | R | Unit — TimingProfilePolicy — Gates Defined but Policy NOT Registered | Policy class exists with 6 gates (viewAny, view, create, update, delete, restore, forceDelete). But policy is NOT registered in any ServiceProvider — Gates fall back to permission-string checks. | — | — | ⬜ |
| TC-D27 | S | Unit — SchoolTimingProfilePolicy — Gates Defined but Policy NOT Registered | Same as TC-D26 for SchoolTimingProfilePolicy. | — | — | ⬜ |
| TC-D28 | T | Integration — Routes — All Three Resource Routes Registered | Shift, timing-profile, school-timing-profile resource routes plus trash/restore/forceDelete/toggleStatus custom routes; all map to correct controller methods. | — | — | ⬜ |
| TC-D29 | U | Known Bug — TimingProfile `store()` Does Not Persist timezone/notes | `store()` uses `$request->only(['profile_code', 'name', 'total_periods', 'is_active'])`. Submitting timezone or notes on create — values are silently dropped. | — | — | ⬜ |
| TC-D30 | V | Known Bug — SchoolShift store() Does Not Log Activity | `SchoolShiftController@store()` does NOT call `activityLog()`. Only update, destroy, restore, forceDelete, toggleStatus log activity. | — | — | ⬜ |

### 6.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|-----------------|---------|---------|--------|
| TC-CR01 | CR | P1 | Model — `$fillable` matches DDL columns — SchoolShift | `$fillable` contains exactly: code, name, description, default_start_time, default_end_time, ordinal, is_active | — | — | ◌ |
| TC-CR02 | CR | P1 | Model — `$fillable` matches DDL columns — TimingProfile | Model should have `$fillable` containing: profile_code, name, total_periods, timezone, notes, is_active | — | — | ◌ |
| TC-CR03 | CR | P1 | Model — `$fillable` matches DDL columns — SchoolTimingProfile | Model should have `$fillable` containing: profile_name, short_name, description, is_active | — | — | ◌ |
| TC-CR04 | CR | P1 | Model — `$casts` for booleans/integers/dates — SchoolShift | `is_active` → boolean; `ordinal` → integer; `default_start_time`/`default_end_time` → datetime (though they are TIME fields) | — | — | ◌ |
| TC-CR05 | CR | P1 | Model — SoftDeletes trait correctly implemented — All three models | Each model uses `SoftDeletes` trait; `delete()` sets `deleted_at`; `restore()` nullifies `deleted_at` | — | — | ◌ |
| TC-CR06 | CR | P1 | Model — relationships defined — SchoolShift | `timetableTypes()` → `hasMany(TimetableType::class, 'shift_id')`; scopes: `active()`, `ordered()` | — | — | ◌ |
| TC-CR07 | CR | P1 | Controller — try-catch exception handling on write methods | All three controllers' `store()`, `update()`, `destroy()` should use try-catch or appropriate error handling | — | — | ◌ |
| TC-CR08 | CR | P1 | Controller — `Gate::authorize()` on every method | Every controller method across all three controllers calls `Gate::authorize()` before business logic | — | — | ◌ |
| TC-CR09 | CR | P1 | Controller — activity logged on all state changes | SchoolShift: logs on update, destroy, restore, forceDelete, toggleStatus (EXCEPT store — known gap). TimingProfile and SchoolTimingProfile: logs on all CRUD + toggleStatus | — | — | ◌ |
| TC-CR10 | CR | P1 | Controller — `is_active=false` before soft delete; restore sets `is_active=true` | SchoolShift: YES — deactivates before delete, reactivates on restore. TimingProfile: NO — neither. SchoolTimingProfile: YES — deactivates before delete, but NO — does NOT reactivate on restore | — | — | ◌ |
| TC-CR11 | CR | P1 | Controller — `toggleStatus()` actually flips `is_active` | All three controllers: validates `is_active`, updates model, returns JSON `{success, is_active, message}` | — | — | ◌ |
| TC-CR12 | CR | P1 | Controller — trash/restore/forceDelete flow | `onlyTrashed()` / `withTrashed()` / `forceDelete()` used correctly. SchoolShift and SchoolTimingProfile: data transformations (is_active) on delete/restore. TimingProfile: no data transformations. | — | — | ◌ |
| TC-CR13 | CR | P1 | Controller — JSON success response after toggleStatus | All three controllers return JSON `{success, is_active, message}`. On save success: `success: true`. On save failure (TimingProfile and SchoolTimingProfile): `success: false` with HTTP 200. | — | — | ◌ |
| TC-CR14 | CR | P1 | Controller — redirect correct after create/update | SchoolShift: redirects to `timetable-foundation.menu.timetableMasters` with tab=shifts. TimingProfile: redirects to `timetable-foundation.index`. SchoolTimingProfile: redirects to `timetable-foundation.index`. | — | — | ◌ |
| TC-CR15 | CR | P1 | Request — validation rules cover all fields — TimingProfileRequest | Rules: profile_code (required, max:50, unique), name (required, max:50, unique), total_periods (required, integer, min:1), timezone (nullable, max:64), notes (nullable, max:500), is_active (nullable, boolean). `prepareForValidation()` normalizes checkbox and empty strings. | — | — | ◌ |
| TC-CR16 | CR | P1 | Request — validation rules cover all fields — SchoolTimingProfileRequest | Rules: profile_name (required, max:100, unique), short_name (nullable, max:20, unique), description (nullable, max:200), is_active (boolean). `prepareForValidation()` normalizes is_active. | — | — | ◌ |
| TC-CR17 | CR | P1 | Request — unique rules ignore current ID on update — Both Requests | TimingProfileRequest: `unique:tt_timing_profile,profile_code,{id},id`. SchoolTimingProfileRequest: `unique:school_timing_profiles,profile_name,{id}`. Both ignore current record on update. | — | — | ◌ |
| TC-CR18 | CR | P1 | Policy — all required methods defined — All three policies | Each policy defines: viewAny, view, create, update, delete, restore, forceDelete. SchoolShiftPolicy registered; TimingProfilePolicy and SchoolTimingProfilePolicy NOT registered (known naming collision issue). | — | — | ◌ |
| TC-CR19 | CR | P1 | Routes — resource + custom routes registered | Shift: route('shift.*') prefix. TimingProfile: route('timing-profile.*') prefix. SchoolTimingProfile: route('school-timing-profile.*') prefix. Each has: resource, trash, restore, forceDelete, toggleStatus routes. All map to correct controller methods. | — | — | ◌ |
| TC-CR20 | CR | P1 | View — Blade `@can` directives on tab/action buttons | Shifts tab on timetable-masters view should have corresponding `@can` directives for create/edit/delete/toggle buttons | — | — | ◌ |
| TC-CR21 | CR | P1 | Breadcrumb — routes registered in `config/breadcrumb.php` | Shift, timing-profile, school-timing-profile routes registered with correct hierarchy | — | — | ◌ |

---

## 7. Detailed Test Steps

### Code Review TC Steps

#### TC-CR01: Model `$fillable` Matches DDL Columns — SchoolShift

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `Modules\TimetableFoundation\Models\SchoolShift::$fillable` | Array contains: `code`, `name`, `description`, `default_start_time`, `default_end_time`, `ordinal`, `is_active` |
| 2 | Compare against DDL columns for `tt_shifts` | All writable columns covered; `id`, `created_at`, `updated_at`, `deleted_at` excluded |

#### TC-CR02: Model `$fillable` Matches DDL Columns — TimingProfile

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `TimingProfile` model (aliased class) `$fillable` | Array contains: `profile_code`, `name`, `total_periods`, `timezone`, `notes`, `is_active` |
| 2 | Compare against DDL columns for `tt_timing_profile` | All writable columns covered; `id`, `created_at`, `updated_at`, `deleted_at` excluded |

#### TC-CR03: Model `$fillable` Matches DDL Columns — SchoolTimingProfile

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `SchoolTimingProfile` model `$fillable` | Array contains: `profile_name`, `short_name`, `description`, `is_active` |
| 2 | Compare against DDL columns for `school_timing_profiles` | All writable columns covered; `id`, `created_at`, `updated_at`, `deleted_at` excluded |

#### TC-CR04: Model `$casts` — SchoolShift

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `SchoolShift::$casts` | `is_active` ⇒ `boolean`, `ordinal` ⇒ `integer`, `default_start_time` ⇒ `datetime`, `default_end_time` ⇒ `datetime` |

#### TC-CR05: SoftDeletes Trait — All Three Models

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect each model class | Each uses `use SoftDeletes;` |
| 2 | Call `delete()` on an active record | `deleted_at` populated; record excluded from default queries |
| 3 | Call `restore()` | `deleted_at` nullified; record reappears in default queries |

#### TC-CR06: Relationships Defined — SchoolShift

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `SchoolShift` model | `timetableTypes()` → `hasMany(TimetableType::class, 'shift_id')` defined |

#### TC-CR07: Controller — Exception Handling

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `SchoolShiftController@store()` | Try-catch or DB transaction wrapping create call |
| 2 | Inspect `SchoolShiftController@update()` | Try-catch or DB transaction wrapping update call |
| 3 | Repeat for TimingProfileController and SchoolTimingProfileController | Same pattern |

#### TC-CR08: Controller — `Gate::authorize()` Present

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect every public method across all three controllers | Each method contains `Gate::authorize('timetable-foundation.<resource>.<action>')` call |

#### TC-CR09: Activity Logged on State Changes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `SchoolShiftController` methods | `activityLog()` called in update, destroy, restore, forceDelete, toggleStatus. NOT called in store. |
| 2 | Inspect `TimingProfileController` methods | `activityLog()` called in store, update, destroy, restore, forceDelete, toggleStatus |
| 3 | Inspect `SchoolTimingProfileController` methods | `activityLog()` called in store, update, destroy, restore, forceDelete, toggleStatus |

#### TC-CR10: `is_active` Deactivation/Reactivation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `SchoolShiftController@destroy()` | `is_active=false` set before `delete()` |
| 2 | Inspect `SchoolShiftController@restore()` | `is_active=true` set after `restore()` |
| 3 | Inspect `TimingProfileController@destroy()` | No `is_active=false` before `delete()` — known inconsistency |
| 4 | Inspect `TimingProfileController@restore()` | No `is_active=true` after `restore()` — known inconsistency |
| 5 | Inspect `SchoolTimingProfileController@destroy()` | `is_active=false` set before `delete()` |
| 6 | Inspect `SchoolTimingProfileController@restore()` | No `is_active=true` after `restore()` — known inconsistency |

#### TC-CR11: `toggleStatus()` Flips `is_active`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Find an active shift record. POST `is_active=false` to toggle-status endpoint | DB record updated: `is_active=0`. JSON response: `{success: true, is_active: false, message: "..."}` |
| 2 | POST `is_active=true` | DB updated: `is_active=1`. JSON response: `{success: true, is_active: true, message: "..."}` |

#### TC-CR12: Trash/Restore/ForceDelete Flow

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft delete a SchoolShift record | DB: `is_active=0`, `deleted_at` set |
| 2 | Restore the same SchoolShift record | DB: `is_active=1`, `deleted_at=NULL` |
| 3 | Force delete the same SchoolShift record | Record removed from DB |
| 4 | Repeat for TimingProfile — note different behaviour | Delete: is_active not changed. Restore: is_active not set to true. |
| 5 | Repeat for SchoolTimingProfile | Delete: is_active set to false. Restore: is_active NOT set to true. |

#### TC-CR13: JSON Response After ToggleStatus

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send valid POST to any toggle-status endpoint | HTTP 200; JSON with `success`, `is_active`, `message` keys |
| 2 | Send invalid POST (missing `is_active`) | Validation error returned |

#### TC-CR14: Redirect After Create/Update

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a shift | Redirects to `route('timetable-foundation.menu.timetableMasters', ['tab' => 'shifts'])` |
| 2 | Create a timing profile | Redirects to `route('timetable-foundation.index')` |
| 3 | Create a school timing profile | Redirects to `route('timetable-foundation.index')` |

#### TC-CR15: TimingProfileRequest Validation Rules

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `TimingProfileRequest::rules()` | Rules defined for all 6 fields as documented in BC-VAL-T01–T06 |
| 2 | Inspect `TimingProfileRequest::prepareForValidation()` | Checkbox `"on"` → boolean; empty strings → null for timezone/notes |

#### TC-CR16: SchoolTimingProfileRequest Validation Rules

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `SchoolTimingProfileRequest::rules()` | Rules defined for all 4 fields as documented in BC-VAL-S01–S04 |
| 2 | Inspect `prepareForValidation()` | Checkbox `"on"` → boolean |

#### TC-CR17: Unique Rules Ignore Current ID On Update

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `TimingProfileRequest::rules()` | profile_code: `unique:tt_timing_profile,profile_code,{id},id` — ignores current record |
| 2 | Inspect `SchoolTimingProfileRequest::rules()` | profile_name: `unique:school_timing_profiles,profile_name,{id}` — ignores current record |

#### TC-CR18: Policy Methods Defined

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `SchoolShiftPolicy` | 6 gate methods: viewAny, view, create, update, delete, restore, forceDelete |
| 2 | Inspect `TimingProfilePolicy` | 6 gate methods; class exists but NOT registered |
| 3 | Inspect `SchoolTimingProfilePolicy` | 6 gate methods; class exists but NOT registered |

#### TC-CR19: Routes Registered

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Run `php artisan route:list \| grep shift` | Resource routes + trash/restore/forceDelete/toggleStatus for shift |
| 2 | Run `php artisan route:list \| grep timing-profile` | Resource routes + custom routes for timing-profile |
| 3 | Run `php artisan route:list \| grep school-timing-profile` | Resource routes + custom routes for school-timing-profile |

#### TC-CR20: Blade `@can` Directives

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect shifts tab Blade view in `resources/views/timetablefoundation/` | `@can('timetable-foundation.shift.create')` wrapping Create button; `@can('timetable-foundation.shift.update')` wrapping Edit/Status buttons; `@can('timetable-foundation.shift.delete')` wrapping Delete button |
| 2 | Repeat for timing-profile and school-timing-profile views | Similar `@can` directives for respective permissions |

#### TC-CR21: Breadcrumb Configuration

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `config/breadcrumb.php` | Entries for `timetable-foundation` menu, `shift.*`, `timing-profile.*`, `school-timing-profile.*` routes with correct hierarchy |

---

### 7.1 Positive TC Steps

#### TC-P01: Shifts Tab Loads With All UI Elements

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin with all `timetable-foundation.*` permissions | Dashboard loaded |
| 2 | Navigate to `GET /timetable-foundation/timetable-masters?tab=shifts` | Page loads with HTTP 200. Shifts tab pane visible. |
| 3 | Verify table header columns | Columns present: #, Code, Name, Description, Start Time, End Time, Ordinal, Status, Actions |
| 4 | Verify search input | Input with name `shift_search` visible |
| 5 | Verify status filter | Status filter dropdown with options: All (default), Active, Inactive |
| 6 | Verify Create button | "Create Shift" or "+" button visible |
| 7 | Verify seed data displayed | At least Morning (ordinal=1) and Afternoon (ordinal=2) shifts displayed in table |

#### TC-P02: Filter Shifts By Name/Code Search

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to Shifts tab | All shifts visible |
| 2 | Enter "MORNING" in search box and submit | Only Morning shift displayed |
| 3 | Enter "XYZ_NOT_EXIST" in search box and submit | No shifts displayed; empty state or "No records found" shown |
| 4 | Clear search and submit | All shifts displayed again |

#### TC-P03: Filter Shifts By Status

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure at least 1 inactive shift exists (can toggle one inactive) | — |
| 2 | Select "Inactive" from status filter | Only inactive shifts displayed |
| 3 | Select "Active" from status filter | Only active shifts displayed |
| 4 | Select "All" from status filter | All shifts (active + inactive) displayed |

#### TC-P04: Shift List Ordered By Ordinal

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | View shifts list | Rows ordered by ordinal column ascending: 1 (Morning), 2 (Afternoon), ... |
| 2 | Query DB directly | `SELECT ordinal FROM tt_shifts WHERE deleted_at IS NULL ORDER BY ordinal` confirms same order |

#### TC-P05: Create Shift With Required Fields Only

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click "Create Shift" button | Create form loaded |
| 2 | Enter code="TEST1", name="Test Shift 1", ordinal=3 | Fields filled |
| 3 | Leave description, default_start_time, default_end_time empty | Fields empty |
| 4 | Leave is_active unchecked | — |
| 5 | Click Save/Submit | POST to `/timetable-foundation/shift`. Record created. |
| 6 | Verify DB | `tt_shifts` has new record: code='TEST1', name='Test Shift 1', ordinal=3, is_active=1, default_start_time=NULL, default_end_time=NULL, description=NULL, deleted_at=NULL |
| 7 | Verify redirect | Redirected to `timetable-foundation.menu.timetableMasters?tab=shifts` with success flash message |

#### TC-P06: Create Shift With All Fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create form: code="TEST2", name="Test Shift 2", description="A test shift", default_start_time="08:00", default_end_time="16:00", ordinal=4, is_active=ON | Form valid |
| 2 | Submit | Record created |
| 3 | Verify DB | All 7 fields correctly persisted. default_start_time='08:00:00', default_end_time='16:00:00', is_active=1 |

#### TC-P07: Create Shift With `is_active=false`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create form: code="TEST3", name="Test Shift 3", ordinal=5, is_active=OFF | Form valid |
| 2 | Submit | Record created with is_active=0 |
| 3 | Verify DB | `is_active` = 0 |

#### TC-P08: View Shift Details

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | From shifts list, click View/eye icon on an existing shift | Show page loaded at `GET /timetable-foundation/shift/{id}` |
| 2 | Verify displayed fields | Code, Name, Description, Default Start Time, Default End Time, Ordinal, Active badge (green for active, red for inactive), Created At, Updated At all visible |

#### TC-P09: Edit Shift Loads Pre-Filled Data

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | From shifts list, click Edit/pencil icon on shift "Test Shift 1" | Edit form at `GET /timetable-foundation/shift/{id}/edit` |
| 2 | Verify form fields | code="TEST1", name="Test Shift 1", ordinal=3 pre-filled. Other fields blank if not set. |

#### TC-P10: Update Shift Name and Code

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Edit shift "Test Shift 1". Change code to "TEST1_UPD", name to "Test Shift 1 Updated" | — |
| 2 | Submit update (PUT) | Redirect with success flash |
| 3 | Verify DB | code='TEST1_UPD', name='Test Shift 1 Updated' |
| 4 | Verify activity log | ActivityLog entry with event 'Updated' and message 'Shift details updated' |

#### TC-P11: Toggle Shift Status Active → Inactive

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Find an active shift. Click toggle status (switch/badge) | AJAX POST to `/timetable-foundation/shift/{id}/toggle-status` with `{"is_active": false}` |
| 2 | Verify JSON response | `{"success": true, "is_active": false, "message": "..."}` |
| 3 | Verify DB | `is_active` = 0 |
| 4 | Verify activity log | Event 'Toggled' with is_active value in context |

#### TC-P12: Soft Delete Active Shift

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click Delete on an active shift | Confirmation dialog (or direct delete) |
| 2 | Confirm deletion | `is_active` set to false; record soft-deleted |
| 3 | Verify redirect | Redirected to shifts tab with success flash "Shift was deactivated and moved to trash." |
| 4 | Verify DB | Record has `is_active=0`, `deleted_at` is NOT NULL |
| 5 | Verify activity log | Event 'Trashed' with message 'Shift was deactivated and moved to trash.' |

#### TC-P13: View Trashed Shifts

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to trash via "Trash" or "Deleted Shifts" link | `GET /timetable-foundation/shift/trash/view` loads |
| 2 | Verify soft-deleted records shown | Previously deleted shifts visible with name, code, deleted_at timestamp |
| 3 | Verify action buttons | Restore and Force Delete buttons visible for each record |

#### TC-P14: Restore Soft-Deleted Shift

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | On trash view, click Restore on a soft-deleted shift | GET `/timetable-foundation/shift/{id}/restore` |
| 2 | Verify redirect | Redirected to trash with success flash "Shift was restored successfully." |
| 3 | Verify DB | `deleted_at` = NULL, `is_active` = 1 |
| 4 | Verify activity log | Event 'Restored' with message 'Shift was restored successfully.' |
| 5 | Verify shift visible in main list | Shift reappears in active shifts tab |

#### TC-P15: Force Delete Shift (No Children)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | On trash view, click Force Delete on a shift with NO dependent records | DELETE `/timetable-foundation/shift/{id}/force-delete` |
| 2 | Verify redirect | Redirected to trash with success flash |
| 3 | Verify DB | Record permanently removed from `tt_shifts` |
| 4 | Verify activity log | Event 'Deleted' with message 'Shift was permanently deleted.' |

#### TC-P16: Timing Profile Index Loads Paginated

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to `GET /timetable-foundation/timing-profile` | Page loads with HTTP 200 |
| 2 | Create 12 timing profiles | — |
| 3 | Verify page 1 shows 10 records | Pagination links visible; 10 records on page 1 |
| 4 | Click page 2 | Remaining 2 records shown |

#### TC-P17: Create Timing Profile

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to create form `GET /timetable-foundation/timing-profile/create` | Form loaded |
| 2 | Enter profile_code="PROF_A", name="Profile A", total_periods=8 | Fields filled |
| 3 | Submit | POST to `/timetable-foundation/timing-profile` |
| 4 | Verify redirect | Redirected to `timetable-foundation.index` with success flash |
| 5 | Verify DB | Record exists in `tt_timing_profile` with profile_code='PROF_A', name='Profile A', total_periods=8, is_active=1 |
| 6 | Verify activity log | Event 'Stored' with message 'A new time profile was created.' |

#### TC-P18: Update Timing Profile With All Fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to edit form for an existing timing profile | Form pre-filled with existing data |
| 2 | Change name, set timezone="Asia/Kolkata", notes="Test notes" | — |
| 3 | Submit update | PUT to `/timetable-foundation/timing-profile/{id}` |
| 4 | Verify DB | All fields updated including timezone and notes |
| 5 | Verify activity log | Event 'Updated' with `changes` array containing old/new pairs and `performed_by` = current user name |

#### TC-P19: School Timing Profile CRUD Lifecycle

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to `GET /timetable-foundation/school-timing-profile` | Index page with paginated list (10 per page) |
| 2 | Click Create; fill profile_name="School Profile A", short_name="SPA", description="Test" | Create form submits |
| 3 | Verify DB after create | Record in `school_timing_profiles` with all fields; is_active=1 |
| 4 | Edit profile_name to "School Profile A Updated" | Update succeeds; activity logged with `changes` |
| 5 | Toggle status to inactive | JSON response `{success: true, is_active: false}` |
| 6 | Delete the profile | `is_active` set to false, then soft-deleted |
| 7 | Go to trash view `GET /timetable-foundation/school-timing-profile/trash/view` | Both soft-deleted SchoolTimingProfiles AND Periods visible |
| 8 | Restore the profile | Profile restored; `deleted_at` null; `is_active` remains false (not reactivated) |
| 9 | Force delete the profile | Record permanently removed from DB |

#### TC-P20: Pagination Overflow Tests

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 11 Timing Profiles | — |
| 2 | Visit `GET /timetable-foundation/timing-profile` | Page 1 shows 10 records; pagination links show 2 pages |
| 3 | Click page 2 | Remaining 1+ record(s) displayed |

#### TC-P21: Full Lifecycle — Shift

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create shift: code="LIFECYCLE", name="Lifecycle Shift", ordinal=10 | Created: is_active=1, deleted_at=NULL |
| 2 | View shift details | Show page loads with all fields |
| 3 | Edit shift name to "Lifecycle Updated" | Updated: name changed; activity logged |
| 4 | Toggle active to inactive | is_active=0; JSON response success |
| 5 | Toggle back to active | is_active=1 |
| 6 | Soft delete the shift | is_active=0, deleted_at set |
| 7 | Restore the shift | is_active=1, deleted_at=NULL |
| 8 | Toggle to inactive | is_active=0 |
| 9 | Soft delete again | is_active=0, deleted_at set |
| 10 | Force delete the shift | Record permanently removed |

#### TC-P22: Empty State — No Shifts

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft delete all shifts or start with empty database | — |
| 2 | Visit shifts tab | Table shows "No records found" or empty state message |

---

### 7.2 Negative TC Steps

#### TC-N01–N03: Shift — Missing Required Fields

| TC ID | Step 1 | Step 2 | Expected |
|-------|--------|--------|----------|
| TC-N01 | Submit create form without `code` | — | Validation error: "The code field is required." |
| TC-N02 | Submit create form without `name` | — | Validation error: "The name field is required." |
| TC-N03 | Submit create form without `ordinal` | — | Validation error: "The ordinal field is required." |

#### TC-N04–N06: Shift — Duplicate Unique Fields

| TC ID | Step 1 | Step 2 | Expected |
|-------|--------|--------|----------|
| TC-N04 | Create shift with code="DUP" | Create second shift with code="DUP" | Validation error: "The code has already been taken." |
| TC-N05 | Create shift with name="Dup Name" | Create second shift with name="Dup Name" | Validation error: "The name has already been taken." |
| TC-N06 | Create shift with ordinal=5 | Create second shift with ordinal=5 | Validation error: "The ordinal has already been taken." |

#### TC-N10: Shift — End Time Before Start Time

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create shift: default_start_time="14:00", default_end_time="13:00" | Validation error: "The default end time must be a date after default start time." (rule `after:default_start_time`) |

#### TC-N11–N12: Shift — Invalid Time Format

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create shift: default_start_time="25:00" | Validation error on `date_format:H:i` |
| 2 | Create shift: default_end_time="abc" | Validation error on `date_format:H:i` |

#### TC-N16–N17: Timing Profile — Duplicate Unique Fields

| TC ID | Step 1 | Step 2 | Expected |
|-------|--------|--------|----------|
| TC-N16 | Create TP with profile_code="PROF_DUP" | Create second TP with profile_code="PROF_DUP" | Validation error: "The profile code has already been taken." |
| TC-N17 | Create TP with name="Dup Profile" | Create second TP with name="Dup Profile" | Validation error: "The name has already been taken." |

#### TC-N24–N25: School Timing Profile — Duplicate Unique Fields

| TC ID | Step 1 | Step 2 | Expected |
|-------|--------|--------|----------|
| TC-N24 | Create STP with profile_name="School Dup" | Create second STP with profile_name="School Dup" | Validation error: "The profile name has already been taken." |
| TC-N25 | Create first STP with short_name="SD" (nullable, so set it) | Create second STP with short_name="SD" | Validation error: "The short name has already been taken." |

#### TC-N29: Permission 403 — No `shift.viewAny`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create user without `timetable-foundation.shift.viewAny` permission | — |
| 2 | Login as that user | — |
| 3 | Navigate to `GET /timetable-foundation/timetable-masters?tab=shifts` (gate: `shift.viewAny` via `SchoolShiftController@index()`) | HTTP 403 Forbidden (or redirect with error) |

#### TC-N37: Guest Access Redirect

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Logout (guest session) | — |
| 2 | Navigate to `GET /timetable-foundation/shift` | Redirected to `/login` |

#### TC-N38: View Non-Existent Shift (404)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send GET to `/timetable-foundation/shift/99999` | HTTP 404 via `findOrFail` |

#### TC-N42: Force Delete Shift With Active PeriodConfig FK

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure a PeriodConfig record references shift_id=exists | — |
| 2 | Soft delete the shift (this succeeds) | Shift trashed |
| 3 | Attempt force delete on the trashed shift | DB exception thrown due to FK constraint `fk_pc_shift` (RESTRICT). Force delete fails. |

#### TC-N46: School Timing Profile — Soft-Deleted Name Unique Violation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create STP with profile_name="UniqueName" | Created successfully |
| 2 | Delete (soft) the STP | Record trashed |
| 3 | Create a new STP with profile_name="UniqueName" | Validation error: "The profile name has already been taken." (unique check includes soft-deleted records because no `whereNull('deleted_at')` clause) |

---

### 7.4 Dependency TC Steps

#### TC-D01: Shift — Delete Deactivates Then Soft-Delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Find an active shift. Capture `is_active` and `deleted_at` | is_active=1, deleted_at=NULL |
| 2 | Call `SchoolShiftController@destroy()` on this shift | — |
| 3 | Verify DB after destroy | is_active=0, deleted_at=timestamp (NOT NULL) |

#### TC-D02: Shift — Restore Reactivates

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Find the trashed shift from TC-D01 | — |
| 2 | Call `SchoolShiftController@restore()` | — |
| 3 | Verify DB after restore | is_active=1, deleted_at=NULL |

#### TC-D03: Timing Profile — Delete Does NOT Deactivate

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Find an active timing profile with is_active=1 | — |
| 2 | Call `TimingProfileController@destroy()` | — |
| 3 | Verify DB after destroy | is_active REMAINS 1 (unchanged), deleted_at=timestamp |

#### TC-D04: Timing Profile — Restore Does NOT Reactivate

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Find the trashed timing profile from TC-D03 (is_active=1, deleted_at=timestamp) | — |
| 2 | Call `TimingProfileController@restore()` | — |
| 3 | Verify DB after restore | is_active=1 (unchanged, was already 1), deleted_at=NULL |

#### TC-D10: DB UNIQUE — `uq_shift_code`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Insert a shift with code="DUP_CODE" directly into DB | Success |
| 2 | Insert another shift with code="DUP_CODE" directly into DB | Integrity constraint violation: Duplicate entry 'DUP_CODE' for key 'uq_shift_code' |

#### TC-D16: Activity Log — Shift CRUD

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a shift | Verify NO activityLog entry for 'Stored' (known gap — store() does not log) |
| 2 | Update the shift | ActivityLog entry: event='Updated', model='SchoolShift', message='Shift details updated' |
| 3 | Toggle the shift status | ActivityLog entry: event='Toggled', context includes is_active value |
| 4 | Soft delete the shift | ActivityLog entry: event='Trashed', message='Shift was deactivated and moved to trash.' |
| 5 | Restore the shift | ActivityLog entry: event='Restored', message='Shift was restored successfully.' |
| 6 | Force delete the shift | ActivityLog entry: event='Deleted', message='Shift was permanently deleted.' |

#### TC-D24: `findOrFail` — Invalid ID Returns 404

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send `GET /timetable-foundation/shift/99999` | 404 Not Found |
| 2 | Send `PUT /timetable-foundation/timing-profile/99999` | 404 Not Found |
| 3 | Send `DELETE /timetable-foundation/school-timing-profile/99999` | 404 Not Found (via implicit model binding) |

#### TC-D29: Known Bug — Timing Profile `timezone` and `notes` Not Persisted On Create

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create timing profile with timezone="Asia/Kolkata" and notes="Important notes" | — |
| 2 | View the created record's details | timezone=NULL, notes=NULL in DB (values silently dropped) |
| 3 | Edit the same profile and save with timezone and notes filled | This time values ARE persisted (update() includes timezone and notes in `$request->only()`) |
