# Test Case Generation Rules — CRITICAL

> **Purpose:** Eliminate test failures caused by wrong URLs, mismatched routes, incorrect breadcrumb assumptions, and tab-based CRUD misunderstandings.
> **Golden Rule for AI Agents:** NEVER guess a URL. ALWAYS verify the exact path from `routes/web.php` or `routes/tenant.php`.

---

## 🔴 SUPREME RULE: ROUTE FILE IS THE SOURCE OF TRUTH FOR URLs

**BEFORE writing ANY test that visits a URL or sends an AJAX request, read the module's `routes/web.php` file.**

The most common test failure pattern:

```
Bug: Test calls wrong URL path for getSections endpoint.
Issue: Test uses:
  /school-setup/subject-class-mapping/get-sections/{id}
But registered route (web.php) is:
  Route::get('/class/{classId}/sections', [SubjectClassMappingController::class, 'getSections'])
Full path: /school-setup/class/{classId}/sections
Why HTTP 500: URL doesn't match any route → Laravel returns 404 page (HTML) → test expects JSON → parse failure → 500.
```

**🔴 NEVER assume a URL pattern. ALWAYS read `web.php` and construct the exact path.**

---

## 1. Architecture Overview — How Routes Work

### 1.1 Route Registration Hierarchy

```
routes/tenant.php                    ← Central tenant route group (tenancy + auth middleware)
  └── prefix='school-setup', name='school-setup.'
      └── Modules/SchoolSetup/routes/web.php    ← All school-setup routes
                                                        Route::get('/class/{classId}/sections', ...)
                                                        → Full URL: /school-setup/class/{classId}/sections
                                                        → Route name: school-setup.subject.class.section

  └── prefix='vendor', name='vendor.'
      └── Modules/Vendor/routes/web.php         ← All vendor routes
                                                        Route::resource('vendor', VendorController::class)
                                                        → Full URL: /vendor
                                                        → Route name: vendor.vendor.index

  └── prefix='cafeteria', name='cafeteria.'
      └── Modules/Cafeteria/routes/web.php      ← All cafeteria routes
                                                        Route::get('/cafeteria/menu-planning', ...)
                                                        → Full URL: /cafeteria/menu-planning
```

### 1.2 Two Path Types for Module Routes

| Type | Registration | Example |
|---|---|---|
| **Module RouteServiceProvider** | Module has own `RouteServiceProvider` with prefix + middleware | `Modules/Vendor/Providers/RouteServiceProvider.php` → prefix `vendor` |
| **Direct group in tenant.php** | Routes registered inside `tenant.php` prefix group | `SchoolSetup` routes under `prefix('school-setup')->name('school-setup.')` |

**To determine which type:**
1. Check `config/modules.php` or `modules_statuses.json` if module is active
2. Check if `Modules/{Module}/Providers/RouteServiceProvider.php` exists
3. If it has its own `RouteServiceProvider`, routes are under that module's prefix
4. If not, routes are in `routes/tenant.php` under a `prefix()` group

---

## 2. Route Pattern Categories

### 2A. Standard CRUD — Resource Route (5 Standard + 4 Extra)

**Every resource** follows this exact pattern:

```php
// In Modules/{Module}/routes/web.php:

// Route::resource provides: index, create, store, show, edit, update, destroy
Route::resource('vendor', VendorController::class);

// 4 extra routes (MUST come AFTER resource for specific paths):
Route::get('/vendor/trash/view',   [VendorController::class, 'trashed'])->name('vendor.trashed');
Route::get('/vendor/{id}/restore', [VendorController::class, 'restore'])->name('vendor.restore');
Route::delete('/vendor/{id}/force-delete', [VendorController::class, 'forceDelete'])->name('vendor.forceDelete');
Route::post('/vendor/{id}/toggle-status', [VendorController::class, 'toggleStatus'])->name('vendor.toggleStatus');
```

**Generated URL patterns (with module prefix `vendor`):**

| Route Name | HTTP Method | URL | Controller Method |
|---|---|---|---|
| `vendor.vendor.index` | GET | `/vendor` | `index()` |
| `vendor.vendor.create` | GET | `/vendor/create` | `create()` |
| `vendor.vendor.store` | POST | `/vendor` | `store()` |
| `vendor.vendor.show` | GET | `/vendor/{vendor}` | `show()` |
| `vendor.vendor.edit` | GET | `/vendor/{vendor}/edit` | `edit()` |
| `vendor.vendor.update` | PUT/PATCH | `/vendor/{vendor}` | `update()` |
| `vendor.vendor.destroy` | DELETE | `/vendor/{vendor}` | `destroy()` |
| `vendor.vendor.trashed` | GET | `/vendor/trash/view` | `trashed()` |
| `vendor.vendor.restore` | GET | `/vendor/{id}/restore` | `restore()` |
| `vendor.vendor.forceDelete` | DELETE | `/vendor/{id}/force-delete` | `forceDelete()` |
| `vendor.vendor.toggleStatus` | POST | `/vendor/{id}/toggle-status` | `toggleStatus()` |

**⚠️ Route Name Pattern:** `{module-prefix}.{route-slug}.{action}` (e.g., `vendor.vendor.index`, `cafeteria.menu-items.create`)

### 2B. Custom AJAX Endpoints

Custom AJAX endpoints are always defined **outside** `Route::resource()`:

```php
// SchoolSetup SubjectClassMapping routes:
Route::get('/class/{classId}/sections', [SubjectClassMappingController::class, 'getSections'])
    ->name('subject.class.section');

// Employee Profile:
Route::get('/employee/class/{classId}/subject-groups', [EmployeeProfileController::class, 'getSubjectGroupsByClass'])
    ->name('employee.subject-groups-by-class');

// Cafeteria Dietary Profiles:
Route::get('/cafeteria/dietary-profiles/search-students', [DietaryProfileController::class, 'studentSearch'])
    ->name('cafeteria.dietary-profiles.student-search');
```

**🔴 CRITICAL:** AJAX endpoint URLs follow **NO** predictable pattern. You MUST read `web.php` to find the exact path.

### 2C. Tab-Based Hub Pages (Multi-Resource on One Page)

Used when multiple sub-resources share one page via tabs. The hub page is a named GET route:

```php
// In Vendor routes/web.php:
// NO Route::resource for the hub — it's just:
Route::resource('vendor', VendorController::class);  // index() returns the tab hub view

// In Cafeteria routes/web.php:
Route::get('/cafeteria/menu-planning', [CafeteriaController::class, 'menuPlanning'])
    ->name('cafeteria.menu-planning');
```

**Tab hub structure:**
```
Controller::index() → view('{module}::tab_module.tab')
                    → includes {resource}/index.blade.php (tab pane partials)
```

**Test URLs for tab pages:**
```
/cafeteria/menu-planning?tab=menu-items          ← Menu Items tab
/cafeteria/menu-planning?tab=weekly-menus        ← Weekly Menus tab
/vendor?tab=vendor                               ← Vendor tab
/vendor?tab=vendor_item                          ← Vendor Item tab
```

**Tab pane HTML IDs** (used by test `waitFor('#pane-id')`):
```
#vendor-pane, #vendor_item-pane, #menu-items-pane, #weekly-menus-pane
```

---

## 3. Constructing Correct Test URLs

### 3.1 URL Construction Formula

```
Test URL = BASE_URL + MODULE_PREFIX + ROUTE_PATH
```

**Where:**
- `BASE_URL` = `$this->tenantBaseUrl` (from test setup, e.g., `http://test.localhost:8000`)
- `MODULE_PREFIX` = the prefix from `routes/tenant.php` or `RouteServiceProvider` (e.g., `/vendor`, `/cafeteria`, `/school-setup`)
- `ROUTE_PATH` = the path string from `Routes::get('/path', ...)` in `web.php`

### 3.2 Test Constants Pattern (from VendorCrudTest)

```php
class VendorCrudTest extends DuskTestCase
{
    // All paths are RELATIVE (no leading prefix — prefix comes from RouteServiceProvider)
    private const CREATE_PATH       = '/vendor/create';
    private const INDEX_PATH        = '/vendor';
    private const SHOW_BASE_PATH    = '/vendor';
    private const TRASH_PATH        = '/vendor/trash/view';
    private const TOGGLE_STATUS_PATH = '/vendor';     // POST to /vendor/{id}/toggle-status

    // For SchoolSetup (prefix added in test setup):
    // private const CREATE_PATH    = '/school-setup/school-class/create';
    // NOT '/school-class/create'
}
```

### 3.3 URL Verification Checklist

Before writing any test URL, verify against `web.php`:

| Check | Question | Action |
|---|---|---|
| Module prefix | What prefix wraps these routes? | Check `RouteServiceProvider` or `tenant.php` group |
| Exact path | What is the string in `Route::get('/path', ...)`? | Copy exact string, including `{param}` names |
| Slug naming | Is it `{route-slug}` or `{route-slug-with-hyphens}`? | Match exactly what's in `web.php` |
| Parameter name | What is the parameter name? | `{id}` vs `{vendor}` vs `{classId}` vs `{item}` |
| Method | GET, POST, PUT, DELETE? | Match in test HTTP call |
| Extra routes | Is it outside `Route::resource`? | Always check for custom routes |

### 3.4 Common URL Mistakes

| ❌ Wrong URL (Guessed) | ✅ Correct URL (Read from web.php) | Why Wrong |
|---|---|---|
| `/school-setup/subject-class-mapping/get-sections/{id}` | `/school-setup/class/{classId}/sections` | Assumed resourceful path, actual route is `/class/{classId}/sections` |
| `/vendor/{id}/restore` | `/vendor/{id}/restore` (same) | Correct — but verify method is GET not POST |
| `/cafeteria/menu-items/toggle/{id}` | `/cafeteria/menu-items/{item}/toggle-availability` | Check exact param name and action suffix |
| `/school-setup/employee/trash` | `/school-setup/employee/trash/view` | Route has `/trash/view`, not `/trash` |
| `/system-config/dropdown/create` | `/system-config/dropdown/create` | This one is correct if route is under `system-config` prefix |

---

## 4. Test URL Maps — Per Architecture Pattern

### 4.1 Standard CRUD Resource Test URLs

For a resource with slug `{slug}` under module prefix `{prefix}`:

```php
private const CREATE_PATH   = '/{slug}/create';
private const INDEX_PATH    = '/{slug}';
private const SHOW_PATH     = '/{slug}';       // + '/' . $id
private const EDIT_PATH     = '/{slug}';       // + '/' . $id . '/edit'
private const TRASH_PATH    = '/{slug}/trash/view';
```

**Test method patterns:**
```php
// Index (tab page — includes ?tab= parameter):
$this->vendorVisitPathWithAuthentication($browser, self::INDEX_PATH . '?tab=vendor', 1200);
$browser->waitFor('#vendor-pane', 12)->assertSee('Vendor Name');

// Create page:
$this->vendorVisitPathWithAuthentication($browser, self::CREATE_PATH, 900);
$browser->waitFor('form', 12)->assertSee('Add New Vendor');

// Store (POST to INDEX_PATH):
$browser->press('Create Vendor')->pause(2500);
$browser->assertPathIsNot(self::CREATE_PATH);

// Show page:
$this->vendorVisitPathWithAuthentication($browser, self::SHOW_PATH . '/' . $vendor->id, 900);
$browser->assertSee($vendor->vendor_name);

// Edit page:
$this->vendorVisitPathWithAuthentication($browser, self::SHOW_PATH . '/' . $vendor->id . '/edit', 900);
$browser->assertSee('Edit Vendor');

// Update (PUT to INDEX_PATH/{id}):
$browser->press('Update')->pause(2500);
$vendor->refresh();

// Delete (direct model call, not browser):
$vendor->delete();

// Toggle status (POST to INDEX_PATH/{id}/toggle-status):
// Done via direct model save in test
$vendor->is_active = false;
$vendor->save();
```

### 4.2 Tab-Hub Page Test URLs

Tab pages require the `?tab={tab_id}` query parameter:

| Tab ID (from `x-backend.tab.nav-tab`) | URL |
|---|---|
| `vendor` | `/vendor?tab=vendor` |
| `vendor_item` | `/vendor?tab=vendor_item` |
| `menu-items` | `/cafeteria/menu-planning?tab=menu-items` |
| `weekly-menus` | `/cafeteria/menu-planning?tab=weekly-menus` |
| `meal-cards` | `/cafeteria/meal-cards-page?tab=meal-cards` |
| `library-settings` | `/library/...?tab=library-settings` |

**Tab pane HTML IDs** are `{tab_id}-pane`:
```php
// Tab ID 'vendor' → waitFor '#vendor-pane'
// Tab ID 'menu-items' → waitFor '#menu-items-pane'
$browser->waitFor('#vendor-pane', 12);
```

**Tab ID lookup in web.php** — the tab ID matches the `'id'` key in the `x-backend.tab.nav-tab` tabs array in `tab_module/tab.blade.php`:
```blade
['id' => 'vendor_item', 'label' => 'Vendor Item', ...]
// Tab ID = 'vendor_item'
// URL param = ?tab=vendor_item
// Pane ID = #vendor_item-pane
```

### 4.3 AJAX Endpoint Test URLs

**Always use direct `$browser->visit(TENANT_URL)` or `HTTP::post()` for AJAX:**

```php
// Direct visit (for HTML responses):
$this->vendorVisitPathWithAuthentication($browser, '/cafeteria/menu-planning?tab=menu-items', 900);

// For JSON AJAX calls, use Laravel's HTTP client or direct model calls instead of browser
$response = Http::withHeaders(['X-Requested-With' => 'XMLHttpRequest'])
    ->post($this->tenantBaseUrl . '/cafeteria/menu-items/' . $item->id . '/toggle-availability');
```

---

## 5. Breadcrumb Config Rules (for Test Validation)

### 5.1 Breadcrumb Config Structure

All breadcrumb is managed in `config/breadcrumb.php` with two maps:

**`hub_map`** — Maps URL segments to parent/hub paths:
```php
'school-class' => 'school-setup/school-class',    // class/* pages → link to school-class hub
'vendor-item'  => 'vendor/vendor',                // vendor-item/* → link to vendor hub
```

**`tab_aliases`** — Maps URL segments to tab IDs when they differ:
```php
'vendor-item'  => 'vendor_item',       // URL segment 'vendor-item' → Tab ID 'vendor_item'
'subscription-plan' => 'plans',        // URL segment 'subscription-plan' → Tab ID 'plans'
'lib-authors'  => 'authors',          // URL segment 'lib-authors' → Tab ID 'authors'
```

### 5.2 Test Validation Points

When testing a tab-based page:
1. **Verify breadcrumb title** matches hub_map entry for current URL segment
2. **Verify tab exists** in `hub_map` with correct parent path
3. **Verify tab visibility** — the `permission` key in `nav-tab` controls visibility

**Common breadcrumb test failures to check:**
- New route added to module but NOT added to `config/breadcrumb.php` → breadcrumb shows wrong path
- Tab alias missing in `tab_aliases` → active tab is not highlighted on page reload
- Tab ID mismatch between blade (nav-tab array) and tab_aliases → wrong tab active

---

## 6. Test Case Writing Rules — Per Resource

### 6.1 Required Test Methods for Every CRUD Resource

| # | Test Method | What It Tests | URL |
|---|---|---|---|
| 1 | `test_{resource}_database_schema_model_and_soft_delete_trait_are_correct` | Schema columns, model table, SoftDeletes, $casts, relationships | N/A (model-only) |
| 2 | `test_{resource}_database_required_fields_reject_missing_values` | DDL NOT NULL columns reject null | N/A (model-only) |
| 3 | `test_{resource}_create_page_loads_and_displays_form` | Create page renders with form fields | `GET /{prefix}/{slug}/create` |
| 4 | `test_{resource}_create_submission_saves_and_redirects` | Form submit creates record, redirects | `POST /{prefix}/{slug}` |
| 5 | `test_{resource}_show_page_displays_details` | Show page renders record data | `GET /{prefix}/{slug}/{id}` |
| 6 | `test_{resource}_edit_page_loads_and_update_works` | Edit form renders and PUT updates | `GET /{prefix}/{slug}/{id}/edit` + `PUT /{prefix}/{slug}/{id}` |
| 7 | `test_{resource}_toggle_status_changes_active_state` | Toggle active/inactive | Direct model save (not browser) |
| 8 | `test_{resource}_trash_restore_force_delete_workflow` | Soft delete → restore → force delete | Direct model calls |
| 9 | `test_{resource}_index_tabbed_page_loads` | Index/tab page renders with tab pane | `GET /{prefix}/{slug}?tab={tab_id}` |
| 10 | `test_{resource}_validation_rejects_duplicate_unique_fields` | Unique constraint validation | `POST /{prefix}/{slug}` with duplicate |

### 6.2 Tab-Only Resources (No Create/Edit/Show Pages)

Some resources are **tab partials only** — they have NO standalone create/edit/show pages. Their CRUD is done inline or via modals:
- Vendor Dashboard (tab partial, no standalone pages)
- Usage Log (read-only tab)
- Attendance (inline mark)

**For tab-only resources:**
- Skip create/edit/show page tests
- Test inline add/edit/delete via AJAX or modal interaction
- Test data loads in the tab pane

### 6.3 Read-Only Tab Resources

Some tabs are **read-only** with NO create/edit/delete:
- Note Downloads (SyllabusBooks)
- Transaction History (Library)
- Usage Log (Vendor)

**For read-only resources:**
- Test index/tab page loads
- No create/edit/delete tests
- Test filter/search works

### 6.4 Settings / Singleton Config Resources

Some modules have a **singleton config** resource (1 row per tenant):
- SyllabusBookConfig (`slb_config`)
- Library Settings (`lib_library_config`)

**For singleton resources:**
- No create or delete tests
- Test edit form loads
- Test update works
- Test only one row exists

---

## 7. Permission String Mapping (for Test Permission Grants)

Every controller method has a `Gate::authorize()` at the top. Tests must grant these permissions:

### 7.1 Standard Permission Map

| Controller Method | Gate::authorize String | Test Must Grant |
|---|---|---|
| `index()` | `'tenant.{slug}.viewAny'` | `'tenant.{slug}.viewAny'` |
| `create()` | `'tenant.{slug}.create'` | `'tenant.{slug}.create'` |
| `store()` | `'tenant.{slug}.create'` | `'tenant.{slug}.create'` |
| `show()` | `'tenant.{slug}.view'` | `'tenant.{slug}.view'` |
| `edit()` | `'tenant.{slug}.update'` | `'tenant.{slug}.update'` |
| `update()` | `'tenant.{slug}.update'` | `'tenant.{slug}.update'` |
| `destroy()` | `'tenant.{slug}.delete'` | `'tenant.{slug}.delete'` |
| `trashed()` | `'tenant.{slug}.restore'` | `'tenant.{slug}.restore'` |
| `restore()` | `'tenant.{slug}.restore'` | `'tenant.{slug}.restore'` |
| `forceDelete()` | `'tenant.{slug}.forceDelete'` | `'tenant.{slug}.forceDelete'` |
| `toggleStatus()` | `'tenant.{slug}.update'` | `'tenant.{slug}.update'` |

### 7.2 Slug Naming Convention

| Module | Slug (in permission) | Example Permission |
|---|---|---|
| Vendor | `vendor` | `tenant.vendor.create` |
| Vendor Item | `vendor-item` | `tenant.vendor-item.update` |
| Vendor Agreement | `vendor-agreement` | `tenant.vendor-agreement.delete` |
| Menu Items | `cafeteria.menu-items` | `tenant.cafeteria.menu-items` |
| Author (SyllabusBooks) | `author` | `tenant.author.viewAny` |
| SubjectClassMapping | `subject-class-mapping` | `tenant.subject-class-mapping.viewAny` |

**🔴 CRITICAL:** The permission slug format uses **hyphens (kebab-case)**, NOT dots. It matches the URL slug, NOT the model name.

### 7.3 Permission Grant Helper (standard pattern for tests)

```php
private function vendorEnsurePermissionsExist(array $permissions): void
{
    $guard = config('auth.defaults.guard', 'web');
    foreach ($permissions as $permission) {
        try {
            \Spatie\Permission\Models\Permission::firstOrCreate([
                'name' => $permission,
                'guard_name' => $guard,
            ]);
        } catch (Throwable) {}
    }
}

private function vendorGrantPermissionsToUser(User $user): void
{
    $permissions = [
        'tenant.vendor.viewAny',
        'tenant.vendor.create',
        'tenant.vendor.view',
        'tenant.vendor.update',
        'tenant.vendor.delete',
        'tenant.vendor.restore',
        'tenant.vendor.forceDelete',
    ];
    $this->vendorEnsurePermissionsExist($permissions);
    foreach ($permissions as $permission) {
        try { $user->givePermissionTo($permission); } catch (Throwable) {}
    }
}
```

---

## 8. Dusk Test Setup Boilerplate

### 8.1 Required Test Properties

```php
private const CREATE_PATH = '/{slug}/create';
private const INDEX_PATH = '/{slug}';
private const SHOW_BASE_PATH = '/{slug}';
private const TRASH_PATH = '/{slug}/trash/view';
private const MIGRATION_FILE = 'Modules/{Module}/database/migrations/{migration_file}.php';
private const CONTROLLER_FILE = 'Modules/{Module}/app/Http/Controllers/{Controller}.php';

private ?User $adminUser = null;
private string $tenantBaseUrl = '';
private string $adminEmail = '';
private string $adminPassword = '';
```

### 8.2 Required Helper Methods (prefix-named)

```php
// setUp/tearDown, authenticate, visit, url, currentPath, initializeTenancy
// resolveAdminUser, grantPermissions, ensurePermissionsExist
// createRecord, forceDeleteRecord, generateUniqueSuffix
// assertDatabaseRejectsMissingField
```

**Naming convention:** Prefix ALL helper methods with `{module_prefix}` (e.g., `vendorAuthenticateBrowserSession`, `schoolSetupAuthenticate`).

---

## 9. URL Verification Checklist (BEFORE Writing Any Test)

Before writing ANY test method that accesses a URL:

- [ ] **Read `routes/web.php`** — find the exact path string for the route
- [ ] **Determine module prefix** — check `RouteServiceProvider` or `tenant.php` group
- [ ] **Construct full URL** = `BASE + PREFIX + PATH`
- [ ] **Identify HTTP method** — GET, POST, PUT, DELETE
- [ ] **Check param names** — `{id}` vs `{vendor}` vs `{classId}` vs `{item}`
- [ ] **Check tab ID** — if tab page, verify `?tab={tab_id}` from `tab.blade.php`
- [ ] **Check pane ID** — `#vendor-pane` = `{tab_id}-pane`
- [ ] **Check permission string** — verify `Gate::authorize()` in controller matches `$user->givePermissionTo()`
- [ ] **Check breadcrumb config** — add route to `config/breadcrumb.php` if missing

---

## 10. DDL / Schema Verification Rules for Tests

### 10.1 Schema Assertions Pattern

```php
public function test_vendor_database_schema_model_and_soft_delete_trait_are_correct(): void
{
    // 1. Table exists
    $this->assertTrue(Schema::hasTable('vnd_vendors'), 'Table does not exist.');

    // 2. All expected columns exist
    $this->assertTrue(Schema::hasColumns('vnd_vendors', [
        'vendor_name', 'contact_person', 'contact_number', 'is_active', 'deleted_at',
    ]), 'Expected columns are missing.');

    // 3. Migration file exists and has correct schema
    $migrationContent = File::get(base_path(self::MIGRATION_FILE));
    $this->assertStringContainsString("Schema::create('vnd_vendors'", $migrationContent);
    $this->assertStringContainsString('$table->softDeletes()', $migrationContent);

    // 4. Controller file has SoftDeletes reference
    $controllerContent = File::get(base_path(self::CONTROLLER_FILE));
    $this->assertStringContainsString('public function destroy(Vendor $vendor)', $controllerContent);

    // 5. Model has proper table name
    $model = new Vendor();
    $this->assertSame('vnd_vendors', $model->getTable());

    // 6. Model uses SoftDeletes trait
    $this->assertContains(SoftDeletes::class, class_uses_recursive(Vendor::class));

    // 7. is_active is cast to boolean
    $this->assertSame('boolean', $model->getCasts()['is_active'] ?? null);

    // 8. Model has correct Eloquent relationships
    $this->assertInstanceOf(BelongsTo::class, $model->vendorType());
    $this->assertInstanceOf(HasMany::class, $model->invoices());
}
```

### 10.2 Required Field Rejection Test Pattern

```php
public function test_vendor_database_required_fields_reject_missing_values(): void
{
    $fieldsToValidate = ['vendor_name', 'contact_person', 'contact_number'];

    foreach ($fieldsToValidate as $field) {
        $this->vendorAssertDatabaseRejectsMissingField($field);
    }
}

private function vendorAssertDatabaseRejectsMissingField(string $missingField): void
{
    $created = null;
    try {
        $payload = [ /* all required fields */ ];
        unset($payload[$missingField]);

        $created = Vendor::query()->create($payload);
        $this->fail("Expected DB rejection for missing field {$missingField}, but insert succeeded.");
    } catch (Throwable $exception) {
        $message = strtolower($exception->getMessage());
        $isExpected = str_contains($message, 'cannot be null')
            || str_contains($message, 'not null')
            || str_contains($message, "doesn't have a default value")
            || str_contains($message, 'integrity constraint')
            || str_contains($message, 'constraint failed')
            || str_contains($message, '23000');
        $this->assertTrue($isExpected, "Expected DB required-field failure for {$missingField}, got: {$exception->getMessage()}");
    } finally {
        if ($created) { $this->vendorForceDeleteRecordByIdIfExists($created->id); }
    }
}
```

---

## 11. Unique Constraint Validation in Tests

### 11.1 FormRequest Unique Rule Pattern

```php
// In FormRequest:
'name' => [
    'required',
    'string',
    'max:100',
    Rule::unique('vnd_vendors', 'name')
        ->ignore($recordId)
        ->whereNull('deleted_at'),
],
```

### 11.2 Test Unique Constraint

```php
public function test_vendor_validation_rejects_duplicate_name(): void
{
    $vendorTypeId = $this->vendorResolveVendorTypeIdOrSkip();
    $name = 'Unique Vendor ' . $this->vendorGenerateUniqueSuffix();

    // Create first record
    $first = $this->vendorCreateRecordDirectly($vendorTypeId, ['vendor_name' => $name]);
    try {
        // Attempt duplicate — should fail
        $this->expectException(QueryException::class);
        Vendor::create([
            'vendor_name' => $name,
            'vendor_type_id' => $vendorTypeId,
            'contact_person' => 'Test',
            'contact_number' => '9000000000',
            'is_active' => true,
        ]);
    } finally {
        $this->vendorForceDeleteRecordByIdIfExists((int) $first->id);
    }
}
```

---

## 12. Test Class Structure Template

```php
<?php

namespace Tests\Browser\Modules\{Module}\{Resource};

use Modules\SchoolSetup\Models\User;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Schema;
use Laravel\Dusk\Browser;
use Modules\Prime\Models\Domain;
use Modules\{Module}\Models\{Resource};
use Spatie\MediaLibrary\InteractsWithMedia;
use Tests\DuskTestCase;
use Throwable;

class {Resource}CrudTest extends DuskTestCase
{
    // ─── URL CONSTANTS (READ FROM routes/web.php) ─────────────────────────
    private const CREATE_PATH = '/{slug}/create';
    private const INDEX_PATH = '/{slug}';
    private const SHOW_BASE_PATH = '/{slug}';
    private const TRASH_PATH = '/{slug}/trash/view';
    private const TOGGLE_STATUS_PATH = '/{slug}';  // POST to /{slug}/{id}/toggle-status
    private const MIGRATION_FILE = 'Modules/{Module}/database/migrations/...';
    private const CONTROLLER_FILE = 'Modules/{Module}/app/Http/Controllers/{Resource}Controller.php';

    private ?User $adminUser = null;
    private string $tenantBaseUrl = '';
    private string $adminEmail = '';
    private string $adminPassword = '';

    // ─── SETUP / TEARDOWN ─────────────────────────────────────────────────
    protected function setUp(): void
    {
        parent::setUp();
        $this->tenantBaseUrl = rtrim(env('DUSK_TENANT_URL', env('APP_URL', 'http://test.localhost:8000')), '/');
        $this->adminEmail = (string) env('DUSK_ADMIN_EMAIL', 'root@tenant.com');
        $this->adminPassword = (string) env('DUSK_ADMIN_PASSWORD', 'password');
        $this->{prefix}InitializeTenantContext();
        $this->{prefix}ResolveAdminUserAndPermissions();
    }

    protected function tearDown(): void
    {
        if (function_exists('tenancy') && tenancy()->initialized) {
            tenancy()->end();
        }
        parent::tearDown();
    }

    // ─── TEST METHODS ─────────────────────────────────────────────────────
    // 1. Schema + Model test
    // 2. Required field rejection test
    // 3. Create page loads test
    // 4. Create submission test
    // 5. Show page test
    // 6. Edit + Update test
    // 7. Toggle status test
    // 8. Trash/Restore/ForceDelete test
    // 9. Index tabbed page test
    // 10. Unique constraint test (if applicable)

    // ─── HELPER METHODS ───────────────────────────────────────────────────
    // All prefixed with {prefix} to avoid collision
}
```

---

## 13. Quick Reference: URL Pattern Verification Table

| Module | Route Slug | Full URL (with prefix) | Route Name |
|---|---|---|---|
| Vendor | `vendor` | `/vendor` | `vendor.vendor.index` |
| Vendor | `vendor/create` | `/vendor/create` | `vendor.vendor.create` |
| Vendor | `vendor/{vendor}` | `/vendor/{id}` | `vendor.vendor.show` |
| Vendor | `vendor/{vendor}/edit` | `/vendor/{id}/edit` | `vendor.vendor.edit` |
| Vendor | `vendor/{id}/toggle-status` | `/vendor/{id}/toggle-status` | `vendor.vendor.toggleStatus` |
| Vendor | `vendor-item` | `/vendor-item` | `vendor.vendor-item.index` |
| SchoolSetup | `school-class` | `/school-setup/school-class` | `school-setup.school-class.index` |
| SchoolSetup | `class/{classId}/sections` | `/school-setup/class/{classId}/sections` | `school-setup.subject.class.section` |
| Cafeteria | `cafeteria/menu-planning` | `/cafeteria/menu-planning` | `cafeteria.menu-planning` |
| Cafeteria | `cafeteria/menu-items` | `/cafeteria/menu-items` | `cafeteria.menu-items.index` |
| Cafeteria | `cafeteria/menu-items/{item}/toggle-availability` | `/cafeteria/menu-items/{id}/toggle-availability` | `cafeteria.menu-items.toggle-availability` |

---

## 14. Common Failure Patterns & Fixes

| Failure | Root Cause | Fix |
|---|---|---|
| `Expected 200, got 404` | URL path wrong in test | Read `web.php`, construct correct path |
| `Expected JSON, got HTML (404 page)` | AJAX URL doesn't match any route | Check route exists, check method (GET vs POST) |
| `Undefined variable: $records` | Tab pane partial expects variable from hub controller | Test via hub URL with `?tab=` not standalone URL |
| `No such table: vnd_vendors` | Tenancy not initialized before DB query | Call `{prefix}InitializeTenantContext()` in setUp |
| `403 Forbidden` | Missing permission grant | Add permission to `vendorGrantPermissionsToUser()` |
| `Breadcrumb shows wrong page` | Route not in `config/breadcrumb.php` | Add entry to `hub_map` in `config/breadcrumb.php` |
| `Tab not visible` | `permission` key missing in `nav-tab` | Add `'permission' => 'tenant.{slug}.viewAny'` to tabs array |
| `Undefined array key "tab"` | Tab partial accessed directly not via hub | Always use hub URL + `?tab=` parameter |
| `Route [resource.index] not defined` | Route name mismatch | Check route name ends with correct action (e.g., `vendor.vendor.index`) |
| `MethodNotAllowedHttpException` | Wrong HTTP method for route | Check if route is GET, POST, PUT, DELETE in `web.php` |

---

> **🔴 FINAL RULE:** When in doubt about ANY URL, route name, permission string, tab ID, or pane ID — read the actual source file. Never guess. The route file (`routes/web.php`), the tab hub view (`tab_module/tab.blade.php`), and the breadcrumb config (`config/breadcrumb.php`) are the three sources of truth.
