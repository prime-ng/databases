# PROMPT: Extract Shared Index Query to Service/Trait — HPC Module
**Task ID:** P1_17
**Issue IDs:** PERF-HPC-002
**Priority:** P1-High
**Estimated Effort:** 2 hours
**Prerequisites:** None

---

## CONFIGURATION
```
MODULE_PATH    = /Users/bkwork/Herd/prime_ai/Modules/Hpc
```

---

## CONTEXT

All 15 HPC controllers contain a near-identical ~70-line block in their `index()` method that queries 10+ models to populate a shared tabbed index page. This fires ~15 queries per request for data that the active tab may not even display. The block is duplicated 15 times — any change requires editing 15 files.

---

## PRE-READ (Mandatory)

1. `{MODULE_PATH}/app/Http/Controllers/HpcController.php` — Read `index()` method
2. `{MODULE_PATH}/app/Http/Controllers/CircularGoalsController.php` — Read `index()` to see the duplicated pattern
3. Read 1-2 more controllers to confirm the pattern is consistent

---

## STEPS

1. Identify the common query block that appears in all 15 controllers' `index()` methods
2. Create a new trait `{MODULE_PATH}/app/Http/Controllers/Traits/HpcIndexDataTrait.php` (or a service `HpcIndexDataService.php`)
3. Extract the shared query block into a method like `getHpcIndexData()` that returns the view data array
4. Replace the duplicated block in all 15 controllers with a call to the shared method
5. Consider making tab data lazy-loadable (return empty collections for non-active tabs) — but this is optional for this task

---

## ACCEPTANCE CRITERIA

- Common index query logic exists in exactly ONE place (trait or service)
- All 15 controllers use the shared method
- Index pages load correctly with all tab data
- Zero duplicated query blocks across controllers

---

## DO NOT

- Do NOT change what data is loaded (maintain backward compatibility)
- Do NOT implement AJAX tab loading in this task (that's a future enhancement)
- Do NOT modify blade views
