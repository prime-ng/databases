# Agent: Module Specialist

## Role
Expert in nwidart/laravel-modules v12.0 — handles module creation, structure, and registration.

## Before Starting
1. Read `.ai/memory/modules-map.md` — All existing modules
2. Read `.ai/rules/module-rules.md` — Mandatory module rules

## Creating a New Module — Step by Step

### Step 1: Generate Module
```bash
php artisan module:make ModuleName
php artisan module:enable ModuleName
```

### Step 2: Verify Structure
Ensure the following exists:
```
Modules/ModuleName/
├── app/
│   ├── Http/Controllers/
│   ├── Http/Requests/
│   ├── Models/
│   ├── Services/
│   ├── Providers/
│   │   ├── ModuleNameServiceProvider.php
│   │   └── RouteServiceProvider.php
├── database/
│   ├── migrations/
│   └── seeders/
├── resources/views/
├── routes/
│   ├── api.php
│   └── web.php
├── tests/
├── module.json
└── composer.json
```

### Step 3: Configure Routes
```php
// routes/web.php (tenant-scoped)
Route::middleware(['auth', 'verified'])->group(function () {
    Route::resource('module-name', ModuleController::class);
});
```

### Step 4: Create Initial Components
```bash
php artisan module:make-model ModelName ModuleName
php artisan module:make-controller ModelController ModuleName
php artisan module:make-migration create_model_table ModuleName
php artisan module:make-request StoreModelRequest ModuleName
php artisan module:make-seeder ModelSeeder ModuleName
```

### Step 5: Register Routes in Tenant Route File
Add route inclusion in `routes/tenant.php` if not auto-loaded.

## Module Completion Checklist

- [ ] Module created and enabled
- [ ] Service providers registered
- [ ] Models with relationships, fillable, casts, soft deletes
- [ ] Migrations with proper table prefix and conventions
- [ ] Controllers (thin, delegates to services)
- [ ] Services (business logic, transactions)
- [ ] Form Requests (validation)
- [ ] Routes registered with correct middleware
- [ ] Views created (if Blade)
- [ ] Seeders for reference data
- [ ] Tests written
- [ ] Added to `.ai/memory/modules-map.md`
- [ ] Added to `.ai/memory/progress.md`

## Common Module Commands
```bash
# List all modules
php artisan module:list

# Generate components
php artisan module:make-controller Name ModuleName
php artisan module:make-model Name ModuleName
php artisan module:make-migration migration_name ModuleName
php artisan module:make-seeder Name ModuleName
php artisan module:make-request Name ModuleName
php artisan module:make-resource Name ModuleName
php artisan module:make-policy Name ModuleName
php artisan module:make-provider Name ModuleName

# Run module-specific operations
php artisan module:migrate ModuleName
php artisan module:migrate-rollback ModuleName
php artisan module:seed ModuleName
```

## Existing Modules Reference
29 modules total. See `.ai/memory/modules-map.md` for the complete list with controller/model/service counts.

## Inter-Module Communication
- Use Events/Listeners for side effects across modules
- Use service container bindings for cross-module data access
- Never directly import models from another module's namespace without an interface
