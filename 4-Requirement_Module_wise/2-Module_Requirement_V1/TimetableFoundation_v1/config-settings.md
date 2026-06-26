# TimetableFoundation — Configuration & Priority Settings

## What It Does
Provides system-wide configuration settings for timetable operations and priority definitions for activity ranking. Configuration covers solver behaviour, generation defaults, and display options. Priority settings control the relative importance of activities during generation.

## Tenant Admin Context
System administrators set global timetable configuration values (e.g., max periods per day, default period duration, solver timeout). They also define activity priority levels that influence solver behaviour.

## Database Tables Read / Written

| Table | Fields Used |
|---|---|
| `tt_configs` | `id`, `key`, `value`, `group`, `description`, `is_active` |
| `tt_priority_configs` | `id`, `name`, `level`, `color`, `weight`, `is_default`, `is_active` |

## Business Rules
1. **Config key-value**: Settings are stored as key-value pairs with a group classification for organisation.
2. **Priority levels**: Multiple levels (e.g., 1=Critical, 2=High, 3=Normal, 4=Low) with weight values.
3. **Default priority**: One priority can be marked as default — applied to new activities automatically.
4. **Solver weight**: Priority weight influences the solver's ordering of placement attempts.
5. **Recalculation**: Priority config can trigger recalculation of activity priority assignments.

## Process Flow: Configuration Lifecycle
1. Admin updates configuration values via the settings UI.
2. Changes take effect immediately for new generations.
3. Admin defines priority levels with display colours and solver weights.
4. Priority changes can be bulk-applied to existing activities via recalculation.

## CRUD Operations
- **Create/Read/Update/Delete**: Configuration keys and values, priority levels

## Permissions
- **Admin**: Full CRUD
