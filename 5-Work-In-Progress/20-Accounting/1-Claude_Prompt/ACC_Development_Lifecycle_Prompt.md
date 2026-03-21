# ACC — Accounting Module Development Lifecycle Prompt

**Purpose:** This is a single consolidated prompt to build the complete Accounting module for Prime-AI through all 9 development phases. Paste this into Claude and work through each phase sequentially. Claude will stop after each phase for your review and confirmation.

**Date:** 2026-03-20
**Developer:** Brijesh | **Branch:** Brijesh_Finance

---

## CONFIGURATION (Referenced throughout all phases)

```
MODULE_CODE       = ACC
MODULE            = Accounting
MODULE_DIR        = Modules/Accounting/
APP_REPO          = prime_ai_tarun
BRANCH            = Brijesh_Finance
DEVELOPER         = Brijesh
RBS_MODULE_CODE   = K
DB_TABLE_PREFIX   = acc_
DATABASE_NAME     = tenant_db
OUTPUT_DIR        = databases/5-Work-In-Progress/20-Accounting/DDL
MIGRATION_DIR     = prime_ai_tarun/database/migrations/tenant
REQUIREMENT_FILE  = databases/1-DDL_Tenant_Modules/20-Account/Claude_Plan/Account_Requirement_v4.md
PLAN_FILE         = databases/1-DDL_Tenant_Modules/20-Account/Claude_Plan/Initial_Plan_v4.md
RBS_FILE          = 3-Project_Planning/1-RBS/PrimeAI_RBS_Menu_Mapping_v2.0.md
FEATURE_SPEC_DIR  = databases/5-Work-In-Progress/20-Accounting/2-Claude_Plan/3-Feature_Specs
DDL_DIR           = databases/1-DDL_Tenant_Modules/20-Account/DDL
```

---

## HOW TO USE THIS PROMPT

1. Paste this entire document into a new Claude conversation
2. Tell Claude: **"Start Phase 1"**
3. Claude will read the required files, generate the output, and STOP
4. You review the output, give feedback or confirm: **"Approved. Proceed to Phase 2"**
5. Repeat for all 9 phases
6. For Phase 3 (Screen Planning): YOU provide your layout decisions, then Claude confirms

**Estimated total time:** ~5 working days

---

## PHASE 1 — Requirements & Feature Specification
### Phase 1 Input Files
Read these files BEFORE generating output:
1. `{REQUIREMENT_FILE}` — Complete Accounting module requirement (v4)
2. `{PLAN_FILE}` — Initial plan with architecture and table summary
3. `{RBS_FILE}` — Find Module K section (line 2844)
4. `AI_Brain/memory/project-context.md` — Project context
5. `AI_Brain/memory/modules-map.md` — Existing modules (avoid duplication)
6. `AI_Brain/agents/business-analyst.md` — BA agent instructions

### Phase 1 Task
Generate a comprehensive Feature Specification for the Accounting module.

**Module:** Accounting
**RBS Module Code:** K (Finance & Accounting — 70 sub-tasks)
**Table Prefix:** acc_
**Database:** tenant_db
**Description:** Tally-Prime inspired double-entry bookkeeping system for Indian K-12 schools. Voucher Engine as central nervous system — every transaction flows through acc_vouchers + acc_voucher_items as Dr/Cr pairs.

**No wireframes.** Generate the feature specification from:
- Account_Requirement_v4.md (21 tables, 18 controllers, 9 services)
- Initial_Plan_v4.md (architecture, integration points)
- RBS Module K sub-tasks (K1-K13, 70 sub-tasks)
- Indian K-12 school domain knowledge
- Patterns from existing Prime-AI modules

**Generate:**
1. Entity list — all 21 tables with columns, types, relationships
2. Entity Relationship Diagram (text-based)
3. Business rules — validation rules, cascade behaviors, status workflows
4. Permission list — all Gate permissions needed (accounting.resource.action format)
5. Dependencies — which existing modules this connects to
6. Integration events — StudentFee, Transport, Payroll, Inventory events

Do NOT generate screen layouts yet — that comes in Phase 3.

### Phase 1 Output Files
| File | Location |
|------|----------|
| `ACC_FeatureSpec.md` | `{FEATURE_SPEC_DIR}/ACC_FeatureSpec.md` |

### Phase 1 Quality Gate
- [ ] Every RBS sub-task (K1-K13) maps to at least one entity/column
- [ ] All 21 table relationships (FK) are defined
- [ ] Table names use `acc_` prefix convention
- [ ] Business rules documented (double-entry balance, FY locking, voucher numbering, etc.)
- [ ] All cross-module integration events listed

**After completing Phase 1, STOP and say:** "Phase 1 (Feature Specification) complete. Output: `ACC_FeatureSpec.md`. Please review and confirm to proceed to Phase 2 (DDL Design)."

---

## PHASE 2 — Database Schema Design (DDL + Seeders)
### Phase 2 Input Files
1. `{FEATURE_SPEC_DIR}/ACC_FeatureSpec.md` — Feature spec from Phase 1
2. `{REQUIREMENT_FILE}` — Table schemas (Section 4)
3. `AI_Brain/agents/db-architect.md` — DB Architect agent instructions
4. `databases/0-DDL_Masters/tenant_db_v2.sql` — Existing schema for reference (old acc_* will be replaced)

### Phase 2A Task — Generate DDL
Generate the DDL SQL for all 21 tables in the Accounting module.

**Rules (MUST follow):**
1. Table prefix: `acc_`
2. Every table MUST have: `id` (BIGINT UNSIGNED AUTO_INCREMENT), `is_active`, `created_by`, `created_at`, `updated_at`, `deleted_at`
3. Index ALL foreign keys
4. Junction tables suffix: `_jnt`
5. JSON columns suffix: `_json`
6. Boolean columns prefix: `is_` or `has_`
7. Use `BIGINT UNSIGNED` for all IDs
8. Add `COMMENT` on every column
9. Use InnoDB, utf8mb4_unicode_ci
10. Old acc_* DDL in tenant_db_v2.sql is UNUSED — this is a fresh schema

**Generate:**
1. DDL SQL file — all CREATE TABLE statements with comments
2. Laravel Migration file — for `database/migrations/tenant/`
3. Table summary — one-line description of each table
4. ALTER TABLE for `sch_employees` — add 14 payroll columns

### Phase 2B Task — Generate Seeders
Generate Laravel seeders for:
1. `AccountGroupSeeder` — 32 groups (Tally's 28 + 4 school-specific)
2. `VoucherTypeSeeder` — 10 voucher types with prefixes
3. `TaxRateSeeder` — 5 GST rates (CGST/SGST 9%, IGST 18%, CGST/SGST 2.5%)
4. `CostCenterSeeder` — 10 cost centers (Primary/Middle/Senior Wing, Admin, Transport, etc.)
5. `DefaultLedgerSeeder` — 11 default ledgers (Cash, Petty Cash, GST Payable, etc.)
6. `TallyLedgerMappingSeeder` — ~40 auto-mapped Tally ledger names
7. `AssetCategorySeeder` — 5 categories (Furniture SLM 10%, IT Equipment WDV 40%, etc.)

### Phase 2 Output Files
| File | Location |
|------|----------|
| `ACC_DDL_v1.sql` | `{DDL_DIR}/ACC_DDL_v1.sql` |
| `ACC_Migration.php` | `{OUTPUT_DIR}/ACC_Migration.php` |
| `ACC_SchEmployees_Enhancement.sql` | `{DDL_DIR}/ACC_SchEmployees_Enhancement.sql` |
| `ACC_Seeders/` | `{OUTPUT_DIR}/ACC_Seeders/` (7 seeder files) |
| `ACC_TableSummary.md` | `{OUTPUT_DIR}/ACC_TableSummary.md` |

### Phase 2 Quality Gate
- [ ] All 21 tables from requirement exist in DDL
- [ ] Foreign keys match referenced tables with correct `acc_` prefix
- [ ] Required columns (id, is_active, created_by, timestamps, deleted_at) on ALL tables
- [ ] `acc_vouchers` has source_module + source_type + source_id (polymorphic)
- [ ] `acc_ledgers` has student_id→std_students, employee_id→sch_employees, vendor_id→vnd_vendors
- [ ] sch_employees ALTER TABLE adds 14 columns with Schema::hasColumn() guard

**After completing Phase 2, STOP and say:** "Phase 2 (DDL + Seeders) complete. Output: `ACC_DDL_v1.sql` + 7 seeders. Please review the DDL and confirm to proceed to Phase 3 (Screen Planning)."

---

## PHASE 3 — Screen Planning (USER DECISION POINT)
### Phase 3 — What YOU Do
After reviewing the DDL, YOU decide how screens are organized. Fill in and provide to Claude:

```
# Accounting — Screen Planning

## Master Index Pages (Tab-Based)
[YOUR DECISION: Which entities share a tab-based master page?]
Example:
  Tab-based Master 1: Account Groups + Ledgers + Tax Rates + Cost Centers + Asset Categories
  Tab-based Master 2: [OR each gets its own page?]

## Separate Pages
[YOUR DECISION: Which entities get standalone pages?]
Example:
  - Voucher Entry (most critical — Dr/Cr grid with ledger typeahead)
  - Financial Year management
  - Bank Reconciliation (dual-pane: book vs bank)
  - Budget management
  - Expense Claims
  - Reports (Trial Balance, P&L, Balance Sheet, Day Book, etc.)
  - Dashboard

## Form Layouts
[YOUR DECISION per entity]
  - Voucher: Tabbed (by voucher type: Payment/Receipt/Journal/etc.)
  - Ledger: Slide-out panel from list
  - Account Group: Tree view with inline edit
  - Budget: Grid (cost center rows × ledger columns)

## Special Screens
  - Dashboard with KPI cards + charts
  - Reports with date range filters + PDF/CSV export
  - Tally Ledger Mapping (two-column: Our Ledger ↔ Tally Name)
  - Bank Reconciliation (dual-pane)
```

### Phase 3A — Claude Confirms Screen Plan
After YOU provide your decisions, Claude will confirm:
1. How many Blade view files will be created?
2. How many controllers are needed?
3. Which entities share a controller vs have their own?
4. Which views are tab-based vs standalone?
5. Complete file list for Phase 6 (Frontend)

### Phase 3 Output Files
| File | Location |
|------|----------|
| `ACC_ScreenPlan.md` | `{OUTPUT_DIR}/ACC_ScreenPlan.md` |
| `ACC_FileList.md` | `{OUTPUT_DIR}/ACC_FileList.md` (complete list of all files to be created) |

### Phase 3 Quality Gate
- [ ] You've decided: which tables = which screens
- [ ] You've decided: tabs vs separate pages
- [ ] You've decided: form layout per entity
- [ ] Claude has confirmed the file list and you've approved it

**After completing Phase 3, STOP and say:** "Phase 3 (Screen Planning) complete. Output: `ACC_ScreenPlan.md` + `ACC_FileList.md`. Please review the file list and confirm to proceed to Phase 4 (Scaffolding)."

---

## PHASE 4 — Module Scaffolding
### Phase 4 Input Files
1. `{FEATURE_SPEC_DIR}/ACC_FeatureSpec.md`
2. `{DDL_DIR}/ACC_DDL_v1.sql`
3. `AI_Brain/agents/module-agent.md`
4. `AI_Brain/templates/model.md`
5. Reference module: `Modules/Vendor/` (for structure pattern)

### Phase 4 Task
Create the complete module scaffold for Accounting:

**Module Config:**
- Name: Accounting
- Alias: accounting
- Table prefix: acc_
- Route prefix: /accounting/*

**Generate:**
1. `module.json`, `composer.json`
2. `AccountingServiceProvider.php`, `RouteServiceProvider.php`, `EventServiceProvider.php`
3. `routes/web.php`, `routes/api.php`
4. `app/Contracts/VoucherServiceInterface.php` — shared interface for Payroll & Inventory
5. **21 Models** (one per acc_ table) — with: $table, $fillable (include created_by), $casts, SoftDeletes, all relationships

**CRITICAL RULES:**
- Models use exact table name from DDL
- $fillable includes `created_by`, excludes id/timestamps/deleted_at
- NEVER include `is_super_admin` in $fillable
- All BelongsTo relationships match FK column names

### Phase 4 Output Files
| File | Location |
|------|----------|
| `ACC_ModuleScaffold/` | `{OUTPUT_DIR}/ACC_ModuleScaffold/` (module.json, composers, providers) |
| `ACC_Models/` | `{OUTPUT_DIR}/ACC_Models/` (21 model files) |
| `ACC_VoucherServiceInterface.php` | `{OUTPUT_DIR}/ACC_VoucherServiceInterface.php` |

### Phase 4 Quality Gate
- [ ] Every DDL table has a Model
- [ ] Every Model has SoftDeletes, $table, $fillable, $casts
- [ ] `created_by` in every $fillable
- [ ] VoucherServiceInterface defined with createEntry(), reverseEntry(), getLedgerBalance()

**After completing Phase 4, STOP and say:** "Phase 4 (Scaffolding) complete. Output: 21 models + VoucherServiceInterface. Please review and confirm to proceed to Phase 5 (Backend)."

---

## PHASE 5 — Backend Development
### Phase 5 Input Files
1. `{FEATURE_SPEC_DIR}/ACC_FeatureSpec.md`
2. `{OUTPUT_DIR}/ACC_ScreenPlan.md` — Screen planning from Phase 3
3. `AI_Brain/agents/backend-developer.md`
4. Reference: `Modules/Vendor/app/Http/Controllers/VendorController.php`

### Phase 5A Task — Controllers + FormRequests + Routes
Generate for EACH entity that needs a controller (18 controllers):

**Controller** (11 standard methods): index, create, store, show, edit, update, destroy, trashed, restore, forceDelete, toggleStatus

**FormRequest** (2 per entity): Store[Entity]Request, Update[Entity]Request
- authorize() uses Gate — NOT `return true`
- rules() matches DDL column constraints

**Routes** in module `web.php` AND `routes/tenant.php`:
- trash/restore routes BEFORE Route::resource
- EnsureTenantHasModule middleware on route group

### Phase 5B Task — Services (9 services)
Generate all 9 services:
1. `VoucherService` (implements VoucherServiceInterface) — THE critical service
2. `AccountingService` — balance calculations, ledger balance computation
3. `ReportService` — Trial Balance, P&L, Balance Sheet, Day Book, Cash/Bank Book
4. `ReconciliationService` — bank statement import, auto-match, BRS report
5. `DepreciationService` — SLM/WDV calculations, bulk depreciation run
6. `RecurringJournalService` — auto-generate vouchers from templates (scheduled job)
7. `TallyExportService` — XML generation for Tally export
8. `FeeIntegrationService` — listener for StudentFee events → Receipt Voucher
9. `TransportIntegrationService` — listener for Transport events → Sales/Receipt Voucher

### Phase 5 Output Files
| File | Location |
|------|----------|
| `ACC_Controllers/` | `{OUTPUT_DIR}/ACC_Controllers/` (18 controller files) |
| `ACC_FormRequests/` | `{OUTPUT_DIR}/ACC_FormRequests/` (~30 request files) |
| `ACC_Routes.php` | `{OUTPUT_DIR}/ACC_Routes.php` (module web.php) |
| `ACC_TenantRoutes.php` | `{OUTPUT_DIR}/ACC_TenantRoutes.php` (tenant.php additions) |
| `ACC_Services/` | `{OUTPUT_DIR}/ACC_Services/` (9 service files) |
| `ACC_Events/` | `{OUTPUT_DIR}/ACC_Events/` (event + listener files) |

### Phase 5 Quality Gate
- [ ] Gate::authorize() on every public method
- [ ] $request->validated() on every store/update
- [ ] No $request->all() anywhere
- [ ] Routes in both module web.php AND tenant.php
- [ ] EnsureTenantHasModule middleware applied
- [ ] DB::transaction() on multi-table writes (especially VoucherService)
- [ ] activityLog() on every mutation
- [ ] VoucherService validates Dr = Cr before saving

**After completing Phase 5, STOP and say:** "Phase 5 (Backend) complete. Output: 18 controllers + 9 services + routes. Please review and confirm to proceed to Phase 6 (Frontend)."

---

## PHASE 6 — Frontend Development
### Phase 6 Input Files
1. `{OUTPUT_DIR}/ACC_ScreenPlan.md` — Your screen decisions from Phase 3
2. `AI_Brain/agents/frontend-developer.md`
3. Reference views:
   - Tab-based: `Modules/Transport/resources/views/transport-master/index.blade.php`
   - Simple index: `Modules/SchoolSetup/resources/views/building/index.blade.php`
   - Create form: `Modules/Transport/resources/views/driver_helper/create.blade.php`

### Phase 6 Task
Generate ALL views based on Phase 3 screen decisions (~45 Blade files):
- Index views with columns, pagination, @forelse/@empty
- Create/Edit forms with @csrf, @method, @error, old()
- Show views where requested
- Tab-based master views
- Dashboard with KPI cards + Chart.js
- Report views with date filters + export buttons
- Voucher entry screen (Dr/Cr dynamic grid)
- Bank reconciliation dual-pane view
- Tally ledger mapping screen

**Patterns (MUST follow):**
- Layout: `<x-backend.layouts.app>`
- Breadcrumbs: `<x-backend.components.breadcrum>`
- Card header: `<x-backend.card.header>`
- Status badges: `badge bg-success` / `badge bg-danger`
- Delete: SweetAlert2 confirmation
- Pagination: `{{ $items->links() }}`

### Phase 6 Output Files
| File | Location |
|------|----------|
| `ACC_Views/` | `{OUTPUT_DIR}/ACC_Views/` (~45 Blade files organized by entity) |

### Phase 6 Quality Gate
- [ ] All views use `<x-backend.layouts.app>`
- [ ] Breadcrumbs on every page
- [ ] Forms have @csrf and @method
- [ ] @forelse/@empty on all tables
- [ ] Pagination present
- [ ] No hardcoded route names

**After completing Phase 6, STOP and say:** "Phase 6 (Frontend) complete. Output: ~45 Blade view files. Please review and confirm to proceed to Phase 7 (Security)."

---

## PHASE 7 — Security Hardening
### Phase 7 Task
Verify and fix ALL of the following across the entire module:
1. Gate::authorize() on EVERY public controller method
2. FormRequest authorize() uses Gate — NOT `return true`
3. $request->validated() everywhere — NO $request->all()
4. EnsureTenantHasModule middleware on route group
5. No is_super_admin in any $fillable
6. No ::all() or unbounded ::get()
7. No dd(), dump(), var_dump()
8. No hardcoded API keys
9. Permission naming consistent: accounting.resource.action
10. Central models not queried from tenant context
11. SoftDeletes on all models

Generate Permission Seeder: `AccountingPermissionSeeder.php`

### Phase 7 Output Files
| File | Location |
|------|----------|
| `ACC_PermissionSeeder.php` | `{OUTPUT_DIR}/ACC_PermissionSeeder.php` |
| `ACC_SecurityAudit.md` | `{OUTPUT_DIR}/ACC_SecurityAudit.md` (findings + fixes) |

**After completing Phase 7, STOP and say:** "Phase 7 (Security) complete. Output: PermissionSeeder + SecurityAudit. Please review and confirm to proceed to Phase 8 (Testing)."

---

## PHASE 8 — Testing
### Phase 8 Task
Generate Pest 4.x tests:

**Unit tests** (`tests/Unit/Accounting/`):
- Model instantiation, fillable, casts, relationships, soft delete for all 21 models
- VoucherService: double-entry balance validation
- ReportService: Trial Balance computation
- DepreciationService: SLM/WDV calculations

**Feature tests** (`Modules/Accounting/tests/Feature/`):
- index 200/403, store valid/invalid, update, destroy, restore for key controllers
- Voucher creation with balanced Dr/Cr
- FY locking prevents edits
- Cross-module integration (PayrollApproved → creates voucher)

### Phase 8 Output Files
| File | Location |
|------|----------|
| `ACC_UnitTests/` | `{OUTPUT_DIR}/ACC_UnitTests/` |
| `ACC_FeatureTests/` | `{OUTPUT_DIR}/ACC_FeatureTests/` |

**After completing Phase 8, STOP and say:** "Phase 8 (Testing) complete. Output: unit + feature tests. Please review and confirm to proceed to Phase 9 (Review & Deploy)."

---

## PHASE 9 — Code Review + AI Brain Update + Deploy Checklist
### Phase 9 Task
1. Review all generated code for the module — fix any issues
2. Update AI Brain:
   - `AI_Brain/memory/modules-map.md` — add module with accurate counts
   - `AI_Brain/state/progress.md` — update completion entry
   - `AI_Brain/lessons/known-issues.md` — add any gotchas
3. Generate pre-deployment checklist:
   - `php artisan route:list --path=accounting`
   - `php artisan tenants:migrate --pretend`
   - All seeders run without errors
   - No dd(), dump(), backup files

### Phase 9 Output Files
| File | Location |
|------|----------|
| `ACC_CodeReview.md` | `{OUTPUT_DIR}/ACC_CodeReview.md` |
| `ACC_DeployChecklist.md` | `{OUTPUT_DIR}/ACC_DeployChecklist.md` |

### Phase 9 — Manual Steps (YOU do)
1. `php artisan tenants:migrate`
2. Seed: `php artisan tenants:seed --class="Modules\Accounting\Database\Seeders\AccountingPermissionSeeder"`
3. Assign permissions to roles via admin UI
4. Browser test all screens
5. Git commit on branch `Brijesh_Accounting`

**After completing Phase 9, say:** "Phase 9 (Review & Deploy) complete. All 9 phases done. Module ready for manual deployment steps."

---

## OUTPUT FILE SUMMARY (All 9 Phases)

| Phase | Output File | Description |
|-------|-----------|-------------|
| 1 | `ACC_FeatureSpec.md` | Feature specification with entities, ER diagram, business rules, permissions |
| 2 | `ACC_DDL_v1.sql` | Complete DDL for 21 tables |
| 2 | `ACC_Migration.php` | Laravel migration file |
| 2 | `ACC_SchEmployees_Enhancement.sql` | ALTER TABLE for sch_employees |
| 2 | `ACC_Seeders/` | 7 seeder files |
| 2 | `ACC_TableSummary.md` | One-line description per table |
| 3 | `ACC_ScreenPlan.md` | Screen layout decisions |
| 3 | `ACC_FileList.md` | Complete file list for all phases |
| 4 | `ACC_ModuleScaffold/` | module.json, providers, routes |
| 4 | `ACC_Models/` | 21 model files |
| 4 | `ACC_VoucherServiceInterface.php` | Shared contract |
| 5 | `ACC_Controllers/` | 18 controller files |
| 5 | `ACC_FormRequests/` | ~30 FormRequest files |
| 5 | `ACC_Routes.php` | Module routes |
| 5 | `ACC_TenantRoutes.php` | Tenant route additions |
| 5 | `ACC_Services/` | 9 service files |
| 5 | `ACC_Events/` | Event + listener files |
| 6 | `ACC_Views/` | ~45 Blade view files |
| 7 | `ACC_PermissionSeeder.php` | Permission seeder |
| 7 | `ACC_SecurityAudit.md` | Security findings |
| 8 | `ACC_UnitTests/` | Pest unit tests |
| 8 | `ACC_FeatureTests/` | Pest feature tests |
| 9 | `ACC_CodeReview.md` | Code review results |
| 9 | `ACC_DeployChecklist.md` | Pre-deployment checklist |
