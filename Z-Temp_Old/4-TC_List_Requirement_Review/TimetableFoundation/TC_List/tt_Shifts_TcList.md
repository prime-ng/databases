# tt_Shifts_TcList

## Module: TimetableFoundation → Timetable Masters → Shifts

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | TimetableFoundation |
| Tab Group | Timetable Masters |
| Feature | Shifts |
| URL(s) | `GET /timetable-foundation/shift` — redirects to `timetable-foundation.menu.timetableMasters?tab=shifts` |
| | `GET /timetable-foundation/shift/create` — create form |
| | `POST /timetable-foundation/shift` — store |
| | `GET /timetable-foundation/shift/{id}` — show |
| | `GET /timetable-foundation/shift/{id}/edit` — edit form |
| | `PUT /timetable-foundation/shift/{id}` — update |
| | `DELETE /timetable-foundation/shift/{id}` — destroy (soft) |
| | `GET /timetable-foundation/shift/trash/view` — trashed list |
| | `GET /timetable-foundation/shift/{id}/restore` — restore |
| | `DELETE /timetable-foundation/shift/{id}/force-delete` — force delete |
| | `POST /timetable-foundation/shift/{shift}/toggle-status` — toggle AJAX |
| Controller | `Modules\TimetableFoundation\Http\Controllers\SchoolShiftController`; `index()` (redirect), `create()`, `store()`, `show()`, `edit()`, `update()`, `destroy()`, `trashedShift()`, `restore()`, `forceDelete()`, `toggleStatus()` |
| Model(s) | `Modules\TimetableFoundation\Models\SchoolShift` (table: `tt_shifts`) |
| Validation (Create) | Inline in `store()` (no separate Form Request) |
| Validation (Update) | Inline in `update()` — unique rules ignore current ID |
| Policy | Implicit (no dedicated Policy file) — `Gate::authorize()` uses permission strings directly |
| Permissions | `timetable-foundation.shift.viewAny` |
| | `timetable-foundation.shift.view` |
| | `timetable-foundation.shift.create` |
| | `timetable-foundation.shift.update` |
| | `timetable-foundation.shift.delete` |
| | `timetable-foundation.shift.restore` |
| | `timetable-foundation.shift.forceDelete` |
| Pagination | No pagination on main tab; 10 records per page on trash view |
| Soft Deletes | Yes — `SoftDeletes` trait on Model |
| Read-Only | No — full CRUD |

---

## 2. Pre-conditions

- Admin user has all `timetable-foundation.shift.*` permissions granted.
- Dusk environment variables set: `DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD`.
- Tenant academic session, classes, sections, subjects not required for this CRUD screen (no FK dependencies at creation time).
- At least one shift exists for edit/delete tests (created fresh as needed).

---

## 3. Default Data Load

The `index()` method in `SchoolShiftController` redirects to `TimetableFoundationController@timetableMasters` with `tab=shifts`. That method queries shifts with timetable types count, ordered by `ordinal`, no pagination.

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| Shifts list | `TimetableFoundationController@timetableMasters` | `SchoolShift::withCount('timetableTypes')->orderBy('ordinal')->get()` | `s_search` (name/code), `s_status` (1/0) | None (master data) |

---

## 4. Test Data Strategy

- **Seed shifts**: Create 3 seed shifts via UI: MORNING, AFTERNOON, EVENING with ordinals 1, 2, 3.
- **Test shifts**: Create additional test shifts via UI for edit/delete/toggle tests — use unique codes e.g. `TEST_SHIFT_01`, `TEST_SHIFT_02`.
- **Pre-test cleanup**: Ensure no test shift codes collide — use a unique test prefix.
- **Child table data**: For dependency tests, create Period Config, Timetable Type, or Period Set records referencing a shift to verify RESTRICT behaviour.
- **Pagination overflow**: Create 12+ shifts in trash to test the 10-record per-page limit (trash only).

---

## 5. Business Conditions

### 5.1 Database Schema — `tt_shifts`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | `id` | TINYINT UNSIGNED | PK, NOT NULL, AUTO_INCREMENT |
| BC-DB-02 | `code` | VARCHAR(20) | NOT NULL, UNIQUE (`uq_shift_code`) |
| BC-DB-03 | `name` | VARCHAR(100) | NOT NULL, UNIQUE (`uq_shift_name`) |
| BC-DB-04 | `description` | VARCHAR(255) | DEFAULT NULL |
| BC-DB-05 | `default_start_time` | TIME | DEFAULT NULL |
| BC-DB-06 | `default_end_time` | TIME | DEFAULT NULL |
| BC-DB-07 | `ordinal` | TINYINT UNSIGNED | NOT NULL, UNIQUE (`uq_shift_ordinal`) |
| BC-DB-08 | `is_active` | TINYINT(1) | NOT NULL, DEFAULT 1 |
| BC-DB-09 | `created_at` | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |
| BC-DB-10 | `updated_at` | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP |
| BC-DB-11 | `deleted_at` | TIMESTAMP | NULL DEFAULT NULL |
| BC-DB-12 | UNIQUE KEY `uq_shift_code` | — | `code` |
| BC-DB-13 | UNIQUE KEY `uq_shift_name` | — | `name` |
| BC-DB-14 | UNIQUE KEY `uq_shift_ordinal` | — | `ordinal` |

### 5.2 Validation Rules — Inline in `store()` (Create)

| BC ID | Field | Rule(s) | Error Message |
|-------|-------|---------|---------------|
| BC-VAL-01 | `code` | `required`, `string`, `max:20`, `unique:tt_shifts,code` with `whereNull('deleted_at')` | Laravel default |
| BC-VAL-02 | `name` | `required`, `string`, `max:100`, `unique:tt_shifts,name` with `whereNull('deleted_at')` | Laravel default |
| BC-VAL-03 | `description` | `nullable`, `string`, `max:255` | Laravel default |
| BC-VAL-04 | `default_start_time` | `nullable`, `date_format:H:i` | Laravel default |
| BC-VAL-05 | `default_end_time` | `nullable`, `date_format:H:i`, `after:default_start_time` | Laravel default |
| BC-VAL-06 | `ordinal` | `required`, `integer`, `min:1`, `unique:tt_shifts,ordinal` with `whereNull('deleted_at')` | Laravel default |
| BC-VAL-07 | `is_active` | `nullable` (normalized via `$request->boolean()`) | — |

### 5.3 Validation Rules — Inline in `update()` (Update)

| BC ID | Field | Rule(s) | Error Message |
|-------|-------|---------|---------------|
| BC-VAL-08 | `code` | `required`, `string`, `max:20`, `unique:tt_shifts,code` → ignores current ID with `whereNull('deleted_at')` | Laravel default |
| BC-VAL-09 | `name` | `required`, `string`, `max:100`, `unique:tt_shifts,name` → ignores current ID with `whereNull('deleted_at')` | Laravel default |
| BC-VAL-10 | `description` | `nullable`, `string`, `max:255` | Laravel default |
| BC-VAL-11 | `default_start_time` | `nullable`, `date_format:H:i` | Laravel default |
| BC-VAL-12 | `default_end_time` | `nullable`, `date_format:H:i`, `after:default_start_time` | Laravel default |
| BC-VAL-13 | `ordinal` | `required`, `integer`, `min:1`, `unique:tt_shifts,ordinal` → ignores current ID with `whereNull('deleted_at')` | Laravel default |
| BC-VAL-14 | `is_active` | `nullable` (normalized via `$request->boolean()`) | — |

### 5.4 Authorization

| BC ID | Permission | Behavior |
|-------|-----------|----------|
| BC-AUTH-01 | `timetable-foundation.shift.viewAny` | Without it → 403 on index / trashed list |
| BC-AUTH-02 | `timetable-foundation.shift.view` | Without it → 403 on show |
| BC-AUTH-03 | `timetable-foundation.shift.create` | Without it → 403 on create/store |
| BC-AUTH-04 | `timetable-foundation.shift.update` | Without it → 403 on edit/update/toggleStatus |
| BC-AUTH-05 | `timetable-foundation.shift.delete` | Without it → 403 on destroy/forceDelete |
| BC-AUTH-06 | `timetable-foundation.shift.restore` | Without it → 403 on restore/trashed view |
| BC-AUTH-07 | `timetable-foundation.shift.forceDelete` | Without it → 403 on forceDelete |
| BC-AUTH-08 | Guest access | Redirect to `/login` on any route |

### 5.5 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Screen loads with `tab=shifts` | Table list of shifts rendered; each row shows ordinal, code, name, description, default start/end time, timetable type count, status toggle, action buttons |
| BC-BIZ-02 | Search by `s_search` | Shifts matching name or code (case-insensitive substring) shown; non-matching shifts hidden |
| BC-BIZ-03 | Filter by `s_status=1` | Only active shifts displayed |
| BC-BIZ-04 | Filter by `s_status=0` | Only inactive shifts displayed |
| BC-BIZ-05 | Empty shift list | "No shifts found." or equivalent placeholder displayed |
| BC-BIZ-06 | Soft delete a shift | `is_active` set to false before `delete()`; record moved to trash with `deleted_at` |
| BC-BIZ-07 | Restore from trash | `is_active` set to true after `restore()`; record reappears in main list |
| BC-BIZ-08 | Toggle status | AJAX POST flips `is_active`; JSON response `{success: true, is_active, message}` returned |
| BC-BIZ-09 | Start time provided without end time | Allowed — no validation error |
| BC-BIZ-10 | End time provided without start time | Validation error — `after:default_start_time` rule requires default_start_time to be non-null (`after` rule fails when comparing against null) |

### 5.6 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|------------------|----------------|
| BC-REF-01 | `tt_period_configs.shift_id` | `tt_shifts.id` | RESTRICT |
| BC-REF-02 | `tt_timetable_types.shift_id` | `tt_shifts.id` | RESTRICT |
| BC-REF-03 | `tt_period_sets.shift_id` | `tt_shifts.id` | RESTRICT |

---

## 6. Test Case List

### 6.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|-----------------|---------|---------|--------|
| TC-P01 | Load shifts tab on Timetable Masters page | `GET /timetable-foundation/timetable-masters?tab=shifts` returns 200; table rendered with all shifts ordered by ordinal; each row shows: ordinal #, code, name, description (or "—"), default start/end times, timetable type count, status toggle, action buttons | — | — | ⬜ |
| TC-P02 | Search shifts by code or name | Enter `MORNING` in search box, submit; only shifts with code/name containing "MORNING" shown; non-matching shifts hidden | — | — | ⬜ |
| TC-P03 | Filter by active status | Select "Active" from status dropdown, submit; only shifts with `is_active = 1` displayed | — | — | ⬜ |
| TC-P04 | Filter by inactive status | Select "Inactive" from status dropdown, submit; only shifts with `is_active = 0` displayed | — | — | ⬜ |
| TC-P05 | Reset filters | Apply search and status filter, then click reset button; all shifts shown without filters | — | — | ⬜ |
| TC-P06 | Create shift — all fields filled | Fill code=`MORNING`, name=`Morning Shift`, description=`Standard morning shift`, default_start_time=`07:30`, default_end_time=`14:30`, ordinal=`1`, Active=checked; submit; shift created; redirect to tab; success flash | — | — | ⬜ |
| TC-P07 | Create shift — required fields only | Fill code=`AFTERNOON`, name=`Afternoon Shift`, ordinal=`2`; leave description, start/end times blank; submit; shift created with defaults (`is_active=true`); optional fields null | — | — | ⬜ |
| TC-P08 | View shift details | Navigate to show page for a shift; all fields displayed: Code, Name, Description, Default Start Time, Default End Time, Ordinal, Is Active, Created At, Updated At, timetable types count | — | — | ⬜ |
| TC-P09 | Edit shift — update name and times | Navigate to edit page for a shift; change name to `Updated Shift`, set default_start_time=`08:00`, default_end_time=`15:00`; submit; update succeeds; redirect to tab; success flash; values updated | — | — | ⬜ |
| TC-P10 | Toggle active status via AJAX | POST to toggle-status endpoint with `is_active=true` for an inactive shift; JSON response `{"success":true, "is_active":true, "message":"..."}`; DB updated; status badge changes in UI | — | — | ⬜ |
| TC-P11 | Soft delete shift | Click delete on a shift; `is_active` set to false; record soft-deleted (`deleted_at` populated); redirect to tab; success flash; record no longer appears in main list | — | — | ⬜ |
| TC-P12 | Trash view loads soft-deleted shifts | Navigate to trash view; soft-deleted records shown with code, name, description, "Inactive" status badge, restore and force-delete action buttons | — | — | ⬜ |
| TC-P13 | Restore shift from trash | Click restore on a soft-deleted shift; `restore()` called; `is_active` set to true; redirect to trash; success flash; record reappears in main list | — | — | ⬜ |
| TC-P14 | Force delete shift from trash | Click force delete on a soft-deleted shift; record permanently deleted from DB; redirect to trash; success flash; record no longer in trash | — | — | ⬜ |
| TC-P15 | Trash view pagination | Create 12+ soft-deleted shifts; navigate to page 2 of trash view; remaining records shown with correct pagination | — | — | ⬜ |

### 6.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|-----------------|---------|---------|--------|
| TC-N01 | Create shift — missing required fields | Submit create form with empty code, name, ordinal; validation errors for `code` (required), `name` (required), `ordinal` (required) | — | — | ⬜ |
| TC-N02 | Create shift — duplicate code | Submit with code `MORNING` (already exists); validation error: `code` must be unique | — | — | ⬜ |
| TC-N03 | Create shift — duplicate name | Submit with name `Morning Shift` (already exists); validation error: `name` must be unique | — | — | ⬜ |
| TC-N04 | Create shift — duplicate ordinal | Submit with ordinal `1` (already exists); validation error: `ordinal` must be unique | — | — | ⬜ |
| TC-N05 | Create shift — ordinal less than 1 | Submit `ordinal=0`; validation error: min:1 | — | — | ⬜ |
| TC-N06 | Create shift — end time before start time | Set `default_start_time=14:00`, `default_end_time=12:00`; validation error: `after:default_start_time` | — | — | ⬜ |
| TC-N07 | Create shift — end time provided without start time | Set `default_end_time=14:00` with no start time; validation error: `after:default_start_time` rule fails | — | — | ⬜ |
| TC-N08 | Edit shift — update to duplicate code | Change shift code to an existing code; validation error: `code` must be unique | — | — | ⬜ |
| TC-N09 | Guest access to index route | Visit any shift route while not logged in; redirect to `/login` | — | — | ⬜ |
| TC-N10 | Missing viewAny permission | User without `viewAny` tries to access index; 403 Forbidden | — | — | ⬜ |
| TC-N11 | Missing create permission | User without `create` tries to access create/store; 403 Forbidden | — | — | ⬜ |
| TC-N12 | Non-existent shift ID — show/edit/update/destroy | Access route with invalid ID (e.g. 9999); 404 Not Found | — | — | ⬜ |
| TC-N13 | Delete shift referenced by Period Config | Try to delete a shift that has Period Config records; DB FK RESTRICT throws integrity violation; shift not deleted; 500 error page | — | — | ⬜ |
| TC-N14 | Delete shift referenced by Timetable Type | Try to delete a shift that has Timetable Type records; DB FK RESTRICT throws integrity violation; shift not deleted; 500 error page | — | — | ⬜ |

### 6.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|-----------------|---------|---------|--------|
| TC-D01 | A | Delete shift that has Period Config records | Delete blocked by FK RESTRICT constraint; DB throws integrity constraint violation; shift not deleted | — | — | ⬜ |
| TC-D02 | A | Delete shift that has Timetable Type records | Delete blocked by FK RESTRICT constraint; DB throws integrity constraint violation; shift not deleted | — | — | ⬜ |
| TC-D03 | A | Delete shift that has Period Set records | Delete blocked by FK RESTRICT constraint; DB throws integrity constraint violation; shift not deleted | — | — | ⬜ |
| TC-D04 | B | Activity logging on update/delete/restore/toggle | `update()` creates activity log entry with action 'Updated'; `destroy()` with action 'Trashed'; `restore()` with action 'Restored'; `forceDelete()` with action 'Deleted'; `toggleStatus()` with action 'Toggled' | — | — | ⬜ |
| TC-D05 | C | Model `$fillable` matches DDL columns | `$fillable` array contains: code, name, description, default_start_time, default_end_time, ordinal, is_active (no extra columns, no missing columns) | — | — | ⬜ |
| TC-D06 | C | Model `$casts` for boolean/integer/datetime columns | `is_active` → boolean, `ordinal` → integer, `default_start_time` → datetime, `default_end_time` → datetime | — | — | ⬜ |
| TC-D07 | D | Unique `code` constraint at DB level | Direct DB insert with duplicate code (e.g. 'MORNING') throws `SQLSTATE[23000]: Integrity constraint violation` for `uq_shift_code` | — | — | ⬜ |
| TC-D08 | D | Unique `name` constraint at DB level | Direct DB insert with duplicate name throws `SQLSTATE[23000]` for `uq_shift_name` | — | — | ⬜ |
| TC-D09 | D | Unique `ordinal` constraint at DB level | Direct DB insert with duplicate ordinal throws `SQLSTATE[23000]` for `uq_shift_ordinal` | — | — | ⬜ |

### 6.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|-----------------|---------|---------|--------|
| TC-CR01 | CR | P1 | Model — `$fillable` matches DDL columns for mass-assignment protection | All 7 DDL columns present (code, name, description, default_start_time, default_end_time, ordinal, is_active); no extra column | — | — | ◌ |
| TC-CR02 | CR | P1 | Model — `$casts` for booleans/integers/dates | `is_active` → boolean; `ordinal` → integer; `default_start_time` → datetime; `default_end_time` → datetime | — | — | ◌ |
| TC-CR03 | CR | P1 | Model — SoftDeletes trait correctly implemented | `SoftDeletes` imported and used; `deleted_at` column expected in DB | — | — | ◌ |
| TC-CR04 | CR | P1 | Model — relationships defined | `timetableTypes()` (hasMany TimetableType) defined with correct FK `shift_id` | — | — | ◌ |
| TC-CR05 | CR | P1 | Controller — try-catch exception handling on all write methods | `store()`, `update()`, `destroy()`, `forceDelete()`, `restore()`, `toggleStatus()` handle exceptions gracefully | — | — | ◌ |
| TC-CR06 | CR | P1 | Controller — DB transactions on multi-step writes | `destroy()` wraps deactivate+delete; `restore()` wraps restore+activate | — | — | ◌ |
| TC-CR07 | CR | P1 | Controller — `Gate::authorize()` on every method | Each public method calls `Gate::authorize()` before any logic | — | — | ◌ |
| TC-CR08 | CR | P1 | Controller — activity logged on all state changes | `update()` → 'Updated'; `destroy()` → 'Trashed'; `forceDelete()` → 'Deleted'; `restore()` → 'Restored'; `toggleStatus()` → 'Toggled'; `store()` does NOT log activity (noted gap) | — | — | ◌ |
| TC-CR09 | CR | P1 | Controller — `is_active=false` before soft delete; restore sets `is_active=true` | `destroy()` sets `is_active=false` via `update()` then `delete()`; `restore()` calls `restore()` then sets `is_active=true` via `update()` | — | — | ◌ |
| TC-CR10 | CR | P1 | Controller — `toggleStatus()` flips `is_active` | Method validates `is_active` boolean, updates model, returns JSON `{success: true, is_active, message}` | — | — | ◌ |
| TC-CR11 | CR | P1 | Controller — trash/restore/forceDelete flow | `trashedShift()` uses `onlyTrashed()` + `paginate(10)`; `restore()` uses `onlyTrashed()->findOrFail($id)`; `forceDelete()` uses `withTrashed()->findOrFail($id)` | — | — | ◌ |
| TC-CR12 | CR | P1 | Controller — JSON/flash response after write operations | All write methods return redirect with `success` flash message (or JSON for toggleStatus); failure scenarios return `error` flash | — | — | ◌ |
| TC-CR13 | CR | P1 | Validation — rules cover all fields; unique rules ignore current ID on update | `store()`: 3 unique rules; `update()`: each unique rule has `->ignore($shift->id)` | — | — | ◌ |
| TC-CR14 | CR | P1 | Routes — resource + custom routes registered; model binding 404s | `Route::resource('shift', ...)` generates 7 routes; 4 custom routes (trashed, restore, forceDelete, toggleStatus); implicit model binding on toggle route | — | — | ◌ |
| TC-CR15 | CR | P1 | View — Blade `@can` directives on action buttons | Action buttons (edit, delete, status switch) visibility gated by user permissions | — | — | ◌ |
| TC-CR16 | CR | P1 | Breadcrumb — route registered in `config/breadcrumb.php` | Breadcrumb for shift routes renders correct hierarchy under Timetable Masters | — | — | ◌ |

---

## 7. Detailed Test Steps

#### TC-CR01: Model — `$fillable` Matches DDL Columns

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `SchoolShift.php` `$fillable` array | Array contains: `code`, `name`, `description`, `default_start_time`, `default_end_time`, `ordinal`, `is_active` |
| 2 | Cross-reference with DDL columns of `tt_shifts` | All 7 fillable columns exist in DDL; no fillable column absent from DDL; no DDL column that is fillable (excluding id, timestamps, deleted_at) is missing |

#### TC-CR02: Model — `$casts` for Booleans/Integers/Dates

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `SchoolShift.php` `$casts` array | Contains: `is_active`→boolean, `ordinal`→integer, `default_start_time`→datetime, `default_end_time`→datetime |

#### TC-CR03: Model — SoftDeletes Trait

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `SchoolShift.php` imports | `use SoftDeletes;` present from `Illuminate\Database\Eloquent\SoftDeletes` |

#### TC-CR04: Model — Relationships Defined

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `SchoolShift.php` | `timetableTypes()` returns `$this->hasMany(TimetableType::class, 'shift_id')` |

#### TC-CR05: Controller — Try-Catch Exception Handling

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `SchoolShiftController.php` `store()` method | Method body wrapped in `try-catch`; exception caught gracefully; validation errors returned as redirect back with `error` flash |
| 2 | Inspect `update()` method | Try-catch present; database or validation exceptions handled; error flash on failure |
| 3 | Inspect `destroy()`, `forceDelete()`, `restore()`, `toggleStatus()` methods | Each method has try-catch handling; exceptions do not propagate as unhandled 500 errors |

#### TC-CR06: Controller — DB Transactions on Multi-Step Writes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `destroy()` method | Uses `DB::transaction()` or `\DB::beginTransaction()` to wrap both `is_active=false` update and `delete()` call; transaction committed on success, rolled back on failure |
| 2 | Inspect `restore()` method | Uses `DB::transaction()` to wrap `restore()` call and `is_active=true` update; atomic operation |

#### TC-CR07: Controller — `Gate::authorize()` on Every Method

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect each public method in `SchoolShiftController.php` | Each method (`index`, `create`, `store`, `show`, `edit`, `update`, `destroy`, `trashedShift`, `restore`, `forceDelete`, `toggleStatus`) calls `Gate::authorize()` with appropriate permission string before any business logic |

#### TC-CR08: Controller — Activity Logged on All State Changes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `update()` method | Calls `activityLog()` with action `'Updated'` and descriptive message after successful save |
| 2 | Inspect `destroy()`, `forceDelete()`, `restore()`, `toggleStatus()` methods | `destroy()` logs `'Trashed'`; `forceDelete()` logs `'Deleted'`; `restore()` logs `'Restored'`; `toggleStatus()` logs `'Toggled'`; each with appropriate message text |

#### TC-CR09: Controller — `is_active=false` Before Soft Delete; Restore Sets `is_active=true`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `destroy()` method | Sets `$shift->is_active = false` via `update()` method, then calls `$shift->delete()` to soft-delete |
| 2 | Inspect `restore()` method | Calls `$shift->restore()` (Eloquent), then sets `$shift->is_active = true` via `update()` |

#### TC-CR10: Controller — `toggleStatus()` Flips `is_active`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `toggleStatus()` method | Validates incoming `is_active` boolean parameter; updates model's `is_active` to the new value |
| 2 | Verify return value | Returns JSON response `{"success": true, "is_active": <new_value>, "message": "..."}` on success; JSON with `success: false` on failure |

#### TC-CR11: Controller — Trash/Restore/ForceDelete Flow

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `trashedShift()` method | Uses `SchoolShift::onlyTrashed()->paginate(10)` to load soft-deleted records with 10-record pagination |
| 2 | Inspect `restore()` method | Uses `SchoolShift::onlyTrashed()->findOrFail($id)` to locate trashed record before restoring |
| 3 | Inspect `forceDelete()` method | Uses `SchoolShift::withTrashed()->findOrFail($id)` to locate record (including soft-deleted) before permanent deletion |

#### TC-CR12: Controller — JSON/Flash Response After Write Operations

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `store()`, `update()`, `destroy()`, `restore()`, `forceDelete()` methods | Each returns `redirect()->route(...)` with `->with('success', '...')` flash message on success; `->with('error', '...')` on failure |
| 2 | Inspect `toggleStatus()` method | Returns `response()->json(['success' => true, 'is_active' => ..., 'message' => '...'])` (not a redirect) |

#### TC-CR13: Validation — Rules Cover All Fields; Unique Ignores Current ID on Update

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `store()` validation rules | `code` has `unique:tt_shifts,code` with `whereNull('deleted_at')`; `name` has `unique:tt_shifts,name` with `whereNull('deleted_at')`; `ordinal` has `unique:tt_shifts,ordinal` with `whereNull('deleted_at')` |
| 2 | Inspect `update()` validation rules | Each unique rule appends `->ignore($shift->id)` to exclude the current record from uniqueness check |

#### TC-CR14: Routes — Resource + Custom Routes Registered

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `web.php` or `routes/*` for shift routes | `Route::resource('shift', SchoolShiftController::class)` generates 7 standard resource routes |
| 2 | Locate custom routes | 4 custom routes registered: `trash/view` (GET), `{id}/restore` (GET), `{id}/force-delete` (DELETE), `{shift}/toggle-status` (POST) |
| 3 | Verify implicit model binding | Toggle route uses `{shift}` parameter for implicit binding; non-existent IDs resolve to 404 |

#### TC-CR15: View — Blade `@can` Directives on Action Buttons

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect shift index/show Blade view files | Action buttons (View, Edit, Trash, Restore, Force Delete, Status Toggle) wrapped in `@can('timetable-foundation.shift.view')`, `@can('timetable-foundation.shift.update')`, etc. |
| 2 | Verify fallback | When user lacks permission, the corresponding button/action is not rendered in HTML |

#### TC-CR16: Breadcrumb — Route Registered in `config/breadcrumb.php`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `config/breadcrumb.php` | Shift routes included in breadcrumb configuration; hierarchy shows Timetable Masters → Shifts for the index route |
| 2 | Verify child route breadcrumbs | Create, edit, show, trash routes have correct parent-child breadcrumb relationships

---

### 7.1 Positive TC Steps

#### TC-P01: Load Shifts Tab

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Log in as admin with full permissions | Dashboard loads |
| 2 | Navigate to `GET /timetable-foundation/timetable-masters?tab=shifts` | HTTP 200; page title "Timetable Masters" visible |
| 3 | Locate the Shifts tab pane | Table rendered with shift items; each row shows ordinal (#), code (e.g. MORNING), name (e.g. "Morning Shift"), description (or "—" if null), default start/end time (or "—" if null), timetable type count, status toggle switch, action buttons (View, Edit, Trash) |
| 4 | Verify rows ordered by ordinal ascending | Shifts listed in ordinal order (1, 2, 3...) |

#### TC-P02: Search Shifts by Code or Name

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Type `MORNING` in the search bar | — |
| 2 | Click search (magnifying glass) button | Page reloads with `?tab=shifts&s_search=MORNING`; only shift with "MORNING" in code or name shown; non-matching shifts hidden |
| 3 | Clear search and submit empty search | All shifts shown again |

#### TC-P03: Filter by Active Status

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select "Active" from status dropdown | — |
| 2 | Click search button | Page reloads with `?tab=shifts&s_status=1`; only shifts with `is_active=1` displayed |

#### TC-P04: Filter by Inactive Status

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select "Inactive" from status dropdown | — |
| 2 | Click search button | Page reloads with `?tab=shifts&s_status=0`; only shifts with `is_active=0` displayed |

#### TC-P05: Reset Filters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Apply search text and status filter | Filtered results shown |
| 2 | Click reset (rotate-left icon) button | Page reloads with `?tab=shifts`; all shifts shown; search and filter fields cleared |

#### TC-P06: Create Shift — All Fields Filled

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click "Add" button to navigate to create form | `GET /timetable-foundation/shift/create` — form rendered with all fields |
| 2 | Fill code: `MORNING` | — |
| 3 | Fill name: `Morning Shift` | — |
| 4 | Fill description: `Standard morning shift for grades 3-12` | — |
| 5 | Fill default_start_time: `07:30` | — |
| 6 | Fill default_end_time: `14:30` | — |
| 7 | Fill ordinal: `1` | — |
| 8 | Ensure "Active" status switch is ON | — |
| 9 | Click "Create Shift" submit button | POST request; redirect to `timetable-foundation.menu.timetableMasters?tab=shifts`; success flash message displayed |
| 10 | Find `MORNING` in the table | Shift present with code `MORNING`, name "Morning Shift", start time "07:30", end time "14:30", ordinal #1, active status badge |

#### TC-P07: Create Shift — Required Fields Only

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to create form | — |
| 2 | Fill code: `AFTERNOON` | — |
| 3 | Fill name: `Afternoon Shift` | — |
| 4 | Fill ordinal: `2` | — |
| 5 | Leave description, start time, end time blank | — |
| 6 | Submit form | Shift created; code=`AFTERNOON`, name=`Afternoon Shift`, description=null, default_start_time=null, default_end_time=null, ordinal=2, `is_active=true` |

#### TC-P08: View Shift Details

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to show page for a shift: `GET /timetable-foundation/shift/{id}` | HTTP 200; detail table with all fields displayed: Code, Name, Description, Default Start Time, Default End Time, Ordinal, Is Active (Yes/No badge), Created At, Updated At |
| 2 | Verify timetable types count displayed | Count of related timetable types shown |
| 3 | Verify Edit button present | Link to edit route visible |
| 4 | Verify Back button present | Link to `timetableMasters?tab=shifts` visible |

#### TC-P09: Edit Shift — Update Name and Times

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to edit page for a shift: `GET /timetable-foundation/shift/{id}/edit` | Form pre-filled with current data |
| 2 | Change name to `Updated Shift` | — |
| 3 | Set default_start_time to `08:00` | — |
| 4 | Set default_end_time to `15:00` | — |
| 5 | Submit form | PUT request; redirect to tab; success flash message |
| 6 | Find the shift in the list | Name updated to "Updated Shift"; start time "08:00"; end time "15:00" |

#### TC-P10: Toggle Active Status via AJAX

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Identify an inactive non-system shift | — |
| 2 | Click the status toggle switch for that shift | AJAX POST to `toggle-status` endpoint with `is_active=true` |
| 3 | Verify response | JSON `{"success": true, "is_active": true, "message": "..."}` |
| 4 | Verify UI updates | Status badge changes to "Active" (green); list reflects new active state upon reload |

#### TC-P11: Soft Delete Shift

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click delete (trash icon) on a shift (e.g. `AFTERNOON`) | DELETE request to destroy route |
| 2 | Verify redirect | Redirect to `timetableMasters?tab=shifts` |
| 3 | Verify flash | Success flash message displayed |
| 4 | Verify shift absent from main list | `AFTERNOON` not in table |
| 5 | Query DB directly | `deleted_at` populated; `is_active=0` |

#### TC-P12: Trash View Loads Soft-Deleted Shifts

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to trash view: `GET /timetable-foundation/shift/trash/view` | HTTP 200; table with Code, Name, Description, Status, Action columns |
| 2 | Verify deleted shift appears | `AFTERNOON` listed with: code `AFTERNOON`, name "Afternoon Shift", status "Inactive" badge, restore and force-delete action icons |

#### TC-P13: Restore Shift from Trash

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | On trash view, click restore (undo icon) for `AFTERNOON` | GET request to restore route |
| 2 | Verify redirect | Redirect to trash view |
| 3 | Verify flash | Success flash message displayed |
| 4 | Navigate to main shifts tab | `AFTERNOON` reappears in table; status is active |
| 5 | Query DB directly | `deleted_at` null; `is_active=1` |

#### TC-P14: Force Delete Shift from Trash

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft delete a shift (e.g. `EVENING`) | — |
| 2 | Navigate to trash view | Shift visible in trash |
| 3 | Click force delete (X icon) for `EVENING` | DELETE request to force-delete route |
| 4 | Verify redirect | Redirect to trash view |
| 5 | Verify flash | Success flash message displayed |
| 6 | Verify shift absent from trash and main list | Shift permanently removed |
| 7 | Query DB directly | Shift record does not exist |

#### TC-P15: Trash View Pagination

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure 12+ soft-deleted shifts exist | — |
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
| 1 | Create shift with `code=MORNING` | Created successfully |
| 2 | Create another shift with `code=MORNING` | Validation error: "The code has already been taken." |

#### TC-N03: Duplicate Name

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create shift with `name=Morning Shift` | Created successfully |
| 2 | Create another shift with `name=Morning Shift` | Validation error: "The name has already been taken." |

#### TC-N04: Duplicate Ordinal

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create shift with `ordinal=1` | Created successfully |
| 2 | Create another shift with `ordinal=1` | Validation error: "The ordinal has already been taken." |

#### TC-N05: Ordinal Less Than 1

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create shift with `ordinal=0` | Validation error: "The ordinal must be at least 1." |

#### TC-N06: End Time Before Start Time

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create shift with `default_start_time=14:00`, `default_end_time=12:00` | Validation error: "The default end time must be a date after default start time." |

#### TC-N07: End Time Without Start Time

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create shift with `default_end_time=14:00`, no start time | Validation error: "The default end time must be a date after default start time." (because `after:default_start_time` compares against a null value) |

#### TC-N08: Edit — Update to Duplicate Code

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Edit a shift, change its code to an already-existing code | Validation error: "The code has already been taken." |

#### TC-N09: Guest Access Redirect

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Log out | — |
| 2 | Navigate to `GET /timetable-foundation/shift/create` | Redirected to `/login` |

#### TC-N10: Missing viewAny Permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Log in as user without `viewAny` permission | — |
| 2 | Navigate to shifts tab | 403 Forbidden |

#### TC-N11: Missing create Permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Log in as user without `create` permission | — |
| 2 | Navigate to create form or POST store | 403 Forbidden |

#### TC-N12: Non-Existent Shift ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to `GET /timetable-foundation/shift/9999` | HTTP 404 |
| 2 | Navigate to edit for ID 9999 | HTTP 404 |
| 3 | POST to update with ID 9999 | HTTP 404 |

#### TC-N13: FK RESTRICT — Period Config Exists

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a Period Config record referencing a specific shift | — |
| 2 | Attempt to delete that shift via the UI | Delete fails; integrity constraint violation logged; user sees a 500 error (FK RESTRICT prevents deletion) |

#### TC-N14: FK RESTRICT — Timetable Type Exists

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a Timetable Type record referencing a specific shift | — |
| 2 | Attempt to delete that shift via the UI | Delete fails; integrity constraint violation logged; FK RESTRICT prevents deletion |

---

### 7.3 Dependency TC Steps

#### TC-D01: FK RESTRICT — Period Config Exists

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Identify a shift that has `tt_period_configs` records referencing it (or create a period config with this shift) | — |
| 2 | Attempt to delete this shift via the UI | Delete fails; integrity constraint violation logged; FK RESTRICT prevents deletion |

#### TC-D02: FK RESTRICT — Timetable Type Exists

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Identify a shift that has `tt_timetable_types` records referencing it | — |
| 2 | Attempt to delete this shift via the UI | Delete fails; integrity constraint violation logged; FK RESTRICT prevents deletion |

#### TC-D03: FK RESTRICT — Period Set Exists

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Identify a shift that has `tt_period_sets` records referencing it | — |
| 2 | Attempt to delete this shift via the UI | Delete fails; integrity constraint violation logged; FK RESTRICT prevents deletion |

#### TC-D04: Activity Logging on State Changes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a new shift (note: store() may not log explicitly) | No activity log entry for create (known gap — store() does not call activityLog()) |
| 2 | Edit and update the shift | Activity log entry created: action 'Updated', message 'Shift details updated' |
| 3 | Toggle status of the shift | Activity log entry created: action 'Toggled', message 'Shift status was updated.' |
| 4 | Soft delete the shift | Activity log entry created: action 'Trashed', message 'Shift was deactivated and moved to trash.' |
| 5 | Restore the shift | Activity log entry created: action 'Restored', message 'Shift was restored successfully.' |
| 6 | Force delete the shift | Activity log entry created: action 'Deleted', message 'Shift was permanently deleted.' |

#### TC-D05: Model — `$fillable` Matches DDL Columns

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `SchoolShift.php` `$fillable` array | Contains exactly: `code`, `name`, `description`, `default_start_time`, `default_end_time`, `ordinal`, `is_active` — matching all DDL columns (excluding id, timestamps, deleted_at) |
| 2 | Verify no extra column exists in `$fillable` | Every fillable column is a real column in `tt_shifts` |

#### TC-D06: Model — `$casts` for Boolean/Integer/Datetime

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `SchoolShift.php` `$casts` array | `is_active` → `boolean`, `ordinal` → `integer`, `default_start_time` → `datetime`, `default_end_time` → `datetime` |

#### TC-D07: Unique Code Constraint at DB Level

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Insert a duplicate code directly into `tt_shifts` via SQL: `INSERT INTO tt_shifts (code, name, ordinal) VALUES ('MORNING', 'Duplicate', 99)` | SQL error: `SQLSTATE[23000]: Integrity constraint violation` — duplicate entry for key `uq_shift_code` |

#### TC-D08: Unique Name Constraint at DB Level

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Insert a duplicate name directly into `tt_shifts` via SQL: `INSERT INTO tt_shifts (code, name, ordinal) VALUES ('DUP', 'Morning Shift', 98)` | SQL error: `SQLSTATE[23000]: Integrity constraint violation` — duplicate entry for key `uq_shift_name` |

#### TC-D09: Unique Ordinal Constraint at DB Level

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Insert a duplicate ordinal directly into `tt_shifts` via SQL: `INSERT INTO tt_shifts (code, name, ordinal) VALUES ('DUP2', 'Duplicate', 1)` | SQL error: `SQLSTATE[23000]: Integrity constraint violation` — duplicate entry for key `uq_shift_ordinal` |

---

