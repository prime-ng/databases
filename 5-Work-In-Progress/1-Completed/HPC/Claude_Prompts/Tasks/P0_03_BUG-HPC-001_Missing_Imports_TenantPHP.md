# PROMPT: Add 4 Missing Template Controller Imports — HPC Module
**Task ID:** P0_03
**Issue IDs:** BUG-HPC-001
**Priority:** P0-Critical
**Estimated Effort:** 15 minutes
**Prerequisites:** None — this is a P0 task, do it first

---

## CONFIGURATION
```
LARAVEL_REPO   = /Users/bkwork/Herd/prime_ai
ROUTES_FILE    = {LARAVEL_REPO}/routes/tenant.php
```

---

## CONTEXT

Four HPC template controller classes have routes registered in `tenant.php` (for `hpc-templates`, `hpc-template-parts`, `hpc-template-sections`, `hpc-template-rubrics` resources) but the controller classes are NOT imported via `use` statements. All 4 resource routes return HTTP 500 "Class not found" when accessed. The controller files exist in the module — only the imports are missing.

---

## PRE-READ (Mandatory)

1. `{ROUTES_FILE}` — Search for `hpc-templates` to find the route definitions and the existing `use` import block at the top

---

## STEPS

1. Open `{ROUTES_FILE}` and locate the `use` import section at the top of the file
2. Add these 4 imports (verify exact class names match files in `Modules/Hpc/app/Http/Controllers/`):
   ```
   use Modules\Hpc\Http\Controllers\HpcTemplatesController;
   use Modules\Hpc\Http\Controllers\HpcTemplatePartsController;
   use Modules\Hpc\Http\Controllers\HpcTemplateSectionsController;
   use Modules\Hpc\Http\Controllers\HpcTemplateRubricsController;
   ```
3. Verify by running `php artisan route:cache` — should complete without errors

---

## ACCEPTANCE CRITERIA

- All 4 `use` statements added to tenant.php
- `php artisan route:cache` runs without "Class not found" errors
- Routes for `hpc-templates`, `hpc-template-parts`, `hpc-template-sections`, `hpc-template-rubrics` are accessible

---

## DO NOT

- Do NOT modify any route definitions — only add imports
- Do NOT remove any existing imports
- Do NOT modify any controller files
