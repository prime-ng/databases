# Tenancy Architecture Map

## Package Details
- **Package:** stancl/tenancy v3.9
- **Laravel:** 12.0
- **Config:** `config/tenancy.php`

## Tenancy Strategy
- **Type:** Database-per-tenant isolation
- **ID Generator:** `Stancl\Tenancy\UUIDGenerator` (UUID primary keys for tenants)
- **Identification:** Domain-based (`InitializeTenancyByDomain` middleware)
- **Central Connection:** `central` (env `TENANCY_CENTRAL_CONNECTION`)
- **DB Prefix:** `tenant_` (each tenant gets `tenant_{uuid}` database)

## Bootstrappers (Active)
1. `DatabaseTenancyBootstrapper` — Switches DB connection to tenant DB
2. `CacheTenancyBootstrapper` — Prefixes cache keys with `tenant_`
3. `FilesystemTenancyBootstrapper` — Prefixes storage paths with tenant ID
4. `QueueTenancyBootstrapper` — Ensures queued jobs run in tenant context

## Tenant Model
- **Class:** `Modules\Prime\Models\Tenant`
- **Table:** `prm_tenant`
- **Extends:** `Stancl\Tenancy\Database\Models\Tenant` (BaseTenant)
- **Implements:** `TenantWithDatabase`, `HasMedia`
- **Traits:** `HasDatabase`, `HasDomains`, `SoftDeletes`, `InteractsWithMedia`
- **Key Fields:** id (UUID), tenant_group_id, code, short_name, name, udise_code, affiliation_no, email, website_url, address fields, locale, currency, established_date, is_active

## Domain Model
- **Class:** `Modules\Prime\Models\Domain`
- **Table:** `prm_tenant_domains`
- **Extends:** `Stancl\Tenancy\Database\Models\Domain` (BaseDomain)

## Central Models (System DB — prime_db + global_db)
These models are NEVER tenant-scoped:
- `Modules\Prime\Models\Tenant`
- `Modules\Prime\Models\Domain`
- `Modules\Prime\Models\TenantGroup`
- `Modules\Prime\Models\TenantPlan`
- `Modules\Prime\Models\TenantPlanRate`
- `Modules\Prime\Models\TenantPlanModule`
- `Modules\Prime\Models\TenantInvoice`
- `Modules\GlobalMaster\Models\Country`, `State`, `City`, `District`
- `Modules\GlobalMaster\Models\Board`, `Plan`, `Module`
- `Modules\Prime\Models\Setting`, `Menu`, `MenuModule`
- `Modules\Prime\Models\Role`, `Permission` (central RBAC)

## Tenant-Scoped Models (Tenant DB)
Everything inside these modules is tenant-scoped:
- `SchoolSetup\Models\*` — Organization, SchoolClass, Section, Subject, Teacher, Room, etc.
- `SmartTimetable\Models\*` — Activity, Timetable, Constraint, etc.
- `StudentProfile\Models\*` — Student, Guardian, Attendance, etc.
- `StudentFee\Models\*` — FeeHeadMaster, FeeInvoice, FeeReceipt, etc.
- `Transport\Models\*` — Vehicle, Route, Trip, etc.
- `Syllabus\Models\*` — Lesson, Topic, Competency, etc.
- `QuestionBank\Models\*` — Question, Tag, Version, etc.
- `Notification\Models\*` — Channel, Template, Delivery, etc.
- `Vendor\Models\*` — Vendor, Agreement, Invoice, etc.
- `Complaint\Models\*` — Complaint, Category, Action, etc.
- `Hpc\Models\*` — LearningOutcome, Evaluation, etc.
- `Recommendation\Models\*` — Rule, Material, StudentRecommendation, etc.
- `App\Models\User` — `sys_users` table (exists in both central and tenant DBs)

## Tenancy Service Provider
- **Location:** `app/Providers/TenancyServiceProvider.php`
- **Tenant Creation Pipeline:** Currently only `CreateDatabase` is active
  - Commented out: `MigrateDatabase`, `CreateRootUser`, `AddOrganizationDetails`, `SeedDatabase`
- **Events:** Full lifecycle events registered (Creating, Created, Saving, Saved, Updating, Updated, Deleting, Deleted)

## How to Initialize Tenancy in Code
```php
// Option 1: Initialize for a specific tenant
$tenant = Tenant::find($tenantId);
tenancy()->initialize($tenant);
// ... tenant-scoped code here ...
tenancy()->end();

// Option 2: Run closure in tenant context
$tenant->run(function () {
    // All queries here go to tenant DB
    $students = Student::all();
});
```

## Tenant Migrations
- **Path:** `database/migrations/tenant/` (216 files)
- **Run command:** `php artisan tenants:migrate`
- **Rollback:** `php artisan tenants:migrate --rollback`
- **Seed:** `php artisan tenants:seed`
- **Seeder class:** `TenantDatabaseSeeder`

## Central Migrations
- **Path:** `database/migrations/` (6 files)
- **Run command:** `php artisan migrate`

## Route Separation
- **Central routes:** `routes/web.php` — Runs on APP_DOMAIN, no tenant context
- **Tenant routes:** `routes/tenant.php` — Runs with tenancy middleware, full tenant context
- **Auth routes:** `routes/auth.php` — Authentication (tenant-scoped)
- **API routes:** `routes/api.php` — Minimal, Sanctum-protected

## Middleware Priority
```
PreventAccessFromCentralDomains
InitializeTenancyByDomain
InitializeTenancyBySubdomain
InitializeTenancyByDomainOrSubdomain
InitializeTenancyByPath
InitializeTenancyByRequestData
```

## Storage
- Tenant-aware filesystem: `storage/tenant_{uuid}/`
- Each tenant gets isolated local and public disk paths
- Use `tenant_asset()` for tenant-specific asset URLs
