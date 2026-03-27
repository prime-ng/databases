# Missing Migrations — Corrected Analysis

**Tarun's claim:** 14 DDL tables without migrations
**Reality:** 10 DDL tables truly have no migration

---

## Tarun's Errors (4 tables wrongly listed as "missing")

| # | Tarun Said "No Migration" | Reality | Explanation |
|---|---|---|---|
| 1 | `tt_teacher_availability` | **HAS migration** → `tt_teacher_availabilities` | Tarun searched for singular name only; migration uses plural |
| 2 | `tt_teacher_availability_detail` | **HAS migration** → `tt_teacher_availability_logs` | Different name, but same concept; migration exists |
| 3 | `tt_requirement_consolidation` | **HAS migration** → `tt_requirement_consolidations` | Tarun searched for singular; migration uses plural |
| 4 | `tt_class_requirement_subgroups` | **Tarun listed as needing migration** | Already in DDL as plural; indeed has no migration (this one IS correct) |

**Corrected count:** 10 DDL tables without any migration (not 14).

---

## Confirmed: 10 DDL Tables With No Migration

### Group A: Actively Referenced in Code — CREATE MIGRATIONS NOW

| # | DDL Table | Model `$table` | Referenced By | Impact |
|---|---|---|---|---|
| 1 | `tt_generation_strategy` | `tt_generation_strategy` | `Timetable.generation_strategy_id` FK, `GenerationStrategy` model used in controller | **CRASH** — FK reference to non-existent table |
| 2 | `tt_teacher_workload` | `tt_teacher_workloads` | `AnalyticsService::getWorkloadReport()` | **CRASH** — analytics page will 500 |
| 3 | `tt_constraint_violation` | `tt_constraint_violations` | `ConflictDetectionService`, `AnalyticsService` | **CRASH** — conflict detection writes here |
| 4 | `tt_change_log` | `tt_change_logs` | `RefinementService::logChange()` | **CRASH** — refinement swap logging fails |
| 5 | `tt_teacher_absence` | `tt_teacher_absences` | `SubstitutionService::reportAbsence()` | **CRASH** — substitution workflow unusable |
| 6 | `tt_substitution_log` | `tt_substitution_logs` | `SubstitutionService::assignSubstitute()` | **CRASH** — substitution logging fails |

### Group B: Referenced But Lower Priority

| # | DDL Table | Model `$table` | Referenced By | Impact |
|---|---|---|---|---|
| 7 | `tt_room_availability` | `tt_room_availabilities` | `RoomAvailabilityService`, `RoomAvailabilityDetail` parent | **Feature blocked** — room availability system |
| 8 | `tt_room_availability_detail` | `tt_room_availability_details` | Child of room_availability | **Feature blocked** — depends on #7 |
| 9 | `tt_priority_config` | `tt_priority_configs` | Referenced in constraint scoring | **Degraded** — defaults used when table missing |

### Group C: Design Only — No Active Code Path

| # | DDL Table | Model `$table` | Impact |
|---|---|---|---|
| 10 | `tt_class_requirement_groups` | `tt_class_requirement_groups` | LOW — part of future requirement consolidation |

Note: `tt_class_requirement_subgroups` also has no migration but was already correctly identified by Tarun.

---

## Why Tarun's Local DB Shows These Gaps

Tarun's analysis was performed by comparing the DDL file against the codebase **statically** (file reads, not database inspection). His local MySQL database likely has the same gaps as any fresh tenant DB — these 10 tables simply don't exist because no migration creates them.

This is **NOT** a local sync issue — it's a genuine gap in the migration set. Every tenant database in production will be missing these 10 tables.

---

## Migration Priority

| Priority | Tables | Effort | Blocks |
|---|---|---|---|
| P0 (immediate) | `tt_teacher_absences`, `tt_substitution_logs`, `tt_change_logs` | 30 min | Substitution + Refinement features |
| P1 (this sprint) | `tt_teacher_workloads`, `tt_constraint_violations` | 30 min | Analytics + Conflict detection |
| P2 (next sprint) | `tt_generation_strategy`, `tt_room_availabilities`, `tt_room_availability_details` | 1 hr | Generation strategy + Room availability |
| P3 (backlog) | `tt_priority_configs`, `tt_class_requirement_groups`, `tt_class_requirement_subgroups` | 30 min | Constraint scoring, requirements |
