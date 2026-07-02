# Role & Permission Rules — MANDATORY

> **Gold Standard Reference:** Vendor Module (`Modules/Vendor`) is the canonical example of correctly implemented role & permission checks across all Blade views and Controllers. When in doubt, refer to Vendor Module files.

---

## 1. Permission Key Naming Convention

All permissions are **tenant-scoped** and follow the dot-separated format:

```
tenant.<module-slug>.<action>
```

### Standard Actions Per Resource

| Action         | Usage                                                  |
|----------------|--------------------------------------------------------|
| `viewAny`      | Listing / index page, tab panel visibility             |
| `view`         | Individual show / details page                         |
| `create`       | Add button, create form, store action                  |
| `update`       | Edit form, save button, status-switch toggle           |
| `delete`       | Soft delete / trash action                             |
| `restore`      | Restore from trash                                     |
| `forceDelete`  | Permanently delete from trash                          |
| `status`       | Special toggle for status columns (if separate from update) |
| `export`       | Export / Download PDF / CSV                            |
| `print`        | Print action                                           |

### Module Slug Examples

| Module                    | Slug                      | Example Permission Key                   |
|---------------------------|---------------------------|------------------------------------------|
| Vendor                    | `vendor`                  | `tenant.vendor.create`                   |
| Vendor Agreement          | `vendor-agreement`        | `tenant.vendor-agreement.update`         |
| Vendor Item               | `vendor-item`             | `tenant.vendor-item.delete`              |
| Vendor Invoice            | `vendor-invoice`          | `tenant.vendor-invoice.status`           |
| Vendor Payment            | `vendor-payment`          | `tenant.vendor-payment.forceDelete`      |
| Vendor Usage Log          | `usage-log`               | `tenant.usage-log.viewAny`               |
| Admission Cycle           | `adm-cycle`               | `tenant.adm-cycle.restore`               |
| Behavioural Assessment    | `ba-<resource>`           | `tenant.ba-rating-scale.create`          |
| Cafeteria                 | `cafeteria`               | `tenant.cafeteria.menu-categories`       |

---

## 2. Controller-Level Authorization (Gate::authorize)

Always use `Gate::authorize()` at the **start of every controller method**:

```php
use Illuminate\Support\Facades\Gate;

public function index(Request $request)
{
    Gate::authorize('tenant.vendor.viewAny');
    // ...
}

public function create()
{
    Gate::authorize('tenant.vendor.create');
    // ...
}

public function store(VendorRequest $request)
{
    Gate::authorize('tenant.vendor.create');
    // ...
}

public function show($id)
{
    Gate::authorize('tenant.vendor.view');
    // ...
}

public function edit($id)
{
    Gate::authorize('tenant.vendor.update');
    // ...
}

public function update(VendorRequest $request, $id)
{
    Gate::authorize('tenant.vendor.update');
    // ...
}

public function destroy($id)
{
    Gate::authorize('tenant.vendor.delete');
    // ...
}

public function trashed()
{
    Gate::authorize('tenant.vendor.restore');
    // ...
}

public function restore($id)
{
    Gate::authorize('tenant.vendor.restore');
    // ...
}

public function forceDelete($id)
{
    Gate::authorize('tenant.vendor.forceDelete');
    // ...
}

public function toggleStatus(Request $request, $id)
{
    Gate::authorize('tenant.vendor.update');
    // ...
}
```

---

## 3. Blade View — Gold Standard Pattern

### Rule A: Table Column Symmetry (CRITICAL ⚠️)

**ALWAYS wrap BOTH `<th>` in `<thead>` AND `<td>` in `<tbody>` in the exact same `@can` / `@canany` check.**

Hiding only the header while the body cell renders (or vice-versa) shifts all table columns and completely breaks the UI grid rendering.

#### ✅ CORRECT — Status Column
```blade
{{-- HEADER --}}
<thead>
    <tr>
        <th>Name</th>
        @can('tenant.vendor.update')
        <th>Status</th>
        @endcan
        @canany(['tenant.vendor.view', 'tenant.vendor.update', 'tenant.vendor.delete'])
        <th width="20">Action</th>
        @endcanany
    </tr>
</thead>

{{-- BODY --}}
<tbody>
    @foreach($vendors as $vendor)
    <tr>
        <td>{{ $vendor->vendor_name }}</td>
        @can('tenant.vendor.update')
        <td>
            <x-backend.table.status-switch url="vendor.vendor" :model="$vendor" permission="tenant.vendor.update" />
        </td>
        @endcan
        @canany(['tenant.vendor.view', 'tenant.vendor.update', 'tenant.vendor.delete'])
        <td>
            <x-backend.table.action :id="$vendor->id" url="vendor.vendor"
                :view-permission="'tenant.vendor.view'"
                :edit-permission="'tenant.vendor.update'"
                :delete-permission="'tenant.vendor.delete'"
            />
        </td>
        @endcanany
    </tr>
    @endforeach
</tbody>
```

#### ❌ WRONG — Status body cell NOT wrapped (bug from payment-details/index.blade.php)
```blade
{{-- HEADER is protected --}}
@can('tenant.vendor-payment.update')
<th>Status</th>
@endcan

{{-- BODY cell is NOT protected — columns shift!! --}}
<td>
    <span class="badge">{{ $pay->status }}</span>
</td>
```

---

### Rule B: Add Button — Create Permission

```blade
@can('tenant.vendor.create')
<a href="{{ route('vendor.vendor.create') }}" class="btn btn-primary btn-sm">
    <i class="fa fa-plus"></i> Add Vendor
</a>
@endcan
```

---

### Rule C: Trash Page Actions

```blade
{{-- HEADER --}}
@canany(['tenant.vendor.restore', 'tenant.vendor.forceDelete'])
<th width="130">Action</th>
@endcanany

{{-- BODY --}}
@canany(['tenant.vendor.restore', 'tenant.vendor.forceDelete'])
<td>
    <x-backend.table.action-trashed
        :id="$vendor->id"
        url="vendor.vendor"
        permissions="tenant.vendor"
    />
</td>
@endcanany
```

---

### Rule D: Closing Directive Matching (MUST follow)

| Opening        | Closing        |
|----------------|----------------|
| `@can`         | `@endcan`      |
| `@cannot`      | `@endcannot`   |
| `@canany`      | `@endcanany`   |

**NEVER** close a `@canany` block with `@endcan`. This causes rendering bugs.

---

### Rule E: Tab / Navigation Visibility

Wrap tab navigation links in `viewAny` checks:

```blade
<ul class="nav nav-tabs">
    @can('tenant.vendor.viewAny')
    <li class="nav-item">
        <a class="nav-link {{ $activeTab === 'vendor' ? 'active' : '' }}" href="?tab=vendor">
            Vendors
        </a>
    </li>
    @endcan

    @can('tenant.vendor-agreement.viewAny')
    <li class="nav-item">
        <a class="nav-link {{ $activeTab === 'vendor_agreement' ? 'active' : '' }}" href="?tab=vendor_agreement">
            Agreements
        </a>
    </li>
    @endcan
</ul>
```

### Rule G: Tab Component with Permission Key (`x-backend.tab.nav-tab`)

When using the `x-backend.tab.nav-tab` component, pass `'permission'` key in the tabs array. The component automatically hides the tab button if the user lacks that permission. Also wrap each `@include` in `@can`/`@endcan`:

```blade
<x-backend.tab.nav-tab :tabs="[
    ['id' => 'vendor',          'label' => 'Vendor',         'icon' => 'fa-solid fa-truck',                    'permission' => 'tenant.vendor.viewAny'],
    ['id' => 'vendor_item',     'label' => 'Vendor Item',   'icon' => 'fa-solid fa-cube',                     'permission' => 'tenant.vendor-item.viewAny'],
    ['id' => 'vendor_invoice',  'label' => 'Vendor Invoice','icon' => 'fa-solid fa-file-invoice-dollar',      'permission' => 'tenant.vendor-invoice.viewAny'],
]" :active="request('tab', 'vendor')">

    @can('tenant.vendor.viewAny')
    @include('vendor::vendor.index')
    @endcan
    @can('tenant.vendor-item.viewAny')
    @include('vendor::vendor-item.index')
    @endcan
    @can('tenant.vendor-invoice.viewAny')
    @include('vendor::vendor-invoice.index')
    @endcan

</x-backend.tab.nav-tab>
```

**Rules:**
- Each tab array entry MUST include `'permission' => 'tenant.<module-slug>.<action>'`
- The `x-backend.tab.nav-tab` component uses this permission to show/hide the tab button
- Also wrap the corresponding `@include` content in `@can('tenant.<module-slug>.<action>')` / `@endcan`
- Use `viewAny` for listing tabs, `create` for add buttons, etc.
- Follow the same permission key format: `tenant.<module-slug>.<action>`

---

### Rule F: Show/Detail Page Buttons

```blade
@can('tenant.vendor.update')
<a href="{{ route('vendor.vendor.edit', $vendor->id) }}" class="btn btn-warning btn-sm">
    <i class="fa fa-edit"></i> Edit
</a>
@endcan

@can('tenant.vendor.delete')
<form action="{{ route('vendor.vendor.destroy', $vendor->id) }}" method="POST" class="d-inline">
    @csrf @method('DELETE')
    <button type="submit" class="btn btn-danger btn-sm" onclick="return confirm('Sure?')">
        <i class="fa fa-trash"></i> Delete
    </button>
</form>
@endcan
```

---

## 4. Blade @can — MANDATORY in EVERY Blade File

**Every single blade file** (index, create, edit, show, trash, partials) MUST have `@can` / `@canany` checks:
- **Add/Create buttons** → `@can('{module}.{resource}.create')`
- **Edit/Update buttons** → `@can('{module}.{resource}.update')`
- **Delete buttons** → `@can('{module}.{resource}.delete')`
- **View/Show buttons** → `@can('{module}.{resource}.view')`
- **Status column** → BOTH `<th>` AND `<td>` wrapped in `@can('{module}.{resource}.update')`
- **Action column** → BOTH `<th>` AND `<td>` wrapped in `@canany(['...update', '...delete'])`
- **Trash actions** → BOTH `<th>` AND `<td>` wrapped in `@canany(['...restore', '...forceDelete'])`
- **Tab includes** → Each `@include` wrapped in `@can('{module}.{resource}.viewAny')`
- **Tab nav-tab** → `'permission'` key in each tab array entry

**Permission key format:** Follow existing module's pattern. Cafeteria uses `cafeteria.menu-items.*` (not `tenant.cafeteria.*`). Use what the existing module uses — never assume.

---

## 5. Quick Checklist Before Committing a Blade File

- [ ] Every `<th>` for Status/Action has matching permission wrapper
- [ ] Every `<td>` for Status/Action has the **exact same** permission wrapper as its `<th>`
- [ ] `@canany` is closed with `@endcanany`, NOT `@endcan`
- [ ] All add/create buttons are wrapped in `@can('...create')`
- [ ] All form submit buttons are wrapped in `@can('...create')` or `@can('...update')`
- [ ] Controller has `Gate::authorize(...)` at top of every method
- [ ] Permission key format follows existing module's convention (e.g., `cafeteria.menu-items.*` or `tenant.vendor.*`)
- [ ] Controllers, views, AND policies all use the EXACT SAME permission string (dots vs hyphens match)
- [ ] Permission string matches `permissionslist.php` exactly — that file is the SOURCE OF TRUTH, NOT the policy filename
- [ ] Policy name AND permission string BOTH use the same pluralization (e.g., `LibBooksMasterPolicy` + `tenant.lib-books-master.*` — NOT `LibBookMasterPolicy` + `tenant.lib-books-master.*`)

---
## 7. CRITICAL: Check `permissionslist.php` as Source of Truth (June 2026)

**Bug Pattern:** Policy filename and DB permission group name can diverge.

### Rules
1. **`permissionslist.php` is the source of truth** for permission strings — NOT the policy class name, NOT the `permission` key in the hub view, NOT the `@can` string in any blade file.
2. **ALWAYS cross-check every Gate::authorize string against `config/permissionslist.php`** before assuming it's correct.
3. **Policy class name pluralization can differ** from permission string pluralization. For example:
   - Policy class: `LibBookMasterPolicy` (no 's' on Book)
   - DB permission group: `lib-books-master` (with 's' on Books)
   - Correct string: `tenant.lib-books-master.*` — match permissionslist.php, NOT the class name.
4. **Hub tab views** — every `x-backend.tab.nav-tab` entry MUST have a `permission` key matching a group in `permissionslist.php`. Missing keys = all users see the tab regardless of permissions.

### Example: Library Module State After June 9 Fix
| Policy Class | permissionslist.php Group | Controller String | Status |
|---|---|---|---|
| `LibBookMasterPolicy` | `lib-books-master` | `tenant.lib-books-master.*` | ✅ Fixed |
| `LibResourceTypePolicy` | `lib-resource-types` | `tenant.lib-resource-types.*` | ✅ Fixed (`library.`→`tenant.`) |
| `LibInventoryAuditDetailPolicy` | `lib-inventory-audit-details` | `tenant.lib-inventory-audit-details.*` | ✅ Fixed (singular→plural) |
| `LibFineSlabDetailPolicy` | `lib-fine-slab-details` | `tenant.lib-fine-slab-details.*` | ✅ Fixed (mixed singular/plural) |

---
## 6. CRITICAL: Permission String Consistency — Dots vs Hyphens

### 🔴 Bug Pattern: Dots vs Hyphens Mismatch (June 2026 — 13 policies fixed)

**The most costly bug in the Cafeteria module.** Every policy file used dot-notation permissions (`cafeteria.event.meal.view`) while EVERY controller and blade view used hyphens (`cafeteria.event-meals.view`). `Gate::authorize()` never matched policy methods — access only worked via `is_super_admin` bypass in `Gate::before`.

### Rule
**Controller `Gate::authorize()` and view `@can` MUST use the EXACT SAME permission string** — no dot vs hyphen mismatches. If views use `@can('cafeteria.dietary-profiles.update')` (hyphens, plural), controller MUST use `Gate::authorize('cafeteria.dietary-profiles.update')` — NOT `cafeteria.dietary.profile.update` (dots).

Inconsistencies cause: user sees button (view allows) but gets 403 (Gate blocks), or vice versa.

### Fix Applied
- All 13 Cafeteria policies: `cafeteria.{resource}.{action}` → `cafeteria.{resource-with-hyphens}.{action}`
- `restore`/`forceDelete` changed from reusing `delete` permission to dedicated `restore`/`forceDelete` permissions

### Fix Mapping Reference
| Policy | Old (dots) | New (hyphens) |
|--------|-----------|---------------|
| MenuItemPolicy | `cafeteria.menu.item.*` | `cafeteria.menu-items.*` |
| EventMealPolicy | `cafeteria.event.meal.*` | `cafeteria.event-meals.*` |
| MealAttendancePolicy | `cafeteria.meal.attendance.*` | `cafeteria.attendance.*` |
| MealCardPolicy | `cafeteria.meal.card.*` | `cafeteria.meal-cards.*` |
| SubscriptionPlanPolicy | `cafeteria.subscription.plan.*` | `cafeteria.subscription-plans.*` |
| SubscriptionEnrollmentPolicy | `cafeteria.subscription.enrollment.*` | `cafeteria.subscription-enrollments.*` |
| DailyMenuPolicy | `cafeteria.daily.menu.*` | `cafeteria.weekly-menus.*` |
| OrderPolicy | `cafeteria.order.*` | `cafeteria.orders.*` |
| PosSessionPolicy | `cafeteria.pos.session.*` | `cafeteria.pos.*` |
| StockItemPolicy | `cafeteria.stock.item.*` | `cafeteria.stock.*` |
| SupplierPolicy | `cafeteria.supplier.*` | `cafeteria.suppliers.*` |
| FssaiRecordPolicy | `cafeteria.fssai.record.*` | `cafeteria.fssai.*` |
| DietaryProfilePolicy | `cafeteria.dietary.profile.*` | `cafeteria.dietary-profiles.*` |
