# Table Name Mismatches — Corrected Analysis

**Tarun's claim:** 32 singular/plural mismatches, 10 matching tables
**Reality:** 39 singular in DDL (all needing pluralization), 3 genuinely plural, 2 DDL-missing tables

---

## Correction: Tarun's "10 Matching Tables" List

| # | Tarun Said "Matches" | Actual DDL Name | Actual Status |
|---|---|---|---|
| 1 | `tt_config` | `tt_config` | **Singular** — but Model also uses `tt_config` → TRUE match (singular works in Laravel for config tables) |
| 2 | `tt_generation_strategy` | `tt_generation_strategy` | **Singular** — Model uses `tt_generation_strategy` → TRUE match but NO migration exists |
| 3 | `tt_school_days` | `tt_school_days` | **Plural** → TRUE match |
| 4 | `tt_working_day` | `tt_working_day` | **Singular** — Model uses `tt_working_day` → TRUE match |
| 5 | `tt_class_working_day_jnt` | `tt_class_working_day_jnt` | **Singular** — Model uses `tt_class_working_day_jnt` → Match, BUT migration creates `tt_class_working_days` (different!) |
| 6 | `tt_period_set_period_jnt` | `tt_period_set_period_jnt` | **Singular** — Model and migration match → TRUE match |
| 7 | `tt_class_timetable_type_jnt` | `tt_class_timetable_type_jnt` | **Singular** — TRUE match |
| 8 | `tt_constraint_category_scope` | `tt_constraint_category_scope` | **Singular** — TRUE match |
| 9 | `tt_parallel_group` | **NOT IN DDL** | Migration-only table; Tarun assumed it was in DDL |
| 10 | `tt_parallel_group_activity` | **NOT IN DDL** | Migration-only table; Tarun assumed it was in DDL |

**Result:** Only 8 of Tarun's 10 "matching" tables actually exist in the DDL (and 2 of those have migration name conflicts).

---

## Corrected Full Table Inventory

### Category A: DDL + Migration + Model — All Three Exist (28 tables)

These tables exist in DDL (singular), have a migration (plural), and have a model. The name difference is cosmetic (DDL is design doc, migration is source of truth).

| # | DDL Name (Singular) | Migration Creates (Plural) | Model `$table` | Name Match? |
|---|---|---|---|---|
| 1 | `tt_config` | `tt_config` | `tt_config` | MATCH (all singular) |
| 2 | `tt_shift` | `tt_shifts` | `tt_shifts` | Migration=Model, DDL differs |
| 3 | `tt_day_type` | `tt_day_types` | `tt_day_types` | Migration=Model, DDL differs |
| 4 | `tt_period_type` | `tt_period_types` | `tt_period_types` | Migration=Model, DDL differs |
| 5 | `tt_teacher_assignment_role` | `tt_teacher_assignment_roles` | `tt_teacher_assignment_roles` | Migration=Model, DDL differs |
| 6 | `tt_school_days` | `tt_school_days` | `tt_school_days` | MATCH (all plural) |
| 7 | `tt_working_day` | `tt_working_day` | `tt_working_day` | MATCH (all singular) |
| 8 | `tt_period_set` | `tt_period_sets` | `tt_period_sets` | Migration=Model, DDL differs |
| 9 | `tt_period_set_period_jnt` | `tt_period_set_period_jnt` | `tt_period_set_period_jnt` | MATCH (all singular jnt) |
| 10 | `tt_timetable_type` | `tt_timetable_types` | `tt_timetable_types` | Migration=Model, DDL differs |
| 11 | `tt_class_timetable_type_jnt` | `tt_class_timetable_type_jnt` | `tt_class_timetable_type_jnt` | MATCH |
| 12 | `tt_slot_requirement` | `tt_slot_requirements` | `tt_slot_requirements` | Migration=Model, DDL differs |
| 13 | `tt_requirement_consolidation` | `tt_requirement_consolidations` | `tt_requirement_consolidations` | Migration=Model, DDL differs |
| 14 | `tt_constraint_category_scope` | `tt_constraint_category_scope` | `tt_constraint_category_scope` | MATCH |
| 15 | `tt_constraint_type` | `tt_constraint_types` | `tt_constraint_types` | Migration=Model, DDL differs |
| 16 | `tt_constraint` | `tt_constraints` | `tt_constraints` | Migration=Model, DDL differs |
| 17 | `tt_teacher_unavailable` | `tt_teacher_unavailables` | `tt_teacher_unavailables` | Migration=Model, DDL differs |
| 18 | `tt_room_unavailable` | `tt_room_unavailables` | `tt_room_unavailables` | Migration=Model, DDL differs |
| 19 | `tt_teacher_availability` | `tt_teacher_availabilities` | `tt_teacher_availabilities` | Migration=Model, DDL differs |
| 20 | `tt_activity` | `tt_activities` | `tt_activities` | Migration=Model, DDL differs |
| 21 | `tt_sub_activity` | `tt_sub_activities` | `tt_sub_activities` | Migration=Model, DDL differs |
| 22 | `tt_activity_priority` | `tt_activity_priorities` | `tt_activity_priorities` | Migration=Model, DDL differs |
| 23 | `tt_activity_teacher` | `tt_activity_teachers` | `tt_activity_teachers` | Migration=Model, DDL differs |
| 24 | `tt_timetable` | `tt_timetables` | `tt_timetables` | Migration=Model, DDL differs |
| 25 | `tt_conflict_detection` | `tt_conflict_detections` | `tt_conflict_detections` | Migration=Model, DDL differs |
| 26 | `tt_resource_booking` | `tt_resource_bookings` | `tt_resource_bookings` | Migration=Model, DDL differs |
| 27 | `tt_generation_run` | `tt_generation_runs` | `tt_generation_runs` | Migration=Model, DDL differs |
| 28 | `tt_timetable_cell` | `tt_timetable_cells` | `tt_timetable_cells` | Migration=Model, DDL differs |

### Category B: DDL Only — No Migration Exists (10 tables)

These tables are designed in the DDL but never created by any migration. **They do NOT exist in the database.**

| # | DDL Table | Model Exists? | Model `$table` | REAL GAP? |
|---|---|---|---|---|
| 1 | `tt_generation_strategy` | Yes | `tt_generation_strategy` | YES — FK referenced by `tt_timetables.generation_strategy_id` |
| 2 | `tt_room_availability` | Yes | `tt_room_availabilities` | YES — used by RoomAvailabilityService |
| 3 | `tt_room_availability_detail` | Yes | `tt_room_availability_details` | YES — child of room_availability |
| 4 | `tt_priority_config` | Yes | `tt_priority_configs` | YES — used in constraint scoring |
| 5 | `tt_constraint_violation` | Yes | `tt_constraint_violations` | YES — used by ConflictDetectionService |
| 6 | `tt_teacher_workload` | Yes | `tt_teacher_workloads` | YES — used by AnalyticsService |
| 7 | `tt_change_log` | Yes | `tt_change_logs` | YES — used by RefinementService |
| 8 | `tt_teacher_absence` | Yes | `tt_teacher_absences` | YES — used by SubstitutionService |
| 9 | `tt_substitution_log` | Yes | `tt_substitution_logs` | YES — used by SubstitutionService |
| 10 | `tt_class_requirement_groups` | Yes | `tt_class_requirement_groups` | LOW — part of requirement system |

Note: `tt_class_requirement_subgroups` (DDL) does NOT have a model with matching table name — the closest is `ClassRequirementSubgroup` but need to verify.

### Category C: Migration Only — Not in DDL (10 tables)

| # | Migration Creates | Model Exists? | Status |
|---|---|---|---|
| 1 | `tt_days` | `Day.php` | Legacy — replaced by `tt_school_days` |
| 2 | `tt_periods` | `Period.php` | Legacy — replaced by `tt_period_type` + `tt_period_set` |
| 3 | `tt_timing_profile` | `TimingProfile.php` | Legacy — absorbed into period sets |
| 4 | `tt_timing_profile_period` | `TimingProfilePeriod.php` | Legacy — absorbed into period set periods |
| 5 | `tt_timetable_modes` | `TimetableMode.php` | Legacy — replaced by `tt_timetable_type` |
| 6 | `tt_class_mode_rules` | `ClassModeRule.php` | Legacy — replaced by `tt_class_timetable_type_jnt` |
| 7 | `tt_class_working_days` | None (model uses `tt_class_working_day_jnt`) | NAME CONFLICT — model points to DDL name, migration uses different name |
| 8 | `tt_teacher_availability_logs` | `TeacherAvailabilityLog.php` uses `tt_teacher_availability_details` | NAME CONFLICT — three different names! |
| 9 | `tt_parallel_group` | `ParallelGroup.php` | OK — added post-DDL (2026-03-12) |
| 10 | `tt_parallel_group_activity` | `ParallelGroupActivity.php` | OK — added post-DDL (2026-03-12) |

### Category D: Model-Only Name Conflicts (2 BUGS)

| Model | Model `$table` | Migration Creates | DDL Table | BUG? |
|---|---|---|---|---|
| `ClassWorkingDay` | `tt_class_working_day_jnt` | `tt_class_working_days` | `tt_class_working_day_jnt` | **YES** — Model queries non-existent table name at runtime |
| `TeacherAvailabilityLog` | `tt_teacher_availability_details` | `tt_teacher_availability_logs` | `tt_teacher_availability_detail` | **YES** — Three names, none match; model queries non-existent table |

---

## Recommendation

**DDL should be updated to match migrations (plural names).** The DDL is a design blueprint. The running code (migrations+models) is the source of truth. Update DDL to align, not the other way around.

**Two model `$table` bugs must be fixed immediately** — `ClassWorkingDay` and `TeacherAvailabilityLog` reference tables that don't exist under those names.
