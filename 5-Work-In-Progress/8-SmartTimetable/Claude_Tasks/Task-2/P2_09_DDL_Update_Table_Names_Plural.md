# PROMPT: Update DDL Table Names to Plural — Schema Reconciliation — SmartTimetable DDL Gap Fix
**Task ID:** P2_09
**Issue IDs:** DDL-vs-code table name drift
**Priority:** P2-Medium
**Estimated Effort:** 1-2 hours
**Prerequisites:** All P0 and P1 tasks completed

---

## CONFIGURATION
```
LARAVEL_REPO   = /Users/bkwork/Herd/prime_ai_tarun
MODULE_PATH    = {LARAVEL_REPO}/Modules/SmartTimetable
DDL_FILE       = /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/0-DDL_Masters/tenant_db_v2.sql
BRANCH         = Brijesh_SmartTimetable
```

---

## CONTEXT

28 tables in `tenant_db_v2.sql` use singular names (e.g., `tt_activity`, `tt_constraint`) while the Laravel migrations and models use plural names (e.g., `tt_activities`, `tt_constraints`). The DDL is a design document; migrations are the source of truth. The DDL must be updated to match the actual database table names used by the running application.

This is a DDL-only change — no code files are modified. All `CREATE TABLE` statements, `FOREIGN KEY` references, `INDEX` names, and `CONSTRAINT` names must use the new plural table names.

---

## PRE-READ (Mandatory)

1. `{DDL_FILE}` — full file, identify all `tt_*` CREATE TABLE statements
2. A sample of model files in `{MODULE_PATH}/app/Models/` — confirm `$table` uses plural names

---

## STEPS

1. Open `{DDL_FILE}` for editing
2. Rename the following 32 tables from singular to plural (including updating the `CREATE TABLE`, `DROP TABLE IF EXISTS`, and all `REFERENCES` clauses):

| # | Current DDL Name (Singular) | New DDL Name (Plural) |
|---|---|---|
| 1 | `tt_shift` | `tt_shifts` |
| 2 | `tt_day_type` | `tt_day_types` |
| 3 | `tt_period_type` | `tt_period_types` |
| 4 | `tt_teacher_assignment_role` | `tt_teacher_assignment_roles` |
| 5 | `tt_period_set` | `tt_period_sets` |
| 6 | `tt_timetable_type` | `tt_timetable_types` |
| 7 | `tt_slot_requirement` | `tt_slot_requirements` |
| 8 | `tt_requirement_consolidation` | `tt_requirement_consolidations` |
| 9 | `tt_constraint_type` | `tt_constraint_types` |
| 10 | `tt_constraint` | `tt_constraints` |
| 11 | `tt_teacher_unavailable` | `tt_teacher_unavailables` |
| 12 | `tt_room_unavailable` | `tt_room_unavailables` |
| 13 | `tt_teacher_availability` | `tt_teacher_availabilities` |
| 14 | `tt_teacher_availability_detail` | `tt_teacher_availability_logs` |
| 15 | `tt_room_availability` | `tt_room_availabilities` |
| 16 | `tt_room_availability_detail` | `tt_room_availability_details` |
| 17 | `tt_priority_config` | `tt_priority_configs` |
| 18 | `tt_activity` | `tt_activities` |
| 19 | `tt_sub_activity` | `tt_sub_activities` |
| 20 | `tt_activity_priority` | `tt_activity_priorities` |
| 21 | `tt_activity_teacher` | `tt_activity_teachers` |
| 22 | `tt_timetable` | `tt_timetables` |
| 23 | `tt_conflict_detection` | `tt_conflict_detections` |
| 24 | `tt_resource_booking` | `tt_resource_bookings` |
| 25 | `tt_generation_run` | `tt_generation_runs` |
| 26 | `tt_constraint_violation` | `tt_constraint_violations` |
| 27 | `tt_timetable_cell` | `tt_timetable_cells` |
| 28 | `tt_timetable_cell_teacher` | `tt_timetable_cell_teachers` |
| 29 | `tt_teacher_workload` | `tt_teacher_workloads` |
| 30 | `tt_change_log` | `tt_change_logs` |
| 31 | `tt_teacher_absence` | `tt_teacher_absences` |
| 32 | `tt_substitution_log` | `tt_substitution_logs` |

3. For each renamed table, also update:
   - All `FOREIGN KEY ... REFERENCES tt_old_name(...)` clauses throughout the file to use the new plural name
   - All `INDEX` and `CONSTRAINT` names that embed the old table name (e.g., `idx_tt_activity_class` becomes `idx_tt_activities_class`)
   - Any `DROP TABLE IF EXISTS` statements at the top of the file
4. Keep junction tables with `_jnt` suffix as-is (e.g., `tt_class_working_day_jnt` stays unchanged)
5. Keep config/singleton tables as-is if they are already correct
6. After all renames, do a final search for any remaining singular references that were missed

---

## ACCEPTANCE CRITERIA

- All 32 `tt_*` tables listed above use plural names in the DDL matching their migration/model counterparts
- All `FOREIGN KEY ... REFERENCES` clauses point to the correct plural table names
- All `INDEX` and `CONSTRAINT` names are updated to reflect plural table names
- The DDL remains valid SQL (consistent `CREATE TABLE` / `REFERENCES` / `DROP TABLE` naming)
- Junction tables (`_jnt` suffix) are unchanged
- No singular `tt_` table names remain for the 32 tables listed above

---

## DO NOT

- Do NOT change any code files (models, controllers, services, migrations)
- Do NOT create any migrations
- Do NOT modify column names — only table names, FK references, and index names
- Do NOT rename junction tables (`_jnt` suffix tables)
- Do NOT change the order of tables in the DDL file
