# TimetableFoundation — Academic Terms

## What It Does
Academic terms divide the academic session into smaller scheduling periods (e.g., Term 1, Term 2, Term 3). Each timetable is associated with an academic term, and activities are scoped within a term. Terms define start/end dates that constrain timetable generation.

## Tenant Admin Context
Administrators create academic terms aligned with the school's academic calendar. The terms must fall within the bounds of the parent academic session. Term dates are used by the solver to determine the number of teaching weeks available.

## Database Tables Read / Written

| Table | Fields Used |
|---|---|
| `tt_academic_terms` | `id`, `academic_session_id`, `name`, `short_name`, `start_date`, `end_date`, `is_current`, `is_active` |

## Business Rules
1. **Session scoping**: Terms must belong to an academic session and their dates must fall within the session's start/end range.
2. **Non-overlapping**: Term date ranges should not overlap within the same academic session.
3. **Current term**: Only one term can be marked as `is_current = true` at a time.
4. **Required for timetables**: Every timetable must reference an academic term.
5. **Solver constraint**: The solver uses term dates to calculate the number of available teaching days per activity.

## Process Flow: Academic Term Lifecycle
1. Admin navigates to Academic Terms → Create
2. Selects academic session, enters name, start date, end date
3. Optionally marks as current term
4. System validates date range within session bounds
5. Term is available for timetable creation and activity scoping

## CRUD Operations
- **Create/Read/Update/Delete**: Academic terms
- **Set current**: Mark a term as the active one

## Permissions
- **Admin**: Full CRUD
