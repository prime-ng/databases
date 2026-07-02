# CRUD UI Rules — MANDATORY

> 📄 **Full Gold-Standard CRUD Code Templates (Routes + Controller + All Blade Views)**: See `rules/crud-patterns.md`.
> 📄 **Tab-Based Hub Module Pattern** (one index → private queries → hub view → partials): See `rules/crud-patterns.md` **Section 2B**.
> This file contains the abstract UI rules. `crud-patterns.md` has the actual copy-paste code templates.

## Standard CRUD UI, Component & Coding Patterns

This document defines the strict UI and Blade component patterns to be used across all CRUD operations (Index, Create, Edit, Show, Trash) in the application, along with essential controller and model coding practices. Always default to these patterns when generating new modules or updating existing ones.

## 0. General Coding Rules
- **Model Imports (CRITICAL):** Whenever you reference a Model, Request, Service, or any class in a Controller or any other file, **you MUST explicitly add the `use` import statement at the top of the file** defining its base path (e.g., `use App\Models\User;` or `use Modules\Admission\Models\AdmissionCycle;`). Never assume it is already imported or globally available.

## 1. Global Layout & Structure
- **Layout:** Always extend the standard backend layout: `<x-backend.layouts.app>`.
- **Breadcrumbs:** ALWAYS use `<x-backend.components.breadcrum title="Page Title" :links="[]" />` — `:links` array MUST be **empty** `[]`. NEVER hardcode route links inside blade. Breadcrumb is managed centrally via `config/breadcrumb.php` (hub_map + tab_aliases). If a new route needs breadcrumb support, add it there, NOT in the blade file.
- **Main Container:** Wrap the entire content in `<div class="container-fluid">`.

## 1B. Tab-Based Hub Module (Multi-Resource on One Page)
- Use when a module has multiple related sub-resources that belong on one tabbed page (e.g., Vendor, Vendor Item, Vendor Agreement all on `/vendor`).
- **Hub Controller `index()`** loads ALL sub-resource data via private query helper methods and passes them all to one hub view.
- **Hub View** (`tab_module/tab.blade.php`) uses `<x-backend.tab.nav-tab :tabs="[...]" :active="request('tab', 'default')">` to render tab navigation with per-tab permission keys.
- **Tab Partials** (`{resource}/index.blade.php`) are simple `<div class="tab-pane fade ...">` partials — NOT standalone full pages.
- **Security:** Both `x-backend.tab.nav-tab` (hides nav item) AND `@can ... @include` (prevents rendering body) provide double-layer tab security.
- **Private Query Rules:** Each private query method MUST check `$request->input('tab') === '{tab_id}'` before applying filters. Use unique paginator names per tab (`'vendors_page'`, `'items_page'`) to avoid cross-tab pagination conflicts.
- **Pagination in partials:** Always use `->appends(['tab' => '{tab_id}'])->links()` and include `<input type="hidden" name="tab" value="{tab_id}">` in every filter form.
- 📄 See `rules/crud-patterns.md` **Section 2B** for the full code template.

## 2. Index Page (Listing)
- **Search Bar / Tab Header:** Use `<x-backend.tab.search-bar>` for the top action bar (search input, filters, create button/modal trigger).
- **Table Container:** Use `<div class="table-responsive">`.
- **Table Classes:** `<table class="table table-sm align-middle">` with `<thead class="table-light">`.
- **Status Badges:** Use subtle background colors with borders for statuses. 
  - *Active/Success:* `bg-success-subtle text-success border-success border rounded-pill`
  - *Inactive/Error:* `bg-danger-subtle text-danger border-danger border rounded-pill`
  - *Pending/Draft:* `bg-secondary-subtle text-secondary border-secondary border rounded-pill`
- **Action Column:** Use the standard action component where possible:
  `<x-backend.table.action :id="$model->id" url="module.route" view-permission="..." edit-permission="..." delete-permission="..." />`
- **Pagination:** Center the pagination links beneath the table.
  ```blade
  @if(method_exists($models, 'links'))
      <div class="d-flex justify-content-center mt-3">
          {{ $models->appends(request()->query())->links() }}
      </div>
  @endif
  ```

## 3. Create & Edit Pages (Dedicated Route Pattern)
- **Grid Layout:** Typically divide the screen into `col-md-8` (Main Form/Details) and `col-md-4` (Sidebar/Actions & Metadata).
- **Form Sections (Cards):** Group related fields into cards: `<div class="card shadow-sm border-0 mb-4">`.
- **Card Header:** `<div class="card-header bg-white py-3 border-bottom"><h6 class="card-title mb-0 fw-bold"><i class="fa-solid fa-icon me-2 text-primary"></i>Section Name</h6></div>`
- **Form Groups:** Use `<div class="row g-3">` inside the card body.
- **Labels & Fields:** 
  - `<label class="form-label fw-semibold">Field Name</label>`
  - Append `<span class="text-danger">*</span>` for required fields.
- **Form Controls:** Use `.form-control` or `.form-select`. Remember to re-populate using `value="{{ old('field', $model?->field) }}"`.
- **Sidebar Actions (col-md-4):**
  - Group submit and cancel buttons in a `<div class="d-grid gap-2">`.
  - Save/Update Button: `<button type="submit" class="btn btn-warning"><i class="fa-solid fa-floppy-disk me-2"></i>Save</button>` (Use `btn-primary` for Create, `btn-warning` for Update). **Use default/medium size — NO `btn-lg` or `btn-sm`.**
  - Cancel Button: `<a href="..." class="btn btn-light">Cancel</a>` — default size, no `btn-lg`.

## 4. View / Show Page
- **Grid Layout:** Similar to Create/Edit (`col-md-8` for Details, `col-md-4` for Actions).
- **Details Card:** 
  - Card Header to include Record ID/Status on the right side.
  - Value display styling: 
    ```blade
    <div class="col-md-6">
        <label class="text-muted small">Field Name</label>
        <div class="fw-medium">{{ $model->value ?? '-' }}</div>
    </div>
    ```
- **Actions Sidebar (col-md-4):**
  - Card Header: `<i class="fa-solid fa-bolt me-2 text-muted"></i>Actions`
  - Stack buttons using `<div class="card-body d-flex flex-column gap-2">`.
  - Button styling: Edit (`btn-outline-warning`), Proceed/Approve (`btn-success`), Decline/Reject (`btn-outline-danger`), Back (`btn-outline-secondary`). Ensure buttons use `.w-100`.
  - **All sidebar action buttons use default/medium size — NO `btn-lg` or `btn-sm`.** Big buttons look disproportionate in the sidebar.

## 5. Trash Page
- Similar to the standard Index page table structure.
- **Actions:** Provide specific Restore and Force-Delete buttons via standard forms (POST/DELETE methods with CSRF tokens). Use confirmation dialogues (`onclick="return confirm('...')"`).

## 6. Modals (Alternative UI for Quick Create/Edit)
When sticking to a single-page setup (e.g. Setup/Config modules):
- Container: `<div class="modal fade" id="..." tabindex="-1" aria-hidden="true">`
- Header: `.modal-header` with a `.modal-title` containing an icon.
- Body: Wrap fields in `.row.g-3`.
- Footer: `.modal-footer` with Cancel (`btn-light`) and Submit (`btn-primary`/`btn-warning`) buttons.
- Use Vanilla JS `fetch()` to handle AJAX submission and SweetAlert2 (`Swal.fire`) for notifications. Reload the page on success unless strict DOM manipulation is required.

## 7. Component Usage Pattern — How to Call Components

### 7a. x-backend.form.input-text (VERBATIM from Vendor create.blade.php)
```blade
<x-backend.form.input-text
    type="text"          {{-- REQUIRED: 'text', 'number', 'email', etc. No default. --}}
    name="field_name"
    id="field_name"
    label="Field Label"
    placeholder="Enter value"
    required="true"      {{-- or omit for optional --}}
    value="{{ old('field_name') }}"
/>
```
- **`type` is REQUIRED** — the constructor has `string $type` with NO default value. Missing it causes `Unresolvable dependency resolving [Parameter #0 [ <required> string $type ]]`.
- Always pass `type` as the first attribute for clarity (matching Vendor module pattern).
- For number fields: `type="number"` on InputText, not `x-backend.form.input-number`.

### 7b. x-backend.form.input-textarea (VERBATIM from Vendor create.blade.php)
```blade
<x-backend.form.input-textarea
    name="field_name"
    id="field_name"
    placeholder="Enter text"
    label="Field Label"
    :required="true"
    value="{{ old('field_name') }}"
/>
```
- Only `name` is required; all other params have defaults.

### 7c. x-backend.form.form-dropdown (VERBATIM from Vendor create.blade.php)
```blade
<x-backend.form.form-dropdown
    key="table.column"   {{-- e.g., vnd_vendors.vendor_type_id --}}
    name="field_name"
    label="Field Label"
/>
```

### 7d. x-backend.form.status-switch (VERBATIM from Vendor create.blade.php)
```blade
<x-backend.form.status-switch
    :isActive="old('is_active', true)"
/>
```

### 7e. x-backend.form.button-submit (VERBATIM from Vendor create.blade.php)
```blade
<x-backend.form.button-submit title="Button Text" />
```

### 7f. x-backend.tab.nav-tab (VERBATIM from Vendor tab.blade.php)
```blade
<x-backend.tab.nav-tab :tabs="[
    ['id' => 'tab_id', 'label' => 'Tab Label', 'icon' => 'fa-solid fa-icon', 'permission' => 'module.resource.action'],
]" :active="request('tab', 'default_tab')">
    @can('module.resource.action')
        @include('module::resource.index')
    @endcan
</x-backend.tab.nav-tab>
```
- Nav-tab uses SLOT (wraps content) — NOT self-closing.
- Double security: `permission` key in tabs array hides nav item + `@can` prevents body rendering.
- Each tab content is a separate included file under `@can`.

## 7g. SweetAlert Confirm Dialog Pattern

```blade
<form action="{{ route('{resource}.destroy', $item) }}" method="POST" class="confirm-action"
      data-confirm="Delete this record?">
    @csrf @method('DELETE')
    <button type="submit" class="btn btn-danger">Delete</button>
</form>
```

**Handler (add via `@push('scripts')`):**
```javascript
$(document).on('submit', '.confirm-action', function(e) {
    e.preventDefault();
    var form = this;
    var message = $(this).data('confirm') || 'Are you sure?';
    Swal.fire({
        title: 'Confirm', text: message, icon: 'warning',
        showCancelButton: true, confirmButtonColor: '#d33',
        confirmButtonText: 'Yes', cancelButtonText: 'Cancel'
    }).then((result) => {
        if (result.isConfirmed) form.submit();
    });
});
```

## 7h. Student Name Display Pattern

In table cells and show pages, display student name with ID below (not just the raw ID):
```blade
{{ $record->student?->first_name }} {{ $record->student?->last_name }}<br>
<small class="text-muted">#{{ $record->student_id }}</small>
```

**Must eager-load:**
```php
$query->with('student')  // or ->load('student')
```

Applies to all models with `student_id` FK (orders, dietary-profiles, attendance, pos-transactions, etc.)

## 8. STRICT NO-MODIFY RULE
- **🚫 NEVER modify any component file — EVER.** This includes:
  - All `<x-backend.*>` core components
  - All `<x-frontend.*>` components
  - Any custom component files under `resources/views/components/`
  - Module-level components under `Modules/*/resources/views/components/`
- **Reason:** Components are shared across ALL modules. Changing one breaks others.
- **What to do instead:** If functionality is missing, handle it in the Blade view directly (inline HTML/JS) or use the component's existing props. Never edit the component file itself.
- **No exceptions.** Even for small CSS/JS tweaks — keep changes in the view file.

## 9. Canonical Module References

| Pattern | Reference Module |
|---|---|
| Full Tab-Based Hub (multi-resource on one tabbed page) | `Modules/Vendor` — `VendorController` + `tab_module/tab.blade.php` |
| Standard CRUD (single resource) | `Modules/Vendor` — `VndItemController` + `vendor-item/*.blade.php` |
| Role & Permission checks in Blade | `Modules/Vendor` — all `index.blade.php` and `trash.blade.php` files |
| activityLog, Gate::authorize, $request->validated() | `Modules/Vendor` — `VendorController`, `VndItemController` |

---

## 10. Standard Dashboard Design Pattern (MANDATORY)

Every dashboard built or refactored in the application **MUST** follow a strict layout and visualization pattern inspired by the gold standard `Modules/Cafeteria` dashboard:

### 10a. Layout Architecture (Top to Bottom)
1. **Top Row (KPI Stats):** 
   - Use exactly 4 columns (`col-xl-3 col-md-6`).
   - Cards must be borderless (`border-0 shadow-sm h-100`).
   - Icons must be wrapped in a subtle background colored circle (`bg-*-subtle rounded-circle d-flex align-items-center justify-content-center` with dimensions `width:56px;height:56px;`).
   - Values must use prominent bold styling (`fs-2 fw-bold text-dark`), and labels must be small and muted (`text-muted small`).
   - Do **NOT** put view or action buttons inside the KPI cards. Keep them pure, compact statistic tiles.

2. **Middle Row (Chart & Quick Links - Grid Ratio `col-md-8` / `col-md-4`):**
   - **Left Column (`col-md-8`):** Render a single, beautiful, spacious Chart (e.g. Daily Trend or category metrics) inside a borderless shadow card. Keep the canvas clean and readable.
   - **Right Column (`col-md-4`):** Render a dedicated **Quick Actions** card. This card must contain a vertical stack of button links (`btn-outline-*`) navigating directly to major sub-modules.

3. **Bottom Row (Two Side-by-Side Tables - Grid Ratio `col-md-6` / `col-md-6`):**
   - Render exactly **two tables** placed side-by-side. **NEVER** render three tables in a single row to avoid visual clutter and cramped cells.
   - Each table card must have a clean header (`bg-white border-bottom py-3`), featuring a representative icon on the left and a right-aligned "View All →" badge button/link on the right.
   - Limit columns to the most essential fields (e.g., Name, Type, Time, Status) with standard status badges. Eager-load relations to prevent N+1 queries.
   - Wrap table bodies in `@forelse` and `@empty` statements providing friendly fallback empty states (`No records found`).

### 10b. Scripting & Visual Fallbacks
- **🚫 NO `@push('scripts')` WRAPPER:** Never wrap dashboard scripts inside `@push('scripts')` and `@endpush` (unless explicitly requested). Place scripts inline at the very bottom of the view, directly inside the `<x-backend.layouts.app>` layout container tag.
- **DOMContentLoaded Wrapper:** Always enclose all custom JavaScript initialization and Chart.js code inside a `document.addEventListener('DOMContentLoaded', function() { ... });` block to guarantee deferred, clean execution.
- **Rich Aesthetic Fallbacks:** If the database contains zero visitor or activity records, **always** configure premium mock/demonstration datasets to populate the chart. This keeps the dashboard visually engaging and premium upon first load, and seamlessly transitions to live database values once the user adds new records.
- **Gradients and Curated Colors:** Use curated color palettes (indigo, soft violet, emerald, sky blue, amber) rather than plain generic browser primary colors. Enable standard options like `borderRadius: 6` on bar charts for a sleek, premium product feel.
