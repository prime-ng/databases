# Day Types — Business Requirements

## What This Screen Does

The Day Types screen is a **simple CRUD master data screen** that defines the classifications a school can apply to any calendar date — Working Day, Holiday, Exam, PTM Day, Sports Day, Annual Day, and any custom types the school needs. Each day type carries two business flags that drive system-wide behaviour: `is_working_day` (whether the day counts as a school day) and `reduced_periods` (whether fewer periods are scheduled on this day type).

Day types are the building blocks of the Working Days calendar. When the system initializes or modifies the school calendar, it assigns one or more day types to each date. The mutual-exclusion rules that govern which combinations of day types can coexist on a single date are enforced by the `WorkingDayController`, not by this screen — this screen purely manages the type definitions themselves.

The screen appears under **Timetable Configuration → Timetable Masters** tab group, specifically the **Day Types** tab (`tab=day-types`). It is purely administrative master data with no AJAX endpoints.

## When This Screen Is Used

- **Initial system setup** — During Timetable Foundation configuration, an administrator verifies or creates the school's day type categories. A seeder may pre-populate standard types: Study Day, Holiday, Exam, PTM Day, Sports Day, Annual Day.
- **Adding custom day types** — If the school uses a specialised type (e.g., "Cultural Event Day", "Foundation Day"), the administrator creates a new day type with appropriate flags.
- **Modifying day type details** — If a day type's name, working-day flag, reduced-periods flag, or ordinal needs adjustment, the administrator edits the record.
- **Deactivating obsolete types** — When a day type is no longer needed, the administrator deactivates or soft-deletes it.
- **Inspecting day type usage** — Administrators view the details of a day type to see its flags and timestamps.

## Default Data Load

The `DayTypeController@index` method authorises the user and redirects to the Timetable Masters page with `tab=day-types`. The actual data load occurs in `TimetableFoundationController@timetableMasters`, which queries:

```php
$dayTypes = DayType::query()
    ->orderBy('ordinal')
    ->get();
```

The result set is **not paginated** (master data, typically 6–15 rows). It includes:

| Filter | Input name | Default |
|--------|------------|---------|
| Search (name/code) | `dt_search` | None (all) |
| Status (is_active) | `dt_status` | `1` (active only) |

Columns rendered in the table: **# (ordinal)**, **Code**, **Name**, **Description**, **Working Day** (Yes/No badge), **Reduced Periods** (Yes/No badge), **Status** (toggle), **Action** (View, Edit, Trash).

## Key Fields at a Glance

**Identity Fields**

- **Code** — A unique uppercase code (e.g., `STUDY`, `HOLIDAY`, `EXAM`, `PTM_DAY`, `SPORTS_DAY`, `ANNUAL_DAY`). The controller automatically uppercases the code via `strtoupper()` before saving. Max 20 characters. Used as a stable reference in the Working Day initialization logic (which resolves the Holiday type by checking codes 'H', 'HD', then fallback).
- **Name** — Human-readable display name (e.g., "Study Day", "Holiday", "Exam"). Max 100 characters.
- **Description** — Optional free-text explanation of the day type's purpose. Max 255 characters.

**Behavioural Flags**

- **Is Working Day** (`is_working_day`) — Boolean, default `true`. When true, the day type represents an instructional day (e.g., Study Day, PTM Day). When false, it represents a non-working day (e.g., Holiday, Exam, Sports Day). This flag drives the `is_school_day` computation on Working Day rows — if at least one assigned day type on a date has `is_working_day = true`, the date is a school day.
- **Reduced Periods** (`reduced_periods`) — Boolean, default `false`. When true, the school operates with fewer periods on days of this type (e.g., Exam, PTM Day, Sports Day). The timetable solver uses this flag to adjust period counts.

**Ordering and Status**

- **Ordinal** — Unsigned tiny integer, controls sort order in list views (ascending). Must be unique across all day types.
- **Is Active** (`is_active`) — Boolean, default `true`. Soft toggle for enabling/disabling a day type without deleting it.

**Timestamps**
- `created_at` / `updated_at` — Standard Laravel timestamps.
- `deleted_at` — Nullable; populated by `SoftDeletes` trait on soft delete.

## Business Rules and Conditions

**BR-001 — Code Uniqueness (Across Non-Deleted Records)**
The `code` column has a unique key (`uq_daytype_code`). The validation rule `Rule::unique('tt_day_types', 'code')->whereNull('deleted_at')` enforces uniqueness, ignoring soft-deleted records. On update, the rule uses `->ignore($dayType->id)` so the day type's own code does not trigger a false conflict.

**BR-002 — Name Uniqueness**
The `name` column has a unique key (`uq_daytype_name`). Same enforcement pattern as code.

**BR-003 — Ordinal Uniqueness**
The `ordinal` column has a unique key (`uq_daytype_ordinal`). Same enforcement pattern as code and name.

**BR-004 — Code Auto-Uppercase**
The controller normalises the `code` field via `strtoupper()` before creating or updating a record. Lowercase or mixed-case input is automatically capitalised.

**BR-005 — Deactivation Cascade on Delete**
When a day type is soft-deleted via `destroy()`, the controller first sets `is_active = false`, then calls `$dayType->delete()`. This ensures the day type is immediately excluded from active queries.

**BR-006 — Reactivation on Restore**
When a trashed day type is restored via `restore()`, the controller automatically sets `is_active = true`. The day type becomes immediately available for use.

**BR-007 — Activity Logging on All Mutations**
Every state-changing operation (create, update, destroy, restore, forceDelete, toggleStatus) invokes the `activityLog()` helper to record an audit trail.

**BR-008 — Referential Dependency from Working Days**
The `tt_working_days` table references `tt_day_types.id` via four FK columns (`day_type1_id`, `day_type2_id`, `day_type3_id`, `day_type4_id`) each with `ON DELETE RESTRICT`. A day type cannot be deleted if it is referenced by any working day row.

## Workflow Steps

**Creating a New Day Type**

1. User navigates to **Timetable Foundation → Timetable Masters → Day Types** tab.
2. Clicks **"Add New"** → `DayTypeController@create`.
3. `Gate::authorize('timetable-foundation.day-type.create')` — 403 if unauthorised.
4. Form rendered: Code (`text`, required, max 20), Name (`text`, required, max 100), Description (`textarea`, optional), Is Working Day (`checkbox`, default checked), Reduced Periods (`checkbox`), Ordinal (`number`, min 1), is_active (`checkbox`, default checked).
5. On submit → `POST /day-type` → `store()`.
6. Validation runs: code unique, name unique, ordinal unique.
7. Code uppercased via `strtoupper()`.
8. Checkbox fields normalised: `is_working_day` via `$request->boolean()`, `reduced_periods` via `$request->boolean()`, `is_active` via `$request->boolean()`.
9. `DayType::create(...)` → new row inserted.
10. Activity logged: `'Day type was created successfully.'`.
11. Redirect to `timetable-foundation.menu.timetableMasters?tab=day-types` with success flash.

**Editing an Existing Day Type**

1. User clicks **Edit** on a day type row → `DayTypeController@edit($id)`.
2. `Gate::authorize('timetable-foundation.day-type.update')`.
3. Form pre-filled with existing values.
4. On submit → `PUT /day-type/{id}` → `update()`.
5. Same validation as create, with unique rules ignoring current ID.
6. Code uppercased via `strtoupper()`.
7. Checkbox fields normalised via `$request->boolean()`.
8. `$dayType->update(...)` → row updated.
9. Activity logged: `'Day type was updated successfully.'`.
10. Redirect with success flash.

**Soft-Deleting a Day Type**

1. Click **Trash** → `destroy($id)`.
2. `Gate::authorize('timetable-foundation.day-type.delete')`.
3. `is_active = false` → `save()` → `delete()` (SoftDeletes).
4. Activity logged: `'Day type was deactivated and moved to trash.'`.
5. Redirect with success flash.

**Restoring a Trashed Day Type**

1. Navigate to **Trash** view → `trashedDayType()` lists only-trashed records.
2. Click **Restore** → `restore($id)`.
3. `Gate::authorize('timetable-foundation.day-type.restore')`.
4. `$dayType->restore()` → `is_active = true` → `save()`.
5. Activity logged: `'Day type was restored successfully.'`.
6. Redirect to trash view with success flash.

**Toggling Status**

1. User toggles the switch in the list table → `POST /day-type/{dayType}/toggle-status` → `toggleStatus()`.
2. Validates `is_active` required boolean.
3. Saves new status.
4. Returns JSON `{ success: true, is_active, message }` on success, or `{ success: false, ... }` with 422 on failure.

## Example Scenario

Mrs. Sharma, the Timetable Manager at Sunshine Academy, is reviewing day types:

1. She navigates to **Timetable Masters → Day Types** tab. Six pre-seeded types are visible: Study Day (ordinal 1, `is_working_day=true`, `reduced_periods=false`), Holiday (ordinal 2, `is_working_day=false`, `reduced_periods=false`), Exam (ordinal 3, `is_working_day=false`, `reduced_periods=true`), PTM Day (ordinal 4, `is_working_day=true`, `reduced_periods=true`), Sports Day (ordinal 5, `is_working_day=false`, `reduced_periods=true`), and Annual Day (ordinal 6, `is_working_day=false`, `reduced_periods=false`).

2. The school is introducing a "Cultural Fest" day. Mrs. Sharma clicks **Add New** and creates:
   - Code: `CULTURAL_FEST` (auto-uppercased)
   - Name: `Cultural Fest`
   - Description: `Annual cultural festival day`
   - Is Working Day: No
   - Reduced Periods: Yes
   - Ordinal: `7`

3. Later, the school discontinues Sports Day as a separate category. Mrs. Sharma soft-deletes the Sports Day type. It is deactivated, moved to trash, and can be restored if needed.

4. Mrs. Sharma tries to delete the Study Day type but cannot because it is referenced by Working Day records. The FK RESTRICT constraint prevents deletion.

## Related Screens

- **Working Days** (Timetable Foundation) — `tt_working_days.day_type{1-4}_id` FKs reference `tt_day_types.id`. This is where day types are actually assigned to calendar dates.
- **School Days** (Timetable Foundation) — The weekly template that works alongside day types to determine the school calendar.
- **Class Working Days** (Timetable Foundation) — Class-specific overrides that can override the school-wide day type assignments.

## Requirements

- `DayTypeController` provides full CRUD with methods `index()` (redirects to masters page), `create()`, `store()`, `show()`, `edit()`, `update()`, `destroy()`, `restore()`, `forceDelete()`, `trashedDayType()`, and `toggleStatus()` — implements `SoftDeletes` on the `DayType` model. The `destroy()` method sets `is_active = false` via direct property assignment before calling `delete()` and logs an activity. The `restore()` method restores and then sets `is_active = true` via direct property assignment. Gates: `timetable-foundation.day-type.*`. Policy: No dedicated policy file — gate checks use implicit model/policy resolution. Routes: resource `day-type` (`Route::resource('day-type', DayTypeController::class)`) plus `/day-type/trash/view`, `/{id}/restore`, `/{id}/force-delete`, `/{dayType}/toggle-status`.
- Validation is inline in the controller (no Form Request): `code` unique with `whereNull('deleted_at')`, `name` unique with `whereNull('deleted_at')`, `ordinal` unique with `whereNull('deleted_at')`, `description` nullable|string|max:255, `is_working_day` nullable|boolean (update only), `reduced_periods` nullable|boolean (update only), `is_active` required (store) / nullable (update).
- Code is auto-uppercased via `strtoupper()` before both create and update.
- Checkbox fields (`is_working_day`, `reduced_periods`, `is_active`) are normalised via `$request->boolean()`.
- The `DayType` model uses `SoftDeletes`, extends `BaseModel`, and defines `$casts` for `is_working_day` (boolean), `reduced_periods` (boolean), `is_active` (boolean), `ordinal` (integer), `created_at` (datetime), `updated_at` (datetime), `deleted_at` (datetime). It defines `$attributes` defaults for `is_working_day` (true), `reduced_periods` (false), `is_active` (true), `ordinal` (1). The model defines `$fillable` including `created_by`.
- Activity logging is performed on all state-changing operations.

## Who Can Access

| Gate/Permission | Methods | Notes |
|---|---|---|
| `timetable-foundation.day-type.viewAny` | `DayTypeController@index` | Loads the day-types tab |
| `timetable-foundation.day-type.create` | `DayTypeController@create`, `store` | Create and store day type |
| `timetable-foundation.day-type.view` | `DayTypeController@show` | View single record |
| `timetable-foundation.day-type.update` | `DayTypeController@edit`, `update`, `toggleStatus` | Edit, update, toggle status |
| `timetable-foundation.day-type.delete` | `DayTypeController@destroy` | Soft-delete (deactivate + trash) |
| `timetable-foundation.day-type.restore` | `DayTypeController@restore`, `trashedDayType` | Restore and view trash |
| `timetable-foundation.day-type.forceDelete` | `DayTypeController@forceDelete` | Permanent delete |

Global page access is gated by `timetable-foundation.viewAny` on `TimetableFoundationController@timetableMasters`.

No dedicated policy file for `DayType` — gate checks use Laravel's implicit model policy resolution.

## Logic Flow

### Store Flow

```
User submits create form
        │
        ▼
Gate::authorize('timetable-foundation.day-type.create')
        │
        ▼ (authorised)
Validate request:
  • code: required|string|max:20|unique:tt_day_types (whereNull deleted_at)
  • name: required|string|max:100|unique:tt_day_types (whereNull deleted_at)
  • description: nullable|string|max:255
  • ordinal: required|integer|min:1|unique:tt_day_types (whereNull deleted_at)
  • is_active: required
        │
        ▼ (pass)
Normalize:
  • code = strtoupper(code)
  • is_working_day = $request->boolean('is_working_day')
  • reduced_periods = $request->boolean('reduced_periods')
  • is_active = $request->boolean('is_active')
        │
        ▼
Persist: DayType::create([...])
        │
        ▼
activityLog('Created')
        │
        ▼
Redirect → timetable-foundation.menu.timetableMasters?tab=day-types
```

### Update Flow

```
User submits edit form
        │
        ▼
Gate::authorize('timetable-foundation.day-type.update')
        │
        ▼ (authorised)
Validate request (unique rules ignore current ID):
  • code: required|string|max:20|unique:tt_day_types (ignore current, whereNull deleted_at)
  • name: required|string|max:100|unique:tt_day_types (ignore current, whereNull deleted_at)
  • ordinal: required|integer|min:1|unique:tt_day_types (ignore current, whereNull deleted_at)
  • is_working_day: nullable|boolean
  • reduced_periods: nullable|boolean
  • is_active: nullable
        │
        ▼ (pass)
Normalize: code = strtoupper(code), booleans via $request->boolean()
        │
        ▼
$dayType->update([...])
        │
        ▼
activityLog('Updated')
        │
        ▼
Redirect → timetable-foundation.menu.timetableMasters?tab=day-types
```

### Delete Flow

```
User clicks Trash
        │
        ▼
Gate::authorize('timetable-foundation.day-type.delete')
        │
        ▼ (authorised)
$dayType = DayType::findOrFail($id)
        │
        ▼
$dayType->is_active = false → save() → delete()
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
POST /day-type/{dayType}/toggle-status
        │
        ▼
Gate::authorize('timetable-foundation.day-type.update')
        │
        ▼ (authorised)
Validate: is_active required|boolean
        │
        ▼
$dayType->is_active = (bool) $request->input('is_active')
        │
        ▼
if save() succeeds → JSON { success: true, is_active, message }
else → JSON { success: false, is_active, message } with 422
```

## Validate Before Save

**Store (DayTypeController — inline validation)**

| Field | Rule(s) | Error Message |
|---|---|---|
| `code` | `required`, `string`, `max:20`, `unique:tt_day_types,code` with `whereNull('deleted_at')` | Laravel default |
| `name` | `required`, `string`, `max:100`, `unique:tt_day_types,name` with `whereNull('deleted_at')` | Laravel default |
| `description` | `nullable`, `string`, `max:255` | Laravel default |
| `ordinal` | `required`, `integer`, `min:1`, `unique:tt_day_types,ordinal` with `whereNull('deleted_at')` | Laravel default |
| `is_active` | `required` | Laravel default |

**Controller-level (store):**
- `code` auto-uppercased via `strtoupper()`
- `is_working_day` normalized via `$request->boolean()` (uses checkbox default false)
- `reduced_periods` normalized via `$request->boolean()` (uses checkbox default false)
- `is_active` normalized via `$request->boolean()` (uses checkbox default false)

**Update (DayTypeController — inline validation)**

| Field | Rule(s) | Error Message |
|---|---|---|
| `code` | `required`, `string`, `max:20`, `unique:tt_day_types,code` with `->ignore($dayType->id)->whereNull('deleted_at')` | Laravel default |
| `name` | `required`, `string`, `max:100`, `unique:tt_day_types,name` with `->ignore($dayType->id)->whereNull('deleted_at')` | Laravel default |
| `description` | `nullable`, `string`, `max:255` | Laravel default |
| `ordinal` | `required`, `integer`, `min:1`, `unique:tt_day_types,ordinal` with `->ignore($dayType->id)->whereNull('deleted_at')` | Laravel default |
| `is_working_day` | `nullable`, `boolean` | Laravel default |
| `reduced_periods` | `nullable`, `boolean` | Laravel default |
| `is_active` | `nullable` | Normalized via `$request->boolean()` |

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
| Toggle status save failure | JSON `{ success: false, is_active, message: flash('status_switch_failed.day_type') }` with 422 | Controller check |

## Success Scenarios

**SC-001 — Create a New Day Type**
Mrs. Sharma creates a day type with Code = `CULTURAL_FEST` (entered as `cultural_fest`), Name = `Cultural Fest`, Description = `Annual cultural festival day`, Is Working Day = unchecked, Reduced Periods = checked, Ordinal = `7`. The code is auto-uppercased to `CULTURAL_FEST`. The type is saved with `is_working_day = false`, `reduced_periods = true`, and `is_active = true`. She is redirected to the Day Types tab with a green success message.

**SC-002 — Edit a Day Type Name**
Mrs. Sharma changes the name of `SPORTS_DAY` to `Annual Sports Day`. The update succeeds, activity is logged with "Day type was updated successfully.", and the table refreshes with the new name.

**SC-003 — Soft Delete and Restore a Day Type**
Mrs. Sharma soft-deletes the `ANNUAL_DAY` day type. It is deactivated (`is_active = false`), soft-deleted, and disappears from the active list. She navigates to Trash view and restores it. The day type reappears with `is_active = true` and is available for use.

**SC-004 — Toggle Status via AJAX**
Mrs. Sharma clicks the status toggle next to `EXAM`. A POST request is sent; the server flips `is_active` from `true` to `false` and returns `{ success: true, is_active: false }`. The toggle UI updates without a page reload.

## Failure Scenarios

**FC-001 — Duplicate Day Type Code**
Mrs. Sharma tries to create a day type with code `HOLIDAY` which already exists. The `unique` validation rule returns: "The code has already been taken."

**FC-002 — Duplicate Name**
Mrs. Sharma creates a day type with name `Exam` but `Exam` already exists. The `unique` validation rule returns: "The name has already been taken."

**FC-003 — Duplicate Ordinal**
Mrs. Sharma creates a day type with ordinal `2` but ordinal `2` already exists (Holiday). The `unique` validation rule returns: "The ordinal has already been taken."

**FC-004 — Delete Day Type Referenced by Working Days**
Mrs. Sharma tries to delete the `STUDY` day type, but it is referenced by Working Day records. The database FK RESTRICT constraint throws an integrity constraint violation, resulting in a 500 error page.

**FC-005 — Code Auto-Uppercase Verification**
Mrs. Sharma enters code `exam` (lowercase). The system auto-uppercases it to `EXAM`. This is transparent to the user — the saved code is always uppercase.

## Dependencies module and tables

| Dependency | Type | Details |
|---|---|---|
| `tt_day_types` | Primary table | Master data table; `tinyIncrements('id')` — max 255 rows. All CRUD operations target this table. |
| `tt_working_days` | Child (FK) | Four FK columns (`day_type1_id`, `day_type2_id`, `day_type3_id`, `day_type4_id`) each reference `tt_day_types(id)` with `ON DELETE RESTRICT`. |
| `Modules\TimetableFoundation\Models\DayType` | Eloquent model | Uses `SoftDeletes`; extends `BaseModel`. |
| `TimetableFoundationServiceProvider` | Service provider | Registers policies. |
| `activityLog()` helper | Service dependency | Called on every state change (create, update, destroy, restore, forceDelete, toggleStatus). |

**Table:** `tt_day_types`

| Column | Type | Details |
|---|---|---|
| `id` | TINYINT UNSIGNED | Primary key, auto-increment (max 255 rows) |
| `code` | VARCHAR(20) | NOT NULL. Unique (`uq_daytype_code`). |
| `name` | VARCHAR(100) | NOT NULL. Unique (`uq_daytype_name`). |
| `description` | VARCHAR(255) | DEFAULT NULL. |
| `is_working_day` | TINYINT(1) | NOT NULL, DEFAULT 1. |
| `reduced_periods` | TINYINT(1) | NOT NULL, DEFAULT 0. |
| `ordinal` | TINYINT UNSIGNED | NOT NULL. Unique (`uq_daytype_ordinal`). |
| `is_active` | TINYINT(1) | NOT NULL, DEFAULT 1. |
| `created_at` | TIMESTAMP | NULL DEFAULT CURRENT_TIMESTAMP. |
| `updated_at` | TIMESTAMP | NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP. |
| `deleted_at` | TIMESTAMP | NULL DEFAULT NULL. |

**Unique Keys:**
- `uq_daytype_code` — on `code`
- `uq_daytype_name` — on `name`
- `uq_daytype_ordinal` — on `ordinal`
