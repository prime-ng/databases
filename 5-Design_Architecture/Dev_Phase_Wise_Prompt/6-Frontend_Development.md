# Phase 6 — Frontend Development
================================

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


### What YOU Provide
Nothing extra — Claude uses your Phase 3 screen planning decisions.

### Prompt 6A — Generate All Views

```
## Generate All Views

Read:
- The Screen Planning from Phase 3
- `AI_Brain/agents/frontend-developer.md`
- Reference views from existing modules:
  - Tab-based: `Modules/Transport/resources/views/transport-master/index.blade.php`
  - Simple index: `Modules/SchoolSetup/resources/views/building/index.blade.php`
  - Create form: `Modules/Transport/resources/views/driver_helper/create.blade.php`

Based on my screen planning decisions from Phase 3:
[Paste or reference your Phase 3 decisions]

Generate ALL views for [MODULE_NAME]:

For each entity, generate the views I specified in Phase 3:
- Index views (with columns I specified)
- Create/Edit forms (with layout I specified: single/two-column/tabbed)
- Show views (where I requested them)
- Tab-based master view (if I specified one)

**Use these patterns exactly:**
- Layout: `<x-backend.layouts.app>`
- Breadcrumbs: `<x-backend.components.breadcrum>`
- Card header: `<x-backend.card.header>`
- Tables: `@forelse`/`@empty` with pagination
- Forms: `@csrf`, `@method('PUT')`, `@error`, `old()` pattern
- Status badges: `badge bg-success` / `badge bg-danger`

Store ALL views in: `Modules/[MODULE_NAME]/resources/views/`
```

### Prompt 6B — Generate Specific View (if you want to do one entity at a time)

```
## Generate View for [ENTITY]

Read `AI_Brain/agents/frontend-developer.md`.

Generate the [index/create/edit/show] view for [ENTITY] in [MODULE_NAME]:

**File:** `Modules/[MODULE_NAME]/resources/views/[entity]/[type].blade.php`

**Layout:** [From my Phase 3 decision: single column / two column / tabbed]
**Columns/Fields:** [From my Phase 3 decision]

Follow the exact patterns from the frontend-developer agent.
```

### Quality Gate 6
- [ ] All views use `<x-backend.layouts.app>`
- [ ] Breadcrumbs on every page
- [ ] Forms have `@csrf` and `@method` where needed
- [ ] `@forelse`/`@empty` on all tables
- [ ] Pagination present
- [ ] No hardcoded route names

