# School Days & Working Days — Business Requirements

## What This Screen Does

This feature defines the **temporal foundation** of the entire timetable system. It answers four questions that every school needs answered before any timetable can be built: which weekdays the school operates, what kinds of days exist (study, holiday, exam, etc.), which concrete dates within the academic session are school days or holidays, and whether specific classes have their own overrides on top of the school-wide calendar.

Four interrelated entities work together. **School days** sets the weekly template — Monday through Sunday, marking each day as open or closed. **Day types** defines classifications that can be applied to any calendar date (Study Day, Holiday, Exam, PTM Day, etc.), each carrying flags that tell the system whether the day counts as a working day and whether it has reduced periods. **Working days** builds the concrete calendar of dates for an academic session, assigning up to four day types per date and computing whether the school is open. **Class working days** lets administrators override the school-wide calendar for specific classes — for example, giving Class 10 a study day when the rest of the school has a holiday.

All four are accessed from a single Timetable Masters page via four tabs. The working days and class working days tabs use FullCalendar for drag-and-drop, click-to-assign, and calendar-style interaction.

## When This Screen Is Used

- **At the start of an academic session** when the administrator needs to initialize the working day calendar for the entire session — the system bulk-generates dates and assigns Working Day or Holiday types based on the configured weekly template
- **Whenever a school holiday is declared** — the administrator goes to the Working Days tab, clicks the date, and assigns a Holiday or other non-working day type
- **When a special event or exam schedule is created** — the administrator assigns Exam, PTM Day, Sports Day, or other special day types to specific dates, possibly stacking multiple types on the same date
- **When a class needs a different schedule from the school norm** — the administrator uses the Class Working Days tab to create overrides for one or more classes, marking them as exam day, holiday, half-day, or study day independently of the school-wide calendar
- **When the school changes its weekly schedule** — the administrator updates the School Days tab to mark a weekday as open or closed, then re-initializes the working day calendar
- **When a working day row with linked class overrides is deleted** — the system prompts for confirmation and cascades the deletion

## Default Data Load

All four screens load via `TimetableFoundationController@timetableMasters` at route `timetable-foundation.menu.timetableMasters`, with the active tab determined by the `tab` query parameter. The page gate is `timetable-foundation.viewAny`.

| Tab | Parameter | Controller | Data Load |
|-----|-----------|------------|-----------|
| `school-days` | `tab=school-days` | `SchoolDayController@index` | Redirects to the masters page with the tab parameter. The masters page queries `SchoolDay::query()` with optional `sd_search` (name/code) and `sd_status` (is_active) filters, ordered by `ordinal`. No pagination — all 7 rows returned. |
| `day-types` | `tab=day-types` | `DayTypeController@index` | Redirects to the masters page. The masters page queries `DayType::query()` with optional `dt_search` and `dt_status` filters, ordered by `name`. No pagination. |
| `working-days` | `tab=working-days` | `WorkingDayController@index` | Redirects to the masters page. The masters page eager-loads `WorkingDay` with all four day-type relationships (`dayType`, `dayType2`, `dayType3`, `dayType4`). No pagination — FullCalendar handles lazy-loading via the `eventFeed` AJAX endpoint. |
| `class-working-days` | `tab=class-working-days` | `ClassWorkingDayController@index` | Redirects to the masters page. The masters page eager-loads `ClassWorkingDay` with `academicSession`, `class`, `section`, and `workingDay`. FullCalendar lazy-loads via `eventFeed` and background events via `workingDayFeed`. |

Shared dropdowns on the masters page are loaded for each tab's filter bars (shift, search, status). The `WorkingDay` and `ClassWorkingDay` models use `SoftDeletes`; trashed records can be viewed via dedicated trash routes (`school-day/trash/view`, `working-day/trash/view`, etc.) with 10 records per page.

## Key Fields at a Glance

**School Days — Weekly Template**

Each of the seven rows represents one day of the week. `code` holds a three-letter abbreviation (MON, TUE, ... SUN). `name` is the full English name. `day_of_week` follows ISO 8601 numbering (Monday = 1, Sunday = 7) and is unique — no two days can share the same ISO number. `ordinal` controls display order and is also unique. `is_school_day` is the key business flag: when checked (default), the school operates on that weekday; when unchecked, the weekday is a weekly closed day (e.g., Sunday). Soft-delete support via `deleted_at` and standard `is_active` toggle.

**Day Types — Classifications**

Each day type has a `code` (uppercase, e.g., STUDY, HOLIDAY, EXAM, PTM_DAY, SPORTS_DAY, ANNUAL_DAY) and a `name`. Two boolean flags drive system behaviour: `is_working_day` (true = counts as a working day, false = holiday-like) and `reduced_periods` (true = fewer periods than normal on this day type). `ordinal` controls sort order and is unique. Soft-delete and `is_active` toggle apply. Colors for calendar rendering are hardcoded in `WorkingDayController` via the `DAY_TYPE_COLORS` constant — they map day-type codes to hex colours and are not stored in the database.

**Working Days — Concrete Calendar**

Each row represents one date within an academic session. `academic_session_id` links to the current session. `date` is unique — there can be only one row per calendar date. Up to four day types can be stacked via `day_type1_id` (required, NOT NULL) through `day_type4_id` (nullable). `is_school_day` is dynamically computed: true if any assigned day type has `is_working_day = true`, false if all assigned types are non-working. `remarks` is free text (max 500 characters). The `date` column has a UNIQUE constraint; the system handles existing or trashed rows by updating or restoring them rather than failing.

**Class Working Days — Class Overrides**

Each row represents a class-specific override for a specific date. The unique constraint is on `(class_id, working_day_id)` — one record per class per working day. Five boolean flags drive behaviour: `is_exam_day`, `is_ptm_day`, `is_half_day`, `is_holiday`, and `is_study_day` (default true). These flags are mutually exclusive at the business level — resolved from a single `day_type` string by `resolveDayTypeFlags()` in the controller. `period_set_id` optionally links to an alternative period set for half-days or special schedules. The model provides `isTeachingAllowed()` (returns true when `is_active && is_study_day && !is_holiday`) and `isSpecialDay()` (returns true when any of exam/ptm/half_day is set).

## Business Rules and Conditions

**Weekly Template Definition.** The school defines exactly seven rows in `tt_school_days` (Monday through Sunday), one per weekday. `is_school_day` marks whether the school operates on that day. During calendar initialization, the system reads two configuration values from `tt_configs`: `week_start_day` (default MONDAY) determines the first day of the week, and `default_school_closed_days_per_week` (default 1) determines how many consecutive days immediately preceding the week start are closed. The system computes which ISO weekdays are closed using the formula `closedIsoDays[i] = ((weekStartIso - 1 - i + 7) % 7) + 1` for i from 1 to closedDaysCount. For example, with week start Monday and 1 closed day, Sunday (ISO 7) is closed; with 2 closed days, Saturday and Sunday are closed.

**Day Type Classification and Flags.** Each day type carries two boolean flags that control system-wide behaviour. `is_working_day = true` means the day type represents an instructional day (Study Day, PTM Day); `false` means it represents a non-working day (Holiday, Exam, Sports Day, Annual Day). This flag drives the `is_school_day` computation on working days. `reduced_periods = true` means the school operates with fewer periods on that day type (Exam, PTM Day, Sports Day); `false` means normal period count. Half-day detection checks whether any assigned day type on a school day has `reduced_periods = true`.

**Multiple Day Types Per Date.** A working day date can have up to four day types stacked in slots 1 through 4. Slot 1 is always required (NOT NULL in the schema). New day types are added to the first available empty slot. When a slot is removed, remaining slots are compacted upward — day_type2 shifts to day_type1, day_type3 to day_type2, and so on — ensuring slot 1 is always populated when any types remain. The calendar event feed emits one event per filled slot, each with an ID of the format `wd-{workingDayId}-{slot}` for independent drag-and-drop.

**Mutual Exclusion of Day Types on a Single Date.** Four rules are enforced when stacking day types: (1) no duplicate day type can be assigned — the same type cannot appear in more than one slot on the same date; (2) maximum four types per date; (3) working and non-working day types cannot coexist on the same date — the system throws "Cannot add a working day type — this date is already a holiday" or the reverse; (4) at most one non-working type per date — the system throws "Only one holiday type allowed per date". After any add or remove, `is_school_day` is recomputed from the remaining day types: true if any remaining type is a working day type.

**Working Day Calendar Initialization.** The `ajaxInitializeWorkingDays` method bulk-generates the calendar for the entire academic session. For each date from the session's start date to end date, it checks whether the date's ISO weekday is in the computed closed-day list. If closed, it sets `day_type1_id` to the holiday type and `is_school_day = false`. Otherwise, it sets `day_type1_id` to the working day type and `is_school_day = true`. The working day type is the first active type where `is_working_day = true`, ordered by ordinal. The holiday type is resolved by priority: first an active type with code 'H', then 'HD', then the first active non-working type by ordinal. The method supports a `clear_existing` flag to force-delete all existing rows (and linked class working days) before re-initialization.

**Working Day Must Exist Before Class Override.** Before a class working day record can be created, the underlying working day row for that date must already exist. The `ajaxStore` method in `ClassWorkingDayController` validates this explicitly and throws a `RuntimeException` with a message directing the user to add the date in the Working Days tab first.

**Class Override Behaviour.** Class working day entries are permitted on any configured date regardless of the underlying day type's `is_working_day` flag — a class can have a study day on a school-wide holiday. The `ajaxInitialize` method creates default records from existing working days: `is_holiday` is set to the inverse of the working day's `is_school_day`, and `is_study_day` is set to match `is_school_day`. Only the holiday and study day flags are set during initialization; exam, ptm, and half_day flags always start as false.

**Cascading Deletion.** When a WorkingDay row is deleted via `ajaxDestroy` and it was the last slot on that date, linked ClassWorkingDay records are force-deleted (not soft-deleted) within a database transaction. The UI prompts for confirmation when linked records exist, showing the count of affected records and the date label.

**Working Day Counter Updates (DDL Condition — Not Yet Implemented).** The DDL specifies four counter updates on `sch_academic_term` that should fire when working day statuses change: decrement `term_total_teaching_days` when marking a day as Holiday; increment `term_total_exam_days` when marking a day as Exam Day; adjust `term_total_working_days` when toggling between working and holiday. These are specified in the DDL conditions but are not yet implemented in the controllers.

## Workflow Steps

**Initializing the Calendar for a New Academic Session.** The administrator navigates to the Timetable Masters page and opens the Working Days tab. They click the "Initialize Calendar" button, which calls `POST /working-day/ajax/initialize-calander`. The system validates that a current academic session exists with valid start and end dates, that at least one active Working Day type exists, and that at least one active Holiday type exists. If `clear_existing` is checked, all existing working days (and linked class working days) are force-deleted first. Then for every date in the session range, the system checks the weekly closed-day list and assigns either the Working Day type (for open days) or the Holiday type (for closed days). A success message reports the count of initialized days.

**Assigning a Day Type to a Single Date.** On the Working Days calendar, the administrator clicks an empty date cell. A dialog opens where they select a day type. On confirmation, `POST /working-day/ajax/store` is called. The system either creates a new WorkingDay row with the type in slot 1, restores a trashed row, or stacks the type into the next free slot on an existing row. Mutual exclusion rules are checked per date. Errors like "is already assigned to this date" or "This date already has 4 day types (max)" are reported per date; partial success across a date range is reported via `applied` and `skipped` arrays.

**Dragging a Day Type to a Different Date.** The administrator drags a calendar event from one date to another on the Working Days calendar. The system calls `POST /working-day/ajax/edit` with the event ID (`wd-{id}-{slot}`) and the target date. It removes the slot from the source date (compacting remaining slots upward), then adds the day type to the target date's first empty slot under the same mutual exclusion rules. The operation is atomic within a database transaction; on conflict, the entire move is rolled back with an error message.

**Creating Class Overrides for Exam Day.** The administrator switches to the Class Working Days tab. They select a date range, one or more classes, optionally sections, and choose "exam" as the day type. `POST /class-working-day/ajax/store` is called. The system validates that the underlying WorkingDay row exists for each date, then resolves "exam" to `is_exam_day = true` and all other flags false. It creates one ClassWorkingDay record per class per date (cross-product of class_ids and date range). If `send_notification` is checked, a `SpecialDayAssigned` event is dispatched with the created records, notification channels, and the authenticated user.

**Initializing Class Working Days from the School Calendar.** The administrator clicks "Initialize from Working Days" on the Class Working Days tab. They select classes and optionally a period set. `POST /class-working-day/ajax/initialize` creates default records for every working day in the session: `is_holiday = !wd.is_school_day` and `is_study_day = wd.is_school_day`. If `clear_existing` is checked, existing class working day records for the selected classes are force-deleted first.

## Example Scenario

St. Mary's High School starts a new academic session on 1 April 2026. The school operates Monday through Saturday, with Sunday as the weekly holiday. The administrator, Mrs. Sharma, first checks the School Days tab — all seven days are present, Monday through Saturday are marked as `is_school_day = true`, Sunday is `false`. The `week_start_day` config is set to Monday and `default_school_closed_days_per_week` is 1, so the system will treat Sunday as closed.

On the Day Types tab, she verifies the standard types: Study Day (is_working_day=true, reduced_periods=false), Holiday (is_working_day=false), Exam (is_working_day=false, reduced_periods=true), PTM Day (is_working_day=true, reduced_periods=true), Sports Day (is_working_day=false, reduced_periods=true), and Annual Day (is_working_day=false, reduced_periods=false). All are active with their default colours.

Mrs. Sharma switches to the Working Days tab and clicks "Initialize Calendar". The session runs from 1 April 2026 to 31 March 2027. The system creates 365 rows — every Sunday gets the Holiday type with `is_school_day = false`, every other day gets the Working Day type with `is_school_day = true`.

Later, the school declares 15 August (Independence Day) as a holiday. Mrs. Sharma clicks that date on the calendar, selects the Holiday day type, and confirms. The system adds Holiday as a second slot alongside the existing Study Day — but the mutual exclusion rule prevents this because Holiday is non-working and Study Day is working. Instead, it replaces the slot. She uses the "clear and reassign" approach by removing Study Day first, then adding Holiday. The date's `is_school_day` becomes false.

For the annual PTM on 10 September, she clicks the date, selects PTM Day. Since PTM Day has `is_working_day = true` and `reduced_periods = true`, it stacks alongside the existing Study Day. The date remains a school day (`is_school_day = true`) but is flagged as a half-day (reduced periods).

Class 10 has extra board exam preparation on Saturdays, which are normally school days. Mrs. Sharma goes to the Class Working Days tab, selects Class 10, and initializes the records from working days. Then she bulk-edits specific Saturdays to add exam flags. When a school-wide holiday is declared on 2 October, she creates a class override for Class 10 marking it as a study day, so Class 10 students can attend extra classes while the rest of the school is on holiday.

## Related Screens

- **Academic Terms** — defines the academic session start/end dates and term structure that the working day calendar initialization depends on
- **Period Sets** — defines which period range a class uses; referenced by Class Working Day overrides via `period_set_id` for half-day or special schedules
- **Shift** — defines morning/afternoon/evening shifts; used by the timetable solver in conjunction with working days to determine available teaching slots
- **Timetable Config** — stores `week_start_day` and `default_school_closed_days_per_week` settings that drive calendar initialization logic
- **Slot Requirement** — consumes working day data to generate available teaching slots per class-section for the timetable solver
- **Teacher Availability** — consumes working day data alongside slot requirements to determine teacher-period allocations

## Requirements

- `SchoolDayController` provides full CRUD with methods `index()`, `create()`, `store()`, `show()`, `edit()`, `update()`, `destroy()`, `restore()`, `forceDelete()`, `trashedDay()`, and `toggleStatus()` — implements `SoftDeletes` on the `SchoolDay` model. The `destroy()` method sets `is_active = false` before soft-deleting and logs an activity. The `restore()` method restores and sets `is_active = true`. Validation is inline in the controller (no Form Request): `code` unique on `tt_school_days`, `day_of_week` unique and between 1–7, `ordinal` unique and min:1, checkboxes normalized via `$request->boolean()`. Gates: `timetable-foundation.school-day.*` for every method. Policy: no dedicated policy file — gates on the `SchoolDay` model fall through to implicit policy resolution. Routes: resource `school-day` plus `/school-day/trash/view`, `/{id}/restore`, `/{id}/force-delete`, `/{schoolDay}/toggle-status`.

- `DayTypeController` provides full CRUD with methods `index()`, `create()`, `store()`, `show()`, `edit()`, `update()`, `destroy()`, `restore()`, `forceDelete()`, `trashedDayType()`, and `toggleStatus()`. The `store()` method uppercases the code via `strtoupper()`, normalizes checkboxes via `$request->boolean()`, and logs an activity. Validation is inline: `code` unique with `whereNull('deleted_at')`, `name` unique with `whereNull('deleted_at')`, `ordinal` unique with `whereNull('deleted_at')`. The `update()` method uses `Rule::unique()->ignore($dayType->id)->whereNull('deleted_at')`. Gates: `timetable-foundation.day-type.*`. Routes: resource `day-type` plus trash/restore/force-delete/toggle-status.

- `WorkingDayController` provides standard CRUD (`index()`, `create()`, `store()`, `show()`, `edit()`, `update()`, `destroy()`) plus AJAX endpoints: `ajaxStore()` (POST `/working-day/ajax/store`), `ajaxEdit()` (POST `/working-day/ajax/edit`), `ajaxUpdateRemark()` (POST `/working-day/ajax/remark/{id}`), `ajaxDestroy()` (DELETE `/working-day/ajax/delete/{id}`), `ajaxInitializeWorkingDays()` (POST `/working-day/ajax/initialize-calander`), `ajaxClearWorkingDays()` (DELETE `/working-day/ajax/clear`), and `eventFeed()` (GET `/working-day/ajax/events`). The `ajaxStore()` method supports date ranges (FullCalendar `end` is exclusive, so `subDay()` is applied), handles trashed rows by restoring and resetting to a single-slot row, stacks types via `addDayTypeToWorkingDay()` with mutual exclusion validation, and reports partial success via `applied`/`skipped` arrays. The `ajaxEdit()` method parses event IDs (`wd-{id}-{slot}`), removes the slot from the source with compaction via `removeSlotAndCompact()`, and adds to the target's first empty slot — all within a DB transaction. The `ajaxDestroy()` method checks whether the removed slot is the last; if so, it counts linked `ClassWorkingDay` records and either returns a `requires_confirm` response (when linked records exist and `force` is not set) or force-deletes the row and all linked records within a transaction. The `ajaxInitializeWorkingDays()` method computes closed ISO weekdays from `tt_configs` values `week_start_day` and `default_school_closed_days_per_week`, resolves Working Day and Holiday types via priority rules, and iterates the session date range. The `eventFeed()` method lazy-loads events based on FullCalendar's `start`/`end` parameters, emitting one event per filled slot with extended props. A `DAY_TYPE_COLORS` constant maps day-type codes to hex colors. Gates: `timetable-foundation.working-day.*`. Policy: `WorkingDayPolicy` in `Modules\TimetableFoundation\Policies` with methods `viewAny()`, `view()`, `create()`, `update()`, `delete()`, `restore()`, `forceDelete()`.

- `ClassWorkingDayController` provides standard CRUD (`index()`, `create()`, `store()`, `show()`, `edit()`, `update()`, `destroy()`, `restore()`, `forceDelete()`, `trashedClassWorkingDay()`, `toggleStatus()`) plus AJAX endpoints: `ajaxStore()` (POST `/class-working-day/ajax/store`), `ajaxDestroy()` (DELETE `/class-working-day/ajax/delete/{id}`), `ajaxInitialize()` (POST `/class-working-day/ajax/initialize`), `eventFeed()` (GET `/class-working-day/ajax/events`), and `workingDayFeed()` (GET `/class-working-day/ajax/working-day-feed`). The `ajaxStore()` method accepts `class_ids[]`, `section_ids[]`, date range (`start`/`end`), `day_type` string, optional `period_set_id`, `send_notification`, and `notification_channels[]`. It validates the underlying WorkingDay row exists, resolves the `day_type` string to boolean flags via `resolveDayTypeFlags()`, creates records via cross-product of classes × sections × dates, uses `withTrashed()` to find existing records (restoring and updating if found), and dispatches a `SpecialDayAssigned` event when `send_notification` is true. The `ajaxDestroy()` method strips the `cwd-` prefix from the event ID and force-deletes the record. The `ajaxInitialize()` method creates default records from existing WorkingDays for selected classes, supporting `clear_existing` and optional `period_set_id`. The `workingDayFeed()` method returns background events from the Working Day calendar for reference overlay. The `eventFeed()` method supports `class_ids[]` and `section_ids[]` filtering and applies color coding by flag type. The `resolveDayTypeFlags()` private method maps strings ("exam", "ptm", "half_day", "holiday", "study") to boolean flag arrays. Gates: `timetable-foundation.class-working-day.*`. Policy: `ClassWorkingDayPolicy` in `Modules\TimetableFoundation\Policies` with standard methods. Event: `Modules\TimetableFoundation\Events\SpecialDayAssigned` dispatched with `classWorkingDays`, `channels`, and `user` — no listener is registered in the current codebase.

- All four models use `SoftDeletes`. The `ClassWorkingDay` model also uses `HasFactory`.

- No Form Request classes are used — all validation is inline in the controllers.

- Activity logging is performed on all create, update, delete (trash), restore, force-delete, and toggle-status operations via the `activityLog()` helper.

- The `ClassWorkingDay` model provides helper methods `isTeachingAllowed()` (returns `is_active && is_study_day && !is_holiday`) and `isSpecialDay()` (returns `is_exam_day || is_ptm_day || is_half_day`).

## Who Can Access

| Gate/Permission | Methods | Notes |
|---|---|---|
| `timetable-foundation.school-day.viewAny` | `SchoolDayController@index` | Loads the school-days tab |
| `timetable-foundation.school-day.create` | `SchoolDayController@create`, `store` | Create and store school day |
| `timetable-foundation.school-day.view` | `SchoolDayController@show` | View single record |
| `timetable-foundation.school-day.update` | `SchoolDayController@edit`, `update`, `toggleStatus` | Edit, update, toggle status |
| `timetable-foundation.school-day.delete` | `SchoolDayController@destroy` | Soft-delete (deactivate + trash) |
| `timetable-foundation.school-day.restore` | `SchoolDayController@restore`, `trashedDay` | Restore and view trash |
| `timetable-foundation.school-day.forceDelete` | `SchoolDayController@forceDelete` | Permanent delete |
| `timetable-foundation.day-type.viewAny` | `DayTypeController@index` | Loads the day-types tab |
| `timetable-foundation.day-type.create` | `DayTypeController@create`, `store` | Create and store day type |
| `timetable-foundation.day-type.view` | `DayTypeController@show` | View single record |
| `timetable-foundation.day-type.update` | `DayTypeController@edit`, `update`, `toggleStatus` | Edit, update, toggle status |
| `timetable-foundation.day-type.delete` | `DayTypeController@destroy` | Soft-delete |
| `timetable-foundation.day-type.restore` | `DayTypeController@restore`, `trashedDayType` | Restore and view trash |
| `timetable-foundation.day-type.forceDelete` | `DayTypeController@forceDelete` | Permanent delete |
| `timetable-foundation.working-day.viewAny` | `WorkingDayController@index`, `eventFeed` | Loads tab and calendar events |
| `timetable-foundation.working-day.create` | `WorkingDayController@create`, `store`, `ajaxStore`, `ajaxInitializeWorkingDays` | Create, store, AJAX add, initialize |
| `timetable-foundation.working-day.view` | `WorkingDayController@show` | View single record |
| `timetable-foundation.working-day.update` | `WorkingDayController@edit`, `update`, `ajaxEdit`, `ajaxUpdateRemark`, `toggleStatus` | Edit, update, drag-drop, remark, toggle |
| `timetable-foundation.working-day.delete` | `WorkingDayController@destroy`, `ajaxDestroy`, `ajaxClearWorkingDays` | Soft-delete, AJAX remove, clear all |
| `timetable-foundation.working-day.restore` | `WorkingDayController@restore`, `trashedWorkingDay` | Restore and view trash |
| `timetable-foundation.working-day.forceDelete` | `WorkingDayController@forceDelete` | Permanent delete |
| `timetable-foundation.class-working-day.viewAny` | `ClassWorkingDayController@index`, `eventFeed`, `workingDayFeed` | Loads tab, class events, background feed |
| `timetable-foundation.class-working-day.create` | `ClassWorkingDayController@create`, `store`, `ajaxStore`, `ajaxInitialize` | Create, store, AJAX add, initialize |
| `timetable-foundation.class-working-day.view` | `ClassWorkingDayController@show` | View single record |
| `timetable-foundation.class-working-day.update` | `ClassWorkingDayController@edit`, `update`, `toggleStatus` | Edit, update, toggle |
| `timetable-foundation.class-working-day.delete` | `ClassWorkingDayController@destroy`, `ajaxDestroy` | Soft-delete, AJAX force-delete |
| `timetable-foundation.class-working-day.restore` | `ClassWorkingDayController@restore`, `trashedClassWorkingDay` | Restore and view trash |
| `timetable-foundation.class-working-day.forceDelete` | `ClassWorkingDayController@forceDelete` | Permanent delete |

Global page access is gated by `timetable-foundation.viewAny` on `TimetableFoundationController@timetableMasters`.

**Policies:** `WorkingDayPolicy` and `ClassWorkingDayPolicy` are registered in `Modules\TimetableFoundation\Policies`. The `DayType` model has no dedicated policy file; gate checks use implicit model resolution. The `SchoolDay` model has no dedicated policy file either.

## Logic Flow

**1. Page Load (Timetable Masters).** The user navigates to `timetable-foundation.menu.timetableMasters` with a `tab` parameter (defaults to no tab — the first tab in the Blade view renders). The controller loads all data for all tabs in a single request: shifts, day types, period types, teacher roles, school days, working days (with all four day-type relationships), class working days (with academic session, class, section, working day), period configs, period sets, and timetable types. The Working Days and Class Working Days tabs render FullCalendar instances; the initial date range events are lazy-loaded via the `eventFeed` AJAX endpoints when the calendar renders.

**2. Create School Day.** The user opens the create form for school days (`SchoolDayController@create`). On submit, `store()` validates: `code` required, string, max:10, unique; `name` required, max:20; `short_name` required, max:5; `day_of_week` required, integer, between:1-7, unique; `ordinal` required, integer, min:1, unique; `is_school_day` and `is_active` nullable checkboxes. Checkbox fields are normalized via `$request->boolean()`. The record is created and the user is redirected back to the school-days tab with a success flash message.

**3. Update Day Type.** The user edits a day type. The `update()` method validates: `code` required, string, max:20, unique ignoring own ID with `whereNull('deleted_at')`; `name` required, max:100, unique with same ignore; `ordinal` required, min:1, unique with same ignore; `description` nullable, max:255; `is_working_day`, `reduced_periods`, `is_active` as nullable/boolean. The code is uppercased via `strtoupper()`. The record is updated and activity is logged.

**4. Initialize Working Days Calendar.** The user clicks "Initialize Calendar" on the working-days tab. `ajaxInitializeWorkingDays()` validates the current session exists. It reads `week_start_day` and `default_school_closed_days_per_week` from `tt_configs`. It resolves Working Day type (first active `is_working_day=true` ordered by ordinal) and Holiday type (priority: code 'H' → 'HD' → first active non-working by ordinal). If `clear_existing` is true, it force-deletes existing WorkingDay rows and linked ClassWorkingDay rows for the session date range. Then it iterates every date from session start to end, checking if the date's ISO weekday is in the closed-day list. Each date is either created as a new WorkingDay row or updated (including restoring trashed rows). All operations run within a single DB transaction. A JSON response reports the count of initialized days.

**5. Add Day Type to Working Day (AJAX).** The user clicks a date on the FullCalendar and selects a day type. `ajaxStore()` validates `start` (required date), `end` (nullable date), and `day_type_id` (required, exists). For each date in the range (end is exclusive — FullCalendar convention, so `subDay()` is applied), the method uses a DB transaction:
- Check for existing row with `withTrashed()` and `lockForUpdate()`
- If trashed: restore, reset to single-slot row with the new type, recompute `is_school_day`
- If no row exists: create with the new type in slot 1
- If row exists: call `addDayTypeToWorkingDay()` which checks mutual exclusion rules, finds the first free slot, assigns the type, and recomputes `is_school_day`
On `RuntimeException` from mutual exclusion, the date is skipped (not failed) and added to the `skipped` array. Partial success is reported with `applied` and `skipped` counts.

**6. Drag Day Type to Different Date (AJAX).** The user drags a calendar event from one date to another. `ajaxEdit()` parses the event ID (`wd-{id}-{slot}`), validates the target date, and within a DB transaction:
- Remove the slot from the source WorkingDay via `removeSlotAndCompact()` (shifts remaining slots upward)
- Find or create the target WorkingDay row (with trashed-row recovery)
- Call `addDayTypeToWorkingDay()` to stack the moved type into the first free slot on the target
On any `RuntimeException`, the transaction is rolled back and a 422 error is returned.

**7. Delete Last Slot on Working Day (AJAX).** The user deletes the last day type slot on a date. `ajaxDestroy()` detects that `slotIdsExcept()` returns empty after excluding the slot. It counts linked ClassWorkingDay records. If linked records exist and `force` is not set, it returns `requires_confirm: true` with the linked count and date label. If confirmed (force=true) or no linked records, a DB transaction force-deletes the WorkingDay row and (if linked records exist) force-deletes all linked ClassWorkingDay records. If the slot is not the last, `removeSlotAndCompact()` shifts remaining slots up.

**8. Create Class Working Day Overrides (AJAX).** The user selects a date range, classes, a day type, and optionally sections and a period set. `ajaxStore()` validates the inputs and resolves the day type string via `resolveDayTypeFlags()`. Within a DB transaction, for each date in the range, it validates the underlying WorkingDay row exists (throws RuntimeException if not), then iterates the cross-product of classes × sections, using `withTrashed()` to find existing records (restore + update) or creating new ones. On completion, if `send_notification` is true, a `SpecialDayAssigned` event is dispatched.

**9. Delete.** All four entity types follow the same pattern: `destroy()` sets `is_active = false`, saves, then calls `delete()` (soft delete). Activity is logged. The record moves to the trash view. `restore()` restores and reactivates (`is_active = true`). `forceDelete()` permanently removes the record plus associated activity log references.

## Validate Before Save

**School Days (SchoolDayController — inline validation)**

| Field | Rule(s) | Error Message |
|---|---|---|
| `code` | required, string, max:10, unique:tt_school_days,code | Default Laravel messages |
| `name` | required, string, max:20 | Default |
| `short_name` | required, string, max:5 | Default |
| `day_of_week` | required, integer, between:1,7, unique:tt_school_days,day_of_week | Default |
| `ordinal` | required, integer, min:1, unique:tt_school_days,ordinal | Default |
| `is_school_day` | nullable | Normalized via `$request->boolean()` |
| `is_active` | nullable | Normalized via `$request->boolean()` |

On update: unique rules append `,` . $schoolDay->id to ignore the current record.

**Day Types (DayTypeController — inline validation)**

| Field | Rule(s) | Error Message |
|---|---|---|
| `code` | required, string, max:20, unique:tt_day_types,code with `whereNull('deleted_at')` | Default |
| `name` | required, string, max:100, unique:tt_day_types,name with `whereNull('deleted_at')` | Default |
| `description` | nullable, string, max:255 | Default |
| `ordinal` | required, integer, min:1, unique:tt_day_types,ordinal with `whereNull('deleted_at')` | Default |
| `is_active` | required (in store) / nullable (in update) | Default |
| `is_working_day` | nullable (not in store validation, passed to create/update) | Normalized via `$request->boolean()` |
| `reduced_periods` | nullable (not in store validation, passed to create/update) | Normalized via `$request->boolean()` |

**Controller-level:** `code` is auto-uppercased via `strtoupper()` before create/update.

**Working Days — Resource CRUD (WorkingDayController — inline validation)**

| Field | Rule(s) | Error Message |
|---|---|---|
| `date` | required, date | Default |
| `day_type1_id` | required, exists:tt_day_types,id | Default |
| `is_school_day` | required, boolean | Default |
| `is_active` | nullable, boolean | Normalized via `$request->boolean()` |

**Working Days — AJAX Store (ajaxStore)**

| Field | Rule(s) | Error Message |
|---|---|---|
| `start` | required, date | Default |
| `end` | nullable, date | Default |
| `day_type_id` | required, exists:tt_day_types,id | Default |

**Controller-level (addDayTypeToWorkingDay):**
- Duplicate day type on same date → `"{name}" is already assigned to this date.`
- Max 4 types per date → `"This date already has 4 day types (max)."`
- Adding working type to a date with non-working types → `"Cannot add a working day type — this date is already a holiday."`
- Adding non-working type to a date with working types → `"Cannot add a holiday — this date already has working day type(s)."`
- Adding second non-working type → `"Only one holiday type allowed per date."`

**Working Days — AJAX Edit (ajaxEdit)**

| Field | Rule(s) | Error Message |
|---|---|---|
| `id` | required, string | `"Invalid event ID."` (controller check) |
| `date` | required, date | Default |

**Controller-level:**
- Parsed event ID yields null → `"Invalid event ID."` (422)
- Source slot is empty → `"Source slot is empty."` (422)
- Source day type not found → `"Source day type not found."` (422)
- Same source and target date → `"No change."` (200, not an error)
- Target add violates mutual exclusion → RuntimeException caught and returned as 422

**Working Days — AJAX Update Remark (ajaxUpdateRemark)**

| Field | Rule(s) | Error Message |
|---|---|---|
| `remarks` | nullable, string, max:500 | Default |

**Working Days — AJAX Destroy (ajaxDestroy)**

**Controller-level:**
- Invalid event ID → `"Invalid event ID."` (422)
- Working day not found → `"Working day not found or already deleted."` (404)
- Slot already empty → `"That slot is already empty."` (422)
- Last slot with linked records and no force flag → `"{N} class working day record(s) are linked to {date}. Removing the last day type will also remove those records."` (200, requires_confirm=true)

**Working Days — AJAX Initialize Working Days (ajaxInitializeWorkingDays)**

**Controller-level:**
- No current session or missing dates → `"No current academic session found or session has no start/end dates."` (422)
- No active Working Day type → `"No active Working Day type found."` (422)
- No active Holiday type → `"No active Holiday day type found."` (422)

**Class Working Days — Resource CRUD (ClassWorkingDayController — inline validation)**

| Field | Rule(s) | Error Message |
|---|---|---|
| `academic_session_id` | required, integer, exists:sch_organization_academic_sessions,id | Default |
| `date` | required, date | Default |
| `class_id` | required, integer, exists:sch_classes,id | Default |
| `section_id` | nullable, integer, exists:sch_sections,id | Default |
| `working_day_id` | nullable, integer, exists:tt_working_days,id | Default |
| `period_set_id` | nullable, integer, exists:tt_period_sets,id | Default |
| `is_exam_day` | nullable, boolean | Normalized via `$request->boolean()` |
| `is_ptm_day` | nullable, boolean | Normalized via `$request->boolean()` |
| `is_half_day` | nullable, boolean | Normalized via `$request->boolean()` |
| `is_holiday` | nullable, boolean | Normalized via `$request->boolean()` |
| `is_study_day` | nullable, boolean | Normalized via `$request->boolean()` |
| `is_active` | nullable, boolean | Normalized via `$request->boolean()` |

**Class Working Days — AJAX Store (ajaxStore)**

| Field | Rule(s) | Error Message |
|---|---|---|
| `start` | required, date | Default |
| `end` | nullable, date | Default |
| `class_ids` | required, array, min:1 | Default |
| `class_ids.*` | integer, exists:sch_classes,id | Default |
| `section_ids` | nullable, array | Default |
| `section_ids.*` | integer, exists:sch_sections,id | Default |
| `day_type` | required, string | Default |
| `period_set_id` | nullable, integer, exists:tt_period_sets,id | Default |
| `send_notification` | nullable, boolean | Default |
| `notification_channels` | nullable, array | Default |
| `notification_channels.*` | string, in:email,sms,in_app | Default |

**Controller-level:**
- Underlying WorkingDay row does not exist for a date → `"{date} has not been configured in Working Days yet. Please go to the Working Days tab and add this date first."` (422)

**Class Working Days — AJAX Initialize (ajaxInitialize)**

| Field | Rule(s) | Error Message |
|---|---|---|
| `class_ids` | required, array, min:1 | Default |
| `class_ids.*` | integer, exists:sch_classes,id | Default |
| `section_ids` | nullable, array | Default |
| `section_ids.*` | integer, exists:sch_sections,id | Default |
| `period_set_id` | nullable, integer, exists:tt_period_sets,id | Default |
| `clear_existing` | required, boolean | Default |

**Controller-level:**
- No current session → `"No current academic session."` (422)
- No working days in session range → `"No working days found. Please auto-fill Working Days first."` (422)

**Class Working Days — Toggle Status (toggleStatus)**

| Field | Rule(s) | Error Message |
|---|---|---|
| `is_active` | required, boolean | Default |

**Controller-level (status switch failure):** JSON `{ success: false, is_active: ..., message: flash('status_switch_failed.*') }` with 422 status.

## Error Handling and Validation Messages

| Scenario | Message | Type |
|---|---|---|
| School day unique code violation | `validation.unique` (Laravel default) | Validation rule |
| School day day_of_week out of range (not 1-7) | `validation.between` | Validation rule |
| School day ordinal < 1 | `validation.min` | Validation rule |
| Day type code already exists (including soft-deleted) | `validation.unique` | Validation rule |
| Day type name already exists | `validation.unique` | Validation rule |
| Day type ordinal already exists | `validation.unique` | Validation rule |
| Working day duplicate day type on same date | `"{name}" is already assigned to this date.` | Controller check (422 JSON) |
| Working day max 4 types per date | `"This date already has 4 day types (max)."` | Controller check (422 JSON) |
| Working day — add working type to holiday date | `"Cannot add a working day type — this date is already a holiday."` | Controller check (422 JSON) |
| Working day — add holiday to working date | `"Cannot add a holiday — this date already has working day type(s)."` | Controller check (422 JSON) |
| Working day — second non-working type on date | `"Only one holiday type allowed per date."` | Controller check (422 JSON) |
| Working day AJAX edit — invalid event ID | `"Invalid event ID."` | Controller check (422 JSON) |
| Working day AJAX edit — source slot empty | `"Source slot is empty."` | Controller check (422 JSON) |
| Working day AJAX edit — source type not found | `"Source day type not found."` | Controller check (422 JSON) |
| Working day AJAX edit — move to same date | `"No change."` | Controller check (200 JSON) |
| Working day AJAX destroy — invalid event ID | `"Invalid event ID."` | Controller check (422 JSON) |
| Working day AJAX destroy — not found | `"Working day not found or already deleted."` | Controller check (404 JSON) |
| Working day AJAX destroy — slot already empty | `"That slot is already empty."` | Controller check (422 JSON) |
| Working day AJAX destroy — last slot with linked records | `"{N} class working day record(s) are linked to {date}. Removing the last day type will also remove those records."` | Controller check (200 JSON, requires_confirm) |
| Working day initialize — no current session | `"No current academic session found or session has no start/end dates."` | Controller check (422 JSON) |
| Working day initialize — no Working Day type | `"No active Working Day type found."` | Controller check (422 JSON) |
| Working day initialize — no Holiday type | `"No active Holiday day type found."` | Controller check (422 JSON) |
| Class working day AJAX store — working day missing | `"{date} has not been configured in Working Days yet. Please go to the Working Days tab and add this date first."` | Controller check (422 JSON) |
| Class working day AJAX initialize — no session | `"No current academic session."` | Controller check (422 JSON) |
| Class working day AJAX initialize — no working days | `"No working days found. Please auto-fill Working Days first."` | Controller check (422 JSON) |
| Class working day toggle status — save failure | `flash('status_switch_failed.class_working_day')` | Controller check (422 JSON) |
| School day toggle status — save failure | `flash('status_switch_failed.school_day')` | Controller check (422 JSON) |
| Day type toggle status — save failure | `flash('status_switch_failed.day_type')` | Controller check (422 JSON) |
| Working day toggle status — save failure | `flash('status_switch_failed.working_day')` | Controller check (422 JSON) |
| Any gate failure | 403 Forbidden (Laravel `AuthorizationException`) | Gate |

## Success Scenarios

**SC-001 — Initialize Working Day Calendar for New Session.** The administrator has configured school days (Mon-Sat open, Sun closed) and verified that active Study Day and Holiday day types exist. They click "Initialize Calendar" on the Working Days tab without the clear_existing flag. For a session from 1 April 2026 to 31 March 2027 (365 days), the system creates 365 WorkingDay rows — Sundays get the Holiday type with `is_school_day = false`, all other days get the Study Day type with `is_school_day = true`. The response is `{ status: true, message: "Initialized 365 days (2026-04-01 to 2027-03-31). School-closed days set as Holiday, rest as Working Day." }`.

**SC-002 — Stack PTM Day Alongside Study Day.** The school has a PTM on 10 September. The administrator clicks 10 September on the Working Days calendar and selects the PTM Day type. `ajaxStore()` finds an existing row (already has Study Day in slot 1 from initialization). The PTM Day type has `is_working_day = true`, so it passes mutual exclusion. The system finds slot 2 is empty, assigns PTM Day there, and recomputes `is_school_day = true`. The response is `{ status: true, message: "Saved 1 day(s)." }`. The date now has Study Day + PTM Day, and because PTM Day has `reduced_periods = true`, the date is a half-day.

**SC-003 — Drag a Holiday to a New Date.** The administrator drags a Holiday event from 15 August to 16 August. `ajaxEdit()` parses the event ID, removes the Holiday slot from 15 August (compacting remaining slots upward), and adds it to 16 August's first free slot. If 16 August had only a Study Day, the Holiday type (non-working) triggers the mutual exclusion rule and the move fails with an error message. If 16 August had no working types, the Holiday is added successfully.

**SC-004 — Create Class Override for Exam Day.** The administrator selects Class 10-A, date range 1 March to 15 March, day type "exam", on the Class Working Days tab. `ajaxStore()` validates the underlying WorkingDay rows exist for all 15 dates, resolves "exam" to `{ is_exam_day: true, is_ptm_day: false, is_half_day: false, is_holiday: false, is_study_day: false }`, and creates 15 ClassWorkingDay records (one per date). The response is `{ status: true, message: "15 class working day(s) saved.", count: 15 }`. The calendar shows these dates in red for Class 10-A.

**SC-005 — Restore a Trashed School Day.** The administrator restores a Sunday that was soft-deleted. `SchoolDayController@restore()` finds the trashed record via `onlyTrashed()`, calls `restore()`, sets `is_active = true`, and saves. The Sunday row reappears in the School Days tab with its original values. Activity is logged with message "School day was restored successfully."

## Failure Scenarios

**FC-001 — Initialize Without Active Holiday Type.** The administrator deletes or deactivates all non-working day types, then tries to initialize the calendar. `ajaxInitializeWorkingDays()` cannot find a Holiday type after checking code 'H', 'HD', and the fallback first active non-working type. The response is `{ status: false, message: "No active Holiday day type found." }` with 422 status. The calendar is not initialized.

**FC-002 — Create Class Override on Uninitialized Date.** The administrator selects a date range that includes a date not yet configured in the Working Days tab. `ajaxStore()` validates each date's underlying WorkingDay row. For the unconfigured date, no row is found, and a RuntimeException is thrown with message `"15 Aug 2026 has not been configured in Working Days yet. Please go to the Working Days tab and add this date first."` The entire operation is rolled back, and no records are created.

**FC-003 — Add Duplicate Day Type to Same Date.** A date already has Study Day assigned. The administrator attempts to add another Study Day. `addDayTypeToWorkingDay()` finds the new type ID already exists in one of the four slots and throws `"Study Day is already assigned to this date."` The date is reported as skipped in the `ajaxStore()` response.

**FC-004 — Delete Last Slot with Linked Class Records Without Confirmation.** A WorkingDay row has linked ClassWorkingDay records. The administrator deletes the only remaining day type slot without setting the `force` flag. `ajaxDestroy()` returns `{ status: false, requires_confirm: true, linked_count: 5, date_label: "15 Aug 2026", message: "5 class working day record(s) are linked to 15 Aug 2026. Removing the last day type will also remove those records." }` with 200 status. The deletion does not proceed. The UI shows a confirmation dialog.

**FC-005 — Gate Authorization Failure.** An administrator without the `timetable-foundation.working-day.create` permission tries to access the Working Day create form or call `ajaxStore()`. Laravel throws an `AuthorizationException` and returns a 403 Forbidden response. The record is not created.

## Dependencies module and tables

| Dependency | Type | Details |
|---|---|---|
| `sch_organization_academic_sessions` | FK parent (tt_working_days, tt_class_working_days_jnt) | `academic_session_id` references `sch_organization_academic_sessions.id` (no FK constraint in DDL but used in queries via `OrganizationAcademicSession` model) |
| `tt_day_types` | FK parent (tt_working_days) | `day_type1_id`, `day_type2_id`, `day_type3_id`, `day_type4_id` each FK to `tt_day_types.id` with `ON DELETE RESTRICT` |
| `tt_working_days` | FK parent (tt_class_working_days_jnt) | `working_day_id` FK to `tt_working_days.id` (no explicit FK in DDL but used in queries and cascade logic) |
| `sch_classes` | FK parent (tt_class_working_days_jnt) | `class_id` FK to `sch_classes.id` |
| `sch_sections` | FK parent (tt_class_working_days_jnt) | `section_id` FK to `sch_sections.id` (nullable) |
| `tt_period_sets` | FK parent (tt_class_working_days_jnt) | `period_set_id` FK to `tt_period_sets.id` (nullable) |
| `tt_class_working_days_jnt` | Child (of tt_working_days) | Force-deleted when parent WorkingDay row's last slot is removed via `ajaxDestroy()` |
| `sch_academic_term` | Counter target | DDL conditions specify counter updates on `term_total_teaching_days`, `term_total_exam_days`, `term_total_working_days` (not yet implemented) |
| `SpecialDayAssigned` event | Event | Dispatched from `ClassWorkingDayController@ajaxStore` when `send_notification` is true; no listener registered |
| `activityLog()` helper | Service | All controllers log create, update, delete, restore, force-delete, and toggle operations |

**Table:** `tt_school_days`

| Column | Type | Details |
|--------|------|---------|
| `id` | TINYINT UNSIGNED | Primary key, auto-increment |
| `code` | VARCHAR(10) | NOT NULL, UNIQUE (`uq_schoolday_code`), e.g. 'MON', 'TUE' |
| `name` | VARCHAR(20) | NOT NULL, e.g. 'Monday', 'Tuesday' |
| `short_name` | VARCHAR(5) | NOT NULL, e.g. 'Mon', 'Tue' |
| `day_of_week` | TINYINT UNSIGNED | NOT NULL, UNIQUE (`uq_schoolday_dow`), ISO 8601: 1–7 |
| `ordinal` | TINYINT UNSIGNED | NOT NULL, indexed (`idx_schoolday_ordinal`), display order |
| `is_school_day` | TINYINT(1) | NOT NULL, DEFAULT 1 — 1 = school open, 0 = closed |
| `is_active` | TINYINT(1) | NOT NULL, DEFAULT 1 |
| `created_at` | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |
| `updated_at` | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP |
| `deleted_at` | TIMESTAMP | NULL, soft delete |

**Table:** `tt_day_types`

| Column | Type | Details |
|--------|------|---------|
| `id` | TINYINT UNSIGNED | Primary key, auto-increment |
| `code` | VARCHAR(20) | NOT NULL, UNIQUE (`uq_daytype_code`), e.g. 'STUDY', 'HOLIDAY', 'EXAM' |
| `name` | VARCHAR(100) | NOT NULL, UNIQUE (`uq_daytype_name`) |
| `description` | VARCHAR(255) | NULL |
| `is_working_day` | TINYINT(1) | NOT NULL, DEFAULT 1 — 1 = working, 0 = non-working |
| `reduced_periods` | TINYINT(1) | NOT NULL, DEFAULT 0 — 1 = fewer periods on this type |
| `ordinal` | TINYINT UNSIGNED | NOT NULL, DEFAULT 1, UNIQUE (`uq_daytype_ordinal`) |
| `is_active` | TINYINT(1) | NOT NULL, DEFAULT 1 |
| `created_at` | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |
| `updated_at` | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP |
| `deleted_at` | TIMESTAMP | NULL, soft delete |

**Table:** `tt_working_days`

| Column | Type | Details |
|--------|------|---------|
| `id` | INT UNSIGNED | Primary key, auto-increment |
| `academic_session_id` | SMALLINT UNSIGNED | NOT NULL, FK to `sch_org_academic_sessions_jnt.id` |
| `date` | DATE | NOT NULL, UNIQUE (`uq_workday_date`) |
| `day_type1_id` | TINYINT UNSIGNED | NOT NULL, FK to `tt_day_types.id` ON DELETE RESTRICT |
| `day_type2_id` | TINYINT UNSIGNED | NULL, FK to `tt_day_types.id` ON DELETE RESTRICT |
| `day_type3_id` | TINYINT UNSIGNED | NULL, FK to `tt_day_types.id` ON DELETE RESTRICT |
| `day_type4_id` | TINYINT UNSIGNED | NULL, FK to `tt_day_types.id` ON DELETE RESTRICT |
| `is_school_day` | TINYINT(1) | NOT NULL, DEFAULT 1 — 1 = school open, 0 = closed |
| `remarks` | VARCHAR(255) | NULL |
| `is_active` | TINYINT(1) | NOT NULL, DEFAULT 1 |
| `created_at` | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |
| `updated_at` | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP |
| `deleted_at` | TIMESTAMP | NULL, soft delete |
| | | INDEX `idx_workday_daytype` on (`day_type1_id`, `day_type2_id`, `day_type3_id`, `day_type4_id`) |
| | | FK `fk_workday_daytype1` REFERENCES `tt_day_types(id)` ON DELETE RESTRICT |
| | | FK `fk_workday_daytype2` REFERENCES `tt_day_types(id)` ON DELETE RESTRICT |
| | | FK `fk_workday_daytype3` REFERENCES `tt_day_types(id)` ON DELETE RESTRICT |
| | | FK `fk_workday_daytype4` REFERENCES `tt_day_types(id)` ON DELETE RESTRICT |

**Table:** `tt_class_working_days_jnt`

| Column | Type | Details |
|--------|------|---------|
| `id` | INT UNSIGNED | Primary key, auto-increment |
| `academic_session_id` | SMALLINT UNSIGNED | NOT NULL |
| `date` | DATE | NOT NULL |
| `class_id` | INT UNSIGNED | NOT NULL, FK to `sch_classes.id` |
| `section_id` | INT UNSIGNED | NULL, FK to `sch_sections.id` |
| `working_day_id` | INT UNSIGNED | NOT NULL, FK to `tt_working_days.id` (used in queries) |
| `is_exam_day` | TINYINT(1) | NOT NULL, DEFAULT 0 |
| `is_ptm_day` | TINYINT(1) | NOT NULL, DEFAULT 0 |
| `is_half_day` | TINYINT(1) | NOT NULL, DEFAULT 0 |
| `is_holiday` | TINYINT(1) | NOT NULL, DEFAULT 0 |
| `is_study_day` | TINYINT(1) | NOT NULL, DEFAULT 1 |
| `is_active` | TINYINT(1) | NOT NULL, DEFAULT 1 |
| `created_at` | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |
| `updated_at` | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP |
| `deleted_at` | TIMESTAMP | NULL, soft delete |
| | | UNIQUE KEY `uq_class_working_day` (`class_id`, `working_day_id`) |
| | | INDEX `idx_class_working_day_class` (`class_id`) |
| | | INDEX `idx_class_working_day_working_day` (`working_day_id`) |

> **Note:** The DDL does not define explicit FK constraints with `ON DELETE` actions for `academic_session_id`, `class_id`, `section_id`, or `working_day_id` on `tt_class_working_days_jnt`. The cascade behaviour when deleting a `tt_working_days` row is implemented in controller code (`ajaxDestroy` force-deletes linked `ClassWorkingDay` records).
