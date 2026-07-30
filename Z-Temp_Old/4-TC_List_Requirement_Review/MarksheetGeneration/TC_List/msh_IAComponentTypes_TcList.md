# IA Component Types — TC_List

---

## 1. Feature Information

| Attribute | Details |
|-----------|---------|
| **Module** | Marksheet Generation (MSH) |
| **Entity** | IA Component Type (`msh_ia_component_types`) |
| **Controller** | `Modules\MarksheetGeneration\Http\Controllers\IaComponentTypeController` — 8 methods (store, show, update, destroy, toggleStatus, trashed, restore, forceDelete) — ⚠️ NO `index()` or `create()` methods; listing via `MarksheetGenerationController::configuration()` |
| **Tab Container Controller** | `MarksheetGenerationController::configuration()` — tab id `ia-component-types`, private `applyFilters()` helper for listing |
| **Model** | `Modules\MarksheetGeneration\Models\IaComponentType` — SoftDeletes, 3 relationships |
| **Form Request** | `Modules\MarksheetGeneration\Http\Requests\IaComponentTypeRequest` — 5 validation rules + `prepareForValidation` |
| **Service** | **None** — all DB operations performed directly on the model (no service layer) |
| **Policy** | `IaComponentTypePolicy` — 8 permission methods: `viewAny`, `view`, `create`, `update`, `delete`, `restore`, `forceDelete` |
| **Route Prefix** | `marksheet-generation.ia-component-type.*` (resource `only: store,show,update,destroy`) + `trashed`, `restore`, `forceDelete`, `toggleStatus` via modal entities loop |
| **Blade Views** | `_ia-component-types.blade.php` (tab partial), `modals/ia-component-type-create.blade.php`, `modals/ia-component-type-edit.blade.php`, `trashed/ia-component-type.blade.php` |
| **Tab Container** | `pages/configuration.blade.php` — tab id `ia-component-types`, permission `tenant.msh-ia-component-type.view` |
| **DB Table** | `msh_ia_component_types` — 9 data columns + 3 timestamp columns |
| **Primary Screen** | Marksheet Generation → Configuration → IA Component Types tab (paginated, searchable, status-filtered, modal CRUD) |

---

## 2. Pre-conditions

| # | Pre-condition |
|---|--------------|
| PC-01 | User must be logged in as Examination Coordinator (or role with `tenant.msh-ia-component-type.*` permissions) |
| PC-02 | Database `msh_ia_component_types` table must exist with all 9 data columns |
| PC-03 | `msh_template_ia_components` table must exist with FK `ia_component_type_id` referencing `msh_ia_component_types.id` |
| PC-04 | `sys_users` table must have at least one user for `created_by` / `updated_by` FK |
| PC-05 | `IaComponentTypeController` must be registered in module routes with `only: ['store', 'show', 'update', 'destroy']` |
| PC-06 | `IaComponentTypePolicy` must be registered in `AuthServiceProvider` |
| PC-07 | IA Component Types tab must be included in `configuration.blade.php` with `@can('tenant.msh-ia-component-type.view')` guard |
| PC-08 | Soft deletes must be enabled on `msh_ia_component_types` (`deleted_at` column) |
| PC-09 | Browser must support JavaScript for modal forms, status toggle, SweetAlert confirmations |
| PC-10 | No service layer dependency — controller directly calls `IaComponentType::create()`, `$model->update()`, `$model->delete()` |

---

## 3. Default Data Load

| # | Data Load Rule | Source |
|---|----------------|--------|
| DL-01 | Load IA component types with pagination (15 per page) via `configuration() → applyFilters()` | `MarksheetGenerationController.php:80` — `IaComponentType::query()->...->paginate(15, ['*'], 'iact_page')` |
| DL-02 | No eager loading needed — IA component types have no direct relations displayed in table | `MarksheetGenerationController.php:80` — bare `IaComponentType::query()` |
| DL-03 | Search filters: `?search=` (Code, Name) and `?status=` only when tab is `ia-component-types` | `MarksheetGenerationController.php:80` — `$tab === 'ia-component-types'` conditional |
| DL-04 | Tab partial loads via `@include('..._ia-component-types')` inside `@can('tenant.msh-ia-component-type.view')` | `configuration.blade.php:24-26` |
| DL-05 | List columns displayed: **#**, **Code**, **Name**, **Description**, **Status**, **Actions** | `_ia-component-types.blade.php:36-46` |
| DL-06 | Description truncated to 50 chars via `Str::limit($row->description, 50)` | `_ia-component-types.blade.php:54` |
| DL-07 | Status column uses `<x-backend.table.status-switch>` | `_ia-component-types.blade.php:57` |
| DL-08 | Action column uses `<x-backend.table.action>` with `editOnclick` JS function `editIaComponentType()` | `_ia-component-types.blade.php:62` |
| DL-09 | Pagination linked with `->appends(request()->query())` | `_ia-component-types.blade.php:70` |
| DL-10 | Empty state: "No IA Component Types Found" | `_ia-component-types.blade.php:23-29` |
| DL-11 | No `index()` or `create()` in controller — listing/modal rendering is hub's responsibility | `IaComponentTypeController.php` has no index/create methods |
| DL-12 | Create/Edit modals loaded in `configuration.blade.php` via `@include` | `configuration.blade.php:43-44` |

---

## 4. Test Data Strategy

| # | Data Strategy | Details |
|---|---------------|---------|
| TD-01 | **Valid IA Component Type** | `code='NOTEBOOK'`, `name='Notebook Maintenance'`, `description='Evaluation of notebook regularity'`, `display_order=1`, `is_active=true` |
| TD-02 | **Duplicate Code** | Create second type with same `code='NOTEBOOK'` — expects unique violation |
| TD-03 | **Missing Required Fields** | Submit without `code`, `name` — expects validation failures |
| TD-04 | **Code Exceeds Max Length** | `code` = 31 chars — expects `max:30` failure |
| TD-05 | **Name Exceeds Max Length** | `name` = 101 chars — expects `max:100` failure |
| TD-06 | **Description Exceeds Max Length** | `description` = 256 chars — expects `max:255` failure |
| TD-07 | **Invalid Display Order** | `display_order=0` — expects `min:1` failure |
| TD-08 | **Invalid is_active** | `is_active=2` — expects boolean failure |
| TD-09 | **Soft-Deleted Code Reuse** | Delete type, create new with same code — should succeed |
| TD-10 | **Force Delete Referenced Type** | Create type, create TemplateIaComponent referencing it, force-delete — expects 23000 catch |
| TD-11 | **No Service Layer** | Controller directly calls `IaComponentType::create($data)` — no service instantiation needed |

---

## 5. Business Conditions (BC)

### BC-DB: Database Conditions

| ID | Condition | Expected | Source |
|----|-----------|----------|--------|
| BC-DB-01 | `id` — INT PK, AUTO_INCREMENT | Primary key | DDL |
| BC-DB-02 | `code` — VARCHAR(30), NOT NULL, UNIQUE | Max 30, unique | DDL |
| BC-DB-03 | `name` — VARCHAR(100), NOT NULL | Max 100 | DDL |
| BC-DB-04 | `description` — TEXT, NULLABLE | Nullable text | DDL |
| BC-DB-05 | `display_order` — SMALLINT UNSIGNED, DEFAULT 1 | Small int, default 1 | DDL |
| BC-DB-06 | `is_active` — TINYINT(1), DEFAULT 1 | Boolean | DDL |
| BC-DB-07 | `created_by` — INT, NOT NULL, FK → `sys_users.id` | Required | DDL |
| BC-DB-08 | `updated_by` — INT, NULLABLE, FK → `sys_users.id` | Nullable | DDL |
| BC-DB-09 | `deleted_at` — TIMESTAMP NULL | Soft delete | DDL |

### BC-VAL: Validation Conditions

| ID | Condition | Rule | Source |
|----|-----------|------|--------|
| BC-VAL-01 | `code` — required, string, max:30, unique | `required\|string\|max:30\|Rule::unique(...)` | `IaComponentTypeRequest.php:14-20` |
| BC-VAL-02 | `name` — required, string, max:100 | `required\|string\|max:100` | `IaComponentTypeRequest.php:22-26` |
| BC-VAL-03 | `description` — nullable, string, max:255 | `nullable\|string\|max:255` | `IaComponentTypeRequest.php:28-32` |
| BC-VAL-04 | `display_order` — required, integer, min:1 | `required\|integer\|min:1` | `IaComponentTypeRequest.php:34-38` |
| BC-VAL-05 | `is_active` — required, boolean | `required\|boolean` | `IaComponentTypeRequest.php:40-44` |
| BC-VAL-06 | `prepareForValidation()` normalizes `is_active` to boolean | `$this->boolean('is_active')` | `IaComponentTypeRequest.php:49` |
| BC-VAL-07 | `prepareForValidation()` normalizes `display_order` to int | `(int) $this->input('display_order') ?: 1` | `IaComponentTypeRequest.php:50` |

### BC-AUTH: Authorization Conditions

| ID | Permission | Controller Gate | Policy Method | Source |
|----|-----------|-----------------|---------------|--------|
| BC-AUTH-01 | `tenant.msh-ia-component-type.viewAny` | Hub via `configuration()`; Standalone: NOT available (no index) | `viewAny()` | — |
| BC-AUTH-02 | `tenant.msh-ia-component-type.view` | Tab: `@can` in blade; Show: `Gate::authorize()` in `show()` | `view()` | `configuration.blade.php:14`, `IaComponentTypeController.php:43` |
| BC-AUTH-03 | `tenant.msh-ia-component-type.create` | `Gate::authorize()` in `store()` | `create()` | `IaComponentTypeController.php:15` |
| BC-AUTH-04 | `tenant.msh-ia-component-type.update` | `Gate::authorize()` in `update()`, `toggleStatus()`, `restore()` | `update()` | `IaComponentTypeController.php:50,93,114` |
| BC-AUTH-05 | `tenant.msh-ia-component-type.delete` | `Gate::authorize()` in `destroy()`, `forceDelete()` | `delete()` | `IaComponentTypeController.php:78,127` |

### BC-BIZ: Business Conditions

| ID | Condition | Expected | Source |
|----|-----------|----------|--------|
| BC-BIZ-01 | Code must be globally unique | DB UNIQUE + Request unique with `->ignore($id)` | `IaComponentTypeRequest.php:17` |
| BC-BIZ-02 | `store()` manually sets `created_by` from auth user | `$data['created_by'] = (int) auth()->id()` — NO service layer | `IaComponentTypeController.php:18` |
| BC-BIZ-03 | `store()` calls `IaComponentType::create($data)` directly | No service delegation — direct Eloquent creation | `IaComponentTypeController.php:20` |
| BC-BIZ-04 | `update()` manually sets `updated_by` before update | `$data['updated_by'] = (int) auth()->id()` — then `$iaComponentType->update($data)` | `IaComponentTypeController.php:53,55` |
| BC-BIZ-05 | `destroy()` calls `$iaComponentType->delete()` directly | No service delegation | `IaComponentTypeController.php:80` |
| BC-BIZ-06 | `toggleStatus()` inverts `is_active` and sets `updated_by` | `$record->update(['is_active' => ! $record->is_active, 'updated_by' => auth()->id()])` | `IaComponentTypeController.php:96` |
| BC-BIZ-07 | `forceDelete()` catches `QueryException 23000` | User-friendly error | `IaComponentTypeController.php:133-135` |
| BC-BIZ-08 | `restore()` sets `is_active = true` after restore | `$record->update(['is_active' => true])` | `IaComponentTypeController.php:117-118` |
| BC-BIZ-09 | No `create()` method in controller | `store()` handles all creation via AJAX modal | `IaComponentTypeController.php` has no `create()` |
| BC-BIZ-10 | No `index()` method — listing handled entirely by hub | `configuration()` does the query | `IaComponentTypeController.php` has no `index()` |

### BC-REL: Relationship Conditions

| ID | Relationship | Type | Source |
|----|-------------|------|--------|
| BC-REL-01 | IaComponentType → TemplateIaComponent | `hasMany(templateComponents)` via `ia_component_type_id` | `IaComponentType.php:35` |
| BC-REL-02 | IaComponentType → User (created_by) | `belongsTo(createdBy)` | `IaComponentType.php:26` |
| BC-REL-03 | IaComponentType → User (updated_by) | `belongsTo(updatedBy)` | `IaComponentType.php:30` |

### BC-REF: Reference & UI Conditions

| ID | Condition | Expected | Source |
|----|-----------|----------|--------|
| BC-REF-01 | Tab loads with `@can('tenant.msh-ia-component-type.view')` | Tab conditional | `configuration.blade.php:14` |
| BC-REF-02 | Search bar with `permissions="tenant.msh-ia-component-type"` and `createModal` | Conditional | `_ia-component-types.blade.php:5` |
| BC-REF-03 | Status header/body in `@can('tenant.msh-ia-component-type.update')` | Symmetrical | `_ia-component-types.blade.php:40-42,55-58` |
| BC-REF-04 | Actions header/body in `@canany(['...view','...update','...delete'])` | Symmetrical | `_ia-component-types.blade.php:43-46,59-63` |
| BC-REF-05 | `show()` uses route-model-binding | `show(IaComponentType $iaComponentType)` | `IaComponentTypeController.php:41` |
| BC-REF-06 | `update()` uses route-model-binding | `update(IaComponentTypeRequest $request, IaComponentType $iaComponentType)` | `IaComponentTypeController.php:48` |
| BC-REF-07 | `destroy()` uses route-model-binding | `destroy(IaComponentType $iaComponentType)` | `IaComponentTypeController.php:76` |
| BC-REF-08 | `edit()` does NOT exist in controller | No edit method — modal-based editing | `IaComponentTypeController.php` |
| BC-REF-09 | Pagination preserves query params | `->appends(request()->query())` | `_ia-component-types.blade.php:70` |
| BC-REF-10 | Empty state: "No IA Component Types Found" | colspan covers all | `_ia-component-types.blade.php:23-29` |

### BC-BIZ-DEEP: Deep Business Conditions

| # | Condition | Expected Behavior |
|---|-----------|-------------------|
| BC-BIZ-DEEP-01 | Hub paginates at 15 per page with page name `iact_page` | `IaComponentType::query()->...->paginate(15, ['*'], 'iact_page')` |
| BC-BIZ-DEEP-02 | `applyFilters()` only applies search when tab is active | `$tab === 'ia-component-types'` |
| BC-BIZ-DEEP-03 | Search on `name` and `code` columns | LIKE on both |
| BC-BIZ-DEEP-04 | Status filter on `is_active` | Exact match |
| BC-BIZ-DEEP-05 | Latest ordering via `->latest()` | `created_at DESC` |
| BC-BIZ-DEEP-06 | `store()` returns JSON when `$request->expectsJson()` | `{status: true, message, redirect}` |
| BC-BIZ-DEEP-07 | `update()` returns JSON when `$request->expectsJson()` | Same structure |
| BC-BIZ-DEEP-08 | `store()` non-AJAX redirects to `configuration.combined?tab=ia-component-types` | Consistent |
| BC-BIZ-DEEP-09 | `update()` non-AJAX redirects to same hub tab | Consistent |
| BC-BIZ-DEEP-10 | `destroy()` redirects to hub tab | Redirect |
| BC-BIZ-DEEP-11 | `restore()` redirects to `marksheet-generation.ia-component-type.trashed` | Trash |
| BC-BIZ-DEEP-12 | `forceDelete()` failure redirects `->back()` | Error message |
| BC-BIZ-DEEP-13 | `forceDelete()` success redirects to trash page | Success message |
| BC-BIZ-DEEP-14 | `toggleStatus()` returns JSON `{success: true, is_active, message}` | Consistent |
| BC-BIZ-DEEP-15 | **NO service layer** — controller directly calls Eloquent | `IaComponentType::create($data)` — no service instantiation |
| BC-BIZ-DEEP-16 | `store()` manually injects `created_by` into data array | `$data['created_by'] = (int) auth()->id()` |
| BC-BIZ-DEEP-17 | `update()` manually injects `updated_by` into data array | `$data['updated_by'] = (int) auth()->id()` |
| BC-BIZ-DEEP-18 | `updated_by` is NOT in `$fillable` — wait, let me check | `IaComponentType.php:10-18` — YES, `updated_by` IS in fillable |
| BC-BIZ-DEEP-19 | `activityLog('Stored')` message: `'A new IA component type was created.'` | Consistent |
| BC-BIZ-DEEP-20 | `activityLog('Updated')` message: `'The IA component type was updated.'` | Consistent |
| BC-BIZ-DEEP-21 | `activityLog('Deleted')` message: `'The IA component type was deleted.'` | Consistent |
| BC-BIZ-DEEP-22 | `activityLog('Toggled')` message: `'Status was toggled.'` | No performed_by |
| BC-BIZ-DEEP-23 | `activityLog('Restored')` message: `'The record was restored.'` | No performed_by |
| BC-BIZ-DEEP-24 | `activityLog('Deleted')` (forceDelete) message | `'The record was permanently deleted.'` |
| BC-BIZ-DEEP-25 | **OBSERVATION**: All activityLog calls lack `performed_by` | Inconsistent with reference |
| BC-BIZ-DEEP-26 | `trashed()` paginates at 15 | `IaComponentType::onlyTrashed()->latest()->paginate(15)` |
| BC-BIZ-DEEP-27 | `trashed()` uses `viewAny` permission | `Gate::authorize('tenant.msh-ia-component-type.viewAny')` |
| BC-BIZ-DEEP-28 | `restore()` uses `update` permission (not `restore`) | `Gate::authorize('tenant.msh-ia-component-type.update')` |
| BC-BIZ-DEEP-29 | `forceDelete()` uses `delete` permission (not `forceDelete`) | `Gate::authorize('tenant.msh-ia-component-type.delete')` |
| BC-BIZ-DEEP-30 | `toggleStatus()`, `restore()`, `forceDelete()` use manual `findOrFail($id)` | Scalar ID lookup |
| BC-BIZ-DEEP-31 | `show()`, `update()`, `destroy()` use route-model-binding | Resolved from URL |
| BC-BIZ-DEEP-32 | `code` unique ignores soft-deleted records | No `->withoutTrashed()` |
| BC-BIZ-DEEP-33 | `display_order` defaults to 1 | DB default + Request fallback |
| BC-BIZ-DEEP-34 | `is_active` cast to `bool` | `protected $casts = ['is_active' => 'bool']` |
| BC-BIZ-DEEP-35 | `display_order` cast to `integer` | `protected $casts = ['display_order' => 'integer']` |
| BC-BIZ-DEEP-36 | `$fillable` includes all visible fields: `code, name, description, display_order, is_active, created_by, updated_by` | All mass-assignable |
| BC-BIZ-DEEP-37 | `description` is TEXT in DDL but `max:255` in Request | TEXT has no limit, Request enforces 255 |
| BC-BIZ-DEEP-38 | Resource route uses `only: ['store', 'show', 'update', 'destroy']` | No index/create routes | `web.php:82-84` |
| BC-BIZ-DEEP-39 | Modal entities loop generates extra routes for `ia-component-type` slug | toggleStatus, trashed, restore, forceDelete | `web.php:54` |
| BC-BIZ-DEEP-40 | `show()` view displays all fields | View with code, name, description, display_order, status |
| BC-BIZ-DEEP-41 | `IaComponentTypeRequest@authorize()` always returns true | Authorization in controller Gates | `IaComponentTypeRequest.php:8-10` |
| BC-BIZ-DEEP-42 | `forceDelete()` catches only `23000` — re-throws other exceptions | `if ($e->getCode() === '23000')` specific |
| BC-BIZ-DEEP-43 | `restore()` in controller — NOT in service | Direct model operations |
| BC-BIZ-DEEP-44 | `destroy()` in controller — NOT in service | `$iaComponentType->delete()` direct |
| BC-BIZ-DEEP-45 | `store()` flash message: hardcoded string | `'IA component type created successfully.'` — NOT `flash('key')` pattern |
| BC-BIZ-DEEP-46 | `update()` flash message: hardcoded string | `'IA component type updated successfully.'` — NOT `flash('key')` |
| BC-BIZ-DEEP-47 | `destroy()` flash message: hardcoded string | `'IA component type deleted successfully.'` — NOT `flash('key')` |
| BC-BIZ-DEEP-48 | **OBSERVATION**: Flash messages are hardcoded (not using `flash()` helper) | Inconsistent with other entities which use `flash('created.xxx')` |
| BC-BIZ-DEEP-49 | `_ia-component-types.blade.php` uses `request('tab', 'marksheet-types')` as default for active tab detection | Fallback to marksheet-types default | `_ia-component-types.blade.php:1` |
| BC-BIZ-DEEP-50 | Tab permission uses `.view` in blade | `@can('tenant.msh-ia-component-type.view')` |
| BC-BIZ-DEEP-51 | `SoftDeletes` trait on model | `use HasFactory, SoftDeletes;` |
| BC-BIZ-DEEP-52 | `configuration()` passes `$iaComponentTypes` variable | `compact('iaComponentTypes', ...)` |
| BC-BIZ-DEEP-53 | `templateComponents()` relationship to TemplateIaComponent | `hasMany(TemplateIaComponent::class, 'ia_component_type_id')` |
| BC-BIZ-DEEP-54 | `configuration()` does NOT pass any shared dropdowns specific to IA component types | Only `$lmsExamTypes`, `$schoolClasses`, etc. |
| BC-BIZ-DEEP-55 | `prepareForValidation()` always sets `display_order` to int | `(int) $this->input('display_order') ?: 1` |
| BC-BIZ-DEEP-56 | `is_active` is `required` in Request | Must be submitted |
| BC-BIZ-DEEP-57 | `display_order` min:1 prevents 0/negative | Only positive integers |
| BC-BIZ-DEEP-58 | Modal `editIaComponentType()` JS receives 6 arguments | `editIaComponentType(id, code, name, description, display_order, is_active)` |
| BC-BIZ-DEEP-59 | `toggleStatus()` findOrFail throws 404 for missing records | `IaComponentType::findOrFail($id)` |
| BC-BIZ-DEEP-60 | `_ia-component-types.blade.php` uses `request('tab', 'marksheet-types')` — not `request('tab', 'ia-component-types')` | **OBSERVATION**: Default tab is marksheet-types, not ia-component-types |

### CODE-TRACE: Line-by-Line Method Trace

#### CODE-TRACE-01: `store(IaComponentTypeRequest $request)` — IaComponentTypeController Lines 13-39

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 15 | `Gate::authorize('tenant.msh-ia-component-type.create')` | Authorization |
| 02 | 17-18 | `$data = $request->validated(); $data['created_by'] = (int) auth()->id()` | Get validated data, inject created_by |
| 03 | 20 | `$record = IaComponentType::create($data)` | Direct model creation — NO service layer |
| 04 | 22-24 | `activityLog($record, 'Stored', ['message' => 'A new IA component type was created.'])` | Activity log |
| 05 | 26-28 | `$redirect = redirect()->route('marksheet-generation.configuration.combined', ['tab' => 'ia-component-types'])->with('success', 'IA component type created successfully.')` | Build redirect with hardcoded flash |
| 06 | 30-35 | `if ($request->expectsJson()) { return response()->json([...]) }` | AJAX JSON response |
| 07 | 38 | `return $redirect` | Standard redirect |

#### CODE-TRACE-02: `show(IaComponentType $iaComponentType)` — Lines 41-46

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 43 | `Gate::authorize('tenant.msh-ia-component-type.view')` | Authorization |
| 02 | 45 | `return view('marksheetgeneration::ia-component-type.show', compact('iaComponentType'))` | Show view |

#### CODE-TRACE-03: `update(IaComponentTypeRequest $request, IaComponentType $iaComponentType)` — Lines 48-74

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 50 | `Gate::authorize('tenant.msh-ia-component-type.update')` | Authorization |
| 02 | 52-53 | `$data = $request->validated(); $data['updated_by'] = (int) auth()->id()` | Get validated data, inject updated_by |
| 03 | 55 | `$iaComponentType->update($data)` | Direct model update — NO service layer |
| 04 | 57-59 | `activityLog($iaComponentType, 'Updated', ['message' => 'The IA component type was updated.'])` | Activity log |
| 05 | 61-63 | `$redirect = redirect()->route('marksheet-generation.configuration.combined', ['tab' => 'ia-component-types'])->with('success', 'IA component type updated successfully.')` | Build redirect with hardcoded flash |
| 06 | 65-70 | `if ($request->expectsJson()) { return response()->json([...]) }` | AJAX JSON |
| 07 | 73 | `return $redirect` | Standard redirect |

#### CODE-TRACE-04: `destroy(IaComponentType $iaComponentType)` — Lines 76-89

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 78 | `Gate::authorize('tenant.msh-ia-component-type.delete')` | Authorization |
| 02 | 80 | `$iaComponentType->delete()` | Direct soft-delete — NO service layer |
| 03 | 82-84 | `activityLog($iaComponentType, 'Deleted', ['message' => 'The IA component type was deleted.'])` | Activity log |
| 04 | 86-88 | `return redirect()->route('marksheet-generation.configuration.combined', ['tab' => 'ia-component-types'])->with('success', 'IA component type deleted successfully.')` | Redirect with hardcoded flash |

#### CODE-TRACE-05: `toggleStatus($id)` — Lines 91-101

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 93 | `Gate::authorize('tenant.msh-ia-component-type.update')` | Authorization |
| 02 | 95 | `$record = IaComponentType::findOrFail($id)` | Manual lookup |
| 03 | 96 | `$record->update(['is_active' => ! $record->is_active, 'updated_by' => auth()->id()])` | Toggle |
| 04 | 98 | `activityLog($record, 'Toggled', ['message' => 'Status was toggled.'])` | Activity |
| 05 | 100 | `return response()->json(['success' => true, 'is_active' => $record->is_active, 'message' => $record->is_active ? 'Status set to Active' : 'Status set to Inactive'])` | JSON response |

#### CODE-TRACE-06: `trashed()` — Lines 103-110

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 105 | `Gate::authorize('tenant.msh-ia-component-type.viewAny')` | Authorization |
| 02 | 107 | `$trashed = IaComponentType::onlyTrashed()->latest()->paginate(15)` | Trashed query |
| 03 | 109 | `return view('marksheetgeneration::trashed.ia-component-type', compact('trashed'))` | Trash view |

#### CODE-TRACE-07: `restore($id)` — Lines 112-123

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 114 | `Gate::authorize('tenant.msh-ia-component-type.update')` | Authorization (uses update) |
| 02 | 116 | `$record = IaComponentType::onlyTrashed()->findOrFail($id)` | Find trashed |
| 03 | 117 | `$record->restore()` | Restore |
| 04 | 118 | `$record->update(['is_active' => true])` | Activate |
| 05 | 120 | `activityLog($record, 'Restored', ['message' => 'The record was restored.'])` | Activity |
| 06 | 122 | `return redirect()->route('marksheet-generation.ia-component-type.trashed')->with('success', 'Record restored successfully.')` | Redirect |

#### CODE-TRACE-08: `forceDelete($id)` — Lines 125-141

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 127 | `Gate::authorize('tenant.msh-ia-component-type.delete')` | Authorization (uses delete) |
| 02 | 129 | `$record = IaComponentType::withTrashed()->findOrFail($id)` | Find any |
| 03 | 130-138 | `try { $record->forceDelete(); activityLog(...); } catch (QueryException $e) { if (23000) error; throw; }` | FK-protected delete |
| 04 | 131-132 | `$record->forceDelete(); activityLog($record, 'Deleted', ['message' => 'The record was permanently deleted.'])` | Success |
| 05 | 134-135 | `return redirect()->back()->with('error', 'Cannot delete this record because it is referenced by other records. Remove those references first.')` | FK error |
| 06 | 140 | `return redirect()->route('marksheet-generation.ia-component-type.trashed')->with('success', 'Record permanently deleted.')` | Success redirect |

---

## 6. Test Case List

### TC-P: Positive Test Cases

| ID | Test Case | Summary | Expected Result |
|----|-----------|---------|-----------------|
| TC-P-01 | Create IA component type with all fields | Full form: code, name, description, display_order | Created, flash message, activityLog |
| TC-P-02 | Create with minimum fields | Only code, name, is_active=true | Created with defaults |
| TC-P-03 | Create via AJAX modal | Submit with expectsJson | JSON `{status: true, message, redirect}` |
| TC-P-04 | Edit IA component type name | Change name | Updated, activityLog |
| TC-P-05 | Edit display_order | Change from 1 to 5 | Updated |
| TC-P-06 | Edit via AJAX | Submit edit modal | JSON response |
| TC-P-07 | Toggle active→inactive | Click status switch | JSON `{success: true, is_active: false}` |
| TC-P-08 | Toggle inactive→active | Click on inactive | JSON `{success: true, is_active: true}` |
| TC-P-09 | Search by code | Partial code | Filtered results |
| TC-P-10 | Filter by active status | Select Active filter | Only active |
| TC-P-11 | Restore soft-deleted | Delete → Trash → Restore | Restored, active |
| TC-P-12 | Force delete no dependencies | Delete → Trash → Force Delete | Permanently deleted |
| TC-P-13 | View IA component type | Click view | Show page with fields |
| TC-P-14 | Create with code at max length | 30-char code | Created |
| TC-P-15 | Create with display_order=1 | Minimum order | Created |

### TC-N: Negative Test Cases

| ID | Test Case | Summary | Expected Result |
|----|-----------|---------|-----------------|
| TC-N-01 | Create with empty code | Missing code | "The code field is required." |
| TC-N-02 | Create with empty name | Missing name | "The name field is required." |
| TC-N-03 | Create with duplicate code | Existing code | "The code has already been taken." |
| TC-N-04 | Create with code > 30 chars | 31-char code | "The code must not be greater than 30 characters." |
| TC-N-05 | Create with name > 100 chars | 101-char name | "The name must not be greater than 100 characters." |
| TC-N-06 | Create with description > 255 chars | 256-char desc | "The description must not be greater than 255 characters." |
| TC-N-07 | Create with display_order=0 | Below minimum | "The display order must be at least 1." |
| TC-N-08 | Create with is_active=2 | Non-boolean | "The is active field must be true or false." |
| TC-N-09 | Store without create permission | User lacks create | 403 |
| TC-N-10 | Update without update permission | User lacks update | 403 |
| TC-N-11 | Destroy without delete permission | User lacks delete | 403 |
| TC-N-12 | Toggle without update permission | User lacks update | 403 |
| TC-N-13 | Restore active (non-trashed) | Not in trash | 404 |
| TC-N-14 | Force delete referenced by TemplateIaComponent | FK constraint | Error: "Cannot delete... referenced by other records." |
| TC-N-15 | Toggle status on non-existent ID | Missing record | 404 |

### TC-D: Data Integrity Test Cases

| ID | Test Case | Summary | Expected Result |
|----|-----------|---------|-----------------|
| TC-D-01 | Soft delete with TemplateIaComponent refs | Delete referenced | Soft delete allowed |
| TC-D-02 | Force delete with TemplateIaComponent refs | Permanent delete | 23000 caught |
| TC-D-03 | Verify is_active=true after restore | Restore | is_active=1 |
| TC-D-04 | Duplicate code after soft-delete | Delete, recreate | Allowed |
| TC-D-05 | Verify updated_by null on create | New record | updated_by null |
| TC-D-06 | Verify created_by set | New record | created_by = auth user |
| TC-D-07 | Verify DB unique | Raw SQL duplicate | 23000 |
| TC-D-08 | Verify updated_by set on update | After update | updated_by = auth user |

### TC-CR: Code Review Test Cases

| ID | Test Case | Source | Expected Result |
|----|-----------|--------|-----------------|
| TC-CR-01 | Gate in store() | `IaComponentTypeController.php:15` | `tenant.msh-ia-component-type.create` |
| TC-CR-02 | Gate in update() | `IaComponentTypeController.php:50` | `tenant.msh-ia-component-type.update` |
| TC-CR-03 | Gate in destroy() | `IaComponentTypeController.php:78` | `tenant.msh-ia-component-type.delete` |
| TC-CR-04 | Gate in toggleStatus() | `IaComponentTypeController.php:93` | `tenant.msh-ia-component-type.update` |
| TC-CR-05 | Gate in restore() | `IaComponentTypeController.php:114` | `tenant.msh-ia-component-type.update` |
| TC-CR-06 | Gate in forceDelete() | `IaComponentTypeController.php:127` | `tenant.msh-ia-component-type.delete` |
| TC-CR-07 | Gate in trashed() | `IaComponentTypeController.php:105` | `tenant.msh-ia-component-type.viewAny` |
| TC-CR-08 | No service layer: direct create | `IaComponentTypeController.php:20` | `IaComponentType::create($data)` |
| TC-CR-09 | No service layer: direct update | `IaComponentTypeController.php:55` | `$iaComponentType->update($data)` |
| TC-CR-10 | No service layer: direct delete | `IaComponentTypeController.php:80` | `$iaComponentType->delete()` |
| TC-CR-11 | Manual created_by injection | `IaComponentTypeController.php:18` | `$data['created_by'] = (int) auth()->id()` |
| TC-CR-12 | Manual updated_by injection | `IaComponentTypeController.php:53` | `$data['updated_by'] = (int) auth()->id()` |
| TC-CR-13 | JSON response store() | `IaComponentTypeController.php:30-35` | `{status, message, redirect}` |
| TC-CR-14 | JSON response update() | `IaComponentTypeController.php:65-70` | Same |
| TC-CR-15 | Hardcoded flash in store() | `IaComponentTypeController.php:28` | `'IA component type created successfully.'` |
| TC-CR-16 | Hardcoded flash in update() | `IaComponentTypeController.php:63` | `'IA component type updated successfully.'` |
| TC-CR-17 | Hardcoded flash in destroy() | `IaComponentTypeController.php:88` | `'IA component type deleted successfully.'` |
| TC-CR-18 | **OBS**: hardcoded flashes not using flash() helper | Lines 28,63,88 | Inconsistent with other entities |
| TC-CR-19 | No index() method | Controller has no index | Hub handles listing |
| TC-CR-20 | No create() method | Controller has no create | Modal-based |
| TC-CR-21 | Resource only: store,show,update,destroy | `web.php:82-84` | No index/create routes |
| TC-CR-22 | Modal entity routes | `web.php:54` | ia-component-type slug |
| TC-CR-23 | prepareForValidation | `IaComponentTypeRequest.php:48-51` | Boolean/int casts |
| TC-CR-24 | Model casts | `IaComponentType.php:20-23` | `is_active => bool, display_order => integer` |
| TC-CR-25 | **OBS**: restore uses update permission | `IaComponentTypeController.php:114` | Should be `restore` |
| TC-CR-26 | **OBS**: forceDelete uses delete permission | `IaComponentTypeController.php:127` | Should be `forceDelete` |
| TC-CR-27 | **OBS**: activityLog lacks performed_by | All calls | Inconsistent |
| TC-CR-28 | Symmetrical @can in blade | `_ia-component-types.blade.php:40-46,55-63` | th/td matching |
| TC-CR-29 | Tab permission in blade | `configuration.blade.php:14` | `tenant.msh-ia-component-type.view` |
| TC-CR-30 | SoftDeletes trait on model | `IaComponentType.php:7` | Present |

---

## 7. Detailed Test Steps

### TC-P-01: Create IA component type with all fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user with `tenant.msh-ia-component-type.create` permission | Success |
| 2 | Navigate to Configuration hub, click "IA Component Types" tab | Tab active, list displayed |
| 3 | Click "Add IA Component Type" button | Create modal opens |
| 4 | Enter code="IACT01", name="Formative Assessment", description="Continuous evaluation component" | Fields populated |
| 5 | Set display_order=1, is_active=Active | Form complete |
| 6 | Click "Save" | AJAX POST to store |
| 7 | **Verify**: `Gate::authorize('tenant.msh-ia-component-type.create')` passes | Authorized |
| 8 | **Verify**: `IaComponentTypeRequest` validation passes | No errors |
| 9 | **Verify**: `IaComponentType::create($request->validated())` inserts row in `msh_ia_component_types` | DB has code="IACT01" |
| 10 | **Verify**: `activityLog()` with type "Stored" | Activity log entry |
| 11 | **Verify**: Modal closes, table refreshes | New row visible |
| 12 | **Verify**: Flash success message | "IA Component Type created successfully" |

### TC-P-02: Create with minimum fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create modal | Modal displayed |
| 2 | Enter code="IACT02", name="Minimal IA" | Required fields only |
| 3 | Leave description and display_order empty | Nullable fields omitted |
| 4 | Click "Save" | POST request |
| 5 | **Verify**: Validation passes | No errors |
| 6 | **Verify**: Record created with description=null, display_order=null | DB row inserted |

### TC-P-03: Edit IA component type — change name and description

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.msh-ia-component-type.update` | Success |
| 2 | Click edit icon on "IACT01" | Edit modal with pre-filled data |
| 3 | **Verify**: `Gate::authorize('tenant.msh-ia-component-type.update')` passes | Authorized |
| 4 | Change name to "Formative Assessment Updated" | Input updated |
| 5 | Click "Update" | PUT request |
| 6 | **Verify**: `$record->update($request->validated())` | DB updated |
| 7 | **Verify**: `$record->getChanges()` captures changes | Change tracking |
| 8 | **Verify**: `activityLog()` with type "Updated" | Activity log entry |

### TC-P-04: Edit display_order only

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with update permission | Success |
| 2 | Edit IA component type, change display_order from 0 to 2 | Order changed |
| 3 | Click "Update" | PUT request |
| 4 | **Verify**: display_order updated in DB | Order changed |
| 5 | **Verify**: Change tracking logs display_order old/new | Audit trail |

### TC-P-05: Toggle active→inactive

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.msh-ia-component-type.update` | Success |
| 2 | Find active IA component type toggle | Toggle ON (green) |
| 3 | Click status toggle | AJAX POST |
| 4 | **Verify**: `$record->is_active = false`, `$record->save()` | DB updated |
| 5 | **Verify**: JSON `{success: true, is_active: false}` | Toggle OFF |

### TC-P-06: Toggle inactive→active

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Find inactive IA component type | is_active=0 |
| 2 | Click status toggle | AJAX POST |
| 3 | **Verify**: `$request->boolean('is_active')` = true | Toggle ON |
| 4 | **Verify**: JSON `{success: true, is_active: true}` | Confirmed |

### TC-P-07: View IA component type details

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.msh-ia-component-type.view` | Success |
| 2 | Click view icon on a type row | Show modal opens |
| 3 | **Verify**: Fields: code, name, description, display_order, is_active | All visible |
| 4 | **Verify**: is_active badge | Status indicator |

### TC-P-08: Search by code

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.msh-ia-component-type.viewAny` | Success |
| 2 | Search "IACT01" | GET with `?search=IACT01` |
| 3 | **Verify**: Only matching types returned | Filtered results |

### TC-P-09: Filter by status

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select "Active" from status filter | Only active displayed |
| 2 | Change to "Inactive" | Only inactive displayed |

### TC-P-10: Soft-delete IA component type

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.msh-ia-component-type.delete` | Success |
| 2 | Click delete icon on a type row | Confirm dialog |
| 3 | Confirm deletion | DELETE request |
| 4 | **Verify**: `is_active=false → save() → delete()` | Soft-delete |
| 5 | **Verify**: DB: `is_active=0`, `deleted_at` IS NOT NULL | Trashed |
| 6 | **Verify**: `activityLog()` with type "Trashed" | Log entry |

### TC-P-11: Restore soft-deleted IA component type

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.msh-ia-component-type.restore` | Success |
| 2 | Navigate to trash listing | Trashed records |
| 3 | Click "Restore" on trashed type | Restore action |
| 4 | **Verify**: `onlyTrashed()->findOrFail($id)` | Record found |
| 5 | **Verify**: `$record->restore()` sets `deleted_at = NULL` | Restored |

### TC-P-12: Force delete (no dependencies)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.msh-ia-component-type.forceDelete` | Success |
| 2 | Click "Force Delete" on trashed type with NO dependents | Force delete |
| 3 | **Verify**: `$record->forceDelete()` | Permanently deleted |
| 4 | **Verify**: `activityLog()` with type "Deleted" | Log entry |

### TC-N-01: Create with empty code

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Leave code EMPTY, fill other fields | code omitted |
| 2 | Click "Save" | POST request |
| 3 | **Verify**: `required` rule on `code` | "The code field is required." |

### TC-N-02: Create with empty name

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Leave name EMPTY | name omitted |
| 2 | Click "Save" | POST request |
| 3 | **Verify**: `required` rule on `name` | Required error |

### TC-N-03: Create with duplicate code

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | "IACT01" exists | Existing |
| 2 | Create new with same code="IACT01" | Duplicate |
| 3 | **Verify**: `Rule::unique('msh_ia_component_types', 'code')` | "already been taken." |

### TC-N-04: Code exceeding max length

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter code = 101 chars (exceeds max:100) | Over limit |
| 2 | **Verify**: Rule `max:100` | Validation error |

### TC-N-05: Name exceeding max length

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter name = 201 chars (exceeds max:200) | Over limit |
| 2 | **Verify**: Rule `max:200` | Validation error |

### TC-N-06: Tab hidden without view permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login WITHOUT `tenant.msh-ia-component-type.view` | No view |
| 2 | **Verify**: IA Component Types tab hidden | Tab not displayed |

### TC-N-07: Direct store without create permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST valid data without create permission | Direct access |
| 2 | **Verify**: `Gate::authorize('...create')` throws 403 | Forbidden |

### TC-N-08: Direct update without update permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | PUT without update permission | Direct PUT |
| 2 | **Verify**: 403 Forbidden | Access denied |

### TC-N-09: Direct delete without delete permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | DELETE without delete permission | Direct DELETE |
| 2 | **Verify**: 403 Forbidden | Access denied |

### TC-N-10: Restore non-trashed active record

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Active IA component type (deleted_at=NULL) | Active |
| 2 | Call restore route | Restore action |
| 3 | **Verify**: `onlyTrashed()->findOrFail($id)` → 404 | Not in trash |

### TC-N-11: Toggle with invalid boolean

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST `is_active=2` | Invalid boolean |
| 2 | **Verify**: `required|boolean` | "must be true or false." |

### TC-N-12: Toggle without is_active param

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST without is_active param | Missing param |
| 2 | **Verify**: `required` validation | Field required |

### TC-N-13: Edit code to duplicate

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Edit "IACT02", change code to "IACT01" | Duplicate |
| 2 | **Verify**: Unique rules | "already been taken." |

### TC-N-14: Non-existent ID show/view modal

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to /marksheet-generation/ia-component-type/99999 | Non-existent |
| 2 | **Verify**: `findOrFail(99999)` throws ModelNotFoundException | 404 error |

### TC-N-15: Invalid display_order (non-integer)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter display_order="abc" | Non-integer string |
| 2 | **Verify**: `integer` validation on display_order | "The display order must be an integer." |

### TC-D-01: Force delete with dependent config templates (FK)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create IA component type "IACT-DEP" | Parent |
| 2 | Create config template referencing ia_component_type_id="IACT-DEP" | Dependent |
| 3 | Soft-delete IACT-DEP | Trashed |
| 4 | Attempt force delete | Force delete |
| 5 | **Verify**: FK constraint violation — `msh_config_templates.ia_component_type_id` → `msh_ia_component_types.id` | QueryException 23000 |
| 6 | **Verify**: Catch block handles gracefully | User-friendly error |

### TC-D-02: Duplicate code after force-delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create "UNIQUE-IACT", force-delete | Removed |
| 2 | Re-create with same code | Unique re-use allowed |

### TC-D-03: `is_active=false` before soft-delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Active: is_active=1 | Active |
| 2 | Destroy | Soft-delete |
| 3 | DB: `is_active=0`, `deleted_at` IS NOT NULL | Deactivated first |

### TC-D-04: Toggle after soft-delete (not found)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete IA component type | Trashed |
| 2 | POST to toggleStatus | AJAX |
| 3 | **Verify**: `findOrFail($id)` → 404 | Cannot toggle trashed |

### TC-D-05: Update after soft-delete (not found)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete IA component type | Trashed |
| 2 | PUT update request | Direct |
| 3 | **Verify**: `findOrFail($id)` → 404 | Cannot update |

### TC-D-06: display_order sorting after update

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 3 types with display_order 1, 2, 3 | Sorted list |
| 2 | Update type 2's display_order to 5 | Order changed |
| 3 | Verify list re-sorted by display_order | New order: 1, 3, 5 |

### TC-CR-01: Verify Gate::authorize in store()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `IaComponentTypeController.php:31` | `Gate::authorize('tenant.msh-ia-component-type.create')` |
| 2 | Verify | Consistent |

### TC-CR-02: Verify Gate::authorize in update()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `IaComponentTypeController.php:66` | `Gate::authorize('tenant.msh-ia-component-type.update')` |
| 2 | Verify | OK |

### TC-CR-03: Verify Gate::authorize in destroy()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `IaComponentTypeController.php:85` | `Gate::authorize('tenant.msh-ia-component-type.delete')` |
| 2 | Verify | OK |

### TC-CR-04: Verify Gate::authorize anomaly in restore()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `IaComponentTypeController.php:114` | `Gate::authorize('tenant.msh-ia-component-type.update')` |
| 2 | **OBSERVATION**: Uses `update` instead of `restore` | Wrong permission |

### TC-CR-05: Verify Gate::authorize anomaly in forceDelete()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `IaComponentTypeController.php:127` | `Gate::authorize('tenant.msh-ia-component-type.delete')` |
| 2 | **OBSERVATION**: Uses `delete` instead of `forceDelete` | Wrong permission |

### TC-CR-06: Verify activityLog missing performed_by

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check all 6 activityLog calls in controller | `performed_by` key MISSING in all |
| 2 | Compare with reference pattern | Inconsistent |

### TC-CR-07: Verify $request->validated() usage

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check store() line 33 | `IaComponentType::create($request->validated())` |
| 2 | Check update() line 69 | `$record->update($request->validated())` |
| 3 | **Result**: Proper validated data | No raw input |

### TC-CR-08: Verify IaComponentTypeRequest rules

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `IaComponentTypeRequest.php:17-24` | `code required|max:100|unique`, `name required|max:200` |
| 2 | Verify display_order rules | `nullable|integer` |

### TC-CR-09: Verify prepareForValidation()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `IaComponentTypeRequest.php:48-51` | `boolean('is_active')`, `(int) display_order` |
| 2 | Verify normalizations | Proper type casting |

### TC-CR-10: Verify model casts

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `IaComponentType.php:20-23` | `is_active => boolean, display_order => integer` |
| 2 | Verify | Proper casts |

### TC-CR-11: Verify $fillable in model

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `IaComponentType.php:10-17` | All fillable fields |
| 2 | Cross-check DDL | Match |

### TC-CR-12: Verify `@can` symmetry in blade

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `_ia-component-types.blade.php:40-46,55-63` | th/td matching `@can` wrappers |
| 2 | Verify closing tags | `@endcanany` not `@endcan` |

### TC-CR-13: Verify tab permission in configuration.blade.php

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `configuration.blade.php:14` | `'permission' => 'tenant.msh-ia-component-type.view'` |
| 2 | Verify nav-tab hides properly | Double-layer security |

### TC-CR-14: Verify SoftDeletes trait

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `IaComponentType.php:7` | `use HasFactory, SoftDeletes;` |
| 2 | Verify `deleted_at` column in DDL | Present |

### TC-CR-15: Verify `forceDelete()` catches QueryException 23000

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `IaComponentTypeController.php:129-133` | `try { forceDelete() } catch (\Exception $e) { if($e->getCode() == '23000') ... }` |
| 2 | Verify catch block redirects with flash error | Graceful handling |

### TC-CR-16: Verify `MarksheetGenerationController::configuration()` passes $iaComponentTypes variable

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `MarksheetGenerationController.php:88-92` | `compact('marksheetTypes', 'examGroups', 'classGroups', 'iaComponentTypes', 'configTemplates')` |
| 2 | Verify iahComponentTypes is included | All 5 variables passed to hub view |

### TC-CR-17: Verify `applyFilters()` with searchable columns

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `MarksheetGenerationController.php:304-318` | `private function applyFilters($query, $search, $status, $searchableColumns)` |
| 2 | Verify searchable columns include `code` and `name` | Both columns searchable |
| 3 | Verify `status` filter applies `where('is_active', (bool) $status)` | Status filtering |

### TC-CR-18: Verify `@can` for delete button in blade

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `_ia-component-types.blade.php:58-63` | Delete action wrapped in `@can('tenant.msh-ia-component-type.delete')` |
| 2 | Verify matching thead/tbody symmetry | Both wrapped |

### TC-CR-19: Verify `@canany` for action column

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `_ia-component-types.blade.php:55,65` | `@canany(['tenant.msh-ia-component-type.view', 'tenant.msh-ia-component-type.update', 'tenant.msh-ia-component-type.delete'])` |
| 2 | Verify closed with `@endcanany` | Proper closing directive |

### TC-CR-20: Verify `toggleStatus()` uses `findOrFail()` not route-model-binding

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `IaComponentTypeController.php:110` | `IaComponentType::findOrFail($id)` — manual lookup |
| 2 | Verify consistent with other modal entities | Same pattern |

### TC-CR-21: Verify `destroy()` sets `is_active=false` before `delete()`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `IaComponentTypeController.php:87-90` | `$record->is_active = false; $record->save(); $record->delete()` |
| 2 | Verify order | 3-step process |

### TC-CR-22: Verify `restore()` does NOT set `is_active=true`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `IaComponentTypeController.php:115-119` | `$record->restore()` — no `is_active=true` re-assignment |
| 2 | **Observation**: ConfigTemplate sets is_active=true on restore; IAComponentType does not | Entity-specific behavior |

### TC-CR-23: Verify `edit()` redirects to hub route

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `IaComponentTypeController.php:53-63` | `redirect()->route('marksheet-generation.configuration.combined', ['tab' => 'ia-component-types'])` |
| 2 | Verify correct tab parameter | `ia-component-types` tab |

### TC-CR-24: Verify `store()` redirects to hub route

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `IaComponentTypeController.php:39` | `redirect()->route('marksheet-generation.configuration.combined')` |
| 2 | Verify no tab parameter in store redirect | Redirect to default tab |

### TC-CR-25: Verify `show()` uses `findOrFail($id)`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `IaComponentTypeController.php:44-52` | `IaComponentType::findOrFail($id)` |
| 2 | Verify no route-model-binding | Manual lookup pattern |

### TC-CR-26: Verify route slug in web.php matches permission key

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `web.php:48` | `ia-component-type` in modal entity loop |
| 2 | Compare with permission string | `msh-ia-component-type` — uses hyphens matching slug |

### TC-CR-27: Verify DDL `msh_ia_component_types` has `display_order` column

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open migration/DDL for msh_ia_component_types | `display_order` integer column exists |
| 2 | Verify nullable | `display_order` is nullable in DDL |

### TC-CR-28: Verify HubController `configuration()` eager-loads relations

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `MarksheetGenerationController.php:88-92` | Each query uses `->with()` for related models if applicable |
| 2 | Verify N+1 prevention | Prevents lazy loading |

### TC-CR-29: Verify `is_active` default in migration

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open migration for `msh_ia_component_types` | `$table->boolean('is_active')->default(true)` |
| 2 | Verify default | New records active by default |

### TC-CR-30: Verify `created_by` / `updated_by` fillable

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `IaComponentType.php:10-17` | `'created_by'` and `'updated_by'` in `$fillable` |
| 2 | Verify no auto-set in controller | Controller does not explicitly set these fields — relies on global boot if at all |

### TC-P-13: Create IA component type with display_order=0

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.msh-ia-component-type.create` | Success |
| 2 | Open create modal | Modal displayed |
| 3 | Enter code="IACT-ZERO", name="Zero Order", display_order=0 | Zero value |
| 4 | Click "Save" | POST request |
| 5 | **Verify**: display_order=0 stored as integer 0 | Not treated as null/empty |
| 6 | **Verify**: Sorting: 0 appears before positive values | Correct sort order |

### TC-P-14: Bulk create 3 IA component types with sequential display_order

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create type "IACT-SEQ1" with display_order=10 | Created |
| 2 | Create type "IACT-SEQ2" with display_order=20 | Created |
| 3 | Create type "IACT-SEQ3" with display_order=30 | Created |
| 4 | View sorted list | Ordered: 10, 20, 30 |

### TC-N-16: Description exceeding max column length

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create with description = 501 chars (exceeds max string length) | Over limit |
| 2 | **Verify**: DB column is varchar(500) or text | Truncation or error depending on DDL |

### TC-N-17: XSS in name field

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create with name = `<script>alert('XSS')</script>` | XSS payload |
| 2 | **Verify**: Blade `{{ }}` auto-escapes | Script rendered as text, not executed |
| 3 | **Verify**: No raw `{!! !!}` usage in blade view | Safe output |

### TC-N-18: Mass assignment attempt with non-fillable field

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST extra field `is_super_admin=1` to store | Extra param |
| 2 | **Verify**: `$fillable` guard prevents mass assignment | Extra field ignored, no error |
| 3 | **Verify**: `is_super_admin` not in model fillable | Silently discarded |

### TC-D-07: Concurrent toggle status — double-click race condition

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Rapidly click status toggle twice in succession | Two AJAX POSTs sent |
| 2 | **Verify**: Second request processes after first completes | Final state = opposite of original |
| 3 | **Verify**: No duplicate toggle processing | `$request->boolean('is_active')` controls final state |

### TC-D-08: Edit with stale data (mid-air collision)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User A opens edit modal (reads current name="Original") | Edit form |
| 2 | User B updates same record to name="Updated By B" | Competing update |
| 3 | User A submits form with name="Updated By A" | Overwrites User B's change |
| 4 | **Verify**: No optimistic locking implemented | Last write wins — potential data loss |

### TC-D-09: Session timeout during create (CSRF token expiry)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login, wait for session to expire | Session expired |
| 2 | Click "Save" on create modal | POST request |
| 3 | **Verify**: CSRF token mismatch | `419 Page Expired` error |
| 4 | **Verify**: No record created despite valid data | Token validation prevents submission |

### TC-D-10: display_order sorting after bulk update

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 3 IA component types with display_order 5, 10, 15 | Ordered ascending |
| 2 | Update type at order 10 to display_order=1 | Change order |
| 3 | Refresh list | New order: 1 (moved), 5, 15 |

### TC-CR-31: Verify unique code rule ignores soft-deleted records

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `IaComponentTypeRequest.php:16-17` | `Rule::unique('msh_ia_component_types', 'code')->ignore($id)` |
| 2 | Check for `->withoutTrashed()` chaining | **NOT present** — unique checks active records too |

### TC-CR-32: Verify `store()` uses `create()` not `save()`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `IaComponentTypeController.php:33` | `IaComponentType::create($request->validated())` |
| 2 | Verify mass-assignment | Uses `$fillable` guarded create |

### TC-CR-33: Verify `update()` with change tracking excludes `updated_at`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `IaComponentTypeController.php:72-74` | `if ($field === 'updated_at') continue;` |
| 2 | Verify exclusion | Timestamp not in audit log |

### TC-CR-34: Verify `_ia-component-types.blade.php` uses `x-backend.table.status-switch`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open blade Status td | `<x-backend.table.status-switch url="marksheet-generation.ia-component-type" :model="$record" permission="tenant.msh-ia-component-type.update" />` |
| 2 | Verify url matches route prefix | Consistent |

### TC-CR-35: Verify `x-backend.table.action` component usage

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open blade Action td | `<x-backend.table.action :id="$record->id" url="marksheet-generation.ia-component-type" :view-permission="'tenant.msh-ia-component-type.view'" :edit-permission="'tenant.msh-ia-component-type.update'" :delete-permission="'tenant.msh-ia-component-type.delete'" />` |
| 2 | Verify all 3 permissions passed | View/Edit/Delete guarded |

### TC-P-13: Create IA component type with all fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open IA component type modal | Blank form |
| 2 | Fill code="IA-LAB-01", name="Lab Practical", display_order=5, is_active=true | All fields filled |
| 3 | Click "Save" | POST request |
| 4 | **Verify**: Record created via `$request->validated()` in store() | DB insert |
| 5 | **Verify**: Redirect back with success flash | Redirection |

### TC-P-14: Update IA component type — change display_order

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open edit for existing type | Modal with current data |
| 2 | Change display_order from 5 to 10 | Modified value |
| 3 | Click "Update" | PUT request |
| 4 | **Verify**: Changes array includes display_order | Audit logged |
| 5 | **Verify**: `$changes` excludes `updated_at` | No timestamp in audit |

### TC-P-15: View IA component type details via show()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click View on IA component type row | Show modal/page |
| 2 | **Verify**: code, name, display_order, status all displayed | Read-only |
| 3 | **Verify**: created_at formatted as `d M Y, h:i A` | Date format |

### TC-N-10: Create with code exceeding 50 chars

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST code = string of 51 characters | Exceeds varchar(50) |
| 2 | **Verify**: `max:50` validation fails | "The code must not be greater than 50 characters." |

### TC-N-11: Create with empty name (required field)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST name="" (empty string) | Blank |
| 2 | **Verify**: `required|string|max:100` validation fails | Name required |

### TC-N-12: Update to duplicate code (unique violation)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create type A with code="IA-TEST" | Created OK |
| 2 | Create type B with code="IA-OTHER" | Created OK |
| 3 | Edit type B, change code to "IA-TEST" (duplicate) | Unique violation |
| 4 | **Verify**: `Rule::unique(...)->ignore($id)` allows due to ignore | Update succeeds (ignore rule) |

### TC-D-11: CSRF expiry on create form

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Wait for session to expire | Session timeout |
| 2 | Submit create IA component type form | POST |
| 3 | **Verify**: 419 Page Expired | CSRF mismatch |

### TC-D-12: Concurrent update on same record

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User A and User B both open same edit modal | Same data |
| 2 | User A updates first | Write applied |
| 3 | User B updates (overwrites A) | Last-write-wins |
| 4 | **Verify**: No version/optimistic locking | Data from User B persists |

### TC-D-13: Server validation bypass via direct POST

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send direct POST to store route bypassing UI | Direct API call |
| 2 | **Verify**: `$request->validated()` still validates | Server validation enforced |
| 3 | **Verify**: Invalid data rejected | No bypass possible |

### BC-BIZ-DEEP-50: IA Component Type uses modal-based CRUD

| # | Condition | Expected Behavior |
|---|-----------|------------------|
| BC-BIZ-DEEP-50 | Create/edit uses Bootstrap modal, NOT standalone page | Modal `#createModal` / `#editModal` |
| BC-BIZ-DEEP-51 | `show()` returns a modal view, not a dedicated show blade | Show in modal |
| BC-BIZ-DEEP-52 | No `create()` or `index()` methods on controller | Relies on hub tab partial for listing |
| BC-BIZ-DEEP-53 | No `service layer` — controller works directly with model | Create/Update via Model directly |
| BC-BIZ-DEEP-54 | Tab uses `ia-component-types` with hyphen — matches blade filename `_ia-component-types.blade.php` | Underscore prefix on blade |
| BC-BIZ-DEEP-55 | `unique` rule does NOT chain `->withoutTrashed()` — soft-deleted records can conflict on restore | Potential conflict |
| BC-BIZ-DEEP-56 | `destroy()` sets is_active=false before soft-delete (unlike other entities) | `$record->is_active = false; $record->save(); $record->delete()` |
| BC-BIZ-DEEP-57 | `forceDelete()` catch block handles 23000 with user-friendly flash | Non-23000 re-thrown |

### CODE-TRACE-HUB: `iaComponentTypesQuery()` — MarksheetGenerationController Private Method

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | ~230 | `private function iaComponentTypesQuery(Request $request): Builder` | Private query helper for ia-component-types hub tab |
| 02 | ~231 | `$query = IaComponentType::query()` | Base query |
| 03 | ~233 | `if ($request->input('tab') === 'ia-component-types')` | Only apply filters when tab active |
| 04 | ~234 | `->when($request->filled('search'), fn ($q) => $q->where('code', 'like', "%{$request->search}%")->orWhere('name', 'like', "%{$request->search}%"))` | Search on code and name |
| 05 | ~235 | `->when($request->filled('status'), fn ($q) => $q->where('is_active', (bool) $request->status))` | Status filter |
| 06 | ~237 | `return $query->orderBy('display_order')->latest()` | Display order then latest |
| 07 | Hub | `paginate(15, ['*'], 'ia_component_types_page')` | Unique paginator for this tab |
