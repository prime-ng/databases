# Phase 4 — Module Scaffolding
==============================

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

### Prompt 4A — Scaffold Module + Models

```
## Scaffold Module

Read:
- `3-Project_Planning/3-Feature_Specs/[MODULE_NAME]_FeatureSpec.md`
- The DDL from Phase 2
- `AI_Brain/agents/module-agent.md`
- `AI_Brain/templates/model.md`

Create the complete module scaffold for [MODULE_NAME]:

**Module Config:**
- Name: [MODULE_NAME]
- Alias: [module-name]
- Table prefix: [prefix_]
- Route prefix: /[module-name]/*

Generate:
1. `module.json`, `composer.json`
2. Service Providers (ModuleServiceProvider, RouteServiceProvider)
3. Route files (`web.php`, `api.php`)
4. **One Model per DDL table** — with:
   - Correct `$table` with prefix
   - All `$fillable` columns (include `created_by`, exclude id/timestamps/deleted_at)
   - `$casts` for booleans, JSON, dates
   - `use SoftDeletes`
   - All relationships (BelongsTo, HasMany, BelongsToMany) matching FK columns

Store in: `Modules/[MODULE_NAME]/`
```

### Quality Gate 4
- [ ] Every DDL table has a Model
- [ ] Every Model has SoftDeletes, $table, $fillable, $casts
- [ ] `created_by` in every $fillable
- [ ] No `is_super_admin` in any $fillable



