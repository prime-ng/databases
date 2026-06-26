# Holiday Calendar — Requirements

## What It Does
Manages the school holiday calendar with 4 holiday types: national, state, school, and optional holidays. Holiday dates are used by the leave system to exclude non-working days from leave day count calculations, and by the LOP system to exclude holidays from absentee flagging. Supports applicability filters (teaching/non-teaching/all).

Features:
- 4 holiday types with visual distinction
- Academic year association
- Teaching / Non-Teaching / All applicability
- Optional holiday allocation for employee selection
- Used by leave day-count calculation to exclude holidays
- Soft-delete with full restore/force-delete workflow

## Database Fields

**hrs_holiday_calendars**

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `academic_year_id` | BIGINT UNSIGNED FK → `glb_academic_sessions` | Required. |
| `holiday_date` | DATE | Required. The date of the holiday. |
| `holiday_name` | VARCHAR(150) | Required. Display name: `Republic Day`, `Diwali`, etc. |
| `holiday_type` | ENUM | `national`, `state`, `school`, `optional`. |
| `applicable_to` | ENUM | `all`, `teaching`, `non_teaching`. |
| `is_active` | BOOLEAN | Default true. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard timestamps. |

## Business Rules

**Holiday Type Usage**
- `national`: Fixed national holidays (Republic Day, Independence Day, Gandhi Jayanti). No date restriction.
- `state`: State-specific holidays. Filtered by school's state.
- `school`: Institution-declared holidays (foundation day, annual day, etc.)
- `optional`: Employee can choose up to `policy.optional_holiday_count` optional holidays per year. Employees opt in which optional holidays they want to take.

**Exclusion from Leave Calculation**
- When `LeaveService::calculateDays()` counts days between from_date and to_date, it excludes:
  - Sundays
  - Holidays where `applicable_to` matches employee category
- Only non-optional holidays are auto-excluded (optional holidays require employee opt-in)

**Academic Year Scope**
- Holidays are filtered by `academic_year_id`
- `scopeForYear(academicYearId)` provides query scoping
- Holidays cannot span across academic years (each year has its own set)

**Optional Holiday Selection**
- Employees can select optional holidays they wish to avail
- Maximum selections = `policy.optional_holiday_count`
- Selection is per academic year
- Once selected, those days are treated as holidays for that employee's leave calculation

**Duplicate Date Detection**
- No two active holidays can exist for the same `holiday_date` and `academic_year_id`
- Creating or updating a holiday checks for date conflicts

## CRUD Operations

**List Holidays**
- Calendar view or table view (toggleable)
- Filterable by: academic year, holiday type, month
- Color-coded by holiday type (national=red, state=blue, school=green, optional=orange)

**Create Holiday**
- Bulk add option: paste multiple dates with the same name
- Date picker with month navigation

**Show / Edit Holiday**
- Pre-filled form for editing
- Date change re-checks for duplicates

**Toggle Active Status**
- Toggles `is_active` between 1 and 0

**Soft Delete / Restore / Force Delete**
- Standard delete: soft-deletes the record

## Permissions

| Operation | Permission Key |
|---|---|
| View / Manage holidays | `hrs.holiday.manage` |
| Create / Edit / Delete | `hrs.holiday.manage` |
| Toggle status / Restore / Force delete | `hrs.holiday.manage` |
