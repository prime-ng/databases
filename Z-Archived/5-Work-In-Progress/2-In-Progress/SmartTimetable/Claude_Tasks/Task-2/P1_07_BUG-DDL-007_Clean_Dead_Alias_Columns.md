# PROMPT: Document Dead Alias Columns — Tech Debt Tracking — SmartTimetable DDL Gap Fix
**Task ID:** P1_07
**Issue IDs:** BUG-DDL-007
**Priority:** P1-High
**Estimated Effort:** 15 minutes
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

The fix migration `2026_03_12_100002` added 5 alias columns to `tt_constraints` as part of a v7.6 schema mapping fix:
- `academic_term_id` (alias for `academic_session_id`)
- `effective_from_date` (alias for `effective_from`)
- `effective_to_date` (alias for `effective_to`)
- `applicable_days_json` (alias for `applies_to_days_json`)
- `target_type_id` (alias for an existing column)

Nobody reads or writes these alias columns. The Constraint model uses the original column names throughout. These dead columns add confusion for anyone reading the schema — they appear to be required fields but are always NULL. This is tech debt that should be tracked but NOT fixed by dropping columns (additive-only policy).

---

## PRE-READ (Mandatory)

1. `{LARAVEL_REPO}/database/migrations/tenant/` — find the migration file `2026_03_12_100002*` (search for `100002` in the filename)
2. `{MODULE_PATH}/app/Models/Constraint.php` — confirm which column names the model actually uses
3. `/Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/AI_Brain/lessons/known-issues.md` — existing tech debt documentation

---

## STEPS

1. Locate the fix migration file matching `2026_03_12_100002*` in `{LARAVEL_REPO}/database/migrations/tenant/`
2. Add a comment block at the top of the migration's `up()` method documenting the dead alias columns:
   ```php
   /**
    * TECH DEBT: The 5 alias columns added below (academic_term_id, effective_from_date,
    * effective_to_date, applicable_days_json, target_type_id) are dead weight.
    * The Constraint model uses the original column names (academic_session_id,
    * effective_from, effective_to, applies_to_days_json, constraint_target_type_id).
    * These aliases are never read or written. DO NOT use them in new code.
    * Tracked in AI_Brain/lessons/known-issues.md as tech debt.
    * Additive-only policy: DO NOT drop these columns.
    */
   ```
3. Open `AI_Brain/lessons/known-issues.md` at `/Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/AI_Brain/lessons/known-issues.md`
4. Add a new section documenting this tech debt:
   ```
   ## Dead Alias Columns in tt_constraints (BUG-DDL-007)
   - Migration `2026_03_12_100002` added 5 alias columns that duplicate existing columns
   - Aliases: academic_term_id, effective_from_date, effective_to_date, applicable_days_json, target_type_id
   - Originals: academic_session_id, effective_from, effective_to, applies_to_days_json, constraint_target_type_id
   - Model uses original names — aliases are always NULL
   - Resolution: Can be dropped in a future major version cleanup migration
   - Added: 2026-03-17
   ```

---

## ACCEPTANCE CRITERIA

- Migration file has a clear documentation comment block explaining the dead alias columns
- `AI_Brain/lessons/known-issues.md` has a new entry tracking BUG-DDL-007 as tech debt
- No functional code changes — documentation only
- The migration still runs without errors (comment-only change)

---

## DO NOT

- Do NOT drop any columns — additive-only policy
- Do NOT modify the `Constraint` model
- Do NOT create new migrations
- Do NOT rename any columns
- Do NOT modify any controller or service files
