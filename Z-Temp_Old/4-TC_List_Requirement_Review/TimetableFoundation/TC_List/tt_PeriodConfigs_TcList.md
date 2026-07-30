# tt_PeriodConfigs_TcList

## Module: TimetableFoundation → Timetable Masters → Period Configs

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | TimetableFoundation |
| Tab Group | Timetable Masters |
| Feature | Period Configs |
| URL(s) | `GET timetable-foundation/timetable-masters?tab=period-configs` (index via tab), `POST timetable-foundation/period-config` (store), `GET timetable-foundation/period-config/{id}` (show), `GET timetable-foundation/period-config/{id}/edit` (edit), `PUT timetable-foundation/period-config/{periodConfig}` (update), `DELETE timetable-foundation/period-config/{id}` (destroy), `GET timetable-foundation/period-config/trash/view` (trashed), `GET timetable-foundation/period-config/{id}/restore` (restore), `DELETE timetable-foundation/period-config/{id}/force-delete` (forceDelete), `POST timetable-foundation/period-config/{periodConfig}/toggle-status` (toggleStatus), `POST timetable-foundation/period-config/ajax/reorder` (ajaxReorder), `POST timetable-foundation/period-config/{periodConfig}/ajax-times` (ajaxUpdateTimes), `POST timetable-foundation/period-config/{periodConfig}/ajax-can-be-free` (ajaxToggleCanBeFree) |
| Controller | `Modules\TimetableFoundation\Http\Controllers\PeriodConfigController`; screen loaded via `TimetableFoundationController@timetableMasters()` |
| Model(s) | `Modules\TimetableFoundation\Models\PeriodConfig` (table: `tt_period_configs`) |
| Validation (Create/Update) | Inline `validatePayload()` helper in `PeriodConfigController` — no dedicated Form Request |
| Policy | `Modules\TimetableFoundation\Policies\PeriodConfigPolicy` |
| Permissions | `timetable-foundation.period-config.viewAny`, `timetable-foundation.period-config.view`, `timetable-foundation.period-config.create`, `timetable-foundation.period-config.update`, `timetable-foundation.period-config.delete`, `timetable-foundation.period-config.restore`, `timetable-foundation.period-config.forceDelete` |
| Pagination | Configurable; default page size |
| Soft Deletes | Yes (`SoftDeletes` trait on model) |
| Activity Log | Events: `Trashed`, `Restored`, `Deleted`, `Toggled` via `activityLog()` helper |

---

## 2. Pre-conditions

- Required permissions: All `timetable-foundation.period-config.*` permissions (viewAny, view, create, update, delete, restore, forceDelete)
- Required seed/reference data: At least one active `SchoolShift` (`tt_shifts`); at least one active `PeriodType` (`tt_period_types`) for creation
- Required seed data for AJAX tests: At least 3 period configs in the same shift for reorder testing; a shift with both teaching and non-teaching configs for can-be-free toggle tests
- Tenant context must be initialized via `tenancy()->initialize()`
- Dusk environment variables: `DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD`
- For soft-delete tests: At least one period config record in the database
- For AJAX update-times tests: A shift with start_time and end_time set to valid values

---

## 3. Default Data Load

When the Timetable Masters page loads via `TimetableFoundationController@timetableMasters()` (`GET timetable-foundation/timetable-masters?tab=period-configs`), the following data is available:

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| Period Configs Grid | `index()` → redirect to `timetableMasters()` | `PeriodConfig::with('shift','periodType')->orderBy('shift_id')->orderBy('display_order')->orderBy('slot_ord')` | None | Default page size |
| Shared: Shifts (create/edit) | `create()` / `edit()` | `SchoolShift::where('is_active', true)->orderBy('ordinal')->get()` | is_active=true | None |
| Shared: Period Types (create/edit) | `create()` / `edit()` | `PeriodType::where('is_active', true)->orderBy('ordinal')->get()` | is_active=true | None |

---

## 4. Test Data Strategy

- **Unique suffix:** Use `now()->format('His')` for code uniqueness across test runs (e.g., `SLOT_TST_142530`)
- **Code uniqueness:** Unique per shift (scoped `(shift_id, code)`); test same code in different shifts should succeed
- **Slot ordinal uniqueness:** Unique per shift (scoped `(shift_id, slot_ord)`); only for teaching slots; NULL values are exempt from unique constraint
- **Time values:** Use `H:i` format (e.g., `07:45`, `08:30`); `end_time` must be strictly after `start_time`
- **Non-teaching slots:** `is_teaching_slot=false` forces `slot_ord=null` and `can_be_free_period=false`
- **Duration:** Auto-computed by GENERATED column as `TIMESTAMPDIFF(MINUTE, start_time, end_time)` — always read-only
- **Pre-test cleanup:** Delete created records by code suffix before/after tests to avoid collisions
- **FK chain:** PeriodConfig → Shift (RESTRICT), PeriodType (RESTRICT); PeriodSetPeriod → PeriodConfig (RESTRICT)
- **Soft delete:** Controller sets `is_active=false` before soft delete; restore sets `is_active=true`

---

## 5. Business Conditions

### 5.1 Database Schema — `tt_period_configs`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | id | INT UNSIGNED PK | Auto-increment |
| BC-DB-02 | shift_id | TINYINT UNSIGNED FK | NOT NULL, FK `tt_shifts(id)` ON DELETE RESTRICT |
| BC-DB-03 | slot_ord | TINYINT UNSIGNED | NULL (null for non-teaching), UNIQUE `(shift_id, slot_ord)` |
| BC-DB-04 | code | VARCHAR(20) | NOT NULL, UNIQUE `(shift_id, code)` |
| BC-DB-05 | short_name | VARCHAR(50) | NOT NULL |
| BC-DB-06 | period_type_id | TINYINT UNSIGNED FK | NOT NULL, FK `tt_period_types(id)` ON DELETE RESTRICT |
| BC-DB-07 | start_time | TIME | NOT NULL |
| BC-DB-08 | end_time | TIME | NOT NULL, CHECK `end_time > start_time` |
| BC-DB-09 | duration_minutes | SMALLINT UNSIGNED | GENERATED ALWAYS AS (TIMESTAMPDIFF(MINUTE, start_time, end_time)) STORED |
| BC-DB-10 | is_teaching_slot | TINYINT(1) | NOT NULL DEFAULT 0 |
| BC-DB-11 | can_be_free_period | TINYINT(1) | NOT NULL DEFAULT 0 |
| BC-DB-12 | display_order | TINYINT UNSIGNED | NOT NULL DEFAULT 1 |
| BC-DB-13 | is_active | TINYINT(1) | NOT NULL DEFAULT 1 |
| BC-DB-14 | created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |
| BC-DB-15 | updated_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP |
| BC-DB-16 | deleted_at | TIMESTAMP | NULLABLE (soft delete) |

### 5.2 Validation Rules — Period Config (Create/Update via `validatePayload()`)

| BC ID | Field | Rule(s) | Error Message |
|-------|-------|---------|---------------|
| BC-VAL-01 | shift_id | required, integer, exists:tt_shifts,id | — |
| BC-VAL-02 | slot_ord | nullable, integer, min:1, max:50; unique scoped `(shift_id, slot_ord)` + `whereNull('deleted_at')` + ignore on update | — |
| BC-VAL-03 | code | required, string, max:20; unique scoped `(shift_id, code)` + `whereNull('deleted_at')` + ignore on update | — |
| BC-VAL-04 | short_name | required, string, max:50 | — |
| BC-VAL-05 | period_type_id | required, integer, exists:tt_period_types,id | — |
| BC-VAL-06 | start_time | required, date_format:H:i | — |
| BC-VAL-07 | end_time | required, date_format:H:i, after:start_time | — |
| BC-VAL-08 | is_teaching_slot | sometimes, boolean | — |
| BC-VAL-09 | can_be_free_period | sometimes, boolean | — |
| BC-VAL-10 | display_order | sometimes, integer, min:1, max:50 | — |
| BC-VAL-11 | is_active | sometimes, boolean | — |
| BC-VAL-12 | **Business rule (controller)** | If `is_teaching_slot` is false, force `slot_ord = null` and `can_be_free_period = false` | Applied silently — no user-facing message |

### 5.3 Authorization

| BC ID | Permission | Controller Method(s) | Behavior |
|-------|-----------|----------------------|----------|
| BC-AUTH-01 | timetable-foundation.period-config.viewAny | `index()` | Without → 403 |
| BC-AUTH-02 | timetable-foundation.period-config.view | `show()` | Without → 403 |
| BC-AUTH-03 | timetable-foundation.period-config.create | `create()`, `store()` | Without → 403 |
| BC-AUTH-04 | timetable-foundation.period-config.update | `edit()`, `update()`, `toggleStatus()`, `ajaxToggleCanBeFree()`, `ajaxUpdateTimes()`, `ajaxReorder()` | Without → 403 |
| BC-AUTH-05 | timetable-foundation.period-config.delete | `destroy()` | Without → 403 |
| BC-AUTH-06 | timetable-foundation.period-config.restore | `trashedPeriodConfig()`, `restore()` | Without → 403 |
| BC-AUTH-07 | timetable-foundation.period-config.forceDelete | `forceDelete()` | Without → 403 |
| BC-AUTH-G | Guest access | All routes | Redirect to /login |

### 5.4 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Period Configs tab loads via `timetableMasters()` at `GET timetable-foundation/timetable-masters?tab=period-configs` | Grid rendered with all period configs ordered by shift and display_order; each row shows code, short_name, period type badge, start/end times, duration, teaching slot indicator, free-period flag, and status toggle |
| BC-BIZ-02 | Non-teaching slot forces slot_ord=null and can_be_free_period=false | If `is_teaching_slot=false`, controller sets `slot_ord=null` and `can_be_free_period=false` before saving |
| BC-BIZ-03 | duration_minutes is GENERATED column | Computed as `TIMESTAMPDIFF(MINUTE, start_time, end_time)` — guarded from mass assignment, read-only in UI |
| BC-BIZ-04 | ajaxReorder updates display_order only | POST with `ids[]` array updates `display_order` in transaction; `slot_ord` untouched |
| BC-BIZ-05 | ajaxUpdateTimes validates and returns new duration | Validates `after:start_time`, updates record, returns JSON with new `start_time`, `end_time`, `duration_minutes` |
| BC-BIZ-06 | ajaxToggleCanBeFree only on teaching slots | If `is_teaching_slot=false`, returns JSON 422: "Only teaching slots can be marked as free periods" |
| BC-BIZ-07 | Deactivate before soft delete | `destroy()` sets `is_active=false` before calling `delete()` |
| BC-BIZ-08 | Restore reactivates | `restore()` sets `is_active=true` after `restore()` |
| BC-BIZ-09 | Activity log on state changes | `activityLog()` called on destroy (Trashed), restore (Restored), forceDelete (Deleted), toggleStatus (Toggled), ajaxToggleCanBeFree (Toggled) |
| BC-BIZ-10 | Empty state — no configs exist | Grid shows "No records found" with Add button visible |

### 5.5 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|------------------|----------------|
| BC-REF-01 | tt_period_configs.shift_id | tt_shifts (id) | RESTRICT |
| BC-REF-02 | tt_period_configs.period_type_id | tt_period_types (id) | RESTRICT |
| BC-REF-03 | tt_period_set_periods_jnt.period_config_id | tt_period_configs (id) | RESTRICT |

---

## 6. Test Case List

### 6.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | Period Configs Tab — Page Loads With All UI Elements | Page loads with `?tab=period-configs`, Add Period Config button, configs grid with all columns (Shift, Code, Short Name, Period Type, Start, End, Duration, Teaching, Free, Active, Actions) | — | — | ⬜ |
| TC-P02 | Create Period Config With Complete Teaching Slot Data | Config created with shift, code, short_name, period_type, start_time, end_time, is_teaching_slot=true, slot_ord=1, display_order=1; duration auto-computed | — | — | ⬜ |
| TC-P03 | Create Period Config As Non-Teaching Slot | `is_teaching_slot=false`; system forces `slot_ord=null`, `can_be_free_period=false` | — | — | ⬜ |
| TC-P04 | Create Period Config With Can Be Free Period Flag | Teaching slot created with `can_be_free_period=true` | — | — | ⬜ |
| TC-P05 | Create Period Config Without Optional Display Order | Default `display_order=1` assigned | — | — | ⬜ |
| TC-P06 | Create Period Config As Inactive | Config created with `is_active=false`; hidden from active-only dropdowns | — | — | ⬜ |
| TC-P07 | View Period Config Details | Show page displays shift, code, short_name, period type badge, start_time, end_time, duration, teaching slot flag, free-period flag, display_order, status, timestamps | — | — | ⬜ |
| TC-P08 | Edit Period Config Loads Pre-Filled Data | Edit form shows existing config with all fields pre-populated | — | — | ⬜ |
| TC-P09 | Update Period Config Basic Fields | Update code, short_name, start/end times; fields persist correctly | — | — | ⬜ |
| TC-P10 | Update Period Config — Convert Teaching to Non-Teaching | Set `is_teaching_slot=false`; controller forces `slot_ord=null`, `can_be_free_period=false` | — | — | ⬜ |
| TC-P11 | AJAX Reorder Period Configs | POST `ajax/reorder` with ordered `ids` array updates `display_order` for all configs in transaction | — | — | ⬜ |
| TC-P12 | AJAX Update Times Inline | POST `ajax-times` with `start_time=08:00`, `end_time=08:45` returns JSON with new times and computed `duration_minutes=45` | — | — | ⬜ |
| TC-P13 | AJAX Toggle Can Be Free Period (Teaching Slot) | POST `ajax-can-be-free` toggles `can_be_free_period` on teaching slot; returns JSON success | — | — | ⬜ |
| TC-P14 | Toggle Period Config Status Active ↔ Inactive | `is_active` flips via AJAX; JSON response with new status | — | — | ⬜ |
| TC-P15 | Soft Delete Period Config | `is_active` set to false; record soft-deleted; hidden from main grid | — | — | ⬜ |
| TC-P16 | View Trashed Period Configs | Trash view lists all soft-deleted configs with Restore and Force Delete actions | — | — | ⬜ |
| TC-P17 | Restore Soft-Deleted Period Config | Record restored; `is_active` set to true; reappears in main grid | — | — | ⬜ |
| TC-P18 | Force Delete Period Config | Record permanently removed from DB | — | — | ⬜ |
| TC-P19 | Full Lifecycle: Create → View → Edit → Toggle Status → Soft Delete → Restore → Force Delete | All steps succeed; data transitions correctly at each stage | — | — | ⬜ |
| TC-P20 | Empty State — No Period Configs Exist | Grid shows empty state message with Add button visible | — | — | ⬜ |

### 6.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | Missing `shift_id` | Validation error: "The shift id field is required." | — | — | ⬜ |
| TC-N02 | Missing `code` | Validation error: "The code field is required." | — | — | ⬜ |
| TC-N03 | Missing `short_name` | Validation error: "The short name field is required." | — | — | ⬜ |
| TC-N04 | Missing `period_type_id` | Validation error: "The period type id field is required." | — | — | ⬜ |
| TC-N05 | Missing `start_time` | Validation error: "The start time field is required." | — | — | ⬜ |
| TC-N06 | Missing `end_time` | Validation error: "The end time field is required." | — | — | ⬜ |
| TC-N07 | Duplicate `code` Within Same Shift | Scoped unique validation error | — | — | ⬜ |
| TC-N08 | Duplicate `code` Across Different Shifts Succeeds | Same code allowed in different shift | — | — | ⬜ |
| TC-N09 | Duplicate `slot_ord` Within Same Shift | Scoped unique validation error | — | — | ⬜ |
| TC-N10 | `end_time` Before `start_time` | Validation error: "The end time must be a time after start time." | — | — | ⬜ |
| TC-N11 | Invalid FK `shift_id` (non-existent) | Validation error: "The selected shift id is invalid." | — | — | ⬜ |
| TC-N12 | Invalid FK `period_type_id` (non-existent) | Validation error: "The selected period type id is invalid." | — | — | ⬜ |
| TC-N13 | `code` Exceeds 20 Characters | Validation error on `code` max:20 | — | — | ⬜ |
| TC-N14 | `short_name` Exceeds 50 Characters | Validation error on `short_name` max:50 | — | — | ⬜ |
| TC-N15 | `slot_ord` < 1 | Validation error on `slot_ord` min:1 | — | — | ⬜ |
| TC-N16 | `display_order` > 50 | Validation error on `display_order` max:50 | — | — | ⬜ |
| TC-N17 | Delete Config Referenced By Junction Record (RESTRICT) | FK constraint violation; deletion fails | — | — | ⬜ |
| TC-N18 | AJAX Toggle CanBeFree On Non-Teaching Slot | JSON 422: "Only teaching slots can be marked as free periods" | — | — | ⬜ |
| TC-N19 | AJAX Update Times With Invalid Format (not H:i) | Validation error on `date_format:H:i` | — | — | ⬜ |
| TC-N20 | AJAX Reorder With Non-Existent ID | Validation error on exists:tt_period_configs,id | — | — | ⬜ |
| TC-N21 | Permission 403 — No `period-config.viewAny` | 403 Forbidden on accessing the tab | — | — | ⬜ |
| TC-N22 | Permission 403 — No `period-config.create` | 403 Forbidden on create form and store | — | — | ⬜ |
| TC-N23 | Permission 403 — No `period-config.update` | 403 Forbidden on edit, update, toggleStatus, and all AJAX endpoints | — | — | ⬜ |
| TC-N24 | Permission 403 — No `period-config.delete` | 403 Forbidden on destroy | — | — | ⬜ |
| TC-N25 | Permission 403 — No `period-config.restore` | 403 Forbidden on trash view and restore | — | — | ⬜ |
| TC-N26 | Permission 403 — No `period-config.forceDelete` | 403 Forbidden on forceDelete | — | — | ⬜ |
| TC-N27 | Guest Access Redirect | Unauthenticated user redirected to /login | — | — | ⬜ |
| TC-N28 | Non-Existent Record — 404 on Show | `GET period-config/99999` → 404 | — | — | ⬜ |
| TC-N29 | Non-Existent Record — 404 on Edit | `GET period-config/99999/edit` → 404 | — | — | ⬜ |
| TC-N30 | Non-Existent Record — 404 on Update | `PUT period-config/99999` → 404 | — | — | ⬜ |
| TC-N31 | Non-Existent Record — 404 on Destroy | `DELETE period-config/99999` → 404 | — | — | ⬜ |
| TC-N32 | Non-Existent Record — 404 on Restore | `GET period-config/99999/restore` → 404 | — | — | ⬜ |
| TC-N33 | Non-Existent Record — 404 on Force Delete | `DELETE period-config/99999/force-delete` → 404 | — | — | ⬜ |
| TC-N34 | Non-Existent Record — 404 on Toggle Status | `POST period-config/99999/toggle-status` → 404 | — | — | ⬜ |

### 6.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|-----------------|---------|---------|--------|
| TC-D01 | A | Non-Teaching Slot Forces slot_ord=null and can_be_free_period=false | Creating config with `is_teaching_slot=false` results in `slot_ord=null`, `can_be_free_period=false` | — | — | ⬜ |
| TC-D02 | B | duration_minutes Is Generated Column | `start=08:00`, `end=08:45` → `duration_minutes=45`; cannot be mass-assigned (guarded) | — | — | ⬜ |
| TC-D03 | C | ajaxReorder Within Transaction | All `display_order` updates succeed or none; consistent DB state | — | — | ⬜ |
| TC-D04 | D | ajaxUpdateTimes Recalculates Duration | Changing start from 08:00 to 08:15 (end=08:45) results in `duration_minutes=30` in response | — | — | ⬜ |
| TC-D05 | E | Soft Delete Sets is_active=false | `destroy()` sets `is_active=false` before `delete()`; record retrievable via `onlyTrashed()` | — | — | ⬜ |
| TC-D06 | E | Restore Sets is_active=true | `restore()` nullifies `deleted_at` and sets `is_active=true` | — | — | ⬜ |
| TC-D07 | F | Shift Deletion Blocked By Period Config (RESTRICT) | Cannot delete shift referenced by period configs | — | — | ⬜ |
| TC-D08 | F | Period Type Deletion Blocked By Period Config (RESTRICT) | Cannot delete period type referenced by period configs | — | — | ⬜ |
| TC-D09 | G | Period Config Deletion Blocked By Junction (RESTRICT) | Cannot delete period config referenced by `tt_period_set_periods_jnt` | — | — | ⬜ |
| TC-D10 | H | Activity Logged After State Changes | Activity log entries created for Trashed/Restored/Deleted/Toggled | — | — | ⬜ |
| TC-D11 | I | DB — tt_period_configs Composite Uniques | Duplicate `(shift_id, slot_ord)` or `(shift_id, code)` at DB level throws integrity violation | — | — | ⬜ |
| TC-D12 | J | DB — CHECK end_time > start_time | Direct DB insert with `start_time=09:00, end_time=08:00` fails constraint | — | — | ⬜ |
| TC-D13 | K | Unit — PeriodConfig Model $casts | `is_teaching_slot`, `can_be_free_period`, `is_active` cast to boolean; `slot_ord`, `display_order` cast to integer | — | — | ⬜ |
| TC-D14 | L | Unit — PeriodConfig Model SoftDeletes Trait | `delete()` sets `deleted_at`; `restore()` nullifies; `onlyTrashed()` filters deleted | — | — | ⬜ |
| TC-D15 | M | Unit — PeriodConfig Model Relationships | `shift()` returns BelongsTo; `periodType()` returns BelongsTo; `periodSetPeriods()` returns HasMany | — | — | ⬜ |
| TC-D16 | N | Integration — findOrFail Returns 404 on Invalid ID | Non-existent ID for show/edit/update/destroy returns 404 | — | — | ⬜ |
| TC-D17 | O | Integration — Gate::authorize() Before All Operations | Each controller method calls Gate::authorize() before processing; 403 w/o permissions | — | — | ⬜ |
| TC-D18 | P | Integration — All Custom Routes Registered | Every AJAX, trash, restore, forceDelete, toggleStatus route resolves to correct controller method | — | — | ⬜ |
| TC-D19 | Q | Cross-Module — PeriodConfig Referenced By PeriodSetPeriod (RESTRICT) | Junction FK `period_config_id` blocks deletion of referenced period config | — | — | ⬜ |

### 6.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|-----------------|---------|---------|--------|
| TC-CR01 | CR | P1 | Model — `$fillable` matches DDL columns (mass-assignment protection) | `$fillable` includes: shift_id, slot_ord, code, short_name, period_type_id, start_time, end_time, is_teaching_slot, can_be_free_period, display_order, is_active; `duration_minutes` is `$guarded` | — | — | ◌ |
| TC-CR02 | CR | P1 | Model — `$casts` for booleans/integers/dates | `is_teaching_slot`→boolean, `can_be_free_period`→boolean, `is_active`→boolean, `slot_ord`→integer, `display_order`→integer, `start_time`→datetime:H:i:s, `end_time`→datetime:H:i:s | — | — | ◌ |
| TC-CR03 | CR | P1 | Model — SoftDeletes trait correctly implemented | `use SoftDeletes;` present; `deleted_at` column in DDL; `delete()` sets `deleted_at`; `restore()` nullifies | — | — | ◌ |
| TC-CR04 | CR | P1 | Model — relationships defined | `shift()`→BelongsTo, `periodType()`→BelongsTo, `periodSetPeriods()`→HasMany | — | — | ◌ |
| TC-CR05 | CR | P1 | Controller — try-catch exception handling on all write methods | `store()`, `update()`, `destroy()` use try-catch; on exception → redirect back with error message | — | — | ◌ |
| TC-CR06 | CR | P1 | Controller — DB transactions on multi-step writes | `ajaxReorder()` wraps display_order updates in `DB::transaction()` | — | — | ◌ |
| TC-CR07 | CR | P1 | Controller — `Gate::authorize()` on every method | Every method calls `Gate::authorize()` with respective permission string before logic | — | — | ◌ |
| TC-CR08 | CR | P1 | Controller — activity logged on all state changes | `activityLog()` called on destroy, restore, forceDelete, toggleStatus, ajaxToggleCanBeFree | — | — | ◌ |
| TC-CR09 | CR | P1 | Controller — `is_active=false` before soft delete; restore sets `is_active=true` | `destroy()` sets `is_active=false` before `delete()`; `restore()` sets `is_active=true` after `restore()` | — | — | ◌ |
| TC-CR10 | CR | P1 | Controller — `toggleStatus()` flips `is_active` | `toggleStatus()` receives `is_active` boolean, saves, returns JSON success | — | — | ◌ |
| TC-CR11 | CR | P1 | Controller — trash/restore/forceDelete flow | `trashedPeriodConfig()` uses `onlyTrashed()`; `restore()` uses `onlyTrashed()->findOrFail()`; `forceDelete()` uses `withTrashed()->findOrFail()` | — | — | ◌ |
| TC-CR12 | CR | P1 | Controller — redirect/JSON response after write | `store()`/`update()`/`destroy()` → redirect with flash; `toggleStatus()`/AJAX endpoints → JSON response | — | — | ◌ |
| TC-CR13 | CR | P1 | Validation — unique rules ignore current ID on update | `code` and `slot_ord` scoped unique rules use `->ignore($ignoreId)` on update | — | — | ◌ |
| TC-CR14 | CR | P1 | Validation — business rules in controller | Non-teaching slot forces `slot_ord=null` and `can_be_free_period=false`; ajaxToggleCanBeFree checks `is_teaching_slot` | — | — | ◌ |
| TC-CR15 | CR | P1 | Policy — all required methods defined | Policy defines viewAny, view, create, update, delete, restore, forceDelete; permission strings match gate names | — | — | ◌ |
| TC-CR16 | CR | P1 | Routes — resource + custom routes registered; model binding 404s | Resource route for `period-config`; custom routes for trashed, restore, forceDelete, toggleStatus, AJAX; implicit model binding throws 404 | — | — | ◌ |
| TC-CR17 | CR | P1 | View — Blade `@can` directives on tab/action buttons | Tab and action buttons guarded by permissions | — | — | ◌ |
| TC-CR18 | CR | P1 | View — `isset()`/null-safe checks for relationship variables | `$config->shift->name ?? '--'` pattern; `$config->periodType->name ?? '--'` | — | — | ◌ |
| TC-CR19 | CR | P1 | Breadcrumb — route registered in `config/breadcrumb.php` | Each view defines breadcrumb hierarchy via `x-backend.components.breadcrum` | — | — | ◌ |
| TC-CR20 | CR | P1 | Database — unique indexes match request validation rules | `uq_pc_shift_ord` on `(shift_id, slot_ord)`, `uq_pc_shift_code` on `(shift_id, code)` match scoped unique rules | — | — | ◌ |

---

## 7. Detailed Test Steps

#### TC-CR01: Model — `$fillable` Matches DDL Columns (Mass-Assignment Protection)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `PeriodConfig.php` model | Model found in `Modules/TimetableFoundation/Models/` |
| 2 | Inspect `$fillable` array | Contains: shift_id, slot_ord, code, short_name, period_type_id, start_time, end_time, is_teaching_slot, can_be_free_period, display_order, is_active |
| 3 | Verify `duration_minutes` is NOT in `$fillable` | `duration_minutes` is in `$guarded` array (generated column) |

#### TC-CR02: Model — `$casts` for Booleans/Integers/Dates

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `$casts` property in model | `is_teaching_slot` → boolean, `can_be_free_period` → boolean, `is_active` → boolean |
| 2 | Verify integer casts | `slot_ord` → integer, `display_order` → integer |
| 3 | Verify time casts | `start_time` → datetime:H:i:s, `end_time` → datetime:H:i:s |

#### TC-CR03: Model — SoftDeletes Trait Correctly Implemented

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect model for `use SoftDeletes` | `use Illuminate\Database\Eloquent\SoftDeletes;` present |
| 2 | Soft delete a record | `deleted_at` set; record excluded from normal queries |
| 3 | Query `onlyTrashed()` | Only soft-deleted records appear |
| 4 | Restore | `deleted_at` nullified; record visible in normal queries |

#### TC-CR04: Model — Relationships Defined

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `shift()` relationship | Returns `belongsTo(SchoolShift::class)` |
| 2 | Inspect `periodType()` relationship | Returns `belongsTo(PeriodType::class)` |
| 3 | Inspect `periodSetPeriods()` relationship | Returns `hasMany(PeriodSetPeriod::class)` |

#### TC-CR05: Controller — Try-Catch Exception Handling on All Write Methods

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `store()` | Try-catch wraps all logic; catch returns redirect back with error message |
| 2 | Inspect `update()` | Same try-catch pattern as store |
| 3 | Inspect `destroy()` | Try-catch wraps set is_active=false + delete + activity log; catch rolls back |

#### TC-CR06: Controller — DB Transactions on Multi-Step Writes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `ajaxReorder()` | `DB::transaction(function () { ... });` wraps all `display_order` updates |

#### TC-CR07: Controller — `Gate::authorize()` on Every Method

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `index()` | `Gate::authorize('timetable-foundation.period-config.viewAny')` |
| 2 | Inspect `create()` | `Gate::authorize('timetable-foundation.period-config.create')` |
| 3 | Inspect `store()` | `Gate::authorize('timetable-foundation.period-config.create')` |
| 4 | Inspect `show()` | `Gate::authorize('timetable-foundation.period-config.view')` |
| 5 | Inspect `edit()` | `Gate::authorize('timetable-foundation.period-config.update')` |
| 6 | Inspect `update()` | `Gate::authorize('timetable-foundation.period-config.update')` |
| 7 | Inspect `destroy()` | `Gate::authorize('timetable-foundation.period-config.delete')` |
| 8 | Inspect AJAX methods | Each calls `Gate::authorize('timetable-foundation.period-config.update')` |

#### TC-CR08: Controller — Activity Logged on All State Changes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `destroy()` | `activityLog($periodConfig, 'Trashed', [...])` |
| 2 | Inspect `restore()` | `activityLog($periodConfig, 'Restored', [...])` |
| 3 | Inspect `forceDelete()` | `activityLog($periodConfig, 'Deleted', [...])` |
| 4 | Inspect `toggleStatus()` | `activityLog($periodConfig, 'Toggled', [...])` |
| 5 | Inspect `ajaxToggleCanBeFree()` | `activityLog($periodConfig, 'Toggled', [...])` |

#### TC-CR09: Controller — `is_active=false` Before Soft Delete; Restore Sets Active

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `destroy()` | `$periodConfig->is_active = false; $periodConfig->save(); $periodConfig->delete();` |
| 2 | Inspect `restore()` | `$periodConfig->restore(); $periodConfig->is_active = true; $periodConfig->save();` |

#### TC-CR10: Controller — `toggleStatus()` Flips `is_active`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `toggleStatus()` | Validates `is_active` required|boolean; sets value; saves; returns JSON |

#### TC-CR11: Controller — Trash/Restore/ForceDelete Flow

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `trashedPeriodConfig()` | `PeriodConfig::onlyTrashed()->with(...)->paginate()` |
| 2 | Inspect `restore($id)` | `PeriodConfig::onlyTrashed()->findOrFail($id)->restore()` |
| 3 | Inspect `forceDelete($id)` | `PeriodConfig::withTrashed()->findOrFail($id)->forceDelete()` |

#### TC-CR12: Controller — Redirect/JSON Response After Write

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `store()` success | `redirect()->route(...)->with('success', flash(...))` |
| 2 | Inspect `update()` success | `redirect()->route(...)->with('success', flash(...))` |
| 3 | Inspect `destroy()` success | `redirect()->route(...)->with('success', flash(...))` |
| 4 | Inspect `toggleStatus()` response | JSON with `success`, `is_active`, `message` |
| 5 | Inspect AJAX responses | JSON with appropriate fields |

#### TC-CR13: Validation — Unique Ignores Current ID On Update

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `validatePayload()` update path | `code` rule: scoped unique + `->ignore($ignoreId)` |
| 2 | Inspect `slot_ord` update rule | Scoped unique + `->ignore($ignoreId)` |

#### TC-CR14: Validation — Business Rules in Controller

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `store()` lines 40-60 | If `! is_teaching_slot`, force `slot_ord=null`, `can_be_free_period=false` |
| 2 | Inspect `ajaxToggleCanBeFree()` | Checks `is_teaching_slot`; if false, returns 422 |

#### TC-CR15: Policy — All Required Methods Defined

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `PeriodConfigPolicy.php` | Policy found |
| 2 | Inspect each method | `viewAny()`, `view()`, `create()`, `update()`, `delete()`, `restore()`, `forceDelete()` all defined; each returns `$user->can(...)` |

#### TC-CR16: Routes — Resource + Custom Routes Registered

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `routes/web.php` | Route group found at lines 169-176 |
| 2 | Verify resource route | `Route::resource('period-config', PeriodConfigController::class)` |
| 3 | Verify custom routes | trashed, restore, forceDelete, toggleStatus, ajax routes present |
| 4 | Verify AJAX routes before resource | AJAX routes registered before resource to avoid wildcard conflicts |

#### TC-CR17: View — Blade `@can` Directives on Tab/Action Buttons

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect period config tab view | `@can('timetable-foundation.period-config.create')` on Add button |
| 2 | Inspect action buttons | View, Edit, Delete actions guarded by `@can` directives |

#### TC-CR18: View — `isset()`/Null-Safe Checks for Relationship Variables

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect list view | `$config->shift->name ?? '--'` pattern for relationship access |
| 2 | Inspect show view | Null-safe access for optional relationships |

#### TC-CR19: Breadcrumb — Route Registered in Config

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect create view | `x-backend.components.breadcrum` with title "Create Period Config" |
| 2 | Inspect edit view | Breadcrumb hierarchy: Timetable Masters > Period Configs > Edit |

#### TC-CR20: Database — Unique Indexes Match Request Validation Rules

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check DDL for `tt_period_configs` | `uq_pc_shift_ord` on `(shift_id, slot_ord)` matches scoped unique validation |
| 2 | Check DDL for `uq_pc_shift_code` | `uq_pc_shift_code` on `(shift_id, code)` matches scoped unique validation |

---

### 7.1 Positive TC Steps

#### TC-P01: Period Configs Tab — Page Loads With All UI Elements

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with admin credentials | Dashboard loads |
| 2 | Navigate to Timetable Foundation → Timetable Masters → Period Configs tab | Page loads with `?tab=period-configs` |
| 3 | Check "Add Period Config" button | Button visible (if create permission) |
| 4 | Check configs grid columns | Shift, Code, Short Name, Period Type (with colour badge), Start, End, Duration, Teaching indicator, Free indicator, Active toggle, Actions (View/Edit/Delete) |
| 5 | Verify data grouped by shift | Configs displayed in shift-grouped sections |

#### TC-P02: Create Period Config With Complete Teaching Slot Data

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click "Add Period Config" | Create form opens with shift and period type dropdowns |
| 2 | Select shift "Morning" | Shift selected |
| 3 | Enter code `SLOT_01`, short_name `Period 1` | Fields filled |
| 4 | Select period type "TEACHING" | Type selected |
| 5 | Enter start_time `07:45`, end_time `08:30` | Times filled |
| 6 | Toggle ON `is_teaching_slot`, enter `slot_ord=1`, `display_order=1` | Fields set |
| 7 | Click "Save" | POST to `period-config`; redirects with success |
| 8 | DB check: `SELECT * FROM tt_period_configs WHERE code='SLOT_01'` | Record exists; `duration_minutes=45`; `is_teaching_slot=1`; `slot_ord=1`; `display_order=1` |

#### TC-P03: Create Period Config As Non-Teaching Slot

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open Add Period Config form | Form visible |
| 2 | Enter code `ASSEMBLY`, short_name `Assembly` | Fields filled |
| 3 | Select period type "ASSEMBLY" | Type selected |
| 4 | Enter start_time `07:30`, end_time `07:45` | Times filled |
| 5 | Leave `is_teaching_slot` unchecked, `slot_ord` empty | Non-teaching settings |
| 6 | Click "Save" | Config created |
| 7 | DB check: `SELECT slot_ord, is_teaching_slot, can_be_free_period FROM tt_period_configs WHERE code='ASSEMBLY'` | `slot_ord=NULL`, `is_teaching_slot=0`, `can_be_free_period=0` |

#### TC-P04: Create Period Config With Can Be Free Period Flag

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open Add Period Config form | Form visible |
| 2 | Enter code `FREE_SLOT`, short_name `Free Eligible` | Fields filled |
| 3 | Select shift, period type "TEACHING" | Fields set |
| 4 | Enter start_time `09:00`, end_time `09:45` | Times filled |
| 5 | Toggle ON `is_teaching_slot`, enter `slot_ord=5` | Teaching slot |
| 6 | Toggle ON `can_be_free_period` | Free period flag ON |
| 7 | Click "Save" | Config created |
| 8 | DB check: `SELECT can_be_free_period FROM tt_period_configs WHERE code='FREE_SLOT'` | `can_be_free_period=1` |

#### TC-P05: Create Period Config Without Optional Display Order

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create config with all required fields, leave display_order empty | Config created |
| 2 | DB check | `display_order=1` (default) |

#### TC-P06: Create Period Config As Inactive

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create config with `is_active` toggle OFF | Config created with `is_active=0` |
| 2 | Verify config hidden from active displays | Not shown in dropdowns/queries filtering by is_active |

#### TC-P07: View Period Config Details

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a config with all fields | Record exists |
| 2 | Click "View" on that config | Show page loads |
| 3 | Verify displayed fields | Shift name, Code, Short Name, Period Type badge, Start/End Time, Duration, Teaching Slot badge, Free Period badge, Display Order, Active Status, Created At, Updated At |

#### TC-P08: Edit Period Config Loads Pre-Filled Data

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create config with known values | Record exists |
| 2 | Click "Edit" on that config | Edit form loads with all fields pre-filled matching DB values |

#### TC-P09: Update Period Config Basic Fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Edit existing config | Edit form loaded |
| 2 | Change code from `SLOT_01` to `SLOT_01_UPD`, short_name from `Period 1` to `Updated Period 1` | Fields changed |
| 3 | Change start_time to `08:00`, end_time to `08:50` | Times changed |
| 4 | Click "Save" | Update succeeds; redirect with success |
| 5 | DB check | `code='SLOT_01_UPD'`, `short_name='Updated Period 1'`, `start_time=08:00`, `end_time=08:50`, `duration_minutes=50` |

#### TC-P10: Update Period Config — Convert Teaching to Non-Teaching

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create teaching config with `slot_ord=3`, `can_be_free_period=true` | Teaching slot |
| 2 | Edit: set `is_teaching_slot=false`, leave `slot_ord=3` and `can_be_free_period=true` | Contradicting fields |
| 3 | Click "Save" | Controller forces `slot_ord=null`, `can_be_free_period=false` |
| 4 | DB check | `is_teaching_slot=0`, `slot_ord=NULL`, `can_be_free_period=0` |

#### TC-P11: AJAX Reorder Period Configs

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 3 configs in same shift with `display_order=1,2,3` | Configs exist |
| 2 | POST `period-config/ajax/reorder` with `ids=[3,1,2]` | AJAX request |
| 3 | Check response | JSON `{status:true, message:"Order saved."}` |
| 4 | DB check: `SELECT id, display_order FROM tt_period_configs WHERE id IN (1,2,3)` | id=3→order=1, id=1→order=2, id=2→order=3 |

#### TC-P12: AJAX Update Times Inline

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create config with `start=08:00`, `end=08:45` | Config exists |
| 2 | POST `period-config/{id}/ajax-times` with `start_time=09:00`, `end_time=09:40` | AJAX request |
| 3 | Check response | JSON `{status:true, start_time:"09:00", end_time:"09:40", duration_minutes:40}` |
| 4 | DB check | `start_time=09:00`, `end_time=09:40`, `duration_minutes=40` |

#### TC-P13: AJAX Toggle Can Be Free Period (Teaching Slot)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create teaching slot with `can_be_free_period=false` | Config exists |
| 2 | POST `period-config/{id}/ajax-can-be-free` with `can_be_free_period=true` | AJAX request |
| 3 | Check response | JSON `{success:true, can_be_free_period:true, message:"Free-period eligibility updated."}` |
| 4 | DB check | `can_be_free_period=1` |

#### TC-P14: Toggle Period Config Status Active ↔ Inactive

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create active config (`is_active=1`) | Config exists |
| 2 | Click status toggle → POST to `toggle-status` with `is_active=0` | AJAX request |
| 3 | Check response | JSON `{success:true, is_active:false, message:"..."}` |
| 4 | DB check | `is_active=0` |
| 5 | Toggle back to active | JSON `{success:true, is_active:true}`; DB `is_active=1` |

#### TC-P15: Soft Delete Period Config

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create active config (`is_active=1`) | Config exists |
| 2 | Click "Delete" on that config | DELETE to `period-config/{id}` |
| 3 | Verify redirect | Redirected with success flash |
| 4 | DB check: `is_active=0`, `deleted_at` set | Record soft-deleted |
| 5 | Verify hidden from main grid | Main grid shows only active records |

#### TC-P16: View Trashed Period Configs

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete at least one config | Config in trash |
| 2 | Navigate to trash: `GET period-config/trash/view` | Trash page loads |
| 3 | Verify columns and actions | Columns: code, short_name, shift, deleted_at; Actions: Restore, Force Delete |

#### TC-P17: Restore Soft-Deleted Period Config

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to trash view | Trashed configs listed |
| 2 | Click "Restore" on a trashed config | GET to `period-config/{id}/restore` |
| 3 | Verify redirect | Redirected to trash view with success flash |
| 4 | DB check | `deleted_at=NULL`, `is_active=1` |
| 5 | Verify in main grid | Config reappears in active list |

#### TC-P18: Force Delete Period Config

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to trash view | Trashed configs listed |
| 2 | Click "Force Delete" on a trashed config | DELETE to `period-config/{id}/force-delete` |
| 3 | Verify redirect | Redirected to trash view with success flash |
| 4 | DB check (including withTrashed) | Record permanently removed |

#### TC-P19: Full Lifecycle

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create config (TC-P02) | Config created |
| 2 | View details (TC-P07) | Details shown |
| 3 | Edit config (TC-P09) | Updated |
| 4 | Toggle status inactive (TC-P14) | Status changed |
| 5 | Soft delete (TC-P15) | Config trashed |
| 6 | View in trash (TC-P16) | Config in trash list |
| 7 | Restore (TC-P17) | Config restored, active |
| 8 | Force delete (TC-P18) | Config permanently removed |

#### TC-P20: Empty State — No Period Configs Exist

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure no period configs exist | No records |
| 2 | Load Period Configs tab | Grid shows empty state message with Add button visible |

---

### 7.2 Negative TC Steps

#### TC-N01 to TC-N06: Missing Required Fields

| TC ID | Step 1: Action | Step 2: Expected Result |
|-------|----------------|-------------------------|
| TC-N01 | Leave `shift_id` empty, fill all other required fields | Validation error: "The shift id field is required." |
| TC-N02 | Leave `code` empty | Validation error: "The code field is required." |
| TC-N03 | Leave `short_name` empty | Validation error: "The short name field is required." |
| TC-N04 | Leave `period_type_id` empty | Validation error: "The period type id field is required." |
| TC-N05 | Leave `start_time` empty | Validation error: "The start time field is required." |
| TC-N06 | Leave `end_time` empty | Validation error: "The end time field is required." |

#### TC-N07: Duplicate `code` Within Same Shift

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create config with code `DUP_CODE` in shift 1 | Created |
| 2 | Create another config with code `DUP_CODE` in same shift 1 | Validation error on scoped unique |

#### TC-N08: Duplicate `code` Across Different Shifts Succeeds

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create config with code `SAME_CODE` in shift 1 | Created |
| 2 | Create config with same code `SAME_CODE` in shift 2 | Success (different shift) |

#### TC-N09: Duplicate `slot_ord` Within Same Shift

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create teaching config with `slot_ord=5` in shift 1 | Created |
| 2 | Create another teaching config with `slot_ord=5` in same shift | Validation error on scoped unique |

#### TC-N10: `end_time` Before `start_time`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter `start_time=09:00`, `end_time=08:00` | End before start |
| 2 | Click "Save" | Validation error: "The end time must be a time after start time." |

#### TC-N11 to TC-N12: Invalid FKs

| TC ID | Step 1: Action | Step 2: Expected Result |
|-------|----------------|-------------------------|
| TC-N11 | Set `shift_id` to non-existent value (999) | Validation error: "The selected shift id is invalid." |
| TC-N12 | Set `period_type_id` to non-existent value (999) | Validation error: "The selected period type id is invalid." |

#### TC-N13 to TC-N16: Field Length/Range Violations

| TC ID | Step 1: Action | Step 2: Expected Result |
|-------|----------------|-------------------------|
| TC-N13 | Enter `code` with 21+ characters | Validation error on code max:20 |
| TC-N14 | Enter `short_name` with 51+ characters | Validation error on short_name max:50 |
| TC-N15 | Set `slot_ord=0` | Validation error on slot_ord min:1 |
| TC-N16 | Set `display_order=51` | Validation error on display_order max:50 |

#### TC-N17: Delete Config Referenced By Junction Record (RESTRICT)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Identify a period config that is referenced by a junction record | Junction exists for this config |
| 2 | Try to delete that period config | FK constraint violation; deletion fails; error message returned |

#### TC-N18: AJAX Toggle CanBeFree On Non-Teaching Slot

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create non-teaching config (`is_teaching_slot=0`) | Config exists |
| 2 | POST `ajax-can-be-free` with `can_be_free_period=true` | AJAX request |
| 3 | Check response | JSON 422: "Only teaching slots can be marked as free periods" |

#### TC-N19: AJAX Update Times With Invalid Format

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST `ajax-times` with `start_time=25:00` | Invalid time format |
| 2 | Check response | Validation error on `date_format:H:i` |

#### TC-N20: AJAX Reorder With Non-Existent ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST `ajax/reorder` with `ids=[99999,1,2]` | Non-existent ID included |
| 2 | Check response | Validation error on exists:tt_period_configs,id |

#### TC-N21 to TC-N26: Permission 403

| TC ID | Step 1: Action | Step 2: Expected Result |
|-------|----------------|-------------------------|
| TC-N21 | Login as user without `period-config.viewAny` | 403 on accessing tab |
| TC-N22 | User without `period-config.create` | 403 on create form and store |
| TC-N23 | User without `period-config.update` | 403 on edit, update, toggleStatus, AJAX endpoints |
| TC-N24 | User without `period-config.delete` | 403 on destroy |
| TC-N25 | User without `period-config.restore` | 403 on trash view and restore |
| TC-N26 | User without `period-config.forceDelete` | 403 on forceDelete |

#### TC-N27: Guest Access Redirect

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Logout (guest session) | Not authenticated |
| 2 | Access any period-config route | Redirected to /login |

#### TC-N28 to TC-N34: Non-Existent Record — 404

| TC ID | Step 1: Action | Step 2: Expected Result |
|-------|----------------|-------------------------|
| TC-N28 | `GET /period-config/99999` | 404 Not Found |
| TC-N29 | `GET /period-config/99999/edit` | 404 Not Found |
| TC-N30 | `PUT /period-config/99999` | 404 Not Found |
| TC-N31 | `DELETE /period-config/99999` | 404 Not Found |
| TC-N32 | `GET /period-config/99999/restore` | 404 Not Found |
| TC-N33 | `DELETE /period-config/99999/force-delete` | 404 Not Found |
| TC-N34 | `POST /period-config/99999/toggle-status` | 404 Not Found |

---

### 7.3 Dependency TC Steps

#### TC-D01: Non-Teaching Slot Forces slot_ord=null and can_be_free_period=false

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create config with `is_teaching_slot=false`, submit `slot_ord=5`, `can_be_free_period=true` | Submitted with contradicting flags |
| 2 | DB check | `is_teaching_slot=0`, `slot_ord=NULL`, `can_be_free_period=0` |

#### TC-D02: duration_minutes Is Generated Column

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create config with `start=08:00`, `end=08:45` | Duration auto-computed |
| 2 | DB check | `duration_minutes=45` |
| 3 | Attempt mass-assign via `PeriodConfig::create(['duration_minutes'=>30])` | `duration_minutes` ignored (guarded) |

#### TC-D03: ajaxReorder Within Transaction

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST `ajax/reorder` with valid IDs | All `display_order` updates succeed |
| 2 | POST `ajax/reorder` with one invalid ID | Transaction rolls back; no partial updates |

#### TC-D04: ajaxUpdateTimes Recalculates Duration

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create config with `start=08:00`, `end=08:45` | `duration_minutes=45` |
| 2 | POST `ajax-times` with `start_time=08:15`, `end_time=08:45` | Response shows `duration_minutes=30` |
| 3 | DB check | `start_time=08:15`, `duration_minutes=30` |

#### TC-D05: Soft Delete Sets is_active=false

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create active config (`is_active=1`) | Config active |
| 2 | Delete config | `is_active` set to false, then soft-deleted |
| 3 | Query `onlyTrashed()` | `is_active=0`, `deleted_at` not null |

#### TC-D06: Restore Sets is_active=true

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Restore a soft-deleted config | `restore()` nullifies `deleted_at` and sets `is_active=true` |
| 2 | Verify DB | `deleted_at=NULL`, `is_active=1` |

#### TC-D07: Shift Deletion Blocked By Period Config (RESTRICT)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Identify a shift that has period configs | Shift referenced by configs |
| 2 | Attempt to delete that shift | FK constraint violation; deletion blocked |

#### TC-D08: Period Type Deletion Blocked By Period Config (RESTRICT)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Identify a period type referenced by period configs | Type in use |
| 2 | Attempt to delete that period type | FK constraint violation; deletion blocked |

#### TC-D09: Period Config Deletion Blocked By Junction (RESTRICT)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Identify a period config referenced by junction | Junction row exists |
| 2 | Attempt to delete that period config | FK constraint violation; deletion blocked |

#### TC-D10: Activity Logged After State Changes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create, then delete a config | Activity log entries created for create (not directly logged) and Trashed |
| 2 | Restore the config | Activity log entry with event 'Restored' |
| 3 | Force delete the config | Activity log entry with event 'Deleted' |
| 4 | Toggle status | Activity log entry with event 'Toggled' |

#### TC-D11: DB — Unique Constraints

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Direct DB insert: duplicate `(shift_id=1, slot_ord=1)` | Integrity constraint violation |
| 2 | Direct DB insert: duplicate `(shift_id=1, code='SLOT_01')` | Integrity constraint violation |

#### TC-D12: DB — CHECK end_time > start_time

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Direct DB insert with `start_time='09:00'`, `end_time='08:00'` | CHECK constraint violation; insert fails |

#### TC-D13: Unit — PeriodConfig Model $casts

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Retrieve a PeriodConfig from DB | Model instance returned |
| 2 | Check `is_teaching_slot` type | Returns boolean, not integer |
| 3 | Check `can_be_free_period` type | Returns boolean |
| 4 | Check `slot_ord` type | Returns integer |
| 5 | Check `is_active` type | Returns boolean |

#### TC-D14: Unit — SoftDeletes Trait

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Delete a config | `delete()` sets `deleted_at` |
| 2 | Query `onlyTrashed()` | Only soft-deleted records returned |
| 3 | Restore | `restore()` nullifies `deleted_at` |
| 4 | Query normally | Record visible again |

#### TC-D15: Unit — PeriodConfig Relationships

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Fetch config with `shift` relationship | `$config->shift` returns SchoolShift model |
| 2 | Fetch config with `periodType` relationship | `$config->periodType` returns PeriodType model |
| 3 | Fetch config with `periodSetPeriods` relationship | `$config->periodSetPeriods` returns Collection of PeriodSetPeriod |

#### TC-D16: Integration — findOrFail Returns 404 on Invalid ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Access show/edit/update/destroy with valid ID | Model loaded successfully |
| 2 | Access with non-existent ID (99999) | `ModelNotFoundException` → HTTP 404 |

#### TC-D17: Integration — Gate::authorize() Before All Operations

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user without period-config.viewAny | 403 on accessing tab |
| 2 | Login as user with only period-config.create | Can access create form; cannot access edit |

#### TC-D18: Integration — All Custom Routes Registered

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Run `php artisan route:list | grep period-config` | All routes present: resource + trash/restore/forceDelete/toggleStatus/AJAX |
| 2 | Verify AJAX routes before resource | AJAX routes registered before resource to avoid `{periodConfig}` capturing `ajax` |

#### TC-D19: Cross-Module — Period Config Referenced By Junction (RESTRICT)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Identify period config with junction records | Junction exists |
| 2 | Attempt to force-delete that config | FK RESTRICT blocks deletion |
