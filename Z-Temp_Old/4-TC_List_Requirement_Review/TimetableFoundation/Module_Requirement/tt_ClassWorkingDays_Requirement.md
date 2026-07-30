# Class Working Days — Business Requirements

## What This Screen Does

The Class Working Days screen allows administrators to **override the school-wide working day calendar for specific classes**. While the Working Days tab defines what kind of day a particular date is for the entire school, the Class Working Days tab lets the school designate a date as an exam day, PTM day, half-day, holiday, or study day for one or more specific classes independently of the school-wide designation.

For example, Class 10 may have an exam on a day that is a regular school day for everyone else. Or Class 5 may have a study day on a date declared as a school-wide holiday. This fine-grained control is essential for schools that run multiple sections with different schedules, especially during examination periods, special events, or class-specific activities.

The screen uses a **FullCalendar** interface overlaid with background events from the school-wide Working Days calendar. Administrators can filter by class and section, apply bulk overrides across date ranges, initialise class working days from the school-wide calendar, and delete individual overrides.

## When This Screen Is Used

- **During examination periods** — the administrator selects exam classes and a date range, then assigns the "exam" day type to mark those dates as exam days for specific classes
- **When a class has a special event** — the administrator marks a class's day as PTM day or half-day
- **When a class needs to study on a school holiday** — the administrator creates a class override with "study" day type on a date that is a school-wide holiday, so the class can attend extra classes
- **When an override is no longer needed** — the administrator deletes the class working day record for a specific class and date
- **At the start of a session** — the administrator bulk-initialises class working days from the existing school-wide Working Days, creating default records for all selected classes

## Default Data Load

The Class Working Days tab loads via `TimetableFoundationController@timetableMasters` at route `timetable-foundation.menu.timetableMasters`, with the `tab=class-working-days` query parameter.

The calendar events are lazy-loaded via two AJAX endpoints:
- `eventFeed` (GET `/class-working-day/ajax/events`) — returns class working day events with colour coding by flag type
- `workingDayFeed` (GET `/class-working-day/ajax/working-day-feed`) — returns background events from the school-wide Working Days calendar for reference overlay

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| Class filter dropdown | `timetableMasters()` | Active classes | `is_active = 1` | None |
| Section filter dropdown | `timetableMasters()` | Active sections | `is_active = 1` | None |
| Calendar Events | `eventFeed()` | `ClassWorkingDay::with(academicSession, class, section, workingDay)->whereBetween('date',[$start,$end])` | `class_ids[]`, `section_ids[]`, date range | None |
| Background events | `workingDayFeed()` | `WorkingDay::whereBetween('date',[$start,$end])` with dayType relations | Date range | None |

## Key Fields at a Glance

**Identity Fields**

- **Academic Session ID** — Links the record to the current academic session.
- **Date** — The calendar date for which the override applies.
- **Class** — The school class (e.g., Class 10, Class 5). Each class can have at most one record per working day (unique constraint on `(class_id, working_day_id)`).
- **Section** — Optional section within the class (e.g., A, B). When null, the override applies to all sections of the class.
- **Working Day ID** — References the school-wide WorkingDay row for this date. The underlying WorkingDay must exist before a ClassWorkingDay can be created.

**Day Type Flags**

Five boolean flags determine the nature of the override. They are set via the `resolveDayTypeFlags()` method when the `day_type` string is provided (e.g., "exam", "ptm", "half_day", "holiday", "study"):

- **Is Study Day** (`is_study_day`) — Default `true`. When true, the class holds regular instruction on this date. The `isTeachingAllowed()` method returns `true` only when `is_study_day = true` and `is_holiday = false`.
- **Is Exam Day** (`is_exam_day`) — When true, the class has examinations and normal teaching does not occur.
- **Is PTM Day** (`is_ptm_day`) — When true, parent-teacher meetings are scheduled.
- **Is Half Day** (`is_half_day`) — When true, the class operates on a reduced schedule. Optionally linked to a `period_set_id` for defining the reduced period set.
- **Is Holiday** (`is_holiday`) — When true, the class is on holiday regardless of the school-wide designation.

**Helper Methods**

- **`isTeachingAllowed()`** — Returns `true` when `is_active && is_study_day && !is_holiday`. Used by the system to determine whether teaching can occur for this class on this date.
- **`isSpecialDay()`** — Returns `true` when any of `is_exam_day`, `is_ptm_day`, or `is_half_day` is `true`.

**Additional Fields**

- **Period Set ID** — Optional reference to a `tt_period_sets` record for defining alternative period timing on half-days or special schedules.
- **Is Active** — Standard enable/disable flag.
- **Deleted At** — Populated on soft delete. Supports trash, restore, and force-delete flows.

## Business Rules and Conditions

**Working Day Must Exist First.** Before a class working day record can be created for a date, the underlying WorkingDay row for that date must exist in `tt_working_days`. The `ajaxStore` method validates this explicitly and throws a `RuntimeException` with a message directing the user to configure the date in the Working Days tab first.

**One Record Per Class Per Working Day.** The unique constraint on `(class_id, working_day_id)` ensures that each class has at most one override record per working day. When an existing record is found (including soft-deleted), the system restores and updates it rather than creating a duplicate.

**Day Type Flag Resolution.** The `resolveDayTypeFlags()` private method maps a `day_type` string to boolean flags:

| day_type string | is_study_day | is_exam_day | is_ptm_day | is_half_day | is_holiday |
|----------------|-------------|-------------|------------|-------------|------------|
| "study" | true | false | false | false | false |
| "exam" | false | true | false | false | false |
| "ptm" | false | false | true | false | false |
| "half_day" | false | false | false | true | false |
| "holiday" | false | false | false | false | true |

These flags are mutually exclusive at the business level — a single record represents a single day type designation.

**Bulk Cross-Product Creation.** The `ajaxStore` method accepts `class_ids[]`, `section_ids[]`, a date range, and a `day_type` string. It creates records as a cross-product: for each date in the range, for each class in `class_ids`, for each section in `section_ids`, one ClassWorkingDay record is created. For example, 2 classes × 2 sections × 5 dates = 20 records.

**Trashed Record Recovery.** During `ajaxStore`, if a ClassWorkingDay record already exists in a soft-deleted state for the `(class_id, working_day_id)` combination, the system restores it and updates its flags rather than failing with a duplicate error.

**Initialisation from Working Days.** The `ajaxInitialize` method creates default ClassWorkingDay records from existing WorkingDay rows for selected classes. It maps:
- `is_holiday = !workingDay.is_school_day` — if the school-wide day is closed, the class override is a holiday
- `is_study_day = workingDay.is_school_day` — if the school-wide day is open, the class override is a study day
- All other flags (`is_exam_day`, `is_ptm_day`, `is_half_day`) default to `false`

The method supports `clear_existing` to force-delete existing records before re-initialisation, and an optional `period_set_id` to apply to all created records.

**Teaching Allowed Computation.** The `isTeachingAllowed()` helper determines if teaching can occur: `is_active && is_study_day && !is_holiday`. If the record is inactive, or if the class is on holiday, teaching is not allowed regardless of the study day flag.

**Notification Dispatch.** When `send_notification` is `true` in `ajaxStore`, a `SpecialDayAssigned` event is dispatched with the created records, notification channels (email, SMS, in-app), and the authenticated user. No listener is registered in the current codebase — this is a dispatch-only integration point for future notification handling.

## Workflow Steps

**Filtering by Class and Section.** The administrator navigates to the Class Working Days tab. The FullCalendar initially shows all class working days. They use the class and section filter dropdowns to narrow the view to specific classes. The calendar re-fetches events from `eventFeed` with `class_ids[]` and `section_ids[]` parameters. Background events from `workingDayFeed` remain visible for reference.

**Creating Class Overrides for Exam Day.** The administrator selects a date range (e.g., 1 March to 15 March), one or more classes (e.g., Class 10, Class 12), optionally sections, and chooses "exam" as the day type. They click "Save." `POST /class-working-day/ajax/store` validates the inputs, verifies the underlying WorkingDay rows exist for all dates in the range, resolves "exam" to the flag set, and creates records for the cross-product of classes × sections × dates. If `send_notification` is checked, a notification event is dispatched.

**Initialising from Working Days.** The administrator clicks "Initialize from Working Days." A dialog prompts for class selection and an optional period set. They select one or more classes and confirm. `POST /class-working-day/ajax/initialize` creates default records for every existing WorkingDay in the session, mapping school-day to study-day and closed-day to holiday. If `clear_existing` is checked, existing ClassWorkingDay records for the selected classes are force-deleted before creation.

**Deleting a Class Override.** The administrator clicks the delete icon on a calendar event. `DELETE /class-working-day/ajax/delete/{id}` is called with the event ID (format `cwd-{id}`). The method strips the `cwd-` prefix and force-deletes the record.

**Viewing Class Override Details.** The administrator clicks on a calendar event to view details. A popup shows the class name, section, date, day type flags, and the underlying working day reference.

## Example Scenario

St. Mary's High School has already initialised the Working Days calendar. Mrs. Sharma now needs to configure class-specific schedules.

Class 10 has board exam practicals from 1 March to 10 March. Mrs. Sharma goes to the Class Working Days tab, selects Class 10, sets the date range to 1 March – 10 March, chooses "exam" as the day type, and clicks Save. The system validates that all 10 dates have WorkingDay rows, resolves "exam" to `{ is_exam_day: true, is_study_day: false, is_ptm_day: false, is_half_day: false, is_holiday: false }`, and creates 10 ClassWorkingDay records — one per date. The calendar shows these dates in a distinct colour for Class 10.

Class 5 has a special PTM on 15 September. Mrs. Sharma selects Class 5, date 15 September, day type "ptm." The system creates a record with `is_ptm_day = true`. Since Class 5 also has a study day from the initialised defaults, the administrator first initialised Class 5 from working days, then edits the 15 September record to change it from study to ptm.

On 2 October (a school-wide holiday), Class 12 needs extra revision classes. Mrs. Sharma creates an override for Class 12 on 2 October with day type "study." The system sets `is_study_day = true` and `is_holiday = false`, overriding the school-wide holiday for this class. The `isTeachingAllowed()` method returns `true` for this class on this date.

## Related Screens

- **Working Days** — provides the underlying school-wide calendar that Class Working Days depends on; background events from this screen are overlaid on the Class Working Days calendar
- **School Days** — indirectly affects Class Working Days through the working day initialization chain
- **Day Types** — defines classifications that inform the class override flag semantics
- **Period Sets** — defines alternative period schedules referenced by `period_set_id` for half-day or special schedules
- **Academic Terms** — defines the session scope for initialization

## Requirements

- `ClassWorkingDayController` provides standard CRUD (`index()`, `create()`, `store()`, `show()`, `edit()`, `update()`, `destroy()`) plus AJAX endpoints: `ajaxStore()` (POST `/class-working-day/ajax/store`), `ajaxDestroy()` (DELETE `/class-working-day/ajax/delete/{id}`), `ajaxInitialize()` (POST `/class-working-day/ajax/initialize`), `eventFeed()` (GET `/class-working-day/ajax/events`), and `workingDayFeed()` (GET `/class-working-day/ajax/working-day-feed`).

- The `ajaxStore()` method validates `start` (required date), `end` (nullable date), `class_ids` (required array, min:1), `class_ids.*` (exists:sch_classes,id), `section_ids` (nullable array), `section_ids.*` (exists:sch_sections,id), `day_type` (required string), `period_set_id` (nullable exists:tt_period_sets,id), `send_notification` (nullable boolean), `notification_channels` (nullable array), `notification_channels.*` (string, in:email,sms,in_app). For each date in the range, validates that a WorkingDay row exists. Resolves the `day_type` string via `resolveDayTypeFlags()`. Creates records as a cross-product of classes × sections × dates. Uses `withTrashed()` to find existing records (restoring and updating if found). Dispatches `SpecialDayAssigned` event when `send_notification` is true.

- The `ajaxDestroy()` method strips the `cwd-` prefix from the event ID and force-deletes the record via `withTrashed()->findOrFail($id)->forceDelete()`.

- The `ajaxInitialize()` method validates `class_ids` (required array, min:1), `class_ids.*` (exists:sch_classes,id), `section_ids` (nullable array), `period_set_id` (nullable exists:tt_period_sets,id), `clear_existing` (required boolean). For each WorkingDay in the current session, creates a ClassWorkingDay record: `is_holiday = !wd.is_school_day`, `is_study_day = wd.is_school_day`, other flags false. If `clear_existing` is true, force-deletes existing records for selected classes first.

- The `eventFeed()` method filters by `class_ids[]`, `section_ids[]`, and date range. Returns events with colour coding based on the day type flag (exam=red, ptm=green, half_day=orange, holiday=grey, study=blue).

- The `workingDayFeed()` method returns school-wide Working Day events as background events for reference overlay on the calendar.

- The `resolveDayTypeFlags()` private method maps strings "study", "exam", "ptm", "half_day", "holiday" to their respective boolean flag arrays.

- Gates: `timetable-foundation.class-working-day.viewAny` (tab + eventFeed + workingDayFeed), `.create` (create/store/ajaxStore/ajaxInitialize), `.view` (show), `.update` (edit/update/toggleStatus), `.delete` (destroy/ajaxDestroy), `.restore` (restore/trashed), `.forceDelete` (forceDelete).

- Policy: `ClassWorkingDayPolicy` in `Modules\TimetableFoundation\Policies` with standard CRUD methods.

- Event: `Modules\TimetableFoundation\Events\SpecialDayAssigned` dispatched with `classWorkingDays` (Collection), `channels` (array), and `user` (authenticated user). No listener is registered in the current codebase.

- The `ClassWorkingDay` model uses `SoftDeletes` and `HasFactory`. It provides `isTeachingAllowed()` and `isSpecialDay()` helper methods.

## Who Can Access

| Gate/Permission | Methods | Notes |
|---|---|---|
| `timetable-foundation.class-working-day.viewAny` | `index`, `eventFeed`, `workingDayFeed` | Loads tab and calendar events |
| `timetable-foundation.class-working-day.create` | `create`, `store`, `ajaxStore`, `ajaxInitialize` | Create, store, AJAX add, initialize |
| `timetable-foundation.class-working-day.view` | `show` | View single record |
| `timetable-foundation.class-working-day.update` | `edit`, `update`, `toggleStatus` | Edit, update, toggle |
| `timetable-foundation.class-working-day.delete` | `destroy`, `ajaxDestroy` | Soft-delete, AJAX force-delete |
| `timetable-foundation.class-working-day.restore` | `restore`, `trashedClassWorkingDay` | Restore and view trash |
| `timetable-foundation.class-working-day.forceDelete` | `forceDelete` | Permanent delete |

Global page access to the tab is gated by `timetable-foundation.viewAny` on `TimetableFoundationController@timetableMasters`.

## Logic Flow

**1. Page Load (Class Working Days Tab).** The user navigates to `timetable-foundation.menu.timetableMasters?tab=class-working-days`. A FullCalendar instance is rendered with class/section filter dropdowns. Two AJAX calls are made: `eventFeed` for class events and `workingDayFeed` for background reference events.

**2. Bulk Create Overrides (AJAX).** The user selects classes, sections, date range, and day type. `ajaxStore()` validates all inputs. For each date in the range, it checks that the underlying WorkingDay row exists (throws RuntimeException with a descriptive message if not). It resolves the `day_type` string to flags via `resolveDayTypeFlags()`. For each date × class × section combination, it uses `withTrashed()` to find an existing record — if found, restores and updates flags; otherwise creates a new record. On completion, if `send_notification` is true, dispatches `SpecialDayAssigned` event. Returns `{ status: true, message: "{count} class working day(s) saved.", count }`.

**3. Delete Override (AJAX).** The user clicks delete on a calendar event. `ajaxDestroy()` strips the `cwd-` prefix from the event ID, finds the record via `withTrashed()->findOrFail($id)`, and calls `forceDelete()`. Returns `{ status: true, message: "Class working day deleted." }`.

**4. Initialize from Working Days (AJAX).** The user selects classes and clicks "Initialize from Working Days." `ajaxInitialize()` validates the inputs and the current session. If `clear_existing` is true, force-deletes existing ClassWorkingDay records for the selected classes. Then iterates all WorkingDay rows in the session, creating a ClassWorkingDay for each date × class combination. Maps `is_holiday = !wd.is_school_day` and `is_study_day = wd.is_school_day`. Returns `{ status: true, message: "Created {count} class working day(s)." }`.

**5. Event Feed (AJAX).** The FullCalendar calls `eventFeed()` with date range and selected class/section IDs. The controller queries `ClassWorkingDay::with(relations)->whereBetween('date',[$start,$end])` with optional `class_ids[]` and `section_ids[]` filters. Each event includes the class name, section name, day type flags, and a colour based on which flag is active. Events have event ID format `cwd-{id}`.

**6. Working Day Feed (AJAX).** The FullCalendar calls `workingDayFeed()` for background reference. Returns the school-wide WorkingDay events for the visible date range. These are rendered as background events behind the class-specific events.

**7. Delete (Resource).** The user can also soft-delete via the resource `destroy()` method. Sets `is_active = false`, saves, calls `delete()`. The record moves to the trash. `restore()` restores and reactivates. `forceDelete()` permanently removes the record.

## Validate Before Save

**Class Working Days — Resource CRUD (store)**

| Field | Rule(s) | Error Message |
|---|---|---|
| `academic_session_id` | required, integer, exists:sch_organization_academic_sessions,id | Laravel default |
| `date` | required, date | Laravel default |
| `class_id` | required, integer, exists:sch_classes,id | Laravel default |
| `section_id` | nullable, integer, exists:sch_sections,id | Laravel default |
| `working_day_id` | nullable, integer, exists:tt_working_days,id | Laravel default |
| `period_set_id` | nullable, integer, exists:tt_period_sets,id | Laravel default |
| `is_exam_day` | nullable, boolean | Normalized via `$request->boolean()` |
| `is_ptm_day` | nullable, boolean | Normalized via `$request->boolean()` |
| `is_half_day` | nullable, boolean | Normalized via `$request->boolean()` |
| `is_holiday` | nullable, boolean | Normalized via `$request->boolean()` |
| `is_study_day` | nullable, boolean | Normalized via `$request->boolean()` |
| `is_active` | nullable, boolean | Normalized via `$request->boolean()` |

**Class Working Days — AJAX Store (ajaxStore)**

| Field | Rule(s) | Error Message |
|---|---|---|
| `start` | required, date | Laravel default |
| `end` | nullable, date | Laravel default |
| `class_ids` | required, array, min:1 | Laravel default |
| `class_ids.*` | integer, exists:sch_classes,id | Laravel default |
| `section_ids` | nullable, array | Laravel default |
| `section_ids.*` | integer, exists:sch_sections,id | Laravel default |
| `day_type` | required, string | Laravel default |
| `period_set_id` | nullable, integer, exists:tt_period_sets,id | Laravel default |
| `send_notification` | nullable, boolean | Laravel default |
| `notification_channels` | nullable, array | Laravel default |
| `notification_channels.*` | string, in:email,sms,in_app | Laravel default |

**Controller-level:**
- Underlying WorkingDay row does not exist for a date → `"{date} has not been configured in Working Days yet. Please go to the Working Days tab and add this date first."` (422)

**Class Working Days — AJAX Initialize (ajaxInitialize)**

| Field | Rule(s) | Error Message |
|---|---|---|
| `class_ids` | required, array, min:1 | Laravel default |
| `class_ids.*` | integer, exists:sch_classes,id | Laravel default |
| `section_ids` | nullable, array | Laravel default |
| `section_ids.*` | integer, exists:sch_sections,id | Laravel default |
| `period_set_id` | nullable, integer, exists:tt_period_sets,id | Laravel default |
| `clear_existing` | required, boolean | Laravel default |

**Controller-level:**
- No current session → `"No current academic session."` (422)
- No working days found for session → `"No working days found. Please auto-fill Working Days first."` (422)

**Class Working Days — Toggle Status**

| Field | Rule(s) | Error Message |
|---|---|---|
| `is_active` | required, boolean | Laravel default |

**Controller-level:**
- Save failure → JSON `{ success: false, is_active: <current>, message: flash('status_switch_failed.class_working_day') }` with 422 status.

## Error Handling and Validation Messages

| Scenario | Message | Type |
|---|---|---|
| AJAX store — working day missing for date | `"{date} has not been configured in Working Days yet. Please go to the Working Days tab and add this date first."` | Controller check (422 JSON) |
| AJAX initialize — no current session | `"No current academic session."` | Controller check (422 JSON) |
| AJAX initialize — no working days found | `"No working days found. Please auto-fill Working Days first."` | Controller check (422 JSON) |
| Toggle status — save failure | `flash('status_switch_failed.class_working_day')` | Controller check (422 JSON) |
| Validation failure (any field) | Laravel default validation messages | Validation rule |
| Gate authorization failure | 403 Forbidden (`AuthorizationException`) | Gate |
| Guest access | Redirect to `/login` | Authentication |

## Success Scenarios

**SC-001 — Bulk Create Exam Overrides for Multiple Classes.** The administrator selects Class 10-A and Class 10-B, date range 1 March–15 March, day type "exam." The system validates all 15 dates have WorkingDay rows, resolves "exam" flags, and creates 30 records (2 classes × 15 dates × 1 section each). Response: `{ status: true, message: "30 class working day(s) saved.", count: 30 }`.

**SC-002 — Initialize from Working Days.** The administrator selects Class 5, Class 6, Class 7 and clicks "Initialize from Working Days." The system finds 200 WorkingDay rows in the session and creates 600 ClassWorkingDay records (3 classes × 200 dates). Study days map to `is_study_day=true`, holidays map to `is_holiday=true`. Response: `{ status: true, message: "Created 600 class working day(s)." }`.

**SC-003 — Override School Holiday for a Class.** Class 12 needs to study on a school-wide holiday (2 October). The administrator selects Class 12, date 2 October, day type "study." The system creates a record with `is_study_day=true, is_holiday=false`. The class calendar shows a study day event while the background working day feed shows a holiday.

**SC-004 — Delete a Class Override.** The administrator clicks delete on a Class 10 exam day event. `ajaxDestroy` force-deletes the record. The event disappears from the calendar.

**SC-005 — Filter by Class.** The administrator selects Class 10 from the class filter dropdown. The calendar reloads with only Class 10's events visible.

## Failure Scenarios

**FC-001 — Create Override on Uninitialized Date.** The administrator selects a date range that includes dates not yet configured in the Working Days tab. `ajaxStore` validates each date and returns 422 with `"15 Aug 2026 has not been configured in Working Days yet. Please go to the Working Days tab and add this date first."` The entire operation is rolled back.

**FC-002 — Initialize Without Working Days.** The administrator tries to initialize Class Working Days before initializing the school-wide Working Day calendar. `ajaxInitialize` returns 422 with `"No working days found. Please auto-fill Working Days first."`

**FC-003 — Initialize Without Active Session.** No current academic session exists. `ajaxInitialize` returns 422 with `"No current academic session."`

**FC-004 — Missing Required Fields in AJAX Store.** The administrator submits without selecting classes or a date range. Validation returns errors for `class_ids` (required), `start` (required), `day_type` (required).

**FC-005 — Unauthorized Access.** A user without `class-working-day.create` permission tries to call `ajaxStore`. 403 Forbidden.

## Dependencies module and tables

| Dependency | Type | Details |
|---|---|---|
| `tt_class_working_days_jnt` | Primary table | Junction table for class × working day overrides |
| `tt_working_days` | FK parent (logical) | `working_day_id` references `tt_working_days.id`; must exist before class override creation |
| `sch_classes` | FK parent | `class_id` FK to `sch_classes.id` |
| `sch_sections` | FK parent (nullable) | `section_id` FK to `sch_sections.id` |
| `tt_period_sets` | FK parent (nullable) | `period_set_id` FK to `tt_period_sets.id` |
| `sch_organization_academic_sessions` | FK parent (logical) | `academic_session_id` references academic sessions |
| `SpecialDayAssigned` event | Event | Dispatched when `send_notification` is true; no listener registered |
| `activityLog()` helper | Service | Logs all state-changing operations |
| `ClassWorkingDayPolicy` | Auth policy | Gates all CRUD + AJAX operations |

**Table:** `tt_class_working_days_jnt`

| Column | Type | Details |
|---|---|---|
| `id` | INT UNSIGNED | Primary key, auto-increment |
| `academic_session_id` | SMALLINT UNSIGNED | NOT NULL |
| `date` | DATE | NOT NULL |
| `class_id` | INT UNSIGNED | NOT NULL, FK to `sch_classes.id` |
| `section_id` | INT UNSIGNED | NULL, FK to `sch_sections.id` |
| `working_day_id` | INT UNSIGNED | NOT NULL, FK to `tt_working_days.id` |
| `is_exam_day` | TINYINT(1) | NOT NULL, DEFAULT 0 |
| `is_ptm_day` | TINYINT(1) | NOT NULL, DEFAULT 0 |
| `is_half_day` | TINYINT(1) | NOT NULL, DEFAULT 0 |
| `is_holiday` | TINYINT(1) | NOT NULL, DEFAULT 0 |
| `is_study_day` | TINYINT(1) | NOT NULL, DEFAULT 1 |
| `is_active` | TINYINT(1) | NOT NULL, DEFAULT 1 |
| `created_at` | TIMESTAMP | NULL DEFAULT NULL |
| `updated_at` | TIMESTAMP | NULL DEFAULT NULL |
| `deleted_at` | TIMESTAMP | NULL DEFAULT NULL |

**Unique Keys:**
- `uq_class_working_day` — on `(class_id, working_day_id)`

**Indexes:**
- `idx_class_working_day_class` — on `class_id`
- `idx_class_working_day_working_day` — on `working_day_id`

> **Note:** The DDL does not define explicit FK constraints with `ON DELETE` actions for `academic_session_id`, `class_id`, `section_id`, or `working_day_id`. The cascade behaviour when deleting a `tt_working_days` row is implemented in controller code.
