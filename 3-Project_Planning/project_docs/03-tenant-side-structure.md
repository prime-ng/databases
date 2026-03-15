# Tenant (School) Side — Structure Guide

## What is Tenant Side

- Each school created by Prime = one tenant
- Gets its own database (isolated data)
- Gets its own subdomain (e.g., `school1.primeai.in`)
- stancl/tenancy handles DB switching and domain routing automatically
- All 22 tenant modules run inside tenant context

## Tenant Modules (22)

| Module | Controllers | Models | Table Prefix |
|--------|-------------|--------|--------------|
| SchoolSetup | 34 | 42 | sch_* |
| SmartTimetable | 27 | 86 | tt_* |
| Transport | 31 | 36 | tpt_* |
| StudentProfile | 5 | 14 | std_* |
| Syllabus | 15 | 22 | slb_* |
| SyllabusBooks | 4 | 6 | bok_* |
| QuestionBank | 7 | 17 | qns_* |
| Notification | 12 | 14 | ntf_* |
| Complaint | 8 | 6 | cmp_* |
| Vendor | 7 | 8 | vnd_* |
| Payment | 4 | 5 | pay_* |
| Dashboard | 1 | 0 | - |
| Scheduler | 1 | 2 | - |
| Hpc | 15 | 26 | hpc_* |
| LmsExam | 11 | 11 | exm_* |
| LmsQuiz | 5 | 6 | quz_* |
| LmsHomework | 5 | 5 | - |
| LmsQuests | 4 | 4 | - |
| StudentFee | 15 | 23 | fin_* |
| Recommendation | 10 | 11 | rec_* |
| StudentPortal | 3 | 0 | - |
| Library | 26 | 35 | lib_* |

## Folder Structure — Tenant Module Example (Hpc)

```
Modules/Hpc/
├── app/
│   ├── Http/
│   │   ├── Controllers/         <- 15 controllers
│   │   └── Requests/            <- 14 FormRequests
│   ├── Models/                  <- 26 models
│   ├── Services/                <- 1 service (HpcReportService)
│   └── Providers/
├── database/
│   ├── migrations/              <- EMPTY (tenant migrations go in database/migrations/tenant/)
│   └── seeders/
├── resources/
│   └── views/                   <- 229 blade files across 19 folders
│       ├── circular-goals/
│       ├── components/layouts/
│       ├── hpc/
│       ├── hpc_form/
│       │   ├── partials/
│       │   └── pdf/             <- DomPDF templates (inline styles only)
│       │       ├── first_pdf.blade.php
│       │       ├── second_pdf.blade.php
│       │       ├── third_pdf.blade.php
│       │       └── fourth_pdf.blade.php
│       ├── hpc-parameters/
│       ├── hpc-performance-descriptor/
│       ├── hpc-template-parts/
│       ├── hpc-template-rubrics/
│       ├── hpc-template-sections/
│       ├── hpc-templates/
│       ├── knowledge-graph-validation/
│       ├── learning-activities/
│       ├── learning-outcomes/
│       ├── question-mapping/
│       ├── student-hpc-evaluation/
│       ├── student-list/
│       ├── syllabus-coverage/
│       └── topic-equivalency/
├── routes/
│   ├── web.php                  <- Module-level route definitions
│   └── api.php
└── module.json
```

## CRITICAL: Tenant Migration Location

```
database/migrations/tenant/      <- ALL tenant table migrations go here (278 files)
```

**NEVER put tenant migrations inside the module folder.** The module's `database/migrations/` should remain empty for tenant modules.

Run with: `php artisan tenants:migrate`

## Route Registration — Tenant

- Module routes defined in: `Modules/<ModuleName>/routes/web.php`
- All tenant controllers imported and routes registered in: `routes/tenant.php` (2715 lines, 1328 Route:: calls)
- `routes/tenant.php` is the MASTER tenant route file
- Middleware: `InitializeTenancyByDomain`, `PreventAccessFromCentralDomains`

## Module Route Group Pattern (from SchoolSetup/routes/web.php)

```php
Route::middleware(['web', InitializeTenancyByDomain::class, PreventAccessFromCentralDomains::class])
    ->group(function () {
        Route::middleware(['auth', 'verified'])
            ->prefix('school-setup')
            ->name('school-setup.')
            ->group(function () {
                Route::resource('building', BuildingController::class);
                Route::get('/building/trash/view', [BuildingController::class, 'trashedBuilding']);
                Route::get('/building/{id}/restore', [BuildingController::class, 'restore']);
                Route::delete('/building/{id}/force-delete', [BuildingController::class, 'forceDelete']);
                Route::post('/building/{building}/toggle-status', [BuildingController::class, 'toggleStatus']);
            });
    });
```

## Tenancy Middleware Stack

```php
// Applied automatically to all tenant routes:
InitializeTenancyByDomain::class    // Switches DB to tenant's database
PreventAccessFromCentralDomains::class  // Blocks central domain from accessing tenant routes
EnsureTenantIsActive::class         // Checks tenant is not suspended
// Should be applied (but currently missing on most modules):
EnsureTenantHasModule::class        // Checks tenant's plan includes this module
```
