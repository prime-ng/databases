# PROMPT: Replace Cross-Layer Dropdown Import — HPC Module
**Task ID:** P1_15
**Issue IDs:** BUG-HPC-012
**Priority:** P1-High
**Estimated Effort:** 30 minutes
**Prerequisites:** None

---

## CONFIGURATION
```
MODULE_PATH    = /Users/bkwork/Herd/prime_ai/Modules/Hpc
```

---

## CONTEXT

`LearningOutcomesController` imports `Modules\Prime\Models\Dropdown` — a central/prime DB model — in tenant context. This is a cross-layer violation. The controller should use the tenant-scoped dropdown table (`sys_dropdown_table`) via `Modules\SystemConfig\Models\Dropdown` or equivalent.

---

## PRE-READ (Mandatory)

1. `{MODULE_PATH}/app/Http/Controllers/LearningOutcomesController.php`
2. Search for tenant-scoped dropdown model: find files matching `*Dropdown*` in `Modules/SystemConfig/app/Models/` or `Modules/SchoolSetup/app/Models/`

---

## STEPS

1. Find the `use Modules\Prime\Models\Dropdown;` import
2. Identify where `Dropdown` is used in the controller (likely populating a dropdown in create/edit views)
3. Replace with the tenant-scoped equivalent model
4. If no tenant Dropdown model exists, use `DB::table('sys_dropdown_table')->where(...)` or query via `tenancy()->central(fn() => Dropdown::where(...)->get())`

---

## ACCEPTANCE CRITERIA

- No `Modules\Prime\Models\Dropdown` import in any HPC controller
- Dropdown data still loads correctly in the view
- Data comes from tenant-scoped source

---

## DO NOT

- Do NOT modify the Prime Dropdown model
- Do NOT create new models unless absolutely necessary
