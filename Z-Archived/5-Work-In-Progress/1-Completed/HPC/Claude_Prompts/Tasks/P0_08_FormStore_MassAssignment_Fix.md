# PROMPT: Fix Mass Assignment in formStore() — HPC Module
**Task ID:** P0_08
**Issue IDs:** SEC-HPC-001 (partial)
**Priority:** P0-Critical
**Estimated Effort:** 1 hour
**Prerequisites:** None — this is a P0 task, do it first

---

## CONFIGURATION
```
LARAVEL_REPO   = /Users/bkwork/Herd/prime_ai
MODULE_PATH    = {LARAVEL_REPO}/Modules/Hpc
```

---

## CONTEXT

`HpcController::formStore()` (around line 823) uses `$request->all()` to save form data, creating a mass assignment surface. While HPC form data is stored as JSON key-value pairs (not directly mapped to model columns), `$request->all()` can include unexpected fields like `_token`, `_method`, or attacker-injected fields. The method should use explicit field extraction or `$request->only()` to accept only expected form fields.

---

## PRE-READ (Mandatory)

1. `{MODULE_PATH}/app/Http/Controllers/HpcController.php` — Read the `formStore()` method (around line 800-850)

---

## STEPS

1. Read the `formStore()` method to understand what fields it expects
2. Identify the inline `validate()` call to see what fields are declared
3. Replace `$request->all()` with `$request->only([...])` listing only the validated/expected fields, OR use `$request->validated()` if inline validation covers all needed fields
4. If the method uses `$request->all()` in multiple places, fix each occurrence
5. Also check if `$request->except(['_token', '_method'])` would be more appropriate given the dynamic nature of HPC form fields

---

## ACCEPTANCE CRITERIA

- `$request->all()` no longer used in `formStore()`
- Only expected form fields are processed
- Form save/load still works correctly for all 4 templates
- No regression in PDF generation that depends on saved form data

---

## DO NOT

- Do NOT create a new FormRequest for formStore() in this task (that's a larger refactor)
- Do NOT change the form data storage format
- Do NOT modify the blade form templates
- Do NOT refactor the entire formStore() method — just fix the mass assignment
