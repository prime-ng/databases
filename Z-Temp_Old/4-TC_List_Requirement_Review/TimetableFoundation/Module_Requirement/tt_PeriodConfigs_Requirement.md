# Period Configs — Business Requirements

## What This Screen Does

Period Configs define every individual timeslot in a school day — their exact start and end times, whether they are teaching or non-teaching slots, which period type they belong to, and whether they can be used as free periods. Each config belongs to a specific shift (Morning, Afternoon, Evening) and together the configs for a shift form the complete timing grid that all timetables reference. Period configs are the atomic building blocks of the school schedule — every timetable slot ultimately traces back to a period config's start time, end time, and duration.

The screen provides a master list view grouped by shift, with inline AJAX editing for times, drag-and-drop reordering, and toggle controls for the teaching-slot and free-period flags.

## When This Screen Is Used

- **Initial school setup** — When a new school configures its daily schedule, the administrator defines each timeslot of the day with precise start and end times for each shift.
- **Adding a new shift** — When a school adds an Afternoon or Evening shift, a complete set of period configs must be defined for that shift.
- **Adjusting bell timings** — When the school changes its schedule (e.g., shifting the start of the school day or shortening period durations), the administrator edits the relevant configs.
- **Reordering the daily grid** — When period sequence changes (e.g., moving assembly to after first period), the administrator uses drag-and-drop to reorder configs.
- **Marking free-period eligibility** — When the administrator decides which teaching slots may be used as free periods for certain teachers or classes.
- **Feeding the timetable solver** — Period configs are consumed by the SmartTimetable solver to determine absolute timing for every scheduled slot.

## Default Data Load

The screen is one of four tabs on the **Timetable Masters** page, accessed at `timetable-foundation.menu.timetableMasters` with tab parameter `?tab=period-configs#period-configs`. The `PeriodConfigController@index` method is called which gates on `timetable-foundation.period-config.viewAny` and redirects to the menu route.

The default data load includes:

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| Period Configs Grid | `index()` → `timetableMasters()` | `PeriodConfig::with('shift','periodType')->orderBy('shift_id')->orderBy('display_order')->orderBy('slot_ord')` | None | Default page size |
| Shared: Shifts (create/edit) | `create()` / `edit()` | `SchoolShift::where('is_active', true)->orderBy('ordinal')->get()` | is_active=true | None |
| Shared: Period Types (create/edit) | `create()` / `edit()` | `PeriodType::where('is_active', true)->orderBy('ordinal')->get()` | is_active=true | None |

## Key Fields at a Glance

**Identity and Classification**

- **Shift** — Which operational shift (Morning, Afternoon, Evening) the timeslot belongs to. All configs for a shift collectively define that shift's daily timeline.
- **Slot Ordinal** — The sequential number for teaching slots only (1, 2, 3…). This value is NULL for non-teaching slots (assembly, breaks, lunch). The combination of `(shift_id, slot_ord)` must be unique.
- **Code** — A short machine-readable identifier like `SLOT-01` or `SLOT-02`, unique within the shift.
- **Short Name** — A human-readable display label such as "Assembly", "Period 1", "Short Break", or "Lunch".

**Timing**

- **Period Type** — The default type of this time block (Teaching, Break, Lunch, Assembly, etc.). Each type carries its own colour badge displayed in the grid.
- **Start Time** — The fixed clock time at which the slot begins (e.g., `07:45`).
- **End Time** — The fixed clock time at which the slot ends (e.g., `08:30`). Must be strictly after start time.
- **Duration (Auto)** — The length of the slot in minutes, automatically calculated by the database as `TIMESTAMPDIFF(MINUTE, start_time, end_time)`. This is a generated column — never manually entered.

**Slot Behaviour**

- **Is Teaching Slot** — Whether this slot is a teaching period. Only teaching slots get a `slot_ord` and can be marked as free-period eligible. When this is set to false, the controller forces `slot_ord = NULL` and `can_be_free_period = false`.
- **Can Be Free Period** — Whether this teaching slot may be used as a free period (no activity assigned). This toggle is only applicable when `is_teaching_slot = true`.
- **Display Order** — The UI display order, independent of `slot_ord`. Used for drag-and-drop reordering. Non-teaching slots can be interleaved between teaching slots in display order.

## Business Rules and Conditions

**Teaching Slot / Slot Ordinal Coupling.** Only slots with `is_teaching_slot = true` receive a non-null `slot_ord`. When `is_teaching_slot` is false, the controller forces `slot_ord = null` and `can_be_free_period = false`. This ensures non-instructional slots (assembly, breaks, lunch) never participate in teaching-period calculations.

**Free-Period Eligibility Constraint.** Only teaching slots can be marked as `can_be_free_period = true`. The AJAX `ajaxToggleCanBeFree` endpoint explicitly checks `is_teaching_slot` and returns HTTP 422 with a descriptive message if violated. The same constraint is enforced during create/update in the controller.

**Generated Duration Column.** The `duration_minutes` column in `tt_period_configs` is a `GENERATED ALWAYS AS (TIMESTAMPDIFF(MINUTE, start_time, end_time)) STORED` column. It is guarded from mass assignment (`$guarded` in the model) and is never written by the application. The UI displays it as read-only.

**End Time Must Be After Start Time.** Every period config must have `end_time > start_time`. Zero-duration or negative-duration slots are invalid. This is enforced by a database `CHECK` constraint (`chk_pc_time`) and by the server-side validation rule `after:start_time`.

**Unique Code per Shift.** Within a single shift, no two period configs may share the same `code`. This is enforced by a composite unique key `uq_pc_shift_code` on `(shift_id, code)`, and by scoped unique validation that ignores soft-deleted records.

**Unique Slot Ordinal per Shift.** Within a single shift, no two teaching slots may share the same `slot_ord`. This is enforced by a composite unique key `uq_pc_shift_ord` on `(shift_id, slot_ord)`, and by scoped unique validation that ignores soft-deleted records.

**Deactivation Before Soft Delete.** When a period config is deleted, the controller sets `is_active = false` before calling the model's `delete()` method. This ensures the deleted slot is immediately excluded from dropdowns and active-use queries.

**Restore Reactivates.** When a soft-deleted period config is restored, the controller sets `is_active = true` after the restore, bringing it back to active use.

## Workflow Steps

**Viewing the Period Configs Grid.** The administrator navigates to Timetable Masters → Period Configs tab. The grid displays all configs grouped by shift, showing each config's code, short name, period type (with colour badge), start time, end time, duration, teaching slot indicator, free-period indicator, and status toggle. Configs are ordered by `display_order` within each shift.

**Creating a New Period Config.** The administrator clicks "Add Period Config", selects a shift and period type, enters the code, short name, start time, end time, and optionally marks it as a teaching slot (with slot ordinal) and free-period eligible. Non-teaching slots automatically have `slot_ord` set to null and `can_be_free_period` forced to false.

**Editing a Period Config.** The administrator clicks the Edit action on any row, modifies any field (except the generated `duration_minutes` which is read-only), and saves. The controller re-applies all business rules during update.

**Inline Time Editing (AJAX).** The administrator can click the start or end time cell in the grid to edit it inline. The `ajaxUpdateTimes` endpoint validates the new times (including `after:start_time`), updates the record, and returns the new duration. The grid row refreshes to show the updated times.

**Drag-and-Drop Reorder (AJAX).** The administrator drags rows to reorder them. The `ajaxReorder` endpoint receives an ordered array of config IDs and updates each config's `display_order` to match the new sequence. The `slot_ord` values are not affected — only `display_order` changes.

**Toggling Can-Be-Free Period (AJAX).** The administrator clicks the free-period toggle on a teaching slot. The `ajaxToggleCanBeFree` endpoint flips the flag and returns JSON success. If clicked on a non-teaching slot, the server returns HTTP 422.

**Deleting a Period Config.** The administrator clicks the Trash action. The controller gates with `.delete`, sets `is_active = false`, soft-deletes, and logs the activity.

## Example Scenario

Ms. Sharma, the timetable administrator at Gurukul Academy, is setting up the Morning Shift for the new academic year. She creates 12 period configs for the Morning shift:

1. **SLOT-A** (Assembly, 07:30–07:45) — period type ASSEMBLY, non-teaching, slot_ord = null
2. **SLOT-01** (Period 1, 07:45–08:30) — period type TEACHING, teaching slot, slot_ord = 1
3. **SLOT-02** (Period 2, 08:30–09:15) — teaching slot, slot_ord = 2
4. **SLOT-03** (Period 3, 09:15–10:00) — teaching slot, slot_ord = 3
5. **SLOT-B1** (Short Break 1, 10:00–10:15) — period type BREAK, non-teaching
6. **SLOT-04** (Period 4, 10:15–11:00) — teaching slot, slot_ord = 4
7. **SLOT-05** (Period 5, 11:00–11:45) — teaching slot, slot_ord = 5
8. **SLOT-L** (Lunch, 11:45–12:30) — period type LUNCH, non-teaching
9. **SLOT-06** (Period 6, 12:30–13:15) — teaching slot, slot_ord = 6
10. **SLOT-07** (Period 7, 13:15–14:00) — teaching slot, slot_ord = 7
11. **SLOT-B2** (Short Break 2, 14:00–14:15) — non-teaching
12. **SLOT-08** (Period 8, 14:15–15:00) — teaching slot, slot_ord = 8

She marks SLOT-04 and SLOT-07 as `can_be_free_period = true` so the scheduling system can assign free periods for teachers during those slots. She verifies that SLOT-A (Assembly) has `slot_ord = null` and `can_be_free_period = false`. Later, she reorders via drag-and-drop to move Short Break 2 before Period 7 for the new term. The `display_order` updates and the grid reflects the new sequence.

## Related Screens

- **Period Types** — Defines the classifications (Teaching, Break, Lunch, Assembly, etc.) that each period config references via `period_type_id`
- **Period Sets** — Groups a range of period configs into a named set (e.g., "Standard 8-Period Day") that classes use as their timing template
- **Shifts Master** — Defines the operational shifts (Morning, Afternoon, Evening) that period configs belong to
- **Timetable Preparation → Requirement Consolidation** — Downstream process that reads period config data for slot requirement generation

## Requirements

- `PeriodConfigController` (307 lines, `Modules/TimetableFoundation/Http/Controllers/`) handles CRUD + AJAX endpoints for `tt_period_configs`. Public methods: `index()`, `create()`, `store()`, `show()`, `edit()`, `update()`, `destroy()`, `trashed*()`, `restore()`, `forceDelete()`, `toggleStatus()`, `ajaxReorder()`, `ajaxUpdateTimes()`, `ajaxToggleCanBeFree()`.
- The `index()` method gates with `timetable-foundation.period-config.viewAny` and redirects to `timetable-foundation.menu.timetableMasters`.
- The `store()` method (lines 40–60) forces `slot_ord = null` and `can_be_free_period = false` when `is_teaching_slot` is false.
- The `ajaxUpdateTimes()` method (lines 150–180) validates `start_time` and `end_time` with `date_format:H:i` and `after:start_time`, updates the record, and returns JSON with the new times and computed `duration_minutes`.
- The `ajaxToggleCanBeFree()` method (lines 200–220) checks `is_teaching_slot` — if false, returns HTTP 422 with "Only teaching slots can be marked as free periods".
- The `ajaxReorder()` method (lines 250–280) accepts an `ids[]` array, validates existence, and updates `display_order` in a database transaction.
- Validation is handled via a `validatePayload()` helper (not a dedicated Form Request) that returns validated data or throws `ValidationException`.
- The `PeriodConfig` model (`Modules/TimetableFoundation/Models/`, table: `tt_period_configs`) uses `SoftDeletes`, guards `duration_minutes` from mass assignment, and casts booleans/integers appropriately. Relationships: `shift()` (BelongsTo), `periodType()` (BelongsTo), `periodSetPeriods()` (HasMany).
- The `PeriodConfigPolicy` defines `viewAny`, `view`, `create`, `update`, `delete`, `restore`, `forceDelete` — each delegating to `timetable-foundation.period-config.{action}`.
- Routes are registered in `routes/web.php` (lines 169–176): `Route::resource('period-config', PeriodConfigController::class)` plus custom routes for trashed, restore, forceDelete, toggleStatus, and AJAX endpoints.
- Activity logging is implemented on all state changes: destroy (Trashed), restore (Restored), forceDelete (Deleted), toggleStatus (Toggled), ajaxToggleCanBeFree (Toggled).

## Who Can Access

| Gate/Permission | Methods | Notes |
|-----------------|---------|-------|
| `timetable-foundation.period-config.viewAny` | `index()` | Required to view the Period Configs tab |
| `timetable-foundation.period-config.view` | `show()` | Required to view a single config's details |
| `timetable-foundation.period-config.create` | `create()`, `store()` | Required to show create form and persist a new config |
| `timetable-foundation.period-config.update` | `edit()`, `update()`, `toggleStatus()`, `ajaxToggleCanBeFree()`, `ajaxUpdateTimes()`, `ajaxReorder()` | Required to edit a config, toggle status, or use AJAX operations |
| `timetable-foundation.period-config.delete` | `destroy()` | Required to soft-delete a config |
| `timetable-foundation.period-config.restore` | `trashed*()`, `restore()` | Required to view trashed configs and restore them |
| `timetable-foundation.period-config.forceDelete` | `forceDelete()` | Required to permanently delete a config |

**Policy:** `Modules\TimetableFoundation\Policies\PeriodConfigPolicy` — each method checks the corresponding permission string.

## Logic Flow

**1. Page Load (List View).** The user navigates to Timetable Masters → Period Configs tab. `TimetableFoundationController@timetableMasters()` renders the multi-tab layout. The Period Configs tab fetches `PeriodConfig::with('shift','periodType')->orderBy('shift_id')->orderBy('display_order')`. The grid shows all configs with shift badge, code, short name, period type badge, start/end times, duration, teaching slot indicator, free-period toggle, and status toggle.

**2. Create.** User clicks "Add Period Config". `create()` gates with `.create`, loads `SchoolShift` and `PeriodType` dropdowns (both filtered to active only). User fills the form and submits POST to `store()`. The controller validates via `validatePayload()`, applies business rules (teaching-slot coupling), creates the record, logs activity, and redirects to the tab with success flash.

**3. Edit/Update.** User clicks Edit. `edit()` gates with `.update`, loads the form pre-filled. User modifies any field and submits PUT/PATCH to `update()`. The controller validates, re-applies business rules, updates the record, logs activity with change tracking, and redirects.

**4. AJAX Reorder.** User drags a row to a new position. The frontend sends POST to `ajaxReorder` with an ordered array of config IDs. The controller validates each ID exists, then updates `display_order` for all configs in a transaction. The `slot_ord` is not modified.

**5. AJAX Update Times.** User double-clicks a start or end time cell in the grid, edits the time, and presses Enter. The frontend sends POST to `ajaxUpdateTimes` with the new `start_time` and `end_time`. The controller validates, updates the record, and returns JSON with the new times and computed `duration_minutes`.

**6. AJAX Toggle Can Be Free.** User clicks the free-period toggle on a row. The frontend sends POST to `ajaxToggleCanBeFree`. The controller checks `is_teaching_slot`. If false, returns 422 JSON error. If true, toggles `can_be_free_period`, saves, and returns JSON success.

**7. Toggle Status.** User clicks the status toggle switch. POST to `toggleStatus()`. Validates `is_active` as required|boolean, saves, returns JSON `{ success, is_active, message }`.

**8. Soft Delete.** User triggers delete. `destroy()` gates with `.delete`, sets `is_active = false`, calls `delete()`, logs activity, and redirects.

**9. View Trash.** User navigates to trash (`trashedPeriodConfig()`). Loads `PeriodConfig::onlyTrashed()->with(...)->paginate()`.

**10. Restore.** User clicks Restore. `restore()` gates with `.restore`, calls `withTrashed()->findOrFail($id)->restore()`, sets `is_active = true`, logs activity, and redirects.

**11. Force Delete.** User clicks Force Delete. `forceDelete()` gates with `.forceDelete`, calls `withTrashed()->findOrFail($id)->forceDelete()`, logs activity, and redirects.

## Validate Before Save

Validation is performed by the `validatePayload()` helper in `PeriodConfigController`:

| Field | Rule(s) | Error Message |
|-------|---------|---------------|
| `shift_id` | required, integer, exists:tt_shifts,id | — |
| `slot_ord` | nullable, integer, min:1, max:50; unique scoped `(shift_id, slot_ord)` ignoring soft-deletes and current ID on update | — |
| `code` | required, string, max:20; unique scoped `(shift_id, code)` ignoring soft-deletes and current ID on update | — |
| `short_name` | required, string, max:50 | — |
| `period_type_id` | required, integer, exists:tt_period_types,id | — |
| `start_time` | required, date_format:H:i | — |
| `end_time` | required, date_format:H:i, after:start_time | — |
| `is_teaching_slot` | sometimes, boolean | — |
| `can_be_free_period` | sometimes, boolean | — |
| `display_order` | sometimes, integer, min:1, max:50 | — |
| `is_active` | sometimes, boolean | — |

**Controller-level checks:**

| Check | Location | Action |
|-------|----------|--------|
| Non-teaching slot forces slot_ord=null | `store()` / `update()` | `if (! $data['is_teaching_slot']) { $data['slot_ord'] = null; $data['can_be_free_period'] = false; }` |
| Can-be-free only on teaching slots | `ajaxToggleCanBeFree()` | If `! $periodConfig->is_teaching_slot`, return 422 with "Only teaching slots can be marked as free periods" |

## Error Handling and Validation Messages

| Scenario | Message | Type |
|----------|---------|------|
| Missing required field (e.g., code) | "The code field is required." | Validation rule |
| Invalid FK (shift_id) | "The selected shift id is invalid." | Validation rule |
| end_time before start_time | "The end time must be a time after start time." | Validation rule (`after`) |
| Duplicate code within shift | Default unique validation message | Validation rule |
| Duplicate slot_ord within shift | Default unique validation message | Validation rule |
| Toggle can-be-free on non-teaching slot | "Only teaching slots can be marked as free periods" | 422 JSON |
| AJAX time update with end <= start | "The end time must be a time after start time." | 422 JSON |
| AJAX reorder with non-existent ID | Validation error on exists:tt_period_configs,id | 422 JSON |
| Model not found (any show/edit/update/destroy) | `ModelNotFoundException` → 404 page | 404 |
| Not authorised (any operation) | `AuthorizationException` → 403 | 403 |
| Generic database/exception on create | "Failed to create period config: <exception message>" | Controller check (500) |
| Generic database/exception on update | "Failed to update period config: <exception message>" | Controller check (500) |
| Generic database/exception on delete | "Failed to delete period config: <exception message>" | Controller check (500) |
| Toggle status validation failure | Standard Laravel validation error for "is_active" | Validation rule (AJAX JSON — 422) |

## Success Scenarios

**SC-001 — Create a Teaching Period Config.** Mrs. Gupta creates SLOT-01 for the Morning shift: code="SLOT-01", short_name="Period 1", period_type="TEACHING", start_time=07:45, end_time=08:30, is_teaching_slot=true, slot_ord=1, display_order=1. The system validates all fields, auto-computes `duration_minutes` as 45, creates the record with `is_active=true`, logs the activity, and redirects with a success flash. The new config appears in the grid grouped under Morning shift.

**SC-002 — Create a Non-Teaching Slot (Assembly).** Mrs. Gupta creates SLOT-A (Assembly) for the Morning shift: code="SLOT-A", short_name="Assembly", period_type="ASSEMBLY", start_time=07:30, end_time=07:45, is_teaching_slot=false. The controller forces `slot_ord=null` and `can_be_free_period=false`. The created record has these forced values regardless of what was submitted.

**SC-003 — AJAX Reorder Configs.** Mrs. Gupta drags SLOT-03 (Period 3) to the position before SLOT-02 (Period 2) in the grid. The frontend sends `ids=[5,3,2,1,4]` (the new order). The `ajaxReorder` endpoint validates all IDs exist, then updates `display_order` for each: id=5→1, id=3→2, id=2→3, id=1→4, id=4→5. The grid refreshes showing the new order.

**SC-004 — AJAX Toggle Can-Be-Free on Teaching Slot.** Mrs. Gupta clicks the free-period toggle on SLOT-04 (a teaching slot). The `ajaxToggleCanBeFree` endpoint flips `can_be_free_period` from false to true, returns `{success: true, can_be_free_period: true, message: "Free-period eligibility updated."}`, and the UI updates the toggle.

**SC-005 — Full Lifecycle.** Create a period config → View its details → Edit its timing → Toggle its status → Toggle can-be-free → Soft delete → Restore → Force delete. Every transition succeeds and the activity log records each state change.

## Failure Scenarios

**FC-001 — End Time Before Start Time.** Mrs. Gupta enters start_time=09:00 and end_time=08:00. The `after:start_time` validation rule catches this and returns "The end time must be a time after start time." The form is re-displayed with the error highlighted. The database CHECK constraint provides a second line of defence.

**FC-002 — Duplicate Code Within Shift.** Mrs. Gupta creates a config with code "SLOT-01" in the Morning shift where "SLOT-01" already exists for that shift. The scoped unique validation returns a default uniqueness error. The `uq_pc_shift_code` unique key provides a database-level backstop.

**FC-003 — Toggle Can-Be-Free on Non-Teaching Slot.** Mrs. Gupta clicks the free-period toggle on SLOT-A (Assembly, is_teaching_slot=false). The controller returns HTTP 422 with JSON `{success: false, message: "Only teaching slots can be marked as free periods"}`. The free-period flag remains unchanged.

**FC-004 — Delete Config Referenced by Junction (RESTRICT).** Mrs. Gupta attempts to delete SLOT-01 which is referenced by one or more `tt_period_set_periods_jnt` records. The FK constraint `fk_psp_period_config` (ON DELETE RESTRICT) blocks the deletion. The database throws an integrity constraint violation, and the controller's catch handler redirects with "Failed to delete period config: ...".

**FC-005 — Unauthorised Access.** A user without `timetable-foundation.period-config.create` attempts to access the create form. `Gate::authorize()` throws `AuthorizationException`, resulting in a 403 HTTP response.

## Dependencies module and tables

| Dependency | Type | Details |
|------------|------|---------|
| `tt_shifts` | FK parent (RESTRICT) | `shift_id` FK references `tt_shifts(id)`. A shift with period configs cannot be deleted. |
| `tt_period_types` | FK parent (RESTRICT) | `period_type_id` FK references `tt_period_types(id)`. A period type with configs cannot be deleted. |
| `tt_period_set_periods_jnt` | Child (CASCADE/RESTRICT) | `period_config_id` FK references `tt_period_configs(id)` ON DELETE RESTRICT. Junction records reference period configs and block their deletion. |
| `activityLog()` helper | Service dependency | Called on every state-changing action (destroy, restore, forceDelete, toggleStatus, ajaxToggleCanBeFree). |

**Table:** `tt_period_configs`

| Column | Type | Details |
|--------|------|---------|
| `id` | INT UNSIGNED | PK, Auto Increment |
| `shift_id` | TINYINT UNSIGNED | NOT NULL, FK → `tt_shifts(id)` ON DELETE RESTRICT |
| `slot_ord` | TINYINT UNSIGNED | NULL (null for non-teaching), UNIQUE `(shift_id, slot_ord)` |
| `code` | VARCHAR(20) | NOT NULL, UNIQUE `(shift_id, code)` |
| `short_name` | VARCHAR(50) | NOT NULL |
| `period_type_id` | TINYINT UNSIGNED | NOT NULL, FK → `tt_period_types(id)` ON DELETE RESTRICT |
| `start_time` | TIME | NOT NULL |
| `end_time` | TIME | NOT NULL, CHECK `end_time > start_time` |
| `duration_minutes` | SMALLINT UNSIGNED | GENERATED ALWAYS AS (TIMESTAMPDIFF(MINUTE, start_time, end_time)) STORED |
| `is_teaching_slot` | TINYINT(1) | NOT NULL, DEFAULT 0 |
| `can_be_free_period` | TINYINT(1) | NOT NULL, DEFAULT 0 |
| `display_order` | TINYINT UNSIGNED | NOT NULL, DEFAULT 1 |
| `is_active` | TINYINT(1) | NOT NULL, DEFAULT 1 |
| `created_at` | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |
| `updated_at` | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP |
| `deleted_at` | TIMESTAMP | NULL (soft delete) |

**Unique Keys:**
- `uq_pc_shift_ord` — on `(shift_id, slot_ord)` (except NULLs)
- `uq_pc_shift_code` — on `(shift_id, code)`
