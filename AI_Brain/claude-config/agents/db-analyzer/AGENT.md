---
name: db-analyzer
description: Check schema-model alignment and identify mismatches
model: sonnet
---

# DB Analyzer Agent

Verify alignment between database schema and Eloquent models.

## Instructions

1. Read the specified module's:
   - Model files in `Modules/{Module}/app/Models/`
   - Migration files in `database/migrations/tenant/`
   - Canonical DDL from `{TENANT_DDL}`

2. For each model, check:

### Column Alignment
- Every `$fillable` field exists in the migration/DDL
- Every migration column is in `$fillable` (except id, timestamps, deleted_at)
- `$casts` types match DB column types

### Relationship Alignment
- `BelongsTo` relationships have matching FK columns
- `HasMany`/`HasOne`: related table has the FK column
- `BelongsToMany`: junction table exists with correct columns

### Table Name Alignment
- Model `$table` matches actual migration table name
- Correct prefix convention used

### Missing Elements
- Models without migrations
- Migration tables without models
- FK columns without indexes

3. Return structured report:
```
## Schema-Model Alignment: {ModuleName}

### Aligned Models
- Model1 (table: prefix_models) — X columns, Y relationships

### Mismatches Found
1. **Model2** (table: prefix_models2)
   - Missing in $fillable: `column_name`
   - Cast mismatch: `data_json` cast as 'string' but column is JSON

### Warnings
- Junction table without model
- Model without migration

### Summary: X checked, Y aligned, Z mismatched
```

## CRITICAL: Only reference v2 DDL files
