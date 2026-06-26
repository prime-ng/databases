# TimetableFoundation — Teacher Availability

## What It Does
Manages teacher availability for timetable scheduling. Defines per-teacher availability as a percentage/ratio, records specific unavailable slots (day+period), tracks teacher assignment roles (class teacher, subject teacher, etc.), and logs all availability changes for audit.

## Tenant Admin Context
Academic administrators configure teacher availability — which days and periods each teacher is free for teaching. Teachers can be marked as part-time (50% availability), have specific unavailable periods (e.g., Friday afternoons), or be assigned special roles (e.g., Class Teacher, Head of Department). Availability changes are logged for accountability.

## Database Tables Read / Written

| Table | Fields Used |
|---|---|
| `tt_teacher_assignment_roles` | `id`, `teacher_id`, `role_id`, `class_id`, `section_id`, `subject_id`, `is_active` |
| `tt_teacher_availabilities` | `id`, `teacher_id`, `academic_term_id`, `day_of_week`, `period_ord`, `is_available`, `availability_ratio` |
| `tt_teacher_availability_logs` | `id`, `teacher_id`, `changed_by`, `old_availability`, `new_availability`, `change_reason`, `changed_at` |

## Business Rules
1. **Availability ratio**: Teachers can have a global availability percentage (100% = full-time, 50% = part-time) that scales their effective weekly periods in solver calculations.
2. **Per-slot availability**: Teachers can be marked unavailable for specific day+period combinations (e.g., every Friday 6th period = meeting).
3. **Assignment roles**: A teacher can hold multiple roles — Class Teacher for Class 5A, Subject Teacher for English for Classes 5A/5B/5C, HOD for Science department.
4. **Role scoping**: Roles can be class-wide, section-specific, or subject-specific.
5. **Quick edit**: Availability calendar supports rapid toggling of available/unavailable slots with AJAX.
6. **Change audit**: Every availability change is logged with who changed it, what changed, and why.

## Process Flow: Teacher Availability Lifecycle
### Setup
1. Admin navigates to Teacher Availability → selects teacher + academic term.
2. Calendar view shows week grid (Mon–Sat × all periods).
3. Admin toggles available/unavailable slots.
4. System saves availability records and logs changes.

### Batch Generation
1. Admin can generate availability from school-wide defaults (all teachers 100% available).
2. Batch edit for groups of teachers (e.g., all primary teachers have Wednesday half-day).

### Solver Usage
1. The solver loads teacher availability for the academic term.
2. Unavailable slots are enforced as hard constraints (teacher cannot be placed in unavailable slot).
3. Availability ratio influences teacher workload balancing.
4. Assignment roles are used for role-specific constraint matching (e.g., class teacher must have first period with their class).

## CRUD Operations
- **Create/Read/Update/Delete**: Teacher availability records, assignment roles
- **Read/Update**: Availability logs (view-only for non-admins)
- **Batch operations**: Quick edit grid, bulk apply defaults, copy from term to term

## Permissions
- **Admin**: Full CRUD on teacher availability and roles
- **Teacher**: View own availability (read-only)
