# School Days Tab — Business Requirements

## What This Screen Does

The School Days tab defines the **weekly operating template** for the school. It displays seven pre-seeded rows — one for each day of the week (Monday through Sunday) — and lets administrators mark each day as either a school day (open) or a closed day (weekly holiday). This template serves as the foundation for working day calendar initialization: when the system bulk-generates dates for an academic session, it uses the school days configuration to determine which weekdays are working and which are closed.

This is a **simple configuration screen** — the seven rows are seeded during system setup and are not meant to be created or deleted in normal operation. The primary interaction is toggling the `is_school_day` flag (open/closed) and the `is_active` flag (enabled/disabled) for individual days. The screen also supports full CRUD for customisation needs, though creating or deleting weekdays is uncommon.

## When This Screen Is Used

- **At the start of an academic session** — the administrator reviews the school days template to confirm which days are marked as open (e.g., Monday through Saturday) and which are closed (e.g., Sunday) before initializing the working day calendar
- **When the school changes its weekly schedule** — for example, adopting a five-day week (Monday–Friday) instead of a six-day week — the administrator toggles Saturday from school day to closed
- **When a school observes a weekly holiday on a different day** — some schools operate Sunday–Thursday with Friday closed; the administrator updates the template accordingly
- **When a day needs temporary deactivation** — the administrator toggles `is_active` off rather than deleting, preserving the record for future reactivation
- **When a seed day is accidentally deleted** — the administrator uses the school day's CRUD forms to recreate the missing day or restores it from trash

## Default Data Load

The School Days tab loads via `TimetableFoundationController@timetableMasters` at route `timetable-foundation.menu.timetableMasters`, with the `tab=school-days` query parameter. The page gate is `timetable-foundation.viewAny`.

The master page queries all school days with optional filters:

```php
$schoolDays = SchoolDay::query()
    ->when($r->filled('sd_search'), fn($q) => $q->where(function($q) use ($r) {
        $q->where('name', 'like', "%{$r->sd_search}%")
          ->orWhere('code', 'like', "%{$r->sd_search}%");
    }))
    ->when(true, $applyStatus('sd_status', '1'))
    ->orderBy('ordinal')
    ->get();
```

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| School Days table | `timetableMasters()` | `SchoolDay::orderBy('ordinal')` | `sd_search` (name/code), `sd_status` (is_active) | None — all 7 rows returned |

## Key Fields at a Glance

**Identity Fields**

- **Code** — A 3-letter abbreviation uniquely identifying the day (e.g., `MON`, `TUE`, `WED`, `THU`, `FRI`, `SAT`, `SUN`). Max 10 characters. Used as a stable reference in system logic and display.
- **Name** — The full English name of the day (e.g., "Monday", "Tuesday"). Max 20 characters. Displayed in the table and used in filter search.
- **Short Name** — A 2–3 letter abbreviation for compact display (e.g., "Mon", "Tue"). Max 5 characters.

**Temporal Fields**

- **Day of Week** — The ISO 8601 numeric representation (Monday = 1, Tuesday = 2, ..., Sunday = 7). This value is unique — no two days can share the same ISO number. Used by the working day initialization logic to compute closed days from the weekly closed-day config.
- **Ordinal** — The display order (1–7). Controls the row sequence in the table. Also used by the working day initialization logic when resolving day types by ordinal priority.

**Status Flags**

- **Is School Day** — The key business flag. When checked (`1`, default), the school operates on that weekday. When unchecked (`0`), the weekday is a weekly closed day. The working day initialization algorithm reads this flag to assign either the Working Day type or Holiday type to dates falling on that weekday.
- **Is Active** — Standard enable/disable flag. Inactive days are hidden from most queries and from selection. Toggling this off preserves the record without deleting it.
- **Deleted At** — Populated when the record is soft-deleted. The record moves to the trash view and can be restored or force-deleted.

## Business Rules and Conditions

**Seven-Day Constraint.** The `tt_school_days` table is designed to hold exactly seven rows — one for each day of the week. While the schema does not enforce a row-count constraint, the system is seeded with seven rows, and creating additional rows (e.g., a duplicate Monday) is semantically invalid and would violate the unique constraint on `day_of_week` (ISO 1–7).

**Day-of-Week Uniqueness.** The `day_of_week` column has a unique index (`uq_schoolday_dow`). No two records may share the same ISO weekday number. This enforces the natural constraint that each weekday appears at most once.

**Code Uniqueness.** The `code` column has a unique index (`uq_schoolday_code`). Each 3-letter code must be unique across all records, including soft-deleted ones.

**Ordinal Not Enforced as Unique.** The `ordinal` column lacks a unique constraint. Multiple days may share the same ordinal value, which would cause non-deterministic ordering. In practice, the seed data assigns ordinals 1–7, and administrators should maintain this convention.

**Display Order.** Rows are always ordered by `ordinal` ascending. This ensures Monday appears first (ordinal 1) and Sunday last (ordinal 7).

**Deactivation on Delete.** When a school day is soft-deleted via `destroy()`, the controller first sets `is_active = false`, then calls `delete()`. This ensures the day is immediately excluded from active queries even before the SoftDeletes trait hides it.

**Reactivation on Restore.** When a trashed school day is restored, the controller automatically sets `is_active = true`.

**Working Day Calendar Dependency.** The `ajaxInitializeWorkingDays` method in `WorkingDayController` reads the school days template to compute which weekdays are closed. Specifically, it reads the `week_start_day` and `default_school_closed_days_per_week` config values and computes the closed ISO weekday set. Any school day with `is_school_day = false` within that computed set is treated as closed during initialization.

## Workflow Steps

**Reviewing the Weekly Template.** The administrator navigates to Timetable Masters via the sidebar and clicks the School Days tab. The table renders seven rows ordered by ordinal. Each row shows the day name, code, a coloured badge for school day status (green for open, red for closed), a status toggle for `is_active`, and action buttons for view, edit, and trash.

**Toggling a Day's School Status.** The administrator identifies a day whose school status needs changing (e.g., Saturday from open to closed). They click the inline toggle switch for the `is_school_day` column. An AJAX request is sent to the toggle-status endpoint. The controller flips the boolean value. The badge colour updates immediately without a page reload.

**Editing Day Details.** The administrator clicks the Edit button on a day row. The edit form is pre-filled with the current values. They can update the name, short name, or ordinal. The `code` and `day_of_week` fields are typically left unchanged because they uniquely identify the weekday. On submission, the update is saved and the administrator is redirected back to the tab.

**Viewing a Deleted Day in Trash.** After soft-deleting a day, the administrator navigates to the trash view (linked from the School Days tab). The trash view lists soft-deleted records with options to Restore or Force Delete.

## Example Scenario

Sunshine Academy operates Monday through Saturday, with Sunday as the weekly holiday. The academic year starts on 1 April 2026.

The administrator, Mrs. Sharma, navigates to Timetable Masters → School Days tab. She sees the seven pre-seeded rows:

| Code | Name | Day of Week | Ordinal | School Day | Active |
|------|------|-------------|---------|------------|--------|
| MON | Monday | 1 | 1 | Yes | Yes |
| TUE | Tuesday | 2 | 2 | Yes | Yes |
| WED | Wednesday | 3 | 3 | Yes | Yes |
| THU | Thursday | 4 | 4 | Yes | Yes |
| FRI | Friday | 5 | 5 | Yes | Yes |
| SAT | Saturday | 6 | 6 | Yes | Yes |
| SUN | Sunday | 7 | 7 | No | Yes |

All days are active. Sunday has `is_school_day = false`, which correctly reflects the weekly holiday. Mrs. Sharma confirms the template is correct before initializing the working day calendar.

Later, the school board decides to adopt a five-day week (Monday–Friday). Mrs. Sharma returns to the School Days tab and toggles Saturday's `is_school_day` flag to off. The badge changes to "Closed". She then re-initializes the working day calendar, and the system now treats every Saturday as a closed day.

## Related Screens

- **Working Days** — consumes the school days template during calendar initialization to determine which weekdays are open and closed
- **Timetable Config** — stores `week_start_day` and `default_school_closed_days_per_week` settings that work alongside school days to compute the closed-day set
- **Day Types** — defines the classifications (Working Day, Holiday, Exam, etc.) that are assigned to concrete dates on the working day calendar

## Requirements

- `SchoolDayController` provides full CRUD with methods `index()`, `create()`, `store()`, `show()`, `edit()`, `update()`, `destroy()`, `restore()`, `forceDelete()`, `trashedDay()`, and `toggleStatus()` — implements `SoftDeletes` on the `SchoolDay` model. The `destroy()` method sets `is_active = false` before soft-deleting and logs an activity. The `restore()` method restores the record and sets `is_active = true`. Validation is inline in the controller (no Form Request): `code` unique on `tt_school_days`, `day_of_week` unique and between 1–7, `ordinal` min:1, checkboxes normalized via `$request->boolean()`. On update, unique rules append `,` . $schoolDay->id to ignore the current record.

- Gates: `timetable-foundation.school-day.viewAny`, `.create`, `.view`, `.update`, `.delete`, `.restore`, `.forceDelete` — each gates the corresponding controller method. The `toggleStatus()` method gates with `update`.

- No dedicated policy file — gate checks on the `SchoolDay` model fall through to implicit policy resolution via `Gate::policy()` registration in the service provider.

- Routes: `Route::resource('school-day', SchoolDayController::class)` with trash/restore/forceDelete/toggleStatus additions.

- Activity logging is performed on all state-changing operations (create, update, destroy, restore, forceDelete, toggleStatus) via the `activityLog()` helper.

- The tab grid is loaded from `TimetableFoundationController@timetableMasters`, not from `SchoolDayController@index`. The `SchoolDayController@index` method redirects to the masters page with `tab=school-days`.

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

Global page access to the tab is gated by `timetable-foundation.viewAny` on `TimetableFoundationController@timetableMasters`.

No dedicated policy class — the `SchoolDay` model uses implicit gate resolution.

## Logic Flow

**1. Page Load (School Days Tab).** The user navigates to `timetable-foundation.menu.timetableMasters?tab=school-days`. `TimetableFoundationController@timetableMasters` authorises via `timetable-foundation.viewAny`. The method queries `SchoolDay::query()` with optional `sd_search` and `sd_status` filters, ordered by `ordinal`. The 7 rows are rendered in a table with inline toggles for `is_school_day` and `is_active`, plus action buttons.

**2. Create School Day.** The user clicks "Add New" → `SchoolDayController@create`. `Gate::authorize('timetable-foundation.school-day.create')`. Form rendered: code (text, max:10), name (text, max:20), short_name (text, max:5), day_of_week (number, 1–7), ordinal (number, min:1), is_school_day (checkbox), is_active (checkbox). On submit → `POST /school-day` → `store()`. Validation runs → if fails, redirect back with errors. `$request->boolean()` normalises checkboxes. `SchoolDay::create($validated)`. Activity logged. Redirect to `timetableMasters?tab=school-days` with success flash.

**3. Edit School Day.** The user clicks Edit → `SchoolDayController@edit($id)`. `Gate::authorize('timetable-foundation.school-day.update')`. Form pre-filled. On submit → `PUT /school-day/{id}` → `update()`. Validation same as store, but unique rules ignore current ID. Record updated. Redirect with success flash.

**4. Toggle School Day Flag.** The user clicks the inline toggle for `is_school_day` or the status toggle for `is_active`. `POST /school-day/{schoolDay}/toggle-status` (with `is_active` or `is_school_day` in request body). The controller validates the boolean, updates the model, and returns JSON `{ success: true, is_active: <new_value>, message: "..." }`. The UI updates the badge/toggle without a page reload.

**5. Soft Delete.** The user clicks Trash → `destroy($id)`. `Gate::authorize('timetable-foundation.school-day.delete')`. Sets `is_active = false`, saves, calls `delete()`. Activity logged: "School day was deactivated and moved to trash." Redirect with success flash.

**6. Restore.** Navigate to trash view → click Restore → `restore($id)`. `Gate::authorize('timetable-foundation.school-day.restore')`. Finds trashed record via `onlyTrashed()->findOrFail($id)`. Calls `$schoolDay->restore()`, sets `is_active = true`, saves. Activity logged. Redirect to trash view with success flash.

**7. Force Delete.** Click Force Delete on a trashed record → `forceDelete($id)`. `Gate::authorize('timetable-foundation.school-day.forceDelete')`. Finds record via `withTrashed()->findOrFail($id)`. Calls `$schoolDay->forceDelete()`. Activity logged. Redirect to trash view with success flash.

## Validate Before Save

**School Days — Inline Validation (store & update)**

| Field | Rule(s) | Error Message |
|---|---|---|
| `code` | required, string, max:10, unique:tt_school_days,code | Laravel default |
| `name` | required, string, max:20 | Laravel default |
| `short_name` | required, string, max:5 | Laravel default |
| `day_of_week` | required, integer, between:1,7, unique:tt_school_days,day_of_week | Laravel default |
| `ordinal` | required, integer, min:1 | Laravel default |
| `is_school_day` | nullable | Normalized via `$request->boolean()` |
| `is_active` | nullable | Normalized via `$request->boolean()` |

On update, unique rules append `,` . $schoolDay->id to ignore the current record (e.g., `unique:tt_school_days,code,{$schoolDay->id}`).

## Error Handling and Validation Messages

| Scenario | Message | Type |
|---|---|---|
| Code already exists | `validation.unique` | Validation rule |
| day_of_week out of range (not 1–7) | `validation.between` | Validation rule |
| Ordinal < 1 | `validation.min` | Validation rule |
| Missing required field | `validation.required` | Validation rule |
| Gate authorization failure | 403 Forbidden (`AuthorizationException`) | Gate |
| Toggle status save failure | `flash('status_switch_failed.school_day')` with 422 JSON | Controller check |
| Model not found (show/edit/update/destroy) | 404 (`ModelNotFoundException`) | Controller |
| Guest access | Redirect to `/login` | Authentication |

## Success Scenarios

**SC-001 — View School Days Template.** The administrator navigates to the School Days tab. All seven days (Mon–Sun) are displayed in ordinal order, each showing its code, name, school day status (Yes/No badge), and active status (Active/Inactive badge). Sunday shows "No" for school day. The page loads without errors.

**SC-002 — Toggle School Day Status.** The administrator toggles Saturday's `is_school_day` from Yes to No. An AJAX request flips the flag. The badge changes from "Yes" (green) to "No" (red). The database record is updated. Subsequent working day initialization treats Saturday as closed.

**SC-003 — Edit Day Name and Short Name.** The administrator edits "Wednesday" to change its short name from "Wed" to "Weds". The update succeeds, and the table reflects the change immediately after redirect.

**SC-004 — Soft Delete and Restore.** The administrator soft-deletes "Tuesday". It disappears from the main table and appears in the trash view. The administrator restores it. It reappears in the main table with all original values and `is_active = true`.

**SC-005 — Toggle Active Status.** The administrator toggles the active status of a day to inactive. The row remains visible but the status badge changes to "Inactive". The administrator can reverse this by toggling back to active.

## Failure Scenarios

**FC-001 — Duplicate Code on Create.** The administrator tries to create a school day with code "MON" (which already exists). The unique validation returns: "The code has already been taken." The form is re-displayed with the error.

**FC-002 — day_of_week Out of Range.** The administrator enters `day_of_week = 8`. The `between:1,7` validation returns: "The day of week must be between 1 and 7."

**FC-003 — Unauthorised Access.** A user without the `timetable-foundation.school-day.update` permission tries to edit a school day. `Gate::authorize()` throws `AuthorizationException`, resulting in a 403 HTTP response.

**FC-004 — Non-Existent Record.** The administrator navigates to `/school-day/9999/edit` where the record does not exist. The controller's `findOrFail($id)` throws `ModelNotFoundException`, resulting in a 404 page.

**FC-005 — Toggle Status Failure.** A database save failure during toggle-status results in a JSON response with `{ success: false, is_active: <current_value>, message: flash('status_switch_failed.school_day') }` and HTTP 422.

## Dependencies module and tables

| Dependency | Type | Details |
|---|---|---|
| `tt_school_days` | Primary table | Master data table with 7 pre-seeded rows. All CRUD operations target this table. |
| `tt_configs` | Configuration dependency | Stores `week_start_day` and `default_school_closed_days_per_week` used together with school days for working day initialization. |
| `tt_working_days` | Consumer | Working day initialization reads school days to determine closed weekdays. |
| `activityLog()` helper | Service | Logs all state-changing operations. |
| No FK parent tables | — | `tt_school_days` has no foreign key dependencies — it is a root reference table. |
| No child tables | — | No table has a FK referencing `tt_school_days`. |

**Table:** `tt_school_days`

| Column | Type | Details |
|---|---|---|
| `id` | TINYINT UNSIGNED | Primary key, auto-increment |
| `code` | VARCHAR(10) | NOT NULL, UNIQUE (`uq_schoolday_code`), e.g. 'MON', 'TUE' |
| `name` | VARCHAR(20) | NOT NULL, e.g. 'Monday', 'Tuesday' |
| `short_name` | VARCHAR(5) | NOT NULL, e.g. 'Mon', 'Tue' |
| `day_of_week` | TINYINT UNSIGNED | NOT NULL, UNIQUE (`uq_schoolday_dow`), ISO 8601: 1–7 |
| `ordinal` | TINYINT UNSIGNED | NOT NULL, display order |
| `is_school_day` | TINYINT(1) | NOT NULL, DEFAULT 1 — 1 = school open, 0 = closed |
| `is_active` | TINYINT(1) | NOT NULL, DEFAULT 1 |
| `created_at` | TIMESTAMP | NULLABLE |
| `updated_at` | TIMESTAMP | NULLABLE |
| `deleted_at` | TIMESTAMP | NULLABLE, soft delete |

**Unique Keys:**
- `uq_schoolday_code` — on `code`
- `uq_schoolday_dow` — on `day_of_week`
