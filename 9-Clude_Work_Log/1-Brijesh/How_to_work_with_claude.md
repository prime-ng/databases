# Prompt:
Now you have understood my Project and you also know what type of output we are looking for. You have seen what type of Frontend Design we want. I want to get 100% accurate output from you which should be similer to the output we have created. Now Give me a detailed plan for below items :
- Give me the complete process how should I work with you to generate every outcome starting from Requirement Creation and upto Fully Developed and tested Application. 
- First give me all the steps I need to follow to complete the entire development lifecycle with you.
- Then provide me Prompts for every steps which I need to use to provide you input and ask for the requirement output.
- Also provide me detail if anything I need to create mannualy to provide.
- Provide me a complete blueprint of how should I work with you to get expected outcome with 100% accuracy.
- Store the Output into "databases/3-Design_Architecture" folder

# Responce:
## Table of Contents
   12
   13 1. [Development Lifecycle Overview](#1-development-lifecycle-overview)
   14 2. [Phase 1 — Requirement Creation](#phase-1--requirement-creation)
   15 3. [Phase 2 — Database Schema Design](#phase-2--database-schema-design)
   16 4. [Phase 3 — Module Scaffolding](#phase-3--module-scaffolding)
   17 5. [Phase 4 — Backend Development](#phase-4--backend-development)
   18 6. [Phase 5 — Frontend Development](#phase-5--frontend-development)
   19 7. [Phase 6 — Security Hardening](#phase-6--security-hardening)
   20 8. [Phase 7 — Testing](#phase-7--testing)
   21 9. [Phase 8 — Code Review & AI Brain Update](#phase-8--code-review--ai-brain-update)
   22 10. [Phase 9 — Integration & Deployment](#phase-9--integration--deployment)
   23 11. [What You Must Create Manually](#what-you-must-create-manually)
   24 12. [Quality Gates](#quality-gates)
   25 13. [Prompt Library — Complete Reference](#prompt-library)
   26
   27 ---
   28
   29 ## 1. Development Lifecycle Overview
   30
   31 ```
   32 ┌──────────────────────────────────────────────────────────────────────┐
   33 │                    DEVELOPMENT LIFECYCLE (per module)                 │
   34 │                                                                      │
   35 │  Phase 1          Phase 2          Phase 3          Phase 4          │
   36 │  REQUIREMENT  →   DB SCHEMA    →   SCAFFOLDING  →   BACKEND         │
   37 │  (Manual+Claude)  (Claude)         (Claude)         (Claude)         │
   38 │  RBS document     DDL SQL          Models           Controllers      │
   39 │  Menu mapping     Migrations       Routes           Services         │
   40 │  Wireframes       Seeders          module.json      FormRequests     │
   41 │                                                                      │
   42 │  Phase 5          Phase 6          Phase 7          Phase 8          │
   43 │  FRONTEND     →   SECURITY     →   TESTING      →   REVIEW          │
   44 │  (Claude)         (Claude)         (Claude)         (Claude)         │
   45 │  Blade views      Gate::authorize  Pest tests       Code review      │
   46 │  Components       Policies         Feature tests    AI Brain update  │
   47 │  Alpine.js        FormRequest auth Unit tests       known-issues.md  │
   48 │                                                                      │
   49 │  Phase 9                                                             │
   50 │  DEPLOY                                                              │
   51 │  (Manual)                                                            │
   52 │  Tenant migrate                                                      │
   53 │  Route cache                                                         │
   54 │  Seed permissions                                                    │
   55 └──────────────────────────────────────────────────────────────────────┘
   56
   57 Each phase has:
   58   ✅ A ready-to-use PROMPT (copy-paste into Claude)
   59   ✅ INPUT files Claude needs to read
   60   ✅ OUTPUT files Claude will create/modify
   61   ✅ QUALITY GATE (verification before moving to next phase)
   62 ```
   63
   64 ---
   65
   66 ## Phase 1 — Requirement Creation
   67
   68 ### What YOU do (Manual)
   69
   70 1. **Write the RBS entry** for the module/sub-module following the existing format in `2-Project_Planning/1-RBS/PrimeAI_RBS_Menu_Mapping_v2.0.md`
   71 2. **Create wireframe sketches** (paper/Figma/Balsamiq) for each screen — at minimum:
   72    - Index page (list view with filters)
   73    - Create/Edit form (all fields, tabs if multi-step)
   74    - Show page (detail view)
   75    - Any special screens (dashboard, reports, calendar)
   76 3. **Define business rules** — what happens on create/update/delete, cascade behaviors, status workflows
   77
   78 ### What Claude does
   79
   80 Claude can help you refine and expand requirements if you give it the basic idea.
   81
   82 ### Prompt 1A — Generate RBS from Module Description
   83
   84 ```
   85 ## Generate RBS Entry
   86
   87 Read the existing RBS format from:
   88 - `2-Project_Planning/1-RBS/PrimeAI_RBS_Menu_Mapping_v2.0.md` (first 100 lines for format)
   89
   90 Now generate a complete RBS entry for this new module:
   91
   92 **Module Name:** [MODULE_NAME]
   93 **Module Code:** [X] (single letter from RBS)
   94 **Table Prefix:** [prefix_]
   95 **Database:** tenant_db
   96 **Description:** [Brief description of what this module does]
   97
   98 **Screens/Menus I need:**
   99 1. [Screen 1 name] — [what it does]
  100 2. [Screen 2 name] — [what it does]
  101 3. [Screen 3 name] — [what it does]
  102 ...
  103
  104 **Business Rules:**
  105 - [Rule 1]
  106 - [Rule 2]
  107 ...
  108
  109 Generate the RBS entry in the EXACT format used in PrimeAI_RBS_Menu_Mapping_v2.0.md with:
  110 - Functionality codes (F.X1.1)
  111 - Task codes (T.X1.1.1)
  112 - Sub-task codes (ST.X1.1.1.1)
  113 - Table references
  114 - Menu hierarchy
  115
  116 Store the output in: `2-Project_Planning/1-RBS/[MODULE_NAME]_RBS.md`
  117 ```
  118
  119 ### Prompt 1B — Generate Detailed Feature Specification from RBS
  120
  121 ```
  122 ## Generate Feature Specification
  123
  124 Read the RBS entry for [MODULE_NAME] from:
  125 - `2-Project_Planning/1-RBS/[MODULE_NAME]_RBS.md`
  126
  127 Also read the AI Brain context:
  128 - `AI_Brain/memory/project-context.md`
  129 - `AI_Brain/memory/tenancy-map.md`
  130 - `AI_Brain/rules/module-rules.md`
  131
  132 Generate a detailed Feature Specification document that includes:
  133
  134 1. **Entity Relationship Diagram** (text-based) showing all tables and relationships
  135 2. **Screen-by-Screen Specification:**
  136    - For each screen: fields, field types, validation rules, dropdown sources
  137    - CRUD operations and their business logic
  138    - Status workflows (if any)
  139 3. **API Endpoints** (if needed) — RESTful routes with request/response format
  140 4. **Permissions** — list all Gate permissions needed (format: `module-name.resource.action`)
  141 5. **Dependencies** — which other modules this depends on (SchoolSetup, StudentProfile, etc.)
  142
  143 Store the output in: `2-Project_Planning/3-Feature_Specs/[MODULE_NAME]_FeatureSpec.md`
  144 ```
  145
  146 ### Quality Gate 1
  147 - [ ] RBS entry covers ALL screens from your wireframes
  148 - [ ] Every screen has at least 2 functionalities with tasks and sub-tasks
  149 - [ ] Table names use correct prefix convention
  150 - [ ] Business rules are documented
  151
  152 ---
  153
  154 ## Phase 2 — Database Schema Design
  155
  156 ### What YOU do
  157 - Review the generated DDL and confirm table structure
  158 - Check column names match your wireframe field names
  159
  160 ### Prompt 2A — Generate Database Schema (DDL)
  161
  162 ```
  163 ## Generate Database Schema
  164
  165 Read these files:
  166 - `2-Project_Planning/3-Feature_Specs/[MODULE_NAME]_FeatureSpec.md`
  167 - `AI_Brain/rules/tenancy-rules.md` — for table naming rules
  168 - `databases/1-master_dbs/1-DDLs/tenant_db_v2.sql` (first 100 lines for format reference)
  169
  170 Generate the DDL SQL for all tables in the [MODULE_NAME] module.
  171
  172 **Rules (MUST follow):**
  173 1. Table prefix: `[prefix_]` (e.g., `hos_` for hostel, `acc_` for accounting)
  174 2. Every table MUST have: `id`, `is_active`, `created_by`, `created_at`, `updated_at`, `deleted_at`
  175 3. Index ALL foreign keys
  176 4. Junction tables suffix: `_jnt`
  177 5. JSON columns suffix: `_json`
  178 6. Boolean columns prefix: `is_` or `has_`
  179 7. Use `BIGINT UNSIGNED` for all IDs
  180 8. Use `VARCHAR(255)` for names, `TEXT` for descriptions
  181 9. Add `COMMENT` on every column
  182
  183 Generate:
  184 1. **DDL SQL file** — all CREATE TABLE statements
  185 2. **Laravel Migration file** — for `database/migrations/tenant/`
  186
  187 Store SQL in: `databases/2-Tenant_Modules/[N]-[MODULE_NAME]/DDL/[prefix]_tables_v1.sql`
  188 Store migration in: `database/migrations/tenant/YYYY_MM_DD_create_[prefix]_tables.php`
  189 ```
  190
  191 ### Prompt 2B — Generate Seeders
  192
  193 ```
  194 ## Generate Database Seeders
  195
  196 Read the DDL from: `databases/2-Tenant_Modules/[N]-[MODULE_NAME]/DDL/[prefix]_tables_v1.sql`
  197
  198 Generate Laravel seeders for:
  199 1. **Lookup/config tables** — pre-populate with standard data (types, statuses, categories)
  200 2. **Demo data seeder** — realistic sample data for testing (10-20 records per table)
  201
  202 Follow the pattern in: `AI_Brain/templates/tenant-migration.md`
  203
  204 Store in: `Modules/[MODULE_NAME]/database/seeders/`
  205 ```
  206
  207 ### Quality Gate 2
  208 - [ ] All tables from the feature spec exist in DDL
  209 - [ ] Foreign keys match referenced tables
  210 - [ ] Required columns (id, is_active, created_by, timestamps, deleted_at) present on ALL tables
  211 - [ ] Migration runs without errors: `php artisan tenants:migrate --pretend`
  212
  213 ---
  214
  215 ## Phase 3 — Module Scaffolding
  216
  217 ### What YOU do
  218 - Nothing — Claude generates everything
  219
  220 ### Prompt 3A — Scaffold Module Structure
  221
  222 ```
  223 ## Scaffold New Module
  224
  225 Read these references:
  226 - `AI_Brain/memory/modules-map.md` — module structure pattern
  227 - `AI_Brain/templates/module-structure.md`
  228 - `AI_Brain/templates/model.md`
  229 - `AI_Brain/rules/module-rules.md`
  230
  231 Create the complete module scaffold for [MODULE_NAME]:
  232
  233 **Module Config:**
  234 - Name: [MODULE_NAME]
  235 - Alias: [module-name]
  236 - Table prefix: [prefix_]
  237 - Route prefix: /[module-name]/*
  238
  239 **Generate these files:**
  240
  241 1. `module.json` — module config with providers
  242 2. `composer.json` — PSR-4 autoloading
  243 3. `app/Providers/[MODULE_NAME]ServiceProvider.php`
  244 4. `app/Providers/RouteServiceProvider.php`
  245 5. `routes/web.php` — empty route group with correct middleware
  246 6. `routes/api.php` — empty API route group
  247
  248 **For each table in the DDL, generate:**
  249 7. `app/Models/[EntityName].php` — following `AI_Brain/templates/model.md` pattern:
  250    - Correct `$table` with prefix
  251    - All `$fillable` columns (excluding id, timestamps, deleted_at)
  252    - `$casts` for booleans, JSON, dates
  253    - `use SoftDeletes`
  254    - All relationships (BelongsTo, HasMany, BelongsToMany)
  255
  256 Store all files in: `Modules/[MODULE_NAME]/`
  257
  258 **CRITICAL RULES:**
  259 - Models MUST use the exact table name from DDL
  260 - $fillable MUST include `created_by`
  261 - NEVER include `is_super_admin`, `remember_token` in $fillable
  262 - All BelongsTo relationships must match FK column names
  263 ```
  264
  265 ### Quality Gate 3
  266 - [ ] `module.json` exists and is valid JSON
  267 - [ ] Every DDL table has a corresponding Model file
  268 - [ ] Every Model has `use SoftDeletes`
  269 - [ ] Every Model has `created_by` in `$fillable`
  270 - [ ] `composer.json` autoload namespace matches module name
  271
  272 ---
  273
  274 ## Phase 4 — Backend Development
  275
  276 ### What YOU do
  277 - Review generated controllers match your wireframe flows
  278 - Provide any complex business logic rules Claude needs
  279
  280 ### Prompt 4A — Generate Controllers + FormRequests + Routes
  281
  282 ```
  283 ## Generate Backend — Controllers, FormRequests, Routes
  284
  285 Read these files:
  286 - `2-Project_Planning/3-Feature_Specs/[MODULE_NAME]_FeatureSpec.md`
  287 - `AI_Brain/templates/module-controller.md` — controller pattern
  288 - `AI_Brain/templates/form-request.md` — FormRequest pattern
  289 - `AI_Brain/rules/module-rules.md`
  290 - Reference controller: `Modules/Transport/app/Http/Controllers/VehicleController.php` (for a well-structured example)
  291
  292 For the [MODULE_NAME] module, generate:
  293
  294 ### For each resource entity:
  295
  296 **1. Controller** (`app/Http/Controllers/[Entity]Controller.php`):
  297 - `index()` — paginated list with eager loading, Gate::authorize
  298 - `create()` — load form dropdowns, Gate::authorize
  299 - `store()` — use FormRequest, `$request->validated()`, activity log, DB::transaction
  300 - `show()` — load with relationships, Gate::authorize
  301 - `edit()` — same as create + load existing record, Gate::authorize
  302 - `update()` — use FormRequest, `$request->validated()`, activity log, DB::transaction
  303 - `destroy()` — soft delete, Gate::authorize, activity log
  304 - `trashed()` — list soft-deleted records, Gate::authorize
  305 - `restore()` — restore soft-deleted, Gate::authorize
  306 - `forceDelete()` — permanent delete, Gate::authorize
  307 - `toggleStatus()` — toggle is_active, Gate::authorize
  308
  309 **2. FormRequest** (`app/Http/Requests/Store[Entity]Request.php`, `Update[Entity]Request.php`):
  310 - `authorize()` → use Gate policy check (NOT `return true`)
  311 - `rules()` → validation rules matching DDL column constraints
  312 - `messages()` → user-friendly error messages
  313
  314 **3. Routes** (`routes/web.php`):
  315 - `Route::resource('[entity-name]', [Entity]Controller::class)`
  316 - `Route::get('[entity-name]/trash/view', ...)` — BEFORE Route::resource
  317 - `Route::get('[entity-name]/{id}/restore', ...)`
  318 - `Route::delete('[entity-name]/{id}/force-delete', ...)`
  319 - `Route::post('[entity-name]/{id}/toggle-status', ...)`
  320
  321 **ALSO register in `routes/tenant.php`:**
  322 - Add the route group under the module prefix with `['auth', 'verified', 'module:[MODULE_NAME]']` middleware
  323
  324 **CRITICAL RULES:**
  325 - ALWAYS use `$request->validated()` — NEVER `$request->all()`
  326 - ALWAYS add `Gate::authorize()` as FIRST line of every public method
  327 - Permission naming: `[module-name].[resource].[action]` (e.g., `hostel.room.create`)
  328 - Use `DB::transaction()` for multi-table writes
  329 - Call `activityLog()` on every mutation
  330 - Eager load relationships in index(): `->with(['relation1', 'relation2'])`
  331 - Paginate: `->paginate(15)` — NEVER use `::all()` or `::get()` unbounded
  332 ```
  333
  334 ### Prompt 4B — Generate Services (if complex business logic)
  335
  336 ```
  337 ## Generate Service Class
  338
  339 Read the Feature Specification for [MODULE_NAME].
  340
  341 The following business logic is too complex for a controller and needs a dedicated service:
  342
  343 **Service Name:** [ServiceName]Service
  344 **Location:** `Modules/[MODULE_NAME]/app/Services/[ServiceName]Service.php`
  345
  346 **Methods needed:**
  347 1. `[methodName]($params)` — [describe what it does]
  348 2. `[methodName]($params)` — [describe what it does]
  349 ...
  350
  351 **Business Rules:**
  352 - [Rule 1]
  353 - [Rule 2]
  354
  355 Follow the pattern in `AI_Brain/templates/module-service.md`.
  356 Use constructor injection for dependencies.
  357 Wrap multi-step operations in `DB::transaction()`.
  358 Add `\Log::info()` for important operations.
  359 ```
  360
  361 ### Quality Gate 4
  362 - [ ] Every controller method has `Gate::authorize()` as first line
  363 - [ ] Every `store()`/`update()` uses a FormRequest with `$request->validated()`
  364 - [ ] No `$request->all()` anywhere
  365 - [ ] No `::all()` or unbounded `::get()` in any query
  366 - [ ] `DB::transaction()` used for multi-table writes
  367 - [ ] `activityLog()` called on every create/update/delete
  368 - [ ] Routes registered in BOTH module `web.php` AND `routes/tenant.php`
  369 - [ ] `EnsureTenantHasModule` middleware applied on route group
  370
  371 ---
  372
  373 ## Phase 5 — Frontend Development
  374
  375 ### What YOU do
  376 - Provide wireframe screenshots or detailed descriptions of each screen
  377 - Specify any custom UI components needed
  378
  379 ### Prompt 5A — Generate Index (List) View
  380
  381 ```
  382 ## Generate Index View
  383
  384 Read these reference files for the EXACT pattern to follow:
  385 - `Modules/Transport/resources/views/transport-master/index.blade.php` (tab-based index)
  386 - OR `Modules/SchoolSetup/resources/views/building/index.blade.php` (simple index)
  387 - `resources/views/components/backend/` (available Blade components)
  388
  389 Generate the index view for [ENTITY] in [MODULE_NAME]:
  390
  391 **File:** `Modules/[MODULE_NAME]/resources/views/[entity]/index.blade.php`
  392
  393 **Layout Pattern (MUST follow exactly):**
  394 ```blade
  395 <x-backend.layouts.app>
  396     <x-backend.components.breadcrum title="[Title]" :links="[...]" />
  397     <div class="container-fluid">
  398         <div class="row">
  399             <div class="col-sm-12">
  400                 <div class="card mb-4">
  401                     <x-backend.card.header title="[Title]" url="[module].[entity]" />
  402                     <div class="card-body">
  403                         <table class="table table-sm">
  404                             ...
  405                         </table>
  406                     </div>
  407                 </div>
  408             </div>
  409         </div>
  410     </div>
  411 </x-backend.layouts.app>
  412 ```
  413
  414 **Columns to display:** [list columns]
  415 **Filters needed:** [list filters]
  416 **Action buttons:** Edit, Delete, Toggle Status, View (icons from AdminLTE)
  417 **Pagination:** Use `{{ $entities->links() }}`
  418
  419 **Features:**
  420 - @forelse / @empty pattern for no-data message
  421 - Status badge: `<span class="badge bg-success">Active</span>` / `<span class="badge bg-danger">Inactive</span>`
  422 - SweetAlert2 for delete confirmation
  423 - Toast notifications for success/error messages
  424 ```
  425
  426 ### Prompt 5B — Generate Create/Edit Form View
  427
  428 ```
  429 ## Generate Create/Edit Form View
  430
  431 Read these reference files:
  432 - `Modules/Transport/resources/views/driver_helper/create.blade.php`
  433 - `Modules/SchoolSetup/resources/views/organization/create.blade.php`
  434
  435 Generate the create form for [ENTITY] in [MODULE_NAME]:
  436
  437 **File:** `Modules/[MODULE_NAME]/resources/views/[entity]/create.blade.php`
  438
  439 **Form fields (from DDL/Feature Spec):**
  440 | Field | Type | Label | Required | Notes |
  441 |-------|------|-------|----------|-------|
  442 | name | text | Name | Yes | max 255 |
  443 | description | textarea | Description | No | |
  444 | type_id | select | Type | Yes | dropdown from [table] |
  445 | start_date | date | Start Date | Yes | |
  446 | is_active | checkbox | Active | No | default true |
  447 | document | file | Upload Document | No | pdf, max 5MB |
  448 ...
  449
  450 **Layout:** [Single column / Two column / Tabbed]
  451 **Submit URL:** `route('[module].[entity].store')`
  452 **Method:** POST with @csrf
  453
  454 **For Edit:** Same form but:
  455 - Method: PUT with @method('PUT')
  456 - Pre-fill all fields with `old('field', $entity->field)`
  457 - Submit URL: `route('[module].[entity].update', $entity)`
  458
  459 **CRITICAL:**
  460 - Use Bootstrap 5 classes: `form-control`, `form-select`, `form-check-input`
  461 - Error display: `@error('field') ... @enderror` pattern
  462 - All selects: `<option value="">-- Select --</option>` as first option
  463 - File inputs: show existing file link on edit
  464 ```
  465
  466 ### Prompt 5C — Generate Show (Detail) View
  467
  468 ```
  469 ## Generate Show/Detail View
  470
  471 Generate the show/detail view for [ENTITY]:
  472
  473 **File:** `Modules/[MODULE_NAME]/resources/views/[entity]/show.blade.php`
  474
  475 **Display fields:** [same as form fields but read-only]
  476 **Related data tabs:** [if the entity has child relationships, show them in tabs]
  477 **Action buttons:** Edit, Delete, Back to List
  478 ```
  479
  480 ### Prompt 5D — Generate Tab-Based Master View (if module has multiple entities on one page)
  481
  482 ```
  483 ## Generate Tab-Based Master Index
  484
  485 Read reference: `Modules/Transport/resources/views/transport-master/index.blade.php`
  486
  487 Generate a tab-based master index for [MODULE_NAME] that shows multiple entities:
  488
  489 **Tabs:**
  490 1. [Tab 1 Name] — shows [Entity1] list
  491 2. [Tab 2 Name] — shows [Entity2] list
  492 3. [Tab 3 Name] — shows [Entity3] list
  493 ...
  494
  495 **Pattern:**
  496 - Bootstrap 5 nav-tabs
  497 - Each tab loads an @include partial: `[module]::partials.[entity]._list`
  498 - Active tab remembered via URL hash or session
  499
  500 **CRITICAL:** Do NOT load ALL tab data on initial page load.
  501 Use AJAX to load tab content when clicked:
  502 ```javascript
  503 // Alpine.js tab loading
  504 document.querySelectorAll('[data-tab-url]').forEach(tab => {
  505     tab.addEventListener('click', function() {
  506         fetch(this.dataset.tabUrl)
  507             .then(r => r.text())
  508             .then(html => document.getElementById(this.dataset.target).innerHTML = html);
  509     });
  510 });
  511 ```
  512 ```
  513
  514 ### Quality Gate 5
  515 - [ ] All views use `<x-backend.layouts.app>` wrapper
  516 - [ ] Breadcrumbs present on every page
  517 - [ ] Forms have `@csrf` and `@method` where needed
  518 - [ ] Error display uses `@error` pattern
  519 - [ ] Tables use `@forelse`/`@empty`
  520 - [ ] Delete uses SweetAlert2 confirmation
  521 - [ ] No hardcoded route names like `central-127.0.0.1.*`
  522 - [ ] Pagination present on all list views
  523
  524 ---
  525
  526 ## Phase 6 — Security Hardening
  527
  528 ### Prompt 6A — Security Audit + Fix
  529
  530 ```
  531 ## Security Hardening
  532
  533 Read the completed module code in `Modules/[MODULE_NAME]/`.
  534
  535 Verify and fix ALL of the following:
  536
  537 1. **Gate::authorize()** on EVERY public controller method
  538 2. **FormRequest** on every store()/update() — authorize() returns Gate check, NOT `return true`
  539 3. **$request->validated()** used everywhere — NO `$request->all()`
  540 4. **EnsureTenantHasModule** middleware on route group in tenant.php
  541 5. **No `is_super_admin`** in any $fillable or $request->only()
  542 6. **No `::all()` or unbounded `::get()`** — all queries scoped and paginated
  543 7. **No `dd()`, `dump()`, `var_dump()`** in any code
  544 8. **No hardcoded API keys** — all secrets via `config()` / `env()`
  545 9. **No `$request->all()` in Log statements** — log only specific fields
  546 10. **Permission naming consistent** — all use `[module-name].[resource].[action]`
  547 11. **Central models not queried from tenant context** — wrap in `tenancy()->central()`
  548 12. **SoftDeletes** on all models
  549
  550 Generate a Permission Seeder: `Modules/[MODULE_NAME]/database/seeders/[MODULE_NAME]PermissionSeeder.php`
  551 - All CRUD permissions for every resource
  552 - Special permissions (generate, export, publish, etc.)
  553
  554 Run `/review` on the module and fix any issues found.
  555 ```
  556
  557 ### Quality Gate 6
  558 - [ ] `grep -r "request->all()" Modules/[MODULE_NAME]/` returns 0 results
  559 - [ ] `grep -r "::all()" Modules/[MODULE_NAME]/app/Http/Controllers/` returns 0 results
  560 - [ ] `grep -r "dd(" Modules/[MODULE_NAME]/` returns 0 results (excluding comments)
  561 - [ ] `grep -rL "Gate::authorize" Modules/[MODULE_NAME]/app/Http/Controllers/` returns 0 files
  562 - [ ] Permission seeder runs without errors
  563
  564 ---
  565
  566 ## Phase 7 — Testing
  567
  568 ### Prompt 7A — Generate Unit Tests
  569
  570 ```
  571 ## Generate Unit Tests
  572
  573 Read:
  574 - `AI_Brain/rules/testing.md` — Pest 4.x rules
  575 - `AI_Brain/templates/test-unit.md` — unit test template
  576 - Existing tests: `tests/Unit/SmartTimetable/` for reference
  577
  578 Generate Pest 4.x unit tests for [MODULE_NAME]:
  579
  580 **File:** `tests/Unit/[MODULE_NAME]/[Entity]Test.php`
  581
  582 For each model, test:
  583 1. Model can be instantiated
  584 2. Fillable fields are correct
  585 3. Casts are correct
  586 4. Relationships return correct types
  587 5. Soft delete works
  588 6. Scopes (if any) return correct results
  589
  590 **Syntax:** Use `it()` or `test()` — NOT PHPUnit classes.
  591 **Table names:** Must include prefix in assertions: `[prefix]_entities` not `entities`
  592 **No hardcoded IDs** — use factories or mock data
  593
  594 Run: `/test [MODULE_NAME]`
  595 ```
  596
  597 ### Prompt 7B — Generate Feature Tests
  598
  599 ```
  600 ## Generate Feature Tests
  601
  602 Read: `AI_Brain/templates/test-feature-tenant.md`
  603
  604 Generate Pest feature tests for [MODULE_NAME]:
  605
  606 **File:** `Modules/[MODULE_NAME]/tests/Feature/[Entity]ControllerTest.php`
  607
  608 For each controller, test:
  609 1. `index` returns 200 for authorized user
  610 2. `index` returns 403 for unauthorized user
  611 3. `store` creates record with valid data
  612 4. `store` returns 422 for invalid data
  613 5. `update` modifies existing record
  614 6. `destroy` soft-deletes record
  615 7. `restore` restores soft-deleted record
  616
  617 Run: `/test [MODULE_NAME]`
  618 ```
  619
  620 ### Quality Gate 7
  621 - [ ] All tests pass: `./vendor/bin/pest tests/Unit/[MODULE_NAME]/`
  622 - [ ] Test coverage: at least 2 tests per controller method
  623 - [ ] Both success AND failure paths tested
  624
  625 ---
  626
  627 ## Phase 8 — Code Review & AI Brain Update
  628
  629 ### Prompt 8A — Code Review
  630
  631 ```
  632 ## Code Review
  633
  634 Run `/review` on `Modules/[MODULE_NAME]/`.
  635
  636 Check for:
  637 1. Security: auth, validation, mass assignment
  638 2. Tenancy: no cross-layer imports, correct DB context
  639 3. Performance: N+1 queries, unbounded selects, missing eager loading
  640 4. Code quality: naming consistency, dead code, backup files
  641
  642 Fix all issues found.
  643 ```
  644
  645 ### Prompt 8B — Update AI Brain
  646
  647 ```
  648 ## Update AI Brain
  649
  650 The [MODULE_NAME] module is now complete. Update the AI Brain:
  651
  652 1. `AI_Brain/memory/modules-map.md`:
  653    - Add row to tenant modules table with accurate controller/model/service/request counts
  654    - Add to Module Completion Detail table
  655
  656 2. `AI_Brain/state/progress.md`:
  657    - Add entry with completion % and date
  658    - List what's complete and what's pending (if any)
  659
  660 3. `AI_Brain/lessons/known-issues.md`:
  661    - Add any known limitations or gotchas discovered during development
  662
  663 4. `AI_Brain/state/decisions.md`:
  664    - Add any architectural decisions made during development
  665 ```
  666
  667 ### Quality Gate 8
  668 - [ ] Code review returns 0 critical issues
  669 - [ ] AI Brain files updated with accurate data
  670 - [ ] All counts verified against actual filesystem
  671
  672 ---
  673
  674 ## Phase 9 — Integration & Deployment
  675
  676 ### What YOU do (Manual)
  677
  678 1. **Run tenant migrations:** `php artisan tenants:migrate`
  679 2. **Seed permissions:** `php artisan tenants:seed --class="Modules\[MODULE_NAME]\Database\Seeders\[MODULE_NAME]PermissionSeeder"`
  680 3. **Assign permissions to roles** via the admin UI
  681 4. **Test in browser** — walk through every screen manually
  682 5. **Verify tenant isolation** — login as two different tenants, confirm data separation
  683 6. **Cache routes:** `php artisan route:cache` — verify no errors
  684 7. **Git commit** with descriptive message
  685
  686 ### Prompt 9A — Pre-Deployment Checklist
  687
  688 ```
  689 ## Pre-Deployment Verification
  690
  691 Verify the [MODULE_NAME] module is ready for deployment:
  692
  693 1. `php artisan route:list --path=[module-name]` — all routes resolve
  694 2. `php artisan route:cache` — no errors
  695 3. All migrations run: `php artisan tenants:migrate --pretend`
  696 4. All seeders run without errors
  697 5. No `dd()` or `dump()` in any file
  698 6. No hardcoded URLs or API keys
  699 7. No backup files (`*_backup*`, `*_copy*`, `* copy.*`)
  700 8. All tests pass: `/test [MODULE_NAME]`
  701
  702 Report any issues found.
  703 ```
  704
  705 ---
  706
  707 ## What You Must Create Manually
  708
  709 These items CANNOT be generated by Claude and require human input:
  710
  711 | Item | Why Manual | When |
  712 |------|-----------|------|
  713 | **Wireframe/UI mockups** | Claude needs visual reference for forms and layouts | Phase 1 |
  714 | **Business rules** | Domain knowledge about school operations | Phase 1 |
  715 | **Field labels and dropdown values** | Language-specific, school-specific terminology | Phase 1 |
  716 | **Branding/CSS customization** | Visual design decisions | Phase 5 |
  717 | **Permission assignment to roles** | Business decision about who can do what | Phase 9 |
  718 | **Browser manual testing** | Cannot be automated — visual verification | Phase 9 |
  719 | **Tenant data verification** | Login as different tenants, check isolation | Phase 9 |
  720 | **Production deployment** | Server config, DNS, SSL | Phase 9 |
  721 | **Stakeholder demo/approval** | Human sign-off | Phase 9 |
  722
  723 ### What YOU Should Provide to Claude for Best Results
  724
  725 For each module, prepare a **Module Input Document** with:
  726
  727 ```markdown
  728 # [MODULE_NAME] — Claude Input Document
  729
  730 ## 1. Screens
  731 | Screen | Type | Fields | Notes |
  732 |--------|------|--------|-------|
  733 | Vehicle List | Index | name, number, type, status | filterable by type |
  734 | Add Vehicle | Create | name, number, type_id, capacity, driver_id, photo | two-column layout |
  735 ...
  736
  737 ## 2. Relationships
  738 - Vehicle belongs to VehicleType
  739 - Vehicle has many Trips
  740 - Vehicle has many MaintenanceRecords
  741 ...
  742
  743 ## 3. Business Rules
  744 - Cannot delete a vehicle with active trips
  745 - Vehicle number must be unique within the tenant
  746 - Status changes must be logged
  747 ...
  748
  749 ## 4. Dropdown Sources
  750 - vehicle_type: from `tpt_vehicle_types` table
  751 - driver: from `sch_teachers` where role = 'driver'
  752 ...
  753
  754 ## 5. Special Features
  755 - CSV import for bulk vehicle creation
  756 - PDF export of vehicle register
  757 - Dashboard with chart (vehicles by type)
  758 ...
  759 ```
  760
  761 ---
  762
  763 ## Quality Gates — Complete Checklist
  764
  765 Run this after EVERY module is complete:
  766
  767 ```bash
  768 # 1. Lint check
  769 php artisan route:list --path=[module-name]
  770
  771 # 2. No security violations
  772 grep -r "\$request->all()" Modules/[MODULE_NAME]/app/Http/Controllers/
  773 grep -r "::all()" Modules/[MODULE_NAME]/app/Http/Controllers/
  774 grep -r "dd(" Modules/[MODULE_NAME]/app/ | grep -v "//"
  775 grep -rL "Gate::authorize" Modules/[MODULE_NAME]/app/Http/Controllers/
  776
  777 # 3. Tests pass
  778 ./vendor/bin/pest tests/Unit/[MODULE_NAME]/
  779 ./vendor/bin/pest Modules/[MODULE_NAME]/tests/
  780
  781 # 4. Route cache works
  782 php artisan route:cache && php artisan route:clear
  783
  784 # 5. Migration works
  785 php artisan tenants:migrate --pretend
  786 ```
  787
  788 ---
  789
  790 ## Prompt Library
  791
  792 ### Quick Reference — Copy-Paste Prompts
  793
  794 | # | Phase | Prompt | Use When |
  795 |---|-------|--------|----------|
  796 | 1A | Requirement | Generate RBS Entry | Starting a new module |
  797 | 1B | Requirement | Generate Feature Spec | After RBS is approved |
  798 | 2A | Schema | Generate DDL + Migration | After feature spec |
  799 | 2B | Schema | Generate Seeders | After DDL |
  800 | 3A | Scaffolding | Scaffold Module | After schema |
  801 | 4A | Backend | Generate Controllers + Routes | After scaffold |
  802 | 4B | Backend | Generate Services | For complex logic |
  803 | 5A | Frontend | Generate Index View | Per entity |
  804 | 5B | Frontend | Generate Create/Edit Form | Per entity |
  805 | 5C | Frontend | Generate Show View | Per entity |
  806 | 5D | Frontend | Generate Tab-Based Master | For multi-entity modules |
  807 | 6A | Security | Security Hardening | After all code is written |
  808 | 7A | Testing | Generate Unit Tests | After security |
  809 | 7B | Testing | Generate Feature Tests | After unit tests |
  810 | 8A | Review | Code Review | After testing |
  811 | 8B | Review | Update AI Brain | After review |
  812 | 9A | Deploy | Pre-Deployment Check | Before going live |
  813
  814 ### Module Development Sequence (Optimal Order)
  815
  816 For a typical module with 5 entities:
  817
  818 ```
  819 Day 1 AM:  Prompt 1A (RBS) → Review → Prompt 1B (Feature Spec)
  820 Day 1 PM:  Prompt 2A (DDL + Migration) → Review DDL → Prompt 2B (Seeders)
  821 Day 2 AM:  Prompt 3A (Scaffold all models) → Prompt 4A (All controllers + routes)
  822 Day 2 PM:  Prompt 4B (Services if needed) → Run migrations → Verify routes
  823 Day 3 AM:  Prompt 5A-5D (All views — run for each entity)
  824 Day 3 PM:  Prompt 6A (Security hardening) → Run quality gate checks
  825 Day 4 AM:  Prompt 7A + 7B (All tests) → Fix failures
  826 Day 4 PM:  Prompt 8A (Code review) → Prompt 8B (AI Brain) → Prompt 9A (Deploy check)
  827 Day 5:     Manual testing in browser → Permission assignment → Done
  828 ```
  829
  830 **5 working days per module with Claude acceleration.**
  831
  832 ---
  833
  834 ## Example: Building the Hostel Module (Step by Step)
  835
  836 ### Step 1 — You write the Module Input Document:
  837 ```
  838 Module: HostelManagement
  839 Prefix: hos_
  840 Screens: Hostel List, Room Setup, Student Allotment, Attendance, Mess Menu, Fee, Reports
  841 Business Rules: Room capacity cannot be exceeded, Gender-based allocation, etc.
  842 ```
  843
  844 ### Step 2 — Run Prompt 1A with your input → Claude generates RBS
  845
  846 ### Step 3 — Run Prompt 1B → Claude generates Feature Spec with all fields and relationships
  847
  848 ### Step 4 — Run Prompt 2A → Claude generates 8 CREATE TABLE statements + Laravel migration
  849
  850 ### Step 5 — You review DDL, approve → Run Prompt 2B → Seeders created
  851
  852 ### Step 6 — Run Prompt 3A → 8 Models, module.json, providers created
  853
  854 ### Step 7 — Run Prompt 4A → 8 Controllers, 16 FormRequests, routes registered
  855
  856 ### Step 8 — Run Prompts 5A-5D → 24 Blade views (index + create + edit + show × 6 entities + 1 master tab + partials)
  857
  858 ### Step 9 — Run Prompt 6A → Gate checks verified, permission seeder created
  859
  860 ### Step 10 — Run Prompts 7A + 7B → 40+ tests written and passing
  861
  862 ### Step 11 — Run Prompts 8A + 8B → Code reviewed, AI Brain updated
  863
  864 ### Step 12 — Run Prompt 9A → Pre-deployment check passes
  865
  866 ### Step 13 — You: migrate, seed, assign permissions, test in browser → DONE
  867
  868 **Total: ~5 days for a complete module with 8 entities, 24 views, 8 controllers, 40 tests.**

  File created: 3-Design_Architecture/Development_Lifecycle_Blueprint_v1.0.md (868 lines)

  What's Inside

  9-Phase Development Lifecycle

  Phase 1: Requirement Creation (Manual + Claude)
  Phase 2: Database Schema Design (Claude)
  Phase 3: Module Scaffolding (Claude)
  Phase 4: Backend Development (Claude)
  Phase 5: Frontend Development (Claude)
  Phase 6: Security Hardening (Claude)
  Phase 7: Testing (Claude)
  Phase 8: Code Review & AI Brain Update (Claude)
  Phase 9: Integration & Deployment (Manual)

  17 Ready-to-Use Prompts

  ┌───────┬───────────────────────────────┬─────────────────────────────────────────────────────────┐
  │   #   │            Prompt             │                         Purpose                         │
  ├───────┼───────────────────────────────┼─────────────────────────────────────────────────────────┤
  │ 1A    │ Generate RBS Entry            │ Create requirement from module description              │
  ├───────┼───────────────────────────────┼─────────────────────────────────────────────────────────┤
  │ 1B    │ Generate Feature Spec         │ Expand RBS into detailed spec with fields/relationships │
  ├───────┼───────────────────────────────┼─────────────────────────────────────────────────────────┤
  │ 2A    │ Generate DDL + Migration      │ Create SQL schema + Laravel migration                   │
  ├───────┼───────────────────────────────┼─────────────────────────────────────────────────────────┤
  │ 2B    │ Generate Seeders              │ Lookup data + demo data                                 │
  ├───────┼───────────────────────────────┼─────────────────────────────────────────────────────────┤
  │ 3A    │ Scaffold Module               │ Models, providers, module.json, composer.json           │
  ├───────┼───────────────────────────────┼─────────────────────────────────────────────────────────┤
  │ 4A    │ Generate Controllers + Routes │ Full CRUD with Gate, FormRequests, routes               │
  ├───────┼───────────────────────────────┼─────────────────────────────────────────────────────────┤
  │ 4B    │ Generate Services             │ Complex business logic                                  │
  ├───────┼───────────────────────────────┼─────────────────────────────────────────────────────────┤
  │ 5A-5D │ Generate Views                │ Index, Create/Edit, Show, Tab-based master              │
  ├───────┼───────────────────────────────┼─────────────────────────────────────────────────────────┤
  │ 6A    │ Security Hardening            │ Verify all auth, validation, mass-assignment            │
  ├───────┼───────────────────────────────┼─────────────────────────────────────────────────────────┤
  │ 7A-7B │ Generate Tests                │ Unit + Feature tests (Pest 4.x)                         │
  ├───────┼───────────────────────────────┼─────────────────────────────────────────────────────────┤
  │ 8A-8B │ Code Review + Brain           │ Audit + update AI Brain                                 │
  ├───────┼───────────────────────────────┼─────────────────────────────────────────────────────────┤
  │ 9A    │ Pre-Deployment Check          │ Final verification                                      │
  └───────┴───────────────────────────────┴─────────────────────────────────────────────────────────┘

  What YOU Must Provide Manually

  - Wireframe/mockup sketches for each screen
  - Business rules (domain knowledge)
  - Field labels and dropdown values
  - Permission-to-role assignment
  - Browser testing + stakeholder approval

  Estimated Time Per Module

  ~5 working days with Claude: 1 day requirements → 1 day schema+scaffold → 1 day views → 1 day security+tests → 1 day review+deploy

  Included Example

  Full step-by-step walkthrough for building the Hostel module (8 entities, 24 views, 8 controllers, 40 tests).

✻ Worked for 5m 31s
