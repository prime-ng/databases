# TimetableFoundation — Timing Profiles & Shifts

## What It Does
Manages school timing profiles (bell timings for different seasons or day types) and school shifts (morning, afternoon, evening batches). Enables schools with multiple shifts or seasonal timing variations to maintain separate schedules.

## Tenant Admin Context
Administrators configure timing profiles for different periods of the academic year (e.g., Winter Schedule with shorter periods, Summer Schedule with longer periods). Shifts are used by schools that operate multiple batches (Morning Shift 6–11 AM, Day Shift 11 AM–4 PM).

## Database Tables Read / Written

| Table | Fields Used |
|---|---|
| `tt_school_timing_profiles` | `id`, `name`, `code`, `start_time`, `end_time`, `period_duration`, `is_active` |
| `tt_timing_profiles` | `id`, `academic_session_id`, `name`, `effective_from`, `effective_to`, `period_set_id`, `is_active` |
| `tt_school_shifts` | `id`, `name`, `code`, `start_time`, `end_time`, `is_active` |

## Business Rules
1. **Profiles can be seasonal**: A timing profile has `effective_from` and `effective_to` dates, enabling automatic switching between winter/summer schedules.
2. **Shift scoping**: Classes are assigned to shifts. The shift determines which period set applies.
3. **Period set linking**: Each timing profile links to a period set, which defines the actual timeslots.
4. **Overlap prevention**: Shift timings should not overlap for shared resources.

## Process Flow: Timing Profile Lifecycle
1. Admin creates timing profiles (Winter: Nov–Feb, Summer: Mar–Oct) with linked period sets.
2. Admin configures shifts if the school operates multiple batches.
3. The solver reads the currently active timing profile to determine available slot times.
4. Shift assignments determine which students/teachers are active at which times.

## CRUD Operations
- **Create/Read/Update/Delete**: Timing profiles, school shifts
- **Set active**: Mark the currently active profile

## Permissions
- **Admin**: Full CRUD
