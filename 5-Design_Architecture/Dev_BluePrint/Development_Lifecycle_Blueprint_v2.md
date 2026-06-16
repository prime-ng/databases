# Prime-AI — Development Lifecycle Blueprint v2

**Purpose:** Practical step-by-step process for building modules with Claude AI — designed for the real workflow where you have RBS and high-level requirements but NO wireframes upfront.

**Key Change from v1:** Wireframes are NOT required before starting. Instead, you decide screen layouts AFTER Claude generates the database schema. This matches how you actually work.

**Date:** 2026-03-15
**Team:** 3 Developers + Claude AI

---

## The Real Workflow (v2)

```
┌──────────────────────────────────────────────────────────────────────────────────────────────┐
│                           DEVELOPMENT LIFECYCLE v2 (per module)                              │
│                                                                                              │
│  Phase 1              Phase 2              Phase 3               Phase 4                     │
│  REQUIREMENTS    →    DDL DESIGN     →     SCREEN PLANNING  →    SCAFFOLD                    │
│  (You + Claude)       (Claude)             (YOU decide)          (Claude)                    │
│  RBS document         SQL tables           Which tables =        Models                      │
│  High-level idea      Migrations           which screens?        module.json                 │
│  Business rules       Columns + FKs        Tabs? Combined?       Relationships               │
│  NO wireframes        Seeders              Layout choices                                    │
│                                                                                              │
│  Phase 5              Phase 6              Phase 7               Phase 8                     │
│  BACKEND         →    FRONTEND       →     SECURITY         →    TEST + REVIEW               │
│  (Claude)             (Claude)             (Claude)              (Claude)                    │
│  Controllers          Views from YOUR      Gate::authorize       Pest tests                  │
│  FormRequests         screen decisions     EnsureTenantHas       Code review                 │
│  Routes               Blade templates      Permission seeder     AI Brain update             │
│  Services                                                                                    │
│                                                                                              │
│  Phase 9                                                                                     │
│  DEPLOY (Manual)                                                                             │
│  Migrate, seed, assign permissions, browser test                                             │
│                                                                                              │
└──────────────────────────────────────────────────────────────────────────────────────────────┘

KEY DIFFERENCE FROM v1:
  ❌ v1: Wireframes required BEFORE Phase 1 (blocked many teams)
  ✅ v2: Phase 3 (Screen Planning) happens AFTER you see the DDL tables
         You decide layout only when you know what data exists
```

---

## Phase 1 — Requirements (No Wireframes Needed)

### What YOU Provide

You only need to give Claude **three things**:

1. **Module name + description** (1-2 sentences)
2. **RBS reference** — point to the relevant section in `PrimeAI_RBS_Menu_Mapping_v2.0.md`
3. **Business rules** — what special logic applies (optional — Claude can suggest defaults)

That's it. No wireframes. No field lists. No screen layouts.

### Prompt 1A — Generate Feature Specification from RBS

```
## Generate Feature Specification from RBS

Read these files:
1. `3-Project_Planning/1-RBS/PrimeAI_RBS_Menu_Mapping_v2.0.md` — find Module [X] section
2. `AI_Brain/memory/project-context.md` — project context
3. `AI_Brain/memory/modules-map.md` — existing modules (to avoid duplication)
4. `AI_Brain/agents/business-analyst.md` — follow the BA agent instructions

**Module:** [MODULE_NAME]
**RBS Module Code:** [X] (e.g., O for Hostel, K for Accounting)
**Table Prefix:** [prefix_] (e.g., hos_, acc_)
**Database:** tenant_db
**Description:** [1-2 sentence description]

**Additional business rules (if any):**
- [Rule 1, e.g., "Room capacity cannot be exceeded"]
- [Rule 2, e.g., "Gender-based room allocation"]

**I do NOT have wireframes.** Generate the feature specification based purely on:
- The RBS sub-tasks for this module
- Indian K-12 school domain knowledge
- Patterns from similar existing modules in Prime-AI

Generate:
1. **Entity list** — all tables needed with columns, types, relationships
2. **Entity Relationship Diagram** (text-based)
3. **Business rules** — validation rules, cascade behaviors, status workflows
4. **Permission list** — all Gate permissions needed
5. **Dependencies** — which existing modules this connects to

Do NOT generate screen layouts yet — that comes in Phase 3 after DDL review.

Store output in: `3-Project_Planning/3-Feature_Specs/[MODULE_NAME]_FeatureSpec.md`
```

### Quality Gate 1
- [ ] Every RBS sub-task maps to at least one entity/column
- [ ] All entity relationships (FK) are defined
- [ ] Table names use correct prefix convention
- [ ] Business rules are documented

---

## Phase 2 — Database Schema Design (DDL)

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

---

## Phase 3 — Screen Planning (YOU Decide)

### This is the NEW phase that replaces wireframes

After reviewing the DDL, you now know exactly what tables and columns exist. NOW you tell Claude how to organize them into screens.

### What YOU Provide

Fill in this template and give it to Claude:

```markdown
# [MODULE_NAME] — Screen Planning

## I have reviewed the DDL. Here is how I want the screens organized:

### Master Index Page (Tab-Based)
Tab 1: [Entity1 Name] — show columns: [col1, col2, col3]
Tab 2: [Entity2 Name] — show columns: [col1, col2, col3]
Tab 3: [Entity3 Name] — show columns: [col1, col2, col3]
(OR: No master page — each entity gets its own page)

### Screen Combinations
- [Entity1] and [Entity2] should be on the SAME create form (two sections)
- [Entity3] gets its own separate create/edit form
- [Entity4] is a child of [Entity3] — show as a tab on Entity3's show page

### Form Layouts
- [Entity1] create form: Two-column layout
- [Entity2] create form: Single column with tabs (Tab 1: Basic Info, Tab 2: Details)
- [Entity3] create form: Simple single column

### Special Screens
- Dashboard with: [chart type] showing [what data]
- Report page with: [filters] and [export options]
- (OR: No special screens for now — just CRUD)

### Notes
- [Entity5] is a lookup table — only needs a simple CRUD, no fancy UI
- [Entity6] is read-only — no create/edit, just index + show
```

### Prompt 3A — Claude Confirms Screen Plan

```
## Confirm Screen Plan

I have provided my screen planning decisions above.

Based on my decisions and the DDL from Phase 2, confirm:
1. How many Blade view files will be created?
2. How many controllers are needed?
3. Which entities share a controller vs have their own?
4. Which views are tab-based vs standalone?

List every file that will be created in Phase 5 (Frontend) so I can approve before proceeding.
```

### Quality Gate 3
- [ ] You've decided: which tables = which screens
- [ ] You've decided: tabs vs separate pages
- [ ] You've decided: form layout (columns, tabs, sections)
- [ ] Claude has confirmed the file list and you've approved it

---

## Phase 4 — Module Scaffolding

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

---

## Phase 5 — Backend Development

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

---

## Phase 6 — Frontend Development

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

---

## Phase 7 — Security Hardening

*(Same as v1 Phase 6)*

### Prompt 7A — Security Audit + Fix

```
## Security Hardening

Read `AI_Brain/agents/backend-developer.md` (security rules section).
Read the completed module code in `Modules/[MODULE_NAME]/`.

Verify and fix ALL of the following:
1. Gate::authorize() on EVERY public controller method
2. FormRequest authorize() uses Gate — NOT `return true`
3. $request->validated() everywhere — NO $request->all()
4. EnsureTenantHasModule middleware on route group
5. No is_super_admin in any $fillable
6. No ::all() or unbounded ::get()
7. No dd(), dump(), var_dump()
8. No hardcoded API keys
9. Permission naming consistent: [module-name].[resource].[action]
10. Central models not queried from tenant context without tenancy()->central()
11. SoftDeletes on all models

Generate Permission Seeder: `Modules/[MODULE_NAME]/database/seeders/[MODULE_NAME]PermissionSeeder.php`
```

---

## Phase 8 — Testing

*(Same as v1 Phase 7)*

### Prompt 8A — Generate Tests

```
## Generate Tests

Read `AI_Brain/agents/test-agent.md`.

Generate Pest 4.x tests for [MODULE_NAME]:

**Unit tests** (`tests/Unit/[MODULE_NAME]/`):
- Model instantiation, fillable, casts, relationships, soft delete

**Feature tests** (`Modules/[MODULE_NAME]/tests/Feature/`):
- index 200/403, store valid/invalid, update, destroy, restore

Run: /test [MODULE_NAME]
```

---

## Phase 9 — Code Review + AI Brain Update

*(Same as v1 Phase 8)*

### Prompt 9A — Review + Update Brain

```
## Code Review + AI Brain Update

1. Run /review on Modules/[MODULE_NAME]/ — fix all issues
2. Update AI_Brain/memory/modules-map.md — add module with accurate counts
3. Update AI_Brain/state/progress.md — add completion entry
4. Update AI_Brain/lessons/known-issues.md — add any gotchas found
```

---

## Phase 10 — Deploy

*(Same as v1 Phase 9 — manual steps)*

1. `php artisan tenants:migrate`
2. Seed permissions
3. Assign to roles
4. Browser test
5. Git commit

---

## Complete Workflow Example: Building Hostel Module

### Phase 1 — You provide (5 minutes):
```
Module: HostelManagement
RBS Module Code: O (from PrimeAI_RBS_Menu_Mapping_v2.0.md)
Table Prefix: hos_
Description: Hostel room management, student allotment, mess, attendance, fees for boarding schools.

Business rules:
- Room capacity cannot be exceeded
- Gender-based room allocation (boys/girls/co-ed hostels)
- Fee prorated for mid-session joins
```
Run Prompt 1A → Claude generates Feature Spec with ~8 entities.

### Phase 2 — Claude generates DDL (30 min):
Run Prompt 2A → Claude creates DDL with 8 tables:
```
hos_hostels, hos_rooms, hos_room_types, hos_student_allotments,
hos_attendance, hos_mess_menus, hos_hostel_fees, hos_incidents
```
**YOU review the DDL.** Confirm tables and columns look right.

### Phase 3 — YOU decide screen layout (15 minutes):
After seeing the DDL, you write:
```
Master Index: Tab-based
  Tab 1: Hostels — name, address, type, warden, capacity
  Tab 2: Room Types — name, description
  Tab 3: Rooms — number, floor, hostel, room_type, capacity, status

Separate Pages:
  - Student Allotment — two-column form (student select + room select)
  - Attendance — date picker + checklist (like Transport attendance)
  - Mess Menu — weekly grid (like a timetable view)
  - Hostel Fee — simple CRUD, single column
  - Incidents — simple CRUD with textarea for description

Special: No dashboard for now. Just CRUD.
```

### Phase 4 — Claude scaffolds (20 min):
Run Prompt 4A → 8 Models created with relationships.

### Phase 5 — Claude builds backend (1 hour):
Run Prompt 5A → 8 Controllers, 16 FormRequests, routes registered.

### Phase 6 — Claude builds frontend (1 hour):
Run Prompt 6A → 1 master tab view + 5 separate CRUD page sets = ~20 Blade files.

### Phase 7-10 — Security, Tests, Review, Deploy (2 hours):
Run Prompts 7A, 8A, 9A → Security hardened, 30+ tests, AI Brain updated.

### Total: ~1 day for a complete module with 8 entities.

---

## What's Different from v1?

| Aspect | v1 (Old) | v2 (New) |
|--------|----------|----------|
| **Wireframes required?** | Yes — before starting | No — decide screens after DDL |
| **Phase 3** | Module Scaffolding | Screen Planning (YOUR decisions) |
| **When you decide screen layout** | Before Phase 1 | After Phase 2 (DDL review) |
| **What you provide upfront** | RBS + Wireframes + Fields | RBS + Description + Business rules |
| **When to provide layout details** | Phase 1 (blocks everything) | Phase 3 (after you see the tables) |
| **Prompts count** | 17 | 14 (streamlined) |
| **Your decision points** | Phase 1 only | Phase 1 (requirements) + Phase 3 (screens) |

---

## Prompt Library — Quick Reference

| # | Phase | Prompt | Your Input | Claude Output |
|---|-------|--------|-----------|---------------|
| 1A | Requirements | Feature Spec from RBS | Module name + RBS code + business rules | Feature spec with entities + relationships |
| 2A | DDL | Generate Schema | Feature spec reference | SQL DDL + Laravel migration |
| 2B | DDL | Generate Seeders | DDL reference | Seeder files |
| 3A | Screen Planning | Confirm Screen Plan | YOUR screen layout decisions | File list confirmation |
| 4A | Scaffold | Module + Models | DDL reference | Models, module.json, providers |
| 5A | Backend | Controllers + Routes | Feature spec + screen plan | Controllers, FormRequests, routes |
| 5B | Backend | Services | Complex logic description | Service classes |
| 6A | Frontend | Generate All Views | YOUR screen plan from Phase 3 | All Blade view files |
| 6B | Frontend | Generate Single View | Entity + layout preference | One view file |
| 7A | Security | Hardening + Permissions | Module reference | Fixed code + permission seeder |
| 8A | Testing | Unit + Feature Tests | Module reference | Pest test files |
| 9A | Review | Code Review + Brain Update | Module reference | Fixed issues + AI Brain entries |

---

## Screen Planning Template (Copy-Paste for Phase 3)

Use this template after you've reviewed the DDL:

```markdown
# [MODULE_NAME] — Screen Planning

## Master Index Page
(Choose one)
- [ ] Tab-based master index (like Transport)
- [ ] Each entity gets its own page (like SchoolSetup)

If tab-based, list tabs:
Tab 1: [Entity] — columns: [col1, col2, col3, status, action]
Tab 2: [Entity] — columns: [col1, col2, col3, status, action]
Tab 3: [Entity] — columns: [col1, col2, col3, status, action]

## Create/Edit Forms
For each entity:

[Entity1]:
- Layout: [ ] Single column  [ ] Two column  [ ] Tabbed
- Fields on form: [list or "all from DDL"]
- Dropdowns: [which fields are selects, what's the source table]

[Entity2]:
- Layout: [ ] Single column  [ ] Two column  [ ] Tabbed
- Fields on form: [list or "all from DDL"]

## Combined/Child Screens
- [EntityA] is a child of [EntityB] — show as tab on EntityB's show page
- [EntityC] and [EntityD] share one create form (two sections)

## Special Screens
- [ ] Dashboard with charts — (describe what data)
- [ ] Reports page — (describe filters and exports)
- [ ] Calendar view — (describe what events)
- [ ] None — just CRUD for now

## Lookup Tables (simple CRUD only)
- [EntityX] — just a name field, simple list + create modal
- [EntityY] — just name + description, simple CRUD
```
--------------------------------------------------------------------------------------------------------------------------------------------

What Changed: v1 vs v2

  v1 (blocked):  Wireframes → RBS → DDL → Scaffold → Backend → Frontend
                     ❌
                 You don't have wireframes

  v2 (unblocked): RBS → DDL → YOU REVIEW DDL → Screen Decisions → Backend → Frontend
                   ↑         ↑                   ↑
                You give    Claude              You tell Claude:
                module name generates           "these 3 tables = 1 tab page"
                + business  tables              "this entity = two-column form"
                rules                           "no dashboard for now, just CRUD"

  The key insight: Phase 3 (Screen Planning)

  A NEW phase inserted between DDL and coding where you look at the tables Claude created and then tell Claude:

  - Which tables go on the same screen (tabs vs separate pages)
  - How the create form should look (single/two-column/tabbed)
  - Which entities are children shown on parent's show page
  - Whether you want a dashboard/reports or just CRUD for now

  What you provide at each phase:

  ┌───────────┬─────────────────────────────────────────┬─────────────┐
  │   Phase   │               You Provide               │ Time Needed │
  ├───────────┼─────────────────────────────────────────┼─────────────┤
  │ Phase 1   │ Module name + RBS code + business rules │ 5 min       │
  ├───────────┼─────────────────────────────────────────┼─────────────┤
  │ Phase 2   │ Review DDL output, confirm it's correct │ 15 min      │
  ├───────────┼─────────────────────────────────────────┼─────────────┤
  │ Phase 3   │ Fill in the Screen Planning template    │ 15 min      │
  ├───────────┼─────────────────────────────────────────┼─────────────┤
  │ Phase 4-9 │ Nothing — Claude does everything        │ 0 min       │
  ├───────────┼─────────────────────────────────────────┼─────────────┤
  │ Phase 10  │ Browser testing + permission assignment │ 30 min      │
  └───────────┴─────────────────────────────────────────┴─────────────┘

  Total YOUR time: ~1 hour per module. Claude does the rest.