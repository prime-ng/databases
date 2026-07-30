# tt_SchoolDaysTab_TcList

## Module: TimetableFoundation → Timetable Masters → School Days Tab

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | TimetableFoundation |
| Tab Group | Timetable Masters |
| Feature | School Days Tab |
| URL(s) | `GET /timetable-foundation/timetable-masters?tab=school-days` — main tab view |
| | `GET /timetable-foundation/school-day` — redirects to tab |
| | `GET /timetable-foundation/school-day/create` — create form |
| | `POST /timetable-foundation/school-day` — store |
| | `GET /timetable-foundation/school-day/{id}` — show |
| | `GET /timetable-foundation/school-day/{id}/edit` — edit form |
| | `PUT /timetable-foundation/school-day/{id}` — update |
| | `DELETE /timetable-foundation/school-day/{id}` — destroy (soft) |
| | `GET /timetable-foundation/school-day/trash/view` — trash list |
| | `GET /timetable-foundation/school-day/{id}/restore` — restore |
| | `DELETE /timetable-foundation/school-day/{id}/force-delete` — force delete |
| | `POST /timetable-foundation/school-day/{schoolDay}/toggle-status` — AJAX toggle |
| Controller | Tab: `TimetableFoundationController@timetableMasters()`; CRUD: `Modules\TimetableFoundation\Http\Controllers\SchoolDayController` |
| Model(s) | `Modules\TimetableFoundation\Models\SchoolDay` (table: `tt_school_days`) |
| Validation (Create) | Inline in `store()` (no Form Request) |
| Validation (Update) | Inline in `update()` — unique rules ignore current ID |
| Policy | No dedicated policy — implicit gate resolution |
| Permissions | `timetable-foundation.school-day.viewAny` |
| | `timetable-foundation.school-day.view` |
| | `timetable-foundation.school-day.create` |
| | `timetable-foundation.school-day.update` |
| | `timetable-foundation.school-day.delete` |
| | `timetable-foundation.school-day.restore` |
| | `timetable-foundation.school-day.forceDelete` |
| Pagination | None on main tab (max 7 rows); 10 records per page on trash view |
| Soft Deletes | Yes — `SoftDeletes` trait on `SchoolDay` model |
| Read-Only | Partially — pre-seeded reference data with toggle/CRUD capability |

---

## 2. Pre-conditions

- Admin user has all `timetable-foundation.school-day.*` permissions granted.
- Dusk environment variables set: `DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD`.
- Seeded school day records exist: 7 rows (MON–SUN) with `is_school_day = 1` for MON–SAT and `is_school_day = 0` for SUN.
- All 7 records have `is_active = 1` and `deleted_at = NULL`.
- Tenant academic session is initialized (for related working day dependency tests).

---

## 3. Default Data Load

The `TimetableFoundationController@timetableMasters()` method loads the School Days tab data with optional search and status filters:

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| School Days table | `timetableMasters()` | `SchoolDay::query()->orderBy('ordinal')` | `sd_search` (name/code LIKE), `sd_status` (is_active = 1/0) | None (all 7 rows) |

All 7 pre-seeded rows are returned by default with `sd_status` defaulting to `1` (active only). The table columns rendered are: **# (ordinal)**, **Code**, **Name**, **Short Name**, **Day of Week**, **School Day** (Yes/No badge), **Status** (toggle), **Action** (View, Edit, Trash).

---

## 4. Test Data Strategy

- **Seed data**: The 7 system-seeded days (MON–SUN) are used for most display and toggle tests. No additional records need to be created for default-load verification.
- **Unique test records**: For create/edit tests, use distinct codes (e.g., `TEST`) and `day_of_week` values outside 1–7 range to trigger validation.
- **Pre-test cleanup**: Ensure no test records collide with seed data. Use `forceDelete` on created test records after each test.
- **Pagination overflow**: Create 12+ soft-deleted records to test 10-record per-page limit on trash view.
- **Cross-module data**: No FK parent data required for this feature (it is a root reference table).

---

## 5. Business Conditions

### 5.1 Database Schema — `tt_school_days`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | `id` | TINYINT UNSIGNED | PK, NOT NULL, AUTO_INCREMENT |
| BC-DB-02 | `code` | VARCHAR(10) | NOT NULL, UNIQUE (`uq_schoolday_code`) |
| BC-DB-03 | `name` | VARCHAR(20) | NOT NULL |
| BC-DB-04 | `short_name` | VARCHAR(5) | NOT NULL |
| BC-DB-05 | `day_of_week` | TINYINT UNSIGNED | NOT NULL, UNIQUE (`uq_schoolday_dow`) |
| BC-DB-06 | `ordinal` | TINYINT UNSIGNED | NOT NULL |
| BC-DB-07 | `is_school_day` | TINYINT(1) | NOT NULL, DEFAULT 1 |
| BC-DB-08 | `is_active` | TINYINT(1) | NOT NULL, DEFAULT 1 |
| BC-DB-09 | `created_at` | TIMESTAMP | NULL DEFAULT NULL |
| BC-DB-10 | `updated_at` | TIMESTAMP | NULL DEFAULT NULL |
| BC-DB-11 | `deleted_at` | TIMESTAMP | NULL DEFAULT NULL |
| BC-DB-12 | UNIQUE KEY `uq_schoolday_code` | — | `code` |
| BC-DB-13 | UNIQUE KEY `uq_schoolday_dow` | — | `day_of_week` |

### 5.2 Validation Rules — Inline in `store()` (Create)

| BC ID | Field | Rule(s) | Error Message |
|-------|-------|---------|---------------|
| BC-VAL-01 | `code` | `required`, `string`, `max:10`, `unique:tt_school_days,code` | Laravel default |
| BC-VAL-02 | `name` | `required`, `string`, `max:20` | Laravel default |
| BC-VAL-03 | `short_name` | `required`, `string`, `max:5` | Laravel default |
| BC-VAL-04 | `day_of_week` | `required`, `integer`, `between:1,7`, `unique:tt_school_days,day_of_week` | Laravel default |
| BC-VAL-05 | `ordinal` | `required`, `integer`, `min:1` | Laravel default |
| BC-VAL-06 | `is_school_day` | `nullable` (normalized via `$request->boolean()`) | — |
| BC-VAL-07 | `is_active` | `nullable` (normalized via `$request->boolean()`) | — |

### 5.3 Validation Rules — Inline in `update()` (Update)

| BC ID | Field | Rule(s) | Error Message |
|-------|-------|---------|---------------|
| BC-VAL-08 | `code` | `required`, `string`, `max:10`, `unique:tt_school_days,code,{id}` | Laravel default |
| BC-VAL-09 | `name` | `required`, `string`, `max:20` | Laravel default |
| BC-VAL-10 | `short_name` | `required`, `string`, `max:5` | Laravel default |
| BC-VAL-11 | `day_of_week` | `required`, `integer`, `between:1,7`, `unique:tt_school_days,day_of_week,{id}` | Laravel default |
| BC-VAL-12 | `ordinal` | `required`, `integer`, `min:1` | Laravel default |
| BC-VAL-13 | `is_school_day` | `nullable` (normalized via `$request->boolean()`) | — |
| BC-VAL-14 | `is_active` | `nullable` (normalized via `$request->boolean()`) | — |

### 5.4 Authorization

| BC ID | Permission | Behavior |
|-------|-----------|----------|
| BC-AUTH-01 | `timetable-foundation.school-day.viewAny` | Without it → 403 on index/tab load |
| BC-AUTH-02 | `timetable-foundation.school-day.view` | Without it → 403 on show |
| BC-AUTH-03 | `timetable-foundation.school-day.create` | Without it → 403 on create/store |
| BC-AUTH-04 | `timetable-foundation.school-day.update` | Without it → 403 on edit/update/toggleStatus |
| BC-AUTH-05 | `timetable-foundation.school-day.delete` | Without it → 403 on destroy/forceDelete |
| BC-AUTH-06 | `timetable-foundation.school-day.restore` | Without it → 403 on restore |
| BC-AUTH-07 | `timetable-foundation.school-day.forceDelete` | Without it → 403 on forceDelete |
| BC-AUTH-08 | Guest access to any school-day route | Redirect to `/login` |

### 5.5 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Screen loads with `tab=school-days` | Table of 7 school days rendered, ordered by `ordinal` ascending (1=Mon, 2=Tue, ..., 7=Sun) |
| BC-BIZ-02 | Search by `sd_search` | Days with matching `name` or `code` (LIKE, case-insensitive) shown; non-matching days hidden |
| BC-BIZ-03 | Filter by `sd_status=1` | Only active days (`is_active = 1`) displayed |
| BC-BIZ-04 | Filter by `sd_status=0` | Only inactive days (`is_active = 0`) displayed |
| BC-BIZ-05 | No matching results after filter | Empty table with "No records found" message |
| BC-BIZ-06 | Each row displays all key columns | Ordinal (#), Code, Name, Short Name, Day of Week, School Day (Yes/No badge), Status toggle, Action buttons |
| BC-BIZ-07 | Default filter `sd_status=1` | Only active days shown on initial load |
| BC-BIZ-08 | Toggle `is_school_day` via AJAX | JSON response `{ success: true, is_school_day: <new_value>, message }`; badge colour updates |
| BC-BIZ-09 | Toggle `is_active` via AJAX | JSON response `{ success: true, is_active: <new_value>, message }`; status badge updates |
| BC-BIZ-10 | Soft delete a school day | `is_active` set to false before `delete()`; record removed from main table; appears in trash |
| BC-BIZ-11 | Restore from trash | `is_active` set to true after `restore()`; record reappears in main table |
| BC-BIZ-12 | Force delete from trash | Record permanently removed; absent from both main table and trash |

### 5.6 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|------------------|----------------|
| BC-REF-01 | — | — | `tt_school_days` has no foreign keys — it is a root reference table |

---

## 6. Test Case List

### 6.1 Display & Filter Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|-----------------|---------|---------|--------|
| TC-P01 | Load School Days tab on Timetable Masters page | `GET /timetable-foundation/timetable-masters?tab=school-days` returns 200; table renders with all 7 seeded days (MON–SUN) ordered by ordinal (1–7); each row shows ordinal, code, name, short name, day_of_week, School Day badge, Status toggle, action buttons | — | — | ⬜ |
| TC-P02 | Verify seed data for Sunday | Sunday row shows code=SUN, name=Sunday, short_name=Sun, day_of_week=7, ordinal=7, School Day=No (red badge), Status=Active | — | — | ⬜ |
| TC-P03 | Verify seed data for Monday | Monday row shows code=MON, name=Monday, short_name=Mon, day_of_week=1, ordinal=1, School Day=Yes (green badge), Status=Active | — | — | ⬜ |
| TC-P04 | Search by day name | Enter "Monday" in search box, submit; only Monday row displayed; other 6 rows hidden | — | — | ⬜ |
| TC-P05 | Search by code | Enter "SUN" in search box, submit; only Sunday row displayed | — | — | ⬜ |
| TC-P06 | Partial search match | Enter "day" in search box; rows with "day" in name (Monday, Tuesday, Wednesday, Thursday, Friday, Saturday) displayed; Sunday also matches because code contains "SUN" — verify | — | — | ⬜ |
| TC-P07 | Filter by active status | Select "Active" from status dropdown; all 7 seed rows displayed (all are active) | — | — | ⬜ |
| TC-P08 | Filter by inactive status | First toggle one day to inactive, then select "Inactive" from status dropdown; only the inactive day shown | — | — | ⬜ |
| TC-P09 | Reset filters | Apply search and status filter, then click reset; all active days shown without filters | — | — | ⬜ |
| TC-P10 | Empty state from search | Search for "ZZZ" (no match); empty table with "No records found" message | — | — | ⬜ |
| TC-P11 | View single school day detail | Click View button on Monday row; `GET /school-day/{id}` renders detail page with all fields displayed: Code, Name, Short Name, Day of Week, Ordinal, School Day, Status, Created, Updated | — | — | ⬜ |
| TC-P12 | Create school day — all fields valid | Create day with code=TEST, name=Test Day, short_name=Tst, day_of_week=8 (not allowed — must be 1-7). Test with valid day_of_week, e.g., code=EXTRA, name=Extra Day, short_name=Ext, day_of_week=8 rejected, so use day_of_week=15 rejected. Use valid unique day_of_week=8 (no existing seed uses 8) — but validation between:1,7 blocks anything outside 1-7. So test create with valid day_of_week=1 fails duplicate. For this test, just verify the create form renders. | — | — | ⬜ |
| TC-P13 | Edit school day — update name and ordinal | Click Edit on Saturday row; change name to "Saturday (Half Day)", change ordinal to 8; submit; update succeeds; redirect to tab; Saturday shows updated name and ordinal 8 | — | — | ⬜ |
| TC-P14 | Toggle `is_school_day` flag via AJAX | Click the School Day toggle switch on Saturday; AJAX POST to toggle-status; response `{ success: true, is_school_day: false, message }`; badge changes from "Yes" (green) to "No" (red) | — | — | ⬜ |
| TC-P15 | Toggle `is_active` via AJAX | Click the Active toggle switch on Tuesday; AJAX POST to toggle-status; response `{ success: true, is_active: false, message }`; status badge changes to "Inactive" | — | — | ⬜ |
| TC-P16 | Soft delete a school day | Click Trash on Tuesday; redirect to tab; success flash; Tuesday removed from table; appears in trash view | — | — | ⬜ |
| TC-P17 | Trash view loads with soft-deleted records | Navigate to trash view (`GET /school-day/trash/view`); deleted Tuesday listed with name, code, restored/force-delete actions | — | — | ⬜ |
| TC-P18 | Restore from trash | Click Restore on Tuesday in trash view; restore succeeds; success flash; Tuesday reappears in main table with active status | — | — | ⬜ |
| TC-P19 | Force delete from trash | Soft delete a test day; navigate to trash; click Force Delete; record permanently removed; absent from both main table and trash | — | — | ⬜ |
| TC-P20 | Trash pagination with 12+ deleted records | Create and soft-delete 12 test days; trash view shows 10 records on page 1, 2+ records on page 2; page navigation visible | — | — | ⬜ |

### 6.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|-----------------|---------|---------|--------|
| TC-N01 | Create — missing required fields | Submit create form with empty code, name, short_name, day_of_week, ordinal; validation errors for each required field | — | — | ⬜ |
| TC-N02 | Create — duplicate code | Submit with code "MON" (already exists); validation error: "The code has already been taken." | — | — | ⬜ |
| TC-N03 | Create — duplicate day_of_week | Submit with day_of_week=1 (Monday already has 1); validation error: "The day of week has already been taken." | — | — | ⬜ |
| TC-N04 | Create — day_of_week out of range | Submit with day_of_week=0 or day_of_week=8; validation error: "The day of week must be between 1 and 7." | — | — | ⬜ |
| TC-N05 | Create — ordinal < 1 | Submit with ordinal=0; validation error: "The ordinal must be at least 1." | — | — | ⬜ |
| TC-N06 | Update — duplicate code (excluding own ID) | Change Tuesday's code to "MON" (already used by Monday); validation error: "The code has already been taken." | — | — | ⬜ |
| TC-N07 | Guest access redirect | Log out; navigate to any school-day route; redirect to `/login` | — | — | ⬜ |
| TC-N08 | Missing viewAny permission | User without `viewAny` tries to access tab; 403 Forbidden | — | — | ⬜ |
| TC-N09 | Missing create permission | User without `create` tries to access create/store; 403 Forbidden | — | — | ⬜ |
| TC-N10 | Missing update permission | User without `update` tries to edit; 403 Forbidden | — | — | ⬜ |
| TC-N11 | Missing delete permission | User without `delete` tries to destroy; 403 Forbidden | — | — | ⬜ |
| TC-N12 | Non-existent record — show/edit/update/destroy | Access route with invalid ID (e.g., 9999); 404 Not Found | — | — | ⬜ |
| TC-N13 | Toggle status on non-existent record | POST to toggle-status with invalid ID; 404 Not Found | — | — | ⬜ |
| TC-N14 | Force delete non-existent record | DELETE force-delete with invalid ID; 404 Not Found | — | — | ⬜ |

### 6.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|-----------------|---------|---------|--------|
| TC-D01 | A | Activity logging on create/update/delete/restore/toggle | Each state change creates an activity log entry with model name, action type (Created/Updated/Trashed/Restored/Deleted/Toggled), and descriptive message | — | — | ⬜ |
| TC-D02 | B | Model `$fillable` matches DDL columns | `$fillable` array contains: code, name, short_name, day_of_week, ordinal, is_school_day, is_active (no extra columns, no missing columns) | — | — | ⬜ |
| TC-D03 | B | Model `$casts` for boolean/integer/datetime columns | `is_school_day` → boolean, `is_active` → boolean, `day_of_week` → integer, `ordinal` → integer, `created_at` → datetime, `updated_at` → datetime, `deleted_at` → datetime | — | — | ⬜ |
| TC-D04 | C | Unique `code` constraint at DB level | Direct DB insert with duplicate code (e.g., 'MON') throws `SQLSTATE[23000]: Integrity constraint violation` for `uq_schoolday_code` | — | — | ⬜ |
| TC-D05 | C | Unique `day_of_week` constraint at DB level | Direct DB insert with duplicate day_of_week (e.g., 1) throws `SQLSTATE[23000]: Integrity constraint violation` for `uq_schoolday_dow` | — | — | ⬜ |
| TC-D06 | D | Working day initialization reads school days | After toggling Saturday's `is_school_day` to false, `ajaxInitializeWorkingDays` treats Saturdays as closed days (assigned Holiday type) | — | — | ⬜ |

### 6.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|-----------------|---------|---------|--------|
| TC-CR01 | CR | P1 | Model — `$fillable` matches DDL columns for mass-assignment protection | All 7 DDL columns (code, name, short_name, day_of_week, ordinal, is_school_day, is_active) present; no extra column | — | — | ◌ |
| TC-CR02 | CR | P1 | Model — `$casts` for booleans/integers/dates | Boolean casts for is_school_day, is_active; integer casts for day_of_week, ordinal; datetime for 3 timestamps | — | — | ◌ |
| TC-CR03 | CR | P1 | Model — SoftDeletes trait correctly implemented | `SoftDeletes` imported and used; `deleted_at` column in `$casts`; soft-deleted records hidden from queries | — | — | ◌ |
| TC-CR04 | CR | P1 | Controller — try-catch exception handling on all write methods | `store()`, `update()`, `destroy()`, `forceDelete()`, `restore()`, `toggleStatus()` have exception handling | — | — | ◌ |
| TC-CR05 | CR | P1 | Controller — `Gate::authorize()` on every method | Each public method calls `Gate::authorize()` with the appropriate permission before any logic | — | — | ◌ |
| TC-CR06 | CR | P1 | Controller — activity logged on all state changes | `store()` → 'Created'; `update()` → 'Updated'; `destroy()` → 'Trashed'; `forceDelete()` → 'Deleted'; `restore()` → 'Restored'; `toggleStatus()` → 'Toggled' | — | — | ◌ |
| TC-CR07 | CR | P1 | Controller — `is_active=false` before soft delete; restore sets `is_active=true` | `destroy()` sets `is_active=false` then `save()` before `delete()`; `restore()` calls `restore()` then sets `is_active=true` then `save()` | — | — | ◌ |
| TC-CR08 | CR | P1 | Controller — `toggleStatus()` flips boolean correctly | Method validates boolean, updates model, saves, returns JSON `{success: true, is_active/is_school_day: <new_value>, message: "..."}` | — | — | ◌ |
| TC-CR09 | CR | P1 | Controller — trash/restore/forceDelete flow | `trashedDay()` uses `onlyTrashed()` + `paginate(10)`; `restore()` uses `onlyTrashed()->findOrFail($id)`; `forceDelete()` uses `withTrashed()->findOrFail($id)` | — | — | ◌ |
| TC-CR10 | CR | P1 | Controller — redirect with flash after write operations | All write methods return redirect with `success` flash message (or JSON for toggleStatus); failure scenarios return `error` flash | — | — | ◌ |
| TC-CR11 | CR | P1 | Validation — rules cover all fields; unique rules ignore current ID on update | `store()` rules include `unique:tt_school_days,code` and `unique:tt_school_days,day_of_week`; `update()` rules append `,{id}` to ignore current record | — | — | ◌ |
| TC-CR12 | CR | P1 | Routes — resource + custom routes registered | `Route::resource('school-day', SchoolDayController::class)` with trash/restore/forceDelete/toggleStatus routes; implicit model binding returns 404 for missing IDs | — | — | ◌ |
| TC-CR13 | CR | P1 | View — Blade `@can` directives on action buttons | Action buttons (edit, delete, status switch) rendered based on user permissions; hidden when user lacks permission | — | — | ◌ |
| TC-CR14 | CR | P1 | Breadcrumb — route registered in config | `school-day.*` routes registered in `config/breadcrumb.php` and render correct hierarchy | — | — | ◌ |
| TC-CR15 | CR | P1 | Database — unique indexes match validation rules | DB `uq_schoolday_code` and `uq_schoolday_dow` match the `unique` validation rules in store/update | — | — | ◌ |

---

## 7. Detailed Test Steps

#### TC-CR01: Model — `$fillable` Matches DDL Columns

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `SchoolDay.php` `$fillable` array | Array contains: `code`, `name`, `short_name`, `day_of_week`, `ordinal`, `is_school_day`, `is_active` |
| 2 | Cross-reference with DDL columns of `tt_school_days` | All 7 fillable columns exist in DDL; no fillable column is absent from DDL |

#### TC-CR02: Model — `$casts` for Booleans/Integers/Dates

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `SchoolDay.php` `$casts` array | Contains: `is_school_day`→boolean, `is_active`→boolean, `day_of_week`→integer, `ordinal`→integer, `created_at`→datetime, `updated_at`→datetime, `deleted_at`→datetime |

#### TC-CR03: Model — SoftDeletes Trait

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `SchoolDay.php` imports | `use SoftDeletes;` present from `Illuminate\Database\Eloquent\SoftDeletes` |
| 2 | Verify `deleted_at` in `$casts` | `'deleted_at' => 'datetime'` present |

#### TC-CR04: Controller — Try-Catch Exception Handling

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `SchoolDayController.php` `store()` method | Method body wrapped in `try-catch`; validation and database exceptions handled gracefully; error flash returned on failure |
| 2 | Inspect `update()`, `destroy()`, `forceDelete()`, `restore()`, `toggleStatus()` methods | Each method has try-catch handling; exceptions produce redirect with error flash rather than unhandled 500 errors |

#### TC-CR05: Controller — `Gate::authorize()` on Every Method

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect each public method in `SchoolDayController.php` | Every method (`index`, `create`, `store`, `show`, `edit`, `update`, `destroy`, `trashedDay`, `restore`, `forceDelete`, `toggleStatus`) calls `Gate::authorize()` with appropriate `timetable-foundation.school-day.*` permission before executing business logic |

#### TC-CR06: Controller — Activity Logged on All State Changes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `store()` method | Calls `activityLog()` with action `'Created'` and descriptive message after successful save |
| 2 | Inspect `update()`, `destroy()`, `forceDelete()`, `restore()`, `toggleStatus()` methods | `update()` logs `'Updated'`; `destroy()` logs `'Trashed'`; `forceDelete()` logs `'Deleted'`; `restore()` logs `'Restored'`; `toggleStatus()` logs `'Toggled'` |

#### TC-CR07: Controller — `is_active=false` Before Soft Delete; Restore Sets `is_active=true`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `destroy()` method | Sets `$schoolDay->is_active = false` via `save()`, then calls `$schoolDay->delete()` to soft-delete |
| 2 | Inspect `restore()` method | Calls `$schoolDay->restore()` (Eloquent), then sets `$schoolDay->is_active = true` via `save()` |

#### TC-CR08: Controller — `toggleStatus()` Flips Boolean Correctly

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `toggleStatus()` method | Validates incoming boolean parameter (either `is_active` or `is_school_day`); updates the corresponding model attribute |
| 2 | Verify return value | Returns JSON `{"success": true, "is_active" / "is_school_day": <new_value>, "message": "..."}` on success |

#### TC-CR09: Controller — Trash/Restore/ForceDelete Flow

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `trashedDay()` method | Uses `SchoolDay::onlyTrashed()->paginate(10)` for trash listing |
| 2 | Inspect `restore()` method | Uses `SchoolDay::onlyTrashed()->findOrFail($id)` to locate trashed record |
| 3 | Inspect `forceDelete()` method | Uses `SchoolDay::withTrashed()->findOrFail($id)` to locate record before permanent deletion |

#### TC-CR10: Controller — Redirect with Flash After Write Operations

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `store()`, `update()`, `destroy()`, `restore()`, `forceDelete()` methods | Each returns `redirect()->route(...)` with `->with('success', '...')` flash on success; `->with('error', '...')` on failure |
| 2 | Inspect `toggleStatus()` method | Returns `response()->json([...])` (not a redirect) |

#### TC-CR11: Validation — Rules Cover All Fields; Unique Ignores Current ID on Update

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `store()` validation rules | `code` has `unique:tt_school_days,code`; `day_of_week` has `unique:tt_school_days,day_of_week` and `between:1,7` |
| 2 | Inspect `update()` validation rules | Unique rules append `,{id}` to ignore current record; `day_of_week` keeps `between:1,7` |

#### TC-CR12: Routes — Resource + Custom Routes Registered

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect route definitions for school-day | `Route::resource('school-day', SchoolDayController::class)` generates 7 resource routes |
| 2 | Locate custom routes | Custom routes for `trash/view`, `{id}/restore`, `{id}/force-delete`, `{schoolDay}/toggle-status` registered |
| 3 | Verify implicit model binding | Non-existent school-day IDs return 404 |

#### TC-CR13: View — Blade `@can` Directives on Action Buttons

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect school-day Blade views | Action buttons (View, Edit, Trash, Restore, Force Delete, Status Toggle) wrapped in `@can('timetable-foundation.school-day.*')` directives |
| 2 | Verify permission gating | Buttons not rendered in HTML when user lacks the corresponding permission |

#### TC-CR14: Breadcrumb — Route Registered in Config

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `config/breadcrumb.php` | `school-day.*` routes registered with correct hierarchy: Timetable Masters → School Days |
| 2 | Verify sub-routes | Create, edit, show, trash routes have appropriate parent breadcrumb links |

#### TC-CR15: Database — Unique Indexes Match Validation Rules

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect database schema for `tt_school_days` | `uq_schoolday_code` unique index on `code` column matches the `unique` validation rule |
| 2 | Inspect `uq_schoolday_dow` index | `uq_schoolday_dow` unique index on `day_of_week` column matches the `unique:tt_school_days,day_of_week` validation rule

---

### 7.1 Display & Filter TC Steps

#### TC-P01: Load School Days Tab

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Log in as admin with full permissions | Dashboard loads |
| 2 | Navigate to `GET /timetable-foundation/timetable-masters?tab=school-days` | HTTP 200; page title "Timetable Masters" visible; School Days tab pane active |
| 3 | Verify table structure | Table has 7 rows; columns: #, Code, Name, Short Name, Day of Week, School Day, Status, Action |
| 4 | Verify row order | Rows ordered 1–7: Monday (1), Tuesday (2), Wednesday (3), Thursday (4), Friday (5), Saturday (6), Sunday (7) |

#### TC-P02: Verify Sunday Seed Data

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Locate Sunday row (ordinal 7) | Code = "SUN", Name = "Sunday", Short Name = "Sun", Day of Week = 7 |
| 2 | Check School Day badge | Badge shows "No" in red/closed style |
| 3 | Check Status toggle | Toggle is ON (Active), green |

#### TC-P03: Verify Monday Seed Data

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Locate Monday row (ordinal 1) | Code = "MON", Name = "Monday", Short Name = "Mon", Day of Week = 1 |
| 2 | Check School Day badge | Badge shows "Yes" in green/open style |

#### TC-P04: Search by Day Name

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Type "Monday" in the search box | — |
| 2 | Click search button | Page reloads with `?tab=school-days&sd_search=Monday`; only Monday row displayed |
| 3 | Clear search and re-submit | All 7 rows displayed again |

#### TC-P05: Search by Code

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Type "SUN" in search box | — |
| 2 | Click search button | Page reloads with `?tab=school-days&sd_search=SUN`; only Sunday row displayed |

#### TC-P06: Partial Search Match

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Type "day" in search box | — |
| 2 | Click search button | Rows matching "day" in name or code displayed (Monday, Tuesday, Wednesday, Thursday, Friday, Saturday, Sunday if "sun" contains substring "day" — verify actual matching behavior) |

#### TC-P07: Filter by Active Status

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select "Active" from status dropdown | — |
| 2 | Click search button | Page reloads with `?tab=school-days&sd_status=1`; all active rows displayed |

#### TC-P08: Filter by Inactive Status

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Toggle Tuesday's status to inactive first | AJAX toggle sets `is_active=false` |
| 2 | Select "Inactive" from status dropdown | — |
| 3 | Click search button | Page reloads with `?tab=school-days&sd_status=0`; only Tuesday (inactive) displayed |
| 4 | Toggle Tuesday back to active | Clean up test data |

#### TC-P09: Reset Filters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Apply search text and status filter | Filtered results shown |
| 2 | Click reset button | Page reloads with `?tab=school-days`; all active days shown; search and filter fields cleared |

#### TC-P10: Empty State from Search

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Type "ZZZ" in search box | — |
| 2 | Click search button | Empty table with "No records found" message |

#### TC-P11: View Single School Day Detail

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click View button on Monday row | `GET /school-day/{id}` renders detail page |
| 2 | Verify all fields displayed | Code: MON, Name: Monday, Short Name: Mon, Day of Week: 1, Ordinal: 1, School Day: Yes, Status: Active, Created/Updated timestamps visible |
| 3 | Verify Edit and Back buttons present | Links to edit route and tab visible |

#### TC-P12: Create School Day

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click "Add New" button | `GET /school-day/create` — form rendered with fields: Code, Name, Short Name, Day of Week, Ordinal, Is School Day, Is Active |
| 2 | Fill code: `EXTRA` | — |
| 3 | Fill name: `Extra Day` | — |
| 4 | Fill short_name: `Ext` | — |
| 5 | Fill day_of_week: `8` | — |
| 6 | Fill ordinal: `8` | — |
| 7 | Check Is School Day | — |
| 8 | Check Is Active | — |
| 9 | Submit form | POST request; redirect to tab; success flash message; new day appears in table (ordinal 8, last row) |
| 10 | Clean up: delete the test record | — |

#### TC-P13: Edit School Day — Update Name and Ordinal

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click Edit on Saturday row | `GET /school-day/{id}/edit` — form pre-filled with current values |
| 2 | Change name to "Saturday (Half Day)" | — |
| 3 | Change ordinal to `8` | — |
| 4 | Submit form | PUT request; redirect to tab; success flash message |
| 5 | Verify updated row | Saturday (ordinal 8) shows new name "Saturday (Half Day)" |
| 6 | Reset: edit again and restore original name and ordinal 6 | — |

#### TC-P14: Toggle `is_school_day` via AJAX

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click the School Day toggle switch on Saturday row | AJAX POST to toggle-status endpoint with `is_school_day=false` |
| 2 | Verify response | JSON `{"success": true, "is_school_day": false, "message": "..."}` |
| 3 | Verify badge update | School Day badge changes to "No" (red) immediately |
| 4 | Toggle back to Yes | Clean up |

#### TC-P15: Toggle `is_active` via AJAX

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click the Active toggle switch on Tuesday row | AJAX POST to toggle-status endpoint with `is_active=false` |
| 2 | Verify response | JSON `{"success": true, "is_active": false, "message": "..."}` |
| 3 | Verify status badge | Status changes to "Inactive" |
| 4 | Toggle back to Active | Clean up |

#### TC-P16: Soft Delete a School Day

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click Trash (delete icon) on Tuesday row | DELETE request to destroy route |
| 2 | Verify redirect | Redirect to tab |
| 3 | Verify flash message | Success flash message displayed |
| 4 | Verify Tuesday absent from table | Tuesday row no longer visible in main list |
| 5 | Query DB directly | `deleted_at` populated; `is_active=0` |

#### TC-P17: Trash View Loads Soft-Deleted Records

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to trash view: `GET /school-day/trash/view` | HTTP 200; table with soft-deleted school days listed |
| 2 | Verify Tuesday appears | Tuesday listed with code TUE, show/edit details, restore and force-delete action icons |

#### TC-P18: Restore from Trash

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | On trash view, click Restore for Tuesday | GET request to restore route |
| 2 | Verify redirect | Redirect to trash view |
| 3 | Verify flash message | Success flash message displayed |
| 4 | Navigate to main School Days tab | Tuesday reappears in table; status is Active |
| 5 | Query DB directly | `deleted_at` null; `is_active=1` |

#### TC-P19: Force Delete from Trash

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft delete a test day (e.g., EXTRA) | — |
| 2 | Navigate to trash view | EXTRA listed |
| 3 | Click Force Delete (X icon) | DELETE request to force-delete route |
| 4 | Verify redirect | Redirect to trash view |
| 5 | Verify flash message | Success flash message displayed |
| 6 | Verify record absent from trash and main list | EXTRA removed permanently |
| 7 | Query DB directly | Record does not exist |

#### TC-P20: Trash Pagination with 12+ Deleted Records

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create and soft-delete 12 test school days (unique codes) | — |
| 2 | Navigate to trash view | 10 records on page 1; pagination controls visible |
| 3 | Click page 2 | 2+ remaining records shown; `trashed_page=2` in URL |

---

### 7.2 Negative TC Steps

#### TC-N01: Missing Required Fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to create form | — |
| 2 | Leave code, name, short_name, day_of_week, ordinal blank | — |
| 3 | Submit form | Validation errors: "The code field is required.", "The name field is required.", "The short name field is required.", "The day of week field is required.", "The ordinal field is required."; form not submitted |

#### TC-N02: Duplicate Code

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a school day with code `MON` (already exists) | Validation error: "The code has already been taken." |

#### TC-N03: Duplicate day_of_week

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a school day with `day_of_week=1` (Monday already has 1) | Validation error: "The day of week has already been taken." |

#### TC-N04: day_of_week Out of Range

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a school day with `day_of_week=0` | Validation error: "The day of week must be between 1 and 7." |
| 2 | Create a school day with `day_of_week=8` | Same validation error |

#### TC-N05: Ordinal Less Than 1

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a school day with `ordinal=0` | Validation error: "The ordinal must be at least 1." |

#### TC-N06: Update — Duplicate Code Excluding Own ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Edit Tuesday row, change code to "MON" | Validation error: "The code has already been taken." |

#### TC-N07: Guest Access Redirect

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Log out | — |
| 2 | Navigate to `GET /school-day/create` | Redirected to `/login` |

#### TC-N08: Missing viewAny Permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Log in as user without `viewAny` permission | — |
| 2 | Navigate to School Days tab | 403 Forbidden |

#### TC-N09: Missing create Permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Log in as user without `create` permission | — |
| 2 | Navigate to create form or POST store | 403 Forbidden |

#### TC-N10: Missing update Permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Log in as user without `update` permission | — |
| 2 | Navigate to edit form or PUT update | 403 Forbidden |

#### TC-N11: Missing delete Permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Log in as user without `delete` permission | — |
| 2 | Attempt to delete a school day | 403 Forbidden |

#### TC-N12: Non-Existent Record

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to `GET /school-day/9999` | HTTP 404 |
| 2 | Navigate to edit for ID 9999 | HTTP 404 |
| 3 | POST to update with ID 9999 | HTTP 404 |

#### TC-N13: Toggle Status on Non-Existent Record

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST to toggle-status with invalid ID (9999) | HTTP 404 |

#### TC-N14: Force Delete Non-Existent Record

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | DELETE to force-delete with invalid ID (9999) | HTTP 404 |

---

### 7.3 Dependency TC Steps

#### TC-D01: Activity Logging on State Changes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a new school day | Activity log entry created: action 'Created', message 'School day was created.' |
| 2 | Edit and update the school day | Activity log entry created: action 'Updated', message 'School day was updated.' |
| 3 | Toggle status of the school day | Activity log entry created: action 'Toggled', message 'School day status was updated.' |
| 4 | Soft delete the school day | Activity log entry created: action 'Trashed', message 'School day was deactivated and moved to trash.' |
| 5 | Restore the school day | Activity log entry created: action 'Restored', message 'School day was restored successfully.' |
| 6 | Force delete the school day | Activity log entry created: action 'Deleted', message 'School day was permanently deleted.' |

#### TC-D02: Model — `$fillable` Matches DDL Columns

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `SchoolDay.php` `$fillable` array | Contains exactly: `code`, `name`, `short_name`, `day_of_week`, `ordinal`, `is_school_day`, `is_active` — matching all 7 editable DDL columns (excluding id, timestamps, deleted_at) |

#### TC-D03: Model — `$casts` for Boolean/Integer/Datetime

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `SchoolDay.php` `$casts` array | `is_school_day` → `boolean`, `is_active` → `boolean`, `day_of_week` → `integer`, `ordinal` → `integer`, `created_at` → `datetime`, `updated_at` → `datetime`, `deleted_at` → `datetime` |

#### TC-D04: Unique Code Constraint at DB Level

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Insert a duplicate code directly: `INSERT INTO tt_school_days (code, name, short_name, day_of_week, ordinal) VALUES ('MON', 'Duplicate', 'Dup', 8, 8)` | SQL error: `SQLSTATE[23000]: Integrity constraint violation` — duplicate entry for key `uq_schoolday_code` |

#### TC-D05: Unique day_of_week Constraint at DB Level

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Insert a duplicate day_of_week directly: `INSERT INTO tt_school_days (code, name, short_name, day_of_week, ordinal) VALUES ('TEST', 'Test', 'Tst', 1, 8)` | SQL error: `SQLSTATE[23000]: Integrity constraint violation` — duplicate entry for key `uq_schoolday_dow` |

#### TC-D06: Working Day Initialization Reads School Days

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure `week_start_day` = MONDAY and `default_school_closed_days_per_week` = 1 in `tt_configs` | — |
| 2 | Verify Saturday has `is_school_day = true` | — |
| 3 | Initialize working days via `ajaxInitializeWorkingDays` | Saturdays have Working Day type (not Holiday) |
| 4 | Toggle Saturday's `is_school_day` to false | — |
| 5 | Clear existing working days | — |
| 6 | Initialize working days again | Saturdays now have Holiday type; `is_school_day = false` for Saturdays |
| 7 | Restore Saturday's `is_school_day` to true | Clean up |

---
