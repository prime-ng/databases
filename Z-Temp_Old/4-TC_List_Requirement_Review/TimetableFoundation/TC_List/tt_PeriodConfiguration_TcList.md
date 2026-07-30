# tt_PeriodConfiguration_TcList

## Module: TimetableFoundation → Timetable Masters → Period Configuration

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | TimetableFoundation |
| Tab Group | Timetable Masters |
| Feature | Period Configuration (Period Types, Period Configs, Period Sets, Period Set Periods) |
| URL(s) | `GET timetable-foundation/timetable-masters?tab=period-types` (index via tab), `GET timetable-foundation/timetable-masters?tab=period-configs`, `GET timetable-foundation/timetable-masters?tab=period-sets`, `GET timetable-foundation/timetable-masters?tab=period-set-period` |
| | **Period Types:** `POST timetable-foundation/period-type` (store), `GET timetable-foundation/period-type/{id}` (show), `GET timetable-foundation/period-type/{id}/edit` (edit), `PUT timetable-foundation/period-type/{periodType}` (update), `DELETE timetable-foundation/period-type/{id}` (destroy), `GET timetable-foundation/period-type/trash/view` (trashed), `GET timetable-foundation/period-type/{id}/restore` (restore), `DELETE timetable-foundation/period-type/{id}/force-delete` (forceDelete), `POST timetable-foundation/period-type/{periodType}/toggle-status` (toggleStatus) |
| | **Period Configs:** `POST timetable-foundation/period-config` (store), `GET timetable-foundation/period-config/{id}` (show), `GET timetable-foundation/period-config/{id}/edit` (edit), `PUT timetable-foundation/period-config/{periodConfig}` (update), `DELETE timetable-foundation/period-config/{id}` (destroy), `GET timetable-foundation/period-config/trash/view` (trashed), `GET timetable-foundation/period-config/{id}/restore` (restore), `DELETE timetable-foundation/period-config/{id}/force-delete` (forceDelete), `POST timetable-foundation/period-config/{periodConfig}/toggle-status` (toggleStatus), `POST timetable-foundation/period-config/ajax/reorder` (ajaxReorder), `POST timetable-foundation/period-config/{periodConfig}/ajax-times` (ajaxUpdateTimes), `POST timetable-foundation/period-config/{periodConfig}/ajax-can-be-free` (ajaxToggleCanBeFree) |
| | **Period Sets:** `POST timetable-foundation/period-set` (store), `GET timetable-foundation/period-set/{id}` (show), `GET timetable-foundation/period-set/{id}/edit` (edit), `PUT timetable-foundation/period-set/{periodSet}` (update), `DELETE timetable-foundation/period-set/{id}` (destroy), `GET timetable-foundation/period-set/trash/view` (trashed), `GET timetable-foundation/period-set/{id}/restore` (restore), `DELETE timetable-foundation/period-set/{id}/force-delete` (forceDelete), `POST timetable-foundation/period-set/{periodSet}/toggle-status` (toggleStatus), `GET timetable-foundation/period-set/ajax/period-configs?shift_id={id}` (ajaxPeriodConfigs), `POST timetable-foundation/period-set/{periodSet}/ajax/sync-range` (ajaxSyncRange) |
| | **Period Set Periods:** `POST timetable-foundation/period-set-period` (store), `GET timetable-foundation/period-set-period/{id}` (show), `GET timetable-foundation/period-set-period/{id}/edit` (edit), `PUT timetable-foundation/period-set-period/{id}` (update), `DELETE timetable-foundation/period-set-period/{id}` (destroy), `GET timetable-foundation/period-set-period/trash/view` (trashed), `GET timetable-foundation/period-set-period/{id}/restore` (restore), `DELETE timetable-foundation/period-set-period/{id}/force-delete` (forceDelete), `POST timetable-foundation/period-set-period/{period}/toggle-status` (toggleStatus) |
| Controller(s) | `Modules\TimetableFoundation\Http\Controllers\PeriodTypeController`, `Modules\TimetableFoundation\Http\Controllers\PeriodConfigController`, `Modules\TimetableFoundation\Http\Controllers\PeriodSetController`, `Modules\TimetableFoundation\Http\Controllers\PeriodSetPeriodController`; screen loaded via `TimetableFoundationController@timetableMasters()` |
| Model(s) | `Modules\TimetableFoundation\Models\PeriodType` (table: `tt_period_types`), `Modules\TimetableFoundation\Models\PeriodConfig` (table: `tt_period_configs`), `Modules\TimetableFoundation\Models\PeriodSet` (table: `tt_period_sets`), `Modules\TimetableFoundation\Models\PeriodSetPeriod` (table: `tt_period_set_periods_jnt`) |
| Validation (Create/Update) | **Period Type:** Inline in `PeriodTypeController@store()` / `PeriodTypeController@update()` — no separate Form Request. **Period Config:** `PeriodConfigController::validatePayload()` helper. **Period Set:** Inline in `PeriodSetController@store()` / `PeriodSetController@update()`. **Period Set Period:** Inline in `PeriodSetPeriodController@store()` / `PeriodSetPeriodController@update()` |
| Policy(s) | `PeriodTypePolicy`, `PeriodConfigPolicy`, `PeriodSetPolicy`, `PeriodPolicy` (for PeriodSetPeriod) |
| Permissions | `timetable-foundation.period-type.{viewAny,view,create,update,delete,restore,forceDelete}`, `timetable-foundation.period-config.{viewAny,view,create,update,delete,restore,forceDelete}`, `timetable-foundation.period-set.{viewAny,view,create,update,delete,restore,forceDelete}`, `timetable-foundation.period-set-period.{viewAny,view,create,update,delete,restore,forceDelete}` |
| Pagination | Period Types: 10/page (`pa_page`), Period Configs: 25/page, Period Sets: 10/page, Period Set Periods (trashed): 20/page |
| Soft Deletes | Yes — all four models use `SoftDeletes` trait |
| Activity Log | Events: `Trashed`, `Restored`, `Deleted`, `Toggled` via `activityLog()` helper |

---

## 2. Pre-conditions

- Required permissions: All `timetable-foundation.period-type.*`, `timetable-foundation.period-config.*`, `timetable-foundation.period-set.*`, `timetable-foundation.period-set-period.*` permissions (viewAny, view, create, update, delete, restore, forceDelete)
- Required seed/reference data: At least one active `SchoolShift` (`tt_shift`); at least one active `PeriodType` for Period Config CRUD; for Period Sets, at least one active Shift and active PeriodConfigs for the same shift
- Tenant context must be initialized via `tenancy()->initialize()`
- Dusk environment variables: `DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD`
- For soft-delete tests: At least one record of each entity in the database
- For Period Set sync tests: A shift with at least 8 period configs (teaching + non-teaching) configured
- For cascade tests: A Period Set with at least one junction record

---

## 3. Default Data Load

When the Timetable Masters page loads via `TimetableFoundationController@timetableMasters()` (`GET timetable-foundation/timetable-masters`), the following data is available per tab:

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| Period Types Tab | `PeriodTypeController@index()` redirects to `timetableMasters?tab=period-types` | `PeriodType::orderBy('ordinal')` | None | 10/page (`pa_page`) |
| Period Configs Tab | `PeriodConfigController@index()` | `PeriodConfig::with('shift','periodType')->orderBy('shift_id')->orderBy('slot_ord')` | None | 25/page |
| Period Sets Tab | `PeriodSetController@index()` redirects to `timetableMasters?tab=period-sets` | `PeriodSet::orderBy('name')` | None | 10/page |
| Period Set Periods Tab | `PeriodSetPeriodController@index()` redirects to `timetableMasters?tab=period-set-period` | `PeriodSetPeriod::with('periodSet','periodType')` via global scope ordering | None | Dependent on Period Set context |
| Shared: Shifts | `PeriodConfigController@create()` / `edit()` | `SchoolShift::where('is_active',true)->orderBy('ordinal')` | is_active=true | None |
| Shared: Period Types | `PeriodConfigController@create()` / `edit()` | `PeriodType::where('is_active',true)->orderBy('ordinal')` | is_active=true | None |
| Shared: Classes | `PeriodSetController@create()` | `SchoolClass::all()` | None | None |
| Shared: Period Configs (by shift) | `PeriodSetController@edit()` | `PeriodConfig::with('periodType')->where('shift_id',X)->where('is_active',true)->ordered()` | shift_id, is_active | None |

---

## 4. Test Data Strategy

- **Unique suffix**: Use `now()->format('His')` for code/name uniqueness across test runs (e.g., `TEST_THEORY_142530`)
- **Period Type codes**: Uppercase, underscore-separated, max 30 chars; must be unique across all types (includes soft-deleted)
- **Period Type ordinals**: Must be unique (includes soft-deleted); auto-set default is 1
- **Period Config codes**: Unique per shift (scoped unique `(shift_id, code)`); non-teaching slots have `slot_ord = null`
- **Period Config slot_ord**: Unique per shift (scoped unique `(shift_id, slot_ord)`); only for teaching slots
- **Period Set codes**: Globally unique (`uq_periodset_code`); uppercase only with regex `^[A-Z0-9_]+$`
- **Period Set Period codes**: Unique per set (scoped unique `(period_set_id, code)`)
- **Period Set Period period_ord**: Unique per set (scoped unique `(period_set_id, period_ord)`)
- **Period Set Period period_config_id**: Unique per set (scoped unique `(period_set_id, period_config_id)`)
- **System records**: Some Period Types are `is_system = true` — protect `code`, `is_break`, `is_schedulable`, `counts_as_teaching`, `counts_as_workload` from modification and prevent deletion
- **Default Period Set**: Only one set can have `is_default = true` at a time
- **Pre-test cleanup**: Delete created records by code suffix before/after tests to avoid collisions
- **Cross-entity FK chain**: PeriodConfig → Shift (RESTRICT), PeriodType (RESTRICT); PeriodSet → Shift (RESTRICT); PeriodSetPeriod → PeriodSet (CASCADE), PeriodConfig (RESTRICT), PeriodType (RESTRICT)

---

## 5. Business Conditions

### 5.1 Database Schema — `tt_period_types`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | id | TINYINT UNSIGNED PK | Auto-increment |
| BC-DB-02 | code | VARCHAR(30) | NOT NULL, UNIQUE (`uq_periodtype_code`) |
| BC-DB-03 | name | VARCHAR(100) | NOT NULL |
| BC-DB-04 | description | VARCHAR(255) | DEFAULT NULL |
| BC-DB-05 | color_code | VARCHAR(10) | DEFAULT NULL |
| BC-DB-06 | icon | VARCHAR(50) | DEFAULT NULL |
| BC-DB-07 | is_schedulable | TINYINT(1) | NOT NULL DEFAULT 1 |
| BC-DB-08 | counts_as_teaching | TINYINT(1) | NOT NULL DEFAULT 0 |
| BC-DB-09 | counts_as_workload | TINYINT(1) | NOT NULL DEFAULT 0 |
| BC-DB-10 | is_break | TINYINT(1) | NOT NULL DEFAULT 0 |
| BC-DB-11 | is_free_period | TINYINT(1) | NOT NULL DEFAULT 0 |
| BC-DB-12 | ordinal | TINYINT UNSIGNED | DEFAULT 1, UNIQUE (`uq_periodtype_ordinal`) |
| BC-DB-13 | duration_minutes | INT UNSIGNED | DEFAULT 30 |
| BC-DB-14 | is_active | TINYINT(1) | NOT NULL DEFAULT 1 |
| BC-DB-15 | created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |
| BC-DB-16 | updated_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP |
| BC-DB-17 | deleted_at | TIMESTAMP | NULLABLE (soft delete) |

### 5.2 Database Schema — `tt_period_configs`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-20 | id | INT UNSIGNED PK | Auto-increment |
| BC-DB-21 | shift_id | TINYINT UNSIGNED FK | NOT NULL, FK `tt_shift.id` ON DELETE RESTRICT |
| BC-DB-22 | slot_ord | TINYINT UNSIGNED | NULL (null for non-teaching), UNIQUE `(shift_id, slot_ord)` |
| BC-DB-23 | code | VARCHAR(20) | NOT NULL, UNIQUE `(shift_id, code)` |
| BC-DB-24 | short_name | VARCHAR(50) | NOT NULL |
| BC-DB-25 | period_type_id | TINYINT UNSIGNED FK | NOT NULL, FK `tt_period_types.id` ON DELETE RESTRICT |
| BC-DB-26 | start_time | TIME | NOT NULL |
| BC-DB-27 | end_time | TIME | NOT NULL, CHECK `end_time > start_time` |
| BC-DB-28 | duration_minutes | SMALLINT UNSIGNED | GENERATED ALWAYS AS (TIMESTAMPDIFF(MINUTE, start_time, end_time)) STORED |
| BC-DB-29 | is_teaching_slot | TINYINT(1) | NOT NULL DEFAULT 0 |
| BC-DB-30 | can_be_free_period | TINYINT(1) | NOT NULL DEFAULT 0 |
| BC-DB-31 | display_order | TINYINT UNSIGNED | NOT NULL DEFAULT 1 |
| BC-DB-32 | is_active | TINYINT(1) | NOT NULL DEFAULT 1 |
| BC-DB-33 | created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |
| BC-DB-34 | updated_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP |
| BC-DB-35 | deleted_at | TIMESTAMP | NULLABLE (soft delete) |

### 5.3 Database Schema — `tt_period_sets`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-40 | id | INT UNSIGNED PK | Auto-increment |
| BC-DB-41 | code | VARCHAR(30) | NOT NULL, UNIQUE (`uq_periodset_code`) |
| BC-DB-42 | name | VARCHAR(100) | NOT NULL |
| BC-DB-43 | description | VARCHAR(255) | DEFAULT NULL |
| BC-DB-44 | shift_id | TINYINT UNSIGNED FK | NOT NULL, FK `tt_shift.id` ON DELETE RESTRICT |
| BC-DB-45 | from_period_ord | TINYINT UNSIGNED | NOT NULL |
| BC-DB-46 | to_period_ord | TINYINT UNSIGNED | NOT NULL, CHECK `to_period_ord >= from_period_ord` |
| BC-DB-47 | total_periods | TINYINT UNSIGNED | NOT NULL |
| BC-DB-48 | teaching_periods | TINYINT UNSIGNED | NOT NULL |
| BC-DB-49 | exam_periods | TINYINT UNSIGNED | NOT NULL |
| BC-DB-50 | free_periods | TINYINT UNSIGNED | NOT NULL |
| BC-DB-51 | is_default | TINYINT(1) | DEFAULT 0 |
| BC-DB-52 | is_active | TINYINT(1) | NOT NULL DEFAULT 1 |
| BC-DB-53 | created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |
| BC-DB-54 | updated_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP |
| BC-DB-55 | deleted_at | TIMESTAMP | NULLABLE (soft delete) |

### 5.4 Database Schema — `tt_period_set_periods_jnt`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-60 | id | INT UNSIGNED PK | Auto-increment |
| BC-DB-61 | period_set_id | INT UNSIGNED FK | NOT NULL, FK `tt_period_sets.id` ON DELETE CASCADE |
| BC-DB-62 | period_config_id | INT UNSIGNED FK | NOT NULL, FK `tt_period_configs.id` ON DELETE RESTRICT |
| BC-DB-63 | period_ord | TINYINT UNSIGNED | NOT NULL, UNIQUE `(period_set_id, period_ord)` |
| BC-DB-64 | code | VARCHAR(20) | NOT NULL, UNIQUE `(period_set_id, code)` |
| BC-DB-65 | short_name | VARCHAR(50) | NOT NULL |
| BC-DB-66 | period_type_id | INT UNSIGNED FK | NOT NULL, FK `tt_period_types.id` ON DELETE RESTRICT |
| BC-DB-67 | is_active | TINYINT(1) | NOT NULL DEFAULT 1 |
| BC-DB-68 | created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |
| BC-DB-69 | updated_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP |
| BC-DB-70 | deleted_at | TIMESTAMP | NULLABLE (soft delete) |

### 5.5 Validation Rules — Period Type (Create)

| BC ID | Field | Rule(s) | Error Message |
|-------|-------|---------|---------------|
| BC-VAL-01 | code | required, string, max:30, unique:tt_period_types,code (with `whereNull('deleted_at')`) | — (default Laravel message) |
| BC-VAL-02 | name | required, string, max:100 | — |
| BC-VAL-03 | description | nullable, string, max:255 | — |
| BC-VAL-04 | color_code | nullable, string, max:10, regex:/^#([A-Fa-f0-9]{6}\|[A-Fa-f0-9]{3})$/ | — |
| BC-VAL-05 | icon | nullable, string, max:50 | — |
| BC-VAL-06 | ordinal | required, integer, min:1, unique:tt_period_types,ordinal (with `whereNull('deleted_at')`) | — |
| BC-VAL-07 | is_schedulable | sometimes, boolean | — |
| BC-VAL-08 | counts_as_teaching | sometimes, boolean | — |
| BC-VAL-09 | counts_as_workload | sometimes, boolean | — |
| BC-VAL-10 | is_break | sometimes, boolean | — |
| BC-VAL-11 | is_free_period | sometimes, boolean | — |
| BC-VAL-12 | is_active | sometimes (defaults to false if unchecked) | — |
| BC-VAL-13 | **Business rule (controller)** | If `is_break` = true, force `is_schedulable=false`, `counts_as_teaching=false`, `counts_as_workload=false` | Applied silently — no user-facing message |
| BC-VAL-14 | **System flag (controller)** | On create: `is_system` forced to false | — |

### 5.6 Validation Rules — Period Type (Update)

| BC ID | Field | Rule(s) | Error Message |
|-------|-------|---------|---------------|
| BC-VAL-U01 | name | required, string, max:100 | — |
| BC-VAL-U02 | description | nullable, string, max:255 | — |
| BC-VAL-U03 | color_code | nullable, string, max:10, regex:/^#([A-Fa-f0-9]{6}\|[A-Fa-f0-9]{3})$/ | — |
| BC-VAL-U04 | icon | nullable, string, max:50 | — |
| BC-VAL-U05 | ordinal | required, integer, min:1, unique:tt_period_types,ordinal ->ignore($periodType->id) (with `whereNull('deleted_at')`) | — |
| BC-VAL-U06 | is_schedulable | sometimes, boolean | — |
| BC-VAL-U07 | counts_as_teaching | sometimes, boolean | — |
| BC-VAL-U08 | counts_as_workload | sometimes, boolean | — |
| BC-VAL-U09 | is_break | sometimes, boolean | — |
| BC-VAL-U10 | is_free_period | sometimes, boolean | — |
| BC-VAL-U11 | is_active | sometimes | — |
| BC-VAL-U12 | **System record protection** | If `$periodType->is_system`, unset `code`, `is_break`, `is_schedulable`, `counts_as_teaching`, `counts_as_workload` | Core behaviour unchanged for system records |
| BC-VAL-U13 | **Non-system break rule** | If `!$periodType->is_system && is_break`, set `is_schedulable=false`, `counts_as_teaching=false`, `counts_as_workload=false` | Applied silently |
| BC-VAL-U14 | is_system | Never allow client to change | Silently unset |

### 5.7 Validation Rules — Period Config (Create/Update via `validatePayload()`)

| BC ID | Field | Rule(s) | Error Message |
|-------|-------|---------|---------------|
| BC-VAL-20 | shift_id | required, integer, exists:tt_shifts,id | — |
| BC-VAL-21 | slot_ord | nullable, integer, min:1, max:50; unique `tt_period_configs,slot_ord` scoped `where('shift_id',$shiftId)` + `whereNull('deleted_at')` + ignore on update | — |
| BC-VAL-22 | code | required, string, max:20; unique `tt_period_configs,code` scoped `where('shift_id',$shiftId)` + `whereNull('deleted_at')` + ignore on update | — |
| BC-VAL-23 | short_name | required, string, max:50 | — |
| BC-VAL-24 | period_type_id | required, integer, exists:tt_period_types,id | — |
| BC-VAL-25 | start_time | required, date_format:H:i | — |
| BC-VAL-26 | end_time | required, date_format:H:i, after:start_time | — |
| BC-VAL-27 | is_teaching_slot | sometimes, boolean | — |
| BC-VAL-28 | can_be_free_period | sometimes, boolean | — |
| BC-VAL-29 | display_order | sometimes, integer, min:1, max:50 | — |
| BC-VAL-30 | is_active | sometimes, boolean | — |
| BC-VAL-31 | **Business rule (controller)** | If `is_teaching_slot` is false, force `slot_ord = null` and `can_be_free_period = false` | — |

### 5.8 Validation Rules — Period Set (Create)

| BC ID | Field | Rule(s) | Error Message |
|-------|-------|---------|---------------|
| BC-VAL-40 | code | required, string, max:30, regex:/^[A-Z0-9_]+$/, unique:tt_period_sets,code | — |
| BC-VAL-41 | name | required, string, max:100 | — |
| BC-VAL-42 | description | nullable, string, max:255 | — |
| BC-VAL-43 | total_periods | required, integer, min:0, max:`$maxPeriodsPerDay` (floor 15, default 20) | — |
| BC-VAL-44 | teaching_periods | required, integer, min:0, lte:total_periods | — |
| BC-VAL-45 | exam_periods | required, integer, min:0, max:20 | — |
| BC-VAL-46 | free_periods | required, integer, min:0, max:20 | — |
| BC-VAL-47 | shift_id | required, integer, exists:tt_shifts,id; custom: `to_period_ord` cannot exceed teaching slot count in shift | "To Period Ord ({$to}) cannot exceed the number of teaching slots in this shift ({$teachingCount})." |
| BC-VAL-48 | from_period_ord | required, integer, min:1, max:50 | — |
| BC-VAL-49 | to_period_ord | required, integer, min:1, max:50, gte:from_period_ord | — |
| BC-VAL-50 | applicable_class_ids | nullable, array | — |
| BC-VAL-51 | applicable_class_ids.* | integer, exists:sch_classes,id | — |
| BC-VAL-52 | period_config_ids | nullable, array | — |
| BC-VAL-53 | period_config_ids.* | integer, exists:tt_period_configs,id | — |
| BC-VAL-54 | is_default | nullable, boolean | — |
| BC-VAL-55 | is_active | nullable | — |

### 5.9 Validation Rules — Period Set (Update — additional checks)

| BC ID | Field | Rule(s) | Error Message |
|-------|-------|---------|---------------|
| BC-VAL-U40 | code | unique:tt_period_sets,code ->ignore($periodSet->id), regex:/^[A-Z0-9_]+$/ | — |
| BC-VAL-U41 | periods.*.code | required, string, max:20 | — |
| BC-VAL-U42 | periods.*.short_name | nullable, string, max:50 | — |
| BC-VAL-U43 | periods.*.period_type_id | required, integer, exists:tt_period_types,id | — |
| BC-VAL-U44 | periods.*.period_ord | required, integer, min:1, max:50 | — |
| BC-VAL-U45 | periods.*.is_active | nullable | — |
| BC-VAL-U46 | **Cross-row dedup (controller)** | Duplicate `period_ord` across submitted rows | "Period Ord {X} is duplicated within this set." |
| BC-VAL-U47 | **Cross-row dedup (controller)** | Duplicate `code` across submitted rows or vs existing DB rows | "Code \"{X}\" is already used by another period in this set." |
| BC-VAL-U48 | **Default set protection** | If `is_default`, all other sets have `is_default=false` | Applied silently |

### 5.10 Validation Rules — Period Set Period (Create/Update)

| BC ID | Field | Rule(s) | Error Message |
|-------|-------|---------|---------------|
| BC-VAL-60 | period_set_id | required, exists:tt_period_sets,id | — |
| BC-VAL-61 | period_config_id | required, exists:tt_period_configs,id | — |
| BC-VAL-62 | period_type_id | required, exists:tt_period_types,id | — |
| BC-VAL-63 | code | required, string, max:20; unique `tt_period_set_periods_jnt,code` scoped `where('period_set_id',X)` + `whereNull('deleted_at')`; ignore on update | — |
| BC-VAL-64 | short_name | nullable, string, max:10 | — |
| BC-VAL-65 | period_ord | required, integer, min:1; unique scoped `where('period_set_id',X)` + `whereNull('deleted_at')`; ignore on update | — |
| BC-VAL-66 | is_active | sometimes | — |
| BC-VAL-67 | **Shift consistency (controller)** | `periodConfig.shift_id` must match `periodSet.shift_id` | "Selected timeslot belongs to a different shift than the period set." |
| BC-VAL-68 | **Total cap (controller)** | Existing count must be < `periodSet.total_periods` | "This period set is already at its maximum of {N} period(s). You cannot add more." |

### 5.11 Authorization

| BC ID | Permission | Controller Method(s) | Behavior |
|-------|-----------|---------------------|----------|
| BC-AUTH-01 | timetable-foundation.period-type.viewAny | PeriodTypeController@index(), @show() | Without → 403 |
| BC-AUTH-02 | timetable-foundation.period-type.view | PeriodTypeController@show() | Without → 403 |
| BC-AUTH-03 | timetable-foundation.period-type.create | PeriodTypeController@create(), @store() | Without → 403 |
| BC-AUTH-04 | timetable-foundation.period-type.update | PeriodTypeController@edit(), @update(), @toggleStatus() | Without → 403 |
| BC-AUTH-05 | timetable-foundation.period-type.delete | PeriodTypeController@destroy() | Without → 403 |
| BC-AUTH-06 | timetable-foundation.period-type.restore | PeriodTypeController@restore(), @trashedPeriodType() | Without → 403 |
| BC-AUTH-07 | timetable-foundation.period-type.forceDelete | PeriodTypeController@forceDelete() | Without → 403 |
| BC-AUTH-10 | timetable-foundation.period-config.viewAny | PeriodConfigController@index() | Without → 403 |
| BC-AUTH-11 | timetable-foundation.period-config.view | PeriodConfigController@show() | Without → 403 |
| BC-AUTH-12 | timetable-foundation.period-config.create | PeriodConfigController@create(), @store() | Without → 403 |
| BC-AUTH-13 | timetable-foundation.period-config.update | PeriodConfigController@edit(), @update(), @toggleStatus(), @ajaxToggleCanBeFree(), @ajaxUpdateTimes(), @ajaxReorder() | Without → 403 |
| BC-AUTH-14 | timetable-foundation.period-config.delete | PeriodConfigController@destroy() | Without → 403 |
| BC-AUTH-15 | timetable-foundation.period-config.restore | PeriodConfigController@restore(), @trashedPeriodConfig() | Without → 403 |
| BC-AUTH-16 | timetable-foundation.period-config.forceDelete | PeriodConfigController@forceDelete() | Without → 403 |
| BC-AUTH-20 | timetable-foundation.period-set.viewAny | PeriodSetController@index(), @ajaxPeriodConfigs() | Without → 403 |
| BC-AUTH-21 | timetable-foundation.period-set.view | PeriodSetController@show() | Without → 403 |
| BC-AUTH-22 | timetable-foundation.period-set.create | PeriodSetController@create(), @store() | Without → 403 |
| BC-AUTH-23 | timetable-foundation.period-set.update | PeriodSetController@edit(), @update(), @toggleStatus(), @ajaxSyncRange() | Without → 403 |
| BC-AUTH-24 | timetable-foundation.period-set.delete | PeriodSetController@destroy() | Without → 403 |
| BC-AUTH-25 | timetable-foundation.period-set.restore | PeriodSetController@restore(), @trashedPeriodSet() | Without → 403 |
| BC-AUTH-26 | timetable-foundation.period-set.forceDelete | PeriodSetController@forceDelete() | Without → 403 |
| BC-AUTH-30 | timetable-foundation.period-set-period.viewAny | PeriodSetPeriodController@index(), @trashedPeriodSetPeriod() | Without → 403 |
| BC-AUTH-31 | timetable-foundation.period-set-period.view | PeriodSetPeriodController@show() | Without → 403 |
| BC-AUTH-32 | timetable-foundation.period-set-period.create | PeriodSetPeriodController@create(), @store() | Without → 403 |
| BC-AUTH-33 | timetable-foundation.period-set-period.update | PeriodSetPeriodController@edit(), @update(), @toggleStatus() | Without → 403 |
| BC-AUTH-34 | timetable-foundation.period-set-period.delete | PeriodSetPeriodController@destroy() | Without → 403 |
| BC-AUTH-G | Guest access | All routes | Redirect to /login |

### 5.12 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Period Type — is_break forces flag cascade | If `is_break=true`, controller sets `is_schedulable=false`, `counts_as_teaching=false`, `counts_as_workload=false` before saving |
| BC-BIZ-02 | Period Type — System record protection on update | If `is_system=true`, `code`, `is_break`, `is_schedulable`, `counts_as_teaching`, `counts_as_workload` are unset from validated data |
| BC-BIZ-03 | Period Type — System record protection on delete | If `is_system=true`, `destroy()` redirects back with error `flash('operation_failed')` |
| BC-BIZ-04 | Period Type — System record protection on forceDelete | If `is_system=true`, `forceDelete()` redirects back with error `flash('system_record_force_delete_not_allowed')` |
| BC-BIZ-05 | Period Type — System record protection on toggleStatus | If `is_system=true`, `toggleStatus()` returns JSON 403 with `flash('system_record_status_change_not_allowed')` |
| BC-BIZ-06 | Period Type — Deactivate before soft delete | `destroy()` sets `is_active=false` before calling `delete()` |
| BC-BIZ-07 | Period Type — Restore reactivates | `restore()` sets `is_active=true` after `restore()` |
| BC-BIZ-08 | Period Type — Activity log on Trashed | `activityLog()` called with event 'Trashed' on destroy |
| BC-BIZ-09 | Period Type — Activity log on Restored | `activityLog()` called with event 'Restored' on restore |
| BC-BIZ-10 | Period Type — Activity log on Deleted (forceDelete) | `activityLog()` called with event 'Deleted' on forceDelete |
| BC-BIZ-11 | Period Type — Activity log on Toggled | `activityLog()` called with event 'Toggled' on toggleStatus |
| BC-BIZ-12 | Period Config — Non-teaching slot has no slot_ord | If `is_teaching_slot=false`, `slot_ord` forced to null and `can_be_free_period=false` |
| BC-BIZ-13 | Period Config — duration_minutes is GENERATED | Column is computed as `TIMESTAMPDIFF(MINUTE, start_time, end_time)` STORED — never mass-assigned (`$guarded`) |
| BC-BIZ-14 | Period Config — ajaxReorder updates display_order only | POST to `ajaxReorder` with `ids[]` array updates `display_order` in transaction; `slot_ord` untouched |
| BC-BIZ-15 | Period Config — ajaxUpdateTimes updates start/end times | POST with `start_time` and `end_time` (format H:i, `after:start_time`); returns JSON with computed `duration_minutes` |
| BC-BIZ-16 | Period Config — ajaxToggleCanBeFree only on teaching slots | If `is_teaching_slot=false`, returns JSON 422: "Only teaching slots can be marked as free periods." |
| BC-BIZ-17 | Period Config — Deactivate before soft delete | `destroy()` sets `is_active=false` before `delete()` |
| BC-BIZ-18 | Period Config — Restore reactivates | `restore()` sets `is_active=true` after `restore()` |
| BC-BIZ-19 | Period Config — Activity log on all state changes | Events: Trashed, Restored, Deleted, Toggled |
| BC-BIZ-20 | Period Set — Default set singleton | If `is_default=true` on create/update, all other sets have `is_default=false` |
| BC-BIZ-21 | Period Set — Code uppercase normalization | `store()` and `update()` force `code = strtoupper($validated['code'])` |
| BC-BIZ-22 | Period Set — Default set protection on destroy | If `is_default=true`, `destroy()` redirects back with error `flash('default_period_set_delete_not_allowed')` |
| BC-BIZ-23 | Period Set — Default set protection on forceDelete | If `is_default=true`, `forceDelete()` redirects back with error `flash('default_period_set_force_delete_not_allowed')` |
| BC-BIZ-24 | Period Set — Default set protection on toggleStatus | If `is_default=true` and toggling to inactive, returns JSON 403 with `flash('default_period_set_disable_not_allowed')` |
| BC-BIZ-25 | Period Set — Deactivate before soft delete | `destroy()` sets `is_active=false` before `delete()` |
| BC-BIZ-26 | Period Set — Restore reactivates | `restore()` sets `is_active=true` after `restore()` |
| BC-BIZ-27 | Period Set — Auto-create junction rows on create | If `period_config_ids` provided, `syncPeriodSetPeriods()` wipes and rebuilds junction from selected configs |
| BC-BIZ-28 | Period Set — Picker membership sync on update | If `selected_period_config_ids` submitted, `syncPickerMembership()` diffs current vs selected; force-deletes removed, creates new |
| BC-BIZ-29 | Period Set — Auto-add in range on update | If picker NOT submitted, `autoAddInRangeConfigs()` adds configs falling in `(from_period_ord..to_period_ord)` range |
| BC-BIZ-30 | Period Set — Derived counters sync from junction | After update, `syncDerivedCountersFromJunction()` recomputes total_periods, teaching_periods, from/to_period_ord from junction contents |
| BC-BIZ-31 | Period Set — Two-pass period_ord update | Uses park values above max in Pass 1, final ordinals in Pass 2 to avoid unique constraint collisions during swaps |
| BC-BIZ-32 | Period Set — ajaxPeriodConfigs returns configs for a shift | GET with `shift_id` returns JSON with `configs` array, `teaching_slot_count`, and `in_range` flag per config |
| BC-BIZ-33 | Period Set — ajaxSyncRange persists from/to and auto-adds | POST with new `from_period_ord`/`to_period_ord`; updates set and auto-adds newly-in-range configs; returns JSON with `added` count |
| BC-BIZ-34 | Period Set — Activity log on all state changes | Events: Trashed, Restored, Deleted, Toggled |
| BC-BIZ-35 | Period Set Period — Shift consistency check | `periodConfig.shift_id` must equal `periodSet.shift_id` at store/update; mismatch returns validation error |
| BC-BIZ-36 | Period Set Period — Total period cap | Cannot add period when existing count >= `periodSet.total_periods` |
| BC-BIZ-37 | Period Set Period — Code uppercase normalization | `store()` and `update()` force `code = strtoupper($validated['code'])` |
| BC-BIZ-38 | Period Set Period — Soft delete (no deactivate step) | `destroy()` calls `delete()` directly without setting `is_active=false` |
| BC-BIZ-39 | Period Set Period — AJAX delete support | If `request()->expectsJson()`, returns JSON `{success:true, message:'Period removed successfully.'}` |
| BC-BIZ-40 | Period Set Period — Timing delegated to PeriodConfig | `start_time`, `end_time`, `duration_minutes` are accessors reading from `periodConfig` relationship (v7.7 design) |
| BC-BIZ-41 | Screen loads via TimetableFoundationController@timetableMasters() at GET timetable-foundation/timetable-masters with `tab` parameter | Navigating to the Timetable Masters page loads all four tabs; each tab's data is fetched via respective controller |

### 5.13 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|------------------|----------------|
| BC-REF-01 | tt_period_configs.shift_id | tt_shift (id) | RESTRICT |
| BC-REF-02 | tt_period_configs.period_type_id | tt_period_type (id) | RESTRICT |
| BC-REF-03 | tt_period_sets.shift_id | tt_shift (id) | RESTRICT |
| BC-REF-04 | tt_period_set_periods_jnt.period_set_id | tt_period_set (id) | CASCADE |
| BC-REF-05 | tt_period_set_periods_jnt.period_config_id | tt_period_configs (id) | RESTRICT |
| BC-REF-06 | tt_period_set_periods_jnt.period_type_id | tt_period_type (id) | RESTRICT |

---

## 6. Test Case List

### 6.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | Period Types Tab — Page Loads With All UI Elements | Page loads with `tab=period-types`, Add Period Type button, period types grid with all columns, actions (View/Edit/Delete/Toggle) | — | — | ⬜ |
| TC-P02 | Period Configs Tab — Page Loads With All UI Elements | Page loads with `tab=period-configs`, Add Period Config button, configs grid with shift/period type/times displayed | — | — | ⬜ |
| TC-P03 | Period Sets Tab — Page Loads With All UI Elements | Page loads with `tab=period-sets`, Add Period Set button, sets grid with shift/period counts | — | — | ⬜ |
| TC-P04 | Create Period Type With All Required Fields | Period type created with code, name, ordinal; saved with default flags (is_schedulable=1, non-break) | — | — | ⬜ |
| TC-P05 | Create Period Type With All Flags Set | Period type created with `is_schedulable=true`, `counts_as_teaching=true`, `counts_as_workload=true`, `is_break=false`, `is_free_period=true` | — | — | ⬜ |
| TC-P06 | Create Period Type With Break Flag | Period type created with `is_break=true`; auto-forces `is_schedulable=false`, `counts_as_teaching=false`, `counts_as_workload=false` | — | — | ⬜ |
| TC-P07 | Create Period Type With Color Code And Icon | Color code `#FF5733` and icon `fa-solid fa-chalkboard-teacher` saved correctly | — | — | ⬜ |
| TC-P08 | Create Period Type With Custom Duration | `duration_minutes=45` saved correctly | — | — | ⬜ |
| TC-P09 | Edit Period Type Loads Pre-Filled Data | Edit form shows existing period type data with all fields populated | — | — | ⬜ |
| TC-P10 | Update Period Type Name And Code (Non-System) | Name and code updated on a non-system period type | — | — | ⬜ |
| TC-P11 | Update Period Type — System Record Cannot Change Core Attributes | Update system record changes only name/description/icon/color/is_active; code and core booleans silently ignored | — | — | ⬜ |
| TC-P12 | View Period Type Details | Show page displays period type name, code, color, icon, all boolean flags, ordinal, duration | — | — | ⬜ |
| TC-P13 | Create Period Config With Complete Data | Period config created with shift, code, short_name, period_type, start_time, end_time, is_teaching_slot=true, slot_ord=1 | — | — | ⬜ |
| TC-P14 | Create Period Config As Non-Teaching Slot | `is_teaching_slot=false`; system forces `slot_ord=null`, `can_be_free_period=false` | — | — | ⬜ |
| TC-P15 | Create Period Config With Can Be Free Period Flag | Teaching slot created with `can_be_free_period=true` | — | — | ⬜ |
| TC-P16 | Edit Period Config Loads Pre-Filled Data | Edit form shows existing period config with shift, period type, times | — | — | ⬜ |
| TC-P17 | Update Period Config Times | Update start/end times; duration_minutes auto-recalculates via GENERATED column | — | — | ⬜ |
| TC-P18 | View Period Config Details | Show page displays shift, code, short_name, period type, start_time, end_time, duration, flags | — | — | ⬜ |
| TC-P19 | AJAX Reorder Period Configs | POST to `ajaxReorder` with ordered IDs array updates display_order for all configs | — | — | ⬜ |
| TC-P20 | AJAX Update Times Inline | POST to `ajaxUpdateTimes` with start_time=08:00 and end_time=08:45 returns JSON with new times and computed duration_minutes | — | — | ⬜ |
| TC-P21 | AJAX Toggle Can Be Free Period | POST to `ajaxToggleCanBeFree` toggles `can_be_free_period` on teaching slot; returns JSON success | — | — | ⬜ |
| TC-P22 | Toggle Period Config Status Active ↔ Inactive | `is_active` flips; config hidden from dropdowns when inactive | — | — | ⬜ |
| TC-P23 | Create Period Set With Complete Data | Period set created with code, name, shift, from/to period ord, total/teaching/exam/free period counts | — | — | ⬜ |
| TC-P24 | Create Period Set As Default | Period set created with `is_default=true`; any existing default set downgraded to `is_default=false` | — | — | ⬜ |
| TC-P25 | Create Period Set With Applicable Classes | `applicable_class_ids` stores JSON array of class IDs (if column exists) | — | — | ⬜ |
| TC-P26 | Create Period Set With Auto-Created Junction Rows | `period_config_ids` selected triggers `syncPeriodSetPeriods()` which creates junction records | — | — | ⬜ |
| TC-P27 | Edit Period Set Loads Pre-Filled Data | Edit form shows period set with shift, from/to ord, counts, junction rows | — | — | ⬜ |
| TC-P28 | Update Period Set Basic Fields | Update name, description, counts; fields persist correctly | — | — | ⬜ |
| TC-P29 | Update Period Set — Change From/To Ord With Auto-Add | Widen `from_period_ord`/`to_period_ord` range; `autoAddInRangeConfigs()` creates new junction rows | — | — | ⬜ |
| TC-P30 | Update Period Set — Picker Membership Sync | Check/uncheck configs in picker; removed rows force-deleted, added rows created | — | — | ⬜ |
| TC-P31 | Update Period Set — Per-Row Overrides (Code, Period Type) | Inline edit of junction rows updates code, short_name, period_type_id, is_active per row | — | — | ⬜ |
| TC-P32 | Update Period Set — Swap Period Ordinals | Two rows with ordinals 2 and 3 swapped; park-and-reassign algorithm avoids unique constraint violation | — | — | ⬜ |
| TC-P33 | Update Period Set — Derived Counters Synced After Save | After update, total_periods, teaching_periods, from_period_ord, to_period_ord recomputed from actual junction contents | — | — | ⬜ |
| TC-P34 | View Period Set Details | Show page displays code, name, shift, period range, counts, list of member periods | — | — | ⬜ |
| TC-P35 | AJAX Fetch Period Configs For Shift | GET `ajaxPeriodConfigs?shift_id=X` returns JSON with configs array, each tagged with `in_range`, and `teaching_slot_count` | — | — | ⬜ |
| TC-P36 | AJAX Sync Range Inline | POST `ajaxSyncRange` with new from/to ordinals updates set and auto-adds new configs; returns JSON with `added` count | — | — | ⬜ |
| TC-P37 | Toggle Period Set Status Active ↔ Inactive | `is_active` flips; JSON success response returned | — | — | ⬜ |
| TC-P38 | Create Period Set Period Independently | POST to `period-set-period/store` with period_set_id, period_config_id, period_type_id, code, period_ord creates junction record | — | — | ⬜ |
| TC-P39 | Edit Period Set Period | Update code, short_name, period_type_id, period_ord, is_active | — | — | ⬜ |
| TC-P40 | View Period Set Period Details | Show page displays period set, period config, period type, code, ord, active status | — | — | ⬜ |
| TC-P41 | Toggle Period Set Period Status | `is_active` flips; JSON success | — | — | ⬜ |
| TC-P42 | Full Lifecycle: Create Period Type → Config → Set → Period → Edit → Toggle → Delete | All transitions succeed across the data chain; referential integrity maintained at each step | — | — | ⬜ |
| TC-P43 | Empty State — No Period Types Configured | Grid shows "No period types found" with Add button visible | — | — | ⬜ |
| TC-P44 | Empty State — No Period Configs | Grid shows empty state message | — | — | ⬜ |
| TC-P45 | Empty State — No Period Sets | Grid shows "No period sets found" with Add button visible | — | — | ⬜ |

### 6.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | Period Type — Missing `code` | Validation error: "The code field is required." | — | — | ⬜ |
| TC-N02 | Period Type — Missing `name` | Validation error: "The name field is required." | — | — | ⬜ |
| TC-N03 | Period Type — Duplicate `code` (including soft-deleted) | Validation error on unique:tt_period_types,code | — | — | ⬜ |
| TC-N04 | Period Type — Duplicate `ordinal` | Validation error on unique:tt_period_types,ordinal | — | — | ⬜ |
| TC-N05 | Period Type — `code` > 30 Characters | Validation error on code.max | — | — | ⬜ |
| TC-N06 | Period Type — `name` > 100 Characters | Validation error on name.max | — | — | ⬜ |
| TC-N07 | Period Type — Invalid `color_code` Format (Not Hex) | Regex validation fails for invalid hex color | — | — | ⬜ |
| TC-N08 | Period Type — Delete System Record | Redirect back with error `flash('operation_failed')` | — | — | ⬜ |
| TC-N09 | Period Type — Force Delete System Record | Redirect back with error `flash('system_record_force_delete_not_allowed')` | — | — | ⬜ |
| TC-N10 | Period Type — Toggle Status On System Record | JSON 403 with `flash('system_record_status_change_not_allowed')` | — | — | ⬜ |
| TC-N11 | Period Config — Missing `shift_id` | Validation error: "The shift id field is required." | — | — | ⬜ |
| TC-N12 | Period Config — Missing `code` | Validation error: "The code field is required." | — | — | ⬜ |
| TC-N13 | Period Config — Duplicate `code` Within Same Shift | Validation error on unique scoped (shift_id, code) | — | — | ⬜ |
| TC-N14 | Period Config — Duplicate `slot_ord` Within Same Shift | Validation error on unique scoped (shift_id, slot_ord) | — | — | ⬜ |
| TC-N15 | Period Config — `start_time` After `end_time` | Validation error: "The end time must be a date after start time." | — | — | ⬜ |
| TC-N16 | Period Config — Invalid FK `shift_id` | Validation error: "The selected shift id is invalid." | — | — | ⬜ |
| TC-N17 | Period Config — Invalid FK `period_type_id` | Validation error: "The selected period type id is invalid." | — | — | ⬜ |
| TC-N18 | Period Config — Delete Config With Junction Records (RESTRICT) | Cannot delete period config referenced by junction; FK constraint violation | — | — | ⬜ |
| TC-N19 | Period Config — AJAX Toggle CanBeFree On Non-Teaching Slot | JSON 422: "Only teaching slots can be marked as free periods." | — | — | ⬜ |
| TC-N20 | Period Config — AJAX Update Times With Invalid Format | Validation error on date_format:H:i | — | — | ⬜ |
| TC-N21 | Period Config — AJAX Reorder With Non-Existent ID | Validation error on exists:tt_period_configs,id | — | — | ⬜ |
| TC-N22 | Period Set — Missing `code` | Validation error: "The code field is required." | — | — | ⬜ |
| TC-N23 | Period Set — Code With Invalid Characters (e.g., spaces, hyphens) | Regex `/^[A-Z0-9_]+$/` fails; validation error | — | — | ⬜ |
| TC-N24 | Period Set — Duplicate `code` | Validation error on unique:tt_period_sets,code | — | — | ⬜ |
| TC-N25 | Period Set — `to_period_ord` < `from_period_ord` | Validation error on gte:from_period_ord | — | — | ⬜ |
| TC-N26 | Period Set — `to_period_ord` Exceeds Teaching Slot Count | Custom validation fails: "To Period Ord ({$to}) cannot exceed the number of teaching slots in this shift ({$teachingCount})." | — | — | ⬜ |
| TC-N27 | Period Set — `teaching_periods` > `total_periods` | Validation error on lte:total_periods | — | — | ⬜ |
| TC-N28 | Period Set — `exam_periods` > 20 | Validation error on max:20 | — | — | ⬜ |
| TC-N29 | Period Set — Delete Default Set | Redirect back with error `flash('default_period_set_delete_not_allowed')` | — | — | ⬜ |
| TC-N30 | Period Set — Force Delete Default Set | Redirect back with error `flash('default_period_set_force_delete_not_allowed')` | — | — | ⬜ |
| TC-N31 | Period Set — Toggle Default Set To Inactive | JSON 403: `flash('default_period_set_disable_not_allowed')` | — | — | ⬜ |
| TC-N32 | Period Set — Update With Duplicate Period Ord In Rows | Cross-row dedup catches duplicate; back with error "Period Ord {X} is duplicated within this set." | — | — | ⬜ |
| TC-N33 | Period Set — Update With Duplicate Code In Rows | Cross-row dedup catches duplicate; back with error "Code \"{X}\" is already used by another period in this set." | — | — | ⬜ |
| TC-N34 | Period Set Period — Duplicate `code` Within Same Set | Validation error on unique scoped (period_set_id, code) | — | — | ⬜ |
| TC-N35 | Period Set Period — Duplicate `period_ord` Within Same Set | Validation error on unique scoped (period_set_id, period_ord) | — | — | ⬜ |
| TC-N36 | Period Set Period — Shift Mismatch (Config Belongs To Different Shift) | "Selected timeslot belongs to a different shift than the period set." | — | — | ⬜ |
| TC-N37 | Period Set Period — Exceed Total Period Cap | "This period set is already at its maximum of {N} period(s). You cannot add more." | — | — | ⬜ |
| TC-N38 | Permission 403 — No Timetable Foundation Permissions | 403 Forbidden on all CRUD endpoints for user without any `timetable-foundation.*` gates | — | — | ⬜ |
| TC-N39 | Guest Access Redirect | Redirected to /login for all period configuration routes | — | — | ⬜ |
| TC-N40 | Non-Existent Record — 404 On Show/Edit/Update/Destroy | ModelNotFoundException returns 404 for invalid IDs | — | — | ⬜ |
| TC-N41 | Period Type — Whitespace-Only Name | Required validation catches whitespace-only string | — | — | ⬜ |
| TC-N42 | Period Set — Code With Lowercase (Should Pass, Gets Uppercased) | `code` stored as uppercase after normalization | — | — | ⬜ |
| TC-N43 | Period Config — `display_order` > 50 | Validation error on max:50 | — | — | ⬜ |
| TC-N44 | Period Set — Missing `shift_id` | Validation error: "The shift id field is required." | — | — | ⬜ |
| TC-N45 | Period Set Period — Missing `period_set_id` | Validation error: "The period set id field is required." | — | — | ⬜ |

### 6.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|-----------------|---------|---------|--------|
| TC-D01 | A | Period Type — Break Flag Forces Cascading Flags | Creating type with `is_break=true` results in `is_schedulable=false`, `counts_as_teaching=false`, `counts_as_workload=false` | — | — | ⬜ |
| TC-D02 | B | Period Type — System Record Core Attribute Protection | System record's `code`, `is_break`, `is_schedulable`, `counts_as_teaching`, `counts_as_workload` unchanged after update | — | — | ⬜ |
| TC-D03 | C | Period Type — Soft Delete Cascades is_active=false + deleted_at | `destroy()` sets `is_active=false` then `deleted_at`; record retrievable via `onlyTrashed()` | — | — | ⬜ |
| TC-D04 | C | Period Type — Restore Resets is_active=true and nulls deleted_at | `restore()` sets `deleted_at=null` and `is_active=true` | — | — | ⬜ |
| TC-D05 | D | Period Config — Non-Teaching Slot Forces slot_ord=null | Saving with `is_teaching_slot=false` results in `slot_ord=null` and `can_be_free_period=false` | — | — | ⬜ |
| TC-D06 | D | Period Config — duration_minutes Is Generated Column | `start=08:00`, `end=08:45` → `duration_minutes=45`; cannot be mass-assigned (guarded) | — | — | ⬜ |
| TC-D07 | E | Period Config — ajaxReorder Within Transaction | All display_order updates succeed or none; consistent DB state | — | — | ⬜ |
| TC-D08 | F | Period Config — ajaxUpdateTimes Recalculates Duration | Changing start from 08:00 to 08:15 (end=08:45) results in duration_minutes=30 in response | — | — | ⬜ |
| TC-D09 | G | Period Set — Default Set Singleton Enforcement | Setting `is_default=true` on Set B auto-sets Set A's `is_default=false` | — | — | ⬜ |
| TC-D10 | H | Period Set — Create Auto-Syncs Junction From Configs | After create with `period_config_ids=[5,6,7]`, junction rows exist with correct period_ord sequence | — | — | ⬜ |
| TC-D11 | I | Period Set — Update Picker Sync Removes Unchecked Rows | Unchecking Config B in picker results in Config B force-deleted from junction | — | — | ⬜ |
| TC-D12 | I | Period Set — Update Picker Sync Adds Newly Checked Rows | Checking Config C creates new junction row with auto-assigned period_ord | — | — | ⬜ |
| TC-D13 | J | Period Set — Auto-Add In Range On Range Widen | Changing `to_period_ord` from 8 to 10 auto-adds configs with slot_ord 9 and 10 | — | — | ⬜ |
| TC-D14 | K | Period Set — Two-Pass Ord Swap Avoids Unique Violation | Swapping ordinals 2<->3 succeeds; unique constraint not violated | — | — | ⬜ |
| TC-D15 | L | Period Set — Derived Counters Recalculated After Sync | After picker sync, `total_periods` and `teaching_periods` match actual junction counts | — | — | ⬜ |
| TC-D16 | M | Period Set — Activity Logged After State Changes | Activity log entries created for Trashed/Restored/Deleted/Toggled | — | — | ⬜ |
| TC-D17 | N | Period Set Period — Shift Consistency Enforced | Creating with config from different shift returns error | — | — | ⬜ |
| TC-D18 | N | Period Set Period — Cap Enforcement | Adding 9th period to set with total_periods=8 returns cap error | — | — | ⬜ |
| TC-D19 | O | Shift Deletion Blocked By Period Config (RESTRICT) | Cannot delete shift referenced by period configs | — | — | ⬜ |
| TC-D20 | O | Period Type Deletion Blocked By Period Config (RESTRICT) | Cannot delete period type referenced by period configs | — | — | ⬜ |
| TC-D21 | P | Period Set Deletion Cascades To Junction Records (CASCADE) | Deleting period set auto-deletes all its `tt_period_set_periods_jnt` records | — | — | ⬜ |
| TC-D22 | O | Period Config Deletion Blocked By Junction (RESTRICT) | Cannot delete period config referenced by `tt_period_set_periods_jnt` | — | — | ⬜ |
| TC-D23 | O | Period Type Deletion Blocked By Period Set Period (RESTRICT) | Cannot delete period type referenced by `tt_period_set_periods_jnt` | — | — | ⬜ |
| TC-D24 | Q | Cross-Module — ClassTimetableType references PeriodSet | Period set deletion may be blocked by `tt_class_timetable_type_jnt.period_set_id` FK | — | — | ⬜ |
| TC-D25 | R | DB — tt_period_types Unique Constraints | Duplicate `code` or `ordinal` at DB level throws integrity violation | — | — | ⬜ |
| TC-D26 | S | DB — tt_period_configs Composite Uniques | Duplicate `(shift_id, slot_ord)` or `(shift_id, code)` throws integrity violation | — | — | ⬜ |
| TC-D27 | T | DB — tt_period_sets Unique Constraint | Duplicate `code` at DB level throws integrity violation | — | — | ⬜ |
| TC-D28 | U | DB — tt_period_set_periods_jnt Composite Uniques | Duplicate `(period_set_id, period_ord)`, `(period_set_id, code)`, or `(period_set_id, period_config_id)` throws integrity violation | — | — | ⬜ |
| TC-D29 | V | DB — tt_period_configs CHECK end_time > start_time | Direct DB insert with `start_time=09:00, end_time=08:00` fails constraint | — | — | ⬜ |
| TC-D30 | W | DB — tt_period_sets CHECK to>=from | Direct DB insert with `from=10, to=5` fails constraint | — | — | ⬜ |
| TC-D31 | X | Unit — PeriodType SoftDeletes Trait | `delete()` sets `deleted_at`; `restore()` nullifies; `onlyTrashed()` filters deleted | — | — | ⬜ |
| TC-D32 | Y | Unit — PeriodConfig $casts Verification | `is_teaching_slot`, `can_be_free_period`, `is_active` cast to boolean; `slot_ord` to integer | — | — | ⬜ |
| TC-D33 | Z | Unit — PeriodSet Relationships | `shift()`, `periods()`, `periodSetPeriods()`, `periodConfigs()` return correct model types | — | — | ⬜ |
| TC-D34 | AA | Unit — PeriodSetPeriod Delegated Accessors | `start_time`/`end_time`/`duration_minutes` read from `periodConfig` relationship | — | — | ⬜ |
| TC-D35 | AB | Integration — findOrFail Returns 404 on Invalid ID | Non-existent ID for show/edit/update/destroy returns 404 for all controllers | — | — | ⬜ |
| TC-D36 | AC | Integration — Gate::authorize() Before All Operations | Each controller method calls Gate::authorize() before processing; 403 w/o permissions | — | — | ⬜ |
| TC-D37 | AD | Integration — activityLog After State Changes | Log entry contains entity ID, event name, message for all state changes | — | — | ⬜ |
| TC-D38 | AE | Unit — PeriodTypeController Break Cascade Logic | Controller forces is_schedulable=0, counts_as_teaching=0, counts_as_workload=0 when is_break=1 | — | — | ⬜ |
| TC-D39 | AF | Unit — PeriodSetController Default Singleton Logic | Creating set with is_default=true runs `PeriodSet::where('is_default',true)->update(['is_default'=>false])` first | — | — | ⬜ |
| TC-D40 | AG | Unit — syncDerivedCountersFromJunction Logic | After junction change, `total_periods` = count of rows; `teaching_periods` = count where `periodType.counts_as_teaching` or `periodConfig.is_teaching_slot` | — | — | ⬜ |
| TC-D41 | AH | Integration — All Custom Routes Registered | Every AJAX, trash, restore, forceDelete, toggleStatus route resolves to correct controller method | — | — | ⬜ |
| TC-D42 | AI | Integration — System Record Force Delete Protection Flow | System record's `is_system=1` blocks forceDelete; redirect with error message | — | — | ⬜ |
| TC-D43 | AJ | Unit — PeriodSet Two-Pass Period Ord Update | Park values set above max ord, then final ordinals written; unique constraint not violated during swap | — | — | ⬜ |
| TC-D44 | AK | Integration — ajaxSyncRange Auto-Add In Range | Widening range via ajaxSyncRange auto-adds new configs; returns JSON with count | — | — | ⬜ |
| TC-D45 | AL | Cross-Module — Slot Requirement Derived From Period Set | `tt_slot_requirement` records derive period counts from assigned period set | — | — | ⬜ |

### 6.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|-----------------|---------|---------|--------|
| TC-CR01 | CR | P1 | Model — PeriodType `$fillable` Matches DDL Columns | `$fillable` includes all mutable columns: code, name, description, color_code, icon, is_schedulable, counts_as_teaching, counts_as_workload, is_break, is_free_period, ordinal, duration_minutes, is_active, created_by | — | — | ◌ |
| TC-CR02 | CR | P1 | Model — PeriodConfig `$fillable` Matches DDL Columns | `$fillable` includes shift_id, slot_ord, code, short_name, can_be_free_period, period_type_id, start_time, end_time, is_teaching_slot, display_order, is_active; duration_minutes is `$guarded` | — | — | ◌ |
| TC-CR03 | CR | P1 | Model — PeriodSet `$fillable` Matches DDL Columns | `$fillable` includes code, name, description, shift_id, from_period_ord, to_period_ord, total_periods, teaching_periods, exam_periods, free_periods, is_default, is_active | — | — | ◌ |
| TC-CR04 | CR | P1 | Model — PeriodSetPeriod `$fillable` Matches DDL Columns | `$fillable` includes period_set_id, period_config_id, period_ord, code, short_name, period_type_id, is_active | — | — | ◌ |
| TC-CR05 | CR | P1 | Model — All Four Models Have Correct `$casts` | Boolean casts for `is_active`, `is_schedulable`, `counts_as_teaching`, `is_break`, `is_free_period`; integer casts for ordinals, durations; datetime casts for timestamps | — | — | ◌ |
| TC-CR06 | CR | P1 | Model — SoftDeletes Trait Correctly Implemented | All four models use `SoftDeletes` trait; `deleted_at` in `$casts` as 'datetime' | — | — | ◌ |
| TC-CR07 | CR | P1 | Model — All Eloquent Relationships Defined | PeriodConfig: shift(), periodType(), periodSetPeriods(); PeriodSet: timetables(), periods(), periodSetPeriods(), periodConfigs(), shift(), classModeRules(); PeriodSetPeriod: periodSet(), periodConfig(), periodType(); PeriodType: periodSetPeriods() | — | — | ◌ |
| TC-CR08 | CR | P1 | Controller — Gate::authorize() On Every Method | All CRUD, AJAX, and custom methods in all four controllers call Gate::authorize() before processing | — | — | ◌ |
| TC-CR09 | CR | P1 | Controller — Activity Logged On All State Changes | `activityLog()` called on destroy, restore, forceDelete, toggleStatus for all entities | — | — | ◌ |
| TC-CR10 | CR | P1 | Controller — `is_active=false` Before Soft Delete | PeriodType, PeriodConfig, PeriodSet controllers set `is_active=false` before `delete()`; PeriodSetPeriod does not | — | — | ◌ |
| TC-CR11 | CR | P1 | Controller — Restore Sets `is_active=true` | PeriodType, PeriodConfig, PeriodSet restore methods set `is_active=true` after `restore()` | — | — | ◌ |
| TC-CR12 | CR | P1 | Controller — `toggleStatus()` Flips `is_active` | All toggleStatus methods accept `is_active` boolean, update record, return JSON success/failure | — | — | ◌ |
| TC-CR13 | CR | P1 | Controller — Trash/Restore/ForceDelete Flow | All controllers have trashed listing, restore, forceDelete; trashed uses `onlyTrashed()`, forceDelete uses `withTrashed()` | — | — | ◌ |
| TC-CR14 | CR | P1 | Controller — JSON Response Or Redirect After Write | Create/update redirect with flash message; AJAX endpoints return JSON `{success:true/false}`; delete returns redirect or JSON | — | — | ◌ |
| TC-CR15 | CR | P1 | Validation — Unique Ignores Current ID On Update | Code/ordinal uniqueness ignores own ID via `->ignore($id)` on update for all entities | — | — | ◌ |
| TC-CR16 | CR | P1 | Validation — Period Set Cross-Row Dedup | Controller validates period_ord and code uniqueness across submitted rows + existing DB rows via `$seenOrds`/`$seenCodes` before saving | — | — | ◌ |
| TC-CR17 | CR | P1 | Policy — All Required Methods Defined | Each policy defines viewAny, view, create, update, delete, restore, forceDelete methods; permission strings match gate names | — | — | ◌ |
| TC-CR18 | CR | P1 | Routes — Resource + Custom Routes Registered | All four resources registered; custom routes for trashed, restore, forceDelete, toggleStatus, AJAX endpoints registered before resource routes | — | — | ◌ |
| TC-CR19 | CR | P1 | Database — Unique Indexes Match Validation Rules | `uq_periodtype_code`, `uq_periodtype_ordinal`, `uq_pc_shift_ord`, `uq_pc_shift_code`, `uq_periodset_code`, `uq_psp_set_ord`, `uq_psp_set_code`, `uq_psp_set_config` all match validation unique rules | — | — | ◌ |
| TC-CR20 | CR | P1 | PeriodConfig — DB Transaction On ajaxReorder | `ajaxReorder()` wraps display_order updates in `DB::transaction()` | — | — | ◌ |
| TC-CR21 | CR | P1 | PeriodSet — DB Transaction On Junction Writes | `syncPeriodSetPeriods()`, `syncPickerMembership()`, `autoAddInRangeConfigs()` all use `DB::transaction()` | — | — | ◌ |
| TC-CR22 | CR | P1 | PeriodSet — Inline Period Update Uses DB Transaction | update() wraps park-and-reassign + field updates in `DB::transaction()` with try-catch for QueryException | — | — | ◌ |
| TC-CR23 | CR | P1 | PeriodSet — QueryException Handling for Integrity Violations | Catches SQLSTATE 23000; maps `uq_psp_set_code` and `uq_psp_set_period_ord` to user-friendly error messages | — | — | ◌ |
| TC-CR24 | CR | P1 | Model — PeriodSetPeriod Global Scope for Ordering | Global scope `ordered` applies: shift_id ASC, display_order ASC, slot_ord ASC, period_ord ASC via correlated subqueries | — | — | ◌ |
| TC-CR25 | CR | P1 | PeriodSet — maxPeriodsPerDay Floor Logic | `maxPeriodsPerDay = max((int)Config::get('total_number_of_period_per_day', 20), 15)` — never below 15 | — | — | ◌ |

---

## 7. Detailed Test Steps

#### TC-CR01: Model — PeriodType `$fillable` Matches DDL Columns

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `PeriodType.php` model | File found in `Modules/TimetableFoundation/Models/` |
| 2 | Inspect `$fillable` array | Contains: code, name, description, color_code, icon, is_schedulable, counts_as_teaching, counts_as_workload, is_break, is_free_period, ordinal, duration_minutes, is_active, created_by |
| 3 | Cross-check against DDL `tt_period_types` columns | All mutable columns present; no extra columns in fillable not in DDL |

#### TC-CR02: Model — PeriodConfig `$fillable` Matches DDL Columns

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `PeriodConfig.php` model | File found |
| 2 | Inspect `$fillable` array | Contains shift_id, slot_ord, code, short_name, can_be_free_period, period_type_id, start_time, end_time, is_teaching_slot, display_order, is_active |
| 3 | Verify `duration_minutes` is guarded | `$guarded = ['duration_minutes']` (generated column — never mass-assigned) |

#### TC-CR03: Model — PeriodSet `$fillable` Matches DDL Columns

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `PeriodSet.php` model | File found |
| 2 | Inspect `$fillable` array | Contains code, name, description, shift_id, from_period_ord, to_period_ord, total_periods, teaching_periods, exam_periods, free_periods, is_default, is_active |
| 3 | Cross-check DDL | All columns match DDL `tt_period_sets` |

#### TC-CR04: Model — PeriodSetPeriod `$fillable` Matches DDL Columns

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `PeriodSetPeriod.php` model | File found |
| 2 | Inspect `$fillable` array | Contains period_set_id, period_config_id, period_ord, code, short_name, period_type_id, is_active |

#### TC-CR05: Model — All Four Models Have Correct `$casts`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect PeriodType `$casts` | is_schedulable→boolean, counts_as_teaching→boolean, counts_as_workload→boolean, is_break→boolean, is_free_period→boolean, is_active→boolean, ordinal→integer, duration_minutes→integer |
| 2 | Inspect PeriodConfig `$casts` | can_be_free_period→boolean, is_teaching_slot→boolean, is_active→boolean, slot_ord→integer, display_order→integer, start_time→datetime:H:i:s, end_time→datetime:H:i:s |
| 3 | Inspect PeriodSet `$casts` | is_default→boolean, is_active→boolean, shift_id→integer, from_period_ord→integer, to_period_ord→integer, all period counts→integer |
| 4 | Inspect PeriodSetPeriod `$casts` | is_active→boolean, all FK IDs→integer |

#### TC-CR06: Model — SoftDeletes Trait Correctly Implemented

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect each model import | `use SoftDeletes;` present in all four models |
| 2 | Verify `$casts` includes `deleted_at` | `'deleted_at' => 'datetime'` in all four models |

#### TC-CR07: Model — All Eloquent Relationships Defined

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect PeriodConfig relationships | `shift()`→BelongsTo, `periodType()`→BelongsTo, `periodSetPeriods()`→HasMany |
| 2 | Inspect PeriodSet relationships | `timetables()`→HasMany, `periods()`→HasMany, `periodSetPeriods()`→HasMany, `periodConfigs()`→HasManyThrough, `shift()`→BelongsTo, `classModeRules()`→HasMany |
| 3 | Inspect PeriodSetPeriod relationships | `periodSet()`→BelongsTo, `periodConfig()`→BelongsTo, `periodType()`→BelongsTo |
| 4 | Inspect PeriodType relationships | `periodSetPeriods()`→HasMany |

#### TC-CR08: Controller — Gate::authorize() On Every Method

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect PeriodTypeController | Every method starts with `Gate::authorize('timetable-foundation.period-type.*')` |
| 2 | Inspect PeriodConfigController | Every method starts with `Gate::authorize('timetable-foundation.period-config.*')` |
| 3 | Inspect PeriodSetController | Every method starts with `Gate::authorize('timetable-foundation.period-set.*')` |
| 4 | Inspect PeriodSetPeriodController | Every method starts with `Gate::authorize('timetable-foundation.period-set-period.*')` |

#### TC-CR09: Controller — Activity Logged On All State Changes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Search for `activityLog(` in PeriodTypeController | Called in destroy (Trashed), restore (Restored), forceDelete (Deleted), toggleStatus (Toggled) |
| 2 | Search in PeriodConfigController | Called in destroy (Trashed), restore (Restored), forceDelete (Deleted), toggleStatus (Toggled), ajaxToggleCanBeFree (Toggled) |
| 3 | Search in PeriodSetController | Called in destroy (Trashed), restore (Restored), forceDelete (Deleted), toggleStatus (Toggled) |

#### TC-CR10: Controller — `is_active=false` Before Soft Delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect PeriodTypeController@destroy() | `$periodType->is_active = false; $periodType->save(); $periodType->delete();` |
| 2 | Inspect PeriodConfigController@destroy() | `$periodConfig->is_active = false; $periodConfig->save(); $periodConfig->delete();` |
| 3 | Inspect PeriodSetController@destroy() | `$periodSet->is_active = false; $periodSet->save(); $periodSet->delete();` |
| 4 | Inspect PeriodSetPeriodController@destroy() | Calls `$psp->delete()` directly — NO deactivate step |

#### TC-CR11: Controller — Restore Sets `is_active=true`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect PeriodTypeController@restore() | `$periodType->restore(); $periodType->is_active = true; $periodType->save();` |
| 2 | Inspect PeriodConfigController@restore() | `$periodConfig->restore(); $periodConfig->is_active = true; $periodConfig->save();` |
| 3 | Inspect PeriodSetController@restore() | `$periodSet->restore(); $periodSet->is_active = true; $periodSet->save();` |

#### TC-CR12: Controller — `toggleStatus()` Flips `is_active`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect PeriodTypeController@toggleStatus() | Validates `is_active` required|boolean; sets `$periodType->is_active = (bool) $request->input('is_active')`; saves; returns JSON |
| 2 | Inspect PeriodConfigController@toggleStatus() | Same pattern; returns JSON with success flag |
| 3 | Inspect PeriodSetController@toggleStatus() | Same pattern; protects default set from deactivation |
| 4 | Inspect PeriodSetPeriodController@toggleStatus() | Same pattern; returns JSON |

#### TC-CR13: Controller — Trash/Restore/ForceDelete Flow

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect each controller | Each has `trashed*()` using `onlyTrashed()`; `restore($id)` using `onlyTrashed()->findOrFail($id)`; `forceDelete($id)` using `withTrashed()->findOrFail($id)` |

#### TC-CR14: Controller — JSON Response Or Redirect After Write

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a Period Type | POST to store(); redirects back with `with('success', flash('created.period_type'))` |
| 2 | Toggle status via AJAX | POST to toggleStatus(); returns `response()->json(['success'=>true, 'message'=>flash('status_updated.*')])` |
| 3 | AJAX endpoint | ajaxReorder/ajaxUpdateTimes/ajaxToggleCanBeFree return JSON with `status`/`success` field |
| 4 | Delete via AJAX | PeriodSetPeriod returns JSON `{success:true, message:'Period removed successfully.'}` |

#### TC-CR15: Validation — Unique Ignores Current ID On Update

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect PeriodTypeController@update() | `ordinal` rule: `Rule::unique('tt_period_types','ordinal')->ignore($periodType->id)->whereNull('deleted_at')` |
| 2 | Inspect PeriodConfigController::validatePayload() | `code` and `slot_ord` rules: scoped unique + `->ignore($ignoreId)` |
| 3 | Inspect PeriodSetController@update() | `code` rule: `Rule::unique('tt_period_sets','code')->ignore($periodSet->id)` |
| 4 | Inspect PeriodSetPeriodController@update() | `code` and `period_ord`: scoped unique + `->ignore($periodSetPeriod->id)` |

#### TC-CR16: Validation — Period Set Cross-Row Dedup

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open PeriodSetController@update() | Lines 263–314 implement cross-row dedup for `period_ord` and `code` |
| 2 | Verify `$seenOrds` tracking | Each submitted `period_ord` tracked; collision caught with validation error |
| 3 | Verify `$seenCodes` tracking | Each submitted `code` tracked; collision with other submitted rows OR existing DB rows caught |
| 4 | Verify `$existingCodesByOtherRows` | Pre-loads codes from existing rows not being submitted for collision detection |

#### TC-CR17: Policy — All Required Methods Defined

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect PeriodTypePolicy.php | Methods: viewAny, view, create, update, delete, restore, forceDelete |
| 2 | Inspect PeriodConfigPolicy.php | Methods: viewAny, view, create, update, delete, restore, forceDelete |
| 3 | Inspect PeriodSetPolicy.php | Methods: viewAny, view, create, update, delete, restore, forceDelete |
| 4 | Inspect PeriodPolicy.php (for PeriodSetPeriod) | Methods: viewAny, view, create, update, delete, restore, forceDelete |

#### TC-CR18: Routes — Resource + Custom Routes Registered

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `routes/web.php` for TimetableFoundation | Lines 161–196 contain all period routes |
| 2 | Verify resource routes | `Route::resource('period-type',...)`, `Route::resource('period-config',...)`, `Route::resource('period-set',...)`, `Route::resource('period-set-period',...)` |
| 3 | Verify custom routes | Trash, restore, forceDelete, toggleStatus, AJAX routes present for each entity |
| 4 | Verify AJAX routes before resource | AJAX routes registered before resource routes to avoid wildcard conflicts |

#### TC-CR19: Database — Unique Indexes Match Validation Rules

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check DDL for `tt_period_types` | `uq_periodtype_code` on code, `uq_periodtype_ordinal` on ordinal |
| 2 | Check DDL for `tt_period_configs` | `uq_pc_shift_ord` on (shift_id, slot_ord), `uq_pc_shift_code` on (shift_id, code) |
| 3 | Check DDL for `tt_period_sets` | `uq_periodset_code` on code |
| 4 | Check DDL for `tt_period_set_periods_jnt` | `uq_psp_set_ord`, `uq_psp_set_code`, `uq_psp_set_config` match scoped unique rules |

#### TC-CR20: PeriodConfig — DB Transaction On ajaxReorder

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open PeriodConfigController@ajaxReorder() | Lines 253–275 |
| 2 | Inspect transaction wrapper | `DB::transaction(function () use ($validated) { ... });` wraps all display_order updates |
| 3 | Verify rollback | Any failure rolls back all order updates; no partial state |

#### TC-CR21: PeriodSet — DB Transaction On Junction Writes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `syncPeriodSetPeriods()` | `DB::transaction()` wraps wipe and create all junction rows |
| 2 | Inspect `syncPickerMembership()` | `DB::transaction()` wraps forceDelete and new creates |
| 3 | Inspect `autoAddInRangeConfigs()` | `DB::transaction()` wraps all junction creates |

#### TC-CR22: PeriodSet — Inline Period Update Uses DB Transaction

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect PeriodSetController@update() lines 379-425 | `DB::transaction()` wraps park-and-reassign + field updates |
| 2 | Verify try-catch | Catches `QueryException` and maps SQLSTATE 23000 to user-friendly errors |

#### TC-CR23: PeriodSet — QueryException Handling for Integrity Violations

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect catch block (lines 426-461) | SQLSTATE 23000 checked for `uq_psp_set_code` and `uq_psp_set_period_ord` |
| 2 | Verify error message mapping | Code collision returns "Code is already used by another period in this set." |
| 3 | Verify ordinal collision mapping | Ord collision returns "Period Ord is already used by another period in this set." |

#### TC-CR24: Model — PeriodSetPeriod Global Scope for Ordering

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open PeriodSetPeriod.php `booted()` method | Global scope `ordered` registered |
| 2 | Inspect order criteria | Order by: shift_id ASC, display_order ASC, slot_ord ASC (via correlated subqueries), then period_ord |

#### TC-CR25: PeriodSet — maxPeriodsPerDay Floor Logic

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect store() and create() in PeriodSetController | `maxPeriodsPerDay = max((int) Config::get('total_number_of_period_per_day', 20), 15)` |
| 2 | Verify the floor is 15 | When config returns a value below 15, maxPeriodsPerDay is 15 |

### 7.1 Positive TC Steps

#### TC-P01: Period Types Tab — Page Loads With All UI Elements

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with admin credentials | Dashboard loads |
| 2 | Expand "Timetable Foundation" from sidebar | Menu options appear |
| 3 | Click "Timetable Masters" and select "Period Types" tab | Page loads with `?tab=period-types` |
| 4 | Check "Add Period Type" button | Button visible (if create permission) |
| 5 | Check period types grid | Columns: Code, Name, Ordinal, Duration, Teaching, Break, Active, Actions |
| 6 | Check pagination | 10 records per page with page navigation |

#### TC-P02: Period Configs Tab — Page Loads With All UI Elements

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to Timetable Masters → Period Configs tab | Page loads with `?tab=period-configs` |
| 2 | Check "Add Period Config" button | Visible |
| 3 | Check configs grid | Columns: Shift, Code, Short Name, Period Type, Start, End, Duration, Teaching, Free, Active, Actions |
| 4 | Check pagination | 25 records per page |

#### TC-P03: Period Sets Tab — Page Loads With All UI Elements

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to Timetable Masters → Period Sets tab | Page loads with `?tab=period-sets` |
| 2 | Check "Add Period Set" button | Visible |
| 3 | Check sets grid | Columns: Code, Name, Shift, Period Range, Total, Teaching, Default, Active, Actions |
| 4 | Check pagination | 10 records per page |

#### TC-P04: Create Period Type With All Required Fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to Period Types tab, click "Add Period Type" | Create form opens |
| 2 | Enter code: `TEST_THEORY`, name: `Test Theory`, ordinal: `5` | Fields filled |
| 3 | Click "Save" | POST to `period-type`; redirects to tab with success message |
| 4 | DB check: `SELECT * FROM tt_period_types WHERE code='TEST_THEORY'` | Record exists; `is_schedulable=1`, `is_break=0`, `is_active=1` |

#### TC-P05: Create Period Type With All Flags Set

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open Add Period Type form | Form visible |
| 2 | Enter code: `TEST_TEACH`, name: `Test Teaching`, ordinal: `15` | Required fields set |
| 3 | Toggle ON: counts_as_teaching, counts_as_workload, is_schedulable, is_free_period | All ON |
| 4 | Click "Save" | Period type created |
| 5 | DB check: `SELECT is_schedulable, counts_as_teaching, counts_as_workload, is_free_period, is_break FROM tt_period_types WHERE code='TEST_TEACH'` | All 4 flags = 1, is_break = 0 |

#### TC-P06: Create Period Type With Break Flag

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open Add Period Type form | Form visible |
| 2 | Enter code: `TEST_BREAK`, name: `Test Break`, ordinal: `20` | Required fields set |
| 3 | Toggle ON: is_break | is_break = true |
| 4 | Leave is_schedulable, counts_as_teaching, counts_as_workload unchecked | Toggles OFF |
| 5 | Click "Save" | Period type created |
| 6 | DB check: `SELECT is_break, is_schedulable, counts_as_teaching, counts_as_workload FROM tt_period_types WHERE code='TEST_BREAK'` | is_break=1, is_schedulable=0, counts_as_teaching=0, counts_as_workload=0 |

#### TC-P07: Create Period Type With Color Code And Icon

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter code: `TEST_COLOR`, name: `Test Color`, ordinal: `25` | Required fields set |
| 2 | Enter color_code: `#FF5733`, icon: `fa-solid fa-chalkboard-teacher` | Fields filled |
| 3 | Click "Save" | Period type created |
| 4 | DB check: `SELECT color_code, icon FROM tt_period_types WHERE code='TEST_COLOR'` | `color_code='#FF5733'`, `icon='fa-solid fa-chalkboard-teacher'` |

#### TC-P08: Create Period Type With Custom Duration

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create period type: code=`TEST_DUR45`, name=`Test 45min`, ordinal=`30`, duration_minutes=`45` | Period type created |
| 2 | DB check | `duration_minutes=45` |

#### TC-P09: Edit Period Type Loads Pre-Filled Data

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create period type: code=`TEST_EDIT`, name=`Edit Me`, ordinal=`35` | Record exists |
| 2 | Click "Edit" on that period type | Edit form loads with pre-filled data |
| 3 | Verify name="Edit Me", ordinal=35 | Pre-filled correctly |

#### TC-P10: Update Period Type Name And Code (Non-System)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create type: code=`OLD_CODE`, name=`Old Name`, ordinal=`40` | Record exists |
| 2 | Edit: change code to `NEW_CODE`, name to `New Name` | Fields updated |
| 3 | Click "Save" | Update succeeds |
| 4 | DB check | `code='NEW_CODE'`, `name='New Name'` |

#### TC-P12: View Period Type Details

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create period type with all fields | Record exists |
| 2 | Click "View" | Show page with code, name, description, color, icon, all flags, ordinal, duration, status |

#### TC-P13: Create Period Config With Complete Data

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to Period Configs tab, click "Add Period Config" | Create form opens with shift and period type dropdowns |
| 2 | Select shift (e.g., "Morning") | Shift selected |
| 3 | Enter code: `SLOT-01`, short_name: `Period 1` | Fields filled |
| 4 | Select period type: `TEACHING` | Type selected |
| 5 | Enter start_time: `07:45`, end_time: `08:30` | Times filled |
| 6 | Toggle ON: is_teaching_slot, enter slot_ord: `1`, display_order: `1` | Fields filled |
| 7 | Click "Save" | POST to `period-config`; redirects with success |
| 8 | DB check: `SELECT * FROM tt_period_configs WHERE code='SLOT-01'` | Record exists; `duration_minutes=45`; `is_teaching_slot=1`; `slot_ord=1` |

#### TC-P14: Create Period Config As Non-Teaching Slot

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open Add Period Config form | Form visible |
| 2 | Enter code: `ASSEMBLY`, short_name: `Assembly` | Fields filled |
| 3 | Select period type: `ASSEMBLY`, start_time: `07:30`, end_time: `07:45` | Fields filled |
| 4 | Leave `is_teaching_slot` unchecked, `slot_ord` empty | Non-teaching settings |
| 5 | Click "Save" | Period config created |
| 6 | DB check: `SELECT slot_ord, is_teaching_slot, can_be_free_period FROM tt_period_configs WHERE code='ASSEMBLY'` | `slot_ord=NULL`, `is_teaching_slot=0`, `can_be_free_period=0` |

#### TC-P19: AJAX Reorder Period Configs

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 3 configs in same shift with display_order 1,2,3 | Configs exist |
| 2 | POST `period-config/ajax/reorder` with `ids=[3,1,2]` | AJAX request |
| 3 | Check response | JSON `{status:true, message:"Order saved."}` |
| 4 | DB check: `SELECT id, display_order FROM tt_period_configs WHERE id IN (1,2,3)` | id=3→display_order=1, id=1→2, id=2→3 |

#### TC-P20: AJAX Update Times Inline

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create config with start=08:00, end=08:45 | Config exists |
| 2 | POST `period-config/{id}/ajax-times` with `start_time=09:00`, `end_time=09:40` | AJAX request |
| 3 | Check response | JSON `{status:true, start_time:"09:00", end_time:"09:40", duration_minutes:40}` |

#### TC-P21: AJAX Toggle Can Be Free Period

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create teaching slot with can_be_free_period=false | Config exists |
| 2 | POST `period-config/{id}/ajax-can-be-free` with `can_be_free_period=true` | AJAX request |
| 3 | Check response | JSON `{success:true, can_be_free_period:true, message:"Free-period eligibility updated."}` |
| 4 | DB check | `can_be_free_period=1` |

#### TC-P22: Toggle Period Config Status

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create active period config | is_active=1 |
| 2 | Click status toggle (set is_active=0) | POST to toggle-status |
| 3 | Check response | JSON `{success:true, is_active:false}` |
| 4 | DB check | is_active=0 |
| 5 | Toggle back | is_active=1 |

#### TC-P23: Create Period Set With Complete Data

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to Period Sets tab, click "Add Period Set" | Create form opens |
| 2 | Enter code: `STANDARD_8P`, name: `Standard 8 Period Set` | Fields filled |
| 3 | Select shift: `MORNING`, set from=1, to=12 | Range set |
| 4 | Set total_periods: `12`, teaching_periods: `8`, exam_periods: `0`, free_periods: `0` | Counts set |
| 5 | Click "Save" | POST to `period-set`; redirects with success |
| 6 | DB check: `SELECT * FROM tt_period_sets WHERE code='STANDARD_8P'` | Record exists; all counts match |

#### TC-P24: Create Period Set As Default

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Set A with is_default=true | Set A created as default |
| 2 | Create Set B with is_default=true | Set B created as default |
| 3 | DB check: `SELECT id, is_default FROM tt_period_sets` | Only Set B has is_default=1; Set A has is_default=0 |

#### TC-P26: Create Period Set With Auto-Created Junction Rows

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure shift has 4 period configs with IDs 1,2,3,4 | Configs exist |
| 2 | Create period set with `period_config_ids=[1,2,3,4]` | POST to store |
| 3 | DB check: `SELECT * FROM tt_period_set_periods_jnt WHERE period_set_id={newId}` | 4 junction rows; period_ord=1,2,3,4; codes copied from configs |

#### TC-P29: Update Period Set — Change From/To Ord With Auto-Add

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create set with from=1, to=8, configs for slot 1-8 in junction | 8 rows in junction |
| 2 | Edit: change to_period_ord to 10 | Range widened |
| 3 | Submit without picker (or via ajaxSyncRange) | Auto-add creates 2 new junction rows |
| 4 | DB check: `SELECT COUNT(*) FROM tt_period_set_periods_jnt WHERE period_set_id={id}` | Count = 10 |

#### TC-P30: Update Period Set — Picker Membership Sync

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create set with configs A,B,C in junction | 3 rows exist |
| 2 | Edit: uncheck B, check D; submit with `selected_period_config_ids=[A,C,D]` | Picker submitted |
| 3 | Save | Row B force-deleted; row D created |
| 4 | DB check | Junction has A, C, D only |

#### TC-P32: Update Period Set — Swap Period Ordinals

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create set with 2 junction rows: ord=2 and ord=3 | Rows exist |
| 2 | Edit: swap ordinals (row 2→3, row 3→2) | Ordinals swapped in form |
| 3 | Save | Update succeeds (park-and-reassign avoids unique violation) |
| 4 | DB check: `SELECT id, period_ord FROM tt_period_set_periods_jnt WHERE period_set_id={id} ORDER BY id` | Row 1 → period_ord=3, Row 2 → period_ord=2 |

#### TC-P35: AJAX Fetch Period Configs For Shift

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Shift has 5 configs (3 teaching, 2 non-teaching) | Configs exist |
| 2 | GET `period-set/ajax/period-configs?shift_id=1&from=1&to=3` | AJAX request |
| 3 | Check response | JSON with 5 items; teaching slot_ord 1-3 have `in_range=true`; `teaching_slot_count=3` |

#### TC-P36: AJAX Sync Range Inline

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create set with from=1, to=8, 8 configs auto-added | Set and junction exist |
| 2 | POST `period-set/{id}/ajax/sync-range` with `from=1&to=10` | AJAX request |
| 3 | Check response | JSON `{success:true, added:2, message:"Range saved. Auto-added 2 new period(s)."}` |

#### TC-P38: Create Period Set Period Independently

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to Period Set Periods tab, click "Add" | Create form opens |
| 2 | Select a period set, a period config, a period type | Fields filled |
| 3 | Enter code: `P-1`, short_name: `Period-1`, period_ord: `1` | Fields filled |
| 4 | Click "Save" | POST to `period-set-period`; redirects with success |
| 5 | DB check: `SELECT * FROM tt_period_set_periods_jnt WHERE code='P-1'` | Record exists; all FKs correct |

#### TC-P42: Full Lifecycle: Create Period Type → Config → Set → Period → Edit → Toggle → Delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create period type: code=`LIFE_TEST`, teaching=true | Period Type created |
| 2 | Create shift (if needed) | Shift exists |
| 3 | Create period config using shift and LIFECYCLE_TEST type | Period Config created |
| 4 | Create period set with config in junction | Period Set created; junction row exists |
| 5 | Edit junction row (change code/name) | Junction updated |
| 6 | Toggle period config status | Toggle succeeds |
| 7 | Delete junction row (PeriodSetPeriod) | Soft-deleted |
| 8 | Restore junction row | Restored |
| 9 | Delete period set | Set soft-deleted; junction rows cascade-deleted |

### 7.2 Negative TC Steps

#### TC-N01: Period Type — Missing `code`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open Add Period Type form, fill name and ordinal, leave code blank | Code empty |
| 2 | Click "Save" | Validation error: "The code field is required." |

#### TC-N03: Period Type — Duplicate `code`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create period type: code=`DUP_TEST` | Created |
| 2 | Create another with same code `DUP_TEST` | Validation error on unique:tt_period_types,code |

#### TC-N04: Period Type — Duplicate `ordinal`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create period type with ordinal `50` | Created |
| 2 | Create another with ordinal `50` | Validation error on unique:tt_period_types,ordinal |

#### TC-N08: Period Type — Delete System Record

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Identify a system period type (is_system=1) | System record exists |
| 2 | Click "Delete" on that record | Redirects back with error `flash('operation_failed')` |

#### TC-N10: Period Type — Toggle Status On System Record

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click status toggle on a system record | AJAX POST to toggle-status |
| 2 | Check response | JSON 403: `{success:false, message:flash('system_record_status_change_not_allowed')}` |

#### TC-N13: Period Config — Duplicate `code` Within Same Shift

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create config with code `SLOT_DUP` in shift 1 | Created |
| 2 | Create another config with code `SLOT_DUP` in same shift | Validation error on scoped unique |

#### TC-N15: Period Config — `start_time` After `end_time`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter start_time=09:00, end_time=08:00 | End before start |
| 2 | Click "Save" | Validation error: "The end time must be a date after start time." |

#### TC-N18: Period Config — Delete With Junction Records (RESTRICT)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Identify a period config referenced by a junction record | Junction exists |
| 2 | Try to delete that period config | FK constraint violation; deletion fails |

#### TC-N19: Period Config — AJAX Toggle CanBeFree On Non-Teaching Slot

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create non-teaching config (is_teaching_slot=0) | Config exists |
| 2 | POST `ajax-can-be-free` with `can_be_free_period=true` | AJAX request |
| 3 | Check response | JSON 422: "Only teaching slots can be marked as free periods." |

#### TC-N25: Period Set — `to_period_ord` < `from_period_ord`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set from=10, to=5 | to < from |
| 2 | Click "Save" | Validation error on gte:from_period_ord |

#### TC-N26: Period Set — `to_period_ord` Exceeds Teaching Slot Count

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Shift has 8 teaching slots | Teaching count = 8 |
| 2 | Set to_period_ord=10 | Exceeds limit |
| 3 | Click "Save" | Custom validation error: "To Period Ord (10) cannot exceed the number of teaching slots in this shift (8)." |

#### TC-N29: Period Set — Delete Default Set

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure a period set is marked as default | is_default=1 |
| 2 | Click "Delete" on that set | Redirect back with error `flash('default_period_set_delete_not_allowed')` |

#### TC-N32: Period Set — Update With Duplicate Period Ord In Rows

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Edit period set with 2 junction rows | Both rows visible |
| 2 | Set both rows to period_ord=3 | Duplicate ord |
| 3 | Click "Save" | Back with error: "Period Ord 3 is duplicated within this set." |

#### TC-N33: Period Set — Update With Duplicate Code In Rows

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Edit period set with 2 junction rows | Both rows visible |
| 2 | Set both to code=`SAME_CODE` | Duplicate code |
| 3 | Click "Save" | Back with error: "Code \"SAME_CODE\" is already used by another period in this set." |

#### TC-N36: Period Set Period — Shift Mismatch

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Period set uses shift MORNING (id=1) | Set exists |
| 2 | Period config uses shift AFTERNOON (id=2) | Config exists |
| 3 | Create period set period with that config | "Selected timeslot belongs to a different shift than the period set." |

#### TC-N37: Period Set Period — Exceed Total Period Cap

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Period set has total_periods=8 and 8 periods already | At capacity |
| 2 | Try to add 9th period | "This period set is already at its maximum of 8 period(s). You cannot add more." |

#### TC-N38: Permission 403 — No Timetable Foundation Permissions

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user without any `timetable-foundation.*` permissions | User exists |
| 2 | Try to access Period Types tab | 403 Forbidden |
| 3 | Try to POST to any store/update/delete endpoint | 403 Forbidden |

#### TC-N39: Guest Access Redirect

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Logout (guest session) | Not authenticated |
| 2 | Try to access `timetable-foundation/timetable-masters?tab=period-types` | Redirected to /login |

#### TC-N40: Non-Existent Record — 404

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | GET `period-type/9999` | 404 Not Found |
| 2 | GET `period-config/9999` | 404 Not Found |
| 3 | GET `period-set/9999` | 404 Not Found |
| 4 | GET `period-set-period/9999` | 404 Not Found |

### 7.3 Dependency TC Steps

#### TC-D01: Period Type — Break Flag Forces Cascading Flags

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create period type with is_break=true, is_schedulable=true, counts_as_teaching=true | Submitted with contradicting flags |
| 2 | DB check: `SELECT is_schedulable, counts_as_teaching, counts_as_workload FROM tt_period_types WHERE code='...'` | All forced to 0 by controller logic |

#### TC-D02: Period Type — System Record Core Attribute Protection

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Note system record's core attribues before update: code, is_break | Core values noted |
| 2 | Submit update with changed code and is_break | Form submitted |
| 3 | DB check: code, is_break, is_schedulable, counts_as_teaching, counts_as_workload | All core attributes unchanged |

#### TC-D03: Period Type — Soft Delete Flow

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create non-system period type | Record active |
| 2 | Delete it | is_active set to false, then soft-deleted |
| 3 | Query with `onlyTrashed()` | Found with is_active=0, deleted_at not null |

#### TC-D06: Period Config — duration_minutes Is Generated Column

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create with start=08:00, end=08:45 | Duration auto-computed |
| 2 | DB check | `duration_minutes=45` |

#### TC-D09: Period Set — Default Set Singleton Enforcement

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Set A with is_default=true | Set A is default |
| 2 | Create Set B with is_default=true | Set B replaces Set A |
| 3 | DB check: `SELECT id, is_default FROM tt_period_sets` | Only Set B has is_default=1 |

#### TC-D10: Period Set — Create Auto-Syncs Junction

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create period set with `period_config_ids=[5,6,7]` | Store succeeds |
| 2 | DB check: `SELECT period_config_id, period_ord FROM tt_period_set_periods_jnt WHERE period_set_id={setId} ORDER BY period_ord` | ord=1→config5, ord=2→config6, ord=3→config7 |

#### TC-D13: Period Set — Auto-Add On Range Widen

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set has from=1, to=8, 8 configs in junction | 8 junction rows |
| 2 | Submit update with to_period_ord=10 (picker not submitted) | Update succeeds |
| 3 | DB check: junction count | 10 rows (2 new configs auto-added) |

#### TC-D14: Period Set — Two-Pass Ord Swap

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | 2 junction rows with period_ord=2 and ord=3 | Rows exist |
| 2 | Submit update swapping ordinals | Pass 1: ord 2→park(>max), ord 3→park+1; Pass 2: park→3, park+1→2 |
| 3 | DB check | Rows have swapped ordinals; no unique violation |

#### TC-D15: Period Set — Derived Counters Recalculated

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set has 8 junction rows (6 teaching, 2 non-teaching) | total=8, teaching=6 |
| 2 | Remove 1 teaching via picker sync | 7 rows total, 5 teaching |
| 3 | DB check: `SELECT total_periods, teaching_periods FROM tt_period_sets WHERE id={id}` | `total_periods=7`, `teaching_periods=5` |

#### TC-D21: Period Set Deletion Cascades To Junction (CASCADE)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Period set has 5 junction rows | 5 rows exist |
| 2 | Delete the period set | Set soft-deleted |
| 3 | DB check: `SELECT * FROM tt_period_set_periods_jnt WHERE period_set_id={id}` | All 5 junction rows also soft-deleted (CASCADE) |

#### TC-D31: Unit — PeriodType SoftDeletes Trait

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Delete a period type | `delete()` sets deleted_at |
| 2 | Query with `onlyTrashed()` | Only soft-deleted records returned |
| 3 | Restore | `restore()` nullifies deleted_at |
| 4 | Query normally | Record visible again |

#### TC-D32: Unit — PeriodConfig $casts Verification

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Retrieve a PeriodConfig from DB | Model instance returned |
| 2 | Check `is_teaching_slot` type | Returns boolean (true/false) not integer |
| 3 | Check `slot_ord` type | Returns integer |
| 4 | Check `is_active` type | Returns boolean |

#### TC-D34: Unit — PeriodSetPeriod Delegated Accessors

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Load PeriodSetPeriod with periodConfig relationship | Eager loaded |
| 2 | Call `$psp->start_time` | Returns value from `$psp->periodConfig->start_time` |
| 3 | Call `$psp->end_time` | Returns value from `$psp->periodConfig->end_time` |
| 4 | Call `$psp->duration_minutes` | Returns (int) from `$psp->periodConfig->duration_minutes` |

#### TC-D36: Integration — Gate::authorize() Before All Operations

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user without period-config.viewAny permission | User has no TT permissions |
| 2 | Try to access Period Configs tab | 403 Forbidden |
| 3 | Login as user with only period-set.create | User has limited permissions |
| 4 | Try to access Period Sets tab | 403 Forbidden (needs viewAny) |
| 5 | Try to create a period set | Succeeds (has create permission) |

