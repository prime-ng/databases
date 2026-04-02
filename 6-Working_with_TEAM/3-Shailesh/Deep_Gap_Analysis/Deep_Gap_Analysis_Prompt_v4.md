# ╔════════════════════════════════════════════════════════════════════════╗
# ║      MODULE DEEP GAP ANALYSIS — BATCH EXECUTION PROMPT                 ║
# ║      Prime-AI Academic Intelligence Platform                           ║
# ╚════════════════════════════════════════════════════════════════════════╝
#
# HOW TO USE:
#   1. Change only below 2 lines : APP_BRANCH, DATE
#   2. No need to change any Path — Everything will derive automatically
#   3. Copy entire file → Paste it into Claude Code
#   4. Claude will iterate through ALL modules in the list below,
#      run the full Deep Gap Analysis for each, and write a separate
#      output file per module into {OUTPUT_DIR_A}.
# ═════════════════════════════════════════════════════════════════════════

---
## List of Modules

Below is the complete module inventory with their MODULE_TYPE.
Claude will process **every module** in this list, one by one, top to bottom.

| # | MODULE_NAME | MODULE_TYPE | DATABASE_FILE (auto-resolved) |
|---|-------------|-------------|-------------------------------|
| 1 | Billing | Prime | {PRIME_DDL} |
| 2 | Complaint | Tenant | {TENANT_DDL} |
| 3 | Dashboard | Other | — (No DDL) |
| 4 | Documentation | Other | — (No DDL) |
| 5 | GlobalMaster | Global | {GLOBAL_DDL} |
| 6 | Hpc | Tenant | {TENANT_DDL} |
| 7 | Library | Tenant | {TENANT_DDL} |
| 8 | LmsExam | Tenant | {TENANT_DDL} |
| 9 | LmsHomework | Tenant | {TENANT_DDL} |
| 10 | LmsQuests | Tenant | {TENANT_DDL} |
| 11 | LmsQuiz | Tenant | {TENANT_DDL} |
| 12 | Notification | Tenant | {TENANT_DDL} |
| 13 | Payment | Tenant | {TENANT_DDL} |
| 14 | Prime | Prime | {PRIME_DDL} |
| 15 | QuestionBank | Tenant | {TENANT_DDL} |
| 16 | Recommendation | Tenant | {TENANT_DDL} |
| 17 | Scheduler | Other | — (No DDL) |
| 18 | SchoolSetup | Tenant | {TENANT_DDL} |
| 19 | SmartTimetable | Tenant | {TENANT_DDL} |
| 20 | StandardTimetable | Tenant | {TENANT_DDL} |
| 21 | StudentFee | Tenant | {TENANT_DDL} |
| 22 | StudentPortal | Tenant | {TENANT_DDL} |
| 23 | StudentProfile | Tenant | {TENANT_DDL} |
| 24 | Syllabus | Tenant | {TENANT_DDL} |
| 25 | SyllabusBooks | Prime | {PRIME_DDL} |
| 26 | SystemConfig | Prime | {PRIME_DDL} |
| 27 | TimetableFoundation | Prime | {PRIME_DDL} |
| 28 | Transport | Tenant | {TENANT_DDL} |
| 29 | Vendor | Tenant | {TENANT_DDL} |

---

## ▶ GLOBAL VARIABLES (set once, apply to all modules):

```
APP_REPO       = prime_ai_tarun
APP_BRANCH     = Brijesh_SmartTimetable
DATE           = 2026-03-22
```

---

## ▶ BATCH EXECUTION INSTRUCTIONS

For **each module** in the "List of Modules" table above, do the following:

1. Set the current module's variables:
   ```
   MODULE_NAME   = {current module from the list}
   MODULE_TYPE   = {corresponding MODULE_TYPE from the list}
   DATABASE_FILE = {resolved based on MODULE_TYPE — see CONFIGURATION section}
   ```

2. Execute the **FULL analysis** (Steps 0 through 9 + OUTPUT) described below for this module.

3. Write the output report to a **separate file**:
   ```
   {OUTPUT_DIR_A}/{MODULE_NAME}_Deep_Gap_Analysis.md
   ```
   For example: `{OUTPUT_DIR_A}/Billing_Deep_Gap_Analysis.md`

4. After writing the file, print a one-line status:
   ```
   ✅ [{current #}/{total}] {MODULE_NAME} — Analysis complete → {output file path}
   ```

5. Move to the **next module** in the list and repeat from step 1.

6. After ALL modules are done, write a **Summary Index** file:
   ```
   {OUTPUT_DIR_A}/_Module_Analysis_Summary_{DATE}.md
   ```
   This summary file should contain:
   - A table listing every module with: Overall Score, Production Ready status, Total Issues count, and link to the detailed report file.
   - Aggregate counts across all modules.

---

## ▶ ROLE & OBJECTIVE

You are a **Senior Laravel Architect** performing a production-readiness audit of
the **`{MODULE_NAME}`** module in the Prime-AI platform.

**Your job:** Read every line of code, every DB table, every route, every test & every task from RBS —
then produce an **exhaustive gap analysis** that tells the development team:
- What is MISSING (features not built)
- What is BROKEN (bugs, crashes, wrong logic)
- What is DANGEROUS (security holes)
- What is SLOW (performance bottlenecks)
- What is UNTESTED (no test coverage)
- What violates project STANDARDS (conventions, tenancy rules, architecture)

**Do NOT modify any code. This is a read-only deep audit.**

---

## ═══ STEP 0 — LOAD DEFAULT PATHS & CONFIGURATION ═══

### DEFAULT PATHS
Read "/Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/AI_Brain/config/paths.md"

### Rules
- If any Path is missing in `paths.md` then find that in `CONFIGURATION` section below.
- If any variable exists at both place, in `paths.md` & in `CONFIGURATION` section also, then consider `CONFIGURATION` section Variable.

---

### CONFIGURATION
```
DB_REPO         = /Users/bkwork/WorkFolder/2-New_Primedb/pgdatabase
OLD_REPO        = /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases
AI_BRAIN        = {OLD_REPO}/AI_Brain
RBS_FILE        = {OLD_REPO}/3-Project_Planning/1-RBS/PrimeAI_RBS_Menu_Mapping_v2.0.md
MODULE_PATH     = {LARAVEL_REPO}/Modules/{MODULE_NAME}
BROWSER_TESTS   = {LARAVEL_REPO}/tests/Browser/Modules/{MODULE_NAME}
FEATURE_TESTS   = {LARAVEL_REPO}/tests/Feature/{MODULE_NAME}
UNIT_TESTS      = {LARAVEL_REPO}/tests/Unit/{MODULE_NAME}
MODULE_TESTS    = {LARAVEL_REPO}/Modules/{MODULE_NAME}/tests
ROUTES_FILE     = {LARAVEL_REPO}/routes/tenant.php
POLICIES_DIR    = {LARAVEL_REPO}/app/Policies
APP_PROVIDERS   = {LARAVEL_REPO}/app/Providers/AppServiceProvider.php
TENANT_MIGS     = {LARAVEL_REPO}/database/migrations/tenant
ACTIVITY_LOG    = {LARAVEL_REPO}/app/Helpers/activityLog.php

OUTPUT_REPO     = {OLD_REPO}
OUTPUT_DIR      = {OUTPUT_REPO}/3-Project_Planning/2-Gap_Analysis/2-Modules_Wise/2026Mar22
OUTPUT_DIR_A    = {OUTPUT_REPO}/3-Project_Planning/2-Gap_Analysis/2-Modules_Wise/2026Mar22
```

### DATABASE_FILE Resolution (based on MODULE_TYPE)
```
If MODULE_TYPE = "Tenant"  → DATABASE_FILE = {TENANT_DDL}
If MODULE_TYPE = "Prime"   → DATABASE_FILE = {PRIME_DDL}
If MODULE_TYPE = "Global"  → DATABASE_FILE = {GLOBAL_DDL}
If MODULE_TYPE = "Other"   → DATABASE_FILE = NONE (skip DDL-related checks)
```

---

## ═══ STEP 1 — LOAD AI BRAIN CONTEXT ═══

> `config/paths.md` already read in Step 0.
> Now read below files. These files define rules.
> **Note:** You only need to read the AI Brain files ONCE for the first module. Retain this context for all subsequent modules.

### 1A — Core Memory Files
| # | File | Why Read |
|---|------|---------|
| 1 | `{AI_BRAIN}/memory/project-context.md` | Tech stack, external services, key workflows |
| 2 | `{AI_BRAIN}/memory/tenancy-map.md` | **CRITICAL** — multi-tenancy isolation rules |
| 3 | `{AI_BRAIN}/memory/modules-map.md` | Module inventory, current status, known issues |
| 4 | `{AI_BRAIN}/memory/conventions.md` | Naming conventions, code patterns |
| 5 | `{AI_BRAIN}/memory/architecture.md` | System architecture, request flow, patterns |
| 6 | `{AI_BRAIN}/memory/school-domain.md` | School business domain rules |
| 7 | `{AI_BRAIN}/memory/decisions.md` | All architectural decisions (D1–D20+) |
| 8 | `{AI_BRAIN}/state/progress.md` | What is done / in-progress for this module |
| 9 | `{AI_BRAIN}/state/decisions.md` | Latest architectural decisions |

### 1B — Rules Files (MANDATORY — follow without exception)
| # | File | Why Read |
|---|------|---------|
| 10 | `{AI_BRAIN}/rules/tenancy-rules.md` | Tenancy isolation — most critical |
| 11 | `{AI_BRAIN}/rules/module-rules.md` | Module development standards |
| 12 | `{AI_BRAIN}/rules/security-rules.md` | Security requirements |
| 13 | `{AI_BRAIN}/rules/laravel-rules.md` | Laravel conventions |
| 14 | `{AI_BRAIN}/rules/code-style.md` | PSR-12 and project style |

### 1C — Lessons & Known Issues
| # | File | Why Read |
|---|------|---------|
| 15 | `{AI_BRAIN}/lessons/known-issues.md` | Known bugs, gotchas, hard-won fixes |

**After reading all 15 files, summarize:**
- What is this module supposed to do? (business purpose)
- What is its current known completion % from progress.md?
- What known bugs / issues are already logged for it?

---

## ═══ STEP 2 — DATABASE SCHEMA DEEP ANALYSIS ═══

### 2A — Extract Tenant Module Tables from {TENANT_DDL}

Read {TENANT_DDL} if {MODULE_TYPE} = `Tenant` and find ALL tables prefixed with the `Table Prefix` from below list where `Module` = {MODULE_NAME} in below list:

| Module | Table Prefix |
|--------|-------------|
| Hpc | `hpc_*` |
| SmartTimetable | `tt_*` |
| SchoolSetup | `sch_*` |
| StudentProfile | `std_*` |
| StudentFee | `fin_*` |
| Transport | `tpt_*` |
| Syllabus | `slb_*` |
| QuestionBank | `qns_*` |
| Complaint | `cmp_*` |
| Notification | `ntf_*` |
| Vendor | `vnd_*` |
| Recommendation | `rec_*` |
| LmsExam | `exm_*` |
| LmsQuiz | `quz_*` |
| LmsHomework | `hmw_*` |
| LmsQuests | `qst_*` |
| Library | `bok_*` |
| Payment | `pay_*` |
| StandardTimetable | `tt_*` |
| StudentPortal | `std_*` |

### 2B — Extract Prime Module Tables from {PRIME_DDL}

Read {PRIME_DDL} if {MODULE_TYPE} = `Prime` and find ALL tables prefixed with the `Table Prefix` from below list where `Module` = {MODULE_NAME} in below list:

| Module | Table Prefix |
|--------|-------------|
| Billing | `bil_*` |
| Prime | `prm_*` |
| SystemConfig | `sys_*` |
| TimetableFoundation | `tt_*` |
| SyllabusBooks | `slb_*` |

### 2C — Extract Global Module Tables from {GLOBAL_DDL}

Read all the tables from {GLOBAL_DDL} if {MODULE_TYPE} is `Global`.

| Module | Table Prefix |
|--------|-------------|
| GlobalMaster | `glb_*` |


### 2D — NO DDL Modules

If {MODULE_TYPE} = `Other` and {MODULE_NAME} is any of the modules listed below, then NO tables belong to the Module and you should skip all DDL Schema-related checks for these Modules:

| Module |
|--------|
| Dashboard |
| Documentation |
| Scheduler |

### 2E — For Each Table (excluding Modules belonging to `2D - NO DDL Modules` section), Record:
- Complete column list with data types, NULL/NOT NULL, DEFAULT values
- All PRIMARY KEY, UNIQUE KEY, INDEX, FOREIGN KEY definitions
- ENUM columns and their allowed values
- JSON columns (suffix `_json`)
- Boolean columns (prefix `is_` / `has_`)
- Soft-delete column (`deleted_at`)
- Audit columns (`created_by`, `created_at`, `updated_at`)

### 2F — DB Integrity Checks
- [ ] Every table has: `id`, `is_active`, `created_by`, `created_at`, `updated_at`, `deleted_at`
- [ ] Every FK column has a corresponding INDEX
- [ ] Junction tables end with `_jnt`
- [ ] JSON columns end with `_json`
- [ ] Boolean columns start with `is_` or `has_`
- [ ] No duplicate column definitions
- [ ] No orphaned FK references (pointing to non-existent tables)
- [ ] ENUM values are consistent across related tables

### 2G — Cross-Reference with Tenant Migrations
Check `{TENANT_MIGS}/` for migrations belonging to this module:
- [ ] Does a migration exist for every table in the DDL?
- [ ] Do migrations have `down()` methods that properly reverse `up()`?
- [ ] Are there additive-only migrations (no drops/renames) for existing tables?
- [ ] Are there columns in migrations that DON'T exist in the DDL (migration ahead of DDL)?
- [ ] Are there columns in DDL that have NO migration (DDL ahead of migrations)?

---

## ═══ STEP 3 — ROUTES DEEP ANALYSIS ═══

Open `{ROUTES_FILE}` and find ALL routes for `{MODULE_NAME}`.

### 3A — Build Complete Route Inventory
For EVERY route found, record:
```
Method | URI | Controller@Method | Route Name | Middleware Stack
```

### 3B — Route Integrity Checks
- [ ] Does every referenced Controller FILE exist at `{MODULE_PATH}/app/Http/Controllers/`?
- [ ] Does every referenced Controller METHOD exist and is it non-empty?
- [ ] Are route names following convention: `{module-slug}.{resource}.{action}`?
- [ ] Is `EnsureTenantHasModule` applied to the module's route group?
- [ ] Is `auth` middleware applied to ALL non-public routes?
- [ ] Are resource routes using `Route::resource()` or manually defined? (resource preferred)
- [ ] Are `createByCategory` / `editByCategory` style routes placed BEFORE `Route::resource()`?
- [ ] Are there routes that exist in file but are COMMENTED OUT (module inaccessible)?
- [ ] Are DELETE routes using proper HTTP DELETE method (not GET)?
- [ ] Are any route closures used instead of controller methods? (should not be)

### 3C — Missing Routes Check
Based on models found in Step 4B, check if these standard routes exist for each main entity:
```
GET    /{resource}           → index()
GET    /{resource}/create    → create()
POST   /{resource}           → store()
GET    /{resource}/{id}      → show()
GET    /{resource}/{id}/edit → edit()
PUT    /{resource}/{id}      → update()
DELETE /{resource}/{id}      → destroy()
PATCH  /{resource}/{id}/restore    → restore()   (soft-delete)
DELETE /{resource}/{id}/force      → forceDelete() (hard delete)
```

---

## ═══ STEP 4 — MODULE CODE DEEP AUDIT ═══

> Read EVERY .php file inside `{MODULE_PATH}/`. Do not skip any file.

---

### 4A — Controllers (`{MODULE_PATH}/app/Http/Controllers/`)

For EACH controller, perform ALL these checks:

#### Authorization Checks
- [ ] Does EVERY public method call `Gate::authorize()` or `$this->authorize()` before any logic?
- [ ] Does `index()` have Gate check? (commonly skipped)
- [ ] Does `show()` have Gate check?
- [ ] Does `create()` / `store()` have Gate check?
- [ ] Does `edit()` / `update()` have Gate check?
- [ ] Does `destroy()` / `restore()` / `forceDelete()` have Gate check?
- [ ] Are non-standard actions (generate, approve, publish, send, toggle, export) gated?
- [ ] Are the Gate permission strings following format: `tenant.{module-slug}.{action}`?
- [ ] Is `EnsureTenantHasModule` applied (via middleware in constructor or route)?

#### Input Handling Checks
- [ ] Does `store()` use a FormRequest class (not inline `$request->validate()`)?
- [ ] Does `update()` use a FormRequest class?
- [ ] Is `$request->all()` ever passed directly to `create()` or `update()`? (mass assignment risk)
- [ ] Is `$request->validated()` used (not `$request->all()` after validation)?
- [ ] Are file upload fields validated for MIME type, max size, extension?

#### Response & Error Handling Checks
- [ ] Does `store()` redirect with `->with('success', ...)` on success?
- [ ] Does `store()` return back with errors on failure?
- [ ] Are try/catch blocks present for operations that can fail (DB, file, external service)?
- [ ] Do catch blocks return user-friendly error messages (not raw exception dumps)?
- [ ] Are there `dd()`, `dump()`, `var_dump()`, `print_r()`, `die()` calls in ANY method?
- [ ] Are there `Log::info()` / `Log::error()` calls for important operations?

#### Activity Logging Checks
- [ ] Is activity logging called on `store()` (create action)?
- [ ] Is activity logging called on `update()` (update action)?
- [ ] Is activity logging called on `destroy()` (delete action)?
- [ ] Reference `{ACTIVITY_LOG}` for the correct helper function signature

#### Code Quality Checks
- [ ] Is any controller method LONGER than 50 lines? (God method — needs refactoring)
- [ ] Is the controller FILE longer than 400 lines? (God controller — needs splitting)
- [ ] Are there empty/stub methods with no body or only a comment?
- [ ] Are services injected via constructor (not instantiated with `new` inside methods)?
- [ ] Is there repeated logic across multiple methods that should be extracted to a private method or service?
- [ ] Are there hardcoded IDs, strings, or config values that should come from config/DB?

#### Soft Delete Checks
- [ ] Does `destroy()` soft-delete (not force-delete by default)?
- [ ] Does a `restore()` method exist for soft-deleted records?
- [ ] Does a `forceDelete()` method exist?
- [ ] Is there a trash/recycle bin view showing soft-deleted records?

---

### 4B — Models (`{MODULE_PATH}/app/Models/`)

For EACH model, perform ALL these checks:

#### Table & Fillable Checks
- [ ] Is `$table` explicitly set with the correct prefixed name (e.g., `hpc_reports`)?
- [ ] Does `$fillable` include ALL columns from the DB table (Step 2)?
- [ ] Are there columns in `$fillable` that DON'T exist in DB? (crashes on insert)
- [ ] Is `$guarded = []` used? (dangerous — should use explicit `$fillable`)
- [ ] Is `is_active` in `$fillable`? (should be — used for toggle)
- [ ] Is `created_by` in `$fillable`? (should be — set from auth()->id())
- [ ] Are `created_at`, `updated_at`, `deleted_at` NOT in `$fillable`? (managed by Laravel)

#### Casts & Attributes Checks
- [ ] Are all `*_json` columns cast as `array` or `collection` in `$casts`?
- [ ] Are all `is_*` / `has_*` columns cast as `boolean` in `$casts`?
- [ ] Are date/timestamp columns cast as `datetime` or `Carbon` where needed?
- [ ] Are ENUM columns cast as appropriate backed enum or string?
- [ ] Are there Accessor / Mutator methods for computed or formatted attributes?

#### Trait & Interface Checks
- [ ] Does the model use `SoftDeletes` trait? (required by project rules)
- [ ] If using `InteractsWithMedia` — does `registerMediaConversions()` use `?Media $media = null`? (PHP 8.4 compat)
- [ ] Does the model use `HasFactory` trait?
- [ ] Are there any custom traits defined for shared behavior?

#### Relationships Checks
- [ ] Is a `belongsTo()` defined for EVERY FK column in the table?
- [ ] Are `hasMany()` / `hasOne()` defined for all child relationships?
- [ ] Are `belongsToMany()` defined for all junction table relationships?
- [ ] Do relationship method names follow Laravel convention (camelCase, singular for belongsTo/hasOne, plural for hasMany/belongsToMany)?
- [ ] Do all `belongsToMany()` calls specify the correct junction table name?
- [ ] Are any relationships pointing to WRONG model class or wrong FK column?
- [ ] Are there `withTrashed()` / `onlyTrashed()` scope methods needed?

#### Scope Checks
- [ ] Is there a global scope for `is_active = 1`? (or is this handled in queries?)
- [ ] Are there named local scopes (`scopeActive()`, `scopeForSession()`, etc.) used across controllers?
- [ ] Are there any scopes that accidentally bypass tenant isolation?

#### Observer Checks
- [ ] Is there an Observer class for this model? (check `{MODULE_PATH}/app/Observers/`)
- [ ] Is the Observer registered in the module's ServiceProvider?
- [ ] Does the Observer handle `created`, `updated`, `deleted` events correctly?

---

### 4C — Services (`{MODULE_PATH}/app/Services/`)

For EACH service, perform ALL these checks:

#### Registration Checks
- [ ] Is the service bound in the module's `ModuleServiceProvider::register()`?
- [ ] Is it bound as singleton (`$this->app->singleton(...)`) or instance (`$this->app->bind(...)`)?
- [ ] Is the service injected via controller constructor (not `new ServiceClass()` inline)?

#### Transaction Checks
- [ ] Are multi-step write operations wrapped in `DB::transaction()`?
- [ ] Are transactions using `DB::transaction(function() { ... })` or manual `beginTransaction()`/`commit()`/`rollback()`?
- [ ] Is `DB::rollback()` called in catch blocks for manual transactions?

#### Error Handling Checks
- [ ] Are exceptions caught and re-thrown as domain-specific exceptions?
- [ ] Are there silent catch blocks that swallow errors with no logging?
- [ ] Are external service calls (Razorpay, email, SMS) wrapped in try/catch?
- [ ] Are there `dd()` / `dump()` calls in service methods?

#### Data Integrity Checks
- [ ] Are hardcoded IDs, API keys, URLs, or email addresses present? (should use config)
- [ ] Are raw SQL queries (`DB::statement()`, `DB::select()` with string SQL) used? (prefer Eloquent)
- [ ] Do raw queries use parameterized bindings (no string concatenation of user input)?
- [ ] Is `created_by` being set from `auth()->id()` (not hardcoded)?

---

### 4D — Form Requests (`{MODULE_PATH}/app/Http/Requests/`)

- [ ] Does a FormRequest exist for EVERY `store()` method?
- [ ] Does a FormRequest exist for EVERY `update()` method?
- [ ] List controllers using `$request->validate()` inline — needs FormRequest
- [ ] Does each FormRequest have a proper `authorize()` method (not just `return true`)?
- [ ] Do `exists:` rules use PREFIXED table names? (e.g., `exists:sch_classes,id` not `exists:classes,id`)
- [ ] Do `unique:` rules use PREFIXED table names?
- [ ] Do `unique:` rules on update() ignore the current record's ID?
- [ ] Are required fields marked `required` (not missing validation entirely)?
- [ ] Are optional fields marked `nullable` where appropriate?
- [ ] Are string fields validated with `max:` to prevent oversized input?
- [ ] Are file upload fields validated for `mimes:` and `max:` size?
- [ ] Are FK fields validated with `exists:` to prevent orphaned records?
- [ ] Are ENUM fields validated with `in:` listing allowed values?

---

### 4E — Policies (`{POLICIES_DIR}/`)

- [ ] Does a Policy class exist for EACH major model in this module?
  - List which models have policies and which don't
- [ ] Is each Policy registered in `{APP_PROVIDERS}` via `Gate::policy(Model::class, Policy::class)`?
- [ ] Does each Policy have ALL 7 standard methods?
  ```
  viewAny(), view(), create(), update(), delete(), restore(), forceDelete()
  ```
- [ ] Are there non-standard actions in controllers (approve, publish, review, generate, send, toggle, export)?
  - Does the Policy have matching extra methods for these?
- [ ] Does each method check the correct Spatie permission string: `$user->can('tenant.{slug}.{action}')`?
- [ ] Is `before()` method ABSENT from all policies? (global bypass is in AppServiceProvider — do NOT add before() to individual policies)
- [ ] Are any Policy methods returning `true` without checking permissions? (security hole)

---

### 4F — Views (`{MODULE_PATH}/resources/views/`)

#### Existence Checks
- [ ] Does a view file exist for every `view()` call in controllers?
- [ ] Are there view files that exist but are never referenced (dead views)?
- [ ] Are there partial views referenced with `@include()` that DON'T exist?
- [ ] Are there component references (`<x-*>`) that don't have corresponding component files?

#### Form Correctness Checks
- [ ] Do ALL forms have `@csrf`?
- [ ] Do PUT/PATCH forms have `@method('PUT')` or `@method('PATCH')`?
- [ ] Do DELETE forms have `@method('DELETE')`?
- [ ] Do forms display validation errors with `@error('field')` or `$errors->get('field')`?
- [ ] Do forms pre-fill `old()` values on validation failure?
- [ ] Do edit forms pre-populate existing values from the model?

#### Data Display Checks
- [ ] Do index/list views show ALL important columns?
- [ ] Are there `{{ $variable }}` usages where variable might be null? (should use `{{ $variable ?? '' }}` or null-safe)
- [ ] Are there hardcoded tenant IDs, school codes, or user IDs in blade files?
- [ ] Are there direct DB queries inside blade files? (`Model::where(...)` in views is bad)
- [ ] Do views have `@forelse` with `@empty` for empty state handling?

#### Soft Delete UI Checks
- [ ] Is there a trash/recycle bin view for soft-deleted records?
- [ ] Are restore and force-delete buttons present in trash view?
- [ ] Is deleted record clearly indicated (strikethrough, badge, etc.) if shown in main list?

#### Pagination Checks
- [ ] Are list views using `->paginate()` (not `->get()`) for large datasets?
- [ ] Are `{{ $collection->links() }}` pagination links present in list views?

---

### 4G — Jobs, Events & Listeners

Check `{MODULE_PATH}/app/Jobs/`, `{MODULE_PATH}/app/Events/`, `{MODULE_PATH}/app/Listeners/`:

- [ ] Are there any heavy operations in controllers that should be dispatched as Jobs?
  (PDF generation, bulk email, report calculation, data import/export)
- [ ] Are existing Jobs using `ShouldQueue` interface?
- [ ] Do Jobs initialize tenant context in `handle()`? (tenancy context lost in queued jobs)
- [ ] Do Jobs have `$tries` and `$backoff` properties set?
- [ ] Are Events fired for important domain actions (created, approved, sent, etc.)?
- [ ] Are Event listeners registered in the module's `EventServiceProvider`?
- [ ] Are Listeners queued (`ShouldQueue`) for non-blocking processing?

---

### 4H — Emails / Mailables

Check `{MODULE_PATH}/app/Emails/` or `{MODULE_PATH}/app/Mail/`:

- [ ] Are there Mailable classes for all email notifications in this module?
- [ ] Are email templates in `{MODULE_PATH}/resources/views/emails/`?
- [ ] Are Mailables dispatched via `Mail::to()->send()` or `Mail::to()->queue()`?
- [ ] Is email dispatch queued (not synchronous in web request)?
- [ ] Are there hardcoded email addresses in Mailables?

---

### 4I — Module Service Providers

Check `{MODULE_PATH}/app/Providers/`:

- [ ] Does `{MODULE_NAME}ServiceProvider` register all Services as singletons?
- [ ] Does `RouteServiceProvider` load routes correctly?
- [ ] Does `EventServiceProvider` register all Events → Listeners?
- [ ] Are there any services or bindings that should be in the provider but are missing?

---

### 4J — Seeders

Check `{MODULE_PATH}/database/seeders/`:

- [ ] Is there a seeder for required config/master data (types, statuses, categories)?
- [ ] Is the seeder called from `TenantDatabaseSeeder`?
- [ ] Does the seeder use `updateOrCreate()` (idempotent) instead of `create()` (fails on re-run)?
- [ ] Are there seeder routes exposed in tenant.php (unauthenticated data creation endpoint)?

---

## ═══ STEP 5 — TEST COVERAGE DEEP ANALYSIS ═══

### 5A — Browser Tests
Check `{BROWSER_TESTS}/`:
- [ ] Does the directory exist?
- Read ALL test files found
- For each file: list all `it()` / `test()` function names and what they test

### 5B — Unit & Feature Tests
Check `{MODULE_TESTS}/`:
- Read all Unit and Feature test files
- For each: list test names and coverage area

Check `{FEATURE_TESTS}/`:
- Read ALL test files found
- For each: list test names and coverage area

Check `{UNIT_TESTS}/`:
- Read ALL test files found
- For each: list test names and coverage area


### 5C — Coverage Gap Matrix
Build a matrix: for each Controller@Method, does a test exist?

| Controller | Method | Browser Test | Unit Test | Feature Test | Coverage |
|-----------|--------|-------------|-----------|-------------|---------|
| {Controller} | index() | ✅/❌ | ✅/❌ | ✅/❌ | % |
| {Controller} | store() | ✅/❌ | ✅/❌ | ✅/❌ | % |
| ... | | | | | |

### 5D — Critical Missing Test Types
- [ ] No test for UNAUTHORIZED access (non-logged-in user gets 401/403?)
- [ ] No test for WRONG ROLE access (teacher accessing admin route?)
- [ ] No test for VALIDATION FAILURE (store with missing required field)
- [ ] No test for SOFT DELETE (destroy → not in index → restore → back in index)
- [ ] No test for TENANT ISOLATION (one tenant cannot access another's data)
- [ ] No test for FORM SUBMISSION (create → store → redirect with success)
- [ ] No test for UPDATE (edit → update → changes saved)

---

## ═══ STEP 6 — BUSINESS LOGIC COMPLETENESS ═══

Based on DB tables (Step 2) and existing code (Step 4), check if the full business workflow is implemented:

### 6A — CRUD Completeness
For each DB table in this module:
- [ ] Is there a corresponding Model?
- [ ] Is there a corresponding Controller?
- [ ] Are all 9 standard CRUD actions implemented? (index/create/store/show/edit/update/destroy/restore/forceDelete)
- [ ] Is there an index view? create/edit form? show view?

### 6B — Workflow Completeness
Does the module have any multi-step workflows (approval, publish, generate, assign)?
For each workflow:
- [ ] Is the initial state set correctly on create?
- [ ] Are all state transitions implemented?
- [ ] Are invalid transitions blocked?
- [ ] Are workflow events fired (for notifications/logging)?
- [ ] Is the current state visible in the UI?

### 6C — Reporting & Export
- [ ] Does the module need a PDF report? Is it implemented?
- [ ] Does the module need Excel export? Is it implemented?
- [ ] Does the module need any dashboard/summary view? Is it implemented?

### 6D — Search & Filter
- [ ] Do index views have search by name/keyword?
- [ ] Do index views have relevant filters (by class, section, session, status, date)?
- [ ] Is search implemented server-side (not client-side JS on paginated data)?

### 6E — Bulk Operations
- [ ] Does the module need bulk import? Is it implemented?
- [ ] Does the module need bulk action (bulk delete, bulk assign, bulk update status)? Is it implemented?
- [ ] If bulk import exists, does it validate each row and report row-level errors?

---

## ═══ STEP 7 — SECURITY DEEP AUDIT ═══

Check for ALL 18 security issues. Note exact file + line for each found:

| Code | Check | What to Find |
|------|-------|-------------|
| SEC-01 | Mass Assignment — Privilege | `is_super_admin` in Model `$fillable` |
| SEC-02 | Mass Assignment — Data | `$request->all()` in `create()` or `update()` |
| SEC-03 | Missing Gate — Index | `index()` with no Gate check |
| SEC-04 | Missing Gate — Show | `show()` with no Gate check |
| SEC-05 | Missing Gate — Write | `store()`/`update()`/`destroy()` with no Gate check |
| SEC-06 | Missing Gate — Custom | Non-standard actions (approve/publish/generate) with no Gate check |
| SEC-07 | Missing Route Auth | Routes with no `auth` middleware |
| SEC-08 | Missing Module Guard | Module routes without `EnsureTenantHasModule` middleware |
| SEC-09 | Hardcoded Secrets | API keys, passwords, tokens hardcoded in PHP files |
| SEC-10 | Webhook Auth Conflict | Webhook routes inside `auth` middleware (will always return 401) |
| SEC-11 | Config Cache Break | `env()` called directly in route files (breaks after `config:cache`) |
| SEC-12 | SQL Injection | Raw SQL with string-concatenated user input |
| SEC-13 | File Upload Risk | File upload without MIME type + size validation |
| SEC-14 | Validation Table Name | `exists:` / `unique:` using unprefixed table name (bypasses tenant scope) |
| SEC-15 | Cross-Tenant Leak | Queries without tenant scope that can return other schools' data |
| SEC-16 | Exposed Seeder Route | GET route that runs seeders accessible without auth in production |
| SEC-17 | IDOR Risk | `show()`/`edit()` that load by ID without checking tenant ownership |
| SEC-18 | Open Redirect | Redirect using unvalidated user input as URL |

---

## ═══ STEP 8 — PERFORMANCE DEEP AUDIT ═══

Check for ALL performance issues. Note exact file + line + estimated query count impact.

### 8A — Query Performance

| Code | Check | What to Find |
|------|-------|-------------|
| PERF-Q01 | Unbounded Query | `Model::all()` anywhere — no scope, no limit, no pagination |
| PERF-Q02 | N+1 in Loop | `foreach` loop calling `->relation` / `Model::find()` / `->where()` inside it |
| PERF-Q03 | Missing Eager Load | Relationships accessed on collection without `with()` |
| PERF-Q04 | Count in Loop | `->count()` or `->exists()` inside loop — use `withCount()` / `loadCount()` |
| PERF-Q05 | Get then Count | `->get()` then `->count()` on same builder — call `->count()` on builder directly |
| PERF-Q06 | Duplicate Queries | Same query executed 2+ times in same method/request |
| PERF-Q07 | Select Star | `->get()` fetching all columns when 1-3 columns needed — add `->select(['id','name'])` |
| PERF-Q08 | Unindexed WHERE | Frequent `->where('column', $val)` on column with no DB index |
| PERF-Q09 | Unindexed ORDER | `->orderBy('column')` on non-indexed column on large table |
| PERF-Q10 | No Chunk on Bulk | Processing >1000 records without `->chunk()` or `->cursor()` |
| PERF-Q11 | User::all | `User::all()` / `Teacher::all()` / `Student::all()` — always unbounded |
| PERF-Q12 | withTrashed Scan | `withTrashed()` on large table without additional scope — full table scan |

### 8B — Controller / View Layer

| Code | Check | What to Find |
|------|-------|-------------|
| PERF-V01 | Tab Data Eagerness | `index()` loads all tab data at once — should AJAX-load per tab |
| PERF-V02 | PDF in Request | PDF generation inside synchronous web request — should be queued Job |
| PERF-V03 | Excel in Request | Excel import/export inside web request without chunking |
| PERF-V04 | File Ops Sync | Image resize/compress/convert in synchronous request |
| PERF-V05 | Logic in Blade | `Model::where()` or `DB::select()` called directly inside Blade view |
| PERF-V06 | No Pagination | List view using `->get()` instead of `->paginate(20)` on growing dataset |
| PERF-V07 | View Composer Abuse | ViewComposer running expensive queries on every render |

### 8C — Caching

| Code | Check | What to Find |
|------|-------|-------------|
| PERF-C01 | Dropdown No Cache | Class/subject/teacher/room dropdown fetched fresh every page load |
| PERF-C02 | Settings No Cache | Settings/config data queried on every request |
| PERF-C03 | Cache No Prefix | `Cache::remember('key', ...)` without tenant ID prefix — cross-tenant collision |
| PERF-C04 | Analytics No Cache | Report/analytics computed fresh on every load |
| PERF-C05 | Loop Config Fetch | Config/seeder data fetched inside loop — should load once before loop |
| PERF-C06 | Wrong TTL | Cache TTL too short (config data with 60s TTL) or too long (user data with 1hr TTL) |

### 8D — Memory & Resources

| Code | Check | What to Find |
|------|-------|-------------|
| PERF-M01 | Memory Flood | Large collection loaded into PHP memory — use `cursor()` or `chunk(1000)` |
| PERF-M02 | Chunk Too Large | `chunk()` size > 500 for heavy processing (image, PDF, API calls per record) |
| PERF-M03 | PDF Memory | Large PDF loaded entirely into memory — use streaming/incremental |
| PERF-M04 | Infinite Recursion | Recursive method without depth limit (tree structures, nested categories) |
| PERF-M05 | Job No Limit | Queued job processing unlimited records in single execution |

---

## ═══ STEP 9 — ARCHITECTURE & CONVENTIONS AUDIT ═══

### 9A — Tenancy Isolation
- [ ] No central models (`Modules\Prime\Models\*`, `Modules\GlobalMaster\Models\*`) imported inside tenant module controllers?
- [ ] No tenant-scoped queries run outside tenant context?
- [ ] No `DB::connection('central')` or `DB::connection('mysql')` hardcoded in tenant code?
- [ ] Academic year resolved via: `OrganizationAcademicSession::where('is_current', true)->firstOrFail()`

### 9B — Naming Conventions
- [ ] Route names follow: `{module-kebab}.{resource-kebab}.{action}` ?
- [ ] Blade view files use kebab-case folder/file names?
- [ ] Policy class names follow: `{ModelName}Policy`?
- [ ] FormRequest class names follow: `Store{ModelName}Request` / `Update{ModelName}Request`?
- [ ] Service class names follow: `{ModuleName}{Feature}Service`?

### 9C — God Controller / God Method Detection
- [ ] Any controller > 400 lines? (list them with line count)
- [ ] Any single method > 60 lines? (list them)
- [ ] Any controller doing DB work that should be in a Service?
- [ ] Any controller with > 10 injected dependencies?

### 9D — Module Structure Completeness
Check that these standard files exist:
- [ ] `{MODULE_PATH}/app/Providers/{MODULE_NAME}ServiceProvider.php`
- [ ] `{MODULE_PATH}/app/Providers/RouteServiceProvider.php`
- [ ] `{MODULE_PATH}/app/Providers/EventServiceProvider.php`
- [ ] `{MODULE_PATH}/module.json`
- [ ] `{MODULE_PATH}/composer.json`
- [ ] `{MODULE_PATH}/routes/web.php` (even if empty — intentional)
- [ ] `{MODULE_PATH}/routes/api.php`

---

## ═══ OUTPUT — FULL GAP ANALYSIS REPORT ═══

After completing ALL 9 steps above for the current module, produce this report and write it to:
**`{OUTPUT_DIR_A}/{MODULE_NAME}_Deep_Gap_Analysis_{DATE}.md`**

---

```markdown
# {MODULE_NAME} Module — Production-Readiness Gap Analysis
**Date:** {DATE}  |  **Branch:** {APP_BRANCH}  |  **Auditor:** Claude Code (Deep Audit)
**Module Path:** {MODULE_PATH}

{GAP_ANALYSIS}
---

## EXECUTIVE SUMMARY

| Category | Found | Severity Breakdown |
|----------|-------|--------------------|
| Missing Features | X | Critical: X / High: X / Medium: X |
| Bugs (Crashes / Wrong Logic) | X | Critical: X / High: X / Medium: X |
| Security Issues | X | Critical: X / High: X / Medium: X |
| Performance Issues — Queries | X | — |
| Performance Issues — View/Controller | X | — |
| Performance Issues — Caching | X | — |
| Performance Issues — Memory | X | — |
| Missing Tests | X | — |
| DB / Model Mismatches | X | — |
| Missing Policies | X | — |
| Stub / Empty Methods | X | — |
| Architecture Violations | X | — |
| **TOTAL ISSUES** | **X** | — |

### Module Scorecard
| Area | Score | Status |
|------|-------|--------|
| Feature Completeness | X / 10 | 🔴🟡🟢 |
| Security | X / 10 | 🔴🟡🟢 |
| Performance | X / 10 | 🔴🟡🟢 |
| Test Coverage | X / 10 | 🔴🟡🟢 |
| Code Quality | X / 10 | 🔴🟡🟢 |
| Architecture | X / 10 | 🔴🟡🟢 |
| **Overall** | **X / 10** | 🔴🟡🟢 |

**Overall Completion:** X%
**Production Ready:** ❌ NO / ⚠️ PARTIAL / ✅ YES
**Reason:** (one sentence why)

---

## SECTION 1 — MISSING FEATURES

> Features the module should have (based on DB schema + domain rules) but doesn't yet.

### MF-001: [Feature Name]
- **Expected:** What this module SHOULD do
- **DB Evidence:** Which table/columns indicate this feature is planned
- **Current State:** What is built so far
- **Gap:** What exactly is missing
- **Impact:** 🔴 Critical / 🟡 High / 🟢 Medium / ⚪ Low
- **Effort:** S (< 2h) / M (2–8h) / L (1–3 days) / XL (> 3 days)
- **Files to Create:** list
- **Files to Edit:** list

---

## SECTION 2 — BUGS (Crashes, Wrong Logic, Data Corruption Risks)

### BUG-001: [Bug Title]
- **File:** `path/to/Controller.php` : line X
- **Code (problematic):**
  ```php
  // paste the buggy line(s) here
  ```
- **Symptom:** What error/wrong behavior occurs
- **Root Cause:** Why it happens technically
- **Impact:** What breaks, which users are affected
- **Fix:**
  ```php
  // paste the correct code here
  ```
- **Severity:** 🔴 Critical (crash/data loss) / 🟡 High (wrong data) / 🟢 Medium / ⚪ Low

---

## SECTION 3 — SECURITY ISSUES

### SEC-001: [Issue Title]
- **Check Triggered:** SEC-XX
- **File:** `path/to/file.php` : line X
- **Code (vulnerable):**
  ```php
  // paste vulnerable line here
  ```
- **Risk:** What an attacker can do (data theft / privilege escalation / DoS / etc.)
- **Fix:**
  ```php
  // paste the secure version here
  ```
- **Priority:** 🔴 Fix Immediately / 🟡 Fix Before Release / 🟢 Fix Soon

---

## SECTION 4 — PERFORMANCE ISSUES

### 4A — Query Performance (N+1, Unbounded, Missing Indexes)

#### PERF-Q-001: [Issue Title]
- **Check Triggered:** PERF-QXX
- **File:** `path/to/file.php` : line X
- **Problem Code:**
  ```php
  // paste problematic code
  ```
- **Impact:** +X DB queries per page load (X rows × Y relations)
- **Fix:**
  ```php
  // paste optimized code
  ```

### 4B — Controller / View Layer Performance

#### PERF-V-001: [Issue Title]
- **Check Triggered:** PERF-VXX
- **File:** `path/to/file.php` : line X
- **Impact:** Adds ~Xs to page response / XMB memory
- **Fix:** Description + code if applicable

### 4C — Caching Issues

#### PERF-C-001: [Issue Title]
- **Check Triggered:** PERF-CXX
- **File:** `path/to/file.php` : line X
- **Currently:** Fetched fresh every request
- **Fix:**
  ```php
  Cache::remember('tenant_'.tenant()->id.'_{key}', 3600, function() {
      // query here
  });
  ```

### 4D — Memory / Resource Issues

#### PERF-M-001: [Issue Title]
- **Check Triggered:** PERF-MXX
- **File:** `path/to/file.php` : line X
- **Impact:** XMB peak memory / timeout risk on large datasets
- **Fix:** Use `cursor()` / `chunk(500)` / streaming

---

## SECTION 5 — AUTHORIZATION GAPS

Every controller method with NO Gate check:

| Controller | Method | HTTP | Required Permission | Fix |
|-----------|--------|------|--------------------|----|
| FooController | index() | GET | `tenant.foo.viewAny` | Add `Gate::authorize('tenant.foo.viewAny')` |
| ... | | | | |

---

## SECTION 6 — MISSING POLICIES

| Model | Policy File | Registered in AppServiceProvider | Standard Methods Missing | Extra Actions Missing |
|-------|------------|----------------------------------|--------------------------|----------------------|
| FooModel | ❌ Missing | ❌ | viewAny,view,create... | approve,publish |
| ... | | | | |

---

## SECTION 7 — DB / MODEL MISMATCHES

### 7A — Columns in DB but NOT in Model $fillable
| Table | Column | Type | Nullable | Action |
|-------|--------|------|---------|--------|
| hpc_reports | status | enum | NO | Add to `$fillable` |
| ... | | | | |

### 7B — Columns in Model $fillable but NOT in DB
| Model | Column | Action |
|-------|--------|--------|
| HpcReport | report_hash | Add migration or remove from fillable |
| ... | | |

### 7C — Missing $casts
| Model | Column | Should Be Cast As | Fix |
|-------|--------|-----------------|-----|
| | | | |

### 7D — Missing Relationships
| Model | FK Column | Missing Relationship | Fix |
|-------|-----------|---------------------|-----|
| | | | |

### 7E — Migration Issues
| Issue | Table | Details | Action |
|-------|-------|---------|--------|
| | | | |

---

## SECTION 8 — ROUTE ISSUES

| Method | URI | Problem | Fix |
|--------|-----|---------|-----|
| GET | /foo/bar | Controller FooController not found | Create controller |
| POST | /foo | No auth middleware | Add to middleware group |
| ... | | | |

---

## SECTION 9 — MISSING FORM REQUESTS

| Controller | Method | Current Validation | Required FormRequest | Fix |
|-----------|--------|-------------------|---------------------|-----|
| | | `$request->all()` | `StoreFooRequest` | Create FormRequest class |
| | | | | |

---

## SECTION 10 — TEST COVERAGE GAPS

### Existing Tests
| File Path | Test Count | What It Covers |
|-----------|-----------|----------------|
| | | |

### Coverage Matrix
| Controller | Method | Browser | Unit | Feature | Status |
|-----------|--------|---------|------|---------|--------|
| | index() | ❌ | ❌ | ❌ | 🔴 None |
| | store() | ✅ | ❌ | ❌ | 🟡 Partial |
| | | | | | |

### Critical Missing Tests
| Test Description | Priority | Type Needed |
|-----------------|---------|------------|
| Unauthorized access → 403 | 🔴 | Feature |
| Wrong role → 403 | 🔴 | Feature |
| Validation failure → errors shown | 🟡 | Feature |
| Tenant isolation — cannot view other tenant's data | 🔴 | Feature |
| | | |

---

## SECTION 11 — STUB / EMPTY METHODS

| File | Method | Lines | Status | Action |
|------|--------|-------|--------|--------|
| | | | Empty body | Implement or remove |
| | | | Has `// TODO` | Implement |
| | | | Has `dd()` | Remove dd(), implement |
| | | | | |

---

## SECTION 12 — ARCHITECTURE VIOLATIONS

| Violation Type | File | Details | Fix |
|---------------|------|---------|-----|
| God Controller | FooController.php | 2483 lines | Split into sub-controllers |
| Cross-layer import | BarController.php | Uses `Prime\Models\Setting` in tenant module | Replace with tenant Setting model |
| Cross-tenant risk | BazController.php:45 | No tenant scope on query | Add `->where('tenant_id', tenant()->id)` |
| | | | |

---

## SECTION 13 — WHAT IS WORKING CORRECTLY ✅

List features that are fully implemented, tested, and production-ready:

| Feature | Controller | Status |
|---------|-----------|--------|
| | | ✅ Complete |

---

## PRIORITY FIX PLAN

### P0 — 🔴 FIX IMMEDIATELY (Security / Fatal Crash / Data Loss)
> Deploy blocker — do NOT go to production without fixing these

1. **[SEC/BUG-XXX]** — Short description — File:line
2. ...

### P1 — 🟡 FIX BEFORE RELEASE (Auth Gaps / Major Bugs / Data Integrity)
> Core functionality broken or unauthorized access possible

1. **[SEC/BUG-XXX]** — Short description — File:line
2. ...

### P2 — 🟠 FIX SOON (Performance / Missing Business Logic)
> App works but slowly or missing features block users

1. **[PERF/MF-XXX]** — Short description — File:line
2. ...

### P3 — ⚪ NICE TO HAVE (Refactors / Tests / Minor Gaps)
> Quality improvements, not blockers

1. **[TEST/ARCH-XXX]** — Short description
2. ...

---

## PERFORMANCE OPTIMIZATION ROADMAP

### Quick Wins — < 1 hour each (add eager loading, pagination, select columns)
| Issue | File | Fix |
|-------|------|-----|
| | | |

### Medium Effort — 2–8 hours (AJAX tabs, cache layer, queue jobs)
| Issue | File | Estimated Time | Fix |
|-------|------|---------------|-----|
| | | | |

### Large Effort — > 1 day (God controller split, bulk import, analytics pipeline)
| Issue | Estimated Time | Plan |
|-------|---------------|------|
| | | |

---

## EFFORT ESTIMATION

| Work Area | Items | Estimated Hours |
|-----------|-------|----------------|
| P0 Critical Fixes | X items | ~X hours |
| P1 Auth & Bug Fixes | X items | ~X hours |
| P2 Feature Completion | X items | ~X hours |
| P2 Performance Fixes | X items | ~X hours |
| P3 Tests | X items | ~X hours |
| P3 Refactors | X items | ~X hours |
| **TOTAL** | **X items** | **~X hours** |
```

---

## ▶ ANALYSIS RULES — READ BEFORE STARTING

1. **Open every file** — do not guess or assume from filenames. Read actual code.
2. **Check the real DB** — always cross-reference with `{DATABASE_FILE}`, not just model definitions.
3. **Be specific** — every issue MUST have exact file path + line number.
4. **No false positives** — only report an issue if you have confirmed it in the code.
5. **Tenancy awareness** — never flag tenant-scoped code as a bug for not accessing central DB.
6. **Policy registration** — always check `{APP_PROVIDERS}` to see which policies are actually registered.
7. **Read-only** — do NOT modify any code. Only read and report.
8. **No hallucination** — if a file doesn't exist, say it's missing. Do not invent content.
9. **Show the code** — for bugs and security issues, paste the actual problematic lines and the fix.
10. **Count everything** — the Summary table must have accurate counts from your actual findings.

---

## ▶ START NOW — EXECUTION ORDER

```
Step 0-A → Read this prompt file → Derive DB_REPO from the path
Step 0-B → Read {DB_REPO}/AI_Brain/config/paths.md
           → Get LARAVEL_REPO, TENANT_DDL, PRIME_DDL, GLOBAL_DDL, AI_BRAIN from there
Step 0-C → Build all derived paths from MODULE_NAME and the configuration above

Step 1   → Read AI Brain (15 files — memory + rules + lessons)
           → This only needs to be done ONCE. Retain context for all modules.

─── BEGIN MODULE LOOP (for each module in the List of Modules table) ───

  Set MODULE_NAME and MODULE_TYPE from the current row in the list.
  Resolve DATABASE_FILE based on MODULE_TYPE.

  Step 2   → Extract module tables from the appropriate DDL file + cross-check migrations
             (Skip if MODULE_TYPE = "Other")
  Step 3   → Map all module routes from ROUTES_FILE
  Step 4   → Read every PHP file inside MODULE_PATH
             Controllers → Models → Services → Requests →
             Policies → Views → Jobs → Events → Providers → Seeders
  Step 5   → Read tests (BROWSER_TESTS + MODULE_TESTS + FEATURE_TESTS + UNIT_TESTS)
  Step 6   → Business logic completeness check
  Step 7   → Security audit (18 checks)
  Step 8   → Performance audit (30+ checks)
  Step 9   → Architecture audit
  OUTPUT   → Write full gap analysis report to:
             {OUTPUT_DIR_A}/{MODULE_NAME}_Deep_Gap_Analysis.md
  STATUS   → Print: ✅ [X/29] {MODULE_NAME} — Analysis complete

─── END MODULE LOOP ───

FINAL    → Write Summary Index to:
           {OUTPUT_DIR_A}/_Module_Analysis_Summary_{DATE}.md
           (Table of all modules with scores, issue counts, and file links)
```

**Start from Step 0-A. Do not skip any step. Read all files before writing any output. Process every module in the list sequentially.**
