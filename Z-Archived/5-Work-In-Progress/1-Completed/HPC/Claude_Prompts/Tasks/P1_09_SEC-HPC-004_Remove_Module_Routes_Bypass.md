# PROMPT: Remove Module Routes That Bypass Tenancy — HPC Module
**Task ID:** P1_09
**Issue IDs:** SEC-HPC-004
**Priority:** P1-High
**Estimated Effort:** 30 minutes
**Prerequisites:** P0 complete

---

## CONFIGURATION
```
LARAVEL_REPO   = /Users/bkwork/Herd/prime_ai
MODULE_PATH    = {LARAVEL_REPO}/Modules/Hpc
```

---

## CONTEXT

The HPC module's own `Modules/Hpc/routes/web.php` and `Modules/Hpc/routes/api.php` register routes (e.g., `Route::resource('hpcs', HpcController::class)`) that are accessible on the central domain. These bypass all tenancy middleware (InitializeTenancyByDomain, PreventAccessFromCentralDomains, EnsureTenantIsActive). All HPC routes must be in `routes/tenant.php` only.

---

## PRE-READ (Mandatory)

1. `{MODULE_PATH}/routes/web.php`
2. `{MODULE_PATH}/routes/api.php`

---

## STEPS

1. Read `{MODULE_PATH}/routes/web.php` — identify all route registrations
2. Read `{MODULE_PATH}/routes/api.php` — identify all route registrations
3. Empty both files (keep the `<?php` tag and a comment explaining routes are in tenant.php):
   ```php
   <?php
   // All HPC routes are registered in routes/tenant.php with tenancy middleware.
   // Do NOT add routes here — they bypass tenant isolation.
   ```
4. Verify the corresponding routes already exist in `routes/tenant.php` (they do — the gap analysis confirmed 89 route references)

---

## ACCEPTANCE CRITERIA

- `Modules/Hpc/routes/web.php` contains no `Route::` calls
- `Modules/Hpc/routes/api.php` contains no `Route::` calls
- All HPC functionality still works via tenant.php routes
- `php artisan route:list --path=hpc` shows only tenant-scoped routes

---

## DO NOT

- Do NOT remove the route files entirely — keep them with comments
- Do NOT modify routes/tenant.php
- Do NOT change the module's RouteServiceProvider
