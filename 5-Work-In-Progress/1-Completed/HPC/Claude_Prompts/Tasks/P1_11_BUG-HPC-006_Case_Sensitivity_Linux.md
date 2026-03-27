# PROMPT: Fix Case-Sensitivity Issues for Linux Deployment — HPC Module
**Task ID:** P1_11
**Issue IDs:** BUG-HPC-006
**Priority:** P1-High
**Estimated Effort:** 30 minutes
**Prerequisites:** None

---

## CONFIGURATION
```
LARAVEL_REPO   = /Users/bkwork/Herd/prime_ai
MODULE_PATH    = {LARAVEL_REPO}/Modules/Hpc
```

---

## CONTEXT

`HpcTemplates` model references relationship classes using uppercase `HPC` prefix (`HPCTemplateSections`, `HPCTemplateRubrics`, `HPCTemplateRubricItems`) but the actual class files use `Hpc` prefix (`HpcTemplateSections`, `HpcTemplateRubrics`, `HpcTemplateRubricItems`). This works on macOS (case-insensitive filesystem) but breaks on Linux (case-sensitive), causing `Class not found` errors in production.

---

## PRE-READ (Mandatory)

1. `{MODULE_PATH}/app/Models/HpcTemplates.php` — Find all relationship definitions
2. Verify actual filenames: `ls {MODULE_PATH}/app/Models/HpcTemplate*`

---

## STEPS

1. Open `{MODULE_PATH}/app/Models/HpcTemplates.php`
2. Find all relationship methods that reference `HPCTemplateSections`, `HPCTemplateRubrics`, `HPCTemplateRubricItems`
3. Replace with correct case: `HpcTemplateSections`, `HpcTemplateRubrics`, `HpcTemplateRubricItems`
4. Also check `use` import statements at the top of the file for the same issue
5. Search all other HPC models for any uppercase `HPC` references: `grep -r "HPC[A-Z]" {MODULE_PATH}/app/Models/`

---

## ACCEPTANCE CRITERIA

- Zero uppercase `HPC` class references in any model file (should be `Hpc`)
- All relationship methods reference correct class names
- `php artisan tinker` → `(new HpcTemplates)->sections` loads without error

---

## DO NOT

- Do NOT rename model files or classes — only fix references TO them
- Do NOT change table names or database schema
