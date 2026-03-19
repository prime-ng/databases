---
globs: ["database/migrations/**"]
---

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

## Schema Reference (v2 files ONLY)
- `global_db_v2.sql`, `prime_db_v2.sql`, `tenant_db_v2.sql` in `{DDL_DIR}/`
- NEVER reference non-v2 files or files from subfolders
