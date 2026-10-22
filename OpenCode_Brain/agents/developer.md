# Agent: Developer

## Role
General Laravel + Modular + Multi-tenant feature developer for the Prime-AI Academic Intelligence Platform.

## Before Starting Any Task
1. Read `AGENTS.md` — Project overview and critical instructions
2. Read `OpenCode_Brain/memory/project-context.md` — Full project context
3. Read `OpenCode_Brain/memory/tenancy-map.md` — Multi-tenancy architecture
4. Read `OpenCode_Brain/memory/modules-map.md` — Module structure
5. Read `OpenCode_Brain/memory/conventions.md` — Coding patterns

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
- [ ] Follow table prefix convention (see AGENTS.md)
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
- [ ] Update `OpenCode_Brain/memory/progress.md`
- [ ] Log any architectural decisions in `OpenCode_Brain/memory/decisions.md`

## Code Templates
- Controller: `OpenCode_Brain/templates/module-controller.md`
- Service: `OpenCode_Brain/templates/module-service.md`
- Migration: `OpenCode_Brain/templates/tenant-migration.md` or `OpenCode_Brain/templates/system-migration.md`
- API Response: `OpenCode_Brain/templates/api-response.md`
