# PROMPT: Add Phantom Table Definitions to DDL — Schema Reconciliation — SmartTimetable DDL Gap Fix
**Task ID:** P2_13
**Issue IDs:** 12 phantom tables need DDL
**Priority:** P2-Medium
**Estimated Effort:** 1 hour
**Prerequisites:** P0_04 (migrations for these tables must exist first), P2_09 (table names must be plural)

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

The 12 phantom tables that received migrations in task P0_04 (BUG-DDL-005) need corresponding `CREATE TABLE` definitions in the DDL for schema documentation completeness. These tables were originally referenced only by models without any DDL or migration. After P0_04 created the migrations, the tables exist in the database but are still missing from the DDL design document.

The DDL serves as the canonical schema reference for the project — every table that exists in a migration should also have a DDL definition.

---

## PRE-READ (Mandatory)

1. `{DDL_FILE}` — full file to identify placement positions for new tables
2. The 12 migration files created in P0_04 in `{LARAVEL_REPO}/database/migrations/tenant/` — these are the source of truth for column definitions:
   - Search for `tt_analytics_daily_snapshots`
   - Search for `tt_room_utilizations`
   - Search for `tt_constraint_target_types`
   - Search for `tt_conflict_resolution_sessions`
   - Search for `tt_conflict_resolution_options`
   - Search for `tt_impact_analysis_sessions`
   - Search for `tt_impact_analysis_details`
   - Search for `tt_batch_operations`
   - Search for `tt_batch_operation_items`
   - Search for `tt_substitution_patterns`
   - Search for `tt_substitution_recommendations`
   - Search for `tt_generation_queues`
3. Corresponding model files in `{MODULE_PATH}/app/Models/` to confirm `$table` names

---

## STEPS

### Step 1: Create DDL for Analytics tables

Add CREATE TABLE statements for:

1. **`tt_analytics_daily_snapshots`** — daily timetable health metrics
   - Place near `tt_teacher_workloads` and `tt_room_utilizations` (analytics section)
   - Use migration column definitions as source

2. **`tt_room_utilizations`** — room usage statistics per timetable
   - Place near analytics tables

### Step 2: Create DDL for Constraint Infrastructure tables

3. **`tt_constraint_target_types`** — defines what entities constraints can target (teacher, class, room, etc.)
   - Place near `tt_constraint_types` and `tt_constraints`

### Step 3: Create DDL for Conflict Resolution tables

4. **`tt_conflict_resolution_sessions`** — tracks conflict resolution workflows
   - Place after `tt_conflict_detections`

5. **`tt_conflict_resolution_options`** — resolution options for each conflict session
   - Place immediately after `tt_conflict_resolution_sessions`

### Step 4: Create DDL for Impact Analysis tables

6. **`tt_impact_analysis_sessions`** — tracks swap/move impact analysis requests
   - Place near refinement-related tables

7. **`tt_impact_analysis_details`** — detailed results of each impact analysis
   - Place immediately after `tt_impact_analysis_sessions`

### Step 5: Create DDL for Batch Operations tables

8. **`tt_batch_operations`** — tracks batch swap/move operations
   - Place near refinement-related tables

9. **`tt_batch_operation_items`** — individual items within a batch operation
   - Place immediately after `tt_batch_operations`

### Step 6: Create DDL for Substitution tables

10. **`tt_substitution_patterns`** — learned patterns for substitution scoring
    - Place near `tt_substitution_logs`

11. **`tt_substitution_recommendations`** — auto-generated substitute teacher recommendations
    - Place immediately after `tt_substitution_patterns`

### Step 7: Create DDL for Generation Queue table

12. **`tt_generation_queues`** — queued timetable generation jobs
    - Place near `tt_generation_runs`

### Step 8: Validation

1. Count all `tt_*` CREATE TABLE statements in the DDL — total should increase by 12
2. Verify each new table has standard columns: `id`, `is_active`, `created_by`, `created_at`, `updated_at`, `deleted_at`
3. Verify FK references point to existing (plural-named) tables
4. Ensure no duplicate table names in the DDL

---

## ACCEPTANCE CRITERIA

- DDL contains CREATE TABLE definitions for all 12 tables listed above
- Each definition matches the corresponding migration columns exactly (names, types, defaults, constraints)
- All FK references point to correct table names (plural, matching P2_09 renames)
- Each table has the standard audit column set: `is_active`, `created_by`, `created_at`, `updated_at`, `deleted_at`
- New tables are placed logically near related existing tables
- Total `tt_*` table count in DDL increases by exactly 12
- DDL remains valid SQL syntax

---

## DO NOT

- Do NOT change any code files (models, controllers, services)
- Do NOT modify existing DDL table definitions
- Do NOT create or modify any migrations — use existing P0_04 migrations as source
- Do NOT add tables for the 25 Phase-2 phantom models (those have no migrations)
- Do NOT change column definitions to differ from the migration — DDL must match migration exactly
