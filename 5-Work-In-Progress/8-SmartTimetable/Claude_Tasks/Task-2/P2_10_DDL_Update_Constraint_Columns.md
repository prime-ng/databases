# PROMPT: Update DDL Constraint Table Columns — Schema Reconciliation — SmartTimetable DDL Gap Fix
**Task ID:** P2_10
**Issue IDs:** Column drift in constraint tables
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

The `tt_constraints` and `tt_constraint_types` DDL definitions have significantly different column names and missing columns compared to the running migrations and models. The DDL was written during initial design and never updated as the schema evolved through migrations. Since the DDL serves as schema documentation, it must reflect the actual database state.

Key drifts in `tt_constraints`:
- `academic_term_id` should be `academic_session_id`
- `applicable_days` should be `applies_to_days_json`
- `apply_for_all_days` column does not exist in migration — should be removed
- Missing columns: `status`, `uuid`, `timetable_type_id`, `applicable_periods_json`, `applies_to_terms_json`

Key drifts in `tt_constraint_types`:
- `is_hard_constraint` should be `is_hard_capable`
- `param_schema` should be `parameter_schema`
- `applicable_to` should be `applicable_target_types`
- `target_id_required` does not exist in migration — should be removed
- Missing columns: `is_soft_capable`, `constraint_level`

---

## PRE-READ (Mandatory)

1. `{DDL_FILE}` — read the `tt_constraints` and `tt_constraint_types` CREATE TABLE statements (note: after P2_09 these will be plural names)
2. `{LARAVEL_REPO}/database/migrations/tenant/` — search for migrations that create or modify `tt_constraints` and `tt_constraint_types`
3. `{MODULE_PATH}/app/Models/Constraint.php` — confirm `$fillable` and `$casts` for actual column names
4. `{MODULE_PATH}/app/Models/ConstraintType.php` — confirm `$fillable` and `$casts` for actual column names

---

## STEPS

### Step 1: Update `tt_constraints` table definition

1. Rename columns:
   - `academic_term_id` → `academic_session_id`
   - `applicable_days` → `applies_to_days_json` (JSON type)
2. Remove columns that don't exist in migration:
   - `apply_for_all_days`
3. Add missing columns (place after related existing columns):
   - `uuid CHAR(36) NULL` — after `id`
   - `timetable_type_id INT UNSIGNED NULL` — after `timetable_id`, with FK to `tt_timetable_types`
   - `status ENUM('active','inactive','draft') NOT NULL DEFAULT 'active'` — after `is_hard`
   - `applicable_periods_json JSON NULL` — after `applies_to_days_json`
   - `applies_to_terms_json JSON NULL` — after `applicable_periods_json`
4. Update any INDEX or FK references to use the new column names

### Step 2: Update `tt_constraint_types` table definition

1. Rename columns:
   - `is_hard_constraint` → `is_hard_capable`
   - `param_schema` → `parameter_schema`
   - `applicable_to` → `applicable_target_types`
2. Remove columns that don't exist in migration:
   - `target_id_required`
3. Add missing columns:
   - `is_soft_capable TINYINT(1) NOT NULL DEFAULT 1` — after `is_hard_capable`
   - `constraint_level ENUM('hard','soft','configurable') NOT NULL DEFAULT 'configurable'` — after `is_soft_capable`
4. Update any INDEX or FK references to use the new column names

### Step 3: Cross-reference validation

1. Compare the updated DDL columns against the migration columns — every migration column should now have a DDL counterpart
2. Compare against the model `$fillable` — every fillable field should map to a DDL column
3. Verify FK references point to correct (now-plural) table names

---

## ACCEPTANCE CRITERIA

- `tt_constraints` DDL definition matches migration columns exactly (names, types, defaults)
- `tt_constraint_types` DDL definition matches migration columns exactly
- No orphaned columns remain in DDL that don't exist in migrations
- All FK and INDEX references use correct column and table names
- DDL remains valid SQL syntax

---

## DO NOT

- Do NOT change any code files (models, controllers, services)
- Do NOT create or modify any migrations — this is DDL-only
- Do NOT change columns in other tables — only `tt_constraints` and `tt_constraint_types`
- Do NOT modify the column order arbitrarily — place new columns logically near related fields
