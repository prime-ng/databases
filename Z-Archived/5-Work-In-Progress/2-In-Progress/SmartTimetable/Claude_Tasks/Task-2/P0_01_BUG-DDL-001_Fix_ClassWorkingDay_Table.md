# PROMPT: Fix ClassWorkingDay Model Table Name — SmartTimetable DDL Gap Fix
**Task ID:** P0_01
**Issue IDs:** BUG-DDL-001
**Priority:** P0-Critical
**Estimated Effort:** 5 minutes
**Prerequisites:** None — this is a P0 task, do it first

---

## CONFIGURATION
```
LARAVEL_REPO   = /Users/bkwork/Herd/prime_ai_tarun
MODULE_PATH    = {LARAVEL_REPO}/Modules/SmartTimetable
BRANCH         = Brijesh_SmartTimetable
```

---

## CONTEXT

The `ClassWorkingDay` model has `$table = 'tt_class_working_day_jnt'` but the migration creates the table as `tt_class_working_days`. The DDL also uses `tt_class_working_day_jnt` but the DDL is a design doc — the migration is the source of truth. Any query on this model will crash with "Base table or view not found: 1146 Table 'tenant_db.tt_class_working_day_jnt' doesn't exist".

See `05_Real_Bugs_Found.md` — BUG-DDL-001.

---

## PRE-READ (Mandatory)

1. `{MODULE_PATH}/app/Models/ClassWorkingDay.php` — the model to fix
2. `{LARAVEL_REPO}/database/migrations/tenant/` — search for `tt_class_working` to confirm actual table name

---

## STEPS

1. Open `{MODULE_PATH}/app/Models/ClassWorkingDay.php`
2. Find the line: `protected $table = 'tt_class_working_day_jnt';`
3. Change it to: `protected $table = 'tt_class_working_days';`
4. Search the entire SmartTimetable module for any other references to `tt_class_working_day_jnt` and update them to `tt_class_working_days`
5. Run `php -l {MODULE_PATH}/app/Models/ClassWorkingDay.php` to confirm no syntax errors

---

## ACCEPTANCE CRITERIA

- `ClassWorkingDay::first()` executes without "table not found" error
- No references to `tt_class_working_day_jnt` remain in the SmartTimetable module
- `php -l` passes on the modified file

---

## DO NOT

- Do NOT create any migrations — this is a model-only fix
- Do NOT rename the actual database table
- Do NOT modify any other models in this task
- Do NOT change the DDL file
