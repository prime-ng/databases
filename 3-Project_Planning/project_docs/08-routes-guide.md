# Routes Guide

## Two Master Route Files

| File | Purpose | Who Uses It |
|------|---------|-------------|
| `routes/web.php` | ALL prime/central routes | Prime, GlobalMaster, Billing, SystemConfig, Documentation |
| `routes/tenant.php` | ALL tenant/school routes | SchoolSetup, Hpc, SmartTimetable, Transport, and all other tenant modules |

## ABSOLUTE RULE

```
Prime controllers  ->  routes/web.php     ONLY
Tenant controllers ->  routes/tenant.php  ONLY
NEVER cross-register routes between these two files
```

## Prime Route Pattern (routes/web.php)

```php
use Modules\Prime\Http\Controllers\TenantController;

Route::domain(env('APP_DOMAIN'))->name("central-127.0.0.1.")->group(function () {
    Route::middleware(['auth', 'verified'])->prefix('prime')->name('prime.')->group(function () {
        Route::resource('tenant', TenantController::class);
        Route::get('/tenant/trash/view', [TenantController::class, 'trashedTenant'])->name('tenant.trashed');
        Route::get('/tenant/{id}/restore', [TenantController::class, 'restore'])->name('tenant.restore');
        Route::delete('/tenant/{id}/force-delete', [TenantController::class, 'forceDelete'])->name('tenant.forceDelete');
        Route::post('/tenant/{tenant}/toggle-status', [TenantController::class, 'toggleStatus'])->name('tenant.toggleStatus');
    });
});
```

## Tenant Route Pattern (routes/tenant.php)

```php
use Modules\Hpc\Http\Controllers\LearningOutcomesController;

Route::middleware([InitializeTenancyByDomain::class, PreventAccessFromCentralDomains::class])
    ->group(function () {
        Route::middleware(['auth', 'verified'])->prefix('hpc')->name('hpc.')->group(function () {
            Route::resource('learning-outcomes', LearningOutcomesController::class);
            Route::get('/learning-outcomes/trash/view', [LearningOutcomesController::class, 'trashed'])
                ->name('learning-outcomes.trashed');
            Route::get('/learning-outcomes/{id}/restore', [LearningOutcomesController::class, 'restore'])
                ->name('learning-outcomes.restore');
            Route::delete('/learning-outcomes/{id}/force-delete', [LearningOutcomesController::class, 'forceDelete'])
                ->name('learning-outcomes.forceDelete');
            Route::post('/learning-outcomes/{id}/toggle-status', [LearningOutcomesController::class, 'toggleStatus'])
                ->name('learning-outcomes.toggleStatus');
        });
    });
```

## Module-Level Route File Pattern

```php
// Modules/Hpc/routes/web.php
<?php
use Illuminate\Support\Facades\Route;
use Modules\Hpc\Http\Controllers\HpcController;

Route::middleware(['auth', 'verified'])->group(function () {
    Route::resource('hpcs', HpcController::class)->names('hpc');
});
```

## Named Routes Convention

```php
// Format: <module-prefix>.<feature>.<action>
Route::resource('learning-outcomes', LearningOutcomesController::class)
    ->names('hpc.learning-outcomes');
// Generates:
//   hpc.learning-outcomes.index
//   hpc.learning-outcomes.create
//   hpc.learning-outcomes.store
//   hpc.learning-outcomes.show
//   hpc.learning-outcomes.edit
//   hpc.learning-outcomes.update
//   hpc.learning-outcomes.destroy
```

## Standard Route Group for a New Tenant Feature

```php
// In routes/tenant.php, add inside the main middleware group:

// 1. Import the controller at the top of the file
use Modules\NewModule\Http\Controllers\NewFeatureController;

// 2. Add the route group
Route::middleware(['auth', 'verified'])->prefix('new-module')->name('new-module.')->group(function () {
    // Resource routes
    Route::resource('new-feature', NewFeatureController::class);

    // Trash/Restore routes (ALWAYS register BEFORE Route::resource to avoid conflicts)
    Route::get('/new-feature/trash/view', [NewFeatureController::class, 'trashed'])
        ->name('new-feature.trashed');
    Route::get('/new-feature/{id}/restore', [NewFeatureController::class, 'restore'])
        ->name('new-feature.restore');
    Route::delete('/new-feature/{id}/force-delete', [NewFeatureController::class, 'forceDelete'])
        ->name('new-feature.forceDelete');
    Route::post('/new-feature/{id}/toggle-status', [NewFeatureController::class, 'toggleStatus'])
        ->name('new-feature.toggleStatus');
});
```

## Route Verification

```bash
# List all routes for a module:
php artisan route:list --path=hpc

# Cache routes (test for errors):
php artisan route:cache

# Clear route cache:
php artisan route:clear
```
