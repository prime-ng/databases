# Period Sets — Business Requirements

## What This Screen Does

Period Sets define which range of period configs a particular class group uses for its daily schedule. A period set references a shift and selects a contiguous range of `slot_ord` values (e.g., slot_ord 1 through 12) from that shift's period configs, establishing how many total periods, teaching periods, exam periods, and free periods the set contains. Period sets are the bridge between the master timeslot grid (Period Configs) and the class-level schedule — each class + timetable type combination is assigned a period set that determines its daily timing template.

The screen provides full CRUD for period sets, an AJAX endpoint to fetch period configs tagged with range membership, and an AJAX sync-range operation that widens/narrows the range and auto-adds newly in-scope configs to the junction.

## When This Screen Is Used

- **Creating daily schedule templates** — When the administrator defines the standard set of periods for a class group (e.g., "Standard 8-Period Day" for 3rd–12th, "Toddler 6-Period Day" for BV1–2nd).
- **Defining half-day or special schedules** — When a school needs a reduced set of periods for half days, exam days, sports days, or special events.
- **Setting a default period set** — When the administrator marks one set as the default, used when no specific set is assigned to a class group.
- **Adjusting the range of periods** — When a class group's schedule changes (e.g., adding an extra period or removing a break slot), the administrator widens or narrows the period set's range.
- **Feeding downstream timetabling** — Period sets are consumed by `tt_class_timetable_types_jnt` (which assigns sets to classes) and by the Requirement Consolidation module for slot requirement generation.

## Default Data Load

The screen is one of four tabs on the **Timetable Masters** page, accessed at `timetable-foundation.menu.timetableMasters` with tab parameter `?tab=period-sets#period-sets`. The `PeriodSetController@index` method gates on `timetable-foundation.period-set.viewAny` and redirects to the menu route.

The default data load includes:

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| Period Sets Grid | `index()` → `timetableMasters()` | `PeriodSet::with('shift')->orderBy('name')` | None | Default page size |
| Shared: Shifts (create/edit) | `create()` / `edit()` | `SchoolShift::where('is_active', true)->orderBy('ordinal')->get()` | is_active=true | None |
| Shared: Period Configs (edit) | `edit()` | `PeriodConfig::with('periodType')->where('shift_id', X)->where('is_active', true)->ordered()` | shift_id, is_active | None |
| Period Configs AJAX | `ajaxPeriodConfigs()` | `PeriodConfig::where('shift_id', $shiftId)->ordered()->get()` with `in_range` and `teaching_slot_count` computed | shift_id | None |

## Key Fields at a Glance

**Identity and Classification**

- **Code** — A machine-readable identifier such as `STANDARD_8P` or `HALF_DAY_4P`. Must be uppercase letters, digits, and underscores only (regex: `^[A-Z0-9_]+$`). Globally unique across all period sets.
- **Name** — The human-readable display name, e.g., "Standard 8-Period Day".
- **Description** — An optional note explaining the purpose or usage of the period set.
- **Shift** — Which shift's timing grid this set uses. All period configs within the set come from this shift's master configs.

**Period Range and Counts**

- **From Period Ordinal** — The first `slot_ord` value from the shift's period configs that is included in this set (e.g., 1).
- **To Period Ordinal** — The last `slot_ord` value included (e.g., 12). Must be greater than or equal to `from_period_ord` and cannot exceed the shift's total teaching slot count.
- **Total Periods** — The total number of period slots in this set, including both teaching and non-teaching periods.
- **Teaching Periods** — How many of the total periods are actual teaching periods.
- **Exam Periods** — How many periods are reserved for exams.
- **Free Periods** — How many periods are marked as free periods.

**Status Flags**

- **Is Default** — Whether this set is the default period set. Only one set can be default at a time. The default set cannot be deleted, force-deleted, or deactivated.
- **Active Status** — Whether the set is enabled and available for assignment to classes.

**Junction Records (`tt_period_set_periods_jnt`)**

Each period set has a one-to-many relationship with `tt_period_set_periods_jnt`, the junction table that links a period set to its individual period configs. Each junction record stores:
- `period_ord` — The ordinal within this set (1, 2, 3…)
- `code` — A period code within the set (e.g., P-1, BRK)
- `short_name` — A display name within the set
- `period_type_id` — The period type, which can override the config's default type

## Business Rules and Conditions

**Code Format Constraint.** The `code` field must consist of uppercase letters (A–Z), digits (0–9), and underscores only. Lowercase letters, hyphens, spaces, and special characters are rejected. This is enforced by the regex rule `/^[A-Z0-9_]+$/`. The controller also normalises the code to uppercase via `strtoupper()`.

**Unique Code.** Each period set must have a globally unique code. Enforced by a database unique index `uq_periodset_code` on `tt_period_sets.code` and by the `unique:tt_period_sets,code` validation rule (ignoring the current record's ID on update).

**Range Constraints.** The `to_period_ord` must be greater than or equal to `from_period_ord`. Additionally, `to_period_ord` cannot exceed the shift's total teaching slot count. A custom validation rule checks this: if the shift has 8 teaching slots, `to_period_ord` cannot be 10.

**Only One Default Period Set.** At any time, at most one period set can have `is_default = true`. When a set is created or updated with `is_default = true`, the controller runs `PeriodSet::where('is_default', true)->update(['is_default' => false])` before saving the new default. The default set is protected from deletion, force-deletion, and deactivation.

**Period Counts Consistency.** `teaching_periods` must be less than or equal to `total_periods`. This is enforced by `lte:total_periods` validation. All period counts (total, teaching, exam, free) are user-defined at create time but can be recalculated from junction contents via `syncDerivedCountersFromJunction()` during updates.

**Additive Range Sync (v7.7).** When the `from_period_ord` / `to_period_ord` range is widened, the system automatically adds period configs that newly fall within the range to the junction table. This operation is additive only — existing junction rows that fall outside the narrowed range are preserved (not removed).

**Two-Pass Ordinal Swapping.** When updating junction rows, if period ordinals are swapped (e.g., ord 2 and ord 3), the controller uses a two-pass approach: in Pass 1, it parks values above the maximum ordinal to avoid unique constraint collisions; in Pass 2, it writes the final ordinals.

**Deactivation Before Soft Delete.** When a period set is deleted, the controller sets `is_active = false` before calling `delete()`. The default set is protected: attempting to delete or deactivate it returns an error.

**Restore Reactivates.** When a soft-deleted period set is restored, the controller sets `is_active = true` after the restore.

## Workflow Steps

**Viewing the Period Sets Grid.** The administrator navigates to Timetable Masters → Period Sets tab. The grid displays all period sets with their code, name, shift badge, from/to period range, total/teaching/exam/free period counts, default indicator (badge), and status toggle.

**Creating a Period Set.** The administrator clicks "Add Period Set", enters the code, name, description, selects a shift, sets the from/to period ordinal range, and enters the period counts. The administrator can optionally select individual period configs to include in the set (which auto-creates junction records). Also optionally marks the set as default. On save, the controller validates, normalises the code to uppercase, enforces default uniqueness, creates junction rows if config IDs were provided, logs activity, and redirects.

**Editing a Period Set — Basic Fields.** The administrator edits the code, name, description, shift, range, and counts. During update, the controller handles picker membership sync (if `selected_period_config_ids` is submitted) or auto-adds in-range configs (if the picker is not submitted). It also syncs derived counters from the actual junction contents.

**Editing a Period Set — Inline Period Management.** On the edit page, the administrator sees a table of junction rows (period configs in the set). Each row shows period_ord, code, short_name, period_type_id, and is_active toggle. The administrator can edit individual rows, reorder them, or remove them. The two-pass swap algorithm handles ordinal changes without unique constraint violations.

**AJAX Fetch Period Configs.** On the edit page (and other screens that need to show available configs), the `ajaxPeriodConfigs` endpoint is called with a `shift_id`. It returns all period configs for that shift, each tagged with `in_range` (whether it falls within the current from/to range) and `teaching_slot_count` (the number of teaching slots in the shift).

**AJAX Sync Range.** On the edit page, the administrator can adjust the `from_period_ord` / `to_period_ord` range via an AJAX POST to `ajaxSyncRange`. The controller updates the range, calls `autoAddInRangeConfigs()` to add newly-in-range configs, and returns JSON with the count of added configs.

**Marking a Period Set as Default.** The administrator toggles `is_default = true` on create or edit. The controller automatically clears the default flag from any previously-default set. Once marked as default, the set cannot be deleted, force-deleted, or deactivated.

## Example Scenario

Mr. Sharma, the timetable administrator at Gurukul Academy, creates three period sets for the new academic year:

1. **STANDARD_8P** (Standard 8-Period Day): code = `STANDARD_8P`, shift = Morning, from = 1, to = 12, total = 12, teaching = 8, exam = 0, free = 0. He marks this as the default set. He provides `period_config_ids` for all 12 configs in the shift, and the system creates 12 junction records automatically.

2. **TODDLER_6P** (Toddler 6-Period Day): code = `TODDLER_6P`, shift = Morning, from = 3, to = 10, total = 6, teaching = 5, exam = 0, free = 1. This set uses a subset of the morning shift configs, skipping assembly and the first period.

3. **HALF_DAY** (Half-Day Schedule): code = `HALF_DAY`, shift = Morning, from = 1, to = 6, total = 4, teaching = 3, exam = 1, free = 0. This set is used for half-day schedules during special events.

Later, Mr. Sharma widens the TODDLER range from 3–10 to 3–11 via `ajaxSyncRange`. The system auto-adds config SLOT-11 to the junction (now 7 configs). The existing out-of-range configs (none in this case) are preserved. When he tries to delete STANDARD_8P (the default), the system rejects the operation with an error.

## Related Screens

- **Period Configs** — Provides the master list of timeslots that period sets reference via their range
- **Period Types** — Provides the classifications (Teaching, Break, Lunch, etc.) that junction rows reference
- **Class Timetable Types** — Assigns period sets to specific class + section + timetable type combinations, consuming the period set definitions
- **Timetable Types** — Defines the types of timetables (Standard, Exam, Sports Day, etc.) that period sets can be assigned to
- **Timetable Preparation → Requirement Consolidation** — Downstream process that reads period set data for slot requirement generation

## Requirements

- `PeriodSetController` (992 lines, `Modules/TimetableFoundation/Http/Controllers/`) handles CRUD + AJAX endpoints for `tt_period_sets`. Public methods: `index()`, `create()`, `store()`, `show()`, `edit()`, `update()`, `destroy()`, `trashed*()`, `restore()`, `forceDelete()`, `toggleStatus()`, `ajaxPeriodConfigs()`, `ajaxSyncRange()`.
- The `store()` method (lines 100–140) enforces default uniqueness (clears existing defaults), normalises code to uppercase, validates `to_period_ord` against the shift's teaching slot count, and calls `syncPeriodSetPeriods()` if `period_config_ids` are provided.
- The `update()` method (lines 300–500) handles the two-pass period_ord swap, syncs junction records via `syncPickerMembership()` (if picker submitted) or `autoAddInRangeConfigs()` (if not), and recalculates derived counters via `syncDerivedCountersFromJunction()`.
- The `ajaxPeriodConfigs()` method (lines 750–800) accepts `shift_id` as a query parameter, returns JSON with all period configs for that shift. Each config is tagged with `in_range` (whether its `slot_ord` falls between the current set's `from_period_ord` and `to_period_ord`) and `teaching_slot_count` (total teaching slots in the shift).
- The `ajaxSyncRange()` method (lines 690–710) accepts `from_period_ord` and `to_period_ord`, updates the set, calls `autoAddInRangeConfigs()` which finds configs in the new range not yet in the junction and creates them (additive only). Returns JSON with `added` count.
- The `autoAddInRangeConfigs()` method (lines 773–834) identifies configs with `slot_ord` in `[from, to]` range that do not already have a junction row and creates them.
- The `syncDerivedCountersFromJunction()` method recomputes `total_periods`, `teaching_periods`, `from_period_ord`, and `to_period_ord` from the actual junction contents after an update.
- The `syncPickerMembership()` method diffs the currently selected config IDs against the existing junction rows, force-deletes removed rows, and creates new rows for added configs.
- The `syncPeriodSetPeriods()` method wipes all existing junction rows and recreates them from the provided `period_config_ids` array.
- Validation is handled inline in the controller methods (no dedicated Form Request). Custom validation rules check `to_period_ord` against the shift's teaching slot count and enforce cross-row uniqueness for period_ord and code during update.
- The `PeriodSet` model (`Modules/TimetableFoundation/Models/`, table: `tt_period_sets`) uses `SoftDeletes`, casts booleans/integers, and defines relationships: `shift()` (BelongsTo), `periods()` (HasMany), `periodSetPeriods()` (HasMany), `periodConfigs()` (HasManyThrough), `timetables()` (HasMany), `classModeRules()` (HasMany).
- The `PeriodSetPolicy` defines `viewAny`, `view`, `create`, `update`, `delete`, `restore`, `forceDelete` — each delegating to `timetable-foundation.period-set.{action}`.
- Routes are registered in `routes/web.php` (lines 190–196): `Route::resource('period-set', PeriodSetController::class)` plus custom routes for trashed, restore, forceDelete, toggleStatus, AJAX endpoints.
- Activity logging is implemented on all state changes: destroy (Trashed), restore (Restored), forceDelete (Deleted), toggleStatus (Toggled).

## Who Can Access

| Gate/Permission | Methods | Notes |
|-----------------|---------|-------|
| `timetable-foundation.period-set.viewAny` | `index()`, `ajaxPeriodConfigs()` | Required to view the Period Sets tab and AJAX config list |
| `timetable-foundation.period-set.view` | `show()` | Required to view a single period set's details |
| `timetable-foundation.period-set.create` | `create()`, `store()` | Required to show create form and persist a new set |
| `timetable-foundation.period-set.update` | `edit()`, `update()`, `toggleStatus()`, `ajaxSyncRange()` | Required to edit a set, toggle status, or use AJAX sync-range |
| `timetable-foundation.period-set.delete` | `destroy()` | Required to soft-delete a set |
| `timetable-foundation.period-set.restore` | `trashed*()`, `restore()` | Required to view trashed sets and restore them |
| `timetable-foundation.period-set.forceDelete` | `forceDelete()` | Required to permanently delete a set |

**Policy:** `Modules\TimetableFoundation\Policies\PeriodSetPolicy` — each method checks the corresponding permission string.

## Logic Flow

**1. Page Load (List View).** The user navigates to Timetable Masters → Period Sets tab. `PeriodSet::with('shift')->orderBy('name')` loads all sets. Each row shows code, name, shift badge, period range, totals, default indicator, status toggle.

**2. Create.** User clicks "Add Period Set". `create()` gates with `.create`, loads active shifts. User selects a shift (which populates the period config picker and range limits), enters code/name/description, sets from/to ordinals, enters period counts, optionally selects configs and marks as default. POST to `store()`. The controller validates, normalises code to uppercase, enforces default uniqueness, creates junction rows from selected config IDs, logs activity, and redirects.

**3. Edit/Update (with picker).** User clicks Edit. `edit()` gates with `.update`, loads existing set data plus period configs for the set's shift (with `in_range` tagging). User modifies fields and/or checks/unchecks configs in the picker. POST to `update()`. The controller validates, processes `selected_period_config_ids` via `syncPickerMembership()` (removes unchecked, adds newly checked), recalculates counters, logs activity, and redirects.

**4. Edit/Update (without picker — range change only).** User adjusts `from_period_ord` and/or `to_period_ord` without using the picker. The controller calls `autoAddInRangeConfigs()` to add configs in the new range not yet in the junction. Existing out-of-range rows are preserved.

**5. Inline Period Management During Update.** The edit form shows a table of junction rows. User edits period_ord, code, short_name, period_type_id, or is_active per row. On save, the controller:
- Validates cross-row uniqueness for `period_ord` and `code` (against submitted rows + existing DB rows)
- Applies two-pass ordinal swapping if ordinals changed
- Updates each junction row's fields
- Recalculates derived counters from junction
- Logs activity

**6. AJAX Fetch Period Configs.** GET `ajaxPeriodConfigs?shift_id=X`. Returns JSON with `configs` array (each tagged `in_range` boolean), and `teaching_slot_count`.

**7. AJAX Sync Range.** POST `ajaxSyncRange` with `from_period_ord` and `to_period_ord`. Updates the set's range, calls `autoAddInRangeConfigs()`, returns JSON `{success, added, message}`.

**8. Toggle Status.** POST to `toggleStatus()`. If the set is default and toggling to inactive, returns 403 JSON error. Otherwise flips `is_active` and returns JSON success.

**9. Soft Delete.** `destroy()` gates with `.delete`. If `is_default = true`, redirects back with error. Otherwise sets `is_active = false`, calls `delete()`, logs activity.

**10. Restore.** `restore()` gates with `.restore`. Calls `onlyTrashed()->findOrFail($id)->restore()`, sets `is_active = true`.

**11. Force Delete.** `forceDelete()` gates with `.forceDelete`. If `is_default = true`, returns error. Otherwise calls `withTrashed()->findOrFail($id)->forceDelete()`.

## Validate Before Save

Validation is performed inline in `PeriodSetController@store()` and `@update()`:

| Field | Rule(s) | Error Message |
|-------|---------|---------------|
| `code` | required, string, max:30, regex:/^[A-Z0-9_]+$/, unique:tt_period_sets,code (ignore on update) | — |
| `name` | required, string, max:100 | — |
| `description` | nullable, string, max:255 | — |
| `shift_id` | required, integer, exists:tt_shifts,id | — |
| `from_period_ord` | required, integer, min:1 | — |
| `to_period_ord` | required, integer, min:1, gte:from_period_ord + custom: must not exceed shift's teaching slot count | "To Period Ord ({$to}) cannot exceed the number of teaching slots in this shift ({$teachingCount})." |
| `total_periods` | required, integer, min:1, max:`maxPeriodsPerDay` (floor 15, default 20) | — |
| `teaching_periods` | required, integer, lte:total_periods | — |
| `exam_periods` | required, integer | — |
| `free_periods` | required, integer | — |
| `is_default` | nullable, boolean | — |
| `applicable_class_ids` | nullable, array | — |
| `applicable_class_ids.*` | integer, exists:sch_classes,id | — |
| `period_config_ids` (create only) | nullable, array | — |
| `period_config_ids.*` (create only) | integer, exists:tt_period_configs,id | — |

**Update-specific inline row validation:**

| Field | Rule(s) | Error Message |
|-------|---------|---------------|
| `periods.*.code` | required, string, max:20 | — |
| `periods.*.short_name` | nullable, string, max:50 | — |
| `periods.*.period_type_id` | required, integer, exists:tt_period_types,id | — |
| `periods.*.period_ord` | required, integer, min:1 | — |
| `periods.*.is_active` | nullable | — |

**Controller-level checks:**

| Check | Location | Action |
|-------|----------|--------|
| `to_period_ord` exceeds teaching slots | `store()` / `update()` custom validator | Custom validation error with shift's teaching count |
| Default set singleton | `store()` / `update()` | `PeriodSet::where('is_default', true)->update(['is_default' => false])` |
| Duplicate `period_ord` across submitted rows | `update()` | Validation error: "Period Ord {X} is duplicated within this set." |
| Duplicate `code` across submitted rows or vs existing DB rows | `update()` | Validation error: "Code \"{X}\" is already used by another period in this set." |
| Default set protection on delete | `destroy()` | Error redirect with `flash('default_period_set_delete_not_allowed')` |
| Default set protection on forceDelete | `forceDelete()` | Error redirect with `flash('default_period_set_force_delete_not_allowed')` |
| Default set protection on deactivate | `toggleStatus()` | JSON 403 with `flash('default_period_set_disable_not_allowed')` |

## Error Handling and Validation Messages

| Scenario | Message | Type |
|----------|---------|------|
| Missing required field (e.g., code) | "The code field is required." | Validation rule |
| Code with invalid characters | Regex `/^[A-Z0-9_]+$/` fails | Validation rule |
| Duplicate code | Default unique validation message | Validation rule |
| `to_period_ord` < `from_period_ord` | "The to period ord must be greater than or equal to from period ord." | Validation rule (`gte`) |
| `to_period_ord` exceeds shift teaching slots | "To Period Ord ({$to}) cannot exceed the number of teaching slots in this shift ({$teachingCount})." | Custom validation |
| `teaching_periods` > `total_periods` | Validation error on `lte:total_periods` | Validation rule |
| Delete default set | Error flash: `flash('default_period_set_delete_not_allowed')` | 302 Redirect |
| Force delete default set | Error flash: `flash('default_period_set_force_delete_not_allowed')` | 302 Redirect |
| Toggle default set to inactive | JSON 403: `flash('default_period_set_disable_not_allowed')` | 403 JSON |
| Duplicate period_ord in update rows | "Period Ord {X} is duplicated within this set." | Controller check |
| Duplicate code in update rows | "Code \"{X}\" is already used by another period in this set." | Controller check |
| Non-existent record (any) | `ModelNotFoundException` → 404 page | 404 |
| Not authorised (any operation) | `AuthorizationException` → 403 | 403 |
| Generic database/exception on create | "Failed to create period set: <exception message>" | Controller check (500) |
| Generic database/exception on update | "Failed to update period set: <exception message>" | Controller check (500) |
| Generic database/exception on delete | "Failed to delete period set: <exception message>" | Controller check (500) |

## Success Scenarios

**SC-001 — Create a Standard Period Set.** Mr. Sharma creates "STANDARD_8P" with code `STANDARD_8P`, name "Standard 8-Period Day", shift "Morning", from=1, to=12, total=12, teaching=8, exam=0, free=0. He marks it as default and selects all 12 period configs for the shift. The system validates, normalises code to uppercase, clears any existing default, creates the set with `is_default=true`, creates 12 junction records with sequential period_ord values, logs activity, and redirects with success.

**SC-002 — Widen Period Set Range via AJAX.** The TODDLER set has from=3, to=10 with 8 junction rows. Mr. Sharma widens to from=3, to=11 via `ajaxSyncRange`. The controller updates the range, finds that SLOT-11 (slot_ord=11) is newly in range and not yet in the junction, creates one new junction row, and returns `{success: true, added: 1, message: "Range saved. Auto-added 1 new period(s)."}`.

**SC-003 — Swap Period Ordinals Without Unique Violation.** The STANDARD_8P set has junction rows with ordinals 1 through 12. Mr. Sharma swaps the order of rows 2 and 3 (submitting period_ord=3 for the former row 2 and period_ord=2 for the former row 3). The controller's two-pass algorithm: Pass 1 parks both ordinals to values above 12 (e.g., 13 and 14), Pass 2 writes the final ordinals (2 and 3). No unique constraint violation occurs.

**SC-004 — Protect Default Set from Deletion.** Mr. Sharma attempts to delete the STANDARD_8P set which is marked as default. The `destroy()` method checks `is_default` and redirects back with an error flash: "Default period set cannot be deleted." The set remains intact.

## Failure Scenarios

**FC-001 — Invalid Code Format.** Mr. Sharma enters code "standard-8p" (lowercase with hyphens). The regex `/^[A-Z0-9_]+$/` rejects the value, and the form shows a validation error.

**FC-002 — To Period Ord Exceeds Teaching Slot Count.** Mr. Sharma sets to_period_ord=15 for a shift that has only 8 teaching slots. The custom validation rule checks the shift's teaching slot count and returns: "To Period Ord (15) cannot exceed the number of teaching slots in this shift (8)."

**FC-003 — Duplicate Period Ordinal Within Update.** During edit, Mr. Sharma sets two junction rows to `period_ord=3`. The controller's cross-row dedup check catches the duplicate and returns: "Period Ord 3 is duplicated within this set."

**FC-004 — Toggle Default Set to Inactive.** Mr. Sharma clicks the status toggle on the STANDARD_8P set (the default). The `toggleStatus()` method detects `is_default=true` and returns JSON 403: `{success: false, message: flash('default_period_set_disable_not_allowed')}`.

**FC-005 — Unauthorised Access.** A user without `timetable-foundation.period-set.create` attempts to access the create form. `Gate::authorize()` throws `AuthorizationException`, resulting in a 403 HTTP response.

## Dependencies module and tables

| Dependency | Type | Details |
|------------|------|---------|
| `tt_shifts` | FK parent (RESTRICT) | `shift_id` FK references `tt_shifts(id)`. A shift with period sets cannot be deleted. |
| `tt_period_configs` | FK parent (indirect) | Referenced via `tt_period_set_periods_jnt.period_config_id` (ON DELETE RESTRICT). Junction records reference configs. |
| `tt_period_set_periods_jnt` | Child (CASCADE) | `period_set_id` FK references `tt_period_sets(id)` ON DELETE CASCADE. Deleting a set cascades to delete all its junction rows. |
| `tt_class_timetable_types_jnt` | Consumer | References `tt_period_sets` via FK. A period set referenced by class-timetable-type assignments cannot be deleted (RESTRICT or CASCADE depending on FK definition). |
| `activityLog()` helper | Service dependency | Called on every state-changing action (destroy, restore, forceDelete, toggleStatus). |

**Table:** `tt_period_sets`

| Column | Type | Details |
|--------|------|---------|
| `id` | INT UNSIGNED | PK, Auto Increment |
| `code` | VARCHAR(30) | NOT NULL, UNIQUE (`uq_periodset_code`) |
| `name` | VARCHAR(100) | NOT NULL |
| `description` | VARCHAR(255) | DEFAULT NULL |
| `shift_id` | TINYINT UNSIGNED | NOT NULL, FK → `tt_shifts(id)` ON DELETE RESTRICT |
| `from_period_ord` | TINYINT UNSIGNED | NOT NULL |
| `to_period_ord` | TINYINT UNSIGNED | NOT NULL, CHECK `to_period_ord >= from_period_ord` |
| `total_periods` | TINYINT UNSIGNED | NOT NULL |
| `teaching_periods` | TINYINT UNSIGNED | NOT NULL |
| `exam_periods` | TINYINT UNSIGNED | NOT NULL |
| `free_periods` | TINYINT UNSIGNED | NOT NULL |
| `is_default` | TINYINT(1) | DEFAULT 0 |
| `is_active` | TINYINT(1) | NOT NULL, DEFAULT 1 |
| `created_at` | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |
| `updated_at` | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP |
| `deleted_at` | TIMESTAMP | NULL (soft delete) |

**Table:** `tt_period_set_periods_jnt`

| Column | Type | Details |
|--------|------|---------|
| `id` | INT UNSIGNED | PK, Auto Increment |
| `period_set_id` | INT UNSIGNED | NOT NULL, FK → `tt_period_sets(id)` ON DELETE CASCADE |
| `period_config_id` | INT UNSIGNED | NOT NULL, FK → `tt_period_configs(id)` ON DELETE RESTRICT |
| `period_ord` | TINYINT UNSIGNED | NOT NULL, UNIQUE `(period_set_id, period_ord)` |
| `code` | VARCHAR(20) | NOT NULL, UNIQUE `(period_set_id, code)` |
| `short_name` | VARCHAR(50) | NOT NULL |
| `period_type_id` | TINYINT UNSIGNED | NOT NULL, FK → `tt_period_types(id)` ON DELETE RESTRICT |
| `is_active` | TINYINT(1) | NOT NULL, DEFAULT 1 |
| `created_at` | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |
| `updated_at` | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP |
| `deleted_at` | TIMESTAMP | NULL (soft delete) |
