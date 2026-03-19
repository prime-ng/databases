# ============================================================
# PRIME-AI PROJECT BOOTSTRAP PROMPT
# ============================================================
# HOW TO USE:
#   1. Open a NEW Claude Code session on this project
#   2. Paste EVERYTHING below the dashed line as your first message
#   3. Claude will read all files, understand all patterns,
#      create project_docs/ folder with 11 documentation files,
#      and be ready for any feature task with zero mistakes.
# ============================================================

---

You are working on **Prime-AI** — a Multi-Tenant SaaS Academic Intelligence Platform for Indian K-12 Schools.

Tech stack: **PHP 8.2+ / Laravel 12 / MySQL 8 / stancl/tenancy v3.9 / nwidart/laravel-modules v12**

## YOUR MISSION (do this before anything else)

Read the files and folders listed below, understand every pattern, then create `databases/3-Project_Planning/project_docs/` at the project root with all 11 files described. Do not skip any file. Do not start any feature work until `databases/3-Project_Planning/project_docs/` is complete.

---

## STEP 1 — READ THESE FILES FIRST

Read all of these in one go (parallel reads):
- `CLAUDE.md`
- `.claude/rules/hpc.md`
- `.claude/rules/migrations.md`
- `.claude/rules/school-setup.md`
- `.claude/rules/smart-timetable.md`
- `.claude/rules/student-fee.md`
- `routes/web.php` (first 80 lines)
- `routes/tenant.php` (first 80 lines)
- `Modules/Prime/routes/web.php`
- `Modules/Hpc/routes/web.php`
- `Modules/SchoolSetup/routes/web.php`

---

## STEP 2 — EXPLORE THESE FOLDERS

Run ls/glob on each of these:

```
Modules/                                              ← all module names
Modules/Prime/app/Http/Controllers/
Modules/Prime/app/Models/
Modules/Prime/resources/views/
Modules/Prime/database/migrations/
Modules/Billing/app/Http/Controllers/
Modules/Billing/app/Models/
Modules/GlobalMaster/app/Http/Controllers/
Modules/GlobalMaster/app/Models/
Modules/SystemConfig/app/Http/Controllers/
Modules/Hpc/app/Http/Controllers/
Modules/Hpc/app/Models/
Modules/Hpc/resources/views/
Modules/SchoolSetup/app/Http/Controllers/
Modules/SchoolSetup/app/Models/
Modules/SchoolSetup/resources/views/
Modules/SmartTimetable/app/Http/Controllers/
Modules/SmartTimetable/app/Models/
Modules/Transport/app/Http/Controllers/
Modules/Transport/app/Models/
Modules/StudentFee/app/Http/Controllers/
Modules/StudentProfile/app/Http/Controllers/
Modules/Syllabus/app/Http/Controllers/
Modules/QuestionBank/app/Http/Controllers/
Modules/LmsExam/app/Http/Controllers/
Modules/LmsQuiz/app/Http/Controllers/
Modules/Library/app/Http/Controllers/
Modules/Complaint/app/Http/Controllers/
Modules/Notification/app/Http/Controllers/
Modules/Vendor/app/Http/Controllers/
database/migrations/
database/migrations/tenant/
resources/views/components/
resources/views/components/backend/
resources/views/components/prime/
resources/views/components/frontend/
```

---

## STEP 3 — CREATE project_docs/ FOLDER WITH THESE 11 FILES

Create folder `project_docs/` at the project root. Then write each file below exactly as described.

---

### FILE 1: `project_docs/01-project-overview.md`

Write a complete overview covering:

**Project Identity**
- Name: Prime-AI ERP + LMS + LXP
- Purpose: Multi-Tenant SaaS Academic Intelligence Platform, Indian K-12 Schools
- Tech: PHP 8.2+ / Laravel 12.0 / MySQL 8.x / stancl/tenancy v3.9 / nwidart/laravel-modules v12.0

**Two Sides of the Application**
- PRIME side = Application owner/super-admin (one instance, central)
- TENANT side = Each school (separate database + separate subdomain)
- Multi-tenancy: stancl/tenancy creates a new DB and domain per school automatically

**3-Layer Database Architecture**

| Layer | Database | Tables | Prefix |
|-------|----------|--------|--------|
| Global | global_db | ~12 | glb_* |
| Prime | prime_db | ~27 | prm_*, bil_*, sys_* |
| Tenant | tenant_db | ~368 | tt_*, std_*, sch_*, fin_*, hpc_*, etc. |

**Table Prefix Convention (full list)**
```
sys_  → System config
glb_  → Global master data
prm_  → Prime admin tables
bil_  → Billing tables
sch_  → School setup (classes, teachers, rooms)
tt_   → Timetable
std_  → Student data
slb_  → Syllabus
qns_  → Questions / Question bank
rec_  → Recommendations
bok_  → Books / Library
cmp_  → Complaints
ntf_  → Notifications
tpt_  → Transport
vnd_  → Vendor
hpc_  → Holistic Progress Card
fin_  → Fees / Finance
exm_  → Exams
quz_  → Quiz
beh_  → Behaviour
hos_  → Hostel
mes_  → Mess
acc_  → Accounting
lib_  → Library
_jnt  → Junction/bridge tables (suffix)
_json → JSON column (suffix)
```

**27 Modules — Full List**

| Module | Side | Status | Table Prefix |
|--------|------|--------|--------------|
| Prime | Central | 100% | prm_* |
| GlobalMaster | Central | 100% | glb_* |
| SystemConfig | Central | 100% | sys_* |
| Billing | Central | 100% | bil_* |
| Documentation | Central | 100% | doc_* |
| SchoolSetup | Tenant | 100% | sch_* |
| SmartTimetable | Tenant | 95% | tt_* |
| Transport | Tenant | 90% | tpt_* |
| StudentProfile | Tenant | 100% | std_* |
| Syllabus | Tenant | 100% | slb_* |
| SyllabusBooks | Tenant | 100% | bok_* |
| QuestionBank | Tenant | 100% | qns_* |
| Notification | Tenant | 100% | ntf_* |
| Complaint | Tenant | 100% | cmp_* |
| Vendor | Tenant | 100% | vnd_* |
| Payment | Tenant | 100% | pay_* |
| Dashboard | Tenant | 100% | - |
| Scheduler | Tenant | 100% | sch_schedule_* |
| Hpc | Tenant | 95% | hpc_* |
| LmsExam | Tenant | 90% | exm_* |
| LmsQuiz | Tenant | 85% | quz_* |
| LmsHomework | Tenant | 80% | - |
| LmsQuests | Tenant | 80% | - |
| StudentFee | Tenant | 80% | fin_* |
| Recommendation | Tenant | 85% | rec_* |
| StudentPortal | Tenant | Pending | - |
| Library | Tenant | Pending | lib_* |

---

### FILE 2: `project_docs/02-prime-side-structure.md`

Write complete documentation of the PRIME (central) side:

**What is Prime Side**
Prime is the super-admin/owner panel of the entire SaaS platform. It manages:
- Tenant (school) creation and management
- Billing and subscriptions
- Global master data (countries, states, boards, plans)
- System configuration (menus, settings)
- User roles and permissions at platform level

**Prime Modules**
- Prime, GlobalMaster, SystemConfig, Billing, Documentation

**Folder Structure — Prime Module Example**
```
Modules/Prime/
├── app/
│   ├── Http/
│   │   └── Controllers/         ← All prime controllers (22 controllers)
│   ├── Models/                  ← All prime models (27 models)
│   └── Providers/
├── database/
│   └── migrations/              ← Prime-specific table migrations
├── resources/
│   └── views/                   ← All prime blade files
│       ├── academic-session/
│       ├── activity-log/
│       ├── auth/
│       ├── board/
│       ├── components/
│       │   └── layouts/
│       ├── core-configuration/
│       ├── dropdown/
│       ├── email/
│       ├── foundational-setup/
│       ├── language/
│       ├── menu/
│       ├── notification/
│       ├── prime/
│       ├── role-permission/
│       ├── sales-plan-and-module-mgmt/
│       ├── session-board-setup/
│       ├── setting/
│       ├── subscription-billing/
│       ├── tenant/
│       ├── tenant-group/
│       ├── tenant-management/
│       └── user/
├── routes/
│   ├── web.php                  ← Module-level prime routes
│   └── api.php
├── tests/
└── module.json
```

**Route Registration — Prime**
- Module routes defined in: `Modules/Prime/routes/web.php`
- All controllers also imported and routes re-registered in: `routes/web.php`
- `routes/web.php` is the MASTER central route file

**Migration Location — Prime**
- `Modules/Prime/database/migrations/` → prime/billing specific tables
- `database/migrations/` → core framework tables (cache, jobs, media, notifications)
- Run with: `php artisan migrate`

**Prime Controllers List (22)**
AcademicSessionController, ActivityLogController, BoardController,
DropdownController, DropdownMgmtController, DropdownNeedController,
EmailController, LanguageController, MenuController, NotificationController,
PrimeAuthController, PrimeController, RolePermissionController,
SalesPlanAndModuleMgmtController, SessionBoardSetupController, SettingController,
TenantController, TenantGroupController, TenantManagementController,
UserController, UserRolePrmController

**Billing Module Controllers (6)**
BillingCycleController, BillingManagementController, InvoicingAuditLogController,
InvoicingController, InvoicingPaymentController, SubscriptionController

---

### FILE 3: `project_docs/03-tenant-side-structure.md`

Write complete documentation of the TENANT (school) side:

**What is Tenant Side**
- Each school created by Prime = one tenant
- Gets its own database (isolated data)
- Gets its own subdomain (e.g., school1.primeai.in)
- stancl/tenancy handles DB switching and domain routing automatically
- All 22 tenant modules run inside tenant context

**Tenant Modules (22)**
SchoolSetup, SmartTimetable, Transport, StudentProfile, Syllabus, SyllabusBooks,
QuestionBank, Notification, Complaint, Vendor, Payment, Dashboard, Scheduler,
Hpc, LmsExam, LmsQuiz, LmsHomework, LmsQuests, StudentFee, Recommendation,
StudentPortal, Library

**Folder Structure — Tenant Module Example (Hpc)**
```
Modules/Hpc/
├── app/
│   ├── Http/
│   │   └── Controllers/         ← Tenant controllers (15 controllers)
│   ├── Models/                  ← Tenant models (26 models)
│   └── Providers/
├── database/
│   └── migrations/              ← EMPTY or not used — tenant migrations go elsewhere
├── resources/
│   └── views/                   ← Module blade files
│       ├── circular-goals/
│       ├── components/
│       │   └── layouts/
│       ├── hpc/
│       ├── hpc-parameters/
│       ├── hpc-performance-descriptor/
│       ├── hpc-template-parts/
│       ├── hpc-template-rubrics/
│       ├── hpc-template-sections/
│       ├── hpc-templates/
│       ├── hpc_form/
│       │   ├── partials/
│       │   └── pdf/              ← PDF blade files (DomPDF, inline styles only)
│       ├── knowledge-graph-validation/
│       ├── learning-activities/
│       ├── learning-outcomes/
│       ├── question-mapping/
│       ├── student-hpc-evaluation/
│       ├── student-list/
│       ├── syllabus-coverage/
│       └── topic-equivalency/
├── routes/
│   ├── web.php                  ← Module-level route definitions
│   └── api.php
└── module.json
```

**CRITICAL: Tenant Migration Location**
```
database/migrations/tenant/      ← ALL tenant table migrations go here
```
NEVER put tenant migrations inside the module folder.
Currently has 278 migration files covering all 22 tenant modules.

**Route Registration — Tenant**
- Module routes defined in: `Modules/<ModuleName>/routes/web.php`
- All tenant controllers imported and routes registered in: `routes/tenant.php`
- `routes/tenant.php` is the MASTER tenant route file

---

### FILE 4: `project_docs/04-migration-guide.md`

Write a complete migration guide:

**Two Migration Types**

| Type | File Location | Command |
|------|--------------|---------|
| Central/Prime | `database/migrations/` | `php artisan migrate` |
| Central/Prime module | `Modules/<ModuleName>/database/migrations/` | `php artisan migrate` |
| Tenant | `database/migrations/tenant/` | `php artisan tenants:migrate` |

**CRITICAL RULE: Tenant migrations ALWAYS go in `database/migrations/tenant/`. NEVER inside any module folder.**

**Create Migration Commands**
```bash
# Tenant migration (most common for feature work):
php artisan make:migration create_hpc_learning_outcomes_table --path=database/migrations/tenant

# Central migration:
php artisan make:migration create_prm_boards_table

# Run all tenant migrations (all schools):
php artisan tenants:migrate

# Run for specific tenant:
php artisan tenants:migrate --tenants=<tenant-uuid>

# Run central migrations:
php artisan migrate
```

**Required Columns on EVERY Table**
```php
$table->id();
$table->boolean('is_active')->default(true);
$table->unsignedBigInteger('created_by')->nullable();
$table->timestamps();       // created_at, updated_at
$table->softDeletes();      // deleted_at
```

**Column Naming Rules**
- Boolean columns → prefix `is_` or `has_` (e.g., `is_active`, `has_attachment`)
- JSON columns → suffix `_json` (e.g., `config_json`, `applies_to_days_json`)
- Junction tables → suffix `_jnt` (e.g., `hpc_circular_goal_competency_jnt`)
- Always index foreign keys
- Always index frequently queried columns

**Table Prefix by Module**
```
Prime/GlobalMaster  → prm_*, glb_*, sys_*, bil_*
SchoolSetup         → sch_*
SmartTimetable      → tt_*
StudentProfile      → std_*
StudentFee          → fin_*
Hpc                 → hpc_*
Transport           → tpt_*
Syllabus            → slb_*
QuestionBank        → qns_*
Notification        → ntf_*
Complaint           → cmp_*
Vendor              → vnd_*
Library             → lib_*
LmsExam             → exm_*
LmsQuiz             → quz_*
Recommendation      → rec_*
```

**NEVER modify existing migrations — always create new additive ones.**

**Migration File Naming**
```
YYYY_MM_DD_HHMMSS_create_<prefix>_<table>_table.php
Example: 2026_03_15_100000_create_hpc_new_feature_table.php
```

---

### FILE 5: `project_docs/05-model-guide.md`

Write a complete model guide:

**Model Location — Universal Rule**
```
Modules/<ModuleName>/app/Models/<ModelName>.php
```
This applies to ALL modules — both prime and tenant.

**Namespace Pattern**
```php
namespace Modules\<ModuleName>\Models;
// OR (both exist in this project):
namespace Modules\<ModuleName>\App\Models;
```

**Standard Model Template**
```php
<?php

namespace Modules\Hpc\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class LearningOutcomes extends Model
{
    use SoftDeletes;

    protected $table = 'hpc_learning_outcomes';

    protected $fillable = [
        'name',
        'description',
        'hpc_parameter_id',
        'is_active',
        'created_by',
    ];

    // Relationships
    public function parameter()
    {
        return $this->belongsTo(HpcParameters::class, 'hpc_parameter_id');
    }
}
```

**Rules**
- Always define `$table` explicitly with correct prefix
- Always define `$fillable` — never use `$guarded = []`
- Always `use SoftDeletes`
- Junction model names end in `Jnt` (e.g., `CircularGoalCompetencyJnt`)

**Create via artisan**
```bash
php artisan module:make-model <ModelName> <ModuleName>
# Example:
php artisan module:make-model LearningOutcomes Hpc
# Verify file created at: Modules/Hpc/app/Models/LearningOutcomes.php
```

**Model Counts per Module (for reference)**
```
SmartTimetable  → 86 models (largest)
SchoolSetup     → 42 models
Hpc             → 26 models
Library         → 35 models
Prime           → 27 models
Transport       → 36 models
StudentFee      → 23 models
QuestionBank    → 17 models
Syllabus        → 22 models
StudentProfile  → 14 models
Notification    → 14 models
```

---

### FILE 6: `project_docs/06-controller-guide.md`

Write a complete controller guide:

**Controller Location — Universal Rule**
```
Modules/<ModuleName>/app/Http/Controllers/<ControllerName>.php
```

**Namespace Pattern**
```php
namespace Modules\<ModuleName>\Http\Controllers;
```

**Base Class**
```php
use App\Http\Controllers\Controller;

class LearningOutcomesController extends Controller
```

**Standard CRUD Controller Template**
```php
<?php

namespace Modules\Hpc\Http\Controllers;

use App\Http\Controllers\Controller;
use Modules\Hpc\Models\LearningOutcomes;
use Illuminate\Http\Request;

class LearningOutcomesController extends Controller
{
    public function index()
    {
        $outcomes = LearningOutcomes::where('is_active', true)->get();
        return view('hpc::learning-outcomes.index', compact('outcomes'));
    }

    public function create()
    {
        return view('hpc::learning-outcomes.create');
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
        ]);
        $validated['created_by'] = auth()->id();
        LearningOutcomes::create($validated);
        return redirect()->route('hpc.learning-outcomes.index')
            ->with('success', 'Created successfully.');
    }

    public function edit(LearningOutcomes $learningOutcome)
    {
        return view('hpc::learning-outcomes.edit', compact('learningOutcome'));
    }

    public function update(Request $request, LearningOutcomes $learningOutcome)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
        ]);
        $learningOutcome->update($validated);
        return redirect()->route('hpc.learning-outcomes.index')
            ->with('success', 'Updated successfully.');
    }

    public function destroy(LearningOutcomes $learningOutcome)
    {
        $learningOutcome->delete(); // soft delete
        return redirect()->route('hpc.learning-outcomes.index')
            ->with('success', 'Deleted successfully.');
    }
}
```

**View Return Pattern**
```php
// Pattern: '<lowercase-modulename>::<folder>.<file>'
return view('hpc::learning-outcomes.index', compact('data'));
return view('schoolsetup::school-class.index', compact('classes'));
return view('prime::tenant.index', compact('tenants'));
```

**Create via artisan**
```bash
php artisan module:make-controller <ControllerName> <ModuleName>
# Example:
php artisan module:make-controller LearningOutcomesController Hpc
# File created at: Modules/Hpc/app/Http/Controllers/LearningOutcomesController.php
```

**Controller Counts per Module (for reference)**
```
SchoolSetup     → 40 controllers (largest)
SmartTimetable  → 28 controllers
Transport       → 31 controllers
GlobalMaster    → 15 controllers
Hpc             → 15 controllers
Prime           → 22 controllers
StudentFee      → 15 controllers
Notification    → 12 controllers
Library         → 26 controllers
```

---

### FILE 7: `project_docs/07-blade-views-guide.md`

Write a complete blade/views guide:

**Blade File Location — Universal Rule**
```
Modules/<ModuleName>/resources/views/<feature-folder>/<file>.blade.php
```

**Standard Folder Structure Inside a Module's views/**
```
Modules/Hpc/resources/views/
├── components/
│   └── layouts/                 ← module-specific layout
├── learning-outcomes/
│   ├── index.blade.php          ← list page
│   ├── create.blade.php         ← create form
│   └── edit.blade.php           ← edit form
├── hpc-parameters/
│   ├── index.blade.php
│   ├── create.blade.php
│   └── edit.blade.php
└── hpc_form/
    ├── pdf/                     ← PDF templates (DomPDF)
    │   ├── first_pdf.blade.php
    │   ├── second_pdf.blade.php
    │   └── third_pdf.blade.php
    └── partials/
```

**Blade View Namespace (used in controllers)**
```php
// Format: '<modulename-lowercase>::<folder>.<filename>'
'hpc::learning-outcomes.index'
'schoolsetup::school-class.index'
'smarttimetable::activity.index'
'prime::tenant.index'
'billing::billing-management.index'
```

**Shared Global Components (resources/views/components/)**
```
resources/views/components/
├── backend/                    ← Backend panel components
│   ├── card/
│   │   └── header.blade.php
│   ├── components/
│   │   ├── breadcrum.blade.php
│   │   ├── create-dropdown.blade.php
│   │   ├── filter.blade.php
│   │   ├── menu-item.blade.php
│   │   ├── pre-loader.blade.php
│   │   ├── search.blade.php
│   │   └── search-filter-option.blade.php
│   ├── email/
│   │   └── template.blade.php
│   ├── form/                   ← Reusable form elements
│   ├── layouts/                ← Main backend layout
│   ├── partials/
│   ├── tab/
│   └── table/
├── frontend/                   ← Frontend/student portal
│   ├── form/
│   └── layout/
└── prime/                      ← Prime admin specific
    ├── card/
    ├── components/
    ├── form/
    ├── layouts/
    ├── partials/
    └── table/
```

**How to Use Shared Components in Blade**
```blade
{{-- Backend layout --}}
<x-backend.layouts.app>
    {{-- content --}}
</x-backend.layouts.app>

{{-- Prime layout --}}
<x-prime.layouts.app>
    {{-- content --}}
</x-prime.layouts.app>

{{-- Breadcrumb --}}
<x-backend.components.breadcrum :items="$breadcrumbs" />

{{-- Search --}}
<x-backend.components.search />

{{-- Filter --}}
<x-backend.components.filter />
```

**PDF Blade Files — Special Rules (HPC Module Decision D13)**
```
RULES FOR ALL PDF TEMPLATES:
✗ NO Bootstrap classes — use inline styles only
✗ NO flexbox or CSS grid — use <table> for ALL layouts
✗ NO JavaScript
✗ NO Blade components (<x-...>)
✓ One self-contained *_pdf.blade.php file per template
✓ Contains $css array at top
✓ Contains helper closures
✓ Full <!DOCTYPE html> document inside

Current PDF templates:
- first_pdf.blade.php  → Template 1, Grades 3-5
- second_pdf.blade.php → Template 2, Grades 3-5 variant
- third_pdf.blade.php  → Template 3, Grades 6-8
```

**Emoji Assets in HPC**
```blade
{{-- Always use local public folder, not URLs --}}
<img src="{{ asset('emoji/happy.png') }}" />
<img src="{{ asset('emoji/no.png') }}" />
```

---

### FILE 8: `project_docs/08-routes-guide.md`

Write a complete routing guide:

**Two Master Route Files**

| File | Purpose | Controller Namespace |
|------|---------|---------------------|
| `routes/web.php` | ALL prime/central routes | Modules\Prime\*, Modules\Billing\*, Modules\GlobalMaster\*, Modules\SystemConfig\* |
| `routes/tenant.php` | ALL tenant/school routes | Modules\SchoolSetup\*, Modules\Hpc\*, Modules\SmartTimetable\*, etc. |

**Prime Route Pattern (routes/web.php)**
```php
use Modules\Hpc\Http\Controllers\LearningOutcomesController;

Route::middleware(['auth', 'verified'])->group(function () {
    Route::resource('learning-outcomes', LearningOutcomesController::class)
        ->names('hpc.learning-outcomes');
});
```

**Tenant Route Pattern (routes/tenant.php)**
```php
use Modules\Hpc\Http\Controllers\LearningOutcomesController;

Route::middleware(['auth', 'verified'])->group(function () {
    Route::resource('learning-outcomes', LearningOutcomesController::class)
        ->names('hpc.learning-outcomes');
});
```

**Module-Level Route File Pattern**
```php
// Modules/Hpc/routes/web.php
<?php
use Illuminate\Support\Facades\Route;
use Modules\Hpc\Http\Controllers\HpcController;

Route::middleware(['auth', 'verified'])->group(function () {
    Route::resource('hpcs', HpcController::class)->names('hpc');
});
```

**Named Routes Convention**
```php
// Format: <module>.<feature>.<action>
Route::resource('learning-outcomes', LearningOutcomesController::class)
    ->names('hpc.learning-outcomes');
// Generates: hpc.learning-outcomes.index, .create, .store, .show, .edit, .update, .destroy

// Custom named routes:
Route::get('/hpc/report', [HpcController::class, 'report'])->name('hpc.report');
```

**ABSOLUTE RULE**
```
Prime controllers  →  routes/web.php     ONLY
Tenant controllers →  routes/tenant.php  ONLY
NEVER cross-register routes between these two files
```

---

### FILE 9: `project_docs/09-artisan-commands-reference.md`

Write a complete artisan commands reference:

**nwidart/laravel-modules v12 Commands**

```bash
# ─────────────────────────────────────────
# MODULE SCAFFOLD COMMANDS
# ─────────────────────────────────────────

# Create a new module
php artisan module:make <ModuleName>
# Example: php artisan module:make Attendance

# Create multiple modules at once
php artisan module:make ModuleA ModuleB ModuleC

# Create controller inside a module
php artisan module:make-controller <ControllerName> <ModuleName>
# Example: php artisan module:make-controller AttendanceController Attendance
# Result: Modules/Attendance/app/Http/Controllers/AttendanceController.php

# Create model inside a module
php artisan module:make-model <ModelName> <ModuleName>
# Example: php artisan module:make-model Attendance Attendance
# Result: Modules/Attendance/app/Models/Attendance.php

# Create migration inside a module (for prime only)
php artisan module:make-migration <MigrationName> <ModuleName>
# Example: php artisan module:make-migration create_prm_boards_table Prime

# Create form request
php artisan module:make-request <RequestName> <ModuleName>
# Example: php artisan module:make-request StoreAttendanceRequest Attendance

# Create resource (API resource)
php artisan module:make-resource <ResourceName> <ModuleName>

# Create seeder
php artisan module:make-seeder <SeederName> <ModuleName>

# Create factory
php artisan module:make-factory <FactoryName> <ModuleName>

# Create policy
php artisan module:make-policy <PolicyName> <ModuleName>

# Create middleware
php artisan module:make-middleware <MiddlewareName> <ModuleName>

# Create command
php artisan module:make-command <CommandName> <ModuleName>

# Create event
php artisan module:make-event <EventName> <ModuleName>

# Create listener
php artisan module:make-listener <ListenerName> <ModuleName>

# Create job
php artisan module:make-job <JobName> <ModuleName>

# Create provider
php artisan module:make-provider <ProviderName> <ModuleName>

# Create test
php artisan module:make-test <TestName> <ModuleName>

# ─────────────────────────────────────────
# MODULE MANAGEMENT COMMANDS
# ─────────────────────────────────────────

# List all modules with status
php artisan module:list

# Enable a module
php artisan module:enable <ModuleName>

# Disable a module
php artisan module:disable <ModuleName>

# ─────────────────────────────────────────
# MIGRATION COMMANDS
# ─────────────────────────────────────────

# Create tenant migration (MOST COMMON):
php artisan make:migration create_hpc_new_table_table --path=database/migrations/tenant

# Create central migration:
php artisan make:migration create_prm_new_table_table

# Run all central migrations:
php artisan migrate

# Run all tenant migrations (all schools):
php artisan tenants:migrate

# Run tenant migrations for specific school:
php artisan tenants:migrate --tenants=<tenant-uuid>

# Rollback tenant migrations:
php artisan tenants:migrate-rollback

# ─────────────────────────────────────────
# CACHE & OPTIMIZATION COMMANDS
# ─────────────────────────────────────────

php artisan optimize:clear          # Clear all caches
php artisan config:clear            # Clear config cache
php artisan route:clear             # Clear route cache
php artisan view:clear              # Clear compiled views
php artisan cache:clear             # Clear application cache

# ─────────────────────────────────────────
# TESTING COMMANDS (Pest 4.x)
# ─────────────────────────────────────────

./vendor/bin/pest                           # All tests
./vendor/bin/pest tests/Unit/               # Unit tests only
./vendor/bin/pest --filter="keyword"        # Filter by keyword
./vendor/bin/pest Modules/Hpc/              # Module tests only
```

---

### FILE 10: `project_docs/10-new-feature-checklist.md`

Write a complete step-by-step checklist:

```markdown
# New Feature Checklist

## BEFORE WRITING ANY CODE — Ask These Questions

1. Is this a PRIME feature (platform admin) or TENANT feature (school)?
2. Does the module already exist or do I need to create it?
3. What table prefix should this feature use?
4. Does the migration go in tenant/ or central/?
5. Does the route go in routes/web.php or routes/tenant.php?

---

## PRIME FEATURE — Step by Step

### Step 1: Module
```bash
# Only if module does not exist:
php artisan module:make <ModuleName>
```

### Step 2: Migration
```bash
# Central migration:
php artisan make:migration create_<prefix>_<table>_table
# Run:
php artisan migrate
```

### Step 3: Model
```bash
php artisan module:make-model <ModelName> <ModuleName>
```
Then edit the model:
- Set `protected $table = '<prefix>_<table>';`
- Set `protected $fillable = [...]`
- Add `use SoftDeletes;`
- Verify file at: `Modules/<ModuleName>/app/Models/`

### Step 4: Controller
```bash
php artisan module:make-controller <ControllerName> <ModuleName>
```
Then implement: `index()`, `create()`, `store()`, `edit()`, `update()`, `destroy()`
Return views as: `'<modulename>::<folder>.<file>'`

### Step 5: Views
Create in: `Modules/<ModuleName>/resources/views/<feature>/`
Files: `index.blade.php`, `create.blade.php`, `edit.blade.php`
Use shared components: `<x-prime.layouts.app>` or `<x-backend.layouts.app>`

### Step 6: Routes
Open `routes/web.php` → add use statement → add Route::resource()

---

## TENANT FEATURE — Step by Step

### Step 1: Module
```bash
# Only if module does not exist:
php artisan module:make <ModuleName>
```

### Step 2: Migration ← MOST IMPORTANT STEP
```bash
# Tenant migration ALWAYS goes here:
php artisan make:migration create_<prefix>_<table>_table --path=database/migrations/tenant
# Run:
php artisan tenants:migrate
```

### Step 3: Model
```bash
php artisan module:make-model <ModelName> <ModuleName>
```
Then edit the model:
- Set `protected $table = '<tenant-prefix>_<table>';`
- Set `protected $fillable = [...]`
- Add `use SoftDeletes;`
- Verify file at: `Modules/<ModuleName>/app/Models/`

### Step 4: Controller
```bash
php artisan module:make-controller <ControllerName> <ModuleName>
```
Implement CRUD methods, return views as: `'<modulename>::<folder>.<file>'`

### Step 5: Views
Create in: `Modules/<ModuleName>/resources/views/<feature>/`
Files: `index.blade.php`, `create.blade.php`, `edit.blade.php`
Use: `<x-backend.layouts.app>` for standard pages

### Step 6: Routes
Open `routes/tenant.php` → add use statement → add Route::resource()

---

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
Controllers (15): AcademicSessionController, ActivityLogController, CityController, CountryController, DistrictController, DropdownController, GeographySetupController, GlobalMasterController, LanguageController, ModuleController, NotificationController, OrganizationController, PlanController, SessionBoardSetupController, StateController
Models (12): ActivityLog, Board, City, Country, District, Dropdown, DropdownNeed, Language, Media, Module, Plan, State

Prime [PRIME] — Central
Controllers (22): AcademicSessionController, ActivityLogController, BoardController, DropdownController, DropdownMgmtController, DropdownNeedController, EmailController, LanguageController, MenuController, NotificationController, PrimeAuthController, PrimeController, RolePermissionController, SalesPlanAndModuleMgmtController, SessionBoardSetupController, SettingController, TenantController, TenantGroupController, TenantManagementController, UserController, UserRolePrmController
Models (27): AcademicSession, ActivityLog, Board, Domain, Dropdown, DropdownMgmtModel, DropdownNeed, DropdownNeedDropdown, DropdownNeedTableJnt, Language, Media, Menu, MenuModule, Permission, Role, Setting, Tenant, TenantGroup, TenantInvoice, TenantInvoiceModule, TenantInvoicingAuditLog, TenantInvoicingPayment, TenantPlan, TenantPlanBillingSchedule, TenantPlanModule, TenantPlanRate, User

SystemConfig [PRIME] — Central
Controllers (3): MenuController, SettingController, SystemConfigController
Models (3): Menu, Setting, Translation

**TENANT MODULES:**

Complaint [TENANT]
Controllers (8): AiInsightController, ComplaintActionController, ComplaintCategoryController, ComplaintController, ComplaintDashboardController, ComplaintReportController, DepartmentSlaController, MedicalCheckController
Models (6): AiInsight, Complaint, ComplaintAction, ComplaintCategory, DepartmentSla, MedicalCheck

Dashboard [TENANT]
Controllers (1): DashboardController
Models: none

Hpc [TENANT] — 95%
Controllers (15): CircularGoalsController, HpcController, HpcParametersController, HpcPerformanceDescriptorController, HpcTemplatePartsController, HpcTemplateRubricsController, HpcTemplateSectionsController, HpcTemplatesController, KnowledgeGraphValidationController, LearningActivitiesController, LearningOutcomesController, QuestionMappingController, StudentHpcEvaluationController, SyllabusCoverageSnapshotController, TopicEquivalencyController
Models (26): CircularGoalCompetencyJnt, CircularGoals, HpcLevels, HpcParameters, HpcPerformanceDescriptor, HpcReport, HpcReportItem, HpcReportTable, HpcTemplateParts, HpcTemplatePartsItems, HpcTemplateRubricItems, HpcTemplateRubrics, HpcTemplateSectionItems, HpcTemplateSectionTable, HpcTemplateSections, HpcTemplates, KnowledgeGraphValidation, LearningActivities, LearningActivityType, LearningOutcomes, OutcomesEntityJnt, OutcomesQuestionJnt, StudentHpcEvaluation, StudentHpcSnapshot, SyllabusCoverageSnapshot, TopicEquivalency

Library [TENANT] — Pending
Controllers (26): LibAuthorController, LibBookConditionController, LibBookCopyController, LibBookMasterController, LibCategoryController, LibCirculationReportController, LibDigitalResourceController, LibDigitalResourceTagController, LibFineController, LibFineReportController, LibFineSlabConfigController, LibFineSlabDetailController, LibGenreController, LibInventoryAuditController, LibInventoryAuditDetailController, LibKeywordController, LibMemberController, LibMembershipTypeController, LibPublisherController, LibReportPrintController, LibReservationController, LibResourceTypeController, LibShelfLocationController, LibTransactionController, LibraryController, MasterDashboardController
Models (35): LibAuthor, LibBookAuthorJnt, LibBookCategoryJnt, LibBookCondition, LibBookConditionJnt, LibBookCopy, LibBookGenreJnt, LibBookKeywordJnt, LibBookMaster, LibBookPopularityTrend, LibBookSubjectJnt, LibCategory, LibCollectionHealthMetric, LibCurricularAlignment, LibDigitalResource, LibDigitalResourceTag, LibEngagementEvent, LibFine, LibFinePayment, LibFineSlabConfig, LibFineSlabDetail, LibGenre, LibInventoryAudit, LibInventoryAuditDetail, LibKeyword, LibMember, LibMembershipType, LibPredictiveAnalytic, LibPublisher, LibReadingBehaviorAnalytics, LibReservation, LibResourceType, LibShelfLocation, LibTransaction, LibTransactionHistory

LmsExam [TENANT] — 90%
Controllers (11): ExamAllocationController, ExamBlueprintController, ExamPaperController, ExamPaperSetController, ExamScopeController, ExamStatusEventController, ExamStudentGroupController, ExamStudentGroupMemberController, ExamTypeController, LmsExamController, PaperSetQuestionController
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
Controllers (12): ChannelMasterController, DeliveryQueueController, NotificationManageController, NotificationTargetController, NotificationTemplateController, NotificationThreadController, NotificationThreadMemberController, ProviderMasterController, ResolvedRecipientController, TargetGroupController, TemplateController, UserPreferenceController
Models (14): ChannelMaster, DeliveryQueue, Notification, NotificationChannel, NotificationDeliveryLog, NotificationTarget, NotificationTemplate, NotificationThread, NotificationThreadMember, ProviderMaster, ResolvedRecipient, TargetGroup, UserDevice, UserPreference

Payment [TENANT]
Controllers (4): PaymentCallbackController, PaymentController, PaymentGatewayController
Models (5): Payment, PaymentGateway, PaymentHistory, PaymentRefund, PaymentWebhook

QuestionBank [TENANT]
Controllers (7): AIQuestionGeneratorController, QuestionBankController, QuestionMediaStoreController, QuestionStatisticController, QuestionTagController, QuestionUsageTypeController, QuestionVersionController
Models (17): QuestionBank, QuestionMedia, QuestionMediaStore, QuestionOption, QuestionPerformanceCategory, QuestionPerformanceCategoryJnt, QuestionQuestionTag, QuestionQuestionTagJnt, QuestionReviewLog, QuestionStatistic, QuestionTag, QuestionTopic, QuestionTopicJnt, QuestionUsageLog, QuestionUsageType, QuestionVersion

Recommendation [TENANT] — 85%
Controllers (10): DynamicMaterialTypeController, DynamicPurposeController, MaterialBundleController, RecAssessmentTypeController, RecTriggerEventController, RecommendationController, RecommendationMaterialController, RecommendationModeController, RecommendationRuleController, StudentRecommendationController
Models (11): BundleMaterialJnt, DynamicMaterialType, DynamicPurpose, MaterialBundle, PerformanceSnapshot, RecAssessmentType, RecTriggerEvent, RecommendationMaterial, RecommendationMode, RecommendationRule, StudentRecommendation

Scheduler [TENANT]
Controllers (1): SchedulerController
Models (2): Schedule, ScheduleRun

SchoolSetup [TENANT] — 100% (Core Infrastructure)
Controllers (40): AttendanceTypeController, BuildingController, ClassGroupController, ClassSubjectGroupController, ClassSubjectManagementController, DepartmentController, DesignationController, DisableReasonController, EmployeeProfileController, EntityGroupController, EntityGroupMemberController, InfrasetupController, LeaveConfigController, LeaveTypeController, OrganizationAcademicSessionController, OrganizationController, OrganizationGroupController, RolePermissionController, RoomController, RoomTypeController, SchCategoryController, SchoolClassController, SchoolSetupController, SectionController, StudyFormatController, SubjectClassMappingController, SubjectController, SubjectGroupController, SubjectGroupSubjectController, SubjectStudyFormatController, SubjectTypeController, TeacherController, UserController, UserRolePrmController
Models (42): AttendanceType, Building, ClassSection, Department, Designation, DisableReason, Employee, EmployeeProfile, EntityGroup, EntityGroupMember, LeaveConfig, LeaveType, Organization, OrganizationAcademicSession, OrganizationGroup, OrganizationPlan, OrganizationPlanRate, Permission, Role, Room, RoomType, SchCategory, SchClassGroupsJnt, SchoolClass, Section, StudyFormat, Subject, SubjectGroup, SubjectGroupSubject, SubjectStudyFormat, SubjectTeacher, SubjectType, Teacher, TeacherCapability, TeacherProfile, User

SmartTimetable [TENANT] — 95%
Controllers (28): ActivityController, AcademicTermController, ClassSubjectSubgroupController, ConstraintController, ConstraintTypeController, DayTypeController, ParallelGroupController, PeriodController, PeriodSetController, PeriodSetPeriodController, PeriodTypeController, RequirementConsolidationController, RoomUnavailableController, SchoolDayController, SchoolShiftController, SchoolTimingProfileController, SlotRequirementController, SmartTimetableController, TeacherAssignmentRoleController, TeacherAvailabilityController, TeacherUnavailableController, TimetableController, TimetableTypeController, TimingProfileController, TtConfigController, TtGenerationStrategyController, WorkingDayController
Models (86): (86 models covering: activities, constraints, periods, timetable cells, parallel groups, generation runs, ML models, approval workflows, conflict detection, optimization, substitution, analytics)

StudentFee [TENANT] — 80%
Controllers (15): FeeConcessionTypeController, FeeFineRuleController, FeeFineTransactionController, FeeGroupMasterController, FeeHeadMasterController, FeeInstallmentController, FeeInvoiceController, FeeScholarshipApplicationController, FeeScholarshipController, FeeStructureMasterController, FeeStudentAssignmentController, FeeStudentConcessionController, FeeTransactionController, StudentFeeController, StudentFeeManagementController
Models (23): FeeConcessionType, FeeDefaulterHistory, FeeFineRule, FeeFineTransaction, FeeGroupHeadsJnt, FeeGroupMaster, FeeHeadMaster, FeeInstallment, FeeInvoice, FeeNameRemovalLog, FeePaymentGatewayLog, FeePaymentReconciliation, FeeReceipt, FeeRefund, FeeScholarship, FeeScholarshipApplication, FeeScholarshipApprovalHistory, FeeStructureDetail, FeeStructureMaster, FeeStudentAssignment, FeeStudentConcession, FeeTransaction, FeeTransactionDetail

StudentPortal [TENANT] — Pending
Controllers (3): NotificationController, StudentPortalComplaintController, StudentPortalController
Models: none

StudentProfile [TENANT] — 100%
Controllers (5): AttendanceController, MedicalIncidentController, StudentController, StudentProfileController, StudentReportController
Models (14): Guardian, MedicalIncident, PreviousEducation, Student, StudentAcademicSession, StudentAddress, StudentAttendance, StudentAttendanceCorrection, StudentDetail, StudentDocument, StudentGuardianJnt, StudentHealthProfile, StudentProfile, VaccinationRecord

Syllabus [TENANT] — 100%
Controllers (15): BloomTaxonomyController, CognitiveSkillController, CompetencieController, CompetencyTypeController, ComplexityLevelController, GradeDivisionController, LessonController, PerformanceCategoryController, QuestionTypeController, QuestionTypeSpecificityController, SyllabusController, SyllabusScheduleController, TopicCompetencyController, TopicController, TopicLevelTypeController
Models (22): BloomTaxonomy, Book, CognitiveSkill, Competencie, CompetencyType, ComplexityLevel, GradeDivisionMaster, Lesson, PerformanceCategory, QuestionType, StudyMaterial, StudyMaterialType, SyllabusSchedule, Topic, TopicCompetency, TopicDependencies, TopicLevelType

SyllabusBooks [TENANT]
Controllers (4): AuthorController, BookController, BookTopicMappingController, SyllabusBooksController
Models (6): BokBook, BookAuthorJnt, BookAuthors, BookClassSubject, BookTopicMapping, MediaFiles

Transport [TENANT] — 90%
Controllers (31): AttendanceDeviceController, DriverAttendanceController, DriverHelperController, DriverRouteVehicleController, FeeCollectionController, FeeMasterController, FineMasterController, LiveTripController, NewTripController, PickupPointController, PickupPointRouteController, RouteController, RouteSchedulerController, ShiftController, StaffMgmtController, StudentAllocationController, StudentAttendanceController, StudentBoardingController, StudentRouteFeesController, TptDailyVehicleInspectionController, TptStudentFineDetailController, TptVehicleFuelController, TptVehicleMaintenanceController, TptVehicleServiceRequestController, TransportDashboardController, TransportMasterController, TransportReportController, TripController, TripMgmtController, VehicleController, VehicleMgmtController
Models (36): AttendanceDevice, DriverHelper, DriverRouteVehicleJnt, PickupPoint, PickupPointRoute, Route, Shift, StudentBoardingLog, StudentPayLog, TptDailyVehicleInspection, TptDriverAttendance, TptFeeCollection, TptFeeMaster, TptFineMaster, TptGpsTripLog, TptLiveTrip, TptRouteSchedulerJnt, TptStudentAllocationJnt, TptStudentFeeCollection, TptStudentFineDetail, TptTrip, TptTripIncidents, TptTripStopDetail, TptVehicleFuel, TptVehicleMaintenance, TptVehicleServiceRequest, Vehicle

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
