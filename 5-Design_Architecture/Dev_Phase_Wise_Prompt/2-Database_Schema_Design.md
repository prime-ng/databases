# Phase 2 — Database Schema Design (DDL)
========================================


## CONFIGURATION
----------------
MODULE_CODE       = ACC                    # Used in: issue codes (BUG-HPC-001), section headers, AI Brain lookups
MODULE            = Accounting             # Used in: issue codes (BUG-HPC-001), section headers, AI Brain lookups
MODULE_DIR        = Modules/Accounting/    # Used in: file paths (Modules/Hpc/), git commands
BRANCH            = Brijesh_Accounting     # Used in: context for the prompt
DEVELOPER         = Brijesh                 # Used in: context for the prompt
RBS_MODULE_CODE   = K
DB_TABLE_PREFIX   = acc_
DATABASE_NAME     = tenant_db
DATE              = 20th Mar 2026         # Used in: git --since filter (Tier 3)


### What YOU Do
- Review the generated DDL — check table names, column names, data types
- Confirm the relationships make sense
- **This is where you start thinking about screens** (but don't decide yet — just notice which tables feel related)

### Prompt 2A — Generate DDL + Migration

```
## Generate Database Schema

Read these files:
- `3-Project_Planning/3-Feature_Specs/[MODULE_NAME]_FeatureSpec.md`
- `AI_Brain/agents/db-architect.md` — follow DB Architect agent instructions
- `AI_Brain/rules/tenancy-rules.md` — table naming rules

Generate the DDL SQL for ALL tables in the [MODULE_NAME] module.

**Rules (MUST follow):**
1. Table prefix: `[prefix_]`
2. Every table MUST have: `id`, `is_active`, `created_by`, `created_at`, `updated_at`, `deleted_at`
3. Index ALL foreign keys
4. Junction tables suffix: `_jnt`
5. JSON columns suffix: `_json`
6. Boolean columns prefix: `is_` or `has_`
7. Use `BIGINT UNSIGNED` for all IDs
8. Use `VARCHAR(255)` for names, `TEXT` for descriptions
9. Add `COMMENT` on every column

Generate:
1. **DDL SQL file** — all CREATE TABLE statements with comments
2. **Laravel Migration file** — for `database/migrations/tenant/`
3. **Table summary** — one-line description of each table for my review

Store DDL in: `databases/2-DDL_Tenant_Modules/[N]-[MODULE_NAME]/DDL/[prefix]_tables_v1.sql`
Store migration in: `database/migrations/tenant/YYYY_MM_DD_create_[prefix]_tables.php`
```

### Prompt 2B — Generate Seeders

```
## Generate Database Seeders

Read the DDL from: `databases/2-DDL_Tenant_Modules/[N]-[MODULE_NAME]/DDL/[prefix]_tables_v1.sql`

Generate Laravel seeders for:
1. **Lookup/config tables** — pre-populate with standard data (types, statuses, categories)
2. **Demo data seeder** — realistic sample data for testing (10-20 records per table)

Store in: `Modules/[MODULE_NAME]/database/seeders/`
```

### Quality Gate 2
- [ ] All entities from the feature spec exist as tables in DDL
- [ ] Foreign keys match referenced tables
- [ ] Required columns (id, is_active, created_by, timestamps, deleted_at) present on ALL tables
- [ ] You've reviewed the DDL and understand what data exists