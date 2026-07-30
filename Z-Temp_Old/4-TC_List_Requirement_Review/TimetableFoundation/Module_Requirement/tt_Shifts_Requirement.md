# Shifts — Business Requirements

## What This Screen Does

The Shifts screen is a **simple CRUD master data screen** that defines the school's operational shifts — morning, afternoon, evening, or any custom shift the school runs. A shift represents a distinct block of time during which classes are conducted. Schools with multiple shifts (e.g., Morning shift for grades 3–12, Afternoon shift for pre-primary) use this screen to create and manage each shift separately.

Each shift carries optional default start and end times that serve as reference values throughout the timetable system. The shift's ordinal determines its display order, and a simple status toggle lets administrators deactivate shifts that are temporarily not in use.

The screen appears under **Timetable Configuration → Timetable Masters** tab group, specifically the **Shifts** tab (`tab=shifts`). It is purely administrative master data — no AJAX endpoints, no complex business logic.

## When This Screen Is Used

- **Initial system setup** — During the Timetable Foundation configuration phase, an administrator creates the school's operational shifts (e.g., Morning, Afternoon, Evening). A seeder may pre-populate common shifts.
- **Adding new shifts** — When the school introduces a new shift (e.g., an extra evening shift for adult education), the administrator creates a new shift record.
- **Modifying shift details** — If a shift's name, default timing, or ordinal needs adjustment, the administrator edits the shift record.
- **Deactivating a shift** — When a shift is discontinued, the administrator deactivates or soft-deletes it. Active shifts are available for selection in downstream screens (Period Config, Timetable Types, etc.).
- **Viewing shift details** — Administrators inspect individual shift records to see the full field set, timestamps, and related timetable types count.

## Default Data Load

The `SchoolShiftController@index` method authorises the user and redirects to the Timetable Masters page with `tab=shifts`. The actual data load occurs in `TimetableFoundationController@timetableMasters`, which queries:

```php
$shifts = SchoolShift::query()
    ->withCount('timetableTypes')
    ->orderBy('ordinal')
    ->get();
```

The result set is **not paginated** (master data, typically 3–10 rows). It includes:

| Filter | Input name | Default |
|--------|------------|---------|
| Search (name/code) | `s_search` | None (all) |
| Status (is_active) | `s_status` | `1` (active only) |

Columns rendered in the table: **# (ordinal)**, **Code**, **Name**, **Description**, **Default Start Time**, **Default End Time**, **Status** (toggle), **Action** (View, Edit, Trash).

## Key Fields at a Glance

**Identity Fields**

- **Code** — A unique machine-readable identifier (e.g., `MORNING`, `AFTERNOON`, `EVENING`). Max 20 characters. Used as a stable reference in downstream configuration screens and solver logic.
- **Name** — Human-readable display name (e.g., `Morning Shift`, `Afternoon Shift`). Max 100 characters.
- **Description** — Optional free-text explanation of the shift's purpose. Max 255 characters.

**Timing Fields**

- **Default Start Time** (`default_start_time`) — Optional time value (H:i format) representing the shift's scheduled start. Stored as TIME in the database. Used as a reference default when no explicit timing is set in the Period Config.
- **Default End Time** (`default_end_time`) — Optional time value (H:i format) representing the shift's scheduled end. Must be after `default_start_time`. Also stored as TIME.

**Ordering and Status**

- **Ordinal** — Unsigned tiny integer, controls sort order in list views (ascending). Must be unique across all shifts.
- **Is Active** (`is_active`) — Boolean, default `true`. Soft toggle for enabling/disabling a shift without deleting it.

**Timestamps**
- `created_at` / `updated_at` — Standard Laravel timestamps.
- `deleted_at` — Nullable; populated by `SoftDeletes` trait on soft delete.

## Business Rules and Conditions

**BR-001 — Code Uniqueness**
The `code` column has a unique key (`uq_shift_code`). The validation rule `Rule::unique('tt_shifts', 'code')->whereNull('deleted_at')` enforces uniqueness at the application layer, ignoring soft-deleted records. On update, the rule uses `->ignore($shift->id)` so the shift's own code does not trigger a false conflict.

**BR-002 — Name Uniqueness**
The `name` column has a unique key (`uq_shift_name`). Same enforcement pattern as code.

**BR-003 — Ordinal Uniqueness**
The `ordinal` column has a unique key (`uq_shift_ordinal`). Same enforcement pattern as code and name. No two shifts can share the same ordinal value.

**BR-004 — Default End Time Must Be After Default Start Time**
If both `default_start_time` and `default_end_time` are supplied, the system validates `after:default_start_time` to ensure the end time is chronologically after the start time.

**BR-005 — Deactivation Cascade on Delete**
When a shift is soft-deleted via `destroy()`, the controller first sets `is_active = false`, then calls `$shift->delete()`. This ensures the shift is immediately excluded from active queries even though the SoftDeletes trait normally hides it only from non-trashed queries.

**BR-006 — Reactivation on Restore**
When a trashed shift is restored via `restore()`, the controller automatically sets `is_active = true`. The shift becomes immediately available for use.

**BR-007 — Activity Logging on All Mutations**
Every state-changing operation (create, update, destroy, restore, forceDelete, toggleStatus) invokes the `activityLog()` helper to record an audit trail. The `store()` method does not explicitly log via `activityLog()` — this is a potential gap versus other controllers in the module.

**BR-008 — Referential Dependency from Timetable Types and Period Configs**
Downstream tables (`tt_timetable_types`, `tt_period_configs`, `tt_period_sets`) reference `tt_shifts.id` via foreign keys with `ON DELETE RESTRICT`. A shift cannot be deleted if it is referenced by any of these child tables.

## Workflow Steps

**Creating a New Shift**

1. User navigates to **Timetable Foundation → Timetable Masters → Shifts** tab.
2. Clicks **"Add New"** → `SchoolShiftController@create`.
3. `Gate::authorize('timetable-foundation.shift.create')` — 403 if unauthorised.
4. Form rendered: Code (`text`, required, max 20), Name (`text`, required, max 100), Description (`textarea`, optional), Default Start Time (`time`, optional), Default End Time (`time`, optional), Ordinal (`number`, min 1), is_active (`checkbox`, default checked).
5. On submit → `POST /shift` → `store()`.
6. Validation runs: code unique, name unique, ordinal unique, default_end_time after default_start_time if both supplied.
7. `SchoolShift::create($validated)` → new row inserted.
8. Redirect to `timetable-foundation.menu.timetableMasters?tab=shifts` with success flash.

**Editing an Existing Shift**

1. User clicks **Edit** on a shift row → `SchoolShiftController@edit($id)`.
2. `Gate::authorize('timetable-foundation.shift.update')`.
3. Form pre-filled with existing values.
4. On submit → `PUT /shift/{id}` → `update()`.
5. Same validation as create, with unique rules ignoring current ID.
6. `$shift->update($validated)` → row updated.
7. Activity logged: `'Shift details updated'`.
8. Redirect with success flash.

**Soft-Deleting a Shift**

1. User clicks **Trash** → `destroy($id)`.
2. `Gate::authorize('timetable-foundation.shift.delete')`.
3. `is_active = false` → `save()` → `delete()` (SoftDeletes).
4. Activity logged: `'Shift was deactivated and moved to trash.'`.
5. Redirect with success flash.

**Restoring a Trashed Shift**

1. Navigate to **Trash** view → `trashedShift()` lists only-trashed records.
2. Click **Restore** → `restore($id)`.
3. `Gate::authorize('timetable-foundation.shift.restore')`.
4. `$shift->restore()` → `is_active = true` → `save()`.
5. Activity logged: `'Shift was restored successfully.'`.
6. Redirect to trash view with success flash.

**Toggling Status**

1. User toggles the switch in the list table → `POST /shift/{shift}/toggle-status` → `toggleStatus()`.
2. Validates `is_active` boolean.
3. Saves new status.
4. Returns JSON `{ success: true, is_active, message }`.

## Example Scenario

Mr. Verma, the Timetable Manager at Sunshine Academy, is setting up shifts for the new academic year:

1. He navigates to **Timetable Masters → Shifts** tab. The screen shows no shifts yet (fresh tenant).

2. He clicks **Add New** and creates the Morning Shift:
   - Code: `MORNING`
   - Name: `Morning Shift`
   - Description: `Standard morning shift for grades 3-12`
   - Default Start Time: `07:30`
   - Default End Time: `14:30`
   - Ordinal: `1`

3. He creates the Afternoon Shift for pre-primary:
   - Code: `AFTERNOON`
   - Name: `Afternoon Shift`
   - Description: `Afternoon shift for pre-primary classes`
   - Default Start Time: `12:00`
   - Default End Time: `17:00`
   - Ordinal: `2`

4. Both shifts appear in the list ordered by ordinal, active by default. The Morning Shift shows its timetable type count as `0` since no timetable types have been configured yet.

5. Later, the school discontinues the Afternoon Shift. Mr. Verma soft-deletes it. The shift is deactivated, moved to trash, and can be restored if needed.

6. He tries to delete the Morning Shift but cannot because it is referenced by a Period Config and a Timetable Type. The FK RESTRICT constraint prevents deletion.

## Related Screens

- **Period Config** (Timetable Foundation) — `tt_period_configs.shift_id` FK references `tt_shifts.id` with `ON DELETE RESTRICT`. Period configs define the school's fixed daily timeslot grid per shift.
- **Timetable Types** (Timetable Foundation) — `tt_timetable_types.shift_id` FK references `tt_shifts.id` with `ON DELETE RESTRICT`. Each timetable type belongs to a shift.
- **Period Sets** (Timetable Foundation) — `tt_period_sets.shift_id` FK references `tt_shifts.id` with `ON DELETE RESTRICT`. Period sets define which period range a class group uses within a shift.

## Requirements

- `SchoolShiftController` provides full CRUD with methods `index()` (redirects to masters page), `create()`, `store()`, `show()`, `edit()`, `update()`, `destroy()`, `restore()`, `forceDelete()`, `trashedShift()`, and `toggleStatus()` — implements `SoftDeletes` on the `SchoolShift` model. The `destroy()` method sets `is_active = false` via `update()` before calling `delete()` and logs an activity. The `restore()` method restores and then sets `is_active = true` via `update()`. The `store()` method does NOT explicitly log activity via `activityLog()` (diverging from the pattern in `update()`, `destroy()`, `restore()`, `forceDelete()`, and `toggleStatus()`). Gates: `timetable-foundation.shift.*`. Policy: No dedicated policy file — gate checks use implicit model/policy resolution. Routes: resource `shift` (`Route::resource('shift', SchoolShiftController::class)`) plus `/shift/trash/view`, `/{id}/restore`, `/{id}/force-delete`, `/{shift}/toggle-status`.
- Validation is inline in the controller (no Form Request): `code` unique on `tt_shifts` with `whereNull('deleted_at')`, `name` unique with `whereNull('deleted_at')`, `ordinal` unique with `whereNull('deleted_at')`, `default_start_time` nullable `date_format:H:i`, `default_end_time` nullable `date_format:H:i|after:default_start_time`, checkboxes normalized via `$request->boolean()`.
- The `SchoolShift` model uses `SoftDeletes`, extends `BaseModel`, and defines `$casts` for `is_active` (boolean), `ordinal` (integer), `default_start_time` (datetime), `default_end_time` (datetime). The model defines a `timetableTypes()` hasMany relationship.
- Activity logging is performed on update, destroy, restore, force-delete, and toggle-status operations. The `store()` method does not explicitly log an activity.

## Who Can Access

| Gate/Permission | Methods | Notes |
|---|---|---|
| `timetable-foundation.shift.viewAny` | `SchoolShiftController@index` | Loads the shifts tab |
| `timetable-foundation.shift.create` | `SchoolShiftController@create`, `store` | Create and store shift |
| `timetable-foundation.shift.view` | `SchoolShiftController@show` | View single record |
| `timetable-foundation.shift.update` | `SchoolShiftController@edit`, `update`, `toggleStatus` | Edit, update, toggle status |
| `timetable-foundation.shift.delete` | `SchoolShiftController@destroy` | Soft-delete (deactivate + trash) |
| `timetable-foundation.shift.restore` | `SchoolShiftController@restore`, `trashedShift` | Restore and view trash |
| `timetable-foundation.shift.forceDelete` | `SchoolShiftController@forceDelete` | Permanent delete |

Global page access is gated by `timetable-foundation.viewAny` on `TimetableFoundationController@timetableMasters`.

No dedicated policy file for `SchoolShift` — gate checks use Laravel's implicit model policy resolution.

## Logic Flow

### Store / Update Flow

```
User submits form
        │
        ▼
Gate::authorize('create' | 'update')
        │
        ▼ (authorised)
Validate request:
  • code: required|string|max:20|unique:tt_shifts,code (ignore current on update, whereNull deleted_at)
  • name: required|string|max:100|unique:tt_shifts,name (ignore current, whereNull deleted_at)
  • description: nullable|string|max:255
  • default_start_time: nullable|date_format:H:i
  • default_end_time: nullable|date_format:H:i|after:default_start_time
  • ordinal: required|integer|min:1|unique:tt_shifts,ordinal (ignore current, whereNull deleted_at)
  • is_active: nullable (normalized via boolean())
        │
        ▼ (pass)
Normalize is_active: $request->boolean('is_active')
        │
        ▼
Persist: SchoolShift::create($validated) / ->update($validated)
        │
        ▼
Redirect → timetable-foundation.menu.timetableMasters?tab=shifts
```

### Delete Flow

```
User clicks Trash
        │
        ▼
Gate::authorize('delete')
        │
        ▼ (authorised)
Find: SchoolShift::findOrFail($id)
        │
        ▼
is_active = false → save() → delete()
        │
        ▼
activityLog('Trashed')
        │
        ▼
Redirect → success
```

### Toggle Status Flow

```
User flips toggle switch
        │
        ▼
POST /shift/{shift}/toggle-status
        │
        ▼
Gate::authorize('update')
        │
        ▼ (authorised)
Validate: is_active required|boolean
        │
        ▼
$shift->update(['is_active' => (bool) $validated['is_active']])
        │
        ▼
activityLog('Toggled')
        │
        ▼
JSON { success: true, is_active, message }
```

## Validate Before Save

The following validation rules are applied in both `store()` and `update()`:

| Field | Rule(s) | Error Message |
|---|---|---|
| `code` | `required`, `string`, `max:20`, `unique:tt_shifts,code` with `whereNull('deleted_at')` | Laravel default |
| `name` | `required`, `string`, `max:100`, `unique:tt_shifts,name` with `whereNull('deleted_at')` | Laravel default |
| `description` | `nullable`, `string`, `max:255` | Laravel default |
| `default_start_time` | `nullable`, `date_format:H:i` | Laravel default |
| `default_end_time` | `nullable`, `date_format:H:i`, `after:default_start_time` | Laravel default |
| `ordinal` | `required`, `integer`, `min:1`, `unique:tt_shifts,ordinal` with `whereNull('deleted_at')` | Laravel default |
| `is_active` | `nullable` | Normalized via `$request->boolean()` |

On update, the `code`, `name`, and `ordinal` unique rules include `->ignore($shift->id)->whereNull('deleted_at')` so the shift's own values do not trigger false conflicts.

## Error Handling and Validation Messages

| Scenario | Message | Type |
|---|---|---|
| Validation failure (any field) | Laravel default `.validation.*` strings | Validation rule (302 redirect) |
| Not authorised (view list) | `AuthorizationException` → 403 page | Gate |
| Not authorised (create) | 403 Forbidden | Gate |
| Not authorised (update/toggle) | 403 Forbidden | Gate |
| Not authorised (delete) | 403 Forbidden | Gate |
| Not authorised (restore) | 403 Forbidden | Gate |
| Model not found | `ModelNotFoundException` → 404 page | Controller `findOrFail()` |
| FK constraint violation (delete blocked) | `SQLSTATE[23000]` integrity constraint violation → 500 error page | Database |
| Toggle status save failure | JSON `{ success: false, is_active, message: flash('status_switch_failed.shift') }` with 422 | Controller check |

## Success Scenarios

**SC-001 — Create Morning Shift**
Mr. Verma creates a shift with Code = `MORNING`, Name = `Morning Shift`, Default Start Time = `07:30`, Default End Time = `14:30`, Ordinal = `1`. The shift is saved with `is_active = true`. He is redirected to the Shifts tab with a green success message. The shift appears first in the ordered list.

**SC-002 — Edit Shift Name**
Mr. Verma changes the name of the `AFTERNOON` shift to `Pre-Primary Afternoon`. The update succeeds, activity is logged with "Shift details updated", and the table refreshes with the new name.

**SC-003 — Toggle Status via AJAX**
Mr. Verma clicks the status toggle next to `AFTERNOON`. A POST request is sent; the server flips `is_active` from `true` to `false` and returns `{ success: true, is_active: false }`. The toggle UI updates without a page reload.

**SC-004 — Soft Delete and Restore Shift**
Mr. Verma soft-deletes the `AFTERNOON` shift. It is deactivated (`is_active = false`), soft-deleted, and disappears from the active list. He navigates to Trash view and restores it. The shift reappears with `is_active = true` and is available for use.

**SC-005 — Force Delete a Shift**
After soft-deleting a shift that has no FK references, Mr. Verma navigates to the Trash view and force-deletes it. The record is permanently removed from the database.

## Failure Scenarios

**FC-001 — Duplicate Shift Code**
Mr. Verma tries to create a shift with code `MORNING` which already exists. The `unique` validation rule returns: "The code has already been taken." The form is re-displayed with the error.

**FC-002 — End Time Before Start Time**
Mr. Verma creates a shift with Default Start Time `14:00` and Default End Time `12:00`. The `after:default_start_time` rule returns a validation error: "The default end time must be a date after default start time."

**FC-003 — Delete Shift Referenced by Period Config**
Mr. Verma tries to delete the `MORNING` shift, but a Period Config record references it. The database FK RESTRICT constraint throws an integrity constraint violation, resulting in a 500 error page.

**FC-004 — Duplicate Ordinal**
Mr. Verma creates two shifts both with ordinal `1`. The second create attempt fails with a `unique` validation error: "The ordinal has already been taken."

**FC-005 — Unauthorised Access (No Permission)**
A teacher without the `timetable-foundation.shift.*` permission tries to access the Shifts tab. `Gate::authorize()` throws an `AuthorizationException`, resulting in a 403 HTTP response.

## Dependencies module and tables

| Dependency | Type | Details |
|---|---|---|
| `tt_shifts` | Primary table | Master data table; `tinyIncrements('id')` — max 255 rows. All CRUD operations target this table. |
| `tt_period_configs` | Child (FK) | `tt_period_configs.shift_id` FK references `tt_shifts(id)` via `fk_pc_shift` with `ON DELETE RESTRICT`. |
| `tt_timetable_types` | Child (FK) | `tt_timetable_types.shift_id` FK references `tt_shifts(id)` via `fk_tttype_shift` with `ON DELETE RESTRICT`. |
| `tt_period_sets` | Child (FK) | `tt_period_sets.shift_id` FK references `tt_shifts(id)` via `fk_periodset_shift` with `ON DELETE RESTRICT`. |
| `Modules\TimetableFoundation\Models\SchoolShift` | Eloquent model | Uses `SoftDeletes`; extends `BaseModel`. |
| `TimetableFoundationServiceProvider` | Service provider | Registers policies. |
| `activityLog()` helper | Service dependency | Called on update, destroy, restore, forceDelete, toggleStatus. |

**Table:** `tt_shifts`

| Column | Type | Details |
|---|---|---|
| `id` | TINYINT UNSIGNED | Primary key, auto-increment (max 255 rows) |
| `code` | VARCHAR(20) | NOT NULL. Unique (`uq_shift_code`). |
| `name` | VARCHAR(100) | NOT NULL. Unique (`uq_shift_name`). |
| `description` | VARCHAR(255) | DEFAULT NULL. |
| `default_start_time` | TIME | DEFAULT NULL. |
| `default_end_time` | TIME | DEFAULT NULL. |
| `ordinal` | TINYINT UNSIGNED | NOT NULL. Unique (`uq_shift_ordinal`). |
| `is_active` | TINYINT(1) | NOT NULL, DEFAULT 1. |
| `created_at` | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP. |
| `updated_at` | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP. |
| `deleted_at` | TIMESTAMP | NULL DEFAULT NULL. |

**Unique Keys:**
- `uq_shift_code` — on `code`
- `uq_shift_name` — on `name`
- `uq_shift_ordinal` — on `ordinal`
