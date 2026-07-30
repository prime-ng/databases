# tt_PeriodTypes_TcList

## Module: TimetableFoundation → Timetable Masters → Period Types

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | TimetableFoundation |
| Tab Group | Timetable Masters |
| Feature | Period Types |
| URL(s) | `GET /timetable-foundation/period-type` — redirects to `timetable-foundation.menu.timetableMasters?tab=period-types` |
| | `GET /timetable-foundation/period-type/create` — create form |
| | `POST /timetable-foundation/period-type` — store |
| | `GET /timetable-foundation/period-type/{id}` — show |
| | `GET /timetable-foundation/period-type/{id}/edit` — edit form |
| | `PUT /timetable-foundation/period-type/{periodType}` — update |
| | `DELETE /timetable-foundation/period-type/{id}` — destroy (soft) |
| | `GET /timetable-foundation/period-type/trash/view` — trashed list |
| | `GET /timetable-foundation/period-type/{id}/restore` — restore |
| | `DELETE /timetable-foundation/period-type/{id}/force-delete` — force delete |
| | `POST /timetable-foundation/period-type/{periodType}/toggle-status` — toggle AJAX |
| Controller | `Modules\TimetableFoundation\Http\Controllers\PeriodTypeController`; `index()` (redirect), `create()`, `store()`, `show()`, `edit()`, `update()` (uses implicit binding), `destroy()`, `trashedPeriodType()`, `restore()`, `forceDelete()`, `toggleStatus()` |
| Model(s) | `Modules\TimetableFoundation\Models\PeriodType` (table: `tt_period_types`) |
| Validation (Create) | Inline in `store()` (no separate Form Request) |
| Validation (Update) | Inline in `update()` — unique rules ignore current ID |
| Policy | Implicit (no dedicated Policy file) — `Gate::authorize()` uses permission strings directly |
| Permissions | `timetable-foundation.period-type.viewAny` |
| | `timetable-foundation.period-type.view` |
| | `timetable-foundation.period-type.create` |
| | `timetable-foundation.period-type.update` |
| | `timetable-foundation.period-type.delete` |
| | `timetable-foundation.period-type.restore` |
| | `timetable-foundation.period-type.forceDelete` |
| Pagination | No pagination on main tab; 10 records per page on trash view |
| Soft Deletes | Yes — `SoftDeletes` trait on Model |
| Read-Only | No — full CRUD with system record protection |

---

## 2. Pre-conditions

- Admin user has all `timetable-foundation.period-type.*` permissions granted.
- Dusk environment variables set: `DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD`.
- Seeded system period types exist: TEACHING, THEORY, PRACTICAL, BREAK, LUNCH, ASSEMBLY, EXAM, RECESS, FREE_PERIOD (all `is_system = 1`).
- At least one non-system period type exists for update/delete tests (created fresh as needed).
- Tenant academic session, classes, sections, subjects not required for this CRUD screen (no FK dependencies at creation time).
- For FK RESTRICT tests, Period Config and Period Set Period records referencing a period type must exist.

---

## 3. Default Data Load

The `index()` method in `PeriodTypeController` redirects to `TimetableFoundationController@timetableMasters` with `tab=period-types`. That method queries period types, ordered by `ordinal`, no pagination.

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| Period Types list | `TimetableFoundationController@timetableMasters` | `PeriodType::orderBy('ordinal')->get()` | `pt_search` (name/code), `pt_status` (1/0) | None (master data) |

---

## 4. Test Data Strategy

- **System seed types**: Verify 9 system period types (TEACHING, THEORY, PRACTICAL, BREAK, LUNCH, ASSEMBLY, EXAM, RECESS, FREE_PERIOD) are present with `is_system = 1`.
- **Non-system types**: Create custom test types via UI for edit/delete/toggle tests — use unique codes e.g. `TEST_PTYPE_01`, `TEST_PTYPE_02`.
- **Break type**: Create a type with `is_break=true` (e.g. code=`SHORT_BREAK`) and verify business rule overrides.
- **Pre-test cleanup**: Ensure no test type codes collide — use a unique test prefix.
- **Child table data**: For dependency tests, create Period Config and Period Set Period records referencing a period type to verify RESTRICT behaviour.
- **Pagination overflow**: Create 12+ period types in trash to test the 10-record per-page limit (trash only).

---

## 5. Business Conditions

### 5.1 Database Schema — `tt_period_types`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | `id` | TINYINT UNSIGNED | PK, NOT NULL, AUTO_INCREMENT |
| BC-DB-02 | `code` | VARCHAR(30) | NOT NULL, UNIQUE (`uq_periodtype_code`) |
| BC-DB-03 | `name` | VARCHAR(100) | NOT NULL |
| BC-DB-04 | `description` | VARCHAR(255) | DEFAULT NULL |
| BC-DB-05 | `color_code` | VARCHAR(10) | DEFAULT NULL |
| BC-DB-06 | `icon` | VARCHAR(50) | DEFAULT NULL |
| BC-DB-07 | `is_schedulable` | TINYINT(1) | NOT NULL, DEFAULT 1 |
| BC-DB-08 | `counts_as_teaching` | TINYINT(1) | NOT NULL, DEFAULT 0 |
| BC-DB-09 | `counts_as_workload` | TINYINT(1) | NOT NULL, DEFAULT 0 |
| BC-DB-10 | `is_break` | TINYINT(1) | NOT NULL, DEFAULT 0 |
| BC-DB-11 | `is_free_period` | TINYINT(1) | NOT NULL, DEFAULT 0 |
| BC-DB-12 | `ordinal` | TINYINT UNSIGNED | NOT NULL, UNIQUE (`uq_periodtype_ordinal`) |
| BC-DB-13 | `duration_minutes` | INT UNSIGNED | DEFAULT 30 |
| BC-DB-14 | `is_active` | TINYINT(1) | NOT NULL, DEFAULT 1 |
| BC-DB-15 | `created_at` | TIMESTAMP | NULL DEFAULT CURRENT_TIMESTAMP |
| BC-DB-16 | `updated_at` | TIMESTAMP | NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP |
| BC-DB-17 | `deleted_at` | TIMESTAMP | NULL DEFAULT NULL |
| BC-DB-18 | UNIQUE KEY `uq_periodtype_code` | — | `code` |
| BC-DB-19 | UNIQUE KEY `uq_periodtype_ordinal` | — | `ordinal` |

### 5.2 Validation Rules — Inline in `store()` (Create)

| BC ID | Field | Rule(s) | Error Message |
|-------|-------|---------|---------------|
| BC-VAL-01 | `code` | `required`, `string`, `max:30`, `unique:tt_period_types,code` with `whereNull('deleted_at')` | Laravel default |
| BC-VAL-02 | `name` | `required`, `string`, `max:100` | Laravel default |
| BC-VAL-03 | `description` | `nullable`, `string`, `max:255` | Laravel default |
| BC-VAL-04 | `color_code` | `nullable`, `string`, `max:10`, `regex:/^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$/` | Laravel default |
| BC-VAL-05 | `icon` | `nullable`, `string`, `max:50` | Laravel default |
| BC-VAL-06 | `ordinal` | `required`, `integer`, `min:1`, `unique:tt_period_types,ordinal` with `whereNull('deleted_at')` | Laravel default |
| BC-VAL-07 | `is_schedulable` | `sometimes`, `boolean` | Normalized via `$request->boolean()` |
| BC-VAL-08 | `counts_as_teaching` | `sometimes`, `boolean` | Normalized via `$request->boolean()` |
| BC-VAL-09 | `counts_as_workload` | `sometimes`, `boolean` | Normalized via `$request->boolean()` |
| BC-VAL-10 | `is_break` | `sometimes`, `boolean` | Normalized via `$request->boolean()` |
| BC-VAL-11 | `is_free_period` | `sometimes`, `boolean` | Normalized via `$request->boolean()` |
| BC-VAL-12 | `is_active` | `sometimes` | Normalized via `$request->boolean()` |
| BC-VAL-13 | *Business rule: is_system* | `is_system` always set to `false` for user-created records | — |
| BC-VAL-14 | *Business rule: break overrides* | If `is_break=true`: `is_schedulable=false`, `counts_as_teaching=false`, `counts_as_workload=false` | — |

### 5.3 Validation Rules — Inline in `update()` (Update)

| BC ID | Field | Rule(s) | Error Message |
|-------|-------|---------|---------------|
| BC-VAL-15 | `name` | `required`, `string`, `max:100` | Laravel default |
| BC-VAL-16 | `description` | `nullable`, `string`, `max:255` | Laravel default |
| BC-VAL-17 | `color_code` | `nullable`, `string`, `max:10`, `regex:/^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$/` | Laravel default |
| BC-VAL-18 | `icon` | `nullable`, `string`, `max:50` | Laravel default |
| BC-VAL-19 | `ordinal` | `required`, `integer`, `min:1`, `unique:tt_period_types,ordinal` → ignores `$periodType->id` with `whereNull('deleted_at')` | Laravel default |
| BC-VAL-20 | `is_schedulable` | `sometimes`, `boolean` | — |
| BC-VAL-21 | `counts_as_teaching` | `sometimes`, `boolean` | — |
| BC-VAL-22 | `counts_as_workload` | `sometimes`, `boolean` | — |
| BC-VAL-23 | `is_break` | `sometimes`, `boolean` | — |
| BC-VAL-24 | `is_free_period` | `sometimes`, `boolean` | Normalized via `$request->boolean()` |
| BC-VAL-25 | `is_active` | `sometimes` | Normalized via `$request->boolean()` |
| BC-VAL-26 | *System protection* | For system records: `code`, `is_break`, `is_schedulable`, `counts_as_teaching`, `counts_as_workload` unset | — |
| BC-VAL-27 | *Business rule: break overrides* | For non-system records if `is_break=true`: overrides applied | — |

### 5.4 Authorization

| BC ID | Permission | Behavior |
|-------|-----------|----------|
| BC-AUTH-01 | `timetable-foundation.period-type.viewAny` | Without it → 403 on index / trashed list |
| BC-AUTH-02 | `timetable-foundation.period-type.view` | Without it → 403 on show |
| BC-AUTH-03 | `timetable-foundation.period-type.create` | Without it → 403 on create/store |
| BC-AUTH-04 | `timetable-foundation.period-type.update` | Without it → 403 on edit/update/toggleStatus |
| BC-AUTH-05 | `timetable-foundation.period-type.delete` | Without it → 403 on destroy/forceDelete |
| BC-AUTH-06 | `timetable-foundation.period-type.restore` | Without it → 403 on restore/trashed view |
| BC-AUTH-07 | `timetable-foundation.period-type.forceDelete` | Without it → 403 on forceDelete |
| BC-AUTH-08 | Guest access | Redirect to `/login` on any route |

### 5.5 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Screen loads with `tab=period-types` | Table list of period types rendered; each row shows ordinal, code, name, colour swatch, icon, boolean flags, Duration, System lock badge, status toggle, action buttons |
| BC-BIZ-02 | Search by `pt_search` | Period types matching name or code shown; non-matching hidden |
| BC-BIZ-03 | Filter by `pt_status=1` | Only active period types displayed |
| BC-BIZ-04 | Filter by `pt_status=0` | Only inactive period types displayed |
| BC-BIZ-05 | Empty period type list | "No period types found." placeholder displayed |
| BC-BIZ-06 | Create period type | `is_system` forced to `false`; activity logged; success flash |
| BC-BIZ-07 | Create break period type | `is_schedulable`, `counts_as_teaching`, `counts_as_workload` all forced to `false` |
| BC-BIZ-08 | Soft delete non-system period type | `is_active` set to false before `delete()`; record moved to trash |
| BC-BIZ-09 | Restore from trash | `is_active` set to true after `restore()` |
| BC-BIZ-10 | Toggle status on non-system type | AJAX POST flips `is_active`; JSON response |
| BC-BIZ-11 | System record update — code protected | `code` unset from validated data; cannot be changed |
| BC-BIZ-12 | System record update — core flags protected | `is_break`, `is_schedulable`, `counts_as_teaching`, `counts_as_workload` unset; cannot be changed |
| BC-BIZ-13 | System record update — other fields allowed | `name`, `description`, `color_code`, `icon`, `ordinal`, `duration_minutes`, `is_free_period`, `is_active` can be changed |
| BC-BIZ-14 | System record delete blocked | Redirect back with error `flash('operation_failed')` |
| BC-BIZ-15 | System record force delete blocked | Redirect back with error `flash('system_record_force_delete_not_allowed')` |
| BC-BIZ-16 | System record toggle status blocked | JSON 403 response with `flash('system_record_status_change_not_allowed')` |

### 5.6 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|------------------|----------------|
| BC-REF-01 | `tt_period_configs.period_type_id` | `tt_period_types.id` | RESTRICT |
| BC-REF-02 | `tt_period_set_periods_jnt.period_type_id` | `tt_period_types.id` | RESTRICT |

---

## 6. Test Case List

### 6.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|-----------------|---------|---------|--------|
| TC-P01 | Load period types tab | `GET /timetable-foundation/timetable-masters?tab=period-types` returns 200; table rendered with all period types ordered by ordinal; each row shows ordinal, code, name, colour swatch, icon, boolean flag badges, duration, system lock icon, status toggle, action buttons | — | — | ⬜ |
| TC-P02 | Search by code or name | Enter `TEACHING`; only matching types shown | — | — | ⬜ |
| TC-P03 | Filter by active status | Active filter; only `is_active=1` types displayed | — | — | ⬜ |
| TC-P04 | Filter by inactive status | Inactive filter; only `is_active=0` types displayed | — | — | ⬜ |
| TC-P05 | Reset filters | Reset clears all filters; all types shown | — | — | ⬜ |
| TC-P06 | Create — all fields filled | Code=`REMEDIAL`, name=`Remedial Period`, color_code=`#FFA500`, icon=`fa-book`, ordinal=`10`, duration=`45`, Schedulable+Workload checked; type created; `is_system=false` | — | — | ⬜ |
| TC-P07 | Create — required fields only | Code=`TEST`, name=`Test Type`, ordinal=`15`; defaults applied (schedulable=true, other flags false, duration=30, active=true) | — | — | ⬜ |
| TC-P08 | Create break type — business rule | Code=`SHORT_BREAK`, Is Break checked + Schedulable also checked; saved with `is_schedulable=false`, `counts_as_teaching=false`, `counts_as_workload=false` | — | — | ⬜ |
| TC-P09 | View details | Show page displays all fields: Code, Name, Description, Color Code swatch, Icon, all boolean flags, Ordinal, Duration, Is System badge, timestamps | — | — | ⬜ |
| TC-P10 | Edit non-system type | Change name, uncheck Schedulable, check Teaching; update succeeds | — | — | ⬜ |
| TC-P11 | Edit system record — limited fields | Description and colour changeable; code and core flags protected | — | — | ⬜ |
| TC-P12 | Edit system record — core flags protected | Core flag changes silently ignored on save | — | — | ⬜ |
| TC-P13 | Toggle status on non-system type | AJAX toggle; JSON `{"success":true, "is_active":true}` | — | — | ⬜ |
| TC-P14 | Soft delete non-system type | Deactivated then soft-deleted; removed from main list | — | — | ⬜ |
| TC-P15 | Trash view | Soft-deleted records shown with restore/force-delete actions | — | — | ⬜ |
| TC-P16 | Restore from trash | Restored with `is_active=true`; reappears in main list | — | — | ⬜ |
| TC-P17 | Force delete from trash | Permanently removed; record gone from DB | — | — | ⬜ |
| TC-P18 | Trash pagination | 12+ deleted records; page 2 shows remaining records | — | — | ⬜ |

### 6.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|-----------------|---------|---------|--------|
| TC-N01 | Missing required fields | Empty code, name, ordinal → validation errors | — | — | ⬜ |
| TC-N02 | Duplicate code | Code `TEACHING` already exists → unique error | — | — | ⬜ |
| TC-N03 | Duplicate ordinal | Ordinal `5` already exists → unique error | — | — | ⬜ |
| TC-N04 | Ordinal < 1 | Ordinal `0` → min:1 validation error | — | — | ⬜ |
| TC-N05 | Code too long | 31+ characters → max:30 error | — | — | ⬜ |
| TC-N06 | Name too long | 101+ characters → max:100 error | — | — | ⬜ |
| TC-N07 | Description too long | 256+ characters → max:255 error | — | — | ⬜ |
| TC-N08 | Invalid hex colour | `color_code=red` → regex error | — | — | ⬜ |
| TC-N09 | Invalid hex colour format | `color_code=#GGGGGG` → regex error | — | — | ⬜ |
| TC-N10 | Delete system record blocked | Click delete on TEACHING; redirect with error `flash('operation_failed')` | — | — | ⬜ |
| TC-N11 | Force delete system record blocked | Redirect with error `flash('system_record_force_delete_not_allowed')` | — | — | ⬜ |
| TC-N12 | Toggle status on system record — 403 | JSON 403 error response | — | — | ⬜ |
| TC-N13 | Guest access | Redirect to `/login` | — | — | ⬜ |
| TC-N14 | Missing viewAny permission | 403 on index | — | — | ⬜ |
| TC-N15 | Missing create permission | 403 on create/store | — | — | ⬜ |
| TC-N16 | Non-existent ID | show/edit/update/destroy for ID 9999 → 404 | — | — | ⬜ |
| TC-N17 | FK RESTRICT — Period Config exists | Delete blocked by FK constraint | — | — | ⬜ |
| TC-N18 | FK RESTRICT — Period Set Period exists | Delete blocked by FK constraint | — | — | ⬜ |

### 6.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|-----------------|---------|---------|--------|
| TC-D01 | A | Delete type with Period Config records | FK RESTRICT (`fk_pc_period_type`) blocks deletion | — | — | ⬜ |
| TC-D02 | A | Delete type with Period Set Period records | FK RESTRICT (`fk_psp_period_type`) blocks deletion | — | — | ⬜ |
| TC-D03 | B | System record — edit core flags protected | `code`, `is_break`, `is_schedulable`, `counts_as_teaching`, `counts_as_workload` unchanged | — | — | ⬜ |
| TC-D04 | B | System record — delete blocked | Cannot soft-delete or force-delete | — | — | ⬜ |
| TC-D05 | B | System record — toggle status blocked | JSON 403 response | — | — | ⬜ |
| TC-D06 | C | Break rule — forces schedulable=false | Create with is_break=true; `is_schedulable=false` | — | — | ⬜ |
| TC-D07 | C | Break rule — forces counts_as_teaching=false | Create with is_break=true; `counts_as_teaching=false` | — | — | ⬜ |
| TC-D08 | C | Break rule — forces counts_as_workload=false | Create with is_break=true; `counts_as_workload=false` | — | — | ⬜ |
| TC-D09 | C | Break rule — update non-system set is_break=true | Flags forced to false on update | — | — | ⬜ |
| TC-D10 | D | is_system always false for user-created | Create type; `is_system=false` in DB | — | — | ⬜ |
| TC-D11 | E | Activity logging on all state changes | Each state change creates log entry | — | — | ⬜ |
| TC-D12 | F | Model `$fillable` matches DDL | 14 columns in fillable array match DDL | — | — | ⬜ |
| TC-D13 | F | Model `$casts` for booleans/integers | 6 boolean + 2 integer + 3 datetime casts | — | — | ⬜ |
| TC-D14 | G | Unique `code` constraint (DB) | Duplicate code → SQL integrity violation | — | — | ⬜ |
| TC-D15 | G | Unique `ordinal` constraint (DB) | Duplicate ordinal → SQL integrity violation | — | — | ⬜ |
| TC-D16 | H | Model `$attributes` defaults | New instance: schedulable=true, other flags false, ordinal=1, duration=30 | — | — | ⬜ |

### 6.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|-----------------|---------|---------|--------|
| TC-CR01 | CR | P1 | Model — `$fillable` matches DDL | All 14 fillable columns present; no extras | — | — | ◌ |
| TC-CR02 | CR | P1 | Model — `$casts` for booleans/integers/dates | 6 boolean, 2 integer, 3 datetime casts | — | — | ◌ |
| TC-CR03 | CR | P1 | Model — SoftDeletes trait | `SoftDeletes` imported; `deleted_at` in casts | — | — | ◌ |
| TC-CR04 | CR | P1 | Model — `$attributes` defaults | All 8 defaults correctly set | — | — | ◌ |
| TC-CR05 | CR | P1 | Model — relationships defined | `periodSetPeriods()` hasMany with correct FK | — | — | ◌ |
| TC-CR06 | CR | P1 | Controller — exception handling | All write methods handle exceptions gracefully | — | — | ◌ |
| TC-CR07 | CR | P1 | Controller — DB transactions | `destroy()` and `restore()` wrapped | — | — | ◌ |
| TC-CR08 | CR | P1 | Controller — `Gate::authorize()` on every method | Every public method gates before logic | — | — | ◌ |
| TC-CR09 | CR | P1 | Controller — activity logging | All state changes log activity | — | — | ◌ |
| TC-CR10 | CR | P1 | Controller — is_active on delete/restore | `is_active=false` before `delete()`; `true` after `restore()` | — | — | ◌ |
| TC-CR11 | CR | P1 | Controller — toggleStatus flips is_active | Validates, updates, returns JSON | — | — | ◌ |
| TC-CR12 | CR | P1 | Controller — trash/restore/forceDelete flow | `onlyTrashed()`, `withTrashed()`, `paginate(10)` used correctly | — | — | ◌ |
| TC-CR13 | CR | P1 | Controller — flash/JSON responses | Redirect with flash on writes; JSON on toggle | — | — | ◌ |
| TC-CR14 | CR | P1 | Controller — system record protection | `destroy()`, `forceDelete()`, `toggleStatus()`, `update()` all check `is_system` | — | — | ◌ |
| TC-CR15 | CR | P1 | Controller — is_system=false on store | `$validated['is_system'] = false` before create | — | — | ◌ |
| TC-CR16 | CR | P1 | Controller — break rule enforcement | Overrides applied on both create and update | — | — | ◌ |
| TC-CR17 | CR | P1 | Validation — rules cover all fields | Code/ordinal unique rules with ignore on update | — | — | ◌ |
| TC-CR18 | CR | P1 | Routes — resource + custom routes | Resource generates 7 routes; 4 custom routes registered | — | — | ◌ |
| TC-CR19 | CR | P1 | View — @can directives | Action buttons gated by permissions; lock icon on system types | — | — | ◌ |
| TC-CR20 | CR | P1 | Breadcrumb config | Breadcrumb renders correct hierarchy | — | — | ◌ |

---

## 7. Detailed Test Steps

#### TC-CR01: Model — `$fillable` Matches DDL Columns

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `PeriodType.php` `$fillable` array | Contains: code, name, description, color_code, icon, is_schedulable, counts_as_teaching, counts_as_workload, is_break, is_free_period, ordinal, duration_minutes, is_active, created_by |
| 2 | Cross-reference with `tt_period_types` DDL | All 14 fillable columns exist in DDL; no fillable column absent |

#### TC-CR02: Model — `$casts` for Booleans/Integers/Dates

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `$casts` array | 6 boolean + ordinal→integer + duration_minutes→integer + 3 timestamps→datetime |

#### TC-CR03: Model — SoftDeletes Trait

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `PeriodType.php` imports | `use SoftDeletes;` present from `Illuminate\Database\Eloquent\SoftDeletes` |
| 2 | Verify `deleted_at` in `$casts` | `'deleted_at' => 'datetime'` present in `$casts` array |

#### TC-CR04: Model — `$attributes` Default Values

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `PeriodType.php` `$attributes` array | All 8 defaults correctly set: `is_schedulable`→`true`, `counts_as_teaching`→`false`, `counts_as_workload`→`false`, `is_break`→`false`, `is_free_period`→`false`, `is_system`→`false`, `ordinal`→`1`, `duration_minutes`→`30` |

#### TC-CR05: Model — Relationships Defined

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `PeriodType.php` | `periodSetPeriods()` returns `$this->hasMany(PeriodSetPeriod::class, 'period_type_id')` with correct FK |

#### TC-CR06: Controller — Exception Handling

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `PeriodTypeController.php` `store()` method | Wrapped in `try-catch`; validation or database exceptions handled; error flash on failure |
| 2 | Inspect `update()`, `destroy()`, `forceDelete()`, `restore()`, `toggleStatus()` methods | Each method has try-catch handling; unhandled exceptions do not propagate to user as 500 errors |

#### TC-CR07: Controller — DB Transactions

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `destroy()` method | Wraps `is_active=false` update and `delete()` call in `DB::transaction()` |
| 2 | Inspect `restore()` method | Wraps `restore()` call and `is_active=true` update in `DB::transaction()` |

#### TC-CR08: Controller — `Gate::authorize()` on Every Method

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect each public method in `PeriodTypeController.php` | Every method (`index`, `create`, `store`, `show`, `edit`, `update`, `destroy`, `trashedPeriodType`, `restore`, `forceDelete`, `toggleStatus`) calls `Gate::authorize()` with appropriate `timetable-foundation.period-type.*` permission before any logic |

#### TC-CR09: Controller — Activity Logging

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `store()`, `update()`, `destroy()`, `forceDelete()`, `restore()`, `toggleStatus()` methods | Each state-changing method calls `activityLog()` with correct action: `'Created'`, `'Updated'`, `'Trashed'`, `'Deleted'`, `'Restored'`, `'Toggled'` respectively |

#### TC-CR10: Controller — `is_active` on Delete/Restore

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `destroy()` method | Sets `is_active=false` before calling `delete()` |
| 2 | Inspect `restore()` method | Calls `restore()` then sets `is_active=true` |

#### TC-CR11: Controller — `toggleStatus()` Flips `is_active`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `toggleStatus()` method | Validates incoming `is_active` boolean; updates model's `is_active` to the new value |
| 2 | Verify response format | Returns JSON `{"success": true, "is_active": <new_value>, "message": "..."}` or error JSON on failure |

#### TC-CR12: Controller — Trash/Restore/ForceDelete Flow

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `trashedPeriodType()` method | Uses `PeriodType::onlyTrashed()->paginate(10)` for trash listing |
| 2 | Inspect `restore()` method | Uses `PeriodType::onlyTrashed()->findOrFail($id)` |
| 3 | Inspect `forceDelete()` method | Uses `PeriodType::withTrashed()->findOrFail($id)` |

#### TC-CR13: Controller — Flash/JSON Responses

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect write methods (store, update, destroy, restore, forceDelete) | Each returns `redirect()` with `->with('success', ...)` or `->with('error', ...)` flash message |
| 2 | Inspect `toggleStatus()` method | Returns `response()->json([...])` (not a redirect) |

#### TC-CR14: Controller — System Record Protection

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `destroy()` method | Checks `$periodType->is_system`; if true, redirects back with `flash('operation_failed')` error; does not delete |
| 2 | Inspect `forceDelete()` method | Checks `is_system`; redirects with `flash('system_record_force_delete_not_allowed')` |
| 3 | Inspect `toggleStatus()` method | Checks `is_system`; returns JSON 403 response with `flash('system_record_status_change_not_allowed')` |
| 4 | Inspect `update()` method | Unsets `code`, `is_break`, `is_schedulable`, `counts_as_teaching`, `counts_as_workload` from validated data for system records before saving |

#### TC-CR15: Controller — `is_system=false` on Store

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `store()` method | Sets `$validated['is_system'] = false` or explicitly assigns `$periodType->is_system = false` before `save()` to ensure user-created records never have `is_system=true` |

#### TC-CR16: Controller — Break Rule Enforcement

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `store()` method | If `is_break` is true, forces `is_schedulable=false`, `counts_as_teaching=false`, `counts_as_workload=false` before save |
| 2 | Inspect `update()` method | Same break-rule overrides applied when `is_break=true` for non-system records |

#### TC-CR17: Validation — Rules Cover All Fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `store()` validation rules | `code` has `unique:tt_period_types,code` with `whereNull('deleted_at')`; `ordinal` has unique rule; `color_code` has regex for hex colour; all boolean fields use `sometimes`, `boolean` |
| 2 | Inspect `update()` validation rules | Unique rules use `->ignore($periodType->id)->whereNull('deleted_at')`; colour regex present; boolean fields normalized |

#### TC-CR18: Routes — Resource + Custom Routes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect route definitions | `Route::resource('period-type', PeriodTypeController::class)` generates 7 resource routes |
| 2 | Locate custom routes | 4 custom routes: `trash/view`, `{id}/restore`, `{id}/force-delete`, `{periodType}/toggle-status` registered with correct HTTP verbs |

#### TC-CR19: View — `@can` Directives

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect period-type Blade views | Action buttons gated by `@can('timetable-foundation.period-type.*')` directives; system records show lock icon instead of edit/delete buttons (or buttons disabled) |
| 2 | Verify system record UI | System records display a system lock badge; delete/toggle actions hidden or disabled for system records |

#### TC-CR20: Breadcrumb Config

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `config/breadcrumb.php` | Period-type routes registered with correct hierarchy: Timetable Masters → Period Types |
| 2 | Verify sub-routes | Create, edit, show, trash routes have correct parent breadcrumb links pointing to the period-types tab

---

### 7.1 Positive TC Steps

#### TC-P01: Load Period Types Tab

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Log in as admin | Dashboard loads |
| 2 | Navigate to `?tab=period-types` | HTTP 200; table with all period types ordered by ordinal |
| 3 | Verify row content | Each row shows ordinal, code, name, colour swatch, icon text, boolean flag badges, duration, system lock icon, status toggle, action buttons |

#### TC-P02: Search by Code or Name

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Search `TEACHING` | Only matching types shown |
| 2 | Clear and submit empty | All types shown |

#### TC-P03: Filter by Active Status

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select "Active", submit | Only `is_active=1` types shown |

#### TC-P04: Filter by Inactive Status

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select "Inactive", submit | Only `is_active=0` types shown |

#### TC-P05: Reset Filters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Apply filters, click reset | All types shown; filters cleared |

#### TC-P06: Create Period Type — All Fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to create form | Form rendered |
| 2 | Fill code=`REMEDIAL`, name=`Remedial Period`, description=`Extra help session`, color_code=`#FFA500`, icon=`fa-book`, ordinal=`10`, duration=`45`, check Schedulable, check Counts as Workload | — |
| 3 | Submit | POST; redirect with success flash; `is_system=false` in DB |

#### TC-P07: Create — Required Fields Only

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Fill code=`TEST`, name=`Test Type`, ordinal=`15`, submit | Defaults: schedulable=true, all other flags false, duration=30, active=true |

#### TC-P08: Create Break Type — Business Rule

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Fill code=`SHORT_BREAK`, name=`Short Break`, ordinal=`11`, check "Is Break", also check "Schedulable" | Submit; DB shows `is_schedulable=false`, `counts_as_teaching=false`, `counts_as_workload=false` |

#### TC-P09: View Details

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to show for a period type | All fields displayed with badges for boolean flags |

#### TC-P10: Edit Non-System Type

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Edit a non-system type; change name, uncheck Schedulable, check Teaching | Submit; update succeeds; values persisted |

#### TC-P11: Edit System Record — Limited

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Edit TEACHING; code field disabled; change description and colour | Update succeeds; code and core flags unchanged |

#### TC-P12: Edit System Record — Core Flags Protected

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Edit TEACHING via direct API call with modified core flags | Core flag values unchanged in DB |

#### TC-P13: Toggle Status Non-System

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Toggle switch on inactive non-system type | JSON `{"success":true, "is_active":true}` |

#### TC-P14: Soft Delete Non-System

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click trash on non-system type | Deactivated + soft-deleted; removed from main list |

#### TC-P15: Trash View

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to trash view | Deleted types shown with restore/force-delete actions |

#### TC-P16: Restore from Trash

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click restore on deleted type | Restored; `is_active=true`; reappears in main list |

#### TC-P17: Force Delete from Trash

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click force delete | Permanently removed; record deleted from DB |

#### TC-P18: Trash Pagination

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 12+ deleted types, view trash | Page 1 shows 10; page 2 shows remaining |

---

### 7.2 Negative TC Steps

#### TC-N01: Missing Required Fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit empty code, name, ordinal | Validation errors: required for all three |

#### TC-N02: Duplicate Code

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit code `TEACHING` | Validation error: code must be unique |

#### TC-N03: Duplicate Ordinal

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit existing ordinal | Validation error: ordinal must be unique |

#### TC-N04: Ordinal < 1

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit `ordinal=0` | Validation: min:1 |

#### TC-N05: Code Too Long

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit 31+ char code | Validation: max:30 |

#### TC-N06: Name Too Long

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit 101+ char name | Validation: max:100 |

#### TC-N07: Description Too Long

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit 256+ char description | Validation: max:255 |

#### TC-N08: Invalid Hex Colour

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit `color_code=red` | Regex validation error |

#### TC-N09: Invalid Hex Format

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit `color_code=#GGGGGG` | Regex validation error |

#### TC-N10: Delete System Record

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click delete on TEACHING | Redirect back with error `flash('operation_failed')`; `deleted_at` null |

#### TC-N11: Force Delete System Record

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Attempt force delete on TEACHING | Redirect with error `flash('system_record_force_delete_not_allowed')` |

#### TC-N12: Toggle Status on System Record

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Toggle TEACHING status | JSON 403 `{success:false, is_active:true, message:"..."}` |

#### TC-N13: Guest Access

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Log out, visit period-type route | Redirect to `/login` |

#### TC-N14: Missing viewAny

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without viewAny accesses index | 403 Forbidden |

#### TC-N15: Missing create

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without create accesses create/store | 403 Forbidden |

#### TC-N16: Non-Existent ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Access `/period-type/9999` or `/9999/edit` | HTTP 404 |

#### TC-N17: FK RESTRICT — Period Config

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Delete type used in Period Config | FK RESTRICT blocks; integrity violation |

#### TC-N18: FK RESTRICT — Period Set Period

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Delete type used in Period Set Period | FK RESTRICT blocks; integrity violation |

---

### 7.3 Dependency TC Steps

#### TC-D01: FK RESTRICT — Period Config

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Identify type referenced by Period Config | — |
| 2 | Attempt to delete via UI | FK RESTRICT blocks deletion; integrity constraint violation |

#### TC-D02: FK RESTRICT — Period Set Period

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Identify type referenced by Period Set Period | — |
| 2 | Attempt to delete via UI | FK RESTRICT blocks deletion; integrity constraint violation |

#### TC-D03: System Record — Core Flags Protected

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Edit a system type, attempt to change code and core flags | DB shows unchanged code and core flag values |

#### TC-D04: System Record — Delete Blocked

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click delete on system type | Error flash; `deleted_at` null in DB |

#### TC-D05: System Record — Toggle Blocked

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Toggle status on system type | HTTP 403; JSON error response |

#### TC-D06: Break Rule — Schedulable Forced False

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create type with is_break=true | DB: `is_schedulable=false` |

#### TC-D07: Break Rule — Teaching Forced False

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create type with is_break=true | DB: `counts_as_teaching=false` |

#### TC-D08: Break Rule — Workload Forced False

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create type with is_break=true | DB: `counts_as_workload=false` |

#### TC-D09: Break Rule — Update Non-System

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Edit non-system type, set is_break=true | After save: schedulable/teaching/workload all false |

#### TC-D10: is_system False for User-Created

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create type via UI | DB: `is_system=0` |

#### TC-D11: Activity Logging

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Perform create, update, delete, restore, toggle | Activity log entries created for each action |

#### TC-D12: Model `$fillable` Matches DDL

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `$fillable` | 14 columns matching DDL (excludes id, timestamps, deleted_at) |

#### TC-D13: Model `$casts`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `$casts` | 6 boolean, 2 integer, 3 datetime casts |

#### TC-D14: Unique Code Constraint (DB)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | SQL insert duplicate code | Integrity constraint violation for `uq_periodtype_code` |

#### TC-D15: Unique Ordinal Constraint (DB)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | SQL insert duplicate ordinal | Integrity constraint violation for `uq_periodtype_ordinal` |

#### TC-D16: Model `$attributes` Defaults

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `$attributes` array | 8 defaults correctly set |

---

