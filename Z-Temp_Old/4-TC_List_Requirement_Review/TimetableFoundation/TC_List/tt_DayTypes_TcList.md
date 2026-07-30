# tt_DayTypes_TcList

## Module: TimetableFoundation → Timetable Masters → Day Types

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | TimetableFoundation |
| Tab Group | Timetable Masters |
| Feature | Day Types |
| URL(s) | `GET /timetable-foundation/day-type` — redirects to `timetable-foundation.menu.timetableMasters?tab=day-types` |
| | `GET /timetable-foundation/day-type/create` — create form |
| | `POST /timetable-foundation/day-type` — store |
| | `GET /timetable-foundation/day-type/{id}` — show |
| | `GET /timetable-foundation/day-type/{id}/edit` — edit form |
| | `PUT /timetable-foundation/day-type/{id}` — update |
| | `DELETE /timetable-foundation/day-type/{id}` — destroy (soft) |
| | `GET /timetable-foundation/day-type/trash/view` — trashed list |
| | `GET /timetable-foundation/day-type/{id}/restore` — restore |
| | `DELETE /timetable-foundation/day-type/{id}/force-delete` — force delete |
| | `POST /timetable-foundation/day-type/{dayType}/toggle-status` — toggle AJAX |
| Controller | `Modules\TimetableFoundation\Http\Controllers\DayTypeController`; `index()` (redirect), `create()`, `store()`, `show()`, `edit()`, `update()`, `destroy()`, `trashedDayType()`, `restore()`, `forceDelete()`, `toggleStatus()` |
| Model(s) | `Modules\TimetableFoundation\Models\DayType` (table: `tt_day_types`) |
| Validation (Create) | Inline in `store()` (no separate Form Request) |
| Validation (Update) | Inline in `update()` — unique rules ignore current ID |
| Policy | Implicit (no dedicated Policy file) — `Gate::authorize()` uses permission strings directly |
| Permissions | `timetable-foundation.day-type.viewAny` |
| | `timetable-foundation.day-type.view` |
| | `timetable-foundation.day-type.create` |
| | `timetable-foundation.day-type.update` |
| | `timetable-foundation.day-type.delete` |
| | `timetable-foundation.day-type.restore` |
| | `timetable-foundation.day-type.forceDelete` |
| Pagination | No pagination on main tab; 10 records per page on trash view |
| Soft Deletes | Yes — `SoftDeletes` trait on Model |
| Read-Only | No — full CRUD |

---

## 2. Pre-conditions

- Admin user has all `timetable-foundation.day-type.*` permissions granted.
- Dusk environment variables set: `DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD`.
- No seed data is strictly required, but standard types (STUDY, HOLIDAY, EXAM, PTM_DAY, SPORTS_DAY, ANNUAL_DAY) are assumed present for reference.
- Tenant academic session, classes, sections, subjects not required for this CRUD screen (no FK dependencies at creation time).
- At least one day type exists for edit/delete tests (created fresh as needed).

---

## 3. Default Data Load

The `index()` method in `DayTypeController` redirects to `TimetableFoundationController@timetableMasters` with `tab=day-types`. That method queries day types, ordered by `ordinal`, no pagination.

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| Day Types list | `TimetableFoundationController@timetableMasters` | `DayType::orderBy('ordinal')->get()` | `dt_search` (name/code), `dt_status` (1/0) | None (master data) |

---

## 4. Test Data Strategy

- **Standard day types**: Create 6 standard types via UI: STUDY (ord 1, working), HOLIDAY (ord 2, not working), EXAM (ord 3, not working, reduced), PTM_DAY (ord 4, working, reduced), SPORTS_DAY (ord 5, not working, reduced), ANNUAL_DAY (ord 6, not working), or verify they exist if seeded.
- **Test types**: Create additional test types via UI for edit/delete/toggle tests — use unique codes e.g. `TEST_TYPE_01`, `TEST_TYPE_02`.
- **Pre-test cleanup**: Ensure no test type codes collide — use a unique test prefix.
- **Child table data**: For dependency tests, create Working Day records referencing a day type to verify RESTRICT behaviour.
- **Pagination overflow**: Create 12+ day types in trash to test the 10-record per-page limit (trash only).

---

## 5. Business Conditions

### 5.1 Database Schema — `tt_day_types`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | `id` | TINYINT UNSIGNED | PK, NOT NULL, AUTO_INCREMENT |
| BC-DB-02 | `code` | VARCHAR(20) | NOT NULL, UNIQUE (`uq_daytype_code`) |
| BC-DB-03 | `name` | VARCHAR(100) | NOT NULL, UNIQUE (`uq_daytype_name`) |
| BC-DB-04 | `description` | VARCHAR(255) | DEFAULT NULL |
| BC-DB-05 | `is_working_day` | TINYINT(1) | NOT NULL, DEFAULT 1 |
| BC-DB-06 | `reduced_periods` | TINYINT(1) | NOT NULL, DEFAULT 0 |
| BC-DB-07 | `ordinal` | TINYINT UNSIGNED | NOT NULL, UNIQUE (`uq_daytype_ordinal`) |
| BC-DB-08 | `is_active` | TINYINT(1) | NOT NULL, DEFAULT 1 |
| BC-DB-09 | `created_at` | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |
| BC-DB-10 | `updated_at` | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP |
| BC-DB-11 | `deleted_at` | TIMESTAMP | NULL DEFAULT NULL |
| BC-DB-12 | UNIQUE KEY `uq_daytype_code` | — | `code` |
| BC-DB-13 | UNIQUE KEY `uq_daytype_name` | — | `name` |
| BC-DB-14 | UNIQUE KEY `uq_daytype_ordinal` | — | `ordinal` |

### 5.2 Validation Rules — Inline in `store()` (Create)

| BC ID | Field | Rule(s) | Error Message |
|-------|-------|---------|---------------|
| BC-VAL-01 | `code` | `required`, `string`, `max:20`, `unique:tt_day_types,code` with `whereNull('deleted_at')` | Laravel default |
| BC-VAL-02 | `name` | `required`, `string`, `max:100`, `unique:tt_day_types,name` with `whereNull('deleted_at')` | Laravel default |
| BC-VAL-03 | `description` | `nullable`, `string`, `max:255` | Laravel default |
| BC-VAL-04 | `ordinal` | `required`, `integer`, `min:1`, `unique:tt_day_types,ordinal` with `whereNull('deleted_at')` | Laravel default |
| BC-VAL-05 | `is_active` | `required` | Laravel default |
| BC-VAL-06 | *Code normalization* | `strtoupper()` applied to `code` before create | — |
| BC-VAL-07 | *Checkbox normalization* | `is_working_day` → `$request->boolean()`; `reduced_periods` → `$request->boolean()`; `is_active` → `$request->boolean()` | — |

### 5.3 Validation Rules — Inline in `update()` (Update)

| BC ID | Field | Rule(s) | Error Message |
|-------|-------|---------|---------------|
| BC-VAL-08 | `code` | `required`, `string`, `max:20`, `unique:tt_day_types,code` → ignores current ID with `whereNull('deleted_at')` | Laravel default |
| BC-VAL-09 | `name` | `required`, `string`, `max:100`, `unique:tt_day_types,name` → ignores current ID with `whereNull('deleted_at')` | Laravel default |
| BC-VAL-10 | `description` | `nullable`, `string`, `max:255` | Laravel default |
| BC-VAL-11 | `ordinal` | `required`, `integer`, `min:1`, `unique:tt_day_types,ordinal` → ignores current ID with `whereNull('deleted_at')` | Laravel default |
| BC-VAL-12 | `is_working_day` | `nullable`, `boolean` | Laravel default |
| BC-VAL-13 | `reduced_periods` | `nullable`, `boolean` | Laravel default |
| BC-VAL-14 | `is_active` | `nullable` (normalized via `$request->boolean()`) | — |

### 5.4 Authorization

| BC ID | Permission | Behavior |
|-------|-----------|----------|
| BC-AUTH-01 | `timetable-foundation.day-type.viewAny` | Without it → 403 on index / trashed list |
| BC-AUTH-02 | `timetable-foundation.day-type.view` | Without it → 403 on show |
| BC-AUTH-03 | `timetable-foundation.day-type.create` | Without it → 403 on create/store |
| BC-AUTH-04 | `timetable-foundation.day-type.update` | Without it → 403 on edit/update/toggleStatus |
| BC-AUTH-05 | `timetable-foundation.day-type.delete` | Without it → 403 on destroy/forceDelete |
| BC-AUTH-06 | `timetable-foundation.day-type.restore` | Without it → 403 on restore/trashed view |
| BC-AUTH-07 | `timetable-foundation.day-type.forceDelete` | Without it → 403 on forceDelete |
| BC-AUTH-08 | Guest access | Redirect to `/login` on any route |

### 5.5 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Screen loads with `tab=day-types` | Table list of day types rendered; each row shows ordinal, code, name, description, Working Day (Yes/No badge), Reduced Periods (Yes/No badge), status toggle, action buttons |
| BC-BIZ-02 | Search by `dt_search` | Day types matching name or code (case-insensitive substring) shown; non-matching hidden |
| BC-BIZ-03 | Filter by `dt_status=1` | Only active day types displayed |
| BC-BIZ-04 | Filter by `dt_status=0` | Only inactive day types displayed |
| BC-BIZ-05 | Empty day type list | "No day types found." or equivalent placeholder displayed |
| BC-BIZ-06 | Create day type | Code auto-uppercased via `strtoupper()`; `is_working_day` default true; `reduced_periods` default false; activity logged |
| BC-BIZ-07 | Soft delete a day type | `is_active` set to false before `delete()`; record moved to trash |
| BC-BIZ-08 | Restore from trash | `is_active` set to true after `restore()`; record reappears in main list |
| BC-BIZ-09 | Toggle status | AJAX POST flips `is_active`; JSON success/error response |
| BC-BIZ-10 | Update day type | Code auto-uppercased again on update; activity logged with 'Updated' |

### 5.6 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|------------------|----------------|
| BC-REF-01 | `tt_working_days.day_type1_id` | `tt_day_types.id` | RESTRICT |
| BC-REF-02 | `tt_working_days.day_type2_id` | `tt_day_types.id` | RESTRICT |
| BC-REF-03 | `tt_working_days.day_type3_id` | `tt_day_types.id` | RESTRICT |
| BC-REF-04 | `tt_working_days.day_type4_id` | `tt_day_types.id` | RESTRICT |

---

## 6. Test Case List

### 6.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|-----------------|---------|---------|--------|
| TC-P01 | Load day types tab on Timetable Masters page | `GET /timetable-foundation/timetable-masters?tab=day-types` returns 200; table rendered with all day types ordered by ordinal; each row shows: ordinal (#), code, name, description, Working Day (Yes/No badge), Reduced Periods (Yes/No badge), status toggle, action buttons | — | — | ⬜ |
| TC-P02 | Search day types by code or name | Enter `HOLIDAY` in search box, submit; only day types with code/name containing "HOLIDAY" shown | — | — | ⬜ |
| TC-P03 | Filter by active status | Select "Active" from status dropdown; only day types with `is_active = 1` displayed | — | — | ⬜ |
| TC-P04 | Filter by inactive status | Select "Inactive" from status dropdown; only day types with `is_active = 0` displayed | — | — | ⬜ |
| TC-P05 | Reset filters | Apply search and status filter, then click reset; all day types shown without filters | — | — | ⬜ |
| TC-P06 | Create day type — all fields filled | Fill code=`cultural_fest`, name=`Cultural Fest`, description=`Annual cultural festival`, ordinal=`7`, is_working_day=unchecked, reduced_periods=checked, Active=checked; submit; code auto-uppercased to `CULTURAL_FEST`; redirect to tab; success flash | — | — | ⬜ |
| TC-P07 | Create day type — required fields only | Fill code=`TEST`, name=`Test Day Type`, ordinal=`10`; leave description unchecked; submit; day type created with defaults (is_working_day=true, reduced_periods=false, is_active=true) | — | — | ⬜ |
| TC-P08 | View day type details | Navigate to show page for a day type; all fields displayed: Code, Name, Description, Is Working Day (Yes/No badge), Reduced Periods (Yes/No badge), Ordinal, Is Active, Created At, Updated At | — | — | ⬜ |
| TC-P09 | Edit day type — update name and flags | Navigate to edit page for a day type; change name to `Updated Type`, uncheck is_working_day, check reduced_periods; submit; update succeeds; redirect to tab; success flash; values updated | — | — | ⬜ |
| TC-P10 | Toggle active status via AJAX | POST to toggle-status endpoint with `is_active=true` for an inactive day type; JSON response `{"success":true, "is_active":true, "message":"..."}`; DB updated | — | — | ⬜ |
| TC-P11 | Toggle status — failure returns 422 | Simulate DB save failure on toggle; JSON `{"success":false, "is_active":..., "message":flash('status_switch_failed.day_type')}` with HTTP 422 | — | — | ⬜ |
| TC-P12 | Soft delete day type | Click delete on a day type; `is_active` set to false; record soft-deleted; redirect to tab; success flash; record no longer in main list | — | — | ⬜ |
| TC-P13 | Trash view loads soft-deleted day types | Navigate to trash view; soft-deleted records shown with code, name, status "Inactive" badge, restore and force-delete action buttons | — | — | ⬜ |
| TC-P14 | Restore day type from trash | Click restore on a soft-deleted day type; `restore()` called; `is_active` set to true; redirect; success flash; record reappears in main list | — | — | ⬜ |
| TC-P15 | Force delete day type from trash | Click force delete on a soft-deleted day type; record permanently deleted; redirect to trash; success flash; record gone | — | — | ⬜ |
| TC-P16 | Trash view pagination | Create 12+ soft-deleted day types; navigate to page 2 of trash view; remaining records shown with correct pagination | — | — | ⬜ |

### 6.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|-----------------|---------|---------|--------|
| TC-N01 | Create day type — missing required fields | Submit with empty code, name, ordinal; validation errors for `code`, `name`, `ordinal` (required) | — | — | ⬜ |
| TC-N02 | Create day type — duplicate code | Submit with code `HOLIDAY` (already exists); validation error: `code` must be unique | — | — | ⬜ |
| TC-N03 | Create day type — duplicate name | Submit with name `Holiday` (already exists); validation error: `name` must be unique | — | — | ⬜ |
| TC-N04 | Create day type — duplicate ordinal | Submit with ordinal `2` (already exists); validation error: `ordinal` must be unique | — | — | ⬜ |
| TC-N05 | Create day type — ordinal less than 1 | Submit `ordinal=0`; validation error: min:1 | — | — | ⬜ |
| TC-N06 | Create day type — code too long | Submit code longer than 20 characters; validation error: max:20 | — | — | ⬜ |
| TC-N07 | Create day type — name too long | Submit name longer than 100 characters; validation error: max:100 | — | — | ⬜ |
| TC-N08 | Create day type — description too long | Submit description longer than 255 characters; validation error: max:255 | — | — | ⬜ |
| TC-N09 | Guest access to index route | Visit any day-type route while not logged in; redirect to `/login` | — | — | ⬜ |
| TC-N10 | Missing viewAny permission | User without `viewAny` tries to access index; 403 Forbidden | — | — | ⬜ |
| TC-N11 | Missing create permission | User without `create` tries to access create/store; 403 Forbidden | — | — | ⬜ |
| TC-N12 | Non-existent day type ID — show/edit/update/destroy | Access route with invalid ID (e.g. 9999); 404 Not Found | — | — | ⬜ |
| TC-N13 | Delete day type referenced by Working Days | Try to delete a day type used in Working Day records; FK RESTRICT throws integrity violation; day type not deleted | — | — | ⬜ |

### 6.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|-----------------|---------|---------|--------|
| TC-D01 | A | Delete day type referenced in Working Day slot 1 | Delete blocked by FK RESTRICT on `fk_workday_daytype1`; integrity constraint violation | — | — | ⬜ |
| TC-D02 | B | Code auto-uppercase on create | Enter `study` in code field; saved as `STUDY` in database | — | — | ⬜ |
| TC-D03 | B | Code auto-uppercase on update | Edit a day type, change code to `test_code`; saved as `TEST_CODE` in database | — | — | ⬜ |
| TC-D04 | C | Activity logging on create/update/delete/restore/toggle | Each state change creates an activity log entry with model name, action type, and descriptive message | — | — | ⬜ |
| TC-D05 | D | Model `$fillable` matches DDL columns | `$fillable` array contains: code, name, description, is_working_day, reduced_periods, ordinal, is_active, created_by | — | — | ⬜ |
| TC-D06 | D | Model `$casts` for boolean/integer/datetime columns | `is_working_day` → boolean, `reduced_periods` → boolean, `is_active` → boolean, `ordinal` → integer, `created_at` → datetime, `updated_at` → datetime, `deleted_at` → datetime | — | — | ⬜ |
| TC-D07 | E | Unique `code` constraint at DB level | Direct DB insert with duplicate code throws `SQLSTATE[23000]` for `uq_daytype_code` | — | — | ⬜ |
| TC-D08 | E | Unique `name` constraint at DB level | Direct DB insert with duplicate name throws `SQLSTATE[23000]` for `uq_daytype_name` | — | — | ⬜ |
| TC-D09 | E | Unique `ordinal` constraint at DB level | Direct DB insert with duplicate ordinal throws `SQLSTATE[23000]` for `uq_daytype_ordinal` | — | — | ⬜ |
| TC-D10 | F | Model `$attributes` defaults | New DayType instance has: `is_working_day=true`, `reduced_periods=false`, `is_active=true`, `ordinal=1` | — | — | ⬜ |
| TC-D11 | F | Model `$fillable` includes `created_by` | `created_by` column is fillable (present in `$fillable` array) | — | — | ⬜ |

### 6.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|-----------------|---------|---------|--------|
| TC-CR01 | CR | P1 | Model — `$fillable` matches DDL columns for mass-assignment protection | All 7+1 DDL columns present (code, name, description, is_working_day, reduced_periods, ordinal, is_active, created_by); no extra column | — | — | ◌ |
| TC-CR02 | CR | P1 | Model — `$casts` for booleans/integers/dates | `is_working_day` → boolean; `reduced_periods` → boolean; `is_active` → boolean; `ordinal` → integer; `created_at`, `updated_at`, `deleted_at` → datetime | — | — | ◌ |
| TC-CR03 | CR | P1 | Model — SoftDeletes trait correctly implemented | `SoftDeletes` imported and used; `deleted_at` column in `$casts` | — | — | ◌ |
| TC-CR04 | CR | P1 | Model — `$attributes` default values | Defaults set: `is_working_day=true`, `reduced_periods=false`, `is_active=true`, `ordinal=1` | — | — | ◌ |
| TC-CR05 | CR | P1 | Model — relationships defined | `timetableTypes()` (hasMany) defined | — | — | ◌ |
| TC-CR06 | CR | P1 | Controller — try-catch exception handling on all write methods | `store()`, `update()`, `destroy()`, `forceDelete()`, `restore()`, `toggleStatus()` handle exceptions gracefully | — | — | ◌ |
| TC-CR07 | CR | P1 | Controller — DB transactions on multi-step writes | `destroy()` wraps deactivate+delete; `restore()` wraps restore+activate | — | — | ◌ |
| TC-CR08 | CR | P1 | Controller — `Gate::authorize()` on every method | Each public method calls `Gate::authorize()` before any logic | — | — | ◌ |
| TC-CR09 | CR | P1 | Controller — activity logged on all state changes | `store()` → 'Created'; `update()` → 'Updated'; `destroy()` → 'Trashed'; `forceDelete()` → 'Deleted'; `restore()` → 'Restored'; `toggleStatus()` → 'Toggled' | — | — | ◌ |
| TC-CR10 | CR | P1 | Controller — `is_active=false` before soft delete; restore sets `is_active=true` | `destroy()` sets `is_active=false` then `save()` then `delete()`; `restore()` calls `restore()` then sets `is_active=true` then `save()` | — | — | ◌ |
| TC-CR11 | CR | P1 | Controller — `toggleStatus()` flips `is_active` | Method validates `is_active` boolean, updates model, returns JSON on success/failure | — | — | ◌ |
| TC-CR12 | CR | P1 | Controller — trash/restore/forceDelete flow | `trashedDayType()` uses `onlyTrashed()` + `paginate(10)`; `restore()` uses `onlyTrashed()->findOrFail()`; `forceDelete()` uses `withTrashed()->findOrFail()` | — | — | ◌ |
| TC-CR13 | CR | P1 | Controller — JSON/flash response after write operations | All write methods return redirect with flash (or JSON for toggleStatus) | — | — | ◌ |
| TC-CR14 | CR | P1 | Validation — rules cover all fields; unique rules ignore current ID on update | `store()`: 3 unique rules with `whereNull('deleted_at')`; `update()`: each unique rule has `->ignore($dayType->id)->whereNull('deleted_at')` | — | — | ◌ |
| TC-CR15 | CR | P1 | Routes — resource + custom routes registered; model binding 404s | `Route::resource('day-type', ...)` generates 7 routes; 4 custom routes (trashed, restore, forceDelete, toggleStatus) | — | — | ◌ |
| TC-CR16 | CR | P1 | View — Blade `@can` directives on action buttons | Action buttons visibility gated by user permissions | — | — | ◌ |
| TC-CR17 | CR | P1 | Breadcrumb — route registered in `config/breadcrumb.php` | Breadcrumb for day-type routes renders correct hierarchy under Timetable Masters | — | — | ◌ |

---

## 7. Detailed Test Steps

#### TC-CR01: Model — `$fillable` Matches DDL Columns

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `DayType.php` `$fillable` array | Array contains: `code`, `name`, `description`, `is_working_day`, `reduced_periods`, `ordinal`, `is_active`, `created_by` |
| 2 | Cross-reference with DDL columns of `tt_day_types` | All 8 fillable columns exist in DDL; no fillable column absent from DDL |

#### TC-CR02: Model — `$casts` for Booleans/Integers/Dates

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `DayType.php` `$casts` array | Contains: `is_working_day`→boolean, `reduced_periods`→boolean, `is_active`→boolean, `ordinal`→integer, `created_at`→datetime, `updated_at`→datetime, `deleted_at`→datetime |

#### TC-CR03: Model — SoftDeletes Trait

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `DayType.php` imports | `use SoftDeletes;` present from `Illuminate\Database\Eloquent\SoftDeletes` |

#### TC-CR04: Model — `$attributes` Default Values

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `DayType.php` `$attributes` array | Contains: `is_working_day`→`true`, `reduced_periods`→`false`, `is_active`→`true`, `ordinal`→`1` |

#### TC-CR05: Model — Relationships Defined

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `DayType.php` | `timetableTypes()` returns `$this->hasMany(TimetableType::class, 'day_type_id')` |

#### TC-CR06: Controller — Try-Catch Exception Handling

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `DayTypeController.php` `store()` method | Method body wrapped in `try-catch`; validation or database exceptions handled gracefully; error flash returned on failure |
| 2 | Inspect `update()`, `destroy()`, `forceDelete()`, `restore()`, `toggleStatus()` methods | Each method has try-catch; exceptions do not produce unhandled 500 errors |

#### TC-CR07: Controller — DB Transactions on Multi-Step Writes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `destroy()` method | Uses `DB::transaction()` or `\DB::beginTransaction()` / `\DB::commit()` to wrap `is_active=false` save and `delete()` call atomically |
| 2 | Inspect `restore()` method | Uses DB transaction to wrap `restore()` call and `is_active=true` save atomically |

#### TC-CR08: Controller — `Gate::authorize()` on Every Method

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect each public method in `DayTypeController.php` | Every method (`index`, `create`, `store`, `show`, `edit`, `update`, `destroy`, `trashedDayType`, `restore`, `forceDelete`, `toggleStatus`) calls `Gate::authorize()` with the relevant `timetable-foundation.day-type.*` permission before executing logic |

#### TC-CR09: Controller — Activity Logged on All State Changes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `store()` method | Calls `activityLog()` with action `'Created'` and descriptive message |
| 2 | Inspect `update()`, `destroy()`, `forceDelete()`, `restore()`, `toggleStatus()` methods | `update()` logs `'Updated'`; `destroy()` logs `'Trashed'`; `forceDelete()` logs `'Deleted'`; `restore()` logs `'Restored'`; `toggleStatus()` logs `'Toggled'`; each with relevant message |

#### TC-CR10: Controller — `is_active=false` Before Soft Delete; Restore Sets `is_active=true`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `destroy()` method | Sets `$dayType->is_active = false` via `save()`, then calls `$dayType->delete()` to soft-delete |
| 2 | Inspect `restore()` method | Calls `$dayType->restore()` (Eloquent), then sets `$dayType->is_active = true` via `save()` |

#### TC-CR11: Controller — `toggleStatus()` Flips `is_active`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `toggleStatus()` method | Validates incoming `is_active` boolean parameter; updates model's `is_active` property |
| 2 | Verify return value | Returns JSON `{"success": true, "is_active": <new_value>, "message": "..."}` on success; JSON with `success: false` and HTTP 422 on failure |

#### TC-CR12: Controller — Trash/Restore/ForceDelete Flow

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `trashedDayType()` method | Uses `DayType::onlyTrashed()->paginate(10)` for trash listing |
| 2 | Inspect `restore()` method | Uses `DayType::onlyTrashed()->findOrFail($id)` to locate trashed record |
| 3 | Inspect `forceDelete()` method | Uses `DayType::withTrashed()->findOrFail($id)` to locate record before permanent deletion |

#### TC-CR13: Controller — JSON/Flash Response After Write Operations

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `store()`, `update()`, `destroy()`, `restore()`, `forceDelete()` methods | Each returns `redirect()->route(...)` with `->with('success', '...')` flash on success; `->with('error', '...')` on failure |
| 2 | Inspect `toggleStatus()` method | Returns `response()->json([...])` with JSON payload (not a redirect) |

#### TC-CR14: Validation — Rules Cover All Fields; Unique Ignores Current ID on Update

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `store()` validation rules | `code` has `unique:tt_day_types,code` with `whereNull('deleted_at')`; `name` and `ordinal` also have unique rules with `whereNull('deleted_at')` |
| 2 | Inspect `update()` validation rules | Each unique rule appends `->ignore($dayType->id)->whereNull('deleted_at')` to exclude the current record from uniqueness check |

#### TC-CR15: Routes — Resource + Custom Routes Registered

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect route definitions for day-type | `Route::resource('day-type', DayTypeController::class)` generates 7 standard resource routes |
| 2 | Locate custom routes | 4 custom routes: `trash/view` (GET), `{id}/restore` (GET), `{id}/force-delete` (DELETE), `{dayType}/toggle-status` (POST) |
| 3 | Verify implicit model binding | Toggle route uses `{dayType}` for implicit binding; non-existent IDs return 404 |

#### TC-CR16: View — Blade `@can` Directives on Action Buttons

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect day-type index/show Blade views | Action buttons (View, Edit, Trash, Restore, Force Delete, Toggle) wrapped in `@can('timetable-foundation.day-type.*')` directives |
| 2 | Verify permission gating | Buttons not rendered in HTML when user lacks corresponding permission |

#### TC-CR17: Breadcrumb — Route Registered in `config/breadcrumb.php`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `config/breadcrumb.php` | Day-type routes included with correct hierarchy: Timetable Masters → Day Types |
| 2 | Verify child routes | Create, edit, show, trash routes have appropriate parent breadcrumb links

---

### 7.1 Positive TC Steps

#### TC-P01: Load Day Types Tab

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Log in as admin with full permissions | Dashboard loads |
| 2 | Navigate to `GET /timetable-foundation/timetable-masters?tab=day-types` | HTTP 200; page title "Timetable Masters" visible |
| 3 | Locate the Day Types tab pane | Table rendered with day type items; each row shows ordinal, code, name, description (or "—" if null), Working Day (Yes/No badge), Reduced Periods (Yes/No badge), status toggle switch, action buttons (View, Edit, Trash) |
| 4 | Verify rows ordered by ordinal ascending | Day types listed in ordinal order (1, 2, 3...) |

#### TC-P02: Search Day Types by Code or Name

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Type `HOLIDAY` in the search bar | — |
| 2 | Click search button | Page reloads with `?tab=day-types&dt_search=HOLIDAY`; only day types with "HOLIDAY" in code or name shown; non-matching hidden |
| 3 | Clear search and submit empty search | All day types shown again |

#### TC-P03: Filter by Active Status

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select "Active" from status dropdown | — |
| 2 | Click search button | Page reloads with `?tab=day-types&dt_status=1`; only day types with `is_active=1` displayed |

#### TC-P04: Filter by Inactive Status

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select "Inactive" from status dropdown | — |
| 2 | Click search button | Page reloads with `?tab=day-types&dt_status=0`; only day types with `is_active=0` displayed |

#### TC-P05: Reset Filters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Apply search text and status filter | Filtered results shown |
| 2 | Click reset button | Page reloads with `?tab=day-types`; all day types shown; search and filter fields cleared |

#### TC-P06: Create Day Type — All Fields Filled

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click "Add" button to navigate to create form | `GET /timetable-foundation/day-type/create` — form rendered |
| 2 | Fill code: `cultural_fest` | — |
| 3 | Fill name: `Cultural Fest` | — |
| 4 | Fill description: `Annual cultural festival day` | — |
| 5 | Fill ordinal: `7` | — |
| 6 | Leave "Is Working Day" unchecked | — |
| 7 | Check "Reduced Periods" | — |
| 8 | Ensure "Active" is ON | — |
| 9 | Click "Create Day Type" submit button | POST request; redirect to `timetableMasters?tab=day-types`; success flash message |
| 10 | Find `CULTURAL_FEST` in the table | Code shown as `CULTURAL_FEST` (auto-uppercased); name "Cultural Fest"; Working Day badge shows "No"; Reduced Periods badge shows "Yes" |

#### TC-P07: Create Day Type — Required Fields Only

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to create form | — |
| 2 | Fill code: `TEST` | — |
| 3 | Fill name: `Test Day Type` | — |
| 4 | Fill ordinal: `10` | — |
| 5 | Leave description and checkboxes at defaults | — |
| 6 | Submit form | Day type created; `is_working_day=true`, `reduced_periods=false`, `is_active=true` |

#### TC-P08: View Day Type Details

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to show page for a day type: `GET /timetable-foundation/day-type/{id}` | HTTP 200; detail table with all fields: Code, Name, Description, Is Working Day (Yes/No badge), Reduced Periods (Yes/No badge), Ordinal, Is Active (Yes/No badge), Created At, Updated At |

#### TC-P09: Edit Day Type — Update Name and Flags

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to edit page for a day type | Form pre-filled with current data |
| 2 | Change name to `Updated Type` | — |
| 3 | Uncheck "Is Working Day" | — |
| 4 | Check "Reduced Periods" | — |
| 5 | Submit form | PUT request; redirect to tab; success flash; values updated |

#### TC-P10: Toggle Active Status via AJAX

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Identify an inactive day type | — |
| 2 | Click the status toggle switch | AJAX POST to toggle-status endpoint with `is_active=true` |
| 3 | Verify response | JSON `{"success": true, "is_active": true, "message": "..."}` |
| 4 | Verify UI updates | Status badge changes to "Active" (green) |

#### TC-P11: Toggle Status — Failure Returns 422

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Simulate a DB save failure on toggle (if possible via DB constraint or mocking) | JSON `{"success":false, "is_active":..., "message":flash('status_switch_failed.day_type')}` with HTTP 422 |

#### TC-P12: Soft Delete Day Type

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click delete (trash icon) on a day type | DELETE request to destroy route |
| 2 | Verify redirect | Redirect to `timetableMasters?tab=day-types` |
| 3 | Verify flash | Success flash message |
| 4 | Verify day type absent from main list | Day type no longer in table |
| 5 | Query DB directly | `deleted_at` populated; `is_active=0` |

#### TC-P13: Trash View Loads Soft-Deleted Day Types

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to trash view: `GET /timetable-foundation/day-type/trash/view` | HTTP 200; table with Code, Name, Description, Status, Action columns |
| 2 | Verify deleted day type appears | Day type listed with code, name, status "Inactive" badge, restore and force-delete action icons |

#### TC-P14: Restore Day Type from Trash

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | On trash view, click restore for a deleted day type | GET request to restore route |
| 2 | Verify redirect | Redirect to trash view |
| 3 | Verify flash | Success flash message |
| 4 | Navigate to main day types tab | Day type reappears in table; status is active |
| 5 | Query DB directly | `deleted_at` null; `is_active=1` |

#### TC-P15: Force Delete Day Type from Trash

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft delete a day type | — |
| 2 | Navigate to trash view | Day type visible in trash |
| 3 | Click force delete | DELETE request to force-delete route |
| 4 | Verify redirect | Redirect to trash view |
| 5 | Verify flash | Success flash message |
| 6 | Verify day type absent from trash and main list | Day type permanently removed |
| 7 | Query DB directly | Record does not exist |

#### TC-P16: Trash View Pagination

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure 12+ soft-deleted day types exist | — |
| 2 | Navigate to trash view | 10 records shown on page 1; pagination controls visible |
| 3 | Click page 2 link | Remaining records shown on page 2 |

---

### 7.2 Negative TC Steps

#### TC-N01: Missing Required Fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to create form | — |
| 2 | Leave code, name, ordinal blank | — |
| 3 | Submit form | Validation errors: "The code field is required.", "The name field is required.", "The ordinal field is required."; form not submitted |

#### TC-N02: Duplicate Code

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create day type with `code=STUDY` (if exists) or any existing code | Validation error: "The code has already been taken." |

#### TC-N03: Duplicate Name

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create day type with an existing name | Validation error: "The name has already been taken." |

#### TC-N04: Duplicate Ordinal

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create day type with an existing ordinal | Validation error: "The ordinal has already been taken." |

#### TC-N05: Ordinal Less Than 1

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create day type with `ordinal=0` | Validation error: "The ordinal must be at least 1." |

#### TC-N06: Code Too Long

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create day type with code of 21+ characters | Validation error: max `string` validation — "The code must not be greater than 20 characters." |

#### TC-N07: Name Too Long

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create day type with name of 101+ characters | Validation error: max `string` validation |

#### TC-N08: Description Too Long

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create day type with description of 256+ characters | Validation error: "The description must not be greater than 255 characters." |

#### TC-N09: Guest Access Redirect

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Log out | — |
| 2 | Navigate to `GET /timetable-foundation/day-type/create` | Redirected to `/login` |

#### TC-N10: Missing viewAny Permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Log in as user without `viewAny` permission | — |
| 2 | Navigate to day types tab | 403 Forbidden |

#### TC-N11: Missing create Permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Log in as user without `create` permission | — |
| 2 | Navigate to create form or POST store | 403 Forbidden |

#### TC-N12: Non-Existent Day Type ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to `GET /timetable-foundation/day-type/9999` | HTTP 404 |
| 2 | Navigate to edit for ID 9999 | HTTP 404 |

#### TC-N13: FK RESTRICT — Working Day References Day Type

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Identify a day type that is referenced by a Working Day record (e.g. STUDY) | — |
| 2 | Attempt to delete this day type via the UI | Delete fails; integrity constraint violation; FK RESTRICT prevents deletion |

---

### 7.3 Dependency TC Steps

#### TC-D01: FK RESTRICT — Working Day Slot 1

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Identify a day type used in `tt_working_days.day_type1_id` | — |
| 2 | Attempt to delete this day type via the UI | Delete fails; integrity constraint violation logged; FK `fk_workday_daytype1` prevents deletion |

#### TC-D02: Code Auto-Uppercase on Create

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create day type with code `study` (lowercase) | Code saved as `STUDY` in database (uppercased via `strtoupper()`) |

#### TC-D03: Code Auto-Uppercase on Update

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Edit a day type and change code to `test_code` | Code saved as `TEST_CODE` in database (uppercased) |

#### TC-D04: Activity Logging on State Changes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a new day type | Activity log entry created: action 'Created', message 'Day type was created successfully.' |
| 2 | Edit and update the day type | Activity log entry created: action 'Updated', message 'Day type was updated successfully.' |
| 3 | Toggle status of the day type | Activity log entry created: action 'Toggled', message 'Day type status was updated.' |
| 4 | Soft delete the day type | Activity log entry created: action 'Trashed', message 'Day type was deactivated and moved to trash.' |
| 5 | Restore the day type | Activity log entry created: action 'Restored', message 'Day type was restored successfully.' |
| 6 | Force delete the day type | Activity log entry created: action 'Deleted', message 'Day type was permanently deleted.' |

#### TC-D05: Model — `$fillable` Matches DDL Columns

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `DayType.php` `$fillable` array | Contains exactly: `code`, `name`, `description`, `is_working_day`, `reduced_periods`, `ordinal`, `is_active`, `created_by` — matching all DDL columns (excluding id, timestamps, deleted_at) |
| 2 | Verify no extra column | Every fillable column is a real column in `tt_day_types` |

#### TC-D06: Model — `$casts` for Boolean/Integer/Datetime

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `DayType.php` `$casts` array | `is_working_day` → `boolean`, `reduced_periods` → `boolean`, `is_active` → `boolean`, `ordinal` → `integer`, `created_at` → `datetime`, `updated_at` → `datetime`, `deleted_at` → `datetime` |

#### TC-D07: Unique Code Constraint at DB Level

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Insert a duplicate code directly into `tt_day_types` via SQL: `INSERT INTO tt_day_types (code, name, ordinal) VALUES ('STUDY', 'Duplicate', 99)` | SQL error: `SQLSTATE[23000]: Integrity constraint violation` — duplicate entry for key `uq_daytype_code` |

#### TC-D08: Unique Name Constraint at DB Level

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Insert a duplicate name directly into `tt_day_types` via SQL: `INSERT INTO tt_day_types (code, name, ordinal) VALUES ('DUP', 'Study Day', 98)` | SQL error: `SQLSTATE[23000]: Integrity constraint violation` — duplicate entry for key `uq_daytype_name` |

#### TC-D09: Unique Ordinal Constraint at DB Level

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Insert a duplicate ordinal directly into `tt_day_types` via SQL: `INSERT INTO tt_day_types (code, name, ordinal) VALUES ('DUP2', 'Duplicate', 1)` | SQL error: `SQLSTATE[23000]: Integrity constraint violation` — duplicate entry for key `uq_daytype_ordinal` |

#### TC-D10: Model `$attributes` Defaults

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `DayType.php` `$attributes` array | `is_working_day` → `true`, `reduced_periods` → `false`, `is_active` → `true`, `ordinal` → `1` |

#### TC-D11: Model `$fillable` Includes `created_by`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `DayType.php` `$fillable` array | `created_by` is present in the `$fillable` array |

---

