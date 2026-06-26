# TimetableFoundation — Timetable Types & Class Assignments

## What It Does
Defines timetable type classifications (Regular, Exam, Remedial, Sports, etc.) and assigns timetable types to class-sections. Each timetable type can have its own period set, generation strategy, and scheduling rules.

## Tenant Admin Context
Administrators create timetable types for different scheduling contexts. For example, a "Regular Academic" timetable uses standard periods, while an "Exam Timetable" uses exam slots. Class-timetable-type assignments determine which timetable type applies to which class-section.

## Database Tables Read / Written

| Table | Fields Used |
|---|---|
| `tt_timetable_types` | `id`, `name`, `code`, `description`, `color`, `is_primary`, `is_active` |
| `tt_class_timetable_types` | `id`, `class_id`, `timetable_type_id`, `period_set_id`, `is_active` |

## Business Rules
1. **Primary type**: One timetable type can be marked as primary — used as the default for all classes unless overridden.
2. **Class assignment**: Each class can have multiple timetable types (e.g., Regular + Exam), but only one per scheduling context.
3. **Period set linking**: Each class-timetable-type assignment can specify a custom period set. If null, the timetable type's default period set is used.
4. **Solver scoping**: The solver generates one timetable per class-timetable-type assignment.

## Process Flow: Timetable Types Lifecycle
1. Admin creates timetable types (Regular Academic, Exam, Remedial, Sports).
2. Admin assigns timetable types to class-sections, optionally with custom period sets.
3. The assigned timetable types appear as generation options when creating a new timetable.
4. The solver reads the timetable type to determine applicable period set, constraints, and rules.

## CRUD Operations
- **Create/Read/Update/Delete**: Timetable types, class-timetable-type assignments

## Permissions
- **Admin**: Full CRUD
