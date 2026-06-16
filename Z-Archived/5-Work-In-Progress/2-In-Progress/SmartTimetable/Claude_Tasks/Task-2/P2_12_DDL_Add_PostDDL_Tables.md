# PROMPT: Add Post-DDL Tables to DDL — Schema Reconciliation — SmartTimetable DDL Gap Fix
**Task ID:** P2_12
**Issue IDs:** Migration-only tables not in DDL
**Priority:** P2-Medium
**Estimated Effort:** 30 minutes
**Prerequisites:** P2_09 (table names must be plural first)

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

4 tables were added via migration after the DDL was originally written and are not documented in `tenant_db_v2.sql`:

1. **`tt_parallel_groups`** — groups activities that must run in the same time slot (parallel periods). Added 2026-03-12.
2. **`tt_parallel_group_activities`** — junction table linking parallel groups to their member activities. Added 2026-03-12.
3. **`tt_class_subject_groups`** — defines subject groupings within a class for timetable generation.
4. **`tt_class_subject_subgroups`** — defines subgroups within a class subject group.

Additionally, 6 legacy tables exist in the DDL that have been superseded by the new schema but were never marked as deprecated:
- `tt_days`, `tt_periods`, `tt_timing_profile`, `tt_timing_profile_period`, `tt_timetable_modes`, `tt_class_mode_rules`

---

## PRE-READ (Mandatory)

1. `{DDL_FILE}` — full file to identify where new tables should be placed
2. `{LARAVEL_REPO}/database/migrations/tenant/` — search for migrations creating `tt_parallel_group`, `tt_class_subject_group`, `tt_class_subject_subgroup` to get exact column definitions
3. `{MODULE_PATH}/app/Models/ParallelGroup.php` — confirm `$table` and `$fillable`
4. `{MODULE_PATH}/app/Models/ParallelGroupActivity.php` — confirm `$table` and `$fillable`
5. `{MODULE_PATH}/app/Models/ClassSubjectGroup.php` — confirm `$table` and `$fillable`
6. `{MODULE_PATH}/app/Models/ClassSubjectSubgroup.php` — confirm `$table` and `$fillable`

---

## STEPS

### Step 1: Add `tt_parallel_groups` table definition

1. Read the migration file that creates this table
2. Create a `CREATE TABLE tt_parallel_groups` statement in the DDL with all columns from the migration
3. Place it after the activity-related tables (after `tt_activity_teachers`) since parallel groups relate to activities
4. Include standard columns: `id`, `is_active`, `created_by`, `created_at`, `updated_at`, `deleted_at`
5. Include all FK constraints and indexes from the migration

### Step 2: Add `tt_parallel_group_activities` table definition

1. Read the migration file
2. Create a `CREATE TABLE tt_parallel_group_activities` statement
3. Place it immediately after `tt_parallel_groups`
4. Include FK to `tt_parallel_groups` and `tt_activities`

### Step 3: Add `tt_class_subject_groups` table definition

1. Read the migration file
2. Create a `CREATE TABLE tt_class_subject_groups` statement
3. Place it near the class/section-related tables
4. Include all columns, FKs, and indexes from the migration

### Step 4: Add `tt_class_subject_subgroups` table definition

1. Read the migration file
2. Create a `CREATE TABLE tt_class_subject_subgroups` statement
3. Place it immediately after `tt_class_subject_groups`
4. Include FK to `tt_class_subject_groups`

### Step 5: Mark legacy tables as DEPRECATED

Add a comment block before each of these 6 legacy tables in the DDL:
```sql
-- ┌──────────────────────────────────────────────────────────┐
-- │ DEPRECATED: This table is superseded by the new schema.  │
-- │ Retained for backward compatibility. Do not use in new   │
-- │ code. See tt_period_sets, tt_shifts, tt_day_types.       │
-- └──────────────────────────────────────────────────────────┘
```

Legacy tables to mark:
- `tt_days` → superseded by `tt_day_types` + `tt_class_working_days`
- `tt_periods` → superseded by `tt_period_sets` + `tt_period_types`
- `tt_timing_profile` → superseded by `tt_period_sets`
- `tt_timing_profile_period` → superseded by `tt_period_sets`
- `tt_timetable_modes` → superseded by `tt_timetable_types`
- `tt_class_mode_rules` → superseded by class configuration

---

## ACCEPTANCE CRITERIA

- DDL contains complete CREATE TABLE definitions for all 4 post-DDL tables
- Each new table definition matches the migration columns exactly
- New tables are placed logically among existing `tt_*` tables
- All 6 legacy tables have DEPRECATED comment blocks
- DDL remains valid SQL syntax
- Total `tt_*` table count in DDL increases by 4

---

## DO NOT

- Do NOT change any code files (models, controllers, services)
- Do NOT create or modify any migrations
- Do NOT delete the 6 legacy table definitions — mark as deprecated only
- Do NOT modify existing DDL table definitions (that is covered by P2_10 and P2_11)
