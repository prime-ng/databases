# Agent: Database Architect

## Role
Database design and migration specialist for the Prime-AI 3-layer multi-tenant architecture.

## Before Designing
1. Read `.ai/memory/tenancy-map.md` — Understand the 3-layer DB architecture
2. Read `.ai/memory/project-context.md` — Review existing table counts and prefixes
3. Read `.ai/memory/conventions.md` — Naming conventions
4. Check existing schema: `/Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/1-master_dbs/1-DDL_schema/`

## First Decision: Which Database?

| Question | Answer | Database |
|----------|--------|----------|
| Is this shared reference data? | Yes | `global_db` |
| Is this SaaS management (tenants, billing, plans)? | Yes | `prime_db` |
| Is this school-specific data? | Yes | `tenant_db` |

## Migration Placement

### Central Migrations → `database/migrations/`
```bash
php artisan make:migration create_table_name
```
Used for: Session tables, cache tables, personal access tokens, media, system-level tables.

### Tenant Migrations → `database/migrations/tenant/`
```bash
php artisan make:migration create_table_name --path=database/migrations/tenant
# OR
php artisan module:make-migration create_table_name ModuleName
```
Used for: All school-specific tables (students, teachers, activities, fees, etc.)

### Running Migrations
```bash
# Central
php artisan migrate

# All tenants
php artisan tenants:migrate

# Specific tenant
php artisan tenants:migrate --tenants=tenant-uuid
```

## Table Design Rules

### Required Columns (ALL tables)
```sql
`id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
`is_active` TINYINT(1) NOT NULL DEFAULT 1,
`created_by` INT UNSIGNED DEFAULT NULL,
`created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
`updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
`deleted_at` TIMESTAMP NULL DEFAULT NULL,
PRIMARY KEY (`id`)
```

### Naming Rules
- Table: `{prefix}_{entity_plural}` (e.g., `std_students`, `tt_activities`)
- Junction: `{prefix}_{entity1}_{entity2}_jnt` (e.g., `std_student_guardian_jnt`)
- Foreign key column: `{entity_singular}_id` (e.g., `student_id`, `teacher_id`)
- Boolean: `is_` or `has_` prefix (e.g., `is_active`, `has_sub_activity`)
- JSON: `_json` suffix (e.g., `params_json`, `preferred_time_slots_json`)
- Date: `_date` suffix (e.g., `effective_from_date`)

### Index Rules
- Always index foreign keys
- Always index `is_active` (used in soft-delete scopes)
- Composite indexes for frequently combined queries
- Unique indexes where business rules require uniqueness

### Data Types
- Primary keys: `INT UNSIGNED AUTO_INCREMENT`
- Foreign keys: `INT UNSIGNED`
- Booleans: `TINYINT(1)`
- Money: `DECIMAL(12,2)` (or `DECIMAL(15,4)` for precise calculations)
- Dates: `DATE` or `TIMESTAMP`
- Short text: `VARCHAR(n)` with appropriate length
- Long text: `TEXT`
- Structured data: `JSON`
- Enums: Use `ENUM()` for fixed sets, or reference tables for dynamic sets

### Soft Deletes
- Use `$table->softDeletes()` in migration
- Use `SoftDeletes` trait on Model
- Toggle active state via `is_active` boolean
- Hard delete only via `forceDelete()`

## Schema Documentation
- Document every schema decision in `.ai/memory/decisions.md`
- Update the DDL schema files in the databases repo after significant changes:
  - `1-master_dbs/1-DDL_schema/tenant_db.sql`
  - `1-master_dbs/1-DDL_schema/prime_db.sql`
  - `1-master_dbs/1-DDL_schema/global_db.sql`

## Existing Schema Stats
- `global_db`: 12 tables
- `prime_db`: 27 tables
- `tenant_db`: 159 tables (4,219 lines of DDL)
- Total: 198 tables
