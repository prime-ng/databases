# TimetableFoundation — Period Configuration

## What It Does
Period configuration defines the timeslot grid that all timetables use. It encompasses period types (lecture, lab, break, assembly), period config (master timeslot definitions with start/end times), period sets (groupings of periods that form a timetable's daily structure), and period-set-period mappings.

## Tenant Admin Context
School administrators define the school's daily schedule structure — how many periods per day, their start/end times, which periods are breaks vs instructional, and how periods are grouped for different timetable types.

## Database Tables Read / Written

| Table | Fields Used |
|---|---|
| `tt_period_types` | `id`, `name`, `code`, `color`, `is_instructional`, `is_break`, `is_active` |
| `tt_period_configs` | `id`, `name`, `start_time`, `end_time`, `duration_minutes`, `period_type_id`, `ordinal`, `is_active` |
| `tt_period_sets` | `id`, `name`, `timetable_type_id`, `total_periods`, `is_default`, `is_active` |
| `tt_period_set_periods` | `id`, `period_set_id`, `period_config_id`, `ordinal`, `is_active` |

## Business Rules
1. **Period types**: Classify each period as instructional (lecture/lab/tutorial) or non-instructional (break/assembly/movement).
2. **Period config**: Defines the actual times (08:00–08:45, etc.) and duration. Each period config is reusable across multiple period sets.
3. **Period sets**: Group periods into a complete daily schedule. A school may have different sets for different timetable types (e.g., Normal Day, Exam Day, Short Day).
4. **Ordinal**: Both period configs and period-set-periods use ordinal for ordering within their scope.
5. **Default set**: One period set per timetable type can be marked as default, used when no specific set is assigned.
6. **Sync range**: Period sets can be synced across academic terms or timetable types — adding/removing periods in one can propagate.

## Process Flow: Period Configuration Lifecycle
### Period Types
1. Admin defines period classifications: Lecture, Lab, Break, Assembly, Movement, etc.
2. Each type specifies whether it counts as instructional time and its display color.

### Period Config
1. Admin creates master period slots with name, start time, end time, and duration.
2. Periods are ordered by ordinal (1st period, 2nd period, etc.).
3. Periods are reusable — same master period can appear in multiple period sets.

### Period Sets
1. Admin creates a period set (e.g., "Regular Weekday Set") linked to a timetable type.
2. Admin adds period configs to the set in order, specifying which periods constitute the daily schedule.
3. The set's total_periods is auto-calculated from member count.
4. The set is used by the solver as the daily slot structure.

## CRUD Operations
- **Create/Read/Update/Delete**: Period types, period configs, period sets, period-set-period mappings
- **Reorder**: Period ordinal updates within sets

## Permissions
- **Admin**: Full CRUD on all period entities
