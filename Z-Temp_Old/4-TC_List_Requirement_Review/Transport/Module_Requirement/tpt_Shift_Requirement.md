# Shift Master — Business Requirements

## What This Screen Does

The Shift Master screen defines the operating time windows for the transport fleet — Morning, Afternoon, Evening shifts. Each shift has a unique code and name, an effective date range, and determines which routes and stops belong to which time slot. The same physical bus can run different routes in different shifts.

Without this screen, there would be no way to tell the system that "Morning Shift" routes are different from "Afternoon Shift" routes, or that a shift that started on April 1st has now ended on March 31st. The entire route and trip scheduling depends on shifts being defined first.

The screen appears in two contexts:
1. **Transport Master → Shift tab** — Paginated list loaded by `TransportMasterController@index()`.
2. **Standalone CRUD** — Full resource via `ShiftController` with create/edit/show/trash/restore/forceDelete/toggleStatus.

---

## Default Data Load

When the Transport Manager opens Transport Master and clicks the Shift tab, the system loads all the defined shifts from the database — 10 shifts per page — showing each shift's code, name, effective date range, and current status. A search box allows typing a shift code or name to find a specific record.

When the Shift Master is accessed through the dedicated menu item instead of the Transport Master hub, the same list appears with the same layout, but in a full-page view rather than a compact tab.

---

## When This Screen Is Used

- **Setting Up Shifts at the Start of the Academic Year** — Every academic year, the Transport Manager sits down to define the time slots during which the school buses will operate. For most schools, this means three shifts: Morning (bringing students to school), Afternoon (returning students who go home for lunch or have half-day schedules), and Evening (dropping students after extracurricular activities). Each shift is given a start and end date — typically April 1st to March 31st, matching the academic calendar. Without these shifts defined first, none of the routes, stops, or trip schedules can be created.

- **Creating Routes That Belong to a Specific Shift** — When the Transport Manager creates a new route, one of the first choices they must make is which shift this route belongs to. A "Morning Pickup Route" is fundamentally different from an "Afternoon Drop Route" — they operate at different times of day, serve different students, and may use different buses. The shift selection ensures that the route is grouped with the correct time slot and never gets mixed up with routes from other shifts.

- **Scheduling Trips Within the Correct Time Window** — Every day, the system generates trips based on routes, and each route belongs to a shift. This means the Morning shift's trips happen in the morning time window, the Afternoon shift's trips happen after lunch, and the Evening shift's trips happen after school. If a shift has reached its effective end date (for example, a "Summer Vacation Shift" that ends on May 31st), the system should no longer allow new trips for that shift — though the current implementation relies on the manager manually deactivating the shift rather than auto-blocking based on dates.

---

## Key Fields at a Glance

**Shift Identity**
Every shift needs two identifiers — a short machine-friendly code like "MORN" or "AFTN" that is easy to type into dropdown searches, and a full human-readable name like "Morning Shift" that appears on reports and screens. Both must be unique across the system because having two shifts both called "Morning" would break route assignment logic.

**Validity Window**
A shift is not permanent — it has a defined start date and an end date. The Morning Shift might run from April 1st to March 31st of the next academic year, while a Summer Vacation Shift might only run for 60 days. The system enforces that the end date must always be later than the start date, preventing impossible entries like a shift that expires before it begins. The `is_active` toggle allows temporarily disabling a shift without losing its historical route and stop associations.

---

## Business Rules and Conditions

**Shift Identity Uniqueness (BR-TPT-015)**
Both the shift code and the shift name must be unique. Two shifts called "MORN" or two shifts both named "Afternoon Shift" would break the dropdown selections in routes and stops. The database enforces this with two separate unique constraints (`uq_shift_code` and `uq_shift_name`), and the `ShiftRequest` validation catches duplicates before reaching the database.

**Date Range Integrity**
A shift's effective end date must always come after its start date. This prevents a shift that "ends" on January 1st but "starts" on February 1st — an impossible timeline. The form request enforces `after:effective_from` on the `effective_to` field.

**Model-DDL Column Mismatch (GAP — CRITICAL)**
The Eloquent model's `$fillable` array includes four fields that do not exist in the database table: `description`, `default_start_time`, `default_end_time`, and `ordinal`. The actual `tpt_shift` DDL only contains: `id, code, name, effective_from, effective_to, is_active, created_at, updated_at, deleted_at`. This means if any code path (a future feature, an import script, or a direct model call) tries to save values into these four phantom fields, it will trigger an SQL "column not found" error. This is a silent time bomb in the codebase.

**Soft Delete Behaviour**
When a shift is deleted, the system sets `is_active = false` and then soft-deletes the record. Restoring the shift clears the `deleted_at` timestamp but does not restore `is_active` — the shift comes back from the dead but remains inactive until the manager manually toggles it back on.

---

## Workflow Steps

**Defining a New Shift**
The Transport Manager opens Transport Master → Shift tab, clicks Add Shift. They enter the shift code (e.g., "AFTN"), name (e.g., "Afternoon Shift"), effective from and to dates, and click Save. The system validates uniqueness, creates the record, and logs the activity. The shift now appears in route and stop dropdowns.

**Deactivating a Shift**
The manager clicks the status toggle to deactivate a shift that is no longer in use. The system flips `is_active` and logs the toggle.

---

## Example Scenario

Green Valley School runs on a two-shift academic schedule. The main school session runs from 8:00 AM to 2:00 PM, but the school also offers an extended day program with extracurricular activities until 5:00 PM. The Transport Manager, Mrs. Desai, needs to set up shifts to match this schedule.

She opens the Shift tab and creates the first shift: code "MORN", name "Morning Shift — Pickup", effective from April 1st to March 31st of the next year. This shift covers the morning pickup operation where buses collect students from their stops and bring them to school between 7:00 AM and 8:00 AM.

Next, she creates the second shift: code "AFTN", name "Afternoon Shift — Drop", with the same effective date range. This shift covers the afternoon drop operation where buses take students back home between 2:00 PM and 3:00 PM.

Finally, she creates a third shift: code "EVNG", name "Evening Shift — Extended Day Drop", effective from April 1st to March 31st as well. This shift is for students who stay back for sports and clubs — their buses run from 5:00 PM to 6:00 PM.

All three shifts are saved successfully. Now when Mrs. Desai moves to the Route Master to create pickup routes, the shift dropdown shows three options: Morning Shift, Afternoon Shift, and Evening Shift. She creates the "MG Road Morning Pickup" route under the Morning shift, the "MG Road Afternoon Drop" route under the Afternoon shift, and the "MG Road Evening Drop" route under the Evening shift. Each route knows exactly which time slot it belongs to.

Later in the year, if the school discontinues the extended day program, Mrs. Desai can simply deactivate the Evening shift. All its routes and stop assignments remain in the system for historical reference, but they no longer appear in active trip generation.

---

## Related Screens

- **Route Master** — Routes are assigned to a shift.
- **Trans. Stops** — Stops are assigned to a shift.
- **Assign Stops to Route** — Junction uses shift_id.
- **Driver-Route-Vehicle Assignment** — Assignments reference shifts.

---

## Requirements

- Controller: `ShiftController` with resource methods: `index`, `create`, `store`, `show`, `edit`, `update`, `destroy`, plus `trashed`, `restore`, `forceDelete`, `toggleStatus`
- Hub tab data: Loaded via `TransportMasterController@index()`
- Route: `Route::resource('shift', ShiftController::class)` + trash/restore/forceDelete/toggleStatus routes
- Permission gates: `tenant.shift.viewAny`, `tenant.shift.view`, `tenant.shift.create`, `tenant.shift.update`, `tenant.shift.delete`, `tenant.shift.restore`, `tenant.shift.forceDelete`
- Form request: `ShiftRequest` — validates code (unique), name (unique), effective_from (required date), effective_to (required date, after:effective_from), is_active (required boolean)
- Activity logging: ✅ Present on `store` (Stored), `update` (Updated with field-level changes), `destroy` (Trashed), `restore` (Restored), `forceDelete` (Deleted), `toggleStatus` (Toggled)

---

## Who Can Access

- **Transport Manager** — Has full control over shift definitions. They can create new shifts, edit existing ones (including changing effective dates), activate or deactivate shifts using the toggle switch, soft-delete obsolete shifts, restore accidentally deleted records, and permanently remove test entries. This is the primary user who manages shift scheduling.

- **Fleet Supervisor** — Can view all shift details and read-only access to the shift list. They need to know which shifts exist so they can plan maintenance schedules, but they do not create or modify shift definitions.

- **School Administrator** — Has read-only access to see the shift structure and effective dates for reporting purposes, but cannot make any changes.

- **Driver** — Does not have access to this screen. Drivers see their assigned shift only through the trip schedule displayed in their mobile app.

Behind the scenes, each action is protected by a permission check. If a user tries to perform an action they are not authorised for, the system displays an "Access Denied" message.

---

## Logic Flow

When the Transport Manager clicks the Shift tab in Transport Master, the system loads the list of all defined shifts — 10 at a time — in order of most recently created. Each row in the list shows the shift code, name, effective from and to dates, and a toggle switch showing whether the shift is active or inactive.

When the manager clicks "Add Shift," a simple form appears asking for four pieces of information: a short code (like "MORN" or "AFTN"), a full name (like "Morning Shift"), a start date, and an end date. There are no dropdowns or complex fields — shift creation is deliberately straightforward.

When the manager submits the form, the system checks that the shift code is not already used by another shift, that the shift name is also unique, and that the end date comes after the start date. If any of these checks fail, the form highlights the problem and refuses to save. If everything is correct, the shift is created with its active status set to Yes, the action is recorded in the activity log, and the manager returns to the shift list where the new shift now appears.

When the manager clicks Edit on an existing shift, the form loads with the current values pre-filled. The manager can change any of the four fields. On save, the system compares the old and new values — if any field changed (for example, the end date was extended by one month), the system logs exactly which field changed and what the old and new values were. If nothing changed, it logs "No changes were made."

When the manager clicks Delete, the system does not erase the shift. Instead, it marks the shift as inactive and hides it from the main list. The record continues to exist in the Trash folder. To see trashed shifts, the manager switches to the Trash view where they can either Restore a shift (which brings it back but keeps it inactive until toggled on) or permanently delete it (which removes it from the database entirely).

When the manager clicks the status toggle switch next to a shift in the list, a quick update fires in the background — the shift's active status flips from Yes to No (or No to Yes), the activity log records the change, and the toggle moves to its new position without reloading the page.

---

## Validate Before Save

| Field | What the System Checks | Error Message If Wrong |
|-------|----------------------|------------------------|
| Shift Code | Must be provided, maximum 20 characters, must not match any existing shift code | "The code has already been taken." |
| Shift Name | Must be provided, maximum 100 characters, must not match any existing shift name | "The name has already been taken." |
| Effective From Date | Must be a valid date | "Please enter a valid start date." |
| Effective To Date | Must be a valid date that comes after the start date | "The end date must be a date after the start date." |
| Active Status | Must be Yes or No | "The active status must be yes or no." |

---

## Error Handling — What Can Go Wrong

| Problem | What the User Sees | What Type of Issue |
|---------|-------------------|-------------------|
| Shift code already used | "The code has already been taken." — the form does not submit until a unique code is entered | Data entry error — prevented before saving |
| Shift name already used | "The name has already been taken." — the form does not submit | Data entry error — prevented before saving |
| End date set before start date | "The end date must be a date after the start date." — the form blocks submission | Data entry error — prevented before saving |
| User tries to access Shift screen without permission | The system shows a blank "Access Denied" page | Permission error — system blocks the action |
| Saving a shift with extra information like description or start/end times | The system crashes with a database error because the shift table does not have columns for description, default start time, or default end time — even though the software code expects these fields to exist | 🔴 Gap — software expects fields that the database does not have |

---

## Success Scenarios — When Everything Works

**SC-001 — Setting Up Shifts for the New Academic Year**
At the start of the academic year, the Transport Manager creates three shifts: Morning (code MORN, valid Apr 1 to Mar 31), Afternoon (code AFTN, same dates), and Evening (code EVNG, same dates). Each shift is saved successfully. The activity log records three "Stored" entries — one for each shift. The shifts now appear in every dropdown across the Transport module: route creation, stop creation, stop assignment, and trip generation.

**SC-002 — Extending a Shift's Effective Period**
The school decides to extend the Afternoon shift by two weeks because the exam schedule requires later dismissal. The Transport Manager opens the Afternoon shift record, changes the end date from March 31st to April 14th, and saves. The system logs the exact change: "Effective to changed from 2026-03-31 to 2026-04-14." The shift remains active and continues to be used for trip generation during the extended period.

**SC-003 — Deactivating a Discontinued Shift**
The school discontinues the Evening shift because the extended day program was cancelled. The Transport Manager toggles the Evening shift's status to Inactive. The toggle changes immediately, the activity log records "Toggled (0)", and the Evening shift disappears from all active dropdowns — but its routes and stop assignments remain in the database for historical records.

---

## Failure Scenarios — What Could Go Wrong

**FC-001 — Shift Soft-Delete Causes All Downstream Data to Vanish**
When the Transport Manager deletes a shift, it becomes inactive and hidden. All routes, stops, and assignments that belonged to that shift are still in the database, but they are now orphaned — they reference a shift that is no longer visible in dropdowns. If the manager later restores the shift, all these relationships come back into view. However, there is no warning when deleting a shift that has active routes and stops linked to it.

**FC-002 — Software Expects Fields That Don't Exist in the Database**
The shift software code has been written with four extra fields that the database simply does not have: a description field, a default start time, a default end time, and an ordinal (sequence number). If any future feature or data import script tries to save information into these fields, the database will throw an error and the save will fail completely. A manager editing a shift that was created by a routine update script could see an unexpected crash instead of a successful save. This is a time bomb in the system that needs to be fixed by either adding the missing columns to the database or removing the phantom fields from the software code.

---

## Dependencies

| Dependency | Type | Details |
|-----------|------|---------|
| `tpt_route` | Child Table | Routes reference shift_id (CASCADE) |
| `tpt_pickup_points` | Child Table | Stops reference shift_id (CASCADE) |
| `tpt_pickup_points_route_jnt` | Child Table | Junction references shift_id (CASCADE) |
| `tpt_driver_route_vehicle_jnt` | Child Table | Assignments reference shift_id |

**Table:** `tpt_shift`

| Column | Type | Details |
|--------|------|---------|
| id | INT UNSIGNED PK | Auto-increment |
| code | VARCHAR(20) NOT NULL UNIQUE | Shift code |
| name | VARCHAR(100) NOT NULL UNIQUE | Shift name |
| effective_from | DATE NOT NULL | Valid from |
| effective_to | DATE NOT NULL | Valid until |
| is_active | TINYINT(1) DEFAULT 1 | Activity flag |
| created_at | TIMESTAMP NULL | — |
| updated_at | TIMESTAMP NULL | — |
| deleted_at | TIMESTAMP NULL | Soft deletes |
