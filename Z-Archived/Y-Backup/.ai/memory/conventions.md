# Coding Conventions & Patterns

## Naming Conventions

### Tables
- Prefixed by module: `tt_`, `std_`, `sch_`, `slb_`, etc.
- Junction tables suffixed with `_jnt`
- Snake_case, plural for main tables (e.g., `tt_activities`, `std_students`)
- Singular for junction targets (e.g., `tt_activity_teacher`)

### Models
- PascalCase, singular (e.g., `Activity`, `Student`, `SchoolClass`)
- Located in `Modules/{Module}/app/Models/`
- Table explicitly set: `protected $table = 'tt_activities';`

### Controllers
- PascalCase with `Controller` suffix (e.g., `ActivityController`, `StudentController`)
- Located in `Modules/{Module}/app/Http/Controllers/`
- Thin controllers — business logic in Services

### Services
- PascalCase with `Service` suffix (e.g., `ConstraintManager`, `FETSolver`)
- Located in `Modules/{Module}/app/Services/`
- Constructor injection for dependencies

### Form Requests
- PascalCase with action prefix (e.g., `StoreStudentRequest`, `UpdateFeeRequest`)
- Located in `Modules/{Module}/app/Http/Requests/`

## Controller Patterns (from existing code)

### Standard CRUD Pattern
```php
public function index(Request $request)
{
    $data = Model::with('relationship')
        ->when($request->search, fn($q) => $q->where('name', 'like', "%{$request->search}%"))
        ->orderBy('created_at', 'desc')
        ->paginate(15);

    return view('module::viewname.index', compact('data'));
}

public function store(StoreRequest $request)
{
    $validated = $request->validated();
    $record = Model::create($validated);
    return redirect()->route('module.index')->with('success', 'Created successfully');
}
```

### API Response Pattern
```php
// Success
return response()->json([
    'success' => true,
    'data' => $result,
    'message' => 'Operation successful'
]);

// Error
return response()->json([
    'success' => false,
    'message' => 'Error description'
], 422);

// Paginated
return response()->json([
    'success' => true,
    'data' => $paginated->items(),
    'meta' => [
        'current_page' => $paginated->currentPage(),
        'last_page' => $paginated->lastPage(),
        'per_page' => $paginated->perPage(),
        'total' => $paginated->total(),
    ]
]);
```

## Model Patterns

### Common Traits
```php
use SoftDeletes;          // On all models
use InteractsWithMedia;   // Where file uploads needed (Spatie)
use HasRoles;             // On User model (Spatie)
```

### Standard Model Structure
```php
class Activity extends Model
{
    use SoftDeletes;

    protected $table = 'tt_activities';

    protected $fillable = [...];

    protected $casts = [
        'is_active' => 'boolean',
        'params_json' => 'array',
        'deleted_at' => 'datetime',
    ];

    // Relationships
    public function teachers(): HasMany { ... }
    public function class(): BelongsTo { ... }

    // Scopes
    public function scopeActive($query) { return $query->where('is_active', true); }
}
```

### Soft Deletes Pattern
- All tables have `is_active` (boolean) + `deleted_at` (timestamp)
- Use `SoftDeletes` trait on all models
- Toggle active/inactive via `is_active` field
- Hard delete only via `forceDelete()`

## Route Patterns

### Tenant Routes (in `routes/tenant.php`)
```php
Route::middleware(['auth', 'verified'])->group(function () {
    Route::resource('model-name', ModelController::class);
    Route::post('model-name/{model}/toggle-status', [ModelController::class, 'toggleStatus']);
    Route::post('model-name/{model}/restore', [ModelController::class, 'restore']);
});
```

### Central Routes (in `routes/web.php`)
```php
Route::domain(config('app.central_domain'))->middleware(['auth'])->group(function () {
    Route::prefix('prime')->group(function () {
        Route::resource('tenant-management', TenantController::class);
    });
});
```

## View Patterns
- Blade templates with module namespace: `module::folder.view`
- Layouts extend a shared layout
- Components for reusable UI elements
- Vite for asset bundling

## Database Conventions
- All tables: `created_at`, `updated_at` (timestamps)
- All tables: `deleted_at` (soft deletes)
- All tables: `is_active` (boolean, default true)
- All tables: `created_by` (nullable, FK to sys_users)
- Foreign keys: `{entity}_id` naming (e.g., `teacher_id`, `class_id`)
- JSON columns: `_json` suffix (e.g., `params_json`, `preferred_time_slots_json`)
- Generated columns for unique constraints on nullable booleans
- InnoDB engine, UTF8MB4 charset
- Indexes on all foreign keys and frequently queried columns
