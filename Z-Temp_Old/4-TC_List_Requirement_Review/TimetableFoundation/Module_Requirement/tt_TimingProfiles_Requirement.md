# Timing Profiles & Shifts — Business Requirements

## What This Screen Does

The Timing Profiles & Shifts feature defines the operational time-blocks that govern when a school's timetable runs. It covers three entities: Shifts (the high-level operational blocks such as Morning, Afternoon, Evening that partition the school day), Timing Profiles (named templates defining a profile code, total period count, timezone, and notes), and School Timing Profiles (tenant-level bindings that assign a profile name and short name to the school's chosen timing arrangement). Together they provide the temporal structure that period configs, period sets, and timetable types reference.

## When This Screen Is Used

- During initial school setup when shifts (Morning, Afternoon, Evening) are defined for the academic year
- When a school operates multiple batches (e.g., Morning Shift 6–11 AM, Day Shift 11 AM–4 PM) and needs separate timing references for each
- When creating timing profile templates with specific period counts and timezone settings
- When assigning a school-level timing profile name that describes the school's current schedule configuration
- Before defining period configs, since each period config is scoped to a specific shift
- When the shift's default start/end times need to be updated as reference values for downstream entities

## Default Data Load

**Shifts tab** loads via the **Timetable Masters** page at `timetable-foundation.menu.timetableMasters?tab=shifts`. The `SchoolShiftController@index()` redirects to the menu route. The view fetches shifts with `SchoolShift::query()->where('is_active', true)->orWhere(function($q) { $q->where('is_active', false)->whereNotNull('deleted_at'); })->orderBy('ordinal')->paginate(10)`.

**Timing Profiles** load via `TimingProfileController@index()` at `timetable-foundation.timing-profile.index` — paginated list of `tt_timing_profile` records (10 per page) with profile_code, name, total_periods, timezone, notes, and status toggle.

**School Timing Profiles** load via `SchoolTimingProfileController@index()` at `timetable-foundation.school-timing-profile.index` — paginated list of `school_timing_profiles` records (10 per page) with profile_name, short_name, description, and status toggle.

## Key Fields at a Glance

**Shifts (`tt_shifts`)**

| Column | Description |
|--------|-------------|
| `code` | Machine code: MORNING, AFTERNOON, EVENING |
| `name` | Display name: "Morning Shift", "Afternoon Shift" |
| `description` | Optional description of the shift |
| `default_start_time` | Default start time (e.g., 07:30:00) — reference value, actual timings are in period configs |
| `default_end_time` | Default end time (e.g., 14:50:00) — reference value, actual timings are in period configs |
| `ordinal` | Display order (1 = Morning, 2 = Afternoon, etc.), unique |
| `is_active` | Whether this shift is currently active |

**Timing Profiles (`tt_timing_profile`)**

| Column | Description |
|--------|-------------|
| `profile_code` | Machine code (e.g., "MORNING_STD") — unique |
| `name` | Display name (e.g., "Morning Standard") — unique |
| `total_periods` | Total number of periods defined by this profile (min 1) |
| `timezone` | Timezone setting (e.g., "Asia/Kolkata") |
| `notes` | Free-text notes about the profile |

**School Timing Profiles (`school_timing_profiles`)**

| Column | Description |
|--------|-------------|
| `profile_name` | Name of the school timing profile — unique |
| `short_name` | Abbreviation or short label — unique |
| `description` | Free-text description |

## Business Rules and Conditions

**Shift Uniqueness Constraints.** The `tt_shifts` table enforces three separate UNIQUE constraints: `code`, `name`, and `ordinal`. At the application layer, uniqueness checks ignore soft-deleted records via `Rule::unique('tt_shifts', 'column')->whereNull('deleted_at')`, allowing a soft-deleted shift's code/name/ordinal to be reused.

**Shift Ordering and Default Times.** The `ordinal` field determines display order via a scoped `ordered()` query. `default_start_time` and `default_end_time` are nullable TIME fields serving as reference values only — actual period timings are defined in `tt_period_configs`. The `default_end_time` must be after `default_start_time` when both are provided.

**Soft Delete Lifecycle with Status Deactivation.** Active shifts follow a three-state model: Active (`is_active=1`, `deleted_at=NULL`) → toggleStatus → Inactive (`is_active=0`) or destroy → Trashed (`is_active=0`, `deleted_at=TIMESTAMP`) → restore → Active (`is_active=1`). When destroyed, `is_active` is set to `false` before soft-deleting. When restored, `is_active` is set back to `true`.

**Timing Profile Validation and Field Constraints.** `profile_code` and `name` are both required, unique, and max 50 characters. `total_periods` is required with a minimum of 1. `timezone` and `notes` are nullable. Note: The `store()` method does not persist `timezone` or `notes` — only `update()` does, which is a potential bug.

**School Timing Profile Field Constraints.** `profile_name` is required and unique (max 100). `short_name` is nullable and unique (max 20). Note: The uniqueness check includes soft-deleted records, which could cause validation failures when restoring trashed records with duplicate names.

**Activity Logging with Change Tracking.** All update operations on Timing Profiles and School Timing Profiles track changed attributes using `getOriginal()` and `getChanges()`, building a `$changedAttributes` array with `old`/`new` pairs for detailed audit logging.

**Pagination and Listing Behaviour.** All three controllers paginate at 10 records per page. The shift tab includes a special query that shows both active and soft-deleted-but-inactive records (not trashed ones — those are in the trash view). The School Timing Profile trash view paginates both `SchoolTimingProfile::onlyTrashed()` and `Period::onlyTrashed()` in a single view.

**Toggle Status (AJAX) Behaviour.** All three controllers accept POST with `{ "is_active": true/false }`, validate with `'is_active' => 'required|boolean'`, update the record, and return JSON `{ success, is_active, message }`. Failure responses return HTTP 200 with `success: false` rather than a 4xx status.

**Shift FK Protection (Downstream).** `tt_shifts` is referenced by `tt_period_configs`, `tt_period_sets`, and `tt_timetable_types` via ON DELETE RESTRICT FKs. A shift cannot be force-deleted if any downstream records reference it.

## Workflow Steps

**Define Shifts.** The administrator navigates to Timetable Masters → shifts tab and creates operational shifts. Each shift requires a unique code (e.g., "MORNING"), unique name (e.g., "Morning Shift"), optional description, optional default start/end times, and a unique ordinal. The seeded MORNING (ordinal=1) and AFTERNOON (ordinal=2) shifts are typically sufficient for most schools.

**Define Timing Profiles.** The administrator navigates to `timing-profile.*` routes and creates named templates. Each profile has a unique code (e.g., "MORNING_STD"), name, total period count, optional timezone, and notes. The timezone and notes fields are only persisted on update, not on create.

**Define School Timing Profiles.** The administrator navigates to `school-timing-profile.*` routes and creates tenant-level profile bindings. Each school timing profile has a unique name, optional short name, and optional description. This binds a timing arrangement to the school.

**Edit and Update.** For all three entities, the administrator can edit and update records. Timing Profiles and School Timing Profiles track old vs new values for audit logging. Shifts redirect to the shifts tab after update.

**Soft Delete and Restore.** The administrator clicks Trash to deactivate and soft-delete a record. Shifts and School Timing Profiles deactivate before soft-deleting. The trash view lists soft-deleted records for restore or force delete.

## Example Scenario

Mrs. Gupta, the administrator at Gurukul Academy, is setting up the timetable foundation. She verifies that two shifts exist: "MORNING" (Morning Shift, 07:30–14:50, ordinal=1) and "AFTERNOON" (Afternoon Shift, 12:00–18:00, ordinal=2), both seeded by the system.

She creates a Timing Profile "MORNING_STD" with `total_periods=12` and timezone "Asia/Kolkata". She also creates a School Timing Profile "Gurukul_Standard_Profile" with short name "GUR_STD".

Later, the school decides to add an Evening batch. Mrs. Gupta creates a new shift "EVENING" (ordinal=3) with default times 16:00–21:00. She creates a corresponding Timing Profile "EVENING_STD" with `total_periods=8`. An administrator then creates period configs and period sets scoped to the Evening shift.

## Related Screens

- **Period Configuration → Period Configs** — each period config is scoped to a shift via `shift_id` (FK ON DELETE RESTRICT)
- **Period Configuration → Period Sets** — each period set references a shift via `shift_id` (FK ON DELETE RESTRICT)
- **Timetable Types** — each timetable type references a shift via `shift_id` (FK ON DELETE RESTRICT)
- **Period Types** — provides the period type classification that, combined with shifts, defines the full timing grid

## Requirements

- `SchoolShiftController` (227 lines) handles CRUD + AJAX for `tt_shifts`. Key methods: `store()` and `update()` use inline `$request->validate()` with unique rules ignoring soft-deleted records; `destroy()` deactivates before soft-deleting; `restore()` reactivates; `toggleStatus()` returns JSON. No dedicated Form Request.
- `TimingProfileController` (264 lines) handles CRUD for `tt_timing_profile`. Uses `TimingProfileRequest` (dedicated Form Request). Key methods: `store()` persists only `profile_code`, `name`, `total_periods`, `is_active` (NOT `timezone` or `notes`); `update()` tracks old vs new values via `getOriginal()`/`getChanges()`; `destroy()` soft-deletes WITHOUT deactivating first (inconsistency with SchoolShift).
- `SchoolTimingProfileController` (208 lines) handles CRUD for `school_timing_profiles`. Uses `SchoolTimingProfileRequest` (dedicated Form Request). Key methods: `store()` uses `$request->validated()`; `update()` tracks old vs new values; `destroy()` deactivates before soft-deleting; `trashedPeriod()` paginates both `SchoolTimingProfile::onlyTrashed()` and `Period::onlyTrashed()`.
- All three controllers use explicit `Gate::authorize()` calls. Permission strings follow `timetable-foundation.shift.*`, `timetable-foundation.timing-profile.*`, and `timetable-foundation.school-timing-profile.*`.
- All three models use `SoftDeletes`. `SchoolShift` model casts `is_active` to boolean, `ordinal` to integer, and `default_start_time`/`default_end_time` as datetime.
- `SchoolShiftPolicy` is registered in `TimetableFoundationServiceProvider`. `TimingProfilePolicy` and `SchoolTimingProfilePolicy` are NOT registered (technical debt due to naming collision — `TimingProfile` and `SchoolTimingProfile` are aliases of `SchoolShift` in `AppServiceProvider`).
- Routes under `timetable-foundation` prefix: `shift.*` (lines 129–134), `timing-profile.*` (lines 286–290), `school-timing-profile.*` (lines 294–298) in `web.php`.

## Who Can Access

| Gate/Permission | Methods | Notes |
|-----------------|---------|-------|
| `timetable-foundation.shift.viewAny` | `index()` | List (redirect to tab) |
| `timetable-foundation.shift.view` | `show()` | View single |
| `timetable-foundation.shift.create` | `create()`, `store()` | Create |
| `timetable-foundation.shift.update` | `edit()`, `update()`, `toggleStatus()` | Edit and toggle |
| `timetable-foundation.shift.delete` | `destroy()` | Soft delete |
| `timetable-foundation.shift.restore` | `restore()`, `trashedShift()` | Restore and view trash |
| `timetable-foundation.shift.forceDelete` | `forceDelete()` | Permanent delete |
| `timetable-foundation.timing-profile.*` | All TimingProfileController methods | Full CRUD + toggle (policy NOT registered) |
| `timetable-foundation.school-timing-profile.*` | All SchoolTimingProfileController methods | Full CRUD + toggle (policy NOT registered) |
| Policy | `SchoolShiftPolicy` registered; `TimingProfilePolicy` and `SchoolTimingProfilePolicy` NOT registered | Gate falls back to permission-string checks for latter two |

## Logic Flow

**Page Load — Shifts Tab.** User navigates to `timetable-foundation.menu.timetableMasters?tab=shifts`. The `TimetableFoundationController@timetableMasters()` renders the layout. The shifts grid shows active and soft-deleted-but-inactive records (excluding trashed) ordered by ordinal, paginated at 10 per page.

**Page Load — Timing Profiles / School Timing Profiles.** User navigates to the respective resource route. The `index()` method gates with `viewAny`, paginates 10 records per page, and renders the list view.

**Create Shift.** User fills the form: code ("EVENING"), name ("Evening Shift"), ordinal (3), optional default times. The `store()` method validates uniqueness (ignoring soft-deleted records) and creates the record. Activity is NOT logged on create (unlike update which does log).

**Create Timing Profile.** User fills the form with `profile_code`, `name`, `total_periods`, optional `timezone`/`notes`. The `store()` method persists only `profile_code`, `name`, `total_periods`, and `is_active` — timezone and notes are NOT saved (likely a bug — only update() saves them).

**Update (all entities).** User edits the record and submits. The controller validates, updates, logs activity (including change tracking for Timing Profile and School Timing Profile), and redirects.

**Toggle Status.** User clicks the toggle button. AJAX POST to `toggleStatus()` with `{ "is_active": true/false }`. The controller validates, updates the record, and returns JSON `{ success: true, is_active: true, message: "Status updated successfully." }`.

**Delete.** User clicks Trash. For Shifts and School Timing Profiles: `is_active` is set to `false`, then `delete()` is called. For Timing Profiles: `delete()` is called directly without deactivation (inconsistency). Activity is logged.

**Restore / Force Delete.** User views trash, clicks Restore (calls `restore()`, reactivates for Shifts, logs activity) or Force Delete (calls `forceDelete()`, logs activity).

## Validate Before Save

**Shift (store/update — inline validation)**

| Field | Rule(s) | Error Message |
|-------|---------|---------------|
| `code` | required, string, max:20, unique (where deleted_at IS NULL) | "The code has already been taken." |
| `name` | required, string, max:100, unique (where deleted_at IS NULL) | "The name has already been taken." |
| `description` | nullable, string, max:255 | — |
| `default_start_time` | nullable, date_format:H:i | — |
| `default_end_time` | nullable, date_format:H:i, after:default_start_time | "The default end time must be a time after default start time." |
| `ordinal` | required, integer, min:1, unique (where deleted_at IS NULL) | "The ordinal has already been taken." |
| `is_active` | nullable (boolean via `$request->boolean()`) | — |

**Timing Profile (TimingProfileRequest)**

| Field | Rule(s) | Error Message |
|-------|---------|---------------|
| `profile_code` | required, string, max:50, unique (ignoring current id) | — |
| `name` | required, string, max:50, unique (ignoring current id) | — |
| `total_periods` | required, integer, min:1 | — |
| `timezone` | nullable, string, max:64 | — |
| `notes` | nullable, string, max:500 | — |
| `is_active` | nullable, boolean | — |

**School Timing Profile (SchoolTimingProfileRequest)**

| Field | Rule(s) | Error Message |
|-------|---------|---------------|
| `profile_name` | required, string, max:100, unique (includes soft-deleted records) | — |
| `short_name` | nullable, string, max:20, unique (includes soft-deleted records) | — |
| `description` | nullable, string, max:200 | — |
| `is_active` | boolean | — |

## Error Handling and Validation Messages

| Scenario | Message | Type |
|----------|---------|------|
| Shift code/name/ordinal duplicate | "The [field] has already been taken." | Validation rule |
| Shift end time before start time | "The default end time must be a time after default start time." | Validation rule |
| SchoolTimingProfile restore with duplicate short_name | Uniqueness check includes soft-deleted records → validation failure | Validation rule |
| Model not found (any show/edit/update/destroy) | `ModelNotFoundException` → 404 page | 404 |
| Not authorised (any operation) | `AuthorizationException` → 403 | 403 |
| Toggle status save failure | JSON `{ success: false, is_active, message: "Status switch failed." }` | 200 JSON |

## Success Scenarios

**SC-001 — Create New Shift.** Mrs. Gupta creates an "EVENING" shift with ordinal=3, default_start_time="16:00", default_end_time="21:00". The system validates uniqueness, creates the record with `is_active=true`, and redirects to the shifts tab with a success flash. The new shift appears in the grid.

**SC-002 — Toggle Shift Status.** Mrs. Gupta toggles the "AFTERNOON" shift to inactive. AJAX POST to `toggleStatus()` with `is_active=false`. The system updates `is_active` to `false`. JSON response: `{ success: true, is_active: false, message: "Status updated successfully." }`. The grid badge updates from green to red.

**SC-003 — Update Timing Profile with Change Tracking.** Mrs. Gupta updates the "MORNING_STD" timing profile's `total_periods` from 12 to 10. The controller captures `getOriginal()` before the update, performs the update, captures `getChanges()`, builds `$changedAttributes['total_periods'] = ['old' => 12, 'new' => 10]`, logs the activity with the change details, and redirects with a success flash.

**SC-004 — Soft Delete and Restore a Shift.** Mrs. Gupta trashes the "AFTERNOON" shift. The controller sets `is_active=false`, calls `delete()`, logs "'Trashed' with message 'Shift was deactivated and moved to trash.'", and redirects. She later navigates to the trash view, finds the shift, and clicks Restore. The controller calls `restore()`, sets `is_active=true`, logs "'Restored'", and redirects.

## Failure Scenarios

**FC-001 — Duplicate Shift Code.** Mrs. Gupta attempts to create a shift with code "MORNING" when one already exists. The `Rule::unique('tt_shifts', 'code')->whereNull('deleted_at')` validation fails with "The code has already been taken."

**FC-002 — Delete Shift with Existing Period Configs.** Mrs. Gupta attempts to force-delete the "MORNING" shift, but it has period configs referencing it via `ON DELETE RESTRICT` FK. The database constraint prevents deletion, returning a foreign key constraint error.

**FC-003 — Timing Profile Timezone Not Saved on Create.** Mrs. Gupta creates a Timing Profile with `profile_code="WINTER_STD"`, `total_periods=10`, and `timezone="Asia/Kolkata"`. The `store()` method uses `$request->only(['profile_code', 'name', 'total_periods', 'is_active'])` and does NOT include `timezone` or `notes`. The timezone value is silently discarded and not persisted. She must edit the record and save again to persist the timezone.

**FC-004 — Restore Timing Profile Without Reactivation.** A Timing Profile is soft-deleted (without deactivation). When restored via `restore()`, the controller does NOT set `is_active=true`. The restored record remains inactive in the listing, which is inconsistent with the SchoolShift behaviour where restore reactivates.

## Dependencies module and tables

| Dependency | Type | Details |
|------------|------|---------|
| `tt_period_configs` | Child | References `tt_shifts.id` via `shift_id` (ON DELETE RESTRICT) — cannot force-delete a shift with existing period configs |
| `tt_period_sets` | Child | References `tt_shifts.id` via `shift_id` (ON DELETE RESTRICT) — cannot force-delete a shift with existing period sets |
| `tt_timetable_types` | Child | References `tt_shifts.id` via `shift_id` (ON DELETE RESTRICT) — cannot force-delete a shift with existing timetable types |
| `tt_timing_profile` | Independent | No FK relationship to `tt_shifts` — logically related but independently defined |
| `school_timing_profiles` | Independent | No FK relationship to `tt_shifts` — logically related but independently defined |
| `activityLog()` helper | Service | Audit logging on all state-changing operations |

**Table:** `tt_shifts`

| Column | Type | Details |
|--------|------|---------|
| `id` | TINYINT UNSIGNED | PK, Auto Increment |
| `code` | VARCHAR(20) | NOT NULL, UNIQUE |
| `name` | VARCHAR(100) | NOT NULL, UNIQUE |
| `description` | VARCHAR(255) | DEFAULT NULL |
| `default_start_time` | TIME | DEFAULT NULL |
| `default_end_time` | TIME | DEFAULT NULL |
| `ordinal` | TINYINT UNSIGNED | DEFAULT 1, UNIQUE |
| `is_active` | TINYINT(1) | NOT NULL, DEFAULT 1 |
| `created_at` | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |
| `updated_at` | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP ON UPDATE |
| `deleted_at` | TIMESTAMP | NULL |

> **Note:** The DDL for `tt_timing_profile` and `school_timing_profiles` tables was not available in the consolidated DDL file. The `tt_timing_profile` and `school_timing_profiles` tables exist in the codebase (models, controllers, migrations) but their DDL definitions are not included in `Timetable_DDL_v7.8.sql` — this is a suspected gap in the DDL file that needs to be addressed.
