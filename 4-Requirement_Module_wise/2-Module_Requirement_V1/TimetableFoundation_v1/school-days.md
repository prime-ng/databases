# TimetableFoundation — School Days & Working Days

## What It Does
Defines which days of the week are school days (e.g., Monday–Saturday), classifies each calendar day into day types (regular working day, holiday, festival, exam day, etc.), manages the academic year calendar of working days, and supports class-specific working day overrides.

## Tenant Admin Context
Administrators set the school's weekly schedule (which days are active), mark holidays and special days on the calendar, and override working days for specific classes (e.g., Class 10 has extra classes on Saturday).

## Database Tables Read / Written

| Table | Fields Used |
|---|---|
| `tt_school_days` | `id`, `name`, `short_name`, `ordinal`, `is_school_day`, `is_active` |
| `tt_day_types` | `id`, `name`, `code`, `color`, `is_working_day`, `reduced_periods`, `is_active` |
| `tt_working_days` | `id`, `academic_session_id`, `date`, `day_type_id`, `day_type_id_2`, `day_type_id_3`, `day_type_id_4`, `is_school_day`, `is_active` |
| `tt_class_working_days` | `id`, `class_id`, `working_day_id`, `is_working`, `period_count`, `is_active` |

## Business Rules
1. **School days**: Define the weekly template — typically Mon–Sat with Sunday excluded. Each school day has an ordinal (1=Monday, 7=Sunday).
2. **Day types**: Classify calendar days — Regular, Holiday, Festival, Exam, Sports Day, etc. Multiple day types can apply to a single date (e.g., Festival + Holiday).
3. **Working days calendar**: Each date in the academic session is either a school day or a non-school day. Up to 4 day types can be assigned per date.
4. **Class overrides**: Specific classes can override the school-wide working day — e.g., Class 12 has a working day when the rest of the school has a holiday.
5. **Holiday detection**: A date is a holiday if `is_school_day = false` OR any assigned day type has `is_working_day = false`.
6. **Half-day detection**: A date is a half-day if it's a school day AND any assigned day type has `reduced_periods = true`.
7. **Solver input**: The solver reads working days to determine available teaching slots per class-section.

## Process Flow: School Days Lifecycle
### Weekly Setup
1. Admin defines school days — which days of the week are active and their order.
2. Admin configures day types with colour coding and working-day flags.

### Calendar Generation
1. Admin initialises the working day calendar for an academic session.
2. System auto-generates all dates within the session range as school days by default.
3. Admin bulk-marks holidays, exam days, etc., or imports from a calendar.
4. Admin can set class-specific overrides.

### Solver Usage
1. The solver queries working days for the academic term.
2. Only dates where `is_school_day = true` and no excluded day type applies are used for scheduling.
3. Class-specific overrides modify available days per class.

## CRUD Operations
- **Create/Read/Update/Delete**: School days, day types, working days, class working days
- **Bulk operations**: Mark multiple dates as holidays, copy from previous session, inherit from school calendar

## Permissions
- **Admin**: Full CRUD on days and working calendar
