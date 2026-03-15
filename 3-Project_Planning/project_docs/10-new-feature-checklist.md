# New Feature Checklist

## BEFORE WRITING ANY CODE — Ask These Questions

1. Is this a PRIME feature (platform admin) or TENANT feature (school)?
2. Does the module already exist or do I need to create it?
3. What table prefix should this feature use?
4. Does the migration go in `database/migrations/tenant/` or `database/migrations/`?
5. Does the route go in `routes/web.php` or `routes/tenant.php`?

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
- Set `protected $fillable = [...]` (include `created_by`)
- Add `use SoftDeletes;`
- Verify file at: `Modules/<ModuleName>/app/Models/`

### Step 4: Controller
```bash
php artisan module:make-controller <ControllerName> <ModuleName>
```
Then implement: `index()`, `create()`, `store()`, `edit()`, `update()`, `destroy()`
Return views as: `'<modulename>::<folder>.<file>'`
Add `Gate::authorize()` to every method.

### Step 5: Views
Create in: `Modules/<ModuleName>/resources/views/<feature>/`
Files: `index.blade.php`, `create.blade.php`, `edit.blade.php`
Use shared components: `<x-prime.layouts.app>`

### Step 6: Routes
Open `routes/web.php` -> add use statement -> add Route::resource()

---

## TENANT FEATURE — Step by Step

### Step 1: Module
```bash
# Only if module does not exist:
php artisan module:make <ModuleName>
```

### Step 2: Migration
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
- Set `protected $fillable = [...]` (include `created_by`)
- Add `use SoftDeletes;`
- Verify file at: `Modules/<ModuleName>/app/Models/`

### Step 4: Controller
```bash
php artisan module:make-controller <ControllerName> <ModuleName>
```
Implement CRUD methods, return views as: `'<modulename>::<folder>.<file>'`
Add `Gate::authorize()` to every method.

### Step 5: Views
Create in: `Modules/<ModuleName>/resources/views/<feature>/`
Files: `index.blade.php`, `create.blade.php`, `edit.blade.php`
Use: `<x-backend.layouts.app>` for standard pages

### Step 6: Routes
Open `routes/tenant.php` -> add use statement -> add Route::resource()

---

## FINAL CHECKLIST (Both Types)

- [ ] Table has: `id`, `is_active`, `created_by`, `created_at`, `updated_at`, `deleted_at`
- [ ] Boolean columns prefixed with `is_` or `has_`
- [ ] JSON columns suffixed with `_json`
- [ ] Junction tables suffixed with `_jnt`
- [ ] Foreign keys are indexed
- [ ] Migration is additive (never modified existing one)
- [ ] Migration in correct path (web.php central, tenant/ for tenant)
- [ ] Model has `$table` and `$fillable` defined
- [ ] Model has `use SoftDeletes`
- [ ] Model has `created_by` in `$fillable`
- [ ] Controller has `Gate::authorize()` on every public method
- [ ] Controller uses `$request->validate()` or FormRequest — NOT `$request->all()`
- [ ] Controller calls `activityLog()` on mutations
- [ ] Controller uses `->paginate()` — NOT `::all()` or unbounded `::get()`
- [ ] Route in CORRECT file (web.php for prime, tenant.php for tenant)
- [ ] View namespace is correct: `'<modulename>::<folder>.<file>'`
- [ ] Shared components used from `resources/views/components/`
- [ ] No `dd()`, `dump()`, or `var_dump()` in code
- [ ] No hardcoded API keys
- [ ] No `is_super_admin` in `$fillable`
