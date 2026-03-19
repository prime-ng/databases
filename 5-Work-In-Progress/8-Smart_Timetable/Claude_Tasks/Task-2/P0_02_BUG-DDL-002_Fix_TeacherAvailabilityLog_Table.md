# PROMPT: Fix TeacherAvailabilityLog Model Table Name — SmartTimetable DDL Gap Fix
**Task ID:** P0_02
**Issue IDs:** BUG-DDL-002
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

Three different names exist for the same concept:
- **DDL:** `tt_teacher_availability_detail` (singular)
- **Migration:** `tt_teacher_availability_logs` (plural, different word)
- **Model:** `$table = 'tt_teacher_availability_details'` (plural, yet another name)

The model queries `tt_teacher_availability_details` which does NOT exist. The migration created `tt_teacher_availability_logs`. Any query will crash with "table not found".

See `05_Real_Bugs_Found.md` — BUG-DDL-002.

---

## PRE-READ (Mandatory)

1. `{MODULE_PATH}/app/Models/TeacherAvailabilityLog.php` — the model to fix
2. `{LARAVEL_REPO}/database/migrations/tenant/` — search for `teacher_availability_log` to confirm actual table name

---

## STEPS

1. Open `{MODULE_PATH}/app/Models/TeacherAvailabilityLog.php`
2. Find the line: `protected $table = 'tt_teacher_availability_details';`
3. Change it to: `protected $table = 'tt_teacher_availability_logs';`
4. Search the entire SmartTimetable module for any other references to `tt_teacher_availability_details` and update them to `tt_teacher_availability_logs`
5. Run `php -l {MODULE_PATH}/app/Models/TeacherAvailabilityLog.php` to confirm no syntax errors

---

## ACCEPTANCE CRITERIA

- `TeacherAvailabilityLog::first()` executes without "table not found" error
- No references to `tt_teacher_availability_details` remain in the SmartTimetable module
- `php -l` passes on the modified file

---

## DO NOT

- Do NOT create any migrations — this is a model-only fix
- Do NOT rename the actual database table
- Do NOT modify any other models in this task
- Do NOT change the DDL file
