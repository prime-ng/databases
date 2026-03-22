# PROMPT: Fix Constraint Model Fillable — Non-Existent Columns — SmartTimetable DDL Gap Fix
**Task ID:** P1_06
**Issue IDs:** BUG-DDL-006
**Priority:** P1-High
**Estimated Effort:** 30 minutes
**Prerequisites:** All P0 tasks completed

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

The `Constraint` model has `apply_for_all_days` in its `$fillable` array, but this column does not exist in any migration or the DDL. Mass-assignment silently drops the value — any form submission that sets `apply_for_all_days` loses the data without error.

The `ConstraintType` model has `conflict_detection_logic`, `validation_logic`, and `resolution_priority` in its `$fillable` array. None of these columns exist in the `tt_constraint_types` migration or DDL. These are future-feature placeholders that were added prematurely.

Both models will silently discard values for these non-existent columns during `create()` or `update()` calls, which can lead to confusing bugs where data appears to save but is actually lost.

---

## PRE-READ (Mandatory)

1. `{MODULE_PATH}/app/Models/Constraint.php` — check `$fillable` and `$table`
2. `{MODULE_PATH}/app/Models/ConstraintType.php` — check `$fillable` and `$table`
3. `{LARAVEL_REPO}/database/migrations/tenant/` — search for `tt_constraints` and `tt_constraint_types` to confirm actual columns
4. Search for `apply_for_all_days` usage across SmartTimetable controllers/services
5. Search for `conflict_detection_logic`, `validation_logic`, `resolution_priority` usage across SmartTimetable controllers/services

---

## STEPS

1. Open `{MODULE_PATH}/app/Models/Constraint.php`
2. Check whether `apply_for_all_days` is used anywhere in controllers or services:
   - If it IS used in active code: create a migration to add the column `apply_for_all_days TINYINT(1) DEFAULT 0` to `tt_constraints`
   - If it is NOT used: remove `'apply_for_all_days'` from the `$fillable` array
3. Open `{MODULE_PATH}/app/Models/ConstraintType.php`
4. Remove `'conflict_detection_logic'`, `'validation_logic'`, and `'resolution_priority'` from the `$fillable` array
5. Add a TODO comment above the `$fillable` array in ConstraintType:
   ```php
   // TODO Phase-2: Add conflict_detection_logic (TEXT), validation_logic (TEXT),
   //              resolution_priority (INT) columns via migration when implementing
   //              automated constraint conflict resolution.
   ```
6. Run `php -l` on both modified model files to confirm no syntax errors
7. Search the entire SmartTimetable module for any other references to the removed fillable fields and update or annotate as needed

---

## ACCEPTANCE CRITERIA

- No `$fillable` entries reference non-existent columns in either `Constraint` or `ConstraintType` models
- If `apply_for_all_days` was needed, a migration exists and the column is in the database
- If `apply_for_all_days` was not needed, it is removed from `$fillable`
- `conflict_detection_logic`, `validation_logic`, `resolution_priority` removed from `ConstraintType::$fillable` with TODO comment
- All constraint CRUD operations (create, update) save data correctly without silent data loss
- `php -l` passes on both modified files

---

## DO NOT

- Do NOT change existing columns in any migration
- Do NOT modify controller logic or service classes
- Do NOT touch `ConstraintCategory`, `ConstraintScope`, or other constraint-adjacent models
- Do NOT remove columns from migrations — additive-only policy
- Do NOT add the future ConstraintType columns via migration — they are Phase-2
