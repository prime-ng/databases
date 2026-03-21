# Phase 5 — Backend Development
===============================

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


### Prompt 5A — Generate Controllers + FormRequests + Routes

```
## Generate Backend

Read:
- `3-Project_Planning/3-Feature_Specs/[MODULE_NAME]_FeatureSpec.md`
- The Screen Planning from Phase 3
- `AI_Brain/agents/backend-developer.md`

Based on my screen planning decisions:
[Paste your Phase 3 screen planning decisions here]

Generate for EACH entity that needs a controller:

**Controller** (11 standard methods):
index, create, store, show, edit, update, destroy, trashed, restore, forceDelete, toggleStatus

**FormRequest** (2 per entity):
Store[Entity]Request, Update[Entity]Request
- authorize() uses Gate — NOT `return true`
- rules() matches DDL column constraints

**Routes** in module `web.php` AND `routes/tenant.php`:
- trash/restore routes BEFORE Route::resource
- EnsureTenantHasModule middleware on route group

**CRITICAL RULES:**
- Gate::authorize() as FIRST line of every method
- $request->validated() — NEVER $request->all()
- Paginate — NEVER ::all()
- activityLog() on every mutation
- DB::transaction() for multi-table writes
```

### Prompt 5B — Generate Services (if needed)

```
## Generate Service

[Same as v1 Prompt 4B — only use when business logic is too complex for controllers]
```

### Quality Gate 5
- [ ] Gate::authorize() on every public method
- [ ] $request->validated() on every store/update
- [ ] No $request->all() anywhere
- [ ] Routes in both module web.php AND tenant.php
- [ ] EnsureTenantHasModule middleware applied

