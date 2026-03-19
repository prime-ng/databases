# PROMPT: Add Missing Columns to DDL Tables — Schema Reconciliation — SmartTimetable DDL Gap Fix
**Task ID:** P2_11
**Issue IDs:** Migration columns missing from DDL
**Priority:** P2-Medium
**Estimated Effort:** 1 hour
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

Several DDL tables are missing columns that exist in the actual migrations. The most significant gaps are:

- `tt_timetables` is missing 10 columns that were added for generation tracking and validation
- `tt_activities` has incorrect FK column names for class grouping and is missing `uuid`
- Multiple tables are missing `created_by` (standard audit column)
- Several tables are missing `deleted_at` (soft delete column)

The DDL must be updated to match migration columns for complete schema documentation.

---

## PRE-READ (Mandatory)

1. `{DDL_FILE}` — read all `tt_*` CREATE TABLE statements
2. `{LARAVEL_REPO}/database/migrations/tenant/` — search for migrations creating/modifying `tt_timetables`, `tt_activities`, and other tt_* tables
3. A sample of model files in `{MODULE_PATH}/app/Models/` — confirm `$fillable` arrays for column presence

---

## STEPS

### Step 1: Fix `tt_timetables` — add 10 missing columns

Add the following columns to the `tt_timetables` CREATE TABLE statement:
- `uuid CHAR(36) NULL` — after `id`
- `total_activities INT UNSIGNED DEFAULT 0` — after generation-related columns
- `placed_activities INT UNSIGNED DEFAULT 0`
- `failed_activities INT UNSIGNED DEFAULT 0`
- `hard_violations INT UNSIGNED DEFAULT 0`
- `soft_violations INT UNSIGNED DEFAULT 0`
- `settings_json JSON NULL`
- `generated_at TIMESTAMP NULL`
- `validated_at TIMESTAMP NULL`
- `validation_status ENUM('pending','valid','invalid','warnings') DEFAULT 'pending'`

### Step 2: Fix `tt_activities` — column name corrections and uuid

1. Rename index/FK references:
   - `class_group_id` → `class_subject_group_id` in INDEX and FK definitions
   - `class_subgroup_id` → `class_subject_subgroup_id` in INDEX and FK definitions
2. Add `uuid CHAR(36) NULL` after `id`

### Step 3: Add `created_by` to all tables missing it

Add `created_by INT UNSIGNED NULL` (before `created_at`) to every `tt_*` table that is missing this column. Cross-reference each CREATE TABLE statement — the standard column set is: `is_active`, `created_by`, `created_at`, `updated_at`, `deleted_at`.

### Step 4: Add `deleted_at` to tables missing it

Add `deleted_at TIMESTAMP NULL` (after `updated_at`) to these tables that are missing soft delete support:
- `tt_generation_strategy`
- `tt_constraint_violations`
- `tt_change_logs`
- Any other `tt_*` table missing `deleted_at`

### Step 5: Cross-reference validation

For each `tt_*` table in the DDL, compare columns against the corresponding migration. Document any remaining discrepancies as comments in the DDL for future resolution.

---

## ACCEPTANCE CRITERIA

- `tt_timetables` DDL has all 10 additional columns matching the migration
- `tt_activities` DDL uses `class_subject_group_id` and `class_subject_subgroup_id` in INDEX/FK references
- `tt_activities` DDL has `uuid` column
- Every `tt_*` table has the standard column set: `is_active`, `created_by`, `created_at`, `updated_at`, `deleted_at`
- All DDL tables match their migration counterparts in column count and names
- DDL remains valid SQL syntax

---

## DO NOT

- Do NOT change any code files (models, controllers, services, migrations)
- Do NOT create any migrations
- Do NOT modify column names that are already correct
- Do NOT remove any existing columns from the DDL — additive changes only
- Do NOT change data types of existing columns unless they clearly don't match the migration
