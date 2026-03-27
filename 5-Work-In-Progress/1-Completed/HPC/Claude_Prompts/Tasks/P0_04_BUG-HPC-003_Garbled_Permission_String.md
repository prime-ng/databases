# PROMPT: Fix Garbled Permission String in HpcTemplatesController — HPC Module
**Task ID:** P0_04
**Issue IDs:** BUG-HPC-003
**Priority:** P0-Critical
**Estimated Effort:** 5 minutes
**Prerequisites:** None — this is a P0 task, do it first

---

## CONFIGURATION
```
LARAVEL_REPO   = /Users/bkwork/Herd/prime_ai
MODULE_PATH    = {LARAVEL_REPO}/Modules/Hpc
```

---

## CONTEXT

`HpcTemplatesController::show()` (line ~97) contains a garbled permission string: `tenant.hpc-templates.viHpcTemplatesRequest ew`. This always throws 403 Forbidden, making the template detail view permanently broken. The correct string should be `tenant.hpc-templates.view`.

---

## PRE-READ (Mandatory)

1. `{MODULE_PATH}/app/Http/Controllers/HpcTemplatesController.php`

---

## STEPS

1. Open HpcTemplatesController.php
2. Find the `show()` method (around line 97)
3. Replace the garbled permission string `tenant.hpc-templates.viHpcTemplatesRequest ew` with `tenant.hpc-templates.view`
4. Search the entire file for any other garbled or unusual permission strings

---

## ACCEPTANCE CRITERIA

- `show()` method uses `tenant.hpc-templates.view` as permission string
- No other garbled permission strings exist in the file
- File parses without syntax errors

---

## DO NOT

- Do NOT change any other methods in this controller
- Do NOT refactor the authorization pattern
