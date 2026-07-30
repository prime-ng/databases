# Period Configuration — Business Requirements

## What This Screen Does

Period Configuration defines the school's daily timeslot grid that all timetables use. It encompasses four layers of data: Period Types (what kind of time block each slot is), Period Configs (the master list of fixed start/end times per shift), Period Sets (which range of those slots a class group uses), and Period Set Periods (the junction mapping individual configs into a set, with optional period-type overrides). Together they determine **when** classes run and **what type** each time block is.

## When This Screen Is Used

- During initial school setup when the administrator defines the school's daily schedule structure — how many periods per day, their start/end times, and which periods are breaks vs instructional
- When adding a new shift (e.g., Afternoon shift) that requires its own set of period timings
- When creating different daily schedules for different class groups (e.g., Standard 8-period day for 3rd–12th, Toddler 6-period day for BV1–2nd, Half Day for special events)
- When a period type needs to be added, modified, or deactivated (e.g., adding a new "Sports" period type)
- When the school wants to mark certain teaching slots as available for free periods
- When the scheduling solver reads period configs and period sets as inputs for timetable generation

## Default Data Load

The screen loads via the **Timetable Masters** page accessed at `timetable-foundation.menu.timetableMasters` with tab parameter `?tab=period-types`, `?tab=period-configs`, `?tab=period-sets`, or `?tab=period-set-periods`. Each tab is rendered by its respective controller's `index()` method, which redirects to the menu route. Default data load includes:

- **Period Types tab (`PeriodTypeController@index`):** Paginated list of all `tt_period_types` records (10 per page) with code, name, colour swatch, ordinal, duration, and status toggle
- **Period Configs tab (`PeriodConfigController@index`):** Paginated list of `tt_period_configs` records ordered by `shift_id`, `display_order`, `slot_ord` (10 per page) — each row shows code, short name, period type badge, start/end times, duration, teaching-slot and can-be-free indicators, and status toggle
- **Period Sets tab (`PeriodSetController@index`):** Paginated list of `tt_period_sets` records (10 per page) with code, name, shift, range, totals, default indicator, and status toggle
- **Period Set Periods tab (`PeriodSetPeriodController@index`):** Paginated list of `tt_period_set_periods_jnt` records (10 per page) with period set, period config, period_ord, code, short name, and period type

## Key Fields at a Glance

**Period Types (`tt_period_types`)**

| Column | Description |
|--------|-------------|
| `code` | Machine identifier: THEORY, TEACHING, PRACTICAL, BREAK, LUNCH, ASSEMBLY, EXAM, RECESS, FREE |
| `name` | Display name for the period type |
| `color_code` | Hex colour for UI badge display (e.g., `#FF0000`) |
| `icon` | Font Awesome or CSS class for visual icon |
| `is_schedulable` | Whether activities can be assigned to this period type |
| `counts_as_teaching` | Whether this type counts toward teacher teaching load |
| `counts_as_workload` | Whether this type counts toward teacher workload calculation |
| `is_break` | Whether this is a break/lunch/non-instructional period |
| `is_free_period` | Whether this period type can be used as a free period (no activity assigned) |
| `ordinal` | Display sort order (unique) |
| `duration_minutes` | Suggested default duration in minutes |

**Period Configs (`tt_period_configs`)**

| Column | Description |
|--------|-------------|
| `shift_id` | Which operational shift (Morning/Afternoon/Evening) this timeslot belongs to |
| `slot_ord` | Sequential teaching-slot order (1,2,3...12). NULL for non-teaching slots |
| `code` | Machine-readable slot code: SLOT-01, SLOT-02, etc. |
| `short_name` | Display label: "Assembly", "Period 1", "Short Break", "Lunch" |
| `period_type_id` | Default period type (Teaching, Break, Lunch, Assembly) |
| `start_time` | Fixed start time for this slot (e.g., 07:45:00) |
| `end_time` | Fixed end time for this slot (e.g., 08:30:00) |
| `duration_minutes` | Auto-calculated as `TIMESTAMPDIFF(MINUTE, start_time, end_time)` — generated column, never written |
| `is_teaching_slot` | Whether this slot is a teaching period (for quick filtering) |
| `can_be_free_period` | Whether this slot can be used as a free period in some period sets (v7.8) |
| `display_order` | UI display order independent of `slot_ord` |

**Period Sets (`tt_period_sets`)**

| Column | Description |
|--------|-------------|
| `code` | Machine code: STANDARD_8P, HALF_DAY_4P, TODDLER_6P |
| `name` | Display name for the period set |
| `shift_id` | Which shift's timing grid this set uses |
| `from_period_ord` | First `slot_ord` from `tt_period_configs` in range |
| `to_period_ord` | Last `slot_ord` from `tt_period_configs` in range |
| `total_periods` | Total period count including breaks |
| `teaching_periods` | Count of teaching periods |
| `exam_periods` | Count of exam periods |
| `free_periods` | Count of free periods |
| `is_default` | Whether this is the default period set (only one allowed) |

**Period Set Periods (`tt_period_set_periods_jnt`)**

| Column | Description |
|--------|-------------|
| `period_set_id` | Parent period set |
| `period_config_id` | Reference to the master timeslot — timing is inherited from here |
| `period_ord` | Ordinal within this period set (1,2,3...) |
| `code` | Period code within this set: P-1, P-2, BRK, LUNCH |
| `short_name` | Display name: "Period-1", "Break", "Lunch" |
| `period_type_id` | Period type — can override the config's default type |

## Business Rules and Conditions

**Break Period Mutual Exclusion.** When a period type has `is_break = true`, the system MUST force `is_schedulable`, `counts_as_teaching`, and `counts_as_workload` to `false`. Break periods (BREAK, LUNCH, RECESS) are non-instructional — they cannot have activities scheduled and do not count toward teaching loads.

**Generated Duration Column.** `duration_minutes` in `tt_period_configs` is a `GENERATED ALWAYS AS (TIMESTAMPDIFF(MINUTE, start_time, end_time)) STORED` column. The application MUST never write to this column — it is guarded against mass assignment and is read-only in the UI.

**End Time After Start Time.** For every `tt_period_configs` row, `end_time` MUST be strictly greater than `start_time`. Zero-duration and negative-duration slots are invalid, enforced by a CHECK constraint and server-side validation rule `after:start_time`.

**Only One Default Period Set.** At any time, at most one period set can have `is_default = true`. Setting a period set as default automatically removes the default flag from any previously-default set. The default set cannot be deleted or disabled.

**Period Set Defines Range, Not Timing (v7.7).** Period Sets do not store start/end times. They reference `shift_id`, `from_period_ord`, and `to_period_ord` to select a contiguous range of `slot_ord` values from `tt_period_configs`. Actual day start/end times are derived from the period configs in the range.

**Shift Consistency Across Entities.** A period config and a period set belong to exactly one shift each. When creating a Period Set Period (junction), the `period_config_id`'s shift MUST match the `period_set_id`'s shift. Cross-shift associations are invalid.

**Teaching Slot / Can-Be-Free-Period Coupling.** Only teaching slots (`is_teaching_slot = true`) can have `can_be_free_period = true`. Setting `is_teaching_slot = false` forces `can_be_free_period = false`.

**System Record Protection (Period Types).** System period types (seeded records like THEORY, TEACHING, PRACTICAL, BREAK, LUNCH) have immutable core behaviour fields (`code`, `is_break`, `is_schedulable`, `counts_as_teaching`, `counts_as_workload`). These records cannot be deleted or force-deleted.

**Sync Range Additive Behaviour (v7.7).** When the `from_period_ord` / `to_period_ord` range on a Period Set is widened, the system automatically adds period configs that newly fall within the range to the junction. This operation is additive only — it does not remove existing junction rows that fall outside the narrowed range.

**Solver / Timetable Integration.** Period Configs provide absolute start/end times of each slot. Period Sets determine which range of slots a class group uses. Period Set Periods provide the ordered list of slots for a specific class + timetable type. Period Types determine slot behaviour (schedulable, teaching, workload, break, free). These four entities together form the timing inputs to the SmartTimetable solver.

## Workflow Steps

**Define Period Types.** The administrator navigates to Timetable Masters → Period Types tab and creates period classifications. For each type, they set a code (e.g., "THEORY"), name, colour code for visual display, six behavioural flags (is_schedulable, counts_as_teaching, counts_as_workload, is_break, is_free_period), ordinal, and default duration. System records are seeded automatically and have restricted editability.

**Define Period Configs (Master Timeslot Grid).** The administrator selects a shift (e.g., Morning) and creates each timeslot of the school day: SLOT-01 (Assembly, 07:30–07:45), SLOT-02 (Period 1, 07:45–08:30), continuing through all teaching and non-teaching slots. Each config specifies start time, end time, period type, whether it is a teaching slot, and whether it can be used as a free period. The duration is computed automatically. The administrator can reorder slots via drag-and-drop and update times inline via AJAX.

**Define Period Sets.** The administrator creates groupings such as "Standard 8-Period Day" for 3rd–12th classes and "Toddler 6-Period Day" for younger classes. For each set, they select a shift, specify the range of period configs (from/to slot_ord), and the system auto-populates the junction records. The administrator can mark one set as default, which is used when no specific set is assigned to a class.

**Map Period Set Periods.** Within a period set, the administrator can optionally override the period type for individual slots (e.g., marking a TEACHING slot as FREE for certain class groups). This is managed through the inline editing table on the period set edit page, where rows show period_ord, code, short_name, period_type_id, and the is_active toggle.

## Example Scenario

Mr. Sharma, the timetable administrator at Gurukul Academy, is setting up the timetable foundation for the new academic year. He first ensures the nine standard period types are present (THEORY, TEACHING, PRACTICAL, BREAK, LUNCH, ASSEMBLY, EXAM, RECESS, FREE). He then creates a Morning Shift period config grid with 12 slots: Assembly (07:30–07:45), Periods 1–8 (08:30–14:45), two short breaks, and lunch. He verifies that `duration_minutes` is auto-calculated for each slot.

Next, he creates two period sets: "STANDARD_8P" (from slot_ord=1 to slot_ord=12, covering all 12 slots) for classes 3rd–12th, and "TODDLER_6P" (from slot_ord=3 to slot_ord=11) for BV1–2nd. He marks "STANDARD_8P" as the default. He widens the TODDLER range from 3–10 to 3–11, and the system auto-adds the newly in-range config SLOT-11 to the junction.

For the EXAM period set, he overrides the period type on SLOT-01 through SLOT-12 from TEACHING to EXAM, ensuring exam days use the same timing grid with exam-appropriate period types.

## Related Screens

- **Shifts Master** — defines the operational shifts (Morning, Afternoon, Evening) that Period Configs and Period Sets reference via `shift_id`
- **Class Timetable Types** — assigns period sets to class+section+timetable-type combinations, which is the consumer of period set definitions
- **Timetable Types** — defines the types of timetables (Standard, Exam, etc.) that period sets can be assigned to
- **Timetable Preparation → Requirement Consolidation** — downstream process that reads the period configuration data as context for slot requirement generation

## Requirements

- `PeriodTypeController` (361 lines) handles CRUD + toggleStatus + trash/restore/forceDelete for `tt_period_types`. Key methods: `store()` (lines 50–100) validates and creates period types with break mutual-exclusion logic; `update()` (lines 180–230) enforces system-record protection; `destroy()` (lines 233–270) blocks deletion of system records; `toggleStatus()` (lines 320–340) returns JSON 403 for system records.
- `PeriodConfigController` (307 lines) handles CRUD + AJAX endpoints for `tt_period_configs`. Key methods: `store()` (lines 40–60) forces `slot_ord=null` and `can_be_free_period=false` when `is_teaching_slot=false`; `ajaxUpdateTimes()` (lines 150–180) validates `after:start_time` and returns updated duration; `ajaxToggleCanBeFree()` (lines 200–220) returns 422 if not a teaching slot; `ajaxReorder()` (lines 250–280) updates `display_order` only.
- `PeriodSetController` (992 lines) handles CRUD + AJAX endpoints for `tt_period_sets`. Key methods: `store()` (lines 100–140) enforces default uniqueness; `update()` (lines 300–500) syncs junction records, updates derived counters, auto-adds in-range configs; `ajaxSyncRange()` (lines 690–710) persists range change and triggers auto-add; `ajaxPeriodConfigs()` (lines 750–800) returns filtered configs for the picker; `autoAddInRangeConfigs()` (lines 773–834) adds newly-in-range configs additive-only.
- `PeriodSetPeriodController` (320 lines) handles CRUD for `tt_period_set_periods_jnt`. Key methods: `store()` (lines 70–100) enforces shift consistency check and total period cap; `update()` (lines 190–230) enforces same checks.
- All four controllers use explicit `Gate::authorize()` calls for each method. Permission strings follow the pattern `timetable-foundation.{resource}.{action}` where resource is `period-type`, `period-config`, `period-set`, or `period-set-period`.
- All four models use `SoftDeletes` trait. The `PeriodConfig` model guards `duration_minutes` from mass assignment. The `PeriodSet` model has accessor methods `getDayStartTimeAttribute()` and `getDayEndTimeAttribute()` that query the `periodConfigs()` relationship.
- Validation is handled via inline `$request->validate()` in `SchoolShiftController` (not a dedicated Form Request) and inline validation in controller methods for the other three entities.
- Activity logging is implemented on all write operations (create, update, destroy, restore, forceDelete, toggleStatus) via `activityLog()` helper.
- Routes under `timetable-foundation` prefix: `period-type.*` (lines 162–166), `period-config.*` (lines 169–176), `period-set-period.*` (lines 181–186), `period-set.*` (lines 190–196) in `web.php`.

## Who Can Access

| Gate/Permission | Methods | Notes |
|-----------------|---------|-------|
| `timetable-foundation.period-type.*` | All PeriodTypeController methods | viewAny, view, create, update, delete, restore, forceDelete — full CRUD |
| `timetable-foundation.period-config.*` | All PeriodConfigController methods | Full CRUD including AJAX endpoints |
| `timetable-foundation.period-set.*` | All PeriodSetController methods | Full CRUD including AJAX endpoints |
| `timetable-foundation.period-set-period.*` | All PeriodSetPeriodController methods | Full CRUD |
| Policy | Each entity has its own Policy class (e.g., `PeriodTypePolicy`, `PeriodConfigPolicy`, `PeriodSetPolicy`, `PeriodPolicy`) | Registered in `TimetableFoundationServiceProvider::registerPolicies()` |

## Logic Flow

**Page Load (any tab).** User navigates to `timetable-foundation.menu.timetableMasters?tab=<tab>`. The `TimetableFoundationController@timetableMasters()` method loads the shared layout and renders the active tab. Each tab's content is fetched via the resource controller's `index()` method, which gates with `viewAny`, then redirects to the menu route. The view renders a paginated table (10 records per page) with the entity's columns.

**Create (any entity).** User clicks "Add New" on the tab. The `create()` method gates with `.create`, renders the create form. User fills in fields and submits POST to `store()`. The controller validates, enforces business rules (break mutual exclusion, shift consistency, teaching-slot coupling, default uniqueness), creates the record, logs activity, and redirects to the tab with a success flash.

**Edit/Update.** User clicks "Edit" on a record. The `edit()` method gates with `.update`, renders the edit form with pre-filled data. System records have restricted editable fields. User modifies and submits PUT/PATCH to `update()`. The controller validates, re-applies business rules, handles conditional logic (e.g., default set uniqueness, system record protection), updates the record, logs activity with change tracking, and redirects.

**Inline AJAX Operations (Period Configs).** The period config tab supports three AJAX operations: `ajaxReorder` updates `display_order` via drag-and-drop; `ajaxUpdateTimes` accepts `start_time` and `end_time` and returns the updated `duration_minutes`; `ajaxToggleCanBeFree` toggles the free-period flag (rejected with 422 if not a teaching slot).

**Sync Range (Period Set).** The `ajaxSyncRange` endpoint accepts a new `from_period_ord` / `to_period_ord`. It updates the range, then calls `autoAddInRangeConfigs()` which finds configs within the new range not yet in the junction and creates them. This is additive — existing out-of-range rows are preserved.

**Delete.** User clicks "Trash" on a record. The `destroy()` method gates with `.delete`, deactivates (`is_active=false`) if applicable, calls `delete()` for soft deletion, logs activity, and redirects. System records (Period Types) are protected from deletion. The default Period Set cannot be deleted.

**Restore / Force Delete.** User navigates to the trash view via `trashed*()` method, gates with `.restore`, shows soft-deleted records. User clicks "Restore" to call `restore()` (reactivates `is_active=true`), or "Force Delete" to call `forceDelete()`. Both log activity.

## Validate Before Save

**Period Type (store/update)**

| Field | Rule(s) | Error Message |
|-------|---------|---------------|
| `code` | required, string, max:30, unique (soft-deletes ignored) | "The code has already been taken." |
| `name` | required, string, max:100 | "The name field is required." |
| `color_code` | nullable, string, max:10, regex:/^#([A-Fa-f0-9]{6}\|[A-Fa-f0-9]{3})$/ | "The color code must be a valid hex color." |
| `ordinal` | required, integer, min:1, unique | "The ordinal has already been taken." |
| `duration_minutes` | required, integer, min:1 | "The duration minutes must be at least 1." |
| `is_break`, `is_schedulable`, etc. | boolean | — |

**Period Config (store/update)**

| Field | Rule(s) | Error Message |
|-------|---------|---------------|
| `shift_id` | required, integer, exists:tt_shifts,id | — |
| `code` | required, string, max:20, unique per shift | "The code has already been taken." |
| `short_name` | required, string, max:50 | — |
| `period_type_id` | required, integer, exists:tt_period_types,id | — |
| `start_time` | required, date_format:H:i | — |
| `end_time` | required, date_format:H:i, after:start_time | "The end time must be a time after start time." |
| `slot_ord` | nullable, integer, min:1, unique per shift | — |
| `is_teaching_slot` | sometimes, boolean | — |
| `can_be_free_period` | sometimes, boolean | — |

**Period Set (store/update)**

| Field | Rule(s) | Error Message |
|-------|---------|---------------|
| `code` | required, string, max:30, regex:/^[A-Z0-9_]+$/, unique | "The code has already been taken." |
| `name` | required, string, max:100 | — |
| `shift_id` | required, integer, exists:tt_shifts,id | — |
| `from_period_ord` | required, integer, min:1, max:50 | — |
| `to_period_ord` | required, integer, min:1, max:50, gte:from_period_ord | "The to period ord must be greater than or equal to from period ord." |
| `teaching_periods` | required, integer, min:0, lte:total_periods | — |
| `is_default` | nullable, boolean | — |

**Period Set Period (store/update)**

| Field | Rule(s) | Error Message |
|-------|---------|---------------|
| `period_set_id` | required, exists:tt_period_sets,id | — |
| `period_config_id` | required, exists:tt_period_configs,id | — |
| `period_type_id` | required, exists:tt_period_types,id | — |
| `code` | required, string, max:20, unique per set | "The code has already been taken." |
| `period_ord` | required, integer, min:1, unique per set | "The period ord has already been taken." |

## Error Handling and Validation Messages

| Scenario | Message | Type |
|----------|---------|------|
| System period type edit with core field change | Core fields silently unset from validated data | Controller logic |
| Delete system period type | Redirect with error: deletion blocked | 302 Redirect |
| Toggle status on system period type | JSON `{ "success": false, "message": "Unauthorized." }` | 403 JSON |
| Toggle can-be-free on non-teaching slot | "Only teaching slots can be marked as free periods" | 422 JSON |
| Cross-shift junction creation | "Selected timeslot belongs to a different shift" | Validation error |
| Junction count exceeds total_periods | "Maximum periods reached for this period set" | Validation error |
| Default set toggle to inactive | 403 Forbidden | 403 JSON |
| AJAX time update with end <= start | "The end time must be a time after start time." | 422 JSON |
| Model not found (any show/edit/update/destroy) | `ModelNotFoundException` → 404 page | 404 |
| Not authorised (any operation) | `AuthorizationException` → 403 | 403 |

## Success Scenarios

**SC-001 — Create New Period Type.** Mrs. Gupta, the administrator, adds a new "SPORTS" period type with `is_schedulable=true`, `counts_as_teaching=false`, `counts_as_workload=false`, `is_break=false`. The system validates the unique code, creates the record with `is_active=true`, logs the activity, and redirects to the period types tab with a success flash. The new type appears in the grid with a status toggle set to active.

**SC-002 — Widen Period Set Range (Sync Range).** Mr. Sharma widens the "TODDLER_6P" period set range from slot_ord 3–10 to slot_ord 3–11. The system updates `from_period_ord` and `to_period_ord`, then identifies SLOT-11 as newly in-range. It creates a new `tt_period_set_periods_jnt` row with the config's default period type. The existing out-of-range rows (none in this case) are preserved. The response confirms the range was updated with 1 auto-added config.

**SC-003 — Inline Time Update.** Mrs. Gupta changes the start time of SLOT-02 from 07:45 to 07:50 via the AJAX inline time editor. The system validates `after:start_time` (end_time is 08:30, so 07:50 is valid), updates the record, and returns the new `start_time`, `end_time`, and `duration_minutes` (now 40 minutes). The grid refreshes to show the updated values.

**SC-004 — Mark Default Period Set.** Mr. Sharma creates "STANDARD_8P" and sets `is_default=true`. The system runs `PeriodSet::where('is_default', true)->update(['is_default' => false])` before saving the new record. "STANDARD_8P" is saved with `is_default=true` and is the only default. Later attempts to delete or disable it are rejected with a 403.

## Failure Scenarios

**FC-001 — Break Flag Without Unsetting Teaching Flags.** Mrs. Gupta creates a period type with `is_break=true`, `is_schedulable=true`, `counts_as_teaching=true`. The controller forces `is_schedulable=false`, `counts_as_teaching=false`, `counts_as_workload=false` before saving. The saved record has the correct break-only flags despite the input values.

**FC-002 — Delete System Period Type.** Mr. Sharma attempts to delete the "THEORY" period type. The controller detects `is_system` on the record and redirects with an error: "Cannot delete a system period type." The record remains in the database.

**FC-003 — Cross-Shift Junction.** A period config from the Afternoon shift is mapped into a period set configured for the Morning shift. The controller compares `(int)$periodConfig->shift_id !== (int)$periodSet->shift_id` and returns a validation error: "Selected timeslot belongs to a different shift."

**FC-004 — End Time Before Start Time.** A period config is created with start=09:00, end=08:00. The database CHECK constraint `chk_pc_time` and the server-side `after:start_time` validation both reject the record. The user sees a validation error message.

**FC-005 — Toggle Can-Be-Free on Non-Teaching Slot.** A break slot (SLOT-04, Short Break 1) is toggled via AJAX to set `can_be_free_period=true`. The controller checks `is_teaching_slot` — it is `false`, so it returns HTTP 422 with "Only teaching slots can be marked as free periods."

## Dependencies module and tables

| Dependency | Type | Details |
|------------|------|---------|
| `tt_shifts` | FK parent | Referenced by `tt_period_configs.shift_id` (ON DELETE RESTRICT) and `tt_period_sets.shift_id` (ON DELETE RESTRICT) |
| `tt_period_types` | FK parent | Referenced by `tt_period_configs.period_type_id` (ON DELETE RESTRICT) and `tt_period_set_periods_jnt.period_type_id` (ON DELETE RESTRICT) |
| `tt_period_configs` | FK parent | Referenced by `tt_period_set_periods_jnt.period_config_id` (ON DELETE RESTRICT) |
| `tt_period_sets` | FK parent | Referenced by `tt_period_set_periods_jnt.period_set_id` (ON DELETE CASCADE) — if a period set is deleted, its junction rows are cascade-deleted |
| SmartTimetable solver | Consumer | Reads period configs, period sets, period set periods, and period types as timing and slot-behaviour inputs |
| `tt_class_timetable_types_jnt` | Consumer | Links period sets to class+timetable-type combinations |

**Table:** `tt_period_types`

| Column | Type | Details |
|--------|------|---------|
| `id` | TINYINT UNSIGNED | PK, Auto Increment |
| `code` | VARCHAR(30) | NOT NULL, UNIQUE |
| `name` | VARCHAR(100) | NOT NULL |
| `description` | VARCHAR(255) | DEFAULT NULL |
| `color_code` | VARCHAR(10) | DEFAULT NULL |
| `icon` | VARCHAR(50) | DEFAULT NULL |
| `is_schedulable` | TINYINT(1) | NOT NULL, DEFAULT 1 |
| `counts_as_teaching` | TINYINT(1) | NOT NULL, DEFAULT 0 |
| `counts_as_workload` | TINYINT(1) | NOT NULL, DEFAULT 0 |
| `is_break` | TINYINT(1) | NOT NULL, DEFAULT 0 |
| `is_free_period` | TINYINT(1) | NOT NULL, DEFAULT 0 |
| `ordinal` | TINYINT UNSIGNED | NOT NULL, UNIQUE |
| `duration_minutes` | INT UNSIGNED | DEFAULT 30 |
| `is_active` | TINYINT(1) | NOT NULL, DEFAULT 1 |
| `created_at` | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |
| `updated_at` | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP ON UPDATE |
| `deleted_at` | TIMESTAMP | NULL |

**Table:** `tt_period_configs`

| Column | Type | Details |
|--------|------|---------|
| `id` | INT UNSIGNED | PK, Auto Increment |
| `shift_id` | TINYINT UNSIGNED | NOT NULL, FK → `tt_shifts(id)` ON DELETE RESTRICT |
| `slot_ord` | TINYINT UNSIGNED | NULL, UNIQUE(shift_id, slot_ord) |
| `code` | VARCHAR(20) | NOT NULL, UNIQUE(shift_id, code) |
| `short_name` | VARCHAR(50) | NOT NULL |
| `period_type_id` | TINYINT UNSIGNED | NOT NULL, FK → `tt_period_types(id)` ON DELETE RESTRICT |
| `start_time` | TIME | NOT NULL |
| `end_time` | TIME | NOT NULL, CHECK(end_time > start_time) |
| `duration_minutes` | SMALLINT UNSIGNED | GENERATED ALWAYS AS (TIMESTAMPDIFF(MINUTE, start_time, end_time)) STORED |
| `is_teaching_slot` | TINYINT(1) | NOT NULL, DEFAULT 0 |
| `can_be_free_period` | TINYINT(1) | NOT NULL, DEFAULT 0 |
| `display_order` | TINYINT UNSIGNED | NOT NULL, DEFAULT 1 |
| `is_active` | TINYINT(1) | NOT NULL, DEFAULT 1 |
| `created_at` | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |
| `updated_at` | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP ON UPDATE |
| `deleted_at` | TIMESTAMP | NULL |

**Table:** `tt_period_sets`

| Column | Type | Details |
|--------|------|---------|
| `id` | INT UNSIGNED | PK, Auto Increment |
| `code` | VARCHAR(30) | NOT NULL, UNIQUE |
| `name` | VARCHAR(100) | NOT NULL |
| `description` | VARCHAR(255) | DEFAULT NULL |
| `shift_id` | TINYINT UNSIGNED | NOT NULL, FK → `tt_shifts(id)` ON DELETE RESTRICT |
| `from_period_ord` | TINYINT UNSIGNED | NOT NULL |
| `to_period_ord` | TINYINT UNSIGNED | NOT NULL, CHECK(to >= from) |
| `total_periods` | TINYINT UNSIGNED | NOT NULL |
| `teaching_periods` | TINYINT UNSIGNED | NOT NULL |
| `exam_periods` | TINYINT UNSIGNED | NOT NULL |
| `free_periods` | TINYINT UNSIGNED | NOT NULL |
| `is_default` | TINYINT(1) | DEFAULT 0 |
| `is_active` | TINYINT(1) | NOT NULL, DEFAULT 1 |
| `created_at` | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |
| `updated_at` | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP ON UPDATE |
| `deleted_at` | TIMESTAMP | NULL |

**Table:** `tt_period_set_periods_jnt`

| Column | Type | Details |
|--------|------|---------|
| `id` | INT UNSIGNED | PK, Auto Increment |
| `period_set_id` | INT UNSIGNED | NOT NULL, FK → `tt_period_sets(id)` ON DELETE CASCADE |
| `period_config_id` | INT UNSIGNED | NOT NULL, FK → `tt_period_configs(id)` ON DELETE RESTRICT |
| `period_ord` | TINYINT UNSIGNED | NOT NULL, UNIQUE(set_id, period_ord) |
| `code` | VARCHAR(20) | NOT NULL, UNIQUE(set_id, code) |
| `short_name` | VARCHAR(50) | NOT NULL |
| `period_type_id` | TINYINT UNSIGNED | NOT NULL, FK → `tt_period_types(id)` ON DELETE RESTRICT |
| `is_active` | TINYINT(1) | NOT NULL, DEFAULT 1 |
| `created_at` | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |
| `updated_at` | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP ON UPDATE |
| `deleted_at` | TIMESTAMP | NULL |
