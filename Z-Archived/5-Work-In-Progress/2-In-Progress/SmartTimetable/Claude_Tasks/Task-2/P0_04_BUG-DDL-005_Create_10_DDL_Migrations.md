# PROMPT: Create 10 Missing DDL Table Migrations — SmartTimetable DDL Gap Fix
**Task ID:** P0_04
**Issue IDs:** BUG-DDL-005
**Priority:** P0-Critical
**Estimated Effort:** 2 hours
**Prerequisites:** None — this is a P0 task, do it first

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

10 tables are defined in the DDL (`tenant_db_v2.sql`) but have NO Laravel migration. These tables do not exist in the database, causing runtime crashes when any service queries the corresponding models. This blocks Analytics (P14), Refinement (P15), Substitution (P16), and other features.

All migrations must use **plural table names** matching model `$table` values and follow the **additive-only** migration policy. Every table must include standard columns: `is_active`, `created_by`, `created_at`, `updated_at`, `deleted_at`.

See `02_Missing_Migrations_Corrected.md` and `05_Real_Bugs_Found.md` — BUG-DDL-005.

---

## PRE-READ (Mandatory)

1. `{DDL_FILE}` — Read the CREATE TABLE definitions for these 10 `tt_*` tables
2. The corresponding model files in `{MODULE_PATH}/app/Models/` for each table (to confirm `$table` and `$fillable`)
3. `{LARAVEL_REPO}/database/migrations/tenant/` — verify no migration already exists for these tables

---

## STEPS

Create one migration file per table in `{LARAVEL_REPO}/database/migrations/tenant/`. Use timestamp prefix `2026_03_17_NNNNNN` with sequential numbers.

### Sub-Task 4.1: tt_teacher_absences (from DDL tt_teacher_absence)
- **Model:** TeacherAbsences.php → `$table = 'tt_teacher_absences'`
- **Columns:** id (INT UNSIGNED PK AI), teacher_id (INT UNSIGNED FK→sch_teachers), absence_date (DATE NOT NULL), absence_type (ENUM: LEAVE,SICK,TRAINING,OFFICIAL_DUTY,OTHER), start_period (TINYINT UNSIGNED NULL), end_period (TINYINT UNSIGNED NULL), reason (VARCHAR 500 NULL), status (ENUM: PENDING,APPROVED,REJECTED,CANCELLED default PENDING), approved_by (INT UNSIGNED NULL FK→sys_users), approved_at (TIMESTAMP NULL), substitution_required (TINYINT 1 default 1), substitution_completed (TINYINT 1 default 0), is_active (TINYINT 1 default 1), created_by (INT UNSIGNED NULL FK→sys_users), created_at, updated_at, deleted_at
- **Indexes:** UNIQUE(teacher_id, absence_date), INDEX(absence_date), INDEX(status)
- **Priority:** P0 — blocks SubstitutionService

### Sub-Task 4.2: tt_substitution_logs (from DDL tt_substitution_log)
- **Model:** SubstitutionLog.php → `$table = 'tt_substitution_logs'`
- **Columns:** id (INT UNSIGNED PK AI), teacher_absence_id (INT UNSIGNED NULL FK→tt_teacher_absences), cell_id (INT UNSIGNED FK→tt_timetable_cells), substitution_date (DATE NOT NULL), absent_teacher_id (INT UNSIGNED FK→sch_teachers), substitute_teacher_id (INT UNSIGNED FK→sch_teachers), assignment_method (ENUM: AUTO,MANUAL,SWAP default MANUAL), reason (VARCHAR 500 NULL), status (ENUM: ASSIGNED,COMPLETED,CANCELLED default ASSIGNED), notified_at (TIMESTAMP NULL), accepted_at (TIMESTAMP NULL), completed_at (TIMESTAMP NULL), feedback (TEXT NULL), assigned_by (INT UNSIGNED NULL FK→sys_users), is_active (TINYINT 1 default 1), created_at, updated_at, deleted_at
- **Indexes:** INDEX(substitution_date), INDEX(absent_teacher_id), INDEX(substitute_teacher_id), INDEX(status)
- **Priority:** P0 — blocks SubstitutionService
- **Note:** Must run AFTER 4.1 (FK dependency on tt_teacher_absences)

### Sub-Task 4.3: tt_change_logs (from DDL tt_change_log)
- **Model:** ChangeLog.php → `$table = 'tt_change_logs'`
- **Columns:** id (INT UNSIGNED PK AI), timetable_id (INT UNSIGNED FK→tt_timetables), cell_id (INT UNSIGNED NULL FK→tt_timetable_cells ON DELETE SET NULL), change_type (ENUM: CREATE,UPDATE,DELETE,LOCK,UNLOCK,SWAP,SUBSTITUTE), change_date (DATE NOT NULL), old_values_json (JSON NULL), new_values_json (JSON NULL), reason (VARCHAR 500 NULL), changed_by (INT UNSIGNED NULL FK→sys_users ON DELETE SET NULL), is_active (TINYINT 1 default 1), created_by (INT UNSIGNED NULL), created_at, updated_at, deleted_at
- **Indexes:** INDEX(timetable_id), INDEX(cell_id), INDEX(change_date), INDEX(change_type)
- **Priority:** P0 — blocks RefinementService

### Sub-Task 4.4: tt_teacher_workloads (from DDL tt_teacher_workload)
- **Model:** TeacherWorkload.php → `$table = 'tt_teacher_workloads'`
- **Columns:** id (INT UNSIGNED PK AI), teacher_id (INT UNSIGNED FK→sch_teachers), academic_session_id (INT UNSIGNED FK→sch_org_academic_sessions_jnt), timetable_id (INT UNSIGNED NULL FK→tt_timetables ON DELETE SET NULL), weekly_periods_assigned (SMALLINT UNSIGNED default 0), weekly_periods_max (SMALLINT UNSIGNED NULL), weekly_periods_min (SMALLINT UNSIGNED NULL), daily_distribution_json (JSON NULL), subjects_assigned_json (JSON NULL), classes_assigned_json (JSON NULL), utilization_percent (DECIMAL 5,2 NULL), gap_periods_total (SMALLINT UNSIGNED default 0), consecutive_max (TINYINT UNSIGNED default 0), last_calculated_at (TIMESTAMP NULL), is_active (TINYINT 1 default 1), created_by (INT UNSIGNED NULL), created_at, updated_at, deleted_at
- **Indexes:** UNIQUE(teacher_id, academic_session_id, timetable_id), INDEX(academic_session_id)
- **Priority:** P0 — blocks AnalyticsService

### Sub-Task 4.5: tt_constraint_violations (from DDL tt_constraint_violation)
- **Model:** ConstraintViolation.php → `$table = 'tt_constraint_violations'`
- **Columns:** id (INT UNSIGNED PK AI), timetable_id (INT UNSIGNED FK→tt_timetables ON DELETE CASCADE), constraint_id (INT UNSIGNED FK→tt_constraints ON DELETE CASCADE), violation_type (ENUM: HARD,SOFT NOT NULL), violation_count (INT UNSIGNED NOT NULL), violation_details (JSON NULL), is_active (TINYINT 1 default 1), created_by (INT UNSIGNED NULL), created_at, updated_at, deleted_at
- **Indexes:** INDEX(timetable_id), INDEX(constraint_id)
- **Priority:** P0 — blocks ConflictDetectionService

### Sub-Task 4.6: tt_generation_strategy (singular — matches model)
- **Model:** TtGenerationStrategy.php → `$table = 'tt_generation_strategy'`
- **Columns:** id (SMALLINT UNSIGNED PK AI), code (VARCHAR 20 NOT NULL UNIQUE), name (VARCHAR 100 NOT NULL), description (VARCHAR 255 NULL), algorithm_type (ENUM: RECURSIVE,GENETIC,SIMULATED_ANNEALING,TABU_SEARCH,HYBRID default RECURSIVE), max_recursive_depth (INT UNSIGNED default 14), max_placement_attempts (INT UNSIGNED default 2000), tabu_size (INT UNSIGNED default 100), cooling_rate (DECIMAL 5,2 default 0.95), population_size (INT UNSIGNED default 50), generations (INT UNSIGNED default 100), activity_sorting_method (ENUM: LESS_TEACHER_FIRST,DIFFICULTY_FIRST,CONSTRAINT_COUNT,DURATION_FIRST,RANDOM default LESS_TEACHER_FIRST), timeout_seconds (INT UNSIGNED default 300), parameters_json (JSON NULL), is_default (TINYINT 1 default 0), is_active (TINYINT 1 default 1), created_by (INT UNSIGNED NULL), created_at, updated_at, deleted_at
- **Indexes:** UNIQUE(code)
- **Priority:** P1 — FK from tt_timetables.generation_strategy_id

### Sub-Task 4.7: tt_room_availabilities (from DDL tt_room_availability)
- **Model:** RoomAvailability.php → `$table = 'tt_room_availabilities'`
- **Columns:** id (INT UNSIGNED PK AI), room_id (INT UNSIGNED FK→sch_rooms), room_type_id (INT UNSIGNED NULL), total_rooms_in_category (SMALLINT UNSIGNED NOT NULL), can_be_assigned (TINYINT 1 default 1), overall_availability_status (ENUM: Available,Unavailable,Partially_Available,Assigned default Available), available_for_full_timetable_duration (TINYINT 1 default 1), is_class_house_room (TINYINT 1 default 0), house_room_class_id (INT UNSIGNED NULL), house_room_section_id (INT UNSIGNED NULL), activity_id (INT UNSIGNED NULL), capacity (INT UNSIGNED NULL), max_limit (INT UNSIGNED NULL), can_be_assigned_for_lecture (TINYINT 1 default 1), can_be_assigned_for_practical (TINYINT 1 default 1), can_be_assigned_for_exam (TINYINT 1 default 1), can_be_assigned_for_activity (TINYINT 1 default 1), can_be_assigned_for_sports (TINYINT 1 default 1), timetable_start_time (TIME NOT NULL), timetable_end_time (TIME NOT NULL), is_active (TINYINT 1 default 1), created_by (INT UNSIGNED NULL), created_at, updated_at, deleted_at
- **Priority:** P1 — room availability system
- **Note:** DDL has inconsistent FK/INDEX references — use columns as listed above, skip broken FK refs

### Sub-Task 4.8: tt_room_availability_details (from DDL tt_room_availability_detail)
- **Model:** RoomAvailabilityDetail.php → `$table = 'tt_room_availability_details'`
- **Columns:** id (INT UNSIGNED PK AI), room_availability_id (INT UNSIGNED FK→tt_room_availabilities), room_id (INT UNSIGNED), room_type_id (INT UNSIGNED), day_number (TINYINT UNSIGNED NOT NULL), day_name (VARCHAR 10 NOT NULL), period_number (TINYINT UNSIGNED NOT NULL), availability_for_period (ENUM: Available,Unavailable,Assigned default Available), assigned_class_id (INT UNSIGNED NULL), assigned_section_id (INT UNSIGNED NULL), assigned_subject_study_format_id (INT UNSIGNED NULL), room_available_from_date (DATE NULL), activity_id (INT UNSIGNED NULL), is_active (TINYINT 1 default 1), created_by (INT UNSIGNED NULL), created_at, updated_at, deleted_at
- **Priority:** P1 — depends on 4.7

### Sub-Task 4.9: tt_priority_configs (from DDL tt_priority_config)
- **Model:** PriorityConfig.php → `$table = 'tt_priority_configs'`
- **Columns:** id (INT UNSIGNED PK AI), requirement_consolidation_id (INT UNSIGNED NULL), tot_students (INT UNSIGNED NULL), teacher_scarcity_index (DECIMAL 7,2 default 1), weekly_load_ratio (DECIMAL 7,2 default 1), average_teacher_availability_ratio (DECIMAL 7,2 default 1), rigidity_score (DECIMAL 7,2 default 1), resource_scarcity (DECIMAL 7,2 default 1), subject_difficulty_index (DECIMAL 7,2 default 1), is_active (TINYINT 1 default 1), created_by (INT UNSIGNED NULL), created_at, updated_at, deleted_at
- **Priority:** P2 — constraint scoring

### Sub-Task 4.10: tt_class_requirement_groups (already plural in DDL)
- **Model:** ClassRequirementGroup.php → `$table = 'tt_class_requirement_groups'`
- **Columns:** id (INT UNSIGNED PK AI), code (CHAR 50 NOT NULL UNIQUE), name (VARCHAR 100 NOT NULL), class_group_id (INT UNSIGNED), class_id (INT UNSIGNED FK→sch_classes), section_id (INT UNSIGNED NULL FK→sch_sections), subject_id (INT UNSIGNED), study_format_id (INT UNSIGNED), subject_type_id (INT UNSIGNED), subject_study_format_id (INT UNSIGNED), class_house_room_id (INT UNSIGNED), student_count (INT UNSIGNED NULL), eligible_teacher_count (INT UNSIGNED NULL), is_active (TINYINT 1 default 1), created_by (INT UNSIGNED NULL), created_at, updated_at, deleted_at
- **Indexes:** UNIQUE(code), INDEX(class_id, section_id)
- **Priority:** P2 — requirement system
- **Note:** DDL has broken FK references to undefined columns — skip those, use columns as listed

---

## VERIFICATION

After creating all 10 migrations:
1. Run `php artisan migrate --pretend` to dry-run and check SQL output
2. Run `php artisan migrate` to actually create the tables
3. Verify each model can execute `Model::first()` without "table not found" error

---

## ACCEPTANCE CRITERIA

- All 10 migration files created in `database/migrations/tenant/`
- `php artisan migrate` succeeds without errors
- Each model's corresponding table exists in the tenant database
- All tables have: id, is_active, created_by, created_at, updated_at, deleted_at columns
- FK constraints that reference existing tables are properly defined
- No existing data or tables are affected

---

## DO NOT

- Do NOT drop or modify any existing tables
- Do NOT rename any existing columns (additive-only policy — Decision D17)
- Do NOT use singular table names — use plural matching model `$table` values
- Do NOT add FK constraints referencing tables that don't exist yet (skip broken DDL FKs)
- Do NOT modify any model files in this task — models already have correct `$table` values
