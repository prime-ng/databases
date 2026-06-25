# CRUD Code Patterns — MANDATORY Gold Standard

> **Canonical Reference:** `Modules/Vendor` is the gold-standard for all CRUD implementation patterns in this ERP.
> Every new module MUST follow these exact patterns for Routes, Controllers, and Blade views.

---

## 1. Routes (`routes/web.php`)

Every resource follows this exact 5-route pattern **per resource** (standard resource + 4 extras):

```php
<?php

use Illuminate\Support\Facades\Route;
use Modules\{Module}\Http\Controllers\{Resource}Controller;

// ------------------------------------------------------------------
// {Resource} Routes
// ------------------------------------------------------------------
Route::resource('{route-slug}', {Resource}Controller::class);
Route::get('/{route-slug}/trash/view',        [{Resource}Controller::class, 'trashed'])     ->name('{route-slug}.trashed');
Route::get('/{route-slug}/{id}/restore',       [{Resource}Controller::class, 'restore'])     ->name('{route-slug}.restore');
Route::delete('/{route-slug}/{id}/force-delete', [{Resource}Controller::class, 'forceDelete'])->name('{route-slug}.forceDelete');
Route::post('/{route-slug}/{id}/toggle-status',  [{Resource}Controller::class, 'toggleStatus'])->name('{route-slug}.toggleStatus');
```

### Real Example (Vendor Module):
```php
Route::resource('vendor', VendorController::class);
Route::get('/vendor/trash/view',          [VendorController::class, 'trashed'])     ->name('vendor.trashed');
Route::get('/vendor/{id}/restore',         [VendorController::class, 'restore'])     ->name('vendor.restore');
Route::delete('/vendor/{id}/force-delete', [VendorController::class, 'forceDelete'])->name('vendor.forceDelete');
Route::post('/vendor/{id}/toggle-status',  [VendorController::class, 'toggleStatus'])->name('vendor.toggleStatus');
```

### ⚠️ Important Route Rules:
- `trash/view` route MUST come before `{id}/restore` to avoid route conflict with `show($id)`.
- Route name prefix must match the module prefix used in Blade views (e.g. `vendor.vendor.index` calls the `vendor` prefix group).
- All routes must be inside the module's `routes/web.php` loaded by `RouteServiceProvider`.

---

## 2. Controller (`app/Http/Controllers/{Resource}Controller.php`)

### Full Standard CRUD Controller Pattern:

```php
<?php

namespace Modules\{Module}\Http\Controllers;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Gate;
use Modules\{Module}\Http\Requests\{Resource}Request;
use Modules\{Module}\Models\{Resource};

class {Resource}Controller extends Controller
{
    /**
     * List all records (paginated).
     */
    public function index(Request $request)
    {
        Gate::authorize('tenant.{slug}.viewAny');

        $records = {Resource}::query()
            ->when($request->filled('search'), fn ($q) =>
                $q->where('name', 'like', "%{$request->search}%")
            )
            ->when($request->filled('status'), fn ($q) =>
                $q->where('is_active', (bool) $request->status)
            )
            ->latest()
            ->paginate(10)
            ->withQueryString();

        return view('{module}::{view-folder}.index', compact('records'));
    }

    /**
     * Show the create form.
     */
    public function create()
    {
        Gate::authorize('tenant.{slug}.create');

        return view('{module}::{view-folder}.create');
    }

    /**
     * Store a new record.
     */
    public function store({Resource}Request $request)
    {
        Gate::authorize('tenant.{slug}.create');

        $record = {Resource}::create($request->validated());

        activityLog($record, 'Stored', [
            'message'      => '{Resource} created.',
            'performed_by' => Auth::user()->name,
        ]);

        return redirect()
            ->route('{module}.{route-slug}.index')
            ->with('success', flash('created.{slug}'));
    }

    /**
     * Show the record details (read-only).
     */
    public function show($id)
    {
        Gate::authorize('tenant.{slug}.view');

        $record = {Resource}::findOrFail($id);

        return view('{module}::{view-folder}.show', compact('record'));
    }

    /**
     * Show the edit form.
     */
    public function edit($id)
    {
        Gate::authorize('tenant.{slug}.update');

        $record = {Resource}::findOrFail($id);

        return view('{module}::{view-folder}.edit', compact('record'));
    }

    /**
     * Update the record.
     */
    public function update({Resource}Request $request, $id)
    {
        Gate::authorize('tenant.{slug}.update');

        $record   = {Resource}::findOrFail($id);
        $original = $record->getOriginal();
        $record->update($request->validated());

        // Track attribute changes for audit log
        $changes = [];
        foreach ($record->getChanges() as $field => $newValue) {
            if ($field === 'updated_at') continue;
            $changes[$field] = ['old' => $original[$field] ?? null, 'new' => $newValue];
        }

        activityLog($record, 'Updated', [
            'message'      => empty($changes) ? '{Resource} updated. No attributes changed.' : '{Resource} was updated.',
            'changes'      => $changes,
            'performed_by' => Auth::user()->name,
        ]);

        return redirect()
            ->route('{module}.{route-slug}.index')
            ->with('success', flash('updated.{slug}'));
    }

    /**
     * Soft delete (move to trash).
     */
    public function destroy($id)
    {
        Gate::authorize('tenant.{slug}.delete');

        $record = {Resource}::findOrFail($id);
        $record->is_active = false;
        $record->save();
        $record->delete();

        activityLog($record, 'Trashed', [
            'message'      => '{Resource} deactivated and trashed.',
            'performed_by' => Auth::user()->name,
        ]);

        return redirect()
            ->route('{module}.{route-slug}.index')
            ->with('success', flash('trashed.{slug}'));
    }

    /**
     * List all soft-deleted records.
     */
    public function trashed()
    {
        Gate::authorize('tenant.{slug}.restore');

        $records = {Resource}::onlyTrashed()->paginate(10);

        return view('{module}::{view-folder}.trash', compact('records'));
    }

    /**
     * Restore a soft-deleted record.
     */
    public function restore($id)
    {
        Gate::authorize('tenant.{slug}.restore');

        $record = {Resource}::onlyTrashed()->findOrFail($id);
        $record->restore();
        $record->is_active = true;
        $record->save();

        activityLog($record, 'Restored', [
            'message'      => '{Resource} restored.',
            'performed_by' => Auth::user()->name,
        ]);

        return redirect()
            ->route('{module}.{route-slug}.index')
            ->with('success', flash('restored.{slug}'));
    }

    /**
     * Permanently delete from trash.
     */
    public function forceDelete($id)
    {
        Gate::authorize('tenant.{slug}.forceDelete');

        $record = {Resource}::withTrashed()->findOrFail($id);
        $record->forceDelete();

        activityLog($record, 'Deleted', [
            'message'      => '{Resource} permanently deleted.',
            'performed_by' => Auth::user()->name,
        ]);

        return redirect()
            ->route('{module}.{route-slug}.index')
            ->with('success', flash('force_deleted.{slug}'));
    }

    /**
     * Toggle is_active status (AJAX).
     */
    public function toggleStatus(Request $request, $id)
    {
        Gate::authorize('tenant.{slug}.update');

        $request->validate([
            'is_active' => 'required|boolean',
        ]);

        $record = {Resource}::findOrFail($id);
        $record->is_active = $request->boolean('is_active');
        $record->save();

        activityLog($record, 'Toggled', [
            'message'      => '{Resource} status updated.',
            'performed_by' => Auth::user()->name,
        ]);

        return response()->json([
            'success'   => true,
            'is_active' => $record->is_active,
            'message'   => flash('status_updated.{slug}'),
        ]);
    }
}
```

### Controller Rules:
- **`Gate::authorize()`** MUST be the **first line** inside **EVERY method** — index, create, store, show, edit, update, destroy, trashed, restore, forceDelete, toggleStatus, and any custom methods. No exceptions.
- **ALWAYS use string-based gates**: `Gate::authorize('{module}.{resource}.{action}')` (e.g., `Gate::authorize('tenant.vendor.create')`). NEVER use policy-based forms like `Gate::authorize('create', Model::class)` or `Gate::authorize('view', $record)`.
- Always use **`$request->validated()`** — never raw `$request->input()`.
- Always call **`activityLog()`** after any create / update / delete / restore.
- **`trashed()`** uses `Gate::authorize('...restore')` — this is correct, as only users who can restore should access the trash list.
- **`toggleStatus()`** uses `Gate::authorize('...update')` — status toggle is considered an update action.

---

## 2B. Tab-Based Hub Module Pattern (Multi-Resource under One Index)

> **When to use:** When a module has **multiple sub-resources** (e.g., Vendor, Vendor Item, Vendor Agreement, Vendor Invoice) that should all be visible on **one page as tabs** — not on separate pages.
>
> **Real Example:** `Modules/Vendor` — One `VendorController::index()` loads ALL sub-resource data and passes it to `tab_module/tab.blade.php`. Each sub-resource's list is a separate partial file included inside that hub.

---

### Architecture Diagram

```
routes/web.php
└── Route::resource('vendor', VendorController::class)  ← Hub route (index = tab page)

VendorController::index()
├── Gate::any([all tabs' viewAny permissions]) || abort(403)   ← Must have at least 1 permission
├── $filters = $request->only([...])
├── $vendors           = $this->vendorsQuery($request)->paginate(10, ['*'], 'vendors_page')
├── $vendorAgreements  = $this->vendorAgreementsQuery($request)->paginate(...)
├── $vendorItems       = $this->vendorItemsQuery($request)->paginate(...)
├── ...all sub-resources...
└── return view('vendor::tab_module.tab', [...all data...])

tab_module/tab.blade.php   ← ONE hub view, renders all tabs
├── x-backend.tab.nav-tab  ← Tab nav with per-tab permissions
├── @can → @include('vendor::vendor.index')             ← Tab 1 partial
├── @can → @include('vendor::vendor-item.index')        ← Tab 2 partial
├── @can → @include('vendor::vendor-agreement.index')   ← Tab 3 partial
└── ...

vendor/index.blade.php          ← Partial: NOT a standalone page, just a <div class="tab-pane">
vendor-item/index.blade.php     ← Partial: same
vendor-agreement/index.blade.php ← Partial: same
```

---

### 2B-1. Hub Controller — `index()` + Private Query Methods

```php
public function index(Request $request)
{
    // ✅ Use Gate::any() — user must have AT LEAST ONE tab's viewAny permission
    Gate::any([
        'tenant.vendor.viewAny',
        'tenant.vendor-item.viewAny',
        'tenant.vendor-agreement.viewAny',
        'tenant.vendor-invoice.viewAny',
        'tenant.vendor-payment.viewAny',
        'tenant.usage-log.viewAny',
    ]) || abort(403);

    // Collect shared filters from request
    $filters = $request->only([
        'data_type', 'date_range', 'status', 'vendor_id',
    ]);

    // ✅ Each sub-resource has its own PRIVATE query method
    // ✅ Each uses a UNIQUE paginator name to avoid pagination conflict between tabs
    return view('vendor::tab_module.tab', [
        'filters'          => $filters,
        'vendors'          => $this->vendorsQuery($request)->paginate(10, ['*'], 'vendors_page')->withQueryString(),
        'vendorAgreements' => $this->vendorAgreementsQuery($request)->paginate(10, ['*'], 'agreements_page')->withQueryString(),
        'vendorItems'      => $this->vendorItemsQuery($request)->paginate(10, ['*'], 'items_page')->withQueryString(),
        'vendorsList'      => Vendor::get(),   // Shared reference list for dropdowns
    ]);
}

// ─── Private query helpers ──────────────────────────────────────────────────

/**
 * Only apply tab-specific filters when that tab is active.
 * This prevents cross-tab filter pollution.
 */
private function vendorsQuery(Request $request): Builder
{
    $query = Vendor::query();

    if ($request->input('tab') === 'vendor') {
        $query
            ->when($request->filled('search'), fn ($q) =>
                $q->where('vendor_name', 'like', "%{$request->search}%")
                  ->orWhere('email', 'like', "%{$request->search}%")
            )
            ->when($request->filled('status'), fn ($q) =>
                $q->where('is_active', (bool) $request->status)
            );
    }

    return $query->latest();
}

private function vendorAgreementsQuery(Request $request): Builder
{
    $query = VndAgreement::with('vendor');

    if ($request->input('tab') === 'vendor_agreement') {
        $query
            ->when($request->filled('search'), fn ($q) =>
                $q->whereHas('vendor', fn ($v) => $v->where('vendor_name', 'like', "%{$request->search}%"))
                  ->orWhere('agreement_ref_no', 'like', "%{$request->search}%")
            )
            ->when($request->filled('status'), fn ($q) =>
                $q->where('is_active', (bool) $request->status)
            );
    }

    return $query->latest();
}

// ... same pattern for each additional sub-resource
```

**Rules for private query methods:**
- Method MUST be `private` (not public — never expose as a route).
- Method MUST check `$request->input('tab') === '{tab_id}'` before applying filters.
- Use **unique paginator page names** per sub-resource (e.g., `'vendors_page'`, `'agreements_page'`) to prevent one tab's pagination from affecting another tab.
- Always end with `->latest()` for consistent ordering.

---

### 2B-2. Hub View — `tab_module/tab.blade.php`

```blade
<x-backend.layouts.app>
    <x-backend.components.breadcrum title="{Module} Master" :links="[]" />

    <div class="container-fluid">

        {{-- ✅ Tab Navigation — each tab has a permission key --}}
        <x-backend.tab.nav-tab :tabs="[
            ['id' => '{tab1_id}',  'label' => '{Tab 1 Label}',  'icon' => 'fa-solid fa-{icon}', 'permission' => 'tenant.{slug1}.viewAny'],
            ['id' => '{tab2_id}',  'label' => '{Tab 2 Label}',  'icon' => 'fa-solid fa-{icon}', 'permission' => 'tenant.{slug2}.viewAny'],
            ['id' => '{tab3_id}',  'label' => '{Tab 3 Label}',  'icon' => 'fa-solid fa-{icon}', 'permission' => 'tenant.{slug3}.viewAny'],
        ]" :active="request('tab', '{default_tab_id}')">

            {{-- ✅ Each tab body is @included ONLY if user has its viewAny permission --}}
            @can('tenant.{slug1}.viewAny')
                @include('{module}::{view-folder1}.index')
            @endcan

            @can('tenant.{slug2}.viewAny')
                @include('{module}::{view-folder2}.index')
            @endcan

            @can('tenant.{slug3}.viewAny')
                @include('{module}::{view-folder3}.index')
            @endcan

        </x-backend.tab.nav-tab>

    </div>
</x-backend.layouts.app>
```

**Rules for the hub view:**
- `x-backend.tab.nav-tab` handles tab visibility automatically using the `permission` key in each tab config.
- The `@can` check around `@include` provides **double security** — tab nav won't show it, AND the body won't render.
- The `:active="request('tab', '{default_tab_id}')"` sets the default active tab on first page load.
- Hub view does NOT have any business logic — all data comes from the controller.

---

### 2B-3. Tab Partial View — `{view-folder}/index.blade.php`

Tab partials are **NOT standalone pages**. They are `<div class="tab-pane">` divs that are included into the hub view.

```blade
{{-- begin::{Resource} Tab Body --}}
<div class="tab-pane fade p-4 bg-white rounded shadow-sm"
     id="{tab_id}-pane"
     role="tabpanel"
     aria-labelledby="{tab_id}-tab"
     tabindex="0">

    {{-- Search/Filter Bar + Add Button --}}
    <x-backend.tab.search-bar url="{module}.{route-slug}">
        <form class="d-flex align-items-center flex-grow-1 gap-2 me-3" method="GET">
            <input type="hidden" name="tab" value="{tab_id}">
            {{-- ... filters ... --}}
        </form>

        @can('tenant.{slug}.create')
        <a href="{{ route('{module}.{route-slug}.create') }}" class="btn btn-primary btn-sm">
            <i class="fa-solid fa-plus"></i> Add {Resource}
        </a>
        @endcan
    </x-backend.tab.search-bar>

    {{-- Table --}}
    <table class="table table-sm">
        {{-- ... standard table with symmetrical @can guards ... --}}
    </table>

    {{-- Pagination — MUST append tab name + use unique page name variable --}}
    <div class="row d-flex justify-content-center align-items-center my-4 px-4">
        <div class="col-sm-12">
            {{ $records->appends(['tab' => '{tab_id}'])->links() }}
        </div>
    </div>
</div>
{{-- end::{Resource} Tab Body --}}
```

**Rules for tab partial views:**
- Top-level element MUST be `<div class="tab-pane fade ...">` — never `<x-backend.layouts.app>`.
- The `id` of the pane MUST match the tab `id` defined in `x-backend.tab.nav-tab`.
- Pagination MUST use `->appends(['tab' => '{tab_id}'])` so switching pages keeps the correct tab active.
- The `<input type="hidden" name="tab" value="{tab_id}">` MUST be inside every filter form.

---

## 3. Blade Views


### 3A. Tab Hub Page (`tab.blade.php`)

Used when a module has multiple sub-resources shown as tabs on one page.

```blade
<x-backend.layouts.app>
    <x-backend.components.breadcrum title="{Module} Master" :links="[]" />

    <div class="container-fluid">
        <x-backend.tab.nav-tab :tabs="[
            ['id' => '{tab_id}',   'label' => '{Label}',  'icon' => 'fa-solid fa-{icon}', 'permission' => 'tenant.{slug}.viewAny'],
            ['id' => '{tab_id2}',  'label' => '{Label2}', 'icon' => 'fa-solid fa-{icon}', 'permission' => 'tenant.{slug2}.viewAny'],
        ]" :active="request('tab', '{default_tab}')">

            @can('tenant.{slug}.viewAny')
                @include('{module}::{view-folder}.index')
            @endcan

            @can('tenant.{slug2}.viewAny')
                @include('{module}::{view-folder2}.index')
            @endcan

        </x-backend.tab.nav-tab>
    </div>
</x-backend.layouts.app>
```

---

### 3B. Index Partial (`index.blade.php`)

Index partials are included inside a tab pane — they are NOT standalone pages.

```blade
{{-- begin::{Resource} Tab Body --}}
<div class="tab-pane fade p-4 bg-white rounded shadow-sm"
     id="{tab_id}-pane" role="tabpanel"
     aria-labelledby="{tab_id}-tab" tabindex="0">

    {{-- ================= SEARCH / FILTER BAR ================= --}}
    <x-backend.tab.search-bar url="{module}.{route-slug}">
        <form class="d-flex align-items-center flex-grow-1 gap-2 me-3" method="GET">
            <input type="hidden" name="tab" value="{tab_id}">
            <input type="text" name="search" value="{{ request('search') }}"
                class="form-control form-control-sm flex-grow-1" placeholder="Search...">

            <select name="status" class="form-select form-select-sm" style="max-width: 140px;">
                <option value="">All</option>
                <option value="1" {{ request('status') == '1' ? 'selected' : '' }}>Active</option>
                <option value="0" {{ request('status') == '0' ? 'selected' : '' }}>Inactive</option>
            </select>

            <button class="btn btn-primary btn-sm" type="submit">
                <i class="fa-solid fa-magnifying-glass"></i>
            </button>
            @if(request()->filled('search') || request()->filled('status'))
                <a href="{{ route('{module}.{route-slug}.index', ['tab' => '{tab_id}']) }}"
                   class="btn btn-secondary btn-sm" title="Clear Filter">
                    <i class="fa-solid fa-arrows-rotate"></i>
                </a>
            @endif
        </form>

        {{-- Add Button --}}
        @can('tenant.{slug}.create')
        <a href="{{ route('{module}.{route-slug}.create') }}" class="btn btn-primary btn-sm">
            <i class="fa-solid fa-plus"></i> Add {Resource}
        </a>
        @endcan
    </x-backend.tab.search-bar>

    {{-- ================= TABLE ================= --}}
    <table class="table table-sm">
        <thead class="table-light">
            <tr>
                <th>Name</th>
                <th>Other Column</th>
                {{-- ⚠️ RULE: th and td MUST have same @can wrapper --}}
                @can('tenant.{slug}.update')
                <th>Status</th>
                @endcan
                @canany(['tenant.{slug}.view', 'tenant.{slug}.update', 'tenant.{slug}.delete'])
                <th width="20">Action</th>
                @endcanany
            </tr>
        </thead>
        <tbody>
            @forelse($records as $record)
            <tr>
                <td>{{ $record->name }}</td>
                <td>{{ $record->other ?? '-' }}</td>
                @can('tenant.{slug}.update')
                <td>
                    <x-backend.table.status-switch
                        url="{module}.{route-slug}"
                        :model="$record"
                        permission="tenant.{slug}.update"
                    />
                </td>
                @endcan
                @canany(['tenant.{slug}.view', 'tenant.{slug}.update', 'tenant.{slug}.delete'])
                <td>
                    <x-backend.table.action
                        :id="$record->id"
                        url="{module}.{route-slug}"
                        :view-permission="'tenant.{slug}.view'"
                        :edit-permission="'tenant.{slug}.update'"
                        :delete-permission="'tenant.{slug}.delete'"
                    />
                </td>
                @endcanany
            </tr>
            @empty
            <tr>
                <td colspan="5" class="text-center text-muted">No records found.</td>
            </tr>
            @endforelse
        </tbody>
    </table>

    {{-- ================= PAGINATION ================= --}}
    <div class="row d-flex justify-content-center align-items-center my-4 px-4">
        <div class="col-sm-12">
            {{ $records->appends(['tab' => '{tab_id}'])->links() }}
        </div>
    </div>
</div>
{{-- end::{Resource} Tab Body --}}
```

---

### 3C. Create Page (`create.blade.php`)

Standalone page for creating a new record.

```blade
<x-backend.layouts.app>
    {{-- ================= BREADCRUMB ================= --}}
    <x-backend.components.breadcrum title="Add New {Resource}" :links="[]" />

    <div class="container-fluid">
        <div class="row">
            <div class="col-sm-12">
                <div class="card mb-4">
                    <div class="card-body">

                        {{-- ================= VALIDATION ERRORS ================= --}}
                        @if ($errors->any())
                            <div class="alert alert-danger">
                                <ul class="mb-0">
                                    @foreach ($errors->all() as $error)
                                        <li>{{ $error }}</li>
                                    @endforeach
                                </ul>
                            </div>
                        @endif

                        {{-- ================= CREATE FORM ================= --}}
                        <form method="POST" action="{{ route('{module}.{route-slug}.store') }}">
                            @csrf

                            {{-- 4-Column grid layout (col-md-3) --}}
                            <div class="row g-3">
                                <div class="col-md-3">
                                    <x-backend.form.input-text
                                        name="name" id="name"
                                        label="Name" placeholder="Enter Name"
                                        required="true"
                                        value="{{ old('name') }}"
                                    />
                                </div>

                                {{-- Status Switch --}}
                                <div class="col-md-3">
                                    <x-backend.form.status-switch :isActive="old('is_active', true)" />
                                </div>
                            </div>

                            {{-- ================= SUBMIT ================= --}}
                            <div class="mt-4">
                                <x-backend.form.button-submit title="Create {Resource}" />
                            </div>
                        </form>
                        {{-- ================= END FORM ================= --}}

                    </div>
                </div>
            </div>
        </div>
    </div>
</x-backend.layouts.app>
```

---

### 3D. Edit Page (`edit.blade.php`)

Standalone page for editing an existing record.

```blade
<x-backend.layouts.app>
    {{-- ================= BREADCRUMB ================= --}}
    <x-backend.components.breadcrum title="Edit {Resource}" :links="[]" />

    <div class="container-fluid">
        <div class="row">
            <div class="col-sm-12">
                <div class="card mb-4">
                    <div class="card-body">

                        {{-- ================= VALIDATION ERRORS ================= --}}
                        @if ($errors->any())
                            <div class="alert alert-danger">
                                <ul class="mb-0">
                                    @foreach ($errors->all() as $error)
                                        <li>{{ $error }}</li>
                                    @endforeach
                                </ul>
                            </div>
                        @endif

                        {{-- ================= EDIT FORM ================= --}}
                        <form method="POST"
                              action="{{ route('{module}.{route-slug}.update', $record->id) }}">
                            @csrf
                            @method('PUT')

                            {{-- 4-Column grid layout (col-md-3) --}}
                            <div class="row g-3">
                                <div class="col-md-3">
                                    <x-backend.form.input-text
                                        name="name" id="name"
                                        label="Name" placeholder="Enter Name"
                                        required="true"
                                        value="{{ old('name', $record->name) }}"
                                    />
                                </div>

                                {{-- Status Switch --}}
                                <div class="col-md-3">
                                    <x-backend.form.status-switch
                                        :isActive="old('is_active', (bool) $record->is_active)"
                                    />
                                </div>
                            </div>

                            {{-- ================= SUBMIT ================= --}}
                            <div class="mt-4">
                                <x-backend.form.button-submit title="Update {Resource}" />
                            </div>
                        </form>
                        {{-- ================= END FORM ================= --}}

                    </div>
                </div>
            </div>
        </div>
    </div>
</x-backend.layouts.app>
```

---

### 3E. Show / Details Page (`show.blade.php`)

Read-only view of a single record. Split into two info cards (left + right column).

```blade
<x-backend.layouts.app>
    {{-- ================= BREADCRUMB ================= --}}
    <x-backend.components.breadcrum title="{Resource} Details" :links="[]" />

    <div class="container-fluid">
        <div class="row">
            <div class="col-sm-12">
                <div class="card mb-4">

                    {{-- ================= CARD HEADER ================= --}}
                    <div class="card-header">
                        <h3 class="card-title">{Resource} Details</h3>
                        <div class="card-tools">
                            <a href="{{ route('{module}.{route-slug}.index') }}"
                               class="btn btn-sm btn-primary">
                                <i class="fas fa-arrow-left"></i> Back
                            </a>
                            @can('tenant.{slug}.update')
                            <a href="{{ route('{module}.{route-slug}.edit', $record->id) }}"
                               class="btn btn-sm btn-warning">
                                <i class="fas fa-edit"></i> Edit
                            </a>
                            @endcan
                        </div>
                    </div>

                    {{-- ================= CARD BODY ================= --}}
                    <div class="card-body">
                        <div class="row g-4">

                            {{-- LEFT INFO CARD --}}
                            <div class="col-md-6">
                                <div class="card h-100">
                                    <div class="card-header bg-light fw-bold">Basic Information</div>
                                    <div class="card-body p-0">
                                        <table class="table table-bordered table-striped mb-0">
                                            <tbody>
                                                <tr>
                                                    <th width="40%">Name</th>
                                                    <td>{{ $record->name ?? '-' }}</td>
                                                </tr>
                                                <tr>
                                                    <th>Status</th>
                                                    <td>
                                                        @if($record->is_active)
                                                            <span class="badge bg-success">Active</span>
                                                        @else
                                                            <span class="badge bg-danger">Inactive</span>
                                                        @endif
                                                    </td>
                                                </tr>
                                                <tr>
                                                    <th>Created At</th>
                                                    <td>{{ $record->created_at?->format('d M Y, h:i A') ?? '-' }}</td>
                                                </tr>
                                            </tbody>
                                        </table>
                                    </div>
                                </div>
                            </div>

                            {{-- RIGHT INFO CARD --}}
                            <div class="col-md-6">
                                <div class="card h-100">
                                    <div class="card-header bg-light fw-bold">Additional Details</div>
                                    <div class="card-body p-0">
                                        <table class="table table-bordered table-striped mb-0">
                                            <tbody>
                                                <tr>
                                                    <th width="40%">Other Field</th>
                                                    <td>{{ $record->other_field ?? '-' }}</td>
                                                </tr>
                                            </tbody>
                                        </table>
                                    </div>
                                </div>
                            </div>

                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</x-backend.layouts.app>
```

---

### 3F. Trash Page (`trash.blade.php`)

Standalone page showing soft-deleted records with restore/force-delete actions.

```blade
<x-backend.layouts.app>
    {{-- ================= BREADCRUMB ================= --}}
    <x-backend.components.breadcrum title="Trashed {Resources}" :links="[]" />

    <div class="container-fluid">
        <div class="card mb-4">
            <div class="card-body">

                {{-- ================= TABLE ================= --}}
                <div class="table-responsive">
                    <table class="table table-sm align-middle">
                        <thead class="table-light">
                            <tr>
                                <th>Name</th>
                                <th>Other Column</th>
                                <th>Status</th>
                                {{-- ⚠️ RULE: th and td MUST have same @canany wrapper --}}
                                @canany(['tenant.{slug}.restore', 'tenant.{slug}.forceDelete'])
                                <th width="130">Action</th>
                                @endcanany
                            </tr>
                        </thead>
                        <tbody>
                            @forelse ($records as $record)
                            <tr>
                                <td><strong>{{ $record->name }}</strong></td>
                                <td>{{ $record->other ?? '-' }}</td>
                                <td>
                                    <span class="badge bg-danger">Deleted</span>
                                </td>
                                @canany(['tenant.{slug}.restore', 'tenant.{slug}.forceDelete'])
                                <td>
                                    <x-backend.table.action-trashed
                                        :id="$record->id"
                                        url="{module}.{route-slug}"
                                        permissions="tenant.{slug}"
                                    />
                                </td>
                                @endcanany
                            </tr>
                            @empty
                            <tr>
                                <td colspan="4" class="text-center text-muted py-4">
                                    No trashed {resources} found.
                                </td>
                            </tr>
                            @endforelse
                        </tbody>
                    </table>
                </div>

                {{-- ================= PAGINATION ================= --}}
                @if($records->hasPages())
                    <div class="d-flex justify-content-center mt-3">
                        {{ $records->links() }}
                    </div>
                @endif

            </div>
        </div>
    </div>
</x-backend.layouts.app>
```

---

## 4. Key Rules Quick Reference

| Area | Rule |
|---|---|
| **Routes** | `Route::resource` + 4 extra routes (trashed, restore, forceDelete, toggleStatus) |
| **Controller** | `Gate::authorize()` is FIRST line in every method |
| **Controller** | Use `$request->validated()`, never raw `$request->input()` |
| **Controller** | Call `activityLog()` after every create/update/delete/restore |
| **Blade Forms** | Always use `@csrf`, edit forms use `@method('PUT')` |
| **Blade Layout** | 4-column grid (`col-md-3`) for create/edit fields |
| **Blade Layout** | `<x-backend.components.breadcrum :links="[]" />` on EVERY page — NEVER hardcode links in blade; manage via `config/breadcrumb.php` |
| **Table: Status** | `<th>` and `<td>` BOTH wrapped in same `@can('...update')` |
| **Table: Action** | `<th>` and `<td>` BOTH wrapped in same `@canany([...view, ...update, ...delete])` |
| **Table: Trash** | `<th>` and `<td>` BOTH wrapped in same `@canany([...restore, ...forceDelete])` |
| **Closing Tags** | `@can` → `@endcan`, `@canany` → `@endcanany`. Never mix. |
| **Pagination** | Always use `->appends(['tab' => '{tab_id}'])->links()` in tab-based index views |
| **Status field** | Create page: `old('is_active', true)` — Edit page: `old('is_active', (bool) $record->is_active)` |
| **show() method** | MUST render a view (`return view(...)`), NOT `redirect()->route('edit')` |
| **FormRequest** | DDL `NOT NULL` → `'required'` on create (POST). For updates (PUT/PATCH), use conditional: `$isUpdate = $this->isMethod('PUT') || $this->isMethod('PATCH')` then `$isUpdate ? ['nullable', 'integer'] : ['required', 'integer']` |
| **Session-like resources** | Resources that are append-only logs (e.g., POS Sessions) have NO edit/update — only Create, View, Close. Always `redirect()->back()` after actions. |
| **Finite State Machine (FSM)** | State transitions MUST be controlled: compute `$allowedTransitions` in controller via `match($record->status)`, pass to view dropdown, exclude current status. Terminal states have `[]` (empty array). |
| **DB ENUM alignment** | DB ENUM columns MUST match migration values exactly. DDL v1/v2 files may be outdated — always check both DDL AND latest migration file. |
