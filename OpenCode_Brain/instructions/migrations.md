> **Applies to:** database/migrations/**
> OpenCode has no path-scoped auto-load. Read this file before working on those paths, or load the matching skill from `.opencode/skills/`.

# Migration Rules

## Two Migration Paths
- **Central:** `database/migrations/` → `php artisan migrate`
- **Tenant:** `database/migrations/tenant/` → `php artisan tenants:migrate`

## Critical Rules
1. **NEVER modify existing migrations.** Always create new additive migrations.
2. **Tenant migrations go in `database/migrations/tenant/`** — not in module directories
3. **Table naming:** Use prefix convention (`tt_*`, `std_*`, `sch_*`, etc.)
4. **Required columns on ALL tables:** `id`, `is_active`, `created_by`, `created_at`, `updated_at`, `deleted_at`
5. **Index ALL foreign keys** and frequently queried columns
6. **Junction tables:** suffix with `_jnt`
7. **JSON columns:** suffix with `_json`
8. **Boolean columns:** prefix with `is_` or `has_`

## Commands
```bash
php artisan make:migration create_table --path=database/migrations/tenant  # Tenant
php artisan make:migration create_table                                     # Central
php artisan tenants:migrate                                                 # Run tenant
php artisan tenants:migrate --tenants=uuid                                  # Specific tenant
```

## Schema Reference (resolve via config/paths.md)
- DEV (AI work, v4): `{DEV_GLOBAL_DDL}`, `{DEV_PRIME_DDL}`, `{DEV_TENANT_DDL}`
- Production (app, v3): `{GLOBAL_DDL}`, `{PRIME_DDL}`, `{TENANT_DDL}`
- NEVER reference `*_Old*` files or files from subfolders
