# PROMPT: Add EnsureTenantHasModule Middleware to HPC Routes — HPC Module
**Task ID:** P0_05
**Issue IDs:** SEC-HPC-003
**Priority:** P0-Critical
**Estimated Effort:** 30 minutes
**Prerequisites:** None — this is a P0 task, do it first

---

## CONFIGURATION
```
LARAVEL_REPO   = /Users/bkwork/Herd/prime_ai
ROUTES_FILE    = {LARAVEL_REPO}/routes/tenant.php
```

---

## CONTEXT

The HPC route group in `tenant.php` (around line 2498) does not use the `EnsureTenantHasModule` middleware. This means any authenticated tenant user can access HPC features even if their school's subscription plan does not include the HPC module. Across the entire 2715-line tenant.php, only 1 instance of `EnsureTenantHasModule` exists for a different module.

---

## PRE-READ (Mandatory)

1. `{ROUTES_FILE}` — Find the HPC route group (search for `/hpc/` routes, around line 2498)
2. Search for existing `EnsureTenantHasModule` usage elsewhere in tenant.php to match the pattern

---

## STEPS

1. Read tenant.php and locate the HPC route group
2. Find how `EnsureTenantHasModule` is used elsewhere in the file (the one existing usage)
3. Add `EnsureTenantHasModule::class.':Hpc'` to the HPC route group middleware array
4. Ensure the `use App\Http\Middleware\EnsureTenantHasModule;` import exists at the top of the file (add if missing)

---

## ACCEPTANCE CRITERIA

- HPC route group has `EnsureTenantHasModule` middleware with `Hpc` module parameter
- Import statement is present at top of tenant.php
- `php artisan route:cache` runs without errors
- Tenants without HPC module in their plan get 403 when accessing /hpc/* routes

---

## DO NOT

- Do NOT add EnsureTenantHasModule to other module route groups in this task
- Do NOT modify the middleware class itself
- Do NOT change any route definitions — only add middleware
