# Prime-AI — Complete Development Lifecycle Blueprint

**Purpose:** Step-by-step process for working with Claude AI to build every module from requirement to fully developed and tested code — with 100% accuracy matching existing codebase patterns.

**Date:** 2026-03-15
**Team:** 3 Developers + Claude AI
**Tech Stack:** PHP 8.2 / Laravel 12 / AdminLTE v4 / Bootstrap 5 / MySQL 8 / stancl/tenancy v3.9 / nwidart/laravel-modules v12

---

## Table of Contents

1. [Development Lifecycle Overview](#1-development-lifecycle-overview)
2. [Phase 1 — Requirement Creation](#phase-1--requirement-creation)
3. [Phase 2 — Database Schema Design](#phase-2--database-schema-design)
4. [Phase 3 — Module Scaffolding](#phase-3--module-scaffolding)
5. [Phase 4 — Backend Development](#phase-4--backend-development)
6. [Phase 5 — Frontend Development](#phase-5--frontend-development)
7. [Phase 6 — Security Hardening](#phase-6--security-hardening)
8. [Phase 7 — Testing](#phase-7--testing)
9. [Phase 8 — Code Review & AI Brain Update](#phase-8--code-review--ai-brain-update)
10. [Phase 9 — Integration & Deployment](#phase-9--integration--deployment)
11. [What You Must Create Manually](#what-you-must-create-manually)
12. [Quality Gates](#quality-gates)
13. [Prompt Library — Complete Reference](#prompt-library)

---

## 1. Development Lifecycle Overview

```
┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                               DEVELOPMENT LIFECYCLE (per module)                                             │
│                                                                                                              │
│  Phase 1               Phase 2               Phase 3               Phase 4               Phase 5             │
│  REQUIREMENT      →    DB SCHEMA       →     SCAFFOLDING     →     BACKEND         →     FRONTEND            │
│  (Manual+Claude)       (Claude)              (Claude)              (Claude)              (Claude)            │
│  RBS document          DDL SQL               Models                Controllers           Blade views         │
│  Menu mapping          Migrations            Routes                Services              Components          │
│  Wireframes            Seeders               module.json           FormRequests          Alpine.js           │
│                                                                                                              │
│  Phase 6               Phase 7               Phase 8               Phase 9                                   │
│  SECURITY         →    TESTING        →      REVIEW          →     DEPLOY                                    │
│  (Claude)              (Claude)              (Claude)              (Manual)                                  │
│  Gate::authorize       Pest tests            Code review           Tenant migrate                            │
│  Policies              Feature tests         AI Brain update       Route cache                               │
│  FormRequest auth      Unit tests            known-issues.md       Seed permissions                          │
│                                                                                                              │
└──────────────────────────────────────────────────────────────────────────────────────────────────────────────┘

Each phase has:
  ✅ A ready-to-use PROMPT (copy-paste into Claude)
  ✅ INPUT files Claude needs to read
  ✅ OUTPUT files Claude will create/modify
  ✅ QUALITY GATE (verification before moving to next phase)
```

---

## Phase 1 — Requirement Creation

### What YOU do (Manual)

1. **Write the RBS entry** for the module/sub-module following the existing format in `3-Project_Planning/1-RBS/PrimeAI_RBS_Menu_Mapping_v2.0.md`
2. **Create wireframe sketches** (paper/Figma/Balsamiq) for each screen — at minimum:
   - Index page (list view with filters)
   - Create/Edit form (all fields, tabs if multi-step)
   - Show page (detail view)
   - Any special screens (dashboard, reports, calendar)
3. **Define business rules** — what happens on create/update/delete, cascade behaviors, status workflows

### What Claude does

Claude can help you refine and expand requirements if you give it the basic idea.

### Prompt 1A — Generate RBS from Module Description

```
## Generate RBS Entry

Read the existing RBS format from:
- `3-Project_Planning/1-RBS/PrimeAI_RBS_Menu_Mapping_v2.0.md` (first 100 lines for format)

Now generate a complete RBS entry for this new module:

**Module Name:** [MODULE_NAME]
**Module Code:** [X] (single letter from RBS)
**Table Prefix:** [prefix_]
**Database:** tenant_db
**Description:** [Brief description of what this module does]

**Screens/Menus I need:**
1. [Screen 1 name] — [what it does]
2. [Screen 2 name] — [what it does]
3. [Screen 3 name] — [what it does]
...

**Business Rules:**
- [Rule 1]
- [Rule 2]
...

Generate the RBS entry in the EXACT format used in PrimeAI_RBS_Menu_Mapping_v2.0.md with:
- Functionality codes (F.X1.1)
- Task codes (T.X1.1.1)
- Sub-task codes (ST.X1.1.1.1)
- Table references
- Menu hierarchy

Store the output in: `3-Project_Planning/1-RBS/[MODULE_NAME]_RBS.md`
```

### Prompt 1B — Generate Detailed Feature Specification from RBS

```
## Generate Feature Specification

Read the RBS entry for [MODULE_NAME] from:
- `3-Project_Planning/1-RBS/[MODULE_NAME]_RBS.md`

Also read the AI Brain context:
- `AI_Brain/memory/project-context.md`
- `AI_Brain/memory/tenancy-map.md`
- `AI_Brain/rules/module-rules.md`

Generate a detailed Feature Specification document that includes:

1. **Entity Relationship Diagram** (text-based) showing all tables and relationships
2. **Screen-by-Screen Specification:**
   - For each screen: fields, field types, validation rules, dropdown sources
   - CRUD operations and their business logic
   - Status workflows (if any)
3. **API Endpoints** (if needed) — RESTful routes with request/response format
4. **Permissions** — list all Gate permissions needed (format: `module-name.resource.action`)
5. **Dependencies** — which other modules this depends on (SchoolSetup, StudentProfile, etc.)

Store the output in: `3-Project_Planning/3-Feature_Specs/[MODULE_NAME]_FeatureSpec.md`
```

### Quality Gate 1
- [ ] RBS entry covers ALL screens from your wireframes
- [ ] Every screen has at least 2 functionalities with tasks and sub-tasks
- [ ] Table names use correct prefix convention
- [ ] Business rules are documented

---

## Phase 2 — Database Schema Design

### What YOU do
- Review the generated DDL and confirm table structure
- Check column names match your wireframe field names

### Prompt 2A — Generate Database Schema (DDL)

```
## Generate Database Schema

Read these files:
- `3-Project_Planning/3-Feature_Specs/[MODULE_NAME]_FeatureSpec.md`
- `AI_Brain/rules/tenancy-rules.md` — for table naming rules
- `databases/0-DDL_Masters/tenant_db_v2.sql` (first 100 lines for format reference)

Generate the DDL SQL for all tables in the [MODULE_NAME] module.

**Rules (MUST follow):**
1. Table prefix: `[prefix_]` (e.g., `hos_` for hostel, `acc_` for accounting)
2. Every table MUST have: `id`, `is_active`, `created_by`, `created_at`, `updated_at`, `deleted_at`
3. Index ALL foreign keys
4. Junction tables suffix: `_jnt`
5. JSON columns suffix: `_json`
6. Boolean columns prefix: `is_` or `has_`
7. Use `BIGINT UNSIGNED` for all IDs
8. Use `VARCHAR(255)` for names, `TEXT` for descriptions
9. Add `COMMENT` on every column

Generate:
1. **DDL SQL file** — all CREATE TABLE statements
2. **Laravel Migration file** — for `database/migrations/tenant/`

Store SQL in: `databases/2-DDL_Tenant_Modules/[N]-[MODULE_NAME]/DDL/[prefix]_tables_v1.sql`
Store migration in: `database/migrations/tenant/YYYY_MM_DD_create_[prefix]_tables.php`
```

### Prompt 2B — Generate Seeders

```
## Generate Database Seeders

Read the DDL from: `databases/2-DDL_Tenant_Modules/[N]-[MODULE_NAME]/DDL/[prefix]_tables_v1.sql`

Generate Laravel seeders for:
1. **Lookup/config tables** — pre-populate with standard data (types, statuses, categories)
2. **Demo data seeder** — realistic sample data for testing (10-20 records per table)

Follow the pattern in: `AI_Brain/templates/tenant-migration.md`

Store in: `Modules/[MODULE_NAME]/database/seeders/`
```

### Quality Gate 2
- [ ] All tables from the feature spec exist in DDL
- [ ] Foreign keys match referenced tables
- [ ] Required columns (id, is_active, created_by, timestamps, deleted_at) present on ALL tables
- [ ] Migration runs without errors: `php artisan tenants:migrate --pretend`

---

## Phase 3 — Module Scaffolding

### What YOU do
- Nothing — Claude generates everything

### Prompt 3A — Scaffold Module Structure

```
## Scaffold New Module

Read these references:
- `AI_Brain/memory/modules-map.md` — module structure pattern
- `AI_Brain/templates/module-structure.md`
- `AI_Brain/templates/model.md`
- `AI_Brain/rules/module-rules.md`

Create the complete module scaffold for [MODULE_NAME]:

**Module Config:**
- Name: [MODULE_NAME]
- Alias: [module-name]
- Table prefix: [prefix_]
- Route prefix: /[module-name]/*

**Generate these files:**

1. `module.json` — module config with providers
2. `composer.json` — PSR-4 autoloading
3. `app/Providers/[MODULE_NAME]ServiceProvider.php`
4. `app/Providers/RouteServiceProvider.php`
5. `routes/web.php` — empty route group with correct middleware
6. `routes/api.php` — empty API route group

**For each table in the DDL, generate:**
7. `app/Models/[EntityName].php` — following `AI_Brain/templates/model.md` pattern:
   - Correct `$table` with prefix
   - All `$fillable` columns (excluding id, timestamps, deleted_at)
   - `$casts` for booleans, JSON, dates
   - `use SoftDeletes`
   - All relationships (BelongsTo, HasMany, BelongsToMany)

Store all files in: `Modules/[MODULE_NAME]/`

**CRITICAL RULES:**
- Models MUST use the exact table name from DDL
- $fillable MUST include `created_by`
- NEVER include `is_super_admin`, `remember_token` in $fillable
- All BelongsTo relationships must match FK column names
```

### Quality Gate 3
- [ ] `module.json` exists and is valid JSON
- [ ] Every DDL table has a corresponding Model file
- [ ] Every Model has `use SoftDeletes`
- [ ] Every Model has `created_by` in `$fillable`
- [ ] `composer.json` autoload namespace matches module name

---

## Phase 4 — Backend Development

### What YOU do
- Review generated controllers match your wireframe flows
- Provide any complex business logic rules Claude needs

### Prompt 4A — Generate Controllers + FormRequests + Routes

```
## Generate Backend — Controllers, FormRequests, Routes

Read these files:
- `3-Project_Planning/3-Feature_Specs/[MODULE_NAME]_FeatureSpec.md`
- `AI_Brain/templates/module-controller.md` — controller pattern
- `AI_Brain/templates/form-request.md` — FormRequest pattern
- `AI_Brain/rules/module-rules.md`
- Reference controller: `Modules/Transport/app/Http/Controllers/VehicleController.php` (for a well-structured example)

For the [MODULE_NAME] module, generate:

### For each resource entity:

**1. Controller** (`app/Http/Controllers/[Entity]Controller.php`):
- `index()` — paginated list with eager loading, Gate::authorize
- `create()` — load form dropdowns, Gate::authorize
- `store()` — use FormRequest, `$request->validated()`, activity log, DB::transaction
- `show()` — load with relationships, Gate::authorize
- `edit()` — same as create + load existing record, Gate::authorize
- `update()` — use FormRequest, `$request->validated()`, activity log, DB::transaction
- `destroy()` — soft delete, Gate::authorize, activity log
- `trashed()` — list soft-deleted records, Gate::authorize
- `restore()` — restore soft-deleted, Gate::authorize
- `forceDelete()` — permanent delete, Gate::authorize
- `toggleStatus()` — toggle is_active, Gate::authorize

**2. FormRequest** (`app/Http/Requests/Store[Entity]Request.php`, `Update[Entity]Request.php`):
- `authorize()` → use Gate policy check (NOT `return true`)
- `rules()` → validation rules matching DDL column constraints
- `messages()` → user-friendly error messages

**3. Routes** (`routes/web.php`):
- `Route::resource('[entity-name]', [Entity]Controller::class)`
- `Route::get('[entity-name]/trash/view', ...)` — BEFORE Route::resource
- `Route::get('[entity-name]/{id}/restore', ...)`
- `Route::delete('[entity-name]/{id}/force-delete', ...)`
- `Route::post('[entity-name]/{id}/toggle-status', ...)`

**ALSO register in `routes/tenant.php`:**
- Add the route group under the module prefix with `['auth', 'verified', 'module:[MODULE_NAME]']` middleware

**CRITICAL RULES:**
- ALWAYS use `$request->validated()` — NEVER `$request->all()`
- ALWAYS add `Gate::authorize()` as FIRST line of every public method
- Permission naming: `[module-name].[resource].[action]` (e.g., `hostel.room.create`)
- Use `DB::transaction()` for multi-table writes
- Call `activityLog()` on every mutation
- Eager load relationships in index(): `->with(['relation1', 'relation2'])`
- Paginate: `->paginate(15)` — NEVER use `::all()` or `::get()` unbounded
```

### Prompt 4B — Generate Services (if complex business logic)

```
## Generate Service Class

Read the Feature Specification for [MODULE_NAME].

The following business logic is too complex for a controller and needs a dedicated service:

**Service Name:** [ServiceName]Service
**Location:** `Modules/[MODULE_NAME]/app/Services/[ServiceName]Service.php`

**Methods needed:**
1. `[methodName]($params)` — [describe what it does]
2. `[methodName]($params)` — [describe what it does]
...

**Business Rules:**
- [Rule 1]
- [Rule 2]

Follow the pattern in `AI_Brain/templates/module-service.md`.
Use constructor injection for dependencies.
Wrap multi-step operations in `DB::transaction()`.
Add `\Log::info()` for important operations.
```

### Quality Gate 4
- [ ] Every controller method has `Gate::authorize()` as first line
- [ ] Every `store()`/`update()` uses a FormRequest with `$request->validated()`
- [ ] No `$request->all()` anywhere
- [ ] No `::all()` or unbounded `::get()` in any query
- [ ] `DB::transaction()` used for multi-table writes
- [ ] `activityLog()` called on every create/update/delete
- [ ] Routes registered in BOTH module `web.php` AND `routes/tenant.php`
- [ ] `EnsureTenantHasModule` middleware applied on route group

---

## Phase 5 — Frontend Development

### What YOU do
- Provide wireframe screenshots or detailed descriptions of each screen
- Specify any custom UI components needed

### Prompt 5A — Generate Index (List) View

```
## Generate Index View

Read these reference files for the EXACT pattern to follow:
- `Modules/Transport/resources/views/transport-master/index.blade.php` (tab-based index)
- OR `Modules/SchoolSetup/resources/views/building/index.blade.php` (simple index)
- `resources/views/components/backend/` (available Blade components)

Generate the index view for [ENTITY] in [MODULE_NAME]:

**File:** `Modules/[MODULE_NAME]/resources/views/[entity]/index.blade.php`

**Layout Pattern (MUST follow exactly):**
```blade
<x-backend.layouts.app>
    <x-backend.components.breadcrum title="[Title]" :links="[...]" />
    <div class="container-fluid">
        <div class="row">
            <div class="col-sm-12">
                <div class="card mb-4">
                    <x-backend.card.header title="[Title]" url="[module].[entity]" />
                    <div class="card-body">
                        <table class="table table-sm">
                            ...
                        </table>
                    </div>
                </div>
            </div>
        </div>
    </div>
</x-backend.layouts.app>
```

**Columns to display:** [list columns]
**Filters needed:** [list filters]
**Action buttons:** Edit, Delete, Toggle Status, View (icons from AdminLTE)
**Pagination:** Use `{{ $entities->links() }}`

**Features:**
- @forelse / @empty pattern for no-data message
- Status badge: `<span class="badge bg-success">Active</span>` / `<span class="badge bg-danger">Inactive</span>`
- SweetAlert2 for delete confirmation
- Toast notifications for success/error messages
```

### Prompt 5B — Generate Create/Edit Form View

```
## Generate Create/Edit Form View

Read these reference files:
- `Modules/Transport/resources/views/driver_helper/create.blade.php`
- `Modules/SchoolSetup/resources/views/organization/create.blade.php`

Generate the create form for [ENTITY] in [MODULE_NAME]:

**File:** `Modules/[MODULE_NAME]/resources/views/[entity]/create.blade.php`

**Form fields (from DDL/Feature Spec):**
| Field | Type | Label | Required | Notes |
|-------|------|-------|----------|-------|
| name | text | Name | Yes | max 255 |
| description | textarea | Description | No | |
| type_id | select | Type | Yes | dropdown from [table] |
| start_date | date | Start Date | Yes | |
| is_active | checkbox | Active | No | default true |
| document | file | Upload Document | No | pdf, max 5MB |
...

**Layout:** [Single column / Two column / Tabbed]
**Submit URL:** `route('[module].[entity].store')`
**Method:** POST with @csrf

**For Edit:** Same form but:
- Method: PUT with @method('PUT')
- Pre-fill all fields with `old('field', $entity->field)`
- Submit URL: `route('[module].[entity].update', $entity)`

**CRITICAL:**
- Use Bootstrap 5 classes: `form-control`, `form-select`, `form-check-input`
- Error display: `@error('field') ... @enderror` pattern
- All selects: `<option value="">-- Select --</option>` as first option
- File inputs: show existing file link on edit
```

### Prompt 5C — Generate Show (Detail) View

```
## Generate Show/Detail View

Generate the show/detail view for [ENTITY]:

**File:** `Modules/[MODULE_NAME]/resources/views/[entity]/show.blade.php`

**Display fields:** [same as form fields but read-only]
**Related data tabs:** [if the entity has child relationships, show them in tabs]
**Action buttons:** Edit, Delete, Back to List
```

### Prompt 5D — Generate Tab-Based Master View (if module has multiple entities on one page)

```
## Generate Tab-Based Master Index

Read reference: `Modules/Transport/resources/views/transport-master/index.blade.php`

Generate a tab-based master index for [MODULE_NAME] that shows multiple entities:

**Tabs:**
1. [Tab 1 Name] — shows [Entity1] list
2. [Tab 2 Name] — shows [Entity2] list
3. [Tab 3 Name] — shows [Entity3] list
...

**Pattern:**
- Bootstrap 5 nav-tabs
- Each tab loads an @include partial: `[module]::partials.[entity]._list`
- Active tab remembered via URL hash or session

**CRITICAL:** Do NOT load ALL tab data on initial page load.
Use AJAX to load tab content when clicked:
```javascript
// Alpine.js tab loading
document.querySelectorAll('[data-tab-url]').forEach(tab => {
    tab.addEventListener('click', function() {
        fetch(this.dataset.tabUrl)
            .then(r => r.text())
            .then(html => document.getElementById(this.dataset.target).innerHTML = html);
    });
});
```
```

### Quality Gate 5
- [ ] All views use `<x-backend.layouts.app>` wrapper
- [ ] Breadcrumbs present on every page
- [ ] Forms have `@csrf` and `@method` where needed
- [ ] Error display uses `@error` pattern
- [ ] Tables use `@forelse`/`@empty`
- [ ] Delete uses SweetAlert2 confirmation
- [ ] No hardcoded route names like `central-127.0.0.1.*`
- [ ] Pagination present on all list views

---

## Phase 6 — Security Hardening

### Prompt 6A — Security Audit + Fix

```
## Security Hardening

Read the completed module code in `Modules/[MODULE_NAME]/`.

Verify and fix ALL of the following:

1. **Gate::authorize()** on EVERY public controller method
2. **FormRequest** on every store()/update() — authorize() returns Gate check, NOT `return true`
3. **$request->validated()** used everywhere — NO `$request->all()`
4. **EnsureTenantHasModule** middleware on route group in tenant.php
5. **No `is_super_admin`** in any $fillable or $request->only()
6. **No `::all()` or unbounded `::get()`** — all queries scoped and paginated
7. **No `dd()`, `dump()`, `var_dump()`** in any code
8. **No hardcoded API keys** — all secrets via `config()` / `env()`
9. **No `$request->all()` in Log statements** — log only specific fields
10. **Permission naming consistent** — all use `[module-name].[resource].[action]`
11. **Central models not queried from tenant context** — wrap in `tenancy()->central()`
12. **SoftDeletes** on all models

Generate a Permission Seeder: `Modules/[MODULE_NAME]/database/seeders/[MODULE_NAME]PermissionSeeder.php`
- All CRUD permissions for every resource
- Special permissions (generate, export, publish, etc.)

Run `/review` on the module and fix any issues found.
```

### Quality Gate 6
- [ ] `grep -r "request->all()" Modules/[MODULE_NAME]/` returns 0 results
- [ ] `grep -r "::all()" Modules/[MODULE_NAME]/app/Http/Controllers/` returns 0 results
- [ ] `grep -r "dd(" Modules/[MODULE_NAME]/` returns 0 results (excluding comments)
- [ ] `grep -rL "Gate::authorize" Modules/[MODULE_NAME]/app/Http/Controllers/` returns 0 files
- [ ] Permission seeder runs without errors

---

## Phase 7 — Testing

### Prompt 7A — Generate Unit Tests

```
## Generate Unit Tests

Read:
- `AI_Brain/rules/testing.md` — Pest 4.x rules
- `AI_Brain/templates/test-unit.md` — unit test template
- Existing tests: `tests/Unit/SmartTimetable/` for reference

Generate Pest 4.x unit tests for [MODULE_NAME]:

**File:** `tests/Unit/[MODULE_NAME]/[Entity]Test.php`

For each model, test:
1. Model can be instantiated
2. Fillable fields are correct
3. Casts are correct
4. Relationships return correct types
5. Soft delete works
6. Scopes (if any) return correct results

**Syntax:** Use `it()` or `test()` — NOT PHPUnit classes.
**Table names:** Must include prefix in assertions: `[prefix]_entities` not `entities`
**No hardcoded IDs** — use factories or mock data

Run: `/test [MODULE_NAME]`
```

### Prompt 7B — Generate Feature Tests

```
## Generate Feature Tests

Read: `AI_Brain/templates/test-feature-tenant.md`

Generate Pest feature tests for [MODULE_NAME]:

**File:** `Modules/[MODULE_NAME]/tests/Feature/[Entity]ControllerTest.php`

For each controller, test:
1. `index` returns 200 for authorized user
2. `index` returns 403 for unauthorized user
3. `store` creates record with valid data
4. `store` returns 422 for invalid data
5. `update` modifies existing record
6. `destroy` soft-deletes record
7. `restore` restores soft-deleted record

Run: `/test [MODULE_NAME]`
```

### Quality Gate 7
- [ ] All tests pass: `./vendor/bin/pest tests/Unit/[MODULE_NAME]/`
- [ ] Test coverage: at least 2 tests per controller method
- [ ] Both success AND failure paths tested

---

## Phase 8 — Code Review & AI Brain Update

### Prompt 8A — Code Review

```
## Code Review

Run `/review` on `Modules/[MODULE_NAME]/`.

Check for:
1. Security: auth, validation, mass assignment
2. Tenancy: no cross-layer imports, correct DB context
3. Performance: N+1 queries, unbounded selects, missing eager loading
4. Code quality: naming consistency, dead code, backup files

Fix all issues found.
```

### Prompt 8B — Update AI Brain

```
## Update AI Brain

The [MODULE_NAME] module is now complete. Update the AI Brain:

1. `AI_Brain/memory/modules-map.md`:
   - Add row to tenant modules table with accurate controller/model/service/request counts
   - Add to Module Completion Detail table

2. `AI_Brain/state/progress.md`:
   - Add entry with completion % and date
   - List what's complete and what's pending (if any)

3. `AI_Brain/lessons/known-issues.md`:
   - Add any known limitations or gotchas discovered during development

4. `AI_Brain/state/decisions.md`:
   - Add any architectural decisions made during development
```

### Quality Gate 8
- [ ] Code review returns 0 critical issues
- [ ] AI Brain files updated with accurate data
- [ ] All counts verified against actual filesystem

---

## Phase 9 — Integration & Deployment

### What YOU do (Manual)

1. **Run tenant migrations:** `php artisan tenants:migrate`
2. **Seed permissions:** `php artisan tenants:seed --class="Modules\[MODULE_NAME]\Database\Seeders\[MODULE_NAME]PermissionSeeder"`
3. **Assign permissions to roles** via the admin UI
4. **Test in browser** — walk through every screen manually
5. **Verify tenant isolation** — login as two different tenants, confirm data separation
6. **Cache routes:** `php artisan route:cache` — verify no errors
7. **Git commit** with descriptive message

### Prompt 9A — Pre-Deployment Checklist

```
## Pre-Deployment Verification

Verify the [MODULE_NAME] module is ready for deployment:

1. `php artisan route:list --path=[module-name]` — all routes resolve
2. `php artisan route:cache` — no errors
3. All migrations run: `php artisan tenants:migrate --pretend`
4. All seeders run without errors
5. No `dd()` or `dump()` in any file
6. No hardcoded URLs or API keys
7. No backup files (`*_backup*`, `*_copy*`, `* copy.*`)
8. All tests pass: `/test [MODULE_NAME]`

Report any issues found.
```

---

## What You Must Create Manually

These items CANNOT be generated by Claude and require human input:

| Item | Why Manual | When |
|------|-----------|------|
| **Wireframe/UI mockups** | Claude needs visual reference for forms and layouts | Phase 1 |
| **Business rules** | Domain knowledge about school operations | Phase 1 |
| **Field labels and dropdown values** | Language-specific, school-specific terminology | Phase 1 |
| **Branding/CSS customization** | Visual design decisions | Phase 5 |
| **Permission assignment to roles** | Business decision about who can do what | Phase 9 |
| **Browser manual testing** | Cannot be automated — visual verification | Phase 9 |
| **Tenant data verification** | Login as different tenants, check isolation | Phase 9 |
| **Production deployment** | Server config, DNS, SSL | Phase 9 |
| **Stakeholder demo/approval** | Human sign-off | Phase 9 |

### What YOU Should Provide to Claude for Best Results

For each module, prepare a **Module Input Document** with:

```markdown
# [MODULE_NAME] — Claude Input Document

## 1. Screens
| Screen | Type | Fields | Notes |
|--------|------|--------|-------|
| Vehicle List | Index | name, number, type, status | filterable by type |
| Add Vehicle | Create | name, number, type_id, capacity, driver_id, photo | two-column layout |
...

## 2. Relationships
- Vehicle belongs to VehicleType
- Vehicle has many Trips
- Vehicle has many MaintenanceRecords
...

## 3. Business Rules
- Cannot delete a vehicle with active trips
- Vehicle number must be unique within the tenant
- Status changes must be logged
...

## 4. Dropdown Sources
- vehicle_type: from `tpt_vehicle_types` table
- driver: from `sch_teachers` where role = 'driver'
...

## 5. Special Features
- CSV import for bulk vehicle creation
- PDF export of vehicle register
- Dashboard with chart (vehicles by type)
...
```

---

## Quality Gates — Complete Checklist

Run this after EVERY module is complete:

```bash
# 1. Lint check
php artisan route:list --path=[module-name]

# 2. No security violations
grep -r "\$request->all()" Modules/[MODULE_NAME]/app/Http/Controllers/
grep -r "::all()" Modules/[MODULE_NAME]/app/Http/Controllers/
grep -r "dd(" Modules/[MODULE_NAME]/app/ | grep -v "//"
grep -rL "Gate::authorize" Modules/[MODULE_NAME]/app/Http/Controllers/

# 3. Tests pass
./vendor/bin/pest tests/Unit/[MODULE_NAME]/
./vendor/bin/pest Modules/[MODULE_NAME]/tests/

# 4. Route cache works
php artisan route:cache && php artisan route:clear

# 5. Migration works
php artisan tenants:migrate --pretend
```

---

## Prompt Library

### Quick Reference — Copy-Paste Prompts

| # | Phase | Prompt | Use When |
|---|-------|--------|----------|
| 1A | Requirement | Generate RBS Entry | Starting a new module |
| 1B | Requirement | Generate Feature Spec | After RBS is approved |
| 2A | Schema | Generate DDL + Migration | After feature spec |
| 2B | Schema | Generate Seeders | After DDL |
| 3A | Scaffolding | Scaffold Module | After schema |
| 4A | Backend | Generate Controllers + Routes | After scaffold |
| 4B | Backend | Generate Services | For complex logic |
| 5A | Frontend | Generate Index View | Per entity |
| 5B | Frontend | Generate Create/Edit Form | Per entity |
| 5C | Frontend | Generate Show View | Per entity |
| 5D | Frontend | Generate Tab-Based Master | For multi-entity modules |
| 6A | Security | Security Hardening | After all code is written |
| 7A | Testing | Generate Unit Tests | After security |
| 7B | Testing | Generate Feature Tests | After unit tests |
| 8A | Review | Code Review | After testing |
| 8B | Review | Update AI Brain | After review |
| 9A | Deploy | Pre-Deployment Check | Before going live |

### Module Development Sequence (Optimal Order)

For a typical module with 5 entities:

```
Day 1 AM:  Prompt 1A (RBS) → Review → Prompt 1B (Feature Spec)
Day 1 PM:  Prompt 2A (DDL + Migration) → Review DDL → Prompt 2B (Seeders)
Day 2 AM:  Prompt 3A (Scaffold all models) → Prompt 4A (All controllers + routes)
Day 2 PM:  Prompt 4B (Services if needed) → Run migrations → Verify routes
Day 3 AM:  Prompt 5A-5D (All views — run for each entity)
Day 3 PM:  Prompt 6A (Security hardening) → Run quality gate checks
Day 4 AM:  Prompt 7A + 7B (All tests) → Fix failures
Day 4 PM:  Prompt 8A (Code review) → Prompt 8B (AI Brain) → Prompt 9A (Deploy check)
Day 5:     Manual testing in browser → Permission assignment → Done
```

**5 working days per module with Claude acceleration.**

---

## Example: Building the Hostel Module (Step by Step)

### Step 1 — You write the Module Input Document:
```
Module: HostelManagement
Prefix: hos_
Screens: Hostel List, Room Setup, Student Allotment, Attendance, Mess Menu, Fee, Reports
Business Rules: Room capacity cannot be exceeded, Gender-based allocation, etc.
```

### Step 2 — Run Prompt 1A with your input → Claude generates RBS

### Step 3 — Run Prompt 1B → Claude generates Feature Spec with all fields and relationships

### Step 4 — Run Prompt 2A → Claude generates 8 CREATE TABLE statements + Laravel migration

### Step 5 — You review DDL, approve → Run Prompt 2B → Seeders created

### Step 6 — Run Prompt 3A → 8 Models, module.json, providers created

### Step 7 — Run Prompt 4A → 8 Controllers, 16 FormRequests, routes registered

### Step 8 — Run Prompts 5A-5D → 24 Blade views (index + create + edit + show × 6 entities + 1 master tab + partials)

### Step 9 — Run Prompt 6A → Gate checks verified, permission seeder created

### Step 10 — Run Prompts 7A + 7B → 40+ tests written and passing

### Step 11 — Run Prompts 8A + 8B → Code reviewed, AI Brain updated

### Step 12 — Run Prompt 9A → Pre-deployment check passes

### Step 13 — You: migrate, seed, assign permissions, test in browser → DONE

**Total: ~5 days for a complete module with 8 entities, 24 views, 8 controllers, 40 tests.**
