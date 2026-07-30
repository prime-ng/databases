# Working Days — Business Requirements

## What This Screen Does

The Working Days screen builds the **concrete daily calendar** for an academic session. While the School Days tab defines the weekly template (which weekdays are open or closed), the Working Days tab assigns specific day types — Study Day, Holiday, Exam, PTM Day, Sports Day — to every date in the session. This screen answers the question: "What kind of day is a particular date for the whole school?"

The screen uses a **FullCalendar** interface where each date cell displays up to four stacked day-type events, colour-coded for quick scanning. Administrators can click empty dates to add day types, drag events between dates, delete individual type slots, and initialise the entire calendar from the weekly template in one click. The resulting working day data is consumed by the Class Working Days screen, the Slot Requirement solver, and the Teacher Availability module.

## When This Screen Is Used

- **At the start of an academic session** — the administrator initialises the calendar by clicking "Initialize Calendar", which bulk-generates all dates and assigns the Working Day or Holiday type based on the weekly School Days template
- **When a school holiday is declared** — the administrator clicks a date, selects the Holiday day type, and assigns it alongside (or replacing) existing types
- **When a special event occurs** — the administrator assigns Exam, PTM Day, Sports Day, or other types to specific dates, possibly stacking multiple types on the same date (up to 4 per date)
- **When a day type needs to be moved** — the administrator drags a day-type event from one date to another, and the system compacts slots at the source and stacks the type at the target
- **When a day type is no longer needed** — the administrator deletes a slot; if it was the last slot, the system prompts about linked class working day records before removing the entire row
- **When school-wide remarks need updating** — the administrator edits the remarks field for a specific date

## Default Data Load

The Working Days tab loads via `TimetableFoundationController@timetableMasters` at route `timetable-foundation.menu.timetableMasters`, with the `tab=working-days` query parameter. The page gate is `timetable-foundation.viewAny`.

The working days data itself is **not loaded on page load** — instead, a FullCalendar instance is rendered, and events are lazy-loaded via the `eventFeed` AJAX endpoint (`GET /working-day/ajax/events`) when the calendar renders or navigates to a new date range.

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| Day Types dropdown | `timetableMasters()` | Active day types for the add-day-type dialog | `is_active = 1` | None |
| Calendar Events | `eventFeed()` | `WorkingDay::with(dayType, dayType2, dayType3, dayType4)->whereBetween('date',[$start,$end])` | Date range from FullCalendar | None |
| Shared: Academic Sessions | `timetableMasters()` | Current academic session | `is_current = 1` | None |

The `eventFeed()` method emits one event per filled day-type slot, with:
- Event ID format: `wd-{workingDayId}-{slotNumber}` (e.g., `wd-42-1`)
- Title from the day type's `short_name` or `name`
- Color from `DAY_TYPE_COLORS` constant (mapping day-type codes to hex colours)
- Extended props: `day_type_id`, `slot`, `working_day_id`, `is_school_day`, `date`, `remarks`

## Key Fields at a Glance

**Identity Fields**

- **Date** — The calendar date (DATE type). Each date can appear at most once in the table (unique constraint on `date`). The system creates one row per date during initialisation.
- **Academic Session ID** — Links the working day record to the current academic session. Used in queries and initialisation scope.

**Day Type Slots (1–4)**

- **Day Type 1** (required) — The primary day type assigned to this date. Always NOT NULL. Typically the Working Day type after initialisation.
- **Day Types 2–4** (optional) — Additional day types stacked on the same date. Can be used to mark special events on a day that is already a working day (e.g., add PTM Day alongside Study Day). Slots are compacted upward when a slot is removed — slot 2 shifts to slot 1 if slot 1 is removed, and so on.

**Status Fields**

- **Is School Day** — Computed boolean: `true` if any assigned day type has `is_working_day = true`, `false` if all assigned types are non-working. This is the aggregate indicator — the date is a school day if at least one working type is present.
- **Remarks** — Free text (max 255 characters). Used to note the reason for a holiday, exam, or special schedule. Editable via `ajaxUpdateRemark`.
- **Is Active** — Standard enable/disable flag.
- **Deleted At** — Populated on soft delete. The working day record can be restored or force-deleted. When a trashed row is re-encountered during AJAX store, the system restores it rather than failing.

## Business Rules and Conditions

**Calendar Initialisation from Weekly Template.** The `ajaxInitializeWorkingDays` method creates the entire academic session calendar in a single operation. For each date in the session range, it checks whether the date's ISO weekday falls in the computed closed-day set. The closed-day set is derived from two `tt_configs` values: `week_start_day` (default MONDAY) and `default_school_closed_days_per_week` (default 1). The formula is `closedIsoDays[i] = ((weekStartIso - 1 - i + 7) % 7) + 1` for i from 1 to closedDaysCount. For example, with week start Monday and 1 closed day, Sunday (ISO 7) is closed. If the date is closed, it receives the Holiday type; otherwise, the Working Day type.

**Day Type Resolution During Initialisation.** The Working Day type is resolved as the first active day type where `is_working_day = true`, ordered by `ordinal`. The Holiday type is resolved with priority: (1) an active type with code 'H', (2) failing that, an active type with code 'HD', (3) failing that, the first active non-working type by ordinal. Both types must exist for initialisation to proceed.

**Maximum Four Types Per Date.** A single date can hold up to four day-type slots. Attempting to add a fifth type throws "This date already has 4 day types (max)." The system adds new types to the first available empty slot (compact fill).

**No Duplicate Day Types.** The same day type cannot appear in more than one slot on the same date. Attempting to add a type that already occupies a slot throws "{name} is already assigned to this date."

**Working/Non-Working Mutual Exclusion.** Working day types (where `is_working_day = true`) and non-working day types (where `is_working_day = false`) cannot coexist on the same date. If a date has holiday types and a working type is added, the system throws "Cannot add a working day type — this date is already a holiday." Conversely, adding a holiday to a date with working types throws "Cannot add a holiday — this date already has working day type(s)."

**At Most One Non-Working Type Per Date.** Only one holiday-like day type can be assigned per date. Attempting to add a second non-working type throws "Only one holiday type allowed per date."

**Slot Compaction on Remove.** When a day-type slot is removed (via `ajaxDestroy` or drag-and-drop edit), the remaining slots are compacted upward. For example, if slot 2 is removed, slot 3 shifts to slot 2, and slot 4 shifts to slot 3. The system always maintains slot 1 as the primary slot (NOT NULL in the schema).

**Is School Day Re-computation.** After any add or remove operation, `is_school_day` is recomputed from the remaining day types: `true` if any remaining type has `is_working_day = true`, `false` otherwise.

**Working Day Must Exist Before Class Override.** Before a class working day record can reference a working day, the underlying date must already have a WorkingDay row. The `ClassWorkingDayController` validates this explicitly.

**Cascading Deletion on Last Slot.** When the last day-type slot on a date is removed via `ajaxDestroy`, the method checks for linked `ClassWorkingDay` records. If found and the `force` flag is not set, the response includes `requires_confirm: true` with the count of linked records and the date label. If confirmed (or no linked records), the WorkingDay row and all linked ClassWorkingDay records are force-deleted within a database transaction.

**Trashed Row Recovery.** During `ajaxStore`, if a WorkingDay row already exists in the trashed state (soft-deleted) for the given date, the system restores it and resets it to a single-slot row with the new day type. This prevents duplicate-date conflicts and ensures data integrity.

## Workflow Steps

**Initialising the Calendar for a New Session.** The administrator navigates to the Working Days tab and clicks the "Initialize Calendar" button. A dialog prompts with an optional "Clear existing" checkbox. On confirmation, `POST /working-day/ajax/initialize-calander` is called. The system validates the current academic session, resolves Working Day and Holiday types, and iterates every date in the session range. Each date's ISO weekday is checked against the closed-day list. Open dates get the Working Day type with `is_school_day = true`; closed dates get the Holiday type with `is_school_day = false`. A success message reports the number of initialised days.

**Adding a Day Type to a Date.** The administrator clicks an empty date cell on the calendar. A dialog opens showing available day types. They select a type and confirm. `POST /working-day/ajax/store` is called with `start` (date), `end` (nullable for range), and `day_type_id`. If no row exists for the date, a new WorkingDay row is created. If a trashed row exists, it is restored and reset. If a row already exists, the system calls `addDayTypeToWorkingDay()` which checks mutual exclusion, finds the first free slot, and assigns the type. The response reports `applied` and `skipped` counts for range operations.

**Dragging a Day Type to a Different Date.** The administrator drags a calendar event from one date to another. `POST /working-day/ajax/edit` is called with the event ID (format `wd-{id}-{slot}`) and the target date. The system removes the slot from the source date (compacting remaining slots upward), then adds the day type to the target date's first empty slot — all within a database transaction. If the target violates mutual exclusion, the transaction is rolled back and an error is returned. If source and target are the same date, the response is "No change."

**Deleting a Day-Type Slot.** The administrator clicks the delete icon on a calendar event. `DELETE /working-day/ajax/delete/{id}` is called with the event ID. The controller parses the event ID to extract the working day ID and slot number. If the slot is not the last, `removeSlotAndCompact()` removes it and shifts remaining slots upward. If it is the last slot, the controller checks for linked ClassWorkingDay records. If linked records exist and `force` is not set, a confirmation response is returned. On confirmation (or no linked records), the row and all linked records are force-deleted.

**Editing Remarks.** The administrator clicks a date and selects the "Remarks" option. A dialog opens with the current remarks text. They enter or update the text and confirm. `POST /working-day/ajax/remark/{id}` saves the new remarks string (max 255 characters).

**Clearing the Calendar.** The administrator clicks "Clear All" to remove all working days for the current session. `DELETE /working-day/ajax/clear` force-deletes all rows and linked class working day records within a transaction.

## Example Scenario

St. Mary's High School starts its new academic session on 1 April 2026. Mrs. Sharma, the administrator, has already confirmed the School Days template (Mon–Sat open, Sun closed) and verified that the Day Types include Study Day (working) and Holiday (non-working).

She navigates to the Working Days tab and clicks "Initialize Calendar." The session runs 1 April 2026 to 31 March 2027. The system resolves Study Day (ordinal 1, `is_working_day = true`) and Holiday (code 'H', `is_working_day = false`). It creates 365 rows — all Sundays get Holiday type with `is_school_day = false`, all other days get Study Day type with `is_school_day = true`. The response: "Initialized 365 days."

On 15 August (Independence Day), the school declares a holiday. Mrs. Sharma clicks the 15 August cell, selects "Holiday" from the day-type dialog, and confirms. Since 15 August already has Study Day in slot 1, and Holiday is non-working, the mutual exclusion rule triggers: "Cannot add a holiday — this date already has working day type(s)." Mrs. Sharma first removes the Study Day slot from 15 August, then adds Holiday. The date now has only Holiday, and `is_school_day` is recomputed to `false`.

For the annual PTM on 10 September, Mrs. Sharma clicks the date and selects "PTM Day." Since PTM Day has `is_working_day = true` and `reduced_periods = true`, it stacks alongside Study Day without conflict. The date now has two slots: Study Day (slot 1) and PTM Day (slot 2). `is_school_day` remains `true`.

During board exam season, Mrs. Sharma drags the Holiday event from 15 August to 16 August (a Sunday that already has Holiday). The source date (15 August) now has no slots — it was the last slot — so the row is deleted. The target date (16 August) already has Holiday, so the duplicate rule triggers and the move is rolled back.

Later, Mrs. Sharma needs to delete the PTM Day from 10 September. She clicks delete on the PTM Day event. Since it is not the last slot (Study Day remains), `removeSlotAndCompact()` removes it, and `is_school_day` stays `true`.

## Related Screens

- **School Days** — provides the weekly template consumed during calendar initialisation
- **Day Types** — defines the classifications that populate the four day-type slots
- **Class Working Days** — consumes working day records to create class-specific overrides; dependent on Working Day rows existing
- **Academic Terms** — defines the academic session start/end dates used in initialisation
- **Timetable Config** — stores `week_start_day` and `default_school_closed_days_per_week` settings
- **Slot Requirement** — consumes working day data for timetable solver
- **Teacher Availability** — consumes working day data for teacher scheduling

## Requirements

- `WorkingDayController` provides standard CRUD (`index()`, `create()`, `store()`, `show()`, `edit()`, `update()`, `destroy()`) plus AJAX endpoints: `ajaxStore()` (POST `/working-day/ajax/store`), `ajaxEdit()` (POST `/working-day/ajax/edit`), `ajaxUpdateRemark()` (POST `/working-day/ajax/remark/{id}`), `ajaxDestroy()` (DELETE `/working-day/ajax/delete/{id}`), `ajaxInitializeWorkingDays()` (POST `/working-day/ajax/initialize-calander`), `ajaxClearWorkingDays()` (DELETE `/working-day/ajax/clear`), and `eventFeed()` (GET `/working-day/ajax/events`).

- The `eventFeed()` method receives FullCalendar's `start`/`end` parameters and lazy-loads events for the visible date range. It emits one event per filled slot with ID format `wd-{workingDayId}-{slot}`. Colours are resolved via the `DAY_TYPE_COLORS` constant — a hardcoded map of day-type codes to hex colours.

- The `ajaxStore()` method supports a date range (FullCalendar's `end` is exclusive, so `subDay()` is applied). It handles three cases: no existing row (create new), trashed row (restore and reset), or existing row (stack via `addDayTypeToWorkingDay()`). Partial success across a range is reported via `applied` and `skipped` arrays.

- The `ajaxEdit()` method parses the event ID (`wd-{id}-{slot}`), removes the slot from the source with `removeSlotAndCompact()`, and adds the type to the target via `addDayTypeToWorkingDay()` — all within a DB transaction. On any `RuntimeException`, the transaction is rolled back and a 422 error is returned. If source and target are the same date, returns "No change" (200).

- The `ajaxDestroy()` method checks whether the removed slot is the last. If so, it counts linked `ClassWorkingDay` records. If linked records exist and `force` is not set, it returns `{ requires_confirm: true, linked_count, date_label }` (200). If confirmed or no linked records, it force-deletes the WorkingDay row and linked ClassWorkingDay records within a DB transaction. If the slot is not the last, `removeSlotAndCompact()` shifts remaining slots upward.

- The `ajaxInitializeWorkingDays()` method reads `week_start_day` and `default_school_closed_days_per_week` from `tt_configs`, resolves the Working Day type (first active working type by ordinal) and Holiday type (priority: code 'H' → 'HD' → first active non-working by ordinal), and iterates the session date range. If `clear_existing` is true, it force-deletes existing rows first.

- Gates: `timetable-foundation.working-day.viewAny` (tab + eventFeed), `.create` (create/store/ajaxStore/ajaxInitializeWorkingDays), `.view` (show), `.update` (edit/update/ajaxEdit/ajaxUpdateRemark/toggleStatus), `.delete` (destroy/ajaxDestroy/ajaxClearWorkingDays), `.restore` (restore/trashed), `.forceDelete` (forceDelete).

- Policy: `WorkingDayPolicy` in `Modules\TimetableFoundation\Policies` with methods `viewAny()`, `view()`, `create()`, `update()`, `delete()`, `restore()`, `forceDelete()`.

- Validation is inline in the controller (no Form Request classes).

- Activity logging is performed on create, update, destroy, restore, force-delete, and toggle-status operations.

## Who Can Access

| Gate/Permission | Methods | Notes |
|---|---|---|
| `timetable-foundation.working-day.viewAny` | `index`, `eventFeed` | Loads tab and calendar events |
| `timetable-foundation.working-day.create` | `create`, `store`, `ajaxStore`, `ajaxInitializeWorkingDays` | Create, store, AJAX add, initialize |
| `timetable-foundation.working-day.view` | `show` | View single record |
| `timetable-foundation.working-day.update` | `edit`, `update`, `ajaxEdit`, `ajaxUpdateRemark`, `toggleStatus` | Edit, update, drag-drop, remark, toggle |
| `timetable-foundation.working-day.delete` | `destroy`, `ajaxDestroy`, `ajaxClearWorkingDays` | Soft-delete, AJAX remove, clear all |
| `timetable-foundation.working-day.restore` | `restore`, `trashedWorkingDay` | Restore and view trash |
| `timetable-foundation.working-day.forceDelete` | `forceDelete` | Permanent delete |

Global page access to the tab is gated by `timetable-foundation.viewAny` on `TimetableFoundationController@timetableMasters`.

## Logic Flow

**1. Page Load (Working Days Tab).** The user navigates to `timetable-foundation.menu.timetableMasters?tab=working-days`. The controller renders the page with a FullCalendar instance. No events are loaded on page render — the calendar requests events from `eventFeed` when it renders the initial view. Shared data (day types, academic sessions) is available in the page state for the add-dialog.

**2. Calendar Initialisation.** The user clicks "Initialize Calendar." `ajaxInitializeWorkingDays()` validates the current session exists. It reads config values `week_start_day` and `default_school_closed_days_per_week` from `tt_configs`. It resolves Working Day type (first active `is_working_day=true`, ordered by ordinal) and Holiday type (priority: code 'H' → 'HD' → first active non-working by ordinal). If `clear_existing` is true, it force-deletes existing WorkingDay rows and linked ClassWorkingDay rows. Then it iterates every date from session start to end. Each date is checked against the closed-day set. If closed: `day_type1_id = holidayType->id, is_school_day = false`. If open: `day_type1_id = workingDayType->id, is_school_day = true`. All operations run within a DB transaction. Response: `{ status: true, message: "Initialized {count} days ({start} to {end})." }`.

**3. Add Day Type (AJAX).** The user clicks a date and selects a day type. `ajaxStore()` validates `start` (required date), `end` (nullable date), `day_type_id` (required, exists). For each date in the range (with `subDay()` applied to exclusive end):
- Check for existing row via `withTrashed()` and `lockForUpdate()`
- If trashed: restore, reset to single-slot row with the new type, recompute `is_school_day`
- If no row: create with the new type in slot 1
- If row exists: call `addDayTypeToWorkingDay()` which checks mutual exclusion, finds first free slot, assigns type, recomputes `is_school_day`
- On `RuntimeException`: skip the date, add to `skipped` array
- Response: `{ status: true, message: "Saved {applied} day(s).", applied: [...], skipped: [...] }`

**4. Drag to Move (AJAX).** The user drags an event to a new date. `ajaxEdit()` validates `id` and `date`. It parses the event ID into `workingDayId` and `slot`. Within a DB transaction:
- Remove the slot from the source WorkingDay via `removeSlotAndCompact()` (shifts remaining slots upward)
- Find or create the target WorkingDay row (with trashed-row recovery)
- Call `addDayTypeToWorkingDay()` to stack the moved type into the first free slot on the target
- On `RuntimeException`: roll back transaction, return 422 error
- Response on success: `{ status: true, message: "Day type moved successfully." }`

**5. Delete Slot (AJAX).** The user deletes a calendar event. `ajaxDestroy()` parses the event ID. If the slot is not the last, `removeSlotAndCompact()` shifts remaining slots up. If it is the last slot:
- Count linked `ClassWorkingDay` records
- If linked records exist and `force` is not set: return `{ requires_confirm: true, linked_count, date_label }` (200)
- If confirmed (`force=true`) or no linked records: DB transaction force-deletes the WorkingDay row and linked ClassWorkingDay records
- Response on success: `{ status: true, message: "Day type removed." }`

**6. Update Remarks (AJAX).** The user edits remarks for a date. `ajaxUpdateRemark()` validates `remarks` (nullable, string, max:255). Updates the WorkingDay row's `remarks` field. Response: `{ status: true, message: "Remarks updated." }`.

**7. Clear All.** The user clicks "Clear All." `ajaxClearWorkingDays()` force-deletes all WorkingDay rows and linked ClassWorkingDay records for the current session within a transaction.

## Validate Before Save

**Working Days — Resource CRUD (store)**

| Field | Rule(s) | Error Message |
|---|---|---|
| `date` | required, date | Laravel default |
| `day_type1_id` | required, exists:tt_day_types,id | Laravel default |
| `is_school_day` | required, boolean | Laravel default |
| `is_active` | nullable, boolean | Normalized via `$request->boolean()` |

**Working Days — AJAX Store (ajaxStore)**

| Field | Rule(s) | Error Message |
|---|---|---|
| `start` | required, date | Laravel default |
| `end` | nullable, date | Laravel default |
| `day_type_id` | required, exists:tt_day_types,id | Laravel default |

**Controller-level (addDayTypeToWorkingDay):**
- Duplicate day type on same date → `"{name}" is already assigned to this date.`
- Max 4 types per date → `"This date already has 4 day types (max)."`
- Adding working type to non-working date → `"Cannot add a working day type — this date is already a holiday."`
- Adding non-working type to working date → `"Cannot add a holiday — this date already has working day type(s)."`
- Adding second non-working type → `"Only one holiday type allowed per date."`

**Working Days — AJAX Edit (ajaxEdit)**

| Field | Rule(s) | Error Message |
|---|---|---|
| `id` | required, string | Laravel default |
| `date` | required, date | Laravel default |

**Controller-level:**
- Invalid event ID format → `"Invalid event ID."` (422)
- Source slot is empty → `"Source slot is empty."` (422)
- Source day type not found → `"Source day type not found."` (422)
- Same source and target date → `"No change."` (200)
- Target add violates mutual exclusion → RuntimeException caught as 422

**Working Days — AJAX Update Remark (ajaxUpdateRemark)**

| Field | Rule(s) | Error Message |
|---|---|---|
| `remarks` | nullable, string, max:255 | Laravel default |

**Working Days — AJAX Destroy (ajaxDestroy)**

**Controller-level:**
- Invalid event ID → `"Invalid event ID."` (422)
- Working day not found → `"Working day not found or already deleted."` (404)
- Slot already empty → `"That slot is already empty."` (422)
- Last slot with linked records and no force → `"{N} class working day record(s) are linked to {date}. Removing the last day type will also remove those records."` (200, requires_confirm=true)

**Working Days — AJAX Initialize (ajaxInitializeWorkingDays)**

**Controller-level:**
- No current session or missing dates → `"No current academic session found or session has no start/end dates."` (422)
- No active Working Day type → `"No active Working Day type found."` (422)
- No active Holiday type → `"No active Holiday day type found."` (422)

## Error Handling and Validation Messages

| Scenario | Message | Type |
|---|---|---|
| Duplicate day type on date | `"{name}" is already assigned to this date.` | Controller check (422 JSON) |
| Max 4 types per date | `"This date already has 4 day types (max)."` | Controller check (422 JSON) |
| Add working type to holiday date | `"Cannot add a working day type — this date is already a holiday."` | Controller check (422 JSON) |
| Add holiday to working date | `"Cannot add a holiday — this date already has working day type(s)."` | Controller check (422 JSON) |
| Second non-working type on date | `"Only one holiday type allowed per date."` | Controller check (422 JSON) |
| AJAX edit — invalid event ID | `"Invalid event ID."` | Controller check (422 JSON) |
| AJAX edit — source slot empty | `"Source slot is empty."` | Controller check (422 JSON) |
| AJAX edit — source type not found | `"Source day type not found."` | Controller check (422 JSON) |
| AJAX edit — move to same date | `"No change."` | Controller check (200 JSON) |
| AJAX destroy — invalid event ID | `"Invalid event ID."` | Controller check (422 JSON) |
| AJAX destroy — not found | `"Working day not found or already deleted."` | Controller check (404 JSON) |
| AJAX destroy — slot already empty | `"That slot is already empty."` | Controller check (422 JSON) |
| AJAX destroy — last slot with linked records | `"{N} class working day record(s) are linked to {date}. Removing the last day type will also remove those records."` | Controller check (200 JSON, requires_confirm) |
| Initialize — no current session | `"No current academic session found or session has no start/end dates."` | Controller check (422 JSON) |
| Initialize — no Working Day type | `"No active Working Day type found."` | Controller check (422 JSON) |
| Initialize — no Holiday type | `"No active Holiday day type found."` | Controller check (422 JSON) |
| Toggle status — save failure | `flash('status_switch_failed.working_day')` | Controller check (422 JSON) |
| Gate authorization failure | 403 Forbidden (`AuthorizationException`) | Gate |

## Success Scenarios

**SC-001 — Initialize Calendar for New Session.** A 365-day session initializes with all Sundays as Holiday and all other days as Study Day. Response: `{ status: true, message: "Initialized 365 days (2026-04-01 to 2027-03-31). School-closed days set as Holiday, rest as Working Day." }`.

**SC-002 — Stack PTM Day Alongside Study Day.** The administrator clicks 10 September and adds PTM Day. Since both are working types, the system stacks PTM Day in slot 2. Response: `{ status: true, message: "Saved 1 day(s)." }`. The date has 2 slots; `is_school_day = true`.

**SC-003 — Drag Holiday to a New Date.** The administrator drags a Holiday from 15 August to 22 August (an empty date). The source slot is removed and the target receives the Holiday type. Response: `{ status: true, message: "Day type moved successfully." }`.

**SC-004 — Delete Last Slot Without Linked Records.** The administrator deletes the only remaining slot on a date that has no linked class working days. The WorkingDay row is force-deleted. Response: `{ status: true, message: "Day type removed." }`.

**SC-005 — Delete Last Slot With Confirmation.** The administrator tries to delete the last slot on a date that has 3 linked class working day records. Response: `{ status: false, requires_confirm: true, linked_count: 3, date_label: "15 Aug 2026", message: "3 class working day record(s) are linked to 15 Aug 2026. Removing the last day type will also remove those records." }`. The UI shows a confirmation dialog. On confirm (with force=true), the row and linked records are deleted.

## Failure Scenarios

**FC-001 — Initialize Without Active Holiday Type.** The administrator deletes or deactivates all non-working day types, then initializes. The system cannot resolve a Holiday type and returns 422 with `"No active Holiday day type found."`.

**FC-002 — Add Duplicate Day Type.** A date already has Study Day; the administrator adds another Study Day. The system returns 422 with `"Study Day is already assigned to this date."`.

**FC-003 — Add Holiday to a Date With Working Types.** A date has Study Day; the administrator adds Holiday. The system returns 422 with `"Cannot add a holiday — this date already has working day type(s)."`.

**FC-004 — Drag to a Date That Already Violates Mutual Exclusion.** The administrator drags a Holiday to a date that already has a working type. The transaction rolls back and returns 422 with the mutual exclusion error.

**FC-005 — Delete Last Slot Without Confirmation (Linked Records Exist).** The administrator deletes the last slot on a date with linked class working days without setting the `force` flag. The system returns requires_confirm instead of deleting. The deletion does not proceed until confirmed.

**FC-006 — Initialize Without Active Session.** The administrator tries to initialize when no current academic session exists. Response: 422 with `"No current academic session found or session has no start/end dates."`.

## Dependencies module and tables

| Dependency | Type | Details |
|---|---|---|
| `tt_working_days` | Primary table | Core table for this feature |
| `tt_day_types` | FK parent | `day_type1_id` through `day_type4_id` FK to `tt_day_types.id` ON DELETE RESTRICT |
| `sch_organization_academic_sessions` | FK parent (logical) | `academic_session_id` references organization academic sessions |
| `tt_class_working_days_jnt` | Child table | Force-deleted via controller when last WorkingDay slot is removed |
| `tt_school_days` | Config dependency | Weekly template used during initialization |
| `tt_configs` | Config dependency | Stores `week_start_day` and `default_school_closed_days_per_week` |
| `sch_academic_term` | Counter target (DDL planned) | Counter updates not yet implemented |
| `WorkingDayPolicy` | Auth policy | Gates all CRUD + AJAX operations |
| `activityLog()` helper | Service | Logs all state-changing operations |

**Table:** `tt_working_days`

| Column | Type | Details |
|---|---|---|
| `id` | INT UNSIGNED | Primary key, auto-increment |
| `academic_session_id` | SMALLINT UNSIGNED | NOT NULL |
| `date` | DATE | NOT NULL, UNIQUE (`uq_workday_date`) |
| `day_type1_id` | TINYINT UNSIGNED | NOT NULL, FK to `tt_day_types.id` ON DELETE RESTRICT |
| `day_type2_id` | TINYINT UNSIGNED | NULL, FK to `tt_day_types.id` ON DELETE RESTRICT |
| `day_type3_id` | TINYINT UNSIGNED | NULL, FK to `tt_day_types.id` ON DELETE RESTRICT |
| `day_type4_id` | TINYINT UNSIGNED | NULL, FK to `tt_day_types.id` ON DELETE RESTRICT |
| `is_school_day` | TINYINT(1) | NOT NULL, DEFAULT 1 |
| `remarks` | VARCHAR(255) | NULL |
| `is_active` | TINYINT(1) | NOT NULL, DEFAULT 1 |
| `created_at` | TIMESTAMP | NULL DEFAULT NULL |
| `updated_at` | TIMESTAMP | NULL DEFAULT NULL |
| `deleted_at` | TIMESTAMP | NULL DEFAULT NULL |

**Unique Keys:**
- `uq_workday_date` — on `date`

**Foreign Keys:**
- `fk_workday_daytype1` — `day_type1_id` → `tt_day_types(id)` ON DELETE RESTRICT
- `fk_workday_daytype2` — `day_type2_id` → `tt_day_types(id)` ON DELETE RESTRICT
- `fk_workday_daytype3` — `day_type3_id` → `tt_day_types(id)` ON DELETE RESTRICT
- `fk_workday_daytype4` — `day_type4_id` → `tt_day_types(id)` ON DELETE RESTRICT
