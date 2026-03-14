# Template: New Module Structure

## Step 1: Create Module
```bash
php artisan module:make ModuleName
php artisan module:enable ModuleName
```

## Step 2: Generated Structure
```
Modules/ModuleName/
├── app/
│   ├── Http/
│   │   ├── Controllers/
│   │   │   └── ModuleNameController.php
│   │   ├── Requests/
│   │   └── Middleware/
│   ├── Models/
│   ├── Services/
│   ├── Jobs/
│   ├── Providers/
│   │   ├── ModuleNameServiceProvider.php
│   │   ├── RouteServiceProvider.php
│   │   └── EventServiceProvider.php
│   └── Emails/
├── database/
│   ├── migrations/
│   └── seeders/
├── resources/
│   └── views/
│       └── layouts/
├── routes/
│   ├── api.php
│   └── web.php
├── tests/
│   ├── Feature/
│   └── Unit/
├── config/
│   └── config.php
├── composer.json
├── module.json
└── vite.config.js
```

## Step 3: Generate Components
```bash
# Model
php artisan module:make-model EntityName ModuleName

# Controller
php artisan module:make-controller EntityController ModuleName

# Migration
php artisan module:make-migration create_prefix_entities_table ModuleName

# Form Request
php artisan module:make-request StoreEntityRequest ModuleName
php artisan module:make-request UpdateEntityRequest ModuleName

# Seeder
php artisan module:make-seeder EntitySeeder ModuleName

# Policy
php artisan module:make-policy EntityPolicy ModuleName
```

## Step 4: Post-Generation Checklist
- [ ] Module enabled: `php artisan module:enable ModuleName`
- [ ] Table prefix follows convention (see CLAUDE.md)
- [ ] Model has: `$table`, `$fillable`, `$casts`, `SoftDeletes`, relationships
- [ ] Migration has: `is_active`, `created_by`, `timestamps()`, `softDeletes()`
- [ ] Controller is thin, delegates to Service
- [ ] Routes registered with `['auth', 'verified']` middleware
- [ ] Form Requests validate all user input
- [ ] Service handles business logic with transactions
- [ ] Added to `.ai/memory/modules-map.md`
- [ ] Added to `.ai/memory/progress.md`
