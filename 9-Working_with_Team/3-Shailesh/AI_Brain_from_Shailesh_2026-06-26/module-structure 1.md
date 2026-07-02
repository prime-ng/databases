# Module Structure — MANDATORY Gold Standard

> **Canonical Reference:** `Modules/Vendor` is the gold-standard for all module structure, service providers, policies, models, and form requests.
> Every new Laravel Module MUST follow this exact structure.

---

## 1. Directory Structure

```
Modules/{ModuleName}/
├── app/
│   ├── Http/
│   │   ├── Controllers/
│   │   │   ├── {Resource}Controller.php         ← Hub controller (Tab-based) or single-resource
│   │   │   └── {SubResource}Controller.php      ← Per-resource controller
│   │   └── Requests/
│   │       ├── {Resource}Request.php
│   │       └── {SubResource}Request.php
│   ├── Jobs/                                    ← Background jobs (queued)
│   ├── Mail/                                    ← Mailables
│   ├── Models/
│   │   ├── {Resource}.php                       ← Primary model (SoftDeletes + HasMedia)
│   │   └── {SubResource}.php
│   ├── Policies/
│   │   ├── {Resource}Policy.php                 ← One Policy per Model
│   │   └── {SubResource}Policy.php
│   └── Providers/
│       ├── {ModuleName}ServiceProvider.php      ← Main service provider
│       ├── RouteServiceProvider.php             ← Route loading + middleware
│       └── EventServiceProvider.php             ← Event → Listener bindings
├── database/
│   └── migrations/
├── lang/
├── resources/
│   └── views/
│       ├── tab_module/
│       │   └── tab.blade.php                   ← Hub tab view (if tab-based module)
│       ├── {resource}/
│       │   ├── index.blade.php                 ← Tab partial (NOT standalone)
│       │   ├── create.blade.php                ← Standalone full page
│       │   ├── edit.blade.php                  ← Standalone full page
│       │   ├── show.blade.php                  ← Standalone full page
│       │   └── trash.blade.php                 ← Standalone full page
│       └── components/                         ← Blade components (if any)
├── routes/
│   ├── web.php
│   └── api.php
└── module.json
```

---

## 2. RouteServiceProvider Pattern

Every module has its own `RouteServiceProvider` that applies tenancy + auth middleware and sets a route prefix and name.

```php
<?php

namespace Modules\{Module}\Providers;

use App\Http\Middleware\EnsureTenantIsActive;
use Illuminate\Foundation\Support\Providers\RouteServiceProvider as ServiceProvider;
use Illuminate\Support\Facades\Route;
use Stancl\Tenancy\Middleware\InitializeTenancyByDomain;
use Stancl\Tenancy\Middleware\PreventAccessFromCentralDomains;

class RouteServiceProvider extends ServiceProvider
{
    protected string $name = '{ModuleName}';

    public function boot(): void
    {
        parent::boot();
    }

    public function map(): void
    {
        $this->mapApiRoutes();
        $this->mapWebRoutes();
    }

    protected function mapWebRoutes(): void
    {
        Route::middleware([
                'web',
                InitializeTenancyByDomain::class,
                PreventAccessFromCentralDomains::class,
                EnsureTenantIsActive::class,
                'auth',
                'verified',
            ])
            ->prefix('{module-slug}')        // ← URL prefix e.g. 'vendor'
            ->name('{module-slug}.')         // ← Route name prefix e.g. 'vendor.'
            ->group(module_path($this->name, '/routes/web.php'));
    }

    protected function mapApiRoutes(): void
    {
        Route::middleware('api')
            ->prefix('api')
            ->name('api.')
            ->group(module_path($this->name, '/routes/api.php'));
    }
}
```

**Rules:**
- Route prefix MUST be the module's slug (e.g., `vendor`, `behavioural-assessment`).
- Route name prefix MUST match URL prefix + `.` (e.g., `vendor.`).
- ALL tenancy + auth middleware MUST be applied here — never in individual route files.
- `'verified'` middleware MUST be included.

---

## 3. ServiceProvider Pattern

```php
<?php

namespace Modules\{Module}\Providers;

use Illuminate\Support\Facades\Gate;
use Illuminate\Support\ServiceProvider;
use Modules\{Module}\Models\{Resource};
use Modules\{Module}\Policies\{Resource}Policy;
// ... import all models and policies

class {Module}ServiceProvider extends ServiceProvider
{
    use PathNamespace;

    protected string $name = '{ModuleName}';
    protected string $nameLower = '{module-name-lower}';

    public function boot(): void
    {
        $this->registerCommands();
        $this->registerCommandSchedules();
        $this->registerTranslations();
        $this->registerConfig();
        $this->registerViews();
        $this->loadMigrationsFrom(module_path($this->name, 'database/migrations'));
        $this->registerPolicies();   // ← MUST call registerPolicies() here
    }

    public function register(): void
    {
        $this->app->register(EventServiceProvider::class);
        $this->app->register(RouteServiceProvider::class);
    }

    /**
     * Register all Model → Policy bindings using Gate::policy().
     * One entry per Model that has a Policy.
     */
    protected function registerPolicies(): void
    {
        Gate::policy({Resource}::class, {Resource}Policy::class);
        Gate::policy({SubResource}::class, {SubResource}Policy::class);
        // ... repeat for every model
    }

    // ... registerTranslations, registerConfig, registerViews
    // (copy standard boilerplate from VendorServiceProvider)
}
```

**Rules:**
- `registerPolicies()` MUST register ALL models that need authorization.
- `boot()` MUST call `$this->registerPolicies()`.
- Both `EventServiceProvider` and `RouteServiceProvider` MUST be registered in `register()`.

---

## 4. Policy Pattern

One Policy file per Model. Policy methods delegate to Spatie permission system via `$user->can('tenant.{slug}.{action}')`.

```php
<?php

namespace Modules\{Module}\Policies;

use App\Models\User;
use Modules\{Module}\Models\{Resource};

class {Resource}Policy
{
    public function viewAny(User $user): bool
    {
        return $user->can('tenant.{slug}.viewAny');
    }

    public function view(User $user, {Resource} $record): bool
    {
        return $user->can('tenant.{slug}.view');
    }

    public function create(User $user): bool
    {
        return $user->can('tenant.{slug}.create');
    }

    public function update(User $user, {Resource} $record): bool
    {
        return $user->can('tenant.{slug}.update');
    }

    public function delete(User $user, {Resource} $record): bool
    {
        return $user->can('tenant.{slug}.delete');
    }

    public function restore(User $user, {Resource} $record): bool
    {
        return $user->can('tenant.{slug}.restore');
    }

    public function forceDelete(User $user, {Resource} $record): bool
    {
        return $user->can('tenant.{slug}.forceDelete');
    }
}
```

**Rules:**
- `authorize()` in Policy methods ALWAYS delegates to Spatie via `$user->can('tenant.{slug}.{action}')`.
- NEVER add direct role checks or custom logic in Policy methods.
- Policy MUST be registered in `ServiceProvider::registerPolicies()` via `Gate::policy(Model::class, Policy::class)`.

---

## 5. Model Pattern

```php
<?php

namespace Modules\{Module}\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Spatie\MediaLibrary\HasMedia;
use Spatie\MediaLibrary\InteractsWithMedia;
use Spatie\MediaLibrary\MediaCollections\Models\Media;
use Modules\GlobalMaster\Models\Dropdown;

class {Resource} extends Model implements HasMedia
{
    use SoftDeletes, InteractsWithMedia;

    protected $table = '{module_prefix}_{table_name}';  // e.g. 'vnd_vendors', 'adm_students'

    /* ===================== FILLABLE ===================== */

    protected $fillable = [
        // explicit column list — NEVER use $guarded = []
        'name',
        'is_active',
        // ...
    ];

    /* ===================== CASTS ===================== */

    protected $casts = [
        'is_active'   => 'boolean',
        'amount'      => 'decimal:2',
        'start_date'  => 'date',
        'created_at'  => 'datetime',
        'updated_at'  => 'datetime',
        'deleted_at'  => 'datetime',
    ];

    /* ===================== DEFAULTS (optional) ===================== */

    protected $attributes = [
        'is_active' => true,
        'status'    => 'DRAFT',
    ];

    /* ===================== CONSTANTS (for ENUM columns) ===================== */

    public const STATUS_DRAFT   = 'DRAFT';
    public const STATUS_ACTIVE  = 'ACTIVE';
    public const STATUS_EXPIRED = 'EXPIRED';

    /* ===================== SCOPES ===================== */

    public function scopeActive($query)
    {
        return $query->where('is_active', true);
    }

    public function scopeCurrent($query)
    {
        return $query
            ->whereDate('start_date', '<=', now())
            ->whereDate('end_date', '>=', now());
    }

    /* ===================== RELATIONSHIPS ===================== */

    public function category()
    {
        return $this->belongsTo(Dropdown::class, 'category_id');
    }

    public function items()
    {
        return $this->hasMany({SubResource}::class, 'parent_id');
    }

    public function item()
    {
        return $this->hasOne({SubResource}::class, 'parent_id');
    }

    // hasManyThrough example (Vendor → Invoice → Payment)
    public function payments()
    {
        return $this->hasManyThrough(
            Payment::class,
            Invoice::class,
            'vendor_id',   // FK on invoices
            'invoice_id',  // FK on payments
            'id',          // Local key on vendors
            'id'           // Local key on invoices
        );
    }

    /* ===================== SPATIE MEDIA ===================== */

    public function registerMediaCollections(): void
    {
        $this->addMediaCollection('{collection_name}')
             ->singleFile();   // use for profile/document — one file per record
    }

    public function registerMediaConversions(?Media $media = null): void
    {
        $this->addMediaConversion('small')
            ->width(150)->height(150)->sharpen(10)->nonQueued();

        $this->addMediaConversion('medium')
            ->width(400)->height(400)->sharpen(10)->nonQueued();
    }

    /* ===================== HELPERS ===================== */

    public function hasPhoto(): bool
    {
        return $this->hasMedia('{collection_name}');
    }

    public function photoUrl(string $conversion = ''): ?string
    {
        if (! $this->hasPhoto()) return null;
        return $conversion
            ? $this->getFirstMediaUrl('{collection_name}', $conversion)
            : $this->getFirstMediaUrl('{collection_name}');
    }
}
```

**Model Rules:**
- Table name MUST use module prefix: `{module_prefix}_{table_name}` (e.g. `vnd_vendors`, `adm_students`).
- NEVER use `$guarded = []` — always use explicit `$fillable`.
- ALWAYS cast `is_active` to `'boolean'`.
- ALWAYS cast monetary amounts to `'decimal:2'`.
- ALWAYS cast date fields to `'date'` or `'datetime'`.
- Use `protected $attributes` for default column values.
- Use `public const` for ENUM column values — never raw strings in code.
- Use `scopeActive()` on every model that has `is_active` column.
- If model uses file uploads, implement `HasMedia` + `InteractsWithMedia` from Spatie.

---

## 6. FormRequest Pattern

```php
<?php

namespace Modules\{Module}\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;
use Modules\{Module}\Models\{Resource};

class {Resource}Request extends FormRequest
{
    /**
     * Always return true — authorization is handled by Gate::authorize() in the controller.
     */
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        // For update routes, resolve the current record ID for unique() ignore
        $recordId = $this->route('{route_param}');
        $recordId = is_object($recordId) ? $recordId->id : $recordId;

        return [

            /* ================= REQUIRED FIELDS ================= */

            'name' => [
                'required',
                'string',
                'max:100',
                Rule::unique('{table_name}', 'name')
                    ->ignore($recordId)
                    ->whereNull('deleted_at'),   // ← ALWAYS scope unique to non-deleted
            ],

            /* ================= DROPDOWN FK FIELDS ================= */

            'category_id' => [
                'required',
                'integer',
                'exists:sys_dropdowns,id',
            ],

            /* ================= ENUM FIELDS ================= */

            'item_type' => [
                'required',
                Rule::in(['SERVICE', 'PRODUCT']),
            ],

            /* ================= OPTIONAL / NULLABLE FIELDS ================= */

            'description' => [
                'nullable',
                'string',
            ],

            /* ================= STATUS ================= */

            'is_active' => [
                'required',
                'boolean',
            ],
        ];
    }

    /**
     * Cast checkbox boolean BEFORE validation runs.
     * This ensures 'on'/'off'/'1'/'0' from HTML checkboxes become proper booleans.
     */
    protected function prepareForValidation(): void
    {
        $this->merge([
            'is_active' => $this->boolean('is_active'),
        ]);
    }

    /**
     * Custom error messages (optional but recommended for user-facing clarity).
     */
    public function messages(): array
    {
        return [
            'name.required' => 'Name is required.',
            'name.unique'   => 'This name already exists.',
        ];
    }
}
```

**FormRequest Rules:**
- `authorize()` ALWAYS returns `true` — Controller handles authorization via `Gate::authorize()`.
- ALWAYS use `Rule::unique(...)->ignore($recordId)->whereNull('deleted_at')` for unique fields — never plain `'unique:table,column'`.
- ALWAYS resolve the route param ID: `$id = is_object($id) ? $id->id : $id` (handles both model-binding and raw ID).
- ALWAYS use `prepareForValidation()` to cast `is_active` boolean from HTML checkboxes.
- NEVER call `$this->validate()` inside a Controller — use FormRequest injection instead.
- Group rules by section with `/* ===== SECTION ===== */` comments.

---

## 7. Media Upload in Controller

When a model uses `HasMedia`, the controller handles file uploads separately after `create()` or `update()`:

```php
// On Store:
$record = {Resource}::create($request->validated());

if ($request->hasFile('{field_name}')) {
    $record->addMediaFromRequest('{field_name}')
           ->toMediaCollection('{collection_name}');
    $record->update(['{flag_column}' => true]);
}

// On Update (clear old file first):
if ($request->hasFile('{field_name}')) {
    $record->clearMediaCollection('{collection_name}');
    $record->addMediaFromRequest('{field_name}')
           ->toMediaCollection('{collection_name}');
    $record->update(['{flag_column}' => true]);
}

// On Force Delete (always clear media first):
$record->clearMediaCollection('{collection_name}');
$record->forceDelete();
```

---

## 8. Routes (`routes/web.php`) — Full Pattern

```php
<?php

use Illuminate\Support\Facades\Route;
use Modules\{Module}\Http\Controllers\{Resource}Controller;
use Modules\{Module}\Http\Controllers\{SubResource}Controller;

// ─── {Resource} ───────────────────────────────────────────────────────────
Route::resource('{route-slug}', {Resource}Controller::class);
Route::get('/{route-slug}/trash/view',           [{Resource}Controller::class, 'trashed'])    ->name('{route-slug}.trashed');
Route::get('/{route-slug}/{id}/restore',          [{Resource}Controller::class, 'restore'])    ->name('{route-slug}.restore');
Route::delete('/{route-slug}/{id}/force-delete',  [{Resource}Controller::class, 'forceDelete'])->name('{route-slug}.forceDelete');
Route::post('/{route-slug}/{id}/toggle-status',   [{Resource}Controller::class, 'toggleStatus'])->name('{route-slug}.toggleStatus');

// ─── {SubResource} ────────────────────────────────────────────────────────
Route::resource('{sub-route-slug}', {SubResource}Controller::class);
Route::get('/{sub-route-slug}/trash/view',           [{SubResource}Controller::class, 'trashed'])    ->name('{sub-route-slug}.trashed');
Route::get('/{sub-route-slug}/{id}/restore',          [{SubResource}Controller::class, 'restore'])    ->name('{sub-route-slug}.restore');
Route::delete('/{sub-route-slug}/{id}/force-delete',  [{SubResource}Controller::class, 'forceDelete'])->name('{sub-route-slug}.forceDelete');
Route::post('/{sub-route-slug}/{id}/toggle-status',   [{SubResource}Controller::class, 'toggleStatus'])->name('{sub-route-slug}.toggleStatus');
```

**Route Rules:**
- `trash/view` MUST come BEFORE `{id}/restore` in declaration order — prevents route conflict.
- No middleware in `routes/web.php` — all middleware is in `RouteServiceProvider`.
- Route name = `{module-prefix}.{route-slug}.{action}` (e.g., `vendor.vendor.index`, `vendor.vendor-item.create`).
- Comments MUST wrap each resource block for readability.

---

## 9. Quick Checklist — New Module Setup

- [ ] `{Module}ServiceProvider` created with `registerPolicies()` calling `Gate::policy()` for ALL models
- [ ] `RouteServiceProvider` created with correct prefix + name + full middleware stack
- [ ] `EventServiceProvider` created (even if empty)
- [ ] All Models have: `$table`, `$fillable`, `$casts` (with `is_active => 'boolean'`), `scopeActive()`
- [ ] All Models with ENUM columns have `public const` for each ENUM value
- [ ] All Models with file uploads implement `HasMedia + InteractsWithMedia`
- [ ] One Policy per Model, each delegating to `$user->can('tenant.{slug}.{action}')`
- [ ] One FormRequest per resource, with `authorize()=true`, `Rule::unique()->whereNull('deleted_at')`, `prepareForValidation()` boolean cast
- [ ] Routes: `Route::resource` + 4 extra routes per resource, `trash/view` before `{id}/restore`
- [ ] Views: `tab_module/tab.blade.php` (hub) + `{resource}/index.blade.php` (tab partials) + standalone `create/edit/show/trash`
