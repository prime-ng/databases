# Holiday Calendar — Business Requirements

## What This Screen Does

The Holiday Calendar screen allows the school to define and manage holidays for each academic year. It captures the date, name, type (national, state, school, optional), and staff applicability of each holiday. The calendar serves as a reference for leave application processing — when computing leave days, the system excludes holidays falling within the leave period.

---

## When This Screen Is Used

- Annual Calendar Planning when the school administration publishes the holiday list for the upcoming academic year
- Leave Application Processing when the system automatically excludes holidays from leave day counts
- Optional Holiday Election when employees choose optional holidays from the configured pool
- Holiday Type Categorization to distinguish between mandatory national holidays, state-specific holidays, school-declared events, and optional holidays employees can elect

## Default Data Load

The screen is loaded via `HrMenuController@hrMasters()` at route `GET /hr-masters` with tab parameter `tab=holidays`. The controller loads holidays from `HolidayCalendar::with('academicYear')->orderBy('holiday_date', 'desc')`, filtered by search and type when the active tab is `holidays`. Academic years are loaded from `OrganizationAcademicSession::orderBy('start_date', 'desc')` for the filter dropdown.

Separately, `HolidayController@index()` at `GET /holidays` provides a paginated view with 30 records per page, scoped to the current academic session via `OrganizationAcademicSession::where('is_current', true)`, searchable by `holiday_name`, and filterable by `holiday_type`.

---

## Key Fields at a Glance

**Date and Name**
The Holiday Date is the specific calendar date of the holiday. The Holiday Name is a descriptive label such as "Independence Day" or "Diwali".

**Categorization**
The Holiday Type classifies the holiday as National (fixed by the national government), State (state-specific), School (declared by the school administration), or Optional (employees can choose to avail). The Applicable To setting controls which staff category the holiday applies to.

**Academic Year Context**
Each holiday is linked to an academic year via the academic year selector. When viewing, the system defaults to the current academic session.

---

## Business Rules and Conditions

**Current Session Default**
When loading the standalone index page, the system automatically filters holidays to the current academic session identified by `is_current = true`.

**Leave Day Computation Exclusion**
The holiday calendar is consumed by the leave application system. When computing the `days_count` for a leave application, holidays falling within the from-to date range are excluded from the count. This ensures employees do not consume leave days for scheduled holidays.

**Optional Holiday Limit**
Optional holidays are subject to the leave policy's `optional_holiday_count` limit, which caps how many optional holidays an employee can elect in a year.

---

## Workflow Steps

**Adding a Holiday**
The HR Manager navigates to HR Masters → Holiday Calendar, clicks Add, selects the academic year, picks a date, enters a name (e.g., "Republic Day"), selects type "National", sets applicable to "All", and saves. The system creates the holiday record and logs the activity.

**Editing a Holiday**
The HR Manager clicks Edit on an existing holiday, changes its name or type, and saves. The system updates the record.

---

## Example Scenario

At the start of the academic year 2025-26, the HR Manager inputs all school holidays: Republic Day (Jan 26 — National), Diwali (Oct 31 — State), School Foundation Day (Sep 15 — School), and two optional holidays. Later, when a teacher applies for leave from Oct 28 to Nov 2, the system sees Oct 31 is a holiday and counts only 4 leave days instead of 5.

---

## Related Screens

- **Leave Applications** — Holiday calendar data is consumed for leave day computation
- **Leave Policy** — Configures the optional holiday count limit
- **Leave Balances** — Holiday exclusions affect balance consumption

---

## Requirements

- Controller `HolidayController`: `index()` loads paginated grid scoped to current session; `store()` creates with validated + `created_by`/`updated_by`; `show()` displays single; `edit()` loads edit form with academic years; `update()` updates with validated + `updated_by`; `toggleStatus()` flips `is_active` via JSON; `destroy()` sets `is_active=false` before soft-delete; `trashed()` lists soft-deleted; `restore()` restores and sets `is_active=true`; `forceDelete()` permanently deletes
- Gate: `Gate::authorize('hrs.leave_type.manage')` on all methods (shared permission with Leave Types)
- Route resource: `holidays` with `except(['create'])`, plus custom `toggle-status`, `trashed`, `restore`, `force-delete`
- Validation `StoreHolidayRequest`: `academic_year_id` required, exists:sch_org_academic_sessions_jnt,id; `holiday_date` required, date; `holiday_name` required, max:150; `holiday_type` required, in:national,state,school,optional; `applicable_to` required, in:all,teaching,non_teaching; `is_active` required, boolean
- `prepareForValidation()`: casts `is_active` to boolean (default true)
- Model `HolidayCalendar`: SoftDeletes, table `hrs_holiday_calendars`, `$fillable` = 8 fields, `$casts` = `holiday_date` as date, `is_active` as boolean; relationships: `academicYear()` BelongsTo; scopes: `active()`, `forYear()`
- Activity logged via `activityLog()` on all state-changing operations
- Policy: `HolidayCalendarPolicy` using single permission `hrs.holiday.manage` for all gates

## Who Can Access

| Gate/Permission | Methods | Notes |
|----------------|---------|-------|
| `hrs.leave_type.manage` | All HolidayController methods | Shared with Leave Types (code uses this permission, policy defines `hrs.holiday.manage`) |
| `hrs.holiday.manage` | `index()`, `store()`, `show()`, `edit()`, `update()`, `toggleStatus()`, `destroy()`, `trashed()`, `restore()`, `forceDelete()` | Policy-level permission |
| Policy: `HolidayCalendarPolicy` | All gates | Uses `hrs.holiday.manage` |

> **Note:** The controller uses `Gate::authorize('hrs.leave_type.manage')` but the policy defines `hrs.holiday.manage`. Both permission strings may work depending on Spatie role configuration.

## Logic Flow

1. **Page Load** — `HrMenuController@hrMasters()` loads tabbed view; `HolidayController@index()` scopes to current academic session. Gate enforced. Search by name, filter by type.
2. **Create** — `store()` receives validated `StoreHolidayRequest` data. `created_by` and `updated_by` set. Redirect to tab with success flash.
3. **Edit/Update** — `edit()` loads model + academic years for dropdown. `update()` merges `updated_by`.
4. **Status Toggle** — `toggleStatus()` flips `is_active`, returns JSON response.
5. **Delete** — `destroy()` sets `is_active=false`, soft-deletes. No dependency guards (holidays can be deleted freely).
6. **Trash/Restore/ForceDelete** — Standard soft-delete lifecycle.

## Validate Before Save

| Field | Rule(s) | Error Message |
|-------|---------|---------------|
| `academic_year_id` | required, exists:sch_org_academic_sessions_jnt,id | — |
| `holiday_date` | required, date | — |
| `holiday_name` | required, string, max:150 | — |
| `holiday_type` | required, in:national,state,school,optional | — |
| `applicable_to` | required, in:all,teaching,non_teaching | — |
| `is_active` | required, boolean | — |

## Error Handling and Validation Messages

| Scenario | Message | Type |
|----------|---------|------|
| Invalid academic year | "The selected academic year id is invalid." | Validation (exists) |
| Invalid holiday type | "The selected holiday type is invalid." | Validation (in) |
| Missing required fields | "The [field] field is required." | Validation |

## Success Scenarios

**SC-001 — Creating a National Holiday**
HR Manager creates "Republic Day" on 2026-01-26, type National, applicable to All. System creates record, logs Created activity, redirects with "Holiday added successfully."

**SC-002 — Updating Holiday Type**
HR Manager edits a holiday from type School to type Optional. System updates and logs Updated activity.

**SC-003 — Soft-Deleting a Holiday**
HR Manager removes a holiday. System soft-deletes, no dependency block.

## Failure Scenarios

**FC-001 — Invalid Academic Year Reference**
User selects a non-existent academic year. Validation error: "The selected academic year id is invalid."

## Dependencies module and tables

| Dependency | Type | Details |
|-----------|------|---------|
| `sch_org_academic_sessions_jnt` | FK Table | `academic_year_id` → `id` ON DELETE RESTRICT |
| `hrs_leave_applications` | Consumer | Holiday dates referenced for leave day count computation |
| Activity Log | Consumer | `activityLog()` on CRUD |

**Table:** `hrs_holiday_calendars`

| Column | Type | Details |
|--------|------|---------|
| id | BIGINT UNSIGNED PK | Auto-increment |
| academic_year_id | SMALLINT UNSIGNED FK | NOT NULL, FK → `sch_org_academic_sessions_jnt.id` |
| holiday_date | DATE | NOT NULL |
| holiday_name | VARCHAR(150) | NOT NULL |
| holiday_type | ENUM('national','state','school','optional') | NOT NULL |
| applicable_to | ENUM('all','teaching','non_teaching') | NOT NULL DEFAULT 'all' |
| is_active | TINYINT(1) | NOT NULL DEFAULT 1 |
| created_by | BIGINT UNSIGNED | NOT NULL |
| updated_by | BIGINT UNSIGNED | NOT NULL |
| created_at | TIMESTAMP | NULL |
| updated_at | TIMESTAMP | NULL |
| deleted_at | TIMESTAMP | NULL (soft delete) |
