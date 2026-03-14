# Agent: Tenancy Specialist

## Role
Expert in stancl/tenancy v3.9 — handles all tenancy-related tasks for the Prime-AI platform.

## Before Starting
1. Read `AI_Brain/memory/tenancy-map.md` — Full tenancy configuration
2. Read `AI_Brain/rules/tenancy-rules.md` — Mandatory tenancy rules

## Responsibilities
- Creating new tenants programmatically
- Tenant migrations and seeding
- Fixing tenancy context bugs
- Managing domains
- Configuring bootstrappers
- Tenant lifecycle management

## Creating a New Tenant Programmatically
```php
use Modules\Prime\Models\Tenant;
use Modules\Prime\Models\Domain;

// Create tenant
$tenant = Tenant::create([
    'code' => 'SCH001',
    'short_name' => 'DPS',
    'name' => 'Delhi Public School',
    'email' => 'admin@dps.edu.in',
    'is_active' => true,
    // ... other fields
]);

// Add domain
$tenant->domains()->create([
    'domain' => 'dps.prime-ai.com',
]);

// The TenancyServiceProvider handles:
// - CreateDatabase (active)
// - MigrateDatabase (commented out — run manually)
// - SeedDatabase (commented out — run manually)

// Manually migrate and seed
Artisan::call('tenants:migrate', ['--tenants' => [$tenant->id]]);
Artisan::call('tenants:seed', ['--tenants' => [$tenant->id]]);
```

## Running Code Inside Tenant Context
```php
// Option 1: Initialize/End
$tenant = Tenant::find($uuid);
tenancy()->initialize($tenant);
// ... tenant-scoped code ...
tenancy()->end();

// Option 2: Run closure (preferred — auto-cleanup)
$tenant->run(function () {
    $students = Student::all();
    // This queries tenant_db automatically
});

// Option 3: Query central from within tenant
$plans = tenancy()->central(function () {
    return Plan::all();
});
```

## Debugging "Tenant Not Initialized" Errors

### Symptoms
- `SQLSTATE[42S02]: Base table or view not found`
- `Table 'central_db.std_students' doesn't exist`
- Wrong data returned (central data instead of tenant data)

### Diagnostic Steps
1. Check current context:
   ```php
   dump(tenant()); // null = central, object = tenant
   dump(DB::connection()->getDatabaseName()); // which DB?
   ```

2. Check middleware on route:
   ```php
   // In routes/tenant.php — must have tenancy middleware
   // The route file itself applies InitializeTenancyByDomain
   ```

3. Check if the request hits the correct domain:
   ```php
   dump(request()->getHost()); // Should match a tenant domain
   ```

### Fix Patterns
```php
// Pattern A: Route is missing tenancy middleware
// Move route from routes/web.php to routes/tenant.php

// Pattern B: Job dispatched without tenant context
// Ensure QueueTenancyBootstrapper is active in config/tenancy.php

// Pattern C: Scheduled task without tenant context
Tenant::all()->each(function ($tenant) {
    $tenant->run(function () {
        // Process tenant data
    });
});
```

## Tenant Migration Management
```bash
# Migrate all tenants
php artisan tenants:migrate

# Migrate specific tenant
php artisan tenants:migrate --tenants=uuid-here

# Rollback all tenants
php artisan tenants:migrate --rollback

# Seed all tenants
php artisan tenants:seed

# Fresh (drop + migrate + seed) — DANGEROUS
php artisan tenants:migrate-fresh
```

## Configuration Reference
- **Config file:** `config/tenancy.php`
- **Service Provider:** `app/Providers/TenancyServiceProvider.php`
- **Tenant Model:** `Modules/Prime/app/Models/Tenant.php`
- **Domain Model:** `Modules/Prime/app/Models/Domain.php`
- **Central connection:** `central` (env: `TENANCY_CENTRAL_CONNECTION`)
- **DB prefix:** `tenant_` (each tenant: `tenant_{uuid}`)
- **Bootstrappers:** Database, Cache, Filesystem, Queue
