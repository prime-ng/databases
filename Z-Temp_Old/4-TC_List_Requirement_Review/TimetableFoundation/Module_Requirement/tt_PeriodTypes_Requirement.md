# Period Types — Business Requirements

## What This Screen Does

The Period Types screen is a **CRUD master data screen** that defines the canonical set of period classifications used throughout the timetable system — Teaching, Theory, Practical, Break, Lunch, Assembly, Exam, Recess, Free Period, and any custom types a school needs. Each period type carries multiple behavioural flags that control how the timetable solver treats periods of that type: whether they are schedulable, count as teaching, count as workload, are break periods, or are free periods.

A subset of period types are designated as **system records** (`is_system = true`). These are seeded by the application (e.g., TEACHING, BREAK, LUNCH) and are protected from deletion, force-deletion, and from having their core behavioural flags modified. User-created types have `is_system = false` and can be fully managed.

The screen appears under **Timetable Configuration → Timetable Masters** tab group, specifically the **Period Types** tab (`tab=period-types`). It is administrative master data with full CRUD, status toggle, and trash/restore/forceDelete flows.

## When This Screen Is Used

- **Initial system setup** — During Timetable Foundation seeding, canonical period types are created as system-protected records (TEACHING, BREAK, LUNCH, ASSEMBLY, EXAM, RECESS, FREE_PERIOD, THEORY, PRACTICAL). Administrators inspect these after seeding.
- **Adding custom period types** — If a school uses a specialised period type not covered by the seed set (e.g., "Lab Period", "Remedial", "Library Period"), the administrator creates a new type with the appropriate behavioural flags.
- **Modifying non-system period types** — Custom types may have their name, description, colour, icon, flags, ordinal, or duration adjusted. System records cannot have their code or core behavioural flags changed.
- **Deactivating obsolete types** — When a period type is no longer needed, the administrator deactivates or soft-deletes it. System records cannot be deleted or deactivated.
- **Configuring Period Configs** — The Period Config screen (which defines the school's fixed daily timeslot grid) references period types. Changes to period type flags (e.g., `is_schedulable`) affect how period config slots behave.

## Default Data Load

The `PeriodTypeController@index` method authorises the user and redirects to the Timetable Masters page with `tab=period-types`. The actual data load occurs in `TimetableFoundationController@timetableMasters`, which queries:

```php
$periodTypes = PeriodType::query()
    ->orderBy('ordinal')
    ->get();
```

The result set is **not paginated** (master data, typically 9–20 rows). It includes:

| Filter | Input name | Default |
|--------|------------|---------|
| Search (name/code) | `pt_search` | None (all) |
| Status (is_active) | `pt_status` | `1` (active only) |

Columns rendered in the table: **# (ordinal)**, **Code**, **Name**, **Colour** (swatch), **Icon**, **Schedulable**, **Counts as Teaching**, **Counts as Workload**, **Break**, **Free Period**, **Duration**, **System** (lock badge), **Status** (toggle), **Action** (View, Edit, Trash).

## Key Fields at a Glance

**Identity Fields**

- **Code** — A unique uppercase code (e.g., `TEACHING`, `BREAK`, `LUNCH`, `ASSEMBLY`, `EXAM`, `RECESS`, `FREE_PERIOD`, `THEORY`, `PRACTICAL`). Max 30 characters. System records use stable codes referenced by seeders and solver logic.
- **Name** — Human-readable display name (e.g., "Teaching", "Break", "Lunch", "Assembly"). Max 100 characters.
- **Description** — Optional free-text explanation of the period type's purpose. Max 255 characters.
- **Color Code** (`color_code`) — Optional hex colour string (e.g., `#FF0000`, `#00FF00`, `#0000FF`). Validated with regex `/^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$/`. Used for visual differentiation in timetable views.
- **Icon** — Optional CSS class string (e.g., `fa-solid fa-chalkboard-teacher`, `fa-solid fa-clock`). Max 50 characters.

**Behavioural Flags**

- **Is Schedulable** (`is_schedulable`) — Boolean, default `true`. When false, the period type cannot be scheduled in the timetable (e.g., Free Period). If `is_break` is true, this is **forced to false**.
- **Counts as Teaching** (`counts_as_teaching`) — Boolean, default `false`. When true, periods of this type contribute to the teacher's teaching load statistics. If `is_break` is true, this is **forced to false**.
- **Counts as Workload** (`counts_as_workload`) — Boolean, default `false`. When true, periods of this type contribute to workload calculations. If `is_break` is true, this is **forced to false**.
- **Is Break** (`is_break`) — Boolean, default `false`. When true, the period type represents a break (Short Break, Lunch). This flag forces `is_schedulable`, `counts_as_teaching`, and `counts_as_workload` to `false`.
- **Is Free Period** (`is_free_period`) — Boolean, default `false`. When true, the period type represents unassigned/free time in the timetable.
- **Is System** (`is_system`) — Boolean, default `false` for user-created records. The `store()` method always sets `is_system = false`. The `update()` method protects system records by unsetting `code`, `is_break`, `is_schedulable`, `counts_as_teaching`, and `counts_as_workload` from the validated data.

**Duration and Ordering**

- **Ordinal** — Unsigned tiny integer, controls sort order in list views (ascending). Must be unique across all period types.
- **Duration Minutes** (`duration_minutes`) — Integer, default `30`. The typical duration of this period type in minutes (e.g., 30, 40, 45, 60). Consumed by the period config and timetable solver.

**Status and Timestamps**
- **Is Active** (`is_active`) — Boolean, default `true`.
- `created_at` / `updated_at` — Standard Laravel timestamps.
- `deleted_at` — Nullable; populated by `SoftDeletes` trait on soft delete.

## Business Rules and Conditions

**BR-001 — Code Uniqueness (Across Non-Deleted Records)**
The `code` column has a unique key (`uq_periodtype_code`). The validation rule `Rule::unique('tt_period_types', 'code')->whereNull('deleted_at')` enforces uniqueness, ignoring soft-deleted records. On update, the code field is not part of the validated array for system records (it is unset).

**BR-002 — Ordinal Uniqueness**
The `ordinal` column has a unique key (`uq_periodtype_ordinal`). The validation rule `Rule::unique('tt_period_types', 'ordinal')->whereNull('deleted_at')` enforces this. On update, `->ignore($periodType->id)` is used.

**BR-003 — Break Period Flag Overrides**
If `is_break` is set to `true`, the controller forces three other flags to `false`:
- `is_schedulable = false` — break periods cannot be scheduled as teaching slots
- `counts_as_teaching = false` — break time is not counted as teaching
- `counts_as_workload = false` — break time is not counted as workload

This is enforced both on create and update (for non-system records).

**BR-004 — System Record Protection**
Records with `is_system = true` are protected against:

| Action | Behaviour |
|--------|-----------|
| Update — code change | `code` is unset from `$validated`; no change allowed |
| Update — core behavioural flags | `is_break`, `is_schedulable`, `counts_as_teaching`, `counts_as_workload` are unset from `$validated`; no change allowed |
| Update — other fields | Name, description, colour, icon, ordinal, duration, free period flag, and status can still be changed |
| Delete (soft) | Redirect back with `flash('operation_failed')` error |
| Force Delete | Redirect back with `flash('system_record_force_delete_not_allowed')` error |
| Toggle Status | JSON 403 response with `flash('system_record_status_change_not_allowed')` |

**BR-005 — User-Created Records Always Non-System**
The `store()` method explicitly sets `$validated['is_system'] = false` before creating the record. Users can never create system records through the UI.

**BR-006 — Deactivation Cascade on Delete**
When a period type is soft-deleted via `destroy()`, the controller first sets `is_active = false`, then calls `$periodType->delete()`. This ensures immediate exclusion from active queries.

**BR-007 — Reactivation on Restore**
When a trashed period type is restored, the controller sets `is_active = true`.

**BR-008 — Activity Logging on All Mutations**
Every state-changing operation (create, update, destroy, restore, forceDelete, toggleStatus) invokes the `activityLog()` helper to record an audit trail.

**BR-009 — Colour Code Validation**
The `color_code` field must match the hex colour regex `/^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$/`. Three-digit hex codes (e.g., `#F00`) and six-digit hex codes (e.g., `#FF0000`) are accepted.

**BR-010 — Referential Dependency from Period Configs and Period Sets**
Downstream tables (`tt_period_configs`, `tt_period_set_periods_jnt`) reference `tt_period_types.id` via foreign keys with `ON DELETE RESTRICT`. A period type cannot be deleted if it is referenced.

## Workflow Steps

**Creating a New Period Type**

1. User navigates to **Timetable Foundation → Timetable Masters → Period Types** tab.
2. Clicks **"Add New"** → `PeriodTypeController@create`.
3. `Gate::authorize('timetable-foundation.period-type.create')` — 403 if unauthorised.
4. Form rendered: Code (`text`, required, max 30), Name (`text`, required, max 100), Description (`textarea`, optional), Color Code (`text`, optional, hex regex), Icon (`text`, optional, max 50), Ordinal (`number`, min 1), Duration Minutes (`number`, default 30), plus checkboxes for Schedulable (default checked), Counts as Teaching, Counts as Workload, Is Break, Is Free Period, Is Active (default checked).
5. On submit → `POST /period-type` → `store()`.
6. Validation runs.
7. Boolean flags normalised via `$request->boolean()`.
8. `is_system` set to `false`.
9. If `is_break` is true, `is_schedulable`, `counts_as_teaching`, `counts_as_workload` forced to `false`.
10. `PeriodType::create($validated)` → new row inserted.
11. Redirect to `timetable-foundation.menu.timetableMasters?tab=period-types` with success flash.

**Editing an Existing Period Type**

1. User clicks **Edit** on a period type row → `PeriodTypeController@edit($id)`.
2. `Gate::authorize('timetable-foundation.period-type.update')`.
3. Form pre-filled with existing values.
4. On submit → `PUT /period-type/{periodType}` → `update()`.
5. Validation runs (code and ordinal unique with ignore).
6. If `is_system`:
   - `code`, `is_break`, `is_schedulable`, `counts_as_teaching`, `counts_as_workload` are unset from validated data
   - Remaining fields (name, description, colour, icon, ordinal, duration, free period, status) are allowed to change
7. If not `is_system`:
   - All boolean flags normalised via `$request->boolean()`
   - If `is_break` is true, forced overrides applied
8. `$periodType->update($validated)` → row updated.
9. Redirect with success flash.

**Soft-Deleting a Period Type**

1. Click **Trash** → `destroy($id)`.
2. `Gate::authorize('timetable-foundation.period-type.delete')`.
3. If `is_system` → redirect back with error `flash('operation_failed')`.
4. `is_active = false` → `save()` → `delete()` (SoftDeletes).
5. Activity logged: `'Period type was deactivated and moved to trash.'`.
6. Redirect with success flash.

**Restoring a Trashed Period Type**

1. Navigate to **Trash** view → `trashedPeriodType()` lists only-trashed records.
2. Click **Restore** → `restore($id)`.
3. `Gate::authorize('timetable-foundation.period-type.restore')`.
4. `$periodType->restore()` → `is_active = true` → `save()`.
5. Activity logged: `'Period type was restored successfully.'`.
6. Redirect to trash view with success flash.

**Toggling Status**

1. User toggles the switch in the list table → `POST /period-type/{periodType}/toggle-status`.
2. `Gate::authorize('timetable-foundation.period-type.update')`.
3. Validates `is_active` required boolean.
4. If `is_system` → JSON 403 response.
5. Saves new status.
6. Returns JSON `{ success: true, is_active, message }` on success, or `{ success: false, ... }` with 422 on failure.

## Example Scenario

Mr. Kumar, the Timetable Manager at Sunshine Academy, is configuring period types:

1. He navigates to **Timetable Masters → Period Types** tab. Nine pre-seeded system types are visible: TEACHING, THEORY, PRACTICAL, BREAK, LUNCH, ASSEMBLY, EXAM, RECESS, FREE_PERIOD. All show the lock icon indicating they are system records.

2. The school runs a "Remedial" programme where students receive extra help. Mr. Kumar clicks **Add New** and creates:
   - Code: `REMEDIAL`
   - Name: `Remedial Period`
   - Description: `Extra remedial help session`
   - Color Code: `#FFA500` (orange)
   - Icon: `fa-solid fa-book-open`
   - Schedulable: checked
   - Counts as Teaching: unchecked
   - Counts as Workload: checked
   - Is Break: unchecked
   - Is Free Period: unchecked
   - Ordinal: `10`
   - Duration: `45`

3. Mr. Kumar tries to edit the LUNCH system record to change `counts_as_workload` to `true`. The controller redirects back with an error because system record core flags cannot be modified. However, he can change LUNCH's description or colour.

4. Later, the school discontinues the RECESS type. Mr. Kumar tries to delete it, but it is a system record — deletion is blocked. He would need to deactivate it instead (toggle status to inactive).

5. Mr. Kumar soft-deletes the custom REMEDIAL type. It is deactivated, moved to trash, and can be restored if the programme is revived.

## Related Screens

- **Period Config** (Timetable Foundation) — `tt_period_configs.period_type_id` FK references `tt_period_types.id` with `ON DELETE RESTRICT`. Period configs define the school's fixed daily timeslot grid and each slot references a period type.
- **Period Sets** (Timetable Foundation) — `tt_period_set_periods_jnt.period_type_id` FK references `tt_period_types.id` with `ON DELETE RESTRICT`. Period set periods can override the default period type from period config.
- **Timetable View** (Timetable Foundation) — The timetable rendering uses period type colours, icons, and flags to display and classify timetable cells.

## Requirements

- `PeriodTypeController` provides full CRUD with methods `index()` (redirects to masters page), `create()`, `store()`, `show()`, `edit()`, `update()`, `destroy()`, `restore()`, `forceDelete()`, `trashedPeriodType()`, and `toggleStatus()` — implements `SoftDeletes` on the `PeriodType` model. The `destroy()` method checks `is_system` before proceeding; if system, redirects back with error. The `forceDelete()` method also checks `is_system` and blocks with error. The `update()` method uses Laravel implicit model binding (`PeriodType $periodType`). Gates: `timetable-foundation.period-type.*`. Policy: No dedicated policy file — gate checks use implicit model/policy resolution. Routes: resource `period-type` (`Route::resource('period-type', PeriodTypeController::class)`) plus `/period-type/trash/view`, `/{id}/restore`, `/{id}/force-delete`, `/{periodType}/toggle-status`.
- Validation is inline in the controller (no Form Request): `code` required|string|max:30|unique with `whereNull('deleted_at')`, `name` required|string|max:100, `description` nullable|string|max:255, `color_code` nullable|string|max:10|regex hex, `icon` nullable|string|max:50, `ordinal` required|integer|min:1|unique with `whereNull('deleted_at')`, boolean flags as `sometimes|boolean`, `is_active` as `sometimes`. On update, `code` and `ordinal` unique rules use `->ignore($periodType->id)`.
- Boolean flags normalised via `$request->boolean()` on both create and update (for non-system records).
- `is_system` always set to `false` for user-created records.
- Business rule enforcement: if `is_break` is true, `is_schedulable`, `counts_as_teaching`, `counts_as_workload` forced to false (both on create and update for non-system records).
- System record protection: `update()` unsets `code`, `is_break`, `is_schedulable`, `counts_as_teaching`, `counts_as_workload` from validated data for system records.
- The `PeriodType` model uses `SoftDeletes`, extends `BaseModel`, and defines `$casts` for all boolean flags, `ordinal` (integer), `duration_minutes` (integer), timestamps (datetime). Defines `$attributes` defaults. Defines `$fillable` including `created_by`. Defines scopes `active`, `schedulable`, `teaching`, `breaks`, `ordered`. Defines `periodSetPeriods()` hasMany relationship.
- Activity logging is performed on all state-changing operations.

## Who Can Access

| Gate/Permission | Methods | Notes |
|---|---|---|
| `timetable-foundation.period-type.viewAny` | `PeriodTypeController@index` | Loads the period-types tab |
| `timetable-foundation.period-type.create` | `PeriodTypeController@create`, `store` | Create and store period type |
| `timetable-foundation.period-type.view` | `PeriodTypeController@show` | View single record |
| `timetable-foundation.period-type.update` | `PeriodTypeController@edit`, `update`, `toggleStatus` | Edit, update, toggle status |
| `timetable-foundation.period-type.delete` | `PeriodTypeController@destroy` | Soft-delete (deactivate + trash) |
| `timetable-foundation.period-type.restore` | `PeriodTypeController@restore`, `trashedPeriodType` | Restore and view trash |
| `timetable-foundation.period-type.forceDelete` | `PeriodTypeController@forceDelete` | Permanent delete |

Global page access is gated by `timetable-foundation.viewAny` on `TimetableFoundationController@timetableMasters`.

No dedicated policy file for `PeriodType` — gate checks use Laravel's implicit model policy resolution.

## Logic Flow

### Store Flow

```
User submits create form
        │
        ▼
Gate::authorize('timetable-foundation.period-type.create')
        │
        ▼ (authorised)
Validate request:
  • code (required, unique, max:30)
  • name (required, max:100)
  • description (nullable, max:255)
  • color_code (nullable, max:10, hex regex)
  • icon (nullable, max:50)
  • ordinal (required, min:1, unique)
  • is_schedulable, counts_as_teaching, counts_as_workload, is_break, is_free_period (sometimes|boolean)
  • is_active (sometimes)
        │
        ▼ (pass)
Normalize booleans via $request->boolean()
Set is_system = false
        │
        ▼
If is_break:
  is_schedulable = false
  counts_as_teaching = false
  counts_as_workload = false
        │
        ▼
Persist: PeriodType::create($validated)
        │
        ▼
Redirect → timetable-foundation.menu.timetableMasters?tab=period-types
```

### Update Flow

```
User submits edit form
        │
        ▼
Gate::authorize('timetable-foundation.period-type.update')
        │
        ▼ (authorised)
Validate request (code/ordinal unique ignore current)
        │
        ▼
if $periodType->is_system:
  unset code, is_break, is_schedulable, counts_as_teaching, counts_as_workload
else:
  normalize booleans via $request->boolean()
  if is_break:
    enforce overrides
        │
        ▼
is_free_period and is_active normalized via $request->boolean()
unset is_system (never allow client to change)
        │
        ▼
$periodType->update($validated)
        │
        ▼
Redirect → timetable-foundation.menu.timetableMasters?tab=period-types
```

### Delete Flow

```
User clicks Trash
        │
        ▼
Gate::authorize('timetable-foundation.period-type.delete')
        │
        ▼ (authorised)
$periodType = PeriodType::findOrFail($id)
        │
        ▼
if $periodType->is_system:
  redirect back with error flash('operation_failed')
else:
  is_active = false → save() → delete()
  activityLog('Trashed')
  redirect → success
```

### Toggle Status Flow

```
User flips toggle switch
        │
        ▼
POST /period-type/{periodType}/toggle-status
        │
        ▼
Gate::authorize('timetable-foundation.period-type.update')
        │
        ▼ (authorised)
Validate: is_active required|boolean
        │
        ▼
if $periodType->is_system:
  JSON 403 { success: false, is_active, message: flash('system_record_status_change_not_allowed') }
else:
  $periodType->is_active = (bool) $request->input('is_active')
  if save() succeeds → JSON { success: true, is_active, message }
  else → JSON { success: false, ... } with 422
```

## Validate Before Save

**Store (PeriodTypeController — inline validation)**

| Field | Rule(s) | Error Message |
|---|---|---|
| `code` | `required`, `string`, `max:30`, `unique:tt_period_types,code` with `whereNull('deleted_at')` | Laravel default |
| `name` | `required`, `string`, `max:100` | Laravel default |
| `description` | `nullable`, `string`, `max:255` | Laravel default |
| `color_code` | `nullable`, `string`, `max:10`, `regex:/^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$/` | Laravel default |
| `icon` | `nullable`, `string`, `max:50` | Laravel default |
| `ordinal` | `required`, `integer`, `min:1`, `unique:tt_period_types,ordinal` with `whereNull('deleted_at')` | Laravel default |
| `is_schedulable` | `sometimes`, `boolean` | Normalized via `$request->boolean()` |
| `counts_as_teaching` | `sometimes`, `boolean` | Normalized via `$request->boolean()` |
| `counts_as_workload` | `sometimes`, `boolean` | Normalized via `$request->boolean()` |
| `is_break` | `sometimes`, `boolean` | Normalized via `$request->boolean()` |
| `is_free_period` | `sometimes`, `boolean` | Normalized via `$request->boolean()` |
| `is_active` | `sometimes` | Normalized via `$request->boolean()` |

**Controller-level (store):**
- `is_system` explicitly set to `false`
- If `is_break` → `is_schedulable=false`, `counts_as_teaching=false`, `counts_as_workload=false`

**Update (PeriodTypeController — inline validation)**

| Field | Rule(s) | Error Message |
|---|---|---|
| `code` | (for non-system) `required`, `string`, `max:30`, `unique:tt_period_types,code` → ignores current | Laravel default |
| `name` | `required`, `string`, `max:100` | Laravel default |
| `description` | `nullable`, `string`, `max:255` | Laravel default |
| `color_code` | `nullable`, `string`, `max:10`, `regex:/^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$/` | Laravel default |
| `icon` | `nullable`, `string`, `max:50` | Laravel default |
| `ordinal` | `required`, `integer`, `min:1`, `unique:tt_period_types,ordinal` → ignores current | Laravel default |
| `is_schedulable` | `sometimes`, `boolean` | — |
| `counts_as_teaching` | `sometimes`, `boolean` | — |
| `counts_as_workload` | `sometimes`, `boolean` | — |
| `is_break` | `sometimes`, `boolean` | — |
| `is_free_period` | `sometimes`, `boolean` | Normalized via `$request->boolean()` |
| `is_active` | `sometimes` | Normalized via `$request->boolean()` |

**Controller-level (update):**
- System records: `code`, `is_break`, `is_schedulable`, `counts_as_teaching`, `counts_as_workload` unset from validated data
- Non-system records: if `is_break` → forced overrides applied
- `is_system` always unset (never allow client to change)

## Error Handling and Validation Messages

| Scenario | Message | Type |
|---|---|---|
| Validation failure (any field) | Laravel default `.validation.*` strings | Validation rule (302 redirect) |
| Invalid hex colour | `validation.regex` — colour format invalid | Validation rule |
| Not authorised (view list) | `AuthorizationException` → 403 page | Gate |
| Not authorised (create) | 403 Forbidden | Gate |
| Not authorised (update/toggle) | 403 Forbidden | Gate |
| Not authorised (delete) | 403 Forbidden | Gate |
| Not authorised (restore) | 403 Forbidden | Gate |
| Model not found | `ModelNotFoundException` → 404 page | Controller `findOrFail()` |
| Delete system record | Redirect back with `flash('operation_failed')` error | Controller check |
| Force delete system record | Redirect back with `flash('system_record_force_delete_not_allowed')` | Controller check |
| Toggle status on system record | JSON 403 `{ success: false, is_active, message: flash('system_record_status_change_not_allowed') }` | Controller check |
| FK constraint violation (delete blocked) | `SQLSTATE[23000]` integrity constraint violation → 500 error page | Database |
| Toggle status save failure | JSON `{ success: false, is_active, message: flash('status_switch_failed.period_type') }` with 422 | Controller check |

## Success Scenarios

**SC-001 — Create a Custom Period Type**
Mr. Kumar creates a period type with Code = `REMEDIAL`, Name = `Remedial Period`, Color Code = `#FFA500`, Icon = `fa-solid fa-book-open`, Ordinal = `10`, Duration = `45`, Schedulable = checked, Counts as Workload = checked. The type is saved with `is_system = false`, `is_active = true`. He is redirected to the Period Types tab with a green success message.

**SC-002 — Create a Break Period Type — Business Rules Applied**
Mr. Kumar creates a type with Code = `SHORT_BREAK`, Name = `Short Break`, Is Break = checked. Even if he also checked Schedulable and Counts as Workload, the controller forces `is_schedulable = false`, `counts_as_teaching = false`, `counts_as_workload = false` because `is_break` is true.

**SC-003 — Edit a Non-System Period Type**
Mr. Kumar edits the `REMEDIAL` type to change its colour to `#FF6347` and duration to `40`. The update succeeds.

**SC-004 — Edit a System Record — Limited Fields**
Mr. Kumar edits the `LUNCH` system record to change its description to "Mid-day meal break (30 min)". The code remains unchanged, and the behavioural flags are protected. The update succeeds for description only.

**SC-005 — Toggle Status on Non-System Type**
Mr. Kumar toggles the status of the `REMEDIAL` type from active to inactive. The server returns `{ success: true, is_active: false }`. The type is hidden from selection dropdowns.

**SC-006 — Delete and Restore Custom Type**
Mr. Kumar soft-deletes the `REMEDIAL` type. It is deactivated and moved to trash. He restores it — it reappears with `is_active = true`.

## Failure Scenarios

**FC-001 — Duplicate Period Type Code**
Mr. Kumar tries to create a period type with code `TEACHING` (already exists as system type). The `unique` validation rule returns: "The code has already been taken."

**FC-002 — Duplicate Ordinal**
Mr. Kumar creates a period type with ordinal `5` but ordinal `5` already exists. The `unique` validation rule returns: "The ordinal has already been taken."

**FC-003 — Invalid Hex Colour**
Mr. Kumar enters colour `red` (not a hex code). The `regex` validation rule returns an error for invalid colour format.

**FC-004 — Delete System Record Blocked**
Mr. Kumar tries to delete the `TEACHING` system record. The `destroy()` method checks `is_system` and redirects back with error `flash('operation_failed')`.

**FC-005 — Toggle Status on System Record — 403**
Mr. Kumar tries to toggle the status of the `TEACHING` system record. The server returns HTTP 403 with JSON `{ success: false, is_active: true, message: "System record status cannot be changed." }`.

**FC-006 — Force Delete System Record Blocked**
Mr. Kumar tries to force-delete the `TEACHING` system record from trash (if it were deletable — it never can be). The `forceDelete()` method checks `is_system` and redirects back with error `flash('system_record_force_delete_not_allowed')`.

**FC-007 — Delete Period Type Referenced by Period Config**
Mr. Kumar tries to delete a non-system period type that is referenced by a Period Config record. The FK RESTRICT constraint throws a database integrity violation.

## Dependencies module and tables

| Dependency | Type | Details |
|---|---|---|
| `tt_period_types` | Primary table | Master data table; `tinyIncrements('id')` — max 255 rows. All CRUD operations target this table. |
| `tt_period_configs` | Child (FK) | `tt_period_configs.period_type_id` FK references `tt_period_types(id)` via `fk_pc_period_type` with `ON DELETE RESTRICT`. |
| `tt_period_set_periods_jnt` | Child (FK) | `tt_period_set_periods_jnt.period_type_id` FK references `tt_period_types(id)` via `fk_psp_period_type` with `ON DELETE RESTRICT`. |
| `Modules\TimetableFoundation\Models\PeriodType` | Eloquent model | Uses `SoftDeletes`; extends `BaseModel`. |
| `TimetableFoundationServiceProvider` | Service provider | Registers policies. |
| `activityLog()` helper | Service dependency | Called on every state change. |

**Table:** `tt_period_types`

| Column | Type | Details |
|---|---|---|
| `id` | TINYINT UNSIGNED | Primary key, auto-increment (max 255 rows) |
| `code` | VARCHAR(30) | NOT NULL. Unique (`uq_periodtype_code`). |
| `name` | VARCHAR(100) | NOT NULL. |
| `description` | VARCHAR(255) | DEFAULT NULL. |
| `color_code` | VARCHAR(10) | DEFAULT NULL. Hex colour. |
| `icon` | VARCHAR(50) | DEFAULT NULL. CSS class. |
| `is_schedulable` | TINYINT(1) | NOT NULL, DEFAULT 1. |
| `counts_as_teaching` | TINYINT(1) | NOT NULL, DEFAULT 0. |
| `counts_as_workload` | TINYINT(1) | NOT NULL, DEFAULT 0. |
| `is_break` | TINYINT(1) | NOT NULL, DEFAULT 0. |
| `is_free_period` | TINYINT(1) | NOT NULL, DEFAULT 0. |
| `ordinal` | TINYINT UNSIGNED | NOT NULL. Unique (`uq_periodtype_ordinal`). |
| `duration_minutes` | INT UNSIGNED | DEFAULT 30. |
| `is_active` | TINYINT(1) | NOT NULL, DEFAULT 1. |
| `created_at` | TIMESTAMP | NULL DEFAULT CURRENT_TIMESTAMP. |
| `updated_at` | TIMESTAMP | NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP. |
| `deleted_at` | TIMESTAMP | NULL DEFAULT NULL. |

**Unique Keys:**
- `uq_periodtype_code` — on `code`
- `uq_periodtype_ordinal` — on `ordinal`
