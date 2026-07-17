# Controller & Model Code Pattern — Full Stack Flow

> **Purpose:** Define how Controller, Model, Blade, FormRequest, Policy, Routes, ServiceProvider, and Breadcrumb connect.
> **Note:** This file uses `Modules/Vendor` as the gold-standard reference.

---

## 1. Complete Request Lifecycle

```
Browser hits:  GET /vendor/create
                    │
                    ▼
┌─────────────────────────────────────────────────┐
│  1. routes/web.php                              │
│     Route::resource('vendor', VendorController)  │
│     ↓                                           │
│     Matches: GET /vendor/create                  │
│     Route name: vendor.vendor.create             │
└─────────────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────────┐
│  2. RouteServiceProvider applies middleware      │
│     web → InitializeTenancyByDomain              │
│     → PreventAccessFromCentralDomains            │
│     → EnsureTenantIsActive → auth → verified      │
│     → prefix: 'vendor' → name: 'vendor.'         │
└─────────────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────────┐
│  3. VendorController::create()                   │
│     Gate::authorize('tenant.vendor.create')      │
│     return view('vendor::vendor.create');         │
└─────────────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────────┐
│  4. resources/views/vendor/create.blade.php      │
│     <x-backend.layouts.app>                      │
│     <x-backend.components.breadcrum ... />       │
│     <form action="{{ route('vendor.vendor.store') }}"> │
│       @csrf                                      │
│       <x-backend.form.input-text name="vendor_name" ... /> │
│       <x-backend.form.form-dropdown key="vnd_vendors.vendor_type_id" ... /> │
│       <x-backend.form.status-switch ... />       │
│     </form>                                      │
└─────────────────────────────────────────────────┘
                    │
                    ▼  User fills form, clicks "Create Vendor"
                    │
┌─────────────────────────────────────────────────┐
│  5. POST /vendor (stored in form action)         │
│     Route: Route::post('/vendor', [VendorController::class, 'store']) │
│     name: vendor.vendor.store                    │
└─────────────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────────┐
│  6. VendorRequest (Form Request)                 │
│     authorize() → return true                    │
│     rules() → validates vendor_name, is_active,  │
│               contact_person, contact_number...   │
│     prepareForValidation() → boolean cast         │
│     returns $request->validated()                 │
└─────────────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────────┐
│  7. VendorController::store(VendorRequest $request) │
│     Gate::authorize('tenant.vendor.create')      │
│     $vendor = Vendor::create($request->validated()) │
│     activityLog(...)                             │
│     return redirect()->route('vendor.vendor.index') │
│              ->with('success', flash('created.vendor')) │
└─────────────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────────┐
│  8. config/breadcrumb.php                        │
│     'vendor' => 'vendor/vendor'  (hub_map)      │
│     Resolves breadcrumb for /vendor page         │
└─────────────────────────────────────────────────┘
```

---

## 2. Routes → Controller Connection

### 2.1 Route Registration Types

**Type A — Module RouteServiceProvider** (Vendor, Cafeteria, Library):
```php
// Modules/Vendor/Providers/RouteServiceProvider.php
protected function mapWebRoutes(): void
{
    Route::middleware(['web', InitializeTenancyByDomain::class,
           PreventAccessFromCentralDomains::class,
           EnsureTenantIsActive::class, 'auth', 'verified'])
        ->prefix('vendor')       // ← URL prefix
        ->name('vendor.')        // ← Route name prefix
        ->group(module_path($this->name, '/routes/web.php'));
}
// All routes in Modules/Vendor/routes/web.php automatically have:
//   URL:  /vendor/{path}
//   Name: vendor.{name}
```

**Type B — Direct tenant.php group** (SchoolSetup):
```php
// routes/tenant.php
Route::middleware([...])->prefix('school-setup')->name('school-setup.')->group(function () {
    // include Modules/SchoolSetup/routes/web.php  (loaded via require or inline)
});
// All routes in SchoolSetup have:
//   URL:  /school-setup/{path}
//   Name: school-setup.{name}
```

### 2.2 Route Resource → Controller Method Map

| Route Definition | HTTP | URL | Controller Method | Blade View |
|---|---|---|---|---|
| `Route::resource('vendor', VendorController::class)` | GET | `/vendor` | `index()` | `vendor::tab_module.tab` (hub) |
| | GET | `/vendor/create` | `create()` | `vendor::vendor.create` |
| | POST | `/vendor` | `store()` | redirect → index |
| | GET | `/vendor/{vendor}` | `show()` | `vendor::vendor.show` |
| | GET | `/vendor/{vendor}/edit` | `edit()` | `vendor::vendor.edit` |
| | PUT | `/vendor/{vendor}` | `update()` | redirect → index |
| | DELETE | `/vendor/{vendor}` | `destroy()` | redirect → index |
| Custom: `GET /vendor/trash/view` | GET | `/vendor/trash/view` | `trashed()` | `vendor::vendor.trash` |
| Custom: `GET /vendor/{id}/restore` | GET | `/vendor/{id}/restore` | `restore()` | redirect → index |
| Custom: `DELETE /vendor/{id}/force-delete` | DELETE | `/vendor/{id}/force-delete` | `forceDelete()` | redirect → index |
| Custom: `POST /vendor/{id}/toggle-status` | POST | `/vendor/{id}/toggle-status` | `toggleStatus()` | JSON response |

### 2.3 Route Name Convention

```
{module-prefix}.{route-slug}.{action}

Examples:
  vendor.vendor.index          ← Vendor list
  vendor.vendor.create         ← Vendor create form
  vendor.vendor.store          ← Vendor store (POST)
  vendor.vendor-item.index     ← Vendor Item list
  cafeteria.menu-items.create  ← Menu Item create
  school-setup.school-class.index ← School Class list
```

**In Blade, route names are used in:**
```blade
<form action="{{ route('vendor.vendor.store') }}" method="POST">
<a href="{{ route('vendor.vendor.create') }}">Add Vendor</a>
<a href="{{ route('vendor.vendor.edit', $vendor->id) }}">Edit</a>
```

---

## 3. Controller Pattern — Full Template

### 3.1 Controller Class Structure

```
VendorController
├── index()         → Gate::any([...permissions]) → view('module::tab_module.tab', data)
├── create()        → Gate::authorize('create') → view('module::resource.create')
├── store(Request)  → Gate::authorize('create') → Model::create(validated) → activityLog() → redirect
├── show($id)       → Gate::authorize('view') → view('module::resource.show', compact('record'))
├── edit($id)       → Gate::authorize('update') → view('module::resource.edit', compact('record'))
├── update(Request) → Gate::authorize('update') → record->update(validated) → activityLog() → redirect
├── destroy($id)    → Gate::authorize('delete') → record->delete() → activityLog() → redirect
├── trashed()       → Gate::authorize('restore') → view('module::resource.trash')
├── restore($id)    → Gate::authorize('restore') → record->restore() → activityLog() → redirect
├── forceDelete($id)→ Gate::authorize('forceDelete') → record->forceDelete() → activityLog() → redirect
├── toggleStatus()  → Gate::authorize('update') → toggle is_active → JSON response
│
├── PRIVATE: vendorsQuery($request)        ← tab-scoped query builder
├── PRIVATE: vendorItemsQuery($request)    ← tab-scoped query builder
└── PRIVATE: vendorAgreementsQuery($request) ← tab-scoped query builder
```

### 3.2 Each Method Pattern

```php
// ─── INDEX (Hub — loads ALL tab data) ────────────────────────────────────
public function index(Request $request)
{
    Gate::any(['tenant.vendor.viewAny', 'tenant.vendor-item.viewAny', ...]) || abort(403);

    return view('vendor::tab_module.tab', [
        'vendors'     => $this->vendorsQuery($request)->paginate(10, ['*'], 'vendors_page')->withQueryString(),
        'vendorItems' => $this->vendorItemsQuery($request)->paginate(10, ['*'], 'items_page')->withQueryString(),
        'filters'     => $request->only(['search', 'status']),
    ]);
}

// ─── PRIVATE QUERY (tab-scoped!) ──────────────────────────────────────────
private function vendorsQuery(Request $request)
{
    $query = Vendor::query();
    if ($request->input('tab') === 'vendor') {   // ← ONLY filter when this tab is active
        $query->when($request->filled('search'), fn($q) =>
            $q->where('vendor_name', 'like', "%{$request->search}%")
        );
    }
    return $query->latest();
}

// ─── CREATE ───────────────────────────────────────────────────────────────
public function create()
{
    Gate::authorize('tenant.vendor.create');
    return view('vendor::vendor.create');
}

// ─── STORE ────────────────────────────────────────────────────────────────
public function store(VendorRequest $request)
{
    Gate::authorize('tenant.vendor.create');
    $vendor = Vendor::create($request->validated());
    activityLog($vendor, 'Stored', ['message' => 'Vendor created.', 'performed_by' => Auth::user()->name]);
    return redirect()->route('vendor.vendor.index')->with('success', flash('created.vendor'));
}

// ─── SHOW ─────────────────────────────────────────────────────────────────
public function show(Vendor $vendor)
{
    Gate::authorize('tenant.vendor.view');
    return view('vendor::vendor.show', compact('vendor'));
}

// ─── EDIT ─────────────────────────────────────────────────────────────────
public function edit(Vendor $vendor)
{
    Gate::authorize('tenant.vendor.update');
    return view('vendor::vendor.edit', compact('vendor'));
}

// ─── UPDATE ───────────────────────────────────────────────────────────────
public function update(VendorRequest $request, Vendor $vendor)
{
    Gate::authorize('tenant.vendor.update');
    $original = $vendor->getOriginal();
    $vendor->update($request->validated());
    // Track changes for audit
    $changes = [];
    foreach ($vendor->getChanges() as $field => $newValue) {
        if ($field === 'updated_at') continue;
        $changes[$field] = ['old' => $original[$field] ?? null, 'new' => $newValue];
    }
    activityLog($vendor, 'Updated', ['message' => 'Vendor updated.', 'changes' => $changes]);
    return redirect()->route('vendor.vendor.index')->with('success', flash('updated.vendor'));
}

// ─── DESTROY (soft delete) ────────────────────────────────────────────────
public function destroy(Vendor $vendor)
{
    Gate::authorize('tenant.vendor.delete');
    $vendor->is_active = false;
    $vendor->save();
    $vendor->delete();
    activityLog($vendor, 'Trashed', ['message' => 'Vendor trashed.']);
    return redirect()->route('vendor.vendor.index')->with('success', flash('trashed.vendor'));
}

// ─── TRASHED (list soft-deleted) ──────────────────────────────────────────
public function trashed()
{
    Gate::authorize('tenant.vendor.restore');
    $vendors = Vendor::onlyTrashed()->paginate(10);
    return view('vendor::vendor.trash', compact('vendors'));
}

// ─── RESTORE ──────────────────────────────────────────────────────────────
public function restore($id)
{
    Gate::authorize('tenant.vendor.restore');
    $vendor = Vendor::onlyTrashed()->findOrFail($id);
    $vendor->restore();
    $vendor->is_active = true;
    $vendor->save();
    activityLog($vendor, 'Restored', ['message' => 'Vendor restored.']);
    return redirect()->route('vendor.vendor.index')->with('success', flash('restored.vendor'));
}

// ─── FORCE DELETE ─────────────────────────────────────────────────────────
public function forceDelete($id)
{
    Gate::authorize('tenant.vendor.forceDelete');
    $vendor = Vendor::withTrashed()->findOrFail($id);
    $vendor->forceDelete();
    activityLog($vendor, 'Deleted', ['message' => 'Vendor permanently deleted.']);
    return redirect()->route('vendor.vendor.index')->with('success', flash('force_deleted.vendor'));
}

// ─── TOGGLE STATUS (AJAX) ─────────────────────────────────────────────────
public function toggleStatus(Request $request, $id)
{
    Gate::authorize('tenant.vendor.update');
    $request->validate(['is_active' => 'required|boolean']);
    $vendor = Vendor::findOrFail($id);
    $vendor->is_active = $request->is_active;
    $vendor->save();
    activityLog($vendor, 'Toggled', ['message' => 'Vendor status updated.']);
    return response()->json(['success' => true, 'is_active' => $vendor->is_active, 'message' => flash('status_updated.vendor')]);
}
```

### 3.3 Controller Rules Summary

| Rule | Description |
|---|---|
| `Gate::authorize()` | FIRST line in EVERY method (index, create, store, show, edit, update, destroy, trashed, restore, forceDelete, toggleStatus) |
| `$request->validated()` | ALWAYS use validated data, never `$request->all()` or `$request->input()` |
| `activityLog()` | After EVERY create/update/delete/restore operation |
| `View::make()` | Use `view('module::resource.action', compact('var'))` |
| Redirect | Always `->route('module.slug.index')` after success |
| Flash messages | Use `->with('success', flash('action.resource'))` |
| `destroy()` | Set `is_active = false` BEFORE `->delete()` |
| Private query methods | Tab-scoped: check `$request->input('tab')` before applying filters |
| Unique paginator names | Each tab's paginate needs a unique page name: `paginate(10, ['*'], 'unique_page')` |

---

## 4. Model Pattern

### 4.1 Model Structure

```
Vendor (Model)
├── SoftDeletes          ← trait for soft delete
├── InteractsWithMedia   ← Spatie trait for file uploads
│
├── $table = 'vnd_vendors'   ← table name (prefix_table)
├── $fillable = [ ... ]      ← explicit column list (NEVER $guarded = [])
├── $casts = [ ... ]         ← type casting (is_active → boolean, etc.)
│
├── scopeActive()            ← where('is_active', true)
│
├── vendorType()             ← belongsTo(Dropdown)
├── invoices()               ← hasMany(VndInvoice)
├── agreements()             ← hasMany(VndAgreement)
├── payments()               ← hasManyThrough(VndPayment, VndInvoice)
│
├── registerMediaCollections() → 'vendor_documents'
├── registerMediaConversions() → 'small' (150x150), 'medium' (400x400)
│
├── Accessors: getPanMaskedAttribute()      ← masked PAN
└── Accessors: getBankAccountMaskedAttribute() ← masked account
```

### 4.2 Complete Model Template

```php
<?php

namespace Modules\{Module}\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Spatie\MediaLibrary\HasMedia;
use Spatie\MediaLibrary\InteractsWithMedia;
use Spatie\MediaLibrary\MediaCollections\Models\Media;

class {Resource} extends Model implements HasMedia
{
    use SoftDeletes, InteractsWithMedia;

    protected $table = '{prefix}_{table_name}';   // e.g. 'vnd_vendors'

    protected $fillable = [
        'name',           // ← ALL DB columns that can be mass-assigned
        'is_active',      // ← ALWAYS include is_active
        // ... every column from DDL
    ];

    protected $casts = [
        'is_active'  => 'boolean',       // ← ALWAYS
        'amount'     => 'decimal:2',
        'start_date' => 'date',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
        'deleted_at' => 'datetime',
    ];

    protected $attributes = [
        'is_active' => true,             // ← default values
    ];

    // ─── Scopes ───────────────────────────────────────────────────────────
    public function scopeActive($query)
    {
        return $query->where('is_active', true);
    }

    // ─── Relations ────────────────────────────────────────────────────────
    public function category()
    {
        return $this->belongsTo(Dropdown::class, 'category_id');
    }

    public function items()
    {
        return $this->hasMany(SubResource::class, 'parent_id');
    }

    // ─── Media ────────────────────────────────────────────────────────────
    public function registerMediaCollections(): void
    {
        $this->addMediaCollection('documents')->singleFile();
    }

    public function registerMediaConversions(?Media $media = null): void
    {
        $this->addMediaConversion('thumb')->width(150)->height(150)->nonQueued();
    }
}
```

### 4.3 Model Rules

| Rule | Why |
|---|---|
| Use `$fillable`, NEVER `$guarded = []` | Mass assignment protection |
| Always cast `is_active` to `'boolean'` | Status switch component needs boolean |
| Always cast monetary amounts to `'decimal:2'` | Prevents floating point corruption |
| Use `SoftDeletes` trait on ALL critical records | Data recovery |
| Table name = `{prefix}_{snake_plural}` | Convention: `vnd_vendors`, `std_students` |
| Define `scopeActive()` on every model with `is_active` | Reusable filter |
| Use `public const` for ENUM columns | Never raw strings |
| No business logic in models | Models = data structure only |

---

## 5. Blade View → Controller Connection

### 5.1 How Blade Receives Data

```php
// In Controller:
public function create()
{
    return view('vendor::vendor.create');
    // No data needed for create form — just the view
}

public function show(Vendor $vendor)
{
    return view('vendor::vendor.show', compact('vendor'));
    // $vendor variable is available in the Blade view
}

// In Blade (show.blade.php):
{{ $vendor->vendor_name }}      ← access model property
{{ $vendor->vendorType->name }} ← access relationship
@if($vendor->is_active)         ← access casted boolean
```

### 5.2 Data Flow: Controller → Blade

```
Controller:
  return view('vendor::vendor.show', [
      'vendor' => Vendor::with('vendorType')->findOrFail($id)
  ]);
             │
             ▼
Blade file (resources/views/vendor/show.blade.php):
  <x-backend.layouts.app>
    <x-backend.components.breadcrum title="Vendor Details" :links="[]" />
    <div class="container-fluid">
      <table>
        <tr><th>Name</th><td>{{ $vendor->vendor_name }}</td></tr>  ← $vendor COMES FROM CONTROLLER
        <tr><th>Type</th><td>{{ $vendor->vendorType?->name ?? '-' }}</td></tr>  ← relationship
        <tr><th>Status</th>
          <td>@if($vendor->is_active) Active @else Inactive @endif</td>
        </tr>
      </table>
    </div>
  </x-backend.layouts.app>
```

**Variable naming rule:** The variable name in `compact('vendor')` becomes the variable name in Blade (`$vendor`).

### 5.3 Blade File Naming Convention

```
resources/views/{resource}/
├── index.blade.php        ← Tab partial (included in hub view)
├── create.blade.php       ← Standalone create form
├── edit.blade.php         ← Standalone edit form
├── show.blade.php         ← Standalone detail view
└── trash.blade.php        ← Standalone trash list
```

### 5.4 Blade Component Mapping

| Form Field | Component | Blade Usage |
|---|---|---|
| Text input | `x-backend.form.input-text` | `type="text" name="field" value="{{ old('field') }}" required="true"` |
| Textarea | `x-backend.form.input-textarea` | `name="field" value="{{ old('field') }}"` |
| Dropdown (FK) | `x-backend.form.form-dropdown` | `key="table.column" name="field" label="Label"` |
| Status toggle | `x-backend.form.status-switch` | `:isActive="old('is_active', true)"` |
| Submit button | `x-backend.form.button-submit` | `title="Create Resource"` |
| Status switch (table) | `x-backend.table.status-switch` | `url="module.slug" :model="$record" permission="tenant.slug.update"` |
| Action buttons (table) | `x-backend.table.action` | `:id="$record->id" url="module.slug" :view-permission="..." :edit-permission="..." :delete-permission="..."` |
| Trash actions | `x-backend.table.action-trashed` | `:id="$record->id" url="module.slug" permissions="tenant.slug"` |
| Breadcrumb | `x-backend.components.breadcrum` | `title="Page Title" :links="[]"` |
| Search bar | `x-backend.tab.search-bar` | `url="module.slug"` |
| Tab navigation | `x-backend.tab.nav-tab` | `:tabs="[...]" :active="request('tab', 'default')"` → slot for content |

### 5.5 How `$errors->any()` Works

When validation fails in `VendorRequest`, Laravel automatically:
1. Redirects back to the form page
2. Flashes old input (`old('field_name')`)
3. Makes `$errors` available in Blade

```blade
{{-- In create.blade.php — show validation errors --}}
@if ($errors->any())
    <div class="alert alert-danger">
        <ul class="mb-0">
            @foreach ($errors->all() as $error)
                <li>{{ $error }}</li>
            @endforeach
        </ul>
    </div>
@endif

{{-- Repopulate form input after failed validation --}}
<x-backend.form.input-text
    name="vendor_name"
    value="{{ old('vendor_name') }}"   ← old() repopulates from previous request
/>
```

### 5.6 Blade Permission Guards

**Status column — BOTH `<th>` AND `<td>` wrapped identically:**
```blade
{{-- HEADER --}}
@can('tenant.vendor.update')
<th>Status</th>
@endcan

{{-- BODY — must match header exactly --}}
@can('tenant.vendor.update')
<td>
    <x-backend.table.status-switch url="vendor.vendor" :model="$vendor" permission="tenant.vendor.update" />
</td>
@endcan
```

**Action column — BOTH `<th>` AND `<td>` wrapped identically:**
```blade
@canany(['tenant.vendor.view', 'tenant.vendor.update', 'tenant.vendor.delete'])
<th width="20">Action</th>
@endcanany

@canany(['tenant.vendor.view', 'tenant.vendor.update', 'tenant.vendor.delete'])
<td>
    <x-backend.table.action :id="$vendor->id" url="vendor.vendor"
        :view-permission="'tenant.vendor.view'"
        :edit-permission="'tenant.vendor.update'"
        :delete-permission="'tenant.vendor.delete'" />
</td>
@endcanany
```

**Add button:**
```blade
@can('tenant.vendor.create')
<a href="{{ route('vendor.vendor.create') }}" class="btn btn-primary btn-sm">
    <i class="fa-solid fa-plus"></i> Add Vendor
</a>
@endcan
```

---

## 6. FormRequest Pattern

### 6.1 Structure

```php
class VendorRequest extends FormRequest
{
    // ALWAYS return true — authorization is in Controller via Gate::authorize()
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        $vendorId = $this->route('vendor');          // ← route param name
        $vendorId = is_object($vendorId) ? $vendorId->id : $vendorId;

        return [
            'vendor_name' => [
                'required',
                'string',
                'max:100',
                Rule::unique('vnd_vendors', 'vendor_name')
                    ->ignore($vendorId)
                    ->whereNull('deleted_at'),        // ← ALWAYS scope to non-deleted
            ],
            'contact_person' => ['required', 'string', 'max:100'],
            'is_active'      => ['required', 'boolean'],
        ];
    }

    // Cast checkbox boolean BEFORE validation
    protected function prepareForValidation(): void
    {
        $this->merge([
            'is_active' => $this->boolean('is_active'),
        ]);
    }
}
```

### 6.2 FormRequest → Controller Data Flow

```
User submits form
       │
       ▼
VendorRequest::authorize() → true
       │
       ▼
VendorRequest::prepareForValidation()
  → $this->merge(['is_active' => true/false])   ← HTML checkbox → boolean
       │
       ▼
VendorRequest::rules()
  → validates all fields
       │
       ▼
Controller::store(VendorRequest $request)
  $validated = $request->validated();             ← ONLY validated fields
  $vendor = Vendor::create($validated);            ← creates record
```

### 6.3 Key FormRequest Rules

| DDL Column | FormRequest Rule | Blade Attribute |
|---|---|---|
| `NOT NULL` | `'required'` | `required="true"` |
| `NULL` (nullable) | `'nullable'` | (omit required) |
| `UNIQUE` | `Rule::unique('table','col')->ignore($id)->whereNull('deleted_at')` | — |
| `DEFAULT value` | Can omit `required` | — |
| FK column | `'exists:table,id'` or `'integer'` | `x-backend.form.form-dropdown` |

---

## 7. Policy Pattern

### 7.1 Structure

```php
class VendorPolicy
{
    public function viewAny(User $user): bool
    {
        return $user->can('tenant.vendor.viewAny');   // ← delegates to Spatie
    }
    public function view(User $user, Vendor $vendor): bool
    {
        return $user->can('tenant.vendor.view');
    }
    public function create(User $user): bool
    {
        return $user->can('tenant.vendor.create');
    }
    public function update(User $user, Vendor $vendor): bool
    {
        return $user->can('tenant.vendor.update');
    }
    public function delete(User $user, Vendor $vendor): bool
    {
        return $user->can('tenant.vendor.delete');
    }
    public function restore(User $user, Vendor $vendor): bool
    {
        return $user->can('tenant.vendor.restore');
    }
    public function forceDelete(User $user, Vendor $vendor): bool
    {
        return $user->can('tenant.vendor.forceDelete');
    }
}
```

### 7.2 Policy Registration (in ServiceProvider)

```php
// Modules/Vendor/Providers/VendorServiceProvider.php
protected function registerPolicies(): void
{
    Gate::policy(Vendor::class, VendorPolicy::class);
    Gate::policy(VndItem::class, VndItemPolicy::class);
    Gate::policy(VndAgreement::class, VndAgreementPolicy::class);
    // ... one entry per model
}
```

### 7.3 How Controller → Policy Connect

```
Controller:
  Gate::authorize('tenant.vendor.create')
       │
       ▼
  Looks up VendorPolicy via Gate::policy() registration
       │
       ▼
  VendorPolicy::create($user)
       │
       ▼
  return $user->can('tenant.vendor.create');   ← Spatie permission check
```

**Note:** Even though Policy is registered, the Controller uses `Gate::authorize('tenant.vendor.create')` (string-based), NOT `Gate::authorize('create', Vendor::class)` (policy-method-based). The string goes directly to Spatie.

---

## 8. Tab-Based Hub Pattern — Full Layer View

### 8.1 All Layers Together

```
┌─────────────────────────────────────────────────────────────────────┐
│  routes/web.php                                                     │
│  Route::resource('vendor', VendorController::class);                │
│  Route::get('/vendor/trash/view', ...);                             │
│  Route::get('/vendor/{id}/restore', ...);                           │
│  ...                                                                │
└─────────────────────────────────────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────────┐
│  VendorController::index($request)                                   │
│    Gate::any([...]) || abort(403)                                    │
│    $vendors   = $this->vendorsQuery($request)->paginate(...)        │
│    $items     = $this->vendorItemsQuery($request)->paginate(...)    │
│    return view('vendor::tab_module.tab', [                          │
│        'vendors' => $vendors,                                       │
│        'vendorItems' => $items,                                     │
│    ]);                                                              │
└─────────────────────────────────────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────────┐
│  tab_module/tab.blade.php  (HUB VIEW)                                │
│  <x-backend.tab.nav-tab :tabs="[                                    │
│      ['id' => 'vendor', 'label' => 'Vendor', 'permission' => ...],  │
│      ['id' => 'vendor_item', 'label' => 'Vendor Item', ...],       │
│  ]">                                                                 │
│    @can('tenant.vendor.viewAny')                                    │
│      @include('vendor::vendor.index')     ← tab partial            │
│    @endcan                                                          │
│    @can('tenant.vendor-item.viewAny')                               │
│      @include('vendor::vendor-item.index') ← tab partial           │
│    @endcan                                                          │
│  </x-backend.tab.nav-tab>                                           │
└─────────────────────────────────────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────────┐
│  vendor-item/index.blade.php  (TAB PARTIAL)                          │
│  <div class="tab-pane" id="vendor_item-pane">                       │
│    <x-backend.tab.search-bar url="vendor.vendor-item">             │
│      <input type="hidden" name="tab" value="vendor_item">          │
│      @can('tenant.vendor-item.create')                              │
│        <a href="{{ route('vendor.vendor-item.create') }}">Add</a>   │
│      @endcan                                                        │
│    </x-backend.tab.search-bar>                                      │
│    <table>...</table>                                               │
│    {{ $vendorItems->appends(['tab' => 'vendor_item'])->links() }}  │
│  </div>                                                             │
└─────────────────────────────────────────────────────────────────────┘
```

### 8.2 Tab Partial Variables — Where They Come From

```blade
{{-- In vendor-item/index.blade.php (tab partial) --}}

{{ $vendorItems }}  ← Comes from VendorController::index()
                      → key 'vendorItems' in the view data array

{{ $filters }}      ← Comes from same controller method
                      → key 'filters' in the view data array
```

**🔴 CRITICAL:** Tab partials are NOT standalone routes. You cannot visit `/vendor-item` directly — it gets data from the hub controller's `index()` method. Always visit the hub URL with `?tab=vendor_item`.

---

## 9. Breadcrumb → Blade Connection

### 9.1 Config (`config/breadcrumb.php`)

```php
'hub_map' => [
    'vendor'       => 'vendor/vendor',          // /vendor/* → links to /vendor
    'vendor-item'  => 'vendor/vendor',          // /vendor-item/* → links to /vendor
    'vendor-agreement' => 'vendor/vendor',
],
'tab_aliases' => [
    'vendor-item'  => 'vendor_item',            // URL segment → tab ID
    'vendor-agreement' => 'vendor_agreement',
],
```

### 9.2 Blade Usage

```blade
{{-- In EVERY view — :links MUST be empty [] --}}
<x-backend.components.breadcrum title="Add New Vendor" :links="[]" />
```

**How breadcrumb resolution works:**
```
1. Current URL: /vendor-item/create
2. System looks at first URL segment: 'vendor-item'
3. Looks up hub_map: 'vendor-item' => 'vendor/vendor'
4. Breadcrumb shows: Home > Vendor > Add New Vendor
   (Vendor links to /vendor)
```

---

## 10. Full File Checklist — What Each Layer Owns

| Layer | File | Owns |
|---|---|---|
| **Routes** | `routes/web.php` | URL paths, HTTP methods, route names, controller mapping |
| **Controller** | `app/Http/Controllers/{Resource}Controller.php` | Authorization (`Gate::authorize()`), data fetching, view selection, redirects, activity logging |
| **Model** | `app/Models/{Resource}.php` | Table name, fillable columns, casts, relationships, scopes, media collections |
| **FormRequest** | `app/Http/Requests/{Resource}Request.php` | Validation rules, unique constraints, boolean casting |
| **Policy** | `app/Policies/{Resource}Policy.php` | Permission delegation to Spatie (one method per action) |
| **ServiceProvider** | `app/Providers/{Module}ServiceProvider.php` | Policy registration via `Gate::policy()`, module bootstrapping |
| **RouteServiceProvider** | `app/Providers/RouteServiceProvider.php` | URL prefix, route name prefix, middleware stack |
| **Breadcrumb** | `config/breadcrumb.php` | hub_map (URL→parent), tab_aliases (URL→tab ID) |
| **Blade View** | `resources/views/{resource}/*.blade.php` | HTML rendering, form components, permission guards (`@can`), breadcrumb component |
| **Migration** | `database/migrations/*.php` | Schema: columns, types, indexes, FKs, defaults |

---

## 11. Common Stack Trace — Understanding Errors

### 11.1 "Undefined variable: vendors" in Blade

```
Error: Undefined variable: vendors
  At: Modules/Vendor/resources/views/vendor-item/index.blade.php:22
```

**Root cause:** Tab partial `vendor-item/index.blade.php` uses `$vendorItems`, but it was accessed via standalone URL `/vendor-item` instead of hub URL `/vendor?tab=vendor_item`.

**Fix:** Visit `/vendor?tab=vendor_item` — the hub controller passes `$vendorItems` to the view.

### 11.2 "Call to undefined method" — Laravel 12 validate()

```
Error: Call to undefined method App\Http\Controllers\Controller::validate()
```

**Root cause:** Laravel 12 base `Controller` class doesn't have `ValidatesRequests` trait. Calling `$this->validate()` crashes.

**Fix:** Use `$request->validate([...])` for inline validation or inject a FormRequest class.

### 11.3 "Route [resource.index] not defined"

```
Error: Route [vendor.vendor-item.index] not defined.
  At: vendor-item/index.blade.php (route() helper)
```

**Root cause:** Route name `vendor.vendor-item.index` doesn't match what's registered in `routes/web.php`. Route might be registered as `vendor-item.index` (without module prefix) or typo in slug.

**Fix:** Check the actual route name in `php artisan route:list | grep vendor-item`

### 11.4 "404 — page not found" on AJAX call

```
GET /school-setup/subject-class-mapping/get-sections/5 → 404
```

**Root cause:** Route is registered as `/class/{classId}/sections`, not `/subject-class-mapping/get-sections/{id}`.

**Fix:** Use the correct URL: `/school-setup/class/5/sections`

---

## 12. Pattern Summary — Sentence per Layer

| Layer | One-Sentence Pattern |
|---|---|
| **Route** | `Route::resource('slug', Ctrl::class)` + 4 extra routes (trashed, restore, forceDelete, toggleStatus) |
| **Controller** | Every method starts with `Gate::authorize()`, uses `$request->validated()`, calls `activityLog()`, returns view or redirect |
| **Model** | `$table`, `$fillable` (no `$guarded`), `$casts`, `SoftDeletes`, relationships, `scopeActive()`, no business logic |
| **FormRequest** | `authorize()=true`, `rules()` with `Rule::unique()` for unique fields, `prepareForValidation()` for boolean cast |
| **Policy** | Each method delegates to `$user->can('tenant.{slug}.{action}')`, registered in ServiceProvider via `Gate::policy()` |
| **Blade** | `x-backend.layouts.app` → breadcrum → container-fluid → card → form/table → `@can` guards → pagination |
| **Breadcrumb** | `hub_map` maps URL segments to parent pages; `tab_aliases` maps URL segments to tab IDs; blade uses `:links="[]"` |
| **ServiceProvider** | Registers `EventServiceProvider`, `RouteServiceProvider`, and `Gate::policy()` for all models in `registerPolicies()` |
