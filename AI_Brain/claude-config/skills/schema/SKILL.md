---
name: schema
description: Generate or validate database schema for a module
user_invocable: true
---

# /schema — Database Schema Work

Generate DDL, migrations, and models for a module, or validate schema-model alignment.

## Usage
- `/schema ModuleName` — Generate schema for a new module
- `/schema validate ModuleName` — Validate schema-model alignment
- `/schema migrate ModuleName` — Generate a new migration

## Steps

1. Read canonical DDL files (v2 ONLY):
   - `{GLOBAL_DDL}`
   - `{PRIME_DDL}`
   - `{TENANT_DDL}`

2. Determine table prefix from module name

3. For new schema:
   - Generate CREATE TABLE DDL following conventions
   - Required columns: id, is_active, created_by, created_at, updated_at, deleted_at
   - FK indexes on all foreign key columns
   - Generate Laravel migration files → `database/migrations/tenant/`
   - Generate Eloquent models → `Modules/{Module}/app/Models/`

4. For validation:
   - Compare model `$fillable` against migration columns
   - Check `$casts` types match DB types
   - Verify relationships match FK definitions
   - Report mismatches

## CRITICAL: NEVER reference non-v2 DDL files
