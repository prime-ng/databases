# Tenancy Rules — MANDATORY

## Database Context Rules

1. **NEVER query tenant-scoped models from a central context without initializing tenancy first.**
   ```php
   // WRONG — will query central DB
   $students = Student::all();

   // CORRECT — initialize tenant first
   $tenant = Tenant::find($tenantId);
   tenancy()->initialize($tenant);
   $students = Student::all();
   ```

2. **NEVER query central models from inside a tenant context without switching back.**
   ```php
   // WRONG — inside tenant context, this queries tenant DB
   $plans = Plan::all();

   // CORRECT — temporarily switch to central
   $plans = tenancy()->central(function () {
       return Plan::all();
   });
   ```

3. **ALWAYS use the correct migration path:**
   - Central migrations: `database/migrations/`
   - Tenant migrations: `database/migrations/tenant/`
   - Module migrations: Use `php artisan module:make-migration MigrationName ModuleName`

4. **ALWAYS use `tenancy()->initialize($tenant)` or `$tenant->run()` when running tenant-scoped operations from central context.**

5. **NEVER hardcode tenant IDs.** Always resolve from current tenancy context:
   ```php
   // WRONG
   $tenantId = 'abc-123';

   // CORRECT
   $tenantId = tenant('id');
   // or
   $tenant = tenant();
   ```

6. **ALWAYS use tenant-aware queues when dispatching jobs that involve tenant data:**
   ```php
   // The QueueTenancyBootstrapper handles this automatically,
   // but always dispatch from within tenant context
   dispatch(new ProcessStudentReport($studentId));
   ```

## Route Rules

7. **Central routes go in `routes/web.php`** — These run on the central domain with no tenant context.

8. **Tenant routes go in `routes/tenant.php`** — These run with tenancy middleware and full tenant context.

9. **Module routes** — Place in `Modules/{Module}/routes/web.php` or `api.php`. These are loaded within the tenant route group.

10. **NEVER register tenant routes without tenancy middleware.** The middleware stack must include `InitializeTenancyByDomain` or equivalent.

## Migration Rules

11. **Creating a new tenant migration:**
    ```bash
    # Option A: Direct file in tenant migrations
    php artisan make:migration create_new_table --path=database/migrations/tenant

    # Option B: Module migration (recommended)
    php artisan module:make-migration create_new_table ModuleName
    ```

12. **Creating a new central migration:**
    ```bash
    php artisan make:migration create_new_table
    ```

13. **Running tenant migrations:**
    ```bash
    php artisan tenants:migrate
    php artisan tenants:migrate --tenants=tenant-uuid  # specific tenant
    ```

14. **Running central migrations:**
    ```bash
    php artisan migrate
    ```

## Testing Rules

15. **Always test both central and tenant contexts** when touching shared code (User model, auth, etc.).

16. **Use `$tenant->run()` in tests** to ensure tenant context:
    ```php
    $tenant->run(function () {
        // assertions here run in tenant context
    });
    ```

## Storage Rules

17. **Tenant files must be stored in tenant-specific paths.** The FilesystemTenancyBootstrapper handles this automatically via prefixing.

18. **Use `tenant_asset()` for tenant-specific asset URLs**, not `asset()`.

## Common Pitfalls

- Forgetting to end tenancy after initialization: Always use `tenancy()->end()` or `$tenant->run()`.
- Caching central data inside tenant context: Cache keys get tenant-prefixed, causing misses.
- Running `php artisan migrate` instead of `php artisan tenants:migrate` for tenant tables.
- Querying `sys_users` without knowing which DB you're connected to (exists in both central and tenant).
