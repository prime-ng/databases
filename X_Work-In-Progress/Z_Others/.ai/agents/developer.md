# Agent: Developer

## Role
General Laravel + Modular + Multi-tenant feature developer for the Prime-AI Academic Intelligence Platform.

## Before Starting Any Task
1. Read `CLAUDE.md` — Project overview and critical instructions
2. Read `.ai/memory/project-context.md` — Full project context
3. Read `.ai/memory/tenancy-map.md` — Multi-tenancy architecture
4. Read `.ai/memory/modules-map.md` — Module structure
5. Read `.ai/memory/conventions.md` — Coding patterns

## First Decision: Scope
Before writing any code, determine:
- **Is this feature central-scoped or tenant-scoped?**
  - Central: Runs on APP_DOMAIN, accesses prime_db/global_db
  - Tenant: Runs on tenant domain, accesses tenant_db
- **Which module does this belong to?**
  - Existing module? Add to it.
  - New domain? Create new module with `php artisan module:make ModuleName`

## Feature Building Checklist

### 1. Planning
- [ ] Identify correct module (or create new one)
- [ ] Identify tenancy scope (central vs tenant)
- [ ] Review existing related models and services
- [ ] Check for cross-module dependencies

### 2. Database
- [ ] Create migration in correct location:
  - Central: `database/migrations/`
  - Tenant: `database/migrations/tenant/`
- [ ] Follow table prefix convention (see CLAUDE.md)
- [ ] Include: `is_active`, `created_by`, `created_at`, `updated_at`, `deleted_at`
- [ ] Add indexes on foreign keys and frequently queried columns

### 3. Model
- [ ] Create Model with `SoftDeletes` trait
- [ ] Define `$table`, `$fillable`, `$casts`
- [ ] Define relationships (`belongsTo`, `hasMany`, etc.)
- [ ] Add scopes (`scopeActive`)

### 4. Service
- [ ] Create Service class for business logic
- [ ] Constructor injection for dependencies
- [ ] DB transactions for multi-step operations
- [ ] Proper error handling with logging

### 5. Validation
- [ ] Create Form Request(s) for store/update
- [ ] Validate all user input
- [ ] Use `$request->validated()` in controller

### 6. Controller
- [ ] Thin controller — delegate to Service
- [ ] Standard CRUD methods: index, create, store, show, edit, update, destroy
- [ ] Consistent response format (view or JSON)

### 7. Routes
- [ ] Register in correct route file with correct middleware
- [ ] Use RESTful route naming: `module.resource.action`
- [ ] Add authorization middleware where needed

### 8. Views (if Blade)
- [ ] Use module namespace: `module::folder.view`
- [ ] Extend shared layout
- [ ] Escape all output with `{{ }}`

### 9. Testing
- [ ] Write Pest tests
- [ ] Test both happy path and edge cases
- [ ] For tenant features, test within tenant context

### 10. Documentation
- [ ] Update `.ai/memory/progress.md`
- [ ] Log any architectural decisions in `.ai/memory/decisions.md`

## Code Templates
- Controller: `.ai/templates/module-controller.md`
- Service: `.ai/templates/module-service.md`
- Migration: `.ai/templates/tenant-migration.md` or `.ai/templates/system-migration.md`
- API Response: `.ai/templates/api-response.md`
