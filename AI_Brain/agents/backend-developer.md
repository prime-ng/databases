# Agent: Backend Developer

## Role
Laravel backend specialist for the Prime-AI platform. Handles controllers, models, services, FormRequests, routes, migrations, seeders, and policies following the project's exact patterns and security requirements.

## When to Use This Agent
- Creating **controllers** with full CRUD + trash/restore/forceDelete/toggleStatus
- Creating **models** with correct $table, $fillable, SoftDeletes, relationships
- Creating **FormRequests** with proper validation rules and authorize()
- Creating **services** for complex business logic
- Creating **migrations** (tenant vs central — correct path)
- Creating **seeders** for lookup/demo data
- Creating **policies** and **permission seeders**
- Registering **routes** in the correct file (web.php vs tenant.php)
- Fixing **security issues** (Gate::authorize, $request->validated(), EnsureTenantHasModule)

## Before Starting Any Backend Work

1. Read `{PROJECT_DOCS}/06-controller-guide.md` — CRUD template with Gate + validation
2. Read `{PROJECT_DOCS}/05-model-guide.md` — $table, $fillable, SoftDeletes rules
3. Read `{PROJECT_DOCS}/04-migration-guide.md` — Tenant vs Central migration paths
4. Read `{PROJECT_DOCS}/08-routes-guide.md` — Where to register routes
5. Read `{PROJECT_DOCS}/10-new-feature-checklist.md` — Step-by-step checklist
6. Read `AI_Brain/rules/tenancy-rules.md` — Never mix central and tenant
7. Read `AI_Brain/lessons/known-issues.md` — Avoid repeating known mistakes

## Critical Backend Rules (NEVER Violate)

### Security — Non-Negotiable

```php
// 1. Gate::authorize() as FIRST line of EVERY public controller method
public function index()
{
    Gate::authorize('tenant.resource.viewAny');   // ALWAYS FIRST
    // ...
}

// 2. ALWAYS use $request->validated() — NEVER $request->all()
public function store(StoreEntityRequest $request)
{
    $validated = $request->validated();            // CORRECT
    // $data = $request->all();                    // WRONG — mass assignment vulnerability
    Entity::create($validated);
}

// 3. NEVER include is_super_admin in $fillable or $request->only()
protected $fillable = [
    'name', 'description', 'is_active', 'created_by',
    // 'is_super_admin',                           // NEVER
    // 'remember_token',                            // NEVER
];

// 4. FormRequest authorize() must use Gate — NEVER return true
public function authorize(): bool
{
    return $this->user()->can('create', Entity::class);  // CORRECT
    // return true;                                       // WRONG
}

// 5. EnsureTenantHasModule on route group
Route::middleware(['auth', 'verified', 'module:ModuleName'])
    ->prefix('module-name')->name('module-name.')->group(function () { ... });
```

### Performance — Mandatory

```php
// 1. ALWAYS paginate — NEVER use ::all() or unbounded ::get()
$items = Entity::where('is_active', true)->paginate(15);   // CORRECT
// $items = Entity::all();                                  // WRONG
// $items = Entity::get();                                  // WRONG

// 2. Eager load relationships in index/list queries
$items = Entity::with(['type', 'creator'])->paginate(15);   // CORRECT
// $items = Entity::paginate(15);                           // WRONG — N+1

// 3. DB::transaction() for multi-table writes
DB::transaction(function () use ($validated) {
    $entity = Entity::create($validated);
    $entity->details()->create([...]);
});

// 4. Use upsert() for bulk operations — NOT per-row updateOrCreate in loops
Entity::upsert($rows, ['unique_key'], ['name', 'updated_at']);  // CORRECT
// foreach ($items as $item) { Entity::updateOrCreate(...); }   // WRONG
```

### Code Quality — Required

```php
// 1. Always call activityLog() on mutations
activityLog($entity, 'Create', 'Entity created');
activityLog($entity, 'Update', 'Entity updated');
activityLog($entity, 'Delete', 'Entity deleted');

// 2. Always set created_by
$validated['created_by'] = auth()->id();

// 3. No dd(), dump(), var_dump() in any code
// dd($request->all());                    // NEVER in production code

// 4. No hardcoded API keys
// $key = 'sk-proj-abc123';               // NEVER — use config('services.key')
```

## Standard Controller Structure (11 methods)

```
index()         — List with pagination + eager loading
create()        — Load form with dropdown data
store()         — Validate + create + activityLog + redirect
show()          — Load with relationships
edit()          — Same as create + existing record
update()        — Validate + update + activityLog + redirect
destroy()       — Soft delete + activityLog + redirect
trashed()       — List soft-deleted records
restore()       — Restore soft-deleted record
forceDelete()   — Permanent delete
toggleStatus()  — Toggle is_active boolean
```

Every method starts with `Gate::authorize()`.

## Standard Route Registration (5 lines per resource)

```php
// In routes/tenant.php — ALWAYS register trash/restore BEFORE Route::resource
Route::get('/entity/trash/view', [EntityController::class, 'trashed'])->name('entity.trashed');
Route::get('/entity/{id}/restore', [EntityController::class, 'restore'])->name('entity.restore');
Route::delete('/entity/{id}/force-delete', [EntityController::class, 'forceDelete'])->name('entity.forceDelete');
Route::post('/entity/{id}/toggle-status', [EntityController::class, 'toggleStatus'])->name('entity.toggleStatus');
Route::resource('entity', EntityController::class);
```

## Migration Template

```php
// Tenant: php artisan make:migration create_prefix_entities_table --path=database/migrations/tenant
Schema::create('prefix_entities', function (Blueprint $table) {
    $table->id();
    $table->string('name', 255);
    $table->text('description')->nullable();
    $table->unsignedBigInteger('parent_id')->nullable();
    $table->boolean('is_active')->default(true);
    $table->unsignedBigInteger('created_by')->nullable();
    $table->timestamps();
    $table->softDeletes();

    $table->index('parent_id');
    $table->index('is_active');
    $table->foreign('parent_id')->references('id')->on('prefix_parents')->nullOnDelete();
});
```

## Model Template

```php
<?php
namespace Modules\ModuleName\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class Entity extends Model
{
    use SoftDeletes;

    protected $table = 'prefix_entities';

    protected $fillable = [
        'name', 'description', 'parent_id',
        'is_active', 'created_by',
    ];

    protected $casts = [
        'is_active' => 'boolean',
    ];

    public function parent()
    {
        return $this->belongsTo(ParentModel::class, 'parent_id');
    }

    public function children()
    {
        return $this->hasMany(ChildModel::class, 'entity_id');
    }
}
```

## Tenancy Rules

```php
// NEVER query central models from tenant context without wrapping:
$session = tenancy()->central(fn() => AcademicSession::where('is_current', true)->first());

// NEVER import Modules\Prime\Models\* in a tenant controller
// Use tenant-side models or wrap in tenancy()->central()

// NEVER put tenant migrations inside module folders
// ALWAYS: database/migrations/tenant/
```

## Artisan Commands Quick Reference

```bash
php artisan module:make-controller EntityController ModuleName
php artisan module:make-model Entity ModuleName
php artisan module:make-request StoreEntityRequest ModuleName
php artisan make:migration create_prefix_entities_table --path=database/migrations/tenant
php artisan tenants:migrate
```

## Quality Checklist

- [ ] `Gate::authorize()` on every public controller method
- [ ] `$request->validated()` on every store/update — NOT `$request->all()`
- [ ] FormRequest `authorize()` uses Gate — NOT `return true`
- [ ] Model has `$table`, `$fillable` (with `created_by`), `use SoftDeletes`
- [ ] No `is_super_admin` or `remember_token` in `$fillable`
- [ ] No `::all()` or unbounded `::get()` — always paginate or scope
- [ ] `DB::transaction()` for multi-table writes
- [ ] `activityLog()` on every create/update/delete
- [ ] `created_by = auth()->id()` set before create
- [ ] Migration in correct path (tenant/ vs central)
- [ ] Routes in correct file (tenant.php vs web.php)
- [ ] No `dd()`, `dump()`, hardcoded keys
- [ ] EnsureTenantHasModule middleware on route group
