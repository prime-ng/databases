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


======================================================================================================================

## FINAL CHECKLIST (Both Types)                                                                                                                                                                           
- [ ] Table has: `id`, `is_active`, `created_by`, `created_at`, `updated_at`, `deleted_at`                                                                                                                
- [ ] Boolean columns prefixed with `is_` or `has_`                                                                                                                                                       
- [ ] JSON columns suffixed with `_json`                                                                                                                                                                  
- [ ] Junction tables suffixed with `_jnt`                                                                                                                                                                
- [ ] Foreign keys are indexed                                                                                                                                                                            
- [ ] Migration is additive (never modified existing one)                                                                                                                                                 
- [ ] Model has `$table` and `$fillable` defined                                                                                                                                                          
- [ ] Route in CORRECT file (web.php for prime, tenant.php for tenant)                                                                                                                                    
- [ ] View namespace is correct: `'<modulename>::<folder>.<file>'`                                                                                                                                        
- [ ] Shared components used from `resources/views/components/`                                                                                                                                           
```                                                                                                                                                                                                       
                                                                                                                                                                                                          
---                                                                                                                                                                                                       
                                                                                                                                                                                                          
### FILE 11: `project_docs/11-all-modules-controllers-models.md`                                                                                                                                          
                                                                                                                                                                                                          
Write a full reference table of all 27 modules listing their controllers and models:                                                                                                                      
                                                                                                                                                                                                          
**Format per module:**                                                                                                                                                                                    
```                                                                                                                                                                                                       
## <ModuleName> [PRIME/TENANT] — Status: X%                                                                                                                                                               
Table Prefix: <prefix>_*                                                                                                                                                                                  
Controllers: <count> | Models: <count>                                                                                                                                                                    
                                                                                                                                                                                                          
Controllers:                                                                                                                                                                                              
- ControllerName.php                                                                                                                                                                                      
                                                                                                                                                                                                          
Models:                                                                                                                                                                                                   
- ModelName.php                                                                                                                                                                                           
                                                                                                                                                                                                          
Views: Modules/<ModuleName>/resources/views/                                                                                                                                                              
Migrations: [central/tenant] → [path]                                                                                                                                                                     
Routes registered in: [routes/web.php / routes/tenant.php]                                                                                                                                                
```                                                                                                                                                                                                       
                                                                                                                                                                                                          
Use this data to fill it in:                                                                                                                                                                              
                                                                                                                                                                                                          
**PRIME MODULES:**                                                                                                                                                                                        
                                                                                                                                                                                                          
Billing [PRIME] — Central                                                                                                                                                                                 
Controllers (6): BillingCycleController, BillingManagementController, InvoicingAuditLogController, InvoicingController, InvoicingPaymentController, SubscriptionController                                
Models (6): BilTenantInvoice, BillOrgInvoicingModulesJnt, BillTenatEmailSchedule, BillingCycle, InvoicingAuditLog, InvoicingPayment                                                                       
                                                                                                                                                                                                          
Documentation [PRIME] — Central                                                                                                                                                                           
Controllers (3): DocumentationArticleController, DocumentationCategoryController, DocumentationController                                                                                                 
Models (2): Article, Category                                                                                                                                                                             
                                                                                                                                                                                                          
GlobalMaster [PRIME] — Central                                                                                                                                                                            
Controllers (15): AcademicSessionController, ActivityLogController, CityController, CountryController, DistrictController, DropdownController, GeographySetupController, GlobalMasterController,          
LanguageController, ModuleController, NotificationController, OrganizationController, PlanController, SessionBoardSetupController, StateController                                                        
Models (12): ActivityLog, Board, City, Country, District, Dropdown, DropdownNeed, Language, Media, Module, Plan, State                                                                                    
                                                                                                                                                                                                          
Prime [PRIME] — Central                                                                                                                                                                                   
Controllers (22): AcademicSessionController, ActivityLogController, BoardController, DropdownController, DropdownMgmtController, DropdownNeedController, EmailController, LanguageController,             
MenuController, NotificationController, PrimeAuthController, PrimeController, RolePermissionController, SalesPlanAndModuleMgmtController, SessionBoardSetupController, SettingController,                 
TenantController, TenantGroupController, TenantManagementController, UserController, UserRolePrmController                                                                                                
Models (27): AcademicSession, ActivityLog, Board, Domain, Dropdown, DropdownMgmtModel, DropdownNeed, DropdownNeedDropdown, DropdownNeedTableJnt, Language, Media, Menu, MenuModule, Permission, Role,     
Setting, Tenant, TenantGroup, TenantInvoice, TenantInvoiceModule, TenantInvoicingAuditLog, TenantInvoicingPayment, TenantPlan, TenantPlanBillingSchedule, TenantPlanModule, TenantPlanRate, User          
                                                                                                                                                                                                          
SystemConfig [PRIME] — Central                                                                                                                                                                            
Controllers (3): MenuController, SettingController, SystemConfigController                                                                                                                                
Models (3): Menu, Setting, Translation                                                                                                                                                                    
                                                                                                                                                                                                          
**TENANT MODULES:**                                                                                                                                                                                       
                                                                                                                                                                                                          
Complaint [TENANT]                                                                                                                                                                                        
Controllers (8): AiInsightController, ComplaintActionController, ComplaintCategoryController, ComplaintController, ComplaintDashboardController, ComplaintReportController, DepartmentSlaController,      
MedicalCheckController                                                                                                                                                                                    
Models (6): AiInsight, Complaint, ComplaintAction, ComplaintCategory, DepartmentSla, MedicalCheck                                                                                                         
                                                                                                                                                                                                          
Dashboard [TENANT]                                                                                                                                                                                        
Controllers (1): DashboardController                                                                                                                                                                      
Models: none                                                                                                                                                                                              
                                                                                                                                                                                                          
Hpc [TENANT] — 95%                                                                                                                                                                                        
Controllers (15): CircularGoalsController, HpcController, HpcParametersController, HpcPerformanceDescriptorController, HpcTemplatePartsController, HpcTemplateRubricsController,                          
HpcTemplateSectionsController, HpcTemplatesController, KnowledgeGraphValidationController, LearningActivitiesController, LearningOutcomesController, QuestionMappingController,                           
StudentHpcEvaluationController, SyllabusCoverageSnapshotController, TopicEquivalencyController                                                                                                            
Models (26): CircularGoalCompetencyJnt, CircularGoals, HpcLevels, HpcParameters, HpcPerformanceDescriptor, HpcReport, HpcReportItem, HpcReportTable, HpcTemplateParts, HpcTemplatePartsItems,             
HpcTemplateRubricItems, HpcTemplateRubrics, HpcTemplateSectionItems, HpcTemplateSectionTable, HpcTemplateSections, HpcTemplates, KnowledgeGraphValidation, LearningActivities, LearningActivityType,      
LearningOutcomes, OutcomesEntityJnt, OutcomesQuestionJnt, StudentHpcEvaluation, StudentHpcSnapshot, SyllabusCoverageSnapshot, TopicEquivalency                                                            
                                                                                                                                                                                                          
Library [TENANT] — Pending                                                                                                                                                                                
Controllers (26): LibAuthorController, LibBookConditionController, LibBookCopyController, LibBookMasterController, LibCategoryController, LibCirculationReportController, LibDigitalResourceController,   
LibDigitalResourceTagController, LibFineController, LibFineReportController, LibFineSlabConfigController, LibFineSlabDetailController, LibGenreController, LibInventoryAuditController,                   
LibInventoryAuditDetailController, LibKeywordController, LibMemberController, LibMembershipTypeController, LibPublisherController, LibReportPrintController, LibReservationController,                    
LibResourceTypeController, LibShelfLocationController, LibTransactionController, LibraryController, MasterDashboardController                                                                             
Models (35): LibAuthor, LibBookAuthorJnt, LibBookCategoryJnt, LibBookCondition, LibBookConditionJnt, LibBookCopy, LibBookGenreJnt, LibBookKeywordJnt, LibBookMaster, LibBookPopularityTrend,              
LibBookSubjectJnt, LibCategory, LibCollectionHealthMetric, LibCurricularAlignment, LibDigitalResource, LibDigitalResourceTag, LibEngagementEvent, LibFine, LibFinePayment, LibFineSlabConfig,             
LibFineSlabDetail, LibGenre, LibInventoryAudit, LibInventoryAuditDetail, LibKeyword, LibMember, LibMembershipType, LibPredictiveAnalytic, LibPublisher, LibReadingBehaviorAnalytics, LibReservation,      
LibResourceType, LibShelfLocation, LibTransaction, LibTransactionHistory                                                                                                                                  
                                                                                                                                                                                                          
LmsExam [TENANT] — 90%                                                                                                                                                                                    
Controllers (11): ExamAllocationController, ExamBlueprintController, ExamPaperController, ExamPaperSetController, ExamScopeController, ExamStatusEventController, ExamStudentGroupController,             
ExamStudentGroupMemberController, ExamTypeController, LmsExamController, PaperSetQuestionController                                                                                                       
Models (11): Exam, ExamAllocation, ExamBlueprint, ExamPaper, ExamPaperSet, ExamScope, ExamStatusEvent, ExamStudentGroup, ExamStudentGroupMember, ExamType, PaperSetQuestion                               
                                                                                                                                                                                                          
LmsHomework [TENANT] — 80%                                                                                                                                                                                
Controllers (5): ActionTypeController, HomeworkSubmissionController, LmsHomeworkController, RuleEngineConfigController, TriggerEventController                                                            
Models (5): ActionType, Homework, HomeworkSubmission, RuleEngineConfig, TriggerEvent                                                                                                                      
                                                                                                                                                                                                          
LmsQuests [TENANT] — 80%                                                                                                                                                                                  
Controllers (4): LmsQuestController, QuestAllocationController, QuestQuestionController, QuestScopeController                                                                                             
Models (4): Quest, QuestAllocation, QuestQuestion, QuestScope                                                                                                                                             
                                                                                                                                                                                                          
LmsQuiz [TENANT] — 85%                                                                                                                                                                                    
Controllers (5): AssessmentTypeController, DifficultyDistributionConfigController, LmsQuizController, QuizAllocationController, QuizQuestionController                                                    
Models (6): AssessmentType, DifficultyDistributionConfig, DifficultyDistributionDetail, Quiz, QuizAllocation, QuizQuestion                                                                                
                                                                                                                                                                                                          
Notification [TENANT]                                                                                                                                                                                     
Controllers (12): ChannelMasterController, DeliveryQueueController, NotificationManageController, NotificationTargetController, NotificationTemplateController, NotificationThreadController,             
NotificationThreadMemberController, ProviderMasterController, ResolvedRecipientController, TargetGroupController, TemplateController, UserPreferenceController                                            
Models (14): ChannelMaster, DeliveryQueue, Notification, NotificationChannel, NotificationDeliveryLog, NotificationTarget, NotificationTemplate, NotificationThread, NotificationThreadMember,            
ProviderMaster, ResolvedRecipient, TargetGroup, UserDevice, UserPreference                                                                                                                                
                                                                                                                                                                                                          
Payment [TENANT]                                                                                                                                                                                          
Controllers (4): PaymentCallbackController, PaymentController, PaymentGatewayController                                                                                                                   
Models (5): Payment, PaymentGateway, PaymentHistory, PaymentRefund, PaymentWebhook                                                                                                                        
                                                                                                                                                                                                          
QuestionBank [TENANT]                                                                                                                                                                                     
Controllers (7): AIQuestionGeneratorController, QuestionBankController, QuestionMediaStoreController, QuestionStatisticController, QuestionTagController, QuestionUsageTypeController,                    
QuestionVersionController                                                                                                                                                                                 
Models (17): QuestionBank, QuestionMedia, QuestionMediaStore, QuestionOption, QuestionPerformanceCategory, QuestionPerformanceCategoryJnt, QuestionQuestionTag, QuestionQuestionTagJnt,                   
QuestionReviewLog, QuestionStatistic, QuestionTag, QuestionTopic, QuestionTopicJnt, QuestionUsageLog, QuestionUsageType, QuestionVersion                                                                  
                                                                                                                                                                                                          
Recommendation [TENANT] — 85%                                                                                                                                                                             
Controllers (10): DynamicMaterialTypeController, DynamicPurposeController, MaterialBundleController, RecAssessmentTypeController, RecTriggerEventController, RecommendationController,                    
RecommendationMaterialController, RecommendationModeController, RecommendationRuleController, StudentRecommendationController                                                                             
Models (11): BundleMaterialJnt, DynamicMaterialType, DynamicPurpose, MaterialBundle, PerformanceSnapshot, RecAssessmentType, RecTriggerEvent, RecommendationMaterial, RecommendationMode,                 
RecommendationRule, StudentRecommendation                                                                                                                                                                 
                                                                                                                                                                                                          
Scheduler [TENANT]                                                                                                                                                                                        
Controllers (1): SchedulerController                                                                                                                                                                      
Models (2): Schedule, ScheduleRun                                                                                                                                                                         
                                                                                                                                                                                                          
SchoolSetup [TENANT] — 100% (Core Infrastructure)                                                                                                                                                         
Controllers (40): AttendanceTypeController, BuildingController, ClassGroupController, ClassSubjectGroupController, ClassSubjectManagementController, DepartmentController, DesignationController,         
DisableReasonController, EmployeeProfileController, EntityGroupController, EntityGroupMemberController, InfrasetupController, LeaveConfigController, LeaveTypeController,                                 
OrganizationAcademicSessionController, OrganizationController, OrganizationGroupController, RolePermissionController, RoomController, RoomTypeController, SchCategoryController, SchoolClassController,   
SchoolSetupController, SectionController, StudyFormatController, SubjectClassMappingController, SubjectController, SubjectGroupController, SubjectGroupSubjectController, SubjectStudyFormatController,   
SubjectTypeController, TeacherController, UserController, UserRolePrmController                                                                                                                           
Models (42): AttendanceType, Building, ClassSection, Department, Designation, DisableReason, Employee, EmployeeProfile, EntityGroup, EntityGroupMember, LeaveConfig, LeaveType, Organization,             
OrganizationAcademicSession, OrganizationGroup, OrganizationPlan, OrganizationPlanRate, Permission, Role, Room, RoomType, SchCategory, SchClassGroupsJnt, SchoolClass, Section, StudyFormat, Subject,     
SubjectGroup, SubjectGroupSubject, SubjectStudyFormat, SubjectTeacher, SubjectType, Teacher, TeacherCapability, TeacherProfile, User                                                                      
                                                                                                                                                                                                          
SmartTimetable [TENANT] — 95%                                                                                                                                                                             
Controllers (28): ActivityController, AcademicTermController, ClassSubjectSubgroupController, ConstraintController, ConstraintTypeController, DayTypeController, ParallelGroupController,                 
PeriodController, PeriodSetController, PeriodSetPeriodController, PeriodTypeController, RequirementConsolidationController, RoomUnavailableController, SchoolDayController, SchoolShiftController,        
SchoolTimingProfileController, SlotRequirementController, SmartTimetableController, TeacherAssignmentRoleController, TeacherAvailabilityController, TeacherUnavailableController, TimetableController,    
TimetableTypeController, TimingProfileController, TtConfigController, TtGenerationStrategyController, WorkingDayController                                                                                
Models (86): (86 models covering: activities, constraints, periods, timetable cells, parallel groups, generation runs, ML models, approval workflows, conflict detection, optimization, substitution,     
analytics)                                                                                                                                                                                                
                                                                                                                                                                                                          
StudentFee [TENANT] — 80%                                                                                                                                                                                 
Controllers (15): FeeConcessionTypeController, FeeFineRuleController, FeeFineTransactionController, FeeGroupMasterController, FeeHeadMasterController, FeeInstallmentController, FeeInvoiceController,    
FeeScholarshipApplicationController, FeeScholarshipController, FeeStructureMasterController, FeeStudentAssignmentController, FeeStudentConcessionController, FeeTransactionController,                    
StudentFeeController, StudentFeeManagementController                                                                                                                                                      
Models (23): FeeConcessionType, FeeDefaulterHistory, FeeFineRule, FeeFineTransaction, FeeGroupHeadsJnt, FeeGroupMaster, FeeHeadMaster, FeeInstallment, FeeInvoice, FeeNameRemovalLog,                     
FeePaymentGatewayLog, FeePaymentReconciliation, FeeReceipt, FeeRefund, FeeScholarship, FeeScholarshipApplication, FeeScholarshipApprovalHistory, FeeStructureDetail, FeeStructureMaster,                  
FeeStudentAssignment, FeeStudentConcession, FeeTransaction, FeeTransactionDetail                                                                                                                          
                                                                                                                                                                                                          
StudentPortal [TENANT] — Pending                                                                                                                                                                          
Controllers (3): NotificationController, StudentPortalComplaintController, StudentPortalController                                                                                                        
Models: none                                                                                                                                                                                              
                                                                                                                                                                                                          
StudentProfile [TENANT] — 100%                                                                                                                                                                            
Controllers (5): AttendanceController, MedicalIncidentController, StudentController, StudentProfileController, StudentReportController                                                                    
Models (14): Guardian, MedicalIncident, PreviousEducation, Student, StudentAcademicSession, StudentAddress, StudentAttendance, StudentAttendanceCorrection, StudentDetail, StudentDocument,               
StudentGuardianJnt, StudentHealthProfile, StudentProfile, VaccinationRecord                                                                                                                               
                                                                                                                                                                                                          
Syllabus [TENANT] — 100%                                                                                                                                                                                  
Controllers (15): BloomTaxonomyController, CognitiveSkillController, CompetencieController, CompetencyTypeController, ComplexityLevelController, GradeDivisionController, LessonController,               
PerformanceCategoryController, QuestionTypeController, QuestionTypeSpecificityController, SyllabusController, SyllabusScheduleController, TopicCompetencyController, TopicController,                     
TopicLevelTypeController                                                                                                                                                                                  
Models (22): BloomTaxonomy, Book, CognitiveSkill, Competencie, CompetencyType, ComplexityLevel, GradeDivisionMaster, Lesson, PerformanceCategory, QuestionType, StudyMaterial, StudyMaterialType,         
SyllabusSchedule, Topic, TopicCompetency, TopicDependencies, TopicLevelType                                                                                                                               
                                                                                                                                                                                                          
SyllabusBooks [TENANT]                                                                                                                                                                                    
Controllers (4): AuthorController, BookController, BookTopicMappingController, SyllabusBooksController                                                                                                    
Models (6): BokBook, BookAuthorJnt, BookAuthors, BookClassSubject, BookTopicMapping, MediaFiles                                                                                                           
                                                                                                                                                                                                          
Transport [TENANT] — 90%                                                                                                                                                                                  
Controllers (31): AttendanceDeviceController, DriverAttendanceController, DriverHelperController, DriverRouteVehicleController, FeeCollectionController, FeeMasterController, FineMasterController,       
LiveTripController, NewTripController, PickupPointController, PickupPointRouteController, RouteController, RouteSchedulerController, ShiftController, StaffMgmtController, StudentAllocationController,   
StudentAttendanceController, StudentBoardingController, StudentRouteFeesController, TptDailyVehicleInspectionController, TptStudentFineDetailController, TptVehicleFuelController,                        
TptVehicleMaintenanceController, TptVehicleServiceRequestController, TransportDashboardController, TransportMasterController, TransportReportController, TripController, TripMgmtController,              
VehicleController, VehicleMgmtController                                                                                                                                                                  
Models (36): AttendanceDevice, DriverHelper, DriverRouteVehicleJnt, PickupPoint, PickupPointRoute, Route, Shift, StudentBoardingLog, StudentPayLog, TptDailyVehicleInspection, TptDriverAttendance,       
TptFeeCollection, TptFeeMaster, TptFineMaster, TptGpsTripLog, TptLiveTrip, TptRouteSchedulerJnt, TptStudentAllocationJnt, TptStudentFeeCollection, TptStudentFineDetail, TptTrip, TptTripIncidents,       
TptTripStopDetail, TptVehicleFuel, TptVehicleMaintenance, TptVehicleServiceRequest, Vehicle                                                                                                               
                                                                                                                                                                                                          
Vendor [TENANT]                                                                                                                                                                                           
Controllers (7): VendorAgreementController, VendorController, VendorDashboardController, VendorInvoiceController, VendorPaymentController, VndItemController, VndUsageLogController                       
Models (8): Vendor, VendorDashboard, VndAgreement, VndAgreementItem, VndInvoice, VndItem, VndPayment, VndUsageLog                                                                                         
                                                                                                                                                                                                          
---                                                                                                                                                                                                       
                                                                                                                                                                                                          
### FILE 12 (Index): `project_docs/README.md`                                                                                                                                                             
                                                                                                                                                                                                          
```markdown                                                                                                                                                                                               
# Prime-AI Project Documentation                                                                                                                                                                          
                                                                                                                                                                                                          
Auto-generated from full codebase exploration.                                                                                                                                                            
Use these docs before starting any feature task.                                                                                                                                                          
                                                                                                                                                                                                          
| File | Description |                                                                                                                                                                                    
|------|-------------|                                                                                                                                                                                    
| 01-project-overview.md | Project identity, tech stack, 3-layer DB, all 27 modules |                                                                                                                     
| 02-prime-side-structure.md | Prime/central side — structure, routes, migrations |                                                                                                                       
| 03-tenant-side-structure.md | Tenant/school side — structure, routes, migrations |                                                                                                                      
| 04-migration-guide.md | How to create migrations (prime vs tenant), naming rules |                                                                                                                      
| 05-model-guide.md | How to create models, $table, $fillable, SoftDeletes |                                                                                                                              
| 06-controller-guide.md | How to create controllers, CRUD pattern, view namespace |                                                                                                                      
| 07-blade-views-guide.md | How to create views, shared components, PDF rules |                                                                                                                           
| 08-routes-guide.md | Route files, naming, prime vs tenant registration |                                                                                                                                
| 09-artisan-commands-reference.md | All artisan commands (module, migration, cache) |                                                                                                                    
| 10-new-feature-checklist.md | Step-by-step checklist for any new feature |                                                                                                                              
| 11-all-modules-controllers-models.md | Full reference: all 27 modules, controllers, models |                                                                                                            
                                                                                                                                                                                                          
## Quick Rules                                                                                                                                                                                            
1. Prime migration → `database/migrations/` or `Modules/<Name>/database/migrations/`                                                                                                                      
2. Tenant migration → `database/migrations/tenant/` **ALWAYS**                                                                                                                                            
3. Models → `Modules/<Name>/app/Models/`                                                                                                                                                                  
4. Controllers → `Modules/<Name>/app/Http/Controllers/`                                                                                                                                                   
5. Prime routes → `routes/web.php`                                                                                                                                                                        
6. Tenant routes → `routes/tenant.php`                                                                                                                                                                    
7. Views → `Modules/<Name>/resources/views/<feature>/`                                                                                                                                                    
8. NEVER mix prime and tenant code                                                                                                                                                                        
9. NEVER modify existing migrations                                                                                                                                                                       
```                                                                                                                                                                                                       
                                                                                                                                                                                                          
---                                                                                                                                                                                                       
                                                                                                                                                                                                          
## AFTER ALL FILES ARE CREATED                                                                                                                                                                            
                                                                                                                                                                                                          
Verify all 12 files exist in `project_docs/`.                                                                                                                                                             
Then reply: **"Documentation complete. project_docs/ is ready. Assign me any feature task."**                                                                                                             
                                                                                                                                                                                                          
From now on, before writing any code for any task:                                                                                                                                                        
1. Identify: Prime or Tenant?                                                                                                                                                                             
2. Check which module it belongs to                                                                                                                                                                       
3. Use the correct migration path                                                                                                                                                                         
4. Use the correct route file                                                                                                                                                                             
5. Follow the exact folder structure from these docs                                                                                                                                                      
6. Read an existing similar file before writing new code                                                                                                                                                  
                                                                                                                                                                                                          

⏺ I'll execute this systematically. Let me start with Steps 1 and 2 — reading all the specified files and exploring all the folders.

⏺ Read 11 files (ctrl+o to expand)

⏺ Step 1 complete. Now Step 2 — exploring all specified folders in parallel.

⏺ Bash(cd /Users/bkwork/Herd/prime_ai_shailesh && ls -d Modules/*/ | sed 's|.*/Modules/||;s|/||' | sort && echo "===PRIME CONTROLLERS===" && ls Modules/Prime/app/Http/…)
  ⎿  ModulesBilling/
     ModulesComplaint/
     ModulesDashboard/
     … +111 lines (ctrl+o to expand)
  ⎿  Shell cwd was reset to /Users/bkwork/Herd/prime_ai_tarun

⏺ Bash(cd /Users/bkwork/Herd/prime_ai_shailesh && echo "===BILLING CTRL===" && ls Modules/Billing/app/Http/Controllers/*.php 2>/dev/null | sed 's|.*/||' | sort && echo…)
  ⎿  ===BILLING CTRL===
     BillingCycleController.php
     BillingManagementController.php
     … +87 lines (ctrl+o to expand)
  ⎿  Shell cwd was reset to /Users/bkwork/Herd/prime_ai_tarun

⏺ Bash(cd /Users/bkwork/Herd/prime_ai_shailesh && echo "===HPC VIEWS===" && ls -d Modules/Hpc/resources/views/*/ 2>/dev/null | sed 's|.*/views/||;s|/||' | sort && echo…)
  ⎿  ===HPC VIEWS===
     circular-goals
     components
     … +101 lines (ctrl+o to expand)
  ⎿  Shell cwd was reset to /Users/bkwork/Herd/prime_ai_tarun

⏺ Bash(cd /Users/bkwork/Herd/prime_ai_shailesh && echo "===SMARTTT CTRL===" && ls Modules/SmartTimetable/app/Http/Controllers/*.php 2>/dev/null | sed 's|.*/||' | sort…)
  ⎿  ===SMARTTT CTRL===
     AcademicTermController.php
     ActivityController.php
     … +85 lines (ctrl+o to expand)
  ⎿  Shell cwd was reset to /Users/bkwork/Herd/prime_ai_tarun

⏺ Bash(cd /Users/bkwork/Herd/prime_ai_shailesh && echo "===STUDENTFEE CTRL===" && ls Modules/StudentFee/app/Http/Controllers/*.php 2>/dev/null | sed 's|.*/||' | sort &…)
  ⎿  ===STUDENTFEE CTRL===
     FeeConcessionTypeController.php
     FeeFineRuleController.php
     … +61 lines (ctrl+o to expand)
  ⎿  Shell cwd was reset to /Users/bkwork/Herd/prime_ai_tarun

⏺ Bash(cd /Users/bkwork/Herd/prime_ai_shailesh && echo "===LIBRARY CTRL===" && ls Modules/Library/app/Http/Controllers/*.php 2>/dev/null | sed 's|.*/||' | sort && echo…)
  ⎿  ===LIBRARY CTRL===
     LibAuthorController.php
     LibBookConditionController.php
     … +58 lines (ctrl+o to expand)
  ⎿  Shell cwd was reset to /Users/bkwork/Herd/prime_ai_tarun

⏺ Bash(cd /Users/bkwork/Herd/prime_ai_shailesh && echo "===COMPONENTS BACKEND===" && ls -d resources/views/components/backend/*/ 2>/dev/null | sed 's|.*/backend/||;s|/…)
  ⎿  ===COMPONENTS BACKEND===
     card
     components
     … +37 lines (ctrl+o to expand)
  ⎿  Shell cwd was reset to /Users/bkwork/Herd/prime_ai_tarun

⏺ Steps 1 and 2 complete. I have all the codebase data. Now creating all 12 files in project_docs/.

⏺ Bash(mkdir -p /Users/bkwork/Herd/prime_ai_shailesh/project_docs)
  ⎿  Done

⏺ Creating all files in parallel batches. Starting with files 1-4:

⏺ Write(~/Herd/prime_ai_shailesh/project_docs/01-project-overview.md)
  ⎿  Wrote 93 lines to ../prime_ai_shailesh/project_docs/01-project-overview.md
      1 # Prime-AI — Project Overview
      2
      3 ## Project Identity
      4
      5 - **Name:** Prime-AI ERP + LMS + LXP
      6 - **Purpose:** Multi-Tenant SaaS Academic Intelligence Platform for Indian K-12 Schools
      7 - **Tech:** PHP 8.2+ / Laravel 12.0 / MySQL 8.x / stancl/tenancy v3.9 / nwidart/laravel-modules v12.0
      8
      9 ## Two Sides of the Application
     … +83 lines (ctrl+o to expand)

⏺ Write(~/Herd/prime_ai_shailesh/project_docs/02-prime-side-structure.md)
  ⎿  Wrote 131 lines to ../prime_ai_shailesh/project_docs/02-prime-side-structure.md
       1 # Prime (Central) Side — Structure Guide
       2
       3 ## What is Prime Side
       4
       5 Prime is the super-admin/owner panel of the entire SaaS platform. It manages:
       6 - Tenant (school) creation and management
       7 - Billing and subscriptions
       8 - Global master data (countries, states, boards, plans)
       9 - System configuration (menus, settings)
      10 - User roles and permissions at platform level
     … +121 lines (ctrl+o to expand)

⏺ Write(~/Herd/prime_ai_shailesh/project_docs/03-tenant-side-structure.md)
  ⎿  Wrote 128 lines to ../prime_ai_shailesh/project_docs/03-tenant-side-structure.md
      1 # Tenant (School) Side — Structure Guide
      2
      3 ## What is Tenant Side
      4
      5 - Each school created by Prime = one tenant
      6 - Gets its own database (isolated data)
      7 - Gets its own subdomain (e.g., `school1.primeai.in`)
      8 - stancl/tenancy handles DB switching and domain routing automatically
      9 - All 22 tenant modules run inside tenant context
     … +118 lines (ctrl+o to expand)

⏺ Write(~/Herd/prime_ai_shailesh/project_docs/04-migration-guide.md)
  ⎿  Wrote 93 lines to ../prime_ai_shailesh/project_docs/04-migration-guide.md
      1 # Migration Guide
      2
      3 ## Two Migration Types
      4
      5 | Type | File Location | Command | Example |
      6 |------|--------------|---------|---------|
      7 | Central/Prime | `database/migrations/` | `php artisan migrate` | Users, cache, sessions |
      8 | Central/Prime module | `Modules/<Name>/database/migrations/` | `php artisan migrate` | Tenants, plans, billing |
      9 | **Tenant** | **`database/migrations/tenant/`** | **`php artisan tenants:migrate`** | All school data (278 files) |
     … +83 lines (ctrl+o to expand)

⏺ Files 1-4 created. Now files 5-8:

⏺ Write(~/Herd/prime_ai_shailesh/project_docs/05-model-guide.md)
  ⎿  Wrote 107 lines to ../prime_ai_shailesh/project_docs/05-model-guide.md
      1 # Model Guide
      2
      3 ## Model Location — Universal Rule
      4
      5 ```
      6 Modules/<ModuleName>/app/Models/<ModelName>.php
      7 ```
      8
      9 This applies to ALL modules — both prime and tenant.
     … +97 lines (ctrl+o to expand)

⏺ Write(~/Herd/prime_ai_shailesh/project_docs/06-controller-guide.md)
  ⎿  Wrote 190 lines to ../prime_ai_shailesh/project_docs/06-controller-guide.md
      1 # Controller Guide
      2
      3 ## Controller Location — Universal Rule
      4
      5 ```
      6 Modules/<ModuleName>/app/Http/Controllers/<ControllerName>.php
      7 ```
      8
      9 ## Namespace Pattern
     … +180 lines (ctrl+o to expand)

⏺ Write(~/Herd/prime_ai_shailesh/project_docs/07-blade-views-guide.md)
  ⎿  Wrote 213 lines to ../prime_ai_shailesh/project_docs/07-blade-views-guide.md
      1 # Blade Views Guide
      2
      3 ## Blade File Location — Universal Rule
      4
      5 ```
      6 Modules/<ModuleName>/resources/views/<feature-folder>/<file>.blade.php
      7 ```
      8
      9 ## Blade View Namespace (used in controllers)
     … +203 lines (ctrl+o to expand)

⏺ Write(~/Herd/prime_ai_shailesh/project_docs/08-routes-guide.md)
  ⎿  Wrote 120 lines to ../prime_ai_shailesh/project_docs/08-routes-guide.md
       1 # Routes Guide
       2
       3 ## Two Master Route Files
       4
       5 | File | Purpose | Who Uses It |
       6 |------|---------|-------------|
       7 | `routes/web.php` | ALL prime/central routes | Prime, GlobalMaster, Billing, SystemConfig, Documentation |
       8 | `routes/tenant.php` | ALL tenant/school routes | SchoolSetup, Hpc, SmartTimetable, Transport, and all other tenant modules |
       9
      10 ## ABSOLUTE RULE
     … +110 lines (ctrl+o to expand)

⏺ Files 5-8 done. Now files 9-12:

⏺ Write(~/Herd/prime_ai_shailesh/project_docs/09-artisan-commands-reference.md)
  ⎿  Wrote 133 lines to ../prime_ai_shailesh/project_docs/09-artisan-commands-reference.md
       1 # Artisan Commands Reference
       2
       3 ## nwidart/laravel-modules v12 Commands
       4
       5 ### Module Scaffold Commands
       6
       7 ```bash
       8 # Create a new module
       9 php artisan module:make <ModuleName>
      10 # Example: php artisan module:make Attendance
     … +123 lines (ctrl+o to expand)

⏺ Write(~/Herd/prime_ai_shailesh/project_docs/10-new-feature-checklist.md)
  ⎿  Wrote 121 lines to ../prime_ai_shailesh/project_docs/10-new-feature-checklist.md
      1 # New Feature Checklist
      2
      3 ## BEFORE WRITING ANY CODE — Ask These Questions
      4
      5 1. Is this a PRIME feature (platform admin) or TENANT feature (school)?
      6 2. Does the module already exist or do I need to create it?
      7 3. What table prefix should this feature use?
      8 4. Does the migration go in `database/migrations/tenant/` or `database/migrations/`?
      9 5. Does the route go in `routes/web.php` or `routes/tenant.php`?
     … +111 lines (ctrl+o to expand)

⏺ Write(~/Herd/prime_ai_shailesh/project_docs/11-all-modules-controllers-models.md)
  ⎿  Wrote 284 lines to ../prime_ai_shailesh/project_docs/11-all-modules-controllers-models.md
      1 # All Modules — Controllers & Models Reference
      2
      3 ## PRIME (CENTRAL) MODULES
      4
      5 ---
      6
      7 ### Prime [PRIME] — Status: ~80%
      8 **Table Prefix:** prm_*
      9 **Controllers:** 22 | **Models:** 27
     … +274 lines (ctrl+o to expand)

⏺ Write(~/Herd/prime_ai_shailesh/project_docs/README.md)
  ⎿  Wrote 30 lines to ../prime_ai_shailesh/project_docs/README.md
       1 # Prime-AI Project Documentation
       2
       3 Auto-generated from full codebase exploration on 2026-03-15.
       4 Use these docs before starting any feature task.
       5
       6 | File | Description |
       7 |------|-------------|
       8 | [01-project-overview.md](01-project-overview.md) | Project identity, tech stack, 3-layer DB, all 27 modules |
       9 | [02-prime-side-structure.md](02-prime-side-structure.md) | Prime/central side — structure, routes, migrations |
      10 | [03-tenant-side-structure.md](03-tenant-side-structure.md) | Tenant/school side — structure, routes, migrations |
     … +20 lines (ctrl+o to expand)

⏺ Now let me verify all 12 files exist:

⏺ Read 1 file (ctrl+o to expand)

⏺ Documentation complete. project_docs/ is ready with all 12 files. Assign me any feature task.

  Files created:

  ┌─────┬──────────────────────────────────────┬────────┬─────────────────────────────────────────────────────────────────────────┐
  │  #  │                 File                 │  Size  │                                 Content                                 │
  ├─────┼──────────────────────────────────────┼────────┼─────────────────────────────────────────────────────────────────────────┤
  │ 1   │ 01-project-overview.md               │ 4.5KB  │ Project identity, 3-layer DB, 27 modules with counts                    │
  ├─────┼──────────────────────────────────────┼────────┼─────────────────────────────────────────────────────────────────────────┤
  │ 2   │ 02-prime-side-structure.md           │ 4.7KB  │ Prime side: 5 modules, folder structure, 22 controllers listed          │
  ├─────┼──────────────────────────────────────┼────────┼─────────────────────────────────────────────────────────────────────────┤
  │ 3   │ 03-tenant-side-structure.md          │ 4.9KB  │ Tenant side: 22 modules, HPC folder example, migration rules            │
  ├─────┼──────────────────────────────────────┼────────┼─────────────────────────────────────────────────────────────────────────┤
  │ 4   │ 04-migration-guide.md                │ 3.1KB  │ Two migration paths, required columns, naming rules                     │
  ├─────┼──────────────────────────────────────┼────────┼─────────────────────────────────────────────────────────────────────────┤
  │ 5   │ 05-model-guide.md                    │ 2.5KB  │ Model template, $table/$fillable rules, counts per module               │
  ├─────┼──────────────────────────────────────┼────────┼─────────────────────────────────────────────────────────────────────────┤
  │ 6   │ 06-controller-guide.md               │ 6.2KB  │ Full CRUD template with Gate, view namespace, counts                    │
  ├─────┼──────────────────────────────────────┼────────┼─────────────────────────────────────────────────────────────────────────┤
  │ 7   │ 07-blade-views-guide.md              │ 8.7KB  │ Index + Create patterns, shared components, PDF rules                   │
  ├─────┼──────────────────────────────────────┼────────┼─────────────────────────────────────────────────────────────────────────┤
  │ 8   │ 08-routes-guide.md                   │ 4.5KB  │ Prime vs Tenant routing, named routes, standard group pattern           │
  ├─────┼──────────────────────────────────────┼────────┼─────────────────────────────────────────────────────────────────────────┤
  │ 9   │ 09-artisan-commands-reference.md     │ 3.9KB  │ All module/migration/cache/test commands                                │
  ├─────┼──────────────────────────────────────┼────────┼─────────────────────────────────────────────────────────────────────────┤
  │ 10  │ 10-new-feature-checklist.md          │ 3.8KB  │ Step-by-step for Prime and Tenant features + final checklist            │
  ├─────┼──────────────────────────────────────┼────────┼─────────────────────────────────────────────────────────────────────────┤
  │ 11  │ 11-all-modules-controllers-models.md │ 13.7KB │ Complete reference: all 27 modules with every controller and model name │
  ├─────┼──────────────────────────────────────┼────────┼─────────────────────────────────────────────────────────────────────────┤
  │ 12  │ README.md                            │ 1.9KB  │ Index + quick rules                                                     │
  └─────┴──────────────────────────────────────┴────────┴─────────────────────────────────────────────────────────────────────────┘

✻ Crunched for 6m 12s

❯ Read all the information you just created in all the documents in folder "/Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/3-Project_Planning/project_docs" and Update AI_Brain  

⏺ Searched for 1 pattern, read 2 files (ctrl+o to expand)

⏺ Found at databases/3-Project_Planning/project_docs/. Let me read all 12 files and then update the AI Brain.

⏺ Read 12 files (ctrl+o to expand)

⏺ All 12 files read. Now let me read the current AI Brain files to see what needs updating, then update them.

⏺ Read 1 file (ctrl+o to expand)

⏺ Now I have the full picture. The project-context.md needs updating with accurate stats from the project_docs audit. Let me update the AI Brain files.

⏺ Update(~/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/AI_Brain/memory/project-context.md)
  ⎿  Added 13 lines, removed 16 lines
       84  - Alpine.js 3.4
       85  - Vite 7.0 build tool
       86  
       87 -## Key Statistics                                                                                                                                                                       
       87 +## Key Statistics (re-verified 2026-03-15 against `prime_ai_shailesh` branch `Brijesh_HPC`)                                                                                             
       88  | Metric | Count |
       89  |--------|-------|
       90 -| Modules | 29 (27 active + 2 pending) |                                                                                                                                                
       91 -| Total Models | 381 |                                                                                                                                                                  
       92 -| Total Controllers | 283 |                                                                                                                                                             
       93 -| Total Services | 12 |                                                                                                                                                                 
       94 -| Total Jobs | 9 |                                                                                                                                                                      
       90 +| Modules | 27 (5 central + 22 tenant) |                                                                                                                                                
       91 +| Total Models | ~470 |                                                                                                                                                                 
       92 +| Total Controllers | ~290 |                                                                                                                                                            
       93 +| Total Services | ~40 (SmartTimetable: 21, Library: 9, others) |                                                                                                                       
       94  | Tenant DB Tables | 368 |
       96 -| Central DB Tables | 39 (global + prime) |                                                                                                                                             
       97 -| Total DB Tables | 407 |                                                                                                                                                               
       95 +| Central DB Tables | ~39 (global + prime) |                                                                                                                                            
       96  | Authorization Policies | 195+ |
       99 -| Form Requests | 168 |                                                                                                                                                                 
      100 -| Tenant Migrations | 216 files |                                                                                                                                                       
      101 -| Central Migrations | 6 files |                                                                                                                                                        
      102 -| Blade Views | 500+ |                                                                                                                                                                  
      103 -| Central Roles | 6 |                                                                                                                                                                   
      104 -| Tenant Roles | 9 |                                                                                                                                                                    
      105 -| Tenant Route Lines | 2,628 |                                                                                                                                                          
      106 -| Central Route Lines | 973 |                                                                                                                                                           
       97 +| Tenant Migrations | 278 files in `database/migrations/tenant/` |                                                                                                                      
       98 +| Central Migrations | 5 files in `database/migrations/` + 37 in `Modules/Prime/database/migrations/` |                                                                                 
       99 +| Tenant Route Lines | 2,715 (1,328 Route:: calls) |                                                                                                                                    
      100 +| Blade Views (total) | ~1,800+ |                                                                                                                                                       
      101 +| Shared Components | `resources/views/components/backend/` (8 dirs), `prime/` (6 dirs), `frontend/` (2 dirs) |                                                                         
      102 +| **Overall platform completion** | **~31%** of RBS (1112 sub-tasks), **~70%** of built modules' CRUD |                                                                                 
      103 +| **Full project docs** | `databases/3-Project_Planning/project_docs/` (12 files — overview, guides, reference) |                                                                       
      104  
      105  ## Key Business Workflows
      106  1. **Tenant Onboarding:** TenantController → UUID creation → domain setup → DB provisioning → migrations → CreateRootUser job → plan assignment

⏺ Now update the AI Brain's MEMORY.md index to reference the new project_docs.

⏺ Read 1 file (ctrl+o to expand)

⏺ Update(~/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/AI_Brain/memory/MEMORY.md)
  ⎿  Added 1 line, removed 1 line
      2  
      3  > This file is the index of all memory files in `AI_Brain/memory/`.
      4  > **Start every session by reading `AI_Brain/README.md` first.**
      5 -> Last Updated: 2026-03-12                                                                                                                                                                
      5 +> Last Updated: 2026-03-15                                                                                                                                                                
      6  
      7  ---
      8  

⏺ Update(~/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/AI_Brain/memory/MEMORY.md)
  ⎿  Added 36 lines
      46  
      47  ---
      48  
      49 +## Project Documentation (created 2026-03-15)                                                                                                                                            
      50 +                                                                                                                                                                                         
      51 +> **Location:** `databases/3-Project_Planning/project_docs/` (12 files)                                                                                                                  
      52 +> These contain verified codebase patterns — use before writing any new code.                                                                                                            
      53 +                                                                                                                                                                                         
      54 +| File | What It Answers |                                                                                                                                                               
      55 +|------|----------------|                                                                                                                                                                
      56 +| `01-project-overview.md` | What is this project? What modules exist? What DB prefixes? |                                                                                               
      57 +| `02-prime-side-structure.md` | How is the central/admin side organized? |                                                                                                              
      58 +| `03-tenant-side-structure.md` | How is the school/tenant side organized? |                                                                                                             
      59 +| `04-migration-guide.md` | Where do migrations go? What columns are required? |                                                                                                         
      60 +| `05-model-guide.md` | How to create a model? What must be in $fillable? |                                                                                                              
      61 +| `06-controller-guide.md` | CRUD template with Gate, validation, activityLog |                                                                                                          
      62 +| `07-blade-views-guide.md` | Index + Create/Edit Blade patterns, shared components |                                                                                                    
      63 +| `08-routes-guide.md` | Prime routes vs Tenant routes — where to register |                                                                                                             
      64 +| `09-artisan-commands-reference.md` | All module/migration/test/cache commands |                                                                                                        
      65 +| `10-new-feature-checklist.md` | Step-by-step: Prime feature vs Tenant feature |                                                                                                        
      66 +| `11-all-modules-controllers-models.md` | Every controller and model name across all 27 modules |                                                                                       
      67 +                                                                                                                                                                                         
      68 +## Project Planning Documents                                                                                                                                                            
      69 +                                                                                                                                                                                         
      70 +> **Location:** `databases/3-Project_Planning/` (also `2-Project_Planning/`)                                                                                                             
      71 +                                                                                                                                                                                         
      72 +| Folder | Contents |                                                                                                                                                                    
      73 +|--------|----------|                                                                                                                                                                    
      74 +| `1-RBS/` | Requirements Breakdown Structure — 1112 sub-tasks, 27 RBS modules |                                                                                                         
      75 +| `2-Gap_Analysis/` | Detailed gap analysis — what's pending per module |                                                                                                                
      76 +| `9-Work_Status/` | Work status (31% overall) + Development estimation (13 months with 3 devs + Claude) |                                                                               
      77 +                                                                                                                                                                                         
      78 +## Development Lifecycle Blueprint                                                                                                                                                       
      79 +                                                                                                                                                                                         
      80 +> **Location:** `databases/3-Design_Architecture/Development_Lifecycle_Blueprint_v1.0.md`                                                                                                
      81 +> 9-phase process with 17 ready-to-use prompts for building any module from scratch.                                                                                                     
      82 +                                                                                                                                                                                         
      83 +---                                                                                                                                                                                      
      84 +                                                                                                                                                                                         
      85  ## Quick Reference: Canonical DDL Paths
      86  
      87  ```

⏺ Now update the critical bugs quick reference with findings from the deep audit.

⏺ Update(~/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/AI_Brain/memory/MEMORY.md)
  ⎿  Added 12 lines, removed 8 lines
       93  
       94  ---
       95  
       96 -## Quick Reference: Active Critical Bugs                                                                                                                                                
       96 +## Quick Reference: Active Critical Bugs (updated 2026-03-15 deep audit)                                                                                                                
       97  
       98  | ID | Severity | One-Line Summary |
       99  |----|----------|-----------------|
      100 -| BUG-002 | CRITICAL | Duplicate Gate::policy() registrations — VehiclePolicy, QuestionBankPolicy, SectionPolicy silently lost |                                                        
      101 -| BUG-004 | HIGH | Tenant migration pipeline commented out — new tenants get empty databases |                                                                                          
      102 -| SEC-002 | CRITICAL | is_super_admin in User $fillable — privilege escalation via mass assignment |                                                                                    
      100 +| SEC-QNS-002 | **REVOKE NOW** | OpenAI + Gemini API keys hardcoded in QuestionBank/AIQuestionGeneratorController |                                                                     
      101 +| SEC-PAY-001 | **REVOKE NOW** | Razorpay test keys hardcoded in Payment/PaymentController copy.php |                                                                                   
      102 +| SEC-PLATFORM-001 | CRITICAL | Only 1 EnsureTenantHasModule usage across entire 2715-line tenant.php |                                                                                 
      103 +| SEC-PLATFORM-004 | CRITICAL | is_super_admin in $fillable on BOTH User models + writable from student login form |                                                                    
      104 +| SEC-PLATFORM-002 | CRITICAL | env('APP_DOMAIN') in routes/web.php — ALL central routes 404 after config:cache |                                                                       
      105  | SEC-004 | CRITICAL | Payment webhook behind auth middleware — ALL Razorpay payments fail |
      104 -| SEC-005 | CRITICAL | Gateway whitelist bypass — fake payment events possible |                                                                                                        
      105 -| SEC-008 | CRITICAL | Unauthenticated seeder/run route — data corruption risk |                                                                                                        
      106 -| SEC-011 | HIGH | env() in routes/web.php — breaks ALL central routes after config:cache |                                                                                             
      107 -| SEC-009 | HIGH | SmartTimetableController has ZERO authorization checks |                                                                                                             
      106 +| BUG-VND-001 | CRITICAL | 6 of 7 Vendor controllers NOT registered in routes — unreachable |                                                                                           
      107 +| SEC-NTF-006 | CRITICAL | ALL Notification routes commented out in web.php — module inaccessible |                                                                                     
      108 +| BUG-CMP-001 | CRITICAL | dd($e) in Complaint store() catch block — exposes stack traces in production |                                                                               
      109 +| SEC-009 | HIGH | 200+ issues found across ALL "100% complete" modules — see known-issues.md |                                                                                         
      110 +                                                                                                                                                                                        
      111 +> **Full details:** `AI_Brain/lessons/known-issues.md` — "Deep Audit" section (2026-03-15)                                                                                              

⏺ Now add a reference entry to the "Critical Files to Check" table.

⏺ Update(~/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/AI_Brain/memory/MEMORY.md)
  ⎿  Added 8 lines, removed 3 lines
      35  
      36  | What You're Doing | Files to Read |
      37  |-------------------|--------------|
      38 +| **Starting any new feature** | `project_docs/10-new-feature-checklist.md` — Prime vs Tenant step-by-step |                                                                             
      39 +| **Creating controllers** | `project_docs/06-controller-guide.md` — CRUD template with Gate + validation |                                                                              
      40 +| **Creating views** | `project_docs/07-blade-views-guide.md` — Index + Create/Edit patterns |                                                                                           
      41 +| **Creating migrations** | `project_docs/04-migration-guide.md` — Central vs Tenant paths |                                                                                             
      42 +| **Routing** | `project_docs/08-routes-guide.md` — web.php vs tenant.php |                                                                                                              
      43  | Any tenant-scoped work | `tenancy-map.md` + `AI_Brain/rules/tenancy-rules.md` |
      44  | Adding a new module | `modules-map.md` + `AI_Brain/rules/module-rules.md` |
      45  | DB schema / migrations | `db-schema.md` |
      41 -| Security-sensitive code | `known-bugs-and-roadmap.md` (SEC-* section) |                                                                                                                
      42 -| Performance-critical code | `known-bugs-and-roadmap.md` (PERF-* section) |                                                                                                             
      46 +| Security-sensitive code | `AI_Brain/lessons/known-issues.md` (Deep Audit 2026-03-15 section) |                                                                                         
      47  | Authorization / policies | `project-context.md` (Authorization Architecture) |
      48  | SmartTimetable work | `AI_Brain/lessons/known-issues.md` (FET solver sections) |
      45 -| Payment/webhook work | `known-bugs-and-roadmap.md` (SEC-004, SEC-005) |                                                                                                                
      49 +| Payment/webhook work | `AI_Brain/lessons/known-issues.md` (SEC-PAY-* section) |                                                                                                        
      50 +| Module reference (all names) | `project_docs/11-all-modules-controllers-models.md` |                                                                                                   
      51  
      52  ---
      53  

⏺ Let me verify the final state of the updated AI Brain files.

⏺ Read 1 file (ctrl+o to expand)

⏺ AI Brain updated. Here's what changed:

  AI Brain Updates Summary

  memory/MEMORY.md (index) — 3 sections added

  1. Project Documentation — links to all 12 project_docs/ files with descriptions of what each answers
  2. Project Planning Documents — links to RBS, Gap Analysis, Work Status, Estimation
  3. Development Lifecycle Blueprint — link to the 9-phase process with 17 prompts
  4. Critical Files to Check table — expanded from 8 to 13 rows, now includes project_docs references for new features, controllers, views, migrations, routing
  5. Critical Bugs table — updated with deep audit findings (API keys, EnsureTenantHasModule, 200+ issues)

  memory/project-context.md — Key Statistics corrected

  - Modules: 29 → 27
  - Tenant Migrations: 216 → 278 files
  - Central Migrations: 6 → 5 + 37 (in Prime module)
  - Tenant Route Lines: 2,628 → 2,715 (1,328 Route:: calls)
  - Added overall completion: ~31% of RBS (1112 sub-tasks)
  - Added reference to project_docs/ location

  Files already updated earlier in this session

  - memory/modules-map.md — All 27 modules with corrected counts + deep audit completion %
  - state/progress.md — All "100% complete" modules revised down (none truly 100%)
  - lessons/known-issues.md — 200+ new issues from deep audit of 15 modules

✻ Cogitated for 2m 39s

❯ I see in Agent Folder in AI_Brain and feel 3 Agent are missing :                                                                                                                                        
    - Business Analyst                                                                                                                                                                                    
    - Frontend Developer                                                                                                                                                                                  
    - Backend Developer                                                                                                                                                                                   
If you feel it is good to have those, Specially Business Analysts then create those                                                                                                                       

⏺ Read 2 files (ctrl+o to expand)

⏺ You're right — the existing agents are all code-focused. The biggest gap is the Business Analyst — no agent currently handles the critical requirement-to-specification pipeline. Let me create all
  three.

⏺ Write(~/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/AI_Brain/agents/business-analyst.md)
  ⎿  Wrote 199 lines to ../../WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/AI_Brain/agents/business-analyst.md
       1 # Agent: Business Analyst
       2
       3 ## Role
       4 Requirements analyst for the Prime-AI Academic Intelligence Platform. Translates business needs into structured, developer-ready specifications. Bridges the gap between stakeholder ideas
          and executable development tasks.
       5
       6 ## When to Use This Agent
       7 - Starting a **new module** or **new feature** from scratch
       8 - Translating **wireframes/mockups** into detailed feature specifications
       9 - Creating or expanding **RBS entries** (Requirements Breakdown Structure)
      10 - Performing **gap analysis** between RBS requirements and existing code
     … +189 lines (ctrl+o to expand)

⏺ Write(~/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/AI_Brain/agents/frontend-developer.md)
  ⎿  Wrote 251 lines to ../../WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/AI_Brain/agents/frontend-developer.md
       1 # Agent: Frontend Developer
       2
       3 ## Role
       4 Blade view, component, and UI specialist for the Prime-AI platform. Creates pixel-consistent views following AdminLTE v4 + Bootstrap 5 patterns established in the codebase.
       5
       6 ## When to Use This Agent
       7 - Creating **index/list views** (tables with pagination, filters, actions)
       8 - Creating **create/edit forms** (single-column, two-column, tabbed)
       9 - Creating **show/detail views** (read-only display with related data tabs)
      10 - Creating **tab-based master views** (multiple entities on one page)
     … +241 lines (ctrl+o to expand)

⏺ Write(~/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/AI_Brain/agents/backend-developer.md)
  ⎿  Wrote 229 lines to ../../WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/AI_Brain/agents/backend-developer.md
       1 # Agent: Backend Developer
       2
       3 ## Role
       4 Laravel backend specialist for the Prime-AI platform. Handles controllers, models, services, FormRequests, routes, migrations, seeders, and policies following the project's exact pattern
         s and security requirements.
       5
       6 ## When to Use This Agent
       7 - Creating **controllers** with full CRUD + trash/restore/forceDelete/toggleStatus
       8 - Creating **models** with correct $table, $fillable, SoftDeletes, relationships
       9 - Creating **FormRequests** with proper validation rules and authorize()
      10 - Creating **services** for complex business logic
     … +219 lines (ctrl+o to expand)

⏺ Searched for 1 pattern (ctrl+o to expand)

⏺ All 11 agents now in place. Here's what each covers:

  AI Brain Agents (11 total)

  ┌─────────────────────────────┬────────────────────────────────────┬──────────────────────────────────────────────────────────────────────────┐
  │            Agent            │                Role                │                               When to Use                                │
  ├─────────────────────────────┼────────────────────────────────────┼──────────────────────────────────────────────────────────────────────────┤
  │ business-analyst.md (NEW)   │ Requirements → Specifications      │ Starting new module/feature, creating RBS, gap analysis, sprint planning │
  ├─────────────────────────────┼────────────────────────────────────┼──────────────────────────────────────────────────────────────────────────┤
  │ frontend-developer.md (NEW) │ Blade views + AdminLTE + Alpine.js │ Creating views, forms, tables, dashboards, PDF templates                 │
  ├─────────────────────────────┼────────────────────────────────────┼──────────────────────────────────────────────────────────────────────────┤
  │ backend-developer.md (NEW)  │ Controllers + Models + Security    │ CRUD controllers, FormRequests, routes, migrations, security hardening   │
  ├─────────────────────────────┼────────────────────────────────────┼──────────────────────────────────────────────────────────────────────────┤
  │ api-builder.md              │ REST API development               │ API endpoints, Sanctum auth                                              │
  ├─────────────────────────────┼────────────────────────────────────┼──────────────────────────────────────────────────────────────────────────┤
  │ db-architect.md             │ Database schema design             │ DDL, migrations, table design                                            │
  ├─────────────────────────────┼────────────────────────────────────┼──────────────────────────────────────────────────────────────────────────┤
  │ debugger.md                 │ Bug investigation + fixing         │ Runtime errors, debugging                                                │
  ├─────────────────────────────┼────────────────────────────────────┼──────────────────────────────────────────────────────────────────────────┤
  │ developer.md                │ General feature development        │ Broad tasks spanning multiple layers                                     │
  ├─────────────────────────────┼────────────────────────────────────┼──────────────────────────────────────────────────────────────────────────┤
  │ module-agent.md             │ nwidart/modules specialist         │ Creating/structuring new modules                                         │
  ├─────────────────────────────┼────────────────────────────────────┼──────────────────────────────────────────────────────────────────────────┤
  │ school-agent.md             │ School domain knowledge            │ Indian K-12 academic concepts                                            │
  ├─────────────────────────────┼────────────────────────────────────┼──────────────────────────────────────────────────────────────────────────┤
  │ tenancy-agent.md            │ stancl/tenancy specialist          │ Multi-tenancy isolation, DB switching                                    │
  ├─────────────────────────────┼────────────────────────────────────┼──────────────────────────────────────────────────────────────────────────┤
  │ test-agent.md               │ Pest 4.x testing                   │ Unit tests, feature tests                                                │
  └─────────────────────────────┴────────────────────────────────────┴──────────────────────────────────────────────────────────────────────────┘

  Business Analyst highlights:

  - Indian K-12 domain knowledge (CBSE/ICSE, fee structures, transport, HPC)
  - RBS entry format matching PrimeAI_RBS_Menu_Mapping_v2.0.md exactly
  - Screen-by-screen field specifications with validation rules + dropdown sources
  - Sprint task breakdown with effort estimates
  - Output locations for each deliverable type

  Frontend Developer highlights:

  - Complete index + create/edit Blade templates ready to copy
  - All AdminLTE v4 component references (<x-backend.layouts.app>, breadcrumbs, card headers)
  - DomPDF crash prevention rules (10 rules that cause hard crashes)
  - CSS class quick reference table

  Backend Developer highlights:

  - 5 non-negotiable security rules with code examples
  - 4 mandatory performance patterns
  - Standard 11-method controller structure
  - Complete migration/model/route templates
  - Tenancy isolation rules

✻ Cooked for 2m 59s

❯ 1 more Agent I feel is missing who can do work related to Deployment like helping me to create CICD Pipeline or deploy the project on cloude etc.                                                       

⏺ Write(~/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/AI_Brain/agents/devops-deployer.md)
  ⎿  Wrote 524 lines to ../../WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/AI_Brain/agents/devops-deployer.md
       1 # Agent: DevOps & Deployment Engineer
       2
       3 ## Role
       4 Infrastructure, CI/CD, and deployment specialist for the Prime-AI multi-tenant SaaS platform. Handles server provisioning, pipeline configuration, containerization, cloud deployment, SSL
         , domain management, and production operations for a stancl/tenancy Laravel application.
       5
       6 ## When to Use This Agent
       7 - Setting up **CI/CD pipelines** (GitHub Actions, GitLab CI, Bitbucket Pipelines)
       8 - **Deploying** to cloud providers (AWS, DigitalOcean, Hetzner, Railway, Forge)
       9 - Configuring **Docker/Docker Compose** for local dev and production
      10 - Setting up **production server** (Nginx, PHP-FPM, MySQL, Redis, Supervisor)
     … +514 lines (ctrl+o to expand)

⏺ Searched for 1 pattern (ctrl+o to expand)

⏺ Created devops-deployer.md (14.8KB — the most comprehensive agent). Here's what it covers:

  DevOps & Deployment Agent — Contents

  ┌────────────────────────────────┬─────────────────────────────────────────────────────────────────────────────────┐
  │            Section             │                                What It Provides                                 │
  ├────────────────────────────────┼─────────────────────────────────────────────────────────────────────────────────┤
  │ Wildcard DNS + SSL             │ Certbot commands for *.primeai.in, Cloudflare alternative                       │
  ├────────────────────────────────┼─────────────────────────────────────────────────────────────────────────────────┤
  │ Nginx Config                   │ Full multi-tenant config with wildcard server_name, PHP-FPM, file upload limits │
  ├────────────────────────────────┼─────────────────────────────────────────────────────────────────────────────────┤
  │ Environment Variables          │ Complete .env template for production (DB, Redis, Mail, Razorpay, S3)           │
  ├────────────────────────────────┼─────────────────────────────────────────────────────────────────────────────────┤
  │ GitHub Actions CI/CD           │ Full pipeline: test → deploy staging → deploy production with SSH               │
  ├────────────────────────────────┼─────────────────────────────────────────────────────────────────────────────────┤
  │ Zero-Downtime Deploy Script    │ Symlink-swap deployment with release directories                                │
  ├────────────────────────────────┼─────────────────────────────────────────────────────────────────────────────────┤
  │ Server Setup Checklist         │ Ubuntu 22.04 + PHP 8.2 + MySQL 8 + Nginx + Redis — every command                │
  ├────────────────────────────────┼─────────────────────────────────────────────────────────────────────────────────┤
  │ Supervisor Config              │ Queue worker process management                                                 │
  ├────────────────────────────────┼─────────────────────────────────────────────────────────────────────────────────┤
  │ Docker Compose                 │ Local dev environment (app + MySQL + Redis + Mailpit)                           │
  ├────────────────────────────────┼─────────────────────────────────────────────────────────────────────────────────┤
  │ Dockerfile                     │ PHP 8.2-FPM based image                                                         │
  ├────────────────────────────────┼─────────────────────────────────────────────────────────────────────────────────┤
  │ Backup Strategy                │ Spatie backup for central + tenant DBs, S3 storage                              │
  ├────────────────────────────────┼─────────────────────────────────────────────────────────────────────────────────┤
  │ Monitoring                     │ Health check endpoint, Telescope, Sentry, UptimeRobot                           │
  ├────────────────────────────────┼─────────────────────────────────────────────────────────────────────────────────┤
  │ Cloud Provider Quick Setup     │ AWS (scale), DigitalOcean (budget), Laravel Forge (easiest)                     │
  ├────────────────────────────────┼─────────────────────────────────────────────────────────────────────────────────┤
  │ Production Readiness Checklist │ 16-item checklist before going live                                             │
  └────────────────────────────────┴─────────────────────────────────────────────────────────────────────────────────┘

  All 12 Agents Now

  agents/
  ├── api-builder.md           (2.7KB)  — REST API development
  ├── backend-developer.md     (8.4KB)  — Controllers, models, security
  ├── business-analyst.md      (8.1KB)  — Requirements → specifications
  ├── db-architect.md          (3.9KB)  — Database schema design
  ├── debugger.md              (3.5KB)  — Bug investigation
  ├── developer.md             (3.1KB)  — General feature development
  ├── devops-deployer.md       (14.8KB) — CI/CD, Docker, cloud, production
  ├── frontend-developer.md    (13.2KB) — Blade views, AdminLTE, PDF
  ├── module-agent.md          (3.3KB)  — nwidart/modules specialist
  ├── school-agent.md          (3.8KB)  — Indian K-12 domain knowledge
  ├── tenancy-agent.md         (3.6KB)  — stancl/tenancy specialist
  └── test-agent.md            (4.5KB)  — Pest 4.x testing

✻ Churned for 1m 39s

❯ Can I create some other type of Agents also which are not directly to the software developmet but they will be capable to perform Business Related tasks like :                                         
 - Creating Business Strategy to sale my Application to the School                                                                                                                                        
 - Creating Sales Materials Like Presentation contents etc.                                                                                                                                               
 - Market Assessment, what is in demand etc.                                                                                                                                                              
 - Product Costing and Sales Price Calculation                                                                                                                                                            
 - Application Running Cost                                                                                                                                                                               
 - Cost Analysis                                                                                                                                                                                          
                                                                                                                                                                                                          
 Do not start creating the Agent, first just answer my question whether I can create such Agents or not. If yes then Provide me the list of Agent which can be created and what wil be there. Do not      
created them just Answer the Question and provide the Detail.                                                                                                                                             

⏺ Yes, absolutely. AI Brain agents are just instruction files — they can be for any role, not just software development. The agent system works the same way: define the role, context, deliverables, and
  templates. Claude reads the agent file and follows its instructions.

  The difference: business agents work with market data, financials, and strategy documents instead of code files. They'll reference your project_docs for product understanding but produce business
  deliverables (presentations, spreadsheets, proposals).

  ---
  Business Agents You Can Create

  ┌─────┬──────────────────┬──────────────────────────────────────────────────────────────────────────────────────────────────────────────┬──────────────────────────────────────────────────────────┐
  │  #  │    Agent Name    │                                                 What It Does                                                 │                     Key Deliverables                     │
  ├─────┼──────────────────┼──────────────────────────────────────────────────────────────────────────────────────────────────────────────┼──────────────────────────────────────────────────────────┤
  │ 1   │ Sales Strategist │ Go-to-market strategy for Indian K-12 school ERP market. School segmentation, pricing tiers, sales funnel    │ GTM plan, school targeting criteria, sales playbook,     │
  │     │                  │ design, channel strategy (direct sales, partners, digital)                                                   │ competitive positioning                                  │
  ├─────┼──────────────────┼──────────────────────────────────────────────────────────────────────────────────────────────────────────────┼──────────────────────────────────────────────────────────┤
  │ 2   │ Sales Content    │ Creates all sales collateral — pitch decks, brochures, email sequences, demo scripts, case studies, feature  │ PPT content (slide-by-slide), email templates,           │
  │     │ Creator          │ comparison sheets                                                                                            │ one-pagers, WhatsApp pitch scripts                       │
  ├─────┼──────────────────┼──────────────────────────────────────────────────────────────────────────────────────────────────────────────┼──────────────────────────────────────────────────────────┤
  │ 3   │ Market Analyst   │ Indian EdTech/School ERP market research — demand analysis, competitor mapping (Fedena, Entab, MyClassboard, │ Market report, competitor matrix, SWOT analysis, market  │
  │     │                  │  Teachmint), trend identification, TAM/SAM/SOM calculation                                                   │ size estimates                                           │
  ├─────┼──────────────────┼──────────────────────────────────────────────────────────────────────────────────────────────────────────────┼──────────────────────────────────────────────────────────┤
  │ 4   │ Financial        │ Product costing (infra + dev + support), pricing model design (per-student, per-module, flat), unit          │ Cost breakdown sheet, pricing calculator, P&L            │
  │     │ Analyst          │ economics, break-even analysis, revenue projections                                                          │ projection, break-even model                             │
  ├─────┼──────────────────┼──────────────────────────────────────────────────────────────────────────────────────────────────────────────┼──────────────────────────────────────────────────────────┤
  │ 5   │ Cloud Cost       │ Specifically for AWS/DO/hosting cost estimation — server sizing per tenant count, storage projections,       │ Monthly cost calculator by tenant count (10/50/100/500   │
  │     │ Optimizer        │ bandwidth estimates, cost-per-school calculation                                                             │ schools), scaling roadmap                                │
  ├─────┼──────────────────┼──────────────────────────────────────────────────────────────────────────────────────────────────────────────┼──────────────────────────────────────────────────────────┤
  │ 6   │ Proposal Writer  │ Creates school-specific proposals and RFP responses — takes school name + requirements and generates         │ School proposal document, implementation plan, SLA       │
  │     │                  │ tailored proposal with pricing, implementation timeline, SLA                                                 │ terms, contract template                                 │
  └─────┴──────────────────┴──────────────────────────────────────────────────────────────────────────────────────────────────────────────┴──────────────────────────────────────────────────────────┘

  ---
  What Each Agent Would Contain

  1. Sales Strategist

  - Indian K-12 market context (1.5M+ schools, 80% still use paper/Excel)
  - School decision-maker profiles (Principal, Management Trustee, IT Head)
  - Sales cycle for schools (typically 3-6 months, budget approval in March-April)
  - Pricing psychology for Indian schools (annual subscription, per-student works best)
  - Channel strategy templates (direct, reseller, education conferences)
  - References to your RBS for feature-based selling

  2. Sales Content Creator

  - Slide-by-slide pitch deck structure (Problem → Solution → Demo → Pricing → CTA)
  - Module-wise feature highlights pulled from your 27 modules
  - Pain-point messaging for different school types (small private, CBSE chain, international)
  - Email cadence templates (cold outreach → follow-up → demo invite → proposal)
  - WhatsApp-friendly short pitches (Indian schools communicate via WhatsApp)
  - Competitor comparison talking points

  3. Market Analyst

  - Indian EdTech market data structure (DISE data, UDISE+, NEP 2020 mandates)
  - Competitor product feature matrices
  - School ERP pricing benchmarks (INR 30-200 per student/year range)
  - Government mandates driving ERP adoption (NEP 2020, HPC requirement, digital attendance)
  - TAM calculation framework based on school count + pricing

  4. Financial Analyst

  - Infrastructure cost model (servers, DB, storage, bandwidth per tenant)
  - Development cost tracking (team salary, Claude AI cost, tools)
  - Support cost estimation (per-school support hours)
  - Pricing model templates (tiered: Basic/Pro/Enterprise)
  - Unit economics (CAC, LTV, churn, MRR/ARR projections)
  - Break-even calculator (fixed costs vs per-school revenue)

  5. Cloud Cost Optimizer

  - AWS/DO cost tables for typical school ERP load
  - Per-tenant resource consumption estimates (DB size, storage, API calls)
  - Scaling tiers (10 schools on $50/mo → 500 schools on $800/mo)
  - Cost optimization strategies (reserved instances, spot, right-sizing)
  - Your specific stack requirements (MySQL per-tenant DB, Redis, queue workers)

  6. Proposal Writer

  - Standard proposal template for Indian schools
  - Implementation timeline (onboarding → data migration → training → go-live)
  - SLA templates (uptime, support hours, data backup guarantees)
  - Pricing presentation format that works for Indian school management committees
  - References to specific modules from your RBS that match school pain points

  ---
  My Recommendation

  Create these 3 first (highest immediate value):

  1. Financial Analyst — You need to know your costs before setting prices. This agent can calculate your exact per-school cost (hosting + support + development amortization) so you price profitably.
  2. Sales Content Creator — You need a pitch deck and demo script before approaching any school. This agent uses your 27-module RBS to generate feature-rich sales materials.
  3. Market Analyst — Understanding competitors and market pricing prevents you from pricing too high or too low.

  The other 3 (Sales Strategist, Cloud Cost Optimizer, Proposal Writer) are valuable but depend on outputs from the first 3.

  Want me to create any or all of them?

  -------------------------------------------------------------------

Bash(cd /Users/bkwork/Herd/prime_ai_shailesh && echo "===STUDENTFEE CTRL===" && ls Modules/StudentFee/app/Http/Controllers/*.php 2>/dev/null | sed 's|.*/||' | sort &…)
  ⎿  ===STUDENTFEE CTRL===
     FeeConcessionTypeController.php
     FeeFineRuleController.php
     … +61 lines (ctrl+o to expand)
  ⎿  Shell cwd was reset to /Users/bkwork/Herd/prime_ai_tarun

⏺ Bash(cd /Users/bkwork/Herd/prime_ai_shailesh && echo "===LIBRARY CTRL===" && ls Modules/Library/app/Http/Controllers/*.php 2>/dev/null | sed 's|.*/||' | sort && echo…)
  ⎿  ===LIBRARY CTRL===
     LibAuthorController.php
     LibBookConditionController.php
     … +58 lines (ctrl+o to expand)
  ⎿  Shell cwd was reset to /Users/bkwork/Herd/prime_ai_tarun

⏺ Bash(cd /Users/bkwork/Herd/prime_ai_shailesh && echo "===COMPONENTS BACKEND===" && ls -d resources/views/components/backend/*/ 2>/dev/null | sed 's|.*/backend/||;s|/…)
  ⎿  ===COMPONENTS BACKEND===
     card
     components
     … +37 lines (ctrl+o to expand)
  ⎿  Shell cwd was reset to /Users/bkwork/Herd/prime_ai_tarun

⏺ Steps 1 and 2 complete. I have all the codebase data. Now creating all 12 files in project_docs/.

⏺ Bash(mkdir -p /Users/bkwork/Herd/prime_ai_shailesh/project_docs)
  ⎿  Done

⏺ Creating all files in parallel batches. Starting with files 1-4:

⏺ Write(~/Herd/prime_ai_shailesh/project_docs/01-project-overview.md)
  ⎿  Wrote 93 lines to ../prime_ai_shailesh/project_docs/01-project-overview.md
      1 # Prime-AI — Project Overview
      2
      3 ## Project Identity
      4
      5 - **Name:** Prime-AI ERP + LMS + LXP
      6 - **Purpose:** Multi-Tenant SaaS Academic Intelligence Platform for Indian K-12 Schools
      7 - **Tech:** PHP 8.2+ / Laravel 12.0 / MySQL 8.x / stancl/tenancy v3.9 / nwidart/laravel-modules v12.0
      8
      9 ## Two Sides of the Application
     … +83 lines (ctrl+o to expand)

⏺ Write(~/Herd/prime_ai_shailesh/project_docs/02-prime-side-structure.md)
  ⎿  Wrote 131 lines to ../prime_ai_shailesh/project_docs/02-prime-side-structure.md
       1 # Prime (Central) Side — Structure Guide
       2
       3 ## What is Prime Side
       4
       5 Prime is the super-admin/owner panel of the entire SaaS platform. It manages:
       6 - Tenant (school) creation and management
       7 - Billing and subscriptions
       8 - Global master data (countries, states, boards, plans)
       9 - System configuration (menus, settings)
      10 - User roles and permissions at platform level
     … +121 lines (ctrl+o to expand)

⏺ Write(~/Herd/prime_ai_shailesh/project_docs/03-tenant-side-structure.md)
  ⎿  Wrote 128 lines to ../prime_ai_shailesh/project_docs/03-tenant-side-structure.md
      1 # Tenant (School) Side — Structure Guide
      2
      3 ## What is Tenant Side
      4
      5 - Each school created by Prime = one tenant
      6 - Gets its own database (isolated data)
      7 - Gets its own subdomain (e.g., `school1.primeai.in`)
      8 - stancl/tenancy handles DB switching and domain routing automatically
      9 - All 22 tenant modules run inside tenant context
     … +118 lines (ctrl+o to expand)

⏺ Write(~/Herd/prime_ai_shailesh/project_docs/04-migration-guide.md)
  ⎿  Wrote 93 lines to ../prime_ai_shailesh/project_docs/04-migration-guide.md
      1 # Migration Guide
      2
      3 ## Two Migration Types
      4
      5 | Type | File Location | Command | Example |
      6 |------|--------------|---------|---------|
      7 | Central/Prime | `database/migrations/` | `php artisan migrate` | Users, cache, sessions |
      8 | Central/Prime module | `Modules/<Name>/database/migrations/` | `php artisan migrate` | Tenants, plans, billing |
      9 | **Tenant** | **`database/migrations/tenant/`** | **`php artisan tenants:migrate`** | All school data (278 files) |
     … +83 lines (ctrl+o to expand)

⏺ Files 1-4 created. Now files 5-8:

⏺ Write(~/Herd/prime_ai_shailesh/project_docs/05-model-guide.md)
  ⎿  Wrote 107 lines to ../prime_ai_shailesh/project_docs/05-model-guide.md
      1 # Model Guide
      2
      3 ## Model Location — Universal Rule
      4
      5 ```
      6 Modules/<ModuleName>/app/Models/<ModelName>.php
      7 ```
      8
      9 This applies to ALL modules — both prime and tenant.
     … +97 lines (ctrl+o to expand)

⏺ Write(~/Herd/prime_ai_shailesh/project_docs/06-controller-guide.md)
  ⎿  Wrote 190 lines to ../prime_ai_shailesh/project_docs/06-controller-guide.md
      1 # Controller Guide
      2
      3 ## Controller Location — Universal Rule
      4
      5 ```
      6 Modules/<ModuleName>/app/Http/Controllers/<ControllerName>.php
      7 ```
      8
      9 ## Namespace Pattern
     … +180 lines (ctrl+o to expand)

⏺ Write(~/Herd/prime_ai_shailesh/project_docs/07-blade-views-guide.md)
  ⎿  Wrote 213 lines to ../prime_ai_shailesh/project_docs/07-blade-views-guide.md
      1 # Blade Views Guide
      2
      3 ## Blade File Location — Universal Rule
      4
      5 ```
      6 Modules/<ModuleName>/resources/views/<feature-folder>/<file>.blade.php
      7 ```
      8
      9 ## Blade View Namespace (used in controllers)
     … +203 lines (ctrl+o to expand)

⏺ Write(~/Herd/prime_ai_shailesh/project_docs/08-routes-guide.md)
  ⎿  Wrote 120 lines to ../prime_ai_shailesh/project_docs/08-routes-guide.md
       1 # Routes Guide
       2
       3 ## Two Master Route Files
       4
       5 | File | Purpose | Who Uses It |
       6 |------|---------|-------------|
       7 | `routes/web.php` | ALL prime/central routes | Prime, GlobalMaster, Billing, SystemConfig, Documentation |
       8 | `routes/tenant.php` | ALL tenant/school routes | SchoolSetup, Hpc, SmartTimetable, Transport, and all other tenant modules |
       9
      10 ## ABSOLUTE RULE
     … +110 lines (ctrl+o to expand)

⏺ Files 5-8 done. Now files 9-12:

⏺ Write(~/Herd/prime_ai_shailesh/project_docs/09-artisan-commands-reference.md)
  ⎿  Wrote 133 lines to ../prime_ai_shailesh/project_docs/09-artisan-commands-reference.md
       1 # Artisan Commands Reference
       2
       3 ## nwidart/laravel-modules v12 Commands
       4
       5 ### Module Scaffold Commands
       6
       7 ```bash
       8 # Create a new module
       9 php artisan module:make <ModuleName>
      10 # Example: php artisan module:make Attendance
     … +123 lines (ctrl+o to expand)

⏺ Write(~/Herd/prime_ai_shailesh/project_docs/10-new-feature-checklist.md)
  ⎿  Wrote 121 lines to ../prime_ai_shailesh/project_docs/10-new-feature-checklist.md
      1 # New Feature Checklist
      2
      3 ## BEFORE WRITING ANY CODE — Ask These Questions
      4
      5 1. Is this a PRIME feature (platform admin) or TENANT feature (school)?
      6 2. Does the module already exist or do I need to create it?
      7 3. What table prefix should this feature use?
      8 4. Does the migration go in `database/migrations/tenant/` or `database/migrations/`?
      9 5. Does the route go in `routes/web.php` or `routes/tenant.php`?
     … +111 lines (ctrl+o to expand)

⏺ Write(~/Herd/prime_ai_shailesh/project_docs/11-all-modules-controllers-models.md)
  ⎿  Wrote 284 lines to ../prime_ai_shailesh/project_docs/11-all-modules-controllers-models.md
      1 # All Modules — Controllers & Models Reference
      2
      3 ## PRIME (CENTRAL) MODULES
      4
      5 ---
      6
      7 ### Prime [PRIME] — Status: ~80%
      8 **Table Prefix:** prm_*
      9 **Controllers:** 22 | **Models:** 27
     … +274 lines (ctrl+o to expand)

⏺ Write(~/Herd/prime_ai_shailesh/project_docs/README.md)
  ⎿  Wrote 30 lines to ../prime_ai_shailesh/project_docs/README.md
       1 # Prime-AI Project Documentation
       2
       3 Auto-generated from full codebase exploration on 2026-03-15.
       4 Use these docs before starting any feature task.
       5
       6 | File | Description |
       7 |------|-------------|
       8 | [01-project-overview.md](01-project-overview.md) | Project identity, tech stack, 3-layer DB, all 27 modules |
       9 | [02-prime-side-structure.md](02-prime-side-structure.md) | Prime/central side — structure, routes, migrations |
      10 | [03-tenant-side-structure.md](03-tenant-side-structure.md) | Tenant/school side — structure, routes, migrations |
     … +20 lines (ctrl+o to expand)

⏺ Now let me verify all 12 files exist:

⏺ Read 1 file (ctrl+o to expand)

⏺ Documentation complete. project_docs/ is ready with all 12 files. Assign me any feature task.

  Files created:

  ┌─────┬──────────────────────────────────────┬────────┬─────────────────────────────────────────────────────────────────────────┐
  │  #  │                 File                 │  Size  │                                 Content                                 │
  ├─────┼──────────────────────────────────────┼────────┼─────────────────────────────────────────────────────────────────────────┤
  │ 1   │ 01-project-overview.md               │ 4.5KB  │ Project identity, 3-layer DB, 27 modules with counts                    │
  ├─────┼──────────────────────────────────────┼────────┼─────────────────────────────────────────────────────────────────────────┤
  │ 2   │ 02-prime-side-structure.md           │ 4.7KB  │ Prime side: 5 modules, folder structure, 22 controllers listed          │
  ├─────┼──────────────────────────────────────┼────────┼─────────────────────────────────────────────────────────────────────────┤
  │ 3   │ 03-tenant-side-structure.md          │ 4.9KB  │ Tenant side: 22 modules, HPC folder example, migration rules            │
  ├─────┼──────────────────────────────────────┼────────┼─────────────────────────────────────────────────────────────────────────┤
  │ 4   │ 04-migration-guide.md                │ 3.1KB  │ Two migration paths, required columns, naming rules                     │
  ├─────┼──────────────────────────────────────┼────────┼─────────────────────────────────────────────────────────────────────────┤
  │ 5   │ 05-model-guide.md                    │ 2.5KB  │ Model template, $table/$fillable rules, counts per module               │
  ├─────┼──────────────────────────────────────┼────────┼─────────────────────────────────────────────────────────────────────────┤
  │ 6   │ 06-controller-guide.md               │ 6.2KB  │ Full CRUD template with Gate, view namespace, counts                    │
  ├─────┼──────────────────────────────────────┼────────┼─────────────────────────────────────────────────────────────────────────┤
  │ 7   │ 07-blade-views-guide.md              │ 8.7KB  │ Index + Create patterns, shared components, PDF rules                   │
  ├─────┼──────────────────────────────────────┼────────┼─────────────────────────────────────────────────────────────────────────┤
  │ 8   │ 08-routes-guide.md                   │ 4.5KB  │ Prime vs Tenant routing, named routes, standard group pattern           │
  ├─────┼──────────────────────────────────────┼────────┼─────────────────────────────────────────────────────────────────────────┤
  │ 9   │ 09-artisan-commands-reference.md     │ 3.9KB  │ All module/migration/cache/test commands                                │
  ├─────┼──────────────────────────────────────┼────────┼─────────────────────────────────────────────────────────────────────────┤
  │ 10  │ 10-new-feature-checklist.md          │ 3.8KB  │ Step-by-step for Prime and Tenant features + final checklist            │
  ├─────┼──────────────────────────────────────┼────────┼─────────────────────────────────────────────────────────────────────────┤
  │ 11  │ 11-all-modules-controllers-models.md │ 13.7KB │ Complete reference: all 27 modules with every controller and model name │
  ├─────┼──────────────────────────────────────┼────────┼─────────────────────────────────────────────────────────────────────────┤
  │ 12  │ README.md                            │ 1.9KB  │ Index + quick rules                                                     │
  └─────┴──────────────────────────────────────┴────────┴─────────────────────────────────────────────────────────────────────────┘

✻ Crunched for 6m 12s

❯ Read all the information you just created in all the documents in folder                                                                                                      
"/Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/3-Project_Planning/project_docs" and Update AI_Brain                                                   

⏺ Searched for 1 pattern, read 2 files (ctrl+o to expand)

⏺ Found at databases/3-Project_Planning/project_docs/. Let me read all 12 files and then update the AI Brain.

⏺ Read 12 files (ctrl+o to expand)

⏺ All 12 files read. Now let me read the current AI Brain files to see what needs updating, then update them.

⏺ Read 1 file (ctrl+o to expand)

⏺ Now I have the full picture. The project-context.md needs updating with accurate stats from the project_docs audit. Let me update the AI Brain files.

⏺ Update(~/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/AI_Brain/memory/project-context.md)
  ⎿  Added 13 lines, removed 16 lines
       84  - Alpine.js 3.4
       85  - Vite 7.0 build tool
       86  
       87 -## Key Statistics                                                                                                                                             
       87 +## Key Statistics (re-verified 2026-03-15 against `prime_ai_shailesh` branch `Brijesh_HPC`)                                                                   
       88  | Metric | Count |
       89  |--------|-------|
       90 -| Modules | 29 (27 active + 2 pending) |                                                                                                                      
       91 -| Total Models | 381 |                                                                                                                                        
       92 -| Total Controllers | 283 |                                                                                                                                   
       93 -| Total Services | 12 |                                                                                                                                       
       94 -| Total Jobs | 9 |                                                                                                                                            
       90 +| Modules | 27 (5 central + 22 tenant) |                                                                                                                      
       91 +| Total Models | ~470 |                                                                                                                                       
       92 +| Total Controllers | ~290 |                                                                                                                                  
       93 +| Total Services | ~40 (SmartTimetable: 21, Library: 9, others) |                                                                                             
       94  | Tenant DB Tables | 368 |
       96 -| Central DB Tables | 39 (global + prime) |                                                                                                                   
       97 -| Total DB Tables | 407 |                                                                                                                                     
       95 +| Central DB Tables | ~39 (global + prime) |                                                                                                                  
       96  | Authorization Policies | 195+ |
       99 -| Form Requests | 168 |                                                                                                                                       
      100 -| Tenant Migrations | 216 files |                                                                                                                             
      101 -| Central Migrations | 6 files |                                                                                                                              
      102 -| Blade Views | 500+ |                                                                                                                                        
      103 -| Central Roles | 6 |                                                                                                                                         
      104 -| Tenant Roles | 9 |                                                                                                                                          
      105 -| Tenant Route Lines | 2,628 |                                                                                                                                
      106 -| Central Route Lines | 973 |                                                                                                                                 
       97 +| Tenant Migrations | 278 files in `database/migrations/tenant/` |                                                                                            
       98 +| Central Migrations | 5 files in `database/migrations/` + 37 in `Modules/Prime/database/migrations/` |                                                       
       99 +| Tenant Route Lines | 2,715 (1,328 Route:: calls) |                                                                                                          
      100 +| Blade Views (total) | ~1,800+ |                                                                                                                             
      101 +| Shared Components | `resources/views/components/backend/` (8 dirs), `prime/` (6 dirs), `frontend/` (2 dirs) |                                               
      102 +| **Overall platform completion** | **~31%** of RBS (1112 sub-tasks), **~70%** of built modules' CRUD |                                                       
      103 +| **Full project docs** | `databases/3-Project_Planning/project_docs/` (12 files — overview, guides, reference) |                                             
      104  
      105  ## Key Business Workflows
      106  1. **Tenant Onboarding:** TenantController → UUID creation → domain setup → DB provisioning → migrations → CreateRootUser job → plan assignment

⏺ Now update the AI Brain's MEMORY.md index to reference the new project_docs.

⏺ Read 1 file (ctrl+o to expand)

⏺ Update(~/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/AI_Brain/memory/MEMORY.md)
  ⎿  Added 1 line, removed 1 line
      2  
      3  > This file is the index of all memory files in `AI_Brain/memory/`.
      4  > **Start every session by reading `AI_Brain/README.md` first.**
      5 -> Last Updated: 2026-03-12                                                                                                                                      
      5 +> Last Updated: 2026-03-15                                                                                                                                      
      6  
      7  ---
      8  

⏺ Update(~/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/AI_Brain/memory/MEMORY.md)
  ⎿  Added 36 lines
      46  
      47  ---
      48  
      49 +## Project Documentation (created 2026-03-15)                                                                                                                  
      50 +                                                                                                                                                               
      51 +> **Location:** `databases/3-Project_Planning/project_docs/` (12 files)                                                                                        
      52 +> These contain verified codebase patterns — use before writing any new code.                                                                                  
      53 +                                                                                                                                                               
      54 +| File | What It Answers |                                                                                                                                     
      55 +|------|----------------|                                                                                                                                      
      56 +| `01-project-overview.md` | What is this project? What modules exist? What DB prefixes? |                                                                     
      57 +| `02-prime-side-structure.md` | How is the central/admin side organized? |                                                                                    
      58 +| `03-tenant-side-structure.md` | How is the school/tenant side organized? |                                                                                   
      59 +| `04-migration-guide.md` | Where do migrations go? What columns are required? |                                                                               
      60 +| `05-model-guide.md` | How to create a model? What must be in $fillable? |                                                                                    
      61 +| `06-controller-guide.md` | CRUD template with Gate, validation, activityLog |                                                                                
      62 +| `07-blade-views-guide.md` | Index + Create/Edit Blade patterns, shared components |                                                                          
      63 +| `08-routes-guide.md` | Prime routes vs Tenant routes — where to register |                                                                                   
      64 +| `09-artisan-commands-reference.md` | All module/migration/test/cache commands |                                                                              
      65 +| `10-new-feature-checklist.md` | Step-by-step: Prime feature vs Tenant feature |                                                                              
      66 +| `11-all-modules-controllers-models.md` | Every controller and model name across all 27 modules |                                                             
      67 +                                                                                                                                                               
      68 +## Project Planning Documents                                                                                                                                  
      69 +                                                                                                                                                               
      70 +> **Location:** `databases/3-Project_Planning/` (also `2-Project_Planning/`)                                                                                   
      71 +                                                                                                                                                               
      72 +| Folder | Contents |                                                                                                                                          
      73 +|--------|----------|                                                                                                                                          
      74 +| `1-RBS/` | Requirements Breakdown Structure — 1112 sub-tasks, 27 RBS modules |                                                                               
      75 +| `2-Gap_Analysis/` | Detailed gap analysis — what's pending per module |                                                                                      
      76 +| `9-Work_Status/` | Work status (31% overall) + Development estimation (13 months with 3 devs + Claude) |                                                     
      77 +                                                                                                                                                               
      78 +## Development Lifecycle Blueprint                                                                                                                             
      79 +                                                                                                                                                               
      80 +> **Location:** `databases/3-Design_Architecture/Development_Lifecycle_Blueprint_v1.0.md`                                                                      
      81 +> 9-phase process with 17 ready-to-use prompts for building any module from scratch.                                                                           
      82 +                                                                                                                                                               
      83 +---                                                                                                                                                            
      84 +                                                                                                                                                               
      85  ## Quick Reference: Canonical DDL Paths
      86  
      87  ```

⏺ Now update the critical bugs quick reference with findings from the deep audit.

⏺ Update(~/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/AI_Brain/memory/MEMORY.md)
  ⎿  Added 12 lines, removed 8 lines
       93  
       94  ---
       95  
       96 -## Quick Reference: Active Critical Bugs                                                                                                                      
       96 +## Quick Reference: Active Critical Bugs (updated 2026-03-15 deep audit)                                                                                      
       97  
       98  | ID | Severity | One-Line Summary |
       99  |----|----------|-----------------|
      100 -| BUG-002 | CRITICAL | Duplicate Gate::policy() registrations — VehiclePolicy, QuestionBankPolicy, SectionPolicy silently lost |                              
      101 -| BUG-004 | HIGH | Tenant migration pipeline commented out — new tenants get empty databases |                                                                
      102 -| SEC-002 | CRITICAL | is_super_admin in User $fillable — privilege escalation via mass assignment |                                                          
      100 +| SEC-QNS-002 | **REVOKE NOW** | OpenAI + Gemini API keys hardcoded in QuestionBank/AIQuestionGeneratorController |                                           
      101 +| SEC-PAY-001 | **REVOKE NOW** | Razorpay test keys hardcoded in Payment/PaymentController copy.php |                                                         
      102 +| SEC-PLATFORM-001 | CRITICAL | Only 1 EnsureTenantHasModule usage across entire 2715-line tenant.php |                                                       
      103 +| SEC-PLATFORM-004 | CRITICAL | is_super_admin in $fillable on BOTH User models + writable from student login form |                                          
      104 +| SEC-PLATFORM-002 | CRITICAL | env('APP_DOMAIN') in routes/web.php — ALL central routes 404 after config:cache |                                             
      105  | SEC-004 | CRITICAL | Payment webhook behind auth middleware — ALL Razorpay payments fail |
      104 -| SEC-005 | CRITICAL | Gateway whitelist bypass — fake payment events possible |                                                                              
      105 -| SEC-008 | CRITICAL | Unauthenticated seeder/run route — data corruption risk |                                                                              
      106 -| SEC-011 | HIGH | env() in routes/web.php — breaks ALL central routes after config:cache |                                                                   
      107 -| SEC-009 | HIGH | SmartTimetableController has ZERO authorization checks |                                                                                   
      106 +| BUG-VND-001 | CRITICAL | 6 of 7 Vendor controllers NOT registered in routes — unreachable |                                                                 
      107 +| SEC-NTF-006 | CRITICAL | ALL Notification routes commented out in web.php — module inaccessible |                                                           
      108 +| BUG-CMP-001 | CRITICAL | dd($e) in Complaint store() catch block — exposes stack traces in production |                                                     
      109 +| SEC-009 | HIGH | 200+ issues found across ALL "100% complete" modules — see known-issues.md |                                                               
      110 +                                                                                                                                                              
      111 +> **Full details:** `AI_Brain/lessons/known-issues.md` — "Deep Audit" section (2026-03-15)                                                                    

⏺ Now add a reference entry to the "Critical Files to Check" table.

⏺ Update(~/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/AI_Brain/memory/MEMORY.md)
  ⎿  Added 8 lines, removed 3 lines
      35  
      36  | What You're Doing | Files to Read |
      37  |-------------------|--------------|
      38 +| **Starting any new feature** | `project_docs/10-new-feature-checklist.md` — Prime vs Tenant step-by-step |                                                   
      39 +| **Creating controllers** | `project_docs/06-controller-guide.md` — CRUD template with Gate + validation |                                                    
      40 +| **Creating views** | `project_docs/07-blade-views-guide.md` — Index + Create/Edit patterns |                                                                 
      41 +| **Creating migrations** | `project_docs/04-migration-guide.md` — Central vs Tenant paths |                                                                   
      42 +| **Routing** | `project_docs/08-routes-guide.md` — web.php vs tenant.php |                                                                                    
      43  | Any tenant-scoped work | `tenancy-map.md` + `AI_Brain/rules/tenancy-rules.md` |
      44  | Adding a new module | `modules-map.md` + `AI_Brain/rules/module-rules.md` |
      45  | DB schema / migrations | `db-schema.md` |
      41 -| Security-sensitive code | `known-bugs-and-roadmap.md` (SEC-* section) |                                                                                      
      42 -| Performance-critical code | `known-bugs-and-roadmap.md` (PERF-* section) |                                                                                   
      46 +| Security-sensitive code | `AI_Brain/lessons/known-issues.md` (Deep Audit 2026-03-15 section) |                                                               
      47  | Authorization / policies | `project-context.md` (Authorization Architecture) |
      48  | SmartTimetable work | `AI_Brain/lessons/known-issues.md` (FET solver sections) |
      45 -| Payment/webhook work | `known-bugs-and-roadmap.md` (SEC-004, SEC-005) |                                                                                      
      49 +| Payment/webhook work | `AI_Brain/lessons/known-issues.md` (SEC-PAY-* section) |                                                                              
      50 +| Module reference (all names) | `project_docs/11-all-modules-controllers-models.md` |                                                                         
      51  
      52  ---
      53  

⏺ Let me verify the final state of the updated AI Brain files.

⏺ Read 1 file (ctrl+o to expand)

⏺ AI Brain updated. Here's what changed:

  AI Brain Updates Summary

  memory/MEMORY.md (index) — 3 sections added

  1. Project Documentation — links to all 12 project_docs/ files with descriptions of what each answers
  2. Project Planning Documents — links to RBS, Gap Analysis, Work Status, Estimation
  3. Development Lifecycle Blueprint — link to the 9-phase process with 17 prompts
  4. Critical Files to Check table — expanded from 8 to 13 rows, now includes project_docs references for new features, controllers, views, migrations, routing
  5. Critical Bugs table — updated with deep audit findings (API keys, EnsureTenantHasModule, 200+ issues)

  memory/project-context.md — Key Statistics corrected

  - Modules: 29 → 27
  - Tenant Migrations: 216 → 278 files
  - Central Migrations: 6 → 5 + 37 (in Prime module)
  - Tenant Route Lines: 2,628 → 2,715 (1,328 Route:: calls)
  - Added overall completion: ~31% of RBS (1112 sub-tasks)
  - Added reference to project_docs/ location

  Files already updated earlier in this session

  - memory/modules-map.md — All 27 modules with corrected counts + deep audit completion %
  - state/progress.md — All "100% complete" modules revised down (none truly 100%)
  - lessons/known-issues.md — 200+ new issues from deep audit of 15 modules

✻ Cogitated for 2m 39s

❯ I see in Agent Folder in AI_Brain and feel 3 Agent are missing :                                                                                                              
    - Business Analyst                                                                                                                                                          
    - Frontend Developer                                                                                                                                                        
    - Backend Developer                                                                                                                                                         
If you feel it is good to have those, Specially Business Analysts then create those                                                                                             

⏺ Read 2 files (ctrl+o to expand)

⏺ You're right — the existing agents are all code-focused. The biggest gap is the Business Analyst — no agent currently handles the critical requirement-to-specification
  pipeline. Let me create all three.

⏺ Write(~/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/AI_Brain/agents/business-analyst.md)
  ⎿  Wrote 199 lines to ../../WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/AI_Brain/agents/business-analyst.md
       1 # Agent: Business Analyst
       2
       3 ## Role
       4 Requirements analyst for the Prime-AI Academic Intelligence Platform. Translates business needs into structured, developer-ready specifications. Bridges the gap
     between stakeholder ideas
          and executable development tasks.
       5
       6 ## When to Use This Agent
       7 - Starting a **new module** or **new feature** from scratch
       8 - Translating **wireframes/mockups** into detailed feature specifications
       9 - Creating or expanding **RBS entries** (Requirements Breakdown Structure)
      10 - Performing **gap analysis** between RBS requirements and existing code
     … +189 lines (ctrl+o to expand)

⏺ Write(~/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/AI_Brain/agents/frontend-developer.md)
  ⎿  Wrote 251 lines to ../../WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/AI_Brain/agents/frontend-developer.md
       1 # Agent: Frontend Developer
       2
       3 ## Role
       4 Blade view, component, and UI specialist for the Prime-AI platform. Creates pixel-consistent views following AdminLTE v4 + Bootstrap 5 patterns established in the
      codebase.
       5
       6 ## When to Use This Agent
       7 - Creating **index/list views** (tables with pagination, filters, actions)
       8 - Creating **create/edit forms** (single-column, two-column, tabbed)
       9 - Creating **show/detail views** (read-only display with related data tabs)
      10 - Creating **tab-based master views** (multiple entities on one page)
     … +241 lines (ctrl+o to expand)

⏺ Write(~/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/AI_Brain/agents/backend-developer.md)
  ⎿  Wrote 229 lines to ../../WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/AI_Brain/agents/backend-developer.md
       1 # Agent: Backend Developer
       2
       3 ## Role
       4 Laravel backend specialist for the Prime-AI platform. Handles controllers, models, services, FormRequests, routes, migrations, seeders, and policies following the
      project's exact pattern
         s and security requirements.
       5
       6 ## When to Use This Agent
       7 - Creating **controllers** with full CRUD + trash/restore/forceDelete/toggleStatus
       8 - Creating **models** with correct $table, $fillable, SoftDeletes, relationships
       9 - Creating **FormRequests** with proper validation rules and authorize()
      10 - Creating **services** for complex business logic
     … +219 lines (ctrl+o to expand)

⏺ Searched for 1 pattern (ctrl+o to expand)

⏺ All 11 agents now in place. Here's what each covers:

  AI Brain Agents (11 total)

  ┌─────────────────────────────┬────────────────────────────────────┬──────────────────────────────────────────────────────────────────────────┐
  │            Agent            │                Role                │                               When to Use                                │
  ├─────────────────────────────┼────────────────────────────────────┼──────────────────────────────────────────────────────────────────────────┤
  │ business-analyst.md (NEW)   │ Requirements → Specifications      │ Starting new module/feature, creating RBS, gap analysis, sprint planning │
  ├─────────────────────────────┼────────────────────────────────────┼──────────────────────────────────────────────────────────────────────────┤
  │ frontend-developer.md (NEW) │ Blade views + AdminLTE + Alpine.js │ Creating views, forms, tables, dashboards, PDF templates                 │
  ├─────────────────────────────┼────────────────────────────────────┼──────────────────────────────────────────────────────────────────────────┤
  │ backend-developer.md (NEW)  │ Controllers + Models + Security    │ CRUD controllers, FormRequests, routes, migrations, security hardening   │
  ├─────────────────────────────┼────────────────────────────────────┼──────────────────────────────────────────────────────────────────────────┤
  │ api-builder.md              │ REST API development               │ API endpoints, Sanctum auth                                              │
  ├─────────────────────────────┼────────────────────────────────────┼──────────────────────────────────────────────────────────────────────────┤
  │ db-architect.md             │ Database schema design             │ DDL, migrations, table design                                            │
  ├─────────────────────────────┼────────────────────────────────────┼──────────────────────────────────────────────────────────────────────────┤
  │ debugger.md                 │ Bug investigation + fixing         │ Runtime errors, debugging                                                │
  ├─────────────────────────────┼────────────────────────────────────┼──────────────────────────────────────────────────────────────────────────┤
  │ developer.md                │ General feature development        │ Broad tasks spanning multiple layers                                     │
  ├─────────────────────────────┼────────────────────────────────────┼──────────────────────────────────────────────────────────────────────────┤
  │ module-agent.md             │ nwidart/modules specialist         │ Creating/structuring new modules                                         │
  ├─────────────────────────────┼────────────────────────────────────┼──────────────────────────────────────────────────────────────────────────┤
  │ school-agent.md             │ School domain knowledge            │ Indian K-12 academic concepts                                            │
  ├─────────────────────────────┼────────────────────────────────────┼──────────────────────────────────────────────────────────────────────────┤
  │ tenancy-agent.md            │ stancl/tenancy specialist          │ Multi-tenancy isolation, DB switching                                    │
  ├─────────────────────────────┼────────────────────────────────────┼──────────────────────────────────────────────────────────────────────────┤
  │ test-agent.md               │ Pest 4.x testing                   │ Unit tests, feature tests                                                │
  └─────────────────────────────┴────────────────────────────────────┴──────────────────────────────────────────────────────────────────────────┘

  Business Analyst highlights:

  - Indian K-12 domain knowledge (CBSE/ICSE, fee structures, transport, HPC)
  - RBS entry format matching PrimeAI_RBS_Menu_Mapping_v2.0.md exactly
  - Screen-by-screen field specifications with validation rules + dropdown sources
  - Sprint task breakdown with effort estimates
  - Output locations for each deliverable type

  Frontend Developer highlights:

  - Complete index + create/edit Blade templates ready to copy
  - All AdminLTE v4 component references (<x-backend.layouts.app>, breadcrumbs, card headers)
  - DomPDF crash prevention rules (10 rules that cause hard crashes)
  - CSS class quick reference table

  Backend Developer highlights:

  - 5 non-negotiable security rules with code examples
  - 4 mandatory performance patterns
  - Standard 11-method controller structure
  - Complete migration/model/route templates
  - Tenancy isolation rules

✻ Cooked for 2m 59s

❯ 1 more Agent I feel is missing who can do work related to Deployment like helping me to create CICD Pipeline or deploy the project on cloude etc.                             

⏺ Write(~/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/AI_Brain/agents/devops-deployer.md)
  ⎿  Wrote 524 lines to ../../WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/AI_Brain/agents/devops-deployer.md
       1 # Agent: DevOps & Deployment Engineer
       2
       3 ## Role
       4 Infrastructure, CI/CD, and deployment specialist for the Prime-AI multi-tenant SaaS platform. Handles server provisioning, pipeline configuration,
     containerization, cloud deployment, SSL
         , domain management, and production operations for a stancl/tenancy Laravel application.
       5
       6 ## When to Use This Agent
       7 - Setting up **CI/CD pipelines** (GitHub Actions, GitLab CI, Bitbucket Pipelines)
       8 - **Deploying** to cloud providers (AWS, DigitalOcean, Hetzner, Railway, Forge)
       9 - Configuring **Docker/Docker Compose** for local dev and production
      10 - Setting up **production server** (Nginx, PHP-FPM, MySQL, Redis, Supervisor)
     … +514 lines (ctrl+o to expand)

⏺ Searched for 1 pattern (ctrl+o to expand)

⏺ Created devops-deployer.md (14.8KB — the most comprehensive agent). Here's what it covers:

  DevOps & Deployment Agent — Contents

  ┌────────────────────────────────┬─────────────────────────────────────────────────────────────────────────────────┐
  │            Section             │                                What It Provides                                 │
  ├────────────────────────────────┼─────────────────────────────────────────────────────────────────────────────────┤
  │ Wildcard DNS + SSL             │ Certbot commands for *.primeai.in, Cloudflare alternative                       │
  ├────────────────────────────────┼─────────────────────────────────────────────────────────────────────────────────┤
  │ Nginx Config                   │ Full multi-tenant config with wildcard server_name, PHP-FPM, file upload limits │
  ├────────────────────────────────┼─────────────────────────────────────────────────────────────────────────────────┤
  │ Environment Variables          │ Complete .env template for production (DB, Redis, Mail, Razorpay, S3)           │
  ├────────────────────────────────┼─────────────────────────────────────────────────────────────────────────────────┤
  │ GitHub Actions CI/CD           │ Full pipeline: test → deploy staging → deploy production with SSH               │
  ├────────────────────────────────┼─────────────────────────────────────────────────────────────────────────────────┤
  │ Zero-Downtime Deploy Script    │ Symlink-swap deployment with release directories                                │
  ├────────────────────────────────┼─────────────────────────────────────────────────────────────────────────────────┤
  │ Server Setup Checklist         │ Ubuntu 22.04 + PHP 8.2 + MySQL 8 + Nginx + Redis — every command                │
  ├────────────────────────────────┼─────────────────────────────────────────────────────────────────────────────────┤
  │ Supervisor Config              │ Queue worker process management                                                 │
  ├────────────────────────────────┼─────────────────────────────────────────────────────────────────────────────────┤
  │ Docker Compose                 │ Local dev environment (app + MySQL + Redis + Mailpit)                           │
  ├────────────────────────────────┼─────────────────────────────────────────────────────────────────────────────────┤
  │ Dockerfile                     │ PHP 8.2-FPM based image                                                         │
  ├────────────────────────────────┼─────────────────────────────────────────────────────────────────────────────────┤
  │ Backup Strategy                │ Spatie backup for central + tenant DBs, S3 storage                              │
  ├────────────────────────────────┼─────────────────────────────────────────────────────────────────────────────────┤
  │ Monitoring                     │ Health check endpoint, Telescope, Sentry, UptimeRobot                           │
  ├────────────────────────────────┼─────────────────────────────────────────────────────────────────────────────────┤
  │ Cloud Provider Quick Setup     │ AWS (scale), DigitalOcean (budget), Laravel Forge (easiest)                     │
  ├────────────────────────────────┼─────────────────────────────────────────────────────────────────────────────────┤
  │ Production Readiness Checklist │ 16-item checklist before going live                                             │
  └────────────────────────────────┴─────────────────────────────────────────────────────────────────────────────────┘

  All 12 Agents Now

  agents/
  ├── api-builder.md           (2.7KB)  — REST API development
  ├── backend-developer.md     (8.4KB)  — Controllers, models, security
  ├── business-analyst.md      (8.1KB)  — Requirements → specifications
  ├── db-architect.md          (3.9KB)  — Database schema design
  ├── debugger.md              (3.5KB)  — Bug investigation
  ├── developer.md             (3.1KB)  — General feature development
  ├── devops-deployer.md       (14.8KB) — CI/CD, Docker, cloud, production
  ├── frontend-developer.md    (13.2KB) — Blade views, AdminLTE, PDF
  ├── module-agent.md          (3.3KB)  — nwidart/modules specialist
  ├── school-agent.md          (3.8KB)  — Indian K-12 domain knowledge
  ├── tenancy-agent.md         (3.6KB)  — stancl/tenancy specialist
  └── test-agent.md            (4.5KB)  — Pest 4.x testing

✻ Churned for 1m 39s

❯ Can I create some other type of Agents also which are not directly to the software developmet but they will be capable to perform Business Related tasks like :               
 - Creating Business Strategy to sale my Application to the School                                                                                                              
 - Creating Sales Materials Like Presentation contents etc.                                                                                                                     
 - Market Assessment, what is in demand etc.                                                                                                                                    
 - Product Costing and Sales Price Calculation                                                                                                                                  
 - Application Running Cost                                                                                                                                                     
 - Cost Analysis                                                                                                                                                                
                                                                                                                                                                                
 Do not start creating the Agent, first just answer my question whether I can create such Agents or not. If yes then Provide me the list of Agent which can be created and what 
 wil be there. Do not created them just Answer the Question and provide the Detail.                                                                                             

⏺ Yes, absolutely. AI Brain agents are just instruction files — they can be for any role, not just software development. The agent system works the same way: define the role,
  context, deliverables, and templates. Claude reads the agent file and follows its instructions.

  The difference: business agents work with market data, financials, and strategy documents instead of code files. They'll reference your project_docs for product understanding
   but produce business deliverables (presentations, spreadsheets, proposals).

  ---
  Business Agents You Can Create

  ┌─────┬─────────────────┬─────────────────────────────────────────────────────────────────────────────────────────────┬───────────────────────────────────────────────────┐
  │  #  │   Agent Name    │                                        What It Does                                         │                 Key Deliverables                  │
  ├─────┼─────────────────┼─────────────────────────────────────────────────────────────────────────────────────────────┼───────────────────────────────────────────────────┤
  │ 1   │ Sales           │ Go-to-market strategy for Indian K-12 school ERP market. School segmentation, pricing       │ GTM plan, school targeting criteria, sales        │
  │     │ Strategist      │ tiers, sales funnel design, channel strategy (direct sales, partners, digital)              │ playbook, competitive positioning                 │
  ├─────┼─────────────────┼─────────────────────────────────────────────────────────────────────────────────────────────┼───────────────────────────────────────────────────┤
  │ 2   │ Sales Content   │ Creates all sales collateral — pitch decks, brochures, email sequences, demo scripts, case  │ PPT content (slide-by-slide), email templates,    │
  │     │ Creator         │ studies, feature comparison sheets                                                          │ one-pagers, WhatsApp pitch scripts                │
  ├─────┼─────────────────┼─────────────────────────────────────────────────────────────────────────────────────────────┼───────────────────────────────────────────────────┤
  │ 3   │ Market Analyst  │ Indian EdTech/School ERP market research — demand analysis, competitor mapping (Fedena,     │ Market report, competitor matrix, SWOT analysis,  │
  │     │                 │ Entab, MyClassboard, Teachmint), trend identification, TAM/SAM/SOM calculation              │ market size estimates                             │
  ├─────┼─────────────────┼─────────────────────────────────────────────────────────────────────────────────────────────┼───────────────────────────────────────────────────┤
  │ 4   │ Financial       │ Product costing (infra + dev + support), pricing model design (per-student, per-module,     │ Cost breakdown sheet, pricing calculator, P&L     │
  │     │ Analyst         │ flat), unit economics, break-even analysis, revenue projections                             │ projection, break-even model                      │
  ├─────┼─────────────────┼─────────────────────────────────────────────────────────────────────────────────────────────┼───────────────────────────────────────────────────┤
  │ 5   │ Cloud Cost      │ Specifically for AWS/DO/hosting cost estimation — server sizing per tenant count, storage   │ Monthly cost calculator by tenant count           │
  │     │ Optimizer       │ projections, bandwidth estimates, cost-per-school calculation                               │ (10/50/100/500 schools), scaling roadmap          │
  ├─────┼─────────────────┼─────────────────────────────────────────────────────────────────────────────────────────────┼───────────────────────────────────────────────────┤
  │ 6   │ Proposal Writer │ Creates school-specific proposals and RFP responses — takes school name + requirements and  │ School proposal document, implementation plan,    │
  │     │                 │ generates tailored proposal with pricing, implementation timeline, SLA                      │ SLA terms, contract template                      │
  └─────┴─────────────────┴─────────────────────────────────────────────────────────────────────────────────────────────┴───────────────────────────────────────────────────┘

  ---
  What Each Agent Would Contain

  1. Sales Strategist

  - Indian K-12 market context (1.5M+ schools, 80% still use paper/Excel)
  - School decision-maker profiles (Principal, Management Trustee, IT Head)
  - Sales cycle for schools (typically 3-6 months, budget approval in March-April)
  - Pricing psychology for Indian schools (annual subscription, per-student works best)
  - Channel strategy templates (direct, reseller, education conferences)
  - References to your RBS for feature-based selling

  2. Sales Content Creator

  - Slide-by-slide pitch deck structure (Problem → Solution → Demo → Pricing → CTA)
  - Module-wise feature highlights pulled from your 27 modules
  - Pain-point messaging for different school types (small private, CBSE chain, international)
  - Email cadence templates (cold outreach → follow-up → demo invite → proposal)
  - WhatsApp-friendly short pitches (Indian schools communicate via WhatsApp)
  - Competitor comparison talking points

  3. Market Analyst

  - Indian EdTech market data structure (DISE data, UDISE+, NEP 2020 mandates)
  - Competitor product feature matrices
  - School ERP pricing benchmarks (INR 30-200 per student/year range)
  - Government mandates driving ERP adoption (NEP 2020, HPC requirement, digital attendance)
  - TAM calculation framework based on school count + pricing

  4. Financial Analyst

  - Infrastructure cost model (servers, DB, storage, bandwidth per tenant)
  - Development cost tracking (team salary, Claude AI cost, tools)
  - Support cost estimation (per-school support hours)
  - Pricing model templates (tiered: Basic/Pro/Enterprise)
  - Unit economics (CAC, LTV, churn, MRR/ARR projections)
  - Break-even calculator (fixed costs vs per-school revenue)

  5. Cloud Cost Optimizer

  - AWS/DO cost tables for typical school ERP load
  - Per-tenant resource consumption estimates (DB size, storage, API calls)
  - Scaling tiers (10 schools on $50/mo → 500 schools on $800/mo)
  - Cost optimization strategies (reserved instances, spot, right-sizing)
  - Your specific stack requirements (MySQL per-tenant DB, Redis, queue workers)

  6. Proposal Writer

  - Standard proposal template for Indian schools
  - Implementation timeline (onboarding → data migration → training → go-live)
  - SLA templates (uptime, support hours, data backup guarantees)
  - Pricing presentation format that works for Indian school management committees
  - References to specific modules from your RBS that match school pain points

  ---
  My Recommendation

  Create these 3 first (highest immediate value):

  1. Financial Analyst — You need to know your costs before setting prices. This agent can calculate your exact per-school cost (hosting + support + development amortization)
  so you price profitably.
  2. Sales Content Creator — You need a pitch deck and demo script before approaching any school. This agent uses your 27-module RBS to generate feature-rich sales materials.
  3. Market Analyst — Understanding competitors and market pricing prevents you from pricing too high or too low.

  The other 3 (Sales Strategist, Cloud Cost Optimizer, Proposal Writer) are valuable but depend on outputs from the first 3.

  Want me to create any or all of them?

✻ Sautéed for 38s

❯ Write Now I dont want you to create those Agents but let me know what will be data I should provide you to build the best Agent for those skills?                             

⏺ Here's exactly what data you need to prepare for each agent:

  ---
  1. Financial Analyst Agent — Data Needed

  Infrastructure Costs (Monthly)

  ┌──────────────────┬───────────────────────────────────────────────────────────────┐
  │       Item       │                        What to Provide                        │
  ├──────────────────┼───────────────────────────────────────────────────────────────┤
  │ Server hosting   │ Provider name, plan, monthly cost (e.g., DigitalOcean $48/mo) │
  ├──────────────────┼───────────────────────────────────────────────────────────────┤
  │ Database hosting │ Managed MySQL or self-hosted? Monthly cost                    │
  ├──────────────────┼───────────────────────────────────────────────────────────────┤
  │ Redis/Cache      │ Managed or on same server? Cost                               │
  ├──────────────────┼───────────────────────────────────────────────────────────────┤
  │ Domain + DNS     │ Annual cost for primeai.in + Cloudflare plan                  │
  ├──────────────────┼───────────────────────────────────────────────────────────────┤
  │ SSL certificate  │ Free (Let's Encrypt) or purchased?                            │
  ├──────────────────┼───────────────────────────────────────────────────────────────┤
  │ Email service    │ SMTP provider + monthly cost (e.g., Gmail Workspace, AWS SES) │
  ├──────────────────┼───────────────────────────────────────────────────────────────┤
  │ SMS gateway      │ Provider name + per-SMS cost (e.g., MSG91 at ₹0.15/SMS)       │
  ├──────────────────┼───────────────────────────────────────────────────────────────┤
  │ Backup storage   │ S3/Spaces — estimated monthly cost                            │
  ├──────────────────┼───────────────────────────────────────────────────────────────┤
  │ CDN (if any)     │ Cloudflare free or paid plan?                                 │
  ├──────────────────┼───────────────────────────────────────────────────────────────┤
  │ Monitoring tools │ Sentry, UptimeRobot — free or paid?                           │
  └──────────────────┴───────────────────────────────────────────────────────────────┘

  Development Costs

  ┌──────────────────────────────────┬─────────────────────────────────────────────────────────────────────┐
  │               Item               │                           What to Provide                           │
  ├──────────────────────────────────┼─────────────────────────────────────────────────────────────────────┤
  │ Developer salaries               │ Monthly CTC per developer (3 developers — Tarun, Shailesh, Gaurav?) │
  ├──────────────────────────────────┼─────────────────────────────────────────────────────────────────────┤
  │ Your own time cost               │ Hours/month you spend + your opportunity cost                       │
  ├──────────────────────────────────┼─────────────────────────────────────────────────────────────────────┤
  │ Claude AI cost                   │ Monthly spend on Claude API/subscription                            │
  ├──────────────────────────────────┼─────────────────────────────────────────────────────────────────────┤
  │ Tools & licenses                 │ GitHub, Figma, any paid tools — monthly cost                        │
  ├──────────────────────────────────┼─────────────────────────────────────────────────────────────────────┤
  │ How many months spent so far     │ Total development time invested                                     │
  ├──────────────────────────────────┼─────────────────────────────────────────────────────────────────────┤
  │ How many more months to complete │ Your estimate (we calculated ~13 months)                            │
  └──────────────────────────────────┴─────────────────────────────────────────────────────────────────────┘

  Support & Operations Costs (Projected)

  ┌──────────────────────────┬─────────────────────────────────────────────────────┐
  │           Item           │                   What to Provide                   │
  ├──────────────────────────┼─────────────────────────────────────────────────────┤
  │ Support staff planned    │ How many support people? Salary range?              │
  ├──────────────────────────┼─────────────────────────────────────────────────────┤
  │ Training time per school │ How many days to onboard a school?                  │
  ├──────────────────────────┼─────────────────────────────────────────────────────┤
  │ Who does onboarding?     │ Developer? Dedicated person? Your cost per day?     │
  ├──────────────────────────┼─────────────────────────────────────────────────────┤
  │ Data migration effort    │ How many hours to migrate a school's existing data? │
  └──────────────────────────┴─────────────────────────────────────────────────────┘

  Revenue Goals

  ┌─────────────────────────────────────────────────────────────────┬─────────────────────────────┐
  │                              Item                               │       What to Provide       │
  ├─────────────────────────────────────────────────────────────────┼─────────────────────────────┤
  │ Target number of schools — Year 1                               │ e.g., 10 schools            │
  ├─────────────────────────────────────────────────────────────────┼─────────────────────────────┤
  │ Target number of schools — Year 2                               │ e.g., 50 schools            │
  ├─────────────────────────────────────────────────────────────────┼─────────────────────────────┤
  │ Target number of schools — Year 3                               │ e.g., 200 schools           │
  ├─────────────────────────────────────────────────────────────────┼─────────────────────────────┤
  │ Average students per school                                     │ Range (e.g., 500–2000)      │
  ├─────────────────────────────────────────────────────────────────┼─────────────────────────────┤
  │ Are you targeting small private, CBSE chains, or international? │ School type affects pricing │
  └─────────────────────────────────────────────────────────────────┴─────────────────────────────┘

  ---
  2. Sales Content Creator Agent — Data Needed

  Company Information

  ┌──────────────────────────────┬─────────────────────────────────────────────────────────────┐
  │             Item             │                       What to Provide                       │
  ├──────────────────────────────┼─────────────────────────────────────────────────────────────┤
  │ Company name                 │ Legal entity name                                           │
  ├──────────────────────────────┼─────────────────────────────────────────────────────────────┤
  │ Company tagline              │ One-liner (e.g., "AI-Powered School Intelligence Platform") │
  ├──────────────────────────────┼─────────────────────────────────────────────────────────────┤
  │ Logo file                    │ Path or description                                         │
  ├──────────────────────────────┼─────────────────────────────────────────────────────────────┤
  │ Founder names + backgrounds  │ Your team's credentials (education, experience)             │
  ├──────────────────────────────┼─────────────────────────────────────────────────────────────┤
  │ Company registration details │ For proposal credibility (Pvt Ltd, LLP, etc.)               │
  ├──────────────────────────────┼─────────────────────────────────────────────────────────────┤
  │ Office location              │ City, state                                                 │
  ├──────────────────────────────┼─────────────────────────────────────────────────────────────┤
  │ Website URL                  │ If exists                                                   │
  ├──────────────────────────────┼─────────────────────────────────────────────────────────────┤
  │ Contact details              │ Phone, email for sales                                      │
  └──────────────────────────────┴─────────────────────────────────────────────────────────────┘

  Product Positioning

  ┌──────────────────────────────────────┬──────────────────────────────────────────────────────────────────┐
  │                 Item                 │                         What to Provide                          │
  ├──────────────────────────────────────┼──────────────────────────────────────────────────────────────────┤
  │ Top 5 features you want to highlight │ What makes you different from competitors?                       │
  ├──────────────────────────────────────┼──────────────────────────────────────────────────────────────────┤
  │ What problem are you solving?        │ In school's language, not tech language                          │
  ├──────────────────────────────────────┼──────────────────────────────────────────────────────────────────┤
  │ Any pilot schools?                   │ If you've deployed to even 1 school — name, results, testimonial │
  ├──────────────────────────────────────┼──────────────────────────────────────────────────────────────────┤
  │ Demo video/screenshots               │ Any existing demo material?                                      │
  ├──────────────────────────────────────┼──────────────────────────────────────────────────────────────────┤
  │ Which modules are your strongest?    │ What would you show first in a demo?                             │
  └──────────────────────────────────────┴──────────────────────────────────────────────────────────────────┘

  Target Audience

  ┌───────────────────────────────────┬──────────────────────────────────────────────────────────┐
  │               Item                │                     What to Provide                      │
  ├───────────────────────────────────┼──────────────────────────────────────────────────────────┤
  │ Who makes the buying decision?    │ Principal? Trustee? IT head? Management committee?       │
  ├───────────────────────────────────┼──────────────────────────────────────────────────────────┤
  │ What is their biggest pain point? │ Manual work? Parent complaints? Fee collection? Reports? │
  ├───────────────────────────────────┼──────────────────────────────────────────────────────────┤
  │ What do they currently use?       │ Paper registers? Excel? Another ERP?                     │
  ├───────────────────────────────────┼──────────────────────────────────────────────────────────┤
  │ What's their budget range?        │ What can a school afford annually?                       │
  ├───────────────────────────────────┼──────────────────────────────────────────────────────────┤
  │ Preferred communication channel   │ Email? WhatsApp? In-person meeting?                      │
  └───────────────────────────────────┴──────────────────────────────────────────────────────────┘

  Competitor Knowledge

  ┌──────────────────────────────┬────────────────────────────────────────────────────┐
  │             Item             │                  What to Provide                   │
  ├──────────────────────────────┼────────────────────────────────────────────────────┤
  │ Competitors you know of      │ Names + what you know about their pricing          │
  ├──────────────────────────────┼────────────────────────────────────────────────────┤
  │ What they do better than you │ Be honest — helps position around gaps             │
  ├──────────────────────────────┼────────────────────────────────────────────────────┤
  │ What you do better than them │ Your unique advantages (AI, HPC, timetable solver) │
  └──────────────────────────────┴────────────────────────────────────────────────────┘

  ---
  3. Market Analyst Agent — Data Needed

  Your Market Definition

  ┌─────────────────────┬──────────────────────────────────────────────────────────┐
  │        Item         │                     What to Provide                      │
  ├─────────────────────┼──────────────────────────────────────────────────────────┤
  │ Geographic focus    │ Which states/cities first? All India or specific region? │
  ├─────────────────────┼──────────────────────────────────────────────────────────┤
  │ School type focus   │ Private only? Government too? CBSE/ICSE/State board?     │
  ├─────────────────────┼──────────────────────────────────────────────────────────┤
  │ School size range   │ Minimum students? Maximum? (e.g., 300–5000)              │
  ├─────────────────────┼──────────────────────────────────────────────────────────┤
  │ Fee-paying capacity │ Schools charging ₹X+ annual fees (indicates tech budget) │
  └─────────────────────┴──────────────────────────────────────────────────────────┘

  Existing Market Knowledge

  ┌─────────────────────────────────────┬───────────────────────────────────────────────────┐
  │                Item                 │                  What to Provide                  │
  ├─────────────────────────────────────┼───────────────────────────────────────────────────┤
  │ Schools you've spoken to            │ How many? What was their reaction?                │
  ├─────────────────────────────────────┼───────────────────────────────────────────────────┤
  │ Competitors you've evaluated        │ Any demos you've seen? Pricing you've found?      │
  ├─────────────────────────────────────┼───────────────────────────────────────────────────┤
  │ Industry events you know of         │ EdTech conferences, school principal associations │
  ├─────────────────────────────────────┼───────────────────────────────────────────────────┤
  │ Government mandates you're aware of │ NEP 2020, UDISE+, HPC requirements?               │
  ├─────────────────────────────────────┼───────────────────────────────────────────────────┤
  │ Any market reports you've read      │ Share links or key numbers you remember           │
  └─────────────────────────────────────┴───────────────────────────────────────────────────┘

  Your Pricing Hypothesis

  ┌──────────────────────────────────┬───────────────────────────────────────────────────────────┐
  │               Item               │                      What to Provide                      │
  ├──────────────────────────────────┼───────────────────────────────────────────────────────────┤
  │ What you think schools would pay │ Per student/year or flat annual fee?                      │
  ├──────────────────────────────────┼───────────────────────────────────────────────────────────┤
  │ How did you arrive at this?      │ Gut feel? Competitor pricing? School feedback?            │
  ├──────────────────────────────────┼───────────────────────────────────────────────────────────┤
  │ Module-wise pricing or bundled?  │ Do you want to sell all modules together or individually? │
  └──────────────────────────────────┴───────────────────────────────────────────────────────────┘

  ---
  4. Sales Strategist Agent — Data Needed

  ┌───────────────────────────┬──────────────────────────────────────────────────────────────────┐
  │           Item            │                         What to Provide                          │
  ├───────────────────────────┼──────────────────────────────────────────────────────────────────┤
  │ Sales team size           │ Just you? Dedicated sales person?                                │
  ├───────────────────────────┼──────────────────────────────────────────────────────────────────┤
  │ Sales budget (monthly)    │ Travel, marketing, ads — what can you spend?                     │
  ├───────────────────────────┼──────────────────────────────────────────────────────────────────┤
  │ Existing school network   │ Any contacts in schools? Education associations?                 │
  ├───────────────────────────┼──────────────────────────────────────────────────────────────────┤
  │ Partnership possibilities │ Any resellers, education consultants, or school chains you know? │
  ├───────────────────────────┼──────────────────────────────────────────────────────────────────┤
  │ Timeline pressure         │ When do you need first paying customer?                          │
  ├───────────────────────────┼──────────────────────────────────────────────────────────────────┤
  │ Preferred sales model     │ Direct sales? Channel partners? Online self-signup?              │
  └───────────────────────────┴──────────────────────────────────────────────────────────────────┘

  ---
  5. Cloud Cost Optimizer Agent — Data Needed

  ┌────────────────────────────────┬─────────────────────────────────────────────────────────────┐
  │              Item              │                       What to Provide                       │
  ├────────────────────────────────┼─────────────────────────────────────────────────────────────┤
  │ Current hosting setup          │ Provider, plan, specs (CPU/RAM/Disk)                        │
  ├────────────────────────────────┼─────────────────────────────────────────────────────────────┤
  │ Current monthly hosting bill   │ Exact amount                                                │
  ├────────────────────────────────┼─────────────────────────────────────────────────────────────┤
  │ Number of test tenants running │ How many school DBs exist today?                            │
  ├────────────────────────────────┼─────────────────────────────────────────────────────────────┤
  │ Average DB size per tenant     │ If you know (even rough — 50MB? 500MB?)                     │
  ├────────────────────────────────┼─────────────────────────────────────────────────────────────┤
  │ Average monthly storage growth │ Per tenant                                                  │
  ├────────────────────────────────┼─────────────────────────────────────────────────────────────┤
  │ Peak concurrent users expected │ Per school (e.g., 50 teachers + 500 students + 200 parents) │
  ├────────────────────────────────┼─────────────────────────────────────────────────────────────┤
  │ Cloud provider preference      │ AWS? DigitalOcean? No preference?                           │
  ├────────────────────────────────┼─────────────────────────────────────────────────────────────┤
  │ Budget ceiling for infra       │ Max you'd spend monthly                                     │
  └────────────────────────────────┴─────────────────────────────────────────────────────────────┘

  ---
  6. Proposal Writer Agent — Data Needed

  ┌──────────────────────────┬─────────────────────────────────────────────────┐
  │           Item           │                 What to Provide                 │
  ├──────────────────────────┼─────────────────────────────────────────────────┤
  │ Standard pricing tiers   │ Basic/Pro/Enterprise — what's included in each? │
  ├──────────────────────────┼─────────────────────────────────────────────────┤
  │ Implementation timeline  │ How many weeks from signing to go-live?         │
  ├──────────────────────────┼─────────────────────────────────────────────────┤
  │ Training approach        │ On-site? Remote? How many sessions?             │
  ├──────────────────────────┼─────────────────────────────────────────────────┤
  │ SLA commitments          │ Uptime guarantee? Support hours? Response time? │
  ├──────────────────────────┼─────────────────────────────────────────────────┤
  │ Payment terms            │ Annual upfront? Monthly? EMI option?            │
  ├──────────────────────────┼─────────────────────────────────────────────────┤
  │ Contract duration        │ 1 year? 3 years?                                │
  ├──────────────────────────┼─────────────────────────────────────────────────┤
  │ Data migration included? │ Free or extra charge?                           │
  ├──────────────────────────┼─────────────────────────────────────────────────┤
  │ Customization policy     │ Do you customize per school? Extra charge?      │
  └──────────────────────────┴─────────────────────────────────────────────────┘

  ---
  How to Provide This Data

  Create a single file:

  databases/4-Business_Planning/Business_Input_Data.md

  Fill in whatever you know — even partial data is useful. For items you don't know yet, write TBD or Need to research. The agents can work with partial data and flag what's
  missing.

  Start with Financial Analyst data — that's the foundation everything else depends on. You can't set pricing without knowing your costs.

✻ Sautéed for 55s

────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
❯  
────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
  ⏵⏵ accept edits on (shift+tab to cycle)


