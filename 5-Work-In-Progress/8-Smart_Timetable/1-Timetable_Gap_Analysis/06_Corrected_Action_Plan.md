# Corrected Action Plan

Based on verified findings from cross-referencing Tarun's audit against actual DDL + codebase.

---

## Priority 0: IMMEDIATE — Fix Runtime Crashes (2-3 hours)

### Action 0.1: Fix 2 Model Table Name Bugs
| Model | Current `$table` | Change To | Why |
|---|---|---|---|
| `ClassWorkingDay` | `tt_class_working_day_jnt` | `tt_class_working_days` | Match migration |
| `TeacherAvailabilityLog` | `tt_teacher_availability_details` | `tt_teacher_availability_logs` | Match migration |

### Action 0.2: Fix TimetableCell scopeForClass()
Change from direct `class_id`/`section_id` query to `whereHas('activity', ...)` since those columns exist on `tt_activities`, not `tt_timetable_cells`.

### Action 0.3: Create 22 Missing Migrations
**10 for DDL-designed tables (no migration exists):**

| Table to Create | Schema Source | Priority |
|---|---|---|
| `tt_teacher_absences` | DDL `tt_teacher_absence` + pluralize | P0 — blocks substitution |
| `tt_substitution_logs` | DDL `tt_substitution_log` + pluralize | P0 — blocks substitution |
| `tt_change_logs` | DDL `tt_change_log` + pluralize | P0 — blocks refinement |
| `tt_teacher_workloads` | DDL `tt_teacher_workload` + pluralize | P0 — blocks analytics |
| `tt_constraint_violations` | DDL `tt_constraint_violation` + pluralize | P0 — blocks conflict detection |
| `tt_generation_strategy` | DDL `tt_generation_strategy` (keep singular, matches model) | P1 |
| `tt_room_availabilities` | DDL `tt_room_availability` + pluralize | P1 |
| `tt_room_availability_details` | DDL `tt_room_availability_detail` + pluralize | P1 |
| `tt_priority_configs` | DDL `tt_priority_config` + pluralize | P2 |
| `tt_class_requirement_groups` | DDL `tt_class_requirement_groups` (already plural) | P2 |

**12 for phantom models referenced in active code:**

| Table to Create | Referenced By | Priority |
|---|---|---|
| `tt_analytics_daily_snapshots` | AnalyticsService | P0 |
| `tt_room_utilizations` | AnalyticsService | P0 |
| `tt_constraint_target_types` | ConstraintController | P0 |
| `tt_conflict_resolution_sessions` | RefinementService | P1 |
| `tt_conflict_resolution_options` | RefinementService | P1 |
| `tt_impact_analysis_sessions` | RefinementService | P1 |
| `tt_impact_analysis_details` | RefinementService | P1 |
| `tt_batch_operations` | RefinementService | P1 |
| `tt_batch_operation_items` | RefinementService | P1 |
| `tt_substitution_patterns` | SubstitutionService | P1 |
| `tt_substitution_recommendations` | SubstitutionService | P1 |
| `tt_generation_queues` | GenerateTimetableJob | P2 |

**Migration rule:** Follow additive-only policy (D17). Use plural names matching model `$table`. Include standard columns (`is_active`, `created_by`, `created_at`, `updated_at`, `deleted_at`).

---

## Priority 1: HIGH — Fix Silent Bugs (1 hour)

### Action 1.1: Clean Constraint Model Fillable
Remove non-existent columns from model `$fillable`:
- `Constraint`: remove `apply_for_all_days` (or add column via migration if needed)
- `ConstraintType`: remove `conflict_detection_logic`, `validation_logic`, `resolution_priority` (or add columns)

### Action 1.2: Annotate 25 Dormant Phantom Models
Add to each model:
```php
/**
 * @phase2 — No migration exists. DO NOT use until table is created.
 * @see 5-Work-In-Progress/8-Smart_Timetable/1-Timetable_Gap_Analysis/03_Phantom_Models_Confirmed.md
 */
```

---

## Priority 2: MEDIUM — DDL Reconciliation (4-6 hours)

### Action 2.1: Update DDL Table Names to Plural
Update `tenant_db_v2.sql` for all 28 mismatched singular tables to match migration plural names.

### Action 2.2: Update DDL Column Names for Constraint Tables
Align `tt_constraint` and `tt_constraint_type` DDL columns with actual migration columns.

### Action 2.3: Add Missing Columns to DDL
- `tt_timetable`: add `uuid`, `total_activities`, `placed_activities`, etc. (10 columns)
- `tt_activity`: fix `class_group_id` → `class_subject_group_id` in INDEX/FK
- All tables: add `created_by` to the 36 tables missing it

### Action 2.4: Add Post-DDL Tables to DDL
Add these migration-only tables to the DDL:
- `tt_parallel_group`, `tt_parallel_group_activity` (parallel periods, added 2026-03-12)
- `tt_class_subject_groups`, `tt_class_subject_subgroups` (class grouping)
- Document 6 legacy tables as deprecated

### Action 2.5: Add Phantom Table Definitions to DDL
For the 12 phantom tables getting migrations (Action 0.3), also add their definitions to the DDL.

---

## Priority 3: LOW — Backlog (2-3 hours)

### Action 3.1: Fix TeacherAvailablity Typo
Rename class and file: `TeacherAvailablity` → `TeacherAvailability`. Update all imports.

### Action 3.2: Clean Up Dead Alias Columns
Consider migration to drop the 5 unused alias columns from `tt_constraints` added by `2026_03_12_100002`. Or wire the model to use them and drop the originals. Pick one direction.

### Action 3.3: Clean Up Duplicate Columns in tt_constraint_types
Table now has both `is_hard_constraint` + `is_hard_capable`, `param_schema` + `parameter_schema`. Sync values or drop old columns.

### Action 3.4: Mark Legacy Tables as Deprecated
Add deprecation notice to models for: `Day`, `Period`, `TimingProfile`, `TimingProfilePeriod`, `TimetableMode`, `ClassModeRule`.

---

## Effort Summary

| Priority | Actions | Effort | Who |
|---|---|---|---|
| P0: Fix crashes | 2 model fixes + 22 migrations + 1 scope fix | 2-3 hours | Tarun |
| P1: Silent bugs | 2 fillable cleanups + 25 annotations | 1 hour | Tarun |
| P2: DDL reconciliation | Full DDL update (5 sub-tasks) | 4-6 hours | Brijesh |
| P3: Cleanup | Typo + alias columns + deprecation | 2-3 hours | Anyone |
| **Total** | | **~10-13 hours** | |

---

## Decisions for Team

| # | Question | Recommendation |
|---|---|---|
| D-A | Phantom models: delete or keep? | **Keep** 12 active + annotate 25 dormant as @phase2 |
| D-B | DDL vs code: which is source of truth? | **Code (migrations)** — update DDL to match |
| D-C | Dead alias columns: keep or drop? | **Drop** via migration — they cause confusion |
| D-D | Legacy tables: keep or remove? | **Keep migrations** (immutability), deprecate models |
| D-E | Who creates the 22 missing migrations? | **Tarun** — he wrote the services that need them |
